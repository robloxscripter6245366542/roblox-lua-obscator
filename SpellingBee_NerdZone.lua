-- ═══════════════════════════════════════════════════════════════════════
--  SPELLING BEE SCRIPT  |  by Nerd Zone
--  UI: Rayfield Library
--  Features: Auto-Bot, Speed Typer, Speed/Jump mods, Anti-AFK
-- ═══════════════════════════════════════════════════════════════════════

local Rayfield = loadstring(game:HttpGet("https://sirius.menu/rayfield"))()

-- ── Services ──────────────────────────────────────────────────────────
local Players    = game:GetService("Players")
local UIS        = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local VirtualUser = game:GetService("VirtualUser")
local TweenService = game:GetService("TweenService")
local LP         = Players.LocalPlayer
local PGui       = LP:WaitForChild("PlayerGui")

-- ── State ─────────────────────────────────────────────────────────────
local botEnabled    = false
local typingSpeed   = 0.05   -- seconds between each character (lower = faster)
local currentWord   = ""
local isTyping      = false
local antiAFK       = false
local infiniteJump  = false
local walkSpeed     = 16
local jumpPower     = 50

-- ── Rayfield Window ───────────────────────────────────────────────────
local Window = Rayfield:CreateWindow({
    Name             = "Spelling Bee  |  Nerd Zone",
    Icon             = "pencil",
    LoadingTitle     = "Nerd Zone",
    LoadingSubtitle  = "Spelling Bee Script",
    Theme            = "Default",
    DisableRayfieldPrompts  = false,
    DisableBuildWarnings    = true,
    ConfigurationSaving = {
        Enabled    = true,
        FolderName = "NerdZone",
        FileName   = "SpellingBee",
    },
    Discord  = { Enabled = false },
    KeySystem = false,
})

-- ═══════════════════════════════════════════════════════════════════════
--  HELPER: Locate the active answer TextBox in the game
-- ═══════════════════════════════════════════════════════════════════════
local function findAnswerBox()
    -- Most Spelling Bee games put the input box inside PlayerGui
    for _, obj in PGui:GetDescendants() do
        if obj:IsA("TextBox") and obj.TextEditable and obj.Visible then
            local n = obj.Name:lower()
            if n:find("answer") or n:find("input") or n:find("spell")
            or n:find("type")  or n:find("word")  or n:find("text") then
                return obj
            end
        end
    end
    -- Fallback: return the first visible, editable TextBox found
    for _, obj in PGui:GetDescendants() do
        if obj:IsA("TextBox") and obj.TextEditable and obj.Visible then
            return obj
        end
    end
    -- Also check workspace GUIs (BillboardGuis etc.)
    for _, obj in workspace:GetDescendants() do
        if obj:IsA("TextBox") and obj.TextEditable and obj.Visible then
            return obj
        end
    end
    return nil
end

-- ── Locate the label that shows the word to spell ─────────────────────
local function findWordLabel()
    local candidates = {}
    for _, obj in PGui:GetDescendants() do
        if obj:IsA("TextLabel") and obj.Visible and obj.Text ~= "" then
            local n = obj.Name:lower()
            local t = obj.Text:lower()
            if n:find("word") or n:find("spell") or n:find("current")
            or n:find("question") or n:find("prompt") then
                table.insert(candidates, obj)
            end
        end
    end
    -- Return the one with the shortest, most word-like text
    table.sort(candidates, function(a, b)
        return #a.Text < #b.Text
    end)
    return candidates[1]
end

-- ── Type a string into a TextBox, one char at a time ──────────────────
local function typeWord(box, word, speed)
    if isTyping then return end
    isTyping = true
    box.Text = ""
    box:CaptureFocus()
    for i = 1, #word do
        if not isTyping then break end  -- cancel if bot toggled off mid-type
        box.Text = word:sub(1, i)
        task.wait(speed)
    end
    task.wait(0.05)
    box:ReleaseFocus(true)   -- submit (fires FocusLost with enterPressed=true)
    task.wait(0.1)
    isTyping = false
end

