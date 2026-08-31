--!nocheck
-- Advanced Aimbot + ESP with Menu  (bug-fixed version)
-- Press INSERT to open the menu.  Hold RIGHT CLICK to aim (when Aimbot is ON).
--
-- Fixes over the original:
--   * Aimbot menu-toggle no longer fights the right-click hold (separate flags).
--   * Per-feature ESP toggles (Boxes/Names/Health/Tracers/HeadDots) are now
--     actually respected by the render loop instead of being overwritten to
--     visible every frame.
--   * Turning "ESP Master" off now hides drawings instead of freezing them.
--   * "Show Names + Distance" toggles the Distance drawing too.
--   * ESP is hidden for players with no character / missing parts / dead / off-screen.
--   * Guards against MaxHealth == 0, hpPct out of range, and a degenerate aim CFrame.
--   * getClosest uses the real screen centre and no longer depends on draw order.

local uis = game:GetService("UserInputService")
local Players = game:GetService("Players")
local rs = game:GetService("RunService")

local plr = Players.LocalPlayer
local cam = workspace.CurrentCamera

-- ==================== STATE ====================
local aimbotEnabled = true   -- menu toggle: is the aimbot allowed to run?
local rightHeld     = false  -- is right mouse button currently held?
local fovRadius     = 120

local espEnabled  = true     -- ESP master switch
local showBoxes   = true
local showNames   = true     -- controls Name + Distance
local showHealth  = true
local showTracers = true
local showHeadDots = true

-- FOV Circle
local fovCircle = Drawing.new("Circle")
fovCircle.Radius = fovRadius
fovCircle.Color = Color3.fromRGB(255, 255, 0)
fovCircle.Thickness = 1.5
fovCircle.Transparency = 0.7
fovCircle.Visible = true
fovCircle.Filled = false

-- ESP Tables
local esp = {}

-- ==================== MENU ====================
local screenGui = Instance.new("ScreenGui")
screenGui.Name = "AimbotESP_Menu"
screenGui.ResetOnSpawn = false
screenGui.Parent = plr:WaitForChild("PlayerGui")

local menuFrame = Instance.new("Frame")
menuFrame.Size = UDim2.new(0, 380, 0, 520)
menuFrame.Position = UDim2.new(0.5, -190, 0.5, -260)
menuFrame.BackgroundColor3 = Color3.fromRGB(25, 25, 35)
menuFrame.BorderSizePixel = 0
menuFrame.Visible = false
menuFrame.Parent = screenGui

local title = Instance.new("TextLabel")
title.Size = UDim2.new(1, 0, 0, 50)
title.BackgroundColor3 = Color3.fromRGB(35, 35, 50)
title.Text = "Advanced Aimbot + ESP"
title.TextColor3 = Color3.fromRGB(255, 255, 255)
title.TextSize = 18
title.Font = Enum.Font.GothamBold
title.Parent = menuFrame

-- Close Button
local closeBtn = Instance.new("TextButton")
closeBtn.Size = UDim2.new(0, 30, 0, 30)
closeBtn.Position = UDim2.new(1, -35, 0, 10)
closeBtn.BackgroundTransparency = 1
closeBtn.Text = "X"
closeBtn.TextColor3 = Color3.fromRGB(255, 80, 80)
closeBtn.TextSize = 20
closeBtn.Font = Enum.Font.GothamBold
closeBtn.Parent = menuFrame

-- Menu Items
local function createToggle(name, default, yOffset, callback)
    local toggleFrame = Instance.new("Frame")
    toggleFrame.Size = UDim2.new(1, -20, 0, 40)
    toggleFrame.Position = UDim2.new(0, 10, 0, yOffset)
    toggleFrame.BackgroundTransparency = 1
    toggleFrame.Parent = menuFrame

    local label = Instance.new("TextLabel")
    label.Size = UDim2.new(0.7, 0, 1, 0)
    label.BackgroundTransparency = 1
    label.Text = name
    label.TextColor3 = Color3.fromRGB(255, 255, 255)
    label.TextSize = 15
    label.Font = Enum.Font.Gotham
    label.TextXAlignment = Enum.TextXAlignment.Left
    label.Parent = toggleFrame

    local toggleBtn = Instance.new("TextButton")
    toggleBtn.Size = UDim2.new(0, 60, 0, 25)
    toggleBtn.Position = UDim2.new(1, -70, 0.5, -12.5)
    toggleBtn.BackgroundColor3 = default and Color3.fromRGB(0, 170, 0) or Color3.fromRGB(100, 100, 100)
    toggleBtn.Text = default and "ON" or "OFF"
    toggleBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
    toggleBtn.TextSize = 13
    toggleBtn.Font = Enum.Font.GothamBold
    toggleBtn.Parent = toggleFrame

    local enabled = default
    toggleBtn.MouseButton1Click:Connect(function()
        enabled = not enabled
        toggleBtn.BackgroundColor3 = enabled and Color3.fromRGB(0, 170, 0) or Color3.fromRGB(100, 100, 100)
        toggleBtn.Text = enabled and "ON" or "OFF"
        callback(enabled)
    end)

    return toggleBtn
