local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
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
local UPDATE_INTERVAL = 0.0001
local PARRY_COOLDOWN = 0.3
local HIGH_SPEED_THRESHOLD = 300
local PLAYER_DETECTOR_DISTANCE = 17

local autoParryEnabled = true
local currentParryDistance = 34
local targetParryDistance = 34
local lastParryTime = 0
local lastDistanceUpdate = 0
local visualSphere = nil
local playerDetectorSpheres = {}
local isAutoParryFrozen = false
local frozenParryDistance = 34
local isHighSpeedMode = false
local showVisualSphere = true
local showPlayerDetectors = true
local showSpeedLabel = true
local totalParries = 0
local highSpeedParries = 0

-- ============================================
-- AUTO SPAM CONFIGURATION
-- ============================================

local SPAM_DETECTION_DISTANCE = 34.3
local autoSpamEnabled = true
local spamStarted = false
local totalSpams = 0
local spamDuration = 0
local lastSpamStartTime = 0


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
            Content = Value and "Enabled ✓" or "Disabled ✗",
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
            for ball, cache in pairs(billboardCache) do
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
    Content = "🔵 Blue = Normal Mode\n🔴 Red = High Speed Mode\n🟢 Green = Player Detectors\n🟡 Yellow = Ball Velocity"
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
billboardCache = {}

function createVisualSphere()
    if visualSphere then visualSphere:Destroy() end
    visualSphere = Instance.new("Part")
    visualSphere.Name = "VisualDetector"
    visualSphere.Shape = Enum.PartType.Ball
    visualSphere.Material = Enum.Material.ForceField
    visualSphere.Color = Color3.fromRGB(100, 100, 255)
    visualSphere.Transparency = 0.7
    visualSphere.CanCollide = false
    visualSphere.Anchored = true
    visualSphere.Parent = workspace
end

function createPlayerDetectorSpheres()
    if not showPlayerDetectors then return end
    for _, sphere in pairs(playerDetectorSpheres) do if sphere then sphere:Destroy() end end
    playerDetectorSpheres = {}
    for _, player in pairs(Players:GetPlayers()) do
        if player.Character then
            local hrp = player.Character:FindFirstChild("HumanoidRootPart")
            if hrp then
                local sphere = Instance.new("Part")
                sphere.Name = "PlayerDetector_" .. player.Name
                sphere.Shape = Enum.PartType.Ball
                sphere.Material = Enum.Material.ForceField
                sphere.Color = Color3.fromRGB(100, 255, 100)
                sphere.Transparency = 0.7
                sphere.CanCollide = false
                sphere.Anchored = true
                sphere.Size = Vector3.new(PLAYER_DETECTOR_DISTANCE * 2, PLAYER_DETECTOR_DISTANCE * 2, PLAYER_DETECTOR_DISTANCE * 2)
                sphere.Parent = workspace
                playerDetectorSpheres[player.Name] = sphere
            end
        end
    end
end

local function updatePlayerDetectorSpheres()
    if not showPlayerDetectors then return end
    for _, player in pairs(Players:GetPlayers()) do
        if player.Character then
            local hrp = player.Character:FindFirstChild("HumanoidRootPart")
            if hrp then
                if not playerDetectorSpheres[player.Name] or not playerDetectorSpheres[player.Name].Parent then
                    local sphere = Instance.new("Part")
                    sphere.Name = "PlayerDetector_" .. player.Name
                    sphere.Shape = Enum.PartType.Ball
                    sphere.Material = Enum.Material.ForceField
                    sphere.Color = Color3.fromRGB(100, 255, 100)
                    sphere.Transparency = 0.7
                    sphere.CanCollide = false
                    sphere.Anchored = true
                    sphere.Size = Vector3.new(PLAYER_DETECTOR_DISTANCE * 2, PLAYER_DETECTOR_DISTANCE * 2, PLAYER_DETECTOR_DISTANCE * 2)
                    sphere.Parent = workspace
                    playerDetectorSpheres[player.Name] = sphere
                end
                playerDetectorSpheres[player.Name].Position = hrp.Position
            end
        end
    end
end

function clearPlayerDetectorSpheres()
    for _, sphere in pairs(playerDetectorSpheres) do if sphere then sphere:Destroy() end end
    playerDetectorSpheres = {}
end

local function getBallVelocity(ball)
    if ball:IsA("BasePart") then return ball.AssemblyLinearVelocity.Magnitude end
    for _, child in pairs(ball:GetDescendants()) do
        if child:IsA("BasePart") then return child.AssemblyLinearVelocity.Magnitude end
    end
    return 0
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

local function getBallPosition(ball)
    if ball:IsA("BasePart") then return ball.Position end
    for _, child in pairs(ball:GetDescendants()) do
        if child:IsA("BasePart") then return child.Position end
    end
    return nil
end

