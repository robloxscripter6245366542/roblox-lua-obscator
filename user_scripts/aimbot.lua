-- ============================================================
--  TORSO AIMBOT  (camera lock-on)
--
--  • Locks your camera onto the closest player's torso.
--  • Only locks when the target is INSIDE your FOV circle.
--    If they walk off your FOV, the lock releases automatically.
--  • Works regardless of which way the target is facing
--    (still locks when you're behind them).
--  • Small draggable UI: turn it On/Off and change the FOV.
--
--  Hold the aim key (default: Right Mouse Button) to lock,
--  or flip "Always Lock" in the UI to lock without holding.
-- ============================================================

local Players            = game:GetService("Players")
local RunService         = game:GetService("RunService")
local UserInputService   = game:GetService("UserInputService")
local Workspace          = game:GetService("Workspace")

local LocalPlayer = Players.LocalPlayer
local Camera      = Workspace.CurrentCamera

-- ============================================================
-- CONFIG
-- ============================================================
local Config = {
    Enabled      = false,             -- master on/off
    FOV          = 120,               -- radius in pixels; target must be inside to lock
    AlwaysLock   = false,             -- true = lock without holding the aim key
    AimKey       = Enum.UserInputType.MouseButton2,  -- hold to aim (Right Mouse)
    TeamCheck    = true,              -- don't target your own team
    WallCheck    = false,             -- require line of sight to torso
    Smoothness   = 0.35,              -- 0 = instant snap, 1 = very slow follow
    ShowFOV      = true,              -- draw the FOV circle
    TorsoNames   = { "UpperTorso", "Torso", "HumanoidRootPart" }, -- try in order
}

-- ============================================================
-- HELPERS
-- ============================================================

-- Return the first existing torso-like part on a character.
local function getTorso(character)
    for _, name in ipairs(Config.TorsoNames) do
        local part = character:FindFirstChild(name)
        if part then return part end
    end
    return nil
end

-- Is this player a valid, alive target?
local function isValidTarget(player)
    if player == LocalPlayer then return false end
    local character = player.Character
    if not character then return false end
    local humanoid = character:FindFirstChildOfClass("Humanoid")
    if not humanoid or humanoid.Health <= 0 then return false end
    if not getTorso(character) then return false end
    if Config.TeamCheck and player.Team and LocalPlayer.Team then
        if player.Team == LocalPlayer.Team then return false end
    end
    return true
end

-- Line-of-sight check: is the torso visible (not behind a wall)?
local function hasLineOfSight(torso, character)
    if not Config.WallCheck then return true end
    local origin = Camera.CFrame.Position
    local dir = (torso.Position - origin)
    local params = RaycastParams.new()
    params.FilterType = Enum.RaycastFilterType.Exclude
    params.FilterDescendantsInstances = { LocalPlayer.Character }
    local result = Workspace:Raycast(origin, dir, params)
    if not result then return true end
    return result.Instance:IsDescendantOf(character)
end

-- Find the target whose torso is closest to the screen center AND inside the FOV.
-- Returns torso part or nil. "Off the FOV" -> returns nil (no lock).
local function getClosestTorsoInFOV()
    local closestTorso   = nil
    local closestDelta   = Config.FOV        -- must be within FOV radius to qualify
    local screenCenter   = Vector2.new(Camera.ViewportSize.X / 2, Camera.ViewportSize.Y / 2)

    for _, player in ipairs(Players:GetPlayers()) do
        if isValidTarget(player) then
            local character = player.Character
            local torso     = getTorso(character)
            local screenPos, onScreen = Camera:WorldToViewportPoint(torso.Position)
            if onScreen then
                local delta = (Vector2.new(screenPos.X, screenPos.Y) - screenCenter).Magnitude
                if delta < closestDelta and hasLineOfSight(torso, character) then
                    closestDelta = delta
                    closestTorso = torso
                end
            end
        end
    end
    return closestTorso
end

-- ============================================================
-- FOV CIRCLE (Drawing API; degrades gracefully if unavailable)
-- ============================================================
local fovCircle
local hasDrawing = (typeof(Drawing) == "table") or (Drawing ~= nil)
if hasDrawing then
    local ok, circle = pcall(function()
        local c = Drawing.new("Circle")
        c.Thickness   = 2
        c.NumSides    = 64
        c.Radius      = Config.FOV
        c.Filled      = false
        c.Visible     = false
        c.Color       = Color3.fromRGB(255, 255, 255)
        c.Transparency = 1
        return c
    end)
    if ok then fovCircle = circle end
end

local function updateFOVCircle()
    if not fovCircle then return end
    fovCircle.Radius  = Config.FOV
    fovCircle.Visible = Config.Enabled and Config.ShowFOV
    fovCircle.Position = Vector2.new(Camera.ViewportSize.X / 2, Camera.ViewportSize.Y / 2)
end

-- ============================================================
-- AIM LOOP
-- ============================================================
local aimKeyDown = false

UserInputService.InputBegan:Connect(function(input, gpe)
    if gpe then return end
    if input.UserInputType == Config.AimKey then aimKeyDown = true end
end)
UserInputService.InputEnded:Connect(function(input)
    if input.UserInputType == Config.AimKey then aimKeyDown = false end
end)

local currentTorso = nil

RunService.RenderStepped:Connect(function()
    Camera = Workspace.CurrentCamera
    updateFOVCircle()

    if not Config.Enabled then currentTorso = nil; return end
    local shouldAim = Config.AlwaysLock or aimKeyDown
    if not shouldAim then currentTorso = nil; return end

    -- Re-pick the closest in-FOV target every frame; drop lock if none in FOV.
    currentTorso = getClosestTorsoInFOV()
    if not currentTorso then return end

    local camPos = Camera.CFrame.Position
    local goalCFrame = CFrame.new(camPos, currentTorso.Position)

    if Config.Smoothness > 0 then
        -- Lerp toward the target for a smoother, less robotic snap.
        local alpha = 1 - math.clamp(Config.Smoothness, 0, 0.99)
        Camera.CFrame = Camera.CFrame:Lerp(goalCFrame, alpha)
    else
        Camera.CFrame = goalCFrame
    end
end)

-- ============================================================
-- UI  (self-contained ScreenGui, draggable)
-- ============================================================
local function makeUI()
    local gui = Instance.new("ScreenGui")
    gui.Name = "TorsoAimbotUI"
    gui.ResetOnSpawn = false
    gui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
    -- Prefer CoreGui so it survives respawns / character reloads
    local parent = game:GetService("CoreGui")
    local okParent = pcall(function()
        if syn and syn.protect_gui then syn.protect_gui(gui) end
        if gethui then parent = gethui() end
        gui.Parent = parent
    end)
    if not okParent then gui.Parent = LocalPlayer:WaitForChild("PlayerGui") end

    local frame = Instance.new("Frame")
    frame.Size = UDim2.new(0, 230, 0, 150)
    frame.Position = UDim2.new(0, 40, 0, 200)
    frame.BackgroundColor3 = Color3.fromRGB(25, 25, 30)
    frame.BorderSizePixel = 0
    frame.Active = true
    frame.Draggable = true
    frame.Parent = gui
    local corner = Instance.new("UICorner"); corner.CornerRadius = UDim.new(0, 8); corner.Parent = frame

    local title = Instance.new("TextLabel")
    title.Size = UDim2.new(1, 0, 0, 32)
    title.BackgroundColor3 = Color3.fromRGB(35, 35, 42)
    title.BorderSizePixel = 0
    title.Text = "  🎯 Torso Aimbot"
    title.TextColor3 = Color3.fromRGB(255, 255, 255)
    title.Font = Enum.Font.GothamBold
    title.TextSize = 15
    title.TextXAlignment = Enum.TextXAlignment.Left
    title.Parent = frame
    local tcorner = Instance.new("UICorner"); tcorner.CornerRadius = UDim.new(0, 8); tcorner.Parent = title

    -- Toggle button
    local toggle = Instance.new("TextButton")
    toggle.Size = UDim2.new(1, -20, 0, 34)
    toggle.Position = UDim2.new(0, 10, 0, 42)
    toggle.BackgroundColor3 = Color3.fromRGB(180, 50, 50)
    toggle.Text = "OFF"
    toggle.TextColor3 = Color3.fromRGB(255, 255, 255)
    toggle.Font = Enum.Font.GothamBold
    toggle.TextSize = 14
    toggle.BorderSizePixel = 0
    toggle.Parent = frame
    local bcorner = Instance.new("UICorner"); bcorner.CornerRadius = UDim.new(0, 6); bcorner.Parent = toggle

    toggle.MouseButton1Click:Connect(function()
        Config.Enabled = not Config.Enabled
        toggle.Text = Config.Enabled and "ON" or "OFF"
        toggle.BackgroundColor3 = Config.Enabled
            and Color3.fromRGB(50, 170, 80) or Color3.fromRGB(180, 50, 50)
    end)

    -- FOV label
    local fovLabel = Instance.new("TextLabel")
    fovLabel.Size = UDim2.new(1, -20, 0, 18)
    fovLabel.Position = UDim2.new(0, 10, 0, 84)
    fovLabel.BackgroundTransparency = 1
    fovLabel.Text = "FOV: " .. Config.FOV
    fovLabel.TextColor3 = Color3.fromRGB(220, 220, 220)
    fovLabel.Font = Enum.Font.Gotham
    fovLabel.TextSize = 13
    fovLabel.TextXAlignment = Enum.TextXAlignment.Left
    fovLabel.Parent = frame

    -- FOV slider track
    local track = Instance.new("Frame")
    track.Size = UDim2.new(1, -20, 0, 8)
    track.Position = UDim2.new(0, 10, 0, 110)
    track.BackgroundColor3 = Color3.fromRGB(60, 60, 70)
    track.BorderSizePixel = 0
    track.Parent = frame
    local trcorner = Instance.new("UICorner"); trcorner.CornerRadius = UDim.new(1, 0); trcorner.Parent = track

    local fill = Instance.new("Frame")
    fill.BackgroundColor3 = Color3.fromRGB(90, 140, 255)
    fill.BorderSizePixel = 0
    fill.Parent = track
    local flcorner = Instance.new("UICorner"); flcorner.CornerRadius = UDim.new(1, 0); flcorner.Parent = fill

    local knob = Instance.new("Frame")
    knob.Size = UDim2.new(0, 14, 0, 14)
    knob.AnchorPoint = Vector2.new(0.5, 0.5)
    knob.Position = UDim2.new(0, 0, 0.5, 0)
    knob.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
    knob.BorderSizePixel = 0
    knob.ZIndex = 2
    knob.Parent = track
    local kcorner = Instance.new("UICorner"); kcorner.CornerRadius = UDim.new(1, 0); kcorner.Parent = knob

    local FOV_MIN, FOV_MAX = 20, 500
    local function setFOVFromScale(scale)
        scale = math.clamp(scale, 0, 1)
        Config.FOV = math.floor(FOV_MIN + (FOV_MAX - FOV_MIN) * scale + 0.5)
        fovLabel.Text = "FOV: " .. Config.FOV
        fill.Size = UDim2.new(scale, 0, 1, 0)
        knob.Position = UDim2.new(scale, 0, 0.5, 0)
    end
    setFOVFromScale((Config.FOV - FOV_MIN) / (FOV_MAX - FOV_MIN))

    local dragging = false
    local function updateFromInput(input)
        local rel = (input.Position.X - track.AbsolutePosition.X) / track.AbsoluteSize.X
        setFOVFromScale(rel)
    end
    track.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1
        or input.UserInputType == Enum.UserInputType.Touch then
            dragging = true; updateFromInput(input)
        end
    end)
    knob.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1
        or input.UserInputType == Enum.UserInputType.Touch then
            dragging = true
        end
    end)
    UserInputService.InputChanged:Connect(function(input)
        if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement
                      or input.UserInputType == Enum.UserInputType.Touch) then
            updateFromInput(input)
        end
    end)
    UserInputService.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1
        or input.UserInputType == Enum.UserInputType.Touch then
            dragging = false
        end
    end)

    -- Always-Lock toggle (small)
    local alwaysBtn = Instance.new("TextButton")
    alwaysBtn.Size = UDim2.new(1, -20, 0, 22)
    alwaysBtn.Position = UDim2.new(0, 10, 0, 124)
    alwaysBtn.BackgroundColor3 = Color3.fromRGB(45, 45, 55)
    alwaysBtn.Text = "Always Lock: OFF  (hold RMB)"
    alwaysBtn.TextColor3 = Color3.fromRGB(210, 210, 210)
    alwaysBtn.Font = Enum.Font.Gotham
    alwaysBtn.TextSize = 12
    alwaysBtn.BorderSizePixel = 0
    alwaysBtn.Parent = frame
    local acorner = Instance.new("UICorner"); acorner.CornerRadius = UDim.new(0, 6); acorner.Parent = alwaysBtn
    alwaysBtn.MouseButton1Click:Connect(function()
        Config.AlwaysLock = not Config.AlwaysLock
        alwaysBtn.Text = Config.AlwaysLock and "Always Lock: ON" or "Always Lock: OFF  (hold RMB)"
    end)

    -- grow the frame to fit the always-lock row
    frame.Size = UDim2.new(0, 230, 0, 158)
end

pcall(makeUI)

warn("[Torso Aimbot] Loaded. Toggle it in the UI, hold Right-Mouse to lock (or enable Always Lock).")
