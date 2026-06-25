-- ════════════════════════════════════════════════════════════════════════
--  Blade Ball  |  Auto Parry  |  v1.0
--  Place ID: 13772394625
--  Requires: getnilinstances, firesignal, hookmetamethod
-- ════════════════════════════════════════════════════════════════════════

local Players    = game:GetService("Players")
local RS         = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local StarterGui = game:GetService("StarterGui")
local WS         = game:GetService("Workspace")

local LP     = Players.LocalPlayer
local Camera = WS.CurrentCamera

-- ── Config ────────────────────────────────────────────────────────────────
local CFG = {
    Enabled       = true,
    ParryDistance = 35,   -- stud radius to trigger parry
    Delay         = 0,    -- seconds to wait before firing (0 = instant)
    Notifications = true,
}

-- ── Remotes ───────────────────────────────────────────────────────────────
local Remotes      = RS:WaitForChild("Remotes")
local BallAdded    = Remotes:WaitForChild("BallAdded")
local BallExplode  = Remotes:WaitForChild("BallExplode")

-- Remote name from server info panel (Parry Remote field)
local PARRY_REMOTE_NAME = "eehbffibel9j:e9h=ec<h=i`:9:5981e"

-- ── Nil-instance helpers ──────────────────────────────────────────────────
local function GetNil(Name, DebugId)
    for _, obj in getnilinstances() do
        if obj.Name == Name and obj:GetDebugId() == DebugId then
            return obj
        end
    end
end

-- ── Notification helper ───────────────────────────────────────────────────
local function notify(title, text, duration)
    if not CFG.Notifications then return end
    pcall(function()
        StarterGui:SetCore("SendNotification", {
            Title    = title,
            Text     = text,
            Duration = duration or 3,
        })
    end)
end

-- ── Find the parry RemoteEvent ────────────────────────────────────────────
local function GetParryRemote()
    -- First try ReplicatedStorage
    for _, v in RS:GetDescendants() do
        if v:IsA("RemoteEvent") and v.Name == PARRY_REMOTE_NAME then
            return v
        end
    end
    -- Fallback: nil instances (obfuscated remotes often live there)
    for _, obj in getnilinstances() do
        if obj:IsA("RemoteEvent") and obj.Name == PARRY_REMOTE_NAME then
            return obj
        end
    end
    return nil
end

-- ── Character helpers ─────────────────────────────────────────────────────
local function getHRP()
    local char = LP.Character
    return char and char:FindFirstChild("HumanoidRootPart")
end

-- ── Active ball tracking ──────────────────────────────────────────────────
local activeBalls = {}  -- [ball] = connection

local function fireparry(ball)
    if not CFG.Enabled then return end

    local parryRemote = GetParryRemote()
    if not parryRemote then
        notify("AutoParry", "Parry remote not found!", 3)
        return
    end

    local hrp = getHRP()
    if not hrp then return end

    -- Check ball is still in workspace and close enough
    if not ball or not ball.Parent then return end
    local ballPos = ball:IsA("BasePart") and ball.Position
                    or (ball:FindFirstChildOfClass("BasePart") and ball:FindFirstChildOfClass("BasePart").Position)
    if not ballPos then return end

    local dist = (hrp.Position - ballPos).Magnitude
    if dist > CFG.ParryDistance then return end

    if CFG.Delay > 0 then
        task.wait(CFG.Delay)
    end

    -- Fire the parry remote
    pcall(function()
        parryRemote:FireServer()
    end)
end

-- ── Watch a ball for proximity ────────────────────────────────────────────
local function watchBall(ball)
    if activeBalls[ball] then return end  -- already tracking

    local conn = RunService.Heartbeat:Connect(function()
        if not CFG.Enabled then return end
        if not ball or not ball.Parent then
            if activeBalls[ball] then
                activeBalls[ball]:Disconnect()
                activeBalls[ball] = nil
            end
            return
        end

        local hrp = getHRP()
        if not hrp then return end

        local ballPart = ball:IsA("BasePart") and ball
                         or ball:FindFirstChildOfClass("BasePart")
        if not ballPart then return end

        local dist = (hrp.Position - ballPart.Position).Magnitude
        if dist <= CFG.ParryDistance then
            -- Disconnect before firing to avoid double-firing
            activeBalls[ball]:Disconnect()
            activeBalls[ball] = nil
            fireparry(ball)
        end
    end)

    activeBalls[ball] = conn
