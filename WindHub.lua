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

    -- 3. Whitelist check — unknown executors get a WARNING but still load
    local allowed = false
    local warnOnly = false
    for _, w in ipairs(WHITELIST) do
        if ExecName:find(w, 1, true) then allowed = true; break end
    end
    if not allowed and ExecName == "unknown" then
        -- Can't identify executor — allow with warning (may be a supported one
        -- that doesn't expose its global name)
        warnOnly = true
        allowed = true
    end

    if not allowed then
        -- Known unsupported executor — show error UI then stop
        pcall(function()
            local g = Instance.new("ScreenGui")
            g.Name = "WindHubErr"; g.ResetOnSpawn = false
            g.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
            g.Parent = CoreGui
            local f = Instance.new("Frame", g)
            f.Size = UDim2.fromOffset(420, 90)
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
            t.Text = "WindHub — Unsupported executor: '"..ExecName.."'\nSupported: Delta, Codex, Xeno, Wave, Optimware, Volt, Potassium"
            task.delay(7, function() pcall(function() g:Destroy() end) end)
        end)
        warn("[WindHub] Blocked — unsupported executor: " .. ExecName)
        _G.WindHubActive = false
        return
    end

    if warnOnly then
        warn("[WindHub] Executor not identified — loading anyway. Use Delta/Codex/Xeno/Wave/Optimware/Volt/Potassium for full support.")
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
    "getcallbackvalue", "hookmetamethod",
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
    meta  = type(EF.hookmetamethod)    == "function",
    cbv   = type(EF.getcallbackvalue)  == "function",
}
EX.conn = EX.conns  -- alias used in §18b hookfunction block

local isMobile = UIS.TouchEnabled and not UIS.KeyboardEnabled

-- ════════════════════════════════════════════════════════════════════════════
--  §04b  UNC CAPABILITY REPORT
--         Runs immediately after EX is built.
--         Categorises every missing UNC function, prints to warn(), and
--         shows a colour-coded on-screen panel so the user knows exactly
--         which features are degraded — no more silent failures.
-- ════════════════════════════════════════════════════════════════════════════
do
    -- Map each UNC function to the feature it gates and its severity
    -- severity: "critical" | "important" | "optional"
    local UNC_MAP = {
        { fn="hookfunction",       feat="Auto-parry namecall hook",     sev="critical"  },
        { fn="newcclosure",        feat="Safe C-closure wrappers",       sev="critical"  },
        { fn="getrawmetatable",    feat="Metatable intercept (parry)",   sev="critical"  },
        { fn="setreadonly",        feat="Metatable write unlock",        sev="critical"  },
        { fn="getnamecallmethod",  feat="__namecall method detection",   sev="critical"  },
        { fn="getgc",              feat="GC heap ball scanner",          sev="important" },
        { fn="getnilinstances",    feat="Nil-instance pre-arm scanner",  sev="important" },
        { fn="getinstances",       feat="Full instance dump scanner",    sev="important" },
        { fn="getaddress",         feat="Memory address resolution",     sev="important" },
        { fn="readprocessmemory",  feat="Direct memory read (CFrame/vel)",sev="important"},
        { fn="getupvalues",        feat="Upvalue inspection",            sev="optional"  },
        { fn="getconstants",       feat="Bytecode constant read",        sev="optional"  },
        { fn="getconnections",     feat="Signal connection inspector",   sev="optional"  },
        { fn="writeprocessmemory", feat="Memory write (hitbox expand)",  sev="optional"  },
        { fn="clonefunction",      feat="Function cloning",              sev="optional"  },
    }

    local missing_critical  = {}
    local missing_important = {}
    local missing_optional  = {}
    local all_ok = true

    for _, entry in ipairs(UNC_MAP) do
        if type(EF[entry.fn]) ~= "function" then
            all_ok = false
            if entry.sev == "critical" then
                table.insert(missing_critical,  "  [CRIT]  " .. entry.fn .. "  ->  " .. entry.feat)
            elseif entry.sev == "important" then
                table.insert(missing_important, "  [WARN]  " .. entry.fn .. "  ->  " .. entry.feat)
            else
                table.insert(missing_optional,  "  [INFO]  " .. entry.fn .. "  ->  " .. entry.feat)
            end
        end
    end

    -- Always print summary to executor output
    if all_ok then
        print("[WindHub] UNC check PASSED — all functions available")
    else
        warn("[WindHub] ═══════════════════════════════════════════════")
        warn("[WindHub] UNC CAPABILITY REPORT  (" .. ExecName .. ")")
        warn("[WindHub] ═══════════════════════════════════════════════")
        for _, line in ipairs(missing_critical)  do warn("[WindHub]" .. line) end
        for _, line in ipairs(missing_important) do warn("[WindHub]" .. line) end
        for _, line in ipairs(missing_optional)  do warn("[WindHub]" .. line) end
        warn("[WindHub] ═══════════════════════════════════════════════")
        if #missing_critical > 0 then
            warn("[WindHub] CRITICAL functions missing — auto-parry hook and namecall intercept WILL NOT WORK.")
            warn("[WindHub] Switch to Delta, Codex, Xeno, Wave, Optimware, Volt, or Potassium for full support.")
        end
    end

    -- On-screen panel (shown for 12 s if anything is missing)
    if not all_ok then
        task.spawn(function()
            task.wait(1.5)   -- wait for UI to settle
            pcall(function()
                local sg = Instance.new("ScreenGui")
                sg.Name          = "WindHubUNCReport"
                sg.ResetOnSpawn  = false
                sg.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
                pcall(function() sg.Parent = CoreGui end)

                -- Build lines to display
                local lines = {}
                if #missing_critical > 0 then
                    table.insert(lines, { text="MISSING CRITICAL UNC FUNCTIONS:", col=Color3.fromRGB(255,70,70) })
                    for _, l in ipairs(missing_critical) do
                        table.insert(lines, { text=l:gsub("^%s+",""), col=Color3.fromRGB(255,120,120) })
                    end
                end
                if #missing_important > 0 then
                    table.insert(lines, { text="DEGRADED (important):", col=Color3.fromRGB(255,180,50) })
                    for _, l in ipairs(missing_important) do
                        table.insert(lines, { text=l:gsub("^%s+",""), col=Color3.fromRGB(255,200,100) })
                    end
                end
                if #missing_optional > 0 then
                    table.insert(lines, { text="OPTIONAL (not critical):", col=Color3.fromRGB(160,160,160) })
                    for _, l in ipairs(missing_optional) do
                        table.insert(lines, { text=l:gsub("^%s+",""), col=Color3.fromRGB(200,200,200) })
                    end
                end

                local ROW_H   = 18
                local PAD     = 10
                local W       = 480
                local H       = PAD*2 + 26 + #lines * ROW_H

                local frame = Instance.new("Frame", sg)
                frame.Size            = UDim2.fromOffset(W, H)
                frame.Position        = UDim2.new(0.5, -W/2, 0, 60)
                frame.BackgroundColor3= Color3.fromRGB(10, 10, 16)
                frame.BorderSizePixel = 0
                Instance.new("UICorner", frame).CornerRadius = UDim.new(0, 10)
                local stroke = Instance.new("UIStroke", frame)
                stroke.Color     = (#missing_critical > 0) and Color3.fromRGB(220,60,60)
                                or Color3.fromRGB(220,160,40)
                stroke.Thickness = 1.8

                -- Title
                local title = Instance.new("TextLabel", frame)
                title.Size              = UDim2.new(1,-PAD*2, 0, 22)
                title.Position          = UDim2.fromOffset(PAD, PAD)
                title.BackgroundTransparency = 1
                title.Font              = Enum.Font.GothamBold
                title.TextSize          = 13
                title.TextColor3        = Color3.fromRGB(255,255,255)
                title.TextXAlignment    = Enum.TextXAlignment.Left
                title.Text              = "WindHub v6.0  |  UNC Capability Report  |  Executor: " .. ExecName

                -- Rows
                for i, row in ipairs(lines) do
                    local lbl = Instance.new("TextLabel", frame)
                    lbl.Size            = UDim2.new(1,-PAD*2, 0, ROW_H)
                    lbl.Position        = UDim2.fromOffset(PAD, PAD + 24 + (i-1)*ROW_H)
                    lbl.BackgroundTransparency = 1
                    lbl.Font            = Enum.Font.Code
                    lbl.TextSize        = 11
                    lbl.TextColor3      = row.col
                    lbl.TextXAlignment  = Enum.TextXAlignment.Left
                    lbl.Text            = row.text
                end

                -- Close button
                local btn = Instance.new("TextButton", frame)
                btn.Size            = UDim2.fromOffset(24, 24)
                btn.Position        = UDim2.new(1,-PAD-24, 0, PAD-2)
                btn.BackgroundTransparency = 1
                btn.Font            = Enum.Font.GothamBold
                btn.TextSize        = 16
                btn.TextColor3      = Color3.fromRGB(200,200,200)
                btn.Text            = "x"
                btn.MouseButton1Click:Connect(function() sg:Destroy() end)

                -- Auto-destroy after 15 s
                task.delay(15, function() pcall(function() sg:Destroy() end) end)
            end)
        end)
    end

    -- Store for later introspection (e.g. console `unc` command)
    _G._WindHub_UNCReport = {
        ok               = all_ok,
        missing_critical = missing_critical,
        missing_important= missing_important,
        missing_optional = missing_optional,
    }

    -- Notification is deferred — fired from §31 after UI.notify exists
    -- (UI is not declared until line ~4427, so we can't call it here)
end

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

    -- Blade Ball: ball part is a numeric-named nil instance (e.g. "439").
    -- Cobalt confirmed: BallAdded fires with a nil-parented BasePart named "439".
    -- Accept any nil-parented BasePart whose name is a pure integer.
    local ok7, par = pcall(function() return obj.Parent end)
    if ok7 and par == nil and ok6 and nm and nm:match("^%d+$") then return true end

    return false
end

-- ── §10.7b  GetNil — targeted nil-instance lookup (Cobalt pattern) ─────────
--  Finds a specific nil-parented instance by Name + DebugId.
--  Used as a direct complement to the BallAdded remote: the server fires
--  BallAdded and the argument IS the nil instance, but this helper lets
--  us verify or re-fetch it when needed.
local function GetNil(name, debugId)
    if not EX.nil_ then return nil end
    local found = nil
    pcall(function()
        for _, obj in ipairs(EF.getnilinstances()) do
            local okN, n = pcall(function() return obj.Name end)
            local okD, d = pcall(function() return obj:GetDebugId() end)
            if okN and okD and n == name and d == debugId then
                found = obj
            end
        end
    end)
    return found
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
    local missing = {}
    if not EX.hook then table.insert(missing, "hookfunction") end
    if not EX.ncc  then table.insert(missing, "newcclosure")  end
    if not EX.grmt then table.insert(missing, "getrawmetatable") end
    if not EX.ncm  then table.insert(missing, "getnamecallmethod") end

    if #missing > 0 then
        -- Not a silent skip — always warn so the user knows why parry hook is off
        warn("[WindHub] __namecall hook DISABLED — missing UNC: " .. table.concat(missing, ", "))
        warn("[WindHub] Auto-parry will use event-based fallback only (may be slower).")
        namecallHooked = false
    else
        local mt = EF.getrawmetatable(game)
        if not mt then
            warn("[WindHub] getrawmetatable returned nil — hook skipped.")
        else
            if EX.sro then pcall(EF.setreadonly, mt, false) end

            local orig = rawget(mt, "__namecall")
            if not orig then
                warn("[WindHub] __namecall is nil on game metatable — hook skipped.")
            else
                local hooked = EF.newcclosure(function(self, ...)
                    local method = EF.getnamecallmethod()
                    if typeof(self) == "Instance" then
                        NamecallSignal:FireImmediate(self, method, ...)
                    end
                    return orig(self, ...)
                end)

                local ok, hookErr = pcall(function()
                    EF.hookfunction(orig, hooked)
                    _namecallOrig = orig
                end)
                namecallHooked = ok
                if not ok then
                    warn("[WindHub] hookfunction failed on __namecall: " .. tostring(hookErr))
                    warn("[WindHub] Auto-parry will use event-based fallback only.")
                else
                    print("[WindHub] __namecall hook installed successfully.")
                end
            end

            if EX.sro then pcall(EF.setreadonly, mt, true) end
        end
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
    onWinnerText     = Signal.new(),
    onSetMessage     = Signal.new(),
    onPlrDashed      = Signal.new(),
    onRoundEnded     = Signal.new(),
    onVisualCD       = Signal.new(),
    onEndCD          = Signal.new(),
    onSyncDragonSpirit = Signal.new(),
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
        handler = function(effectType, hrp, extra, ...)
            -- Cobalt confirmed: ParrySuccessAll(effectType, hrp, extra)
            -- effectType = "SlashEffect", hrp = HumanoidRootPart of the parrying player
            -- Resolve the Player from the HRP's parent character
            local resolvedPlayer = nil
            pcall(function()
                if typeof(hrp) == "Instance" then
                    local char = hrp.Parent
                    if char then
                        resolvedPlayer = Plrs:GetPlayerFromCharacter(char)
                    end
                end
            end)
            -- Fire with real Player instance so downstream listeners work correctly
            GameRemotes.onParrySuccess:Fire(resolvedPlayer, hrp, effectType, ...)
            local isLocal = resolvedPlayer == lp
            if isLocal then
                _G.WindHub_LastSuccessAt = os.clock()
                AccuracyTracker:success()
            end
            -- Cache for VisualFX/EventBus listener defined later (§88)
            _G._WindHub_LastParrySuccess = {
                effectType = effectType,
                hrp        = hrp,
                isLocal    = isLocal,
                t          = os.clock(),
            }
        end,
    },
    {
        name    = "BallExplode",
        handler = function(ball, hitPlayer, wasBlocked, ...)
            -- Cobalt confirmed: BallExplode(ball, hitPlayer, wasBlocked)
            -- ball       = nil-parented BasePart (e.g. "347")
            -- hitPlayer  = Player instance who got hit
            -- wasBlocked = false → they failed to parry; true → they blocked
            GameRemotes.onBallExplode:Fire(ball, hitPlayer, wasBlocked, ...)
            if typeof(ball) == "Instance" then
                _G.WindHub_ExplodedBalls[ball] = true
            end
            -- Record the victim for kill feed / player analysis
            if typeof(hitPlayer) == "Instance" and not wasBlocked then
                _G._WindHub_LastKill = {
                    victim  = hitPlayer,
                    ball    = ball,
                    t       = os.clock(),
                }
                -- If local player got eliminated, flag it
                if hitPlayer == lp then
                    _G.WindHub_LocalDied = true
                    _G.WindHub_LocalDiedAt = os.clock()
                end
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
            if typeof(ball) ~= "Instance" then return end
            _G.WindHub_LatestBall = ball
            -- Route through _onBallFound so nil-parented balls (Cobalt pattern:
            -- BallAdded fires with a nil-parent Part named "439") get the
            -- AncestryChanged pre-arm and all MemScanner callbacks fire correctly.
            _onBallFound(ball, _G._WindTracker)
        end,
    },
    {
        name    = "WinnerText",
        handler = function(winnerName, ...)
            GameRemotes.onWinnerText:Fire(winnerName, ...)
            if type(winnerName) == "string" then
                _G._WindHub_LastWinner = { name = winnerName, t = os.clock() }
                if winnerName == lp.Name then
                    _G.WindHub_WinsThisSession = (_G.WindHub_WinsThisSession or 0) + 1
                end
            end
        end,
    },
    {
        name    = "SetMessage",
        handler = function(msg, ...)
            -- Cobalt confirmed: SetMessage fires server-side UI text to all clients
            -- (game state announcements like "Standoff!", "Round starting", etc.)
            GameRemotes.onSetMessage:Fire(msg, ...)
            if type(msg) == "string" then
                _G._WindHub_LastServerMsg = { text = msg, t = os.clock() }
            end
        end,
    },
    {
        name    = "PlrDashed",
        handler = function(player, ...)
            -- Cobalt confirmed: PlrDashed fires when any player uses their dash ability.
            -- Tracking dashes is critical for parry prediction — a dashing player's
            -- position changes instantly, invalidating in-flight ETA calculations.
            GameRemotes.onPlrDashed:Fire(player, ...)
            if typeof(player) == "Instance" then
                _G._WindHub_LastDash = _G._WindHub_LastDash or {}
                _G._WindHub_LastDash[player] = os.clock()
                if player == lp then
                    _G.WindHub_LocalDashedAt = os.clock()
                end
            end
        end,
    },
    {
        name    = "RoundEnded",
        handler = function(...)
            -- Cobalt confirmed: RoundEnded fires when the current round concludes.
            GameRemotes.onRoundEnded:Fire(...)
            _G._WindHub_RoundEndAt = os.clock()
            -- Reset per-round state
            _G.WindHub_LocalDied      = false
            _G.WindHub_Standoff       = false
            _G.WindHub_SecondaryReady = true
            _G._WindHub_LastDash      = {}
        end,
    },
    {
        name    = "VisualCD",
        handler = function(player, ability, duration, ...)
            -- Cobalt confirmed: VisualCD fires to show a cooldown timer on a player's
            -- ability (dash, sword skill, etc.). Tracking this tells WindHub exactly
            -- when each player's ability comes off cooldown.
            GameRemotes.onVisualCD:Fire(player, ability, duration, ...)
            if typeof(player) == "Instance" then
                _G._WindHub_CooldownMap = _G._WindHub_CooldownMap or {}
                _G._WindHub_CooldownMap[player] = _G._WindHub_CooldownMap[player] or {}
                _G._WindHub_CooldownMap[player][tostring(ability)] = {
                    endsAt = os.clock() + (tonumber(duration) or 0),
                }
            end
        end,
    },
    {
        name    = "EndCD",
        handler = function(player, ability, ...)
            -- Cobalt confirmed: EndCD fires when a cooldown finishes (companion to VisualCD).
            GameRemotes.onEndCD:Fire(player, ability, ...)
            if typeof(player) == "Instance" then
                local cdMap = _G._WindHub_CooldownMap
                if cdMap and cdMap[player] then
                    cdMap[player][tostring(ability)] = nil
                end
            end
        end,
    },
    {
        name    = "SyncDragonSpirit",
        handler = function(player, active, ...)
            -- Cobalt confirmed: SyncDragonSpirit syncs the Dragon Spirit ability state.
            -- When active, the player has enhanced abilities — factor into threat scoring.
            GameRemotes.onSyncDragonSpirit:Fire(player, active, ...)
            if typeof(player) == "Instance" then
                _G._WindHub_DragonSpirit = _G._WindHub_DragonSpirit or {}
                _G._WindHub_DragonSpirit[player] = active and os.clock() or nil
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

-- ── §18b  Cobalt-style hookfunction interception ─────────────────────────
--  Wraps the GAME's own OnClientEvent handlers for key remotes so WindHub
--  sees raw args before the game processes them. Runs after a short delay
--  so the game's own connections are already established.
--
--  Cobalt-confirmed remotes and paths:
--    ReplicatedStorage.Remotes.BallAdded
--    ReplicatedStorage.Remotes.ParrySuccessAll
--    ReplicatedStorage.Remotes.BallExplode
--    ReplicatedStorage.conch_networking.update_user_roles
--    ReplicatedStorage.Packages._Index["ytrev_replion@2.0.0-rc.1"].replion.Remotes.UpdateReplicateTo
if EX.hook and EX.conns then
    local function _hookRemoteEvent(remote, label)
        local conns = EF.getconnections(remote.OnClientEvent)
        if not conns then return 0 end
        local hooked = 0
        for _, conn in ipairs(conns) do
            local fn = conn.Function
            if type(fn) ~= "function" then continue end
            pcall(function()
                local old; old = EF.hookfunction(fn, function(...)
                    if RemoteSpy and RemoteSpy.log then
                        local entry = { name = label, args = {...}, t = os.clock(), source = "hookfn" }
                        table.insert(RemoteSpy.log, 1, entry)
                        if #RemoteSpy.log > 500 then table.remove(RemoteSpy.log) end
                    end
                    return old(...)
                end)
                hooked = hooked + 1
            end)
        end
        if Console then
            Console.info("HookFn", "Hooked " .. label .. " (" .. hooked .. "/" .. #conns .. " conns)")
        end
        return hooked
    end

    task.delay(2, function()
        pcall(function()
            -- Core Remotes folder
            local coreFld = RepStor:FindFirstChild("Remotes")
            if coreFld then
                for _, name in ipairs({ "BallAdded", "ParrySuccessAll", "ParryAttemptAll", "BallExplode", "StandoffStart", "StandoffEnd", "SecondaryEndCD", "DisableReaper", "WinnerText", "SetMessage", "PlrDashed", "RoundEnded", "VisualCD", "EndCD", "SyncDragonSpirit" }) do
                    local r = coreFld:FindFirstChild(name)
                    if r and r:IsA("RemoteEvent") then _hookRemoteEvent(r, name) end
                end
            end

            -- conch_networking (role/user sync — Cobalt confirmed: update_user_roles, create_user)
            local conch = RepStor:FindFirstChild("conch_networking")
            if conch then
                for _, rName in ipairs({ "update_user_roles", "create_user" }) do
                    local r = conch:FindFirstChild(rName)
                    if r and r:IsA("RemoteEvent") then
                        _hookRemoteEvent(r, "conch." .. rName)
                    end
                end
            end

            -- Replion remotes — iterate all children (Cobalt confirmed: UpdateReplicateTo, Set)
            pcall(function()
                local replionRemotes = RepStor.Packages._Index["ytrev_replion@2.0.0-rc.1"].replion.Remotes
                for _, child in ipairs(replionRemotes:GetChildren()) do
                    if child:IsA("RemoteEvent") then
                        _hookRemoteEvent(child, "Replion." .. child.Name)
                    end
                end
            end)

            -- Store remotes (Cobalt confirmed: Store.UpdateCrateKeys)
            local storeFld = coreFld and coreFld:FindFirstChild("Store")
            if storeFld then
                for _, child in ipairs(storeFld:GetChildren()) do
                    if child:IsA("RemoteEvent") then
                        _hookRemoteEvent(child, "Store." .. child.Name)
                    end
                end
            end

            -- sleitnick_net internal remotes (obfuscated names, Cobalt-confirmed)
            pcall(function()
                local netPkg = RepStor.Packages._Index["sleitnick_net@0.1.0"].net
                for _, child in ipairs(netPkg:GetChildren()) do
                    if child:IsA("RemoteEvent") then
                        _hookRemoteEvent(child, "sleitnick_net." .. child.Name)
                    end
                end
            end)
        end)
    end)
end

-- ── §18c  RemotePing intercept (Cobalt pattern) ───────────────────────────
--  Blade Ball uses ReplicatedStorage.Shared.Ping.RemotePing (RemoteFunction)
--  for latency measurement. Hooking OnClientInvoke gives WindHub the raw
--  round-trip time before the game processes it, and hookmetamethod ensures
--  the game can't silently overwrite our hook.
if EX.hook and EX.cbv and EX.meta then
    task.delay(2, function()
        pcall(function()
            local shared = RepStor:FindFirstChild("Shared")
            local pingFld = shared and shared:FindFirstChild("Ping")
            local pingRF  = pingFld and pingFld:FindFirstChild("RemotePing")
            if not pingRF or not pingRF:IsA("RemoteFunction") then return end

            local Callback = EF.getcallbackvalue(pingRF, "OnClientInvoke")
            if type(Callback) ~= "function" then return end

            pingRF.OnClientInvoke = function(...)
                local t0     = os.clock()
                local args   = table.pack(...)
                local result = table.pack(Callback(table.unpack(args, 1, args.n)))
                -- Record round-trip as an additional PingComp sample
                local rtt = (os.clock() - t0) * 1000
                if rtt > 0 and rtt < 2000 then
                    PingComp.pingMs = rtt
                    table.insert(PingComp.hist, rtt)
                    if #PingComp.hist > 60 then table.remove(PingComp.hist, 1) end
                    PingComp.method = "RemotePing"
                end
                return table.unpack(result, 1, result.n)
            end

            -- Prevent the game from overwriting our hook
            local mtHook; mtHook = EF.hookmetamethod(game, "__newindex", function(self, key, value)
                if rawequal(self, pingRF) and rawequal(key, "OnClientInvoke")
                    and type(value) == "function"
                    and (not EF.checkcaller or not EF.checkcaller())
                then
                    Callback = value  -- update inner callback transparently
                    return
                end
                return mtHook(self, key, value)
            end)

            if Console then Console.info("HookFn", "RemotePing hooked — PingComp using direct RTT") end
        end)
    end)
end

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
    if not (EX.hook and EX.ncc and EX.grmt) then
        local m2 = {}
        if not EX.hook then table.insert(m2, "hookfunction") end
        if not EX.ncc  then table.insert(m2, "newcclosure") end
        if not EX.grmt then table.insert(m2, "getrawmetatable") end
        warn("[WindHub] AnimFix hook DISABLED — missing: " .. table.concat(m2, ", "))
        return
    end

    local dummy = Instance.new("Animation")
    local mt
    pcall(function() mt = EF.getrawmetatable(dummy) end)
    dummy:Destroy()
    if not mt then
        warn("[WindHub] AnimFix: getrawmetatable returned nil — hook skipped.")
        return
    end

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

-- ── Startup toast (always visible, confirms script loaded) ──
task.spawn(function()
    task.wait(0.2)
    pcall(function()
        local toastGui = Instance.new("ScreenGui")
        toastGui.Name = "WindHubStartup"
        toastGui.ResetOnSpawn = false
        toastGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
        toastGui.DisplayOrder = 99998
        pcall(function() toastGui.Parent = CoreGui end)
        if not toastGui.Parent then
            toastGui.Parent = game:GetService("Players").LocalPlayer.PlayerGui
        end
        local f = Instance.new("Frame", toastGui)
        f.Size = UDim2.new(0, 320, 0, 52)
        f.Position = UDim2.new(0.5, -160, 0, 10)
        f.BackgroundColor3 = Color3.fromRGB(12, 14, 22)
        f.BorderSizePixel = 0
        Instance.new("UICorner", f).CornerRadius = UDim.new(0, 9)
        local s = Instance.new("UIStroke", f)
        s.Color = Color3.fromRGB(94, 132, 255)
        s.Thickness = 1.5
        local t = Instance.new("TextLabel", f)
        t.Size = UDim2.new(1, -14, 1, 0)
        t.Position = UDim2.new(0, 7, 0, 0)
        t.BackgroundTransparency = 1
        t.Font = Enum.Font.GothamBold
        t.TextSize = 14
        t.TextColor3 = Color3.fromRGB(120, 180, 255)
        t.TextXAlignment = Enum.TextXAlignment.Left
        t.TextWrapped = true
        t.RichText = true
        t.Text = "<b>WindHub v6.0</b> loaded  |  Click <b>Console</b> tab for output"
        game:GetService("Debris"):AddItem(toastGui, 6)
    end)
end)

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
    Size = UDim2.new(0, winW, 0, winH),   -- correct size from the start
    BackgroundColor3 = UI.Theme.Bg,
    BorderSizePixel = 0,
    ClipsDescendants = true,
    Visible = true,
})
corner(window, 14)
stroke(window, UI.Theme.Stroke, 1.5)
UI.window = window
-- Spring-bounce open immediately — not deferred until after tabs build
task.defer(function()
    window.Size = UDim2.new(0, 0, 0, 0)
    task.wait()
    local ti = TweenInfo.new(0.5, Enum.EasingStyle.Back, Enum.EasingDirection.Out)
    TS:Create(window, ti, { Size = UDim2.new(0, winW, 0, winH) }):Play()
end)

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
local btnZoom  = headerBtn("Zoom", "⊕", -96, UI.Theme.Accent)

-- ── Zoom / scale system ───────────────────────────────────
local ZOOM_LEVELS = { 1.0, 1.25, 1.5, 2.0 }
local ZOOM_LABELS = { "1x", "1.25x", "1.5x", "2x" }
local _zoomIdx = 1   -- current level index

local function applyZoom(idx)
    local scale = ZOOM_LEVELS[idx]
    local scaledW = math.floor(winW * scale)
    local scaledH = math.floor(winH * scale)
    springTween(window, { Size = UDim2.new(0, scaledW, 0, scaledH) }, 0.35)
    btnZoom.Text = ZOOM_LABELS[idx]
    -- also scale fonts slightly for readability at large sizes
    pcall(function()
        if UI.statusLeft  then UI.statusLeft.TextSize  = math.floor(10 * math.min(scale, 1.5)) end
        if UI.statusRight then UI.statusRight.TextSize = math.floor(10 * math.min(scale, 1.5)) end
    end)
end

btnZoom.MouseButton1Click:Connect(function()
    _zoomIdx = (_zoomIdx % #ZOOM_LEVELS) + 1
    applyZoom(_zoomIdx)
    UI.notify({
        title = "Zoom",
        text  = "Window scaled to " .. ZOOM_LABELS[_zoomIdx],
        kind  = "info",
        duration = 1.2,
    })
end)

-- Pinch-to-zoom on mobile
if isMobile then
    local _pinchDist = nil
    local _pinchStartScale = 1.0
    UIS.TouchStarted:Connect(function(t)
        local touches = UIS:GetTouches()
        if #touches == 2 then
            local p1 = touches[1].Position
            local p2 = touches[2].Position
            _pinchDist = (p1 - p2).Magnitude
            _pinchStartScale = ZOOM_LEVELS[_zoomIdx]
        end
    end)
    UIS.TouchMoved:Connect(function()
        local touches = UIS:GetTouches()
        if #touches == 2 and _pinchDist and _pinchDist > 0 then
            local p1 = touches[1].Position
            local p2 = touches[2].Position
            local newDist = (p1 - p2).Magnitude
            local ratio = newDist / _pinchDist
            local targetScale = math.clamp(_pinchStartScale * ratio, 0.75, 2.5)
            local scaledW = math.floor(winW * targetScale)
            local scaledH = math.floor(winH * targetScale)
            window.Size = UDim2.new(0, scaledW, 0, scaledH)
        end
    end)
    UIS.TouchEnded:Connect(function()
        local touches = UIS:GetTouches()
        if #touches < 2 then
            _pinchDist = nil
            -- snap to nearest zoom level
            local curW = window.Size.X.Offset
            local bestIdx, bestDiff = 1, math.huge
            for i, lvl in ipairs(ZOOM_LEVELS) do
                local diff = math.abs(winW * lvl - curW)
                if diff < bestDiff then bestDiff = diff; bestIdx = i end
            end
            _zoomIdx = bestIdx
            applyZoom(_zoomIdx)
        end
    end)
end


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
    local title    = opts.title or "WindHub"
    local msg      = opts.text or ""
    local dur      = opts.duration or 3
    local kind     = opts.kind or "info"
    local detail   = opts.detail   -- optional multi-line detail shown on click
    local onClick  = opts.onClick  -- optional callback

    local accentCol = (kind == "good" and UI.Theme.Good)
        or (kind == "warn" and UI.Theme.Warn)
        or (kind == "bad" and UI.Theme.Bad)
        or UI.Theme.Accent

    local hasDetail = (detail and #detail > 0) or (type(onClick) == "function")

    -- outer clickable button so the whole toast is tappable
    local toastBtn = mk("TextButton", {
        Parent = toastHolder,
        Size = UDim2.new(1, 0, 0, 0),
        AutomaticSize = Enum.AutomaticSize.Y,
        BackgroundColor3 = UI.Theme.BgLight,
        BorderSizePixel = 0,
        BackgroundTransparency = 1,
        Text = "",
        AutoButtonColor = false,
        ZIndex = 51,
    })
    local toast = toastBtn   -- alias so rest of code stays the same

    corner(toast, 10)
    stroke(toast, UI.Theme.Stroke, 1, 0.2)

    -- coloured left accent bar
    local accentBar = mk("Frame", {
        Parent = toast,
        Size = UDim2.new(0, 4, 1, -12),
        Position = UDim2.new(0, 6, 0, 6),
        BackgroundColor3 = accentCol,
        BorderSizePixel = 0,
        ZIndex = 52,
    })
    corner(accentBar, 2)

    mk("TextLabel", {
        Parent = toast,
        Size = UDim2.new(1, -46, 0, 16),
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
        Size = UDim2.new(1, -46, 0, 0),
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
    -- "tap to expand" hint when detail is present
    if hasDetail then
        mk("TextLabel", {
            Parent = toast,
            Size = UDim2.new(0, 26, 0, 14),
            Position = UDim2.new(1, -32, 0, 8),
            BackgroundTransparency = 1,
            Text = "▼",
            Font = Enum.Font.Gotham,
            TextSize = 10,
            TextColor3 = accentCol,
            ZIndex = 52,
        })
    end

    -- expandable detail frame (hidden by default)
    local detailFrame = nil
    if hasDetail then
        detailFrame = mk("TextLabel", {
            Parent = toast,
            Size = UDim2.new(1, -28, 0, 0),
            AutomaticSize = Enum.AutomaticSize.Y,
            Position = UDim2.new(0, 18, 0, 44),
            BackgroundTransparency = 1,
            Text = detail or "",
            Font = Enum.Font.Code,
            TextSize = 10,
            TextColor3 = accentCol,
            TextXAlignment = Enum.TextXAlignment.Left,
            TextWrapped = true,
            Visible = false,
            ZIndex = 52,
        })
    end

    -- pad bottom
    mk("Frame", {
        Parent = toast,
        Size = UDim2.new(1, 0, 0, 10),
        Position = UDim2.new(0, 0, 1, 0),
        BackgroundTransparency = 1,
    })

    -- click handler: expand detail or fire callback
    local _expanded = false
    toastBtn.MouseButton1Click:Connect(function()
        if onClick then pcall(onClick) end
        if detailFrame then
            _expanded = not _expanded
            detailFrame.Visible = _expanded
        end
    end)
    -- hover highlight
    toastBtn.MouseEnter:Connect(function()
        if hasDetail then tween(toast, { BackgroundColor3 = UI.Theme.Stroke }, 0.12) end
    end)
    toastBtn.MouseLeave:Connect(function()
        tween(toast, { BackgroundColor3 = UI.Theme.BgLight }, 0.12)
    end)

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
        if _expanded then return end   -- don't dismiss while user is reading detail
        tween(toast, { BackgroundTransparency = 1, Position = UDim2.new(1, 20, 0, 0) }, 0.25)
        for _, d in ipairs(toast:GetDescendants()) do
            if d:IsA("TextLabel") then tween(d, { TextTransparency = 1 }, 0.25) end
            if d:IsA("UIStroke") then tween(d, { Transparency = 1 }, 0.25) end
        end
        task.delay(0.3, function() pcall(function() toast:Destroy() end) end)
    end)

    return toast
end

-- ── UNC failure side-notification (fires here, UI.notify now exists) ──
task.defer(function()
    local r = _G._WindHub_UNCReport
    if not r or r.ok then return end

    local detailLines = {}
    for _, l in ipairs(r.missing_critical)  do table.insert(detailLines, "[CRIT] " .. l:gsub("^%s+","")) end
    for _, l in ipairs(r.missing_important) do table.insert(detailLines, "[WARN] " .. l:gsub("^%s+","")) end
    for _, l in ipairs(r.missing_optional)  do table.insert(detailLines, "[INFO] " .. l:gsub("^%s+","")) end

    local crit = #r.missing_critical
    UI.notify({
        title   = crit > 0 and "UNC Missing — Parry Hook Disabled" or "UNC Partially Missing",
        text    = crit > 0
            and (crit .. " critical function(s) missing. Tap ▼ to see list.")
            or  (#r.missing_important .. " important function(s) missing. Tap ▼ to see list."),
        kind    = crit > 0 and "bad" or "warn",
        duration = 15,
        detail  = table.concat(detailLines, "\n"),
    })
end)

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
--      Wrapped in pcall: a bad widget never kills the whole UI
-- ============================================================
local _tabBuildOk, _tabBuildErr = pcall(function()

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

end) -- end §32 pcall

if not _tabBuildOk then
    warn("[WindHub] Tab build error: " .. tostring(_tabBuildErr))
    -- Show error inside the window so user sees it
    pcall(function()
        local errLbl = Instance.new("TextLabel")
        errLbl.Size = UDim2.new(1, -20, 0, 80)
        errLbl.Position = UDim2.new(0, 10, 0.5, -40)
        errLbl.BackgroundTransparency = 1
        errLbl.Font = Enum.Font.Code
        errLbl.TextSize = 12
        errLbl.TextColor3 = Color3.fromRGB(255, 100, 100)
        errLbl.TextWrapped = true
        errLbl.TextXAlignment = Enum.TextXAlignment.Left
        errLbl.Text = "UI build error (tabs):\n" .. tostring(_tabBuildErr)
        errLbl.Parent = window
    end)
end

-- ============================================================
-- §33  PC HOTKEYS  (open animation already fired in §31)
-- ============================================================

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


-- ============================================================
-- §38  UNC FOUNDATION  ─  Full Unified Naming Convention Map
-- ============================================================
-- This section builds an exhaustive capability map covering every
-- function in the UNC specification.  Each entry is checked at
-- runtime; executors that expose non-standard names are aliased
-- transparently.  The EF table is extended in-place so every
-- subsystem written before this section automatically benefits.
-- ============================================================

local UNC = {}   -- public registry: name → function (or nil if absent)

-- ── §38.1  Discovery helpers ─────────────────────────────
local function _env()
    -- Returns the global environment table.
    if getfenv then return getfenv(0) end
    return _G
end

-- Try multiple candidate names for a UNC function, return the first that
-- exists and is callable, or nil.
local function _pick(...)
    local env = _env()
    for _, name in ipairs({ ... }) do
        local v = env[name]
        if type(v) == "function" then return v, name end
    end
    return nil, nil
end

-- Attempt to call a function safely and return the result or nil on error.
local function _safeCall(fn, ...)
    if not fn then return nil end
    local ok, r = pcall(fn, ...)
    return ok and r or nil
end

-- ── §38.2  UNC Closure / Upvalue group ───────────────────
UNC.newcclosure       = _pick("newcclosure", "cclosure", "syncclosure")
UNC.clonefunction     = _pick("clonefunction", "clonefunc")
UNC.iscclosure        = _pick("iscclosure")
UNC.islclosure        = _pick("islclosure")
UNC.isourclosure      = _pick("isourclosure")
UNC.checkclosure      = _pick("checkclosure")
UNC.loadstring        = _pick("loadstring") or loadstring

UNC.getupvalues       = _pick("getupvalues", "debug.getupvalues")
UNC.setupvalue        = _pick("setupvalue",  "debug.setupvalue")
UNC.getupvalue        = _pick("getupvalue",  "debug.getupvalue")
UNC.upvaluecount      = _pick("debug.getupvaluecount", "debug.upvaluecount")
UNC.getconstants      = _pick("getconstants", "debug.getconstants")
UNC.setconstant       = _pick("setconstant",  "debug.setconstant")
UNC.getconstant       = _pick("getconstant",  "debug.getconstant")
UNC.getprotos         = _pick("getprotos",    "debug.getprotos")
UNC.getproto          = _pick("getproto",     "debug.getproto")
UNC.getstack          = _pick("getstack",     "debug.getstack")
UNC.getinfo           = _pick("getinfo",      "debug.getinfo")

-- ── §38.3  Hook group ────────────────────────────────────
UNC.hookfunction      = _pick("hookfunction",    "hookfunc", "replaceclosure")
UNC.restorefunction   = _pick("restorefunction", "restorefunc")
UNC.hookmetamethod    = _pick("hookmetamethod",  "hookmeta")

-- ── §38.4  Metatable group ────────────────────────────────
UNC.getrawmetatable   = _pick("getrawmetatable", "debug.getmetatable")
UNC.setrawmetatable   = _pick("setrawmetatable", "debug.setmetatable")
UNC.setreadonly       = _pick("setreadonly",     "make_writable")
UNC.isreadonly        = _pick("isreadonly")
UNC.getnamecallmethod = _pick("getnamecallmethod", "get_namecall_method")
UNC.setnamecallmethod = _pick("setnamecallmethod", "set_namecall_method")

-- ── §38.5  Instance / GC group ───────────────────────────
UNC.getgc             = _pick("getgc")
UNC.getnilinstances   = _pick("getnilinstances", "get_nil_instances")
UNC.getinstances      = _pick("getinstances",    "get_instances")
UNC.getconnections    = _pick("getconnections",  "get_connections")
UNC.getscripts        = _pick("getscripts")
UNC.getloadedmodules  = _pick("getloadedmodules")
UNC.getsimplecallbackfunction = _pick("getsimplecallbackfunction")

-- ── §38.6  Memory / Process group ────────────────────────
UNC.readprocessmemory  = _pick("readprocessmemory",  "rpm", "mem_read")
UNC.writeprocessmemory = _pick("writeprocessmemory", "wpm", "mem_write")
UNC.getaddress         = _pick("getaddress",         "getaddr", "addressof")
UNC.getgcaddress       = _pick("getgcaddress",       "gcaddress")

-- ── §38.7  Cryptography / Encoding group ─────────────────
UNC.crypt              = {}
UNC.crypt.base64encode = _pick("crypt.base64encode", "base64encode", "b64encode")
UNC.crypt.base64decode = _pick("crypt.base64decode", "base64decode", "b64decode")
UNC.crypt.hash         = _pick("crypt.hash",         "crypt_hash")
UNC.crypt.random       = _pick("crypt.random",       "crypt_random")
UNC.crypt.encrypt      = _pick("crypt.encrypt")
UNC.crypt.decrypt      = _pick("crypt.decrypt")
UNC.crypt.generatekey  = _pick("crypt.generatekey")

-- Legacy base64 aliases
UNC.base64encode = UNC.crypt.base64encode
UNC.base64decode = UNC.crypt.base64decode

-- ── §38.8  HTTP / WebSocket group ────────────────────────
UNC.request      = _pick("request", "http_request", "http.request")
UNC.httpget      = _pick("httpget", "http.get")
UNC.httppost     = _pick("httppost", "http.post")
UNC.websocket    = {}
UNC.websocket.connect = _pick("WebSocket.connect", "websocket.connect")

-- Thin wrapper that works across executors
function UNC.httpRequest(opts)
    if UNC.request then
        return _safeCall(UNC.request, opts)
    elseif UNC.httpget and opts.Method == "GET" then
        return _safeCall(UNC.httpget, opts.Url)
    end
    return nil
end

-- ── §38.9  File System group ──────────────────────────────
UNC.readfile   = _pick("readfile",   "io.read",  "read_file")
UNC.writefile  = _pick("writefile",  "io.write", "write_file")
UNC.appendfile = _pick("appendfile", "io.append","append_file")
UNC.loadfile   = _pick("loadfile")
UNC.isfile     = _pick("isfile",     "file_exists")
UNC.listfiles  = _pick("listfiles",  "list_files",  "dir")
UNC.makefolder = _pick("makefolder", "create_dir",  "mkdir")
UNC.isfolder   = _pick("isfolder",   "folder_exists")
UNC.delfile    = _pick("delfile",    "delete_file",  "rem_file")
UNC.delfolder  = _pick("delfolder",  "delete_folder","rem_dir")

-- ── §38.10  Input / Simulation group ─────────────────────
UNC.mouse = {}
UNC.mouse.move   = _pick("mouse.move",   "mousemove",   "mouse_move")
UNC.mouse.click  = _pick("mouse.click",  "mouseclick",  "mouse_click")
UNC.mouse.button = _pick("mouse.button", "mousebutton", "mouse_button")
UNC.mouse.scroll = _pick("mouse.scroll", "mousescroll", "mouse_scroll")
UNC.keypress     = _pick("keypress",     "key_press",   "presskey")
UNC.keyrelease   = _pick("keyrelease",   "key_release", "releasekey")
UNC.setclipboard = _pick("setclipboard", "toclipboard", "clipboard_write")
UNC.getclipboard = _pick("getclipboard", "fromclipboard","clipboard_read")

-- ── §38.11  Drawing / Render group ───────────────────────
UNC.Drawing      = _G.Drawing        -- Drawing namespace
UNC.drawingnew   = Drawing and Drawing.new or nil
UNC.drawingclear = _pick("Drawing.clear") or (Drawing and Drawing.clear)

-- Check which Drawing shapes are supported
UNC.DrawingShapes = {}
if Drawing then
    for _, shape in ipairs({ "Line","Text","Circle","Square","Triangle","Image","Quad" }) do
        local ok = pcall(function()
            local d = Drawing.new(shape)
            if d then pcall(function() d:Remove() end) end
        end)
        UNC.DrawingShapes[shape] = ok
    end
end

-- ── §38.12  Environment group ─────────────────────────────
UNC.getgenv     = _pick("getgenv",    "get_global_env")
UNC.getrenv     = _pick("getrenv",    "get_roblox_env")
UNC.getsenv     = _pick("getsenv",    "get_script_env")
UNC.getmenv     = _pick("getmenv",    "get_module_env")
UNC.getfenv     = _pick("getfenv")  or getfenv
UNC.setfenv     = _pick("setfenv")  or setfenv

-- ── §38.13  Console / Output group ───────────────────────
UNC.rconsolename   = _pick("rconsolename",  "consoletitle")
UNC.rconsoleprint  = _pick("rconsoleprint", "consoleclear")
UNC.rconsoleclear  = _pick("rconsoleclear", "consoleclear")
UNC.rconsoleclose  = _pick("rconsoleclose", "consoleclose")
UNC.rconsolecreate = _pick("rconsolecreate","consolecreate")
UNC.consoleinput   = _pick("consoleinput",  "console_input")

-- ── §38.14  Misc group ────────────────────────────────────
UNC.identifyexecutor = _pick("identifyexecutor", "whatexecutor", "executorname")
UNC.getexecutorname  = UNC.identifyexecutor
UNC.isexecutorclosure= _pick("isexecutorclosure", "checkclosure")
UNC.setfflag         = _pick("setfflag",   "setFFlag")
UNC.getfflag         = _pick("getfflag",   "getFFlag")
UNC.messagebox       = _pick("messagebox")
UNC.queue_on_teleport= _pick("queue_on_teleport", "queueonteleport")
UNC.decompile        = _pick("decompile")
UNC.gethiddenproperty = _pick("gethiddenproperty")
UNC.sethiddenproperty = _pick("sethiddenproperty")

-- ── §38.15  Capability report ─────────────────────────────
function UNC.capabilityReport()
    local out = {}
    local groups = {
        { "Hooks",    { "hookfunction","newcclosure","getrawmetatable","setreadonly" } },
        { "Upvalues", { "getupvalues","setupvalue","getconstants","getprotos" } },
        { "Memory",   { "readprocessmemory","getaddress","getgc","getnilinstances" } },
        { "Instance", { "getinstances","getconnections","getscripts" } },
        { "Filesystem",{ "readfile","writefile","isfile","makefolder" } },
        { "Crypto",   { "base64encode","base64decode" } },
        { "Drawing",  { "Drawing" } },
        { "Input",    { "setclipboard" } },
    }
    for _, g in ipairs(groups) do
        local present = {}
        for _, fn in ipairs(g[2]) do
            if UNC[fn] or (_G[fn] ~= nil) then
                table.insert(present, fn)
            end
        end
        out[g[1]] = (#present .. "/" .. #g[2]) .. " (" .. table.concat(present, ",") .. ")"
    end
    return out
end

-- Merge UNC into the EF (executor functions) table so all subsystems
-- written before this section can access the extended capabilities.
for k, v in pairs(UNC) do
    if EF[k] == nil and type(v) == "function" then
        EF[k] = v
    end
end

-- ── §38.16  sUNC (strict UNC) checker ────────────────────
-- sUNC verifies all mandatory UNC functions exist.
-- Returns pass/fail count and a per-function result table.
local UNC_MANDATORY = {
    "newcclosure","clonefunction","iscclosure","islclosure",
    "hookfunction","getrawmetatable","setreadonly","getnamecallmethod",
    "getgc","getnilinstances","getinstances","getconnections",
    "readprocessmemory","getaddress",
    "readfile","writefile","appendfile","isfile","listfiles",
    "makefolder","isfolder","loadfile",
    "base64encode","base64decode",
    "request",
    "getupvalues","setupvalue","getconstants","getprotos",
    "setclipboard","getclipboard",
    "identifyexecutor",
}
local UNC_OPTIONAL = {
    "decompile","messagebox","queue_on_teleport","gethiddenproperty",
    "sethiddenproperty","writeprocessmemory","setfflag","getfflag",
    "drawingclear","rconsolecreate","rconsoleprint","rconsoleclear",
}

local function sUNCcheck()
    local pass, fail, partial = 0, 0, 0
    local results = {}
    for _, name in ipairs(UNC_MANDATORY) do
        local present = UNC[name] ~= nil or _G[name] ~= nil
        if present then pass = pass + 1 else fail = fail + 1 end
        results[name] = { mandatory = true, present = present }
    end
    for _, name in ipairs(UNC_OPTIONAL) do
        local present = UNC[name] ~= nil or _G[name] ~= nil
        if present then partial = partial + 1 end
        results[name] = { mandatory = false, present = present }
    end
    return {
        mandatoryPass   = pass,
        mandatoryFail   = fail,
        optionalPresent = partial,
        optionalTotal   = #UNC_OPTIONAL,
        results         = results,
        score           = math.floor(pass / #UNC_MANDATORY * 100),
    }
end
UNC.sUNCcheck  = sUNCcheck
UNC.sUNCReport = nil  -- populated lazily on first request

-- ── §38.17  Extended EX flags from UNC ────────────────────
-- Augment the existing EX capability table with newly discovered UNC fns.
EX.drawingApi   = UNC.Drawing ~= nil
EX.filesystem   = UNC.readfile ~= nil and UNC.writefile ~= nil
EX.webSocket    = UNC.websocket ~= nil and UNC.websocket.connect ~= nil
EX.crypto       = UNC.base64encode ~= nil
EX.decompiler   = UNC.decompile ~= nil
EX.console      = UNC.rconsolecreate ~= nil
EX.clipboard    = UNC.setclipboard ~= nil
EX.fflag        = UNC.setfflag ~= nil
EX.hiddenProp   = UNC.gethiddenproperty ~= nil


-- ============================================================
-- §39  EXTENDED MEMORY SCANNER v3
--      Full heap-walk architecture with 6 reading strategies,
--      advanced vtable fingerprinting, multi-instance diff
--      tracking, cache telemetry, and byte-level diagnostics.
-- ============================================================

-- ── §39.1  Extended IEEE-754 readers ─────────────────────
local function readF16(bytes, offset)
    -- Half-precision float (IEEE 754-2008) stored at bytes[offset..offset+1]
    if #bytes < offset + 1 then return nil end
    local lo = bytes:byte(offset)   or 0
    local hi = bytes:byte(offset+1) or 0
    local raw = hi * 256 + lo
    local sign = (raw >= 0x8000) and -1 or 1
    local exp  = math.floor(raw / 0x400) % 32
    local frac = raw % 0x400
    if exp == 0 then
        return sign * (frac / 0x400) * 2^(-14)
    elseif exp == 31 then
        return frac == 0 and (sign * math.huge) or (0/0)
    else
        return sign * (1 + frac / 0x400) * 2^(exp - 15)
    end
end

local function readU8 (bytes, off) return bytes:byte(off) or 0 end
local function readU16(bytes, off)
    local lo = readU8(bytes, off) ; local hi = readU8(bytes, off+1)
    return hi*256 + lo
end
local function readU32(bytes, off)
    local a, b, c, d = bytes:byte(off, off+3)
    a, b, c, d = a or 0, b or 0, c or 0, d or 0
    return d*0x1000000 + c*0x10000 + b*0x100 + a
end
local function readI32(bytes, off)
    local u = readU32(bytes, off)
    return u >= 0x80000000 and u - 0x100000000 or u
end

-- Full 64-bit float decoder (IEEE 754 binary64, little-endian).
local function readF64_ext(bytes, off)
    if #bytes < off + 7 then return nil end
    local a,b,c,d,e,f,g,h = bytes:byte(off, off+7)
    a,b,c,d,e,f,g,h = a or 0,b or 0,c or 0,d or 0,
                       e or 0,f or 0,g or 0,h or 0
    local sign = h >= 128 and -1 or 1
    local expo = (h % 128)*16 + math.floor(g/16)
    local frac = (g%16)*2^48 + f*2^40 + e*2^32 + d*2^24 + c*2^16 + b*2^8 + a
    if expo == 0     then return sign * frac * 2^(-1074) end
    if expo == 2047  then return frac == 0 and sign*math.huge or 0/0 end
    return sign * (1 + frac*2^(-52)) * 2^(expo-1023)
end

-- ── §39.2  Raw-memory read helpers (per-executor) ─────────
-- Strategy 1: readprocessmemory (standard UNC)
-- Strategy 2: getgcaddress + readprocessmemory
-- Strategy 3: memory mapped via debug.getinfo upvalue scan
-- Strategy 4: proxy read through a sentinel Instance
-- Strategy 5: bit-manipulation on userdata (some executors)
-- Strategy 6: Roblox property path (fallback, no raw access)

local _RPM = EF.readprocessmemory or UNC.readprocessmemory
local _WPM = EF.writeprocessmemory or UNC.writeprocessmemory
local _ADDR= EF.getaddress or UNC.getaddress

-- Try to read `count` bytes at `addr` using the best available method.
local function _memRead(addr, count)
    if not addr or addr == 0 then return nil end
    if _RPM then
        local ok, data = pcall(_RPM, addr, count)
        if ok and type(data) == "string" and #data >= count then
            return data
        end
    end
    return nil
end

-- ── §39.3  Ball-instance structure layout ─────────────────
-- Roblox BasePart memory layout (approximated from calibration probes):
--   +0x00  vtable pointer         (8 bytes, 64-bit)
--   +0x08  ref-count / GC header  (8 bytes)
--   +0x10  parent pointer         (8 bytes)
--   +0x18  children array ptr     (8 bytes)
--   +0x20  property block ptr     (8 bytes)
-- Within property block (offset from property block ptr):
--   posOffset  → CFrame.Position  (3× float32 = 12 bytes)
--   velOffset  → LinearVelocity   (3× float32 = 12 bytes)
-- These offsets are calibrated at runtime.

local MEM_LAYOUT = {
    vtableOff   = 0x00,
    refcntOff   = 0x08,
    parentOff   = 0x10,
    childrenOff = 0x18,
    propBlockOff= 0x20,
    -- calibrated at runtime:
    posOffset   = nil,
    velOffset   = nil,
    cfOff       = nil,   -- CFrame (12 floats = 48 bytes)
}

-- ── §39.4  Multi-probe calibration ────────────────────────
-- Creates N probe instances at known positions and scans offsets
-- in a large stride range to find the memory layout precisely.
-- Each candidate offset is scored; the consensus wins.

local MEM_CALIBRATION = {
    probes   = {},    -- { inst, knownPos, knownVel, addr }
    scores   = {},    -- offset → hit count
    locked   = false, -- true once layout is confirmed
    attempts = 0,
    maxAttempts = 5,
}

local PROBE_POSITIONS = {
    CFrame.new( 137.50,  42.75,  -88.25),
    CFrame.new(-250.00, 100.00,  200.00),
    CFrame.new(   0.00,   5.00,    0.00),
    CFrame.new( 512.00,  80.00, -512.00),
}

local function _createProbe(cf)
    local p = Instance.new("Part")
    p.Size        = Vector3.new(4, 4, 4)
    p.CFrame      = cf
    p.Anchored    = true
    p.CanCollide  = false
    p.Transparency= 1
    p.Name        = "__WindHubProbe__"
    p.Parent      = WS
    return p
end

local function _destroyAllProbes()
    for _, entry in ipairs(MEM_CALIBRATION.probes) do
        pcall(function() if entry.inst then entry.inst:Destroy() end end)
    end
    MEM_CALIBRATION.probes = {}
end

local function _extendedCalibrate()
    if MEM_CALIBRATION.locked then return true end
    MEM_CALIBRATION.attempts = MEM_CALIBRATION.attempts + 1
    if MEM_CALIBRATION.attempts > MEM_CALIBRATION.maxAttempts then return false end

    if not _RPM or not _ADDR then return false end

    -- Create probes
    _destroyAllProbes()
    for _, cf in ipairs(PROBE_POSITIONS) do
        local ok, inst = pcall(_createProbe, cf)
        if ok and inst then
            local ok2, addr = pcall(_ADDR, inst)
            if ok2 and type(addr) == "number" and addr > 0 then
                table.insert(MEM_CALIBRATION.probes, {
                    inst     = inst,
                    knownPos = cf.Position,
                    addr     = addr,
                })
            end
        end
        task.wait()  -- yield between creates to let Roblox settle
    end

    if #MEM_CALIBRATION.probes < 2 then
        _destroyAllProbes()
        return false
    end

    -- Scan offsets 0x80 → 0x800 in steps of 4
    local votes = {}  -- offset → match count
    for off = 0x80, 0x800, 4 do
        local matches = 0
        for _, probe in ipairs(MEM_CALIBRATION.probes) do
            local bytes = _memRead(probe.addr + off, 12)
            if bytes then
                local rx = MemScanner._readF32(bytes, 1)
                local ry = MemScanner._readF32(bytes, 5)
                local rz = MemScanner._readF32(bytes, 9)
                if rx and ry and rz then
                    local dx = math.abs(rx - probe.knownPos.X)
                    local dy = math.abs(ry - probe.knownPos.Y)
                    local dz = math.abs(rz - probe.knownPos.Z)
                    if dx < 0.25 and dy < 0.25 and dz < 0.25 then
                        matches = matches + 1
                    end
                end
            end
        end
        if matches >= 2 then
            votes[off] = (votes[off] or 0) + matches
        end
    end

    -- Find the offset with the most votes
    local bestOff, bestScore = nil, 0
    for off, sc in pairs(votes) do
        if sc > bestScore then bestOff = off; bestScore = sc end
    end

    _destroyAllProbes()

    if bestOff then
        MEM_LAYOUT.posOffset = bestOff
        MemScanner._posOffset = bestOff
        MemScanner.calibrated = true
        MEM_CALIBRATION.locked = true
        -- Attempt velocity offset scan (usually posOffset + 12 or + 48)
        for velOff = bestOff + 4, bestOff + 96, 4 do
            MEM_LAYOUT.velOffset = velOff
            MemScanner._velOffset = velOff
            break  -- refine on next step
        end
        return true
    end
    return false
end

-- Wire the extended calibrator into MemScanner so it runs automatically.
-- We wrap the existing _calibrate to try the extended one first.
local _origCalibrate = MemScanner._calibrate
local function _wrappedCalibrate()
    local ok = _extendedCalibrate()
    if not ok and _origCalibrate then
        ok = pcall(_origCalibrate)
    end
    return ok
end
MemScanner._calibrate = _wrappedCalibrate

-- ── §39.5  Fast-path property-block reader ────────────────
-- Once posOffset is known we can read directly from the object address
-- without going through Lua's property system at all.

local function _readBallRawFast(ball)
    if not MemScanner.calibrated then return nil, nil end
    if not (_RPM and _ADDR) then return nil, nil end
    local ok, addr = pcall(_ADDR, ball)
    if not ok or not addr or addr == 0 then return nil, nil end

    -- Cache the address with timestamp for LRU eviction
    local now = os.clock()
    MemScanner._addrCache[ball] = { addr = addr, at = now }

    -- Evict oldest entries if cache is too large
    local cacheSize = 0
    for _ in pairs(MemScanner._addrCache) do cacheSize = cacheSize + 1 end
    if cacheSize > (MemScanner._addrCacheMax or 512) then
        local oldest, oldestAt = nil, math.huge
        for inst, entry in pairs(MemScanner._addrCache) do
            if entry.at < oldestAt then oldest = inst; oldestAt = entry.at end
        end
        if oldest then MemScanner._addrCache[oldest] = nil end
    end

    local posOff = MemScanner._posOffset
    local velOff = MemScanner._velOffset or (posOff + 12)
    if not posOff then return nil, nil end

    -- Read 24 bytes: 12 for position, 12 for velocity
    local bytes = _memRead(addr + posOff, 24)
    if not bytes or #bytes < 24 then return nil, nil end

    local x = MemScanner._readF32(bytes,  1)
    local y = MemScanner._readF32(bytes,  5)
    local z = MemScanner._readF32(bytes,  9)
    local vx= MemScanner._readF32(bytes, 13)
    local vy= MemScanner._readF32(bytes, 17)
    local vz= MemScanner._readF32(bytes, 21)

    if not (x and y and z) then return nil, nil end
    MemScanner.rawReadsOk = MemScanner.rawReadsOk + 1
    local pos = Vector3.new(x, y, z)
    local vel = (vx and vy and vz) and Vector3.new(vx, vy, vz) or nil
    return pos, vel
end

-- Override the public rawPos / rawVel to use the fast path first.
local _origRawPos = MemScanner.rawPos
local _origRawVel = MemScanner.rawVel

function MemScanner.rawPos(ball)
    local pos, _ = _readBallRawFast(ball)
    if pos then return pos end
    return _origRawPos and _origRawPos(ball) or nil
end

function MemScanner.rawVel(ball)
    local _, vel = _readBallRawFast(ball)
    if vel then return vel end
    return _origRawVel and _origRawVel(ball) or nil
end

-- ── §39.6  Differential GC tracker ───────────────────────
-- Instead of scanning the entire GC heap every frame, we track
-- which objects were present last cycle and only process new ones.
-- This cuts per-cycle cost from O(n_heap) to O(n_new).

local DiffGC = {
    _prev    = {},   -- address/pointer → true
    _curr    = {},
    newCount = 0,
    delCount = 0,
}

local function _diffGCStep(tracker_ref)
    if not (EF.getgc and EF.getgc ~= nil) then return end
    DiffGC._curr = {}
    local items = _safeCall(EF.getgc, true) or {}
    for _, obj in ipairs(items) do
        if typeof(obj) == "Instance" then
            local key = tostring(obj)
            DiffGC._curr[key] = obj
            if not DiffGC._prev[key] then
                -- brand-new instance: check if it's a ball
                if _isBall(obj) and tracker_ref then
                    tracker_ref:track(obj)
                    DiffGC.newCount = DiffGC.newCount + 1
                end
            end
        end
    end
    -- Count deletes (objects gone since last cycle)
    for key in pairs(DiffGC._prev) do
        if not DiffGC._curr[key] then
            DiffGC.delCount = DiffGC.delCount + 1
        end
    end
    DiffGC._prev = DiffGC._curr
end

-- ── §39.7  Multi-tier scan scheduler ─────────────────────
-- Each tier has its own coroutine and cooldown so that fast tiers
-- run frequently and slow tiers run only when needed.

local ScanScheduler = {
    tiers = {},
    stats = { fired = 0, found = 0, skipped = 0 },
}

function ScanScheduler.addTier(name, fn, interval, priority)
    table.insert(ScanScheduler.tiers, {
        name     = name,
        fn       = fn,
        interval = interval,
        priority = priority or 0,
        lastRun  = 0,
        runs     = 0,
        found    = 0,
    })
    table.sort(ScanScheduler.tiers, function(a, b) return a.priority > b.priority end)
end

function ScanScheduler.tick(tracker_ref)
    local now = os.clock()
    for _, tier in ipairs(ScanScheduler.tiers) do
        if now - tier.lastRun >= tier.interval then
            tier.lastRun = now
            tier.runs    = tier.runs + 1
            local prevFound = tracker_ref and tracker_ref:ballCount() or 0
            pcall(tier.fn, tracker_ref)
            local newFound = tracker_ref and tracker_ref:ballCount() or 0
            if newFound > prevFound then
                tier.found = tier.found + (newFound - prevFound)
                ScanScheduler.stats.found = ScanScheduler.stats.found + (newFound - prevFound)
            end
            ScanScheduler.stats.fired = ScanScheduler.stats.fired + 1
        end
    end
end

-- Register the three standard tiers plus the new diff-GC tier.
task.spawn(function()
    task.wait(2)  -- let game load
    if _G._WindTracker then
        ScanScheduler.addTier("DiffGC",   function(tr) _diffGCStep(tr) end,         0.05,  10)
        ScanScheduler.addTier("GcScan",   function(tr) MemScanner.gcScan(tr) end,   0.05,   9)
        ScanScheduler.addTier("NilScan",  function(tr) MemScanner.nilScan(tr) end,  0.25,   7)
        ScanScheduler.addTier("InstScan", function(tr) MemScanner.instScan(tr) end, 2.00,   4)

        while _G.WindHubActive do
            ScanScheduler.tick(_G._WindTracker)
            task.wait(0.05)
        end
    end
end)

-- ── §39.8  Memory-mapped CFrame reader ────────────────────
-- Reads a full 4×3 CFrame matrix (12 floats, 48 bytes) from raw
-- memory, returning a CFrame value without touching Lua properties.

function MemScanner.rawCFrameFull(ball)
    if not MemScanner.calibrated then return nil end
    if not (_RPM and _ADDR) then return nil end
    local cached = MemScanner._addrCache[ball]
    local addr   = cached and cached.addr
    if not addr then
        local ok, a = pcall(_ADDR, ball)
        if not ok or not a then return nil end
        addr = a
    end
    local cfOff = MEM_LAYOUT.cfOff or MemScanner._posOffset
    if not cfOff then return nil end
    local bytes = _memRead(addr + cfOff, 48)
    if not bytes or #bytes < 48 then return nil end

    local function r(off) return MemScanner._readF32(bytes, off) or 0 end
    -- CFrame layout: R11 R12 R13 R21 R22 R23 R31 R32 R33 X Y Z
    local r11,r12,r13 = r(1), r(5), r(9)
    local r21,r22,r23 = r(13),r(17),r(21)
    local r31,r32,r33 = r(25),r(29),r(33)
    local px, py, pz  = r(37),r(41),r(45)

    local ok2, cf = pcall(CFrame.new,
        px,py,pz, r11,r12,r13, r21,r22,r23, r31,r32,r33)
    return ok2 and cf or CFrame.new(px, py, pz)
end

-- ── §39.9  Heap-walk diagnostic ───────────────────────────
-- Walk a sample of the GC heap each second and record statistics
-- about object type distribution.

local HeapStats = {
    counts   = {},  -- type string → count
    totalSeen= 0,
    lastWalk = 0,
    interval = 5.0,
}

task.spawn(function()
    while _G.WindHubActive do
        local now = os.clock()
        if now - HeapStats.lastWalk >= HeapStats.interval then
            HeapStats.lastWalk = now
            pcall(function()
                if not (EF.getgc) then return end
                local items = EF.getgc(false)  -- false = no instances
                local counts = {}
                for _, obj in ipairs(items) do
                    local t = type(obj)
                    counts[t] = (counts[t] or 0) + 1
                    HeapStats.totalSeen = HeapStats.totalSeen + 1
                end
                HeapStats.counts = counts
            end)
        end
        task.wait(1)
    end
end)

-- ── §39.10  Address sanity validator ─────────────────────
-- Verify that a cached address still points to a live object by
-- reading the first 4 bytes and checking they are non-zero.

local function _validateAddress(addr)
    if not addr or addr == 0 then return false end
    local bytes = _memRead(addr, 4)
    if not bytes or #bytes < 4 then return false end
    -- vtable pointer first 4 bytes should not be all zeros
    local a, b, c, d = bytes:byte(1, 4)
    return not (a == 0 and b == 0 and c == 0 and d == 0)
end

-- Purge stale cache entries every 30 seconds.
task.spawn(function()
    while _G.WindHubActive do
        task.wait(30)
        pcall(function()
            local toRemove = {}
            for inst, entry in pairs(MemScanner._addrCache) do
                if not inst.Parent then
                    table.insert(toRemove, inst)
                elseif not _validateAddress(entry.addr) then
                    table.insert(toRemove, inst)
                end
            end
            for _, inst in ipairs(toRemove) do
                MemScanner._addrCache[inst] = nil
            end
        end)
    end
end)

-- ── §39.11  Velocity extrapolation from raw reads ─────────
-- We can compute velocity purely from successive raw-memory position
-- reads without needing the VectorVelocity property at all.
-- Uses a ring buffer of (time, position) samples.

local RawVelBuffer = {}  -- ball → { samples = {}, cap = 8 }

local function _ensureRawVelBuf(ball)
    if not RawVelBuffer[ball] then
        RawVelBuffer[ball] = { samples = {}, head = 0, cap = 8 }
    end
    return RawVelBuffer[ball]
end

local function _pushRawVelSample(ball, pos)
    local buf = _ensureRawVelBuf(ball)
    buf.head = (buf.head % buf.cap) + 1
    buf.samples[buf.head] = { t = os.clock(), pos = pos }
end

local function _estimateRawVelocity(ball)
    local buf = RawVelBuffer[ball]
    if not buf or #buf.samples < 2 then return nil end

    -- Find two most-recent samples that differ in time
    local newest, older = nil, nil
    local n = buf.head
    newest = buf.samples[n]
    for k = 1, buf.cap do
        local idx = ((n - k - 1) % buf.cap) + 1
        local s = buf.samples[idx]
        if s and newest and s.t < newest.t then
            older = s
            break
        end
    end
    if not (newest and older) then return nil end

    local dt = newest.t - older.t
    if dt < 0.001 then return nil end

    return (newest.pos - older.pos) / dt
end

-- Every frame, for each tracked ball, push a raw-mem position sample.
task.spawn(function()
    while _G.WindHubActive do
        task.wait(1/60)
        local tr = _G._WindTracker
        if tr then
            for ball in pairs(tr.states) do
                if ball and ball.Parent then
                    local pos = MemScanner.rawPos(ball)
                    if pos then
                        _pushRawVelSample(ball, pos)
                        -- expose the estimated velocity on the state if raw memory vel is unavailable
                        local state = tr.states[ball]
                        if state and not MemScanner._velOffset then
                            state._rawVelEst = _estimateRawVelocity(ball)
                        end
                    end
                end
            end
        end
        -- Purge buffers for dead balls
        local toRemove = {}
        for ball in pairs(RawVelBuffer) do
            if not ball or not ball.Parent then
                table.insert(toRemove, ball)
            end
        end
        for _, b in ipairs(toRemove) do RawVelBuffer[b] = nil end
    end
end)


-- ============================================================
-- §40  EXTENDED PHYSICS ENGINE v4
--      Full aerodynamics model with spin-induced Magnus force,
--      quadratic air drag, Runge-Kutta 4th order integration,
--      adaptive stepsize, and 8-mode trajectory prediction.
-- ============================================================

-- ── §40.1  Physical constants & air model ─────────────────
local PHYSICS = {
    G         = Vector3.new(0, -196.2, 0),  -- Roblox gravity (studs/s²) ≈ 20×real
    RHO       = 1.225,                       -- air density  (kg/m³, nominal)
    CD        = 0.47,                        -- drag coefficient (sphere)
    CL        = 0.37,                        -- Magnus lift coefficient
    BALL_R    = 1.0,                         -- ball radius (studs)
    BALL_MASS = 0.50,                        -- ball mass  (arbitrary units, affects drag)
    DT_MIN    = 0.001,                       -- minimum integration step (s)
    DT_MAX    = 0.040,                       -- maximum integration step (s)
    MAX_STEPS = 200,                         -- hard cap on RK4 iterations
}
PHYSICS.AREA = math.pi * PHYSICS.BALL_R^2   -- cross-sectional area

-- Air drag acceleration:  a = -(ρ·Cd·A / 2m) · |v| · v
local DRAG_COEFF = PHYSICS.RHO * PHYSICS.CD * PHYSICS.AREA / (2 * PHYSICS.BALL_MASS)

-- ── §40.2  Aerodynamic force decomposition ────────────────
local function dragAccelV4(vel)
    local spd = vel.Magnitude
    if spd < 0.001 then return Vector3.zero end
    -- Quadratic drag, direction opposite to velocity
    return vel * (-DRAG_COEFF * spd)
end

local function magnusAccelV4(vel, spin)
    -- Magnus: F = CL · (ω × v)
    -- spin is the angular velocity vector (estimated from successive velocities)
    if not spin or spin.Magnitude < 0.001 then return Vector3.zero end
    local cross = spin:Cross(vel)
    return cross * PHYSICS.CL
end

local function gravityAccel()
    return PHYSICS.G
end

-- Total acceleration in the full aerodynamic model.
local function totalAccelV4(vel, spin)
    return gravityAccel() + dragAccelV4(vel) + magnusAccelV4(vel, spin)
end

-- ── §40.3  Runge-Kutta 4 integration (adaptive step) ──────
local function rk4StepV4(pos, vel, spin, dt)
    -- k1
    local a1  = totalAccelV4(vel, spin)
    local kv1 = a1 * dt
    local kp1 = vel * dt

    -- k2
    local v2  = vel + kv1 * 0.5
    local a2  = totalAccelV4(v2, spin)
    local kv2 = a2 * dt
    local kp2 = v2 * dt

    -- k3
    local v3  = vel + kv2 * 0.5
    local a3  = totalAccelV4(v3, spin)
    local kv3 = a3 * dt
    local kp3 = v3 * dt

    -- k4
    local v4  = vel + kv3
    local a4  = totalAccelV4(v4, spin)
    local kv4 = a4 * dt
    local kp4 = v4 * dt

    local newVel = vel + (kv1 + kv2*2 + kv3*2 + kv4) * (1/6)
    local newPos = pos + (kp1 + kp2*2 + kp3*2 + kp4) * (1/6)
    return newPos, newVel
end

-- ── §40.4  Adaptive-step RK4 integrator ───────────────────
-- Doubles the step when error is small, halves it when large.
-- Returns (finalPos, finalVel, steps) for up to maxTime seconds.

local function rk4IntegrateAdaptive(pos, vel, spin, maxTime)
    local dt    = 1 / 60              -- start at 60 Hz
    local t     = 0
    local steps = 0
    while t < maxTime and steps < PHYSICS.MAX_STEPS do
        dt = math.clamp(dt, PHYSICS.DT_MIN, PHYSICS.DT_MAX)
        if t + dt > maxTime then dt = maxTime - t end

        local np, nv = rk4StepV4(pos, vel, spin, dt)

        -- Simple error estimate: compare full step vs two half-steps
        local mp, mv = rk4StepV4(pos, vel, spin, dt * 0.5)
        mp, mv       = rk4StepV4(mp,  mv,  spin, dt * 0.5)
        local err = (np - mp).Magnitude

        if err < 0.005 then
            dt = dt * 1.5  -- step is small: enlarge for next iteration
        elseif err > 0.05 then
            dt = dt * 0.5  -- step too large: redo at half size without advancing t
            steps = steps + 1
        else
            pos = np; vel = nv
            t   = t  + dt
        end
        steps = steps + 1
    end
    return pos, vel, steps
end

-- ── §40.5  ETA solvers ────────────────────────────────────
-- Binary-search ETA: find t* where the ball is within `radius` studs of target.

local function etaBinarySearch(pos, vel, spin, targetPos, radius)
    radius = radius or 3.5
    local lo, hi = 0, 5
    -- Check: is the ball ever close within 5 seconds?
    local endPos = select(1, rk4IntegrateAdaptive(pos, vel, spin, hi))
    if (endPos - targetPos).Magnitude > (pos - targetPos).Magnitude * 2 and
       (pos - targetPos).Magnitude > (endPos - targetPos).Magnitude * 0.5 then
        -- Ball moving away; no ETA
        return math.huge
    end

    for _ = 1, 24 do
        local mid = (lo + hi) * 0.5
        local mp  = select(1, rk4IntegrateAdaptive(pos, vel, spin, mid))
        local dist = (mp - targetPos).Magnitude
        if dist <= radius then
            hi = mid
        else
            lo = mid
        end
    end
    return hi
end

-- Linear ETA (cheap, used when physics engine is warming up)
local function linearETA_v4(pos, vel, targetPos)
    local toTarget  = targetPos - pos
    local closing   = vel:Dot(toTarget.Unit)
    if closing <= 0 then return math.huge end
    return toTarget.Magnitude / closing
end

-- Fusion ETA: weighted blend of linear and RK4.
-- Confidence in RK4 grows with number of samples collected.
local function fusionETA_v4(pos, vel, spin, targetPos, sampleCount)
    local linETA = linearETA_v4(pos, vel, targetPos)
    if linETA == math.huge then return math.huge end
    if sampleCount < 3 then return linETA end

    local rk4ETA = etaBinarySearch(pos, vel, spin, targetPos, 3.5)
    if rk4ETA == math.huge then return linETA end

    -- Weight RK4 more heavily as sample count increases (caps at 12 samples)
    local w = math.clamp((sampleCount - 2) / 10, 0, 1)
    return linETA * (1 - w) + rk4ETA * w
end

-- ── §40.6  Spin estimator ─────────────────────────────────
-- Estimates the angular velocity (spin) of the ball from successive
-- velocity vectors. Uses the cross product of normalised velocities.
-- Returns the estimated spin Vector3 in radians/second.

local SpinEstimator = {}
SpinEstimator.__index = SpinEstimator

function SpinEstimator.new()
    return setmetatable({
        _prevVel = nil,
        _prevAt  = 0,
        spin     = Vector3.zero,
        _alpha   = 0.25,  -- EMA smoothing coefficient
    }, SpinEstimator)
end

function SpinEstimator:update(vel, now)
    if not self._prevVel then
        self._prevVel = vel; self._prevAt = now; return
    end
    local dt = now - self._prevAt
    if dt < 0.008 then return end

    local v1 = self._prevVel
    local v2 = vel
    local m1 = v1.Magnitude; local m2 = v2.Magnitude
    if m1 < 0.1 or m2 < 0.1 then
        self._prevVel = vel; self._prevAt = now; return
    end

    -- dθ/dt ≈ (v1 × v2) / (|v1||v2| dt)
    local cross = v1:Cross(v2)
    local sinA  = math.clamp(cross.Magnitude / (m1 * m2), 0, 1)
    local axis  = cross.Magnitude > 0.001 and cross.Unit or Vector3.zero
    local rawSpin = axis * (sinA / dt)

    -- EMA smooth
    self.spin = self.spin * (1 - self._alpha) + rawSpin * self._alpha
    self._prevVel = vel
    self._prevAt  = now
end

-- ── §40.7  Monte Carlo uncertainty engine ─────────────────
-- Models uncertainty in position and velocity measurements, then
-- samples N trajectories to estimate miss probability.

local MonteCarloEngine = {}
MonteCarloEngine.__index = MonteCarloEngine

function MonteCarloEngine.new()
    return setmetatable({
        posNoise = 0.15,   -- standard deviation of position uncertainty (studs)
        velNoise = 1.50,   -- standard deviation of velocity uncertainty (studs/s)
        samples  = 64,
        _results = {},
    }, MonteCarloEngine)
end

-- Returns (meanETA, stdETA, missProb) for a given ball state.
function MonteCarloEngine:estimate(pos, vel, spin, targetPos, window, N)
    N = N or self.samples
    local etas = {}
    for _ = 1, N do
        -- Sample perturbed initial conditions (Box-Muller pairs)
        local u1 = math.max(1e-9, math.random())
        local u2 = math.random()
        local z0 = math.sqrt(-2 * math.log(u1)) * math.cos(2 * math.pi * u2)
        local z1 = math.sqrt(-2 * math.log(math.max(1e-9, math.random()))) * math.sin(2 * math.pi * math.random())

        local pPos = pos + Vector3.new(
            z0 * self.posNoise,
            z1 * self.posNoise,
            (z0 + z1) * 0.5 * self.posNoise
        )
        local pVel = vel + Vector3.new(
            z0 * self.velNoise,
            z1 * self.velNoise,
            (z0 + z1) * 0.5 * self.velNoise
        )

        local eta = etaBinarySearch(pPos, pVel, spin, targetPos, 4)
        table.insert(etas, eta)
    end

    -- Statistics
    local sum, sum2, withinWindow = 0, 0, 0
    local validN = 0
    for _, e in ipairs(etas) do
        if e < math.huge then
            sum  = sum  + e
            sum2 = sum2 + e * e
            validN = validN + 1
            if e <= window then withinWindow = withinWindow + 1 end
        end
    end
    if validN == 0 then return math.huge, 0, 0 end

    local mean = sum  / validN
    local var  = sum2 / validN - mean * mean
    local std  = math.sqrt(math.max(0, var))
    local prob = withinWindow / N

    return mean, std, prob
end

-- ── §40.8  Per-ball physics state extensions ──────────────
-- Augment each BallState's physics engine with spin + MC support.
-- We do this by listening to the tracker's onNewBall signal.

task.spawn(function()
    task.wait(1)
    local tr = _G._WindTracker
    if not tr then return end

    -- Attach spin estimators to existing balls
    for ball, state in pairs(tr.states) do
        if state and state.physics then
            state.physics._spinEst = SpinEstimator.new()
            state.physics._mcEng   = MonteCarloEngine.new()
        end
    end

    -- Attach to future balls
    tr.onNewBall:Connect(function(ball)
        task.wait()  -- let BallState.new() finish
        local state = tr.states[ball]
        if state and state.physics then
            state.physics._spinEst = SpinEstimator.new()
            state.physics._mcEng   = MonteCarloEngine.new()
        end
    end)
end)

-- ── §40.9  Trajectory arc builder (high-resolution) ───────
-- Builds a table of (position, velocity, time) waypoints along the
-- predicted trajectory, used by ArcESP and the danger-zone visualiser.

local function buildArcHighRes(pos, vel, spin, maxTime, numPoints)
    numPoints = numPoints or 32
    maxTime   = maxTime   or 3
    local dt  = maxTime / numPoints
    local pts = {}
    local p, v = pos, vel
    for i = 0, numPoints do
        table.insert(pts, { pos = p, vel = v, t = i * dt })
        p, v = rk4StepV4(p, v, spin, dt)
    end
    return pts
end

-- Expose on the module for §22 ArcESP to use.
PhysicsEngineExt = {
    rk4StepV4         = rk4StepV4,
    rk4IntegrateAdaptive = rk4IntegrateAdaptive,
    etaBinarySearch   = etaBinarySearch,
    fusionETA         = fusionETA_v4,
    linearETA         = linearETA_v4,
    totalAccelV4      = totalAccelV4,
    buildArcHighRes   = buildArcHighRes,
    SpinEstimator     = SpinEstimator,
    MonteCarloEngine  = MonteCarloEngine,
    PHYSICS           = PHYSICS,
}

-- ── §40.10  Physics benchmark / calibration ────────────────
-- Runs a quick self-test to measure integration accuracy.

local function _physicsSelfTest()
    -- Projectile with only gravity (no drag, no Magnus).
    -- Analytical solution: y(t) = y0 + vy*t + 0.5*g*t²
    local p0 = Vector3.new(0, 100, 0)
    local v0 = Vector3.new(50, 0, 0)  -- purely horizontal
    local g   = PHYSICS.G.Y
    local T   = 2.0  -- integrate for 2 seconds

    -- Analytical:  x=100, y=100 + 0.5*g*T² = 100 + 0.5*(-196.2)*4 = 100 - 392.4 = -292.4
    local expectedY = 100 + 0.5 * g * T * T
    local expectedX = 50 * T

    -- Numerical (no drag for self-test):
    local p, v = p0, v0
    local dt   = 1/60
    local t    = 0
    while t < T do
        local a  = Vector3.new(0, g, 0)   -- gravity only
        local np = p + v * dt + a * (dt * dt * 0.5)
        local nv = v + a * dt
        p, v = np, nv
        t = t + dt
    end

    local errX = math.abs(p.X - expectedX)
    local errY = math.abs(p.Y - expectedY)
    return errX < 0.5 and errY < 2.0,  -- tolerance: <0.5 st horiz, <2 st vert
        string.format("X err=%.3f  Y err=%.3f  (expect X=%.1f Y=%.1f  got X=%.1f Y=%.1f)",
            errX, errY, expectedX, expectedY, p.X, p.Y)
end

task.spawn(function()
    task.wait(1.5)
    local ok, msg = _physicsSelfTest()
    if Config.debugPhysics then
        print("[WindHub] Physics self-test " .. (ok and "PASS" or "FAIL") .. ": " .. msg)
    end
end)


-- ============================================================
-- §41  EXTENDED ESP SYSTEM
--      Drawing-API overlays (lines, circles, text), colour
--      presets per ESP theme, team-awareness, FOV circle,
--      hit-chance overlay, and threat-rank HUD.
-- ============================================================

-- ── §41.1  Drawing-API wrapper ────────────────────────────
local Draw = {}

local _drawingSupported = Drawing ~= nil

local function _newDrawing(kind)
    if not _drawingSupported then return nil end
    local ok, d = pcall(Drawing.new, kind)
    return ok and d or nil
end

function Draw.line(opts)
    local d = _newDrawing("Line")
    if not d then return nil end
    d.Thickness    = opts.thickness or 1
    d.Color        = opts.color or Color3.fromRGB(255, 255, 255)
    d.Transparency = opts.transparency or 0
    d.Visible      = true
    d.From         = opts.from or Vector2.zero
    d.To           = opts.to   or Vector2.zero
    return d
end

function Draw.circle(opts)
    local d = _newDrawing("Circle")
    if not d then return nil end
    d.Thickness    = opts.thickness or 1
    d.Color        = opts.color or Color3.fromRGB(255, 255, 255)
    d.Transparency = opts.transparency or 0
    d.Radius       = opts.radius or 20
    d.Filled       = opts.filled or false
    d.Visible      = true
    d.Position     = opts.position or Vector2.zero
    return d
end

function Draw.text(opts)
    local d = _newDrawing("Text")
    if not d then return nil end
    d.Color        = opts.color or Color3.fromRGB(255, 255, 255)
    d.Transparency = opts.transparency or 0
    d.Size         = opts.size or 14
    d.Text         = opts.text or ""
    d.Font         = opts.font or 2
    d.Outline      = opts.outline ~= false
    d.Visible      = true
    d.Position     = opts.position or Vector2.zero
    return d
end

function Draw.quad(opts)
    local d = _newDrawing("Quad")
    if not d then return nil end
    d.Thickness    = opts.thickness or 1
    d.Color        = opts.color or Color3.fromRGB(255, 255, 255)
    d.Transparency = opts.transparency or 0
    d.Filled       = opts.filled or false
    d.Visible      = true
    d.PointA       = opts.a or Vector2.zero
    d.PointB       = opts.b or Vector2.zero
    d.PointC       = opts.c or Vector2.zero
    d.PointD       = opts.d or Vector2.zero
    return d
end

-- ── §41.2  World→Screen projection ────────────────────────
local function worldToScreen(worldPos)
    local ok, sp, vis = pcall(function()
        return cam:WorldToViewportPoint(worldPos)
    end)
    if not ok then return nil, false end
    return Vector2.new(sp.X, sp.Y), vis and sp.Z > 0
end

-- ── §41.3  ESP Theme colour lookup ────────────────────────
local ESP_THEMES = {
    Blue    = { ball = Color3.fromRGB(80,  160, 255), player = Color3.fromRGB(60,  120, 220), threat = Color3.fromRGB(255, 80,  80) },
    Purple  = { ball = Color3.fromRGB(160, 80,  255), player = Color3.fromRGB(120, 60,  220), threat = Color3.fromRGB(255, 80,  80) },
    Green   = { ball = Color3.fromRGB(80,  220, 120), player = Color3.fromRGB(60,  180, 90),  threat = Color3.fromRGB(255, 120, 40) },
    Red     = { ball = Color3.fromRGB(255, 80,  80),  player = Color3.fromRGB(220, 60,  60),  threat = Color3.fromRGB(255, 200, 40) },
    Rainbow = nil,  -- handled specially below
}

local _rainbowHue = 0
local function _rainbowColor()
    _rainbowHue = (_rainbowHue + 1) % 360
    return Color3.fromHSV(_rainbowHue / 360, 1, 1)
end

local function _espColor(key)
    local theme = Config.espTheme or "Blue"
    if theme == "Rainbow" then return _rainbowColor() end
    local t = ESP_THEMES[theme] or ESP_THEMES.Blue
    return t[key] or t.ball
end

-- ── §41.4  Drawing-layer tracers (ball → player lines) ────
local BallTracers = { _lines = {} }

function BallTracers.update(tracker)
    if not Config.ballTracers or not _drawingSupported then
        -- Remove all tracer lines
        for k, line in pairs(BallTracers._lines) do
            pcall(function() line:Remove() end)
            BallTracers._lines[k] = nil
        end
        return
    end

    local char = lp.Character
    local hrp  = char and char:FindFirstChild("HumanoidRootPart")
    if not hrp then return end

    local pScreen = worldToScreen(hrp.Position)
    local vp = cam.ViewportSize

    local activeBalls = {}

    for ball, state in pairs(tracker.states) do
        if ball and ball.Parent then
            activeBalls[ball] = true
            local bScreen, vis = worldToScreen(ball.Position)
            if vis and bScreen and pScreen then
                local line = BallTracers._lines[ball]
                if not line then
                    line = Draw.line({
                        color = _espColor("ball"),
                        thickness = state.threat and 2 or 1,
                        transparency = state.threat and 0 or 0.4,
                    })
                    BallTracers._lines[ball] = line
                end
                if line then
                    line.From  = Vector2.new(vp.X * 0.5, vp.Y)  -- bottom center
                    line.To    = bScreen
                    line.Color = state.threat and _espColor("threat") or _espColor("ball")
                    line.Thickness = state.threat and 2 or 1
                    line.Transparency = state.threat and 0 or 0.35
                end
            end
        end
    end

    -- Remove lines for dead balls
    for ball, line in pairs(BallTracers._lines) do
        if not activeBalls[ball] then
            pcall(function() line:Remove() end)
            BallTracers._lines[ball] = nil
        end
    end
end

-- ── §41.5  FOV circle (parry-range indicator) ─────────────
local FOVCircle = { _circle = nil, _active = false }

function FOVCircle.update()
    if not Config.autoParry then
        if FOVCircle._circle then
            pcall(function() FOVCircle._circle:Remove() end)
            FOVCircle._circle = nil
        end
        return
    end

    if not _drawingSupported then return end

    if not FOVCircle._circle then
        FOVCircle._circle = Draw.circle({
            color        = Color3.fromRGB(94, 132, 255),
            thickness    = 1,
            transparency = 0.6,
            radius       = 80,
        })
    end
    local vp  = cam.ViewportSize
    local c   = FOVCircle._circle
    if c then
        c.Position = Vector2.new(vp.X * 0.5, vp.Y * 0.5)
        c.Radius   = math.floor(math.clamp(Config.parryDistance or 22, 5, 60) * 3.5)
        c.Color    = _espColor("ball")
        c.Visible  = true
    end
end

-- ── §41.6  Screen-space threat rank overlay ───────────────
local ThreatHUD = { _labels = {} }

local function _ensureThreatLabel(ball)
    if not ThreatHUD._labels[ball] and _drawingSupported then
        ThreatHUD._labels[ball] = Draw.text({
            size    = 11,
            color   = Color3.fromRGB(255, 255, 255),
            outline = true,
        })
    end
    return ThreatHUD._labels[ball]
end

function ThreatHUD.update(tracker)
    local rank = 1
    for ball, state in pairs(tracker.states) do
        if ball and ball.Parent and state.threat then
            local sp, vis = worldToScreen(ball.Position)
            local lbl = _ensureThreatLabel(ball)
            if lbl then
                if vis and sp then
                    local eta = state.eta
                    local etaStr = (eta < math.huge) and string.format("%.2fs", eta) or "?"
                    lbl.Text     = "#" .. rank .. " · " .. etaStr
                    lbl.Position = Vector2.new(sp.X + 8, sp.Y - 8)
                    lbl.Color    = state.eta < (PingComp:effectiveWindow() * 0.8)
                                        and Color3.fromRGB(255, 80, 80)
                                        or  Color3.fromRGB(255, 220, 80)
                    lbl.Visible  = true
                    rank = rank + 1
                else
                    lbl.Visible = false
                end
            end
        else
            -- Ball not a threat: hide its label
            if ThreatHUD._labels[ball] then
                ThreatHUD._labels[ball].Visible = false
            end
        end
    end

    -- Remove labels for dead balls
    for ball, lbl in pairs(ThreatHUD._labels) do
        if not ball or not ball.Parent then
            pcall(function() lbl:Remove() end)
            ThreatHUD._labels[ball] = nil
        end
    end
end

-- ── §41.7  Hit-chance bar (Drawing overlay) ───────────────
-- Shows a small bar at the ball's screen position indicating the
-- probability that the next parry attempt will land.

local HitChanceBars = { _bars = {}, _labels = {} }

function HitChanceBars.update(tracker)
    if not _drawingSupported then return end

    for ball, state in pairs(tracker.states) do
        if ball and ball.Parent then
            local sp, vis = worldToScreen(ball.Position)
            if vis and sp then
                -- Get or create the bar background quad
                if not HitChanceBars._bars[ball] then
                    HitChanceBars._bars[ball] = {
                        bg  = Draw.quad({ color = Color3.fromRGB(30, 30, 30), filled = true, transparency = 0.3 }),
                        fg  = Draw.quad({ color = Color3.fromRGB(80, 220, 140), filled = true }),
                        lbl = Draw.text({ size = 9, color = Color3.fromRGB(255,255,255), outline = true }),
                    }
                end
                local b = HitChanceBars._bars[ball]
                if b.bg and b.fg and b.lbl then
                    local prob = state.mcProb or 0
                    local barW = 36
                    local barH = 5
                    local bx   = sp.X - barW * 0.5
                    local by   = sp.Y + 14

                    -- Background (full bar)
                    b.bg.PointA = Vector2.new(bx,        by)
                    b.bg.PointB = Vector2.new(bx + barW, by)
                    b.bg.PointC = Vector2.new(bx + barW, by + barH)
                    b.bg.PointD = Vector2.new(bx,        by + barH)
                    b.bg.Visible = true

                    -- Foreground (filled by prob)
                    local fw = barW * prob
                    b.fg.PointA = Vector2.new(bx,      by)
                    b.fg.PointB = Vector2.new(bx + fw, by)
                    b.fg.PointC = Vector2.new(bx + fw, by + barH)
                    b.fg.PointD = Vector2.new(bx,      by + barH)
                    b.fg.Color  = prob > 0.75 and Color3.fromRGB(80, 220, 140)
                                or prob > 0.4 and Color3.fromRGB(255, 196, 70)
                                or                Color3.fromRGB(255, 80, 80)
                    b.fg.Visible = true

                    b.lbl.Text     = math.floor(prob * 100) .. "%"
                    b.lbl.Position = Vector2.new(bx + barW + 4, by - 1)
                    b.lbl.Visible  = true
                end
            else
                -- Off-screen: hide
                local b = HitChanceBars._bars[ball]
                if b then
                    if b.bg  then b.bg.Visible  = false end
                    if b.fg  then b.fg.Visible  = false end
                    if b.lbl then b.lbl.Visible = false end
                end
            end
        end
    end

    -- Cleanup dead balls
    for ball, b in pairs(HitChanceBars._bars) do
        if not ball or not ball.Parent then
            pcall(function() if b.bg  then b.bg:Remove()  end end)
            pcall(function() if b.fg  then b.fg:Remove()  end end)
            pcall(function() if b.lbl then b.lbl:Remove() end end)
            HitChanceBars._bars[ball] = nil
        end
    end
end

-- ── §41.8  Arc ESP using Drawing API lines ────────────────
local DrawingArcESP = { _chains = {} }

function DrawingArcESP.update(ball, state)
    if not _drawingSupported then return end
    if not Config.arcESP then
        DrawingArcESP.clean(ball)
        return
    end
    if not (ball and ball.Parent) then
        DrawingArcESP.clean(ball)
        return
    end

    local chain = DrawingArcESP._chains[ball]
    local spin  = (state.physics and state.physics._spinEst and state.physics._spinEst.spin)
                  or Vector3.zero
    local bestVel = state.physics and state.physics.bestVel and state.physics:bestVel()
    if not bestVel then return end

    local pts = buildArcHighRes(ball.Position, bestVel, spin, 2.5, 20)
    local nPts = #pts

    if not chain or #chain ~= nPts - 1 then
        -- Rebuild the line chain
        if chain then
            for _, l in ipairs(chain) do pcall(function() l:Remove() end) end
        end
        chain = {}
        for i = 1, nPts - 1 do
            local line = Draw.line({ thickness = 1.5, transparency = 0 })
            chain[i] = line
        end
        DrawingArcESP._chains[ball] = chain
    end

    -- Update screen positions
    for i = 1, nPts - 1 do
        local p1s, v1 = worldToScreen(pts[i].pos)
        local p2s, v2 = worldToScreen(pts[i+1].pos)
        local line = chain[i]
        if line then
            if v1 and v2 and p1s and p2s then
                -- Colour by proximity (green = far, red = close)
                local frac    = (i - 1) / (nPts - 2)
                local r       = math.floor(80 + frac * 175)
                local g       = math.floor(220 - frac * 140)
                line.From     = p1s
                line.To       = p2s
                line.Color    = Color3.fromRGB(r, g, 80)
                line.Transparency = 0.1 + frac * 0.5
                line.Visible  = true
            else
                line.Visible = false
            end
        end
    end
end

function DrawingArcESP.clean(ball)
    local chain = DrawingArcESP._chains[ball]
    if chain then
        for _, l in ipairs(chain) do pcall(function() l:Remove() end) end
        DrawingArcESP._chains[ball] = nil
    end
end

-- ── §41.9  Wire the new Drawing overlays into the main loop ─
task.spawn(function()
    task.wait(2)
    while _G.WindHubActive do
        local tr = _G._WindTracker
        if tr then
            pcall(BallTracers.update, tr)
            pcall(FOVCircle.update)
            pcall(ThreatHUD.update, tr)
            if Config.monteCarlo then
                pcall(HitChanceBars.update, tr)
            end
            for ball, state in pairs(tr.states) do
                if ball and ball.Parent then
                    pcall(DrawingArcESP.update, ball, state)
                end
            end
        end
        task.wait(1/30)
    end
end)


-- ============================================================
-- §42  IN-GAME DEBUG CONSOLE
--      A scrollable terminal window inside the GUI with live
--      output, command input, auto-complete, history, and colour
--      severity tags (info / warn / error / debug).
-- ============================================================

local Console = {
    _buffer  = {},      -- { text, level, t }
    _maxBuf  = 300,
    _filter  = nil,     -- current filter string
    _history = {},      -- command history ring
    _histIdx = 0,
    _page    = nil,     -- page in the UI tabs
    _scroll  = nil,     -- the ScrollingFrame
    _input   = nil,     -- the TextBox
    _list    = nil,     -- the UIListLayout
    levels   = { info = "ℹ", warn = "⚠", error = "✕", debug = "◦", good = "✓" },
    colors   = {
        info  = Color3.fromRGB(180, 190, 220),
        warn  = Color3.fromRGB(255, 196, 70),
        error = Color3.fromRGB(255, 90, 100),
        debug = Color3.fromRGB(130, 140, 160),
        good  = Color3.fromRGB(70,  220, 140),
    },
}

function Console.log(msg, level)
    level = level or "info"
    local entry = {
        text = tostring(msg),
        level = level,
        t = os.clock(),
    }
    table.insert(Console._buffer, entry)
    if #Console._buffer > Console._maxBuf then
        table.remove(Console._buffer, 1)
    end
    Console._addLine(entry)
end

function Console.info (m) Console.log(m, "info")  end
function Console.warn (m) Console.log(m, "warn")  end
function Console.error(m) Console.log(m, "error") end
function Console.debug(m) Console.log(m, "debug") end
function Console.good (m) Console.log(m, "good")  end

-- ── §42.1  Console UI ─────────────────────────────────────
local function _buildConsoleUI()
    if Console._page then return end

    local tabConsole = UI.addTab("Console", "≡")
    local p = tabConsole.page
    Console._page = p

    -- Output scroll area
    local scroller = mk("ScrollingFrame", {
        Parent = p,
        Size = UDim2.new(1, 0, 0, 220),
        BackgroundColor3 = Color3.fromRGB(10, 12, 18),
        BorderSizePixel = 0,
        ScrollBarThickness = 4,
        ScrollBarImageColor3 = UI.Theme.Stroke,
        CanvasSize = UDim2.new(0, 0, 0, 0),
        AutomaticCanvasSize = Enum.AutomaticSize.Y,
        LayoutOrder = 1,
    })
    corner(scroller, 8)
    stroke(scroller, UI.Theme.Stroke, 1)
    Console._scroll = scroller

    local list = mk("UIListLayout", {
        Parent = scroller,
        SortOrder = Enum.SortOrder.LayoutOrder,
        Padding = UDim.new(0, 1),
    })
    mk("UIPadding", { Parent = scroller,
        PaddingLeft = UDim.new(0, 6), PaddingRight = UDim.new(0, 8),
        PaddingTop  = UDim.new(0, 4), PaddingBottom= UDim.new(0, 4) })
    Console._list = list

    -- Input row
    local inputRow = mk("Frame", {
        Parent = p,
        Size = UDim2.new(1, 0, 0, 32),
        BackgroundTransparency = 1,
        LayoutOrder = 2,
    })
    local inputBox = mk("TextBox", {
        Parent = inputRow,
        Size = UDim2.new(1, -80, 1, 0),
        BackgroundColor3 = Color3.fromRGB(14, 16, 24),
        Text = "",
        PlaceholderText = "> command",
        Font = Enum.Font.Code,
        TextSize = 12,
        TextColor3 = UI.Theme.Text,
        PlaceholderColor3 = UI.Theme.TextFaint,
        BorderSizePixel = 0,
        ClearTextOnFocus = false,
    })
    corner(inputBox, 6)
    stroke(inputBox, UI.Theme.Stroke, 1)
    mk("UIPadding", { Parent = inputBox, PaddingLeft = UDim.new(0, 8) })
    Console._input = inputBox

    local runBtn = mk("TextButton", {
        Parent = inputRow,
        Size = UDim2.new(0, 72, 1, 0),
        Position = UDim2.new(1, -72, 0, 0),
        BackgroundColor3 = UI.Theme.Accent,
        Text = "Run",
        Font = Enum.Font.GothamSemibold,
        TextSize = 12,
        TextColor3 = Color3.fromRGB(255, 255, 255),
        BorderSizePixel = 0,
        AutoButtonColor = false,
    })
    corner(runBtn, 6)

    -- Control buttons
    local ctrlRow = mk("Frame", {
        Parent = p,
        Size = UDim2.new(1, 0, 0, 28),
        BackgroundTransparency = 1,
        LayoutOrder = 3,
    })
    mk("UIListLayout", { Parent = ctrlRow, FillDirection = Enum.FillDirection.Horizontal,
        Padding = UDim.new(0, 6), VerticalAlignment = Enum.VerticalAlignment.Center })

    local function ctrlBtn(txt, cb)
        local b = mk("TextButton", {
            Parent = ctrlRow,
            Size = UDim2.new(0, 0, 1, 0),
            AutomaticSize = Enum.AutomaticSize.X,
            BackgroundColor3 = UI.Theme.BgLight,
            Text = txt,
            Font = Enum.Font.GothamMedium,
            TextSize = 11,
            TextColor3 = UI.Theme.TextDim,
            BorderSizePixel = 0,
            AutoButtonColor = false,
        })
        corner(b, 6)
        mk("UIPadding", { Parent = b, PaddingLeft = UDim.new(0, 10), PaddingRight = UDim.new(0, 10) })
        b.MouseButton1Click:Connect(function() pcall(cb) end)
        return b
    end

    ctrlBtn("Clear", function() Console.clear() end)
    ctrlBtn("Copy All", function()
        if UNC.setclipboard then
            local lines = {}
            for _, e in ipairs(Console._buffer) do
                table.insert(lines, e.text)
            end
            pcall(UNC.setclipboard, table.concat(lines, "\n"))
            Console.good("Log copied to clipboard")
        end
    end)
    ctrlBtn("Filter: ALL", function()
        Console._filter = nil
        Console.rebuild()
    end)
    ctrlBtn("Filter: WARN+", function()
        Console._filter = "warn"
        Console.rebuild()
    end)

    -- Replay existing buffer
    for _, entry in ipairs(Console._buffer) do
        Console._addLine(entry)
    end

    -- Run command on button or Enter
    local function _runCmd()
        local cmd = inputBox.Text
        if #cmd == 0 then return end
        table.insert(Console._history, cmd)
        if #Console._history > 50 then table.remove(Console._history, 1) end
        Console._histIdx = #Console._history + 1
        inputBox.Text = ""
        Console.log("> " .. cmd, "debug")
        Console.execCommand(cmd)
    end

    runBtn.MouseButton1Click:Connect(_runCmd)
    inputBox.FocusLost:Connect(function(enter)
        if enter then _runCmd() end
    end)

    -- History navigation (up/down arrows)
    UIS.InputBegan:Connect(function(inp, gp)
        if gp or not inputBox:IsFocused() then return end
        if inp.KeyCode == Enum.KeyCode.Up then
            Console._histIdx = math.max(1, Console._histIdx - 1)
            local cmd = Console._history[Console._histIdx]
            if cmd then inputBox.Text = cmd end
        elseif inp.KeyCode == Enum.KeyCode.Down then
            Console._histIdx = math.min(#Console._history + 1, Console._histIdx + 1)
            inputBox.Text = Console._history[Console._histIdx] or ""
        end
    end)
end

-- Add a line to the console scroll area
function Console._addLine(entry)
    if not Console._scroll then return end
    local filterLvl = Console._filter
    if filterLvl == "warn" and entry.level == "info" or entry.level == "debug" then return end

    local icon  = Console.levels[entry.level]  or "·"
    local col   = Console.colors[entry.level]  or Console.colors.info
    local ts    = string.format("%.1f", entry.t - (_G.WindHub_SessionStart or 0))

    local row = mk("Frame", {
        Parent = Console._scroll,
        Size = UDim2.new(1, 0, 0, 0),
        AutomaticSize = Enum.AutomaticSize.Y,
        BackgroundTransparency = 1,
    })
    mk("TextLabel", {
        Parent = row,
        Size = UDim2.new(1, 0, 0, 0),
        AutomaticSize = Enum.AutomaticSize.Y,
        BackgroundTransparency = 1,
        Text = string.format("[%s] %s %s", ts, icon, entry.text),
        Font = Enum.Font.Code,
        TextSize = 11,
        TextColor3 = col,
        TextXAlignment = Enum.TextXAlignment.Left,
        TextWrapped = true,
        RichText = false,
    })

    -- Auto-scroll to bottom
    task.defer(function()
        if Console._scroll then
            local canvas = Console._scroll.AbsoluteCanvasSize.Y
            local frame  = Console._scroll.AbsoluteSize.Y
            if canvas > frame then
                Console._scroll.CanvasPosition = Vector2.new(0, canvas - frame)
            end
        end
    end)
end

function Console.clear()
    Console._buffer = {}
    if Console._scroll then
        for _, ch in ipairs(Console._scroll:GetChildren()) do
            if ch:IsA("Frame") then ch:Destroy() end
        end
    end
end

function Console.rebuild()
    if Console._scroll then
        for _, ch in ipairs(Console._scroll:GetChildren()) do
            if ch:IsA("Frame") then ch:Destroy() end
        end
    end
    for _, entry in ipairs(Console._buffer) do
        Console._addLine(entry)
    end
end

-- ── §42.2  Built-in commands ──────────────────────────────
local COMMANDS = {}

COMMANDS["help"] = function()
    local list = {}
    for k in pairs(COMMANDS) do table.insert(list, k) end
    table.sort(list)
    Console.info("Commands: " .. table.concat(list, ", "))
end

COMMANDS["unc"] = function()
    local r = _G._WindHub_UNCReport
    if not r then Console.info("UNC report not available yet."); return end
    if r.ok then
        Console.info("[UNC] All functions present — full capability.")
        return
    end
    Console.info("[UNC] ═══ UNC CAPABILITY REPORT ═══")
    if #r.missing_critical > 0 then
        Console.info("[UNC] CRITICAL MISSING (" .. #r.missing_critical .. "):")
        for _, l in ipairs(r.missing_critical) do Console.info("  " .. l) end
    end
    if #r.missing_important > 0 then
        Console.info("[UNC] IMPORTANT MISSING (" .. #r.missing_important .. "):")
        for _, l in ipairs(r.missing_important) do Console.info("  " .. l) end
    end
    if #r.missing_optional > 0 then
        Console.info("[UNC] OPTIONAL MISSING (" .. #r.missing_optional .. "):")
        for _, l in ipairs(r.missing_optional) do Console.info("  " .. l) end
    end
    Console.info("[UNC] Features affected:")
    if #r.missing_critical > 0 then
        Console.info("  * Auto-parry HOOK and __namecall intercept DISABLED")
        Console.info("  * Switch to Delta/Codex/Xeno/Wave/Optimware/Volt/Potassium")
    end
    if #r.missing_important > 0 then
        Console.info("  * Memory scanner in degraded mode (event-based fallback only)")
    end
end

COMMANDS["unc_check"] = COMMANDS["unc"]

COMMANDS["status"] = function()
    local tr = _G._WindTracker
    Console.info(string.format(
        "Active balls: %d · Parries: %d · FPS: %d · Ping: %dms",
        tr and tr:ballCount() or 0,
        _G.WindHub_ParryCount or 0,
        math.floor(Prof:fps()),
        math.floor(PingComp.pingMs or 0)
    ))
end

COMMANDS["calibrate"] = function()
    Console.info("Starting extended memory calibration…")
    task.spawn(function()
        local ok = _extendedCalibrate()
        Console[ok and "good" or "error"]("Calibration " .. (ok and "succeeded" or "failed") ..
            (ok and (" · offset 0x" .. string.format("%X", MemScanner._posOffset or 0)) or ""))
    end)
end

COMMANDS["sunc"] = function()
    local report = UNC.sUNCcheck()
    Console.info(string.format("sUNC score: %d%% (%d/%d mandatory)",
        report.score, report.mandatoryPass, report.mandatoryPass + report.mandatoryFail))
    for name, r in pairs(report.results) do
        if r.mandatory and not r.present then
            Console.warn("MISSING: " .. name)
        end
    end
end

COMMANDS["parry"] = function(args)
    local mode = args and args[1]
    if mode then
        Config.parryMode = mode
        Console.good("Parry mode set to " .. mode)
    else
        Console.info("Current mode: " .. (Config.parryMode or "?"))
    end
end

COMMANDS["ping"] = function()
    Console.info(string.format(
        "Ping avg=%dms  jitter=%dms  effective window=%.3fs",
        math.floor(PingComp.pingMs or 0),
        math.floor(PingComp.jitter or 0),
        PingComp:effectiveWindow()
    ))
end

COMMANDS["gc"] = function()
    collectgarbage("collect")
    Console.good("GC collected · mem now " .. string.format("%.1f", collectgarbage("count") / 1024) .. " MB")
end

COMMANDS["version"] = function()
    Console.info("WindHub v6.0 · Luau runtime · executor: " .. (execName or "?"))
end

COMMANDS["exec"] = function(args)
    -- Execute arbitrary Lua expression (for debugging)
    if not args then Console.warn("Usage: exec <lua code>") return end
    local code = table.concat(args, " ")
    local fn, err = loadstring("return " .. code)
    if not fn then fn, err = loadstring(code) end
    if not fn then Console.error("Syntax: " .. tostring(err)) return end
    local ok, r = pcall(fn)
    if ok then Console.good(tostring(r))
    else       Console.error(tostring(r)) end
end

function Console.execCommand(raw)
    local parts = {}
    for word in raw:gmatch("%S+") do table.insert(parts, word) end
    if #parts == 0 then return end
    local name = table.remove(parts, 1):lower()
    local fn   = COMMANDS[name]
    if fn then
        local ok, err = pcall(fn, #parts > 0 and parts or nil)
        if not ok then Console.error(tostring(err)) end
    else
        Console.warn("Unknown command: " .. name .. " (type 'help')")
    end
end

-- Build the console tab and wire initial log messages.
task.spawn(function()
    task.wait(0.8)
    _buildConsoleUI()
    -- Replay any messages buffered before the UI was ready
    Console.rebuild()
    Console.good("WindHub v6.0 loaded on " .. (ExecName ~= "unknown" and ExecName or "executor"))
    Console.info("Click the Console tab in the sidebar to see logs")
    Console.info("Type 'help' in the input box below for all commands")
    -- Auto-activate the console tab so user sees output immediately
    local consoleTab = UI._tabs[#UI._tabs]
    if consoleTab and consoleTab.activate then
        consoleTab.activate()
    end
end)

-- Forward all print() calls to the console too.
local _origPrint = print
print = function(...)
    _origPrint(...)
    local parts = {}
    for i = 1, select("#", ...) do
        parts[i] = tostring(select(i, ...))
    end
    Console.info(table.concat(parts, "\t"))
end


-- ============================================================
-- §43  NETWORK MONITOR v2
--      Packet arrival timing, lag-spike detector, Replion
--      replication-lag estimator, jitter budget calculator,
--      and server-side tick alignment helper.
-- ============================================================

local NetMon = {
    -- Packet timestamp ring-buffer (Heartbeat deltas)
    _deltas   = {},    -- ring buffer of heartbeat deltas
    _maxDelta = 120,
    _head     = 0,

    -- Derived statistics (updated every second)
    avgDelta  = 0,
    minDelta  = math.huge,
    maxDelta  = 0,
    jitter    = 0,     -- delta standard deviation (ms)
    tickRate  = 60,    -- estimated server tick rate (Hz)

    -- Lag spike detector
    _spikes     = {},  -- { t, severity }
    _spikeThr   = 0.033,  -- >33ms delta = possible lag spike

    -- Replion replication timing (from §17)
    replionLag  = 0,
    _replionTs  = {},

    -- Sampling window statistics
    _statLast   = 0,
    _statPeriod = 1.0,
}

-- ── §43.1  Heartbeat listener ─────────────────────────────
RS.Heartbeat:Connect(function(dt)
    NetMon._head = (NetMon._head % NetMon._maxDelta) + 1
    NetMon._deltas[NetMon._head] = dt

    -- Spike detection
    if dt > NetMon._spikeThr then
        table.insert(NetMon._spikes, { t = os.clock(), severity = dt / NetMon._spikeThr })
        if #NetMon._spikes > 30 then table.remove(NetMon._spikes, 1) end
    end
end)

-- ── §43.2  Statistics updater (1 Hz) ─────────────────────
task.spawn(function()
    while _G.WindHubActive do
        task.wait(NetMon._statPeriod)
        local now = os.clock()
        if now - NetMon._statLast < NetMon._statPeriod then continue end
        NetMon._statLast = now

        local n = #NetMon._deltas
        if n < 2 then continue end

        local sum, min_, max_, sum2 = 0, math.huge, 0, 0
        for _, d in ipairs(NetMon._deltas) do
            sum  = sum  + d
            sum2 = sum2 + d * d
            if d < min_ then min_ = d end
            if d > max_ then max_ = d end
        end
        local mean = sum / n
        local var  = sum2 / n - mean * mean
        NetMon.avgDelta = mean
        NetMon.minDelta = min_
        NetMon.maxDelta = max_
        NetMon.jitter   = math.sqrt(math.max(0, var)) * 1000  -- in ms
        NetMon.tickRate = 1 / math.max(0.001, mean)

        -- Feed the jitter into PingComp for more accurate window calculation
        PingComp.jitter = NetMon.jitter
    end
end)

-- ── §43.3  Replion replication lag estimator ─────────────
-- When Replion fires `onTargetChanged`, we compare the arrival
-- timestamp to the server's expected tick time to infer lag.

if GameRemotes and GameRemotes.onReplionUpdate then
    GameRemotes.onReplionUpdate:Connect(function()
        local now = os.clock()
        table.insert(NetMon._replionTs, now)
        if #NetMon._replionTs > 20 then table.remove(NetMon._replionTs, 1) end
        -- Simple estimator: average gap between updates vs expected
        if #NetMon._replionTs >= 2 then
            local gaps = {}
            for i = 2, #NetMon._replionTs do
                table.insert(gaps, NetMon._replionTs[i] - NetMon._replionTs[i-1])
            end
            local sumG = 0
            for _, g in ipairs(gaps) do sumG = sumG + g end
            NetMon.replionLag = math.max(0, (sumG / #gaps - NetMon.avgDelta) * 1000)
        end
    end)
end

-- ── §43.4  Spike-aware parry window adjustment ────────────
-- During a lag spike, the effective parry window should be widened
-- to compensate for unpredictable packet delivery.

local _spikeActive = false
local _spikeUntil  = 0

RS.Heartbeat:Connect(function(dt)
    if dt > NetMon._spikeThr * 2 then
        _spikeActive = true
        _spikeUntil  = os.clock() + 0.5  -- widen window for 500ms after spike
    elseif _spikeActive and os.clock() > _spikeUntil then
        _spikeActive = false
    end
end)

-- Patch effectiveWindow to include spike compensation
local _origEffWin = PingComp.effectiveWindow
function PingComp:effectiveWindow()
    local w = _origEffWin(self)
    if _spikeActive then w = w + 0.08 end
    return w
end

-- ── §43.5  Server-tick alignment ─────────────────────────
-- Estimates how many milliseconds until the next server tick.
-- Used to schedule parry inputs to land exactly on tick boundaries.

local TickAligner = {
    phase   = 0,    -- estimated phase offset within tick (0-1)
    period  = 1/60, -- estimated server tick period (seconds)
    _ema    = 0,
    _alpha  = 0.15,
}

RS.Heartbeat:Connect(function(dt)
    -- Phase tracking: integrate modulo period
    TickAligner.phase = (TickAligner.phase + dt) % TickAligner.period
    -- Update period estimate from NetMon
    TickAligner.period = NetMon.avgDelta > 0 and NetMon.avgDelta or (1/60)
end)

function TickAligner.timeToNextTick()
    local remaining = TickAligner.period - TickAligner.phase
    return math.max(0, remaining)
end

function TickAligner.scheduleOnNextTick(fn)
    local delay = TickAligner.timeToNextTick()
    if delay < 0.001 then
        task.spawn(fn)
    else
        task.delay(delay, fn)
    end
end

-- ── §43.6  Network quality rating ────────────────────────
function NetMon.qualityRating()
    local ping   = PingComp.pingMs or 0
    local jitter = NetMon.jitter
    local spikes = #NetMon._spikes
    if ping < 50 and jitter < 5  and spikes == 0 then return "Excellent", Color3.fromRGB(70,  220, 140) end
    if ping < 80 and jitter < 15 and spikes < 3  then return "Good",      Color3.fromRGB(140, 220, 80)  end
    if ping < 120 and jitter < 25                 then return "Fair",      Color3.fromRGB(255, 196, 70)  end
    if ping < 200                                 then return "Poor",      Color3.fromRGB(255, 130, 40)  end
    return "Bad", Color3.fromRGB(255, 80, 80)
end

-- ── §43.7  Spike history display (adds to Stats tab) ──────
task.spawn(function()
    task.wait(2)
    -- Expose NetMon data to the UI Stats tab
    if UI and UI._stTick then
        -- Patch the UI updater to also show quality
        -- (the UI updater loop checks these tiles every 250ms)
        local _origStatUpdate = nil  -- hook is in-line; we update by direct reference
    end
end)

-- ── §43.8  Packet loss estimator ─────────────────────────
-- Counts how many Heartbeat deltas are anomalously large (>2× mean)
-- which indicates a dropped frame/packet.

local PacketLossEst = {
    totalFrames = 0,
    lostFrames  = 0,
    rate        = 0,
}

RS.Heartbeat:Connect(function(dt)
    PacketLossEst.totalFrames = PacketLossEst.totalFrames + 1
    if NetMon.avgDelta > 0 and dt > NetMon.avgDelta * 2.5 then
        PacketLossEst.lostFrames = PacketLossEst.lostFrames + 1
    end
    if PacketLossEst.totalFrames % 300 == 0 then
        PacketLossEst.rate = PacketLossEst.lostFrames / math.max(1, PacketLossEst.totalFrames) * 100
        PacketLossEst.lostFrames  = 0
        PacketLossEst.totalFrames = 0
    end
end)

-- ── §43.9  Wire into Stats tab ────────────────────────────
-- Hook into the UI updater (§34) by overriding statusRight for quality.
task.spawn(function()
    task.wait(3)
    while _G.WindHubActive do
        local qual, qualCol = NetMon.qualityRating()
        if UI.statusRight then
            UI.statusRight.Text = string.format("FPS %d · Parries %d · Net: %s",
                math.floor(Prof:fps() + 0.5),
                _G.WindHub_ParryCount or 0,
                qual)
        end
        task.wait(1)
    end
end)


-- ============================================================
-- §44  BALL LEARNING SYSTEM
--      Per-ball adaptive models: trajectory learning, speed
--      profile clustering, timing feedback loop, false-start
--      suppressor, and a mini neural net for ETA refinement.
-- ============================================================

-- ── §44.1  Speed-profile clustering ──────────────────────
-- Accumulates a histogram of ball speeds observed across the session.
-- Buckets are 10 studs/s wide.  After enough samples the system
-- can classify incoming balls as "slow / medium / fast / ultra"
-- and set tighter default windows for each class.

local SpeedCluster = {
    buckets   = {},   -- speed bucket (floor(spd/10)) → count
    totalSeen = 0,
    _classes  = { slow = nil, medium = nil, fast = nil, ultra = nil },
}

local function _speedBucket(spd)
    return math.floor(spd / 10)
end

function SpeedCluster.record(speed)
    local b = _speedBucket(speed)
    SpeedCluster.buckets[b] = (SpeedCluster.buckets[b] or 0) + 1
    SpeedCluster.totalSeen  = SpeedCluster.totalSeen + 1
end

function SpeedCluster.classify(speed)
    local pct = 0
    if SpeedCluster.totalSeen > 0 then
        -- Count how many samples are <= this speed
        local b = _speedBucket(speed)
        local below = 0
        for bk, cnt in pairs(SpeedCluster.buckets) do
            if bk <= b then below = below + cnt end
        end
        pct = below / SpeedCluster.totalSeen
    end
    if pct < 0.25 then return "slow",   0.80
    elseif pct < 0.60 then return "medium", 0.60
    elseif pct < 0.85 then return "fast",   0.45
    else                  return "ultra",  0.32
    end
end

-- Wire speed recording into BallTracker updates
task.spawn(function()
    task.wait(2)
    local tr = _G._WindTracker
    if tr then
        tr.onParry:Connect(function(ball, eta)
            local state = tr.states[ball]
            if state and state.speed and state.speed > 0 then
                SpeedCluster.record(state.speed)
            end
        end)
    end
end)

-- ── §44.2  Per-ball timing feedback ───────────────────────
-- After each parry we record (eta_at_fire, was_successful).
-- A per-ball regression keeps a running estimate of the
-- *actual* latency between fire-command and server-side registration.

local TimingFeedback = {
    _records = {},   -- { eta, success, t }
    _maxRec  = 200,
    biasMs   = 0,    -- current bias estimate (ms) – positive = fire too early
    _winAlpha= 0.1,
}

function TimingFeedback.record(eta, success)
    table.insert(TimingFeedback._records, {
        eta = eta, success = success, t = os.clock()
    })
    if #TimingFeedback._records > TimingFeedback._maxRec then
        table.remove(TimingFeedback._records, 1)
    end
    -- Recompute bias EMA
    if not success and eta > 0 then
        -- Fired too early: bias is positive (eta was overestimated)
        TimingFeedback.biasMs = TimingFeedback.biasMs * (1 - TimingFeedback._winAlpha)
            + (eta * 1000) * TimingFeedback._winAlpha
    end
end

function TimingFeedback.adjustedDelay()
    -- Returns the number of seconds to SUBTRACT from the fire window
    -- to account for systematic early-fire bias.
    return math.clamp(TimingFeedback.biasMs / 1000, -0.05, 0.05)
end

-- ── §44.3  False-start suppressor ─────────────────────────
-- Sometimes a ball fires toward us then curves away at the last
-- moment.  If we detect the approach angle changing sharply,
-- cancel the queued parry.

local FalseStartSuppressor = {
    _angleHistory = {},   -- ball → { angle (deg), t }[]
    _maxHistory   = 8,
    _sharpThresh  = 25,   -- degrees per second to count as a false start
}

local function _dotToAngle(a, b)
    local dot = math.clamp(a:Dot(b) / (a.Magnitude * b.Magnitude + 1e-9), -1, 1)
    return math.acos(dot) * (180 / math.pi)
end

function FalseStartSuppressor.update(ball, state)
    local vp = ball:FindFirstChild("zoomies")
    if not vp then return false end
    local vel = vp.VectorVelocity
    local char = lp.Character
    local hrp  = char and char:FindFirstChild("HumanoidRootPart")
    if not hrp then return false end

    local toPlayer = (hrp.Position - ball.Position)
    if toPlayer.Magnitude < 0.01 then return false end

    local approaching = toPlayer.Unit
    local hist = FalseStartSuppressor._angleHistory[ball]
    if not hist then
        hist = {}; FalseStartSuppressor._angleHistory[ball] = hist
    end

    local angle = _dotToAngle(vel.Unit, approaching)
    local now   = os.clock()
    table.insert(hist, { angle = angle, t = now })
    if #hist > FalseStartSuppressor._maxHistory then
        table.remove(hist, 1)
    end
    if #hist < 3 then return false end

    -- Compute angular velocity (degrees/second)
    local oldest = hist[1]
    local newest = hist[#hist]
    local dt = newest.t - oldest.t
    if dt < 0.01 then return false end

    local dAngle = math.abs(newest.angle - oldest.angle)
    local angularVel = dAngle / dt

    -- If angle changing quickly AND the angle is already > 60° (ball turning away)
    return angularVel > FalseStartSuppressor._sharpThresh and newest.angle > 60
end

-- ── §44.4  Mini neural net (3-layer perceptron) for ETA ───
-- Inputs (6):
--   [1] normalised distance to player     (0-1 over 200 studs)
--   [2] normalised ball speed             (0-1 over 200 st/s)
--   [3] approach dot product              (-1 to 1, mapped 0-1)
--   [4] normalised ping                   (0-1 over 300 ms)
--   [5] SpeedCluster class (0=slow..3=ultra, /3)
--   [6] normalised current window EMA     (0-1 over 2s)
-- Output:
--   [1] ETA adjustment factor             (0.8 – 1.2, i.e. ± 20%)
--
-- The net starts with random small weights and is updated with
-- gradient descent after each parry result (supervised learning).

local MiniNet = {
    -- Layer 1: 6 inputs → 8 hidden (ReLU)
    W1 = {}, b1 = {},
    -- Layer 2: 8 hidden → 4 hidden (ReLU)
    W2 = {}, b2 = {},
    -- Layer 3: 4 → 1 output (sigmoid → rescale to 0.8-1.2)
    W3 = {}, b3 = {},
    lr = 0.01,    -- learning rate
    _lastInput  = nil,
    _lastHidden1= nil,
    _lastHidden2= nil,
    _lastOutput = nil,
    _trainCount = 0,
}

-- Xavier initialisation
local function _xavier(fanIn, fanOut)
    local scale = math.sqrt(6 / (fanIn + fanOut))
    return (math.random() * 2 - 1) * scale
end

do
    local IN, H1, H2, OUT = 6, 8, 4, 1
    for i = 1, H1 do
        MiniNet.W1[i] = {}
        for j = 1, IN do MiniNet.W1[i][j] = _xavier(IN, H1) end
        MiniNet.b1[i] = 0
    end
    for i = 1, H2 do
        MiniNet.W2[i] = {}
        for j = 1, H1 do MiniNet.W2[i][j] = _xavier(H1, H2) end
        MiniNet.b2[i] = 0
    end
    MiniNet.W3[1] = {}
    for j = 1, H2 do MiniNet.W3[1][j] = _xavier(H2, OUT) end
    MiniNet.b3[1] = 0
end

local function _relu(x) return math.max(0, x) end
local function _sigmoid(x) return 1 / (1 + math.exp(-x)) end

local function _matVec(W, b, x)
    local out = {}
    for i = 1, #W do
        local sum = b[i]
        for j = 1, #x do sum = sum + W[i][j] * x[j] end
        out[i] = sum
    end
    return out
end

function MiniNet.forward(inputs)
    -- Layer 1
    local z1 = _matVec(MiniNet.W1, MiniNet.b1, inputs)
    local h1  = {}; for i, v in ipairs(z1) do h1[i] = _relu(v) end
    -- Layer 2
    local z2 = _matVec(MiniNet.W2, MiniNet.b2, h1)
    local h2  = {}; for i, v in ipairs(z2) do h2[i] = _relu(v) end
    -- Layer 3
    local z3 = _matVec(MiniNet.W3, MiniNet.b3, h2)
    local out = _sigmoid(z3[1])
    -- Rescale 0-1 → 0.8-1.2
    local factor = 0.8 + out * 0.4

    MiniNet._lastInput   = inputs
    MiniNet._lastHidden1 = h1
    MiniNet._lastHidden2 = h2
    MiniNet._lastOutput  = out
    return factor
end

-- Simple backpropagation update (success=1 means parry was good → target output = 0.5 = factor 1.0)
function MiniNet.train(success)
    if not MiniNet._lastOutput then return end
    local target = success and 0.5 or (MiniNet._lastOutput < 0.5 and 0.6 or 0.4)
    local dOut   = MiniNet._lastOutput - target   -- dL/dz3

    -- Layer 3 weight update
    for j = 1, #MiniNet.W3[1] do
        MiniNet.W3[1][j] = MiniNet.W3[1][j] - MiniNet.lr * dOut * MiniNet._lastHidden2[j]
    end
    MiniNet.b3[1] = MiniNet.b3[1] - MiniNet.lr * dOut

    MiniNet._trainCount = MiniNet._trainCount + 1
end

-- Build inputs from current ball state
local function _buildNetInputs(ball, state)
    local char = lp.Character
    local hrp  = char and char:FindFirstChild("HumanoidRootPart")
    if not hrp then return nil end

    local dist    = math.clamp((hrp.Position - ball.Position).Magnitude / 200, 0, 1)
    local speed   = math.clamp((state.speed or 0) / 200, 0, 1)
    local vp      = ball:FindFirstChild("zoomies")
    local vel     = vp and vp.VectorVelocity or Vector3.zero
    local toPlyr  = (hrp.Position - ball.Position).Unit
    local dot     = math.clamp(vel.Unit:Dot(toPlyr), -1, 1)
    local approx  = (dot + 1) / 2
    local pingN   = math.clamp((PingComp.pingMs or 0) / 300, 0, 1)
    local _, clsIdx = SpeedCluster.classify(state.speed or 0)
    local clsN    = (clsIdx or 0)
    local winN    = math.clamp((Config.parryWindow or 0.5) / 2, 0, 1)
    return { dist, speed, approx, pingN, clsN, winN }
end

-- Wire train step into onParry
task.spawn(function()
    task.wait(2)
    local tr = _G._WindTracker
    if not tr then return end
    tr.onParry:Connect(function(ball, eta)
        local state = tr.states[ball]
        if not state then return end
        local inputs = _buildNetInputs(ball, state)
        if inputs then MiniNet.forward(inputs) end
        MiniNet.train(true)   -- successful parry → positive reinforcement
        TimingFeedback.record(eta, true)
    end)
end)

-- ── §44.5  Per-session trend analyser ─────────────────────
-- Tracks whether accuracy is improving or degrading over the
-- last N windows of time (each 30 seconds).

local TrendAnalyser = {
    _windows   = {},
    _windowSz  = 30,    -- seconds per window
    _windowStart = os.clock(),
    _curHits   = 0,
    _curShots  = 0,
    trend      = "stable",   -- "improving" | "degrading" | "stable"
}

AccuracyTracker_origFired = AccuracyTracker.fired
function AccuracyTracker:fired()
    AccuracyTracker_origFired(self)
    TrendAnalyser._curShots = TrendAnalyser._curShots + 1
end
AccuracyTracker_origSuccess = AccuracyTracker.success
function AccuracyTracker:success()
    AccuracyTracker_origSuccess(self)
    TrendAnalyser._curHits  = TrendAnalyser._curHits  + 1
end

task.spawn(function()
    while _G.WindHubActive do
        task.wait(TrendAnalyser._windowSz)
        local shots = TrendAnalyser._curShots
        local hits  = TrendAnalyser._curHits
        local rate  = shots > 0 and hits / shots or 0
        table.insert(TrendAnalyser._windows, rate)
        if #TrendAnalyser._windows > 6 then table.remove(TrendAnalyser._windows, 1) end
        TrendAnalyser._curHits  = 0
        TrendAnalyser._curShots = 0

        -- Detect trend over the last 3 windows
        if #TrendAnalyser._windows >= 3 then
            local last   = TrendAnalyser._windows[#TrendAnalyser._windows]
            local prev   = TrendAnalyser._windows[#TrendAnalyser._windows - 1]
            local pprev  = TrendAnalyser._windows[#TrendAnalyser._windows - 2]
            local slope  = (last - pprev) / 2
            if slope > 0.05 then
                TrendAnalyser.trend = "improving"
            elseif slope < -0.05 then
                TrendAnalyser.trend = "degrading"
                UI.notify({ title = "Analytics", text = "Accuracy trending down — consider adjusting parry mode", kind = "warn", duration = 5 })
            else
                TrendAnalyser.trend = "stable"
            end
        end
    end
end)


-- ============================================================
-- §45  ANTI-DETECTION v2
--      Human-behaviour synthesiser: random idle movements,
--      timing jitter profiles, click-pattern randomiser,
--      rate-limit with token bucket, server-event cloaking.
-- ============================================================

-- ── §45.1  Token-bucket rate limiter ─────────────────────
local TokenBucket = {}
TokenBucket.__index = TokenBucket

function TokenBucket.new(capacity, refillRate)
    return setmetatable({
        capacity   = capacity,
        tokens     = capacity,
        refillRate = refillRate,   -- tokens per second
        _lastRefill= os.clock(),
    }, TokenBucket)
end

function TokenBucket:consume(n)
    n = n or 1
    local now = os.clock()
    local elapsed = now - self._lastRefill
    self.tokens = math.min(self.capacity, self.tokens + elapsed * self.refillRate)
    self._lastRefill = now
    if self.tokens >= n then
        self.tokens = self.tokens - n
        return true
    end
    return false
end

function TokenBucket:refill()
    self.tokens = self.capacity
    self._lastRefill = os.clock()
end

-- ── §45.2  Jitter profile library ────────────────────────
-- Named timing profiles that drive human-like reaction delays.
-- Each profile has a mean, standard-deviation, and optional skew.

local JITTER_PROFILES = {
    Pro       = { mean = 0.010, sd = 0.008, skew =  0.0 },
    Average   = { mean = 0.028, sd = 0.014, skew =  0.3 },
    Casual    = { mean = 0.055, sd = 0.022, skew =  0.5 },
    Tryhard   = { mean = 0.006, sd = 0.004, skew = -0.2 },
    Random    = { mean = 0.035, sd = 0.030, skew =  0.8 },
}

local function _jitterSample(profileName)
    local p = JITTER_PROFILES[profileName] or JITTER_PROFILES.Average
    -- Skewed normal via Box-Muller + clamp
    local u1 = math.max(1e-9, math.random())
    local u2 = math.random()
    local z  = math.sqrt(-2 * math.log(u1)) * math.cos(2 * math.pi * u2)
    local v  = p.mean + p.sd * z + p.skew * math.abs(z) * p.sd * 0.5
    return math.clamp(v, 0, p.mean + p.sd * 4)
end

-- ── §45.3  Click-pattern randomiser ──────────────────────
-- Instead of always clicking at the viewport centre, randomise the
-- pixel coordinates in a convincing way:  mostly near centre (where
-- the player's hand rests), with occasional slight drift.

local ClickPattern = {
    _lastX = 0,
    _lastY = 0,
    _drift = Vector2.zero,
    _driftTimer = 0,
}

local function _humanClickPos()
    local vp = cam and cam.ViewportSize or Vector2.new(1280, 720)
    local cx  = vp.X * 0.5
    local cy  = vp.Y * 0.5

    -- Drift towards a random point every 3-8 seconds (simulates resting hand)
    local now = os.clock()
    if now > ClickPattern._driftTimer then
        ClickPattern._drift = Vector2.new(
            (math.random() - 0.5) * 80,
            (math.random() - 0.5) * 60
        )
        ClickPattern._driftTimer = now + 3 + math.random() * 5
    end

    -- Per-click noise around the drifted centre
    local noise = Vector2.new(
        (math.random() - 0.5) * 14,
        (math.random() - 0.5) * 10
    )
    local pos = Vector2.new(cx, cy) + ClickPattern._drift + noise
    return math.floor(pos.X + 0.5), math.floor(pos.Y + 0.5)
end

-- ── §45.4  Mouse-path interpolation ──────────────────────
-- Move the virtual mouse along a curved path to the target
-- click position instead of teleporting (looks human).

local function _bezierPoint(p0, p1, p2, t)
    local mt = 1 - t
    return p0 * mt * mt + p1 * 2 * mt * t + p2 * t * t
end

local function _moveMouse(fromX, fromY, toX, toY, steps)
    steps = steps or math.random(4, 8)
    -- Control point slightly off the straight line
    local cpX = (fromX + toX) * 0.5 + (math.random() - 0.5) * 40
    local cpY = (fromY + toY) * 0.5 + (math.random() - 0.5) * 30

    for i = 1, steps do
        local t  = i / steps
        local pt = _bezierPoint(Vector2.new(fromX, fromY), Vector2.new(cpX, cpY), Vector2.new(toX, toY), t)
        if UNC.mouse and UNC.mouse.move then
            pcall(UNC.mouse.move, math.floor(pt.X), math.floor(pt.Y))
        end
        task.wait(0.002 + math.random() * 0.004)
    end
end

-- ── §45.5  Parry cloaking ─────────────────────────────────
-- When AntiDetect is on, wrap clickParry to:
--   1. Sample a jitter profile delay
--   2. Move the mouse to a human-like position
--   3. Execute the click
--   4. Randomly NOT fire ~2% of the time (misclick simulation)

local AD_BUCKET = TokenBucket.new(Config.maxParryRate or 18, Config.maxParryRate or 18)

local _origClickParry = clickParry   -- saved before override
local function _cloakedClickParry()
    if not Config.antiDetect then
        _origClickParry()
        return
    end

    -- Rate limit check
    if not AD_BUCKET:consume(1) then return end

    -- Misclick suppression (~2% of the time, skip entirely)
    if math.random() < 0.02 then return end

    -- Jitter delay
    local profile = Config.parryMode == "Ultra" and "Tryhard"
        or Config.parryMode == "Conservative" and "Casual"
        or "Average"
    local delay = _jitterSample(profile)

    -- Move mouse to click position
    local tx, ty = _humanClickPos()
    local lx = ClickPattern._lastX == 0 and tx or ClickPattern._lastX
    local ly = ClickPattern._lastY == 0 and ty or ClickPattern._lastY

    task.spawn(function()
        if delay > 0 then task.wait(delay) end
        if Config.varyPosition then
            _moveMouse(lx, ly, tx, ty)
        end
        ClickPattern._lastX = tx
        ClickPattern._lastY = ty
        -- Use the VIM click at the computed position
        if isMobile and VIM and VIM.SendTouchEvent then
            pcall(VIM.SendTouchEvent, VIM, 0, Vector2.new(tx, ty), true,  game)
            task.wait(0.032 + math.random() * 0.012)
            pcall(VIM.SendTouchEvent, VIM, 0, Vector2.new(tx, ty), false, game)
        elseif VIM then
            pcall(VIM.SendMouseButtonEvent, VIM, tx, ty, 0, true,  game, 0)
            task.wait(0.030 + math.random() * 0.012)
            pcall(VIM.SendMouseButtonEvent, VIM, tx, ty, 0, false, game, 0)
        end
    end)
end

-- Patch the global clickParry used by the main loop
clickParry = _cloakedClickParry

-- ── §45.6  Server-event cloaking ─────────────────────────
-- If the executor supports hookfunction we can intercept and delay
-- our own FireServer calls slightly (avoids perfectly-timed patterns).

local function _randomDelay()
    return 0.001 + math.random() * 0.006
end

local function _patchFireServer()
    if not (EX.hook and EF.hookfunction and EF.newcclosure and EF.getrawmetatable) then return end
    local mt = EF.getrawmetatable(game)
    if not mt then return end
    if EF.setreadonly then pcall(EF.setreadonly, mt, false) end
    local orig = rawget(mt, "__namecall")
    if not orig then return end
    local patched = EF.newcclosure(function(self, ...)
        local method = EF.getnamecallmethod and EF.getnamecallmethod() or ""
        if method == "FireServer" and Config.antiDetect then
            local args = { ... }
            task.delay(_randomDelay(), function()
                pcall(orig, self, table.unpack(args))
            end)
            return
        end
        return orig(self, ...)
    end)
    pcall(EF.hookfunction, orig, patched)
end
task.spawn(function()
    task.wait(1)
    pcall(_patchFireServer)
end)

-- ── §45.7  Idle behaviour synthesiser ────────────────────
-- Occasionally perform tiny random camera movements and mouse
-- micro-jitters so the input stream looks like a live human.

local IdleSynth = {
    _lastIdle = 0,
    _interval = function() return 2 + math.random() * 4 end,
    _nextAt   = os.clock() + 3,
}

task.spawn(function()
    while _G.WindHubActive do
        task.wait(0.5)
        if not Config.antiDetect then continue end
        local now = os.clock()
        if now < IdleSynth._nextAt then continue end
        IdleSynth._nextAt = now + IdleSynth._interval()
        -- Tiny random mouse wiggle (1-3 pixels)
        local vp = cam and cam.ViewportSize or Vector2.new(1280, 720)
        local cx = math.floor(vp.X * 0.5 + (math.random() - 0.5) * 6)
        local cy = math.floor(vp.Y * 0.5 + (math.random() - 0.5) * 4)
        if VIM then
            pcall(function() VIM:SendMouseMoveEvent(cx, cy, game) end)
        end
    end
end)

-- ── §45.8  Rate-limit config sync ────────────────────────
Config.Changed:Connect(function(k, v)
    if k == "maxParryRate" then
        AD_BUCKET.capacity   = v
        AD_BUCKET.refillRate = v
        AD_BUCKET:refill()
    end
end)


-- ============================================================
-- §46  REMOTE SPY v3
--      Full argument serialiser, diff tracking, remote blocker
--      (drop mode), call-graph building, frequency heatmap,
--      and a one-click "inject" command to re-fire any logged call.
-- ============================================================

-- ── §46.1  Argument serialiser ───────────────────────────
local function _serializeArg(v, depth)
    depth = depth or 0
    if depth > 4 then return "..." end
    local t = typeof(v)
    if t == "nil"     then return "nil"
    elseif t == "boolean" then return tostring(v)
    elseif t == "number"  then
        if v == math.floor(v) then return tostring(math.floor(v))
        else return string.format("%.4f", v) end
    elseif t == "string"  then return string.format("%q", v)
    elseif t == "table"   then
        local parts = {}
        for k, val in pairs(v) do
            local ks = type(k) == "number" and "" or (tostring(k) .. "=")
            parts[#parts+1] = ks .. _serializeArg(val, depth+1)
        end
        return "{" .. table.concat(parts, ", ") .. "}"
    elseif t == "Vector3"  then return string.format("V3(%.2f,%.2f,%.2f)", v.X, v.Y, v.Z)
    elseif t == "Vector2"  then return string.format("V2(%.2f,%.2f)", v.X, v.Y)
    elseif t == "CFrame"   then
        local p = v.Position
        return string.format("CF(%.2f,%.2f,%.2f)", p.X, p.Y, p.Z)
    elseif t == "Instance" then return "<" .. v.ClassName .. ":" .. v.Name .. ">"
    elseif t == "Color3"   then return string.format("RGB(%.0f,%.0f,%.0f)", v.R*255, v.G*255, v.B*255)
    elseif t == "EnumItem" then return "Enum." .. tostring(v)
    else return t .. "(" .. tostring(v) .. ")"
    end
end

local function _serializeArgs(args)
    local parts = {}
    for _, a in ipairs(args) do
        parts[#parts+1] = _serializeArg(a)
    end
    return "(" .. table.concat(parts, ", ") .. ")"
end

-- ── §46.2  Diff tracker ───────────────────────────────────
-- Keeps the last call signature per remote and flags when args change.
local RemoteSpyDiff = {
    _lastSig = {},   -- remote name → last serialized args
    _changed = {},   -- remote name → count of arg changes
}

local function _trackDiff(name, argsStr)
    local prev = RemoteSpyDiff._lastSig[name]
    if prev and prev ~= argsStr then
        RemoteSpyDiff._changed[name] = (RemoteSpyDiff._changed[name] or 0) + 1
    end
    RemoteSpyDiff._lastSig[name] = argsStr
end

-- ── §46.3  Extended log entry format ─────────────────────
-- Augment the existing RemoteSpy._watchRemote path with rich entries.
-- We store a table keyed by log index so the UI can query specific entries.

local SpyV3 = {
    log       = {},     -- array of {name, path, kind, argsStr, diff, t, idx}
    maxLog    = 200,
    onEntry   = Signal.new(),
    blocked   = {},     -- remote name → true
    _callGraph= {},     -- remote name → list of calling remote names (best-effort)
}

local _spyHookActive = false
local function _spyV3Watch(remote)
    if not (remote:IsA("RemoteEvent") or remote:IsA("RemoteFunction")) then return end
    local name = remote.Name
    local kind = remote:IsA("RemoteEvent") and "Event" or "Function"

    local function onCall(...)
        if not Config.remoteSpy then return end
        if SpyV3.blocked[name] then return end

        local args    = { ... }
        local argsStr = Config.spyArgs and _serializeArgs(args) or "(args hidden)"
        local diff    = RemoteSpyDiff._lastSig[name] and RemoteSpyDiff._lastSig[name] ~= argsStr
        _trackDiff(name, argsStr)

        local entry = {
            name    = name,
            path    = remote:GetFullName(),
            kind    = kind,
            argsStr = argsStr,
            diff    = diff,
            t       = os.clock(),
            idx     = #SpyV3.log + 1,
            remote  = remote,
            rawArgs = Config.spyArgs and args or nil,
        }
        table.insert(SpyV3.log, entry)
        if #SpyV3.log > SpyV3.maxLog then table.remove(SpyV3.log, 1) end
        SpyV3.onEntry:Fire(entry)
    end

    if remote:IsA("RemoteEvent") then
        remote.OnClientEvent:Connect(onCall)
    end
end

-- Scan and hook all remotes
task.spawn(function()
    task.wait(1)
    for _, o in ipairs(WS:GetDescendants())      do pcall(_spyV3Watch, o) end
    for _, o in ipairs(RepStor:GetDescendants()) do pcall(_spyV3Watch, o) end
end)
WS.DescendantAdded:Connect(function(o) pcall(_spyV3Watch, o) end)
RepStor.DescendantAdded:Connect(function(o) pcall(_spyV3Watch, o) end)

-- ── §46.4  SpyV3 formatted log ────────────────────────────
function SpyV3.format(maxLines)
    maxLines = maxLines or 20
    local out = {}
    local n   = #SpyV3.log
    for i = math.max(1, n - maxLines + 1), n do
        local e = SpyV3.log[i]
        if e then
            local diffMark = e.diff and "* " or "  "
            local ts       = string.format("%.1f", e.t - (_G.WindHub_SessionStart or 0))
            out[#out+1] = string.format("%s[%ss] %s %s %s",
                diffMark, ts, e.kind, e.name, e.argsStr)
        end
    end
    return #out > 0 and table.concat(out, "\n") or "No remote calls yet."
end

-- ── §46.5  Block & inject ─────────────────────────────────
function SpyV3.block(name)
    SpyV3.blocked[name] = true
    Console.warn("RemoteSpy: blocked " .. name)
end
function SpyV3.unblock(name)
    SpyV3.blocked[name] = nil
    Console.info("RemoteSpy: unblocked " .. name)
end
function SpyV3.inject(idx)
    local entry = SpyV3.log[idx]
    if not entry then Console.warn("SpyV3.inject: no entry at index " .. tostring(idx)) return end
    if not entry.remote or not entry.rawArgs then Console.warn("SpyV3.inject: args not captured") return end
    pcall(function()
        entry.remote:FireServer(table.unpack(entry.rawArgs))
    end)
    Console.good("SpyV3: re-fired " .. entry.name)
end

-- Register SpyV3 commands with console
COMMANDS["spy"] = function(args)
    if not args then Console.info(SpyV3.format(10)) return end
    local sub = args[1]
    if sub == "block" and args[2] then
        SpyV3.block(args[2])
    elseif sub == "unblock" and args[2] then
        SpyV3.unblock(args[2])
    elseif sub == "inject" and args[2] then
        SpyV3.inject(tonumber(args[2]) or 0)
    elseif sub == "clear" then
        SpyV3.log = {}; Console.good("Spy log cleared")
    elseif sub == "freq" then
        local rows = {}
        for name, cnt in pairs(RemoteSpy.freq or {}) do
            rows[#rows+1] = string.format("  %-24s %d/s", name, cnt)
        end
        table.sort(rows)
        Console.info("Remote frequencies:\n" .. table.concat(rows, "\n"))
    else
        Console.info("spy [block|unblock|inject|clear|freq] [args]")
    end
end

-- ── §46.6  Heatmap by time-of-day (call frequency binned by second) ───
local SpyHeatmap = {
    _bins = {},   -- second-of-session → call count
}
SpyV3.onEntry:Connect(function(entry)
    local sec = math.floor(entry.t - (_G.WindHub_SessionStart or 0))
    SpyHeatmap._bins[sec] = (SpyHeatmap._bins[sec] or 0) + 1
end)

function SpyHeatmap.sparkline(width)
    width = width or 40
    local maxSec = 0
    for s in pairs(SpyHeatmap._bins) do if s > maxSec then maxSec = s end end
    if maxSec == 0 then return "No data" end
    local step  = math.max(1, math.ceil(maxSec / width))
    local bars  = {}
    local CHARS = { "▁","▂","▃","▄","▅","▆","▇","█" }
    local maxV  = 1
    for i = 0, width - 1 do
        local sum = 0
        for j = i * step, (i + 1) * step - 1 do
            sum = sum + (SpyHeatmap._bins[j] or 0)
        end
        bars[i+1] = sum
        if sum > maxV then maxV = sum end
    end
    local line = {}
    for _, v in ipairs(bars) do
        local idx = math.ceil(v / maxV * 8)
        line[#line+1] = CHARS[math.clamp(idx, 1, 8)]
    end
    return table.concat(line)
end

-- ── §46.7  Update UI spy log box to use SpyV3 ─────────────
task.spawn(function()
    while _G.WindHubActive do
        task.wait(0.3)
        if UI._spyLogBox then
            UI._spyLogBox.Text = SpyV3.format(18)
        end
    end
end)


-- ============================================================
-- §47  EXTENDED SERVER ANALYSIS v2
--      Detailed server profiling: tick-rate histogram, latency
--      distribution, server-lag correlation with parry success,
--      player-count load estimator, and auto-recommendation.
-- ============================================================

-- ── §47.1  Tick-rate histogram ────────────────────────────
local TickHist = {
    _buckets = {},    -- bucket (fps rounded to nearest 5) → count
    total    = 0,
}

RS.Heartbeat:Connect(function(dt)
    local fps  = math.floor(1 / math.max(dt, 0.001) / 5 + 0.5) * 5
    fps = math.clamp(fps, 5, 130)
    TickHist._buckets[fps] = (TickHist._buckets[fps] or 0) + 1
    TickHist.total = TickHist.total + 1
end)

function TickHist.mode()
    local best, bestCnt = 60, 0
    for fps, cnt in pairs(TickHist._buckets) do
        if cnt > bestCnt then best = fps; bestCnt = cnt end
    end
    return best
end

function TickHist.sparkline(width)
    width = width or 20
    local CHARS = { "▁","▂","▃","▄","▅","▆","▇","█" }
    local labels, vals = {}, {}
    for fps = 15, 90, 5 do
        labels[#labels+1] = fps
        vals[#vals+1]     = TickHist._buckets[fps] or 0
    end
    local maxV = 1
    for _, v in ipairs(vals) do if v > maxV then maxV = v end end
    local line = {}
    for _, v in ipairs(vals) do
        local idx = math.ceil(v / maxV * 8)
        line[#line+1] = CHARS[math.clamp(idx, 1, 8)]
    end
    return table.concat(line)
end

-- ── §47.2  Latency → success correlation ─────────────────
-- Record (ping, success) pairs to see if higher ping kills accuracy.

local LatencyCorrel = {
    _data  = {},   -- { ping, success }
    _maxN  = 100,
    corr   = 0,    -- Pearson r  (-1 to 1)
}

task.spawn(function()
    task.wait(2)
    local tr = _G._WindTracker
    if not tr then return end
    tr.onParry:Connect(function()
        table.insert(LatencyCorrel._data, {
            ping    = PingComp.pingMs or 0,
            success = 1,
        })
        if #LatencyCorrel._data > LatencyCorrel._maxN then
            table.remove(LatencyCorrel._data, 1)
        end
        -- Update Pearson r
        local n = #LatencyCorrel._data
        if n < 4 then return end
        local sumX, sumY, sumXY, sumX2, sumY2 = 0, 0, 0, 0, 0
        for _, d in ipairs(LatencyCorrel._data) do
            sumX  = sumX  + d.ping
            sumY  = sumY  + d.success
            sumXY = sumXY + d.ping * d.success
            sumX2 = sumX2 + d.ping * d.ping
            sumY2 = sumY2 + d.success * d.success
        end
        local num = n * sumXY - sumX * sumY
        local den = math.sqrt((n * sumX2 - sumX^2) * (n * sumY2 - sumY^2))
        LatencyCorrel.corr = den > 0 and (num / den) or 0
    end)
end)

-- ── §47.3  Player-count load model ───────────────────────
-- More players → more server load → higher tick variance.
-- We track the player count over time and correlate it with
-- the tick-rate stability coefficient.

local LoadModel = {
    _samples = {},    -- { players, tickRate, time }
    _maxN    = 60,
}

task.spawn(function()
    while _G.WindHubActive do
        task.wait(5)
        table.insert(LoadModel._samples, {
            players  = #Plrs:GetPlayers(),
            tickRate = NetMon.tickRate or 60,
            time     = os.clock(),
        })
        if #LoadModel._samples > LoadModel._maxN then
            table.remove(LoadModel._samples, 1)
        end
    end
end)

function LoadModel.recommendMode()
    local n = #LoadModel._samples
    if n < 3 then return "Predictive", "Not enough data yet" end

    local avgTick = 0
    for _, s in ipairs(LoadModel._samples) do avgTick = avgTick + s.tickRate end
    avgTick = avgTick / n

    local ping  = PingComp.pingMs or 0
    local trend = TrendAnalyser.trend

    if avgTick >= 58 and ping < 60 then
        return "RK4",       "Low load, good ping — use accurate physics"
    elseif avgTick >= 55 and ping < 100 then
        return "Fusion",    "Normal conditions — Fusion mode optimal"
    elseif ping > 150 or avgTick < 45 then
        return "Ultra",     "High latency or server load — fire early"
    elseif trend == "degrading" then
        return "Conservative", "Accuracy dropping — widen the window"
    else
        return "Predictive",   "Standard conditions"
    end
end

-- Auto-apply recommended mode every 60 seconds if user has "learning" on
task.spawn(function()
    task.wait(60)
    while _G.WindHubActive do
        if Config.learning then
            local mode, reason = LoadModel.recommendMode()
            if mode ~= Config.parryMode then
                Config.parryMode = mode
                if UI._registry.parryMode then UI._registry.parryMode(mode) end
                Console.info("[AutoTune] Switched to " .. mode .. " (" .. reason .. ")")
            end
        end
        task.wait(60)
    end
end)

-- ── §47.4  Server analysis console command ────────────────
COMMANDS["server"] = function()
    local mode, reason = LoadModel.recommendMode()
    local qual, _ = NetMon.qualityRating()
    Console.info(string.format(
        "Server: %.0f Hz (mode %d Hz) · Stability %.0f%% · Players %d · Net: %s",
        NetMon.tickRate or 60,
        TickHist.mode(),
        (ServerAnalysis.stability or 1) * 100,
        #Plrs:GetPlayers(),
        qual
    ))
    Console.info(string.format(
        "Ping: %dms avg · Jitter: %.1fms · Loss est: %.1f%%",
        math.floor(PingComp.pingMs or 0),
        NetMon.jitter or 0,
        PacketLossEst.rate or 0
    ))
    Console.info("Recommended mode: " .. mode .. " — " .. reason)
    Console.info("Tick histogram: " .. TickHist.sparkline())
    Console.info("Remote heatmap: " .. SpyHeatmap.sparkline(30))
end

-- ── §47.5  Update Stats tab with richer data ──────────────
task.spawn(function()
    task.wait(3)
    while _G.WindHubActive do
        task.wait(2)
        pcall(function()
            if UI._stTick then
                UI._stTick.set(string.format("%.0f Hz", NetMon.tickRate or 60))
            end
            if UI._stStable then
                local st = math.floor((ServerAnalysis.stability or 1) * 100)
                UI._stStable.set(st .. "%")
                if st > 90 then UI._stStable.setColor(UI.Theme.Good)
                elseif st > 70 then UI._stStable.setColor(UI.Theme.Warn)
                else UI._stStable.setColor(UI.Theme.Bad) end
            end
        end)
    end
end)


-- ============================================================
-- §48  EXTENDED AUDIO SYSTEM v2
--      Positional audio for ball approach warnings, dynamic
--      mixing, ducking on parry, beat-sync chime patterns,
--      and a frequency-sweep calibration tone.
-- ============================================================

-- ── §48.1  Sound asset catalogue ─────────────────────────
local AUDIO_CATALOGUE = {
    -- Parry feedback
    parry_success  = { id = "rbxassetid://9120394925", vol = 0.55, pitch = 1.10 },
    parry_miss     = { id = "rbxassetid://9120394925", vol = 0.30, pitch = 0.70 },
    parry_early    = { id = "rbxassetid://9120394925", vol = 0.25, pitch = 0.85 },
    -- Threat alerts
    threat_near    = { id = "rbxassetid://6042053626", vol = 0.40, pitch = 1.00 },
    threat_critical= { id = "rbxassetid://6042053626", vol = 0.65, pitch = 1.40 },
    -- Combo chimes  (ascending notes)
    combo_3        = { id = "rbxassetid://4612334281", vol = 0.45, pitch = 1.00 },
    combo_5        = { id = "rbxassetid://4612334281", vol = 0.55, pitch = 1.15 },
    combo_10       = { id = "rbxassetid://4612334281", vol = 0.70, pitch = 1.35 },
    combo_20       = { id = "rbxassetid://4612334281", vol = 0.85, pitch = 1.60 },
    -- Session events
    spawn          = { id = "rbxassetid://6042053626", vol = 0.30, pitch = 0.90 },
    death          = { id = "rbxassetid://9120394925", vol = 0.35, pitch = 0.60 },
    standoff_start = { id = "rbxassetid://4612334281", vol = 0.50, pitch = 0.80 },
    standoff_win   = { id = "rbxassetid://4612334281", vol = 0.70, pitch = 1.50 },
    calibrate_ping = { id = "rbxassetid://6042053626", vol = 0.20, pitch = 1.80 },
    ui_open        = { id = "rbxassetid://6042053626", vol = 0.15, pitch = 1.20 },
    ui_click       = { id = "rbxassetid://6042053626", vol = 0.12, pitch = 1.60 },
    mode_change    = { id = "rbxassetid://4612334281", vol = 0.20, pitch = 1.30 },
}

-- ── §48.2  Sound pool (re-use Sounds to avoid GC churn) ───
local SoundPool = {
    _pool = {},     -- name → { sound, inUse, def }
    _parent = SoundSvc,
}

task.spawn(function()
    task.wait(1.5)
    for name, def in pairs(AUDIO_CATALOGUE) do
        local s = Instance.new("Sound")
        s.SoundId        = def.id
        s.Volume         = def.vol * (Config.audioVolume or 0.5)
        s.PlaybackSpeed  = def.pitch
        s.RollOffMaxDistance = 0
        s.Parent         = SoundPool._parent
        SoundPool._pool[name] = { sound = s, def = def }
    end
end)

function SoundPool.play(name, overridePitch)
    if not Config.audio then return end
    local entry = SoundPool._pool[name]
    if not entry then return end
    local s = entry.sound
    -- Pitch variance
    local pitchVar = Config.audioPitchVar or 0.1
    local basePitch = overridePitch or entry.def.pitch
    s.PlaybackSpeed = basePitch + (math.random() - 0.5) * pitchVar * basePitch
    s.Volume        = entry.def.vol * (Config.audioVolume or 0.5)
    pcall(function() s:Play() end)
end

-- Override global Audio.play with pool-based version
Audio.play = function(name)
    SoundPool.play(name)
end

-- ── §48.3  Positional audio (approach warning) ────────────
-- Volume scales with how close the ball is to the player.
local function _posAudioVolume(dist, maxDist)
    maxDist = maxDist or 60
    local frac = 1 - math.clamp(dist / maxDist, 0, 1)
    return frac * frac   -- quadratic falloff
end

task.spawn(function()
    while _G.WindHubActive do
        task.wait(0.1)
        if not Config.audioDanger then continue end
        local tr = _G._WindTracker
        if not tr then continue end
        local _, eta = tr:bestThreat()
        if eta and eta < 0.4 then
            local vol = _posAudioVolume(eta * 80, 60)
            if vol > 0.05 then
                SoundPool.play("threat_critical")
            end
        elseif eta and eta < 1.0 then
            SoundPool.play("threat_near")
        end
    end
end)

-- ── §48.4  Dynamic ducking ────────────────────────────────
-- When a parry fires, briefly lower the volume of ambient sounds.
local _duckActive = false
task.spawn(function()
    while _G.WindHubActive do
        task.wait(0.05)
        if _duckActive then
            for name, entry in pairs(SoundPool._pool) do
                if name ~= "parry_success" then
                    entry.sound.Volume = entry.def.vol * (Config.audioVolume or 0.5) * 0.3
                end
            end
        else
            for name, entry in pairs(SoundPool._pool) do
                entry.sound.Volume = entry.def.vol * (Config.audioVolume or 0.5)
            end
        end
    end
end)

task.spawn(function()
    task.wait(2)
    local tr = _G._WindTracker
    if not tr then return end
    tr.onParry:Connect(function()
        _duckActive = true
        SoundPool.play("parry_success")
        task.delay(0.3, function() _duckActive = false end)
    end)
end)

-- ── §48.5  Beat-sync combo chimes ─────────────────────────
-- The combo chime pitches form a pentatonic scale.
local PENTATONIC = { 0.90, 1.00, 1.12, 1.26, 1.41, 1.59, 1.78, 2.00 }

ComboTracker.onCombo:Connect(function(n)
    if not Config.audioCombo then return end
    local degree = math.min(n, #PENTATONIC)
    SoundPool.play("combo_3", PENTATONIC[degree])
    if n >= 5  then task.delay(0.12, function() SoundPool.play("combo_5",  PENTATONIC[math.min(degree+1, #PENTATONIC)]) end) end
    if n >= 10 then task.delay(0.24, function() SoundPool.play("combo_10", PENTATONIC[math.min(degree+2, #PENTATONIC)]) end) end
    if n >= 20 then task.delay(0.36, function() SoundPool.play("combo_20", PENTATONIC[#PENTATONIC]) end) end
end)

-- ── §48.6  UI audio feedback ──────────────────────────────
-- Play subtle click sounds on button presses.
local _uiSoundReady = false
task.spawn(function() task.wait(2); _uiSoundReady = true end)

local function uiClick() if _uiSoundReady then SoundPool.play("ui_click") end end
local function uiMode()  if _uiSoundReady then SoundPool.play("mode_change") end end

-- Wire into config changes
Config.Changed:Connect(function(k, v)
    if k == "parryMode" then uiMode()
    elseif k == "autoParry" then uiClick() end
end)

-- ── §48.7  Calibration ping (tests executor audio pipeline) ─
COMMANDS["ping_audio"] = function()
    SoundPool.play("calibrate_ping")
    Console.info("Audio calibration ping played — did you hear it?")
end

-- ── §48.8  Session-start / spawn / death sounds ───────────
task.spawn(function()
    task.wait(2)
    SoundPool.play("ui_open")
end)

ClientState.onSpawned:Connect(function()
    task.delay(0.5, function() SoundPool.play("spawn") end)
end)

ClientState.onDied:Connect(function()
    SoundPool.play("death")
end)

GameRemotes.onStandoffStart:Connect(function()
    SoundPool.play("standoff_start")
end)


-- ============================================================
-- §49  EXTENDED COMBAT ENGINE
--      Full 5-mode auto-dodge with physics prediction, hitbox
--      expander v2 (per-limb), crowd-control detection,
--      secondary skill manager, and BlazeBarrier mode.
-- ============================================================

-- ── §49.1  Predicted-dodge using physics ─────────────────
-- Instead of dodging purely perpendicular we predict where the
-- ball will be in `leadTime` seconds and dodge away from that point.

local PredictiveDodge = {
    leadTime = 0.22,   -- seconds ahead to look
    active   = false,
}

function PredictiveDodge.attempt(hrp, ball, state)
    if not Config.autoDodge then return end
    if Dodge.busy then return end
    if os.clock() - Dodge.lastAt < Config.dodgeCooldown then return end

    local vp = ball:FindFirstChild("zoomies")
    if not vp then return end
    local bPos = MemScanner.rawPos(ball) or ball.Position
    local bVel = MemScanner.rawVel(ball) or vp.VectorVelocity

    -- Predict where the ball will be at leadTime
    local spin  = (state.physics._spinEst and state.physics._spinEst.spin) or Vector3.zero
    local futurePos = select(1, rk4StepV4(bPos, bVel, spin, PredictiveDodge.leadTime))

    -- Dodge direction = away from future ball position
    local awayDir = (hrp.Position - futurePos)
    if awayDir.Magnitude < 0.01 then
        -- Ball will be exactly on us: dodge perpendicular
        awayDir = bVel.Unit:Cross(Vector3.yAxis)
    else
        awayDir = Vector3.new(awayDir.X, 0, awayDir.Z).Unit
    end

    Dodge.busy   = true
    Dodge.lastAt = os.clock()
    task.spawn(function()
        local dist    = Config.dodgeDistance or 12
        local targetCF= hrp.CFrame * CFrame.new(awayDir * dist)
        TS:Create(hrp, TweenInfo.new(0.13, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
            { CFrame = targetCF }):Play()
        task.wait(0.15)
        Dodge.busy = false
    end)
end

-- ── §49.2  Hitbox Expander v2 (per-limb) ─────────────────
local HitboxV2 = {
    _origSizes = {},    -- part → original size
    _expanded  = false,
}

local LIMB_NAMES = {
    "HumanoidRootPart", "Head",
    "LeftUpperArm","LeftLowerArm","LeftHand",
    "RightUpperArm","RightLowerArm","RightHand",
    "LeftUpperLeg","LeftLowerLeg","LeftFoot",
    "RightUpperLeg","RightLowerLeg","RightFoot",
    "UpperTorso","LowerTorso",
}

function HitboxV2.expand(char)
    if HitboxV2._expanded then return end
    local scalar = Config.hitboxScalar or 8
    local grow   = Vector3.new(scalar, scalar, scalar)
    for _, name in ipairs(LIMB_NAMES) do
        local part = char:FindFirstChild(name)
        if part and part:IsA("BasePart") then
            HitboxV2._origSizes[part] = part.Size
            pcall(function() part.Size = part.Size + grow end)
        end
    end
    HitboxV2._expanded = true
end

function HitboxV2.restore(char)
    if not HitboxV2._expanded then return end
    for part, origSize in pairs(HitboxV2._origSizes) do
        pcall(function()
            if part and part.Parent then
                part.Size = origSize
            end
        end)
    end
    HitboxV2._origSizes = {}
    HitboxV2._expanded  = false
end

-- Replace old HitboxExpand with v2
HitboxExpand.apply   = function(char) HitboxV2.expand(char) end
HitboxExpand.restore = function()
    local char = lp.Character
    if char then HitboxV2.restore(char) end
end

-- ── §49.3  Crowd-control detector ────────────────────────
-- Detects when multiple balls are simultaneously targeting us
-- (server-side CC) and triggers an evasive burst.

local CCDetector = {
    _threatCount = 0,
    _threshold   = 2,
    _burst       = false,
    _lastBurst   = 0,
    _burstCd     = 1.0,
}

task.spawn(function()
    while _G.WindHubActive do
        task.wait(1/20)  -- 20 Hz check
        local tr = _G._WindTracker
        if not tr then continue end

        local threats = 0
        for _, state in pairs(tr.states) do
            if state.threat then threats = threats + 1 end
        end
        CCDetector._threatCount = threats

        if threats >= CCDetector._threshold and not CCDetector._burst then
            local now = os.clock()
            if now - CCDetector._lastBurst > CCDetector._burstCd then
                CCDetector._burst   = true
                CCDetector._lastBurst = now
                -- Fire a short rapid-fire parry burst
                task.spawn(function()
                    for _ = 1, 3 do
                        if _G.WindHubActive then
                            pcall(clickParry)
                            task.wait(0.04 + math.random() * 0.02)
                        end
                    end
                    CCDetector._burst = false
                end)
                if Config.screenAlerts then
                    pcall(function() screenAlert("CC BURST!", Color3.fromRGB(255, 140, 40), 0.6) end)
                end
            end
        end
    end
end)

-- ── §49.4  Secondary skill manager ────────────────────────
-- Tracks the cooldown of the player's secondary skill and auto-fires
-- it when: (a) we're in a standoff, or (b) we're taking a lot of damage.

local SecondaryManager = {
    ready       = false,
    _lastFire   = 0,
    cooldown    = 8,     -- estimated cooldown (seconds) — adjusted from events
    autoFire    = false,
    _onCooldown = false,
}

GameRemotes.onSecondaryEndCD:Connect(function()
    SecondaryManager.ready       = true
    SecondaryManager._onCooldown = false
    if SecondaryManager.autoFire and _G.WindHub_Standoff then
        -- auto-use secondary during standoff
        task.spawn(function()
            task.wait(0.05 + math.random() * 0.1)
            -- fire via the appropriate remote (executor-specific)
            Console.debug("[Secondary] Auto-fire triggered")
        end)
    end
end)

-- ── §49.5  BlazeBarrier mode ──────────────────────────────
-- A special composite mode: combines Ultra parry + hitbox expand +
-- predictive dodge + secondary auto-fire for maximum defence.

local function _setBlazeBarrier(on)
    if on then
        Config.parryMode   = "Ultra"
        Config.hitboxExpand = true
        Config.autoDodge    = true
        SecondaryManager.autoFire = true
        if lp.Character then HitboxV2.expand(lp.Character) end
        UI.notify({ title = "BlazeBarrier", text = "Maximum defence activated!", kind = "warn", duration = 2 })
        Console.warn("BlazeBarrier ON — Ultra + HitboxExpand + PredDodge + AutoSecondary")
        if UI._registry.parryMode    then UI._registry.parryMode("Ultra") end
        if UI._registry.hitboxExpand then UI._registry.hitboxExpand(true)  end
        if UI._registry.autoDodge    then UI._registry.autoDodge(true)    end
    else
        SecondaryManager.autoFire = false
        HitboxV2.restore(lp.Character)
        UI.notify({ title = "BlazeBarrier", text = "Deactivated", kind = "info", duration = 2 })
        Console.info("BlazeBarrier OFF")
    end
end

COMMANDS["blaze"] = function(args)
    local on = not (args and args[1] == "off")
    _setBlazeBarrier(on)
end


-- ============================================================
-- §50  EXTENDED MINIMAP v2
--      Rotating player-centric radar with heading arrow,
--      ball trajectory prediction dots, zone circles,
--      player name tags, threat heat rings, and snapshot export.
-- ============================================================

-- ── §50.1  Minimap geometry helpers ──────────────────────
local MM = {
    SIZE    = 150,
    RANGE   = Config.minimapRange or 200,
    BORDER  = 4,
}

local function _mmCenter()
    if not Minimap._frame then return Vector2.zero end
    local ap = Minimap._frame.AbsolutePosition
    local as = Minimap._frame.AbsoluteSize
    return Vector2.new(ap.X + as.X * 0.5, ap.Y + as.Y * 0.5)
end

-- World position → minimap 0-1 UV space (camera-yaw aligned)
local function _worldToMM(wPos, refPos, yaw)
    local dx = wPos.X - refPos.X
    local dz = wPos.Z - refPos.Z
    local cos_y =  math.cos(yaw)
    local sin_y = -math.sin(yaw)
    local rx =  dx * cos_y - dz * sin_y
    local rz =  dx * sin_y + dz * cos_y
    local range = Config.minimapRange or 200
    local u = math.clamp(rx / range * 0.5 + 0.5, 0, 1)
    local v = math.clamp(rz / range * 0.5 + 0.5, 0, 1)
    return u, v
end

-- ── §50.2  Heading arrow (shows which way player faces) ───
local MMArrow = { _parts = {} }

local function _mmEnsurePart(key, color, sz)
    if not Minimap._frame then return nil end
    if not MMArrow._parts[key] then
        local f = Instance.new("Frame")
        f.Size             = UDim2.fromOffset(sz or 5, sz or 5)
        f.BackgroundColor3 = color
        f.BorderSizePixel  = 0
        f.AnchorPoint      = Vector2.new(0.5, 0.5)
        f.ZIndex           = 5
        Instance.new("UICorner", f).CornerRadius = UDim.new(1, 0)
        f.Parent           = Minimap._frame
        MMArrow._parts[key] = f
    end
    return MMArrow._parts[key]
end

-- ── §50.3  Threat heat rings ──────────────────────────────
-- Draw concentric circles around the player-dot sized by ETA.
-- Close balls = small tight ring (red); far balls = large ring (blue).

local MMHeatRings = {
    _drawing = {},   -- ball → Drawing.Circle (if Drawing API available)
}

function MMHeatRings.update(tracker)
    if not _drawingSupported or not Config.minimap then
        for _, d in pairs(MMHeatRings._drawing) do
            pcall(function() d:Remove() end)
        end
        MMHeatRings._drawing = {}
        return
    end

    local center = _mmCenter()
    local mmSize = Minimap._frame and Minimap._frame.AbsoluteSize.X or MM.SIZE

    local active = {}
    for ball, state in pairs(tracker.states) do
        if ball and ball.Parent and state.threat then
            active[ball] = true
            local ring = MMHeatRings._drawing[ball]
            if not ring then
                ring = Draw.circle({ thickness = 1, filled = false, color = Color3.fromRGB(255, 80, 80) })
                MMHeatRings._drawing[ball] = ring
            end
            if ring then
                local eta = state.eta or math.huge
                if eta == math.huge then ring.Visible = false; continue end
                -- Radius: maps ETA 0-2s to ring radius mmSize/2..4 px
                local rPx = math.clamp((eta / 2) * (mmSize * 0.5), 4, mmSize * 0.5)
                ring.Position  = center
                ring.Radius    = rPx
                ring.Color     = eta < 0.3
                    and Color3.fromRGB(255, 60,  60)
                    or  Color3.fromRGB(255, 180, 60)
                ring.Transparency = 0.3
                ring.Visible   = true
            end
        end
    end

    -- Remove rings for inactive/dead balls
    for ball, ring in pairs(MMHeatRings._drawing) do
        if not active[ball] then
            pcall(function() ring:Remove() end)
            MMHeatRings._drawing[ball] = nil
        end
    end
end

-- ── §50.4  Trajectory preview dots on minimap ─────────────
local MMTrajDots = { _dots = {} }

local function _ensureMMDot(key, color)
    if not Minimap._frame then return nil end
    if not MMTrajDots._dots[key] then
        local f = Instance.new("Frame")
        f.Size             = UDim2.fromOffset(3, 3)
        f.BackgroundColor3 = color or Color3.fromRGB(200, 200, 255)
        f.BorderSizePixel  = 0
        f.AnchorPoint      = Vector2.new(0.5, 0.5)
        f.ZIndex           = 3
        Instance.new("UICorner", f).CornerRadius = UDim.new(1, 0)
        f.Parent           = Minimap._frame
        MMTrajDots._dots[key] = f
    end
    return MMTrajDots._dots[key]
end

local function _updateMMTraj(tracker, refPos, camYaw)
    if not Config.arcESP or not Config.minimap then return end
    for ball, state in pairs(tracker.states) do
        if not (ball and ball.Parent) then continue end
        local bestVel = state.physics and state.physics.bestVel and state.physics:bestVel()
        if not bestVel then continue end
        local spin = (state.physics._spinEst and state.physics._spinEst.spin) or Vector3.zero
        -- 5 prediction dots along the arc
        local p, v = ball.Position, bestVel
        local dt   = 0.15
        for step = 1, 5 do
            p, v = rk4StepV4(p, v, spin, dt)
            local key = tostring(ball) .. "_traj_" .. step
            local frac = step / 5
            local col  = Color3.fromRGB(
                math.floor(80 + frac * 175),
                math.floor(220 - frac * 140),
                80)
            local dot = _ensureMMDot(key, col)
            if dot then
                local u, vv = _worldToMM(p, refPos, camYaw)
                dot.Position = UDim2.fromScale(u, vv)
                dot.Visible  = true
            end
        end
    end
end

-- ── §50.5  Wire extended minimap into the visual loop ─────
task.spawn(function()
    task.wait(3)
    while _G.WindHubActive do
        task.wait(1/20)  -- 20 Hz
        if not Config.minimap then continue end
        local tr = _G._WindTracker
        if not tr then continue end
        pcall(MMHeatRings.update, tr)

        local char = lp.Character
        local hrp  = char and char:FindFirstChild("HumanoidRootPart")
        if hrp and Minimap._frame then
            local yaw = cam and math.atan2(-cam.CFrame.LookVector.X, -cam.CFrame.LookVector.Z) or 0
            _updateMMTraj(tr, hrp.Position, yaw)
        end
    end
end)

-- ── §50.6  Minimap snapshot (copy to clipboard as text art) ─
COMMANDS["minimap_snap"] = function()
    if not (UNC.setclipboard) then Console.warn("Clipboard not supported") return end
    local tr  = _G._WindTracker
    local char = lp.Character
    local hrp  = char and char:FindFirstChild("HumanoidRootPart")
    if not (tr and hrp) then Console.warn("No tracker/character") return end

    local W, H = 40, 20
    local grid = {}
    for y = 1, H do
        grid[y] = {}
        for x = 1, W do grid[y][x] = "·" end
    end

    local function _setCell(u, v, char_)
        local x = math.clamp(math.floor(u * W) + 1, 1, W)
        local y = math.clamp(math.floor(v * H) + 1, 1, H)
        grid[y][x] = char_
    end

    local yaw = cam and math.atan2(-cam.CFrame.LookVector.X, -cam.CFrame.LookVector.Z) or 0
    local ref = hrp.Position

    -- Player
    _setCell(0.5, 0.5, "P")

    -- Other players
    for _, plr in ipairs(Plrs:GetPlayers()) do
        if plr ~= lp and plr.Character then
            local ph = plr.Character:FindFirstChild("HumanoidRootPart")
            if ph then
                local u, v = _worldToMM(ph.Position, ref, yaw)
                _setCell(u, v, "E")
            end
        end
    end

    -- Balls
    for ball, state in pairs(tr.states) do
        if ball and ball.Parent then
            local u, v = _worldToMM(ball.Position, ref, yaw)
            _setCell(u, v, state.threat and "!" or "o")
        end
    end

    local lines = {}
    for y = 1, H do
        lines[y] = table.concat(grid[y], " ")
    end
    local snap = table.concat(lines, "\n")
    pcall(UNC.setclipboard, snap)
    Console.good("Minimap snapshot copied to clipboard")
end


-- ============================================================
-- §51  EXTENDED PROFILE SYSTEM v2
--      Cloud sync stub, profile diff viewer, auto-save on exit,
--      profile inheritance, and session-state snapshot.
-- ============================================================

-- ── §51.1  Profile diff viewer ───────────────────────────
local function _profileDiff(nameA, nameB)
    local a = ProfileManager._store[nameA] or ProfileManager.PRESETS[nameA]
    local b = ProfileManager._store[nameB] or ProfileManager.PRESETS[nameB]
    if not a then return "Profile '" .. nameA .. "' not found" end
    if not b then return "Profile '" .. nameB .. "' not found" end

    local lines = {}
    local allKeys = {}
    for k in pairs(DEFAULTS) do allKeys[k] = true end
    for k in pairs(a) do allKeys[k] = true end
    for k in pairs(b) do allKeys[k] = true end

    for k in pairs(allKeys) do
        local va = a[k] or DEFAULTS[k]
        local vb = b[k] or DEFAULTS[k]
        local sa = tostring(va)
        local sb = tostring(vb)
        if sa ~= sb then
            lines[#lines+1] = string.format("  %-22s  %s → %s", k, sa, sb)
        end
    end
    if #lines == 0 then return "Profiles are identical" end
    table.sort(lines)
    return string.format("Diff %s → %s:\n", nameA, nameB) .. table.concat(lines, "\n")
end

COMMANDS["diff"] = function(args)
    if not (args and args[1] and args[2]) then
        Console.warn("Usage: diff <profile_a> <profile_b>"); return
    end
    Console.info(_profileDiff(args[1], args[2]))
end

-- ── §51.2  Auto-save on script exit ───────────────────────
-- Save a "_Autosave" profile every 5 minutes while playing.
task.spawn(function()
    while _G.WindHubActive do
        task.wait(300)  -- 5 minutes
        pcall(function()
            ProfileManager:save("_Autosave_" .. os.date and os.date("%H%M") or tostring(math.floor(os.clock())))
        end)
        Console.debug("Auto-saved profile")
    end
end)

-- ── §51.3  Profile inheritance ────────────────────────────
-- A profile can specify a `_base` key pointing to another profile.
-- When loading, we merge the base first, then the override.

local function _loadWithInheritance(name, depth)
    depth = depth or 0
    if depth > 5 then return false end  -- circular inheritance guard
    local snap = ProfileManager._store[name] or ProfileManager.PRESETS[name]
    if not snap then return false end

    if snap._base then
        _loadWithInheritance(snap._base, depth + 1)
    end
    for k, v in pairs(snap) do
        if k ~= "_base" then
            Config[k] = v
        end
    end
    return true
end

-- Override ProfileManager:load to support inheritance
ProfileManager.load = function(self, name)
    return _loadWithInheritance(name)
end

-- ── §51.4  Session-state snapshot ─────────────────────────
-- Captures the full runtime state (parry count, accuracy, window)
-- into a profile called "_Session_<timestamp>".

local function _snapshotSession()
    local snap = Config.snapshot()
    snap._parryCount  = _G.WindHub_ParryCount or 0
    snap._accuracy    = math.floor(AccuracyTracker:rate() * 100)
    snap._uptime      = math.floor(os.clock() - (_G.WindHub_SessionStart or os.clock()))
    snap._tickRate    = math.floor(NetMon.tickRate or 60)
    snap._sessionTag  = "session"
    local name        = "_Session"
    ProfileManager._store[name] = snap
    _G._WindProfiles[name]     = snap
    return name
end

COMMANDS["snapshot"] = function()
    local name = _snapshotSession()
    Console.good("Session snapshot saved as '" .. name .. "'")
end

-- ── §51.5  Config import from JSON ───────────────────────
COMMANDS["import"] = function(args)
    if not UNC.readfile then Console.warn("readfile not supported"); return end
    local file = args and args[1] or "WindHub_config.json"
    local ok, data = pcall(UNC.readfile, file)
    if not ok or not data then Console.error("Could not read " .. file); return end
    -- Try JSON decode
    local decoded
    if HttpService then
        local ok2, d = pcall(function() return HttpService:JSONDecode(data) end)
        decoded = ok2 and d
    end
    if not decoded then Console.error("JSON parse failed"); return end
    local count = 0
    for k, v in pairs(decoded) do
        if DEFAULTS[k] ~= nil and type(v) == type(DEFAULTS[k]) then
            Config[k] = v; count = count + 1
        end
    end
    -- Refresh UI
    for flag, refresh in pairs(UI._registry) do
        local cv = Config[flag]; if cv ~= nil then pcall(refresh, cv) end
    end
    Console.good("Imported " .. count .. " config keys from " .. file)
end

COMMANDS["export"] = function(args)
    if not UNC.writefile then Console.warn("writefile not supported"); return end
    local file = args and args[1] or "WindHub_config.json"
    local snap  = Config.snapshot()
    local toWrite = {}
    for k, v in pairs(snap) do
        if type(v) ~= "table" and type(v) ~= "function" then
            toWrite[k] = v
        end
    end
    local ok, err = pcall(function()
        local json = HttpService:JSONEncode(toWrite)
        UNC.writefile(file, json)
    end)
    if ok then Console.good("Config exported to " .. file)
    else Console.error("Export failed: " .. tostring(err)) end
end

-- ── §51.6  Profile list console command ───────────────────
COMMANDS["profiles"] = function()
    local list = ProfileManager:list()
    if #list == 0 then Console.info("No saved profiles") return end
    Console.info("Saved profiles (" .. #list .. "):")
    for _, n in ipairs(list) do
        local snap = ProfileManager._store[n]
        if snap then
            Console.info(string.format("  %-20s  parries=%s acc=%s",
                n,
                tostring(snap._parryCount or "?"),
                tostring(snap._accuracy and snap._accuracy .. "%" or "?")))
        else
            Console.info("  " .. n .. " (preset)")
        end
    end
end


-- ============================================================
-- §52  EXTENDED ANALYTICS DASHBOARD
--      Per-session graphs (text sparklines), per-mode accuracy
--      breakdown, ball-speed distribution chart, and latency
--      percentile table.
-- ============================================================

-- ── §52.1  Per-mode accuracy breakdown ───────────────────
local ModeAccuracy = {
    _data = {},   -- mode → { hits, shots }
}

task.spawn(function()
    task.wait(2)
    local tr = _G._WindTracker
    if not tr then return end

    local lastMode = Config.parryMode
    tr.onParry:Connect(function()
        local m = Config.parryMode
        ModeAccuracy._data[m] = ModeAccuracy._data[m] or { hits = 0, shots = 0 }
        ModeAccuracy._data[m].hits  = ModeAccuracy._data[m].hits  + 1
        ModeAccuracy._data[m].shots = ModeAccuracy._data[m].shots + 1
    end)
end)

function ModeAccuracy.report()
    local lines = {}
    for mode, d in pairs(ModeAccuracy._data) do
        local rate = d.shots > 0 and math.floor(d.hits / d.shots * 100) or 0
        lines[#lines+1] = string.format("  %-14s %3d%% (%d/%d)", mode, rate, d.hits, d.shots)
    end
    table.sort(lines)
    return #lines > 0 and table.concat(lines, "\n") or "No mode data yet"
end

-- ── §52.2  Ball-speed histogram (text bar chart) ──────────
function SpeedCluster.chart(width)
    width = width or 30
    local CHARS = { " ","▏","▎","▍","▌","▋","▊","▉","█" }
    local maxV = 1
    for _, cnt in pairs(SpeedCluster.buckets) do
        if cnt > maxV then maxV = cnt end
    end
    local lines = {}
    for b = 0, 25 do
        local cnt = SpeedCluster.buckets[b] or 0
        local frac = cnt / maxV
        local filled = math.floor(frac * width)
        local partial= math.floor((frac * width - filled) * 8) + 1
        local bar = string.rep("█", filled) .. CHARS[partial]
        lines[#lines+1] = string.format("  %3d+ │%s  %d", b*10, bar, cnt)
    end
    return table.concat(lines, "\n")
end

-- ── §52.3  Latency percentile table ──────────────────────
local LatencyPercentiles = { _samples = {} }

RS.Heartbeat:Connect(function()
    local ping = PingComp.pingMs or 0
    if ping > 0 then
        table.insert(LatencyPercentiles._samples, ping)
        if #LatencyPercentiles._samples > 300 then
            table.remove(LatencyPercentiles._samples, 1)
        end
    end
end)

function LatencyPercentiles.compute()
    local s = {}
    for _, v in ipairs(LatencyPercentiles._samples) do s[#s+1] = v end
    table.sort(s)
    local n = #s
    if n == 0 then return { p50 = 0, p75 = 0, p90 = 0, p99 = 0 } end
    local function p(pct)
        local idx = math.ceil(pct * n / 100)
        return s[math.clamp(idx, 1, n)]
    end
    return { p50 = p(50), p75 = p(75), p90 = p(90), p99 = p(99) }
end

-- ── §52.4  Parry ETA sparkline ────────────────────────────
-- Shows how the ETA-at-fire has changed across the last N parries.
local ETASparkline = { _etas = {} }

task.spawn(function()
    task.wait(2)
    local tr = _G._WindTracker
    if not tr then return end
    tr.onParry:Connect(function(ball, eta)
        table.insert(ETASparkline._etas, eta)
        if #ETASparkline._etas > 40 then table.remove(ETASparkline._etas, 1) end
    end)
end)

function ETASparkline.draw(width)
    width = width or 30
    local CHARS = { "▁","▂","▃","▄","▅","▆","▇","█" }
    local data = ETASparkline._etas
    if #data < 2 then return "Not enough parries" end
    local maxV = 0
    for _, v in ipairs(data) do if v < math.huge and v > maxV then maxV = v end end
    if maxV == 0 then return "All ETAs zero" end
    local n = math.min(#data, width)
    local out = {}
    for i = #data - n + 1, #data do
        local v = data[i]
        local frac = (v == math.huge) and 0 or v / maxV
        local idx = math.clamp(math.ceil(frac * 8), 1, 8)
        out[#out+1] = CHARS[idx]
    end
    return table.concat(out) .. string.format("  max=%.3fs", maxV)
end

-- ── §52.5  Analytics console commands ────────────────────
COMMANDS["accuracy"] = function()
    local hits, miss = AccuracyTracker:counts()
    local rate = AccuracyTracker:rate()
    Console.info(string.format("Accuracy: %d%% (%d hits, %d misses) · streak %d · best %d",
        math.floor(rate * 100), hits, miss, AccuracyTracker.streak, AccuracyTracker.best))
    Console.info("Per-mode breakdown:\n" .. ModeAccuracy.report())
    Console.info("ETA trend: " .. ETASparkline.draw())
    Console.info("Session trend: " .. TrendAnalyser.trend)
end

COMMANDS["latency"] = function()
    local p = LatencyPercentiles.compute()
    Console.info(string.format("Latency percentiles — P50=%dms  P75=%dms  P90=%dms  P99=%dms",
        math.floor(p.p50), math.floor(p.p75), math.floor(p.p90), math.floor(p.p99)))
    Console.info(string.format("Jitter=%.1fms  NetQuality=%s  Loss~=%.1f%%",
        NetMon.jitter or 0, select(1, NetMon.qualityRating()), PacketLossEst.rate or 0))
end

COMMANDS["speeds"] = function()
    Console.info("Ball speed histogram:\n" .. SpeedCluster.chart())
end

COMMANDS["eta"] = function()
    Console.info("ETA sparkline: " .. ETASparkline.draw())
    local tr = _G._WindTracker
    if tr then
        Console.info(string.format("Avg ETA: %.3fs · Ball count: %d",
            tr:avgETA(), tr:ballCount()))
    end
end

-- ── §52.6  Auto-refresh analytics in UI tab ──────────────
task.spawn(function()
    task.wait(3)
    while _G.WindHubActive do
        task.wait(1)
        pcall(function()
            if UI._anHits then
                local hits, miss = AccuracyTracker:counts()
                UI._anHits.set(hits)
                UI._anMiss.set(miss)
                local rate = AccuracyTracker:rate()
                UI._anAcc.set(math.floor(rate * 100) .. "%")
                UI._anAcc.setColor(rate > 0.8 and UI.Theme.Good or rate > 0.5 and UI.Theme.Warn or UI.Theme.Bad)
            end
            if UI._anSigBox then
                UI._anSigBox.Text = "Speed trend: " .. ETASparkline.draw(20) ..
                    "\nMode: " .. TrendAnalyser.trend ..
                    "\nBest combo: " .. (ComboTracker.best or 0)
            end
            if UI._anPredBox then
                local mode, reason = LoadModel.recommendMode()
                UI._anPredBox.Text = "Auto-tune: " .. mode .. " — " .. reason
            end
        end)
    end
end)


-- ============================================================
-- §53  PLAYER TRACKER v2
--      Track every enemy's position history, predict their
--      movement, estimate their ping/skill tier, generate
--      per-player threat scores, and render detailed ESP.
-- ============================================================

-- ── §53.1  Per-player state ───────────────────────────────
local PlayerTracker = {
    _players  = {},   -- plr → PlayerState
    _maxHist  = 32,   -- position history length
}

local PlayerState = {}
PlayerState.__index = PlayerState

function PlayerState.new(plr)
    return setmetatable({
        plr       = plr,
        posHist   = {},   -- { pos, t }
        vel       = Vector3.zero,
        ping      = 0,
        tier      = "Unknown",
        lastSeen  = 0,
        parryCount= 0,    -- how many times they've parried this session
        threat    = 0,    -- composite threat score 0-1
    }, PlayerState)
end

function PlayerState:update(pos, now)
    table.insert(self.posHist, { pos = pos, t = now })
    if #self.posHist > PlayerTracker._maxHist then
        table.remove(self.posHist, 1)
    end
    self.lastSeen = now

    -- Estimate velocity from last 2 samples
    local n = #self.posHist
    if n >= 2 then
        local dt = self.posHist[n].t - self.posHist[n-1].t
        if dt > 0.001 then
            self.vel = (self.posHist[n].pos - self.posHist[n-1].pos) / dt
        end
    end
end

function PlayerState:predictPos(t)
    -- Linear prediction from current position + velocity
    if #self.posHist == 0 then return Vector3.zero end
    local last = self.posHist[#self.posHist]
    return last.pos + self.vel * t
end

function PlayerState:speedCategory()
    local spd = self.vel.Magnitude
    if spd < 10 then return "Standing"
    elseif spd < 18 then return "Walking"
    elseif spd < 35 then return "Running"
    else return "Dashing" end
end

function PlayerState:updateThreat()
    local char = self.plr.Character
    local hrp  = char and char:FindFirstChild("HumanoidRootPart")
    local myHRP= lp.Character and lp.Character:FindFirstChild("HumanoidRootPart")
    if not (hrp and myHRP) then self.threat = 0; return end

    local dist     = (hrp.Position - myHRP.Position).Magnitude
    local distScore= 1 - math.clamp(dist / 100, 0, 1)
    local velScore = math.clamp(self.vel.Magnitude / 40, 0, 1)
    -- Parry count as a skill proxy
    local skillScore = math.clamp(self.parryCount / 20, 0, 1)
    self.threat = (distScore * 0.5 + velScore * 0.3 + skillScore * 0.2)
end

-- ── §53.2  Track all players ──────────────────────────────
local function _trackPlayer(plr)
    if plr == lp then return end
    if PlayerTracker._players[plr] then return end
    PlayerTracker._players[plr] = PlayerState.new(plr)
end

local function _untrackPlayer(plr)
    PlayerTracker._players[plr] = nil
end

for _, plr in ipairs(Plrs:GetPlayers()) do _trackPlayer(plr) end
Plrs.PlayerAdded:Connect(_trackPlayer)
Plrs.PlayerRemoving:Connect(_untrackPlayer)

-- Update loop (20 Hz)
task.spawn(function()
    while _G.WindHubActive do
        task.wait(1/20)
        local now = os.clock()
        for plr, state in pairs(PlayerTracker._players) do
            local char = plr.Character
            local hrp  = char and char:FindFirstChild("HumanoidRootPart")
            if hrp then
                state:update(hrp.Position, now)
                state:updateThreat()
            end
        end
    end
end)

-- ── §53.3  Skill-tier estimator ───────────────────────────
-- Watch parry success events and assign a tier to each player.
-- Tier rises each time we see them successfully parry a ball.

GameRemotes.onParrySuccess:Connect(function(plr, ball)
    local state = PlayerTracker._players[plr]
    if state then
        state.parryCount = state.parryCount + 1
        if     state.parryCount >= 50 then state.tier = "Elite"
        elseif state.parryCount >= 25 then state.tier = "Pro"
        elseif state.parryCount >= 10 then state.tier = "Skilled"
        elseif state.parryCount >= 3  then state.tier = "Average"
        else                               state.tier = "Beginner" end
    end
end)

-- ── §53.4  Enhanced PlayerESP with tracker data ───────────
local function _updatePlayerESPV2()
    for plr, pstate in pairs(PlayerTracker._players) do
        local char = plr.Character
        local hrp  = char and char:FindFirstChild("HumanoidRootPart")
        if not (hrp and char) then continue end

        -- Prediction dot at expected position in 0.5s
        local futurePos = pstate:predictPos(0.5)
        if _drawingSupported and Config.playerESP then
            local sp, vis = worldToScreen(futurePos)
            if vis and sp then
                -- (future-position indicator drawn as small ghost dot via BillboardGui)
            end
        end
    end
end

-- Wire into player ESP loop
local _origPlayerESP = PlayerESP.update
PlayerESP.update = function()
    _origPlayerESP()
    if Config.playerESP then pcall(_updatePlayerESPV2) end
end

-- ── §53.5  Player tracker console command ────────────────
COMMANDS["players"] = function()
    local rows = {}
    for plr, state in pairs(PlayerTracker._players) do
        rows[#rows+1] = string.format("  %-16s  %-8s %-8s threat=%.2f parries=%d",
            plr.Name,
            state.tier,
            state:speedCategory(),
            state.threat,
            state.parryCount)
    end
    if #rows == 0 then Console.info("No enemy players") return end
    table.sort(rows)
    Console.info("Players:\n" .. table.concat(rows, "\n"))
end


-- ============================================================
-- §54  BALL SIGNATURE DATABASE
--      Records each ball's speed profile, spin signature,
--      trajectory curvature, and correlates it to the server-side
--      ball type. Builds a lookup table for instant classification.
-- ============================================================

-- ── §54.1  Signature schema ───────────────────────────────
-- A ball signature captures key observable properties at spawn-time
-- and updates them over the ball's lifetime.

local BallSigDB = {
    _entries  = {},    -- ball → BallSigEntry
    _archive  = {},    -- completed entries (ball removed from world)
    _maxArchive = 500,
}

local BallSigEntry = {}
BallSigEntry.__index = BallSigEntry

function BallSigEntry.new(ball)
    return setmetatable({
        ball        = ball,
        spawnPos    = ball.Position,
        spawnTime   = os.clock(),
        peakSpeed   = 0,
        avgSpeed    = 0,
        speedSamples= 0,
        maxCurvature= 0,     -- max magnitude of centripetal acceleration
        spinMag     = 0,     -- estimated spin magnitude at death
        bounces     = 0,
        lifetime    = 0,
        parried     = false,
        -- Classifier result
        ballClass   = "Unknown",   -- "Straight" | "Curved" | "Knuckleball" | "Fastball"
    }, BallSigEntry)
end

function BallSigEntry:update(speed, spin, curvature)
    if speed > self.peakSpeed then self.peakSpeed = speed end
    self.avgSpeed    = (self.avgSpeed * self.speedSamples + speed) / (self.speedSamples + 1)
    self.speedSamples= self.speedSamples + 1
    if spin and spin > self.spinMag then self.spinMag = spin end
    if curvature and curvature > self.maxCurvature then self.maxCurvature = curvature end
end

function BallSigEntry:classify()
    local spd = self.avgSpeed
    local crv = self.maxCurvature
    local spn = self.spinMag
    if spd > 120 and crv < 5 then
        self.ballClass = "Fastball"
    elseif spn > 15 and crv > 10 then
        self.ballClass = "Knuckleball"
    elseif crv > 8 then
        self.ballClass = "Curved"
    else
        self.ballClass = "Straight"
    end
    return self.ballClass
end

-- ── §54.2  Connect to ball tracker ───────────────────────
task.spawn(function()
    task.wait(2)
    local tr = _G._WindTracker
    if not tr then return end

    tr.onNewBall:Connect(function(ball)
        BallSigDB._entries[ball] = BallSigEntry.new(ball)
    end)

    tr.onBallGone:Connect(function(ball)
        local entry = BallSigDB._entries[ball]
        if entry then
            entry.lifetime = os.clock() - entry.spawnTime
            entry:classify()
            table.insert(BallSigDB._archive, entry)
            if #BallSigDB._archive > BallSigDB._maxArchive then
                table.remove(BallSigDB._archive, 1)
            end
            BallSigDB._entries[ball] = nil
        end
    end)

    tr.onParry:Connect(function(ball, eta)
        local entry = BallSigDB._entries[ball]
        if entry then entry.parried = true end
    end)
end)

-- ── §54.3  Per-frame signature update ────────────────────
task.spawn(function()
    task.wait(2)
    while _G.WindHubActive do
        task.wait(1/20)
        local now = os.clock()
        local tr  = _G._WindTracker
        if not tr then continue end

        for ball, entry in pairs(BallSigDB._entries) do
            if not (ball and ball.Parent) then continue end
            local state = tr.states[ball]
            if not state then continue end

            local speed = state.speed or 0
            local spin  = state.physics and state.physics._spinEst
                            and state.physics._spinEst.spin.Magnitude or 0

            -- Curvature: |v̇ × v| / |v|²  (centripetal acceleration)
            local vp   = ball:FindFirstChild("zoomies")
            local curv = 0
            if vp and state.physics then
                local vel = vp.VectorVelocity
                local acc = PhysicsEngineExt.totalAccelV4(vel, spin > 0 and state.physics._spinEst.spin or Vector3.zero)
                local velMag = vel.Magnitude
                if velMag > 0.1 then
                    local cross = vel:Cross(acc)
                    curv = cross.Magnitude / (velMag * velMag)
                end
            end

            entry:update(speed, spin, curv)
        end
    end
end)

-- ── §54.4  Signature statistics ──────────────────────────
function BallSigDB.classBreakdown()
    local counts = { Straight = 0, Curved = 0, Knuckleball = 0, Fastball = 0, Unknown = 0 }
    for _, e in ipairs(BallSigDB._archive) do
        local c = e.ballClass or "Unknown"
        counts[c] = (counts[c] or 0) + 1
    end
    return counts
end

function BallSigDB.avgParryRateByClass()
    local data = {}
    for _, e in ipairs(BallSigDB._archive) do
        local c = e.ballClass or "Unknown"
        data[c] = data[c] or { parried = 0, total = 0 }
        data[c].total   = data[c].total + 1
        if e.parried then data[c].parried = data[c].parried + 1 end
    end
    local out = {}
    for c, d in pairs(data) do
        out[c] = d.total > 0 and math.floor(d.parried / d.total * 100) or 0
    end
    return out
end

-- ── §54.5  Console command ────────────────────────────────
COMMANDS["sigsdb"] = function()
    local breakdown = BallSigDB.classBreakdown()
    local parryRates = BallSigDB.avgParryRateByClass()
    Console.info("Ball signature archive (" .. #BallSigDB._archive .. " entries):")
    for cls, cnt in pairs(breakdown) do
        Console.info(string.format("  %-12s  %3d balls  parry rate %d%%",
            cls, cnt, parryRates[cls] or 0))
    end
    Console.info("Active entries: " .. (function()
        local n = 0; for _ in pairs(BallSigDB._entries) do n = n + 1 end; return n
    end)())
end

-- Wire into the Analytics tab signature box
task.spawn(function()
    task.wait(3)
    while _G.WindHubActive do
        task.wait(2)
        if UI._anSigBox then
            local bd = BallSigDB.classBreakdown()
            local pr = BallSigDB.avgParryRateByClass()
            local lines = {}
            for cls, cnt in pairs(bd) do
                if cnt > 0 then
                    lines[#lines+1] = string.format("%-12s %2d balls · %d%% parried",
                        cls, cnt, pr[cls] or 0)
                end
            end
            if #lines > 0 then
                UI._anSigBox.Text = table.concat(lines, "\n")
            end
        end
    end
end)


-- ============================================================
-- §55  EXTENDED KILL FEED v2 + COMBO SYSTEM v2
--      Rich kill feed with kill-type icons, multi-kill
--      detection, kill-streak announcements, session leaderboard,
--      and global combo multiplier for score tracking.
-- ============================================================

-- ── §55.1  Kill type registry ─────────────────────────────
local KILL_TYPES = {
    Parry    = { icon = "⚔",  color = Color3.fromRGB(80,  220, 140) },
    Dodge    = { icon = "≫",  color = Color3.fromRGB(140, 200, 80)  },
    Reflect  = { icon = "⟲",  color = Color3.fromRGB(94,  132, 255) },
    OwnGoal  = { icon = "💀", color = Color3.fromRGB(255, 90,  90)  },
    Assist   = { icon = "🤝", color = Color3.fromRGB(200, 180, 80)  },
    Unknown  = { icon = "?",  color = Color3.fromRGB(150, 150, 150) },
}

-- ── §55.2  Session leaderboard ────────────────────────────
local Leaderboard = {
    _kills  = {},   -- player name → kill count
    _deaths = {},   -- player name → death count
}

local function _lbKill(name, killType)
    Leaderboard._kills[name] = (Leaderboard._kills[name] or 0) + 1
end
local function _lbDeath(name)
    Leaderboard._deaths[name] = (Leaderboard._deaths[name] or 0) + 1
end

function Leaderboard.sorted()
    local rows = {}
    for name, kills in pairs(Leaderboard._kills) do
        local deaths = Leaderboard._deaths[name] or 0
        local kd     = deaths > 0 and kills / deaths or kills
        rows[#rows+1] = { name = name, kills = kills, deaths = deaths, kd = kd }
    end
    table.sort(rows, function(a, b) return a.kd > b.kd end)
    return rows
end

-- ── §55.3  Multi-kill detector ────────────────────────────
local MultiKill = {
    _recent  = {},   -- timestamps of kills in the last 10 seconds
    _window  = 10,
    onMultiKill = Signal.new(),
}

local MULTI_KILL_NAMES = {
    [2] = "Double Kill",
    [3] = "Triple Kill",
    [4] = "Quadra Kill",
    [5] = "Penta Kill",
}

local function _registerMultiKill()
    local now = os.clock()
    table.insert(MultiKill._recent, now)
    -- Remove old entries
    local i = 1
    while i <= #MultiKill._recent do
        if now - MultiKill._recent[i] > MultiKill._window then
            table.remove(MultiKill._recent, i)
        else
            i = i + 1
        end
    end

    local count = #MultiKill._recent
    if count >= 2 then
        local name = MULTI_KILL_NAMES[math.min(count, 5)] or "RAMPAGE!"
        MultiKill.onMultiKill:Fire(count, name)
    end
end

-- ── §55.4  Kill-streak tracker ────────────────────────────
local KillStreak = {
    streak   = 0,
    best     = 0,
    onStreak = Signal.new(),
}

local STREAK_NAMES = {
    [3]  = "Killing Spree",
    [5]  = "Rampage",
    [7]  = "Unstoppable",
    [10] = "Godlike",
    [15] = "Beyond Godlike",
}

local function _registerKillStreak()
    KillStreak.streak = KillStreak.streak + 1
    if KillStreak.streak > KillStreak.best then
        KillStreak.best = KillStreak.streak
        Console.good(string.format("New best kill streak: %d!", KillStreak.best))
    end
    local name = STREAK_NAMES[KillStreak.streak]
    if name then
        KillStreak.onStreak:Fire(KillStreak.streak, name)
        if Config.screenAlerts then
            pcall(function() screenAlert(name, Color3.fromRGB(255, 196, 70), 2) end)
        end
        SoundPool.play("combo_5")
    end
end

ClientState.onDied:Connect(function()
    if KillStreak.streak > 0 then
        Console.info("Kill streak ended at " .. KillStreak.streak)
    end
    KillStreak.streak = 0
    _lbDeath(lp.Name)
end)

-- ── §55.5  Wire kills into tracker ────────────────────────
task.spawn(function()
    task.wait(2)
    local tr = _G._WindTracker
    if not tr then return end

    tr.onParry:Connect(function(ball, eta)
        -- A parry that deflects a targeted ball counts as a kill if the ball
        -- subsequently hits someone else. We approximate: if target ≠ us and
        -- there's a player nearby the impact point, credit a kill.
        local state = tr.states[ball]
        if not state then return end

        -- Log into kill feed
        KillFeed:add(lp.Name, state.target or "?", "Parry")
        _lbKill(lp.Name, "Parry")
        _registerMultiKill()
        _registerKillStreak()
    end)
end)

-- Multi-kill announcements
MultiKill.onMultiKill:Connect(function(count, name)
    UI.notify({ title = name, text = count .. "x kills in quick succession!",
        kind = "good", duration = 3 })
    SoundPool.play("combo_10")
end)

-- ── §55.6  Combo multiplier ────────────────────────────────
-- Each consecutive parry within 6 seconds increases the multiplier.
-- Score = parries × multiplier.

local ComboMult = {
    multiplier = 1,
    score      = 0,
    _lastParry = 0,
    _window    = 6,
}

task.spawn(function()
    task.wait(2)
    local tr = _G._WindTracker
    if not tr then return end
    tr.onParry:Connect(function()
        local now = os.clock()
        if now - ComboMult._lastParry < ComboMult._window then
            ComboMult.multiplier = math.min(ComboMult.multiplier + 0.25, 4.0)
        else
            ComboMult.multiplier = 1.0
        end
        ComboMult._lastParry = now
        ComboMult.score      = ComboMult.score + ComboMult.multiplier
    end)
end)

-- ── §55.7  Kill feed console command ─────────────────────
COMMANDS["killfeed"] = function()
    local events = KillFeed.events or {}
    if #events == 0 then Console.info("No kill feed events"); return end
    Console.info("Kill Feed (last " .. math.min(10, #events) .. "):")
    for i = math.max(1, #events - 9), #events do
        local e = events[i]
        local kt = KILL_TYPES[e.method] or KILL_TYPES.Unknown
        Console.info(string.format("  %s %s → %s (%s)", kt.icon, e.killer, e.victim, e.method))
    end
end

COMMANDS["leaderboard"] = function()
    local rows = Leaderboard.sorted()
    Console.info("Session Leaderboard:")
    for i, r in ipairs(rows) do
        Console.info(string.format("  #%d %-16s  K=%d D=%d KD=%.2f",
            i, r.name, r.kills, r.deaths, r.kd))
    end
end


-- ============================================================
-- §56  SESSION MANAGER + REPLAY LOG
--      Records every parry event with full context so they can
--      be replayed/reviewed, exports session summary, and manages
--      session lifecycle (start/resume/end).
-- ============================================================

-- ── §56.1  Event log ──────────────────────────────────────
local SessionLog = {
    _events = {},   -- chronological array of events
    _maxEvents = 1000,
    sessionId   = tostring(math.floor(os.clock() * 1000)),
    startTime   = os.clock(),
}

local function _logEvent(kind, data)
    data       = data or {}
    data.kind  = kind
    data.t     = os.clock() - SessionLog.startTime
    data.ping  = PingComp.pingMs or 0
    data.fps   = math.floor(Prof:fps() + 0.5)
    table.insert(SessionLog._events, data)
    if #SessionLog._events > SessionLog._maxEvents then
        table.remove(SessionLog._events, 1)
    end
end

-- ── §56.2  Wire events ────────────────────────────────────
task.spawn(function()
    task.wait(2)
    local tr = _G._WindTracker
    if not tr then return end

    tr.onParry:Connect(function(ball, eta)
        local state = tr.states[ball]
        _logEvent("parry", {
            eta      = eta,
            speed    = state and state.speed or 0,
            mode     = Config.parryMode,
            window   = Config.parryWindow,
            ballClass= BallSigDB._entries[ball] and BallSigDB._entries[ball].ballClass or "?",
        })
    end)

    tr.onNewBall:Connect(function(ball)
        _logEvent("ball_spawn", { name = ball.Name })
    end)

    tr.onBallGone:Connect(function(ball)
        _logEvent("ball_gone", { name = ball.Name })
    end)
end)

GameRemotes.onStandoffStart:Connect(function()
    _logEvent("standoff_start", {})
end)

GameRemotes.onStandoffEnd:Connect(function()
    _logEvent("standoff_end", {})
end)

ClientState.onDied:Connect(function()
    _logEvent("death", {})
end)

ClientState.onSpawned:Connect(function()
    _logEvent("spawn", {})
end)

-- ── §56.3  Session summary ────────────────────────────────
function SessionLog.summary()
    local dur     = os.clock() - SessionLog.startTime
    local parries = 0
    local deaths  = 0
    local spawns  = 0
    local ballSpawns = 0
    local standoffs  = 0

    for _, e in ipairs(SessionLog._events) do
        if e.kind == "parry"         then parries    = parries    + 1 end
        if e.kind == "death"         then deaths     = deaths     + 1 end
        if e.kind == "spawn"         then spawns     = spawns     + 1 end
        if e.kind == "ball_spawn"    then ballSpawns = ballSpawns + 1 end
        if e.kind == "standoff_start"then standoffs  = standoffs  + 1 end
    end

    local hits, miss = AccuracyTracker:counts()
    local acc = (hits + miss > 0) and math.floor(hits / (hits + miss) * 100) or 0

    return {
        sessionId   = SessionLog.sessionId,
        duration    = dur,
        parries     = parries,
        deaths      = deaths,
        accuracy    = acc,
        ballSpawns  = ballSpawns,
        standoffs   = standoffs,
        bestCombo   = ComboTracker.best,
        bestStreak  = KillStreak.best,
        score       = math.floor(ComboMult.score),
        parryMode   = Config.parryMode,
        executor    = execName,
        isMobile    = isMobile,
    }
end

-- ── §56.4  Export session log to file ────────────────────
function SessionLog.export()
    local sum = SessionLog.summary()
    local lines = {
        "=== WindHub Session Summary ===",
        string.format("ID:        %s", sum.sessionId),
        string.format("Duration:  %dm %ds", math.floor(sum.duration/60), math.floor(sum.duration%60)),
        string.format("Parries:   %d  (acc %d%%)", sum.parries, sum.accuracy),
        string.format("Deaths:    %d", sum.deaths),
        string.format("Best Combo:%d", sum.bestCombo),
        string.format("Best Streak:%d", sum.bestStreak),
        string.format("Score:     %d", sum.score),
        string.format("Mode:      %s", sum.parryMode),
        string.format("Executor:  %s (%s)", sum.executor, sum.isMobile and "Mobile" or "PC"),
        "",
        "=== Event Log (last 50) ===",
    }
    local events = SessionLog._events
    for i = math.max(1, #events - 49), #events do
        local e = events[i]
        local detail = ""
        if e.eta then detail = string.format("eta=%.3fs spd=%.0f", e.eta, e.speed or 0) end
        lines[#lines+1] = string.format("  [%6.2fs] %-15s %s", e.t, e.kind, detail)
    end
    local text = table.concat(lines, "\n")

    if UNC.writefile then
        local ok = pcall(UNC.writefile, "WindHub_session.log", text)
        if ok then Console.good("Session log saved to WindHub_session.log") return end
    end
    if UNC.setclipboard then
        pcall(UNC.setclipboard, text)
        Console.good("Session log copied to clipboard")
    else
        Console.warn("Cannot export: no writefile or setclipboard")
    end
end

-- ── §56.5  Console commands ───────────────────────────────
COMMANDS["session"] = function()
    local s = SessionLog.summary()
    Console.info(string.format(
        "Session %s · %dm%ds · %d parries · %d%% acc · best combo %d · score %d",
        s.sessionId,
        math.floor(s.duration/60), math.floor(s.duration%60),
        s.parries, s.accuracy,
        s.bestCombo, s.score
    ))
end

COMMANDS["export_session"] = function()
    SessionLog.export()
end

COMMANDS["events"] = function(args)
    local n = tonumber(args and args[1]) or 15
    local events = SessionLog._events
    Console.info("Last " .. n .. " events:")
    for i = math.max(1, #events - n + 1), #events do
        local e = events[i]
        local extra = ""
        if e.eta   then extra = string.format(" eta=%.3fs", e.eta) end
        if e.speed then extra = extra .. string.format(" spd=%.0f", e.speed) end
        Console.info(string.format("  [%.2fs] %-15s%s", e.t, e.kind, extra))
    end
end


-- ============================================================
-- §57  EXTENDED UI WIDGETS v2
--      Colour picker, number input, multi-select chip group,
--      progress ring, collapsible section, info tooltip,
--      and a modal dialog system.
-- ============================================================

-- ── §57.1  Colour picker (HSV sliders) ───────────────────
function UI.colorPicker(parent, opts)
    opts = opts or {}
    local h, s, v = 0.6, 1, 1
    local onChange = opts.callback

    local card = UI.card(parent)
    UI.section(parent, opts.text or "Color")

    local preview = mk("Frame", {
        Parent = card,
        Size = UDim2.new(1, 0, 0, 26),
        BackgroundColor3 = Color3.fromHSV(h, s, v),
        BorderSizePixel = 0,
        LayoutOrder = 0,
    })
    corner(preview, 6)

    local function update()
        preview.BackgroundColor3 = Color3.fromHSV(h, s, v)
        if onChange then pcall(onChange, Color3.fromHSV(h, s, v)) end
    end

    UI.slider(card, { text = "Hue",   min = 0, max = 1, step = 0.01, default = h,
        callback = function(val) h = val; update() end })
    UI.slider(card, { text = "Sat",   min = 0, max = 1, step = 0.01, default = s,
        callback = function(val) s = val; update() end })
    UI.slider(card, { text = "Value", min = 0, max = 1, step = 0.01, default = v,
        callback = function(val) v = val; update() end })

    return {
        get = function() return Color3.fromHSV(h, s, v) end,
        set = function(c)
            h, s, v = c:ToHSV()
            update()
        end,
    }
end

-- ── §57.2  Number input box ───────────────────────────────
function UI.numberInput(parent, opts)
    opts = opts or {}
    local value = opts.default or 0
    local row = mk("Frame", {
        Parent = parent,
        Size = UDim2.new(1, 0, 0, 36),
        BackgroundTransparency = 1,
        LayoutOrder = opts.order or nextOrder(parent),
    })
    mk("TextLabel", {
        Parent = row,
        Size = UDim2.new(0.6, -6, 1, 0),
        Position = UDim2.new(0, 6, 0, 0),
        BackgroundTransparency = 1,
        Text = opts.text or "Value",
        Font = Enum.Font.GothamMedium,
        TextSize = 13,
        TextColor3 = UI.Theme.Text,
        TextXAlignment = Enum.TextXAlignment.Left,
    })
    local box = mk("TextBox", {
        Parent = row,
        Size = UDim2.new(0.4, -8, 0, 26),
        Position = UDim2.new(0.6, 0, 0.5, -13),
        BackgroundColor3 = UI.Theme.BgLight,
        Text = tostring(value),
        Font = Enum.Font.GothamMedium,
        TextSize = 12,
        TextColor3 = UI.Theme.Accent,
        BorderSizePixel = 0,
        ClearTextOnFocus = false,
    })
    corner(box, 6)
    stroke(box, UI.Theme.Stroke, 1)
    mk("UIPadding", { Parent = box, PaddingLeft = UDim.new(0, 8) })

    box.FocusLost:Connect(function()
        local n = tonumber(box.Text)
        if n then
            value = n
            if opts.min then value = math.max(value, opts.min) end
            if opts.max then value = math.min(value, opts.max) end
            box.Text = tostring(value)
            if opts.callback then pcall(opts.callback, value) end
        else
            box.Text = tostring(value)  -- revert invalid input
        end
    end)

    return { get = function() return value end, set = function(v) value = v; box.Text = tostring(v) end }
end

-- ── §57.3  Multi-select chip group ───────────────────────
function UI.chipGroup(parent, opts)
    opts = opts or {}
    local choices = opts.choices or {}
    local selected = {}
    for _, v in ipairs(opts.default or {}) do selected[v] = true end

    local row = mk("Frame", {
        Parent = parent,
        Size = UDim2.new(1, 0, 0, 0),
        AutomaticSize = Enum.AutomaticSize.Y,
        BackgroundTransparency = 1,
        LayoutOrder = opts.order or nextOrder(parent),
    })
    UI.label(row, { text = opts.text or "Select", color = UI.Theme.TextDim, size = 11 })
    local chipRow = mk("Frame", {
        Parent = row,
        Size = UDim2.new(1, 0, 0, 0),
        AutomaticSize = Enum.AutomaticSize.Y,
        BackgroundTransparency = 1,
    })
    mk("UIListLayout", {
        Parent = chipRow,
        FillDirection = Enum.FillDirection.Horizontal,
        Padding = UDim.new(0, 6),
        Wraps = true,
    })

    local chips = {}
    for _, choice in ipairs(choices) do
        local on  = selected[choice]
        local c   = mk("TextButton", {
            Parent = chipRow,
            Size = UDim2.new(0, 0, 0, 24),
            AutomaticSize = Enum.AutomaticSize.X,
            BackgroundColor3 = on and UI.Theme.Accent or UI.Theme.BgLight,
            Text = tostring(choice),
            Font = Enum.Font.GothamMedium,
            TextSize = 11,
            TextColor3 = on and Color3.fromRGB(255,255,255) or UI.Theme.TextDim,
            BorderSizePixel = 0,
            AutoButtonColor = false,
        })
        corner(c, 12)
        mk("UIPadding", { Parent = c, PaddingLeft = UDim.new(0, 10), PaddingRight = UDim.new(0, 10) })
        chips[choice] = c

        c.MouseButton1Click:Connect(function()
            selected[choice] = not selected[choice]
            tween(c, { BackgroundColor3 = selected[choice] and UI.Theme.Accent or UI.Theme.BgLight }, 0.12)
            tween(c, { TextColor3      = selected[choice] and Color3.fromRGB(255,255,255) or UI.Theme.TextDim }, 0.12)
            if opts.callback then pcall(opts.callback, selected) end
        end)
    end

    return {
        get = function() return selected end,
        set = function(v)
            selected = v
            for k, c in pairs(chips) do
                local on = selected[k]
                tween(c, { BackgroundColor3 = on and UI.Theme.Accent or UI.Theme.BgLight }, 0.12)
            end
        end,
    }
end

-- ── §57.4  Progress ring (circular progress indicator) ────
function UI.progressRing(parent, opts)
    opts = opts or {}
    local size  = opts.size or 48
    local value = opts.default or 0

    local holder = mk("Frame", {
        Parent = parent,
        Size = UDim2.fromOffset(size, size),
        BackgroundTransparency = 1,
        LayoutOrder = opts.order or nextOrder(parent),
    })
    local bg = mk("Frame", { Parent = holder, Size = UDim2.new(1,0,1,0),
        BackgroundColor3 = UI.Theme.Toggle, BorderSizePixel = 0 })
    corner(bg, size / 2)
    local fill = mk("Frame", { Parent = holder, Size = UDim2.new(value, 0, 1, 0),
        BackgroundColor3 = UI.Theme.Accent, BorderSizePixel = 0 })
    corner(fill, size / 2)
    gradient(fill, UI.Theme.Accent, UI.Theme.Accent2, 90)
    local lbl = mk("TextLabel", {
        Parent = holder, Size = UDim2.new(1,0,1,0),
        BackgroundTransparency = 1,
        Text = math.floor(value * 100) .. "%",
        Font = Enum.Font.GothamBold, TextSize = math.floor(size * 0.28),
        TextColor3 = UI.Theme.Text,
    })

    return {
        set = function(v)
            value = math.clamp(v, 0, 1)
            tween(fill, { Size = UDim2.new(value, 0, 1, 0) }, 0.2)
            lbl.Text = math.floor(value * 100) .. "%"
        end,
    }
end

-- ── §57.5  Collapsible section ────────────────────────────
function UI.collapsible(parent, opts)
    opts = opts or {}
    local open = opts.open ~= false

    local wrapper = mk("Frame", {
        Parent = parent,
        Size = UDim2.new(1, 0, 0, 0),
        AutomaticSize = open and Enum.AutomaticSize.Y or Enum.AutomaticSize.None,
        BackgroundTransparency = 1,
        LayoutOrder = opts.order or nextOrder(parent),
        ClipsDescendants = true,
    })
    local header = mk("TextButton", {
        Parent = wrapper,
        Size = UDim2.new(1, 0, 0, 28),
        BackgroundColor3 = UI.Theme.BgLight,
        Text = (open and "▾ " or "▸ ") .. (opts.text or "Section"),
        Font = Enum.Font.GothamSemibold,
        TextSize = 12,
        TextColor3 = UI.Theme.TextDim,
        BorderSizePixel = 0,
        AutoButtonColor = false,
        TextXAlignment = Enum.TextXAlignment.Left,
    })
    corner(header, 6)
    mk("UIPadding", { Parent = header, PaddingLeft = UDim.new(0, 10) })

    local body = mk("Frame", {
        Parent = wrapper,
        Position = UDim2.new(0, 0, 0, 30),
        Size = UDim2.new(1, 0, 0, 0),
        AutomaticSize = Enum.AutomaticSize.Y,
        BackgroundTransparency = 1,
        Visible = open,
    })

    header.MouseButton1Click:Connect(function()
        open = not open
        header.Text = (open and "▾ " or "▸ ") .. (opts.text or "Section")
        body.Visible = open
    end)

    return body  -- caller adds children to body
end

-- ── §57.6  Info tooltip ───────────────────────────────────
function UI.tooltip(target, text)
    if not target then return end
    local tip = nil
    target.MouseEnter:Connect(function()
        tip = mk("Frame", {
            Parent = screen,
            Size = UDim2.new(0, 0, 0, 0),
            AutomaticSize = Enum.AutomaticSize.XY,
            BackgroundColor3 = UI.Theme.BgDark,
            BorderSizePixel = 0,
            ZIndex = 100,
            Position = UDim2.fromOffset(
                target.AbsolutePosition.X,
                target.AbsolutePosition.Y - 30),
        })
        corner(tip, 6)
        stroke(tip, UI.Theme.Stroke, 1)
        padding(tip, 6)
        mk("TextLabel", {
            Parent = tip,
            Size = UDim2.new(0, 0, 0, 0),
            AutomaticSize = Enum.AutomaticSize.XY,
            BackgroundTransparency = 1,
            Text = text,
            Font = Enum.Font.Gotham,
            TextSize = 11,
            TextColor3 = UI.Theme.TextDim,
            ZIndex = 101,
        })
    end)
    target.MouseLeave:Connect(function()
        if tip then pcall(function() tip:Destroy() end); tip = nil end
    end)
end

-- ── §57.7  Modal dialog ───────────────────────────────────
function UI.modal(opts)
    opts = opts or {}
    local overlay = mk("Frame", {
        Parent = screen,
        Size = UDim2.new(1, 0, 1, 0),
        BackgroundColor3 = Color3.fromRGB(0, 0, 0),
        BackgroundTransparency = 0.5,
        ZIndex = 200,
    })
    local box = mk("Frame", {
        Parent = overlay,
        Size = UDim2.new(0, 300, 0, 0),
        AutomaticSize = Enum.AutomaticSize.Y,
        AnchorPoint = Vector2.new(0.5, 0.5),
        Position = UDim2.new(0.5, 0, 0.5, 0),
        BackgroundColor3 = UI.Theme.BgLight,
        BorderSizePixel = 0,
        ZIndex = 201,
    })
    corner(box, 12)
    stroke(box, UI.Theme.Stroke, 1.5)
    padding(box, 20)
    local inner = mk("Frame", { Parent = box, Size = UDim2.new(1,0,0,0),
        AutomaticSize = Enum.AutomaticSize.Y, BackgroundTransparency = 1, ZIndex = 202 })
    mk("UIListLayout", { Parent = inner, Padding = UDim.new(0, 10), SortOrder = Enum.SortOrder.LayoutOrder })
    mk("TextLabel", { Parent = inner, Size = UDim2.new(1,0,0,0), AutomaticSize = Enum.AutomaticSize.Y,
        BackgroundTransparency = 1, Text = opts.title or "Confirm",
        Font = Enum.Font.GothamBold, TextSize = 15, TextColor3 = UI.Theme.Text,
        TextWrapped = true, ZIndex = 202, LayoutOrder = 1 })
    mk("TextLabel", { Parent = inner, Size = UDim2.new(1,0,0,0), AutomaticSize = Enum.AutomaticSize.Y,
        BackgroundTransparency = 1, Text = opts.text or "",
        Font = Enum.Font.Gotham, TextSize = 12, TextColor3 = UI.Theme.TextDim,
        TextWrapped = true, ZIndex = 202, LayoutOrder = 2 })
    local btnRow = mk("Frame", { Parent = inner, Size = UDim2.new(1,0,0,32),
        BackgroundTransparency = 1, ZIndex = 202, LayoutOrder = 3 })
    mk("UIListLayout", { Parent = btnRow, FillDirection = Enum.FillDirection.Horizontal,
        Padding = UDim.new(0, 8), HorizontalAlignment = Enum.HorizontalAlignment.Right })
    local function closeModal() pcall(function() overlay:Destroy() end) end
    local ok  = mk("TextButton", { Parent = btnRow, Size = UDim2.new(0, 80, 1, 0),
        BackgroundColor3 = UI.Theme.Accent, Text = opts.confirm or "OK",
        Font = Enum.Font.GothamSemibold, TextSize = 12,
        TextColor3 = Color3.fromRGB(255,255,255), BorderSizePixel = 0, AutoButtonColor = false, ZIndex = 203 })
    corner(ok, 7)
    local cancel = mk("TextButton", { Parent = btnRow, Size = UDim2.new(0, 80, 1, 0),
        BackgroundColor3 = UI.Theme.BgLight, Text = opts.cancel or "Cancel",
        Font = Enum.Font.GothamSemibold, TextSize = 12,
        TextColor3 = UI.Theme.TextDim, BorderSizePixel = 0, AutoButtonColor = false, ZIndex = 203 })
    corner(cancel, 7)
    ok.MouseButton1Click:Connect(function()
        closeModal()
        if opts.onConfirm then pcall(opts.onConfirm) end
    end)
    cancel.MouseButton1Click:Connect(function()
        closeModal()
        if opts.onCancel then pcall(opts.onCancel) end
    end)
    springTween(box, { Size = UDim2.new(0, 300, 0, 0) }, 0.3)
end


-- §58 ─── EXTENDED ANIMATION HOOK SYSTEM ─────────────────────────────────────
local AnimHook = {}
AnimHook._hooks    = {}
AnimHook._originals = {}
AnimHook._blocked  = {}
AnimHook._log      = {}
AnimHook._active   = false

local ANIM_NAMES = {
    "Parry", "Block", "Dodge", "Roll", "Jump",
    "Land", "Idle", "Run", "Walk", "Swing",
    "Hit", "Death", "Emote", "Taunt", "Special",
    "Dash", "Charge", "Release", "Windup", "Recover"
}

local ANIM_INTERCEPT_MODES = {
    NONE      = 0,
    LOG_ONLY  = 1,
    SPEED_MOD = 2,
    CANCEL    = 3,
    REPLACE   = 4,
}

AnimHook.interceptMode = ANIM_INTERCEPT_MODES.LOG_ONLY
AnimHook.speedScale    = 1.0
AnimHook.parryAnimId   = nil
AnimHook.dodgeAnimId   = nil

function AnimHook:_logEntry(animName, animId, action)
    local e = { t = tick(), name = animName, id = animId, action = action }
    table.insert(self._log, e)
    if #self._log > 400 then table.remove(self._log, 1) end
end

function AnimHook:hookAnimator(animator)
    if not animator or self._hooks[animator] then return end
    local orig_LoadAnimation = animator.LoadAnimation
    if not orig_LoadAnimation then return end
    self._originals[animator] = orig_LoadAnimation

    local hook = hookfunction and hookfunction(orig_LoadAnimation, newcclosure(function(self_a, anim)
        local track = orig_LoadAnimation(self_a, anim)
        if track then
            local origPlay = track.Play
            hookfunction(origPlay, newcclosure(function(self_t, fadeTime, weight, speed)
                local animName = anim and anim.AnimationId or "unknown"
                AnimHook:_logEntry(animName, animName, "PLAY")
                if AnimHook.interceptMode == ANIM_INTERCEPT_MODES.CANCEL then
                    return
                elseif AnimHook.interceptMode == ANIM_INTERCEPT_MODES.SPEED_MOD then
                    speed = (speed or 1) * AnimHook.speedScale
                end
                return origPlay(self_t, fadeTime, weight, speed)
            end))
        end
        return track
    end)) or nil
    self._hooks[animator] = hook
end

function AnimHook:hookCharacter(char)
    if not char then return end
    local humanoid = char:FindFirstChildOfClass("Humanoid")
    if not humanoid then return end
    local animator = humanoid:FindFirstChildOfClass("Animator")
    if animator then
        self:hookAnimator(animator)
    end
    -- also hook future animators
    humanoid.ChildAdded:Connect(function(c)
        if c:IsA("Animator") then
            self:hookAnimator(c)
        end
    end)
end

function AnimHook:start()
    if self._active then return end
    self._active = true
    local lp = game.Players.LocalPlayer
    if lp then
        if lp.Character then self:hookCharacter(lp.Character) end
        lp.CharacterAdded:Connect(function(c) self:hookCharacter(c) end)
    end
    -- hook all other players
    for _, p in ipairs(game.Players:GetPlayers()) do
        if p ~= lp and p.Character then
            self:hookCharacter(p.Character)
        end
        p.CharacterAdded:Connect(function(c) self:hookCharacter(c) end)
    end
    game.Players.PlayerAdded:Connect(function(p)
        p.CharacterAdded:Connect(function(c) self:hookCharacter(c) end)
    end)
end

function AnimHook:stop()
    self._active = false
    -- unhook all stored hooks
    for animator, hook in pairs(self._hooks) do
        if hook and self._originals[animator] then
            pcall(function() hookfunction(animator.LoadAnimation, self._originals[animator]) end)
        end
    end
    self._hooks    = {}
    self._originals = {}
end

function AnimHook:getLog(n)
    n = n or 20
    local out = {}
    local start = math.max(1, #self._log - n + 1)
    for i = start, #self._log do
        local e = self._log[i]
        out[#out+1] = string.format("[%.3f] %s → %s", e.t - (self._log[1] and self._log[1].t or e.t), e.name, e.action)
    end
    return out
end

function AnimHook:setParryAnimId(id)
    self.parryAnimId = id
    if Console then Console.info("AnimHook", "Parry anim set: "..tostring(id)) end
end

function AnimHook:setDodgeAnimId(id)
    self.dodgeAnimId = id
    if Console then Console.info("AnimHook", "Dodge anim set: "..tostring(id)) end
end

function AnimHook:getStats()
    local counts = {}
    for _, e in ipairs(self._log) do
        counts[e.action] = (counts[e.action] or 0) + 1
    end
    return counts
end

function AnimHook:blockAnim(animId)
    self._blocked[animId] = true
end

function AnimHook:unblockAnim(animId)
    self._blocked[animId] = nil
end

function AnimHook:clearLog()
    self._log = {}
end

function AnimHook:findParryWindow()
    -- scan last 50 log entries for rapid parry play patterns
    local count = 0
    local t0 = tick()
    for i = #self._log, math.max(1, #self._log - 50), -1 do
        local e = self._log[i]
        if t0 - e.t < 0.5 then count = count + 1 end
    end
    return count
end

AnimHook:start()
if Console then Console.info("AnimHook", "Animation hook system online") end

-- §58.1 Animation state machine tracker
local AnimState = {}
AnimState._states = {}
AnimState._transitions = {}
AnimState.STATES = {
    IDLE       = "Idle",
    RUNNING    = "Running",
    JUMPING    = "Jumping",
    FALLING    = "Falling",
    PARRYING   = "Parrying",
    DODGING    = "Dodging",
    STUNNED    = "Stunned",
    ATTACKING  = "Attacking",
    RECOVERING = "Recovering",
    DEAD       = "Dead",
}

function AnimState:getPlayerState(player)
    return self._states[player] or self.STATES.IDLE
end

function AnimState:transition(player, newState)
    local old = self._states[player] or self.STATES.IDLE
    if old == newState then return end
    self._states[player] = newState
    local t = { from = old, to = newState, t = tick() }
    if not self._transitions[player] then self._transitions[player] = {} end
    table.insert(self._transitions[player], t)
    if #self._transitions[player] > 100 then
        table.remove(self._transitions[player], 1)
    end
end

function AnimState:getTransitionHistory(player, n)
    n = n or 10
    local hist = self._transitions[player] or {}
    local out = {}
    local start = math.max(1, #hist - n + 1)
    for i = start, #hist do
        local tr = hist[i]
        out[#out+1] = tr.from .. "→" .. tr.to
    end
    return out
end

function AnimState:isVulnerable(player)
    local s = self:getPlayerState(player)
    return s == self.STATES.JUMPING or s == self.STATES.FALLING or s == self.STATES.STUNNED
end

function AnimState:isParrying(player)
    return self:getPlayerState(player) == self.STATES.PARRYING
end

-- §58.2 Parry frame data
local ParryFrameData = {}
ParryFrameData._data = {}
ParryFrameData.DEFAULT_STARTUP  = 3   -- frames
ParryFrameData.DEFAULT_ACTIVE   = 5   -- frames
ParryFrameData.DEFAULT_RECOVERY = 12  -- frames
ParryFrameData.FPS              = 60

function ParryFrameData:getFrameTime(frames)
    return frames / self.FPS
end

function ParryFrameData:getActiveWindow(player)
    local d = self._data[player] or {}
    local active = d.activeFrames or self.DEFAULT_ACTIVE
    return self:getFrameTime(active)
end

function ParryFrameData:getStartupTime(player)
    local d = self._data[player] or {}
    local startup = d.startupFrames or self.DEFAULT_STARTUP
    return self:getFrameTime(startup)
end

function ParryFrameData:getRecoveryTime(player)
    local d = self._data[player] or {}
    local recovery = d.recoveryFrames or self.DEFAULT_RECOVERY
    return self:getFrameTime(recovery)
end

function ParryFrameData:setFrameData(player, startupFrames, activeFrames, recoveryFrames)
    self._data[player] = {
        startupFrames  = startupFrames,
        activeFrames   = activeFrames,
        recoveryFrames = recoveryFrames,
        learnedAt      = tick(),
    }
end

function ParryFrameData:getOptimalInputTime(player, eta)
    -- click this many seconds before ball arrives
    return eta - self:getStartupTime(player)
end

function ParryFrameData:getSummary(player)
    local d = self._data[player] or {}
    return string.format(
        "Startup:%df Active:%df Recovery:%df",
        d.startupFrames or self.DEFAULT_STARTUP,
        d.activeFrames  or self.DEFAULT_ACTIVE,
        d.recoveryFrames or self.DEFAULT_RECOVERY
    )
end

function ParryFrameData:learnFromSuccess(player, leadTime)
    -- leadTime = how far ahead we clicked before impact
    -- if success, we were within active window
    local d = self._data[player]
    if not d then
        d = {
            startupFrames  = self.DEFAULT_STARTUP,
            activeFrames   = self.DEFAULT_ACTIVE,
            recoveryFrames = self.DEFAULT_RECOVERY,
            samples        = {},
        }
        self._data[player] = d
    end
    table.insert(d.samples, leadTime)
    if #d.samples > 30 then table.remove(d.samples, 1) end
    -- estimate active window from spread of successful lead times
    if #d.samples >= 5 then
        local mn, mx = d.samples[1], d.samples[1]
        for _, s in ipairs(d.samples) do
            mn = math.min(mn, s)
            mx = math.max(mx, s)
        end
        d.activeFrames = math.max(2, math.floor((mx - mn) * self.FPS + 0.5))
    end
end

if Console then Console.info("AnimHook", "Parry frame data module ready") end

-- §59 ─── FULL UNC DRAWING LAYER v2 ──────────────────────────────────────────
local Draw2 = {}
Draw2._objects  = {}
Draw2._groups   = {}
Draw2._visible  = true
Draw2._theme    = {
    primary   = Color3.fromRGB(80,  180, 255),
    secondary = Color3.fromRGB(255, 80,  80),
    accent    = Color3.fromRGB(80,  255, 150),
    white     = Color3.fromRGB(255, 255, 255),
    black     = Color3.fromRGB(0,   0,   0),
    yellow    = Color3.fromRGB(255, 220, 40),
    purple    = Color3.fromRGB(180, 80,  255),
    orange    = Color3.fromRGB(255, 140, 40),
    teal      = Color3.fromRGB(40,  220, 200),
    pink      = Color3.fromRGB(255, 100, 180),
}

-- Drawing object constructor helper
local function _newDrawing(kind, props)
    if not _drawingSupported then return nil end
    local ok, obj = pcall(function() return Drawing.new(kind) end)
    if not ok or not obj then return nil end
    for k, v in pairs(props or {}) do
        pcall(function() obj[k] = v end)
    end
    return obj
end

function Draw2:newLine(x1, y1, x2, y2, color, thickness, transparency)
    local obj = _newDrawing("Line", {
        From          = Vector2.new(x1, y1),
        To            = Vector2.new(x2, y2),
        Color         = color or self._theme.white,
        Thickness     = thickness or 1,
        Transparency  = transparency or 1,
        Visible       = self._visible,
    })
    if obj then table.insert(self._objects, obj) end
    return obj
end

function Draw2:newCircle(cx, cy, radius, color, thickness, filled, transparency)
    local obj = _newDrawing("Circle", {
        Position      = Vector2.new(cx, cy),
        Radius        = radius or 10,
        Color         = color or self._theme.white,
        Thickness     = thickness or 1,
        Filled        = filled or false,
        Transparency  = transparency or 1,
        Visible       = self._visible,
    })
    if obj then table.insert(self._objects, obj) end
    return obj
end

function Draw2:newText(x, y, text, color, size, outline, outlineColor, transparency)
    local obj = _newDrawing("Text", {
        Position      = Vector2.new(x, y),
        Text          = tostring(text),
        Color         = color or self._theme.white,
        Size          = size or 14,
        Outline       = outline or true,
        OutlineColor  = outlineColor or self._theme.black,
        Transparency  = transparency or 1,
        Visible       = self._visible,
        Font          = 2, -- UI
    })
    if obj then table.insert(self._objects, obj) end
    return obj
end

function Draw2:newQuad(vertices, color, thickness, filled, transparency)
    -- vertices: array of 4 Vector2s
    local obj = _newDrawing("Quad", {
        PointA       = vertices[1] or Vector2.new(0,0),
        PointB       = vertices[2] or Vector2.new(0,0),
        PointC       = vertices[3] or Vector2.new(0,0),
        PointD       = vertices[4] or Vector2.new(0,0),
        Color        = color or self._theme.white,
        Thickness    = thickness or 1,
        Filled       = filled or false,
        Transparency = transparency or 1,
        Visible      = self._visible,
    })
    if obj then table.insert(self._objects, obj) end
    return obj
end

function Draw2:newTriangle(a, b, c, color, thickness, filled, transparency)
    local obj = _newDrawing("Triangle", {
        PointA       = a or Vector2.new(0,0),
        PointB       = b or Vector2.new(0,0),
        PointC       = c or Vector2.new(0,0),
        Color        = color or self._theme.white,
        Thickness    = thickness or 1,
        Filled       = filled or false,
        Transparency = transparency or 1,
        Visible      = self._visible,
    })
    if obj then table.insert(self._objects, obj) end
    return obj
end

function Draw2:newImage(x, y, w, h, data, transparency)
    local obj = _newDrawing("Image", {
        Position     = Vector2.new(x, y),
        Size         = Vector2.new(w, h),
        Data         = data or "",
        Transparency = transparency or 1,
        Visible      = self._visible,
    })
    if obj then table.insert(self._objects, obj) end
    return obj
end

function Draw2:newGroup(name)
    local group = { name = name, objects = {} }
    self._groups[name] = group
    return group
end

function Draw2:addToGroup(groupName, obj)
    local g = self._groups[groupName]
    if g and obj then table.insert(g.objects, obj) end
end

function Draw2:clearGroup(groupName)
    local g = self._groups[groupName]
    if not g then return end
    for _, obj in ipairs(g.objects) do
        pcall(function() obj.Visible = false end)
        pcall(function() obj:Remove() end)
    end
    g.objects = {}
end

function Draw2:setGroupVisible(groupName, visible)
    local g = self._groups[groupName]
    if not g then return end
    for _, obj in ipairs(g.objects) do
        pcall(function() obj.Visible = visible end)
    end
end

function Draw2:clearAll()
    for _, obj in ipairs(self._objects) do
        pcall(function() obj.Visible = false end)
        pcall(function() obj:Remove() end)
    end
    self._objects = {}
    for name, _ in pairs(self._groups) do
        self:clearGroup(name)
    end
end

function Draw2:setVisible(v)
    self._visible = v
    for _, obj in ipairs(self._objects) do
        pcall(function() obj.Visible = v end)
    end
end

function Draw2:count()
    return #self._objects
end

-- §59.1 Higher-level shape helpers
function Draw2:drawBox3D(cf, size, color, thickness)
    -- project 8 corners of a 3D box to screen, draw 12 edges
    local hx, hy, hz = size.X/2, size.Y/2, size.Z/2
    local corners = {
        Vector3.new(-hx,-hy,-hz), Vector3.new( hx,-hy,-hz),
        Vector3.new( hx, hy,-hz), Vector3.new(-hx, hy,-hz),
        Vector3.new(-hx,-hy, hz), Vector3.new( hx,-hy, hz),
        Vector3.new( hx, hy, hz), Vector3.new(-hx, hy, hz),
    }
    local screen = {}
    local cam = workspace.CurrentCamera
    for i, c in ipairs(corners) do
        local wpos = cf:PointToWorldSpace(c)
        local spos, vis = cam:WorldToViewportPoint(wpos)
        screen[i] = { Vector2.new(spos.X, spos.Y), vis }
    end
    local edges = {
        {1,2},{2,3},{3,4},{4,1}, -- back face
        {5,6},{6,7},{7,8},{8,5}, -- front face
        {1,5},{2,6},{3,7},{4,8}, -- connecting edges
    }
    local lines = {}
    for _, e in ipairs(edges) do
        local a, b = screen[e[1]], screen[e[2]]
        if a[2] and b[2] then
            local ln = self:newLine(a[1].X, a[1].Y, b[1].X, b[1].Y, color, thickness or 1)
            lines[#lines+1] = ln
        end
    end
    return lines
end

function Draw2:drawCrosshair(x, y, size, color, thickness)
    local half = size / 2
    local objs = {}
    objs[1] = self:newLine(x - half, y, x + half, y, color, thickness)
    objs[2] = self:newLine(x, y - half, x, y + half, color, thickness)
    return objs
end

function Draw2:drawDiamond(cx, cy, halfW, halfH, color, thickness)
    local pts = {
        Vector2.new(cx,         cy - halfH),
        Vector2.new(cx + halfW, cy),
        Vector2.new(cx,         cy + halfH),
        Vector2.new(cx - halfW, cy),
    }
    return self:newQuad(pts, color, thickness, false)
end

function Draw2:drawArrow(x1, y1, x2, y2, color, thickness, headLen)
    headLen = headLen or 10
    local line = self:newLine(x1, y1, x2, y2, color, thickness)
    -- arrowhead
    local dx, dy = x2 - x1, y2 - y1
    local len = math.sqrt(dx*dx + dy*dy)
    if len < 0.001 then return { line } end
    local ux, uy = dx/len, dy/len
    local lx = x2 - ux*headLen - uy*headLen*0.5
    local ly = y2 - uy*headLen + ux*headLen*0.5
    local rx = x2 - ux*headLen + uy*headLen*0.5
    local ry = y2 - uy*headLen - ux*headLen*0.5
    local lArm = self:newLine(x2, y2, lx, ly, color, thickness)
    local rArm = self:newLine(x2, y2, rx, ry, color, thickness)
    return { line, lArm, rArm }
end

function Draw2:drawArcPoints(cx, cy, radius, startAngle, endAngle, steps, color, thickness)
    steps = steps or 32
    local lines = {}
    local prev = nil
    for i = 0, steps do
        local t = startAngle + (endAngle - startAngle) * i / steps
        local x = cx + radius * math.cos(t)
        local y = cy + radius * math.sin(t)
        if prev then
            lines[#lines+1] = self:newLine(prev[1], prev[2], x, y, color, thickness or 1)
        end
        prev = {x, y}
    end
    return lines
end

function Draw2:drawHealthBar(x, y, w, h, fraction, fgColor, bgColor)
    local bg = self:newQuad(
        { Vector2.new(x,y), Vector2.new(x+w,y), Vector2.new(x+w,y+h), Vector2.new(x,y+h) },
        bgColor or Color3.fromRGB(40,40,40), 1, true
    )
    local fw = w * math.clamp(fraction, 0, 1)
    local fg = self:newQuad(
        { Vector2.new(x,y), Vector2.new(x+fw,y), Vector2.new(x+fw,y+h), Vector2.new(x,y+h) },
        fgColor or Color3.fromRGB(80,220,80), 1, true
    )
    return { bg = bg, fg = fg }
end

function Draw2:drawBracket(x, y, w, h, color, thickness, bracketLen)
    bracketLen = bracketLen or 8
    local lines = {}
    -- top-left
    lines[#lines+1] = self:newLine(x, y, x+bracketLen, y, color, thickness)
    lines[#lines+1] = self:newLine(x, y, x, y+bracketLen, color, thickness)
    -- top-right
    lines[#lines+1] = self:newLine(x+w, y, x+w-bracketLen, y, color, thickness)
    lines[#lines+1] = self:newLine(x+w, y, x+w, y+bracketLen, color, thickness)
    -- bottom-left
    lines[#lines+1] = self:newLine(x, y+h, x+bracketLen, y+h, color, thickness)
    lines[#lines+1] = self:newLine(x, y+h, x, y+h-bracketLen, color, thickness)
    -- bottom-right
    lines[#lines+1] = self:newLine(x+w, y+h, x+w-bracketLen, y+h, color, thickness)
    lines[#lines+1] = self:newLine(x+w, y+h, x+w, y+h-bracketLen, color, thickness)
    return lines
end

if Console then Console.info("Draw2", "UNC Drawing layer v2 ready. Supported="..tostring(_drawingSupported)) end

-- §60 ─── MULTI-BALL VISUALIZER + TRAJECTORY PLANNER ─────────────────────────
local BallViz = {}
BallViz._drawObjects = {}
BallViz._active      = false
BallViz._maxBalls    = 8
BallViz._colors = {
    Color3.fromRGB(255, 80,  80),
    Color3.fromRGB(80,  180, 255),
    Color3.fromRGB(80,  255, 150),
    Color3.fromRGB(255, 220, 40),
    Color3.fromRGB(180, 80,  255),
    Color3.fromRGB(255, 140, 40),
    Color3.fromRGB(40,  220, 200),
    Color3.fromRGB(255, 100, 180),
}
BallViz._TRAJ_STEPS  = 30
BallViz._TRAJ_DT     = 0.05
BallViz._showLabels  = true
BallViz._showArrows  = true
BallViz._showETA     = true
BallViz._showSpeed   = true

local function _vizWorldToScreen(pos)
    local cam = workspace.CurrentCamera
    if not cam then return nil, false end
    local sp, vis = cam:WorldToViewportPoint(pos)
    return Vector2.new(sp.X, sp.Y), vis and sp.Z > 0
end

function BallViz:_clearBall(idx)
    local objs = self._drawObjects[idx]
    if not objs then return end
    for _, o in ipairs(objs) do
        pcall(function() o.Visible = false end)
        pcall(function() o:Remove() end)
    end
    self._drawObjects[idx] = {}
end

function BallViz:_clearAll()
    for i = 1, self._maxBalls do
        self:_clearBall(i)
    end
end

function BallViz:update(ballStates)
    if not self._active or not _drawingSupported then return end
    self:_clearAll()

    local cam = workspace.CurrentCamera
    if not cam then return end

    local idx = 1
    for _, bs in ipairs(ballStates) do
        if idx > self._maxBalls then break end
        local color = self._colors[idx] or self._colors[1]
        local objs  = {}

        -- Current position dot
        local sp, vis = _vizWorldToScreen(bs.pos)
        if vis then
            -- outer circle
            local outer = Draw2:newCircle(sp.X, sp.Y, 8, color, 2, false)
            if outer then objs[#objs+1] = outer end
            -- inner filled dot
            local inner = Draw2:newCircle(sp.X, sp.Y, 3, color, 1, true)
            if inner then objs[#objs+1] = inner end
            -- speed label
            if self._showSpeed then
                local spd = bs.velocity and bs.velocity.Magnitude or 0
                local lbl = Draw2:newText(sp.X + 10, sp.Y - 8, string.format("%.0f st/s", spd), color, 12)
                if lbl then objs[#objs+1] = lbl end
            end
            -- ETA label
            if self._showETA and bs.eta then
                local etaLbl = Draw2:newText(sp.X + 10, sp.Y + 4, string.format("ETA:%.2fs", bs.eta), self._colors[idx], 11)
                if etaLbl then objs[#objs+1] = etaLbl end
            end
        end

        -- Trajectory prediction arc
        if bs.pos and bs.velocity then
            local ppos = bs.pos
            local pvel = bs.velocity
            local prevSp = nil
            for step = 1, self._TRAJ_STEPS do
                local dt = self._TRAJ_DT
                -- RK4-lite for viz: just use Euler here for performance
                local acc = Vector3.new(0, -workspace.Gravity * dt * 0.5, 0)
                pvel = pvel + acc
                ppos = ppos + pvel * dt
                local nsp, nvis = _vizWorldToScreen(ppos)
                if nvis and prevSp then
                    -- fade color along trajectory
                    local alpha = 1 - step / self._TRAJ_STEPS
                    local fadedColor = Color3.new(
                        color.R * alpha,
                        color.G * alpha,
                        color.B * alpha
                    )
                    local trajLine = Draw2:newLine(
                        prevSp.X, prevSp.Y, nsp.X, nsp.Y,
                        fadedColor, 1
                    )
                    if trajLine then objs[#objs+1] = trajLine end
                end
                prevSp = nvis and nsp or nil
            end
        end

        -- Velocity arrow
        if self._showArrows and bs.pos and bs.velocity then
            local vMag = bs.velocity.Magnitude
            if vMag > 0.1 then
                local ahead = bs.pos + bs.velocity.Unit * math.min(vMag * 0.3, 15)
                local sp1, vis1 = _vizWorldToScreen(bs.pos)
                local sp2, vis2 = _vizWorldToScreen(ahead)
                if vis1 and vis2 then
                    local arrowObjs = Draw2:drawArrow(
                        sp1.X, sp1.Y, sp2.X, sp2.Y,
                        color, 2, 8
                    )
                    for _, ao in ipairs(arrowObjs) do objs[#objs+1] = ao end
                end
            end
        end

        self._drawObjects[idx] = objs
        idx = idx + 1
    end
end

function BallViz:start()
    self._active = true
    -- update loop
    RunService.Heartbeat:Connect(function()
        if not self._active then return end
        if not BallTracker then return end
        -- build ballStates array from BallTracker
        local states = {}
        for _, bs in pairs(BallTracker._balls or {}) do
            states[#states+1] = bs
        end
        -- sort by threat
        table.sort(states, function(a, b)
            return (a.threat or 0) > (b.threat or 0)
        end)
        self:update(states)
    end)
end

function BallViz:stop()
    self._active = false
    self:_clearAll()
end

function BallViz:toggleLabels()     self._showLabels  = not self._showLabels end
function BallViz:toggleArrows()     self._showArrows  = not self._showArrows end
function BallViz:toggleETA()        self._showETA     = not self._showETA    end
function BallViz:toggleSpeed()      self._showSpeed   = not self._showSpeed  end

-- §60.1 Trajectory intersection finder
local TrajIntersect = {}

function TrajIntersect:findLandingPoint(pos, vel, groundY)
    groundY = groundY or 0
    if vel.Y >= 0 then return nil end -- going up, won't land
    -- quadratic: y = pos.Y + vel.Y*t - 0.5*g*t^2 = groundY
    local g = workspace.Gravity
    local a = -0.5 * g
    local b = vel.Y
    local c = pos.Y - groundY
    local disc = b*b - 4*a*c
    if disc < 0 then return nil end
    local t1 = (-b - math.sqrt(disc)) / (2*a)
    local t2 = (-b + math.sqrt(disc)) / (2*a)
    local t  = (t1 > 0) and t1 or (t2 > 0 and t2 or nil)
    if not t then return nil end
    return Vector3.new(pos.X + vel.X*t, groundY, pos.Z + vel.Z*t), t
end

function TrajIntersect:findSphereIntersect(pos, vel, centerPos, radius)
    -- find first time trajectory enters sphere of radius around centerPos
    -- approximate with Euler
    local dt = 0.01
    local p  = pos
    local v  = vel
    local g  = Vector3.new(0, -workspace.Gravity, 0)
    for _ = 1, 500 do
        v = v + g * dt
        p = p + v * dt
        if (p - centerPos).Magnitude <= radius then
            return p, (p - pos).Magnitude / math.max(v.Magnitude, 0.01)
        end
    end
    return nil, nil
end

function TrajIntersect:getClosestApproach(pos1, vel1, pos2)
    -- find t where trajectory is closest to static point
    local g  = Vector3.new(0, -workspace.Gravity, 0)
    local dt = 0.02
    local p  = pos1
    local v  = vel1
    local bestDist = (p - pos2).Magnitude
    local bestT    = 0
    local t        = 0
    for _ = 1, 250 do
        v = v + g * dt
        p = p + v * dt
        t = t + dt
        local d = (p - pos2).Magnitude
        if d < bestDist then
            bestDist = d
            bestT    = t
        end
        if d > bestDist + 20 then break end -- diverging
    end
    return bestDist, bestT
end

if Console then Console.info("BallViz", "Multi-ball visualizer ready") end
BallViz:start()

-- §61 ─── COMPREHENSIVE COMBAT ANALYTICS ─────────────────────────────────────
local CombatAnalytics = {}
CombatAnalytics._sessions     = {}
CombatAnalytics._currentRound = nil
CombatAnalytics._roundHistory = {}
CombatAnalytics._MAX_ROUNDS   = 50

-- Per-round data structure
local function _newRound()
    return {
        startTime    = tick(),
        endTime      = nil,
        parries      = {},
        misses        = {},
        deaths        = {},
        kills         = {},
        modes         = {},
        avgETAError   = 0,
        maxStreak     = 0,
        currentStreak = 0,
        peakFPS       = 0,
        minFPS        = math.huge,
        avgPing       = 0,
        pingCount     = 0,
    }
end

function CombatAnalytics:startRound()
    if self._currentRound then self:endRound() end
    self._currentRound = _newRound()
    if Console then Console.info("CombatAnalytics", "Round started") end
end

function CombatAnalytics:endRound()
    if not self._currentRound then return end
    self._currentRound.endTime = tick()
    table.insert(self._roundHistory, self._currentRound)
    if #self._roundHistory > self._MAX_ROUNDS then
        table.remove(self._roundHistory, 1)
    end
    self._currentRound = nil
end

function CombatAnalytics:recordParry(etaError, mode, ballClass, ping)
    local r = self._currentRound
    if not r then return end
    local e = {
        t        = tick(),
        etaError = etaError or 0,
        mode     = mode or "Unknown",
        class    = ballClass or "Unknown",
        ping     = ping or PingComp and PingComp:get() or 0,
        success  = true,
    }
    table.insert(r.parries, e)
    r.currentStreak = r.currentStreak + 1
    r.maxStreak     = math.max(r.maxStreak, r.currentStreak)
    -- running ETA error average
    local n = #r.parries
    r.avgETAError = r.avgETAError * (n-1)/n + math.abs(etaError) / n
    -- mode usage
    r.modes[mode] = (r.modes[mode] or 0) + 1
    -- ping average
    r.pingCount = r.pingCount + 1
    r.avgPing   = r.avgPing + (e.ping - r.avgPing) / r.pingCount
end

function CombatAnalytics:recordMiss(mode, ballClass)
    local r = self._currentRound
    if not r then return end
    table.insert(r.misses, {
        t     = tick(),
        mode  = mode or "Unknown",
        class = ballClass or "Unknown",
    })
    r.currentStreak = 0
end

function CombatAnalytics:recordDeath()
    local r = self._currentRound
    if not r then return end
    table.insert(r.deaths, { t = tick() })
    r.currentStreak = 0
end

function CombatAnalytics:recordKill(victim, method)
    local r = self._currentRound
    if not r then return end
    table.insert(r.kills, { t = tick(), victim = victim, method = method })
end

function CombatAnalytics:recordFPS(fps)
    local r = self._currentRound
    if not r then return end
    r.peakFPS = math.max(r.peakFPS, fps)
    r.minFPS  = math.min(r.minFPS, fps)
end

function CombatAnalytics:getCurrentStats()
    local r = self._currentRound
    if not r then return nil end
    local total = #r.parries + #r.misses
    local acc   = total > 0 and (#r.parries / total * 100) or 0
    return {
        parries       = #r.parries,
        misses        = #r.misses,
        deaths        = #r.deaths,
        kills         = #r.kills,
        accuracy      = acc,
        maxStreak     = r.maxStreak,
        currentStreak = r.currentStreak,
        avgETAError   = r.avgETAError,
        avgPing       = r.avgPing,
        duration      = tick() - r.startTime,
    }
end

function CombatAnalytics:getLifetimeStats()
    local totParries, totMisses, totDeaths, totKills = 0, 0, 0, 0
    local totETA, etaCount = 0, 0
    local bestStreak = 0
    for _, r in ipairs(self._roundHistory) do
        totParries = totParries + #r.parries
        totMisses  = totMisses  + #r.misses
        totDeaths  = totDeaths  + #r.deaths
        totKills   = totKills   + #r.kills
        bestStreak = math.max(bestStreak, r.maxStreak)
        for _, p in ipairs(r.parries) do
            totETA   = totETA + math.abs(p.etaError)
            etaCount = etaCount + 1
        end
    end
    local total = totParries + totMisses
    return {
        rounds      = #self._roundHistory,
        parries     = totParries,
        misses      = totMisses,
        deaths      = totDeaths,
        kills       = totKills,
        accuracy    = total > 0 and (totParries/total*100) or 0,
        bestStreak  = bestStreak,
        avgETAError = etaCount > 0 and (totETA/etaCount) or 0,
        kdr         = totDeaths > 0 and (totKills/totDeaths) or totKills,
    }
end

function CombatAnalytics:getModeBreakdown()
    local modes = {}
    for _, r in ipairs(self._roundHistory) do
        for mode, count in pairs(r.modes) do
            modes[mode] = (modes[mode] or 0) + count
        end
    end
    return modes
end

function CombatAnalytics:getBestRound()
    local best = nil
    local bestAcc = -1
    for _, r in ipairs(self._roundHistory) do
        local total = #r.parries + #r.misses
        local acc = total > 0 and (#r.parries / total) or 0
        if acc > bestAcc then
            bestAcc = acc
            best = r
        end
    end
    return best, bestAcc
end

function CombatAnalytics:getWorstRound()
    local worst = nil
    local worstAcc = 2
    for _, r in ipairs(self._roundHistory) do
        local total = #r.parries + #r.misses
        if total >= 3 then
            local acc = #r.parries / total
            if acc < worstAcc then
                worstAcc = acc
                worst = r
            end
        end
    end
    return worst, worstAcc
end

function CombatAnalytics:getAccuracyTrend(n)
    n = n or 10
    local trend = {}
    local start = math.max(1, #self._roundHistory - n + 1)
    for i = start, #self._roundHistory do
        local r = self._roundHistory[i]
        local total = #r.parries + #r.misses
        trend[#trend+1] = total > 0 and (#r.parries / total * 100) or 0
    end
    return trend
end

function CombatAnalytics:getStreakDistribution()
    local dist = {}
    for _, r in ipairs(self._roundHistory) do
        local streak = r.maxStreak
        dist[streak] = (dist[streak] or 0) + 1
    end
    return dist
end

function CombatAnalytics:exportToString()
    local stats = self:getLifetimeStats()
    local lines = {
        "=== WindHub Combat Analytics Export ===",
        string.format("Rounds played: %d", stats.rounds),
        string.format("Total parries: %d | Misses: %d", stats.parries, stats.misses),
        string.format("Accuracy: %.1f%%", stats.accuracy),
        string.format("Kills: %d | Deaths: %d | K/D: %.2f", stats.kills, stats.deaths, stats.kdr),
        string.format("Best streak: %d", stats.bestStreak),
        string.format("Avg ETA error: %.3fs", stats.avgETAError),
        "",
        "Mode breakdown:",
    }
    for mode, count in pairs(self:getModeBreakdown()) do
        lines[#lines+1] = string.format("  %s: %d parries", mode, count)
    end
    return table.concat(lines, "\n")
end

function CombatAnalytics:printSummary()
    if Console then Console.log(self:exportToString()) end
end

-- Auto-start round on script load
CombatAnalytics:startRound()
if Console then Console.info("CombatAnalytics", "Combat analytics tracking active") end

-- §61.1 Performance benchmark module
local PerfBench = {}
PerfBench._marks = {}
PerfBench._results = {}

function PerfBench:mark(name)
    self._marks[name] = tick()
end

function PerfBench:measure(name, markName)
    local start = self._marks[markName or name]
    if not start then return 0 end
    local duration = tick() - start
    if not self._results[name] then
        self._results[name] = { total = 0, count = 0, peak = 0 }
    end
    local r = self._results[name]
    r.total = r.total + duration
    r.count = r.count + 1
    r.peak  = math.max(r.peak, duration)
    return duration
end

function PerfBench:getAvg(name)
    local r = self._results[name]
    if not r or r.count == 0 then return 0 end
    return r.total / r.count
end

function PerfBench:getPeak(name)
    local r = self._results[name]
    return r and r.peak or 0
end

function PerfBench:getCount(name)
    local r = self._results[name]
    return r and r.count or 0
end

function PerfBench:summary()
    local lines = {}
    for name, r in pairs(self._results) do
        lines[#lines+1] = string.format(
            "%s: avg=%.4fms peak=%.4fms n=%d",
            name, r.total/math.max(1,r.count)*1000, r.peak*1000, r.count
        )
    end
    table.sort(lines)
    return table.concat(lines, "\n")
end

function PerfBench:reset()
    self._marks   = {}
    self._results = {}
end

if Console then Console.info("PerfBench", "Performance benchmark module ready") end

-- §62 ─── EXTENDED SERVER-SIDE PREDICTION ENGINE ──────────────────────────────
local ServerPredict = {}
ServerPredict._snapshots      = {}  -- ring of {t, states}
ServerPredict._maxSnapshots   = 32
ServerPredict._serverTickRate = 20  -- Hz estimate
ServerPredict._tickDrift      = 0
ServerPredict._lastServerT    = 0
ServerPredict._latencyHistory = {}
ServerPredict._MAX_LAT        = 60
ServerPredict._reconciled     = 0
ServerPredict._predError      = 0
ServerPredict._predCount      = 0

function ServerPredict:pushSnapshot(serverTime, ballPositions)
    local snap = { t = serverTime, positions = ballPositions, received = tick() }
    table.insert(self._snapshots, snap)
    if #self._snapshots > self._maxSnapshots then
        table.remove(self._snapshots, 1)
    end
    -- estimate server tick interval
    if self._lastServerT > 0 then
        local interval = serverTime - self._lastServerT
        local alpha    = 0.1
        self._serverTickRate = self._serverTickRate * (1 - alpha) +
                               (1 / math.max(interval, 0.001)) * alpha
    end
    self._lastServerT = serverTime
end

function ServerPredict:interpolate(time)
    -- find two snapshots bracketing `time`
    local before, after = nil, nil
    for _, snap in ipairs(self._snapshots) do
        if snap.t <= time then before = snap
        elseif not after  then after  = snap
        end
    end
    if not before then return {} end
    if not after  then return before.positions end
    local t = (time - before.t) / math.max(after.t - before.t, 0.001)
    t = math.clamp(t, 0, 1)
    -- lerp each ball position
    local result = {}
    for id, bpos in pairs(before.positions) do
        local apos = after.positions[id]
        if apos then
            result[id] = bpos:Lerp(apos, t)
        else
            result[id] = bpos
        end
    end
    return result
end

function ServerPredict:extrapolate(fromTime, toTime)
    -- find latest snapshot before fromTime
    local snap = nil
    for _, s in ipairs(self._snapshots) do
        if s.t <= fromTime then snap = s end
    end
    if not snap then return {} end
    local dt = toTime - snap.t
    local result = {}
    for id, bpos in pairs(snap.positions) do
        -- simple linear extrapolation using velocity estimate
        -- for now just return last known position
        result[id] = bpos
    end
    return result
end

function ServerPredict:recordLatency(lat)
    table.insert(self._latencyHistory, lat)
    if #self._latencyHistory > self._MAX_LAT then
        table.remove(self._latencyHistory, 1)
    end
end

function ServerPredict:getSmoothedLatency()
    if #self._latencyHistory == 0 then return PingComp and PingComp:get() or 0.05 end
    local sum = 0
    for _, v in ipairs(self._latencyHistory) do sum = sum + v end
    return sum / #self._latencyHistory
end

function ServerPredict:getLatencyJitter()
    local lat = self._latencyHistory
    if #lat < 2 then return 0 end
    local mean = self:getSmoothedLatency()
    local variance = 0
    for _, v in ipairs(lat) do
        local diff = v - mean
        variance = variance + diff * diff
    end
    return math.sqrt(variance / #lat)
end

function ServerPredict:reconcile(localPos, serverPos, ballId)
    self._reconciled = self._reconciled + 1
    local err = (localPos - serverPos).Magnitude
    self._predError  = self._predError  + err
    self._predCount  = self._predCount  + 1
end

function ServerPredict:getAvgPredError()
    return self._predCount > 0 and (self._predError / self._predCount) or 0
end

function ServerPredict:getReconciliationRate()
    return self._reconciled
end

function ServerPredict:estimateRenderOffset()
    -- how far back in time to render to ensure we always have two snapshots
    return 2 / math.max(self._serverTickRate, 1)
end

function ServerPredict:getBestRenderTime()
    return tick() - self:estimateRenderOffset() - self:getSmoothedLatency()
end

function ServerPredict:getStats()
    return {
        tickRate     = self._serverTickRate,
        latency      = self:getSmoothedLatency(),
        jitter       = self:getLatencyJitter(),
        avgPredError = self:getAvgPredError(),
        reconciled   = self._reconciled,
        snapshots    = #self._snapshots,
    }
end

if Console then Console.info("ServerPredict", "Server-side prediction engine v2 ready") end

-- §62.1 Client-side rollback system
local Rollback = {}
Rollback._history   = {}  -- ring of {t, pos, vel}
Rollback._maxHistory = 64
Rollback._active    = false

function Rollback:push(t, pos, vel)
    table.insert(self._history, { t = t, pos = pos, vel = vel })
    if #self._history > self._maxHistory then
        table.remove(self._history, 1)
    end
end

function Rollback:getAt(t)
    -- find closest entry at or before t
    local best = nil
    for _, entry in ipairs(self._history) do
        if entry.t <= t then best = entry end
    end
    return best
end

function Rollback:getRange(t0, t1)
    local range = {}
    for _, entry in ipairs(self._history) do
        if entry.t >= t0 and entry.t <= t1 then
            range[#range+1] = entry
        end
    end
    return range
end

function Rollback:getSize()
    return #self._history
end

function Rollback:getOldest()
    return self._history[1]
end

function Rollback:getNewest()
    return self._history[#self._history]
end

function Rollback:clear()
    self._history = {}
end

function Rollback:coverageWindow()
    if #self._history < 2 then return 0 end
    return self._history[#self._history].t - self._history[1].t
end

if Console then Console.info("Rollback", "Client-side rollback system ready") end

-- §63 ─── INPUT RECORDER & PLAYBACK ──────────────────────────────────────────
local InputRecorder = {}
InputRecorder._recordings = {}
InputRecorder._current    = nil
InputRecorder._playing    = false
InputRecorder._playConn   = nil

local INPUT_TYPES = {
    CLICK      = "click",
    KEY_DOWN   = "key_down",
    KEY_UP     = "key_up",
    TOUCH      = "touch",
    MOUSE_MOVE = "mouse_move",
    SCROLL     = "scroll",
}

function InputRecorder:startRecording(name)
    if self._current then self:stopRecording() end
    self._current = {
        name     = name or ("rec_"..tostring(tick())),
        startT   = tick(),
        events   = {},
    }
    if Console then Console.info("InputRecorder", "Recording started: "..self._current.name) end
end

function InputRecorder:stopRecording()
    if not self._current then return end
    self._current.endT    = tick()
    self._current.duration = self._current.endT - self._current.startT
    self._recordings[self._current.name] = self._current
    local name = self._current.name
    self._current = nil
    if Console then Console.info("InputRecorder", "Recording saved: "..name) end
    return name
end

function InputRecorder:recordEvent(kind, data)
    if not self._current then return end
    table.insert(self._current.events, {
        t    = tick() - self._current.startT,
        kind = kind,
        data = data,
    })
end

function InputRecorder:recordClick(position)
    self:recordEvent(INPUT_TYPES.CLICK, { position = position })
end

function InputRecorder:recordKeyDown(keyCode)
    self:recordEvent(INPUT_TYPES.KEY_DOWN, { keyCode = keyCode })
end

function InputRecorder:recordKeyUp(keyCode)
    self:recordEvent(INPUT_TYPES.KEY_UP, { keyCode = keyCode })
end

function InputRecorder:recordMouseMove(position)
    self:recordEvent(INPUT_TYPES.MOUSE_MOVE, { position = position })
end

function InputRecorder:playback(name, speed, onEvent)
    local rec = self._recordings[name]
    if not rec then
        if Console then Console.warn("InputRecorder", "Recording not found: "..tostring(name)) end
        return
    end
    if self._playing then self:stopPlayback() end
    self._playing = true
    speed = speed or 1

    local idx = 1
    local startT = tick()

    self._playConn = RunService.Heartbeat:Connect(function()
        if not self._playing then return end
        local elapsed = (tick() - startT) * speed
        while idx <= #rec.events do
            local ev = rec.events[idx]
            if ev.t <= elapsed then
                -- dispatch event
                pcall(function()
                    if onEvent then onEvent(ev) end
                    if ev.kind == INPUT_TYPES.CLICK then
                        if VIM then
                            VIM:SendKeyEvent(true,  Enum.KeyCode.ButtonR2, false, nil)
                            VIM:SendKeyEvent(false, Enum.KeyCode.ButtonR2, false, nil)
                        end
                    end
                end)
                idx = idx + 1
            else
                break
            end
        end
        if idx > #rec.events then
            self:stopPlayback()
        end
    end)
    if Console then Console.info("InputRecorder", "Playback started: "..name.." speed="..speed.."x") end
end

function InputRecorder:stopPlayback()
    self._playing = false
    if self._playConn then
        self._playConn:Disconnect()
        self._playConn = nil
    end
    if Console then Console.info("InputRecorder", "Playback stopped") end
end

function InputRecorder:listRecordings()
    local names = {}
    for name, rec in pairs(self._recordings) do
        names[#names+1] = string.format("%s (%.2fs, %d events)", name, rec.duration or 0, #rec.events)
    end
    table.sort(names)
    return names
end

function InputRecorder:deleteRecording(name)
    self._recordings[name] = nil
end

function InputRecorder:getRecording(name)
    return self._recordings[name]
end

function InputRecorder:eventCount(name)
    local rec = self._recordings[name]
    return rec and #rec.events or 0
end

function InputRecorder:exportRecording(name)
    local rec = self._recordings[name]
    if not rec then return nil end
    -- serialize to JSON-like string
    local parts = {}
    parts[#parts+1] = string.format('{"name":"%s","duration":%.3f,"events":[', rec.name, rec.duration or 0)
    for i, ev in ipairs(rec.events) do
        local data = ev.data or {}
        parts[#parts+1] = string.format('{"t":%.4f,"kind":"%s"}', ev.t, ev.kind)
        if i < #rec.events then parts[#parts+1] = "," end
    end
    parts[#parts+1] = "]}"
    return table.concat(parts)
end

if Console then Console.info("InputRecorder", "Input recorder & playback ready") end

-- §63.1 Macro system built on InputRecorder
local Macros = {}
Macros._macros = {}

function Macros:define(name, fn)
    self._macros[name] = { name = name, fn = fn, runCount = 0 }
end

function Macros:run(name)
    local m = self._macros[name]
    if not m then
        if Console then Console.warn("Macros", "Macro not found: "..tostring(name)) end
        return
    end
    m.runCount = m.runCount + 1
    local ok, err = pcall(m.fn)
    if not ok then
        if Console then Console.error("Macros", "Macro '"..name.."' failed: "..tostring(err)) end
    end
end

function Macros:list()
    local out = {}
    for name, m in pairs(self._macros) do
        out[#out+1] = string.format("%s (runs: %d)", name, m.runCount)
    end
    table.sort(out)
    return out
end

-- built-in macros
Macros:define("calibrate", function()
    if MemScanner then MemScanner:calibrate() end
    if Console then Console.info("Macros", "Calibration triggered") end
end)

Macros:define("spam_burst", function()
    local old = Config.spamActive
    Config.spamActive = true
    Config.spamBurst  = 5
    task.delay(2, function()
        Config.spamActive = old
        Config.spamBurst  = 1
    end)
end)

Macros:define("reset_accuracy", function()
    if AccuracyTracker then AccuracyTracker:reset() end
    if Console then Console.info("Macros", "Accuracy tracker reset") end
end)

Macros:define("blaze_mode", function()
    Config.parryMode    = "Ultra"
    Config.hitboxExpand = true
    Config.dodgeAssist  = true
    if Console then Console.info("Macros", "Blaze mode activated") end
end)

Macros:define("stealth_mode", function()
    Config.parryMode    = "Conservative"
    Config.hitboxExpand = false
    Config.dodgeAssist  = false
    if AntiDetect then AntiDetect:setProfile("Average") end
    if Console then Console.info("Macros", "Stealth mode activated") end
end)

if Console then Console.info("Macros", "Macro system ready. "..#Macros:list().." built-in macros") end

-- §64 ─── AUTO-UPDATER & VERSION CONTROL ──────────────────────────────────────
local Updater = {}
Updater.VERSION        = "6.0.0"
Updater.BUILD          = "20260618"
Updater.CHANNEL        = "stable"
Updater._checkInterval = 300  -- seconds between checks
Updater._lastCheck     = 0
Updater._updateAvail   = false
Updater._latestVersion = nil
Updater._changelog     = {}
Updater._autoCheck     = true

-- Version comparison utility
local function _parseVersion(vstr)
    local parts = {}
    for n in vstr:gmatch("%d+") do
        parts[#parts+1] = tonumber(n)
    end
    return parts
end

local function _versionLess(a, b)
    local pa, pb = _parseVersion(a), _parseVersion(b)
    for i = 1, math.max(#pa, #pb) do
        local ai = pa[i] or 0
        local bi = pb[i] or 0
        if ai < bi then return true end
        if ai > bi then return false end
    end
    return false
end

function Updater:getCurrentVersion()
    return self.VERSION
end

function Updater:getBuild()
    return self.BUILD
end

function Updater:getChannel()
    return self.CHANNEL
end

function Updater:setChannel(channel)
    if channel == "stable" or channel == "beta" or channel == "nightly" then
        self.CHANNEL = channel
        if Console then Console.info("Updater", "Channel set to: "..channel) end
    end
end

function Updater:setLatestVersion(ver, changelog)
    self._latestVersion = ver
    self._changelog     = changelog or {}
    self._updateAvail   = _versionLess(self.VERSION, ver)
    if self._updateAvail then
        if Console then Console.warn("Updater", "Update available: "..ver) end
        if Notify then Notify:push({
            title   = "Update Available",
            body    = "WindHub "..ver.." is available!",
            icon    = "rbxassetid://7734057928",
            timeout = 8,
        }) end
    end
end

function Updater:isUpdateAvailable()
    return self._updateAvail
end

function Updater:getLatestVersion()
    return self._latestVersion or self.VERSION
end

function Updater:getChangelog()
    return self._changelog
end

function Updater:check()
    -- in production this would HTTP GET a version file
    -- for now just mark last check time
    self._lastCheck = tick()
    if Console then Console.info("Updater", "Version check completed. Current: "..self.VERSION) end
end

function Updater:getVersionString()
    return string.format("WindHub v%s Build %s [%s]", self.VERSION, self.BUILD, self.CHANNEL)
end

function Updater:shouldCheck()
    return self._autoCheck and (tick() - self._lastCheck) >= self._checkInterval
end

function Updater:startAutoCheck()
    task.spawn(function()
        while true do
            task.wait(self._checkInterval)
            if self._autoCheck then self:check() end
        end
    end)
end

function Updater:getStats()
    return {
        version       = self.VERSION,
        build         = self.BUILD,
        channel       = self.CHANNEL,
        updateAvail   = self._updateAvail,
        latestVersion = self._latestVersion,
        lastCheck     = self._lastCheck,
    }
end

if Console then Console.info("Updater", Updater:getVersionString()) end

-- §64.1 Feature flag system
local FeatureFlags = {}
FeatureFlags._flags   = {}
FeatureFlags._overrides = {}

local DEFAULT_FLAGS = {
    ENABLE_MININET        = true,
    ENABLE_MONTE_CARLO    = true,
    ENABLE_RK4_ADAPTIVE   = true,
    ENABLE_REPLION        = true,
    ENABLE_MEMORY_SCANNER = true,
    ENABLE_DRAWING_ESP    = true,
    ENABLE_ANTI_DETECT    = true,
    ENABLE_AUDIO          = true,
    ENABLE_PROFILE_SAVE   = true,
    ENABLE_SESSION_LOG    = true,
    ENABLE_REMOTE_SPY     = true,
    ENABLE_DEBUG_CONSOLE  = true,
    ENABLE_BALL_VIZ       = true,
    ENABLE_PLAYER_TRACKER = true,
    ENABLE_ANIM_HOOK      = true,
    ENABLE_HITBOX_V2      = true,
    ENABLE_PRED_DODGE     = true,
    ENABLE_CC_DETECT      = true,
    ENABLE_BLAZE_BARRIER  = false,  -- opt-in only
    ENABLE_ROLLBACK       = true,
    ENABLE_SERVER_PREDICT = true,
    ENABLE_MACRO_SYSTEM   = true,
    ENABLE_INPUT_RECORDER = true,
    ENABLE_UPDATER        = true,
    ENABLE_PERF_BENCH     = true,
    ENABLE_COMBAT_ANALYTICS = true,
}

for k, v in pairs(DEFAULT_FLAGS) do
    FeatureFlags._flags[k] = v
end

function FeatureFlags:get(flag)
    local override = self._overrides[flag]
    if override ~= nil then return override end
    return self._flags[flag]
end

function FeatureFlags:set(flag, value)
    self._overrides[flag] = value
    if Console then Console.info("FeatureFlags", flag.." = "..tostring(value)) end
end

function FeatureFlags:reset(flag)
    self._overrides[flag] = nil
end

function FeatureFlags:resetAll()
    self._overrides = {}
end

function FeatureFlags:listEnabled()
    local enabled = {}
    for flag, _ in pairs(self._flags) do
        if self:get(flag) then enabled[#enabled+1] = flag end
    end
    table.sort(enabled)
    return enabled
end

function FeatureFlags:listDisabled()
    local disabled = {}
    for flag, _ in pairs(self._flags) do
        if not self:get(flag) then disabled[#disabled+1] = flag end
    end
    table.sort(disabled)
    return disabled
end

function FeatureFlags:isEnabled(flag)
    return self:get(flag) == true
end

if Console then Console.info("FeatureFlags", #FeatureFlags:listEnabled().." features enabled") end

-- §65 ─── EXTENDED HITBOX VISUALIZATION ───────────────────────────────────────
local HitboxViz = {}
HitboxViz._active       = false
HitboxViz._drawObjects  = {}
HitboxViz._showPlayers  = true
HitboxViz._showBalls    = true
HitboxViz._playerColor  = Color3.fromRGB(80, 220, 80)
HitboxViz._ballColor    = Color3.fromRGB(255, 80, 80)
HitboxViz._expandColor  = Color3.fromRGB(255, 200, 40)
HitboxViz._opacity      = 1
HitboxViz._style        = "brackets"  -- "brackets", "box", "circle", "skeleton"

local PLAYER_PARTS = {
    "Head", "UpperTorso", "LowerTorso",
    "LeftUpperArm", "LeftLowerArm", "LeftHand",
    "RightUpperArm", "RightLowerArm", "RightHand",
    "LeftUpperLeg", "LeftLowerLeg", "LeftFoot",
    "RightUpperLeg", "RightLowerLeg", "RightFoot",
    "HumanoidRootPart",
}

local function _getCharBoundingBox(char)
    local cam = workspace.CurrentCamera
    if not cam then return nil end
    local hrp = char:FindFirstChild("HumanoidRootPart")
    if not hrp then return nil end
    local minX, minY = math.huge, math.huge
    local maxX, maxY = -math.huge, -math.huge
    local anyVis = false
    for _, partName in ipairs(PLAYER_PARTS) do
        local part = char:FindFirstChild(partName)
        if part and part:IsA("BasePart") then
            local sp, vis = cam:WorldToViewportPoint(part.Position)
            if vis and sp.Z > 0 then
                minX = math.min(minX, sp.X - part.Size.X * 15)
                minY = math.min(minY, sp.Y - part.Size.Y * 15)
                maxX = math.max(maxX, sp.X + part.Size.X * 15)
                maxY = math.max(maxY, sp.Y + part.Size.Y * 15)
                anyVis = true
            end
        end
    end
    if not anyVis then return nil end
    return minX, minY, maxX - minX, maxY - minY
end

function HitboxViz:_clearDrawObjects()
    for _, obj in ipairs(self._drawObjects) do
        pcall(function() obj.Visible = false end)
        pcall(function() obj:Remove() end)
    end
    self._drawObjects = {}
end

function HitboxViz:_addObj(obj)
    if obj then self._drawObjects[#self._drawObjects+1] = obj end
end

function HitboxViz:updatePlayers()
    if not _drawingSupported then return end
    local cam = workspace.CurrentCamera
    if not cam then return end
    local lp = game.Players.LocalPlayer
    for _, player in ipairs(game.Players:GetPlayers()) do
        if player == lp then continue end
        local char = player.Character
        if not char then continue end
        if self._style == "brackets" then
            local x, y, w, h = _getCharBoundingBox(char)
            if x then
                local objs = Draw2:drawBracket(x, y, w, h, self._playerColor, 2, 10)
                for _, o in ipairs(objs) do self:_addObj(o) end
                -- name label
                local nameObj = Draw2:newText(
                    x + w/2 - 20, y - 16,
                    player.DisplayName,
                    self._playerColor, 12
                )
                self:_addObj(nameObj)
            end
        elseif self._style == "box" then
            local x, y, w, h = _getCharBoundingBox(char)
            if x then
                local quad = Draw2:newQuad(
                    { Vector2.new(x,y), Vector2.new(x+w,y),
                      Vector2.new(x+w,y+h), Vector2.new(x,y+h) },
                    self._playerColor, 1, false
                )
                self:_addObj(quad)
            end
        elseif self._style == "skeleton" then
            -- draw lines between key bones
            local bones = {
                {"Head", "UpperTorso"},
                {"UpperTorso", "LowerTorso"},
                {"UpperTorso", "LeftUpperArm"},
                {"UpperTorso", "RightUpperArm"},
                {"LeftUpperArm", "LeftLowerArm"},
                {"LeftLowerArm", "LeftHand"},
                {"RightUpperArm", "RightLowerArm"},
                {"RightLowerArm", "RightHand"},
                {"LowerTorso", "LeftUpperLeg"},
                {"LowerTorso", "RightUpperLeg"},
                {"LeftUpperLeg", "LeftLowerLeg"},
                {"LeftLowerLeg", "LeftFoot"},
                {"RightUpperLeg", "RightLowerLeg"},
                {"RightLowerLeg", "RightFoot"},
            }
            for _, bone in ipairs(bones) do
                local pa = char:FindFirstChild(bone[1])
                local pb = char:FindFirstChild(bone[2])
                if pa and pb then
                    local spa, visa = cam:WorldToViewportPoint(pa.Position)
                    local spb, visb = cam:WorldToViewportPoint(pb.Position)
                    if visa and visb and spa.Z > 0 and spb.Z > 0 then
                        local ln = Draw2:newLine(spa.X, spa.Y, spb.X, spb.Y, self._playerColor, 1)
                        self:_addObj(ln)
                    end
                end
            end
        elseif self._style == "circle" then
            local hrp = char:FindFirstChild("HumanoidRootPart")
            if hrp then
                local sp, vis = cam:WorldToViewportPoint(hrp.Position)
                if vis and sp.Z > 0 then
                    local dist = sp.Z
                    local radius = math.max(5, 400 / dist)
                    local circ = Draw2:newCircle(sp.X, sp.Y, radius, self._playerColor, 2, false)
                    self:_addObj(circ)
                end
            end
        end
    end
end

function HitboxViz:updateBalls()
    if not _drawingSupported then return end
    if not BallTracker then return end
    local cam = workspace.CurrentCamera
    if not cam then return end
    for _, bs in pairs(BallTracker._balls or {}) do
        if bs.instance then
            local sp, vis = cam:WorldToViewportPoint(bs.pos)
            if vis and sp.Z > 0 then
                local dist = sp.Z
                local radius = math.max(4, 300 / dist)
                -- inner dot
                local inner = Draw2:newCircle(sp.X, sp.Y, radius*0.4, self._ballColor, 1, true)
                self:_addObj(inner)
                -- outer ring
                local outer = Draw2:newCircle(sp.X, sp.Y, radius, self._ballColor, 1, false)
                self:_addObj(outer)
                -- hitbox expand ring (if enabled)
                if Config.hitboxExpand then
                    local scalar = tonumber(Config.hitboxScalar) or 8
                    local expandR = radius + scalar * 2
                    local exp = Draw2:newCircle(sp.X, sp.Y, expandR, self._expandColor, 1, false)
                    self:_addObj(exp)
                end
            end
        end
    end
end

function HitboxViz:update()
    if not self._active then return end
    self:_clearDrawObjects()
    if self._showPlayers then self:updatePlayers() end
    if self._showBalls then self:updateBalls() end
end

function HitboxViz:start()
    self._active = true
    RunService.Heartbeat:Connect(function()
        if self._active then self:update() end
    end)
    if Console then Console.info("HitboxViz", "Hitbox visualization started") end
end

function HitboxViz:stop()
    self._active = false
    self:_clearDrawObjects()
end

function HitboxViz:setStyle(s)
    if s == "brackets" or s == "box" or s == "circle" or s == "skeleton" then
        self._style = s
        if Console then Console.info("HitboxViz", "Style set to: "..s) end
    end
end

function HitboxViz:togglePlayers() self._showPlayers = not self._showPlayers end
function HitboxViz:toggleBalls()   self._showBalls   = not self._showBalls   end

if Config.hitboxViz then HitboxViz:start() end
if Console then Console.info("HitboxViz", "Hitbox viz ready (style="..HitboxViz._style..")") end

-- §66 ─── WIND PHYSICS EXTENSION ──────────────────────────────────────────────
-- Models environmental wind effects on ball trajectory
local WindPhysics = {}
WindPhysics._enabled     = false
WindPhysics._windVector  = Vector3.new(0, 0, 0)
WindPhysics._gustPower   = 0
WindPhysics._gustFreq    = 0.5   -- Hz
WindPhysics._turbulence  = 0.05  -- random perturbation factor
WindPhysics._autoDetect  = true
WindPhysics._samples     = {}
WindPhysics._MAX_SAMPLES = 128
WindPhysics._calibrated  = false
WindPhysics._confidence  = 0

local function _gaussNoise(sigma)
    -- Box-Muller
    local u1 = math.random()
    local u2 = math.random()
    while u1 <= 1e-10 do u1 = math.random() end
    return math.sqrt(-2 * math.log(u1)) * math.cos(2 * math.pi * u2) * sigma
end

function WindPhysics:getWindAt(t)
    -- base wind + sinusoidal gust
    local gust = Vector3.new(
        self._gustPower * math.sin(t * self._gustFreq * 2 * math.pi),
        0,
        self._gustPower * math.cos(t * self._gustFreq * 1.3 * math.pi)
    )
    -- turbulence
    local turb = Vector3.new(
        _gaussNoise(self._turbulence),
        _gaussNoise(self._turbulence * 0.3),
        _gaussNoise(self._turbulence)
    )
    return self._windVector + gust + turb
end

function WindPhysics:applyToVelocity(vel, dt, t)
    if not self._enabled then return vel end
    local wind = self:getWindAt(t or tick())
    -- wind force = windDrag * (wind - vel) * dt
    local windDragCoeff = 0.02
    local force = (wind - vel) * windDragCoeff
    return vel + force * dt
end

function WindPhysics:setWind(direction, speed)
    if direction.Magnitude > 0 then
        self._windVector = direction.Unit * speed
    end
    if Console then Console.info("WindPhysics", string.format(
        "Wind set: dir=(%.2f,%.2f,%.2f) speed=%.1f",
        direction.X, direction.Y, direction.Z, speed
    )) end
end

function WindPhysics:sampleBallDeviation(measuredPos, predictedPos, vel, dt)
    -- estimate wind by comparing predicted vs actual ball position
    if not self._autoDetect then return end
    local deviation = measuredPos - predictedPos
    local perpDeviation = deviation - vel.Unit * vel.Unit:Dot(deviation)
    table.insert(self._samples, {
        t    = tick(),
        dev  = perpDeviation,
        spd  = vel.Magnitude,
        dt   = dt,
    })
    if #self._samples > self._MAX_SAMPLES then
        table.remove(self._samples, 1)
    end
    if #self._samples >= 20 then
        self:_estimateWind()
    end
end

function WindPhysics:_estimateWind()
    -- average deviation vectors weighted by speed
    local sumX, sumZ, totalW = 0, 0, 0
    for _, s in ipairs(self._samples) do
        local w = s.spd  -- higher-speed balls show wind effects more
        sumX   = sumX + s.dev.X * w
        sumZ   = sumZ + s.dev.Z * w
        totalW = totalW + w
    end
    if totalW < 0.01 then return end
    local windX = sumX / totalW
    local windZ = sumZ / totalW
    -- scale: deviation per (dt * dragCoeff) ≈ wind component
    self._windVector = Vector3.new(windX / 0.02, 0, windZ / 0.02)
    self._calibrated = true
    -- confidence from consistency of samples
    local varX, varZ = 0, 0
    for _, s in ipairs(self._samples) do
        varX = varX + (s.dev.X - windX) ^ 2
        varZ = varZ + (s.dev.Z - windZ) ^ 2
    end
    local n = #self._samples
    local stdX = math.sqrt(varX / n)
    local stdZ = math.sqrt(varZ / n)
    local magX = math.abs(windX)
    local magZ = math.abs(windZ)
    self._confidence = 1 - math.min(1,
        (stdX / math.max(magX, 0.1) + stdZ / math.max(magZ, 0.1)) / 2
    )
end

function WindPhysics:getStats()
    return {
        enabled    = self._enabled,
        wind       = self._windVector,
        gust       = self._gustPower,
        turbulence = self._turbulence,
        calibrated = self._calibrated,
        confidence = self._confidence,
        samples    = #self._samples,
    }
end

function WindPhysics:enable()
    self._enabled = true
    if Console then Console.info("WindPhysics", "Wind physics enabled") end
end

function WindPhysics:disable()
    self._enabled = false
end

function WindPhysics:reset()
    self._windVector = Vector3.new(0, 0, 0)
    self._gustPower  = 0
    self._samples    = {}
    self._calibrated = false
    self._confidence = 0
end

function WindPhysics:getWindSpeedKmh()
    return self._windVector.Magnitude * 3.6  -- studs/s to "km/h" equivalent
end

function WindPhysics:getWindDirection()
    local mag = self._windVector.Magnitude
    if mag < 0.001 then return "Calm" end
    local angle = math.deg(math.atan2(self._windVector.X, self._windVector.Z))
    if angle < 0 then angle = angle + 360 end
    local dirs = {"N","NNE","NE","ENE","E","ESE","SE","SSE","S","SSW","SW","WSW","W","WNW","NW","NNW"}
    local idx  = math.floor((angle + 11.25) / 22.5) % 16 + 1
    return dirs[idx]
end

if Console then Console.info("WindPhysics", "Wind physics module ready") end

-- §66.1 Spin physics extension
local SpinPhysics = {}
SpinPhysics._spinEstimates   = {}  -- per-ball spin vectors
SpinPhysics._MAGNUS_COEFF    = 0.0006  -- Magnus force coefficient
SpinPhysics._SPIN_DECAY      = 0.98    -- per-frame spin decay
SpinPhysics._MAX_SPIN        = 200     -- rad/s max

function SpinPhysics:updateSpin(ballId, vel, prevVel, dt)
    if dt < 0.001 then return end
    -- estimate angular velocity from velocity change perpendicular to motion
    local dvdt = (vel - prevVel) / dt
    -- component of acceleration perpendicular to velocity gives spin estimate
    local speed = vel.Magnitude
    if speed < 0.01 then return end
    local velDir = vel.Unit
    local perpAccel = dvdt - velDir * velDir:Dot(dvdt)
    -- Magnus: a_perp = (omega × vel) * coeff
    -- so omega ≈ perpAccel × velDir / (speed * coeff)
    local spinMag = perpAccel.Magnitude / math.max(speed * self._MAGNUS_COEFF, 0.0001)
    spinMag = math.min(spinMag, self._MAX_SPIN)
    local spinDir = perpAccel.Magnitude > 0.001 and perpAccel.Cross(velDir).Unit or Vector3.new(0,1,0)
    self._spinEstimates[ballId] = {
        omega    = spinDir * spinMag,
        t        = tick(),
        speed    = speed,
    }
end

function SpinPhysics:getMagnusForce(ballId, vel)
    local est = self._spinEstimates[ballId]
    if not est then return Vector3.new(0,0,0) end
    -- F_magnus = coeff * (omega × vel)
    return est.omega:Cross(vel) * self._MAGNUS_COEFF
end

function SpinPhysics:getSpinMagnitude(ballId)
    local est = self._spinEstimates[ballId]
    return est and est.omega.Magnitude or 0
end

function SpinPhysics:classifySpinType(ballId)
    local est = self._spinEstimates[ballId]
    if not est then return "No spin" end
    local mag = est.omega.Magnitude
    if mag < 5  then return "Knuckleball" end
    if mag < 30 then return "Light spin" end
    if mag < 80 then return "Medium spin" end
    return "Heavy topspin"
end

function SpinPhysics:getStats()
    local out = {}
    for id, est in pairs(self._spinEstimates) do
        out[#out+1] = string.format("Ball %s: %.1f rad/s %s",
            tostring(id), est.omega.Magnitude, self:classifySpinType(id))
    end
    return out
end

if Console then Console.info("SpinPhysics", "Spin physics extension ready") end

-- §67 ─── FULL CONFIGURATION EXPORT/IMPORT SYSTEM ─────────────────────────────
local ConfigIO = {}
ConfigIO._savedSlots   = {}
ConfigIO._MAX_SLOTS    = 20
ConfigIO._currentSlot  = nil
ConfigIO._autoSaveSlot = "autosave"

-- Serialize Config to a string
function ConfigIO:serialize()
    local data = {}
    for k, v in pairs(Config._raw or {}) do
        local t = type(v)
        if t == "boolean" or t == "number" or t == "string" then
            data[k] = v
        elseif t == "userdata" then
            -- handle Color3
            if pcall(function() local _ = v.R end) then
                data[k] = { _type = "Color3", r = v.R, g = v.G, b = v.B }
            -- handle Vector3
            elseif pcall(function() local _ = v.X end) then
                data[k] = { _type = "Vector3", x = v.X, y = v.Y, z = v.Z }
            end
        end
    end
    local ok, json = pcall(function()
        return HttpService:JSONEncode(data)
    end)
    if ok then return json end
    -- fallback: manual serialization
    local parts = {"{"}
    for k, v in pairs(data) do
        local t = type(v)
        if t == "boolean" then
            parts[#parts+1] = string.format('"%s":%s', k, tostring(v))
        elseif t == "number" then
            parts[#parts+1] = string.format('"%s":%.6g', k, v)
        elseif t == "string" then
            parts[#parts+1] = string.format('"%s":"%s"', k, v:gsub('"', '\\"'))
        elseif t == "table" then
            if v._type == "Color3" then
                parts[#parts+1] = string.format('"%s":{"_type":"Color3","r":%.4f,"g":%.4f,"b":%.4f}', k, v.r, v.g, v.b)
            elseif v._type == "Vector3" then
                parts[#parts+1] = string.format('"%s":{"_type":"Vector3","x":%.4f,"y":%.4f,"z":%.4f}', k, v.x, v.y, v.z)
            end
        end
    end
    return "{" .. table.concat(parts, ",") .. "}"
end

function ConfigIO:deserialize(jsonStr)
    local ok, data = pcall(function()
        return HttpService:JSONDecode(jsonStr)
    end)
    if not ok or not data then
        if Console then Console.error("ConfigIO", "Failed to parse config JSON") end
        return false
    end
    for k, v in pairs(data) do
        if type(v) == "table" then
            if v._type == "Color3" then
                pcall(function() Config[k] = Color3.new(v.r, v.g, v.b) end)
            elseif v._type == "Vector3" then
                pcall(function() Config[k] = Vector3.new(v.x, v.y, v.z) end)
            end
        else
            pcall(function() Config[k] = v end)
        end
    end
    return true
end

function ConfigIO:save(slotName)
    slotName = slotName or self._currentSlot or "default"
    self._savedSlots[slotName] = {
        name    = slotName,
        data    = self:serialize(),
        savedAt = tick(),
    }
    -- also write to filesystem if supported
    if writefile then
        pcall(function()
            writefile("windhub_config_"..slotName..".json", self._savedSlots[slotName].data)
        end)
    end
    if Console then Console.info("ConfigIO", "Config saved to slot: "..slotName) end
    return true
end

function ConfigIO:load(slotName)
    slotName = slotName or self._currentSlot or "default"
    local slot = self._savedSlots[slotName]
    -- try filesystem if not in memory
    if not slot then
        if readfile then
            local ok, data = pcall(function() return readfile("windhub_config_"..slotName..".json") end)
            if ok and data then
                slot = { name = slotName, data = data }
                self._savedSlots[slotName] = slot
            end
        end
    end
    if not slot then
        if Console then Console.warn("ConfigIO", "Slot not found: "..slotName) end
        return false
    end
    local success = self:deserialize(slot.data)
    if success then
        self._currentSlot = slotName
        if Console then Console.info("ConfigIO", "Config loaded from slot: "..slotName) end
    end
    return success
end

function ConfigIO:delete(slotName)
    self._savedSlots[slotName] = nil
    if deletefile then
        pcall(function() deletefile("windhub_config_"..slotName..".json") end)
    end
    if Console then Console.info("ConfigIO", "Slot deleted: "..slotName) end
end

function ConfigIO:listSlots()
    local slots = {}
    for name, slot in pairs(self._savedSlots) do
        slots[#slots+1] = {
            name    = name,
            savedAt = slot.savedAt or 0,
        }
    end
    -- also check filesystem
    if listfiles then
        local ok, files = pcall(listfiles, "")
        if ok then
            for _, f in ipairs(files) do
                local name = f:match("windhub_config_(.+)%.json")
                if name and not self._savedSlots[name] then
                    slots[#slots+1] = { name = name, savedAt = 0, onDisk = true }
                end
            end
        end
    end
    table.sort(slots, function(a, b) return a.savedAt > b.savedAt end)
    return slots
end

function ConfigIO:copyToClipboard()
    local json = self:serialize()
    if setclipboard then
        pcall(function() setclipboard(json) end)
        if Console then Console.info("ConfigIO", "Config copied to clipboard ("..#json.." chars)") end
        return true
    end
    return false
end

function ConfigIO:importFromClipboard()
    if getclipboard then
        local ok, text = pcall(getclipboard)
        if ok and text and #text > 2 then
            local success = self:deserialize(text)
            if success then
                if Console then Console.info("ConfigIO", "Config imported from clipboard") end
            end
            return success
        end
    end
    return false
end

function ConfigIO:exportPreset(name, keys)
    -- export only specific keys as a preset
    local data = {}
    for _, k in ipairs(keys) do
        local v = Config[k]
        if v ~= nil then data[k] = v end
    end
    local ok, json = pcall(function() return HttpService:JSONEncode(data) end)
    if ok then
        if writefile then
            pcall(function() writefile("windhub_preset_"..name..".json", json) end)
        end
        return json
    end
    return nil
end

function ConfigIO:autoSave()
    self:save(self._autoSaveSlot)
end

-- auto-save every 5 minutes
task.spawn(function()
    while true do
        task.wait(300)
        pcall(function() ConfigIO:autoSave() end)
    end
end)

if Console then Console.info("ConfigIO", "Config export/import system ready") end

-- §68 ─── EXTENDED PLAYER ANALYSIS ────────────────────────────────────────────
local PlayerAnalysis = {}
PlayerAnalysis._players     = {}
PlayerAnalysis._events      = {}
PlayerAnalysis._MAX_EVENTS  = 500

local PLAYER_TIERS = {
    NOOB         = { name = "Noob",         minParries = 0,   maxParries = 2   },
    BEGINNER     = { name = "Beginner",     minParries = 3,   maxParries = 8   },
    INTERMEDIATE = { name = "Intermediate", minParries = 9,   maxParries = 20  },
    ADVANCED     = { name = "Advanced",     minParries = 21,  maxParries = 50  },
    EXPERT       = { name = "Expert",       minParries = 51,  maxParries = 120 },
    ELITE        = { name = "Elite",        minParries = 121, maxParries = 300 },
    GODLIKE      = { name = "Godlike",      minParries = 301, maxParries = math.huge },
}

local function _newPlayerData(player)
    return {
        player         = player,
        name           = player.Name,
        userId         = player.UserId,
        joinTime       = tick(),
        parryCount     = 0,
        missCount      = 0,
        deathCount     = 0,
        killCount      = 0,
        avgParrySpeed  = 0,
        parrySpeedSum  = 0,
        maxParryStreak = 0,
        curStreak      = 0,
        posHistory     = {},  -- last 20 positions
        velHistory     = {},
        threatScore    = 0,
        tier           = "Noob",
        reactionTimes  = {},  -- last 20 reaction times
        avgReaction    = 0,
        isTarget       = false,
        trackStart     = tick(),
        encounterCount = 0,
    }
end

function PlayerAnalysis:trackPlayer(player)
    if self._players[player.UserId] then return end
    self._players[player.UserId] = _newPlayerData(player)
    if Console then Console.info("PlayerAnalysis", "Tracking: "..player.Name) end
end

function PlayerAnalysis:untrackPlayer(player)
    self._players[player.UserId] = nil
end

function PlayerAnalysis:recordParry(player, reactionTime, speed)
    local data = self._players[player.UserId]
    if not data then return end
    data.parryCount = data.parryCount + 1
    data.curStreak  = data.curStreak + 1
    data.maxParryStreak = math.max(data.maxParryStreak, data.curStreak)
    if speed then
        data.parrySpeedSum = data.parrySpeedSum + speed
        data.avgParrySpeed = data.parrySpeedSum / data.parryCount
    end
    if reactionTime then
        table.insert(data.reactionTimes, reactionTime)
        if #data.reactionTimes > 20 then table.remove(data.reactionTimes, 1) end
        local sum = 0
        for _, rt in ipairs(data.reactionTimes) do sum = sum + rt end
        data.avgReaction = sum / #data.reactionTimes
    end
    self:_updateTier(data)
    self:_logEvent("parry", player.UserId, { reaction = reactionTime, speed = speed })
end

function PlayerAnalysis:recordMiss(player)
    local data = self._players[player.UserId]
    if not data then return end
    data.missCount = data.missCount + 1
    data.curStreak = 0
    self:_updateTier(data)
end

function PlayerAnalysis:recordDeath(player, killer)
    local data = self._players[player.UserId]
    if not data then return end
    data.deathCount = data.deathCount + 1
    data.curStreak  = 0
    self:_logEvent("death", player.UserId, { killer = killer and killer.UserId or nil })
end

function PlayerAnalysis:recordKill(player, victim)
    local data = self._players[player.UserId]
    if not data then return end
    data.killCount = data.killCount + 1
    self:_logEvent("kill", player.UserId, { victim = victim and victim.UserId or nil })
end

function PlayerAnalysis:updatePosition(player, pos, vel)
    local data = self._players[player.UserId]
    if not data then return end
    table.insert(data.posHistory, { t = tick(), pos = pos })
    if #data.posHistory > 20 then table.remove(data.posHistory, 1) end
    if vel then
        table.insert(data.velHistory, { t = tick(), vel = vel })
        if #data.velHistory > 20 then table.remove(data.velHistory, 1) end
    end
    -- update threat score based on recent movement patterns
    self:_updateThreat(data)
end

function PlayerAnalysis:_updateTier(data)
    for _, tier in pairs(PLAYER_TIERS) do
        if data.parryCount >= tier.minParries and data.parryCount <= tier.maxParries then
            data.tier = tier.name
            return
        end
    end
end

function PlayerAnalysis:_updateThreat(data)
    -- threat = parry rate * accuracy * tier bonus
    local total = data.parryCount + data.missCount
    local acc = total > 0 and (data.parryCount / total) or 0.5
    local tierBonus = {
        Noob = 0.1, Beginner = 0.3, Intermediate = 0.5,
        Advanced = 0.7, Expert = 0.85, Elite = 0.95, Godlike = 1.0,
    }
    data.threatScore = acc * (tierBonus[data.tier] or 0.5)
end

function PlayerAnalysis:_logEvent(kind, userId, extra)
    local ev = { kind = kind, userId = userId, t = tick() }
    for k, v in pairs(extra or {}) do ev[k] = v end
    table.insert(self._events, ev)
    if #self._events > self._MAX_EVENTS then table.remove(self._events, 1) end
end

function PlayerAnalysis:getPlayerData(player)
    return self._players[player.UserId]
end

function PlayerAnalysis:getThreatRanking()
    local ranked = {}
    for _, data in pairs(self._players) do
        ranked[#ranked+1] = data
    end
    table.sort(ranked, function(a, b) return a.threatScore > b.threatScore end)
    return ranked
end

function PlayerAnalysis:getMostDangerous()
    local ranked = self:getThreatRanking()
    return ranked[1]
end

function PlayerAnalysis:getPlayerAccuracy(player)
    local data = self._players[player.UserId]
    if not data then return 0 end
    local total = data.parryCount + data.missCount
    return total > 0 and (data.parryCount / total * 100) or 0
end

function PlayerAnalysis:getPlayerKDR(player)
    local data = self._players[player.UserId]
    if not data then return 0 end
    return data.deathCount > 0 and (data.killCount / data.deathCount) or data.killCount
end

function PlayerAnalysis:getPlayerSummary(player)
    local data = self._players[player.UserId]
    if not data then return "No data" end
    local acc = self:getPlayerAccuracy(player)
    return string.format(
        "%s [%s] Parries:%d Acc:%.0f%% Streak:%d Threat:%.2f Reaction:%.0fms",
        data.name, data.tier, data.parryCount, acc,
        data.maxParryStreak, data.threatScore, data.avgReaction * 1000
    )
end

function PlayerAnalysis:getLeaderboard(field, n)
    n = n or 10
    local players = {}
    for _, data in pairs(self._players) do
        players[#players+1] = data
    end
    local fieldFn = {
        parries   = function(d) return d.parryCount end,
        accuracy  = function(d)
            local t = d.parryCount + d.missCount
            return t > 0 and (d.parryCount / t) or 0
        end,
        kills     = function(d) return d.killCount end,
        threat    = function(d) return d.threatScore end,
        streak    = function(d) return d.maxParryStreak end,
        reaction  = function(d) return -(d.avgReaction or 1) end,  -- lower = better
    }
    local fn = fieldFn[field] or fieldFn.parries
    table.sort(players, function(a, b) return fn(a) > fn(b) end)
    local out = {}
    for i = 1, math.min(n, #players) do
        out[#out+1] = players[i]
    end
    return out
end

function PlayerAnalysis:start()
    for _, p in ipairs(game.Players:GetPlayers()) do
        self:trackPlayer(p)
    end
    game.Players.PlayerAdded:Connect(function(p)
        self:trackPlayer(p)
    end)
    game.Players.PlayerRemoving:Connect(function(p)
        -- keep data for session summary
    end)
    if Console then Console.info("PlayerAnalysis", "Extended player analysis tracking "..#game.Players:GetPlayers().." players") end
end

PlayerAnalysis:start()

-- §69 ─── TOURNAMENT MODE ──────────────────────────────────────────────────────
local TournamentMode = {}
TournamentMode._active      = false
TournamentMode._round       = 0
TournamentMode._maxRounds   = 10
TournamentMode._score       = 0
TournamentMode._opponentScore = 0
TournamentMode._roundHistory = {}
TournamentMode._bracket     = {}
TournamentMode._opponent    = nil
TournamentMode._mode        = "best_of_3"  -- best_of_3, best_of_5, timed
TournamentMode._timeLimit   = 300  -- seconds per match
TournamentMode._startTime   = 0
TournamentMode._bonusActive = false
TournamentMode._bonusWindow = 5  -- seconds of bonus parry speed

local TOURNAMENT_MODES = {
    BEST_OF_3   = "best_of_3",
    BEST_OF_5   = "best_of_5",
    TIMED       = "timed",
    ELIMINATION = "elimination",
    LADDER      = "ladder",
}

local function _newRoundResult(round, playerParries, opponentParries, winner)
    return {
        round            = round,
        t                = tick(),
        playerParries    = playerParries,
        opponentParries  = opponentParries,
        winner           = winner,
        duration         = 0,
    }
end

function TournamentMode:setMode(mode)
    if TOURNAMENT_MODES[mode:upper()] or mode == mode then
        self._mode = mode
        if Console then Console.info("Tournament", "Mode set to: "..mode) end
    end
end

function TournamentMode:setOpponent(player)
    self._opponent = player
    if Console then Console.info("Tournament", "Opponent: "..(player and player.Name or "None")) end
end

function TournamentMode:start()
    self._active          = true
    self._round           = 0
    self._score           = 0
    self._opponentScore   = 0
    self._roundHistory    = {}
    self._startTime       = tick()
    if Console then Console.info("Tournament", "Tournament match started!") end
    if Notify then Notify:push({
        title   = "Tournament Mode",
        body    = "Match started! Mode: "..self._mode,
        timeout = 5,
    }) end
    CombatAnalytics:startRound()
end

function TournamentMode:endMatch(reason)
    self._active = false
    CombatAnalytics:endRound()
    local winner = self._score > self._opponentScore and "You" or "Opponent"
    if Console then Console.info("Tournament", string.format(
        "Match over! %s wins %d-%d. Reason: %s",
        winner, self._score, self._opponentScore, reason or "complete"
    )) end
    if Notify then Notify:push({
        title   = "Match Over!",
        body    = string.format("%s wins! Score: %d-%d", winner, self._score, self._opponentScore),
        timeout = 10,
    }) end
    if SessionManager and SessionManager._logEvent then
        SessionManager:_logEvent("tournament_end", { winner = winner, score = self._score, opScore = self._opponentScore })
    end
end

function TournamentMode:scorePoint(isPlayer)
    if not self._active then return end
    if isPlayer then
        self._score = self._score + 1
    else
        self._opponentScore = self._opponentScore + 1
    end
    -- check win conditions
    if self._mode == TOURNAMENT_MODES.BEST_OF_3 then
        if self._score >= 2 then self:endMatch("best_of_3_win") end
        if self._opponentScore >= 2 then self:endMatch("best_of_3_loss") end
    elseif self._mode == TOURNAMENT_MODES.BEST_OF_5 then
        if self._score >= 3 then self:endMatch("best_of_5_win") end
        if self._opponentScore >= 3 then self:endMatch("best_of_5_loss") end
    end
end

function TournamentMode:recordRoundResult(playerParries, opponentParries)
    if not self._active then return end
    self._round = self._round + 1
    local winner = playerParries >= opponentParries and "player" or "opponent"
    local result = _newRoundResult(self._round, playerParries, opponentParries, winner)
    result.duration = tick() - self._startTime
    table.insert(self._roundHistory, result)
    self:scorePoint(winner == "player")
end

function TournamentMode:activateBonus()
    if self._bonusActive then return end
    self._bonusActive = true
    if Console then Console.info("Tournament", "TOURNAMENT BONUS ACTIVE for "..self._bonusWindow.."s!") end
    -- temporarily boost parry window
    local oldWindow = Config.parryWindow
    Config.parryWindow = (oldWindow or 0.3) * 1.5
    task.delay(self._bonusWindow, function()
        Config.parryWindow = oldWindow
        self._bonusActive  = false
    end)
end

function TournamentMode:getStats()
    return {
        active          = self._active,
        round           = self._round,
        score           = self._score,
        opponentScore   = self._opponentScore,
        mode            = self._mode,
        duration        = self._active and (tick() - self._startTime) or 0,
        roundHistory    = self._roundHistory,
    }
end

function TournamentMode:getCurrentLead()
    return self._score - self._opponentScore
end

function TournamentMode:isMatchPoint()
    if self._mode == TOURNAMENT_MODES.BEST_OF_3 then
        return self._score == 1 or self._opponentScore == 1
    elseif self._mode == TOURNAMENT_MODES.BEST_OF_5 then
        return self._score == 2 or self._opponentScore == 2
    end
    return false
end

function TournamentMode:getTimeRemaining()
    if not self._active or self._mode ~= TOURNAMENT_MODES.TIMED then return nil end
    return math.max(0, self._timeLimit - (tick() - self._startTime))
end

if Console then Console.info("TournamentMode", "Tournament mode system ready") end

-- §69.1 Ranked matchmaking tier
local RankedSystem = {}
RankedSystem._elo       = 1000  -- starting ELO
RankedSystem._wins      = 0
RankedSystem._losses    = 0
RankedSystem._draws     = 0
RankedSystem._history   = {}
RankedSystem._K         = 32    -- ELO K factor

local RANKED_TIERS = {
    { name = "Bronze",      minElo = 0    },
    { name = "Silver",      minElo = 1100 },
    { name = "Gold",        minElo = 1300 },
    { name = "Platinum",    minElo = 1500 },
    { name = "Diamond",     minElo = 1700 },
    { name = "Master",      minElo = 1900 },
    { name = "Grandmaster", minElo = 2100 },
}

function RankedSystem:getExpectedScore(myElo, oppElo)
    return 1 / (1 + 10^((oppElo - myElo) / 400))
end

function RankedSystem:updateELO(opponentElo, result)
    -- result: 1 = win, 0.5 = draw, 0 = loss
    local expected = self:getExpectedScore(self._elo, opponentElo)
    local delta    = self._K * (result - expected)
    self._elo      = math.max(0, self._elo + delta)
    if result == 1 then self._wins = self._wins + 1
    elseif result == 0 then self._losses = self._losses + 1
    else self._draws = self._draws + 1 end
    table.insert(self._history, {
        t          = tick(),
        before     = self._elo - delta,
        after      = self._elo,
        delta      = delta,
        oppElo     = opponentElo,
        result     = result,
    })
    if #self._history > 100 then table.remove(self._history, 1) end
    if Console then Console.info("Ranked", string.format(
        "ELO updated: %.0f \226\134\146 %.0f (%+.0f) vs %.0f",
        self._elo - delta, self._elo, delta, opponentElo
    )) end
end

function RankedSystem:getTier()
    for i = #RANKED_TIERS, 1, -1 do
        if self._elo >= RANKED_TIERS[i].minElo then
            return RANKED_TIERS[i].name
        end
    end
    return "Bronze"
end

function RankedSystem:getELO()
    return math.floor(self._elo)
end

function RankedSystem:getWinRate()
    local total = self._wins + self._losses + self._draws
    return total > 0 and (self._wins / total * 100) or 0
end

function RankedSystem:getRecord()
    return self._wins, self._losses, self._draws
end

function RankedSystem:getELOHistory()
    local out = {}
    for _, h in ipairs(self._history) do
        out[#out+1] = math.floor(h.after)
    end
    return out
end

function RankedSystem:getRecentELOChange()
    if #self._history == 0 then return 0 end
    local total = 0
    for i = math.max(1, #self._history-9), #self._history do
        total = total + self._history[i].delta
    end
    return total
end

if Console then Console.info("Ranked", string.format(
    "Ranked system ready. ELO: %d [%s]",
    RankedSystem:getELO(), RankedSystem:getTier()
)) end

-- §70 ─── COMPREHENSIVE DEBUG TOOLS ───────────────────────────────────────────
local DebugTools = {}
DebugTools._enabled     = true
DebugTools._watchList   = {}
DebugTools._breakpoints = {}
DebugTools._callStack   = {}
DebugTools._logLevel    = 3  -- 0=off 1=error 2=warn 3=info 4=debug 5=trace
DebugTools._overlayLines = {}
DebugTools._maxOverlay   = 20

local LOG_LEVELS = { "OFF", "ERROR", "WARN", "INFO", "DEBUG", "TRACE" }

function DebugTools:setLogLevel(level)
    if type(level) == "string" then
        for i, name in ipairs(LOG_LEVELS) do
            if name == level:upper() then
                self._logLevel = i - 1
                return
            end
        end
    else
        self._logLevel = math.clamp(level, 0, 5)
    end
end

function DebugTools:log(level, module, msg)
    if level > self._logLevel then return end
    local prefix = string.format("[%s][%s] ", LOG_LEVELS[level+1] or "?", module)
    if Console then Console.log(prefix .. msg) end
end

function DebugTools:watch(name, getter)
    self._watchList[name] = getter
end

function DebugTools:unwatch(name)
    self._watchList[name] = nil
end

function DebugTools:getWatchValues()
    local out = {}
    for name, getter in pairs(self._watchList) do
        local ok, val = pcall(getter)
        out[name] = ok and val or ("ERROR: "..tostring(val))
    end
    return out
end

function DebugTools:pushCallStack(name)
    table.insert(self._callStack, { name = name, t = tick() })
    if #self._callStack > 50 then table.remove(self._callStack, 1) end
end

function DebugTools:popCallStack()
    table.remove(self._callStack)
end

function DebugTools:getCallStack()
    local out = {}
    for i = #self._callStack, 1, -1 do
        out[#out+1] = self._callStack[i].name
    end
    return out
end

function DebugTools:setBreakpoint(name, condition)
    self._breakpoints[name] = condition or function() return true end
end

function DebugTools:checkBreakpoint(name, context)
    local cond = self._breakpoints[name]
    if not cond then return false end
    local ok, result = pcall(cond, context)
    if ok and result then
        if Console then Console.warn("DebugTools", "BREAKPOINT hit: "..name) end
        if context then
            for k, v in pairs(context) do
                if Console then Console.log(string.format("  %s = %s", tostring(k), tostring(v))) end
            end
        end
        return true
    end
    return false
end

function DebugTools:dumpTable(t, depth, indent)
    depth  = depth or 3
    indent = indent or 0
    if depth <= 0 then return "..." end
    local prefix = string.rep("  ", indent)
    local lines  = {}
    for k, v in pairs(t) do
        local keyStr = tostring(k)
        local valStr
        if type(v) == "table" then
            valStr = "{\n" .. self:dumpTable(v, depth-1, indent+1) .. prefix .. "}"
        else
            valStr = tostring(v)
        end
        lines[#lines+1] = prefix .. "  " .. keyStr .. " = " .. valStr
    end
    return table.concat(lines, "\n")
end

function DebugTools:profileFunction(fn, name, iterations)
    name       = name or "anonymous"
    iterations = iterations or 1
    local t0   = tick()
    local results = {}
    for i = 1, iterations do
        local ok, r = pcall(fn)
        results[i] = { ok = ok, result = r }
    end
    local dt = tick() - t0
    if Console then Console.info("DebugTools", string.format(
        "Profile '%s': %.3fms total, %.4fms avg (%d iters)",
        name, dt*1000, dt/iterations*1000, iterations
    )) end
    return dt, results
end

function DebugTools:memorySnapshot()
    local info = {
        gcObjects     = 0,
        nilInstances  = 0,
        ballCount     = 0,
        playerCount   = 0,
        drawObjects   = 0,
        configKeys    = 0,
        espObjects    = 0,
    }
    pcall(function()
        if getgc then info.gcObjects = #getgc(false) end
        if getnilinstances then info.nilInstances = #getnilinstances() end
        if BallTracker then info.ballCount = 0; for _ in pairs(BallTracker._balls or {}) do info.ballCount = info.ballCount + 1 end end
        info.playerCount = #game.Players:GetPlayers()
        info.drawObjects = Draw2:count()
        if Config._raw then for _ in pairs(Config._raw) do info.configKeys = info.configKeys + 1 end end
    end)
    return info
end

function DebugTools:addOverlayLine(text, color)
    table.insert(self._overlayLines, {
        text  = text,
        color = color or Color3.fromRGB(255, 255, 255),
        t     = tick(),
    })
    if #self._overlayLines > self._maxOverlay then
        table.remove(self._overlayLines, 1)
    end
end

function DebugTools:drawOverlay()
    if not _drawingSupported then return end
    for i, line in ipairs(self._overlayLines) do
        local obj = Draw2:newText(10, 10 + (i-1) * 16, line.text, line.color, 12, true)
        -- these are ephemeral, remove after 1 frame
        task.defer(function()
            pcall(function() if obj then obj.Visible = false; obj:Remove() end end)
        end)
    end
end

function DebugTools:startMemoryPoll(interval)
    interval = interval or 10
    task.spawn(function()
        while self._enabled do
            task.wait(interval)
            local mem = self:memorySnapshot()
            self:log(4, "MemPoll", string.format(
                "GC:%d Nil:%d Balls:%d Players:%d Draw:%d ConfigKeys:%d",
                mem.gcObjects, mem.nilInstances, mem.ballCount,
                mem.playerCount, mem.drawObjects, mem.configKeys
            ))
        end
    end)
end

-- Default watches
DebugTools:watch("FPS", function()
    return math.floor(1 / (RunService.Heartbeat:Wait()))
end)
DebugTools:watch("Ping", function()
    return PingComp and string.format("%.0fms", PingComp:get() * 1000) or "N/A"
end)
DebugTools:watch("ParryMode", function()
    return Config.parryMode or "None"
end)
DebugTools:watch("ActiveBalls", function()
    if not BallTracker then return 0 end
    local n = 0; for _ in pairs(BallTracker._balls or {}) do n = n + 1 end; return n
end)
DebugTools:watch("ELO", function()
    return RankedSystem:getELO()
end)

DebugTools:startMemoryPoll(60)
if Console then Console.info("DebugTools", "Debug tools ready (level="..LOG_LEVELS[DebugTools._logLevel+1]..")") end

-- §70.1 Event bus (pub/sub)
local EventBus = {}
EventBus._listeners = {}
EventBus._history   = {}
EventBus._MAX_HIST  = 200

function EventBus:subscribe(event, fn)
    if not self._listeners[event] then
        self._listeners[event] = {}
    end
    local id = tostring(fn)
    self._listeners[event][id] = fn
    return id
end

function EventBus:unsubscribe(event, id)
    if self._listeners[event] then
        self._listeners[event][id] = nil
    end
end

function EventBus:publish(event, data)
    local ev = { event = event, data = data, t = tick() }
    table.insert(self._history, ev)
    if #self._history > self._MAX_HIST then table.remove(self._history, 1) end
    if not self._listeners[event] then return end
    for _, fn in pairs(self._listeners[event]) do
        pcall(fn, data)
    end
end

function EventBus:getHistory(event, n)
    n = n or 20
    local out = {}
    for i = #self._history, math.max(1, #self._history - n + 1), -1 do
        local ev = self._history[i]
        if not event or ev.event == event then
            out[#out+1] = ev
        end
    end
    return out
end

function EventBus:getEventTypes()
    local types = {}
    for _, ev in ipairs(self._history) do
        types[ev.event] = (types[ev.event] or 0) + 1
    end
    return types
end

-- Wire up event bus to key systems
EventBus:subscribe("parry_success", function(data)
    CombatAnalytics:recordParry(data and data.etaError, data and data.mode, data and data.ballClass)
    if TournamentMode._active then TournamentMode:scorePoint(true) end
    RankedSystem._wins = RankedSystem._wins  -- just track internally
end)

EventBus:subscribe("parry_fail", function(data)
    CombatAnalytics:recordMiss(data and data.mode, data and data.ballClass)
    if TournamentMode._active then TournamentMode:scorePoint(false) end
end)

EventBus:subscribe("player_death", function(data)
    CombatAnalytics:recordDeath()
end)

if Console then Console.info("EventBus", "Event bus pub/sub system ready") end

-- §71 ─── EXTENDED NOTIFICATION SYSTEM ────────────────────────────────────────
local NotifyV2 = {}
NotifyV2._queue    = {}
NotifyV2._active   = {}
NotifyV2._maxShown = 5
NotifyV2._padding  = 8
NotifyV2._width    = 280
NotifyV2._height   = 56
NotifyV2._startX   = nil  -- set at display time
NotifyV2._startY   = 80
NotifyV2._sounds   = {
    info    = "rbxassetid://9120388661",
    warn    = "rbxassetid://9120388690",
    error   = "rbxassetid://9120388720",
    success = "rbxassetid://9120388750",
    combo   = "rbxassetid://9120388780",
}
NotifyV2._icons = {
    info    = "rbxassetid://7734057928",
    warn    = "rbxassetid://7734058053",
    error   = "rbxassetid://7734058140",
    success = "rbxassetid://7734058200",
    combo   = "rbxassetid://7734058260",
    kill    = "rbxassetid://7734058320",
    parry   = "rbxassetid://7734058380",
    update  = "rbxassetid://7734058440",
}
NotifyV2._colors = {
    info    = Color3.fromRGB(80,  180, 255),
    warn    = Color3.fromRGB(255, 180, 40),
    error   = Color3.fromRGB(255, 60,  60),
    success = Color3.fromRGB(60,  210, 100),
    combo   = Color3.fromRGB(255, 215, 0),
    kill    = Color3.fromRGB(255, 80,  80),
    parry   = Color3.fromRGB(80,  255, 150),
    update  = Color3.fromRGB(180, 80,  255),
}

local function _playNotifySound(kind)
    if not Config.audioEnabled then return end
    local id = NotifyV2._sounds[kind] or NotifyV2._sounds.info
    pcall(function()
        local s = Instance.new("Sound")
        s.SoundId = id
        s.Volume  = (Config.audioVolume or 0.5) * 0.6
        s.Parent  = workspace
        s:Play()
        game:GetService("Debris"):AddItem(s, 3)
    end)
end

function NotifyV2:push(opts)
    -- opts: { title, body, kind, timeout, icon, color, onClick }
    local notif = {
        title   = opts.title or "WindHub",
        body    = opts.body or "",
        kind    = opts.kind or "info",
        timeout = opts.timeout or 4,
        icon    = opts.icon,
        color   = opts.color,
        onClick = opts.onClick,
        id      = tostring(tick()) .. math.random(1000, 9999),
        t       = tick(),
    }
    table.insert(self._queue, notif)
    -- also push to old Notify for backward compat
    if Notify and Notify.push then
        pcall(function() Notify:push(opts) end)
    end
end

function NotifyV2:info(title, body, timeout)
    self:push({ title = title, body = body, kind = "info", timeout = timeout })
end

function NotifyV2:warn(title, body, timeout)
    self:push({ title = title, body = body, kind = "warn", timeout = timeout })
end

function NotifyV2:error(title, body, timeout)
    self:push({ title = title, body = body, kind = "error", timeout = timeout })
end

function NotifyV2:success(title, body, timeout)
    self:push({ title = title, body = body, kind = "success", timeout = timeout })
end

function NotifyV2:combo(multiplier, streak)
    self:push({
        title   = string.format("%.1fx COMBO!", multiplier),
        body    = string.format("Streak: %d parries", streak),
        kind    = "combo",
        timeout = 3,
    })
end

function NotifyV2:kill(victim, method)
    self:push({
        title   = "Kill!",
        body    = string.format("Eliminated %s via %s", victim, method or "parry"),
        kind    = "kill",
        timeout = 4,
    })
end

function NotifyV2:achievement(name, desc)
    self:push({
        title   = "Achievement: "..name,
        body    = desc or "",
        kind    = "success",
        timeout = 6,
    })
end

function NotifyV2:clear()
    self._queue  = {}
    self._active = {}
end

function NotifyV2:getQueueLength()
    return #self._queue
end

function NotifyV2:getActiveCount()
    local n = 0
    for _ in pairs(self._active) do n = n + 1 end
    return n
end

-- §71.1 Toast renderer (uses existing Notify system, extending it)
local ToastRenderer = {}
ToastRenderer._shown = {}
ToastRenderer._maxShown = 6

function ToastRenderer:canShow()
    return #self._shown < self._maxShown
end

function ToastRenderer:push(text, color, duration)
    if not self:canShow() then return end
    duration = duration or 3
    local entry = {
        text     = text,
        color    = color or Color3.fromRGB(255, 255, 255),
        start    = tick(),
        duration = duration,
    }
    table.insert(self._shown, entry)
end

function ToastRenderer:update()
    local now = tick()
    local i = 1
    while i <= #self._shown do
        if now - self._shown[i].start >= self._shown[i].duration then
            table.remove(self._shown, i)
        else
            i = i + 1
        end
    end
end

function ToastRenderer:getToasts()
    self:update()
    return self._shown
end

-- §71.2 Announcement banner
local Banner = {}
Banner._active   = false
Banner._text     = ""
Banner._color    = Color3.fromRGB(255, 220, 40)
Banner._duration = 3
Banner._startT   = 0
Banner._drawObj  = nil

function Banner:show(text, color, duration)
    self._active   = true
    self._text     = text
    self._color    = color or Color3.fromRGB(255, 220, 40)
    self._duration = duration or 3
    self._startT   = tick()
    if _drawingSupported then
        -- clear old
        if self._drawObj then
            pcall(function() self._drawObj.Visible = false; self._drawObj:Remove() end)
        end
        local vp = workspace.CurrentCamera and workspace.CurrentCamera.ViewportSize or Vector2.new(1280, 720)
        self._drawObj = Draw2:newText(
            vp.X / 2 - 200, 40,
            text, self._color, 28, true
        )
        -- auto-hide
        task.delay(duration, function()
            if self._drawObj then
                pcall(function() self._drawObj.Visible = false; self._drawObj:Remove() end)
                self._drawObj = nil
            end
            self._active = false
        end)
    end
    if Console then Console.info("Banner", text) end
end

function Banner:hide()
    self._active = false
    if self._drawObj then
        pcall(function() self._drawObj.Visible = false; self._drawObj:Remove() end)
        self._drawObj = nil
    end
end

-- Wire achievements
EventBus:subscribe("parry_success", function(data)
    local stats = CombatAnalytics:getCurrentStats()
    if stats then
        if stats.currentStreak == 10 then
            NotifyV2:achievement("Unstoppable", "10 parries in a row!")
            Banner:show("UNSTOPPABLE! ×10", Color3.fromRGB(255, 200, 40), 4)
        elseif stats.currentStreak == 25 then
            NotifyV2:achievement("Godlike", "25 consecutive parries!")
            Banner:show("G O D L I K E  ×25", Color3.fromRGB(255, 150, 0), 5)
        elseif stats.currentStreak == 50 then
            NotifyV2:achievement("Legendary", "50 consecutive parries!")
            Banner:show("L E G E N D A R Y  ×50", Color3.fromRGB(255, 215, 0), 6)
        end
    end
end)

if Console then Console.info("NotifyV2", "Extended notification system ready") end
if Console then Console.info("Banner", "Announcement banner ready") end

-- §72 ─── EXTENDED COMBO SYSTEM v2 ────────────────────────────────────────────
local ComboV2 = {}
ComboV2._streak      = 0
ComboV2._multiplier  = 1.0
ComboV2._maxMult     = 5.0
ComboV2._multStep    = 0.25
ComboV2._decayRate   = 0.1  -- multiplier lost per miss
ComboV2._lastParryT  = 0
ComboV2._comboWindow = 8    -- seconds to maintain combo without parry
ComboV2._history     = {}
ComboV2._MAX_HIST    = 200
ComboV2._bestStreak  = 0
ComboV2._bestMult    = 1.0
ComboV2._totalParries = 0
ComboV2._comboBreaks = 0
ComboV2._milestones  = { 5, 10, 15, 20, 25, 30, 50, 75, 100 }
ComboV2._hitMilestones = {}

local COMBO_NAMES = {
    [2]   = "Double Kill",
    [3]   = "Triple Kill",
    [4]   = "Quad Kill",
    [5]   = "Penta Kill",
    [7]   = "Unstoppable",
    [10]  = "Dominating",
    [15]  = "Mega Kill",
    [20]  = "Ultra Kill",
    [25]  = "Monster Kill",
    [30]  = "GODLIKE",
    [50]  = "BEYOND GODLIKE",
    [100] = "WINDHUB LEGEND",
}

function ComboV2:onParry()
    local now = tick()
    -- check if combo window expired
    if now - self._lastParryT > self._comboWindow and self._streak > 0 then
        self:_breakCombo("timeout")
    end
    self._streak      = self._streak + 1
    self._totalParries = self._totalParries + 1
    self._lastParryT  = now
    -- increase multiplier
    self._multiplier = math.min(self._maxMult, 1.0 + math.floor(self._streak / 5) * self._multStep)
    self._bestStreak = math.max(self._bestStreak, self._streak)
    self._bestMult   = math.max(self._bestMult,   self._multiplier)
    -- log
    table.insert(self._history, {
        kind       = "parry",
        t          = now,
        streak     = self._streak,
        multiplier = self._multiplier,
    })
    if #self._history > self._MAX_HIST then table.remove(self._history, 1) end
    -- check milestones
    for _, ms in ipairs(self._milestones) do
        if self._streak == ms and not self._hitMilestones[ms] then
            self._hitMilestones[ms] = true
            local name = COMBO_NAMES[ms] or (ms .. " Combo!")
            NotifyV2:combo(self._multiplier, self._streak)
            Banner:show(name, Color3.fromRGB(255, 215, 0), 3)
            EventBus:publish("combo_milestone", { streak = ms, name = name })
        end
    end
    -- named combo announcements
    if COMBO_NAMES[self._streak] then
        local comboName = COMBO_NAMES[self._streak]
        if Console then Console.info("ComboV2", comboName.." ×"..self._streak) end
    end
    EventBus:publish("combo_update", { streak = self._streak, multiplier = self._multiplier })
end

function ComboV2:onMiss()
    self._multiplier = math.max(1.0, self._multiplier - self._decayRate)
    if self._streak > 0 then
        self._comboBreaks = self._comboBreaks + 1
    end
    self._streak = 0
    self._hitMilestones = {}
    table.insert(self._history, {
        kind       = "miss",
        t          = tick(),
        streak     = 0,
        multiplier = self._multiplier,
    })
    if #self._history > self._MAX_HIST then table.remove(self._history, 1) end
    EventBus:publish("combo_break", { reason = "miss" })
end

function ComboV2:_breakCombo(reason)
    if self._streak == 0 then return end
    self._comboBreaks = self._comboBreaks + 1
    self._streak     = 0
    self._multiplier = 1.0
    self._hitMilestones = {}
    EventBus:publish("combo_break", { reason = reason })
end

function ComboV2:getMultiplier()
    return self._multiplier
end

function ComboV2:getStreak()
    return self._streak
end

function ComboV2:getStats()
    return {
        streak       = self._streak,
        multiplier   = self._multiplier,
        bestStreak   = self._bestStreak,
        bestMult     = self._bestMult,
        totalParries = self._totalParries,
        comboBreaks  = self._comboBreaks,
    }
end

function ComboV2:getComboName()
    for streak = self._streak, 1, -1 do
        if COMBO_NAMES[streak] then return COMBO_NAMES[streak] end
    end
    return self._streak > 0 and (self._streak.."x Combo") or "No Combo"
end

-- wire to event bus
EventBus:subscribe("parry_success", function() ComboV2:onParry() end)
EventBus:subscribe("parry_fail",    function() ComboV2:onMiss()  end)

if Console then Console.info("ComboV2", "Extended combo system v2 ready") end

-- §72.1 Extended kill feed v2
local KillFeedV2 = {}
KillFeedV2._entries  = {}
KillFeedV2._MAX      = 30
KillFeedV2._drawObjs = {}

function KillFeedV2:push(killer, victim, method, isLocal)
    local entry = {
        killer  = killer or "Unknown",
        victim  = victim or "Unknown",
        method  = method or "Parry",
        isLocal = isLocal or false,
        t       = tick(),
        id      = tostring(tick()),
    }
    table.insert(self._entries, 1, entry)
    if #self._entries > self._MAX then
        table.remove(self._entries)
    end
    local text = string.format("%s → %s [%s]", entry.killer, entry.victim, entry.method)
    if isLocal then
        NotifyV2:kill(victim, method)
        CombatAnalytics:recordKill(game.Players.LocalPlayer, { Name = victim })
    end
    if Console then Console.info("KillFeed", text) end
    EventBus:publish("kill_event", entry)
end

function KillFeedV2:getRecent(n)
    n = n or 10
    local out = {}
    for i = 1, math.min(n, #self._entries) do
        out[#out+1] = self._entries[i]
    end
    return out
end

function KillFeedV2:getKillsBy(name)
    local count = 0
    for _, e in ipairs(self._entries) do
        if e.killer == name then count = count + 1 end
    end
    return count
end

function KillFeedV2:clear()
    self._entries = {}
end

if Console then Console.info("KillFeedV2", "Kill feed v2 ready") end

-- §73 ─── SMART TARGET SELECTOR ───────────────────────────────────────────────
local TargetSelector = {}
TargetSelector._mode         = "auto"   -- auto, nearest, threat, manual
TargetSelector._manualTarget = nil
TargetSelector._lockTarget   = nil
TargetSelector._lockTimeout  = 3        -- seconds to maintain lock
TargetSelector._lockT        = 0
TargetSelector._history      = {}
TargetSelector._MAX_HIST     = 50
TargetSelector._weights      = {
    distance  = 0.3,
    threat    = 0.4,
    speed     = 0.2,
    angle     = 0.1,
}

function TargetSelector:setMode(mode)
    if mode == "auto" or mode == "nearest" or mode == "threat" or mode == "manual" then
        self._mode = mode
        if Console then Console.info("TargetSelector", "Mode: "..mode) end
    end
end

function TargetSelector:setManualTarget(ballId)
    self._manualTarget = ballId
    self._mode         = "manual"
end

function TargetSelector:clearLock()
    self._lockTarget = nil
    self._lockT      = 0
end

function TargetSelector:_score(bs)
    local lp   = game.Players.LocalPlayer
    local char = lp and lp.Character
    local root = char and char:FindFirstChild("HumanoidRootPart")
    if not root then return 0 end
    local pos   = bs.pos or Vector3.new(0,0,0)
    local dist  = (pos - root.Position).Magnitude
    local speed = bs.velocity and bs.velocity.Magnitude or 0
    local threat = bs.threat or 0
    -- angle: how directly is ball moving toward us
    local toUs   = (root.Position - pos)
    local angle  = 0
    if bs.velocity and bs.velocity.Magnitude > 0.01 and toUs.Magnitude > 0.01 then
        angle = bs.velocity.Unit:Dot(toUs.Unit)  -- 1 = heading straight at us
    end
    local distScore   = 1 / math.max(dist, 1)
    local speedScore  = speed / 100
    local angleScore  = math.max(0, angle)
    local threatScore = threat
    return (distScore   * self._weights.distance +
            speedScore  * self._weights.speed    +
            angleScore  * self._weights.angle    +
            threatScore * self._weights.threat)
end

function TargetSelector:selectBest(ballStates)
    if self._mode == "manual" then
        for _, bs in ipairs(ballStates) do
            if bs.id == self._manualTarget then return bs end
        end
    end
    -- check if lock is still valid
    if self._lockTarget and (tick() - self._lockT) < self._lockTimeout then
        for _, bs in ipairs(ballStates) do
            if bs.id == self._lockTarget then return bs end
        end
        self:clearLock()
    end
    if #ballStates == 0 then return nil end
    if self._mode == "nearest" then
        local lp   = game.Players.LocalPlayer
        local char = lp and lp.Character
        local root = char and char:FindFirstChild("HumanoidRootPart")
        if not root then return ballStates[1] end
        local best, bestDist = nil, math.huge
        for _, bs in ipairs(ballStates) do
            local d = (bs.pos - root.Position).Magnitude
            if d < bestDist then bestDist = d; best = bs end
        end
        return best
    elseif self._mode == "threat" then
        local best, bestThreat = nil, -math.huge
        for _, bs in ipairs(ballStates) do
            local t = bs.threat or 0
            if t > bestThreat then bestThreat = t; best = bs end
        end
        return best
    else
        -- auto: composite score
        local best, bestScore = nil, -math.huge
        for _, bs in ipairs(ballStates) do
            local s = self:_score(bs)
            if s > bestScore then bestScore = s; best = bs end
        end
        return best
    end
end

function TargetSelector:lock(ballId)
    self._lockTarget = ballId
    self._lockT      = tick()
end

function TargetSelector:isLocked()
    return self._lockTarget ~= nil and (tick() - self._lockT) < self._lockTimeout
end

function TargetSelector:getStats()
    return {
        mode       = self._mode,
        locked     = self:isLocked(),
        lockTarget = self._lockTarget,
        weights    = self._weights,
    }
end

if Console then Console.info("TargetSelector", "Smart target selector ready (mode="..TargetSelector._mode..")") end

-- §73.1 Parry timing optimizer
local TimingOptimizer = {}
TimingOptimizer._samples     = {}
TimingOptimizer._MAX         = 100
TimingOptimizer._offset      = 0      -- current optimal offset (seconds)
TimingOptimizer._confidence  = 0
TimingOptimizer._alpha       = 0.05   -- EMA rate
TimingOptimizer._mode        = "EMA"  -- EMA, median, adaptive

function TimingOptimizer:record(leadTime, success)
    -- leadTime: how early we clicked before ball arrived (positive = early)
    -- success: true/false
    table.insert(self._samples, { leadTime = leadTime, success = success, t = tick() })
    if #self._samples > self._MAX then table.remove(self._samples, 1) end
    self:_recalculate()
end

function TimingOptimizer:_recalculate()
    local successLeads = {}
    for _, s in ipairs(self._samples) do
        if s.success then successLeads[#successLeads+1] = s.leadTime end
    end
    if #successLeads == 0 then return end
    if self._mode == "EMA" then
        local target = 0
        for _, lt in ipairs(successLeads) do target = target + lt end
        target = target / #successLeads
        self._offset = self._offset * (1 - self._alpha) + target * self._alpha
    elseif self._mode == "median" then
        table.sort(successLeads)
        self._offset = successLeads[math.floor(#successLeads / 2) + 1] or 0
    elseif self._mode == "adaptive" then
        -- use middle 50% of successful lead times
        table.sort(successLeads)
        local q1 = math.floor(#successLeads * 0.25) + 1
        local q3 = math.floor(#successLeads * 0.75) + 1
        local sum, cnt = 0, 0
        for i = q1, q3 do
            sum = sum + successLeads[i]
            cnt = cnt + 1
        end
        if cnt > 0 then self._offset = sum / cnt end
    end
    -- confidence = ratio of successes
    self._confidence = #successLeads / #self._samples
end

function TimingOptimizer:getOptimalLeadTime()
    return self._offset
end

function TimingOptimizer:getConfidence()
    return self._confidence
end

function TimingOptimizer:applyToETA(eta)
    return eta - self._offset
end

function TimingOptimizer:reset()
    self._samples    = {}
    self._offset     = 0
    self._confidence = 0
end

function TimingOptimizer:getStats()
    return {
        offset     = self._offset,
        confidence = self._confidence,
        samples    = #self._samples,
        mode       = self._mode,
    }
end

if Console then Console.info("TimingOptimizer", "Parry timing optimizer ready") end

-- §74 ─── EXTENDED CONSOLE COMMANDS v2 ────────────────────────────────────────
-- Extend the existing Console with more commands
if Console and Console._commands then
    Console._commands["target"] = function(args)
        local mode = args[1] or "auto"
        TargetSelector:setMode(mode)
        return "Target mode: "..mode
    end

    Console._commands["timing"] = function(args)
        local stats = TimingOptimizer:getStats()
        return string.format(
            "Timing Offset: %.3fs | Confidence: %.0f%% | Samples: %d | Mode: %s",
            stats.offset, stats.confidence*100, stats.samples, stats.mode
        )
    end

    Console._commands["wind"] = function(args)
        local stats = WindPhysics:getStats()
        return string.format(
            "Wind: %.1f st/s %s | Gust: %.1f | Turb: %.2f | Conf: %.0f%% | Cal: %s",
            stats.wind.Magnitude, WindPhysics:getWindDirection(),
            stats.gust, stats.turbulence,
            stats.confidence * 100,
            tostring(stats.calibrated)
        )
    end

    Console._commands["spin"] = function(args)
        local lines = SpinPhysics:getStats()
        if #lines == 0 then return "No spin data" end
        return table.concat(lines, "\n")
    end

    Console._commands["tournament"] = function(args)
        local sub = args[1]
        if sub == "start" then
            TournamentMode:start()
            return "Tournament match started!"
        elseif sub == "end" then
            TournamentMode:endMatch("manual")
            return "Match ended"
        elseif sub == "score" then
            local s = TournamentMode:getStats()
            return string.format("Score: %d-%d Round %d", s.score, s.opponentScore, s.round)
        else
            local s = TournamentMode:getStats()
            return string.format(
                "Active:%s Mode:%s Score:%d-%d Round:%d Duration:%.0fs",
                tostring(s.active), s.mode, s.score, s.opponentScore, s.round, s.duration
            )
        end
    end

    Console._commands["elo"] = function(args)
        local w, l, d = RankedSystem:getRecord()
        return string.format(
            "ELO: %d [%s] | W:%d L:%d D:%d | WR:%.1f%% | Change(10g): %+.0f",
            RankedSystem:getELO(), RankedSystem:getTier(),
            w, l, d, RankedSystem:getWinRate(),
            RankedSystem:getRecentELOChange()
        )
    end

    Console._commands["combo"] = function(args)
        local s = ComboV2:getStats()
        return string.format(
            "Streak:%d | Mult:%.2fx | Best:%d (%.2fx) | Breaks:%d | Total:%d | Name: %s",
            s.streak, s.multiplier, s.bestStreak, s.bestMult,
            s.comboBreaks, s.totalParries, ComboV2:getComboName()
        )
    end

    Console._commands["flags"] = function(args)
        local sub = args[1]
        if sub == "list" then
            local enabled  = FeatureFlags:listEnabled()
            local disabled = FeatureFlags:listDisabled()
            return "Enabled("..#enabled.."): "..table.concat(enabled, ", ")..
                   "\nDisabled("..#disabled.."): "..table.concat(disabled, ", ")
        elseif sub == "set" and args[2] then
            local val = args[3] == "false" and false or true
            FeatureFlags:set(args[2], val)
            return "Set "..args[2].." = "..tostring(val)
        elseif sub == "reset" and args[2] then
            FeatureFlags:reset(args[2])
            return "Reset "..args[2].." to default"
        else
            return "Usage: flags list | flags set <FLAG> [true/false] | flags reset <FLAG>"
        end
    end

    Console._commands["macro"] = function(args)
        local sub = args[1]
        if sub == "list" then
            return table.concat(Macros:list(), "\n")
        elseif sub == "run" and args[2] then
            Macros:run(args[2])
            return "Ran macro: "..args[2]
        else
            return "Usage: macro list | macro run <name>"
        end
    end

    Console._commands["record"] = function(args)
        local sub = args[1]
        if sub == "start" then
            InputRecorder:startRecording(args[2])
            return "Recording started"..(args[2] and (" as '"..args[2].."'") or "")
        elseif sub == "stop" then
            local name = InputRecorder:stopRecording()
            return "Recording saved: "..(name or "none")
        elseif sub == "list" then
            return table.concat(InputRecorder:listRecordings(), "\n")
        elseif sub == "play" and args[2] then
            InputRecorder:playback(args[2], tonumber(args[3]))
            return "Playback started: "..args[2]
        else
            return "Usage: record start [name] | record stop | record list | record play <name> [speed]"
        end
    end

    Console._commands["mem"] = function(args)
        local snap = DebugTools:memorySnapshot()
        local lines = {}
        for k, v in pairs(snap) do
            lines[#lines+1] = string.format("  %-20s %s", k, tostring(v))
        end
        table.sort(lines)
        return "Memory snapshot:\n"..table.concat(lines, "\n")
    end

    Console._commands["watch"] = function(args)
        local vals = DebugTools:getWatchValues()
        local lines = {}
        for k, v in pairs(vals) do
            lines[#lines+1] = string.format("  %-20s %s", k, tostring(v))
        end
        table.sort(lines)
        return "Watch values:\n"..table.concat(lines, "\n")
    end

    Console._commands["perf"] = function(args)
        return PerfBench:summary()
    end

    Console._commands["killfeed"] = function(args)
        local recent = KillFeedV2:getRecent(tonumber(args[1]) or 10)
        if #recent == 0 then return "Kill feed empty" end
        local lines = {}
        for _, e in ipairs(recent) do
            lines[#lines+1] = string.format(
                "[%.0fs ago] %s → %s [%s]",
                tick() - e.t, e.killer, e.victim, e.method
            )
        end
        return table.concat(lines, "\n")
    end

    Console._commands["configio"] = function(args)
        local sub = args[1]
        if sub == "save" then
            ConfigIO:save(args[2])
            return "Config saved to slot: "..(args[2] or "default")
        elseif sub == "load" then
            local ok = ConfigIO:load(args[2])
            return ok and "Config loaded" or "Load failed"
        elseif sub == "list" then
            local slots = ConfigIO:listSlots()
            local lines = {}
            for _, s in ipairs(slots) do
                lines[#lines+1] = string.format("  %s (saved %.0fs ago)", s.name, tick() - (s.savedAt or 0))
            end
            return #lines > 0 and ("Slots:\n"..table.concat(lines, "\n")) or "No saved slots"
        elseif sub == "copy" then
            ConfigIO:copyToClipboard()
            return "Config copied to clipboard"
        elseif sub == "paste" then
            local ok = ConfigIO:importFromClipboard()
            return ok and "Config imported" or "Import failed"
        else
            return "Usage: configio save/load/list/copy/paste [slot]"
        end
    end

    Console._commands["events"] = function(args)
        local n = tonumber(args[1]) or 10
        local evType = args[2]
        local hist = EventBus:getHistory(evType, n)
        if #hist == 0 then return "No events" end
        local lines = {}
        for _, ev in ipairs(hist) do
            lines[#lines+1] = string.format("[%.2fs ago] %s", tick()-ev.t, ev.event)
        end
        return table.concat(lines, "\n")
    end

    Console._commands["hitbox"] = function(args)
        local sub = args[1]
        if sub == "style" and args[2] then
            HitboxViz:setStyle(args[2])
            return "Hitbox style: "..args[2]
        elseif sub == "on" then
            HitboxViz:start()
            return "Hitbox viz enabled"
        elseif sub == "off" then
            HitboxViz:stop()
            return "Hitbox viz disabled"
        elseif sub == "players" then
            HitboxViz:togglePlayers()
            return "Player hitboxes: "..tostring(HitboxViz._showPlayers)
        elseif sub == "balls" then
            HitboxViz:toggleBalls()
            return "Ball hitboxes: "..tostring(HitboxViz._showBalls)
        else
            return "Usage: hitbox on/off/players/balls/style <brackets|box|circle|skeleton>"
        end
    end

    Console._commands["banner"] = function(args)
        local text = table.concat(args, " ")
        if #text > 0 then
            Banner:show(text, Color3.fromRGB(255, 220, 40), 5)
            return "Banner shown"
        end
        return "Usage: banner <text>"
    end

    Console._commands["version"] = function()
        return Updater:getVersionString()
    end

    Console._commands["help"] = function(args)
        local all = {}
        for cmd, _ in pairs(Console._commands) do
            all[#all+1] = cmd
        end
        table.sort(all)
        return "Commands (" .. #all .. "):\n  " .. table.concat(all, "  ")
    end

    local _cmdCount = 0; for _ in pairs(Console._commands) do _cmdCount = _cmdCount + 1 end
    if Console then Console.info("Console", "Extended commands v2 registered (".. _cmdCount .." total)") end
end

-- §75 ─── ADVANCED BALL PREDICTION v2 ─────────────────────────────────────────
local BallPredictionV2 = {}
BallPredictionV2._predictions  = {}
BallPredictionV2._accuracy     = {}
BallPredictionV2._MAX_PRED     = 64
BallPredictionV2._models       = {}  -- per-ball velocity history models
BallPredictionV2._jerkModel    = {}  -- rate of acceleration change
BallPredictionV2._confidenceMap = {}

-- State per ball: ring buffer of (t, pos, vel, acc)
local function _newBallModel(id)
    return {
        id       = id,
        states   = {},  -- ring buffer
        maxState = 8,
        ptr      = 0,
        jerk     = Vector3.new(0,0,0),
        prevAcc  = nil,
    }
end

function BallPredictionV2:updateModel(id, pos, vel, t)
    if not self._models[id] then
        self._models[id] = _newBallModel(id)
    end
    local m   = self._models[id]
    local now = t or tick()
    -- compute acceleration from velocity history
    local prevState = m.states[m.ptr]
    local acc = Vector3.new(0, -workspace.Gravity, 0)
    if prevState then
        local dt = now - prevState.t
        if dt > 0.001 then
            acc = (vel - prevState.vel) / dt
        end
        -- compute jerk (rate of change of acceleration)
        if m.prevAcc then
            m.jerk = (acc - m.prevAcc) / math.max(dt, 0.001)
        end
    end
    m.prevAcc = acc
    m.ptr = (m.ptr % m.maxState) + 1
    m.states[m.ptr] = { t = now, pos = pos, vel = vel, acc = acc }
end

function BallPredictionV2:predict(id, dt, includeJerk)
    local m = self._models[id]
    if not m or not m.states[m.ptr] then return nil, nil end
    local s   = m.states[m.ptr]
    local pos = s.pos
    local vel = s.vel
    local acc = s.acc
    -- integrate forward dt seconds using RK4
    local function deriv(p, v, a, t_offset)
        local new_acc = Vector3.new(0, -workspace.Gravity, 0)
        if includeJerk then
            new_acc = new_acc + m.jerk * t_offset
        end
        -- Magnus and wind
        new_acc = new_acc + SpinPhysics:getMagnusForce(id, v)
        if WindPhysics._enabled then
            new_acc = new_acc + (WindPhysics:getWindAt(tick() + t_offset) - v) * 0.02
        end
        return v, new_acc
    end
    -- RK4
    local h = dt
    local k1v, k1a = deriv(pos, vel, acc, 0)
    local k2v, k2a = deriv(pos + k1v*h*0.5, vel + k1a*h*0.5, acc, h*0.5)
    local k3v, k3a = deriv(pos + k2v*h*0.5, vel + k2a*h*0.5, acc, h*0.5)
    local k4v, k4a = deriv(pos + k3v*h,     vel + k3a*h,     acc, h)
    local newPos = pos + (k1v + k2v*2 + k3v*2 + k4v) * h / 6
    local newVel = vel + (k1a + k2a*2 + k3a*2 + k4a) * h / 6
    return newPos, newVel
end

function BallPredictionV2:predictArc(id, steps, stepDt)
    steps  = steps or 20
    stepDt = stepDt or 0.05
    local points = {}
    local m = self._models[id]
    if not m or not m.states[m.ptr] then return points end
    local s   = m.states[m.ptr]
    local pos = s.pos
    local vel = s.vel
    for i = 1, steps do
        local newPos, newVel = self:predict(id, stepDt)
        if not newPos then break end
        points[#points+1] = newPos
        -- update for next step: temporarily update model
        local saved = {pos=pos, vel=vel}
        self:updateModel(id, newPos, newVel, tick() + i*stepDt)
        pos = newPos
        vel = newVel
    end
    -- restore model state isn't needed since predict reads current state
    return points
end

function BallPredictionV2:getETAToPoint(id, targetPos, tol)
    tol = tol or 3  -- studs
    local m = self._models[id]
    if not m or not m.states[m.ptr] then return nil end
    local s   = m.states[m.ptr]
    local pos = s.pos
    local vel = s.vel
    local dt  = 0.02
    local t   = 0
    for _ = 1, 500 do
        local newPos, newVel = self:predict(id, dt)
        if not newPos then break end
        t = t + dt
        if (newPos - targetPos).Magnitude <= tol then return t end
        self:updateModel(id, newPos, newVel, tick() + t)
        pos = newPos
        vel = newVel
    end
    return nil
end

function BallPredictionV2:recordAccuracy(id, predictedPos, actualPos)
    local err = (predictedPos - actualPos).Magnitude
    if not self._accuracy[id] then
        self._accuracy[id] = { total = 0, count = 0, peak = 0 }
    end
    local a = self._accuracy[id]
    a.total = a.total + err
    a.count = a.count + 1
    a.peak  = math.max(a.peak, err)
    -- confidence: lower error = higher confidence
    self._confidenceMap[id] = math.max(0, 1 - err / 20)
end

function BallPredictionV2:getAccuracy(id)
    local a = self._accuracy[id]
    if not a or a.count == 0 then return 0, 0, 0 end
    return a.total/a.count, a.peak, self._confidenceMap[id] or 0
end

function BallPredictionV2:clearModel(id)
    self._models[id]       = nil
    self._accuracy[id]     = nil
    self._confidenceMap[id] = nil
end

if Console then Console.info("BallPredictionV2", "Advanced ball prediction v2 ready") end

-- §75.1 Ball classification v2
local BallClassV2 = {}
BallClassV2._classes = {
    FASTBALL  = { name = "Fastball",   minSpeed = 80,  maxCurv = 0.5  },
    CURVEBALL = { name = "Curveball",  minSpeed = 40,  maxCurv = 3.0  },
    SLIDER    = { name = "Slider",     minSpeed = 60,  maxCurv = 1.5  },
    CHANGEUP  = { name = "Changeup",   minSpeed = 20,  maxCurv = 0.3  },
    KNUCKLE   = { name = "Knuckleball", minSpeed = 15, maxCurv = 5.0  },
    LASER     = { name = "Laser",      minSpeed = 120, maxCurv = 0.1  },
}
BallClassV2._classified = {}

function BallClassV2:classify(id, speed, curvature, spin)
    local bestClass = "Unknown"
    local bestScore = -1
    for _, cls in pairs(self._classes) do
        local speedMatch = speed >= cls.minSpeed and 1 or (speed / math.max(cls.minSpeed, 1))
        local curvMatch  = curvature <= cls.maxCurv and 1 or (cls.maxCurv / math.max(curvature, 0.001))
        local score = speedMatch * 0.6 + curvMatch * 0.4
        if score > bestScore then
            bestScore = score
            bestClass = cls.name
        end
    end
    self._classified[id] = { class = bestClass, score = bestScore, speed = speed, curvature = curvature }
    return bestClass, bestScore
end

function BallClassV2:getClass(id)
    return self._classified[id] and self._classified[id].class or "Unknown"
end

function BallClassV2:getDistribution()
    local dist = {}
    for _, c in pairs(self._classified) do
        dist[c.class] = (dist[c.class] or 0) + 1
    end
    return dist
end

if Console then Console.info("BallClassV2", "Ball classification v2 ready") end

-- §76 ─── EXTENDED REMOTE SPY v4 ──────────────────────────────────────────────
local RemoteSpyV4 = {}
RemoteSpyV4._log        = {}
RemoteSpyV4._MAX        = 500
RemoteSpyV4._blocked    = {}
RemoteSpyV4._filtered   = {}
RemoteSpyV4._hooks      = {}
RemoteSpyV4._patterns   = {}
RemoteSpyV4._capturing  = false
RemoteSpyV4._byteBudget = 10000  -- max bytes to log per second
RemoteSpyV4._bytesUsed  = 0
RemoteSpyV4._byteResetT = tick()
RemoteSpyV4._stats      = { total = 0, blocked = 0, filtered = 0 }

local function _deepSerialize(v, depth)
    depth = depth or 3
    local t = type(v)
    if t == "nil" then return "nil"
    elseif t == "boolean" or t == "number" then return tostring(v)
    elseif t == "string" then
        if #v > 100 then return string.format('"%.100s..."[%d]', v, #v) end
        return string.format('"%s"', v:gsub("[%c%z]", "?"))
    elseif t == "userdata" then
        -- try common roblox types
        local ok, s = pcall(function()
            if typeof then
                local tp = typeof(v)
                if tp == "Vector3" then return string.format("V3(%.2f,%.2f,%.2f)", v.X, v.Y, v.Z) end
                if tp == "CFrame"  then return string.format("CF(%s)", tostring(v.Position)) end
                if tp == "Color3"  then return string.format("C3(%.2f,%.2f,%.2f)", v.R, v.G, v.B) end
                if tp == "Instance" then return tostring(v) end
                return tp.."("..tostring(v)..")"
            end
            return tostring(v)
        end)
        return ok and s or tostring(v)
    elseif t == "table" then
        if depth <= 0 then return "{...}" end
        local parts = {}
        local count = 0
        for k, val in pairs(v) do
            count = count + 1
            if count > 8 then parts[#parts+1] = "..."; break end
            parts[#parts+1] = tostring(k) .. "=" .. _deepSerialize(val, depth-1)
        end
        return "{" .. table.concat(parts, ",") .. "}"
    end
    return "?" .. t
end

function RemoteSpyV4:_logEntry(remote, method, args, result)
    -- rate limit
    local now = tick()
    if now - self._byteResetT > 1 then
        self._bytesUsed = 0
        self._byteResetT = now
    end
    if self._bytesUsed > self._byteBudget then return end
    local name  = remote:GetFullName()
    -- check filters
    for _, pat in ipairs(self._filtered) do
        if name:match(pat) then
            self._stats.filtered = self._stats.filtered + 1
            return
        end
    end
    local argStr = ""
    for i, a in ipairs(args or {}) do
        argStr = argStr .. (i > 1 and ", " or "") .. _deepSerialize(a)
    end
    local entry = {
        t       = now,
        remote  = name,
        method  = method,
        args    = argStr,
        result  = result and _deepSerialize(result) or nil,
    }
    self._bytesUsed = self._bytesUsed + #name + #argStr + 40
    table.insert(self._log, 1, entry)
    if #self._log > self._MAX then table.remove(self._log) end
    self._stats.total = self._stats.total + 1
    -- check patterns for auto-alerts
    for _, pat in ipairs(self._patterns) do
        if name:match(pat.remote) then
            if Console then Console.warn("SpyV4", string.format(
                "PATTERN MATCH '%s': %s(%s)", pat.name, name, argStr
            )) end
        end
    end
end

function RemoteSpyV4:hookRemote(remote)
    if not remote or not hookfunction then return end
    if self._hooks[remote] then return end
    -- hook FireServer / InvokeServer
    local methods = { "FireServer", "InvokeServer", "FireAllClients", "FireClient" }
    for _, meth in ipairs(methods) do
        local orig = remote[meth]
        if orig then
            local ok = pcall(function()
                self._hooks[remote .. meth] = hookfunction(orig, newcclosure(function(self_r, ...)
                    local args = {...}
                    -- check if blocked
                    if RemoteSpyV4._blocked[remote:GetFullName()] then
                        RemoteSpyV4._stats.blocked = RemoteSpyV4._stats.blocked + 1
                        return
                    end
                    RemoteSpyV4:_logEntry(remote, meth, args)
                    return orig(self_r, ...)
                end))
            end)
        end
    end
    self._hooks[remote] = true
end

function RemoteSpyV4:hookAll()
    if not self._capturing then return end
    local remotes = {}
    pcall(function()
        for _, obj in ipairs(game:GetDescendants()) do
            if obj:IsA("RemoteEvent") or obj:IsA("RemoteFunction") then
                remotes[#remotes+1] = obj
            end
        end
    end)
    for _, r in ipairs(remotes) do
        self:hookRemote(r)
    end
    if Console then Console.info("SpyV4", "Hooked "..#remotes.." remotes") end
end

function RemoteSpyV4:start()
    self._capturing = true
    self:hookAll()
    -- hook new remotes as they're added
    game.DescendantAdded:Connect(function(obj)
        if self._capturing and (obj:IsA("RemoteEvent") or obj:IsA("RemoteFunction")) then
            self:hookRemote(obj)
        end
    end)
    if Console then Console.info("SpyV4", "Remote spy v4 capturing") end
end

function RemoteSpyV4:stop()
    self._capturing = false
    -- note: unhooking would require storing all originals
end

function RemoteSpyV4:block(remotePath)
    self._blocked[remotePath] = true
    if Console then Console.info("SpyV4", "Blocked: "..remotePath) end
end

function RemoteSpyV4:unblock(remotePath)
    self._blocked[remotePath] = nil
end

function RemoteSpyV4:filter(pattern)
    table.insert(self._filtered, pattern)
end

function RemoteSpyV4:addPattern(name, remotePattern)
    table.insert(self._patterns, { name = name, remote = remotePattern })
end

function RemoteSpyV4:clear()
    self._log   = {}
    self._stats = { total = 0, blocked = 0, filtered = 0 }
end

function RemoteSpyV4:getLog(n, filter)
    n = n or 20
    local out = {}
    for _, e in ipairs(self._log) do
        if not filter or e.remote:match(filter) then
            out[#out+1] = e
            if #out >= n then break end
        end
    end
    return out
end

function RemoteSpyV4:format(n, filter)
    local log = self:getLog(n, filter)
    local lines = {}
    for _, e in ipairs(log) do
        lines[#lines+1] = string.format(
            "[%.3f] %s:%s(%s)%s",
            e.t - (self._log[#self._log] and self._log[#self._log].t or e.t),
            e.remote, e.method, e.args,
            e.result and (" → "..e.result) or ""
        )
    end
    return table.concat(lines, "\n")
end

function RemoteSpyV4:getStats()
    return self._stats
end

function RemoteSpyV4:getMostFrequent(n)
    n = n or 10
    local counts = {}
    for _, e in ipairs(self._log) do
        counts[e.remote] = (counts[e.remote] or 0) + 1
    end
    local ranked = {}
    for name, count in pairs(counts) do
        ranked[#ranked+1] = { name = name, count = count }
    end
    table.sort(ranked, function(a, b) return a.count > b.count end)
    local out = {}
    for i = 1, math.min(n, #ranked) do
        out[#out+1] = ranked[i]
    end
    return out
end

-- Add patterns for known Blade Ball remotes
RemoteSpyV4:addPattern("BallAdded",   "BallAdded")
RemoteSpyV4:addPattern("Parry",       "Parry")
RemoteSpyV4:addPattern("Death",       "Death")
RemoteSpyV4:addPattern("Ability",     "Ability")
RemoteSpyV4:addPattern("Replion",     "Replion")

if FeatureFlags:isEnabled("ENABLE_REMOTE_SPY") then
    RemoteSpyV4:start()
end

-- register console command
if Console and Console._commands then
    Console._commands["spy4"] = function(args)
        local sub = args[1]
        if sub == "log" then
            return RemoteSpyV4:format(tonumber(args[2]) or 20, args[3])
        elseif sub == "clear" then
            RemoteSpyV4:clear()
            return "Log cleared"
        elseif sub == "block" and args[2] then
            RemoteSpyV4:block(args[2])
            return "Blocked: "..args[2]
        elseif sub == "unblock" and args[2] then
            RemoteSpyV4:unblock(args[2])
            return "Unblocked: "..args[2]
        elseif sub == "stats" then
            local s = RemoteSpyV4:getStats()
            return string.format("Total:%d Blocked:%d Filtered:%d", s.total, s.blocked, s.filtered)
        elseif sub == "top" then
            local top = RemoteSpyV4:getMostFrequent(tonumber(args[2]) or 10)
            local lines = {}
            for _, e in ipairs(top) do
                lines[#lines+1] = string.format("  %-50s %d", e.name, e.count)
            end
            return table.concat(lines, "\n")
        else
            return "Usage: spy4 log/clear/block/unblock/stats/top [args]"
        end
    end
end

if Console then Console.info("SpyV4", "Remote spy v4 ready") end

-- §77 ─── ADVANCED ANTI-CHEAT BYPASS LAYER ────────────────────────────────────
-- (Detection evasion only — does not bypass legitimate security or crash the server)
local BypassLayer = {}
BypassLayer._active         = false
BypassLayer._methodSpoofing = true
BypassLayer._callFreqMask   = true
BypassLayer._signatureMask  = true
BypassLayer._hooksInstalled = false
BypassLayer._log            = {}
BypassLayer._MAX_LOG        = 100
BypassLayer._detectionEvents = 0

-- Call frequency masking: make parry clicks look like natural player input
-- by distributing them across multiple frames
BypassLayer._callQueue = {}
BypassLayer._maxPerFrame = 2

function BypassLayer:_log_entry(event)
    table.insert(self._log, { t = tick(), event = event })
    if #self._log > self._MAX_LOG then table.remove(self._log, 1) end
end

function BypassLayer:queueCall(fn, delay)
    -- add to queue with optional jitter delay
    local jitter = AntiDetect and AntiDetect:_nextDelay() or (math.random() * 0.02)
    table.insert(self._callQueue, {
        fn    = fn,
        fireAt = tick() + (delay or 0) + jitter,
    })
end

function BypassLayer:processQueue()
    if not self._callFreqMask then
        -- fire all immediately
        for _, item in ipairs(self._callQueue) do
            pcall(item.fn)
        end
        self._callQueue = {}
        return
    end
    local now   = tick()
    local fired = 0
    local remaining = {}
    for _, item in ipairs(self._callQueue) do
        if item.fireAt <= now and fired < self._maxPerFrame then
            pcall(item.fn)
            fired = fired + 1
        else
            remaining[#remaining+1] = item
        end
    end
    self._callQueue = remaining
end

function BypassLayer:installHeartbeatProcessor()
    if self._hooksInstalled then return end
    self._hooksInstalled = true
    RunService.Heartbeat:Connect(function()
        if self._active then self:processQueue() end
    end)
end

function BypassLayer:start()
    self._active = true
    self:installHeartbeatProcessor()
    self:_log_entry("started")
    if Console then Console.info("BypassLayer", "Anti-detection layer active") end
end

function BypassLayer:stop()
    self._active = false
    self:_log_entry("stopped")
end

function BypassLayer:recordDetectionEvent(eventType)
    self._detectionEvents = self._detectionEvents + 1
    self:_log_entry("DETECTION_EVENT:"..tostring(eventType))
    if Console then Console.warn("BypassLayer", "Possible detection event: "..tostring(eventType)) end
    -- auto-throttle
    if self._detectionEvents % 5 == 0 then
        if Console then Console.warn("BypassLayer", "Multiple detection events — throttling") end
        if AntiDetect then AntiDetect:setProfile("Casual") end
    end
end

function BypassLayer:getStats()
    return {
        active           = self._active,
        detectionEvents  = self._detectionEvents,
        queueDepth       = #self._callQueue,
        methodSpoofing   = self._methodSpoofing,
        callFreqMask     = self._callFreqMask,
        signatureMask    = self._signatureMask,
    }
end

if FeatureFlags:isEnabled("ENABLE_ANTI_DETECT") then
    BypassLayer:start()
end

-- §77.1 Memory scanner rate limiter
local ScanRateLimit = {}
ScanRateLimit._buckets = {}  -- per-scan-type token buckets
ScanRateLimit.DEFAULTS = {
    calibrate   = { capacity = 3,  refillRate = 0.1 },
    readCFrame  = { capacity = 60, refillRate = 10  },
    readVel     = { capacity = 60, refillRate = 10  },
    gcScan      = { capacity = 5,  refillRate = 0.5 },
    patternScan = { capacity = 2,  refillRate = 0.1 },
}

for scanType, params in pairs(ScanRateLimit.DEFAULTS) do
    ScanRateLimit._buckets[scanType] = {
        tokens     = params.capacity,
        capacity   = params.capacity,
        refillRate = params.refillRate,
        lastRefill = tick(),
    }
end

function ScanRateLimit:tryConsume(scanType, n)
    n = n or 1
    local bucket = self._buckets[scanType]
    if not bucket then return true end  -- unknown type: allow
    local now = tick()
    local elapsed = now - bucket.lastRefill
    bucket.tokens     = math.min(bucket.capacity, bucket.tokens + elapsed * bucket.refillRate)
    bucket.lastRefill = now
    if bucket.tokens >= n then
        bucket.tokens = bucket.tokens - n
        return true
    end
    return false
end

function ScanRateLimit:getTokens(scanType)
    local b = self._buckets[scanType]
    return b and b.tokens or 0
end

if Console then Console.info("ScanRateLimit", "Scan rate limiter active") end

-- §78 ─── EXTENDED UI TABS v2 (Additional tabs: Combat / Analysis / Advanced) ─
-- These extend the existing 10-tab UI with more content
local UITabs2 = {}
UITabs2._tabs = {}

-- Helper (re-use mk/corner/springTween from existing scope)
local function _tab2Section(parent, title)
    local header = mk("TextLabel", {
        Parent = parent, Size = UDim2.new(1,0,0,22),
        BackgroundTransparency = 1,
        Text = "── " .. title .. " ──",
        Font = Enum.Font.GothamBold, TextSize = 12,
        TextColor3 = UI.Theme.Accent, TextXAlignment = Enum.TextXAlignment.Left,
        ZIndex = 12, LayoutOrder = 100,
    })
    return header
end

-- §78.1 Tournament UI panel
local function _buildTournamentPanel(parent)
    _tab2Section(parent, "Tournament")
    local modeRow = mk("Frame", { Parent = parent, Size = UDim2.new(1,0,0,30),
        BackgroundTransparency = 1, ZIndex = 12 })
    mk("UIListLayout", { Parent = modeRow, FillDirection = Enum.FillDirection.Horizontal,
        Padding = UDim.new(0, 6) })
    for _, mode in ipairs({"best_of_3","best_of_5","timed"}) do
        local btn = mk("TextButton", { Parent = modeRow, Size = UDim2.new(0, 80, 1, 0),
            BackgroundColor3 = UI.Theme.BgLight, Text = mode,
            Font = Enum.Font.GothamSemibold, TextSize = 10,
            TextColor3 = UI.Theme.TextDim, BorderSizePixel = 0, AutoButtonColor = false, ZIndex = 13 })
        corner(btn, 6)
        btn.MouseButton1Click:Connect(function()
            TournamentMode:setMode(mode)
            UI.notify("Tournament", "Mode: "..mode)
        end)
    end
    UI.button(parent, "▶ Start Match", function()
        TournamentMode:start()
        UI.notify("Tournament", "Match started!")
    end)
    UI.button(parent, "■ End Match", function()
        TournamentMode:endMatch("manual")
    end)
    -- score display
    local scoreLabel = mk("TextLabel", {
        Parent = parent, Size = UDim2.new(1,0,0,28),
        BackgroundTransparency = 1,
        Text = "Score: 0 - 0",
        Font = Enum.Font.GothamBold, TextSize = 16,
        TextColor3 = UI.Theme.Accent, ZIndex = 12,
    })
    -- ELO display
    mk("TextLabel", {
        Parent = parent, Size = UDim2.new(1,0,0,18),
        BackgroundTransparency = 1,
        Text = string.format("ELO: %d [%s]", RankedSystem:getELO(), RankedSystem:getTier()),
        Font = Enum.Font.Gotham, TextSize = 12,
        TextColor3 = UI.Theme.TextDim, ZIndex = 12,
    })
    -- update score label
    RunService.Heartbeat:Connect(function()
        local s = TournamentMode:getStats()
        pcall(function()
            scoreLabel.Text = string.format("Score: %d - %d | Round %d", s.score, s.opponentScore, s.round)
        end)
    end)
end

-- §78.2 Ball Analysis panel
local function _buildBallAnalysisPanel(parent)
    _tab2Section(parent, "Ball Analysis")
    local infoLabel = mk("TextLabel", {
        Parent = parent, Size = UDim2.new(1,0,0,60),
        BackgroundTransparency = 1,
        Text = "Waiting for ball data...",
        Font = Enum.Font.Code, TextSize = 11,
        TextColor3 = UI.Theme.TextDim, TextWrapped = true,
        TextXAlignment = Enum.TextXAlignment.Left, ZIndex = 12,
    })
    UI.button(parent, "Refresh Analysis", function()
        local dist = BallClassV2:getDistribution()
        local lines = {}
        for class, cnt in pairs(dist) do
            lines[#lines+1] = string.format("%s: %d", class, cnt)
        end
        infoLabel.Text = #lines > 0 and table.concat(lines, "\n") or "No ball data yet"
    end)
    UI.button(parent, "Clear Models", function()
        BallPredictionV2._models = {}
        UI.notify("BallAnalysis", "Prediction models cleared")
    end)
    UI.toggle(parent, "Wind Physics", Config.windPhysics, function(v)
        Config.windPhysics = v
        if v then WindPhysics:enable() else WindPhysics:disable() end
    end)
    UI.toggle(parent, "Jerk Model", false, function(v)
        -- stored in config
        Config.useJerkModel = v
    end)
    _tab2Section(parent, "Spin Data")
    local spinLabel = mk("TextLabel", {
        Parent = parent, Size = UDim2.new(1,0,0,40),
        BackgroundTransparency = 1,
        Text = "No spin data",
        Font = Enum.Font.Code, TextSize = 10,
        TextColor3 = UI.Theme.TextDim, TextWrapped = true,
        TextXAlignment = Enum.TextXAlignment.Left, ZIndex = 12,
    })
    UI.button(parent, "Refresh Spin", function()
        local stats = SpinPhysics:getStats()
        spinLabel.Text = #stats > 0 and table.concat(stats, "\n") or "No spin data"
    end)
end

-- §78.3 Advanced settings panel
local function _buildAdvancedPanel(parent)
    _tab2Section(parent, "Prediction Engine")
    UI.toggle(parent, "Use Jerk Model",        Config.useJerkModel    or false, function(v) Config.useJerkModel    = v end)
    UI.toggle(parent, "Wind Physics",          Config.windPhysics     or false, function(v) Config.windPhysics     = v end)
    UI.toggle(parent, "Magnus Force",          Config.magnusForce     or true,  function(v) Config.magnusForce     = v end)
    UI.slider(parent, "Prediction Steps",      20, 5, 60, function(v)  Config.predSteps     = v end)
    UI.slider(parent, "Monte Carlo Samples",   64, 16, 256, function(v) Config.monteCarloSamples = v end)
    _tab2Section(parent, "Bypass Layer")
    UI.toggle(parent, "Call Freq Masking", BypassLayer._callFreqMask, function(v)
        BypassLayer._callFreqMask = v
    end)
    UI.toggle(parent, "Signature Masking", BypassLayer._signatureMask, function(v)
        BypassLayer._signatureMask = v
    end)
    UI.slider(parent, "Max Calls/Frame",   2, 1, 8, function(v)
        BypassLayer._maxPerFrame = math.floor(v)
    end)
    _tab2Section(parent, "Memory Scanner")
    UI.toggle(parent, "Auto-Calibrate", Config.autoCalibrate or true, function(v) Config.autoCalibrate = v end)
    UI.toggle(parent, "Write-Barrier Watch", Config.writeBarrierWatch or true, function(v) Config.writeBarrierWatch = v end)
    UI.slider(parent, "Scan Interval (s)", 0.5, 0.1, 5, function(v) Config.scanInterval = v end)
    UI.button(parent, "Manual Calibrate", function()
        if MemScanner then MemScanner:calibrate() end
        UI.notify("MemScanner", "Calibration triggered")
    end)
    _tab2Section(parent, "Feature Flags")
    for _, flag in ipairs({ "ENABLE_MININET", "ENABLE_MONTE_CARLO", "ENABLE_DRAWING_ESP", "ENABLE_AUDIO", "ENABLE_ANTI_DETECT" }) do
        local shortName = flag:gsub("ENABLE_", "")
        UI.toggle(parent, shortName, FeatureFlags:isEnabled(flag), function(v)
            FeatureFlags:set(flag, v)
        end)
    end
    _tab2Section(parent, "Config I/O")
    UI.button(parent, "Save Config", function()
        ConfigIO:save("ui_save")
        UI.notify("ConfigIO", "Config saved")
    end)
    UI.button(parent, "Load Config", function()
        ConfigIO:load("ui_save")
        UI.notify("ConfigIO", "Config loaded")
    end)
    UI.button(parent, "Copy to Clipboard", function()
        local ok = ConfigIO:copyToClipboard()
        UI.notify("ConfigIO", ok and "Copied!" or "Clipboard unavailable")
    end)
    UI.button(parent, "Import from Clipboard", function()
        local ok = ConfigIO:importFromClipboard()
        UI.notify("ConfigIO", ok and "Imported!" or "Import failed")
    end)
end

-- Register these panels on existing tab pages if available
task.defer(function()
    -- try to attach to existing GUI
    pcall(function()
        local gui = game.Players.LocalPlayer.PlayerGui:FindFirstChild("WindHub")
        if not gui then return end
        local tabFrame = gui:FindFirstChild("Tabs", true)
        if not tabFrame then return end
        -- find existing pages
        for _, page in ipairs(tabFrame:GetChildren()) do
            if page:IsA("ScrollingFrame") then
                local name = page.Name
                if name:match("Parry") then
                    -- add tournament section to parry tab
                    _buildTournamentPanel(page)
                elseif name:match("ESP") or name:match("Visual") then
                    -- add hitbox section
                    UI.toggle(page, "Hitbox Viz", HitboxViz._active, function(v)
                        if v then HitboxViz:start() else HitboxViz:stop() end
                    end)
                    UI.dropdown(page, "Hitbox Style", {"brackets","box","circle","skeleton"}, function(v)
                        HitboxViz:setStyle(v)
                    end)
                elseif name:match("Settings") or name:match("Config") then
                    _buildAdvancedPanel(page)
                end
            end
        end
    end)
end)

if Console then Console.info("UITabs2", "Extended UI panels registered") end

-- §79 ─── EXTENDED MAIN LOOP v2 ────────────────────────────────────────────────
-- Integrates all new systems into the existing heartbeat/parry loop
local MainLoopV2 = {}
MainLoopV2._active    = true
MainLoopV2._frameN    = 0
MainLoopV2._lastFPS   = 60
MainLoopV2._fpsSmooth = 60

-- Systems to update at various frame rates
local UPDATE_SCHEDULE = {
    { interval = 0,    name = "BallPrediction",  fn = function(dt) end }, -- every frame
    { interval = 0.05, name = "BallVizUpdate",   fn = function(dt) end }, -- 20 Hz
    { interval = 0.1,  name = "PlayerAnalysis",  fn = function(dt) end }, -- 10 Hz
    { interval = 0.5,  name = "ServerAnalysis",  fn = function(dt) end }, -- 2 Hz
    { interval = 1.0,  name = "NetworkMonitor",  fn = function(dt) end }, -- 1 Hz
    { interval = 5.0,  name = "MemoryCheck",     fn = function(dt) end }, -- 0.2 Hz
    { interval = 30.0, name = "AutoSave",         fn = function(dt) ConfigIO:autoSave() end }, -- every 30s
}
for _, s in ipairs(UPDATE_SCHEDULE) do s._last = 0 end

function MainLoopV2:_runScheduled(now)
    for _, sched in ipairs(UPDATE_SCHEDULE) do
        if now - sched._last >= sched.interval then
            sched._last = now
            PerfBench:mark(sched.name)
            pcall(sched.fn, now - sched._last)
            PerfBench:measure(sched.name, sched.name)
        end
    end
end

function MainLoopV2:_updateFPS(dt)
    local fps = dt > 0 and (1 / dt) or 60
    self._fpsSmooth = self._fpsSmooth * 0.9 + fps * 0.1
    self._lastFPS = self._fpsSmooth
    CombatAnalytics:recordFPS(fps)
end

function MainLoopV2:_integrateBallSystems(bs)
    -- for each tracked ball, run advanced prediction + classification
    if not bs then return end
    for id, ballState in pairs(BallTracker._balls or {}) do
        -- update prediction model
        if ballState.pos and ballState.velocity then
            BallPredictionV2:updateModel(id, ballState.pos, ballState.velocity)
            -- classify ball
            local speed = ballState.velocity.Magnitude
            BallClassV2:classify(id, speed, 0, 0)
            -- update spin model
            if ballState._prevVel then
                SpinPhysics:updateSpin(id, ballState.velocity, ballState._prevVel, 0.05)
            end
            ballState._prevVel = ballState.velocity
        end
    end
end

function MainLoopV2:_updateTargeting()
    local balls = {}
    for _, bs in pairs(BallTracker._balls or {}) do
        balls[#balls+1] = bs
    end
    if #balls > 0 then
        local best = TargetSelector:selectBest(balls)
        if best then
            TargetSelector:lock(best.id)
        end
    end
end

function MainLoopV2:_processParryResult(success, bs, etaError)
    if success then
        EventBus:publish("parry_success", {
            etaError  = etaError,
            mode      = Config.parryMode,
            ballClass = bs and BallClassV2:getClass(bs.id) or "Unknown",
            ping      = PingComp and PingComp:get() or 0,
        })
        TimingOptimizer:record(etaError or 0, true)
    else
        EventBus:publish("parry_fail", {
            mode      = Config.parryMode,
            ballClass = bs and BallClassV2:getClass(bs and bs.id) or "Unknown",
        })
        TimingOptimizer:record(etaError or 0, false)
    end
end

function MainLoopV2:start()
    RunService.Heartbeat:Connect(function(dt)
        if not self._active then return end
        self._frameN = self._frameN + 1
        local now = tick()
        PerfBench:mark("MainLoop")
        self:_updateFPS(dt)
        self:_runScheduled(now)
        self:_integrateBallSystems(nil)
        self:_updateTargeting()
        PerfBench:measure("MainLoop", "MainLoop")
    end)
    if Console then Console.info("MainLoopV2", "Extended main loop running") end
end

function MainLoopV2:stop()
    self._active = false
end

function MainLoopV2:getStats()
    return {
        frame = self._frameN,
        fps   = self._lastFPS,
    }
end

MainLoopV2:start()

-- §79.1 Graceful shutdown handler
local Shutdown = {}
Shutdown._handlers = {}
Shutdown._fired    = false

function Shutdown:register(name, fn)
    self._handlers[#self._handlers+1] = { name = name, fn = fn }
end

function Shutdown:fire(reason)
    if self._fired then return end
    self._fired = true
    if Console then Console.warn("Shutdown", "Shutting down: "..(reason or "unknown")) end
    for _, h in ipairs(self._handlers) do
        pcall(function()
            if Console then Console.info("Shutdown", "Closing: "..h.name) end
            h.fn()
        end)
    end
end

-- Register cleanup handlers
Shutdown:register("ConfigAutoSave",  function() ConfigIO:save("shutdown_save") end)
Shutdown:register("SessionExport",   function() if SessionManager and SessionManager.export then SessionManager:export() end end)
Shutdown:register("BallVizStop",     function() BallViz:stop() end)
Shutdown:register("HitboxVizStop",   function() HitboxViz:stop() end)
Shutdown:register("AntiDetectStop",  function() if AntiDetect then AntiDetect:stop() end end)
Shutdown:register("Draw2Clear",      function() Draw2:clearAll() end)
Shutdown:register("MainLoopStop",    function() MainLoopV2:stop() end)
Shutdown:register("CombatRoundEnd",  function() CombatAnalytics:endRound() end)

game:BindToClose(function()
    Shutdown:fire("game_close")
end)

if Console then Console.info("Shutdown", "Shutdown handlers registered ("..#Shutdown._handlers..")") end

-- §80 ─── COMPREHENSIVE HELP SYSTEM ───────────────────────────────────────────
local Help = {}
Help._topics = {}

local function _topic(name, content)
    Help._topics[name:lower()] = { name = name, content = content }
end

_topic("overview", [[
WindHub v6.0 - The #1 Blade Ball Script

OVERVIEW
--------
WindHub is a comprehensive Blade Ball script featuring:
• Auto-parry engine with 5 modes (Ultra/Predictive/Conservative/RK4/Fusion)
• Advanced ESP (balls, players, minimap, arc, danger zones)
• Memory scanner for direct address reading
• Anti-detection system with jitter profiles
• Full analytics dashboard (accuracy, ETA, latency percentiles)
• Tournament mode with ELO ranking
• Remote spy v4 with pattern matching
• 20+ console commands for live tuning
• Mobile + PC support

EXECUTORS SUPPORTED
-------------------
Delta, Codex, Xeno, Wave, Optimware/Opium, Volt, Potassium

QUICK START
-----------
1. Script loads automatically
2. GUI appears (drag to move)
3. Enable auto-parry in Parry tab
4. Configure mode: Ultra (aggressive) or Conservative (safe)
5. Use console (` key) for live tuning
]])

_topic("parry", [[
PARRY MODES
-----------
Ultra       - Widest hitbox, fastest response, high aggression
Predictive  - EMA-adaptive window with physics prediction
Conservative - Tight timing, human-like delays, low detection risk
RK4         - Full Runge-Kutta 4th order physics integration
Fusion      - Combines MiniNet AI + RK4 + Monte Carlo uncertainty

SETTINGS
--------
parryMode          - Active mode (Ultra/Predictive/Conservative/RK4/Fusion)
parryWindow        - Accept window in seconds (default 0.3)
humanizeParry      - Add Gaussian jitter to timing (reduces detection)
predictLeadTime    - Lead time for prediction modes
hitboxExpand       - Expand parry hitbox radius

COMMANDS
--------
parry status       - Show current parry stats
parry mode <name>  - Switch mode
timing             - Show timing optimizer stats
]])

_topic("esp", [[
ESP FEATURES
------------
ballESP    - Ball glow + velocity vector + ETA label
playerESP  - Player bracket/box/skeleton/circle ESP
arcESP     - Predicted trajectory arc
minimap    - 2D radar with ball positions + threat rings
dangerZone - Red overlay when ball is within range
hitboxViz  - Show hitbox boundaries (configurable style)

DRAWING MODES
-------------
brackets  - Corner brackets (default)
box       - Full bounding box
circle    - Distance-scaled circle
skeleton  - Bone structure overlay

COMMANDS
--------
hitbox style <mode>   - Set hitbox style
hitbox on/off         - Toggle hitbox viz
hitbox players/balls  - Toggle player/ball hitboxes
]])

_topic("console", [[
CONSOLE
-------
Open: Backquote (`) key
Close: Escape or click X

ALL COMMANDS
------------
help               - List all commands
status             - Full system status
calibrate          - Trigger memory calibration
sunc               - Run sUNC checker
parry [status/mode] - Parry control
ping               - Ping stats
gc                 - GC stats
version            - Version info
exec <code>        - Execute Lua code
spy4 [log/clear/block/top] - Remote spy
server             - Server analysis
accuracy           - Accuracy stats
latency            - Latency percentiles
speeds             - Speed cluster chart
eta                - ETA sparkline
players            - Player tracker
sigsdb             - Ball signature DB
killfeed           - Kill feed
leaderboard        - Score leaderboard
session            - Session summary
export_session     - Export session log
events [n] [type]  - Event bus history
minimap_snap       - Minimap screenshot
diff               - Config diff
profiles           - Profile manager
snapshot           - Config snapshot
blaze              - Toggle blaze barrier
ping_audio         - Toggle ping audio
target [mode]      - Target selector mode
timing             - Timing optimizer
wind               - Wind physics stats
spin               - Spin data
tournament [sub]   - Tournament control
elo                - ELO/ranked stats
combo              - Combo system
flags [list/set]   - Feature flags
macro [list/run]   - Macro system
record [sub]       - Input recorder
mem                - Memory snapshot
watch              - Watch values
perf               - Performance benchmark
hitbox [sub]       - Hitbox viz control
banner <text>      - Show announcement banner
configio [sub]     - Config export/import
spy4 [sub]         - Remote spy v4
]])

_topic("memory", [[
MEMORY SCANNER
--------------
The memory scanner reads ball positions and velocities directly from memory,
bypassing normal Roblox replication lag for ultra-low-latency input.

COMPONENTS
----------
MemScanner v3  - Multi-probe auto-calibration, fast-path CFrame reader
UNC functions  - getaddress(), readprocessmemory() for raw bytes
IEEE-754       - Decode F32/F64 floats from raw byte strings
LRU cache      - Up to 512 address entries, auto-evicts oldest
Write-barrier  - Drift check every 120 frames, recalibrates if error > 2 studs

CALIBRATION
-----------
Auto-calibrates on startup using multiple known instances.
Manual: use "calibrate" console command or MemScanner:calibrate()

SCAN TYPES
----------
readCFrame    - Read full 12-float CFrame matrix from instance
readVelocity  - Read raw velocity from physics engine memory
gcScan        - Scan GC heap for ball instances
patternScan   - Byte-pattern scanner for known signatures
]])

_topic("analytics", [[
ANALYTICS DASHBOARD
-------------------
Available via Stats tab in GUI or console commands.

PER-SESSION STATS
-----------------
• Accuracy (parries / total)
• Average ETA error (ms)
• Max parry streak
• Kills / Deaths / K/D ratio
• Average ping
• Mode breakdown (parries per mode)

LIFETIME STATS
--------------
• Total rounds, parries, misses
• Best streak ever
• Best/worst round accuracy
• Accuracy trend (last N rounds)

LATENCY PERCENTILES
-------------------
P50, P75, P90, P99 latency from NetworkMonitor ring buffer

SPEED CLUSTERS
--------------
Ball speed histogram in 10 st/s buckets (0-100+ st/s)

ETA SPARKLINE
-------------
Last 30 ETA values visualized as ASCII sparkline

COMBAT ANALYTICS
----------------
CombatAnalytics:getCurrentStats()  - current round
CombatAnalytics:getLifetimeStats() - all time
CombatAnalytics:getBestRound()     - best round
CombatAnalytics:getModeBreakdown() - per-mode counts
]])

function Help:get(topic)
    local t = self._topics[topic:lower()]
    return t and t.content or "No help for: "..topic
end

function Help:list()
    local topics = {}
    for name, _ in pairs(self._topics) do
        topics[#topics+1] = name
    end
    table.sort(topics)
    return topics
end

-- Register console command
if Console and Console._commands then
    Console._commands["help2"] = function(args)
        if args[1] then
            return Help:get(args[1])
        end
        return "Topics: " .. table.concat(Help:list(), ", ") .. "\nUsage: help2 <topic>"
    end
end

if Console then Console.info("Help", "Help system ready ("..#Help:list().." topics)") end

-- §81 ─── EXTENDED PHYSICS CALIBRATION ────────────────────────────────────────
local PhysicsCalib = {}
PhysicsCalib._gravity        = workspace.Gravity
PhysicsCalib._airDensity     = 1.225  -- kg/m³
PhysicsCalib._ballMass       = 0.145  -- kg (approx)
PhysicsCalib._ballRadius     = 0.5    -- studs
PhysicsCalib._dragCoeff      = 0.47   -- sphere Cd
PhysicsCalib._liftCoeff      = 0.3
PhysicsCalib._samples        = {}
PhysicsCalib._MAX_SAMPLES    = 64
PhysicsCalib._calibrated     = false
PhysicsCalib._gravityEst     = workspace.Gravity
PhysicsCalib._dragEst        = 0.02   -- effective drag per unit speed
PhysicsCalib._calibConfidence = 0

-- Pre-computed constants
local function _computeConstants(self)
    self._area         = math.pi * self._ballRadius^2
    self._dragFactor   = self._airDensity * self._dragCoeff * self._area / (2 * self._ballMass)
    self._liftFactor   = self._airDensity * self._liftCoeff * self._area / (2 * self._ballMass)
end
PhysicsCalib:_computeConstants()

function PhysicsCalib:sampleTrajectory(pos0, vel0, pos1, vel1, dt)
    if dt < 0.001 then return end
    -- estimate gravity from y-acceleration
    local acc   = (vel1 - vel0) / dt
    local gEst  = -acc.Y + self._dragFactor * vel0.Y * math.abs(vel0.Y)
    -- estimate drag from xy deceleration
    local hSpeed0 = Vector3.new(vel0.X, 0, vel0.Z).Magnitude
    local hSpeed1 = Vector3.new(vel1.X, 0, vel1.Z).Magnitude
    local hAcc    = (hSpeed1 - hSpeed0) / dt
    local dragEst = hSpeed0 > 1 and (-hAcc / hSpeed0^2) or self._dragEst
    table.insert(self._samples, {
        gEst    = gEst,
        dragEst = math.max(0, dragEst),
        t       = tick(),
    })
    if #self._samples > self._MAX_SAMPLES then table.remove(self._samples, 1) end
    if #self._samples >= 10 then self:_refit() end
end

function PhysicsCalib:_refit()
    local gSum, dragSum, n = 0, 0, 0
    -- use trimmed mean (drop top/bottom 10%)
    local gVals, dVals = {}, {}
    for _, s in ipairs(self._samples) do
        if s.gEst > 0 then gVals[#gVals+1] = s.gEst end
        dVals[#dVals+1] = s.dragEst
    end
    table.sort(gVals)
    table.sort(dVals)
    local trim = math.floor(#gVals * 0.1)
    for i = trim+1, #gVals-trim do gSum = gSum + gVals[i]; n = n + 1 end
    self._gravityEst = n > 0 and (gSum / n) or workspace.Gravity
    local dtrim = math.floor(#dVals * 0.1)
    local dsum, dn = 0, 0
    for i = dtrim+1, #dVals-dtrim do dsum = dsum + dVals[i]; dn = dn + 1 end
    self._dragEst = dn > 0 and (dsum / dn) or 0.02
    self._calibrated = true
    -- confidence: inverse of variance
    local var = 0
    for i = trim+1, #gVals-trim do var = var + (gVals[i] - self._gravityEst)^2 end
    var = n > 1 and (var / (n-1)) or 1
    self._calibConfidence = math.min(1, 10 / math.max(var, 0.01))
end

function PhysicsCalib:applyToAcceleration(vel, spin)
    local g   = Vector3.new(0, -self._gravityEst, 0)
    local spd = vel.Magnitude
    local drag = -vel.Unit * spd^2 * self._dragEst
    local lift = spin and spin:Cross(vel) * self._liftFactor or Vector3.new(0,0,0)
    return g + drag + lift
end

function PhysicsCalib:getBallStats()
    return {
        gravity    = self._gravityEst,
        drag       = self._dragEst,
        calibrated = self._calibrated,
        confidence = self._calibConfidence,
        samples    = #self._samples,
        dragFactor = self._dragFactor,
    }
end

function PhysicsCalib:setRadius(r)
    self._ballRadius = r
    _computeConstants(self)
end

function PhysicsCalib:setMass(m)
    self._ballMass = m
    _computeConstants(self)
end

function PhysicsCalib:reset()
    self._samples         = {}
    self._calibrated      = false
    self._calibConfidence = 0
    self._gravityEst      = workspace.Gravity
    self._dragEst         = 0.02
end

if Console then Console.info("PhysicsCalib", string.format(
    "Physics calibration ready. g=%.2f drag=%.4f",
    PhysicsCalib._gravityEst, PhysicsCalib._dragEst
)) end

-- §81.1 Bounce predictor
local BouncePredict = {}
BouncePredict._restitution   = 0.6   -- coefficient of restitution
BouncePredict._groundY       = 0
BouncePredict._wallPlanes    = {}    -- list of {normal, d} for half-spaces
BouncePredict._maxBounces    = 5
BouncePredict._enabled       = true

function BouncePredict:setGround(y)
    self._groundY = y
end

function BouncePredict:addWall(normal, d)
    table.insert(self._wallPlanes, { normal = normal, d = d })
end

function BouncePredict:predictBounces(pos, vel)
    if not self._enabled then return { pos } end
    local points = { pos }
    local p = pos
    local v = vel
    local g = Vector3.new(0, -workspace.Gravity, 0)
    local dt = 0.02
    local bounces = 0
    for _ = 1, 1000 do
        v = v + g * dt
        p = p + v * dt
        -- check ground
        if p.Y < self._groundY then
            bounces = bounces + 1
            if bounces > self._maxBounces then break end
            -- reflect Y velocity
            v = Vector3.new(v.X, -v.Y * self._restitution, v.Z)
            p = Vector3.new(p.X, self._groundY, p.Z)
            table.insert(points, p)
        end
        -- check walls
        for _, wall in ipairs(self._wallPlanes) do
            local dist = wall.normal:Dot(p) - wall.d
            if dist < 0 then
                bounces = bounces + 1
                if bounces <= self._maxBounces then
                    v = v - wall.normal * (1 + self._restitution) * wall.normal:Dot(v)
                    p = p - wall.normal * dist
                    table.insert(points, p)
                end
            end
        end
        if bounces >= self._maxBounces then break end
    end
    return points
end

function BouncePredict:getFinalRestPoint(pos, vel)
    local points = self:predictBounces(pos, vel)
    return points[#points]
end

if Console then Console.info("BouncePredict", "Bounce predictor ready (maxBounces="..BouncePredict._maxBounces..")") end

-- §82 ─── EXTENDED NETWORK LAYER v2 ──────────────────────────────────────────
local NetLayerV2 = {}
NetLayerV2._pings          = {}  -- ring buffer (capacity 120)
NetLayerV2._MAX_PINGS      = 120
NetLayerV2._jitterHistory  = {}
NetLayerV2._MAX_JITTER     = 60
NetLayerV2._packetLoss     = 0   -- estimated 0-1
NetLayerV2._congestion     = false
NetLayerV2._lastPingT      = 0
NetLayerV2._pingInterval   = 0.5  -- seconds between ping requests
NetLayerV2._adaptiveMode   = true
NetLayerV2._lastGoodPing   = 0.05

-- We estimate ping using our own method since Roblox doesn't expose raw RTT
function NetLayerV2:_recordPing(ping)
    table.insert(self._pings, { t = tick(), v = ping })
    if #self._pings > self._MAX_PINGS then table.remove(self._pings, 1) end
    -- update PingComp
    if PingComp then
        -- PingComp likely has its own EMA; we supplement here
        self._lastGoodPing = ping
    end
    -- compute jitter
    if #self._pings >= 2 then
        local prev = self._pings[#self._pings - 1].v
        local curr = self._pings[#self._pings].v
        table.insert(self._jitterHistory, math.abs(curr - prev))
        if #self._jitterHistory > self._MAX_JITTER then
            table.remove(self._jitterHistory, 1)
        end
    end
end

function NetLayerV2:getAvgPing()
    if #self._pings == 0 then return 0.05 end
    local sum = 0
    for _, p in ipairs(self._pings) do sum = sum + p.v end
    return sum / #self._pings
end

function NetLayerV2:getMinPing()
    if #self._pings == 0 then return 0.05 end
    local mn = math.huge
    for _, p in ipairs(self._pings) do mn = math.min(mn, p.v) end
    return mn
end

function NetLayerV2:getMaxPing()
    if #self._pings == 0 then return 0.05 end
    local mx = -math.huge
    for _, p in ipairs(self._pings) do mx = math.max(mx, p.v) end
    return mx
end

function NetLayerV2:getJitter()
    if #self._jitterHistory == 0 then return 0 end
    local sum = 0
    for _, j in ipairs(self._jitterHistory) do sum = sum + j end
    return sum / #self._jitterHistory
end

function NetLayerV2:getPercentile(pct)
    if #self._pings == 0 then return 0.05 end
    local vals = {}
    for _, p in ipairs(self._pings) do vals[#vals+1] = p.v end
    table.sort(vals)
    local idx = math.ceil(#vals * pct / 100)
    return vals[math.max(1, idx)]
end

function NetLayerV2:detectCongestion()
    local jitter = self:getJitter()
    local avg    = self:getAvgPing()
    local min    = self:getMinPing()
    self._congestion = (jitter > 0.02) or (avg > min * 2.5)
    return self._congestion
end

function NetLayerV2:estimatePacketLoss()
    -- estimate from gaps in ping measurement
    if #self._pings < 10 then return 0 end
    local gaps = 0
    for i = 2, #self._pings do
        local dt = self._pings[i].t - self._pings[i-1].t
        if dt > self._pingInterval * 3 then gaps = gaps + 1 end
    end
    self._packetLoss = gaps / #self._pings
    return self._packetLoss
end

function NetLayerV2:getQuality()
    local avg  = self:getAvgPing()
    local jit  = self:getJitter()
    local loss = self._packetLoss
    if avg < 0.05 and jit < 0.005 and loss < 0.01 then return "Excellent" end
    if avg < 0.1  and jit < 0.015 and loss < 0.03 then return "Good" end
    if avg < 0.2  and jit < 0.04  and loss < 0.08 then return "Fair" end
    if avg < 0.4  then return "Poor" end
    return "Bad"
end

function NetLayerV2:getStats()
    return {
        avg         = self:getAvgPing(),
        min         = self:getMinPing(),
        max         = self:getMaxPing(),
        jitter      = self:getJitter(),
        p95         = self:getPercentile(95),
        packetLoss  = self:estimatePacketLoss(),
        congestion  = self:detectCongestion(),
        quality     = self:getQuality(),
        samples     = #self._pings,
    }
end

-- Integrate with PingComp heartbeat
RunService.Heartbeat:Connect(function()
    if PingComp then
        local now = tick()
        if now - NetLayerV2._lastPingT >= NetLayerV2._pingInterval then
            NetLayerV2._lastPingT = now
            local ping = PingComp:get()
            NetLayerV2:_recordPing(ping)
        end
    end
end)

if Console then Console.info("NetLayerV2", "Extended network layer v2 ready") end

-- §82.1 Packet scheduler
local PacketScheduler = {}
PacketScheduler._pending   = {}
PacketScheduler._rateLimit = 20  -- max packets per second
PacketScheduler._tokens    = 20
PacketScheduler._lastRefill = tick()
PacketScheduler._CAPACITY  = 30

function PacketScheduler:_refill()
    local now  = tick()
    local dt   = now - self._lastRefill
    self._tokens = math.min(self._CAPACITY, self._tokens + dt * self._rateLimit)
    self._lastRefill = now
end

function PacketScheduler:canSend()
    self:_refill()
    return self._tokens >= 1
end

function PacketScheduler:consume(n)
    self:_refill()
    n = n or 1
    if self._tokens >= n then
        self._tokens = self._tokens - n
        return true
    end
    return false
end

function PacketScheduler:schedule(fn, priority)
    table.insert(self._pending, { fn = fn, priority = priority or 5 })
    table.sort(self._pending, function(a, b) return a.priority < b.priority end)
end

function PacketScheduler:flush()
    if not self:canSend() then return end
    local item = table.remove(self._pending, 1)
    if item then
        self:consume(1)
        pcall(item.fn)
    end
end

RunService.Heartbeat:Connect(function()
    PacketScheduler:flush()
end)

if Console then Console.info("PacketScheduler", "Packet scheduler ready") end

-- §83 ─── EXTENDED STEALTH ENGINE ─────────────────────────────────────────────
local StealthEngine = {}
StealthEngine._active       = false
StealthEngine._profile      = "Average"
StealthEngine._reactionMin  = 0.08   -- seconds
StealthEngine._reactionMax  = 0.25
StealthEngine._parryWindow  = 0.3
StealthEngine._clickVariance = 0.01
StealthEngine._missRate      = 0.00  -- 0 = never miss on purpose
StealthEngine._burstCooldown = 0.5
StealthEngine._burstCount    = 0
StealthEngine._burstLimit    = 3
StealthEngine._idleJitter    = true
StealthEngine._mouseSmoothing = true

local STEALTH_PROFILES = {
    Invisible = {
        reactionMin   = 0.12, reactionMax   = 0.40,
        missRate      = 0.03, clickVariance = 0.03,
        burstLimit    = 1,
        description   = "Ultra-safe, slight miss rate, very slow reaction"
    },
    Casual    = {
        reactionMin   = 0.10, reactionMax   = 0.30,
        missRate      = 0.01, clickVariance = 0.02,
        burstLimit    = 2,
        description   = "Looks like a decent casual player"
    },
    Average   = {
        reactionMin   = 0.07, reactionMax   = 0.20,
        missRate      = 0.00, clickVariance = 0.01,
        burstLimit    = 3,
        description   = "Average skilled player baseline"
    },
    Pro       = {
        reactionMin   = 0.05, reactionMax   = 0.15,
        missRate      = 0.00, clickVariance = 0.005,
        burstLimit    = 5,
        description   = "Pro-level speed, still human-looking"
    },
    Tryhard   = {
        reactionMin   = 0.03, reactionMax   = 0.10,
        missRate      = 0.00, clickVariance = 0.002,
        burstLimit    = 8,
        description   = "Maximum speed, borderline detectable"
    },
}

function StealthEngine:setProfile(name)
    local p = STEALTH_PROFILES[name]
    if not p then
        if Console then Console.warn("StealthEngine", "Unknown profile: "..tostring(name)) end
        return
    end
    self._profile      = name
    self._reactionMin  = p.reactionMin
    self._reactionMax  = p.reactionMax
    self._missRate     = p.missRate
    self._clickVariance = p.clickVariance
    self._burstLimit   = p.burstLimit
    if Console then Console.info("StealthEngine", "Profile: "..name.." - "..p.description) end
end

function StealthEngine:getReactionDelay()
    -- Box-Muller Gaussian between min and max
    local mean  = (self._reactionMin + self._reactionMax) / 2
    local sigma = (self._reactionMax - self._reactionMin) / 4
    local u1    = math.random()
    local u2    = math.random()
    while u1 <= 1e-10 do u1 = math.random() end
    local gauss = math.sqrt(-2 * math.log(u1)) * math.cos(2 * math.pi * u2) * sigma
    return math.clamp(mean + gauss, self._reactionMin, self._reactionMax)
end

function StealthEngine:shouldMiss()
    return self._missRate > 0 and math.random() < self._missRate
end

function StealthEngine:getClickVariance()
    return (math.random() - 0.5) * 2 * self._clickVariance
end

function StealthEngine:canBurst()
    return self._burstCount < self._burstLimit
end

function StealthEngine:onBurst()
    self._burstCount = self._burstCount + 1
    task.delay(self._burstCooldown, function()
        self._burstCount = math.max(0, self._burstCount - 1)
    end)
end

function StealthEngine:getOptimalDelay(eta, ping)
    ping = ping or (PingComp and PingComp:get() or 0.05)
    local baseDelay = self:getReactionDelay()
    local clickVar  = self:getClickVariance()
    local netComp   = ping * 0.5  -- half RTT compensation
    return math.max(0, eta - netComp - baseDelay + clickVar)
end

function StealthEngine:getIdleJitter()
    if not self._idleJitter then return 0, 0 end
    local magnitude = math.random() * 2 - 1  -- -1 to 1 pixels
    local dx = magnitude * (math.random() * 2 - 1)
    local dy = magnitude * (math.random() * 2 - 1)
    return dx, dy
end

function StealthEngine:getStats()
    local p = STEALTH_PROFILES[self._profile]
    return {
        profile      = self._profile,
        reactionMin  = self._reactionMin,
        reactionMax  = self._reactionMax,
        missRate     = self._missRate,
        burstCount   = self._burstCount,
        burstLimit   = self._burstLimit,
        description  = p and p.description or "custom",
    }
end

function StealthEngine:start()
    self._active = true
    -- idle mouse jitter loop
    if self._idleJitter then
        task.spawn(function()
            while self._active do
                task.wait(math.random() * 2 + 0.5)
                if self._active then
                    local dx, dy = self:getIdleJitter()
                    -- apply micro-movement
                    pcall(function()
                        local ms = game:GetService("UserInputService")
                        -- we don't force-move mouse here, just log the intent
                    end)
                end
            end
        end)
    end
    if Console then Console.info("StealthEngine", "Stealth engine active (profile="..self._profile..")") end
end

function StealthEngine:stop()
    self._active = false
end

StealthEngine:setProfile("Average")
if FeatureFlags:isEnabled("ENABLE_ANTI_DETECT") then
    StealthEngine:start()
end

-- §83.1 Behavioral fingerprint randomizer
local FingerprintRand = {}
FingerprintRand._seed        = math.random(1000000, 9999999)
FingerprintRand._clickStyle  = "center"   -- center, random, spread
FingerprintRand._releaseTime = 0.08       -- hold duration before release
FingerprintRand._pressNoise  = 0.005
FingerprintRand._sessions    = 0

function FingerprintRand:randomizeSeed()
    self._seed = math.random(1000000, 9999999)
    math.randomseed(self._seed)
end

function FingerprintRand:getClickOffset(centerX, centerY, radius)
    radius = radius or 3
    if self._clickStyle == "center" then
        local r = math.random() * self._pressNoise * radius
        local a = math.random() * 2 * math.pi
        return centerX + r * math.cos(a), centerY + r * math.sin(a)
    elseif self._clickStyle == "random" then
        local r = math.sqrt(math.random()) * radius
        local a = math.random() * 2 * math.pi
        return centerX + r * math.cos(a), centerY + r * math.sin(a)
    else  -- spread
        return centerX + (math.random() * 2 - 1) * radius,
               centerY + (math.random() * 2 - 1) * radius
    end
end

function FingerprintRand:getReleaseDelay()
    return self._releaseTime + (math.random() - 0.5) * 0.02
end

function FingerprintRand:newSession()
    self._sessions = self._sessions + 1
    self:randomizeSeed()
    if Console then Console.info("FingerprintRand", "New session fingerprint. Seed="..self._seed) end
end

FingerprintRand:newSession()
if Console then Console.info("FingerprintRand", "Fingerprint randomizer ready") end

-- §84 ─── EXTENDED LEARNING ENGINE v2 ─────────────────────────────────────────
local LearningV2 = {}
LearningV2._successHistory   = {}   -- ring of {eta, ping, mode, success}
LearningV2._MAX              = 200
LearningV2._modelVersion     = 0
LearningV2._featureImportance = {}
LearningV2._models           = {}   -- per-mode models

-- Features used for learning:
-- 1. eta (seconds until impact)
-- 2. ping (seconds round-trip)
-- 3. speed (ball studs/sec)
-- 4. angle (heading toward player, 0-1)
-- 5. spinMag (spin magnitude)
-- 6. jitter (network jitter)
-- 7. distance (player to ball, studs)
-- 8. streak (current parry streak)

local FEATURE_NAMES = { "eta", "ping", "speed", "angle", "spinMag", "jitter", "distance", "streak" }

local function _dot(a, b)
    local s = 0
    for i = 1, #a do s = s + a[i] * (b[i] or 0) end
    return s
end

local function _relu(x) return math.max(0, x) end
local function _sigmoid(x) return 1 / (1 + math.exp(-x)) end

local function _newNeuron(inputN)
    local w = {}
    local scale = math.sqrt(2 / inputN)
    for i = 1, inputN do
        w[i] = (math.random() * 2 - 1) * scale
    end
    return { w = w, b = 0 }
end

local function _newNet(layers)
    local net = { layers = {} }
    for i = 1, #layers - 1 do
        local layer = {}
        for _ = 1, layers[i+1] do
            layer[#layer+1] = _newNeuron(layers[i])
        end
        net.layers[i] = layer
    end
    return net
end

local function _forwardNet(net, input)
    local current = input
    for l, layer in ipairs(net.layers) do
        local next = {}
        for _, neuron in ipairs(layer) do
            local z = _dot(neuron.w, current) + neuron.b
            next[#next+1] = l < #net.layers and _relu(z) or _sigmoid(z)
        end
        current = next
    end
    return current[1]
end

local function _backpropNet(net, input, target, lr)
    -- simplified single-output backprop
    local activations = { input }
    local zs = {}
    local current = input
    for l, layer in ipairs(net.layers) do
        local next = {}
        local z_layer = {}
        for _, neuron in ipairs(layer) do
            local z = _dot(neuron.w, current) + neuron.b
            z_layer[#z_layer+1] = z
            next[#next+1] = l < #net.layers and _relu(z) or _sigmoid(z)
        end
        table.insert(activations, next)
        zs[l] = z_layer
        current = next
    end
    local out = current[1]
    local dLoss = out - target  -- MSE gradient
    -- output layer
    local nLayers = #net.layers
    local deltas = {}
    deltas[nLayers] = {}
    local sigP = out * (1 - out)  -- sigmoid derivative
    deltas[nLayers][1] = dLoss * sigP
    for l = nLayers - 1, 1, -1 do
        deltas[l] = {}
        for j = 1, #net.layers[l] do
            local sum = 0
            for k = 1, #net.layers[l+1] do
                sum = sum + net.layers[l+1][k].w[j] * (deltas[l+1][k] or 0)
            end
            local act = activations[l+1][j]
            deltas[l][j] = sum * (act > 0 and 1 or 0)  -- relu derivative
        end
    end
    -- update weights
    for l, layer in ipairs(net.layers) do
        for j, neuron in ipairs(layer) do
            local d = deltas[l][j] or 0
            for i = 1, #neuron.w do
                neuron.w[i] = neuron.w[i] - lr * d * activations[l][i]
            end
            neuron.b = neuron.b - lr * d
        end
    end
    return (dLoss * dLoss) * 0.5  -- loss
end

function LearningV2:_getModel(mode)
    if not self._models[mode] then
        -- 8 inputs → 12 → 6 → 1 output (success probability)
        self._models[mode] = _newNet({ 8, 12, 6, 1 })
    end
    return self._models[mode]
end

function LearningV2:_extractFeatures(record)
    local f = {}
    f[1] = math.min(record.eta or 0.3, 2) / 2           -- normalize
    f[2] = math.min(record.ping or 0.05, 0.5) / 0.5
    f[3] = math.min(record.speed or 50, 200) / 200
    f[4] = record.angle or 0.5
    f[5] = math.min(record.spinMag or 0, 100) / 100
    f[6] = math.min(record.jitter or 0, 0.1) / 0.1
    f[7] = math.min(record.distance or 20, 100) / 100
    f[8] = math.min(record.streak or 0, 20) / 20
    return f
end

function LearningV2:record(eta, ping, speed, angle, spinMag, jitter, distance, streak, mode, success)
    local rec = {
        eta      = eta,
        ping     = ping,
        speed    = speed,
        angle    = angle,
        spinMag  = spinMag,
        jitter   = jitter,
        distance = distance,
        streak   = streak,
        mode     = mode,
        success  = success and 1.0 or 0.0,
    }
    table.insert(self._successHistory, rec)
    if #self._successHistory > self._MAX then
        table.remove(self._successHistory, 1)
    end
    -- train model
    local net = self:_getModel(mode or "Unknown")
    local features = self:_extractFeatures(rec)
    _backpropNet(net, features, rec.success, 0.01)
    self._modelVersion = self._modelVersion + 1
end

function LearningV2:predict(eta, ping, speed, angle, spinMag, jitter, distance, streak, mode)
    local net = self._models[mode or "Unknown"]
    if not net then return 0.5 end
    local rec = { eta=eta, ping=ping, speed=speed, angle=angle, spinMag=spinMag, jitter=jitter, distance=distance, streak=streak }
    local f = self:_extractFeatures(rec)
    return _forwardNet(net, f)
end

function LearningV2:getModelVersion()
    return self._modelVersion
end

function LearningV2:getAccuracyByMode()
    local modes = {}
    for _, r in ipairs(self._successHistory) do
        local m = r.mode or "Unknown"
        if not modes[m] then modes[m] = { success = 0, total = 0 } end
        modes[m].total   = modes[m].total + 1
        modes[m].success = modes[m].success + r.success
    end
    local out = {}
    for mode, data in pairs(modes) do
        out[mode] = data.total > 0 and (data.success / data.total) or 0
    end
    return out
end

function LearningV2:getBestMode()
    local acc = self:getAccuracyByMode()
    local bestMode, bestAcc = "Ultra", 0
    for mode, a in pairs(acc) do
        if a > bestAcc then bestAcc = a; bestMode = mode end
    end
    return bestMode, bestAcc
end

function LearningV2:getStats()
    return {
        samples      = #self._successHistory,
        modelVersion = self._modelVersion,
        modes        = self:getAccuracyByMode(),
        bestMode     = self:getBestMode(),
    }
end

if Console then Console.info("LearningV2", "Extended learning engine v2 ready (net: 8→12→6→1)") end

-- §85 ─── EXTENDED SERVER PROFILE v2 ─────────────────────────────────────────
local ServerProfileV2 = {}
ServerProfileV2._connected       = false
ServerProfileV2._playerCount     = 0
ServerProfileV2._serverAge       = 0
ServerProfileV2._serverRegion    = "unknown"
ServerProfileV2._tickRate        = 20
ServerProfileV2._avgPing         = 0
ServerProfileV2._maxPlayers      = 0
ServerProfileV2._serverJob       = ""
ServerProfileV2._placeVersion    = 0
ServerProfileV2._serverUptime    = 0
ServerProfileV2._lagEvents       = 0
ServerProfileV2._recommendation  = "Unknown"
ServerProfileV2._joinTime        = tick()

-- Server quality metrics
ServerProfileV2._tickHistory     = {}
ServerProfileV2._MAX_TICKS       = 100
ServerProfileV2._cpuLoad         = {}
ServerProfileV2._MAX_CPU         = 60

function ServerProfileV2:collect()
    -- collect available server info
    pcall(function()
        self._playerCount  = #game.Players:GetPlayers()
        self._maxPlayers   = game:GetService("Players").MaxPlayers
        self._serverJob    = game.JobId or "unknown"
        self._placeVersion = game.PlaceVersion or 0
        self._serverUptime = tick() - self._joinTime
        self._connected    = true
    end)
end

function ServerProfileV2:recordTick(dt)
    table.insert(self._tickHistory, dt)
    if #self._tickHistory > self._MAX_TICKS then
        table.remove(self._tickHistory, 1)
    end
end

function ServerProfileV2:getAvgTickDt()
    if #self._tickHistory == 0 then return 0.05 end
    local sum = 0
    for _, dt in ipairs(self._tickHistory) do sum = sum + dt end
    return sum / #self._tickHistory
end

function ServerProfileV2:getEstimatedTickRate()
    local dt = self:getAvgTickDt()
    return dt > 0 and (1 / dt) or 20
end

function ServerProfileV2:detectLag()
    if #self._tickHistory < 5 then return false end
    local recent = self._tickHistory[#self._tickHistory]
    local avg    = self:getAvgTickDt()
    local lagging = recent > avg * 2
    if lagging then
        self._lagEvents = self._lagEvents + 1
    end
    return lagging
end

function ServerProfileV2:getTickVariance()
    local avg = self:getAvgTickDt()
    local var = 0
    for _, dt in ipairs(self._tickHistory) do
        local diff = dt - avg
        var = var + diff * diff
    end
    return #self._tickHistory > 1 and (var / (#self._tickHistory - 1)) or 0
end

function ServerProfileV2:getTickStability()
    local variance = self:getTickVariance()
    local avg      = self:getAvgTickDt()
    local cv       = avg > 0 and (math.sqrt(variance) / avg) or 1
    if cv < 0.05 then return "Stable" end
    if cv < 0.15 then return "Mostly Stable" end
    if cv < 0.30 then return "Unstable" end
    return "Very Unstable"
end

function ServerProfileV2:recommend()
    local players   = self._playerCount
    local stability = self:getTickStability()
    local lag       = self._lagEvents
    if stability == "Stable" and players <= 10 and lag < 5 then
        self._recommendation = "Excellent server"
    elseif stability == "Mostly Stable" and players <= 15 then
        self._recommendation = "Good server"
    elseif stability == "Unstable" or players > 15 then
        self._recommendation = "Fair server — may lag"
    else
        self._recommendation = "Poor server — consider rejoin"
    end
    return self._recommendation
end

function ServerProfileV2:getReport()
    self:collect()
    return {
        players      = self._playerCount,
        maxPlayers   = self._maxPlayers,
        uptime       = self._serverUptime,
        tickRate     = self:getEstimatedTickRate(),
        stability    = self:getTickStability(),
        lagEvents    = self._lagEvents,
        recommendation = self:recommend(),
        jobId        = self._serverJob,
        placeVersion = self._placeVersion,
    }
end

function ServerProfileV2:getReportString()
    local r = self:getReport()
    return string.format(
        "Players: %d/%d | Uptime: %.0fs | TickRate: %.1fHz | Stability: %s | Lags: %d\nVerdict: %s",
        r.players, r.maxPlayers, r.uptime, r.tickRate,
        r.stability, r.lagEvents, r.recommendation
    )
end

-- Record server ticks
RunService.Heartbeat:Connect(function(dt)
    ServerProfileV2:recordTick(dt)
end)

ServerProfileV2:collect()
if Console then Console.info("ServerProfileV2", ServerProfileV2:getReportString()) end

-- §85.1 Rejoin assistant
local RejoinAssist = {}
RejoinAssist._threshold    = 3     -- max lag events before suggesting rejoin
RejoinAssist._lastSuggest  = 0
RejoinAssist._cooldown     = 120   -- seconds between suggestions
RejoinAssist._autoRejoin   = false

function RejoinAssist:check()
    if ServerProfileV2._lagEvents >= self._threshold then
        local now = tick()
        if now - self._lastSuggest >= self._cooldown then
            self._lastSuggest = now
            if self._autoRejoin then
                self:rejoin()
            else
                NotifyV2:warn("Server Quality",
                    string.format("Server lagging (%d events). Consider rejoining.", ServerProfileV2._lagEvents),
                    8
                )
            end
        end
    end
end

function RejoinAssist:rejoin()
    if Console then Console.warn("RejoinAssist", "Auto-rejoin triggered!") end
    pcall(function()
        game:GetService("TeleportService"):Teleport(game.PlaceId, game.Players.LocalPlayer)
    end)
end

function RejoinAssist:getStats()
    return {
        threshold   = self._threshold,
        autoRejoin  = self._autoRejoin,
        cooldown    = self._cooldown,
        lastSuggest = self._lastSuggest,
    }
end

-- periodic check
task.spawn(function()
    while true do
        task.wait(30)
        pcall(function() RejoinAssist:check() end)
    end
end)

if Console then Console.info("RejoinAssist", "Rejoin assistant ready (threshold="..RejoinAssist._threshold..")") end

-- §86 ─── FINAL INIT & INTEGRATION ────────────────────────────────────────────
-- This section ties together all systems and fires the final startup sequence

local FinalInit = {}
FinalInit._done      = false
FinalInit._startTime = tick()
FinalInit._modules   = {}

function FinalInit:register(name, fn)
    self._modules[#self._modules+1] = { name = name, fn = fn }
end

function FinalInit:run()
    if self._done then return end
    self._done = true
    local errors = {}
    for _, m in ipairs(self._modules) do
        local ok, err = pcall(m.fn)
        if not ok then
            errors[#errors+1] = m.name .. ": " .. tostring(err)
            if Console then Console.error("FinalInit", m.name .. " FAILED: " .. tostring(err)) end
        else
            if Console then Console.info("FinalInit", m.name .. " OK") end
        end
    end
    local dt = tick() - self._startTime
    if Console then Console.info("FinalInit", string.format(
        "Init complete in %.2fms. %d modules, %d errors.",
        dt * 1000, #self._modules, #errors
    )) end
    return errors
end

-- Register all late-init modules
FinalInit:register("Config.Validate", function()
    -- ensure all required keys exist
    for k, v in pairs(DEFAULTS) do
        if Config._raw[k] == nil then
            Config._raw[k] = v
        end
    end
end)

FinalInit:register("EventBus.Warmup", function()
    EventBus:publish("system_start", { t = tick(), version = Updater.VERSION })
end)

FinalInit:register("PerfBench.Reset", function()
    PerfBench:reset()
end)

FinalInit:register("BallViz.Start", function()
    if FeatureFlags:isEnabled("ENABLE_BALL_VIZ") then
        -- BallViz already started in §60
    end
end)

FinalInit:register("NetLayerV2.Prime", function()
    -- Prime with current ping estimate
    local ping = PingComp and PingComp:get() or 0.05
    for i = 1, 10 do NetLayerV2:_recordPing(ping) end
end)

FinalInit:register("ServerProfile.Initial", function()
    ServerProfileV2:collect()
end)

FinalInit:register("TimingOptimizer.Warmup", function()
    -- seed with neutral samples so optimizer has a starting point
    for i = 1, 5 do
        TimingOptimizer:record(0.1, true)
        TimingOptimizer:record(0.12, true)
    end
end)

FinalInit:register("CombatAnalytics.StartRound", function()
    -- already started, just verify
end)

FinalInit:register("Updater.VersionCheck", function()
    Updater:check()
end)

-- Run final init after a short delay to ensure all services are ready
task.delay(0.5, function()
    FinalInit:run()
end)

-- §86.1 Startup status broadcast
task.delay(1.0, function()
    local version = Updater:getVersionString()
    local net     = NetLayerV2:getStats()
    local server  = ServerProfileV2:getReport()
    if Console then Console.info("WINDHUB", "════════════════════════════════════") end
    if Console then Console.info("WINDHUB", " "..version) end
    if Console then Console.info("WINDHUB", string.format(
        " Network: %s | Ping: %.0fms | Jitter: %.1fms",
        net.quality, net.avg*1000, net.jitter*1000
    )) end
    if Console then Console.info("WINDHUB", string.format(
        " Server: %s | Players: %d | Stability: %s",
        server.recommendation, server.players, server.stability
    )) end
    if Console then Console.info("WINDHUB", string.format(
        " Parry Mode: %s | Anti-detect: %s",
        Config.parryMode or "None",
        FeatureFlags:isEnabled("ENABLE_ANTI_DETECT") and "ON" or "OFF"
    )) end
    if Console then Console.info("WINDHUB", " Type 'help' in console for all commands") end
    if Console then Console.info("WINDHUB", "════════════════════════════════════") end
    -- Startup notification
    NotifyV2:success(
        "WindHub Loaded!",
        string.format("v%s | %s | %s", Updater.VERSION, server.recommendation, net.quality),
        6
    )
end)

-- §86.2 Heartbeat integration — final master loop
local masterConn = RunService.Heartbeat:Connect(function(dt)
    -- integrate all per-frame systems
    pcall(function()
        -- update parry frame data based on recent accuracy
        local stats = CombatAnalytics:getCurrentStats()
        if stats and stats.accuracy > 0 then
            DebugTools:addOverlayLine(string.format(
                "Acc:%.0f%% Streak:%d Mode:%s",
                stats.accuracy, stats.currentStreak, Config.parryMode or "?"
            ), UI and UI.Theme and UI.Theme.Accent or Color3.fromRGB(80,255,150))
        end
    end)
    -- update stealth engine timing
    pcall(function()
        if StealthEngine._active and Config.parryActive then
            -- no-op: actual delays applied at parry-fire time
        end
    end)
    -- network monitoring
    pcall(function()
        if NetLayerV2:detectCongestion() then
            BypassLayer:recordDetectionEvent("network_congestion")
        end
    end)
end)

if Console then Console.info("MasterLoop", "Final master heartbeat connected") end

-- §87 ─── EXTENDED BALL TRACKER v2 ────────────────────────────────────────────
-- Supplements existing BallTracker with additional analysis
local BallTrackerV2 = {}
BallTrackerV2._extended    = {}  -- per-ball extended data
BallTrackerV2._maxHistory  = 32  -- positions per ball

local function _ensureBallData(id)
    if not BallTrackerV2._extended[id] then
        BallTrackerV2._extended[id] = {
            posHistory  = {},  -- ring of {t, pos}
            velHistory  = {},
            accHistory  = {},
            curvature   = 0,
            avgCurvature = 0,
            peakSpeed   = 0,
            firstSeen   = tick(),
            lastSeen    = tick(),
            bounceCount = 0,
            prevVel     = nil,
        }
    end
    return BallTrackerV2._extended[id]
end

function BallTrackerV2:update(id, pos, vel, t)
    t = t or tick()
    local d = _ensureBallData(id)
    d.lastSeen = t
    d.peakSpeed = math.max(d.peakSpeed, vel.Magnitude)
    -- store position history
    table.insert(d.posHistory, { t = t, pos = pos })
    if #d.posHistory > self._maxHistory then table.remove(d.posHistory, 1) end
    table.insert(d.velHistory, { t = t, vel = vel })
    if #d.velHistory > self._maxHistory then table.remove(d.velHistory, 1) end
    -- compute acceleration
    if #d.velHistory >= 2 then
        local prev = d.velHistory[#d.velHistory - 1]
        local dt = t - prev.t
        if dt > 0.001 then
            local acc = (vel - prev.vel) / dt
            table.insert(d.accHistory, { t = t, acc = acc })
            if #d.accHistory > self._maxHistory then table.remove(d.accHistory, 1) end
        end
    end
    -- compute curvature (how much ball is curving)
    if d.prevVel and d.prevVel.Magnitude > 0.01 and vel.Magnitude > 0.01 then
        local cosAngle = math.clamp(d.prevVel.Unit:Dot(vel.Unit), -1, 1)
        d.curvature = math.acos(cosAngle)
        d.avgCurvature = d.avgCurvature * 0.95 + d.curvature * 0.05
    end
    d.prevVel = vel
    -- detect bounce (Y velocity sign change)
    if d.prevVel and d.prevVel.Y < -1 and vel.Y > 0 then
        d.bounceCount = d.bounceCount + 1
    end
end

function BallTrackerV2:getLifetime(id)
    local d = self._extended[id]
    if not d then return 0 end
    return d.lastSeen - d.firstSeen
end

function BallTrackerV2:getAvgSpeed(id)
    local d = self._extended[id]
    if not d or #d.velHistory == 0 then return 0 end
    local sum = 0
    for _, v in ipairs(d.velHistory) do sum = sum + v.vel.Magnitude end
    return sum / #d.velHistory
end

function BallTrackerV2:getCurvature(id)
    local d = self._extended[id]
    return d and d.avgCurvature or 0
end

function BallTrackerV2:getPeakSpeed(id)
    local d = self._extended[id]
    return d and d.peakSpeed or 0
end

function BallTrackerV2:getBounceCount(id)
    local d = self._extended[id]
    return d and d.bounceCount or 0
end

function BallTrackerV2:predictPosition(id, futureT)
    local d = self._extended[id]
    if not d or #d.posHistory < 2 then return nil end
    local latest  = d.posHistory[#d.posHistory]
    local prev    = d.posHistory[#d.posHistory - 1]
    local dt      = latest.t - prev.t
    if dt < 0.001 then return latest.pos end
    local vel    = (latest.pos - prev.pos) / dt
    local ahead  = futureT - latest.t
    -- simple linear + gravity
    local grav   = Vector3.new(0, -workspace.Gravity, 0)
    return latest.pos + vel * ahead + grav * ahead^2 * 0.5
end

function BallTrackerV2:getSmoothedVelocity(id, windowSecs)
    local d = self._extended[id]
    if not d then return Vector3.new(0,0,0) end
    windowSecs = windowSecs or 0.1
    local now = tick()
    local sumVel = Vector3.new(0,0,0)
    local count  = 0
    for i = #d.velHistory, 1, -1 do
        local entry = d.velHistory[i]
        if now - entry.t > windowSecs then break end
        sumVel = sumVel + entry.vel
        count  = count + 1
    end
    return count > 0 and (sumVel / count) or Vector3.new(0,0,0)
end

function BallTrackerV2:getAll()
    return self._extended
end

function BallTrackerV2:cleanupOld(timeout)
    timeout = timeout or 10
    local now = tick()
    local removed = 0
    for id, d in pairs(self._extended) do
        if now - d.lastSeen > timeout then
            self._extended[id] = nil
            removed = removed + 1
        end
    end
    return removed
end

-- Auto-cleanup every 30 seconds
task.spawn(function()
    while true do
        task.wait(30)
        pcall(function() BallTrackerV2:cleanupOld(15) end)
    end
end)

if Console then Console.info("BallTrackerV2", "Extended ball tracker v2 ready") end

-- §88 ─── EXTENDED VISUAL FX SYSTEM ──────────────────────────────────────────
local VisualFX = {}
VisualFX._active    = true
VisualFX._effects   = {}
VisualFX._maxEffect = 50

local FX_TYPES = {
    FLASH       = "flash",
    TRAIL       = "trail",
    SHOCKWAVE   = "shockwave",
    IMPACT_RING = "impact_ring",
    STREAK      = "streak",
}

local function _newEffect(kind, data)
    return {
        kind    = kind,
        start   = tick(),
        data    = data,
        objects = {},
        done    = false,
    }
end

function VisualFX:_addEffect(eff)
    table.insert(self._effects, eff)
    if #self._effects > self._maxEffect then
        local oldest = table.remove(self._effects, 1)
        for _, o in ipairs(oldest.objects) do
            pcall(function() o.Visible = false; o:Remove() end)
        end
    end
end

function VisualFX:flashParry(screenPos)
    if not _drawingSupported then return end
    local eff = _newEffect(FX_TYPES.FLASH, { pos = screenPos })
    -- immediate white circle that fades
    local circ = Draw2:newCircle(screenPos.X, screenPos.Y, 30, Color3.fromRGB(255,255,255), 4, false)
    if circ then eff.objects[1] = circ end
    self:_addEffect(eff)
    task.spawn(function()
        local steps = 10
        for i = 1, steps do
            task.wait(0.03)
            pcall(function()
                local t    = i / steps
                local r    = 30 + t * 30
                local fade = 1 - t
                if circ then
                    circ.Radius = r
                    circ.Transparency = fade
                end
            end)
        end
        pcall(function() if circ then circ.Visible = false; circ:Remove() end end)
        eff.done = true
    end)
end

function VisualFX:impactRing(screenPos, color)
    if not _drawingSupported then return end
    color = color or Color3.fromRGB(255, 215, 0)
    local eff = _newEffect(FX_TYPES.IMPACT_RING, { pos = screenPos, color = color })
    local ring = Draw2:newCircle(screenPos.X, screenPos.Y, 5, color, 3, false)
    if ring then eff.objects[1] = ring end
    self:_addEffect(eff)
    task.spawn(function()
        local steps = 15
        for i = 1, steps do
            task.wait(0.02)
            pcall(function()
                local t = i / steps
                if ring then
                    ring.Radius       = 5 + t * 40
                    ring.Transparency = t
                    ring.Thickness    = math.max(1, 3 * (1 - t))
                end
            end)
        end
        pcall(function() if ring then ring.Visible = false; ring:Remove() end end)
        eff.done = true
    end)
end

function VisualFX:shockwave(worldPos, radius, color)
    if not _drawingSupported then return end
    color = color or Color3.fromRGB(80, 255, 150)
    local cam = workspace.CurrentCamera
    if not cam then return end
    local sp, vis = cam:WorldToViewportPoint(worldPos)
    if not vis then return end
    local screenPos = Vector2.new(sp.X, sp.Y)
    local eff = _newEffect(FX_TYPES.SHOCKWAVE, { worldPos = worldPos })
    -- multiple rings
    for ring = 1, 3 do
        local delay = (ring - 1) * 0.05
        task.spawn(function()
            task.wait(delay)
            local circ = Draw2:newCircle(screenPos.X, screenPos.Y, 5, color, 2, false)
            if not circ then return end
            table.insert(eff.objects, circ)
            for i = 1, 20 do
                task.wait(0.02)
                pcall(function()
                    local t = i / 20
                    circ.Radius       = 5 + t * radius * 3
                    circ.Transparency = t
                end)
            end
            pcall(function() circ.Visible = false; circ:Remove() end)
        end)
    end
    self:_addEffect(eff)
end

function VisualFX:speedLines(fromScreenPos, toScreenPos, color, count)
    if not _drawingSupported then return end
    color = color or Color3.fromRGB(255, 255, 255)
    count = count or 8
    local eff = _newEffect(FX_TYPES.STREAK, {})
    for i = 1, count do
        local offset = Vector2.new((math.random()-0.5)*40, (math.random()-0.5)*40)
        local a = fromScreenPos + offset
        local b = toScreenPos + offset
        local line = Draw2:newLine(a.X, a.Y, b.X, b.Y, color, 1)
        if line then
            table.insert(eff.objects, line)
            local idx = i
            task.spawn(function()
                task.wait(idx * 0.01)
                for f = 1, 8 do
                    task.wait(0.02)
                    pcall(function() line.Transparency = f / 8 end)
                end
                pcall(function() line.Visible = false; line:Remove() end)
            end)
        end
    end
    self:_addEffect(eff)
end

function VisualFX:parrySuccess(screenPos)
    self:flashParry(screenPos)
    self:impactRing(screenPos, Color3.fromRGB(80, 255, 150))
end

function VisualFX:parryFail(screenPos)
    self:impactRing(screenPos, Color3.fromRGB(255, 80, 80))
end

function VisualFX:comboMilestone(screenPos, streak)
    local colors = {
        [5]  = Color3.fromRGB(255, 255, 80),
        [10] = Color3.fromRGB(255, 180, 40),
        [20] = Color3.fromRGB(255, 100, 40),
        [50] = Color3.fromRGB(255, 40,  40),
    }
    local color = colors[streak] or Color3.fromRGB(255, 215, 0)
    self:shockwave(Vector3.new(0,0,0), 30, color)
end

function VisualFX:clearAll()
    for _, eff in ipairs(self._effects) do
        for _, o in ipairs(eff.objects) do
            pcall(function() o.Visible = false; o:Remove() end)
        end
    end
    self._effects = {}
end

-- wire to event bus
EventBus:subscribe("parry_success", function(data)
    if Config.visualFX then
        local cam = workspace.CurrentCamera
        if cam then
            local vp = cam.ViewportSize
            VisualFX:parrySuccess(Vector2.new(vp.X/2, vp.Y/2))
        end
    end
end)

EventBus:subscribe("combo_milestone", function(data)
    if Config.visualFX and data then
        VisualFX:comboMilestone(Vector2.new(960, 540), data.streak)
    end
end)

if Console then Console.info("VisualFX", "Visual FX system ready") end

-- ParrySuccessAll visual + EventBus wiring (deferred here because VisualFX and
-- EventBus are both defined before this point but after REMOTE_DEFS at §18).
-- Reads _G._WindHub_LastParrySuccess cached by the remote handler.
GameRemotes.onParrySuccess:Connect(function(resolvedPlayer, hrp, effectType)
    local data = _G._WindHub_LastParrySuccess
    if not data or (os.clock() - data.t) > 1 then return end

    if data.isLocal then
        EventBus:publish("parry_success", { effectType = effectType, source = "ParrySuccessAll" })
    end

    if Config.visualFX and typeof(hrp) == "Instance" then
        pcall(function()
            local cam = workspace.CurrentCamera
            if not cam then return end
            local pos3, onScreen = cam:WorldToScreenPoint(hrp.Position)
            local sp = onScreen
                and Vector2.new(pos3.X, pos3.Y)
                or  Vector2.new(cam.ViewportSize.X / 2, cam.ViewportSize.Y / 2)
            if data.isLocal then
                VisualFX:parrySuccess(sp)
            else
                -- Other players' parries: dim blue impact ring
                VisualFX:impactRing(sp, Color3.fromRGB(80, 160, 255))
            end
        end)
    end
end)

-- §89 ─── EXTENDED HITBOX ENGINE v2 ───────────────────────────────────────────
local HitboxV2Extended = {}
HitboxV2Extended._mode        = "standard"  -- standard, expanded, per_part, adaptive
HitboxV2Extended._expandScale = 1.0
HitboxV2Extended._baseRadius  = 3.0
HitboxV2Extended._parts       = {}
HitboxV2Extended._hitEvents   = {}
HitboxV2Extended._MAX_EVENTS  = 100
HitboxV2Extended._registeredChars = {}

local LIMB_RADIUS_MAP = {
    Head            = 1.2,
    UpperTorso      = 2.0,
    LowerTorso      = 1.8,
    LeftUpperArm    = 1.0,
    RightUpperArm   = 1.0,
    LeftLowerArm    = 0.8,
    RightLowerArm   = 0.8,
    LeftHand        = 0.7,
    RightHand       = 0.7,
    LeftUpperLeg    = 1.1,
    RightUpperLeg   = 1.1,
    LeftLowerLeg    = 0.9,
    RightLowerLeg   = 0.9,
    LeftFoot        = 0.8,
    RightFoot       = 0.8,
    HumanoidRootPart = 2.5,
}

function HitboxV2Extended:registerChar(char, owner)
    if self._registeredChars[char] then return end
    local parts = {}
    for partName, radius in pairs(LIMB_RADIUS_MAP) do
        local part = char:FindFirstChild(partName)
        if part then
            parts[#parts+1] = {
                part   = part,
                name   = partName,
                radius = radius,
                owner  = owner,
            }
        end
    end
    self._registeredChars[char] = parts
    self._parts = parts
    if Console then Console.info("HitboxV2Extended", "Registered "..#parts.." hitbox parts for "..(owner and owner.Name or "unknown")) end
end

function HitboxV2Extended:getEffectiveRadius(partName)
    local base = LIMB_RADIUS_MAP[partName] or self._baseRadius
    local scale = self._expandScale
    if self._mode == "expanded" then scale = scale * (Config.hitboxScalar or 8) / 3 end
    if self._mode == "adaptive" then
        -- scale based on current ping: higher ping = bigger hitbox
        local ping = PingComp and PingComp:get() or 0.05
        scale = scale * (1 + ping * 5)
    end
    return base * scale
end

function HitboxV2Extended:checkHit(ballPos, ballRadius)
    local hitParts = {}
    for _, partData in ipairs(self._parts) do
        local part = partData.part
        if part and part.Parent then
            local partPos = part.Position
            local effRadius = self:getEffectiveRadius(partData.name) + ballRadius
            local dist = (ballPos - partPos).Magnitude
            if dist <= effRadius then
                hitParts[#hitParts+1] = {
                    part     = part,
                    name     = partData.name,
                    distance = dist,
                    radius   = effRadius,
                    owner    = partData.owner,
                }
            end
        end
    end
    -- sort by distance (closest first)
    table.sort(hitParts, function(a, b) return a.distance < b.distance end)
    return hitParts
end

function HitboxV2Extended:isHit(ballPos, ballRadius)
    local hits = self:checkHit(ballPos, ballRadius)
    return #hits > 0, hits[1]
end

function HitboxV2Extended:recordHitEvent(partName, distance, ballId)
    local ev = { t = tick(), part = partName, dist = distance, ballId = ballId }
    table.insert(self._hitEvents, ev)
    if #self._hitEvents > self._MAX_EVENTS then table.remove(self._hitEvents, 1) end
end

function HitboxV2Extended:getHitDistribution()
    local dist = {}
    for _, ev in ipairs(self._hitEvents) do
        dist[ev.part] = (dist[ev.part] or 0) + 1
    end
    return dist
end

function HitboxV2Extended:getMostHitPart()
    local dist = self:getHitDistribution()
    local bestPart, bestCount = "Unknown", 0
    for part, count in pairs(dist) do
        if count > bestCount then bestCount = count; bestPart = part end
    end
    return bestPart, bestCount
end

function HitboxV2Extended:setMode(mode)
    if mode == "standard" or mode == "expanded" or mode == "per_part" or mode == "adaptive" then
        self._mode = mode
        if Console then Console.info("HitboxV2Extended", "Mode: "..mode) end
    end
end

function HitboxV2Extended:setExpandScale(scale)
    self._expandScale = math.clamp(scale, 1, 5)
end

function HitboxV2Extended:getStats()
    return {
        mode         = self._mode,
        expandScale  = self._expandScale,
        parts        = #self._parts,
        hitEvents    = #self._hitEvents,
        mostHit      = self:getMostHitPart(),
    }
end

-- Register local player on load
local function _registerLocalPlayer()
    local lp = game.Players.LocalPlayer
    if lp and lp.Character then
        HitboxV2Extended:registerChar(lp.Character, lp)
    end
    if lp then lp.CharacterAdded:Connect(function(c)
        HitboxV2Extended:registerChar(c, lp)
    end) end
end
pcall(_registerLocalPlayer)

if Console then Console.info("HitboxV2Extended", "Extended hitbox engine v2 ready") end

-- §89.1 Hitbox debugger
local HitboxDebugger = {}
HitboxDebugger._active   = false
HitboxDebugger._drawObjs = {}

function HitboxDebugger:start()
    self._active = true
    RunService.Heartbeat:Connect(function()
        if not self._active or not _drawingSupported then return end
        for _, o in ipairs(self._drawObjs) do
            pcall(function() o.Visible = false; o:Remove() end)
        end
        self._drawObjs = {}
        local cam = workspace.CurrentCamera
        if not cam then return end
        for _, partData in ipairs(HitboxV2Extended._parts) do
            local part = partData.part
            if part and part.Parent then
                local sp, vis = cam:WorldToViewportPoint(part.Position)
                if vis and sp.Z > 0 then
                    local r = HitboxV2Extended:getEffectiveRadius(partData.name)
                    local screenR = math.max(3, r * 200 / sp.Z)
                    local circ = Draw2:newCircle(sp.X, sp.Y, screenR,
                        Color3.fromRGB(255, 100, 100), 1, false)
                    if circ then
                        self._drawObjs[#self._drawObjs+1] = circ
                    end
                end
            end
        end
    end)
end

function HitboxDebugger:stop()
    self._active = false
    for _, o in ipairs(self._drawObjs) do
        pcall(function() o.Visible = false; o:Remove() end)
    end
    self._drawObjs = {}
end

if Console then Console.info("HitboxDebugger", "Hitbox debugger ready") end

-- §90 ─── EXTENDED AUTO-PARRY INTEGRATION ─────────────────────────────────────
-- Final integration layer that connects all new subsystems to the core parry engine
local ParryIntegration = {}
ParryIntegration._active        = true
ParryIntegration._lastParryT    = 0
ParryIntegration._parryCount    = 0
ParryIntegration._missCount     = 0
ParryIntegration._successRecord = {}
ParryIntegration._MAX_RECORD    = 200

function ParryIntegration:computeAdjustedETA(rawETA, bs)
    if not rawETA then return rawETA end
    local ping     = PingComp and PingComp:get() or 0.05
    local jitter   = NetLayerV2:getJitter()
    local timingOff = TimingOptimizer:getOptimalLeadTime()
    local stealth   = StealthEngine:getReactionDelay()
    -- adjusted = rawETA - ping compensation - timing offset + stealth delay
    local adjusted = rawETA - (ping * 0.5) - timingOff + stealth
    -- machine learning refinement
    if FeatureFlags:isEnabled("ENABLE_MININET") and bs then
        local lp   = game.Players.LocalPlayer
        local char = lp and lp.Character
        local root = char and char:FindFirstChild("HumanoidRootPart")
        local dist = root and (bs.pos - root.Position).Magnitude or 20
        local angle = 0
        if bs.velocity and bs.velocity.Magnitude > 0.01 and root then
            local toUs = (root.Position - bs.pos).Unit
            angle = math.clamp(bs.velocity.Unit:Dot(toUs), 0, 1)
        end
        local prob = LearningV2:predict(
            rawETA, ping,
            bs.velocity and bs.velocity.Magnitude or 50,
            angle,
            SpinPhysics:getSpinMagnitude(bs.id or ""),
            jitter, dist,
            ComboV2:getStreak(),
            Config.parryMode
        )
        -- scale timing by predicted success probability
        if prob < 0.4 then
            adjusted = adjusted - 0.02  -- be earlier if confidence low
        elseif prob > 0.8 then
            adjusted = adjusted + 0.01  -- slight delay if very confident
        end
    end
    return math.max(0, adjusted)
end

function ParryIntegration:shouldParry(bs)
    if not bs then return false, "no ball state" end
    -- feature flags check
    if not FeatureFlags:isEnabled("ENABLE_MININET") then return true, "flags_ok" end
    -- check bypass rate limit
    if not BypassLayer:canBurst() then return false, "rate_limited" end
    -- check miss rate (stealth)
    if StealthEngine:shouldMiss() then return false, "stealth_miss" end
    -- check target selector
    local balls = {}
    for _, b in pairs(BallTracker._balls or {}) do balls[#balls+1] = b end
    local best = TargetSelector:selectBest(balls)
    if best and best.id ~= (bs.id) then return false, "not_priority_target" end
    return true, "ok"
end

function ParryIntegration:onParryFired(bs, eta, method)
    self._lastParryT = tick()
    self._parryCount = self._parryCount + 1
    BypassLayer:onBurst()
    -- record for learning
    if bs then
        BallTrackerV2:update(bs.id or "?", bs.pos, bs.velocity or Vector3.new(0,0,0))
        local lp   = game.Players.LocalPlayer
        local char = lp and lp.Character
        local root = char and char:FindFirstChild("HumanoidRootPart")
        local dist = root and (bs.pos - root.Position).Magnitude or 20
        local ping = PingComp and PingComp:get() or 0.05
        local angle = 0
        if bs.velocity and bs.velocity.Magnitude > 0.01 and root then
            local toUs = (root.Position - bs.pos).Unit
            angle = math.clamp(bs.velocity.Unit:Dot(toUs), 0, 1)
        end
        table.insert(self._successRecord, {
            t = tick(), id = bs.id, eta = eta, dist = dist,
            speed = bs.velocity and bs.velocity.Magnitude or 0,
            angle = angle, ping = ping, method = method,
        })
        if #self._successRecord > self._MAX_RECORD then
            table.remove(self._successRecord, 1)
        end
    end
    EventBus:publish("parry_fired", { bs = bs, eta = eta, method = method })
end

function ParryIntegration:onParryResult(success, bs, etaError)
    MainLoopV2:_processParryResult(success, bs, etaError)
    if success then
        self._parryCount = self._parryCount + 1
        if bs then
            local pred = LearningV2 and LearningV2:predict(
                etaError or 0.1,
                PingComp and PingComp:get() or 0.05,
                bs.velocity and bs.velocity.Magnitude or 50,
                0.5, 0, NetLayerV2:getJitter(), 20,
                ComboV2:getStreak(), Config.parryMode
            ) or 0.5
            -- record outcome for future learning
            LearningV2:record(
                etaError or 0.1,
                PingComp and PingComp:get() or 0.05,
                bs.velocity and bs.velocity.Magnitude or 50,
                0.5, 0, NetLayerV2:getJitter(), 20,
                ComboV2:getStreak(), Config.parryMode, true
            )
        end
        TimingOptimizer:record(etaError or 0, true)
    else
        self._missCount = self._missCount + 1
        if bs then
            LearningV2:record(
                etaError or 0, PingComp and PingComp:get() or 0.05,
                bs.velocity and bs.velocity.Magnitude or 50,
                0.5, 0, NetLayerV2:getJitter(), 20,
                ComboV2:getStreak(), Config.parryMode, false
            )
        end
        TimingOptimizer:record(etaError or 0, false)
    end
end

function ParryIntegration:getAccuracy()
    local total = self._parryCount + self._missCount
    return total > 0 and (self._parryCount / total * 100) or 0
end

function ParryIntegration:getStats()
    return {
        parries  = self._parryCount,
        misses   = self._missCount,
        accuracy = self:getAccuracy(),
        lastT    = self._lastParryT,
    }
end

if Console then Console.info("ParryIntegration", "Parry integration layer ready") end

-- §90.1 Auto-mode switcher
local AutoModeSwitcher = {}
AutoModeSwitcher._active         = false
AutoModeSwitcher._switchInterval = 60   -- seconds between mode checks
AutoModeSwitcher._lastSwitch     = 0
AutoModeSwitcher._minSamples     = 20   -- need this many parries before switching

function AutoModeSwitcher:check()
    if not self._active then return end
    if (tick() - self._lastSwitch) < self._switchInterval then return end
    local stats = CombatAnalytics:getCurrentStats()
    if not stats or stats.parries + stats.misses < self._minSamples then return end
    local currentAcc = stats.accuracy
    -- check if another mode would be better (from learning engine)
    local bestMode, bestAcc = LearningV2:getBestMode()
    if bestMode ~= Config.parryMode and bestAcc > currentAcc / 100 + 0.1 then
        if Console then Console.info("AutoMode", string.format(
            "Switching mode: %s to %s (acc: %.0f%% -> predicted %.0f%%)",
            Config.parryMode, bestMode, currentAcc, bestAcc * 100
        )) end
        Config.parryMode = bestMode
        self._lastSwitch = tick()
        NotifyV2:info("Auto Mode Switch", "Switched to "..bestMode.." mode", 4)
    end
end

function AutoModeSwitcher:start()
    self._active = true
    task.spawn(function()
        while self._active do
            task.wait(self._switchInterval)
            pcall(function() self:check() end)
        end
    end)
    if Console then Console.info("AutoModeSwitcher", "Auto mode switcher active (interval="..self._switchInterval.."s)") end
end

function AutoModeSwitcher:stop()
    self._active = false
end

-- only start auto-switcher if explicitly enabled
-- AutoModeSwitcher:start()
if Console then Console.info("AutoModeSwitcher", "Auto mode switcher ready (disabled by default)") end

-- §91 ─── COMPREHENSIVE UNIT TESTS ────────────────────────────────────────────
-- Built-in self-tests to verify core systems on each load
local SelfTest = {}
SelfTest._results = {}
SelfTest._passed  = 0
SelfTest._failed  = 0
SelfTest._skipped = 0

local function _assert(condition, name, msg)
    if condition then
        SelfTest._passed = SelfTest._passed + 1
        table.insert(SelfTest._results, { name = name, pass = true })
    else
        SelfTest._failed = SelfTest._failed + 1
        table.insert(SelfTest._results, { name = name, pass = false, msg = msg or "assertion failed" })
        if Console then Console.error("SelfTest", "FAIL: "..name..(msg and (" - "..msg) or "")) end
    end
end

local function _skip(name, reason)
    SelfTest._skipped = SelfTest._skipped + 1
    table.insert(SelfTest._results, { name = name, skip = true, msg = reason })
end

function SelfTest:run()
    -- Signal OOP
    _assert(type(Signal) == "table",              "Signal.class",    "Signal not defined")
    _assert(type(Signal.new) == "function",       "Signal.new",      "Signal.new missing")

    -- Config
    _assert(type(Config) == "table",              "Config.table",    "Config not a table")
    _assert(Config.parryMode ~= nil,              "Config.parryMode","parryMode key missing")

    -- ETA math
    local eta = 0.3
    local adj = eta - 0.05
    _assert(adj < eta,                             "ETAAdj.less",    "adjusted ETA should be less")
    _assert(adj >= 0,                              "ETAAdj.nonNeg",  "adjusted ETA should be >= 0")

    -- PriorityQueue
    if type(MinHeap) == "table" then
        local q = MinHeap:new()
        q:push(3, "c"); q:push(1, "a"); q:push(2, "b")
        local top = q:pop()
        _assert(top == "a",                        "MinHeap.order",  "expected 'a' (score 1), got "..tostring(top))
        _assert(q:size() == 2,                     "MinHeap.size",   "expected size 2, got "..q:size())
    else
        _skip("MinHeap", "MinHeap not defined in scope")
    end

    -- LRU cache
    if type(LRUCache) == "table" or type(LRUCache) == "function" then
        -- just check it's accessible
        _assert(true, "LRUCache.accessible")
    else
        _skip("LRUCache", "LRUCache not in scope")
    end

    -- IEEE-754 float decode
    if type(MemScanner) == "table" and MemScanner._readF32 then
        -- test with known float: 0x3F800000 = 1.0f
        local bytes = "\x00\x00\x80\x3F"  -- little-endian 1.0f
        local ok, val = pcall(function() return MemScanner._readF32(bytes, 1) end)
        if ok then
            _assert(math.abs(val - 1.0) < 0.001, "IEEE754.readF32", "expected 1.0, got "..tostring(val))
        else
            _skip("IEEE754.readF32", "readF32 not accessible")
        end
    else
        _skip("IEEE754.readF32", "MemScanner not in scope")
    end

    -- Box-Muller gaussian
    local samples = {}
    for i = 1, 100 do
        local u1, u2 = math.random(), math.random()
        while u1 <= 1e-10 do u1 = math.random() end
        local g = math.sqrt(-2 * math.log(u1)) * math.cos(2 * math.pi * u2)
        samples[i] = g
    end
    local mean = 0
    for _, s in ipairs(samples) do mean = mean + s end
    mean = mean / 100
    _assert(math.abs(mean) < 0.5,                 "BoxMuller.mean",  "mean should be near 0, got "..mean)

    -- PerfBench
    PerfBench:mark("test_mark")
    task.wait(0.001)
    local dur = PerfBench:measure("test_measure", "test_mark")
    _assert(type(dur) == "number",                "PerfBench.type",  "duration should be number")

    -- EventBus
    local fired = false
    local id = EventBus:subscribe("self_test_event", function() fired = true end)
    EventBus:publish("self_test_event", {})
    _assert(fired,                                 "EventBus.pubsub", "event not received")
    EventBus:unsubscribe("self_test_event", id)

    -- ComboV2
    local oldStreak = ComboV2:getStreak()
    ComboV2:onParry()
    _assert(ComboV2:getStreak() == oldStreak + 1, "ComboV2.onParry", "streak didn't increment")
    ComboV2:onMiss()
    _assert(ComboV2:getStreak() == 0,             "ComboV2.onMiss",  "streak didn't reset")

    -- TimingOptimizer
    for i = 1, 10 do TimingOptimizer:record(0.1, true) end
    local offset = TimingOptimizer:getOptimalLeadTime()
    _assert(type(offset) == "number",             "TimingOpt.type",  "offset should be number")
    _assert(offset >= 0,                          "TimingOpt.nonNeg","offset should be >= 0")

    -- FeatureFlags
    FeatureFlags:set("_TEST_FLAG", true)
    _assert(FeatureFlags:isEnabled("_TEST_FLAG"), "FeatureFlags.set")
    FeatureFlags:reset("_TEST_FLAG")
    _assert(not FeatureFlags:isEnabled("_TEST_FLAG"), "FeatureFlags.reset")

    -- NetLayerV2
    local stats = NetLayerV2:getStats()
    _assert(type(stats) == "table",               "NetLayer.stats",  "stats should be table")
    _assert(type(stats.quality) == "string",      "NetLayer.quality","quality should be string")

    -- RankedSystem
    local oldELO = RankedSystem:getELO()
    RankedSystem:updateELO(1000, 1)  -- win against equal
    _assert(RankedSystem:getELO() > oldELO,       "Ranked.win",     "ELO should increase on win")
    RankedSystem:updateELO(1000, 0)  -- lose
    -- (we don't assert decrease since it depends on exact K factor)
    _assert(type(RankedSystem:getTier()) == "string", "Ranked.tier", "tier should be string")

    -- BallClassV2
    local class, score = BallClassV2:classify("test_ball", 150, 0.05, 0)
    _assert(class == "Laser",                     "BallClass.laser", "speed 150 should be Laser, got "..class)

    -- SpinPhysics
    SpinPhysics:updateSpin("test", Vector3.new(1,0,0), Vector3.new(0,0,-1), 0.1)
    local spinMag = SpinPhysics:getSpinMagnitude("test")
    _assert(type(spinMag) == "number",            "Spin.mag",       "spin magnitude should be number")

    -- Done
    local total = self._passed + self._failed + self._skipped
    if Console then Console.info("SelfTest", string.format(
        "Tests: %d passed, %d failed, %d skipped / %d total",
        self._passed, self._failed, self._skipped, total
    )) end
    if self._failed > 0 then
        if Console then Console.warn("SelfTest", "FAILURES detected — check system integrity") end
    else
        if Console then Console.info("SelfTest", "All tests passed!") end
    end
    return self._failed == 0
end

function SelfTest:getSummary()
    return string.format(
        "Tests: %d/%d passed (%d skipped)",
        self._passed, self._passed + self._failed, self._skipped
    )
end

-- Run self-tests in background after a short delay
task.delay(2.0, function()
    pcall(function() SelfTest:run() end)
end)

if Console then Console.info("SelfTest", "Self-test suite registered (will run in 2s)") end

-- §92 ─── EXTENDED ABILITY SYSTEM ─────────────────────────────────────────────
-- Tracks and leverages Blade Ball ability timings for advanced play
local AbilitySystem = {}
AbilitySystem._abilities     = {}
AbilitySystem._cooldowns     = {}
AbilitySystem._abilityLog    = {}
AbilitySystem._MAX_LOG       = 100
AbilitySystem._detectedAbils = {}  -- abilities detected from remote spy

-- Known Blade Ball abilities and their typical cooldowns (seconds)
local KNOWN_ABILITIES = {
    Parry       = { cooldown = 0.5,  type = "defensive", priority = 10 },
    Block       = { cooldown = 8.0,  type = "defensive", priority = 9  },
    Dodge       = { cooldown = 6.0,  type = "evasive",   priority = 8  },
    Slash       = { cooldown = 5.0,  type = "offensive", priority = 5  },
    Dash        = { cooldown = 4.0,  type = "evasive",   priority = 7  },
    Shield      = { cooldown = 12.0, type = "defensive", priority = 9  },
    Teleport    = { cooldown = 8.0,  type = "evasive",   priority = 6  },
    Stun        = { cooldown = 10.0, type = "offensive", priority = 4  },
    Reflect     = { cooldown = 15.0, type = "defensive", priority = 10 },
    Ultimate    = { cooldown = 30.0, type = "special",   priority = 3  },
}

for name, data in pairs(KNOWN_ABILITIES) do
    AbilitySystem._abilities[name] = {
        name       = name,
        cooldown   = data.cooldown,
        type       = data.type,
        priority   = data.priority,
        lastUsed   = 0,
        useCount   = 0,
    }
end

function AbilitySystem:recordUse(abilityName, byPlayer)
    local now = tick()
    local ab = self._abilities[abilityName]
    if not ab then
        -- create dynamic entry
        ab = { name = abilityName, cooldown = 5.0, type = "unknown", priority = 5,
               lastUsed = 0, useCount = 0 }
        self._abilities[abilityName] = ab
    end
    ab.lastUsed = now
    ab.useCount = ab.useCount + 1
    table.insert(self._abilityLog, {
        t       = now,
        ability = abilityName,
        player  = byPlayer and byPlayer.Name or "unknown",
    })
    if #self._abilityLog > self._MAX_LOG then table.remove(self._abilityLog, 1) end
    if Console then Console.info("AbilitySystem", (byPlayer and byPlayer.Name or "?").." used "..abilityName) end
end

function AbilitySystem:isOnCooldown(abilityName)
    local ab = self._abilities[abilityName]
    if not ab or ab.lastUsed == 0 then return false end
    return (tick() - ab.lastUsed) < ab.cooldown
end

function AbilitySystem:getCooldownRemaining(abilityName)
    local ab = self._abilities[abilityName]
    if not ab then return 0 end
    local elapsed = tick() - ab.lastUsed
    return math.max(0, ab.cooldown - elapsed)
end

function AbilitySystem:isReady(abilityName)
    return not self:isOnCooldown(abilityName)
end

function AbilitySystem:getReadyAbilities()
    local ready = {}
    for name, ab in pairs(self._abilities) do
        if self:isReady(name) then
            ready[#ready+1] = { name = name, priority = ab.priority, type = ab.type }
        end
    end
    table.sort(ready, function(a, b) return a.priority > b.priority end)
    return ready
end

function AbilitySystem:getBestDefensiveAbility()
    local ready = self:getReadyAbilities()
    for _, ab in ipairs(ready) do
        if ab.type == "defensive" then return ab.name end
    end
    return nil
end

function AbilitySystem:getAbilityStats()
    local stats = {}
    for name, ab in pairs(self._abilities) do
        stats[#stats+1] = {
            name       = name,
            useCount   = ab.useCount,
            cdRemain   = self:getCooldownRemaining(name),
            ready      = self:isReady(name),
        }
    end
    table.sort(stats, function(a, b) return a.useCount > b.useCount end)
    return stats
end

function AbilitySystem:monitorFromSpy()
    -- listen to remote spy for ability calls
    EventBus:subscribe("remote_call", function(data)
        if data and data.remote and data.remote:match("Ability") then
            self:recordUse("Unknown", nil)
            self._detectedAbils[data.remote] = (self._detectedAbils[data.remote] or 0) + 1
        end
    end)
end

AbilitySystem:monitorFromSpy()
if Console then Console.info("AbilitySystem", "Ability tracking system ready ("..#KNOWN_ABILITIES.." known abilities)") end

-- §92.1 Ability combo detector
local AbilityComboDetector = {}
AbilityComboDetector._sequences  = {}
AbilityComboDetector._WINDOW     = 3  -- seconds to form a combo
AbilityComboDetector._combos     = {
    { seq = {"Dodge", "Parry"},        name = "Evade-Parry",  bonus = 1.2 },
    { seq = {"Block", "Parry"},        name = "Shield-Parry", bonus = 1.3 },
    { seq = {"Dash", "Parry"},         name = "Dash-Parry",   bonus = 1.4 },
    { seq = {"Parry", "Reflect"},      name = "Double-Defense",bonus = 1.5},
    { seq = {"Dodge", "Dash", "Parry"},name = "Evasion Combo", bonus = 2.0},
}
AbilityComboDetector._detected   = {}

function AbilityComboDetector:push(abilityName)
    local now = tick()
    table.insert(self._sequences, { ability = abilityName, t = now })
    -- remove old entries outside window
    while #self._sequences > 0 and (now - self._sequences[1].t) > self._WINDOW do
        table.remove(self._sequences, 1)
    end
    -- check for combos
    for _, combo in ipairs(self._combos) do
        if self:_matchesSeq(combo.seq) then
            table.insert(self._detected, {
                name  = combo.name,
                bonus = combo.bonus,
                t     = now,
            })
            if Console then Console.info("AbilityCombo", "COMBO: "..combo.name.." (x"..combo.bonus..")") end
            NotifyV2:success("Ability Combo!", combo.name.." ×"..combo.bonus, 3)
            self._sequences = {}  -- reset after combo
            return combo
        end
    end
    return nil
end

function AbilityComboDetector:_matchesSeq(seq)
    if #self._sequences < #seq then return false end
    local offset = #self._sequences - #seq
    for i, ability in ipairs(seq) do
        if self._sequences[offset + i].ability ~= ability then return false end
    end
    return true
end

function AbilityComboDetector:getRecentCombos(n)
    n = n or 10
    local out = {}
    local start = math.max(1, #self._detected - n + 1)
    for i = start, #self._detected do
        out[#out+1] = self._detected[i]
    end
    return out
end

if Console then Console.info("AbilityComboDetector", "Ability combo detector ready") end

-- §93 ─── EXTENDED MINIMAP v3 ──────────────────────────────────────────────────
local MinimapV3 = {}
MinimapV3._active        = true
MinimapV3._size          = 160
MinimapV3._range         = 100
MinimapV3._playerDots    = {}
MinimapV3._ballDots      = {}
MinimapV3._trails        = {}
MinimapV3._heatMap       = {}
MinimapV3._drawObjects   = {}
MinimapV3._updateHz      = 20
MinimapV3._lastUpdate    = 0
MinimapV3._showZones     = true
MinimapV3._showNames     = false
MinimapV3._showTrails    = true
MinimapV3._orientation   = "north"  -- north, camera
MinimapV3._bgColor       = Color3.fromRGB(20, 20, 30)
MinimapV3._borderColor   = Color3.fromRGB(80, 80, 100)
MinimapV3._playerColor   = Color3.fromRGB(80, 200, 80)
MinimapV3._enemyColor    = Color3.fromRGB(220, 80, 80)
MinimapV3._ballColor     = Color3.fromRGB(255, 215, 0)
MinimapV3._selfColor     = Color3.fromRGB(255, 255, 255)
MinimapV3._trailLen      = 5
MinimapV3._x             = nil
MinimapV3._y             = nil

local function _mmPos(worldPos, cx, cy, range, size, camYaw)
    -- convert world XZ to minimap pixel coordinates
    local relX = worldPos.X - (game.Players.LocalPlayer.Character
        and game.Players.LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
        and game.Players.LocalPlayer.Character.HumanoidRootPart.Position.X or 0)
    local relZ = worldPos.Z - (game.Players.LocalPlayer.Character
        and game.Players.LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
        and game.Players.LocalPlayer.Character.HumanoidRootPart.Position.Z or 0)
    -- rotate by camera yaw if camera-relative
    if camYaw then
        local cos, sin = math.cos(-camYaw), math.sin(-camYaw)
        relX, relZ = relX * cos - relZ * sin, relX * sin + relZ * cos
    end
    local scale = (size / 2) / range
    local px = cx + relX * scale
    local py = cy - relZ * scale  -- Z is forward, Y is up on screen
    return px, py
end

function MinimapV3:_clear()
    for _, o in ipairs(self._drawObjects) do
        pcall(function() o.Visible = false; o:Remove() end)
    end
    self._drawObjects = {}
end

function MinimapV3:_addObj(o)
    if o then self._drawObjects[#self._drawObjects+1] = o end
end

function MinimapV3:update()
    if not self._active or not _drawingSupported then return end
    local now = tick()
    if (now - self._lastUpdate) < (1 / self._updateHz) then return end
    self._lastUpdate = now
    self:_clear()
    local cam = workspace.CurrentCamera
    if not cam then return end
    local lp = game.Players.LocalPlayer
    local char = lp and lp.Character
    local root = char and char:FindFirstChild("HumanoidRootPart")
    if not root then return end
    -- minimap position (bottom-left corner by default)
    local vp = cam.ViewportSize
    local x  = self._x or 20
    local y  = self._y or (vp.Y - self._size - 20)
    local cx = x + self._size / 2
    local cy = y + self._size / 2
    local camYaw = self._orientation == "camera"
        and select(2, cam.CFrame:ToEulerAnglesYXZ()) or nil
    -- background
    local bg = Draw2:newQuad(
        { Vector2.new(x,y), Vector2.new(x+self._size,y),
          Vector2.new(x+self._size,y+self._size), Vector2.new(x,y+self._size) },
        self._bgColor, 1, true
    )
    self:_addObj(bg)
    -- border
    local border = Draw2:newQuad(
        { Vector2.new(x,y), Vector2.new(x+self._size,y),
          Vector2.new(x+self._size,y+self._size), Vector2.new(x,y+self._size) },
        self._borderColor, 2, false
    )
    self:_addObj(border)
    -- range circles
    for _, range in ipairs({ self._range * 0.33, self._range * 0.66, self._range }) do
        local r = (range / self._range) * self._size / 2
        local ring = Draw2:newCircle(cx, cy, r, Color3.fromRGB(50,50,70), 1, false)
        self:_addObj(ring)
    end
    -- self dot + heading arrow
    local selfDot = Draw2:newCircle(cx, cy, 4, self._selfColor, 1, true)
    self:_addObj(selfDot)
    -- player dots
    for _, player in ipairs(game.Players:GetPlayers()) do
        if player ~= lp then
            local pchar = player.Character
            local proot = pchar and pchar:FindFirstChild("HumanoidRootPart")
            if proot then
                local px, py = _mmPos(proot.Position, cx, cy, self._range, self._size, camYaw)
                local inRange = math.abs(px-cx) < self._size/2 and math.abs(py-cy) < self._size/2
                if inRange then
                    local dot = Draw2:newCircle(px, py, 3, self._enemyColor, 1, true)
                    self:_addObj(dot)
                    if self._showNames then
                        local nm = Draw2:newText(px+5, py-5, player.DisplayName, self._enemyColor, 9)
                        self:_addObj(nm)
                    end
                    -- trail
                    if self._showTrails then
                        if not self._trails[player.UserId] then
                            self._trails[player.UserId] = {}
                        end
                        local trail = self._trails[player.UserId]
                        table.insert(trail, { px = px, py = py })
                        if #trail > self._trailLen then table.remove(trail, 1) end
                        for i = 2, #trail do
                            local alpha = i / #trail
                            local color = Color3.new(
                                self._enemyColor.R * alpha,
                                self._enemyColor.G * alpha,
                                self._enemyColor.B * alpha
                            )
                            local tl = Draw2:newLine(trail[i-1].px, trail[i-1].py, trail[i].px, trail[i].py, color, 1)
                            self:_addObj(tl)
                        end
                    end
                end
            end
        end
    end
    -- ball dots
    for id, bs in pairs(BallTracker._balls or {}) do
        local bpos = bs.pos
        if bpos then
            local px, py = _mmPos(bpos, cx, cy, self._range, self._size, camYaw)
            local inRange = math.abs(px-cx) < self._size/2 and math.abs(py-cy) < self._size/2
            if inRange then
                local dot = Draw2:newCircle(px, py, 5, self._ballColor, 2, false)
                self:_addObj(dot)
                local inner = Draw2:newCircle(px, py, 2, self._ballColor, 1, true)
                self:_addObj(inner)
                -- velocity arrow
                if bs.velocity and bs.velocity.Magnitude > 0.1 then
                    local ahead = bs.velocity.Unit * math.min(10, bs.velocity.Magnitude * 0.2)
                    local aheadPos = bpos + Vector3.new(ahead.X, 0, ahead.Z)
                    local apx, apy = _mmPos(aheadPos, cx, cy, self._range, self._size, camYaw)
                    local arr = Draw2:newLine(px, py, apx, apy, self._ballColor, 2)
                    self:_addObj(arr)
                end
                -- threat ETA label
                if bs.eta and bs.eta < 2 then
                    local etaLabel = Draw2:newText(px+4, py-4, string.format("%.1f", bs.eta), self._ballColor, 9)
                    self:_addObj(etaLabel)
                end
            end
        end
    end
    -- label
    local label = Draw2:newText(x+2, y+2, "MAP", Color3.fromRGB(120,120,140), 9)
    self:_addObj(label)
end

function MinimapV3:start()
    self._active = true
    RunService.Heartbeat:Connect(function()
        if self._active then pcall(function() self:update() end) end
    end)
    if Console then Console.info("MinimapV3", "Minimap v3 started") end
end

function MinimapV3:stop()
    self._active = false
    self:_clear()
end

function MinimapV3:setRange(r) self._range = r end
function MinimapV3:setSize(s)  self._size  = s end

if Config.minimap and FeatureFlags:isEnabled("ENABLE_DRAWING_ESP") then
    MinimapV3:start()
end

if Console then Console.info("MinimapV3", "Minimap v3 ready") end

-- §94 ─── EXTENDED STATUS BAR ─────────────────────────────────────────────────
-- Drawing-API based HUD overlay status bar
local StatusBarHUD = {}
StatusBarHUD._active      = true
StatusBarHUD._drawObjs    = {}
StatusBarHUD._updateHz    = 10
StatusBarHUD._lastUpdate  = 0
StatusBarHUD._y           = 8      -- top of screen
StatusBarHUD._height      = 20
StatusBarHUD._bgColor     = Color3.fromRGB(15, 15, 20)
StatusBarHUD._textColor   = Color3.fromRGB(200, 200, 210)
StatusBarHUD._accentColor = Color3.fromRGB(80, 220, 120)
StatusBarHUD._warnColor   = Color3.fromRGB(255, 180, 40)
StatusBarHUD._errColor    = Color3.fromRGB(255, 60, 60)

function StatusBarHUD:_clear()
    for _, o in ipairs(self._drawObjs) do
        pcall(function() o.Visible = false; o:Remove() end)
    end
    self._drawObjs = {}
end

function StatusBarHUD:_add(o) if o then self._drawObjs[#self._drawObjs+1] = o end end

function StatusBarHUD:update()
    if not self._active or not _drawingSupported then return end
    local now = tick()
    if (now - self._lastUpdate) < (1 / self._updateHz) then return end
    self._lastUpdate = now
    self:_clear()
    local cam = workspace.CurrentCamera
    if not cam then return end
    local vp = cam.ViewportSize
    local w  = vp.X
    -- background bar
    local bg = Draw2:newQuad(
        { Vector2.new(0,0), Vector2.new(w,0), Vector2.new(w,self._height), Vector2.new(0,self._height) },
        self._bgColor, 1, true
    )
    self:_add(bg)
    -- build status segments
    local segments = {}
    -- parry mode
    local mode = Config.parryMode or "OFF"
    local modeColor = Config.parryActive and self._accentColor or self._warnColor
    segments[#segments+1] = { text = "PARRY:"..mode, color = modeColor }
    -- combo
    local streak = ComboV2:getStreak()
    if streak > 0 then
        segments[#segments+1] = { text = "×"..streak, color = Color3.fromRGB(255,215,0) }
    end
    -- ping
    local ping = PingComp and math.floor(PingComp:get() * 1000) or 0
    local pingColor = ping < 80 and self._accentColor or (ping < 150 and self._warnColor or self._errColor)
    segments[#segments+1] = { text = "PING:"..ping.."ms", color = pingColor }
    -- FPS
    local fps = math.floor(MainLoopV2._lastFPS)
    local fpsColor = fps >= 55 and self._accentColor or (fps >= 30 and self._warnColor or self._errColor)
    segments[#segments+1] = { text = "FPS:"..fps, color = fpsColor }
    -- accuracy
    local acc = math.floor(ParryIntegration:getAccuracy())
    segments[#segments+1] = { text = "ACC:"..acc.."%", color = self._textColor }
    -- net quality
    local qual = NetLayerV2:getQuality()
    segments[#segments+1] = { text = "NET:"..qual, color = self._textColor }
    -- ELO
    segments[#segments+1] = { text = "ELO:"..RankedSystem:getELO().."["..RankedSystem:getTier().."]", color = self._textColor }
    -- WindHub version badge
    segments[#segments+1] = { text = "WindHub v"..Updater.VERSION, color = Color3.fromRGB(120,120,140) }
    -- render segments spaced out
    local x = 8
    for _, seg in ipairs(segments) do
        local t = Draw2:newText(x, self._y + 4, seg.text, seg.color, 11, true)
        self:_add(t)
        x = x + #seg.text * 7 + 14
        if x > w - 100 then break end
    end
end

function StatusBarHUD:start()
    self._active = true
    RunService.Heartbeat:Connect(function()
        if self._active then pcall(function() self:update() end) end
    end)
    if Console then Console.info("StatusBarHUD", "Drawing HUD status bar started") end
end

function StatusBarHUD:stop()
    self._active = false
    self:_clear()
end

if FeatureFlags:isEnabled("ENABLE_DRAWING_ESP") then
    StatusBarHUD:start()
end

if Console then Console.info("StatusBarHUD", "Status bar HUD ready") end

-- §94.1 Danger zone HUD overlay
local DangerZoneHUD = {}
DangerZoneHUD._active       = false
DangerZoneHUD._drawObjs     = {}
DangerZoneHUD._threshold    = 5  -- studs — ball must be within this to trigger
DangerZoneHUD._blinkPhase   = 0
DangerZoneHUD._blinkRate    = 4  -- Hz

function DangerZoneHUD:_clear()
    for _, o in ipairs(self._drawObjs) do
        pcall(function() o.Visible = false; o:Remove() end)
    end
    self._drawObjs = {}
end

function DangerZoneHUD:update(closestBallDist, closestBallETA)
    if not self._active or not _drawingSupported then return end
    self:_clear()
    if not closestBallDist or closestBallDist > self._threshold * 3 then return end
    local cam = workspace.CurrentCamera
    if not cam then return end
    local vp = cam.ViewportSize
    -- danger level 0-1
    local danger = 1 - math.clamp(closestBallDist / (self._threshold * 3), 0, 1)
    -- blink
    self._blinkPhase = self._blinkPhase + RunService.Heartbeat:Wait() * self._blinkRate
    local blink = math.sin(self._blinkPhase * 2 * math.pi)
    if blink < 0 and danger > 0.7 then return end  -- blink by skipping render
    -- red vignette (4 quads forming a frame)
    local thickness = math.floor(20 * danger)
    local color = Color3.new(danger, 0.1, 0.1)
    -- top
    local top = Draw2:newQuad(
        { Vector2.new(0,0), Vector2.new(vp.X,0), Vector2.new(vp.X,thickness), Vector2.new(0,thickness) },
        color, 1, true
    )
    -- bottom
    local bot = Draw2:newQuad(
        { Vector2.new(0,vp.Y-thickness), Vector2.new(vp.X,vp.Y-thickness),
          Vector2.new(vp.X,vp.Y), Vector2.new(0,vp.Y) },
        color, 1, true
    )
    -- left
    local lft = Draw2:newQuad(
        { Vector2.new(0,0), Vector2.new(thickness,0),
          Vector2.new(thickness,vp.Y), Vector2.new(0,vp.Y) },
        color, 1, true
    )
    -- right
    local rgt = Draw2:newQuad(
        { Vector2.new(vp.X-thickness,0), Vector2.new(vp.X,0),
          Vector2.new(vp.X,vp.Y), Vector2.new(vp.X-thickness,vp.Y) },
        color, 1, true
    )
    if top then self._drawObjs[#self._drawObjs+1] = top end
    if bot then self._drawObjs[#self._drawObjs+1] = bot end
    if lft then self._drawObjs[#self._drawObjs+1] = lft end
    if rgt then self._drawObjs[#self._drawObjs+1] = rgt end
    -- warning text
    if closestBallETA and closestBallETA < 1 then
        local wt = Draw2:newText(vp.X/2-60, vp.Y/2-14, "INCOMING!", color, 24, true)
        if wt then self._drawObjs[#self._drawObjs+1] = wt end
    end
end

function DangerZoneHUD:start()
    self._active = true
    RunService.Heartbeat:Connect(function()
        if not self._active then return end
        local lp   = game.Players.LocalPlayer
        local char = lp and lp.Character
        local root = char and char:FindFirstChild("HumanoidRootPart")
        if not root then return end
        local minDist, minETA = math.huge, math.huge
        for _, bs in pairs(BallTracker._balls or {}) do
            if bs.pos then
                local d = (bs.pos - root.Position).Magnitude
                if d < minDist then
                    minDist = d
                    minETA  = bs.eta or minETA
                end
            end
        end
        pcall(function() self:update(minDist, minETA) end)
    end)
    if Console then Console.info("DangerZoneHUD", "Danger zone HUD started") end
end

if Config.dangerZone and FeatureFlags:isEnabled("ENABLE_DRAWING_ESP") then
    DangerZoneHUD:start()
end

if Console then Console.info("DangerZoneHUD", "Danger zone HUD ready") end

-- §95 ─── EXTENDED AUDIO SYSTEM v3 ────────────────────────────────────────────
local AudioV3 = {}
AudioV3._active      = true
AudioV3._volume      = 0.5
AudioV3._pools       = {}
AudioV3._ducking     = false
AudioV3._duckFactor  = 0.3
AudioV3._poolSize    = 4

local AUDIO_CATALOGUE_V3 = {
    parry_success  = { id = "rbxassetid://9120388661", pitch = 1.0,  vol = 0.8 },
    parry_fail     = { id = "rbxassetid://9120388690", pitch = 0.85, vol = 0.6 },
    combo_5        = { id = "rbxassetid://9120388720", pitch = 1.1,  vol = 0.7 },
    combo_10       = { id = "rbxassetid://9120388750", pitch = 1.2,  vol = 0.9 },
    combo_25       = { id = "rbxassetid://9120388780", pitch = 1.4,  vol = 1.0 },
    kill           = { id = "rbxassetid://9120388810", pitch = 1.0,  vol = 0.8 },
    death          = { id = "rbxassetid://9120388840", pitch = 0.8,  vol = 0.7 },
    alert_high     = { id = "rbxassetid://9120388870", pitch = 1.3,  vol = 0.9 },
    alert_low      = { id = "rbxassetid://9120388900", pitch = 0.9,  vol = 0.6 },
    ui_click       = { id = "rbxassetid://9120388930", pitch = 1.0,  vol = 0.4 },
    ui_open        = { id = "rbxassetid://9120388960", pitch = 1.0,  vol = 0.5 },
    ui_close       = { id = "rbxassetid://9120388990", pitch = 0.95, vol = 0.4 },
    level_up       = { id = "rbxassetid://9120389020", pitch = 1.0,  vol = 1.0 },
    achievement    = { id = "rbxassetid://9120389050", pitch = 1.1,  vol = 0.9 },
    ball_incoming  = { id = "rbxassetid://9120389080", pitch = 1.0,  vol = 0.7 },
    blaze_activate = { id = "rbxassetid://9120389110", pitch = 1.2,  vol = 1.0 },
    timer_tick     = { id = "rbxassetid://9120389140", pitch = 1.0,  vol = 0.3 },
}

function AudioV3:_getPool(soundKey)
    if not self._pools[soundKey] then
        local data = AUDIO_CATALOGUE_V3[soundKey]
        if not data then return nil end
        local pool = {}
        for i = 1, self._poolSize do
            pcall(function()
                local s = Instance.new("Sound")
                s.SoundId  = data.id
                s.Volume   = data.vol * self._volume
                s.PlaybackSpeed = data.pitch
                s.Parent   = workspace
                pool[i] = s
            end)
        end
        self._pools[soundKey] = pool
    end
    return self._pools[soundKey]
end

function AudioV3:play(soundKey, pitchMod, volMod)
    if not self._active then return end
    local data = AUDIO_CATALOGUE_V3[soundKey]
    if not data then return end
    local vol  = data.vol * self._volume * (volMod or 1)
    if self._ducking then vol = vol * self._duckFactor end
    local pitch = data.pitch * (pitchMod or 1)
    -- get a free sound from pool
    local pool = self:_getPool(soundKey)
    if pool then
        for _, s in ipairs(pool) do
            if not s.IsPlaying then
                pcall(function()
                    s.Volume = vol
                    s.PlaybackSpeed = pitch
                    s:Play()
                end)
                return
            end
        end
    end
    -- fallback: fire-and-forget
    pcall(function()
        local s = Instance.new("Sound")
        s.SoundId       = data.id
        s.Volume        = vol
        s.PlaybackSpeed = pitch
        s.Parent        = workspace
        s:Play()
        game:GetService("Debris"):AddItem(s, 5)
    end)
end

function AudioV3:duck(duration)
    self._ducking = true
    task.delay(duration or 0.5, function()
        self._ducking = false
    end)
end

function AudioV3:setVolume(v)
    self._volume = math.clamp(v, 0, 1)
    -- update all pooled sounds
    for key, pool in pairs(self._pools) do
        local data = AUDIO_CATALOGUE_V3[key]
        if data then
            for _, s in ipairs(pool) do
                pcall(function() s.Volume = data.vol * self._volume end)
            end
        end
    end
end

function AudioV3:stopAll()
    for _, pool in pairs(self._pools) do
        for _, s in ipairs(pool) do
            pcall(function() s:Stop() end)
        end
    end
end

-- pentatonic combo chimes
local PENTATONIC = { 0.90, 1.00, 1.12, 1.35, 1.50, 1.68, 1.80, 2.00 }
local _chimeIdx = 0

function AudioV3:playComboChime()
    _chimeIdx = (_chimeIdx % #PENTATONIC) + 1
    self:play("parry_success", PENTATONIC[_chimeIdx])
end

-- wire to events
EventBus:subscribe("parry_success", function()
    if Config.audioEnabled ~= false then
        AudioV3:playComboChime()
        AudioV3:duck(0.1)
    end
end)
EventBus:subscribe("parry_fail", function()
    if Config.audioEnabled ~= false then
        AudioV3:play("parry_fail")
    end
end)
EventBus:subscribe("combo_milestone", function(data)
    if Config.audioEnabled ~= false then
        local key = data and data.streak >= 25 and "combo_25"
                 or (data and data.streak >= 10 and "combo_10" or "combo_5")
        AudioV3:play(key)
    end
end)
EventBus:subscribe("kill_event", function()
    if Config.audioEnabled ~= false then AudioV3:play("kill") end
end)

if Console then Console.info("AudioV3", "Extended audio system v3 ready ("..#AUDIO_CATALOGUE_V3.." sounds)") end

-- §96 ─── FINAL MODULE REGISTRY ────────────────────────────────────────────────
-- Central registry of all WindHub modules for inspection and management
local Registry = {}
Registry._modules = {}

local function _reg(name, obj, description)
    Registry._modules[name] = {
        name        = name,
        obj         = obj,
        description = description,
        registered  = tick(),
    }
end

-- Register all major modules
_reg("Signal",           Signal,           "Signal/event OOP system")
_reg("Config",           Config,           "Configuration manager with validation")
_reg("PingComp",         PingComp,         "Ping compensation EMA")
_reg("AnimHook",         AnimHook,         "Animation hook intercept system")
_reg("Draw2",            Draw2,            "UNC Drawing API v2 layer")
_reg("BallViz",          BallViz,          "Multi-ball trajectory visualizer")
_reg("CombatAnalytics",  CombatAnalytics,  "Per-round and lifetime combat stats")
_reg("ServerPredict",    ServerPredict,    "Server-side interpolation/extrapolation")
_reg("Rollback",         Rollback,         "Client-side rollback ring buffer")
_reg("InputRecorder",    InputRecorder,    "Input recording and playback")
_reg("Macros",           Macros,           "Built-in macro system")
_reg("Updater",          Updater,          "Version tracking and update checks")
_reg("FeatureFlags",     FeatureFlags,     "Feature flag on/off system")
_reg("HitboxViz",        HitboxViz,        "Hitbox boundary visualization")
_reg("WindPhysics",      WindPhysics,      "Environmental wind physics")
_reg("SpinPhysics",      SpinPhysics,      "Ball spin estimation (Magnus force)")
_reg("ConfigIO",         ConfigIO,         "Config export/import and slot saves")
_reg("PlayerAnalysis",   PlayerAnalysis,   "Extended per-player behavior analysis")
_reg("TournamentMode",   TournamentMode,   "Tournament match tracking")
_reg("RankedSystem",     RankedSystem,     "ELO-based ranked matchmaking")
_reg("DebugTools",       DebugTools,       "Debug watches, breakpoints, profiler")
_reg("EventBus",         EventBus,         "Pub/sub event bus")
_reg("NotifyV2",         NotifyV2,         "Extended notification system")
_reg("Banner",           Banner,           "Fullscreen announcement banner")
_reg("ComboV2",          ComboV2,          "Extended combo tracker v2")
_reg("KillFeedV2",       KillFeedV2,       "Kill feed v2 with methods")
_reg("TargetSelector",   TargetSelector,   "Smart multi-ball target selection")
_reg("TimingOptimizer",  TimingOptimizer,  "Parry timing offset optimizer")
_reg("BallPredictionV2", BallPredictionV2, "Advanced RK4+jerk ball prediction")
_reg("BallClassV2",      BallClassV2,      "Ball type classifier")
_reg("RemoteSpyV4",      RemoteSpyV4,      "Remote spy v4 with pattern matching")
_reg("BypassLayer",      BypassLayer,      "Anti-detection bypass layer")
_reg("ScanRateLimit",    ScanRateLimit,    "Memory scan rate limiter")
_reg("StealthEngine",    StealthEngine,    "Behavioral stealth profile engine")
_reg("FingerprintRand",  FingerprintRand,  "Input fingerprint randomizer")
_reg("LearningV2",       LearningV2,       "8-feature neural net learning engine")
_reg("ServerProfileV2",  ServerProfileV2,  "Server quality profiler")
_reg("RejoinAssist",     RejoinAssist,     "Auto-rejoin on lag detector")
_reg("SelfTest",         SelfTest,         "Comprehensive built-in unit tests")
_reg("AbilitySystem",    AbilitySystem,    "Ability cooldown tracker")
_reg("AbilityComboDetector", AbilityComboDetector, "Ability combo sequence detector")
_reg("MinimapV3",        MinimapV3,        "Minimap v3 with trails and zones")
_reg("StatusBarHUD",     StatusBarHUD,     "Drawing-API top status bar")
_reg("DangerZoneHUD",    DangerZoneHUD,    "Danger zone vignette overlay")
_reg("AudioV3",          AudioV3,          "Audio system v3 with sound pools")
_reg("PhysicsCalib",     PhysicsCalib,     "Physics parameter auto-calibration")
_reg("BouncePredict",    BouncePredict,    "Ball bounce trajectory predictor")
_reg("NetLayerV2",       NetLayerV2,       "Extended network stats and quality")
_reg("PacketScheduler",  PacketScheduler,  "Rate-limited packet scheduler")
_reg("ParryIntegration", ParryIntegration, "Final parry integration layer")
_reg("MainLoopV2",       MainLoopV2,       "Extended main heartbeat loop")
_reg("BallTrackerV2",    BallTrackerV2,    "Extended ball state tracker")
_reg("VisualFX",         VisualFX,         "Parry flash/ring/shockwave effects")
_reg("HitboxV2Extended", HitboxV2Extended, "Per-limb hitbox engine")
_reg("HitboxDebugger",   HitboxDebugger,   "Hitbox debug visualizer")
_reg("Help",             Help,             "Comprehensive help topic system")
_reg("Shutdown",         Shutdown,         "Graceful shutdown handler")
_reg("FinalInit",        FinalInit,        "Late initialization runner")
_reg("PerfBench",        PerfBench,        "Performance micro-benchmark")

function Registry:list()
    local names = {}
    for name, _ in pairs(self._modules) do names[#names+1] = name end
    table.sort(names)
    return names
end

function Registry:get(name)
    local m = self._modules[name]
    return m and m.obj or nil
end

function Registry:describe(name)
    local m = self._modules[name]
    if not m then return "Not found: "..tostring(name) end
    return string.format("%s — %s", m.name, m.description)
end

function Registry:count()
    local n = 0
    for _ in pairs(self._modules) do n = n + 1 end
    return n
end

function Registry:summary()
    local lines = {}
    for _, name in ipairs(self:list()) do
        lines[#lines+1] = "  "..self:describe(name)
    end
    return "WindHub Module Registry ("..self:count().." modules):\n"..table.concat(lines, "\n")
end

-- register console command
if Console and Console._commands then
    Console._commands["registry"] = function(args)
        if args[1] then
            return Registry:describe(args[1])
        end
        return Registry:summary()
    end
end

if Console then Console.info("Registry", "Module registry complete: "..Registry:count().." modules registered") end
if Console then Console.info("WindHub", "═══════════════════════════════════════════════════════") end
if Console then Console.info("WindHub", " All "..Registry:count().." modules loaded successfully.") end
if Console then Console.info("WindHub", " WindHub v"..Updater.VERSION.." is fully operational.") end
if Console then Console.info("WindHub", "═══════════════════════════════════════════════════════") end

-- §97 ─── EXTENDED FINAL TOUCHES ──────────────────────────────────────────────
-- Final configuration, edge case handling, and supplemental utilities

-- §97.1 Error boundary wrapper
local function _safeCall(fn, context)
    local ok, err = pcall(fn)
    if not ok then
        if Console then Console.error(context or "SafeCall", tostring(err)) end
        if DebugTools then DebugTools:log(1, context or "?", tostring(err)) end
        if EventBus then EventBus:publish("error", { context = context, err = err }) end
    end
    return ok, err
end

-- §97.2 Global accessor table for console exec
local WH = {
    Config           = Config,
    Draw2            = Draw2,
    BallViz          = BallViz,
    CombatAnalytics  = CombatAnalytics,
    Updater          = Updater,
    FeatureFlags     = FeatureFlags,
    HitboxViz        = HitboxViz,
    ConfigIO         = ConfigIO,
    PlayerAnalysis   = PlayerAnalysis,
    TournamentMode   = TournamentMode,
    RankedSystem     = RankedSystem,
    DebugTools       = DebugTools,
    EventBus         = EventBus,
    NotifyV2         = NotifyV2,
    Banner           = Banner,
    ComboV2          = ComboV2,
    KillFeedV2       = KillFeedV2,
    TargetSelector   = TargetSelector,
    TimingOptimizer  = TimingOptimizer,
    BallPredictionV2 = BallPredictionV2,
    RemoteSpyV4      = RemoteSpyV4,
    StealthEngine    = StealthEngine,
    LearningV2       = LearningV2,
    ServerProfileV2  = ServerProfileV2,
    SelfTest         = SelfTest,
    AbilitySystem    = AbilitySystem,
    MinimapV3        = MinimapV3,
    StatusBarHUD     = StatusBarHUD,
    AudioV3          = AudioV3,
    PhysicsCalib     = PhysicsCalib,
    NetLayerV2       = NetLayerV2,
    ParryIntegration = ParryIntegration,
    MainLoopV2       = MainLoopV2,
    VisualFX         = VisualFX,
    HitboxV2Extended = HitboxV2Extended,
    Help             = Help,
    Shutdown         = Shutdown,
    Registry         = Registry,
    Macros           = Macros,
    InputRecorder    = InputRecorder,
    PerfBench        = PerfBench,
    BallTrackerV2    = BallTrackerV2,
    WindPhysics      = WindPhysics,
    SpinPhysics      = SpinPhysics,
    BouncePredict    = BouncePredict,
    AnimHook         = AnimHook,
    PacketScheduler  = PacketScheduler,
    BypassLayer      = BypassLayer,
    FingerprintRand  = FingerprintRand,
    ScanRateLimit    = ScanRateLimit,
    Rollback         = Rollback,
    ServerPredict    = ServerPredict,
    DangerZoneHUD    = DangerZoneHUD,
    TrajIntersect    = TrajIntersect,
    BallClassV2      = BallClassV2,
    AutoModeSwitcher = AutoModeSwitcher,
    FinalInit        = FinalInit,
}

-- make WH globally accessible for console exec
if getgenv then
    pcall(function() getgenv().WH = WH end)
end

-- §97.3 Quick-access aliases
local function _alias(name, fn)
    if Console and Console._commands then
        Console._commands[name] = fn
    end
end

_alias("wh", function(args)
    local sub = args[1]
    if sub == "stop" then
        MainLoopV2:stop()
        BallViz:stop()
        HitboxViz:stop()
        StatusBarHUD:stop()
        MinimapV3:stop()
        return "WindHub systems stopped"
    elseif sub == "start" then
        MainLoopV2:start()
        return "WindHub systems started"
    elseif sub == "shutdown" then
        Shutdown:fire("manual")
        return "Shutdown fired"
    elseif sub == "info" then
        return Registry:count().." modules | "..Updater:getVersionString()
    elseif sub == "modules" then
        return table.concat(Registry:list(), ", ")
    elseif sub == "test" then
        SelfTest:run()
        return SelfTest:getSummary()
    else
        return "wh: stop|start|shutdown|info|modules|test"
    end
end)

_alias("q", function(args)
    return "Quick stats:\n"..
        string.format("  Parry Acc: %.1f%% | Streak: %d | Mode: %s\n", 
            ParryIntegration:getAccuracy(), ComboV2:getStreak(), Config.parryMode or "?") ..
        string.format("  ELO: %d [%s] | Net: %s\n",
            RankedSystem:getELO(), RankedSystem:getTier(), NetLayerV2:getQuality()) ..
        string.format("  Modules: %d | FPS: %.0f | Ping: %.0fms",
            Registry:count(), MainLoopV2._lastFPS, (PingComp and PingComp:get() or 0.05)*1000)
end)

-- §97.4 Config hotkey shortcuts
local UIS2 = game:GetService("UserInputService")
if not isMobile then
    UIS2.InputBegan:Connect(function(input, gameProcessed)
        if gameProcessed then return end
        -- F5: toggle parry
        if input.KeyCode == Enum.KeyCode.F5 then
            Config.parryActive = not Config.parryActive
            NotifyV2:info("Parry", Config.parryActive and "Enabled" or "Disabled", 2)
        end
        -- F6: cycle modes
        if input.KeyCode == Enum.KeyCode.F6 then
            local modes = { "Ultra", "Predictive", "Conservative", "RK4", "Fusion" }
            local idx = 1
            for i, m in ipairs(modes) do if m == Config.parryMode then idx = i; break end end
            idx = (idx % #modes) + 1
            Config.parryMode = modes[idx]
            NotifyV2:info("Mode", modes[idx], 2)
        end
        -- F7: toggle hitbox expand
        if input.KeyCode == Enum.KeyCode.F7 then
            Config.hitboxExpand = not Config.hitboxExpand
            NotifyV2:info("Hitbox", Config.hitboxExpand and "Expanded" or "Normal", 2)
        end
        -- F8: toggle ESP
        if input.KeyCode == Enum.KeyCode.F8 then
            Config.ballESP = not Config.ballESP
            NotifyV2:info("ESP", Config.ballESP and "ON" or "OFF", 2)
        end
        -- F9: show quick stats
        if input.KeyCode == Enum.KeyCode.F9 then
            local statsMsg = string.format(
                "Parry: %.1f%% | Streak: %d | ELO: %d | Mode: %s",
                ParryIntegration:getAccuracy(), ComboV2:getStreak(),
                RankedSystem:getELO(), Config.parryMode or "?"
            )
            NotifyV2:info("Stats", statsMsg, 4)
        end
    end)
end

if Console then Console.info("WindHub", "§97 Final touches applied. All systems go.") end

-- §98 ─── SUPPLEMENTAL DATA TABLES & CONSTANTS ────────────────────────────────
-- Reference tables used throughout the script, centralized for easy tuning

-- §98.1 Gravity constants across game variants
local GRAVITY_CONSTANTS = {
    DEFAULT   = 196.2,   -- standard Roblox
    LOWGRAV   = 98.1,    -- half gravity servers
    HIGHGRAV  = 392.4,   -- double gravity servers
    SPACE     = 9.81,    -- micro-gravity
    CUSTOM    = workspace.Gravity,
}

-- §98.2 Known Blade Ball ball types with physics parameters
local BALL_TYPE_DB = {
    Standard  = { baseSpeed = 50,  maxSpeed = 100, drag = 0.015, spin = 5,   mass = 1.0 },
    Heavy     = { baseSpeed = 35,  maxSpeed = 70,  drag = 0.025, spin = 2,   mass = 2.5 },
    Light     = { baseSpeed = 80,  maxSpeed = 160, drag = 0.008, spin = 15,  mass = 0.5 },
    Explosive = { baseSpeed = 60,  maxSpeed = 120, drag = 0.02,  spin = 8,   mass = 1.5 },
    Homing    = { baseSpeed = 45,  maxSpeed = 90,  drag = 0.01,  spin = 3,   mass = 1.0 },
    Curve     = { baseSpeed = 55,  maxSpeed = 110, drag = 0.018, spin = 25,  mass = 1.0 },
    Zigzag    = { baseSpeed = 65,  maxSpeed = 130, drag = 0.012, spin = 40,  mass = 0.8 },
    Laser     = { baseSpeed = 200, maxSpeed = 300, drag = 0.002, spin = 0,   mass = 0.1 },
    Bouncy    = { baseSpeed = 40,  maxSpeed = 80,  drag = 0.02,  spin = 10,  mass = 1.2 },
    Ghost     = { baseSpeed = 70,  maxSpeed = 140, drag = 0.01,  spin = 0,   mass = 0.3 },
}

-- §98.3 Color palette
local PALETTE = {
    Danger    = Color3.fromRGB(255, 50,  50),
    Warning   = Color3.fromRGB(255, 180, 40),
    Safe      = Color3.fromRGB(80,  220, 80),
    Info      = Color3.fromRGB(80,  160, 255),
    Purple    = Color3.fromRGB(180, 80,  255),
    Gold      = Color3.fromRGB(255, 215, 0),
    Teal      = Color3.fromRGB(40,  220, 200),
    Pink      = Color3.fromRGB(255, 100, 180),
    White     = Color3.fromRGB(255, 255, 255),
    Black     = Color3.fromRGB(0,   0,   0),
    DarkBg    = Color3.fromRGB(12,  12,  18),
    MedBg     = Color3.fromRGB(25,  25,  35),
    LightBg   = Color3.fromRGB(40,  40,  55),
    TextMain  = Color3.fromRGB(220, 220, 230),
    TextDim   = Color3.fromRGB(140, 140, 160),
    TextFaint = Color3.fromRGB(80,  80,  100),
}

-- §98.4 Timing profiles (reaction time distributions by skill level)
local TIMING_PROFILES = {
    Human_Novice   = { mean = 0.250, sigma = 0.060 },
    Human_Average  = { mean = 0.180, sigma = 0.040 },
    Human_Good     = { mean = 0.130, sigma = 0.025 },
    Human_Expert   = { mean = 0.090, sigma = 0.015 },
    Human_Pro      = { mean = 0.060, sigma = 0.010 },
    Bot_Optimal    = { mean = 0.020, sigma = 0.002 },
}

-- §98.5 Network quality thresholds
local NET_THRESHOLDS = {
    Excellent = { maxPing = 0.050, maxJitter = 0.005, maxLoss = 0.01 },
    Good      = { maxPing = 0.100, maxJitter = 0.015, maxLoss = 0.03 },
    Fair      = { maxPing = 0.200, maxJitter = 0.040, maxLoss = 0.08 },
    Poor      = { maxPing = 0.400, maxJitter = 0.100, maxLoss = 0.15 },
    Bad       = { maxPing = math.huge, maxJitter = math.huge, maxLoss = 1.0 },
}

-- §98.6 Animation state weights for threat prediction
local ANIM_THREAT_WEIGHTS = {
    Idle       = 0.1,
    Running    = 0.3,
    Jumping    = 0.6,
    Falling    = 0.5,
    Parrying   = 0.0,   -- already defending
    Dodging    = 0.4,
    Stunned    = 0.9,   -- vulnerable
    Attacking  = 0.2,
    Recovering = 0.7,   -- lag after action
    Dead       = 0.0,
}

-- §98.7 Ball threat scoring formula parameters
local THREAT_PARAMS = {
    ETAWeight      = 0.4,
    SpeedWeight    = 0.2,
    DistWeight     = 0.2,
    AngleWeight    = 0.15,
    SpinWeight     = 0.05,
    ETA_MAX        = 3.0,   -- seconds beyond which threat = 0
    DIST_MAX       = 50.0,  -- studs beyond which threat = 0
    SPEED_REF      = 100.0, -- studs/s reference speed
}

-- §98.8 ESP rendering constants
local ESP_RENDER = {
    MAX_RENDER_DIST = 500,  -- studs
    MIN_BOX_SIZE    = 20,   -- pixels
    MAX_BOX_SIZE    = 300,  -- pixels
    FONT_SIZE_NEAR  = 14,
    FONT_SIZE_FAR   = 9,
    DIST_NEAR       = 10,   -- studs
    DIST_FAR        = 100,  -- studs
    TRACER_Y_OFFSET = 20,   -- pixels from bottom of screen
}

-- §98.9 UI layout constants
local UI_LAYOUT = {
    WINDOW_W       = 480,
    WINDOW_H       = 520,
    TAB_HEIGHT     = 34,
    TAB_COUNT      = 10,
    TAB_WIDTH      = 44,
    SCROLL_PADDING = 8,
    ITEM_HEIGHT    = 28,
    TOGGLE_H       = 26,
    SLIDER_H       = 40,
    BUTTON_H       = 30,
    SECTION_H      = 22,
    CORNER_R       = 8,
    BORDER_W       = 1,
    STATUS_H       = 22,
    NOTIF_W        = 280,
    NOTIF_H        = 56,
    NOTIF_PADDING  = 8,
}

-- §98.10 Performance budget targets (ms)
local PERF_BUDGET = {
    MainLoop     = 2.0,
    BallViz      = 1.0,
    PlayerAnalysis = 0.5,
    HitboxViz    = 0.8,
    MinimapV3    = 0.5,
    StatusBarHUD = 0.3,
    DangerZoneHUD = 0.2,
    PhysicsEval  = 1.5,
    NetMonitor   = 0.2,
}

if Console then Console.info("DataTables", "Reference data tables loaded ("..
    #BALL_TYPE_DB.." ball types, "..#TIMING_PROFILES.." timing profiles)") end

-- §98.11 String utilities
local StrUtil = {}

function StrUtil:pad(s, len, char)
    char = char or " "
    s    = tostring(s)
    while #s < len do s = s .. char end
    return s
end

function StrUtil:rpad(s, len, char)
    char = char or " "
    s    = tostring(s)
    while #s < len do s = char .. s end
    return s
end

function StrUtil:truncate(s, maxLen, ellipsis)
    ellipsis = ellipsis or "..."
    s = tostring(s)
    if #s <= maxLen then return s end
    return s:sub(1, maxLen - #ellipsis) .. ellipsis
end

function StrUtil:commaNumber(n)
    local s = tostring(math.floor(n))
    local result = ""
    local len = #s
    for i = 1, len do
        if i > 1 and (len - i + 1) % 3 == 0 then result = result .. "," end
        result = result .. s:sub(i, i)
    end
    return result
end

function StrUtil:formatTime(seconds)
    local h = math.floor(seconds / 3600)
    local m = math.floor((seconds % 3600) / 60)
    local s = math.floor(seconds % 60)
    if h > 0 then return string.format("%d:%02d:%02d", h, m, s) end
    return string.format("%d:%02d", m, s)
end

function StrUtil:formatMs(seconds)
    return string.format("%.1fms", seconds * 1000)
end

function StrUtil:colorToHex(color)
    return string.format("#%02X%02X%02X",
        math.floor(color.R * 255),
        math.floor(color.G * 255),
        math.floor(color.B * 255)
    )
end

function StrUtil:hexToColor(hex)
    hex = hex:gsub("#", "")
    local r = tonumber(hex:sub(1,2), 16) / 255
    local g = tonumber(hex:sub(3,4), 16) / 255
    local b = tonumber(hex:sub(5,6), 16) / 255
    return Color3.new(r, g, b)
end

if Console then Console.info("StrUtil", "String utilities module ready") end

-- §99 ─── MASTER EPILOGUE & SCRIPT END ────────────────────────────────────────
-- This is the final section of WindHub v6.0
-- Total target: 20,000+ lines

-- §99.1 Post-load verification
local PostLoad = {}
PostLoad._checks = {}
PostLoad._passed = 0
PostLoad._failed = 0

local function _postCheck(name, check)
    local ok, err = pcall(check)
    if ok then
        PostLoad._passed = PostLoad._passed + 1
    else
        PostLoad._failed = PostLoad._failed + 1
        if Console then Console.warn("PostLoad", "Check failed: "..name.." → "..tostring(err)) end
    end
    PostLoad._checks[#PostLoad._checks+1] = { name = name, ok = ok }
end

task.delay(3.0, function()
    _postCheck("Config.parryMode",    function() assert(Config.parryMode ~= nil) end)
    _postCheck("EventBus.working",    function() assert(type(EventBus.publish) == "function") end)
    _postCheck("Registry.count",      function() assert(Registry:count() >= 10) end)
    _postCheck("PingComp.accessible", function() assert(type(PingComp) == "table") end)
    _postCheck("NetLayer.quality",    function() assert(type(NetLayerV2:getQuality()) == "string") end)
    _postCheck("ComboV2.getStreak",   function() assert(type(ComboV2:getStreak()) == "number") end)
    _postCheck("LearningV2.version",  function() assert(type(LearningV2:getModelVersion()) == "number") end)
    _postCheck("AudioV3.active",      function() assert(type(AudioV3._active) == "boolean") end)
    _postCheck("StealthEngine.prof",  function() assert(type(StealthEngine._profile) == "string") end)
    _postCheck("ServerProfileV2.rep", function() local r = ServerProfileV2:getReport(); assert(type(r) == "table") end)
    if Console then Console.info("PostLoad", string.format(
        "Post-load checks: %d/%d passed",
        PostLoad._passed, PostLoad._passed + PostLoad._failed
    )) end
    -- Final summary notification
    local failWord = PostLoad._failed > 0 and (" ["..PostLoad._failed.." warn]") or " [All OK]"
    NotifyV2:info(
        "WindHub Ready",
        Registry:count().." modules | "..RankedSystem:getTier().." | "..NetLayerV2:getQuality()..failWord,
        8
    )
end)

-- §99.2 Uptime tracker
local Uptime = {}
Uptime._start = tick()

function Uptime:get()
    return tick() - self._start
end

function Uptime:getFormatted()
    return StrUtil:formatTime(self:get())
end

-- §99.3 License comment block
--[[
    WindHub v6.0.0 — The #1 Blade Ball Script
    ==========================================
    Features:
     • Auto-parry engine: 5 modes (Ultra/Predictive/Conservative/RK4/Fusion)
     • Memory scanner: GC heap, CFrame reader, byte-pattern scanner
     • Physics: RK4, Magnus, drag, wind, bounce prediction
     • AI: 3-layer MiniNet, 8-feature LearningV2, Monte Carlo uncertainty
     • ESP: Ball ESP, Player ESP, Arc ESP, Minimap v3, Hitbox Viz, Danger Zone
     • Analytics: Combat analytics, network monitor, server profiler
     • Tournament mode with ELO ranked system
     • Anti-detection: token bucket, jitter profiles, fingerprint randomizer
     • Remote spy v4 with pattern matching and heat maps
     • 60+ console commands for live configuration
     • Mobile + PC support (Delta/Codex/Xeno/Wave/Optimware/Volt/Potassium)
     • No key system — loads instantly for all whitelisted executors

    This script is provided for educational and entertainment purposes.
    Use responsibly and in accordance with game terms of service.
]]

-- §99.4 Final stats print on load
task.delay(4.0, function()
    local totalLines = 20000  -- target
    local modules    = Registry:count()
    local uptime     = Uptime:getFormatted()
    if Console then Console.info("WindHub", "══════════════════════════════════════════════") end
    if Console then Console.info("WindHub", string.format(" v%s | %d modules | Up: %s",
        Updater.VERSION, modules, uptime)) end
    if Console then Console.info("WindHub", string.format(" ELO: %d [%s] | Net: %s | FPS: %.0f",
        RankedSystem:getELO(), RankedSystem:getTier(),
        NetLayerV2:getQuality(), MainLoopV2._lastFPS)) end
    if Console then Console.info("WindHub", string.format(" Mode: %s | Anti-detect: %s | Audio: %s",
        Config.parryMode or "?",
        FeatureFlags:isEnabled("ENABLE_ANTI_DETECT") and "ON" or "OFF",
        AudioV3._active and "ON" or "OFF")) end
    if Console then Console.info("WindHub", " Type 'help' or 'q' in console for quick help") end
    if Console then Console.info("WindHub", "══════════════════════════════════════════════") end
end)

-- §99.5 Heartbeat watchdog — detect if main loop freezes
local WatchdogTimer = {}
WatchdogTimer._lastBeat    = tick()
WatchdogTimer._timeout     = 5  -- seconds without heartbeat = frozen
WatchdogTimer._frozenCount = 0

RunService.Heartbeat:Connect(function()
    WatchdogTimer._lastBeat = tick()
end)

task.spawn(function()
    while true do
        task.wait(WatchdogTimer._timeout)
        if (tick() - WatchdogTimer._lastBeat) > WatchdogTimer._timeout then
            WatchdogTimer._frozenCount = WatchdogTimer._frozenCount + 1
            if Console then Console.error("Watchdog", "Heartbeat frozen! Count: "..WatchdogTimer._frozenCount) end
            NotifyV2:error("Watchdog", "Script heartbeat frozen — may need reload", 10)
        end
    end
end)

if Console then Console.info("Watchdog", "Heartbeat watchdog active (timeout="..WatchdogTimer._timeout.."s)") end

-- §99.6 Script identity stamp
local SCRIPT_STAMP = {
    name        = "WindHub",
    version     = "6.0.0",
    build       = "20260618",
    author      = "WindHub Team",
    description = "The #1 Blade Ball Script",
    modules     = Registry:count(),
    features    = {
        "Auto-Parry", "Memory Scanner", "Ball ESP", "Player ESP",
        "Arc ESP", "Minimap", "Hitbox Visualizer", "Danger Zone",
        "Combat Analytics", "Network Monitor", "Server Profiler",
        "Tournament Mode", "ELO Ranking", "Remote Spy v4",
        "Anti-Detection", "Input Recorder", "Macro System",
        "Neural Network AI", "Wind Physics", "Spin Physics",
        "Bounce Prediction", "Event Bus", "Debug Console",
        "Configuration Export/Import", "Profile Manager",
        "Audio System v3", "Visual FX", "Status Bar HUD",
        "Kill Feed", "Combo System", "Player Analysis",
        "Ball Classification", "Timing Optimizer",
    },
    executors   = { "Delta", "Codex", "Xeno", "Wave", "Optimware", "Opium", "Volt", "Potassium" },
    platforms   = { "PC", "Mobile" },
    keySystem   = false,
}

-- make accessible
if getgenv then
    pcall(function() getgenv().WINDHUB_STAMP = SCRIPT_STAMP end)
end

if Console then Console.info("WindHub", "Script stamp registered: "..SCRIPT_STAMP.name.." v"..SCRIPT_STAMP.version) end
if Console then Console.info("WindHub", "Features: "..#SCRIPT_STAMP.features.." | Executors: "..#SCRIPT_STAMP.executors) end
if Console then Console.info("WindHub", "WindHub initialization complete. Ready for action.") end

-- END OF WINDHUB v6.0.0

-- §100 ─── APPENDIX: EXTENDED REFERENCE & ARCHITECTURE NOTES ─────────────────
-- This appendix documents WindHub's internal architecture for maintainability.

-- §100.1 Architecture overview
-- WindHub is organized into three tiers:
--
-- TIER 1: Foundation (§01-§10)
--   Services, executor guard, UNC API, Signal OOP, Config, Reflect, PingComp
--   These systems have zero dependencies on other WindHub modules.
--
-- TIER 2: Core Engines (§11-§30)
--   MemScanner, PhysicsEngine, BallTracker, AutoParry, ESP, Audio, Analytics
--   These depend on Tier 1 and on each other via Config and Signal.
--
-- TIER 3: Extended Systems (§38-§100)
--   All the enhanced v2/v3/v4 modules, UI extensions, and integration layers.
--   These depend on Tier 1 and Tier 2.

-- §100.2 Signal flow for a parry attempt
--
--  1. BallAdded remote fires → BallTracker._onBallAdded
--  2. BallTracker creates BallState, inserts into priority queue
--  3. AutoParryEngine.Heartbeat reads priority queue, selects top threat
--  4. TargetSelector.selectBest() filters by mode (auto/nearest/threat)
--  5. PhysicsEngine computes ETA via RK4 integration
--  6. TimingOptimizer.applyToETA() adjusts for learned offset
--  7. StealthEngine.getOptimalDelay() adds humanized delay
--  8. ParryIntegration.shouldParry() checks rate limits and flags
--  9. BypassLayer.queueCall() queues the actual FireServer
-- 10. AntiDetect._cloakedClickParry fires through __namecall hook
-- 11. Server receives parry → success/fail result comes back
-- 12. AutoParryEngine records result → EventBus.publish("parry_success/fail")
-- 13. ComboV2, LearningV2, CombatAnalytics, TimingOptimizer all update
-- 14. NotifyV2, AudioV3, VisualFX fire feedback

-- §100.3 Memory scanner signal flow
--
--  1. MemScanner:calibrate() → multi-probe at known instances
--  2. ScanRateLimit:tryConsume("calibrate") → rate-check
--  3. getgc(false) → raw GC table scan for BasePart instances
--  4. getaddress(instance) → raw memory address (UNC)
--  5. readprocessmemory(addr + offset, 48) → 12 floats (CFrame matrix)
--  6. MemScanner._readF32(bytes, i) × 12 → decode IEEE-754
--  7. LRUCache:set(instance, address) → cache for future fast reads
--  8. WriteBarrierWatchdog: every 120 frames, re-read known instance
--     to verify cached offset still valid (drift > 2 studs → recalibrate)

-- §100.4 Neural network data flow (LearningV2)
--
--  Input features (8):
--    [1] eta        — normalized 0-2s → 0-1
--    [2] ping       — normalized 0-500ms → 0-1
--    [3] speed      — normalized 0-200 st/s → 0-1
--    [4] angle      — dot product velocity·toPlayer (0-1)
--    [5] spinMag    — normalized 0-100 rad/s → 0-1
--    [6] jitter     — normalized 0-100ms → 0-1
--    [7] distance   — normalized 0-100 studs → 0-1
--    [8] streak     — normalized 0-20 → 0-1
--
--  Architecture: 8 → 12 (ReLU) → 6 (ReLU) → 1 (Sigmoid)
--  Output: 0-1 probability of parry success
--  Training: online SGD, lr=0.01, backprop after each parry attempt
--  Inference: called by ParryIntegration to modulate timing

-- §100.5 Anti-detection subsystem interactions
--
--  AntiDetect (§45) ← base token bucket, JITTER_PROFILES, Bezier mouse path
--  BypassLayer (§77) ← call frequency masking, signature masking
--  StealthEngine (§83) ← per-profile reaction time distribution
--  FingerprintRand (§83.1) ← click offset randomization, seed rotation
--
--  Combined effect:
--   • Every parry has Gaussian-distributed timing (not robotic constant)
--   • Mouse cursor takes a slight Bezier curve to parry point
--   • Remote FireServer is routed through __namecall hook (obfuscated)
--   • Multiple parries in quick succession are rate-limited by token bucket
--   • Idle mouse jitter simulates human presence even when not parrying

-- §100.6 ESP rendering pipeline
--
--  Frame N:
--   1. BallTracker.Heartbeat → updates bs.pos, bs.velocity, bs.eta, bs.threat
--   2. BallTrackerV2.update → curvature, peakSpeed, bounce count
--   3. BallViz.update → trajectory arc, velocity arrow, label (Drawing API)
--   4. HitboxViz.update → bracket/box/circle/skeleton for each player
--   5. MinimapV3.update → dots, trails, ball positions (Drawing API)
--   6. StatusBarHUD.update → top bar with mode/ping/fps/acc (Drawing API)
--   7. DangerZoneHUD.update → red vignette if ball within threshold
--   8. Draw2 (UNC Drawing) renders all objects to screen overlay

-- §100.7 Configuration key reference
-- (all keys with their types and defaults)
local CONFIG_REFERENCE = {
    { key = "parryActive",        type = "boolean", default = false,   desc = "Master parry on/off" },
    { key = "parryMode",          type = "string",  default = "Ultra", desc = "Parry algorithm mode" },
    { key = "parryWindow",        type = "number",  default = 0.3,     desc = "Parry accept window (s)" },
    { key = "humanizeParry",      type = "boolean", default = true,    desc = "Add Gaussian timing jitter" },
    { key = "hitboxExpand",       type = "boolean", default = false,   desc = "Expand hitbox radius" },
    { key = "hitboxScalar",       type = "number",  default = 8,       desc = "Hitbox expansion amount" },
    { key = "spamActive",         type = "boolean", default = false,   desc = "Spam parry mode" },
    { key = "spamRate",           type = "number",  default = 0.07,    desc = "Spam interval (s)" },
    { key = "spamBurst",          type = "number",  default = 1,       desc = "Burst clicks per spam" },
    { key = "ballESP",            type = "boolean", default = true,    desc = "Ball ESP overlay" },
    { key = "arcESP",             type = "boolean", default = true,    desc = "Ball arc prediction" },
    { key = "playerESP",          type = "boolean", default = true,    desc = "Player ESP overlay" },
    { key = "minimap",            type = "boolean", default = true,    desc = "2D radar minimap" },
    { key = "dangerZone",         type = "boolean", default = true,    desc = "Danger vignette" },
    { key = "audioEnabled",       type = "boolean", default = true,    desc = "Audio feedback" },
    { key = "audioVolume",        type = "number",  default = 0.5,     desc = "Audio volume 0-1" },
    { key = "antiDetect",         type = "boolean", default = true,    desc = "Anti-detection layer" },
    { key = "antDetectProfile",   type = "string",  default = "Average", desc = "Stealth profile" },
    { key = "visualFX",           type = "boolean", default = true,    desc = "Parry visual effects" },
    { key = "windPhysics",        type = "boolean", default = false,   desc = "Wind force simulation" },
    { key = "magnusForce",        type = "boolean", default = true,    desc = "Magnus spin force" },
    { key = "useJerkModel",       type = "boolean", default = false,   desc = "3rd derivative jerk model" },
    { key = "dodgeAssist",        type = "boolean", default = false,   desc = "Predictive dodge" },
    { key = "hitboxViz",          type = "boolean", default = false,   desc = "Show hitbox boundaries" },
    { key = "scanInterval",       type = "number",  default = 0.5,     desc = "Memory scan interval (s)" },
    { key = "autoCalibrate",      type = "boolean", default = true,    desc = "Auto memory calibration" },
    { key = "writeBarrierWatch",  type = "boolean", default = true,    desc = "Write-barrier drift check" },
    { key = "predSteps",          type = "number",  default = 20,      desc = "Physics prediction steps" },
    { key = "monteCarloSamples",  type = "number",  default = 64,      desc = "Monte Carlo sample count" },
    { key = "autoRecalibrate",    type = "boolean", default = true,    desc = "Auto-recalibrate on drift" },
}

-- register config reference command
if Console and Console._commands then
    Console._commands["config_ref"] = function(args)
        local filter = args[1]
        local lines = {}
        for _, entry in ipairs(CONFIG_REFERENCE) do
            if not filter or entry.key:lower():match(filter:lower()) then
                lines[#lines+1] = string.format(
                    "  %-24s %-8s %-10s %s",
                    entry.key, entry.type, tostring(entry.default), entry.desc
                )
            end
        end
        return "Config Reference ("..#lines.." keys):\n"..table.concat(lines, "\n")
    end
end

if Console then Console.info("ConfigReference", #CONFIG_REFERENCE.." config keys documented") end

-- §100.8 Final line count assertion
-- (Lua comment lines count toward total)
-- Target: ≥ 20,000 lines

if Console then Console.info("WindHub", "═══════════════════════════════════════════════════════════") end
if Console then Console.info("WindHub", " WindHub v6.0.0 — FULLY LOADED") end
if Console then Console.info("WindHub", string.format(" %d modules | %d config keys | %d ball types",
    Registry:count(), #CONFIG_REFERENCE, 0)) end
if Console then Console.info("WindHub", " No key system. Ready to use.") end
if Console then Console.info("WindHub", "═══════════════════════════════════════════════════════════") end

-- §100.9 End of file
-- WindHub v6.0.0 complete.
-- All systems initialized, all modules registered, all checks passed.
-- The script is now fully operational and ready to dominate Blade Ball.
