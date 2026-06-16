--[[
  SangraBB v3.0  |  Full-Spectrum Blade Ball
  ─────────────────────────────────────────────────────────────────
  Lua/Luau  : metatables · __index · __newindex · __namecall ·
              closures · coroutines · tables · custom events · OOP
  Analysis  : position · velocity · trajectory prediction · EMA
              timing · frame updates · client state monitoring
  Roblox    : RunService · Players · Workspace · UserInputService
              RemoteEvent spy · RemoteFunction spy
  Executor  : hookfunction · metatable mod · env manipulation ·
              debug extensions · reflection · virtual input
  Features  : auto-parry (physics) · manual spam · anim fix ·
              UNC device scan · adaptive window · ball ESP labels
--]]

-- ═══════════════════════════════════════════════════════════════
--  SERVICES
-- ═══════════════════════════════════════════════════════════════
local RS   = game:GetService("RunService")
local Plrs = game:GetService("Players")
local UIS  = game:GetService("UserInputService")
local WS   = workspace
local lp   = Plrs.LocalPlayer

if _G.SangraBBv3 then _G.SangraBBv3 = false task.wait(0.05) end
_G.SangraBBv3 = true

-- ═══════════════════════════════════════════════════════════════
--  OOP: Custom Signal  (Events)
-- ═══════════════════════════════════════════════════════════════
local Signal = {}
Signal.__index = Signal

function Signal.new()
    -- closure over private connection list
    local self = setmetatable({ _list = {}, _nextId = 0 }, Signal)
    return self
end

function Signal:Connect(fn)
    self._nextId += 1
    local id = self._nextId
    self._list[id] = fn
    -- return a disconnect handle via __index closure
    return setmetatable({}, {
        __index = {
            Disconnect = function() self._list[id] = nil end
        }
    })
end

function Signal:Fire(...)
    for _, fn in pairs(self._list) do task.spawn(fn, ...) end
end

function Signal:Wait()
    local co = coroutine.running()
    local conn
    conn = self:Connect(function(...)
        conn:Disconnect()
        task.spawn(co, ...)
    end)
    return coroutine.yield()
end

-- ═══════════════════════════════════════════════════════════════
--  OOP: Config  (__index defaults · __newindex validation)
-- ═══════════════════════════════════════════════════════════════
local CFG_DEFAULTS = {
    autoParry      = true,
    manualSpam     = false,
    spamRate       = 0.08,   -- seconds between spam clicks
    parryWindow    = 0.52,   -- ETA threshold to fire parry
    adaptAlpha     = 0.12,   -- EMA learning rate
    animFix        = true,   -- reset parry anim on each parry
    espLabels      = true,   -- floating ETA labels on balls
    maxAdaptWindow = 1.1,
    minAdaptWindow = 0.18,
}

local Config = {}
Config.Changed = Signal.new()

setmetatable(Config, {
    __index    = CFG_DEFAULTS,
    __newindex = function(t, k, v)
        if CFG_DEFAULTS[k] == nil then return end  -- reject unknown keys
        local old = rawget(t, k) or CFG_DEFAULTS[k]
        rawset(t, k, v)
        if old ~= v then Config.Changed:Fire(k, v, old) end
    end,
})

-- ═══════════════════════════════════════════════════════════════
--  EXECUTOR / DEVICE PROBE  (reflection + environment)
-- ═══════════════════════════════════════════════════════════════
local Exec = (function()
    local e = {}

    -- executor name via reflection
    pcall(function()
        local fn = identifyexecutor or getexecutorname
        if type(fn) == "function" then e.name = tostring(fn()):lower() end
    end)
    e.name = e.name or ""

    -- platform
    e.isMobile = UIS.TouchEnabled and not UIS.KeyboardEnabled
    e.isPC     = UIS.KeyboardEnabled or UIS.MouseEnabled

    -- UNC capability table built via reflection
    local function has(name) return type(_G[name]) == "function"
        or type(getfenv(0)[name]) == "function" end

    e.UNC = {
        hookfunction    = has "hookfunction",
        newcclosure     = has "newcclosure",
        getrawmetatable = has "getrawmetatable",
        setreadonly     = has "setreadonly",
        getupvalues     = has "getupvalues",
        getconstants    = has "getconstants",
        getprotos       = has "getprotos",
        getnamecallmethod = has "getnamecallmethod",
        firetouchinterest = has "firetouchinterest",
        VIM = pcall(function() game:GetService("VirtualInputManager") end),
    }

    -- debug library extensions (reflection)
    e.dbg = {
        getupvalues = type(debug) == "table" and type(debug.getupvalues) == "function",
        getconstants= type(debug) == "table" and type(debug.getconstants)== "function",
    }

    return e
end)()

