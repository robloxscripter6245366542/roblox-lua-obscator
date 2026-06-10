-- Advanced Player Tracker & Movement Mimic Script with Avatar Merging
-- Place in StarterGui or a LocalScript in StarterPlayerScripts
--
-- Behaviour:
--   * Mimic copies the target's EXACT CFrame every frame, so you sit on the
--     same coordinates, turn when they turn, and follow jumps/falls/swims.
--   * No camera takeover - your own camera stays under your control.
--   * Search box lets you filter the player list by name / display name.

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")
local LocalPlayer = Players.LocalPlayer

-- Create ScreenGui
local screenGui = Instance.new("ScreenGui")
screenGui.Name = "PlayerTracker"
screenGui.ResetOnSpawn = false
screenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
screenGui.Parent = LocalPlayer:WaitForChild("PlayerGui")

-- Main frame with modern dark theme and curved corners
local mainFrame = Instance.new("Frame")
mainFrame.Name = "MainFrame"
mainFrame.Size = UDim2.new(0, 340, 0, 520)
mainFrame.Position = UDim2.new(0.02, 0, 0.5, -260)
mainFrame.BackgroundColor3 = Color3.fromRGB(15, 15, 15)
mainFrame.BorderSizePixel = 0
mainFrame.Active = true
mainFrame.Draggable = true
mainFrame.Parent = screenGui

local uiCorner = Instance.new("UICorner")
uiCorner.CornerRadius = UDim.new(0, 14)
uiCorner.Parent = mainFrame

local gradient = Instance.new("UIGradient")
gradient.Color = ColorSequence.new({
    ColorSequenceKeypoint.new(0, Color3.fromRGB(25, 25, 25)),
    ColorSequenceKeypoint.new(1, Color3.fromRGB(15, 15, 15))
})
gradient.Rotation = 45
gradient.Parent = mainFrame

-- Title bar
local titleBar = Instance.new("Frame")
titleBar.Name = "TitleBar"
titleBar.Size = UDim2.new(1, 0, 0, 45)
titleBar.BackgroundColor3 = Color3.fromRGB(25, 25, 25)
titleBar.BorderSizePixel = 0
titleBar.Parent = mainFrame

local titleCorner = Instance.new("UICorner")
titleCorner.CornerRadius = UDim.new(0, 14)
titleCorner.Parent = titleBar

local titleText = Instance.new("TextLabel")
titleText.Name = "TitleText"
titleText.Size = UDim2.new(1, -90, 1, 0)
titleText.Position = UDim2.new(0, 15, 0, 0)
titleText.BackgroundTransparency = 1
titleText.Text = "👻 Possession Tracker"
titleText.TextColor3 = Color3.fromRGB(255, 255, 255)
titleText.Font = Enum.Font.GothamBold
titleText.TextSize = 16
titleText.TextXAlignment = Enum.TextXAlignment.Left
titleText.Parent = titleBar

local closeButton = Instance.new("TextButton")
closeButton.Name = "CloseButton"
closeButton.Size = UDim2.new(0, 30, 0, 30)
closeButton.Position = UDim2.new(1, -35, 0.5, -15)
closeButton.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
closeButton.BorderSizePixel = 0
closeButton.Text = "✕"
closeButton.TextColor3 = Color3.fromRGB(255, 255, 255)
closeButton.Font = Enum.Font.GothamBold
closeButton.TextSize = 14
closeButton.Parent = titleBar

local closeCorner = Instance.new("UICorner")
closeCorner.CornerRadius = UDim.new(0, 8)
closeCorner.Parent = closeButton

local minimizeButton = Instance.new("TextButton")
minimizeButton.Name = "MinimizeButton"
minimizeButton.Size = UDim2.new(0, 30, 0, 30)
minimizeButton.Position = UDim2.new(1, -70, 0.5, -15)
minimizeButton.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
minimizeButton.BorderSizePixel = 0
minimizeButton.Text = "−"
minimizeButton.TextColor3 = Color3.fromRGB(255, 255, 255)
minimizeButton.Font = Enum.Font.GothamBold
minimizeButton.TextSize = 18
minimizeButton.Parent = titleBar

local minCorner = Instance.new("UICorner")
minCorner.CornerRadius = UDim.new(0, 8)
minCorner.Parent = minimizeButton

-- Tab system
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
playerTabBtn.BackgroundColor3 = Color3.fromRGB(52, 152, 219)
playerTabBtn.BorderSizePixel = 0
playerTabBtn.Text = "👥 Players"
playerTabBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
playerTabBtn.Font = Enum.Font.GothamBold
playerTabBtn.TextSize = 11
playerTabBtn.Parent = tabFrame

local playerTabCorner = Instance.new("UICorner")
playerTabCorner.CornerRadius = UDim.new(0, 8)
playerTabCorner.Parent = playerTabBtn

local emotesTabBtn = Instance.new("TextButton")
emotesTabBtn.Name = "EmotesTab"
emotesTabBtn.Size = UDim2.new(0.34, -2, 1, 0)
emotesTabBtn.Position = UDim2.new(0.33, 2, 0, 0)
emotesTabBtn.BackgroundColor3 = Color3.fromRGB(35, 35, 35)
emotesTabBtn.BorderSizePixel = 0
emotesTabBtn.Text = "🎭 My Emotes"
emotesTabBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
emotesTabBtn.Font = Enum.Font.GothamBold
emotesTabBtn.TextSize = 11
emotesTabBtn.Parent = tabFrame

local emotesTabCorner = Instance.new("UICorner")
emotesTabCorner.CornerRadius = UDim.new(0, 8)
emotesTabCorner.Parent = emotesTabBtn

local favsTabBtn = Instance.new("TextButton")
favsTabBtn.Name = "FavsTab"
favsTabBtn.Size = UDim2.new(0.33, -3, 1, 0)
favsTabBtn.Position = UDim2.new(0.67, 3, 0, 0)
favsTabBtn.BackgroundColor3 = Color3.fromRGB(35, 35, 35)
favsTabBtn.BorderSizePixel = 0
favsTabBtn.Text = "⭐ Favorites"
favsTabBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
favsTabBtn.Font = Enum.Font.GothamBold
favsTabBtn.TextSize = 11
favsTabBtn.Parent = tabFrame

local favsTabCorner = Instance.new("UICorner")
favsTabCorner.CornerRadius = UDim.new(0, 8)
favsTabCorner.Parent = favsTabBtn

-- Control panel frame
local controlPanel = Instance.new("Frame")
controlPanel.Name = "ControlPanel"
controlPanel.Size = UDim2.new(1, -10, 0, 176)
controlPanel.Position = UDim2.new(0, 5, 0, 90)
controlPanel.BackgroundTransparency = 1
controlPanel.BorderSizePixel = 0
controlPanel.Parent = mainFrame

