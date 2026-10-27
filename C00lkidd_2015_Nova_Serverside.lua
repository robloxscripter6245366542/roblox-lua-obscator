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

local DECAL_ID = 0 -- c00lkidd face decal (skybox, decal spam, particles, jumpscare)
local MUSIC_ID = 0 -- skeleton music
local SCREAM_ID = 0 -- c00lkidd scream (Script tab)
local THUNDER_ID = 0 -- thunder clap (Script tab)

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

-- each tab is a named page; button name = command name (fired to the server)
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
    Gravity = true, Rainbow = true, Blood = true, Flames = true,
    ["Unanchor All"] = true,
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

-- SCRIPT TAB --------------------------------------------------------
-- Classic c00lkidd flavour, built to the ENHANCED ruleset:
--   * No Crash Scripts -> no lag loops; Flames is capped, Fireworks
--                         cleans itself up, nothing spawns unbounded.
--   * No Mass Kicking  -> there is no kick/remove command here.
--   * Limited Map Edit -> Flames only ADDS reversible fire to parts and
--                         Fireworks adds one small self-cleaning part;
--                         nothing deletes or replaces the map.

-- red screen tint (whole server), fully reversible
commands["Blood"] = {
    on = function()
        local cc = Instance.new("ColorCorrectionEffect")
        cc.Name = "C00lBlood"
        cc.TintColor = Color3.fromRGB(255, 70, 70)
        cc.Saturation = 0.35
        cc.Brightness = -0.05
        cc.Parent = Lighting
    end,
    off = function()
        local cc = Lighting:FindFirstChild("C00lBlood")
        if cc then cc:Destroy() end
    end,
}

-- Flames: adds fire to map parts, CAPPED at FLAME_LIMIT (anti-crash) and
-- fully reversible (adds only; never deletes or replaces the map).
local FLAME_LIMIT = 60
commands["Flames"] = {
    on = function()
        local count = 0
        for _, part in ipairs(Workspace:GetDescendants()) do
            if count >= FLAME_LIMIT then break end
            if part:IsA("BasePart") and not Players:GetPlayerFromCharacter(part.Parent)
                and not part:FindFirstChild("C00lFlame") then
                local f = Instance.new("Fire")
                f.Name = "C00lFlame"
                f.Heat = 0 -- cosmetic only, does no damage
                f.Size = 5
                f.Parent = part
                count += 1
            end
        end
    end,
    off = function()
        for _, f in ipairs(Workspace:GetDescendants()) do
            if f.Name == "C00lFlame" then f:Destroy() end
        end
    end,
}

-- rainbow character trail (the clicker only)
commands["Trail"] = {
    on = function(player)
        local _, _, root = character(player)
        if not root then return end
        local a0 = Instance.new("Attachment")
        a0.Name = "C00lTrailA0"
        a0.Position = Vector3.new(0, 1, 0)
        a0.Parent = root
        local a1 = Instance.new("Attachment")
        a1.Name = "C00lTrailA1"
        a1.Position = Vector3.new(0, -1, 0)
        a1.Parent = root
        local trail = Instance.new("Trail")
        trail.Name = "C00lTrail"
        trail.Attachment0 = a0
        trail.Attachment1 = a1
        trail.Lifetime = 1
        trail.Color = ColorSequence.new(RED, Color3.fromRGB(255, 160, 0))
        trail.Parent = root
    end,
    off = function(player)
        local _, _, root = character(player)
        for _, n in ipairs({ "C00lTrail", "C00lTrailA0", "C00lTrailA1" }) do
            local o = root and root:FindFirstChild(n)
            if o then o:Destroy() end
        end
    end,
}

-- Freeze the clicker in place (self only; respawn clears it)
commands["Freeze"] = {
    on = function(player)
        local _, _, root = character(player)
        if root then root.Anchored = true end
    end,
    off = function(player)
        local _, _, root = character(player)
        if root then root.Anchored = false end
    end,
}

