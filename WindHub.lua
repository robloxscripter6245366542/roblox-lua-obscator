--[[
╔══════════════════════════════════════════════════════════════════════════════╗
║  WindHub  v4.0  |  Ultimate Blade Ball Script                               ║
║──────────────────────────────────────────────────────────────────────────────║
║  Lua/Luau  : metatables · __index · __newindex · __namecall · closures      ║
║              coroutines · tables · custom events/signals · full OOP         ║
║  Analysis  : position · velocity · trajectory · prediction · timing         ║
║              ping compensation · frame updates · client state monitor        ║
║  Roblox    : RunService · Players · Workspace · UserInputService            ║
║              RemoteEvent spy · RemoteFunction spy · TweenService            ║
║  Executor  : hookfunction · metatable mod · env manipulation               ║
║              debug/reflection · getupvalues/getprotos · VIM input           ║
║  Features  : auto-parry (3 modes) · manual spam · anim fix · ping comp     ║
║              auto-dodge · multi-ball priority · ESP (balls+players)         ║
║              prediction arc · hitbox expand · remote logger · stats HUD    ║
║              hotkeys · humanized timing · anti-ban variance · profiler      ║
╚══════════════════════════════════════════════════════════════════════════════╝
  HOTKEYS:
    P  — auto-parry on/off          T  — cycle mode (Ultra/Predictive/Conservative)
    O  — manual spam on/off         R  — reset adaptive window
    I  — animation fix on/off       F  — print stats toggle
    U  — auto-dodge on/off          G  — prediction arc on/off
    Y  — ball ESP on/off            H  — hitbox expand on/off
--]]

local RS      = game:GetService("RunService")
local Plrs    = game:GetService("Players")
local UIS     = game:GetService("UserInputService")
local TS      = game:GetService("TweenService")
local RepStor = game:GetService("ReplicatedStorage")
local WS      = workspace
local lp      = Plrs.LocalPlayer
local cam     = WS.CurrentCamera

if _G.WindHubActive then _G.WindHubActive = false task.wait(0.08) end
_G.WindHubActive = true

-- ═══════════════════════════════════════════════════════════════
--  OOP: Signal  (custom event system — closures + metatables)
-- ═══════════════════════════════════════════════════════════════
local Signal = {}
Signal.__index = Signal

function Signal.new()
    return setmetatable({ _conns = {}, _nextId = 0 }, Signal)
end

function Signal:Connect(fn)
    self._nextId += 1
    local id = self._nextId
    self._conns[id] = fn
    return setmetatable({}, {
        __index = { Disconnect = function() self._conns[id] = nil end }
    })
end

function Signal:Fire(...)
    for _, fn in pairs(self._conns) do task.spawn(fn, ...) end
end

function Signal:Wait()
    local thread = coroutine.running()
    local conn
    conn = self:Connect(function(...)
        conn:Disconnect()
        task.spawn(thread, ...)
    end)
    return coroutine.yield()
end

function Signal:Once(fn)
    local conn
    conn = self:Connect(function(...)
        conn:Disconnect()
        fn(...)
    end)
    return conn
end

-- ═══════════════════════════════════════════════════════════════
--  OOP: Config  (__index defaults · __newindex validation+events)
-- ═══════════════════════════════════════════════════════════════
local DEFAULTS = {
    autoParry      = true,
    parryMode      = "Predictive",   -- "Ultra" | "Predictive" | "Conservative"
    parryWindow    = 0.52,
    minWindow      = 0.15,
    maxWindow      = 1.20,
    adaptAlpha     = 0.12,
    humanizeMin    = 0.010,          -- anti-ban random delay range
    humanizeMax    = 0.045,
    manualSpam     = false,
    spamRate       = 0.07,
    autoDodge      = false,
    dodgeDist      = 22,
    animFix        = true,
    espBalls       = true,
    espPlayers     = false,
    predArc        = true,
    arcSegments    = 18,
    arcDuration    = 0.5,
    hitboxExpand   = false,
    hitboxSize     = Vector3.new(6, 6, 6),
    pingComp       = true,
    printStats     = false,
}

local Config = {}
Config.Changed = Signal.new()

setmetatable(Config, {
    __index    = DEFAULTS,
    __newindex = function(t, k, v)
        if DEFAULTS[k] == nil then return end
        local old = rawget(t, k)
        if old == nil then old = DEFAULTS[k] end
        rawset(t, k, v)
        if old ~= v then Config.Changed:Fire(k, v, old) end
    end,
})

