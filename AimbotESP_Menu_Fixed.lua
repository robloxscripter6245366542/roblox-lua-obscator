--!nocheck
-- Advanced Aimbot + ESP  (100% ScreenGui — no Drawing API)
-- Built for executors that don't support the Drawing API (e.g. Delta).
--
--   * Hold RIGHT CLICK (PC) or the on-screen AIM button (mobile) to aim.
--   * Press INSERT to show/hide the FOV panel.
--   * The only UI control is the Aimbot FOV size (drag the slider).
--
-- Everything that used to be a Drawing (FOV circle, ESP boxes, names,
-- health bars, tracers, head dots) is now a real GUI Instance so it renders
-- on ScreenGui-only executors.

local uis = game:GetService("UserInputService")
local Players = game:GetService("Players")
local rs = game:GetService("RunService")

local plr = Players.LocalPlayer
local cam = workspace.CurrentCamera

-- ==================== STATE ====================
local rightHeld = false    -- PC: right mouse button held
local aimButtonHeld = false -- mobile: on-screen AIM button held
local fovMin, fovMax = 30, 600
local fovRadius = 120

local espEnabled = true
local showBoxes    = true
local showNames    = true
local showHealth   = true
local showTracers  = true
local showHeadDots = true

-- ==================== GUI ROOT ====================
local function getGuiParent()
    -- prefer a hidden container if the executor exposes one, else PlayerGui
    local ok, hui = pcall(function() return gethui() end)
    if ok and hui then return hui end
    return plr:WaitForChild("PlayerGui")
end

local gui = Instance.new("ScreenGui")
gui.Name = "AimbotESP"
gui.ResetOnSpawn = false
gui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
gui.DisplayOrder = 9999
gui.IgnoreGuiInset = false -- matches Camera:WorldToViewportPoint coordinates
gui.Parent = getGuiParent()

local espFolder = Instance.new("Folder")
espFolder.Name = "ESP"
espFolder.Parent = gui

-- ==================== FOV RING ====================
local fovRing = Instance.new("Frame")
fovRing.Name = "FOVRing"
fovRing.AnchorPoint = Vector2.new(0.5, 0.5)
fovRing.BackgroundTransparency = 1
fovRing.BorderSizePixel = 0
fovRing.Parent = gui
do
    local c = Instance.new("UICorner")
    c.CornerRadius = UDim.new(1, 0)
    c.Parent = fovRing
    local s = Instance.new("UIStroke")
    s.Color = Color3.fromRGB(255, 255, 0)
    s.Thickness = 1.5
    s.Transparency = 0.3
    s.Parent = fovRing
end

-- ==================== FOV MENU (ScreenGui slider) ====================
local menu = Instance.new("Frame")
menu.Name = "Menu"
menu.Size = UDim2.fromOffset(240, 92)
menu.Position = UDim2.fromOffset(24, 80)
menu.BackgroundColor3 = Color3.fromRGB(25, 25, 35)
menu.BackgroundTransparency = 0.1
menu.BorderSizePixel = 0
menu.Parent = gui
do
    local c = Instance.new("UICorner")
    c.CornerRadius = UDim.new(0, 8)
    c.Parent = menu
    local s = Instance.new("UIStroke")
    s.Color = Color3.fromRGB(0, 170, 255)
    s.Thickness = 1
    s.Parent = menu
end

local titleBar = Instance.new("TextLabel")
titleBar.Name = "TitleBar"
titleBar.Size = UDim2.new(1, 0, 0, 30)
titleBar.BackgroundColor3 = Color3.fromRGB(35, 35, 50)
titleBar.BorderSizePixel = 0
titleBar.Text = "Aimbot FOV"
titleBar.TextColor3 = Color3.fromRGB(255, 255, 255)
titleBar.Font = Enum.Font.GothamBold
titleBar.TextSize = 15
titleBar.Parent = menu
do
    local c = Instance.new("UICorner")
    c.CornerRadius = UDim.new(0, 8)
    c.Parent = titleBar
end

local valueLabel = Instance.new("TextLabel")
valueLabel.Size = UDim2.new(1, -20, 0, 20)
valueLabel.Position = UDim2.fromOffset(12, 36)
valueLabel.BackgroundTransparency = 1
valueLabel.Text = "FOV: " .. fovRadius
valueLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
valueLabel.Font = Enum.Font.Gotham
valueLabel.TextSize = 14
valueLabel.TextXAlignment = Enum.TextXAlignment.Left
valueLabel.Parent = menu

