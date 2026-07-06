-- Anime Ball v2 - Auto Parry / Auto Spam
-- Requires: ReplicatedStorage.Framework.RemoteFunction ("SwordService","Block",{-0.759547233581543})
-- Requires: workspace.Balls (folder of ball parts/models) and workspace[Player.Name].Highlight

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local Stats = game:GetService("Stats")
local LocalPlayer = Players.LocalPlayer

-- Load WindUI from OUR OWN repo, pinned to a specific commit (not a live
-- third-party branch). This closes the only real exposure vector: the script
-- itself sends nothing out, but it does run whatever UI library it downloads,
-- so we self-host a vendored copy at an immutable commit. Nobody but us can
-- swap this code out from under you, and the exact bytes never change.
local WINDUI_URL = "https://raw.githubusercontent.com/robloxscripter6245366542/roblox-lua-obscator/ef387b14984464482b63eb50241f34a8dfce651f/assets/lunarhub.lua"
local okWindUI, WindUI = pcall(function()
    return loadstring(game:HttpGet(WINDUI_URL))()
end)
if not okWindUI or type(WindUI) ~= "table" then
    return warn("[AnimeBall] UI library failed to load: " .. tostring(WindUI))
end

-- "Crimson Clash" color theme
local AccentRed = Color3.fromHex("#DC143C") -- true crimson
local Gold = Color3.fromHex("#FFC107")
local Emerald = Color3.fromHex("#34D399")
local Amber = Color3.fromHex("#FFD84D")

-- ============================================
-- AUTO PARRY CONFIGURATION
-- ============================================

local MIN_DISTANCE = 1.5
local MAX_DISTANCE = 100
local UPDATE_INTERVAL = 0 -- run every Heartbeat frame
local PARRY_COOLDOWN = 0.3
local HIGH_SPEED_THRESHOLD = 300
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

-- Anti-curve: the ball's velocity vector alone only predicts a straight
-- line, which misses curving/homing balls entirely. We also track the
-- ball's acceleration (rate of change of velocity between frames) and
-- simulate the resulting curved arc forward, instead of assuming it keeps
-- going in whatever direction it's pointed right now.
local antiCurveEnabled = true
local ACCEL_SMOOTHING = 0.35      -- 0-1, higher = react faster to new curvature, lower = smoother/less jittery
local CURVE_SIM_STEPS = 20        -- samples taken along the predicted arc, up to predictionHorizon seconds out
local MAX_CURVE_ACCEL = 400       -- studs/s^2 cap; a parry flips ball velocity in one frame, which would otherwise read as a huge fake curve
local currentCurveAccel = 0       -- last measured curve (lateral acceleration) magnitude, studs/s^2

-- Panic Burst: the single executeParry() + 0.3s cooldown is exactly what
-- loses to super-fast/curving balls - one block fires (sometimes early, on
-- prediction), and if it whiffs the cooldown eats the real parry while the
-- ball crosses the last gap in under 0.2s. When predicted time-to-impact
-- drops below the panic window, fire block every frame (bypassing the
-- cooldown) until the ball is deflected - same spam the game already
-- tolerates from Auto Spam.
local panicBurstEnabled = true
local PANIC_TTI = 0.35            -- seconds; time-to-impact below this triggers per-frame block spam
local totalBurstBlocks = 0

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
}

-- Keep-moving guard: firing block used to yield the main thread on every
-- parry (a full ping round-trip stall = felt movement stutter); that's fixed
-- by firing block in its own thread (fireBlockRemote). This table additionally
-- restores WalkSpeed if the game zeroes it while blocking, so a block can
-- never leave you rooted. Bundled so a dedicated connection captures one
-- upvalue. cachedSpeed learns the game's real walk speed (last non-zero seen).
local Move = { keep = true, cachedSpeed = 16 }

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

