-- CLASSIC C00LKIDD 2015 c00lgui - NOVA SERVERSIDE (MOBILE)
--
-- One self-contained server script for Nova's serverside executor.
-- Same command set as the desktop build, but the GUI is rebuilt to fit
-- phone/tablet screens: a scaling panel with a scrolling button grid,
-- big touch targets, touch drag, and a floating OPEN button so it never
-- eats the whole screen.
--
-- Classic-flavor commands: Message (server-wide banner), Music, Skybox,
-- Decal Spam, Fire, ForceField, Infect, Fling, Sparkles, Smoke, Particles,
-- Disco, Fog, Night, Red Sky, Fullbright, Speed, High Jump, Highlight, Spin,
-- Big Head, Invisible, Rainbow, Gravity, Fov, Reset, Clear All.
--
-- World/visual effects (Message, Music, Skybox, Fog, Night, Red Sky, Disco,
-- Fullbright, Gravity, Decal Spam) are server-wide so everyone sees them.
-- Body effects (Fire, ForceField, Infect, Fling, Speed, etc.) apply ONLY to
-- the player who clicked - never forced onto others.
--
-- Follows the ENHANCED ruleset:
--   * No Crash Scripts  -> Decal Spam is capped (DECAL_LIMIT); Fling is a
--                          one-shot that cleans itself up; no infinite spawns
--                          or lag loops that stall clients or the server.
--   * No Mass Kicking   -> there is no kick/remove-player command at all.
--   * Limited Map Edit  -> Decal Spam only ADDS reversible decals to parts;
--                          nothing deletes or replaces the whole map.
--
-- Set your own asset IDs below before running.

local DECAL_ID = 0 -- face/logo decal (skybox, decal spam, particles)
local MUSIC_ID = 0 -- music track
local DECAL_LIMIT = 250 -- max parts decaled per run (anti-crash cap)

local Players = game:GetService("Players")
local Lighting = game:GetService("Lighting")
local SoundService = game:GetService("SoundService")
local Workspace = game:GetService("Workspace")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local RED = Color3.fromRGB(255, 0, 0)
local WHITE = Color3.new(1, 1, 1)
local BLACK = Color3.new(0, 0, 0)
local TEXTURE = "rbxassetid://" .. DECAL_ID

-- classic c00lkidd GUI message (shown server-wide by the Message button)
local MESSAGE_TEXT = "TEAM C00LKIDD JOIN TODAY!"

-- button name = command name
local BUTTONS = {
    "Message", "Music", "Skybox", "Decal Spam",
    "Fire", "ForceField", "Infect", "Fling",
    "Sparkles", "Smoke", "Particles", "Disco",
    "Fog", "Night", "Red Sky", "Fullbright",
    "Speed", "High Jump", "Highlight", "Spin",
    "Big Head", "Invisible", "Rainbow", "Gravity",
    "Fov", "Reset", "Clear All",
}

-- ===================================================================
-- CLEANUP (re-run safe)
-- ===================================================================

local HOLDER_NAME = "C00lServer"
local REMOTE_NAME = "C00lRemote"

local oldHolder = SoundService:FindFirstChild(HOLDER_NAME)
if oldHolder then oldHolder:Destroy() end
local oldRemote = ReplicatedStorage:FindFirstChild(REMOTE_NAME)
if oldRemote then oldRemote:Destroy() end

local holder = Instance.new("Folder")
holder.Name = HOLDER_NAME
holder.Parent = SoundService

local remote = Instance.new("RemoteEvent")
remote.Name = REMOTE_NAME
remote.Parent = ReplicatedStorage

-- ===================================================================
-- SAVED WORLD STATE
-- ===================================================================

local saved = {
    Ambient = Lighting.Ambient,
    OutdoorAmbient = Lighting.OutdoorAmbient,
    ClockTime = Lighting.ClockTime,
    FogEnd = Lighting.FogEnd,
    FogColor = Lighting.FogColor,
    Brightness = Lighting.Brightness,
    Gravity = Workspace.Gravity,
}

-- ===================================================================
-- SERVER HELPERS
-- ===================================================================

