-- ════════════════════════════════════════════════════════════════════════
--  Blade Ball  |  Auto Parry  v2.1  |  Place ID: 13772394625
--  Requires: getnilinstances, getconnections, hookfunction,
--            getcallbackvalue, hookmetamethod
-- ════════════════════════════════════════════════════════════════════════

local Players      = game:GetService("Players")
local RS           = game:GetService("ReplicatedStorage")
local RunService   = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local UIS          = game:GetService("UserInputService")
local WS           = game:GetService("Workspace")

local LP = Players.LocalPlayer

-- ── Config ────────────────────────────────────────────────────────────────
local CFG = {
    Enabled       = true,
    ParryDistance = 35,
    Delay         = 0,
}

-- ── Live state ────────────────────────────────────────────────────────────
local State = {
    ParryCount   = 0,
    LastParryAt  = 0,
    BallDist     = math.huge,
    ActiveBalls  = {},
    Standoff     = false,
    LastWinner   = "",
    LastMessage  = "",
}

-- ── Remotes ───────────────────────────────────────────────────────────────
local Remotes         = RS:WaitForChild("Remotes")
local Shared          = RS:WaitForChild("Shared")
local BallAdded       = Remotes:WaitForChild("BallAdded")
local BallExplode     = Remotes:WaitForChild("BallExplode")
local ParrySuccessAll = Remotes:WaitForChild("ParrySuccessAll")
local StandoffStart   = Remotes:WaitForChild("StandoffStart")
local WinnerText      = Remotes:WaitForChild("WinnerText")
local SetMessage      = Remotes:WaitForChild("SetMessage")
local ConfidentTarget = Remotes:WaitForChild("ConfidentTarget")
local RemotePing      = Shared:WaitForChild("Ping"):WaitForChild("RemotePing")

-- ── Anti-cheat bypass: keep RemotePing working transparently ─────────────
do
    local Callback = getcallbackvalue(RemotePing, "OnClientInvoke")
    RemotePing.OnClientInvoke = function(...)
        local args = table.pack(...)
        return table.unpack(table.pack(Callback(table.unpack(args, 1, args.n))), 1)
    end
    local mtHook; mtHook = hookmetamethod(game, "__newindex", function(self, key, value, ...)
        if rawequal(self, RemotePing) and rawequal(key, "OnClientInvoke")
           and typeof(value) == "function" and not checkcaller() then
            Callback = value
            return
        end
        return mtHook(self, key, value, ...)
    end)
end

-- ── Hook ParrySuccessAll to count confirmed parries ───────────────────────
for _, conn in getconnections(ParrySuccessAll.OnClientEvent) do
    local old; old = hookfunction(conn.Function, function(...)
        State.ParryCount  = State.ParryCount + 1
        State.LastParryAt = tick()
        return old(...)
    end)
end

-- ── ConfidentTarget: only arm parry when WE are the target ───────────────
State.IsTarget = false
State.TargetName = ""

for _, conn in getconnections(ConfidentTarget.OnClientEvent) do
    local old; old = hookfunction(conn.Function, function(...)
        local args = {...}
        -- arg 1 is typically the targeted Player object
        local target = args[1]
        if typeof(target) == "Instance" and target:IsA("Player") then
            State.IsTarget   = (target == LP)
            State.TargetName = target.DisplayName or target.Name
        end
        return old(...)
    end)
end

-- ── StandoffStart: widen range since ball accelerates ────────────────────
local NORMAL_DIST   = CFG.ParryDistance
local STANDOFF_DIST = CFG.ParryDistance + 20

StandoffStart.OnClientEvent:Connect(function()
    State.Standoff    = true
    CFG.ParryDistance = STANDOFF_DIST
end)

-- ── WinnerText: round ended — reset standoff ────────────────────────────
for _, conn in getconnections(WinnerText.OnClientEvent) do
    local old; old = hookfunction(conn.Function, function(...)
        local args = {...}
        State.LastWinner  = tostring(args[1] or "")
        State.Standoff    = false
        CFG.ParryDistance = NORMAL_DIST
        State.IsTarget    = false
        State.TargetName  = ""
        return old(...)
    end)
