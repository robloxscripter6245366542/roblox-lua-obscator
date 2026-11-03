--!nocheck
--[[
============================================================================
 BladeBall_AutoParry.lua  —  "Blade Ball Hub" auto-parry
============================================================================
 A self-contained auto-parry / auto-deflect for the Roblox game "Blade Ball".

 HOW BLADE BALL WORKS (the bits this script relies on)
 ---------------------------------------------------------------------------
  * The active ball(s) live in a workspace folder, usually `workspace.Balls`.
    Each ball is a BasePart moving toward whichever player it currently
    targets. A ball carries attributes that name its target and mark it as
    the "real" (dangerous) ball vs. a decoy:
        Ball:GetAttribute("target")    -> targeted player's Name (string)
        Ball:GetAttribute("realBall")  -> true for the live ball
    (Older/renamed builds vary, so we discover these defensively.)
  * You survive by *parrying* just before the ball reaches you. In game the
    parry is a keypress (default F) or a click. This script triggers a parry
    the instant the ball is inside a speed/ping-adjusted radius of you.

 PARRY DELIVERY (two independent paths, both attempted)
 ---------------------------------------------------------------------------
  1. Remote path   : scan ReplicatedStorage for a RemoteEvent/Function whose
                     name looks like a parry ("parry"/"deflect"/"ball") and
                     fire it. Survives most key-rebinding updates.
  2. Keypress path : VirtualInputManager taps the configured parry key
                     (default F). Universal fallback when the remote name has
                     drifted or isn't exposed.
  Both are cheap and idempotent within a cooldown, so we fire both.

 FEATURES
 ---------------------------------------------------------------------------
  * Auto Parry with distance + ping-based prediction (parries earlier the
    faster the ball / the higher your ping, so high-latency clients still hit)
  * "Only when targeted" mode (ignores balls aimed at other players)
  * Adjustable parry radius, ping offset, and per-parry cooldown
  * Configurable parry key
  * Self-contained draggable UI (PC + mobile), auto-saving config
  * Clean teardown (single toggle re-runs safely; leaves no dangling binds)
============================================================================
]]

-- ── Services ─────────────────────────────────────────────────────────────
local Players             = game:GetService("Players")
local RunService          = game:GetService("RunService")
local UserInputService    = game:GetService("UserInputService")
local VirtualInputManager  = game:GetService("VirtualInputManager")
local ReplicatedStorage   = game:GetService("ReplicatedStorage")
local Stats               = game:GetService("Stats")
local HttpService         = game:GetService("HttpService")

local LocalPlayer = Players.LocalPlayer
local Camera      = workspace.CurrentCamera

-- ── Config & persistence ─────────────────────────────────────────────────
local ConfigFile = "BladeBall_AutoParry.json"

local Settings = {
    AutoParry       = true,
    OnlyWhenTargeted = true,   -- ignore balls not aimed at you
    ParryRadius     = 22,      -- studs; base trigger distance (before ping scaling)
    PingOffset      = 0.0,     -- extra seconds of lead added on top of measured ping
    Cooldown        = 0.12,    -- min seconds between parries (anti-spam)
    ParryKey        = "F",     -- keypress fallback
    UseRemote       = true,    -- try the discovered parry remote
    UseKeypress     = true,    -- try the VirtualInputManager keypress
    ShowStatus      = true,    -- on-screen status line
}

local function loadConfig()
    if not (isfile and readfile and isfile(ConfigFile)) then return end
    local ok, data = pcall(function() return HttpService:JSONDecode(readfile(ConfigFile)) end)
    if ok and type(data) == "table" then
        for k, v in pairs(data) do
            if Settings[k] ~= nil then Settings[k] = v end
        end
    end
end

local function saveConfig()
    if not writefile then return end
    pcall(function() writefile(ConfigFile, HttpService:JSONEncode(Settings)) end)
end

loadConfig()