local function character(player)
    local char = player.Character
    return char,
        char and char:FindFirstChildOfClass("Humanoid"),
        char and char:FindFirstChild("HumanoidRootPart")
end

local function attach(player, className, name, props)
    local _, _, root = character(player)
    if not root then return end
    local existing = root:FindFirstChild(name)
    if existing then existing:Destroy() end
    local obj = Instance.new(className)
    obj.Name = name
    for k, v in pairs(props or {}) do obj[k] = v end
    obj.Parent = root
    return obj
end

local function detach(player, name)
    local _, _, root = character(player)
    local obj = root and root:FindFirstChild(name)
    if obj then obj:Destroy() end
end

local function loop(fn, delay)
    local running = true
    task.spawn(function()
        while running and holder.Parent do
            fn()
            task.wait(delay)
        end
    end)
    return function() running = false end
end

local active = {}
local stoppers = {}

-- ===================================================================
-- COMMANDS
-- ===================================================================

local commands = {}

commands["Skybox"] = {
    on = function()
        local sky = Instance.new("Sky")
        sky.Name = "C00lSky"
        for _, f in ipairs({ "Bk", "Dn", "Ft", "Lf", "Rt", "Up" }) do
            sky["Skybox" .. f] = TEXTURE
        end
        sky.Parent = Lighting
    end,
    off = function()
        local sky = Lighting:FindFirstChild("C00lSky")
        if sky then sky:Destroy() end
    end,
}

-- Decal Spam: capped at DECAL_LIMIT parts so it can't crash/stall (rule).
-- Only ADDS decals; fully reversible, never touches the whole map (rule).
commands["Decal Spam"] = {
    on = function()
        local count = 0
        for _, part in ipairs(Workspace:GetDescendants()) do
            if count >= DECAL_LIMIT then break end
            if part:IsA("BasePart") and not Players:GetPlayerFromCharacter(part.Parent) then
                local d = Instance.new("Decal")
                d.Name = "C00lDecal"
                d.Face = Enum.NormalId.Front
                d.Texture = TEXTURE
                d.Parent = part
                count += 1
            end
        end
    end,
    off = function()
        for _, d in ipairs(Workspace:GetDescendants()) do
            if d.Name == "C00lDecal" then d:Destroy() end
        end
    end,
}

commands["Music"] = {
    on = function()
        local s = Instance.new("Sound")
        s.Name = "C00lMusic"
        s.SoundId = "rbxassetid://" .. MUSIC_ID
        s.Looped = true
        s.Volume = 1
        s.Parent = holder
        s:Play()
    end,
    off = function()
        local s = holder:FindFirstChild("C00lMusic")
        if s then s:Destroy() end
    end,
}

-- classic on-screen message: the server tells every client to show/hide a
-- big red banner. No crash, no map edit, no kick - just a GUI label (rule-safe).
commands["Message"] = {
    on = function()
        remote:FireAllClients("message", MESSAGE_TEXT)
    end,
    off = function()
        remote:FireAllClients("message", false)
    end,
}

commands["Disco"] = {
    on = function()
        return loop(function()
            local c = Color3.fromHSV(math.random(), 1, 1)
            Lighting.Ambient = c
            Lighting.OutdoorAmbient = c
        end, 0.25)
    end,
    off = function()
        Lighting.Ambient = saved.Ambient
        Lighting.OutdoorAmbient = saved.OutdoorAmbient
    end,
}

commands["Red Sky"] = {
    on = function()
        Lighting.Ambient = RED
        Lighting.OutdoorAmbient = RED
    end,
    off = function()
        Lighting.Ambient = saved.Ambient
        Lighting.OutdoorAmbient = saved.OutdoorAmbient
    end,
}

commands["Fog"] = {
    on = function()
        Lighting.FogColor = BLACK
        Lighting.FogEnd = 60
    end,
    off = function()
        Lighting.FogColor = saved.FogColor
        Lighting.FogEnd = saved.FogEnd
    end,
}

commands["Night"] = {
    on = function() Lighting.ClockTime = 0 end,
    off = function() Lighting.ClockTime = saved.ClockTime end,
}

