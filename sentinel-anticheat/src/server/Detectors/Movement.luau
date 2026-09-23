--!strict
--[[
	Sentinel Movement detector — server-authoritative position validation.
	Runs on a sampled tick. Everything here is measured by the SERVER against the
	replicated character, so a client that lies about its position still gets
	measured on the truth the server sees.

	Catches: speed hacks, teleports, fly/hover, noclip (through/inside solids),
	and infinite jump. Violations raise suspicion via Registry and, for hard
	geometry violations, snap the character back (rollback).
]]

local Workspace = game:GetService("Workspace")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Config = require(ReplicatedStorage.SentinelShared.Config)
local Registry = require(script.Parent.Parent.Core.Registry)
local Profile = require(script.Parent.Parent.Core.Profile)
local Punish = require(script.Parent.Parent.Core.Punish)

local M = { name = "Movement" }

local MIN_INTERVAL = 1 / Config.Movement.SampleHz

-- Overlap params reused for the embedded-in-solid (noclip) check.
local overlapParams = OverlapParams.new()
overlapParams.FilterType = Enum.RaycastFilterType.Exclude

local rayParams = RaycastParams.new()
rayParams.FilterType = Enum.RaycastFilterType.Exclude
rayParams.IgnoreWater = true

local function isSeated(humanoid: Humanoid): boolean
	return humanoid.Sit or humanoid:GetState() == Enum.HumanoidStateType.Seated
end

-- Per-character wiring: infinite-jump needs the jump edge, not a poll.
function M.onCharacter(player: Player, character: Model)
	local humanoid = character:FindFirstChildOfClass("Humanoid")
	if not humanoid then
		return
	end
	humanoid.StateChanged:Connect(function(_old, new)
		if new ~= Enum.HumanoidStateType.Jumping then
			return
		end
		local prof = Profile.get(player)
		if not prof then
			return
		end
		local now = os.clock()
		if now < prof.graceUntil then
			return
		end
		-- Jumping while clearly airborne and not freshly grounded == infinite jump.
		local airborneFor = now - prof.lastGroundedAt
		if humanoid.FloorMaterial == Enum.Material.Air and airborneFor > 0.35 then
			Registry.report(player, "InfiniteJump",
				Config.Movement.Weights.InfiniteJump,
				("jump while airborne %.2fs"):format(airborneFor))
		end
	end)
end

function M.sample(prof: Profile.Profile, now: number)
	if not Config.Movement.Enabled then
		return
	end
	local player = prof.player
	local character = player.Character
	if not character then
		prof.lastPos = nil
		return
	end
	local humanoid = character:FindFirstChildOfClass("Humanoid")
	local hrp = character:FindFirstChild("HumanoidRootPart")
	if not humanoid or not hrp or not hrp:IsA("BasePart") then
		return
	end
	if humanoid.Health <= 0 then
		prof.lastPos = nil
		return
	end

	-- Respect sample rate.
	local dt = now - prof.lastSample
	if dt < MIN_INTERVAL then
		return
	end
	prof.lastSample = now

	local pos = hrp.Position

	-- Seated / vehicle movement is physics-driven and legitimate — trust it,
	-- just keep the bookkeeping current so we don't false-positive on exit.
	if isSeated(humanoid) then
		prof.lastPos = pos
		prof.lastGoodCFrame = hrp.CFrame
		prof.lastGroundedAt = now
		return
	end

	-- Grace window (spawn / authorized teleport): sync state, skip enforcement.
	if now < prof.graceUntil or now < prof.teleportGraceUntil then
		prof.lastPos = pos
		prof.lastGoodCFrame = hrp.CFrame
		return
	end

	if prof.lastPos == nil then
		prof.lastPos = pos
		prof.lastGoodCFrame = hrp.CFrame
		return
	end

	local last = prof.lastPos :: Vector3
	local delta = pos - last
	local horizontal = Vector3.new(delta.X, 0, delta.Z).Magnitude
	local horizSpeed = horizontal / dt

	local grounded = humanoid.FloorMaterial ~= Enum.Material.Air
	if grounded then
		prof.lastGroundedAt = now
		prof.hoverSince = nil
	end

	local violated = false

	-- 1) Teleport: an instantaneous jump farther than any legal single-tick move.
	if horizontal > Config.Movement.MaxTeleportDistance then
		Registry.report(player, "Teleport", Config.Movement.Weights.Teleport,
			("moved %.0f studs in %.3fs"):format(horizontal, dt))
		Punish.rollback(player, "teleport")
		violated = true
	end

	-- 2) Speed: horizontal velocity beyond WalkSpeed + tolerance.
	if not violated then
		local maxSpeed = humanoid.WalkSpeed * Config.Movement.SpeedMultiplier
			+ Config.Movement.SpeedFlatBonus
		if horizSpeed > maxSpeed then
			Registry.report(player, "Speed", Config.Movement.Weights.Speed,
				("%.0f studs/s > %.0f allowed"):format(horizSpeed, maxSpeed))
			Punish.rollback(player, "speed")
			violated = true
		end
	end

	-- 3) Fly / hover: airborne with near-zero vertical velocity for too long.
	if not violated and not grounded then
		local velY = hrp.AssemblyLinearVelocity.Y
		if math.abs(velY) < Config.Movement.HoverVelocityEpsilon then
			if prof.hoverSince == nil then
				prof.hoverSince = now
			elseif now - (prof.hoverSince :: number) > Config.Movement.MaxAirborneHoverTime then
				Registry.report(player, "Fly", Config.Movement.Weights.Fly,
					("hovered %.2fs (vY=%.1f)"):format(now - (prof.hoverSince :: number), velY))
				Punish.rollback(player, "fly")
				violated = true
			end
		else
			prof.hoverSince = nil
		end
	end

	-- 4) Noclip: embedded inside a collidable solid the player shouldn't be in.
	if not violated and Config.Movement.NoclipCheck then
		overlapParams.FilterDescendantsInstances = { character }
		local size = Vector3.new(1, 1, 1)
		local touching = Workspace:GetPartBoundsInBox(CFrame.new(pos), size, overlapParams)
		for _, part in ipairs(touching) do
			if part.CanCollide and part.Anchored then
				Registry.report(player, "Noclip", Config.Movement.Weights.Noclip,
					("inside collidable %q"):format(part:GetFullName()))
				Punish.rollback(player, "noclip")
				violated = true
				break
			end
		end
	end

	-- Advance the trusted baseline only on clean frames; a violated frame keeps
	-- the previous good CFrame so rollback has somewhere safe to send them.
	prof.lastPos = pos
	if not violated then
		prof.lastGoodCFrame = hrp.CFrame
	end
end

return M