-- Unanchor All: lets map parts react to physics. CAPPED and FULLY
-- REVERSIBLE - it records each part's anchor state + position and restores
-- them on off / Clear All, so it stays a limited, non-permanent map edit
-- rather than a whole-map change (Limited Map Editing rule).
local UNANCHOR_LIMIT = 150
local unanchored = {}
commands["Unanchor All"] = {
    on = function()
        for _, part in ipairs(Workspace:GetDescendants()) do
            if #unanchored >= UNANCHOR_LIMIT then break end
            if part:IsA("BasePart") and part.Anchored
                and not Players:GetPlayerFromCharacter(part.Parent) then
                unanchored[#unanchored + 1] = { part = part, cframe = part.CFrame }
                part.Anchored = false
            end
        end
    end,
    off = function()
        for _, saved in ipairs(unanchored) do
            local part = saved.part
            if part and part.Parent then
                part.AssemblyLinearVelocity = Vector3.zero
                part.AssemblyAngularVelocity = Vector3.zero
                part.CFrame = saved.cframe
                part.Anchored = true
            end
        end
        table.clear(unanchored)
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

-- SCRIPT TAB one-shots ----------------------------------------------

-- server-wide scream (self-cleans; one Sound, not a loop)
oneShots["Scream"] = function()
    local s = Instance.new("Sound")
    s.Name = "C00lScream"
    s.SoundId = "rbxassetid://" .. SCREAM_ID
    s.Volume = 1
    s.Parent = holder
    s:Play()
    s.Ended:Connect(function() s:Destroy() end)
    task.delay(10, function() if s then s:Destroy() end end)
end

-- flash the c00lkidd face on every screen for a moment (client GUI only)
oneShots["Jumpscare"] = function()
    remote:FireAllClients("jumpscare", TEXTURE)
end

-- a couple of lightning flashes + a thunder clap, server-wide
oneShots["Thunder"] = function()
    local original = Lighting.Brightness
    task.spawn(function()
        for _ = 1, 2 do
            if not holder.Parent then return end
            Lighting.Brightness = 5
            task.wait(0.07)
            Lighting.Brightness = original
            task.wait(0.12)
        end
    end)
    local s = Instance.new("Sound")
    s.Name = "C00lThunder"
    s.SoundId = "rbxassetid://" .. THUNDER_ID
    s.Volume = 1
    s.Parent = holder
    s:Play()
    s.Ended:Connect(function() s:Destroy() end)
    task.delay(8, function() if s then s:Destroy() end end)
end

-- confetti burst on the clicker
oneShots["Confetti"] = function(player)
    local _, _, root = character(player)
    if not root then return end
    local e = Instance.new("ParticleEmitter")
    e.Name = "C00lConfetti"
    e.Texture = "rbxasset://textures/particles/sparkles_main.dds"
    e.Color = ColorSequence.new({
        ColorSequenceKeypoint.new(0, Color3.fromRGB(255, 60, 60)),
        ColorSequenceKeypoint.new(0.5, Color3.fromRGB(60, 160, 255)),
        ColorSequenceKeypoint.new(1, Color3.fromRGB(255, 220, 60)),
    })
    e.Lifetime = NumberRange.new(1.5, 2.5)
    e.Speed = NumberRange.new(16, 24)
    e.SpreadAngle = Vector2.new(180, 180)
    e.Rate = 0
    e.Parent = root
    e:Emit(90)
    task.delay(3, function() if e then e:Destroy() end end)
end

-- a firework rises from the clicker and bursts (one small self-cleaning part)
oneShots["Fireworks"] = function(player)
    local _, _, root = character(player)
    if not root then return end
    local color = Color3.fromHSV(math.random(), 1, 1)
    local p = Instance.new("Part")
    p.Name = "C00lFirework"
    p.Shape = Enum.PartType.Ball
    p.Size = Vector3.new(1, 1, 1)
    p.Color = color
    p.Material = Enum.Material.Neon
    p.CanCollide = false
    p.CFrame = root.CFrame + Vector3.new(0, 3, 0)
    p.Parent = Workspace
    local bv = Instance.new("BodyVelocity")
    bv.MaxForce = Vector3.new(0, math.huge, 0)
    bv.Velocity = Vector3.new(0, 55, 0)
    bv.Parent = p
    task.delay(0.8, function()
        if not p or not p.Parent then return end
        bv:Destroy()
        local e = Instance.new("ParticleEmitter")
        e.Texture = "rbxasset://textures/particles/sparkles_main.dds"
        e.Color = ColorSequence.new(color)
        e.Lifetime = NumberRange.new(1, 1.6)
        e.Speed = NumberRange.new(26, 34)
        e.SpreadAngle = Vector2.new(180, 180)
        e.Rate = 0
        e.Parent = p
        e:Emit(140)
        p.Transparency = 1
        task.delay(2, function() if p then p:Destroy() end end)
    end)
end

-- sit the clicker down
oneShots["Sit"] = function(player)
    local _, h = character(player)
    if h then h.Sit = true end
end

-- send the clicker back to a spawn point
oneShots["Teleport Spawn"] = function(player)
    local _, _, root = character(player)
    if not root then return end
    local dest
    for _, v in ipairs(Workspace:GetDescendants()) do
        if v:IsA("SpawnLocation") then dest = v break end
    end
    if dest then root.CFrame = dest.CFrame + Vector3.new(0, 5, 0) end
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
-- PREMIUM UI  (modern dark theme + animated tabs; server builds, clones)
-- ===================================================================

-- glassy palette (kept separate from the gameplay RED/WHITE/BLACK above)
local BG      = Color3.fromRGB(18, 18, 26)
local BG2     = Color3.fromRGB(46, 46, 64)       -- gradient highlight (top)
local SURFACE = Color3.fromRGB(38, 38, 52)       -- glass button fill
local STROKE  = Color3.fromRGB(86, 86, 112)
local EDGE    = Color3.fromRGB(255, 255, 255)    -- glass light edge
local ACCENT  = Color3.fromRGB(255, 62, 74)
local TEXT    = Color3.fromRGB(242, 242, 250)
local MUTED   = Color3.fromRGB(156, 156, 176)

local LOGO_ID = DECAL_ID -- the c00lkidd image used for the logo

local PW, PH = 344, 420

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

-- the c00lkidd logo: an image in a glass ring. Set LOGO_ID to your decal;
-- at 0 it shows a clean glass disc with an accent ring (no blocky face).
local function makeLogo(parent, px, z)
    local f = Instance.new("ImageLabel")
    f.Name = "Logo"
    f.BackgroundColor3 = Color3.fromRGB(30, 30, 42)
    f.BackgroundTransparency = 0.1
    f.BorderSizePixel = 0
    f.Size = UDim2.fromOffset(px, px)
    f.Image = "rbxassetid://" .. LOGO_ID
    f.ScaleType = Enum.ScaleType.Crop
    f.ZIndex = z or 1
    f.Parent = parent
    corner(f, math.floor(px / 2))
    local ring = stroke(f, ACCENT, math.max(1.5, px * 0.06), 0)
    ring.Name = "Ring"
    return f
end

-- client-side wiring + animation, inserted as a LocalScript into each GUI
local CLIENT_SOURCE = [[
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local remote = game:GetService("ReplicatedStorage"):WaitForChild("]] .. REMOTE_NAME .. [[")
local camera = workspace.CurrentCamera

local gui = script.Parent
local panel = gui:WaitForChild("MainPanel")
local shadow = gui:WaitForChild("Shadow")
local titleBar = panel:WaitForChild("TitleBar")
local tabBar = panel:WaitForChild("TabBar")
local indicator = tabBar:WaitForChild("Indicator")
local pagesFolder = panel:WaitForChild("Pages")
local panelScale = panel:WaitForChild("Scale")

local ACCENT     = Color3.fromRGB(255, 62, 74)
local SURFACE    = Color3.fromRGB(38, 38, 52)
local SURFACE_HI = Color3.fromRGB(56, 56, 74)
local SURFACE_ON = Color3.fromRGB(78, 30, 40)
local EDGE       = Color3.fromRGB(255, 255, 255)
local TEXT       = Color3.fromRGB(242, 242, 250)
local MUTED      = Color3.fromRGB(156, 156, 176)

local function tween(obj, t, props, style, dir)
    local info = TweenInfo.new(t, style or Enum.EasingStyle.Quint, dir or Enum.EasingDirection.Out)
    local tw = TweenService:Create(obj, info, props)
    tw:Play()
    return tw
end

-- index the pages and remember each one's resting position
local pages, base = {}, {}
for _, page in ipairs(pagesFolder:GetChildren()) do
    if page:IsA("GuiObject") then
        local idx = tonumber(page.Name:match("%d+"))
        pages[idx] = page
        base[page] = page.Position
    end
end

local activeSet = {}

local function styleButton(b, on)
    local s = b:FindFirstChild("Stroke")
    tween(b, 0.2, { BackgroundColor3 = on and SURFACE_ON or SURFACE,
        BackgroundTransparency = on and 0.1 or 0.25 })
    tween(b, 0.2, { TextColor3 = on and Color3.fromRGB(255, 255, 255) or TEXT })
    if s then
        tween(s, 0.2, { Color = on and ACCENT or EDGE,
            Thickness = on and 1.6 or 1, Transparency = on and 0 or 0.72 })
    end
end

local function hookButton(b)
    local sc = b:FindFirstChild("Scale")
    b.MouseEnter:Connect(function()
        if not activeSet[b.Name] then
            tween(b, 0.15, { BackgroundColor3 = SURFACE_HI, BackgroundTransparency = 0.12 })
        end
    end)
    b.MouseLeave:Connect(function()
        styleButton(b, activeSet[b.Name])
        if sc then tween(sc, 0.15, { Scale = 1 }) end
    end)
    b.MouseButton1Down:Connect(function()
        if sc then tween(sc, 0.08, { Scale = 0.95 }) end
    end)
    b.MouseButton1Up:Connect(function()
        if sc then tween(sc, 0.2, { Scale = 1 }, Enum.EasingStyle.Back) end
    end)
    b.MouseButton1Click:Connect(function()
        remote:FireServer(b.Name)
    end)
end

for _, page in ipairs(pagesFolder:GetChildren()) do
    for _, b in ipairs(page:GetChildren()) do
        if b:IsA("TextButton") then hookButton(b) end
    end
end

-- server tells us which commands are active -> glow those buttons
remote.OnClientEvent:Connect(function(kind, payload)
    if kind == "active" then
        activeSet = {}
        for _, name in ipairs(payload) do activeSet[name] = true end
        for _, page in ipairs(pagesFolder:GetChildren()) do
            for _, b in ipairs(page:GetChildren()) do
                if b:IsA("TextButton") then styleButton(b, activeSet[b.Name]) end
            end
        end
    elseif kind == "rainbow" then
        for _, d in ipairs(panel:GetDescendants()) do
            if d:IsA("UIStroke") then d.Color = payload end
        end
    elseif kind == "fov" then
        camera.FieldOfView = camera.FieldOfView > 70 and 70 or 120
    elseif kind == "jumpscare" then
        local js = Instance.new("ImageLabel")
        js.Name = "Jumpscare"
        js.BackgroundColor3 = Color3.new(0, 0, 0)
        js.BorderSizePixel = 0
        js.Size = UDim2.fromScale(1, 1)
        js.Image = payload
        js.ScaleType = Enum.ScaleType.Fit
        js.ZIndex = 999
        js.Parent = gui
        tween(js, 0.15, { ImageTransparency = 0 })
        task.delay(1.1, function()
            tween(js, 0.25, { ImageTransparency = 1, BackgroundTransparency = 1 })
            task.delay(0.3, function() if js then js:Destroy() end end)
        end)
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
        Position = UDim2.new(0, target.Position.X.Offset, 0, 0),
        Size = UDim2.new(0, target.AbsoluteSize.X, 1, 0),
    })

    for n, page in ipairs(pages) do
        if n == i then
            local dir = (previous ~= 0 and n < previous) and -1 or 1
            page.Visible = true
            page.Position = base[page] + UDim2.fromOffset(dir * 26, 0)
            page.GroupTransparency = 1
            tween(page, 0.3, { Position = base[page], GroupTransparency = 0 })
        elseif page.Visible then
            local dir = (n < i) and -1 or 1
            tween(page, 0.2, { Position = base[page] + UDim2.fromOffset(dir * 26, 0), GroupTransparency = 1 })
            task.delay(0.2, function() if current ~= n then page.Visible = false end end)
        end
    end
end

for n, t in ipairs(tabButtons) do
    t.MouseButton1Click:Connect(function() showTab(n) end)
end

task.defer(function()
    local first = tabButtons[1]
    indicator.Position = UDim2.new(0, first.Position.X.Offset, 0, 0)
    indicator.Size = UDim2.new(0, first.AbsoluteSize.X, 1, 0)
    showTab(1, true)
end)

-- CLOSE (reverse the entrance, then remove)
titleBar:WaitForChild("Close").MouseButton1Click:Connect(function()
    tween(panel, 0.2, { GroupTransparency = 1 })
    tween(panelScale, 0.2, { Scale = 0.9 }, Enum.EasingStyle.Quad)
    tween(shadow, 0.2, { ImageTransparency = 1 })
    task.delay(0.22, function() gui:Destroy() end)
end)

-- ENTRANCE (spring in)
panel.GroupTransparency = 1
panelScale.Scale = 0.9
shadow.ImageTransparency = 1
tween(panel, 0.32, { GroupTransparency = 0 })
tween(panelScale, 0.45, { Scale = 1 }, Enum.EasingStyle.Back)
tween(shadow, 0.4, { ImageTransparency = 0.5 })

-- DRAG (title bar) - smooth weighted follow + pick-up / settle animation
local RunService = game:GetService("RunService")
local dragging, dragStart, startPos, targetPos, moveConn

local function shadowTo(pos)
    shadow.Position = UDim2.new(pos.X.Scale, pos.X.Offset - 18, pos.Y.Scale, pos.Y.Offset - 18)
end

titleBar.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1
        or input.UserInputType == Enum.UserInputType.Touch then
        dragging = true
        dragStart = input.Position
        startPos = panel.Position
        targetPos = panel.Position
        -- pick the panel up: a small lift + a lighter shadow
        tween(panelScale, 0.18, { Scale = 1.03 }, Enum.EasingStyle.Back)
        tween(shadow, 0.18, { ImageTransparency = 0.3 })
        if moveConn then moveConn:Disconnect() end
        moveConn = RunService.RenderStepped:Connect(function(dt)
            panel.Position = panel.Position:Lerp(targetPos, math.min(dt * 16, 1))
            shadowTo(panel.Position)
            if not dragging then
                local p = panel.Position
                if math.abs(p.X.Offset - targetPos.X.Offset) < 0.5
                    and math.abs(p.Y.Offset - targetPos.Y.Offset) < 0.5 then
                    panel.Position = targetPos
                    shadowTo(targetPos)
                    moveConn:Disconnect()
                    moveConn = nil
                end
            end
        end)
        input.Changed:Connect(function()
            if input.UserInputState == Enum.UserInputState.End then
                dragging = false
                -- drop it back down
                tween(panelScale, 0.3, { Scale = 1 }, Enum.EasingStyle.Back)
                tween(shadow, 0.25, { ImageTransparency = 0.5 })
            end
        end)
    end
end)
UserInputService.InputChanged:Connect(function(input)
    if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement
        or input.UserInputType == Enum.UserInputType.Touch) then
        local delta = input.Position - dragStart
        targetPos = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X,
            startPos.Y.Scale, startPos.Y.Offset + delta.Y)
    end
end)

