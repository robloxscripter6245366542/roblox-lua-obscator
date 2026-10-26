-- 7. CLASSIC C00LKIDD GUI (c00lgui) - PREMIUM UI
--
-- Drop-in replacement for section 7. Builds a clean, modern c00lgui: a
-- rounded dark panel with a soft drop shadow, a subtle gradient, Gotham
-- text, named tabs (World / Player) with a sliding accent indicator, and a
-- 2-column button grid. All the open/close, tab, hover and toggle
-- ANIMATIONS live in the client script.
--
-- Buttons only work on the client, so put C00lkidd_2015_GUI_Client.lua in
-- StarterPlayer > StarterPlayerScripts as a LocalScript. It wires up
-- dragging, close, tabs and every button by name.

local RED = Color3.fromRGB(255, 0, 0)
local BLACK = Color3.new(0, 0, 0)
local WHITE = Color3.new(1, 1, 1)

-- modern palette
local BG      = Color3.fromRGB(17, 17, 21)
local SURFACE = Color3.fromRGB(31, 31, 38)
local STROKE  = Color3.fromRGB(54, 54, 64)
local ACCENT  = Color3.fromRGB(240, 52, 62)
local TEXT    = Color3.fromRGB(238, 238, 245)
local MUTED   = Color3.fromRGB(150, 150, 163)

local PW, PH = 344, 420

-- each tab is a named page; button name = the name the client looks for
local PAGES = {
    {
        name = "World",
        items = {
            "Skybox", "Decal Spam",
            "Music", "Disco",
            "Fog", "Night",
            "Red Sky", "Fullbright",
            "Gravity", "Rainbow",
            "Fov", "Clear All",
        },
    },
    {
        name = "Player",
        items = {
            "Speed", "High Jump",
            "Highlight", "Spin",
            "Big Head", "Invisible",
            "Fire", "Sparkles",
            "Smoke", "Particles",
            "Reset", "Clear All",
        },
    },
    {
        name = "Script",
        items = {
            "Scream", "Jumpscare",
            "Thunder", "Blood",
            "Trail", "Confetti",
            "Fireworks", "Sit",
            "Freeze", "Flames",
            "Teleport Spawn", "Unanchor All",
            "Clear All",
        },
    },
}

local function corner(obj, r)
    local c = Instance.new("UICorner")
    c.CornerRadius = UDim.new(0, r)
    c.Parent = obj
    return obj
end

local function stroke(obj, color, thickness, transparency)
    local s = Instance.new("UIStroke")
    s.Name = "Stroke"
    s.Color = color
    s.Thickness = thickness or 1
    s.Transparency = transparency or 0
    s.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
    s.Parent = obj
    return s
end

-- a modern command button (styling only; the client wires clicks + anims)
local function makeButton(parent, name, text)
    local b = Instance.new("TextButton")
    b.Name = name
    b.AutoButtonColor = false
    b.BackgroundColor3 = SURFACE
    b.BorderSizePixel = 0
    b.Text = text
    b.Font = Enum.Font.GothamMedium
    b.TextSize = 14
    b.TextColor3 = TEXT
    b.TextTruncate = Enum.TextTruncate.AtEnd
    b.Parent = parent
    corner(b, 8)
    stroke(b, STROKE, 1, 0)
    local scale = Instance.new("UIScale")
    scale.Name = "Scale"
    scale.Parent = b
    return b
end

