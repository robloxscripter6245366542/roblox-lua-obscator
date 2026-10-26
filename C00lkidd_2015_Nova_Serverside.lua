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
-- PREMIUM UI  (modern dark theme + animated tabs; server builds, clones)
-- ===================================================================

-- modern palette (kept separate from the gameplay RED/WHITE/BLACK above)
local BG      = Color3.fromRGB(17, 17, 21)
local SURFACE = Color3.fromRGB(31, 31, 38)
local STROKE  = Color3.fromRGB(54, 54, 64)
local ACCENT  = Color3.fromRGB(240, 52, 62)
local TEXT    = Color3.fromRGB(238, 238, 245)
local MUTED   = Color3.fromRGB(150, 150, 163)

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

local ACCENT     = Color3.fromRGB(240, 52, 62)
local SURFACE    = Color3.fromRGB(31, 31, 38)
local SURFACE_HI = Color3.fromRGB(44, 44, 53)
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
    tween(b, 0.18, { BackgroundColor3 = on and SURFACE_ON or SURFACE })
    tween(b, 0.18, { TextColor3 = on and Color3.fromRGB(255, 255, 255) or TEXT })
    if s then
        tween(s, 0.18, { Color = on and ACCENT or STROKE, Thickness = on and 1.4 or 1 })
    end
end

local function hookButton(b)
    local sc = b:FindFirstChild("Scale")
    b.MouseEnter:Connect(function()
        if not activeSet[b.Name] then tween(b, 0.15, { BackgroundColor3 = SURFACE_HI }) end
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
    indicator.Position = UDim2.new(0, first.Position.X.Offset, 1, -3)
    indicator.Size = UDim2.new(0, first.AbsoluteSize.X, 0, 3)
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

-- DRAG (title bar; shadow follows)
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
        shadow.Position = UDim2.new(panel.Position.X.Scale, panel.Position.X.Offset - 18,
            panel.Position.Y.Scale, panel.Position.Y.Offset - 18)
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
