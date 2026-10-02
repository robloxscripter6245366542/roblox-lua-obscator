--!nocheck
-- ============================================================================
--  Universal Aimbot  —  Smooth Aim Lock + Team-Colored ESP
-- ----------------------------------------------------------------------------
--  ESP
--  * Outlines EVERY player's body using Roblox Highlight instances
--    (works on any character rig — R6, R15, custom).
--  * Colour = each player's own team; players with no team get a fallback.
--  * Re-evaluates live, so it keeps working after respawns / team switches.
--
--  AIMBOT (extracted from HBSS and reworked)
--  * Locks onto the enemy closest to your crosshair inside the FOV circle.
--  * Smooth, frame-rate independent lock: it eases the camera toward the
--    target instead of snapping every frame, and backs off while YOU are
--    moving the camera, so you can still look around / drag off a target.
--  * Skips teammates, dead players and (optionally) players behind walls.
--
--  One draggable panel (PC + mobile) turns everything on and off.
--  Drop this into any executor and run. No Drawing API required.
-- ============================================================================

local Players          = game:GetService("Players")
local RunService       = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local Workspace        = game:GetService("Workspace")

local LocalPlayer = Players.LocalPlayer

-- Re-running the script used to stack a second UI + second set of loops on
-- top of the first. Shut the previous instance down first.
if typeof(getgenv) == "function" then
    local old = getgenv().UniversalESP
    if type(old) == "table" and type(old.Stop) == "function" then
        pcall(old.Stop)
    end
end

-- ==================== CONFIG ====================
local CONFIG = {
    -- ESP
    Enabled          = true,
    UseTeamColor     = true,                        -- outline uses each player's TeamColor
    NoTeamColor      = Color3.fromRGB(255, 0, 0),   -- red highlight for players with no team
    FillTransparency = 0.75,                        -- 1 = outline only, lower = more fill
    OutlineTransparency = 0,
    MaxDistance      = 0,                           -- 0 = unlimited, else studs from you

    -- Aimbot
    AimEnabled       = false,
    AimPart          = "Head",       -- "Head", "HumanoidRootPart" or "Torso"
    AimFOV           = 120,          -- radius (pixels) of the lock circle
    AimRange         = 1000,         -- max studs to a target
    AimWallCheck     = true,         -- ignore players behind walls
    AimTeamCheck     = true,         -- ignore teammates (same non-nil Team)
    AimPrediction    = 0,            -- seconds of velocity lead (0 = off, max 0.5)
    AimStrength      = "Strong",     -- key into AIM_PRESETS
    AimUserYield     = 0.5,          -- lock strength multiplier while you move the camera
    AimUserYieldTime = 0.25,         -- seconds after your last camera input to keep yielding
    AimDeadzone      = 0.0015,       -- radians; stop nudging when already on target (no jitter)
    ShowFOV          = true,
    FOVColor         = Color3.fromRGB(255, 255, 255),
    FOVLockedColor   = Color3.fromRGB(255, 220, 60),
}

-- How fast the camera eases onto the target (per second). The original HBSS
-- lock lerped 50% of the way every tick at 100 Hz (~69/s, basically a snap),
-- which is why it fought you so hard. "Max" is close to that; the rest ease in.
local AIM_PRESETS = { "Soft", "Medium", "Strong", "Max" }
local AIM_SPEED   = { Soft = 10, Medium = 18, Strong = 30, Max = 60 }

-- ==================== STATE ====================
-- NOTE: Roblox only renders ~31 Highlight instances at once. In a very busy
-- server the extra players' outlines may silently not draw.
local highlights  = {}   -- [player] = Highlight
local connections = {}   -- every connection we make, so Stop() can undo it
local running     = true

local RENDER_NAME = "UniversalESP_Aimbot"
local aimTarget   = nil  -- Player currently locked
local lastUserAim = -math.huge -- os.clock() of the last camera input from the user

local function track(conn)
    table.insert(connections, conn)
    return conn
end

-- ==================== SHARED HELPERS ====================

