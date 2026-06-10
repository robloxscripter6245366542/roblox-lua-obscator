-- Possession Tracker v4 — fixed UI + enhanced tracking
-- Place in StarterGui or a LocalScript in StarterPlayerScripts

local Players          = game:GetService("Players")
local RunService       = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local TweenService     = game:GetService("TweenService")
local LocalPlayer      = Players.LocalPlayer

-- ╔══════════════════════════════════════╗
-- ║           SCREEN GUI                 ║
-- ╚══════════════════════════════════════╝
local screenGui = Instance.new("ScreenGui")
screenGui.Name = "PlayerTracker"
screenGui.ResetOnSpawn = false
screenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
screenGui.Parent = LocalPlayer:WaitForChild("PlayerGui")

-- ╔══════════════════════════════════════╗
-- ║           MAIN FRAME                 ║
-- ╚══════════════════════════════════════╝
local mainFrame = Instance.new("Frame")
mainFrame.Name = "MainFrame"
mainFrame.Size = UDim2.new(0, 340, 0, 560)
mainFrame.Position = UDim2.new(0.02, 0, 0.5, -280)
mainFrame.BackgroundColor3 = Color3.fromRGB(15, 15, 15)
mainFrame.BorderSizePixel = 0
mainFrame.Active = true
mainFrame.Draggable = true
mainFrame.Parent = screenGui

local mainCorner = Instance.new("UICorner")
mainCorner.CornerRadius = UDim.new(0, 14)
mainCorner.Parent = mainFrame

local mainGradient = Instance.new("UIGradient")
mainGradient.Color = ColorSequence.new{
    ColorSequenceKeypoint.new(0, Color3.fromRGB(25, 25, 25)),
    ColorSequenceKeypoint.new(1, Color3.fromRGB(15, 15, 15))
}
mainGradient.Rotation = 45
mainGradient.Parent = mainFrame

-- ╔══════════════════════════════════════╗
-- ║           TITLE BAR                  ║
-- ╚══════════════════════════════════════╝
local titleBar = Instance.new("Frame")
titleBar.Name = "TitleBar"
titleBar.Size = UDim2.new(1, 0, 0, 45)
titleBar.Position = UDim2.new(0, 0, 0, 0)
titleBar.BackgroundColor3 = Color3.fromRGB(25, 25, 25)
titleBar.BorderSizePixel = 0
titleBar.Parent = mainFrame

local titleBarCorner = Instance.new("UICorner")
titleBarCorner.CornerRadius = UDim.new(0, 14)
titleBarCorner.Parent = titleBar

local titleLabel = Instance.new("TextLabel")
titleLabel.Size = UDim2.new(1, -90, 1, 0)
titleLabel.Position = UDim2.new(0, 15, 0, 0)
titleLabel.BackgroundTransparency = 1
titleLabel.Text = "👻 Possession Tracker v4"
titleLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
titleLabel.Font = Enum.Font.GothamBold
titleLabel.TextSize = 15
titleLabel.TextXAlignment = Enum.TextXAlignment.Left
titleLabel.Parent = titleBar

local minimizeButton = Instance.new("TextButton")
minimizeButton.Size = UDim2.new(0, 30, 0, 30)
minimizeButton.Position = UDim2.new(1, -70, 0.5, -15)
minimizeButton.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
minimizeButton.BorderSizePixel = 0
minimizeButton.Text = "−"
minimizeButton.TextColor3 = Color3.fromRGB(255, 255, 255)
minimizeButton.Font = Enum.Font.GothamBold
minimizeButton.TextSize = 18
minimizeButton.Parent = titleBar
do local c = Instance.new("UICorner"); c.CornerRadius = UDim.new(0,8); c.Parent = minimizeButton end

local closeButton = Instance.new("TextButton")
closeButton.Size = UDim2.new(0, 30, 0, 30)
closeButton.Position = UDim2.new(1, -35, 0.5, -15)
closeButton.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
closeButton.BorderSizePixel = 0
closeButton.Text = "✕"
closeButton.TextColor3 = Color3.fromRGB(255, 255, 255)
closeButton.Font = Enum.Font.GothamBold
closeButton.TextSize = 14
closeButton.Parent = titleBar
do local c = Instance.new("UICorner"); c.CornerRadius = UDim.new(0,8); c.Parent = closeButton end

-- ╔══════════════════════════════════════╗
-- ║           TAB BAR                    ║
-- ╚══════════════════════════════════════╝
local tabFrame = Instance.new("Frame")
tabFrame.Name = "TabFrame"
tabFrame.Size = UDim2.new(1, -10, 0, 32)
tabFrame.Position = UDim2.new(0, 5, 0, 52)
tabFrame.BackgroundTransparency = 1
tabFrame.BorderSizePixel = 0
tabFrame.Parent = mainFrame

local playerTabBtn = Instance.new("TextButton")
playerTabBtn.Name = "PlayerTab"
playerTabBtn.Size = UDim2.new(0.33, -3, 1, 0)
playerTabBtn.Position = UDim2.new(0, 0, 0, 0)
playerTabBtn.BackgroundColor3 = Color3.fromRGB(52, 152, 219)
playerTabBtn.BorderSizePixel = 0
playerTabBtn.Text = "👥 Players"
playerTabBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
playerTabBtn.Font = Enum.Font.GothamBold
playerTabBtn.TextSize = 11
playerTabBtn.Parent = tabFrame
do local c = Instance.new("UICorner"); c.CornerRadius = UDim.new(0,8); c.Parent = playerTabBtn end

local emotesTabBtn = Instance.new("TextButton")
emotesTabBtn.Name = "EmotesTab"
emotesTabBtn.Size = UDim2.new(0.34, -2, 1, 0)
emotesTabBtn.Position = UDim2.new(0.33, 2, 0, 0)
emotesTabBtn.BackgroundColor3 = Color3.fromRGB(35, 35, 35)
emotesTabBtn.BorderSizePixel = 0
emotesTabBtn.Text = "🎭 Emotes"
emotesTabBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
emotesTabBtn.Font = Enum.Font.GothamBold
emotesTabBtn.TextSize = 11
emotesTabBtn.Parent = tabFrame
do local c = Instance.new("UICorner"); c.CornerRadius = UDim.new(0,8); c.Parent = emotesTabBtn end

local favsTabBtn = Instance.new("TextButton")
favsTabBtn.Name = "FavsTab"
favsTabBtn.Size = UDim2.new(0.33, -3, 1, 0)
favsTabBtn.Position = UDim2.new(0.67, 3, 0, 0)
favsTabBtn.BackgroundColor3 = Color3.fromRGB(35, 35, 35)
favsTabBtn.BorderSizePixel = 0
favsTabBtn.Text = "⭐ Favs"
favsTabBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
favsTabBtn.Font = Enum.Font.GothamBold
favsTabBtn.TextSize = 11
favsTabBtn.Parent = tabFrame
do local c = Instance.new("UICorner"); c.CornerRadius = UDim.new(0,8); c.Parent = favsTabBtn end

