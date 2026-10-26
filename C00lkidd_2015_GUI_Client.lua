-- c00lgui client (LocalScript in StarterPlayer > StarterPlayerScripts)
--
-- Wires up the CoolKidGUI built by C00lkidd_2015_GUI.lua. Every effect is
-- local to the player who clicks it. Set the asset IDs below to your own
-- uploads (0 = that button still toggles but shows nothing).

local DECAL_ID = 0 -- c00lkidd face decal (skybox, decal spam, particles)
local MUSIC_ID = 0 -- skeleton music

local Players = game:GetService("Players")
local Lighting = game:GetService("Lighting")
local SoundService = game:GetService("SoundService")
local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")

local player = Players.LocalPlayer
local camera = workspace.CurrentCamera
local gui = player:WaitForChild("PlayerGui"):WaitForChild("CoolKidGUI")
local panel = gui:WaitForChild("MainPanel")
local shadow = gui:WaitForChild("Shadow")
local titleBar = panel:WaitForChild("TitleBar")
local tabBar = panel:WaitForChild("TabBar")
local indicator = tabBar:WaitForChild("Indicator")
local pages = panel:WaitForChild("Pages")
local panelScale = panel:WaitForChild("Scale")

local RED = Color3.fromRGB(255, 0, 0)
local TEXTURE = "rbxassetid://" .. DECAL_ID
local FACES = Enum.NormalId:GetEnumItems()

-- modern UI palette + animation helper
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

local saved = {
    Ambient = Lighting.Ambient,
    OutdoorAmbient = Lighting.OutdoorAmbient,
    ClockTime = Lighting.ClockTime,
    FogEnd = Lighting.FogEnd,
    FogColor = Lighting.FogColor,
    Brightness = Lighting.Brightness,
    Gravity = workspace.Gravity,
    Fov = camera.FieldOfView,
}

local function character()
    local char = player.Character
    return char, char and char:FindFirstChildOfClass("Humanoid"),
        char and char:FindFirstChild("HumanoidRootPart")
end

local function attach(className, name, props)
    local _, _, root = character()
    if not root then return end
    local obj = Instance.new(className)
    obj.Name = name
    for k, v in pairs(props or {}) do obj[k] = v end
    obj.Parent = root
end

local function detach(name)
    local _, _, root = character()
    local obj = root and root:FindFirstChild(name)
    if obj then obj:Destroy() end
end

local function loop(fn, delay)
    local running = true
    task.spawn(function()
        while running do
            fn()
            task.wait(delay)
        end
    end)
    return function() running = false end
end

-- each action: on() returns optional cleanup, off() undoes it
local stoppers = {}
-- toggled-on buttons show white borders, like the original
local active = {}
local actions = {}