commands["Fullbright"] = {
    on = function()
        Lighting.Brightness = 3
        Lighting.ClockTime = 14
        Lighting.OutdoorAmbient = WHITE
    end,
    off = function()
        Lighting.Brightness = saved.Brightness
        Lighting.ClockTime = saved.ClockTime
        Lighting.OutdoorAmbient = saved.OutdoorAmbient
    end,
}

commands["Gravity"] = {
    on = function() Workspace.Gravity = 50 end,
    off = function() Workspace.Gravity = saved.Gravity end,
}

for name, class in pairs({ Fire = "Fire", Sparkles = "Sparkles", Smoke = "Smoke" }) do
    commands[name] = {
        on = function(player) attach(player, class, "C00l" .. class) end,
        off = function(player) detach(player, "C00l" .. class) end,
    }
end

-- ForceField on the clicker (classic; cosmetic + self-protection only)
commands["ForceField"] = {
    on = function(player)
        local char = character(player)
        if not char then return end
        local existing = char:FindFirstChild("C00lForceField")
        if existing then existing:Destroy() end
        local ff = Instance.new("ForceField")
        ff.Name = "C00lForceField"
        ff.Visible = true
        ff.Parent = char
    end,
    off = function(player)
        local char = character(player)
        local ff = char and char:FindFirstChild("C00lForceField")
        if ff then ff:Destroy() end
    end,
}

-- Infect: the clicker gets the c00lkidd look (red fill + fire). Applied to
-- the one who clicks only, never forced on other players (no griefing).
commands["Infect"] = {
    on = function(player)
        local char = character(player)
        if not char then return end
        if not char:FindFirstChild("C00lLocalHighlight") then
            local hl = Instance.new("Highlight")
            hl.Name = "C00lLocalHighlight"
            hl.FillColor = RED
            hl.FillTransparency = 0.4
            hl.OutlineColor = BLACK
            hl.Parent = char
        end
        attach(player, "Fire", "C00lInfectFire", { Size = 10, Heat = 0 })
    end,
    off = function(player)
        local char = character(player)
        if char then
            local hl = char:FindFirstChild("C00lLocalHighlight")
            if hl then hl:Destroy() end
        end
        detach(player, "C00lInfectFire")
    end,
}

commands["Particles"] = {
    on = function(player)
        attach(player, "ParticleEmitter", "C00lParticles", {
            Texture = TEXTURE, Rate = 30, Speed = NumberRange.new(10),
            SpreadAngle = Vector2.new(180, 180), Lifetime = NumberRange.new(2),
        })
    end,
    off = function(player) detach(player, "C00lParticles") end,
}

commands["Speed"] = {
    on = function(player) local _, h = character(player) if h then h.WalkSpeed = 60 end end,
    off = function(player) local _, h = character(player) if h then h.WalkSpeed = 16 end end,
}

commands["High Jump"] = {
    on = function(player)
        local _, h = character(player)
        if h then h.UseJumpPower = true h.JumpPower = 120 end
    end,
    off = function(player) local _, h = character(player) if h then h.JumpPower = 50 end end,
}

commands["Highlight"] = {
    on = function(player)
        local char = character(player)
        if not char then return end
        local hl = Instance.new("Highlight")
        hl.Name = "C00lLocalHighlight"
        hl.FillColor = RED
        hl.FillTransparency = 0.5
        hl.OutlineColor = BLACK
        hl.Parent = char
    end,
    off = function(player)
        local char = character(player)
        local hl = char and char:FindFirstChild("C00lLocalHighlight")
        if hl then hl:Destroy() end
    end,
}

commands["Spin"] = {
    on = function(player)
        attach(player, "BodyAngularVelocity", "C00lSpin", {
            AngularVelocity = Vector3.new(0, 20, 0),
            MaxTorque = Vector3.new(0, math.huge, 0),
        })
    end,
    off = function(player) detach(player, "C00lSpin") end,
}

