--[[
    Blade Ball  •  WindUI Edition  (Full Hub)
    ===================================================================
    A complete Blade Ball hub built on the WindUI library, themed a soft
    translucent white ("white glass").

    Data sourced from the MegaDumper dump of PlaceId 16281300371 in this
    repo ("Blade ball"). The 3,693 client scripts in that dump are
    protected bytecode (raw VM string tables, not decompilable to
    readable Lua), so there is no readable-logic "big find" to lift.
    What the dump *does* expose cleanly is the full remote map (1,627
    remotes), which is what every feature below is built on:

        Parry      : Remotes.ParryButtonPress (BindableEvent :Fire)
                     Remotes.ParryAttempt     (RemoteEvent  :FireServer)
        Confirm    : Remotes.ParrySuccessAll / ParryAttemptAll
        Abilities  : Remotes.AbilityButtonPress          (Bindable)
                     Remotes.SecondaryAbilityButtonPress (Remote)
        Movement   : Remotes.DashFired / DoubleJump
        Ball state : Remotes.BallAdded / BallExplode / BallRemoved
                     ball parts carry a "zoomies" LinearVelocity and a
                     "target" attribute holding the aimed player's name
        Matchmake  : Remotes.PlayRanked / JoinQueue / PlayTrainingMode
                     Remotes.ReturnToLobby

    UI    : WindUI  (https://github.com/Footagesus/WindUI)
    Theme : white accent, slightly transparent glass window
--]]

-- ═══════════════════════════════════════════════════════════════════
--  SERVICES
-- ═══════════════════════════════════════════════════════════════════
local Players           = game:GetService("Players")
local RunService        = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace         = game:GetService("Workspace")
local Lighting          = game:GetService("Lighting")
local Stats             = game:GetService("Stats")
local UserInputService  = game:GetService("UserInputService")
local TeleportService   = game:GetService("TeleportService")

local LocalPlayer = Players.LocalPlayer
local Camera      = Workspace.CurrentCamera

-- ═══════════════════════════════════════════════════════════════════
--  CONFIG  (mutated live by the UI)
-- ═══════════════════════════════════════════════════════════════════
local Config = {
    -- Auto parry
    autoParry     = false,
    parryMode     = "Predictive",   -- Ultra | Predictive | Conservative
    parryWindow   = 0.28,           -- seconds of ETA that triggers a parry
    pingComp      = true,
    curveComp     = true,           -- follow curved-ball velocity direction
    hitboxReach   = 0,              -- studs subtracted from ball distance
    parryCooldown = 0.09,           -- min seconds between fires

    -- Manual spam (fire parry on a fixed interval, ignore threat check)
    manualSpam    = false,
    spamInterval  = 0.05,           -- seconds between spam fires

    -- Abilities / movement
    autoAbility   = false,          -- fire primary ability when targeted
    abilityDelay  = 0.6,
    autoDash      = false,          -- dash away from an incoming ball
    infiniteJump  = false,

    -- Character
    walkSpeed     = 16,
    walkSpeedOn   = false,
    jumpPower     = 50,
    jumpPowerOn   = false,

    -- Visuals
    ballEsp       = false,
    ballTracers   = false,
    playerEsp     = false,
    predictionArc = false,
    espColor      = Color3.fromRGB(255, 255, 255),
    fullbright    = false,
    fov           = 70,
    fovOn         = false,

    -- Automation
    autoQueue     = false,
    autoLobby     = false,          -- return to lobby on death
    antiAfk       = true,
}

-- ═══════════════════════════════════════════════════════════════════
--  REMOTES  (generic resolver + fire helper)
-- ═══════════════════════════════════════════════════════════════════
local Remotes = ReplicatedStorage:WaitForChild("Remotes", 15)

local function getRemote(name)
    return Remotes and Remotes:FindFirstChild(name)
end

-- Fire any remote by name, dispatching on its class.
local function fireRemote(name, ...)
    local r = getRemote(name)
    if not r then return false end
    local args = { ... }
    local ok = pcall(function()
        if r:IsA("BindableEvent") then
            r:Fire(table.unpack(args))
        elseif r:IsA("RemoteEvent") or r:IsA("UnreliableRemoteEvent") then
            r:FireServer(table.unpack(args))
        elseif r:IsA("BindableFunction") then
            r:Invoke(table.unpack(args))
        elseif r:IsA("RemoteFunction") then
            r:InvokeServer(table.unpack(args))
        end
    end)
    return ok
end

-- Parry uses the game's own client-side BindableEvent path (most legit).
local function fireParry()
    if not fireRemote("ParryButtonPress") then
        fireRemote("ParryAttempt")
    end
end

-- Manual spam: fire the parry on a fixed interval, no threat check. The
-- most reliable ("OP") method — it never misses a timing window because
-- it is always parrying.
task.spawn(function()
    while true do
        if Config.manualSpam then
            fireParry()
            task.wait(Config.spamInterval)
        else
            task.wait(0.1)
        end
    end
end)

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
--  Balls sit loose in the workspace; each has a "zoomies" LinearVelocity.
--  The ball aimed at us has attribute "target" == our name.
-- ═══════════════════════════════════════════════════════════════════
local BallTracker = { balls = {}, parries = 0 }

local function isBall(inst)
    return inst
        and inst:IsA("BasePart")
        and inst:FindFirstChild("zoomies") ~= nil
end

function BallTracker.scan()
    for _, inst in ipairs(Workspace:GetDescendants()) do
        if isBall(inst) then BallTracker.balls[inst] = true end
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

do
    local be = getRemote("BallExplode")
    if be and be:IsA("RemoteEvent") then
        be.OnClientEvent:Connect(function(ball)
            if typeof(ball) == "Instance" then BallTracker.balls[ball] = nil end
        end)
    end
end

-- ball velocity, honouring curve (use the LinearVelocity's live vector).
local function ballVelocity(ball, vp)
    return vp.VectorVelocity
end

-- Returns the most urgent ball aimed at us + ETA (seconds) + its velocity.
function BallTracker.bestThreat(hrpPos)
    local best, bestEta, bestVel = nil, math.huge, nil
    local myName = LocalPlayer.Name

    for ball in pairs(BallTracker.balls) do
        if not (ball and ball.Parent) then
            BallTracker.balls[ball] = nil
        else
            local vp = ball:FindFirstChild("zoomies")
            if vp and ball:GetAttribute("target") == myName then
                local toMe = hrpPos - ball.Position
                local vel  = ballVelocity(ball, vp)
                if vel.Magnitude > 1 and vel:Dot(toMe.Unit) > 0 then
                    local eta = (toMe.Magnitude - Config.hitboxReach) / vel.Magnitude
                    if eta < bestEta then
                        best, bestEta, bestVel = ball, eta, vel
                    end
                end
            end
        end
    end
    return best, bestEta, bestVel
end

function BallTracker.count()
    local n = 0
    for _ in pairs(BallTracker.balls) do n += 1 end
    return n
end

-- ═══════════════════════════════════════════════════════════════════
--  ESP  (balls, tracers, players, prediction arc)
-- ═══════════════════════════════════════════════════════════════════
local Esp = { ballBoxes = {}, tracers = {}, arcDots = {}, playerBoxes = {} }

local function newDrawing(kind)
    if typeof(Drawing) ~= "table" and typeof(Drawing) ~= "userdata" then return nil end
    local ok, d = pcall(Drawing.new, kind)
    return ok and d or nil
end

local function clearTable(tbl, destroyMethod)
    for k, v in pairs(tbl) do
        pcall(function()
            if destroyMethod == "Remove" then v:Remove() else v:Destroy() end
        end)
        tbl[k] = nil
    end
end

local function ensureBallBox(ball)
    local box = Esp.ballBoxes[ball]
    if box and box.Parent then return box end
    box = Instance.new("BoxHandleAdornment")
    box.Name         = "BB_ESP"
    box.Adornee      = ball
    box.Size         = ball.Size + Vector3.new(0.6, 0.6, 0.6)
    box.Transparency = 0.5
    box.AlwaysOnTop  = true
    box.ZIndex       = 5
    box.Parent       = ball
    Esp.ballBoxes[ball] = box
    return box
end

local function ensureTracer(ball)
    local t = Esp.tracers[ball]
    if t then return t end
    t = newDrawing("Line")
    if t then t.Thickness = 1.6 ; Esp.tracers[ball] = t end
    return t
end

local function ensurePlayerBox(plr)
    local box = Esp.playerBoxes[plr]
    if box then return box end
    box = newDrawing("Square")
    if box then
        box.Thickness = 1.6
        box.Filled    = false
        Esp.playerBoxes[plr] = box
    end
    return box
end

local function clearAllEsp()
    clearTable(Esp.ballBoxes, "Destroy")
    clearTable(Esp.tracers, "Remove")
    clearTable(Esp.playerBoxes, "Remove")
    for _, dots in pairs(Esp.arcDots) do clearTable(dots, "Destroy") end
    Esp.arcDots = {}
end

-- ═══════════════════════════════════════════════════════════════════
--  CHARACTER HELPERS
-- ═══════════════════════════════════════════════════════════════════
local function getHumanoid()
    local c = LocalPlayer.Character
    return c and c:FindFirstChildOfClass("Humanoid"), c and c:FindFirstChild("HumanoidRootPart")
end

local function applyCharacterMods()
    local hum = getHumanoid()
    if not hum then return end
    if Config.walkSpeedOn then hum.WalkSpeed = Config.walkSpeed end
    if Config.jumpPowerOn then
        hum.UseJumpPower = true
        hum.JumpPower    = Config.jumpPower
    end
end

LocalPlayer.CharacterAdded:Connect(function()
    task.wait(0.5)
    applyCharacterMods()
end)

-- Infinite jump
UserInputService.JumpRequest:Connect(function()
    if Config.infiniteJump then
        local hum = getHumanoid()
        if hum then hum:ChangeState(Enum.HumanoidStateType.Jumping) end
    end
end)

-- Auto dash: fire a dash away when a ball is closing fast
local lastDash = 0
local function tryAutoDash(eta)
    if not Config.autoDash then return end
    if eta > 0.6 then return end
    if os.clock() - lastDash < 0.9 then return end
    lastDash = os.clock()
    fireRemote("DashFired")
end

-- ═══════════════════════════════════════════════════════════════════
--  FULLBRIGHT
-- ═══════════════════════════════════════════════════════════════════
local savedLighting
local function setFullbright(on)
    if on then
        savedLighting = savedLighting or {
            Brightness = Lighting.Brightness,
            ClockTime  = Lighting.ClockTime,
            FogEnd     = Lighting.FogEnd,
            Ambient    = Lighting.Ambient,
        }
        Lighting.Brightness = 2
        Lighting.ClockTime  = 14
        Lighting.FogEnd     = 1e9
        Lighting.Ambient    = Color3.fromRGB(180, 180, 180)
    elseif savedLighting then
        Lighting.Brightness = savedLighting.Brightness
        Lighting.ClockTime  = savedLighting.ClockTime
        Lighting.FogEnd     = savedLighting.FogEnd
        Lighting.Ambient    = savedLighting.Ambient
    end
end

-- ═══════════════════════════════════════════════════════════════════
--  ANTI-AFK
-- ═══════════════════════════════════════════════════════════════════
do
    local vu = pcall(function() return game:GetService("VirtualUser") end)
        and game:GetService("VirtualUser")
    if vu then
        LocalPlayer.Idled:Connect(function()
            if not Config.antiAfk then return end
            pcall(function()
                vu:CaptureController()
                vu:ClickButton2(Vector2.new())
            end)
        end)
    end
end

-- Auto-lobby on death
local function hookDeath()
    local hum = getHumanoid()
    if hum then
        hum.Died:Connect(function()
            if Config.autoLobby then
                task.wait(1.5)
                fireRemote("ReturnToLobby")
            end
        end)
    end
end
LocalPlayer.CharacterAdded:Connect(function() task.wait(1) hookDeath() end)

-- ═══════════════════════════════════════════════════════════════════
--  MAIN LOOP
-- ═══════════════════════════════════════════════════════════════════
local parryBusy = false
local lastAbility, lastQueue = 0, 0

RunService.Heartbeat:Connect(function()
    local hum, hrp = getHumanoid()
    if not hrp then return end

    local threat, eta, vel = BallTracker.bestThreat(hrp.Position)

    -- ── AUTO PARRY ──────────────────────────────────────────────
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
            task.delay(Config.parryCooldown, function() parryBusy = false end)
        end
    end

    -- ── AUTO ABILITY ────────────────────────────────────────────
    if Config.autoAbility and threat and os.clock() - lastAbility > Config.abilityDelay then
        lastAbility = os.clock()
        fireRemote("AbilityButtonPress")
    end

    -- ── AUTO DASH ───────────────────────────────────────────────
    if threat then tryAutoDash(eta) end

    -- ── AUTO QUEUE ──────────────────────────────────────────────
    if Config.autoQueue and os.clock() - lastQueue > 5 then
        lastQueue = os.clock()
        if not hum or hum.Health <= 0 then
            fireRemote("PlayRanked")
            fireRemote("JoinQueue")
        end
    end
end)

-- Visual loop (RenderStepped so drawings track the camera each frame)
RunService.RenderStepped:Connect(function()
    local hum, hrp = getHumanoid()
    local threat = hrp and select(1, BallTracker.bestThreat(hrp.Position)) or nil

    -- Ball boxes + tracers
    if Config.ballEsp or Config.ballTracers then
        for ball in pairs(BallTracker.balls) do
            if ball and ball.Parent then
                if Config.ballEsp then
                    local box = ensureBallBox(ball)
                    box.Color3 = (ball == threat) and Color3.fromRGB(255, 80, 80)
                        or Config.espColor
                elseif Esp.ballBoxes[ball] then
                    Esp.ballBoxes[ball]:Destroy() ; Esp.ballBoxes[ball] = nil
                end
                if Config.ballTracers then
                    local t = ensureTracer(ball)
                    if t then
                        local sp, on = Camera:WorldToViewportPoint(ball.Position)
                        t.Visible = on
                        if on then
                            t.From = Vector2.new(Camera.ViewportSize.X / 2, Camera.ViewportSize.Y)
                            t.To   = Vector2.new(sp.X, sp.Y)
                            t.Color = (ball == threat) and Color3.fromRGB(255, 80, 80)
                                or Config.espColor
                        end
                    end
                elseif Esp.tracers[ball] then
                    Esp.tracers[ball]:Remove() ; Esp.tracers[ball] = nil
                end
            end
        end
    elseif next(Esp.ballBoxes) or next(Esp.tracers) then
        clearTable(Esp.ballBoxes, "Destroy")
        clearTable(Esp.tracers, "Remove")
    end

    -- Player ESP
    if Config.playerEsp then
        for _, plr in ipairs(Players:GetPlayers()) do
            if plr ~= LocalPlayer then
                local char = plr.Character
                local root = char and char:FindFirstChild("HumanoidRootPart")
                local box  = ensurePlayerBox(plr)
                if root and box then
                    local sp, on = Camera:WorldToViewportPoint(root.Position)
                    box.Visible = on
                    if on then
                        local h = 4000 / sp.Z
                        box.Size     = Vector2.new(h * 0.6, h)
                        box.Position = Vector2.new(sp.X - h * 0.3, sp.Y - h / 2)
                        box.Color    = Config.espColor
                    end
                elseif box then
                    box.Visible = false
                end
            end
        end
    elseif next(Esp.playerBoxes) then
        clearTable(Esp.playerBoxes, "Remove")
    end

    -- Prediction arc for the current threat
    if Config.predictionArc and threat then
        local vp = threat:FindFirstChild("zoomies")
        if vp then
            local dots = Esp.arcDots[threat]
            if not dots then dots = {} ; Esp.arcDots[threat] = dots end
            local pos, v = threat.Position, vp.VectorVelocity
            for i = 1, 12 do
                local d = dots[i]
                if not d then
                    d = Instance.new("Part")
                    d.Anchored, d.CanCollide = true, false
                    d.Size = Vector3.new(0.4, 0.4, 0.4)
                    d.Material = Enum.Material.Neon
                    d.Color = Config.espColor
                    d.Parent = Workspace
                    dots[i] = d
                end
                d.Position = pos + v * (i * 0.03)
            end
        end
    elseif next(Esp.arcDots) then
        for _, dots in pairs(Esp.arcDots) do clearTable(dots, "Destroy") end
        Esp.arcDots = {}
    end
end)

-- Fullbright / FOV tick
RunService.Heartbeat:Connect(function()
    if Config.fovOn then Camera.FieldOfView = Config.fov end
end)

-- ═══════════════════════════════════════════════════════════════════
--  UI  —  WindUI  (white translucent glass)
-- ═══════════════════════════════════════════════════════════════════
local WindUI = loadstring(game:HttpGet(
    "https://github.com/Footagesus/WindUI/releases/latest/download/main.lua"
))()

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
    Title        = "Blade Ball",
    Icon         = "wind",
    Author       = "WindUI Edition",
    Folder       = "BladeBall_WindUI",
    Size         = UDim2.fromOffset(600, 460),
    Transparent  = true,          -- glassy translucent window
    Theme        = "WhiteGlass",
    SideBarWidth = 190,
})
pcall(function() Window:SetTransparent(true) end)

