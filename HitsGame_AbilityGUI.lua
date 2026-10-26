-- ABILITY GUI - one draggable panel for a game's moves (mobile-friendly)
--
-- Each button just sends an input you ALREADY have bound in the game
-- (a key press, or a left click), through the executor's VirtualInputManager.
-- It does exactly what tapping the on-screen control does - it does not hook
-- the game's private remotes or read anything it shouldn't. It's a macro
-- layout, so it needs an executor that exposes VirtualInputManager.
--
-- Set up your moves in ABILITIES below:
--   name  = the button label
--   key   = Enum.KeyCode.X  for a keyboard move, or "click" for a left click
--   hold  = true if the move should fire while held instead of a single tap
--
-- Each button also has a small "A" toggle that auto-repeats the move every
-- AUTO_INTERVAL seconds - handy for grinding a hit counter on a dummy.

local ABILITIES = {
    { name = "Punch",        key = "click",            hold = false },
    { name = "Dash",         key = Enum.KeyCode.Q,     hold = false },
    { name = "Lava Tsunami", key = Enum.KeyCode.E,     hold = false },
    { name = "Flame Spam",   key = Enum.KeyCode.R,     hold = false },
    { name = "Jump",         key = Enum.KeyCode.Space, hold = false },
}

local AUTO_INTERVAL = 0.2 -- seconds between auto-repeats

-- ===================================================================

local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")

-- VirtualInputManager is executor-only; bail cleanly if it's missing
local vim = nil
do
    local ok, service = pcall(function()
        return game:GetService("VirtualInputManager")
    end)
    if ok then vim = service end
end

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

local RED = Color3.fromRGB(255, 0, 0)
local WHITE = Color3.new(1, 1, 1)
local BLACK = Color3.new(0, 0, 0)
local GREEN = Color3.fromRGB(0, 200, 0)

-- ===================================================================
-- INPUT SENDERS
-- ===================================================================

local function pressKey(keycode, down)
    if not vim then return end
    vim:SendKeyEvent(down, keycode, false, game)
end

local function click(down)
    if not vim then return end
    local mouse = player:GetMouse()
    vim:SendMouseButtonEvent(mouse.X, mouse.Y, 0, down, game, 0)
end

-- fire one ability once (down then up)
local function fireOnce(ability)
    if ability.key == "click" then
        click(true)
        task.wait()
        click(false)
    else
        pressKey(ability.key, true)
        task.wait()
        pressKey(ability.key, false)
    end
end

-- hold an ability down / release it
local function setHeld(ability, down)
    if ability.key == "click" then
        click(down)
    else
        pressKey(ability.key, down)
    end
end

-- ===================================================================
-- GUI
-- ===================================================================

local old = playerGui:FindFirstChild("AbilityGUI")
if old then old:Destroy() end

local gui = Instance.new("ScreenGui")
gui.Name = "AbilityGUI"
gui.ResetOnSpawn = false
gui.IgnoreGuiInset = true
gui.DisplayOrder = 100
gui.Parent = playerGui

local function framed(obj)
    obj.BackgroundColor3 = BLACK
    obj.BorderColor3 = RED
    obj.BorderSizePixel = 1
    return obj
end

-- floating open button (shown when the panel is closed)
local openBtn = framed(Instance.new("TextButton"))
openBtn.Name = "OpenButton"
openBtn.Size = UDim2.fromOffset(70, 34)
openBtn.Position = UDim2.fromOffset(10, 10)
openBtn.Text = "moves"
openBtn.Font = Enum.Font.SourceSansBold
openBtn.TextSize = 18
openBtn.TextColor3 = RED
openBtn.Visible = false
openBtn.Parent = gui

local panel = framed(Instance.new("Frame"))
panel.Name = "MainPanel"
panel.Size = UDim2.fromOffset(240, 300)
panel.Position = UDim2.fromScale(0.5, 0.5)
panel.AnchorPoint = Vector2.new(0.5, 0.5)
panel.BorderSizePixel = 3
panel.Active = true
panel.Parent = gui

-- title bar (drag handle)
local titleBar = framed(Instance.new("Frame"))
titleBar.Name = "TitleBar"
titleBar.Size = UDim2.new(1, 0, 0, 36)
titleBar.Active = true
titleBar.Parent = panel

local title = Instance.new("TextLabel")
title.BackgroundTransparency = 1
title.Size = UDim2.new(1, -40, 1, 0)
title.Position = UDim2.fromOffset(8, 0)
title.Font = Enum.Font.SourceSansBold
title.TextSize = 22
title.TextXAlignment = Enum.TextXAlignment.Left
title.Text = "MOVES"
title.TextColor3 = RED
title.TextStrokeTransparency = 0.5
title.Parent = titleBar

local close = framed(Instance.new("TextButton"))
close.Name = "Close"
close.Size = UDim2.fromOffset(36, 36)
close.Position = UDim2.new(1, -36, 0, 0)
close.Text = "X"
close.Font = Enum.Font.SourceSansBold
close.TextSize = 22
close.TextColor3 = RED
close.Parent = titleBar

