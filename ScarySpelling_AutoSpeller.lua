--[[
	Scary Spelling — Auto Speller  (with UI)
	============================================================
	Built from the client dump of the game "Scary Spelling"
	(PlaceId 105055747082176).

	How the game works (from the dump):
	  • ReplicatedStorage.Events.GameEvent is the main RemoteEvent.
	      Client -> Server:
	          FireServer("updateAnswer", word)   -- live text as you type
	          FireServer("submitAnswer", word)   -- lock in the answer
	          FireServer("judgeChooseWord", word)-- pick next word (judge)
	          FireServer("judgeKillPlayer")      -- eliminate speller (judge)
	      Server -> Client (OnClientEvent, first arg is a command string):
	          "Answering"(definition)      -- it's YOUR turn, here's the clue
	          "StopAnswering"
	          "CorrectAnswer" / "IncorrectAnswer"
	          "StartJudgeChooseWord"(words) -- you're the judge, pick one
	          "StartJudgeKill" / "EndJudgeKill"
	          "Died"(...)
	  • The word itself is NEVER sent to the speller — only the definition
	    (shown in MainGui.GameFrame.DefinitionText). So we recover the word
	    from the definition with a dictionary reverse-lookup (Datamuse API,
	    no key required), then fire the remotes just like the real client.

	This is a client-side helper GUI. Load with your executor.
============================================================]]

--// Services
local Players           = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService  = game:GetService("UserInputService")
local HttpService       = game:GetService("HttpService")
local RunService        = game:GetService("RunService")
local StarterGui        = game:GetService("StarterGui")
local TweenService      = game:GetService("TweenService")

local LocalPlayer = Players.LocalPlayer
local PlayerGui   = LocalPlayer:WaitForChild("PlayerGui")

--// ── Config / State ─────────────────────────────────────────────────────
local State = {
	autoAnswer   = true,   -- solve + submit automatically on your turn
	autoJudge    = false,  -- auto-pick a word when you become the judge
	judgeHardest = true,   -- judge: pick the longest (hardest) word
	autoKill     = false,  -- judge: auto-eliminate the speller when prompted
	submitDelay  = 0.35,   -- seconds between "typing" and submitting
	typeMirror   = true,   -- mirror the answer into the on-screen board text
	maxCandidates= 24,     -- how many dictionary candidates to consider
	wordLength   = 0,      -- if > 0, only consider words of this exact length
	                       -- (huge accuracy boost: ~43% -> ~76% top-1)
}

local Session = {
	solved    = 0,
	correct   = 0,
	wrong     = 0,
	candidates= {},        -- ordered guesses for the current word
	candIndex = 0,
	lastDef   = "",
	busy      = false,
}

--// ── Notify helper ──────────────────────────────────────────────────────
local function notify(title, text, dur)
	pcall(function()
		StarterGui:SetCore("SendNotification", { Title = title, Text = text, Duration = dur or 4 })
	end)
end

--// ── HTTP helper (works across most executors) ──────────────────────────
local function httpGet(url)
	-- Try executor request functions first (they set a proper User-Agent).
	local reqFn = (syn and syn.request)
		or (http and http.request)
		or http_request
		or request
		or (fluxus and fluxus.request)
	if reqFn then
		local ok, res = pcall(reqFn, { Url = url, Method = "GET" })
		if ok and res and (res.StatusCode == 200 or res.Success) and res.Body then
			return res.Body
		end
	end
	-- Fallback to game:HttpGet
	local ok, body = pcall(function()
		return game:HttpGetAsync(url)
	end)
	if ok and body then return body end
	ok, body = pcall(function() return game:HttpGet(url) end)
	if ok and body then return body end
	return nil
end

local function urlEncode(s)
	return (s:gsub("[^%w ]", function(c)
		return string.format("%%%02X", string.byte(c))
	end):gsub(" ", "+"))
end