-- ╔══════════════════════════════════════╗
-- ║        CONTROL PANEL                 ║
-- ╚══════════════════════════════════════╝
local controlPanel = Instance.new("Frame")
controlPanel.Name = "ControlPanel"
controlPanel.Size = UDim2.new(1, -10, 0, 206)
controlPanel.Position = UDim2.new(0, 5, 0, 90)
controlPanel.BackgroundTransparency = 1
controlPanel.BorderSizePixel = 0
controlPanel.Parent = mainFrame

-- Player count
local playerCountText = Instance.new("TextLabel")
playerCountText.Name = "PlayerCount"
playerCountText.Size = UDim2.new(1, 0, 0, 16)
playerCountText.Position = UDim2.new(0, 0, 0, 0)
playerCountText.BackgroundTransparency = 1
playerCountText.Text = "Players Online: 0"
playerCountText.TextColor3 = Color3.fromRGB(150, 150, 150)
playerCountText.Font = Enum.Font.Gotham
playerCountText.TextSize = 11
playerCountText.TextXAlignment = Enum.TextXAlignment.Left
playerCountText.Parent = controlPanel

-- Auto Mimic toggle
local autoMimicToggle = Instance.new("TextButton")
autoMimicToggle.Name = "AutoMimicToggle"
autoMimicToggle.Size = UDim2.new(1, 0, 0, 28)
autoMimicToggle.Position = UDim2.new(0, 0, 0, 20)
autoMimicToggle.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
autoMimicToggle.BorderSizePixel = 0
autoMimicToggle.Text = "     🔴 Auto Mimic: OFF"
autoMimicToggle.TextColor3 = Color3.fromRGB(255, 255, 255)
autoMimicToggle.Font = Enum.Font.GothamBold
autoMimicToggle.TextSize = 12
autoMimicToggle.TextXAlignment = Enum.TextXAlignment.Left
autoMimicToggle.Parent = controlPanel
do local c = Instance.new("UICorner"); c.CornerRadius = UDim.new(0,8); c.Parent = autoMimicToggle end

local mimicDot = Instance.new("Frame")
mimicDot.Size = UDim2.new(0, 10, 0, 10)
mimicDot.Position = UDim2.new(0, 8, 0.5, -5)
mimicDot.BackgroundColor3 = Color3.fromRGB(231, 76, 60)
mimicDot.BorderSizePixel = 0
mimicDot.Parent = autoMimicToggle
do local c = Instance.new("UICorner"); c.CornerRadius = UDim.new(1,0); c.Parent = mimicDot end

-- Possession Mode toggle
local possessionToggle = Instance.new("TextButton")
possessionToggle.Name = "PossessionToggle"
possessionToggle.Size = UDim2.new(1, 0, 0, 28)
possessionToggle.Position = UDim2.new(0, 0, 0, 52)
possessionToggle.BackgroundColor3 = Color3.fromRGB(142, 68, 173)
possessionToggle.BorderSizePixel = 0
possessionToggle.Text = "     👻 Possession Mode: ON"
possessionToggle.TextColor3 = Color3.fromRGB(255, 255, 255)
possessionToggle.Font = Enum.Font.GothamBold
possessionToggle.TextSize = 12
possessionToggle.TextXAlignment = Enum.TextXAlignment.Left
possessionToggle.Parent = controlPanel
do local c = Instance.new("UICorner"); c.CornerRadius = UDim.new(0,8); c.Parent = possessionToggle end

local possessionDot = Instance.new("Frame")
possessionDot.Size = UDim2.new(0, 10, 0, 10)
possessionDot.Position = UDim2.new(0, 8, 0.5, -5)
possessionDot.BackgroundColor3 = Color3.fromRGB(46, 204, 113)
possessionDot.BorderSizePixel = 0
possessionDot.Parent = possessionToggle
do local c = Instance.new("UICorner"); c.CornerRadius = UDim.new(1,0); c.Parent = possessionDot end

-- Tracking Mode button
local MODES      = {"POSSESS","BEHIND","SHADOW","GHOST"}
local MODECOLORS = {
    POSSESS = Color3.fromRGB(142, 68, 173),
    BEHIND  = Color3.fromRGB(52, 152, 219),
    SHADOW  = Color3.fromRGB(39, 174, 96),
    GHOST   = Color3.fromRGB(44, 44, 44),
}
local currentModeIdx = 1

local modeButton = Instance.new("TextButton")
modeButton.Name = "ModeButton"
modeButton.Size = UDim2.new(1, 0, 0, 28)
modeButton.Position = UDim2.new(0, 0, 0, 84)
modeButton.BackgroundColor3 = MODECOLORS["POSSESS"]
modeButton.BorderSizePixel = 0
modeButton.Text = "     👻 Mode: POSSESS  (M to cycle)"
modeButton.TextColor3 = Color3.fromRGB(255, 255, 255)
modeButton.Font = Enum.Font.GothamBold
modeButton.TextSize = 11
modeButton.TextXAlignment = Enum.TextXAlignment.Left
modeButton.Parent = controlPanel
do local c = Instance.new("UICorner"); c.CornerRadius = UDim.new(0,8); c.Parent = modeButton end

-- Live HUD strip
local hudFrame = Instance.new("Frame")
hudFrame.Name = "HUD"
hudFrame.Size = UDim2.new(1, 0, 0, 28)
hudFrame.Position = UDim2.new(0, 0, 0, 116)
hudFrame.BackgroundColor3 = Color3.fromRGB(22, 22, 22)
hudFrame.BorderSizePixel = 0
hudFrame.Parent = controlPanel
do local c = Instance.new("UICorner"); c.CornerRadius = UDim.new(0,8); c.Parent = hudFrame end

local hudText = Instance.new("TextLabel")
hudText.Size = UDim2.new(1, -10, 1, 0)
hudText.Position = UDim2.new(0, 8, 0, 0)
hudText.BackgroundTransparency = 1
hudText.Text = "Not tracking"
hudText.TextColor3 = Color3.fromRGB(170, 170, 170)
hudText.Font = Enum.Font.Gotham
hudText.TextSize = 10
hudText.TextXAlignment = Enum.TextXAlignment.Left
hudText.Parent = hudFrame

-- Current emote label
local currentEmoteLabel = Instance.new("TextLabel")
currentEmoteLabel.Name = "CurrentEmote"
currentEmoteLabel.Size = UDim2.new(1, 0, 0, 16)
currentEmoteLabel.Position = UDim2.new(0, 0, 0, 148)
currentEmoteLabel.BackgroundTransparency = 1
currentEmoteLabel.Text = "🎭 Current Emote: None"
currentEmoteLabel.TextColor3 = Color3.fromRGB(180, 180, 180)
currentEmoteLabel.Font = Enum.Font.Gotham
currentEmoteLabel.TextSize = 11
currentEmoteLabel.TextXAlignment = Enum.TextXAlignment.Left
currentEmoteLabel.Parent = controlPanel

