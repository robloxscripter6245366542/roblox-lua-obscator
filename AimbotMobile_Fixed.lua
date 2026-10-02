-- Aimbot Mobile (fixed)
-- Cleaned up from a deobfuscated build. Fixes:
--   * FOV circle now uses a GUI ring (Frame + UIStroke) instead of Drawing.new,
--     so it shows on mobile executors that lack / break the Drawing API.
--   * Ring is centred in a ScreenGui with IgnoreGuiInset, so it lines up with
--     the camera centre the aimbot actually measures from.
--   * Toggle buttons (Team/Kill/Wall Check) no longer error when clicked
--     (old code concatenated a string with a boolean).
--   * Target-part dropdown was parented to script.Parent (nil in executors) and
--     was never used by the aimbot; it now lives in the panel and is used.
--   * Part names fixed for R6 and R15 rigs ("Left Leg"/"LeftLowerLeg", etc.).
--   * FOV slider: knob starts at the real value, drag stops when the finger /
--     mouse is released anywhere, and only pointer movement moves it.
--   * Wall check: ray reaches the full distance and uses the non-deprecated
--     RaycastFilterType.Exclude.
--   * Team check no longer treats everyone as a teammate in games with no teams.
--   * Camera is re-read every frame (CurrentCamera can be replaced).
--   * Panel drag works with touch (Draggable is deprecated / mouse only).
--   * Closing the GUI disconnects every connection; re-running the script
--     replaces the old GUI instead of stacking a second one.

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")

local LocalPlayer = Players.LocalPlayer
local RENDER_NAME = "AimbotRender"

local connections = {}
local function track(conn)
    table.insert(connections, conn)
    return conn
end

-- GUI parent: prefer the executor's hidden UI container, then CoreGui, then PlayerGui.
local function getGuiParent()
    if typeof(gethui) == "function" then
        local ok, hui = pcall(gethui)
        if ok and hui then
            return hui
        end
    end
    local ok, coreGui = pcall(function()
        return game:GetService("CoreGui")
    end)
    if ok and coreGui then
        local canWrite = pcall(function()
            local probe = Instance.new("Folder")
            probe.Parent = coreGui
            probe:Destroy()
        end)
        if canWrite then
            return coreGui
        end
    end
    return LocalPlayer:WaitForChild("PlayerGui")
end

local guiParent = getGuiParent()
for _, oldName in ipairs({ "AimbotGUI", "AimbotFOV" }) do
    local old = guiParent:FindFirstChild(oldName)
    if old then
        old:Destroy()
    end
end
pcall(function()
    RunService:UnbindFromRenderStep(RENDER_NAME)
end)

-- Settings
local aimbotEnabled = false
local fovRadius = 80
local FOV_MAX = 300
local FOV_MIN = 10
local teamCheck = false
local killCheck = false
local wallCheck = false
local targetPartName = "Head"

local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "AimbotGUI"
ScreenGui.ResetOnSpawn = false
ScreenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
ScreenGui.DisplayOrder = 999
ScreenGui.Parent = guiParent

--------------------------------------------------------------------------
-- FOV circle (GUI-based so it works on mobile)
--------------------------------------------------------------------------
-- Own ScreenGui with IgnoreGuiInset so (0.5, 0.5) is the true viewport
-- centre, matching camera.ViewportSize / 2 used by the targeting code.
local FovGui = Instance.new("ScreenGui")
FovGui.Name = "AimbotFOV"
FovGui.ResetOnSpawn = false
FovGui.IgnoreGuiInset = true
FovGui.DisplayOrder = 998
FovGui.Parent = guiParent
ScreenGui.Destroying:Connect(function()
    FovGui:Destroy()
end)

local FovCircle = Instance.new("Frame")
FovCircle.Name = "FOVCircle"
FovCircle.AnchorPoint = Vector2.new(0.5, 0.5)
FovCircle.Position = UDim2.fromScale(0.5, 0.5)
FovCircle.Size = UDim2.fromOffset(fovRadius * 2, fovRadius * 2)
FovCircle.BackgroundTransparency = 1
FovCircle.Active = false
FovCircle.Visible = false
FovCircle.Parent = FovGui
Instance.new("UICorner", FovCircle).CornerRadius = UDim.new(1, 0)

