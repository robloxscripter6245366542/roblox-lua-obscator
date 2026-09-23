--!strict
--[[
	Sentinel Profile — per-player runtime state.
	Holds the rolling suspicion score, movement bookkeeping, exemptions, and a
	small per-player history. One profile per player, created on join.
]]

local Config = require(game:GetService("ReplicatedStorage").SentinelShared.Config)

export type Flag = {
	category: string,
	weight: number,
	detail: string,
	at: number, -- os.time()
}

export type Profile = {
	player: Player,
	joinedAt: number,
	score: number,
	lastDecay: number,
	gainThisSecond: number,
	gainWindow: number,
	flags: { Flag },

	-- movement bookkeeping (written by Movement detector)
	lastPos: Vector3?,
	lastSample: number,
	lastGroundedAt: number,
	hoverSince: number?,
	graceUntil: number, -- movement checks relaxed until this os.clock()
	lastGoodCFrame: CFrame?,

	-- exemptions
	teleportGraceUntil: number,

	-- stats mirror: server-truth values Sentinel authored
	stats: { [string]: number },
	statLastGain: { [string]: number },

	-- client heartbeat
	lastHeartbeat: number,
	missedHeartbeats: number,
}

local Profile = {}
local profiles: { [Player]: Profile } = {}

function Profile.create(player: Player): Profile
	local now = os.clock()
	local p: Profile = {
		player = player,
		joinedAt = os.time(),
		score = 0,
		lastDecay = now,
		gainThisSecond = 0,
		gainWindow = now,
		flags = {},
		lastPos = nil,
		lastSample = now,
		lastGroundedAt = now,
		hoverSince = nil,
		graceUntil = now + Config.Movement.SpawnGracePeriod,
		lastGoodCFrame = nil,
		teleportGraceUntil = 0,
		stats = {},
		statLastGain = {},
		lastHeartbeat = now,
		missedHeartbeats = 0,
	}
	profiles[player] = p
	return p
end

function Profile.get(player: Player): Profile?
	return profiles[player]
end

function Profile.destroy(player: Player)
	profiles[player] = nil
end

function Profile.all(): { [Player]: Profile }
	return profiles
end

-- Bleed score down over elapsed real time. Called each tick before evaluation.
function Profile.decay(p: Profile)
	local now = os.clock()
	local dt = now - p.lastDecay
	if dt <= 0 then
		return
	end
	p.lastDecay = now
	p.score = math.max(0, p.score - Config.Score.DecayPerSecond * dt)

	-- reset the per-second gain cap window
	if now - p.gainWindow >= 1 then
		p.gainWindow = now
		p.gainThisSecond = 0
	end
end

return Profile