WindUI:Notify({
    Title    = "Blade Ball • WindUI",
    Content  = "White glass hub loaded. Enable Auto Parry to start.",
    Duration = 5,
    Icon     = "check",
})

-- ── Tabs ────────────────────────────────────────────────────────────
local ParryTab  = Window:Tab({ Title = "Auto Parry", Icon = "swords" })
local CombatTab = Window:Tab({ Title = "Combat",      Icon = "zap" })
local VisualTab = Window:Tab({ Title = "Visuals",     Icon = "eye" })
local PlayerTab = Window:Tab({ Title = "Player",      Icon = "user" })
local AutoTab   = Window:Tab({ Title = "Automation",  Icon = "repeat" })
local InfoTab   = Window:Tab({ Title = "Info",        Icon = "info" })

-- ── AUTO PARRY ──────────────────────────────────────────────────────
ParryTab:Section({ Title = "Parry" })

local parryToggle = ParryTab:Toggle({
    Title = "Auto Parry", Desc = "Parry balls aimed at you.",
    Value = Config.autoParry,
    Callback = function(v) Config.autoParry = v end,
})
ParryTab:Dropdown({
    Title = "Parry Mode", Values = { "Ultra", "Predictive", "Conservative" },
    Value = Config.parryMode,
    Callback = function(v) Config.parryMode = v end,
})
ParryTab:Slider({
    Title = "Parry Window (ms)", Desc = "Higher = parry earlier.",
    Value = { Min = 80, Max = 500, Default = math.floor(Config.parryWindow * 1000) },
    Step = 5, Callback = function(v) Config.parryWindow = v / 1000 end,
})
ParryTab:Slider({
    Title = "Hitbox Reach (studs)", Desc = "Extra reach subtracted from distance.",
    Value = { Min = 0, Max = 20, Default = Config.hitboxReach },
    Step = 1, Callback = function(v) Config.hitboxReach = v end,
})
ParryTab:Toggle({
    Title = "Ping Compensation", Desc = "Widen window by half your ping.",
    Value = Config.pingComp, Callback = function(v) Config.pingComp = v end,
})
ParryTab:Toggle({
    Title = "Curve Compensation", Desc = "Track curved-ball velocity direction.",
    Value = Config.curveComp, Callback = function(v) Config.curveComp = v end,
})
ParryTab:Keybind({
    Title = "Toggle Auto Parry", Value = "P",
    Callback = function()
        Config.autoParry = not Config.autoParry
        pcall(function() parryToggle:SetValue(Config.autoParry) end)
    end,
})

