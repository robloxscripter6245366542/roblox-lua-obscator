--!nocheck
-- ============================================================================
-- TSB Simulator — a minimal Luau runtime + Roblox API stub used to actually
-- RUN the Fire Hub ("Strongest") script outside Roblox and surface runtime
-- bugs (nil indexes, bad API use, respawn/cleanup errors).
--
-- Layout when combined for a run:  prelude.lua .. Strongest .. driver.lua
-- ============================================================================

_G = {}   -- the CLI's real _G is frozen; shadow it with a writable table (Strongest uses _G.* heavily)

local SIM = { errors = {}, controls = {}, clock = 0 }
_G.__SIM = SIM

local function report(ctx, err)
    table.insert(SIM.errors, { label = SIM.label, ctx = ctx, err = tostring(err) })
end
SIM.report = report

-- ---------------------------------------------------------------- scheduler
-- Cooperative scheduler with a virtual clock. task.wait yields; the driver
-- advances time with SIM.step(dt).
local waiting = {}   -- { co=coroutine, at=number, ctx=string }
local delayed = {}   -- { fn=function, at=number, ctx=string }

local function resume(co, ctx, ...)
    local ok, a = coroutine.resume(co, ...)
    if not ok then report(ctx or "coroutine", a)
    elseif coroutine.status(co) ~= "dead" then
        table.insert(waiting, { co = co, at = SIM.clock + (tonumber(a) or 0), ctx = ctx })
    end
end

local function spawnfn(ctx, fn, ...)
    local co = coroutine.create(fn)
    resume(co, ctx, ...)
    return co
end
SIM.spawn = spawnfn

task = {
    wait = function(t) return coroutine.yield(t or 0) end,
    spawn = function(fn, ...) return spawnfn("task.spawn", fn, ...) end,
    defer = function(fn, ...) return spawnfn("task.defer", fn, ...) end,
    delay = function(t, fn, ...)
        local args = table.pack(...)
        table.insert(delayed, { at = SIM.clock + (tonumber(t) or 0), ctx = "task.delay",
            fn = function() fn(table.unpack(args, 1, args.n)) end })
    end,
}
wait  = task.wait
spawn = task.spawn
delay = function(t, fn) task.delay(t, fn) end
tick  = function() return SIM.clock end
time  = function() return SIM.clock end
local _os = os; os = setmetatable({ clock = function() return SIM.clock end, time = function() return 0 end }, { __index = _os })

function SIM.step(dt)
    SIM.clock += dt
    -- fire due delayed callbacks (in their own coroutines so they can yield)
    local due = {}
    for i = #delayed, 1, -1 do
        if delayed[i].at <= SIM.clock then table.insert(due, delayed[i]); table.remove(delayed, i) end
    end
    for _, d in ipairs(due) do spawnfn(d.ctx, d.fn) end
    -- resume due waiters
    local ready = {}
    for i = #waiting, 1, -1 do
        if waiting[i].at <= SIM.clock then table.insert(ready, waiting[i]); table.remove(waiting, i) end
    end
    for _, w in ipairs(ready) do resume(w.co, w.ctx) end
end

-- ---------------------------------------------------------------- typeof
local TYPETAG = setmetatable({}, { __mode = "k" })
function typeof(v)
    if type(v) == "table" and TYPETAG[v] then return TYPETAG[v] end
    return type(v)
end
local function tag(v, name) TYPETAG[v] = name; return v end

-- ---------------------------------------------------------------- Vector3
local V3 = {}
V3.__index = V3
function V3.new(x, y, z) return tag(setmetatable({ X = x or 0, Y = y or 0, Z = z or 0 }, V3), "Vector3") end
V3.__add = function(a, b) return V3.new(a.X+b.X, a.Y+b.Y, a.Z+b.Z) end
V3.__sub = function(a, b) return V3.new(a.X-b.X, a.Y-b.Y, a.Z-b.Z) end
V3.__unm = function(a) return V3.new(-a.X, -a.Y, -a.Z) end
V3.__mul = function(a, b)
    if type(a) == "number" then return V3.new(b.X*a, b.Y*a, b.Z*a) end
    if type(b) == "number" then return V3.new(a.X*b, a.Y*b, a.Z*b) end
    return V3.new(a.X*b.X, a.Y*b.Y, a.Z*b.Z)