commands["Big Head"] = {
    on = function(player)
        local char = character(player)
        local head = char and char:FindFirstChild("Head")
        if head then head.Size = head.Size * 3 end
    end,
    off = function(player)
        local char = character(player)
        local head = char and char:FindFirstChild("Head")
        if head then head.Size = head.Size / 3 end
    end,
}

commands["Invisible"] = {
    on = function(player)
        local char = character(player)
        if not char then return end
        for _, p in ipairs(char:GetDescendants()) do
            if (p:IsA("BasePart") and p.Name ~= "HumanoidRootPart") or p:IsA("Decal") then
                p.Transparency = 1
            end
        end
    end,
    off = function(player)
        local char = character(player)
        if not char then return end
        for _, p in ipairs(char:GetDescendants()) do
            if (p:IsA("BasePart") and p.Name ~= "HumanoidRootPart") or p:IsA("Decal") then
                p.Transparency = 0
            end
        end
    end,
}

commands["Rainbow"] = {
    on = function()
        return loop(function()
            remote:FireAllClients("rainbow", Color3.fromHSV(tick() % 5 / 5, 1, 1))
        end, 0.05)
    end,
    off = function()
        remote:FireAllClients("rainbow", RED)
    end,
}

-- ONE-SHOT ----------------------------------------------------------

local oneShots = {}

oneShots["Reset"] = function(player)
    local _, h = character(player)
    if h then h.Health = 0 end
end

-- gentle one-shot pop upward on the clicker (self only; cleans itself up)
oneShots["Fling"] = function(player)
    local _, _, root = character(player)
    if not root then return end
    local v = Instance.new("BodyVelocity")
    v.Name = "C00lFling"
    v.MaxForce = Vector3.new(0, math.huge, 0)
    v.Velocity = Vector3.new(0, 60, 0)
    v.Parent = root
    task.delay(0.25, function()
        if v then v:Destroy() end
    end)
end

oneShots["Fov"] = function(player)
    remote:FireClient(player, "fov")
end

-- ===================================================================
-- TOGGLE DISPATCH
-- ===================================================================

