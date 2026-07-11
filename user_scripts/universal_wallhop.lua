-- Universal WallHop Script (works on ANY wall, at any orientation)
--
-- Detection rework:
--   * A body-part Touched event only tells us *something* was touched. To decide
--     whether it is actually a wall we can hop on, we probe with several
--     horizontal rays (toward the touched part, along our movement, and along
--     our facing) at foot/torso/head height and pick the closest wall-like hit.
--   * A hit counts as a wall only if its surface normal is (nearly) horizontal,
--     it is within reach, and the surface continues far enough *above* us — i.e.
--     it is a wall we can keep hopping up, not a low lip, railing, or the floor.
--   * Climbs by applying a real "into-the-wall + up" velocity impulse each hop.
--   * Listens only on the local character's own parts (no whole-workspace
--     Touched storm), reconnects cleanly on respawn, supports R6 and R15 rigs.
--   * Forces shift lock (mouse lock) on so hops go straight into the wall.

local Players = game:GetService("Players")

local LocalPlayer = Players.LocalPlayer

-- ==== Tunables ====================================================
local HOP_COOLDOWN = 0.18 -- min seconds between hops
local HOP_UP_VELOCITY = 55 -- upward speed applied on each hop
local HOP_INTO_WALL_SPEED = 14 -- speed pushed into the wall so you keep climbing
local WALL_NORMAL_MAX_Y = 0.5 -- |normal.Y| below this = a wall (not floor/ceiling)
local WALL_MAX_DISTANCE = 5 -- studs: max reach to a wall we'll still hop on
local WALL_MIN_HEIGHT = 3 -- studs: wall must continue this far above us to be hoppable
local SHIFT_LOCK = true -- force shift lock (mouse lock) on
-- ==================================================================

-- Force shift lock via the default PlayerModule camera controller. Wrapped in
-- pcall since the internal API is not guaranteed across every game. Returns true
-- only when the lock was actually applied, so callers can retry if it wasn't.
local function applyMouseLock()
	if not SHIFT_LOCK then
		return false
	end
	local ok, applied = pcall(function()
		local playerScripts = LocalPlayer:FindFirstChild("PlayerScripts")
		local playerModule = playerScripts and playerScripts:FindFirstChild("PlayerModule")
		if not playerModule then
			return false
		end
		local cameraModule = require(playerModule):GetCameras()
		local controller = cameraModule and cameraModule.activeCameraController
		if controller and controller.SetIsMouseLocked then
			controller:SetIsMouseLocked(true)
			return true
		end
		return false
	end)
	return ok and applied
end

-- The camera controller isn't ready for the first few frames after spawn, so a
-- single attempt usually fails silently. Keep retrying (in its own thread, so it
-- never blocks a hop) until the lock takes.
local function ensureMouseLock()
	if not SHIFT_LOCK then
		return
	end
	task.spawn(function()
		for _ = 1, 30 do
			if applyMouseLock() then
				return
			end
			task.wait(0.1)
		end
	end)
end

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

local lastHopTime = 0
local touchConnections = {}

local function disconnectTouches()
	for _, conn in ipairs(touchConnections) do
		conn:Disconnect()
	end
	table.clear(touchConnections)
end

local function makeParams(character)
	local params = RaycastParams.new()
	params.FilterType = Enum.RaycastFilterType.Exclude
	params.FilterDescendantsInstances = { character }
	params.IgnoreWater = true
	return params
end

-- Collect the horizontal directions worth probing for a wall face: toward the
-- touched part, along our horizontal velocity, and along our facing.
local function candidateDirections(rootPart, wallPart)
	local dirs = {}
	local function add(v)
		local flat = Vector3.new(v.X, 0, v.Z)
		if flat.Magnitude < 1e-3 then
			return
		end
		local unit = flat.Unit
		for _, existing in ipairs(dirs) do
			if existing:Dot(unit) > 0.966 then -- within ~15deg: skip near-duplicate
				return
			end
		end
		table.insert(dirs, unit)
	end
	add(wallPart.Position - rootPart.Position)
	local vel = rootPart.AssemblyLinearVelocity
	if Vector3.new(vel.X, 0, vel.Z).Magnitude > 1 then
		add(vel)
	end
	add(rootPart.CFrame.LookVector)
	return dirs
end