end
V3.__eq = function(a, b) return a.X==b.X and a.Y==b.Y and a.Z==b.Z end
function V3:__index(k)
    if k == "Magnitude" then return math.sqrt(self.X^2 + self.Y^2 + self.Z^2) end
    if k == "Unit" then
        local m = math.sqrt(self.X^2 + self.Y^2 + self.Z^2)
        if m == 0 then m = 1 end
        return V3.new(self.X/m, self.Y/m, self.Z/m)
    end
    return rawget(V3, k)
end
V3.Dot = function(self, o) return self.X*o.X + self.Y*o.Y + self.Z*o.Z end
Vector3 = setmetatable({ new = V3.new, zero = V3.new(0,0,0), yAxis = V3.new(0,1,0),
    xAxis = V3.new(1,0,0), zAxis = V3.new(0,0,1) }, { __index = V3 })

Vector2 = { new = function(x, y) return tag({ X = x or 0, Y = y or 0 }, "Vector2") end }

-- ---------------------------------------------------------------- CFrame
local CF = {}
CF.__index = CF
local function mkcf(pos, look)
    local c = setmetatable({ Position = pos or V3.new(), p = pos or V3.new(),
        LookVector = look or V3.new(0,0,-1), RightVector = V3.new(1,0,0), UpVector = V3.new(0,1,0) }, CF)
    return tag(c, "CFrame")
end
CF.__mul = function(a, b)
    if typeof(b) == "Vector3" then return a.Position + b end     -- point transform (approx)
    if typeof(b) == "CFrame" then return mkcf(a.Position + b.Position, a.LookVector) end
    return a
end
CF.__add = function(a, b) return mkcf(a.Position + b, a.LookVector) end
CF.__sub = function(a, b) return mkcf(a.Position - b, a.LookVector) end
CF.Lerp = function(self, other, a) return mkcf(self.Position + (other.Position - self.Position) * (a or 0), self.LookVector) end
CF.ToWorldSpace = function(self, o) return mkcf(self.Position + o.Position, self.LookVector) end
CF.Inverse = function(self) return mkcf(-self.Position, self.LookVector) end
CFrame = setmetatable({
    new = function(x, y, z)
        if typeof(x) == "Vector3" and typeof(y) == "Vector3" then      -- CFrame.new(from, lookAt)
            return mkcf(x, (y - x).Unit)
        elseif typeof(x) == "Vector3" then return mkcf(x)
        else return mkcf(V3.new(x or 0, y or 0, z or 0)) end
    end,
    lookAt = function(from, to) return mkcf(from, (to - from).Unit) end,
    Angles = function() return mkcf() end,
    fromAxisAngle = function() return mkcf() end,
    fromMatrix = function(pos, r, u) return mkcf(pos or V3.new(), nil) end,
}, {})

-- ---------------------------------------------------------------- misc types
local function passthru(name) return function(...) return tag({ args = { ... } }, name) end end
Color3 = { new = passthru("Color3"), fromRGB = passthru("Color3"), fromHex = passthru("Color3") }
ColorSequence = setmetatable({ new = passthru("ColorSequence") }, {})
ColorSequenceKeypoint = { new = passthru("ColorSequenceKeypoint") }
NumberSequence = { new = passthru("NumberSequence") }
NumberSequenceKeypoint = { new = passthru("NumberSequenceKeypoint") }
NumberRange = { new = passthru("NumberRange") }
UDim = { new = passthru("UDim") }
UDim2 = { new = passthru("UDim2"), fromOffset = passthru("UDim2"), fromScale = passthru("UDim2") }
TweenInfo = { new = passthru("TweenInfo") }

-- ---------------------------------------------------------------- Enum
local enumCache = {}
Enum = setmetatable({}, { __index = function(_, cat)
    local c = enumCache[cat]
    if not c then
        c = setmetatable({}, { __index = function(t, item)
            local e = tag({ Name = item, Value = 0, EnumType = cat }, "EnumItem")
            rawset(t, item, e); return e
        end })
        -- give a couple of numeric values that code compares against
        enumCache[cat] = c
    end
    return c
end })

print("[prelude] core types ready")

