-- Blade Ball Hub
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
    AutoParry    = true,
    ParryDist    = 20,       -- studs: fire parry when ball is this close
    ParryDelay   = 0.08,     -- seconds: tiny delay before firing (feels more natural)
    BallESP      = true,
    ESPColor     = Color3.fromRGB(255, 50, 50),
    AutoDodge    = false,
    DodgeSpeed   = 60,       -- walkspeed burst when dodging
    Prediction   = true,     -- lead the ball's velocity for earlier parry trigger
    PredictTime  = 0.15,     -- seconds to look ahead for prediction
}

-- ──────────────────────────────────────────────────────────────
--  REMOTE DETECTION
-- ──────────────────────────────────────────────────────────────
local Remotes    = ReplicatedStorage:WaitForChild("Remotes", 10)
local BallAdded  = Remotes and Remotes:FindFirstChild("BallAdded")
local ParryRemote= nil

-- Try common parry remote names
if Remotes then
    for _, name in ipairs({"Parry","Deflect","Block","Reflect","Swing","Hit","Slash"}) do
        local r = Remotes:FindFirstChild(name)
        if r then ParryRemote = r; break end
    end
end

-- Fallback: listen for any RemoteEvent fired from a client parry input
-- so we can capture the real name at runtime
if not ParryRemote and Remotes then
    task.spawn(function()
        for _, child in ipairs(Remotes:GetChildren()) do
            if child:IsA("RemoteEvent") and child.Name ~= "BallAdded" then
                -- hook first unknown remote as a candidate parry
                if not ParryRemote then
                    ParryRemote = child
                end
            end
        end
    end)
end

-- ──────────────────────────────────────────────────────────────
--  BALL TRACKING
-- ──────────────────────────────────────────────────────────────
local activeBalls    = {}   -- { ball = BasePart, highlight = SelectionBox, lastFired = number }
local parryDebounce  = false
local lastParryTime  = 0

local function getBallVelocity(ball)
    -- try AssemblyLinearVelocity first, fall back to Velocity
    local ok, vel = pcall(function() return ball.AssemblyLinearVelocity end)
    if ok and vel then return vel end
    return ball.Velocity or Vector3.zero
end

local function predictedBallPos(ball)
    if not cfg.Prediction then return ball.Position end
    local vel = getBallVelocity(ball)
    return ball.Position + vel * cfg.PredictTime
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
    local entry = { ball = ball, highlight = addESP(ball), lastFired = 0 }
    activeBalls[ball] = entry

    -- clean up when ball is removed
    ball.AncestryChanged:Connect(function()
        if not ball.Parent then
            removeESP(entry)
            activeBalls[ball] = nil
        end
    end)
end

-- ──────────────────────────────────────────────────────────────
--  PARRY LOGIC
-- ──────────────────────────────────────────────────────────────
local function fireParry()
    if not ParryRemote then return end
    local now = tick()
    if now - lastParryTime < 0.3 then return end  -- global cooldown
    lastParryTime = now

    task.delay(cfg.ParryDelay, function()
        pcall(function() ParryRemote:FireServer() end)
    end)
end

local function tryAutoParry()
    if not cfg.AutoParry then return end
    local char = LocalPlayer.Character
    if not char then return end
    local root = char:FindFirstChild("HumanoidRootPart")
    if not root then return end
    local h = char:FindFirstChildOfClass("Humanoid")
    if not h or h.Health <= 0 then return end

    local myPos = root.Position

    for ball, entry in pairs(activeBalls) do
        if not ball.Parent then
            activeBalls[ball] = nil
            continue
        end

        local checkPos = predictedBallPos(ball)
        local dist     = (checkPos - myPos).Magnitude

        if dist <= cfg.ParryDist then
            fireParry()
            return  -- one parry per frame is enough
        end
    end
end

-- ──────────────────────────────────────────────────────────────
--  AUTO DODGE (move perpendicular to incoming ball)
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

    local myPos    = root.Position
    local closest  = nil
    local closestD = math.huge

    for ball, _ in pairs(activeBalls) do
        if ball.Parent then
            local d = (ball.Position - myPos).Magnitude
            if d < closestD then closestD = d; closest = ball end
        end
    end

    if closest and closestD < 35 then
        if not dodgeActive then
            originalSpeed = h.WalkSpeed
            dodgeActive   = true
        end
        h.WalkSpeed = cfg.DodgeSpeed

        -- move perpendicular to the ball's travel direction
        local toMe    = (myPos - closest.Position).Unit
        local vel     = getBallVelocity(closest)
        local ballDir = vel.Magnitude > 0.1 and vel.Unit or toMe
        local perp    = Vector3.new(-ballDir.Z, 0, ballDir.X)
        h:MoveTo(myPos + perp * 15)
    else
        if dodgeActive then
            local humanoid = char:FindFirstChildOfClass("Humanoid")
            if humanoid then humanoid.WalkSpeed = originalSpeed end
            dodgeActive = false
        end
    end
