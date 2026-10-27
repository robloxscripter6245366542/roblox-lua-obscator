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

local FACE_ID = 0 -- c00lkidd logo image (set to your decal upload; 0 = glass ring)

-- glassy palette
local BG      = Color3.fromRGB(18, 18, 26)
local BG2     = Color3.fromRGB(46, 46, 64)
local SURFACE = Color3.fromRGB(38, 38, 52)
local STROKE  = Color3.fromRGB(86, 86, 112)
local EDGE    = Color3.fromRGB(255, 255, 255)
local ACCENT  = Color3.fromRGB(255, 62, 74)
local TEXT    = Color3.fromRGB(242, 242, 250)
local MUTED   = Color3.fromRGB(156, 156, 176)

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

-- a glassy command button (styling only; the client wires clicks + anims)
local function makeButton(parent, name, text)
    local b = Instance.new("TextButton")
    b.Name = name
    b.AutoButtonColor = false
    b.BackgroundColor3 = SURFACE
    b.BackgroundTransparency = 0.25
    b.BorderSizePixel = 0
    b.Text = text
    b.Font = Enum.Font.GothamMedium
    b.TextSize = 14
    b.TextColor3 = TEXT
    b.TextTruncate = Enum.TextTruncate.AtEnd
    b.Parent = parent
    corner(b, 10)
    stroke(b, EDGE, 1, 0.72)
    local scale = Instance.new("UIScale")
    scale.Name = "Scale"
    scale.Parent = b
    return b
end