local FovStroke = Instance.new("UIStroke")
FovStroke.Thickness = 1.5
FovStroke.Color = Color3.fromRGB(255, 255, 255)
FovStroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
FovStroke.Parent = FovCircle

local function updateFovCircle()
    FovCircle.Size = UDim2.fromOffset(fovRadius * 2, fovRadius * 2)
    FovCircle.Visible = aimbotEnabled
end

--------------------------------------------------------------------------
-- Toggle button + panel
--------------------------------------------------------------------------
local ToggleButton = Instance.new("ImageButton")
ToggleButton.Size = UDim2.new(0, 50, 0, 50)
ToggleButton.Position = UDim2.new(0, 10, 0, 10)
ToggleButton.BackgroundColor3 = Color3.fromRGB(20, 20, 20)
ToggleButton.Image = "rbxassetid://132533655213092"
ToggleButton.ImageColor3 = Color3.fromRGB(255, 255, 255)
ToggleButton.ScaleType = Enum.ScaleType.Fit
ToggleButton.ZIndex = 10
ToggleButton.Parent = ScreenGui
Instance.new("UICorner", ToggleButton).CornerRadius = UDim.new(1, 0)

local hoverInfo = TweenInfo.new(0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
ToggleButton.MouseEnter:Connect(function()
    TweenService:Create(ToggleButton, hoverInfo, { Size = UDim2.new(0, 55, 0, 55) }):Play()
end)
ToggleButton.MouseLeave:Connect(function()
    TweenService:Create(ToggleButton, hoverInfo, { Size = UDim2.new(0, 50, 0, 50) }):Play()
end)

local Panel = Instance.new("Frame")
Panel.Size = UDim2.new(0, 180, 0, 300)
Panel.Position = UDim2.new(0, 70, 0, 10)
Panel.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
Panel.Active = true
Panel.Parent = ScreenGui
Instance.new("UICorner", Panel).CornerRadius = UDim.new(0, 10)

local panelVisible = true
ToggleButton.MouseButton1Click:Connect(function()
    panelVisible = not panelVisible
    Panel.Visible = panelVisible
end)

local Title = Instance.new("TextLabel")
Title.Size = UDim2.new(1, 0, 0, 30)
Title.Text = "Aimbot Mobile"
Title.BackgroundTransparency = 1
Title.Font = Enum.Font.GothamBold
Title.TextColor3 = Color3.fromRGB(255, 255, 255)
Title.TextScaled = true
Title.Active = true -- drag handle
Title.Parent = Panel

-- Touch + mouse drag via the title bar
do
    local dragInput, dragStart, startPos
    Title.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1
            or input.UserInputType == Enum.UserInputType.Touch then
            dragInput = input
            dragStart = input.Position
            startPos = Panel.Position
        end
    end)
    track(UserInputService.InputChanged:Connect(function(input)
        if not dragStart then
            return
        end
        local isMove = input.UserInputType == Enum.UserInputType.MouseMovement
            or (input.UserInputType == Enum.UserInputType.Touch and input == dragInput)
        if isMove then
            local delta = input.Position - dragStart
            Panel.Position = UDim2.new(
                startPos.X.Scale, startPos.X.Offset + delta.X,
                startPos.Y.Scale, startPos.Y.Offset + delta.Y
            )
        end
    end))
    track(UserInputService.InputEnded:Connect(function(input)
        if input == dragInput or input.UserInputType == Enum.UserInputType.MouseButton1 then
            dragInput, dragStart = nil, nil
        end
    end))
end

