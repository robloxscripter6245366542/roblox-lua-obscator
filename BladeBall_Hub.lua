-- Blade Ball Hub  v3
-- Auto Parry • Ball ESP • Auto Dodge • Prediction
-- Place as a LocalScript in StarterGui or run via executor

local Players          = game:GetService("Players")
local RunService       = game:GetService("RunService")
local ReplicatedStorage= game:GetService("ReplicatedStorage")
local TweenService     = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")

local LocalPlayer = Players.LocalPlayer
local Camera      = workspace.CurrentCamera

-- ──────────────────────────────────────────────────────────────
--  SETTINGS
-- ──────────────────────────────────────────────────────────────
local cfg = {
    AutoParry      = true,
    ParryDist      = 35,    -- outer detection range (studs); ball enters → single fire
    ClashDist      = 20,    -- inside this + heading at you → SPAM mode
    ClashDot       = 0.45,  -- how "head-on" the ball must be (dot product 0–1)
    SpamInterval   = 0.05,  -- seconds between fires during a clash (≈20/sec)
    NormalCooldown = 0.4,   -- cooldown for a single outer-range parry fire
    BallESP        = true,
    ESPColor       = Color3.fromRGB(255, 50, 50),
    AutoDodge      = false,
    DodgeSpeed     = 60,
    Prediction     = true,
    PredictTime    = 0.10,
}

-- ──────────────────────────────────────────────────────────────
--  REMOTES
--  ParryAttempt:FireServer() = real server-side parry (SwordsController)
--  ParryAttemptAll = server→all broadcast (VFX only)
-- ──────────────────────────────────────────────────────────────
local Remotes          = ReplicatedStorage:WaitForChild("Remotes", 10)
local BallAdded        = Remotes and Remotes:FindFirstChild("BallAdded")
local ParryAttempt     = Remotes and Remotes:FindFirstChild("ParryAttempt")
local ParryAttemptAll  = Remotes and Remotes:FindFirstChild("ParryAttemptAll")
local ParryButtonPress = Remotes and Remotes:FindFirstChild("ParryButtonPress")

-- ──────────────────────────────────────────────────────────────
--  PARTICLE SHINE  (local VFX helper)
-- ──────────────────────────────────────────────────────────────
local cachedParticleShine = nil
local function getParticleShine()
    if cachedParticleShine and cachedParticleShine.Parent == nil then
        return cachedParticleShine
    end
    if not getnilinstances then return nil end
    for _, obj in ipairs(getnilinstances()) do
        if obj.Name == "ParticleShine" then
            cachedParticleShine = obj
            return obj
        end
    end
    return nil
end

-- ──────────────────────────────────────────────────────────────
--  BALL TRACKING
-- ──────────────────────────────────────────────────────────────
local activeBalls = {}  -- [ball] = { highlight }
local lastParryTime = 0
local currentMode   = "IDLE"   -- "IDLE" | "TRACKING" | "CLASH"
local lastMode      = ""

local function getBallVelocity(ball)
    local ok, vel = pcall(function() return ball.AssemblyLinearVelocity end)
    if ok and vel then return vel end
    return ball.Velocity or Vector3.zero
end

local function predictedBallPos(ball)
    if not cfg.Prediction then return ball.Position end
    return ball.Position + getBallVelocity(ball) * cfg.PredictTime
end

-- Returns true when the ball is travelling toward myPos
local function isBallClashing(ball, myPos)
    local vel   = getBallVelocity(ball)
    local speed = vel.Magnitude
    if speed < 5 then return false end
    local toPlayer = myPos - ball.Position
    if toPlayer.Magnitude < 0.1 then return true end
    return vel.Unit:Dot(toPlayer.Unit) >= cfg.ClashDot
end