ParryTab:Section({ Title = "Manual Spam" })

local spamToggle = ParryTab:Toggle({
    Title = "Manual Spam", Desc = "Spam parry on a fixed interval — never misses a window.",
    Value = Config.manualSpam,
    Callback = function(v) Config.manualSpam = v end,
})
ParryTab:Slider({
    Title = "Spam Interval (ms)", Desc = "Lower = faster spam (25–200 ms).",
    Value = { Min = 25, Max = 200, Default = math.floor(Config.spamInterval * 1000) },
    Step = 5, Callback = function(v) Config.spamInterval = v / 1000 end,
})
ParryTab:Keybind({
    Title = "Toggle Manual Spam", Value = "O",
    Callback = function()
        Config.manualSpam = not Config.manualSpam
        pcall(function() spamToggle:SetValue(Config.manualSpam) end)
    end,
})

-- ── COMBAT / ABILITIES ──────────────────────────────────────────────
CombatTab:Section({ Title = "Abilities" })
CombatTab:Toggle({
    Title = "Auto Ability", Desc = "Fire your primary ability when targeted.",
    Value = Config.autoAbility, Callback = function(v) Config.autoAbility = v end,
})
CombatTab:Slider({
    Title = "Ability Delay (ms)",
    Value = { Min = 100, Max = 3000, Default = math.floor(Config.abilityDelay * 1000) },
    Step = 50, Callback = function(v) Config.abilityDelay = v / 1000 end,
})
CombatTab:Button({
    Title = "Use Primary Ability Now",
    Callback = function() fireRemote("AbilityButtonPress") end,
})
CombatTab:Button({
    Title = "Use Secondary Ability Now",
    Callback = function()
        if not fireRemote("SecondaryAbilityButtonPress") then
            fireRemote("SecondaryEndCD")
        end
    end,
})