--------------------------------------------------------------------------
-- Notifications
--------------------------------------------------------------------------
local function notify(text, soundId, onDone)
    local Toast = Instance.new("Frame")
    Toast.Size = UDim2.new(0, 310, 0, 60)
    Toast.AnchorPoint = Vector2.new(1, 1)
    Toast.Position = UDim2.new(1, -10, 1, 100)
    Toast.BackgroundColor3 = Color3.fromRGB(25, 25, 25)
    Toast.BackgroundTransparency = 0.1
    Toast.BorderSizePixel = 0
    Toast.ZIndex = 30
    Toast.Parent = ScreenGui
    Instance.new("UICorner", Toast).CornerRadius = UDim.new(0, 10)

    local Icon = Instance.new("ImageLabel")
    Icon.Size = UDim2.new(0, 40, 0, 40)
    Icon.Position = UDim2.new(0, 5, 0.5, -20)
    Icon.BackgroundTransparency = 1
    Icon.Image = "rbxassetid://77474537431792"
    Icon.ZIndex = 31
    Icon.Parent = Toast

    local Label = Instance.new("TextLabel")
    Label.Size = UDim2.new(1, -60, 1, 0)
    Label.Position = UDim2.new(0, 55, 0, 0)
    Label.BackgroundTransparency = 1
    Label.Text = text
    Label.TextColor3 = Color3.fromRGB(255, 255, 255)
    Label.TextSize = 18
    Label.Font = Enum.Font.GothamBold
    Label.TextXAlignment = Enum.TextXAlignment.Left
    Label.TextYAlignment = Enum.TextYAlignment.Center
    Label.TextWrapped = true
    Label.ZIndex = 31
    Label.Parent = Toast

    local Sound = Instance.new("Sound")
    Sound.SoundId = soundId
    Sound.Volume = 1
    Sound.Parent = ScreenGui
    Sound:Play()

    TweenService:Create(Toast, TweenInfo.new(0.5, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), {
        Position = UDim2.new(1, -10, 1, -10),
    }):Play()
    task.delay(3, function()
        local out = TweenService:Create(Toast, TweenInfo.new(0.5, Enum.EasingStyle.Quint, Enum.EasingDirection.In), {
            Position = UDim2.new(1, -10, 1, 100),
        })
        out:Play()
        out.Completed:Connect(function()
            Toast:Destroy()
            if onDone then
                onDone()
            end
        end)
    end)
end

--------------------------------------------------------------------------
-- Close button + confirmation
--------------------------------------------------------------------------
local CloseButton = Instance.new("TextButton")
CloseButton.Size = UDim2.new(0, 30, 0, 30)
CloseButton.Position = UDim2.new(1, -35, 1, -35)
CloseButton.BackgroundColor3 = Color3.fromRGB(255, 50, 50)
CloseButton.Text = "X"
CloseButton.TextColor3 = Color3.new(1, 1, 1)
CloseButton.Font = Enum.Font.GothamBold
CloseButton.TextScaled = true
CloseButton.Parent = Panel
Instance.new("UICorner", CloseButton).CornerRadius = UDim.new(1, 0)

local function shutdown()
    aimbotEnabled = false
    FovCircle.Visible = false
    pcall(function()
        RunService:UnbindFromRenderStep(RENDER_NAME)
    end)
    for _, conn in ipairs(connections) do
        conn:Disconnect()
    end
    table.clear(connections)
end

