-- [INFINITE & GUN] SLAP Script with UI
-- ZAP buffer-aware: captures real slap packets then replays them

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local lp = Players.LocalPlayer
local char = lp.Character or lp.CharacterAdded:Wait()
local Event = game:GetService("ReplicatedStorage"):WaitForChild("ZAP"):WaitForChild("MISC_RELIABLE")

local cfg = {
    killAura      = false,
    autoSlap      = false,
    infiniteReach = false,
    speed         = 32,
    jumpPower     = 60,
    auraRange     = 60,
}

-- ── Capture real outgoing slap packets (ZAP buffer replay) ────────
local lastSlapPacket = nil
local origFireServer = Event.FireServer
hookfunction(origFireServer, function(self, ...)
    lastSlapPacket = {...}
    return origFireServer(self, ...)
end)

-- ── UI ────────────────────────────────────────────────────────────
local gui = Instance.new("ScreenGui")
gui.Name = "SlapUI"
gui.ResetOnSpawn = false
gui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
if gethui then
    gui.Parent = gethui()
elseif syn and syn.protect_gui then
    syn.protect_gui(gui); gui.Parent = game.CoreGui
else
    gui.Parent = game.CoreGui
end

local win = Instance.new("Frame", gui)
win.Size = UDim2.new(0, 270, 0, 360)
win.Position = UDim2.new(0.5, -135, 0.5, -180)
win.BackgroundColor3 = Color3.fromRGB(8, 4, 25)
win.BorderSizePixel = 0
win.Active = true
win.Draggable = true
Instance.new("UICorner", win).CornerRadius = UDim.new(0, 10)
local stroke = Instance.new("UIStroke", win)
stroke.Color = Color3.fromRGB(120, 60, 255)
stroke.Thickness = 1.5
stroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border

-- Animated border glow
task.spawn(function()
    local t = 0
    while win.Parent do
        t += 0.03
        stroke.Color = Color3.fromHSV(0.72 + math.sin(t)*0.05, 0.8, 1)
        task.wait(0.05)
    end
end)

-- Title bar
local titleBar = Instance.new("Frame", win)
titleBar.Size = UDim2.new(1, 0, 0, 42)
titleBar.BackgroundColor3 = Color3.fromRGB(18, 8, 45)
titleBar.BorderSizePixel = 0
Instance.new("UICorner", titleBar).CornerRadius = UDim.new(0, 10)

local title = Instance.new("TextLabel", titleBar)
title.Size = UDim2.new(1, -50, 1, 0)
title.Position = UDim2.new(0, 12, 0, 0)
title.BackgroundTransparency = 1
title.Text = "⚡ SLAP SCRIPT"
title.TextColor3 = Color3.fromRGB(180, 120, 255)
title.Font = Enum.Font.GothamBold
title.TextSize = 14
title.TextXAlignment = Enum.TextXAlignment.Left

local closeBtn = Instance.new("TextButton", titleBar)
closeBtn.Size = UDim2.new(0, 28, 0, 28)
closeBtn.Position = UDim2.new(1, -36, 0, 7)
closeBtn.BackgroundColor3 = Color3.fromRGB(180, 40, 40)
closeBtn.Text = "✕"
closeBtn.TextColor3 = Color3.fromRGB(255,255,255)
closeBtn.Font = Enum.Font.GothamBold
closeBtn.TextSize = 12
closeBtn.BorderSizePixel = 0
Instance.new("UICorner", closeBtn).CornerRadius = UDim.new(0, 6)
closeBtn.MouseButton1Click:Connect(function() gui:Destroy() end)

-- Content
local content = Instance.new("Frame", win)
content.Size = UDim2.new(1, -20, 1, -52)
content.Position = UDim2.new(0, 10, 0, 47)
content.BackgroundTransparency = 1
local layout = Instance.new("UIListLayout", content)
layout.SortOrder = Enum.SortOrder.LayoutOrder
layout.Padding = UDim.new(0, 7)