-- Player count text
local playerCountText = Instance.new("TextLabel")
playerCountText.Name = "PlayerCount"
playerCountText.Size = UDim2.new(1, 0, 0, 18)
playerCountText.Position = UDim2.new(0, 0, 0, 0)
playerCountText.BackgroundTransparency = 1
playerCountText.Text = "Players Online: 0"
playerCountText.TextColor3 = Color3.fromRGB(150, 150, 150)
playerCountText.Font = Enum.Font.Gotham
playerCountText.TextSize = 12
playerCountText.TextXAlignment = Enum.TextXAlignment.Left
playerCountText.Parent = controlPanel

-- Auto mimic toggle
local autoMimicToggle = Instance.new("TextButton")
autoMimicToggle.Name = "AutoMimicToggle"
autoMimicToggle.Size = UDim2.new(1, 0, 0, 30)
autoMimicToggle.Position = UDim2.new(0, 0, 0, 22)
autoMimicToggle.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
autoMimicToggle.BorderSizePixel = 0
autoMimicToggle.Text = "    🔴 Auto Mimic: OFF"
autoMimicToggle.TextColor3 = Color3.fromRGB(255, 255, 255)
autoMimicToggle.Font = Enum.Font.GothamBold
autoMimicToggle.TextSize = 12
autoMimicToggle.Parent = controlPanel

local mimicCorner = Instance.new("UICorner")
mimicCorner.CornerRadius = UDim.new(0, 8)
mimicCorner.Parent = autoMimicToggle

local mimicIndicator = Instance.new("Frame")
mimicIndicator.Name = "MimicIndicator"
mimicIndicator.Size = UDim2.new(0, 10, 0, 10)
mimicIndicator.Position = UDim2.new(0, 8, 0.5, -5)
mimicIndicator.BackgroundColor3 = Color3.fromRGB(231, 76, 60)
mimicIndicator.BorderSizePixel = 0
mimicIndicator.Parent = autoMimicToggle

local mimicIndicatorCorner = Instance.new("UICorner")
mimicIndicatorCorner.CornerRadius = UDim.new(1, 0)
mimicIndicatorCorner.Parent = mimicIndicator

-- Possession mode toggle (controls whether you go invisible while merged)
local possessionToggle = Instance.new("TextButton")
possessionToggle.Name = "PossessionToggle"
possessionToggle.Size = UDim2.new(1, 0, 0, 30)
possessionToggle.Position = UDim2.new(0, 0, 0, 56)
possessionToggle.BackgroundColor3 = Color3.fromRGB(142, 68, 173)
possessionToggle.BorderSizePixel = 0
possessionToggle.Text = "    👻 Possession Mode: ON"
possessionToggle.TextColor3 = Color3.fromRGB(255, 255, 255)
possessionToggle.Font = Enum.Font.GothamBold
possessionToggle.TextSize = 12
possessionToggle.Parent = controlPanel

local possessionCorner = Instance.new("UICorner")
possessionCorner.CornerRadius = UDim.new(0, 8)
possessionCorner.Parent = possessionToggle

local possessionIndicator = Instance.new("Frame")
possessionIndicator.Name = "PossessionIndicator"
possessionIndicator.Size = UDim2.new(0, 10, 0, 10)
possessionIndicator.Position = UDim2.new(0, 8, 0.5, -5)
possessionIndicator.BackgroundColor3 = Color3.fromRGB(46, 204, 113)
possessionIndicator.BorderSizePixel = 0
possessionIndicator.Parent = possessionToggle

local possessionIndicatorCorner = Instance.new("UICorner")
possessionIndicatorCorner.CornerRadius = UDim.new(1, 0)
possessionIndicatorCorner.Parent = possessionIndicator

-- Current emote display
local currentEmoteLabel = Instance.new("TextLabel")
currentEmoteLabel.Name = "CurrentEmote"
currentEmoteLabel.Size = UDim2.new(1, 0, 0, 18)
currentEmoteLabel.Position = UDim2.new(0, 0, 0, 90)
currentEmoteLabel.BackgroundTransparency = 1
currentEmoteLabel.Text = "🎭 Current Emote: None"
currentEmoteLabel.TextColor3 = Color3.fromRGB(200, 200, 200)
currentEmoteLabel.Font = Enum.Font.Gotham
currentEmoteLabel.TextSize = 11
currentEmoteLabel.TextXAlignment = Enum.TextXAlignment.Left
currentEmoteLabel.Parent = controlPanel

-- Stop emote button
local stopEmoteButton = Instance.new("TextButton")
stopEmoteButton.Name = "StopEmoteButton"
stopEmoteButton.Size = UDim2.new(0.5, -3, 0, 26)
stopEmoteButton.Position = UDim2.new(0, 0, 0, 112)
stopEmoteButton.BackgroundColor3 = Color3.fromRGB(60, 60, 60)
stopEmoteButton.BorderSizePixel = 0
stopEmoteButton.Text = "⏹ Stop Emote"
stopEmoteButton.TextColor3 = Color3.fromRGB(255, 255, 255)
stopEmoteButton.Font = Enum.Font.GothamBold
stopEmoteButton.TextSize = 11
stopEmoteButton.Parent = controlPanel

local stopEmoteCorner = Instance.new("UICorner")
stopEmoteCorner.CornerRadius = UDim.new(0, 6)
stopEmoteCorner.Parent = stopEmoteButton

-- Refresh emotes button
local refreshEmotesButton = Instance.new("TextButton")
refreshEmotesButton.Name = "RefreshEmotesButton"
refreshEmotesButton.Size = UDim2.new(0.5, -3, 0, 26)
refreshEmotesButton.Position = UDim2.new(0.5, 3, 0, 112)
refreshEmotesButton.BackgroundColor3 = Color3.fromRGB(46, 204, 113)
refreshEmotesButton.BorderSizePixel = 0
refreshEmotesButton.Text = "🔄 Load Emotes"
refreshEmotesButton.TextColor3 = Color3.fromRGB(255, 255, 255)
refreshEmotesButton.Font = Enum.Font.GothamBold
refreshEmotesButton.TextSize = 11
refreshEmotesButton.Parent = controlPanel

local refreshEmotesCorner = Instance.new("UICorner")
refreshEmotesCorner.CornerRadius = UDim.new(0, 6)
refreshEmotesCorner.Parent = refreshEmotesButton

-- Search box (filters the player list)
local searchBox = Instance.new("TextBox")
searchBox.Name = "SearchBox"
searchBox.Size = UDim2.new(1, -10, 0, 30)
searchBox.Position = UDim2.new(0, 5, 0, 272)
searchBox.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
searchBox.BorderSizePixel = 0
searchBox.Text = ""
searchBox.PlaceholderText = "🔍 Search players..."
searchBox.PlaceholderColor3 = Color3.fromRGB(120, 120, 120)
searchBox.TextColor3 = Color3.fromRGB(255, 255, 255)
searchBox.Font = Enum.Font.Gotham
searchBox.TextSize = 12
searchBox.TextXAlignment = Enum.TextXAlignment.Left
searchBox.ClearTextOnFocus = false
searchBox.Parent = mainFrame