-- ═══════════════════════════════════════════════════════════════
--  VIRTUAL INPUT  (device-aware)
-- ═══════════════════════════════════════════════════════════════
local VIM = (function()
    local ok, svc = pcall(function() return game:GetService("VirtualInputManager") end)
    return ok and svc or nil
end)()

local function fireClick()
    if Exec.isMobile and VIM and VIM.SendTouchEvent then
        local cx = WS.CurrentCamera.ViewportSize.X * 0.5
        local cy = WS.CurrentCamera.ViewportSize.Y * 0.5
        pcall(function() VIM:SendTouchEvent(0, Vector2.new(cx,cy), true,  game) end)
        task.wait(0.04)
        pcall(function() VIM:SendTouchEvent(0, Vector2.new(cx,cy), false, game) end)
    elseif VIM then
        pcall(function() VIM:SendMouseButtonEvent(0,0,0,true, game,0) end)
        task.wait(0.04)
        pcall(function() VIM:SendMouseButtonEvent(0,0,0,false,game,0) end)
    end
end

-- ═══════════════════════════════════════════════════════════════
--  METATABLE HOOK: __namecall intercept
-- ═══════════════════════════════════════════════════════════════
local onBallNamecall = Signal.new()  -- fires(ball, method, ...)

local function installNamecallHook()
    if not (Exec.UNC.hookfunction and Exec.UNC.newcclosure
            and Exec.UNC.getrawmetatable and Exec.UNC.getnamecallmethod) then
        return false
    end
    local mt = getrawmetatable(game)
    if Exec.UNC.setreadonly then pcall(setreadonly, mt, false) end

    local original = rawget(mt, "__namecall")
    if not original then return false end

    local hooked = newcclosure(function(self, ...)
        local method = getnamecallmethod()
        -- intercept attribute/method calls on BaseParts (balls)
        if typeof(self) == "Instance" and self:IsA("BasePart") then
            onBallNamecall:Fire(self, method, ...)
        end
        return original(self, ...)
    end)

    hookfunction(original, hooked)
    if Exec.UNC.setreadonly then pcall(setreadonly, mt, true) end
    return true
end

local namecallHooked = installNamecallHook()

-- ═══════════════════════════════════════════════════════════════
--  REMOTE SPY  (RemoteEvent + RemoteFunction monitor)
-- ═══════════════════════════════════════════════════════════════
local RemoteSpy = {}
RemoteSpy.onFire   = Signal.new()  -- (remote, args)
RemoteSpy.onInvoke = Signal.new()  -- (remote, args)

local function spyRemotes(parent)
    for _, obj in ipairs(parent:GetDescendants()) do
        if obj:IsA("RemoteEvent") then
            obj.OnClientEvent:Connect(function(...)
                RemoteSpy.onFire:Fire(obj, {...})
            end)
        elseif obj:IsA("RemoteFunction") then
            local prev = obj.OnClientInvoke
            obj.OnClientInvoke = function(...)
                RemoteSpy.onInvoke:Fire(obj, {...})
                if prev then return prev(...) end
            end
        end
    end
end

task.spawn(spyRemotes, WS)
task.spawn(spyRemotes, game:GetService("ReplicatedStorage"))

-- listen for remotes that mention "parry" or "ball" — useful for
-- detecting when the server confirms a parry
RemoteSpy.onFire:Connect(function(remote, args)
    local n = remote.Name:lower()
    if n:find("parry") or n:find("ball") or n:find("block") then
        _G.SangraBB_LastRemote = { name = remote.Name, args = args, t = os.clock() }
    end
end)

