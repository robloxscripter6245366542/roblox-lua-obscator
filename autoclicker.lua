-- AutoClicker v2.0  (no GUI / keybind toggle)
-- Target: 50,000 CPS via per-frame bursts, time-budgeted so it NEVER crashes/freezes.
-- Works while you walk/run/jump. You can still click manually. Toggle anytime.
--
-- Controls:
--   [E]                  toggle on/off
--   getgenv().AutoClicker:Stop()      stop from console
--   getgenv().AutoClicker:Start()     start from console
--   getgenv().AutoClicker.CPS = 50000 change rate live

local AC = {
    Enabled    = false,
    CPS        = 50000,   -- target clicks per second
    Budget     = 0.004,   -- max seconds spent clicking per frame (keeps game alive -> never crash)
    SkipOverUI = true,    -- don't click when cursor is over a GUI (stops the Roblox UI click sound)
    Method     = "none",
    ClickCount = 0,
}

-- Expose a global handle so you can control it from the console anytime
if type(getgenv) == "function" then
    getgenv().AutoClicker = AC
end

-- ── UNC function resolver ─────────────────────────────────────────────────────
local function resolve(name)
    if type(getgenv) == "function" then
        local v = getgenv()[name]
        if type(v) == "function" then return v end
    end
    if type(_G[name]) == "function" then return _G[name] end
    return nil
end

local fn = {
    mouse1click   = resolve("mouse1click"),
    mouse1press   = resolve("mouse1press"),
    mouse1release = resolve("mouse1release"),
    mouse2click   = resolve("mouse2click"),
    mouse2press   = resolve("mouse2press"),
    mouse2release = resolve("mouse2release"),
    touchTap      = resolve("touchTap"),
    touchStart    = resolve("touchStart"),
    touchEnd      = resolve("touchEnd"),
}

-- Safe touch position: centre of screen, never the joystick corner
local function getSafePos()
    local cam = workspace.CurrentCamera
    local vp  = cam and cam.ViewportSize or Vector2.new(800, 600)
    return Vector2.new(vp.X * 0.5, vp.Y * 0.5)
end