-- the c00lkidd logo: an image in a glass ring. Set FACE_ID to your decal;
-- at 0 it shows a clean glass disc with an accent ring (no blocky face).
local function makeLogo(parent, px, z)
    local f = Instance.new("ImageLabel")
    f.Name = "Logo"
    f.BackgroundColor3 = Color3.fromRGB(30, 30, 42)
    f.BackgroundTransparency = 0.1
    f.BorderSizePixel = 0
    f.Size = UDim2.fromOffset(px, px)
    f.Image = "rbxassetid://" .. FACE_ID
    f.ScaleType = Enum.ScaleType.Crop
    f.ZIndex = z or 1
    f.Parent = parent
    corner(f, math.floor(px / 2))
    local ring = stroke(f, ACCENT, math.max(1.5, px * 0.06), 0)
    ring.Name = "Ring"
    return f
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
    shadow.ImageColor3 = Color3.fromRGB(255, 40, 55) -- accent glow halo
    shadow.ImageTransparency = 0.62
    shadow.ScaleType = Enum.ScaleType.Slice
    shadow.SliceCenter = Rect.new(24, 24, 276, 276)
    shadow.Size = UDim2.fromOffset(PW + 56, PH + 56)
    shadow.Position = UDim2.new(0.5, -PW / 2 - 28, 0.5, -PH / 2 - 28)
    shadow.ZIndex = 0
    shadow.Parent = gui

    -- MAIN PANEL (translucent glass; CanvasGroup fades the whole window at once)
    local panel = Instance.new("CanvasGroup")
    panel.Name = "MainPanel"
    panel.Size = UDim2.fromOffset(PW, PH)
    panel.Position = UDim2.new(0.5, -PW / 2, 0.5, -PH / 2)
    panel.BackgroundColor3 = WHITE -- the gradient supplies the real color
    panel.BackgroundTransparency = 0.08
    panel.BorderSizePixel = 0
    panel.Active = true
    panel.Parent = gui
    corner(panel, 18)
    stroke(panel, EDGE, 1.4, 0.55).Name = "PanelStroke"

    local grad = Instance.new("UIGradient")
    grad.Rotation = 90
    grad.Color = ColorSequence.new({
        ColorSequenceKeypoint.new(0, BG2),
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

    local logo = makeLogo(titleBar, 26, 1)
    logo.Position = UDim2.fromOffset(14, 13)

    local title = Instance.new("TextLabel")
    title.Name = "Title"
    title.BackgroundTransparency = 1
    title.Position = UDim2.fromOffset(46, 9)
    title.Size = UDim2.new(1, -100, 0, 22)
    title.Font = Enum.Font.GothamBold
    title.TextSize = 18
    title.TextXAlignment = Enum.TextXAlignment.Left
    title.Text = "c00lkidd"
    title.TextColor3 = TEXT
    title.Parent = titleBar

    local subtitle = Instance.new("TextLabel")
    subtitle.Name = "Subtitle"
    subtitle.BackgroundTransparency = 1
    subtitle.Position = UDim2.fromOffset(46, 30)
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
    close.BackgroundTransparency = 0.25
    close.BorderSizePixel = 0
    close.AutoButtonColor = false
    close.Size = UDim2.fromOffset(28, 28)
    close.Position = UDim2.new(1, -40, 0, 12)
    close.Font = Enum.Font.GothamBold
    close.TextSize = 13
    close.Text = "✕"
    close.TextColor3 = MUTED
    close.Parent = titleBar
    corner(close, 9)
    stroke(close, EDGE, 1, 0.72)

    -- help button (re-opens the tutorial)
    local help = Instance.new("TextButton")
    help.Name = "Help"
    help.BackgroundColor3 = SURFACE
    help.BackgroundTransparency = 0.25
    help.BorderSizePixel = 0
    help.AutoButtonColor = false
    help.Size = UDim2.fromOffset(28, 28)
    help.Position = UDim2.new(1, -74, 0, 12)
    help.Font = Enum.Font.GothamBold
    help.TextSize = 15
    help.Text = "?"
    help.TextColor3 = MUTED
    help.Parent = titleBar
    corner(help, 9)
    stroke(help, EDGE, 1, 0.72)

    -- TAB BAR (glass pill slides to the active tab)
    local tabBar = Instance.new("Frame")
    tabBar.Name = "TabBar"
    tabBar.BackgroundTransparency = 1
    tabBar.Position = UDim2.fromOffset(16, 56)
    tabBar.Size = UDim2.new(1, -32, 0, 30)
    tabBar.Parent = panel

    local indicator = Instance.new("Frame")
    indicator.Name = "Indicator"
    indicator.BackgroundColor3 = ACCENT
    indicator.BackgroundTransparency = 0.76
    indicator.BorderSizePixel = 0
    indicator.Size = UDim2.new(0, 72, 1, 0)
    indicator.Position = UDim2.new(0, 0, 0, 0)
    indicator.ZIndex = 1
    indicator.Parent = tabBar
    corner(indicator, 9)
    stroke(indicator, ACCENT, 1, 0.35).Name = "Glow"

    local tabX = 0
    for i, entry in ipairs(PAGES) do
        local t = Instance.new("TextButton")
        t.Name = "Tab" .. i
        t.BackgroundTransparency = 1
        t.AutoButtonColor = false
        t.Position = UDim2.fromOffset(tabX, 0)
        t.Size = UDim2.fromOffset(72, 30)
        t.Font = Enum.Font.GothamBold
        t.TextSize = 13
        t.Text = entry.name
        t.TextColor3 = i == 1 and TEXT or MUTED
        t.ZIndex = 2
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

    -- TUTORIAL overlay (shown on first open; re-open with the ? button).
    -- Scrolls so it fits on any panel size.
    local tut = Instance.new("CanvasGroup")
    tut.Name = "Tutorial"
    tut.Position = UDim2.fromOffset(8, 50)
    tut.Size = UDim2.new(1, -16, 1, -58)
    tut.BackgroundColor3 = Color3.fromRGB(22, 22, 32)
    tut.BackgroundTransparency = 0.04
    tut.BorderSizePixel = 0
    tut.ZIndex = 20
    tut.Visible = true
    tut.Parent = panel
    corner(tut, 14)
    stroke(tut, EDGE, 1.2, 0.6)

    local tscroll = Instance.new("ScrollingFrame")
    tscroll.Name = "TScroll"
    tscroll.BackgroundTransparency = 1
    tscroll.BorderSizePixel = 0
    tscroll.Size = UDim2.new(1, 0, 1, 0)
    tscroll.ScrollBarThickness = 3
    tscroll.ScrollBarImageColor3 = ACCENT
    tscroll.CanvasSize = UDim2.new()
    tscroll.AutomaticCanvasSize = Enum.AutomaticSize.Y
    tscroll.ZIndex = 21
    tscroll.Parent = tut

    local tpad = Instance.new("UIPadding")
    tpad.PaddingTop = UDim.new(0, 16)
    tpad.PaddingBottom = UDim.new(0, 16)
    tpad.PaddingLeft = UDim.new(0, 16)
    tpad.PaddingRight = UDim.new(0, 16)
    tpad.Parent = tscroll

    local tlist = Instance.new("UIListLayout")
    tlist.FillDirection = Enum.FillDirection.Vertical
    tlist.HorizontalAlignment = Enum.HorizontalAlignment.Center
    tlist.Padding = UDim.new(0, 12)
    tlist.SortOrder = Enum.SortOrder.LayoutOrder
    tlist.Parent = tscroll

    -- the c00lkidd logo image (glass ring; set FACE_ID to your decal)
    local face = makeLogo(tscroll, 80, 21)
    face.Name = "Face"
    face.LayoutOrder = 1

    local heading = Instance.new("TextLabel")
    heading.Name = "Heading"
    heading.LayoutOrder = 2
    heading.BackgroundTransparency = 1
    heading.Size = UDim2.new(1, 0, 0, 22)
    heading.Font = Enum.Font.GothamBold
    heading.TextSize = 18
    heading.Text = "Welcome to c00lgui"
    heading.TextColor3 = TEXT
    heading.ZIndex = 21
    heading.Parent = tscroll

    local body = Instance.new("TextLabel")
    body.Name = "Body"
    body.LayoutOrder = 3
    body.BackgroundTransparency = 1
    body.AutomaticSize = Enum.AutomaticSize.Y
    body.Size = UDim2.new(1, 0, 0, 0)
    body.Font = Enum.Font.Gotham
    body.TextSize = 13
    body.TextWrapped = true
    body.RichText = true
    body.TextYAlignment = Enum.TextYAlignment.Top
    body.TextXAlignment = Enum.TextXAlignment.Left
    body.Text = "• <b>Tabs</b> at the top switch between <b>World</b>, <b>Player</b> and <b>Script</b>."
        .. "\n• <b>Click any button</b> to toggle that effect — active ones glow red."
        .. "\n• <b>Drag the title bar</b> to move the panel around."
        .. "\n• <b>Clear All</b> turns every effect back off."
        .. "\n• Click the <b>?</b> button any time to open this again."
    body.TextColor3 = MUTED
    body.ZIndex = 21
    body.Parent = tscroll

    local gotIt = Instance.new("TextButton")
    gotIt.Name = "GotIt"
    gotIt.LayoutOrder = 4
    gotIt.AutoButtonColor = false
    gotIt.BackgroundColor3 = ACCENT
    gotIt.BorderSizePixel = 0
    gotIt.Size = UDim2.new(1, 0, 0, 34)
    gotIt.Font = Enum.Font.GothamBold
    gotIt.TextSize = 14
    gotIt.Text = "Got it"
    gotIt.TextColor3 = Color3.new(1, 1, 1)
    gotIt.ZIndex = 21
    gotIt.Parent = tscroll
    corner(gotIt, 8)

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