local function findClosestBall(humanoidRootPart)
    local ballsFolder = workspace:FindFirstChild("Balls")
    if not ballsFolder then return nil, math.huge end
    local closestBall = nil
    local closestDistance = math.huge
    for _, ball in pairs(ballsFolder:GetChildren()) do
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
    local playerFolder = workspace:FindFirstChild(LocalPlayer.Name)
    return playerFolder and playerFolder:FindFirstChild("Highlight") ~= nil
end

local function isBallInPlayerRange(ball, distanceRange)
    for _, player in pairs(Players:GetPlayers()) do
        if player.Character then
            local hrp = player.Character:FindFirstChild("HumanoidRootPart")
            if hrp then
                local ballPos = getBallPosition(ball)
                if ballPos then
                    local distanceToPlayer = (hrp.Position - ballPos).Magnitude
                    if distanceToPlayer <= distanceRange then return true end
                end
            end
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
    local character = LocalPlayer.Character
    if not character or not character:FindFirstChild("HumanoidRootPart") then return false, nil, math.huge end
    local hrp = character.HumanoidRootPart
    local closestPlayer = nil
    local closestDistance = math.huge
    for _, player in pairs(Players:GetPlayers()) do
        if player ~= LocalPlayer and player.Character then
            local otherHRP = player.Character:FindFirstChild("HumanoidRootPart")
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

local function checkBallDistance()
    local character = LocalPlayer.Character
    if not character or not character:FindFirstChild("HumanoidRootPart") then return false, math.huge end
    local hrp = character.HumanoidRootPart
    local ballsFolder = workspace:FindFirstChild("Balls")
    if not ballsFolder then return false, math.huge end
    local closestDistance = math.huge
    for _, ball in pairs(ballsFolder:GetChildren()) do
        if ball:IsA("BasePart") or ball:FindFirstChildWhichIsA("BasePart") then
            local ballPart = ball:IsA("BasePart") and ball or ball:FindFirstChildWhichIsA("BasePart")
            if ballPart then
                local distance = (hrp.Position - ballPart.Position).Magnitude
                if distance <= SPAM_DETECTION_DISTANCE then closestDistance = math.min(closestDistance, distance) end
            end
        end
    end
    return closestDistance <= SPAM_DETECTION_DISTANCE, closestDistance
end

task.spawn(function()
    while task.wait(0.5) do
        QuickStatsLabel:SetDesc(string.format("• Total Parries: %d (🚀 High Speed: %d)\n• Total Spams: %d\n• Auto Parry: %s\n• Auto Spam: %s", 
            totalParries, highSpeedParries, totalSpams,
            autoParryEnabled and "🟢 ON" or "🔴 OFF",
            autoSpamEnabled and "🟢 ON" or "🔴 OFF"))
        
        ParryStatsLabel:SetDesc(string.format("• Total Parries: %d\n• High Speed Parries: %d\n• Success Rate: %.1f%%\n• Current Mode: %s", 
            totalParries, highSpeedParries, 
            totalParries > 0 and (highSpeedParries / totalParries * 100) or 0,
            isHighSpeedMode and "🚀 MAX SPEED" or "⚡ Normal"))
        
        local spamsPerSecond = 0
        if spamStarted and lastSpamStartTime > 0 then
            local currentDuration = tick() - lastSpamStartTime
            if currentDuration > 0 then spamsPerSecond = totalSpams / (spamDuration + currentDuration) end
        elseif spamDuration > 0 then
            spamsPerSecond = totalSpams / spamDuration
        end
        
        SpamStatsLabel:SetDesc(string.format("• Total Spams: %d\n• Total Duration: %.1fs\n• Average Rate: %.1f spam/s\n• Status: %s", 
            totalSpams, spamDuration, spamsPerSecond, spamStarted and "🟢 ACTIVE" or "🔴 INACTIVE"))
    end
end)

createVisualSphere()
createPlayerDetectorSpheres()