local function broadcastActive()
    local list = {}
    for name in pairs(active) do list[#list + 1] = name end
    remote:FireAllClients("active", list)
end

local function toggle(player, name)
    local cmd = commands[name]
    if not cmd then return end
    if active[name] then
        if stoppers[name] then stoppers[name]() stoppers[name] = nil end
        cmd.off(player)
        active[name] = nil
    else
        stoppers[name] = cmd.on(player)
        active[name] = true
    end
    broadcastActive()
end

oneShots["Clear All"] = function(player)
    for name in pairs(active) do
        toggle(player, name)
    end
end

remote.OnServerEvent:Connect(function(player, name)
    if type(name) ~= "string" then return end
    if oneShots[name] then
        oneShots[name](player)
    elseif commands[name] then
        toggle(player, name)
    end
end)

-- ===================================================================
-- MOBILE GUI  (server builds, clones to each player)
-- ===================================================================

-- client wiring + mobile layout, inserted as a LocalScript per player
local CLIENT_SOURCE = [[
local remote = game:GetService("ReplicatedStorage"):WaitForChild("]] .. REMOTE_NAME .. [[")
local UserInputService = game:GetService("UserInputService")
local camera = workspace.CurrentCamera
local gui = script.Parent
local panel = gui:WaitForChild("MainPanel")
local openBtn = gui:WaitForChild("OpenButton")
local scroll = panel:WaitForChild("Scroll")

local RED = Color3.fromRGB(255, 0, 0)
local WHITE = Color3.new(1, 1, 1)

-- fit the panel to the screen (phones get a near-full-width panel)
local function fit()
    local vp = camera.ViewportSize
    local w = math.clamp(vp.X * 0.9, 240, 360)
    local h = math.clamp(vp.Y * 0.7, 300, 460)
    panel.Size = UDim2.fromOffset(w, h)
    panel.Position = UDim2.new(0.5, -w / 2, 0.5, -h / 2)
end
fit()
camera:GetPropertyChangedSignal("ViewportSize"):Connect(fit)

-- buttons -> fire command name to server
for _, b in ipairs(scroll:GetChildren()) do
    if b:IsA("TextButton") then
        b.MouseButton1Click:Connect(function()
            remote:FireServer(b.Name)
        end)
    end
end

-- server broadcasts active set -> light those borders white
remote.OnClientEvent:Connect(function(kind, payload)
    if kind == "active" then
        local set = {}
        for _, name in ipairs(payload) do set[name] = true end
        for _, b in ipairs(scroll:GetChildren()) do
            if b:IsA("TextButton") then
                b.BorderColor3 = set[b.Name] and WHITE or RED
            end
        end
    elseif kind == "rainbow" then
        for _, d in ipairs(panel:GetDescendants()) do
            if d:IsA("GuiObject") then d.BorderColor3 = payload end
        end
        panel.BorderColor3 = payload
    elseif kind == "fov" then
        camera.FieldOfView = camera.FieldOfView > 70 and 70 or 120
    elseif kind == "message" then
        local banner = gui:FindFirstChild("Banner")
        if payload then
            if not banner then
                banner = Instance.new("TextLabel")
                banner.Name = "Banner"
                banner.BackgroundTransparency = 1
                banner.Size = UDim2.new(1, 0, 0, 60)
                banner.Position = UDim2.fromScale(0, 0.08)
                banner.Font = Enum.Font.SourceSansBold
                banner.TextScaled = true
                banner.TextColor3 = Color3.fromRGB(255, 0, 0)
                banner.TextStrokeTransparency = 0
                banner.ZIndex = 50
                banner.Parent = gui
            end
            banner.Text = payload
        elseif banner then
            banner:Destroy()
        end
    end
end)

-- open / close
local titleBar = panel:WaitForChild("TitleBar")
titleBar:WaitForChild("Close").MouseButton1Click:Connect(function()
    panel.Visible = false
    openBtn.Visible = true
end)
openBtn.MouseButton1Click:Connect(function()
    panel.Visible = true
    openBtn.Visible = false
end)

-- drag (title bar, touch + mouse)
local dragging, dragStart, startPos
titleBar.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1
        or input.UserInputType == Enum.UserInputType.Touch then
        dragging = true
        dragStart = input.Position
        startPos = panel.Position
        input.Changed:Connect(function()
            if input.UserInputState == Enum.UserInputState.End then dragging = false end
        end)
    end
end)
UserInputService.InputChanged:Connect(function(input)
    if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement
        or input.UserInputType == Enum.UserInputType.Touch) then
        local delta = input.Position - dragStart
        panel.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X,
            startPos.Y.Scale, startPos.Y.Offset + delta.Y)
    end
end)
]]

local function classic(obj)
    obj.BackgroundColor3 = BLACK
    obj.BorderColor3 = RED
    obj.BorderSizePixel = 1
    return obj
end

