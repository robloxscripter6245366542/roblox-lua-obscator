-- [INFINITE & GUN] SLAP Script with UI
-- Controls: Kill Aura, Auto Slap, Speed, Jump, Infinite Reach

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
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

-- ── UI ────────────────────────────────────────────────────────────
local gui = Instance.new("ScreenGui")
gui.Name = "SlapUI"
gui.ResetOnSpawn = false
gui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
if gethui then gui.Parent = gethui()
elseif syn and syn.protect_gui then syn.protect_gui(gui); gui.Parent = game.CoreGui
else gui.Parent = game.CoreGui end

local win = Instance.new("Frame", gui)
win.Size = UDim2.new(0, 260, 0, 340)
win.Position = UDim2.new(0.5, -130, 0.5, -170)
win.BackgroundColor3 = Color3.fromRGB(8, 4, 25)
win.BorderSizePixel = 0
win.Active = true
win.Draggable = true
Instance.new("UICorner", win).CornerRadius = UDim.new(0, 10)
local stroke = Instance.new("UIStroke", win)
stroke.Color = Color3.fromRGB(120, 60, 255)
stroke.Thickness = 1.5
stroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border

-- Title bar
local titleBar = Instance.new("Frame", win)
titleBar.Size = UDim2.new(1, 0, 0, 40)
titleBar.BackgroundColor3 = Color3.fromRGB(18, 8, 45)
titleBar.BorderSizePixel = 0
Instance.new("UICorner", titleBar).CornerRadius = UDim.new(0, 10)

local title = Instance.new("TextLabel", titleBar)
title.Size = UDim2.new(1, -10, 1, 0)
title.Position = UDim2.new(0, 10, 0, 0)
title.BackgroundTransparency = 1
title.Text = "⚡ SLAP SCRIPT"
title.TextColor3 = Color3.fromRGB(180, 120, 255)
title.Font = Enum.Font.GothamBold
title.TextSize = 14
title.TextXAlignment = Enum.TextXAlignment.Left

-- Close button
local closeBtn = Instance.new("TextButton", titleBar)
closeBtn.Size = UDim2.new(0, 30, 0, 30)
closeBtn.Position = UDim2.new(1, -35, 0, 5)
closeBtn.BackgroundColor3 = Color3.fromRGB(180, 40, 40)
closeBtn.Text = "✕"
closeBtn.TextColor3 = Color3.fromRGB(255,255,255)
closeBtn.Font = Enum.Font.GothamBold
closeBtn.TextSize = 12
closeBtn.BorderSizePixel = 0
Instance.new("UICorner", closeBtn).CornerRadius = UDim.new(0, 6)
closeBtn.MouseButton1Click:Connect(function() gui:Destroy() end)

-- Content area
local content = Instance.new("Frame", win)
content.Size = UDim2.new(1, -20, 1, -50)
content.Position = UDim2.new(0, 10, 0, 45)
content.BackgroundTransparency = 1
local layout = Instance.new("UIListLayout", content)
layout.SortOrder = Enum.SortOrder.LayoutOrder
layout.Padding = UDim.new(0, 8)

-- ── Helper: toggle row ────────────────────────────────────────────
local function mkToggle(parent, label, key, onChange)
    local row = Instance.new("Frame", parent)
    row.Size = UDim2.new(1, 0, 0, 36)
    row.BackgroundColor3 = Color3.fromRGB(18, 10, 40)
    row.BorderSizePixel = 0
    Instance.new("UICorner", row).CornerRadius = UDim.new(0, 8)

    local lbl = Instance.new("TextLabel", row)
    lbl.Size = UDim2.new(1, -60, 1, 0)
    lbl.Position = UDim2.new(0, 12, 0, 0)
    lbl.BackgroundTransparency = 1
    lbl.Text = label
    lbl.TextColor3 = Color3.fromRGB(210, 200, 240)
    lbl.Font = Enum.Font.Gotham
    lbl.TextSize = 13
    lbl.TextXAlignment = Enum.TextXAlignment.Left

    local tog = Instance.new("Frame", row)
    tog.Size = UDim2.new(0, 40, 0, 20)
    tog.Position = UDim2.new(1, -52, 0.5, -10)
    tog.BackgroundColor3 = Color3.fromRGB(50, 30, 80)
    tog.BorderSizePixel = 0
    Instance.new("UICorner", tog).CornerRadius = UDim.new(1, 0)

    local knob = Instance.new("Frame", tog)
    knob.Size = UDim2.new(0, 16, 0, 16)
    knob.Position = UDim2.new(0, 2, 0.5, -8)
    knob.BackgroundColor3 = Color3.fromRGB(130, 80, 200)
    knob.BorderSizePixel = 0
    Instance.new("UICorner", knob).CornerRadius = UDim.new(1, 0)

    local on = cfg[key]
    local function refresh()
        TweenService:Create(knob, TweenInfo.new(0.15), {
            Position = on and UDim2.new(1,-18,0.5,-8) or UDim2.new(0,2,0.5,-8),
            BackgroundColor3 = on and Color3.fromRGB(120,60,255) or Color3.fromRGB(80,50,120),
        }):Play()
        TweenService:Create(tog, TweenInfo.new(0.15), {
            BackgroundColor3 = on and Color3.fromRGB(60,20,120) or Color3.fromRGB(30,15,60),
        }):Play()
    end
    refresh()

    local btn = Instance.new("TextButton", row)
    btn.Size = UDim2.new(1, 0, 1, 0)
    btn.BackgroundTransparency = 1
    btn.Text = ""
    btn.MouseButton1Click:Connect(function()
        on = not on
        cfg[key] = on
        refresh()
        if onChange then onChange(on) end
    end)
    return row