-- ═══════════════════════════════════════════════════════════════
--  EXECUTOR / DEVICE PROBE  (reflection + env manipulation)
-- ═══════════════════════════════════════════════════════════════
local Exec = {}
do
    local genv = (type(getfenv) == "function" and getfenv(0)) or _G
    local function has(n) return type(genv[n]) == "function" end

    pcall(function()
        local fn = genv.identifyexecutor or genv.getexecutorname
        if type(fn) == "function" then Exec.name = tostring(fn()):lower() end
    end)
    Exec.name     = Exec.name or "unknown"
    Exec.isMobile = UIS.TouchEnabled and not UIS.KeyboardEnabled
    Exec.isPC     = not Exec.isMobile

    Exec.UNC = {
        hookfunction      = has "hookfunction",
        newcclosure       = has "newcclosure",
        getrawmetatable   = has "getrawmetatable",
        setreadonly       = has "setreadonly",
        getupvalues       = has "getupvalues",
        getconstants      = has "getconstants",
        getprotos         = has "getprotos",
        getnamecallmethod = has "getnamecallmethod",
        getconnections    = has "getconnections",
        dbg_up   = type(debug)=="table" and type(debug.getupvalues) =="function",
        dbg_const= type(debug)=="table" and type(debug.getconstants)=="function",
    }
    local ok = pcall(function() game:GetService("VirtualInputManager") end)
    Exec.hasVIM = ok
end

-- ═══════════════════════════════════════════════════════════════
--  REFLECTION UTILS  (debug extensions, upvalues, protos)
-- ═══════════════════════════════════════════════════════════════
local Reflect = {}

function Reflect.upvalues(fn)
    if Exec.UNC.getupvalues then
        local ok, t = pcall(getupvalues, fn); if ok then return t end
    end
    if Exec.UNC.dbg_up then
        local ok, t = pcall(debug.getupvalues, fn); if ok then return t end
    end
    return {}
end

function Reflect.constants(fn)
    if Exec.UNC.getconstants then
        local ok, t = pcall(getconstants, fn); if ok then return t end
    end
    if Exec.UNC.dbg_const then
        local ok, t = pcall(debug.getconstants, fn); if ok then return t end
    end
    return {}
end

function Reflect.protos(fn)
    if Exec.UNC.getprotos then
        local ok, t = pcall(getprotos, fn); if ok then return t end
    end
    return {}
end

-- recursive upvalue/proto search
function Reflect.deepSearch(fn, pred, depth)
    depth = depth or 0
    if depth > 4 then return nil end
    for _, v in pairs(Reflect.upvalues(fn)) do
        if pred(v) then return v end
    end
    for _, p in pairs(Reflect.protos(fn)) do
        if type(p) == "function" then
            local r = Reflect.deepSearch(p, pred, depth+1)
            if r then return r end
        end
    end
end

-- ═══════════════════════════════════════════════════════════════
--  PING COMPENSATION
-- ═══════════════════════════════════════════════════════════════
local PingComp = { pingMs = 0, avg = 0, hist = {} }

task.spawn(function()
    local stats = game:GetService("Stats")
    while _G.WindHubActive do
        pcall(function()
            local p = stats.Network.ServerStatsItem["Data Ping"]:GetValue()
            PingComp.pingMs = p
            table.insert(PingComp.hist, p)
            if #PingComp.hist > 30 then table.remove(PingComp.hist, 1) end
            local s = 0
            for _, v in ipairs(PingComp.hist) do s += v end
            PingComp.avg = s / #PingComp.hist
        end)
        task.wait(1)
    end
end)

function PingComp:effectiveWindow()
    local comp = Config.pingComp and (self.pingMs * 0.0005) or 0
    return Config.parryWindow + comp
end

-- ═══════════════════════════════════════════════════════════════
--  VIRTUAL INPUT  (device-aware, humanized anti-ban delay)
-- ═══════════════════════════════════════════════════════════════
local VIM = (function()
    local ok, s = pcall(function() return game:GetService("VirtualInputManager") end)
    return ok and s or nil
end)()

local function clickParry()
    local delay = Config.humanizeMin + math.random() * (Config.humanizeMax - Config.humanizeMin)
    task.wait(delay)
    if Exec.isMobile and VIM and VIM.SendTouchEvent then
        local cx = cam.ViewportSize.X * 0.5
        local cy = cam.ViewportSize.Y * 0.5
        pcall(function() VIM:SendTouchEvent(0, Vector2.new(cx,cy), true,  game) end)
        task.wait(0.035)
        pcall(function() VIM:SendTouchEvent(0, Vector2.new(cx,cy), false, game) end)
    elseif VIM then
        pcall(function() VIM:SendMouseButtonEvent(0,0,0,true, game,0) end)
        task.wait(0.035)
        pcall(function() VIM:SendMouseButtonEvent(0,0,0,false,game,0) end)
    end
end

-- ═══════════════════════════════════════════════════════════════
--  METATABLE HOOK: __namecall intercept
-- ═══════════════════════════════════════════════════════════════
local NamecallSignal = Signal.new()
local namecallHooked = false