-- ── Toggle helper ─────────────────────────────────────────────────
local function mkToggle(parent, label, key, order)
    local row = Instance.new("Frame", parent)
    row.Size = UDim2.new(1, 0, 0, 38)
    row.BackgroundColor3 = Color3.fromRGB(18, 10, 42)
    row.BorderSizePixel = 0
    row.LayoutOrder = order or 0
    Instance.new("UICorner", row).CornerRadius = UDim.new(0, 8)

    local lbl = Instance.new("TextLabel", row)
    lbl.Size = UDim2.new(1, -62, 1, 0)
    lbl.Position = UDim2.new(0, 12, 0, 0)
    lbl.BackgroundTransparency = 1
    lbl.Text = label
    lbl.TextColor3 = Color3.fromRGB(210, 200, 240)
    lbl.Font = Enum.Font.Gotham
    lbl.TextSize = 13
    lbl.TextXAlignment = Enum.TextXAlignment.Left

    local tog = Instance.new("Frame", row)
    tog.Size = UDim2.new(0, 42, 0, 22)
    tog.Position = UDim2.new(1, -54, 0.5, -11)
    tog.BackgroundColor3 = Color3.fromRGB(35, 20, 60)
    tog.BorderSizePixel = 0
    Instance.new("UICorner", tog).CornerRadius = UDim.new(1, 0)

    local knob = Instance.new("Frame", tog)
    knob.Size = UDim2.new(0, 18, 0, 18)
    knob.Position = UDim2.new(0, 2, 0.5, -9)
    knob.BackgroundColor3 = Color3.fromRGB(100, 60, 160)
    knob.BorderSizePixel = 0
    Instance.new("UICorner", knob).CornerRadius = UDim.new(1, 0)

    local function refresh()
        local on = cfg[key]
        TweenService:Create(knob, TweenInfo.new(0.15), {
            Position = on and UDim2.new(1,-20,0.5,-9) or UDim2.new(0,2,0.5,-9),
            BackgroundColor3 = on and Color3.fromRGB(140,70,255) or Color3.fromRGB(80,50,120),
        }):Play()
        TweenService:Create(tog, TweenInfo.new(0.15), {
            BackgroundColor3 = on and Color3.fromRGB(55,20,110) or Color3.fromRGB(25,12,50),
        }):Play()
    end
    refresh()

    local btn = Instance.new("TextButton", row)
    btn.Size = UDim2.new(1,0,1,0)
    btn.BackgroundTransparency = 1
    btn.Text = ""
    btn.MouseButton1Click:Connect(function()
        cfg[key] = not cfg[key]
        refresh()
    end)
    return row
end

-- ── Stat row helper ───────────────────────────────────────────────
local function mkStat(parent, label, value, order)
    local row = Instance.new("Frame", parent)
    row.Size = UDim2.new(1, 0, 0, 34)
    row.BackgroundColor3 = Color3.fromRGB(14, 7, 35)
    row.BorderSizePixel = 0
    row.LayoutOrder = order or 99
    Instance.new("UICorner", row).CornerRadius = UDim.new(0, 8)

    local lbl = Instance.new("TextLabel", row)
    lbl.Size = UDim2.new(0.6, 0, 1, 0)
    lbl.Position = UDim2.new(0, 12, 0, 0)
    lbl.BackgroundTransparency = 1
    lbl.Text = label
    lbl.TextColor3 = Color3.fromRGB(150, 140, 190)
    lbl.Font = Enum.Font.Gotham
    lbl.TextSize = 12
    lbl.TextXAlignment = Enum.TextXAlignment.Left

    local val = Instance.new("TextLabel", row)
    val.Size = UDim2.new(0.4, -12, 1, 0)
    val.AnchorPoint = Vector2.new(1, 0)
    val.Position = UDim2.new(1, -12, 0, 0)
    val.BackgroundTransparency = 1
    val.Text = tostring(value)
    val.TextColor3 = Color3.fromRGB(140, 80, 255)
    val.Font = Enum.Font.GothamBold
    val.TextSize = 12
    val.TextXAlignment = Enum.TextXAlignment.Right
    return row, val
end

-- ── Section divider ───────────────────────────────────────────────
local function mkDiv(parent, text, order)
    local row = Instance.new("Frame", parent)
    row.Size = UDim2.new(1, 0, 0, 18)
    row.BackgroundTransparency = 1
    row.LayoutOrder = order or 0
    local lbl = Instance.new("TextLabel", row)
    lbl.Size = UDim2.new(1, 0, 1, 0)
    lbl.BackgroundTransparency = 1
    lbl.Text = text
    lbl.TextColor3 = Color3.fromRGB(100, 80, 150)
    lbl.Font = Enum.Font.GothamBold
    lbl.TextSize = 10
    lbl.TextXAlignment = Enum.TextXAlignment.Left
