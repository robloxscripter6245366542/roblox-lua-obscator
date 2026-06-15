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
-- mouse1click / mouse2click / touchTap fire instantly with no release delay.
local clickFn, methodName

if fn.mouse1click then
    clickFn = fn.mouse1click
    methodName = "mouse1click"
elseif fn.mouse2click then
    clickFn = fn.mouse2click
    methodName = "mouse2click"
elseif fn.touchTap then
    local pos = getSafePos()
    clickFn = function() fn.touchTap({pos}) end
    methodName = "touchTap"
elseif fn.mouse1press and fn.mouse1release then
    -- press+release with no wait (still instant, just two calls)
    clickFn = function() fn.mouse1press(); fn.mouse1release() end
    methodName = "mouse1press/release"
elseif fn.mouse2press and fn.mouse2release then
    clickFn = function() fn.mouse2press(); fn.mouse2release() end
    methodName = "mouse2press/release"
elseif fn.touchStart and fn.touchEnd then
    local pos = getSafePos()
    clickFn = function() fn.touchStart({pos}); fn.touchEnd({pos}) end
    methodName = "touchStart/End"
else
    -- VirtualInputManager fallback (no waits)
    local vim = game:GetService("VirtualInputManager")
    clickFn = function()
        vim:SendMouseButtonEvent(0, 0, 0, true,  game, 0)
        vim:SendMouseButtonEvent(0, 0, 0, false, game, 0)
    end
    methodName = "VirtualInputManager"
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
        print("[AutoClicker] " .. (on and "ON" or "OFF")
            .. " | " .. AC.ClickCount .. " clicks | " .. AC.Method)
    end
end)

-- ── Minimal draggable speed bar ───────────────────────────────────────────────
-- A small bar you drag. Drag the fill = set CPS (0 .. MAX_CPS). Click the dot
-- on the left = toggle on/off. No big panel, no notifications.
local MAX_CPS  = 50000
local Players  = game:GetService("Players")

local function getContainer()
    if type(getgenv) == "function" and type(getgenv().gethui) == "function" then
        return getgenv().gethui()
    end
    if type(gethui) == "function" then return gethui() end
    return Players.LocalPlayer:WaitForChild("PlayerGui")
end

local container = getContainer()
local oldGui = container:FindFirstChild("AutoClickerBar")
if oldGui then oldGui:Destroy() end

local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name           = "AutoClickerBar"
ScreenGui.ResetOnSpawn   = false
ScreenGui.IgnoreGuiInset = true
ScreenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
ScreenGui.Parent         = container

-- The draggable bar
local Bar = Instance.new("Frame")
Bar.Name             = "Bar"
Bar.Size             = UDim2.fromOffset(240, 34)
Bar.Position         = UDim2.fromOffset(40, 120)
Bar.BackgroundColor3 = Color3.fromRGB(20, 20, 26)
Bar.BorderSizePixel  = 0
Bar.Parent           = ScreenGui
Instance.new("UICorner", Bar).CornerRadius = UDim.new(0, 8)

-- Toggle dot (left)
local Dot = Instance.new("TextButton")
Dot.Name             = "Dot"
Dot.Text             = ""
Dot.Size             = UDim2.fromOffset(20, 20)
Dot.Position         = UDim2.fromOffset(7, 7)
Dot.BackgroundColor3 = Color3.fromRGB(220, 80, 80)   -- red = off
Dot.BorderSizePixel  = 0
Dot.Parent           = Bar
Instance.new("UICorner", Dot).CornerRadius = UDim.new(1, 0)

-- Slider track
local Track = Instance.new("Frame")
Track.Name             = "Track"
Track.Size             = UDim2.fromOffset(150, 8)
Track.Position         = UDim2.fromOffset(36, 13)
Track.BackgroundColor3 = Color3.fromRGB(45, 45, 55)
Track.BorderSizePixel  = 0
Track.Parent           = Bar
Instance.new("UICorner", Track).CornerRadius = UDim.new(1, 0)