end

-- ── Helper: stat label ────────────────────────────────────────────
local function mkStat(parent, label, value)
    local row = Instance.new("Frame", parent)
    row.Size = UDim2.new(1, 0, 0, 36)
    row.BackgroundColor3 = Color3.fromRGB(18, 10, 40)
    row.BorderSizePixel = 0
    Instance.new("UICorner", row).CornerRadius = UDim.new(0, 8)

    local lbl = Instance.new("TextLabel", row)
    lbl.Size = UDim2.new(0.6, 0, 1, 0)
    lbl.Position = UDim2.new(0, 12, 0, 0)
    lbl.BackgroundTransparency = 1
    lbl.Text = label
    lbl.TextColor3 = Color3.fromRGB(170, 160, 210)
    lbl.Font = Enum.Font.Gotham
    lbl.TextSize = 12
    lbl.TextXAlignment = Enum.TextXAlignment.Left

    local val = Instance.new("TextLabel", row)
    val.Size = UDim2.new(0.4, -12, 1, 0)
    val.Position = UDim2.new(0.6, 0, 0, 0)
    val.BackgroundTransparency = 1
    val.Text = tostring(value)
    val.TextColor3 = Color3.fromRGB(140, 80, 255)
    val.Font = Enum.Font.GothamBold
    val.TextSize = 12
    val.TextXAlignment = Enum.TextXAlignment.Right
    val.AnchorPoint = Vector2.new(1, 0)
    val.Position = UDim2.new(1, -12, 0, 0)
    return row, val
end

-- Toggles
mkToggle(content, "Kill Aura", "killAura")
mkToggle(content, "Auto Slap", "autoSlap")
mkToggle(content, "Infinite Reach", "infiniteReach")

-- Stats
local _, speedVal  = mkStat(content, "Speed", cfg.speed)
local _, jumpVal   = mkStat(content, "Jump Power", cfg.jumpPower)
local _, rangeVal  = mkStat(content, "Aura Range", cfg.auraRange.." studs")
local _, slapsVal  = mkStat(content, "Slaps Landed", "0")

local slapCount = 0

-- ── Speed & Jump on spawn ─────────────────────────────────────────
local function applyStats(c)
    char = c
    local hum = c:WaitForChild("Humanoid")
    hum.WalkSpeed = cfg.speed
    hum.JumpPower = cfg.jumpPower
end
lp.CharacterAdded:Connect(applyStats)
task.spawn(function() applyStats(char) end)

-- ── Intercept MISC_RELIABLE ───────────────────────────────────────
pcall(function()
    for _, conn in getconnections(Event.OnClientEvent) do
        local old; old = hookfunction(conn.Function, function(...)
            return old(...)
        end)
    end
end)

-- ── Infinite Reach ────────────────────────────────────────────────
RunService.Heartbeat:Connect(function()
    if not char then return end
    if cfg.infiniteReach then
        for _, obj in char:GetDescendants() do
            if obj:IsA("BasePart") and obj.Name:lower():find("slap") then
                obj.Size = Vector3.new(cfg.auraRange, cfg.auraRange, cfg.auraRange)
            end
        end
    end
end)

-- ── Kill Aura / Auto Slap ─────────────────────────────────────────
RunService.Heartbeat:Connect(function()
    if not cfg.killAura and not cfg.autoSlap then return end
    local root = char and char:FindFirstChild("HumanoidRootPart")
    if not root then return end

    local closest, closestDist = nil, cfg.auraRange
    for _, p in Players:GetPlayers() do
        if p ~= lp and p.Character then
            local pr  = p.Character:FindFirstChild("HumanoidRootPart")
            local hum = p.Character:FindFirstChildOfClass("Humanoid")
            if pr and hum and hum.Health > 0 then
                local d = (pr.Position - root.Position).Magnitude
                if d < closestDist then closest, closestDist = p, d end
            end
        end
    end

    if not closest then return end
    local tr = closest.Character:FindFirstChild("HumanoidRootPart")
    if not tr then return end

    if cfg.autoSlap then
        root.CFrame = CFrame.new(tr.Position + Vector3.new(0, 0, 2.5))
    end

    pcall(function()
        Event:FireServer("Slap", closest.Character)
        slapCount += 1
        slapsVal.Text = tostring(slapCount)
    end)
end)

-- ── Notify ────────────────────────────────────────────────────────
game.StarterGui:SetCore("SendNotification", {
    Title = "⚡ SLAP SCRIPT",
    Text  = "Loaded! Toggle features in the UI.",
    Duration = 4,
})