-- TUTORIAL (shown on first open; ? re-opens it)
local tutorial = panel:WaitForChild("Tutorial")
local gotIt = tutorial:WaitForChild("TScroll"):WaitForChild("GotIt")
local help = titleBar:WaitForChild("Help")

local function showTutorial()
    tutorial.Visible = true
    tutorial.GroupTransparency = 1
    tween(tutorial, 0.25, { GroupTransparency = 0 })
end
local function hideTutorial()
    tween(tutorial, 0.22, { GroupTransparency = 1 })
    task.delay(0.24, function() tutorial.Visible = false end)
end
gotIt.MouseButton1Click:Connect(hideTutorial)
help.MouseButton1Click:Connect(showTutorial)

-- tell the server we're ready so it can sync which buttons should be lit
remote:FireServer("__ready")
]]

local function buildGui()
    local gui = Instance.new("ScreenGui")
    gui.Name = "CoolKidGUI"
    gui.ResetOnSpawn = false
    gui.DisplayOrder = 100
    gui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling

    -- red glow + soft shadow (sibling behind the panel, follows it on drag)
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
    stroke(panel, EDGE, 1.4, 0.55).Name = "PanelStroke" -- glass light edge

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

    -- the c00lkidd logo image (glass ring; set LOGO_ID to your decal)
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
        .. "\n• <b>Tap any button</b> to toggle that effect — active ones glow red."
        .. "\n• <b>Drag the title bar</b> to move the panel around."
        .. "\n• <b>Clear All</b> turns every effect back off."
        .. "\n• Tap the <b>?</b> button any time to open this again."
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

    local client = Instance.new("LocalScript")
    client.Name = "C00lClient"
    client.Source = CLIENT_SOURCE -- requires an executor to run
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