-- ---------------------------------------------------------------- Signal
local Signal = {}
Signal.__index = Signal
function Signal.new(name) return setmetatable({ _h = {}, _last = {}, _name = name }, Signal) end
function Signal:Connect(fn)
    local h = { fn = fn, alive = true }
    table.insert(self._h, h)
    return { Connected = true, Disconnect = function(s) h.alive = false; if s then s.Connected = false end end }
end
Signal.connect = Signal.Connect
function Signal:Fire(...)
    self._last = table.pack(...)
    for _, h in ipairs(self._h) do
        if h.alive then SIM.spawn(self._name or "signal", h.fn, ...) end
    end
end
function Signal:Wait() return table.unpack(self._last, 1, self._last.n or 0) end

-- ---------------------------------------------------------------- Instance
local EVENT_NAMES = {
    AnimationPlayed=true, Running=true, Died=true, Changed=true, Touched=true,
    ChildAdded=true, ChildRemoved=true, DescendantAdded=true, DescendantRemoving=true,
    CharacterAdded=true, CharacterRemoving=true, Completed=true, Destroying=true,
    StateChanged=true,
}
local Instance = {}
local Inst = {}
Inst.__index = function(self, k)
    local m = rawget(Inst, k)
    if m ~= nil then return m end
    local p = rawget(self, "_props")[k]
    if p ~= nil then return p end
    if EVENT_NAMES[k] then
        local s = rawget(self, "_sig")[k]
        if not s then s = Signal.new(k); rawget(self, "_sig")[k] = s end
        return s
    end
    -- child access by name (Roblox exposes children as properties)
    for _, c in ipairs(rawget(self, "_children")) do
        if c._props.Name == k then return c end
    end
    return nil
end
Inst.__newindex = function(self, k, v)
    if k == "Parent" then
        local old = rawget(self, "_parent")
        if old then for i, c in ipairs(old._children) do if c == self then table.remove(old._children, i) break end end end
        rawset(self, "_parent", v)
        rawget(self, "_props").Parent = v
        if v and v._children then table.insert(v._children, self) end
        return
    end
    if k == "CFrame" and typeof(v) == "CFrame" then rawget(self, "_props").Position = v.Position end
    rawget(self, "_props")[k] = v
end

local classDefaults = {
    Humanoid = function(p) p.Health=100; p.MaxHealth=100; p.WalkSpeed=16; p.JumpPower=50;
        p.AutoRotate=true; p.PlatformStand=false; p.Sit=false; p.MoveDirection=Vector3.zero end,
    BasePart = function(p) p.Position=Vector3.new(); p.CFrame=CFrame.new(); p.Size=Vector3.new(2,2,1);
        p.AssemblyLinearVelocity=Vector3.zero; p.AssemblyAngularVelocity=Vector3.zero;
        p.Velocity=Vector3.zero; p.RotVelocity=Vector3.zero; p.CanCollide=true; p.Anchored=false end,
    Camera = function(p) p.CFrame=CFrame.new(); p.ViewportSize=Vector2.new(1920,1080) end,
    AnimationTrack = function(p) p.TimePosition=0; p.Length=1; p.IsPlaying=true; p.Looped=false;
        p.Speed=1; p.Name="Track" end,
}
local BASEPARTS = { HumanoidRootPart=true, Part=true, MeshPart=true, BasePart=true, UpperTorso=true,
    Torso=true, Head=true, LeftHand=true, RightHand=true, ["Left Arm"]=true, ["Right Arm"]=true }

local function newInstance(class, parent, name)
    local self = setmetatable({ _children = {}, _props = {}, _sig = {}, _attrs = {}, _attrSig = {} }, Inst)
    local p = self._props
    p.ClassName = class
    p.Name = name or class
    if classDefaults[class] then classDefaults[class](p)
    elseif BASEPARTS[class] then classDefaults.BasePart(p) end
    if parent then self.Parent = parent end
    return self
end
function Instance.new(class, parent) return newInstance(class, parent) end

function Inst:FindFirstChild(name, recursive)
    for _, c in ipairs(self._children) do if c._props.Name == name then return c end end
    if recursive then
        for _, c in ipairs(self._children) do local r = c:FindFirstChild(name, true); if r then return r end end
    end
    return nil
end
function Inst:FindFirstChildOfClass(cls)
    for _, c in ipairs(self._children) do if c._props.ClassName == cls then return c end end
    return nil