-- Stop Emote button
local stopEmoteButton = Instance.new("TextButton")
stopEmoteButton.Name = "StopEmoteButton"
stopEmoteButton.Size = UDim2.new(0.5, -3, 0, 26)
stopEmoteButton.Position = UDim2.new(0, 0, 0, 168)
stopEmoteButton.BackgroundColor3 = Color3.fromRGB(60, 60, 60)
stopEmoteButton.BorderSizePixel = 0
stopEmoteButton.Text = "⏹ Stop Emote"
stopEmoteButton.TextColor3 = Color3.fromRGB(255, 255, 255)
stopEmoteButton.Font = Enum.Font.GothamBold
stopEmoteButton.TextSize = 11
stopEmoteButton.Parent = controlPanel
do local c = Instance.new("UICorner"); c.CornerRadius = UDim.new(0,6); c.Parent = stopEmoteButton end

-- Load Emotes button
local refreshEmotesButton = Instance.new("TextButton")
refreshEmotesButton.Name = "RefreshEmotesButton"
refreshEmotesButton.Size = UDim2.new(0.5, -3, 0, 26)
refreshEmotesButton.Position = UDim2.new(0.5, 3, 0, 168)
refreshEmotesButton.BackgroundColor3 = Color3.fromRGB(46, 204, 113)
refreshEmotesButton.BorderSizePixel = 0
refreshEmotesButton.Text = "🔄 Load Emotes"
refreshEmotesButton.TextColor3 = Color3.fromRGB(255, 255, 255)
refreshEmotesButton.Font = Enum.Font.GothamBold
refreshEmotesButton.TextSize = 11
refreshEmotesButton.Parent = controlPanel
do local c = Instance.new("UICorner"); c.CornerRadius = UDim.new(0,6); c.Parent = refreshEmotesButton end

-- ╔══════════════════════════════════════╗
-- ║         SEARCH BOX                   ║
-- ╚══════════════════════════════════════╝
local searchBox = Instance.new("TextBox")
searchBox.Name = "SearchBox"
searchBox.Size = UDim2.new(1, -10, 0, 28)
searchBox.Position = UDim2.new(0, 5, 0, 302)
searchBox.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
searchBox.BorderSizePixel = 0
searchBox.Text = ""
searchBox.PlaceholderText = "🔍  Search players..."
searchBox.PlaceholderColor3 = Color3.fromRGB(110, 110, 110)
searchBox.TextColor3 = Color3.fromRGB(255, 255, 255)
searchBox.Font = Enum.Font.Gotham
searchBox.TextSize = 12
searchBox.TextXAlignment = Enum.TextXAlignment.Left
searchBox.ClearTextOnFocus = false
searchBox.Visible = true
searchBox.Parent = mainFrame
do
    local c = Instance.new("UICorner"); c.CornerRadius = UDim.new(0,8); c.Parent = searchBox
    local p = Instance.new("UIPadding"); p.PaddingLeft = UDim.new(0,10); p.Parent = searchBox
end

-- ╔══════════════════════════════════════╗
-- ║       SCROLLING LISTS                ║
-- ╚══════════════════════════════════════╝
local function makeScrollList(name, visible)
    local sf = Instance.new("ScrollingFrame")
    sf.Name = name
    sf.Size = UDim2.new(1, -10, 1, -400)
    sf.Position = UDim2.new(0, 5, 0, 336)
    sf.BackgroundTransparency = 1
    sf.BorderSizePixel = 0
    sf.ScrollBarThickness = 3
    sf.ScrollBarImageColor3 = Color3.fromRGB(80, 80, 80)
    sf.CanvasSize = UDim2.new(0, 0, 0, 0)
    sf.AutomaticCanvasSize = Enum.AutomaticSize.Y
    sf.ScrollingDirection = Enum.ScrollingDirection.Y
    sf.Visible = visible
    sf.Parent = mainFrame

    local layout = Instance.new("UIListLayout")
    layout.Padding = UDim.new(0, 4)
    layout.HorizontalAlignment = Enum.HorizontalAlignment.Center
    layout.SortOrder = Enum.SortOrder.Name
    layout.Parent = sf

    local pad = Instance.new("UIPadding")
    pad.PaddingLeft  = UDim.new(0, 2)
    pad.PaddingRight = UDim.new(0, 2)
    pad.PaddingTop   = UDim.new(0, 2)
    pad.Parent = sf

    return sf
end

local playerListFrame = makeScrollList("PlayerList", true)
local emotesListFrame = makeScrollList("EmotesList", false)
local favsListFrame   = makeScrollList("FavsList",   false)

-- ╔══════════════════════════════════════╗
-- ║       BOTTOM BUTTONS                 ║
-- ╚══════════════════════════════════════╝
local buttonFrame = Instance.new("Frame")
buttonFrame.Name = "ButtonFrame"
buttonFrame.Size = UDim2.new(1, -10, 0, 36)
buttonFrame.Position = UDim2.new(0, 5, 1, -42)
buttonFrame.BackgroundTransparency = 1
buttonFrame.BorderSizePixel = 0
buttonFrame.Parent = mainFrame

local stopButton = Instance.new("TextButton")
stopButton.Name = "StopButton"
stopButton.Size = UDim2.new(0.72, -3, 1, 0)
stopButton.Position = UDim2.new(0, 0, 0, 0)
stopButton.BackgroundColor3 = Color3.fromRGB(231, 76, 60)
stopButton.BorderSizePixel = 0
stopButton.Text = "⏹ Stop Tracking"
stopButton.TextColor3 = Color3.fromRGB(255, 255, 255)
stopButton.Font = Enum.Font.GothamBold
stopButton.TextSize = 13
stopButton.Parent = buttonFrame
do local c = Instance.new("UICorner"); c.CornerRadius = UDim.new(0,8); c.Parent = stopButton end

local refreshButton = Instance.new("TextButton")
refreshButton.Name = "RefreshButton"
refreshButton.Size = UDim2.new(0.28, -3, 1, 0)
refreshButton.Position = UDim2.new(0.72, 6, 0, 0)
refreshButton.BackgroundColor3 = Color3.fromRGB(52, 152, 219)
refreshButton.BorderSizePixel = 0
refreshButton.Text = "🔄"
refreshButton.TextColor3 = Color3.fromRGB(255, 255, 255)
refreshButton.Font = Enum.Font.GothamBold
refreshButton.TextSize = 16
refreshButton.Parent = buttonFrame
do local c = Instance.new("UICorner"); c.CornerRadius = UDim.new(0,8); c.Parent = refreshButton end

-- ╔══════════════════════════════════════╗
-- ║         NOTIFICATION BAR             ║
-- ╚══════════════════════════════════════╝
local notificationFrame = Instance.new("Frame")
notificationFrame.Name = "Notification"
notificationFrame.Size = UDim2.new(1, 0, 0, 28)
notificationFrame.Position = UDim2.new(0, 0, 0, -33)
notificationFrame.BackgroundColor3 = Color3.fromRGB(46, 204, 113)
notificationFrame.BorderSizePixel = 0
notificationFrame.Visible = false
notificationFrame.Parent = mainFrame
do local c = Instance.new("UICorner"); c.CornerRadius = UDim.new(0,8); c.Parent = notificationFrame end

