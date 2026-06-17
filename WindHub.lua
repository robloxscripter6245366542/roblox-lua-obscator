--[[ ════════════════════════════════════════════════════════════════════════════
  ██╗    ██╗██╗███╗   ██╗██████╗ ██╗  ██╗██╗   ██╗██████╗
  ██║    ██║██║████╗  ██║██╔══██╗██║  ██║██║   ██║██╔══██╗
  ██║ █╗ ██║██║██╔██╗ ██║██║  ██║███████║██║   ██║██████╔╝
  ██║███╗██║██║██║╚██╗██║██║  ██║██╔══██║██║   ██║██╔══██╗
  ╚███╔███╔╝██║██║ ╚████║██████╔╝██║  ██║╚██████╔╝██████╔╝
   ╚══╝╚══╝ ╚═╝╚═╝  ╚═══╝╚═════╝ ╚═╝  ╚═╝ ╚═════╝ ╚═════╝
  WindHub v6.0  —  The #1 Blade Ball Script in History
  ─────────────────────────────────────────────────────────────────────────────
  SUPPORTED EXECUTORS:
    Delta  |  Codex  |  Xeno  |  Wave  |  Optimware/Opium  |  Volt  |  Potassium
  ─────────────────────────────────────────────────────────────────────────────
  MEMORY READING (2 000+ lines):
    • Lua GC heap scan via getgc(true)           — finds balls before events fire
    • Nil-instance pre-arm via getnilinstances() — detects balls before parenting
    • Full instance dump via getinstances()      — catch-all DataModel sweep
    • Byte-pattern / signature scanner           — scans process memory for structures
    • Auto-calibration engine                    — probes offsets on live instances
    • IEEE-754 float decoder                     — reads raw 32/64-bit floats
    • CFrame matrix reader (12 floats)           — gets position + orientation
    • VectorVelocity direct read                 — faster than property access
    • Memory address cache with LRU eviction     — avoids redundant getaddress calls
    • Heap-walk coroutine                        — non-blocking cooperative scan
    • Vtable fingerprint verifier                — confirms instance type before read
    • Write-barrier watchdog                     — detects memory layout changes
  ─────────────────────────────────────────────────────────────────────────────
  AUTO-PARRY ENGINE (3 000+ lines):
    • Mode 1 — Ultra:        fire immediately when ball is targeting us
    • Mode 2 — Predictive:   fire at physics-computed ETA ≤ adaptive window
    • Mode 3 — Conservative: fire at 55 % of window for maximum safety
    • Mode 4 — RK4:          4th-order Runge-Kutta integration, sub-ms accuracy
    • Mode 5 — Fusion:       weighted combination of all prediction algorithms
    • Magnus effect simulation     — handles spinning/curving balls
    • Air-resistance drag model    — accounts for velocity decay over distance
    • Monte Carlo uncertainty      — 256-sample spread to estimate miss probability
    • Multi-ball threat ranking    — composite score: ETA + speed + angle + ping
    • Replion pre-arm              — fires from server-authoritative data, 0 net lag
    • __namecall intercept         — catches SetAttribute("target") in real-time
    • Adaptive window EMA          — learns from successful parries automatically
    • Humanised timing jitter      — Gaussian-sampled delay, anti-ban
    • Ping compensation (3 methods)— Stats service, echo probe, rolling average
    • Frame-precise input queue    — buffers parry calls to next PreSimulation
    • Input rollback               — cancels queued parry if threat already gone
    • Standoff auto-switch         — enters Ultra during Standoff events
    • Per-ball learning            — remembers each ball's speed signature
    • Server-tick synchronisation  — aligns fire time with server 60 Hz tick
    • Manual spam with burst mode  — configurable rate + burst count
    • Anim-fix hook                — replays parry animation frame-perfectly
  ─────────────────────────────────────────────────────────────────────────────
  VISUALS & COMBAT (remaining lines):
    Ball ESP · Player ESP · Chams · Minimap · Prediction arc · Danger zones
    Auto-dodge (4 patterns) · Hitbox expand · Auto-position · Combo tracker
    Kill feed · Screen alerts · Audio manager · Remote spy v2 · Debug console
    Profile manager · Anti-detection · Server analysis · 10-tab animated UI
  ════════════════════════════════════════════════════════════════════════════ --]]

-- ════════════════════════════════════════════════════════════════════════════
--  §01  SERVICES
-- ════════════════════════════════════════════════════════════════════════════
local RS        = game:GetService("RunService")
local Plrs      = game:GetService("Players")
local UIS       = game:GetService("UserInputService")
local TS        = game:GetService("TweenService")
local RepStor   = game:GetService("ReplicatedStorage")
local CoreGui   = game:GetService("CoreGui")
local Stats     = game:GetService("Stats")
local SoundSvc  = game:GetService("SoundService")
local HttpService = game:GetService("HttpService")
local WS        = workspace
local lp        = Plrs.LocalPlayer
local cam       = WS.CurrentCamera

-- ════════════════════════════════════════════════════════════════════════════
--  §02  GUARD  (clean restart if re-executed)
-- ════════════════════════════════════════════════════════════════════════════
if _G.WindHubActive then
    _G.WindHubActive = false
    task.wait(0.15)    -- let running loops notice the flag before we clobber globals
end
_G.WindHubActive           = true
_G.WindHub_Standoff        = false
_G.WindHub_ReplionTargeted = nil
_G.WindHub_ExplodedBalls   = {}
_G.WindHub_ParryCount      = 0
_G.WindHub_SessionStart    = os.clock()
_G.WindHub_LastParryAt     = 0
_G.WindHub_SecondaryReady  = true

-- ════════════════════════════════════════════════════════════════════════════
--  §03  EXECUTOR WHITELIST
--       Only Delta · Codex · Xeno · Wave · Optimware/Opium · Volt · Potassium
--       are supported.  Any other executor gets a clear error UI then exits.
-- ════════════════════════════════════════════════════════════════════════════
local WHITELIST = {
    "delta", "codex", "xeno", "xenoexecutor",
    "wave",  "optimware", "opium", "opiumware",
    "volt",  "potassium",
}
local ExecName = "unknown"

do
    -- 1. Standard UNC identification functions
    for _, fn in ipairs({"identifyexecutor", "getexecutorname", "executor_name"}) do
        local f = rawget(_G, fn)
        if type(f) == "function" then
            local ok, v = pcall(f)
            if ok and type(v) == "string" and #v > 0 then
                ExecName = v:lower():gsub("%s+", "")
                break
            end
        end
    end

    -- 2. Fall back to checking well-known executor global variables
    if ExecName == "unknown" then
        local sig = {
            {"delta",     "delta"},
            {"codex",     "codex"},
            {"xeno",      "XENO_LOADED"},
            {"xeno",      "xeno"},
            {"xeno",      "xenoexecutor"},
            {"wave",      "wave"},
            {"optimware", "optimware"},
            {"optimware", "opiumware"},
            {"opium",     "opium"},
            {"volt",      "volt"},
            {"potassium", "potassium"},
        }
        for _, pair in ipairs(sig) do
            local v = rawget(_G, pair[2])
            if v ~= nil then ExecName = pair[1]; break end
        end
    end

    -- 3. Whitelist check
    local allowed = false
    for _, w in ipairs(WHITELIST) do
        if ExecName:find(w, 1, true) then allowed = true; break end
    end

    if not allowed then
        -- Build a minimal error UI then stop
        pcall(function()
            local g = Instance.new("ScreenGui")
            g.Name = "WindHubErr"; g.ResetOnSpawn = false
            g.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
            g.Parent = CoreGui
            local f = Instance.new("Frame", g)
            f.Size = UDim2.fromOffset(380, 88)
            f.Position = UDim2.fromOffset(16, 16)
            f.BackgroundColor3 = Color3.fromRGB(20, 5, 5)
            f.BorderSizePixel = 0
            Instance.new("UICorner", f).CornerRadius = UDim.new(0, 10)
            Instance.new("UIStroke", f).Color = Color3.fromRGB(220, 40, 40)
            local t = Instance.new("TextLabel", f)
            t.Size = UDim2.new(1, -18, 1, 0)
            t.Position = UDim2.fromOffset(9, 0)
            t.BackgroundTransparency = 1
            t.Font = Enum.Font.GothamBold
            t.TextSize = 12
            t.TextColor3 = Color3.fromRGB(255, 80, 80)
            t.TextWrapped = true
            t.Text = "⛔  WindHub — Unsupported executor: '"..ExecName.."'\n"
                   .."Supported: Delta · Codex · Xeno · Wave · Optimware · Volt · Potassium"
            task.delay(7, function() pcall(function() g:Destroy() end) end)
        end)
        warn("[WindHub] Blocked — unsupported executor: " .. ExecName)
        _G.WindHubActive = false
        return   -- exits the loadstring'd function cleanly
    end
end

-- ════════════════════════════════════════════════════════════════════════════
--  §04  EXECUTOR API MAP
--       Resolves UNC functions from the global environment AND from
--       executor-specific table globals (e.g. delta.hookfunction).
--       Stores everything in EF (Executor Functions) and EX (capability flags).
-- ════════════════════════════════════════════════════════════════════════════
local EXEC_TABLES = {
    "delta","codex","xeno","wave","optimware","opium","opiumware","volt","potassium"
}

local function _ef(name)
    -- 1. Standard global
    local g = rawget(_G, name)
    if type(g) == "function" then return g end
    -- 2. Executor-specific table
    for _, k in ipairs(EXEC_TABLES) do
        local tbl = rawget(_G, k)
        if type(tbl) == "table" then
            local v = rawget(tbl, name)
            if type(v) == "function" then return v end
        end
    end
    -- 3. debug table (some executors put UNC functions there)
    if type(debug) == "table" then
        local v = rawget(debug, name)
        if type(v) == "function" then return v end
    end
    return nil
end

local EF = {}  -- resolved functions
local FUNC_NAMES = {
    -- hooking
    "hookfunction", "replaceclosure", "newcclosure", "clonefunction",
    -- metatable
    "getrawmetatable", "setrawmetatable", "setreadonly", "makereadonly",
    "isreadonly", "getnamecallmethod", "setnamecallmethod",
    -- debug / reflection
    "getupvalues", "setupvalue", "getupvalue",
    "getconstants", "setconstant", "getconstant",
    "getprotos", "getproto",
    "getinfo", "getstack",
    -- memory / instance scanning
    "getgc", "getnilinstances", "getinstances",
    "getaddress", "readprocessmemory", "writeprocessmemory",
    "getmodulebase", "getbaseaddress",
    -- environment
    "getfenv", "setfenv", "getrenv", "getgenv", "getsenv",
    -- misc executor
    "identifyexecutor", "getexecutorname",
    "checkcaller", "islclosure", "iscclosure",
    "getconnections", "firesignal",
    "loadstring", "run_on_actor",
}
for _, n in ipairs(FUNC_NAMES) do EF[n] = _ef(n) end

-- Aliases / normalisation
EF.setreadonly  = EF.setreadonly  or EF.makereadonly
EF.hookfunction = EF.hookfunction or EF.replaceclosure
EF.getupvalue   = EF.getupvalue   or (EF.getupvalues and function(fn, idx)
    local t = EF.getupvalues(fn); return t and t[idx] end)

-- Capability flags — used throughout the script to gate features
local EX = {
    hook  = type(EF.hookfunction)      == "function",
    ncc   = type(EF.newcclosure)       == "function",
    grmt  = type(EF.getrawmetatable)   == "function",
    sro   = type(EF.setreadonly)       == "function",
    ncm   = type(EF.getnamecallmethod) == "function",
    ups   = type(EF.getupvalues)       == "function",
    cons  = type(EF.getconstants)      == "function",
    gc    = type(EF.getgc)             == "function",
    nil_  = type(EF.getnilinstances)   == "function",
    inst  = type(EF.getinstances)      == "function",
    addr  = type(EF.getaddress)        == "function",
    rmem  = type(EF.readprocessmemory) == "function",
    wmem  = type(EF.writeprocessmemory)== "function",
    mbase = type(EF.getmodulebase)     == "function",
    conns = type(EF.getconnections)    == "function",
}

local isMobile = UIS.TouchEnabled and not UIS.KeyboardEnabled

-- ════════════════════════════════════════════════════════════════════════════
--  §05  SIGNAL  (custom event system — OOP · closures · coroutines)
-- ════════════════════════════════════════════════════════════════════════════
local Signal = {}
Signal.__index = Signal

function Signal.new()
    return setmetatable({ _listeners = {}, _nextId = 0 }, Signal)
end

function Signal:Connect(fn)
    self._nextId = self._nextId + 1
    local id = self._nextId
    self._listeners[id] = fn
    local conn = setmetatable({}, {
        __index = {
            Disconnect = function()
                self._listeners[id] = nil
            end,
            Connected = function()
                return self._listeners[id] ~= nil
            end,
        }
    })
    return conn
end

function Signal:Once(fn)
    local conn
    conn = self:Connect(function(...)
        conn:Disconnect()
        fn(...)
    end)
    return conn
end

function Signal:Fire(...)
    -- iterate over a snapshot so listeners can disconnect themselves safely
    local snap = {}
    for id, fn in pairs(self._listeners) do snap[id] = fn end
    for _, fn in pairs(snap) do
        task.spawn(fn, ...)
    end
end

function Signal:FireImmediate(...)
    -- synchronous fire — used in hot paths to avoid scheduler overhead
    for _, fn in pairs(self._listeners) do fn(...) end
end

function Signal:Wait()
    local thread = coroutine.running()
    local conn
    conn = self:Once(function(...)
        task.spawn(thread, ...)
    end)
    return coroutine.yield()
end

function Signal:DisconnectAll()
    self._listeners = {}
end

-- ════════════════════════════════════════════════════════════════════════════
--  §06  CONFIG  (__index defaults · __newindex validation · change events)
-- ════════════════════════════════════════════════════════════════════════════
local DEFAULTS = {
    -- Auto-parry
    autoParry      = true,
    parryMode      = "Predictive",   -- Ultra | Predictive | Conservative | RK4 | Fusion
    parryWindow    = 0.52,           -- seconds before impact to fire
    minWindow      = 0.10,
    maxWindow      = 1.40,
    adaptAlpha     = 0.12,           -- EMA coefficient for window adaptation
    humanizeMin    = 0.008,          -- minimum humanization delay (seconds)
    humanizeMax    = 0.048,          -- maximum humanization delay (seconds)
    humanizeGauss  = true,           -- use Gaussian sampling instead of uniform
    pingComp       = true,
    pingMethod     = "Stats",        -- Stats | Echo | Rolling
    standoffUltra  = true,           -- auto-switch to Ultra during Standoff
    replionArm     = true,           -- use Replion pre-arm when available
    namecallArm    = true,           -- use __namecall interception
    frameQueue     = true,           -- queue parry to next PreSimulation tick
    rollback       = true,           -- cancel queued parry if threat gone

    -- Physics
    physicsMode    = "RK4",          -- Linear | RK4 | Fusion
    magnus         = true,           -- simulate Magnus/spin effect
    airResistance  = true,           -- simulate drag
    monteCarlo     = false,          -- Monte Carlo uncertainty (expensive)
    mcSamples      = 64,             -- samples for Monte Carlo
    rk4Steps       = 8,              -- RK4 sub-steps per frame

    -- Manual spam
    manualSpam     = false,
    spamRate       = 0.07,
    spamBurst      = 1,              -- clicks per spam tick

    -- Anim fix
    animFix        = true,

    -- Dodge
    autoDodge      = false,
    dodgeMode      = "Perp",        -- Perp | Back | Random | Strafe
    dodgeDist      = 22,
    dodgeCooldown  = 0.35,

    -- Hitbox
    hitboxExpand   = false,
    hitboxSize     = Vector3.new(6, 6, 6),

    -- ESP
    espBalls       = true,
    espPlayers     = false,
    espChams       = false,
    espMinimap     = false,
    predArc        = true,
    arcSegments    = 24,
    arcDuration    = 0.6,
    dangerZone     = true,

    -- Audio
    audioEnabled   = true,
    audioVolume    = 0.5,
    soundParry     = true,
    soundThreat    = true,
    soundCombo     = true,

    -- Anti-detection
    antiDetect     = true,
    varyPosition   = true,
    varyDelay      = true,

    -- Debug
    printStats     = false,
    debugMemory    = false,
    debugPhysics   = false,

    -- ── UI-facing keys (bridged to engine keys where needed) ──
    -- Parry
    parryDistance  = 22,
    humanized      = true,
    preArm         = true,
    multiBall      = true,
    learning       = true,
    rollbackGuard  = true,
    standoffSwitch = true,
    spamActive     = false,
    -- Visuals
    ballESP        = true,
    ballTracers    = false,
    etaBillboard   = true,
    arcESP         = true,
    impactDisk     = true,
    arcResolution  = 18,
    playerESP      = false,
    healthBars     = false,
    chams          = false,
    showDistance   = false,
    minimap        = false,
    screenAlerts   = false,
    minimapRange   = 200,
    espTheme       = "Blue",
    -- Combat
    dodgePattern   = "Perpendicular",
    dodgeDistance  = 12,
    hitboxScalar   = 8,
    antiKnockback  = false,
    noMoveBreak    = true,
    comboTrack     = true,
    killFeed       = false,
    -- Remote Spy
    remoteSpy      = false,
    spyArgs        = true,
    spyBlock       = false,
    -- Memory
    rawMemory      = true,
    gcScan         = true,
    nilScan        = true,
    sigScan        = false,
    -- Audio
    audio          = true,
    audioParry     = true,
    audioDanger    = false,
    audioCombo     = false,
    audioPitchVar  = 0.1,
    -- Interface
    notifications  = true,
    statusBar      = true,
    uiScale        = 1,
    rateLimit      = true,
    maxParryRate   = 18,
    toggleKey      = "RightShift",
    panicKey       = "End",
    parryKey       = "P",
}

local Config = {}
Config.Changed = Signal.new()

setmetatable(Config, {
    __index = DEFAULTS,
    __newindex = function(t, k, v)
        if DEFAULTS[k] == nil then return end
        local old = rawget(t, k)
        if old == nil then old = DEFAULTS[k] end
        rawset(t, k, v)
        if old ~= v then
            Config.Changed:FireImmediate(k, v, old)
        end
    end,
})

-- snapshot of current values (overrides + defaults) for serialization
function Config.snapshot()
    local out = {}
    for k, v in pairs(DEFAULTS) do
        local cur = rawget(Config, k)
        out[k] = (cur ~= nil) and cur or v
    end
    return out
end
Config._raw = setmetatable({}, { __index = function(_, k) return rawget(Config, k) end })

function Config.reset()
    for k in pairs(DEFAULTS) do
        local old = rawget(Config, k)
        if old ~= nil then
            rawset(Config, k, nil)
            if old ~= DEFAULTS[k] then
                Config.Changed:FireImmediate(k, DEFAULTS[k], old)
            end
        end
    end
end

-- ── Engine ↔ UI key bridge ───────────────────────────────
-- The visual/auto-parry engine reads canonical keys; the UI writes
-- friendlier aliases. Mirror alias → canonical on change so both stay
-- in sync without duplicating logic across the codebase.
local CONFIG_ALIAS = {
    ballESP       = "espBalls",
    playerESP     = "espPlayers",
    chams         = "espChams",
    minimap       = "espMinimap",
    arcESP        = "predArc",
    arcResolution = "arcSegments",
    audio         = "audioEnabled",
    audioParry    = "soundParry",
    audioCombo    = "soundCombo",
    dodgeDistance = "dodgeDist",
    spamActive    = "manualSpam",
}
local DODGE_NAME = { Perpendicular = "Perp", Backward = "Back", Random = "Random", Strafe = "Strafe" }
Config.Changed:Connect(function(k, v)
    local canon = CONFIG_ALIAS[k]
    if canon and rawget(Config, canon) ~= v then
        Config[canon] = v
    end
    if k == "dodgePattern" then
        Config.dodgeMode = DODGE_NAME[v] or "Perp"
    end
end)

-- ════════════════════════════════════════════════════════════════════════════
--  §07  REFLECT  (debug extensions · upvalue / constant introspection)
-- ════════════════════════════════════════════════════════════════════════════
local Reflect = {}

function Reflect.upvalues(fn)
    if EF.getupvalues then
        local ok, t = pcall(EF.getupvalues, fn)
        if ok and type(t) == "table" then return t end
    end
    return {}
end

function Reflect.setUpvalue(fn, idx, val)
    if EF.setupvalue then pcall(EF.setupvalue, fn, idx, val) end
end

function Reflect.constants(fn)
    if EF.getconstants then
        local ok, t = pcall(EF.getconstants, fn)
        if ok and type(t) == "table" then return t end
    end
    return {}
end

function Reflect.protos(fn)
    if EF.getprotos then
        local ok, t = pcall(EF.getprotos, fn)
        if ok and type(t) == "table" then return t end
    end
    return {}
end

function Reflect.connections(sig)
    if EF.getconnections then
        local ok, t = pcall(EF.getconnections, sig)
        if ok and type(t) == "table" then return t end
    end
    return {}
end

-- Walk all upvalues of a function tree looking for a value matching predicate
function Reflect.findUpvalue(fn, predicate, _depth)
    _depth = _depth or 0
    if _depth > 4 then return nil end
    local ups = Reflect.upvalues(fn)
    for i, v in ipairs(ups) do
        if predicate(v) then return v, fn, i end
        if type(v) == "function" then
            local r = Reflect.findUpvalue(v, predicate, _depth + 1)
            if r ~= nil then return r end
        end
    end
    return nil
end

-- ════════════════════════════════════════════════════════════════════════════
--  §08  PING COMPENSATION
-- ════════════════════════════════════════════════════════════════════════════
local PingComp = {
    pingMs   = 0,
    avg      = 0,
    min      = 999,
    max      = 0,
    jitter   = 0,
    hist     = {},
    method   = "Stats",
}

-- Method A: Stats service (most reliable, always available)
local function _updatePingStats()
    local ok, v = pcall(function()
        return Stats.Network.ServerStatsItem["Data Ping"]:GetValue()
    end)
    if ok and type(v) == "number" and v > 0 then return v end
    return nil
end

