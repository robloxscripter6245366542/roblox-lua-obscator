-- Aimbot Mobile (fixed)
-- Cleaned up from a deobfuscated build. Fixes:
--   * FOV circle is built from Frame segments instead of Drawing.new (and no
--     UIStroke), so it shows on mobile executors that lack either.
--     It is visible as soon as the script runs (toggle with "Show FOV").
--   * Ring is centred in a ScreenGui with IgnoreGuiInset, so it lines up with
--     the camera centre the aimbot actually measures from.
--   * Toggle buttons (Team/Kill/Wall Check) no longer error when clicked
--     (old code concatenated a string with a boolean).
--   * Target-part dropdown was parented to script.Parent (nil in executors) and
--     was never used by the aimbot; it now lives in the panel and is used.
--   * Part names fixed for R6 and R15 rigs ("Left Leg"/"LeftLowerLeg", etc.).
--   * FOV slider: knob starts at the real value, drag stops when the finger /
--     mouse is released anywhere, and only pointer movement moves it.
--   * Wall check: ray reaches the full distance and uses the non-deprecated
--     RaycastFilterType.Exclude.
--   * Team check no longer treats everyone as a teammate in games with no teams.
--   * Camera is re-read every frame (CurrentCamera can be replaced).
--   * Panel drag works with touch (Draggable is deprecated / mouse only).
--   * Closing the GUI disconnects every connection; re-running the script
--     replaces the old GUI instead of stacking a second one.
-- Tracking upgrades for shooters:
--   * Sticky Lock: stays on the current target instead of flicking between
--     players when two are close to the crosshair.
--   * Prediction: leads moving targets by their velocity (slider).
--   * Smoothness slider: 0 = instant snap, higher = smoother camera.
--   * "Auto" target part: aims at whichever of head / torso / root is visible
--     and closest to the crosshair.
--   * Wall check sees through glass, invisible and non-collidable parts.
--   * Optional NPC targeting (bots / dummies with a Humanoid).
--   * Controls live in a scrollable list so the panel fits phone screens.
--   * ESP: red outline around every other player, seen through walls
--     (toggle with the "ESP" button).
--   * Dead players are always skipped (even if the game keeps the body with
--     health left); Kill Check also skips downed / knocked / ragdolled and
--     spawn-protected players.
--   * Config: every option is saved to AimbotMobile_Config.json (executor
--     workspace folder) and restored the next time the script runs.

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")

local LocalPlayer = Players.LocalPlayer
local RENDER_NAME = "AimbotRender"

local connections = {}
local function track(conn)
    table.insert(connections, conn)
    return conn
end

-- GUI parent: prefer the executor's hidden UI container, then CoreGui, then PlayerGui.
local function getGuiParent()
    if typeof(gethui) == "function" then
        local ok, hui = pcall(gethui)
        if ok and hui then
            return hui
        end
    end
    local ok, coreGui = pcall(function()
        return game:GetService("CoreGui")
    end)
    if ok and coreGui then
        local canWrite = pcall(function()
            local probe = Instance.new("Folder")
            probe.Parent = coreGui
            probe:Destroy()
        end)
        if canWrite then
            return coreGui
        end
    end
    return LocalPlayer:WaitForChild("PlayerGui")
end

local guiParent = getGuiParent()
for _, oldName in ipairs({ "AimbotGUI", "AimbotFOV", "AimbotESP" }) do
    local old = guiParent:FindFirstChild(oldName)
    if old then
        old:Destroy()
    end
end
pcall(function()
    RunService:UnbindFromRenderStep(RENDER_NAME)
end)

-- Settings
local aimbotEnabled = false
local showFov = true -- ring is visible as soon as the script runs
local fovRadius = 80
local FOV_MAX = 300
local FOV_MIN = 10
local teamCheck = false
local killCheck = true -- skip dead players by default
local wallCheck = false
local stickyLock = true -- stay on one target instead of flicking between people
local targetNpcs = false
local espEnabled = true -- red outline on every other player
local smoothness = 0 -- 0 = instant, up to 90 = very smooth
local predictionCs = 10 -- lead moving targets by this many hundredths of a second
local targetPartName = "Head"

--------------------------------------------------------------------------
-- Config: options are saved to a file in the executor's workspace folder
-- and loaded the next time the script runs.
--------------------------------------------------------------------------
local HttpService = game:GetService("HttpService")
local CONFIG_FILE = "AimbotMobile_Config.json"
local canSave = typeof(writefile) == "function" and typeof(readfile) == "function"
    and typeof(isfile) == "function"

local VALID_PARTS = {
    Auto = true, Head = true, Torso = true, HumanoidRootPart = true,
    ["Left Leg"] = true, ["Right Leg"] = true,
}

