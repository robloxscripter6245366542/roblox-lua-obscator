-- Universal WallHop Script (works on ANY wall, at any orientation)
--
-- Improvements over the original:
--   * Detects the WALL surface itself via a raycast normal instead of guessing
--     from part height, so it reliably finds vertical / horizontally-facing
--     walls no matter how the part is rotated (angled, thin, or rotated parts).
--   * Only listens to the local character's own parts touching things, instead
--     of connecting a Touched handler to every BasePart in the workspace. This
--     removes the huge memory/perf cost (and the double-connect bug) of the
--     original and gives us the wall part directly.
--   * Reconnects cleanly on respawn and disconnects stale connections.
--   * Climbs by applying a real "into-the-wall + up" velocity impulse each hop
--     rather than a cosmetic camera yaw twist that never affected height.
--   * Supports both R6 ("Torso") and R15 ("UpperTorso"/"LowerTorso") rigs.

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")

local LocalPlayer = Players.LocalPlayer

-- ==== Tunables ====================================================
local HOP_COOLDOWN = 0.18 -- min seconds between hops
local HOP_UP_VELOCITY = 55 -- upward speed applied on each hop
local HOP_INTO_WALL_SPEED = 14 -- speed pushed into the wall so you keep climbing
local WALL_NORMAL_MAX_Y = 0.5 -- |normal.Y| below this = a wall (not a floor/ceiling)
local RAY_EXTRA_REACH = 6 -- studs added to the ray so we still hit the wall
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

local lastHopTime = 0
local touchConnections = {}

local function disconnectTouches()
	for _, conn in ipairs(touchConnections) do
		conn:Disconnect()
	end
	table.clear(touchConnections)
end

-- Returns the outward-facing normal of the wall the character is touching,
-- or nil if the touched surface is not a (roughly vertical) wall.
local function getWallNormal(character, rootPart, wallPart)
	local toWall = wallPart.Position - rootPart.Position
	local horizontal = Vector3.new(toWall.X, 0, toWall.Z)
	if horizontal.Magnitude < 1e-3 then
		return nil
	end

	local params = RaycastParams.new()
	params.FilterType = Enum.RaycastFilterType.Exclude
	params.FilterDescendantsInstances = { character }
	params.IgnoreWater = true

	local direction = horizontal.Unit * (horizontal.Magnitude + RAY_EXTRA_REACH)
	local result = workspace:Raycast(rootPart.Position, direction, params)
	if not result then
		return nil
	end

	-- A wall's surface normal is (nearly) horizontal; a floor/ceiling normal
	-- points mostly up/down. This is what lets us hop on horizontally-facing
	-- walls at any orientation while ignoring the ground.
	if math.abs(result.Normal.Y) >= WALL_NORMAL_MAX_Y then
		return nil
	end

	return result.Normal
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
	if not humanoid or not rootPart then
		return
	end
	if humanoid.Health <= 0 then
		return
	end

	local normal = getWallNormal(character, rootPart, wallPart)
	if not normal then
		return
	end

	lastHopTime = now

	-- Push into the wall (opposite of its outward normal) and upward, so each
	-- hop climbs the wall instead of merely jumping in place.
	local intoWall = Vector3.new(-normal.X, 0, -normal.Z)
	if intoWall.Magnitude > 1e-3 then
		intoWall = intoWall.Unit * HOP_INTO_WALL_SPEED
	else
		intoWall = Vector3.zero
	end

	rootPart.AssemblyLinearVelocity = intoWall + Vector3.new(0, HOP_UP_VELOCITY, 0)
	humanoid:ChangeState(Enum.HumanoidStateType.Jumping)
end

local function connectCharacter(character)
	disconnectTouches()

	for _, part in ipairs(character:GetDescendants()) do
		if part:IsA("BasePart") and validBodyParts[part.Name] then
			local conn = part.Touched:Connect(function(wallPart)
				-- Ignore other parts of our own character.
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
	end
end

if LocalPlayer.Character then
	connectCharacter(LocalPlayer.Character)
end
LocalPlayer.CharacterAdded:Connect(connectCharacter)

print("✅ Universal WallHop loaded! Detects walls of any orientation via surface normals.")
