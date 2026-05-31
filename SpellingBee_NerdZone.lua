-- ═══════════════════════════════════════════════════════════════════════
--  Preppy Hub  |  Spelling Bee  v2.2
--  Delta iOS/iPad + PC  —  pure native GUI, no HTTP dependency
--  Auto-detects game from PlaceId
-- ═══════════════════════════════════════════════════════════════════════

local Players     = game:GetService("Players")
local UIS         = game:GetService("UserInputService")
local RunService  = game:GetService("RunService")
local VirtualUser = game:GetService("VirtualUser")
local RS          = game:GetService("ReplicatedStorage")
local WS          = game:GetService("Workspace")
local TW          = game:GetService("TweenService")
local StarterGui  = game:GetService("StarterGui")
local LP          = Players.LocalPlayer
local PGui        = LP:WaitForChild("PlayerGui")
local isMobile    = UIS.TouchEnabled

-- ── Game detection (from PlaceId) ──────────────────────────────────────
-- Place IDs sourced from the PreppyHub game map
local KNOWN_GAMES = {
    [74779072921656]  = "NerdZone Spelling Bee",
    [17590362521]     = "Spelling Bee",
    [83091000527113]  = "Spelling Bee",
    [17707569217]     = "Spelling Bee",
    [91692552632068]  = "Scary Spelling Bee",
    [133419989757748] = "Bean Cans Spelling Bee",
    [70718852079605]  = "Spelling Bee",
    [115840692772844] = "Spelling Bee",
    [135159688166294] = "Spelling Bee",
}
local GAME_NAME = KNOWN_GAMES[game.PlaceId] or "Spelling Bee"
local IS_KNOWN  = KNOWN_GAMES[game.PlaceId] ~= nil

local function notify(title, text, dur)
    pcall(function()
        StarterGui:SetCore("SendNotification", {Title=title, Text=text, Duration=dur or 4})
    end)
end

notify("Preppy Hub  |  " .. GAME_NAME, IS_KNOWN and "Game detected!" or "Unknown game — universal mode", 3)

-- ── State ─────────────────────────────────────────────────────────────
local botEnabled   = true
local submitDelay  = 0.05
local currentWord  = ""
local answerRemote = nil
local antiAFK      = false
local infJump      = false
local walkSpd      = 16
local jumpPwr      = 50

-- ── Session Stats ──────────────────────────────────────────────────────
local sessionStart = os.clock()
local wordsTyped   = 0
local bestWPM      = 0
local mistakes     = 0

local function getWPM()
    local mins = (os.clock() - sessionStart) / 60
    if mins < 0.01 then return 0 end
    return math.floor(wordsTyped / mins)
end

-- ── UI update handles (set after GUI build) ────────────────────────────
local nWord, nWords, nWpm, nBest, nMist, nAcc

local function updateStats()
    if not nWords then return end
    local wpm = getWPM()
    if wpm > bestWPM then bestWPM = wpm end
    nWords.Text = "Words Typed\n" .. wordsTyped
    nWpm.Text   = "Avg WPM\n"    .. wpm
    nBest.Text  = "Best WPM\n"   .. bestWPM
    nMist.Text  = "Mistakes\n"   .. mistakes
    local acc   = wordsTyped == 0 and 100
                  or math.floor(((wordsTyped - mistakes) / wordsTyped) * 100)
    nAcc.Text   = "Accuracy\n"   .. acc .. "%"
end

-- ═══════════════════════════════════════════════════════════════════════
--  WORD DETECTION + SUBMISSION
-- ═══════════════════════════════════════════════════════════════════════

local UI_BL = {
    spellingbee=1,nerdzone=1,preppyhub=1,preppy=1,hub=1,
    submit=1,answer=1,play=1,reset=1,start=1,continue=1,
    back=1,close=1,menu=1,quit=1,exit=1,enabled=1,disabled=1,
    loading=1,loaded=1,waiting=1,ready=1,error=1,failed=1,
    roblox=1,studio=1,player=1,server=1,client=1,remote=1,
}

local function looksLikeWord(s)
    if type(s) ~= "string" then return false end
    if #s < 2 or #s > 100 then return false end  -- covers any real word
    if not s:match("^%a+$") then return false end
    return not UI_BL[s:lower()]
end

local submitAnswer  -- forward declared