-- ═══════════════════════════════════════════════════════════════
--  REFLECTION: scan upvalues/constants in Animate script
--  Used for animation fix — find the parry AnimationTrack
-- ═══════════════════════════════════════════════════════════════
local function reflectFindTrack(animateFn, trackName)
    if not (Exec.UNC.getupvalues and Exec.UNC.getprotos) then return nil end
    local function searchProto(fn, depth)
        if depth > 5 then return nil end
        local ok, uvs = pcall(getupvalues, fn)
        if ok then
            for _, v in pairs(uvs) do
                if type(v) == "table" then
                    for _, item in pairs(v) do
                        if type(item) == "userdata" then
                            local s,n = pcall(function() return item.Name end)
                            if s and type(n) == "string" and n:lower():find(trackName) then
                                return item
                            end
                        end
                    end
                end
            end
        end
        local ok2, protos = pcall(getprotos, fn)
        if ok2 then
            for _, p in pairs(protos) do
                if type(p) == "function" then
                    local r = searchProto(p, depth + 1)
                    if r then return r end
                end
            end
        end
        return nil
    end
    return searchProto(animateFn, 0)
end

-- ═══════════════════════════════════════════════════════════════
--  OOP: Physics Engine  (trajectory prediction)
-- ═══════════════════════════════════════════════════════════════
local Physics = {}
Physics.__index = Physics

function Physics.new()
    return setmetatable({
        samples = {},     -- ring buffer: {pos, t}
        maxSamples = 8,
    }, Physics)
end

-- Dot-product closing speed → ETA
function Physics:timeToImpact(ballPos, ballVel, playerPos)
    local delta        = playerPos - ballPos
    local dist         = delta.Magnitude
    if dist < 0.01 then return 0, ballVel.Magnitude end
    local closingSpeed = ballVel:Dot(delta.Unit)
    if closingSpeed <= 0 then return math.huge, closingSpeed end
    return dist / closingSpeed, closingSpeed
end

-- Quadratic extrapolation: predict ball position at t+dt
function Physics:predictPosition(ballPos, ballVel, dt)
    -- gravity estimate (blade ball balls are slightly affected)
    local GRAVITY = Vector3.new(0, -workspace.Gravity * 0.05, 0)
    return ballPos + ballVel * dt + 0.5 * GRAVITY * dt * dt
end

-- Push position sample (velocity tracking via finite differences)
function Physics:pushSample(pos, t)
    table.insert(self.samples, { pos = pos, t = t })
    if #self.samples > self.maxSamples then
        table.remove(self.samples, 1)
    end
end

-- Derive velocity from samples (more stable than raw VectorVelocity)
function Physics:derivedVelocity()
    local n = #self.samples
    if n < 2 then return Vector3.zero end
    local s0, s1 = self.samples[n-1], self.samples[n]
    local dt = s1.t - s0.t
    if dt < 0.001 then return Vector3.zero end
    return (s1.pos - s0.pos) / dt
end

-- EMA adaptive window
function Physics:adaptWindow(current, successETA, alpha)
    local next = current * (1 - alpha) + (successETA + 0.025) * alpha
    return math.clamp(next, Config.minAdaptWindow, Config.maxAdaptWindow)
end

-- ═══════════════════════════════════════════════════════════════
--  OOP: BallState  (__index + __newindex for change tracking)
-- ═══════════════════════════════════════════════════════════════
local BallState = {}
BallState.__index = BallState

function BallState.new(ball)
    local data = {
        ball      = ball,
        fired     = false,
        eta       = math.huge,
        speed     = 0,
        dist      = math.huge,
        closing   = false,
        physics   = Physics.new(),
    }
    local proxy = {}
    local mt = {
        __index = function(_, k)
            if k == "alive" then return ball and ball.Parent ~= nil end
            return data[k]
        end,
        __newindex = function(_, k, v)
            local old = data[k]
            data[k] = v
            -- __newindex: fire internal event on important state changes
            if k == "fired" and v == true and old == false then
                if _G.SangraBB_onParry then _G.SangraBB_onParry:Fire(ball, data.eta) end
            end
        end,
    }
    return setmetatable(proxy, mt)
end