local notificationText = Instance.new("TextLabel")
notificationText.Size = UDim2.new(1, 0, 1, 0)
notificationText.BackgroundTransparency = 1
notificationText.Text = ""
notificationText.TextColor3 = Color3.fromRGB(255, 255, 255)
notificationText.Font = Enum.Font.GothamBold
notificationText.TextSize = 12
notificationText.Parent = notificationFrame

-- ╔══════════════════════════════════════╗
-- ║       STATE & CONSTANTS              ║
-- ╚══════════════════════════════════════╝
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
local prevTargetPos    = nil
local TELEPORT_THRESH  = 40

local MODEICONS = {POSSESS="👻", BEHIND="🔵", SHADOW="🟢", GHOST="💀"}

local STATE_LABELS = {
    [Enum.HumanoidStateType.Running]          = "Walking",
    [Enum.HumanoidStateType.Jumping]          = "Jumping",
    [Enum.HumanoidStateType.Freefall]         = "Falling",
    [Enum.HumanoidStateType.Swimming]         = "Swimming",
    [Enum.HumanoidStateType.Climbing]         = "Climbing",
    [Enum.HumanoidStateType.Seated]           = "Seated",
    [Enum.HumanoidStateType.Dead]             = "Dead",
    [Enum.HumanoidStateType.Ragdoll]          = "Ragdoll",
    [Enum.HumanoidStateType.GettingUp]        = "Getting Up",
    [Enum.HumanoidStateType.RunningNoPhysics] = "Idle",
    [Enum.HumanoidStateType.StrafingNoPhysics]= "Idle",
}

-- Forward declarations
local populateEmoteList, populateFavoritesList, applySearchFilter
local updateButtonVisuals, resetButtonVisuals

-- ╔══════════════════════════════════════╗
-- ║           HELPERS                    ║
-- ╚══════════════════════════════════════╝
local function currentMode()
    return MODES[currentModeIdx]
end

local function showNotification(msg, color)
    notificationFrame.BackgroundColor3 = color or Color3.fromRGB(46, 204, 113)
    notificationText.Text = msg
    notificationFrame.Visible = true
    notificationFrame.BackgroundTransparency = 0
    task.spawn(function()
        task.wait(2.5)
        TweenService:Create(notificationFrame, TweenInfo.new(0.4), {BackgroundTransparency = 1}):Play()
        task.wait(0.4)
        notificationFrame.Visible = false
        notificationFrame.BackgroundTransparency = 0
    end)
end

local function setSelfTransparency(t)
    local char = LocalPlayer.Character
    if not char then return end
    for _, v in ipairs(char:GetDescendants()) do
        if v:IsA("BasePart") and v.Name ~= "HumanoidRootPart" then
            v.LocalTransparencyModifier = t
        elseif v:IsA("Decal") then
            v.Transparency = t
        end
    end
end
local function setSelfVisible()   setSelfTransparency(0)    end
local function setSelfGhost()     setSelfTransparency(1)    end
local function setSelfFade()      setSelfTransparency(0.75) end

-- ╔══════════════════════════════════════╗
-- ║        TRACKING CORE                 ║
-- ╚══════════════════════════════════════╝
local function mimicMovement(myChar, targetChar)
    local myH    = myChar:FindFirstChildOfClass("Humanoid")
    local myRoot = myChar:FindFirstChild("HumanoidRootPart")
    local tH     = targetChar:FindFirstChildOfClass("Humanoid")
    local tRoot  = targetChar:FindFirstChild("HumanoidRootPart")
    if not (myH and myRoot and tH and tRoot) then return end

    -- match speed settings
    myH.WalkSpeed  = tH.WalkSpeed
    myH.JumpPower  = tH.JumpPower
    myH.JumpHeight = tH.JumpHeight

    local tPos      = tRoot.Position
    local teleport  = prevTargetPos ~= nil and (tPos - prevTargetPos).Magnitude > TELEPORT_THRESH
    prevTargetPos   = tPos

    -- velocity-predicted target CFrame (compensates ~half a frame of latency)
    local vel     = tRoot.AssemblyLinearVelocity
    local predPos = tPos + vel * (1/60 * 0.5)
    local rot     = tRoot.CFrame - tRoot.CFrame.Position
    local predCF  = CFrame.new(predPos) * rot

    local mode = currentMode()

    if mode == "POSSESS" then
        myRoot.CFrame = teleport and predCF or myRoot.CFrame:Lerp(predCF, 0.85)
        myRoot.AssemblyLinearVelocity  = tRoot.AssemblyLinearVelocity
        myRoot.AssemblyAngularVelocity = tRoot.AssemblyAngularVelocity
        setSelfFade()

    elseif mode == "GHOST" then
        myRoot.CFrame = teleport and predCF or myRoot.CFrame:Lerp(predCF, 0.95)
        myRoot.AssemblyLinearVelocity  = tRoot.AssemblyLinearVelocity
        myRoot.AssemblyAngularVelocity = tRoot.AssemblyAngularVelocity
        setSelfGhost()

    elseif mode == "BEHIND" then
        local behind = predCF * CFrame.new(0, 0, 4)
        myRoot.CFrame = teleport and behind or myRoot.CFrame:Lerp(behind, 0.75)
        myRoot.AssemblyLinearVelocity = tRoot.AssemblyLinearVelocity
        setSelfVisible()

    elseif mode == "SHADOW" then
        local shadowCF = predCF * CFrame.new(0, 0.2, 0)
        local alpha    = teleport and 1 or 0.18
        myRoot.CFrame  = myRoot.CFrame:Lerp(shadowCF, alpha)
        setSelfVisible()
    end

    -- mirror all humanoid states
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

local function updateHUD(tRoot, tH, myRoot)
    if not (tRoot and tH and myRoot) then
        hudText.Text = "Not tracking"
        return
    end
    local dist  = math.floor((myRoot.Position - tRoot.Position).Magnitude * 10 + 0.5) / 10
    local speed = math.floor(tRoot.AssemblyLinearVelocity.Magnitude * 10 + 0.5) / 10
    local state = STATE_LABELS[tH:GetState()] or "?"
    hudText.Text = string.format("📍 %.1f st  ⚡ %.1f st/s  %s  %s",
        dist, speed, state, currentMode())
end

-- ╔══════════════════════════════════════╗
-- ║      START / STOP TRACKING           ║
-- ╚══════════════════════════════════════╝
function updateButtonVisuals()
    for _, b in ipairs(playerListFrame:GetChildren()) do
        if b:IsA("TextButton") then
            local tracked = trackingPlayer ~= nil and b.Name == trackingPlayer.Name
            local si = b:FindFirstChild("StatusIndicator")
            local ti = b:FindFirstChild("TrackIcon")
            local st = b:FindFirstChild("StatusText")
            if si then si.Visible = tracked end
            if ti then ti.Text = tracked and "👻" or "👤" end
            if st then st.Text = tracked and ("👻 " .. currentMode()) or "Click to track" end
            b.BackgroundColor3 = tracked
                and Color3.fromRGB(142, 68, 173)
                or  Color3.fromRGB(30, 30, 30)
        end
    end
