--!nocheck
-- Advanced Aimbot + ESP  (Drawing-API UI)
-- Hold RIGHT CLICK to aim.  Press INSERT to show/hide the FOV panel.
--
-- The UI is built entirely with the Drawing API (no ScreenGui / Instances),
-- and the only control is the Aimbot FOV size, per request.
--
-- Bug fixes carried over from the original menu script:
--   * Aimbot no longer double-writes its state; it aims only while
--     right-click is held.
--   * ESP drawings are hidden for off-screen / dead / character-less players
--     instead of freezing on the last frame.
--   * Health bar guards MaxHealth == 0 and clamps the percentage.
--   * Aim CFrame guarded against a degenerate look-at.
--   * getClosest uses the real screen centre.

local uis = game:GetService("UserInputService")
local Players = game:GetService("Players")
local rs = game:GetService("RunService")

local plr = Players.LocalPlayer
local cam = workspace.CurrentCamera

-- ==================== STATE ====================
local rightHeld = false      -- is right mouse button currently held?

local fovMin, fovMax = 30, 600
local fovRadius = 120

-- ESP is always on with these features (no UI toggles by design)
local espEnabled   = true
local showBoxes    = true
local showNames    = true
local showHealth   = true
local showTracers  = true
local showHeadDots  = true

-- FOV Circle
local fovCircle = Drawing.new("Circle")
fovCircle.Radius = fovRadius
fovCircle.Color = Color3.fromRGB(255, 255, 0)
fovCircle.Thickness = 1.5
fovCircle.Transparency = 0.7
fovCircle.Visible = true
fovCircle.Filled = false

-- ESP table
local esp = {}

-- ==================== DRAWING-API UI (FOV slider only) ====================
local UI_VISIBLE = true

-- panel geometry (absolute screen pixels)
local panelX, panelY = 24, 70
local panelW, panelH = 220, 70
local barX, barY = panelX + 12, panelY + 44
local barW, barH = panelW - 24, 12

local ui = {}
ui.bg = Drawing.new("Square")
ui.bg.Filled = true
ui.bg.Color = Color3.fromRGB(25, 25, 35)
ui.bg.Transparency = 0.85
ui.bg.Size = Vector2.new(panelW, panelH)
ui.bg.Position = Vector2.new(panelX, panelY)

ui.border = Drawing.new("Square")
ui.border.Filled = false
ui.border.Thickness = 1
ui.border.Color = Color3.fromRGB(0, 170, 255)
ui.border.Size = Vector2.new(panelW, panelH)
ui.border.Position = Vector2.new(panelX, panelY)

ui.title = Drawing.new("Text")
ui.title.Size = 16
ui.title.Center = false
ui.title.Outline = true
ui.title.Color = Color3.fromRGB(255, 255, 255)
ui.title.Position = Vector2.new(panelX + 12, panelY + 10)

ui.barTrack = Drawing.new("Square")
ui.barTrack.Filled = true
ui.barTrack.Color = Color3.fromRGB(50, 50, 65)
ui.barTrack.Size = Vector2.new(barW, barH)
ui.barTrack.Position = Vector2.new(barX, barY)

ui.barFill = Drawing.new("Square")
ui.barFill.Filled = true
ui.barFill.Color = Color3.fromRGB(0, 170, 255)
ui.barFill.Size = Vector2.new(0, barH)
ui.barFill.Position = Vector2.new(barX, barY)

local function setUIVisible(state)
    UI_VISIBLE = state
    for _, obj in pairs(ui) do
        obj.Visible = state
    end
end

-- apply a FOV value to the circle + UI
local function setFov(value)
    value = math.clamp(math.floor(value + 0.5), fovMin, fovMax)
    fovRadius = value
    fovCircle.Radius = value
    local pct = (fovMax ~= fovMin) and (value - fovMin) / (fovMax - fovMin) or 0
    ui.barFill.Size = Vector2.new(barW * pct, barH)
    ui.title.Text = "Aimbot FOV: " .. value
end

setUIVisible(UI_VISIBLE)
setFov(fovRadius)

-- slider drag handling (Drawing UI has no built-in input, so we hit-test the mouse)
local dragging = false

local function pointInBar(px, py)
    -- generous vertical tolerance so the thin bar is easy to grab
    return px >= barX and px <= barX + barW
        and py >= barY - 8 and py <= barY + barH + 8
end

local function updateFovFromMouse()
    local mx = uis:GetMouseLocation().X
    local pct = math.clamp((mx - barX) / barW, 0, 1)
    setFov(fovMin + pct * (fovMax - fovMin))
end

-- ==================== ESP ====================
local function hideESP(v)
    for _, obj in pairs(v) do
        obj.Visible = false
    end
end