local searchCorner = Instance.new("UICorner")
searchCorner.CornerRadius = UDim.new(0, 8)
searchCorner.Parent = searchBox

local searchPadding = Instance.new("UIPadding")
searchPadding.PaddingLeft = UDim.new(0, 10)
searchPadding.Parent = searchBox

-- Player List
local playerListFrame = Instance.new("ScrollingFrame")
playerListFrame.Name = "PlayerList"
playerListFrame.Size = UDim2.new(1, -10, 1, -360)
playerListFrame.Position = UDim2.new(0, 5, 0, 308)
playerListFrame.BackgroundTransparency = 1
playerListFrame.BorderSizePixel = 0
playerListFrame.ScrollBarThickness = 3
playerListFrame.ScrollBarImageColor3 = Color3.fromRGB(80, 80, 80)
playerListFrame.CanvasSize = UDim2.new(0, 0, 0, 0)
playerListFrame.AutomaticCanvasSize = Enum.AutomaticSize.Y
playerListFrame.ScrollingDirection = Enum.ScrollingDirection.Y
playerListFrame.Visible = true
playerListFrame.Parent = mainFrame

local playerListLayout = Instance.new("UIListLayout")
playerListLayout.Padding = UDim.new(0, 4)
playerListLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
playerListLayout.SortOrder = Enum.SortOrder.Name
playerListLayout.Parent = playerListFrame

local playerScrollPadding = Instance.new("UIPadding")
playerScrollPadding.PaddingLeft = UDim.new(0, 2)
playerScrollPadding.PaddingRight = UDim.new(0, 2)
playerScrollPadding.PaddingTop = UDim.new(0, 2)
playerScrollPadding.Parent = playerListFrame

-- Emotes List
local emotesListFrame = Instance.new("ScrollingFrame")
emotesListFrame.Name = "EmotesList"
emotesListFrame.Size = UDim2.new(1, -10, 1, -360)
emotesListFrame.Position = UDim2.new(0, 5, 0, 308)
emotesListFrame.BackgroundTransparency = 1
emotesListFrame.BorderSizePixel = 0
emotesListFrame.ScrollBarThickness = 3
emotesListFrame.ScrollBarImageColor3 = Color3.fromRGB(80, 80, 80)
emotesListFrame.CanvasSize = UDim2.new(0, 0, 0, 0)
emotesListFrame.AutomaticCanvasSize = Enum.AutomaticSize.Y
emotesListFrame.ScrollingDirection = Enum.ScrollingDirection.Y
emotesListFrame.Visible = false
emotesListFrame.Parent = mainFrame

local emotesListLayout = Instance.new("UIListLayout")
emotesListLayout.Padding = UDim.new(0, 4)
emotesListLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
emotesListLayout.SortOrder = Enum.SortOrder.Name
emotesListLayout.Parent = emotesListFrame

local emotesScrollPadding = Instance.new("UIPadding")
emotesScrollPadding.PaddingLeft = UDim.new(0, 2)
emotesScrollPadding.PaddingRight = UDim.new(0, 2)
emotesScrollPadding.PaddingTop = UDim.new(0, 2)
emotesScrollPadding.Parent = emotesListFrame

-- Favorites List
local favsListFrame = Instance.new("ScrollingFrame")
favsListFrame.Name = "FavsList"
favsListFrame.Size = UDim2.new(1, -10, 1, -360)
favsListFrame.Position = UDim2.new(0, 5, 0, 308)
favsListFrame.BackgroundTransparency = 1
favsListFrame.BorderSizePixel = 0
favsListFrame.ScrollBarThickness = 3
favsListFrame.ScrollBarImageColor3 = Color3.fromRGB(80, 80, 80)
favsListFrame.CanvasSize = UDim2.new(0, 0, 0, 0)
favsListFrame.AutomaticCanvasSize = Enum.AutomaticSize.Y
favsListFrame.ScrollingDirection = Enum.ScrollingDirection.Y
favsListFrame.Visible = false
favsListFrame.Parent = mainFrame

local favsListLayout = Instance.new("UIListLayout")
favsListLayout.Padding = UDim.new(0, 4)
favsListLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
favsListLayout.SortOrder = Enum.SortOrder.Name
favsListLayout.Parent = favsListFrame

local favsScrollPadding = Instance.new("UIPadding")
favsScrollPadding.PaddingLeft = UDim.new(0, 2)
favsScrollPadding.PaddingRight = UDim.new(0, 2)
favsScrollPadding.PaddingTop = UDim.new(0, 2)
favsScrollPadding.Parent = favsListFrame

-- Bottom control buttons
local buttonFrame = Instance.new("Frame")
buttonFrame.Name = "ButtonFrame"
buttonFrame.Size = UDim2.new(1, -10, 0, 40)
buttonFrame.Position = UDim2.new(0, 5, 1, -46)
buttonFrame.BackgroundTransparency = 1
buttonFrame.BorderSizePixel = 0
buttonFrame.Parent = mainFrame

local stopButton = Instance.new("TextButton")
stopButton.Name = "StopButton"
stopButton.Size = UDim2.new(0.7, -3, 1, 0)
stopButton.BackgroundColor3 = Color3.fromRGB(231, 76, 60)
stopButton.BorderSizePixel = 0
stopButton.Text = "⏹ Stop Tracking"
stopButton.TextColor3 = Color3.fromRGB(255, 255, 255)
stopButton.Font = Enum.Font.GothamBold
stopButton.TextSize = 13
stopButton.Parent = buttonFrame

local stopCorner = Instance.new("UICorner")
stopCorner.CornerRadius = UDim.new(0, 8)
stopCorner.Parent = stopButton

local refreshButton = Instance.new("TextButton")
refreshButton.Name = "RefreshButton"
refreshButton.Size = UDim2.new(0.3, -3, 1, 0)
refreshButton.Position = UDim2.new(0.7, 6, 0, 0)
refreshButton.BackgroundColor3 = Color3.fromRGB(52, 152, 219)
refreshButton.BorderSizePixel = 0
refreshButton.Text = "🔄"
refreshButton.TextColor3 = Color3.fromRGB(255, 255, 255)
refreshButton.Font = Enum.Font.GothamBold
refreshButton.TextSize = 16
refreshButton.Parent = buttonFrame

local refreshCorner = Instance.new("UICorner")
refreshCorner.CornerRadius = UDim.new(0, 8)
refreshCorner.Parent = refreshButton