-- ── Submit via RemoteEvent as fallback ────────────────────────────────
local function tryRemoteSubmit(word)
    local RS = game:GetService("ReplicatedStorage")
    for _, obj in RS:GetDescendants() do
        if obj:IsA("RemoteEvent") then
            local n = obj.Name:lower()
            if n:find("answer") or n:find("submit") or n:find("spell") or n:find("word") then
                pcall(function() obj:FireServer(word) end)
                return true
            end
        end
    end
    return false
end

-- ═══════════════════════════════════════════════════════════════════════
--  TABS
-- ═══════════════════════════════════════════════════════════════════════
local TabBot    = Window:CreateTab("Bot",    "bot")
local TabPlayer = Window:CreateTab("Player", "user")
local TabMisc   = Window:CreateTab("Misc",   "settings")

-- ═══════════════════════════════════════════════════════════════════════
--  BOT TAB
-- ═══════════════════════════════════════════════════════════════════════
TabBot:CreateSection("Auto Typer Bot")

-- Live word display
local WordLabel = TabBot:CreateLabel("Current Word: —", "book-open", Color3.fromRGB(100, 200, 255), true)

-- Bot toggle
TabBot:CreateToggle({
    Name         = "Enable Bot  (auto-detects & types)",
    CurrentValue = false,
    Flag         = "BotEnabled",
    Callback     = function(v)
        botEnabled = v
        if not v then isTyping = false end
    end,
})

-- Typing speed slider  (0.00 = instant, 0.15 = realistic slow)
TabBot:CreateSlider({
    Name         = "Typing Speed  (lower = faster)",
    Range        = {0, 15},
    Increment    = 1,
    Suffix       = "",
    CurrentValue = 5,
    Flag         = "TypingSpeed",
    Callback     = function(v)
        typingSpeed = v / 100   -- 5 → 0.05 s between chars
    end,
})

TabBot:CreateSection("Manual Control")

-- Manual word input
TabBot:CreateInput({
    Name                  = "Set Word Manually",
    CurrentValue          = "",
    PlaceholderText       = "Type the word here…",
    RemoveTextAfterFocusLost = false,
    Flag                  = "ManualWord",
    Callback              = function(text)
        if text ~= "" then
            currentWord = text:lower():gsub("^%s*(.-)%s*$", "%1")
            WordLabel:Set("Current Word: " .. currentWord)
        end
    end,
})

-- Detect word button
TabBot:CreateButton({
    Name     = "Detect Word from Game",
    Callback = function()
        local lbl = findWordLabel()
        if lbl then
            local w = lbl.Text:lower():gsub("^%s*(.-)%s*$", "%1")
            currentWord = w
            WordLabel:Set("Current Word: " .. w)
            Rayfield:Notify({ Title="Word Found", Content=w, Duration=3, Image="check" })
        else
            Rayfield:Notify({ Title="Not Found", Content="Could not find a word label.", Duration=3, Image="x" })
        end
    end,
})

-- Type now button
TabBot:CreateButton({
    Name     = "▶  Type Answer Now",
    Callback = function()
        if currentWord == "" then
            Rayfield:Notify({ Title="No Word", Content="Set a word first.", Duration=3, Image="alert-circle" })
            return
        end
        local box = findAnswerBox()
        if box then
            task.spawn(function() typeWord(box, currentWord, typingSpeed) end)
            Rayfield:Notify({ Title="Typing…", Content=currentWord, Duration=2, Image="pencil" })
        else
            -- Try remote fallback
            local ok = tryRemoteSubmit(currentWord)
            Rayfield:Notify({
                Title   = ok and "Submitted via Remote" or "No Input Found",
                Content = ok and currentWord or "Could not find a TextBox or RemoteEvent.",
                Duration = 3,
                Image   = ok and "check" or "x",
            })
        end
    end,
})

-- Stop typing button
TabBot:CreateButton({
    Name     = "■  Stop Typing",
    Callback = function()
        isTyping = false
        Rayfield:Notify({ Title="Stopped", Content="Typing cancelled.", Duration=2, Image="square" })
    end,
})

