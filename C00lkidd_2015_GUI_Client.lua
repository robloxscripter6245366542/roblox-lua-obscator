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

local player = Players.LocalPlayer
local camera = workspace.CurrentCamera
local gui = player:WaitForChild("PlayerGui"):WaitForChild("CoolKidGUI")
local panel = gui:WaitForChild("MainPanel")
local pages = panel:WaitForChild("Pages")

local RED = Color3.fromRGB(255, 0, 0)
local TEXTURE = "rbxassetid://" .. DECAL_ID
local FACES = Enum.NormalId:GetEnumItems()

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
            for _, b in ipairs(panel:GetDescendants()) do
                if b:IsA("GuiObject") then b.BorderColor3 = c end
            end
            panel.BorderColor3 = c
        end, 0.05)
    end,
    off = function()
        for _, b in ipairs(panel:GetDescendants()) do
            if b:IsA("GuiObject") then
                b.BorderColor3 = active[b.Name] and Color3.new(1, 1, 1) or RED
            end
        end
        panel.BorderColor3 = RED
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


local function setActive(button, on)
    active[button.Name] = on or nil
    for _, page in ipairs(pages:GetChildren()) do
        local b = page:FindFirstChild(button.Name)
        if b then b.BorderColor3 = on and Color3.new(1, 1, 1) or RED end
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

-- PAGING
local pageList = {}
for _, page in ipairs(pages:GetChildren()) do
    pageList[tonumber(page.Name:match("%d+"))] = page
end
local current = 1
local pageNumber = panel:WaitForChild("PageNumber")

local function showPage(i)
    current = (i - 1) % #pageList + 1
    for n, page in ipairs(pageList) do
        page.Visible = n == current
    end
    pageNumber.Text = current .. "/" .. #pageList
end

panel:WaitForChild("Prev").MouseButton1Click:Connect(function() showPage(current - 1) end)
panel:WaitForChild("Next").MouseButton1Click:Connect(function() showPage(current + 1) end)

-- CLOSE
local titleBar = panel:WaitForChild("TitleBar")
titleBar:WaitForChild("Close").MouseButton1Click:Connect(function()
    oneShots["Clear All"]()
    gui:Destroy()
end)

-- DRAG (title bar, mouse + touch)
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
    end
end)