-- Notification frame
local notificationFrame = Instance.new("Frame")
notificationFrame.Name = "Notification"
notificationFrame.Size = UDim2.new(1, 0, 0, 30)
notificationFrame.Position = UDim2.new(0, 0, 0, -35)
notificationFrame.BackgroundColor3 = Color3.fromRGB(46, 204, 113)
notificationFrame.BorderSizePixel = 0
notificationFrame.Visible = false
notificationFrame.Parent = mainFrame

local notifCorner = Instance.new("UICorner")
notifCorner.CornerRadius = UDim.new(0, 8)
notifCorner.Parent = notificationFrame

local notificationText = Instance.new("TextLabel")
notificationText.Size = UDim2.new(1, 0, 1, 0)
notificationText.BackgroundTransparency = 1
notificationText.Text = ""
notificationText.TextColor3 = Color3.fromRGB(255, 255, 255)
notificationText.Font = Enum.Font.GothamBold
notificationText.TextSize = 12
notificationText.Parent = notificationFrame

-- Variables
local trackingPlayer = nil
local trackConnection = nil
local autoMimic = false
local possessionMode = true
local currentEmote = nil
local currentEmoteName = nil
local currentEmoteTrack = nil
local isPlayingEmote = false
local inventoryEmotes = {}
local favoriteEmotes = {}
local searchQuery = ""

-- Forward declarations (referenced inside closures created before their bodies).
local populateEmoteList
local populateFavoritesList
local applySearchFilter

-- Function to get player's inventory emotes
local function getInventoryEmotes()
    local emotes = {}

    pcall(function()
        local humanoidDescription = LocalPlayer.Character and LocalPlayer.Character:FindFirstChildOfClass("HumanoidDescription")
        if not humanoidDescription then
            humanoidDescription = Players:GetHumanoidDescriptionFromUserId(LocalPlayer.UserId)
        end

        if humanoidDescription then
            for i = 1, 8 do
                local emoteName = humanoidDescription["Emote" .. i]
                if emoteName and emoteName ~= "" then
                    table.insert(emotes, {
                        name = emoteName,
                        slot = i,
                        type = "equipped"
                    })
                end
            end
        end
    end)

    pcall(function()
        local emoteService = game:GetService("EmotesService")
        if emoteService then
            local equippedEmotes = emoteService:GetEmotesForUserId(LocalPlayer.UserId)
            if equippedEmotes then
                for _, emoteData in pairs(equippedEmotes) do
                    local exists = false
                    for _, existing in ipairs(emotes) do
                        if existing.name == emoteData.Name then
                            exists = true
                            break
                        end
                    end
                    if not exists then
                        table.insert(emotes, {
                            name = emoteData.Name,
                            slot = emoteData.Slot or 0,
                            type = "inventory"
                        })
                    end
                end
            end
        end
    end)

    return emotes
end

-- Function to play an emote using the game's built-in emote system
local function playInventoryEmote(emoteName)
    local character = LocalPlayer.Character
    if not character then return false end

    local humanoid = character:FindFirstChildOfClass("Humanoid")
    if not humanoid then return false end

    local success = pcall(function()
        humanoid:PlayEmote(emoteName)
    end)

    if success then
        return true
    end

    success = pcall(function()
        local emoteService = game:GetService("EmotesService")
        if emoteService then
            emoteService:PlayEmote(LocalPlayer, emoteName)
        end
    end)

    return success
end

-- Restore our own character transparency to fully visible
local function setSelfVisible()
    local myCharacter = LocalPlayer.Character
    if not myCharacter then return end
    for _, part in ipairs(myCharacter:GetDescendants()) do
        if part:IsA("BasePart") and part.Name ~= "HumanoidRootPart" then
            part.LocalTransparencyModifier = 0
            part.Transparency = 0
        elseif part:IsA("Decal") then
            part.Transparency = 0
        end
    end
end

-- Make our own character fade out (used while possessing/merged)
local function setSelfTransparent()
    local myCharacter = LocalPlayer.Character
    if not myCharacter then return end
    for _, part in ipairs(myCharacter:GetDescendants()) do
        if part:IsA("BasePart") and part.Name ~= "HumanoidRootPart" then
            part.LocalTransparencyModifier = 0.7
        elseif part:IsA("Decal") then
            part.Transparency = 0.7
        end
    end
end

-- Function to show notification
local function showNotification(message, color)
    notificationFrame.BackgroundColor3 = color or Color3.fromRGB(46, 204, 113)
    notificationText.Text = message
    notificationFrame.Visible = true
    notificationFrame.BackgroundTransparency = 0

    task.spawn(function()
        task.wait(2)
        local fadeTween = TweenService:Create(notificationFrame, TweenInfo.new(0.5), {
            BackgroundTransparency = 1
        })
        fadeTween:Play()
        fadeTween.Completed:Wait()
        notificationFrame.Visible = false
        notificationFrame.BackgroundTransparency = 0
    end)
end

-- Function to mimic the target's movement: copy its EXACT CFrame and velocity
-- every frame, and mirror jump / other humanoid states so we follow perfectly.
function mimicPlayerMovement(myCharacter, targetCharacter)
    local myHumanoid = myCharacter:FindFirstChildOfClass("Humanoid")
    local myRootPart = myCharacter:FindFirstChild("HumanoidRootPart")
    local targetHumanoid = targetCharacter:FindFirstChildOfClass("Humanoid")
    local targetRootPart = targetCharacter:FindFirstChild("HumanoidRootPart")

    if not (myHumanoid and myRootPart and targetHumanoid and targetRootPart) then
        return
    end

    -- Exact same coordinates and orientation (we turn whenever they turn).
    myRootPart.CFrame = targetRootPart.CFrame
    myRootPart.AssemblyLinearVelocity = targetRootPart.AssemblyLinearVelocity
    myRootPart.AssemblyAngularVelocity = targetRootPart.AssemblyAngularVelocity

    -- Match movement tuning so our humanoid behaves the same.
    myHumanoid.WalkSpeed = targetHumanoid.WalkSpeed
    myHumanoid.JumpPower = targetHumanoid.JumpPower
    myHumanoid.JumpHeight = targetHumanoid.JumpHeight

    -- Mirror jumping so our jump animation/physics track theirs.
    local targetState = targetHumanoid:GetState()
    if targetHumanoid.Jump or targetState == Enum.HumanoidStateType.Jumping then
        myHumanoid.Jump = true
        myHumanoid:ChangeState(Enum.HumanoidStateType.Jumping)
    elseif targetState == Enum.HumanoidStateType.Freefall then
        myHumanoid:ChangeState(Enum.HumanoidStateType.Freefall)
    elseif targetState == Enum.HumanoidStateType.Seated and not myHumanoid.Sit then
        -- target sat down; let our exact-CFrame copy keep us aligned
    end
end

