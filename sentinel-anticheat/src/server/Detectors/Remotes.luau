--!strict
--[[
	Sentinel Remotes detector.
	The heavy lifting (rate limiting, schema validation, payload caps) lives in
	the shared Net layer. This module:
	  1. connects Net's abuse reporter into the scoring Registry, and
	  2. plants a HONEYPOT remote — a real-looking remote no legitimate client
	     ever fires. Exploiters that spray every remote in ReplicatedStorage will
	     trip it, which is a near-certain cheat signal.
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Config = require(ReplicatedStorage.SentinelShared.Config)
local Net = require(ReplicatedStorage.SentinelShared.Net)
local Registry = require(script.Parent.Parent.Core.Registry)

local R = { name = "Remotes" }

function R.setup()
	if not Config.Remotes.Enabled then
		return
	end

	-- Route every Net-detected abuse into the scoring engine.
	Net.setReporter(function(player, category, weight, detail)
		Registry.report(player, category, weight, detail)
	end)

	-- Honeypot: a plausible-looking remote wired to instantly punish callers.
	Net.event({
		name = "GrantAdminAccess", -- bait; nothing legitimate calls this
		onServerEvent = function(player, ...)
			Registry.report(player, "Honeypot", Config.Remotes.Weights.UnknownRemote * 2,
				"fired honeypot remote 'GrantAdminAccess'")
		end,
	})
end

return R
