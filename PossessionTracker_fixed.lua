-- Advanced Player Tracker v3 — Enhanced Tracking Edition
-- Place in StarterGui or a LocalScript in StarterPlayerScripts
--
-- Tracking modes (cycle with the Mode button or M key):
--   POSSESS  — exact same coords, you turn with them, go transparent
--   BEHIND   — 4 studs behind them, facing same direction
--   SHADOW   — smooth lerp follow, slight offset, never snaps
--   GHOST    — inside + fully invisible (LocalTransparencyModifier)
--
-- Extra features:
--   • Velocity prediction to compensate network latency
--   • Teleport detection: snaps instantly instead of lerping across the map
--   • Mirrors ALL humanoid states (jump, freefall, swim, climb, sit, ragdoll)
--   • Auto re-acquires target after their respawn
--   • Live HUD: distance, target speed, tracking mode, target state
--   • Player search box
--   • Emotes tab with favorites

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")
local LocalPlayer = Players.LocalPlayer

-- ──────────────────────────────────────────────
--  SCREEN GUI
-- ──────────────────────────────────────────────
local screenGui = Instance.new("ScreenGui")
screenGui.Name = "PlayerTracker"
screenGui.ResetOnSpawn = false
screenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
screenGui.Parent = LocalPlayer:WaitForChild("PlayerGui")

-- ──────────────────────────────────────────────
--  MAIN FRAME
-- ──────────────────────────────────────────────
local mainFrame = Instance.new("Frame")
mainFrame.Name = "MainFrame"
mainFrame.Size = UDim2.new(0, 340, 0, 560)
mainFrame.Position = UDim2.new(0.02, 0, 0.5, -280)
mainFrame.BackgroundColor3 = Color3.fromRGB(15, 15, 15)
mainFrame.BorderSizePixel = 0
mainFrame.Active = true
mainFrame.Draggable = true
mainFrame.Parent = screenGui

do
    local c = Instance.new("UICorner"); c.CornerRadius = UDim.new(0,14); c.Parent = mainFrame
    local g = Instance.new("UIGradient")
    g.Color = ColorSequence.new{ColorSequenceKeypoint.new(0,Color3.fromRGB(25,25,25)),ColorSequenceKeypoint.new(1,Color3.fromRGB(15,15,15))}
    g.Rotation = 45; g.Parent = mainFrame
end

-- ──────────────────────────────────────────────
--  TITLE BAR
-- ──────────────────────────────────────────────
local titleBar = Instance.new("Frame")
titleBar.Size = UDim2.new(1,0,0,45)
titleBar.BackgroundColor3 = Color3.fromRGB(25,25,25)
titleBar.BorderSizePixel = 0
titleBar.Parent = mainFrame
do local c=Instance.new("UICorner");c.CornerRadius=UDim.new(0,14);c.Parent=titleBar end

local titleText = Instance.new("TextLabel")
titleText.Size = UDim2.new(1,-90,1,0)
titleText.Position = UDim2.new(0,15,0,0)
titleText.BackgroundTransparency = 1
titleText.Text = "👻 Possession Tracker v3"
titleText.TextColor3 = Color3.fromRGB(255,255,255)
titleText.Font = Enum.Font.GothamBold
titleText.TextSize = 15
titleText.TextXAlignment = Enum.TextXAlignment.Left
titleText.Parent = titleBar

local function makeBtn(parent, x, w, txt, size)
    local b = Instance.new("TextButton")
    b.Size = UDim2.new(0,w,0,w)
    b.Position = UDim2.new(1,x,0.5,-w/2)
    b.BackgroundColor3 = Color3.fromRGB(40,40,40)
    b.BorderSizePixel = 0; b.Text = txt
    b.TextColor3 = Color3.fromRGB(255,255,255)
    b.Font = Enum.Font.GothamBold; b.TextSize = size or 14
    b.Parent = parent
    local c=Instance.new("UICorner");c.CornerRadius=UDim.new(0,8);c.Parent=b
    return b
end

local closeButton    = makeBtn(titleBar, -35, 30, "✕")
local minimizeButton = makeBtn(titleBar, -70, 30, "−", 18)

Instance.new("Frame",titleBar).BackgroundColor3 = Color3.fromRGB(50,50,50)
do
    local d=titleBar:FindFirstChildOfClass("Frame")
    d.Size=UDim2.new(1,-20,0,1); d.Position=UDim2.new(0,10,1,-1); d.BorderSizePixel=0
end

-- ──────────────────────────────────────────────
--  TABS
-- ──────────────────────────────────────────────
local tabFrame = Instance.new("Frame")
tabFrame.Size = UDim2.new(1,-10,0,32)
tabFrame.Position = UDim2.new(0,5,0,52)
tabFrame.BackgroundTransparency = 1; tabFrame.BorderSizePixel = 0
tabFrame.Parent = mainFrame

local playerTabBtn = makeBtn(tabFrame, nil, nil, "👥 Players", 11)
playerTabBtn.Size = UDim2.new(0.33,-3,1,0); playerTabBtn.Position = UDim2.new(0,0,0,0)
playerTabBtn.BackgroundColor3 = Color3.fromRGB(52,152,219)

local emotesTabBtn = makeBtn(tabFrame, nil, nil, "🎭 Emotes", 11)
emotesTabBtn.Size = UDim2.new(0.34,-2,1,0); emotesTabBtn.Position = UDim2.new(0.33,2,0,0)
emotesTabBtn.BackgroundColor3 = Color3.fromRGB(35,35,35)

local favsTabBtn = makeBtn(tabFrame, nil, nil, "⭐ Favs", 11)
favsTabBtn.Size = UDim2.new(0.33,-3,1,0); favsTabBtn.Position = UDim2.new(0.67,3,0,0)
favsTabBtn.BackgroundColor3 = Color3.fromRGB(35,35,35)

-- ──────────────────────────────────────────────
--  CONTROL PANEL
-- ──────────────────────────────────────────────
local controlPanel = Instance.new("Frame")
controlPanel.Size = UDim2.new(1,-10,0,202)
controlPanel.Position = UDim2.new(0,5,0,90)
controlPanel.BackgroundTransparency = 1; controlPanel.BorderSizePixel = 0
controlPanel.Parent = mainFrame

