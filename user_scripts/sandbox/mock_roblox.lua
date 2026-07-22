-- Minimal Roblox API + Anime Ball world mock, for running the autoparry script
-- in real Lua 5.1 to catch RUNTIME bugs. Models the pieces the script touches,
-- per the game dump (Framework RemoteFunction/SwordService, workspace.Balls,
-- LinearVelocity, the [PlayerName].Highlight, Stats ping, etc.).

local M = {}

-- ---------- virtual clock + task scheduler (coroutine based) ----------
local VTIME = 0
local threads = {}   -- {co=, wake=}
local function schedule(co, delay) threads[#threads+1] = {co=co, wake=VTIME+(delay or 0)} end

local task = {}
function task.spawn(f, ...)
  local co = coroutine.create(f)
  local ok, err = coroutine.resume(co, ...)
  if not ok then error("task.spawn thread error: "..tostring(err)) end
  if coroutine.status(co) ~= "dead" then
    -- it yielded (a wait); reschedule based on the yielded delay
    -- (resume already returned the yield value as err on this path is nil; we
    -- capture via a wrapper instead) -- handled by task.wait below
  end
  return co
end
function task.defer(f, ...) return task.spawn(f, ...) end
function task.delay(d, f, ...)
  local co = coroutine.create(function(...) if d and d>0 then coroutine.yield(d) end f(...) end)
  local ok = coroutine.resume(co, ...)
  if coroutine.status(co) ~= "dead" then schedule(co, d or 0) end
  return co
end
function task.wait(d) coroutine.yield(d or 0) return d or 0 end
-- global wait/spawn/delay aliases
local function gspawn(f) return task.spawn(f) end

-- Re-implement spawn so a yielding coroutine gets rescheduled. We wrap the
-- resume loop: task.spawn resumes; if it yields a delay, schedule it.
function task.spawn(f, ...)
  local co = coroutine.create(f)
  local function step(...)
    local ok, a = coroutine.resume(co, ...)
    if not ok then error("thread error: "..tostring(a)) end
    if coroutine.status(co) ~= "dead" then schedule(co, tonumber(a) or 0) end
  end
  step(...)
  return co
end
function task.delay(d, f, ...)
  local args = {...}
  return task.spawn(function() if d and d>0 then task.wait(d) end f(unpack(args)) end)
end

-- advance virtual time, waking scheduled threads
local function advance(dt)
  VTIME = VTIME + dt
  local ready = {}
  local keep = {}
  for _,t in ipairs(threads) do
    if t.wake <= VTIME then ready[#ready+1]=t else keep[#keep+1]=t end
  end
  threads = keep
  for _,t in ipairs(ready) do
    if coroutine.status(t.co) ~= "dead" then
      local ok, a = coroutine.resume(t.co)
      if not ok then error("scheduled thread error: "..tostring(a)) end
      if coroutine.status(t.co) ~= "dead" then schedule(t.co, tonumber(a) or 0) end
    end
  end
end

-- ---------- Vector3 ----------
local Vector3 = {}
Vector3.__index = Vector3
local function v3(x,y,z) return setmetatable({X=x or 0,Y=y or 0,Z=z or 0}, Vector3) end
function Vector3.new(x,y,z) return v3(x,y,z) end
Vector3.__add = function(a,b) return v3(a.X+b.X,a.Y+b.Y,a.Z+b.Z) end
Vector3.__sub = function(a,b) return v3(a.X-b.X,a.Y-b.Y,a.Z-b.Z) end
Vector3.__unm = function(a) return v3(-a.X,-a.Y,-a.Z) end
Vector3.__mul = function(a,b)
  if type(a)=="number" then return v3(b.X*a,b.Y*a,b.Z*a) end
  if type(b)=="number" then return v3(a.X*b,a.Y*b,a.Z*b) end
  return v3(a.X*b.X,a.Y*b.Y,a.Z*b.Z)
end
Vector3.__div = function(a,b)
  if type(b)=="number" then return v3(a.X/b,a.Y/b,a.Z/b) end
  if type(a)=="number" then return v3(a/b.X,a/b.Y,a/b.Z) end
  return v3(a.X/b.X,a.Y/b.Y,a.Z/b.Z)
end
Vector3.__eq = function(a,b) return a.X==b.X and a.Y==b.Y and a.Z==b.Z end
function Vector3:Dot(o) return self.X*o.X+self.Y*o.Y+self.Z*o.Z end
function Vector3:Cross(o) return v3(self.Y*o.Z-self.Z*o.Y, self.Z*o.X-self.X*o.Z, self.X*o.Y-self.Y*o.X) end
function Vector3:Lerp(o,t) return v3(self.X+(o.X-self.X)*t, self.Y+(o.Y-self.Y)*t, self.Z+(o.Z-self.Z)*t) end
function Vector3:Angle(o)
  local d = math.max(-1, math.min(1, self:Dot(o)/((self.Magnitude*o.Magnitude)+1e-9)))
  return math.acos(d)
end
Vector3.__index = function(self, k)
  if k=="Magnitude" then return math.sqrt(self.X*self.X+self.Y*self.Y+self.Z*self.Z) end
  if k=="Unit" then local m=math.sqrt(self.X*self.X+self.Y*self.Y+self.Z*self.Z); if m<1e-9 then return v3(0,0,0) end return v3(self.X/m,self.Y/m,self.Z/m) end
  return Vector3[k]
end
Vector3.new(0,0,0)
Vector3.yAxis = v3(0,1,0); Vector3.xAxis = v3(1,0,0); Vector3.zAxis = v3(0,0,1)

-- ---------- CFrame (enough for LookVector + fromAxisAngle rotation) ----------
local CFrame = {}
CFrame.__index = CFrame
function CFrame.new(px,py,pz)
  local pos = (type(px)=="table") and px or v3(px or 0,py or 0,pz or 0)
  return setmetatable({Position=pos, LookVector=v3(0,0,-1), _rot=nil}, CFrame)
end
function CFrame.fromAxisAngle(axis, angle)
  local a = axis.Unit
  local c = setmetatable({Position=v3(0,0,0), LookVector=v3(0,0,-1)}, CFrame)
  c._axis=a; c._angle=angle
  return c
end
function CFrame:VectorToWorldSpace(vv)
  -- Rodrigues rotation of vv about self._axis by self._angle
  local a=self._axis; local th=self._angle or 0
  if not a then return vv end
  local cosT=math.cos(th); local sinT=math.sin(th)
  local dot=a:Dot(vv)
  local cross=a:Cross(vv)
  return v3(
    vv.X*cosT + cross.X*sinT + a.X*dot*(1-cosT),
    vv.Y*cosT + cross.Y*sinT + a.Y*dot*(1-cosT),
    vv.Z*cosT + cross.Z*sinT + a.Z*dot*(1-cosT))
end

-- ---------- simple stubs for GUI datatypes ----------
local function stubval(name) return setmetatable({__stub=name}, {__index=function() return function() end end}) end
local Color3 = { fromHex=function() return stubval("Color3") end, fromRGB=function() return stubval("Color3") end, new=function() return stubval("Color3") end }
local ColorSequence = { new=function() return stubval("ColorSequence") end }
local UDim2 = { new=function() return stubval("UDim2") end }
local UDim = { new=function() return stubval("UDim") end }

-- ---------- Enum ----------
local function enumfamily(names)
  local t={}; for _,n in ipairs(names) do t[n]=setmetatable({__enum=n},{__tostring=function() return n end}) end
  return t
end
local Enum = {
  PartType = enumfamily({"Ball","Block"}),
  Material = enumfamily({"ForceField","Air","Plastic"}),
  KeyCode = enumfamily({"LeftControl","F"}),
  ActuatorRelativeTo = enumfamily({"World","Attachment0"}),
  VelocityConstraintMode = enumfamily({"Vector","Line"}),
  Font = enumfamily({"GothamBold","Gotham"}),
  EasingStyle = enumfamily({"Sine"}),
  EasingDirection = enumfamily({"In","Out"}),
}

-- ---------- Signal ----------
local Signal = {}
Signal.__index = Signal
local function newSignal() return setmetatable({handlers={}}, Signal) end
function Signal:Connect(fn)
  local h=self.handlers; h[#h+1]=fn
  local conn={Connected=true}
  function conn:Disconnect() self.Connected=false; for i,f in ipairs(h) do if f==fn then table.remove(h,i) break end end end
  return conn
end
function Signal:Fire(...) for _,f in ipairs({unpack(self.handlers)}) do f(...) end end
function Signal:Wait() coroutine.yield(0) end

-- ---------- Instance ----------
local Instance = {}
local InstMeta = {}
local function newInstance(class)
  local self = setmetatable({
    ClassName=class, Name=class, _children={}, _parent=nil,
    _attrs={}, _attrSignals={},
    ChildAdded=newSignal(), ChildRemoved=newSignal(),
    AssemblyLinearVelocity=v3(0,0,0),
    Position=v3(0,0,0),
  }, InstMeta)
  return self
end
InstMeta.__index = function(self, k)
  if k=="Parent" then return rawget(self,"_parent") end
  local m = InstMeta.methods[k]
  if m then return m end
  -- child by name
  for _,c in ipairs(rawget(self,"_children")) do if c.Name==k then return c end end
  return nil
end
InstMeta.__newindex = function(self, k, v)
  if k=="Parent" then
    local old = rawget(self,"_parent")
    if old then for i,c in ipairs(old._children) do if c==self then table.remove(old._children,i) break end end
      old.ChildRemoved:Fire(self) end
    rawset(self,"_parent",v)
    if v then v._children[#v._children+1]=self; v.ChildAdded:Fire(self) end
    return
  end
  rawset(self,k,v)
end
InstMeta.methods = {}
local M2 = InstMeta.methods
function M2.FindFirstChild(self,name,recursive)
  for _,c in ipairs(self._children) do if c.Name==name then return c end end
  if recursive then for _,c in ipairs(self._children) do local r=M2.FindFirstChild(c,name,true); if r then return r end end end
  return nil
end
function M2.FindFirstChildOfClass(self,class)
  for _,c in ipairs(self._children) do if c.ClassName==class then return c end end
  return nil
end
function M2.FindFirstChildWhichIsA(self,class,recursive)
  for _,c in ipairs(self._children) do if M2.IsA(c,class) then return c end end
  if recursive then for _,c in ipairs(self._children) do local r=M2.FindFirstChildWhichIsA(c,class,true); if r then return r end end end
  return nil
end
function M2.GetChildren(self) local t={} for i,c in ipairs(self._children) do t[i]=c end return t end
function M2.GetDescendants(self) local t={} for _,c in ipairs(self._children) do t[#t+1]=c for _,d in ipairs(M2.GetDescendants(c)) do t[#t+1]=d end end return t end
function M2.IsA(self,class)
  if self.ClassName==class then return true end
  if class=="BasePart" and (self.ClassName=="Part" or self.ClassName=="MeshPart" or self.ClassName=="BasePart") then return true end
  if class=="Instance" then return true end
  return false
end
function M2.GetAttribute(self,name) return self._attrs[name] end
function M2.SetAttribute(self,name,val)
  self._attrs[name]=val
  local s=self._attrSignals[name]; if s then s:Fire() end
end
function M2.GetAttributeChangedSignal(self,name)
  local s=self._attrSignals[name]; if not s then s=newSignal(); self._attrSignals[name]=s end return s
end
function M2.WaitForChild(self,name,timeout) return M2.FindFirstChild(self,name) end
function M2.Destroy(self) if self._parent then self.Parent=nil end self._destroyed=true end
function M2.Clone(self) local c=newInstance(self.ClassName); c.Name=self.Name; return c end
function M2.GetPlayers() return self._playersList or {} end
function M2.LoadAnimation() return {Play=function() end,Stop=function() end} end

Instance.new = function(class, parent) local i=newInstance(class); if parent then i.Parent=parent end return i end

M.VTIME=function() return VTIME end
M.advance=advance
M.task=task
M.Vector3=Vector3
M.CFrame=CFrame
M.Color3=Color3
M.ColorSequence=ColorSequence
M.UDim2=UDim2
M.UDim=UDim
M.Enum=Enum
M.Instance=Instance
M.newSignal=newSignal
M.newInstance=newInstance
M.v3=v3
return M