do
    local U = Exec.UNC
    if U.hookfunction and U.newcclosure and U.getrawmetatable and U.getnamecallmethod then
        local mt  = getrawmetatable(game)
        if U.setreadonly then pcall(setreadonly, mt, false) end
        local orig = rawget(mt, "__namecall")
        if orig then
            local ok = pcall(function()
                hookfunction(orig, newcclosure(function(self, ...)
                    local m = getnamecallmethod()
                    if typeof(self) == "Instance" then
                        NamecallSignal:Fire(self, m, ...)
                    end
                    return orig(self, ...)
                end))
            end)
            namecallHooked = ok
        end
        if U.setreadonly then pcall(setreadonly, mt, true) end
    end
end

-- ═══════════════════════════════════════════════════════════════
--  REPLION INTEGRATION  (server-authoritative state sync)
--  Fires before attribute changes reach the client — gives us
--  the earliest possible warning when the ball targets us.
-- ═══════════════════════════════════════════════════════════════
local Replion = {
    onTargetChanged = Signal.new(),   -- (ballId, newTarget)
    onStateChanged  = Signal.new(),   -- (path, value)
    log             = {},
    maxLog          = 60,
}

local REPLION_PATH = {"Packages", "_Index", "ytrev_replion@2.0.0-rc.1", "replion", "Remotes", "Update"}

local function getReplionRemote()
    local ok, remote = pcall(function()
        local root = RepStor
        for _, key in ipairs(REPLION_PATH) do
            root = root[key]
        end
        return root
    end)
    return ok and remote or nil
end

task.spawn(function()
    -- wait for ReplicatedStorage to be fully populated
    task.wait(2)
    local remote = getReplionRemote()
    if not (remote and remote:IsA("RemoteEvent")) then
        -- fallback: scan for any remote named "Update" inside Packages
        local pkgs = RepStor:FindFirstChild("Packages")
        if pkgs then
            for _, desc in ipairs(pkgs:GetDescendants()) do
                if desc:IsA("RemoteEvent") and desc.Name == "Update" then
                    remote = desc
                    break
                end
            end
        end
    end
    if not remote then return end

    remote.OnClientEvent:Connect(function(channel, path, value)
        -- log every Replion update
        local entry = { channel=tostring(channel), path=path, value=value, t=os.clock() }
        table.insert(Replion.log, entry)
        if #Replion.log > Replion.maxLog then table.remove(Replion.log, 1) end

        Replion.onStateChanged:Fire(path, value)

        -- detect ball target change: path typically contains "target" key
        -- value is the player name being targeted
        local pathStr = tostring(path)
        if pathStr:lower():find("target") or pathStr:lower():find("ball") then
            if type(value) == "string" then
                Replion.onTargetChanged:Fire(channel, value)
            end
        end

        -- detect target in table/dict form
        if type(value) == "table" then
            local tgt = value.target or value.Target or value.targetPlayer
            if tgt then
                Replion.onTargetChanged:Fire(channel, tgt)
            end
        end
    end)
end)

-- when Replion tells us WE are targeted: pre-arm parry state
Replion.onTargetChanged:Connect(function(_, newTarget)
    if newTarget == lp.Name then
        _G.WindHub_ReplionTargeted = os.clock()
    end
end)

-- ═══════════════════════════════════════════════════════════════
--  REMOTE SPY  (RemoteEvent + RemoteFunction)
-- ═══════════════════════════════════════════════════════════════
local RemoteSpy = {
    onFired   = Signal.new(),
    onInvoked = Signal.new(),
    log       = {},
}

local function watchRemote(obj)
    if obj:IsA("RemoteEvent") then
        obj.OnClientEvent:Connect(function(...)
            local e = { type="Event", name=obj.Name, args={...}, t=os.clock() }
            table.insert(RemoteSpy.log, e)
            if #RemoteSpy.log > 80 then table.remove(RemoteSpy.log, 1) end
            RemoteSpy.onFired:Fire(e)
        end)
    elseif obj:IsA("RemoteFunction") then
        local prev = obj.OnClientInvoke
        obj.OnClientInvoke = function(...)
            local e = { type="Func", name=obj.Name, args={...}, t=os.clock() }
            table.insert(RemoteSpy.log, e)
            if #RemoteSpy.log > 80 then table.remove(RemoteSpy.log, 1) end
            RemoteSpy.onInvoked:Fire(e)
            if prev then return prev(...) end
        end
    end
end

local function spyAll(root)
    for _, o in ipairs(root:GetDescendants()) do watchRemote(o) end
    root.DescendantAdded:Connect(watchRemote)
end

task.spawn(spyAll, WS)
task.spawn(spyAll, RepStor)

-- detect parry ack from server
RemoteSpy.onFired:Connect(function(e)
    if e.name:lower():find("parr") or e.name:lower():find("block") then
        _G.WindHub_LastParryAck = e
    end
end)