local function loadConfig()
    if not canSave then
        return
    end
    local ok, data = pcall(function()
        if not isfile(CONFIG_FILE) then
            return nil
        end
        return HttpService:JSONDecode(readfile(CONFIG_FILE))
    end)
    if not ok or type(data) ~= "table" then
        return
    end
    local function bool(key, current)
        if type(data[key]) == "boolean" then
            return data[key]
        end
        return current
    end
    local function num(key, current, lo, hi)
        if type(data[key]) == "number" then
            return math.clamp(math.floor(data[key]), lo, hi)
        end
        return current
    end
    aimbotEnabled = bool("aimbotEnabled", aimbotEnabled)
    showFov = bool("showFov", showFov)
    teamCheck = bool("teamCheck", teamCheck)
    killCheck = bool("killCheck", killCheck)
    wallCheck = bool("wallCheck", wallCheck)
    stickyLock = bool("stickyLock", stickyLock)
    targetNpcs = bool("targetNpcs", targetNpcs)
    espEnabled = bool("espEnabled", espEnabled)
    fovRadius = num("fovRadius", fovRadius, FOV_MIN, FOV_MAX)
    smoothness = num("smoothness", smoothness, 0, 90)
    predictionCs = num("predictionCs", predictionCs, 0, 30)
    if type(data.targetPartName) == "string" and VALID_PARTS[data.targetPartName] then
        targetPartName = data.targetPartName
    end
end

local savePending = false
local function writeConfig()
    savePending = false
    if not canSave then
        return
    end
    pcall(function()
        writefile(CONFIG_FILE, HttpService:JSONEncode({
            aimbotEnabled = aimbotEnabled,
            showFov = showFov,
            fovRadius = fovRadius,
            teamCheck = teamCheck,
            killCheck = killCheck,
            wallCheck = wallCheck,
            stickyLock = stickyLock,
            targetNpcs = targetNpcs,
            espEnabled = espEnabled,
            smoothness = smoothness,
            predictionCs = predictionCs,
            targetPartName = targetPartName,
        }))
    end)
end

-- Batches rapid changes (e.g. dragging a slider) into one write.
local function saveConfig()
    if savePending then
        return
    end
    savePending = true
    task.delay(0.5, writeConfig)
end

loadConfig()

local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "AimbotGUI"
ScreenGui.ResetOnSpawn = false
ScreenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
ScreenGui.DisplayOrder = 999
ScreenGui.Parent = guiParent

--------------------------------------------------------------------------
-- FOV circle (GUI-based so it works on mobile)
--------------------------------------------------------------------------
-- Own ScreenGui with IgnoreGuiInset so (0.5, 0.5) is the true viewport
-- centre, matching camera.ViewportSize / 2 used by the targeting code.
local FovGui = Instance.new("ScreenGui")
FovGui.Name = "AimbotFOV"
FovGui.ResetOnSpawn = false
FovGui.IgnoreGuiInset = true
FovGui.DisplayOrder = 998
FovGui.Parent = guiParent
ScreenGui.Destroying:Connect(function()
    FovGui:Destroy()
end)

--------------------------------------------------------------------------
-- ESP: red outline around every other player (Highlight, works on mobile)
--------------------------------------------------------------------------
local ESP_COLOR = Color3.fromRGB(255, 0, 0)

local EspFolder = Instance.new("Folder")
EspFolder.Name = "AimbotESP"
EspFolder.Parent = guiParent
ScreenGui.Destroying:Connect(function()
    EspFolder:Destroy()
end)

local espHighlights = {} -- [Player] = Highlight

local function removeEsp(player)
    local hl = espHighlights[player]
    if hl then
        hl:Destroy()
        espHighlights[player] = nil
    end
end

local function clearEsp()
    for player in pairs(espHighlights) do
        removeEsp(player)
    end
end

-- Called every frame: adds outlines for new players / respawned characters
-- and drops them for players who left.
local function updateEsp()
    if not espEnabled then
        return
    end
    for player, hl in pairs(espHighlights) do
        if player.Parent ~= Players then
            removeEsp(player)
        elseif hl.Adornee ~= player.Character then
            hl.Adornee = player.Character
        end
    end
    for _, player in ipairs(Players:GetPlayers()) do
        if player ~= LocalPlayer and not espHighlights[player] and player.Character then
            local hl = Instance.new("Highlight")
            hl.Name = player.Name
            hl.FillTransparency = 1 -- outline only
            hl.OutlineColor = ESP_COLOR
            hl.OutlineTransparency = 0
            hl.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop -- visible through walls
            hl.Adornee = player.Character
            hl.Parent = EspFolder
            espHighlights[player] = hl
        end
    end
end

-- The ring is built purely from small rotated Frames (no Drawing API, no
-- UIStroke), so it renders on every mobile executor.
local FOV_SEGMENTS = 72
local FOV_THICKNESS = 2
local FOV_COLOR = Color3.fromRGB(255, 255, 255)

local FovCircle = Instance.new("Frame")
FovCircle.Name = "FOVCircle"
FovCircle.Size = UDim2.fromScale(1, 1)
FovCircle.BackgroundTransparency = 1
FovCircle.BorderSizePixel = 0
FovCircle.Active = false
FovCircle.Visible = false
FovCircle.Parent = FovGui

