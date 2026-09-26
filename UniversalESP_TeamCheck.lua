--!nocheck
-- ============================================================================
--  Universal ESP  —  Team-Colored Body Outline
-- ----------------------------------------------------------------------------
--  * Outlines EVERY player's body using Roblox Highlight instances
--    (works on any character rig — R6, R15, custom).
--  * Colour = each player's own team:
--      - Your team shows in your team's colour (e.g. red).
--      - The other team shows in their colour (e.g. blue).
--      - Players with no team get a fallback colour.
--    New players who join are picked up automatically and coloured by
--    whatever team they're on.
--  * Re-evaluates live, so it keeps working after respawns and when players
--    switch teams mid-game.
--
--  Drop this into any executor and run. No Drawing API required.
-- ============================================================================

local Players    = game:GetService("Players")
local RunService = game:GetService("RunService")

local LocalPlayer = Players.LocalPlayer

-- ==================== CONFIG ====================
local CONFIG = {
    Enabled          = true,
    UseTeamColor     = true,                        -- outline uses each player's TeamColor
    NoTeamColor      = Color3.fromRGB(255, 255, 255),-- colour for players with no team
    FillTransparency = 0.75,                        -- 1 = outline only, lower = more fill
    OutlineTransparency = 0,
    MaxDistance      = 0,                            -- 0 = unlimited, else studs from you
    ShowName         = true,                          -- name tag above each player
}

-- ==================== STATE ====================
-- The name tag uses a BillboardGui (AlwaysOnTop). Besides showing the name,
-- it also isn't subject to the ~31 Highlight render cap, so players still show
-- a marker in a busy server even when their outline can't be drawn.
local highlights = {}   -- [player] = Highlight
local markers    = {}   -- [player] = BillboardGui (name tag)
local running    = true

-- ==================== HELPERS ====================

-- Highlight everyone except yourself; each is coloured by their own team.
local function isTarget(player)
    return player ~= LocalPlayer
end

-- Colour to use for a player's outline: their team colour, or the no-team
-- fallback. (player.Team is nil for neutral / unassigned players.)
local function colorFor(player)
    if CONFIG.UseTeamColor and player.Team then
        return player.TeamColor.Color
    end
    return CONFIG.NoTeamColor
end

-- A part we can adorn to / distance-check against. Not every character has a
-- Humanoid the instant it spawns (or at all, for custom rigs), so we fall back
-- through PrimaryPart -> HumanoidRootPart -> Head -> any BasePart. This is the
-- key fix for targets that previously got skipped.
local function getRootPart(character)
    return character.PrimaryPart
        or character:FindFirstChild("HumanoidRootPart")
        or character:FindFirstChild("Head")
        or character:FindFirstChildWhichIsA("BasePart")
end

local function withinRange(character)
    if CONFIG.MaxDistance <= 0 then return true end
    local myChar = LocalPlayer.Character
    local myRoot = myChar and getRootPart(myChar)
    local root   = getRootPart(character)
    if not (myRoot and root) then return true end
    return (myRoot.Position - root.Position).Magnitude <= CONFIG.MaxDistance
end

local function removeHighlight(player)
    local h = highlights[player]
    if h then
        h:Destroy()
        highlights[player] = nil
    end
end

local function removeMarker(player)
    local m = markers[player]
    if m then
        m:Destroy()
        markers[player] = nil
    end
end

local function removeESP(player)
    removeHighlight(player)
    removeMarker(player)
end

local function ensureHighlight(player, character, col)
    local h = highlights[player]
    -- Recreate if missing, destroyed, or now on a new (respawned) character.
    if not h or h.Parent ~= character then
        removeHighlight(player)
        h = Instance.new("Highlight")
        h.Name = "UniversalESP"
        h.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop -- see through walls
        h.Adornee = character
        h.Parent  = character
        highlights[player] = h
    end

    h.FillColor          = col
    h.OutlineColor       = col
    h.FillTransparency   = CONFIG.FillTransparency
    h.OutlineTransparency = CONFIG.OutlineTransparency
end

