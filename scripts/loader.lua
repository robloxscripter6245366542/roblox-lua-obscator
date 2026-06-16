-- SangraHub v1.0
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")

local player = Players.LocalPlayer

if _G.SangraHubRunning then _G.SangraHubRunning = false end
_G.SangraHubRunning = true

local cfg = { speed = false, fly = false, esp = false, noclip = false, infiniteJump = false }

-- GUI
local sg = Instance.new("ScreenGui")
sg.Name = "SangraHub"
sg.ResetOnSpawn = false
sg.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
sg.Parent = game:GetService("CoreGui")

local main = Instance.new("Frame")
main.Size = UDim2.fromOffset(270, 320)
main.Position = UDim2.fromOffset(60, 60)
main.BackgroundColor3 = Color3.fromRGB(15, 15, 22)
main.BorderSizePixel = 0
main.Parent = sg
Instance.new("UICorner", main).CornerRadius = UDim.new(0, 8)

local bar = Instance.new("Frame")
bar.Size = UDim2.new(1, 0, 0, 36)
bar.BackgroundColor3 = Color3.fromRGB(28, 28, 40)
bar.BorderSizePixel = 0
bar.Parent = main
Instance.new("UICorner", bar).CornerRadius = UDim.new(0, 8)

local lbl = Instance.new("TextLabel")
lbl.Size = UDim2.new(1, 0, 1, 0)
lbl.BackgroundTransparency = 1
lbl.Text = "SangraHub  |  RightCtrl to hide"
lbl.TextColor3 = Color3.fromRGB(170, 120, 255)
lbl.TextSize = 13
lbl.Font = Enum.Font.GothamBold
lbl.Parent = bar

local list = Instance.new("Frame")
list.Size = UDim2.new(1, -16, 1, -48)
list.Position = UDim2.fromOffset(8, 44)
list.BackgroundTransparency = 1
list.Parent = main
Instance.new("UIListLayout", list).Padding = UDim.new(0, 6)

local function toggle(name, key)
    local row = Instance.new("Frame")
    row.Size = UDim2.new(1, 0, 0, 38)
    row.BackgroundColor3 = Color3.fromRGB(24, 24, 34)
    row.BorderSizePixel = 0
    row.Parent = list
    Instance.new("UICorner", row).CornerRadius = UDim.new(0, 6)

    local t = Instance.new("TextLabel")
    t.Size = UDim2.new(1, -60, 1, 0)
    t.Position = UDim2.fromOffset(10, 0)
    t.BackgroundTransparency = 1
    t.Text = name
    t.TextColor3 = Color3.fromRGB(210, 210, 225)
    t.TextSize = 13
    t.Font = Enum.Font.Gotham
    t.TextXAlignment = Enum.TextXAlignment.Left
    t.Parent = row

    local btn = Instance.new("TextButton")
    btn.Size = UDim2.fromOffset(48, 24)
    btn.Position = UDim2.new(1, -56, 0.5, -12)
    btn.BackgroundColor3 = Color3.fromRGB(55, 55, 75)
    btn.Text = "OFF"
    btn.TextColor3 = Color3.fromRGB(170, 170, 190)
    btn.TextSize = 12
    btn.Font = Enum.Font.GothamBold
    btn.BorderSizePixel = 0
    btn.Parent = row
    Instance.new("UICorner", btn).CornerRadius = UDim.new(0, 4)

    btn.MouseButton1Click:Connect(function()
        cfg[key] = not cfg[key]
        btn.BackgroundColor3 = cfg[key] and Color3.fromRGB(110, 70, 210) or Color3.fromRGB(55, 55, 75)
        btn.Text = cfg[key] and "ON" or "OFF"
    end)
end

toggle("Speed Boost", "speed")
toggle("Fly", "fly")
toggle("ESP", "esp")
toggle("Noclip", "noclip")
toggle("Infinite Jump", "infiniteJump")