local bar = Instance.new("Frame")
bar.Name = "Bar"
bar.Size = UDim2.new(1, -24, 0, 12)
bar.Position = UDim2.fromOffset(12, 62)
bar.BackgroundColor3 = Color3.fromRGB(50, 50, 65)
bar.BorderSizePixel = 0
bar.Parent = menu
do
    local c = Instance.new("UICorner")
    c.CornerRadius = UDim.new(1, 0)
    c.Parent = bar
end

local fill = Instance.new("Frame")
fill.Name = "Fill"
fill.Size = UDim2.new(0, 0, 1, 0)
fill.BackgroundColor3 = Color3.fromRGB(0, 170, 255)
fill.BorderSizePixel = 0
fill.Parent = bar
do
    local c = Instance.new("UICorner")
    c.CornerRadius = UDim.new(1, 0)
    c.Parent = fill
end

local function setFov(value)
    value = math.clamp(math.floor(value + 0.5), fovMin, fovMax)
    fovRadius = value
    local pct = (fovMax ~= fovMin) and (value - fovMin) / (fovMax - fovMin) or 0
    fill.Size = UDim2.new(pct, 0, 1, 0)
    valueLabel.Text = "FOV: " .. value
end
setFov(fovRadius)

-- --- slider drag (real GUI input; works with mouse and touch) ---
local sliderDragging = false
local function updateFovFromX(px)
    if bar.AbsoluteSize.X <= 0 then return end
    local rel = math.clamp((px - bar.AbsolutePosition.X) / bar.AbsoluteSize.X, 0, 1)
    setFov(fovMin + rel * (fovMax - fovMin))
end
bar.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1
        or input.UserInputType == Enum.UserInputType.Touch then
        sliderDragging = true
        updateFovFromX(input.Position.X)
    end
end)

-- --- title-bar drag to move the panel ---
local menuDragging, dragStart, panelStart = false, nil, nil
titleBar.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1
        or input.UserInputType == Enum.UserInputType.Touch then
        menuDragging = true
        dragStart = input.Position
        panelStart = menu.Position
    end
end)

uis.InputChanged:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseMovement
        or input.UserInputType == Enum.UserInputType.Touch then
        if sliderDragging then
            updateFovFromX(input.Position.X)
        end
        if menuDragging then
            local d = input.Position - dragStart
            menu.Position = UDim2.new(
                panelStart.X.Scale, panelStart.X.Offset + d.X,
                panelStart.Y.Scale, panelStart.Y.Offset + d.Y)
        end
    end
end)

-- ==================== MOBILE AIM BUTTON ====================
-- Mobile has no right-click, so provide an on-screen hold-to-aim button.
local aimBtn = Instance.new("TextButton")
aimBtn.Name = "AimButton"
aimBtn.AnchorPoint = Vector2.new(1, 1)
aimBtn.Position = UDim2.new(1, -30, 1, -120)
aimBtn.Size = UDim2.fromOffset(90, 90)
aimBtn.BackgroundColor3 = Color3.fromRGB(35, 35, 50)
aimBtn.BackgroundTransparency = 0.35
aimBtn.AutoButtonColor = false
aimBtn.Text = "AIM"
aimBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
aimBtn.Font = Enum.Font.GothamBold
aimBtn.TextSize = 20
aimBtn.Parent = gui
do
    local c = Instance.new("UICorner")
    c.CornerRadius = UDim.new(1, 0)
    c.Parent = aimBtn
    local s = Instance.new("UIStroke")
    s.Color = Color3.fromRGB(0, 170, 255)
    s.Thickness = 2
    s.Parent = aimBtn
end

local function setAimButton(state)
    aimButtonHeld = state
    aimBtn.BackgroundColor3 = state and Color3.fromRGB(0, 120, 60) or Color3.fromRGB(35, 35, 50)
end
aimBtn.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1
        or input.UserInputType == Enum.UserInputType.Touch then
        setAimButton(true)
    end
end)
aimBtn.InputEnded:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1
        or input.UserInputType == Enum.UserInputType.Touch then
        setAimButton(false)
    end
end)

-- ==================== ESP (ScreenGui Instances) ====================
local esp = {}

local function hideESP(v)
    v.box.Visible = false
    v.name.Visible = false
    v.distance.Visible = false
    v.healthOutline.Visible = false
    v.headDot.Visible = false
    v.tracer.Visible = false
end