end

-- ──────────────────────────────────────────────────────────────
--  HOOK BallAdded EVENT
-- ──────────────────────────────────────────────────────────────
if BallAdded then
    BallAdded.OnClientEvent:Connect(function(ball)
        if ball then
            task.defer(function() registerBall(ball) end)
        end
    end)
end

-- Also scan workspace in case balls already exist
task.spawn(function()
    for _, v in ipairs(workspace:GetDescendants()) do
        if v:IsA("BasePart") and v.Name:lower():find("ball") then
            registerBall(v)
        end
    end
    workspace.DescendantAdded:Connect(function(v)
        if v:IsA("BasePart") and v.Name:lower():find("ball") then
            registerBall(v)
        end
    end)
end)

-- ──────────────────────────────────────────────────────────────
--  HEARTBEAT LOOP
-- ──────────────────────────────────────────────────────────────
RunService.Heartbeat:Connect(function()
    tryAutoParry()
    tryAutoDodge()
end)

-- ──────────────────────────────────────────────────────────────
--  GUI
-- ──────────────────────────────────────────────────────────────
local screenGui = Instance.new("ScreenGui")
screenGui.Name         = "BladeBallHub"
screenGui.ResetOnSpawn = false
screenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
screenGui.Parent = LocalPlayer:WaitForChild("PlayerGui")

local mainFrame = Instance.new("Frame")
mainFrame.Name             = "Main"
mainFrame.Size             = UDim2.new(0, 280, 0, 380)
mainFrame.Position         = UDim2.new(1, -295, 0.5, -190)
mainFrame.BackgroundColor3 = Color3.fromRGB(13, 13, 13)
mainFrame.BorderSizePixel  = 0
mainFrame.Active           = true
mainFrame.Draggable        = true
mainFrame.Parent           = screenGui
do local c=Instance.new("UICorner");c.CornerRadius=UDim.new(0,14);c.Parent=mainFrame end

-- gradient
local grad = Instance.new("UIGradient")
grad.Color = ColorSequence.new{
    ColorSequenceKeypoint.new(0, Color3.fromRGB(22,22,22)),
    ColorSequenceKeypoint.new(1, Color3.fromRGB(13,13,13))
}
grad.Rotation = 135; grad.Parent = mainFrame

-- title bar
local titleBar = Instance.new("Frame")
titleBar.Size = UDim2.new(1,0,0,44)
titleBar.BackgroundColor3 = Color3.fromRGB(20,20,20)
titleBar.BorderSizePixel  = 0; titleBar.Parent = mainFrame
do local c=Instance.new("UICorner");c.CornerRadius=UDim.new(0,14);c.Parent=titleBar end

local titleLabel = Instance.new("TextLabel")
titleLabel.Size = UDim2.new(1,-70,1,0); titleLabel.Position=UDim2.new(0,14,0,0)
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

-- divider
local div = Instance.new("Frame")
div.Size=UDim2.new(1,-20,0,1); div.Position=UDim2.new(0,10,0,43)
div.BackgroundColor3=Color3.fromRGB(45,45,45); div.BorderSizePixel=0; div.Parent=mainFrame

-- status strip (shows remote found + ball count)
local statusBar = Instance.new("Frame")
statusBar.Size=UDim2.new(1,-10,0,26); statusBar.Position=UDim2.new(0,5,0,50)
statusBar.BackgroundColor3=Color3.fromRGB(20,20,20); statusBar.BorderSizePixel=0
statusBar.Parent=mainFrame
do local c=Instance.new("UICorner");c.CornerRadius=UDim.new(0,8);c.Parent=statusBar end

local statusText = Instance.new("TextLabel")
statusText.Size=UDim2.new(1,-10,1,0); statusText.Position=UDim2.new(0,8,0,0)
statusText.BackgroundTransparency=1
statusText.Text="⚡ Scanning for parry remote…"
statusText.TextColor3=Color3.fromRGB(180,180,180); statusText.Font=Enum.Font.Gotham
statusText.TextSize=10; statusText.TextXAlignment=Enum.TextXAlignment.Left
statusText.Parent=statusBar