end

local function createSlider(name, min, max, default, yOffset, callback)
    local sliderFrame = Instance.new("Frame")
    sliderFrame.Size = UDim2.new(1, -20, 0, 50)
    sliderFrame.Position = UDim2.new(0, 10, 0, yOffset)
    sliderFrame.BackgroundTransparency = 1
    sliderFrame.Parent = menuFrame

    local label = Instance.new("TextLabel")
    label.Size = UDim2.new(1, 0, 0, 20)
    label.BackgroundTransparency = 1
    label.Text = name .. ": " .. default
    label.TextColor3 = Color3.fromRGB(255, 255, 255)
    label.TextSize = 15
    label.Font = Enum.Font.Gotham
    label.TextXAlignment = Enum.TextXAlignment.Left
    label.Parent = sliderFrame

    local bar = Instance.new("Frame")
    bar.Size = UDim2.new(1, 0, 0, 8)
    bar.Position = UDim2.new(0, 0, 0, 30)
    bar.BackgroundColor3 = Color3.fromRGB(50, 50, 65)
    bar.BorderSizePixel = 0
    bar.Parent = sliderFrame

    local fill = Instance.new("Frame")
    -- guard against a zero range (max == min)
    local startPct = (max ~= min) and math.clamp((default - min) / (max - min), 0, 1) or 0
    fill.Size = UDim2.new(startPct, 0, 1, 0)
    fill.BackgroundColor3 = Color3.fromRGB(0, 170, 255)
    fill.BorderSizePixel = 0
    fill.Parent = bar

    local dragging = false
    bar.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then
            dragging = true
        end
    end)

    uis.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then
            dragging = false
        end
    end)

    uis.InputChanged:Connect(function(input)
        if dragging and input.UserInputType == Enum.UserInputType.MouseMovement then
            local mousePos = uis:GetMouseLocation().X
            local barPos = bar.AbsolutePosition.X
            local barSize = bar.AbsoluteSize.X
            local percent = (barSize > 0) and math.clamp((mousePos - barPos) / barSize, 0, 1) or 0
            local value = math.floor(min + (max - min) * percent)

            fill.Size = UDim2.new(percent, 0, 1, 0)
            label.Text = name .. ": " .. value
            callback(value)
        end
    end)
end

-- Menu Toggles
createToggle("Aimbot (Right Click)", true, 60, function(state) aimbotEnabled = state end)
createToggle("ESP Master", true, 110, function(state) espEnabled = state end)
createToggle("Show Boxes", true, 160, function(state) showBoxes = state end)
createToggle("Show Names + Distance", true, 210, function(state) showNames = state end)
createToggle("Health Bars", true, 260, function(state) showHealth = state end)
createToggle("Tracers", true, 310, function(state) showTracers = state end)
createToggle("Head Dots", true, 360, function(state) showHeadDots = state end)

createSlider("FOV Radius", 50, 300, 120, 410, function(value)
    fovRadius = value
    fovCircle.Radius = value
end)

-- Toggle Menu with Insert Key
uis.InputBegan:Connect(function(input, gpe)
    if gpe then return end
    if input.KeyCode == Enum.KeyCode.Insert then
        menuFrame.Visible = not menuFrame.Visible
    end
end)

closeBtn.MouseButton1Click:Connect(function()
    menuFrame.Visible = false
end)

-- ==================== ESP ====================
local function hideESP(v)
    for _, obj in pairs(v) do
        obj.Visible = false
    end
end

local function createESP(player)
    if player == plr then return end
    if esp[player] then return end -- never double-create drawings for a player

    esp[player] = {
        Box = Drawing.new("Square"), BoxOutline = Drawing.new("Square"),
        Name = Drawing.new("Text"), Distance = Drawing.new("Text"),
        HealthBar = Drawing.new("Square"), HealthBarOutline = Drawing.new("Square"),
        Tracer = Drawing.new("Line"), HeadDot = Drawing.new("Circle")
    }

    local v = esp[player]
    -- Box Setup
    v.Box.Thickness = 1.5; v.Box.Filled = false; v.Box.Color = Color3.fromRGB(255, 0, 0); v.Box.Transparency = 1
    v.BoxOutline.Thickness = 3; v.BoxOutline.Filled = false; v.BoxOutline.Color = Color3.fromRGB(0, 0, 0); v.BoxOutline.Transparency = 1

    -- Name & Distance
    v.Name.Size = 14; v.Name.Center = true; v.Name.Outline = true; v.Name.Color = Color3.fromRGB(255, 255, 255)
    v.Distance.Size = 13; v.Distance.Center = true; v.Distance.Outline = true; v.Distance.Color = Color3.fromRGB(200, 200, 200)

    -- Health Bar
    v.HealthBar.Filled = true; v.HealthBar.Transparency = 1
    v.HealthBarOutline.Filled = true; v.HealthBarOutline.Color = Color3.fromRGB(0, 0, 0); v.HealthBarOutline.Transparency = 1

    -- Tracer & Head Dot
    v.Tracer.Thickness = 1.5; v.Tracer.Color = Color3.fromRGB(255, 0, 0); v.Tracer.Transparency = 0.7
    v.HeadDot.Radius = 2.5; v.HeadDot.Color = Color3.fromRGB(255, 0, 0); v.HeadDot.Filled = true

    hideESP(v) -- start hidden; render loop turns things on as needed