local fovSegments = {}
for i = 1, FOV_SEGMENTS do
    local seg = Instance.new("Frame")
    seg.Name = "Seg" .. i
    seg.AnchorPoint = Vector2.new(0.5, 0.5)
    seg.BackgroundColor3 = FOV_COLOR
    seg.BackgroundTransparency = 0
    seg.BorderSizePixel = 0
    seg.Active = false
    seg.Parent = FovCircle
    fovSegments[i] = seg
end

local laidOutRadius
local function layoutFovCircle(radius)
    if radius == laidOutRadius then
        return
    end
    laidOutRadius = radius
    -- Slightly longer than the arc so neighbouring segments overlap (no gaps).
    local segLength = (2 * math.pi * radius) / FOV_SEGMENTS + 1
    for i, seg in ipairs(fovSegments) do
        local angle = (i - 1) / FOV_SEGMENTS * 2 * math.pi
        seg.Size = UDim2.fromOffset(segLength, FOV_THICKNESS)
        seg.Position = UDim2.new(0.5, math.cos(angle) * radius, 0.5, math.sin(angle) * radius)
        seg.Rotation = math.deg(angle) + 90
    end
end

local function updateFovCircle()
    layoutFovCircle(fovRadius)
    FovCircle.Visible = showFov
end
updateFovCircle()

--------------------------------------------------------------------------
-- Toggle button + panel
--------------------------------------------------------------------------
local ToggleButton = Instance.new("ImageButton")
ToggleButton.Size = UDim2.new(0, 50, 0, 50)
ToggleButton.Position = UDim2.new(0, 10, 0, 10)
ToggleButton.BackgroundColor3 = Color3.fromRGB(20, 20, 20)
ToggleButton.Image = "rbxassetid://132533655213092"
ToggleButton.ImageColor3 = Color3.fromRGB(255, 255, 255)
ToggleButton.ScaleType = Enum.ScaleType.Fit
ToggleButton.ZIndex = 10
ToggleButton.Parent = ScreenGui
Instance.new("UICorner", ToggleButton).CornerRadius = UDim.new(1, 0)

local hoverInfo = TweenInfo.new(0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
ToggleButton.MouseEnter:Connect(function()
    TweenService:Create(ToggleButton, hoverInfo, { Size = UDim2.new(0, 55, 0, 55) }):Play()
end)
ToggleButton.MouseLeave:Connect(function()
    TweenService:Create(ToggleButton, hoverInfo, { Size = UDim2.new(0, 50, 0, 50) }):Play()
end)

local Panel = Instance.new("Frame")
Panel.Size = UDim2.new(0, 180, 0, 300)
Panel.Position = UDim2.new(0, 70, 0, 10)
Panel.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
Panel.Active = true
Panel.Parent = ScreenGui
Instance.new("UICorner", Panel).CornerRadius = UDim.new(0, 10)

local panelVisible = true
ToggleButton.MouseButton1Click:Connect(function()
    panelVisible = not panelVisible
    Panel.Visible = panelVisible
end)

local Title = Instance.new("TextLabel")
Title.Size = UDim2.new(1, 0, 0, 30)
Title.Text = "Aimbot Mobile"
Title.BackgroundTransparency = 1
Title.Font = Enum.Font.GothamBold
Title.TextColor3 = Color3.fromRGB(255, 255, 255)
Title.TextScaled = true
Title.Active = true -- drag handle
Title.Parent = Panel

-- Touch + mouse drag via the title bar
do
    local dragInput, dragStart, startPos
    Title.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1
            or input.UserInputType == Enum.UserInputType.Touch then
            dragInput = input
            dragStart = input.Position
            startPos = Panel.Position
        end
    end)
    track(UserInputService.InputChanged:Connect(function(input)
        if not dragStart then
            return
        end
        local isMove = input.UserInputType == Enum.UserInputType.MouseMovement
            or (input.UserInputType == Enum.UserInputType.Touch and input == dragInput)
        if isMove then
            local delta = input.Position - dragStart
            Panel.Position = UDim2.new(
                startPos.X.Scale, startPos.X.Offset + delta.X,
                startPos.Y.Scale, startPos.Y.Offset + delta.Y
            )
        end
    end))
    track(UserInputService.InputEnded:Connect(function(input)
        if input == dragInput or input.UserInputType == Enum.UserInputType.MouseButton1 then
            dragInput, dragStart = nil, nil
        end
    end))
end

