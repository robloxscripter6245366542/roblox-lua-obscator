--!strict
--[[
	Sentinel Net — hardened RemoteEvent/RemoteFunction layer.
	---------------------------------------------------------------------------
	Games route ALL client->server traffic through Sentinel.Net so that every
	remote automatically gets:
	  * per-player token-bucket rate limiting
	  * argument schema validation (type/shape/size)
	  * payload sanity limits (depth, string length)
	  * automatic suspicion flags on abuse (via a pluggable reporter)

	The point: a remote that isn't registered here is an unknown remote, and an
	exploiter firing a raw remote gets caught by the abuse reporter.

	Schema syntax (tiny + dependency-free):
	  { "number", "string", "?boolean", "Instance:BasePart", "Vector3" }
	  - "?T" marks an optional argument (nil allowed)
	  - "Instance:ClassName" requires an Instance of/inheriting ClassName
	  - "any" accepts anything (still size-checked)
]]

local RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Config = require(script.Parent.Config)

local Net = {}
Net.__index = Net

-- Reporter is injected by the server bootstrap so Net can raise suspicion
-- without depending on the whole detection stack. Signature:
--   reporter(player: Player, category: string, weight: number, detail: string)
local reporter: ((Player, string, number, string) -> ())? = nil
function Net.setReporter(fn: (Player, string, number, string) -> ())
	reporter = fn
end

local function report(player: Player, category: string, weight: number, detail: string)
	if reporter then
		reporter(player, category, weight, detail)
	end
end

---------------------------------------------------------------------------
-- Remote container
---------------------------------------------------------------------------
local FOLDER_NAME = "SentinelRemotes"
local function getRemoteFolder(): Folder
	local existing = ReplicatedStorage:FindFirstChild(FOLDER_NAME)
	if existing and existing:IsA("Folder") then
		return existing
	end
	local folder = Instance.new("Folder")
	folder.Name = FOLDER_NAME
	folder.Parent = ReplicatedStorage
	return folder
end

---------------------------------------------------------------------------
-- Validation helpers
---------------------------------------------------------------------------
local function typeMatches(value: any, spec: string): boolean
	if spec == "any" then
		return true
	end
	local instanceClass = string.match(spec, "^Instance:(.+)$")
	if instanceClass then
		return typeof(value) == "Instance" and value:IsA(instanceClass)
	end
	-- typeof covers Roblox datatypes (Vector3, CFrame, ...) and luau types.
	return typeof(value) == spec
end

-- Returns ok, reason. Enforces depth + string-length caps to stop payload bombs.
local function withinSizeLimits(value: any, depth: number): (boolean, string?)
	if depth > Config.Remotes.MaxArgDepth then
		return false, "arg nesting exceeds MaxArgDepth"
	end
	local t = typeof(value)
	if t == "string" then
		if #value > Config.Remotes.MaxStringLength then
			return false, "string exceeds MaxStringLength"
		end
	elseif t == "table" then
		for k, v in pairs(value) do
			local okK, rK = withinSizeLimits(k, depth + 1)
			if not okK then
				return false, rK
			end
			local okV, rV = withinSizeLimits(v, depth + 1)
			if not okV then
				return false, rV
			end
		end
	end
	return true, nil
end

---------------------------------------------------------------------------
-- Token-bucket rate limiter (per player, per remote)
---------------------------------------------------------------------------
type Bucket = { tokens: number, last: number }
local function makeLimiter(ratePerMinute: number, burst: number)
	local refillPerSecond = ratePerMinute / 60
	local buckets: { [Player]: Bucket } = {}
	return function(player: Player): boolean
		local now = os.clock()
		local b = buckets[player]
		if not b then
			b = { tokens = burst, last = now }
			buckets[player] = b
		end
		b.tokens = math.min(burst, b.tokens + (now - b.last) * refillPerSecond)
		b.last = now
		if b.tokens >= 1 then
			b.tokens -= 1
			return true
		end
		return false
	end, function(player: Player)
		buckets[player] = nil
	end
end

---------------------------------------------------------------------------
-- Registration
---------------------------------------------------------------------------
export type RemoteOptions = {
	name: string,
	schema: { string }?,
	ratePerMinute: number?,
	burst: number?,
	-- The actual server handler. Runs only after all checks pass.
	onServerEvent: ((player: Player, ...any) -> ())?,
	onServerInvoke: ((player: Player, ...any) -> ...any)?,
}

local registered: { [string]: boolean } = {}
local limiterCleanup: { (Player) -> () } = {}

