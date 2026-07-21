--[[
    ============================================================
      🔑  KEY SYSTEM  —  Standalone, executor-agnostic key gate
    ============================================================

    A self-contained key system for Roblox script hubs. No third-party
    loadstring, no external UI library — the GUI is drawn with plain
    Instances so it runs anywhere (Delta, Xeno, Solara, Codex, Wave,
    Fluxus, Synapse X, KRNL, Studio, ...).

    ------------------------------------------------------------
    USAGE
    ------------------------------------------------------------

    local KeySystem = loadstring(game:HttpGet(
        "https://raw.githubusercontent.com/robloxscripter6245366542/roblox-lua-obscator/claude/roblox-key-system-5pxqf9/KeySystem.lua"
    ))()

    local ok = KeySystem({
        Title    = "Claude Hub",
        Subtitle = "Enter your key to continue",

        -- 1) Static keys checked locally (fast, offline):
        Keys = { "claude-free-2026", "vip-key-123" },

        -- 2) OR fetch valid keys from a URL (one key per line, or JSON array).
        --    Comments/blank lines are ignored. Optional — leave nil to skip.
        KeyLink = nil, -- e.g. "https://pastebin.com/raw/xxxxx"

        -- Where users go to get a key ("Get Key" button copies this):
        GetKeyLink = "https://your-getkey-link.example/",

        -- Remember a valid key so the user isn't asked again:
        SaveKey  = true,
        FileName = "ClaudeHub_key.txt",

        -- Optional: lock keys to the machine that first used them.
        -- Requires a KeyLink returning "key:hwid" pairs, or is a no-op.
        HWIDLock = false,

        -- Callbacks (optional):
        OnSuccess = function(key) print("Unlocked with", key) end,
        OnFail    = function() warn("Wrong key") end,
    })

    if not ok then return end        -- block the rest of the script
    -- ... your hub loads here ...

    Returns true (yielding until a valid key is entered) or false if the
    user closes the window.
    ============================================================
]]

--// executor-agnostic helpers ------------------------------------------------
local cloneref = (cloneref or clonereference or function(o) return o end)

local Players           = cloneref(game:GetService("Players"))
local HttpService       = cloneref(game:GetService("HttpService"))
local UserInputService  = cloneref(game:GetService("UserInputService"))
local TweenService      = cloneref(game:GetService("TweenService"))
local RunService        = cloneref(game:GetService("RunService"))

local LocalPlayer = Players.LocalPlayer

-- filesystem functions vary by executor; probe for what exists
local fs_writefile = writefile
local fs_readfile  = readfile
local fs_isfile    = isfile
local fs_delfile   = delfile
local fs_makefolder = makefolder
local fs_isfolder   = isfolder

-- clipboard (for the Get Key button)
local setclip = (setclipboard or set_clipboard or toclipboard or (Clipboard and Clipboard.set))

-- HWID (best effort across executors)
local function getHWID()
    local ok, id = pcall(function()
        if gethwid then return gethwid() end
        if syn and syn.crypt and syn.crypt.hwid then return syn.crypt.hwid() end
        return game:GetService("RbxAnalyticsService"):GetClientId()
    end)
    return ok and tostring(id) or "unknown-hwid"
end

-- cross-executor HTTP GET
local function httpGet(url)
    local ok, body = pcall(function() return game:HttpGet(url, true) end)
    if ok and body then return body end
    local req = (syn and syn.request) or (http and http.request) or http_request
        or request or (fluxus and fluxus.request)
    if req then
        local r
        ok = pcall(function() r = req({ Url = url, Method = "GET" }) end)
        if ok and r and (r.Body or r.body) then return r.Body or r.body end
    end
    return nil
end