local function addESP(ball)
    if not cfg.BallESP then return nil end
    local sb = Instance.new("SelectionBox")
    sb.Color3              = cfg.ESPColor
    sb.LineThickness       = 0.06
    sb.SurfaceTransparency = 0.75
    sb.SurfaceColor3       = cfg.ESPColor
    sb.Adornee             = ball
    sb.Parent              = Camera
    return sb
end

local function removeESP(entry)
    if entry.highlight then
        pcall(function() entry.highlight:Destroy() end)
        entry.highlight = nil
    end
end

local function registerBall(ball)
    if not ball or not ball:IsA("BasePart") then return end
    if activeBalls[ball] then return end
    local entry = { highlight = addESP(ball) }
    activeBalls[ball] = entry
    ball.AncestryChanged:Connect(function()
        if not ball.Parent then
            removeESP(entry)
            activeBalls[ball] = nil
        end
    end)
end

-- ──────────────────────────────────────────────────────────────
--  PARRY CORE  (zero-delay, called directly from heartbeat)
-- ──────────────────────────────────────────────────────────────
local function fireParryRaw()
    local char = LocalPlayer.Character
    if not char then return end
    -- Primary: real server-side parry
    if ParryAttempt then
        pcall(function() ParryAttempt:FireServer() end)
    elseif ParryButtonPress then
        pcall(function() ParryButtonPress:Fire() end)
    end
    -- Secondary: local VFX
    if ParryAttemptAll and type(firesignal) == "function" then
        pcall(function()
            firesignal(ParryAttemptAll.OnClientEvent, getParticleShine(), char)
        end)
    end
end

-- ──────────────────────────────────────────────────────────────
--  3-TIER AUTO PARRY
--
--  TIER 1 — CLASH   : ball ≤ ClashDist AND heading at you
--                     → SPAM every SpamInterval (macro mode)
--  TIER 2 — TRACKING: ball ≤ ParryDist AND heading at you
--                     → single fire, NormalCooldown
--  TIER 3 — IGNORE  : ball is far, or close but NOT heading at you
--                     → no fire (avoids wasting parry on stray balls)
-- ──────────────────────────────────────────────────────────────
local function tryAutoParry()
    if not cfg.AutoParry then currentMode = "IDLE"; return end
    if not (ParryAttempt or ParryButtonPress or ParryAttemptAll) then return end

    local char = LocalPlayer.Character
    if not char then return end
    local root = char:FindFirstChild("HumanoidRootPart")
    if not root then return end
    local h = char:FindFirstChildOfClass("Humanoid")
    if not h or h.Health <= 0 then return end

    local myPos = root.Position
    local now   = tick()
    local mode  = "IDLE"

    for ball in pairs(activeBalls) do
        if not ball.Parent then activeBalls[ball] = nil; continue end

        local checkPos = predictedBallPos(ball)
        local dist     = (checkPos - myPos).Magnitude
        local clashing = isBallClashing(ball, myPos)

        if dist <= cfg.ClashDist and clashing then
            -- TIER 1: CLASH — spam as fast as SpamInterval allows
            mode = "CLASH"
            if now - lastParryTime >= cfg.SpamInterval then
                lastParryTime = now
                fireParryRaw()
            end
            break  -- one clash ball is enough to spam

        elseif dist <= cfg.ParryDist and clashing and mode ~= "CLASH" then
            -- TIER 2: TRACKING — single fire with normal cooldown
            mode = "TRACKING"
            if now - lastParryTime >= cfg.NormalCooldown then
                lastParryTime = now
                fireParryRaw()
            end
            -- don't break: keep scanning in case a CLASH ball exists too
        end
    end

    currentMode = mode
end

-- ──────────────────────────────────────────────────────────────
--  AUTO DODGE
-- ──────────────────────────────────────────────────────────────
local originalSpeed = 16
local dodgeActive   = false

