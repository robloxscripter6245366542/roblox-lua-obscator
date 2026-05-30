-- ═══════════════════════════════════════════════════════════════════════
--  SPELLING BEE  —  NerdZone  |  Script by Nerd Zone Hub
--  Game:  "Spelling Bee [🐰 SPRING]"  by NerdZone
--  UI:    Rayfield Library  (sirius.menu/rayfield)
--
--  Features:
--    • Auto-Bot  — reads the word, types it automatically
--    • Typing Speed slider (instant → realistic slow)
--    • Manual word override + one-click type
--    • WalkSpeed / JumpPower sliders
--    • Infinite Jump, Anti-AFK
-- ═══════════════════════════════════════════════════════════════════════

local Rayfield = loadstring(game:HttpGet("https://sirius.menu/rayfield"))()

-- ── Services ──────────────────────────────────────────────────────────
local Players     = game:GetService("Players")
local UIS         = game:GetService("UserInputService")
local RunService  = game:GetService("RunService")
local VirtualUser = game:GetService("VirtualUser")
local RS          = game:GetService("ReplicatedStorage")
local LP          = Players.LocalPlayer
local PGui        = LP:WaitForChild("PlayerGui")

-- ── State ─────────────────────────────────────────────────────────────
local botEnabled  = false
local typingDelay = 0.05   -- seconds between each character
local currentWord = ""
local isTyping    = false
local antiAFK     = false
local infJump     = false
local walkSpd     = 16
local jumpPwr     = 50

-- ═══════════════════════════════════════════════════════════════════════
--  GAME-SPECIFIC HELPERS  (NerdZone Spelling Bee)
-- ═══════════════════════════════════════════════════════════════════════

-- Find the label that shows the word to spell.
-- NerdZone Spelling Bee displays the target word in a ScreenGui label.
local function findWordLabel()
    -- Priority: check common NerdZone label names first
    local priority = {"Word","CurrentWord","SpellWord","WordToSpell","TargetWord","Prompt","Question"}
    for _, name in priority do
        local obj = PGui:FindFirstChild(name, true)
        if obj and obj:IsA("TextLabel") and obj.Text ~= "" and obj.Visible then
            return obj
        end
    end
    -- Fallback: scan every visible TextLabel for a plain dictionary word
    local best, bestScore = nil, -1
    for _, obj in PGui:GetDescendants() do
        if obj:IsA("TextLabel") and obj.Visible and obj.Text ~= "" then
            local t = obj.Text
            -- Score: single word, all alpha chars, 3–30 chars, no numbers/symbols
            if t:match("^%a+$") and #t >= 3 and #t <= 30 then
                local score = #t
                if score > bestScore then best = obj; bestScore = score end
            end
        end
    end
    return best
end

-- Find the TextBox the player types into.
local function findInputBox()
    -- Common NerdZone input names
    local priority = {"Input","AnswerBox","TypeBox","SpellInput","TextInput","Answer","TypeHere"}
    for _, name in priority do
        local obj = PGui:FindFirstChild(name, true)
        if obj and obj:IsA("TextBox") and obj.TextEditable and obj.Visible then
            return obj
        end
    end
    -- Fallback: first visible editable TextBox
    for _, obj in PGui:GetDescendants() do
        if obj:IsA("TextBox") and obj.TextEditable and obj.Visible then
            return obj
        end
    end
    return nil
end

-- Try to submit via a ReplicatedStorage remote (backup method).
local function remoteSubmit(word)
    for _, obj in RS:GetDescendants() do
        if obj:IsA("RemoteEvent") or obj:IsA("RemoteFunction") then
            local n = obj.Name:lower()
            if n:find("submit") or n:find("answer") or n:find("spell") or n:find("word") or n:find("type") then
                pcall(function()
                    if obj:IsA("RemoteEvent") then
                        obj:FireServer(word)
                    else
                        obj:InvokeServer(word)
                    end
                end)
                return true
            end
        end
    end
    return false
end

-- ── Core type function — fills the box one character at a time ─────────
-- This matches NerdZone's real-time letter-tracking exactly the same way
-- a human would type: focus the box, append each character, release.
local function typeWord(box, word, delay)
    if isTyping then return end
    isTyping  = true
    box.Text  = ""
    box:CaptureFocus()
    task.wait(0.05)
    for i = 1, #word do
        if not isTyping then break end
        box.Text = word:sub(1, i)
        task.wait(delay)
    end
    task.wait(0.05)
    box:ReleaseFocus(true)   -- enterPressed = true  →  game treats it as submit
    isTyping = false