-- A part we can adorn to / distance-check against. Not every character has a
-- Humanoid the instant it spawns (or at all, for custom rigs), so we fall back
-- through PrimaryPart -> HumanoidRootPart -> Head -> any BasePart.
local function getRootPart(character)
    return character.PrimaryPart
        or character:FindFirstChild("HumanoidRootPart")
        or character:FindFirstChild("Head")
        or character:FindFirstChildWhichIsA("BasePart")
end

-- ==================== ESP ====================

-- Highlight everyone except yourself; each is coloured by their own team.
local function isTarget(player)
    return player ~= LocalPlayer
end

-- Colour to use for a player's outline: their team colour, or the no-team
-- fallback. (player.Team is nil for neutral / unassigned players.)
local function colorFor(player)
    if CONFIG.UseTeamColor and player.Team then
        return player.TeamColor.Color
    end
    return CONFIG.NoTeamColor
end

local function withinRange(character)
    if CONFIG.MaxDistance <= 0 then return true end
    local myChar = LocalPlayer.Character
    local myRoot = myChar and getRootPart(myChar)
    local root   = getRootPart(character)
    if not (myRoot and root) then return true end
    return (myRoot.Position - root.Position).Magnitude <= CONFIG.MaxDistance
end

local function removeHighlight(player)
    local h = highlights[player]
    if h then
        h:Destroy()
        highlights[player] = nil
    end
end

local function ensureHighlight(player, character, col)
    local h = highlights[player]
    -- Recreate if missing, destroyed, or now on a new (respawned) character.
    if not h or h.Parent ~= character then
        removeHighlight(player)
        h = Instance.new("Highlight")
        h.Name = "UniversalESP"
        h.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop -- see through walls
        h.Adornee = character
        h.Parent  = character
        highlights[player] = h
    end

    h.FillColor          = col
    h.OutlineColor       = col
    h.FillTransparency   = CONFIG.FillTransparency
    h.OutlineTransparency = CONFIG.OutlineTransparency
end

local function refreshESP()
    for _, player in ipairs(Players:GetPlayers()) do
        local character = player.Character
        if CONFIG.Enabled
            and isTarget(player)
            and character
            and getRootPart(character)   -- something we can actually adorn
            and withinRange(character)
        then
            ensureHighlight(player, character, colorFor(player))
        else
            removeHighlight(player)
        end
    end
end

track(RunService.Heartbeat:Connect(function()
    if not running then return end
    refreshESP()
end))

-- ==================== AIMBOT ====================

local function getAliveHumanoid(character)
    local hum = character and character:FindFirstChildOfClass("Humanoid")
    if hum and hum.Health > 0 then return hum end
    return nil
end

local function isTeammate(player)
    -- Only a teammate if BOTH are on the same real team. No-team players (and
    -- everyone, when you have no team) are always valid targets.
    local myTeam = LocalPlayer.Team
    return myTeam ~= nil and player.Team == myTeam
end

local function getAimPart(character)
    local name = CONFIG.AimPart
    local part
    if name == "Torso" then
        part = character:FindFirstChild("UpperTorso") or character:FindFirstChild("Torso")
    else
        part = character:FindFirstChild(name)
    end
    -- Fall back so custom rigs without a "Head" still get targeted.
    return part
        or character:FindFirstChild("Head")
        or character:FindFirstChild("HumanoidRootPart")
        or getRootPart(character)
end

local rayParams = RaycastParams.new()
rayParams.FilterType  = Enum.RaycastFilterType.Exclude
rayParams.IgnoreWater = true

-- True when nothing solid sits between the camera and the target part. Skips
-- glass / invisible parts (up to a few) instead of treating them as walls,
-- and ignores your own character and the target's accessories.
local function isVisible(origin, part, targetChar)
    if not CONFIG.AimWallCheck then return true end
    local ignore = { targetChar }
    if LocalPlayer.Character then table.insert(ignore, LocalPlayer.Character) end
    local cam = Workspace.CurrentCamera
    if cam then table.insert(ignore, cam) end

    local dir = part.Position - origin
    for _ = 1, 4 do
        rayParams.FilterDescendantsInstances = ignore
        local hit = Workspace:Raycast(origin, dir, rayParams)
        if not hit then return true end
        local inst = hit.Instance
        if inst.Transparency < 0.9 and inst.CanCollide then
            return false
        end
        table.insert(ignore, inst)   -- see-through / non-collide: look past it
    end
    return true
