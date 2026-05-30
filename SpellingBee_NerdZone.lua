-- ═══════════════════════════════════════════════════════════════════════
--  SPELLING BEE  —  NerdZone  |  Hook Script  (PC + Mobile Delta)
--  Game:  "Spelling Bee [🐰 SPRING]"  by NerdZone
--  UI:    Rayfield  (sirius.menu/rayfield)
--
--  How it works:
--    1. Hooks every RemoteEvent in ReplicatedStorage — when the server
--       sends a word to the client, we capture it instantly.
--    2. Hooks game.__namecall so any FireServer/InvokeServer for an
--       answer remote is always replaced with the correct word.
--    3. Fires the answer remote directly (fastest method, zero misspelling).
-- ═══════════════════════════════════════════════════════════════════════

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

-- ── Early notification (instant feedback before Rayfield HTTP loads) ───
pcall(function()
    StarterGui:SetCore("SendNotification", {
        Title    = "Spelling Bee  |  NerdZone",
        Text     = "Loading" .. (isMobile and " (mobile)" or "") .. "…",
        Duration = 4,
    })
end)

-- ── Load Rayfield (pcall so a network failure gives visible feedback) ──
local Rayfield
do
    local ok, result = pcall(function()
        return loadstring(game:HttpGet("https://sirius.menu/rayfield"))()
    end)
    if not ok or not result then
        pcall(function()
            StarterGui:SetCore("SendNotification", {
                Title    = "SpellingBee  |  Error",
                Text     = "Rayfield failed: " .. tostring(result):sub(1, 80),
                Duration = 10,
            })
        end)
        warn("[SpellingBee] Rayfield load error: " .. tostring(result))
        return
    end
    Rayfield = result
end

-- ── State ─────────────────────────────────────────────────────────────
local botEnabled   = true
local submitDelay  = 0.05
local currentWord  = ""
local answerRemote = nil
local antiAFK      = false
local infJump      = false
local walkSpd      = 16
local jumpPwr      = 50

local WordLabel    -- assigned after Rayfield window is built

-- ═══════════════════════════════════════════════════════════════════════
--  HOOK HELPERS
-- ═══════════════════════════════════════════════════════════════════════

local function looksLikeWord(s)
    return type(s) == "string"
        and s:match("^%a+$")
        and #s >= 3
        and #s <= 30
end

local function findAnswerRemote()
    if answerRemote then return answerRemote end
    for _, r in RS:GetDescendants() do
        if r:IsA("RemoteEvent") then
            local n = r.Name:lower()
            if n:find("submit") or n:find("answer") or n:find("spell")
            or n:find("type")  or n:find("guess")  or n:find("word") then
                answerRemote = r
                return r
            end
        end
    end
    return nil
end

-- Direct remote fire — no typing, works on both PC and mobile.
local function fireAnswer(word)
    local r = findAnswerRemote()
    if r then
        pcall(function() r:FireServer(word) end)
        return true
    end
    return false
end

-- TextBox fallback — works on PC and mobile (Delta mobile supports CaptureFocus).
local function boxSubmit(word)
    for _, obj in PGui:GetDescendants() do
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
    local ok = fireAnswer(word)
    if not ok then boxSubmit(word) end
end

-- ═══════════════════════════════════════════════════════════════════════
--  HOOK 1 — RemoteEvent.OnClientEvent
-- ═══════════════════════════════════════════════════════════════════════
local function hookIncoming()
    for _, remote in RS:GetDescendants() do
        if remote:IsA("RemoteEvent") then
            remote.OnClientEvent:Connect(function(...)
                for _, v in ipairs({...}) do
                    if looksLikeWord(v) then
                        local w = v:lower()
                        currentWord = w
                        if WordLabel then WordLabel:Set("Word: " .. w) end
                        if botEnabled then
                            task.delay(submitDelay, function() submitAnswer(w) end)
                        end
                        return
                    elseif type(v) == "table" then
                        for _, tv in pairs(v) do
                            if looksLikeWord(tv) then
                                local w2 = tostring(tv):lower()
                                currentWord = w2
                                if WordLabel then WordLabel:Set("Word: " .. w2) end
                                if botEnabled then
                                    task.delay(submitDelay, function() submitAnswer(w2) end)
                                end
                                return
                            end
                        end
                    end
                end
            end)
        end
    end