local function tryAutoDodge()
    if not cfg.AutoDodge then return end
    local char = LocalPlayer.Character
    if not char then return end
    local root = char:FindFirstChild("HumanoidRootPart")
    local h    = char:FindFirstChildOfClass("Humanoid")
    if not (root and h) or h.Health <= 0 then return end

    local myPos   = root.Position
    local closest, closestD = nil, math.huge

    for ball in pairs(activeBalls) do
        if ball.Parent then
            local d = (ball.Position - myPos).Magnitude
            if d < closestD then closestD = d; closest = ball end
        end
    end

    if closest and closestD < 35 then
        if not dodgeActive then originalSpeed = h.WalkSpeed; dodgeActive = true end
        h.WalkSpeed = cfg.DodgeSpeed
        local vel     = getBallVelocity(closest)
        local ballDir = vel.Magnitude > 0.1 and vel.Unit or (myPos - closest.Position).Unit
        h:MoveTo(myPos + Vector3.new(-ballDir.Z, 0, ballDir.X) * 15)
    else
        if dodgeActive then
            local hum = char:FindFirstChildOfClass("Humanoid")
            if hum then hum.WalkSpeed = originalSpeed end
            dodgeActive = false
        end
    end
end

-- ──────────────────────────────────────────────────────────────
--  BALL HOOKS
-- ──────────────────────────────────────────────────────────────
if BallAdded then
    BallAdded.OnClientEvent:Connect(function(ball)
        if ball then task.defer(function() registerBall(ball) end) end
    end)
end

task.spawn(function()
    for _, v in ipairs(workspace:GetDescendants()) do
        if v:IsA("BasePart") and v.Name:lower():find("ball") then registerBall(v) end
    end
    workspace.DescendantAdded:Connect(function(v)
        if v:IsA("BasePart") and v.Name:lower():find("ball") then registerBall(v) end
    end)
end)

-- ──────────────────────────────────────────────────────────────
--  HEARTBEAT
-- ──────────────────────────────────────────────────────────────
RunService.Heartbeat:Connect(function()
    tryAutoParry()
    tryAutoDodge()
end)

-- ──────────────────────────────────────────────────────────────
--  GUI
-- ──────────────────────────────────────────────────────────────
local screenGui = Instance.new("ScreenGui")
screenGui.Name            = "BladeBallHub"
screenGui.ResetOnSpawn    = false
screenGui.ZIndexBehavior  = Enum.ZIndexBehavior.Sibling
screenGui.Parent          = LocalPlayer:WaitForChild("PlayerGui")

local FULL_HEIGHT = 455

local mainFrame = Instance.new("Frame")
mainFrame.Name             = "Main"
mainFrame.Size             = UDim2.new(0, 280, 0, FULL_HEIGHT)
mainFrame.Position         = UDim2.new(1, -295, 0.5, -228)
mainFrame.BackgroundColor3 = Color3.fromRGB(13, 13, 13)
mainFrame.BorderSizePixel  = 0
mainFrame.Active           = true
mainFrame.Draggable        = true
mainFrame.Parent           = screenGui
do local c=Instance.new("UICorner");c.CornerRadius=UDim.new(0,14);c.Parent=mainFrame end

local grad = Instance.new("UIGradient")
grad.Color = ColorSequence.new{
    ColorSequenceKeypoint.new(0, Color3.fromRGB(22,22,22)),
    ColorSequenceKeypoint.new(1, Color3.fromRGB(13,13,13))
}
grad.Rotation = 135; grad.Parent = mainFrame

-- title bar
local titleBar = Instance.new("Frame")
titleBar.Size             = UDim2.new(1,0,0,44)
titleBar.BackgroundColor3 = Color3.fromRGB(20,20,20)
titleBar.BorderSizePixel  = 0; titleBar.Parent = mainFrame
do local c=Instance.new("UICorner");c.CornerRadius=UDim.new(0,14);c.Parent=titleBar end