-- Returns a RaycastResult for the closest hoppable wall, or nil.
local function findWall(character, rootPart, wallPart)
	local params = makeParams(character)
	local best
	local bestDist

	for _, dir in ipairs(candidateDirections(rootPart, wallPart)) do
		for _, dy in ipairs({ -1.5, 0, 1.5 }) do
			local origin = rootPart.Position + Vector3.new(0, dy, 0)
			local hit = workspace:Raycast(origin, dir * WALL_MAX_DISTANCE, params)
			if hit and math.abs(hit.Normal.Y) < WALL_NORMAL_MAX_Y then
				-- Measure from the character's center (not the probe origin) so
				-- probes at different heights are compared consistently.
				local dist = (hit.Position - rootPart.Position).Magnitude
				if not best or dist < bestDist then
					best = hit
					bestDist = dist
				end
			end
		end
	end

	if not best then
		return nil
	end

	-- Confirm the wall extends far enough above us to actually climb. Probe at the
	-- exact column we hit (not the character's center): step just outside the wall
	-- face, rise by WALL_MIN_HEIGHT, then cast back into the wall along its own
	-- normal. This holds for a wall of any orientation; casting from the
	-- character's position only worked when the wall was directly ahead.
	local aboveOrigin = best.Position + best.Normal * 0.5 + Vector3.new(0, WALL_MIN_HEIGHT, 0)
	local aboveHit = workspace:Raycast(aboveOrigin, -best.Normal * 2, params)
	if not aboveHit or math.abs(aboveHit.Normal.Y) >= WALL_NORMAL_MAX_Y then
		return nil
	end

	return best
end

local function tryHop(character, wallPart, otherPart)
	if not validBodyParts[otherPart.Name] then
		return
	end
	if otherPart:FindFirstAncestorOfClass("Tool") then
		return
	end

	local now = os.clock()
	if now - lastHopTime < HOP_COOLDOWN then
		return
	end

	local humanoid = character:FindFirstChildOfClass("Humanoid")
	local rootPart = character:FindFirstChild("HumanoidRootPart")
	if not humanoid or not rootPart or humanoid.Health <= 0 then
		return
	end

	local wall = findWall(character, rootPart, wallPart)
	if not wall then
		return
	end

	lastHopTime = now

	-- Push into the wall (opposite of its outward normal) and upward, so each
	-- hop climbs the wall instead of merely jumping in place.
	local intoWall = Vector3.new(-wall.Normal.X, 0, -wall.Normal.Z)
	if intoWall.Magnitude > 1e-3 then
		intoWall = intoWall.Unit * HOP_INTO_WALL_SPEED
	else
		intoWall = Vector3.zero
	end

	-- Keep shift lock engaged (game code / respawn can clear it) and launch. The
	-- direct velocity is what actually climbs, so it must be the last word this
	-- frame: switch to the Jumping state first (so the humanoid doesn't snap us
	-- back onto the ground), then set the velocity. We deliberately do NOT toggle
	-- Humanoid.Jump — a real jump overwrites our upward velocity with JumpPower
	-- (usually lower, costing height) and does nothing at all while airborne.
	applyMouseLock()
	humanoid:ChangeState(Enum.HumanoidStateType.Jumping)
	rootPart.AssemblyLinearVelocity = intoWall + Vector3.new(0, HOP_UP_VELOCITY, 0)
end

local function connectCharacter(character)
	disconnectTouches()

	local connected = {}
	local function connectPart(part)
		if connected[part] then
			return
		end
		if not (part:IsA("BasePart") and validBodyParts[part.Name]) then
			return
		end
		connected[part] = true
		local conn = part.Touched:Connect(function(wallPart)
			if wallPart:IsDescendantOf(character) then
				return
			end
			if not wallPart.CanCollide then
				return
			end
			tryHop(character, wallPart, part)
		end)
		table.insert(touchConnections, conn)
	end

	for _, part in ipairs(character:GetDescendants()) do
		connectPart(part)
	end

	-- On respawn, CharacterAdded can fire before every body part has streamed
	-- in, so GetDescendants misses them. Catch late-added parts too.
	table.insert(touchConnections, character.DescendantAdded:Connect(connectPart))

	-- Re-apply shift lock once the new character's camera controller exists.
	ensureMouseLock()
end

if LocalPlayer.Character then
	connectCharacter(LocalPlayer.Character)
end
LocalPlayer.CharacterAdded:Connect(connectCharacter)
ensureMouseLock()

print("✅ Universal WallHop loaded! Detects hoppable walls of any orientation via raycasts.")