-- warning strip if VirtualInputManager isn't available
if not vim then
    local warn = Instance.new("TextLabel")
    warn.BackgroundTransparency = 1
    warn.Size = UDim2.new(1, -16, 0, 20)
    warn.Position = UDim2.fromOffset(8, 38)
    warn.Font = Enum.Font.SourceSans
    warn.TextSize = 13
    warn.TextWrapped = true
    warn.Text = "VirtualInputManager unavailable - run via an executor"
    warn.TextColor3 = Color3.fromRGB(255, 180, 0)
    warn.Parent = panel
end

-- scrolling list of ability rows
local scroll = Instance.new("ScrollingFrame")
scroll.Name = "Scroll"
scroll.BackgroundTransparency = 1
scroll.BorderSizePixel = 0
scroll.Position = UDim2.fromOffset(8, 62)
scroll.Size = UDim2.new(1, -16, 1, -70)
scroll.ScrollBarThickness = 6
scroll.ScrollBarImageColor3 = RED
scroll.CanvasSize = UDim2.new()
scroll.AutomaticCanvasSize = Enum.AutomaticSize.Y
scroll.Parent = panel

local list = Instance.new("UIListLayout")
list.Padding = UDim.new(0, 8)
list.SortOrder = Enum.SortOrder.LayoutOrder
list.Parent = scroll

-- one row per ability: [ big move button ][ A auto-toggle ]
local autoLoops = {} -- ability name -> stop function

local function makeRow(ability, order)
    local row = Instance.new("Frame")
    row.Name = ability.name
    row.BackgroundTransparency = 1
    row.Size = UDim2.new(1, 0, 0, 44)
    row.LayoutOrder = order
    row.Parent = scroll

    local btn = framed(Instance.new("TextButton"))
    btn.Size = UDim2.new(1, -52, 1, 0)
    btn.Position = UDim2.fromOffset(0, 0)
    btn.AutoButtonColor = true
    btn.Font = Enum.Font.SourceSans
    btn.TextSize = 18
    btn.TextWrapped = true
    btn.Text = ability.name
    btn.TextColor3 = WHITE
    btn.TextStrokeTransparency = 0.5
    btn.Parent = row

    local auto = framed(Instance.new("TextButton"))
    auto.Size = UDim2.fromOffset(44, 44)
    auto.Position = UDim2.new(1, -44, 0, 0)
    auto.Font = Enum.Font.SourceSansBold
    auto.TextSize = 18
    auto.Text = "A"
    auto.TextColor3 = RED
    auto.Parent = row

    -- main button: tap fires once, or hold if the move is a hold-move
    if ability.hold then
        btn.MouseButton1Down:Connect(function() setHeld(ability, true) end)
        btn.MouseButton1Up:Connect(function() setHeld(ability, false) end)
        btn.MouseLeave:Connect(function() setHeld(ability, false) end)
    else
        btn.MouseButton1Click:Connect(function() fireOnce(ability) end)
    end

    -- auto toggle: repeat the move every AUTO_INTERVAL until toggled off
    auto.MouseButton1Click:Connect(function()
        if autoLoops[ability.name] then
            autoLoops[ability.name]()
            autoLoops[ability.name] = nil
            auto.TextColor3 = RED
            auto.BorderColor3 = RED
        else
            local running = true
            autoLoops[ability.name] = function() running = false end
            auto.TextColor3 = GREEN
            auto.BorderColor3 = GREEN
            task.spawn(function()
                while running and gui.Parent do
                    fireOnce(ability)
                    task.wait(AUTO_INTERVAL)
                end
            end)
        end
    end)
end

for i, ability in ipairs(ABILITIES) do
    makeRow(ability, i)
end

-- ===================================================================
-- OPEN / CLOSE + DRAG
-- ===================================================================

local function stopAllAuto()
    for name, stop in pairs(autoLoops) do
        stop()
        autoLoops[name] = nil
    end
end

close.MouseButton1Click:Connect(function()
    stopAllAuto()
    panel.Visible = false
    openBtn.Visible = true
end)
openBtn.MouseButton1Click:Connect(function()
    panel.Visible = true
    openBtn.Visible = false
end)

local dragging, dragStart, startPos
titleBar.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1
        or input.UserInputType == Enum.UserInputType.Touch then
        dragging = true
        dragStart = input.Position
        startPos = panel.Position
        input.Changed:Connect(function()
            if input.UserInputState == Enum.UserInputState.End then dragging = false end
        end)
    end
end)
UserInputService.InputChanged:Connect(function(input)
    if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement
        or input.UserInputType == Enum.UserInputType.Touch) then
        local delta = input.Position - dragStart
        panel.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X,
            startPos.Y.Scale, startPos.Y.Offset + delta.Y)
    end
end)

-- stop auto-loops if the GUI is cleaned up
gui.AncestryChanged:Connect(function(_, parent)
    if not parent then stopAllAuto() end
end)