-- ═══════════════════════════════════════════════════════════════
--  OOP: Physics Engine
-- ═══════════════════════════════════════════════════════════════
local Physics = {}
Physics.__index = Physics

local GRAV = Vector3.new(0, -WS.Gravity * 0.04, 0)

function Physics.new()
    return setmetatable({ samples={}, speedHist={} }, Physics)
end

function Physics:push(pos, vel, t)
    table.insert(self.samples, {pos=pos, vel=vel, t=t})
    if #self.samples > 12 then table.remove(self.samples, 1) end
    table.insert(self.speedHist, vel.Magnitude)
    if #self.speedHist > 12 then table.remove(self.speedHist, 1) end
end

function Physics:derivedVel()
    local n = #self.samples
    if n < 2 then return Vector3.zero end
    local a, b = self.samples[n-1], self.samples[n]
    local dt = b.t - a.t
    if dt < 1e-4 then return Vector3.zero end
    return (b.pos - a.pos) / dt
end

function Physics:eta(bPos, bVel, pPos)
    local delta   = pPos - bPos
    local dist    = delta.Magnitude
    if dist < 0.01 then return 0 end
    local closing = bVel:Dot(delta.Unit)
    if closing <= 0 then return math.huge end
    return dist / closing
end

function Physics:predict(bPos, bVel, dt)
    return bPos + bVel * dt + 0.5 * GRAV * dt * dt
end

function Physics:arc(bPos, bVel, totalTime, segs)
    local pts = {}
    for i = 0, segs do
        pts[i+1] = self:predict(bPos, bVel, totalTime * (i/segs))
    end
    return pts
end

function Physics:adaptWindow(current, successETA)
    local next = current * (1 - Config.adaptAlpha) + (successETA + 0.03) * Config.adaptAlpha
    return math.clamp(next, Config.minWindow, Config.maxWindow)
end

-- ═══════════════════════════════════════════════════════════════
--  OOP: BallState  (__index + __newindex side-effects)
-- ═══════════════════════════════════════════════════════════════
local BallState = {}
BallState.__index = BallState
BallState.onParried = Signal.new()

function BallState.new(ball)
    local raw = {
        ball      = ball,
        fired     = false,
        eta       = math.huge,
        speed     = 0,
        dist      = math.huge,
        closing   = false,
        threat    = false,
        physics   = Physics.new(),
        spawnAt   = os.clock(),
    }
    return setmetatable({}, {
        __index = function(_, k)
            if k == "alive" then return raw.ball and raw.ball.Parent ~= nil end
            if k == "age"   then return os.clock() - raw.spawnAt end
            return raw[k]
        end,
        __newindex = function(_, k, v)
            local old = raw[k]
            raw[k] = v
            if k == "fired" and v == true and old ~= true then
                BallState.onParried:Fire(raw.ball, raw.eta)
            end
        end,
    })
end

-- ═══════════════════════════════════════════════════════════════
--  OOP: Priority Queue  (min-heap by ETA)
-- ═══════════════════════════════════════════════════════════════
local PQ = {}
PQ.__index = PQ

function PQ.new()
    return setmetatable({ _h = {} }, PQ)
end

function PQ:push(item, p)
    table.insert(self._h, {item=item, p=p})
    table.sort(self._h, function(a,b) return a.p < b.p end)
end

function PQ:peek()   return self._h[1] end
function PQ:pop()    return table.remove(self._h, 1) end
function PQ:clear()  self._h = {} end
function PQ:size()   return #self._h end

-- ═══════════════════════════════════════════════════════════════
--  OOP: BallTracker
-- ═══════════════════════════════════════════════════════════════
local BallTracker = {}
BallTracker.__index = BallTracker

function BallTracker.new()
    local self = setmetatable({
        states      = {},
        window      = Config.parryWindow,
        parryCount  = 0,
        etaHistory  = {},
        queue       = PQ.new(),
        onParry     = Signal.new(),
        onDodge     = Signal.new(),
    }, BallTracker)

    self.onParry:Connect(function(_, eta)
        self.parryCount += 1
        table.insert(self.etaHistory, eta)
        if #self.etaHistory > 60 then table.remove(self.etaHistory, 1) end
    end)

    return self
end

function BallTracker:track(ball)
    if self.states[ball] then return end
    local s = BallState.new(ball)
    self.states[ball] = s

    pcall(function()
        ball:GetAttributeChangedSignal("target"):Connect(function()
            local st = self.states[ball]
            if st then st.fired = false end
        end)
    end)

    if namecallHooked then
        NamecallSignal:Connect(function(inst, method)
            if inst ~= ball then return end
            if method == "SetAttribute" or method == "GetAttributeChangedSignal" then
                local st = self.states[ball]
                if st then st.fired = false end
            end
        end)
    end
end

function BallTracker:untrack(ball)
    self.states[ball] = nil
end