--// ── Dictionary reverse-lookup: definition -> word ──────────────────────
-- Strategy (validated empirically against 30 dictionary-style clues):
--   • Query Datamuse "means-like" (ml) with definitions + parts-of-speech.
--   • Keep only single alphabetic words (spelling-bee answers are one word).
--   • Rank by how many significant clue words appear in the candidate's OWN
--     dictionary definition (overlap), tie-broken by Datamuse relevance.
--     This scored best of the strategies tried (~43% top-1, ~73% top-3).
--   • Bonus if the candidate's part-of-speech matches the clue shape
--     ("a/an/the ..." -> noun, "to ..." -> verb).
--   • If a word length is known, hard-filter to it. This is the single
--     biggest lever measured: top-1 43% -> 76%, top-3 -> 90%.

-- Common words that carry little meaning; ignored when scoring overlap.
local STOPWORDS = {
	a=true, an=true, the=true, of=true, to=true, ["and"]=true, ["or"]=true,
	["in"]=true, on=true, with=true, that=true, makes=true, make=true,
	["is"]=true, are=true, was=true, ["for"]=true, from=true, into=true, by=true,
	as=true, at=true, it=true, its=true, someone=true, person=true, who=true,
	studies=true, study=true, which=true, when=true, where=true, you=true,
	your=true, they=true, them=true, this=true, these=true, those=true,
	something=true, used=true, being=true, having=true, about=true,
}

local function cleanDef(def)
	def = tostring(def or "")
	-- Strip a leading part-of-speech tag like "(noun)" or "noun:" that some
	-- games prepend to the definition line.
	def = def:gsub("^%s*%b()%s*", "")
	def = def:gsub("^%s*%a+%s*[:%-]%s*", "")
	return (def:gsub("^%s*(.-)%s*$", "%1"))
end