-- Name tag above the head, coloured to match the player's team (same as the
-- outline): blue-team players get a blue name, red-team a red name, etc.
local function ensureMarker(player, character, col)
    local root = getRootPart(character)
    if not root then
        removeMarker(player)
        return
    end

    local m = markers[player]
    if not m or m.Adornee ~= root or m.Parent == nil then
        removeMarker(player)
        m = Instance.new("BillboardGui")
        m.Name = "UniversalESP_Tag"
        m.AlwaysOnTop = true                 -- through walls; not capped like Highlight
        m.Size = UDim2.fromOffset(200, 20)
        m.StudsOffset = Vector3.new(0, 3, 0) -- float above the head
        m.Adornee = root
        m.Parent  = root

        local lbl = Instance.new("TextLabel")
        lbl.Name = "Name"
        lbl.BackgroundTransparency = 1
        lbl.Size = UDim2.fromScale(1, 1)
        lbl.Font = Enum.Font.GothamBold
        lbl.TextSize = 14
        lbl.TextStrokeTransparency = 0.4
        lbl.Parent = m

        markers[player] = m
    end

    local lbl = m:FindFirstChild("Name")
    if lbl then
        lbl.Text = (player.DisplayName ~= "" and player.DisplayName) or player.Name
        lbl.TextColor3 = col  -- name colour matches the team-coloured outline
    end
end

-- ==================== MAIN REFRESH LOOP ====================
local function refresh()
    for _, player in ipairs(Players:GetPlayers()) do
        local character = player.Character
        if CONFIG.Enabled
            and isTarget(player)
            and character
            and getRootPart(character)   -- something we can actually adorn
            and withinRange(character)
        then
            local col = colorFor(player)
            ensureHighlight(player, character, col)
            if CONFIG.ShowName then
                ensureMarker(player, character, col)
            else
                removeMarker(player)
            end
        else
            removeESP(player)
        end
    end
end

local heartbeat = RunService.Heartbeat:Connect(function()
    if not running then return end
    refresh()
end)

-- Clean up when a player leaves.
Players.PlayerRemoving:Connect(removeESP)

-- ==================== PUBLIC TOGGLE ====================
-- Optional global so you can flip it from the console: getgenv().UniversalESP
local api = {
    Config = CONFIG,
    Toggle = function()
        CONFIG.Enabled = not CONFIG.Enabled
        return CONFIG.Enabled
    end,
    Stop = function()
        running = false
        CONFIG.Enabled = false
        if heartbeat then heartbeat:Disconnect() end
        for player in pairs(highlights) do
            removeHighlight(player)
        end
        for player in pairs(markers) do
            removeMarker(player)
        end
    end,
}

if typeof(getgenv) == "function" then
    getgenv().UniversalESP = api
end

-- ==================== CURVED DRAGGABLE UI ====================
-- A rounded on/off pill you can drag anywhere on screen. Works with both
-- mouse (PC) and touch (mobile): a tap toggles the ESP, a drag moves it.
local UserInputService = game:GetService("UserInputService")

local ON_COLOR  = Color3.fromRGB(70, 200, 120)
local OFF_COLOR = Color3.fromRGB(90, 95, 110)

local function getGuiParent()
    -- prefer a hidden container if the executor exposes one, else PlayerGui
    local ok, hui = pcall(function() return gethui() end)
    if ok and hui then return hui end
    return LocalPlayer:WaitForChild("PlayerGui")
end

local gui = Instance.new("ScreenGui")
gui.Name = "UniversalESP_UI"
gui.ResetOnSpawn = false
gui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
gui.DisplayOrder = 10000
gui.IgnoreGuiInset = true
gui.Parent = getGuiParent()

-- The draggable pill button.
local btn = Instance.new("TextButton")
btn.Name = "ESPToggle"
btn.Size = UDim2.fromOffset(150, 46)
btn.Position = UDim2.new(0, 20, 0.35, 0)
btn.AutoButtonColor = false
btn.BorderSizePixel = 0
btn.BackgroundColor3 = CONFIG.Enabled and ON_COLOR or OFF_COLOR
btn.Text = ""
btn.Font = Enum.Font.GothamBold
btn.TextColor3 = Color3.fromRGB(255, 255, 255)
btn.TextSize = 16
btn.Parent = gui