CloseButton.MouseButton1Click:Connect(function()
    if ScreenGui:FindFirstChild("ConfirmOverlay") then
        return
    end

    local Overlay = Instance.new("Frame")
    Overlay.Name = "ConfirmOverlay"
    Overlay.Size = UDim2.new(1, 0, 1, 0)
    Overlay.BackgroundColor3 = Color3.new(0, 0, 0)
    Overlay.BackgroundTransparency = 1
    Overlay.ZIndex = 20
    Overlay.Parent = ScreenGui

    local Dialog = Instance.new("Frame")
    Dialog.Size = UDim2.new(0, 300, 0, 140)
    Dialog.Position = UDim2.new(0.5, -150, 0.5, -70)
    Dialog.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
    Dialog.ZIndex = 21
    Dialog.Parent = Overlay
    Instance.new("UICorner", Dialog).CornerRadius = UDim.new(0, 10)

    local DTitle = Instance.new("TextLabel")
    DTitle.Size = UDim2.new(1, 0, 0, 30)
    DTitle.Position = UDim2.new(0, 0, 0, 10)
    DTitle.Text = "Fechar GUI"
    DTitle.Font = Enum.Font.GothamBold
    DTitle.TextColor3 = Color3.new(1, 1, 1)
    DTitle.TextScaled = true
    DTitle.BackgroundTransparency = 1
    DTitle.ZIndex = 21
    DTitle.Parent = Dialog

    local DText = Instance.new("TextLabel")
    DText.Size = UDim2.new(1, -20, 0, 40)
    DText.Position = UDim2.new(0, 10, 0, 45)
    DText.Text = "Você quer realmente fechar a interface?"
    DText.TextWrapped = true
    DText.Font = Enum.Font.Gotham
    DText.TextColor3 = Color3.new(1, 1, 1)
    DText.TextScaled = true
    DText.BackgroundTransparency = 1
    DText.ZIndex = 21
    DText.Parent = Dialog

    local Yes = Instance.new("TextButton")
    Yes.Size = UDim2.new(0.45, -5, 0, 30)
    Yes.Position = UDim2.new(0.05, 0, 1, -40)
    Yes.BackgroundColor3 = Color3.fromRGB(255, 50, 50)
    Yes.Text = "SIM"
    Yes.Font = Enum.Font.GothamBold
    Yes.TextColor3 = Color3.new(1, 1, 1)
    Yes.TextScaled = true
    Yes.ZIndex = 21
    Yes.Parent = Dialog
    Instance.new("UICorner", Yes).CornerRadius = UDim.new(0, 6)

    local No = Instance.new("TextButton")
    No.Size = UDim2.new(0.45, -5, 0, 30)
    No.Position = UDim2.new(0.5, 5, 1, -40)
    No.BackgroundColor3 = Color3.fromRGB(60, 150, 255)
    No.Text = "NÃO"
    No.Font = Enum.Font.GothamBold
    No.TextColor3 = Color3.new(1, 1, 1)
    No.TextScaled = true
    No.ZIndex = 21
    No.Parent = Dialog
    Instance.new("UICorner", No).CornerRadius = UDim.new(0, 6)

    Yes.MouseButton1Click:Connect(function()
        shutdown()
        Overlay:Destroy()
        Panel.Visible = false
        ToggleButton.Visible = false
        notify("Até a próxima!\nBy ZecadaDiv", "rbxassetid://8284260932", function()
            ScreenGui:Destroy()
        end)
    end)
    No.MouseButton1Click:Connect(function()
        Overlay:Destroy()
    end)
end)

--------------------------------------------------------------------------
-- Aimbot toggle
--------------------------------------------------------------------------
local AimbotButton = Instance.new("TextButton")
AimbotButton.Size = UDim2.new(1, -20, 0, 30)
AimbotButton.Position = UDim2.new(0, 10, 0, 35)
AimbotButton.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
AimbotButton.TextColor3 = Color3.fromRGB(255, 255, 255)
AimbotButton.Text = "Ativar Aimbot: OFF"
AimbotButton.Font = Enum.Font.Gotham
AimbotButton.TextScaled = true
AimbotButton.Parent = Panel
Instance.new("UICorner", AimbotButton).CornerRadius = UDim.new(0, 6)

AimbotButton.MouseButton1Click:Connect(function()
    aimbotEnabled = not aimbotEnabled
    AimbotButton.Text = "Ativar Aimbot: " .. (aimbotEnabled and "ON" or "OFF")
    updateFovCircle()
end)

--------------------------------------------------------------------------
-- FOV slider
--------------------------------------------------------------------------
local FovLabel = Instance.new("TextLabel")
FovLabel.Size = UDim2.new(1, -20, 0, 30)
FovLabel.Position = UDim2.new(0, 10, 0, 70)
FovLabel.BackgroundTransparency = 1
FovLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
FovLabel.Text = "FOV: " .. fovRadius
FovLabel.Font = Enum.Font.Gotham
FovLabel.TextScaled = true
FovLabel.Parent = Panel

local SliderBar = Instance.new("TextButton")
SliderBar.Size = UDim2.new(1, -20, 0, 15)
SliderBar.Position = UDim2.new(0, 10, 0, 105)
SliderBar.BackgroundColor3 = Color3.fromRGB(70, 70, 70)
SliderBar.Text = ""
SliderBar.AutoButtonColor = false
SliderBar.Parent = Panel

local SliderKnob = Instance.new("Frame")
SliderKnob.Size = UDim2.new(0, 10, 1, 0)
SliderKnob.AnchorPoint = Vector2.new(0.5, 0)
SliderKnob.Position = UDim2.new(fovRadius / FOV_MAX, 0, 0, 0)
SliderKnob.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
SliderKnob.Parent = SliderBar
Instance.new("UICorner", SliderKnob).CornerRadius = UDim.new(1, 0)