-- Previous background/element colors were near-black (#120306, #240A0E) with
-- only a faint red tinge, so behind glass transparency the panel just read
-- as plain dark glass instead of crimson. Bumped to an actual visible
-- crimson-wine hue so the glass itself carries the color, not just the
-- small accent elements (toggles/sliders).
WindUI:AddTheme({
    Name = "CrimsonClash",
    Accent = AccentRed,
    Dialog = Color3.fromHex("#3D0F19"),
    Text = Color3.fromHex("#FFE9EE"),
    Placeholder = Color3.fromHex("#D98FA0"),
    Background = Color3.fromHex("#2B0A12"),
    Button = Color3.fromHex("#521624"),
    Icon = Color3.fromHex("#FFC4D1"),
    Toggle = AccentRed,
    Slider = Color3.fromHex("#FF4D5E"),
    Checkbox = AccentRed,
    ElementBackground = Color3.fromHex("#451420"),
    ElementBackgroundTransparency = 0.35,
})
WindUI:SetTheme("CrimsonClash")

local Window = WindUI:CreateWindow({
    Title = "Anime Ball v2 | Crimson Clash",
    Icon = "sword",
    Folder = "AnimeBallComplete",
    ToggleKey = Enum.KeyCode.LeftControl,
    Theme = "CrimsonClash",

    Acrylic = true,
    Transparent = true,
    HidePanelBackground = true,
    Radius = 20,
})

-- Re-applied after CreateWindow as a safety net in case window construction
-- resets to a built-in default theme.
WindUI:SetTheme("CrimsonClash")
Window:SetBackgroundTransparency(0.35)

local Tabs = {
    Main = Window:Tab({ Title = "Main", Icon = "home" }),
    Parry = Window:Tab({ Title = "Auto Parry", Icon = "shield" }),
    Spam = Window:Tab({ Title = "Auto Spam", Icon = "zap" }),
    Visuals = Window:Tab({ Title = "Visuals", Icon = "eye" }),
    Stats = Window:Tab({ Title = "Statistics", Icon = "bar-chart" })
}

-- Live status paragraph handles, bundled into one table so the Heartbeat
-- closure captures a single upvalue for all of them (Lua 5.1's 60-upvalue
-- function limit).
local HUD = {}

local FeatureSection = Tabs.Main:Section({ Title = "Feature Control" })

FeatureSection:Toggle({
    Flag = "AutoParryMain",
    Title = "Auto Parry",
    Desc = "Itself Parry Ball",
    Value = true,
    Callback = function(Value)
        autoParryEnabled = Value
        WindUI:Notify({
            Title = "Auto Parry",
            Content = Value and "Enabled" or "Disabled",
            Duration = 3
        })
    end
})

FeatureSection:Toggle({
    Flag = "AutoSpamMain",
    Title = "Auto Spam (Beta)",
    Desc = "Distance near player",
    Value = true,
    Callback = function(Value)
        autoSpamEnabled = Value
        WindUI:Notify({
            Title = "Auto Spam",
            Content = Value and "Enabled" or "Disabled",
            Duration = 3
        })
    end
})

FeatureSection:Toggle({
    Flag = "KeepMoving",
    Title = "Keep Moving While Blocking",
    Desc = "Restore your walk speed if a block ever roots you - blocking/parry never interrupts movement",
    Value = true,
    Callback = function(Value)
        Move.keep = Value
    end
})

local QuickStatsSection = Tabs.Main:Section({ Title = "Quick Stats" })
HUD.QuickStats = QuickStatsSection:Paragraph({
    Title = "Performance",
    Desc = "Loading..."
})

local ParryStatusSection = Tabs.Parry:Section({ Title = "Auto Parry Status" })

HUD.ParryStatus = ParryStatusSection:Paragraph({
    Title = "Detection Status",
    Desc = "Initializing..."
})

HUD.ParryDistance = ParryStatusSection:Paragraph({
    Title = "Distance Info",
    Desc = "Waiting for data..."
})

local PingSection = Tabs.Parry:Section({ Title = "Ping Compensation & Future Prediction" })

PingSection:Toggle({
    Flag = "PingCompEnabled",
    Title = "Ping Compensation",
    Desc = "Parry earlier when ping is high",
    Value = true,
    Callback = function(Value)
        pingCompEnabled = Value
        WindUI:Notify({
            Title = "Ping Compensation",
            Content = Value and "Enabled" or "Disabled",
            Duration = 3
        })
    end
})

PingSection:Toggle({
    Flag = "PingAutoEnabled",
    Title = "Auto (adjust by your ping)",
    Desc = "Set the strength automatically from your live ping - more comp the higher it is. Off = use the manual slider below",
    Value = true,
    Callback = function(Value)
        pingAutoEnabled = Value
        WindUI:Notify({
            Title = "Auto Ping Compensation",
            Content = Value and "ON - tuning to your ping" or "OFF - using manual slider",
            Duration = 3
        })
    end
})

PingSection:Slider({
    Flag = "PingMultiplier",
    Title = "Compensation Strength (manual)",
    Desc = "Only used when Auto is OFF. 1.0 = full ping, higher = parry even earlier",
    Step = 0.05,
    Value = { Min = 0, Max = 3, Default = 1.0 },
    Callback = function(Value)
        pingMultiplier = Value
    end
})

PingSection:Slider({
    Flag = "PredictionHorizon",
    Title = "Prediction Horizon (seconds)",
    Desc = "Max look-ahead into the future used for early parry (0-5s)",
    Step = 0.1,
    Value = { Min = 0, Max = 5, Default = 1.5 },
    Callback = function(Value)
        predictionHorizon = Value
    end
})

PingSection:Slider({
    Flag = "MaxPingComp",
    Title = "Max Extra Range (studs)",
    Desc = "Cap on extra detection studs from ping",
    Step = 1,
    Value = { Min = 0, Max = 150, Default = 60 },
    Callback = function(Value)
        MAX_PING_COMP = Value
    end
})

PingSection:Toggle({
    Flag = "AntiCurveEnabled",
    Title = "Anti-Curve Prediction",
    Desc = "Simulate the ball's actual curved arc instead of a straight line",
    Value = true,
    Callback = function(Value)
        antiCurveEnabled = Value
    end
})

PingSection:Slider({
    Flag = "AccelSmoothing",
    Title = "Curve Reactivity",
    Desc = "Higher = react to new curves faster but jitter more",
    Step = 0.05,
    Value = { Min = 0.05, Max = 1, Default = 0.35 },
    Callback = function(Value)
        ACCEL_SMOOTHING = Value
    end
})

PingSection:Toggle({
    Flag = "PanicBurst",
    Title = "Panic Burst",
    Desc = "Spam block every frame when impact is imminent - catches super fast balls",
    Value = true,
    Callback = function(Value)
        panicBurstEnabled = Value
    end
})

PingSection:Slider({
    Flag = "PanicWindow",
    Title = "Panic Window (seconds)",
    Desc = "Time-to-impact below this fires block every frame",
    Step = 0.05,
    Value = { Min = 0.1, Max = 1, Default = 0.35 },
    Callback = function(Value)
        PANIC_TTI = Value
    end
})

HUD.PingInfo = PingSection:Paragraph({
    Title = "Ping Status",
    Desc = "Measuring..."
})

local SpamStatusSection = Tabs.Spam:Section({ Title = "Auto Spam Status" })

SpamStatusSection:Toggle({
    Flag = "ClashDetect",
    Title = "Smart Clash Detection",
    Desc = "Only spam during a real clash (ball rapidly bouncing back and forth) - not just when standing near someone",
    Value = true,
    Callback = function(Value)
        Clash.enabled = Value
    end
})

HUD.SpamStatus = SpamStatusSection:Paragraph({
    Title = "System Status",
    Desc = "Initializing..."
})

HUD.SpamConditions = SpamStatusSection:Paragraph({
    Title = "Detection Status",
    Desc = "Checking conditions..."
})

local LiveDetectionSection = Tabs.Spam:Section({ Title = "Live Detection" })

HUD.PlayerDetection = LiveDetectionSection:Paragraph({
    Title = "Player Detection",
    Desc = "Scanning..."
})

HUD.BallDetection = LiveDetectionSection:Paragraph({
    Title = "Ball Detection",
    Desc = "Scanning..."
})

HUD.HighlightDetection = LiveDetectionSection:Paragraph({
    Title = "Highlight Detection",
    Desc = "Checking..."
})

-- ============================================
-- VISUALS TAB
-- ============================================

local VisualIndicatorsSection = Tabs.Visuals:Section({ Title = "Visual Indicators" })

VisualIndicatorsSection:Toggle({
    Flag = "VisualSphere",
    Title = "Show Parry Detection Sphere",
    Desc = "Display the auto parry detection range",
    Value = true,
    Callback = function(Value)
        showVisualSphere = Value
        if not Value and visualSphere then
            visualSphere.Transparency = 1
        end
    end
})

VisualIndicatorsSection:Toggle({
    Flag = "PlayerDetector",
    Title = "Show Spam Detection Sphere",
    Desc = "Display 17 stud spheres around players",
    Value = true,
    Callback = function(Value)
        showPlayerDetectors = Value
        if not Value then
            clearPlayerDetectorSpheres()
        else
            createPlayerDetectorSpheres()
        end
    end
})

VisualIndicatorsSection:Toggle({
    Flag = "SpeedLabel",
    Title = "Show Ball Speed Labels",
    Desc = "Display velocity above balls",
    Value = true,
    Callback = function(Value)
        showSpeedLabel = Value
        if not Value then
            for _, cache in pairs(billboardCache) do
                if cache.Billboard then
                    cache.Billboard:Destroy()
                end
            end
            billboardCache = {}
        end
    end
})

VisualIndicatorsSection:Paragraph({
    Title = "Color Guide",
    Desc = "Crimson = Normal Mode\nGold = High Speed Mode\nEmerald = Player Detectors\nAmber = Ball Velocity"
})

-- ============================================
-- STATS TAB
-- ============================================

local PerfStatsSection = Tabs.Stats:Section({ Title = "Performance Statistics" })

HUD.ParryStats = PerfStatsSection:Paragraph({
    Title = "Auto Parry Stats",
    Desc = "Waiting for data..."
})

HUD.SpamStats = PerfStatsSection:Paragraph({
    Title = "Auto Spam Stats",
    Desc = "Waiting for data..."
})

HUD.LiveStats = PerfStatsSection:Paragraph({
    Title = "Live Monitoring",
    Desc = "Monitoring..."
})

PerfStatsSection:Button({
    Title = "Reset All Statistics",
    Desc = "Reset both parry and spam counters",
    Callback = function()
        totalParries = 0
        highSpeedParries = 0
        totalBurstBlocks = 0
        totalSpams = 0
        spamDuration = 0
        WindUI:Notify({
            Title = "Stats Reset",
            Content = "All statistics have been reset",
            Duration = 3
        })
    end
})

-- ============================================
-- CONFIG
-- ============================================

local ConfigSection = Tabs.Stats:Section({ Title = "Config" })
local CONFIG_NAME = "default"

ConfigSection:Button({
    Title = "Save Config",
    Desc = "Save all current settings",
    Callback = function()
        local cfg = Window.ConfigManager:Config(CONFIG_NAME)
        if cfg:Save() then
            WindUI:Notify({ Title = "Config Saved", Content = "Saved to '" .. CONFIG_NAME .. "'", Duration = 3 })
        end
    end
})

ConfigSection:Button({
    Title = "Load Config",
    Desc = "Restore saved settings",
    Callback = function()
        local cfg = Window.ConfigManager:CreateConfig(CONFIG_NAME)
        if cfg:Load() then
            WindUI:Notify({ Title = "Config Loaded", Content = "Loaded '" .. CONFIG_NAME .. "'", Duration = 3 })
        end
    end
})

-- Auto-save: load saved settings on startup, then persist them in the
-- background so any change you make is remembered without pressing Save.
task.spawn(function()
    pcall(function() Window.ConfigManager:CreateConfig(CONFIG_NAME):Load() end)
    while task.wait(3) do
        pcall(function() Window.ConfigManager:Config(CONFIG_NAME):Save() end)
    end
end)

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
    visualSphere.Anchored = true
    visualSphere.Parent = workspace
end

-- Single source of truth for building/refreshing a player detector sphere,
-- used by both the initial-create pass and the per-frame update pass
-- (previously this logic was duplicated in two places).
createOrUpdatePlayerDetectorSphere = function(player)
    if not showPlayerDetectors then return end
    local hrp = getPlayerHRP(player)
    if not hrp then return end

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
    return ball:FindFirstChildWhichIsA("BasePart", true)
end

local function getBallPosition(ball)
    local part = getBallPart(ball)
    return part and part.Position or nil
end

local function getBallVelocityVector(ball)
    local part = getBallPart(ball)
    return part and part.AssemblyLinearVelocity or Vector3.new()
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
    end
    ballMotionCache[ball] = {vel = vel, accel = accel, time = now}
    return accel
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
local function predictCurvedImpact(pos, vel, accel, targetPos, targetVel, targetGravity, meleeRange, maxLookahead, steps)
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
    for i = 1, steps do
        local t = i * dt
        local predictedPos = pos + vel * t + accel * (0.5 * t * t)
        if (predictedPos - targetPos).Magnitude <= meleeRange then
            return true, t
        end
        local drop = Vector3.new(0, -0.5 * targetGravity * t * t, 0)
        local fullMovePos = targetPos + targetVel * t + drop
        if (predictedPos - fullMovePos).Magnitude <= meleeRange then
            return true, t
        end
        local halfMovePos = targetPos + targetVel * (0.5 * t) + drop
        if (predictedPos - halfMovePos).Magnitude <= meleeRange then
            return true, t
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
    folder.ChildAdded:Connect(function(child)
        if isRealBall(child) then ballsCache[child] = true end
    end)
    folder.ChildRemoved:Connect(function(child)
        ballsCache[child] = nil
        ballMotionCache[child] = nil
        -- Also drop (and destroy) the speed-label billboard for this ball,
        -- otherwise billboardCache grows without bound as balls spawn and
        -- despawn over a long session.
        local cached = billboardCache[child]
        if cached and cached.Billboard then cached.Billboard:Destroy() end
        billboardCache[child] = nil
    end)
end

-- Lazily drop balls whose instance has left the game tree without the
-- folder's ChildRemoved firing (e.g. the whole Balls folder was reparented
-- rather than destroyed) - otherwise dead balls linger in the cache forever
-- and corrupt closest-ball selection.
local function purgeDeadBall(ball)
    ballsCache[ball] = nil
    ballMotionCache[ball] = nil
    billboardCache[ball] = nil
