--[[
    Blade Ball  •  WindUI Edition
    -------------------------------------------------------------------
    A clean auto-parry hub for Blade Ball built on the WindUI library,
    themed a soft translucent white ("white glass").

    Game data sourced from the MegaDumper dump of PlaceId 16281300371:
        Balls carry a "zoomies" LinearVelocity (VectorVelocity)
        The threat ball's "target" attribute == your player name
        Parry is triggered by the ParryButtonPress BindableEvent
        Server confirms via Remotes.ParrySuccessAll / ParryAttemptAll

    UI  : WindUI (https://github.com/Footagesus/WindUI)
    Theme: white accent, slightly transparent glass window
--]]

-- ═══════════════════════════════════════════════════════════════════
--  SERVICES
-- ═══════════════════════════════════════════════════════════════════
local Players        = game:GetService("Players")
local RunService     = game:GetService("RunService")
local ReplicatedStor = game:GetService("ReplicatedStorage")
local Workspace      = game:GetService("Workspace")
local Stats          = game:GetService("Stats")

local LocalPlayer = Players.LocalPlayer
local Camera      = Workspace.CurrentCamera

-- ═══════════════════════════════════════════════════════════════════
--  CONFIG  (mutated live by the UI)
-- ═══════════════════════════════════════════════════════════════════
local Config = {
    autoParry   = false,
    parryMode   = "Predictive",  -- Ultra | Predictive | Conservative
    parryWindow = 0.28,          -- seconds of ETA that triggers a parry
    pingComp    = true,          -- add half-ping to the reaction window
    hitboxBoost = 0,             -- studs of extra reach (0 = off)
    ballEsp     = false,
    espColor    = Color3.fromRGB(255, 255, 255),
}

-- ═══════════════════════════════════════════════════════════════════
--  REMOTES
-- ═══════════════════════════════════════════════════════════════════
local Remotes = ReplicatedStor:WaitForChild("Remotes", 15)

local ParryButtonPress = Remotes and Remotes:FindFirstChild("ParryButtonPress")
local ParryAttempt     = Remotes and Remotes:FindFirstChild("ParryAttempt")

-- Fire whatever parry path the game exposes. ParryButtonPress is a
-- client-side BindableEvent the game's own input handler listens to, so
-- firing it runs the game's real parry logic (safest / most legit path).
local function fireParry()
    if ParryButtonPress and ParryButtonPress:IsA("BindableEvent") then
        ParryButtonPress:Fire()
    elseif ParryAttempt then
        pcall(function() ParryAttempt:FireServer() end)
    end
end

-- ═══════════════════════════════════════════════════════════════════
--  PING COMPENSATION
-- ═══════════════════════════════════════════════════════════════════
local PingComp = {}
function PingComp.ms()
    local ok, ping = pcall(function()
        return Stats.Network.ServerStatsItem["Data Ping"]:GetValue()
    end)
    return ok and ping or 0
end
function PingComp.window()
    local w = Config.parryWindow
    if Config.pingComp then
        w = w + (PingComp.ms() / 1000) * 0.5
    end
    return w
end

-- ═══════════════════════════════════════════════════════════════════
--  BALL TRACKER
--  Balls live loose in the workspace; each has a "zoomies" LinearVelocity.
--  The ball actively aimed at us has attribute "target" == our name.
-- ═══════════════════════════════════════════════════════════════════
local BallTracker = {
    balls   = {},   -- [ball] = true
    parries = 0,
}

local function isBall(inst)
    return inst
        and inst:IsA("BasePart")
        and inst:FindFirstChild("zoomies") ~= nil
end

function BallTracker.scan()
    for _, inst in ipairs(Workspace:GetDescendants()) do
        if isBall(inst) then
            BallTracker.balls[inst] = true
        end
    end
end

Workspace.DescendantAdded:Connect(function(inst)
    task.defer(function()
        if isBall(inst) then BallTracker.balls[inst] = true end
    end)
end)

Workspace.DescendantRemoving:Connect(function(inst)
    BallTracker.balls[inst] = nil
end)

if Remotes then
    local ballExplode = Remotes:FindFirstChild("BallExplode")
    if ballExplode then
        ballExplode.OnClientEvent:Connect(function(ball)
            if typeof(ball) == "Instance" then BallTracker.balls[ball] = nil end
        end)
    end
end

-- Returns the most urgent ball aimed at us + its ETA in seconds.
function BallTracker.bestThreat(hrpPos)
    local best, bestEta = nil, math.huge
    local myName = LocalPlayer.Name

    for ball in pairs(BallTracker.balls) do
        if not (ball and ball.Parent) then
            BallTracker.balls[ball] = nil
        else
            local vp = ball:FindFirstChild("zoomies")
            if vp then
                local targeted = ball:GetAttribute("target") == myName
                if targeted then
                    local toMe    = hrpPos - ball.Position
                    local vel     = vp.VectorVelocity
                    local closing = vel:Dot(toMe.Unit) > 0
                    if closing and vel.Magnitude > 1 then
                        local eta = (toMe.Magnitude - Config.hitboxBoost) / vel.Magnitude
                        if eta < bestEta then
                            best, bestEta = ball, eta
                        end
                    end
                end
            end
        end
    end
    return best, bestEta
end

-- ═══════════════════════════════════════════════════════════════════
--  BALL ESP
-- ═══════════════════════════════════════════════════════════════════
local EspBoxes = setmetatable({}, { __mode = "k" })

local function ensureEsp(ball)
    if EspBoxes[ball] then return EspBoxes[ball] end
    local box = Instance.new("BoxHandleAdornment")
    box.Name        = "BB_WindUI_ESP"
    box.Adornee     = ball
    box.Size        = ball.Size + Vector3.new(0.5, 0.5, 0.5)
    box.Color3      = Config.espColor
    box.Transparency = 0.5
    box.AlwaysOnTop = true
    box.ZIndex      = 5
    box.Parent      = ball
    EspBoxes[ball]  = box
    return box
end

local function clearEsp()
    for ball, box in pairs(EspBoxes) do
        if box then box:Destroy() end
        EspBoxes[ball] = nil
    end
end

-- ═══════════════════════════════════════════════════════════════════
--  MAIN LOOP
-- ═══════════════════════════════════════════════════════════════════
local parryBusy = false

RunService.Heartbeat:Connect(function()
    local char = LocalPlayer.Character
    local hrp  = char and char:FindFirstChild("HumanoidRootPart")
    if not hrp then return end

    local threat, eta = BallTracker.bestThreat(hrp.Position)

    -- ESP
    if Config.ballEsp then
        for ball in pairs(BallTracker.balls) do
            if ball and ball.Parent then
                local box = ensureEsp(ball)
                box.Color3 = (ball == threat) and Color3.fromRGB(255, 90, 90)
                    or Config.espColor
            end
        end
    elseif next(EspBoxes) then
        clearEsp()
    end

    -- AUTO PARRY
    if Config.autoParry and threat and not parryBusy then
        local win  = PingComp.window()
        local mode = Config.parryMode
        local fire =
            (mode == "Ultra") or
            (mode == "Predictive"   and eta <= win) or
            (mode == "Conservative" and eta <= win * 0.6)

        if fire then
            parryBusy = true
            fireParry()
            BallTracker.parries += 1
            task.delay(0.09, function() parryBusy = false end)
        end
    end
end)

-- ═══════════════════════════════════════════════════════════════════
--  UI  —  WindUI  (white translucent glass theme)
-- ═══════════════════════════════════════════════════════════════════
local WindUI = loadstring(game:HttpGet(
    "https://github.com/Footagesus/WindUI/releases/latest/download/main.lua"
))()

-- Register a soft white glass theme: white accent/text on a near-black
-- background so the Transparent window reads as translucent white.
WindUI:AddTheme({
    Name        = "WhiteGlass",
    Accent      = "#ffffff",
    Dialog      = "#111111",
    Outline     = "#ffffff",
    Text        = "#ffffff",
    Placeholder = "#c8c8c8",
    Background   = "#0b0b0b",
    Button      = "#f5f5f5",
    Icon        = "#ffffff",
})
WindUI:SetTheme("WhiteGlass")

local Window = WindUI:CreateWindow({
    Title       = "Blade Ball",
    Icon        = "wind",
    Author      = "WindUI Edition",
    Folder      = "BladeBall_WindUI",
    Size        = UDim2.fromOffset(560, 420),
    Transparent = true,          -- glassy translucent window
    Theme       = "WhiteGlass",
    SideBarWidth = 180,
})

-- Push the whole UI toward "slightly transparent" so white glass shows.
pcall(function() Window:SetTransparent(true) end)

WindUI:Notify({
    Title    = "Blade Ball • WindUI",
    Content  = "White glass theme loaded. Toggle Auto Parry to start.",
    Duration = 5,
    Icon     = "check",
})

-- ── Tabs ────────────────────────────────────────────────────────────
local MainTab   = Window:Tab({ Title = "Auto Parry", Icon = "swords" })
local VisualTab = Window:Tab({ Title = "Visuals",    Icon = "eye" })
local InfoTab   = Window:Tab({ Title = "Info",       Icon = "info" })

-- ── Auto Parry ──────────────────────────────────────────────────────
MainTab:Section({ Title = "Parry" })

MainTab:Toggle({
    Title    = "Auto Parry",
    Desc     = "Automatically parry balls aimed at you.",
    Value    = Config.autoParry,
    Callback = function(v) Config.autoParry = v end,
})

MainTab:Dropdown({
    Title  = "Parry Mode",
    Values = { "Ultra", "Predictive", "Conservative" },
    Value  = Config.parryMode,
    Callback = function(v) Config.parryMode = v end,
})

MainTab:Slider({
    Title = "Parry Window (ms)",
    Desc  = "Higher = parry earlier.",
    Value = { Min = 80, Max = 500, Default = math.floor(Config.parryWindow * 1000) },
    Step  = 5,
    Callback = function(v) Config.parryWindow = v / 1000 end,
})

MainTab:Toggle({
    Title    = "Ping Compensation",
    Desc     = "Widen the window based on your ping.",
    Value    = Config.pingComp,
    Callback = function(v) Config.pingComp = v end,
})

MainTab:Slider({
    Title = "Hitbox Reach (studs)",
    Desc  = "Extra reach subtracted from ball distance.",
    Value = { Min = 0, Max = 15, Default = Config.hitboxBoost },
    Step  = 1,
    Callback = function(v) Config.hitboxBoost = v end,
})

-- ── Visuals ─────────────────────────────────────────────────────────
VisualTab:Section({ Title = "ESP" })

VisualTab:Toggle({
    Title    = "Ball ESP",
    Desc     = "Draw a box around every ball (red = targeting you).",
    Value    = Config.ballEsp,
    Callback = function(v)
        Config.ballEsp = v
        if not v then clearEsp() end
    end,
})

VisualTab:Colorpicker({
    Title   = "ESP Color",
    Default = Config.espColor,
    Callback = function(c) Config.espColor = c end,
})

-- ── Info ────────────────────────────────────────────────────────────
InfoTab:Section({ Title = "Status" })

local StatusPara = InfoTab:Paragraph({
    Title = "Live Stats",
    Desc  = "Loading…",
})

InfoTab:Paragraph({
    Title = "About",
    Desc  = "Blade Ball hub on the WindUI library.\n"
        .. "Theme: white glass (translucent). "
        .. "Parry fires the ParryButtonPress BindableEvent.",
})

-- Refresh the live-stats paragraph once per second.
task.spawn(function()
    while task.wait(1) do
        local ok = pcall(function()
            StatusPara:SetDesc(string.format(
                "Ping: %d ms   |   Window: %d ms   |   Parries: %d   |   Balls tracked: %d",
                PingComp.ms(),
                math.floor(PingComp.window() * 1000),
                BallTracker.parries,
                (function()
                    local n = 0
                    for _ in pairs(BallTracker.balls) do n += 1 end
                    return n
                end)()
            ))
        end)
        if not ok then break end
    end
end)

-- ═══════════════════════════════════════════════════════════════════
--  BOOT
-- ═══════════════════════════════════════════════════════════════════
BallTracker.scan()
print("[Blade Ball • WindUI] loaded — white glass theme.")