end
function Inst:FindFirstChildWhichIsA(cls) return self:FindFirstChildOfClass(cls) end
function Inst:WaitForChild(name, _t) return self:FindFirstChild(name) end
function Inst:GetChildren() local t = {}; for i, c in ipairs(self._children) do t[i] = c end; return t end
function Inst:GetDescendants()
    local t = {}
    local function rec(n) for _, c in ipairs(n._children) do table.insert(t, c); rec(c) end end
    rec(self); return t
end
function Inst:IsA(cls)
    local c = self._props.ClassName
    if c == cls then return true end
    if cls == "BasePart" then return BASEPARTS[c] == true end
    if cls == "GuiObject" then return true end
    return false
end
function Inst:Destroy() self.Parent = nil; self._props.Parent = nil end
function Inst:IsDescendantOf(anc)
    local p = rawget(self, "_parent")
    while p do if p == anc then return true end; p = rawget(p, "_parent") end
    return false
end
function Inst:Clone()
    local c = newInstance(self._props.ClassName)
    for k, v in pairs(self._props) do if k ~= "Parent" then c._props[k] = v end end
    return c
end
function Inst:GetAttribute(n) return self._attrs[n] end
function Inst:SetAttribute(n, v)
    self._attrs[n] = v
    local s = self._attrSig[n]; if s then s:Fire() end
end
function Inst:GetAttributeChangedSignal(n)
    local s = self._attrSig[n]; if not s then s = Signal.new("attr:"..n); self._attrSig[n] = s end; return s
end
function Inst:GetPropertyChangedSignal(p)
    local key = "prop:"..p; local s = self._sig[key]
    if not s then s = Signal.new(key); self._sig[key] = s end; return s
end
-- behaviour stubs (no-op) commonly called on various instances
function Inst:FireServer(...) end
function Inst:FireClient(...) end
function Inst:InvokeServer(...) end
function Inst:Play(...) end
function Inst:Stop(...) end
function Inst:Emit(...) end
function Inst:AdjustSpeed(...) end
function Inst:ChangeState(s) self._props.State = s end
function Inst:GetState() return self._props.State or Enum.HumanoidStateType.Running end
function Inst:GetPlayingAnimationTracks() return self._props._tracks or {} end
function Inst:LoadAnimation(anim)
    local tr = newInstance("AnimationTrack"); tr._props.Animation = anim; return tr
end
function Inst:GetMouse() return newInstance("Mouse") end

_G.Instance = Instance

print("[prelude] instance model ready")

-- ---------------------------------------------------------------- services
local services = {}
local RunService = { RenderStepped = Signal.new("RenderStepped"), Heartbeat = Signal.new("Heartbeat"),
    Stepped = Signal.new("Stepped"), BindToRenderStep = function() end, UnbindFromRenderStep = function() end,
    IsClient = function() return true end, IsStudio = function() return false end }
services.RunService = RunService

local TweenService = { Create = function(_, inst, info, goal)
    local completed = Signal.new("Completed")
    return { Completed = completed, Cancel = function() end, Destroy = function() end,
        Play = function()
            if inst and goal then for k, v in pairs(goal) do pcall(function() inst[k] = v end) end end
            task.delay(0, function() completed:Fire() end)
        end }
end }
services.TweenService = TweenService

services.Debris = { AddItem = function(_, inst, t)
    task.delay(tonumber(t) or 0, function() if inst and inst.Destroy then pcall(function() inst:Destroy() end) end end)
end }
services.VirtualInputManager = { SendKeyEvent = function() end, SendMouseButtonEvent = function() end }
services.UserInputService = { InputBegan = Signal.new("InputBegan"), InputChanged = Signal.new("InputChanged"),
    InputEnded = Signal.new("InputEnded"), KeyboardEnabled = true, TouchEnabled = false, MouseBehavior = 0 }
services.ReplicatedStorage = newInstance("ReplicatedStorage")
services.Lighting = newInstance("Lighting")
services.CoreGui = newInstance("CoreGui")
services.Stats = { Network = { ServerStatsItem = setmetatable({}, { __index = function()
    return { GetValue = function() return 50 end } end }) } }

-- workspace
local workspaceInst = newInstance("Workspace")
workspaceInst._props.CurrentCamera = newInstance("Camera")
services.Workspace = workspaceInst
workspace = workspaceInst
Workspace = workspaceInst