end

function resetButtonVisuals()
    for _, b in ipairs(playerListFrame:GetChildren()) do
        if b:IsA("TextButton") then
            b.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
            local si = b:FindFirstChild("StatusIndicator"); if si then si.Visible = false end
            local ti = b:FindFirstChild("TrackIcon");      if ti then ti.Text = "👤" end
            local st = b:FindFirstChild("StatusText");     if st then st.Text = "Click to track" end
        end
    end
end

function stopTracking()
    if trackConnection then trackConnection:Disconnect(); trackConnection = nil end
    setSelfVisible()
    prevTargetPos = nil
    trackingPlayer = nil
    hudText.Text = "Not tracking"
    local char = LocalPlayer.Character
    if char then
        local h = char:FindFirstChildOfClass("Humanoid")
        if h then h.WalkSpeed = 16; h.JumpPower = 50; h.Jump = false end
    end
    resetButtonVisuals()
    stopButton.Text = "⏹ Stop Tracking"
end

function startTracking(player)
    stopTracking()
    if not player then return end
    if not player.Character then
        showNotification("Waiting for " .. player.DisplayName .. "…", Color3.fromRGB(241,196,15))
        task.spawn(function()
            player.CharacterAdded:Wait()
            task.wait(0.5)
            startTracking(player)
        end)
        return
    end

    trackingPlayer = player
    prevTargetPos  = nil
    updateButtonVisuals()
    stopButton.Text = "⏹ Stop: " .. player.DisplayName

    local myChar = LocalPlayer.Character
    if not myChar then LocalPlayer.CharacterAdded:Wait(); myChar = LocalPlayer.Character end
    myChar:WaitForChild("Humanoid", 5)

    trackConnection = RunService.Heartbeat:Connect(function()
        local tChar = trackingPlayer and trackingPlayer.Character
        myChar = LocalPlayer.Character
        if not (tChar and myChar) then return end

        local tRoot  = tChar:FindFirstChild("HumanoidRootPart")
        local tH     = tChar:FindFirstChildOfClass("Humanoid")
        local myRoot = myChar:FindFirstChild("HumanoidRootPart")

        if autoMimic and tRoot and tH and myRoot then
            mimicMovement(myChar, tChar)
        end
        updateHUD(tRoot, tH, myRoot)
    end)

    showNotification("Tracking: " .. player.DisplayName .. " [" .. currentMode() .. "]",
        MODECOLORS[currentMode()])
end