-- Drag
local drag, ds, sp
bar.InputBegan:Connect(function(i)
    if i.UserInputType == Enum.UserInputType.MouseButton1 then
        drag = true; ds = i.Position; sp = main.Position
    end
end)
UserInputService.InputChanged:Connect(function(i)
    if drag and i.UserInputType == Enum.UserInputType.MouseMovement then
        local d = i.Position - ds
        main.Position = UDim2.fromOffset(sp.X.Offset + d.X, sp.Y.Offset + d.Y)
    end
end)
UserInputService.InputEnded:Connect(function(i)
    if i.UserInputType == Enum.UserInputType.MouseButton1 then drag = false end
end)

UserInputService.InputBegan:Connect(function(i, gp)
    if not gp and i.KeyCode == Enum.KeyCode.RightControl then
        main.Visible = not main.Visible
    end
end)

-- Speed / Noclip / Infinite Jump
RunService.Heartbeat:Connect(function()
    if not _G.SangraHubRunning then return end
    local char = player.Character
    if not char then return end
    local hum = char:FindFirstChildOfClass("Humanoid")
    if hum then
        hum.WalkSpeed = cfg.speed and 80 or 16
        if cfg.infiniteJump and hum:GetState() == Enum.HumanoidStateType.Freefall then
            hum:ChangeState(Enum.HumanoidStateType.Jumping)
        end
    end
    if cfg.noclip then
        for _, p in ipairs(char:GetDescendants()) do
            if p:IsA("BasePart") then p.CanCollide = false end
        end
    end
end)

-- Fly
local flyConn, prevFly
local function startFly()
    local char = player.Character
    if not char then return end
    local root = char:FindFirstChild("HumanoidRootPart")
    local hum = char:FindFirstChildOfClass("Humanoid")
    if not root or not hum then return end
    hum.PlatformStand = true
    local bg = Instance.new("BodyGyro", root)
    bg.MaxTorque = Vector3.new(1e6,1e6,1e6); bg.D = 200
    local bv = Instance.new("BodyVelocity", root)
    bv.MaxForce = Vector3.new(1e6,1e6,1e6); bv.Velocity = Vector3.zero
    flyConn = RunService.Heartbeat:Connect(function()
        if not cfg.fly then
            pcall(function() bv:Destroy(); bg:Destroy(); hum.PlatformStand = false end)
            flyConn:Disconnect(); flyConn = nil; return
        end
        local cf = workspace.CurrentCamera.CFrame
        local v = Vector3.zero
        if UserInputService:IsKeyDown(Enum.KeyCode.W) then v += cf.LookVector end
        if UserInputService:IsKeyDown(Enum.KeyCode.S) then v -= cf.LookVector end
        if UserInputService:IsKeyDown(Enum.KeyCode.A) then v -= cf.RightVector end
        if UserInputService:IsKeyDown(Enum.KeyCode.D) then v += cf.RightVector end
        if UserInputService:IsKeyDown(Enum.KeyCode.Space) then v += Vector3.yAxis end
        if UserInputService:IsKeyDown(Enum.KeyCode.LeftShift) then v -= Vector3.yAxis end
        bv.Velocity = v * 60; bg.CFrame = cf
    end)
end

RunService.Heartbeat:Connect(function()
    if cfg.fly and not prevFly then startFly() end
    prevFly = cfg.fly
end)

-- ESP
local boxes = {}
RunService.Heartbeat:Connect(function()
    if not cfg.esp then
        for _, b in pairs(boxes) do pcall(function() b:Destroy() end) end
        boxes = {}; return
    end
    for _, p in ipairs(Players:GetPlayers()) do
        if p ~= player and p.Character and not boxes[p] then
            local b = Instance.new("SelectionBox")
            b.Adornee = p.Character
            b.Color3 = Color3.fromRGB(110, 70, 210)
            b.LineThickness = 0.05
            b.SurfaceTransparency = 0.75
            b.SurfaceColor3 = Color3.fromRGB(110, 70, 210)
            b.Parent = sg
            boxes[p] = b
        end
    end
    for p, b in pairs(boxes) do
        if not p.Character then b:Destroy(); boxes[p] = nil end
    end
end)

Players.PlayerRemoving:Connect(function(p)
    if boxes[p] then boxes[p]:Destroy(); boxes[p] = nil end
end)