-- Players
local Players = { }
services.Players = Players

-- game
game = setmetatable({ PlaceId = 0, JobId = "sim" }, { __index = function(_, k)
    if services[k] then return services[k] end
    return nil
end })
function game:GetService(n)
    if not services[n] then services[n] = newInstance(n) end
    return services[n]
end
function game:HttpGet(url) return tostring(url) end
function game:HttpGetAsync(url) return tostring(url) end
getgenv = getgenv or function() return _G end

-- ---------------------------------------------------------------- loadstring + WindUI mock
local function registerControl(kind, cfg)
    cfg = cfg or {}
    table.insert(SIM.controls, { kind = kind, title = cfg.Title or kind, cfg = cfg })
    return setmetatable({}, { __index = function() return function() end end })
end
local function uiHolder()
    local h = setmetatable({}, { __index = function(_, k)
        if k == "Section" then return function(_, cfg) return uiHolder() end end
        if k == "Tab" then return function(_, cfg) return uiHolder() end end
        for _, kind in ipairs({ "Toggle","Button","Dropdown","Input","Keybind","Paragraph","Slider","Divider","Label" }) do
            if k == kind then return function(_, cfg) return registerControl(kind, cfg) end end
        end
        return function() return uiHolder() end
    end })
    return h
end
local MockWindUI = setmetatable({
    AddTheme = function() end, SetTheme = function() end, Notify = function() end,
    CreateWindow = function() return uiHolder() end,
    EditOpenButton = function() end,
}, { __index = function() return function() return uiHolder() end end })

loadstring = function(src)
    src = tostring(src or "")
    if src:find("WindUI") or src:find("Footagesus") then
        return function() return MockWindUI end
    end
    return function() end   -- external pastebin techs -> no-op (they run in pcall/task.spawn)
end

-- ---------------------------------------------------------------- TSB scenario
local function makeChar(name)
    local m = newInstance("Model"); m._props.Name = name
    local hum = newInstance("Humanoid", m)
    newInstance("Animator", hum)
    local hrp = newInstance("HumanoidRootPart", m); hrp._props.Name = "HumanoidRootPart"
    hrp._props.Position = Vector3.new(0, 5, 0)
    local comm = newInstance("RemoteEvent", m); comm._props.Name = "Communicate"
    for _, part in ipairs({ "Head","UpperTorso","LeftHand","RightHand" }) do
        local pp = newInstance("Part", m); pp._props.Name = part
    end
    return m, hum, hrp
end

local live = newInstance("Folder", workspaceInst); live._props.Name = "Live"

local myChar, myHum, myHRP = makeChar("You")
myChar.Parent = live
local enemyChar, enemyHum, enemyHRP = makeChar("Enemy")
enemyChar.Parent = live
enemyHRP._props.Position = Vector3.new(0, 5, 12)      -- ~12 studs away
local dummy = makeChar("Weakest Dummy")
dummy.Parent = live
select(1, dummy):FindFirstChild("HumanoidRootPart")._props.Position = Vector3.new(0, 5, 8)

local LocalPlayer = newInstance("Player")
LocalPlayer._props.Name = "You"
newInstance("PlayerGui", LocalPlayer)
newInstance("Backpack", LocalPlayer)
LocalPlayer._props.Character = myChar
local enemyPlayer = newInstance("Player"); enemyPlayer._props.Name = "Enemy"
enemyPlayer._props.Character = enemyChar

Players.LocalPlayer = LocalPlayer
function Players:GetPlayers() return { LocalPlayer, enemyPlayer } end
function Players:GetPlayerFromCharacter(c)
    if c == myChar then return LocalPlayer elseif c == enemyChar then return enemyPlayer end
    return nil
end
function Players:FindFirstChild(n)
    if n == "You" then return LocalPlayer elseif n == "Enemy" then return enemyPlayer end
    return nil
end
function Players:GetPlayerByUserId() return nil end

-- expose to driver
SIM.LocalPlayer = LocalPlayer
SIM.myChar, SIM.myHum, SIM.myHRP = myChar, myHum, myHRP
SIM.enemyChar = enemyChar
SIM.live = live
SIM.RunService = RunService
SIM.makeChar = makeChar
SIM.workspace = workspaceInst

print("[prelude] services + TSB world ready — controls will register on load")