-- Register a RemoteEvent (fire-and-forget, client -> server).
function Net.event(opts: RemoteOptions): RemoteEvent
	assert(RunService:IsServer(), "Net.event must be called on the server")
	assert(not registered[opts.name], "duplicate remote name: " .. opts.name)
	registered[opts.name] = true

	local remote = Instance.new("RemoteEvent")
	remote.Name = opts.name
	remote.Parent = getRemoteFolder()

	local allow, cleanup = makeLimiter(
		opts.ratePerMinute or Config.Remotes.DefaultRatePerMinute,
		opts.burst or Config.Remotes.DefaultBurst
	)
	table.insert(limiterCleanup, cleanup)

	remote.OnServerEvent:Connect(function(player: Player, ...)
		if not Config.Remotes.Enabled then
			if opts.onServerEvent then opts.onServerEvent(player, ...) end
			return
		end

		if not allow(player) then
			report(player, "RateLimit", Config.Remotes.Weights.RateLimit,
				("remote %q over budget"):format(opts.name))
			return
		end

		local args = table.pack(...)
		local okSize, sizeReason = withinSizeLimits(args, 0)
		if not okSize then
			report(player, "BadArgs", Config.Remotes.Weights.BadArgs,
				("remote %q payload rejected: %s"):format(opts.name, sizeReason or "?"))
			return
		end

		if opts.schema then
			for i, spec in ipairs(opts.schema) do
				local optional = string.sub(spec, 1, 1) == "?"
				local realSpec = optional and string.sub(spec, 2) or spec
				local value = args[i]
				if value == nil then
					if not optional then
						report(player, "BadArgs", Config.Remotes.Weights.BadArgs,
							("remote %q missing arg #%d (%s)"):format(opts.name, i, realSpec))
						return
					end
				elseif not typeMatches(value, realSpec) then
					report(player, "BadArgs", Config.Remotes.Weights.BadArgs,
						("remote %q arg #%d expected %s got %s"):format(
							opts.name, i, realSpec, typeof(value)))
					return
				end
			end
		end

		if opts.onServerEvent then
			opts.onServerEvent(player, ...)
		end
	end)

	return remote
end

-- Register a RemoteFunction (request/response). Same guarantees as .event.
function Net.func(opts: RemoteOptions): RemoteFunction
	assert(RunService:IsServer(), "Net.func must be called on the server")
	assert(not registered[opts.name], "duplicate remote name: " .. opts.name)
	registered[opts.name] = true

	local remote = Instance.new("RemoteFunction")
	remote.Name = opts.name
	remote.Parent = getRemoteFolder()

	local allow = makeLimiter(
		opts.ratePerMinute or Config.Remotes.DefaultRatePerMinute,
		opts.burst or Config.Remotes.DefaultBurst
	)

	remote.OnServerInvoke = function(player: Player, ...)
		if not Config.Remotes.Enabled then
			return opts.onServerInvoke and opts.onServerInvoke(player, ...)
		end
		if not allow(player) then
			report(player, "RateLimit", Config.Remotes.Weights.RateLimit,
				("remote %q over budget"):format(opts.name))
			return nil
		end
		local args = table.pack(...)
		local okSize, sizeReason = withinSizeLimits(args, 0)
		if not okSize then
			report(player, "BadArgs", Config.Remotes.Weights.BadArgs,
				("remote %q payload rejected: %s"):format(opts.name, sizeReason or "?"))
			return nil
		end
		if opts.schema then
			for i, spec in ipairs(opts.schema) do
				local optional = string.sub(spec, 1, 1) == "?"
				local realSpec = optional and string.sub(spec, 2) or spec
				local value = args[i]
				if value == nil then
					if not optional then
						report(player, "BadArgs", Config.Remotes.Weights.BadArgs,
							("remote %q missing arg #%d"):format(opts.name, i))
						return nil
					end
				elseif not typeMatches(value, realSpec) then
					report(player, "BadArgs", Config.Remotes.Weights.BadArgs,
						("remote %q arg #%d expected %s got %s"):format(
							opts.name, i, realSpec, typeof(value)))
					return nil
				end
			end
		end
		return opts.onServerInvoke and opts.onServerInvoke(player, ...)
	end

	return remote
end

-- Cleanup limiter state when a player leaves (prevents leaks).
function Net.onPlayerRemoving(player: Player)
	for _, cleanup in ipairs(limiterCleanup) do
		cleanup(player)
	end
end

return Net
