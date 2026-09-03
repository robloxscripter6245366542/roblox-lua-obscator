--!strict
--[[
	Sentinel Anti-Cheat — server bootstrap.
	Place this Script (with its Core/ and Detectors/ children) in ServerScriptService.

	It owns the lifecycle: ban checks on join, per-player profiles, the sampled
	detection loop, and the public integration API exposed as `_G.Sentinel`.

	Design in one line: the server measures the truth, a single scoring funnel
	turns anomalies into escalating actions, and games integrate through a small,
	explicit API instead of trusting the client.
]]

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Config = require(ReplicatedStorage.SentinelShared.Config)

local Logger = require(script.Core.Logger)
local Profile = require(script.Core.Profile)
local Registry = require(script.Core.Registry)
local Punish = require(script.Core.Punish)
local Telemetry = require(script.Core.Telemetry)

local Movement = require(script.Detectors.Movement)
local Character = require(script.Detectors.Character)
local Stats = require(script.Detectors.Stats)
local Remotes = require(script.Detectors.Remotes)
local Client = require(script.Detectors.Client)

Logger.info(("starting (DryRun=%s, Enabled=%s)"):format(tostring(Config.DryRun), tostring(Config.Enabled)))

Remotes.setup()
Client.setup()

---------------------------------------------------------------------------
-- Player lifecycle
---------------------------------------------------------------------------
local function onCharacterAdded(player: Player, character: Model)
	local prof = Profile.get(player)
	if not prof then
		return
	end
	-- Fresh spawn: relax movement checks briefly and reset the baseline.
	prof.lastPos = nil
	prof.lastGoodCFrame = nil
	prof.hoverSince = nil
	prof.graceUntil = os.clock() + Config.Movement.SpawnGracePeriod
	prof.lastGroundedAt = os.clock()

	Movement.onCharacter(player, character)
end

local function onPlayerAdded(player: Player)
	-- Enforce persistent bans before anything else.
	local banned, reason = Punish.isBanned(player.UserId)
	if banned then
		player:Kick(Config.Bans.KickMessagePrefix .. (reason or "banned"))
		return
	end

	Profile.create(player)
	Logger.debug("profile created for " .. player.Name)

	player.CharacterAdded:Connect(function(character)
		onCharacterAdded(player, character)
	end)
	if player.Character then
		onCharacterAdded(player, player.Character)
	end
end

local function onPlayerRemoving(player: Player)
	Character.onPlayerRemoving(player)
	Stats.onPlayerRemoving(player)
	Client.onPlayerRemoving(player)
	Registry.onPlayerRemoving(player)
	require(ReplicatedStorage.SentinelShared.Net).onPlayerRemoving(player)
	Profile.destroy(player)
end

for _, player in ipairs(Players:GetPlayers()) do
	task.spawn(onPlayerAdded, player)
end
Players.PlayerAdded:Connect(onPlayerAdded)
Players.PlayerRemoving:Connect(onPlayerRemoving)

---------------------------------------------------------------------------
-- Detection loop
---------------------------------------------------------------------------
-- Movement samples every frame (it self-throttles to Config.Movement.SampleHz).
-- The heavier property/god-mode/client checks run on a slower cadence.
local SLOW_INTERVAL = 0.5
local slowAccum = 0

RunService.Heartbeat:Connect(function(dt)
	local now = os.clock()
	slowAccum += dt
	local doSlow = slowAccum >= SLOW_INTERVAL
	if doSlow then
		slowAccum = 0
	end

	for _, prof in pairs(Profile.all()) do
		Profile.decay(prof)
		Movement.sample(prof, now)
		if doSlow then
			Character.sample(prof, now)
			Character.checkGodMode(prof)
			Client.sample(prof, now)
		end
	end
end)

---------------------------------------------------------------------------
-- Public integration API  ->  _G.Sentinel
---------------------------------------------------------------------------
local API = {}

-- Raise suspicion from your own game code when you detect something Sentinel
-- can't see (e.g. an illegal game-specific action).
API.report = Registry.report

-- Raise a per-player property ceiling for legitimate powerups.
--   Sentinel.exempt(player, "WalkSpeed", 50)
API.exempt = Character.exempt
API.clearExempt = Character.clearExempt

-- Whitelist a server-authorized teleport so it isn't flagged.
-- Call immediately BEFORE you move the character.
function API.allowTeleport(player: Player, seconds: number?)
	local prof = Profile.get(player)
	if prof then
		prof.teleportGraceUntil = os.clock() + (seconds or Config.Movement.TeleportGracePeriod)
	end
end

-- Apply damage the anti-cheat can verify (feeds god-mode detection).
API.damage = Character.damage

-- Server-authoritative stats. See Detectors/Stats for the full surface.
API.Stats = {
	watch = Stats.watch,
	add = Stats.add,
	get = Stats.get,
	set = Stats.set,
}

-- Hardened remote registration (rate limit + schema validation baked in).
API.Net = require(ReplicatedStorage.SentinelShared.Net)

-- Enforcement + moderation helpers.
API.ban = Punish.ban
API.unban = Punish.unban
API.kick = Punish.kick
API.isBanned = Punish.isBanned

-- Telemetry for an in-game admin panel.
API.recentEvents = Telemetry.recent
function API.getScore(player: Player): number
	local prof = Profile.get(player)
	return prof and prof.score or 0
end

_G.Sentinel = API
Logger.info("ready — _G.Sentinel API is live")

return API
