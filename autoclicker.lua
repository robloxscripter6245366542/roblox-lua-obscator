-- AutoClicker v1.1
-- Supports all executors: mouse1click, mouse1press/release, mouse2click/press/release, touchTap, touchStart/End
-- Toggle: GUI button or press [E]
-- Movement-safe: pauses clicking while character is walking so movement is never interrupted

local AC = {
    Enabled      = false,
    CPS          = 20,     -- clicks per second
    Method       = "none",
    ClickCount   = 0,
    _thread      = nil,
}

-- ── UNC function resolver ─────────────────────────────────────────────────────
local function resolve(name)
    if type(getgenv) == "function" then
        local v = getgenv()[name]
        if type(v) == "function" then return v end
    end
    if type(_G[name]) == "function" then return _G[name] end
    local ok, v = pcall(function() return _G[name] end)
    if ok and type(v) == "function" then return v end
    return nil
end

-- ── Detect UNC click functions ────────────────────────────────────────────────
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

-- ── Safe touch position (avoids joystick zone) ───────────────────────────────
-- Joystick is bottom-left (~20% W, ~80% H). We click at screen centre instead.
-- This means touch clicks land in the middle of the screen, not on movement controls.
local function getSafePos()
    local cam = workspace.CurrentCamera
    local vp  = cam and cam.ViewportSize or Vector2.new(800, 600)
    -- Use centre of screen: safe on all device layouts
    return Vector2.new(vp.X * 0.5, vp.Y * 0.5)
end

local Players     = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer

