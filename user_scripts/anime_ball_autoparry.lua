-- Anime Ball v2 - Auto Parry / Auto Spam
-- Requires: ReplicatedStorage.Framework.RemoteFunction ("SwordService","Block",{-0.759547233581543})
-- Requires: workspace.Balls (folder of ball parts/models) and workspace[Player.Name].Highlight

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local Stats = game:GetService("Stats")
local LocalPlayer = Players.LocalPlayer

-- Load Fluent UI Library
local Fluent = loadstring(game:HttpGet("https://github.com/dawid-scripts/Fluent/releases/latest/download/main.lua"))()
local SaveManager = loadstring(game:HttpGet("https://raw.githubusercontent.com/dawid-scripts/Fluent/master/Addons/SaveManager.lua"))()
local InterfaceManager = loadstring(game:HttpGet("https://raw.githubusercontent.com/dawid-scripts/Fluent/master/Addons/InterfaceManager.lua"))()

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
local pingMultiplier = 1.0        -- 1.0 = compensate the full ping; raise for extra safety margin
local MAX_PING_COMP = 60          -- cap on extra studs so it never over-extends absurdly
local predictionHorizon = 1.5     -- max seconds of look-ahead allowed (0 - 5s)
local currentPing = 0             -- last measured round-trip ping in ms
local currentPingComp = 0         -- last computed extra studs of detection range
local currentTimeToImpact = math.huge
local currentRequiredLead = 0

-- Anti-curve: the ball's velocity vector alone only predicts a straight
-- line, which misses curving/homing balls entirely. We also track the
-- ball's acceleration (rate of change of velocity between frames) and
-- simulate the resulting curved arc forward, instead of assuming it keeps
-- going in whatever direction it's pointed right now.
local antiCurveEnabled = true
local ACCEL_SMOOTHING = 0.35      -- 0-1, higher = react faster to new curvature, lower = smoother/less jittery
local CURVE_SIM_STEPS = 20        -- samples taken along the predicted arc, up to predictionHorizon seconds out
local currentCurveAccel = 0       -- last measured curve (lateral acceleration) magnitude, studs/s^2

-- ============================================
-- AUTO SPAM CONFIGURATION
-- ============================================

local SPAM_DETECTION_DISTANCE = 34.3
-- Fires every single Heartbeat frame, uncapped, for as long as the clash
-- conditions (player + ball + Highlight) hold - no duration limit, so a
-- clash can be held indefinitely (an hour+) without the loop giving up.
local autoSpamEnabled = true
local spamStarted = false
local totalSpams = 0
local spamDuration = 0
local lastSpamStartTime = 0

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

local Window = Fluent:CreateWindow({
    Title = "Anime Ball v1",
    SubTitle = "RaptureHub or https://discord.gg/CM7rWRXAJf",
    TabWidth = 160,
    Size = UDim2.fromOffset(580, 460),
    Acrylic = true,
    Theme = "Darker",
    MinimizeKey = Enum.KeyCode.LeftControl
})

local Tabs = {
    Main = Window:AddTab({ Title = "Main", Icon = "home" }),
    Parry = Window:AddTab({ Title = "Auto Parry", Icon = "shield" }),
    Spam = Window:AddTab({ Title = "Auto Spam", Icon = "zap" }),
    Visuals = Window:AddTab({ Title = "Visuals", Icon = "eye" }),
    Stats = Window:AddTab({ Title = "Statistics", Icon = "bar-chart" })
}

Tabs.Main:AddSection("Feature Control")

Tabs.Main:AddToggle("AutoParryMain", {
    Title = "Auto Parry",
    Description = "Itself Parry Ball",
    Default = true,
    Callback = function(Value)
        autoParryEnabled = Value
        Fluent:Notify({
            Title = "Auto Parry",
            Content = Value and "Enabled" or "Disabled",
            Duration = 3
        })
    end
})