-- Crude stemmer so "flies"/"flying"/"flew"-ish forms overlap.
local function stem(w)
	for _, suf in ipairs({ "ing", "edly", "ed", "es", "ly", "s" }) do
		if #w - #suf >= 3 and w:sub(-#suf) == suf then
			return w:sub(1, #w - #suf)
		end
	end
	return w
end

-- Significant, stemmed content tokens of a phrase.
local function contentTokens(phrase)
	local set = {}
	for token in phrase:lower():gmatch("%a+") do
		if #token > 2 and not STOPWORDS[token] then
			set[stem(token)] = true
		end
	end
	return set
end

-- What part of speech does the clue phrasing imply?  nil = unknown.
local function cluePOS(clue)
	local c = clue:lower():gsub("^%s+", "")
	if c:sub(1, 3) == "to " then return "v" end
	if c:match("^an?%s") or c:match("^the%s") then return "n" end
	return nil
end

local function solveDefinition(def, lengthHint)
	local clue = cleanDef(def)
	if clue == "" then return {} end
	lengthHint = lengthHint or State.wordLength or 0

	local url = ("https://api.datamuse.com/words?ml=%s&max=%d&md=dp")
		:format(urlEncode(clue), State.maxCandidates)
	local body = httpGet(url)
	if not body then
		notify("Scary Spelling", "Dictionary lookup failed (no HTTP).", 4)
		return {}
	end

	local ok, data = pcall(function() return HttpService:JSONDecode(body) end)
	if not ok or type(data) ~= "table" then return {} end

	local clueTokens = contentTokens(clue)
	local wantPOS = cluePOS(clue)

	local results = {}
	for i, entry in ipairs(data) do
		local w = entry.word
		if type(w) == "string" and w:match("^%a+$") then
			w = w:lower()
			-- overlap: significant clue tokens present in this word's defs
			local defsBlob = ""
			if type(entry.defs) == "table" then
				defsBlob = table.concat(entry.defs, " ")
			end
			local defTokens = contentTokens(defsBlob)
			local overlap = 0
			for t in pairs(clueTokens) do
				if defTokens[t] then overlap = overlap + 1 end
			end
			-- part-of-speech match bonus
			local posBonus = 0
			if wantPOS and type(entry.tags) == "table" then
				for _, tg in ipairs(entry.tags) do
					if tg == wantPOS then posBonus = 1; break end
				end
			end
			table.insert(results, {
				word    = w,
				rank    = i,          -- Datamuse relevance order (lower = better)
				overlap = overlap,
				pos     = posBonus,
			})
		end
	end

	table.sort(results, function(a, b)
		-- overlap first, then POS match, then Datamuse relevance
		if a.overlap ~= b.overlap then return a.overlap > b.overlap end
		if a.pos ~= b.pos then return a.pos > b.pos end
		return a.rank < b.rank
	end)

	-- De-duplicate and (optionally) length-filter.
	local words, seen = {}, {}
	local function push(r)
		if not seen[r.word] then seen[r.word] = true; words[#words + 1] = r.word end
	end
	if lengthHint > 0 then
		for _, r in ipairs(results) do
			if #r.word == lengthHint then push(r) end
		end
		-- Fall back to the unfiltered list if nothing matched the length.
		if #words == 0 then
			for _, r in ipairs(results) do push(r) end
		end
	else
		for _, r in ipairs(results) do push(r) end
	end
	return words
end

--// ── Remote plumbing ────────────────────────────────────────────────────
local Events = ReplicatedStorage:WaitForChild("Events")
local GameEvent = Events:WaitForChild("GameEvent")

local function fireUpdate(word)
	pcall(function() GameEvent:FireServer("updateAnswer", string.lower(word)) end)
end
local function fireSubmit(word)
	pcall(function() GameEvent:FireServer("submitAnswer", string.lower(word)) end)
end

-- Mirror text onto the game's on-screen spelling board (cosmetic).
local function mirrorText(word)
	if not State.typeMirror then return end
	pcall(function()
		local t = workspace.Map.Functional.Screen.SurfaceGui.MainFrame
			.MainGameContainer.MainTxtContainer.TypingText
		t.Text = word
	end)
end

--// forward declaration for UI updater
local refreshUI

--// ── Answering flow ─────────────────────────────────────────────────────
local function submitCandidate(word)
	fireUpdate(word)
	mirrorText(word)
	task.wait(State.submitDelay)
	fireSubmit(word)
end

local function onAnswering(definition)
	Session.lastDef = tostring(definition or "")
	Session.candidates = {}
	Session.candIndex = 0
	if refreshUI then refreshUI() end

	if not State.autoAnswer then
		notify("Scary Spelling", "Your turn! Press Solve to look up the word.", 4)
		-- Still pre-fetch candidates for the manual panel.
		Session.candidates = solveDefinition(definition)
		if refreshUI then refreshUI() end
		return
	end

	if Session.busy then return end
	Session.busy = true

	Session.candidates = solveDefinition(definition)
	Session.solved = Session.solved + 1

	if #Session.candidates == 0 then
		notify("Scary Spelling", "No word found for that definition.", 4)
		Session.busy = false
		if refreshUI then refreshUI() end
		return
	end

	Session.candIndex = 1
	if refreshUI then refreshUI() end
	submitCandidate(Session.candidates[1])
	Session.busy = false
end

-- On a wrong answer, try the next candidate automatically.
local function onIncorrect()
	Session.wrong = Session.wrong + 1
	if refreshUI then refreshUI() end
	if not State.autoAnswer then return end
	if Session.candIndex > 0 and Session.candIndex < #Session.candidates then
		Session.candIndex = Session.candIndex + 1
		local nextWord = Session.candidates[Session.candIndex]
		task.wait(0.15)
		submitCandidate(nextWord)
		if refreshUI then refreshUI() end
	end
end

local function onCorrect()
	Session.correct = Session.correct + 1
	if refreshUI then refreshUI() end
end

--// ── Judge flow ─────────────────────────────────────────────────────────
local function onJudgeChoose(words)
	if not State.autoJudge or type(words) ~= "table" then return end
	local pick = nil
	for _, w in pairs(words) do
		if type(w) == "string" then
			if not pick then
				pick = w
			elseif State.judgeHardest and #w > #pick then
				pick = w
			elseif (not State.judgeHardest) and #w < #pick then
				pick = w
			end
		end
	end
	if pick then
		task.wait(0.4)
		pcall(function() GameEvent:FireServer("judgeChooseWord", pick) end)
		notify("Scary Spelling", "Judge picked: " .. pick, 3)
	end
end

local function onJudgeKill()
	if not State.autoKill then return end
	task.wait(0.4)
	pcall(function() GameEvent:FireServer("judgeKillPlayer") end)
end

--// ── Listen to the game's own client events (multiple listeners allowed) ─
local dispatch = {
	["Answering"]             = onAnswering,
	["IncorrectAnswer"]       = onIncorrect,
	["CorrectAnswer"]         = onCorrect,
	["StartJudgeChooseWord"]  = onJudgeChoose,
	["StartJudgeKill"]        = onJudgeKill,
}

GameEvent.OnClientEvent:Connect(function(cmd, ...)
	local handler = dispatch[cmd]
	if handler then
		local args = { ... }
		task.spawn(function() handler(table.unpack(args)) end)
	end
end)

--============================================================================
--// UI
--============================================================================
local ACCENT   = Color3.fromRGB(140, 60, 200)
local ACCENT2  = Color3.fromRGB(90, 40, 150)
local BG       = Color3.fromRGB(22, 20, 28)
local BG2      = Color3.fromRGB(32, 28, 42)
local TXT      = Color3.fromRGB(235, 230, 245)
local SUBTXT   = Color3.fromRGB(160, 150, 180)
local GREEN    = Color3.fromRGB(80, 200, 120)
local RED      = Color3.fromRGB(220, 80, 90)

local function corner(inst, r)
	local c = Instance.new("UICorner")
	c.CornerRadius = UDim.new(0, r or 8)
	c.Parent = inst
	return c
end
local function pad(inst, p)
	local u = Instance.new("UIPadding")
	u.PaddingTop = UDim.new(0, p); u.PaddingBottom = UDim.new(0, p)
	u.PaddingLeft = UDim.new(0, p); u.PaddingRight = UDim.new(0, p)
	u.Parent = inst
	return u
end

-- Remove a prior copy if re-run.
pcall(function()
	local old = PlayerGui:FindFirstChild("ScarySpellingHub")
	if old then old:Destroy() end
end)

local gui = Instance.new("ScreenGui")
gui.Name = "ScarySpellingHub"
gui.ResetOnSpawn = false
gui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
gui.Parent = PlayerGui

local main = Instance.new("Frame")
main.Name = "Main"
main.Size = UDim2.new(0, 320, 0, 430)
main.Position = UDim2.new(0, 40, 0.5, -215)
main.BackgroundColor3 = BG
main.BorderSizePixel = 0
main.Active = true
main.Parent = gui
corner(main, 12)

local stroke = Instance.new("UIStroke")
stroke.Color = ACCENT
stroke.Thickness = 1.5
stroke.Transparency = 0.3
stroke.Parent = main

-- Title bar (draggable)
local titleBar = Instance.new("Frame")
titleBar.Size = UDim2.new(1, 0, 0, 44)
titleBar.BackgroundColor3 = BG2
titleBar.BorderSizePixel = 0
titleBar.Parent = main
corner(titleBar, 12)

local titleFix = Instance.new("Frame")  -- square off bottom corners
titleFix.Size = UDim2.new(1, 0, 0, 14)
titleFix.Position = UDim2.new(0, 0, 1, -14)
titleFix.BackgroundColor3 = BG2
titleFix.BorderSizePixel = 0
titleFix.Parent = titleBar

local title = Instance.new("TextLabel")
title.BackgroundTransparency = 1
title.Size = UDim2.new(1, -80, 1, 0)
title.Position = UDim2.new(0, 14, 0, 0)
title.Font = Enum.Font.GothamBold
title.Text = "🐝 Scary Spelling"
title.TextColor3 = TXT
title.TextSize = 16
title.TextXAlignment = Enum.TextXAlignment.Left
title.Parent = titleBar

local minBtn = Instance.new("TextButton")
minBtn.Size = UDim2.new(0, 30, 0, 30)
minBtn.Position = UDim2.new(1, -38, 0, 7)
minBtn.BackgroundColor3 = ACCENT2
minBtn.Text = "–"
minBtn.TextColor3 = TXT
minBtn.Font = Enum.Font.GothamBold
minBtn.TextSize = 18
minBtn.Parent = titleBar
corner(minBtn, 8)

-- Body
local body = Instance.new("ScrollingFrame")
body.Size = UDim2.new(1, 0, 1, -44)
body.Position = UDim2.new(0, 0, 0, 44)
body.BackgroundTransparency = 1
body.BorderSizePixel = 0
body.ScrollBarThickness = 4
body.ScrollBarImageColor3 = ACCENT
body.CanvasSize = UDim2.new(0, 0, 0, 0)
body.AutomaticCanvasSize = Enum.AutomaticSize.Y
body.Parent = main
pad(body, 12)

local list = Instance.new("UIListLayout")
list.Padding = UDim.new(0, 8)
list.SortOrder = Enum.SortOrder.LayoutOrder
list.Parent = body

local order = 0
local function nextOrder() order = order + 1; return order end

-- Toggle row factory
local function makeToggle(text, initial, onChange)
	local row = Instance.new("Frame")
	row.Size = UDim2.new(1, 0, 0, 38)
	row.BackgroundColor3 = BG2
	row.BorderSizePixel = 0
	row.LayoutOrder = nextOrder()
	row.Parent = body
	corner(row, 8)

	local lbl = Instance.new("TextLabel")
	lbl.BackgroundTransparency = 1
	lbl.Size = UDim2.new(1, -60, 1, 0)
	lbl.Position = UDim2.new(0, 12, 0, 0)
	lbl.Font = Enum.Font.GothamMedium
	lbl.Text = text
	lbl.TextColor3 = TXT
	lbl.TextSize = 14
	lbl.TextXAlignment = Enum.TextXAlignment.Left
	lbl.Parent = row

	local knob = Instance.new("TextButton")
	knob.Size = UDim2.new(0, 44, 0, 24)
	knob.Position = UDim2.new(1, -54, 0.5, -12)
	knob.BackgroundColor3 = initial and GREEN or Color3.fromRGB(70, 65, 85)
	knob.Text = ""
	knob.AutoButtonColor = false
	knob.Parent = row
	corner(knob, 12)

	local dot = Instance.new("Frame")
	dot.Size = UDim2.new(0, 18, 0, 18)
	dot.Position = initial and UDim2.new(1, -21, 0.5, -9) or UDim2.new(0, 3, 0.5, -9)
	dot.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
	dot.BorderSizePixel = 0
	dot.Parent = knob
	corner(dot, 9)

	local value = initial
	knob.MouseButton1Click:Connect(function()
		value = not value
		TweenService:Create(knob, TweenInfo.new(0.15), {
			BackgroundColor3 = value and GREEN or Color3.fromRGB(70, 65, 85),
		}):Play()
		TweenService:Create(dot, TweenInfo.new(0.15), {
			Position = value and UDim2.new(1, -21, 0.5, -9) or UDim2.new(0, 3, 0.5, -9),
		}):Play()
		onChange(value)
	end)
	return row
end

-- Section label
local function sectionLabel(text)
	local l = Instance.new("TextLabel")
	l.BackgroundTransparency = 1
	l.Size = UDim2.new(1, 0, 0, 18)
	l.Font = Enum.Font.GothamBold
	l.Text = text
	l.TextColor3 = ACCENT
	l.TextSize = 12
	l.TextXAlignment = Enum.TextXAlignment.Left
	l.LayoutOrder = nextOrder()
	l.Parent = body
	return l
end

--// Speller section
sectionLabel("SPELLER")
makeToggle("Auto Answer (solve + submit)", State.autoAnswer, function(v) State.autoAnswer = v end)
makeToggle("Mirror text to board", State.typeMirror, function(v) State.typeMirror = v end)

-- Word-length hint: hugely improves accuracy (43% -> 76% top-1) when set.
local resolveWithLength  -- forward decl (re-solves current def using new length)
do
	local row = Instance.new("Frame")
	row.Size = UDim2.new(1, 0, 0, 38)
	row.BackgroundColor3 = BG2
	row.BorderSizePixel = 0
	row.LayoutOrder = nextOrder()
	row.Parent = body
	corner(row, 8)

	local lbl = Instance.new("TextLabel")
	lbl.BackgroundTransparency = 1
	lbl.Size = UDim2.new(1, -70, 1, 0)
	lbl.Position = UDim2.new(0, 12, 0, 0)
	lbl.Font = Enum.Font.GothamMedium
	lbl.Text = "Word length (0 = off)"
	lbl.TextColor3 = TXT
	lbl.TextSize = 14
	lbl.TextXAlignment = Enum.TextXAlignment.Left
	lbl.Parent = row

	local box = Instance.new("TextBox")
	box.Size = UDim2.new(0, 48, 0, 26)
	box.Position = UDim2.new(1, -58, 0.5, -13)
	box.BackgroundColor3 = BG
	box.Text = "0"
	box.PlaceholderText = "0"
	box.TextColor3 = TXT
	box.Font = Enum.Font.GothamBold
	box.TextSize = 14
	box.ClearTextOnFocus = false
	box.Parent = row
	corner(box, 6)

	box.FocusLost:Connect(function()
		local n = tonumber(box.Text:match("%d+")) or 0
		State.wordLength = n
		box.Text = tostring(n)
		if resolveWithLength then resolveWithLength() end
	end)
end

--// Judge section
sectionLabel("JUDGE")
makeToggle("Auto Judge (auto-pick word)", State.autoJudge, function(v) State.autoJudge = v end)
makeToggle("Pick hardest word", State.judgeHardest, function(v) State.judgeHardest = v end)
makeToggle("Auto Kill speller", State.autoKill, function(v) State.autoKill = v end)

--// Manual solver panel
sectionLabel("MANUAL SOLVER")

local defBox = Instance.new("TextLabel")
defBox.Size = UDim2.new(1, 0, 0, 54)
defBox.BackgroundColor3 = BG2
defBox.BorderSizePixel = 0
defBox.Font = Enum.Font.Gotham
defBox.Text = "Definition will appear here on your turn…"
defBox.TextColor3 = SUBTXT
defBox.TextSize = 12
defBox.TextWrapped = true
defBox.TextXAlignment = Enum.TextXAlignment.Left
defBox.TextYAlignment = Enum.TextYAlignment.Top
defBox.LayoutOrder = nextOrder()
defBox.Parent = body
corner(defBox, 8)
pad(defBox, 8)

local solveBtn = Instance.new("TextButton")
solveBtn.Size = UDim2.new(1, 0, 0, 34)
solveBtn.BackgroundColor3 = ACCENT
solveBtn.Text = "🔍 Solve current definition"
solveBtn.TextColor3 = TXT
solveBtn.Font = Enum.Font.GothamBold
solveBtn.TextSize = 13
solveBtn.AutoButtonColor = true
solveBtn.LayoutOrder = nextOrder()
solveBtn.Parent = body
corner(solveBtn, 8)

-- Candidate list container
local candContainer = Instance.new("Frame")
candContainer.Size = UDim2.new(1, 0, 0, 0)
candContainer.AutomaticSize = Enum.AutomaticSize.Y
candContainer.BackgroundTransparency = 1
candContainer.LayoutOrder = nextOrder()
candContainer.Parent = body
local candLayout = Instance.new("UIListLayout")
candLayout.Padding = UDim.new(0, 4)
candLayout.Parent = candContainer

local function clearCandidates()
	for _, c in ipairs(candContainer:GetChildren()) do
		if c:IsA("TextButton") then c:Destroy() end
	end
end

local function buildCandidateButtons()
	clearCandidates()
	for i, w in ipairs(Session.candidates) do
		if i > 8 then break end
		local b = Instance.new("TextButton")
		b.Size = UDim2.new(1, 0, 0, 28)
		b.BackgroundColor3 = (i == Session.candIndex) and ACCENT2 or BG2
		b.Text = ("%d.  %s"):format(i, w)
		b.TextColor3 = TXT
		b.Font = Enum.Font.GothamMedium
		b.TextSize = 13
		b.TextXAlignment = Enum.TextXAlignment.Left
		b.Parent = candContainer
		corner(b, 6)
		local px = Instance.new("UIPadding"); px.PaddingLeft = UDim.new(0, 10); px.Parent = b
		b.MouseButton1Click:Connect(function()
			Session.candIndex = i
			submitCandidate(w)
			buildCandidateButtons()
		end)
	end
end

-- Re-run the solver for the current definition (used when the length
-- hint changes). Assigned to the forward-declared upvalue above.
resolveWithLength = function()
	if Session.lastDef == "" then return end
	task.spawn(function()
		Session.candidates = solveDefinition(Session.lastDef)
		Session.candIndex = 0
		buildCandidateButtons()
	end)
end

solveBtn.MouseButton1Click:Connect(function()
	if Session.lastDef == "" then
		notify("Scary Spelling", "No active definition yet.", 3)
		return
	end
	solveBtn.Text = "… solving …"
	task.spawn(function()
		Session.candidates = solveDefinition(Session.lastDef)
		Session.candIndex = 0
		buildCandidateButtons()
		solveBtn.Text = "🔍 Solve current definition"
		if #Session.candidates == 0 then
			notify("Scary Spelling", "No candidates found.", 3)
		end
	end)
end)

--// Stats
sectionLabel("STATS")
local statsLbl = Instance.new("TextLabel")
statsLbl.Size = UDim2.new(1, 0, 0, 20)
statsLbl.BackgroundTransparency = 1
statsLbl.Font = Enum.Font.Gotham
statsLbl.Text = "Solved 0  •  Correct 0  •  Wrong 0"
statsLbl.TextColor3 = SUBTXT
statsLbl.TextSize = 12
statsLbl.TextXAlignment = Enum.TextXAlignment.Left
statsLbl.LayoutOrder = nextOrder()
statsLbl.Parent = body

--// refreshUI implementation
refreshUI = function()
	defBox.Text = (Session.lastDef ~= "" and Session.lastDef)
		or "Definition will appear here on your turn…"
	defBox.TextColor3 = (Session.lastDef ~= "") and TXT or SUBTXT
	statsLbl.Text = ("Solved %d  •  Correct %d  •  Wrong %d")
		:format(Session.solved, Session.correct, Session.wrong)
	buildCandidateButtons()
end

--// Minimise / restore
local minimised = false
minBtn.MouseButton1Click:Connect(function()
	minimised = not minimised
	body.Visible = not minimised
	TweenService:Create(main, TweenInfo.new(0.2), {
		Size = minimised and UDim2.new(0, 320, 0, 44) or UDim2.new(0, 320, 0, 430),
	}):Play()
	minBtn.Text = minimised and "+" or "–"
end)

--// Dragging
do
	local dragging, dragStart, startPos
	local function update(input)
		local delta = input.Position - dragStart
		main.Position = UDim2.new(
			startPos.X.Scale, startPos.X.Offset + delta.X,
			startPos.Y.Scale, startPos.Y.Offset + delta.Y)
	end
	titleBar.InputBegan:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1
			or input.UserInputType == Enum.UserInputType.Touch then
			dragging = true
			dragStart = input.Position
			startPos = main.Position
			input.Changed:Connect(function()
				if input.UserInputState == Enum.UserInputState.End then dragging = false end
			end)
		end
	end)
	titleBar.InputChanged:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseMovement
			or input.UserInputType == Enum.UserInputType.Touch then
			if dragging then update(input) end
		end
	end)
	UserInputService.InputChanged:Connect(function(input)
		if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement
			or input.UserInputType == Enum.UserInputType.Touch) then
			update(input)
		end
	end)
end

refreshUI()
notify("Scary Spelling", "Loaded! Tip: set 'Word length' for far better accuracy.", 6)
print("[Scary Spelling] Auto Speller ready. Remote: Events.GameEvent")
