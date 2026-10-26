-- 7. CLASSIC C00LKIDD 2015 GUI (c00lgui)
--
-- Drop-in replacement for section 7. Builds the GUI the way 2015 Roblox
-- drew it: flat black frames, square red borders (BorderColor3, no
-- UICorner/UIStroke - those didn't exist yet), SourceSans text, a 2-column
-- button grid and "<  1/2  >" paging at the bottom.
--
-- Buttons only work on the client, so put C00lkidd_2015_GUI_Client.lua in
-- StarterPlayer > StarterPlayerScripts as a LocalScript. It wires up
-- dragging, X, paging and every button by name.

local RED = Color3.fromRGB(255, 0, 0)
local BLACK = Color3.new(0, 0, 0)
local WHITE = Color3.new(1, 1, 1)

local PANEL_W, PANEL_H = 300, 345
local BTN_W, BTN_H = 135, 30

-- name shown on the button = name the client looks for
local PAGES = {
    {
        "Skybox", "Decal Spam",
        "Music", "Disco",
        "Fire", "Sparkles",
        "Smoke", "Particles",
        "Fog", "Night",
        "Red Sky", "Clear All",
    },
    {
        "Speed", "High Jump",
        "Highlight", "Spin",
        "Big Head", "Invisible",
        "Rainbow", "Gravity",
        "Fullbright", "Fov",
        "Reset", "Clear All",
    },
}

local function classic(obj)
    obj.BackgroundColor3 = BLACK
    obj.BorderColor3 = RED
    obj.BorderSizePixel = 1
    return obj
end

local function label(parent, text, pos, size, font, textSize, color)
    local l = Instance.new("TextLabel")
    l.BackgroundTransparency = 1
    l.Position = pos
    l.Size = size
    l.Font = font
    l.TextSize = textSize
    l.Text = text
    l.TextColor3 = color
    l.TextStrokeTransparency = 0.5
    l.Parent = parent
    return l
end

local function button(parent, name, text, pos, size)
    local b = classic(Instance.new("TextButton"))
    b.Name = name
    b.Position = pos
    b.Size = size
    b.AutoButtonColor = true
    b.Font = Enum.Font.SourceSans
    b.TextSize = 18
    b.Text = text
    b.TextColor3 = WHITE
    b.TextStrokeTransparency = 0.5
    b.Parent = parent
    return b
end

local function addPlayerEffects(player)
    local playerGui = player:WaitForChild("PlayerGui")

    local existing = playerGui:FindFirstChild("CoolKidGUI")
    if existing then
        existing:Destroy()
    end

    local gui = Instance.new("ScreenGui")
    gui.Name = "CoolKidGUI"
    gui.ResetOnSpawn = false
    gui.DisplayOrder = 100
    gui.Parent = playerGui

    -- MAIN PANEL
    local panel = classic(Instance.new("Frame"))
    panel.Name = "MainPanel"
    panel.Size = UDim2.fromOffset(PANEL_W, PANEL_H)
    panel.Position = UDim2.new(0.5, -PANEL_W / 2, 0.5, -PANEL_H / 2)
    panel.BorderSizePixel = 3
    panel.Active = true
    panel.Parent = gui

    -- TITLE BAR (drag handle)
    local titleBar = classic(Instance.new("Frame"))
    titleBar.Name = "TitleBar"
    titleBar.Size = UDim2.new(1, 0, 0, 30)
    titleBar.Active = true
    titleBar.Parent = panel

    label(titleBar, "c00lgui", UDim2.fromOffset(0, 0), UDim2.new(1, 0, 1, 0),
        Enum.Font.SourceSansBold, 26, RED).Name = "Title"

    local close = button(titleBar, "Close", "X",
        UDim2.new(1, -30, 0, 0), UDim2.fromOffset(30, 30))
    close.Font = Enum.Font.SourceSansBold
    close.TextColor3 = RED
    close.TextSize = 22

    label(panel, "Team C00lkidd join today!", UDim2.fromOffset(0, 32),
        UDim2.new(1, 0, 0, 20), Enum.Font.SourceSans, 16, WHITE).Name = "Subtitle"

    -- PAGES
    local pages = Instance.new("Folder")
    pages.Name = "Pages"
    pages.Parent = panel

    for i, names in ipairs(PAGES) do
        local page = Instance.new("Frame")
        page.Name = "Page" .. i
        page.BackgroundTransparency = 1
        page.Position = UDim2.fromOffset(10, 60)
        page.Size = UDim2.new(1, -20, 0, 6 * (BTN_H + 10))
        page.Visible = i == 1
        page.Parent = pages

        for n, name in ipairs(names) do
            local col = (n - 1) % 2
            local row = math.floor((n - 1) / 2)
            button(page, name, name,
                UDim2.fromOffset(col * (BTN_W + 10), row * (BTN_H + 10)),
                UDim2.fromOffset(BTN_W, BTN_H))
        end
    end

    -- PAGE SWITCHER
    local y = PANEL_H - 40
    button(panel, "Prev", "<", UDim2.fromOffset(10, y), UDim2.fromOffset(40, 30))
        .Font = Enum.Font.SourceSansBold
    button(panel, "Next", ">", UDim2.fromOffset(PANEL_W - 50, y), UDim2.fromOffset(40, 30))
        .Font = Enum.Font.SourceSansBold
    label(panel, "1/" .. #PAGES, UDim2.fromOffset(60, y), UDim2.new(1, -120, 0, 30),
        Enum.Font.SourceSansBold, 22, RED).Name = "PageNumber"

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