end

local function predictedPosition(part)
    local lead = math.clamp(tonumber(CONFIG.AimPrediction) or 0, 0, 0.5)
    if lead <= 0 then return part.Position end
    local ok, vel = pcall(function() return part.AssemblyLinearVelocity end)
    if not ok or typeof(vel) ~= "Vector3" then return part.Position end
    return part.Position + vel * lead
end

-- Checks one player and returns (part, screenDistancePx) if they're a valid
-- target inside `fov` pixels of the screen centre, else nil.
local function evaluate(player, cam, center, fov)
    if player == LocalPlayer then return nil end
    if CONFIG.AimTeamCheck and isTeammate(player) then return nil end
    local char = player.Character
    if not char or not getAliveHumanoid(char) then return nil end
    if char:FindFirstChildOfClass("ForceField") then return nil end

    local part = getAimPart(char)
    if not part then return nil end

    local camPos = cam.CFrame.Position
    if (part.Position - camPos).Magnitude > CONFIG.AimRange then return nil end

    local screen, onScreen = cam:WorldToViewportPoint(part.Position)
    if not onScreen or screen.Z <= 0 then return nil end
    local dist = (Vector2.new(screen.X, screen.Y) - center).Magnitude
    if dist > fov then return nil end

    if not isVisible(camPos, part, char) then return nil end
    return part, dist
end

-- Picks the target CLOSEST TO THE CROSSHAIR (the original picked closest in
-- world distance, which kept yanking you onto whoever was nearest even if you
-- were looking at someone else). The current lock is kept while it stays in a
-- slightly larger circle so it doesn't flicker between two close players.
local function pickTarget(cam)
    local vp = cam.ViewportSize
    local center = Vector2.new(vp.X / 2, vp.Y / 2)

    if aimTarget and aimTarget.Parent == Players then
        local part = evaluate(aimTarget, cam, center, CONFIG.AimFOV * 1.25)
        if part then return aimTarget, part end
    end

    local bestPlayer, bestPart, bestDist = nil, nil, math.huge
    for _, player in ipairs(Players:GetPlayers()) do
        local part, dist = evaluate(player, cam, center, CONFIG.AimFOV)
        if part and dist < bestDist then
            bestPlayer, bestPart, bestDist = player, part, dist
        end
    end
    return bestPlayer, bestPart
end

-- Mark that the user is turning the camera themselves, so the lock eases off.
track(UserInputService.InputChanged:Connect(function(input, processed)
    local t = input.UserInputType
    if t == Enum.UserInputType.MouseMovement then
        -- Mouse only turns the camera when it's locked (first person /
        -- shift-lock) or while right mouse is held.
        local locked = UserInputService.MouseBehavior ~= Enum.MouseBehavior.Default
        local rmb = UserInputService:IsMouseButtonPressed(Enum.UserInputType.MouseButton2)
        if (locked or rmb) and input.Delta.Magnitude > 0.5 then
            lastUserAim = os.clock()
        end
    elseif t == Enum.UserInputType.Touch then
        -- Touches that began on UI (joystick, buttons, our panel) are
        -- `processed`; anything else is a camera swipe.
        if not processed then lastUserAim = os.clock() end
    elseif t == Enum.UserInputType.Gamepad1 and input.KeyCode == Enum.KeyCode.Thumbstick2 then
        if input.Position.Magnitude > 0.2 then lastUserAim = os.clock() end
    end
end))

local onTargetChanged -- set by the UI

local function setAimTarget(player)
    if aimTarget ~= player then
        aimTarget = player
        if onTargetChanged then onTargetChanged(player) end
    end
end