-- ╔══════════════════════════════════════╗
-- ║         MODE CYCLE                   ║
-- ╚══════════════════════════════════════╝
local function cycleMode()
    currentModeIdx = (currentModeIdx % #MODES) + 1
    local m = currentMode()
    modeButton.BackgroundColor3 = MODECOLORS[m]
    modeButton.Text = "     " .. MODEICONS[m] .. " Mode: " .. m .. "  (M to cycle)"
    if trackingPlayer then
        showNotification("Mode → " .. m, MODECOLORS[m])
        updateButtonVisuals()
    end
end
modeButton.MouseButton1Click:Connect(cycleMode)

-- ╔══════════════════════════════════════╗
-- ║        TOGGLE FUNCTIONS              ║
-- ╚══════════════════════════════════════╝
function toggleAutoMimic()
    autoMimic = not autoMimic
    if autoMimic then
        autoMimicToggle.Text = "     🟢 Auto Mimic: ON"
        autoMimicToggle.BackgroundColor3 = Color3.fromRGB(46, 204, 113)
        mimicDot.BackgroundColor3 = Color3.fromRGB(46, 204, 113)
        showNotification("Auto Mimic ON — " .. currentMode(), Color3.fromRGB(46,204,113))
    else
        autoMimicToggle.Text = "     🔴 Auto Mimic: OFF"
        autoMimicToggle.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
        mimicDot.BackgroundColor3 = Color3.fromRGB(231, 76, 60)
        setSelfVisible()
        showNotification("Auto Mimic OFF", Color3.fromRGB(150,150,150))
    end
end

function togglePossessionMode()
    possessionMode = not possessionMode
    if possessionMode then
        possessionToggle.Text = "     👻 Possession Mode: ON"
        possessionToggle.BackgroundColor3 = Color3.fromRGB(142, 68, 173)
        possessionDot.BackgroundColor3 = Color3.fromRGB(46, 204, 113)
        showNotification("Possession: fade while tracking", Color3.fromRGB(142,68,173))
    else
        possessionToggle.Text = "     👻 Possession Mode: OFF"
        possessionToggle.BackgroundColor3 = Color3.fromRGB(60, 60, 60)
        possessionDot.BackgroundColor3 = Color3.fromRGB(150, 150, 150)
        setSelfVisible()
        showNotification("Possession Mode OFF", Color3.fromRGB(150,150,150))
    end
end

-- ╔══════════════════════════════════════╗
-- ║           EMOTES                     ║
-- ╚══════════════════════════════════════╝
local function getInventoryEmotes()
    local emotes = {}
    pcall(function()
        local hd = (LocalPlayer.Character and LocalPlayer.Character:FindFirstChildOfClass("HumanoidDescription"))
            or Players:GetHumanoidDescriptionFromUserId(LocalPlayer.UserId)
        if hd then
            for i = 1, 8 do
                local n = hd["Emote" .. i]
                if n and n ~= "" then
                    table.insert(emotes, {name=n, slot=i, type="equipped"})
                end
            end
        end
    end)
    pcall(function()
        local es = game:GetService("EmotesService")
        if not es then return end
        local eq = es:GetEmotesForUserId(LocalPlayer.UserId)
        if not eq then return end
        for _, ed in pairs(eq) do
            local exists = false
            for _, e in ipairs(emotes) do if e.name == ed.Name then exists=true; break end end
            if not exists then
                table.insert(emotes, {name=ed.Name, slot=ed.Slot or 0, type="inventory"})
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
        if es then es:PlayEmote(LocalPlayer, name) end
    end)
    return ok
end

local function stopCurrentEmote()
    if currentEmoteTrack then pcall(function() currentEmoteTrack:Stop() end); currentEmoteTrack = nil end
    pcall(function()
        local char = LocalPlayer.Character; if not char then return end
        local h = char:FindFirstChildOfClass("Humanoid"); if not h then return end
        for _, t in ipairs(h:GetPlayingAnimationTracks()) do t:Stop() end
    end)
    currentEmoteName = nil
    isPlayingEmote = false
    currentEmoteLabel.Text = "🎭 Current Emote: None"
end

local function executeEmote(name, data)
    stopCurrentEmote()
    local ok = playInventoryEmote(name)
    if ok then
        currentEmoteName = name
        isPlayingEmote = true
        currentEmoteLabel.Text = "🎭 Current Emote: " .. name
        showNotification("Playing: " .. name, Color3.fromRGB(52,152,219))
    else
        showNotification("Failed: " .. name, Color3.fromRGB(231,76,60))
    end
    return ok
end

-- ╔══════════════════════════════════════╗
-- ║       PLAYER BUTTON                  ║
-- ╚══════════════════════════════════════╝
local function createPlayerButton(player)
    local btn = Instance.new("TextButton")
    btn.Name = player.Name
    btn.Size = UDim2.new(1, -4, 0, 50)
    btn.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
    btn.BorderSizePixel = 0
    btn.Text = ""
    btn.AutoButtonColor = false
    btn.ClipsDescendants = true
    btn.Parent = playerListFrame
    do local c = Instance.new("UICorner"); c.CornerRadius = UDim.new(0,10); c.Parent = btn end

    -- avatar initial circle
    local iconBg = Instance.new("Frame")
    iconBg.Size = UDim2.new(0, 36, 0, 36)
    iconBg.Position = UDim2.new(0, 8, 0.5, -18)
    iconBg.BackgroundColor3 = Color3.fromRGB(52, 152, 219)
    iconBg.BorderSizePixel = 0
    iconBg.Parent = btn
    do local c = Instance.new("UICorner"); c.CornerRadius = UDim.new(1,0); c.Parent = iconBg end

    local initLabel = Instance.new("TextLabel")
    initLabel.Size = UDim2.new(1,0,1,0)
    initLabel.BackgroundTransparency = 1
    initLabel.Text = player.Name:sub(1,1):upper()
    initLabel.TextColor3 = Color3.fromRGB(255,255,255)
    initLabel.Font = Enum.Font.GothamBold
    initLabel.TextSize = 16
    initLabel.Parent = iconBg

    local trackIcon = Instance.new("TextLabel")
    trackIcon.Name = "TrackIcon"
    trackIcon.Size = UDim2.new(0, 16, 0, 16)
    trackIcon.Position = UDim2.new(0, 28, 1, -20)
    trackIcon.BackgroundTransparency = 1
    trackIcon.Text = "👤"
    trackIcon.TextSize = 12
    trackIcon.ZIndex = 2
    trackIcon.Parent = btn

    local nameLabel = Instance.new("TextLabel")
    nameLabel.Name = "NameText"
    nameLabel.Size = UDim2.new(1, -65, 0, 20)
    nameLabel.Position = UDim2.new(0, 52, 0, 7)
    nameLabel.BackgroundTransparency = 1
    nameLabel.Text = player.DisplayName ~= player.Name
        and player.DisplayName .. " (@" .. player.Name .. ")"
        or  player.Name
    nameLabel.TextColor3 = Color3.fromRGB(255,255,255)
    nameLabel.Font = Enum.Font.GothamBold
    nameLabel.TextSize = 13
    nameLabel.TextXAlignment = Enum.TextXAlignment.Left
    nameLabel.TextTruncate = Enum.TextTruncate.AtEnd
    nameLabel.Parent = btn

    local statusText = Instance.new("TextLabel")
    statusText.Name = "StatusText"
    statusText.Size = UDim2.new(1, -65, 0, 15)
    statusText.Position = UDim2.new(0, 52, 0, 27)
    statusText.BackgroundTransparency = 1
    statusText.Text = "Click to track"
    statusText.TextColor3 = Color3.fromRGB(150,150,150)
    statusText.Font = Enum.Font.Gotham
    statusText.TextSize = 10
    statusText.TextXAlignment = Enum.TextXAlignment.Left
    statusText.Parent = btn

    local statusDot = Instance.new("Frame")
    statusDot.Name = "StatusIndicator"
    statusDot.Size = UDim2.new(0, 8, 0, 8)
    statusDot.Position = UDim2.new(1, -76, 0, 7)
    statusDot.BackgroundColor3 = Color3.fromRGB(46, 204, 113)
    statusDot.BorderSizePixel = 0
    statusDot.Visible = false
    statusDot.Parent = btn
    do local c = Instance.new("UICorner"); c.CornerRadius = UDim.new(1,0); c.Parent = statusDot end

    -- Dedicated Track / Untrack button on the right edge
    local trackBtn = Instance.new("TextButton")
    trackBtn.Name = "TrackBtn"
    trackBtn.Size = UDim2.new(0, 58, 0, 30)
    trackBtn.Position = UDim2.new(1, -63, 0.5, -15)
    trackBtn.BackgroundColor3 = Color3.fromRGB(52, 152, 219)
    trackBtn.BorderSizePixel = 0
    trackBtn.Text = "Track"
    trackBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
    trackBtn.Font = Enum.Font.GothamBold
    trackBtn.TextSize = 11
    trackBtn.ZIndex = 3
    trackBtn.Parent = btn
    do local c = Instance.new("UICorner"); c.CornerRadius = UDim.new(0,7); c.Parent = trackBtn end

    -- keep name label from overlapping the track button
    nameLabel.Size = UDim2.new(1, -130, 0, 20)
    statusText.Size = UDim2.new(1, -130, 0, 15)

    local function refreshTrackBtn()
        if trackingPlayer == player then
            trackBtn.Text = "Stop"
            trackBtn.BackgroundColor3 = Color3.fromRGB(231, 76, 60)
        else
            trackBtn.Text = "Track"
            trackBtn.BackgroundColor3 = Color3.fromRGB(52, 152, 219)
        end
    end

    trackBtn.MouseButton1Click:Connect(function()
        if trackingPlayer == player then
            stopTracking()
        else
            startTracking(player)
            if not autoMimic then toggleAutoMimic() end
        end
        refreshTrackBtn()
    end)

    btn.MouseEnter:Connect(function()
        if trackingPlayer ~= player then
            TweenService:Create(btn, TweenInfo.new(0.15), {BackgroundColor3 = Color3.fromRGB(45,45,45)}):Play()
        end
    end)
    btn.MouseLeave:Connect(function()
        if trackingPlayer ~= player then
            TweenService:Create(btn, TweenInfo.new(0.15), {BackgroundColor3 = Color3.fromRGB(30,30,30)}):Play()
        end
    end)
    btn.MouseButton1Click:Connect(function()
        -- clicking the row itself also toggles tracking
        if trackingPlayer == player then
            stopTracking()
        else
            startTracking(player)
            if not autoMimic then toggleAutoMimic() end
        end
        refreshTrackBtn()
    end)
    btn.MouseButton2Click:Connect(function()
        startTracking(player)
        if not autoMimic then toggleAutoMimic() end
        cycleMode()
        refreshTrackBtn()
    end)
    return btn
end

-- ╔══════════════════════════════════════╗
-- ║       EMOTE BUTTON                   ║
-- ╚══════════════════════════════════════╝
local function createEmoteButton(emoteData, parentFrame)
    local btn = Instance.new("TextButton")
    btn.Name = emoteData.name
    btn.Size = UDim2.new(1, -4, 0, 44)
    btn.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
    btn.BorderSizePixel = 0
    btn.Text = ""
    btn.AutoButtonColor = false
    btn.Parent = parentFrame
    do local c = Instance.new("UICorner"); c.CornerRadius = UDim.new(0,10); c.Parent = btn end

    local ei = Instance.new("TextLabel")
    ei.Size = UDim2.new(0, 28, 1, 0); ei.Position = UDim2.new(0, 8, 0, 0)
    ei.BackgroundTransparency = 1; ei.Text = "🎭"; ei.TextSize = 18; ei.Parent = btn

    local en = Instance.new("TextLabel")
    en.Size = UDim2.new(1, -90, 0, 22); en.Position = UDim2.new(0, 40, 0, 3)
    en.BackgroundTransparency = 1; en.Text = emoteData.name
    en.TextColor3 = Color3.fromRGB(255,255,255); en.Font = Enum.Font.GothamBold
    en.TextSize = 12; en.TextXAlignment = Enum.TextXAlignment.Left
    en.TextTruncate = Enum.TextTruncate.AtEnd; en.Parent = btn

    local inf = Instance.new("TextLabel")
    inf.Size = UDim2.new(1, -90, 0, 14); inf.Position = UDim2.new(0, 40, 0, 24)
    inf.BackgroundTransparency = 1
    inf.Text = emoteData.type == "equipped" and ("Slot " .. emoteData.slot) or "Inventory"
    inf.TextColor3 = Color3.fromRGB(130,130,130); inf.Font = Enum.Font.Gotham
    inf.TextSize = 10; inf.TextXAlignment = Enum.TextXAlignment.Left; inf.Parent = btn

    local ai = Instance.new("Frame")
    ai.Name = "ActiveIndicator"
    ai.Size = UDim2.new(0, 8, 0, 8); ai.Position = UDim2.new(1, -15, 0.5, -4)
    ai.BackgroundColor3 = Color3.fromRGB(46,204,113); ai.BorderSizePixel = 0
    ai.Visible = false; ai.Parent = btn
    do local c = Instance.new("UICorner"); c.CornerRadius = UDim.new(1,0); c.Parent = ai end

    local fb = Instance.new("TextButton")
    fb.Name = "FavButton"
    fb.Size = UDim2.new(0, 22, 0, 22); fb.Position = UDim2.new(1, -36, 0.5, -11)
    fb.BackgroundColor3 = Color3.fromRGB(50,50,50); fb.BorderSizePixel = 0
    fb.Text = table.find(favoriteEmotes, emoteData.name) and "⭐" or "☆"
    fb.TextColor3 = Color3.fromRGB(255,255,255); fb.Font = Enum.Font.GothamBold
    fb.TextSize = 12; fb.ZIndex = 3; fb.Parent = btn
    do local c = Instance.new("UICorner"); c.CornerRadius = UDim.new(0,4); c.Parent = fb end

    fb.MouseButton1Click:Connect(function()
        local idx = table.find(favoriteEmotes, emoteData.name)
        if idx then
            table.remove(favoriteEmotes, idx); fb.Text = "☆"
            showNotification("Removed from favorites", Color3.fromRGB(150,150,150))
        else
            table.insert(favoriteEmotes, emoteData.name); fb.Text = "⭐"
            showNotification("Added to favorites: " .. emoteData.name, Color3.fromRGB(241,196,15))
        end
        populateFavoritesList()
    end)

    btn.MouseEnter:Connect(function()
        if currentEmoteName ~= emoteData.name then
            TweenService:Create(btn, TweenInfo.new(0.15), {BackgroundColor3=Color3.fromRGB(45,45,45)}):Play()
        end
    end)
    btn.MouseLeave:Connect(function()
        if currentEmoteName ~= emoteData.name then
            TweenService:Create(btn, TweenInfo.new(0.15), {BackgroundColor3=Color3.fromRGB(30,30,30)}):Play()
        end
    end)

    local function clearAllEmoteHighlights()
        for _, fr in ipairs({emotesListFrame, favsListFrame}) do
            for _, b in ipairs(fr:GetChildren()) do
                if b:IsA("TextButton") then
                    b.BackgroundColor3 = Color3.fromRGB(30,30,30)
                    local ind = b:FindFirstChild("ActiveIndicator")
                    if ind then ind.Visible = false end
                end
            end
        end
    end

    btn.MouseButton1Click:Connect(function()
        if currentEmoteName == emoteData.name then
            stopCurrentEmote()
            btn.BackgroundColor3 = Color3.fromRGB(30,30,30)
            ai.Visible = false
        else
            clearAllEmoteHighlights()
            local ok = executeEmote(emoteData.name, emoteData)
            if ok then
                for _, fr in ipairs({emotesListFrame, favsListFrame}) do
                    for _, b in ipairs(fr:GetChildren()) do
                        if b:IsA("TextButton") and b.Name == emoteData.name then
                            b.BackgroundColor3 = Color3.fromRGB(52,152,219)
                            local ind = b:FindFirstChild("ActiveIndicator")
                            if ind then ind.Visible = true end
                        end
                    end
                end
            end
        end
    end)
    return btn
end

-- ╔══════════════════════════════════════╗
-- ║       LIST POPULATION                ║
-- ╚══════════════════════════════════════╝
function applySearchFilter()
    local q = searchQuery:lower()
    for _, b in ipairs(playerListFrame:GetChildren()) do
        if b:IsA("TextButton") then
            local p   = Players:FindFirstChild(b.Name)
            local hay = b.Name:lower() .. " " .. (p and p.DisplayName:lower() or "")
            b.Visible = (q == "" or hay:find(q, 1, true) ~= nil)
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
    if #inventoryEmotes == 0 then
        local l = Instance.new("TextLabel")
        l.Size = UDim2.new(1,0,0,50); l.BackgroundTransparency = 1
        l.Text = "No emotes found.\nClick 'Load Emotes' to refresh."
        l.TextColor3 = Color3.fromRGB(150,150,150); l.Font = Enum.Font.Gotham
        l.TextSize = 12; l.TextWrapped = true; l.Parent = emotesListFrame
    else
        for _, e in ipairs(inventoryEmotes) do createEmoteButton(e, emotesListFrame) end
    end
end

function populateFavoritesList()
    for _, c in ipairs(favsListFrame:GetChildren()) do
        if c:IsA("TextButton") or c:IsA("TextLabel") then c:Destroy() end
    end
    local n = 0
    for _, e in ipairs(inventoryEmotes) do
        if table.find(favoriteEmotes, e.name) then
            createEmoteButton(e, favsListFrame); n = n + 1
        end
    end
    if n == 0 then
        local l = Instance.new("TextLabel")
        l.Size = UDim2.new(1,0,0,50); l.BackgroundTransparency = 1
        l.Text = "No favorites yet.\nClick ☆ on an emote to add it."
        l.TextColor3 = Color3.fromRGB(150,150,150); l.Font = Enum.Font.Gotham
        l.TextSize = 12; l.TextWrapped = true; l.Parent = favsListFrame
    end
end

-- ╔══════════════════════════════════════╗
-- ║            TAB SWITCHING             ║
-- ╚══════════════════════════════════════╝
local currentTabName = "players"
local function showTab(tab)
    currentTabName = tab
    playerListFrame.Visible = (tab == "players")
    emotesListFrame.Visible = (tab == "emotes")
    favsListFrame.Visible   = (tab == "favs")
    searchBox.Visible       = (tab == "players")
    playerTabBtn.BackgroundColor3 = (tab=="players") and Color3.fromRGB(52,152,219) or Color3.fromRGB(35,35,35)
    emotesTabBtn.BackgroundColor3 = (tab=="emotes")  and Color3.fromRGB(52,152,219) or Color3.fromRGB(35,35,35)
    favsTabBtn.BackgroundColor3   = (tab=="favs")    and Color3.fromRGB(52,152,219) or Color3.fromRGB(35,35,35)
    if tab == "favs" then populateFavoritesList() end
end

playerTabBtn.MouseButton1Click:Connect(function() showTab("players") end)
emotesTabBtn.MouseButton1Click:Connect(function() showTab("emotes")  end)
favsTabBtn.MouseButton1Click:Connect(function()   showTab("favs")    end)

-- ╔══════════════════════════════════════╗
-- ║       PLAYER EVENTS                  ║
-- ╚══════════════════════════════════════╝
Players.PlayerAdded:Connect(function(p)
    if p ~= LocalPlayer then
        updatePlayerList()
        showNotification(p.DisplayName .. " joined", Color3.fromRGB(46,204,113))
    end
    -- auto re-track after respawn
    p.CharacterAdded:Connect(function()
        if trackingPlayer == p and autoMimic then
            task.wait(1)
            showNotification(p.DisplayName .. " respawned — re-tracking", Color3.fromRGB(241,196,15))
            startTracking(p)
        end
    end)
end)

Players.PlayerRemoving:Connect(function(p)
    if trackingPlayer == p then stopTracking() end
    task.defer(updatePlayerList)
end)

-- hook respawn for already-present players
for _, p in ipairs(Players:GetPlayers()) do
    p.CharacterAdded:Connect(function()
        if trackingPlayer == p and autoMimic then
            task.wait(1)
            showNotification(p.DisplayName .. " respawned — re-tracking", Color3.fromRGB(241,196,15))
            startTracking(p)
        end
    end)
end

-- ╔══════════════════════════════════════╗
-- ║        BUTTON WIRING                 ║
-- ╚══════════════════════════════════════╝
stopButton.MouseButton1Click:Connect(stopTracking)
autoMimicToggle.MouseButton1Click:Connect(toggleAutoMimic)
possessionToggle.MouseButton1Click:Connect(togglePossessionMode)
refreshButton.MouseButton1Click:Connect(function()
    updatePlayerList()
    showNotification("Player list refreshed", Color3.fromRGB(52,152,219))
end)
stopEmoteButton.MouseButton1Click:Connect(function()
    stopCurrentEmote()
    for _, fr in ipairs({emotesListFrame, favsListFrame}) do
        for _, b in ipairs(fr:GetChildren()) do
            if b:IsA("TextButton") then
                b.BackgroundColor3 = Color3.fromRGB(30,30,30)
                local i = b:FindFirstChild("ActiveIndicator"); if i then i.Visible = false end
            end
        end
    end
end)
refreshEmotesButton.MouseButton1Click:Connect(function()
    populateEmoteList(); populateFavoritesList()
    showNotification("Emotes reloaded", Color3.fromRGB(46,204,113))
end)
searchBox:GetPropertyChangedSignal("Text"):Connect(function()
    searchQuery = searchBox.Text; applySearchFilter()
end)
closeButton.MouseButton1Click:Connect(function()
    stopTracking(); stopCurrentEmote(); screenGui:Destroy()
end)

-- ╔══════════════════════════════════════╗
-- ║           MINIMIZE                   ║
-- ╚══════════════════════════════════════╝
local minimized = false
minimizeButton.MouseButton1Click:Connect(function()
    minimized = not minimized
    if minimized then
        playerListFrame.Visible = false; emotesListFrame.Visible = false; favsListFrame.Visible = false
        controlPanel.Visible = false; buttonFrame.Visible = false
        notificationFrame.Visible = false; tabFrame.Visible = false; searchBox.Visible = false
        mainFrame.Size = UDim2.new(0, 340, 0, 45)
        minimizeButton.Text = "+"
    else
        controlPanel.Visible = true; buttonFrame.Visible = true; tabFrame.Visible = true
        mainFrame.Size = UDim2.new(0, 340, 0, 560)
        minimizeButton.Text = "−"
        showTab(currentTabName)
    end
end)

-- ╔══════════════════════════════════════╗
-- ║       KEYBOARD SHORTCUTS             ║
-- ╚══════════════════════════════════════╝
UserInputService.InputBegan:Connect(function(input, gp)
    if gp then return end
    local k = input.KeyCode
    if     k == Enum.KeyCode.F then stopTracking()
    elseif k == Enum.KeyCode.G then toggleAutoMimic()
    elseif k == Enum.KeyCode.H then togglePossessionMode()
    elseif k == Enum.KeyCode.M then cycleMode()
    elseif k == Enum.KeyCode.E then
        stopCurrentEmote()
        for _, fr in ipairs({emotesListFrame, favsListFrame}) do
            for _, b in ipairs(fr:GetChildren()) do
                if b:IsA("TextButton") then
                    b.BackgroundColor3 = Color3.fromRGB(30,30,30)
                    local i = b:FindFirstChild("ActiveIndicator"); if i then i.Visible = false end
                end
            end
        end
    elseif k.Value >= Enum.KeyCode.One.Value and k.Value <= Enum.KeyCode.Nine.Value then
        local idx = k.Value - Enum.KeyCode.One.Value + 1
        if idx <= #inventoryEmotes then
            executeEmote(inventoryEmotes[idx].name, inventoryEmotes[idx])
        end
    end
end)

-- ╔══════════════════════════════════════╗
-- ║    CHARACTER RESPAWN (local)         ║
-- ╚══════════════════════════════════════╝
LocalPlayer.CharacterAdded:Connect(function(char)
    if isPlayingEmote and currentEmoteName then
        task.wait(0.5)
        pcall(function()
            local h = char:FindFirstChildOfClass("Humanoid")
            if h then h:PlayEmote(currentEmoteName) end
        end)
    end
end)

-- ╔══════════════════════════════════════╗
-- ║           CLEANUP                    ║
-- ╚══════════════════════════════════════╝
script.Destroying:Connect(function()
    stopTracking(); stopCurrentEmote()
    if screenGui then screenGui:Destroy() end
end)

-- ╔══════════════════════════════════════╗
-- ║            INIT                      ║
-- ╚══════════════════════════════════════╝
updatePlayerList()
populateEmoteList()
populateFavoritesList()
showTab("players")
showNotification("Possession Tracker v4 — press M to cycle modes", Color3.fromRGB(142,68,173))