function BallTracker:updateFrame(hrp, now)
    local ppos = hrp.Position
    local name = lp.Name
    self.queue:clear()

    for ball, state in pairs(self.states) do
        if not (ball and ball.Parent) then
            self.states[ball] = nil
            continue
        end
        local vp = ball:FindFirstChild("zoomies")
        if not vp then continue end

        local bvel = vp.VectorVelocity
        local bpos = ball.Position
        state.physics:push(bpos, bvel, now)

        -- pick best velocity estimate
        local derived = state.physics:derivedVel()
        local vel = bvel.Magnitude >= derived.Magnitude and bvel or derived

        local eta     = state.physics:eta(bpos, vel, ppos)
        state.speed   = vel.Magnitude
        state.dist    = (ppos - bpos).Magnitude
        state.eta     = eta
        state.closing = vel:Dot((ppos - bpos).Unit) > 0
        state.threat  = (ball:GetAttribute("target") == name)
            and state.closing
            and not state.fired

        if state.threat then
            self.queue:push(ball, eta)
        end
    end
end

function BallTracker:bestThreat()
    local top = self.queue:peek()
    if not top then return nil, math.huge end
    return top.item, top.p
end

function BallTracker:markParried(ball, eta)
    local s = self.states[ball]
    if not s then return end
    s.fired = true
    self.window = s.physics:adaptWindow(self.window, eta)
    Config.parryWindow = self.window
    self.onParry:Fire(ball, eta)
end

function BallTracker:avgETA()
    if #self.etaHistory == 0 then return 0 end
    local sum = 0
    for _, v in ipairs(self.etaHistory) do sum += v end
    return sum / #self.etaHistory
end

-- ═══════════════════════════════════════════════════════════════
--  ANIMATION FIX  (hookfunction + reflection on AnimationTrack)
-- ═══════════════════════════════════════════════════════════════
local AnimFix = { track = nil, lastAt = 0 }

local function installAnimHook()
    if not (Exec.UNC.hookfunction and Exec.UNC.newcclosure and Exec.UNC.getrawmetatable) then return end
    local dummy = Instance.new("Animation")
    local mt = pcall(getrawmetatable, dummy) and getrawmetatable(dummy)
    dummy:Destroy()
    if not mt then return end
    if Exec.UNC.setreadonly then pcall(setreadonly, mt, false) end
    local orig = rawget(mt, "__index")
    if type(orig) ~= "function" then
        if Exec.UNC.setreadonly then pcall(setreadonly, mt, true) end
        return
    end
    hookfunction(orig, newcclosure(function(self, k)
        local v = orig(self, k)
        if k == "Play" and type(v) == "function" then
            return newcclosure(function(track, ...)
                pcall(function()
                    local id = track.Animation and track.Animation.AnimationId or ""
                    if id:find("parr") or id:find("block") or id:find("deflect") then
                        AnimFix.track = track
                        AnimFix.lastAt = os.clock()
                    end
                end)
                return v(track, ...)
            end)
        end
        return v
    end))
    if Exec.UNC.setreadonly then pcall(setreadonly, mt, true) end
end

local function doAnimFix()
    if not Config.animFix or not AnimFix.track then return end
    if os.clock() - AnimFix.lastAt > 0.12 then return end
    pcall(function()
        if AnimFix.track.IsPlaying then AnimFix.track:Stop(0) end
        AnimFix.track:Play(0)
    end)
end

task.defer(installAnimHook)

-- ═══════════════════════════════════════════════════════════════
--  AUTO-DODGE  (perpendicular teleport from ball path)
-- ═══════════════════════════════════════════════════════════════
local Dodge = { lastAt = 0, busy = false }

function Dodge.attempt(hrp, bPos, bVel)
    if not Config.autoDodge or Dodge.busy then return end
    if os.clock() - Dodge.lastAt < 0.35 then return end
    Dodge.lastAt = os.clock()
    Dodge.busy = true
    task.spawn(function()
        local perp = bVel.Unit:Cross(Vector3.yAxis).Unit
        if math.random() > 0.5 then perp = -perp end
        local target = hrp.CFrame * CFrame.new(perp * Config.dodgeDist)
        TS:Create(hrp, TweenInfo.new(0.15, Enum.EasingStyle.Quad), { CFrame = target }):Play()
        task.wait(0.2)
        Dodge.busy = false
    end)
end

-- ═══════════════════════════════════════════════════════════════
--  HITBOX EXPANDER  (metatable __index override on BaseParts)
-- ═══════════════════════════════════════════════════════════════
local HitboxExpand = { _orig = {} }

function HitboxExpand.apply(char)
    if not Config.hitboxExpand then return end
    for _, p in ipairs(char:GetDescendants()) do
        if p:IsA("BasePart") and not HitboxExpand._orig[p] then
            HitboxExpand._orig[p] = p.Size
            pcall(function() p.Size = Config.hitboxSize end)
        end
    end