local function onWordFound(w)
    w = w:lower()
    if w == currentWord then return end
    currentWord = w
    if nWord then nWord.Text = w:upper() end
    if botEnabled then task.delay(submitDelay, function() submitAnswer(w) end) end
end

-- Broad keyword list — covers NerdZone Spelling Bee, Scary Spelling Bee,
-- Bean Cans Spelling Bee and any other spelling/word game
local ANSWER_KEYS = {
    "submit","answer","spell","type","guess","check","input",
    "word","attempt","confirm","enter","send","fire","respond",
    "bean","can","scary","horror","spook","round","solve",
}
local function isAnswerRemote(name)
    local n = name:lower()
    for _, k in ipairs(ANSWER_KEYS) do if n:find(k,1,true) then return true end end
    return false
end

-- Search every container for a matching answer remote
local function findAnswerRemote()
    if answerRemote and answerRemote.Parent then return answerRemote end
    answerRemote = nil
    for _, root in ipairs(SCAN_ROOTS) do
        local ok, r = pcall(function()
            for _, obj in ipairs(root:GetDescendants()) do
                if obj:IsA("RemoteEvent") and isAnswerRemote(obj.Name) then
                    return obj
                end
            end
        end)
        if ok and r then answerRemote = r; return r end
    end
    return nil
end

-- Last-resort: fire every RemoteEvent in RS + WS with the word.
-- Used when no named answer remote is found (unknown game structure).
local function fireAllRemotes(word)
    local fired = false
    local function blast(root)
        for _, r in ipairs(root:GetDescendants()) do
            if r:IsA("RemoteEvent") then
                pcall(function() r:FireServer(word) end)
                fired = true
            end
        end
    end
    blast(RS); blast(WS)
    return fired
end

-- Genius-level static typing: 40 ms per character, no randomness
-- ~250 WPM burst speed — world-class typist territory
local CHAR_MS = 0.040

local function humanTypeBox(box, word)
    box.Text = ""
    box:CaptureFocus()
    task.wait(0.035)
    for i = 1, #word do
        box.Text = word:sub(1, i)
        task.wait(CHAR_MS)
    end
    task.wait(0.035)
    box:ReleaseFocus(true)
end