end

local function bindHighlightFolder(folder)
    hasHighlightCache = folder:FindFirstChild("Highlight") ~= nil
    folder.ChildAdded:Connect(function(child)
        if child.Name == "Highlight" then hasHighlightCache = true end
    end)
    folder.ChildRemoved:Connect(function(child)
        if child.Name == "Highlight" then hasHighlightCache = false end
    end)
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
    player.CharacterAdded:Connect(function(character) bindCharacter(player, character) end)
    player.CharacterRemoving:Connect(function() playerHRPCache[player] = nil end)
end

-- Calls onFound immediately if `name` already exists under workspace,
-- otherwise hooks ChildAdded and calls it the instant it appears.
local function watchForNamedChild(name, onFound)
    local existing = workspace:FindFirstChild(name)
    if existing then onFound(existing) end
    workspace.ChildAdded:Connect(function(child)
        if child.Name == name then onFound(child) end
    end)
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
    local normalizedVelocity = math.clamp(velocity / 100, 0, 1)
    local distance = MIN_DISTANCE + (MAX_DISTANCE - MIN_DISTANCE) * normalizedVelocity
    distance = math.floor(distance * 2 + 0.5) / 2
    return math.clamp(distance, MIN_DISTANCE, MAX_DISTANCE)
end

-- InvokeServer on a RemoteFunction YIELDS until the server replies. Fired
-- inline from the Heartbeat handler, that stalls everything after it in the
-- same frame (status UI, the whole Auto Spam section) for a full round-trip
-- - the worse your ping, the longer the stall. Fire-and-forget in a fresh
-- thread so the handler never blocks on the network.
local function fireBlockRemote()
    task.spawn(function()
        pcall(function()
            ReplicatedStorage.Framework.RemoteFunction:InvokeServer("SwordService", "Block", {-0.759547233581543})
        end)
    end)
