-- SangraHub v2.0 | Main Hub
-- Speed · Fly · ESP · Noclip · Infinite Jump · Auto-Parry loader
-- Nice UI, draggable, RightCtrl toggle

local Players    = game:GetService("Players")
local RunService = game:GetService("RunService")
local UIS        = game:GetService("UserInputService")
local TweenSvc   = game:GetService("TweenService")

local lp = Players.LocalPlayer

if _G.SangraHubActive then _G.SangraHubActive = false task.wait(0.05) end
_G.SangraHubActive = true

local cfg = {
    speed         = false, speedVal = 80,
    fly           = false,
    esp           = false,
    noclip        = false,
    infiniteJump  = false,
    autoBB        = false,  -- load blade ball parry
}

-- ─── Colour Palette ───────────────────────────────────────────────────────────
local C = {
    bg     = Color3.fromRGB(11, 10, 18),
    panel  = Color3.fromRGB(17, 15, 28),
    bar    = Color3.fromRGB(22, 18, 40),
    row    = Color3.fromRGB(22, 20, 35),
    accent = Color3.fromRGB(130, 75, 255),
    on     = Color3.fromRGB(110, 60, 220),
    off    = Color3.fromRGB(48, 44, 68),
    text   = Color3.fromRGB(210, 205, 230),
    dim    = Color3.fromRGB(140, 135, 165),
    white  = Color3.fromRGB(240, 238, 255),
}

-- ─── GUI skeleton ─────────────────────────────────────────────────────────────
local sg = Instance.new("ScreenGui")
sg.Name = "SangraHub"
sg.ResetOnSpawn = false
sg.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
sg.Parent = game:GetService("CoreGui")

local shadow = Instance.new("Frame")
shadow.Size = UDim2.fromOffset(298, 462)
shadow.Position = UDim2.fromOffset(34, 34)
shadow.BackgroundColor3 = Color3.fromRGB(0,0,0)
shadow.BackgroundTransparency = 0.65
shadow.BorderSizePixel = 0
shadow.Parent = sg
Instance.new("UICorner", shadow).CornerRadius = UDim.new(0, 10)

local win = Instance.new("Frame")
win.Size = UDim2.fromOffset(295, 458)
win.Position = UDim2.fromOffset(32, 32)
win.BackgroundColor3 = C.bg
win.BorderSizePixel = 0
win.Parent = sg
Instance.new("UICorner", win).CornerRadius = UDim.new(0, 10)

local stroke = Instance.new("UIStroke", win)
stroke.Color = C.accent
stroke.Transparency = 0.55
stroke.Thickness = 1.2

-- header bar
local bar = Instance.new("Frame")
bar.Size = UDim2.new(1, 0, 0, 42)
bar.BackgroundColor3 = C.bar
bar.BorderSizePixel = 0
bar.Parent = win
Instance.new("UICorner", bar).CornerRadius = UDim.new(0, 10)

-- accent line under bar
local line = Instance.new("Frame")
line.Size = UDim2.new(1, -20, 0, 1)
line.Position = UDim2.new(0, 10, 0, 42)
line.BackgroundColor3 = C.accent
line.BackgroundTransparency = 0.5
line.BorderSizePixel = 0
line.Parent = win

local icon = Instance.new("TextLabel")
icon.Size = UDim2.fromOffset(30, 42)
icon.Position = UDim2.fromOffset(10, 0)
icon.BackgroundTransparency = 1
icon.Text = "⚡"
icon.TextSize = 18
icon.Font = Enum.Font.GothamBold
icon.TextColor3 = C.accent
icon.Parent = bar

local titleLbl = Instance.new("TextLabel")
titleLbl.Size = UDim2.new(1, -80, 1, 0)
titleLbl.Position = UDim2.fromOffset(38, 0)
titleLbl.BackgroundTransparency = 1
titleLbl.Text = "SangraHub  v2.0"
titleLbl.TextSize = 14
titleLbl.Font = Enum.Font.GothamBold
titleLbl.TextColor3 = C.white
titleLbl.TextXAlignment = Enum.TextXAlignment.Left
titleLbl.Parent = bar