end

-- ── Listen for balls spawning ─────────────────────────────────────────────
local ballAddedConn = firesignal and true or false  -- just a capability check

-- Hook BallAdded to learn when a ball enters play
BallAdded.OnClientEvent:Connect(function(ball)
    if not ball then return end
    watchBall(ball)
end)

-- Also watch balls that already exist in workspace (rejoin case)
for _, obj in WS:GetDescendants() do
    if obj.Name == "Ball" or obj.Name == "656" then
        watchBall(obj)
    end
end
WS.DescendantAdded:Connect(function(obj)
    if obj.Name == "Ball" or obj.Name == "656" then
        watchBall(obj)
    end
end)

-- ── BallExplode: clean up tracking ───────────────────────────────────────
BallExplode.OnClientEvent:Connect(function(ball)
    if ball and activeBalls[ball] then
        activeBalls[ball]:Disconnect()
        activeBalls[ball] = nil
    end
end)

-- ── Simple GUI toggle ─────────────────────────────────────────────────────
local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name              = "BladeBallAutoParry"
ScreenGui.ResetOnSpawn      = false
ScreenGui.ZIndexBehavior    = Enum.ZIndexBehavior.Sibling
ScreenGui.IgnoreGuiInset    = true

pcall(function()
    ScreenGui.Parent = LP:WaitForChild("PlayerGui")
end)

local Frame = Instance.new("Frame", ScreenGui)
Frame.Size            = UDim2.new(0, 180, 0, 60)
Frame.Position        = UDim2.new(0, 10, 0.5, -30)
Frame.BackgroundColor3 = Color3.fromRGB(15, 15, 22)
Frame.BorderSizePixel  = 0
Instance.new("UICorner", Frame).CornerRadius = UDim.new(0, 8)

local Title = Instance.new("TextLabel", Frame)
Title.Size               = UDim2.new(1, 0, 0.45, 0)
Title.Position           = UDim2.new(0, 0, 0, 0)
Title.BackgroundTransparency = 1
Title.Text               = "⚔ Blade Ball AutoParry"
Title.TextColor3         = Color3.fromRGB(255, 255, 255)
Title.TextScaled         = true
Title.Font               = Enum.Font.GothamBold

local StatusLabel = Instance.new("TextLabel", Frame)
StatusLabel.Size               = UDim2.new(1, 0, 0.45, 0)
StatusLabel.Position           = UDim2.new(0, 0, 0.5, 0)
StatusLabel.BackgroundTransparency = 1
StatusLabel.TextScaled         = true
StatusLabel.Font               = Enum.Font.Gotham

local function updateStatus()
    if CFG.Enabled then
        StatusLabel.Text       = "Status: ON  [F] to toggle"
        StatusLabel.TextColor3 = Color3.fromRGB(52, 211, 153)
    else
        StatusLabel.Text       = "Status: OFF [F] to toggle"
        StatusLabel.TextColor3 = Color3.fromRGB(239, 68, 68)
    end
end
updateStatus()

-- ── Keybind: F to toggle ──────────────────────────────────────────────────
game:GetService("UserInputService").InputBegan:Connect(function(input, gameProcessed)
    if gameProcessed then return end
    if input.KeyCode == Enum.KeyCode.F then
        CFG.Enabled = not CFG.Enabled
        updateStatus()
        notify("AutoParry", CFG.Enabled and "Enabled" or "Disabled", 2)
    end
end)

notify("AutoParry", "Blade Ball AutoParry loaded! Press [F] to toggle.", 5)