local function aimStep(dt)
    if not running or not CONFIG.AimEnabled then
        setAimTarget(nil)
        return
    end
    local cam = Workspace.CurrentCamera
    if not cam then return end
    if not getAliveHumanoid(LocalPlayer.Character) then
        setAimTarget(nil)
        return
    end

    local player, part = pickTarget(cam)
    setAimTarget(player)
    if not part then return end

    local camCF   = cam.CFrame
    local camPos  = camCF.Position
    local offset  = predictedPosition(part) - camPos
    if offset.Magnitude < 0.5 then return end
    local wantDir = offset.Unit
    local curDir  = camCF.LookVector

    -- Already on target: don't touch the camera (prevents micro-jitter).
    local dot = math.clamp(curDir:Dot(wantDir), -1, 1)
    if math.acos(dot) < CONFIG.AimDeadzone then return end

    -- Exponential ease: same feel at 30 fps or 240 fps.
    local speed = AIM_SPEED[CONFIG.AimStrength] or AIM_SPEED.Strong
    local alpha = 1 - math.exp(-speed * math.min(dt, 0.1))
    if os.clock() - lastUserAim < CONFIG.AimUserYieldTime then
        alpha = alpha * CONFIG.AimUserYield
    end

    local newDir = curDir:Lerp(wantDir, alpha)
    if newDir.Magnitude < 1e-3 then return end
    newDir = newDir.Unit
    -- CFrame.lookAt breaks when looking straight up/down; skip that frame.
    if math.abs(newDir.Y) > 0.995 then return end
    cam.CFrame = CFrame.lookAt(camPos, camPos + newDir)
end

-- Run right AFTER the default camera script so your own input for the frame is
-- applied first and we only nudge on top of it (instead of overwriting it).
RunService:BindToRenderStep(RENDER_NAME, Enum.RenderPriority.Camera.Value + 1, aimStep)

-- Clean up when a player leaves.
track(Players.PlayerRemoving:Connect(function(player)
    removeHighlight(player)
    if aimTarget == player then setAimTarget(nil) end
end))

-- ==================== PUBLIC API ====================
-- Optional global so you can flip things from the console: getgenv().UniversalESP
local refreshUI -- set by the UI below
local gui

local api = { Config = CONFIG }

function api.Toggle()
    CONFIG.Enabled = not CONFIG.Enabled
    if refreshUI then refreshUI() end
    return CONFIG.Enabled
end

function api.ToggleAimbot()
    CONFIG.AimEnabled = not CONFIG.AimEnabled
    if not CONFIG.AimEnabled then setAimTarget(nil) end
    if refreshUI then refreshUI() end
    return CONFIG.AimEnabled
end

function api.ToggleWallCheck()
    CONFIG.AimWallCheck = not CONFIG.AimWallCheck
    if refreshUI then refreshUI() end
    return CONFIG.AimWallCheck
end

