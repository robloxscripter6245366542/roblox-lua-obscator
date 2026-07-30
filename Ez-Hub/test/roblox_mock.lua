-- Mock Roblox + Luau environment for headless testing of Ez Hub scripts.
-- Not a faithful emulator — it exists to catch load-time and callback CRASHES
-- (nil calls, wrong methods/arity, bad member access) that syntax checks miss.
-- Value math (Vector/CFrame/UDim2) is approximate but arithmetic-safe.

--=============================================================== Luau stdlib
function math.clamp(x, lo, hi) if x < lo then return lo elseif x > hi then return hi else return x end end
function math.round(x) return math.floor(x + 0.5) end
function math.sign(x) return (x > 0 and 1) or (x < 0 and -1) or 0 end
if not table.find then function table.find(t, v) for i, x in ipairs(t) do if x == v then return i end end end end
if not table.unpack then table.unpack = unpack end

-- typeof: report roblox-ish types via a tag, else fall back to Lua type().
local function tagged(t, name) return setmetatable(t, { __rbx = name }) end
function typeof(v)
	local mt = type(v) == "table" and getmetatable(v)
	if mt and mt.__rbx then return mt.__rbx end
	return type(v)
end
_G.typeof = typeof

-- task / threading (run synchronously enough to exercise code once)
-- task.wait yields inside coroutines (so `while true do task.wait() end` loops
-- suspend instead of spinning), and returns immediately at top level.
local function waitImpl() if coroutine.isyieldable() then coroutine.yield() end return 0 end
-- task.spawn runs the fn in a coroutine; a loop that hits task.wait suspends and
-- never resumes (fine for a one-shot load test), so no infinite loops.
local function spawnImpl(fn, ...)
	if type(fn) ~= "function" then return end
	local co = coroutine.create(fn)
	local ok, err = coroutine.resume(co, ...)
	if not ok then error(err, 0) end
end
task = {
	wait = waitImpl,
	spawn = spawnImpl,
	delay = function(a, fn, ...) if type(a) == "function" then spawnImpl(a) elseif type(fn) == "function" then spawnImpl(fn, ...) end end,
	defer = function(fn, ...) spawnImpl(fn, ...) end,
	cancel = function() end,
}
wait = waitImpl
spawn = spawnImpl
function delay(_, fn) if fn then spawnImpl(fn) end end
function tick() return 0 end
function warn(...) end

--=============================================================== value types
local function vec(name, fields)
	local V = {}
	V.__index = V
	V.__rbx = name
	V.__add = function(a, b) return setmetatable({ X = (a.X or 0) + (b.X or 0), Y = (a.Y or 0) + (b.Y or 0), Z = (a.Z or 0) + (b.Z or 0) }, V) end
	V.__sub = function(a, b) return setmetatable({ X = (a.X or 0) - (b.X or 0), Y = (a.Y or 0) - (b.Y or 0), Z = (a.Z or 0) - (b.Z or 0) }, V) end
	V.__mul = function(a, b) local s = type(b) == "number" and b or 1; return setmetatable({ X = (a.X or 0) * s, Y = (a.Y or 0) * s, Z = (a.Z or 0) * s }, V) end
	V.__div = function(a, b) local s = type(b) == "number" and b or 1; if s == 0 then s = 1 end; return setmetatable({ X = (a.X or 0) / s, Y = (a.Y or 0) / s, Z = (a.Z or 0) / s }, V) end
	V.__unm = function(a) return setmetatable({ X = -(a.X or 0), Y = -(a.Y or 0), Z = -(a.Z or 0) }, V) end
	V.Magnitude = 0
	V.magnitude = 0
	function V.new(x, y, z) return setmetatable({ X = x or 0, Y = y or 0, Z = z or 0, Magnitude = 0, magnitude = 0 }, V) end
	V.zero = V.new(0, 0, 0)
	return V
end
Vector2 = vec("Vector2")
Vector3 = vec("Vector3")

local CFrameMT = {}
CFrameMT.__index = CFrameMT
CFrameMT.__rbx = "CFrame"
CFrameMT.__mul = function(a, b) return a end
local function newCFrame()
	return setmetatable({
		Position = Vector3.new(), p = Vector3.new(),
		LookVector = Vector3.new(0, 0, -1), RightVector = Vector3.new(1, 0, 0), UpVector = Vector3.new(0, 1, 0),
		XVector = Vector3.new(1, 0, 0), YVector = Vector3.new(0, 1, 0), ZVector = Vector3.new(0, 0, 1),
	}, CFrameMT)