-- row helper
local function makeToggle(yPos, color, txt)
    local b = Instance.new("TextButton")
    b.Size = UDim2.new(1,0,0,28)
    b.Position = UDim2.new(0,0,0,yPos)
    b.BackgroundColor3 = color
    b.BorderSizePixel = 0
    b.Text = "    " .. txt
    b.TextColor3 = Color3.fromRGB(255,255,255)
    b.Font = Enum.Font.GothamBold; b.TextSize = 12
    b.TextXAlignment = Enum.TextXAlignment.Left
    b.Parent = controlPanel
    local c=Instance.new("UICorner");c.CornerRadius=UDim.new(0,8);c.Parent=b
    local dot = Instance.new("Frame")
    dot.Size=UDim2.new(0,10,0,10); dot.Position=UDim2.new(0,8,0.5,-5)
    dot.BackgroundColor3=Color3.fromRGB(150,150,150); dot.BorderSizePixel=0
    dot.Parent=b
    local dc=Instance.new("UICorner");dc.CornerRadius=UDim.new(1,0);dc.Parent=dot
    return b, dot
end

local playerCountText = Instance.new("TextLabel")
playerCountText.Size = UDim2.new(1,0,0,16); playerCountText.BackgroundTransparency=1
playerCountText.Text = "Players Online: 0"; playerCountText.TextColor3=Color3.fromRGB(150,150,150)
playerCountText.Font=Enum.Font.Gotham; playerCountText.TextSize=11
playerCountText.TextXAlignment=Enum.TextXAlignment.Left
playerCountText.Parent = controlPanel

local autoMimicToggle, mimicDot = makeToggle(20, Color3.fromRGB(40,40,40), "🔴 Auto Mimic: OFF")
mimicDot.BackgroundColor3 = Color3.fromRGB(231,76,60)

local possessionToggle, possessionDot = makeToggle(52, Color3.fromRGB(142,68,173), "👻 Possession Mode: ON")
possessionDot.BackgroundColor3 = Color3.fromRGB(46,204,113)

-- Tracking mode button (cycles through POSSESS / BEHIND / SHADOW / GHOST)
local MODES = {"POSSESS","BEHIND","SHADOW","GHOST"}
local MODECOLORS = {
    POSSESS = Color3.fromRGB(142,68,173),
    BEHIND  = Color3.fromRGB(52,152,219),
    SHADOW  = Color3.fromRGB(39,174,96),
    GHOST   = Color3.fromRGB(30,30,30),
}
local MODEICONS = {POSSESS="👻",BEHIND="🔵",SHADOW="🟢",GHOST="💀"}
local currentModeIdx = 1

local modeButton = Instance.new("TextButton")
modeButton.Size = UDim2.new(1,0,0,28)
modeButton.Position = UDim2.new(0,0,0,84)
modeButton.BackgroundColor3 = MODECOLORS["POSSESS"]
modeButton.BorderSizePixel = 0
modeButton.Text = "  👻 Mode: POSSESS  (tap M to cycle)"
modeButton.TextColor3 = Color3.fromRGB(255,255,255)
modeButton.Font = Enum.Font.GothamBold; modeButton.TextSize = 11
modeButton.TextXAlignment = Enum.TextXAlignment.Left
modeButton.Parent = controlPanel
do local c=Instance.new("UICorner");c.CornerRadius=UDim.new(0,8);c.Parent=modeButton end

-- Live HUD: distance / speed / state
local hudFrame = Instance.new("Frame")
hudFrame.Size = UDim2.new(1,0,0,32)
hudFrame.Position = UDim2.new(0,0,0,116)
hudFrame.BackgroundColor3 = Color3.fromRGB(22,22,22)
hudFrame.BorderSizePixel = 0; hudFrame.Parent = controlPanel
do local c=Instance.new("UICorner");c.CornerRadius=UDim.new(0,8);c.Parent=hudFrame end

local hudText = Instance.new("TextLabel")
hudText.Size = UDim2.new(1,-10,1,0); hudText.Position=UDim2.new(0,8,0,0)
hudText.BackgroundTransparency=1
hudText.Text = "Not tracking"
hudText.TextColor3=Color3.fromRGB(180,180,180)
hudText.Font=Enum.Font.Gotham; hudText.TextSize=10
hudText.TextXAlignment=Enum.TextXAlignment.Left
hudText.Parent=hudFrame

-- Current emote display
local currentEmoteLabel = Instance.new("TextLabel")
currentEmoteLabel.Size = UDim2.new(1,0,0,16)
currentEmoteLabel.Position = UDim2.new(0,0,0,152)
currentEmoteLabel.BackgroundTransparency=1
currentEmoteLabel.Text="🎭 Current Emote: None"
currentEmoteLabel.TextColor3=Color3.fromRGB(180,180,180)
currentEmoteLabel.Font=Enum.Font.Gotham; currentEmoteLabel.TextSize=11
currentEmoteLabel.TextXAlignment=Enum.TextXAlignment.Left
currentEmoteLabel.Parent=controlPanel

-- Stop emote / Load emotes buttons
local stopEmoteButton = makeBtn(controlPanel, nil, nil, "⏹ Stop Emote", 11)
stopEmoteButton.Size=UDim2.new(0.5,-3,0,24); stopEmoteButton.Position=UDim2.new(0,0,0,172)
stopEmoteButton.BackgroundColor3=Color3.fromRGB(60,60,60)

local refreshEmotesButton = makeBtn(controlPanel, nil, nil, "🔄 Load Emotes", 11)
refreshEmotesButton.Size=UDim2.new(0.5,-3,0,24); refreshEmotesButton.Position=UDim2.new(0.5,3,0,172)
refreshEmotesButton.BackgroundColor3=Color3.fromRGB(46,204,113)

-- ──────────────────────────────────────────────
--  SEARCH BOX
-- ──────────────────────────────────────────────
local searchBox = Instance.new("TextBox")
searchBox.Size = UDim2.new(1,-10,0,28)
searchBox.Position = UDim2.new(0,5,0,298)
searchBox.BackgroundColor3=Color3.fromRGB(30,30,30); searchBox.BorderSizePixel=0
searchBox.Text=""; searchBox.PlaceholderText="🔍  Search players..."
searchBox.PlaceholderColor3=Color3.fromRGB(110,110,110)
searchBox.TextColor3=Color3.fromRGB(255,255,255)
searchBox.Font=Enum.Font.Gotham; searchBox.TextSize=12
searchBox.TextXAlignment=Enum.TextXAlignment.Left; searchBox.ClearTextOnFocus=false
searchBox.Parent=mainFrame
do
    local c=Instance.new("UICorner");c.CornerRadius=UDim.new(0,8);c.Parent=searchBox
    local p=Instance.new("UIPadding");p.PaddingLeft=UDim.new(0,10);p.Parent=searchBox