-- Function to start tracking
function startTracking(player)
    stopTracking()

    if not player or not player.Character then
        showNotification("That player has no character yet", Color3.fromRGB(231, 76, 60))
        return
    end

    trackingPlayer = player

    updateButtonVisuals()

    stopButton.BackgroundColor3 = Color3.fromRGB(231, 76, 60)
    stopButton.Text = "⏹ Stop Tracking " .. player.DisplayName

    local character = LocalPlayer.Character
    if not character then
        LocalPlayer.CharacterAdded:Wait()
        character = LocalPlayer.Character
    end
    character:WaitForChild("Humanoid")

    -- Drive the mimic from the physics step so CFrame writes replicate smoothly.
    trackConnection = RunService.Heartbeat:Connect(function()
        local myCharacter = LocalPlayer.Character
        if not (trackingPlayer and trackingPlayer.Character and myCharacter) then
            return
        end

        if autoMimic then
            mimicPlayerMovement(myCharacter, trackingPlayer.Character)
            if possessionMode then
                setSelfTransparent()
            else
                setSelfVisible()
            end
        end
    end)

    showNotification("Now tracking: " .. player.DisplayName, Color3.fromRGB(46, 204, 113))
end

-- Function to stop tracking
function stopTracking()
    if trackConnection then
        trackConnection:Disconnect()
        trackConnection = nil
    end

    setSelfVisible()
    trackingPlayer = nil

    if LocalPlayer.Character then
        local humanoid = LocalPlayer.Character:FindFirstChildOfClass("Humanoid")
        if humanoid then
            humanoid.WalkSpeed = 16
            humanoid.Jump = false
            humanoid.Sit = false
        end
    end

    resetButtonVisuals()

    stopButton.BackgroundColor3 = Color3.fromRGB(231, 76, 60)
    stopButton.Text = "⏹ Stop Tracking"
end

-- Toggle auto mimic
function toggleAutoMimic()
    autoMimic = not autoMimic

    if autoMimic then
        autoMimicToggle.Text = "    🟢 Auto Mimic: ON"
        autoMimicToggle.BackgroundColor3 = Color3.fromRGB(46, 204, 113)
        mimicIndicator.BackgroundColor3 = Color3.fromRGB(46, 204, 113)
        showNotification("Auto Mimic Enabled", Color3.fromRGB(46, 204, 113))
    else
        autoMimicToggle.Text = "    🔴 Auto Mimic: OFF"
        autoMimicToggle.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
        mimicIndicator.BackgroundColor3 = Color3.fromRGB(231, 76, 60)
        setSelfVisible()
        showNotification("Auto Mimic Disabled", Color3.fromRGB(150, 150, 150))
    end
end

-- Toggle possession mode (invisible while merged)
function togglePossessionMode()
    possessionMode = not possessionMode

    if possessionMode then
        possessionToggle.Text = "    👻 Possession Mode: ON"
        possessionToggle.BackgroundColor3 = Color3.fromRGB(142, 68, 173)
        possessionIndicator.BackgroundColor3 = Color3.fromRGB(46, 204, 113)
        showNotification("Possession Mode: invisible while merged", Color3.fromRGB(142, 68, 173))
    else
        possessionToggle.Text = "    👻 Possession Mode: OFF"
        possessionToggle.BackgroundColor3 = Color3.fromRGB(60, 60, 60)
        possessionIndicator.BackgroundColor3 = Color3.fromRGB(150, 150, 150)
        setSelfVisible()
        showNotification("Possession Mode Disabled", Color3.fromRGB(150, 150, 150))
    end
end

-- Function to stop current emote
local function stopCurrentEmote()
    if currentEmoteTrack then
        pcall(function()
            currentEmoteTrack:Stop()
        end)
        currentEmoteTrack = nil
    end

    pcall(function()
        local character = LocalPlayer.Character
        if character then
            local humanoid = character:FindFirstChildOfClass("Humanoid")
            if humanoid then
                for _, track in ipairs(humanoid:GetPlayingAnimationTracks()) do
                    track:Stop()
                end
            end
        end
    end)

    currentEmote = nil
    currentEmoteName = nil
    isPlayingEmote = false
    currentEmoteLabel.Text = "🎭 Current Emote: None"
end

-- Function to execute an emote
local function executeEmote(emoteName, emoteData)
    stopCurrentEmote()

    local success = playInventoryEmote(emoteName)

    if success then
        currentEmote = emoteData
        currentEmoteName = emoteName
        isPlayingEmote = true
        currentEmoteLabel.Text = "🎭 Current Emote: " .. emoteName
        showNotification("Playing: " .. emoteName, Color3.fromRGB(52, 152, 219))
    else
        showNotification("Failed to play emote: " .. emoteName, Color3.fromRGB(231, 76, 60))
    end

    return success
end

-- Update button visuals
function updateButtonVisuals()
    for _, button in ipairs(playerListFrame:GetChildren()) do
        if button:IsA("TextButton") then
            local statusIndicator = button:FindFirstChild("StatusIndicator")
            local trackIcon = button:FindFirstChild("TrackIcon")
            local isTracked = (trackingPlayer ~= nil and button.Name == trackingPlayer.Name)

            if statusIndicator then
                statusIndicator.Visible = isTracked
            end
            if trackIcon then
                trackIcon.Text = isTracked and "👻" or "👤"
            end
            button.BackgroundColor3 = isTracked and Color3.fromRGB(142, 68, 173) or Color3.fromRGB(30, 30, 30)
        end
    end
end

-- Reset button visuals
function resetButtonVisuals()
    for _, button in ipairs(playerListFrame:GetChildren()) do
        if button:IsA("TextButton") then
            button.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
            local statusIndicator = button:FindFirstChild("StatusIndicator")
            local trackIcon = button:FindFirstChild("TrackIcon")
            if statusIndicator then
                statusIndicator.Visible = false
            end
            if trackIcon then
                trackIcon.Text = "👤"
            end
        end
    end
end