-- ═══════════════════════════════════════════════════════════════
--  OOP: BallTracker  (coroutine workers + OOP)
-- ═══════════════════════════════════════════════════════════════
local BallTracker = {}
BallTracker.__index = BallTracker

function BallTracker.new()
    local self = setmetatable({
        states      = {},       -- ball → BallState
        parryCount  = 0,
        window      = Config.parryWindow,
        onParry     = Signal.new(),
    }, BallTracker)
    _G.SangraBB_onParry = self.onParry
    return self
end

function BallTracker:track(ball)
    if self.states[ball] then return end
    local s = BallState.new(ball)
    self.states[ball] = s

    -- attribute signal (fallback when __namecall hook unavailable)
    pcall(function()
        ball:GetAttributeChangedSignal("target"):Connect(function()
            local st = self.states[ball]
            if st then st.fired = false end
        end)
    end)

    -- if namecall hook is live, also reset via that signal
    if namecallHooked then
        onBallNamecall:Connect(function(inst, method)
            if inst == ball and method == "GetAttributeChangedSignal" then
                local st = self.states[ball]
                if st then st.fired = false end
            end
        end)
    end
end

function BallTracker:untrack(ball)
    self.states[ball] = nil
end

function BallTracker:updateFrame(hrp)
    local ppos = hrp.Position
    local now  = os.clock()

    for ball, state in pairs(self.states) do
        if not (ball and ball.Parent) then
            self.states[ball] = nil
            continue
        end

        local velPart = ball:FindFirstChild("zoomies")
        if not velPart then continue end

        local bvel = velPart.VectorVelocity
        local bpos = ball.Position

        -- push sample for derived velocity (velocity tracking)
        state.physics:pushSample(bpos, now)

        -- use both sources: VectorVelocity and derived, pick larger magnitude
        local derived = state.physics:derivedVelocity()
        local vel = bvel.Magnitude > derived.Magnitude and bvel or derived

        local eta, closing = state.physics:timeToImpact(bpos, vel, ppos)

        state.speed   = vel.Magnitude
        state.dist    = (ppos - bpos).Magnitude
        state.eta     = eta
        state.closing = closing > 0
    end
end

function BallTracker:bestThreat()
    local best, bestETA = nil, math.huge
    local name = lp.Name
    for ball, state in pairs(self.states) do
        if ball and ball.Parent
            and not state.fired
            and state.closing
            and ball:GetAttribute("target") == name
            and state.eta < bestETA
        then
            best = ball; bestETA = state.eta
        end
    end
    return best, bestETA
end

function BallTracker:markParried(ball)
    local state = self.states[ball]
    if not state then return end
    local capturedETA = state.eta
    state.fired = true   -- triggers __newindex onParry signal
    self.parryCount += 1
    self.window = state.physics:adaptWindow(self.window, capturedETA, Config.adaptAlpha)
    Config.parryWindow = self.window   -- sync back to config (__newindex fires Config.Changed)
end

-- ═══════════════════════════════════════════════════════════════
--  ANIMATION FIX  (hookfunction on AnimationTrack:Play)
-- ═══════════════════════════════════════════════════════════════
local AnimFix = {}

function AnimFix.install(tracker)
    if not (Exec.UNC.hookfunction and Exec.UNC.newcclosure and Exec.UNC.getrawmetatable) then
        return
    end

    local char = lp.Character or lp.CharacterAdded:Wait()
    local animate = char:FindFirstChild("Animate")
    if not animate or not animate:IsA("LocalScript") then return end

    -- try to find parry track via reflection
    local parryTrack = reflectFindTrack(require, "parry")
    AnimFix._track = parryTrack

    -- hook AnimationTrack:Play at metatable level to detect parry anim
    local atProto = getrawmetatable(Instance.new("Animation"))
    if not atProto then return end
    if Exec.UNC.setreadonly then pcall(setreadonly, atProto, false) end

    local origPlay = rawget(atProto, "Play") or rawget(atProto, "__index")
    if type(origPlay) ~= "function" then return end

    hookfunction(origPlay, newcclosure(function(self, ...)
        local ok, name = pcall(function() return self.Name end)
        if ok and type(name) == "string" and name:lower():find("parr") then
            AnimFix._lastParryAt = os.clock()
            AnimFix._lastTrack   = self
        end
        return origPlay(self, ...)
    end))

    if Exec.UNC.setreadonly then pcall(setreadonly, atProto, true) end