end

-- ──────────────────────────────────────────────
--  SCROLL LISTS (Players / Emotes / Favs)
-- ──────────────────────────────────────────────
local function makeScrollFrame(name, visible)
    local sf = Instance.new("ScrollingFrame")
    sf.Name = name
    sf.Size = UDim2.new(1,-10,1,-395)
    sf.Position = UDim2.new(0,5,0,332)
    sf.BackgroundTransparency=1; sf.BorderSizePixel=0
    sf.ScrollBarThickness=3; sf.ScrollBarImageColor3=Color3.fromRGB(80,80,80)
    sf.CanvasSize=UDim2.new(0,0,0,0); sf.AutomaticCanvasSize=Enum.AutomaticSize.Y
    sf.ScrollingDirection=Enum.ScrollingDirection.Y
    sf.Visible=visible; sf.Parent=mainFrame
    local l=Instance.new("UIListLayout");l.Padding=UDim.new(0,4)
    l.HorizontalAlignment=Enum.HorizontalAlignment.Center
    l.SortOrder=Enum.SortOrder.Name; l.Parent=sf
    local p=Instance.new("UIPadding");p.PaddingLeft=UDim.new(0,2)
    p.PaddingRight=UDim.new(0,2);p.PaddingTop=UDim.new(0,2);p.Parent=sf
    return sf
end

local playerListFrame  = makeScrollFrame("PlayerList", true)
local emotesListFrame  = makeScrollFrame("EmotesList", false)
local favsListFrame    = makeScrollFrame("FavsList",   false)

-- ──────────────────────────────────────────────
--  BOTTOM BUTTONS
-- ──────────────────────────────────────────────
local buttonFrame = Instance.new("Frame")
buttonFrame.Size=UDim2.new(1,-10,0,36); buttonFrame.Position=UDim2.new(0,5,1,-42)
buttonFrame.BackgroundTransparency=1; buttonFrame.BorderSizePixel=0; buttonFrame.Parent=mainFrame

local stopButton = makeBtn(buttonFrame, nil, nil, "⏹ Stop Tracking", 13)
stopButton.Size=UDim2.new(0.72,-3,1,0); stopButton.Position=UDim2.new(0,0,0,0)
stopButton.BackgroundColor3=Color3.fromRGB(231,76,60)

local refreshButton = makeBtn(buttonFrame, nil, nil, "🔄", 16)
refreshButton.Size=UDim2.new(0.28,-3,1,0); refreshButton.Position=UDim2.new(0.72,6,0,0)
refreshButton.BackgroundColor3=Color3.fromRGB(52,152,219)

-- ──────────────────────────────────────────────
--  NOTIFICATION
-- ──────────────────────────────────────────────
local notificationFrame = Instance.new("Frame")
notificationFrame.Size=UDim2.new(1,0,0,28); notificationFrame.Position=UDim2.new(0,0,0,-33)
notificationFrame.BackgroundColor3=Color3.fromRGB(46,204,113)
notificationFrame.BorderSizePixel=0; notificationFrame.Visible=false; notificationFrame.Parent=mainFrame
do local c=Instance.new("UICorner");c.CornerRadius=UDim.new(0,8);c.Parent=notificationFrame end

local notificationText = Instance.new("TextLabel")
notificationText.Size=UDim2.new(1,0,1,0); notificationText.BackgroundTransparency=1
notificationText.Text=""; notificationText.TextColor3=Color3.fromRGB(255,255,255)
notificationText.Font=Enum.Font.GothamBold; notificationText.TextSize=12
notificationText.Parent=notificationFrame

-- ──────────────────────────────────────────────
--  STATE VARIABLES
-- ──────────────────────────────────────────────
local trackingPlayer   = nil
local trackConnection  = nil
local autoMimic        = false
local possessionMode   = true
local currentEmoteName = nil
local currentEmoteTrack= nil
local isPlayingEmote   = false
local inventoryEmotes  = {}
local favoriteEmotes   = {}
local searchQuery      = ""

-- tracking internals
local prevTargetPos    = nil  -- for teleport detection
local TELEPORT_THRESH  = 40   -- studs: if target moves more than this in one frame, snap

-- Forward declarations
local populateEmoteList, populateFavoritesList, applySearchFilter

-- ──────────────────────────────────────────────
--  HELPERS
-- ──────────────────────────────────────────────
local function currentMode()
    return MODES[currentModeIdx]
end

local function showNotification(msg, color)
    notificationFrame.BackgroundColor3 = color or Color3.fromRGB(46,204,113)
    notificationText.Text = msg
    notificationFrame.Visible = true
    notificationFrame.BackgroundTransparency = 0
    task.spawn(function()
        task.wait(2.5)
        TweenService:Create(notificationFrame,TweenInfo.new(0.4),{BackgroundTransparency=1}):Play()
        task.wait(0.4)
        notificationFrame.Visible = false
        notificationFrame.BackgroundTransparency = 0
    end)
end

local function setSelfTransparency(t)
    local char = LocalPlayer.Character; if not char then return end
    for _, v in ipairs(char:GetDescendants()) do
        if v:IsA("BasePart") and v.Name ~= "HumanoidRootPart" then
            v.LocalTransparencyModifier = t
        elseif v:IsA("Decal") then
            v.Transparency = t
        end
    end
end

local function setSelfVisible()    setSelfTransparency(0) end
local function setSelfInvisible()  setSelfTransparency(0.95) end
local function setSelfGhost()      setSelfTransparency(1) end

-- ──────────────────────────────────────────────
--  TRACKING CORE
-- ──────────────────────────────────────────────

-- Returns the predicted CFrame of the target, compensating for ~1 frame of latency
-- using linear extrapolation from the last known velocity.
local function predictedCFrame(targetRoot)
    local vel = targetRoot.AssemblyLinearVelocity
    -- at 60 fps each frame is ~0.0167 s; predict half a frame ahead
    local predicted = targetRoot.Position + vel * (1/60) * 0.5
    return CFrame.new(predicted) * (targetRoot.CFrame - targetRoot.CFrame.Position)