-- Function to create player button
local function createPlayerButton(player)
    local playerButton = Instance.new("TextButton")
    playerButton.Name = player.Name
    playerButton.Size = UDim2.new(1, -4, 0, 50)
    playerButton.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
    playerButton.BorderSizePixel = 0
    playerButton.Text = ""
    playerButton.AutoButtonColor = false
    playerButton.ClipsDescendants = true
    playerButton.Parent = playerListFrame

    local buttonCorner = Instance.new("UICorner")
    buttonCorner.CornerRadius = UDim.new(0, 10)
    buttonCorner.Parent = playerButton

    local playerIcon = Instance.new("Frame")
    playerIcon.Name = "PlayerIcon"
    playerIcon.Size = UDim2.new(0, 36, 0, 36)
    playerIcon.Position = UDim2.new(0, 8, 0.5, -18)
    playerIcon.BackgroundColor3 = Color3.fromRGB(52, 152, 219)
    playerIcon.BorderSizePixel = 0
    playerIcon.Parent = playerButton

    local iconCorner = Instance.new("UICorner")
    iconCorner.CornerRadius = UDim.new(1, 0)
    iconCorner.Parent = playerIcon

    local iconText = Instance.new("TextLabel")
    iconText.Size = UDim2.new(1, 0, 1, 0)
    iconText.BackgroundTransparency = 1
    iconText.Text = player.Name:sub(1, 1):upper()
    iconText.TextColor3 = Color3.fromRGB(255, 255, 255)
    iconText.Font = Enum.Font.GothamBold
    iconText.TextSize = 16
    iconText.Parent = playerIcon

    local trackIcon = Instance.new("TextLabel")
    trackIcon.Name = "TrackIcon"
    trackIcon.Size = UDim2.new(0, 16, 0, 16)
    trackIcon.Position = UDim2.new(0, 30, 1, -20)
    trackIcon.BackgroundTransparency = 1
    trackIcon.Text = "👤"
    trackIcon.TextSize = 12
    trackIcon.ZIndex = 2
    trackIcon.Parent = playerButton

    local nameText = Instance.new("TextLabel")
    nameText.Name = "NameText"
    nameText.Size = UDim2.new(1, -65, 0, 20)
    nameText.Position = UDim2.new(0, 52, 0, 8)
    nameText.BackgroundTransparency = 1
    nameText.Text = player.DisplayName ~= player.Name and player.DisplayName .. " (@" .. player.Name .. ")" or player.Name
    nameText.TextColor3 = Color3.fromRGB(255, 255, 255)
    nameText.Font = Enum.Font.GothamBold
    nameText.TextSize = 13
    nameText.TextXAlignment = Enum.TextXAlignment.Left
    nameText.TextTruncate = Enum.TextTruncate.AtEnd
    nameText.Parent = playerButton

    local statusText = Instance.new("TextLabel")
    statusText.Name = "StatusText"
    statusText.Size = UDim2.new(1, -65, 0, 16)
    statusText.Position = UDim2.new(0, 52, 0, 28)
    statusText.BackgroundTransparency = 1
    statusText.Text = "Click to track"
    statusText.TextColor3 = Color3.fromRGB(150, 150, 150)
    statusText.Font = Enum.Font.Gotham
    statusText.TextSize = 10
    statusText.TextXAlignment = Enum.TextXAlignment.Left
    statusText.Parent = playerButton

    local statusIndicator = Instance.new("Frame")
    statusIndicator.Name = "StatusIndicator"
    statusIndicator.Size = UDim2.new(0, 10, 0, 10)
    statusIndicator.Position = UDim2.new(1, -15, 0, 8)
    statusIndicator.BackgroundColor3 = Color3.fromRGB(46, 204, 113)
    statusIndicator.BorderSizePixel = 0
    statusIndicator.Visible = false
    statusIndicator.Parent = playerButton

    local statusCorner = Instance.new("UICorner")
    statusCorner.CornerRadius = UDim.new(1, 0)
    statusCorner.Parent = statusIndicator

    playerButton.MouseEnter:Connect(function()
        if trackingPlayer ~= player then
            TweenService:Create(playerButton, TweenInfo.new(0.2), {
                BackgroundColor3 = Color3.fromRGB(45, 45, 45)
            }):Play()
        end
    end)

    playerButton.MouseLeave:Connect(function()
        if trackingPlayer ~= player then
            TweenService:Create(playerButton, TweenInfo.new(0.2), {
                BackgroundColor3 = Color3.fromRGB(30, 30, 30)
            }):Play()
        end
    end)

    playerButton.MouseButton1Click:Connect(function()
        if trackingPlayer == player then
            stopTracking()
        else
            startTracking(player)
            if not autoMimic then
                toggleAutoMimic()
            end
            for _, btn in ipairs(playerListFrame:GetChildren()) do
                if btn:IsA("TextButton") then
                    local st = btn:FindFirstChild("StatusText")
                    if st then
                        st.Text = (btn.Name == player.Name) and "👻 Possessing" or "Click to track"
                    end
                end
            end
        end
    end)

    return playerButton
end

-- Filter player buttons by the current search query
function applySearchFilter()
    local query = searchQuery:lower()
    for _, btn in ipairs(playerListFrame:GetChildren()) do
        if btn:IsA("TextButton") then
            local player = Players:FindFirstChild(btn.Name)
            local haystack = btn.Name:lower()
            if player then
                haystack = haystack .. " " .. player.DisplayName:lower()
            end
            btn.Visible = (query == "" or haystack:find(query, 1, true) ~= nil)
        end
    end
end