end

function HitboxExpand.remove(char)
    for part, orig in pairs(HitboxExpand._orig) do
        pcall(function() part.Size = orig end)
    end
    HitboxExpand._orig = {}
end

Config.Changed:Connect(function(k, v)
    local char = lp.Character
    if not char then return end
    if k == "hitboxExpand" then
        if v then HitboxExpand.apply(char) else HitboxExpand.remove(char) end
    end
end)

-- ═══════════════════════════════════════════════════════════════
--  PREDICTION ARC  (visualized ball trajectory dots)
-- ═══════════════════════════════════════════════════════════════
local Arc = { _dots = {} }

local function makeDot()
    local p = Instance.new("Part")
    p.Size = Vector3.new(0.18, 0.18, 0.18)
    p.Anchored = true
    p.CanCollide = false
    p.CastShadow = false
    p.Material = Enum.Material.Neon
    p.Color = Color3.fromRGB(255, 70, 70)
    p.Parent = cam
    return p
end

local function updateArc(ball, state)
    if not Config.predArc or not (ball and ball.Parent) then
        if Arc._dots[ball] then
            for _, d in ipairs(Arc._dots[ball]) do d:Destroy() end
            Arc._dots[ball] = nil
        end
        return
    end
    local vp = ball:FindFirstChild("zoomies")
    if not vp then return end

    local n = Config.arcSegments
    if not Arc._dots[ball] or #Arc._dots[ball] ~= n + 1 then
        if Arc._dots[ball] then
            for _, d in ipairs(Arc._dots[ball]) do d:Destroy() end
        end
        Arc._dots[ball] = {}
        for i = 1, n + 1 do Arc._dots[ball][i] = makeDot() end
    end

    local pts = state.physics:arc(ball.Position, vp.VectorVelocity, Config.arcDuration, n)
    for i, pt in ipairs(pts) do
        if Arc._dots[ball][i] then
            Arc._dots[ball][i].CFrame = CFrame.new(pt)
        end
    end
end

local function cleanArc(ball)
    if Arc._dots[ball] then
        for _, d in ipairs(Arc._dots[ball]) do d:Destroy() end
        Arc._dots[ball] = nil
    end
end

-- ═══════════════════════════════════════════════════════════════
--  ESP SYSTEM  (ball boxes + labels + player boxes)
-- ═══════════════════════════════════════════════════════════════
local ESP = { _bb = {}, _lbl = {}, _plr = {} }

local function ensureBallBox(ball)
    if not ESP._bb[ball] then
        local b = Instance.new("SelectionBox")
        b.Adornee = ball
        b.LineThickness = 0.06
        b.SurfaceTransparency = 0.82
        b.Parent = cam
        ESP._bb[ball] = b
    end
    return ESP._bb[ball]
end

local function ensureBallLabel(ball)
    if not ESP._lbl[ball] then
        local bb = Instance.new("BillboardGui")
        bb.AlwaysOnTop = true
        bb.Size = UDim2.fromOffset(120, 38)
        bb.StudsOffset = Vector3.new(0, 3, 0)
        bb.Adornee = ball
        bb.Parent = cam
        local tl = Instance.new("TextLabel", bb)
        tl.Size = UDim2.new(1,0,1,0)
        tl.BackgroundTransparency = 1
        tl.TextSize = 12
        tl.Font = Enum.Font.Code
        tl.TextStrokeTransparency = 0.3
        ESP._lbl[ball] = { bb = bb, tl = tl }
    end
    return ESP._lbl[ball]
end

local function updateBallESP(ball, state)
    if not Config.espBalls or not (ball and ball.Parent) then
        if ESP._bb[ball]  then ESP._bb[ball]:Destroy();         ESP._bb[ball]  = nil end
        if ESP._lbl[ball] then ESP._lbl[ball].bb:Destroy();     ESP._lbl[ball] = nil end
        return
    end
    local col = state.threat and Color3.fromRGB(255,50,50) or Color3.fromRGB(80,200,255)
    local box = ensureBallBox(ball)
    box.Color3        = col
    box.SurfaceColor3 = col

    local L = ensureBallLabel(ball)
    local etaStr = state.eta >= 99 and "∞" or ("%.3fs"):format(state.eta)
    local tgt = ball:GetAttribute("target") or "?"
    L.tl.Text = ("⚡ %s\nETA %s | %.0f/s"):format(tgt, etaStr, state.speed)
    L.tl.TextColor3 = state.threat and Color3.fromRGB(255,80,80) or Color3.fromRGB(140,220,255)
end

