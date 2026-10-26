-- CLASSIC C00LKIDD 2015 c00lgui - NOVA SERVERSIDE
--
-- One self-contained server script. Paste it into Nova's serverside
-- executor and run. Nova runs this on the SERVER, so:
--   * the GUI is built here and cloned to every player (and late joiners)
--   * a RemoteEvent carries button clicks from each client to the server
--   * a LocalScript is inserted into each player's GUI to wire the buttons
--     (a server CAN parent a LocalScript into PlayerGui; it runs on the client)
--   * world + music effects run on the server so the whole server sees them
--   * character effects apply to whoever clicked
--
-- Nova rules this follows:
--   * everything lives under one script, no client-side injection needed
--   * remotes/instances are named generically and cleaned up on re-run
--   * no auto-executing loadstrings from unknown URLs; all code is inline
--   * set the asset IDs below to your own uploads before running

local DECAL_ID = 0 -- c00lkidd face decal (skybox, decal spam, particles)
local MUSIC_ID = 0 -- skeleton music

local Players = game:GetService("Players")
local Lighting = game:GetService("Lighting")
local SoundService = game:GetService("SoundService")
local Workspace = game:GetService("Workspace")

local RED = Color3.fromRGB(255, 0, 0)
local WHITE = Color3.new(1, 1, 1)
local BLACK = Color3.new(0, 0, 0)
local TEXTURE = "rbxassetid://" .. DECAL_ID

local PANEL_W, PANEL_H = 300, 345
local BTN_W, BTN_H = 135, 30

-- button name = command name (the client fires this string to the server)
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

-- ===================================================================
-- CLEANUP (re-run safe)
-- ===================================================================

local HOLDER_NAME = "C00lServer"
local REMOTE_NAME = "C00lRemote"

local oldHolder = SoundService:FindFirstChild(HOLDER_NAME)
if oldHolder then
    oldHolder:Destroy()
end

local oldRemote = game:GetService("ReplicatedStorage"):FindFirstChild(REMOTE_NAME)
if oldRemote then
    oldRemote:Destroy()
end

local holder = Instance.new("Folder")
holder.Name = HOLDER_NAME
holder.Parent = SoundService

local remote = Instance.new("RemoteEvent")
remote.Name = REMOTE_NAME
remote.Parent = game:GetService("ReplicatedStorage")

-- ===================================================================
-- SAVED WORLD STATE (restored by Clear All)
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
-- SERVER-SIDE HELPERS
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

-- a loop that stops when `holder` is gone (i.e. on re-run)
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

-- World commands affect the whole server (shared state). Body commands
-- affect ONLY the player who clicked, so their on/off state is tracked
-- per player - otherwise one player's toggle would flip another's effect.
local WORLD = {
    Skybox = true, ["Decal Spam"] = true, Music = true, Disco = true,
    ["Red Sky"] = true, Fog = true, Night = true, Fullbright = true,
    Gravity = true, Rainbow = true,
}

local worldActive = {}
local worldStoppers = {}

-- bodyState[player] = { active = {name=true}, stoppers = {name=fn} }
local bodyState = {}
local function stateFor(player)
    local s = bodyState[player]
    if not s then
        s = { active = {}, stoppers = {} }
        bodyState[player] = s
    end
    return s
end

-- ===================================================================
-- COMMANDS (run on the server; world ones are shared, body ones per player)
-- ===================================================================

local commands = {}

-- WORLD -------------------------------------------------------------

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