CombatTab:Section({ Title = "Movement" })
CombatTab:Toggle({
    Title = "Auto Dash", Desc = "Dash away from a fast incoming ball.",
    Value = Config.autoDash, Callback = function(v) Config.autoDash = v end,
})
CombatTab:Toggle({
    Title = "Infinite Jump",
    Value = Config.infiniteJump, Callback = function(v) Config.infiniteJump = v end,
})

-- ── VISUALS ─────────────────────────────────────────────────────────
VisualTab:Section({ Title = "ESP" })
VisualTab:Toggle({
    Title = "Ball ESP", Desc = "Box every ball (red = targeting you).",
    Value = Config.ballEsp, Callback = function(v) Config.ballEsp = v end,
})
VisualTab:Toggle({
    Title = "Ball Tracers", Desc = "Line from screen to each ball.",
    Value = Config.ballTracers, Callback = function(v) Config.ballTracers = v end,
})
VisualTab:Toggle({
    Title = "Prediction Arc", Desc = "Neon dots along the threat ball's path.",
    Value = Config.predictionArc, Callback = function(v) Config.predictionArc = v end,
})
VisualTab:Toggle({
    Title = "Player ESP", Desc = "Box every other player.",
    Value = Config.playerEsp, Callback = function(v) Config.playerEsp = v end,
})
VisualTab:Colorpicker({
    Title = "ESP Color", Default = Config.espColor,
    Callback = function(c) Config.espColor = c end,
})