end

local function executeParry()
    local currentTime = tick()
    if currentTime - lastParryTime < PARRY_COOLDOWN then return end
    lastParryTime = currentTime
    totalParries = totalParries + 1
    if isHighSpeedMode then highSpeedParries = highSpeedParries + 1 end
    fireBlockRemote()
end

local function createSpeedLabel(ball)
    if not showSpeedLabel then return {Billboard = nil, Label = nil} end
    if billboardCache[ball] then return billboardCache[ball] end
    local billboard = Instance.new("BillboardGui")
    billboard.Name = "SpeedLabel"
    billboard.AlwaysOnTop = true
    billboard.Size = UDim2.new(0, 100, 0, 40)
    billboard.StudsOffset = Vector3.new(0, 3, 0)
    billboard.Parent = ball
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
    local closestBall = nil
    local closestDistance = math.huge
    local minThreatTTI = math.huge
    local targetedByAny = false
    local myName = LocalPlayer.Name
    for ball in pairs(ballsCache) do
        if not ball.Parent then
            purgeDeadBall(ball)
        else
            local ballPos = getBallPosition(ball)
            if ballPos then
                local distance = (humanoidRootPart.Position - ballPos).Magnitude
                if distance < closestDistance then
                    closestDistance = distance
                    closestBall = ball
                end
                -- Targeting must consider EVERY ball, not just the closest:
                -- the ball assigned to me may not be the nearest one.
                local target = ball:GetAttribute("Target")
                if target == myName then targetedByAny = true end
                -- Only balls aimed at me (or not yet assigned) can threaten
                -- me; a ball assigned to another player won't hit me, so it
                -- must not arm my panic burst.
                if target == myName or target == nil then
                    local speed = getBallVelocityVector(ball).Magnitude
                    if speed > 0 then
                        local tti = distance / speed
                        if tti < minThreatTTI then minThreatTTI = tti end
                    end
                end
            end
        end
    end
    return closestBall, closestDistance, minThreatTTI, targetedByAny
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