local titleLabel = Instance.new("TextLabel")
titleLabel.Size=UDim2.new(1,-70,1,0); titleLabel.Position=UDim2.new(0,14,0,0)
titleLabel.BackgroundTransparency=1; titleLabel.Text="⚔️  Blade Ball Hub"
titleLabel.TextColor3=Color3.fromRGB(255,255,255); titleLabel.Font=Enum.Font.GothamBold
titleLabel.TextSize=15; titleLabel.TextXAlignment=Enum.TextXAlignment.Left
titleLabel.Parent=titleBar

local closeBtn = Instance.new("TextButton")
closeBtn.Size=UDim2.new(0,28,0,28); closeBtn.Position=UDim2.new(1,-34,0.5,-14)
closeBtn.BackgroundColor3=Color3.fromRGB(40,40,40); closeBtn.BorderSizePixel=0
closeBtn.Text="✕"; closeBtn.TextColor3=Color3.fromRGB(255,255,255)
closeBtn.Font=Enum.Font.GothamBold; closeBtn.TextSize=13; closeBtn.Parent=titleBar
do local c=Instance.new("UICorner");c.CornerRadius=UDim.new(0,8);c.Parent=closeBtn end

local minBtn = Instance.new("TextButton")
minBtn.Size=UDim2.new(0,28,0,28); minBtn.Position=UDim2.new(1,-67,0.5,-14)
minBtn.BackgroundColor3=Color3.fromRGB(40,40,40); minBtn.BorderSizePixel=0
minBtn.Text="−"; minBtn.TextColor3=Color3.fromRGB(255,255,255)
minBtn.Font=Enum.Font.GothamBold; minBtn.TextSize=17; minBtn.Parent=titleBar
do local c=Instance.new("UICorner");c.CornerRadius=UDim.new(0,8);c.Parent=minBtn end

local div = Instance.new("Frame")
div.Size=UDim2.new(1,-20,0,1); div.Position=UDim2.new(0,10,0,43)
div.BackgroundColor3=Color3.fromRGB(45,45,45); div.BorderSizePixel=0; div.Parent=mainFrame

-- status strip
local statusBar = Instance.new("Frame")
statusBar.Size=UDim2.new(1,-10,0,26); statusBar.Position=UDim2.new(0,5,0,50)
statusBar.BackgroundColor3=Color3.fromRGB(20,20,20); statusBar.BorderSizePixel=0
statusBar.Parent=mainFrame
do local c=Instance.new("UICorner");c.CornerRadius=UDim.new(0,8);c.Parent=statusBar end

local statusText = Instance.new("TextLabel")
statusText.Size=UDim2.new(1,-10,1,0); statusText.Position=UDim2.new(0,8,0,0)
statusText.BackgroundTransparency=1; statusText.Text="⚡ Scanning…"
statusText.TextColor3=Color3.fromRGB(180,180,180); statusText.Font=Enum.Font.Gotham
statusText.TextSize=10; statusText.TextXAlignment=Enum.TextXAlignment.Left
statusText.Parent=statusBar

-- mode indicator bar
local modeBar = Instance.new("Frame")
modeBar.Size=UDim2.new(1,-10,0,26); modeBar.Position=UDim2.new(0,5,0,82)
modeBar.BackgroundColor3=Color3.fromRGB(20,20,20); modeBar.BorderSizePixel=0
modeBar.Parent=mainFrame
do local c=Instance.new("UICorner");c.CornerRadius=UDim.new(0,8);c.Parent=modeBar end

local modeText = Instance.new("TextLabel")
modeText.Size=UDim2.new(1,-10,1,0); modeText.Position=UDim2.new(0,8,0,0)
modeText.BackgroundTransparency=1; modeText.Text="● IDLE"
modeText.TextColor3=Color3.fromRGB(120,120,120); modeText.Font=Enum.Font.GothamBold
modeText.TextSize=11; modeText.TextXAlignment=Enum.TextXAlignment.Left
modeText.Parent=modeBar