-- ── Single click (NO yields — must be instant for burst loop) ─────────────────
-- For top speed we only use the fastest no-wait methods.
-- We fire EVERY available input type per click — a mouse click AND a touch tap —
-- so it works in ANY game: ones that detect block via mouse clicks, and ones that
-- use tap-to-block. Whatever the game listens for, we cover it.
local clickFn, methodName
do
    local pos = getSafePos()
    local parts = {}      -- functions to call each click
    local names = {}      -- for display

    -- Mouse left-click (most common)
    if fn.mouse1click then
        parts[#parts+1] = fn.mouse1click
        names[#names+1] = "mouse1click"
    elseif fn.mouse1press and fn.mouse1release then
        parts[#parts+1] = function() fn.mouse1press(); fn.mouse1release() end
        names[#names+1] = "mouse1press/release"
    end

    -- Touch tap (tap-to-block games / mobile)
    if fn.touchTap then
        parts[#parts+1] = function() fn.touchTap({pos}) end
        names[#names+1] = "touchTap"
    elseif fn.touchStart and fn.touchEnd then
        parts[#parts+1] = function() fn.touchStart({pos}); fn.touchEnd({pos}) end
        names[#names+1] = "touchStart/End"
    end

    -- If neither mouse nor touch UNC funcs exist, fall back to right-click then VIM
    if #parts == 0 then
        if fn.mouse2click then
            parts[#parts+1] = fn.mouse2click
            names[#names+1] = "mouse2click"
        elseif fn.mouse2press and fn.mouse2release then
            parts[#parts+1] = function() fn.mouse2press(); fn.mouse2release() end
            names[#names+1] = "mouse2press/release"
        else
            local vim = game:GetService("VirtualInputManager")
            parts[#parts+1] = function()
                vim:SendMouseButtonEvent(0, 0, 0, true,  game, 0)
                vim:SendMouseButtonEvent(0, 0, 0, false, game, 0)
            end
            names[#names+1] = "VirtualInputManager"
        end
    end

    if #parts == 1 then
        clickFn = parts[1]
    else
        clickFn = function()
            for i = 1, #parts do parts[i]() end
        end
    end
    methodName = table.concat(names, " + ")
end
AC.Method = methodName

-- ── Burst engine ──────────────────────────────────────────────────────────────
-- We fire on the EARLIEST point of every frame at the highest render priority,
-- so a click lands before AutoParry's reaction tick -> we win the race.
-- Each frame fires up to (CPS / fps) clicks, capped by a time budget so the
-- frame always finishes -> game never hangs or crashes.
local RunSvc      = game:GetService("RunService")
local UIS_svc     = game:GetService("UserInputService")
local Players_svc = game:GetService("Players")

-- Is the cursor currently over any GUI element? If so we skip clicking, which
-- stops Roblox from playing its UI click sound on every burst.
local function cursorOverGui()
    local lp = Players_svc.LocalPlayer
    local pg = lp and lp:FindFirstChild("PlayerGui")
    if not pg then return false end
    local mp = UIS_svc:GetMouseLocation()
    -- GetGuiObjectsAtPosition expects coords without the 36px top inset
    local ok, objs = pcall(function()
        return pg:GetGuiObjectsAtPosition(mp.X, mp.Y - 36)
    end)
    if ok and objs and #objs > 0 then return true end
    return false
end

local lastClock = os.clock()

local function burst()
    if not AC.Enabled then return end

    -- skip the whole frame if hovering UI -> no annoying click sound
    if AC.SkipOverUI and cursorOverGui() then return end

    local now = os.clock()
    local dt  = now - lastClock
    lastClock = now
    if dt <= 0 then dt = 1/60 end

    -- clicks needed this frame to reach the target rate
    local quota = AC.CPS * dt
    if quota < 1 then quota = 1 end

    local startT = os.clock()
    local fired  = 0
    local budget = AC.Budget

    while fired < quota do
        pcall(clickFn)             -- protected: one bad call can't crash the game
        fired = fired + 1
        if (os.clock() - startT) >= budget then  -- anti-crash time cap
            break
        end
    end

    AC.ClickCount = AC.ClickCount + fired
end

-- Prefer BindToRenderStep at the EARLIEST priority (runs before anything else
-- in the frame, including most AutoParry loops). Fall back to Heartbeat on
-- environments without a render step (e.g. server-side).
local bound = false
local ok = pcall(function()
    RunSvc:BindToRenderStep("AutoClickerBurst", Enum.RenderPriority.First.Value - 1, burst)
    bound = true
end)
if not (ok and bound) then
    RunSvc.Heartbeat:Connect(burst)
end

-- ── Toggle / control API ──────────────────────────────────────────────────────
function AC:Start()
    self.Enabled = true
end

function AC:Stop()
    self.Enabled = false
end

function AC:Toggle()
    self.Enabled = not self.Enabled
    return self.Enabled
end

-- ── Keybind: E (toggle). Responsive even mid-click because the burst loop yields
-- every frame, so InputBegan always gets to run. ──────────────────────────────
local UIS = game:GetService("UserInputService")
UIS.InputBegan:Connect(function(input, gp)
    if gp then return end
    if input.KeyCode == Enum.KeyCode.E then
        local on = AC:Toggle()
        if AC.OnVisual then AC.OnVisual() end   -- keep the UI in sync
        print("[AutoClicker] " .. (on and "ON" or "OFF")
            .. " | " .. AC.ClickCount .. " clicks | " .. AC.Method)
    end
end)

-- ══════════════════════════════════════════════════════════════════════════════
--  PREMIUM GLASSMORPHISM UI  (transparency • gradients • glow • smooth tweens)
-- ══════════════════════════════════════════════════════════════════════════════
local TweenSvc = game:GetService("TweenService")
local Players  = game:GetService("Players")
local MAX_CPS  = 50000

-- Theme ────────────────────────────────────────────────────────────────────────
local THEME = {
    AccentA = Color3.fromRGB(170, 80, 255),   -- purple
    AccentB = Color3.fromRGB(90, 200, 255),   -- cyan
    OnA     = Color3.fromRGB(70, 230, 160),    -- green (on)
    OnB     = Color3.fromRGB(120, 255, 210),
    OffA    = Color3.fromRGB(255, 90, 110),    -- red (off)
    OffB    = Color3.fromRGB(255, 150, 90),
    Glass   = Color3.fromRGB(22, 22, 32),
    Text    = Color3.fromRGB(235, 235, 245),
    Dim     = Color3.fromRGB(150, 150, 170),
}

local function tween(obj, t, props, style, dir)
    return TweenSvc:Create(obj, TweenInfo.new(
        t or 0.25,
        style or Enum.EasingStyle.Quint,
        dir or Enum.EasingDirection.Out
    ), props)
end

local function corner(parent, r)
    local c = Instance.new("UICorner")
    c.CornerRadius = UDim.new(0, r)
    c.Parent = parent
    return c
end

local function gradient(parent, a, b, rot)
    local g = Instance.new("UIGradient")
    g.Color = ColorSequence.new(a, b)
    g.Rotation = rot or 0
    g.Parent = parent
    return g
end

local function stroke(parent, color, thick, trans)
    local s = Instance.new("UIStroke")
    s.Color = color
    s.Thickness = thick or 1
    s.Transparency = trans or 0
    s.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
    s.Parent = parent
    return s
end

-- Container ─────────────────────────────────────────────────────────────────────
local function getContainer()
    if type(getgenv) == "function" and type(getgenv().gethui) == "function" then
        return getgenv().gethui()
    end
    if type(gethui) == "function" then return gethui() end
    return Players.LocalPlayer:WaitForChild("PlayerGui")
end

local container = getContainer()
local oldGui = container:FindFirstChild("AutoClickerUI")
if oldGui then oldGui:Destroy() end

local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name           = "AutoClickerUI"
ScreenGui.ResetOnSpawn   = false
ScreenGui.IgnoreGuiInset = true
ScreenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
ScreenGui.DisplayOrder    = 9999
ScreenGui.Parent         = container

-- Outer glow ────────────────────────────────────────────────────────────────────
local Glow = Instance.new("ImageLabel")
Glow.Name              = "Glow"
Glow.BackgroundTransparency = 1
Glow.Image             = "rbxassetid://6014261993"   -- soft radial
Glow.ImageColor3       = THEME.AccentA
Glow.ImageTransparency = 0.35
Glow.AnchorPoint       = Vector2.new(0.5, 0.5)
Glow.Position          = UDim2.fromScale(0.5, 0.5)
Glow.ScaleType         = Enum.ScaleType.Slice
Glow.SliceCenter       = Rect.new(49, 49, 450, 450)
Glow.Size              = UDim2.new(1, 60, 1, 60)
Glow.ZIndex            = 0

-- Main glass card ────────────────────────────────────────────────────────────────
local Card = Instance.new("Frame")
Card.Name              = "Card"
Card.Size              = UDim2.fromOffset(280, 92)
Card.Position          = UDim2.fromOffset(60, 140)
Card.BackgroundColor3  = THEME.Glass
Card.BackgroundTransparency = 0.25   -- transparency / glass look
Card.BorderSizePixel   = 0
Card.Parent            = ScreenGui
corner(Card, 16)
Glow.Parent = Card

-- subtle vertical gradient on the glass
gradient(Card, Color3.fromRGB(34, 34, 50), Color3.fromRGB(18, 18, 28), 90)

-- gradient border
local CardStroke = stroke(Card, THEME.AccentA, 1.4, 0.1)
gradient(CardStroke, THEME.AccentA, THEME.AccentB, 25)

-- top accent line
local TopLine = Instance.new("Frame")
TopLine.Name             = "TopLine"
TopLine.Size             = UDim2.new(1, -28, 0, 2)
TopLine.Position         = UDim2.new(0, 14, 0, 10)
TopLine.BackgroundColor3 = Color3.new(1, 1, 1)
TopLine.BorderSizePixel  = 0
TopLine.Parent           = Card
corner(TopLine, 2)
gradient(TopLine, THEME.AccentA, THEME.AccentB, 0)

-- Title ──────────────────────────────────────────────────────────────────────────
local Title = Instance.new("TextLabel")
Title.Name              = "Title"
Title.BackgroundTransparency = 1
Title.Position          = UDim2.fromOffset(18, 16)
Title.Size              = UDim2.fromOffset(150, 18)
Title.Font              = Enum.Font.GothamBold
Title.TextSize          = 14
Title.Text              = "AUTOCLICKER"
Title.TextColor3        = THEME.Text
Title.TextXAlignment    = Enum.TextXAlignment.Left
Title.Parent            = Card
gradient(Title, THEME.AccentB, THEME.AccentA, 0)

-- CPS readout (top-right) ─────────────────────────────────────────────────────────
local CpsText = Instance.new("TextLabel")
CpsText.Name              = "CpsText"
CpsText.BackgroundTransparency = 1
CpsText.AnchorPoint       = Vector2.new(1, 0)
CpsText.Position          = UDim2.new(1, -64, 0, 14)
CpsText.Size              = UDim2.fromOffset(48, 22)
CpsText.Font              = Enum.Font.GothamBlack
CpsText.TextSize          = 16
CpsText.TextColor3        = THEME.AccentB
CpsText.TextXAlignment    = Enum.TextXAlignment.Right
CpsText.Text              = "50k"
CpsText.Parent            = Card

local CpsUnit = Instance.new("TextLabel")
CpsUnit.BackgroundTransparency = 1
CpsUnit.AnchorPoint       = Vector2.new(1, 0)
CpsUnit.Position          = UDim2.new(1, -64, 0, 32)
CpsUnit.Size              = UDim2.fromOffset(48, 10)
CpsUnit.Font              = Enum.Font.Gotham
CpsUnit.TextSize          = 8
CpsUnit.TextColor3        = THEME.Dim
CpsUnit.TextXAlignment    = Enum.TextXAlignment.Right
CpsUnit.Text              = "CPS"
CpsUnit.Parent            = Card

-- Toggle pill (animated) ──────────────────────────────────────────────────────────
local Toggle = Instance.new("TextButton")
Toggle.Name              = "Toggle"
Toggle.AutoButtonColor   = false
Toggle.Text              = ""
Toggle.Size              = UDim2.fromOffset(46, 24)
Toggle.Position          = UDim2.new(1, -60, 0, 14)  -- placed top-right, replacing simple readout pos shift
Toggle.Position          = UDim2.fromOffset(18, 56)
Toggle.BackgroundColor3  = Color3.fromRGB(40, 40, 55)
Toggle.BackgroundTransparency = 0.1
Toggle.BorderSizePixel   = 0
Toggle.Parent            = Card
corner(Toggle, 12)
local ToggleStroke = stroke(Toggle, THEME.OffA, 1.2, 0.2)

local Pill = Instance.new("Frame")
Pill.Name              = "Pill"
Pill.Size              = UDim2.fromOffset(18, 18)
Pill.Position          = UDim2.fromOffset(3, 3)
Pill.BackgroundColor3  = Color3.new(1, 1, 1)
Pill.BorderSizePixel   = 0
Pill.Parent            = Toggle
corner(Pill, 9)
gradient(Pill, THEME.OffA, THEME.OffB, 90)

local ToggleLabel = Instance.new("TextLabel")
ToggleLabel.BackgroundTransparency = 1
ToggleLabel.Position      = UDim2.fromOffset(72, 56)
ToggleLabel.Size          = UDim2.fromOffset(70, 24)
ToggleLabel.Font          = Enum.Font.GothamBold
ToggleLabel.TextSize      = 12
ToggleLabel.TextColor3    = THEME.OffA
ToggleLabel.Text          = "OFF"
ToggleLabel.TextXAlignment = Enum.TextXAlignment.Left
ToggleLabel.Parent        = Card

-- Slider ───────────────────────────────────────────────────────────────────────
local Track = Instance.new("Frame")
Track.Name             = "Track"
Track.Size             = UDim2.fromOffset(110, 6)
Track.AnchorPoint      = Vector2.new(1, 0.5)
Track.Position         = UDim2.new(1, -18, 0, 68)
Track.BackgroundColor3 = Color3.fromRGB(50, 50, 68)
Track.BackgroundTransparency = 0.2
Track.BorderSizePixel  = 0
Track.Parent           = Card
corner(Track, 3)

local Fill = Instance.new("Frame")
Fill.Name             = "Fill"
Fill.Size             = UDim2.fromScale(1, 1)
Fill.BackgroundColor3 = Color3.new(1, 1, 1)
Fill.BorderSizePixel  = 0
Fill.Parent           = Track
corner(Fill, 3)
gradient(Fill, THEME.AccentA, THEME.AccentB, 0)

local Knob = Instance.new("Frame")
Knob.Name             = "Knob"
Knob.Size             = UDim2.fromOffset(16, 16)
Knob.AnchorPoint      = Vector2.new(0.5, 0.5)
Knob.Position         = UDim2.fromScale(1, 0.5)
Knob.BackgroundColor3 = Color3.new(1, 1, 1)
Knob.BorderSizePixel  = 0
Knob.ZIndex           = 4
Knob.Parent           = Track
corner(Knob, 8)
stroke(Knob, THEME.AccentB, 1.5, 0)
local KnobGlow = Instance.new("ImageLabel")
KnobGlow.BackgroundTransparency = 1
KnobGlow.Image           = "rbxassetid://6014261993"
KnobGlow.ImageColor3     = THEME.AccentB
KnobGlow.ImageTransparency = 0.3
KnobGlow.AnchorPoint     = Vector2.new(0.5, 0.5)
KnobGlow.Position        = UDim2.fromScale(0.5, 0.5)
KnobGlow.Size            = UDim2.fromScale(2.4, 2.4)
KnobGlow.ZIndex          = 3
KnobGlow.Parent          = Knob

local SpeedLabel = Instance.new("TextLabel")
SpeedLabel.BackgroundTransparency = 1
SpeedLabel.AnchorPoint    = Vector2.new(0, 0.5)
SpeedLabel.Position       = UDim2.new(0, 18, 0, 68)
SpeedLabel.Size           = UDim2.fromOffset(60, 16)
SpeedLabel.Font           = Enum.Font.Gotham
SpeedLabel.TextSize       = 11
SpeedLabel.TextColor3     = THEME.Dim
SpeedLabel.Text           = "Speed"
SpeedLabel.TextXAlignment = Enum.TextXAlignment.Left
SpeedLabel.Parent         = Card

-- Helpers ──────────────────────────────────────────────────────────────────────
local function fmtCPS(n)
    if n >= 1000 then return string.format("%.0fk", n / 1000) end
    return tostring(math.floor(n))
end

-- Animated toggle visuals
local function applyToggleVisual()
    if AC.Enabled then
        tween(Pill, 0.3, {Position = UDim2.fromOffset(25, 3)},
              Enum.EasingStyle.Back):Play()
        tween(Toggle, 0.3, {BackgroundColor3 = Color3.fromRGB(30, 55, 45)}):Play()
        ToggleStroke.Color = THEME.OnA
        Pill.UIGradient.Color = ColorSequence.new(THEME.OnA, THEME.OnB)
        ToggleLabel.Text = "ON"
        tween(ToggleLabel, 0.2, {TextColor3 = THEME.OnA}):Play()
        tween(Glow, 0.3, {ImageColor3 = THEME.OnA, ImageTransparency = 0.25}):Play()
    else
        tween(Pill, 0.3, {Position = UDim2.fromOffset(3, 3)},
              Enum.EasingStyle.Back):Play()
        tween(Toggle, 0.3, {BackgroundColor3 = Color3.fromRGB(40, 40, 55)}):Play()
        ToggleStroke.Color = THEME.OffA
        Pill.UIGradient.Color = ColorSequence.new(THEME.OffA, THEME.OffB)
        ToggleLabel.Text = "OFF"
        tween(ToggleLabel, 0.2, {TextColor3 = THEME.OffA}):Play()
        tween(Glow, 0.3, {ImageColor3 = THEME.AccentA, ImageTransparency = 0.35}):Play()
    end
end

AC.OnVisual = applyToggleVisual   -- let the [E] keybind refresh the UI too

Toggle.MouseButton1Click:Connect(function()
    AC:Toggle()
    applyToggleVisual()
end)
-- hover feedback
Toggle.MouseEnter:Connect(function()
    tween(Toggle, 0.15, {BackgroundTransparency = 0}):Play()
end)
Toggle.MouseLeave:Connect(function()
    tween(Toggle, 0.15, {BackgroundTransparency = 0.1}):Play()
end)

-- Slider drag = set CPS
local function setFromX(absX)
    local rel = (absX - Track.AbsolutePosition.X) / Track.AbsoluteSize.X
    rel = math.clamp(rel, 0, 1)
    tween(Fill, 0.08, {Size = UDim2.fromScale(rel, 1)}):Play()
    tween(Knob, 0.08, {Position = UDim2.fromScale(rel, 0.5)}):Play()
    AC.CPS = math.floor(rel * MAX_CPS)
    CpsText.Text = fmtCPS(AC.CPS)
end

local sliding = false
Track.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1
    or input.UserInputType == Enum.UserInputType.Touch then
        sliding = true
        tween(Knob, 0.1, {Size = UDim2.fromOffset(20, 20)}):Play()
        setFromX(input.Position.X)
    end
end)
UIS.InputChanged:Connect(function(input)
    if sliding and (input.UserInputType == Enum.UserInputType.MouseMovement
        or input.UserInputType == Enum.UserInputType.Touch) then
        setFromX(input.Position.X)
    end
end)
UIS.InputEnded:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1
    or input.UserInputType == Enum.UserInputType.Touch then
        if sliding then tween(Knob, 0.15, {Size = UDim2.fromOffset(16, 16)}):Play() end
        sliding = false
    end
end)

-- Drag the whole card (grab the title / empty areas, not the controls) ──────────
do
    local dragging, dragStart, startPos
    Card.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1
        or input.UserInputType == Enum.UserInputType.Touch then
            local mx, my = input.Position.X, input.Position.Y
            local function over(o, padX, padY)
                padX, padY = padX or 0, padY or 0
                local p, s = o.AbsolutePosition, o.AbsoluteSize
                return mx >= p.X-padX and mx <= p.X+s.X+padX
                   and my >= p.Y-padY and my <= p.Y+s.Y+padY
            end
            if over(Track, 8, 10) or over(Toggle, 4, 4) then return end
            dragging  = true
            dragStart = input.Position
            startPos  = Card.Position
            tween(Card, 0.1, {BackgroundTransparency = 0.15}):Play()
        end
    end)
    UIS.InputChanged:Connect(function(input)
        if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement
            or input.UserInputType == Enum.UserInputType.Touch) then
            local delta = input.Position - dragStart
            Card.Position = UDim2.fromOffset(
                startPos.X.Offset + delta.X,
                startPos.Y.Offset + delta.Y
            )
        end
    end)
    UIS.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1
        or input.UserInputType == Enum.UserInputType.Touch then
            if dragging then tween(Card, 0.2, {BackgroundTransparency = 0.25}):Play() end
            dragging = false
        end
    end)
end

-- Pulsing glow while active (subtle breathing animation) ─────────────────────────
task.spawn(function()
    while ScreenGui.Parent do
        if AC.Enabled then
            tween(Glow, 1.1, {ImageTransparency = 0.15}):Play()
            task.wait(1.1)
            tween(Glow, 1.1, {ImageTransparency = 0.32}):Play()
            task.wait(1.1)
        else
            task.wait(0.3)
        end
    end
end)

-- Entrance animation ─────────────────────────────────────────────────────────────
Card.Size = UDim2.fromOffset(280, 0)
Card.BackgroundTransparency = 1
tween(Card, 0.45, {Size = UDim2.fromOffset(280, 92), BackgroundTransparency = 0.25},
      Enum.EasingStyle.Back):Play()

applyToggleVisual()

print("[AutoClicker v2] Loaded | Method: " .. AC.Method
    .. " | Glass UI: drag card to move, drag slider for 0-50k CPS, click the pill or press [E]")