-- Function to create emote button
local function createEmoteButton(emoteData, parentFrame)
    local emoteButton = Instance.new("TextButton")
    emoteButton.Name = emoteData.name
    emoteButton.Size = UDim2.new(1, -4, 0, 45)
    emoteButton.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
    emoteButton.BorderSizePixel = 0
    emoteButton.Text = ""
    emoteButton.AutoButtonColor = false
    emoteButton.Parent = parentFrame

    local emoteCorner = Instance.new("UICorner")
    emoteCorner.CornerRadius = UDim.new(0, 10)
    emoteCorner.Parent = emoteButton

    local emoteIcon = Instance.new("TextLabel")
    emoteIcon.Name = "EmoteIcon"
    emoteIcon.Size = UDim2.new(0, 30, 1, 0)
    emoteIcon.Position = UDim2.new(0, 10, 0, 0)
    emoteIcon.BackgroundTransparency = 1
    emoteIcon.Text = "🎭"
    emoteIcon.TextSize = 20
    emoteIcon.Parent = emoteButton

    local emoteNameLabel = Instance.new("TextLabel")
    emoteNameLabel.Size = UDim2.new(1, -90, 0, 25)
    emoteNameLabel.Position = UDim2.new(0, 45, 0, 3)
    emoteNameLabel.BackgroundTransparency = 1
    emoteNameLabel.Text = emoteData.name
    emoteNameLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
    emoteNameLabel.Font = Enum.Font.GothamBold
    emoteNameLabel.TextSize = 12
    emoteNameLabel.TextXAlignment = Enum.TextXAlignment.Left
    emoteNameLabel.TextTruncate = Enum.TextTruncate.AtEnd
    emoteNameLabel.Parent = emoteButton

    local emoteInfo = Instance.new("TextLabel")
    emoteInfo.Size = UDim2.new(1, -90, 0, 15)
    emoteInfo.Position = UDim2.new(0, 45, 0, 25)
    emoteInfo.BackgroundTransparency = 1
    emoteInfo.Text = emoteData.type == "equipped" and "Slot " .. emoteData.slot or "Inventory"
    emoteInfo.TextColor3 = Color3.fromRGB(150, 150, 150)
    emoteInfo.Font = Enum.Font.Gotham
    emoteInfo.TextSize = 10
    emoteInfo.TextXAlignment = Enum.TextXAlignment.Left
    emoteInfo.Parent = emoteButton

    local activeIndicator = Instance.new("Frame")
    activeIndicator.Name = "ActiveIndicator"
    activeIndicator.Size = UDim2.new(0, 8, 0, 8)
    activeIndicator.Position = UDim2.new(1, -15, 0.5, -4)
    activeIndicator.BackgroundColor3 = Color3.fromRGB(46, 204, 113)
    activeIndicator.BorderSizePixel = 0
    activeIndicator.Visible = false
    activeIndicator.Parent = emoteButton

    local activeCorner = Instance.new("UICorner")
    activeCorner.CornerRadius = UDim.new(1, 0)
    activeCorner.Parent = activeIndicator

    local favButton = Instance.new("TextButton")
    favButton.Name = "FavButton"
    favButton.Size = UDim2.new(0, 24, 0, 24)
    favButton.Position = UDim2.new(1, -36, 0.5, -12)
    favButton.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
    favButton.BorderSizePixel = 0
    favButton.Text = table.find(favoriteEmotes, emoteData.name) and "⭐" or "☆"
    favButton.TextColor3 = Color3.fromRGB(255, 255, 255)
    favButton.Font = Enum.Font.GothamBold
    favButton.TextSize = 12
    favButton.ZIndex = 3
    favButton.Parent = emoteButton

    local favCorner = Instance.new("UICorner")
    favCorner.CornerRadius = UDim.new(0, 4)
    favCorner.Parent = favButton

    favButton.MouseButton1Click:Connect(function()
        local index = table.find(favoriteEmotes, emoteData.name)
        if index then
            table.remove(favoriteEmotes, index)
            favButton.Text = "☆"
            showNotification("Removed from favorites: " .. emoteData.name, Color3.fromRGB(150, 150, 150))
        else
            table.insert(favoriteEmotes, emoteData.name)
            favButton.Text = "⭐"
            showNotification("Added to favorites: " .. emoteData.name, Color3.fromRGB(241, 196, 15))
        end
        populateFavoritesList()
    end)

    emoteButton.MouseEnter:Connect(function()
        if currentEmoteName ~= emoteData.name then
            TweenService:Create(emoteButton, TweenInfo.new(0.2), {
                BackgroundColor3 = Color3.fromRGB(45, 45, 45)
            }):Play()
        end
    end)

    emoteButton.MouseLeave:Connect(function()
        if currentEmoteName ~= emoteData.name then
            TweenService:Create(emoteButton, TweenInfo.new(0.2), {
                BackgroundColor3 = Color3.fromRGB(30, 30, 30)
            }):Play()
        end
    end)

    emoteButton.MouseButton1Click:Connect(function()
        if currentEmoteName == emoteData.name then
            stopCurrentEmote()
            emoteButton.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
            activeIndicator.Visible = false
        else
            for _, frame in ipairs({emotesListFrame, favsListFrame}) do
                for _, btn in ipairs(frame:GetChildren()) do
                    if btn:IsA("TextButton") then
                        btn.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
                        local ind = btn:FindFirstChild("ActiveIndicator")
                        if ind then ind.Visible = false end
                    end
                end
            end

            local success = executeEmote(emoteData.name, emoteData)
            if success then
                for _, frame in ipairs({emotesListFrame, favsListFrame}) do
                    for _, btn in ipairs(frame:GetChildren()) do
                        if btn:IsA("TextButton") and btn.Name == emoteData.name then
                            btn.BackgroundColor3 = Color3.fromRGB(52, 152, 219)
                            local ind = btn:FindFirstChild("ActiveIndicator")
                            if ind then ind.Visible = true end
                        end
                    end
                end
            end
        end
    end)

    return emoteButton
end

-- Populate emote list
function populateEmoteList()
    for _, child in ipairs(emotesListFrame:GetChildren()) do
        if child:IsA("TextButton") or child:IsA("TextLabel") then
            child:Destroy()
        end
    end

    inventoryEmotes = getInventoryEmotes()

    if #inventoryEmotes == 0 then
        local noEmotesLabel = Instance.new("TextLabel")
        noEmotesLabel.Size = UDim2.new(1, 0, 0, 60)
        noEmotesLabel.BackgroundTransparency = 1
        noEmotesLabel.Text = "No emotes found in inventory.\nClick 'Load Emotes' to refresh."
        noEmotesLabel.TextColor3 = Color3.fromRGB(150, 150, 150)
        noEmotesLabel.Font = Enum.Font.Gotham
        noEmotesLabel.TextSize = 12
        noEmotesLabel.TextWrapped = true
        noEmotesLabel.Parent = emotesListFrame
    else
        for _, emoteData in ipairs(inventoryEmotes) do
            createEmoteButton(emoteData, emotesListFrame)
        end
    end
end

-- Populate favorites list
function populateFavoritesList()
    for _, child in ipairs(favsListFrame:GetChildren()) do
        if child:IsA("TextButton") or child:IsA("TextLabel") then
            child:Destroy()
        end
    end

    local favCount = 0
    for _, emoteData in ipairs(inventoryEmotes) do
        if table.find(favoriteEmotes, emoteData.name) then
            createEmoteButton(emoteData, favsListFrame)
            favCount = favCount + 1
        end
    end

    if favCount == 0 then
        local noFavsLabel = Instance.new("TextLabel")
        noFavsLabel.Size = UDim2.new(1, 0, 0, 60)
        noFavsLabel.BackgroundTransparency = 1
        noFavsLabel.Text = "No favorite emotes yet.\nClick ☆ to add emotes to favorites."
        noFavsLabel.TextColor3 = Color3.fromRGB(150, 150, 150)
        noFavsLabel.Font = Enum.Font.Gotham
        noFavsLabel.TextSize = 12
        noFavsLabel.TextWrapped = true
        noFavsLabel.Parent = favsListFrame
    end
end

-- Tab switching
local function showTab(tab)
    playerListFrame.Visible = (tab == "players")
    emotesListFrame.Visible = (tab == "emotes")
    favsListFrame.Visible = (tab == "favs")
    searchBox.Visible = (tab == "players")

    playerTabBtn.BackgroundColor3 = (tab == "players") and Color3.fromRGB(52, 152, 219) or Color3.fromRGB(35, 35, 35)
    emotesTabBtn.BackgroundColor3 = (tab == "emotes") and Color3.fromRGB(52, 152, 219) or Color3.fromRGB(35, 35, 35)
    favsTabBtn.BackgroundColor3 = (tab == "favs") and Color3.fromRGB(52, 152, 219) or Color3.fromRGB(35, 35, 35)

    if tab == "favs" then
        populateFavoritesList()
    end
end

playerTabBtn.MouseButton1Click:Connect(function() showTab("players") end)
emotesTabBtn.MouseButton1Click:Connect(function() showTab("emotes") end)
favsTabBtn.MouseButton1Click:Connect(function() showTab("favs") end)

