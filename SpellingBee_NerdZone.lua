-- ═══════════════════════════════════════════════════════════════════════
--  SPELLING BEE  —  NerdZone  |  Hook Script  (PC + Mobile Delta)
--  Game:  "Spelling Bee [🐰 SPRING]"  by NerdZone
-- ═══════════════════════════════════════════════════════════════════════

local function main()

-- ── Services ──────────────────────────────────────────────────────────
local Players     = game:GetService("Players")
local UIS         = game:GetService("UserInputService")
local RunService  = game:GetService("RunService")
local VirtualUser = game:GetService("VirtualUser")
local RS          = game:GetService("ReplicatedStorage")
local StarterGui  = game:GetService("StarterGui")
local LP          = Players.LocalPlayer
local PGui        = LP:WaitForChild("PlayerGui")

-- ── Platform ───────────────────────────────────────────────────────────
local isMobile = UIS.TouchEnabled

-- ── Early notification ─────────────────────────────────────────────────
pcall(function()
    StarterGui:SetCore("SendNotification", {
        Title    = "Spelling Bee  |  NerdZone",
        Text     = "Loading" .. (isMobile and " (mobile)..." or "..."),
        Duration = 4,
    })
end)

-- ── Load Rayfield ──────────────────────────────────────────────────────
local ok, result = pcall(function()
    return loadstring(game:HttpGet("https://raw.githubusercontent.com/SiriusXT/Rayfield/main/lib/main.lua"))()
end)
if not ok or not result then
    pcall(function()
        StarterGui:SetCore("SendNotification", {
            Title    = "SpellingBee | Error",
            Text     = "Rayfield failed: " .. tostring(result):sub(1, 80),
            Duration = 10,
        })
    end)
    warn("[SpellingBee] Rayfield error: " .. tostring(result))
    return
end
local Rayfield = result

-- ── State ─────────────────────────────────────────────────────────────
local botEnabled   = true
local submitDelay  = 0.05
local currentWord  = ""
local answerRemote = nil
local antiAFK      = false
local infJump      = false
local walkSpd      = 16
local jumpPwr      = 50
local WordLabel    -- set after UI builds

-- ═══════════════════════════════════════════════════════════════════════
--  HELPERS
-- ═══════════════════════════════════════════════════════════════════════

local function looksLikeWord(s)
    return type(s) == "string"
        and #s >= 3
        and #s <= 30
        and s:match("^%a+$") ~= nil
end

-- Answer remote keywords (intentionally excludes "word" — too broad)
local ANSWER_KEYS = {"submit","answer","spell","type","guess","check"}

local function isAnswerRemote(name)
    local n = name:lower()
    for _, k in ipairs(ANSWER_KEYS) do
        if n:find(k, 1, true) then return true end
    end
    return false
end

local function findAnswerRemote()
    if answerRemote and answerRemote.Parent then return answerRemote end
    answerRemote = nil  -- was destroyed; search again
    for _, r in ipairs(RS:GetDescendants()) do
        if r:IsA("RemoteEvent") and isAnswerRemote(r.Name) then
            answerRemote = r
            return r
        end
    end
    return nil
end

local function fireAnswer(word)
    local r = findAnswerRemote()
    if r then
        pcall(function() r:FireServer(word) end)
        return true
    end
    return false
end

local function boxSubmit(word)
    for _, obj in ipairs(PGui:GetDescendants()) do
        if obj:IsA("TextBox") and obj.TextEditable and obj.Visible then
            obj.Text = word
            obj:CaptureFocus()
            task.wait(0.03)
            obj:ReleaseFocus(true)
            return true
        end
    end
    return false
end

local function submitAnswer(word)
    if word == "" then return end
    if not fireAnswer(word) then boxSubmit(word) end
end

local function onWordFound(w)
    w = w:lower()
    if w == currentWord then return end  -- already processing this word
    currentWord = w
    if WordLabel then WordLabel:Set("Word: " .. w) end
    if botEnabled then
        task.delay(submitDelay, function() submitAnswer(w) end)
    end
end

-- ═══════════════════════════════════════════════════════════════════════
--  HOOK 1 — RemoteEvent.OnClientEvent  (instant, deduplicated)
-- ═══════════════════════════════════════════════════════════════════════
local _hooked = {}  -- remote → true; prevents duplicate connections

local function hookOne(remote)
    if _hooked[remote] then return end
    _hooked[remote] = true
    remote.OnClientEvent:Connect(function(...)
        for _, v in ipairs({...}) do
            if looksLikeWord(v) then
                onWordFound(v)
                return
            elseif type(v) == "table" then
                for _, tv in pairs(v) do
                    if looksLikeWord(tv) then
                        onWordFound(tv)
                        return
                    end
                end
            end
        end
    end)
end

local function hookIncoming()
    for _, r in ipairs(RS:GetDescendants()) do
        if r:IsA("RemoteEvent") then hookOne(r) end
    end
end