local function createESP(player)
    if player == plr then return end
    if esp[player] then return end

    esp[player] = {
        Box = Drawing.new("Square"), BoxOutline = Drawing.new("Square"),
        Name = Drawing.new("Text"), Distance = Drawing.new("Text"),
        HealthBar = Drawing.new("Square"), HealthBarOutline = Drawing.new("Square"),
        Tracer = Drawing.new("Line"), HeadDot = Drawing.new("Circle")
    }

    local v = esp[player]
    v.Box.Thickness = 1.5; v.Box.Filled = false; v.Box.Color = Color3.fromRGB(255, 0, 0); v.Box.Transparency = 1
    v.BoxOutline.Thickness = 3; v.BoxOutline.Filled = false; v.BoxOutline.Color = Color3.fromRGB(0, 0, 0); v.BoxOutline.Transparency = 1

    v.Name.Size = 14; v.Name.Center = true; v.Name.Outline = true; v.Name.Color = Color3.fromRGB(255, 255, 255)
    v.Distance.Size = 13; v.Distance.Center = true; v.Distance.Outline = true; v.Distance.Color = Color3.fromRGB(200, 200, 200)

    v.HealthBar.Filled = true; v.HealthBar.Transparency = 1
    v.HealthBarOutline.Filled = true; v.HealthBarOutline.Color = Color3.fromRGB(0, 0, 0); v.HealthBarOutline.Transparency = 1

    v.Tracer.Thickness = 1.5; v.Tracer.Color = Color3.fromRGB(255, 0, 0); v.Tracer.Transparency = 0.7
    v.HeadDot.Radius = 2.5; v.HeadDot.Color = Color3.fromRGB(255, 0, 0); v.HeadDot.Filled = true

    hideESP(v)
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
    -- INSERT toggles the FOV panel even when the game is capturing input
    if input.KeyCode == Enum.KeyCode.Insert then
        setUIVisible(not UI_VISIBLE)
        return
    end
    if gpe then return end

    if input.UserInputType == Enum.UserInputType.MouseButton2 then
        rightHeld = true
    elseif input.UserInputType == Enum.UserInputType.MouseButton1 then
        if UI_VISIBLE then
            local m = uis:GetMouseLocation()
            if pointInBar(m.X, m.Y) then
                dragging = true
                updateFovFromMouse()
            end
        end
    end
end)

uis.InputEnded:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton2 then
        rightHeld = false
    elseif input.UserInputType == Enum.UserInputType.MouseButton1 then
        dragging = false
    end
end)

uis.InputChanged:Connect(function(input)
    if dragging and input.UserInputType == Enum.UserInputType.MouseMovement then
        updateFovFromMouse()
    end
end)

-- ==================== MAIN RENDER LOOP ====================
rs.RenderStepped:Connect(function()
    fovCircle.Position = Vector2.new(cam.ViewportSize.X / 2, cam.ViewportSize.Y / 2)

    -- Aimbot: aim only while right-click is held
    if rightHeld then
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
                    local distance = math.floor((cam.CFrame.Position - root.Position).Magnitude)

                    v.Box.Size = Vector2.new(width, height)
                    v.Box.Position = Vector2.new(rootPos.X - width / 2, topY)
                    v.Box.Visible = showBoxes

                    v.BoxOutline.Size = v.Box.Size
                    v.BoxOutline.Position = v.Box.Position
                    v.BoxOutline.Visible = showBoxes

                    v.Name.Text = player.Name
                    v.Name.Position = Vector2.new(rootPos.X, topY - 18)
                    v.Name.Visible = showNames

                    v.Distance.Text = distance .. "m"
                    v.Distance.Position = Vector2.new(rootPos.X, topY - 5)
                    v.Distance.Visible = showNames

                    local maxHp = humanoid.MaxHealth
                    local hpPct = (maxHp > 0) and math.clamp(humanoid.Health / maxHp, 0, 1) or 0
                    v.HealthBar.Size = Vector2.new(4, height * hpPct)
                    v.HealthBar.Position = Vector2.new(rootPos.X - width / 2 - 8, topY + height * (1 - hpPct))
                    v.HealthBar.Color = Color3.fromRGB(math.floor(255 * (1 - hpPct)), math.floor(255 * hpPct), 0)
                    v.HealthBar.Visible = showHealth

                    v.HealthBarOutline.Size = Vector2.new(6, height)
                    v.HealthBarOutline.Position = Vector2.new(rootPos.X - width / 2 - 9, topY)
                    v.HealthBarOutline.Visible = showHealth

                    v.HeadDot.Position = Vector2.new(headPos.X, headPos.Y)
                    v.HeadDot.Visible = showHeadDots

                    v.Tracer.From = Vector2.new(cam.ViewportSize.X / 2, cam.ViewportSize.Y)
                    v.Tracer.To = Vector2.new(rootPos.X, topY + height)
                    v.Tracer.Visible = showTracers
                end
            end

            if not rendered then
                hideESP(v)
            end
        end
    end
end)

print("Advanced Aimbot + ESP loaded! Hold RIGHT CLICK to aim. Press INSERT to show/hide the FOV panel.")