-- toggle factory
local function makeToggle(yPos, label, icon, initState, onColor, offColor, onToggle)
    local row = Instance.new("Frame")
    row.Size=UDim2.new(1,-10,0,46); row.Position=UDim2.new(0,5,0,yPos)
    row.BackgroundColor3=Color3.fromRGB(22,22,22); row.BorderSizePixel=0
    row.Parent=mainFrame
    do local c=Instance.new("UICorner");c.CornerRadius=UDim.new(0,10);c.Parent=row end

    local lbl = Instance.new("TextLabel")
    lbl.Size=UDim2.new(1,-70,0,22); lbl.Position=UDim2.new(0,12,0,5)
    lbl.BackgroundTransparency=1; lbl.Text=icon.." "..label
    lbl.TextColor3=Color3.fromRGB(255,255,255); lbl.Font=Enum.Font.GothamBold
    lbl.TextSize=13; lbl.TextXAlignment=Enum.TextXAlignment.Left; lbl.Parent=row

    local sub = Instance.new("TextLabel")
    sub.Size=UDim2.new(1,-70,0,14); sub.Position=UDim2.new(0,12,0,27)
    sub.BackgroundTransparency=1; sub.Text=initState and "Enabled" or "Disabled"
    sub.TextColor3=initState and Color3.fromRGB(100,220,120) or Color3.fromRGB(150,150,150)
    sub.Font=Enum.Font.Gotham; sub.TextSize=10; sub.TextXAlignment=Enum.TextXAlignment.Left
    sub.Parent=row

    local pill = Instance.new("TextButton")
    pill.Size=UDim2.new(0,52,0,26); pill.Position=UDim2.new(1,-60,0.5,-13)
    pill.BackgroundColor3=initState and onColor or offColor
    pill.BorderSizePixel=0; pill.Text=initState and "ON" or "OFF"
    pill.TextColor3=Color3.fromRGB(255,255,255); pill.Font=Enum.Font.GothamBold
    pill.TextSize=11; pill.Parent=row
    do local c=Instance.new("UICorner");c.CornerRadius=UDim.new(0,13);c.Parent=pill end

    local state = initState
    local function toggle()
        state = not state
        pill.Text = state and "ON" or "OFF"
        pill.BackgroundColor3 = state and onColor or offColor
        sub.Text = state and "Enabled" or "Disabled"
        sub.TextColor3 = state and Color3.fromRGB(100,220,120) or Color3.fromRGB(150,150,150)
        TweenService:Create(pill, TweenInfo.new(0.15),
            {BackgroundColor3 = state and onColor or offColor}):Play()
        onToggle(state)
    end
    pill.MouseButton1Click:Connect(toggle)
    row.MouseButton1Click:Connect(toggle)

    return row, pill, sub
end

-- parry distance display + buttons
local distRow = Instance.new("Frame")
distRow.Size=UDim2.new(1,-10,0,46); distRow.Position=UDim2.new(0,5,0,82)
distRow.BackgroundColor3=Color3.fromRGB(22,22,22); distRow.BorderSizePixel=0
distRow.Parent=mainFrame
do local c=Instance.new("UICorner");c.CornerRadius=UDim.new(0,10);c.Parent=distRow end

local distLabel = Instance.new("TextLabel")
distLabel.Size=UDim2.new(1,-120,0,22); distLabel.Position=UDim2.new(0,12,0,5)
distLabel.BackgroundTransparency=1; distLabel.Text="🎯 Parry Distance"
distLabel.TextColor3=Color3.fromRGB(255,255,255); distLabel.Font=Enum.Font.GothamBold
distLabel.TextSize=13; distLabel.TextXAlignment=Enum.TextXAlignment.Left; distLabel.Parent=distRow

local distVal = Instance.new("TextLabel")
distVal.Size=UDim2.new(1,-120,0,14); distVal.Position=UDim2.new(0,12,0,27)
distVal.BackgroundTransparency=1; distVal.Text=cfg.ParryDist.." studs"
distVal.TextColor3=Color3.fromRGB(180,180,180); distVal.Font=Enum.Font.Gotham
distVal.TextSize=10; distVal.TextXAlignment=Enum.TextXAlignment.Left; distVal.Parent=distRow

local decBtn = Instance.new("TextButton")
decBtn.Size=UDim2.new(0,28,0,28); decBtn.Position=UDim2.new(1,-110,0.5,-14)
decBtn.BackgroundColor3=Color3.fromRGB(40,40,40); decBtn.BorderSizePixel=0
decBtn.Text="−"; decBtn.TextColor3=Color3.fromRGB(255,255,255)
decBtn.Font=Enum.Font.GothamBold; decBtn.TextSize=16; decBtn.Parent=distRow
do local c=Instance.new("UICorner");c.CornerRadius=UDim.new(0,8);c.Parent=decBtn end

local distNum = Instance.new("TextLabel")
distNum.Size=UDim2.new(0,32,0,28); distNum.Position=UDim2.new(1,-80,0.5,-14)
distNum.BackgroundTransparency=1; distNum.Text=tostring(cfg.ParryDist)
distNum.TextColor3=Color3.fromRGB(255,255,255); distNum.Font=Enum.Font.GothamBold
distNum.TextSize=14; distNum.TextXAlignment=Enum.TextXAlignment.Center; distNum.Parent=distRow

