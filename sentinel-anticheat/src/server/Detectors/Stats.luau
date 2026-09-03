--!strict
--[[
	Sentinel Stats detector — server-authoritative economy / stat guarding.
	The game mutates watched values ONLY through this API. Sentinel then owns the
	truth for each value, so:
	  * a gain faster than MaxGainPerSecond is rejected (dupe / injection)
	  * a value driven below FloorValue is rejected (underflow / negative money)
	  * if the value is mirrored to an Instance (e.g. a leaderstats IntValue) and
	    something changes that Instance to a value Sentinel didn't author, that is
	    an external write — flagged and corrected.
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Config = require(ReplicatedStorage.SentinelShared.Config)
local Registry = require(script.Parent.Parent.Core.Registry)
local Profile = require(script.Parent.Parent.Core.Profile)

local S = { name = "Stats" }

type Entry = {
	value: number,
	instance: ValueBase?,
	syncing: boolean, -- guards against our own writes tripping the change hook
	lastChange: number,
}
local state: { [Player]: { [string]: Entry } } = {}

local function entryFor(player: Player, name: string): Entry?
	local per = state[player]
	return per and per[name]
end

-- Begin guarding a value. Optionally mirror to an Instance (IntValue/NumberValue)
-- so external writes to that Instance are detected.
function S.watch(player: Player, name: string, initial: number, instance: ValueBase?)
	state[player] = state[player] or {}
	local entry: Entry = {
		value = initial,
		instance = instance,
		syncing = false,
		lastChange = os.clock(),
	}
	state[player][name] = entry

	if instance then
		entry.syncing = true
		;(instance :: any).Value = initial
		entry.syncing = false

		if Config.Stats.DetectExternalWrites then
			instance.Changed:Connect(function(newValue: any)
				if entry.syncing then
					return
				end
				if typeof(newValue) == "number" and newValue ~= entry.value then
					Registry.report(player, "StatExternalWrite", Config.Stats.Weights.ExternalWrite,
						("%q changed to %s outside Sentinel (authored %s)"):format(
							name, tostring(newValue), tostring(entry.value)))
					-- correct back to authored truth
					entry.syncing = true
					;(instance :: any).Value = entry.value
					entry.syncing = false
				end
			end)
		end
	end
end

function S.get(player: Player, name: string): number?
	local e = entryFor(player, name)
	return e and e.value
end

-- Apply a delta with rate + floor validation. Returns the new value (or the
-- unchanged value if rejected).
function S.add(player: Player, name: string, delta: number): number
	local e = entryFor(player, name)
	if not e then
		return 0
	end
	local now = os.clock()
	local dt = math.max(1e-3, now - e.lastChange)

	if delta > 0 then
		local rate = delta / dt
		if rate > Config.Stats.MaxGainPerSecond then
			Registry.report(player, "StatImpossibleRate", Config.Stats.Weights.ImpossibleRate,
				("%q +%s at %.0f/s exceeds %.0f/s"):format(
					name, tostring(delta), rate, Config.Stats.MaxGainPerSecond))
			return e.value -- reject the gain
		end
	end

	local newValue = e.value + delta
	if newValue < Config.Stats.FloorValue then
		Registry.report(player, "StatUnderflow", Config.Stats.Weights.Underflow,
			("%q would drop to %s (floor %s)"):format(
				name, tostring(newValue), tostring(Config.Stats.FloorValue)))
		newValue = Config.Stats.FloorValue
	end

	e.value = newValue
	e.lastChange = now
	if e.instance then
		e.syncing = true
		;(e.instance :: any).Value = newValue
		e.syncing = false
	end
	return newValue
end

-- Hard set (bypasses rate check; use for authoritative resets / loads).
function S.set(player: Player, name: string, value: number)
	local e = entryFor(player, name)
	if not e then
		return
	end
	e.value = math.max(Config.Stats.FloorValue, value)
	e.lastChange = os.clock()
	if e.instance then
		e.syncing = true
		;(e.instance :: any).Value = e.value
		e.syncing = false
	end
end

function S.onPlayerRemoving(player: Player)
	state[player] = nil
end

-- Stats is API-driven, not sampled; sample is a no-op to satisfy the interface.
function S.sample(_prof: Profile.Profile, _now: number) end

return S
