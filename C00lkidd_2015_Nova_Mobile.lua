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

-- each tab is a named page; button name = command name
local PAGES = {
    {
        name = "World",
        items = {
            "Message", "Music", "Skybox", "Decal Spam",
            "Disco", "Fog", "Night", "Red Sky",
            "Fullbright", "Gravity", "Rainbow", "Clear All",
        },
    },
    {
        name = "Player",
        items = {
            "Fire", "ForceField", "Infect", "Fling",
            "Sparkles", "Smoke", "Particles", "Speed",
            "High Jump", "Highlight", "Spin", "Big Head",
            "Invisible", "Fov", "Reset", "Clear All",
        },
    },
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

-- World commands affect the whole server (shared state). Body commands
-- affect ONLY the player who clicked, so their on/off state is tracked
-- per player - otherwise one player's toggle would flip another's effect.
local WORLD = {
    Skybox = true, ["Decal Spam"] = true, Music = true, Message = true,
    Disco = true, ["Red Sky"] = true, Fog = true, Night = true,
    Fullbright = true, Gravity = true, Rainbow = true,
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
        if not char:FindFirstChild("C00lInfectHighlight") then
            local hl = Instance.new("Highlight")
            hl.Name = "C00lInfectHighlight"
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
            local hl = char:FindFirstChild("C00lInfectHighlight")
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
-- MOBILE GUI  (server builds, clones to each player)
-- ===================================================================

-- client wiring + animated mobile layout, inserted as a LocalScript per player
local CLIENT_SOURCE = [[
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local remote = game:GetService("ReplicatedStorage"):WaitForChild("]] .. REMOTE_NAME .. [[")
local camera = workspace.CurrentCamera

local gui = script.Parent
local panel = gui:WaitForChild("MainPanel")
local openBtn = gui:WaitForChild("OpenButton")
local titleBar = panel:WaitForChild("TitleBar")
local tabBar = panel:WaitForChild("TabBar")
local indicator = tabBar:WaitForChild("Indicator")
local pagesFolder = panel:WaitForChild("Pages")
local panelScale = panel:WaitForChild("Scale")

local ACCENT     = Color3.fromRGB(240, 52, 62)
local SURFACE    = Color3.fromRGB(31, 31, 38)
local SURFACE_ON = Color3.fromRGB(52, 26, 30)
local STROKE     = Color3.fromRGB(54, 54, 64)
local TEXT       = Color3.fromRGB(238, 238, 245)
local MUTED      = Color3.fromRGB(150, 150, 163)

local function tween(obj, t, props, style, dir)
    local info = TweenInfo.new(t, style or Enum.EasingStyle.Quint, dir or Enum.EasingDirection.Out)
    local tw = TweenService:Create(obj, info, props)
    tw:Play()
    return tw
end

-- fit the panel to the screen (phones get a near-full-width panel)
local function fit()
    local vp = camera.ViewportSize
    local w = math.clamp(vp.X * 0.9, 250, 380)
    local h = math.clamp(vp.Y * 0.72, 320, 500)
    panel.Size = UDim2.fromOffset(w, h)
    panel.Position = UDim2.new(0.5, -w / 2, 0.5, -h / 2)
end
fit()
camera:GetPropertyChangedSignal("ViewportSize"):Connect(fit)

-- index pages + resting positions
local pages, base = {}, {}
for _, page in ipairs(pagesFolder:GetChildren()) do
    if page:IsA("GuiObject") then
        pages[tonumber(page.Name:match("%d+"))] = page
        base[page] = page.Position
    end
end

local activeSet = {}

local function styleButton(b, on)
    local s = b:FindFirstChild("Stroke")
    tween(b, 0.18, { BackgroundColor3 = on and SURFACE_ON or SURFACE })
    tween(b, 0.18, { TextColor3 = on and Color3.fromRGB(255, 255, 255) or TEXT })
    if s then
        tween(s, 0.18, { Color = on and ACCENT or STROKE, Thickness = on and 1.4 or 1 })
    end
end

local function eachButton(fn)
    for _, page in ipairs(pagesFolder:GetChildren()) do
        for _, b in ipairs(page:GetDescendants()) do
            if b:IsA("TextButton") then fn(b, page) end
        end
    end
end

-- buttons -> fire command name to server (with a touch press animation)
eachButton(function(b)
    local sc = b:FindFirstChild("Scale")
    b.MouseButton1Down:Connect(function()
        if sc then tween(sc, 0.08, { Scale = 0.95 }) end
    end)
    local function up()
        if sc then tween(sc, 0.2, { Scale = 1 }, Enum.EasingStyle.Back) end
    end
    b.MouseButton1Up:Connect(up)
    b.MouseLeave:Connect(up)
    b.MouseButton1Click:Connect(function()
        remote:FireServer(b.Name)
    end)
end)

-- server broadcasts active set -> glow those buttons
remote.OnClientEvent:Connect(function(kind, payload)
    if kind == "active" then
        activeSet = {}
        for _, name in ipairs(payload) do activeSet[name] = true end
        eachButton(function(b) styleButton(b, activeSet[b.Name]) end)
    elseif kind == "rainbow" then
        for _, d in ipairs(panel:GetDescendants()) do
            if d:IsA("UIStroke") then d.Color = payload end
        end
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
                banner.Font = Enum.Font.GothamBlack
                banner.TextScaled = true
                banner.TextColor3 = Color3.fromRGB(255, 40, 50)
                banner.TextStrokeColor3 = Color3.new(0, 0, 0)
                banner.TextStrokeTransparency = 0.3
                banner.ZIndex = 50
                banner.Parent = gui
            end
            banner.Text = payload
        elseif banner then
            banner:Destroy()
        end
    end
end)

-- TABS (sliding indicator + animated page swap)
local tabButtons = {}
for _, t in ipairs(tabBar:GetChildren()) do
    if t:IsA("TextButton") then tabButtons[tonumber(t.Name:match("%d+"))] = t end
end

local current = 0
local function showTab(i, instant)
    i = (i - 1) % #pages + 1
    if i == current then return end
    local previous = current
    current = i

    for n, t in ipairs(tabButtons) do
        tween(t, 0.2, { TextColor3 = n == i and TEXT or MUTED })
    end

    local target = tabButtons[i]
    tween(indicator, instant and 0 or 0.28, {
        Position = UDim2.new(0, target.Position.X.Offset, 1, -3),
        Size = UDim2.new(0, target.AbsoluteSize.X, 0, 3),
    })

    for n, page in ipairs(pages) do
        if n == i then
            local dir = (previous ~= 0 and n < previous) and -1 or 1
            page.Visible = true
            page.Position = base[page] + UDim2.fromOffset(dir * 28, 0)
            page.GroupTransparency = 1
            tween(page, 0.3, { Position = base[page], GroupTransparency = 0 })
        elseif page.Visible then
            local dir = (n < i) and -1 or 1
            tween(page, 0.2, { Position = base[page] + UDim2.fromOffset(dir * 28, 0), GroupTransparency = 1 })
            task.delay(0.2, function() if current ~= n then page.Visible = false end end)
        end
    end
end

for n, t in ipairs(tabButtons) do
    t.MouseButton1Click:Connect(function() showTab(n) end)
end

task.defer(function()
    local first = tabButtons[1]
    indicator.Position = UDim2.new(0, first.Position.X.Offset, 1, -3)
    indicator.Size = UDim2.new(0, first.AbsoluteSize.X, 0, 3)
    showTab(1, true)
end)

-- OPEN / CLOSE (animated)
local function openPanel()
    panel.Visible = true
    panel.GroupTransparency = 1
    panelScale.Scale = 0.9
    tween(panel, 0.3, { GroupTransparency = 0 })
    tween(panelScale, 0.42, { Scale = 1 }, Enum.EasingStyle.Back)
    tween(openBtn, 0.18, { BackgroundTransparency = 1, TextTransparency = 1 })
    task.delay(0.18, function() openBtn.Visible = false end)
end

local function closePanel()
    tween(panel, 0.2, { GroupTransparency = 1 })
    tween(panelScale, 0.2, { Scale = 0.9 }, Enum.EasingStyle.Quad)
    task.delay(0.2, function()
        panel.Visible = false
        openBtn.Visible = true
        openBtn.BackgroundTransparency = 0
        openBtn.TextTransparency = 0
        tween(openBtn, 0.2, { Size = UDim2.fromOffset(72, 36) })
    end)
end

titleBar:WaitForChild("Close").MouseButton1Click:Connect(closePanel)
openBtn.MouseButton1Click:Connect(openPanel)

-- ENTRANCE (spring in)
panel.GroupTransparency = 1
panelScale.Scale = 0.9
tween(panel, 0.34, { GroupTransparency = 0 })
tween(panelScale, 0.46, { Scale = 1 }, Enum.EasingStyle.Back)

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

-- tell the server we're ready so it can sync which buttons should be lit
remote:FireServer("__ready")
]]

-- modern palette (kept separate from the gameplay RED/WHITE/BLACK above)
local BG      = Color3.fromRGB(17, 17, 21)
local SURFACE = Color3.fromRGB(31, 31, 38)
local STROKE  = Color3.fromRGB(54, 54, 64)
local ACCENT  = Color3.fromRGB(240, 52, 62)
local TEXT    = Color3.fromRGB(238, 238, 245)
local MUTED   = Color3.fromRGB(150, 150, 163)

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

-- a modern command button (big touch target; the client wires clicks + anims)
local function makeButton(parent, name, text)
    local b = Instance.new("TextButton")
    b.Name = name
    b.AutoButtonColor = false
    b.BackgroundColor3 = SURFACE
    b.BorderSizePixel = 0
    b.Text = text
    b.Font = Enum.Font.GothamMedium
    b.TextSize = 15
    b.TextColor3 = TEXT
    b.TextWrapped = true
    b.Parent = parent
    corner(b, 9)
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
    gui.IgnoreGuiInset = true
    gui.DisplayOrder = 100
    gui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling

    -- floating OPEN pill (shown when the panel is closed)
    local openBtn = Instance.new("TextButton")
    openBtn.Name = "OpenButton"
    openBtn.AutoButtonColor = false
    openBtn.BackgroundColor3 = ACCENT
    openBtn.BorderSizePixel = 0
    openBtn.Size = UDim2.fromOffset(72, 36)
    openBtn.Position = UDim2.new(0, 14, 0, 14)
    openBtn.Text = "c00l"
    openBtn.Font = Enum.Font.GothamBold
    openBtn.TextSize = 16
    openBtn.TextColor3 = Color3.new(1, 1, 1)
    openBtn.Visible = false
    openBtn.Parent = gui
    corner(openBtn, 10)

    -- MAIN PANEL (CanvasGroup; client refits it to the screen)
    local panel = Instance.new("CanvasGroup")
    panel.Name = "MainPanel"
    panel.Size = UDim2.fromOffset(320, 440)
    panel.Position = UDim2.new(0.5, -160, 0.5, -220)
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
    titleBar.Size = UDim2.new(1, 0, 0, 50)
    titleBar.Active = true
    titleBar.Parent = panel

    local dot = Instance.new("Frame")
    dot.Name = "Dot"
    dot.BackgroundColor3 = ACCENT
    dot.BorderSizePixel = 0
    dot.Size = UDim2.fromOffset(10, 10)
    dot.Position = UDim2.fromOffset(16, 20)
    dot.Parent = titleBar
    corner(dot, 5)

    local title = Instance.new("TextLabel")
    title.Name = "Title"
    title.BackgroundTransparency = 1
    title.Position = UDim2.fromOffset(34, 8)
    title.Size = UDim2.new(1, -90, 0, 20)
    title.Font = Enum.Font.GothamBold
    title.TextSize = 18
    title.TextXAlignment = Enum.TextXAlignment.Left
    title.Text = "c00lgui"
    title.TextColor3 = TEXT
    title.Parent = titleBar

    local subtitle = Instance.new("TextLabel")
    subtitle.Name = "Subtitle"
    subtitle.BackgroundTransparency = 1
    subtitle.Position = UDim2.fromOffset(34, 28)
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
    close.Size = UDim2.fromOffset(32, 32)
    close.Position = UDim2.new(1, -44, 0, 9)
    close.Font = Enum.Font.GothamBold
    close.TextSize = 15
    close.Text = "✕"
    close.TextColor3 = MUTED
    close.Parent = titleBar
    corner(close, 9)
    stroke(close, STROKE, 1, 0)

    -- TAB BAR (named tabs + sliding indicator)
    local tabBar = Instance.new("Frame")
    tabBar.Name = "TabBar"
    tabBar.BackgroundTransparency = 1
    tabBar.Position = UDim2.fromOffset(14, 54)
    tabBar.Size = UDim2.new(1, -28, 0, 30)
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
    indicator.Size = UDim2.new(0, 72, 0, 3)
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
        t.Size = UDim2.fromOffset(80, 28)
        t.Font = Enum.Font.GothamBold
        t.TextSize = 14
        t.Text = entry.name
        t.TextColor3 = i == 1 and TEXT or MUTED
        t.Parent = tabBar
        tabX = tabX + 88
    end

    -- PAGES (one CanvasGroup per tab, each wrapping a scrolling grid)
    local pages = Instance.new("Folder")
    pages.Name = "Pages"
    pages.Parent = panel

    for i, entry in ipairs(PAGES) do
        local page = Instance.new("CanvasGroup")
        page.Name = "Page" .. i
        page.BackgroundTransparency = 1
        page.BorderSizePixel = 0
        page.Position = UDim2.fromOffset(12, 92)
        page.Size = UDim2.new(1, -24, 1, -104)
        page.Visible = i == 1
        page.Parent = pages

        local scroll = Instance.new("ScrollingFrame")
        scroll.Name = "Scroll"
        scroll.BackgroundTransparency = 1
        scroll.BorderSizePixel = 0
        scroll.Size = UDim2.new(1, 0, 1, 0)
        scroll.ScrollBarThickness = 4
        scroll.ScrollBarImageColor3 = ACCENT
        scroll.CanvasSize = UDim2.new()
        scroll.AutomaticCanvasSize = Enum.AutomaticSize.Y
        scroll.Parent = page

        local pad = Instance.new("UIPadding")
        pad.PaddingTop = UDim.new(0, 2)
        pad.PaddingBottom = UDim.new(0, 6)
        pad.Parent = scroll

        local grid = Instance.new("UIGridLayout")
        grid.CellSize = UDim2.new(0.5, -6, 0, 42)
        grid.CellPadding = UDim2.fromOffset(8, 8)
        grid.SortOrder = Enum.SortOrder.LayoutOrder
        grid.Parent = scroll

        for n, name in ipairs(entry.items) do
            makeButton(scroll, name, name).LayoutOrder = n
        end
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