-- ═══════════════════════════════════════════════════════════════════════
--  HOOK 2 — __namecall  (forces correct word on any answer submission)
-- ═══════════════════════════════════════════════════════════════════════
local namecallHook
local function installNamecallHook()
    if not hookmetamethod or not newcclosure or not getnamecallmethod then
        return false
    end
    local ok2 = pcall(function()
        namecallHook = hookmetamethod(game, "__namecall", newcclosure(function(self, ...)
            local method = getnamecallmethod()
            if (method == "FireServer" or method == "InvokeServer")
            and (self:IsA("RemoteEvent") or self:IsA("RemoteFunction"))
            and isAnswerRemote(self.Name) then
                if self:IsA("RemoteEvent") and not answerRemote then
                    answerRemote = self
                end
                if botEnabled and currentWord ~= "" then
                    return namecallHook(self, currentWord)
                end
            end
            return namecallHook(self, ...)
        end))
    end)
    return ok2
end

-- ═══════════════════════════════════════════════════════════════════════
--  HOOK 3 — Screen-label poll  (last resort for UI-only games)
-- ═══════════════════════════════════════════════════════════════════════
local function findWordLabel()
    local names = {"Word","CurrentWord","SpellWord","WordToSpell","TargetWord","Prompt","Question"}
    for _, name in ipairs(names) do
        local obj = PGui:FindFirstChild(name, true)
        if obj and obj:IsA("TextLabel") and obj.Visible and obj.Text ~= "" then
            return obj
        end
    end
    local best, bestLen = nil, -1
    for _, obj in ipairs(PGui:GetDescendants()) do
        if obj:IsA("TextLabel") and obj.Visible and obj.Text ~= "" then
            local t = obj.Text
            if t:match("^%a+$") and #t >= 3 and #t <= 30 and #t > bestLen then
                best = obj; bestLen = #t
            end
        end
    end
    return best
end

-- ═══════════════════════════════════════════════════════════════════════
--  RAYFIELD UI
-- ═══════════════════════════════════════════════════════════════════════
local Window = Rayfield:CreateWindow({
    Name            = "Spelling Bee  |  NerdZone",
    Icon            = "pencil",
    LoadingTitle    = "NerdZone Hub",
    LoadingSubtitle = "Spelling Bee Script",
    Theme           = "Default",
    DisableRayfieldPrompts = false,
    DisableBuildWarnings   = true,
    ConfigurationSaving = {
        Enabled    = true,
        FolderName = "NerdZone",
        FileName   = "SpellingBee",
    },
    Discord   = { Enabled = false },
    KeySystem = false,
})

local BotTab    = Window:CreateTab("Bot",    "bot")
local PlayerTab = Window:CreateTab("Player", "user")
local MiscTab   = Window:CreateTab("Misc",   "settings")

-- ── BOT TAB ───────────────────────────────────────────────────────────
BotTab:CreateSection("Hook Status")

local HookLabel = BotTab:CreateLabel(
    "Hook: hooking now...", "shield", Color3.fromRGB(255, 200, 60), true)
WordLabel = BotTab:CreateLabel(
    "Word: waiting...", "book-open", Color3.fromRGB(100, 210, 255), true)
BotTab:CreateLabel(
    isMobile and "Platform: iPad / Mobile (Delta)" or "Platform: PC",
    "smartphone", Color3.fromRGB(160, 160, 160), true)

BotTab:CreateSection("Auto Submit")

BotTab:CreateToggle({
    Name         = "Auto-Bot  (submit on word capture)",
    CurrentValue = true,
    Flag         = "BotOn",
    Callback     = function(v) botEnabled = v end,
})

BotTab:CreateSlider({
    Name         = "Submit Delay  (0 = instant, 100 = 1 s)",
    Range        = {0, 200},
    Increment    = 5,
    Suffix       = "ms",
    CurrentValue = 50,
    Flag         = "SubDelay",
    Callback     = function(v) submitDelay = v / 1000 end,
})

BotTab:CreateSection("Manual")

BotTab:CreateInput({
    Name                     = "Set Word Manually",
    CurrentValue             = "",
    PlaceholderText          = "e.g.  mississippi",
    RemoveTextAfterFocusLost = false,
    Flag                     = "ManualWord",
    Callback                 = function(text)
        local w = text:lower():match("^%s*(.-)%s*$") or ""
        if looksLikeWord(w) then
            currentWord = w
            if WordLabel then WordLabel:Set("Word: " .. w) end
        end
    end,
})

BotTab:CreateButton({
    Name     = "Submit Current Word Now",
    Callback = function()
        if currentWord == "" then
            Rayfield:Notify({ Title="No Word", Content="No word captured yet.", Duration=3, Image="alert-circle" })
            return
        end
        submitAnswer(currentWord)
        Rayfield:Notify({ Title="Submitted", Content=currentWord, Duration=2, Image="check" })
    end,
})

BotTab:CreateButton({
    Name     = "Re-scan Remotes",
    Callback = function()
        answerRemote = nil
        hookIncoming()
        Rayfield:Notify({ Title="Re-scanned", Content="Hooks refreshed.", Duration=2, Image="refresh-cw" })
    end,
})