end

-- ── SetMessage: capture game status messages ──────────────────────────────
for _, conn in getconnections(SetMessage.OnClientEvent) do
    local old; old = hookfunction(conn.Function, function(...)
        local args = {...}
        State.LastMessage = tostring(args[1] or "")
        return old(...)
    end)
end

-- ── Parry remote (from server info panel) ────────────────────────────────
local PARRY_REMOTE = "eehbffibel9j:e9h=ec<h=i`:9:5981e"

local function getParryRemote()
    for _, v in RS:GetDescendants() do
        if v:IsA("RemoteEvent") and v.Name == PARRY_REMOTE then return v end
    end
    for _, v in getnilinstances() do
        if v:IsA("RemoteEvent") and v.Name == PARRY_REMOTE then return v end
    end
end

-- ── Character ────────────────────────────────────────────────────────────
local function getHRP()
    local c = LP.Character
    return c and c:FindFirstChild("HumanoidRootPart")
end

-- ── Parry fire ────────────────────────────────────────────────────────────
local function doParry(ball)
    if not CFG.Enabled then return end
    -- Skip if ball is confirmed targeting someone else
    if not State.IsTarget and State.TargetName ~= "" then return end
    local remote = getParryRemote()
    if not remote then return end
    local hrp = getHRP()
    if not hrp then return end
    if not ball or not ball.Parent then return end
    local part = ball:IsA("BasePart") and ball or ball:FindFirstChildOfClass("BasePart")
    if not part then return end
    if (hrp.Position - part.Position).Magnitude > CFG.ParryDistance then return end
    if CFG.Delay > 0 then task.wait(CFG.Delay) end
    pcall(function() remote:FireServer() end)
end

-- ── Ball tracking ─────────────────────────────────────────────────────────
local function watchBall(ball)
    if State.ActiveBalls[ball] then return end

    local conn = RunService.Heartbeat:Connect(function()
        if not ball or not ball.Parent then
            if State.ActiveBalls[ball] then
                State.ActiveBalls[ball]:Disconnect()
                State.ActiveBalls[ball] = nil
                State.BallDist = math.huge
            end
            return
        end
        local hrp = getHRP()
        if not hrp then return end
        local part = ball:IsA("BasePart") and ball or ball:FindFirstChildOfClass("BasePart")
        if not part then return end
        local dist = (hrp.Position - part.Position).Magnitude
        State.BallDist = dist
        if CFG.Enabled and dist <= CFG.ParryDistance then
            State.ActiveBalls[ball]:Disconnect()
            State.ActiveBalls[ball] = nil
            State.BallDist = math.huge
            doParry(ball)
        end
    end)

    State.ActiveBalls[ball] = conn
end

BallAdded.OnClientEvent:Connect(function(ball)
    if ball then watchBall(ball) end
end)

BallExplode.OnClientEvent:Connect(function(ball)
    if ball and State.ActiveBalls[ball] then
        State.ActiveBalls[ball]:Disconnect()
        State.ActiveBalls[ball] = nil
        State.BallDist = math.huge
    end
end)

for _, obj in WS:GetDescendants() do
    if obj.Name == "Ball" or obj.Name == "656" then watchBall(obj) end
end
WS.DescendantAdded:Connect(function(obj)
    if obj.Name == "Ball" or obj.Name == "656" then watchBall(obj) end
end)

-- ════════════════════════════════════════════════════════════════════════
--  UI
-- ════════════════════════════════════════════════════════════════════════