-- Fully curved corners (pill shape).
local corner = Instance.new("UICorner")
corner.CornerRadius = UDim.new(1, 0)
corner.Parent = btn

-- Soft vertical gradient for a nicer look.
local gradient = Instance.new("UIGradient")
gradient.Rotation = 90
gradient.Color = ColorSequence.new({
    ColorSequenceKeypoint.new(0, Color3.fromRGB(255, 255, 255)),
    ColorSequenceKeypoint.new(1, Color3.fromRGB(200, 200, 200)),
})
gradient.Transparency = NumberSequence.new({
    NumberSequenceKeypoint.new(0, 0.78),
    NumberSequenceKeypoint.new(1, 0.92),
})
gradient.Parent = btn

-- Subtle outline/glow.
local stroke = Instance.new("UIStroke")
stroke.Thickness = 1.5
stroke.Color = Color3.fromRGB(255, 255, 255)
stroke.Transparency = 0.6
stroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
stroke.Parent = btn

-- Status dot + label inside the pill.
local dot = Instance.new("Frame")
dot.Name = "Dot"
dot.AnchorPoint = Vector2.new(0, 0.5)
dot.Position = UDim2.new(0, 14, 0.5, 0)
dot.Size = UDim2.fromOffset(14, 14)
dot.BorderSizePixel = 0
dot.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
dot.Parent = btn
local dotCorner = Instance.new("UICorner")
dotCorner.CornerRadius = UDim.new(1, 0)
dotCorner.Parent = dot

local label = Instance.new("TextLabel")
label.Name = "Label"
label.BackgroundTransparency = 1
label.AnchorPoint = Vector2.new(0, 0.5)
label.Position = UDim2.new(0, 36, 0.5, 0)
label.Size = UDim2.new(1, -44, 1, 0)
label.Font = Enum.Font.GothamBold
label.TextSize = 15
label.TextXAlignment = Enum.TextXAlignment.Left
label.TextColor3 = Color3.fromRGB(255, 255, 255)
label.Parent = btn

local function refreshButton()
    local on = CONFIG.Enabled
    btn.BackgroundColor3 = on and ON_COLOR or OFF_COLOR
    label.Text = on and "ESP: ON" or "ESP: OFF"
    dot.BackgroundColor3 = on and Color3.fromRGB(235, 255, 240)
                              or  Color3.fromRGB(200, 205, 215)
end
refreshButton()

-- ---- drag + tap handling (mouse and touch) ----
local dragging      = false
local moved         = false
local dragStart      -- Vector2 of the pointer when the press began
local startPos       -- UDim2 of the button when the press began
local DRAG_THRESHOLD = 6  -- pixels of movement before it counts as a drag

btn.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1
        or input.UserInputType == Enum.UserInputType.Touch then
        dragging = true
        moved = false
        dragStart = input.Position
        startPos = btn.Position
    end
end)

UserInputService.InputChanged:Connect(function(input)
    if not dragging then return end
    if input.UserInputType == Enum.UserInputType.MouseMovement
        or input.UserInputType == Enum.UserInputType.Touch then
        local delta = input.Position - dragStart
        if math.abs(delta.X) > DRAG_THRESHOLD or math.abs(delta.Y) > DRAG_THRESHOLD then
            moved = true
        end
        btn.Position = UDim2.new(
            startPos.X.Scale, startPos.X.Offset + delta.X,
            startPos.Y.Scale, startPos.Y.Offset + delta.Y
        )
    end
end)

btn.InputEnded:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1
        or input.UserInputType == Enum.UserInputType.Touch then
        if dragging and not moved then
            -- treated as a tap -> toggle ESP (api.Toggle refreshes the button)
            api.Toggle()
        end
        dragging = false
    end
end)

-- Keep the button in sync if the ESP is toggled elsewhere (console/hotkey).
api.RefreshUI = refreshButton
do
    local baseToggle = api.Toggle
    api.Toggle = function()
        local state = baseToggle()
        refreshButton()
        return state
    end
end

-- Make sure the UI goes away when the ESP is stopped.
do
    local baseStop = api.Stop
    api.Stop = function()
        baseStop()
        if gui then gui:Destroy() end
    end
end

return api