--// main ---------------------------------------------------------------------
local function KeySystem(cfg)
    cfg = cfg or {}
    local Title      = cfg.Title      or "Key System"
    local Subtitle   = cfg.Subtitle   or "Enter your key to continue"
    local Keys       = cfg.Keys       or {}
    local KeyLink    = cfg.KeyLink
    local GetKeyLink = cfg.GetKeyLink  or ""
    local SaveKey    = cfg.SaveKey ~= false
    local FileName   = cfg.FileName   or "KeySystem_key.txt"
    local HWIDLock   = cfg.HWIDLock == true
    local OnSuccess  = cfg.OnSuccess
    local OnFail     = cfg.OnFail

    local SavePath = "KeySystem/" .. FileName
    local HWID = getHWID()

    --// key validation -------------------------------------------------------
    -- Returns true if `key` is valid. Merges static Keys with remote KeyLink.
    local function fetchRemoteKeys()
        if not KeyLink then return nil end
        local body = httpGet(KeyLink)
        if not body then return nil end
        local list = {}
        -- try JSON array first
        local okJson, decoded = pcall(function()
            return HttpService:JSONDecode(body)
        end)
        if okJson and type(decoded) == "table" then
            for _, v in pairs(decoded) do list[#list + 1] = tostring(v) end
        else
            -- fall back to line-delimited (ignore blanks / # comments)
            for line in tostring(body):gmatch("[^\r\n]+") do
                line = line:gsub("^%s+", ""):gsub("%s+$", "")
                if line ~= "" and line:sub(1, 1) ~= "#" then
                    list[#list + 1] = line
                end
            end
        end
        return list
    end

    local function isValid(key)
        if key == nil or key == "" then return false end

        -- static keys
        for _, k in ipairs(Keys) do
            if key == k then return true end
        end

        -- remote keys
        local remote = fetchRemoteKeys()
        if remote then
            for _, entry in ipairs(remote) do
                if HWIDLock and entry:find(":") then
                    -- format "key:hwid" — both must match
                    local k, h = entry:match("^(.-):(.*)$")
                    if k == key and h == HWID then return true end
                elseif entry == key then
                    return true
                end
            end
        end

        return false
    end

    --// saved-key check ------------------------------------------------------
    if SaveKey and fs_readfile and fs_isfile then
        local ok, saved = pcall(function()
            if fs_isfile(SavePath) then return fs_readfile(SavePath) end
        end)
        if ok and saved and saved ~= "" then
            if isValid(saved) then
                if OnSuccess then pcall(OnSuccess, saved) end
                return true
            else
                -- stale/invalid saved key: clear it
                pcall(function() if fs_delfile then fs_delfile(SavePath) end end)
            end
        end
    end

    local function persist(key)
        if not SaveKey or not fs_writefile then return end
        pcall(function()
            if fs_makefolder and fs_isfolder and not fs_isfolder("KeySystem") then
                fs_makefolder("KeySystem")
            end
            fs_writefile(SavePath, key)
        end)
    end

    --// GUI ------------------------------------------------------------------
    -- parent to CoreGui/gethui so it survives and hides from game scripts
    local parent = (gethui and gethui())
        or (cloneref(game:GetService("CoreGui")))
        or LocalPlayer:WaitForChild("PlayerGui")

    -- clean up any previous instance
    pcall(function()
        local old = parent:FindFirstChild("ClaudeKeySystem")
        if old then old:Destroy() end
    end)

    local ScreenGui = Instance.new("ScreenGui")
    ScreenGui.Name = "ClaudeKeySystem"
    ScreenGui.ResetOnSpawn = false
    ScreenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
    ScreenGui.IgnoreGuiInset = true
    ScreenGui.DisplayOrder = 9999
    ScreenGui.Parent = parent

    local function corner(inst, r)
        local c = Instance.new("UICorner")
        c.CornerRadius = UDim2.new(0, r)
        c.Parent = inst
    end

    local Main = Instance.new("Frame")
    Main.Name = "Main"
    Main.Size = UDim2.new(0, 380, 0, 240)
    Main.Position = UDim2.new(0.5, -190, 0.5, -120)
    Main.BackgroundColor3 = Color3.fromRGB(20, 20, 28)
    Main.BorderSizePixel = 0
    Main.Parent = ScreenGui
    corner(Main, 12)

    local stroke = Instance.new("UIStroke")
    stroke.Color = Color3.fromRGB(120, 90, 220)
    stroke.Thickness = 1.5
    stroke.Transparency = 0.3
    stroke.Parent = Main

    local grad = Instance.new("UIGradient")
    grad.Rotation = 90
    grad.Color = ColorSequence.new({
        ColorSequenceKeypoint.new(0, Color3.fromRGB(28, 24, 40)),
        ColorSequenceKeypoint.new(1, Color3.fromRGB(16, 16, 24)),
    })
    grad.Parent = Main

    local TitleLbl = Instance.new("TextLabel")
    TitleLbl.BackgroundTransparency = 1
    TitleLbl.Position = UDim2.new(0, 20, 0, 18)
    TitleLbl.Size = UDim2.new(1, -40, 0, 26)
    TitleLbl.Font = Enum.Font.GothamBold
    TitleLbl.Text = Title
    TitleLbl.TextColor3 = Color3.fromRGB(235, 235, 245)
    TitleLbl.TextSize = 20
    TitleLbl.TextXAlignment = Enum.TextXAlignment.Left
    TitleLbl.Parent = Main

    local SubLbl = Instance.new("TextLabel")
    SubLbl.BackgroundTransparency = 1
    SubLbl.Position = UDim2.new(0, 20, 0, 46)
    SubLbl.Size = UDim2.new(1, -40, 0, 18)
    SubLbl.Font = Enum.Font.Gotham
    SubLbl.Text = Subtitle
    SubLbl.TextColor3 = Color3.fromRGB(150, 150, 170)
    SubLbl.TextSize = 13
    SubLbl.TextXAlignment = Enum.TextXAlignment.Left
    SubLbl.Parent = Main

    -- close button
    local Close = Instance.new("TextButton")
    Close.Size = UDim2.new(0, 28, 0, 28)
    Close.Position = UDim2.new(1, -38, 0, 16)
    Close.BackgroundColor3 = Color3.fromRGB(40, 36, 52)
    Close.Text = "✕"
    Close.Font = Enum.Font.GothamBold
    Close.TextColor3 = Color3.fromRGB(200, 200, 210)
    Close.TextSize = 14
    Close.AutoButtonColor = true
    Close.Parent = Main
    corner(Close, 8)

    -- key input box
    local Box = Instance.new("TextBox")
    Box.Size = UDim2.new(1, -40, 0, 44)
    Box.Position = UDim2.new(0, 20, 0, 84)
    Box.BackgroundColor3 = Color3.fromRGB(30, 28, 40)
    Box.PlaceholderText = "Paste your key here..."
    Box.PlaceholderColor3 = Color3.fromRGB(110, 110, 130)
    Box.Text = ""
    Box.Font = Enum.Font.Gotham
    Box.TextColor3 = Color3.fromRGB(235, 235, 245)
    Box.TextSize = 15
    Box.ClearTextOnFocus = false
    Box.Parent = Main
    corner(Box, 8)
    local boxStroke = Instance.new("UIStroke")
    boxStroke.Color = Color3.fromRGB(70, 60, 100)
    boxStroke.Thickness = 1
    boxStroke.Parent = Box

    -- status label
    local Status = Instance.new("TextLabel")
    Status.BackgroundTransparency = 1
    Status.Position = UDim2.new(0, 20, 0, 132)
    Status.Size = UDim2.new(1, -40, 0, 18)
    Status.Font = Enum.Font.Gotham
    Status.Text = ""
    Status.TextColor3 = Color3.fromRGB(230, 90, 90)
    Status.TextSize = 12
    Status.TextXAlignment = Enum.TextXAlignment.Left
    Status.Parent = Main

    -- buttons row
    local GetKey = Instance.new("TextButton")
    GetKey.Size = UDim2.new(0.5, -25, 0, 40)
    GetKey.Position = UDim2.new(0, 20, 0, 158)
    GetKey.BackgroundColor3 = Color3.fromRGB(40, 36, 52)
    GetKey.Text = "Get Key"
    GetKey.Font = Enum.Font.GothamMedium
    GetKey.TextColor3 = Color3.fromRGB(220, 220, 230)
    GetKey.TextSize = 14
    GetKey.Parent = Main
    corner(GetKey, 8)

    local Submit = Instance.new("TextButton")
    Submit.Size = UDim2.new(0.5, -25, 0, 40)
    Submit.Position = UDim2.new(0.5, 5, 0, 158)
    Submit.BackgroundColor3 = Color3.fromRGB(110, 80, 220)
    Submit.Text = "Check Key"
    Submit.Font = Enum.Font.GothamBold
    Submit.TextColor3 = Color3.fromRGB(255, 255, 255)
    Submit.TextSize = 14
    Submit.Parent = Main
    corner(Submit, 8)

    -- credit
    local Credit = Instance.new("TextLabel")
    Credit.BackgroundTransparency = 1
    Credit.Position = UDim2.new(0, 20, 1, -26)
    Credit.Size = UDim2.new(1, -40, 0, 16)
    Credit.Font = Enum.Font.Gotham
    Credit.Text = "🔑 Key System"
    Credit.TextColor3 = Color3.fromRGB(90, 90, 110)
    Credit.TextSize = 11
    Credit.TextXAlignment = Enum.TextXAlignment.Center
    Credit.Parent = Main

    --// dragging (mouse + touch) ---------------------------------------------
    do
        local dragging, dragStart, startPos
        local function update(input)
            local delta = input.Position - dragStart
            Main.Position = UDim2.new(
                startPos.X.Scale, startPos.X.Offset + delta.X,
                startPos.Y.Scale, startPos.Y.Offset + delta.Y)
        end
        Main.InputBegan:Connect(function(input)
            if input.UserInputType == Enum.UserInputType.MouseButton1
            or input.UserInputType == Enum.UserInputType.Touch then
                dragging = true
                dragStart = input.Position
                startPos = Main.Position
                input.Changed:Connect(function()
                    if input.UserInputState == Enum.UserInputState.End then
                        dragging = false
                    end
                end)
            end
        end)
        UserInputService.InputChanged:Connect(function(input)
            if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement
            or input.UserInputType == Enum.UserInputType.Touch) then
                update(input)
            end
        end)
    end

    --// interaction ----------------------------------------------------------
    local result = nil        -- true = success, false = closed
    local finished = false

    local function setStatus(text, good)
        Status.Text = text
        Status.TextColor3 = good and Color3.fromRGB(90, 210, 120)
                                 or Color3.fromRGB(230, 90, 90)
    end

    local function finish(val)
        if finished then return end
        finished = true
        result = val
        -- fade out then destroy
        pcall(function()
            TweenService:Create(Main, TweenInfo.new(0.2), {
                BackgroundTransparency = 1,
            }):Play()
        end)
        task.delay(0.25, function()
            pcall(function() ScreenGui:Destroy() end)
        end)
    end

    local checking = false
    local function attempt()
        if checking then return end
        local key = Box.Text
        if key == "" then
            setStatus("Please enter a key.", false)
            return
        end
        checking = true
        Submit.Text = "Checking..."
        setStatus("Verifying key...", true)

        task.spawn(function()
            local ok = isValid(key)
            checking = false
            Submit.Text = "Check Key"
            if ok then
                setStatus("Correct! Unlocking...", true)
                persist(key)
                if OnSuccess then pcall(OnSuccess, key) end
                finish(true)
            else
                setStatus("Invalid key. Try again.", false)
                boxStroke.Color = Color3.fromRGB(230, 90, 90)
                task.delay(1.2, function()
                    boxStroke.Color = Color3.fromRGB(70, 60, 100)
                end)
                if OnFail then pcall(OnFail) end
            end
        end)
    end

    Submit.MouseButton1Click:Connect(attempt)
    Box.FocusLost:Connect(function(enterPressed)
        if enterPressed then attempt() end
    end)

    GetKey.MouseButton1Click:Connect(function()
        if setclip and GetKeyLink ~= "" then
            pcall(setclip, GetKeyLink)
            setStatus("Get-key link copied to clipboard!", true)
        elseif GetKeyLink ~= "" then
            setStatus("Get key at: " .. GetKeyLink, true)
        else
            setStatus("No get-key link configured.", false)
        end
    end)

    Close.MouseButton1Click:Connect(function()
        finish(false)
    end)

    -- entry animation
    Main.Size = UDim2.new(0, 380, 0, 0)
    TweenService:Create(Main, TweenInfo.new(0.3, Enum.EasingStyle.Back), {
        Size = UDim2.new(0, 380, 0, 240),
    }):Play()

    --// yield until finished --------------------------------------------------
    while not finished do
        task.wait(0.05)
    end

    return result == true
end

return KeySystem