-- ═══════════════════════════════════════════════════════════════════════
--  PLAYER TAB
-- ═══════════════════════════════════════════════════════════════════════
TabPlayer:CreateSection("Movement")

TabPlayer:CreateSlider({
    Name         = "Walk Speed",
    Range        = {1, 300},
    Increment    = 1,
    Suffix       = "",
    CurrentValue = 16,
    Flag         = "WalkSpeed",
    Callback     = function(v)
        walkSpeed = v
        pcall(function()
            LP.Character.Humanoid.WalkSpeed = v
        end)
    end,
})

TabPlayer:CreateSlider({
    Name         = "Jump Power",
    Range        = {1, 300},
    Increment    = 1,
    Suffix       = "",
    CurrentValue = 50,
    Flag         = "JumpPower",
    Callback     = function(v)
        jumpPower = v
        pcall(function()
            LP.Character.Humanoid.JumpPower = v
        end)
    end,
})

TabPlayer:CreateToggle({
    Name         = "Infinite Jump",
    CurrentValue = false,
    Flag         = "InfJump",
    Callback     = function(v) infiniteJump = v end,
})

TabPlayer:CreateSection("Character")

TabPlayer:CreateButton({
    Name     = "Reset Character",
    Callback = function()
        pcall(function() LP.Character.Humanoid.Health = 0 end)
    end,
})

-- ═══════════════════════════════════════════════════════════════════════
--  MISC TAB
-- ═══════════════════════════════════════════════════════════════════════
TabMisc:CreateSection("Utilities")

TabMisc:CreateToggle({
    Name         = "Anti-AFK",
    CurrentValue = false,
    Flag         = "AntiAFK",
    Callback     = function(v) antiAFK = v end,
})

TabMisc:CreateSection("Info")
TabMisc:CreateLabel("Script by Nerd Zone", "zap",    Color3.fromRGB(100, 180, 255), true)
TabMisc:CreateLabel("UI:  Rayfield Library", "layout", Color3.fromRGB(160, 160, 160), true)

-- ═══════════════════════════════════════════════════════════════════════
--  BACKGROUND LOOPS
-- ═══════════════════════════════════════════════════════════════════════

-- Infinite jump
UIS.JumpRequest:Connect(function()
    if infiniteJump then
        pcall(function()
            LP.Character.Humanoid:ChangeState(Enum.HumanoidStateType.Jumping)
        end)
    end
end)

-- Anti-AFK heartbeat
local _afkTick = 0
RunService.Heartbeat:Connect(function()
    if antiAFK then
        _afkTick += 1
        if _afkTick >= 60 then
            _afkTick = 0
            pcall(function() VirtualUser:CaptureController() end)
        end
    end
end)

-- Re-apply speed on respawn
LP.CharacterAdded:Connect(function(char)
    task.wait(0.5)
    pcall(function()
        char.Humanoid.WalkSpeed = walkSpeed
        char.Humanoid.JumpPower = jumpPower
    end)
end)

-- Bot auto-loop: detect word every second and type it
task.spawn(function()
    while true do
        task.wait(1)
        if botEnabled and not isTyping then
            -- Try to detect the word from the game UI
            local lbl = findWordLabel()
            if lbl then
                local w = lbl.Text:lower():gsub("^%s*(.-)%s*$", "%1")
                -- Only act if the word changed
                if w ~= "" and w ~= currentWord then
                    currentWord = w
                    WordLabel:Set("Current Word: " .. w)
                end
            end

            -- If we have a word and a box, type it
            if currentWord ~= "" then
                local box = findAnswerBox()
                if box and box.Text ~= currentWord then
                    typeWord(box, currentWord, typingSpeed)
                end
            end
        end
    end
end)

-- Load saved configuration
Rayfield:LoadConfiguration()

Rayfield:Notify({
    Title   = "Nerd Zone  |  Spelling Bee",
    Content = "Script loaded! Go to the Bot tab to start.",
    Duration = 5,
    Image   = "pencil",
})
