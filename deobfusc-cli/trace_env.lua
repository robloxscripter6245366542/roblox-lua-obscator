-- ============================================================================
--  trace_env.lua — instrumented Roblox env that LOGS every observable action
--  so reconstruct.py can regenerate clean Lua. Records, in execution order:
--    NEW <id> <ClassName>
--    SET <id> <prop> <serialized-value>
--    CALL <id> <method> <serialized-args>
--    CONN <id> <Event>
--  Values are serialized to Lua source (literals, vN refs, datatype ctors).
-- ============================================================================
local TRACE = assert(io.open(os.getenv("TRACE_OUT") or "/tmp/trace.txt", "w"))
local function emit(line) TRACE:write(line.."\n") TRACE:flush() end

local idof = setmetatable({}, {__mode="k"})   -- instance/object -> id
local nextid = 0
local function newid(obj, kind) nextid = nextid + 1; idof[obj] = "v"..nextid; return idof[obj] end

-- serialize a value to Lua source ------------------------------------------------
local function q(s) return string.format("%q", s) end
local serialize
serialize = function(v, depth)
  depth = depth or 0
  local t = type(v)
  if t == "number" then return (math.type(v)=="integer" and tostring(v) or string.format("%.6g", v)) end
  if t == "string" then return q(v) end
  if t == "boolean" then return tostring(v) end
  if t == "nil" then return "nil" end
  if t == "table" then
    if idof[v] then return idof[v] end                 -- instance reference
    if v.__ctor then return v.__ctor end               -- datatype: stored ctor source
    if v.__enum then return "Enum."..tostring(v.EnumType).."."..tostring(v.Name) end
    if depth < 2 then
      local parts = {}
      for k, vv in pairs(v) do
        if type(k)=="string" and k:match("^[%a_][%w_]*$") then
          parts[#parts+1] = k.."="..serialize(vv, depth+1)
        end
      end
      return "{"..table.concat(parts, ", ").."}"
    end
    return "{}"
  end
  return "nil--["..t.."]"
end

-- datatypes carry a __ctor string so they round-trip to source --------------------
local function dt(name, fmt)
  return function(...)
    local a = {...}
    local args = {}
    for i=1,select("#","...") do end
    for i,x in ipairs(a) do args[i] = serialize(x) end
    local o = { __type=name, __ctor = name.."("..table.concat(args, ", ")..")" }
    -- expose common numeric fields so arithmetic in the script survives
    return setmetatable(o, {__index=function() return 0 end,
      __add=function() return o end,__sub=function() return o end,
      __mul=function() return o end,__div=function() return o end,
      __tostring=function() return o.__ctor end})
  end
end
local function dtlib(name) return setmetatable({new=dt(name..".new")},
  {__index=function(_,k) return dt(name.."."..k) end}) end

local Vector3=dtlib("Vector3"); Vector3.new=dt("Vector3.new")
local Vector2={new=dt("Vector2.new")}
local UDim={new=dt("UDim.new")}
local UDim2={new=dt("UDim2.new"), fromScale=dt("UDim2.fromScale"), fromOffset=dt("UDim2.fromOffset")}
local Color3={new=dt("Color3.new"), fromRGB=dt("Color3.fromRGB"), fromHSV=dt("Color3.fromHSV"), fromHex=dt("Color3.fromHex")}
local CFrame=setmetatable({new=dt("CFrame.new"), Angles=dt("CFrame.Angles")},{__index=function(_,k) return dt("CFrame."..k) end})
local TweenInfo={new=dt("TweenInfo.new")}
local NumberRange={new=dt("NumberRange.new")}
local Rect={new=dt("Rect.new")}
local ColorSequence={new=dt("ColorSequence.new")}
local NumberSequence={new=dt("NumberSequence.new")}
local ColorSequenceKeypoint={new=dt("ColorSequenceKeypoint.new")}
local NumberSequenceKeypoint={new=dt("NumberSequenceKeypoint.new")}
local Font=setmetatable({new=dt("Font.new")},{__index=function(_,k) return dt("Font."..k) end})
local BrickColor=setmetatable({new=dt("BrickColor.new")},{__index=function(_,k) return dt("BrickColor."..k) end})

-- Enum (auto-vivify, serializable) -----------------------------------------------
local Enum = setmetatable({}, { __index = function(_, k)
  return setmetatable({}, { __index = function(_, item)
    return setmetatable({__enum=true, EnumType=k, Name=item}, {}) end,
    __tostring=function() return "Enum."..tostring(k) end }) end })

-- Signal -------------------------------------------------------------------------
local Signal = {}; Signal.__index = Signal
local function newSignal(owner, name)
  return setmetatable({_owner=owner, _name=name}, Signal) end
function Signal:Connect(fn) if idof[self._owner] then emit("CONN "..idof[self._owner].." ".._evname(self)) end
  return {Connected=true, Disconnect=function() end} end
function _evname(s) return s._name or "Event" end
Signal.connect=Signal.Connect
function Signal:Once(fn) return self:Connect(fn) end
function Signal:Wait() if rawget(_G,"__TICK") then __TICK() end return end
function Signal:Fire(...) end

-- Instance -----------------------------------------------------------------------
local function newInstance(class)
  local children, props, events = {}, {}, {}
  local self = setmetatable({}, {})
  local id = newid(self, "inst")
  emit("NEW "..id.." "..class)
  local methods
  local function ev(name) if not events[name] then events[name]=newSignal(self,name) end return events[name] end
  getmetatable(self).__index = function(_, k)
    if k=="ClassName" then return class end
    if k=="Name" then return props.Name or class end
    if k=="Parent" then return props.Parent end
    if methods[k] then return methods[k] end
    if type(k)=="string" and k:match("^%u") and (k:find("Click") or k:find("Mouse") or k:find("Began")
        or k:find("Ended") or k:find("Changed") or k:find("Child") or k:find("Descendant")
        or k:find("Focus") or k:find("Activated") or k:find("Touched") or k=="Heartbeat"
        or k=="RenderStepped" or k=="Stepped") then return ev(k) end
    if props[k] ~= nil then return props[k] end
    return 0
  end
  getmetatable(self).__newindex = function(_, k, v)
    props[k] = v
    -- only log real data properties (Size, Text, Color…); skip function/method
    -- assignments which are environment setup, not script-visible behaviour.
    if type(v) ~= "function" then
      emit("SET "..id.." "..tostring(k).." "..serialize(v))
    end
  end
  getmetatable(self).__tostring = function() return props.Name or class end
  methods = {
    FindFirstChild=function(_,n) for _,c in ipairs(children) do if (c.Name)==n then return c end end end,
    WaitForChild=function(_,n) for _,c in ipairs(children) do if (c.Name)==n then return c end end return newInstance("Instance") end,
    GetChildren=function() local t={} for i,c in ipairs(children) do t[i]=c end return t end,
    GetDescendants=function() return {} end,
    IsA=function(_,c2) return c2==class or c2=="Instance" or c2=="GuiObject" end,
    Clone=function() return newInstance(class) end,
    Destroy=function() emit("CALL "..id.." Destroy ") end,
    Remove=function() end, ClearAllChildren=function() end,
    GetPropertyChangedSignal=function() return ev("Changed") end,
    GetAttribute=function() return nil end, SetAttribute=function() end,
    TweenSize=function() end, TweenPosition=function() end,
    GetService=function(_,n) return self end,
  }
  return self
end
local Instance = { new = function(class, parent)
  local i = newInstance(class or "Instance")
  if parent then i.Parent = parent end
  return i
end }

-- DataModel / services -----------------------------------------------------------
local services = {}
local function service(name)
  if services[name] then return services[name] end
  local s = newInstance(name); s.Name = name
  if name=="Players" then local lp=newInstance("Player"); lp.Name="LocalPlayer"; s.LocalPlayer=lp
    s.GetPlayers=function() return {lp} end end
  if name=="RunService" then s.IsClient=function() return true end s.IsServer=function() return false end
    s.IsStudio=function() return false end
    s.Heartbeat=newSignal(s,"Heartbeat") s.RenderStepped=newSignal(s,"RenderStepped") s.Stepped=newSignal(s,"Stepped") end
  if name=="HttpService" then
    s.RequestAsync=function(_,o) emit("HTTP RequestAsync "..serialize(o)) return {Success=true,StatusCode=200,Body="{}",Headers={}} end
    s.GetAsync=function(_,u) emit("HTTP GetAsync "..serialize(u)) return "" end
    s.PostAsync=function(_,u,b) emit("HTTP PostAsync "..serialize(u).." "..serialize(b)) return "" end
    s.JSONEncode=function(_,t) return "{}" end s.JSONDecode=function() return {} end
    s.GenerateGUID=function() return "{GUID}" end end
  services[name]=s
  return s
end
local game = newInstance("DataModel")
game.GetService = function(_, n) return service(n) end
game.HttpGet = function(_, u) emit("HTTP HttpGet "..serialize(u)) return "" end
game.HttpGetAsync = game.HttpGet

return {
  game=game, workspace=service("Workspace"), Instance=Instance, Enum=Enum,
  Vector3=Vector3, Vector2=Vector2, UDim=UDim, UDim2=UDim2, Color3=Color3, CFrame=CFrame,
  TweenInfo=TweenInfo, NumberRange=NumberRange, Rect=Rect, ColorSequence=ColorSequence,
  NumberSequence=NumberSequence, ColorSequenceKeypoint=ColorSequenceKeypoint,
  NumberSequenceKeypoint=NumberSequenceKeypoint, Font=Font, BrickColor=BrickColor,
  newSignal=newSignal,
}