-- ── Bookkeeping / teardown ───────────────────────────────────────────────
local connections = {}
local function track(conn) connections[#connections + 1] = conn; return conn end

-- If a previous instance of this script is running, tell it to stop.
if _G.__BladeBallAutoParry and _G.__BladeBallAutoParry.stop then
    pcall(_G.__BladeBallAutoParry.stop)
end
local self = {}
_G.__BladeBallAutoParry = self

-- ── Character helpers ────────────────────────────────────────────────────
local function getRoot()
    local char = LocalPlayer.Character
    if not char then return nil end
    return char:FindFirstChild("HumanoidRootPart") or char.PrimaryPart
end

-- ── Ball discovery ───────────────────────────────────────────────────────
-- Blade Ball keeps balls in `workspace.Balls`, but renamed forks exist. We
-- resolve the folder once, then re-resolve lazily if it goes missing.
local BALL_FOLDER_NAMES = { "Balls", "Ball", "GameBalls", "BallsFolder" }

local function findBallFolder()
    for _, name in ipairs(BALL_FOLDER_NAMES) do
        local f = workspace:FindFirstChild(name)
        if f then return f end
    end
    -- Fallback: any folder in workspace that contains a part with a "target"
    -- attribute is almost certainly the ball container.
    for _, child in ipairs(workspace:GetChildren()) do
        if child:IsA("Folder") then
            for _, p in ipairs(child:GetChildren()) do
                if p:IsA("BasePart") and p:GetAttribute("target") ~= nil then
                    return child
                end
            end
        end
    end
    return nil
end

-- Read the target-player name off a ball across attribute-name variants.
local function ballTargetName(ball)
    return ball:GetAttribute("target")
        or ball:GetAttribute("Target")
        or ball:GetAttribute("targetPlayer")
end

-- Is this ball the "real"/live one (not a decoy)? Absent attribute => treat
-- as real so we never ignore a genuine threat on renamed builds.
local function isRealBall(ball)
    local v = ball:GetAttribute("realBall")
    if v == nil then v = ball:GetAttribute("RealBall") end
    if v == nil then return true end
    return v == true
end

-- The current speed of a ball (studs/s), from physics or a speed attribute.
local function ballSpeed(ball)
    local ok, v = pcall(function() return ball.AssemblyLinearVelocity.Magnitude end)
    if ok and v and v > 0 then return v end
    return ball:GetAttribute("speed") or ball:GetAttribute("Speed") or 0
end

-- ── Parry-remote discovery ───────────────────────────────────────────────
-- Cache the first RemoteEvent/Function whose name reads like a parry.
local parryRemote = nil
local function discoverParryRemote()
    if parryRemote and parryRemote.Parent then return parryRemote end
    parryRemote = nil
    local best
    for _, obj in ipairs(ReplicatedStorage:GetDescendants()) do
        if obj:IsA("RemoteEvent") or obj:IsA("RemoteFunction") then
            local n = string.lower(obj.Name)
            if n:find("parry") or n:find("deflect") then
                best = obj; break                       -- strongest signal
            elseif not best and (n:find("ball") and (n:find("press") or n:find("hit") or n:find("swing"))) then
                best = obj                              -- weaker candidate
            end
        end
    end
    parryRemote = best
    return parryRemote
end

-- ── Parry firing ─────────────────────────────────────────────────────────
local function parryKeyCode()
    local name = tostring(Settings.ParryKey or "F"):upper()
    return Enum.KeyCode[name] or Enum.KeyCode.F
end

local function fireParry()
    if Settings.UseRemote then
        local remote = discoverParryRemote()
        if remote then
            pcall(function()
                if remote:IsA("RemoteEvent") then
                    remote:FireServer()
                else
                    remote:InvokeServer()
                end
            end)
        end
    end
    if Settings.UseKeypress then
        local kc = parryKeyCode()
        pcall(function()
            VirtualInputManager:SendKeyEvent(true,  kc, false, game)
            VirtualInputManager:SendKeyEvent(false, kc, false, game)
        end)
    end
end

-- ── Ping (seconds) ───────────────────────────────────────────────────────
local function pingSeconds()
    local ok, ms = pcall(function()
        return Stats.Network.ServerStatsItem["Data Ping"]:GetValue()
    end)
    if ok and ms then return ms / 1000 end
    return 0
end

-- ── Core loop ────────────────────────────────────────────────────────────
local lastParry = 0
local status = "idle"

local function step()
    if not Settings.AutoParry then status = "off"; return end

    local root = getRoot()
    if not root then status = "no character"; return end

    local folder = findBallFolder()
    if not folder then status = "no ball folder"; return end

    local now = os.clock()
    if now - lastParry < Settings.Cooldown then return end

    local myName = LocalPlayer.Name
    local ping   = pingSeconds() + Settings.PingOffset
    local rootPos = root.Position

    for _, ball in ipairs(folder:GetChildren()) do
        if ball:IsA("BasePart") and isRealBall(ball) then
            -- When "only when targeted" is on, skip balls aimed at other
            -- players (an absent target attribute is treated as "aimed here").
            local aimedHere = true
            if Settings.OnlyWhenTargeted then
                local tgt = ballTargetName(ball)
                aimedHere = (tgt == nil) or (tgt == myName)
            end

            if aimedHere then
                local dist  = (ball.Position - rootPos).Magnitude
                local speed = ballSpeed(ball)
                -- Trigger radius grows with ball speed and latency so fast
                -- balls and laggy clients still parry in time.
                local trigger = Settings.ParryRadius + speed * ping

                if dist <= trigger then
                    fireParry()
                    lastParry = now
                    status = string.format("PARRY  d=%.0f  r=%.0f", dist, trigger)
                    return
                end
            end
        end
    end

    status = "watching"
end

-- ── UI (self-contained, PC + mobile) ─────────────────────────────────────
local PlayerGui = LocalPlayer:WaitForChild("PlayerGui")

-- Kill a stale GUI from a previous run before building a fresh one.
local oldGui = PlayerGui:FindFirstChild("BladeBallAutoParryGui")
if oldGui then oldGui:Destroy() end

local gui = Instance.new("ScreenGui")
gui.Name = "BladeBallAutoParryGui"
gui.ResetOnSpawn = false
gui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
gui.Parent = PlayerGui

local function color(r, g, b) return Color3.fromRGB(r, g, b) end
local ACCENT = color(90, 170, 255)

local main = Instance.new("Frame")
main.Name = "Main"
main.Size = UDim2.new(0, 250, 0, 300)
main.Position = UDim2.new(0, 24, 0.5, -150)
main.BackgroundColor3 = color(24, 26, 32)
main.BorderSizePixel = 0
main.Active = true
main.Draggable = true                      -- simple built-in drag (PC + touch)
main.Parent = gui
Instance.new("UICorner", main).CornerRadius = UDim.new(0, 10)

local title = Instance.new("TextLabel")
title.Size = UDim2.new(1, 0, 0, 34)
title.BackgroundColor3 = color(18, 20, 24)
title.BorderSizePixel = 0
title.Text = "Blade Ball • Auto Parry"
title.TextColor3 = ACCENT
title.Font = Enum.Font.GothamBold
title.TextSize = 15
title.Parent = main
Instance.new("UICorner", title).CornerRadius = UDim.new(0, 10)

local list = Instance.new("ScrollingFrame")
list.Size = UDim2.new(1, -12, 1, -78)
list.Position = UDim2.new(0, 6, 0, 40)
list.BackgroundTransparency = 1
list.BorderSizePixel = 0
list.ScrollBarThickness = 4
list.CanvasSize = UDim2.new(0, 0, 0, 0)
list.AutomaticCanvasSize = Enum.AutomaticSize.Y
list.Parent = main
local layout = Instance.new("UIListLayout", list)
layout.Padding = UDim.new(0, 6)
layout.SortOrder = Enum.SortOrder.LayoutOrder

local statusLabel = Instance.new("TextLabel")
statusLabel.Size = UDim2.new(1, -12, 0, 26)
statusLabel.Position = UDim2.new(0, 6, 1, -32)
statusLabel.BackgroundColor3 = color(18, 20, 24)
statusLabel.BorderSizePixel = 0
statusLabel.Text = "status: idle"
statusLabel.TextColor3 = color(180, 185, 195)
statusLabel.Font = Enum.Font.Gotham
statusLabel.TextSize = 12
statusLabel.Parent = main
Instance.new("UICorner", statusLabel).CornerRadius = UDim.new(0, 6)

-- Toggle row ---------------------------------------------------------------
local function addToggle(labelText, key)
    local row = Instance.new("TextButton")
    row.Size = UDim2.new(1, 0, 0, 30)
    row.BackgroundColor3 = color(32, 35, 42)
    row.BorderSizePixel = 0
    row.Text = ""
    row.AutoButtonColor = false
    row.Parent = list
    Instance.new("UICorner", row).CornerRadius = UDim.new(0, 6)

    local lbl = Instance.new("TextLabel")
    lbl.Size = UDim2.new(1, -50, 1, 0)
    lbl.Position = UDim2.new(0, 10, 0, 0)
    lbl.BackgroundTransparency = 1
    lbl.Text = labelText
    lbl.TextColor3 = color(230, 232, 238)
    lbl.TextXAlignment = Enum.TextXAlignment.Left
    lbl.Font = Enum.Font.Gotham
    lbl.TextSize = 13
    lbl.Parent = row

    local pip = Instance.new("Frame")
    pip.Size = UDim2.new(0, 34, 0, 18)
    pip.Position = UDim2.new(1, -42, 0.5, -9)
    pip.BorderSizePixel = 0
    pip.Parent = row
    Instance.new("UICorner", pip).CornerRadius = UDim.new(1, 0)

    local knob = Instance.new("Frame")
    knob.Size = UDim2.new(0, 14, 0, 14)
    knob.BorderSizePixel = 0
    knob.Parent = pip
    Instance.new("UICorner", knob).CornerRadius = UDim.new(1, 0)

    local function render()
        local on = Settings[key]
        pip.BackgroundColor3 = on and ACCENT or color(70, 74, 82)
        knob.BackgroundColor3 = color(245, 246, 250)
        knob.Position = on and UDim2.new(1, -16, 0.5, -7) or UDim2.new(0, 2, 0.5, -7)
    end
    render()

    track(row.MouseButton1Click:Connect(function()
        Settings[key] = not Settings[key]
        render(); saveConfig()
    end))
    return row
end

-- Slider row ---------------------------------------------------------------
local function addSlider(labelText, key, minV, maxV, step)
    local row = Instance.new("Frame")
    row.Size = UDim2.new(1, 0, 0, 44)
    row.BackgroundColor3 = color(32, 35, 42)
    row.BorderSizePixel = 0
    row.Parent = list
    Instance.new("UICorner", row).CornerRadius = UDim.new(0, 6)

    local lbl = Instance.new("TextLabel")
    lbl.Size = UDim2.new(1, -16, 0, 20)
    lbl.Position = UDim2.new(0, 10, 0, 3)
    lbl.BackgroundTransparency = 1
    lbl.TextXAlignment = Enum.TextXAlignment.Left
    lbl.TextColor3 = color(230, 232, 238)
    lbl.Font = Enum.Font.Gotham
    lbl.TextSize = 13
    lbl.Parent = row

    local bar = Instance.new("Frame")
    bar.Size = UDim2.new(1, -20, 0, 6)
    bar.Position = UDim2.new(0, 10, 0, 30)
    bar.BackgroundColor3 = color(60, 64, 72)
    bar.BorderSizePixel = 0
    bar.Parent = row
    Instance.new("UICorner", bar).CornerRadius = UDim.new(1, 0)

    local fill = Instance.new("Frame")
    fill.BackgroundColor3 = ACCENT
    fill.BorderSizePixel = 0
    fill.Parent = bar
    Instance.new("UICorner", fill).CornerRadius = UDim.new(1, 0)

    local function render()
        local v = Settings[key]
        lbl.Text = string.format("%s: %s", labelText,
            (step and step < 1) and string.format("%.2f", v) or tostring(math.floor(v + 0.5)))
        fill.Size = UDim2.new((v - minV) / (maxV - minV), 0, 1, 0)
    end
    render()

    local dragging = false
    local function setFromX(px)
        local rel = math.clamp((px - bar.AbsolutePosition.X) / bar.AbsoluteSize.X, 0, 1)
        local v = minV + rel * (maxV - minV)
        if step then v = math.floor(v / step + 0.5) * step end
        Settings[key] = math.clamp(v, minV, maxV)
        render()
    end

    track(bar.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1
        or input.UserInputType == Enum.UserInputType.Touch then
            dragging = true; setFromX(input.Position.X)
        end
    end))
    track(UserInputService.InputChanged:Connect(function(input)
        if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement
        or input.UserInputType == Enum.UserInputType.Touch) then
            setFromX(input.Position.X)
        end
    end))
    track(UserInputService.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1
        or input.UserInputType == Enum.UserInputType.Touch then
            if dragging then dragging = false; saveConfig() end
        end
    end))
    return row