local sliderInput -- the touch/mouse input currently dragging the slider

local function setSliderFromX(x)
    local width = SliderBar.AbsoluteSize.X
    if width <= 0 then
        return
    end
    local alpha = math.clamp((x - SliderBar.AbsolutePosition.X) / width, 0, 1)
    fovRadius = math.max(FOV_MIN, math.floor(alpha * FOV_MAX))
    SliderKnob.Position = UDim2.new(fovRadius / FOV_MAX, 0, 0, 0)
    FovLabel.Text = "FOV: " .. fovRadius
    updateFovCircle()
end

SliderBar.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.Touch
        or input.UserInputType == Enum.UserInputType.MouseButton1 then
        sliderInput = input
        setSliderFromX(input.Position.X)
    end
end)
track(UserInputService.InputChanged:Connect(function(input)
    if not sliderInput then
        return
    end
    if input.UserInputType == Enum.UserInputType.MouseMovement
        or (input.UserInputType == Enum.UserInputType.Touch and input == sliderInput) then
        setSliderFromX(input.Position.X)
    end
end))
track(UserInputService.InputEnded:Connect(function(input)
    if input == sliderInput or input.UserInputType == Enum.UserInputType.MouseButton1 then
        sliderInput = nil
    end
end))

--------------------------------------------------------------------------
-- Check toggles
--------------------------------------------------------------------------
local function makeToggle(name, y, initial, onChanged)
    local state = initial
    local Button = Instance.new("TextButton")
    Button.Size = UDim2.new(1, -20, 0, 25)
    Button.Position = UDim2.new(0, 10, 0, y)
    Button.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
    Button.TextColor3 = Color3.fromRGB(255, 255, 255)
    Button.Font = Enum.Font.Gotham
    Button.TextScaled = true
    Button.Text = name .. ": " .. (state and "ON" or "OFF")
    Button.Parent = Panel
    Instance.new("UICorner", Button).CornerRadius = UDim.new(0, 6)

    Button.MouseButton1Click:Connect(function()
        state = not state
        Button.Text = name .. ": " .. (state and "ON" or "OFF")
        onChanged(state)
    end)
end

makeToggle("Team Check", 130, teamCheck, function(v)
    teamCheck = v
end)
makeToggle("Kill Check", 160, killCheck, function(v)
    killCheck = v
end)
makeToggle("Wall Check", 190, wallCheck, function(v)
    wallCheck = v
end)

--------------------------------------------------------------------------
-- Target part dropdown
--------------------------------------------------------------------------
-- Display name -> candidate part names (R6 first, then R15).
local PART_ALIASES = {
    Head = { "Head" },
    Torso = { "Torso", "UpperTorso", "LowerTorso" },
    HumanoidRootPart = { "HumanoidRootPart" },
    ["Left Leg"] = { "Left Leg", "LeftUpperLeg", "LeftLowerLeg" },
    ["Right Leg"] = { "Right Leg", "RightUpperLeg", "RightLowerLeg" },
}
local PART_OPTIONS = { "Head", "Torso", "HumanoidRootPart", "Left Leg", "Right Leg" }

local function getTargetPart(character)
    for _, partName in ipairs(PART_ALIASES[targetPartName] or { targetPartName }) do
        local part = character:FindFirstChild(partName)
        if part and part:IsA("BasePart") then
            return part
        end
    end
    -- Fall back so the aimbot still works if the rig lacks the chosen part.
    return character:FindFirstChild("Head") or character:FindFirstChild("HumanoidRootPart")
end