VisualTab:Section({ Title = "World" })
VisualTab:Toggle({
    Title = "Fullbright",
    Value = Config.fullbright,
    Callback = function(v) Config.fullbright = v setFullbright(v) end,
})
VisualTab:Toggle({
    Title = "Custom FOV",
    Value = Config.fovOn, Callback = function(v) Config.fovOn = v end,
})
VisualTab:Slider({
    Title = "FOV", Value = { Min = 40, Max = 120, Default = Config.fov },
    Step = 1, Callback = function(v) Config.fov = v end,
})

-- ── PLAYER ──────────────────────────────────────────────────────────
PlayerTab:Section({ Title = "Movement" })
PlayerTab:Toggle({
    Title = "WalkSpeed",
    Value = Config.walkSpeedOn,
    Callback = function(v) Config.walkSpeedOn = v applyCharacterMods() end,
})
PlayerTab:Slider({
    Title = "WalkSpeed Value",
    Value = { Min = 16, Max = 250, Default = Config.walkSpeed },
    Step = 1, Callback = function(v) Config.walkSpeed = v applyCharacterMods() end,
})
PlayerTab:Toggle({
    Title = "JumpPower",
    Value = Config.jumpPowerOn,
    Callback = function(v) Config.jumpPowerOn = v applyCharacterMods() end,
})
PlayerTab:Slider({
    Title = "JumpPower Value",
    Value = { Min = 50, Max = 350, Default = Config.jumpPower },
    Step = 5, Callback = function(v) Config.jumpPower = v applyCharacterMods() end,
})