--------------------------------------------------------------------------
-- Notifications
--------------------------------------------------------------------------
local function notify(text, soundId, onDone)
    local Toast = Instance.new("Frame")
    Toast.Size = UDim2.new(0, 310, 0, 60)
    Toast.AnchorPoint = Vector2.new(1, 1)
    Toast.Position = UDim2.new(1, -10, 1, 100)
    Toast.BackgroundColor3 = Color3.fromRGB(25, 25, 25)
    Toast.BackgroundTransparency = 0.1
    Toast.BorderSizePixel = 0
    Toast.ZIndex = 30
    Toast.Parent = ScreenGui
    Instance.new("UICorner", Toast).CornerRadius = UDim.new(0, 10)

    local Icon = Instance.new("ImageLabel")
    Icon.Size = UDim2.new(0, 40, 0, 40)
    Icon.Position = UDim2.new(0, 5, 0.5, -20)
    Icon.BackgroundTransparency = 1
    Icon.Image = "rbxassetid://77474537431792"
    Icon.ZIndex = 31
    Icon.Parent = Toast

    local Label = Instance.new("TextLabel")
    Label.Size = UDim2.new(1, -60, 1, 0)
    Label.Position = UDim2.new(0, 55, 0, 0)
    Label.BackgroundTransparency = 1
    Label.Text = text
    Label.TextColor3 = Color3.fromRGB(255, 255, 255)
    Label.TextSize = 18
    Label.Font = Enum.Font.GothamBold
    Label.TextXAlignment = Enum.TextXAlignment.Left
    Label.TextYAlignment = Enum.TextYAlignment.Center
    Label.TextWrapped = true
    Label.ZIndex = 31
    Label.Parent = Toast

    local Sound = Instance.new("Sound")
    Sound.SoundId = soundId
    Sound.Volume = 1
    Sound.Parent = ScreenGui
    Sound:Play()

    TweenService:Create(Toast, TweenInfo.new(0.5, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), {
        Position = UDim2.new(1, -10, 1, -10),
    }):Play()
    task.delay(3, function()
        local out = TweenService:Create(Toast, TweenInfo.new(0.5, Enum.EasingStyle.Quint, Enum.EasingDirection.In), {
            Position = UDim2.new(1, -10, 1, 100),
        })
        out:Play()
        out.Completed:Connect(function()
            Toast:Destroy()
            if onDone then
                onDone()
            end
        end)
    end)
end

--------------------------------------------------------------------------
-- Close button + confirmation
--------------------------------------------------------------------------
local CloseButton = Instance.new("TextButton")
CloseButton.Size = UDim2.new(0, 30, 0, 30)
CloseButton.Position = UDim2.new(1, -35, 1, -35)
CloseButton.BackgroundColor3 = Color3.fromRGB(255, 50, 50)
CloseButton.Text = "X"
CloseButton.TextColor3 = Color3.new(1, 1, 1)
CloseButton.Font = Enum.Font.GothamBold
CloseButton.TextScaled = true
CloseButton.Parent = Panel
Instance.new("UICorner", CloseButton).CornerRadius = UDim.new(1, 0)

local function shutdown()
    aimbotEnabled = false
    showFov = false
    FovCircle.Visible = false
    espEnabled = false
    clearEsp()
    pcall(function()
        RunService:UnbindFromRenderStep(RENDER_NAME)
    end)
    for _, conn in ipairs(connections) do
        conn:Disconnect()
    end
    table.clear(connections)
end

CloseButton.MouseButton1Click:Connect(function()
    if ScreenGui:FindFirstChild("ConfirmOverlay") then
        return
    end

    local Overlay = Instance.new("Frame")
    Overlay.Name = "ConfirmOverlay"
    Overlay.Size = UDim2.new(1, 0, 1, 0)
    Overlay.BackgroundColor3 = Color3.new(0, 0, 0)
    Overlay.BackgroundTransparency = 1
    Overlay.ZIndex = 20
    Overlay.Parent = ScreenGui

    local Dialog = Instance.new("Frame")
    Dialog.Size = UDim2.new(0, 300, 0, 140)
    Dialog.Position = UDim2.new(0.5, -150, 0.5, -70)
    Dialog.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
    Dialog.ZIndex = 21
    Dialog.Parent = Overlay
    Instance.new("UICorner", Dialog).CornerRadius = UDim.new(0, 10)

    local DTitle = Instance.new("TextLabel")
    DTitle.Size = UDim2.new(1, 0, 0, 30)
    DTitle.Position = UDim2.new(0, 0, 0, 10)
    DTitle.Text = "Fechar GUI"
    DTitle.Font = Enum.Font.GothamBold
    DTitle.TextColor3 = Color3.new(1, 1, 1)
    DTitle.TextScaled = true
    DTitle.BackgroundTransparency = 1
    DTitle.ZIndex = 21
    DTitle.Parent = Dialog

    local DText = Instance.new("TextLabel")
    DText.Size = UDim2.new(1, -20, 0, 40)
    DText.Position = UDim2.new(0, 10, 0, 45)
    DText.Text = "Você quer realmente fechar a interface?"
    DText.TextWrapped = true
    DText.Font = Enum.Font.Gotham
    DText.TextColor3 = Color3.new(1, 1, 1)
    DText.TextScaled = true
    DText.BackgroundTransparency = 1
    DText.ZIndex = 21
    DText.Parent = Dialog

    local Yes = Instance.new("TextButton")
    Yes.Size = UDim2.new(0.45, -5, 0, 30)
    Yes.Position = UDim2.new(0.05, 0, 1, -40)
    Yes.BackgroundColor3 = Color3.fromRGB(255, 50, 50)
    Yes.Text = "SIM"
    Yes.Font = Enum.Font.GothamBold
    Yes.TextColor3 = Color3.new(1, 1, 1)
    Yes.TextScaled = true
    Yes.ZIndex = 21
    Yes.Parent = Dialog
    Instance.new("UICorner", Yes).CornerRadius = UDim.new(0, 6)

    local No = Instance.new("TextButton")
    No.Size = UDim2.new(0.45, -5, 0, 30)
    No.Position = UDim2.new(0.5, 5, 1, -40)
    No.BackgroundColor3 = Color3.fromRGB(60, 150, 255)
    No.Text = "NÃO"
    No.Font = Enum.Font.GothamBold
    No.TextColor3 = Color3.new(1, 1, 1)
    No.TextScaled = true
    No.ZIndex = 21
    No.Parent = Dialog
    Instance.new("UICorner", No).CornerRadius = UDim.new(0, 6)

    Yes.MouseButton1Click:Connect(function()
        shutdown()
        Overlay:Destroy()
        Panel.Visible = false
        ToggleButton.Visible = false
        notify("Até a próxima!\nBy ZecadaDiv", "rbxassetid://8284260932", function()
            ScreenGui:Destroy()
        end)
    end)
    No.MouseButton1Click:Connect(function()
        Overlay:Destroy()
    end)
end)