local C = {
    BG     = Color3.fromRGB(9,   9,   15),
    PANEL  = Color3.fromRGB(16,  16,  26),
    CARD   = Color3.fromRGB(22,  22,  36),
    BORDER = Color3.fromRGB(38,  40,  62),
    ACCENT = Color3.fromRGB(110, 70,  255),
    ACCENT2= Color3.fromRGB(160, 100, 255),
    CYAN   = Color3.fromRGB(0,   210, 230),
    GREEN  = Color3.fromRGB(52,  211, 153),
    RED    = Color3.fromRGB(239, 68,  68),
    ORANGE = Color3.fromRGB(251, 146, 60),
    WHITE  = Color3.fromRGB(255, 255, 255),
    OFFWH  = Color3.fromRGB(205, 210, 230),
    MUTED  = Color3.fromRGB(95,  100, 135),
    YELLOW = Color3.fromRGB(255, 215, 50),
}

local TI_FAST = TweenInfo.new(0.18, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
local TI_MED  = TweenInfo.new(0.3,  Enum.EasingStyle.Quad, Enum.EasingDirection.Out)

local function tw(obj, props, speed)
    TweenService:Create(obj, speed or TI_FAST, props):Play()
end

local function corner(p, r)
    local c = Instance.new("UICorner", p); c.CornerRadius = UDim.new(0, r or 8); return c
end

local function pad(p, t, b, l, r)
    local u = Instance.new("UIPadding", p)
    u.PaddingTop = UDim.new(0, t or 0); u.PaddingBottom = UDim.new(0, b or 0)
    u.PaddingLeft= UDim.new(0, l or 0); u.PaddingRight  = UDim.new(0, r or 0)
end

local function vlist(p, spacing)
    local l = Instance.new("UIListLayout", p)
    l.SortOrder = Enum.SortOrder.LayoutOrder
    l.Padding   = UDim.new(0, spacing or 0)
    return l
end

local function divider(p, order)
    local d = Instance.new("Frame", p)
    d.Size = UDim2.new(1, 0, 0, 1); d.BackgroundColor3 = C.BORDER
    d.BorderSizePixel = 0; d.LayoutOrder = order
end

-- ── ScreenGui ─────────────────────────────────────────────────────────────
local SG = Instance.new("ScreenGui")
SG.Name = "BB_AutoParry_v2"; SG.ResetOnSpawn = false
SG.ZIndexBehavior = Enum.ZIndexBehavior.Sibling; SG.IgnoreGuiInset = true
pcall(function() SG.Parent = LP:WaitForChild("PlayerGui") end)

-- ── Window ────────────────────────────────────────────────────────────────
local Win = Instance.new("Frame", SG)
Win.Name = "Window"
Win.Size = UDim2.new(0, 248, 0, 0)
Win.Position = UDim2.new(0, 16, 0.5, -110)
Win.BackgroundColor3 = C.BG
Win.BorderSizePixel = 0
Win.AutomaticSize = Enum.AutomaticSize.Y
Win.ClipsDescendants = true
corner(Win, 14)

local WinStroke = Instance.new("UIStroke", Win)
WinStroke.Color = C.ACCENT; WinStroke.Thickness = 1.5; WinStroke.Transparency = 0.35

vlist(Win, 0)

-- ── Header bar ────────────────────────────────────────────────────────────
local Header = Instance.new("Frame", Win)
Header.Name = "Header"; Header.LayoutOrder = 1
Header.Size = UDim2.new(1, 0, 0, 44)
Header.BackgroundColor3 = C.ACCENT
Header.BorderSizePixel = 0
corner(Header, 14)

-- Mask bottom-radius of header
local HMask = Instance.new("Frame", Header)
HMask.Size = UDim2.new(1, 0, 0.5, 0)
HMask.Position = UDim2.new(0, 0, 0.5, 0)
HMask.BackgroundColor3 = C.ACCENT; HMask.BorderSizePixel = 0

-- Gradient on header
local HGrad = Instance.new("UIGradient", Header)
HGrad.Color = ColorSequence.new({
    ColorSequenceKeypoint.new(0, C.ACCENT2),
    ColorSequenceKeypoint.new(1, C.ACCENT),
})
HGrad.Rotation = 90

local HIcon = Instance.new("TextLabel", Header)
HIcon.Size = UDim2.new(0, 30, 1, 0); HIcon.Position = UDim2.new(0, 10, 0, 0)
HIcon.BackgroundTransparency = 1; HIcon.Text = "⚔"
HIcon.TextColor3 = C.WHITE; HIcon.Font = Enum.Font.GothamBold; HIcon.TextSize = 18

local HTitle = Instance.new("TextLabel", Header)
HTitle.Size = UDim2.new(1, -80, 1, 0); HTitle.Position = UDim2.new(0, 38, 0, 0)
HTitle.BackgroundTransparency = 1; HTitle.Text = "BLADE BALL  AUTO PARRY"
HTitle.TextColor3 = C.WHITE; HTitle.Font = Enum.Font.GothamBold; HTitle.TextSize = 12
HTitle.TextXAlignment = Enum.TextXAlignment.Left

local HVer = Instance.new("TextLabel", Header)
HVer.Size = UDim2.new(0, 32, 1, 0); HVer.Position = UDim2.new(1, -38, 0, 0)
HVer.BackgroundTransparency = 1; HVer.Text = "v2.0"
HVer.TextColor3 = Color3.fromRGB(200, 170, 255); HVer.Font = Enum.Font.Gotham; HVer.TextSize = 10
HVer.Text = "v2.1"
HVer.TextXAlignment = Enum.TextXAlignment.Right

-- ── Status section ────────────────────────────────────────────────────────
local StatusSec = Instance.new("Frame", Win)
StatusSec.Name = "Status"; StatusSec.LayoutOrder = 2
StatusSec.Size = UDim2.new(1, 0, 0, 42)
StatusSec.BackgroundColor3 = C.PANEL; StatusSec.BorderSizePixel = 0
pad(StatusSec, 0, 0, 14, 14)

local SDot = Instance.new("Frame", StatusSec)
SDot.Size = UDim2.new(0, 10, 0, 10); SDot.Position = UDim2.new(0, 0, 0.5, -5)
SDot.BackgroundColor3 = C.GREEN; SDot.BorderSizePixel = 0; corner(SDot, 5)

-- Pulse effect on dot
local PulseFrame = Instance.new("Frame", SDot)
PulseFrame.Size = UDim2.new(2, 0, 2, 0); PulseFrame.Position = UDim2.new(-0.5, 0, -0.5, 0)
PulseFrame.BackgroundColor3 = C.GREEN; PulseFrame.BackgroundTransparency = 0.6
PulseFrame.BorderSizePixel = 0; corner(PulseFrame, 10)

local function pulseDot()
    local t1 = TweenService:Create(PulseFrame, TweenInfo.new(0.8, Enum.EasingStyle.Sine), {
        Size = UDim2.new(3.5, 0, 3.5, 0),
        Position = UDim2.new(-1.25, 0, -1.25, 0),
        BackgroundTransparency = 1,
    })
    local t2 = TweenService:Create(PulseFrame, TweenInfo.new(0, Enum.EasingStyle.Linear), {
        Size = UDim2.new(2, 0, 2, 0),
        Position = UDim2.new(-0.5, 0, -0.5, 0),
        BackgroundTransparency = 0.6,
    })
    t1.Completed:Connect(function() t2:Play() end)
    t1:Play()
end
task.spawn(function()
    while true do pulseDot(); task.wait(1.2) end
end)

local SLabel = Instance.new("TextLabel", StatusSec)
SLabel.Size = UDim2.new(0, 150, 1, 0); SLabel.Position = UDim2.new(0, 18, 0, 0)
SLabel.BackgroundTransparency = 1; SLabel.Text = "AUTO PARRY ACTIVE"
SLabel.TextColor3 = C.GREEN; SLabel.Font = Enum.Font.GothamBold; SLabel.TextSize = 12
SLabel.TextXAlignment = Enum.TextXAlignment.Left

local SKB = Instance.new("TextLabel", StatusSec)
SKB.Size = UDim2.new(0, 50, 1, 0); SKB.Position = UDim2.new(1, -50, 0, 0)
SKB.BackgroundTransparency = 1; SKB.Text = "[F]"
SKB.TextColor3 = C.MUTED; SKB.Font = Enum.Font.GothamBold; SKB.TextSize = 11
SKB.TextXAlignment = Enum.TextXAlignment.Right

divider(Win, 3)

-- ── Ball tracker section ──────────────────────────────────────────────────
local BallSec = Instance.new("Frame", Win)
BallSec.Name = "BallTracker"; BallSec.LayoutOrder = 4
BallSec.Size = UDim2.new(1, 0, 0, 0); BallSec.AutomaticSize = Enum.AutomaticSize.Y
BallSec.BackgroundColor3 = C.PANEL; BallSec.BorderSizePixel = 0
vlist(BallSec, 6); pad(BallSec, 10, 12, 14, 14)

local BallHeader = Instance.new("Frame", BallSec)
BallHeader.Size = UDim2.new(1, 0, 0, 14); BallHeader.BackgroundTransparency = 1
BallHeader.LayoutOrder = 1

local BallLbl = Instance.new("TextLabel", BallHeader)
BallLbl.Size = UDim2.new(0.5, 0, 1, 0); BallLbl.BackgroundTransparency = 1
BallLbl.Text = "BALL DISTANCE"; BallLbl.TextColor3 = C.MUTED
BallLbl.Font = Enum.Font.GothamBold; BallLbl.TextSize = 10
BallLbl.TextXAlignment = Enum.TextXAlignment.Left

local BallVal = Instance.new("TextLabel", BallHeader)
BallVal.Size = UDim2.new(0.5, 0, 1, 0); BallVal.Position = UDim2.new(0.5, 0, 0, 0)
BallVal.BackgroundTransparency = 1; BallVal.Text = "---"
BallVal.TextColor3 = C.OFFWH; BallVal.Font = Enum.Font.GothamBold; BallVal.TextSize = 10
BallVal.TextXAlignment = Enum.TextXAlignment.Right

-- Progress track
local Track = Instance.new("Frame", BallSec)
Track.Size = UDim2.new(1, 0, 0, 10); Track.BackgroundColor3 = C.CARD
Track.BorderSizePixel = 0; Track.LayoutOrder = 2; Track.ClipsDescendants = true
corner(Track, 5)

local Fill = Instance.new("Frame", Track)
Fill.Size = UDim2.new(0, 0, 1, 0); Fill.BackgroundColor3 = C.CYAN
Fill.BorderSizePixel = 0; corner(Fill, 5)

local FillGrad = Instance.new("UIGradient", Fill)
FillGrad.Color = ColorSequence.new({
    ColorSequenceKeypoint.new(0, Color3.fromRGB(0, 200, 255)),
    ColorSequenceKeypoint.new(1, Color3.fromRGB(0, 240, 200)),
})
FillGrad.Rotation = 0

-- Range label under bar
local RangeLbl = Instance.new("TextLabel", BallSec)
RangeLbl.Size = UDim2.new(1, 0, 0, 11); RangeLbl.BackgroundTransparency = 1
RangeLbl.Text = "Parry range: " .. CFG.ParryDistance .. " studs"
RangeLbl.TextColor3 = C.MUTED; RangeLbl.Font = Enum.Font.Gotham; RangeLbl.TextSize = 10
RangeLbl.TextXAlignment = Enum.TextXAlignment.Right; RangeLbl.LayoutOrder = 3

divider(Win, 5)

-- ── Stats section ─────────────────────────────────────────────────────────
local StatSec = Instance.new("Frame", Win)
StatSec.Name = "Stats"; StatSec.LayoutOrder = 6
StatSec.Size = UDim2.new(1, 0, 0, 0); StatSec.AutomaticSize = Enum.AutomaticSize.Y
StatSec.BackgroundColor3 = C.PANEL; StatSec.BorderSizePixel = 0
vlist(StatSec, 4); pad(StatSec, 10, 10, 14, 14)

local function statRow(parent, order, icon, label)
    local row = Instance.new("Frame", parent)
    row.Size = UDim2.new(1, 0, 0, 18); row.BackgroundTransparency = 1; row.LayoutOrder = order

    local card = Instance.new("Frame", row)
    card.Size = UDim2.new(1, 0, 1, 0); card.BackgroundColor3 = C.CARD
    card.BorderSizePixel = 0; corner(card, 6)
    pad(card, 0, 0, 8, 8)

    local iLbl = Instance.new("TextLabel", card)
    iLbl.Size = UDim2.new(0, 18, 1, 0); iLbl.BackgroundTransparency = 1
    iLbl.Text = icon; iLbl.TextColor3 = C.ACCENT2
    iLbl.Font = Enum.Font.GothamBold; iLbl.TextSize = 12

    local tLbl = Instance.new("TextLabel", card)
    tLbl.Size = UDim2.new(0.5, -18, 1, 0); tLbl.Position = UDim2.new(0, 20, 0, 0)
    tLbl.BackgroundTransparency = 1; tLbl.Text = label
    tLbl.TextColor3 = C.MUTED; tLbl.Font = Enum.Font.Gotham; tLbl.TextSize = 10
    tLbl.TextXAlignment = Enum.TextXAlignment.Left

    local vLbl = Instance.new("TextLabel", card)
    vLbl.Size = UDim2.new(0.5, 0, 1, 0); vLbl.Position = UDim2.new(0.5, 0, 0, 0)
    vLbl.BackgroundTransparency = 1; vLbl.Text = "—"
    vLbl.TextColor3 = C.OFFWH; vLbl.Font = Enum.Font.GothamBold; vLbl.TextSize = 10
    vLbl.TextXAlignment = Enum.TextXAlignment.Right

    return vLbl
end

local V_Parries  = statRow(StatSec, 1, "↯", "PARRIES (SERVER)")
local V_Last     = statRow(StatSec, 2, "◷", "LAST PARRY")
local V_Target   = statRow(StatSec, 3, "◉", "BALL TARGET")
local V_Standoff = statRow(StatSec, 4, "⚡", "STANDOFF")
local V_Range    = statRow(StatSec, 5, "◎", "PARRY RANGE")
local V_Delay    = statRow(StatSec, 6, "⏱", "FIRE DELAY")
local V_Message  = statRow(StatSec, 7, "✉", "GAME STATUS")

divider(Win, 7)

-- ── Toggle button ─────────────────────────────────────────────────────────
local ToggleSec = Instance.new("Frame", Win)
ToggleSec.Name = "ToggleSec"; ToggleSec.LayoutOrder = 8
ToggleSec.Size = UDim2.new(1, 0, 0, 0); ToggleSec.AutomaticSize = Enum.AutomaticSize.Y
ToggleSec.BackgroundColor3 = C.PANEL; ToggleSec.BorderSizePixel = 0
pad(ToggleSec, 10, 10, 12, 12)

local Btn = Instance.new("TextButton", ToggleSec)
Btn.Size = UDim2.new(1, 0, 0, 34)
Btn.BackgroundColor3 = C.GREEN; Btn.BorderSizePixel = 0
Btn.Text = "⏸  DISABLE  AUTO PARRY"
Btn.TextColor3 = Color3.fromRGB(5, 20, 15)
Btn.Font = Enum.Font.GothamBold; Btn.TextSize = 12
corner(Btn, 8)

local BtnGrad = Instance.new("UIGradient", Btn)
BtnGrad.Color = ColorSequence.new({
    ColorSequenceKeypoint.new(0, Color3.fromRGB(80, 230, 170)),
    ColorSequenceKeypoint.new(1, Color3.fromRGB(40, 190, 140)),
})
BtnGrad.Rotation = 90

-- ── Update toggle UI ──────────────────────────────────────────────────────
local function setToggleUI(enabled)
    if enabled then
        tw(Btn, { BackgroundColor3 = C.GREEN }, TI_MED)
        tw(SDot, { BackgroundColor3 = C.GREEN }, TI_MED)
        tw(PulseFrame, { BackgroundColor3 = C.GREEN }, TI_MED)
        tw(SLabel, { TextColor3 = C.GREEN }, TI_MED)
        tw(WinStroke, { Color = C.ACCENT }, TI_MED)
        BtnGrad.Color = ColorSequence.new({
            ColorSequenceKeypoint.new(0, Color3.fromRGB(80, 230, 170)),
            ColorSequenceKeypoint.new(1, Color3.fromRGB(40, 190, 140)),
        })
        Btn.Text = "⏸  DISABLE  AUTO PARRY"
        Btn.TextColor3 = Color3.fromRGB(5, 20, 15)
        SLabel.Text = "AUTO PARRY ACTIVE"
    else
        tw(Btn, { BackgroundColor3 = C.RED }, TI_MED)
        tw(SDot, { BackgroundColor3 = C.RED }, TI_MED)
        tw(PulseFrame, { BackgroundColor3 = C.RED }, TI_MED)
        tw(SLabel, { TextColor3 = C.RED }, TI_MED)
        tw(WinStroke, { Color = C.RED }, TI_MED)
        BtnGrad.Color = ColorSequence.new({
            ColorSequenceKeypoint.new(0, Color3.fromRGB(255, 100, 100)),
            ColorSequenceKeypoint.new(1, Color3.fromRGB(200, 50, 50)),
        })
        Btn.Text = "▶  ENABLE   AUTO PARRY"
        Btn.TextColor3 = Color3.fromRGB(255, 220, 220)
        SLabel.Text = "AUTO PARRY PAUSED"
    end
end

Btn.MouseButton1Click:Connect(function()
    CFG.Enabled = not CFG.Enabled
    setToggleUI(CFG.Enabled)
end)

Btn.MouseEnter:Connect(function()
    tw(Btn, { BackgroundTransparency = 0.15 })
end)
Btn.MouseLeave:Connect(function()
    tw(Btn, { BackgroundTransparency = 0 })
end)

UIS.InputBegan:Connect(function(inp, gp)
    if gp then return end
    if inp.KeyCode == Enum.KeyCode.F then
        CFG.Enabled = not CFG.Enabled
        setToggleUI(CFG.Enabled)
    end
end)

-- ── Drag ─────────────────────────────────────────────────────────────────
do
    local dragging, ds, sp
    Header.InputBegan:Connect(function(inp)
        if inp.UserInputType == Enum.UserInputType.MouseButton1 then
            dragging = true; ds = inp.Position; sp = Win.Position
        end
    end)
    Header.InputEnded:Connect(function(inp)
        if inp.UserInputType == Enum.UserInputType.MouseButton1 then dragging = false end
    end)
    UIS.InputChanged:Connect(function(inp)
        if dragging and inp.UserInputType == Enum.UserInputType.MouseMovement then
            local d = inp.Position - ds
            Win.Position = UDim2.new(sp.X.Scale, sp.X.Offset + d.X, sp.Y.Scale, sp.Y.Offset + d.Y)
        end
    end)
end

-- ── Winner banner (shown briefly after each round) ────────────────────────
local WinBanner = Instance.new("Frame", SG)
WinBanner.Size = UDim2.new(0, 240, 0, 36); WinBanner.AnchorPoint = Vector2.new(0.5, 0)
WinBanner.Position = UDim2.new(0.5, 0, 0, 20)
WinBanner.BackgroundColor3 = C.ACCENT; WinBanner.BorderSizePixel = 0
WinBanner.BackgroundTransparency = 1; corner(WinBanner, 10)
local WBGrad = Instance.new("UIGradient", WinBanner)
WBGrad.Color = ColorSequence.new({
    ColorSequenceKeypoint.new(0, C.ACCENT2),
    ColorSequenceKeypoint.new(1, C.ACCENT),
}); WBGrad.Rotation = 90
local WBTxt = Instance.new("TextLabel", WinBanner)
WBTxt.Size = UDim2.new(1, 0, 1, 0); WBTxt.BackgroundTransparency = 1
WBTxt.Text = ""; WBTxt.TextColor3 = C.WHITE
WBTxt.Font = Enum.Font.GothamBold; WBTxt.TextSize = 13

local function showWinner(name)
    WBTxt.Text = "Winner: " .. name
    WinBanner.BackgroundTransparency = 0
    task.delay(4, function()
        tw(WinBanner, { BackgroundTransparency = 1 }, TI_MED)
    end)
end

-- Hook into winner state change to trigger the banner
local _prevWinner = ""
RunService.Heartbeat:Connect(function()
    if State.LastWinner ~= _prevWinner and State.LastWinner ~= "" then
        _prevWinner = State.LastWinner
        showWinner(State.LastWinner)
    end
end)

-- ── AFK bypass: suppress the AFK FireServer call ──────────────────────────
pcall(function()
    local AFKEvent = game:GetService("GamepadService").AFK
    local afkHook; afkHook = hookmetamethod(game, "__namecall", function(self, ...)
        if rawequal(self, AFKEvent) and getnamecallmethod() == "FireServer" then
            return  -- suppress AFK report to server
        end
        return afkHook(self, ...)
    end)
end)

-- ── HUD refresh ───────────────────────────────────────────────────────────
RunService.Heartbeat:Connect(function()
    local dist = State.BallDist

    if dist == math.huge then
        BallVal.Text       = "no ball"
        BallVal.TextColor3 = C.MUTED
        tw(Fill, { Size = UDim2.new(0, 0, 1, 0) })
        tw(Fill, { BackgroundColor3 = C.CYAN })
    else
        local d = math.floor(dist * 10) / 10
        BallVal.Text = d .. " st"
        local ratio = math.clamp(1 - (dist / CFG.ParryDistance), 0, 1)
        tw(Fill, { Size = UDim2.new(ratio, 0, 1, 0) })
        if ratio >= 0.8 then
            BallVal.TextColor3 = C.RED
            tw(Fill, { BackgroundColor3 = C.RED })
        elseif ratio >= 0.5 then
            BallVal.TextColor3 = C.ORANGE
            tw(Fill, { BackgroundColor3 = C.ORANGE })
        else
            BallVal.TextColor3 = C.CYAN
            tw(Fill, { BackgroundColor3 = C.CYAN })
        end
    end

    -- Standoff ring-stroke flash
    if State.Standoff then
        tw(WinStroke, { Color = C.RED, Thickness = 2.5 }, TI_MED)
    elseif CFG.Enabled then
        tw(WinStroke, { Color = C.ACCENT, Thickness = 1.5 }, TI_MED)
    end

    V_Parries.Text = tostring(State.ParryCount)
    if State.LastParryAt > 0 then
        V_Last.Text = string.format("%.1fs ago", tick() - State.LastParryAt)
    end

    -- Target display
    if State.TargetName == "" then
        V_Target.Text      = "—"
        V_Target.TextColor3 = C.MUTED
    elseif State.IsTarget then
        V_Target.Text      = "YOU !"
        V_Target.TextColor3 = C.RED
    else
        V_Target.Text      = State.TargetName
        V_Target.TextColor3 = C.OFFWH
    end

    -- Standoff display
    if State.Standoff then
        V_Standoff.Text      = "ACTIVE"
        V_Standoff.TextColor3 = C.RED
    else
        V_Standoff.Text      = "off"
        V_Standoff.TextColor3 = C.MUTED
    end

    V_Range.Text  = CFG.ParryDistance .. " st"
    V_Delay.Text  = CFG.Delay == 0 and "instant" or (CFG.Delay .. "s")
    V_Message.Text = State.LastMessage ~= "" and State.LastMessage or "—"
    V_Message.TextColor3 = State.LastMessage ~= "" and C.YELLOW or C.MUTED
end)