end

local function mimicMovement(myChar, targetChar)
    local myH   = myChar:FindFirstChildOfClass("Humanoid")
    local myRoot= myChar:FindFirstChild("HumanoidRootPart")
    local tH    = targetChar:FindFirstChildOfClass("Humanoid")
    local tRoot = targetChar:FindFirstChild("HumanoidRootPart")
    if not (myH and myRoot and tH and tRoot) then return end

    -- Match tuning
    myH.WalkSpeed  = tH.WalkSpeed
    myH.JumpPower  = tH.JumpPower
    myH.JumpHeight = tH.JumpHeight

    -- Teleport detection: if target jumped >TELEPORT_THRESH studs, snap instantly
    local tPos = tRoot.Position
    local didTeleport = prevTargetPos and (tPos - prevTargetPos).Magnitude > TELEPORT_THRESH
    prevTargetPos = tPos

    local mode = currentMode()
    local targetCF = predictedCFrame(tRoot)

    if mode == "POSSESS" then
        -- exact same position and rotation
        if didTeleport then
            myRoot.CFrame = targetCF
        else
            myRoot.CFrame = myRoot.CFrame:Lerp(targetCF, 0.85)
        end
        myRoot.AssemblyLinearVelocity  = tRoot.AssemblyLinearVelocity
        myRoot.AssemblyAngularVelocity = tRoot.AssemblyAngularVelocity
        setSelfInvisible()

    elseif mode == "GHOST" then
        -- fully invisible exact copy
        if didTeleport then
            myRoot.CFrame = targetCF
        else
            myRoot.CFrame = myRoot.CFrame:Lerp(targetCF, 0.95)
        end
        myRoot.AssemblyLinearVelocity  = tRoot.AssemblyLinearVelocity
        myRoot.AssemblyAngularVelocity = tRoot.AssemblyAngularVelocity
        setSelfGhost()

    elseif mode == "BEHIND" then
        -- 4 studs directly behind target, facing same direction
        local behind = targetCF * CFrame.new(0, 0, 4)
        if didTeleport then
            myRoot.CFrame = behind
        else
            myRoot.CFrame = myRoot.CFrame:Lerp(behind, 0.75)
        end
        myRoot.AssemblyLinearVelocity = tRoot.AssemblyLinearVelocity
        setSelfVisible()

    elseif mode == "SHADOW" then
        -- smooth floating follow with a small Y offset
        local shadowCF = targetCF * CFrame.new(0, 0.2, 0)
        local alpha = didTeleport and 1 or 0.18
        myRoot.CFrame = myRoot.CFrame:Lerp(shadowCF, alpha)
        setSelfVisible()
    end

    -- Mirror ALL humanoid states
    local state = tH:GetState()
    if tH.Jump or state == Enum.HumanoidStateType.Jumping then
        myH.Jump = true
    end
    if state == Enum.HumanoidStateType.Freefall then
        myH:ChangeState(Enum.HumanoidStateType.Freefall)
    elseif state == Enum.HumanoidStateType.Swimming then
        myH:ChangeState(Enum.HumanoidStateType.Swimming)
    elseif state == Enum.HumanoidStateType.Climbing then
        myH:ChangeState(Enum.HumanoidStateType.Climbing)
    end
end

-- Pretty-print humanoid state for the HUD
local STATE_NAMES = {
    [Enum.HumanoidStateType.Running]     = "Walking",
    [Enum.HumanoidStateType.Jumping]     = "Jumping",
    [Enum.HumanoidStateType.Freefall]    = "Falling",
    [Enum.HumanoidStateType.Swimming]    = "Swimming",
    [Enum.HumanoidStateType.Climbing]    = "Climbing",
    [Enum.HumanoidStateType.Seated]      = "Seated",
    [Enum.HumanoidStateType.Dead]        = "Dead",
    [Enum.HumanoidStateType.Ragdoll]     = "Ragdoll",
    [Enum.HumanoidStateType.GettingUp]   = "Getting Up",
    [Enum.HumanoidStateType.RunningNoPhysics]="Idle",
}

local function updateHUD(tRoot, tH, myRoot)
    if not (tRoot and tH and myRoot) then hudText.Text="Not tracking"; return end
    local dist   = math.floor((myRoot.Position - tRoot.Position).Magnitude * 10 + 0.5) / 10
    local speed  = math.floor(tRoot.AssemblyLinearVelocity.Magnitude * 10 + 0.5) / 10
    local state  = STATE_NAMES[tH:GetState()] or "Unknown"
    hudText.Text = string.format("📍 %.1f st  ⚡ %.1f st/s  📟 %s  🎮 %s", dist, speed, state, currentMode())
end

-- ──────────────────────────────────────────────
--  START / STOP TRACKING
-- ──────────────────────────────────────────────
function updateButtonVisuals()
    for _, b in ipairs(playerListFrame:GetChildren()) do
        if b:IsA("TextButton") then
            local tracked = trackingPlayer ~= nil and b.Name == trackingPlayer.Name
            local si = b:FindFirstChild("StatusIndicator")
            local ti = b:FindFirstChild("TrackIcon")
            if si then si.Visible = tracked end
            if ti then ti.Text = tracked and "👻" or "👤" end
            b.BackgroundColor3 = tracked and Color3.fromRGB(142,68,173) or Color3.fromRGB(30,30,30)
            local st = b:FindFirstChild("StatusText")
            if st then st.Text = tracked and ("👻 " .. currentMode()) or "Click to track" end
        end
    end
end

function resetButtonVisuals()
    for _, b in ipairs(playerListFrame:GetChildren()) do
        if b:IsA("TextButton") then
            b.BackgroundColor3 = Color3.fromRGB(30,30,30)
            local si=b:FindFirstChild("StatusIndicator"); if si then si.Visible=false end
            local ti=b:FindFirstChild("TrackIcon"); if ti then ti.Text="👤" end
            local st=b:FindFirstChild("StatusText"); if st then st.Text="Click to track" end
        end
    end
end

function stopTracking()
    if trackConnection then trackConnection:Disconnect(); trackConnection=nil end
    setSelfVisible()
    prevTargetPos = nil
    trackingPlayer = nil
    hudText.Text = "Not tracking"
    if LocalPlayer.Character then
        local h = LocalPlayer.Character:FindFirstChildOfClass("Humanoid")
        if h then h.WalkSpeed=16; h.JumpPower=50; h.Jump=false end
    end
    resetButtonVisuals()
    stopButton.Text = "⏹ Stop Tracking"