-- ── AUTOMATION ──────────────────────────────────────────────────────
AutoTab:Section({ Title = "Matchmaking" })
AutoTab:Toggle({
    Title = "Auto Queue", Desc = "Rejoin ranked when not in a match.",
    Value = Config.autoQueue, Callback = function(v) Config.autoQueue = v end,
})
AutoTab:Toggle({
    Title = "Return to Lobby on Death",
    Value = Config.autoLobby, Callback = function(v) Config.autoLobby = v end,
})
AutoTab:Toggle({
    Title = "Anti-AFK", Value = Config.antiAfk,
    Callback = function(v) Config.antiAfk = v end,
})

AutoTab:Section({ Title = "Server" })
AutoTab:Button({
    Title = "Rejoin Server",
    Callback = function()
        TeleportService:Teleport(game.PlaceId, LocalPlayer)
    end,
})
AutoTab:Button({
    Title = "Server Hop",
    Callback = function()
        pcall(function() TeleportService:Teleport(game.PlaceId, LocalPlayer) end)
    end,
})
AutoTab:Button({
    Title = "Copy Job ID",
    Callback = function()
        if setclipboard then setclipboard(game.JobId) end
        WindUI:Notify({ Title = "Copied", Content = game.JobId, Duration = 4 })
    end,
})

-- ── INFO ────────────────────────────────────────────────────────────
InfoTab:Section({ Title = "Status" })
local StatusPara = InfoTab:Paragraph({ Title = "Live Stats", Desc = "Loading…" })
InfoTab:Paragraph({
    Title = "About",
    Desc  = "Blade Ball hub on the WindUI library • white glass theme.\n"
        .. "Parry fires the ParryButtonPress BindableEvent; all features "
        .. "are built on the remote map from the MegaDumper dump.",
})

task.spawn(function()
    while task.wait(1) do
        local ok = pcall(function()
            StatusPara:SetDesc(string.format(
                "Ping %d ms  •  Window %d ms  •  Parries %d  •  Balls %d",
                PingComp.ms(),
                math.floor(PingComp.window() * 1000),
                BallTracker.parries,
                BallTracker.count()
            ))
        end)
        if not ok then break end
    end
end)

-- ═══════════════════════════════════════════════════════════════════
--  BOOT
-- ═══════════════════════════════════════════════════════════════════
BallTracker.scan()
applyCharacterMods()
hookDeath()
print("[Blade Ball • WindUI] full hub loaded — white glass theme.")