local function fireAnswer(word)
    task.wait(#word * CHAR_MS)  -- typing time delay regardless of path
    local r = findAnswerRemote()
    if r then
        pcall(function() r:FireServer(word) end)
        return true
    end
    -- No named remote found — broadcast to all (unknown game fallback)
    return fireAllRemotes(word)
end

local function boxSubmit(word)
    local function tryBoxes(root)
        for _, obj in ipairs(root:GetDescendants()) do
            if obj:IsA("TextBox") and obj.TextEditable and obj.Visible then
                humanTypeBox(obj, word)
                return true
            end
        end
    end
    return tryBoxes(PGui) or tryBoxes(WS) or false
end

submitAnswer = function(word)
    if word == "" then return end
    if fireAnswer(word) or boxSubmit(word) then
        wordsTyped += 1; updateStats()
    end
end

-- ═══════════════════════════════════════════════════════════════════════
--  HOOKS
--  Technique sourced from repo's src/tabs/05_remotespy.lua +
--  src/core/02_bridge.lua  (ChildAdded live-watch pattern)
-- ═══════════════════════════════════════════════════════════════════════

-- Scan all args (any depth) for a word-like value; return it or nil
local function extractWord(args)
    for _, v in ipairs(args) do
        if looksLikeWord(v) then return v end
        if type(v) == "table" then
            for _, tv in pairs(v) do
                if looksLikeWord(tv) then return tv end
            end
        end
        if type(v) == "string" then
            local w = v:match("([%a][%a]+)")
            if w and looksLikeWord(w) then return w end
        end
    end
end

-- Hook one RemoteEvent for incoming server→client words (OnClientEvent)
local _hooked = {}
local function hookOne(remote)
    if _hooked[remote] then return end
    _hooked[remote] = true
    remote.OnClientEvent:Connect(function(...)
        local w = extractWord({...})
        if w then task.spawn(onWordFound, w) end
    end)
end

-- Also hook RemoteFunction.OnClientInvoke for games that use RF to deliver words
local _hookedRF = {}
local function hookOneRF(rf)
    if _hookedRF[rf] then return end
    _hookedRF[rf] = true
    rf.OnClientInvoke = function(...)
        local w = extractWord({...})
        if w then task.spawn(onWordFound, w) end
    end
end

-- Hook every RE + RF across all game containers
local function hookIncoming()
    for _, root in ipairs(SCAN_ROOTS) do
        pcall(function()
            for _, r in ipairs(root:GetDescendants()) do
                if r:IsA("RemoteEvent")    then hookOne(r)
                elseif r:IsA("RemoteFunction") then hookOneRF(r) end
            end
        end)
    end
end

-- ── __namecall hook (from 05_remotespy.lua pattern) ────────────────────
-- Uses `local _old; _old =` so the upvalue is valid inside the closure.
-- Intercepts FireServer + InvokeServer outgoing calls to:
--   1. Learn which remote the game uses for answers
--   2. Inject our word when the player would have fired manually
local function installNamecallHook()
    if not hookmetamethod or not newcclosure or not getnamecallmethod then return false end
    local ok = pcall(function()
        local _old; _old = hookmetamethod(game, "__namecall", newcclosure(function(self, ...)
            local m = getnamecallmethod()

            -- Only care about outgoing remote calls
            if m == "FireServer" or m == "InvokeServer" then
                local isRE = pcall(function() return self:IsA("RemoteEvent") end)
                local isRF = pcall(function() return self:IsA("RemoteFunction") end)

                if isRE or isRF then
                    -- Clean name (matches remotespy's tostring trick)
                    local rname = tostring(self):match("^(.+) %(") or tostring(self)

                    -- Learn: any outgoing call whose first arg looks like a word
                    -- is almost certainly the answer submission remote
                    local args = {...}
                    local learnedWord = extractWord(args)
                    if learnedWord and self:IsA("RemoteEvent") then
                        answerRemote = self
                    end

                    -- Override: known answer remote + bot on → inject our word
                    if isAnswerRemote(rname) and botEnabled and currentWord ~= "" then
                        if self:IsA("RemoteEvent") then
                            answerRemote = self
                            return _old(self, currentWord)
                        end
                    end
                end
            end

            return _old(self, ...)
        end))
    end)
    return ok
end

-- ── Live remote watcher (from src/core/02_bridge.lua pattern) ──────────
-- Watches ChildAdded at the top level of each container AND DescendantAdded
-- on the whole game for anything deeper. Covers late-replicated remotes.
local function startLiveWatch()
    -- Per-container top-level watch
    for _, root in ipairs(SCAN_ROOTS) do
        pcall(function()
            root.ChildAdded:Connect(function(ch)
                if ch:IsA("RemoteEvent")    then task.wait(); hookOne(ch)
                elseif ch:IsA("RemoteFunction") then task.wait(); hookOneRF(ch) end
            end)
        end)
    end
    -- Deep watch for everything else anywhere in the game
    game.DescendantAdded:Connect(function(obj)
        if obj:IsA("RemoteEvent")    then task.wait(); hookOne(obj)
        elseif obj:IsA("RemoteFunction") then task.wait(); hookOneRF(obj)
        elseif obj:IsA("StringValue") and isSVKey(obj.Name) then watchSV(obj) end
    end)
end

local _watchedSV = {}
local function watchSV(sv)
    if _watchedSV[sv] then return end
    _watchedSV[sv] = true
    sv.Changed:Connect(function(v) if looksLikeWord(v) then onWordFound(v) end end)
    if looksLikeWord(sv.Value) then onWordFound(sv.Value) end
end

-- Intentionally broad — catches any StringValue whose name hints at a word/prompt
local SV_KEYS = {
    "word","spell","current","target","prompt","letter","round",
    "question","answer","display","show","text","challenge","bean","scary",
}
local function isSVKey(name)
    local n = name:lower()
    for _, k in ipairs(SV_KEYS) do if n:find(k,1,true) then return true end end
    return false
end

local function hookSVs(root)
    for _, obj in ipairs(root:GetDescendants()) do
        if obj:IsA("StringValue") and isSVKey(obj.Name) then watchSV(obj) end
    end
end

-- All game containers to scan — covers every service that can hold remotes/values
local SCAN_ROOTS = {
    RS,
    WS,
    game:GetService("ReplicatedFirst"),
    PGui,
    LP,
}
pcall(function() table.insert(SCAN_ROOTS, LP.Backpack) end)
pcall(function() table.insert(SCAN_ROOTS, LP.Character) end)

local function scanLabels(root)
    local best, score = nil, -1
    for _, obj in ipairs(root:GetDescendants()) do
        if obj:IsA("TextLabel") and obj.Visible and obj.Text ~= "" then
            local t = obj.Text:match("^%s*(.-)%s*$") or ""
            if looksLikeWord(t) then
                local s = #t + (obj.TextSize >= 20 and 50 or 0)
                if s > score then best=t; score=s end
            end
        end
    end
    return best
end

local function getHumanoid()
    local c = LP.Character; return c and c:FindFirstChildOfClass("Humanoid")
end

-- ═══════════════════════════════════════════════════════════════════════
--  GUI  —  Preppy Hub style
-- ═══════════════════════════════════════════════════════════════════════

local old = PGui:FindFirstChild("__PrepSpellHub__")
if old then old:Destroy() end

local SG = Instance.new("ScreenGui")
SG.Name="__PrepSpellHub__"; SG.ResetOnSpawn=false
SG.IgnoreGuiInset=true; SG.DisplayOrder=999
SG.ZIndexBehavior=Enum.ZIndexBehavior.Sibling
local guiParent = PGui
pcall(function() if gethui then guiParent=gethui() end end)
SG.Parent = guiParent

-- Palette
local PINK   = Color3.fromRGB(232, 90,  160)
local PINK2  = Color3.fromRGB(255,130, 190)
local DARK   = Color3.fromRGB( 16,  16,  24)
local CARD   = Color3.fromRGB( 26,  26,  40)
local CARD2  = Color3.fromRGB( 34,  34,  54)
local WHITE  = Color3.fromRGB(255, 255, 255)
local LGRAY  = Color3.fromRGB(190, 185, 210)
local GREEN  = Color3.fromRGB( 65, 200, 110)
local GRAY   = Color3.fromRGB( 60,  60,  88)

local W = isMobile and 310 or 330
local H = isMobile and 530 or 510

local WIN = Instance.new("Frame")
WIN.Size             = UDim2.new(0,W,0,H)
WIN.Position         = isMobile and UDim2.new(0.5,-W/2,0,50) or UDim2.new(0.5,-W/2,0.5,-H/2)
WIN.BackgroundColor3 = DARK
WIN.BorderSizePixel  = 0
WIN.Active           = true
WIN.Parent           = SG
Instance.new("UICorner",WIN).CornerRadius = UDim.new(0,14)
local _ws=Instance.new("UIStroke",WIN); _ws.Color=PINK; _ws.Thickness=1.5

-- ── Title bar ──────────────────────────────────────────────────────────
local BAR = Instance.new("Frame", WIN)
BAR.Size=UDim2.new(1,0,0,52); BAR.BackgroundColor3=CARD; BAR.BorderSizePixel=0
Instance.new("UICorner",BAR).CornerRadius=UDim.new(0,14)
-- cover bottom radius so it blends into body
local _bfix=Instance.new("Frame",BAR)
_bfix.Size=UDim2.new(1,0,0,14); _bfix.Position=UDim2.new(0,0,1,-14)
_bfix.BackgroundColor3=CARD; _bfix.BorderSizePixel=0

-- pink left stripe
local stripe=Instance.new("Frame",BAR)
stripe.Size=UDim2.new(0,4,0,28); stripe.Position=UDim2.new(0,12,0.5,-14)
stripe.BackgroundColor3=PINK; stripe.BorderSizePixel=0
Instance.new("UICorner",stripe).CornerRadius=UDim.new(1,0)

local titleLbl=Instance.new("TextLabel",BAR)
titleLbl.Size=UDim2.new(1,-90,0,20); titleLbl.Position=UDim2.new(0,22,0,8)
titleLbl.BackgroundTransparency=1; titleLbl.Text="Preppy Hub  |  " .. GAME_NAME
titleLbl.TextColor3=WHITE; titleLbl.Font=Enum.Font.GothamBold
titleLbl.TextSize=13; titleLbl.TextXAlignment=Enum.TextXAlignment.Left

local verLbl=Instance.new("TextLabel",BAR)
verLbl.Size=UDim2.new(1,-90,0,14); verLbl.Position=UDim2.new(0,22,0,30)
verLbl.BackgroundTransparency=1; verLbl.Text="Version 2.2  •  " .. (isMobile and "iPad" or "PC") .. (IS_KNOWN and "" or "  •  Universal")
verLbl.TextColor3=LGRAY; verLbl.Font=Enum.Font.Gotham
verLbl.TextSize=10; verLbl.TextXAlignment=Enum.TextXAlignment.Left

local closeBtn=Instance.new("TextButton",BAR)
closeBtn.Size=UDim2.new(0,26,0,26); closeBtn.Position=UDim2.new(1,-36,0.5,-13)
closeBtn.BackgroundColor3=Color3.fromRGB(180,40,80); closeBtn.Text="✕"
closeBtn.TextColor3=WHITE; closeBtn.Font=Enum.Font.GothamBold; closeBtn.TextSize=12
closeBtn.BorderSizePixel=0
Instance.new("UICorner",closeBtn).CornerRadius=UDim.new(1,0)
closeBtn.MouseButton1Click:Connect(function() SG:Destroy() end)

-- Drag
local _d,_dx,_dy,_wx,_wy=false,0,0,0,0
BAR.InputBegan:Connect(function(i)
    local t=i.UserInputType
    if t==Enum.UserInputType.MouseButton1 or t==Enum.UserInputType.Touch then
        if _d and t==Enum.UserInputType.Touch then return end
        _d=true; _dx=i.Position.X; _dy=i.Position.Y
        _wx=WIN.AbsolutePosition.X; _wy=WIN.AbsolutePosition.Y
    end
end)
UIS.InputChanged:Connect(function(i)
    if not _d then return end
    local t=i.UserInputType
    if t==Enum.UserInputType.MouseMovement or t==Enum.UserInputType.Touch then
        WIN.Position=UDim2.new(0,_wx+i.Position.X-_dx,0,_wy+i.Position.Y-_dy)
    end
end)
UIS.InputEnded:Connect(function(i)
    if i.UserInputType==Enum.UserInputType.MouseButton1 or i.UserInputType==Enum.UserInputType.Touch then
        _d=false
    end
end)

-- ── Scrollable body ────────────────────────────────────────────────────
local SC=Instance.new("ScrollingFrame",WIN)
SC.Size=UDim2.new(1,-8,1,-58); SC.Position=UDim2.new(0,4,0,54)
SC.BackgroundTransparency=1; SC.BorderSizePixel=0
SC.ScrollBarThickness=3; SC.ScrollBarImageColor3=PINK
SC.CanvasSize=UDim2.new(0,0,0,0); SC.AutomaticCanvasSize=Enum.AutomaticSize.Y
local _ll=Instance.new("UIListLayout",SC); _ll.Padding=UDim.new(0,6); _ll.SortOrder=Enum.SortOrder.LayoutOrder
local _pd=Instance.new("UIPadding",SC)
_pd.PaddingTop=UDim.new(0,6); _pd.PaddingLeft=UDim.new(0,4); _pd.PaddingRight=UDim.new(0,4)

-- Helper: section header label
local function secHdr(txt)
    local f=Instance.new("Frame",SC); f.Size=UDim2.new(1,0,0,18); f.BackgroundTransparency=1; f.BorderSizePixel=0
    local l=Instance.new("TextLabel",f); l.Size=UDim2.new(1,0,1,0)
    l.BackgroundTransparency=1; l.Text=txt:upper()
    l.TextColor3=PINK; l.Font=Enum.Font.GothamBold; l.TextSize=9
    l.TextXAlignment=Enum.TextXAlignment.Left
end

-- Helper: full-width card
local function card(h)
    local f=Instance.new("Frame",SC); f.Size=UDim2.new(1,0,0,h)
    f.BackgroundColor3=CARD; f.BorderSizePixel=0
    Instance.new("UICorner",f).CornerRadius=UDim.new(0,8)
    return f
end

-- Helper: big action button
local function bigBtn(txt, col, cb)
    local b=Instance.new("TextButton",SC); b.Size=UDim2.new(1,0,0,38)
    b.BackgroundColor3=col; b.Text=txt; b.TextColor3=WHITE
    b.Font=Enum.Font.GothamBold; b.TextSize=13; b.BorderSizePixel=0
    Instance.new("UICorner",b).CornerRadius=UDim.new(0,8)
    b.MouseButton1Click:Connect(cb); return b
end

-- ── WORD DISPLAY ───────────────────────────────────────────────────────
local wordCard = card(56)
local wordTitleL = Instance.new("TextLabel",wordCard)
wordTitleL.Size=UDim2.new(1,0,0,16); wordTitleL.Position=UDim2.new(0,12,0,6)
wordTitleL.BackgroundTransparency=1; wordTitleL.Text="CURRENT WORD"
wordTitleL.TextColor3=PINK; wordTitleL.Font=Enum.Font.GothamBold
wordTitleL.TextSize=9; wordTitleL.TextXAlignment=Enum.TextXAlignment.Left

nWord = Instance.new("TextLabel",wordCard)
nWord.Size=UDim2.new(1,-16,0,28); nWord.Position=UDim2.new(0,12,0,22)
nWord.BackgroundTransparency=1; nWord.Text="—"
nWord.TextColor3=WHITE; nWord.Font=Enum.Font.GothamBold
nWord.TextSize=20; nWord.TextXAlignment=Enum.TextXAlignment.Left

-- ── AUTO TYPE TOGGLE ───────────────────────────────────────────────────
secHdr("Controls")

local togCard = card(52)

local togTitle=Instance.new("TextLabel",togCard)
togTitle.Size=UDim2.new(0.5,0,1,0); togTitle.Position=UDim2.new(0,14,0,0)
togTitle.BackgroundTransparency=1; togTitle.Text="Auto Type"
togTitle.TextColor3=WHITE; togTitle.Font=Enum.Font.GothamBold
togTitle.TextSize=14; togTitle.TextXAlignment=Enum.TextXAlignment.Left

local togSub=Instance.new("TextLabel",togCard)
togSub.Size=UDim2.new(0.5,0,0,14); togSub.Position=UDim2.new(0,14,1,-20)
togSub.BackgroundTransparency=1; togSub.Text="Auto-answers each word"
togSub.TextColor3=LGRAY; togSub.Font=Enum.Font.Gotham
togSub.TextSize=9; togSub.TextXAlignment=Enum.TextXAlignment.Left

-- pill toggle
local togSt = true
local togPill=Instance.new("TextButton",togCard)
togPill.Size=UDim2.new(0,52,0,26); togPill.Position=UDim2.new(1,-64,0.5,-13)
togPill.BackgroundColor3=PINK; togPill.Text=""; togPill.BorderSizePixel=0
Instance.new("UICorner",togPill).CornerRadius=UDim.new(1,0)

local togKnob=Instance.new("Frame",togPill); togKnob.Size=UDim2.new(0,20,0,20)
togKnob.Position=UDim2.new(1,-22,0.5,-10); togKnob.BackgroundColor3=WHITE; togKnob.BorderSizePixel=0
Instance.new("UICorner",togKnob).CornerRadius=UDim.new(1,0)

local togStatusL=Instance.new("TextLabel",togPill)
togStatusL.Size=UDim2.new(1,0,0,10); togStatusL.Position=UDim2.new(0,4,0.5,-5)
togStatusL.BackgroundTransparency=1; togStatusL.Text="ON"
togStatusL.TextColor3=WHITE; togStatusL.Font=Enum.Font.GothamBold
togStatusL.TextSize=8; togStatusL.TextXAlignment=Enum.TextXAlignment.Left

local TI=TweenInfo.new(0.15)
togPill.MouseButton1Click:Connect(function()
    togSt=not togSt; botEnabled=togSt
    TW:Create(togPill,TI,{BackgroundColor3=togSt and PINK or GRAY}):Play()
    TW:Create(togKnob,TI,{Position=togSt and UDim2.new(1,-22,0.5,-10) or UDim2.new(0,2,0.5,-10)}):Play()
    togStatusL.Text=togSt and "ON" or ""
end)

-- Delay stepper
local delCard=card(42)
local delV=50
local delLbl=Instance.new("TextLabel",delCard)
delLbl.Size=UDim2.new(0.6,0,1,0); delLbl.Position=UDim2.new(0,14,0,0)
delLbl.BackgroundTransparency=1; delLbl.Text="Submit Delay:  50ms"
delLbl.TextColor3=LGRAY; delLbl.Font=Enum.Font.Gotham; delLbl.TextSize=12
delLbl.TextXAlignment=Enum.TextXAlignment.Left

local function delBtnMk(sign, xp)
    local b=Instance.new("TextButton",delCard); b.Size=UDim2.new(0,28,0,22); b.Position=xp
    b.BackgroundColor3=CARD2; b.Text=sign; b.TextColor3=WHITE
    b.Font=Enum.Font.GothamBold; b.TextSize=14; b.BorderSizePixel=0
    Instance.new("UICorner",b).CornerRadius=UDim.new(0,5)
    b.MouseButton1Click:Connect(function()
        delV=math.clamp(delV+(sign=="-" and -10 or 10),0,2000)
        delLbl.Text="Submit Delay:  "..delV.."ms"; submitDelay=delV/1000
    end)
end
delBtnMk("-", UDim2.new(0.64,0,0.5,-11))
delBtnMk("+", UDim2.new(0.82,0,0.5,-11))

-- ── SESSION STATS ──────────────────────────────────────────────────────
secHdr("Session Stats")

-- 2×3 stat grid
local gridFrame=Instance.new("Frame",SC)
gridFrame.Size=UDim2.new(1,0,0,0); gridFrame.AutomaticSize=Enum.AutomaticSize.Y
gridFrame.BackgroundTransparency=1; gridFrame.BorderSizePixel=0
local gridLL=Instance.new("UIGridLayout",gridFrame)
gridLL.CellSize=UDim2.new(0.5,-4,0,52); gridLL.CellPadding=UDim2.new(0,6,0,6)
gridLL.SortOrder=Enum.SortOrder.LayoutOrder

local function statCell(label, color)
    local f=Instance.new("Frame",gridFrame); f.BackgroundColor3=CARD; f.BorderSizePixel=0
    Instance.new("UICorner",f).CornerRadius=UDim.new(0,8)
    -- top color bar
    local bar=Instance.new("Frame",f); bar.Size=UDim2.new(1,0,0,3); bar.Position=UDim2.new(0,0,0,0)
    bar.BackgroundColor3=color; bar.BorderSizePixel=0
    Instance.new("UICorner",bar).CornerRadius=UDim.new(0,8)
    local fix=Instance.new("Frame",bar); fix.Size=UDim2.new(1,0,0.5,0); fix.Position=UDim2.new(0,0,0.5,0)
    fix.BackgroundColor3=color; fix.BorderSizePixel=0
    -- value label (set externally via .Text)
    local val=Instance.new("TextLabel",f)
    val.Size=UDim2.new(1,-8,1,-4); val.Position=UDim2.new(0,8,0,4)
    val.BackgroundTransparency=1; val.Text=label.."\n0"
    val.TextColor3=WHITE; val.Font=Enum.Font.GothamBold; val.TextSize=12
    val.TextXAlignment=Enum.TextXAlignment.Left; val.TextYAlignment=Enum.TextYAlignment.Center
    val.TextWrapped=true; val.LineHeight=1.3
    return val
end

nWords = statCell("Words Typed", PINK)
nWpm   = statCell("Avg WPM",     PINK2)
nBest  = statCell("Best WPM",    Color3.fromRGB(255,200,60))
nMist  = statCell("Mistakes",    Color3.fromRGB(220,70,70))
nAcc   = statCell("Accuracy",    GREEN)

-- initial values
nWords.Text="Words Typed\n0"; nWpm.Text="Avg WPM\n0"
nBest.Text="Best WPM\n0"; nMist.Text="Mistakes\n0"; nAcc.Text="Accuracy\n100%"

-- ── CONTROLS ───────────────────────────────────────────────────────────
secHdr("Actions")
bigBtn("▶  Submit Word Now", PINK, function()
    if currentWord=="" then notify("No word","No word captured yet.",3); return end
    submitAnswer(currentWord); notify("Submitted!", currentWord:upper(), 2)
end)
bigBtn("🔄  Re-scan Remotes", CARD2, function()
    answerRemote=nil; hookIncoming(); hookSVs(RS); hookSVs(WS)
    notify("Re-scanned","Hooks refreshed.",2)
end)
bigBtn("📊  Reset Stats", CARD2, function()
    sessionStart=os.clock(); wordsTyped=0; bestWPM=0; mistakes=0; updateStats()
    notify("Stats Reset","Session cleared.",2)
end)

-- ── PLAYER ─────────────────────────────────────────────────────────────
secHdr("Player")

local function togRow(txt, def, cb)
    local f=Instance.new("Frame",SC); f.Size=UDim2.new(1,0,0,40)
    f.BackgroundColor3=CARD; f.BorderSizePixel=0
    Instance.new("UICorner",f).CornerRadius=UDim.new(0,8)
    local l=Instance.new("TextLabel",f); l.Size=UDim2.new(1,-60,1,0); l.Position=UDim2.new(0,12,0,0)
    l.BackgroundTransparency=1; l.Text=txt; l.TextColor3=LGRAY
    l.Font=Enum.Font.Gotham; l.TextSize=12; l.TextXAlignment=Enum.TextXAlignment.Left
    local st=def
    local pi=Instance.new("TextButton",f); pi.Size=UDim2.new(0,44,0,22); pi.Position=UDim2.new(1,-52,0.5,-11)
    pi.BackgroundColor3=st and GREEN or GRAY; pi.Text=""; pi.BorderSizePixel=0
    Instance.new("UICorner",pi).CornerRadius=UDim.new(1,0)
    local kn=Instance.new("Frame",pi); kn.Size=UDim2.new(0,16,0,16)
    kn.Position=st and UDim2.new(1,-18,0.5,-8) or UDim2.new(0,3,0.5,-8)
    kn.BackgroundColor3=WHITE; kn.BorderSizePixel=0
    Instance.new("UICorner",kn).CornerRadius=UDim.new(1,0)
    pi.MouseButton1Click:Connect(function()
        st=not st
        TW:Create(pi,TI,{BackgroundColor3=st and GREEN or GRAY}):Play()
        TW:Create(kn,TI,{Position=st and UDim2.new(1,-18,0.5,-8) or UDim2.new(0,3,0.5,-8)}):Play()
        cb(st)
    end)
end

togRow("Infinite Jump", false, function(v) infJump=v end)
togRow("Anti-AFK",      false, function(v) antiAFK=v end)
bigBtn("💀  Reset Character", Color3.fromRGB(155,40,40), function()
    local h=getHumanoid(); if h then pcall(function() h.Health=0 end) end
end)

-- spacer
local _sp=Instance.new("Frame",SC); _sp.Size=UDim2.new(1,0,0,8); _sp.BackgroundTransparency=1

-- ═══════════════════════════════════════════════════════════════════════
--  INSTALL HOOKS
-- ═══════════════════════════════════════════════════════════════════════

-- Hook every known remote + StringValue right now
hookIncoming()
for _, root in ipairs(SCAN_ROOTS) do
    pcall(function() hookSVs(root) end)
end

-- Install __namecall intercept (remotespy technique)
local _h2ok = installNamecallHook()

-- Start live watchers (ChildAdded per-root + game.DescendantAdded)
startLiveWatch()

-- Re-hook character remotes on respawn
LP.CharacterAdded:Connect(function(char)
    task.wait(1)
    for _, r in ipairs(char:GetDescendants()) do
        if r:IsA("RemoteEvent")    then hookOne(r)
        elseif r:IsA("RemoteFunction") then hookOneRF(r) end
    end
end)

notify("Preppy Hub  |  " .. GAME_NAME,
    "Ready  |  " .. (isMobile and "iPad" or "PC") .. "  |  Auto Type ON", 4)
if not _h2ok then
    notify("Preppy Hub", "Partial hook (events only — __namecall unavailable)", 4)
end

-- ═══════════════════════════════════════════════════════════════════════
--  BACKGROUND LOOPS
-- ═══════════════════════════════════════════════════════════════════════

UIS.JumpRequest:Connect(function()
    if infJump then
        local h=getHumanoid()
        if h then pcall(function() h:ChangeState(Enum.HumanoidStateType.Jumping) end) end
    end
end)

local _afkT=0
RunService.Heartbeat:Connect(function()
    if antiAFK then
        _afkT+=1
        if _afkT>=3600 then _afkT=0; pcall(function() VirtualUser:CaptureController() end) end
    end
end)

LP.CharacterAdded:Connect(function(char)
    task.wait(0.5)
    local h=char:FindFirstChildOfClass("Humanoid"); if not h then return end
    pcall(function() h.WalkSpeed=walkSpd; h.JumpPower=jumpPwr; h.JumpHeight=jumpPwr*0.36 end)
end)

task.spawn(function()
    while true do
        task.wait(0.5)
        if botEnabled then
            local w = scanLabels(PGui) or scanLabels(WS)
            if w then onWordFound(w) end
        end
    end
end)
