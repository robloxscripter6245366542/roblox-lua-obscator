--[[
    ============================================================
      🔑  KEY SYSTEM  —  Standalone, executor-agnostic key gate
      "World's best UI" edition: glass, blur, animated gradients,
      floating particles, spring motion, buttery micro-interactions.
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

        -- Optional look & feel:
        Accent   = Color3.fromRGB(124, 92, 255), -- primary accent
        Accent2  = Color3.fromRGB(236, 72, 153), -- gradient partner
        Blur     = true,                          -- backdrop blur

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
local Lighting          = cloneref(game:GetService("Lighting"))

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
    local Accent     = cfg.Accent  or Color3.fromRGB(124, 92, 255)
    local Accent2    = cfg.Accent2 or Color3.fromRGB(236, 72, 153)
    local UseBlur    = cfg.Blur ~= false

    local SavePath = "KeySystem/" .. FileName
    local HWID = getHWID()

    --// key validation -------------------------------------------------------
    local function fetchRemoteKeys()
        if not KeyLink then return nil end
        local body = httpGet(KeyLink)
        if not body then return nil end
        local list = {}
        local okJson, decoded = pcall(function()
            return HttpService:JSONDecode(body)
        end)
        if okJson and type(decoded) == "table" then
            for _, v in pairs(decoded) do list[#list + 1] = tostring(v) end
        else
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
        for _, k in ipairs(Keys) do
            if key == k then return true end
        end
        local remote = fetchRemoteKeys()
        if remote then
            for _, entry in ipairs(remote) do
                if HWIDLock and entry:find(":") then
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

    ------------------------------------------------------------------
    --  UI TOOLKIT  (small helpers for a consistent design system)
    ------------------------------------------------------------------
    local function tw(inst, time, props, style, dir)
        local t = TweenService:Create(inst, TweenInfo.new(
            time,
            style or Enum.EasingStyle.Quad,
            dir or Enum.EasingDirection.Out
        ), props)
        t:Play()
        return t
    end

    local function corner(inst, r)
        local c = Instance.new("UICorner")
        c.CornerRadius = UDim.new(0, r)
        c.Parent = inst
        return c
    end

    local function padding(inst, all)
        local p = Instance.new("UIPadding")
        p.PaddingTop = UDim.new(0, all); p.PaddingBottom = UDim.new(0, all)
        p.PaddingLeft = UDim.new(0, all); p.PaddingRight = UDim.new(0, all)
        p.Parent = inst
        return p
    end

    local function stroke(inst, color, thickness, transparency)
        local s = Instance.new("UIStroke")
        s.Color = color or Color3.fromRGB(255, 255, 255)
        s.Thickness = thickness or 1
        s.Transparency = transparency or 0
        s.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
        s.Parent = inst
        return s
    end

    local function linearGradient(inst, c1, c2, rotation)
        local g = Instance.new("UIGradient")
        g.Color = ColorSequence.new({
            ColorSequenceKeypoint.new(0, c1),
            ColorSequenceKeypoint.new(1, c2),
        })
        g.Rotation = rotation or 0
        g.Parent = inst
        return g
    end

    -- soft drop shadow (9-slice) behind a frame
    local function dropShadow(parent, spread, transparency, color)
        local s = Instance.new("ImageLabel")
        s.Name = "Shadow"
        s.BackgroundTransparency = 1
        s.Image = "rbxassetid://6014261993"
        s.ImageColor3 = color or Color3.fromRGB(0, 0, 0)
        s.ImageTransparency = transparency or 0.45
        s.ScaleType = Enum.ScaleType.Slice
        s.SliceCenter = Rect.new(49, 49, 450, 450)
        s.Size = UDim2.new(1, spread, 1, spread)
        s.Position = UDim2.new(0.5, 0, 0.5, 0)
        s.AnchorPoint = Vector2.new(0.5, 0.5)
        s.ZIndex = (parent.ZIndex or 1) - 1
        s.Parent = parent
        return s
    end

    -- continuously rotate a UIGradient (living gradient border/glow)
    local function spin(gradient, speed)
        task.spawn(function()
            while gradient.Parent do
                gradient.Rotation = (gradient.Rotation + (speed or 1.4)) % 360
                task.wait()
            end
        end)
    end

    ------------------------------------------------------------------
    --  BUILD
    ------------------------------------------------------------------
    local parent = (gethui and gethui())
        or (cloneref(game:GetService("CoreGui")))
        or LocalPlayer:WaitForChild("PlayerGui")

    pcall(function()
        local old = parent:FindFirstChild("ClaudeKeySystem")
        if old then old:Destroy() end
    end)

    local ScreenGui = Instance.new("ScreenGui")
    ScreenGui.Name = "ClaudeKeySystem"
    ScreenGui.ResetOnSpawn = false
    ScreenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
    ScreenGui.IgnoreGuiInset = true
    ScreenGui.DisplayOrder = 999999
    ScreenGui.Parent = parent

    -- backdrop blur (fades in with the modal)
    local blur
    if UseBlur then
        pcall(function()
            blur = Instance.new("BlurEffect")
            blur.Size = 0
            blur.Parent = Lighting
            tw(blur, 0.35, { Size = 18 })
        end)
    end

    -- dim overlay (also catches clicks outside the card)
    local Dim = Instance.new("TextButton")
    Dim.Name = "Dim"
    Dim.AutoButtonColor = false
    Dim.Text = ""
    Dim.Size = UDim2.new(1, 0, 1, 0)
    Dim.BackgroundColor3 = Color3.fromRGB(6, 6, 10)
    Dim.BackgroundTransparency = 1
    Dim.BorderSizePixel = 0
    Dim.Parent = ScreenGui
    tw(Dim, 0.3, { BackgroundTransparency = 0.35 })

    -- CARD --------------------------------------------------------------------
    local Card = Instance.new("Frame")
    Card.Name = "Card"
    Card.AnchorPoint = Vector2.new(0.5, 0.5)
    Card.Position = UDim2.new(0.5, 0, 0.5, 0)
    Card.Size = UDim2.new(0, 440, 0, 344)
    Card.BackgroundColor3 = Color3.fromRGB(17, 17, 24)
    Card.BorderSizePixel = 0
    Card.ClipsDescendants = true
    Card.ZIndex = 2
    Card.Parent = ScreenGui
    corner(Card, 20)
    linearGradient(Card, Color3.fromRGB(26, 24, 38), Color3.fromRGB(14, 14, 20), 115)
    dropShadow(Card, 90, 0.35)

    -- scale for the spring entrance
    local Scale = Instance.new("UIScale")
    Scale.Scale = 0.86
    Scale.Parent = Card

    -- animated gradient border (living glow)
    local Border = stroke(Card, Color3.fromRGB(255, 255, 255), 1.6, 0.15)
    local BorderGrad = Instance.new("UIGradient")
    BorderGrad.Color = ColorSequence.new({
        ColorSequenceKeypoint.new(0.00, Accent),
        ColorSequenceKeypoint.new(0.50, Accent2),
        ColorSequenceKeypoint.new(1.00, Accent),
    })
    BorderGrad.Parent = Border
    spin(BorderGrad, 1.6)

    -- ambient glow blob behind the header
    local Glow = Instance.new("ImageLabel")
    Glow.BackgroundTransparency = 1
    Glow.Image = "rbxassetid://6014261993"
    Glow.ImageColor3 = Accent
    Glow.ImageTransparency = 0.55
    Glow.ScaleType = Enum.ScaleType.Slice
    Glow.SliceCenter = Rect.new(49, 49, 450, 450)
    Glow.Size = UDim2.new(0, 260, 0, 180)
    Glow.Position = UDim2.new(0.5, 0, 0, -50)
    Glow.AnchorPoint = Vector2.new(0.5, 0)
    Glow.ZIndex = 2
    Glow.Parent = Card

    -- floating particles (subtle depth)
    local FX = Instance.new("Frame")
    FX.BackgroundTransparency = 1
    FX.Size = UDim2.new(1, 0, 1, 0)
    FX.ZIndex = 2
    FX.Parent = Card
    for i = 1, 14 do
        local dot = Instance.new("Frame")
        dot.BackgroundColor3 = (i % 2 == 0) and Accent or Accent2
        dot.BackgroundTransparency = 0.6 + math.random() * 0.25
        local sz = math.random(3, 6)
        dot.Size = UDim2.new(0, sz, 0, sz)
        dot.Position = UDim2.new(math.random(), 0, math.random(), 0)
        dot.ZIndex = 2
        dot.Parent = FX
        corner(dot, sz)
        task.spawn(function()
            while dot.Parent do
                local dur = math.random(35, 70) / 10
                local nx = math.clamp(dot.Position.X.Scale + (math.random() - 0.5) * 0.4, 0.05, 0.95)
                local ny = math.clamp(dot.Position.Y.Scale - math.random(20, 45) / 100, 0.05, 0.95)
                tw(dot, dur, { Position = UDim2.new(nx, 0, ny, 0) }, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut)
                task.wait(dur)
                if dot.Position.Y.Scale <= 0.1 then
                    dot.Position = UDim2.new(math.random(), 0, math.random(85, 98) / 100, 0)
                end
            end
        end)
    end

    -- content layer (above FX)
    local Content = Instance.new("Frame")
    Content.BackgroundTransparency = 1
    Content.Size = UDim2.new(1, 0, 1, 0)
    Content.ZIndex = 3
    Content.Parent = Card

    -- lock badge --------------------------------------------------------------
    local Badge = Instance.new("Frame")
    Badge.AnchorPoint = Vector2.new(0.5, 0)
    Badge.Position = UDim2.new(0.5, 0, 0, 26)
    Badge.Size = UDim2.new(0, 58, 0, 58)
    Badge.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
    Badge.ZIndex = 3
    Badge.Parent = Content
    corner(Badge, 16)
    linearGradient(Badge, Accent, Accent2, 135)
    stroke(Badge, Color3.fromRGB(255, 255, 255), 1, 0.7)
    dropShadow(Badge, 46, 0.4, Accent)

    local Lock = Instance.new("TextLabel")
    Lock.BackgroundTransparency = 1
    Lock.Size = UDim2.new(1, 0, 1, 0)
    Lock.Font = Enum.Font.GothamBold
    Lock.Text = "🔒"
    Lock.TextSize = 26
    Lock.TextColor3 = Color3.fromRGB(255, 255, 255)
    Lock.ZIndex = 4
    Lock.Parent = Badge
    -- gentle breathing on the badge
    task.spawn(function()
        while Badge.Parent do
            tw(Badge, 1.6, { Size = UDim2.new(0, 62, 0, 62) }, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut)
            task.wait(1.6)
            if not Badge.Parent then break end
            tw(Badge, 1.6, { Size = UDim2.new(0, 58, 0, 58) }, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut)
            task.wait(1.6)
        end
    end)

    -- title (gradient text) ---------------------------------------------------
    local TitleLbl = Instance.new("TextLabel")
    TitleLbl.BackgroundTransparency = 1
    TitleLbl.Position = UDim2.new(0, 24, 0, 96)
    TitleLbl.Size = UDim2.new(1, -48, 0, 28)
    TitleLbl.Font = Enum.Font.GothamBold
    TitleLbl.Text = Title
    TitleLbl.TextColor3 = Color3.fromRGB(245, 245, 250)
    TitleLbl.TextSize = 23
    TitleLbl.ZIndex = 3
    TitleLbl.Parent = Content
    linearGradient(TitleLbl, Color3.fromRGB(255, 255, 255), Color3.fromRGB(198, 190, 255), 90)

    local SubLbl = Instance.new("TextLabel")
    SubLbl.BackgroundTransparency = 1
    SubLbl.Position = UDim2.new(0, 24, 0, 126)
    SubLbl.Size = UDim2.new(1, -48, 0, 18)
    SubLbl.Font = Enum.Font.GothamMedium
    SubLbl.Text = Subtitle
    SubLbl.TextColor3 = Color3.fromRGB(150, 150, 170)
    SubLbl.TextSize = 13
    SubLbl.ZIndex = 3
    SubLbl.Parent = Content

    -- close button ------------------------------------------------------------
    local Close = Instance.new("TextButton")
    Close.AnchorPoint = Vector2.new(1, 0)
    Close.Size = UDim2.new(0, 30, 0, 30)
    Close.Position = UDim2.new(1, -16, 0, 16)
    Close.BackgroundColor3 = Color3.fromRGB(38, 36, 50)
    Close.BackgroundTransparency = 0.25
    Close.Text = "✕"
    Close.Font = Enum.Font.GothamBold
    Close.TextColor3 = Color3.fromRGB(190, 190, 205)
    Close.TextSize = 14
    Close.AutoButtonColor = false
    Close.ZIndex = 4
    Close.Parent = Content
    corner(Close, 9)
    Close.MouseEnter:Connect(function()
        tw(Close, 0.15, { BackgroundColor3 = Color3.fromRGB(220, 70, 90), BackgroundTransparency = 0 })
    end)
    Close.MouseLeave:Connect(function()
        tw(Close, 0.15, { BackgroundColor3 = Color3.fromRGB(38, 36, 50), BackgroundTransparency = 0.25 })
    end)

    -- input field -------------------------------------------------------------
    local InputWrap = Instance.new("Frame")
    InputWrap.Position = UDim2.new(0, 24, 0, 160)
    InputWrap.Size = UDim2.new(1, -48, 0, 50)
    InputWrap.BackgroundColor3 = Color3.fromRGB(28, 27, 38)
    InputWrap.ZIndex = 3
    InputWrap.Parent = Content
    corner(InputWrap, 12)
    local InputStroke = stroke(InputWrap, Color3.fromRGB(60, 56, 82), 1.4, 0)

    local KeyIcon = Instance.new("TextLabel")
    KeyIcon.BackgroundTransparency = 1
    KeyIcon.Position = UDim2.new(0, 12, 0, 0)
    KeyIcon.Size = UDim2.new(0, 26, 1, 0)
    KeyIcon.Font = Enum.Font.GothamBold
    KeyIcon.Text = "🔑"
    KeyIcon.TextSize = 16
    KeyIcon.ZIndex = 4
    KeyIcon.Parent = InputWrap

    local Box = Instance.new("TextBox")
    Box.BackgroundTransparency = 1
    Box.Position = UDim2.new(0, 44, 0, 0)
    Box.Size = UDim2.new(1, -56, 1, 0)
    Box.PlaceholderText = "Paste your key here..."
    Box.PlaceholderColor3 = Color3.fromRGB(108, 108, 128)
    Box.Text = ""
    Box.Font = Enum.Font.GothamMedium
    Box.TextColor3 = Color3.fromRGB(240, 240, 248)
    Box.TextSize = 15
    Box.TextXAlignment = Enum.TextXAlignment.Left
    Box.ClearTextOnFocus = false
    Box.ZIndex = 4
    Box.Parent = InputWrap

    -- status line -------------------------------------------------------------
    local Status = Instance.new("TextLabel")
    Status.BackgroundTransparency = 1
    Status.Position = UDim2.new(0, 24, 0, 214)
    Status.Size = UDim2.new(1, -48, 0, 18)
    Status.Font = Enum.Font.GothamMedium
    Status.Text = ""
    Status.TextColor3 = Color3.fromRGB(235, 100, 110)
    Status.TextSize = 12.5
    Status.TextXAlignment = Enum.TextXAlignment.Left
    Status.ZIndex = 3
    Status.Parent = Content

    -- button factory (gradient / ghost, hover-lift, press-scale) --------------
    local function makeButton(opts)
        local btn = Instance.new("TextButton")
        btn.Size = opts.size
        btn.Position = opts.pos
        btn.AnchorPoint = opts.anchor or Vector2.new(0, 0)
        btn.AutoButtonColor = false
        btn.Text = opts.text
        btn.Font = Enum.Font.GothamBold
        btn.TextSize = 14.5
        btn.ZIndex = 3
        btn.Parent = Content
        corner(btn, 12)

        local baseColor, textColor, grad
        if opts.primary then
            baseColor = Color3.fromRGB(255, 255, 255)
            textColor = Color3.fromRGB(255, 255, 255)
            btn.BackgroundColor3 = baseColor
            grad = linearGradient(btn, Accent, Accent2, 0)
            spin(grad, 0.9)
            dropShadow(btn, 26, 0.55, Accent)
        else
            baseColor = Color3.fromRGB(34, 32, 46)
            textColor = Color3.fromRGB(215, 215, 228)
            btn.BackgroundColor3 = baseColor
            btn.BackgroundTransparency = 0.15
            stroke(btn, Color3.fromRGB(72, 66, 96), 1.2, 0.2)
        end
        btn.TextColor3 = textColor

        local scale = Instance.new("UIScale"); scale.Parent = btn
        btn.MouseEnter:Connect(function()
            tw(btn, 0.14, { Position = opts.pos - UDim2.new(0, 0, 0, 2) })
            tw(scale, 0.14, { Scale = 1.03 })
            if not opts.primary then
                tw(btn, 0.14, { BackgroundTransparency = 0 })
            end
        end)
        btn.MouseLeave:Connect(function()
            tw(btn, 0.14, { Position = opts.pos })
            tw(scale, 0.14, { Scale = 1 })
            if not opts.primary then
                tw(btn, 0.14, { BackgroundTransparency = 0.15 })
            end
        end)
        btn.MouseButton1Down:Connect(function()
            tw(scale, 0.08, { Scale = 0.96 })
        end)
        btn.MouseButton1Up:Connect(function()
            tw(scale, 0.12, { Scale = 1.03 }, Enum.EasingStyle.Back)
        end)
        return btn
    end

    local GetKey = makeButton({
        text = "Get Key",
        size = UDim2.new(0.42, -30, 0, 46),
        pos = UDim2.new(0, 24, 0, 244),
        primary = false,
    })

    local Submit = makeButton({
        text = "Unlock",
        size = UDim2.new(0.58, -18, 0, 46),
        pos = UDim2.new(0.42, 6, 0, 244),
        primary = true,
    })

    -- footer ------------------------------------------------------------------
    local Credit = Instance.new("TextLabel")
    Credit.BackgroundTransparency = 1
    Credit.Position = UDim2.new(0, 24, 1, -28)
    Credit.Size = UDim2.new(1, -48, 0, 16)
    Credit.Font = Enum.Font.GothamMedium
    Credit.Text = "🔑  Secured by Key System"
    Credit.TextColor3 = Color3.fromRGB(96, 94, 116)
    Credit.TextSize = 11
    Credit.TextXAlignment = Enum.TextXAlignment.Center
    Credit.ZIndex = 3
    Credit.Parent = Content

    --// dragging (mouse + touch) — grab anywhere on the card ------------------
    do
        local dragging, dragStart, startPos
        local function update(input)
            local delta = input.Position - dragStart
            Card.Position = UDim2.new(
                startPos.X.Scale, startPos.X.Offset + delta.X,
                startPos.Y.Scale, startPos.Y.Offset + delta.Y)
        end
        Card.InputBegan:Connect(function(input)
            if input.UserInputType == Enum.UserInputType.MouseButton1
            or input.UserInputType == Enum.UserInputType.Touch then
                dragging = true
                dragStart = input.Position
                startPos = Card.Position
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
    local result = nil
    local finished = false

    local function setStatus(text, kind)
        Status.Text = text
        if kind == "good" then
            Status.TextColor3 = Color3.fromRGB(74, 222, 128)
        elseif kind == "info" then
            Status.TextColor3 = Color3.fromRGB(150, 150, 175)
        else
            Status.TextColor3 = Color3.fromRGB(251, 113, 133)
        end
    end

    local function cleanup()
        pcall(function()
            if blur then tw(blur, 0.3, { Size = 0 }); task.delay(0.32, function() pcall(function() blur:Destroy() end) end) end
        end)
    end

    local function finish(val)
        if finished then return end
        finished = true
        result = val
        cleanup()
        tw(Dim, 0.25, { BackgroundTransparency = 1 })
        tw(Scale, 0.28, { Scale = 0.88 }, Enum.EasingStyle.Quad, Enum.EasingDirection.In)
        tw(Card, 0.28, { BackgroundTransparency = 1 })
        task.delay(0.3, function()
            pcall(function() ScreenGui:Destroy() end)
        end)
    end

    -- input focus glow
    Box.Focused:Connect(function()
        tw(InputStroke, 0.18, { Color = Accent, Transparency = 0 })
    end)
    Box.FocusLost:Connect(function()
        tw(InputStroke, 0.18, { Color = Color3.fromRGB(60, 56, 82) })
    end)

    local checking = false
    local function attempt()
        if checking then return end
        local key = Box.Text:gsub("^%s+", ""):gsub("%s+$", "")
        if key == "" then
            setStatus("Please enter a key.", "bad")
            tw(InputStroke, 0.15, { Color = Color3.fromRGB(251, 113, 133) })
            task.delay(1, function() tw(InputStroke, 0.2, { Color = Color3.fromRGB(60, 56, 82) }) end)
            return
        end
        checking = true
        Submit.Text = "Verifying"
        setStatus("Verifying key...", "info")

        -- animated "Verifying..." dots
        task.spawn(function()
            local dots = 0
            while checking do
                dots = (dots % 3) + 1
                Submit.Text = "Verifying" .. string.rep(".", dots)
                task.wait(0.25)
            end
        end)

        task.spawn(function()
            local ok = isValid(key)
            checking = false
            if ok then
                Submit.Text = "✓  Unlocked"
                setStatus("Correct! Loading...", "good")
                tw(InputStroke, 0.2, { Color = Color3.fromRGB(74, 222, 128) })
                Lock.Text = "🔓"
                persist(key)
                if OnSuccess then pcall(OnSuccess, key) end
                task.delay(0.55, function() finish(true) end)
            else
                Submit.Text = "Unlock"
                setStatus("Invalid key. Try again.", "bad")
                tw(InputStroke, 0.15, { Color = Color3.fromRGB(251, 113, 133) })
                -- shake
                local ox = Card.Position
                for _, dx in ipairs({ 10, -10, 7, -7, 3, -3, 0 }) do
                    Card.Position = ox + UDim2.new(0, dx, 0, 0)
                    task.wait(0.03)
                end
                Card.Position = ox
                task.delay(1.1, function()
                    if not checking then tw(InputStroke, 0.25, { Color = Color3.fromRGB(60, 56, 82) }) end
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
            setStatus("Get-key link copied to clipboard!", "good")
        elseif GetKeyLink ~= "" then
            setStatus("Get key at: " .. GetKeyLink, "info")
        else
            setStatus("No get-key link configured.", "bad")
        end
    end)

    Close.MouseButton1Click:Connect(function() finish(false) end)

    -- spring entrance
    tw(Scale, 0.45, { Scale = 1 }, Enum.EasingStyle.Back, Enum.EasingDirection.Out)

    --// yield until finished --------------------------------------------------
    while not finished do
        task.wait(0.05)
    end

    return result == true
end

return KeySystem