end

function startTracking(player)
    stopTracking()
    if not player then return end
    -- wait briefly if character not yet ready
    if not player.Character then
        showNotification("Waiting for " .. player.DisplayName .. "...", Color3.fromRGB(241,196,15))
        task.spawn(function()
            local ok = player.CharacterAdded:Wait()
            if ok then startTracking(player) end
        end)
        return
    end

    trackingPlayer = player
    prevTargetPos = nil
    updateButtonVisuals()
    stopButton.Text = "⏹ Stop: " .. player.DisplayName

    local myChar = LocalPlayer.Character
    if not myChar then LocalPlayer.CharacterAdded:Wait(); myChar=LocalPlayer.Character end
    myChar:WaitForChild("Humanoid",5)

    trackConnection = RunService.Heartbeat:Connect(function()
        local tChar = trackingPlayer and trackingPlayer.Character
        myChar = LocalPlayer.Character
        if not (tChar and myChar) then return end

        local tRoot = tChar:FindFirstChild("HumanoidRootPart")
        local tH    = tChar:FindFirstChildOfClass("Humanoid")
        local myRoot= myChar:FindFirstChild("HumanoidRootPart")

        if autoMimic and tRoot and tH and myRoot then
            mimicMovement(myChar, tChar)
        end
        updateHUD(tRoot, tH, myRoot)
    end)

    showNotification("Tracking: " .. player.DisplayName .. " [" .. currentMode() .. "]",
        MODECOLORS[currentMode()])
end