-- helper: distance row factory
local function makeDistRow(yPos, labelTxt, subTxt, initVal, minVal, maxVal, step, onChange)
    local row = Instance.new("Frame")
    row.Size=UDim2.new(1,-10,0,46); row.Position=UDim2.new(0,5,0,yPos)
    row.BackgroundColor3=Color3.fromRGB(22,22,22); row.BorderSizePixel=0; row.Parent=mainFrame
    do local c=Instance.new("UICorner");c.CornerRadius=UDim.new(0,10);c.Parent=row end

    local lbl=Instance.new("TextLabel")
    lbl.Size=UDim2.new(1,-120,0,22);lbl.Position=UDim2.new(0,12,0,5)
    lbl.BackgroundTransparency=1;lbl.Text=labelTxt
    lbl.TextColor3=Color3.fromRGB(255,255,255);lbl.Font=Enum.Font.GothamBold
    lbl.TextSize=13;lbl.TextXAlignment=Enum.TextXAlignment.Left;lbl.Parent=row

    local sub=Instance.new("TextLabel")
    sub.Size=UDim2.new(1,-120,0,14);sub.Position=UDim2.new(0,12,0,27)
    sub.BackgroundTransparency=1;sub.Text=subTxt
    sub.TextColor3=Color3.fromRGB(180,180,180);sub.Font=Enum.Font.Gotham
    sub.TextSize=10;sub.TextXAlignment=Enum.TextXAlignment.Left;sub.Parent=row

    local decB=Instance.new("TextButton")
    decB.Size=UDim2.new(0,28,0,28);decB.Position=UDim2.new(1,-110,0.5,-14)
    decB.BackgroundColor3=Color3.fromRGB(40,40,40);decB.BorderSizePixel=0
    decB.Text="−";decB.TextColor3=Color3.fromRGB(255,255,255)
    decB.Font=Enum.Font.GothamBold;decB.TextSize=16;decB.Parent=row
    do local c=Instance.new("UICorner");c.CornerRadius=UDim.new(0,8);c.Parent=decB end

    local numLbl=Instance.new("TextLabel")
    numLbl.Size=UDim2.new(0,32,0,28);numLbl.Position=UDim2.new(1,-80,0.5,-14)
    numLbl.BackgroundTransparency=1;numLbl.Text=tostring(initVal)
    numLbl.TextColor3=Color3.fromRGB(255,255,255);numLbl.Font=Enum.Font.GothamBold
    numLbl.TextSize=14;numLbl.TextXAlignment=Enum.TextXAlignment.Center;numLbl.Parent=row

    local incB=Instance.new("TextButton")
    incB.Size=UDim2.new(0,28,0,28);incB.Position=UDim2.new(1,-46,0.5,-14)
    incB.BackgroundColor3=Color3.fromRGB(40,40,40);incB.BorderSizePixel=0
    incB.Text="+";incB.TextColor3=Color3.fromRGB(255,255,255)
    incB.Font=Enum.Font.GothamBold;incB.TextSize=16;incB.Parent=row
    do local c=Instance.new("UICorner");c.CornerRadius=UDim.new(0,8);c.Parent=incB end

    decB.MouseButton1Click:Connect(function()
        local v = math.max(minVal, onChange("dec", step))
        numLbl.Text = tostring(v)
    end)
    incB.MouseButton1Click:Connect(function()
        local v = math.min(maxVal, onChange("inc", step))
        numLbl.Text = tostring(v)
    end)
end

-- parry detect distance
makeDistRow(114, "🎯 Detect Distance", cfg.ParryDist.." studs", cfg.ParryDist, 5, 80, 5,
    function(dir, step)
        cfg.ParryDist = dir == "inc" and cfg.ParryDist + step or cfg.ParryDist - step
        cfg.ParryDist = math.clamp(cfg.ParryDist, 5, 80)
        return cfg.ParryDist
    end)