actions["Skybox"] = {
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

actions["Decal Spam"] = {
    on = function()
        for _, part in ipairs(workspace:GetDescendants()) do
            if part:IsA("BasePart") and not Players:GetPlayerFromCharacter(part.Parent) then
                for _, face in ipairs(FACES) do
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
        for _, d in ipairs(workspace:GetDescendants()) do
            if d.Name == "C00lDecal" then d:Destroy() end
        end
    end,
}

actions["Music"] = {
    on = function()
        local s = Instance.new("Sound")
        s.Name = "C00lMusic"
        s.SoundId = "rbxassetid://" .. MUSIC_ID
        s.Looped = true
        s.Volume = 1
        s.Parent = SoundService
        s:Play()
    end,
    off = function()
        local s = SoundService:FindFirstChild("C00lMusic")
        if s then s:Destroy() end
    end,
}

actions["Disco"] = {
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

actions["Red Sky"] = {
    on = function()
        Lighting.Ambient = RED
        Lighting.OutdoorAmbient = RED
    end,
    off = function()
        Lighting.Ambient = saved.Ambient
        Lighting.OutdoorAmbient = saved.OutdoorAmbient
    end,
}

actions["Fog"] = {
    on = function()
        Lighting.FogColor = Color3.new(0, 0, 0)
        Lighting.FogEnd = 60
    end,
    off = function()
        Lighting.FogColor = saved.FogColor
        Lighting.FogEnd = saved.FogEnd
    end,
}

actions["Night"] = {
    on = function() Lighting.ClockTime = 0 end,
    off = function() Lighting.ClockTime = saved.ClockTime end,
}

actions["Fullbright"] = {
    on = function()
        Lighting.Brightness = 3
        Lighting.ClockTime = 14
        Lighting.OutdoorAmbient = Color3.new(1, 1, 1)
    end,
    off = function()
        Lighting.Brightness = saved.Brightness
        Lighting.ClockTime = saved.ClockTime
        Lighting.OutdoorAmbient = saved.OutdoorAmbient
    end,
}

for name, class in pairs({ Fire = "Fire", Sparkles = "Sparkles", Smoke = "Smoke" }) do
    actions[name] = {
        on = function() attach(class, "C00l" .. class) end,
        off = function() detach("C00l" .. class) end,
    }
end

actions["Particles"] = {
    on = function()
        attach("ParticleEmitter", "C00lParticles", {
            Texture = TEXTURE, Rate = 30, Speed = NumberRange.new(10),
            SpreadAngle = Vector2.new(180, 180), Lifetime = NumberRange.new(2),
        })
    end,
    off = function() detach("C00lParticles") end,
}

actions["Speed"] = {
    on = function() local _, h = character() if h then h.WalkSpeed = 60 end end,
    off = function() local _, h = character() if h then h.WalkSpeed = 16 end end,
}

actions["High Jump"] = {
    on = function()
        local _, h = character()
        if h then h.UseJumpPower = true h.JumpPower = 120 end
    end,
    off = function() local _, h = character() if h then h.JumpPower = 50 end end,
}

actions["Highlight"] = {
    on = function()
        local char = character()
        if not char then return end
        local hl = Instance.new("Highlight")
        hl.Name = "C00lLocalHighlight"
        hl.FillColor = RED
        hl.OutlineColor = Color3.new(0, 0, 0)
        hl.Parent = char
    end,
    off = function()
        local char = character()
        local hl = char and char:FindFirstChild("C00lLocalHighlight")
        if hl then hl:Destroy() end
    end,
}

actions["Spin"] = {
    on = function()
        attach("BodyAngularVelocity", "C00lSpin", {
            AngularVelocity = Vector3.new(0, 20, 0),
            MaxTorque = Vector3.new(0, math.huge, 0),
        })
    end,
    off = function() detach("C00lSpin") end,
}

actions["Big Head"] = {
    on = function()
        local char = character()
        local head = char and char:FindFirstChild("Head")
        if head then head.Size = head.Size * 3 end
    end,
    off = function()
        local char = character()
        local head = char and char:FindFirstChild("Head")
        if head then head.Size = head.Size / 3 end
    end,
}

local function setVisible(transparency)
    local char = character()
    if not char then return end
    for _, p in ipairs(char:GetDescendants()) do
        if (p:IsA("BasePart") and p.Name ~= "HumanoidRootPart") or p:IsA("Decal") then
            p.LocalTransparencyModifier = transparency
        end
    end
end

actions["Invisible"] = {
    on = function()
        return loop(function() setVisible(0.8) end, 0.1)
    end,
    off = function() setVisible(0) end,
}

actions["Rainbow"] = {
    on = function()
        return loop(function()
            local c = Color3.fromHSV(tick() % 5 / 5, 1, 1)
            for _, s in ipairs(panel:GetDescendants()) do
                if s:IsA("UIStroke") then s.Color = c end
            end
        end, 0.05)
    end,
    off = function()
        -- restore each button's resting stroke (active = accent, rest = grey)
        for _, page in ipairs(pages:GetChildren()) do
            for _, b in ipairs(page:GetChildren()) do
                local s = b:IsA("TextButton") and b:FindFirstChild("Stroke")
                if s then s.Color = active[b.Name] and ACCENT or STROKE end
            end
        end
        local panelStroke = panel:FindFirstChild("PanelStroke")
        if panelStroke then panelStroke.Color = STROKE end
    end,
}

actions["Gravity"] = {
    on = function() workspace.Gravity = 50 end,
    off = function() workspace.Gravity = saved.Gravity end,
}

actions["Fov"] = {
    on = function() camera.FieldOfView = 120 end,
    off = function() camera.FieldOfView = saved.Fov end,
}

-- one-shot buttons
local oneShots = {}

oneShots["Reset"] = function()
    local _, h = character()
    if h then h.Health = 0 end
end


-- animate a single button to its on/off look
local function styleButton(b, on)
    local s = b:FindFirstChild("Stroke")
    tween(b, 0.18, { BackgroundColor3 = on and SURFACE_ON or SURFACE })
    tween(b, 0.18, { TextColor3 = on and Color3.fromRGB(255, 255, 255) or TEXT })
    if s then
        tween(s, 0.18, { Color = on and ACCENT or STROKE, Thickness = on and 1.4 or 1 })
    end
end

local function setActive(button, on)
    active[button.Name] = on or nil
    for _, page in ipairs(pages:GetChildren()) do
        local b = page:FindFirstChild(button.Name)
        if b then styleButton(b, on) end
    end
end

local function toggle(button)
    local name = button.Name
    local action = actions[name]
    if not action then return end

    if active[name] then
        if stoppers[name] then stoppers[name]() stoppers[name] = nil end
        action.off()
        setActive(button, false)
    else
        stoppers[name] = action.on()
        setActive(button, true)
    end
end

oneShots["Clear All"] = function()
    for name in pairs(active) do
        for _, page in ipairs(pages:GetChildren()) do
            local b = page:FindFirstChild(name)
            if b then toggle(b) break end
        end
    end
end

-- character-bound effects are gone after respawn, so drop their state
local CHARACTER_BOUND = {
    Fire = true, Sparkles = true, Smoke = true, Particles = true, Speed = true,
    ["High Jump"] = true, Highlight = true, Spin = true, ["Big Head"] = true,
}

player.CharacterAdded:Connect(function()
    for name in pairs(CHARACTER_BOUND) do
        if active[name] then
            for _, page in ipairs(pages:GetChildren()) do
                local b = page:FindFirstChild(name)
                if b then setActive(b, false) end
            end
        end
    end
    if active.Invisible then
        stoppers.Invisible()
        stoppers.Invisible = actions.Invisible.on()
    end
end)

for _, page in ipairs(pages:GetChildren()) do
    for _, b in ipairs(page:GetChildren()) do
        if b:IsA("TextButton") then
            local sc = b:FindFirstChild("Scale")
            b.MouseEnter:Connect(function()
                if not active[b.Name] then tween(b, 0.15, { BackgroundColor3 = SURFACE_HI }) end
            end)
            b.MouseLeave:Connect(function()
                styleButton(b, active[b.Name])
                if sc then tween(sc, 0.15, { Scale = 1 }) end
            end)
            b.MouseButton1Down:Connect(function()
                if sc then tween(sc, 0.08, { Scale = 0.95 }) end
            end)
            b.MouseButton1Up:Connect(function()
                if sc then tween(sc, 0.2, { Scale = 1 }, Enum.EasingStyle.Back) end
            end)
            b.MouseButton1Click:Connect(function()
                if oneShots[b.Name] then
                    oneShots[b.Name]()
                else
                    toggle(b)
                end
            end)
        end
    end
end

-- TABS (sliding indicator + animated page swap)
local pageList, base = {}, {}
for _, page in ipairs(pages:GetChildren()) do
    local idx = tonumber(page.Name:match("%d+"))
    pageList[idx] = page
    base[page] = page.Position
end

local tabButtons = {}
for _, t in ipairs(tabBar:GetChildren()) do
    if t:IsA("TextButton") then tabButtons[tonumber(t.Name:match("%d+"))] = t end
end

local current = 0
local function showTab(i, instant)
    i = (i - 1) % #pageList + 1
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

    for n, page in ipairs(pageList) do
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

-- CLOSE (reverse the entrance, then clear effects + remove)
titleBar:WaitForChild("Close").MouseButton1Click:Connect(function()
    tween(panel, 0.2, { GroupTransparency = 1 })
    tween(panelScale, 0.2, { Scale = 0.9 }, Enum.EasingStyle.Quad)
    tween(shadow, 0.2, { ImageTransparency = 1 })
    task.delay(0.22, function()
        oneShots["Clear All"]()
        gui:Destroy()
    end)
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
            if input.UserInputState == Enum.UserInputState.End then
                dragging = false
            end
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