--------------------------------------------------------------------------
-- Scrollable controls area (fits small phone screens)
--------------------------------------------------------------------------
local Content = Instance.new("ScrollingFrame")
Content.Size = UDim2.new(1, 0, 1, -75)
Content.Position = UDim2.new(0, 0, 0, 35)
Content.BackgroundTransparency = 1
Content.BorderSizePixel = 0
Content.ScrollBarThickness = 4
Content.ScrollingDirection = Enum.ScrollingDirection.Y
Content.Parent = Panel

local CONTENT_HEIGHT = 0
local function reserve(y, h)
    CONTENT_HEIGHT = math.max(CONTENT_HEIGHT, y + h)
    Content.CanvasSize = UDim2.new(0, 0, 0, CONTENT_HEIGHT + 10)
end

--------------------------------------------------------------------------
-- Aimbot toggle
--------------------------------------------------------------------------
local AimbotButton = Instance.new("TextButton")
AimbotButton.Size = UDim2.new(1, -20, 0, 30)
AimbotButton.Position = UDim2.new(0, 10, 0, 0)
AimbotButton.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
AimbotButton.TextColor3 = Color3.fromRGB(255, 255, 255)
AimbotButton.Text = "Ativar Aimbot: " .. (aimbotEnabled and "ON" or "OFF")
AimbotButton.Font = Enum.Font.Gotham
AimbotButton.TextScaled = true
AimbotButton.Parent = Content
Instance.new("UICorner", AimbotButton).CornerRadius = UDim.new(0, 6)
reserve(0, 30)

AimbotButton.MouseButton1Click:Connect(function()
    aimbotEnabled = not aimbotEnabled
    AimbotButton.Text = "Ativar Aimbot: " .. (aimbotEnabled and "ON" or "OFF")
    updateFovCircle()
    saveConfig()
end)

--------------------------------------------------------------------------
-- Sliders
--------------------------------------------------------------------------
local function makeSlider(name, y, minValue, maxValue, initial, onChanged)
    local Label = Instance.new("TextLabel")
    Label.Size = UDim2.new(1, -20, 0, 18)
    Label.Position = UDim2.new(0, 10, 0, y)
    Label.BackgroundTransparency = 1
    Label.TextColor3 = Color3.fromRGB(255, 255, 255)
    Label.Text = name .. ": " .. initial
    Label.Font = Enum.Font.Gotham
    Label.TextScaled = true
    Label.Parent = Content

    local Bar = Instance.new("TextButton")
    Bar.Size = UDim2.new(1, -20, 0, 14)
    Bar.Position = UDim2.new(0, 10, 0, y + 20)
    Bar.BackgroundColor3 = Color3.fromRGB(70, 70, 70)
    Bar.Text = ""
    Bar.AutoButtonColor = false
    Bar.Parent = Content
    Instance.new("UICorner", Bar).CornerRadius = UDim.new(1, 0)

    local Knob = Instance.new("Frame")
    Knob.Size = UDim2.new(0, 12, 1, 0)
    Knob.AnchorPoint = Vector2.new(0.5, 0)
    Knob.Position = UDim2.new((initial - minValue) / (maxValue - minValue), 0, 0, 0)
    Knob.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
    Knob.Parent = Bar
    Instance.new("UICorner", Knob).CornerRadius = UDim.new(1, 0)

    reserve(y, 34)

    local dragInput
    local function setFromX(x)
        local width = Bar.AbsoluteSize.X
        if width <= 0 then
            return
        end
        local alpha = math.clamp((x - Bar.AbsolutePosition.X) / width, 0, 1)
        local value = math.floor(minValue + alpha * (maxValue - minValue) + 0.5)
        Knob.Position = UDim2.new((value - minValue) / (maxValue - minValue), 0, 0, 0)
        Label.Text = name .. ": " .. value
        onChanged(value)
        saveConfig()
    end

    Bar.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.Touch
            or input.UserInputType == Enum.UserInputType.MouseButton1 then
            dragInput = input
            Content.ScrollingEnabled = false -- don't scroll the panel while sliding
            setFromX(input.Position.X)
        end
    end)
    track(UserInputService.InputChanged:Connect(function(input)
        if not dragInput then
            return
        end
        if input.UserInputType == Enum.UserInputType.MouseMovement
            or (input.UserInputType == Enum.UserInputType.Touch and input == dragInput) then
            setFromX(input.Position.X)
        end
    end))
    track(UserInputService.InputEnded:Connect(function(input)
        if dragInput and (input == dragInput or input.UserInputType == Enum.UserInputType.MouseButton1) then
            dragInput = nil
            Content.ScrollingEnabled = true
        end
    end))
