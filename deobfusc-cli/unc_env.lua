-- ============================================================================
--  unc_env.lua — virtual Roblox executor environment (~UNC/sUNC surface)
--  Provides a faithful-enough Roblox runtime so obfuscated hubs execute fully
--  in plain Lua 5.4: Instances, Signals, datatypes, Enum, and the full
--  executor function set. Records every Instance/Signal so the driver can
--  fire UI events (e.g. the key-verify button) to reach gated code paths.
-- ============================================================================
local UNC = {}
local LOG = function(...) io.stderr:write("[unc] "..table.concat({...}, " ").."\n") end

-- ── registries (the driver uses these) ──────────────────────────────────────
UNC.signals   = {}     -- every Signal created, by name
UNC.instances = {}     -- every Instance created
UNC.clicks    = {}     -- MouseButton1Click / Activated signals (UI buttons)

-- ── Signal / RBXScriptSignal ────────────────────────────────────────────────
local Signal = {}
Signal.__index = Signal
local function newSignal(owner, name)
  local s = setmetatable({ _h = {}, _name = name, _owner = owner }, Signal)
  UNC.signals[#UNC.signals + 1] = s
  if name == "MouseButton1Click" or name == "Activated" or name == "MouseButton1Up"
     or name == "MouseButton1Down" then
    UNC.clicks[#UNC.clicks + 1] = s
  end
  return s
end
function Signal:Connect(fn) self._h[#self._h + 1] = fn
  return setmetatable({ Connected = true,
    Disconnect = function(c) c.Connected = false end,
    disconnect = function(c) c.Connected = false end }, {__index=function() return function() end end}) end
Signal.connect = Signal.Connect
function Signal:Once(fn) return self:Connect(fn) end
function Signal:Wait(...) return ... end
function Signal:Fire(...) for _, fn in ipairs(self._h) do pcall(fn, ...) end end
Signal.fire = Signal.Fire

-- ── Enum (full-ish, auto-vivifying) ─────────────────────────────────────────
local EnumItem = setmetatable({}, { __index = function() return setmetatable({Value=0,Name="EnumItem"},
  {__tostring=function() return "Enum.Item" end}) end })
local Enum = setmetatable({}, {
  __index = function(_, k)
    return setmetatable({ _enum = k }, {
      __index = function(_, item) return setmetatable({ Name = item, Value = 0, EnumType = k },
        { __tostring = function() return "Enum."..tostring(k).."."..tostring(item) end }) end,
      __tostring = function() return "Enum."..tostring(k) end,
    })
  end,
  __tostring = function() return "Enum" end,
})

-- ── datatypes ───────────────────────────────────────────────────────────────
local function vecmeta(name, fields)
  local M = {}
  M.__index = function(t, k) if k=="Magnitude" then return 0 end
    if k=="Unit" then return t end return rawget(t,k) or 0 end
  M.__add=function(a,b) return setmetatable({}, M) end
  M.__sub=M.__add; M.__mul=M.__add; M.__div=M.__add
  M.__tostring=function() return name end
  M.__eq=function() return false end
  return function(...)
    local a={...}; local o=setmetatable({},M)
    for i,f in ipairs(fields) do o[f]=a[i] or 0 end
    o.__type=name; return o
  end
end
local Vector3 = { new = vecmeta("Vector3", {"X","Y","Z"}),
  zero=vecmeta("Vector3",{"X"})(), one=vecmeta("Vector3",{"X"})(),
  FromNormalId=function() return vecmeta("Vector3",{"X","Y","Z"})() end,
  FromAxis=function() return vecmeta("Vector3",{"X","Y","Z"})() end }
local Vector2 = { new = vecmeta("Vector2", {"X","Y"}) }
local UDim    = { new = vecmeta("UDim",   {"Scale","Offset"}) }
local UDim2   = { new = vecmeta("UDim2",  {"X","Y"}),
  fromScale=vecmeta("UDim2",{"X","Y"}), fromOffset=vecmeta("UDim2",{"X","Y"}) }
local Color3  = { new = vecmeta("Color3", {"R","G","B"}),
  fromRGB = function(r,g,b) local o=vecmeta("Color3",{"R","G","B"})(r,g,b); return o end,
  fromHSV = vecmeta("Color3",{"R","G","B"}), fromHex = vecmeta("Color3",{"R","G","B"}) }
local CFrame  = setmetatable({ new = vecmeta("CFrame", {"X","Y","Z"}),
  Angles=vecmeta("CFrame",{"X"}), fromEulerAnglesXYZ=vecmeta("CFrame",{"X"}),
  lookAt=vecmeta("CFrame",{"X"}) }, {})
local TweenInfo = { new = function(...) return setmetatable({__type="TweenInfo"},{__index=function() return 0 end}) end }
local NumberRange = { new = vecmeta("NumberRange", {"Min","Max"}) }
local Rect    = { new = vecmeta("Rect", {"Min","Max"}) }
local function seqnew() return setmetatable({__type="Sequence"},{__index=function() return {} end}) end
local ColorSequence  = { new = seqnew }
local NumberSequence = { new = seqnew }
local ColorSequenceKeypoint  = { new = seqnew }
local NumberSequenceKeypoint = { new = seqnew }
local BrickColor = { new=function() return setmetatable({Color=Color3.fromRGB(255,255,255),Name="White"},{}) end,
  Random=function() return BrickColor.new() end }
local Font = { new=function() return setmetatable({__type="Font"},{__index=function() return 0 end}) end,
  fromEnum=function() return Font.new() end, fromName=function() return Font.new() end }
local PhysicalProperties = { new=function() return {} end }
local Ray = { new=function() return setmetatable({},{__index=function() return Vector3.new() end}) end }

-- ── Instance ────────────────────────────────────────────────────────────────
local Instance = {}
local function newInstance(className)
  local children, props, events = {}, {}, {}
  local self
  local function getEvent(name) if not events[name] then events[name]=newSignal(self,name) end return events[name] end
  local methods
  self = setmetatable({}, {
    __index = function(_, k)
      if k=="ClassName" then return className end
      if k=="Name" then return props.Name or className end
      if k=="Parent" then return props.Parent end
      if k=="Children" then return children end
      if methods[k] then return methods[k] end
      -- event?
      if k:match("^[A-Z]") and (k=="Changed" or k=="ChildAdded" or k=="ChildRemoved"
         or k=="DescendantAdded" or k=="DescendantRemoving" or k=="MouseButton1Click"
         or k=="MouseButton1Down" or k=="MouseButton1Up" or k=="MouseEnter" or k=="MouseLeave"
         or k=="Activated" or k=="InputBegan" or k=="InputEnded" or k=="FocusLost"
         or k=="Touched" or k=="Heartbeat" or k=="RenderStepped" or k=="Stepped") then
        return getEvent(k)
      end
      if props[k] ~= nil then return props[k] end
      -- unknown property: return a benign 0/instance-ish so arithmetic & indexing survive
      return 0
    end,
    __newindex = function(_, k, v) props[k] = v end,
    __tostring = function() return props.Name or className end,
  })
  methods = {
    FindFirstChild = function(_, n) for _,c in ipairs(children) do if c.Name==n then return c end end end,
    FindFirstChildOfClass = function(_, c2) for _,c in ipairs(children) do if c.ClassName==c2 then return c end end end,
    FindFirstChildWhichIsA = function(_, c2) for _,c in ipairs(children) do if c.ClassName==c2 then return c end end end,
    FindFirstAncestor = function() return nil end,
    WaitForChild = function(_, n) for _,c in ipairs(children) do if c.Name==n then return c end end return newInstance("Instance") end,
    GetChildren = function() local t={} for i,c in ipairs(children) do t[i]=c end return t end,
    GetDescendants = function() return {} end,
    GetChildrenOfClass = function() return {} end,
    IsA = function(_, c2) return c2==className or c2=="Instance" or c2=="GuiObject" end,
    Clone = function(s) local c=newInstance(className) return c end,
    Destroy = function() end, Remove = function() end,
    ClearAllChildren = function() children={} end,
    GetAttribute = function() return nil end, SetAttribute = function() end,
    GetPropertyChangedSignal = function(_, p) return getEvent("Changed") end,
    GetService = function(_, n) return self end,
    TweenSize=function() end, TweenPosition=function() end,
    Connect = function() return getEvent("Changed"):Connect(function() end) end,
  }
  -- store + auto-parent tracking
  UNC.instances[#UNC.instances + 1] = self
  return self
end
Instance.new = function(className, parent)
  local i = newInstance(className or "Instance")
  if parent then i.Parent = parent end
  return i
end

-- ── DataModel (game) + services ─────────────────────────────────────────────
local services = {}
local function service(name)
  if services[name] then return services[name] end
  local s = newInstance(name)
  s.Name = name
  if name == "Players" then
    local lp = newInstance("Player"); lp.Name="Player"; lp.UserId=1; lp.DisplayName="Player"
    s.LocalPlayer = lp
    s.GetPlayers = function() return {lp} end
  end
  if name == "RunService" then
    s.IsClient=function() return true end; s.IsServer=function() return false end
    s.IsStudio=function() return false end
    s.Heartbeat=newSignal(s,"Heartbeat"); s.RenderStepped=newSignal(s,"RenderStepped")
    s.Stepped=newSignal(s,"Stepped")
  end
  if name == "HttpService" then
    s.RequestAsync=function(_,o) UNC.onhttp("RequestAsync", o); return {Success=true,StatusCode=200,Body="{}",Headers={}} end
    s.GetAsync=function(_,u,...) UNC.onhttp("GetAsync", u); return "" end
    s.PostAsync=function(_,u,b,...) UNC.onhttp("PostAsync", u, b); return "" end
    s.JSONEncode=function(_,t) return "{}" end; s.JSONDecode=function(_,x) return {} end
    s.GenerateGUID=function() return "{00000000-0000-0000-0000-000000000000}" end
    s.UrlEncode=function(_,x) return tostring(x) end
  end
  services[name] = s
  return s
end
local game = newInstance("DataModel")
game.GetService = function(_, n) return service(n) end
game.FindService = game.GetService
game.GetGuiObjectsAtPosition = function() return {} end
game.HttpGet = function(_, u, ...) UNC.onhttp("HttpGet", u); return "" end
game.HttpGetAsync = game.HttpGet
game.HttpPost = function(_, u, b, ...) UNC.onhttp("HttpPost", u, b); return "" end
game.JobId = ""; game.PlaceId = 0; game.GameId = 0
local workspace = service("Workspace")

UNC.Enum=Enum; UNC.game=game; UNC.workspace=workspace; UNC.Instance=Instance
UNC.Vector3=Vector3; UNC.Vector2=Vector2; UNC.UDim=UDim; UNC.UDim2=UDim2
UNC.Color3=Color3; UNC.CFrame=CFrame; UNC.TweenInfo=TweenInfo; UNC.NumberRange=NumberRange
UNC.Rect=Rect; UNC.ColorSequence=ColorSequence; UNC.NumberSequence=NumberSequence
UNC.ColorSequenceKeypoint=ColorSequenceKeypoint; UNC.NumberSequenceKeypoint=NumberSequenceKeypoint
UNC.BrickColor=BrickColor; UNC.Font=Font; UNC.Ray=Ray; UNC.PhysicalProperties=PhysicalProperties
UNC.Signal=Signal; UNC.newSignal=newSignal
return UNC
