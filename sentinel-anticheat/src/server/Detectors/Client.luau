--!strict
--[[
	Sentinel Client detector (server half).
	The client LocalScript heartbeats through the "SentinelHeartbeat" remote and
	can self-report known exploit globals it sees in its own environment.

	IMPORTANT: this is FRICTION, not proof. A cheater can delete the LocalScript
	or fake the heartbeat. That's why MissingClient carries a LOW weight — it only
	nudges suspicion and pairs with the server-authoritative detectors that do the
	real work. Laggy players legitimately miss heartbeats too.
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Config = require(ReplicatedStorage.SentinelShared.Config)
local Net = require(ReplicatedStorage.SentinelShared.Net)
local Registry = require(script.Parent.Parent.Core.Registry)
local Profile = require(script.Parent.Parent.Core.Profile)

local CL = { name = "Client" }

-- Track whether we've already flagged the current missing-client streak so we
-- report once per streak, not every sample.
local flaggedMissing: { [Player]: boolean } = {}

function CL.setup()
	if not Config.Client.Enabled then
		return
	end
	Net.event({
		name = "SentinelHeartbeat",
		schema = { "?table" }, -- optional self-report payload
		ratePerMinute = 120,
		burst = 5,
		onServerEvent = function(player, report: { any }?)
			local prof = Profile.get(player)
			if not prof then
				return
			end
			prof.lastHeartbeat = os.clock()
			prof.missedHeartbeats = 0
			flaggedMissing[player] = false

			-- Client volunteered that it detected a known exploit global.
			if type(report) == "table" and report.integrity == false then
				Registry.report(player, "IntegrityReport", Config.Client.Weights.IntegrityReport,
					("client self-reported: %s"):format(tostring(report.reason or "unknown")))
			end
		end,
	})
end

function CL.sample(prof: Profile.Profile, now: number)
	if not Config.Client.Enabled then
		return
	end
	local player = prof.player
	local silence = now - prof.lastHeartbeat
	local misses = silence / Config.Client.HeartbeatInterval
	if misses >= Config.Client.MissedHeartbeatsToFlag and not flaggedMissing[player] then
		flaggedMissing[player] = true
		Registry.report(player, "MissingClient", Config.Client.Weights.MissingClient,
			("no heartbeat for %.1fs"):format(silence))
	end
end

function CL.onPlayerRemoving(player: Player)
	flaggedMissing[player] = nil
end

return CL