end

makeSlider("FOV", 35, FOV_MIN, FOV_MAX, fovRadius, function(v)
    fovRadius = v
    updateFovCircle()
end)
-- 0 = instant snap, higher = slower / more human-looking camera movement.
makeSlider("Smoothness", 75, 0, 90, smoothness, function(v)
    smoothness = v
end)
-- How far ahead (in hundredths of a second) to lead moving targets.
makeSlider("Prediction", 115, 0, 30, predictionCs, function(v)
    predictionCs = v
end)

--------------------------------------------------------------------------
-- Toggles
--------------------------------------------------------------------------
local function makeToggle(name, y, initial, onChanged)
    local state = initial
    local Button = Instance.new("TextButton")
    Button.Size = UDim2.new(1, -20, 0, 25)
    Button.Position = UDim2.new(0, 10, 0, y)
    Button.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
    Button.TextColor3 = Color3.fromRGB(255, 255, 255)
    Button.Font = Enum.Font.Gotham
    Button.TextScaled = true
    Button.Text = name .. ": " .. (state and "ON" or "OFF")
    Button.Parent = Content
    Instance.new("UICorner", Button).CornerRadius = UDim.new(0, 6)
    reserve(y, 25)

    Button.MouseButton1Click:Connect(function()
        state = not state
        Button.Text = name .. ": " .. (state and "ON" or "OFF")
        onChanged(state)
        saveConfig()
    end)
end

makeToggle("Team Check", 155, teamCheck, function(v)
    teamCheck = v
end)
makeToggle("Kill Check", 185, killCheck, function(v)
    killCheck = v
end)
makeToggle("Wall Check", 215, wallCheck, function(v)
    wallCheck = v
end)
makeToggle("Sticky Lock", 245, stickyLock, function(v)
    stickyLock = v
end)
makeToggle("Target NPCs", 275, targetNpcs, function(v)
    targetNpcs = v
end)
makeToggle("Show FOV", 305, showFov, function(v)
    showFov = v
    updateFovCircle()
end)
makeToggle("ESP", 335, espEnabled, function(v)
    espEnabled = v
    if v then
        updateEsp()
    else
        clearEsp()
    end
end)

--------------------------------------------------------------------------
-- Target part dropdown
--------------------------------------------------------------------------
-- Display name -> candidate part names (R6 first, then R15).
local PART_ALIASES = {
    Head = { "Head" },
    Torso = { "Torso", "UpperTorso", "LowerTorso" },
    HumanoidRootPart = { "HumanoidRootPart" },
    ["Left Leg"] = { "Left Leg", "LeftUpperLeg", "LeftLowerLeg" },
    ["Right Leg"] = { "Right Leg", "RightUpperLeg", "RightLowerLeg" },
}
-- "Auto" picks whichever of these is visible and closest to the crosshair.
local AUTO_PARTS = { "Head", "Torso", "HumanoidRootPart" }
local PART_OPTIONS = { "Auto", "Head", "Torso", "HumanoidRootPart", "Left Leg", "Right Leg" }

local function findPart(character, displayName)
    for _, partName in ipairs(PART_ALIASES[displayName] or { displayName }) do
        local part = character:FindFirstChild(partName)
        if part and part:IsA("BasePart") then
            return part
        end
    end
    return nil
end