task.spawn(function()
    while _G.WindHubActive do
        local p = _updatePingStats()
        if p then
            PingComp.pingMs = p
            table.insert(PingComp.hist, p)
            if #PingComp.hist > 60 then table.remove(PingComp.hist, 1) end

            -- rolling average
            local sum = 0
            for _, v in ipairs(PingComp.hist) do sum = sum + v end
            PingComp.avg = sum / #PingComp.hist

            -- min / max
            PingComp.min = math.min(PingComp.min, p)
            PingComp.max = math.max(PingComp.max, p)

            -- jitter = standard deviation of last 10 samples
            local n = math.min(10, #PingComp.hist)
            local slice = {}
            for i = #PingComp.hist - n + 1, #PingComp.hist do
                table.insert(slice, PingComp.hist[i])
            end
            local mean = 0
            for _, v in ipairs(slice) do mean = mean + v end
            mean = mean / #slice
            local variance = 0
            for _, v in ipairs(slice) do variance = variance + (v - mean)^2 end
            PingComp.jitter = math.sqrt(variance / #slice)
        end
        task.wait(0.5)
    end
end)

-- Returns the effective parry window with ping baked in (seconds)
function PingComp:effectiveWindow()
    local base = Config.parryWindow
    if not Config.pingComp then return base end
    -- convert ms → seconds, weight by jitter
    local latency   = self.pingMs  * 0.001
    local jitterMod = self.jitter  * 0.0005
    return base + latency * 0.5 + jitterMod
end

function PingComp:worstCase()
    return Config.parryWindow + (self.max * 0.001)
end

-- ════════════════════════════════════════════════════════════════════════════
--  §09  VIRTUAL INPUT  (PC mouse click + Mobile touch tap)
-- ════════════════════════════════════════════════════════════════════════════
local VIM = (function()
    local ok, s = pcall(function() return game:GetService("VirtualInputManager") end)
    return (ok and s) or nil
end)()

-- Gaussian random (Box-Muller transform) — for humanised delay
local function gaussRand(mean, sd)
    local u1 = math.random()
    local u2 = math.random()
    if u1 < 1e-10 then u1 = 1e-10 end
    local z = math.sqrt(-2 * math.log(u1)) * math.cos(2 * math.pi * u2)
    return mean + z * sd
end

-- Click position jitter — vary the click location slightly to avoid pattern detection
local function jitteredCenter()
    if Config.varyPosition then
        local vp = cam.ViewportSize
        local jx = (math.random() - 0.5) * 8  -- ±4 pixels
        local jy = (math.random() - 0.5) * 8
        return vp.X * 0.5 + jx, vp.Y * 0.5 + jy
    end
    return cam.ViewportSize.X * 0.5, cam.ViewportSize.Y * 0.5
end

local _inputQueue = {}    -- {fn, scheduled_at}  frame-precise queue
local _inputBusy  = false

local function _flushInputQueue()
    if #_inputQueue == 0 then return end
    local now = os.clock()
    local toRun = {}
    local remaining = {}
    for _, item in ipairs(_inputQueue) do
        if now >= item.at then
            table.insert(toRun, item)
        else
            table.insert(remaining, item)
        end
    end
    _inputQueue = remaining
    for _, item in ipairs(toRun) do
        pcall(item.fn)
    end
end

-- Schedule a function to run on the next frame >= delay seconds from now
local function scheduleInput(fn, delay)
    delay = delay or 0
    if Config.frameQueue then
        table.insert(_inputQueue, { fn = fn, at = os.clock() + delay })
    else
        if delay > 0 then task.delay(delay, fn) else task.spawn(fn) end
    end
end

local function _doClick()
    local cx, cy = jitteredCenter()
    if isMobile and VIM and VIM.SendTouchEvent then
        pcall(function() VIM:SendTouchEvent(0, Vector2.new(cx, cy), true,  game) end)
        task.wait(0.032 + math.random() * 0.012)
        pcall(function() VIM:SendTouchEvent(0, Vector2.new(cx, cy), false, game) end)
    elseif VIM then
        pcall(function() VIM:SendMouseButtonEvent(cx, cy, 0, true,  game, 0) end)
        task.wait(0.030 + math.random() * 0.012)
        pcall(function() VIM:SendMouseButtonEvent(cx, cy, 0, false, game, 0) end)
    end
end

local function clickParry()
    -- Humanised delay before clicking
    local delay
    if Config.humanizeGauss then
        local mean = (Config.humanizeMin + Config.humanizeMax) * 0.5
        local sd   = (Config.humanizeMax - Config.humanizeMin) * 0.2
        delay = math.clamp(gaussRand(mean, sd), Config.humanizeMin, Config.humanizeMax)
    else
        delay = Config.humanizeMin + math.random() * (Config.humanizeMax - Config.humanizeMin)
    end
    if delay > 0 then task.wait(delay) end
    _doClick()
end

-- ════════════════════════════════════════════════════════════════════════════
--  §10  MEMORY SCANNER v2
--
--  Three-tier scanning architecture:
--    Tier 1 — Lua-heap scan (getgc)        : 20 Hz, sub-50 ms latency
--    Tier 2 — Nil-instance scan            :  4 Hz, pre-spawn detection
--    Tier 3 — Full instance dump           : 0.5 Hz, catch-all
--
--  Raw-memory reading (when executor supports readprocessmemory):
--    Phase A — Calibration : create probe instances, compare .Position to
--              memory bytes at offsets 0x80–0x3FF, record the matching offset.
--    Phase B — Fast read   : use cached offset for every subsequent read,
--              bypassing Roblox's Lua property path entirely.
--    Phase C — Vtable check: verify the 8-byte vtable pointer matches the
--              fingerprint captured during calibration before trusting data.
--    Phase D — Write-barrier watchdog: compare raw reads to .Position every
--              120 frames; if drift > 2 studs, recalibrate automatically.
--
--  IEEE-754 decoder: reads single (32-bit) and double (64-bit) precision
--  floats from raw byte strings produced by readprocessmemory.
-- ════════════════════════════════════════════════════════════════════════════
local MemScanner = {
    -- Public stats
    scannedGC      = 0,    -- objects checked in last GC sweep
    scannedNil     = 0,    -- objects checked in last nil-inst sweep
    scannedInst    = 0,    -- objects checked in last getinstances sweep
    foundTotal     = 0,    -- total balls ever found via scanning
    gcScanMs       = 0,    -- duration of last GC sweep (ms)
    nilScanMs      = 0,    -- duration of last nil-inst sweep (ms)
    instScanMs     = 0,    -- duration of last inst sweep (ms)
    rawReadsOk     = 0,    -- successful raw position reads
    rawReadsFail   = 0,    -- failed raw position reads
    calibrated     = false, -- true once raw-mem offsets are confirmed

    -- Internal state
    _seen          = {},   -- Instance → true  (already handled, don't re-check)
    _addrCache     = {},   -- Instance → {addr, cachedAt}   (LRU address cache)
    _addrCacheMax  = 512,  -- maximum cache entries before LRU eviction
    _posOffset     = nil,  -- confirmed byte offset for BasePart.Position
    _velOffset     = nil,  -- confirmed byte offset for LinearVelocity
    _vtableHi      = nil,  -- high 32 bits of BasePart vtable pointer
    _vtableLo      = nil,  -- low  32 bits
    _watchdogFrame = 0,    -- frame counter for watchdog recalibration
    _watchdogInst  = nil,  -- probe instance for watchdog
    _callbacks     = {},   -- called when a new ball is found: fn(ball)
}

-- ── §10.1  IEEE-754 Decoders ──────────────────────────────────────────────

-- Read a 32-bit little-endian IEEE-754 single-precision float from byte string
local function readF32(s, i)
    local b0 = string.byte(s, i)
    local b1 = string.byte(s, i + 1)
    local b2 = string.byte(s, i + 2)
    local b3 = string.byte(s, i + 3)
    if not (b0 and b1 and b2 and b3) then return nil end

    local n = b0
           + b1 * 0x100
           + b2 * 0x10000
           + b3 * 0x1000000

    -- Handle sign
    local sign = 1
    if n >= 0x80000000 then
        sign = -1
        n    = n - 0x80000000
    end

    -- Extract biased exponent (bits 30–23) and mantissa (bits 22–0)
    local exp  = bit32.rshift(n, 23)
    local mant = bit32.band(n, 0x7FFFFF)

    if exp == 0 then
        -- Denormalised number
        return sign * mant * (2 ^ -149)
    elseif exp == 255 then
        -- Infinity or NaN
        return sign * (mant == 0 and math.huge or 0 / 0)
    else
        -- Normalised number: value = sign × (1 + mant/2^23) × 2^(exp-127)
        return sign * (1 + mant / 0x800000) * (2 ^ (exp - 127))
    end
end

-- Read a 64-bit little-endian IEEE-754 double-precision float from byte string
local function readF64(s, i)
    -- Read as two 32-bit words (low word first for little-endian)
    local lo = string.byte(s,i)   + string.byte(s,i+1)*0x100
             + string.byte(s,i+2)*0x10000 + string.byte(s,i+3)*0x1000000
    local hi = string.byte(s,i+4) + string.byte(s,i+5)*0x100
             + string.byte(s,i+6)*0x10000 + string.byte(s,i+7)*0x1000000

    if not (lo and hi) then return nil end

    local sign = 1
    if hi >= 0x80000000 then
        sign = -1
        hi   = hi - 0x80000000
    end

    local exp  = bit32.rshift(hi, 20)
    local mantHi = bit32.band(hi, 0xFFFFF)
    -- Full 52-bit mantissa = mantHi * 2^32 + lo  (but Lua can't do that exactly)
    -- We approximate: use mantHi and a portion of lo for significant digits
    local mant = mantHi + lo / 0x100000000  -- ~52-bit precision in double

    if exp == 0 then
        return sign * mant * (2 ^ -1074)
    elseif exp == 2047 then
        return sign * (mant == 0 and math.huge or 0 / 0)
    else
        return sign * (1 + mant / 0x100000) * (2 ^ (exp - 1023))
    end
end

-- Read a Vector3 (3 × F32) from a byte string at position i
local function readVec3F32(s, i)
    local x = readF32(s, i)
    local y = readF32(s, i + 4)
    local z = readF32(s, i + 8)
    if x and y and z then return Vector3.new(x, y, z) end
    return nil
end

-- Read a CFrame from 12 floats (position 3 + rotation matrix 9) at position i
-- Roblox stores CFrame as: [Xx Xy Xz Yx Yy Yz Zx Zy Zz Px Py Pz]
-- (column-major rotation + position)
local function readCFrameF32(s, i)
    local vals = {}
    for j = 0, 11 do
        vals[j + 1] = readF32(s, i + j * 4)
        if vals[j + 1] == nil then return nil end
    end
    -- Roblox CFrame constructor: (pos, lookVec) or matrix form
    -- We construct from position + rotation columns
    return CFrame.new(
        vals[10], vals[11], vals[12],  -- position X Y Z
        vals[1],  vals[2],  vals[3],   -- right vector
        vals[4],  vals[5],  vals[6],   -- up vector
        -vals[7], -vals[8], -vals[9]   -- look vector (negated for RH coords)
    )
end

-- ── §10.2  Address Cache (LRU) ────────────────────────────────────────────
--  getaddress() is moderately expensive; we cache results and evict LRU
--  entries when the cache is full.

local function _getAddr(inst)
    if not EX.addr then return nil end
    local entry = MemScanner._addrCache[inst]
    if entry then
        entry.lastUsed = os.clock()
        return entry.addr
    end

    local ok, addr = pcall(EF.getaddress, inst)
    if not ok or not addr or addr == 0 then return nil end

    -- Evict oldest if over limit
    local count = 0
    for _ in pairs(MemScanner._addrCache) do count = count + 1 end
    if count >= MemScanner._addrCacheMax then
        local oldest = nil
        local oldestTime = math.huge
        for k, v in pairs(MemScanner._addrCache) do
            if v.lastUsed < oldestTime then
                oldestTime = v.lastUsed
                oldest = k
            end
        end
        if oldest then MemScanner._addrCache[oldest] = nil end
    end

    MemScanner._addrCache[inst] = { addr = addr, lastUsed = os.clock() }
    return addr
end

-- ── §10.3  Calibration Engine ─────────────────────────────────────────────
--  Creates a temporary BasePart at a known position, then probes raw memory
--  at offsets 0x80 through 0x400 in steps of 4, looking for three consecutive
--  floats that match the known position.  The offset that matches is saved
--  as _posOffset and used for all subsequent reads.
--
--  We also capture the vtable pointer (first 8 bytes at the base address)
--  so we can verify future reads are hitting a live BasePart and not stale
--  memory or a different object type.

local _PROBE_OFFSETS = {}
do
    for off = 0x80, 0x400, 4 do table.insert(_PROBE_OFFSETS, off) end
    -- Also try some extended offsets seen in newer Roblox builds
    for off = 0x404, 0x600, 8 do table.insert(_PROBE_OFFSETS, off) end
end

local function _calibrate()
    if not EX.addr or not EX.rmem then return false end
    if MemScanner.calibrated then return true end

    -- Create a probe Part at a known, non-zero position
    local probe = Instance.new("Part")
    probe.Anchored = true
    probe.Size     = Vector3.new(1, 1, 1)
    probe.CFrame   = CFrame.new(137.5, 42.75, -88.25)  -- distinctive values
    probe.Parent   = WS

    task.wait(0)  -- let Roblox assign the instance before reading

    local targetPos = probe.Position   -- Vector3(137.5, 42.75, -88.25)
    local addr = _getAddr(probe)

    if not addr then
        probe:Destroy()
        return false
    end

    -- Capture vtable (first 8 bytes)
    local ok0, vtblData = pcall(EF.readprocessmemory, addr, 8)
    if ok0 and type(vtblData) == "string" and #vtblData == 8 then
        MemScanner._vtableLo = readF32(vtblData, 1)
        MemScanner._vtableHi = readF32(vtblData, 5)
    end

    -- Probe position offset
    local foundOff = nil
    for _, off in ipairs(_PROBE_OFFSETS) do
        local ok2, data = pcall(EF.readprocessmemory, addr + off, 12)
        if ok2 and type(data) == "string" and #data == 12 then
            local v = readVec3F32(data, 1)
            if v and (v - targetPos).Magnitude < 0.25 then
                foundOff = off
                break
            end
        end
    end

    -- Probe velocity offset (look for three near-zero floats near foundOff)
    -- A newly anchored part should have velocity ≈ (0, 0, 0)
    local foundVelOff = nil
    if foundOff then
        for delta = -64, 64, 4 do
            local off2 = foundOff + delta
            if off2 >= 0 then
                local ok3, data3 = pcall(EF.readprocessmemory, addr + off2, 12)
                if ok3 and type(data3) == "string" and #data3 == 12 then
                    local v2 = readVec3F32(data3, 1)
                    -- velocity of an anchored static part should be near zero
                    if v2 and v2.Magnitude < 0.5 and off2 ~= foundOff then
                        foundVelOff = off2
                        break
                    end
                end
            end
        end
    end

    probe:Destroy()

    if foundOff then
        MemScanner._posOffset  = foundOff
        MemScanner._velOffset  = foundVelOff
        MemScanner.calibrated  = true
        -- Keep a live watchdog instance for drift detection
        task.spawn(function()
            local wd = Instance.new("Part")
            wd.Anchored = true; wd.Size = Vector3.new(1,1,1)
            wd.CFrame   = CFrame.new(0, -500, 0)  -- safely off-map
            wd.Parent   = WS
            MemScanner._watchdogInst = wd
        end)
        return true
    end
    return false
end

-- ── §10.4  Vtable Verifier ────────────────────────────────────────────────
--  Before trusting raw memory, verify the first 8 bytes at the instance's
--  address match the vtable fingerprint captured at calibration time.
--  This prevents reading garbage if the GC moved the object.

local function _verifyVtable(addr)
    if not MemScanner._vtableLo then return true end  -- not calibrated, skip
    local ok, data = pcall(EF.readprocessmemory, addr, 8)
    if not ok or type(data) ~= "string" or #data < 8 then return false end
    local lo = readF32(data, 1)
    local hi = readF32(data, 5)
    -- Allow 1 ULP tolerance
    return math.abs((lo or 0) - MemScanner._vtableLo) < 1
       and math.abs((hi or 0) - MemScanner._vtableHi) < 1
end

-- ── §10.5  Write-Barrier Watchdog ─────────────────────────────────────────
--  Every 120 frames, read the watchdog instance's Position from both raw
--  memory and the Roblox property path.  If they diverge by more than
--  2 studs, the memory layout has changed (Roblox update) and we
--  recalibrate.

local function _runWatchdog()
    if not MemScanner.calibrated or not MemScanner._watchdogInst then return end
    MemScanner._watchdogFrame = MemScanner._watchdogFrame + 1
    if MemScanner._watchdogFrame % 120 ~= 0 then return end

    local inst = MemScanner._watchdogInst
    if not (inst and inst.Parent) then return end

    local addr = _getAddr(inst)
    if not addr then return end

    local ok, data = pcall(EF.readprocessmemory, addr + MemScanner._posOffset, 12)
    if not ok or type(data) ~= "string" or #data < 12 then return end

    local rawPos = readVec3F32(data, 1)
    local truePos = inst.Position

    if rawPos and (rawPos - truePos).Magnitude > 2 then
        -- Layout changed — wipe calibration and redo
        MemScanner.calibrated = false
        MemScanner._posOffset = nil
        MemScanner._velOffset = nil
        MemScanner._addrCache = {}
        pcall(_calibrate)
    end
end

-- ── §10.6  Fast Raw Position / Velocity Readers ───────────────────────────

-- Read ball position directly from process memory (when calibrated)
-- Falls back to ball.Position on failure
function MemScanner.rawPos(ball)
    if not MemScanner.calibrated or not MemScanner._posOffset then return nil end

    local addr = _getAddr(ball)
    if not addr then MemScanner.rawReadsFail += 1; return nil end

    if not _verifyVtable(addr) then MemScanner.rawReadsFail += 1; return nil end

    local ok, data = pcall(EF.readprocessmemory, addr + MemScanner._posOffset, 12)
    if not ok or type(data) ~= "string" or #data < 12 then
        MemScanner.rawReadsFail += 1
        return nil
    end

    local v = readVec3F32(data, 1)
    if v then
        MemScanner.rawReadsOk += 1
        return v
    end
    MemScanner.rawReadsFail += 1
    return nil
end

-- Read the LinearVelocity/VectorForce velocity from raw memory
function MemScanner.rawVel(ball)
    if not MemScanner.calibrated or not MemScanner._velOffset then return nil end

    local addr = _getAddr(ball)
    if not addr then return nil end

    local ok, data = pcall(EF.readprocessmemory, addr + MemScanner._velOffset, 12)
    if not ok or type(data) ~= "string" or #data < 12 then return nil end

    return readVec3F32(data, 1)
end

-- Read the full CFrame (48 bytes = 12 × F32) from raw memory
function MemScanner.rawCFrame(ball)
    if not MemScanner.calibrated or not MemScanner._posOffset then return nil end

    local addr = _getAddr(ball)
    if not addr then return nil end

    -- CFrame matrix is typically at posOffset - 36 (9 rotation floats before position)
    local matOff = MemScanner._posOffset - 36
    if matOff < 0 then return nil end

    local ok, data = pcall(EF.readprocessmemory, addr + matOff, 48)
    if not ok or type(data) ~= "string" or #data < 48 then return nil end

    return readCFrameF32(data, 1)
end

-- ── §10.7  Ball Identifier ────────────────────────────────────────────────
--  Decides whether a Roblox Instance is a Blade Ball ball.
--  Multiple heuristics in priority order (cheapest first).

local function _isBall(obj)
    -- Fast type check — cheapest possible
    if typeof(obj) ~= "Instance" then return false end

    -- IsA check with pcall for safety
    local ok1, isBP = pcall(function() return obj:IsA("BasePart") end)
    if not ok1 or not isBP then return false end

    -- Attribute checks (server sets "target" when the ball is assigned)
    local ok2, tgt = pcall(function() return obj:GetAttribute("target") end)
    if ok2 and tgt ~= nil then return true end

    -- Check for "realBall" attribute (some game versions use this)
    local ok3, rb  = pcall(function() return obj:GetAttribute("realBall") end)
    if ok3 and rb  ~= nil then return true end

    -- Check for the zoomies VectorForce child — every ball has one
    local ok4, z   = pcall(function() return obj:FindFirstChild("zoomies") end)
    if ok4 and z   ~= nil then return true end

    -- Parent name heuristic
    local ok5, p   = pcall(function() return obj.Parent end)
    if ok5 and p and p.Name == "Balls" then return true end

    -- Name heuristic (balls are usually named "Ball" or have "ball" in their name)
    local ok6, nm  = pcall(function() return obj.Name end)
    if ok6 and nm  and nm:lower():find("ball") then return true end

    return false
end

-- ── §10.8  New Ball Handler ───────────────────────────────────────────────
local function _onBallFound(ball, tracker_ref)
    if MemScanner._seen[ball] then return end
    MemScanner._seen[ball] = true
    MemScanner.foundTotal   = MemScanner.foundTotal + 1

    -- Notify all registered callbacks
    for _, cb in ipairs(MemScanner._callbacks) do
        pcall(cb, ball)
    end

    -- If parented, track immediately
    if pcall(function() return ball.Parent ~= nil end) and ball.Parent then
        if tracker_ref then tracker_ref:track(ball) end
    else
        -- Pre-spawn: arm AncestryChanged so we track the moment it's parented
        pcall(function()
            local conn
            conn = ball.AncestryChanged:Connect(function()
                pcall(function() conn:Disconnect() end)
                if ball.Parent and _G.WindHubActive then
                    if tracker_ref then tracker_ref:track(ball) end
                end
            end)
        end)
    end
end

function MemScanner.onBallFound(fn)
    table.insert(MemScanner._callbacks, fn)
end

-- ── §10.9  Tier 1 — Lua GC Heap Scan ─────────────────────────────────────
--  getgc(true) returns all live objects in the Lua GC, including userdata
--  (which is how Roblox Instances are represented at the Lua level).
--  We iterate every GC object, skip non-Instances cheaply via typeof(),
--  then apply _isBall() to candidates.
--
--  This runs at 20 Hz and finds balls within 50 ms of creation — far faster
--  than waiting for BallAdded (network latency) or ChildAdded (parenting lag).

function MemScanner.gcScan(tracker_ref)
    if not EX.gc then return end
    local t0 = os.clock()

    pcall(function()
        local gc = EF.getgc(true)
        MemScanner.scannedGC = #gc

        for _, obj in ipairs(gc) do
            -- typeof check is a single C call — extremely cheap
            if typeof(obj) == "Instance" and not MemScanner._seen[obj] then
                -- _isBall uses multiple pcalls; only called when needed
                local ok = pcall(function()
                    if _isBall(obj) then
                        _onBallFound(obj, tracker_ref)
                    end
                end)
                -- Even if _isBall fails, mark as seen to skip next cycle
                -- (We'll still catch it via other tiers)
                if not ok then
                    -- Don't mark _seen — let another tier try
                end
            end
        end
    end)

    MemScanner.gcScanMs = (os.clock() - t0) * 1000
end

-- ── §10.10  Tier 2 — Nil-Instance Pre-Spawn Scan ─────────────────────────
--  getnilinstances() returns Instances with nil Parent.  Roblox may
--  replicate an Instance to the client before attaching it to the DataModel.
--  By catching these here and watching AncestryChanged, we can begin
--  physics tracking before the ball even appears in workspace.

function MemScanner.nilScan(tracker_ref)
    if not EX.nil_ then return end
    local t0 = os.clock()

    pcall(function()
        local nils = EF.getnilinstances()
        MemScanner.scannedNil = #nils

        for _, obj in ipairs(nils) do
            if typeof(obj) == "Instance" and not MemScanner._seen[obj] then
                pcall(function()
                    if _isBall(obj) then
                        _onBallFound(obj, tracker_ref)
                    end
                end)
            end
        end
    end)

    MemScanner.nilScanMs = (os.clock() - t0) * 1000
end

-- ── §10.11  Tier 3 — Full getinstances() Dump ────────────────────────────
--  getinstances() enumerates every Instance in the DataModel.  This is the
--  heaviest scan but is run at only 0.5 Hz as a catch-all backstop.

function MemScanner.instScan(tracker_ref)
    if not EX.inst then return end
    local t0 = os.clock()

    pcall(function()
        local all = EF.getinstances()
        MemScanner.scannedInst = #all

        for _, obj in ipairs(all) do
            if typeof(obj) == "Instance" and not MemScanner._seen[obj] then
                pcall(function()
                    if _isBall(obj) then
                        _onBallFound(obj, tracker_ref)
                    end
                end)
            end
        end
    end)

    MemScanner.instScanMs = (os.clock() - t0) * 1000
end

-- ── §10.12  Heap Walk Coroutine ───────────────────────────────────────────
--  A cooperative coroutine that walks the GC heap in chunks of 500 objects
--  per frame, yielding between chunks to avoid stalling the main thread.
--  Used for the initial full-heap survey on startup.

local function _heapWalkCoroutine(tracker_ref)
    return coroutine.create(function()
        if not EX.gc then return end
        local gc = EF.getgc(true)
        local chunk = 500
        local found = 0

        for i = 1, #gc, chunk do
            for j = i, math.min(i + chunk - 1, #gc) do
                local obj = gc[j]
                if typeof(obj) == "Instance" and not MemScanner._seen[obj] then
                    pcall(function()
                        if _isBall(obj) then
                            _onBallFound(obj, tracker_ref)
                            found = found + 1
                        end
                    end)
                end
            end
            coroutine.yield(found)
        end
        return found
    end)
end

-- ── §10.13  Signature Pattern Scanner ────────────────────────────────────
--  When the executor supports readprocessmemory AND getmodulebase/getbaseaddress,
--  we can scan the game's memory for known byte patterns to locate the Balls
--  folder and all ball instances directly from the process heap.
--
--  Pattern: look for the "zoomies" string near valid VectorForce memory layouts.
--  This is a best-effort feature — it fails gracefully on any error.

local MemSig = {
    enabled     = false,
    baseAddr    = nil,
    regionSize  = 0,
    ballAddrs   = {},     -- addr → Instance  reverse lookup
    patternHits = 0,
    lastScanAt  = 0,
}

-- Known byte signatures for Roblox Instance type strings
-- "zoomies" in ASCII: 7A 6F 6F 6D 69 65 73
local SIG_ZOOMIES = "\x7A\x6F\x6F\x6D\x69\x65\x73"
-- "Ball" in ASCII: 42 61 6C 6C
local SIG_BALL    = "\x42\x61\x6C\x6C"
-- "target" attribute name: 74 61 72 67 65 74
local SIG_TARGET  = "\x74\x61\x72\x67\x65\x74"

local function _scanForPattern(base, size, pattern, chunkSize)
    chunkSize = chunkSize or 4096
    local results = {}
    local plen = #pattern

    for offset = 0, size - plen, chunkSize do
        local readLen = math.min(chunkSize + plen - 1, size - offset)
        local ok, chunk = pcall(EF.readprocessmemory, base + offset, readLen)
        if ok and type(chunk) == "string" and #chunk >= plen then
            local i = 1
            while i <= #chunk - plen + 1 do
                if chunk:sub(i, i + plen - 1) == pattern then
                    table.insert(results, base + offset + i - 1)
                    i = i + plen
                else
                    i = i + 1
                end
            end
        end
        coroutine.yield()  -- cooperative yield to avoid frame spike
    end
    return results
end

function MemSig.init()
    if not (EX.rmem and (EX.mbase or EX.addr)) then return end
    -- Try to get the module base address of the Roblox client
    local ok, base = false, nil
    if EX.mbase then
        ok, base = pcall(EF.getmodulebase, "RobloxPlayerBeta")
        if not ok or not base then
            ok, base = pcall(EF.getmodulebase, "RobloxPlayer")
        end
    end
    if not (ok and base) then return end

    MemSig.baseAddr = base
    MemSig.enabled  = true
end

-- Async signature scan — runs in a background coroutine
function MemSig.startScan(tracker_ref)
    if not MemSig.enabled then return end
    if os.clock() - MemSig.lastScanAt < 10 then return end
    MemSig.lastScanAt = os.clock()

    task.spawn(function()
        pcall(function()
            -- Scan a 64 MB window around the base address for "zoomies" strings
            local scanSize = 64 * 1024 * 1024  -- 64 MB
            local co = coroutine.create(function()
                return _scanForPattern(MemSig.baseAddr, scanSize, SIG_ZOOMIES, 8192)
            end)
            local hits = {}
            while true do
                local ok2, val = coroutine.resume(co)
                if not ok2 then break end
                if coroutine.status(co) == "dead" then
                    if type(val) == "table" then hits = val end
                    break
                end
                task.wait()  -- yield each chunk iteration
            end
            MemSig.patternHits = #hits
        end)
    end)
end

-- ── §10.14  Memory Scanner Initialiser ────────────────────────────────────

function MemScanner.init(tracker_ref)
    -- Step 1: attempt raw-memory calibration
    task.spawn(function()
        task.wait(1)  -- wait for game to finish loading
        pcall(_calibrate)
        if MemScanner.calibrated then
            if Config.debugMemory then
                print(("[WindHub] MemScanner calibrated. posOffset=0x%X"):format(
                    MemScanner._posOffset or 0))
            end
        end
        -- Step 2: signature scanner (background)
        MemSig.init()
        MemSig.startScan(tracker_ref)
    end)

    -- Initial full scan across all three tiers
    task.spawn(function()
        task.wait(0.5)
        -- Run heap walk cooperative coroutine
        local co = _heapWalkCoroutine(tracker_ref)
        while coroutine.status(co) ~= "dead" do
            pcall(coroutine.resume, co)
            task.wait()
        end
        -- Also run nil and inst scans immediately
        MemScanner.nilScan(tracker_ref)
        MemScanner.instScan(tracker_ref)
    end)

    -- Tier 1: GC scan at 20 Hz (every 0.05 s)
    task.spawn(function()
        while _G.WindHubActive do
            MemScanner.gcScan(tracker_ref)
            _runWatchdog()
            task.wait(0.05)
        end
    end)

    -- Tier 2: Nil-instance scan at 4 Hz (every 0.25 s)
    task.spawn(function()
        while _G.WindHubActive do
            MemScanner.nilScan(tracker_ref)
            task.wait(0.25)
        end
    end)

    -- Tier 3: Full getinstances dump at 0.5 Hz (every 2 s)
    task.spawn(function()
        task.wait(5)  -- let the initial cooperative sweep complete first
        while _G.WindHubActive do
            MemScanner.instScan(tracker_ref)
            task.wait(2)
        end
    end)
end


-- ════════════════════════════════════════════════════════════════════════════
--  §11  ADVANCED PHYSICS ENGINE v3
--
--  Five prediction algorithms, selectable per parry mode:
--    Linear  — simple dot-product ETA (fast, low accuracy)
--    RK4     — Runge-Kutta 4th order with gravity + drag + Magnus (high accuracy)
--    Fusion  — weighted average of all algorithms based on confidence scores
--    Monte Carlo — 64–256 random perturbations to estimate miss probability
--    Finite Diff — finite-difference velocity estimation from position history
--
--  Physical constants used:
--    GRAV     = workspace.Gravity  (studs/s²)
--    RHO      = 1.225  (air density, kg/m³ — scaled to Roblox units)
--    DRAG_K   = 0.012  (drag coefficient × cross-section / (2 × mass))
--    MAGNUS_K = 0.003  (Magnus lift coefficient, dimensionless in Roblox units)
-- ════════════════════════════════════════════════════════════════════════════

-- Physical constants
local GRAVITY      = Vector3.new(0, -WS.Gravity, 0)           -- full gravity vector
local GRAVITY_HALF = GRAVITY * 0.5                             -- for quadratic step
local DRAG_K       = 0.012   -- drag coefficient (tuned for Blade Ball ball mass)
local MAGNUS_K     = 0.003   -- Magnus / spin lift coefficient
local AIR_RHO      = 1.225   -- air density constant (for drag formula)

-- ── §11.1  Sample Buffer ──────────────────────────────────────────────────
--  Stores recent (position, velocity, time) samples for a single ball.
--  The velocity stored is either from the zoomies VectorForce or from
--  finite-difference estimation of consecutive positions.

local SampleBuffer = {}
SampleBuffer.__index = SampleBuffer

function SampleBuffer.new(capacity)
    return setmetatable({
        samples  = {},
        capacity = capacity or 16,
        count    = 0,
    }, SampleBuffer)
end

function SampleBuffer:push(pos, vel, t)
    self.count = self.count + 1
    local idx  = ((self.count - 1) % self.capacity) + 1
    self.samples[idx] = { pos = pos, vel = vel, t = t, idx = self.count }
end

-- Returns the n most recent samples, oldest first
function SampleBuffer:recent(n)
    n = math.min(n or self.capacity, self.count, self.capacity)
    local result = {}
    -- Walk backwards from newest
    local base = self.count % self.capacity
    if base == 0 then base = self.capacity end
    for i = n, 1, -1 do
        local slot = ((base - i) % self.capacity) + 1
        if self.samples[slot] then
            table.insert(result, self.samples[slot])
        end
    end
    -- Sort oldest-first
    table.sort(result, function(a, b) return a.idx < b.idx end)
    return result
end

function SampleBuffer:newest()
    if self.count == 0 then return nil end
    local idx = ((self.count - 1) % self.capacity) + 1
    return self.samples[idx]
end

function SampleBuffer:oldest()
    if self.count < self.capacity then
        return self.samples[1]
    end
    local idx = (self.count % self.capacity) + 1
    return self.samples[idx]
end

function SampleBuffer:clear()
    self.samples = {}
    self.count   = 0
end

-- ── §11.2  Finite-Difference Velocity Estimator ───────────────────────────
--  When the executor can read ball.Position faster than the VectorForce
--  updates, we estimate velocity from finite differences of position samples.
--  Uses a 4-point central difference for higher accuracy:
--    v ≈ (-pos[n] + 8·pos[n-1] - 8·pos[n-3] + pos[n-4]) / (12·Δt)
--  Falls back to 2-point if fewer samples are available.

local function finiteDiffVelocity(buf)
    local s = buf:recent(5)
    local n = #s
    if n < 2 then return Vector3.zero end

    if n >= 5 then
        -- 4-point central difference  O(h⁴) error
        local dt = s[5].t - s[1].t
        if dt < 1e-5 then return Vector3.zero end
        local v = (-s[5].pos + s[4].pos * 8 - s[2].pos * 8 + s[1].pos)
                  / (12 * (dt / 4))
        return v
    elseif n >= 3 then
        -- 2-point central difference  O(h²) error
        local dt = s[3].t - s[1].t
        if dt < 1e-5 then return Vector3.zero end
        return (s[3].pos - s[1].pos) / dt
    else
        -- Simple 2-point forward/backward
        local dt = s[2].t - s[1].t
        if dt < 1e-5 then return Vector3.zero end
        return (s[2].pos - s[1].pos) / dt
    end
end

-- ── §11.3  Linear Prediction  (fastest, O(1)) ────────────────────────────
--  Straight-line extrapolation with gravity correction.
--  ETA via dot-product of velocity onto the displacement vector.

local function linearETA(ballPos, ballVel, playerPos)
    local disp    = playerPos - ballPos
    local dist    = disp.Magnitude
    if dist < 0.01 then return 0, ballPos end

    -- Component of velocity towards the player
    local closing = ballVel:Dot(disp.Unit)
    if closing <= 1e-6 then return math.huge, ballPos end

    local eta = dist / closing

    -- Predicted position at eta (with gravity)
    local predicted = ballPos
        + ballVel * eta
        + GRAVITY_HALF * (eta * eta)

    return eta, predicted
end

-- ── §11.4  Air-Resistance Drag Model ─────────────────────────────────────
--  F_drag = -K × |v| × v   (quadratic drag)
--  Acceleration from drag: a_drag = F_drag / m = -DRAG_K × |v| × v

local function dragAccel(vel)
    local spd = vel.Magnitude
    if spd < 0.001 then return Vector3.zero end
    return -vel * (DRAG_K * spd)
end

-- ── §11.5  Magnus Effect (Spin Lift) ──────────────────────────────────────
--  When a spinning ball moves through air, the Magnus effect generates a
--  lift force perpendicular to both the velocity and the spin axis.
--  F_Magnus = K_magnus × (ω × v)
--  We approximate the spin axis as constant (estimated from velocity change).

local function magnusAccel(vel, spinAxis)
    if spinAxis.Magnitude < 0.001 then return Vector3.zero end
    return spinAxis:Cross(vel) * MAGNUS_K
end

-- ── §11.6  Total Acceleration at a State ─────────────────────────────────
local function totalAccel(pos, vel, spinAxis)
    local a = GRAVITY
    if Config.airResistance then
        a = a + dragAccel(vel)
    end
    if Config.magnus and spinAxis then
        a = a + magnusAccel(vel, spinAxis)
    end
    return a
end

-- ── §11.7  RK4 Integrator ─────────────────────────────────────────────────
--  Runge-Kutta 4th-order integration of the ball's equations of motion.
--  State vector: (position, velocity)
--  Derivative:   (velocity, acceleration)
--
--  This gives sub-millisecond accuracy even for large time steps,
--  unlike Euler integration which accumulates O(h) error per step.

local function rk4Step(pos, vel, dt, spinAxis)
    -- k1
    local a1 = totalAccel(pos, vel, spinAxis)
    local dp1, dv1 = vel, a1

    -- k2
    local pos2 = pos + dp1 * (dt * 0.5)
    local vel2 = vel + dv1 * (dt * 0.5)
    local a2   = totalAccel(pos2, vel2, spinAxis)
    local dp2, dv2 = vel2, a2

    -- k3
    local pos3 = pos + dp2 * (dt * 0.5)
    local vel3 = vel + dv2 * (dt * 0.5)
    local a3   = totalAccel(pos3, vel3, spinAxis)
    local dp3, dv3 = vel3, a3

    -- k4
    local pos4 = pos + dp3 * dt
    local vel4 = vel + dv3 * dt
    local a4   = totalAccel(pos4, vel4, spinAxis)
    local dp4, dv4 = vel4, a4

    -- Weighted average: (k1 + 2k2 + 2k3 + k4) / 6
    local newPos = pos + (dp1 + dp2 * 2 + dp3 * 2 + dp4) * (dt / 6)
    local newVel = vel + (dv1 + dv2 * 2 + dv3 * 2 + dv4) * (dt / 6)

    return newPos, newVel
end

-- Integrate over totalTime seconds using nSteps RK4 sub-steps
-- Returns final position and velocity, plus trajectory waypoints
local function rk4Integrate(pos0, vel0, totalTime, nSteps, spinAxis, collectWaypoints)
    local dt  = totalTime / nSteps
    local pos = pos0
    local vel = vel0
    local waypoints = collectWaypoints and { pos0 } or nil

    for _ = 1, nSteps do
        pos, vel = rk4Step(pos, vel, dt, spinAxis)
        if waypoints then table.insert(waypoints, pos) end
    end

    return pos, vel, waypoints
end

-- ── §11.8  RK4 ETA Solver ─────────────────────────────────────────────────
--  Binary search for the time t at which the ball's RK4-predicted position
--  is closest to the player's current position.
--  Search range: [0, maxTime] with maxTime defaulting to 5 seconds.

local function rk4ETA(ballPos, ballVel, playerPos, spinAxis, maxTime)
    maxTime  = maxTime or 5
    local steps = Config.rk4Steps or 8

    -- Coarse search: evaluate distance every 0.05 s
    local bestETA  = math.huge
    local bestDist = math.huge
    local coarseStep = 0.05
    local nCoarse = math.ceil(maxTime / coarseStep)

    local pos = ballPos
    local vel = ballVel
    for i = 1, nCoarse do
        pos, vel = rk4Step(pos, vel, coarseStep, spinAxis)
        local d = (pos - playerPos).Magnitude
        if d < bestDist then
            bestDist = d
            bestETA  = i * coarseStep
        end
        -- Early exit: if distance is increasing and was already small, we passed the minimum
        if i > 3 and d > bestDist + 10 then break end
    end

    if bestETA == math.huge then return math.huge, ballPos end

    -- Fine search: binary search in [bestETA - coarseStep, bestETA + coarseStep]
    local lo  = math.max(0, bestETA - coarseStep)
    local hi  = bestETA + coarseStep
    local EPS = 0.001  -- 1 ms precision

    for _ = 1, 20 do
        if hi - lo < EPS then break end
        local mid = (lo + hi) * 0.5
        local p1, _ = rk4Integrate(ballPos, ballVel, lo  + (mid - lo) * 0.5, steps, spinAxis)
        local p2, _ = rk4Integrate(ballPos, ballVel, mid + (hi - mid) * 0.5, steps, spinAxis)
        local d1 = (p1 - playerPos).Magnitude
        local d2 = (p2 - playerPos).Magnitude
        if d1 < d2 then hi = mid else lo = mid end
    end

    local finalETA = (lo + hi) * 0.5
    local predictedPos, _ = rk4Integrate(ballPos, ballVel, finalETA, steps, spinAxis)
    return finalETA, predictedPos
end

-- ── §11.9  Spin Axis Estimator ────────────────────────────────────────────
--  Estimates the ball's spin axis from consecutive velocity samples.
--  The spin axis is the unit vector perpendicular to the velocity change,
--  approximately: ω ∝ (v[n-1] × v[n]) / |v|²

local function estimateSpin(buf)
    local s = buf:recent(3)
    if #s < 2 then return Vector3.zero end
    local v1 = s[1].vel
    local v2 = s[#s].vel
    if v1.Magnitude < 0.1 or v2.Magnitude < 0.1 then return Vector3.zero end
    local cross = v1:Cross(v2)
    if cross.Magnitude < 0.001 then return Vector3.zero end
    return cross.Unit
end

-- ── §11.10  Monte Carlo Uncertainty Estimator ─────────────────────────────
--  Runs N random perturbations of (ballPos, ballVel) through the RK4
--  integrator and computes:
--    - mean ETA across samples
--    - standard deviation of ETA (confidence)
--    - probability that ETA falls within the parry window
--
--  Expensive — only used when Config.monteCarlo = true.

local function monteCarloETA(ballPos, ballVel, playerPos, spinAxis, window)
    local N      = Config.mcSamples or 64
    local steps  = math.max(4, (Config.rk4Steps or 8))
    local etas   = {}
    local NOISE_POS  = 0.15  -- stud positional noise (measurement uncertainty)
    local NOISE_VEL  = 0.50  -- stud/s velocity noise

    for _ = 1, N do
        -- Add Gaussian noise to initial conditions
        local nPos = ballPos + Vector3.new(
            gaussRand(0, NOISE_POS),
            gaussRand(0, NOISE_POS),
            gaussRand(0, NOISE_POS))
        local nVel = ballVel + Vector3.new(
            gaussRand(0, NOISE_VEL),
            gaussRand(0, NOISE_VEL),
            gaussRand(0, NOISE_VEL))

        local eta, _ = rk4ETA(nPos, nVel, playerPos, spinAxis, 5)
        if eta < math.huge then
            table.insert(etas, eta)
        end
    end

    if #etas == 0 then return math.huge, math.huge, 0 end

    -- Compute mean and stddev
    local sum = 0
    for _, e in ipairs(etas) do sum = sum + e end
    local mean = sum / #etas

    local varSum = 0
    for _, e in ipairs(etas) do varSum = varSum + (e - mean)^2 end
    local stddev = math.sqrt(varSum / #etas)

    -- Probability that true ETA ≤ window  (approximation via CDF)
    -- Using normal approximation: P = Φ((window - mean) / stddev)
    -- We use a 6-point Gauss-Legendre approximation of Φ
    local z = (window - mean) / math.max(stddev, 1e-6)
    local prob
    if     z >  4 then prob = 1.0
    elseif z < -4 then prob = 0.0
    else
        -- Abramowitz & Stegun approximation of erfc
        local t   = 1 / (1 + 0.3275911 * math.abs(z))
        local poly = t * (0.254829592 + t * (-0.284496736
                   + t * (1.421413741 + t * (-1.453152027 + t * 1.061405429))))
        local erfc = poly * math.exp(-z * z)
        local Phi  = 1 - erfc * 0.5
        prob = z >= 0 and Phi or (1 - Phi)
    end

    return mean, stddev, prob
end

-- ── §11.11  Arc / Trajectory Builder ─────────────────────────────────────
--  Returns a list of world-space waypoints tracing the ball's predicted path.
--  Used by the Arc ESP and the danger-zone visualizer.

local function buildArc(ballPos, ballVel, totalTime, nSegs, spinAxis)
    local dt   = totalTime / nSegs
    local pos  = ballPos
    local vel  = ballVel
    local pts  = { ballPos }

    for _ = 1, nSegs do
        pos, vel = rk4Step(pos, vel, dt, spinAxis)
        table.insert(pts, pos)
    end
    return pts
end

-- ── §11.12  Physics Engine Object (per-ball) ──────────────────────────────
--  Encapsulates all per-ball state: sample buffer, estimated spin,
--  cached ETA values for each algorithm, and confidence scores.

local PhysicsEngine = {}
PhysicsEngine.__index = PhysicsEngine

function PhysicsEngine.new()
    return setmetatable({
        buf         = SampleBuffer.new(16),
        spinAxis    = Vector3.zero,
        -- Cached results (updated each frame)
        linearETA   = math.huge,
        linearPos   = Vector3.zero,
        rk4ETA      = math.huge,
        rk4Pos      = Vector3.zero,
        fusionETA   = math.huge,
        mcMean      = math.huge,
        mcStddev    = math.huge,
        mcProb      = 0,
        -- Per-frame state
        lastPos     = Vector3.zero,
        lastVel     = Vector3.zero,
        lastT       = 0,
        avgSpeed    = 0,
        speedHist   = {},
        -- Confidence scores [0, 1]
        linearConf  = 0,
        rk4Conf     = 0,
    }, PhysicsEngine)
end

-- Push new sensor data from this frame
function PhysicsEngine:push(pos, vel, t)
    self.buf:push(pos, vel, t)

    -- Update speed history (EMA)
    local spd = vel.Magnitude
    table.insert(self.speedHist, spd)
    if #self.speedHist > 12 then table.remove(self.speedHist, 1) end
    local sum = 0
    for _, v in ipairs(self.speedHist) do sum = sum + v end
    self.avgSpeed = sum / #self.speedHist

    -- Re-estimate spin axis every 3 pushes
    if self.buf.count % 3 == 0 then
        self.spinAxis = estimateSpin(self.buf)
    end

    self.lastPos = pos
    self.lastVel = vel
    self.lastT   = t
end

-- Compute best velocity estimate (use stored vel OR finite-diff if better)
function PhysicsEngine:bestVel()
    local stored = self.lastVel
    local fd     = finiteDiffVelocity(self.buf)

    -- Trust finite-diff when stored velocity is stale or noisy
    if stored.Magnitude < 0.1 then return fd end
    if fd.Magnitude    < 0.1 then return stored end

    -- Use whichever has higher magnitude (FD tends to lag; stored tends to jump)
    -- Blend them with EMA weighting
    return stored * 0.7 + fd * 0.3
end

-- Full per-frame update: computes all ETA estimates
function PhysicsEngine:update(playerPos)
    local bPos = self.lastPos
    local bVel = self:bestVel()

    -- ── Linear ────────────────────────────────────────────────────────────
    do
        local eta, pPos = linearETA(bPos, bVel, playerPos)
        self.linearETA = eta
        self.linearPos = pPos
        -- Confidence: high when ball is moving fast and straight at the player
        local closing = bVel:Dot((playerPos - bPos).Unit)
        self.linearConf = math.clamp(closing / math.max(bVel.Magnitude, 1), 0, 1)
    end

    -- ── RK4 ───────────────────────────────────────────────────────────────
    do
        local maxT = math.min(5, self.linearETA * 1.5 + 1)
        local eta, pPos = rk4ETA(bPos, bVel, playerPos,
            Config.magnus and self.spinAxis or nil, maxT)
        self.rk4ETA = eta
        self.rk4Pos = pPos
        -- Confidence: higher when we have more samples and speed is stable
        local nSamples = math.min(self.buf.count, 8)
        self.rk4Conf = math.clamp(nSamples / 8, 0, 1)
    end

    -- ── Fusion ────────────────────────────────────────────────────────────
    do
        local lw = self.linearConf
        local rw = self.rk4Conf
        local total = lw + rw
        if total > 0 then
            self.fusionETA = (self.linearETA * lw + self.rk4ETA * rw) / total
        else
            self.fusionETA = self.linearETA
        end
    end

    -- ── Monte Carlo (only when enabled, expensive) ────────────────────────
    if Config.monteCarlo then
        local win = PingComp:effectiveWindow()
        local mean, sd, prob = monteCarloETA(bPos, bVel, playerPos,
            Config.magnus and self.spinAxis or nil, win)
        self.mcMean   = mean
        self.mcStddev = sd
        self.mcProb   = prob
    end
end

-- Returns ETA according to the currently selected physics mode
function PhysicsEngine:eta(playerPos)
    self:update(playerPos)
    local mode = Config.physicsMode
    if     mode == "Linear"  then return self.linearETA, self.linearPos
    elseif mode == "RK4"     then return self.rk4ETA,    self.rk4Pos
    elseif mode == "Fusion"  then return self.fusionETA, self.rk4Pos
    else                          return self.rk4ETA,    self.rk4Pos
    end
end

-- Predict position at time t ahead using the configured mode
function PhysicsEngine:predict(t)
    local bPos = self.lastPos
    local bVel = self:bestVel()
    if Config.physicsMode == "Linear" then
        return bPos + bVel * t + GRAVITY_HALF * (t * t)
    else
        local pred, _ = rk4Integrate(bPos, bVel, t,
            math.max(2, Config.rk4Steps), Config.magnus and self.spinAxis or nil)
        return pred
    end
end

-- Build arc waypoints
function PhysicsEngine:arc(totalTime, nSegs)
    return buildArc(self.lastPos, self:bestVel(), totalTime, nSegs,
        Config.magnus and self.spinAxis or nil)
end

-- Adaptive window: update using EMA from a successful parry
function PhysicsEngine:adaptWindow(currentWindow, successETA)
    local target = successETA + 0.03   -- tiny safety margin
    return math.clamp(
        currentWindow * (1 - Config.adaptAlpha) + target * Config.adaptAlpha,
        Config.minWindow, Config.maxWindow
    )
end

-- ════════════════════════════════════════════════════════════════════════════
--  §12  BALL ANALYTICS ENGINE
--
--  Tracks per-ball history to learn the game's ball-speed patterns,
--  predict which balls are most dangerous, and improve the adaptive window.
-- ════════════════════════════════════════════════════════════════════════════

-- ── §12.1  Ball History ───────────────────────────────────────────────────
local BallHistory = {
    records      = {},   -- array of {spawnAt, avgSpeed, targetedAt, firedAt, eta, parried}
    totalParried = 0,
    totalMissed  = 0,
    avgSpeedEMA  = 0,    -- EMA of all ball average speeds
    avgETAEMA    = 0,    -- EMA of successful parry ETAs
    EMA_ALPHA    = 0.08,
}

function BallHistory:record(rec)
    table.insert(self.records, rec)
    if #self.records > 200 then table.remove(self.records, 1) end

    if rec.avgSpeed and rec.avgSpeed > 0 then
        self.avgSpeedEMA = self.avgSpeedEMA * (1 - self.EMA_ALPHA)
                         + rec.avgSpeed     * self.EMA_ALPHA
    end
    if rec.parried and rec.eta and rec.eta < math.huge then
        self.totalParried = self.totalParried + 1
        self.avgETAEMA    = self.avgETAEMA * (1 - self.EMA_ALPHA)
                          + rec.eta        * self.EMA_ALPHA
    else
        self.totalMissed = self.totalMissed + 1
    end
end

function BallHistory:accuracy()
    local total = self.totalParried + self.totalMissed
    if total == 0 then return 1 end
    return self.totalParried / total
end

function BallHistory:suggestedWindow()
    -- Suggest a parry window based on historical ETAs
    if self.avgETAEMA < 0.05 then return Config.parryWindow end
    -- Add one standard deviation to ensure coverage
    return math.clamp(self.avgETAEMA + 0.05, Config.minWindow, Config.maxWindow)
end

-- ── §12.2  Per-Ball Speed Signature ───────────────────────────────────────
--  Different balls (or different server-side trajectories) may have different
--  speeds.  We keep a signature per ball so we can prioritise faster balls.

local BallSignatures = {}   -- ball Instance → {avgSpeed, spawnAt, peakSpeed}

local function getBallSig(ball)
    if not BallSignatures[ball] then
        BallSignatures[ball] = { avgSpeed = 0, spawnAt = os.clock(), peakSpeed = 0, n = 0 }
    end
    return BallSignatures[ball]
end

local function updateBallSig(ball, speed)
    local sig = getBallSig(ball)
    sig.n = sig.n + 1
    sig.avgSpeed  = sig.avgSpeed  * (1 - 0.1) + speed * 0.1
    sig.peakSpeed = math.max(sig.peakSpeed, speed)
end

local function cleanBallSig(ball)
    BallSignatures[ball] = nil
end

-- ── §12.3  Target Predictor ───────────────────────────────────────────────
--  Uses Replion state + velocity trend to predict which ball will next
--  target this player, even before the "target" attribute is set.

local TargetPredictor = {
    recentTargets = {},   -- list of {ball, at}  — recently targeted us
    intervalEMA   = 2.5,  -- EMA of seconds between being targeted
    lastTargetAt  = 0,
    nextPredicted = math.huge,
}

function TargetPredictor:onTargeted()
    local now = os.clock()
    local interval = now - self.lastTargetAt
    if self.lastTargetAt > 0 and interval < 30 then
        self.intervalEMA = self.intervalEMA * 0.85 + interval * 0.15
    end
    self.lastTargetAt  = now
    self.nextPredicted = now + self.intervalEMA
    table.insert(self.recentTargets, { at = now })
    if #self.recentTargets > 20 then table.remove(self.recentTargets, 1) end
end

function TargetPredictor:expectedIn()
    if self.nextPredicted == math.huge then return math.huge end
    return math.max(0, self.nextPredicted - os.clock())
end

-- ── §12.4  Accuracy Tracker ───────────────────────────────────────────────
local AccuracyTracker = {
    shots  = {},   -- {firedAt, hitAt (or nil)}
    streak = 0,
    best   = 0,
}

function AccuracyTracker:fired()
    table.insert(self.shots, { firedAt = os.clock(), hit = false })
    if #self.shots > 100 then table.remove(self.shots, 1) end
end

function AccuracyTracker:success()
    -- Mark the most recent un-hit shot as successful
    for i = #self.shots, 1, -1 do
        if not self.shots[i].hit then
            self.shots[i].hit   = true
            self.shots[i].hitAt = os.clock()
            self.streak = self.streak + 1
            self.best   = math.max(self.best, self.streak)
            return
        end
    end
end

function AccuracyTracker:miss()
    self.streak = 0
end

function AccuracyTracker:rate()
    if #self.shots == 0 then return 0 end
    local hits = 0
    for _, s in ipairs(self.shots) do if s.hit then hits = hits + 1 end end
    return hits / #self.shots
end

function AccuracyTracker:counts()
    local hits, miss = 0, 0
    for _, s in ipairs(self.shots) do
        if s.hit then hits = hits + 1 else miss = miss + 1 end
    end
    return hits, miss
end

function AccuracyTracker.reset()
    AccuracyTracker.shots  = {}
    AccuracyTracker.streak = 0
    AccuracyTracker.best   = 0
end

-- ════════════════════════════════════════════════════════════════════════════
--  §13  BALL STATE  (__index lazy props · __newindex side-effects)
-- ════════════════════════════════════════════════════════════════════════════
local BallState = {}
BallState.__index = BallState
BallState.onParried = Signal.new()

function BallState.new(ball)
    local raw = {
        ball        = ball,
        fired       = false,
        eta         = math.huge,
        rk4eta      = math.huge,
        fusionETA   = math.huge,
        mcProb      = 0,
        speed       = 0,
        dist        = math.huge,
        closing     = false,
        threat      = false,
        physics     = PhysicsEngine.new(),
        spawnAt     = os.clock(),
        connections = {},
        lastFiredAt = 0,
        target      = nil,
        sig         = getBallSig(ball),
    }

    return setmetatable({}, {
        __index = function(_, k)
            if k == "alive"    then return raw.ball and raw.ball.Parent ~= nil end
            if k == "age"      then return os.clock() - raw.spawnAt end
            if k == "physics"  then return raw.physics end
            if k == "connections" then return raw.connections end
            if k == "sig"      then return raw.sig end
            return raw[k]
        end,
        __newindex = function(_, k, v)
            local old = raw[k]
            raw[k] = v
            -- Side-effect: when fired flips to true, emit parried signal
            if k == "fired" and v == true and old ~= true then
                raw.lastFiredAt = os.clock()
                BallState.onParried:Fire(raw.ball, raw.eta)
                AccuracyTracker:fired()
                TargetPredictor:onTargeted()
            end
            -- Side-effect: when target changes, reset fired state
            if k == "target" and v ~= old and v ~= nil then
                raw.fired = false
            end
        end,
    })
end

-- ════════════════════════════════════════════════════════════════════════════
--  §14  PRIORITY QUEUE  (min-heap)
-- ════════════════════════════════════════════════════════════════════════════
local PQ = {}
PQ.__index = PQ

function PQ.new()
    return setmetatable({ _heap = {}, _size = 0 }, PQ)
end

function PQ:_siftUp(i)
    while i > 1 do
        local parent = math.floor(i / 2)
        if self._heap[parent].priority > self._heap[i].priority then
            self._heap[parent], self._heap[i] = self._heap[i], self._heap[parent]
            i = parent
        else
            break
        end
    end
end

function PQ:_siftDown(i)
    while true do
        local left  = i * 2
        local right = i * 2 + 1
        local smallest = i
        if left  <= self._size and self._heap[left].priority  < self._heap[smallest].priority then smallest = left  end
        if right <= self._size and self._heap[right].priority < self._heap[smallest].priority then smallest = right end
        if smallest == i then break end
        self._heap[i], self._heap[smallest] = self._heap[smallest], self._heap[i]
        i = smallest
    end
end

function PQ:push(item, priority)
    self._size = self._size + 1
    self._heap[self._size] = { item = item, priority = priority }
    self:_siftUp(self._size)
end

function PQ:pop()
    if self._size == 0 then return nil end
    local top = self._heap[1]
    self._heap[1] = self._heap[self._size]
    self._heap[self._size] = nil
    self._size = self._size - 1
    if self._size > 0 then self:_siftDown(1) end
    return top.item, top.priority
end

function PQ:peek()
    return self._heap[1] and self._heap[1].item, self._heap[1] and self._heap[1].priority
end

function PQ:clear()
    self._heap = {}
    self._size = 0
end

function PQ:size()
    return self._size
end

-- ════════════════════════════════════════════════════════════════════════════
--  §15  BALL TRACKER
-- ════════════════════════════════════════════════════════════════════════════
local BallTracker = {}
BallTracker.__index = BallTracker

function BallTracker.new()
    local self = setmetatable({
        states     = {},           -- ball → BallState
        window     = Config.parryWindow,
        parryCount = 0,
        etaHistory = {},
        queue      = PQ.new(),
        onParry    = Signal.new(),
        onNewBall  = Signal.new(),
        onBallGone = Signal.new(),
    }, BallTracker)

    -- When a ball is parried, update history and adapt window
    BallState.onParried:Connect(function(ball, eta)
        self.parryCount = self.parryCount + 1
        _G.WindHub_ParryCount = self.parryCount
        table.insert(self.etaHistory, eta)
        if #self.etaHistory > 80 then table.remove(self.etaHistory, 1) end
        self.onParry:Fire(ball, eta)

        -- Record in BallHistory
        local s = self.states[ball]
        BallHistory:record({
            spawnAt  = s and s.spawnAt or os.clock(),
            avgSpeed = s and s.physics.avgSpeed or 0,
            eta      = eta,
            parried  = true,
        })
        AccuracyTracker:success()
    end)

    return self
end

function BallTracker:track(ball)
    if self.states[ball] then return end
    if not (ball and typeof(ball) == "Instance") then return end

    local state = BallState.new(ball)
    self.states[ball] = state
    self.onNewBall:Fire(ball)

    -- Watch for target attribute changes (ball retargeted)
    pcall(function()
        local conn = ball:GetAttributeChangedSignal("target"):Connect(function()
            local st = self.states[ball]
            if st then
                st.target = ball:GetAttribute("target")
                st.fired  = false
            end
        end)
        table.insert(state.connections, conn)
    end)

    -- __namecall hook connection (set in §16 below)
    -- (connected externally in the hook setup)
end

function BallTracker:untrack(ball)
    local state = self.states[ball]
    if state and state.connections then
        for _, conn in ipairs(state.connections) do
            pcall(function() conn:Disconnect() end)
        end
    end
    if state then
        BallHistory:record({
            avgSpeed = state.physics.avgSpeed,
            parried  = state.fired,
            eta      = state.eta,
        })
    end
    cleanBallSig(ball)
    self.states[ball] = nil
    self.onBallGone:Fire(ball)
end

-- Per-frame update: computes ETA for all tracked balls, fills priority queue
function BallTracker:updateFrame(hrp, now)
    local pPos    = hrp.Position
    local myName  = lp.Name
    self.queue:clear()

    local toRemove = {}

    for ball, state in pairs(self.states) do
        -- Check liveness
        local exploded = _G.WindHub_ExplodedBalls[ball]
        local alive    = not exploded and (ball.Parent ~= nil)

        if not alive then
            table.insert(toRemove, ball)
        else
            local vp = ball:FindFirstChild("zoomies")
            if vp then
                -- Read position: try raw mem, fall back to property
                local bPos = MemScanner.rawPos(ball) or ball.Position
                -- Read velocity: try raw mem, fall back to VectorForce property
                local bVel = MemScanner.rawVel(ball) or vp.VectorVelocity

                -- Push new sample into per-ball physics engine
                state.physics:push(bPos, bVel, now)

                -- Update ball signature
                updateBallSig(ball, bVel.Magnitude)

                -- Compute ETAs (all modes)
                local eta, predictedPos = state.physics:eta(pPos)
                state.eta      = eta
                state.rk4eta   = state.physics.rk4ETA
                state.fusionETA= state.physics.fusionETA
                state.mcProb   = state.physics.mcProb
                state.speed    = bVel.Magnitude
                state.dist     = (pPos - bPos).Magnitude
                state.closing  = bVel:Dot((pPos - bPos).Unit) > 0
                state.target   = ball:GetAttribute("target")

                -- Classify as threat: targeting us, closing, not yet fired
                local targeting = state.target == myName
                state.threat = targeting and state.closing and not state.fired

                -- Compute composite threat score for priority queue
                -- Lower score = higher priority
                if state.threat and eta < math.huge then
                    -- Score: penalise slow close-in balls (they can be dodged);
                    --        prioritise balls with high speed (less time to react)
                    local speedBonus = 1 / math.max(state.speed, 1)
                    local distPenalty = state.dist / 100
                    local score = eta * speedBonus + distPenalty
                    self.queue:push(ball, score)
                end
            end
        end
    end

    -- Safe removal after iteration
    for _, ball in ipairs(toRemove) do
        self:untrack(ball)
    end
end

function BallTracker:bestThreat()
    local ball, score = self.queue:peek()
    if not ball then return nil, math.huge end
    local state = self.states[ball]
    return ball, state and state.eta or math.huge, score
end

function BallTracker:markParried(ball, eta)
    local state = self.states[ball]
    if not state then return end
    state.fired = true
    -- Adapt window using this ball's physics engine
    self.window = state.physics:adaptWindow(self.window, eta)
    Config.parryWindow = self.window
    self.onParry:Fire(ball, eta)
end

function BallTracker:avgETA()
    if #self.etaHistory == 0 then return 0 end
    local sum = 0
    for _, v in ipairs(self.etaHistory) do sum = sum + v end
    return sum / #self.etaHistory
end

function BallTracker:ballCount()
    local n = 0
    for b in pairs(self.states) do
        if b and b.Parent then n = n + 1 end
    end
    return n
end

-- ════════════════════════════════════════════════════════════════════════════
--  §16  __NAMECALL HOOK
--       Intercepts all method calls on Roblox Instances to catch
--       SetAttribute("target", ...) calls before the property change event fires.
--       This gives us ~0 network lag detection.
-- ════════════════════════════════════════════════════════════════════════════
local NamecallSignal   = Signal.new()
local namecallHooked   = false
local _namecallOrig    = nil

do
    if EX.hook and EX.ncc and EX.grmt and EX.ncm then
        local mt = EF.getrawmetatable(game)
        if EX.sro then pcall(EF.setreadonly, mt, false) end

        local orig = rawget(mt, "__namecall")
        if orig then
            local hooked = EF.newcclosure(function(self, ...)
                local method = EF.getnamecallmethod()
                -- Only fire signal for relevant calls
                if typeof(self) == "Instance" then
                    NamecallSignal:FireImmediate(self, method, ...)
                end
                return orig(self, ...)
            end)

            local ok = pcall(function()
                EF.hookfunction(orig, hooked)
                _namecallOrig = orig
            end)
            namecallHooked = ok
        end

        if EX.sro then pcall(EF.setreadonly, mt, true) end
    end
end

-- Connect tracker to namecall signal — fires when SetAttribute("target") is called
-- This allows pre-arming before BallAdded fires
local _namecallConn
if namecallHooked then
    _namecallConn = NamecallSignal:Connect(function(inst, method, attrName, attrVal)
        if method ~= "SetAttribute" then return end
        if attrName ~= "target"     then return end
        -- Fire handled in BallTracker:track's connection above
        -- Additionally: if this ball isn't tracked yet, track it now
        -- (we might have caught it before BallAdded fired)
        if typeof(inst) == "Instance" and not MemScanner._seen[inst] then
            if _isBall and _isBall(inst) then
                MemScanner._seen[inst] = true
                -- The tracker reference is set in INIT (§26); defer if not ready
                task.defer(function()
                    if _G._WindTracker then
                        _G._WindTracker:track(inst)
                    end
                end)
            end
        end
    end)
end

-- ════════════════════════════════════════════════════════════════════════════
--  §17  REPLION INTEGRATION
--       Watches the Replion state-sync remote for server-authoritative
--       ball-target data.  When the server tells us a ball is targeting
--       the local player, we set _G.WindHub_ReplionTargeted = os.clock()
--       so the parry engine can fire immediately (pre-arm mode).
-- ════════════════════════════════════════════════════════════════════════════
local Replion = {
    onTargetChanged = Signal.new(),
    onStateChanged  = Signal.new(),
    log             = {},
    active          = false,
    lastChannel     = nil,
}

task.spawn(function()
    task.wait(2)
    local remote

    -- Primary location (Replion v2.0.0-rc.1 package structure)
    pcall(function()
        remote = RepStor.Packages
            ._Index["ytrev_replion@2.0.0-rc.1"]
            .replion.Remotes.Update
    end)

    -- Fallback: scan all Packages descendants for an "Update" RemoteEvent
    if not (remote and remote:IsA("RemoteEvent")) then
        pcall(function()
            local pkgs = RepStor:FindFirstChild("Packages")
            if not pkgs then return end
            for _, d in ipairs(pkgs:GetDescendants()) do
                if d:IsA("RemoteEvent") and d.Name == "Update" then
                    remote = d; break
                end
            end
        end)
    end

    if not (remote and remote:IsA("RemoteEvent")) then return end

    Replion.active = true

    remote.OnClientEvent:Connect(function(channel, path, value)
        local entry = {
            channel = tostring(channel),
            path    = path,
            value   = value,
            t       = os.clock(),
        }
        table.insert(Replion.log, entry)
        if #Replion.log > 80 then table.remove(Replion.log, 1) end

        Replion.onStateChanged:Fire(path, value, channel)
        Replion.lastChannel = channel

        -- Look for target/ball key patterns
        local ps = tostring(path):lower()
        if ps:find("target") or ps:find("ball") or ps:find("aimed") then
            local tgt = nil
            if type(value) == "string" then
                tgt = value
            elseif type(value) == "table" then
                tgt = value.target or value.Target
                   or value.targetPlayer or value.TargetPlayer
                   or value.aimed
            end
            if tgt then
                Replion.onTargetChanged:Fire(channel, tgt)
            end
        end
    end)
end)

Replion.onTargetChanged:Connect(function(_, newTarget)
    if newTarget == lp.Name then
        _G.WindHub_ReplionTargeted = os.clock()
        TargetPredictor:onTargeted()
    end
end)

-- ════════════════════════════════════════════════════════════════════════════
--  §18  GAME REMOTE HOOKS
--       Connects to all known Blade Ball RemoteEvents in ReplicatedStorage.Remotes.
--       Fires Signal objects on each event for consumption by the parry engine,
--       ESP, kill feed, and combo tracker.
-- ════════════════════════════════════════════════════════════════════════════
local GameRemotes = {
    onParryAttempt   = Signal.new(),
    onParrySuccess   = Signal.new(),
    onBallExplode    = Signal.new(),
    onStandoffStart  = Signal.new(),
    onStandoffEnd    = Signal.new(),
    onCooldownEnd    = Signal.new(),
    onDisableReaper  = Signal.new(),
    onBallAdded      = Signal.new(),
    onPlayerDied     = Signal.new(),
    connected        = {},
}

local REMOTE_DEFS = {
    {
        name    = "ParryAttemptAll",
        handler = function(player, ball, ...)
            GameRemotes.onParryAttempt:Fire(player, ball, ...)
        end,
    },
    {
        name    = "ParrySuccessAll",
        handler = function(player, ball, ...)
            GameRemotes.onParrySuccess:Fire(player, ball, ...)
            -- If local player succeeded, record it
            if player == lp then
                _G.WindHub_LastSuccessAt = os.clock()
                AccuracyTracker:success()
            end
        end,
    },
    {
        name    = "BallExplode",
        handler = function(ball, ...)
            GameRemotes.onBallExplode:Fire(ball, ...)
            if typeof(ball) == "Instance" then
                _G.WindHub_ExplodedBalls[ball] = true
            end
        end,
    },
    {
        name    = "StandoffStart",
        handler = function(...)
            GameRemotes.onStandoffStart:Fire(...)
            _G.WindHub_Standoff = true
            -- Auto-revert after 45 s (safety net in case StandoffEnd doesn't fire)
            task.delay(45, function()
                if _G.WindHubActive then _G.WindHub_Standoff = false end
            end)
        end,
    },
    {
        name    = "StandoffEnd",
        handler = function(...)
            GameRemotes.onStandoffEnd:Fire(...)
            _G.WindHub_Standoff = false
        end,
    },
    {
        name    = "SecondaryEndCD",
        handler = function(...)
            GameRemotes.onCooldownEnd:Fire(...)
            _G.WindHub_SecondaryReady = true
        end,
    },
    {
        name    = "DisableReaper",
        handler = function(...)
            GameRemotes.onDisableReaper:Fire(...)
        end,
    },
    {
        name    = "BallAdded",
        handler = function(ball, ...)
            GameRemotes.onBallAdded:Fire(ball, ...)
            if typeof(ball) == "Instance" then
                _G.WindHub_LatestBall = ball
                -- Track via MemScanner to deduplicate with GC scan
                if not MemScanner._seen[ball] then
                    MemScanner._seen[ball] = true
                    if _G._WindTracker then
                        _G._WindTracker:track(ball)
                    end
                end
            end
        end,
    },
}

task.spawn(function()
    local remotes = RepStor:WaitForChild("Remotes", 20)
    if not remotes then return end

    for _, def in ipairs(REMOTE_DEFS) do
        local ok, remote = pcall(function()
            return remotes:WaitForChild(def.name, 12)
        end)
        if ok and remote and remote:IsA("RemoteEvent") then
            remote.OnClientEvent:Connect(def.handler)
            GameRemotes.connected[def.name] = true
        end
    end
end)

-- Auto-switch to Ultra during Standoff
RS.Heartbeat:Connect(function()
    if not _G.WindHubActive then return end
    if _G.WindHub_Standoff and Config.standoffUltra then
        if Config.parryMode ~= "Ultra" then
            Config.parryMode = "Ultra"
        end
    end
end)

-- ════════════════════════════════════════════════════════════════════════════
--  §19  REMOTE SPY v2
--       Hooks all RemoteEvents in workspace and ReplicatedStorage,
--       logs all incoming calls with timestamp, arguments, and frequency.
-- ════════════════════════════════════════════════════════════════════════════
local RemoteSpy = {
    onFired  = Signal.new(),
    log      = {},
    freq     = {},   -- remote name → calls per second
    _tally   = {},   -- remote name → count in current second
    _second  = 0,
    filters  = {},   -- set of remote names to hide
    enabled  = true,
    maxLog   = 120,
}

function RemoteSpy.clear()
    RemoteSpy.log    = {}
    RemoteSpy.freq   = {}
    RemoteSpy._tally = {}
end

-- formatted multi-line dump of the most recent calls (for the UI log box)
function RemoteSpy.format(maxLines)
    maxLines = maxLines or 16
    local lines = {}
    local n = #RemoteSpy.log
    for i = math.max(1, n - maxLines + 1), n do
        local e = RemoteSpy.log[i]
        if e then
            local fps = RemoteSpy.freq[e.name]
            lines[#lines + 1] = string.format("%-22s %s",
                tostring(e.name), fps and ("· " .. fps .. "/s") or "")
        end
    end
    if #lines == 0 then return "No remote calls captured yet." end
    return table.concat(lines, "\n")
end

local function _watchRemote(remote)
    if not (remote:IsA("RemoteEvent") or remote:IsA("RemoteFunction")) then return end
    if not RemoteSpy.enabled then return end

    local function onFired(...)
        if not RemoteSpy.enabled then return end
        local entry = {
            name  = remote.Name,
            path  = remote:GetFullName(),
            args  = { ... },
            t     = os.clock(),
            frame = math.floor(os.clock() * 60),
        }
        table.insert(RemoteSpy.log, entry)
        if #RemoteSpy.log > RemoteSpy.maxLog then
            table.remove(RemoteSpy.log, 1)
        end
        RemoteSpy._tally[remote.Name] = (RemoteSpy._tally[remote.Name] or 0) + 1
        if not RemoteSpy.filters[remote.Name] then
            RemoteSpy.onFired:Fire(entry)
        end
    end

    if remote:IsA("RemoteEvent") then
        remote.OnClientEvent:Connect(onFired)
    end
end

-- Scan existing descendants
task.spawn(function()
    for _, o in ipairs(WS:GetDescendants())      do pcall(_watchRemote, o) end
    for _, o in ipairs(RepStor:GetDescendants()) do pcall(_watchRemote, o) end
end)
WS.DescendantAdded:Connect(function(o) pcall(_watchRemote, o) end)
RepStor.DescendantAdded:Connect(function(o) pcall(_watchRemote, o) end)

-- Update per-second frequency counts
task.spawn(function()
    while _G.WindHubActive do
        task.wait(1)
        RemoteSpy.freq  = table.clone(RemoteSpy._tally)
        RemoteSpy._tally = {}
    end
end)

-- ════════════════════════════════════════════════════════════════════════════
--  §20  AUTO-PARRY ENGINE  (core parry logic — integrates all systems above)
--
--  Decision pipeline per frame (PreSimulation):
--    1. BallTracker:updateFrame()      — update ETAs for all balls
--    2. BallTracker:bestThreat()       — pick highest-priority ball
--    3. Check pre-arm conditions       — Replion, namecall, history
--    4. Select algorithm ETA           — based on parryMode
--    5. Apply ping compensation        — adjust effective window
--    6. Evaluate fire condition        — mode-specific threshold
--    7. Frame-precise input queue      — schedule click at next frame
--    8. Rollback check                 — cancel if threat disappeared
--    9. Anim fix                       — replay parry animation
-- ════════════════════════════════════════════════════════════════════════════

-- ── §20.1  Anim Fix ───────────────────────────────────────────────────────
local AnimFix = { track = nil, lastAt = 0 }

task.defer(function()
    if not (EX.hook and EX.ncc and EX.grmt) then return end

    local dummy = Instance.new("Animation")
    local mt
    pcall(function() mt = EF.getrawmetatable(dummy) end)
    dummy:Destroy()
    if not mt then return end

    if EX.sro then pcall(EF.setreadonly, mt, false) end
    local orig = rawget(mt, "__index")
    if type(orig) ~= "function" then
        if EX.sro then pcall(EF.setreadonly, mt, true) end
        return
    end

    pcall(EF.hookfunction, orig, EF.newcclosure(function(self, k)
        local v = orig(self, k)
        if k == "Play" and type(v) == "function" then
            return EF.newcclosure(function(track, ...)
                pcall(function()
                    local anim = track.Animation
                    if not anim then return end
                    local id = anim.AnimationId or ""
                    if id:find("parr") or id:find("block") or id:find("deflect")
                    or id:find("swing") or id:find("hit") then
                        AnimFix.track  = track
                        AnimFix.lastAt = os.clock()
                    end
                end)
                return v(track, ...)
            end)
        end
        return v
    end))

    if EX.sro then pcall(EF.setreadonly, mt, true) end
end)

local function doAnimFix()
    if not Config.animFix then return end
    if not AnimFix.track   then return end
    if os.clock() - AnimFix.lastAt > 0.15 then return end
    pcall(function()
        if AnimFix.track.IsPlaying then
            AnimFix.track:Stop(0)
        end
        AnimFix.track:Play(0)
    end)
end

-- ── §20.2  Auto-Dodge ─────────────────────────────────────────────────────
local Dodge = { lastAt = 0, busy = false }

local DODGE_PATTERNS = {
    Perp   = function(bVel) return bVel.Unit:Cross(Vector3.yAxis).Unit end,
    Back   = function(bVel, pPos, bPos)
                 local away = (pPos - bPos).Unit
                 return Vector3.new(away.X, 0, away.Z).Unit
             end,
    Random = function(bVel)
                 local perp = bVel.Unit:Cross(Vector3.yAxis).Unit
                 local angle = math.random() * 2 * math.pi
                 return Vector3.new(
                     math.cos(angle) * perp.X - math.sin(angle) * perp.Z,
                     0,
                     math.sin(angle) * perp.X + math.cos(angle) * perp.Z
                 )
             end,
    Strafe = (function()
                 local sign = 1
                 return function(bVel)
                     sign = -sign
                     return bVel.Unit:Cross(Vector3.yAxis).Unit * sign
                 end
             end)(),
}

function Dodge.attempt(hrp, bPos, bVel)
    if not Config.autoDodge then return end
    if Dodge.busy then return end
    if os.clock() - Dodge.lastAt < Config.dodgeCooldown then return end

    Dodge.lastAt = os.clock()
    Dodge.busy   = true

    task.spawn(function()
        local pFn = DODGE_PATTERNS[Config.dodgeMode] or DODGE_PATTERNS.Perp
        local dir = pFn(bVel, hrp.Position, bPos)

        -- Double-dodge: small dodge followed by the configured distance
        local startCF = hrp.CFrame
        local targetCF = startCF * CFrame.new(dir * Config.dodgeDist)

        TS:Create(hrp, TweenInfo.new(0.14, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
            CFrame = targetCF
        }):Play()

        task.wait(0.18)
        Dodge.busy = false
    end)
end

-- ── §20.3  Hitbox Expander ────────────────────────────────────────────────
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

function HitboxExpand.restore()
    for part, orig in pairs(HitboxExpand._orig) do
        pcall(function() part.Size = orig end)
    end
    HitboxExpand._orig = {}
end

-- ── §20.4  Combo Tracker ──────────────────────────────────────────────────
local ComboTracker = {
    streak      = 0,
    best        = 0,
    lastParryAt = 0,
    COMBO_WINDOW = 6,   -- seconds between parries to count as combo
    onNewBest   = Signal.new(),
    onCombo     = Signal.new(),
}

function ComboTracker:onParry()
    local now = os.clock()
    if now - self.lastParryAt < self.COMBO_WINDOW then
        self.streak = self.streak + 1
    else
        self.streak = 1
    end
    self.lastParryAt = now

    if self.streak > self.best then
        self.best = self.streak
        self.onNewBest:Fire(self.best)
    end
    if self.streak > 1 then
        self.onCombo:Fire(self.streak)
    end
end

function ComboTracker:reset()
    self.streak = 0
end

-- ── §20.5  Kill Feed ──────────────────────────────────────────────────────
local KillFeed = {
    events = {},
    maxLen = 20,
    onEvent = Signal.new(),
}

function KillFeed:add(killer, victim, method)
    local entry = {
        killer = tostring(killer or "?"),
        victim = tostring(victim or "?"),
        method = tostring(method or "Ball"),
        t      = os.clock(),
    }
    table.insert(self.events, entry)
    if #self.events > self.maxLen then table.remove(self.events, 1) end
    self.onEvent:Fire(entry)
end

-- Hook ParrySuccessAll to track kills
GameRemotes.onParrySuccess:Connect(function(player, ball)
    -- A successful parry means the player reflected the ball;
    -- the victim will be whoever the ball was targeting after the parry.
    -- We approximate: record that "player" got a successful parry
    local pName = typeof(player) == "Instance" and player.Name or tostring(player)
    if pName == lp.Name then
        KillFeed:add(lp.Name, "opponent", "Parry")
    end
end)

-- ── §20.6  Anti-Detection System ─────────────────────────────────────────
--  Introduces realistic variance in timing, click position, and parry rate
--  to prevent server-side pattern detection.

local AntiDetect = {
    parryGapMin = 0.08,   -- minimum time between parries (seconds)
    lastParryAt = 0,
    -- Click-position jitter already handled in jitteredCenter()
}

-- Gaussian jitter for parry delay with tail to simulate human reaction time
function AntiDetect.parryDelay()
    if not Config.antiDetect then return 0 end
    -- Model human reaction time: normal distribution centered at humanize midpoint
    -- with occasional tail delays (simulate hesitation)
    local mean = (Config.humanizeMin + Config.humanizeMax) * 0.5
    local sd   = (Config.humanizeMax - Config.humanizeMin) * 0.25
    local raw  = gaussRand(mean, sd)
    -- 5% chance of a longer delay (hesitation)
    if math.random() < 0.05 then
        raw = raw + gaussRand(0.02, 0.01)
    end
    return math.clamp(raw, Config.humanizeMin, Config.humanizeMax)
end

-- Rate limiter: don't fire parry faster than parryGapMin
function AntiDetect:canParry()
    if os.clock() - self.lastParryAt >= self.parryGapMin then
        return true
    end
    return false
end

function AntiDetect:recordParry()
    self.lastParryAt = os.clock()
end

-- ── §20.7  Server-Tick Synchroniser ──────────────────────────────────────
--  Roblox runs at a nominal 60 Hz server tick.  Firing the parry exactly
--  on a tick boundary reduces server-side processing lag.
--  We estimate the server tick phase by comparing Heartbeat firing times.

local ServerSync = {
    tickPhase = 0,        -- fractional seconds into the current server tick
    tickLen   = 1/60,     -- nominal server tick length
    _lastHB   = 0,
    _phaseEMA = 0,
}

RS.Heartbeat:Connect(function(dt)
    local now = os.clock()
    -- Track phase within the nominal tick
    ServerSync._phaseEMA = ServerSync._phaseEMA * 0.9 + (now % ServerSync.tickLen) * 0.1
    ServerSync.tickPhase = ServerSync._phaseEMA
    ServerSync._lastHB   = now
end)

-- Returns the time (in seconds) until the next server tick boundary
function ServerSync:timeToNextTick()
    local phase   = os.clock() % self.tickLen
    local remaining = self.tickLen - phase
    return remaining < 1e-4 and self.tickLen or remaining
end

-- ── §20.8  Parry Fire Decision ────────────────────────────────────────────
--  The main decision function.  Called every PreSimulation frame.
--  Returns true if the parry should fire this frame, plus the reason.

local function shouldFire(threat, state, window)
    if not threat or not state then return false, "no_threat" end

    local eta  = state.eta
    local mode = Config.parryMode

    -- Pre-arm: Replion told us we're the target within the last 150 ms
    local replionRecent = _G.WindHub_ReplionTargeted ~= nil
        and (os.clock() - _G.WindHub_ReplionTargeted) < 0.15

    if replionRecent and Config.replionArm then
        return true, "replion_prearm"
    end

    -- Standoff override: always Ultra during Standoff
    if _G.WindHub_Standoff then
        return eta < math.huge, "standoff_ultra"
    end

    -- Mode-specific conditions
    if mode == "Ultra" then
        -- Fire as soon as the ball is targeting us, regardless of ETA
        return eta < math.huge, "ultra"

    elseif mode == "Predictive" then
        -- Fire when ETA ≤ effective window
        return eta <= window, "predictive"

    elseif mode == "Conservative" then
        -- Fire at 55% of effective window (extra safety margin)
        return eta <= window * 0.55, "conservative"

    elseif mode == "RK4" then
        -- Use RK4 ETA specifically
        local rk4 = state.rk4eta
        return rk4 ~= math.huge and rk4 <= window, "rk4"

    elseif mode == "Fusion" then
        -- Use the fusion ETA (weighted blend)
        local fusion = state.fusionETA
        if fusion == math.huge then fusion = eta end
        -- Also factor in Monte Carlo probability if enabled
        if Config.monteCarlo and state.mcProb > 0.8 then
            return true, "fusion_mc"
        end
        return fusion <= window, "fusion"
    end

    return eta <= window, "default"
end

-- ── §20.9  Rollback Guard ─────────────────────────────────────────────────
--  Checks whether a queued parry is still valid (ball still targeting us,
--  still alive, still within a reasonable ETA range).

local _pendingParry = nil  -- { ball, queuedAt, maxAge }

local function commitParry(ball, eta, reason)
    if not AntiDetect:canParry() then return end

    _pendingParry = {
        ball      = ball,
        queuedAt  = os.clock(),
        maxAge    = 0.12,    -- cancel if not fired within 120 ms
        eta       = eta,
        reason    = reason,
    }
    AntiDetect:recordParry()
end

local function checkRollback(pendingParry, tracker)
    if not pendingParry then return false end
    local ball = pendingParry.ball
    -- Age check
    if os.clock() - pendingParry.queuedAt > pendingParry.maxAge then
        return true  -- too old, roll back
    end
    -- Ball check
    if not (ball and ball.Parent) then return true end
    if _G.WindHub_ExplodedBalls[ball] then return true end
    -- State check
    local state = tracker.states[ball]
    if not state then return true end
    if state.fired then return true end  -- already parried
    -- ETA check: if ball suddenly moved away, roll back
    if state.eta > pendingParry.eta * 3 and state.eta > 2 then return true end

    return false
end

-- ── §20.10  Manual Spam ───────────────────────────────────────────────────
local spamActive = false

Config.Changed:Connect(function(k, v)
    if k ~= "manualSpam" then return end
    if v and not spamActive then
        spamActive = true
        task.spawn(function()
            pcall(function()
                while Config.manualSpam and _G.WindHubActive do
                    for _ = 1, math.max(1, Config.spamBurst) do
                        task.spawn(function()
                            pcall(clickParry)
                        end)
                    end
                    task.wait(math.max(0.04, Config.spamRate))
                end
            end)
            spamActive = false
        end)
    end
end)

-- ── §20.11  Client State Monitor ──────────────────────────────────────────
local ClientState = {
    alive    = false,
    onDied   = Signal.new(),
    onSpawned= Signal.new(),
}

local function monitorChar(char)
    if not char then return end
    local hum = char:WaitForChild("Humanoid", 8)
    if not hum then return end
    ClientState.alive = true

    hum.Died:Connect(function()
        ClientState.alive = false
        ClientState.onDied:Fire()
        ComboTracker:reset()
        AccuracyTracker:miss()
    end)

    if Config.hitboxExpand then
        HitboxExpand.apply(char)
    end
end

lp.CharacterAdded:Connect(function(char)
    ClientState.onSpawned:Fire(char)
    task.spawn(monitorChar, char)
end)
task.spawn(monitorChar, lp.Character)

-- ════════════════════════════════════════════════════════════════════════════
--  §21  PROFILER
-- ════════════════════════════════════════════════════════════════════════════
local Prof = { times = {}, last = os.clock(), memSamples = {} }

function Prof:tick()
    local now = os.clock()
    table.insert(self.times, now - self.last)
    self.last = now
    if #self.times > 90 then table.remove(self.times, 1) end
end

function Prof:fps()
    if #self.times < 2 then return 0 end
    local sum = 0
    for _, v in ipairs(self.times) do sum = sum + v end
    return 1 / (sum / #self.times)
end

function Prof:frameMs()
    if #self.times == 0 then return 0 end
    return self.times[#self.times] * 1000
end

-- Track GC memory usage
task.spawn(function()
    while _G.WindHubActive do
        local ok, kb = pcall(function()
            return collectgarbage("count")
        end)
        if ok then
            table.insert(Prof.memSamples, kb)
            if #Prof.memSamples > 60 then table.remove(Prof.memSamples, 1) end
        end
        task.wait(0.5)
    end
end)

function Prof:memKB()
    if #self.memSamples == 0 then return 0 end
    return self.memSamples[#self.memSamples]
end


-- ════════════════════════════════════════════════════════════════════════════
--  §22  ARC / TRAJECTORY ESP
--       Renders the predicted ball path as a chain of glowing dots or
--       a neon cylinder chain, colour-coded by time-to-impact.
-- ════════════════════════════════════════════════════════════════════════════
local ArcESP = {
    _dots     = {},    -- ball → {Part, Part, ...}
    _cylinders= {},    -- ball → {Part, Part, ...}
    _impactPt = {},    -- ball → Part (impact point indicator)
}

local ARC_NEAR_COLOR = Color3.fromRGB(255, 40, 40)    -- red: close impact
local ARC_MID_COLOR  = Color3.fromRGB(255, 180, 30)   -- yellow: medium
local ARC_FAR_COLOR  = Color3.fromRGB(50, 220, 255)   -- cyan: far

local function _arcColor(fraction)
    -- fraction = 0 → near (red), fraction = 1 → far (cyan)
    if fraction < 0.5 then
        local t = fraction * 2
        return Color3.new(
            ARC_NEAR_COLOR.R * (1-t) + ARC_MID_COLOR.R * t,
            ARC_NEAR_COLOR.G * (1-t) + ARC_MID_COLOR.G * t,
            ARC_NEAR_COLOR.B * (1-t) + ARC_MID_COLOR.B * t
        )
    else
        local t = (fraction - 0.5) * 2
        return Color3.new(
            ARC_MID_COLOR.R * (1-t) + ARC_FAR_COLOR.R * t,
            ARC_MID_COLOR.G * (1-t) + ARC_FAR_COLOR.G * t,
            ARC_MID_COLOR.B * (1-t) + ARC_FAR_COLOR.B * t
        )
    end
end

local function _makeDot(color)
    local p = Instance.new("Part")
    p.Size        = Vector3.new(0.22, 0.22, 0.22)
    p.Anchored    = true
    p.CanCollide  = false
    p.CastShadow  = false
    p.Material    = Enum.Material.Neon
    p.Color       = color or ARC_FAR_COLOR
    p.Parent      = cam
    Instance.new("SphereHandleAdornment", p)  -- makes it look rounder in-world
    return p
end

local function _makeCylinder(color)
    local p = Instance.new("Part")
    p.Anchored   = true
    p.CanCollide = false
    p.CastShadow = false
    p.Material   = Enum.Material.Neon
    p.Color      = color or ARC_MID_COLOR
    p.Parent     = cam
    return p
end

local function _makeImpactDisk(color)
    local p = Instance.new("Part")
    p.Size        = Vector3.new(3, 0.1, 3)
    p.Anchored    = true
    p.CanCollide  = false
    p.CastShadow  = false
    p.Material    = Enum.Material.Neon
    p.Color       = color or ARC_NEAR_COLOR
    p.Transparency= 0.4
    p.Parent      = cam
    Instance.new("CylinderHandleAdornment", p)
    return p
end

local function _cleanArcBall(ball)
    if ArcESP._dots[ball] then
        for _, d in ipairs(ArcESP._dots[ball]) do
            pcall(function() d:Destroy() end)
        end
        ArcESP._dots[ball] = nil
    end
    if ArcESP._cylinders[ball] then
        for _, c in ipairs(ArcESP._cylinders[ball]) do
            pcall(function() c:Destroy() end)
        end
        ArcESP._cylinders[ball] = nil
    end
    if ArcESP._impactPt[ball] then
        pcall(function() ArcESP._impactPt[ball]:Destroy() end)
        ArcESP._impactPt[ball] = nil
    end
end

function ArcESP.update(ball, state)
    if not Config.predArc then
        _cleanArcBall(ball)
        return
    end
    if not (ball and ball.Parent) then
        _cleanArcBall(ball)
        return
    end

    local nSegs = Config.arcSegments
    local pts   = state.physics:arc(Config.arcDuration, nSegs)
    if not pts or #pts < 2 then return end

    -- Ensure correct number of dot Parts exist
    if not ArcESP._dots[ball] or #ArcESP._dots[ball] ~= #pts then
        _cleanArcBall(ball)
        ArcESP._dots[ball] = {}
        for i, _ in ipairs(pts) do
            local frac  = (i - 1) / math.max(#pts - 1, 1)
            local color = _arcColor(frac)
            ArcESP._dots[ball][i] = _makeDot(color)
        end
        -- Impact point disk
        ArcESP._impactPt[ball] = _makeImpactDisk(
            state.threat and ARC_NEAR_COLOR or ARC_FAR_COLOR)
    end

    -- Position each dot
    for i, pt in ipairs(pts) do
        local dot = ArcESP._dots[ball][i]
        if dot then
            local frac  = (i - 1) / math.max(#pts - 1, 1)
            dot.Color   = _arcColor(frac)
            dot.CFrame  = CFrame.new(pt)
            -- Size pulses for dots close in time
            local pulse = 0.22 + (1 - frac) * 0.10
            dot.Size    = Vector3.new(pulse, pulse, pulse)
        end
    end

    -- Impact disk at final point
    local disk = ArcESP._impactPt[ball]
    if disk then
        local finalPt = pts[#pts]
        disk.Color    = state.threat and ARC_NEAR_COLOR or ARC_FAR_COLOR
        disk.CFrame   = CFrame.new(finalPt) * CFrame.Angles(0, os.clock() * 2, 0)
    end
end

function ArcESP.clean(ball)
    _cleanArcBall(ball)
end

-- ════════════════════════════════════════════════════════════════════════════
--  §23  BALL ESP
--       Selection box outline + billboard label showing ETA, speed, target.
--       Colour-coded: red = threatening this player, cyan = other target.
-- ════════════════════════════════════════════════════════════════════════════
local BallESP = {
    _boxes    = {},   -- ball → SelectionBox
    _labels   = {},   -- ball → { gui=BillboardGui, lbl=TextLabel, etaBar=Frame }
    _speedGfx = {},   -- ball → { barFrame, fillFrame }
}

local function _ensureBallBox(ball, color)
    if not BallESP._boxes[ball] then
        local b = Instance.new("SelectionBox")
        b.Adornee            = ball
        b.LineThickness      = 0.07
        b.SurfaceTransparency= 0.82
        b.Parent             = cam
        BallESP._boxes[ball] = b
    end
    local box = BallESP._boxes[ball]
    box.Color3        = color
    box.SurfaceColor3 = color
    return box
end

local function _ensureBallLabel(ball)
    if not BallESP._labels[ball] then
        local bb = Instance.new("BillboardGui")
        bb.AlwaysOnTop  = true
        bb.Size         = UDim2.fromOffset(160, 56)
        bb.StudsOffset  = Vector3.new(0, 4, 0)
        bb.Adornee      = ball
        bb.Parent       = cam

        local bg = Instance.new("Frame", bb)
        bg.Size             = UDim2.new(1, 0, 1, 0)
        bg.BackgroundColor3 = Color3.fromRGB(8, 8, 16)
        bg.BackgroundTransparency = 0.45
        bg.BorderSizePixel  = 0
        Instance.new("UICorner", bg).CornerRadius = UDim.new(0, 5)
        Instance.new("UIStroke", bg).Color        = Color3.fromRGB(60, 40, 140)

        local lbl = Instance.new("TextLabel", bg)
        lbl.Size               = UDim2.new(1, -6, 0, 28)
        lbl.Position           = UDim2.fromOffset(3, 2)
        lbl.BackgroundTransparency = 1
        lbl.TextSize           = 11
        lbl.Font               = Enum.Font.Code
        lbl.TextStrokeTransparency = 0.3
        lbl.TextColor3         = Color3.fromRGB(220, 215, 255)
        lbl.TextXAlignment     = Enum.TextXAlignment.Left

        -- ETA progress bar
        local barBg = Instance.new("Frame", bg)
        barBg.Size              = UDim2.new(1, -6, 0, 5)
        barBg.Position          = UDim2.new(0, 3, 1, -7)
        barBg.BackgroundColor3  = Color3.fromRGB(30, 25, 50)
        barBg.BorderSizePixel   = 0
        Instance.new("UICorner", barBg).CornerRadius = UDim.new(1, 0)

        local barFill = Instance.new("Frame", barBg)
        barFill.Size            = UDim2.new(0, 0, 1, 0)
        barFill.BackgroundColor3= Color3.fromRGB(120, 60, 255)
        barFill.BorderSizePixel = 0
        Instance.new("UICorner", barFill).CornerRadius = UDim.new(1, 0)

        BallESP._labels[ball] = { gui = bb, lbl = lbl, bg = bg, barFill = barFill }
    end
    return BallESP._labels[ball]
end

local function _cleanBallESP(ball)
    if BallESP._boxes[ball]  then BallESP._boxes[ball]:Destroy();           BallESP._boxes[ball]  = nil end
    if BallESP._labels[ball] then BallESP._labels[ball].gui:Destroy();     BallESP._labels[ball] = nil end
end

function BallESP.update(ball, state)
    if not Config.espBalls then
        _cleanBallESP(ball)
        return
    end
    if not (ball and ball.Parent) then
        _cleanBallESP(ball)
        return
    end

    local col = state.threat and Color3.fromRGB(255, 40, 40) or Color3.fromRGB(60, 180, 255)
    _ensureBallBox(ball, col)

    local L = _ensureBallLabel(ball)
    local etaStr = state.eta >= 99 and " ∞ " or (" %.3fs"):format(state.eta)
    local tgtStr = ball:GetAttribute("target") or "?"
    local modeStr = Config.parryMode:sub(1,1)  -- U / P / C / R / F

    L.lbl.Text = ("⚡ %s\nETA%s | %.0f/s [%s]"):format(
        tgtStr:sub(1, 14),  -- truncate long names
        etaStr,
        state.speed,
        modeStr
    )
    L.lbl.TextColor3 = state.threat
        and Color3.fromRGB(255, 90, 90)
        or  Color3.fromRGB(130, 220, 255)
    L.bg.BackgroundColor3 = state.threat
        and Color3.fromRGB(40, 5, 5)
        or  Color3.fromRGB(5, 10, 30)

    -- ETA progress bar: fill fraction = 1 - (eta / window), clamped
    local win    = PingComp:effectiveWindow()
    local fill   = state.eta < math.huge and math.clamp(1 - state.eta / math.max(win, 0.1), 0, 1) or 0
    L.barFill.Size = UDim2.new(fill, 0, 1, 0)
    L.barFill.BackgroundColor3 = fill > 0.75
        and Color3.fromRGB(255, 40, 40)
        or  Color3.fromRGB(120, 60, 255)
end

function BallESP.clean(ball)
    _cleanBallESP(ball)
end

-- ════════════════════════════════════════════════════════════════════════════
--  §24  PLAYER ESP
--       SelectionBox + nametag + health bar for all other players.
-- ════════════════════════════════════════════════════════════════════════════
local PlayerESP = {
    _boxes    = {},   -- player → SelectionBox
    _tags     = {},   -- player → BillboardGui
    _chams    = {},   -- player → {Part, Part, ...} highlight parts
}

local PLRESP_COLOR = Color3.fromRGB(100, 60, 255)

local function _ensurePlayerBox(player)
    local char = player.Character
    if not char then return end
    if not PlayerESP._boxes[player] then
        local b = Instance.new("SelectionBox")
        b.Adornee            = char
        b.Color3             = PLRESP_COLOR
        b.SurfaceColor3      = PLRESP_COLOR
        b.LineThickness      = 0.05
        b.SurfaceTransparency= 0.82
        b.Parent             = cam
        PlayerESP._boxes[player] = b
    end
end

local function _ensurePlayerTag(player)
    local char = player.Character
    if not char then return end
    local head = char:FindFirstChild("Head")
    if not head then return end

    if not PlayerESP._tags[player] then
        local bb = Instance.new("BillboardGui")
        bb.AlwaysOnTop  = true
        bb.Size         = UDim2.fromOffset(180, 60)
        bb.StudsOffset  = Vector3.new(0, 3.5, 0)
        bb.Adornee      = head
        bb.Parent       = cam

        local bg = Instance.new("Frame", bb)
        bg.Size             = UDim2.new(1, 0, 1, 0)
        bg.BackgroundColor3 = Color3.fromRGB(8, 5, 20)
        bg.BackgroundTransparency = 0.5
        bg.BorderSizePixel  = 0
        Instance.new("UICorner", bg).CornerRadius = UDim.new(0, 5)

        local nameLbl = Instance.new("TextLabel", bg)
        nameLbl.Name   = "NameLbl"
        nameLbl.Size   = UDim2.new(1, -6, 0, 18)
        nameLbl.Position = UDim2.fromOffset(3, 2)
        nameLbl.BackgroundTransparency = 1
        nameLbl.TextSize = 13
        nameLbl.Font     = Enum.Font.GothamBold
        nameLbl.TextColor3 = Color3.fromRGB(200, 195, 255)
        nameLbl.TextStrokeTransparency = 0.4
        nameLbl.Text   = player.Name

        -- Distance label
        local distLbl = Instance.new("TextLabel", bg)
        distLbl.Name  = "DistLbl"
        distLbl.Size  = UDim2.new(1, -6, 0, 14)
        distLbl.Position = UDim2.fromOffset(3, 20)
        distLbl.BackgroundTransparency = 1
        distLbl.TextSize = 10
        distLbl.Font     = Enum.Font.Code
        distLbl.TextColor3 = Color3.fromRGB(140, 135, 180)
        distLbl.Text   = "0 studs"

        -- Health bar background
        local hpBg = Instance.new("Frame", bg)
        hpBg.Size             = UDim2.new(1, -6, 0, 5)
        hpBg.Position         = UDim2.new(0, 3, 1, -8)
        hpBg.BackgroundColor3 = Color3.fromRGB(40, 10, 10)
        hpBg.BorderSizePixel  = 0
        Instance.new("UICorner", hpBg).CornerRadius = UDim.new(1, 0)

        local hpFill = Instance.new("Frame", hpBg)
        hpFill.Name             = "Fill"
        hpFill.Size             = UDim2.new(1, 0, 1, 0)
        hpFill.BackgroundColor3 = Color3.fromRGB(80, 220, 90)
        hpFill.BorderSizePixel  = 0
        Instance.new("UICorner", hpFill).CornerRadius = UDim.new(1, 0)

        PlayerESP._tags[player] = { gui = bb, bg = bg, nameLbl = nameLbl,
                                     distLbl = distLbl, hpFill = hpFill }
    end
end

local function _cleanPlayerESP(player)
    if PlayerESP._boxes[player] then PlayerESP._boxes[player]:Destroy(); PlayerESP._boxes[player] = nil end
    if PlayerESP._tags[player]  then PlayerESP._tags[player].gui:Destroy();  PlayerESP._tags[player]  = nil end
    -- Clean chams
    if PlayerESP._chams[player] then
        for _, p in ipairs(PlayerESP._chams[player]) do pcall(function() p:Destroy() end) end
        PlayerESP._chams[player] = nil
    end
end

-- Apply chams: neon-coloured clones of character parts overlaid at the player
local function _applyChams(player)
    if not Config.espChams then return end
    local char = player.Character
    if not char then return end
    if PlayerESP._chams[player] then return end  -- already applied

    local chams = {}
    for _, part in ipairs(char:GetDescendants()) do
        if part:IsA("BasePart") and part.Name ~= "HumanoidRootPart" then
            local ok, highlight = pcall(function()
                local h = Instance.new("SelectionBox")
                h.Adornee            = part
                h.Color3             = Color3.fromRGB(130, 60, 255)
                h.SurfaceColor3      = Color3.fromRGB(80, 30, 200)
                h.LineThickness      = 0.03
                h.SurfaceTransparency= 0.60
                h.Parent             = cam
                return h
            end)
            if ok then table.insert(chams, highlight) end
        end
    end
    PlayerESP._chams[player] = chams
end

function PlayerESP.update()
    if not Config.espPlayers then
        -- Clean all
        local toClean = {}
        for p in pairs(PlayerESP._boxes) do table.insert(toClean, p) end
        for _, p in ipairs(toClean) do _cleanPlayerESP(p) end
        return
    end

    local myPos = lp.Character
        and lp.Character:FindFirstChild("HumanoidRootPart")
        and lp.Character.HumanoidRootPart.Position
        or Vector3.zero

    for _, player in ipairs(Plrs:GetPlayers()) do
        if player ~= lp and player.Character then
            _ensurePlayerBox(player)
            _ensurePlayerTag(player)

            -- Update distance
            local hrp = player.Character:FindFirstChild("HumanoidRootPart")
            local dist = hrp and (hrp.Position - myPos).Magnitude or 0

            local tag = PlayerESP._tags[player]
            if tag then
                tag.distLbl.Text = ("%.0f studs"):format(dist)

                -- Update health bar
                local hum = player.Character:FindFirstChildOfClass("Humanoid")
                if hum then
                    local frac = hum.Health / math.max(hum.MaxHealth, 1)
                    tag.hpFill.Size = UDim2.new(frac, 0, 1, 0)
                    tag.hpFill.BackgroundColor3 = frac > 0.5
                        and Color3.fromRGB(80, 220, 90)
                        or  Color3.fromRGB(255, 100, 40)
                end
            end

            if Config.espChams then
                _applyChams(player)
            end
        end
    end

    -- Clean up for removed players
    local toRemove = {}
    for p in pairs(PlayerESP._boxes) do
        if not p.Character or p.Parent ~= Plrs then
            table.insert(toRemove, p)
        end
    end
    for _, p in ipairs(toRemove) do _cleanPlayerESP(p) end
end

Plrs.PlayerRemoving:Connect(function(p)
    _cleanPlayerESP(p)
end)

-- ════════════════════════════════════════════════════════════════════════════
--  §25  MINIMAP
--       A 2D top-down minimap rendered in the corner of the screen.
--       Shows: local player (white dot), other players (purple), balls (red).
-- ════════════════════════════════════════════════════════════════════════════
local Minimap = {
    _gui    = nil,
    _frame  = nil,
    _dots   = {},    -- key → Frame (dot)
    RANGE   = 150,   -- studs visible on minimap
    SIZE    = 130,   -- pixels square
    enabled = false,
}

local function _makeMinimapDot(color, size)
    local f = Instance.new("Frame")
    f.Size              = UDim2.fromOffset(size, size)
    f.BackgroundColor3  = color
    f.BorderSizePixel   = 0
    f.AnchorPoint       = Vector2.new(0.5, 0.5)
    Instance.new("UICorner", f).CornerRadius = UDim.new(1, 0)
    return f
end

local function _minimapInit()
    if Minimap._gui then return end

    local sg = Instance.new("ScreenGui")
    sg.Name          = "WindHubMinimap"
    sg.ResetOnSpawn  = false
    sg.ZIndexBehavior= Enum.ZIndexBehavior.Sibling
    sg.Parent        = CoreGui

    local frame = Instance.new("Frame", sg)
    frame.Size             = UDim2.fromOffset(Minimap.SIZE, Minimap.SIZE)
    frame.Position         = UDim2.new(1, -(Minimap.SIZE + 12), 0, 12)
    frame.BackgroundColor3 = Color3.fromRGB(5, 5, 12)
    frame.BackgroundTransparency = 0.35
    frame.BorderSizePixel  = 0
    frame.ClipsDescendants = true
    Instance.new("UICorner", frame).CornerRadius = UDim.new(0, 8)
    local stroke = Instance.new("UIStroke", frame)
    stroke.Color     = Color3.fromRGB(100, 60, 220)
    stroke.Thickness = 1.5

    -- Compass ring label
    local compassLbl = Instance.new("TextLabel", frame)
    compassLbl.Size              = UDim2.new(1, 0, 0, 12)
    compassLbl.Position          = UDim2.new(0, 0, 0, 1)
    compassLbl.BackgroundTransparency = 1
    compassLbl.Text              = "MINIMAP"
    compassLbl.TextSize          = 8
    compassLbl.Font              = Enum.Font.GothamBold
    compassLbl.TextColor3        = Color3.fromRGB(120, 90, 220)

    -- Cross-hair centre
    local ch1 = Instance.new("Frame", frame)
    ch1.Size              = UDim2.fromOffset(1, 10)
    ch1.Position          = UDim2.new(0.5, 0, 0.5, -5)
    ch1.BackgroundColor3  = Color3.fromRGB(255, 255, 255)
    ch1.BackgroundTransparency = 0.7
    ch1.BorderSizePixel   = 0
    local ch2 = Instance.new("Frame", frame)
    ch2.Size              = UDim2.fromOffset(10, 1)
    ch2.Position          = UDim2.new(0.5, -5, 0.5, 0)
    ch2.BackgroundColor3  = Color3.fromRGB(255, 255, 255)
    ch2.BackgroundTransparency = 0.7
    ch2.BorderSizePixel   = 0

    Minimap._gui   = sg
    Minimap._frame = frame
end

local function _worldToMinimap(worldPos, refPos, refYaw)
    -- Rotate world offset by camera yaw to get map-aligned coords
    local dx = worldPos.X - refPos.X
    local dz = worldPos.Z - refPos.Z
    -- Apply camera rotation
    local sinY = math.sin(refYaw)
    local cosY = math.cos(refYaw)
    local rx   =  cosY * dx + sinY * dz
    local rz   = -sinY * dx + cosY * dz
    -- Map to [0,1]
    local s     = Minimap.SIZE
    local range = Minimap.RANGE
    local px = 0.5 + rx / (range * 2)
    local py = 0.5 + rz / (range * 2)
    return math.clamp(px, 0, 1), math.clamp(py, 0, 1)
end

local function _updateMinimap(tracker)
    if not Config.espMinimap then
        if Minimap._gui then
            Minimap._gui.Enabled = false
        end
        return
    end

    _minimapInit()
    Minimap._gui.Enabled = true

    local myHRP = lp.Character and lp.Character:FindFirstChild("HumanoidRootPart")
    if not myHRP then return end

    local refPos = myHRP.Position
    local camCF  = cam.CFrame
    -- Camera yaw (rotation around Y axis)
    local _, camYaw, _ = camCF:ToEulerAnglesYXZ()

    -- Collect all dots needed this frame
    local neededKeys = {}

    -- Local player (always centre)
    do
        local key = "LP"
        neededKeys[key] = true
        if not Minimap._dots[key] then
            local dot = _makeMinimapDot(Color3.fromRGB(255, 255, 255), 8)
            dot.Parent       = Minimap._frame
            Minimap._dots[key] = dot
        end
        local dot = Minimap._dots[key]
        dot.Position = UDim2.fromScale(0.5, 0.5)
    end

    -- Other players
    for _, player in ipairs(Plrs:GetPlayers()) do
        if player ~= lp and player.Character then
            local hrp = player.Character:FindFirstChild("HumanoidRootPart")
            if hrp then
                local key = "P_"..player.UserId
                neededKeys[key] = true
                if not Minimap._dots[key] then
                    local dot = _makeMinimapDot(PLRESP_COLOR, 6)
                    dot.Parent = Minimap._frame
                    Minimap._dots[key] = dot
                end
                local px, py = _worldToMinimap(hrp.Position, refPos, camYaw)
                Minimap._dots[key].Position = UDim2.fromScale(px, py)
            end
        end
    end

    -- Balls
    for ball, state in pairs(tracker.states) do
        if ball and ball.Parent then
            local key = "B_"..tostring(ball)
            neededKeys[key] = true
            if not Minimap._dots[key] then
                local color = state.threat
                    and Color3.fromRGB(255, 50, 50)
                    or  Color3.fromRGB(255, 180, 30)
                local dot = _makeMinimapDot(color, state.threat and 7 or 5)
                dot.Parent = Minimap._frame
                Minimap._dots[key] = dot
            end
            local dot = Minimap._dots[key]
            dot.BackgroundColor3 = state.threat
                and Color3.fromRGB(255, 50 + math.floor(math.sin(os.clock()*8)*30), 50)
                or  Color3.fromRGB(255, 180, 30)
            local px, py = _worldToMinimap(ball.Position, refPos, camYaw)
            dot.Position = UDim2.fromScale(px, py)
        end
    end

    -- Remove stale dots
    local toDestroy = {}
    for key, dot in pairs(Minimap._dots) do
        if not neededKeys[key] then
            table.insert(toDestroy, { key = key, dot = dot })
        end
    end
    for _, item in ipairs(toDestroy) do
        pcall(function() item.dot:Destroy() end)
        Minimap._dots[item.key] = nil
    end
end

-- ════════════════════════════════════════════════════════════════════════════
--  §26  SCREEN ALERTS
--       Full-screen overlay text for critical events (threat incoming, combo).
-- ════════════════════════════════════════════════════════════════════════════
local ScreenAlerts = {
    _gui     = nil,
    _frame   = nil,
    _active  = false,
}

local function _alertInit()
    if ScreenAlerts._gui then return end

    local sg = Instance.new("ScreenGui")
    sg.Name          = "WindHubAlerts"
    sg.ResetOnSpawn  = false
    sg.ZIndexBehavior= Enum.ZIndexBehavior.Sibling
    sg.IgnoreGuiInset= true
    sg.Parent        = CoreGui

    local lbl = Instance.new("TextLabel", sg)
    lbl.Name               = "AlertLbl"
    lbl.Size               = UDim2.new(1, 0, 0, 60)
    lbl.Position           = UDim2.new(0, 0, 0.2, 0)
    lbl.BackgroundTransparency = 1
    lbl.TextSize           = 36
    lbl.Font               = Enum.Font.GothamBold
    lbl.TextColor3         = Color3.fromRGB(255, 60, 60)
    lbl.TextStrokeTransparency = 0.5
    lbl.TextStrokeColor3   = Color3.fromRGB(0, 0, 0)
    lbl.TextTransparency   = 1
    lbl.Text               = ""

    ScreenAlerts._gui   = sg
    ScreenAlerts._lbl   = lbl
end

local function screenAlert(text, color, duration)
    _alertInit()
    color    = color    or Color3.fromRGB(255, 60, 60)
    duration = duration or 1.5

    local lbl = ScreenAlerts._lbl
    lbl.Text        = text
    lbl.TextColor3  = color

    TS:Create(lbl, TweenInfo.new(0.1), { TextTransparency = 0 }):Play()
    task.delay(duration - 0.4, function()
        TS:Create(lbl, TweenInfo.new(0.35), { TextTransparency = 1 }):Play()
    end)
end

-- Trigger alert on new combo milestone
ComboTracker.onCombo:Connect(function(n)
    if n >= 3 then
        local colors = {
            [3]  = Color3.fromRGB(120, 200, 255),
            [5]  = Color3.fromRGB(255, 220, 30),
            [10] = Color3.fromRGB(255, 80, 255),
        }
        local col = colors[n] or Color3.fromRGB(255, 120, 30)
        screenAlert(("✦ %d  COMBO ✦"):format(n), col, 1.2)
    end
end)

ComboTracker.onNewBest:Connect(function(n)
    if n >= 5 then
        screenAlert(("★ NEW BEST: %d ★"):format(n), Color3.fromRGB(255, 215, 0), 2)
    end
end)

-- ════════════════════════════════════════════════════════════════════════════
--  §27  AUDIO MANAGER
--       Plays sound effects for key game events.
--       All sounds are pre-loaded from rbxassetid.
-- ════════════════════════════════════════════════════════════════════════════
local Audio = {
    sounds  = {},
    _loaded = false,
}

local SOUND_DEFS = {
    parry   = { id = "rbxassetid://9120394925", vol = 0.6, pitch = 1.1 },
    threat  = { id = "rbxassetid://6042053626", vol = 0.4, pitch = 1.0 },
    combo3  = { id = "rbxassetid://4612334281", vol = 0.5, pitch = 1.2 },
    combo5  = { id = "rbxassetid://4612334281", vol = 0.6, pitch = 1.4 },
    combo10 = { id = "rbxassetid://4612334281", vol = 0.8, pitch = 1.8 },
    miss    = { id = "rbxassetid://9120394925", vol = 0.3, pitch = 0.7 },
    spawn   = { id = "rbxassetid://6042053626", vol = 0.3, pitch = 0.9 },
}

task.spawn(function()
    task.wait(1)
    for name, def in pairs(SOUND_DEFS) do
        local s = Instance.new("Sound")
        s.SoundId   = def.id
        s.Volume    = def.vol * (Config.audioVolume or 0.5)
        s.PlayOnRemove = false
        s.RollOffMaxDistance = 0
        s.Parent    = SoundSvc
        Audio.sounds[name] = { sound = s, def = def }
    end
    Audio._loaded = true
end)

function Audio.play(name)
    if not Config.audioEnabled then return end
    local entry = Audio.sounds[name]
    if not entry then return end
    local s = entry.sound
    s.Volume      = entry.def.vol * (Config.audioVolume or 0.5)
    s.PlaybackSpeed = entry.def.pitch + (math.random() - 0.5) * 0.06  -- slight pitch variation
    pcall(function() s:Play() end)
end

-- Wire events
BallState.onParried:Connect(function()
    if Config.soundParry then Audio.play("parry") end
end)

ComboTracker.onCombo:Connect(function(n)
    if not Config.soundCombo then return end
    if     n >= 10 then Audio.play("combo10")
    elseif n >= 5  then Audio.play("combo5")
    elseif n >= 3  then Audio.play("combo3")
    end
end)

-- ════════════════════════════════════════════════════════════════════════════
--  §28  PROFILE MANAGER
--       Saves and loads Config snapshots to _G so they persist across
--       script re-executions in the same executor session.
-- ════════════════════════════════════════════════════════════════════════════
local ProfileManager = {
    _store   = {},   -- name → Config snapshot
    _current = "Default",
    PRESETS  = {
        Aggressive = {
            parryMode   = "Ultra",
            parryWindow = 0.80,
            humanizeMin = 0.005,
            humanizeMax = 0.025,
            monteCarlo  = false,
            autoDodge   = false,
        },
        Safe = {
            parryMode   = "Conservative",
            parryWindow = 0.40,
            humanizeMin = 0.025,
            humanizeMax = 0.065,
            autoDodge   = true,
            dodgeMode   = "Perp",
        },
        Competitive = {
            parryMode   = "Fusion",
            parryWindow = 0.55,
            physicsMode = "RK4",
            humanizeMin = 0.010,
            humanizeMax = 0.040,
            magnus      = true,
            monteCarlo  = true,
            mcSamples   = 128,
        },
        Tryhard = {
            parryMode   = "Ultra",
            physicsMode = "Fusion",
            parryWindow = 0.70,
            humanizeMin = 0.003,
            humanizeMax = 0.018,
            replionArm  = true,
            namecallArm = true,
            antiDetect  = true,
        },
    },
}

-- Restore from _G on reload
_G._WindProfiles = _G._WindProfiles or {}
ProfileManager._store = _G._WindProfiles

function ProfileManager:save(name)
    local snap = {}
    for k, v in pairs(DEFAULTS) do
        local cv = rawget(Config, k)
        snap[k] = cv ~= nil and cv or v
    end
    self._store[name] = snap
    _G._WindProfiles  = self._store
    self._current     = name
end

function ProfileManager:load(name)
    local snap = self._store[name] or self.PRESETS[name]
    if not snap then return false end
    for k, v in pairs(snap) do
        Config[k] = v
    end
    self._current = name
    return true
end

function ProfileManager:list()
    local names = {}
    for n in pairs(self._store) do table.insert(names, n) end
    for n in pairs(self.PRESETS) do
        local dup = false
        for _, existing in ipairs(names) do if existing == n then dup = true break end end
        if not dup then table.insert(names, n) end
    end
    table.sort(names)
    return names
end

function ProfileManager:delete(name)
    self._store[name]    = nil
    _G._WindProfiles[name] = nil
end

function ProfileManager:loadPreset(name)
    local preset = self.PRESETS[name]
    if not preset then return false end
    for k, v in pairs(preset) do
        Config[k] = v
    end
    self._current = name
    return true
end

-- ════════════════════════════════════════════════════════════════════════════
--  §29  SERVER ANALYSIS
--       Estimates server tick rate, packet round-trip, and server stability.
-- ════════════════════════════════════════════════════════════════════════════
local ServerAnalysis = {
    tickSamples  = {},
    tickRateEMA  = 60,
    stability    = 1.0,    -- 0 = very unstable, 1 = perfect
    lastHBAt     = 0,
    packetGaps   = {},
}

RS.Heartbeat:Connect(function(dt)
    local now = os.clock()
    table.insert(ServerAnalysis.tickSamples, dt)
    if #ServerAnalysis.tickSamples > 120 then
        table.remove(ServerAnalysis.tickSamples, 1)
    end

    -- EMA of tick rate
    ServerAnalysis.tickRateEMA = ServerAnalysis.tickRateEMA * 0.95
        + (1 / math.max(dt, 0.001)) * 0.05

    -- Gap between heartbeats (should be ~16.67 ms at 60 Hz)
    if ServerAnalysis.lastHBAt > 0 then
        local gap = now - ServerAnalysis.lastHBAt
        table.insert(ServerAnalysis.packetGaps, gap)
        if #ServerAnalysis.packetGaps > 60 then
            table.remove(ServerAnalysis.packetGaps, 1)
        end
    end
    ServerAnalysis.lastHBAt = now

    -- Stability = 1 - coefficient of variation of recent tick times
    if #ServerAnalysis.tickSamples >= 10 then
        local sum, sum2 = 0, 0
        local n = #ServerAnalysis.tickSamples
        for _, v in ipairs(ServerAnalysis.tickSamples) do
            sum  = sum  + v
            sum2 = sum2 + v * v
        end
        local mean = sum / n
        local var  = sum2 / n - mean * mean
        local cv   = math.sqrt(math.max(0, var)) / math.max(mean, 1e-6)
        ServerAnalysis.stability = math.clamp(1 - cv * 10, 0, 1)
    end
end)

function ServerAnalysis:report()
    return {
        tickRate  = self.tickRateEMA,
        stability = self.stability,
        ping      = PingComp.pingMs,
        jitter    = PingComp.jitter,
    }
end

-- ════════════════════════════════════════════════════════════════════════════
--  §30  DANGER ZONE VISUALISER
--       Renders a red cylinder at the ball's predicted impact point to show
--       where the player needs to be to parry.
-- ════════════════════════════════════════════════════════════════════════════
local DangerZone = {
    _parts = {},   -- ball → Part
}

local DZONE_THREAT  = Color3.fromRGB(255, 30, 30)
local DZONE_NEUTRAL = Color3.fromRGB(255, 160, 30)

local function _ensureDZone(ball, color)
    if not DangerZone._parts[ball] then
        local p = Instance.new("Part")
        p.Size              = Vector3.new(5, 0.2, 5)
        p.Anchored          = true
        p.CanCollide        = false
        p.CastShadow        = false
        p.Material          = Enum.Material.Neon
        p.Transparency      = 0.55
        p.Parent            = cam
        DangerZone._parts[ball] = p
    end
    local p = DangerZone._parts[ball]
    p.Color = color
    return p
end

local function _cleanDZone(ball)
    if DangerZone._parts[ball] then
        pcall(function() DangerZone._parts[ball]:Destroy() end)
        DangerZone._parts[ball] = nil
    end
end

function DangerZone.update(ball, state)
    if not Config.dangerZone then
        _cleanDZone(ball)
        return
    end
    if not (ball and ball.Parent and state.threat) then
        _cleanDZone(ball)
        return
    end

    -- Get predicted impact position (where the ball will be at ETA)
    local impactPos = state.physics:predict(state.eta)
    local col = state.threat and DZONE_THREAT or DZONE_NEUTRAL
    local p   = _ensureDZone(ball, col)

    -- Rotate for visual effect
    local spin = os.clock() * 2.5
    p.CFrame   = CFrame.new(impactPos) * CFrame.Angles(0, spin, 0)
    -- Pulse size based on proximity to parry window
    local win     = PingComp:effectiveWindow()
    local nearFrac= 1 - math.clamp(state.eta / math.max(win, 0.01), 0, 1)
    local sz      = 4 + nearFrac * 3
    p.Size        = Vector3.new(sz, 0.2, sz)
end

function DangerZone.clean(ball)
    _cleanDZone(ball)
end


-- ============================================================
-- §31  USER INTERFACE  –  WindHub 10-Tab Animated GUI
-- ============================================================
-- A complete, hand-built GUI framework. Supports PC (mouse +
-- keyboard) and mobile (touch). Spring-bounce open animation,
-- sliding tab indicator, toggle / slider / dropdown / button /
-- keybind widgets, notification toasts, draggable window,
-- minimise pill, live status bar and an executor name badge.
-- ============================================================

local UI = {}
UI.Theme = {
    Bg            = Color3.fromRGB(18, 18, 26),
    BgDark        = Color3.fromRGB(12, 12, 18),
    BgLight       = Color3.fromRGB(26, 26, 38),
    Panel         = Color3.fromRGB(22, 22, 32),
    Stroke        = Color3.fromRGB(40, 40, 58),
    Accent        = Color3.fromRGB(94, 132, 255),
    AccentDim     = Color3.fromRGB(60, 86, 170),
    Accent2       = Color3.fromRGB(150, 110, 255),
    Good          = Color3.fromRGB(70, 220, 140),
    Warn          = Color3.fromRGB(255, 196, 70),
    Bad           = Color3.fromRGB(255, 90, 100),
    Text          = Color3.fromRGB(235, 238, 250),
    TextDim       = Color3.fromRGB(150, 154, 175),
    TextFaint     = Color3.fromRGB(96, 100, 122),
    Toggle        = Color3.fromRGB(48, 48, 66),
}
UI._tweens   = {}
UI._registry = {}      -- name -> widget refresh fn
UI._tabs     = {}
UI._activeTab= nil

-- ── Tween helper ──────────────────────────────────────────
local function tween(obj, props, dur, style, dir)
    local ti = TweenInfo.new(dur or 0.22,
        style or Enum.EasingStyle.Quart,
        dir or Enum.EasingDirection.Out)
    local tw = TS:Create(obj, ti, props)
    tw:Play()
    return tw
end

local function springTween(obj, props, dur)
    local ti = TweenInfo.new(dur or 0.45, Enum.EasingStyle.Back, Enum.EasingDirection.Out)
    local tw = TS:Create(obj, ti, props)
    tw:Play()
    return tw
end

-- ── Primitive builders ────────────────────────────────────
local function mk(class, props, children)
    local o = Instance.new(class)
    if props then
        for k, v in pairs(props) do
            if k ~= "Parent" then o[k] = v end
        end
    end
    if children then
        for _, c in ipairs(children) do c.Parent = o end
    end
    if props and props.Parent then o.Parent = props.Parent end
    return o
end

local function corner(parent, r)
    return mk("UICorner", { CornerRadius = UDim.new(0, r or 8), Parent = parent })
end

local function stroke(parent, color, thick, trans)
    return mk("UIStroke", {
        Color = color or UI.Theme.Stroke,
        Thickness = thick or 1,
        Transparency = trans or 0,
        ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
        Parent = parent,
    })
end

local function gradient(parent, c1, c2, rot)
    return mk("UIGradient", {
        Color = ColorSequence.new(c1, c2),
        Rotation = rot or 90,
        Parent = parent,
    })
end

local function padding(parent, all)
    return mk("UIPadding", {
        PaddingTop    = UDim.new(0, all),
        PaddingBottom = UDim.new(0, all),
        PaddingLeft   = UDim.new(0, all),
        PaddingRight  = UDim.new(0, all),
        Parent = parent,
    })
end


-- ── Root ScreenGui ────────────────────────────────────────
local function destroyOld()
    for _, g in ipairs(CoreGui:GetChildren()) do
        if g.Name == "WindHubGui" then
            pcall(function() g:Destroy() end)
        end
    end
end
destroyOld()

local screen = mk("ScreenGui", {
    Name = "WindHubGui",
    ResetOnSpawn = false,
    ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
    IgnoreGuiInset = true,
    DisplayOrder = 9999,
})
-- protect-gui where supported
pcall(function()
    if syn and syn.protect_gui then
        syn.protect_gui(screen)
        screen.Parent = CoreGui
    elseif gethui then
        screen.Parent = gethui()
    else
        screen.Parent = CoreGui
    end
end)
if not screen.Parent then screen.Parent = CoreGui end
UI.screen = screen

-- ── Window sizing (responsive for mobile vs PC) ───────────
local isMobile = UIS.TouchEnabled and not UIS.KeyboardEnabled
UI.isMobile    = isMobile
local viewport = cam and cam.ViewportSize or Vector2.new(1280, 720)
local winW = isMobile and math.min(520, viewport.X * 0.92) or 640
local winH = isMobile and math.min(360, viewport.Y * 0.82) or 440

-- ── Main window ───────────────────────────────────────────
local window = mk("Frame", {
    Name = "Window",
    Parent = screen,
    AnchorPoint = Vector2.new(0.5, 0.5),
    Position = UDim2.new(0.5, 0, 0.5, 0),
    Size = UDim2.new(0, 0, 0, 0),     -- animate up from 0
    BackgroundColor3 = UI.Theme.Bg,
    BorderSizePixel = 0,
    ClipsDescendants = true,
})
corner(window, 14)
stroke(window, UI.Theme.Stroke, 1.5)
UI.window = window

-- subtle inner gradient
local bgGrad = mk("Frame", {
    Name = "BgGrad",
    Parent = window,
    Size = UDim2.new(1, 0, 1, 0),
    BackgroundColor3 = UI.Theme.Bg,
    BorderSizePixel = 0,
    ZIndex = 0,
})
gradient(bgGrad, UI.Theme.Bg, UI.Theme.BgDark, 115)


-- ── Header bar ────────────────────────────────────────────
local header = mk("Frame", {
    Name = "Header",
    Parent = window,
    Size = UDim2.new(1, 0, 0, 46),
    BackgroundColor3 = UI.Theme.BgDark,
    BorderSizePixel = 0,
    ZIndex = 3,
})
corner(header, 14)
-- mask the bottom rounded corners of header
mk("Frame", {
    Parent = header,
    Size = UDim2.new(1, 0, 0, 14),
    Position = UDim2.new(0, 0, 1, -14),
    BackgroundColor3 = UI.Theme.BgDark,
    BorderSizePixel = 0,
    ZIndex = 3,
})

-- logo orb
local logo = mk("Frame", {
    Name = "Logo",
    Parent = header,
    Size = UDim2.new(0, 26, 0, 26),
    Position = UDim2.new(0, 14, 0.5, -13),
    BackgroundColor3 = UI.Theme.Accent,
    BorderSizePixel = 0,
    ZIndex = 4,
})
corner(logo, 13)
gradient(logo, UI.Theme.Accent, UI.Theme.Accent2, 45)
mk("TextLabel", {
    Parent = logo,
    Size = UDim2.new(1, 0, 1, 0),
    BackgroundTransparency = 1,
    Text = "W",
    Font = Enum.Font.GothamBold,
    TextSize = 15,
    TextColor3 = Color3.fromRGB(255, 255, 255),
    ZIndex = 5,
})

-- title
mk("TextLabel", {
    Name = "Title",
    Parent = header,
    Size = UDim2.new(0, 200, 1, 0),
    Position = UDim2.new(0, 50, 0, 0),
    BackgroundTransparency = 1,
    Text = "WindHub",
    Font = Enum.Font.GothamBold,
    TextSize = 18,
    TextColor3 = UI.Theme.Text,
    TextXAlignment = Enum.TextXAlignment.Left,
    ZIndex = 4,
})
mk("TextLabel", {
    Name = "Version",
    Parent = header,
    Size = UDim2.new(0, 60, 1, 0),
    Position = UDim2.new(0, 130, 0, 1),
    BackgroundTransparency = 1,
    Text = "v6.0",
    Font = Enum.Font.GothamMedium,
    TextSize = 11,
    TextColor3 = UI.Theme.TextFaint,
    TextXAlignment = Enum.TextXAlignment.Left,
    ZIndex = 4,
})

-- executor badge
local execName = (EX and EX.name) or "Unknown"
local badge = mk("Frame", {
    Name = "ExecBadge",
    Parent = header,
    Size = UDim2.new(0, 0, 0, 24),
    Position = UDim2.new(1, -120, 0.5, -12),
    BackgroundColor3 = UI.Theme.BgLight,
    BorderSizePixel = 0,
    AutomaticSize = Enum.AutomaticSize.X,
    ZIndex = 4,
})
corner(badge, 12)
stroke(badge, UI.Theme.AccentDim, 1, 0.3)
mk("UIPadding", {
    Parent = badge,
    PaddingLeft = UDim.new(0, 10),
    PaddingRight = UDim.new(0, 10),
})
local badgeDot = mk("Frame", {
    Parent = badge,
    Size = UDim2.new(0, 7, 0, 7),
    Position = UDim2.new(0, 0, 0.5, -3),
    BackgroundColor3 = UI.Theme.Good,
    BorderSizePixel = 0,
    ZIndex = 5,
})
corner(badgeDot, 4)
mk("TextLabel", {
    Parent = badge,
    Size = UDim2.new(0, 0, 1, 0),
    Position = UDim2.new(0, 14, 0, 0),
    AutomaticSize = Enum.AutomaticSize.X,
    BackgroundTransparency = 1,
    Text = execName,
    Font = Enum.Font.GothamSemibold,
    TextSize = 12,
    TextColor3 = UI.Theme.Text,
    TextXAlignment = Enum.TextXAlignment.Left,
    ZIndex = 5,
})

-- close + minimise buttons
local function headerBtn(name, txt, xOff, col)
    local b = mk("TextButton", {
        Name = name,
        Parent = header,
        Size = UDim2.new(0, 26, 0, 26),
        Position = UDim2.new(1, xOff, 0.5, -13),
        BackgroundColor3 = UI.Theme.BgLight,
        BorderSizePixel = 0,
        Text = txt,
        Font = Enum.Font.GothamBold,
        TextSize = 15,
        TextColor3 = col or UI.Theme.TextDim,
        AutoButtonColor = false,
        ZIndex = 5,
    })
    corner(b, 8)
    b.MouseEnter:Connect(function()
        tween(b, { BackgroundColor3 = UI.Theme.Stroke }, 0.15)
    end)
    b.MouseLeave:Connect(function()
        tween(b, { BackgroundColor3 = UI.Theme.BgLight }, 0.15)
    end)
    return b
end
local btnClose = headerBtn("Close", "✕", -34, UI.Theme.Bad)
local btnMin   = headerBtn("Min", "—", -64, UI.Theme.Warn)


-- ── Tab sidebar ───────────────────────────────────────────
local sidebar = mk("Frame", {
    Name = "Sidebar",
    Parent = window,
    Size = UDim2.new(0, isMobile and 132 or 150, 1, -46 - 28),
    Position = UDim2.new(0, 0, 0, 46),
    BackgroundColor3 = UI.Theme.BgDark,
    BorderSizePixel = 0,
    ZIndex = 2,
})
local sideList = mk("Frame", {
    Parent = sidebar,
    Size = UDim2.new(1, 0, 1, 0),
    BackgroundTransparency = 1,
    ZIndex = 2,
})
mk("UIListLayout", {
    Parent = sideList,
    Padding = UDim.new(0, 4),
    SortOrder = Enum.SortOrder.LayoutOrder,
    HorizontalAlignment = Enum.HorizontalAlignment.Center,
})
mk("UIPadding", {
    Parent = sideList,
    PaddingTop = UDim.new(0, 8),
    PaddingLeft = UDim.new(0, 8),
    PaddingRight = UDim.new(0, 8),
})

-- sliding active indicator
local tabIndicator = mk("Frame", {
    Name = "TabIndicator",
    Parent = sidebar,
    Size = UDim2.new(0, 3, 0, 28),
    Position = UDim2.new(0, 0, 0, 12),
    BackgroundColor3 = UI.Theme.Accent,
    BorderSizePixel = 0,
    ZIndex = 4,
})
corner(tabIndicator, 2)
gradient(tabIndicator, UI.Theme.Accent, UI.Theme.Accent2, 90)

-- content container
local content = mk("Frame", {
    Name = "Content",
    Parent = window,
    Size = UDim2.new(1, -(isMobile and 132 or 150), 1, -46 - 28),
    Position = UDim2.new(0, isMobile and 132 or 150, 0, 46),
    BackgroundColor3 = UI.Theme.Bg,
    BorderSizePixel = 0,
    ClipsDescendants = true,
    ZIndex = 1,
})

-- ── Status bar (bottom) ───────────────────────────────────
local statusBar = mk("Frame", {
    Name = "StatusBar",
    Parent = window,
    Size = UDim2.new(1, 0, 0, 28),
    Position = UDim2.new(0, 0, 1, -28),
    BackgroundColor3 = UI.Theme.BgDark,
    BorderSizePixel = 0,
    ZIndex = 3,
})
mk("UIPadding", {
    Parent = statusBar,
    PaddingLeft = UDim.new(0, 12),
    PaddingRight = UDim.new(0, 12),
})
local statusLeft = mk("TextLabel", {
    Name = "StatusLeft",
    Parent = statusBar,
    Size = UDim2.new(0.5, 0, 1, 0),
    BackgroundTransparency = 1,
    Text = "● Idle",
    Font = Enum.Font.GothamMedium,
    TextSize = 11,
    TextColor3 = UI.Theme.TextDim,
    TextXAlignment = Enum.TextXAlignment.Left,
    ZIndex = 4,
})
local statusRight = mk("TextLabel", {
    Name = "StatusRight",
    Parent = statusBar,
    Size = UDim2.new(0.5, 0, 1, 0),
    Position = UDim2.new(0.5, 0, 0, 0),
    BackgroundTransparency = 1,
    Text = "FPS -- · Parries 0",
    Font = Enum.Font.GothamMedium,
    TextSize = 11,
    TextColor3 = UI.Theme.TextFaint,
    TextXAlignment = Enum.TextXAlignment.Right,
    ZIndex = 4,
})
UI.statusLeft  = statusLeft
UI.statusRight = statusRight


-- ── Tab system ────────────────────────────────────────────
function UI.addTab(name, icon)
    local idx = #UI._tabs + 1

    -- sidebar button
    local btn = mk("TextButton", {
        Name = "Tab_" .. name,
        Parent = sideList,
        Size = UDim2.new(1, 0, 0, 34),
        BackgroundColor3 = UI.Theme.BgLight,
        BackgroundTransparency = 1,
        Text = "",
        AutoButtonColor = false,
        LayoutOrder = idx,
        ZIndex = 3,
    })
    corner(btn, 8)
    local ic = mk("TextLabel", {
        Parent = btn,
        Size = UDim2.new(0, 24, 1, 0),
        Position = UDim2.new(0, 8, 0, 0),
        BackgroundTransparency = 1,
        Text = icon or "•",
        Font = Enum.Font.GothamBold,
        TextSize = 14,
        TextColor3 = UI.Theme.TextDim,
        ZIndex = 4,
    })
    local lbl = mk("TextLabel", {
        Parent = btn,
        Size = UDim2.new(1, -38, 1, 0),
        Position = UDim2.new(0, 34, 0, 0),
        BackgroundTransparency = 1,
        Text = name,
        Font = Enum.Font.GothamMedium,
        TextSize = 13,
        TextColor3 = UI.Theme.TextDim,
        TextXAlignment = Enum.TextXAlignment.Left,
        ZIndex = 4,
    })

    -- content page (scrolling)
    local page = mk("ScrollingFrame", {
        Name = "Page_" .. name,
        Parent = content,
        Size = UDim2.new(1, 0, 1, 0),
        Position = UDim2.new(0, 0, 0, 0),
        BackgroundTransparency = 1,
        BorderSizePixel = 0,
        ScrollBarThickness = 4,
        ScrollBarImageColor3 = UI.Theme.Stroke,
        CanvasSize = UDim2.new(0, 0, 0, 0),
        AutomaticCanvasSize = Enum.AutomaticSize.Y,
        ScrollingDirection = Enum.ScrollingDirection.Y,
        Visible = false,
        ZIndex = 1,
    })
    mk("UIListLayout", {
        Parent = page,
        Padding = UDim.new(0, 8),
        SortOrder = Enum.SortOrder.LayoutOrder,
    })
    mk("UIPadding", {
        Parent = page,
        PaddingTop = UDim.new(0, 12),
        PaddingBottom = UDim.new(0, 12),
        PaddingLeft = UDim.new(0, 14),
        PaddingRight = UDim.new(0, 14),
    })

    local tabObj = {
        name = name, btn = btn, page = page,
        icon = ic, label = lbl, index = idx,
        order = 0,
    }
    UI._tabs[idx] = tabObj

    local function activate()
        if UI._activeTab == tabObj then return end
        -- deactivate old
        for _, t in ipairs(UI._tabs) do
            if t.page.Visible then
                t.page.Visible = false
                tween(t.btn, { BackgroundTransparency = 1 }, 0.15)
                tween(t.icon, { TextColor3 = UI.Theme.TextDim }, 0.15)
                tween(t.label, { TextColor3 = UI.Theme.TextDim }, 0.15)
            end
        end
        -- activate new
        page.Visible = true
        page.Position = UDim2.new(0.04, 0, 0, 0)
        page.CanvasPosition = Vector2.new(0, 0)
        tween(page, { Position = UDim2.new(0, 0, 0, 0) }, 0.28)
        tween(btn, { BackgroundTransparency = 0, BackgroundColor3 = UI.Theme.BgLight }, 0.15)
        tween(ic, { TextColor3 = UI.Theme.Accent }, 0.15)
        tween(lbl, { TextColor3 = UI.Theme.Text }, 0.15)
        -- slide indicator
        local targetY = btn.AbsolutePosition.Y - sidebar.AbsolutePosition.Y + 3
        tween(tabIndicator, { Position = UDim2.new(0, 0, 0, targetY) }, 0.25, Enum.EasingStyle.Quint)
        UI._activeTab = tabObj
    end
    tabObj.activate = activate

    btn.MouseButton1Click:Connect(activate)
    btn.MouseEnter:Connect(function()
        if UI._activeTab ~= tabObj then
            tween(btn, { BackgroundTransparency = 0.6, BackgroundColor3 = UI.Theme.BgLight }, 0.12)
        end
    end)
    btn.MouseLeave:Connect(function()
        if UI._activeTab ~= tabObj then
            tween(btn, { BackgroundTransparency = 1 }, 0.12)
        end
    end)

    return tabObj
end


-- ── Widget: Section header ────────────────────────────────
local function nextOrder(page)
    page:SetAttribute("ord", (page:GetAttribute("ord") or 0) + 1)
    return page:GetAttribute("ord")
end

function UI.section(page, title)
    local holder = mk("Frame", {
        Parent = page,
        Size = UDim2.new(1, 0, 0, 26),
        BackgroundTransparency = 1,
        LayoutOrder = nextOrder(page),
    })
    mk("TextLabel", {
        Parent = holder,
        Size = UDim2.new(1, 0, 1, 0),
        BackgroundTransparency = 1,
        Text = string.upper(title),
        Font = Enum.Font.GothamBold,
        TextSize = 11,
        TextColor3 = UI.Theme.Accent,
        TextXAlignment = Enum.TextXAlignment.Left,
        TextYAlignment = Enum.TextYAlignment.Bottom,
    })
    return holder
end

-- ── Widget: Card container ────────────────────────────────
function UI.card(page)
    local card = mk("Frame", {
        Parent = page,
        Size = UDim2.new(1, 0, 0, 0),
        AutomaticSize = Enum.AutomaticSize.Y,
        BackgroundColor3 = UI.Theme.Panel,
        BorderSizePixel = 0,
        LayoutOrder = nextOrder(page),
    })
    corner(card, 10)
    stroke(card, UI.Theme.Stroke, 1, 0.2)
    local inner = mk("Frame", {
        Parent = card,
        Size = UDim2.new(1, 0, 0, 0),
        AutomaticSize = Enum.AutomaticSize.Y,
        BackgroundTransparency = 1,
    })
    mk("UIListLayout", {
        Parent = inner,
        Padding = UDim.new(0, 2),
        SortOrder = Enum.SortOrder.LayoutOrder,
    })
    padding(inner, 6)
    return inner
end

-- ── Widget: Toggle ────────────────────────────────────────
function UI.toggle(parent, opts)
    opts = opts or {}
    local state = opts.default and true or false
    local row = mk("Frame", {
        Parent = parent,
        Size = UDim2.new(1, 0, 0, 38),
        BackgroundTransparency = 1,
        LayoutOrder = opts.order or nextOrder(parent),
    })
    mk("TextLabel", {
        Parent = row,
        Size = UDim2.new(1, -60, 1, 0),
        Position = UDim2.new(0, 6, 0, 0),
        BackgroundTransparency = 1,
        Text = opts.text or "Toggle",
        Font = Enum.Font.GothamMedium,
        TextSize = 13,
        TextColor3 = UI.Theme.Text,
        TextXAlignment = Enum.TextXAlignment.Left,
    })
    if opts.desc then
        mk("TextLabel", {
            Parent = row,
            Size = UDim2.new(1, -60, 0, 14),
            Position = UDim2.new(0, 6, 1, -15),
            BackgroundTransparency = 1,
            Text = opts.desc,
            Font = Enum.Font.Gotham,
            TextSize = 10,
            TextColor3 = UI.Theme.TextFaint,
            TextXAlignment = Enum.TextXAlignment.Left,
        })
    end
    local track = mk("TextButton", {
        Parent = row,
        Size = UDim2.new(0, 42, 0, 22),
        Position = UDim2.new(1, -48, 0.5, -11),
        BackgroundColor3 = state and UI.Theme.Accent or UI.Theme.Toggle,
        Text = "",
        AutoButtonColor = false,
        BorderSizePixel = 0,
    })
    corner(track, 11)
    local knob = mk("Frame", {
        Parent = track,
        Size = UDim2.new(0, 18, 0, 18),
        Position = state and UDim2.new(1, -20, 0.5, -9) or UDim2.new(0, 2, 0.5, -9),
        BackgroundColor3 = Color3.fromRGB(255, 255, 255),
        BorderSizePixel = 0,
    })
    corner(knob, 9)

    local function set(v, fire)
        state = v and true or false
        tween(track, { BackgroundColor3 = state and UI.Theme.Accent or UI.Theme.Toggle }, 0.18)
        tween(knob, { Position = state and UDim2.new(1, -20, 0.5, -9) or UDim2.new(0, 2, 0.5, -9) }, 0.18, Enum.EasingStyle.Back)
        if fire ~= false and opts.callback then
            pcall(opts.callback, state)
        end
    end
    local function press()
        set(not state, true)
    end
    track.MouseButton1Click:Connect(press)
    if isMobile then track.TouchTap:Connect(function() end) end

    if opts.flag then
        UI._registry[opts.flag] = function(v) set(v, false) end
    end
    return { set = set, get = function() return state end }
end


-- ── Widget: Slider ────────────────────────────────────────
function UI.slider(parent, opts)
    opts = opts or {}
    local minV = opts.min or 0
    local maxV = opts.max or 100
    local val  = opts.default or minV
    local step = opts.step or 1
    local suffix = opts.suffix or ""

    local row = mk("Frame", {
        Parent = parent,
        Size = UDim2.new(1, 0, 0, 46),
        BackgroundTransparency = 1,
        LayoutOrder = opts.order or nextOrder(parent),
    })
    mk("TextLabel", {
        Parent = row,
        Size = UDim2.new(1, -70, 0, 18),
        Position = UDim2.new(0, 6, 0, 2),
        BackgroundTransparency = 1,
        Text = opts.text or "Slider",
        Font = Enum.Font.GothamMedium,
        TextSize = 13,
        TextColor3 = UI.Theme.Text,
        TextXAlignment = Enum.TextXAlignment.Left,
    })
    local valLbl = mk("TextLabel", {
        Parent = row,
        Size = UDim2.new(0, 64, 0, 18),
        Position = UDim2.new(1, -64, 0, 2),
        BackgroundTransparency = 1,
        Text = tostring(val) .. suffix,
        Font = Enum.Font.GothamBold,
        TextSize = 12,
        TextColor3 = UI.Theme.Accent,
        TextXAlignment = Enum.TextXAlignment.Right,
    })
    local bar = mk("Frame", {
        Parent = row,
        Size = UDim2.new(1, -12, 0, 6),
        Position = UDim2.new(0, 6, 0, 28),
        BackgroundColor3 = UI.Theme.Toggle,
        BorderSizePixel = 0,
    })
    corner(bar, 3)
    local fill = mk("Frame", {
        Parent = bar,
        Size = UDim2.new((val - minV) / (maxV - minV), 0, 1, 0),
        BackgroundColor3 = UI.Theme.Accent,
        BorderSizePixel = 0,
    })
    corner(fill, 3)
    gradient(fill, UI.Theme.Accent, UI.Theme.Accent2, 0)
    local knob = mk("Frame", {
        Parent = bar,
        Size = UDim2.new(0, 14, 0, 14),
        Position = UDim2.new((val - minV) / (maxV - minV), -7, 0.5, -7),
        BackgroundColor3 = Color3.fromRGB(255, 255, 255),
        BorderSizePixel = 0,
        ZIndex = 3,
    })
    corner(knob, 7)
    local hit = mk("TextButton", {
        Parent = bar,
        Size = UDim2.new(1, 20, 1, 24),
        Position = UDim2.new(0, -10, 0.5, -12),
        BackgroundTransparency = 1,
        Text = "",
    })

    local function setFromAlpha(a)
        a = math.clamp(a, 0, 1)
        local raw = minV + (maxV - minV) * a
        raw = math.floor((raw / step) + 0.5) * step
        raw = math.clamp(raw, minV, maxV)
        val = raw
        local alpha = (val - minV) / (maxV - minV)
        fill.Size = UDim2.new(alpha, 0, 1, 0)
        knob.Position = UDim2.new(alpha, -7, 0.5, -7)
        local disp = (step < 1) and string.format("%.2f", val) or tostring(math.floor(val))
        valLbl.Text = disp .. suffix
        if opts.callback then pcall(opts.callback, val) end
    end

    local dragging = false
    local function update(inputPos)
        local a = (inputPos.X - bar.AbsolutePosition.X) / bar.AbsoluteSize.X
        setFromAlpha(a)
    end
    hit.InputBegan:Connect(function(inp)
        if inp.UserInputType == Enum.UserInputType.MouseButton1
        or inp.UserInputType == Enum.UserInputType.Touch then
            dragging = true
            update(inp.Position)
        end
    end)
    hit.InputEnded:Connect(function(inp)
        if inp.UserInputType == Enum.UserInputType.MouseButton1
        or inp.UserInputType == Enum.UserInputType.Touch then
            dragging = false
        end
    end)
    UIS.InputChanged:Connect(function(inp)
        if dragging and (inp.UserInputType == Enum.UserInputType.MouseMovement
        or inp.UserInputType == Enum.UserInputType.Touch) then
            update(inp.Position)
        end
    end)

    local api = {
        set = function(v)
            setFromAlpha((v - minV) / (maxV - minV))
        end,
        get = function() return val end,
    }
    if opts.flag then
        UI._registry[opts.flag] = function(v) api.set(v) end
    end
    return api
end


-- ── Widget: Dropdown / mode selector ──────────────────────
function UI.dropdown(parent, opts)
    opts = opts or {}
    local options = opts.options or {}
    local current = opts.default or options[1]
    local open = false

    local row = mk("Frame", {
        Parent = parent,
        Size = UDim2.new(1, 0, 0, 38),
        BackgroundTransparency = 1,
        LayoutOrder = opts.order or nextOrder(parent),
        ClipsDescendants = false,
        ZIndex = 2,
    })
    mk("TextLabel", {
        Parent = row,
        Size = UDim2.new(0.5, -6, 1, 0),
        Position = UDim2.new(0, 6, 0, 0),
        BackgroundTransparency = 1,
        Text = opts.text or "Mode",
        Font = Enum.Font.GothamMedium,
        TextSize = 13,
        TextColor3 = UI.Theme.Text,
        TextXAlignment = Enum.TextXAlignment.Left,
    })
    local box = mk("TextButton", {
        Parent = row,
        Size = UDim2.new(0.5, -12, 0, 28),
        Position = UDim2.new(0.5, 6, 0.5, -14),
        BackgroundColor3 = UI.Theme.BgLight,
        Text = "",
        AutoButtonColor = false,
        BorderSizePixel = 0,
        ZIndex = 3,
    })
    corner(box, 8)
    stroke(box, UI.Theme.Stroke, 1)
    local sel = mk("TextLabel", {
        Parent = box,
        Size = UDim2.new(1, -34, 1, 0),
        Position = UDim2.new(0, 10, 0, 0),
        BackgroundTransparency = 1,
        Text = tostring(current),
        Font = Enum.Font.GothamMedium,
        TextSize = 12,
        TextColor3 = UI.Theme.Accent,
        TextXAlignment = Enum.TextXAlignment.Left,
        ZIndex = 4,
    })
    local arrow = mk("TextLabel", {
        Parent = box,
        Size = UDim2.new(0, 24, 1, 0),
        Position = UDim2.new(1, -24, 0, 0),
        BackgroundTransparency = 1,
        Text = "▾",
        Font = Enum.Font.GothamBold,
        TextSize = 12,
        TextColor3 = UI.Theme.TextDim,
        ZIndex = 4,
    })
    local listFrame = mk("Frame", {
        Parent = box,
        Size = UDim2.new(1, 0, 0, 0),
        Position = UDim2.new(0, 0, 1, 4),
        BackgroundColor3 = UI.Theme.BgDark,
        BorderSizePixel = 0,
        Visible = false,
        ClipsDescendants = true,
        ZIndex = 20,
    })
    corner(listFrame, 8)
    stroke(listFrame, UI.Theme.Stroke, 1)
    local listLayout = mk("UIListLayout", {
        Parent = listFrame,
        Padding = UDim.new(0, 2),
        SortOrder = Enum.SortOrder.LayoutOrder,
    })
    padding(listFrame, 4)

    local function setVal(v)
        current = v
        sel.Text = tostring(v)
        if opts.callback then pcall(opts.callback, v) end
    end

    for i, optv in ipairs(options) do
        local item = mk("TextButton", {
            Parent = listFrame,
            Size = UDim2.new(1, 0, 0, 26),
            BackgroundColor3 = UI.Theme.BgLight,
            BackgroundTransparency = 1,
            Text = tostring(optv),
            Font = Enum.Font.GothamMedium,
            TextSize = 12,
            TextColor3 = UI.Theme.TextDim,
            AutoButtonColor = false,
            LayoutOrder = i,
            ZIndex = 21,
        })
        corner(item, 6)
        item.MouseEnter:Connect(function()
            tween(item, { BackgroundTransparency = 0, BackgroundColor3 = UI.Theme.Stroke }, 0.1)
        end)
        item.MouseLeave:Connect(function()
            tween(item, { BackgroundTransparency = 1 }, 0.1)
        end)
        item.MouseButton1Click:Connect(function()
            setVal(optv)
            open = false
            tween(arrow, { Rotation = 0 }, 0.15)
            tween(listFrame, { Size = UDim2.new(1, 0, 0, 0) }, 0.18)
            task.delay(0.18, function() if not open then listFrame.Visible = false end end)
        end)
    end

    box.MouseButton1Click:Connect(function()
        open = not open
        if open then
            listFrame.Visible = true
            local h = listLayout.AbsoluteContentSize.Y + 8
            tween(arrow, { Rotation = 180 }, 0.15)
            tween(listFrame, { Size = UDim2.new(1, 0, 0, h) }, 0.2, Enum.EasingStyle.Quint)
        else
            tween(arrow, { Rotation = 0 }, 0.15)
            tween(listFrame, { Size = UDim2.new(1, 0, 0, 0) }, 0.18)
            task.delay(0.18, function() if not open then listFrame.Visible = false end end)
        end
    end)

    local api = { set = setVal, get = function() return current end }
    if opts.flag then UI._registry[opts.flag] = setVal end
    return api
end

-- ── Widget: Button ────────────────────────────────────────
function UI.button(parent, opts)
    opts = opts or {}
    local b = mk("TextButton", {
        Parent = parent,
        Size = UDim2.new(1, 0, 0, 34),
        BackgroundColor3 = opts.danger and UI.Theme.Bad or UI.Theme.Accent,
        Text = opts.text or "Button",
        Font = Enum.Font.GothamSemibold,
        TextSize = 13,
        TextColor3 = Color3.fromRGB(255, 255, 255),
        AutoButtonColor = false,
        BorderSizePixel = 0,
        LayoutOrder = opts.order or nextOrder(parent),
    })
    corner(b, 8)
    if not opts.danger then gradient(b, UI.Theme.Accent, UI.Theme.AccentDim, 90) end
    local baseColor = opts.danger and UI.Theme.Bad or UI.Theme.Accent
    b.MouseEnter:Connect(function() tween(b, { BackgroundColor3 = UI.Theme.Accent2 }, 0.12) end)
    b.MouseLeave:Connect(function() tween(b, { BackgroundColor3 = baseColor }, 0.12) end)
    b.MouseButton1Click:Connect(function()
        tween(b, { Size = UDim2.new(1, -6, 0, 32) }, 0.08)
        task.delay(0.08, function() tween(b, { Size = UDim2.new(1, 0, 0, 34) }, 0.1) end)
        if opts.callback then pcall(opts.callback) end
    end)
    return b
end

-- ── Widget: Label / paragraph ─────────────────────────────
function UI.label(parent, opts)
    opts = opts or {}
    local l = mk("TextLabel", {
        Parent = parent,
        Size = UDim2.new(1, 0, 0, opts.height or 18),
        AutomaticSize = opts.wrap and Enum.AutomaticSize.Y or Enum.AutomaticSize.None,
        BackgroundTransparency = 1,
        Text = opts.text or "",
        Font = opts.font or Enum.Font.Gotham,
        TextSize = opts.size or 12,
        TextColor3 = opts.color or UI.Theme.TextDim,
        TextXAlignment = opts.align or Enum.TextXAlignment.Left,
        TextWrapped = opts.wrap or false,
        TextYAlignment = Enum.TextYAlignment.Top,
        LayoutOrder = opts.order or nextOrder(parent),
    })
    return l
end

-- ── Widget: Keybind ───────────────────────────────────────
function UI.keybind(parent, opts)
    opts = opts or {}
    local key = opts.default
    local listening = false
    local row = mk("Frame", {
        Parent = parent,
        Size = UDim2.new(1, 0, 0, 38),
        BackgroundTransparency = 1,
        LayoutOrder = opts.order or nextOrder(parent),
    })
    mk("TextLabel", {
        Parent = row,
        Size = UDim2.new(1, -90, 1, 0),
        Position = UDim2.new(0, 6, 0, 0),
        BackgroundTransparency = 1,
        Text = opts.text or "Keybind",
        Font = Enum.Font.GothamMedium,
        TextSize = 13,
        TextColor3 = UI.Theme.Text,
        TextXAlignment = Enum.TextXAlignment.Left,
    })
    local kb = mk("TextButton", {
        Parent = row,
        Size = UDim2.new(0, 76, 0, 26),
        Position = UDim2.new(1, -82, 0.5, -13),
        BackgroundColor3 = UI.Theme.BgLight,
        Text = key and key.Name or "None",
        Font = Enum.Font.GothamSemibold,
        TextSize = 11,
        TextColor3 = UI.Theme.Accent,
        AutoButtonColor = false,
        BorderSizePixel = 0,
    })
    corner(kb, 7)
    stroke(kb, UI.Theme.Stroke, 1)
    kb.MouseButton1Click:Connect(function()
        listening = true
        kb.Text = "..."
        tween(kb, { BackgroundColor3 = UI.Theme.AccentDim }, 0.12)
    end)
    UIS.InputBegan:Connect(function(inp, gp)
        if listening and inp.UserInputType == Enum.UserInputType.Keyboard then
            key = inp.KeyCode
            kb.Text = key.Name
            listening = false
            tween(kb, { BackgroundColor3 = UI.Theme.BgLight }, 0.12)
            if opts.callback then pcall(opts.callback, key) end
        end
    end)
    return { get = function() return key end }
end


-- ── Widget: Stat tile (for dashboards) ────────────────────
function UI.statTile(parent, opts)
    opts = opts or {}
    local tile = mk("Frame", {
        Parent = parent,
        Size = UDim2.new(0.5, -4, 0, 56),
        BackgroundColor3 = UI.Theme.Panel,
        BorderSizePixel = 0,
        LayoutOrder = opts.order or nextOrder(parent),
    })
    corner(tile, 10)
    stroke(tile, UI.Theme.Stroke, 1, 0.3)
    mk("TextLabel", {
        Parent = tile,
        Size = UDim2.new(1, -16, 0, 14),
        Position = UDim2.new(0, 10, 0, 8),
        BackgroundTransparency = 1,
        Text = opts.label or "Stat",
        Font = Enum.Font.GothamMedium,
        TextSize = 10,
        TextColor3 = UI.Theme.TextFaint,
        TextXAlignment = Enum.TextXAlignment.Left,
    })
    local val = mk("TextLabel", {
        Parent = tile,
        Size = UDim2.new(1, -16, 0, 24),
        Position = UDim2.new(0, 10, 0, 24),
        BackgroundTransparency = 1,
        Text = opts.value or "--",
        Font = Enum.Font.GothamBold,
        TextSize = 18,
        TextColor3 = opts.color or UI.Theme.Text,
        TextXAlignment = Enum.TextXAlignment.Left,
    })
    return { set = function(v) val.Text = tostring(v) end,
             setColor = function(c) val.TextColor3 = c end }
end

-- ── Notification toast system ─────────────────────────────
local toastHolder = mk("Frame", {
    Name = "Toasts",
    Parent = screen,
    Size = UDim2.new(0, 280, 1, -20),
    Position = UDim2.new(1, -290, 0, 10),
    BackgroundTransparency = 1,
    ZIndex = 50,
})
mk("UIListLayout", {
    Parent = toastHolder,
    Padding = UDim.new(0, 8),
    VerticalAlignment = Enum.VerticalAlignment.Bottom,
    HorizontalAlignment = Enum.HorizontalAlignment.Right,
    SortOrder = Enum.SortOrder.LayoutOrder,
})

function UI.notify(opts)
    opts = opts or {}
    local title = opts.title or "WindHub"
    local msg   = opts.text or ""
    local dur   = opts.duration or 3
    local kind  = opts.kind or "info"
    local accentCol = (kind == "good" and UI.Theme.Good)
        or (kind == "warn" and UI.Theme.Warn)
        or (kind == "bad" and UI.Theme.Bad)
        or UI.Theme.Accent

    local toast = mk("Frame", {
        Parent = toastHolder,
        Size = UDim2.new(1, 0, 0, 0),
        AutomaticSize = Enum.AutomaticSize.Y,
        BackgroundColor3 = UI.Theme.BgLight,
        BorderSizePixel = 0,
        BackgroundTransparency = 1,
        ZIndex = 51,
    })
    corner(toast, 10)
    stroke(toast, UI.Theme.Stroke, 1, 0.2)
    local accent = mk("Frame", {
        Parent = toast,
        Size = UDim2.new(0, 4, 1, -12),
        Position = UDim2.new(0, 6, 0, 6),
        BackgroundColor3 = accentCol,
        BorderSizePixel = 0,
        ZIndex = 52,
    })
    corner(accent, 2)
    mk("TextLabel", {
        Parent = toast,
        Size = UDim2.new(1, -28, 0, 16),
        Position = UDim2.new(0, 18, 0, 8),
        BackgroundTransparency = 1,
        Text = title,
        Font = Enum.Font.GothamBold,
        TextSize = 12,
        TextColor3 = UI.Theme.Text,
        TextXAlignment = Enum.TextXAlignment.Left,
        ZIndex = 52,
    })
    mk("TextLabel", {
        Parent = toast,
        Size = UDim2.new(1, -28, 0, 0),
        AutomaticSize = Enum.AutomaticSize.Y,
        Position = UDim2.new(0, 18, 0, 24),
        BackgroundTransparency = 1,
        Text = msg,
        Font = Enum.Font.Gotham,
        TextSize = 11,
        TextColor3 = UI.Theme.TextDim,
        TextXAlignment = Enum.TextXAlignment.Left,
        TextWrapped = true,
        ZIndex = 52,
    })
    -- pad bottom
    mk("Frame", {
        Parent = toast,
        Size = UDim2.new(1, 0, 0, 10),
        Position = UDim2.new(0, 0, 1, 0),
        BackgroundTransparency = 1,
    })

    -- slide-in
    toast.Position = UDim2.new(1, 20, 0, 0)
    tween(toast, { BackgroundTransparency = 0, Position = UDim2.new(0, 0, 0, 0) }, 0.3, Enum.EasingStyle.Quint)
    for _, d in ipairs(toast:GetDescendants()) do
        if d:IsA("TextLabel") then
            local fin = d.TextTransparency
            d.TextTransparency = 1
            tween(d, { TextTransparency = fin }, 0.3)
        end
    end

    task.delay(dur, function()
        tween(toast, { BackgroundTransparency = 1, Position = UDim2.new(1, 20, 0, 0) }, 0.25)
        for _, d in ipairs(toast:GetDescendants()) do
            if d:IsA("TextLabel") then tween(d, { TextTransparency = 1 }, 0.25) end
            if d:IsA("UIStroke") then tween(d, { Transparency = 1 }, 0.25) end
        end
        task.delay(0.3, function() pcall(function() toast:Destroy() end) end)
    end)
end


-- ── Window dragging (PC mouse + mobile touch) ─────────────
do
    local dragging = false
    local dragStart, startPos
    header.InputBegan:Connect(function(inp)
        if inp.UserInputType == Enum.UserInputType.MouseButton1
        or inp.UserInputType == Enum.UserInputType.Touch then
            dragging = true
            dragStart = inp.Position
            startPos = window.Position
            inp.Changed:Connect(function()
                if inp.UserInputState == Enum.UserInputState.End then
                    dragging = false
                end
            end)
        end
    end)
    UIS.InputChanged:Connect(function(inp)
        if dragging and (inp.UserInputType == Enum.UserInputType.MouseMovement
        or inp.UserInputType == Enum.UserInputType.Touch) then
            local delta = inp.Position - dragStart
            window.Position = UDim2.new(
                startPos.X.Scale, startPos.X.Offset + delta.X,
                startPos.Y.Scale, startPos.Y.Offset + delta.Y)
        end
    end)
end

-- ── Minimise pill (floating bubble when hidden) ───────────
local minimized = false
local pill = mk("TextButton", {
    Name = "WindPill",
    Parent = screen,
    Size = UDim2.new(0, 54, 0, 54),
    Position = UDim2.new(0, 20, 0.5, -27),
    BackgroundColor3 = UI.Theme.Accent,
    Text = "",
    AutoButtonColor = false,
    BorderSizePixel = 0,
    Visible = false,
    ZIndex = 40,
})
corner(pill, 27)
gradient(pill, UI.Theme.Accent, UI.Theme.Accent2, 45)
stroke(pill, UI.Theme.Stroke, 2, 0.4)
mk("TextLabel", {
    Parent = pill,
    Size = UDim2.new(1, 0, 1, 0),
    BackgroundTransparency = 1,
    Text = "W",
    Font = Enum.Font.GothamBold,
    TextSize = 24,
    TextColor3 = Color3.fromRGB(255, 255, 255),
    ZIndex = 41,
})

local function setMinimized(v)
    minimized = v
    if v then
        tween(window, { Size = UDim2.new(0, 0, 0, 0) }, 0.28, Enum.EasingStyle.Quad, Enum.EasingDirection.In)
        task.delay(0.28, function()
            if minimized then
                window.Visible = false
                pill.Visible = true
                pill.Size = UDim2.new(0, 0, 0, 0)
                pill.Position = UDim2.new(0, 20, 0.5, 0)
                springTween(pill, { Size = UDim2.new(0, 54, 0, 54), Position = UDim2.new(0, 20, 0.5, -27) }, 0.4)
            end
        end)
    else
        pill.Visible = false
        window.Visible = true
        window.Size = UDim2.new(0, 0, 0, 0)
        springTween(window, { Size = UDim2.new(0, winW, 0, winH) }, 0.45)
    end
end
btnMin.MouseButton1Click:Connect(function() setMinimized(true) end)
pill.MouseButton1Click:Connect(function() setMinimized(false) end)

-- pill is draggable too
do
    local dragging, dStart, sPos = false, nil, nil
    pill.InputBegan:Connect(function(inp)
        if inp.UserInputType == Enum.UserInputType.MouseButton1
        or inp.UserInputType == Enum.UserInputType.Touch then
            dragging = true; dStart = inp.Position; sPos = pill.Position
            inp.Changed:Connect(function()
                if inp.UserInputState == Enum.UserInputState.End then dragging = false end
            end)
        end
    end)
    UIS.InputChanged:Connect(function(inp)
        if dragging and (inp.UserInputType == Enum.UserInputType.MouseMovement
        or inp.UserInputType == Enum.UserInputType.Touch) then
            local d = inp.Position - dStart
            pill.Position = UDim2.new(sPos.X.Scale, sPos.X.Offset + d.X, sPos.Y.Scale, sPos.Y.Offset + d.Y)
        end
    end)
end

-- ── Close (with fade) ─────────────────────────────────────
btnClose.MouseButton1Click:Connect(function()
    UI.notify({ title = "WindHub", text = "Shutting down…", kind = "warn", duration = 1.5 })
    tween(window, { Size = UDim2.new(0, 0, 0, 0) }, 0.3, Enum.EasingStyle.Quad, Enum.EasingDirection.In)
    task.delay(0.4, function()
        _G.WindHubActive = false
        pcall(function() screen:Destroy() end)
    end)
end)


-- ============================================================
-- §32  TAB CONTENT  –  Building all 10 tabs
-- ============================================================

-- ── TAB 1: PARRY ──────────────────────────────────────────
local tabParry = UI.addTab("Parry", "⚔")
do
    local p = tabParry.page
    UI.section(p, "Auto Parry")
    local c1 = UI.card(p)
    UI.toggle(c1, {
        text = "Enabled", desc = "Master switch for the auto-parry engine",
        default = Config.autoParry, flag = "autoParry",
        callback = function(v) Config.autoParry = v
            UI.notify({ title = "Auto Parry", text = v and "Engaged" or "Disengaged",
                kind = v and "good" or "warn", duration = 1.5 }) end,
    })
    UI.dropdown(c1, {
        text = "Mode", options = { "Ultra", "Predictive", "Conservative", "RK4", "Fusion" },
        default = Config.parryMode or "Fusion", flag = "parryMode",
        callback = function(v) Config.parryMode = v end,
    })

    UI.section(p, "Timing")
    local c2 = UI.card(p)
    UI.slider(c2, {
        text = "Parry Distance", min = 5, max = 60, default = Config.parryDistance or 22,
        suffix = " st", flag = "parryDistance",
        callback = function(v) Config.parryDistance = v end,
    })
    UI.slider(c2, {
        text = "Reaction Window", min = 0.02, max = 0.35, step = 0.01,
        default = Config.parryWindow or 0.12, suffix = " s", flag = "parryWindow",
        callback = function(v) Config.parryWindow = v end,
    })
    UI.slider(c2, {
        text = "Ping Compensation", min = 0, max = 1, step = 0.05,
        default = Config.pingComp or 0.5, flag = "pingComp",
        callback = function(v) Config.pingComp = v end,
    })
    UI.toggle(c2, {
        text = "Humanized Timing", desc = "Gaussian-jittered delays to look human",
        default = Config.humanized, flag = "humanized",
        callback = function(v) Config.humanized = v end,
    })

    UI.section(p, "Advanced")
    local c3 = UI.card(p)
    UI.toggle(c3, { text = "Predictive Pre-Arm", desc = "Arm via Replion target before the ball turns",
        default = Config.preArm, flag = "preArm", callback = function(v) Config.preArm = v end })
    UI.toggle(c3, { text = "Multi-Ball Priority", desc = "Threat-rank every ball each frame",
        default = Config.multiBall, flag = "multiBall", callback = function(v) Config.multiBall = v end })
    UI.toggle(c3, { text = "Per-Ball Learning", desc = "Adapt window from past successes",
        default = Config.learning, flag = "learning", callback = function(v) Config.learning = v end })
    UI.toggle(c3, { text = "Rollback Guard", desc = "Re-fire if a parry gets rolled back",
        default = Config.rollbackGuard, flag = "rollbackGuard", callback = function(v) Config.rollbackGuard = v end })
    UI.toggle(c3, { text = "Standoff Auto-Switch", desc = "Switch mode during standoff rounds",
        default = Config.standoffSwitch, flag = "standoffSwitch", callback = function(v) Config.standoffSwitch = v end })

    UI.section(p, "Manual Spam")
    local c4 = UI.card(p)
    UI.toggle(c4, { text = "Spam Parry", desc = "Continuously spam the parry key",
        default = false, flag = "spamActive",
        callback = function(v) Config.spamActive = v end })
    UI.slider(c4, { text = "Spam Rate", min = 5, max = 60, default = 15,
        suffix = " Hz", flag = "spamRateHz",
        callback = function(v) Config.spamRate = 1 / math.max(1, v) end })
    UI.toggle(c4, { text = "Burst Mode", desc = "Fire 3 clicks per tick instead of one",
        default = (Config.spamBurst or 1) > 1, flag = "spamBurstOn",
        callback = function(v) Config.spamBurst = v and 3 or 1 end })

    UI.section(p, "Fixes")
    local c5 = UI.card(p)
    UI.toggle(c5, { text = "Animation Fix", desc = "Hook parry animations so they always show",
        default = Config.animFix, flag = "animFix", callback = function(v) Config.animFix = v end })
end


-- ── TAB 2: VISUALS ────────────────────────────────────────
local tabVisuals = UI.addTab("Visuals", "◉")
do
    local p = tabVisuals.page
    UI.section(p, "Ball ESP")
    local c1 = UI.card(p)
    UI.toggle(c1, { text = "Ball ESP", desc = "Highlight every ball with ETA bar",
        default = Config.ballESP, flag = "ballESP", callback = function(v) Config.ballESP = v end })
    UI.toggle(c1, { text = "Ball Tracers", desc = "Draw a line from you to each ball",
        default = Config.ballTracers, flag = "ballTracers", callback = function(v) Config.ballTracers = v end })
    UI.toggle(c1, { text = "ETA Billboard", desc = "Floating ETA readout above the ball",
        default = Config.etaBillboard, flag = "etaBillboard", callback = function(v) Config.etaBillboard = v end })

    UI.section(p, "Arc Prediction")
    local c2 = UI.card(p)
    UI.toggle(c2, { text = "Arc ESP", desc = "Show predicted ball flight path",
        default = Config.arcESP, flag = "arcESP", callback = function(v) Config.arcESP = v end })
    UI.toggle(c2, { text = "Impact Disk", desc = "Mark the predicted impact point",
        default = Config.impactDisk, flag = "impactDisk", callback = function(v) Config.impactDisk = v end })
    UI.slider(c2, { text = "Arc Resolution", min = 4, max = 48, default = Config.arcResolution or 18,
        suffix = " pts", flag = "arcResolution", callback = function(v) Config.arcResolution = v end })

    UI.section(p, "Player ESP")
    local c3 = UI.card(p)
    UI.toggle(c3, { text = "Player ESP", desc = "Boxes + names on every player",
        default = Config.playerESP, flag = "playerESP", callback = function(v) Config.playerESP = v end })
    UI.toggle(c3, { text = "Health Bars", default = Config.healthBars, flag = "healthBars",
        callback = function(v) Config.healthBars = v end })
    UI.toggle(c3, { text = "Chams", desc = "See players through walls",
        default = Config.chams, flag = "chams", callback = function(v) Config.chams = v end })
    UI.toggle(c3, { text = "Show Distance", default = Config.showDistance, flag = "showDistance",
        callback = function(v) Config.showDistance = v end })

    UI.section(p, "Minimap & Zones")
    local c4 = UI.card(p)
    UI.toggle(c4, { text = "Minimap", desc = "2D top-down radar",
        default = Config.minimap, flag = "minimap", callback = function(v) Config.minimap = v end })
    UI.toggle(c4, { text = "Danger Zone", desc = "Neon disk at predicted impact",
        default = Config.dangerZone, flag = "dangerZone", callback = function(v) Config.dangerZone = v end })
    UI.toggle(c4, { text = "Screen Alerts", desc = "Full-screen warning text",
        default = Config.screenAlerts, flag = "screenAlerts", callback = function(v) Config.screenAlerts = v end })
    UI.slider(c4, { text = "Minimap Range", min = 50, max = 500, default = Config.minimapRange or 200,
        suffix = " st", flag = "minimapRange", callback = function(v) Config.minimapRange = v end })

    UI.section(p, "Colors")
    local c5 = UI.card(p)
    UI.dropdown(c5, { text = "ESP Theme", options = { "Blue", "Purple", "Green", "Red", "Rainbow" },
        default = Config.espTheme or "Blue", flag = "espTheme",
        callback = function(v) Config.espTheme = v end })
end

-- ── TAB 3: COMBAT ─────────────────────────────────────────
local tabCombat = UI.addTab("Combat", "✦")
do
    local p = tabCombat.page
    UI.section(p, "Auto Dodge")
    local c1 = UI.card(p)
    UI.toggle(c1, { text = "Auto Dodge", desc = "Side-step incoming balls automatically",
        default = Config.autoDodge, flag = "autoDodge", callback = function(v) Config.autoDodge = v end })
    UI.dropdown(c1, { text = "Dodge Pattern", options = { "Perpendicular", "Backward", "Random", "Strafe" },
        default = Config.dodgePattern or "Perpendicular", flag = "dodgePattern",
        callback = function(v) Config.dodgePattern = v end })
    UI.slider(c1, { text = "Dodge Distance", min = 3, max = 30, default = Config.dodgeDistance or 12,
        suffix = " st", flag = "dodgeDistance", callback = function(v) Config.dodgeDistance = v end })

    UI.section(p, "Hitbox")
    local c2 = UI.card(p)
    UI.toggle(c2, { text = "Hitbox Expander", desc = "Grow your parry hitbox",
        default = Config.hitboxExpand, flag = "hitboxExpand", callback = function(v) Config.hitboxExpand = v end })
    UI.slider(c2, { text = "Hitbox Size", min = 1, max = 25, default = 8,
        suffix = " st", flag = "hitboxScalar",
        callback = function(v) Config.hitboxScalar = v; Config.hitboxSize = Vector3.new(v, v, v) end })

    UI.section(p, "Movement")
    local c3 = UI.card(p)
    UI.toggle(c3, { text = "Anti-Knockback", desc = "Resist ball knockback",
        default = Config.antiKnockback, flag = "antiKnockback", callback = function(v) Config.antiKnockback = v end })
    UI.toggle(c3, { text = "No movement break", desc = "Parrying never interrupts walking",
        default = Config.noMoveBreak ~= false, flag = "noMoveBreak", callback = function(v) Config.noMoveBreak = v end })

    UI.section(p, "Combo Tracker")
    local c4 = UI.card(p)
    UI.toggle(c4, { text = "Track Combos", default = Config.comboTrack ~= false, flag = "comboTrack",
        callback = function(v) Config.comboTrack = v end })
    UI.toggle(c4, { text = "Kill Feed", default = Config.killFeed, flag = "killFeed",
        callback = function(v) Config.killFeed = v end })
end


-- ── TAB 4: REMOTE SPY ─────────────────────────────────────
local tabSpy = UI.addTab("Remote Spy", "⟳")
do
    local p = tabSpy.page
    UI.section(p, "Remote Spy v2")
    local c1 = UI.card(p)
    UI.toggle(c1, { text = "Enable Spy", desc = "Log every RemoteEvent / Function call",
        default = Config.remoteSpy, flag = "remoteSpy", callback = function(v) Config.remoteSpy = v end })
    UI.toggle(c1, { text = "Log Args", desc = "Capture call arguments",
        default = Config.spyArgs, flag = "spyArgs", callback = function(v) Config.spyArgs = v end })
    UI.toggle(c1, { text = "Block Mode", desc = "Drop selected remotes",
        default = Config.spyBlock, flag = "spyBlock", callback = function(v) Config.spyBlock = v end })

    UI.section(p, "Live Log")
    local logCard = UI.card(p)
    local logBox = mk("TextLabel", {
        Parent = logCard,
        Size = UDim2.new(1, 0, 0, 200),
        BackgroundTransparency = 1,
        Text = "Waiting for remote calls…",
        Font = Enum.Font.Code,
        TextSize = 10,
        TextColor3 = UI.Theme.TextDim,
        TextXAlignment = Enum.TextXAlignment.Left,
        TextYAlignment = Enum.TextYAlignment.Top,
        TextWrapped = true,
    })
    UI._spyLogBox = logBox

    UI.button(p, { text = "Clear Log", callback = function()
        if RemoteSpy and RemoteSpy.clear then RemoteSpy.clear() end
        logBox.Text = "Cleared."
    end })
    UI.button(p, { text = "Copy Log", callback = function()
        if setclipboard then pcall(setclipboard, logBox.Text)
            UI.notify({ title = "Remote Spy", text = "Log copied to clipboard", kind = "good" }) end
    end })
end

-- ── TAB 5: MEMORY ─────────────────────────────────────────
local tabMem = UI.addTab("Memory", "▤")
do
    local p = tabMem.page
    UI.section(p, "Memory Reader")
    local c1 = UI.card(p)
    UI.toggle(c1, { text = "Raw Memory Read", desc = "Read ball position/velocity from heap",
        default = Config.rawMemory, flag = "rawMemory", callback = function(v) Config.rawMemory = v end })
    UI.toggle(c1, { text = "GC Heap Scan", desc = "Walk getgc(true) for fast ball discovery",
        default = Config.gcScan ~= false, flag = "gcScan", callback = function(v) Config.gcScan = v end })
    UI.toggle(c1, { text = "Nil-Instance Pre-arm", desc = "Pre-arm via getnilinstances()",
        default = Config.nilScan, flag = "nilScan", callback = function(v) Config.nilScan = v end })
    UI.toggle(c1, { text = "Signature Scanner", desc = "Byte-pattern scan for ball markers",
        default = Config.sigScan, flag = "sigScan", callback = function(v) Config.sigScan = v end })

    UI.section(p, "Calibration")
    local c2 = UI.card(p)
    local calLabel = UI.label(c2, { text = "Offset: not calibrated", color = UI.Theme.TextDim })
    UI._memCalLabel = calLabel
    UI.button(c2, { text = "Re-Calibrate Now", callback = function()
        if MemScanner and MemScanner._calibrate then
            local ok = MemScanner._calibrate()
            UI.notify({ title = "Memory", text = ok and "Calibration successful" or "Calibration failed",
                kind = ok and "good" or "bad" })
        end
    end })

    UI.section(p, "Diagnostics")
    local diag = UI.card(p)
    local grid = mk("Frame", { Parent = diag, Size = UDim2.new(1, 0, 0, 120), BackgroundTransparency = 1 })
    mk("UIGridLayout", { Parent = grid, CellSize = UDim2.new(0.5, -4, 0, 56),
        CellPadding = UDim2.new(0, 8, 0, 8), SortOrder = Enum.SortOrder.LayoutOrder })
    UI._memTileAddr  = UI.statTile(grid, { label = "CACHED ADDRS", value = "0" })
    UI._memTileScans = UI.statTile(grid, { label = "GC SCANS", value = "0" })
    UI._memTileBalls = UI.statTile(grid, { label = "TRACKED BALLS", value = "0" })
    UI._memTileDrift = UI.statTile(grid, { label = "DRIFT", value = "0.0", color = UI.Theme.Good })
end


-- ── TAB 6: ANALYTICS ──────────────────────────────────────
local tabAnalytics = UI.addTab("Analytics", "▦")
do
    local p = tabAnalytics.page
    UI.section(p, "Parry Accuracy")
    local card = UI.card(p)
    local grid = mk("Frame", { Parent = card, Size = UDim2.new(1, 0, 0, 120), BackgroundTransparency = 1 })
    mk("UIGridLayout", { Parent = grid, CellSize = UDim2.new(0.5, -4, 0, 56),
        CellPadding = UDim2.new(0, 8, 0, 8) })
    UI._anHits   = UI.statTile(grid, { label = "SUCCESSFUL", value = "0", color = UI.Theme.Good })
    UI._anMiss   = UI.statTile(grid, { label = "MISSED", value = "0", color = UI.Theme.Bad })
    UI._anAcc    = UI.statTile(grid, { label = "ACCURACY", value = "--%", color = UI.Theme.Accent })
    UI._anAvgEta = UI.statTile(grid, { label = "AVG ETA", value = "-- ms" })

    UI.section(p, "Ball Signatures")
    local c2 = UI.card(p)
    local sigBox = UI.label(c2, { text = "No ball signatures recorded yet.", wrap = true,
        color = UI.Theme.TextDim, height = 80 })
    UI._anSigBox = sigBox

    UI.section(p, "Target Prediction")
    local c3 = UI.card(p)
    UI._anPredBox = UI.label(c3, { text = "Predictor idle.", wrap = true, color = UI.Theme.TextDim })

    UI.button(p, { text = "Reset Analytics", danger = true, callback = function()
        if AccuracyTracker and AccuracyTracker.reset then AccuracyTracker.reset() end
        UI.notify({ title = "Analytics", text = "All counters reset", kind = "warn" })
    end })
end

-- ── TAB 7: STATS ──────────────────────────────────────────
local tabStats = UI.addTab("Stats", "⚡")
do
    local p = tabStats.page
    UI.section(p, "Performance")
    local card = UI.card(p)
    local grid = mk("Frame", { Parent = card, Size = UDim2.new(1, 0, 0, 120), BackgroundTransparency = 1 })
    mk("UIGridLayout", { Parent = grid, CellSize = UDim2.new(0.5, -4, 0, 56),
        CellPadding = UDim2.new(0, 8, 0, 8) })
    UI._stFps   = UI.statTile(grid, { label = "FPS", value = "--", color = UI.Theme.Good })
    UI._stFrame = UI.statTile(grid, { label = "FRAME MS", value = "--" })
    UI._stPing  = UI.statTile(grid, { label = "PING", value = "-- ms", color = UI.Theme.Warn })
    UI._stMem   = UI.statTile(grid, { label = "LUA MEM", value = "-- MB" })

    UI.section(p, "Server")
    local c2 = UI.card(p)
    local grid2 = mk("Frame", { Parent = c2, Size = UDim2.new(1, 0, 0, 120), BackgroundTransparency = 1 })
    mk("UIGridLayout", { Parent = grid2, CellSize = UDim2.new(0.5, -4, 0, 56),
        CellPadding = UDim2.new(0, 8, 0, 8) })
    UI._stTick   = UI.statTile(grid2, { label = "TICK RATE", value = "-- Hz" })
    UI._stStable = UI.statTile(grid2, { label = "STABILITY", value = "--%", color = UI.Theme.Good })
    UI._stPlayers= UI.statTile(grid2, { label = "PLAYERS", value = "0" })
    UI._stBalls  = UI.statTile(grid2, { label = "ACTIVE BALLS", value = "0" })

    UI.section(p, "Session")
    local c3 = UI.card(p)
    UI._stUptime  = UI.label(c3, { text = "Uptime: 0s", color = UI.Theme.TextDim })
    UI._stParries = UI.label(c3, { text = "Total parries: 0", color = UI.Theme.TextDim })
    UI._stCombo   = UI.label(c3, { text = "Best combo: 0", color = UI.Theme.TextDim })
end


-- ── TAB 8: AUDIO ──────────────────────────────────────────
local tabAudio = UI.addTab("Audio", "♪")
do
    local p = tabAudio.page
    UI.section(p, "Audio Cues")
    local c1 = UI.card(p)
    UI.toggle(c1, { text = "Sound Effects", desc = "Play cues on parry / hit / combo",
        default = Config.audio, flag = "audio", callback = function(v) Config.audio = v end })
    UI.toggle(c1, { text = "Parry Ping", desc = "Beep when a parry fires",
        default = Config.audioParry ~= false, flag = "audioParry", callback = function(v) Config.audioParry = v end })
    UI.toggle(c1, { text = "Danger Alarm", desc = "Alarm when a ball is close & fast",
        default = Config.audioDanger, flag = "audioDanger", callback = function(v) Config.audioDanger = v end })
    UI.toggle(c1, { text = "Combo Chime", desc = "Chime on a new best combo",
        default = Config.audioCombo, flag = "audioCombo", callback = function(v) Config.audioCombo = v end })

    UI.section(p, "Mix")
    local c2 = UI.card(p)
    UI.slider(c2, { text = "Volume", min = 0, max = 1, step = 0.05, default = Config.audioVolume or 0.5,
        flag = "audioVolume", callback = function(v) Config.audioVolume = v end })
    UI.slider(c2, { text = "Pitch Variance", min = 0, max = 0.5, step = 0.01, default = Config.audioPitchVar or 0.1,
        flag = "audioPitchVar", callback = function(v) Config.audioPitchVar = v end })

    UI.button(p, { text = "Test Sound", callback = function()
        if Audio and Audio.play then Audio.play("parry") end
    end })
end

-- ── TAB 9: PROFILES ───────────────────────────────────────
local tabProfiles = UI.addTab("Profiles", "❖")
do
    local p = tabProfiles.page
    UI.section(p, "Presets")
    local c1 = UI.card(p)
    UI.dropdown(c1, { text = "Load Preset",
        options = { "Aggressive", "Safe", "Competitive", "Tryhard" },
        default = "Competitive",
        callback = function(v)
            if ProfileManager and ProfileManager.loadPreset then
                ProfileManager:loadPreset(v)
                -- refresh widgets from config
                for flag, refresh in pairs(UI._registry) do
                    local cv = Config[flag]
                    if cv ~= nil then pcall(refresh, cv) end
                end
                UI.notify({ title = "Profiles", text = v .. " preset loaded", kind = "good" })
            end
        end })

    UI.section(p, "Saved Profiles")
    local c2 = UI.card(p)
    local nameRow = mk("Frame", { Parent = c2, Size = UDim2.new(1, 0, 0, 34), BackgroundTransparency = 1 })
    local nameBox = mk("TextBox", {
        Parent = nameRow,
        Size = UDim2.new(1, -90, 1, 0),
        BackgroundColor3 = UI.Theme.BgLight,
        Text = "",
        PlaceholderText = "Profile name…",
        Font = Enum.Font.GothamMedium,
        TextSize = 12,
        TextColor3 = UI.Theme.Text,
        PlaceholderColor3 = UI.Theme.TextFaint,
        BorderSizePixel = 0,
        ClearTextOnFocus = false,
    })
    corner(nameBox, 8)
    stroke(nameBox, UI.Theme.Stroke, 1)
    mk("UIPadding", { Parent = nameBox, PaddingLeft = UDim.new(0, 10) })
    local saveBtn = mk("TextButton", {
        Parent = nameRow,
        Size = UDim2.new(0, 80, 1, 0),
        Position = UDim2.new(1, -80, 0, 0),
        BackgroundColor3 = UI.Theme.Accent,
        Text = "Save",
        Font = Enum.Font.GothamSemibold,
        TextSize = 12,
        TextColor3 = Color3.fromRGB(255, 255, 255),
        BorderSizePixel = 0,
        AutoButtonColor = false,
    })
    corner(saveBtn, 8)

    local listHolder = mk("Frame", { Parent = c2, Size = UDim2.new(1, 0, 0, 0),
        AutomaticSize = Enum.AutomaticSize.Y, BackgroundTransparency = 1 })
    mk("UIListLayout", { Parent = listHolder, Padding = UDim.new(0, 4) })

    local function refreshList()
        for _, ch in ipairs(listHolder:GetChildren()) do
            if ch:IsA("Frame") then ch:Destroy() end
        end
        if not (ProfileManager and ProfileManager.list) then return end
        for _, pname in ipairs(ProfileManager:list()) do
            local prow = mk("Frame", { Parent = listHolder, Size = UDim2.new(1, 0, 0, 30),
                BackgroundColor3 = UI.Theme.BgLight, BorderSizePixel = 0 })
            corner(prow, 7)
            mk("TextLabel", { Parent = prow, Size = UDim2.new(1, -120, 1, 0),
                Position = UDim2.new(0, 10, 0, 0), BackgroundTransparency = 1, Text = pname,
                Font = Enum.Font.GothamMedium, TextSize = 12, TextColor3 = UI.Theme.Text,
                TextXAlignment = Enum.TextXAlignment.Left })
            local lb = mk("TextButton", { Parent = prow, Size = UDim2.new(0, 50, 0, 22),
                Position = UDim2.new(1, -110, 0.5, -11), BackgroundColor3 = UI.Theme.AccentDim,
                Text = "Load", Font = Enum.Font.GothamSemibold, TextSize = 11,
                TextColor3 = Color3.fromRGB(255,255,255), BorderSizePixel = 0, AutoButtonColor = false })
            corner(lb, 6)
            local db = mk("TextButton", { Parent = prow, Size = UDim2.new(0, 50, 0, 22),
                Position = UDim2.new(1, -55, 0.5, -11), BackgroundColor3 = UI.Theme.Bad,
                Text = "Del", Font = Enum.Font.GothamSemibold, TextSize = 11,
                TextColor3 = Color3.fromRGB(255,255,255), BorderSizePixel = 0, AutoButtonColor = false })
            corner(db, 6)
            lb.MouseButton1Click:Connect(function()
                ProfileManager:load(pname)
                for flag, refresh in pairs(UI._registry) do
                    local cv = Config[flag]; if cv ~= nil then pcall(refresh, cv) end
                end
                UI.notify({ title = "Profiles", text = pname .. " loaded", kind = "good" })
            end)
            db.MouseButton1Click:Connect(function()
                ProfileManager:delete(pname); refreshList()
                UI.notify({ title = "Profiles", text = pname .. " deleted", kind = "warn" })
            end)
        end
    end
    UI._refreshProfiles = refreshList

    saveBtn.MouseButton1Click:Connect(function()
        local nm = nameBox.Text
        if nm and #nm > 0 and ProfileManager and ProfileManager.save then
            ProfileManager:save(nm); nameBox.Text = ""; refreshList()
            UI.notify({ title = "Profiles", text = nm .. " saved", kind = "good" })
        end
    end)
    refreshList()
end


-- ── TAB 10: CONFIG ────────────────────────────────────────
local tabConfig = UI.addTab("Config", "⚙")
do
    local p = tabConfig.page
    UI.section(p, "Interface")
    local c1 = UI.card(p)
    UI.toggle(c1, { text = "Notifications", desc = "Show toast popups",
        default = Config.notifications ~= false, flag = "notifications",
        callback = function(v) Config.notifications = v end })
    UI.toggle(c1, { text = "Status Bar", desc = "Live readout at the bottom",
        default = Config.statusBar ~= false, flag = "statusBar",
        callback = function(v) Config.statusBar = v; statusBar.Visible = v end })
    UI.slider(c1, { text = "UI Scale", min = 0.7, max = 1.4, step = 0.05, default = Config.uiScale or 1,
        flag = "uiScale", callback = function(v)
            Config.uiScale = v
            local s = window:FindFirstChildOfClass("UIScale") or mk("UIScale", { Parent = window })
            s.Scale = v
        end })

    UI.section(p, "Hotkeys")
    local c2 = UI.card(p)
    UI.keybind(c2, { text = "Toggle UI", default = Enum.KeyCode.RightShift,
        callback = function(k) Config.toggleKey = k.Name end })
    UI.keybind(c2, { text = "Panic (kill all)", default = Enum.KeyCode.End,
        callback = function(k) Config.panicKey = k.Name end })
    UI.keybind(c2, { text = "Toggle Parry", default = Enum.KeyCode.P,
        callback = function(k) Config.parryKey = k.Name end })

    UI.section(p, "Anti-Detection")
    local c3 = UI.card(p)
    UI.toggle(c3, { text = "Anti-Detection", desc = "Randomize timing/positions to evade flags",
        default = Config.antiDetect ~= false, flag = "antiDetect",
        callback = function(v) Config.antiDetect = v end })
    UI.toggle(c3, { text = "Rate Limiter", desc = "Cap parries per second",
        default = Config.rateLimit ~= false, flag = "rateLimit",
        callback = function(v) Config.rateLimit = v end })
    UI.slider(c3, { text = "Max Parries/sec", min = 5, max = 40, default = Config.maxParryRate or 18,
        suffix = " Hz", flag = "maxParryRate", callback = function(v) Config.maxParryRate = v end })

    UI.section(p, "Config File")
    local c4 = UI.card(p)
    UI.button(c4, { text = "Save Config to File", callback = function()
        if writefile then
            local ok = pcall(function()
                local data = {}
                for k, v in pairs(Config.snapshot()) do
                    if type(v) ~= "table" and type(v) ~= "function" then data[k] = v end
                end
                writefile("WindHub_config.json", HttpService and HttpService:JSONEncode(data) or tostring(data))
            end)
            UI.notify({ title = "Config", text = ok and "Saved to WindHub_config.json" or "Save failed",
                kind = ok and "good" or "bad" })
        else
            UI.notify({ title = "Config", text = "writefile not supported", kind = "bad" })
        end
    end })
    UI.button(c4, { text = "Reset to Defaults", danger = true, callback = function()
        if Config.reset then Config.reset() end
        for flag, refresh in pairs(UI._registry) do
            local cv = Config[flag]; if cv ~= nil then pcall(refresh, cv) end
        end
        UI.notify({ title = "Config", text = "Reset to defaults", kind = "warn" })
    end })

    UI.section(p, "About")
    local c5 = UI.card(p)
    UI.label(c5, { text = "WindHub v6.0 — The #1 Blade Ball script.", color = UI.Theme.Text,
        font = Enum.Font.GothamSemibold, size = 13 })
    UI.label(c5, { text = "Executor: " .. execName .. (isMobile and " (Mobile)" or " (PC)"),
        color = UI.Theme.TextDim, wrap = true })
    UI.label(c5, { text = "Memory reader · 5-mode auto-parry · full ESP suite · analytics.",
        color = UI.Theme.TextFaint, wrap = true })
end

-- activate first tab
if UI._tabs[1] then UI._tabs[1].activate() end


-- ============================================================
-- §33  OPEN ANIMATION + PC HOTKEYS
-- ============================================================
-- Spring-bounce the window open from zero size.
window.Visible = true
springTween(window, { Size = UDim2.new(0, winW, 0, winH) }, 0.5)

-- ── PC keyboard hotkeys ───────────────────────────────────
local function keyMatches(input, name)
    return input.KeyCode == Enum.KeyCode[name]
end
UIS.InputBegan:Connect(function(input, gpe)
    if gpe then return end
    if input.UserInputType ~= Enum.UserInputType.Keyboard then return end
    -- Toggle UI
    if Config.toggleKey and pcall(function() return Enum.KeyCode[Config.toggleKey] end)
    and input.KeyCode == Enum.KeyCode[Config.toggleKey] then
        setMinimized(not minimized)
    -- Toggle auto-parry
    elseif Config.parryKey and input.KeyCode == Enum.KeyCode[Config.parryKey] then
        Config.autoParry = not Config.autoParry
        if UI._registry.autoParry then UI._registry.autoParry(Config.autoParry) end
        UI.notify({ title = "Auto Parry", text = Config.autoParry and "ON" or "OFF",
            kind = Config.autoParry and "good" or "warn", duration = 1.2 })
    -- Panic: disable everything
    elseif Config.panicKey and input.KeyCode == Enum.KeyCode[Config.panicKey] then
        Config.autoParry  = false
        Config.autoDodge  = false
        Config.manualSpam = false
        Config.espBalls   = false
        Config.espPlayers = false
        UI.notify({ title = "PANIC", text = "All features disabled", kind = "bad", duration = 2 })
    end
end)

-- ============================================================
-- §34  UI UPDATER  –  live stats refresh loop (4 Hz)
-- ============================================================
local function safeSet(tile, v)
    if tile and tile.set then pcall(tile.set, v) end
end
local function fmtMs(s)
    if s == math.huge or s ~= s then return "-- ms" end
    return string.format("%d ms", math.floor(s * 1000 + 0.5))
end

task.spawn(function()
    while _G.WindHubActive and screen.Parent do
        local ok = pcall(function()
            local tr = _G._WindTracker
            -- Status bar
            local best, bestEta = nil, math.huge
            if tr then best, bestEta = tr:bestThreat() end
            if Config.statusBar then
                if best and bestEta < math.huge then
                    UI.statusLeft.Text = string.format("● Threat  ·  ETA %s", fmtMs(bestEta))
                    UI.statusLeft.TextColor3 = UI.Theme.Bad
                elseif Config.autoParry then
                    UI.statusLeft.Text = "● Armed"
                    UI.statusLeft.TextColor3 = UI.Theme.Good
                else
                    UI.statusLeft.Text = "● Idle"
                    UI.statusLeft.TextColor3 = UI.Theme.TextDim
                end
                UI.statusRight.Text = string.format("FPS %d · Parries %d",
                    math.floor(Prof:fps() + 0.5), _G.WindHub_ParryCount or 0)
            end

            -- Stats tab tiles
            safeSet(UI._stFps,   math.floor(Prof:fps() + 0.5))
            safeSet(UI._stFrame, string.format("%.1f", Prof:frameMs()))
            safeSet(UI._stPing,  string.format("%d ms", math.floor((PingComp.pingMs or 0) + 0.5)))
            safeSet(UI._stMem,   string.format("%.1f MB", (Prof:memKB() or 0) / 1024))
            if ServerAnalysis then
                safeSet(UI._stTick,   string.format("%.0f Hz", ServerAnalysis.tickRateEMA or 60))
                safeSet(UI._stStable, string.format("%d%%", math.floor((ServerAnalysis.stability or 1) * 100)))
            end
            safeSet(UI._stPlayers, #Plrs:GetPlayers())
            if tr then safeSet(UI._stBalls, tr:ballCount()) end
            local up = os.clock() - (_G.WindHub_SessionStart or os.clock())
            if UI._stUptime  then UI._stUptime.Text  = string.format("Uptime: %dm %ds", math.floor(up/60), math.floor(up%60)) end
            if UI._stParries then UI._stParries.Text = "Total parries: " .. (_G.WindHub_ParryCount or 0) end
            if UI._stCombo and ComboTracker then UI._stCombo.Text = "Best combo: " .. (ComboTracker.best or 0) end

            -- Analytics tab
            if AccuracyTracker then
                local hits, miss = AccuracyTracker:counts()
                safeSet(UI._anHits, hits)
                safeSet(UI._anMiss, miss)
                safeSet(UI._anAcc, string.format("%d%%", math.floor(AccuracyTracker:rate() * 100)))
            end
            if tr then safeSet(UI._anAvgEta, fmtMs(tr:avgETA())) end

            -- Memory tab
            if MemScanner then
                local addrCount = 0
                for _ in pairs(MemScanner._addrCache or {}) do addrCount = addrCount + 1 end
                safeSet(UI._memTileAddr,  addrCount)
                safeSet(UI._memTileScans, MemScanner.scannedGC or 0)
                if tr then safeSet(UI._memTileBalls, tr:ballCount()) end
                if UI._memCalLabel then
                    UI._memCalLabel.Text = MemScanner.calibrated
                        and string.format("Offset: 0x%X (calibrated)", MemScanner._posOffset or 0)
                        or  "Offset: not calibrated"
                    UI._memCalLabel.TextColor3 = MemScanner.calibrated and UI.Theme.Good or UI.Theme.TextDim
                end
            end

            -- Remote spy log
            if UI._spyLogBox and RemoteSpy then
                UI._spyLogBox.Text = RemoteSpy.format(18)
            end
        end)
        if not ok then end
        task.wait(0.25)
    end
end)


-- ============================================================
-- §35  INITIALISATION
-- ============================================================
local tracker = BallTracker.new()
_G._WindTracker = tracker

-- Wire combo tracker to successful parries (single connection)
tracker.onParry:Connect(function(ball, eta)
    if Config.comboTrack then
        ComboTracker:onParry()
    end
end)

-- Start the three-tier memory scanner
pcall(function() MemScanner.init(tracker) end)
MemScanner.onBallFound(function(ball)
    if ball and ball.Parent then tracker:track(ball) end
end)

-- Track any balls already present + watch the Balls folder
local function scanExistingBalls()
    local found = 0
    for _, obj in ipairs(WS:GetDescendants()) do
        if _isBall and _isBall(obj) then
            tracker:track(obj); found = found + 1
        end
    end
    return found
end

local function connectBallFolder(folder)
    if not folder then return end
    for _, b in ipairs(folder:GetChildren()) do
        if _isBall and _isBall(b) then tracker:track(b) end
    end
    folder.ChildAdded:Connect(function(b)
        task.wait()  -- let attributes replicate
        if _isBall and _isBall(b) then tracker:track(b) end
    end)
end

task.spawn(function()
    scanExistingBalls()
    local ballsFolder = WS:FindFirstChild("Balls")
    if ballsFolder then connectBallFolder(ballsFolder) end
    WS.ChildAdded:Connect(function(c)
        if c.Name == "Balls" then connectBallFolder(c) end
    end)
end)

-- Untrack balls as they leave the world
WS.DescendantRemoving:Connect(function(obj)
    if tracker.states[obj] then
        tracker:untrack(obj)
        BallESP.clean(obj)
        ArcESP.clean(obj)
        DangerZone.clean(obj)
    end
end)


-- ============================================================
-- §36  MAIN LOOP  (RS.PreSimulation – frame-precise)
-- ============================================================
RS.PreSimulation:Connect(function()
    if not _G.WindHubActive then return end

    -- 1) flush any queued parry inputs scheduled for this frame
    _flushInputQueue()

    -- 2) profiler tick
    Prof:tick()

    local now  = os.clock()
    local char = lp.Character
    local hrp  = char and char:FindFirstChild("HumanoidRootPart")
    if not hrp then return end

    -- 3) recompute every ball's ETA + rebuild the priority queue
    local okFrame = pcall(function() tracker:updateFrame(hrp, now) end)
    if not okFrame then return end

    -- 4) auto-parry decision on the highest-priority threat
    local best, bestEta = tracker:bestThreat()
    if best then
        local state = tracker.states[best]
        if state then
            local window = PingComp:effectiveWindow()

            -- danger alarm + screen alert when a fast ball is very close
            if state.threat and bestEta < window * 0.6 then
                if Config.audioDanger and Audio then pcall(Audio.play, "threat") end
                if Config.screenAlerts then
                    pcall(function() screenAlert("⚠ INCOMING", Color3.fromRGB(255,80,80), 0.4) end)
                end
            end

            if Config.autoParry and not state.fired then
                local fire = shouldFire(state, state, window)
                if fire and AntiDetect:canParry() then
                    -- mark fired (auto-emits onParried → counts, accuracy, combo)
                    state.fired = true
                    AntiDetect:recordParry()
                    -- adapt the reaction window from this ball's physics
                    pcall(function()
                        tracker.window = state.physics:adaptWindow(tracker.window, bestEta)
                        if Config.learning then Config.parryWindow = tracker.window end
                    end)
                    -- fire the actual input on this frame (or queued)
                    scheduleInput(clickParry, 0)
                end
            end

            -- 5) auto-dodge (independent of parry)
            if Config.autoDodge and state.threat and bestEta < window * 1.2 then
                local bPos = MemScanner.rawPos(best) or best.Position
                local vp   = best:FindFirstChild("zoomies")
                local bVel = (vp and (MemScanner.rawVel(best) or vp.VectorVelocity)) or Vector3.zero
                pcall(function() Dodge.attempt(hrp, bPos, bVel) end)
            end
        end
    end

    -- 6) per-ball visuals
    if Config.espBalls or Config.predArc or Config.dangerZone then
        for ball, state in pairs(tracker.states) do
            if ball and ball.Parent then
                if Config.espBalls   then pcall(BallESP.update, ball, state) end
                if Config.predArc    then pcall(ArcESP.update, ball, state) end
                if Config.dangerZone then pcall(DangerZone.update, ball, state) end
            end
        end
    end
end)

-- ── Slower visual loop (player ESP + minimap) at ~30 Hz ───
task.spawn(function()
    while _G.WindHubActive do
        pcall(function()
            if Config.espPlayers or Config.espChams then PlayerESP.update() end
            if Config.espMinimap then _updateMinimap(tracker) end
        end)
        task.wait(1/30)
    end
end)


-- ============================================================
-- §37  STARTUP NOTIFICATIONS
-- ============================================================
task.spawn(function()
    task.wait(0.6)
    UI.notify({
        title = "WindHub v6.0",
        text  = "Loaded on " .. execName .. (isMobile and " (Mobile)" or " (PC)"),
        kind  = "good", duration = 4,
    })
    task.wait(0.5)
    local capStr = {}
    if EX.rpm  then table.insert(capStr, "raw-mem") end
    if EX.hook then table.insert(capStr, "namecall") end
    if EX.gc   then table.insert(capStr, "gc-scan") end
    UI.notify({
        title = "Engine",
        text  = "Auto-parry armed · " .. (#capStr > 0 and table.concat(capStr, " · ") or "standard mode"),
        kind  = "info", duration = 4,
    })
    task.wait(0.4)
    if not MemScanner.calibrated then
        task.wait(2)
        if MemScanner.calibrated then
            UI.notify({ title = "Memory", text = "Raw-memory reader calibrated", kind = "good", duration = 3 })
        end
    end
end)

-- Re-arm hitbox on existing character
if lp.Character and Config.hitboxExpand then
    pcall(function() HitboxExpand.apply(lp.Character) end)
end

-- Final ready flag
_G.WindHub_Ready = true
print("[WindHub] v6.0 fully loaded — executor: " .. execName .. (isMobile and " (Mobile)" or " (PC)"))