end

-- ── Keypress-based fallback (if the game uses UIS instead of TextBox) ──
-- Some Spelling Bee versions listen to raw keypresses; simulate each key.
local CHAR_TO_KEY = {}
do
    local alpha = "abcdefghijklmnopqrstuvwxyz"
    for i = 1, #alpha do
        local ch  = alpha:sub(i, i)
        local key = Enum.KeyCode[ch:upper()]
        if key then CHAR_TO_KEY[ch] = key end
    end
end

local function keypressType(word, delay)
    if isTyping then return end
    isTyping = true
    for i = 1, #word do
        if not isTyping then break end
        local ch  = word:sub(i, i):lower()
        local key = CHAR_TO_KEY[ch]
        if key then
            -- Try executor keypress first (Delta/Synapse/KRNL)
            if type(keypress) == "function" then
                pcall(keypress, key.Value)
                task.wait(0.02)
                pcall(keyrelease, key.Value)
            end
        end
        task.wait(delay)
    end
    -- Press Enter to submit
    if type(keypress) == "function" then
        pcall(keypress, 13)   -- Return/Enter
        task.wait(0.05)
        pcall(keyrelease, 13)
    end
    isTyping = false
end

-- ── Master type function: tries TextBox → keypress → remote ──────────
local function doType(word)
    if word == "" then return end
    local box = findInputBox()
    if box then
        task.spawn(function() typeWord(box, word, typingDelay) end)
    elseif type(keypress) == "function" then
        task.spawn(function() keypressType(word, typingDelay) end)
    else
        remoteSubmit(word)
    end
end

-- ═══════════════════════════════════════════════════════════════════════
--  RAYFIELD WINDOW
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

-- ═══════════════════════════════════════════════════════════════════════
--  BOT TAB
-- ═══════════════════════════════════════════════════════════════════════
local BotTab    = Window:CreateTab("Bot",    "bot")
local PlayerTab = Window:CreateTab("Player", "user")
local MiscTab   = Window:CreateTab("Misc",   "settings")

-- ── Bot Tab ───────────────────────────────────────────────────────────
BotTab:CreateSection("Auto Typer")

local WordLabel = BotTab:CreateLabel("Word: —", "book-open", Color3.fromRGB(100, 210, 255), true)

BotTab:CreateToggle({
    Name         = "Enable Auto-Bot",
    CurrentValue = false,
    Flag         = "BotOn",
    Callback     = function(v)
        botEnabled = v
        if not v then isTyping = false end
    end,
})

-- Speed: slider goes 0–20; value / 100 = delay in seconds
-- 0  → instant  (0.00 s per char)
-- 5  → fast     (0.05 s per char)  ← default
-- 20 → slow     (0.20 s per char, looks human)
BotTab:CreateSlider({
    Name         = "Typing Speed  (0 = instant, 20 = slow)",
    Range        = {0, 20},
    Increment    = 1,
    Suffix       = "",
    CurrentValue = 5,
    Flag         = "TypingSpd",
    Callback     = function(v)
        typingDelay = v / 100
    end,
})

BotTab:CreateSection("Manual")

BotTab:CreateInput({
    Name                     = "Set Word Manually",
    CurrentValue             = "",
    PlaceholderText          = "e.g.  mississippi",
    RemoveTextAfterFocusLost = false,
    Flag                     = "ManualWord",
    Callback                 = function(text)
        text = text:lower():match("^%s*(.-)%s*$")
        if text ~= "" then
            currentWord = text
            WordLabel:Set("Word: " .. currentWord)
        end
    end,
})

BotTab:CreateButton({
    Name     = "Detect Word from Screen",
    Callback = function()
        local lbl = findWordLabel()
        if lbl then
            local w = lbl.Text:lower():match("^%s*(.-)%s*$")
            currentWord = w
            WordLabel:Set("Word: " .. w)
            Rayfield:Notify({ Title = "Detected", Content = w, Duration = 3, Image = "check" })
        else
            Rayfield:Notify({ Title = "Not Found", Content = "No word label found yet.", Duration = 3, Image = "x" })
        end
    end,
})

BotTab:CreateButton({
    Name     = "▶  Type Answer Now",
    Callback = function()
        if currentWord == "" then
            Rayfield:Notify({ Title = "No Word", Content = "Detect or set a word first.", Duration = 3, Image = "alert-circle" })
            return
        end
        Rayfield:Notify({ Title = "Typing…", Content = currentWord, Duration = 2, Image = "pencil" })
        doType(currentWord)
    end,
})