local hintLbl = Instance.new("TextLabel")
hintLbl.Size = UDim2.fromOffset(80, 42)
hintLbl.Position = UDim2.new(1, -82, 0, 0)
hintLbl.BackgroundTransparency = 1
hintLbl.Text = "RCtrl hide"
hintLbl.TextSize = 10
hintLbl.Font = Enum.Font.Gotham
hintLbl.TextColor3 = C.dim
hintLbl.TextXAlignment = Enum.TextXAlignment.Right
hintLbl.Parent = bar

-- content scroll
local scroll = Instance.new("ScrollingFrame")
scroll.Size = UDim2.new(1, -12, 1, -56)
scroll.Position = UDim2.fromOffset(6, 52)
scroll.BackgroundTransparency = 1
scroll.BorderSizePixel = 0
scroll.ScrollBarThickness = 3
scroll.ScrollBarImageColor3 = C.accent
scroll.CanvasSize = UDim2.new(0, 0, 0, 0)
scroll.AutomaticCanvasSize = Enum.AutomaticSize.Y
scroll.Parent = win

local list = Instance.new("Frame")
list.Size = UDim2.new(1, 0, 0, 0)
list.AutomaticSize = Enum.AutomaticSize.Y
list.BackgroundTransparency = 1
list.Parent = scroll

local layout = Instance.new("UIListLayout", list)
layout.Padding = UDim.new(0, 5)
Instance.new("UIPadding", list).PaddingTop = UDim.new(0, 4)

-- ─── Section header ───────────────────────────────────────────────────────────
local function section(title)
    local s = Instance.new("Frame")
    s.Size = UDim2.new(1, -8, 0, 24)
    s.BackgroundTransparency = 1
    s.Parent = list

    local t = Instance.new("TextLabel", s)
    t.Size = UDim2.new(1, 0, 1, 0)
    t.BackgroundTransparency = 1
    t.Text = ("  %s"):format(title:upper())
    t.TextSize = 10
    t.Font = Enum.Font.GothamBold
    t.TextColor3 = C.accent
    t.TextXAlignment = Enum.TextXAlignment.Left

    local ln = Instance.new("Frame", s)
    ln.Size = UDim2.new(1, -60, 0, 1)
    ln.Position = UDim2.new(0, 56, 1, -1)
    ln.BackgroundColor3 = C.accent
    ln.BackgroundTransparency = 0.7
    ln.BorderSizePixel = 0
end

-- ─── Toggle row ───────────────────────────────────────────────────────────────
local function toggle(label, hint, key, callback)
    local row = Instance.new("Frame")
    row.Size = UDim2.new(1, -8, 0, 44)
    row.BackgroundColor3 = C.row
    row.BorderSizePixel = 0
    row.Parent = list
    Instance.new("UICorner", row).CornerRadius = UDim.new(0, 7)

    local lbl = Instance.new("TextLabel", row)
    lbl.Size = UDim2.new(1, -70, 0, 22)
    lbl.Position = UDim2.fromOffset(10, 4)
    lbl.BackgroundTransparency = 1
    lbl.Text = label
    lbl.TextSize = 13
    lbl.Font = Enum.Font.GothamBold
    lbl.TextColor3 = C.text
    lbl.TextXAlignment = Enum.TextXAlignment.Left

    local sub = Instance.new("TextLabel", row)
    sub.Size = UDim2.new(1, -70, 0, 16)
    sub.Position = UDim2.fromOffset(10, 24)
    sub.BackgroundTransparency = 1
    sub.Text = hint
    sub.TextSize = 10
    sub.Font = Enum.Font.Gotham
    sub.TextColor3 = C.dim
    sub.TextXAlignment = Enum.TextXAlignment.Left

    local btn = Instance.new("TextButton", row)
    btn.Size = UDim2.fromOffset(52, 26)
    btn.Position = UDim2.new(1, -60, 0.5, -13)
    btn.BackgroundColor3 = C.off
    btn.Text = "OFF"
    btn.TextSize = 11
    btn.Font = Enum.Font.GothamBold
    btn.TextColor3 = C.text
    btn.BorderSizePixel = 0
    Instance.new("UICorner", btn).CornerRadius = UDim.new(0, 5)

    local function refresh()
        local on = cfg[key]
        TweenSvc:Create(btn, TweenInfo.new(0.15), {
            BackgroundColor3 = on and C.on or C.off,
        }):Play()
        btn.Text = on and "ON" or "OFF"
    end

    btn.MouseButton1Click:Connect(function()
        cfg[key] = not cfg[key]
        refresh()
        if callback then callback(cfg[key]) end
    end)

    refresh()
    return btn