-- clash spam distance
makeDistRow(166, "⚡ Clash Distance",  cfg.ClashDist.." studs", cfg.ClashDist, 5, 40, 5,
    function(dir, step)
        cfg.ClashDist = dir == "inc" and cfg.ClashDist + step or cfg.ClashDist - step
        cfg.ClashDist = math.clamp(cfg.ClashDist, 5, 40)
        return cfg.ClashDist
    end)

-- toggle factory
local function makeToggle(yPos, label, icon, initState, onColor, offColor, onToggle)
    local row=Instance.new("Frame")
    row.Size=UDim2.new(1,-10,0,46);row.Position=UDim2.new(0,5,0,yPos)
    row.BackgroundColor3=Color3.fromRGB(22,22,22);row.BorderSizePixel=0;row.Parent=mainFrame
    do local c=Instance.new("UICorner");c.CornerRadius=UDim.new(0,10);c.Parent=row end

    local lbl=Instance.new("TextLabel")
    lbl.Size=UDim2.new(1,-70,0,22);lbl.Position=UDim2.new(0,12,0,5)
    lbl.BackgroundTransparency=1;lbl.Text=icon.." "..label
    lbl.TextColor3=Color3.fromRGB(255,255,255);lbl.Font=Enum.Font.GothamBold
    lbl.TextSize=13;lbl.TextXAlignment=Enum.TextXAlignment.Left;lbl.Parent=row

    local sub=Instance.new("TextLabel")
    sub.Size=UDim2.new(1,-70,0,14);sub.Position=UDim2.new(0,12,0,27)
    sub.BackgroundTransparency=1
    sub.Text=initState and "Enabled" or "Disabled"
    sub.TextColor3=initState and Color3.fromRGB(100,220,120) or Color3.fromRGB(150,150,150)
    sub.Font=Enum.Font.Gotham;sub.TextSize=10;sub.TextXAlignment=Enum.TextXAlignment.Left
    sub.Parent=row

    local pill=Instance.new("TextButton")
    pill.Size=UDim2.new(0,52,0,26);pill.Position=UDim2.new(1,-60,0.5,-13)
    pill.BackgroundColor3=initState and onColor or offColor
    pill.BorderSizePixel=0;pill.Text=initState and "ON" or "OFF"
    pill.TextColor3=Color3.fromRGB(255,255,255);pill.Font=Enum.Font.GothamBold
    pill.TextSize=11;pill.Parent=row
    do local c=Instance.new("UICorner");c.CornerRadius=UDim.new(0,13);c.Parent=pill end

    local state=initState
    local function toggle()
        state=not state
        pill.Text=state and "ON" or "OFF"
        pill.BackgroundColor3=state and onColor or offColor
        sub.Text=state and "Enabled" or "Disabled"
        sub.TextColor3=state and Color3.fromRGB(100,220,120) or Color3.fromRGB(150,150,150)
        TweenService:Create(pill,TweenInfo.new(0.15),{BackgroundColor3=state and onColor or offColor}):Play()
        onToggle(state)
    end
    pill.MouseButton1Click:Connect(toggle)
    row.MouseButton1Click:Connect(toggle)
end

makeToggle(218, "Auto Parry",  "🛡️", cfg.AutoParry,   Color3.fromRGB(52,152,219),  Color3.fromRGB(50,50,50), function(v) cfg.AutoParry = v end)
makeToggle(270, "Ball ESP",    "🔴", cfg.BallESP,     Color3.fromRGB(231,76,60),   Color3.fromRGB(50,50,50), function(v)
    cfg.BallESP = v
    for ball, entry in pairs(activeBalls) do
        removeESP(entry)
        if v then entry.highlight = addESP(ball) end
    end
end)
makeToggle(322, "Auto Dodge",  "💨", cfg.AutoDodge,   Color3.fromRGB(46,204,113),  Color3.fromRGB(50,50,50), function(v) cfg.AutoDodge = v end)
makeToggle(374, "Prediction",  "🔮", cfg.Prediction,  Color3.fromRGB(155,89,182),  Color3.fromRGB(50,50,50), function(v) cfg.Prediction = v end)