end

-- ═══════════════════════════════════════════════════════════════════════
--  HOOK 2 — __namecall (hookmetamethod)
--  Delta mobile supports hookmetamethod, newcclosure, getnamecallmethod.
-- ═══════════════════════════════════════════════════════════════════════
local namecallHook

local function installNamecallHook()
    if not hookmetamethod    then return false end
    if not newcclosure       then return false end
    if not getnamecallmethod then return false end

    local ok, err = pcall(function()
        namecallHook = hookmetamethod(game, "__namecall", newcclosure(function(self, ...)
            local method = getnamecallmethod()

            if method == "FireServer" or method == "InvokeServer" then
                if self:IsA("RemoteEvent") or self:IsA("RemoteFunction") then
                    local name = self.Name:lower()
                    if name:find("submit") or name:find("answer") or name:find("spell")
                    or name:find("type")  or name:find("guess") then
                        if self:IsA("RemoteEvent") and not answerRemote then
                            answerRemote = self
                        end
                        if botEnabled and currentWord ~= "" then
                            return namecallHook(self, currentWord)
                        end
                    end
                end
            end

            return namecallHook(self, ...)
        end))
    end)

    return ok
end

-- ═══════════════════════════════════════════════════════════════════════
--  HOOK 3 — Screen label poll (last-resort for UI-only games)
-- ═══════════════════════════════════════════════════════════════════════
local function findWordLabel()
    local priority = {"Word","CurrentWord","SpellWord","WordToSpell","TargetWord","Prompt","Question"}
    for _, name in priority do
        local obj = PGui:FindFirstChild(name, true)
        if obj and obj:IsA("TextLabel") and obj.Text ~= "" and obj.Visible then
            return obj
        end
    end
    local best, bestScore = nil, -1
    for _, obj in PGui:GetDescendants() do
        if obj:IsA("TextLabel") and obj.Visible and obj.Text ~= "" then
            local t = obj.Text
            if t:match("^%a+$") and #t >= 3 and #t <= 30 then
                if #t > bestScore then best = obj; bestScore = #t end
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
    Discord  = { Enabled = false },
    KeySystem = false,
})

local BotTab    = Window:CreateTab("Bot",    "bot")
local PlayerTab = Window:CreateTab("Player", "user")
local MiscTab   = Window:CreateTab("Misc",   "settings")

-- ── BOT TAB ───────────────────────────────────────────────────────────
BotTab:CreateSection("Hook Status")

local HookLabel = BotTab:CreateLabel(
    "Hook: installing…", "shield", Color3.fromRGB(255, 200, 60), true)
WordLabel = BotTab:CreateLabel(
    "Word: —", "book-open", Color3.fromRGB(100, 210, 255), true)
BotTab:CreateLabel(
    isMobile and "Platform: Mobile (Delta)" or "Platform: PC",
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
        local w = text:lower():match("^%s*(.-)%s*$")
        if w ~= "" then
            currentWord = w
            WordLabel:Set("Word: " .. w)
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
        Rayfield:Notify({ Title="Re-scanned", Content="Hooks re-applied.", Duration=2, Image="refresh-cw" })
    end,
})

-- ── PLAYER TAB ────────────────────────────────────────────────────────
PlayerTab:CreateSection("Movement")

PlayerTab:CreateSlider({
    Name = "Walk Speed", Range = {1,300}, Increment = 1,
    Suffix = "", CurrentValue = 16, Flag = "WalkSpd",
    Callback = function(v)
        walkSpd = v
        pcall(function() LP.Character.Humanoid.WalkSpeed = v end)
    end,
})