end

-- ─── Sections ─────────────────────────────────────────────────────────────────
section("Movement")
toggle("Speed Boost", "80 walkspeed", "speed")
toggle("Fly",         "WASD + Space/Shift", "fly")
toggle("Noclip",      "Walk through walls", "noclip")
toggle("Infinite Jump","Jump forever", "infiniteJump")

section("Visuals")
toggle("Player ESP",  "Highlight all players", "esp")

section("Combat")
toggle("Auto Parry (BB)", "Blade Ball auto-parry", "autoBB", function(on)
    if on then
        pcall(function()
            loadstring(game:HttpGet(
                "https://raw.githubusercontent.com/robloxscripter6245366542/roblox-lua-obscator/claude/remove-key-system-qxfa4f/scripts/loader.lua"
            ))()
        end)
    else
        _G.SangraBBActive = false
    end
end)

-- ─── Drag ────────────────────────────────────────────────────────────────────
local drag, ds, sp
bar.InputBegan:Connect(function(i)
    if i.UserInputType == Enum.UserInputType.MouseButton1 then
        drag = true; ds = i.Position; sp = win.Position
    end
end)
UIS.InputChanged:Connect(function(i)
    if drag and i.UserInputType == Enum.UserInputType.MouseMovement then
        local d = i.Position - ds
        local nx = sp.X.Offset + d.X
        local ny = sp.Y.Offset + d.Y
        win.Position  = UDim2.fromOffset(nx, ny)
        shadow.Position = UDim2.fromOffset(nx + 2, ny + 2)
    end
end)
UIS.InputEnded:Connect(function(i)
    if i.UserInputType == Enum.UserInputType.MouseButton1 then drag = false end
end)
UIS.InputBegan:Connect(function(i, gp)
    if not gp and i.KeyCode == Enum.KeyCode.RightControl then
        local v = not win.Visible
        win.Visible    = v
        shadow.Visible = v
    end
end)

-- ─── ESP ─────────────────────────────────────────────────────────────────────
local boxes = {}
RunService.Heartbeat:Connect(function()
    if not cfg.esp then
        for _, b in pairs(boxes) do pcall(function() b:Destroy() end) end
        boxes = {}; return
    end
    for _, p in ipairs(Players:GetPlayers()) do
        if p ~= lp and p.Character and not boxes[p] then
            local b = Instance.new("SelectionBox")
            b.Adornee = p.Character
            b.Color3 = C.accent
            b.LineThickness = 0.06
            b.SurfaceTransparency = 0.78
            b.SurfaceColor3 = C.accent
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

-- ─── Speed / Noclip / InfJump ────────────────────────────────────────────────
RunService.Heartbeat:Connect(function()
    if not _G.SangraHubActive then return end
    local char = lp.Character
    if not char then return end
    local hum = char:FindFirstChildOfClass("Humanoid")
    if hum then
        hum.WalkSpeed = cfg.speed and cfg.speedVal or 16
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

-- ─── Fly ─────────────────────────────────────────────────────────────────────
local flyConn, prevFly
local function startFly()
    local char = lp.Character
    if not char then return end
    local root = char:FindFirstChild("HumanoidRootPart")
    local hum  = char:FindFirstChildOfClass("Humanoid")
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
        if UIS:IsKeyDown(Enum.KeyCode.W) then v += cf.LookVector end
        if UIS:IsKeyDown(Enum.KeyCode.S) then v -= cf.LookVector end
        if UIS:IsKeyDown(Enum.KeyCode.A) then v -= cf.RightVector end
        if UIS:IsKeyDown(Enum.KeyCode.D) then v += cf.RightVector end
        if UIS:IsKeyDown(Enum.KeyCode.Space)     then v += Vector3.yAxis end
        if UIS:IsKeyDown(Enum.KeyCode.LeftShift) then v -= Vector3.yAxis end
        bv.Velocity = v * 65; bg.CFrame = cf
    end)
end

RunService.Heartbeat:Connect(function()
    if cfg.fly and not prevFly then startFly() end
    prevFly = cfg.fly
end)