do
    local Holder = Instance.new("Frame")
    Holder.Size = UDim2.new(1, -20, 0, 36)
    Holder.Position = UDim2.new(0, 10, 0, 220)
    Holder.BackgroundTransparency = 1
    Holder.ZIndex = 5
    Holder.Parent = Panel

    local Label = Instance.new("TextLabel")
    Label.Text = "Aimbot Target Part"
    Label.Size = UDim2.new(1, 0, 0, 16)
    Label.TextSize = 13
    Label.TextColor3 = Color3.fromRGB(255, 255, 255)
    Label.BackgroundTransparency = 1
    Label.Font = Enum.Font.Gotham
    Label.ZIndex = 5
    Label.Parent = Holder

    local Selected = Instance.new("TextButton")
    Selected.Size = UDim2.new(1, 0, 0, 20)
    Selected.Position = UDim2.new(0, 0, 0, 16)
    Selected.BackgroundColor3 = Color3.fromRGB(25, 25, 25)
    Selected.BorderSizePixel = 0
    Selected.Text = targetPartName
    Selected.TextSize = 14
    Selected.TextColor3 = Color3.fromRGB(255, 255, 255)
    Selected.Font = Enum.Font.GothamBold
    Selected.ZIndex = 5
    Selected.Parent = Holder

    local List = Instance.new("Frame")
    List.Visible = false
    List.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
    List.BorderSizePixel = 0
    List.Position = UDim2.new(0, 0, 1, 0)
    List.Size = UDim2.new(1, 0, 0, #PART_OPTIONS * 20)
    List.ClipsDescendants = true
    List.ZIndex = 6
    List.Parent = Selected

    for i, option in ipairs(PART_OPTIONS) do
        local Item = Instance.new("TextButton")
        Item.Text = option
        Item.Size = UDim2.new(1, 0, 0, 20)
        Item.Position = UDim2.new(0, 0, 0, (i - 1) * 20)
        Item.BackgroundTransparency = 1
        Item.TextSize = 14
        Item.TextColor3 = Color3.fromRGB(255, 255, 255)
        Item.Font = Enum.Font.Gotham
        Item.ZIndex = 7
        Item.Parent = List
        Item.MouseButton1Click:Connect(function()
            targetPartName = option
            Selected.Text = option
            List.Visible = false
        end)
    end

    Selected.MouseButton1Click:Connect(function()
        List.Visible = not List.Visible
    end)
end

--------------------------------------------------------------------------
-- Targeting
--------------------------------------------------------------------------
local function isVisible(camera, part, character)
    local origin = camera.CFrame.Position
    local params = RaycastParams.new()
    params.FilterType = Enum.RaycastFilterType.Exclude
    params.FilterDescendantsInstances = { LocalPlayer.Character, camera }
    local result = workspace:Raycast(origin, part.Position - origin, params)
    return result == nil or result.Instance:IsDescendantOf(character)
end

local function getClosestTarget(camera)
    local center = camera.ViewportSize / 2
    local bestDist = math.huge
    local bestPart

    for _, player in ipairs(Players:GetPlayers()) do
        if player == LocalPlayer then
            continue
        end
        local character = player.Character
        if not character then
            continue
        end
        if teamCheck and player.Team ~= nil and player.Team == LocalPlayer.Team then
            continue
        end
        local humanoid = character:FindFirstChildOfClass("Humanoid")
        if killCheck and (not humanoid or humanoid.Health <= 0) then
            continue
        end
        local part = getTargetPart(character)
        if not part then
            continue
        end
        if wallCheck and not isVisible(camera, part, character) then
            continue
        end

        local screenPos, onScreen = camera:WorldToViewportPoint(part.Position)
        if onScreen then
            local dist = (Vector2.new(screenPos.X, screenPos.Y) - center).Magnitude
            if dist < fovRadius and dist < bestDist then
                bestDist = dist
                bestPart = part
            end
        end
    end

    return bestPart
end

RunService:BindToRenderStep(RENDER_NAME, Enum.RenderPriority.Camera.Value + 1, function()
    updateFovCircle()
    if not aimbotEnabled then
        return
    end
    local camera = workspace.CurrentCamera
    if not camera then
        return
    end
    local part = getClosestTarget(camera)
    if part then
        camera.CFrame = CFrame.new(camera.CFrame.Position, part.Position)
    end
end)

--------------------------------------------------------------------------
-- Startup
--------------------------------------------------------------------------
notify("Script Ativado\nBy ZecadaDiv", "rbxassetid://6026984224")
if setclipboard then
    pcall(setclipboard, "https://www.roblox.com/pt/users/7904067601/profile?friendshipSourceType=PlayerSearch")
end
