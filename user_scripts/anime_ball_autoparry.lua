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
    -- Participation gate. The game's clash state is MATCH-WIDE: ClashController
    -- reads MatchService.IsClashing and applies the lighting/effects (and the
    -- ClashEffect attributes, and StartClash) for everyone in the arena. So
    -- "a clash is happening" is NOT "I'm in the clash". Without this gate a
    -- bystander within parry range fired a block every frame at other people's
    -- clash (180 blocks in 3s in the sandbox) - burning the 1s cooldown and the
    -- game's 120 req/s remote budget right before the ball came for them.
    -- I'm a participant if a ball targeted me within PART_WINDOW seconds (in a
    -- clash the target flips to each clasher every exchange) or the ball is
    -- within NEAR studs of me (the exchange is happening on top of me).
    meAt = -math.huge,
    PART_WINDOW = 1.5,
    NEAR = 15,
    -- Shield-cover hold (real miss report #4). Our last ACCEPTED shield's window
    -- on the server's clock (set from each block's reply), whether it already
    -- covers the ball now aimed at me (covered, worked out each frame), and how
    -- far the ball we SEE trails the real one beyond half a ping (VIEW_LAG,
    -- Roblox's interpolation - the report showed ~0.13-0.14s).
    shieldFrom = 0,
    shieldTo = 0,
    acceptedSent = -math.huge,   -- when the block that raised it was SENT
    covered = false,
    farRally = false,            -- no game clash and nobody within PARTNER_NEAR studs
    lowBall = nil, lowAt = -math.huge,   -- last time the closest ball was slow (launch window)
    parryAt = { -math.huge, -math.huge, -math.huge },   -- my last three parries (when I saw them), newest first
    chainFor = -math.huge,       -- the parry the rally chain last fired for
    CHAIN_GAP = 0.5,             -- rally chain: both recent parry gaps must be this short
    FAST_GAP = 0.35,             -- parry gaps this short = a clash, whatever the distance
    CLOSE_RET = 18,              -- an opponent this close returns my parry instantly
    fastRally = false,
    VIEW_LAG = 0.12,
}

-- One parry by me, seen now (from the game's BlockSuccess, or the ball's
-- target switching from me to someone else). Both arrive half a ping after the
-- parry, so two sightings within 0.15s are the same parry.
-- Has my last accepted shield already parried, and is a NEW pass on its way
-- (a ball's target switched to me after that parry)? Then that shield may be
-- USED UP: real miss report #8 - a shield parried a ball and the return 0.45s
-- later, well inside its 0.6s, found no shield. Only for a new pass: the ball
-- just parried still LOOKS like it is coming (the view is half a ping +
-- VIEW_LAG old), and a block fired at it lands on a ball flying away.
-- Whether a parried shield really is gone differs between real reports (#8:
-- gone; #4: blocks refused for its whole 0.6s), so the server's own answer
-- decides: the first block sent while such a shield would still be up is a
-- PROBE. Accepted -> it was used up ("open"); refused -> it is still up
-- ("held") and that shield's lock and cover hold stay on. Learned once. While
-- the probe's answer is out, everything else acts as if it is still up (so
-- the normal block still goes as it ends), with one extra block allowed in
-- flight so the probe can't take that block's slot.
Clash.toMeLast = -math.huge
Clash.postParry = nil      -- nil = not known yet, "open", "held"
Clash.probeSent = nil
Clash.lastProbe = false    -- was the last block sent a probe?
Clash.parriedSince = function()   -- my last accepted shield has parried
    return Clash.parryAt[1] - (Clash.shieldFrom - Clash.acceptedSent) >= Clash.shieldFrom - 0.02
end
Clash.returnSend = false           -- set while Return Pre-Shield is sending (see there)
Clash.spentRaw = function()
    -- ...and a NEW pass is on its way - except for Return Pre-Shield (and its
    -- rally chain), whose blocks are timed for the NEXT return, never aimed at
    -- the ball just parried: waiting for that ball to visibly come back cost
    -- 0.17s and the block landed late in the sandbox (rally chain, 156 ms;
    -- pre-shield, 200 ms).
    return Clash.parriedSince() and (Clash.returnSend or Clash.toMeLast > Clash.parryAt[1])
end
-- May my shield be used up? (Callers deciding whether to TRY a block.)
Clash.shieldSpent = function()
    return Clash.postParry ~= "held" and Clash.spentRaw()
end
Clash.noteParry = function(t)
    local pa = Clash.parryAt
    if t - pa[1] > 0.15 then
        pa[3], pa[2], pa[1] = pa[2], pa[1], t
    end
end

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

-- The game's own SERVER-SIDE auto parry (AutoParryService, added in the
-- 2026-10-31 update). The client asks with AutoParryService.SetEnabled:Invoke(bool)
-- and the server answers with the new state, or nil if your account isn't
-- allowed. A server-side parry has no ping delay at all. Filled in below.
local GameAP = { want = false, status = "off", setEnabled = nil }

-- Auto-Dash Away: when an opponent rushes into you (or a ball is about to hit
-- point-blank while your block is still on cooldown) it fires the game's own
-- dash, angled away from the threat and toward the side you're already moving.
--   range   = studs: how close a rushing player / ball must be
--   closing = studs/s: how fast they must be coming at you to count as a rush
--   angle   = degrees off "straight away" (0 = straight back, 90 = sideways)
local AutoDash = { enabled = false, range = 14, closing = 35, angle = 45,
                   lastFire = 0, count = 0, rejectedAt = 0, lastReason = "-" }

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
GameAP.want         = setting("GameAutoParry", false)
Clash.HL            = { on = setting("BallHitLogger", true) }   -- Ball Hit Logger (see BALL HIT LOGGER)
AutoDash.enabled    = setting("AutoDash", false)
Clash.retOn         = setting("ReturnPreShield", true)
Clash.rate          = math.clamp(setting("ClashSpeed", 85), 30, 110)
AutoDash.range      = math.clamp(setting("AutoDashRange", AutoDash.range), 6, 30)
AutoDash.closing    = math.clamp(setting("AutoDashClosing", AutoDash.closing), 10, 120)
AutoDash.angle      = math.clamp(setting("AutoDashAngle", AutoDash.angle), 0, 90)

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
-- "Crimson Glass": a see-through crimson window (Acrylic blur + transparent
-- background) with tinted glass panels, a crimson glow shadow and bright
-- crimson accents. Every glass surface is a translucent red tint, not grey.
-- Window see-through amount (0 = solid, 0.9 = almost clear); default 0.4.
local glassTransparency = math.clamp(setting("GlassTransparency", 0.4), 0, 0.9)
do -- scoped so the helpers don't count toward the main chunk's 200-local cap
local function hex(h) return Color3.fromHex(h) end
pcall(function()
    WindUI:AddTheme({
        Name = "CrimsonGlass",
        -- core palette
        Accent = hex("#DC143C"),
        Primary = hex("#FF2E4D"),
        Background = hex("#3A0A14"),
        Dialog = hex("#2A0710"),
        Outline = hex("#FF6B81"),
        Text = hex("#FFF0F3"),
        Placeholder = hex("#E8A0AE"),
        Button = hex("#8B1A2B"),
        Icon = hex("#FF8FA3"),
        Hover = hex("#FF4D6A"),
        White = hex("#FFFFFF"),
        Black = hex("#000000"),
        -- controls
        Toggle = hex("#DC143C"),
        ToggleBar = hex("#FFFFFF"),
        Slider = hex("#FF2E4D"),
        SliderThumb = hex("#FFFFFF"),
        SliderIcon = hex("#FF8FA3"),
        Checkbox = hex("#DC143C"),
        ProgressBar = hex("#FF2E4D"),
        -- glass surfaces (translucent crimson tints)
        ElementBackground = hex("#FF3355"),
        ElementBackgroundTransparency = 0.88,
        PanelBackground = hex("#FF5A73"),
        PanelBackgroundTransparency = 0.92,
        LabelBackground = hex("#FF4D6A"),
        LabelBackgroundTransparency = 0.9,
        SectionBox = hex("#FF4D6A"),
        SectionBoxTransparency = 0.93,
        SectionBoxBorder = hex("#FF8FA3"),
        SectionBoxBorderTransparency = 0.6,
        SectionBoxBackground = hex("#FF3355"),
        SectionBoxBackgroundTransparency = 0.95,
        -- tabs
        TabBackground = hex("#FF4D6A"),
        TabBackgroundHover = hex("#FF4D6A"),
        TabBackgroundHoverTransparency = 0.88,
        TabBackgroundActive = hex("#DC143C"),
        TabBackgroundActiveTransparency = 0.6,
        TabBorder = hex("#FF8FA3"),
        TabBorderTransparencyActive = 0.35,
        -- window chrome
        WindowShadow = hex("#DC143C"),   -- crimson glow instead of a black shadow
        WindowSearchBarBackground = hex("#2A0710"),
        SearchBarBorder = hex("#FF8FA3"),
        SearchBarBorderTransparency = 0.6,
        DropdownBackground = hex("#2A0710"),
        DropdownTabBorder = hex("#FF8FA3"),
        Tooltip = hex("#5A0F1E"),
        -- notifications
        Notification = hex("#3A0A14"),
        Notification2 = hex("#DC143C"),
        Notification2Transparency = 0.85,
        NotificationBorder = hex("#FF6B81"),
        NotificationBorderTransparency = 0.5,
    })
    WindUI:SetTheme("CrimsonGlass")
end)
end

local LOGO_ICON = "https://raw.githubusercontent.com/robloxscripter6245366542/roblox-lua-obscator/main/assets/anime_ball_logo_rounded.png"