-- Slider fill
local Fill = Instance.new("Frame")
Fill.Name             = "Fill"
Fill.Size             = UDim2.fromScale(1, 1)   -- starts full (50k)
Fill.BackgroundColor3 = Color3.fromRGB(220, 80, 255)
Fill.BorderSizePixel  = 0
Fill.Parent           = Track
Instance.new("UICorner", Fill).CornerRadius = UDim.new(1, 0)

-- Slider knob
local Knob = Instance.new("Frame")
Knob.Name             = "Knob"
Knob.Size             = UDim2.fromOffset(14, 14)
Knob.AnchorPoint      = Vector2.new(0.5, 0.5)
Knob.Position         = UDim2.fromScale(1, 0.5)
Knob.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
Knob.BorderSizePixel  = 0
Knob.ZIndex           = 3
Knob.Parent           = Track
Instance.new("UICorner", Knob).CornerRadius = UDim.new(1, 0)

-- CPS readout (right)
local CpsText = Instance.new("TextLabel")
CpsText.Name              = "CpsText"
CpsText.BackgroundTransparency = 1
CpsText.Size              = UDim2.fromOffset(46, 34)
CpsText.Position          = UDim2.fromOffset(192, 0)
CpsText.Font              = Enum.Font.GothamBold
CpsText.TextSize          = 11
CpsText.TextColor3        = Color3.fromRGB(100, 220, 255)
CpsText.Text              = "50k"
CpsText.Parent            = Bar

local function fmtCPS(n)
    if n >= 1000 then
        return string.format("%.0fk", n / 1000)
    end
    return tostring(math.floor(n))
end

local function refreshDot()
    Dot.BackgroundColor3 = AC.Enabled and Color3.fromRGB(80, 220, 100)
                                       or  Color3.fromRGB(220, 80, 80)
end

Dot.MouseButton1Click:Connect(function()
    AC:Toggle()
    refreshDot()
end)

-- ── Slider drag = set CPS ─────────────────────────────────────────────────────
local function setFromX(absX)
    local rel = (absX - Track.AbsolutePosition.X) / Track.AbsoluteSize.X
    rel = math.clamp(rel, 0, 1)
    Fill.Size      = UDim2.fromScale(rel, 1)
    Knob.Position  = UDim2.fromScale(rel, 0.5)
    AC.CPS         = math.floor(rel * MAX_CPS)
    CpsText.Text   = fmtCPS(AC.CPS)
end

local sliding = false
Track.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1
    or input.UserInputType == Enum.UserInputType.Touch then
        sliding = true
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
        sliding = false
    end
end)

-- ── Drag the whole bar (grab anywhere except the slider/dot) ──────────────────
do
    local dragging, dragStart, startPos
    Bar.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1
        or input.UserInputType == Enum.UserInputType.Touch then
            -- ignore if the press started on the track or dot (those have their own jobs)
            local mx, my = input.Position.X, input.Position.Y
            local tp, ts = Track.AbsolutePosition, Track.AbsoluteSize
            local dp, ds = Dot.AbsolutePosition,   Dot.AbsoluteSize
            local onTrack = mx >= tp.X and mx <= tp.X+ts.X and my >= tp.Y-6 and my <= tp.Y+ts.Y+6
            local onDot   = mx >= dp.X and mx <= dp.X+ds.X and my >= dp.Y   and my <= dp.Y+ds.Y
            if onTrack or onDot then return end
            dragging  = true
            dragStart = input.Position
            startPos  = Bar.Position
        end
    end)
    UIS.InputChanged:Connect(function(input)
        if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement
            or input.UserInputType == Enum.UserInputType.Touch) then
            local delta = input.Position - dragStart
            Bar.Position = UDim2.fromOffset(
                startPos.X.Offset + delta.X,
                startPos.Y.Offset + delta.Y
            )
        end
    end)
    UIS.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1
        or input.UserInputType == Enum.UserInputType.Touch then
            dragging = false
        end
    end)
end

refreshDot()

print("[AutoClicker v2] Loaded | Method: " .. AC.Method
    .. " | Drag the bar to move it, drag the slider to set speed (0-50k CPS)"
    .. " | tap the dot or press [E] to toggle")