-- Update player list
local function updatePlayerList()
    for _, child in ipairs(playerListFrame:GetChildren()) do
        if child:IsA("TextButton") then
            child:Destroy()
        end
    end

    local players = Players:GetPlayers()

    for _, player in ipairs(players) do
        if player ~= LocalPlayer then
            createPlayerButton(player)
        end
    end

    playerCountText.Text = "Players Online: " .. #players

    if trackingPlayer and not Players:FindFirstChild(trackingPlayer.Name) then
        stopTracking()
        showNotification("Tracked player left the game", Color3.fromRGB(231, 76, 60))
    end

    if trackingPlayer then
        updateButtonVisuals()
    end

    applySearchFilter()
end

-- Search box behaviour
searchBox:GetPropertyChangedSignal("Text"):Connect(function()
    searchQuery = searchBox.Text
    applySearchFilter()
end)

-- Event handlers
Players.PlayerAdded:Connect(function(player)
    if player ~= LocalPlayer then
        updatePlayerList()
        showNotification(player.DisplayName .. " joined the game", Color3.fromRGB(46, 204, 113))
    end
end)

Players.PlayerRemoving:Connect(function(player)
    if trackingPlayer == player then
        stopTracking()
    end
    task.defer(updatePlayerList)
end)

stopButton.MouseButton1Click:Connect(function()
    stopTracking()
    for _, btn in ipairs(playerListFrame:GetChildren()) do
        if btn:IsA("TextButton") then
            local st = btn:FindFirstChild("StatusText")
            if st then st.Text = "Click to track" end
        end
    end
end)

stopEmoteButton.MouseButton1Click:Connect(function()
    stopCurrentEmote()
    for _, frame in ipairs({emotesListFrame, favsListFrame}) do
        for _, btn in ipairs(frame:GetChildren()) do
            if btn:IsA("TextButton") then
                btn.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
                local ind = btn:FindFirstChild("ActiveIndicator")
                if ind then ind.Visible = false end
            end
        end
    end
end)

refreshButton.MouseButton1Click:Connect(function()
    updatePlayerList()
    showNotification("Player list refreshed", Color3.fromRGB(52, 152, 219))
end)

refreshEmotesButton.MouseButton1Click:Connect(function()
    populateEmoteList()
    populateFavoritesList()
    showNotification("Emotes reloaded from inventory", Color3.fromRGB(46, 204, 113))
end)

autoMimicToggle.MouseButton1Click:Connect(toggleAutoMimic)
possessionToggle.MouseButton1Click:Connect(togglePossessionMode)

closeButton.MouseButton1Click:Connect(function()
    stopTracking()
    stopCurrentEmote()
    screenGui:Destroy()
end)

-- Minimize button
local minimized = false
local currentTab = "players"
minimizeButton.MouseButton1Click:Connect(function()
    minimized = not minimized

    if minimized then
        playerListFrame.Visible = false
        emotesListFrame.Visible = false
        favsListFrame.Visible = false
        controlPanel.Visible = false
        buttonFrame.Visible = false
        notificationFrame.Visible = false
        tabFrame.Visible = false
        searchBox.Visible = false
        mainFrame.Size = UDim2.new(0, 340, 0, 45)
        minimizeButton.Text = "+"
    else
        controlPanel.Visible = true
        buttonFrame.Visible = true
        tabFrame.Visible = true
        mainFrame.Size = UDim2.new(0, 340, 0, 520)
        minimizeButton.Text = "−"
        showTab(currentTab)
    end
end)

-- Track which tab is active so restore-from-minimize shows the right one
playerTabBtn.MouseButton1Click:Connect(function() currentTab = "players" end)
emotesTabBtn.MouseButton1Click:Connect(function() currentTab = "emotes" end)
favsTabBtn.MouseButton1Click:Connect(function() currentTab = "favs" end)

-- Initial setup
updatePlayerList()
populateEmoteList()
populateFavoritesList()
showTab("players")

-- Handle character respawn
LocalPlayer.CharacterAdded:Connect(function(character)
    if isPlayingEmote and currentEmoteName then
        task.wait(0.5)
        pcall(function()
            local humanoid = character:FindFirstChildOfClass("Humanoid")
            if humanoid then
                humanoid:PlayEmote(currentEmoteName)
            end
        end)
        showNotification("Emote resumed: " .. currentEmoteName, Color3.fromRGB(52, 152, 219))
    end

    if trackingPlayer and autoMimic then
        task.wait(1)
        if trackingPlayer and trackingPlayer.Character then
            showNotification("Respawned - continuing mimic", Color3.fromRGB(241, 196, 15))
        end
    end
end)

-- Keyboard shortcuts (ignored while typing in the search box)
UserInputService.InputBegan:Connect(function(input, gameProcessed)
    if gameProcessed then return end

    if input.KeyCode == Enum.KeyCode.F then
        stopTracking()
    elseif input.KeyCode == Enum.KeyCode.G then
        toggleAutoMimic()
    elseif input.KeyCode == Enum.KeyCode.H then
        togglePossessionMode()
    elseif input.KeyCode == Enum.KeyCode.E then
        stopCurrentEmote()
        for _, frame in ipairs({emotesListFrame, favsListFrame}) do
            for _, btn in ipairs(frame:GetChildren()) do
                if btn:IsA("TextButton") then
                    btn.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
                    local ind = btn:FindFirstChild("ActiveIndicator")
                    if ind then ind.Visible = false end
                end
            end
        end
    elseif input.KeyCode.Value >= Enum.KeyCode.One.Value and input.KeyCode.Value <= Enum.KeyCode.Nine.Value then
        local emoteIndex = input.KeyCode.Value - Enum.KeyCode.One.Value + 1
        if emoteIndex <= #inventoryEmotes then
            local emoteData = inventoryEmotes[emoteIndex]
            for _, frame in ipairs({emotesListFrame, favsListFrame}) do
                for _, btn in ipairs(frame:GetChildren()) do
                    if btn:IsA("TextButton") then
                        btn.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
                        local ind = btn:FindFirstChild("ActiveIndicator")
                        if ind then ind.Visible = false end
                    end
                end
            end

            local success = executeEmote(emoteData.name, emoteData)
            if success then
                for _, frame in ipairs({emotesListFrame, favsListFrame}) do
                    for _, btn in ipairs(frame:GetChildren()) do
                        if btn:IsA("TextButton") and btn.Name == emoteData.name then
                            btn.BackgroundColor3 = Color3.fromRGB(52, 152, 219)
                            local ind = btn:FindFirstChild("ActiveIndicator")
                            if ind then ind.Visible = true end
                        end
                    end
                end
            end
        end
    end
end)

-- Clean up
script.Destroying:Connect(function()
    stopTracking()
    stopCurrentEmote()
    if screenGui then
        screenGui:Destroy()
    end
end)