end

for _, p in pairs(Players:GetPlayers()) do createESP(p) end
Players.PlayerAdded:Connect(createESP)

Players.PlayerRemoving:Connect(function(player)
    if esp[player] then
        for _, obj in pairs(esp[player]) do obj:Remove() end
        esp[player] = nil
    end
end)

-- ==================== AIMBOT ====================
-- Get Closest Target within the FOV circle.
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

-- Right Click hold state
uis.InputBegan:Connect(function(input, gpe)
    if gpe then return end
    if input.UserInputType == Enum.UserInputType.MouseButton2 then
        rightHeld = true
    end
end)

uis.InputEnded:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton2 then
        rightHeld = false
    end
end)

-- ==================== MAIN RENDER LOOP ====================
rs.RenderStepped:Connect(function()
    fovCircle.Position = Vector2.new(cam.ViewportSize.X / 2, cam.ViewportSize.Y / 2)
    fovCircle.Visible = aimbotEnabled

    -- Aimbot: aim only while enabled AND right-click held
    if aimbotEnabled and rightHeld then
        local target = getClosest()
        if target then
            local camPos = cam.CFrame.Position
            -- avoid a degenerate look-at (throws when positions coincide)
            if (target.Position - camPos).Magnitude > 0.05 then
                cam.CFrame = CFrame.new(camPos, target.Position)
            end
        end
    end

    -- ESP master off: hide everything and stop.
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
                    local topY = math.min(headPos.Y, legPos.Y) -- true top of the box
                    local distance = math.floor((cam.CFrame.Position - root.Position).Magnitude)

                    -- Box
                    v.Box.Size = Vector2.new(width, height)
                    v.Box.Position = Vector2.new(rootPos.X - width / 2, topY)
                    v.Box.Visible = showBoxes

                    v.BoxOutline.Size = v.Box.Size
                    v.BoxOutline.Position = v.Box.Position
                    v.BoxOutline.Visible = showBoxes

                    -- Name + Distance
                    v.Name.Text = player.Name
                    v.Name.Position = Vector2.new(rootPos.X, topY - 18)
                    v.Name.Visible = showNames

                    v.Distance.Text = distance .. "m"
                    v.Distance.Position = Vector2.new(rootPos.X, topY - 5)
                    v.Distance.Visible = showNames

                    -- Health Bar (guard MaxHealth == 0 and clamp)
                    local maxHp = humanoid.MaxHealth
                    local hpPct = (maxHp > 0) and math.clamp(humanoid.Health / maxHp, 0, 1) or 0
                    v.HealthBar.Size = Vector2.new(4, height * hpPct)
                    v.HealthBar.Position = Vector2.new(rootPos.X - width / 2 - 8, topY + height * (1 - hpPct))
                    v.HealthBar.Color = Color3.fromRGB(math.floor(255 * (1 - hpPct)), math.floor(255 * hpPct), 0)
                    v.HealthBar.Visible = showHealth

                    v.HealthBarOutline.Size = Vector2.new(6, height)
                    v.HealthBarOutline.Position = Vector2.new(rootPos.X - width / 2 - 9, topY)
                    v.HealthBarOutline.Visible = showHealth

                    -- Head Dot
                    v.HeadDot.Position = Vector2.new(headPos.X, headPos.Y)
                    v.HeadDot.Visible = showHeadDots

                    -- Tracer
                    v.Tracer.From = Vector2.new(cam.ViewportSize.X / 2, cam.ViewportSize.Y)
                    v.Tracer.To = Vector2.new(rootPos.X, topY + height)
                    v.Tracer.Visible = showTracers
                end
            end

            if not rendered then
                hideESP(v) -- off-screen, dead, no character, or missing parts
            end
        end
    end
end)

print("Advanced Aimbot + ESP with Menu Loaded! Press INSERT to open menu.")