local ballCountLabel = Instance.new("TextLabel")
ballCountLabel.Size=UDim2.new(1,-10,0,18);ballCountLabel.Position=UDim2.new(0,5,1,-22)
ballCountLabel.BackgroundTransparency=1;ballCountLabel.Text="Active balls: 0"
ballCountLabel.TextColor3=Color3.fromRGB(80,80,80);ballCountLabel.Font=Enum.Font.Gotham
ballCountLabel.TextSize=10;ballCountLabel.Parent=mainFrame

-- ──────────────────────────────────────────────────────────────
--  STATUS + MODE UPDATER
-- ──────────────────────────────────────────────────────────────
local MODE_CFG = {
    IDLE     = { text = "● IDLE",             color = Color3.fromRGB(120,120,120) },
    TRACKING = { text = "◉ TRACKING",         color = Color3.fromRGB(255,200,50)  },
    CLASH    = { text = "⚡ CLASH — SPAMMING", color = Color3.fromRGB(255,60,60)   },
}

task.spawn(function()
    while task.wait(0.25) do
        if not screenGui.Parent then break end

        -- remote status
        local rs = ParryAttempt and "✅ ParryAttempt"
            or (ParryButtonPress and "✅ ParryButtonPress"
            or "⚠️  Parry remote not found")
        local count = 0
        for _ in pairs(activeBalls) do count = count + 1 end
        statusText.Text = rs .. "  |  " .. count .. " ball(s)"
        ballCountLabel.Text = "Active balls: " .. count

        -- mode indicator (only update when mode changes to avoid flicker)
        if currentMode ~= lastMode then
            lastMode = currentMode
            local m = MODE_CFG[currentMode] or MODE_CFG.IDLE
            modeText.Text       = m.text
            modeText.TextColor3 = m.color
            modeBar.BackgroundColor3 = currentMode == "CLASH"
                and Color3.fromRGB(40,10,10)
                or  Color3.fromRGB(20,20,20)
        end

        -- re-add missing ESP
        if cfg.BallESP then
            for ball, entry in pairs(activeBalls) do
                if ball.Parent and not entry.highlight then
                    entry.highlight = addESP(ball)
                end
            end
        end
    end
end)

-- ──────────────────────────────────────────────────────────────
--  MINIMIZE / CLOSE
-- ──────────────────────────────────────────────────────────────
local minimized = false
minBtn.MouseButton1Click:Connect(function()
    minimized = not minimized
    mainFrame.Size = minimized
        and UDim2.new(0, 280, 0, 44)
        or  UDim2.new(0, 280, 0, FULL_HEIGHT)
    minBtn.Text = minimized and "+" or "−"
end)
closeBtn.MouseButton1Click:Connect(function() screenGui:Destroy() end)

-- ──────────────────────────────────────────────────────────────
--  KEYBOARD SHORTCUTS   P=parry  O=esp  L=dodge
-- ──────────────────────────────────────────────────────────────
UserInputService.InputBegan:Connect(function(input, gp)
    if gp then return end
    if     input.KeyCode == Enum.KeyCode.P then cfg.AutoParry = not cfg.AutoParry
    elseif input.KeyCode == Enum.KeyCode.O then cfg.BallESP   = not cfg.BallESP
    elseif input.KeyCode == Enum.KeyCode.L then cfg.AutoDodge = not cfg.AutoDodge
    end
end)

print("[BladeBall Hub v3] ParryAttempt:" .. (ParryAttempt and "✓" or "✗")
    .. " ParryAttemptAll:" .. (ParryAttemptAll and "✓" or "✗")
    .. " ParryButtonPress:" .. (ParryButtonPress and "✓" or "✗"))