BotTab:CreateButton({
    Name     = "■  Stop",
    Callback = function()
        isTyping = false
        Rayfield:Notify({ Title = "Stopped", Content = "Typing cancelled.", Duration = 2, Image = "square" })
    end,
})

-- ═══════════════════════════════════════════════════════════════════════
--  PLAYER TAB
-- ═══════════════════════════════════════════════════════════════════════
PlayerTab:CreateSection("Movement")

PlayerTab:CreateSlider({
    Name         = "Walk Speed",
    Range        = {1, 300},
    Increment    = 1,
    Suffix       = "",
    CurrentValue = 16,
    Flag         = "WalkSpd",
    Callback     = function(v)
        walkSpd = v
        pcall(function() LP.Character.Humanoid.WalkSpeed = v end)
    end,
})

PlayerTab:CreateSlider({
    Name         = "Jump Power",
    Range        = {1, 300},
    Increment    = 1,
    Suffix       = "",
    CurrentValue = 50,
    Flag         = "JumpPwr",
    Callback     = function(v)
        jumpPwr = v
        pcall(function() LP.Character.Humanoid.JumpPower = v end)
    end,
})

PlayerTab:CreateToggle({
    Name         = "Infinite Jump",
    CurrentValue = false,
    Flag         = "InfJump",
    Callback     = function(v) infJump = v end,
})

PlayerTab:CreateSection("Character")

PlayerTab:CreateButton({
    Name     = "Reset Character",
    Callback = function()
        pcall(function() LP.Character.Humanoid.Health = 0 end)
    end,
})

-- ═══════════════════════════════════════════════════════════════════════
--  MISC TAB
-- ═══════════════════════════════════════════════════════════════════════
MiscTab:CreateSection("Utilities")

MiscTab:CreateToggle({
    Name         = "Anti-AFK",
    CurrentValue = false,
    Flag         = "AntiAFK",
    Callback     = function(v) antiAFK = v end,
})

MiscTab:CreateSection("Info")
MiscTab:CreateLabel("Script: NerdZone Hub",    "zap",    Color3.fromRGB(100, 180, 255), true)
MiscTab:CreateLabel("UI: Rayfield Library",     "layout", Color3.fromRGB(160, 160, 160), true)
MiscTab:CreateLabel("Game: Spelling Bee by NerdZone", "bee", Color3.fromRGB(255, 220, 60), true)

-- ═══════════════════════════════════════════════════════════════════════
--  BACKGROUND LOOPS
-- ═══════════════════════════════════════════════════════════════════════

-- Infinite jump
UIS.JumpRequest:Connect(function()
    if infJump then
        pcall(function()
            LP.Character.Humanoid:ChangeState(Enum.HumanoidStateType.Jumping)
        end)
    end
end)

-- Anti-AFK (kicks every ~60 frames)
local _afkFrame = 0
RunService.Heartbeat:Connect(function()
    if antiAFK then
        _afkFrame += 1
        if _afkFrame >= 120 then
            _afkFrame = 0
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

-- ── Bot main loop — polls every 0.8 s ─────────────────────────────────
task.spawn(function()
    local lastWord = ""
    while true do
        task.wait(0.8)

        if botEnabled and not isTyping then
            -- 1. Detect word from screen
            local lbl = findWordLabel()
            if lbl then
                local w = lbl.Text:lower():match("^%s*(.-)%s*$")
                if w and w ~= "" and w:match("^%a+$") then
                    currentWord = w
                    if w ~= lastWord then
                        lastWord = w
                        WordLabel:Set("Word: " .. w)
                    end
                end
            end

            -- 2. Type it if box is empty / doesn't match yet
            if currentWord ~= "" then
                local box = findInputBox()
                if box and box.Text:lower() ~= currentWord then
                    doType(currentWord)
                elseif not box then
                    -- No TextBox: try remote every new word
                    if currentWord ~= lastWord then
                        remoteSubmit(currentWord)
                    end
                end
            end
        end
    end
end)

-- ── Load saved config & show welcome ──────────────────────────────────
Rayfield:LoadConfiguration()

Rayfield:Notify({
    Title   = "NerdZone  |  Spelling Bee",
    Content = "Loaded! Enable Auto-Bot in the Bot tab.",
    Duration = 5,
    Image   = "pencil",
})