local function createESP(player)
    if player == plr then return end
    if esp[player] then return end

    local box = Instance.new("Frame")
    box.BackgroundTransparency = 1
    box.BorderSizePixel = 0
    box.Parent = espFolder
    local boxStroke = Instance.new("UIStroke")
    boxStroke.Color = Color3.fromRGB(255, 0, 0)
    boxStroke.Thickness = 1.5
    boxStroke.Parent = box

    local name = Instance.new("TextLabel")
    name.AnchorPoint = Vector2.new(0.5, 1)
    name.BackgroundTransparency = 1
    name.Font = Enum.Font.GothamBold
    name.TextSize = 13
    name.TextColor3 = Color3.fromRGB(255, 255, 255)
    name.TextStrokeTransparency = 0
    name.Size = UDim2.fromOffset(200, 14)
    name.Parent = espFolder

    local distance = Instance.new("TextLabel")
    distance.AnchorPoint = Vector2.new(0.5, 0)
    distance.BackgroundTransparency = 1
    distance.Font = Enum.Font.Gotham
    distance.TextSize = 12
    distance.TextColor3 = Color3.fromRGB(200, 200, 200)
    distance.TextStrokeTransparency = 0
    distance.Size = UDim2.fromOffset(200, 14)
    distance.Parent = espFolder

    local healthOutline = Instance.new("Frame")
    healthOutline.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
    healthOutline.BorderSizePixel = 0
    healthOutline.Parent = espFolder
    local healthFill = Instance.new("Frame")
    healthFill.AnchorPoint = Vector2.new(0.5, 1)
    healthFill.Position = UDim2.new(0.5, 0, 1, 0)
    healthFill.BorderSizePixel = 0
    healthFill.Parent = healthOutline

    local headDot = Instance.new("Frame")
    headDot.AnchorPoint = Vector2.new(0.5, 0.5)
    headDot.BackgroundColor3 = Color3.fromRGB(255, 0, 0)
    headDot.BorderSizePixel = 0
    headDot.Size = UDim2.fromOffset(6, 6)
    headDot.Parent = espFolder
    do
        local c = Instance.new("UICorner")
        c.CornerRadius = UDim.new(1, 0)
        c.Parent = headDot
    end

    local tracer = Instance.new("Frame")
    tracer.AnchorPoint = Vector2.new(0, 0.5)
    tracer.BackgroundColor3 = Color3.fromRGB(255, 0, 0)
    tracer.BackgroundTransparency = 0.3
    tracer.BorderSizePixel = 0
    tracer.Parent = espFolder

    esp[player] = {
        box = box, name = name, distance = distance,
        healthOutline = healthOutline, healthFill = healthFill,
        headDot = headDot, tracer = tracer,
    }
    hideESP(esp[player])
end

for _, p in pairs(Players:GetPlayers()) do createESP(p) end
Players.PlayerAdded:Connect(createESP)

Players.PlayerRemoving:Connect(function(player)
    local v = esp[player]
    if v then
        for _, obj in pairs(v) do
            if typeof(obj) == "Instance" then obj:Destroy() end
        end
        esp[player] = nil
    end
end)

-- ==================== AIMBOT ====================
local function getClosest()
    local closest = nil
    local shortest = math.huge
    local center = Vector2.new(cam.ViewportSize.X / 2, cam.ViewportSize.Y / 2)
    local myHead = plr.Character and plr.Character:FindFirstChild("Head")

    for _, v in pairs(Players:GetPlayers()) do
        if v ~= plr and v.Character then
            local humanoid = v.Character:FindFirstChildOfClass("Humanoid")
            local head = v.Character:FindFirstChild("Head")
            if humanoid and humanoid.Health > 0 and head then
                local screenPos, onScreen = cam:WorldToViewportPoint(head.Position)
                if onScreen then
                    local distFromCenter = (Vector2.new(screenPos.X, screenPos.Y) - center).Magnitude
                    local dist3D = myHead and (head.Position - myHead.Position).Magnitude or math.huge
                    if distFromCenter <= fovRadius and dist3D < shortest then
                        shortest = dist3D
                        closest = head
                    end
                end
            end
        end
    end
    return closest
end

-- ==================== INPUT ====================
uis.InputBegan:Connect(function(input, gpe)
    if input.KeyCode == Enum.KeyCode.Insert then
        menu.Visible = not menu.Visible
        return
    end
    if gpe then return end
    if input.UserInputType == Enum.UserInputType.MouseButton2 then
        rightHeld = true
    end
end)