local function buildGui()
    local gui = Instance.new("ScreenGui")
    gui.Name = "CoolKidGUI"
    gui.ResetOnSpawn = false
    gui.DisplayOrder = 100
    gui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling

    -- soft drop shadow (sibling behind the panel, follows it on drag)
    local shadow = Instance.new("ImageLabel")
    shadow.Name = "Shadow"
    shadow.BackgroundTransparency = 1
    shadow.Image = "rbxassetid://5028857084"
    shadow.ImageColor3 = BLACK
    shadow.ImageTransparency = 0.5
    shadow.ScaleType = Enum.ScaleType.Slice
    shadow.SliceCenter = Rect.new(24, 24, 276, 276)
    shadow.Size = UDim2.fromOffset(PW + 36, PH + 36)
    shadow.Position = UDim2.new(0.5, -PW / 2 - 18, 0.5, -PH / 2 - 18)
    shadow.ZIndex = 0
    shadow.Parent = gui

    -- MAIN PANEL (CanvasGroup so the whole window fades as one on open/close)
    local panel = Instance.new("CanvasGroup")
    panel.Name = "MainPanel"
    panel.Size = UDim2.fromOffset(PW, PH)
    panel.Position = UDim2.new(0.5, -PW / 2, 0.5, -PH / 2)
    panel.BackgroundColor3 = WHITE -- the gradient supplies the real color
    panel.BorderSizePixel = 0
    panel.Active = true
    panel.Parent = gui
    corner(panel, 14)
    stroke(panel, STROKE, 1.2, 0).Name = "PanelStroke"

    local grad = Instance.new("UIGradient")
    grad.Rotation = 90
    grad.Color = ColorSequence.new({
        ColorSequenceKeypoint.new(0, Color3.fromRGB(34, 34, 42)),
        ColorSequenceKeypoint.new(1, BG),
    })
    grad.Parent = panel

    local panelScale = Instance.new("UIScale")
    panelScale.Name = "Scale"
    panelScale.Parent = panel

    -- TITLE BAR (drag handle)
    local titleBar = Instance.new("Frame")
    titleBar.Name = "TitleBar"
    titleBar.BackgroundTransparency = 1
    titleBar.Size = UDim2.new(1, 0, 0, 52)
    titleBar.Active = true
    titleBar.Parent = panel

    local dot = Instance.new("Frame")
    dot.Name = "Dot"
    dot.BackgroundColor3 = ACCENT
    dot.BorderSizePixel = 0
    dot.Size = UDim2.fromOffset(10, 10)
    dot.Position = UDim2.fromOffset(18, 21)
    dot.Parent = titleBar
    corner(dot, 5)

    local title = Instance.new("TextLabel")
    title.Name = "Title"
    title.BackgroundTransparency = 1
    title.Position = UDim2.fromOffset(36, 9)
    title.Size = UDim2.new(1, -90, 0, 22)
    title.Font = Enum.Font.GothamBold
    title.TextSize = 18
    title.TextXAlignment = Enum.TextXAlignment.Left
    title.Text = "c00lgui"
    title.TextColor3 = TEXT
    title.Parent = titleBar

    local subtitle = Instance.new("TextLabel")
    subtitle.Name = "Subtitle"
    subtitle.BackgroundTransparency = 1
    subtitle.Position = UDim2.fromOffset(36, 30)
    subtitle.Size = UDim2.new(1, -90, 0, 14)
    subtitle.Font = Enum.Font.Gotham
    subtitle.TextSize = 11
    subtitle.TextXAlignment = Enum.TextXAlignment.Left
    subtitle.Text = "Team C00lkidd join today!"
    subtitle.TextColor3 = MUTED
    subtitle.Parent = titleBar

    local close = Instance.new("TextButton")
    close.Name = "Close"
    close.BackgroundColor3 = SURFACE
    close.BorderSizePixel = 0
    close.AutoButtonColor = false
    close.Size = UDim2.fromOffset(28, 28)
    close.Position = UDim2.new(1, -40, 0, 12)
    close.Font = Enum.Font.GothamBold
    close.TextSize = 13
    close.Text = "✕"
    close.TextColor3 = MUTED
    close.Parent = titleBar
    corner(close, 8)
    stroke(close, STROKE, 1, 0)

    -- TAB BAR (named tabs + sliding indicator)
    local tabBar = Instance.new("Frame")
    tabBar.Name = "TabBar"
    tabBar.BackgroundTransparency = 1
    tabBar.Position = UDim2.fromOffset(16, 56)
    tabBar.Size = UDim2.new(1, -32, 0, 30)
    tabBar.Parent = panel

    local sep = Instance.new("Frame")
    sep.Name = "Sep"
    sep.BackgroundColor3 = STROKE
    sep.BackgroundTransparency = 0.4
    sep.BorderSizePixel = 0
    sep.Size = UDim2.new(1, 0, 0, 1)
    sep.Position = UDim2.new(0, 0, 1, 0)
    sep.Parent = tabBar

    local indicator = Instance.new("Frame")
    indicator.Name = "Indicator"
    indicator.BackgroundColor3 = ACCENT
    indicator.BorderSizePixel = 0
    indicator.Size = UDim2.new(0, 60, 0, 3)
    indicator.Position = UDim2.new(0, 0, 1, -3)
    indicator.ZIndex = 2
    indicator.Parent = tabBar
    corner(indicator, 2)

    local tabX = 0
    for i, entry in ipairs(PAGES) do
        local t = Instance.new("TextButton")
        t.Name = "Tab" .. i
        t.BackgroundTransparency = 1
        t.AutoButtonColor = false
        t.Position = UDim2.fromOffset(tabX, 0)
        t.Size = UDim2.fromOffset(72, 28)
        t.Font = Enum.Font.GothamBold
        t.TextSize = 13
        t.Text = entry.name
        t.TextColor3 = i == 1 and TEXT or MUTED
        t.Parent = tabBar
        tabX = tabX + 80
    end

    -- PAGES (one CanvasGroup grid per tab)
    local pages = Instance.new("Folder")
    pages.Name = "Pages"
    pages.Parent = panel

    for i, entry in ipairs(PAGES) do
        local page = Instance.new("CanvasGroup")
        page.Name = "Page" .. i
        page.BackgroundTransparency = 1
        page.BorderSizePixel = 0
        page.Position = UDim2.fromOffset(16, 96)
        page.Size = UDim2.new(1, -32, 1, -108)
        page.Visible = i == 1
        page.Parent = pages

        local grid = Instance.new("UIGridLayout")
        grid.CellSize = UDim2.new(0.5, -5, 0, 34)
        grid.CellPadding = UDim2.fromOffset(10, 10)
        grid.SortOrder = Enum.SortOrder.LayoutOrder
        grid.Parent = page

        for n, name in ipairs(entry.items) do
            makeButton(page, name, name).LayoutOrder = n
        end
    end

    return gui
end

local function addPlayerEffects(player)
    local playerGui = player:WaitForChild("PlayerGui")

    local existing = playerGui:FindFirstChild("CoolKidGUI")
    if existing then
        existing:Destroy()
    end

    local gui = buildGui()
    gui.Parent = playerGui

    -- PLAYER EFFECTS
    if playerEffects then
        local function onCharacter(character)
            local old = character:FindFirstChild("CoolKidHighlight")
            if old then
                old:Destroy()
            end

            local highlight = Instance.new("Highlight")
            highlight.Name = "CoolKidHighlight"
            highlight.FillColor = RED
            highlight.FillTransparency = 0.6
            highlight.OutlineColor = BLACK
            highlight.Parent = character
        end

        player.CharacterAdded:Connect(onCharacter)

        if player.Character then
            onCharacter(player.Character)
        end
    end
end

for _, player in ipairs(Players:GetPlayers()) do
    task.spawn(addPlayerEffects, player)
end

Players.PlayerAdded:Connect(addPlayerEffects)
