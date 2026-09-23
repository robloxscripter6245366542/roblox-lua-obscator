--!strict
--[[
	Sentinel Registry — the detection intake + scoring engine.
	Every detector calls Registry.report(...). The registry:
	  1. adds weight to the player's suspicion score (capped per second)
	  2. records the flag + telemetry event
	  3. fires the highest threshold action newly crossed
	This is the single funnel between "something looked wrong" and "do something".
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Config = require(ReplicatedStorage.SentinelShared.Config)
local Logger = require(script.Parent.Logger)
local Profile = require(script.Parent.Profile)
local Punish = require(script.Parent.Punish)
local Telemetry = require(script.Parent.Telemetry)

local Registry = {}

-- Sorted ascending so we can find the highest threshold a score satisfies.
local thresholds = table.clone(Config.Score.Thresholds)
table.sort(thresholds, function(a, b)
	return a.at < b.at
end)

-- Remember the highest threshold index already actioned per player so an action
-- fires once per crossing, not every frame the score stays high.
local actionedIndex: { [Player]: number } = {}

-- Core entry point. Safe to call from any detector.
function Registry.report(player: Player, category: string, weight: number, detail: string)
	if not Config.Enabled and not Config.DryRun then
		return
	end
	local prof = Profile.get(player)
	if not prof then
		return
	end

	Profile.decay(prof)

	-- Per-second gain cap: one chaotic frame can't rocket someone to a ban.
	local room = Config.Score.MaxGainPerSecond - prof.gainThisSecond
	local applied = math.max(0, math.min(weight, room))
	prof.score += applied
	prof.gainThisSecond += applied

	local flag: Profile.Flag = {
		category = category,
		weight = applied,
		detail = detail,
		at = os.time(),
	}
	table.insert(prof.flags, flag)
	if #prof.flags > 50 then
		table.remove(prof.flags, 1)
	end

	Logger.debug(("flag %s +%.1f (score %.1f) — %s"):format(
		category, applied, prof.score, detail))

	-- Find highest threshold now satisfied.
	local hitIndex = 0
	local hitAction: string? = nil
	for i, t in ipairs(thresholds) do
		if prof.score >= t.at then
			hitIndex = i
			hitAction = t.action
		end
	end

	local action: string? = nil
	local prev = actionedIndex[player] or 0
	if hitIndex > prev and hitAction then
		action = Punish.apply(player, hitAction, ("%s (%s)"):format(category, detail))
		-- After a kick/ban the score is meaningless; after a warn keep watching.
		if hitAction == "kick" or hitAction == "ban" then
			prof.score = 0
			hitIndex = 0
		end
	end
	-- Track the *current* satisfied tier (not a high-water mark), so a player
	-- whose score decays back down can re-trigger a warning if they reoffend.
	actionedIndex[player] = hitIndex

	local event: Telemetry.Event = {
		at = os.time(),
		userId = player.UserId,
		name = player.Name,
		category = category,
		detail = detail,
		score = prof.score,
		action = action,
	}
	Telemetry.record(event)
	if action then
		Telemetry.webhook(event)
	end
end

function Registry.onPlayerRemoving(player: Player)
	actionedIndex[player] = nil
end

return Registry