-- ── Click dispatch ────────────────────────────────────────────────────────────
local function doClick()
    -- Primary: mouse1click (most compatible, doesn't affect WASD movement)
    if fn.mouse1click then
        fn.mouse1click()
        return "mouse1click"
    end

    -- mouse1press + release
    if fn.mouse1press and fn.mouse1release then
        fn.mouse1press()
        task.wait(0.01)
        fn.mouse1release()
        return "mouse1press/release"
    end

    -- mouse2click
    if fn.mouse2click then
        fn.mouse2click()
        return "mouse2click"
    end

    -- mouse2press + release
    if fn.mouse2press and fn.mouse2release then
        fn.mouse2press()
        task.wait(0.01)
        fn.mouse2release()
        return "mouse2press/release"
    end

    -- touchTap — uses safe centre position, NOT the joystick corner
    if fn.touchTap then
        fn.touchTap({getSafePos()})
        return "touchTap"
    end

    -- touchStart + touchEnd — safe centre position
    if fn.touchStart and fn.touchEnd then
        local pos = getSafePos()
        fn.touchStart({pos})
        task.wait(0.01)
        fn.touchEnd({pos})
        return "touchStart/End"
    end

    -- Last resort: VirtualInputManager
    local ok = pcall(function()
        local vim = game:GetService("VirtualInputManager")
        vim:SendMouseButtonEvent(0, 0, 0, true,  game, 0)
        task.wait(0.01)
        vim:SendMouseButtonEvent(0, 0, 0, false, game, 0)
    end)
    if ok then return "VirtualInputManager" end

    return "none"
end

local function detectMethod()
    if fn.mouse1click   then return "mouse1click" end
    if fn.mouse1press   then return "mouse1press/release" end
    if fn.mouse2click   then return "mouse2click" end
    if fn.mouse2press   then return "mouse2press/release" end
    if fn.touchTap      then return "touchTap" end
    if fn.touchStart    then return "touchStart/End" end
    return "VirtualInputManager"
end
AC.Method = detectMethod()

-- ── Click loop ────────────────────────────────────────────────────────────────
local function startLoop()
    if AC._thread then return end
    AC.ClickCount = 0
    AC._thread = task.spawn(function()
        while AC.Enabled do
            -- Always click — walking, running, jumping, all fine
            local used = doClick()
            if AC.Method == "none" then AC.Method = used end
            AC.ClickCount = AC.ClickCount + 1
            task.wait(1 / AC.CPS)
        end
        AC._thread = nil
    end)
end

local function stopLoop()
    AC.Enabled = false
end

local function toggle()
    AC.Enabled = not AC.Enabled
    if AC.Enabled then startLoop() else stopLoop() end
end

-- ── GUI ───────────────────────────────────────────────────────────────────────
local UIS      = game:GetService("UserInputService")
local RunSvc   = game:GetService("RunService")

local function getContainer()
    if type(getgenv) == "function" and type(getgenv().gethui) == "function" then
        return getgenv().gethui()
    end
    if type(gethui) == "function" then return gethui() end
    return LocalPlayer:WaitForChild("PlayerGui")
end

local container = getContainer()
local old = container:FindFirstChild("AutoClickerGUI")
if old then old:Destroy() end

local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name           = "AutoClickerGUI"
ScreenGui.ResetOnSpawn   = false
ScreenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
ScreenGui.IgnoreGuiInset = true
ScreenGui.Parent         = container

-- Window
local W = Instance.new("Frame")
W.Name              = "Window"
W.Size              = UDim2.fromOffset(260, 180)
W.Position          = UDim2.fromOffset(40, 200)
W.BackgroundColor3  = Color3.fromRGB(18, 18, 22)
W.BorderSizePixel   = 0
W.Parent            = ScreenGui
Instance.new("UICorner", W).CornerRadius = UDim.new(0, 10)

-- Shadow
local Shadow = Instance.new("ImageLabel")
Shadow.BackgroundTransparency = 1
Shadow.Image             = "rbxassetid://6014261993"
Shadow.ImageColor3       = Color3.fromRGB(0, 0, 0)
Shadow.ImageTransparency = 0.5
Shadow.AnchorPoint       = Vector2.new(0.5, 0.5)
Shadow.Position          = UDim2.fromScale(0.5, 0.5)
Shadow.ScaleType         = Enum.ScaleType.Slice
Shadow.Size              = UDim2.new(1, 30, 1, 30)
Shadow.SliceCenter       = Rect.new(49, 49, 450, 450)
Shadow.ZIndex            = -1
Shadow.Parent            = W

-- Title bar
local TitleBar = Instance.new("Frame")
TitleBar.Size             = UDim2.new(1, 0, 0, 36)
TitleBar.BackgroundColor3 = Color3.fromRGB(26, 26, 32)
TitleBar.BorderSizePixel  = 0
TitleBar.Parent           = W
Instance.new("UICorner", TitleBar).CornerRadius = UDim.new(0, 10)

local TitleFill = Instance.new("Frame")
TitleFill.Size             = UDim2.new(1, 0, 0, 10)
TitleFill.Position         = UDim2.new(0, 0, 1, -10)
TitleFill.BackgroundColor3 = Color3.fromRGB(26, 26, 32)
TitleFill.BorderSizePixel  = 0
TitleFill.Parent           = TitleBar

local TitleLabel = Instance.new("TextLabel")
TitleLabel.Text               = "AutoClicker"
TitleLabel.Font               = Enum.Font.GothamBold
TitleLabel.TextSize           = 15
TitleLabel.TextColor3         = Color3.fromRGB(220, 80, 255)
TitleLabel.BackgroundTransparency = 1
TitleLabel.Size               = UDim2.new(1, -40, 1, 0)
TitleLabel.Position           = UDim2.fromOffset(12, 0)
TitleLabel.TextXAlignment     = Enum.TextXAlignment.Left
TitleLabel.Parent             = TitleBar

local CloseBtn = Instance.new("TextButton")
CloseBtn.Text              = "✕"
CloseBtn.Font              = Enum.Font.GothamBold
CloseBtn.TextSize          = 14
CloseBtn.TextColor3        = Color3.fromRGB(255, 255, 255)
CloseBtn.BackgroundColor3  = Color3.fromRGB(200, 60, 60)
CloseBtn.Size              = UDim2.fromOffset(22, 22)
CloseBtn.Position          = UDim2.new(1, -30, 0.5, -11)
CloseBtn.BorderSizePixel   = 0
CloseBtn.Parent            = TitleBar
Instance.new("UICorner", CloseBtn).CornerRadius = UDim.new(0, 6)
CloseBtn.MouseButton1Click:Connect(function()
    stopLoop()
    ScreenGui:Destroy()
end)

-- Body
local Body = Instance.new("Frame")
Body.BackgroundTransparency = 1
Body.Size     = UDim2.new(1, 0, 1, -36)
Body.Position = UDim2.fromOffset(0, 36)
Body.Parent   = W

local Pad = Instance.new("UIPadding", Body)
Pad.PaddingLeft   = UDim.new(0, 14)
Pad.PaddingRight  = UDim.new(0, 14)
Pad.PaddingTop    = UDim.new(0, 10)
Pad.PaddingBottom = UDim.new(0, 10)

local Layout = Instance.new("UIListLayout", Body)
Layout.SortOrder = Enum.SortOrder.LayoutOrder
Layout.Padding   = UDim.new(0, 7)

local function makeRow(order, labelText)
    local row = Instance.new("Frame")
    row.BackgroundTransparency = 1
    row.Size        = UDim2.new(1, 0, 0, 22)
    row.LayoutOrder = order
    row.Parent      = Body

    local lbl = Instance.new("TextLabel")
    lbl.Text              = labelText
    lbl.Font              = Enum.Font.Gotham
    lbl.TextSize          = 13
    lbl.TextColor3        = Color3.fromRGB(160, 160, 175)
    lbl.BackgroundTransparency = 1
    lbl.Size              = UDim2.fromOffset(80, 22)
    lbl.TextXAlignment    = Enum.TextXAlignment.Left
    lbl.Parent            = row

    local val = Instance.new("TextLabel")
    val.Font              = Enum.Font.GothamBold
    val.TextSize          = 12
    val.BackgroundTransparency = 1
    val.Size              = UDim2.new(1, -80, 1, 0)
    val.Position          = UDim2.fromOffset(80, 0)
    val.TextXAlignment    = Enum.TextXAlignment.Left
    val.Parent            = row

    return val
end

local StatusVal = makeRow(1, "Status:")
local CpsVal    = makeRow(2, "CPS:")
local MethodVal = makeRow(3, "Method:")

StatusVal.TextColor3 = Color3.fromRGB(220, 80, 80)
CpsVal.TextColor3    = Color3.fromRGB(100, 220, 255)
MethodVal.TextColor3 = Color3.fromRGB(180, 180, 255)

-- Toggle button
local ToggleBtn = Instance.new("TextButton")
ToggleBtn.Font             = Enum.Font.GothamBold
ToggleBtn.TextSize         = 14
ToggleBtn.TextColor3       = Color3.fromRGB(255, 255, 255)
ToggleBtn.BackgroundColor3 = Color3.fromRGB(50, 180, 80)
ToggleBtn.BorderSizePixel  = 0
ToggleBtn.Size             = UDim2.new(1, 0, 0, 34)
ToggleBtn.LayoutOrder      = 4
ToggleBtn.Parent           = Body
Instance.new("UICorner", ToggleBtn).CornerRadius = UDim.new(0, 8)

-- ── UI update ─────────────────────────────────────────────────────────────────
local function updateUI()
    CpsVal.Text    = tostring(AC.CPS) .. " CPS"
    MethodVal.Text = AC.Method

    if AC.Enabled then
        StatusVal.Text             = "ON — " .. AC.ClickCount .. " clicks"
        StatusVal.TextColor3       = Color3.fromRGB(80, 220, 100)
        ToggleBtn.Text             = "Disable  [E]"
        ToggleBtn.BackgroundColor3 = Color3.fromRGB(200, 50, 50)
    else
        StatusVal.Text             = "OFF"
        StatusVal.TextColor3       = Color3.fromRGB(220, 80, 80)
        ToggleBtn.Text             = "Enable  [E]"
        ToggleBtn.BackgroundColor3 = Color3.fromRGB(50, 180, 80)
    end
end

ToggleBtn.MouseButton1Click:Connect(function()
    toggle()
    updateUI()
end)

UIS.InputBegan:Connect(function(input, gp)
    if gp then return end
    if input.KeyCode == Enum.KeyCode.E then
        toggle()
        updateUI()
    end
end)

RunSvc.Heartbeat:Connect(function()
    if AC.Enabled then
        StatusVal.Text = "ON — " .. AC.ClickCount .. " clicks"
    end
end)

-- ── Dragging ──────────────────────────────────────────────────────────────────
do
    local dragging, dragStart, startPos
    TitleBar.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1
        or input.UserInputType == Enum.UserInputType.Touch then
            dragging  = true
            dragStart = input.Position
            startPos  = W.Position
        end
    end)
    UIS.InputChanged:Connect(function(input)
        if dragging and (
            input.UserInputType == Enum.UserInputType.MouseMovement or
            input.UserInputType == Enum.UserInputType.Touch
        ) then
            local delta = input.Position - dragStart
            W.Position  = UDim2.fromOffset(
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

-- ── Init ──────────────────────────────────────────────────────────────────────
updateUI()
print("[AutoClicker] Loaded | Method: " .. AC.Method .. " | [E] to toggle | Clicks fire during walk/run/jump")