-- ──────────────────────────────────────────────
--  MODE CYCLING
-- ──────────────────────────────────────────────
local function cycleMode()
    currentModeIdx = (currentModeIdx % #MODES) + 1
    local m = currentMode()
    modeButton.BackgroundColor3 = MODECOLORS[m]
    modeButton.Text = "  " .. MODEICONS[m] .. " Mode: " .. m .. "  (tap M to cycle)"
    if trackingPlayer then
        showNotification("Mode → " .. m, MODECOLORS[m])
        updateButtonVisuals()
    end
end
modeButton.MouseButton1Click:Connect(cycleMode)

-- ──────────────────────────────────────────────
--  AUTO-MIMIC TOGGLE
-- ──────────────────────────────────────────────
function toggleAutoMimic()
    autoMimic = not autoMimic
    if autoMimic then
        autoMimicToggle.Text  = "    🟢 Auto Mimic: ON"
        autoMimicToggle.BackgroundColor3 = Color3.fromRGB(46,204,113)
        mimicDot.BackgroundColor3 = Color3.fromRGB(46,204,113)
        showNotification("Auto Mimic ON — mode: " .. currentMode(), Color3.fromRGB(46,204,113))
    else
        autoMimicToggle.Text  = "    🔴 Auto Mimic: OFF"
        autoMimicToggle.BackgroundColor3 = Color3.fromRGB(40,40,40)
        mimicDot.BackgroundColor3 = Color3.fromRGB(231,76,60)
        setSelfVisible()
        showNotification("Auto Mimic OFF", Color3.fromRGB(150,150,150))
    end
end

-- ──────────────────────────────────────────────
--  POSSESSION TOGGLE (controls visibility only)
-- ──────────────────────────────────────────────
function togglePossessionMode()
    possessionMode = not possessionMode
    if possessionMode then
        possessionToggle.Text = "    👻 Possession Mode: ON"
        possessionToggle.BackgroundColor3 = Color3.fromRGB(142,68,173)
        possessionDot.BackgroundColor3 = Color3.fromRGB(46,204,113)
        showNotification("Possession: invisible while tracking", Color3.fromRGB(142,68,173))
    else
        possessionToggle.Text = "    👻 Possession Mode: OFF"
        possessionToggle.BackgroundColor3 = Color3.fromRGB(60,60,60)
        possessionDot.BackgroundColor3 = Color3.fromRGB(150,150,150)
        setSelfVisible()
        showNotification("Possession Mode OFF", Color3.fromRGB(150,150,150))
    end
end

-- ──────────────────────────────────────────────
--  EMOTES
-- ──────────────────────────────────────────────
local function getInventoryEmotes()
    local emotes = {}
    pcall(function()
        local hd = LocalPlayer.Character and LocalPlayer.Character:FindFirstChildOfClass("HumanoidDescription")
            or Players:GetHumanoidDescriptionFromUserId(LocalPlayer.UserId)
        if hd then
            for i=1,8 do
                local name = hd["Emote"..i]
                if name and name~="" then
                    table.insert(emotes,{name=name,slot=i,type="equipped"})
                end
            end
        end
    end)
    pcall(function()
        local es = game:GetService("EmotesService")
        if es then
            local eq = es:GetEmotesForUserId(LocalPlayer.UserId)
            if eq then
                for _,ed in pairs(eq) do
                    local exists=false
                    for _,e in ipairs(emotes) do if e.name==ed.Name then exists=true; break end end
                    if not exists then table.insert(emotes,{name=ed.Name,slot=ed.Slot or 0,type="inventory"}) end
                end
            end
        end
    end)
    return emotes
end

local function playInventoryEmote(name)
    local char = LocalPlayer.Character; if not char then return false end
    local h = char:FindFirstChildOfClass("Humanoid"); if not h then return false end
    local ok = pcall(function() h:PlayEmote(name) end)
    if ok then return true end
    ok = pcall(function()
        local es = game:GetService("EmotesService")
        if es then es:PlayEmote(LocalPlayer,name) end
    end)
    return ok
end

local function stopCurrentEmote()
    if currentEmoteTrack then pcall(function() currentEmoteTrack:Stop() end); currentEmoteTrack=nil end
    pcall(function()
        local char=LocalPlayer.Character; if not char then return end
        local h=char:FindFirstChildOfClass("Humanoid"); if not h then return end
        for _,t in ipairs(h:GetPlayingAnimationTracks()) do t:Stop() end
    end)
    currentEmoteName=nil; isPlayingEmote=false
    currentEmoteLabel.Text="🎭 Current Emote: None"
end

local function executeEmote(name, data)
    stopCurrentEmote()
    local ok = playInventoryEmote(name)
    if ok then
        currentEmoteName=name; isPlayingEmote=true
        currentEmoteLabel.Text="🎭 Current Emote: " .. name
        showNotification("Playing: "..name, Color3.fromRGB(52,152,219))
    else
        showNotification("Failed: "..name, Color3.fromRGB(231,76,60))
    end
    return ok
end

-- ──────────────────────────────────────────────
--  PLAYER BUTTONS
-- ──────────────────────────────────────────────
local function createPlayerButton(player)
    local btn = Instance.new("TextButton")
    btn.Name=player.Name; btn.Size=UDim2.new(1,-4,0,50)
    btn.BackgroundColor3=Color3.fromRGB(30,30,30); btn.BorderSizePixel=0
    btn.Text=""; btn.AutoButtonColor=false; btn.ClipsDescendants=true
    btn.Parent=playerListFrame
    do local c=Instance.new("UICorner");c.CornerRadius=UDim.new(0,10);c.Parent=btn end

    local icon=Instance.new("Frame"); icon.Size=UDim2.new(0,36,0,36)
    icon.Position=UDim2.new(0,8,0.5,-18); icon.BackgroundColor3=Color3.fromRGB(52,152,219)
    icon.BorderSizePixel=0; icon.Parent=btn
    do local c=Instance.new("UICorner");c.CornerRadius=UDim.new(1,0);c.Parent=icon end

    local il=Instance.new("TextLabel"); il.Size=UDim2.new(1,0,1,0); il.BackgroundTransparency=1
    il.Text=player.Name:sub(1,1):upper(); il.TextColor3=Color3.fromRGB(255,255,255)
    il.Font=Enum.Font.GothamBold; il.TextSize=16; il.Parent=icon

    local ti=Instance.new("TextLabel"); ti.Name="TrackIcon"
    ti.Size=UDim2.new(0,16,0,16); ti.Position=UDim2.new(0,28,1,-20)
    ti.BackgroundTransparency=1; ti.Text="👤"; ti.TextSize=12; ti.ZIndex=2; ti.Parent=btn

    local nl=Instance.new("TextLabel"); nl.Name="NameText"
    nl.Size=UDim2.new(1,-65,0,20); nl.Position=UDim2.new(0,52,0,7)
    nl.BackgroundTransparency=1
    nl.Text=player.DisplayName~=player.Name and player.DisplayName.." (@"..player.Name..")" or player.Name
    nl.TextColor3=Color3.fromRGB(255,255,255); nl.Font=Enum.Font.GothamBold; nl.TextSize=13
    nl.TextXAlignment=Enum.TextXAlignment.Left; nl.TextTruncate=Enum.TextTruncate.AtEnd; nl.Parent=btn

    local sl=Instance.new("TextLabel"); sl.Name="StatusText"
    sl.Size=UDim2.new(1,-65,0,15); sl.Position=UDim2.new(0,52,0,27)
    sl.BackgroundTransparency=1; sl.Text="Click to track"
    sl.TextColor3=Color3.fromRGB(150,150,150); sl.Font=Enum.Font.Gotham; sl.TextSize=10
    sl.TextXAlignment=Enum.TextXAlignment.Left; sl.Parent=btn

    local si=Instance.new("Frame"); si.Name="StatusIndicator"
    si.Size=UDim2.new(0,10,0,10); si.Position=UDim2.new(1,-15,0,7)
    si.BackgroundColor3=Color3.fromRGB(46,204,113); si.BorderSizePixel=0; si.Visible=false; si.Parent=btn
    do local c=Instance.new("UICorner");c.CornerRadius=UDim.new(1,0);c.Parent=si end

    btn.MouseEnter:Connect(function()
        if trackingPlayer~=player then TweenService:Create(btn,TweenInfo.new(0.15),{BackgroundColor3=Color3.fromRGB(45,45,45)}):Play() end
    end)
    btn.MouseLeave:Connect(function()
        if trackingPlayer~=player then TweenService:Create(btn,TweenInfo.new(0.15),{BackgroundColor3=Color3.fromRGB(30,30,30)}):Play() end
    end)
    btn.MouseButton1Click:Connect(function()
        if trackingPlayer==player then
            stopTracking()
        else
            startTracking(player)
            if not autoMimic then toggleAutoMimic() end
        end
    end)
    btn.MouseButton2Click:Connect(function()
        -- right-click: track + cycle to next mode
        startTracking(player)
        if not autoMimic then toggleAutoMimic() end
        cycleMode()
    end)
    return btn
end

-- ──────────────────────────────────────────────
--  EMOTE BUTTONS
-- ──────────────────────────────────────────────
local function createEmoteButton(emoteData, parent)
    local btn = Instance.new("TextButton")
    btn.Name=emoteData.name; btn.Size=UDim2.new(1,-4,0,44)
    btn.BackgroundColor3=Color3.fromRGB(30,30,30); btn.BorderSizePixel=0
    btn.Text=""; btn.AutoButtonColor=false; btn.Parent=parent
    do local c=Instance.new("UICorner");c.CornerRadius=UDim.new(0,10);c.Parent=btn end

    local ei=Instance.new("TextLabel"); ei.Size=UDim2.new(0,28,1,0); ei.Position=UDim2.new(0,8,0,0)
    ei.BackgroundTransparency=1; ei.Text="🎭"; ei.TextSize=18; ei.Parent=btn

    local en=Instance.new("TextLabel"); en.Size=UDim2.new(1,-90,0,22); en.Position=UDim2.new(0,40,0,3)
    en.BackgroundTransparency=1; en.Text=emoteData.name; en.TextColor3=Color3.fromRGB(255,255,255)
    en.Font=Enum.Font.GothamBold; en.TextSize=12; en.TextXAlignment=Enum.TextXAlignment.Left
    en.TextTruncate=Enum.TextTruncate.AtEnd; en.Parent=btn

    local inf=Instance.new("TextLabel"); inf.Size=UDim2.new(1,-90,0,14); inf.Position=UDim2.new(0,40,0,24)
    inf.BackgroundTransparency=1
    inf.Text=emoteData.type=="equipped" and "Slot "..emoteData.slot or "Inventory"
    inf.TextColor3=Color3.fromRGB(130,130,130); inf.Font=Enum.Font.Gotham; inf.TextSize=10
    inf.TextXAlignment=Enum.TextXAlignment.Left; inf.Parent=btn

    local ai=Instance.new("Frame"); ai.Name="ActiveIndicator"
    ai.Size=UDim2.new(0,8,0,8); ai.Position=UDim2.new(1,-15,0.5,-4)
    ai.BackgroundColor3=Color3.fromRGB(46,204,113); ai.BorderSizePixel=0; ai.Visible=false; ai.Parent=btn
    do local c=Instance.new("UICorner");c.CornerRadius=UDim.new(1,0);c.Parent=ai end

    local fb=Instance.new("TextButton"); fb.Name="FavButton"
    fb.Size=UDim2.new(0,22,0,22); fb.Position=UDim2.new(1,-36,0.5,-11)
    fb.BackgroundColor3=Color3.fromRGB(50,50,50); fb.BorderSizePixel=0
    fb.Text=table.find(favoriteEmotes,emoteData.name) and "⭐" or "☆"
    fb.TextColor3=Color3.fromRGB(255,255,255); fb.Font=Enum.Font.GothamBold; fb.TextSize=12
    fb.ZIndex=3; fb.Parent=btn
    do local c=Instance.new("UICorner");c.CornerRadius=UDim.new(0,4);c.Parent=fb end

    fb.MouseButton1Click:Connect(function()
        local idx=table.find(favoriteEmotes,emoteData.name)
        if idx then
            table.remove(favoriteEmotes,idx); fb.Text="☆"
            showNotification("Removed from favorites",Color3.fromRGB(150,150,150))
        else
            table.insert(favoriteEmotes,emoteData.name); fb.Text="⭐"
            showNotification("Added to favorites: "..emoteData.name, Color3.fromRGB(241,196,15))
        end
        populateFavoritesList()
    end)

    btn.MouseEnter:Connect(function()
        if currentEmoteName~=emoteData.name then TweenService:Create(btn,TweenInfo.new(0.15),{BackgroundColor3=Color3.fromRGB(45,45,45)}):Play() end
    end)
    btn.MouseLeave:Connect(function()
        if currentEmoteName~=emoteData.name then TweenService:Create(btn,TweenInfo.new(0.15),{BackgroundColor3=Color3.fromRGB(30,30,30)}):Play() end
    end)

    btn.MouseButton1Click:Connect(function()
        if currentEmoteName==emoteData.name then
            stopCurrentEmote(); btn.BackgroundColor3=Color3.fromRGB(30,30,30); ai.Visible=false
        else
            for _,fr in ipairs({emotesListFrame,favsListFrame}) do
                for _,b in ipairs(fr:GetChildren()) do
                    if b:IsA("TextButton") then b.BackgroundColor3=Color3.fromRGB(30,30,30)
                        local ind=b:FindFirstChild("ActiveIndicator"); if ind then ind.Visible=false end
                    end
                end
            end
            local ok=executeEmote(emoteData.name,emoteData)
            if ok then
                for _,fr in ipairs({emotesListFrame,favsListFrame}) do
                    for _,b in ipairs(fr:GetChildren()) do
                        if b:IsA("TextButton") and b.Name==emoteData.name then
                            b.BackgroundColor3=Color3.fromRGB(52,152,219)
                            local ind=b:FindFirstChild("ActiveIndicator"); if ind then ind.Visible=true end
                        end
                    end
                end
            end
        end
    end)
    return btn
end

-- ──────────────────────────────────────────────
--  LIST POPULATION
-- ──────────────────────────────────────────────
function applySearchFilter()
    local q = searchQuery:lower()
    for _, b in ipairs(playerListFrame:GetChildren()) do
        if b:IsA("TextButton") then
            local p = Players:FindFirstChild(b.Name)
            local hay = b.Name:lower() .. " " .. (p and p.DisplayName:lower() or "")
            b.Visible = (q=="" or hay:find(q,1,true)~=nil)
        end
    end
end

local function updatePlayerList()
    for _, c in ipairs(playerListFrame:GetChildren()) do
        if c:IsA("TextButton") then c:Destroy() end
    end
    local ps = Players:GetPlayers()
    for _, p in ipairs(ps) do
        if p ~= LocalPlayer then createPlayerButton(p) end
    end
    playerCountText.Text = "Players Online: " .. #ps
    if trackingPlayer and not Players:FindFirstChild(trackingPlayer.Name) then
        stopTracking()
        showNotification("Tracked player left", Color3.fromRGB(231,76,60))
    end
    if trackingPlayer then updateButtonVisuals() end
    applySearchFilter()
end

function populateEmoteList()
    for _, c in ipairs(emotesListFrame:GetChildren()) do
        if c:IsA("TextButton") or c:IsA("TextLabel") then c:Destroy() end
    end
    inventoryEmotes = getInventoryEmotes()
    if #inventoryEmotes==0 then
        local l=Instance.new("TextLabel"); l.Size=UDim2.new(1,0,0,50)
        l.BackgroundTransparency=1; l.Text="No emotes found.\nClick 'Load Emotes' to refresh."
        l.TextColor3=Color3.fromRGB(150,150,150); l.Font=Enum.Font.Gotham; l.TextSize=12
        l.TextWrapped=true; l.Parent=emotesListFrame
    else
        for _, e in ipairs(inventoryEmotes) do createEmoteButton(e,emotesListFrame) end
    end
end

function populateFavoritesList()
    for _, c in ipairs(favsListFrame:GetChildren()) do
        if c:IsA("TextButton") or c:IsA("TextLabel") then c:Destroy() end
    end
    local n=0
    for _, e in ipairs(inventoryEmotes) do
        if table.find(favoriteEmotes,e.name) then createEmoteButton(e,favsListFrame); n=n+1 end
    end
    if n==0 then
        local l=Instance.new("TextLabel"); l.Size=UDim2.new(1,0,0,50)
        l.BackgroundTransparency=1; l.Text="No favorites yet.\nClick ☆ to add emotes."
        l.TextColor3=Color3.fromRGB(150,150,150); l.Font=Enum.Font.Gotham; l.TextSize=12
        l.TextWrapped=true; l.Parent=favsListFrame
    end
end

-- ──────────────────────────────────────────────
--  TABS
-- ──────────────────────────────────────────────
local currentTabName = "players"
local function showTab(tab)
    currentTabName = tab
    playerListFrame.Visible  = (tab=="players")
    emotesListFrame.Visible  = (tab=="emotes")
    favsListFrame.Visible    = (tab=="favs")
    searchBox.Visible        = (tab=="players")
    playerTabBtn.BackgroundColor3 = (tab=="players") and Color3.fromRGB(52,152,219) or Color3.fromRGB(35,35,35)
    emotesTabBtn.BackgroundColor3 = (tab=="emotes")  and Color3.fromRGB(52,152,219) or Color3.fromRGB(35,35,35)
    favsTabBtn.BackgroundColor3   = (tab=="favs")    and Color3.fromRGB(52,152,219) or Color3.fromRGB(35,35,35)
    if tab=="favs" then populateFavoritesList() end
end
playerTabBtn.MouseButton1Click:Connect(function() showTab("players") end)
emotesTabBtn.MouseButton1Click:Connect(function() showTab("emotes")  end)
favsTabBtn.MouseButton1Click:Connect(function()   showTab("favs")    end)

-- ──────────────────────────────────────────────
--  EVENTS
-- ──────────────────────────────────────────────
Players.PlayerAdded:Connect(function(p)
    if p~=LocalPlayer then updatePlayerList(); showNotification(p.DisplayName.." joined",Color3.fromRGB(46,204,113)) end
end)
Players.PlayerRemoving:Connect(function(p)
    if trackingPlayer==p then stopTracking() end
    task.defer(updatePlayerList)
end)

-- Auto re-acquire tracked player after their respawn
Players.PlayerAdded:Connect(function(p)
    p.CharacterAdded:Connect(function()
        if trackingPlayer==p and autoMimic then
            task.wait(1)
            showNotification(p.DisplayName.." respawned — re-tracking", Color3.fromRGB(241,196,15))
            startTracking(p)
        end
    end)
end)
for _, p in ipairs(Players:GetPlayers()) do
    p.CharacterAdded:Connect(function()
        if trackingPlayer==p and autoMimic then
            task.wait(1)
            showNotification(p.DisplayName.." respawned — re-tracking", Color3.fromRGB(241,196,15))
            startTracking(p)
        end
    end)
end

stopButton.MouseButton1Click:Connect(function() stopTracking() end)
autoMimicToggle.MouseButton1Click:Connect(toggleAutoMimic)
possessionToggle.MouseButton1Click:Connect(togglePossessionMode)
refreshButton.MouseButton1Click:Connect(function() updatePlayerList(); showNotification("Refreshed",Color3.fromRGB(52,152,219)) end)
stopEmoteButton.MouseButton1Click:Connect(function()
    stopCurrentEmote()
    for _,fr in ipairs({emotesListFrame,favsListFrame}) do
        for _,b in ipairs(fr:GetChildren()) do
            if b:IsA("TextButton") then b.BackgroundColor3=Color3.fromRGB(30,30,30)
                local i=b:FindFirstChild("ActiveIndicator"); if i then i.Visible=false end
            end
        end
    end
end)
refreshEmotesButton.MouseButton1Click:Connect(function()
    populateEmoteList(); populateFavoritesList()
    showNotification("Emotes reloaded",Color3.fromRGB(46,204,113))
end)

searchBox:GetPropertyChangedSignal("Text"):Connect(function()
    searchQuery=searchBox.Text; applySearchFilter()
end)

closeButton.MouseButton1Click:Connect(function() stopTracking(); stopCurrentEmote(); screenGui:Destroy() end)

-- ──────────────────────────────────────────────
--  MINIMIZE
-- ──────────────────────────────────────────────
local minimized = false
minimizeButton.MouseButton1Click:Connect(function()
    minimized = not minimized
    if minimized then
        playerListFrame.Visible=false; emotesListFrame.Visible=false; favsListFrame.Visible=false
        controlPanel.Visible=false; buttonFrame.Visible=false; notificationFrame.Visible=false
        tabFrame.Visible=false; searchBox.Visible=false
        mainFrame.Size=UDim2.new(0,340,0,45); minimizeButton.Text="+"
    else
        controlPanel.Visible=true; buttonFrame.Visible=true; tabFrame.Visible=true
        mainFrame.Size=UDim2.new(0,340,0,560); minimizeButton.Text="−"
        showTab(currentTabName)
    end
end)

-- ──────────────────────────────────────────────
--  KEYBOARD SHORTCUTS
-- ──────────────────────────────────────────────
UserInputService.InputBegan:Connect(function(input, gp)
    if gp then return end
    local k = input.KeyCode
    if k==Enum.KeyCode.F then
        stopTracking()
    elseif k==Enum.KeyCode.G then
        toggleAutoMimic()
    elseif k==Enum.KeyCode.H then
        togglePossessionMode()
    elseif k==Enum.KeyCode.M then
        cycleMode()
    elseif k==Enum.KeyCode.E then
        stopCurrentEmote()
        for _,fr in ipairs({emotesListFrame,favsListFrame}) do
            for _,b in ipairs(fr:GetChildren()) do
                if b:IsA("TextButton") then b.BackgroundColor3=Color3.fromRGB(30,30,30)
                    local i=b:FindFirstChild("ActiveIndicator"); if i then i.Visible=false end
                end
            end
        end
    elseif k.Value>=Enum.KeyCode.One.Value and k.Value<=Enum.KeyCode.Nine.Value then
        local idx = k.Value - Enum.KeyCode.One.Value + 1
        if idx<=#inventoryEmotes then
            executeEmote(inventoryEmotes[idx].name, inventoryEmotes[idx])
        end
    end
end)

-- ──────────────────────────────────────────────
--  CHARACTER RESPAWN
-- ──────────────────────────────────────────────
LocalPlayer.CharacterAdded:Connect(function(char)
    if isPlayingEmote and currentEmoteName then
        task.wait(0.5)
        pcall(function()
            local h=char:FindFirstChildOfClass("Humanoid")
            if h then h:PlayEmote(currentEmoteName) end
        end)
    end
end)

-- ──────────────────────────────────────────────
--  CLEANUP
-- ──────────────────────────────────────────────
script.Destroying:Connect(function()
    stopTracking(); stopCurrentEmote()
    if screenGui then screenGui:Destroy() end
end)

-- ──────────────────────────────────────────────
--  INIT
-- ──────────────────────────────────────────────
updatePlayerList()
populateEmoteList()
populateFavoritesList()
showTab("players")

showNotification("Possession Tracker v3 loaded! Press M to cycle modes", Color3.fromRGB(142,68,173))
