-- Anime Ball Hub - Auto Parry / Auto Spam  (WindUI)
-- Requires: ReplicatedStorage.Framework.RemoteFunction ("SwordService","Block",{camLookY})
-- Requires: workspace.Balls (folder of ball parts/models) and workspace[Player.Name].Highlight

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local Stats = game:GetService("Stats")
local LocalPlayer = Players.LocalPlayer

-- ============================================
-- UNLOAD / KILL-SWITCH INFRASTRUCTURE
-- ============================================
-- Every event connection and background loop this script starts is registered
-- so a single Unload() tears the whole thing down cleanly: it disconnects both
-- Heartbeat loops and the cache hooks, stops the background threads, restores
-- the one game function we monkey-patch, removes every Instance we spawn
-- (detection spheres, speed labels) and closes the UI. Without it the only way
-- to stop the script was to rejoin, and re-executing it stacked a second copy.
local activeConnections = {}   -- RBXScriptConnections to drop on unload
local destroyed = false        -- background loops/hooks check this to go inert
local mainLoopConn = nil       -- the per-frame parry Heartbeat (disconnected on unload)
local moveGuardConn = nil      -- the walk-speed guard Heartbeat
local unloadScript             -- forward decl; body defined once everything exists
local ballColorController = nil -- BallController we patch (kept so we can restore it)
local ballColorOriginal = nil   -- its original ChangeBallColor
local swordController = nil     -- SwordController we patch for BlockSuccess
local blockSuccessOriginal = nil
local function track(conn)
    if conn then table.insert(activeConnections, conn) end
    return conn
end

-- Re-exec guard: if a previous copy is still loaded, unload it first so we never
-- stack two UIs / two sets of Heartbeat loops. No-op on executors without getgenv.
if getgenv then
    local okEnv, genv = pcall(getgenv)
    if okEnv and type(genv) == "table" then
        local prev = genv.AnimeBallHubUnload or genv.AnimeBallUnload
        if type(prev) == "function" then pcall(prev) end
    end
end

-- ============================================
-- UI LIBRARY: WindUI (Footagesus)
-- ============================================
-- Real WindUI, fetched from its official release (with a mirror fallback).
-- Executor-agnostic fetch: reuse a loader-provided HttpGet when present, else
-- try game:HttpGet, else every common request() entry point.
local WINDUI_URLS = {
    "https://github.com/Footagesus/WindUI/releases/latest/download/main.lua",
    "https://raw.githubusercontent.com/Footagesus/WindUI/main/dist/main.lua",
}
local _genv = (getgenv and getgenv()) or {}
local function _httpGet(url)
    if type(_genv.LeviathanHttpGet) == "function" then
        local okL, b = pcall(_genv.LeviathanHttpGet, url)
        if okL and type(b) == "string" and #b > 0 then return b end
    end
    local ok, body = pcall(function() return game:HttpGet(url, true) end)
    if ok and type(body) == "string" and #body > 0 then return body end
    local req = (syn and syn.request) or (http and http.request) or http_request or request
        or (fluxus and fluxus.request) or _genv.request
    if req then
        local okr, r = pcall(req, { Url = url, Method = "GET" })
        if okr and type(r) == "table" and type(r.Body) == "string" and #r.Body > 0 then return r.Body end
    end
    return nil
end
local _loadstring = loadstring or _genv.loadstring
local WindUI, windErr = nil, "no source"
for _, url in ipairs(WINDUI_URLS) do
    local ok, lib = pcall(function()
        local src = _httpGet(url)
        if not src then error("download failed") end
        local fn, cerr = _loadstring(src)
        if not fn then error(cerr) end
        return fn()
    end)
    if ok and type(lib) == "table" then WindUI = lib break end
    windErr = lib
end
if not WindUI then
    pcall(function()
        game:GetService("StarterGui"):SetCore("SendNotification", {
            Title = "Anime Ball Hub", Text = "WindUI failed to load: " .. tostring(windErr), Duration = 8,
        })
    end)
    return warn("[Anime Ball Hub] WindUI failed to load: " .. tostring(windErr))
end

-- Notifications are suppressed until the UI is fully built: some WindUI builds
-- fire each Toggle's callback once on creation, which used to spam a stack of
-- "Enabled" toasts on every load.
local uiReady = false
local function notify(title, content, duration)
    if not uiReady then return end
    pcall(function()
        WindUI:Notify({ Title = title, Content = content, Duration = duration or 3 })
    end)
end

-- Paragraph text setter that can never throw. HUD writes happen inside the
-- parry Heartbeat BEFORE the block decision; an error there (a missing SetDesc
-- on some WindUI build, a destroyed element after unload) used to abort the
-- whole frame and silently skip the parry. Also skips redundant writes.
local hudCache = setmetatable({}, { __mode = "k" })
local function setDesc(el, text)
    if not el or hudCache[el] == text then return end
    hudCache[el] = text
    pcall(function() el:SetDesc(text) end)
end

-- ============================================
-- SETTINGS PERSISTENCE (own JSON file)
-- ============================================
-- WindUI's ConfigManager API differs between releases (the old code mixed
-- :Config and :CreateConfig and never registered elements, so Save/Load did
-- nothing or errored). We persist our own settings table instead and load it
-- BEFORE the UI is built, so every element simply starts at the saved value.
local HttpService = game:GetService("HttpService")
local CONFIG_FOLDER = "AnimeBallHub"
local CONFIG_FILE = CONFIG_FOLDER .. "/settings.json"
local Settings = {}
local function fsOk() return type(writefile) == "function" and type(readfile) == "function" end
local function loadSettings()
    if not fsOk() then return false end
    local ok, data = pcall(function()
        if type(isfile) == "function" and not isfile(CONFIG_FILE) then return nil end
        return HttpService:JSONDecode(readfile(CONFIG_FILE))
    end)
    if ok and type(data) == "table" then
        for k, v in pairs(data) do Settings[k] = v end
        return true
    end
    return false
end
local lastSavedJson = nil
local function saveSettings()
    if not fsOk() then return false end
    local ok = pcall(function()
        local json = HttpService:JSONEncode(Settings)
        if json == lastSavedJson then return end
        if type(isfolder) == "function" and type(makefolder) == "function" and not isfolder(CONFIG_FOLDER) then
            makefolder(CONFIG_FOLDER)
        end
        writefile(CONFIG_FILE, json)
        lastSavedJson = json
    end)
    return ok
end
-- Saved value for `key` if it has the right type, else `default`.
local function setting(key, default)
    local v = Settings[key]
    if type(v) == type(default) then return v end
    return default
end
loadSettings()
-- Debounced auto-save: any change marks dirty; a background loop writes it once.
local settingsDirty = false
local function setSetting(key, value)
    Settings[key] = value
    settingsDirty = true
end

-- "Crimson Clash" color theme
local AccentRed = Color3.fromHex("#DC143C") -- true crimson
local Gold = Color3.fromHex("#FFC107")
local Emerald = Color3.fromHex("#34D399")
local Amber = Color3.fromHex("#FFD84D")

-- ============================================
-- AUTO PARRY CONFIGURATION
-- ============================================

local MIN_DISTANCE = 8      -- even a slow ball gets a real engagement bubble (was 1.5)
local MAX_DISTANCE = 130    -- lock onto fast balls further out so it reacts sooner (was 100)
local UPDATE_INTERVAL = 0 -- run every Heartbeat frame
local PARRY_COOLDOWN = 0.3
local HIGH_SPEED_THRESHOLD = 50   -- studs/s; from live telemetry: real ball speed runs ~29 median / 50 p90 / 57-143 peak (ability balls). The old 300 never triggered, so high-speed mode (max detection range) was effectively dead. 50 = the p90, where a ball is genuinely "fast".
local PLAYER_DETECTOR_DISTANCE = 17

local autoParryEnabled = true
local currentParryDistance = 34
local targetParryDistance = 34
local lastParryTime = 0
local lastDistanceUpdate = 0
local isAutoParryFrozen = false
local frozenParryDistance = 34
local isHighSpeedMode = false
local showVisualSphere = true
local showPlayerDetectors = true
local showSpeedLabel = true
local totalParries = 0
local highSpeedParries = 0

-- The parry DECISION runs every Heartbeat frame (never throttled), but the
-- on-screen status text does not need to. Formatting these big status strings
-- and writing UI text every frame - up to 240Hz on a high-refresh client - is
-- pure overhead with no gameplay effect: a human can't perceive a status
-- refreshing faster than ~15Hz. Refresh the display at a fixed cadence so the
-- hot loop spends its time on detection, not on string.format.
local HUD_REFRESH_INTERVAL = 1 / 15
local lastHudRefresh = 0

-- ============================================
-- PING COMPENSATION / FUTURE PREDICTION CONFIGURATION
-- ============================================
-- With high ping the server "sees" you later than your screen shows. To still
-- block in time we parry as soon as the ball's predicted time-to-impact drops
-- below our round-trip latency window, i.e. we look `leadTime` seconds into
-- the future (leadTime = ping * pingMultiplier, capped by PredictionHorizon).
-- Only the *closing* component of the ball's velocity (the part actually
-- headed at the player) is used, so a ball flying past you no longer
-- triggers an early parry.

local pingCompEnabled = true
local pingAutoEnabled = true      -- auto-tune the strength from your live ping instead of the manual slider
local pingMultiplier = 1.0        -- manual strength (used only when Auto is OFF): 1.0 = full ping
local MAX_PING_COMP = 60          -- cap on extra studs so it never over-extends absurdly
local predictionHorizon = 1.5     -- max seconds of look-ahead allowed (0 - 5s)
local currentPing = 0             -- last measured round-trip ping in ms
local smoothedPing = 0            -- exponentially-smoothed ping so comp changes gradually, never jerks
local currentPingComp = 0         -- last computed extra studs of detection range
local currentAutoMult = 1.0       -- last effective multiplier chosen by Auto mode
local currentTimeToImpact = math.huge
local currentRequiredLead = 0
local PING_SMOOTHING = 0.1        -- 0-1; how fast smoothedPing chases the raw ping (low = smoother)

-- Client-side frame-lag compensation. Ping comp covers NETWORK latency, but a
-- laggy client (frame stutter / low FPS) is a SEPARATE problem: if your frames
-- are 100ms apart, the parry decision is made up to a full frame late relative
-- to where the ball really is, and you can die during the freeze before the
-- next frame ever runs. So we measure the real frame time and, on a laggy
-- client, fire that much EARLIER - the last frame before a stutter still sends
-- the block. Tracked as a decaying max because lag is bursty: one 150ms hitch
-- matters even when the average frame time looks fine.
local frameLag = 0                -- decaying-max estimate of local frame time (seconds)
local FRAME_LAG_CAP = 0.3         -- max seconds of frame-lag comp to apply (beyond this the client is basically frozen and nothing helps)
local lastFrameClock = 0

-- Anti-curve: the ball's velocity vector alone only predicts a straight
-- line, which misses curving/homing balls entirely. We also track the
-- ball's acceleration (rate of change of velocity between frames) and
-- simulate the resulting curved arc forward, instead of assuming it keeps
-- going in whatever direction it's pointed right now.
local antiCurveEnabled = true
local ACCEL_SMOOTHING = 0.35      -- 0-1, higher = react faster to new curvature, lower = smoother/less jittery
local CURVE_SIM_STEPS = 20        -- samples taken along the predicted arc, up to predictionHorizon seconds out
local MAX_CURVE_ACCEL = 150       -- studs/s^2 cap; a parry flips ball velocity in one frame, which would otherwise read as a huge fake curve. Live telemetry: real curve accel peaks ~98 (avg 12). 150 leaves headroom for hard-curve abilities not in that sample, while still sitting far below the thousands-magnitude parry-bounce spikes it exists to reject. (Old 400 was ~4x too loose.)
local MAX_TURN_RATE = 12          -- rad/s cap on the ball's velocity-vector rotation ("curve angle" rate). Real homing curves top out near a_perp/speed ~= 98/29 ~= 3.4 rad/s; 12 leaves headroom for sharper abilities while rejecting parry/bounce direction flips (a ~180 deg reversal in one 60fps frame reads as ~188 rad/s), which must NOT be modelled as sustained turning.
local currentCurveAccel = 0       -- last measured curve (lateral acceleration) magnitude, studs/s^2
local currentTurnRate = 0         -- last measured turn rate (velocity-vector rotation) in rad/s

