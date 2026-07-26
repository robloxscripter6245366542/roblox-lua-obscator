-- Cam Lock (auto aim-assist camera lock)
--
-- What it does:
--   * "Look-to-lock": while your camera is pointed near a player, it automatically
--     acquires them and locks your camera onto them. You don't press anything to
--     lock — just aim near someone and the camera snaps/eases onto their target
--     part and tracks them as they (and you) move.
--   * Picks the player whose character is *closest to the center of your screen*
--     (i.e. closest to where you're looking), inside a configurable field-of-view
--     cone. Ties never happen because it compares pixel distance to crosshair.
--   * Once locked it "sticks": it keeps tracking that target even if you drift a
--     bit, and only releases when the target dies, leaves, goes out of range,
--     goes fully behind you / far off screen, or (optionally) breaks line of sight.
--
-- Controls (see keybinds in the config below):
--   * TOGGLE_KEY  — turn the whole cam lock feature on/off.
--   * UNLOCK_KEY  — force-release the current target (it can re-acquire after).
--   * A held "hold to disable" key is also supported so you can freely look around.
--
-- Notes:
--   * Uses the default camera. It only rotates the camera to face the target; it
--     does not teleport you or touch your character, so it's a camera aim-assist.
--   * Smoothing is configurable: 1 = instant snap, lower = smoother/laggier ease.
--   * Handles respawns (yours and the target's) and players leaving cleanly.

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local Workspace = game:GetService("Workspace")

local LocalPlayer = Players.LocalPlayer
local Camera = Workspace.CurrentCamera

-- ==== Config ======================================================
local CONFIG = {
	ENABLED = true, -- master switch (also toggled by TOGGLE_KEY)

	-- Field-of-view cones, measured in screen pixels from the crosshair (center).
	-- Bigger = easier to acquire but less selective.
	ACQUIRE_FOV = 140, -- must aim this close (px) to a player to auto-lock onto them
	RELEASE_FOV = 700, -- once locked, target must leave this radius (px) to release

	-- Target part to lock onto. Common choices: "Head" (headshots) or
	-- "HumanoidRootPart" (chest/center, more forgiving).
	TARGET_PART = "HumanoidRootPart",

	MAX_DISTANCE = 1000, -- studs: ignore players farther than this (0 = no limit)
	SMOOTHNESS = 0.55, -- 0..1 camera easing per frame toward target (1 = instant snap)

	TEAM_CHECK = false, -- true = never lock onto teammates (same Team)
	WALL_CHECK = false, -- true = release/skip target when a wall blocks line of sight
	ALIVE_CHECK = true, -- true = never lock onto dead players (Humanoid.Health <= 0)

	-- Keybinds (see Enum.KeyCode for names).
	TOGGLE_KEY = Enum.KeyCode.K, -- enable/disable the whole feature
	UNLOCK_KEY = Enum.KeyCode.L, -- force-release the current target
	HOLD_DISABLE_KEY = Enum.KeyCode.LeftAlt, -- hold to temporarily suspend locking

	NOTIFY = true, -- print status messages when acquiring / releasing / toggling
}
-- ==================================================================

local currentTarget = nil -- the Player we're locked onto (nil = none)

local function notify(msg)
	if CONFIG.NOTIFY then
		print("[CamLock] " .. msg)
	end
end

-- Resolve the part we should aim at on a given player, or nil if unavailable.
local function getTargetPart(player)
	local char = player.Character
	if not char then
		return nil
	end
	local part = char:FindFirstChild(CONFIG.TARGET_PART)
	if not part then
		-- Fall back to root/head so the lock still works if the preferred part is missing.
		part = char:FindFirstChild("HumanoidRootPart")
			or char:FindFirstChild("Head")
			or char.PrimaryPart
	end
	return part
end

-- Is there a wall between our camera and the target part?
local function isBlocked(char, targetPos)
	local origin = Camera.CFrame.Position
	local params = RaycastParams.new()
	params.FilterType = Enum.RaycastFilterType.Exclude
	params.FilterDescendantsInstances = { LocalPlayer.Character, char, Camera }
	params.IgnoreWater = true
	local hit = Workspace:Raycast(origin, targetPos - origin, params)
	-- A hit before reaching the target means something (a wall) is in the way.
	return hit ~= nil
end

-- Whether `player` is a legal target right now (alive, on-screen consideration
-- happens separately). Returns the target part when valid, else nil.
local function validate(player)
	if player == LocalPlayer then
		return nil
	end

	local char = player.Character
	if not char then
		return nil
	end

	if CONFIG.ALIVE_CHECK then
		local humanoid = char:FindFirstChildOfClass("Humanoid")
		if not humanoid or humanoid.Health <= 0 then
			return nil
		end
	end

	if CONFIG.TEAM_CHECK and LocalPlayer.Team ~= nil and player.Team == LocalPlayer.Team then
		return nil
	end

	local part = getTargetPart(player)
	if not part then
		return nil
	end

	local pos = part.Position

	if CONFIG.MAX_DISTANCE > 0 then
		local root = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
		local fromPos = root and root.Position or Camera.CFrame.Position
		if (pos - fromPos).Magnitude > CONFIG.MAX_DISTANCE then
			return nil
		end
	end

	if CONFIG.WALL_CHECK and isBlocked(char, pos) then
		return nil
	end

	return part
end

-- Pixel distance from the crosshair (screen center) to the target part, or nil if
-- the part is behind the camera / off screen. Lower = closer to where you're aiming.
local function screenDistance(part)
	local screenPos, onScreen = Camera:WorldToViewportPoint(part.Position)
	if not onScreen or screenPos.Z <= 0 then
		return nil
	end
	local center = Camera.ViewportSize / 2
	local dx = screenPos.X - center.X
	local dy = screenPos.Y - center.Y
	return math.sqrt(dx * dx + dy * dy)
end

-- Scan all players and return the best acquisition candidate: the valid player
-- whose target part is closest to the crosshair and within ACQUIRE_FOV.
local function findAcquireTarget()
	local best, bestDist = nil, CONFIG.ACQUIRE_FOV
	for _, player in ipairs(Players:GetPlayers()) do
		local part = validate(player)
		if part then
			local dist = screenDistance(part)
			if dist and dist <= bestDist then
				best, bestDist = player, dist
			end
		end
	end
	return best
end

-- Should we keep the current lock? Returns the target part if still valid and
-- within the (larger) release cone, else nil.
local function shouldKeepTarget()
	if not currentTarget or not currentTarget.Parent then
		return nil
	end
	local part = validate(currentTarget)
	if not part then
		return nil
	end
	local dist = screenDistance(part)
	if not dist or dist > CONFIG.RELEASE_FOV then
		return nil
	end
	return part
end

local function setTarget(player)
	if player == currentTarget then
		return
	end
	currentTarget = player
	if player then
		notify("Locked onto " .. player.Name)
	else
		notify("Released")
	end
end

-- Target selection (scanning every player and viewport-projecting them) is the
-- expensive part, so it runs on a throttle instead of every rendered frame. The
-- camera rotation still runs every frame off the cached part, so aim stays smooth.
local SCAN_INTERVAL = 1 / 15 -- seconds between target (re)scans
local scanAccum = 0
local lockedPart = nil -- cached part we're currently aiming at

local function rescan()
	local part = shouldKeepTarget()
	if not part then
		if currentTarget then
			setTarget(nil)
		end
		local acquired = findAcquireTarget()
		if acquired then
			setTarget(acquired)
			part = getTargetPart(acquired)
		end
	end
	lockedPart = part
end

-- Per-frame: maintain/acquire target and ease the camera toward it.
local function onRenderStep(dt)
	if not CONFIG.ENABLED then
		if currentTarget then
			setTarget(nil)
		end
		lockedPart = nil
		return
	end

	-- Hold-to-disable lets you freely look around without dropping in and out.
	if CONFIG.HOLD_DISABLE_KEY and UserInputService:IsKeyDown(CONFIG.HOLD_DISABLE_KEY) then
		return
	end

	scanAccum = scanAccum + (dt or 0)
	if scanAccum >= SCAN_INTERVAL or lockedPart == nil then
		scanAccum = 0
		rescan()
	end

	-- Drop a cached part that was destroyed between scans.
	if lockedPart and not lockedPart.Parent then
		lockedPart = nil
	end
	if not lockedPart then
		return
	end

	-- Rotate the camera to look at the target part, keeping the camera's own
	-- position. SMOOTHNESS eases the rotation so it doesn't teleport violently.
	local camPos = Camera.CFrame.Position
	local goal = CFrame.new(camPos, lockedPart.Position)
	local alpha = math.clamp(CONFIG.SMOOTHNESS, 0, 1)
	Camera.CFrame = Camera.CFrame:Lerp(goal, alpha)
end

-- Keep our Camera reference fresh (it changes on respawn / game camera swaps).
local function refreshCamera()
	Camera = Workspace.CurrentCamera
end
Workspace:GetPropertyChangedSignal("CurrentCamera"):Connect(refreshCamera)

-- Drop the lock immediately if the target leaves the game.
Players.PlayerRemoving:Connect(function(player)
	if player == currentTarget then
		setTarget(nil)
	end
end)

UserInputService.InputBegan:Connect(function(input, gameProcessed)
	if gameProcessed then
		return
	end
	if input.KeyCode == CONFIG.TOGGLE_KEY then
		CONFIG.ENABLED = not CONFIG.ENABLED
		if not CONFIG.ENABLED then
			setTarget(nil)
		end
		notify(CONFIG.ENABLED and "Enabled" or "Disabled")
	elseif input.KeyCode == CONFIG.UNLOCK_KEY then
		if currentTarget then
			setTarget(nil)
		end
	end
end)

RunService.RenderStepped:Connect(onRenderStep)

notify("Loaded. Aim near a player to auto-lock. Toggle=" .. CONFIG.TOGGLE_KEY.Name
	.. ", Unlock=" .. CONFIG.UNLOCK_KEY.Name .. ".")