end
function CFrameMT:ToWorldSpace() return self end
function CFrameMT:ToObjectSpace() return self end
function CFrameMT:PointToObjectSpace() return Vector3.new() end
function CFrameMT:VectorToObjectSpace() return Vector3.new() end
function CFrameMT:GetComponents() return 0,0,0,0,0,0,0,0,0,0,0,0 end
function CFrameMT:ToEulerAnglesYXZ() return 0, 0, 0 end
function CFrameMT:Lerp() return self end
CFrame = {
	new = function() return newCFrame() end,
	Angles = function() return newCFrame() end,
	fromEulerAnglesYXZ = function() return newCFrame() end,
	fromMatrix = function() return newCFrame() end,
	lookAt = function() return newCFrame() end,
}

local function simple(name, ctor)
	local M = { __rbx = name }
	M.__index = M
	return setmetatable({ new = ctor and function(...) return setmetatable(ctor(...), M) end or function(...) return setmetatable({ args = { ... } }, M) end },
		{ __index = function() return function(...) return setmetatable({ args = { ... } }, M) end end })
end

UDim = { new = function(s, o) return { Scale = s or 0, Offset = o or 0 } end }
UDim2 = {
	new = function(xs, xo, ys, yo) return { X = { Scale = xs or 0, Offset = xo or 0 }, Y = { Scale = ys or 0, Offset = yo or 0 } } end,
	fromOffset = function(x, y) return UDim2.new(0, x, 0, y) end,
	fromScale = function(x, y) return UDim2.new(x, 0, y, 0) end,
}
local Color3MT = { __rbx = "Color3" }
Color3MT.__index = { ToHSV = function() return 0, 0, 0 end, Lerp = function(self) return self end, ToHex = function() return "ffffff" end, ToHSVA = function() return 0, 0, 0, 1 end }
local function mkColor(r, g, b) return setmetatable({ R = r or 0, G = g or 0, B = b or 0 }, Color3MT) end
Color3 = {
	new = function(r, g, b) return mkColor(r, g, b) end,
	fromRGB = function(r, g, b) return mkColor((r or 0) / 255, (g or 0) / 255, (b or 0) / 255) end,
	fromHSV = function() return mkColor(0, 0, 0) end,
	fromHex = function() return mkColor(1, 1, 1) end,
}
BrickColor = { new = function() return { Color = Color3.new() } end }
Rect = { new = function() return {} end }
Region3 = { new = function() return {} end }
NumberRange = { new = function() return {} end }
NumberSequence = { new = function() return {} end }
ColorSequence = { new = function() return {} end }
NumberSequenceKeypoint = { new = function() return {} end }
ColorSequenceKeypoint = { new = function() return {} end }
TweenInfo = { new = function(...) return { args = { ... } } end }
Font = { new = function() return { __rbx = "Font" } end }
PhysicalProperties = { new = function() return {} end }

RaycastParams = { new = function() return { FilterType = nil, FilterDescendantsInstances = {} } end }

-- Color3 value objects need :ToHSV(); patch fromRGB/new returns
local _c3new, _c3rgb, _c3hsv = Color3.new, Color3.fromRGB, Color3.fromHSV
local function withHSV(c) c.ToHSV = color3ToHSV; return c end

--=============================================================== Enum
local EnumItemMT = { __rbx = "EnumItem" }
EnumItemMT.__index = EnumItemMT
local function enumItem(enumType, name) return setmetatable({ Name = name, Value = 0, EnumType = enumType }, EnumItemMT) end
Enum = setmetatable({}, {
	__index = function(_, enumType)
		return setmetatable({}, {
			__index = function(_, k) return enumItem(enumType, k) end,
			__rbx = "Enum",
		})
	end,
})

--=============================================================== signals
local ALL_SIGNALS = {}
local SIGNAL_ERRORS = {}
local function newSignal()
	local conns = {}
	local sig = {}
	sig.__rbx = "RBXScriptSignal"
	function sig:Connect(fn)
		local c = { Connected = true, _fn = fn }
		function c:Disconnect() self.Connected = false end
		table.insert(conns, c)
		return setmetatable(c, { __rbx = "RBXScriptConnection" })
	end
	sig.connect = sig.Connect
	function sig:Once(fn) return sig:Connect(fn) end
	function sig:Wait() return end
	function sig:Fire(...)
		for _, c in ipairs(conns) do
			if c.Connected then
				local ok, err = pcall(c._fn, ...)
				if not ok then table.insert(SIGNAL_ERRORS, tostring(err)) end
			end
		end
	end
	table.insert(ALL_SIGNALS, sig)
	return sig