Tabs.Main:AddToggle("AutoSpamMain", {
    Title = "Auto Spam (Beta)",
    Description = "Distance near player",
    Default = true,
    Callback = function(Value)
        autoSpamEnabled = Value
        Fluent:Notify({
            Title = "Auto Spam",
            Content = Value and "Enabled" or "Disabled",
            Duration = 3
        })
    end
})

Tabs.Main:AddSection("Quick Stats")
local QuickStatsLabel = Tabs.Main:AddParagraph({
    Title = "Performance",
    Content = "Loading..."
})

Tabs.Parry:AddSection("Auto Parry Status")

local ParryStatusLabel = Tabs.Parry:AddParagraph({
    Title = "Detection Status",
    Content = "Initializing..."
})

local ParryDistanceLabel = Tabs.Parry:AddParagraph({
    Title = "Distance Info",
    Content = "Waiting for data..."
})

Tabs.Parry:AddSection("Ping Compensation & Future Prediction")

Tabs.Parry:AddToggle("PingCompEnabled", {
    Title = "Ping Compensation",
    Description = "Parry earlier when ping is high",
    Default = true,
    Callback = function(Value)
        pingCompEnabled = Value
        Fluent:Notify({
            Title = "Ping Compensation",
            Content = Value and "Enabled" or "Disabled",
            Duration = 3
        })
    end
})

Tabs.Parry:AddSlider("PingMultiplier", {
    Title = "Compensation Strength",
    Description = "1.0 = full ping. Higher = parry even earlier",
    Default = 1.0,
    Min = 0,
    Max = 3,
    Rounding = 2,
    Callback = function(Value)
        pingMultiplier = Value
    end
})

Tabs.Parry:AddSlider("PredictionHorizon", {
    Title = "Prediction Horizon (seconds)",
    Description = "Max look-ahead into the future used for early parry (0-5s)",
    Default = 1.5,
    Min = 0,
    Max = 5,
    Rounding = 2,
    Callback = function(Value)
        predictionHorizon = Value
    end
})

Tabs.Parry:AddSlider("MaxPingComp", {
    Title = "Max Extra Range (studs)",
    Description = "Cap on extra detection studs from ping",
    Default = 60,
    Min = 0,
    Max = 150,
    Rounding = 0,
    Callback = function(Value)
        MAX_PING_COMP = Value
    end
})

Tabs.Parry:AddToggle("AntiCurveEnabled", {
    Title = "Anti-Curve Prediction",
    Description = "Simulate the ball's actual curved arc instead of a straight line",
    Default = true,
    Callback = function(Value)
        antiCurveEnabled = Value
    end
})

Tabs.Parry:AddSlider("AccelSmoothing", {
    Title = "Curve Reactivity",
    Description = "Higher = react to new curves faster but jitter more",
    Default = 0.35,
    Min = 0.05,
    Max = 1,
    Rounding = 2,
    Callback = function(Value)
        ACCEL_SMOOTHING = Value
    end
})

local PingInfoLabel = Tabs.Parry:AddParagraph({
    Title = "Ping Status",
    Content = "Measuring..."
})

Tabs.Spam:AddSection("Auto Spam Status")

local SpamStatusLabel = Tabs.Spam:AddParagraph({
    Title = "System Status",
    Content = "Initializing..."
})

local SpamConditionsLabel = Tabs.Spam:AddParagraph({
    Title = "Detection Status",
    Content = "Checking conditions..."
})

Tabs.Spam:AddSection("Live Detection")

local PlayerDetectionLabel = Tabs.Spam:AddParagraph({
    Title = "Player Detection",
    Content = "Scanning..."
})

local BallDetectionLabel = Tabs.Spam:AddParagraph({
    Title = "Ball Detection",
    Content = "Scanning..."
})

local HighlightDetectionLabel = Tabs.Spam:AddParagraph({
    Title = "Highlight Detection",
    Content = "Checking..."
})

-- ============================================
-- VISUALS TAB
-- ============================================

Tabs.Visuals:AddSection("Visual Indicators")