commands["Decal Spam"] = {
    on = function()
        for _, part in ipairs(Workspace:GetDescendants()) do
            if part:IsA("BasePart") and not Players:GetPlayerFromCharacter(part.Parent) then
                for _, face in ipairs(Enum.NormalId:GetEnumItems()) do
                    local d = Instance.new("Decal")
                    d.Name = "C00lDecal"
                    d.Face = face
                    d.Texture = TEXTURE
                    d.Parent = part
                end
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

-- PER-PLAYER BODY ---------------------------------------------------
-- these take the clicking player; state is still shared-toggle so the
-- button lights up, but the effect is applied to the one who clicked.

for name, class in pairs({ Fire = "Fire", Sparkles = "Sparkles", Smoke = "Smoke" }) do
    commands[name] = {
        on = function(player) attach(player, class, "C00l" .. class) end,
        off = function(player) detach(player, "C00l" .. class) end,
    }
end

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
            if p:IsA("BasePart") and p.Name ~= "HumanoidRootPart" then
                p.Transparency = 1
            elseif p:IsA("Decal") then
                p.Transparency = 1
            end
        end
    end,
    off = function(player)
        local char = character(player)
        if not char then return end
        for _, p in ipairs(char:GetDescendants()) do
            if p:IsA("BasePart") and p.Name ~= "HumanoidRootPart" then
                p.Transparency = 0
            elseif p:IsA("Decal") then
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

oneShots["Fov"] = function(player)
    -- camera is client-only; tell that client to toggle fov
    remote:FireClient(player, "fov")
end

-- ===================================================================
-- TOGGLE DISPATCH
-- ===================================================================

-- a player's lit buttons = all active world commands + their own body ones
local function activeListFor(player)
    local list = {}
    for name in pairs(worldActive) do list[#list + 1] = name end
    local s = bodyState[player]
    if s then
        for name in pairs(s.active) do list[#list + 1] = name end
    end
    return list
end

local function sendActive(player)
    remote:FireClient(player, "active", activeListFor(player))
end

local function sendActiveAll()
    for _, p in ipairs(Players:GetPlayers()) do
        sendActive(p)
    end
end

local function toggleWorld(player, name)
    local cmd = commands[name]
    if worldActive[name] then
        if worldStoppers[name] then worldStoppers[name]() worldStoppers[name] = nil end
        cmd.off(player)
        worldActive[name] = nil
    else
        worldStoppers[name] = cmd.on(player)
        worldActive[name] = true
    end
    sendActiveAll() -- world change relights every player's buttons
end

local function toggleBody(player, name)
    local cmd = commands[name]
    local s = stateFor(player)
    if s.active[name] then
        if s.stoppers[name] then s.stoppers[name]() s.stoppers[name] = nil end
        cmd.off(player)
        s.active[name] = nil
    else
        s.stoppers[name] = cmd.on(player)
        s.active[name] = true
    end
    sendActive(player)
end

local function toggle(player, name)
    if not commands[name] then return end
    if WORLD[name] then
        toggleWorld(player, name)
    else
        toggleBody(player, name)
    end
end

oneShots["Clear All"] = function(player)
    -- turn off every world effect (affects everyone)
    for name in pairs(worldActive) do
        if worldStoppers[name] then worldStoppers[name]() worldStoppers[name] = nil end
        commands[name].off(player)
        worldActive[name] = nil
    end
    -- turn off this player's own body effects
    local s = bodyState[player]
    if s then
        for name in pairs(s.active) do
            if s.stoppers[name] then s.stoppers[name]() s.stoppers[name] = nil end
            commands[name].off(player)
            s.active[name] = nil
        end
    end
    sendActiveAll()
end

-- clear a player's body effects (used on respawn; effects are already gone)
local function clearBody(player)
    local s = bodyState[player]
    if not s then return end
    for name in pairs(s.active) do
        if s.stoppers[name] then s.stoppers[name]() s.stoppers[name] = nil end
        s.active[name] = nil
    end
end

remote.OnServerEvent:Connect(function(player, name)
    if type(name) ~= "string" then return end
    if name == "__ready" then
        sendActive(player) -- client just loaded; sync its button lights
    elseif oneShots[name] then
        oneShots[name](player)
    elseif commands[name] then
        toggle(player, name)
    end
end)

Players.PlayerRemoving:Connect(function(player)
    local s = bodyState[player]
    if s then
        for _, stop in pairs(s.stoppers) do stop() end
        bodyState[player] = nil
    end
end)

-- ===================================================================
-- GUI BUILDER (server builds, clones to each player)
-- ===================================================================

local function classic(obj)
    obj.BackgroundColor3 = BLACK
    obj.BorderColor3 = RED
    obj.BorderSizePixel = 1
    return obj
end

local function label(parent, text, pos, size, font, textSize, color, name)
    local l = Instance.new("TextLabel")
    l.Name = name or "Label"
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

-- client-side wiring, inserted as a LocalScript into each player's GUI
local CLIENT_SOURCE = [[
local remote = game:GetService("ReplicatedStorage"):WaitForChild("]] .. REMOTE_NAME .. [[")
local UserInputService = game:GetService("UserInputService")
local camera = workspace.CurrentCamera
local gui = script.Parent
local panel = gui:WaitForChild("MainPanel")
local pages = panel:WaitForChild("Pages")

local RED = Color3.fromRGB(255, 0, 0)
local WHITE = Color3.new(1, 1, 1)

-- buttons -> fire the command name to the server
for _, page in ipairs(pages:GetChildren()) do
    for _, b in ipairs(page:GetChildren()) do
        if b:IsA("TextButton") then
            b.MouseButton1Click:Connect(function()
                remote:FireServer(b.Name)
            end)
        end
    end
end

-- server tells us which commands are active -> light those borders white
remote.OnClientEvent:Connect(function(kind, payload)
    if kind == "active" then
        local set = {}
        for _, name in ipairs(payload) do set[name] = true end
        for _, page in ipairs(pages:GetChildren()) do
            for _, b in ipairs(page:GetChildren()) do
                if b:IsA("TextButton") and b.Name ~= "Prev" and b.Name ~= "Next" then
                    b.BorderColor3 = set[b.Name] and WHITE or RED
                end
            end
        end
    elseif kind == "rainbow" then
        for _, d in ipairs(panel:GetDescendants()) do
            if d:IsA("GuiObject") then d.BorderColor3 = payload end
        end
        panel.BorderColor3 = payload
    elseif kind == "fov" then
        camera.FieldOfView = camera.FieldOfView > 70 and 70 or 120
    end
end)

-- paging
local pageList = {}
for _, page in ipairs(pages:GetChildren()) do
    pageList[tonumber(page.Name:match("%d+"))] = page
end
local current = 1
local pageNumber = panel:WaitForChild("PageNumber")
local function showPage(i)
    current = (i - 1) % #pageList + 1
    for n, page in ipairs(pageList) do page.Visible = n == current end
    pageNumber.Text = current .. "/" .. #pageList
end
panel:WaitForChild("Prev").MouseButton1Click:Connect(function() showPage(current - 1) end)
panel:WaitForChild("Next").MouseButton1Click:Connect(function() showPage(current + 1) end)

-- close
local titleBar = panel:WaitForChild("TitleBar")
titleBar:WaitForChild("Close").MouseButton1Click:Connect(function() gui:Destroy() end)

-- drag (mouse + touch)
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

-- tell the server we're ready so it can sync which buttons should be lit
remote:FireServer("__ready")
]]

local function buildGui()
    local gui = Instance.new("ScreenGui")
    gui.Name = "CoolKidGUI"
    gui.ResetOnSpawn = false
    gui.DisplayOrder = 100

    local panel = classic(Instance.new("Frame"))
    panel.Name = "MainPanel"
    panel.Size = UDim2.fromOffset(PANEL_W, PANEL_H)
    panel.Position = UDim2.new(0.5, -PANEL_W / 2, 0.5, -PANEL_H / 2)
    panel.BorderSizePixel = 3
    panel.Active = true
    panel.Parent = gui

    local titleBar = classic(Instance.new("Frame"))
    titleBar.Name = "TitleBar"
    titleBar.Size = UDim2.new(1, 0, 0, 30)
    titleBar.Active = true
    titleBar.Parent = panel

    label(titleBar, "c00lgui", UDim2.fromOffset(0, 0), UDim2.new(1, 0, 1, 0),
        Enum.Font.SourceSansBold, 26, RED, "Title")

    local close = button(titleBar, "Close", "X", UDim2.new(1, -30, 0, 0), UDim2.fromOffset(30, 30))
    close.Font = Enum.Font.SourceSansBold
    close.TextColor3 = RED
    close.TextSize = 22

    label(panel, "Team C00lkidd join today!", UDim2.fromOffset(0, 32),
        UDim2.new(1, 0, 0, 20), Enum.Font.SourceSans, 16, WHITE, "Subtitle")

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

    local y = PANEL_H - 40
    button(panel, "Prev", "<", UDim2.fromOffset(10, y), UDim2.fromOffset(40, 30)).Font =
        Enum.Font.SourceSansBold
    button(panel, "Next", ">", UDim2.fromOffset(PANEL_W - 50, y), UDim2.fromOffset(40, 30)).Font =
        Enum.Font.SourceSansBold
    label(panel, "1/" .. #PAGES, UDim2.fromOffset(60, y), UDim2.new(1, -120, 0, 30),
        Enum.Font.SourceSansBold, 22, RED, "PageNumber")

    local client = Instance.new("LocalScript")
    client.Name = "C00lClient"
    client.Source = CLIENT_SOURCE -- requires an executor; Studio uses a fallback below
    client.Parent = gui

    return gui
end

-- In a normal server (no exploit), LocalScript.Source can't be set and the
-- client wiring won't run. Nova's serverside CAN set Source. If Source failed
-- to stick, we still ship the GUI; buttons just won't be wired.
local function giveGui(player)
    local playerGui = player:FindFirstChildOfClass("PlayerGui")
        or player:WaitForChild("PlayerGui")

    local existing = playerGui:FindFirstChild("CoolKidGUI")
    if existing then existing:Destroy() end

    local gui = buildGui()
    gui.Parent = playerGui

    -- server-side red highlight on their character, like the classic GUI
    local function onCharacter(character)
        -- a respawn wipes the old character's body effects; clear their state
        -- so buttons reflect reality instead of staying stuck "on"
        clearBody(player)
        sendActive(player)

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
