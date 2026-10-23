--!strict
--[[
	Sentinel Character detector — humanoid property + god-mode guarding.
	The server's Humanoid is authoritative: an exploiter editing WalkSpeed locally
	does NOT change the server value, so if the server ever sees a value above the
	configured ceiling, something (a rogue server-side script, a compromised
	remote, or a mis-set value) pushed it there — correct it and flag.

	God mode: track authorized damage; if health never falls after damage that
	Sentinel recorded, the humanoid is likely locked.
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Config = require(ReplicatedStorage.SentinelShared.Config)
local Registry = require(script.Parent.Parent.Core.Registry)
local Profile = require(script.Parent.Parent.Core.Profile)

local C = { name = "Character" }

-- Exemptions let a game legitimately exceed a ceiling (e.g. a speed powerup).
-- Sentinel.exempt(player, "WalkSpeed", value) raises the allowed ceiling.
local exemptions: { [Player]: { [string]: number } } = {}
function C.exempt(player: Player, prop: string, value: number)
	exemptions[player] = exemptions[player] or {}
	exemptions[player][prop] = value
end
function C.clearExempt(player: Player)
	exemptions[player] = nil
end

local function ceiling(player: Player, prop: string, base: number): number
	local ex = exemptions[player]
	if ex and ex[prop] then
		return math.max(base, ex[prop])
	end
	return base
end

function C.sample(prof: Profile.Profile, _now: number)
	if not Config.Character.Enabled then
		return
	end
	local player = prof.player
	local character = player.Character
	if not character then
		return
	end
	local humanoid = character:FindFirstChildOfClass("Humanoid")
	if not humanoid then
		return
	end

	-- WalkSpeed
	local maxWalk = ceiling(player, "WalkSpeed", Config.Character.MaxWalkSpeed)
	if humanoid.WalkSpeed > maxWalk then
		Registry.report(player, "CharacterWalkSpeed", Config.Character.Weights.WalkSpeed,
			("WalkSpeed %.0f > %.0f"):format(humanoid.WalkSpeed, maxWalk))
		if Config.Character.Correct then
			humanoid.WalkSpeed = maxWalk
		end
	end

	-- Jump (either JumpPower or JumpHeight depending on the humanoid's mode)
	local maxJump = ceiling(player, "JumpPower", Config.Character.MaxJumpPower)
	if humanoid.UseJumpPower and humanoid.JumpPower > maxJump then
		Registry.report(player, "CharacterJumpPower", Config.Character.Weights.JumpPower,
			("JumpPower %.0f > %.0f"):format(humanoid.JumpPower, maxJump))
		if Config.Character.Correct then
			humanoid.JumpPower = maxJump
		end
	end

	-- HipHeight (used for hover/step exploits)
	local maxHip = ceiling(player, "HipHeight", Config.Character.MaxHipHeight)
	if humanoid.HipHeight > maxHip then
		Registry.report(player, "CharacterHipHeight", Config.Character.Weights.HipHeight,
			("HipHeight %.1f > %.1f"):format(humanoid.HipHeight, maxHip))
		if Config.Character.Correct then
			humanoid.HipHeight = maxHip
		end
	end
end

--[[
	God-mode support. The game calls Sentinel.Character.damage(player, amount)
	instead of humanoid:TakeDamage directly; Sentinel applies it AND remembers the
	expected post-damage health. If a later sample shows health did not drop as
	expected, the humanoid is likely locked by an exploit-side script.
]]
local expectedHealth: { [Player]: number } = {}

function C.damage(player: Player, amount: number)
	local character = player.Character
	if not character then
		return
	end
	local humanoid = character:FindFirstChildOfClass("Humanoid")
	if not humanoid then
		return
	end
	local before = humanoid.Health
	humanoid:TakeDamage(amount)
	expectedHealth[player] = math.max(0, before - amount)
end

function C.checkGodMode(prof: Profile.Profile)
	if not Config.Character.GodModeCheck then
		return
	end
	local player = prof.player
	local expected = expectedHealth[player]
	if expected == nil then
		return
	end
	local character = player.Character
	local humanoid = character and character:FindFirstChildOfClass("Humanoid")
	if not humanoid then
		return
	end
	-- Allow a small margin for regen scripts running the same frame.
	if humanoid.Health > expected + 2 then
		Registry.report(player, "GodMode", Config.Character.Weights.GodMode,
			("health %.0f exceeds expected %.0f after damage"):format(humanoid.Health, expected))
	end
	expectedHealth[player] = nil
end

function C.onPlayerRemoving(player: Player)
	exemptions[player] = nil
	expectedHealth[player] = nil
end

return C