local windowConfig = {
    Title = "Anime Ball Hub",
    Icon = LOGO_ICON,
    Author = "Auto Parry • Auto Spam",
    Folder = "AnimeBallHub",
    Size = UDim2.fromOffset(580, 460),
    Theme = "CrimsonGlass",
    Transparent = true,   -- see-through glass background
    Acrylic = true,       -- blur what's behind the window (frosted glass)
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
pcall(function() WindUI:SetTheme("CrimsonGlass") end)  -- re-apply in case the window reset it
pcall(function() Window:SetBackgroundTransparency(glassTransparency) end)
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
    Kick    = Window:Tab({ Title = "Kick",       Icon = "log-out" }),
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

toggle(Tabs.Main, "GameAutoParry", "Game's Server Auto Parry (beta)",
    "Ask the game's own server-side auto parry (added in the latest update) to parry for you - zero ping delay. "
        .. "The server decides if your account may use it; status shows below. Script parry keeps running too.",
    GameAP.want, function(v)
    GameAP.want = v
    if GameAP.setEnabled then GameAP.setEnabled(v) end
end)
HUD.GameAP = paragraph(Tabs.Main, "Server Auto Parry", "Status: off")

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

toggle(Tabs.Parry, "ReturnPreShield", "Return Pre-Shield",
    "When an opponent near you is about to hit the ball, block early if their return would reach you faster than your ping - "
        .. "so fast close returns are already shielded", Clash.retOn, function(v)
    Clash.retOn = v
end)

section(Tabs.Parry, "Auto-Dash Away")
toggle(Tabs.Parry, "AutoDash", "Auto-Dash Away",
    "Dash away at an angle when a player rushes into you, or a ball is about to hit point-blank while your block is on cooldown. "
        .. "Uses the game's own dash (1.1s cooldown). Holding W/A/S/D overrides the direction.", AutoDash.enabled, function(v)
    AutoDash.enabled = v
end)
slider(Tabs.Parry, "AutoDashRange", "Dash Trigger Distance (studs)",
    "How close a rushing player or ball must be", 6, 30, 1, AutoDash.range, function(v)
    AutoDash.range = v
end)
slider(Tabs.Parry, "AutoDashClosing", "Rush Speed (studs/s)",
    "How fast a player must be coming at you to count as a rush (dash = ~90)", 10, 120, 5, AutoDash.closing, function(v)
    AutoDash.closing = v
end)
slider(Tabs.Parry, "AutoDashAngle", "Dash Angle (degrees)",
    "0 = straight away from them, 45 = diagonal, 90 = sideways. Side follows the way you're moving", 0, 90, 5, AutoDash.angle, function(v)
    AutoDash.angle = v
end)
HUD.AutoDash = paragraph(Tabs.Parry, "Auto-Dash Status", "Off")

-- ============================================
-- AUTO SPAM TAB
-- ============================================
section(Tabs.Spam, "Auto Spam Status")
slider(Tabs.Spam, "ClashSpeed", "Clash Speed (blocks/s)",
    "How fast it blocks during a clash. The game drops requests above 120/s total and can lock the remote "
        .. "for ~15s, so above ~100 risks LOSING the clash. 85 = fastest safe default", 30, 110, 5, Clash.rate, function(v)
    Clash.rate = v
end)
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
section(Tabs.Visuals, "Menu Glass")
slider(Tabs.Visuals, "GlassTransparency", "Glass Transparency",
    "How see-through the crimson glass window is (0 = solid)", 0, 0.9, 0.05, glassTransparency, function(v)
    glassTransparency = v
    pcall(function() Window:SetBackgroundTransparency(v) end)
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

-- ============================================
-- MISS RECORDER
-- ============================================
-- Keeps the last ~2.5s of what the parry saw and decided each frame, plus every
-- block sent and the server's answer. When you get hit by a ball that was aimed
-- at you, it freezes that history into a text report you can copy and send, so
-- a real in-game miss can be diagnosed from facts instead of guesses.
Clash.log, Clash.logN, Clash.events, Clash.misses, Clash.lastReport = {}, 0, {}, 0, nil
Clash.rec = function(t, d, v, cl, tti, arr, lead, within, cover, inWin, panic, imminent, always, targeted, held)
    Clash.logN = Clash.logN + 1
    Clash.log[(Clash.logN - 1) % 150 + 1] = { t, d, v, cl, tti, arr, lead, within, cover, inWin, panic, imminent, always, targeted, held }
end
Clash.event = function(t, what)
    local e = Clash.events
    e[#e + 1] = { t, what }
    if #e > 400 then table.remove(e, 1) end
end
Clash.buildReport = function(now, cause)
    local function f(x) if x == nil or x ~= x or x >= 1e6 then return "inf" end return string.format("%.2f", x) end
    local function b(x) return x and "1" or "0" end
    local lines = {
        "Anime Ball Hub miss report #" .. Clash.misses .. " (" .. cause .. ")",
        string.format("ping %.0f ms (smoothed %.0f) | frameLag %.0f ms | clashSpeed %d | preShield %s | pingComp %s | antiCurve %s",
            currentPing, smoothedPing, frameLag * 1000, Clash.rate or 0, tostring(Clash.retOn), tostring(pingCompEnabled), tostring(antiCurveEnabled)),
        "time   dist  speed close  tti   arr   lead  W C S P I A T H  (W=withinRange C=coverable S=inShieldWindow P=panic I=imminent A=alwaysFire T=targeted H=held: my shield already covers it)",
    }
    local rows = {}
    for i = 1, math.min(Clash.logN, 150) do
        local r = Clash.log[i]
        if r and now - r[1] <= 1.5 then rows[#rows + 1] = r end
    end
    table.sort(rows, function(a, c) return a[1] < c[1] end)
    for _, r in ipairs(rows) do
        lines[#lines + 1] = string.format("%+.2f %5s %5s %5s %5s %5s %5s %s %s %s %s %s %s %s %s",
            r[1] - now, f(r[2]), f(r[3]), f(r[4]), f(r[5]), f(r[6]), f(r[7]),
            b(r[8]), b(r[9]), b(r[10]), b(r[11]), b(r[12]), b(r[13]), b(r[14]), b(r[15]))
    end
    lines[#lines + 1] = "-- blocks --"
    for _, e in ipairs(Clash.events) do
        if now - e[1] <= 2.0 then lines[#lines + 1] = string.format("%+.2f %s", e[1] - now, e[2]) end
    end
    return table.concat(lines, "\n")
end
Clash.onMiss = function(cause)
    if destroyed or (tick() - Clash.meAt) > 2.0 then return end   -- only balls that were aimed at me
    Clash.misses = Clash.misses + 1
    Clash.lastReport = Clash.buildReport(tick(), cause)
    setDesc(HUD.MissLog, string.format("Misses recorded: %d\nLast: %s - press Copy and paste it to the dev", Clash.misses, cause))
    pcall(function()
        if type(appendfile) == "function" and type(isfile) == "function" and isfile(CONFIG_FOLDER .. "/miss_reports.txt") then
            appendfile(CONFIG_FOLDER .. "/miss_reports.txt", "\n\n" .. Clash.lastReport)
        elseif type(writefile) == "function" then
            if type(isfolder) == "function" and type(makefolder) == "function" and not isfolder(CONFIG_FOLDER) then makefolder(CONFIG_FOLDER) end
            writefile(CONFIG_FOLDER .. "/miss_reports.txt", Clash.lastReport)
        end
    end)
    notify("Miss recorded", "Statistics tab > Copy Last Miss Report, then paste it to the dev", 5)
end
section(Tabs.Stats, "Miss Recorder")
HUD.MissLog = paragraph(Tabs.Stats, "Miss Recorder", "No misses recorded yet. When a ball aimed at you hits you, a report is saved here.")
Tabs.Stats:Button({
    Title = "Copy Last Miss Report",
    Desc = "Copies what the parry saw in the 1.5s before your last miss",
    Callback = function()
        if not Clash.lastReport then notify("Miss Recorder", "No miss recorded yet") return end
        local clip = setclipboard or toclipboard
        local ok = clip ~= nil and pcall(clip, Clash.lastReport)
        notify(ok and "Copied" or "Copy failed", ok and "Paste it to the dev" or ("Saved in " .. CONFIG_FOLDER .. "/miss_reports.txt"), 4)
    end,
})

-- Ball Hit Logger: how the ball reacts to every hit (speed before/after, how
-- much each hit adds, time between hits, in-flight speed-up...). The recorder
-- itself is under BALL HIT LOGGER further down; these callbacks look it up
-- when clicked.
section(Tabs.Stats, "Ball Hit Logger")
toggle(Tabs.Stats, "BallHitLogger", "Ball Hit Logger",
    "Record how the ball's speed changes on every hit (any player's hit, not just yours)", Clash.HL.on, function(v)
    Clash.HL.on = v
end)
HUD.HitLog = paragraph(Tabs.Stats, "Hit Log", "No hits logged yet. Play a round, then press Copy Ball Hit Log.")
Tabs.Stats:Button({
    Title = "Copy Ball Hit Log",
    Desc = "Copies every logged hit: speed in/out, % and studs/s added per hit, gaps, flight speed-up",
    Callback = function()
        local okB, text = pcall(function() return Clash.HL.build() end)
        if not okB or type(text) ~= "string" then
            notify("Ball Hit Logger", "Couldn't build the log: " .. tostring(text), 5)
            return
        end
        pcall(function()
            if type(writefile) == "function" then
                if type(isfolder) == "function" and type(makefolder) == "function" and not isfolder(CONFIG_FOLDER) then makefolder(CONFIG_FOLDER) end
                writefile(CONFIG_FOLDER .. "/ball_hits.txt", text)
            end
        end)
        local clip = setclipboard or toclipboard or (Clipboard and Clipboard.set)
        local ok = clip ~= nil and pcall(clip, text)
        notify(ok and "Copied" or "Copy failed",
            ok and (#Clash.HL.hits .. " hits copied - paste it to the dev") or ("Saved in " .. CONFIG_FOLDER .. "/ball_hits.txt"), 4)
    end,
})
Tabs.Stats:Button({
    Title = "Clear Ball Hit Log",
    Desc = "Start a fresh log",
    Callback = function()
        if Clash.HL.clear then Clash.HL.clear() end
        setDesc(HUD.HitLog, "Log cleared. Play a round, then press Copy Ball Hit Log.")
        notify("Ball Hit Logger", "Log cleared", 3)
    end,
})

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
-- KICK TAB (kick yourself from the game)
-- ============================================
-- Player:Kick() on your OWN player is allowed from the client: it disconnects
-- you with your message. Nothing here can affect anyone else. Kept inside a
-- do-block so it adds no locals to the main chunk (Luau's 200-local cap).
do
    local kickMessage = "You kicked yourself (Anime Ball Hub)"
    section(Tabs.Kick, "Kick Yourself")
    paragraph(Tabs.Kick, "What this does",
        "Disconnects YOU from this server with your message. It only affects your own account.")
    pcall(function()
        Tabs.Kick:Input({
            Title = "Kick Message",
            Desc = "Shown on the disconnect screen",
            Value = kickMessage,
            Placeholder = "Kick message",
            Callback = function(text)
                if type(text) == "string" and text ~= "" then kickMessage = text end
            end,
        })
    end)
    Tabs.Kick:Button({
        Title = "Kick Me Now",
        Desc = "Leave the game immediately with the message above",
        Callback = function()
            pcall(function() LocalPlayer:Kick(kickMessage) end)
        end,
    })
    Tabs.Kick:Button({
        Title = "Kick Me In 3 Seconds",
        Desc = "Same, with a 3 second countdown",
        Callback = function()
            notify("Kicking", "Leaving in 3 seconds...", 3)
            task.delay(3, function()
                if not destroyed then pcall(function() LocalPlayer:Kick(kickMessage) end) end
            end)
        end,
    })
    section(Tabs.Kick, "Rejoin")
    Tabs.Kick:Button({
        Title = "Rejoin This Server",
        Desc = "Leave and come straight back to the same server",
        Callback = function()
            local TeleportService = game:GetService("TeleportService")
            local ok = pcall(function()
                TeleportService:TeleportToPlaceInstance(game.PlaceId, game.JobId, LocalPlayer)
            end)
            if not ok then pcall(function() TeleportService:Teleport(game.PlaceId, LocalPlayer) end) end
        end,
    })
end

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
    -- At least half a 60 fps frame apart: two Heartbeat handlers (the parry
    -- loop and Return Pre-Shield) read a ball in the SAME frame a fraction of a
    -- millisecond apart, and re-sampling between them read an unmoved position
    -- over that sliver as speed 0 for the second reader.
    if now > s.time + 0.008 then
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
    -- The ball's velocity replicates ~30 times a second, so on every other
    -- 60 fps frame it hasn't changed at all and the NEXT frame carries two
    -- frames' turn at once - read over one frame, a real 9 rad/s homing turn
    -- looks like 20+ rad/s and was thrown out as a "bounce" below (real miss
    -- report #6: the turn rate never registered). So an unchanged reading
    -- leaves the state alone (for up to 0.05s) and the next real change is
    -- measured over the time it actually took.
    if prev and (vel - prev.vel).Magnitude < 1e-6 and now - prev.time < 0.05 then
        return prev.accel, prev.omega or 0, prev.axis
    end
    -- A LAUNCH (a held or slow ball suddenly fast - an ability shot, a serve)
    -- is not a curve: read as delta-v it is a huge one-frame acceleration and
    -- turn that the smoothing then carried for several frames, so the arc said
    -- the ball would miss (arr=inf) the whole way in (report #6). Start fresh.
    if prev and speed > 50 and prev.vel.Magnitude < 0.25 * speed then
        ballMotionCache[ball] = {vel = vel, accel = Vector3.new(), time = now, dir = dir, omega = 0, axis = prev.axis}
        return Vector3.new(), 0, prev.axis
    end
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
local function recordBlockResult(ok, result, sentAt)
    Clash.event(tick(), "RESULT " .. (not ok and "error" or (result == nil and "rejected" or (result and "parried" or "shield-up"))))
    -- Remember where our accepted shield sits on the server's clock: it went up
    -- about half the round trip after we sent it and lasts BLOCK_DURATION.
    -- Clash.covered (main loop) uses this window - see "Shield-cover hold".
    -- An INSTANT parry (true: the ball was already in range as the block
    -- landed) uses the block up on that ball - it leaves NO shield behind (real
    -- miss report #7: the return 0.43s later found none). Recording it as a
    -- 0.6s shield made the cover hold sit on its hands for that return. It is
    -- a parry, though (and a parry resets the cooldown).
    if sentAt and sentAt == Clash.probeSent then
        Clash.probeSent = nil
        if ok then
            Clash.postParry = result == nil and "held" or "open"
            Clash.event(tick(), result == nil and "RULE: a parried shield stays up" or "RULE: a parried shield is used up")
        end
    end
    if ok and result == true then
        Clash.noteParry(tick())
    elseif ok and result ~= nil and sentAt then
        Clash.acceptedSent = sentAt
        Clash.shieldFrom = sentAt + (tick() - sentAt) / 2
        Clash.shieldTo = Clash.shieldFrom + BLOCK_DURATION
    end
    blockSent = blockSent + 1
    if not ok then
        lastBlockResult = "error"
    elseif result == nil then
        blockRejected = blockRejected + 1
        lastBlockResult = "rejected"
        AutoDash.rejectedAt = tick()
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
local function fireBlockRemote(clash, why)
    local nowT = tick()
    -- Shield lock (real miss reports #4 and #5), in a long-range rally only
    -- (never in a game clash: blocks are accepted back-to-back there). A block
    -- sent within BLOCK_DURATION of the last ACCEPTED one lands while that
    -- shield is still up (both travel the same path, at any ping), and it can
    -- only hurt:
    --  * before that shield has parried, its cooldown is still running, so the
    --    block is refused and its reply ties up the send slot for a round trip
    --    (a lone ball allows one in flight) - or, if the parry happens while it
    --    is in flight, it is ACCEPTED on a ball now flying away and starts a
    --    fresh 1s cooldown (report #5: the return a second later found every
    --    block refused);
    --  * after a parry the server may still refuse it while my shield is up
    --    (report #4: every block for 0.6s after one went up was rejected).
    -- The shield that is up covers that time anyway; the next block goes as
    -- it ends (sending 0.6s + 10 ms after the accepted one lands just then).
    -- Once that shield has PARRIED, though, it may be used up (report #8: the
    -- return 0.45s later found none and this lock held the block until too
    -- late), so the lock lifts: a block sent then is either needed, or simply
    -- refused while the shield is still up.
    local probe = false
    if Clash.farRally and nowT - Clash.acceptedSent < BLOCK_DURATION + 0.01 then
        if Clash.postParry == "open" and Clash.spentRaw() then
            -- known: a parried shield is used up - send
        elseif Clash.postParry == nil and Clash.probeSent == nil and Clash.spentRaw() then
            probe = true
        else
            return false
        end
    end
    if clash then
        -- Clash: a token bucket at Clash.rate blocks/s instead of "one per
        -- frame". On a 60 fps client the old per-frame gate capped a clash at
        -- ~60/s; the bucket lets up to 2 go in one frame so the clash reaches
        -- the chosen rate (default 85/s) - still under the game's 120/s budget
        -- and far under its 20-per-0.1s burst limit (bucket holds at most 2).
        Clash.tokens = math.min(2, (Clash.tokens or 0) + (nowT - (Clash.tokenAt or nowT)) * Clash.rate)
        Clash.tokenAt = nowT
        if Clash.tokens < 1 then return false end
    elseif nowT - lastBlockSendTime < BLOCK_SEND_INTERVAL then
        return false
    end
    -- In-flight cap. Each Block:Invoke takes a full round-trip to return, so a
    -- fixed cap of 2 limited a clash to ~2/RTT blocks reaching the server (about
    -- 15/s at 130 ms, 10/s at 200 ms) whatever the send interval - and if the
    -- server uses up the shield on each parry, a point-blank clash drops returns
    -- (pointblank_hold: 36/60 held at 200 ms). Scale it with ping so ~70/s can
    -- arrive; CLASH_SEND_INTERVAL still caps the actual send rate under the
    -- game's 120/s budget, so this never floods.
    -- Not in a long-range rally (Clash.farRally: no game clash, nobody within
    -- PARTNER_NEAR): there a burst of clash-rate blocks in flight does nothing
    -- for the ball - the opponent's return takes most of a second - but one of
    -- them lands just after my shield parries and starts a fresh cooldown on a
    -- ball flying away (real miss report #5, and #4 at 180 ms in the sandbox).
    -- One at a time, the reply says my shield is up before the next can go.
    local cap = 1
    if clash and not Clash.farRally then
        cap = math.clamp(math.ceil((math.max(smoothedPing, currentPing) / 1000) * Clash.rate) + 3, CLASH_INFLIGHT, 18)
    end
    if Clash.probeSent then cap = cap + 1 end   -- the probe must not take the real block's slot
    if blocksInFlight >= cap then
        -- Lag-spike trickle (real miss report #3, 173 ms): during a point-blank
        -- clash the server's replies stalled for ~0.2s, the in-flight cap filled
        -- and sending STOPPED for 0.16s - the ball got through that gap. Raising
        -- the cap outright is unsafe: if it's the UPLOAD that stalled, every
        -- queued block lands at once when it clears and the game drops anything
        -- over 20 per 0.1s (and can lock the remote ~15s). So in a clash, past
        -- the cap, keep trickling ~20 blocks/s (every 3rd frame at 60 fps), at most 10 extra: the
        -- shield stays fresh if only replies are late, and a burst on recovery
        -- stays under the limit.
        if not clash or Clash.farRally or blocksInFlight >= cap + 10 or nowT - lastBlockSendTime < 0.04 then
            return false
        end
    end
    if clash then Clash.tokens = Clash.tokens - 1 end
    if probe then Clash.probeSent = nowT end
    Clash.lastProbe = probe
    Clash.event(nowT, (clash and "SEND clash" or "SEND") .. (why and (" (" .. why .. ")") or ""))
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
                if ok then recordBlockResult(true, result, nowT); return end
                swordServiceProxy = nil -- proxy went stale; re-fetch next time
            end
            -- Fallback: generic framework RemoteFunction router.
            local ok, result = pcall(function()
                return ReplicatedStorage.Framework.RemoteFunction:InvokeServer("SwordService", "Block", {lookY})
            end)
            recordBlockResult(ok, result, nowT)
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
                -- A ball with NO target only counts as a threat while it is near
                -- or could reach me soon: a stray ball ~1400 studs away with no
                -- target was preferred over the rally ball aimed at my opponent,
                -- so the parry loop watched IT, not the ball about to come back
                -- at me (real miss report #9).
                local strayFar = false
                if target == nil and not invisible and distance > 150 then
                    local v = getBallVelocityVector(ball)
                    local cl = v:Dot(humanoidRootPart.Position - ballPos) / distance
                    strayFar = cl <= 0 or distance / cl > 1.5
                end
                if (target == myName or (target == nil and not strayFar) or invisible or serverSaysMe) then
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
    if Clash.holdAway then return end   -- ball heading away in a long rally (see Clash.holdAway)
    if Clash.covered then return end    -- our shield already covers it (see Shield-cover hold)
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
            pcall(function() Clash.event(tick(), "PARRY CONFIRMED by server") end)
            Clash.noteParry(tick())
            blockParried = blockParried + 1
            blockLanded = blockLanded + 1
            lastBlockResult = "parried"
        end
        return orig(...)
    end
end)

-- ============================================
-- BALL HIT LOGGER
-- ============================================
-- Records how every ball reacts to every hit, whoever hits it, so the game's
-- speed rules can be read off real play: the speed going in and coming out of
-- each hit, how much each hit adds (% and studs/s), the time between hits,
-- how much the ball speeds up (or slows) in flight between hits, how far it
-- turns, and how far apart the two players were. Copy Ball Hit Log puts it
-- all on the clipboard (and in AnimeBallHub/ball_hits.txt); also
-- getgenv().AnimeBallHubHitLog() from the console. Read-only: it never
-- touches the parry.
--
-- A hit = the ball's Target switching to another player. The Target flips
-- about half a ping after the server's hit, but the ball's velocity on screen
-- can show it later, so each hit is pinned to the frame the ball visibly
-- TURNS (>= 40 deg from one frame to the next) or jumps in speed (>= 8%), and
-- the speeds are read on the frames either side of that.
do
    local HL = Clash.HL
    HL.MAX, HL.RALLY_GAP, HL.KEEP = 400, 6, 4
    HL.clear = function()
        HL.balls = setmetatable({}, { __mode = "k" })   -- [ball] = its samples and hit state
        HL.hits, HL.pending, HL.fx, HL.delays = {}, {}, {}, {}
        HL.rallies, HL.fxHit, HL.fxRef, HL.fxSeen = 0, 0, 0, false
        HL.since = tick()
    end
    HL.clear()

    local function median(list)
        local n = #list
        if n == 0 then return nil end
        table.sort(list)
        if n % 2 == 1 then return list[(n + 1) / 2] end
        return (list[n / 2] + list[n / 2 + 1]) / 2
    end
    HL.median = median
    local function copy(t)
        local c = {}
        for i, v in ipairs(t) do c[i] = v end
        return c
    end
    local function speedsIn(B, t0, t1)
        local out = {}
        for _, x in ipairs(B.s) do
            if x[1] >= t0 and x[1] < t1 then out[#out + 1] = x[2] end
        end
        return out
    end
    -- the last sample at or before t (or the first one, if all are later)
    local function sampleAt(B, t)
        local best
        for _, x in ipairs(B.s) do
            if x[1] <= t then best = x else return best or x end
        end
        return best
    end
    local function angleOf(a, b)
        if not a or not b or a.Magnitude < 1 or b.Magnitude < 1 then return nil end
        return math.deg(math.acos(math.clamp(a.Unit:Dot(b.Unit), -1, 1)))
    end
    HL.fmt = function(v)
        local t = typeof(v)
        if t == "number" then return string.format("%.4g", v) end
        if t == "string" then return v end
        if t == "Instance" then return v.Name end
        if t == "Vector3" then return string.format("(%.1f,%.1f,%.1f)", v.X, v.Y, v.Z) end
        if t == "boolean" or t == "nil" then return tostring(v) end
        return t
    end
    -- the flip -> visible-turn delay, median of the recent hits
    HL.lag = function()
        return median(copy(HL.delays)) or 0.1
    end
    local function hrpOf(name)
        if type(name) ~= "string" then return nil end
        for _, pl in ipairs(Players:GetPlayers()) do
            if pl.Name == name then return getPlayerHRP(pl) end
        end
        return nil
    end

    -- A ball's flight between two hits (or since the last one): how long it
    -- flew, its speed at the start and end, top and lowest speed, how fast it
    -- sped up (studs/s per second), and its average speed from how far it
    -- actually moved.
    local function segment(B, t0, t1)
        if not B or t1 - t0 < 0.03 then return nil end
        local first, last, smax, smin, dist, prevPos
        for _, x in ipairs(B.s) do
            if x[1] >= t0 and x[1] <= t1 then
                first = first or x
                last = x
                smax = math.max(smax or 0, x[2])
                smin = math.min(smin or math.huge, x[2])
                if prevPos then dist = (dist or 0) + (x[4] - prevPos).Magnitude end
                prevPos = x[4]
            end
        end
        if not first or first == last then return nil end
        local dur = last[1] - first[1]
        return {
            dur = t1 - t0, s0 = first[2], s1 = last[2], smax = smax, smin = smin,
            acc = dur > 0.05 and (last[2] - first[2]) / dur or nil,
            moved = dist and dur > 0.05 and dist / dur or nil,
            partial = B.s[1] and B.s[1][1] > t0 or false,
        }
    end
    HL.segment = segment

    local function attrsOf(ball)
        local ok, attrs = pcall(function() return ball:GetAttributes() end)
        if not ok or type(attrs) ~= "table" then return nil end
        local keys = {}
        for k in pairs(attrs) do
            if k ~= "Target" then keys[#keys + 1] = tostring(k) end   -- Target is the from/to columns
        end
        table.sort(keys)
        local parts = {}
        for _, k in ipairs(keys) do parts[#parts + 1] = k .. "=" .. HL.fmt(attrs[k]) end
        return table.concat(parts, " ")
    end

    HL.newHit = function(ball, B, now, from, to)
        local prev = B.lastHit
        if not prev or now - prev.t > HL.RALLY_GAP then
            HL.rallies = HL.rallies + 1
            B.rally, B.n = HL.rallies, 0
            prev = nil
        end
        B.n = B.n + 1
        local h = {
            rally = B.rally, n = B.n, ball = B.name, t = now, from = from, to = to,
            serve = from == nil, ping = currentPing, B = B, prevHit = prev,
            gap = prev and now - prev.t or nil,
        }
        if prev then prev.nextT = now end
        local a, b = hrpOf(from), hrpOf(to)
        if a and b then h.pdist = (a.Position - b.Position).Magnitude end
        local seen = B.s[#B.s]
        if seen and a then h.bdist = (seen[4] - a.Position).Magnitude end
        local at = attrsOf(ball)
        if at and at ~= B.attrs then h.attrs, B.attrs = at, at end
        -- the game's own hit effect for this ball, if it arrived first
        for i = #HL.fx, 1, -1 do
            local e = HL.fx[i]
            if now - e.t > 0.5 then break end
            if e.kind == "HitEffect" and e.ball == ball and e.player == from and not e.used then
                h.fx, e.used = e.text, true
                break
            end
        end
        B.lastHit = h
        HL.hits[#HL.hits + 1] = h
        if #HL.hits > HL.MAX then table.remove(HL.hits, 1) end
        HL.pending[#HL.pending + 1] = h
    end

    -- Pin a hit to the frame the ball visibly reacted, then read its speeds.
    local TRACE = { -0.1, -0.05, 0, 0.05, 0.1, 0.2, 0.3 }
    HL.measure = function(h, now)
        local B = h.B
        local ph = h.prevHit
        if not h.turn then
            -- In a fast rally the ball on screen can still be showing the
            -- PREVIOUS hit when the Target flips again, so pin that one first
            -- and only look after its turn.
            if ph and not ph.turn then return false end
            local from = h.t - 0.02
            if ph then from = math.max(from, ph.turn + 0.03) end
            -- frame to frame: a hit turns the ball (or jumps its speed) in
            -- one frame, while homing only bends it a few degrees a frame
            local px
            for _, x in ipairs(B.s) do
                if x[1] > h.t + 0.7 or (h.nextT and x[1] > h.nextT + 0.3) then break end
                if x[1] > from and px then
                    local ang, ps = angleOf(px[3], x[3]), px[2]
                    if (ang and ang >= 40)
                        or (ps < 5 and x[2] >= 20)
                        or (ps >= 5 and math.abs(x[2] - ps) >= 0.08 * ps) then
                        h.turn, h.delay = x[1], x[1] - h.t
                        break
                    end
                end
                px = x
            end
            if not h.turn then
                if now < h.t + 0.7 then return false end
                h.turn, h.guess = h.t + HL.lag(), true   -- never visibly reacted: assume the usual delay
            end
        end
        if now < h.turn + 0.32 then return false end
        local before0 = h.turn - 0.12
        if ph and ph.turn then before0 = math.max(before0, ph.turn + 0.03) end
        local after1 = h.turn + 0.12
        if h.nextT then after1 = math.min(after1, h.turn + math.max(0.03, (h.nextT - h.t) * 0.8)) end
        -- the frame just before the turn and the turn frame itself (a ball
        -- also speeds up in flight, so reading further out would blur that
        -- into the hit's own jump)
        local bl, al = speedsIn(B, before0, h.turn), speedsIn(B, h.turn, after1)
        h.sIn, h.sOut = bl[#bl], al[1]
        if h.sIn and h.sOut and h.sIn >= 1 then
            h.pct, h.add = h.sOut / h.sIn - 1, h.sOut - h.sIn
        end
        local vb, va = sampleAt(B, h.turn - 0.02), sampleAt(B, h.turn + 0.05)
        h.ang = vb and va and angleOf(vb[3], va[3])
        local tr = {}
        for i, off in ipairs(TRACE) do
            local x = sampleAt(B, h.turn + off)
            tr[i] = x and string.format("%.0f", x[2]) or "-"
            if off == -0.05 then tr[i] = tr[i] .. " |" end
        end
        h.trace = table.concat(tr, " ")
        -- the flight the PREVIOUS hit started ends at this one
        if ph and ph.turn and not ph.seg then
            ph.seg = segment(B, ph.turn + 0.05, h.turn - 0.02)
            ph.B = nil
        end
        h.prevHit = nil
        if not h.guess then
            HL.delays[#HL.delays + 1] = h.delay
            if #HL.delays > 60 then table.remove(HL.delays, 1) end
        end
        return true
    end

    HL.step = function()
        local now = tick()
        for ball in pairs(ballsCache) do
            local part = ball.Parent and getBallPart(ball)
            if part then
                local B = HL.balls[ball]
                if not B then
                    B = { s = {}, name = ball.Name, n = 0 }
                    HL.balls[ball] = B
                end
                local v = getBallVelocityVector(ball)
                local sp, pos = v.Magnitude, part.Position
                local s = B.s
                -- skip glitched physics (NaN / huge): it would poison the math
                if sp == sp and sp < 1e5 and pos.X == pos.X and math.abs(pos.X) < 1e7 then
                    s[#s + 1] = { now, sp, v, pos }
                end
                while s[1] and now - s[1][1] > HL.KEEP do table.remove(s, 1) end
                local target = Clash.targetOf(ball)
                if not B.seen then
                    B.seen, B.target = true, target   -- already in play when first seen: not a hit
                elseif target ~= B.target then
                    if target then HL.newHit(ball, B, now, B.target, target) end
                    B.target = target
                end
            end
        end
        local left = {}
        for _, h in ipairs(HL.pending) do   -- oldest first: each hit needs the one before pinned
            if not HL.measure(h, now) then left[#left + 1] = h end
        end
        HL.pending = left
        if HUD.HitLog and now - (HL.hudAt or 0) >= 0.25 then
            HL.hudAt = now
            setDesc(HUD.HitLog, HL.status())
        end
    end

    -- Average change per hit (serves and ability launches from no target left out).
    HL.stats = function()
        local pcts, adds, ups, sames, downs = {}, {}, 0, 0, 0
        for _, h in ipairs(HL.hits) do
            if h.pct and not h.serve then
                pcts[#pcts + 1], adds[#adds + 1] = h.pct * 100, h.add
                if h.pct > 0.01 then ups = ups + 1 elseif h.pct < -0.01 then downs = downs + 1 else sames = sames + 1 end
            end
        end
        local function mean(t) local x = 0 for _, v in ipairs(t) do x = x + v end return #t > 0 and x / #t or nil end
        local function sd(t, m)
            if #t < 2 then return nil end
            local x = 0 for _, v in ipairs(t) do x = x + (v - m) ^ 2 end
            return math.sqrt(x / (#t - 1))
        end
        local mp, ma = mean(pcts), mean(adds)
        return {
            n = #pcts, mp = mp, ma = ma, sp = mp and sd(pcts, mp), sa = ma and sd(adds, ma),
            medp = median(copy(pcts)), meda = median(copy(adds)),
            ups = ups, sames = sames, downs = downs,
        }
    end

    HL.status = function()
        local last
        for i = #HL.hits, 1, -1 do
            if HL.hits[i].sOut then last = HL.hits[i] break end
        end
        local st = HL.stats()
        local lines = { string.format("Hits logged: %d in %d rallies", #HL.hits, HL.rallies) }
        if last then
            lines[#lines + 1] = string.format("Last: %s -> %s  %.0f -> %.0f studs/s (%+.1f%%)",
                tostring(last.from or "(none)"), tostring(last.to), last.sIn or 0, last.sOut, (last.pct or 0) * 100)
        end
        if st.mp then
            lines[#lines + 1] = string.format("Avg per hit: %+.1f%% (%+.1f studs/s) over %d hits", st.mp, st.ma, st.n)
        end
        return table.concat(lines, "\n")
    end

    HL.build = function()
        local now = tick()
        local function f0(x) return x and string.format("%.0f", x) or "-" end
        local function f2(x) return x and string.format("%.2f", x) or "-" end
        local function nm(x) return tostring(x or "(none)") end
        local L = {}
        local hits = HL.hits
        L[#L + 1] = string.format("Anime Ball Hub ball hit log | %d hits in %d rallies over %.0fs | ping %.0f ms | me: %s",
            #hits, HL.rallies, now - HL.since, currentPing, LocalPlayer.Name)
        L[#L + 1] = string.format("Ball velocity shows a hit %.2fs after its Target flips (median of %d) | game HitEffect calls seen: %d, ReflectEffect: %d%s",
            HL.lag(), #HL.delays, HL.fxHit, HL.fxRef, HL.fxSeen and "" or " (hook not active)")
        local st = HL.stats()
        L[#L + 1] = "== Summary =="
        if st.mp then
            L[#L + 1] = string.format("Speed change per hit: avg %+.1f%% (median %+.1f%%) = avg %+.1f studs/s (median %+.1f) over %d hits",
                st.mp, st.medp, st.ma, st.meda, st.n)
            L[#L + 1] = string.format("Hits that sped it up: %d, kept it the same (within 1%%): %d, slowed it: %d", st.ups, st.sames, st.downs)
            if st.sp and st.sa and st.n >= 4 then
                -- which rule fits: the same % every hit, or the same studs/s every hit?
                local rp = st.sp / math.max(math.abs(st.mp), 0.1)
                local ra = st.sa / math.max(math.abs(st.ma), 0.1)
                L[#L + 1] = string.format("Spread: %.1f%% (%.2fx of the mean) vs %.1f studs/s (%.2fx) -> looks like %s",
                    st.sp, rp, st.sa, ra,
                    rp < ra and string.format("the same PERCENT each hit (~%+.1f%%)", st.medp)
                        or string.format("the same STUDS/S each hit (~%+.1f)", st.meda))
            end
        else
            L[#L + 1] = "No measured hits yet."
        end
        local top, topH, accs, gaps = 0, nil, {}, {}
        for _, h in ipairs(hits) do
            local sm = math.max(h.sOut or 0, h.seg and h.seg.smax or 0)
            if sm > top then top, topH = sm, h end
            if h.seg and h.seg.acc and h.seg.dur >= 0.15 then accs[#accs + 1] = h.seg.acc end
            if h.gap then gaps[#gaps + 1] = h.gap end
        end
        local accMed = median(accs)
        if accMed then
            L[#L + 1] = string.format("In flight between hits: median speed-up %+.1f studs/s per second (%d flights of 0.15s+)", accMed, #accs)
        end
        if topH then
            L[#L + 1] = string.format("Top speed seen: %.0f studs/s (rally %d, hit %d)", top, topH.rally, topH.n)
        end
        if #gaps > 0 then
            local g = copy(gaps)
            table.sort(g)
            L[#L + 1] = string.format("Time between hits: median %.2fs, shortest %.2fs, longest %.2fs", median(copy(gaps)), g[1], g[#g])
        end

        -- average speed after the Nth hit of a rally
        local byN, maxN = {}, 0
        for _, h in ipairs(hits) do
            if h.sOut then
                local b = byN[h.n] or { 0, 0, {} }
                b[1], b[2] = b[1] + h.sOut, b[2] + 1
                if h.pct and not h.serve then b[3][#b[3] + 1] = h.pct * 100 end
                byN[h.n] = b
                if h.n > maxN then maxN = h.n end
            end
        end
        L[#L + 1] = "== Speed after the Nth hit of a rally (average over rallies) =="
        for n = 1, math.min(maxN, 60) do
            local b = byN[n]
            if b then
                local mp = median(b[3])
                L[#L + 1] = string.format("hit %2d: %4.0f studs/s  (%s, %d rallies)", n, b[1] / b[2],
                    mp and string.format("%+.1f%%", mp) or "serve", b[2])
            end
        end

        L[#L + 1] = "== Rallies =="
        local rl, order = {}, {}
        for _, h in ipairs(hits) do
            local r = rl[h.rally]
            if not r then
                r = { first = h, n = 0, top = 0 }
                rl[h.rally] = r
                order[#order + 1] = h.rally
            end
            r.n, r.last = r.n + 1, h
            r.top = math.max(r.top, h.sOut or 0, h.seg and h.seg.smax or 0)
        end
        for _, id in ipairs(order) do
            local r = rl[id]
            local s0
            for _, h in ipairs(hits) do
                if h.rally == id and h.sOut then s0 = h.sOut break end
            end
            L[#L + 1] = string.format("rally %d (ball %s): %d hits in %.1fs, %s -> %s studs/s, top %.0f",
                id, tostring(r.first.ball), r.n, r.last.t - r.first.t, f0(s0), f0(r.last.sOut), r.top)
        end

        L[#L + 1] = "== Hits (newest last) =="
        L[#L + 1] = "r   #   time   gap  from         -> to             in   out     +%   +s/s delay  turn  plyrs ball |  flight  start  end  max  min  accel moved | game hit effect"
        L[#L + 1] = "(in/out = speed just before/after the hit; delay = Target flip -> visible turn, ~ = never turned, guessed; turn = deg the heading changed; plyrs = studs between the two players; ball = ball to hitter; flight = the flight this hit started; accel = studs/s per second; moved = avg speed from distance moved; * = flight cut off)"
        local startI = math.max(1, #hits - 199)
        for i = startI, #hits do
            local h = hits[i]
            local sg = h.seg
            if not sg and h.turn and h.B then sg = segment(h.B, h.turn + 0.05, now) end   -- still flying
            L[#L + 1] = string.format("%-3d %-3d %6.2f %5s %-12.12s -> %-12.12s %5s %5s %6s %6s %5s%s %4s %5s %4s | %6s %5s %5s %4s %4s %6s %5s%s | %s",
                h.rally, h.n, h.t - HL.since, h.gap and string.format("%.2f", h.gap) or "-",
                nm(h.from), nm(h.to), f0(h.sIn), f0(h.sOut),
                h.pct and string.format("%+.1f", h.pct * 100) or "-", h.add and string.format("%+.0f", h.add) or "-",
                f2(h.delay), h.guess and "~" or " ", f0(h.ang), f0(h.pdist), f0(h.bdist),
                sg and f2(sg.dur) or "-", sg and f0(sg.s0) or "-", sg and f0(sg.s1) or "-", sg and f0(sg.smax) or "-",
                sg and f0(sg.smin) or "-", sg and sg.acc and string.format("%+.0f", sg.acc) or "-", sg and f0(sg.moved) or "-",
                sg and sg.partial and "*" or " ", h.fx or "-")
        end

        L[#L + 1] = "== Speed around each hit (studs/s at -0.10 -0.05 | 0 +0.05 +0.10 +0.20 +0.30 s from the visible turn) =="
        for i = math.max(1, #hits - 79), #hits do
            local h = hits[i]
            if h.trace then L[#L + 1] = string.format("r%d #%d: %s", h.rally, h.n, h.trace) end
        end

        L[#L + 1] = "== Ball attributes (shown when they changed) =="
        for _, h in ipairs(hits) do
            if h.attrs then L[#L + 1] = string.format("r%d #%d %s: %s", h.rally, h.n, tostring(h.ball), h.attrs) end
        end

        L[#L + 1] = "== Game effect calls (last 40) =="
        for i = math.max(1, #HL.fx - 39), #HL.fx do
            local e = HL.fx[i]
            L[#L + 1] = string.format("%7.2f %s(%s)", e.t - HL.since, e.kind, e.text)
        end
        return table.concat(L, "\n")
    end

    -- The game's own effects: the server calls BallController.Server.HitEffect
    -- (player, sword, ball, pitch, vfx - decompiled) on a hit and
    -- ReflectEffect(ball, pitch) on a reflect. Logged as they come (and the
    -- game's function is always called as normal).
    HL.onFx = function(kind, ...)
        local n = select("#", ...)
        local args = { ... }
        local parts = {}
        for i = 1, math.min(n, 6) do parts[#parts + 1] = HL.fmt(args[i]) end
        local now = tick()
        local ref = kind == "HitEffect" and args[3] or args[1]
        local ball = resolveBallRef and resolveBallRef(ref) or nil
        local e = { t = now, kind = kind, text = table.concat(parts, ", "), ball = ball,
            player = kind == "HitEffect" and HL.fmt(args[1]) or nil }
        HL.fx[#HL.fx + 1] = e
        if #HL.fx > 200 then table.remove(HL.fx, 1) end
        if kind == "HitEffect" then HL.fxHit = HL.fxHit + 1 else HL.fxRef = HL.fxRef + 1 end
        local B = ball and HL.balls[ball]
        local h = B and B.lastHit
        if h and now - h.t <= 0.5 then
            -- (it can also arrive just BEFORE that hit's Target flip: then the
            -- flip picks it up, matched by the hitter's name)
            if kind == "HitEffect" and not h.fx and h.from == e.player then h.fx, e.used = e.text, true end
            if kind == "ReflectEffect" then h.reflects = (h.reflects or 0) + 1 end
        end
    end
    task.spawn(function()
        local BC
        for _ = 1, 15 do
            if destroyed then return end
            local ok, controller = pcall(function()
                return require(ReplicatedStorage:WaitForChild("Framework", 5)):Get("BallController")
            end)
            if ok and type(controller) == "table" and type(controller.Server) == "table" then
                BC = controller
                break
            end
            task.wait(1)
        end
        if not BC or destroyed then return end
        local restore = {}
        for _, name in ipairs({ "HitEffect", "ReflectEffect" }) do
            local orig = BC.Server[name]
            if type(orig) == "function" then
                restore[#restore + 1] = { name, orig }
                BC.Server[name] = function(...)
                    if not destroyed and HL.on then pcall(HL.onFx, name, ...) end
                    return orig(...)
                end
            end
        end
        HL.fxSeen = #restore > 0
        HL.fxRestore = function()
            for _, r in ipairs(restore) do
                pcall(function() BC.Server[r[1]] = r[2] end)
            end
            restore = {}
        end
    end)

    track(RunService.Heartbeat:Connect(function()
        if destroyed or not HL.on then return end
        local ok, err = pcall(HL.step)
        if not ok and not HL.err then
            HL.err = true   -- report once, don't spam every frame
            warn("[Anime Ball Hub] Ball Hit Logger error: " .. tostring(err))
        end
    end))
    pcall(function() _genv.AnimeBallHubHitLog = function() return HL.build() end end)
end

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

-- Miss Recorder, ability context: log every ability the server plays on this
-- client (AbilityController.Server.* - e.g. Explode("ChronoStasis Activate"),
-- AbilityEffect(...)) and the ability-related state changes on balls and
-- players (Anchored = frozen ball, Invisible, UsingAbility, SlowTime, ...), so
-- a miss report shows WHICH ability was in play. Logging only; every wrapper
-- calls the game's original and is restored on unload.
task.spawn(function()
    local AC = getController("AbilityController")
    if not AC or destroyed or type(AC.Server) ~= "table" then return end
    pcall(function()
        local names = {}
        for name, fn in pairs(AC.Server) do
            if type(fn) == "function" then names[#names + 1] = name end
        end
        for _, name in ipairs(names) do
            patch(AC.Server, name, function(orig)
                return function(...)
                    if not destroyed then
                        local args = { n = select("#", ...), ... }
                        pcall(function()
                            local parts = {}
                            for i = 1, math.min(args.n, 3) do
                                local a = args[i]
                                parts[#parts + 1] = typeof(a) == "Instance" and a.Name or tostring(a)
                            end
                            Clash.event(tick(), "ABILITY " .. name .. "(" .. table.concat(parts, ", ") .. ")")
                        end)
                    end
                    return orig(...)
                end
            end)
        end
    end)
end)
do
    local WATCH = { Invisible = true, UsingAbility = true, SlowTime = true, IsTarget = true,
                    Stunned = true, Frozen = true, ClashEffect = true }
    local function watchAttrs(inst, label)
        pcall(function()
            track(inst.AttributeChanged:Connect(function(attr)
                if WATCH[attr] or attr:find("Ability") or attr:find("Slow") then
                    pcall(function() Clash.event(tick(), string.format("%s %s=%s", label, attr, tostring(inst:GetAttribute(attr)))) end)
                end
            end))
        end)
    end
    local function watchBall(ball)
        watchAttrs(ball, "BALL")
        pcall(function()
            track(ball:GetPropertyChangedSignal("Anchored"):Connect(function()
                Clash.event(tick(), "BALL Anchored=" .. tostring(ball.Anchored) .. " (frozen ball)")
            end))
        end)
    end
    local function watchPlayer(pl)
        local label = pl == LocalPlayer and "ME" or ("PLAYER " .. pl.Name)
        watchAttrs(pl, label)
        if pl.Character then watchAttrs(pl.Character, label) end
        pcall(function() track(pl.CharacterAdded:Connect(function(c) watchAttrs(c, label) end)) end)
    end
    task.spawn(function()
        pcall(function()
            local balls = workspace:WaitForChild("Balls", 10)
            if not balls then return end
            for _, b in ipairs(balls:GetChildren()) do watchBall(b) end
            track(balls.ChildAdded:Connect(watchBall))
        end)
        pcall(function()
            for _, pl in ipairs(Players:GetPlayers()) do watchPlayer(pl) end
            track(Players.PlayerAdded:Connect(watchPlayer))
        end)
    end)
end

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

-- Auto-Dash Away (see AutoDash at the top). Own throttled Heartbeat so it adds
-- nothing to the parry loop. Direction: straight away from the threat, rotated
-- by AutoDash.angle toward the side you're already moving (so it keeps your
-- momentum instead of fighting it).
AutoDash.dirFor = function(myPos, myVel, threatPos)
    local away = Vector3.new(myPos.X - threatPos.X, 0, myPos.Z - threatPos.Z)
    if away.Magnitude < 1e-3 then
        away = Vector3.new(myVel.X, 0, myVel.Z)
        if away.Magnitude < 1e-3 then away = Camera.flatDir * -1 end
    end
    away = away.Unit
    local side = Vector3.new(-away.Z, 0, away.X)              -- perpendicular, flat
    local s = (myVel.X * side.X + myVel.Z * side.Z) >= 0 and 1 or -1
    local a = math.rad(AutoDash.angle)
    local dir = away * math.cos(a) + side * (s * math.sin(a))
    return dir.Magnitude > 1e-3 and dir.Unit or away
end
AutoDash.threat = function(hrp)
    local myPos, myVel = hrp.Position, hrp.AssemblyLinearVelocity
    -- 1) A player rushing into you (a dash-in clash).
    for _, pl in ipairs(Players:GetPlayers()) do
        if pl ~= LocalPlayer then
            local ohrp = getPlayerHRP(pl)
            if ohrp then
                local off = myPos - ohrp.Position
                local d = off.Magnitude
                if d > 1e-3 and d <= AutoDash.range then
                    local closing = (ohrp.AssemblyLinearVelocity - myVel):Dot(off) / d
                    if closing >= AutoDash.closing then
                        return ohrp.Position, "rush: " .. pl.Name .. string.format(" (%.0f studs/s)", closing)
                    end
                end
            end
        end
    end
    -- 2) A ball about to hit point-blank while your block was just rejected
    --    (still on cooldown), so blocking can't save you - dodge instead.
    if tick() - AutoDash.rejectedAt <= 0.6 then
        for ball in pairs(ballsCache) do
            if ball.Parent then
                local bp = getBallPosition(ball)
                if bp then
                    local off = myPos - bp
                    local d = off.Magnitude
                    if d > 1e-3 and d <= AutoDash.range then
                        local closing = getBallVelocityVector(ball):Dot(off) / d
                        if closing > 0 and (d - EFFECTIVE_HIT_RADIUS) / closing <= 0.35 then
                            return bp, "ball on cooldown"
                        end
                    end
                end
            end
        end
    end
    return nil
end
AutoDash.inClash = function()
    if Clash.server == true or spamStarted then return true end
    if tick() < Clash.forceUntil then return true end
    if #Clash.flipTimes >= Clash.MIN_FLIPS then return true end
    local effects = workspace:FindFirstChild("Effects")
    return effects ~= nil and effects:GetAttribute("ClashEffect") == true
end
track(RunService.Heartbeat:Connect(function()
    if destroyed or not AutoDash.enabled then return end
    local now = tick()
    if now - AutoDash.lastFire < 1.15 then return end     -- the game's dash cooldown is 1.1s
    local ctl = Dash.controller
    if not ctl or type(ctl.ForceDash) ~= "function" or ctl.CanDash == false or ctl.Dashing == true then return end
    -- Never dash out of a clash: dashing away mid-clash breaks the exchange
    -- the parry is holding. Any clash signal counts (server StartClash, the
    -- game's ClashEffect attribute, the clash hold window, ball reversals, or
    -- Auto Spam currently spamming a clash).
    if AutoDash.inClash() then
        setDesc(HUD.AutoDash, string.format("Dashed %d time(s)\nPaused: you're in a clash", AutoDash.count))
        return
    end
    local hrp = getPlayerHRP(LocalPlayer)
    if not hrp then return end
    local threatPos, reason = AutoDash.threat(hrp)
    if not threatPos then return end
    local dir = AutoDash.dirFor(hrp.Position, hrp.AssemblyLinearVelocity, threatPos)
    AutoDash.lastFire = now
    -- The game's Dash reads your MoveDirection (unless W/A/S/D is held), so
    -- point it at the escape angle, then let the game's own dash fire (keeps
    -- its animation, replication and cooldown). Separate pcalls: a failed
    -- Move must never stop the dash itself.
    pcall(function()
        local humanoid = hrp.Parent and hrp.Parent:FindFirstChildOfClass("Humanoid")
        if humanoid then humanoid:Move(dir, false) end
    end)
    AutoDash.lastDir = dir
    pcall(function() ctl.ForceDash() end)
    AutoDash.count = AutoDash.count + 1
    AutoDash.lastReason = reason
    setDesc(HUD.AutoDash, string.format("Dashed %d time(s)\nLast: %s", AutoDash.count, reason))
end))

-- Return Pre-Shield. The fast close-return miss: an opponent near you hits the
-- ball straight back, and it lands in (gap - hit radius) / speed seconds -
-- often LESS than your ping, so a block fired after the ball turns can't reach
-- the server in time (sandbox: 7/12 missed at 120-200 ms). So while a ball
-- aimed at a nearby opponent is about to reach them, and their return would be
-- too fast to react to, fire the block now, timed so the 0.6s shield (which
-- registers half-a-ping after firing) covers the return. One block per
-- approach; own Heartbeat so it adds nothing to the parry loop.
Clash.RET_RANGE = 35        -- studs: opponent must be this close for a too-fast return
Clash.RET_SPEEDUP = 1.25    -- assume the return comes back this much faster (balls speed up per hit)
Clash.FRESH_MAX = 0.35      -- fresh return: block on the target switch when the straight line takes <= this
Clash.retBall, Clash.retAt, Clash.retCount = nil, 0, 0
Clash.retPrev, Clash.retPrevAt = setmetatable({}, { __mode = "k" }), setmetatable({}, { __mode = "k" })
Clash.retApp, Clash.retLockApp = setmetatable({}, { __mode = "k" }), nil
Clash.retWant, Clash.retWantAt, Clash.retWantApp, Clash.retWantUntil, Clash.retWantArr = nil, 0, nil, 0, 0
Clash.retLast = setmetatable({}, { __mode = "k" })
Clash.toMeAt, Clash.heldFor = setmetatable({}, { __mode = "k" }), setmetatable({}, { __mode = "k" })
Clash.fastSpd, Clash.fastAt = setmetatable({}, { __mode = "k" }), setmetatable({}, { __mode = "k" })
Clash.frozenSrv, Clash.stasisFor = setmetatable({}, { __mode = "k" }), setmetatable({}, { __mode = "k" })
Clash.STASIS_T = 4.0        -- Stasis holds the ball this long (AbilityInfo)
track(RunService.Heartbeat:Connect(function()
    if destroyed or not Clash.retOn or not autoParryEnabled then return end
    local hrp = getPlayerHRP(LocalPlayer)
    if not hrp then return end
    -- Every block this handler sends is timed for a RETURN (see Clash.spentRaw).
    Clash.returnSend = true
    local ok, err = pcall(Clash.preShieldStep, hrp)
    Clash.returnSend = false
    if not ok and not Clash.preShieldErr then
        Clash.preShieldErr = true   -- report once, don't spam every frame
        warn("[Anime Ball Hub] Return Pre-Shield error: " .. tostring(err))
    end
end))
Clash.preShieldStep = function(hrp)
    local now = tick()
    local myPos = hrp.Position
    local ping = math.max(smoothedPing, currentPing) / 1000
    local myName = LocalPlayer.Name
    -- Rally chain. In a rally fast enough that my last two parries came less
    -- than CHAIN_GAP apart, the next return lands inside a shield raised right
    -- after a parry, and the ball on screen (half a ping + VIEW_LAG old) is out
    -- of step with the real one - it shows the ball coming at me while it is
    -- at the opponent. Nothing that waits to SEE the return can be on time, so
    -- after each parry send the next block the moment the shield lock lets it
    -- land - as the current shield ends (sandbox: a 0.23s rally at 420
    -- studs/s was lost waiting).
    local pa = Clash.parryAt
    if Clash.farRally and pa[1] > Clash.chainFor
        and pa[1] - pa[2] <= Clash.CHAIN_GAP and pa[2] - pa[3] <= Clash.CHAIN_GAP
        and now - pa[1] <= Clash.CHAIN_GAP + 0.1 then
        local sent = fireBlockRemote(false, "rally chain")
        if sent then
            if not Clash.lastProbe then Clash.chainFor = pa[1] end
            totalBurstBlocks = totalBurstBlocks + 1
        end
    end
    -- A pre-shield block held back (shield lock, or the one-in-flight slot
    -- busy - see below). Dropped once its return can no longer be covered, if
    -- I parried since, or if the block that was in flight came back accepted
    -- and its shield already covers that return: then a fresh block would only
    -- land on a ball flying away and burn the cooldown (real miss reports #4
    -- and #5).
    if Clash.retWant then
        if now > Clash.retWantUntil or Clash.parryAt[1] > Clash.retWantAt
            or (Clash.farRally and Clash.retWantArr >= Clash.shieldFrom - 0.05
                and Clash.retWantArr <= Clash.shieldTo - frameLag and not Clash.shieldSpent()) then
            Clash.retWant = nil
        elseif fireBlockRemote(false, "pre-shield, held") then
            if not Clash.lastProbe then
                Clash.retBall, Clash.retAt, Clash.retLockApp = Clash.retWant, now, Clash.retWantApp
            end
            Clash.retCount = Clash.retCount + 1
            totalBurstBlocks = totalBurstBlocks + 1
            Clash.retWant = nil
        end
    end
    for ball in pairs(ballsCache) do
        local target = ball.Parent and ball:GetAttribute("Target") or nil
        local sm = serverTargetCache[ball]
        if sm ~= nil and (now - sm.time) < SERVER_TARGET_TTL then target = sm.target end
        -- A ball that was aimed at me and is now aimed at someone else was
        -- parried by me. The game's own BlockSuccess signal never showed up in
        -- the real miss reports, so this is how parries are noticed there.
        if type(target) == "string" and target ~= myName and Clash.retLast[ball] == myName then
            Clash.noteParry(now)
        end
        if target == myName and Clash.retLast[ball] ~= myName then
            Clash.toMeAt[ball] = now
            Clash.toMeLast = now
        end
        Clash.retLast[ball] = target
        -- Held ability launch (real miss report #6, 158 ms). Another player's
        -- ability HELD the ball - it read speed 0 - then switched its target to
        -- me and shot it at ~475 studs/s from ~125 studs.
        -- The ball on screen is half a ping + VIEW_LAG old, so it still sat
        -- there at speed 0 when the target said me, and by the time it visibly
        -- moved a block could no longer land in time. So when a ball that was
        -- just moving fast is held (under a quarter of that speed) and its
        -- target switches to me,
        -- block for the earliest it can arrive at the speed it had: from where
        -- it is (a held ball's position is current), counted from the switch.
        -- A hovering serve never qualifies: it was not fast a moment ago.
        do
            local bp = ball.Parent and getBallPosition(ball)
            local bv = bp and getBallVelocityVector(ball)
            local spd = bv and bv.Magnitude or 0
            if spd >= 60 then
                if not (Clash.fastAt[ball] and now - Clash.fastAt[ball] < 0.5 and Clash.fastSpd[ball] > spd) then
                    Clash.fastSpd[ball] = spd
                end
                Clash.fastAt[ball] = now
            end
            local fs, fa, toMe = Clash.fastSpd[ball], Clash.fastAt[ball], Clash.toMeAt[ball]
            if target == myName and bp and fs and fs >= 150 and spd < 0.25 * fs and now - fa <= 2.5
                and toMe and now - toMe <= Clash.FRESH_MAX + 0.1 and Clash.heldFor[ball] ~= toMe then
                local straight = math.max((bp - myPos).Magnitude - EFFECTIVE_HIT_RADIUS, 0) / (fs * Clash.RET_SPEEDUP)
                local earliest = toMe - ping / 2 + straight
                local covered = Clash.farRally and earliest >= Clash.shieldFrom - 0.05
                    and earliest + straight * 1.7 <= Clash.shieldTo - frameLag and not Clash.shieldSpent()
                if straight <= Clash.FRESH_MAX and not covered and now + ping / 2 >= earliest - 0.05 then
                    if fireBlockRemote(false, "held launch") then
                        if not Clash.lastProbe then Clash.heldFor[ball] = toMe end
                        totalBurstBlocks = totalBurstBlocks + 1
                    end
                end
            end
            -- Stasis ("Stop the ball in mid air for 4 seconds or until parried!"
            -- - AbilityInfo). A ball aimed at me that was flying and now sits
            -- frozen near me resumes 4s after it stopped, and from up close it
            -- lands before I could even SEE it move again (it is half a ping +
            -- VIEW_LAG old). So block for that moment: the shield goes up just
            -- before the release. Only while it is still frozen and still aimed
            -- at me, so an early release (parried out of it) can't waste it.
            if target == myName and bp and spd < 2 and (bp - myPos).Magnitude <= 150 then
                if not Clash.frozenSrv[ball] and fa and now - fa <= 1.0 then
                    -- when it stopped, on the server's clock: an Anchored ball
                    -- shows it half a ping late, a stopped position VIEW_LAG later
                    local anchored = false
                    pcall(function() anchored = getBallPart(ball).Anchored == true end)
                    Clash.frozenSrv[ball] = now - ping / 2 - (anchored and 0 or Clash.VIEW_LAG)
                end
            else
                Clash.frozenSrv[ball] = nil
            end
            local fz = Clash.frozenSrv[ball]
            if fz and now - fz >= 0.3 and Clash.stasisFor[ball] ~= fz
                and now + ping / 2 >= fz + Clash.STASIS_T - 0.1 then
                if fireBlockRemote(false, "stasis") then
                    if not Clash.lastProbe then Clash.stasisFor[ball] = fz end
                    totalBurstBlocks = totalBurstBlocks + 1
                end
            end
        end
        -- One block per APPROACH (each time the ball is sent at an opponent):
        -- a fixed 0.8s lock still held the NEXT approach in a long rally
        -- (sandbox: round trips ~0.7s).
        if type(target) == "string" and target ~= myName then
            if target ~= Clash.retPrev[ball] or Clash.retPrevAt[ball] == nil
                or now - Clash.retPrevAt[ball] > 0.1 then
                Clash.retApp[ball] = (Clash.retApp[ball] or 0) + 1
            end
            -- The target reaches me half a ping after the opponent hits, but the
            -- ball on screen is VIEW_LAG further behind - it is still flying to
            -- them when the target already says me. Keep treating it as that
            -- approach for that long, or the pre-shield never gets its turn on
            -- a far opponent (sandbox: 55 studs at 160 ms).
            Clash.retPrev[ball], Clash.retPrevAt[ball] = target, now
        elseif target == myName and Clash.retPrev[ball]
            and now - Clash.retPrevAt[ball] <= Clash.FRESH_MAX + 0.1 then
            -- Fresh return: the target just switched from them to me - they hit
            -- it. That reaches me half a ping after the hit, while the ball on
            -- screen is another VIEW_LAG behind and may still be looping out
            -- (sandbox: a 250 studs/s serve launched 150 deg away showed 62 studs
            -- out, only starting to turn, as the real one landed). The earliest
            -- it can arrive is the straight line from them; a shield raised for
            -- that still covers a loop up to ~2x longer, so when that straight
            -- line is short, block for it now instead of waiting to SEE it.
            local fromName = Clash.retPrev[ball]
            local fhrp = nil
            for _, pl in ipairs(Players:GetPlayers()) do
                if pl.Name == fromName then fhrp = getPlayerHRP(pl) break end
            end
            local bp = fhrp and getBallPosition(ball)
            local vel = bp and getBallVelocityVector(ball)
            local speed = vel and vel.Magnitude or 0
            if bp and speed > 1 and ball.Parent
                and not (Clash.retBall == ball and Clash.retLockApp == Clash.retApp[ball])
                and ((fhrp.Position - bp).Magnitude <= 30 or vel:Dot(fhrp.Position - bp) > 0) then
                -- The return starts where THEY parried it - a hit radius out from
                -- them, toward me - and ends a hit radius out from me (counting
                -- only my side made a slow 27-stud return look 0.13s later than
                -- it was, and the block landed with the ball - sandbox).
                local straight = math.max((fhrp.Position - myPos).Magnitude - 2 * EFFECTIVE_HIT_RADIUS, 0)
                    / (speed * Clash.RET_SPEEDUP)
                local earliest = Clash.retPrevAt[ball] - ping / 2 + straight
                local latest = earliest + straight * 1.7
                local covered = Clash.farRally and earliest >= Clash.shieldFrom - 0.05
                    and latest <= Clash.shieldTo - frameLag and not Clash.shieldSpent()
                if straight <= Clash.FRESH_MAX and not covered and now + ping / 2 >= earliest - 0.05 then
                    if fireBlockRemote(false, "fresh return") then
                        if not Clash.lastProbe then
                            Clash.retBall, Clash.retAt, Clash.retLockApp = ball, now, Clash.retApp[ball]
                        end
                        Clash.retCount = Clash.retCount + 1
                        totalBurstBlocks = totalBurstBlocks + 1
                        Clash.retWant = nil
                    elseif Clash.retWant == nil then
                        Clash.retWant, Clash.retWantAt, Clash.retWantApp = ball, now, Clash.retApp[ball]
                        Clash.retWantUntil, Clash.retWantArr = latest - ping / 2, latest
                    end
                end
            end
            -- ...and for VIEW_LAG after the switch the ball on screen is still
            -- flying to them: keep treating it as that approach.
            if now - Clash.retPrevAt[ball] <= ping / 2 + Clash.VIEW_LAG + 0.05 then
                target = fromName
            end
        end
        if ball.Parent and not (Clash.retBall == ball and Clash.retLockApp == Clash.retApp[ball]) then
            local ohrp = nil
            if type(target) == "string" and target ~= myName then
                for _, pl in ipairs(Players:GetPlayers()) do
                    if pl.Name == target then ohrp = getPlayerHRP(pl) break end
                end
            end
            if ohrp then
                local gap = (ohrp.Position - myPos).Magnitude
                local bp = getBallPosition(ball)
                local vel = bp and getBallVelocityVector(ball) or nil
                local speed = vel and vel.Magnitude or 0
                -- Range scales with ping and ball speed: a return is too fast to
                -- react to whenever it can cover the gap within ping + 0.05s, so a
                -- fixed 35 studs missed farther opponents at high ping (45 studs
                -- at 200 ms in move_return_test). Capped so far players are ignored.
                -- The ball on screen also trails the real one by VIEW_LAG (Roblox
                -- interpolation), and you can only react once it visibly turns, so
                -- that counts toward "too fast" too (sandbox: a 55-stud return at
                -- 160 ms was left to the reactive path and arrived 0.04s unblocked).
                local react = ping + frameLag + 0.05 + Clash.VIEW_LAG
                local reach = Clash.RET_RANGE
                if speed > 1 then
                    reach = math.clamp(react * speed * Clash.RET_SPEEDUP + EFFECTIVE_HIT_RADIUS,
                        Clash.RET_RANGE, 90)
                end
                if bp and gap <= reach then
                    local toP = ohrp.Position - bp
                    local dP = toP.Magnitude
                    local closing = dP > 1e-3 and vel:Dot(toP) / dP or 0
                    if closing > 1 and speed > 1 then
                        local ttiToP = math.max(dP - EFFECTIVE_HIT_RADIUS, 0) / closing
                        -- Your own movement changes the return time: dashing/jumping
                        -- IN shortens it, dashing AWAY lengthens it (firing early
                        -- then would let the shield expire before the ball lands and
                        -- the cooldown block the real block). Signed, floored so a
                        -- hard dash away can't make the estimate absurd.
                        local towardP = (ohrp.Position - myPos)
                        local myIn = gap > 1e-3 and hrp.AssemblyLinearVelocity:Dot(towardP) / gap or 0
                        local retClose = math.max(speed * Clash.RET_SPEEDUP + myIn, speed * 0.5)
                        local returnWindow = math.max(gap - EFFECTIVE_HIT_RADIUS, 0) / retClose
                        -- Fire as LATE as still covers it: predicted arrival within
                        -- ping + 0.2s leaves ~0.4s of the 0.6s shield as slack if the
                        -- return takes longer than predicted (you dash away after we
                        -- fire). And only when reacting after the turn truly can't
                        -- make it (ping + a frame + 0.05s); otherwise the normal
                        -- reactive parry handles it without spending the cooldown early.
                        -- When the return lands while the shield I already have
                        -- is still up, that shield takes it: a block now would be
                        -- refused, or land as it ends on a ball already flying
                        -- away and start a fresh 1s cooldown (real miss report
                        -- #4). Its real arrival = what I see moved forward by
                        -- half a ping + VIEW_LAG.
                        -- The return is counted at a THIRD of the ball's speed: a
                        -- homing return can loop far out and back (sandbox: a 52-stud
                        -- return at 420 studs/s took 0.28s, 2.3x the straight line),
                        -- and calling it covered when it isn't is a sure miss.
                        local retArrive = now - ping / 2 - Clash.VIEW_LAG + ttiToP
                            + math.max(gap - EFFECTIVE_HIT_RADIUS, 0) / (speed / 3)
                        local covered = Clash.farRally and retArrive >= Clash.shieldFrom - 0.05
                            and retArrive <= Clash.shieldTo - frameLag and not Clash.shieldSpent()
                        if not covered and returnWindow < react
                            and (ttiToP + returnWindow) <= ping + 0.2 then
                            -- Locked only once a block actually went out. One held
                            -- back (shield lock, rate cap) stays PENDING and goes the
                            -- moment it can (top of this loop): by the time the lock
                            -- lets it land, the ball on screen may already have
                            -- reached them and this check no longer runs (sandbox:
                            -- a 0.59s rally lost its return that way).
                            if fireBlockRemote(false, "pre-shield") then
                                if not Clash.lastProbe then
                                    Clash.retBall, Clash.retAt, Clash.retLockApp = ball, now, Clash.retApp[ball]
                                end
                                Clash.retCount = Clash.retCount + 1
                                totalBurstBlocks = totalBurstBlocks + 1
                                Clash.retWant = nil
                            elseif Clash.retWant == nil then
                                Clash.retWant, Clash.retWantAt, Clash.retWantApp = ball, now, Clash.retApp[ball]
                                Clash.retWantUntil, Clash.retWantArr = retArrive - ping / 2, retArrive
                            end
                            break
                        end
                    end
                end
            end
        end
    end
end

-- Game's server-side auto parry (see GameAP at the top).
-- (kept as a field, not a local: the main chunk is at Luau's 200-local limit)
GameAP.statusText = function(text)
    GameAP.status = text
    setDesc(HUD.GameAP, "Status: " .. text)
end
GameAP.setEnabled = function(on)
    task.spawn(function()
        local svc
        local okFetch = pcall(function()
            svc = require(ReplicatedStorage:WaitForChild("Framework", 5)):Fetch("AutoParryService")
        end)
        if not okFetch or type(svc) ~= "table" or svc.SetEnabled == nil then
            GameAP.statusText(on and "not available in this server/version" or "off")
            return
        end
        if on then GameAP.statusText("asking the server...") end
        local ok, result = pcall(function() return svc.SetEnabled:Invoke(on) end)
        if destroyed and on then
            pcall(function() svc.SetEnabled:Invoke(false) end)
            return
        end
        if not ok then
            GameAP.statusText("error: " .. tostring(result))
        elseif result == nil then
            GameAP.statusText(on and "REFUSED - the server doesn't allow it for your account" or "off")
        elseif result == true then
            GameAP.active = true
            GameAP.statusText("ON - the server is parrying for you")
            notify("Server Auto Parry", "Enabled by the game server")
        else
            GameAP.active = false
            GameAP.statusText("off")
        end
    end)
end
if GameAP.want then GameAP.setEnabled(true) end

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
local function runAutoSpam(amTargeted, clashDetected, realClash, hudTick, recentlyTargeted)
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
        -- STAY used to be "clash OR any ball within 34 studs", so once started
        -- Auto Spam never stopped while a ball idled nearby - even after the
        -- clash ended and the ball was aimed at someone else (sandbox: 60 extra
        -- blocks/s after EndClash, each one burning the cooldown). A nearby
        -- ball only keeps it going while it's still recently been aimed at me.
        spamStayCond = clashDetected or (ballInRange and recentlyTargeted)
    else
        spamStartCond = playerInRange and ballInRange and amTargeted
        spamStayCond = ballInRange and recentlyTargeted
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

-- Is a ball near me (within `radius` studs) in play between me and `otherName`?
-- True when its target (fresh server capture, else the attribute) is me, them,
-- or not assigned yet. Used to gate the dash-in pre-shield.
Clash.targetOf = function(ball)
    local target = ball:GetAttribute("Target")
    local sm = serverTargetCache[ball]
    if sm ~= nil and (tick() - sm.time) < SERVER_TARGET_TTL then target = sm.target end
    if type(target) ~= "string" then return nil end
    return target
end
-- True when the ball's target is another player more than PARTNER_NEAR studs
-- from me (a long-range rally, not a point-blank clash). Unknown target = false.
Clash.PARTNER_NEAR = 25
Clash.partnerFar = function(ball, myPos)
    local tgt = Clash.targetOf(ball)
    if not tgt or tgt == LocalPlayer.Name then return false end
    for _, pl in ipairs(Players:GetPlayers()) do
        if pl.Name == tgt then
            local o = getPlayerHRP(pl)
            return o ~= nil and (o.Position - myPos).Magnitude > Clash.PARTNER_NEAR
        end
    end
    return false
end
Clash.holdAway = false
-- Distance to the nearest other living player (math.huge if none).
Clash.nearestOther = function(myPos)
    local best = math.huge
    for _, pl in ipairs(Players:GetPlayers()) do
        if pl ~= LocalPlayer then
            local o = getPlayerHRP(pl)
            if o then
                local d = (o.Position - myPos).Magnitude
                if d < best then best = d end
            end
        end
    end
    return best
end
Clash.NEAR_BALL = 22
Clash.ballInvolves = function(otherName, myPos, radius)
    local myName = LocalPlayer.Name
    for ball in pairs(ballsCache) do
        if ball.Parent then
            local bp = getBallPosition(ball)
            if bp and (bp - myPos).Magnitude <= radius then
                local target = ball:GetAttribute("Target")
                local sm = serverTargetCache[ball]
                if sm ~= nil and (tick() - sm.time) < SERVER_TARGET_TTL then target = sm.target end
                if type(target) ~= "string" or target == myName or target == otherName then
                    return true
                end
            end
        end
    end
    return false
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
    if amTargeted then Clash.meAt = currentTime end
    local inMyClash = (currentTime - Clash.meAt) <= Clash.PART_WINDOW or closestAnyDist <= Clash.NEAR

    -- Clash detection: count rapid direction reversals of the closest ball.
    -- Runs outside the parry branch so Auto Spam's clash sensing works even
    -- with Auto Parry toggled off.
    local ballPos, ballVel
    if closestBall then
        ballPos = getBallPosition(closestBall)
        ballVel = getBallVelocityVector(closestBall)
        -- Only count reversals of a ball I'm part of (see Clash.meAt): a ball
        -- ping-ponging between two OTHER players reverses just the same.
        if inMyClash and Clash.lastVelBall == closestBall and Clash.lastVelVec then
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
    -- Match-wide signal -> only mine if I'm a participant.
    if realClash and not inMyClash then realClash = false end
    if realClash then Clash.forceUntil = currentTime + Clash.GRACE end
    local clashActive = realClash or currentTime < Clash.forceUntil
    local clashDetected = clashActive or (#Clash.flipTimes >= Clash.MIN_FLIPS)
    -- Long-range rally hold (real miss report #2): while my clash's ball is
    -- aimed at a partner who is NOT on top of me, no path may fire - see the
    -- clashFire note in the parry branch.
    -- A FAST exchange - my last parries came FAST_GAP apart or less - is a
    -- clash whatever the distance (real miss report #9: an opponent ~28 studs
    -- away, a return every ~0.2s). There the next pass always lands within a
    -- shield raised right after a parry, so none of the long-rally rules below
    -- (hold while it flies to them, one block at a time, shield lock, cover
    -- hold) protects anything - they only stop the stream of blocks that keeps
    -- one landing right after each parry, which is what holds a clash when a
    -- parry uses the shield up.
    local pa = Clash.parryAt
    Clash.fastRally = pa[1] - pa[2] <= Clash.FAST_GAP and pa[2] - pa[3] <= Clash.FAST_GAP
        and currentTime - pa[1] <= Clash.FAST_GAP + 0.15
    Clash.holdAway = closestBall ~= nil and clashDetected and not amTargeted and not Clash.fastRally
        and Clash.partnerFar(closestBall, humanoidRootPart.Position)
    Clash.covered = false   -- set again in the parry branch below (Shield-cover hold)
    -- Shield lock / cover hold only outside a game clash and with nobody within
    -- PARTNER_NEAR studs (a point-blank exchange keeps firing as before).
    Clash.farRally = closestBall ~= nil and not clashActive and not Clash.fastRally
        and Clash.nearestOther(humanoidRootPart.Position) > Clash.PARTNER_NEAR

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
        -- Never below the range this ball's speed calls for (real miss report #4).
        -- A serve that hovered next to another player froze the range small; the
        -- freeze then kept overwriting it after launch, and high-speed mode only
        -- sets MAX on the frame it switches on - so a 380 studs/s ball was
        -- "out of range" (W=0) at 46 studs. Freezing exists to stop the range
        -- SHRINKING; growing it never causes a miss.
        if velocity > 0 then
            local need = calculateDistance(velocity)
            if currentParryDistance < need then
                currentParryDistance = need
                if isAutoParryFrozen then frozenParryDistance = need end
            end
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
                -- Target-agnostic only while the target is UNKNOWN (first frames,
                -- not replicated yet) or in a clash. Once the ball is known to be
                -- aimed at someone else - e.g. the instant after my own parry -
                -- firing here lands a block on nothing and spends the cooldown
                -- the ball's quick return needs (real miss report #1).
                and ((clashActive and not Clash.holdAway) or Clash.targetOf(closestBall) == nil
                    or Clash.targetOf(closestBall) == LocalPlayer.Name)

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
        -- ...and only for a ball that is actually a threat to ME: aimed at me,
        -- not assigned yet (a hovering serve), or part of my real clash. A REAL
        -- miss (report #1, 153 ms) came from this: right after a successful
        -- parry the ball switched to another target but stayed within 22 studs,
        -- point-blank kept firing, one block landed on nothing (the parry had
        -- reset the cooldown), and the ball's quick return found every block
        -- rejected. replay_miss1.lua reproduces it.
        -- Long-range rally hold (see the clashFire note below). Decided from the
        -- ball's TARGET, not its motion: right after my parry the server switches
        -- the target to the opponent while my ping-stale view still shows the
        -- ball coming in, so a motion check fires too late (sandbox replay).
        local pointBlank = closestBall ~= nil and closestDistance <= (EFFECTIVE_HIT_RADIUS + 11)
            and (surfaceTTI <= shieldLead or velocity == 0)
            and (amTargeted or ((clashActive or fastClashHold) and not Clash.holdAway)
                or Clash.targetOf(closestBall) == nil)
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
                            -- Only a pre-shield if a ball near me is actually in
                            -- play between us (see Clash.ballInvolves): a player
                            -- merely standing/walking next to me while the ball is
                            -- elsewhere fired a block every frame (180 in 3s in the
                            -- sandbox) and kept me on cooldown for the real ball.
                            -- Dashing at me (>= 45 studs/s) with a ball of ours in
                            -- play within 34 studs, or standing on top of me (<= 9)
                            -- with such a ball within 22 studs.
                            if (oClose >= 45 and Clash.ballInvolves(pl.Name, humanoidRootPart.Position, 34))
                                or (od <= 9 and Clash.ballInvolves(pl.Name, humanoidRootPart.Position, Clash.NEAR_BALL)) then
                                clashIncoming = true break
                            end
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
        -- Long-range rally hold (real miss report #2, 108 ms): in a clash with an
        -- opponent ~60 studs away, firing nonstop meant the block right after
        -- each successful parry (which resets the cooldown) was ACCEPTED on a
        -- ball now flying away, starting a fresh 1s cooldown that was still
        -- running when their return arrived ~0.5-1s later. So while the ball is
        -- aimed at a player who is NOT on top of me, hold the clash fire
        -- (Clash.holdAway, computed above); it resumes the moment the ball is
        -- aimed at me again. Point-blank clashes (partner within 25 studs) are
        -- unchanged.
        local clashFire = (clashActive or fastClashHold) and not Clash.holdAway
        local alwaysFire = clashFire or pointBlank or clashIncoming
        -- Clash send rate only for a real clash / dash-in; point-blank on a lone
        -- ball uses the normal rate (one accepted block is all it needs).
        local clashRate = clashFire or clashIncoming
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
        -- Homing arrival (real miss report #4, 119 ms): a ball aimed at ME that is
        -- TURNING onto me arrives even while its heading still points well off.
        -- The arc above keeps turning at the measured rate (a circle) and said
        -- "misses" (arr=inf) until the ball was 24 studs out at 380 studs/s - one
        -- frame from impact. So for a ball whose target is me, that is turning
        -- toward my side (>= 2 rad/s) and already closing at a quarter of its
        -- speed, also open the window on distance over its closing speed (never
        -- counted slower than half its raw speed). Not for a ball flying straight
        -- past (side-then-snap) or circling me (orbit-then-snap): its turn or its
        -- closing speed is ~0, and firing early on it burns the cooldown before
        -- it snaps in (test_scenarios caught both).
        -- Launch window (real miss report #6, 158 ms): an ability held the ball
        -- still, then shot it at me at ~475 studs/s from ~125 studs, starting
        -- 75 deg off and swinging in. Right after a launch the arc above has
        -- no curve history to go on and called it a miss (arr=inf) until it
        -- was one frame out. For 0.4s after a ball aimed at me goes from slow
        -- (< 40 studs/s) to fast (>= 150), and is closing at a quarter of its
        -- speed, open the window on distance over its closing speed (never
        -- counted slower than half its raw speed). A side-then-snap or orbiting
        -- ball is never slow-then-fast like that, so it is unaffected.
        if velocity < 40 then Clash.lowBall, Clash.lowAt = closestBall, currentTime end
        if not inShieldWindow and ballPos and velocity >= 150 and closingSpeed >= 0.25 * velocity
            and Clash.lowBall == closestBall and currentTime - Clash.lowAt <= 0.4
            and Clash.targetOf(closestBall) == LocalPlayer.Name then
            inShieldWindow = math.max(closestDistance - EFFECTIVE_HIT_RADIUS, 0)
                / math.max(closingSpeed, 0.5 * velocity) <= shieldLead
        end
        if not inShieldWindow and ballPos and velocity > 0 and closingSpeed >= 0.25 * velocity
            and ballOmega >= 2 and Clash.targetOf(closestBall) == LocalPlayer.Name then
            local toMe = humanoidRootPart.Position - ballPos
            local vhat = ballVel / velocity
            if ballAccel:Dot(toMe - vhat * toMe:Dot(vhat)) > 0 then
                inShieldWindow = math.max(closestDistance - EFFECTIVE_HIT_RADIUS, 0)
                    / math.max(closingSpeed, 0.5 * velocity) <= shieldLead
            end
        end
        -- Instant point-blank return (Instant Transmission: "teleports you to
        -- the player you hit the ball to"; or anyone just standing next to me).
        -- When a ball aimed at me is in the block window and an opponent is
        -- within CLOSE_RET studs, my parry sends it straight into them and it
        -- comes back within a frame or two - and if a parry uses the shield up,
        -- only a block landing right after my parry can take it. So it is a
        -- clash already: keep blocks streaming. Decided on TIME, not the ball's
        -- distance: the ball I see is ~0.17s old, still 40+ studs out as the
        -- real one arrives (the dash-in check needs it within 34 - sandbox).
        if not clashIncoming and inShieldWindow and Clash.targetOf(closestBall) == LocalPlayer.Name
            and Clash.nearestOther(humanoidRootPart.Position) <= Clash.CLOSE_RET then
            clashIncoming = true
            alwaysFire, clashRate = true, true
        end
        -- Shield-cover hold (real miss reports #4 and #5). In a long-range rally
        -- the ball we see trails the real one by half a ping plus Roblox's
        -- interpolation, so it still shows "coming at me" after my shield has
        -- already parried it (or is about to). A block fired then lands on a
        -- ball already flying away - just after the parry reset the cooldown
        -- (#5, 110 studs/s) or as my shield ends (#4, 400 studs/s) - and is
        -- ACCEPTED: a new 1s cooldown starts and its shield runs out before the
        -- opponent's return, which then finds every block refused. So when my
        -- last accepted shield's window already contains
        -- the ball's real arrival, nothing fires for it (Auto Spam included);
        -- the next block is left for the return (Return Pre-Shield / the
        -- normal window). Real arrival = what I see, moved forward by half a
        -- ping + VIEW_LAG, at its closing speed. Only while the ball I see is
        -- really coming at me: just after the opponent's return the target is
        -- already me but the ball on screen is still the last pass flying
        -- away, and that is a NEW pass the old shield may not cover (sandbox).
        -- Never in a game clash (blocks are accepted back-to-back there), nor
        -- with another player within PARTNER_NEAR studs (point-blank exchange).
        if Clash.farRally and velocity > 0 and closingSpeed >= 0.5 * velocity
            and Clash.targetOf(closestBall) == LocalPlayer.Name then
            local arrive = currentTime - currentPing / 2000 - Clash.VIEW_LAG
                + math.max(closestDistance - EFFECTIVE_HIT_RADIUS, 0) / closingSpeed
            -- Once my shield has parried it may be used up (report #8), so it
            -- only still counts for a block that would land after it ends -
            -- one landing while it is (said to be) up is either needed or
            -- simply refused. A block landing after it ends for a ball due
            -- before it ends is the report #4 mistake, held either way.
            Clash.covered = arrive >= Clash.shieldFrom - 0.05 and arrive <= Clash.shieldTo - frameLag
                and (not Clash.shieldSpent() or currentTime + currentPing / 2000 >= Clash.shieldTo - frameLag)
        end
        if Clash.covered then
            -- held: the shield that is up already takes this ball
        elseif amTargeted or ((clashActive or fastClashHold) and not Clash.holdAway) or imminentThreat or pointBlank or clashIncoming then
            if (withinRange or willArriveInTime or clashIncoming) and (alwaysFire or (coverable and inShieldWindow)) then executeParry(clashRate) end
            -- Fire block every frame while the shield window is open (or mid-clash
            -- / point-blank), so jitter in the estimate can't leave a gap - the
            -- FIRST block sets a shield that covers impact, later ones are
            -- cooldown-gated by the server and harmless.
            if alwaysFire or ((panicNow or imminentThreat) and coverable and inShieldWindow) then
                if fireBlockRemote(clashRate) then   -- real clash -> faster clash send rate
                    totalBurstBlocks = totalBurstBlocks + 1
                end
            end
        end
        -- Miss Recorder: one compact row per frame (see Clash.rec).
        Clash.rec(currentTime, closestDistance, velocity, closingSpeed, currentTimeToImpact,
            surfaceArriveTime, shieldLead, withinRange, coverable, inShieldWindow, panicNow,
            imminentThreat, alwaysFire, amTargeted, Clash.covered)
    end

    updateVisualSphere(humanoidRootPart)
    runAutoSpam(amTargeted, clashDetected, realClash, hudTick,
        (currentTime - Clash.meAt) <= Clash.PART_WINDOW)
end)

-- Miss Recorder: a ball aimed at me just hit me if I die (or lose health)
-- while a ball targeted me in the last 2s.
do
    -- Fully guarded: the recorder is diagnostics only and must never be able
    -- to break loading or parrying (e.g. a humanoid without HealthChanged).
    local function watchHumanoid(character)
        pcall(function()
            local hum = character and character:WaitForChild("Humanoid", 5)
            if not hum or not hum.HealthChanged then return end
            local last = hum.Health
            track(hum.HealthChanged:Connect(function(h)
                pcall(function()
                    if type(h) == "number" and type(last) == "number" and h < last - 1 then
                        Clash.onMiss(h <= 0 and "died" or "took damage")
                    end
                end)
                last = h
            end))
        end)
    end
    if LocalPlayer.Character then task.spawn(watchHumanoid, LocalPlayer.Character) end
    track(LocalPlayer.CharacterAdded:Connect(function(c) task.spawn(watchHumanoid, c) end))
end

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
    if Clash.HL.fxRestore then pcall(Clash.HL.fxRestore) end
    -- Hand the game's server auto parry back to "off" if we turned it on.
    if GameAP.active then
        pcall(function()
            local svc = require(ReplicatedStorage.Framework):Fetch("AutoParryService")
            task.spawn(function() pcall(function() svc.SetEnabled:Invoke(false) end) end)
        end)
        GameAP.active = false
    end
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
            genv.AnimeBallHubHitLog = nil
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