local lastUpdateTime = 0
RunService.Heartbeat:Connect(function()
    local currentTime = tick()
    if currentTime - lastUpdateTime < UPDATE_INTERVAL then return end
    lastUpdateTime = currentTime
    
    local character = LocalPlayer.Character
    if not character then return end
    local humanoidRootPart = character:FindFirstChild("HumanoidRootPart")
    if not humanoidRootPart then return end
    
    local hasHighlight = hasPlayerHighlight()
    local closestBall, closestDistance = findClosestBall(humanoidRootPart)
    
    if autoParryEnabled and closestBall then
        updatePlayerDetectorSpheres()
        local ballInDetectorRange = isBallInPlayerRange(closestBall, PLAYER_DETECTOR_DISTANCE)
        local velocity = getBallVelocity(closestBall)
        
        if velocity >= HIGH_SPEED_THRESHOLD then
            if not isHighSpeedMode then
                isHighSpeedMode = true
                currentParryDistance = MAX_DISTANCE
                targetParryDistance = MAX_DISTANCE
            end
        else
            if isHighSpeedMode then isHighSpeedMode = false end
        end
        
        if ballInDetectorRange and not isAutoParryFrozen then
            isAutoParryFrozen = true
            frozenParryDistance = currentParryDistance
        elseif not ballInDetectorRange and isAutoParryFrozen then
            isAutoParryFrozen = false
        end
        
        if velocity == 0 and not isAutoParryFrozen then
            isAutoParryFrozen = true
            frozenParryDistance = currentParryDistance
        elseif velocity > 0 and isAutoParryFrozen and not ballInDetectorRange then
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
        
        ParryStatusLabel:SetDesc(string.format("Status: %s", autoParryEnabled and "🟢 ACTIVE" or "🔴 DISABLED"))
        ParryDistanceLabel:SetDesc(string.format("• Detection Range: %.1f studs\n• Ball Velocity: %.1f studs/s\n• Distance to Ball: %.1f studs\n• Mode: %s\n• Frozen: %s", 
            currentParryDistance, velocity, closestDistance,
            isHighSpeedMode and "🚀 MAX SPEED" or "⚡ Normal",
            isAutoParryFrozen and "Yes" or "No"))
        
        if showSpeedLabel then
            local speedLabel = createSpeedLabel(closestBall)
            if speedLabel.Label then
                speedLabel.Label.Text = string.format("%.1f%s", velocity, isHighSpeedMode and " 🚀" or "")
            end
        end
        
        if hasHighlight and closestDistance <= currentParryDistance then executeParry() end
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
        SpamStatusLabel:SetDesc("🔴 AUTO SPAM: DISABLED")
        SpamConditionsLabel:SetDesc("Auto Spam is turned off")
        return
    end
    
    local playerInRange, closestPlayer, playerDistance = checkPlayerDistance()
    local ballInRange, ballDistance = checkBallDistance()
    local hasHL = hasPlayerHighlight()
    
    if playerInRange and closestPlayer then
        PlayerDetectionLabel:SetDesc(string.format("✅ Player: %s\nDistance: %.1f studs", closestPlayer.Name, playerDistance))
    else
        PlayerDetectionLabel:SetDesc("❌ No players in range")
    end
    
    if ballInRange then
        BallDetectionLabel:SetDesc(string.format("✅ Ball Found\nDistance: %.1f studs", ballDistance))
    else
        BallDetectionLabel:SetDesc(string.format("❌ No ball in range\nClosest: %.1f studs", ballDistance))
    end
    
    if hasHL then
        HighlightDetectionLabel:SetDesc("✅ Highlight Active")
    else
        HighlightDetectionLabel:SetDesc("❌ No Highlight")
    end
    
    if playerInRange and ballInRange and hasHL then
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
        SpamStatusLabel:SetDesc("🟢 AUTO SPAM: ACTIVE\nSpamming at maximum speed!")
        SpamConditionsLabel:SetDesc("✅ Player | ✅ Ball | ✅ Highlight\nAll conditions met!")
        LiveStatsLabel:SetDesc(string.format("• Parry Status: %s\n• Spam Status: SPAMMING 💥\n• Player: %s (%.1f studs)\n• Ball Distance: %.1f studs\n• Parry Range: %.1f studs\n• Total Spams: %d", 
            autoParryEnabled and "Active" or "Disabled",
            closestPlayer and closestPlayer.Name or "Unknown", playerDistance, ballDistance, currentParryDistance, totalSpams))
        executeSpam()
        executeSpam()
    else
        SpamStatusLabel:SetDesc("🔴 AUTO SPAM: INACTIVE\nWaiting for conditions...")
        local conditionText = (playerInRange and "✅ Player" or "❌ Player") .. " | " .. (ballInRange and "✅ Ball" or "❌ Ball") .. " | " .. (hasHL and "✅ Highlight" or "❌ Highlight") .. "\nWaiting for all conditions..."
        SpamConditionsLabel:SetDesc(conditionText)
        LiveStatsLabel:SetDesc(string.format("• Parry Status: %s\n• Spam Status: WAITING ⏳\n• Player in Range: %s\n• Ball in Range: %s\n• Highlight: %s\n• Parry Range: %.1f studs", 
            autoParryEnabled and "Active" or "Disabled",
            playerInRange and "Yes" or "No", ballInRange and "Yes" or "No", hasHL and "Active" or "Inactive", currentParryDistance))
    end
end)

LocalPlayer.CharacterRemoving:Connect(function()
    if visualSphere then visualSphere:Destroy() visualSphere = nil end
    clearPlayerDetectorSpheres()
    isHighSpeedMode = false
end)

Fluent:Notify({
    Title = "Anime Ball Loaded!",
    Content = "Skibidi",
    Duration = 5
})