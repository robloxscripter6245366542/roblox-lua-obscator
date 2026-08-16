--!nocheck
-- ============================================================================
--  Phantom Ball offline sandbox — mock Roblox harness (prelude)
--
--  This file is CONCATENATED in front of the real user_scripts/phantom_ballz.lua
--  and a test epilogue, then run under the Luau CLI. It installs just enough of a
--  mock Roblox API (as globals) for the real script — embedded Leviathan UI and
--  all — to load and run, so the epilogue can drive the actual internal
--  functions (setSpam/setVis/setFx/updIcons) and assert real behaviour.
--
--  Everything here is a GLOBAL so (a) the loaded script sees it and (b) it does
--  not consume the main chunk's local-variable budget.
-- ============================================================================

unpack = unpack or table.unpack
tick = os.clock
-- The Luau CLI's real _G is frozen; NeverZen writes _G.NZ_RESET etc. Shadow it
-- with a writable table (only explicit _G.x accesses are affected).
_G = {}
_ERRORS = {}
local function recordErr(where, err) _ERRORS[#_ERRORS + 1] = tostring(where) .. ": " .. tostring(err) end

-- ── Permissive "universal" value: callable, indexable, returns itself ────────
local U_mt = {}
UNIVERSAL = setmetatable({ __u = true }, U_mt)
local function num0() return 0 end
U_mt.__index = function() return UNIVERSAL end
U_mt.__newindex = function() end
U_mt.__call = function() return UNIVERSAL end
U_mt.__add = num0; U_mt.__sub = num0; U_mt.__mul = num0; U_mt.__div = num0
U_mt.__mod = num0; U_mt.__pow = num0; U_mt.__unm = num0; U_mt.__len = num0
U_mt.__concat = function() return "" end
U_mt.__lt = function() return false end
U_mt.__le = function() return false end
U_mt.__tostring = function() return "<universal>" end

-- ── Signal (firable, counts live connections) ────────────────────────────────
function Signal()
	local s = { _h = {}, connects = 0, live = 0 }
	function s:Connect(fn)
		self.connects = self.connects + 1
		self.live = self.live + 1
		self._h[#self._h + 1] = fn
		local c = { Connected = true }
		function c:Disconnect()
			if not self.Connected then return end
			self.Connected = false
			s.live = s.live - 1
			for i, h in ipairs(s._h) do if h == fn then table.remove(s._h, i) break end end
		end
		c.disconnect = c.Disconnect
		return c
	end
	s.Once = s.Connect
	function s:Wait() return end
	function s:Fire(...)
		local snapshot = {}
		for i, h in ipairs(self._h) do snapshot[i] = h end
		for _, h in ipairs(snapshot) do
			local ok, err = pcall(h, ...)
			if not ok then recordErr("signal", err) end
		end
	end
	return s
end

-- ── Instance mock: permissive, but tracks Name/ClassName/Parent + a few evts ─
function makeInstance(className)
	local inst
	local props = { ClassName = className or "Instance", Name = className or "Instance" }
	local events = {}
	local children = {}
	local mt = {}
	mt.__index = function(_, k)
		if props[k] ~= nil then return props[k] end
		-- Firable events NeverZen/Phantom may connect to.
		if k == "InputBegan" or k == "InputEnded" or k == "InputChanged"
			or k == "MouseButton1Click" or k == "MouseButton1Down" or k == "MouseButton1Up"
			or k == "MouseEnter" or k == "MouseLeave" or k == "TouchTap"
			or k == "AncestryChanged" or k == "ChildAdded" or k == "DescendantAdded"
			or k == "Changed" then
			if not events[k] then events[k] = Signal() end
			return events[k]
		end
		if k == "GetPropertyChangedSignal" then
			return function(_, _) return Signal() end
		end
		if k == "FindFirstChild" or k == "FindFirstChildOfClass" or k == "FindFirstChildWhichIsA" then
			return function(_, name) return children[name] end
		end
		if k == "WaitForChild" then
			return function(_, name) return children[name] end
		end
		if k == "GetChildren" or k == "GetDescendants" then
			return function() local t = {} for _, v in pairs(children) do t[#t + 1] = v end return t end
		end
		if k == "IsA" then return function() return true end end
		if k == "IsDescendantOf" then return function() return true end end
		if k == "GetAttribute" then return function() return nil end end
		if k == "SetAttribute" then return function() end end
		if k == "Destroy" or k == "Remove" then return function() props.Parent = nil end end
		if k == "Clone" then return function() return makeInstance(className) end end
		-- Anything else → permissive no-op that stays chainable.
		return UNIVERSAL
	end
	mt.__newindex = function(_, k, v) props[k] = v end
	mt.__tostring = function() return "Instance<" .. tostring(props.ClassName) .. ">" end
	inst = setmetatable({ __roblox = true, __events = events, __children = children }, mt)
	return inst
end

-- ── typeof ───────────────────────────────────────────────────────────────────
function typeof(x)
	local t = type(x)
	if t ~= "table" then return t end
	local mt = getmetatable(x)
	if mt and mt.__typename then return mt.__typename end
	if rawget(x, "__roblox") then return "Instance" end
	if rawget(x, "__enumitem") then return "EnumItem" end
	if x == UNIVERSAL then return "Instance" end
	return "table"
end

-- ── Datatypes ────────────────────────────────────────────────────────────────
local function typed(name, tbl) return setmetatable(tbl, { __typename = name }) end
Color3 = {
	fromRGB = function(r, g, b) return typed("Color3", { R = (r or 0) / 255, G = (g or 0) / 255, B = (b or 0) / 255 }) end,
	new = function(r, g, b) return typed("Color3", { R = r or 0, G = g or 0, B = b or 0 }) end,
	fromHSV = function() return typed("Color3", { R = 0, G = 0, B = 0 }) end,
}
UDim = { new = function(s, o) return typed("UDim", { Scale = s or 0, Offset = o or 0 }) end }
UDim2 = {
	new = function(xs, xo, ys, yo) return typed("UDim2", { X = { Scale = xs or 0, Offset = xo or 0 }, Y = { Scale = ys or 0, Offset = yo or 0 } }) end,
	fromScale = function(x, y) return UDim2.new(x, 0, y, 0) end,
	fromOffset = function(x, y) return UDim2.new(0, x, 0, y) end,
}
Vector2 = { new = function(x, y) return typed("Vector2", { X = x or 0, Y = y or 0 }) end }
-- Vector3 with real math, so the parry/clash decision can be exercised offline.
local V3mt = {}
V3mt.__typename = "Vector3"
local function v3(x, y, z) return setmetatable({ X = x or 0, Y = y or 0, Z = z or 0 }, V3mt) end
V3mt.__index = function(t, k)
	if k == "Magnitude" then return math.sqrt(t.X * t.X + t.Y * t.Y + t.Z * t.Z) end
	if k == "Unit" then
		local m = math.sqrt(t.X * t.X + t.Y * t.Y + t.Z * t.Z)
		if m == 0 then return v3(0, 0, 0) end
		return v3(t.X / m, t.Y / m, t.Z / m)
	end
	if k == "Dot" then return function(self, o) return self.X * o.X + self.Y * o.Y + self.Z * o.Z end end
	return nil
end
V3mt.__add = function(a, b) return v3(a.X + b.X, a.Y + b.Y, a.Z + b.Z) end
V3mt.__sub = function(a, b) return v3(a.X - b.X, a.Y - b.Y, a.Z - b.Z) end
V3mt.__mul = function(a, b)
	if type(b) == "number" then return v3(a.X * b, a.Y * b, a.Z * b) end
	if type(a) == "number" then return v3(b.X * a, b.Y * a, b.Z * a) end
	return v3(a.X * b.X, a.Y * b.Y, a.Z * b.Z)
end
V3mt.__div = function(a, b)
	if type(b) == "number" then return v3(a.X / b, a.Y / b, a.Z / b) end
	return v3(a.X / b.X, a.Y / b.Y, a.Z / b.Z)
end
V3mt.__unm = function(a) return v3(-a.X, -a.Y, -a.Z) end
Vector3 = { new = v3, zero = v3(0, 0, 0) }
CFrame = setmetatable({ new = function() return typed("CFrame", {}) end, Angles = function() return typed("CFrame", {}) end },
	{ __index = function() return function() return typed("CFrame", {}) end end })
TweenInfo = { new = function(...) return typed("TweenInfo", { args = { ... } }) end }
Rect = { new = function() return typed("Rect", {}) end }
NumberSequenceKeypoint = { new = function() return typed("NumberSequenceKeypoint", {}) end }
ColorSequenceKeypoint = { new = function() return typed("ColorSequenceKeypoint", {}) end }
NumberSequence = { new = function() return typed("NumberSequence", {}) end }
ColorSequence = { new = function() return typed("ColorSequence", {}) end }
NumberRange = { new = function() return typed("NumberRange", {}) end }
Font = setmetatable({ new = function() return typed("Font", {}) end }, { __index = function() return UNIVERSAL end })

Instance = { new = function(cls) return makeInstance(cls) end }

-- ── Enum (memoized, distinct, stable items) ──────────────────────────────────
Enum = setmetatable({}, {
	__index = function(self, cat)
		local c = rawget(self, "__cats")
		if not c then c = {} rawset(self, "__cats", c) end
		if not c[cat] then
			c[cat] = setmetatable({}, {
				__index = function(t, item)
					local items = rawget(t, "__items")
					if not items then items = {} rawset(t, "__items", items) end
					if not items[item] then
						items[item] = setmetatable({ __enumitem = true, Name = item, Value = 0, EnumType = cat }, { __typename = "EnumItem" })
					end
					return items[item]
				end,
			})
		end
		return c[cat]
	end,
})

-- ── Cooperative task scheduler ───────────────────────────────────────────────
_PARKED = {}
_READY = {}
task = {}
function task.spawn(fn, ...)
	local co = coroutine.create(fn)
	local ok, err = coroutine.resume(co, ...)
	if not ok then recordErr("spawn", err)
	elseif coroutine.status(co) ~= "dead" then _PARKED[#_PARKED + 1] = co end
	return co
end
function task.defer(fn, ...) _READY[#_READY + 1] = { fn = fn, args = { ... } } return nil end
function task.delay(_, fn, ...) _READY[#_READY + 1] = { fn = fn, args = { ... } } return nil end
function task.wait(_) coroutine.yield() return 0 end
function task.cancel() end
wait = task.wait
spawn = task.spawn
delay = function(t, fn, ...) return task.delay(t, fn, ...) end

function DRAIN(cycles)
	for _ = 1, cycles or 6 do
		-- start any deferred/ready functions
		while #_READY > 0 do
			local item = table.remove(_READY, 1)
			local co = coroutine.create(item.fn)
			local ok, err = coroutine.resume(co, unpack(item.args))
			if not ok then recordErr("ready", err)
			elseif coroutine.status(co) ~= "dead" then _PARKED[#_PARKED + 1] = co end
		end
		-- resume everything parked on a task.wait once
		local list = _PARKED
		_PARKED = {}
		for _, co in ipairs(list) do
			local ok, err = coroutine.resume(co)
			if not ok then recordErr("resume", err)
			elseif coroutine.status(co) ~= "dead" then _PARKED[#_PARKED + 1] = co end
		end
	end
end

-- ── In-memory filesystem (executor fs shims) ─────────────────────────────────
_DISK = {}
_FOLDERS = {}
function writefile(path, content) _DISK[path] = content end
function readfile(path) return _DISK[path] end
function isfile(path) return _DISK[path] ~= nil end
function isfolder(path) return _FOLDERS[path] == true end
function makefolder(path) _FOLDERS[path] = true end
function delfile(path) _DISK[path] = nil end

-- ── Minimal JSON (objects, arrays, strings, numbers, booleans, null) ─────────
local function jsonEncode(v)
	local t = type(v)
	if t == "nil" then return "null" end
	if t == "boolean" then return v and "true" or "false" end
	if t == "number" then return tostring(v) end
	if t == "string" then return '"' .. v:gsub('[\\"]', '\\%0'):gsub("\n", "\\n") .. '"' end
	if t == "table" then
		-- array?
		local n, isArr = 0, true
		for k in pairs(v) do n = n + 1 if type(k) ~= "number" then isArr = false end end
		if isArr and n > 0 then
			local parts = {}
			for i = 1, n do parts[i] = jsonEncode(v[i]) end
			return "[" .. table.concat(parts, ",") .. "]"
		end
		local parts = {}
		for k, val in pairs(v) do parts[#parts + 1] = '"' .. tostring(k) .. '":' .. jsonEncode(val) end
		return "{" .. table.concat(parts, ",") .. "}"
	end
	return "null"
end
local function jsonDecode(s)
	local i = 1
	local function skip() while i <= #s and s:sub(i, i):match("%s") do i = i + 1 end end
	local parseValue
	local function parseString()
		i = i + 1 -- opening quote
		local buf = {}
		while i <= #s do
			local c = s:sub(i, i)
			if c == "\\" then
				local n = s:sub(i + 1, i + 1)
				buf[#buf + 1] = (n == "n") and "\n" or n
				i = i + 2
			elseif c == '"' then i = i + 1 break
			else buf[#buf + 1] = c i = i + 1 end
		end
		return table.concat(buf)
	end
	local function parseObject()
		local o = {}
		i = i + 1 skip()
		if s:sub(i, i) == "}" then i = i + 1 return o end
		while true do
			skip()
			local key = parseString()
			skip() i = i + 1 -- colon
			o[key] = parseValue()
			skip()
			local c = s:sub(i, i)
			i = i + 1
			if c == "}" then break end
		end
		return o
	end
	local function parseArray()
		local a = {}
		i = i + 1 skip()
		if s:sub(i, i) == "]" then i = i + 1 return a end
		while true do
			a[#a + 1] = parseValue()
			skip()
			local c = s:sub(i, i)
			i = i + 1
			if c == "]" then break end
		end
		return a
	end
	parseValue = function()
		skip()
		local c = s:sub(i, i)
		if c == "{" then return parseObject() end
		if c == "[" then return parseArray() end
		if c == '"' then return parseString() end
		if c == "t" then i = i + 4 return true end
		if c == "f" then i = i + 5 return false end
		if c == "n" then i = i + 4 return nil end
		local j = i
		while i <= #s and s:sub(i, i):match("[%-%d%.eE%+]") do i = i + 1 end
		return tonumber(s:sub(j, i - 1))
	end
	return parseValue()
end

-- ── Services and game tree ───────────────────────────────────────────────────
RUN = makeInstance("RunService")
rawset(RUN, "PostSimulation", Signal())
rawset(RUN, "Heartbeat", Signal())
rawset(RUN, "RenderStepped", Signal())
UIS = makeInstance("UserInputService")
rawset(UIS, "InputBegan", Signal())
rawset(UIS, "InputEnded", Signal())
rawset(UIS, "InputChanged", Signal())
UIS.TouchEnabled = false

WORKSPACE = makeInstance("Workspace")
rawset(WORKSPACE, "DescendantAdded", Signal())
WORKSPACE.CurrentCamera = makeInstance("Camera")
rawset(WORKSPACE, "QueryDescendants", function() return {} end)
workspace = WORKSPACE

LOCALPLAYER = makeInstance("Player")
LOCALPLAYER.Name = "Tester"
LOCALPLAYER.DisplayName = "Tester"
LOCALPLAYER.UserId = 123
rawset(LOCALPLAYER, "CharacterAdded", Signal())
rawset(LOCALPLAYER, "GetMouse", function() return UNIVERSAL end)
LOCALPLAYER.Character = nil

PLAYERS = makeInstance("Players")
PLAYERS.LocalPlayer = LOCALPLAYER

REPLICATEDSTORAGE = makeInstance("ReplicatedStorage")
STARTERGUI = makeInstance("StarterGui")
rawset(STARTERGUI, "SetCore", function() end)

HTTP = makeInstance("HttpService")
rawset(HTTP, "JSONEncode", function(_, v) return jsonEncode(v) end)
rawset(HTTP, "JSONDecode", function(_, s) return jsonDecode(s) end)
rawset(HTTP, "GenerateGUID", function() return "{GUID}" end)

local SERVICES = {
	RunService = RUN, UserInputService = UIS, Players = PLAYERS,
	ReplicatedStorage = REPLICATEDSTORAGE, StarterGui = STARTERGUI, Workspace = WORKSPACE,
	HttpService = HTTP,
}

game = makeInstance("DataModel")
game.GameId = 4538598064
game.PlaceId = 0
rawset(game, "GetService", function(_, name) return SERVICES[name] or makeInstance(name) end)
rawset(game, "FindService", function(_, name) return SERVICES[name] end)
rawset(game, "JobId", "sandbox")

-- ── Globals executors expose (mostly absent → guarded by the script) ─────────
_GENV = {}
function getgenv() return _GENV end
cloneref = nil
hookfunction = nil
hookmetamethod = nil
getgc = nil
setthreadidentity = nil
protectgui = nil
protect_gui = nil
syn = nil
buffer = buffer -- luau provides a real buffer library; fine

function warn(...)
	local parts = {}
	for i = 1, select("#", ...) do parts[i] = tostring((select(i, ...))) end
	print("[warn] " .. table.concat(parts, " "))
end