Tabs.Visuals:AddToggle("VisualSphere", {
    Title = "Show Parry Detection Sphere",
    Description = "Display the auto parry detection range",
    Default = true,
    Callback = function(Value)
        showVisualSphere = Value
        if not Value and visualSphere then
            visualSphere.Transparency = 1
        end
    end
})

Tabs.Visuals:AddToggle("PlayerDetector", {
    Title = "Show Spam Detection Sphere",
    Description = "Display 17 stud spheres around players",
    Default = true,
    Callback = function(Value)
        showPlayerDetectors = Value
        if not Value then
            clearPlayerDetectorSpheres()
        else
            createPlayerDetectorSpheres()
        end
    end
})

Tabs.Visuals:AddToggle("SpeedLabel", {
    Title = "Show Ball Speed Labels",
    Description = "Display velocity above balls",
    Default = true,
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

Tabs.Visuals:AddParagraph({
    Title = "Color Guide",
    Content = "Blue = Normal Mode\nRed = High Speed Mode\nGreen = Player Detectors\nYellow = Ball Velocity"
})

-- ============================================
-- STATS TAB
-- ============================================

Tabs.Stats:AddSection("Performance Statistics")

local ParryStatsLabel = Tabs.Stats:AddParagraph({
    Title = "Auto Parry Stats",
    Content = "Waiting for data..."
})

local SpamStatsLabel = Tabs.Stats:AddParagraph({
    Title = "Auto Spam Stats",
    Content = "Waiting for data..."
})

local LiveStatsLabel = Tabs.Stats:AddParagraph({
    Title = "Live Monitoring",
    Content = "Monitoring..."
})

Tabs.Stats:AddButton({
    Title = "Reset All Statistics",
    Description = "Reset both parry and spam counters",
    Callback = function()
        totalParries = 0
        highSpeedParries = 0
        totalSpams = 0
        spamDuration = 0
        Fluent:Notify({
            Title = "Stats Reset",
            Content = "All statistics have been reset",
            Duration = 3
        })
    end
})

-- ============================================
-- SAVE MANAGER
-- ============================================

SaveManager:SetLibrary(Fluent)
InterfaceManager:SetLibrary(Fluent)
SaveManager:IgnoreThemeSettings()
SaveManager:SetIgnoreIndexes({})
InterfaceManager:SetFolder("AnimeBallComplete")
SaveManager:SetFolder("AnimeBallComplete/configs")
SaveManager:BuildConfigSection(Tabs.Stats)
Window:SelectTab(1)

-- ============================================
-- VISUALS
-- ============================================

createVisualSphere = function()
    if visualSphere then visualSphere:Destroy() end
    visualSphere = Instance.new("Part")
    visualSphere.Name = "VisualDetector"
    visualSphere.Shape = Enum.PartType.Ball
    visualSphere.Material = Enum.Material.ForceField
    visualSphere.Color = Color3.fromRGB(100, 100, 255)
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
        sphere.Color = Color3.fromRGB(100, 255, 100)
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

local function getBallVelocity(ball)
    return getBallVelocityVector(ball).Magnitude
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
local function updateBallCurvature(ball, pos, vel, now)
    local prev = ballMotionCache[ball]
    local accel = Vector3.new()
    if prev and now > prev.time then
        local dt = now - prev.time
        local rawAccel = (vel - prev.vel) / dt
        accel = prev.accel:Lerp(rawAccel, ACCEL_SMOOTHING)
    end
    ballMotionCache[ball] = {vel = vel, accel = accel, time = now}
    return accel
end

-- Simulates the curved arc (pos + vel*t + 0.5*accel*t^2) forward in small
-- steps up to maxLookahead seconds, returning true (and the time) as soon as
-- the predicted position comes within meleeRange of targetPos. This is what
-- lets a curving ball still trigger an early "future" parry instead of only
-- ever being caught once it's already in range.
local function predictCurvedImpact(pos, vel, accel, targetPos, meleeRange, maxLookahead, steps)
    if maxLookahead <= 0 then return false, nil end
    steps = steps or CURVE_SIM_STEPS
    local dt = maxLookahead / steps
    for i = 1, steps do
        local t = i * dt
        local predictedPos = pos + vel * t + accel * (0.5 * t * t)
        if (predictedPos - targetPos).Magnitude <= meleeRange then
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
    for _, ball in pairs(folder:GetChildren()) do ballsCache[ball] = true end
    folder.ChildAdded:Connect(function(child) ballsCache[child] = true end)
    folder.ChildRemoved:Connect(function(child)
        ballsCache[child] = nil
        ballMotionCache[child] = nil
    end)
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

-- Extra detection studs so a high-ping client triggers the parry earlier,
-- based on the closing speed of the ball (not its raw magnitude) and capped
-- by both MAX_PING_COMP (studs) and predictionHorizon (seconds of look-ahead).
local function getPingCompensation(closingSpeed)
    if not pingCompEnabled or closingSpeed <= 0 then
        currentPingComp = 0
        currentRequiredLead = 0
        return 0
    end
    currentPing = getPing()
    local leadTime = math.clamp((currentPing / 1000) * pingMultiplier, 0, predictionHorizon)
    currentRequiredLead = leadTime
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

local function executeParry()
    local currentTime = tick()
    if currentTime - lastParryTime < PARRY_COOLDOWN then return end
    lastParryTime = currentTime
    totalParries = totalParries + 1
    if isHighSpeedMode then highSpeedParries = highSpeedParries + 1 end
    pcall(function()
        ReplicatedStorage.Framework.RemoteFunction:InvokeServer("SwordService", "Block", {-0.759547233581543})
    end)
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
    label.TextColor3 = Color3.fromRGB(255, 255, 100)
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
local function findClosestBall(humanoidRootPart)
    local closestBall = nil
    local closestDistance = math.huge
    for ball in pairs(ballsCache) do
        local ballPos = getBallPosition(ball)
        if ballPos then
            local distance = (humanoidRootPart.Position - ballPos).Magnitude
            if distance < closestDistance then
                closestDistance = distance
                closestBall = ball
            end
        end
    end
    return closestBall, closestDistance
end

local function hasPlayerHighlight()
    return hasHighlightCache
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
    pcall(function()
        ReplicatedStorage.Framework.RemoteFunction:InvokeServer("SwordService", "Block", {-0.759547233581543})
    end)
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
        local ballPos = getBallPosition(ball)
        if ballPos then
            local distance = (hrp.Position - ballPos).Magnitude
            if distance < closestDistance then closestDistance = distance end
        end
    end
    return closestDistance <= SPAM_DETECTION_DISTANCE, closestDistance
end

task.spawn(function()
    while task.wait(0.5) do
        QuickStatsLabel:SetDesc(string.format("- Total Parries: %d (High Speed: %d)\n- Total Spams: %d\n- Auto Parry: %s\n- Auto Spam: %s",
            totalParries, highSpeedParries, totalSpams,
            autoParryEnabled and "ON" or "OFF",
            autoSpamEnabled and "ON" or "OFF"))

        ParryStatsLabel:SetDesc(string.format("- Total Parries: %d\n- High Speed Parries: %d\n- High Speed Rate: %.1f%%\n- Current Mode: %s",
            totalParries, highSpeedParries,
            totalParries > 0 and (highSpeedParries / totalParries * 100) or 0,
            isHighSpeedMode and "MAX SPEED" or "Normal"))

        local spamsPerSecond = 0
        if spamStarted and lastSpamStartTime > 0 then
            local currentDuration = tick() - lastSpamStartTime
            if currentDuration > 0 then spamsPerSecond = totalSpams / (spamDuration + currentDuration) end
        elseif spamDuration > 0 then
            spamsPerSecond = totalSpams / spamDuration
        end

        SpamStatsLabel:SetDesc(string.format("- Total Spams: %d\n- Total Duration: %.1fs\n- Average Rate: %.1f spam/s\n- Status: %s",
            totalSpams, spamDuration, spamsPerSecond, spamStarted and "ACTIVE" or "INACTIVE"))

        local livePing = getPing()
        PingInfoLabel:SetDesc(string.format("- Current Ping: %.0f ms\n- Compensation: %s\n- Strength: %.2fx\n- Prediction Horizon: %.2fs\n- Last Extra Range: +%.1f studs\n- Last Time-To-Impact: %s",
            livePing,
            pingCompEnabled and "ON" or "OFF",
            pingMultiplier,
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

    local hasHighlight = hasPlayerHighlight()
    local closestBall, closestDistance = findClosestBall(humanoidRootPart)

    if autoParryEnabled and closestBall then
        updatePlayerDetectorSpheres()
        local ballInDetectorRange = isBallInPlayerRange(closestBall, PLAYER_DETECTOR_DISTANCE)
        local ballPos = getBallPosition(closestBall)
        local ballVel = getBallVelocityVector(closestBall)
        local velocity = ballVel.Magnitude
        local closingSpeed = ballPos and getClosingSpeed(ballPos, ballVel, humanoidRootPart.Position) or 0
        local ballAccel = ballPos and updateBallCurvature(closestBall, ballPos, ballVel, currentTime) or Vector3.new()
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
        local pingComp = getPingCompensation(closingSpeed)
        local effectiveParryDistance = currentParryDistance + pingComp

        -- Parry if the ball is already inside melee range, OR if its
        -- predicted path enters melee range before our ping round-trip
        -- completes. With Anti-Curve on, the path is a simulated curved arc
        -- (using measured curvature) rather than a straight line, so a
        -- curving/homing ball is caught too, not just ones flying straight.
        local withinRange = closestDistance <= currentParryDistance
        local willArriveInTime = false
        if pingCompEnabled and currentRequiredLead > 0 and ballPos then
            if antiCurveEnabled then
                local arrives, arriveTime = predictCurvedImpact(
                    ballPos, ballVel, ballAccel, humanoidRootPart.Position,
                    currentParryDistance, currentRequiredLead)
                willArriveInTime = arrives
                currentTimeToImpact = arrives and arriveTime or (closingSpeed > 0 and (closestDistance / closingSpeed) or math.huge)
            elseif closingSpeed > 0 then
                willArriveInTime = ((closestDistance - currentParryDistance) / closingSpeed) <= currentRequiredLead
                currentTimeToImpact = closestDistance / closingSpeed
            else
                currentTimeToImpact = math.huge
            end
        else
            currentTimeToImpact = closingSpeed > 0 and (closestDistance / closingSpeed) or math.huge
        end

        ParryStatusLabel:SetDesc(string.format("Status: %s", autoParryEnabled and "ACTIVE" or "DISABLED"))
        ParryDistanceLabel:SetDesc(string.format("- Detection Range: %.1f studs\n- Ping Comp: +%.1f studs (%.0f ms, lead %.2fs)\n- Effective Range: %.1f studs\n- Ball Speed: %.1f studs/s (closing: %.1f)\n- Curve: %.1f studs/s^2 (%s)\n- Distance to Ball: %.1f studs\n- Time-To-Impact: %s\n- Mode: %s\n- Frozen: %s",
            currentParryDistance, pingComp, currentPing, currentRequiredLead, effectiveParryDistance, velocity, closingSpeed,
            currentCurveAccel, antiCurveEnabled and "ON" or "OFF", closestDistance,
            currentTimeToImpact < math.huge and string.format("%.2fs", currentTimeToImpact) or "n/a",
            isHighSpeedMode and "MAX SPEED" or "Normal",
            isAutoParryFrozen and "Yes" or "No"))

        if showSpeedLabel then
            local speedLabel = createSpeedLabel(closestBall)
            if speedLabel.Label then
                speedLabel.Label.Text = string.format("%.1f%s", velocity, isHighSpeedMode and " [FAST]" or "")
            end
        end

        if hasHighlight and (withinRange or willArriveInTime) then executeParry() end
    end

    if visualSphere and showVisualSphere then
        if not visualSphere.Parent then createVisualSphere() end
        visualSphere.Size = Vector3.new(currentParryDistance * 2, currentParryDistance * 2, currentParryDistance * 2)
        visualSphere.Position = humanoidRootPart.Position
        visualSphere.Transparency = 0.7
        if isHighSpeedMode then
            visualSphere.Color = Color3.fromRGB(255, 50, 50)
        else
            visualSphere.Color = Color3.fromRGB(100, 100, 255)
        end
    elseif visualSphere then
        visualSphere.Transparency = 1
    end

    if not autoSpamEnabled then
        if spamStarted then
            spamDuration = spamDuration + (tick() - lastSpamStartTime)
            spamStarted = false
        end
        SpamStatusLabel:SetDesc("AUTO SPAM: DISABLED")
        SpamConditionsLabel:SetDesc("Auto Spam is turned off")
        return
    end

    local playerInRange, closestPlayer, playerDistance = checkPlayerDistance()
    local ballInRange, ballDistance = checkBallDistance()

    if playerInRange and closestPlayer then
        PlayerDetectionLabel:SetDesc(string.format("Player: %s\nDistance: %.1f studs", closestPlayer.Name, playerDistance))
    else
        PlayerDetectionLabel:SetDesc("No players in range")
    end

    if ballInRange then
        BallDetectionLabel:SetDesc(string.format("Ball Found\nDistance: %.1f studs", ballDistance))
    else
        BallDetectionLabel:SetDesc(string.format("No ball in range\nClosest: %.1f studs", ballDistance))
    end

    HighlightDetectionLabel:SetDesc(hasHighlight and "Highlight Active" or "No Highlight")

    if playerInRange and ballInRange and hasHighlight then
        if not spamStarted then
            spamStarted = true
            lastSpamStartTime = tick()
        end
    end

    if not ballInRange then
        if spamStarted then
            spamDuration = spamDuration + (tick() - lastSpamStartTime)
            spamStarted = false
        end
    end

    if spamStarted then
        SpamStatusLabel:SetDesc("AUTO SPAM: ACTIVE\nSpamming block!")
        SpamConditionsLabel:SetDesc("Player | Ball | Highlight\nAll conditions met!")
        LiveStatsLabel:SetDesc(string.format("- Parry Status: %s\n- Spam Status: SPAMMING\n- Player: %s (%.1f studs)\n- Ball Distance: %.1f studs\n- Parry Range: %.1f studs\n- Total Spams: %d",
            autoParryEnabled and "Active" or "Disabled",
            closestPlayer and closestPlayer.Name or "Unknown", playerDistance, ballDistance, currentParryDistance, totalSpams))
        executeSpam()
    else
        SpamStatusLabel:SetDesc("AUTO SPAM: INACTIVE\nWaiting for conditions...")
        local conditionText = (playerInRange and "[OK] Player" or "[--] Player") .. " | " .. (ballInRange and "[OK] Ball" or "[--] Ball") .. " | " .. (hasHighlight and "[OK] Highlight" or "[--] Highlight") .. "\nWaiting for all conditions..."
        SpamConditionsLabel:SetDesc(conditionText)
        LiveStatsLabel:SetDesc(string.format("- Parry Status: %s\n- Spam Status: WAITING\n- Player in Range: %s\n- Ball in Range: %s\n- Highlight: %s\n- Parry Range: %.1f studs",
            autoParryEnabled and "Active" or "Disabled",
            playerInRange and "Yes" or "No", ballInRange and "Yes" or "No", hasHighlight and "Active" or "Inactive", currentParryDistance))
    end
end)

LocalPlayer.CharacterRemoving:Connect(function()
    if visualSphere then visualSphere:Destroy() visualSphere = nil end
    clearPlayerDetectorSpheres()
    isHighSpeedMode = false
end)

Fluent:Notify({
    Title = "Anime Ball Loaded!",
    Content = "Auto Parry + Ping Compensation ready",
    Duration = 5
})