function api.CycleStrength()
    local idx = table.find(AIM_PRESETS, CONFIG.AimStrength) or 3
    CONFIG.AimStrength = AIM_PRESETS[idx % #AIM_PRESETS + 1]
    if refreshUI then refreshUI() end
    return CONFIG.AimStrength
end

function api.Stop()
    if not running then return end
    running = false
    CONFIG.Enabled = false
    CONFIG.AimEnabled = false
    pcall(function() RunService:UnbindFromRenderStep(RENDER_NAME) end)
    for _, c in ipairs(connections) do
        pcall(function() c:Disconnect() end)
    end
    table.clear(connections)
    for player in pairs(highlights) do
        removeHighlight(player)
    end
    aimTarget = nil
    if gui then gui:Destroy() end
end

if typeof(getgenv) == "function" then
    getgenv().UniversalESP = api
    getgenv().UniversalAimbot = api
end

-- ==================== UI: ONE DRAGGABLE PANEL ====================
-- Drag it by the title bar (mouse or touch). Tap a row to toggle it.
-- "–" collapses the panel to just the title bar.
local ON_COLOR   = Color3.fromRGB(70, 200, 120)
local OFF_COLOR  = Color3.fromRGB(90, 95, 110)
local BG_COLOR   = Color3.fromRGB(24, 26, 32)
local ROW_COLOR  = Color3.fromRGB(36, 39, 48)
local TEXT_COLOR = Color3.fromRGB(255, 255, 255)

local function getGuiParent()
    -- prefer a hidden container if the executor exposes one, else PlayerGui
    local ok, hui = pcall(function() return gethui() end)
    if ok and hui then return hui end
    return LocalPlayer:WaitForChild("PlayerGui")
end

local function corner(parent, radius)
    local c = Instance.new("UICorner")
    c.CornerRadius = radius or UDim.new(0, 10)
    c.Parent = parent
    return c
end

gui = Instance.new("ScreenGui")
gui.Name = "UniversalESP_UI"
gui.ResetOnSpawn = false
gui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
gui.DisplayOrder = 10000
-- IgnoreGuiInset makes (0.5, 0.5) the true viewport centre, so the FOV circle
-- lines up with what the aimbot measures (HBSS hard-coded a -28px offset).
gui.IgnoreGuiInset = true
gui.Parent = getGuiParent()

-- ---- FOV circle ----
local fovRing = Instance.new("Frame")
fovRing.Name = "FOV"
fovRing.AnchorPoint = Vector2.new(0.5, 0.5)
fovRing.Position = UDim2.fromScale(0.5, 0.5)
fovRing.BackgroundTransparency = 1
fovRing.Active = false
fovRing.Parent = gui
corner(fovRing, UDim.new(1, 0))
local fovStroke = Instance.new("UIStroke")
fovStroke.Thickness = 1.5
fovStroke.Transparency = 0.35
fovStroke.Color = CONFIG.FOVColor
fovStroke.Parent = fovRing

onTargetChanged = function(player)
    fovStroke.Color = player and CONFIG.FOVLockedColor or CONFIG.FOVColor
end

-- ---- panel ----
local PANEL_W, TITLE_H, ROW_H, PAD = 190, 34, 36, 8

local panel = Instance.new("Frame")
panel.Name = "Panel"
panel.Position = UDim2.new(0, 20, 0.3, 0)
panel.BackgroundColor3 = BG_COLOR
panel.BorderSizePixel = 0
panel.ClipsDescendants = true
panel.Parent = gui
corner(panel, UDim.new(0, 12))
local panelStroke = Instance.new("UIStroke")
panelStroke.Thickness = 1.5
panelStroke.Color = Color3.fromRGB(255, 255, 255)
panelStroke.Transparency = 0.8
panelStroke.Parent = panel

local title = Instance.new("TextButton")
title.Name = "Title"
title.Size = UDim2.new(1, 0, 0, TITLE_H)
title.BackgroundTransparency = 1
title.AutoButtonColor = false
title.Text = "  Universal Aimbot"
title.TextXAlignment = Enum.TextXAlignment.Left
title.Font = Enum.Font.GothamBold
title.TextSize = 15
title.TextColor3 = TEXT_COLOR
title.Parent = panel

local minBtn = Instance.new("TextButton")
minBtn.Name = "Minimize"
minBtn.AnchorPoint = Vector2.new(1, 0.5)
minBtn.Position = UDim2.new(1, -6, 0, TITLE_H / 2)
minBtn.Size = UDim2.fromOffset(26, 22)
minBtn.BackgroundColor3 = ROW_COLOR
minBtn.AutoButtonColor = true
minBtn.Text = "–"
minBtn.Font = Enum.Font.GothamBold
minBtn.TextSize = 16
minBtn.TextColor3 = TEXT_COLOR
minBtn.ZIndex = 2
minBtn.Parent = panel
corner(minBtn, UDim.new(0, 6))

local rows = {}
local function makeRow(index, text, onTap)
    local row = Instance.new("TextButton")
    row.Name = text
    row.Position = UDim2.new(0, PAD, 0, TITLE_H + (index - 1) * (ROW_H + 6))
    row.Size = UDim2.new(1, -PAD * 2, 0, ROW_H)
    row.BackgroundColor3 = ROW_COLOR
    row.AutoButtonColor = false
    row.Text = ""
    row.Parent = panel
    corner(row, UDim.new(0, 8))

    local lbl = Instance.new("TextLabel")
    lbl.BackgroundTransparency = 1
    lbl.Position = UDim2.new(0, 10, 0, 0)
    lbl.Size = UDim2.new(1, -80, 1, 0)
    lbl.Font = Enum.Font.GothamSemibold
    lbl.TextSize = 14
    lbl.TextXAlignment = Enum.TextXAlignment.Left
    lbl.TextColor3 = TEXT_COLOR
    lbl.Text = text
    lbl.Parent = row

    local pill = Instance.new("TextLabel")
    pill.AnchorPoint = Vector2.new(1, 0.5)
    pill.Position = UDim2.new(1, -8, 0.5, 0)
    pill.Size = UDim2.fromOffset(62, 24)
    pill.BorderSizePixel = 0
    pill.Font = Enum.Font.GothamBold
    pill.TextSize = 13
    pill.TextColor3 = TEXT_COLOR
    pill.Parent = row
    corner(pill, UDim.new(1, 0))

    row.Activated:Connect(onTap)
    rows[index] = pill
    return pill
end

local espPill    = makeRow(1, "ESP",        api.Toggle)
local aimPill    = makeRow(2, "Aimbot",     api.ToggleAimbot)
local wallPill   = makeRow(3, "Wall Check", api.ToggleWallCheck)
local lockPill   = makeRow(4, "Lock",       api.CycleStrength)

local EXPANDED_H = TITLE_H + #rows * (ROW_H + 6) + PAD - 6
local collapsed  = false

local function setPill(pill, on)
    pill.BackgroundColor3 = on and ON_COLOR or OFF_COLOR
    pill.Text = on and "ON" or "OFF"
end

refreshUI = function()
    setPill(espPill,  CONFIG.Enabled)
    setPill(aimPill,  CONFIG.AimEnabled)
    setPill(wallPill, CONFIG.AimWallCheck)
    lockPill.BackgroundColor3 = Color3.fromRGB(80, 120, 220)
    lockPill.Text = CONFIG.AimStrength

    fovRing.Size = UDim2.fromOffset(CONFIG.AimFOV * 2, CONFIG.AimFOV * 2)
    fovRing.Visible = CONFIG.AimEnabled and CONFIG.ShowFOV

    panel.Size = UDim2.fromOffset(PANEL_W, collapsed and TITLE_H or EXPANDED_H)
    minBtn.Text = collapsed and "+" or "–"
end
refreshUI()
api.RefreshUI = refreshUI

minBtn.Activated:Connect(function()
    collapsed = not collapsed
    refreshUI()
end)

-- ---- drag handling (mouse and touch) ----
local dragging  = false
local dragInput  -- the specific input (finger) doing the drag
local dragStart  -- Vector2 of the pointer when the press began
local startPos   -- UDim2 of the panel when the press began

title.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1
        or input.UserInputType == Enum.UserInputType.Touch then
        dragging  = true
        dragInput = input
        dragStart = input.Position
        startPos  = panel.Position
    end
end)

track(UserInputService.InputChanged:Connect(function(input)
    if not dragging then return end
    local t = input.UserInputType
    -- Only follow the finger that started the drag, so a second finger
    -- turning the camera doesn't drag the panel around.
    if t == Enum.UserInputType.MouseMovement
        or (t == Enum.UserInputType.Touch and input == dragInput) then
        local delta = input.Position - dragStart
        panel.Position = UDim2.new(
            startPos.X.Scale, startPos.X.Offset + delta.X,
            startPos.Y.Scale, startPos.Y.Offset + delta.Y
        )
    end
end))

-- Listen on UserInputService (not the title) so releasing the pointer off the
-- panel still ends the drag instead of leaving it stuck to the cursor.
track(UserInputService.InputEnded:Connect(function(input)
    if not dragging then return end
    local t = input.UserInputType
    if t == Enum.UserInputType.MouseButton1
        or (t == Enum.UserInputType.Touch and input == dragInput) then
        dragging  = false
        dragInput = nil
    end
end))

return api