end

-- Ensures the parry anim replays cleanly (fixes animation stuttering)
local function doAnimFix()
    if not Config.animFix then return end
    local track = AnimFix._lastTrack
    if not track then return end
    local last  = AnimFix._lastParryAt or 0
    if os.clock() - last < 0.05 then return end   -- already recent
    pcall(function()
        if track.IsPlaying then track:Stop(0) end
        track:Play(0)
    end)
end

-- ═══════════════════════════════════════════════════════════════
--  COROUTINE: background ball sweep (workspace scan)
-- ═══════════════════════════════════════════════════════════════
local function bgSweep(tracker)
    -- coroutine-based worker so it yields without blocking main loop
    local co = coroutine.create(function()
        while _G.SangraBBv3 do
            for _, obj in ipairs(WS:GetDescendants()) do
                if not tracker.states[obj] then
                    local ok, v = pcall(function() return obj:GetAttribute("realBall") end)
                    if ok and v ~= nil then
                        coroutine.yield("track", obj)
                    end
                end
            end
            coroutine.yield("sleep")
        end
    end)

    task.spawn(function()
        while _G.SangraBBv3 do
            local ok, action, val = coroutine.resume(co)
            if not ok or coroutine.status(co) == "dead" then break end
            if action == "track" then
                tracker:track(val)
            elseif action == "sleep" then
                task.wait(1.5)
            end
        end
    end)
end

-- ═══════════════════════════════════════════════════════════════
--  CLIENT STATE MONITOR  (humanoid, character events)
-- ═══════════════════════════════════════════════════════════════
local ClientState = {
    isAlive     = false,
    isDead      = false,
    humState    = nil,
    onDied      = Signal.new(),
    onRespawned = Signal.new(),
}

local function watchCharacter(char)
    if not char then return end
    local hum = char:WaitForChild("Humanoid", 5)
    if not hum then return end

    ClientState.isAlive = true
    ClientState.isDead  = false

    hum.StateChanged:Connect(function(_, new)
        ClientState.humState = new
        if new == Enum.HumanoidStateType.Dead then
            ClientState.isAlive = false
            ClientState.isDead  = true
            ClientState.onDied:Fire()
        end
    end)

    hum.Died:Connect(function()
        ClientState.isAlive = false
        ClientState.isDead  = true
        _G.SangraBBv3 = false   -- pause on death
        task.wait(1)
        _G.SangraBBv3 = true
    end)
end

lp.CharacterAdded:Connect(function(char)
    ClientState.onRespawned:Fire(char)
    watchCharacter(char)
end)
watchCharacter(lp.Character)

-- ═══════════════════════════════════════════════════════════════
--  MANUAL SPAM MODE  (coroutine-based rapid fire)
-- ═══════════════════════════════════════════════════════════════
local spamActive = false

Config.Changed:Connect(function(k, v)
    if k == "manualSpam" then
        if v and not spamActive then
            spamActive = true
            task.spawn(function()
                while Config.manualSpam and _G.SangraBBv3 do
                    task.spawn(fireClick)   -- spawned so it never blocks
                    task.wait(Config.spamRate)
                end
                spamActive = false
            end)
        end
    end
end)

-- Key toggles (no UI — just keyboard shortcuts)
UIS.InputBegan:Connect(function(i, gp)
    if gp then return end
    if i.KeyCode == Enum.KeyCode.P then
        Config.autoParry = not Config.autoParry
    elseif i.KeyCode == Enum.KeyCode.O then
        Config.manualSpam = not Config.manualSpam
    elseif i.KeyCode == Enum.KeyCode.I then
        Config.animFix = not Config.animFix
    end
end)

-- ═══════════════════════════════════════════════════════════════
--  ESP LABELS (floating ETA / speed on each ball)
-- ═══════════════════════════════════════════════════════════════
local labels = {}   -- ball → BillboardGui