end

addToggle("Auto Parry",        "AutoParry")
addToggle("Only When Targeted","OnlyWhenTargeted")
addToggle("Use Remote",        "UseRemote")
addToggle("Use Keypress",      "UseKeypress")
addSlider("Parry Radius",  "ParryRadius", 5,  60, 1)
addSlider("Ping Offset",   "PingOffset",  0,  0.2, 0.01)
addSlider("Cooldown",      "Cooldown",    0,  0.5, 0.01)

-- ── Drive ────────────────────────────────────────────────────────────────
track(RunService.Heartbeat:Connect(function()
    local ok, err = pcall(step)
    if not ok then status = "err: " .. tostring(err) end
    if Settings.ShowStatus then
        statusLabel.Text = "status: " .. status
        statusLabel.Visible = true
    else
        statusLabel.Visible = false
    end
end))

-- ── Teardown API ─────────────────────────────────────────────────────────
function self.stop()
    for _, c in ipairs(connections) do pcall(function() c:Disconnect() end) end
    table.clear(connections)
    if gui then gui:Destroy() end
    _G.__BladeBallAutoParry = nil
end

pcall(function()
    local StarterGui = game:GetService("StarterGui")
    StarterGui:SetCore("SendNotification", {
        Title = "Blade Ball Hub",
        Text  = "Auto-parry loaded. Toggle in the panel.",
        Duration = 4,
    })
end)