uis.InputEnded:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton2 then
        rightHeld = false
    elseif input.UserInputType == Enum.UserInputType.MouseButton1
        or input.UserInputType == Enum.UserInputType.Touch then
        sliderDragging = false
        menuDragging = false
        -- release aim if the finger/cursor lifted anywhere (e.g. slid off the button)
        if aimButtonHeld then setAimButton(false) end
    end
end)

-- ==================== MAIN RENDER LOOP ====================
rs.RenderStepped:Connect(function()
    local vp = cam.ViewportSize

    -- FOV ring follows screen centre, sized to the FOV radius
    fovRing.Position = UDim2.fromOffset(vp.X / 2, vp.Y / 2)
    fovRing.Size = UDim2.fromOffset(fovRadius * 2, fovRadius * 2)

    -- Aimbot: aim while right-click (PC) or the AIM button (mobile) is held
    if rightHeld or aimButtonHeld then
        local target = getClosest()
        if target then
            local camPos = cam.CFrame.Position
            if (target.Position - camPos).Magnitude > 0.05 then
                cam.CFrame = CFrame.new(camPos, target.Position)
            end
        end
    end

    if not espEnabled then
        for _, v in pairs(esp) do hideESP(v) end
        return
    end

    for _, player in pairs(Players:GetPlayers()) do
        local v = esp[player]
        if player ~= plr and v then
            local char = player.Character
            local root = char and char:FindFirstChild("HumanoidRootPart")
            local head = char and char:FindFirstChild("Head")
            local humanoid = char and char:FindFirstChildOfClass("Humanoid")

            local rendered = false
            if root and head and humanoid and humanoid.Health > 0 then
                local rootPos, onScreen = cam:WorldToViewportPoint(root.Position)
                if onScreen then
                    rendered = true
                    local headPos = cam:WorldToViewportPoint(head.Position + Vector3.new(0, 0.8, 0))
                    local legPos = cam:WorldToViewportPoint(root.Position - Vector3.new(0, 3.5, 0))
                    local height = math.abs(headPos.Y - legPos.Y)
                    local width = height * 0.55
                    local topY = math.min(headPos.Y, legPos.Y)
                    local bottomY = topY + height
                    local leftX = rootPos.X - width / 2
                    local distance = math.floor((cam.CFrame.Position - root.Position).Magnitude)

                    -- Box
                    v.box.Position = UDim2.fromOffset(leftX, topY)
                    v.box.Size = UDim2.fromOffset(width, height)
                    v.box.Visible = showBoxes

                    -- Name (above box) + Distance (below box)
                    v.name.Text = player.Name
                    v.name.Position = UDim2.fromOffset(rootPos.X, topY - 4)
                    v.name.Visible = showNames

                    v.distance.Text = distance .. "m"
                    v.distance.Position = UDim2.fromOffset(rootPos.X, bottomY + 2)
                    v.distance.Visible = showNames

                    -- Health bar (left of box)
                    local maxHp = humanoid.MaxHealth
                    local hpPct = (maxHp > 0) and math.clamp(humanoid.Health / maxHp, 0, 1) or 0
                    v.healthOutline.Position = UDim2.fromOffset(leftX - 8, topY)
                    v.healthOutline.Size = UDim2.fromOffset(4, height)
                    v.healthOutline.Visible = showHealth
                    v.healthFill.Size = UDim2.new(1, 0, hpPct, 0)
                    v.healthFill.BackgroundColor3 = Color3.fromRGB(
                        math.floor(255 * (1 - hpPct)), math.floor(255 * hpPct), 0)

                    -- Head dot
                    v.headDot.Position = UDim2.fromOffset(headPos.X, headPos.Y)
                    v.headDot.Visible = showHeadDots

                    -- Tracer (bottom centre of screen -> box bottom centre)
                    local from = Vector2.new(vp.X / 2, vp.Y)
                    local to = Vector2.new(rootPos.X, bottomY)
                    local diff = to - from
                    local len = diff.Magnitude
                    v.tracer.Position = UDim2.fromOffset(from.X, from.Y)
                    v.tracer.Size = UDim2.fromOffset(len, 1.5)
                    v.tracer.Rotation = math.deg(math.atan2(diff.Y, diff.X))
                    v.tracer.Visible = showTracers
                end
            end

            if not rendered then
                hideESP(v)
            end
        end
    end
end)

print("Advanced Aimbot + ESP (ScreenGui) loaded! Hold RIGHT CLICK or the AIM button to aim. Press INSERT for the FOV panel.")