end

-- Build UI rows
mkDiv(content, "  COMBAT", 1)
mkToggle(content, "Kill Aura  (teleport to nearest)", "killAura", 2)
mkToggle(content, "Auto Slap  (packet replay)", "autoSlap", 3)
mkToggle(content, "Infinite Reach  (expand hitbox)", "infiniteReach", 4)
mkDiv(content, "  MOVEMENT", 5)
mkToggle(content, "Speed Boost  (x2)", "speed", 6)
mkToggle(content, "High Jump", "jumpPower", 7)
mkDiv(content, "  STATS", 8)
local _, slapsVal  = mkStat(content, "Slaps Landed", "0", 9)
local _, packetVal = mkStat(content, "Packet Captured", "No", 10)

-- ── Speed config (reuse key slot differently) ─────────────────────
-- Override: treat cfg.speed & jumpPower as toggles for simplicity
local BASE_SPEED, BASE_JUMP = 32, 80
cfg.speed = false
cfg.jumpPower = false

-- ── Apply movement stats on spawn ─────────────────────────────────
local function applyMovement(c)
    char = c
    local hum = c:WaitForChild("Humanoid")
    hum.WalkSpeed = cfg.speed and BASE_SPEED or 16
    hum.JumpPower = cfg.jumpPower and BASE_JUMP or 50
end
lp.CharacterAdded:Connect(function(c)
    applyMovement(c)
end)
task.spawn(function() applyMovement(char) end)

RunService.Heartbeat:Connect(function()
    local hum = char and char:FindFirstChildOfClass("Humanoid")
    if hum then
        hum.WalkSpeed = cfg.speed and BASE_SPEED or 16
        hum.JumpPower = cfg.jumpPower and BASE_JUMP or 50
    end
end)

-- ── Infinite reach ────────────────────────────────────────────────
RunService.Heartbeat:Connect(function()
    if not char or not cfg.infiniteReach then return end
    for _, obj in char:GetDescendants() do
        if obj:IsA("BasePart") and obj.Name:lower():find("slap") then
            obj.Size = Vector3.new(cfg.auraRange, cfg.auraRange, cfg.auraRange)
        end
    end
end)

-- ── Kill Aura + packet replay ─────────────────────────────────────
local slapCount = 0
local lastSlap = 0

RunService.Heartbeat:Connect(function()
    if tick() - lastSlap < 0.1 then return end
    if not cfg.killAura and not cfg.autoSlap then return end
    local root = char and char:FindFirstChild("HumanoidRootPart")
    if not root then return end

    -- Find nearest enemy
    local target, closest = nil, cfg.auraRange
    for _, p in Players:GetPlayers() do
        if p ~= lp and p.Character then
            local pr  = p.Character:FindFirstChild("HumanoidRootPart")
            local hum = p.Character:FindFirstChildOfClass("Humanoid")
            if pr and hum and hum.Health > 0 then
                local d = (pr.Position - root.Position).Magnitude
                if d < closest then target, closest = p, d end
            end
        end
    end
    if not target then return end

    local tr = target.Character:FindFirstChild("HumanoidRootPart")
    if not tr then return end

    -- Teleport behind target (kill aura)
    if cfg.killAura then
        root.CFrame = CFrame.new(tr.Position + Vector3.new(0, 0, 2.5))
    end

    -- Replay last captured slap packet (auto slap via real ZAP buffer)
    if cfg.autoSlap and lastSlapPacket then
        pcall(function()
            Event:FireServer(table.unpack(lastSlapPacket))
        end)
        slapCount += 1
        slapsVal.Text = tostring(slapCount)
    end

    lastSlap = tick()
end)

-- Update packet status label
RunService.Heartbeat:Connect(function()
    packetVal.Text = lastSlapPacket and "✓ Ready" or "Waiting…"
    packetVal.TextColor3 = lastSlapPacket
        and Color3.fromRGB(80, 255, 120)
        or  Color3.fromRGB(255, 160, 60)
end)

-- ── Ready ─────────────────────────────────────────────────────────
game.StarterGui:SetCore("SendNotification", {
    Title = "⚡ SLAP SCRIPT",
    Text  = "Loaded! Slap once manually to capture packet, then enable Auto Slap.",
    Duration = 6,
})