-- Panic Burst: the single executeParry() + 0.3s cooldown is exactly what
-- loses to super-fast/curving balls - one block fires (sometimes early, on
-- prediction), and if it whiffs the cooldown eats the real parry while the
-- ball crosses the last gap in under 0.2s. When predicted time-to-impact
-- drops below the panic window, fire block every frame (bypassing the
-- cooldown) until the ball is deflected - same spam the game already
-- tolerates from Auto Spam.
-- Real timing from the game's SwordInfo module: a block lasts BLOCK_DURATION
-- (0.6s of protection) and can only be re-cast once per second (the server
-- enforces that 1s cooldown, so per-frame spam beyond it is simply ignored -
-- harmless). The panic window must stay <= BLOCK_DURATION: fire any earlier
-- and the 0.6s protection expires before the ball actually arrives.
local BLOCK_DURATION = 0.6
-- Server block cooldown (game's SwordInfo DefaultCooldown): after a block lands
-- you can't block again for this long unless a successful parry resets it.
local DefaultCooldown = 1.0
-- The ball connects with you before its CENTER reaches your center - it has a
-- hit radius. The game's own BallController tutorial reveals the exact value:
-- it counts the ball as arriving when (distance - 8) / ballSpeed <= 0.6, i.e.
-- a ball is "on you" at ~8 studs of center-to-center distance, and its block
-- threshold is BLOCK_DURATION. We mirror that 8-stud radius so every
-- time-to-impact estimate reflects when the ball SURFACE hits, not its center
-- - otherwise we chronically under-estimate how soon impact lands.
local BALL_HIT_RADIUS = 8
-- The ball collides with your WHOLE avatar - any body part (an outstretched
-- arm, a leg, the head, the torso edge), not just the HumanoidRootPart center
-- we measure distance from. So the ball effectively reaches you a
-- character-radius SOONER than a center-to-center measure says; measuring only
-- to the HRP chronically over-estimates how much time you have, and the block
-- times for the center while the ball already clipped a limb ("it misses").
-- Fold the avatar's half-extent into every impact estimate so the block fires
-- when the ball meets your avatar's EDGE. ~3 studs ~= a standard character's
-- reach from HRP center to an arm/leg/torso surface. Erring larger only fires a
-- touch earlier (the 0.6s block still covers it), so it's the safe direction.
local PLAYER_HIT_RADIUS = 3
-- Combined ball+avatar contact radius: the ball is "on you" when its centre is
-- within this of your HRP centre. Precomputed as one value so the hot loop
-- references a single constant (keeps the big Heartbeat closure under Lua 5.1's
-- 60-upvalue cap).
local EFFECTIVE_HIT_RADIUS = BALL_HIT_RADIUS + PLAYER_HIT_RADIUS
local panicBurstEnabled = true
-- s; TTI below this triggers per-frame block spam. Deliberately LESS than
-- BLOCK_DURATION (0.6): the server's 1s cooldown means only the FIRST block in
-- the burst registers, so its protection window is [impact - PANIC_TTI, impact
-- - PANIC_TTI + 0.6]. At 0.6 that window ends exactly at impact (zero margin -
-- any latency/jitter and the block expires a hair too early = miss). At 0.45 the
-- ball lands with 0.15s of protection still left, absorbing latency/jitter. Ping
-- compensation adds currentRequiredLead on top for high ping.
local PANIC_TTI = 0.45
local totalBurstBlocks = 0

-- Block-result telemetry. SwordService.Block:Invoke returns the server's verdict
-- (truthy = the block landed/was accepted, falsy = rejected, typically because
-- you're still on the 1s cooldown). We were discarding it; capturing it is the
-- ground truth for WHY a ball got through - accepted-but-still-hit vs
-- rejected-on-cooldown vs never-sent.
-- Return values, verified against the decompiled SwordController.Block:
--   nil   -> server REJECTED the block (cooldown / no sword) - no shield
--   false -> block ACCEPTED, shield is up (a parry may follow via BlockSuccess)
--   true  -> block parried a ball instantly (cooldown reset)
-- The old code counted `false` as "rejected", so the land rate read ~0% and the
-- unstick watchdog thought every normal block had failed.
local blockSent = 0        -- total Block:Invoke calls that completed
local blockLanded = 0      -- accepted (false or true): a shield went up
local blockRejected = 0    -- nil: refused (cooldown / no sword)
local blockParried = 0     -- confirmed parries (instant true + server BlockSuccess)
local lastBlockResult = "-" -- "shield" / "parried" / "rejected" / "error"

-- Stuck-block self-heal. A block can get "stuck" - we keep firing at a ball
-- that's targeting us and in range, yet nothing lands: the service proxy went
-- stale, an internal latch (isAutoParryFrozen / the parry cooldown) jammed, or a
-- block left the character rooted. Since the game's block is time-bounded (0.6s
-- protection, 1s cooldown), a sustained "on you but no block landing" window is
-- the signature of a stuck client state, not normal play. A light watchdog
-- watches for exactly that and unsticks it (re-fetch the proxy, clear the
-- latches, restore WalkSpeed) so parrying resumes. All recovery actions are
-- harmless resets, so a rare false trigger costs nothing.
local autoUnstick = true
local totalUnsticks = 0
local UNSTICK_TIMEOUT = 1.0 -- s of "ball on you, firing, nothing landing" before we heal

-- ============================================
-- AUTO SPAM CONFIGURATION
-- ============================================

local SPAM_DETECTION_DISTANCE = 34.3
-- Fires every single Heartbeat frame, uncapped, for as long as the clash
-- holds - no duration limit, so a clash can be held indefinitely (an hour+)
-- without the loop giving up.
local autoSpamEnabled = true
local spamStarted = false
local totalSpams = 0
local spamDuration = 0
local lastSpamStartTime = 0

-- Smart clash detection: proximity alone (player near + ball near +
-- highlight) can't tell "clashing" apart from "jumping around next to
-- someone", and jump-clashing can stretch those checks enough to drop the
-- spam mid-clash. The actual physical signature of a clash is the ball
-- rapidly REVERSING direction as it ping-pongs between the two players, so
-- that's what we detect: velocity reversals within a sliding time window.
-- Entering the clash requires the highlight (proof you're a participant,
-- not a bystander next to someone else's clash); staying in it only
-- requires the reversals to continue, so highlight flicker between the two
-- clashers or jump-stretched distances can't break the hold.
-- Bundled into one table so the big Heartbeat closure captures a single
-- upvalue instead of seven (Lua 5.1 caps a function at 60 upvalues).
local Clash = {
    enabled = true,
    WINDOW = 1.2,        -- seconds; reversals are counted inside this sliding window
    MIN_FLIPS = 2,       -- reversals needed inside the window to call it a clash
    MIN_SPEED = 10,      -- studs/s; ignore direction jitter of a near-stationary ball
    flipTimes = {},
    lastVelBall = nil,   -- ball the last stored velocity belongs to
    lastVelVec = nil,
    -- Clash-hold grace: the game clears/re-sets workspace.Effects.ClashEffect as
    -- the ball changes hands each exchange, so the authoritative signal can blink
    -- off for a frame or two mid-clash. Without a hold, force-firing stops in that
    -- gap and a fast return sneaks through - dropping the clash. Once a real clash
    -- is seen we keep force-firing for GRACE seconds past the last true reading,
    -- so a momentary flicker can never break the clash. Re-armed every frame the
    -- signal is genuinely on, so it only ends when the clash actually ends.
    -- Widened to 0.8s because a CURVING clash ball arcs OUT of your parry radius
    -- (dropping withinRange/ClashEffect) for longer than a flicker before it
    -- curves back into you - the shorter 0.4s hold lapsed mid-arc and the return
    -- landed unblocked ("clash curve loses"). 0.8 covers a full curve arc; the
    -- extra held blocks are harmless (server gates the cooldown).
    GRACE = 0.8,
    forceUntil = 0,
    -- Server clash state captured straight from ClashController.Server.
    -- StartClash / EndClash (see the client game fixes). The game only sets its
    -- own ClashEffect attributes when your "Clash" VISUAL setting is on and
    -- the map has a BallSpawn, so on its own that signal is often dead.
    server = false,
}

-- Keep-moving guard: firing block used to yield the main thread on every
-- parry (a full ping round-trip stall = felt movement stutter); that's fixed
-- by firing block in its own thread (fireBlockRemote). This table additionally
-- restores WalkSpeed if the game zeroes it while blocking, so a block can
-- never leave you rooted. Bundled so a dedicated connection captures one
-- upvalue. cachedSpeed learns the game's real walk speed (last non-zero seen).
local Move = { keep = true, cachedSpeed = 16 }

-- Dash awareness: a SuperDash flings the character fast for a fraction of a
-- second, then stops. The parry prediction projects your CURRENT velocity
-- forward, so mid-dash it thinks you'll be far away and can wrongly decide a
-- ball "misses" - then the dash ends, the ball catches up, and you eat it
-- unblocked. The game exposes the dash state via
-- Framework:Get("MovementController").Dashing; while that's true (and for a
-- short grace after), we stop trusting the "it'll miss" math and just block
-- through any nearby ball that's targeting us. Bundled into one table.
-- SPEED/GRACE come from the game's real AbilityInfo.Settings: DashSpeed = 90
-- studs/s, DashCooldown = 1.1s. MARGIN is how far a dash can still carry you
-- during the grace window (SPEED * GRACE = 90 * 0.35 = 31.5), so a ball that's
-- that far out can still reach you the instant the dash stops - which is
-- exactly the case the old hand-guessed 25 under-covered.
local Dash = { aware = true, controller = nil, endTime = 0, GRACE = 0.35, SPEED = 90, MARGIN = 32 }

-- Camera tracking. Roblox character movement is CAMERA-RELATIVE (WASD moves you
-- where the camera faces), so the camera's flat facing is the direction you're
-- about to move/strafe/dash - a prediction input the ball-only math can't get
-- from velocity alone (a standing player has zero velocity yet is about to bolt
-- wherever they're looking). We also track how fast the camera is TURNING: a
-- hard camera whip is the tell-tale of a panic dodge, during which your position
-- becomes unpredictable - so, like Dash-aware, we stop trusting the "it'll miss"
-- math and force the burst on any nearby targeting ball. WHIP_RATE is the turn
-- speed (rad/s) above which we treat you as actively dodging.
local Camera = {
    aware = true,
    lookDir = Vector3.new(0, 0, -1),  -- current camera LookVector
    flatDir = Vector3.new(0, 0, -1),  -- horizontal (y=0) facing, unit
    angVel = 0,                        -- rad/s the camera is rotating
    lastLook = nil,
    lastTime = 0,
    WHIP_RATE = 3.5,                   -- rad/s (~200 deg/s) = a deliberate dodge-whip
    MARGIN = 32,                       -- studs of reach to still force the burst during a whip
}

-- Forward declarations (assigned further down, but referenced by UI callbacks
-- that can fire before those definitions run).
local billboardCache = {}
local visualSphere = nil
local playerDetectorSpheres = {}
local createVisualSphere
local createOrUpdatePlayerDetectorSphere
local createPlayerDetectorSpheres
local updatePlayerDetectorSpheres
local clearPlayerDetectorSpheres
local getPlayerHRP

-- Live state kept up to date by event hooks (see LIVE STATE HOOKS below)
-- instead of being re-scanned with GetChildren()/FindFirstChild() on every
-- single Heartbeat frame.
local ballsCache = {}         -- [ballInstance] = true
local playerHRPCache = {}     -- [player] = HumanoidRootPart
local hasHighlightCache = false
local ballMotionCache = {}    -- [ballInstance] = {vel, accel, time} - tracks curvature
-- Resolving a ball model's BasePart is a deep, recursive descendant search
-- (FindFirstChildWhichIsA with the recursive flag). The hot loop needs the
-- part several times per ball per frame - findClosestBall, the closest-ball
-- re-read, checkBallDistance, isBallInPlayerRange - so re-searching it every
-- time is the single largest per-frame cost when many balls are in play. Cache
-- the resolved part per ball and reuse it while it's still in the tree; only
-- re-search when it has been destroyed/reparented.
local ballPartCache = {}      -- [ballInstance] = resolved BasePart
local ballPosSample = {}      -- [ballInstance] = {pos, time, vel} - motion-derived velocity
-- Server-authoritative target capture. The game's BallController.Server.ChangeBallColor
-- is invoked by the SERVER with the ball's real target the instant it retargets -
-- and for INVISIBLE balls it bails out BEFORE writing the Target attribute, so this
-- hook is the ONLY client-visible source of an invisible ball's true target. We record
-- [ball] = {target = name, time = tick()} so findClosestBall can arm the panic even
-- when ball:GetAttribute("Target") never reports us. (Hook installed lazily below.)
local serverTargetCache = {}  -- [ballInstance] = {target=playerName, time=tick()}
-- The capture is refreshed on EVERY retarget, so the latest one is the truth
-- for as long as the ball lives (cleared when it despawns). The TTL is only a
-- safety net in case a retarget call is ever missed.
local SERVER_TARGET_TTL = 15
local resolveBallRef, recordServerTarget  -- defined next to the ChangeBallColor hook

-- ============================================
-- APPLY SAVED SETTINGS
-- ============================================
-- Every user-tunable value starts from the saved settings file (if any), so the
-- UI below is built showing - and the logic runs with - your saved choices.
autoParryEnabled    = setting("AutoParry", autoParryEnabled)
autoSpamEnabled     = setting("AutoSpam", autoSpamEnabled)
Move.keep           = setting("KeepMoving", Move.keep)
autoUnstick         = setting("AutoUnstick", autoUnstick)
pingCompEnabled     = setting("PingComp", pingCompEnabled)
pingAutoEnabled     = setting("PingAuto", pingAutoEnabled)
pingMultiplier      = math.clamp(setting("PingMultiplier", pingMultiplier), 0, 3)
predictionHorizon   = math.clamp(setting("PredictionHorizon", predictionHorizon), 0, 5)
MAX_PING_COMP       = math.clamp(setting("MaxPingComp", MAX_PING_COMP), 0, 150)
antiCurveEnabled    = setting("AntiCurve", antiCurveEnabled)
ACCEL_SMOOTHING     = math.clamp(setting("CurveReactivity", ACCEL_SMOOTHING), 0.05, 1)
panicBurstEnabled   = setting("PanicBurst", panicBurstEnabled)
PANIC_TTI           = math.clamp(setting("PanicWindow", PANIC_TTI), 0.1, BLOCK_DURATION)
Dash.aware          = setting("DashAware", Dash.aware)
Camera.aware        = setting("CameraAware", Camera.aware)
Clash.enabled       = setting("SmartClash", Clash.enabled)
showVisualSphere    = setting("ShowParrySphere", showVisualSphere)
showPlayerDetectors = setting("ShowSpamSphere", showPlayerDetectors)
showSpeedLabel      = setting("ShowSpeedLabel", showSpeedLabel)

-- WindUI sliders hand back a number on most builds but a string on a few;
-- coerce so the math below never compares a string to a number.
local function num(v, fallback)
    local n = tonumber(v)
    if n == nil or n ~= n then return fallback end
    return n
end

-- ============================================
-- WINDOW + THEME
-- ============================================
pcall(function()
    WindUI:AddTheme({
        Name = "CrimsonClash",
        Accent = AccentRed,
        Dialog = Color3.fromHex("#3D0F19"),
        Outline = Color3.fromHex("#FF4D5E"),
        Text = Color3.fromHex("#FFE9EE"),
        Placeholder = Color3.fromHex("#D98FA0"),
        Background = Color3.fromHex("#2B0A12"),
        Button = Color3.fromHex("#521624"),
        Icon = Color3.fromHex("#FFC4D1"),
    })
    WindUI:SetTheme("CrimsonClash")
end)

local LOGO_ICON = "https://raw.githubusercontent.com/robloxscripter6245366542/roblox-lua-obscator/main/assets/anime_ball_logo_rounded.png"

local windowConfig = {
    Title = "Anime Ball Hub",
    Icon = LOGO_ICON,
    Author = "Auto Parry • Auto Spam",
    Folder = "AnimeBallHub",
    Size = UDim2.fromOffset(580, 460),
    Theme = "CrimsonClash",
    Transparent = true,
    SideBarWidth = 190,
    ToggleKey = Enum.KeyCode.RightControl,
}
-- Not every executor can turn a URL into an image; if the window fails to build
-- with the logo, rebuild it with a stock Lucide icon instead of giving up.
local okWin, Window = pcall(function() return WindUI:CreateWindow(windowConfig) end)
if not okWin or type(Window) ~= "table" then
    windowConfig.Icon = "shield"
    okWin, Window = pcall(function() return WindUI:CreateWindow(windowConfig) end)
end
if not okWin or type(Window) ~= "table" then
    return warn("[Anime Ball Hub] failed to create window: " .. tostring(Window))
end
pcall(function() Window:SetToggleKey(Enum.KeyCode.RightControl) end)
-- Floating open button (needed on mobile, where there is no keyboard toggle).
pcall(function()
    Window:EditOpenButton({
        Title = "Anime Ball Hub",
        Icon = "shield",
        CornerRadius = UDim.new(0, 12),
        StrokeThickness = 2,
        Color = ColorSequence.new(AccentRed, Gold),
        Draggable = true,
    })
end)

local Tabs = {
    Main    = Window:Tab({ Title = "Main",       Icon = "house" }),
    Parry   = Window:Tab({ Title = "Auto Parry", Icon = "shield" }),
    Spam    = Window:Tab({ Title = "Auto Spam",  Icon = "zap" }),
    Visuals = Window:Tab({ Title = "Visuals",    Icon = "eye" }),
    Stats   = Window:Tab({ Title = "Statistics", Icon = "activity" }),
    Discord = Window:Tab({ Title = "Discord",    Icon = "message-circle" }),
}
pcall(function() Window:SelectTab(1) end)

-- Live status paragraph handles, bundled into one table so the Heartbeat
-- closure captures a single upvalue for all of them.
local HUD = {}

-- Element helpers: every element is added straight to its Tab (supported by
-- every WindUI release); Section is just a header. Toggle/Slider persist their
-- value under `key` automatically.
local function section(tab, title)
    pcall(function() tab:Section({ Title = title }) end)
end
local function toggle(tab, key, title, desc, value, onChange)
    return tab:Toggle({
        Title = title, Desc = desc, Value = value,
        Callback = function(v)
            v = v and true or false
            onChange(v)
            setSetting(key, v)
        end,
    })
end
local function slider(tab, key, title, desc, min, max, step, value, onChange)
    return tab:Slider({
        Title = title, Desc = desc, Step = step,
        Value = { Min = min, Max = max, Default = value },
        Callback = function(v)
            v = math.clamp(num(v, value), min, max)
            onChange(v)
            setSetting(key, v)
        end,
    })
end
local function paragraph(tab, title, desc)
    return tab:Paragraph({ Title = title, Desc = desc })
end

-- ============================================
-- MAIN TAB
-- ============================================
pcall(function()
    Tabs.Main:Image({ Image = LOGO_ICON, AspectRatio = "1:1", Radius = 16 })
end)

section(Tabs.Main, "Feature Control")
toggle(Tabs.Main, "AutoParry", "Auto Parry", "Automatically parry balls aimed at you", autoParryEnabled, function(v)
    autoParryEnabled = v
    notify("Auto Parry", v and "Enabled" or "Disabled")
end)
toggle(Tabs.Main, "AutoSpam", "Auto Spam", "Spam block during a real clash", autoSpamEnabled, function(v)
    autoSpamEnabled = v
    notify("Auto Spam", v and "Enabled" or "Disabled")
end)
toggle(Tabs.Main, "KeepMoving", "Keep Moving While Blocking",
    "Restore your walk speed if a block ever roots you", Move.keep, function(v)
    Move.keep = v
end)
toggle(Tabs.Main, "AutoUnstick", "Auto-Unstick Blocking",
    "If blocking gets stuck (nothing landing while a ball is on you), auto-recover", autoUnstick, function(v)
    autoUnstick = v
    notify("Auto-Unstick", v and "Enabled" or "Disabled")
end)

section(Tabs.Main, "Quick Stats")
HUD.QuickStats = paragraph(Tabs.Main, "Performance", "Loading...")

-- Full kill switch (also getgenv().AnimeBallHubUnload()). unloadScript is
-- assigned near the end of the file; the callback reads it at click time.
section(Tabs.Main, "Script Control")
Tabs.Main:Button({
    Title = "Unload Anime Ball Hub",
    Desc = "Stop everything and remove the menu (re-run the loadstring to load again)",
    Callback = function()
        if unloadScript then unloadScript() end
    end,
})

-- ============================================
-- AUTO PARRY TAB
-- ============================================
section(Tabs.Parry, "Auto Parry Status")
HUD.ParryStatus = paragraph(Tabs.Parry, "Detection Status", "Initializing...")
HUD.ParryDistance = paragraph(Tabs.Parry, "Distance Info", "Waiting for data...")

section(Tabs.Parry, "Ping Compensation & Prediction")
toggle(Tabs.Parry, "PingComp", "Ping Compensation", "Parry earlier when ping is high", pingCompEnabled, function(v)
    pingCompEnabled = v
    if not v then currentRequiredLead, currentPingComp = 0, 0 end
end)
toggle(Tabs.Parry, "PingAuto", "Auto Strength (by ping)",
    "Pick the strength from your live ping. Off = use the manual slider", pingAutoEnabled, function(v)
    pingAutoEnabled = v
end)
slider(Tabs.Parry, "PingMultiplier", "Compensation Strength (manual)",
    "Only used when Auto is OFF. 1.0 = full ping", 0, 3, 0.05, pingMultiplier, function(v)
    pingMultiplier = v
end)
slider(Tabs.Parry, "PredictionHorizon", "Prediction Horizon (s)",
    "Max look-ahead used for early parry", 0, 5, 0.1, predictionHorizon, function(v)
    predictionHorizon = v
end)
slider(Tabs.Parry, "MaxPingComp", "Max Extra Range (studs)",
    "Cap on extra detection studs from ping", 0, 150, 1, MAX_PING_COMP, function(v)
    MAX_PING_COMP = v
end)
toggle(Tabs.Parry, "AntiCurve", "Anti-Curve Prediction",
    "Simulate the ball's curved arc instead of a straight line", antiCurveEnabled, function(v)
    antiCurveEnabled = v
end)
slider(Tabs.Parry, "CurveReactivity", "Curve Reactivity",
    "Higher = react to new curves faster but jitter more", 0.05, 1, 0.05, ACCEL_SMOOTHING, function(v)
    ACCEL_SMOOTHING = v
end)
toggle(Tabs.Parry, "PanicBurst", "Panic Burst",
    "Spam block when impact is imminent - catches super fast balls", panicBurstEnabled, function(v)
    panicBurstEnabled = v
end)
slider(Tabs.Parry, "PanicWindow", "Panic Window (s)",
    "Time-to-impact below this fires the burst. ~0.45 leaves margin inside the 0.6s block", 0.1, BLOCK_DURATION, 0.05, PANIC_TTI, function(v)
    PANIC_TTI = math.min(v, BLOCK_DURATION)
end)
toggle(Tabs.Parry, "DashAware", "Dash-Aware Blocking",
    "Keep blocking correctly while you dash", Dash.aware, function(v)
    Dash.aware = v
end)
toggle(Tabs.Parry, "CameraAware", "Camera-Aware Blocking",
    "Predict camera-relative dodges and block through hard camera whips", Camera.aware, function(v)
    Camera.aware = v
end)
HUD.PingInfo = paragraph(Tabs.Parry, "Ping Status", "Measuring...")

-- ============================================
-- AUTO SPAM TAB
-- ============================================
section(Tabs.Spam, "Auto Spam Status")
toggle(Tabs.Spam, "SmartClash", "Smart Clash Detection",
    "Only spam during a real clash - not just when standing near someone", Clash.enabled, function(v)
    Clash.enabled = v
end)
HUD.SpamStatus = paragraph(Tabs.Spam, "System Status", "Initializing...")
HUD.SpamConditions = paragraph(Tabs.Spam, "Detection Status", "Checking conditions...")

section(Tabs.Spam, "Live Detection")
HUD.PlayerDetection = paragraph(Tabs.Spam, "Player Detection", "Scanning...")
HUD.BallDetection = paragraph(Tabs.Spam, "Ball Detection", "Scanning...")
HUD.HighlightDetection = paragraph(Tabs.Spam, "Target Detection", "Checking...")

-- ============================================
-- VISUALS TAB
-- ============================================
section(Tabs.Visuals, "Visual Indicators")
toggle(Tabs.Visuals, "ShowParrySphere", "Show Parry Detection Sphere",
    "Display the auto parry detection range", showVisualSphere, function(v)
    showVisualSphere = v
    if not v and visualSphere then visualSphere.Transparency = 1 end
end)
toggle(Tabs.Visuals, "ShowSpamSphere", "Show Spam Detection Spheres",
    "Display 17 stud spheres around players", showPlayerDetectors, function(v)
    showPlayerDetectors = v
    if clearPlayerDetectorSpheres then
        if v then createPlayerDetectorSpheres() else clearPlayerDetectorSpheres() end
    end
end)
toggle(Tabs.Visuals, "ShowSpeedLabel", "Show Ball Speed Labels",
    "Display velocity above balls", showSpeedLabel, function(v)
    showSpeedLabel = v
    if not v then
        for _, cache in pairs(billboardCache) do
            if cache.Billboard then pcall(function() cache.Billboard:Destroy() end) end
        end
        billboardCache = {}
    end
end)
paragraph(Tabs.Visuals, "Color Guide",
    "Crimson = Normal Mode\nGold = High Speed Mode\nEmerald = Player Detectors\nAmber = Ball Velocity")

-- ============================================
-- STATS TAB
-- ============================================
section(Tabs.Stats, "Performance Statistics")
HUD.ParryStats = paragraph(Tabs.Stats, "Auto Parry Stats", "Waiting for data...")
HUD.SpamStats = paragraph(Tabs.Stats, "Auto Spam Stats", "Waiting for data...")
HUD.LiveStats = paragraph(Tabs.Stats, "Live Monitoring", "Monitoring...")

Tabs.Stats:Button({
    Title = "Reset All Statistics",
    Desc = "Reset both parry and spam counters",
    Callback = function()
        totalParries = 0
        highSpeedParries = 0
        totalBurstBlocks = 0
        totalSpams = 0
        spamDuration = 0
        if spamStarted then lastSpamStartTime = tick() end
        blockSent = 0
        blockLanded = 0
        blockRejected = 0
        blockParried = 0
        lastBlockResult = "-"
        totalUnsticks = 0
        notify("Stats Reset", "All statistics have been reset")
    end,
})

-- ============================================
-- CONFIG
-- ============================================
section(Tabs.Stats, "Config")
paragraph(Tabs.Stats, "Auto-Save",
    fsOk() and ("Settings save automatically to " .. CONFIG_FILE)
        or "Your executor has no file functions - settings won't persist")
Tabs.Stats:Button({
    Title = "Save Config Now",
    Desc = "Write all current settings to disk",
    Callback = function()
        settingsDirty = false
        if saveSettings() and fsOk() then
            notify("Config Saved", "Saved to " .. CONFIG_FILE)
        else
            notify("Config Not Saved", "Your executor doesn't support writefile")
        end
    end,
})
Tabs.Stats:Button({
    Title = "Reset Config",
    Desc = "Delete saved settings (defaults apply on next load)",
    Callback = function()
        Settings = {}
        settingsDirty = false
        lastSavedJson = nil
        pcall(function()
            if type(delfile) == "function" and (type(isfile) ~= "function" or isfile(CONFIG_FILE)) then
                delfile(CONFIG_FILE)
            end
        end)
        notify("Config Reset", "Defaults will apply next time you load the hub")
    end,
})

-- Debounced background save: only touches the disk when something changed.
task.spawn(function()
    while not destroyed do
        task.wait(2)
        if destroyed then break end
        if settingsDirty then
            settingsDirty = false
            saveSettings()
        end
    end
end)

-- ============================================
-- DISCORD TAB
-- ============================================
local DISCORD_INVITE = "https://discord.gg/sA5448GTS"
section(Tabs.Discord, "Community")
paragraph(Tabs.Discord, "Join the Discord", DISCORD_INVITE)
Tabs.Discord:Button({
    Title = "Copy Invite Link",
    Desc = "Copies the Discord invite to your clipboard",
    Callback = function()
        local clip = setclipboard or toclipboard or (Clipboard and Clipboard.set)
        local ok = clip ~= nil and pcall(clip, DISCORD_INVITE)
        notify(ok and "Copied!" or "Copy Failed",
            ok and ("Invite copied: " .. DISCORD_INVITE) or ("Copy this manually: " .. DISCORD_INVITE), 5)
    end,
})

-- ============================================
-- VISUALS
-- ============================================

createVisualSphere = function()
    if visualSphere then visualSphere:Destroy() end
    visualSphere = Instance.new("Part")
    visualSphere.Name = "VisualDetector"
    visualSphere.Shape = Enum.PartType.Ball
    visualSphere.Material = Enum.Material.ForceField
    visualSphere.Color = AccentRed
    visualSphere.Transparency = 0.7
    visualSphere.CanCollide = false
    visualSphere.CanQuery = false
    visualSphere.CanTouch = false   -- never trip the map's Touched triggers
    visualSphere.CastShadow = false
    visualSphere.Anchored = true
    visualSphere.Parent = workspace
end

-- Single source of truth for building/refreshing a player detector sphere,
-- used by both the initial-create pass and the per-frame update pass
-- (previously this logic was duplicated in two places).
createOrUpdatePlayerDetectorSphere = function(player)
    if not showPlayerDetectors then return end
    local hrp = getPlayerHRP(player)
    if not hrp then
        -- Dead / not spawned: drop the sphere instead of leaving it frozen in place.
        local stale = playerDetectorSpheres[player.Name]
        if stale then stale:Destroy() playerDetectorSpheres[player.Name] = nil end
        return
    end

    local sphere = playerDetectorSpheres[player.Name]
    if not sphere or not sphere.Parent then
        sphere = Instance.new("Part")
        sphere.Name = "PlayerDetector_" .. player.Name
        sphere.Shape = Enum.PartType.Ball
        sphere.Material = Enum.Material.ForceField
        sphere.Color = Emerald
        sphere.Transparency = 0.7
        sphere.CanCollide = false
        sphere.CanQuery = false
        sphere.CanTouch = false
        sphere.CastShadow = false
        sphere.Anchored = true
        sphere.Size = Vector3.new(PLAYER_DETECTOR_DISTANCE * 2, PLAYER_DETECTOR_DISTANCE * 2, PLAYER_DETECTOR_DISTANCE * 2)
        sphere.Parent = workspace
        playerDetectorSpheres[player.Name] = sphere
    end
    sphere.Position = hrp.Position
end

createPlayerDetectorSpheres = function()
    if not showPlayerDetectors then return end
    clearPlayerDetectorSpheres()
    for _, player in pairs(Players:GetPlayers()) do
        createOrUpdatePlayerDetectorSphere(player)
    end
end

updatePlayerDetectorSpheres = function()
    if not showPlayerDetectors then return end
    for _, player in pairs(Players:GetPlayers()) do
        createOrUpdatePlayerDetectorSphere(player)
    end
end

clearPlayerDetectorSpheres = function()
    for _, sphere in pairs(playerDetectorSpheres) do if sphere then sphere:Destroy() end end
    playerDetectorSpheres = {}
end

-- ============================================
-- BALL HELPERS
-- ============================================

-- The Balls folder can also hold static map objects (BallPad, BallSpawn per
-- the game's own hierarchy) that are NOT balls. Treating them as balls makes
-- the auto-parry lock onto the pad and even burst-block while you stand near
-- it. Skip anything on this ignore list.
local IGNORED_BALL_NAMES = {
    BallPad = true,
    BallSpawn = true,
}
local function isRealBall(ball)
    return not IGNORED_BALL_NAMES[ball.Name]
end

local function getBallPart(ball)
    if ball:IsA("BasePart") then return ball end
    -- Reuse the previously resolved part while it's still in the tree; a
    -- destroyed/reparented part reports Parent == nil, which forces a fresh
    -- (deep) search. This turns the common case into an O(1) table lookup.
    local cached = ballPartCache[ball]
    if cached and cached.Parent ~= nil then return cached end
    local part = ball:FindFirstChildWhichIsA("BasePart", true)
    ballPartCache[ball] = part
    return part
end

local function getBallPosition(ball)
    local part = getBallPart(ball)
    return part and part.Position or nil
end

-- The ball is driven by a LinearVelocity constraint whose VectorVelocity is
-- the EXACT velocity the game is steering it at - cleaner and more immediate
-- than AssemblyLinearVelocity (the physics-interpolated, collision-noisy
-- measured result). Reading the constraint means a curve/homing turn shows up
-- the instant the server commands it, not a frame later.
--
-- CRITICAL: VectorVelocity is only a WORLD-space vector when RelativeTo ==
-- World. If it's relative to an attachment it's in the ball's local frame,
-- and feeding that into the world-space closing-speed / curvature math would
-- produce garbage. So only trust it when world-relative and in Vector mode;
-- otherwise fall back to AssemblyLinearVelocity, which is always world-space
-- (and was the proven source before this optimization).
-- Motion-derived velocity: how far the ball's position actually moved since the
-- last frame we sampled it, per second. This is the last-resort truth for a ball
-- driven KINEMATICALLY - moved by CFrame/Position each frame instead of physics
-- (some abilities and custom maps do this). Such a ball reports ~0 on both its
-- LinearVelocity constraint AND AssemblyLinearVelocity, so without this it looks
-- stationary, the arrival math never fires, and it sails in unblocked ("it just
-- doesn't block that ball"). Frame-guarded: the sample only advances when the
-- clock moves on, so calling this several times within one frame (findClosestBall
-- + the main read) returns the same derived velocity instead of dividing by ~0.
local function kinematicVelocity(ball, part, now)
    local s = ballPosSample[ball]
    local pos = part.Position
    if not s then
        ballPosSample[ball] = { pos = pos, time = now, vel = Vector3.new() }
        return Vector3.new()
    end
    if now > s.time + 1e-4 then
        s.vel = (pos - s.pos) / (now - s.time)
        s.pos, s.time = pos, now
    end
    return s.vel
end

local function getBallVelocityVector(ball)
    local part = getBallPart(ball)
    if not part then return Vector3.new() end
    local lv = ball:FindFirstChildOfClass("LinearVelocity")
        or part:FindFirstChildOfClass("LinearVelocity")
    if lv and lv.Enabled
        and lv.RelativeTo == Enum.ActuatorRelativeTo.World
        and lv.VelocityConstraintMode == Enum.VelocityConstraintMode.Vector then
        local vv = lv.VectorVelocity
        if vv.Magnitude > 0.1 then return vv end
    end
    local measured = part.AssemblyLinearVelocity
    if measured.Magnitude > 0.1 then return measured end
    -- Physics reports the ball as still - if it's actually being moved
    -- kinematically, recover its real velocity from the change in position.
    local kv = kinematicVelocity(ball, part, tick())
    if kv.Magnitude > 0.1 then return kv end
    return measured
end

-- Component of the ball's velocity that is actually closing the distance to
-- `targetPos` (positive = approaching, negative/zero = moving away or level).
-- Using this instead of raw speed means a ball that whizzes past the player
-- without ever heading at them no longer triggers an early "future" parry.
local function getClosingSpeed(ballPos, ballVel, targetPos)
    local toTarget = targetPos - ballPos
    local dist = toTarget.Magnitude
    if dist < 1e-3 then return ballVel.Magnitude end
    return ballVel:Dot(toTarget / dist)
end

-- Samples the local camera each frame: its facing (for camera-relative move
-- prediction) and how fast it's rotating (for whip/dodge detection). Cheap; run
-- once per frame before the prediction reads Camera.*.
local function updateCamera(now)
    local cam = workspace.CurrentCamera
    if not cam then return end
    local look = cam.CFrame.LookVector
    if Camera.lastLook and now > Camera.lastTime then
        local dt = now - Camera.lastTime
        local dot = math.clamp(look:Dot(Camera.lastLook), -1, 1)
        Camera.angVel = math.acos(dot) / dt
    end
    Camera.lastLook = look
    Camera.lastTime = now
    Camera.lookDir = look
    local flat = Vector3.new(look.X, 0, look.Z)
    if flat.Magnitude > 1e-3 then Camera.flatDir = flat.Unit end
end

-- Per-frame sampler: camera + client frame-lag, run once at the top of the main
-- loop. Frame lag is a decaying max - it jumps straight to a spike so a stutter
-- is compensated on the very frame it appears, then decays slowly so one hitch
-- keeps the window widened for a short while after (bursty lag tends to recur).
-- Capped so a full freeze doesn't blow the window open. Returns the current
-- frame lag so the caller can hold it as a local (zero upvalue cost).
local function updatePerFrame(now)
    updateCamera(now)
    if lastFrameClock > 0 then
        local dt = now - lastFrameClock
        -- A multi-second gap is a tab-out / loading pause, NOT gameplay stutter;
        -- feeding it in would peg frameLag to its cap and hold the panic window
        -- wide for ~0.5s after you return (spurious early firing). Only real
        -- frame hitches (below this bound) should count as lag.
        if dt <= 1 then
            if dt > frameLag then frameLag = dt else frameLag = frameLag + (dt - frameLag) * 0.1 end
            frameLag = math.clamp(frameLag, 0, FRAME_LAG_CAP)
        else
            frameLag = 0  -- resumed from a pause; start clean
        end
    end
    lastFrameClock = now
    return frameLag
end

-- ============================================
-- ANTI-CURVE PREDICTION
-- ============================================
-- A ball's current velocity vector only describes where it's headed *right
-- now*. Curving/homing balls change direction over time, so extrapolating a
-- straight line from one frame's velocity misses them - the whole point of
-- "seeing the future" breaks down the moment the ball doesn't fly straight.
-- Instead we measure how the velocity vector itself is changing frame to
-- frame (acceleration = curvature), smooth it to cut down on per-frame
-- jitter, then simulate the resulting curved arc forward in small steps to
-- see whether it enters melee range within our ping lead time - rather than
-- solving a single straight-line distance/speed division.

-- Updates and returns the smoothed acceleration (curvature) vector for a
-- ball, from the change in its velocity since the last frame we saw it.
local function updateBallCurvature(ball, vel, now)
    local prev = ballMotionCache[ball]
    local accel = Vector3.new()
    -- Curve-angle (turn-rate) state: how fast, and about which axis, the ball's
    -- velocity VECTOR is rotating. This is the missing piece the linear-accel
    -- (parabolic) model can't express - a homing ball keeps turning, tracing a
    -- circular arc, and only a constant-turn-rate model reproduces that arc.
    local omega = 0                      -- rad/s, smoothed
    local axis = prev and prev.axis or Vector3.yAxis  -- rotation axis, smoothed
    local speed = vel.Magnitude
    local dir = speed > 1e-3 and (vel / speed) or (prev and prev.dir) or nil
    if prev and now > prev.time then
        local dt = now - prev.time
        local rawAccel = (vel - prev.vel) / dt
        -- A parry/bounce reverses the ball's velocity within a single frame;
        -- read as delta-v/dt that's a one-frame "acceleration" in the
        -- thousands of studs/s^2, and the smoothing would carry that phantom
        -- curve for several frames - enough for predictCurvedImpact to
        -- hallucinate an arc back into range and waste a parry (0.3s
        -- cooldown) on a ball that's actually flying away. Real curve/homing
        -- forces are far below this cap.
        local mag = rawAccel.Magnitude
        if mag > MAX_CURVE_ACCEL then
            rawAccel = rawAccel * (MAX_CURVE_ACCEL / mag)
        end
        accel = prev.accel:Lerp(rawAccel, ACCEL_SMOOTHING)

        -- Measure the angle the velocity direction swept this frame and its
        -- axis. Same anti-bounce logic as the accel cap: a near-180 deg flip in
        -- one frame is a bounce/parry, NOT a sustained curve - reject it (omega
        -- 0) so we don't extrapolate a phantom loop. Genuine curves sit far
        -- under MAX_TURN_RATE.
        if dir and prev.dir then
            local dot = math.clamp(dir:Dot(prev.dir), -1, 1)
            local sweptAngle = math.acos(dot)          -- radians turned this frame
            local rawOmega = sweptAngle / dt
            if rawOmega <= MAX_TURN_RATE then
                local cross = prev.dir:Cross(dir)
                if cross.Magnitude > 1e-4 then
                    axis = prev.axis and prev.axis:Lerp(cross.Unit, ACCEL_SMOOTHING).Unit or cross.Unit
                end
                local prevOmega = prev.omega or 0
                omega = prevOmega + (rawOmega - prevOmega) * ACCEL_SMOOTHING
            else
                -- bounce frame: keep the previously smoothed turn but decay it,
                -- never spike it up from a reversal.
                omega = (prev.omega or 0) * (1 - ACCEL_SMOOTHING)
            end
        end
    end
    ballMotionCache[ball] = {vel = vel, accel = accel, time = now, dir = dir, omega = omega, axis = axis}
    return accel, omega, axis
end

-- Simulates the curved arc (pos + vel*t + 0.5*accel*t^2) forward in small
-- steps up to maxLookahead seconds, returning true (and the time) as soon as
-- the predicted ball position comes within meleeRange of the player. This is
-- what lets a curving ball still trigger an early "future" parry instead of
-- only ever being caught once it's already in range.
--
-- The player's future position is genuinely unknowable when they're jumping,
-- dashing, and flipping direction - a straight projection of current
-- velocity is wrong the moment any of that happens, and would predict the
-- ball "misses" when it's actually homing in. So the arc is checked against
-- THREE movement hypotheses, and arrival against any one counts:
--   1. player stops/turns          (targetPos)
--   2. player keeps moving         (targetPos + targetVel*t, minus gravity
--                                    drop while airborne - a jump is an arc,
--                                    not a straight line up)
--   3. player decelerates          (half velocity - a dash bleeds speed, so
--                                    reality sits between hypotheses 1 and 2)
-- Erring toward parrying is the right bias: a slightly-early block costs
-- nothing here, a missed one loses the round.
local function predictCurvedImpact(pos, vel, accel, targetPos, targetVel, targetGravity, meleeRange, maxLookahead, steps, omega, axis, camDir, camSpeed)
    if maxLookahead <= 0 then return false, nil end
    steps = steps or CURVE_SIM_STEPS
    -- Anti-tunneling: at a fixed step count a fast ball can jump much further
    -- than the parry radius between samples and pass straight through the
    -- sphere unseen (temporal aliasing). Raise the step count so no single
    -- step advances more than half the melee radius, using the arc's peak
    -- speed (current speed + accel over the window). Capped so the loop can
    -- never blow up on absurd inputs.
    local peakSpeed = vel.Magnitude + accel.Magnitude * maxLookahead
    local safeStep = math.max(meleeRange * 0.5, 1)
    local neededSteps = math.ceil(peakSpeed * maxLookahead / safeStep)
    steps = math.clamp(math.max(steps, neededSteps), 1, 400)
    local dt = maxLookahead / steps

    -- Constant-turn-rate ("homing") arc: integrate a SECOND ball forward whose
    -- velocity vector rotates by omega*dt about `axis` every step. Where the
    -- polynomial (pos + v t + 0.5 a t^2) arc straightens a hard-curving ball
    -- out and loses it, this one keeps turning with it - reproducing the actual
    -- circular path a homing ball flies. We test BOTH arcs each step and count
    -- arrival by EITHER (bias toward blocking; an extra parry is harmless, a
    -- miss loses). The rotation is precomputed once as a per-step CFrame.
    omega = omega or 0
    local doHoming = omega > 1e-3 and axis ~= nil and axis.Magnitude > 1e-3
    local stepRot, hpos, hvel
    if doHoming then
        stepRot = CFrame.fromAxisAngle(axis.Unit, omega * dt)
        hpos, hvel = pos, vel
    end

    for i = 1, steps do
        local t = i * dt
        local drop = Vector3.new(0, -0.5 * targetGravity * t * t, 0)
        local fullMovePos = targetPos + targetVel * t + drop
        local halfMovePos = targetPos + targetVel * (0.5 * t) + drop
        -- Camera-relative hypothesis: the player breaks into a move/dash in the
        -- direction the camera faces (movement is camera-relative), which the
        -- velocity-based hypotheses can't see when they're currently still.
        local camMovePos = camDir and targetPos + camDir * (camSpeed * t) + drop or nil

        -- Polynomial (linear-acceleration) arc.
        local predictedPos = pos + vel * t + accel * (0.5 * t * t)
        if (predictedPos - targetPos).Magnitude <= meleeRange
            or (predictedPos - fullMovePos).Magnitude <= meleeRange
            or (predictedPos - halfMovePos).Magnitude <= meleeRange
            or (camMovePos and (predictedPos - camMovePos).Magnitude <= meleeRange) then
            return true, t
        end

        -- Turn-rate (homing) arc, integrated incrementally.
        if doHoming then
            hpos = hpos + hvel * dt
            hvel = stepRot:VectorToWorldSpace(hvel)
            if (hpos - targetPos).Magnitude <= meleeRange
                or (hpos - fullMovePos).Magnitude <= meleeRange
                or (hpos - halfMovePos).Magnitude <= meleeRange
                or (camMovePos and (hpos - camMovePos).Magnitude <= meleeRange) then
                return true, t
            end
        end
    end
    return false, nil
end

-- ============================================
-- LIVE STATE HOOKS
-- ============================================
-- Balls, player HumanoidRootParts, and the local Highlight are tracked via
-- signal hooks (ChildAdded/ChildRemoved/CharacterAdded/CharacterRemoving)
-- instead of being re-discovered with GetChildren()/FindFirstChild() on
-- every Heartbeat frame. This removes the duplicate independent folder
-- scans Auto Parry and Auto Spam used to each run, and reacts the instant a
-- ball spawns/despawns or the Highlight appears instead of polling for it.

local function trackBallsFolder(folder)
    -- Only cache real balls, never the static BallPad/BallSpawn map objects
    -- that also live in this folder (filtering here means every consumer of
    -- ballsCache is automatically correct).
    for _, ball in pairs(folder:GetChildren()) do
        if isRealBall(ball) then ballsCache[ball] = true end
    end
    track(folder.ChildAdded:Connect(function(child)
        if isRealBall(child) then ballsCache[child] = true end
    end))
    track(folder.ChildRemoved:Connect(function(child)
        ballsCache[child] = nil
        ballMotionCache[child] = nil
        serverTargetCache[child] = nil
        ballPartCache[child] = nil
        ballPosSample[child] = nil
        -- Also drop (and destroy) the speed-label billboard for this ball,
        -- otherwise billboardCache grows without bound as balls spawn and
        -- despawn over a long session.
        local cached = billboardCache[child]
        if cached and cached.Billboard then cached.Billboard:Destroy() end
        billboardCache[child] = nil
    end))
end

-- ===================== Advanced ball detection =====================
-- The event hooks on workspace.Balls are the fast path, but in the real game
-- they can silently miss balls - and a ball the cache never learns about is a
-- guaranteed "it just doesn't block". Three ways they miss:
--   * the folder isn't named exactly "Balls" (GameBalls, BallsFolder, a Model),
--   * the folder is replaced/reparented wholesale (the old hooks die with it),
--   * a ball spawns the same frame the hook binds and ChildAdded is lost.
-- So we ALSO discover EVERY ball-like container (workspace-level Folder/Model
-- whose name contains "ball"), bind the same tracking to each, and run a cheap
-- periodic RECONCILE that sweeps them and adds anything the events missed. This
-- makes detection self-healing: whatever slips past the fast path, the sweep
-- catches within a fraction of a second.
local boundContainers = setmetatable({}, { __mode = "k" })  -- weak: don't pin dead folders
local function bindBallContainer(folder)
    if not folder or boundContainers[folder] then return end
    boundContainers[folder] = true
    trackBallsFolder(folder)  -- caches existing balls + hooks ChildAdded/ChildRemoved
end

-- Find and bind any not-yet-known ball container directly under workspace.
-- A container is a ball-named FOLDER (balls live in folders - "Balls",
-- "GameBalls", "BallsFolder"). We deliberately do NOT auto-bind ball-named
-- Models: a player whose USERNAME contains "ball" has a character Model in
-- workspace, and binding it would add their body parts to the ball cache and
-- make the script parry (or lock onto) a person. A Model with a Humanoid is a
-- character and is always skipped; the primary game folder is bound explicitly
-- by name via watchForNamedChild regardless of type, so nothing real is missed.
local function discoverBallContainers()
    local ok, children = pcall(function() return workspace:GetChildren() end)
    if not ok then return end
    for _, child in ipairs(children) do
        if not boundContainers[child]
            and child:IsA("Folder")
            and not child:FindFirstChildOfClass("Humanoid")
            and child.Name:lower():find("ball", 1, true) then
            bindBallContainer(child)
        end
    end
end

-- Safety-net sweep: discover containers, then add any real ball an event missed.
-- Cheap (a handful of containers, each with a handful of children) and idempotent.
-- Self-throttled (~5x/sec) so the main loop can call it every frame for one
-- upvalue and no extra bookkeeping - a ball the fast path drops is recovered
-- within ~0.2s, long before it could reach you.
local RECONCILE_INTERVAL = 0.2
local lastReconcile = 0
local function reconcileBalls(now)
    if now - lastReconcile < RECONCILE_INTERVAL then return end
    lastReconcile = now
    discoverBallContainers()
    for folder in pairs(boundContainers) do
        if folder.Parent then
            for _, child in ipairs(folder:GetChildren()) do
                if not ballsCache[child] and isRealBall(child) and getBallPart(child) then
                    ballsCache[child] = true
                end
            end
        end
    end
end

-- Lazily drop balls whose instance has left the game tree without the
-- folder's ChildRemoved firing (e.g. the whole Balls folder was reparented
-- rather than destroyed) - otherwise dead balls linger in the cache forever
-- and corrupt closest-ball selection.
local function purgeDeadBall(ball)
    ballsCache[ball] = nil
    ballMotionCache[ball] = nil
    serverTargetCache[ball] = nil
    ballPartCache[ball] = nil
    ballPosSample[ball] = nil
    local cached = billboardCache[ball]
    if cached and cached.Billboard then pcall(function() cached.Billboard:Destroy() end) end
    billboardCache[ball] = nil
end

-- Only the CURRENT folder is watched: on respawn a new same-named model
-- appears and the previous folder's connections are dropped (they used to pile
-- up for every death, and a late ChildRemoved on the dead model could clear the
-- live highlight flag).
local highlightConns = {}
local function bindHighlightFolder(folder)
    for _, c in ipairs(highlightConns) do pcall(function() c:Disconnect() end) end
    highlightConns = {}
    hasHighlightCache = folder:FindFirstChild("Highlight") ~= nil
    highlightConns[1] = track(folder.ChildAdded:Connect(function(child)
        if child.Name == "Highlight" then hasHighlightCache = true end
    end))
    highlightConns[2] = track(folder.ChildRemoved:Connect(function(child)
        if child.Name == "Highlight" then hasHighlightCache = false end
    end))
end

getPlayerHRP = function(player)
    local hrp = playerHRPCache[player]
    if hrp and hrp.Parent then return hrp end
    return nil
end

local function bindCharacter(player, character)
    playerHRPCache[player] = nil
    local hrp = character:FindFirstChild("HumanoidRootPart")
    if hrp then
        playerHRPCache[player] = hrp
        return
    end
    -- HRP hasn't streamed in yet (fresh spawn) - wait for it off-thread so
    -- this doesn't stall the CharacterAdded handler.
    task.spawn(function()
        local waited = character:WaitForChild("HumanoidRootPart", 5)
        if waited and character.Parent then
            playerHRPCache[player] = waited
        end
    end)
end

local function bindPlayer(player)
    if player.Character then bindCharacter(player, player.Character) end
    track(player.CharacterAdded:Connect(function(character) bindCharacter(player, character) end))
    track(player.CharacterRemoving:Connect(function() playerHRPCache[player] = nil end))
end

-- Calls onFound immediately if `name` already exists under workspace,
-- otherwise hooks ChildAdded and calls it the instant it appears.
local function watchForNamedChild(name, onFound)
    local existing = workspace:FindFirstChild(name)
    if existing then onFound(existing) end
    track(workspace.ChildAdded:Connect(function(child)
        if child.Name == name then onFound(child) end
    end))
end

-- ============================================
-- PING
-- ============================================

local function getPing()
    -- Primary: Stats network item (round-trip ms). Fallback: GetNetworkPing()*1000.
    local ok, ping = pcall(function()
        return Stats.Network.ServerStatsItem["Data Ping"]:GetValue()
    end)
    if ok and type(ping) == "number" and ping > 0 then return ping end
    local ok2, p2 = pcall(function() return LocalPlayer:GetNetworkPing() * 1000 end)
    if ok2 and type(p2) == "number" and p2 > 0 then return p2 end
    return 0
end

-- The ping lead time is purely a function of latency/settings - it must NOT
-- depend on the ball's straight-line closing speed. (It previously did, via
-- getPingCompensation zeroing it out whenever closingSpeed <= 0, which
-- silently disabled the curved-arc prediction below for exactly the balls it
-- exists to catch: ones that aren't closing in a straight line *right now*
-- but are about to, because they're curving in.)
local function getPingLeadTime()
    if not pingCompEnabled then
        currentRequiredLead = 0
        return 0
    end
    currentPing = getPing()
    -- Smooth the raw ping with an exponential moving average. Roblox's ping
    -- reading jitters frame-to-frame; feeding it straight into the lead time
    -- makes the parry window twitch, which is felt as stutter. Chasing a
    -- smoothed value means the compensation eases up/down gradually instead.
    if smoothedPing == 0 then
        smoothedPing = currentPing
    else
        smoothedPing = smoothedPing + (currentPing - smoothedPing) * PING_SMOOTHING
    end
    -- Auto mode: pick the strength from your live ping instead of the manual
    -- slider. Low ping needs almost nothing; the safety margin grows with
    -- ping (1.0x at 0ms up to 2.0x at 400ms+), so the worse your connection,
    -- the earlier it blocks - with no knob to tune.
    local mult
    if pingAutoEnabled then
        mult = math.clamp(1.0 + smoothedPing / 400, 1.0, 2.0)
    else
        mult = pingMultiplier
    end
    currentAutoMult = mult
    local leadTime = math.clamp((smoothedPing / 1000) * mult, 0, predictionHorizon)
    currentRequiredLead = leadTime
    return leadTime
end

-- Extra detection studs (legacy straight-line display value) so a high-ping
-- client's effective range readout reflects the compensation, capped by
-- MAX_PING_COMP. Only meaningful when the ball is actually closing in a
-- straight line; the curved-arc prediction below is what actually decides
-- whether to parry early.
local function getPingCompensation(closingSpeed, leadTime)
    if not pingCompEnabled or closingSpeed <= 0 then
        currentPingComp = 0
        return 0
    end
    local comp = math.clamp(closingSpeed * leadTime, 0, MAX_PING_COMP)
    currentPingComp = comp
    return comp
end

local function calculateDistance(velocity)
    if velocity >= HIGH_SPEED_THRESHOLD then return MAX_DISTANCE end
    local normalizedVelocity = math.clamp(velocity / 75, 0, 1)  -- ramp to full range sooner
    local distance = MIN_DISTANCE + (MAX_DISTANCE - MIN_DISTANCE) * normalizedVelocity
    distance = math.floor(distance * 2 + 0.5) / 2
    return math.clamp(distance, MIN_DISTANCE, MAX_DISTANCE)
end

-- InvokeServer on a RemoteFunction YIELDS until the server replies. Fired
-- inline from the Heartbeat handler, that stalls everything after it in the
-- same frame (status UI, the whole Auto Spam section) for a full round-trip
-- - the worse your ping, the longer the stall. Fire-and-forget in a fresh
-- thread so the handler never blocks on the network.
--
-- The block argument is the CAMERA's vertical look direction. The real
-- SwordController sends SwordService.Block:Invoke(CurrentCamera.CFrame
-- .LookVector.Y) - a LIVE value. The old hardcoded -0.759... was one frozen
-- camera angle; sending your actual live pitch matches a legit client and
-- avoids the server ever seeing a stale/mismatched block direction.
--
-- Transport: the decompiled SwordController fires the block through the
-- framework's service proxy - framework:Fetch("SwordService").Block:Invoke(lookY)
-- - passing lookY as a single argument. That is the game's OWN verified path,
-- so we use it first (cached). If it's ever unavailable in this environment we
-- fall back to the generic RemoteFunction router, which also works; the two
-- together make the block call bulletproof.
local swordServiceProxy = nil
local function getSwordService()
    if swordServiceProxy then return swordServiceProxy end
    pcall(function()
        -- Bounded WaitForChild: this runs inside fireBlockRemote's spawned
        -- thread, so a plain (infinite) WaitForChild would hang - and leak - a
        -- fresh thread on every block attempt if Framework were ever missing.
        -- On timeout we return nil and fireBlockRemote falls back to the generic
        -- RemoteFunction router.
        local framework = ReplicatedStorage:WaitForChild("Framework", 5)
        if framework then
            swordServiceProxy = require(framework):Fetch("SwordService")
        end
    end)
    return swordServiceProxy
end
-- Records what the server returned for a Block call so the HUD can show whether
-- our blocks are landing or being rejected on cooldown.
local function recordBlockResult(ok, result)
    blockSent = blockSent + 1
    if not ok then
        lastBlockResult = "error"
    elseif result == nil then
        blockRejected = blockRejected + 1
        lastBlockResult = "rejected"
    else
        blockLanded = blockLanded + 1
        if result == true then
            blockParried = blockParried + 1
            lastBlockResult = "parried"
        else
            lastBlockResult = "shield"
        end
    end
end
-- Block-send RATE CAP. Spamming the block is worse than useless, and the game
-- dump is explicit about why:
--   * A block is a 0.6s SHIELD on a 1s cooldown (SwordInfo: BlockDuration 0.6,
--     DefaultCooldown 1), and a SUCCESSFUL parry RESETS the cooldown - so you can
--     re-block instantly the moment a return lands. One well-TIMED block per
--     return wins a clash; extra sends just get cooldown-rejected by the server.
--   * Every remote call shares the game's NetRay budget - 120 requests/sec global
--     and 20 per 0.1s burst (RATE_LIMIT defaults). Blow it and requests are
--     DROPPED and a circuit breaker locks the remote out for ~15s. Flooding the
--     block therefore makes the game silently EAT the block that would've saved
--     you, and you lose the clash. (This is why the old click-storm lost clashes.)
-- Two send rates, both kept UNDER the game's limit so nothing is ever dropped:
--   * lone ball: ~30/s - one well-timed block per return is all a single ball
--     needs, and it barely touches the budget.
--   * CLASH: ~70/s - the clash WINNER is decided server-side (code we can't see),
--     and in practice a faster clicker overruns a slower one, so in a clash we
--     click as fast as we safely can. 70/s is ~7 per 0.1s (burst limit 20) and
--     leaves ~50/s of the 120/s global budget for movement/dash/abilities - so it
--     out-clicks a human/most autoclickers WITHOUT the flood that got dropped and
--     lost clashes before. Up to CLASH_INFLIGHT concurrent requests so high ping
--     still reaches that rate; the interval still caps the actual send rate, so
--     concurrency can't push us over the limit.
local BLOCK_SEND_INTERVAL = 0.033  -- lone ball: ~30/s
local CLASH_SEND_INTERVAL = 0.009  -- clash: fire every frame, up to ~110/s on a
                                   -- high-refresh device - as close to the 120/s
                                   -- limit as is safe (leaves ~10/s so a dash /
                                   -- ability can't tip you over and get dropped)
local CLASH_INFLIGHT = 2
local blocksInFlight = 0
local lastBlockSendTime = -1
local function fireBlockRemote(clash)
    local nowT = tick()
    local interval = clash and CLASH_SEND_INTERVAL or BLOCK_SEND_INTERVAL
    if nowT - lastBlockSendTime < interval then return false end
    if blocksInFlight >= (clash and CLASH_INFLIGHT or 1) then return false end
    lastBlockSendTime = nowT
    blocksInFlight = blocksInFlight + 1
    task.spawn(function()
        -- The whole body is pcall-wrapped so the in-flight counter is ALWAYS
        -- decremented afterward - even if something in here errors. Otherwise a
        -- single throwing send would leak the counter, and after CLASH_INFLIGHT
        -- leaks the guard would wedge and block firing would stop for good.
        pcall(function()
            local cam = workspace.CurrentCamera
            -- NB: a plain `cam and cam...Y or default` would wrongly fall back to
            -- the default when the camera is exactly level (LookVector.Y == 0, a
            -- valid pitch, not a missing value). Keep the real 0 so the block
            -- direction we send matches a legit client instead of a frozen angle.
            local lookY = -0.759547233581543
            if cam then lookY = cam.CFrame.LookVector.Y end
            -- Preferred: the game's exact call path. Capture the RETURN (server's
            -- accept/reject verdict), not just whether the call errored.
            local svc = getSwordService()
            if svc then
                local ok, result = pcall(function() return svc.Block:Invoke(lookY) end)
                if ok then recordBlockResult(true, result); return end
                swordServiceProxy = nil -- proxy went stale; re-fetch next time
            end
            -- Fallback: generic framework RemoteFunction router.
            local ok, result = pcall(function()
                return ReplicatedStorage.Framework.RemoteFunction:InvokeServer("SwordService", "Block", {lookY})
            end)
            recordBlockResult(ok, result)
        end)
        blocksInFlight = blocksInFlight - 1   -- always runs, even on error
    end)
    return true
end

-- force=true bypasses the client-side PARRY_COOLDOWN. During a clash / point-
-- blank exchange the ball reverses every few frames, so throttling fires to one
-- per 0.3s leaves most returns unshielded ("the clashing is so slow") - and it
-- contradicts fireBlockRemote's own rule that a landed block resets the server
-- cooldown, so continuous fire stays protected. Clashes therefore fire EVERY
-- frame (Heartbeat is the natural rate limit; the server rejects any extra).
-- A lone ball keeps the 0.3s throttle so a single too-early block can't spam.
local function executeParry(force)
    local currentTime = tick()
    if not force and currentTime - lastParryTime < PARRY_COOLDOWN then return end
    -- Stats only count blocks that were actually sent (the rate cap used to make
    -- every throttled frame count as a "parry").
    if fireBlockRemote(force) then   -- force = clash/point-blank -> faster clash send rate
        lastParryTime = currentTime
        totalParries = totalParries + 1
        if isHighSpeedMode then highSpeedParries = highSpeedParries + 1 end
    end
end

local function createSpeedLabel(ball)
    if not showSpeedLabel then return {Billboard = nil, Label = nil} end
    local existing = billboardCache[ball]
    if existing and existing.Billboard and existing.Billboard.Parent then return existing end
    if existing and existing.Billboard then pcall(function() existing.Billboard:Destroy() end) end
    -- A BillboardGui needs a BasePart to position against. When the ball is a
    -- Model (not a BasePart), parenting straight to it gives the GUI nothing to
    -- anchor to and it renders at the world origin / not at all. Adorn it to the
    -- resolved BasePart so the label sits on the ball for model-balls too.
    local anchorPart = getBallPart(ball) or ball
    local billboard = Instance.new("BillboardGui")
    billboard.Name = "SpeedLabel"
    billboard.AlwaysOnTop = true
    billboard.Size = UDim2.new(0, 100, 0, 40)
    billboard.StudsOffset = Vector3.new(0, 3, 0)
    billboard.Adornee = anchorPart
    billboard.Parent = anchorPart
    local label = Instance.new("TextLabel")
    label.Size = UDim2.new(1, 0, 1, 0)
    label.BackgroundTransparency = 1
    label.TextColor3 = Amber
    label.TextSize = 18
    label.Font = Enum.Font.GothamBold
    label.TextStrokeTransparency = 0.5
    label.Parent = billboard
    billboardCache[ball] = {Billboard = billboard, Label = label}
    return billboardCache[ball]
end

-- Iterates the event-maintained ballsCache instead of re-scanning
-- workspace.Balls:GetChildren() (Auto Parry and Auto Spam previously ran
-- this scan independently every frame - now there's a single shared cache).
-- Returns the closest ball + its distance, and additionally the smallest
-- worst-case time-to-impact across ALL balls (distance / ball speed). That
-- third value lets Panic Burst react to the most imminent threat even when
-- it isn't the closest ball - so in a multi-ball mode a fast ball rushing
-- you can't be ignored just because a slow one is sitting nearer. With a
-- single ball it equals that ball's own TTI, so behavior is unchanged.
local function findClosestBall(humanoidRootPart)
    -- Closest THREATENING ball (aimed at me / unassigned / invisible-closing)
    -- and, separately, the closest ball of ANY target. We PREFER the threatening
    -- one to drive the arc prediction and shield-window: a ball aimed at someone
    -- ELSE that is merely nearer must not shadow the ball actually coming for me
    -- (the "decoy" bug - my real threat fired on too late = a miss at higher
    -- ping, reproduced in the sandbox). But when NOTHING is aimed at me we fall
    -- back to the nearest ball of any target, because a dash-in clash rides the
    -- opponent's OWN ball (Target = them) into you - its nearness is the whole
    -- telegraph, and the parry logic still has to run to pre-shield it.
    local threatBall, threatDist = nil, math.huge
    local closestAnyBall, closestAnyDist = nil, math.huge
    local minThreatTTI = math.huge
    -- Most-imminent CLOSING surface arrival among threatening balls, tracked as
    -- the two smallest (arrival + owning ball) so the caller can EXCLUDE whichever
    -- ball ends up as the closest/threat ball. Why: the closest ball's shield
    -- window is computed by the accurate CURVED arc (surfaceArriveTime); this
    -- straight-line estimate is only a fallback for OTHER threatening balls - a
    -- faster one farther out that the nearest-ball arc can't see (the "two-threat"
    -- miss). Applying the straight-line estimate to the closest ball too would
    -- fire early on a curving side-then-in ball (its partial closing looks like an
    -- arrival that never comes), whiffing and burning the cooldown - so we never
    -- let it override the curve arc for the ball the arc is already handling.
    local minArr1, minArr1Ball, minArr2 = math.huge, nil, math.huge
    local targetedByAny = false
    local myName = LocalPlayer.Name
    for ball in pairs(ballsCache) do
        if not ball.Parent then
            purgeDeadBall(ball)
        else
            local ballPos = getBallPosition(ball)
            if ballPos then
                local distance = (humanoidRootPart.Position - ballPos).Magnitude
                if distance < closestAnyDist then closestAnyDist = distance; closestAnyBall = ball end
                -- Targeting must consider EVERY ball, not just the closest:
                -- the ball assigned to me may not be the nearest one.
                local target = ball:GetAttribute("Target")
                -- Server-hook capture (see serverTargetCache) is the game's own
                -- retarget call. The Target ATTRIBUTE goes stale whenever the
                -- ball is invisible or the round has NoHighlight on (the game
                -- returns before writing it), so a fresh capture OVERRIDES the
                -- attribute: a stale "Target = me" no longer makes us block a
                -- ball that's really aimed at someone else (which burned our
                -- cooldown right before our real ball arrived), and a stale
                -- "Target = them" no longer hides the ball coming for us.
                local sm = serverTargetCache[ball]
                if sm ~= nil and (tick() - sm.time) < SERVER_TARGET_TTL then
                    target = sm.target
                end
                if type(target) ~= "string" then target = nil end
                local serverSaysMe = target == myName
                if serverSaysMe then targetedByAny = true end
                -- Only balls aimed at me (or not yet assigned, or hidden and
                -- closing) can threaten me; a ball assigned to another player
                -- won't hit me, so it must not arm my panic burst.
                -- Invisible balls are a special threat: the game's BallController
                -- bails out of ChangeBallColor BEFORE it writes the Target
                -- attribute whenever a ball is Invisible, so an invisible ball
                -- that retargets onto you may never report target == your name -
                -- which would leave amTargeted false and cause a guaranteed miss
                -- (this is exactly what the Invisibility ability exploits). So
                -- if an invisible ball is actually closing on us, treat it as
                -- aimed at us regardless of its (possibly stale) Target attr.
                local invisible = ball:GetAttribute("Invisible") == true
                if target == myName or target == nil or invisible or serverSaysMe then
                    if distance < threatDist then
                        threatDist = distance
                        threatBall = ball
                    end
                    local vel = getBallVelocityVector(ball)
                    local speed = vel.Magnitude
                    if invisible and speed > 0
                        and vel:Dot(humanoidRootPart.Position - ballPos) > 0 then
                        targetedByAny = true
                    end
                    if speed > 0 then
                        -- Match the closest-ball worst-case TTI: count arrival at
                        -- the ball's SURFACE (its 8-stud hit radius), not its
                        -- center, so a fast NON-closest ball (a second ball, a
                        -- split) arms the panic burst at the same moment the
                        -- closest-ball path would - never a few ms later.
                        local tti = math.max(distance - EFFECTIVE_HIT_RADIUS, 0) / speed
                        if tti < minThreatTTI then minThreatTTI = tti end
                        -- Direction-aware surface arrival for the shield window
                        -- (only if this ball is actually closing on us). Keep the
                        -- two smallest so the closest/threat ball can be excluded.
                        if distance > 1e-3 then
                            local toPlayer = humanoidRootPart.Position - ballPos
                            local closing = vel:Dot(toPlayer) / distance
                            if closing > 0 then
                                local arrive = math.max(distance - EFFECTIVE_HIT_RADIUS, 0) / closing
                                if arrive < minArr1 then
                                    minArr2 = minArr1; minArr1 = arrive; minArr1Ball = ball
                                elseif arrive < minArr2 then
                                    minArr2 = arrive
                                end
                            end
                        end
                    end
                end
            end
        end
    end
    -- Prefer the threatening ball; fall back to the nearest ball of any target
    -- when nothing is aimed at me (dash-in clash). Callers get the closest-any
    -- distance separately for pure-proximity checks (clashIncoming).
    -- The arc ball (threatBall, else the any-ball fallback) is handled by the
    -- curve-aware surfaceArriveTime, so exclude it from the straight-line
    -- most-imminent estimate: if it owns the smallest arrival, hand back the
    -- second smallest (the next threatening ball the arc can't see).
    local arcBall = threatBall or closestAnyBall
    local otherArrive = (minArr1Ball ~= nil and minArr1Ball == arcBall) and minArr2 or minArr1
    if threatBall then
        return threatBall, threatDist, minThreatTTI, targetedByAny, closestAnyDist, otherArrive
    end
    return closestAnyBall, closestAnyDist, minThreatTTI, targetedByAny, closestAnyDist, otherArrive
end

-- The event cache can go stale-FALSE: it's reset on death, but some games
-- keep the Highlight instance alive across deaths and only re-add it when
-- the target changes - in that case no ChildAdded ever fires again and a
-- stale false would permanently disable ALL parrying ("it never blocks").
-- So false is always verified with a direct lookup; a missed event can slow
-- one frame down, never turn the parry off for good.
local function hasPlayerHighlight()
    if hasHighlightCache then return true end
    local folder = workspace:FindFirstChild(LocalPlayer.Name)
    local has = folder ~= nil and folder:FindFirstChild("Highlight") ~= nil
    if has then hasHighlightCache = true end
    return has
end

local function isBallInPlayerRange(ball, distanceRange)
    local ballPos = getBallPosition(ball)
    if not ballPos then return false end
    for _, player in pairs(Players:GetPlayers()) do
        local hrp = getPlayerHRP(player)
        if hrp and (hrp.Position - ballPos).Magnitude <= distanceRange then
            return true
        end
    end
    return false
end

-- Auto Spam only runs during a clash, so it uses the clash send rate (it used
-- the slower lone-ball rate before), and only counts blocks actually sent.
local function executeSpam()
    if fireBlockRemote(true) then totalSpams = totalSpams + 1 end
end

local function checkPlayerDistance()
    local hrp = getPlayerHRP(LocalPlayer)
    if not hrp then return false, nil, math.huge end
    local closestPlayer = nil
    local closestDistance = math.huge
    for _, player in pairs(Players:GetPlayers()) do
        if player ~= LocalPlayer then
            local otherHRP = getPlayerHRP(player)
            if otherHRP then
                local distance = (hrp.Position - otherHRP.Position).Magnitude
                if distance <= SPAM_DETECTION_DISTANCE and distance < closestDistance then
                    closestDistance = distance
                    closestPlayer = player
                end
            end
        end
    end
    return closestPlayer ~= nil, closestPlayer, closestDistance
end

-- Reuses getBallPosition (deep descendant search) and the shared ballsCache
-- so balls with a nested BasePart are no longer silently missed, and the
-- ball folder is no longer re-scanned separately from findClosestBall.
local function checkBallDistance()
    local hrp = getPlayerHRP(LocalPlayer)
    if not hrp then return false, math.huge end
    local closestDistance = math.huge
    for ball in pairs(ballsCache) do
        if not ball.Parent then
            purgeDeadBall(ball)
        else
            local ballPos = getBallPosition(ball)
            if ballPos then
                local distance = (hrp.Position - ballPos).Magnitude
                if distance < closestDistance then closestDistance = distance end
            end
        end
    end
    return closestDistance <= SPAM_DETECTION_DISTANCE, closestDistance
end

task.spawn(function()
    while task.wait(0.5) do
        if destroyed then break end
        setDesc(HUD.QuickStats, string.format("- Total Parries: %d (High Speed: %d)\n- Total Spams: %d\n- Auto Parry: %s\n- Auto Spam: %s",
            totalParries, highSpeedParries, totalSpams,
            autoParryEnabled and "ON" or "OFF",
            autoSpamEnabled and "ON" or "OFF"))

        setDesc(HUD.ParryStats, string.format("- Total Parries: %d\n- High Speed Parries: %d\n- Burst Blocks: %d\n- High Speed Rate: %.1f%%\n- Current Mode: %s\n- Blocks Sent: %d | Shield Up: %d | Rejected: %d\n- Confirmed Parries: %d | Accept Rate: %.0f%% | Last: %s\n- Auto-Unstick: %s (%d recoveries)",
            totalParries, highSpeedParries, totalBurstBlocks,
            totalParries > 0 and (highSpeedParries / totalParries * 100) or 0,
            isHighSpeedMode and "MAX SPEED" or "Normal",
            blockSent, blockLanded, blockRejected, blockParried,
            blockSent > 0 and (blockLanded / blockSent * 100) or 0, lastBlockResult,
            autoUnstick and "ON" or "OFF", totalUnsticks))

        local spamsPerSecond = 0
        if spamStarted and lastSpamStartTime > 0 then
            local currentDuration = tick() - lastSpamStartTime
            if currentDuration > 0 then spamsPerSecond = totalSpams / (spamDuration + currentDuration) end
        elseif spamDuration > 0 then
            spamsPerSecond = totalSpams / spamDuration
        end

        setDesc(HUD.SpamStats, string.format("- Total Spams: %d\n- Total Duration: %.1fs\n- Average Rate: %.1f spam/s\n- Status: %s",
            totalSpams, spamDuration, spamsPerSecond, spamStarted and "ACTIVE" or "INACTIVE"))

        local livePing = getPing()
        setDesc(HUD.PingInfo, string.format("- Current Ping: %.0f ms (smoothed %.0f)\n- Frame Lag: %.0f ms (%.0f FPS)%s\n- Compensation: %s\n- Mode: %s\n- Strength: %.2fx%s\n- Prediction Horizon: %.2fs\n- Last Extra Range: +%.1f studs\n- Last Time-To-Impact: %s",
            livePing, smoothedPing,
            frameLag * 1000, frameLag > 0 and (1 / frameLag) or 0,
            frameLag >= 0.05 and " (LAGGING - firing early)" or "",
            pingCompEnabled and "ON" or "OFF",
            pingAutoEnabled and "AUTO" or "Manual",
            pingAutoEnabled and currentAutoMult or pingMultiplier,
            pingAutoEnabled and " (auto)" or "",
            predictionHorizon,
            currentPingComp,
            currentTimeToImpact < math.huge and string.format("%.2fs", currentTimeToImpact) or "n/a"))
    end
end)

-- Wire up the live-state hooks before anything reads from their caches.
for _, player in pairs(Players:GetPlayers()) do bindPlayer(player) end
track(Players.PlayerAdded:Connect(bindPlayer))
track(Players.PlayerRemoving:Connect(function(player)
    playerHRPCache[player] = nil
    -- Also destroy this player's detector sphere. updatePlayerDetectorSpheres
    -- only iterates CURRENT players, so a departed player's sphere would
    -- otherwise linger in workspace forever, frozen at its last position, and
    -- leak in the playerDetectorSpheres table.
    local sphere = playerDetectorSpheres[player.Name]
    if sphere then sphere:Destroy() end
    playerDetectorSpheres[player.Name] = nil
end))
-- Bind the primary Balls folder through bindBallContainer so it registers as a
-- known container (the reconcile sweep won't double-bind it), then discover any
-- other ball-like containers already present.
watchForNamedChild("Balls", bindBallContainer)
discoverBallContainers()
watchForNamedChild(LocalPlayer.Name, bindHighlightFolder)

-- Grab the game's MovementController so we can read its .Dashing flag. It may
-- not exist immediately, so retry a few times; if it never loads, Dash-Aware
-- simply stays inert (controller nil) and nothing breaks.
task.spawn(function()
    for _ = 1, 15 do
        if destroyed then return end
        local ok, controller = pcall(function()
            return require(ReplicatedStorage:WaitForChild("Framework")):Get("MovementController")
        end)
        if ok and controller then
            Dash.controller = controller
            break
        end
        task.wait(1)
    end
end)

-- Resolve the ball a server call refers to: an Instance, or a ball NAME looked
-- up in workspace.Balls (then any other bound ball container).
resolveBallRef = function(ref)
    if typeof(ref) == "Instance" then return ref end
    if ref == nil then return nil end
    local key = tostring(ref)
    local balls = workspace:FindFirstChild("Balls")
    local found = balls and balls:FindFirstChild(key)
    if found then return found end
    for folder in pairs(boundContainers) do
        if folder.Parent then
            found = folder:FindFirstChild(key)
            if found then return found end
        end
    end
    return nil
end
-- Keep only the NEWEST capture per ball (a deferred lookup must not overwrite a
-- later retarget).
recordServerTarget = function(ball, name, stamp)
    if not isRealBall(ball) then return end
    local prev = serverTargetCache[ball]
    if prev and prev.time > stamp then return end
    serverTargetCache[ball] = { target = name, time = stamp }
    ballsCache[ball] = true
end

-- Hook BallController.Server.ChangeBallColor to capture the SERVER's real target
-- for each ball the instant it retargets. The server invokes this every time a
-- ball is (re)assigned, and for INVISIBLE balls it runs this callback but bails
-- before writing the Target attribute - so this is the only client-visible truth
-- for an invisible ball's target. We record it into serverTargetCache, which
-- findClosestBall consults to arm the panic even when the attribute never names
-- us. Fully pcall-guarded and lazy: if the controller never loads or the game
-- changes the signature, capture just stays inert - it never touches the game's
-- own return value and never breaks parrying.
task.spawn(function()
    local BC
    for _ = 1, 15 do
        if destroyed then return end
        local ok, controller = pcall(function()
            return require(ReplicatedStorage:WaitForChild("Framework")):Get("BallController")
        end)
        if ok and controller and controller.Server
            and type(controller.Server.ChangeBallColor) == "function" then
            BC = controller
            break
        end
        task.wait(1)
    end
    if not BC or destroyed then return end
    local orig = BC.Server.ChangeBallColor
    -- Remember what we patched so Unload() can put the game's own function back.
    ballColorController = BC
    ballColorOriginal = orig
    BC.Server.ChangeBallColor = function(...)
        -- Once unloaded, behave as the untouched game function.
        if destroyed then return orig(...) end
        -- Real signature (decompiled BallController): ChangeBallColor(ballName,
        -- targetName, customColor). The FIRST arg is the ball's NAME inside
        -- workspace.Balls (the game resolves it with Balls:WaitForChild(name)),
        -- not an Instance. The old hook scanned for an Instance + "first string"
        -- and so recorded the ball name as the target and never matched a ball -
        -- the invisible / NoHighlight target capture never worked in-game.
        local ballRef, targetName = ...
        if type(targetName) == "string" then
            local stamp = tick()
            pcall(function()
                local ball = resolveBallRef(ballRef)
                if ball then
                    recordServerTarget(ball, targetName, stamp)
                elseif ballRef ~= nil then
                    -- Ball not replicated yet: resolve it shortly (the game waits
                    -- up to 2s too) without yielding the game's own handler.
                    task.spawn(function()
                        for _ = 1, 20 do
                            task.wait(0.1)
                            if destroyed then return end
                            local b = resolveBallRef(ballRef)
                            if b then recordServerTarget(b, targetName, stamp) return end
                        end
                    end)
                end
            end)
        end
        return orig(...)
    end
end)

-- Hook SwordController.Server.BlockSuccess: the server calls it every time one
-- of our blocks actually PARRIES a ball. That's the only ground truth for "the
-- parry worked" (Block:Invoke usually returns false = shield up, and the parry
-- lands later), so it feeds the Confirmed Parries stat and keeps the unstick
-- watchdog from "recovering" healthy blocking.
task.spawn(function()
    local SC
    for _ = 1, 15 do
        if destroyed then return end
        local ok, controller = pcall(function()
            return require(ReplicatedStorage:WaitForChild("Framework", 5)):Get("SwordController")
        end)
        if ok and type(controller) == "table" and type(controller.Server) == "table"
            and type(controller.Server.BlockSuccess) == "function" then
            SC = controller
            break
        end
        task.wait(1)
    end
    if not SC or destroyed then return end
    local orig = SC.Server.BlockSuccess
    swordController, blockSuccessOriginal = SC, orig
    SC.Server.BlockSuccess = function(...)
        if not destroyed then
            blockParried = blockParried + 1
            blockLanded = blockLanded + 1
            lastBlockResult = "parried"
        end
        return orig(...)
    end
end)

-- ============================================
-- CLIENT GAME FIXES (your client only)
-- ============================================
-- Bugs in the game's OWN client code (decompiled) that hurt blocking. Each is
-- patched on this client only and restored on unload. Every patch is
-- pcall-guarded and skipped if the game's code no longer matches.
local gameFixes = {}  -- { {tbl, key, original}, ... } restored on unload
local function patch(tbl, key, replacement)
    local orig = tbl[key]
    if type(orig) ~= "function" then return nil end
    gameFixes[#gameFixes + 1] = { tbl, key, orig }
    tbl[key] = replacement(orig)
    return orig
end
local function getController(name)
    for _ = 1, 15 do
        if destroyed then return nil end
        local ok, c = pcall(function()
            return require(ReplicatedStorage:WaitForChild("Framework", 5)):Get(name)
        end)
        if ok and type(c) == "table" then return c end
        task.wait(1)
    end
    return nil
end

-- Fix 1: ClashController.Server.StartClash only flips ClashMode (and so the
-- ClashEffect attributes) when your "Clash" visual setting is ON, and Step only
-- applies it on maps that have a BallSpawn. Record the server's real clash
-- state ourselves so clash holding works with effects off / on any map.
task.spawn(function()
    local CC = getController("ClashController")
    if not CC or destroyed or type(CC.Server) ~= "table" then return end
    pcall(function()
        patch(CC.Server, "StartClash", function(orig)
            return function(...)
                if not destroyed then Clash.server = true end
                return orig(...)
            end
        end)
        patch(CC.Server, "EndClash", function(orig)
            return function(...)
                if not destroyed then Clash.server = false end
                return orig(...)
            end
        end)
    end)
end)

-- Fix 2: BallController.GetBallAsync connects a NEW Invisible-changed handler
-- to the ball on every call - and it's called for every ball sound, hit effect
-- and retarget. Over a round that's hundreds of duplicate connections (all
-- firing at once when the ball goes invisible) = growing lag and frame hitches,
-- which make parries late. Let the game connect once per ball, then reuse it.
task.spawn(function()
    local BC = getController("BallController")
    if not BC or destroyed then return end
    pcall(function()
        local seen = setmetatable({}, { __mode = "k" })
        patch(BC, "GetBallAsync", function(orig)
            return function(ref, ...)
                if ref ~= nil and not destroyed then
                    local folder = workspace:FindFirstChild("Balls")
                    local ball = folder and folder:FindFirstChild(tostring(ref))
                    if ball and seen[ball] then
                        BC.CurrentBall = ball
                        return ball
                    end
                end
                local ball = orig(ref, ...)
                if typeof(ball) == "Instance" then seen[ball] = true end
                return ball
            end
        end)
    end)
end)

createVisualSphere()
createPlayerDetectorSpheres()

-- Parry-range sphere. Recreated whenever it's missing (it is destroyed on
-- death; the old code only recreated it if the variable was still set, so the
-- sphere vanished for good after your first death).
local function updateVisualSphere(humanoidRootPart)
    if showVisualSphere then
        if not visualSphere or not visualSphere.Parent then createVisualSphere() end
        local d = currentParryDistance * 2
        visualSphere.Size = Vector3.new(d, d, d)
        visualSphere.Position = humanoidRootPart.Position
        visualSphere.Transparency = 0.7
        visualSphere.Color = isHighSpeedMode and Gold or AccentRed
    elseif visualSphere then
        visualSphere.Transparency = 1
    end
end

-- Auto Spam: split out of the main Heartbeat so that closure stays under Lua
-- 5.1's 60-upvalue cap (the offline test sandbox runs stock 5.1).
local function runAutoSpam(amTargeted, clashDetected, realClash, hudTick)
    if not autoSpamEnabled then
        if spamStarted then
            spamDuration = spamDuration + (tick() - lastSpamStartTime)
            spamStarted = false
        end
        if hudTick then
            setDesc(HUD.SpamStatus, "AUTO SPAM: DISABLED")
            setDesc(HUD.SpamConditions, "Auto Spam is turned off")
        end
        return
    end

    local playerInRange, closestPlayer, playerDistance = checkPlayerDistance()
    local ballInRange, ballDistance = checkBallDistance()

    if hudTick then
        if playerInRange and closestPlayer then
            setDesc(HUD.PlayerDetection, string.format("Player: %s\nDistance: %.1f studs", closestPlayer.Name, playerDistance))
        else
            setDesc(HUD.PlayerDetection, "No players in range")
        end

        if ballInRange then
            setDesc(HUD.BallDetection, string.format("Ball Found\nDistance: %.1f studs", ballDistance))
        else
            setDesc(HUD.BallDetection, string.format("No ball in range\nClosest: %.1f studs", ballDistance))
        end

        setDesc(HUD.HighlightDetection, amTargeted and "Targeted (you)" or "Not targeted")
    end

    -- Start vs. stay conditions differ on purpose:
    --  * START needs proof this clash is YOURS, not one you're standing next
    --    to - the highlight plus (with smart detection) real clash reversals,
    --    so merely jumping around near someone never triggers it.
    --  * STAY only needs the clash to still be going (reversals continuing)
    --    OR the ball still nearby - so highlight flicker between the two
    --    clashers and jump-stretched distances can't drop the spam mid-clash.
    local spamStartCond, spamStayCond
    if Clash.enabled then
        spamStartCond = clashDetected and amTargeted and ballInRange
        spamStayCond = clashDetected or ballInRange
    else
        spamStartCond = playerInRange and ballInRange and amTargeted
        spamStayCond = ballInRange
    end

    if spamStartCond and not spamStarted then
        spamStarted = true
        lastSpamStartTime = tick()
    elseif spamStarted and not spamStayCond then
        spamDuration = spamDuration + (tick() - lastSpamStartTime)
        spamStarted = false
    end

    if spamStarted then
        if hudTick then
            setDesc(HUD.SpamStatus, "AUTO SPAM: ACTIVE\nSpamming block!")
            setDesc(HUD.SpamConditions, string.format("Clash: %s | Ball | Highlight\nClashing - all in!",
                Clash.enabled and (clashDetected and (realClash and "LIVE (game)" or "LIVE (detected)") or "holding") or "off"))
            setDesc(HUD.LiveStats, string.format("- Parry Status: %s\n- Spam Status: SPAMMING\n- Clash: %s (%d flips/%.1fs)\n- Player: %s (%.1f studs)\n- Ball Distance: %.1f studs\n- Total Spams: %d",
                autoParryEnabled and "Active" or "Disabled",
                realClash and "GAME" or (clashDetected and "detected" or "cooling"), #Clash.flipTimes, Clash.WINDOW,
                closestPlayer and closestPlayer.Name or "Unknown", playerDistance, ballDistance, totalSpams))
        end
        executeSpam()
    elseif hudTick then
        setDesc(HUD.SpamStatus, "AUTO SPAM: INACTIVE\nWaiting for a clash...")
        local clashText = Clash.enabled and (clashDetected and "[OK] Clash" or "[--] Clash") or "[off] Clash"
        local conditionText = clashText .. " | " .. (ballInRange and "[OK] Ball" or "[--] Ball") .. " | " .. (amTargeted and "[OK] Targeted" or "[--] Targeted") .. "\nWaiting for a real clash..."
        setDesc(HUD.SpamConditions, conditionText)
        setDesc(HUD.LiveStats, string.format("- Parry Status: %s\n- Spam Status: WAITING\n- Clash Detected: %s (%d flips)\n- Ball in Range: %s\n- Highlight: %s",
            autoParryEnabled and "Active" or "Disabled",
            clashDetected and "Yes" or "No", #Clash.flipTimes,
            ballInRange and "Yes" or "No", amTargeted and "Yes" or "No"))
    end
end

local lastUpdateTime = 0
mainLoopConn = RunService.Heartbeat:Connect(function()
    local currentTime = tick()
    if currentTime - lastUpdateTime < UPDATE_INTERVAL then return end
    lastUpdateTime = currentTime

    -- Display-only status text refreshes at HUD_REFRESH_INTERVAL, never the
    -- parry logic - gate every SetDesc in this loop on hudTick, nothing else.
    local hudTick = (currentTime - lastHudRefresh) >= HUD_REFRESH_INTERVAL
    if hudTick then lastHudRefresh = currentTime end

    local humanoidRootPart = getPlayerHRP(LocalPlayer)
    if not humanoidRootPart then return end

    -- Self-healing detection: sweep every ball-like container for anything the
    -- event hooks missed (differently-named/replaced folder, lost ChildAdded).
    -- Self-throttled, so calling it every frame is cheap.
    reconcileBalls(currentTime)

    -- Sample the camera (facing + turn rate) and measure client frame lag for
    -- this frame. Kept as a single call returning a closure-LOCAL frameLag so
    -- neither the lag state nor the camera sampler costs the big Heartbeat
    -- closure any upvalues (Lua 5.1's 60-per-function cap).
    local frameLag = updatePerFrame(currentTime)

    -- Keep the spam-detector spheres tracking players regardless of parry
    -- state - previously this only ran inside the parry-with-ball branch,
    -- so the spheres froze in place whenever no ball existed (between
    -- rounds) or Auto Parry was toggled off.
    updatePlayerDetectorSpheres()

    local hasHighlight = hasPlayerHighlight()
    local closestBall, closestDistance, minThreatTTI, targetedByAny, closestAnyDist, minThreatArrive = findClosestBall(humanoidRootPart)

    -- The ball controller stores its assigned target as an attribute
    -- (ball:SetAttribute("Target", playerName)); that is the game's own
    -- source of truth for "this ball is coming for ME". Unlike the highlight
    -- it also works for invisible balls, whose highlight is force-disabled.
    -- targetedByAny checks every ball (not just the closest), OR'd with the
    -- highlight so it's strictly more reliable, never less.
    local amTargeted = hasHighlight or targetedByAny

    -- Clash detection: count rapid direction reversals of the closest ball.
    -- Runs outside the parry branch so Auto Spam's clash sensing works even
    -- with Auto Parry toggled off.
    local ballPos, ballVel
    if closestBall then
        ballPos = getBallPosition(closestBall)
        ballVel = getBallVelocityVector(closestBall)
        if Clash.lastVelBall == closestBall and Clash.lastVelVec then
            local m1, m2 = Clash.lastVelVec.Magnitude, ballVel.Magnitude
            if m1 > Clash.MIN_SPEED and m2 > Clash.MIN_SPEED
                and Clash.lastVelVec:Dot(ballVel) / (m1 * m2) < -0.3 then
                table.insert(Clash.flipTimes, currentTime)
            end
        end
    end
    Clash.lastVelBall = closestBall
    Clash.lastVelVec = ballVel
    while #Clash.flipTimes > 0 and currentTime - Clash.flipTimes[1] > Clash.WINDOW do
        table.remove(Clash.flipTimes, 1)
    end
    -- Authoritative clash state from the game itself: the ClashController sets
    -- workspace.Effects.ClashEffect (and the active ball's ClashEffect attr)
    -- to true during a real clash and clears it on EndClash. That's ground
    -- truth - the velocity-reversal count below is kept only as a fallback for
    -- when those attributes aren't present.
    -- A clash always has a ball in play; with none left it's over even if the
    -- server's EndClash never reached us (so a stale flag can't make us spam).
    if not closestBall then Clash.server = false end
    local realClash = Clash.server == true
    local effects = workspace:FindFirstChild("Effects")
    if realClash then
        -- server said so (settings-independent)
    elseif effects and effects:GetAttribute("ClashEffect") == true then
        realClash = true
    elseif closestBall and closestBall:GetAttribute("ClashEffect") == true then
        realClash = true
    end
    -- Hold the authoritative clash signal through brief flickers (see Clash.GRACE):
    -- arm the grace whenever it's genuinely on, and treat the clash as active for
    -- GRACE seconds afterward so a one-frame blink of ClashEffect can't stop the
    -- force-fire mid-exchange and let a return through.
    if realClash then Clash.forceUntil = currentTime + Clash.GRACE end
    local clashActive = realClash or currentTime < Clash.forceUntil
    local clashDetected = clashActive or (#Clash.flipTimes >= Clash.MIN_FLIPS)

    if hudTick and not (autoParryEnabled and closestBall) then
        setDesc(HUD.ParryStatus, autoParryEnabled and "Status: ACTIVE - waiting for a ball" or "Status: DISABLED")
    end

    if autoParryEnabled and closestBall then
        local ballInDetectorRange = isBallInPlayerRange(closestBall, PLAYER_DETECTOR_DISTANCE)
        local velocity = ballVel and ballVel.Magnitude or 0
        local closingSpeed = ballPos and getClosingSpeed(ballPos, ballVel, humanoidRootPart.Position) or 0
        local ballAccel, ballOmega, ballAxis = Vector3.new(), 0, nil
        if ballPos then
            ballAccel, ballOmega, ballAxis = updateBallCurvature(closestBall, ballVel, currentTime)
        end
        currentCurveAccel = ballAccel.Magnitude
        currentTurnRate = ballOmega or 0

        if velocity >= HIGH_SPEED_THRESHOLD then
            if not isHighSpeedMode then
                isHighSpeedMode = true
                currentParryDistance = MAX_DISTANCE
                targetParryDistance = MAX_DISTANCE
            end
        else
            if isHighSpeedMode then isHighSpeedMode = false end
        end

        -- Single, unambiguous freeze rule: hold the current detection radius
        -- while the ball sits inside another player's melee range or isn't
        -- moving at all; release it the instant neither is true anymore.
        -- (Replaces two separate, partially-contradictory freeze/unfreeze
        -- blocks that could re-freeze immediately after unfreezing.)
        local shouldFreeze = ballInDetectorRange or velocity == 0
        if shouldFreeze and not isAutoParryFrozen then
            isAutoParryFrozen = true
            frozenParryDistance = currentParryDistance
        elseif not shouldFreeze and isAutoParryFrozen then
            isAutoParryFrozen = false
        end

        if not isHighSpeedMode then targetParryDistance = calculateDistance(velocity) end

        if not isAutoParryFrozen and not isHighSpeedMode then
            if currentTime - lastDistanceUpdate >= 0.1 then
                if currentParryDistance ~= targetParryDistance then
                    if currentParryDistance < targetParryDistance then
                        -- Expand the detection range INSTANTLY. Previously it grew
                        -- at only +0.4 per 0.1s (4 studs/s): after a clash - where
                        -- the slow/reversing ball shrinks the range toward its
                        -- speed-scaled minimum - it took ~8 seconds to recover, and
                        -- during that time any ball outside the collapsed radius
                        -- went undetected and unblocked ("clash ends, I walk, it no
                        -- blocks"). Growing instantly can only ADD safety; a bigger
                        -- range never causes a miss. Shrinking stays gradual so the
                        -- range doesn't twitch on a momentary speed dip.
                        currentParryDistance = targetParryDistance
                    elseif currentParryDistance > targetParryDistance then
                        currentParryDistance = math.max(currentParryDistance - 10, targetParryDistance)
                    end
                    lastDistanceUpdate = currentTime
                end
            end
        elseif isAutoParryFrozen then
            currentParryDistance = frozenParryDistance
        end

        -- Ping compensation / future prediction: extend the trigger range so
        -- high-ping clients fire early enough that the block still lands on
        -- the server in time. Uses closing speed (not raw speed) so a ball
        -- moving away or past the player never triggers an early parry.
        local leadTime = getPingLeadTime()
        local pingComp = getPingCompensation(closingSpeed, leadTime)
        local effectiveParryDistance = currentParryDistance + pingComp

        -- Parry if the ball is already inside melee range, OR if its
        -- predicted path enters melee range before our ping round-trip
        -- completes. With Anti-Curve on, the path is a simulated curved arc
        -- (using measured curvature) rather than a straight line, so a
        -- curving/homing ball is caught too, not just ones flying straight.
        -- The look-ahead runs to the larger of the ping lead and the panic
        -- window, so time-to-impact is known even at low ping - previously
        -- prediction only looked ping-far ahead, which at 30ms ping meant a
        -- 30ms warning against a 500 stud/s ball.
        local withinRange = closestDistance <= currentParryDistance
        local willArriveInTime = false
        local panicNow = false
        -- A ball inside your parry radius whose imminent arrival lands within the
        -- panic window is a threat REGARDLESS of amTargeted/ClashEffect. This
        -- closes two gaps: (1) the first frame of a super-close clash, where the
        -- ball's Target hasn't replicated and ClashEffect isn't set yet, and
        -- (2) fast/hard-curving balls that fly sideways and only turn onto you at
        -- the last instant. The actual condition (computed below, once
        -- worstCaseTTI/effectivePanicTTI exist) is direction-AGNOSTIC: in-range
        -- AND (worst-case raw-speed arrival OR curve-predicted arrival) within the
        -- window - deliberately NOT gated on closing speed, since a curving ball's
        -- closing speed is <= 0 right up until it snaps in.
        local imminentThreat = false
        -- coverable: is the ball's impact within the window a block fired NOW
        -- would actually protect (ping + BLOCK_DURATION + frameLag)? Set inside
        -- the ballPos block once the TTIs are known; gates the fire so we don't
        -- burn the cooldown too early. Pre-declared here so the fire block below
        -- (outside the ballPos scope) can read it.
        local coverable = false
        -- surfaceArriveTime: predicted seconds until the ball's actual (curved)
        -- path brings it within a body-radius (EFFECTIVE_HIT_RADIUS) of you - the
        -- direction/curve-aware trigger for the shield window below. huge = the
        -- ball's path does not reach your body soon (e.g. it's glancing past),
        -- so we must NOT fire (that whiffs and burns the cooldown).
        local surfaceArriveTime = math.huge
        currentTimeToImpact = math.huge
        if ballPos then
            -- The block fired now protects for BLOCK_DURATION, starting after a
            -- ping round-trip; this is the furthest-out impact it can still
            -- cover. Also the horizon we search and the gate we fire within.
            local coverWindow = (currentPing / 1000) + BLOCK_DURATION + frameLag
            -- Look-ahead must reach AT LEAST the coverage window, plus frameLag
            -- for laggy clients. Previously it was only ~PANIC_TTI (0.45s) - too
            -- short: when you MOVE, your own speed closes the gap so the ball
            -- reaches you further out in time than a 0.45s arc ever sees, so the
            -- arc never found the arrival, currentTimeToImpact stayed huge, and
            -- the coverable gate suppressed the block ("moving, no block").
            local lookahead = math.max(currentRequiredLead + frameLag,
                panicBurstEnabled and (PANIC_TTI + frameLag) or 0, coverWindow)
            if antiCurveEnabled and lookahead > 0 then
                local playerVel = humanoidRootPart.AssemblyLinearVelocity
                -- Mid-jump the player follows a gravity arc, not a straight
                -- line up - project the fall only while airborne (a grounded
                -- humanoid counteracts gravity).
                local character = humanoidRootPart.Parent
                local humanoid = character and character:FindFirstChildOfClass("Humanoid")
                local airborne = humanoid ~= nil and humanoid.FloorMaterial == Enum.Material.Air
                local playerGravity = airborne and workspace.Gravity or 0
                -- Camera-relative movement hypothesis: you can break into a
                -- move/dash toward where the camera faces at any moment, so also
                -- test the ball's arc against that path at (at least) walk speed.
                local camDir, camSpeed = nil, 0
                if Camera.aware then
                    camDir = Camera.flatDir
                    -- Use 16 only as the no-humanoid fallback, NOT when WalkSpeed
                    -- is a real 0: `humanoid and WalkSpeed or 16` would read a
                    -- rooted (WalkSpeed==0) player as able to sprint at 16 and
                    -- over-predict the camera-dodge path. When rooted, the
                    -- camera-move speed is just your current velocity.
                    local walkSpeed = humanoid and humanoid.WalkSpeed
                    if walkSpeed == nil then walkSpeed = 16 end
                    camSpeed = math.max(playerVel.Magnitude, walkSpeed)
                end
                local arrives, arriveTime = predictCurvedImpact(
                    ballPos, ballVel, ballAccel, humanoidRootPart.Position, playerVel, playerGravity,
                    currentParryDistance, lookahead, nil, ballOmega, ballAxis, camDir, camSpeed)
                if arrives then
                    currentTimeToImpact = arriveTime
                elseif closingSpeed > 0 then
                    currentTimeToImpact = math.max(closestDistance - EFFECTIVE_HIT_RADIUS, 0) / closingSpeed
                end
                willArriveInTime = pingCompEnabled and arrives and arriveTime <= currentRequiredLead
                -- Same curved-arc sim but tested against a BODY-radius sphere, to
                -- decide when the ball's real path actually reaches YOU (the shield
                -- window trigger). Short horizon - we only care about arrivals
                -- inside the shield-coverage window, never the far future.
                local sArr, sT = predictCurvedImpact(
                    ballPos, ballVel, ballAccel, humanoidRootPart.Position, playerVel, playerGravity,
                    EFFECTIVE_HIT_RADIUS, math.min(lookahead, 1.0), nil, ballOmega, ballAxis, camDir, camSpeed)
                if sArr then surfaceArriveTime = sT end
            elseif closingSpeed > 0 then
                currentTimeToImpact = math.max(closestDistance - EFFECTIVE_HIT_RADIUS, 0) / closingSpeed
                willArriveInTime = pingCompEnabled and currentRequiredLead > 0
                    and ((closestDistance - currentParryDistance) / closingSpeed) <= currentRequiredLead
                -- Anti-Curve off: no arc, so fall back to the straight-line closing
                -- estimate for the shield-window trigger.
                surfaceArriveTime = currentTimeToImpact
            end
            -- Worst-case bound: a fast-curving ball can turn fully onto you
            -- at any moment, so the estimated time-to-impact (which trusts
            -- the ball's current direction) is not enough on its own. If the
            -- ball's raw speed could carry it to you within the panic window
            -- - regardless of where it's pointed right now - and you're the
            -- highlighted target, treat impact as imminent. This is what
            -- makes the burst immune to both hard curves and the player's
            -- own jump/dash movement scrambling the direction estimates.
            -- This is the game's own block-timing formula, verified from
            -- BallController: impactTime = (distance - BALL_HIT_RADIUS) / speed,
            -- using the ball's raw AssemblyLinearVelocity magnitude. Subtracting
            -- the 8-stud hit radius means we treat the ball as landing when its
            -- surface reaches us, exactly like the game does - firing the burst
            -- a touch earlier and never a frame too late.
            -- Include the PLAYER's own speed in the closing rate. When you move
            -- crazy (dash/jump/strafe), you and the ball can close on each other
            -- far faster than the ball travels alone - worst case, both rush
            -- together at ball speed + your speed. Counting only the ball made
            -- the burst arm too late while you were moving fast at high ping (the
            -- block was sent, but the real gap had already closed). Adding your
            -- speed shrinks the worst-case TTI exactly when you're moving hard,
            -- so the burst opens early enough to still land.
            local playerSpeed = humanoidRootPart.AssemblyLinearVelocity.Magnitude
            local closeRate = velocity + playerSpeed
            local worstCaseTTI = closeRate > 0
                and (math.max(closestDistance - EFFECTIVE_HIT_RADIUS, 0) / closeRate) or math.huge
            -- The ball's impact is coverable if ANY realistic estimate puts it
            -- inside the block's coverage window: the arc/closing prediction
            -- (currentTimeToImpact) OR the movement-aware worst case (which adds
            -- YOUR speed to the closing rate) OR a second, faster ball
            -- (minThreatTTI). Including worstCaseTTI is what fixes "moving, no
            -- block": when you run at the ball your own speed makes it arrive
            -- sooner, and only this term sees that.
            coverable = currentTimeToImpact <= coverWindow
                or worstCaseTTI <= coverWindow
                or (minThreatTTI or math.huge) <= coverWindow
            -- withinRange is included explicitly: a ball already inside the
            -- parry radius is always an imminent threat, even when its
            -- time-to-impact estimate is unusable (hovering pre-serve at
            -- zero velocity, orbiting with no closing speed, or Anti-Curve
            -- disabled). Burst-while-inside beats one parry per 0.3s.
            -- minThreatTTI covers ALL balls, so a second, faster ball that
            -- isn't the closest still arms the burst.
            -- Ping-scaled panic window. THIS is why high-ping (180-200ms+)
            -- players couldn't block: the ball you see is ~half-a-ping stale
            -- AND the Block invoke takes a round-trip to register, so the
            -- burst must START firing earlier the higher the ping. A fixed
            -- window (~0.45s) simply doesn't begin soon enough at 200 ping -
            -- by the time TTI drops under 0.45s the block already can't reach
            -- the server before the (already-stale) ball connects. Add the
            -- ping lead (currentRequiredLead, which scales with smoothed ping)
            -- to the window so at 200 ping the burst opens ~0.75s out. Capped
            -- at ping + BLOCK_DURATION so the block's 0.6s protection window
            -- still covers the ball's actual arrival and never expires early.
            -- At low ping currentRequiredLead ~= 0, so this is a no-op.
            -- frameLag widens the window (and its ceiling) too: a laggy client
            -- must open the burst frameLag earlier so the last frame before a
            -- stutter still fires, and the ceiling grows with it so that clamp
            -- doesn't cancel the compensation out.
            local pingSec = currentPing / 1000
            local effectivePanicTTI = math.clamp(PANIC_TTI + currentRequiredLead + frameLag,
                PANIC_TTI, pingSec + frameLag + BLOCK_DURATION)
            panicNow = panicBurstEnabled
                and (withinRange or currentTimeToImpact <= effectivePanicTTI
                    or worstCaseTTI <= effectivePanicTTI or (minThreatTTI or math.huge) <= effectivePanicTTI)

            -- Target-agnostic imminent threat: a ball inside the effective parry
            -- radius whose imminent arrival lands within the (ping-scaled) panic
            -- window fires the block even if Target/ClashEffect haven't arrived.
            -- Deliberately NOT gated on closingSpeed > 0: a hard-curving ball
            -- (e.g. Wind Shuriken) moves SIDEWAYS and only sharp-turns into you at
            -- the last moment, so its closing speed is <= 0 right up until impact -
            -- gating on it meant curving/fast balls slipped through when amTargeted
            -- also flickered. Instead we use the direction-agnostic worst-case
            -- (raw speed could carry it to us) OR the anti-curve predicted arrival,
            -- so a ball that COULD reach us in time is blocked regardless of where
            -- it's pointed this frame. Erring toward blocking is the right bias -
            -- an extra block is harmless (server gates the cooldown), a miss loses.
            imminentThreat = panicBurstEnabled
                and closestDistance <= effectiveParryDistance
                and (worstCaseTTI <= effectivePanicTTI
                    or currentTimeToImpact <= effectivePanicTTI)

            -- Dash-aware: while you're dashing (and briefly after), your
            -- position is changing so fast that the "it'll miss me" math is
            -- unreliable - the dash ends and the ball catches up. So during
            -- the dash grace, if a targeting ball is anywhere near, force the
            -- burst instead of trusting the prediction. This is what stops a
            -- dash from causing a missed block.
            if Dash.aware and Dash.controller then
                if Dash.controller.Dashing == true then Dash.endTime = currentTime end
                if (currentTime - Dash.endTime) <= Dash.GRACE
                    and closestDistance <= effectiveParryDistance + Dash.MARGIN then
                    panicNow = true
                end
            end

            -- Camera-whip-aware: a hard camera whip is the tell of a panic dodge
            -- (you spin the camera, then dash/strafe that way). Your position
            -- becomes unpredictable for that moment, so - like Dash-aware - stop
            -- trusting the "it'll miss" math and force the burst on any nearby
            -- targeting ball. This directly kills the "I move/look around crazy
            -- and it misses" case.
            if Camera.aware and Camera.angVel >= Camera.WHIP_RATE
                and (amTargeted or clashActive)
                and closestDistance <= effectiveParryDistance + Camera.MARGIN then
                panicNow = true
            end
        end

        if hudTick then
            setDesc(HUD.ParryStatus, string.format("Status: %s", autoParryEnabled and "ACTIVE" or "DISABLED"))
            setDesc(HUD.ParryDistance, string.format("- Detection Range: %.1f studs\n- Ping Comp: +%.1f studs (%.0f ms, lead %.2fs)\n- Effective Range: %.1f studs\n- Ball Speed: %.1f studs/s (closing: %.1f)\n- Curve: %.1f studs/s^2 | Turn: %.0f deg/s (%s)\n- Camera: %.0f deg/s%s\n- Distance to Ball: %.1f studs\n- Time-To-Impact: %s\n- Panic Burst: %s\n- Mode: %s\n- Frozen: %s",
                currentParryDistance, pingComp, currentPing, currentRequiredLead, effectiveParryDistance, velocity, closingSpeed,
                currentCurveAccel, math.deg(currentTurnRate), antiCurveEnabled and "ON" or "OFF",
                math.deg(Camera.angVel), Camera.angVel >= Camera.WHIP_RATE and " (WHIP)" or "", closestDistance,
                currentTimeToImpact < math.huge and string.format("%.2fs", currentTimeToImpact) or "n/a",
                panicNow and "FIRING" or (panicBurstEnabled and "armed" or "off"),
                isHighSpeedMode and "MAX SPEED" or "Normal",
                isAutoParryFrozen and "Yes" or "No"))
        end

        if hudTick and showSpeedLabel then
            local speedLabel = createSpeedLabel(closestBall)
            if speedLabel.Label then
                speedLabel.Label.Text = string.format("%.1f%s", velocity, isHighSpeedMode and " [FAST]" or "")
            end
        end

        -- During a real, game-confirmed clash we fire regardless of amTargeted:
        -- the ball's Target attribute flips to the OTHER clasher every time it
        -- heads their way, so amTargeted drops false for a fraction of a second
        -- each exchange - and if Auto Spam is off, nothing would fire in that
        -- gap and the ball returns before we react. Because we're one of the two
        -- clashers, the ball is always about to come back; blocking every frame
        -- keeps a fresh 0.6s block up for every return, and the server resets
        -- the block cooldown on each successful parry, so this holds a clash
        -- indefinitely. realClash (workspace.Effects/ball ClashEffect) is the
        -- game's own authoritative signal (held briefly through flickers by
        -- clashActive), so this can't false-fire outside a genuine clash.
        --
        -- fastClashHold: a point-blank, super-fast clash (you're inside each
        -- other, the ball reversing every frame) sometimes never sets ClashEffect
        -- and its Target flickers too fast for amTargeted to catch. But a ball
        -- flipping direction every frame is EXACTLY what the reversal detector
        -- picks up instantly (clashDetected), so if that fires while the ball is
        -- in our parry radius, force the block too - this is what keeps a
        -- super-close, super-fast clash held. Scoped to withinRange so a lone
        -- ball bouncing near other players can't trip it.
        local fastClashHold = clashDetected and withinRange
        -- Surface-arrival time (raw distance / raw speed) and the shield-coverage
        -- lead, computed here because BOTH pointBlank and the lone-ball window
        -- below need them. shieldLead is the window in which a block fired now
        -- still has its 0.6s shield covering impact (centred with ping so a stale
        -- ball / late-registering block still lands). See the lone-ball note below.
        local shieldLead = math.clamp(0.3 + (currentPing / 1000), 0.25, 0.7)
        local surfaceTTI = velocity > 0
            and (math.max(closestDistance - EFFECTIVE_HIT_RADIUS, 0) / velocity) or math.huge
        -- Point-blank guarantee: a ball essentially ON TOP of you (you're inside
        -- each other) MUST be blocked continuously. At thousands of studs/s inside
        -- each other the ball reverses many times per frame, the reversal detector
        -- can alias, and Target/ClashEffect never settle - but a 0.6s block covers
        -- ALL of those reversals, and firing it every frame keeps one always up.
        -- TIME-gated as well as distance-gated: the 22-stud radius alone fires
        -- continuously the instant a SLOW ball enters it (~0.7s out at 20 studs/s),
        -- which whiffs the first block and burns the 1s cooldown before impact (a
        -- real miss the sandbox caught). So require the ball to be genuinely
        -- imminent (inside the shield window) OR stationary-on-you (a hovering
        -- pre-serve ball at zero speed) - a real point-blank clash ball is fast
        -- and close, so surfaceTTI is tiny and this still holds.
        local pointBlank = closestBall ~= nil and closestDistance <= (EFFECTIVE_HIT_RADIUS + 11)
            and (surfaceTTI <= shieldLead or velocity == 0)
        -- Clash-incoming PRE-SHIELD. The way you die to "they dash into me and
        -- clash inside me": once the ball is hit from INSIDE you it lands in a few
        -- ms - far under one ping - so reacting to the ball is hopeless. But the
        -- opponent's DASH is a ~0.3s telegraph. So the instant an opposing player
        -- is dashing INTO you (closing fast) at close range with a ball in play, we
        -- start firing NOW - a 0.6s shield goes up during their approach and is
        -- already covering you when the point-blank clash begins. Gated tight
        -- (opponent within CLASH_NEAR and closing >= CLASH_DASH_SPEED, or already
        -- overlapping you) so ordinary nearby movement doesn't trip it; a wasted
        -- pre-shield is harmless (server cooldown-gates it). Off with Clash toggle.
        local clashIncoming = false
        -- Uses closestAnyDist (nearest ball of ANY target), not closestDistance:
        -- in a dash-in clash the opponent rides their OWN ball (Target = them)
        -- into you, so it isn't a "threatening" ball by attribute, but its
        -- nearness is exactly the telegraph we pre-shield on.
        if Clash.enabled and closestAnyDist <= 34 then
            for _, pl in ipairs(Players:GetPlayers()) do
                if pl ~= LocalPlayer then
                    local ohrp = getPlayerHRP(pl)
                    if ohrp then
                        local off = humanoidRootPart.Position - ohrp.Position
                        local od = off.Magnitude
                        if od <= 18 then
                            local ov = ohrp.AssemblyLinearVelocity
                            local oClose = od > 1e-3 and ov:Dot(off) / od or 0
                            if od <= 9 or oClose >= 45 then clashIncoming = true break end
                        end
                    end
                end
            end
        end
        -- coverable (computed above) holds fire for a normal incoming ball until
        -- its impact is within the window a block fired now would actually cover
        -- (ping + BLOCK_DURATION + frameLag). This stops the block being sprayed
        -- too early and burning the server's 1s cooldown into a ~0.4s gap where
        -- the ball lands unblocked ("misses most of the time"). Clash /
        -- point-blank fire EVERY frame regardless: there each successful parry
        -- resets the cooldown, so continuous fire stays protected and holds the
        -- exchange indefinitely.
        -- IMPORTANT (why we do NOT continuously spam a lone incoming ball):
        -- a block is a 0.6s shield that only activates on the server ~half-a-ping
        -- after we fire, and a block that lands on NOTHING still spends the server's
        -- 1s cooldown (only a *successful* parry resets it). So firing every frame
        -- from far out makes the FIRST (too-early) block whiff and cooldown-lock
        -- us, and the ball then arrives while we're still locked out = guaranteed
        -- miss. Continuous fire is therefore reserved for clashes / point-blank
        -- (where each parry resets the cooldown, so it stays protected). A lone
        -- ball is handled by the panic burst, which only opens inside the tight
        -- window where the shield actually covers impact.
        local alwaysFire = clashActive or fastClashHold or pointBlank or clashIncoming
        -- Shield-window gate for a LONE incoming ball. `coverable` uses
        -- coverWindow = ping + BLOCK_DURATION, which is actually TOO EARLY: a
        -- block is only a 0.6s shield that activates ~half-a-ping after we fire,
        -- so a block fired a whole ping+0.6 out has its shield EXPIRE before the
        -- ball arrives, and the 1s server cooldown then locks out the re-block -
        -- the "dead-zone miss" (first block 0.6-1.0s before impact), which the
        -- sandbox reproduced for fast lone balls. So the lone-ball fire is gated
        -- to the window where the 0.6s shield actually still covers impact:
        -- ~BLOCK_DURATION minus a small margin, widened by ping (the ball we see
        -- is stale and the block registers a ping late, so fire that much
        -- earlier). Clash / point-blank bypass this and fire every frame - there
        -- each successful parry resets the cooldown, so continuous fire stays
        -- protected. The window opens on the ball's CLOSING-based surface arrival
        -- (distance / closing speed) - direction-aware on purpose: a ball flying
        -- SIDEWAYS or past you (closing speed <= 0) must NOT open it, or its block
        -- whiffs and burns the 1s cooldown before the ball actually curves in (the
        -- sandbox caught this on a Wind-Shuriken "side then snap" ball). A curving
        -- ball opens the window the instant it turns toward you and starts
        -- closing, which still leaves the 0.6s shield covering impact. The
        -- anti-curve arrival (willArriveInTime) and the panic paths below add the
        -- extra coverage for hard/late curves; pointBlank covers a ball already
        -- on top of you regardless of direction.
        --
        -- surfaceArriveTime is the CLOSEST ball's curved-arc arrival; minThreatArrive
        -- is the soonest CLOSING arrival across ALL threatening balls. Opening the
        -- window on either means a fast threatening ball farther out isn't shadowed
        -- by a nearer slow one (the "two-threat" miss the sandbox reproduced) - and
        -- because minThreatArrive is closing-gated too, a sideways/passing ball
        -- still can't open it.
        local inShieldWindow = surfaceArriveTime <= shieldLead or minThreatArrive <= shieldLead
        if amTargeted or clashActive or imminentThreat or fastClashHold or pointBlank or clashIncoming then
            if (withinRange or willArriveInTime or clashIncoming) and (alwaysFire or (coverable and inShieldWindow)) then executeParry(alwaysFire) end
            -- Fire block every frame while the shield window is open (or mid-clash
            -- / point-blank), so jitter in the estimate can't leave a gap - the
            -- FIRST block sets a shield that covers impact, later ones are
            -- cooldown-gated by the server and harmless.
            if alwaysFire or ((panicNow or imminentThreat) and coverable and inShieldWindow) then
                if fireBlockRemote(alwaysFire) then   -- clash/point-blank -> faster clash send rate
                    totalBurstBlocks = totalBurstBlocks + 1
                end
            end
        end
    end

    updateVisualSphere(humanoidRootPart)
    runAutoSpam(amTargeted, clashDetected, realClash, hudTick)
end)

track(LocalPlayer.CharacterRemoving:Connect(function()
    if visualSphere then visualSphere:Destroy() visualSphere = nil end
    clearPlayerDetectorSpheres()
    isHighSpeedMode = false
    Clash.server = false  -- dying ends your clash
    -- The highlight lives under the (now removed) character's workspace
    -- entry; without this reset the cache holds its last value until the
    -- respawned character rebinds, letting a phantom highlight gate parries
    -- while dead.
    hasHighlightCache = false
end))

-- Movement guard, in its own connection so it doesn't add to the main
-- Heartbeat closure's upvalue count (Lua 5.1's 60-per-function limit). Learns
-- the game's real walk speed from the last non-zero value seen, and restores
-- it whenever a block roots the character - so blocking never interrupts
-- movement. Toggle: Main tab > Keep Moving While Blocking.
moveGuardConn = RunService.Heartbeat:Connect(function()
    if not Move.keep then return end
    local hrp = getPlayerHRP(LocalPlayer)
    if not hrp then return end
    local character = hrp.Parent
    local humanoid = character and character:FindFirstChildOfClass("Humanoid")
    if not humanoid then return end
    local ws = humanoid.WalkSpeed
    if ws > 0.5 then
        Move.cachedSpeed = ws
    elseif Move.cachedSpeed > 0.5 then
        humanoid.WalkSpeed = Move.cachedSpeed
    end
end)

-- Stuck-block watchdog. Own connection (throttled to ~5Hz) so it adds no
-- upvalues to the main Heartbeat closure. It watches for the one state that
-- means blocking is genuinely stuck - a ball is targeting us and sitting in
-- range, yet NO block has landed for a full UNSTICK_TIMEOUT window - and clears
-- whatever wedged: a stale SwordService proxy, a jammed freeze/parry-cooldown
-- latch, or a WalkSpeed a block left at zero. In healthy play a landing block
-- (each successful parry returns truthy) keeps refreshing the timer, so this
-- only fires when parrying has actually stopped working. Every recovery action
-- is a harmless reset, so a rare false trigger costs nothing.
local unstickLastCheck = 0
local unstickLandedMark = 0
local unstickHealthyTime = tick()
track(RunService.Heartbeat:Connect(function()
    if destroyed or not autoUnstick then return end
    local now = tick()
    if now - unstickLastCheck < 0.2 then return end
    unstickLastCheck = now

    -- A block landed since last check => things work; keep the timer fresh.
    if blockLanded > unstickLandedMark then
        unstickLandedMark = blockLanded
        unstickHealthyTime = now
    end

    -- Is a ball that's targeting us actually on us right now?
    local hrp = autoParryEnabled and getPlayerHRP(LocalPlayer) or nil
    local onMe = false
    if hrp then
        local cb, cd, _, targeted = findClosestBall(hrp)
        onMe = cb ~= nil and (targeted or hasPlayerHighlight())
            and cd <= (currentParryDistance + EFFECTIVE_HIT_RADIUS)
    end
    if not onMe then
        unstickHealthyTime = now  -- no threat => not stuck
        return
    end

    -- Ball on us + nothing landing for the whole window => stuck. Unstick it.
    if now - unstickHealthyTime >= UNSTICK_TIMEOUT then
        swordServiceProxy = nil    -- drop a possibly-dead proxy; re-fetched next fire
        isAutoParryFrozen = false  -- release a jammed detection-range freeze
        lastParryTime = 0          -- clear the parry cooldown latch (fire immediately)
        -- Restore WalkSpeed if a block left us rooted (even with Keep Moving off).
        pcall(function()
            local character = hrp.Parent
            local humanoid = character and character:FindFirstChildOfClass("Humanoid")
            if humanoid and humanoid.WalkSpeed <= 0.5 and Move.cachedSpeed > 0.5 then
                humanoid.WalkSpeed = Move.cachedSpeed
            end
        end)
        totalUnsticks = totalUnsticks + 1
        unstickHealthyTime = now   -- give the recovery a fresh window before re-arming
        -- Silent by design: recovery can fire once a second while a ball sits on
        -- you, and a toast every second is pure noise. The running count is on the
        -- Statistics tab (Auto-Unstick) for anyone who wants to see it.
    end
end))

-- ============================================
-- UNLOAD IMPLEMENTATION
-- ============================================
-- Defined here (not up top) because it touches everything created above:
-- connections, the hooked controller, the spawned Instances and the Window.
-- Idempotent - safe to call twice, and safe to call from the button, the
-- getgenv handle, or the re-exec guard.
unloadScript = function()
    if destroyed then return end
    destroyed = true  -- background loops + the ChangeBallColor hook go inert

    -- Persist any unsaved setting change before tearing down.
    if settingsDirty then settingsDirty = false; saveSettings() end

    -- Notify BEFORE we tear the UI down (the toast survives the window closing).
    notify("Anime Ball Hub Unloaded", "All loops, hooks and visuals removed", 4)
    uiReady = false

    -- Stop both Heartbeat loops - no more per-frame parry/block firing or HUD work.
    if mainLoopConn then pcall(function() mainLoopConn:Disconnect() end) mainLoopConn = nil end
    if moveGuardConn then pcall(function() moveGuardConn:Disconnect() end) moveGuardConn = nil end

    -- Drop every registered event connection (ball/highlight/player/workspace hooks).
    for _, conn in ipairs(activeConnections) do
        pcall(function() conn:Disconnect() end)
    end
    activeConnections = {}

    -- Restore the game's own ChangeBallColor if we patched it.
    if ballColorController and ballColorOriginal then
        pcall(function() ballColorController.Server.ChangeBallColor = ballColorOriginal end)
    end
    ballColorController, ballColorOriginal = nil, nil
    if swordController and blockSuccessOriginal then
        pcall(function() swordController.Server.BlockSuccess = blockSuccessOriginal end)
    end
    swordController, blockSuccessOriginal = nil, nil
    -- Undo the client game fixes (newest first).
    for i = #gameFixes, 1, -1 do
        local f = gameFixes[i]
        pcall(function() f[1][f[2]] = f[3] end)
    end
    gameFixes = {}
    Clash.server = false

    -- Remove every Instance we spawned: detection sphere, player detectors, labels.
    if visualSphere then pcall(function() visualSphere:Destroy() end) visualSphere = nil end
    pcall(clearPlayerDetectorSpheres)
    for _, cache in pairs(billboardCache) do
        if cache and cache.Billboard then pcall(function() cache.Billboard:Destroy() end) end
    end
    billboardCache = {}

    -- Drop the ball cache and the highlight watchers.
    for ball in pairs(ballsCache) do ballsCache[ball] = nil end
    for _, conn in ipairs(highlightConns) do pcall(function() conn:Disconnect() end) end
    highlightConns = {}

    -- Close the UI window.
    pcall(function() Window:Destroy() end)

    -- Release the global handle so a fresh load starts clean.
    if getgenv then
        local okEnv, genv = pcall(getgenv)
        if okEnv and type(genv) == "table" then
            genv.AnimeBallLoaded = nil
            genv.AnimeBallUnload = nil
            genv.AnimeBallHubLoaded = nil
            genv.AnimeBallHubUnload = nil
        end
    end
end

-- Expose the unloader globally so it also works from the console
-- (getgenv().AnimeBallHubUnload()) and so the re-exec guard at the top can find it.
if getgenv then
    local okEnv, genv = pcall(getgenv)
    if okEnv and type(genv) == "table" then
        local unload = function() if unloadScript then unloadScript() end end
        genv.AnimeBallHubLoaded = true
        genv.AnimeBallHubUnload = unload
        -- Legacy names kept so older loaders / console habits still work.
        genv.AnimeBallLoaded = true
        genv.AnimeBallUnload = unload
    end
end

uiReady = true
notify("Anime Ball Hub Loaded!", "Auto Parry + Auto Spam ready. RightCtrl toggles the menu.", 5)