local incBtn = Instance.new("TextButton")
incBtn.Size=UDim2.new(0,28,0,28); incBtn.Position=UDim2.new(1,-46,0.5,-14)
incBtn.BackgroundColor3=Color3.fromRGB(40,40,40); incBtn.BorderSizePixel=0
incBtn.Text="+"; incBtn.TextColor3=Color3.fromRGB(255,255,255)
incBtn.Font=Enum.Font.GothamBold; incBtn.TextSize=16; incBtn.Parent=distRow
do local c=Instance.new("UICorner");c.CornerRadius=UDim.new(0,8);c.Parent=incBtn end

decBtn.MouseButton1Click:Connect(function()
    cfg.ParryDist = math.max(5, cfg.ParryDist - 5)
    distNum.Text = tostring(cfg.ParryDist)
    distVal.Text = cfg.ParryDist.." studs"
end)
incBtn.MouseButton1Click:Connect(function()
    cfg.ParryDist = math.min(80, cfg.ParryDist + 5)
    distNum.Text = tostring(cfg.ParryDist)
    distVal.Text = cfg.ParryDist.." studs"
end)

-- Toggles (stacked below the distance row)
makeToggle(134, "Auto Parry",    "🛡️",  cfg.AutoParry,   Color3.fromRGB(52,152,219),  Color3.fromRGB(50,50,50), function(v) cfg.AutoParry = v end)
makeToggle(186, "Ball ESP",      "🔴",  cfg.BallESP,     Color3.fromRGB(231,76,60),   Color3.fromRGB(50,50,50), function(v)
    cfg.BallESP = v
    -- refresh highlights
    for ball, entry in pairs(activeBalls) do
        removeESP(entry)
        if v then entry.highlight = addESP(ball) end
    end
end)
makeToggle(238, "Auto Dodge",    "💨",  cfg.AutoDodge,   Color3.fromRGB(46,204,113),  Color3.fromRGB(50,50,50), function(v) cfg.AutoDodge = v end)
makeToggle(290, "Prediction",    "🔮",  cfg.Prediction,  Color3.fromRGB(155,89,182),  Color3.fromRGB(50,50,50), function(v) cfg.Prediction = v end)

-- live ball counter at bottom
local ballCountLabel = Instance.new("TextLabel")
ballCountLabel.Size=UDim2.new(1,-10,0,18); ballCountLabel.Position=UDim2.new(0,5,1,-24)
ballCountLabel.BackgroundTransparency=1; ballCountLabel.Text="Active balls: 0"
ballCountLabel.TextColor3=Color3.fromRGB(100,100,100); ballCountLabel.Font=Enum.Font.Gotham
ballCountLabel.TextSize=10; ballCountLabel.Parent=mainFrame

-- ──────────────────────────────────────────────────────────────
--  STATUS UPDATER
-- ──────────────────────────────────────────────────────────────
task.spawn(function()
    while task.wait(0.5) do
        if not screenGui.Parent then break end

        -- try to find parry remote if still missing
        if not ParryRemote and Remotes then
            for _, name in ipairs({"Parry","Deflect","Block","Reflect","Swing","Hit","Slash"}) do
                local r = Remotes:FindFirstChild(name)
                if r then ParryRemote = r; break end
            end
        end

        local remoteStatus = ParryRemote
            and ("✅ Remote: " .. ParryRemote.Name)
            or  "⚠️  Parry remote not found"

        local count = 0
        for _ in pairs(activeBalls) do count = count + 1 end

        statusText.Text = remoteStatus .. "  |  " .. count .. " ball(s)"
        ballCountLabel.Text = "Active balls: " .. count

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
    if minimized then
        mainFrame.Size = UDim2.new(0, 280, 0, 44)
        minBtn.Text = "+"
    else
        mainFrame.Size = UDim2.new(0, 280, 0, 380)
        minBtn.Text = "−"
    end
end)

closeBtn.MouseButton1Click:Connect(function()
    screenGui:Destroy()
end)

-- ──────────────────────────────────────────────────────────────
--  KEYBOARD SHORTCUTS
-- ──────────────────────────────────────────────────────────────
UserInputService.InputBegan:Connect(function(input, gp)
    if gp then return end
    if input.KeyCode == Enum.KeyCode.P then
        cfg.AutoParry = not cfg.AutoParry
    elseif input.KeyCode == Enum.KeyCode.O then
        cfg.BallESP = not cfg.BallESP
    elseif input.KeyCode == Enum.KeyCode.L then
        cfg.AutoDodge = not cfg.AutoDodge
    end
end)

-- ──────────────────────────────────────────────────────────────
--  DONE
-- ──────────────────────────────────────────────────────────────
print("[BladeBall Hub] Loaded. Parry remote: " .. (ParryRemote and ParryRemote.Name or "not found yet"))