local function updatePlayerESP()
    if not Config.espPlayers then
        for p, b in pairs(ESP._plr) do b:Destroy(); ESP._plr[p] = nil end
        return
    end
    for _, p in ipairs(Plrs:GetPlayers()) do
        if p ~= lp and p.Character and not ESP._plr[p] then
            local b = Instance.new("SelectionBox")
            b.Adornee = p.Character
            b.Color3 = Color3.fromRGB(100,60,255)
            b.SurfaceColor3 = Color3.fromRGB(100,60,255)
            b.LineThickness = 0.05
            b.SurfaceTransparency = 0.80
            b.Parent = cam
            ESP._plr[p] = b
        end
    end
    for p, b in pairs(ESP._plr) do
        if not p.Character then b:Destroy(); ESP._plr[p] = nil end
    end
end

Plrs.PlayerRemoving:Connect(function(p)
    if ESP._plr[p] then ESP._plr[p]:Destroy(); ESP._plr[p] = nil end
end)

-- ═══════════════════════════════════════════════════════════════
--  CLIENT STATE MONITOR  (character + humanoid lifecycle)
-- ═══════════════════════════════════════════════════════════════
local ClientState = {
    alive     = false,
    humState  = nil,
    onDied    = Signal.new(),
    onSpawned = Signal.new(),
}

local function monitorChar(char)
    if not char then return end
    local hum = char:WaitForChild("Humanoid", 5)
    if not hum then return end
    ClientState.alive = true

    hum.StateChanged:Connect(function(_, new)
        ClientState.humState = new
    end)

    hum.Died:Connect(function()
        ClientState.alive = false
        ClientState.onDied:Fire()
    end)

    if Config.hitboxExpand then HitboxExpand.apply(char) end
end

lp.CharacterAdded:Connect(function(char)
    ClientState.onSpawned:Fire(char)
    task.spawn(monitorChar, char)
end)
task.spawn(monitorChar, lp.Character)

-- ═══════════════════════════════════════════════════════════════
--  COROUTINE: background sweep for hidden balls
-- ═══════════════════════════════════════════════════════════════
local function startSweep(tracker)
    local co = coroutine.wrap(function()
        while _G.WindHubActive do
            for _, obj in ipairs(WS:GetDescendants()) do
                if not tracker.states[obj] then
                    local ok, v = pcall(function()
                        return obj:GetAttribute("realBall")
                    end)
                    if ok and v ~= nil then
                        coroutine.yield("track", obj)
                    end
                end
            end
            coroutine.yield("wait", 2)
        end
    end)

    task.spawn(function()
        while _G.WindHubActive do
            local action, data = co()
            if action == "track" then
                tracker:track(data)
            elseif action == "wait" then
                task.wait(data)
            else
                task.wait()
            end
        end
    end)
end

-- ═══════════════════════════════════════════════════════════════
--  MANUAL SPAM  (coroutine loop, respects spamRate)
-- ═══════════════════════════════════════════════════════════════
local spamActive = false

Config.Changed:Connect(function(k, v)
    if k ~= "manualSpam" then return end
    if v and not spamActive then
        spamActive = true
        task.spawn(function()
            while Config.manualSpam and _G.WindHubActive do
                task.spawn(clickParry)
                task.wait(Config.spamRate)
            end
            spamActive = false
        end)
    end
end)

-- ═══════════════════════════════════════════════════════════════
--  PROFILER  (frame-time tracker)
-- ═══════════════════════════════════════════════════════════════
local Prof = { times = {}, last = os.clock() }

function Prof:tick()
    local now = os.clock()
    table.insert(self.times, now - self.last)
    self.last = now
    if #self.times > 60 then table.remove(self.times, 1) end
end