local function buildGui()
    local gui = Instance.new("ScreenGui")
    gui.Name = "CoolKidGUI"
    gui.ResetOnSpawn = false
    gui.IgnoreGuiInset = true
    gui.DisplayOrder = 100

    -- floating OPEN button (shown when the panel is closed)
    local openBtn = classic(Instance.new("TextButton"))
    openBtn.Name = "OpenButton"
    openBtn.Size = UDim2.fromOffset(70, 34)
    openBtn.Position = UDim2.new(0, 10, 0, 10)
    openBtn.Text = "c00l"
    openBtn.Font = Enum.Font.SourceSansBold
    openBtn.TextSize = 20
    openBtn.TextColor3 = RED
    openBtn.Visible = false
    openBtn.Parent = gui

    -- MAIN PANEL (sized by the client to fit the screen)
    local panel = classic(Instance.new("Frame"))
    panel.Name = "MainPanel"
    panel.Size = UDim2.fromOffset(320, 420)
    panel.Position = UDim2.new(0.5, -160, 0.5, -210)
    panel.BorderSizePixel = 3
    panel.Active = true
    panel.Parent = gui

    -- TITLE BAR
    local titleBar = classic(Instance.new("Frame"))
    titleBar.Name = "TitleBar"
    titleBar.Size = UDim2.new(1, 0, 0, 40)
    titleBar.Active = true
    titleBar.Parent = panel

    local title = Instance.new("TextLabel")
    title.Name = "Title"
    title.BackgroundTransparency = 1
    title.Size = UDim2.new(1, -44, 1, 0)
    title.Position = UDim2.fromOffset(8, 0)
    title.Font = Enum.Font.SourceSansBold
    title.TextSize = 24
    title.TextXAlignment = Enum.TextXAlignment.Left
    title.Text = "c00lgui"
    title.TextColor3 = RED
    title.TextStrokeTransparency = 0.5
    title.Parent = titleBar

    local close = classic(Instance.new("TextButton"))
    close.Name = "Close"
    close.Size = UDim2.fromOffset(40, 40)
    close.Position = UDim2.new(1, -40, 0, 0)
    close.Text = "X"
    close.Font = Enum.Font.SourceSansBold
    close.TextSize = 24
    close.TextColor3 = RED
    close.Parent = titleBar

    -- SUBTITLE
    local subtitle = Instance.new("TextLabel")
    subtitle.Name = "Subtitle"
    subtitle.BackgroundTransparency = 1
    subtitle.Size = UDim2.new(1, 0, 0, 20)
    subtitle.Position = UDim2.fromOffset(0, 42)
    subtitle.Font = Enum.Font.SourceSans
    subtitle.TextSize = 16
    subtitle.Text = "Team C00lkidd join today!"
    subtitle.TextColor3 = WHITE
    subtitle.TextStrokeTransparency = 0.5
    subtitle.Parent = panel

    -- SCROLLING BUTTON GRID (mobile: 2 columns, big targets, scrolls)
    local scroll = Instance.new("ScrollingFrame")
    scroll.Name = "Scroll"
    scroll.BackgroundTransparency = 1
    scroll.BorderSizePixel = 0
    scroll.Position = UDim2.fromOffset(8, 66)
    scroll.Size = UDim2.new(1, -16, 1, -74)
    scroll.ScrollBarThickness = 6
    scroll.ScrollBarImageColor3 = RED
    scroll.CanvasSize = UDim2.new()
    scroll.AutomaticCanvasSize = Enum.AutomaticSize.Y
    scroll.Parent = panel

    local grid = Instance.new("UIGridLayout")
    grid.CellSize = UDim2.new(0.5, -6, 0, 42)
    grid.CellPadding = UDim2.fromOffset(8, 8)
    grid.SortOrder = Enum.SortOrder.LayoutOrder
    grid.Parent = scroll

    for i, name in ipairs(BUTTONS) do
        local b = classic(Instance.new("TextButton"))
        b.Name = name
        b.LayoutOrder = i
        b.AutoButtonColor = true
        b.Font = Enum.Font.SourceSans
        b.TextSize = 18
        b.TextWrapped = true
        b.Text = name
        b.TextColor3 = WHITE
        b.TextStrokeTransparency = 0.5
        b.Parent = scroll
    end

    local client = Instance.new("LocalScript")
    client.Name = "C00lClient"
    client.Source = CLIENT_SOURCE -- requires an executor to run
    client.Parent = gui

    return gui
end

local function giveGui(player)
    local playerGui = player:FindFirstChildOfClass("PlayerGui")
        or player:WaitForChild("PlayerGui")

    local existing = playerGui:FindFirstChild("CoolKidGUI")
    if existing then existing:Destroy() end

    local gui = buildGui()
    gui.Parent = playerGui

    local function onCharacter(character)
        local old = character:FindFirstChild("CoolKidHighlight")
        if old then old:Destroy() end
        local highlight = Instance.new("Highlight")
        highlight.Name = "CoolKidHighlight"
        highlight.FillColor = RED
        highlight.FillTransparency = 0.6
        highlight.OutlineColor = BLACK
        highlight.Parent = character
    end
    player.CharacterAdded:Connect(onCharacter)
    if player.Character then onCharacter(player.Character) end
end

for _, player in ipairs(Players:GetPlayers()) do
    task.spawn(giveGui, player)
end

Players.PlayerAdded:Connect(giveGui)