local function executeSpam()
    fireBlockRemote()
    totalSpams = totalSpams + 1
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
        HUD.QuickStats:SetDesc(string.format("- Total Parries: %d (High Speed: %d)\n- Total Spams: %d\n- Auto Parry: %s\n- Auto Spam: %s",
            totalParries, highSpeedParries, totalSpams,
            autoParryEnabled and "ON" or "OFF",
            autoSpamEnabled and "ON" or "OFF"))

        HUD.ParryStats:SetDesc(string.format("- Total Parries: %d\n- High Speed Parries: %d\n- Burst Blocks: %d\n- High Speed Rate: %.1f%%\n- Current Mode: %s",
            totalParries, highSpeedParries, totalBurstBlocks,
            totalParries > 0 and (highSpeedParries / totalParries * 100) or 0,
            isHighSpeedMode and "MAX SPEED" or "Normal"))

        local spamsPerSecond = 0
        if spamStarted and lastSpamStartTime > 0 then
            local currentDuration = tick() - lastSpamStartTime
            if currentDuration > 0 then spamsPerSecond = totalSpams / (spamDuration + currentDuration) end
        elseif spamDuration > 0 then
            spamsPerSecond = totalSpams / spamDuration
        end

        HUD.SpamStats:SetDesc(string.format("- Total Spams: %d\n- Total Duration: %.1fs\n- Average Rate: %.1f spam/s\n- Status: %s",
            totalSpams, spamDuration, spamsPerSecond, spamStarted and "ACTIVE" or "INACTIVE"))

        local livePing = getPing()
        HUD.PingInfo:SetDesc(string.format("- Current Ping: %.0f ms (smoothed %.0f)\n- Compensation: %s\n- Mode: %s\n- Strength: %.2fx%s\n- Prediction Horizon: %.2fs\n- Last Extra Range: +%.1f studs\n- Last Time-To-Impact: %s",
            livePing, smoothedPing,
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
Players.PlayerAdded:Connect(bindPlayer)
Players.PlayerRemoving:Connect(function(player) playerHRPCache[player] = nil end)
watchForNamedChild("Balls", trackBallsFolder)
watchForNamedChild(LocalPlayer.Name, bindHighlightFolder)

createVisualSphere()
createPlayerDetectorSpheres()

local lastUpdateTime = 0
RunService.Heartbeat:Connect(function()
    local currentTime = tick()
    if currentTime - lastUpdateTime < UPDATE_INTERVAL then return end
    lastUpdateTime = currentTime

    local humanoidRootPart = getPlayerHRP(LocalPlayer)
    if not humanoidRootPart then return end

    -- Keep the spam-detector spheres tracking players regardless of parry
    -- state - previously this only ran inside the parry-with-ball branch,
    -- so the spheres froze in place whenever no ball existed (between
    -- rounds) or Auto Parry was toggled off.
    updatePlayerDetectorSpheres()

    local hasHighlight = hasPlayerHighlight()
    local closestBall, closestDistance, minThreatTTI, targetedByAny = findClosestBall(humanoidRootPart)

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
    local clashDetected = #Clash.flipTimes >= Clash.MIN_FLIPS

    if autoParryEnabled and closestBall then
        local ballInDetectorRange = isBallInPlayerRange(closestBall, PLAYER_DETECTOR_DISTANCE)
        local velocity = ballVel and ballVel.Magnitude or 0
        local closingSpeed = ballPos and getClosingSpeed(ballPos, ballVel, humanoidRootPart.Position) or 0
        local ballAccel = ballPos and updateBallCurvature(closestBall, ballVel, currentTime) or Vector3.new()
        currentCurveAccel = ballAccel.Magnitude

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
                        currentParryDistance = math.min(currentParryDistance + 0.4, targetParryDistance)
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
        currentTimeToImpact = math.huge
        if ballPos then
            local lookahead = math.max(currentRequiredLead, panicBurstEnabled and PANIC_TTI or 0)
            if antiCurveEnabled and lookahead > 0 then
                local playerVel = humanoidRootPart.AssemblyLinearVelocity
                -- Mid-jump the player follows a gravity arc, not a straight
                -- line up - project the fall only while airborne (a grounded
                -- humanoid counteracts gravity).
                local character = humanoidRootPart.Parent
                local humanoid = character and character:FindFirstChildOfClass("Humanoid")
                local airborne = humanoid ~= nil and humanoid.FloorMaterial == Enum.Material.Air
                local playerGravity = airborne and workspace.Gravity or 0
                local arrives, arriveTime = predictCurvedImpact(
                    ballPos, ballVel, ballAccel, humanoidRootPart.Position, playerVel, playerGravity,
                    currentParryDistance, lookahead)
                if arrives then
                    currentTimeToImpact = arriveTime
                elseif closingSpeed > 0 then
                    currentTimeToImpact = closestDistance / closingSpeed
                end
                willArriveInTime = pingCompEnabled and arrives and arriveTime <= currentRequiredLead
            elseif closingSpeed > 0 then
                currentTimeToImpact = closestDistance / closingSpeed
                willArriveInTime = pingCompEnabled and currentRequiredLead > 0
                    and ((closestDistance - currentParryDistance) / closingSpeed) <= currentRequiredLead
            end
            -- Worst-case bound: a fast-curving ball can turn fully onto you
            -- at any moment, so the estimated time-to-impact (which trusts
            -- the ball's current direction) is not enough on its own. If the
            -- ball's raw speed could carry it to you within the panic window
            -- - regardless of where it's pointed right now - and you're the
            -- highlighted target, treat impact as imminent. This is what
            -- makes the burst immune to both hard curves and the player's
            -- own jump/dash movement scrambling the direction estimates.
            local worstCaseTTI = velocity > 0 and (closestDistance / velocity) or math.huge
            -- withinRange is included explicitly: a ball already inside the
            -- parry radius is always an imminent threat, even when its
            -- time-to-impact estimate is unusable (hovering pre-serve at
            -- zero velocity, orbiting with no closing speed, or Anti-Curve
            -- disabled). Burst-while-inside beats one parry per 0.3s.
            -- minThreatTTI covers ALL balls, so a second, faster ball that
            -- isn't the closest still arms the burst.
            panicNow = panicBurstEnabled
                and (withinRange or currentTimeToImpact <= PANIC_TTI
                    or worstCaseTTI <= PANIC_TTI or (minThreatTTI or math.huge) <= PANIC_TTI)
        end

        HUD.ParryStatus:SetDesc(string.format("Status: %s", autoParryEnabled and "ACTIVE" or "DISABLED"))
        HUD.ParryDistance:SetDesc(string.format("- Detection Range: %.1f studs\n- Ping Comp: +%.1f studs (%.0f ms, lead %.2fs)\n- Effective Range: %.1f studs\n- Ball Speed: %.1f studs/s (closing: %.1f)\n- Curve: %.1f studs/s^2 (%s)\n- Distance to Ball: %.1f studs\n- Time-To-Impact: %s\n- Panic Burst: %s\n- Mode: %s\n- Frozen: %s",
            currentParryDistance, pingComp, currentPing, currentRequiredLead, effectiveParryDistance, velocity, closingSpeed,
            currentCurveAccel, antiCurveEnabled and "ON" or "OFF", closestDistance,
            currentTimeToImpact < math.huge and string.format("%.2fs", currentTimeToImpact) or "n/a",
            panicNow and "FIRING" or (panicBurstEnabled and "armed" or "off"),
            isHighSpeedMode and "MAX SPEED" or "Normal",
            isAutoParryFrozen and "Yes" or "No"))

        if showSpeedLabel then
            local speedLabel = createSpeedLabel(closestBall)
            if speedLabel.Label then
                speedLabel.Label.Text = string.format("%.1f%s", velocity, isHighSpeedMode and " [FAST]" or "")
            end
        end

        if amTargeted then
            if withinRange or willArriveInTime then executeParry() end
            -- Impact imminent: keep firing block every frame (no cooldown)
            -- until the ball is deflected, so a single early/whiffed parry
            -- can never leave a super-fast or hard-curving ball unblocked.
            if panicNow then
                fireBlockRemote()
                totalBurstBlocks = totalBurstBlocks + 1
            end
        end
    end

    if visualSphere and showVisualSphere then
        if not visualSphere.Parent then createVisualSphere() end
        visualSphere.Size = Vector3.new(currentParryDistance * 2, currentParryDistance * 2, currentParryDistance * 2)
        visualSphere.Position = humanoidRootPart.Position
        visualSphere.Transparency = 0.7
        if isHighSpeedMode then
            visualSphere.Color = Gold
        else
            visualSphere.Color = AccentRed
        end
    elseif visualSphere then
        visualSphere.Transparency = 1
    end

    if not autoSpamEnabled then
        if spamStarted then
            spamDuration = spamDuration + (tick() - lastSpamStartTime)
            spamStarted = false
        end
        HUD.SpamStatus:SetDesc("AUTO SPAM: DISABLED")
        HUD.SpamConditions:SetDesc("Auto Spam is turned off")
        return
    end

    local playerInRange, closestPlayer, playerDistance = checkPlayerDistance()
    local ballInRange, ballDistance = checkBallDistance()

    if playerInRange and closestPlayer then
        HUD.PlayerDetection:SetDesc(string.format("Player: %s\nDistance: %.1f studs", closestPlayer.Name, playerDistance))
    else
        HUD.PlayerDetection:SetDesc("No players in range")
    end

    if ballInRange then
        HUD.BallDetection:SetDesc(string.format("Ball Found\nDistance: %.1f studs", ballDistance))
    else
        HUD.BallDetection:SetDesc(string.format("No ball in range\nClosest: %.1f studs", ballDistance))
    end

    HUD.HighlightDetection:SetDesc(amTargeted and "Targeted (you)" or "Not targeted")

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
        HUD.SpamStatus:SetDesc("AUTO SPAM: ACTIVE\nSpamming block!")
        HUD.SpamConditions:SetDesc(string.format("Clash: %s | Ball | Highlight\nClashing - all in!",
            Clash.enabled and (clashDetected and "LIVE" or "holding") or "off"))
        HUD.LiveStats:SetDesc(string.format("- Parry Status: %s\n- Spam Status: SPAMMING\n- Clash: %s (%d flips/%.1fs)\n- Player: %s (%.1f studs)\n- Ball Distance: %.1f studs\n- Total Spams: %d",
            autoParryEnabled and "Active" or "Disabled",
            clashDetected and "LIVE" or "cooling", #Clash.flipTimes, Clash.WINDOW,
            closestPlayer and closestPlayer.Name or "Unknown", playerDistance, ballDistance, totalSpams))
        executeSpam()
    else
        HUD.SpamStatus:SetDesc("AUTO SPAM: INACTIVE\nWaiting for a clash...")
        local clashText = Clash.enabled and (clashDetected and "[OK] Clash" or "[--] Clash") or "[off] Clash"
        local conditionText = clashText .. " | " .. (ballInRange and "[OK] Ball" or "[--] Ball") .. " | " .. (amTargeted and "[OK] Targeted" or "[--] Targeted") .. "\nWaiting for a real clash..."
        HUD.SpamConditions:SetDesc(conditionText)
        HUD.LiveStats:SetDesc(string.format("- Parry Status: %s\n- Spam Status: WAITING\n- Clash Detected: %s (%d flips)\n- Ball in Range: %s\n- Highlight: %s",
            autoParryEnabled and "Active" or "Disabled",
            clashDetected and "Yes" or "No", #Clash.flipTimes,
            ballInRange and "Yes" or "No", amTargeted and "Yes" or "No"))
    end
end)

LocalPlayer.CharacterRemoving:Connect(function()
    if visualSphere then visualSphere:Destroy() visualSphere = nil end
    clearPlayerDetectorSpheres()
    isHighSpeedMode = false
    -- The highlight lives under the (now removed) character's workspace
    -- entry; without this reset the cache holds its last value until the
    -- respawned character rebinds, letting a phantom highlight gate parries
    -- while dead.
    hasHighlightCache = false
end)

-- Movement guard, in its own connection so it doesn't add to the main
-- Heartbeat closure's upvalue count (Lua 5.1's 60-per-function limit). Learns
-- the game's real walk speed from the last non-zero value seen, and restores
-- it whenever a block roots the character - so blocking never interrupts
-- movement. Toggle: Main tab > Keep Moving While Blocking.
RunService.Heartbeat:Connect(function()
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

WindUI:Notify({
    Title = "Anime Ball Loaded!",
    Content = "Auto Parry + Ping Compensation ready",
    Duration = 5
})