function Prof:fps()
    if #self.times == 0 then return 0 end
    local s = 0
    for _, v in ipairs(self.times) do s += v end
    return 1 / (s / #self.times)
end

-- ═══════════════════════════════════════════════════════════════
--  HOTKEYS
-- ═══════════════════════════════════════════════════════════════
local MODES = { "Ultra", "Predictive", "Conservative" }
local modeIdx = 2

UIS.InputBegan:Connect(function(i, gp)
    if gp then return end
    local k = i.KeyCode
    if     k == Enum.KeyCode.P then Config.autoParry    = not Config.autoParry;    print("[WindHub] Auto-Parry:",    Config.autoParry)
    elseif k == Enum.KeyCode.O then Config.manualSpam   = not Config.manualSpam;   print("[WindHub] Manual Spam:",   Config.manualSpam)
    elseif k == Enum.KeyCode.I then Config.animFix      = not Config.animFix;      print("[WindHub] Anim Fix:",      Config.animFix)
    elseif k == Enum.KeyCode.U then Config.autoDodge    = not Config.autoDodge;    print("[WindHub] Auto-Dodge:",    Config.autoDodge)
    elseif k == Enum.KeyCode.Y then Config.espBalls     = not Config.espBalls;     print("[WindHub] Ball ESP:",      Config.espBalls)
    elseif k == Enum.KeyCode.H then Config.hitboxExpand = not Config.hitboxExpand; print("[WindHub] Hitbox:",        Config.hitboxExpand)
    elseif k == Enum.KeyCode.G then Config.predArc      = not Config.predArc;      print("[WindHub] Pred Arc:",      Config.predArc)
    elseif k == Enum.KeyCode.F then Config.printStats   = not Config.printStats;   print("[WindHub] Stats:",         Config.printStats)
    elseif k == Enum.KeyCode.T then
        modeIdx = (modeIdx % #MODES) + 1
        Config.parryMode = MODES[modeIdx]
        print("[WindHub] Mode:", Config.parryMode)
    elseif k == Enum.KeyCode.R then
        Config.parryWindow = DEFAULTS.parryWindow
        print("[WindHub] Window reset →", DEFAULTS.parryWindow)
    end
end)

-- ═══════════════════════════════════════════════════════════════
--  INIT
-- ═══════════════════════════════════════════════════════════════
local tracker = BallTracker.new()

local ballsFolder = WS:FindFirstChild("Balls") or WS:WaitForChild("Balls", 30)
if ballsFolder then
    for _, b in ipairs(ballsFolder:GetChildren()) do tracker:track(b) end
    ballsFolder.ChildAdded:Connect(function(b)
        task.defer(function() tracker:track(b) end)
    end)
    ballsFolder.ChildRemoved:Connect(function(b)
        tracker:untrack(b)
        updateBallESP(b, { threat=false, eta=math.huge, speed=0 })
        cleanArc(b)
    end)
end

startSweep(tracker)

-- stats ticker (coroutine)
task.spawn(function()
    while _G.WindHubActive do
        task.wait(5)
        if Config.printStats then
            print(("[WindHub] parries:%d  window:%.3fs  avgETA:%.3fs  ping:%dms  fps:%.0f  mode:%s  hook:%s"):format(
                tracker.parryCount, tracker.window, tracker:avgETA(),
                PingComp.pingMs, Prof:fps(), Config.parryMode, tostring(namecallHooked)
            ))
        end
    end
end)

-- ═══════════════════════════════════════════════════════════════
--  MAIN LOOP  (RunService.PreSimulation — frame-by-frame)
-- ═══════════════════════════════════════════════════════════════
local parryBusy  = false
local frameCount = 0

RS.PreSimulation:Connect(function()
    if not _G.WindHubActive then return end
    Prof:tick()

    local char = lp.Character
    if not char then return end
    local hrp = char:FindFirstChild("HumanoidRootPart")
    if not hrp or not ClientState.alive then return end

    local now = os.clock()

    -- position + velocity tracking, threat queue rebuild
    tracker:updateFrame(hrp, now)

    -- visuals every 2nd frame
    frameCount += 1
    if frameCount % 2 == 0 then
        for ball, state in pairs(tracker.states) do
            updateBallESP(ball, state)
            updateArc(ball, state)
        end
        updatePlayerESP()
    end

    -- ── AUTO-PARRY ──────────────────────────────────────────────
    if Config.autoParry and not parryBusy then
        local threat, eta = tracker:bestThreat()

        -- Replion pre-arm: if server just targeted us (<150ms ago) and
        -- we have a closing ball, treat as Ultra regardless of mode
        local replionRecent = _G.WindHub_ReplionTargeted
            and (os.clock() - _G.WindHub_ReplionTargeted) < 0.15

        if threat then
            local win = PingComp:effectiveWindow()
            local mode = Config.parryMode
            local fire = replionRecent
                or (mode == "Ultra")
                or (mode == "Predictive"    and eta <= win)
                or (mode == "Conservative"  and eta <= win * 0.55)

            if fire then
                parryBusy = true
                tracker:markParried(threat, eta)
                doAnimFix()
                task.spawn(function()
                    clickParry()
                    task.wait(0.1)
                    parryBusy = false
                end)
            end
        end
    end

    -- ── AUTO-DODGE fallback ─────────────────────────────────────
    if Config.autoDodge and not parryBusy then
        local threat, eta = tracker:bestThreat()
        if threat and eta < 0.75 then
            local vp = threat:FindFirstChild("zoomies")
            if vp then
                Dodge.attempt(hrp, threat.Position, vp.VectorVelocity)
            end
        end
    end
end)

-- ═══════════════════════════════════════════════════════════════
--  STARTUP
-- ═══════════════════════════════════════════════════════════════
task.spawn(function()
    task.wait(1.2)
    print("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━")
    print("  WindHub v4.0  |  Blade Ball")
    print(("  Exec: %-12s  Platform: %s"):format(Exec.name, Exec.isPC and "PC" or "Mobile"))
    print(("  Namecall hook: %-5s  Ping: %dms"):format(tostring(namecallHooked), PingComp.pingMs))
    print("  P=parry  O=spam  I=animfix  U=dodge")
    print("  Y=ballesp  H=hitbox  G=arc  T=mode  F=stats")
    print("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━")
end)