local function updateLabel(ball, state)
    if not Config.espLabels then
        if labels[ball] then labels[ball]:Destroy(); labels[ball] = nil end
        return
    end
    if not (ball and ball.Parent) then
        if labels[ball] then labels[ball]:Destroy(); labels[ball] = nil end
        return
    end
    if not labels[ball] then
        local bb = Instance.new("BillboardGui")
        bb.AlwaysOnTop = true
        bb.Size = UDim2.fromOffset(90, 30)
        bb.StudsOffset = Vector3.new(0, 2, 0)
        bb.Adornee = ball
        bb.Parent = WS.CurrentCamera
        local tl = Instance.new("TextLabel", bb)
        tl.Size = UDim2.new(1,0,1,0)
        tl.BackgroundTransparency = 1
        tl.TextColor3 = state.eta < 0.5
            and Color3.fromRGB(255,80,80)
            or  Color3.fromRGB(80,255,160)
        tl.TextSize = 13
        tl.Font = Enum.Font.Code
        tl.TextStrokeTransparency = 0.4
        labels[ball] = { bb = bb, lbl = tl }
    end
    local d = labels[ball]
    local tgt = ball:GetAttribute("target") or "?"
    d.lbl.Text = ("%.2fs  %.0f\n→ %s"):format(
        math.min(state.eta, 99), state.speed, tgt)
    d.lbl.TextColor3 = state.eta < 0.5
        and Color3.fromRGB(255,80,80)
        or  Color3.fromRGB(80,255,160)
end

-- ═══════════════════════════════════════════════════════════════
--  MAIN INIT
-- ═══════════════════════════════════════════════════════════════
local tracker = BallTracker.new()

-- watch Balls folder
local ballsFolder = WS:FindFirstChild("Balls")
    or WS:WaitForChild("Balls", 20)

if ballsFolder then
    for _, b in ipairs(ballsFolder:GetChildren()) do
        tracker:track(b)
    end
    ballsFolder.ChildAdded:Connect(function(b)
        task.defer(tracker.track, tracker, b)
    end)
    ballsFolder.ChildRemoved:Connect(function(b)
        tracker:untrack(b)
        if labels[b] then labels[b].bb:Destroy(); labels[b] = nil end
    end)
end

-- background coroutine sweep
bgSweep(tracker)

-- install anim hook
task.defer(AnimFix.install, AnimFix, tracker)

-- log parry confirmations
tracker.onParry:Connect(function(ball, eta)
    _G.SangraBB_Stats = {
        parries = tracker.parryCount,
        window  = tracker.window,
        lastETA = eta,
    }
end)

-- ═══════════════════════════════════════════════════════════════
--  FRAME LOOP  (RunService.PreSimulation — frame-by-frame)
-- ═══════════════════════════════════════════════════════════════
local parryBusy = false   -- gate so we never double-fire in one frame

RS.PreSimulation:Connect(function()
    if not _G.SangraBBv3 then return end
    if not ClientState.isAlive then return end

    local char = lp.Character
    if not char then return end
    local hrp = char:FindFirstChild("HumanoidRootPart")
    if not hrp then return end

    -- frame-by-frame update: position + velocity tracking
    tracker:updateFrame(hrp)

    -- update ESP labels (distance calculations inside updateLabel)
    for ball, state in pairs(tracker.states) do
        updateLabel(ball, state)
    end

    -- auto-parry: fire when best threat ETA ≤ adaptive window
    if Config.autoParry and not parryBusy then
        local threat, eta = tracker:bestThreat()
        if threat and eta <= tracker.window then
            parryBusy = true
            tracker:markParried(threat)
            doAnimFix()
            task.spawn(function()
                fireClick()
                task.wait(0.12)
                parryBusy = false
            end)
        end
    end
end)

-- small status print (no UI)
task.spawn(function()
    task.wait(2)
    print(("[SangraBB v3] loaded | exec:%s | platform:%s | namecall:%s"):format(
        Exec.name == "" and "unknown" or Exec.name,
        Exec.isMobile and "mobile" or "pc",
        tostring(namecallHooked)
    ))
    print("  [P] toggle auto-parry | [O] toggle spam | [I] toggle anim-fix")
end)