PlayerTab:CreateSlider({
    Name = "Jump Power", Range = {1,300}, Increment = 1,
    Suffix = "", CurrentValue = 50, Flag = "JumpPwr",
    Callback = function(v)
        jumpPwr = v
        pcall(function() LP.Character.Humanoid.JumpPower = v end)
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
        pcall(function() LP.Character.Humanoid.Health = 0 end)
    end,
})

-- ── MISC TAB ──────────────────────────────────────────────────────────
MiscTab:CreateSection("Utilities")

MiscTab:CreateToggle({
    Name = "Anti-AFK", CurrentValue = false, Flag = "AntiAFK",
    Callback = function(v) antiAFK = v end,
})

MiscTab:CreateSection("Info")
MiscTab:CreateLabel("Script: NerdZone Hub",          "zap",       Color3.fromRGB(100,180,255), true)
MiscTab:CreateLabel("UI: Rayfield Library",           "layout",    Color3.fromRGB(160,160,160), true)
MiscTab:CreateLabel("Game: Spelling Bee by NerdZone", "bee",       Color3.fromRGB(255,220,60),  true)
MiscTab:CreateLabel("Supports: Delta PC + Mobile",    "check",     Color3.fromRGB(100,220,100), true)

-- ═══════════════════════════════════════════════════════════════════════
--  INSTALL HOOKS
-- ═══════════════════════════════════════════════════════════════════════
task.spawn(function()
    task.wait(1)   -- let RS populate

    hookIncoming()

    local hook2ok = installNamecallHook()

    if hook2ok then
        HookLabel:Set("Hook: ACTIVE  (__namecall + OnClientEvent)", "shield-check")
    else
        HookLabel:Set("Hook: partial  (OnClientEvent only)", "shield-alert")
    end

    RS.DescendantAdded:Connect(function(obj)
        if obj:IsA("RemoteEvent") then
            task.wait(0.1)
            hookIncoming()
        end
    end)
end)

-- ═══════════════════════════════════════════════════════════════════════
--  BACKGROUND LOOPS
-- ═══════════════════════════════════════════════════════════════════════

-- Infinite jump — UIS.JumpRequest fires from both PC keys and mobile jump button
UIS.JumpRequest:Connect(function()
    if infJump then
        pcall(function()
            LP.Character.Humanoid:ChangeState(Enum.HumanoidStateType.Jumping)
        end)
    end
end)

-- Anti-AFK — VirtualUser:CaptureController works on PC and mobile Delta
local _afkTick = 0
RunService.Heartbeat:Connect(function()
    if antiAFK then
        _afkTick += 1
        if _afkTick >= 120 then
            _afkTick = 0
            pcall(function() VirtualUser:CaptureController() end)
        end
    end
end)

-- Re-apply speed on respawn
LP.CharacterAdded:Connect(function(char)
    task.wait(0.5)
    pcall(function()
        char.Humanoid.WalkSpeed = walkSpd
        char.Humanoid.JumpPower = jumpPwr
    end)
end)

-- Fallback screen-poll (UI-only games / words shown as labels only)
task.spawn(function()
    local lastSeen = ""
    while true do
        task.wait(0.5)
        if botEnabled then
            local lbl = findWordLabel()
            if lbl then
                local w = lbl.Text:lower():match("^%s*(.-)%s*$")
                if w and w ~= "" and w:match("^%a+$") and w ~= lastSeen then
                    lastSeen = w
                    currentWord = w
                    if WordLabel then WordLabel:Set("Word: " .. w) end
                    task.delay(submitDelay, function() submitAnswer(w) end)
                end
            end
        end
    end
end)

-- ═══════════════════════════════════════════════════════════════════════
Rayfield:LoadConfiguration()

Rayfield:Notify({
    Title    = "NerdZone  |  Spelling Bee",
    Content  = "Ready  •  " .. (isMobile and "Mobile" or "PC") .. "  •  Auto-Bot ON",
    Duration = 5,
    Image    = "shield",
})
