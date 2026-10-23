-- WallHop Script (for games that use parts named "WallHopPart")
--
-- Touch a "WallHopPart" with one of your body parts and the script forces shift
-- lock on, then launches you up-and-into the wall so you climb it. Shift lock is
-- released again (restoring your original setting) once you're clearly falling
-- away from the wall, so the hop run has a clean end.
--
-- This is a cleaned-up rewrite of the original decompiled version. Fixes:
--   * Single shared state instead of two divergent copies. The original kept one
--     set of variables for WallHopParts that existed at load and a *different*
--     set for parts added later; the fall-watcher only read the first set, so
--     any WallHopPart that spawned after load forced shift lock and never
--     released it. Now there is one source of truth.
--   * One touch handler wired to both existing and future WallHopParts, instead
--     of the whole body being copy-pasted inline and inside the connect closure.
--   * Applies a real up + into-wall velocity so you actually climb tall walls,
--     rather than only re-triggering the jump state (which hopped in place).
--   * Dropped the camera-yank (rotating the camera 25 deg and reverting it) —
--     it fought the player's own aim and did nothing to move you up the wall.

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")

local LocalPlayer = Players.LocalPlayer

-- ==== Tunables ====================================================
local WALL_PART_NAME = "WallHopPart" -- only parts with this name are hoppable
local HOP_COOLDOWN = 0.3 -- min seconds between hops
local HOP_UP_VELOCITY = 55 -- upward speed applied on each hop
local HOP_INTO_WALL_SPEED = 14 -- speed pushed into the wall so you keep climbing
local FALL_RELEASE_SPEED = -10 -- Y velocity below this counts as "falling away"
local FALL_RELEASE_TIME = 0.12 -- seconds of falling before shift lock is released
local FORCE_SHIFT_LOCK = true -- force shift lock (mouse lock) on while hopping
-- ==================================================================

local validBodyParts = {
	Head = true,
	Torso = true,
	UpperTorso = true,
	LowerTorso = true,
	["Left Arm"] = true,
	["Right Arm"] = true,
	["Left Leg"] = true,
	["Right Leg"] = true,
	HumanoidRootPart = true,
}

-- Shared state (single source of truth — the original kept two divergent copies).
local lastHopTime = 0
local shiftLockForced = false -- did WE turn shift lock on?
local originalMouseLocked = nil -- the player's shift-lock setting before we forced it
local fallStartedAt = nil -- os.clock() when the character began falling away

-- Resolve the default PlayerModule camera controller (used for shift lock).
local function getCameraController()
	local playerScripts = LocalPlayer:FindFirstChild("PlayerScripts")
	local playerModule = playerScripts and playerScripts:FindFirstChild("PlayerModule")
	if not playerModule then
		return nil
	end
	local cameraModule = require(playerModule):GetCameras()
	return cameraModule and cameraModule.activeCameraController or nil
end

local function isMouseLocked()
	local ok, locked = pcall(function()
		local controller = getCameraController()
		if controller and controller.GetIsMouseLocked then
			return controller:GetIsMouseLocked()
		end
		return false
	end)
	return ok and locked or false
end

local function setMouseLocked(locked)
	pcall(function()
		local controller = getCameraController()
		if controller and controller.SetIsMouseLocked then
			controller:SetIsMouseLocked(locked)
		end
	end)
end

local function tryHop(wallPart, bodyPart)
	local character = LocalPlayer.Character
	if not character or bodyPart.Parent ~= character then
		return
	end
	if not validBodyParts[bodyPart.Name] then
		return
	end
	if bodyPart:FindFirstAncestorOfClass("Tool") then
		return
	end

	local humanoid = character:FindFirstChildOfClass("Humanoid")
	local rootPart = character:FindFirstChild("HumanoidRootPart")
	if not humanoid or not rootPart or humanoid.Health <= 0 then
		return
	end

	-- Ignore walls whose top is already below us — nothing left to climb.
	if wallPart.Position.Y + wallPart.Size.Y * 0.5 < rootPart.Position.Y then
		return
	end

	local now = os.clock()
	if now - lastHopTime < HOP_COOLDOWN then
		return
	end
	lastHopTime = now

	-- Force shift lock on, remembering the player's original setting once so the
	-- fall-watcher can restore it later.
	if FORCE_SHIFT_LOCK then
		if originalMouseLocked == nil then
			originalMouseLocked = isMouseLocked()
		end
		if not shiftLockForced then
			setMouseLocked(true)
			shiftLockForced = true
		end
	end

	-- Climb: push up and into the wall. "Into the wall" is the horizontal
	-- direction from us toward the wall part, so it works at any orientation.
	local toWall = wallPart.Position - rootPart.Position
	toWall = Vector3.new(toWall.X, 0, toWall.Z)
	local intoWall = Vector3.zero
	if toWall.Magnitude > 1e-3 then
		intoWall = toWall.Unit * HOP_INTO_WALL_SPEED
	end

	-- Switch to Jumping first (so the humanoid doesn't plant us back down), then
	-- set the velocity as the last write of the frame so it actually takes.
	humanoid:ChangeState(Enum.HumanoidStateType.Jumping)
	rootPart.AssemblyLinearVelocity = intoWall + Vector3.new(0, HOP_UP_VELOCITY, 0)
	fallStartedAt = nil
end

-- Wire the touch handler to a part if it's a WallHopPart. We watch the wall
-- parts themselves (as the original did), not the character's body parts.
local connected = {}
local function connectPart(part)
	if connected[part] then
		return
	end
	if not (part:IsA("BasePart") and part.Name == WALL_PART_NAME) then
		return
	end
	connected[part] = true
	part.Touched:Connect(function(bodyPart)
		tryHop(part, bodyPart)
	end)
end

for _, descendant in ipairs(workspace:GetDescendants()) do
	connectPart(descendant)
end
workspace.DescendantAdded:Connect(connectPart)

-- Release shift lock (restoring the player's original setting) once we've been
-- falling away from the wall for a moment — i.e. the hop run is over.
RunService.RenderStepped:Connect(function()
	if not shiftLockForced then
		return
	end
	local character = LocalPlayer.Character
	local rootPart = character and character:FindFirstChild("HumanoidRootPart")
	if not rootPart then
		return
	end

	if rootPart.AssemblyLinearVelocity.Y < FALL_RELEASE_SPEED then
		fallStartedAt = fallStartedAt or os.clock()
		if os.clock() - fallStartedAt >= FALL_RELEASE_TIME then
			-- Only turn shift lock back off if the player didn't have it on to
			-- begin with; otherwise leave their own setting untouched.
			if FORCE_SHIFT_LOCK and originalMouseLocked == false then
				setMouseLocked(false)
			end
			shiftLockForced = false
			originalMouseLocked = nil
			fallStartedAt = nil
		end
	else
		fallStartedAt = nil
	end
end)

-- Reset state on respawn so a fresh character starts clean.
LocalPlayer.CharacterAdded:Connect(function()
	shiftLockForced = false
	originalMouseLocked = nil
	fallStartedAt = nil
end)

print("✅ WallHop loaded! Hop any part named '" .. WALL_PART_NAME .. "'.")