do
    local y = 365
    local Holder = Instance.new("Frame")
    Holder.Size = UDim2.new(1, -20, 0, 36)
    Holder.Position = UDim2.new(0, 10, 0, y)
    Holder.BackgroundTransparency = 1
    Holder.ZIndex = 5
    Holder.Parent = Content
    -- leave room below for the open list (it is clipped by the scroll area)
    reserve(y, 36 + #PART_OPTIONS * 20)

    local Label = Instance.new("TextLabel")
    Label.Text = "Aimbot Target Part"
    Label.Size = UDim2.new(1, 0, 0, 16)
    Label.TextSize = 13
    Label.TextColor3 = Color3.fromRGB(255, 255, 255)
    Label.BackgroundTransparency = 1
    Label.Font = Enum.Font.Gotham
    Label.ZIndex = 5
    Label.Parent = Holder

    local Selected = Instance.new("TextButton")
    Selected.Size = UDim2.new(1, 0, 0, 20)
    Selected.Position = UDim2.new(0, 0, 0, 16)
    Selected.BackgroundColor3 = Color3.fromRGB(25, 25, 25)
    Selected.BorderSizePixel = 0
    Selected.Text = targetPartName
    Selected.TextSize = 14
    Selected.TextColor3 = Color3.fromRGB(255, 255, 255)
    Selected.Font = Enum.Font.GothamBold
    Selected.ZIndex = 5
    Selected.Parent = Holder

    local List = Instance.new("Frame")
    List.Visible = false
    List.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
    List.BorderSizePixel = 0
    List.Position = UDim2.new(0, 0, 1, 0)
    List.Size = UDim2.new(1, 0, 0, #PART_OPTIONS * 20)
    List.ClipsDescendants = true
    List.ZIndex = 6
    List.Parent = Selected

    for i, option in ipairs(PART_OPTIONS) do
        local Item = Instance.new("TextButton")
        Item.Text = option
        Item.Size = UDim2.new(1, 0, 0, 20)
        Item.Position = UDim2.new(0, 0, 0, (i - 1) * 20)
        Item.BackgroundTransparency = 1
        Item.TextSize = 14
        Item.TextColor3 = Color3.fromRGB(255, 255, 255)
        Item.Font = Enum.Font.Gotham
        Item.ZIndex = 7
        Item.Parent = List
        Item.MouseButton1Click:Connect(function()
            targetPartName = option
            Selected.Text = option
            List.Visible = false
            saveConfig()
        end)
    end

    Selected.MouseButton1Click:Connect(function()
        List.Visible = not List.Visible
    end)
end

--------------------------------------------------------------------------
-- NPC tracking (Humanoid models that are not player characters)
--------------------------------------------------------------------------
local npcModels = {} -- [Model] = true

local function considerNpc(inst)
    if inst:IsA("Humanoid") then
        local model = inst.Parent
        if model and model:IsA("Model") and not Players:GetPlayerFromCharacter(model) then
            npcModels[model] = true
        end
    end
end

task.spawn(function()
    for _, inst in ipairs(workspace:GetDescendants()) do
        considerNpc(inst)
    end
end)
track(workspace.DescendantAdded:Connect(considerNpc))
track(workspace.DescendantRemoving:Connect(function(inst)
    if npcModels[inst] then
        npcModels[inst] = nil
    end
end))

--------------------------------------------------------------------------
-- Targeting
--------------------------------------------------------------------------
local rayParams = RaycastParams.new()
rayParams.FilterType = Enum.RaycastFilterType.Exclude
rayParams.IgnoreWater = true

-- Line-of-sight check that sees through glass, invisible walls and
-- non-collidable decoration (common in shooters), up to a few layers deep.
local function isVisible(origin, part, character)
    local ignore = { LocalPlayer.Character, workspace.CurrentCamera }
    local target = part.Position
    for _ = 1, 4 do
        rayParams.FilterDescendantsInstances = ignore
        local result = workspace:Raycast(origin, target - origin, rayParams)
        if not result then
            return true
        end
        local hit = result.Instance
        if hit:IsDescendantOf(character) then
            return true
        end
        if hit.Transparency >= 0.9 or not hit.CanCollide then
            table.insert(ignore, hit)
        else
            return false
        end
    end
    return false
end

local function isTeammate(character)
    local player = Players:GetPlayerFromCharacter(character)
    return player ~= nil and player.Team ~= nil and player.Team == LocalPlayer.Team
end

-- Returns (part, screenDistance) for the best aim part on this character,
-- or nil if it fails the enabled checks.
-- Flags many shooters use instead of (or before) setting Health to 0.
local DOWNED_FLAGS = { "Dead", "IsDead", "Died", "Downed", "Knocked", "KnockedOut", "KO", "Ragdoll", "Ragdolled" }

local function hasFlag(inst)
    for _, name in ipairs(DOWNED_FLAGS) do
        if inst:GetAttribute(name) == true then
            return true
        end
        local value = inst:FindFirstChild(name)
        if value and value:IsA("BoolValue") and value.Value then
            return true
        end
    end
    return false
end

-- True when the character is dead or can't be hurt right now. Games often
-- leave Health above 0 for a moment (or forever) after a kill, so Health
-- alone isn't enough.
local function isDeadOrDown(character, humanoid)
    if humanoid.Health <= 0 or humanoid:GetState() == Enum.HumanoidStateType.Dead then
        return true
    end
    if not character:FindFirstChild("HumanoidRootPart") and not character:FindFirstChild("Head") then
        return true -- body taken apart / ragdoll leftovers
    end
    if hasFlag(character) or hasFlag(humanoid) then
        return true
    end
    local player = Players:GetPlayerFromCharacter(character)
    if player and hasFlag(player) then
        return true
    end
    return false
end

-- Bodies that died are ignored for a while even if the game resets their
-- health (common with ragdoll corpses). Player characters are ignored for
-- DEAD_IGNORE_TIME so games that respawn in place still work; NPC / corpse
-- models stay ignored for good.
local DEAD_IGNORE_TIME = 5
local deadModels = setmetatable({}, { __mode = "k" }) -- [Model] = os.clock() of death

local function recentlyDied(character)
    local diedAt = deadModels[character]
    if not diedAt then
        return false
    end
    if Players:GetPlayerFromCharacter(character) and os.clock() - diedAt > DEAD_IGNORE_TIME then
        deadModels[character] = nil
        return false
    end
    return true
end

local function evaluateCharacter(character, camera, center, origin)
    if not character or not character.Parent or character == LocalPlayer.Character then
        return nil
    end
    local humanoid = character:FindFirstChildOfClass("Humanoid")
    if not humanoid then
        return nil
    end
    -- Truly dead targets are always skipped. Kill Check additionally skips
    -- downed / knocked / ragdolled players and spawn-protected ones.
    if humanoid.Health <= 0 or humanoid:GetState() == Enum.HumanoidStateType.Dead then
        deadModels[character] = os.clock()
        return nil
    end
    if recentlyDied(character) then
        return nil
    end
    if killCheck and (isDeadOrDown(character, humanoid) or character:FindFirstChildOfClass("ForceField")) then
        return nil
    end
    if teamCheck and isTeammate(character) then
        return nil
    end

    local candidates
    if targetPartName == "Auto" then
        candidates = AUTO_PARTS
    else
        -- Chosen part first; fall back to the head / root so the aimbot
        -- still works on custom rigs that lack it.
        candidates = { targetPartName, "Head", "HumanoidRootPart" }
    end

    local bestPart, bestDist
    for _, name in ipairs(candidates) do
        local part = findPart(character, name)
        if part then
            local screenPos, onScreen = camera:WorldToViewportPoint(part.Position)
            if onScreen and (not wallCheck or isVisible(origin, part, character)) then
                local dist = (Vector2.new(screenPos.X, screenPos.Y) - center).Magnitude
                if targetPartName ~= "Auto" then
                    return part, dist -- first valid part in priority order
                end
                if not bestDist or dist < bestDist then
                    bestPart, bestDist = part, dist
                end
            end
        end
    end
    return bestPart, bestDist
end

local currentTarget -- character model we are locked onto

local function acquireTarget(camera)
    local center = camera.ViewportSize / 2
    local origin = camera.CFrame.Position

    -- Sticky lock: keep the current target while it stays valid, even if it
    -- drifts a bit past the FOV edge, so the aim doesn't flick between people.
    if stickyLock and currentTarget then
        local part, dist = evaluateCharacter(currentTarget, camera, center, origin)
        if part and dist <= fovRadius * 1.5 then
            return part
        end
        currentTarget = nil
    end

    local bestPart, bestChar
    local bestDist = fovRadius
    local function consider(character)
        local part, dist = evaluateCharacter(character, camera, center, origin)
        if part and dist < bestDist then
            bestPart, bestChar, bestDist = part, character, dist
        end
    end

    for _, player in ipairs(Players:GetPlayers()) do
        if player ~= LocalPlayer then
            consider(player.Character)
        end
    end
    if targetNpcs then
        for model in pairs(npcModels) do
            consider(model)
        end
    end

    currentTarget = bestChar
    return bestPart
end

-- Where to aim: the part position, led by its velocity when prediction is on.
local function aimPoint(part)
    local pos = part.Position
    if predictionCs > 0 then
        local velocity = part.AssemblyLinearVelocity
        local root = part.Parent and part.Parent:FindFirstChild("HumanoidRootPart")
        if root and velocity.Magnitude < 0.1 then
            velocity = root.AssemblyLinearVelocity
        end
        pos = pos + velocity * (predictionCs / 100)
    end
    return pos
end

RunService:BindToRenderStep(RENDER_NAME, Enum.RenderPriority.Camera.Value + 1, function(dt)
    updateFovCircle()
    updateEsp()
    if not aimbotEnabled then
        currentTarget = nil
        return
    end
    local camera = workspace.CurrentCamera
    if not camera then
        return
    end
    local part = acquireTarget(camera)
    if not part then
        return
    end

    local camPos = camera.CFrame.Position
    local goal = CFrame.lookAt(camPos, aimPoint(part))
    if smoothness <= 0 then
        camera.CFrame = goal
    else
        -- Frame-rate independent smoothing: same feel at 30 or 120 FPS.
        local keep = (smoothness / 100) ^ (dt * 60)
        camera.CFrame = camera.CFrame:Lerp(goal, 1 - keep)
    end
end)

--------------------------------------------------------------------------
-- Startup
--------------------------------------------------------------------------
notify("Script Ativado\nBy ZecadaDiv", "rbxassetid://6026984224")
if setclipboard then
    pcall(setclipboard, "https://www.roblox.com/pt/users/7904067601/profile?friendshipSourceType=PlayerSearch")
end