end

-- Fire every connected signal once with a synthetic event, to exercise UI
-- callbacks (button clicks, toggles, input handlers, render loops). Returns a
-- de-duplicated list of errors raised inside those callbacks.
function _G.__fireAllSignals()
	for i = #SIGNAL_ERRORS, 1, -1 do SIGNAL_ERRORS[i] = nil end
	-- A hybrid synthetic event: a mock Instance (so :FindFirstChild etc. work for
	-- CharacterAdded-style signals) that also carries InputObject fields.
	local fake = Instance.new("InputObject")
	fake.UserInputType = Enum.UserInputType.Keyboard
	fake.KeyCode = Enum.KeyCode.E
	fake.Position = Vector3.new(960, 540, 0)
	fake.Delta = Vector3.new(0, 0, 0)
	fake.UserInputState = Enum.UserInputState.Begin
	local snapshot = {}
	for _, s in ipairs(ALL_SIGNALS) do snapshot[#snapshot + 1] = s end
	for _, s in ipairs(snapshot) do pcall(function() s:Fire(fake, false) end) end
	local seen, out = {}, {}
	for _, e in ipairs(SIGNAL_ERRORS) do if not seen[e] then seen[e] = true; out[#out + 1] = e end end
	return table.concat(out, "\n---\n")
end

--=============================================================== Instance
local SIGNAL_NAMES = {
	MouseButton1Click = true, MouseButton1Down = true, MouseButton1Up = true,
	MouseButton2Click = true, MouseEnter = true, MouseLeave = true, MouseMoved = true,
	InputBegan = true, InputChanged = true, InputEnded = true, Changed = true,
	Touched = true, Died = true, CharacterAdded = true, CharacterRemoving = true,
	DescendantAdded = true, DescendantRemoving = true, ChildAdded = true, ChildRemoved = true,
	PlayerAdded = true, PlayerRemoving = true, FocusLost = true, Focused = true,
	JumpRequest = true, Idled = true, Completed = true, MessageOut = true,
	RenderStepped = true, Heartbeat = true, Stepped = true, OnClientEvent = true,
	PromptTriggered = true, StateChanged = true,
}

local DEFAULTS = {} -- key -> function() returns default value
local function defBox() return UDim2.new() end
for _, k in ipairs({ "Position", "Size", "CanvasSize", "CellSize", "CellPadding" }) do DEFAULTS[k] = defBox end
for _, k in ipairs({ "AbsolutePosition", "AbsoluteSize", "AbsoluteContentSize" }) do DEFAULTS[k] = function() return Vector2.new() end end
DEFAULTS.CFrame = function() return CFrame.new() end
DEFAULTS.Rotation = function() return 0 end
DEFAULTS.ZIndex = function() return 1 end
DEFAULTS.Text = function() return "" end
DEFAULTS.Visible = function() return true end
DEFAULTS.Enabled = function() return true end
DEFAULTS.Health = function() return 100 end
DEFAULTS.MaxHealth = function() return 100 end
DEFAULTS.WalkSpeed = function() return 16 end
DEFAULTS.JumpPower = function() return 50 end
DEFAULTS.Value = function() return 0 end
DEFAULTS.FieldOfView = function() return 70 end
DEFAULTS.ViewportSize = function() return Vector2.new(1920, 1080) end
DEFAULTS.CameraType = function() return enumItem("CameraType", "Custom") end
DEFAULTS.TextBounds = function() return Vector2.new() end
DEFAULTS.PlaceId = function() return 0 end
DEFAULTS.JobId = function() return "job" end
DEFAULTS.UserId = function() return 1 end
DEFAULTS.Name = function() return "Instance" end
DEFAULTS.Parent = function() return nil end
DEFAULTS.FloorMaterial = function() return enumItem("Material", "Plastic") end
DEFAULTS.AssemblyLinearVelocity = function() return Vector3.new() end
DEFAULTS.Velocity = function() return Vector3.new() end
DEFAULTS.PrimaryPart = function() return nil end
DEFAULTS.TextFits = function() return true end
DEFAULTS.TeamColor = function() return { Color = Color3.new() } end
DEFAULTS.Team = function() return nil end

local InstanceMT = {}
local function makeInstance(class)
	local self = { _class = class, _props = {}, _children = {}, _signals = {}, _pcs = {} }
	return setmetatable(self, InstanceMT)
end

local METHODS -- forward
InstanceMT.__index = function(t, k)
	if METHODS[k] then return METHODS[k] end
	if SIGNAL_NAMES[k] then
		local s = t._signals[k]; if not s then s = newSignal(); t._signals[k] = s end; return s
	end
	local props = rawget(t, "_props")
	if props[k] ~= nil then return props[k] end
	-- child by name
	for _, ch in ipairs(rawget(t, "_children")) do
		if ch._props.Name == k or ch._class == k then return ch end
	end
	if k == "ClassName" then return rawget(t, "_class") end
	if DEFAULTS[k] then return DEFAULTS[k]() end
	return nil
end
InstanceMT.__newindex = function(t, k, v)
	if k == "Parent" then
		rawget(t, "_props").Parent = v
		if type(v) == "table" and rawget(v, "_children") then table.insert(v._children, t) end
		return
	end
	rawget(t, "_props")[k] = v
end
InstanceMT.__rbx = "Instance"

METHODS = {
	Destroy = function(self) self._props.Parent = nil end,
	Remove = function(self) end,
	Clone = function(self) local c = makeInstance(self._class); for k, v in pairs(self._props) do c._props[k] = v end; return c end,
	ClearAllChildren = function(self) self._children = {} end,
	GetChildren = function(self) local r = {}; for i, c in ipairs(self._children) do r[i] = c end; return r end,
	GetDescendants = function(self)
		local r = {}
		local function walk(n) for _, c in ipairs(n._children) do table.insert(r, c); walk(c) end end
		walk(self); return r
	end,
	FindFirstChild = function(self, name)
		for _, c in ipairs(self._children) do if c._props.Name == name or c._class == name then return c end end
		return nil
	end,
	FindFirstChildOfClass = function(self, cls) for _, c in ipairs(self._children) do if c._class == cls then return c end end end,
	FindFirstChildWhichIsA = function(self, cls) for _, c in ipairs(self._children) do if c._class == cls then return c end end end,
	FindFirstAncestorOfClass = function(self) return nil end,
	WaitForChild = function(self, name)
		local c = METHODS.FindFirstChild(self, name)
		if c then return c end
		c = makeInstance(name); c._props.Name = name; table.insert(self._children, c); c._props.Parent = self; return c
	end,
	IsA = function(self, cls) return self._class == cls end,
	IsDescendantOf = function() return true end,
	GetPropertyChangedSignal = function(self, prop) local key = "pcs_" .. prop; local s = self._signals[key]; if not s then s = newSignal(); self._signals[key] = s end; return s end,
	GetAttribute = function() return nil end,
	SetAttribute = function() end,
	TweenPosition = function(self, pos, _, _, _, _, cb) if type(cb) == "function" then pcall(cb) end return true end,
	TweenSize = function(self, sz, _, _, _, _, cb) if type(cb) == "function" then pcall(cb) end return true end,
	TweenSizeAndPosition = function(self, _, _, _, _, _, _, cb) if type(cb) == "function" then pcall(cb) end return true end,
	GetMouse = function() return makeInstance("Mouse") end,
	ChangeState = function() end,
	Kick = function() error("KICK CALLED", 0) end,
	FireServer = function() end,
	InvokeServer = function() return nil end,
	Fire = function() end,
	Invoke = function() return nil end,
	Play = function() end,
	Stop = function() end,
	LoadAnimation = function() return makeInstance("AnimationTrack") end,
	PivotTo = function() end,
	GetPivot = function() return CFrame.new() end,
	CaptureFocus = function() end,
	ReleaseFocus = function() end,
	GetPlayers = function(self) return self._props._players or {} end,
	GetTeams = function() return {} end,
	Raycast = function() return nil end,
	WorldToViewportPoint = function() return Vector3.new(960, 540, 10), true end,
	WorldToScreenPoint = function() return Vector3.new(960, 540, 10), true end,
	ScreenPointToRay = function() return { Origin = Vector3.new(), Direction = Vector3.new(0, 0, -1) } end,
	GetPartsObscuringTarget = function() return {} end,
	GetUserThumbnailAsync = function() return "" end,
	PreloadAsync = function() end,
	JSONDecode = function(_, s) return {} end,
	JSONEncode = function(_, t) return "{}" end,
	Connect = function() return { Disconnect = function() end } end,
	protect_gui = function() end,
	CaptureController = function() end,
	ClickButton2 = function() end,
	Teleport = function() end,
	TeleportToPlaceInstance = function() end,
	ShakeOnce = function() end,
	GetService = function(self, name) return self:_getService(name) end,
	_getService = function(self, name) return getService(name) end,
	Create = function(self, inst, info, goal)
		local tw = { Completed = newSignal(), PlaybackState = enumItem("PlaybackState", "Begin") }
		function tw:Play() end
		function tw:Cancel() end
		function tw:Pause() end
		return tw
	end,
	GetMouseLocation = function() return Vector2.new(960, 540) end,
	GetMouseDelta = function() return Vector2.new(0, 0) end,
	IsKeyDown = function() return false end,
	GetMouseButtonsPressed = function() return {} end,
	GetPropertyChangedSignalX = function() end,
}

_G.Instance = { new = function(class, parent) local i = makeInstance(class); if parent then i.Parent = parent end; return i end }

--=============================================================== services / game
local services = {}
function getService(name)
	if services[name] then return services[name] end
	local s = makeInstance(name)
	s._props.Name = name
	-- signal-bearing services already handled via SIGNAL_NAMES on access
	services[name] = s
	return s
end
_G.getService = getService

-- Players service with a LocalPlayer
local Players = getService("Players")
local localPlayer = makeInstance("Player")
localPlayer._props.Name = "TestPlayer"
localPlayer._props.UserId = 1
local playerGui = makeInstance("PlayerGui"); playerGui._props.Name = "PlayerGui"; playerGui.Parent = localPlayer
local character = makeInstance("Model"); character._props.Name = "TestPlayer"; character.Parent = nil
local hrp = makeInstance("Part"); hrp._props.Name = "HumanoidRootPart"; hrp.Parent = character
local head = makeInstance("Part"); head._props.Name = "Head"; head.Parent = character
local hum = makeInstance("Humanoid"); hum._props.Name = "Humanoid"; hum.Parent = character
localPlayer._props.Character = character
Players._props.LocalPlayer = localPlayer
Players._props._players = { localPlayer }
function Players.__unused() end

-- Workspace
local Workspace = getService("Workspace")
local camera = makeInstance("Camera"); camera._props.Name = "CurrentCamera"; camera.Parent = Workspace
Workspace._props.CurrentCamera = camera
local currentRooms = makeInstance("Folder"); currentRooms._props.Name = "CurrentRooms"; currentRooms.Parent = Workspace

-- game
local gameObj = makeInstance("DataModel")
gameObj._props.Name = "game"
gameObj._props.PlaceId = 6839171747  -- a supported PlaceId so gated hubs build
gameObj._props.JobId = "test-job"
gameObj._props.CoreGui = getService("CoreGui")
gameObj._props.Players = Players
gameObj._props.Workspace = Workspace
gameObj._props.Lighting = getService("Lighting")
gameObj._props.ReplicatedStorage = getService("ReplicatedStorage")
gameObj.GetService = function(_, name) return getService(name) end
gameObj.HttpGet = function() return "{}" end
gameObj.HttpGetAsync = function() return "{}" end
_G.game = gameObj
_G.workspace = Workspace
_G.Workspace = Workspace
_G.script = makeInstance("LocalScript")

--=============================================================== executor globals
function gethui() return getService("CoreGui") end
function get_hidden_gui() return getService("CoreGui") end
function getgenv() return _G end
function setclipboard() end
function setfpscap() end
function mouse1click() end
function mouse1press() end
function mouse1release() end
function fireproximityprompt() end
function protectgui() end
function loadstring(src) return load(src) end
function getrawmetatable() return {} end
function hookfunction() end
function setreadonly() end
function identifyexecutor() return "MockExecutor", "1.0" end
function isfile() return false end
function isfolder() return false end
function makefolder() end
function writefile() end
function delfile() end
function listfiles() return {} end
function readfile() return "{}" end
syn = { protect_gui = function() end, cache = {} }
Drawing = {
	Fonts = { Monospace = 0, UI = 1 },
	new = function(kind)
		local d = { _kind = kind, Visible = false }
		function d:Remove() end
		return setmetatable(d, { __index = function() return 0 end, __newindex = function(t, k, v) rawset(t, k, v) end })
	end,
}
VirtualUser = { CaptureController = function() end, ClickButton2 = function() end }
VirtualInputManager = {}

-- require: return an empty table (CosmeticLibrary etc.)
local _require = require
function require(m)
	return { Cosmetics = {}, Rarities = {}, init = function(_, cb) if cb then end return {} end }
end

return true