-- ── PLAYER TAB ────────────────────────────────────────────────────────
PlayerTab:CreateSection("Movement")

local function getHumanoid()
    local char = LP.Character
    return char and char:FindFirstChildOfClass("Humanoid")
end

PlayerTab:CreateSlider({
    Name = "Walk Speed", Range = {1,300}, Increment = 1,
    Suffix = "", CurrentValue = 16, Flag = "WalkSpd",
    Callback = function(v)
        walkSpd = v
        local hum = getHumanoid()
        if hum then pcall(function() hum.WalkSpeed = v end) end
    end,
})

PlayerTab:CreateSlider({
    Name = "Jump Power", Range = {1,300}, Increment = 1,
    Suffix = "", CurrentValue = 50, Flag = "JumpPwr",
    Callback = function(v)
        jumpPwr = v
        local hum = getHumanoid()
        if hum then pcall(function()
            hum.JumpPower  = v
            hum.JumpHeight = v * 0.36  -- cover both Humanoid v1 and v2
        end) end
    end,
})

PlayerTab:CreateToggle({
    Name = "Infinite Jump", CurrentValue = false, Flag = "InfJump",
    Callback = function(v) infJump = v end,
})

PlayerTab:CreateSection("Character")

PlayerTab:CreateButton({
    Name = "Reset Character",
    Callback = function()
        local hum = getHumanoid()
        if hum then pcall(function() hum.Health = 0 end) end
    end,
})

-- ── MISC TAB ──────────────────────────────────────────────────────────
MiscTab:CreateSection("Utilities")

MiscTab:CreateToggle({
    Name = "Anti-AFK", CurrentValue = false, Flag = "AntiAFK",
    Callback = function(v) antiAFK = v end,
})

MiscTab:CreateSection("Info")
MiscTab:CreateLabel("Script: NerdZone Hub",          "zap",    Color3.fromRGB(100,180,255), true)
MiscTab:CreateLabel("UI: Rayfield Library",           "layout", Color3.fromRGB(160,160,160), true)
MiscTab:CreateLabel("Game: Spelling Bee by NerdZone", "bee",    Color3.fromRGB(255,220,60),  true)
MiscTab:CreateLabel("Supports: Delta PC + Mobile",    "check",  Color3.fromRGB(100,220,100), true)

-- ═══════════════════════════════════════════════════════════════════════
--  INSTALL HOOKS — immediately, no delay
-- ═══════════════════════════════════════════════════════════════════════
hookIncoming()  -- hook all existing remotes right now

local hook2ok = installNamecallHook()

if hook2ok then
    HookLabel:Set("Hook: ACTIVE  (__namecall + events)", "shield-check")
else
    HookLabel:Set("Hook: partial  (events only — no __namecall)", "shield-alert")
end

-- Catch remotes that appear after load (game lazy-loads them)
RS.DescendantAdded:Connect(function(obj)
    if obj:IsA("RemoteEvent") then
        task.wait()  -- one frame so the remote is fully parented
        hookOne(obj)
    end
end)

-- ═══════════════════════════════════════════════════════════════════════
--  BACKGROUND LOOPS
-- ═══════════════════════════════════════════════════════════════════════

-- Infinite jump (works from mobile jump button via UIS.JumpRequest)
UIS.JumpRequest:Connect(function()
    if infJump then
        local hum = getHumanoid()
        if hum then
            pcall(function() hum:ChangeState(Enum.HumanoidStateType.Jumping) end)
        end
    end
end)

-- Anti-AFK — fires once per minute (3600 heartbeats ≈ 60s)
local _afkTick = 0
RunService.Heartbeat:Connect(function()
    if antiAFK then
        _afkTick += 1
        if _afkTick >= 3600 then
            _afkTick = 0
            pcall(function() VirtualUser:CaptureController() end)
        end
    end
end)

-- Re-apply speed/jump on respawn
LP.CharacterAdded:Connect(function(char)
    task.wait(0.5)
    local hum = char:FindFirstChildOfClass("Humanoid")
    if not hum then return end
    pcall(function()
        hum.WalkSpeed  = walkSpd
        hum.JumpPower  = jumpPwr
        hum.JumpHeight = jumpPwr * 0.36
    end)
end)

-- Fallback screen poll (for UI-only games with no remotes)
task.spawn(function()
    while true do
        task.wait(0.5)
        if botEnabled then
            local lbl = findWordLabel()
            if lbl then
                local raw = lbl.Text
                local w = raw:lower():match("^%s*(.-)%s*$")
                if w and looksLikeWord(w) then
                    onWordFound(w)
                end
            end
        end
    end
end)

-- ═══════════════════════════════════════════════════════════════════════
Rayfield:LoadConfiguration()

Rayfield:Notify({
    Title    = "NerdZone  |  Spelling Bee",
    Content  = "Ready  |  " .. (isMobile and "iPad/Mobile" or "PC") .. "  |  Auto-Bot ON",
    Duration = 5,
    Image    = "shield",
})

end  -- main()

main()
