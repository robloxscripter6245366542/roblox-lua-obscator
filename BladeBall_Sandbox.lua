--[[
    Blade Ball  •  Auto-Parry Sandbox
    ===================================================================
    A self-contained test arena that REPLICATES the Blade Ball parry
    mechanics so the auto-parry can be validated and tuned without the
    real game. Drop this into Roblox Studio (Run / Play) — no executor,
    no game required.

    What it replicates (everything the hub depends on):
      • ReplicatedStorage.Remotes.ParryButtonPress   (BindableEvent)
        ReplicatedStorage.Remotes.ParryAttempt       (BindableEvent)
        ReplicatedStorage.Remotes.BallAdded / BallExplode / ParrySuccessAll
      • workspace.Balls — ball parts, each with:
          - a "realBall" attribute flagging the true ball (decoys lack it)
          - a "target" attribute holding the aimed player's name
          (velocity is derived from position deltas, as the hub does)
      • homing + curving ball physics (velocity changes over time)
      • simulated network latency on the parry press (configurable ping)
      • impact detection + a parry-active window (deflect vs death)

    It then runs the SAME curve-aware predictor the hub ships with,
    fires ParryButtonPress, and scores every round on a live HUD.

    CONFIG is at the top. Set BRAIN = false to test your own reflexes.
--]]

-- ═══════════════════════════════════════════════════════════════════
--  CONFIG
-- ═══════════════════════════════════════════════════════════════════
local CFG = {
    BRAIN         = true,      -- true: auto-parry brain plays. false: press Space yourself
    PARRY_ACTIVE  = 0.45,      -- seconds a parry stays "active" (deflect window)
    COOLDOWN      = 0.35,      -- seconds before parry can be pressed again
    HIT_RADIUS    = 4.0,       -- deflect / impact distance
    PING_MS       = 90,        -- simulated round-trip latency on the press
    SPAWN_EVERY   = 1.2,       -- seconds between ball spawns
    SPEED_MIN     = 70,
    SPEED_MAX     = 240,       -- ball speed ramps toward this
    CURVE_MAX     = 90,        -- max perpendicular curve acceleration
    SPAWN_DIST    = 90,        -- studs the ball spawns away
    -- Brain tuning (mirrors the hub)
    WINDOW        = 0.28,      -- press when predicted impact <= WINDOW
    MARGIN        = 0.05,      -- tuned safety margin
}

-- ═══════════════════════════════════════════════════════════════════
--  MOCK GAME ENVIRONMENT  (real Instances — works in Studio)
-- ═══════════════════════════════════════════════════════════════════
local RunService = game:GetService("RunService")
local Players    = game:GetService("Players")

local RepStore = game:GetService("ReplicatedStorage")
local Remotes  = RepStore:FindFirstChild("Remotes") or Instance.new("Folder")
Remotes.Name   = "Remotes"
Remotes.Parent = RepStore

local function ensureBindable(name)
    local b = Remotes:FindFirstChild(name)
    if not b then b = Instance.new("BindableEvent") b.Name = name b.Parent = Remotes end
    return b
end
local ParryButtonPress = ensureBindable("ParryButtonPress")
local ParryAttempt     = ensureBindable("ParryAttempt")
local BallAdded        = ensureBindable("BallAdded")
local BallExplode      = ensureBindable("BallExplode")
local ParrySuccessAll  = ensureBindable("ParrySuccessAll")

local BallsFolder = workspace:FindFirstChild("Balls") or Instance.new("Folder")
BallsFolder.Name   = "Balls"
BallsFolder.Parent = workspace

-- The defender. Use the local character if present, else a static part.
local PLAYER_NAME = (Players.LocalPlayer and Players.LocalPlayer.Name) or "Tester"
local playerPart
do
    local char = Players.LocalPlayer and Players.LocalPlayer.Character
    playerPart = char and char:FindFirstChild("HumanoidRootPart")
    if not playerPart then
        playerPart = Instance.new("Part")
        playerPart.Name        = "SandboxPlayer"
        playerPart.Anchored     = true
        playerPart.Size         = Vector3.new(3, 5, 1)
        playerPart.Color        = Color3.fromRGB(90, 170, 255)
        playerPart.Position     = Vector3.new(0, 5, 0)
        playerPart.Parent       = workspace
    end
end
local function playerPos() return playerPart.Position end

-- ═══════════════════════════════════════════════════════════════════
--  PARRY STATE  (server-truth, with simulated latency)
-- ═══════════════════════════════════════════════════════════════════
local parryActiveUntil = -1
local lastPressServer  = -999

local function registerPress()
    -- press arrives after ping/2, then stays active PARRY_ACTIVE
    local delay = (CFG.PING_MS / 1000) * 0.5
    task.delay(delay, function()
        parryActiveUntil = os.clock() + CFG.PARRY_ACTIVE
        lastPressServer  = os.clock()
    end)
end
ParryButtonPress.Event:Connect(registerPress)
ParryAttempt.Event:Connect(registerPress)

-- Let a human test by pressing Space
if Players.LocalPlayer then
    game:GetService("UserInputService").InputBegan:Connect(function(i, gpe)
        if gpe then return end
        if i.KeyCode == Enum.KeyCode.Space then ParryButtonPress:Fire() end
    end)
end

-- ═══════════════════════════════════════════════════════════════════
--  BALL SPAWNER + PHYSICS  (homing + curve)
-- ═══════════════════════════════════════════════════════════════════
local balls = {}       -- [part] = { vel, speed, curve, alive }
local rng   = Random.new()
local roundSpeed = CFG.SPEED_MIN

local function spawnBall()
    roundSpeed = math.min(roundSpeed + 6, CFG.SPEED_MAX)   -- ramp like the real game
    local ang = rng:NextNumber(0, math.pi * 2)
    local origin = playerPos() + Vector3.new(math.cos(ang), 0, math.sin(ang)) * CFG.SPAWN_DIST

    local ball = Instance.new("Part")
    ball.Shape        = Enum.PartType.Ball
    ball.Size         = Vector3.new(3, 3, 3)
    ball.Anchored     = true
    ball.CanCollide   = false
    ball.Material     = Enum.Material.Neon
    ball.Color        = Color3.fromRGB(255, 210, 90)
    ball.Position     = origin
    -- real Blade Ball attributes: the true ball is flagged "realBall" and
    -- its "target" attribute holds the aimed player's name.
    ball:SetAttribute("realBall", true)
    ball:SetAttribute("target", PLAYER_NAME)
    ball.Parent       = BallsFolder

    local dir = (playerPos() - origin).Unit
    balls[ball] = {
        vel   = dir * roundSpeed,
        speed = roundSpeed,
        curve = rng:NextNumber(0, CFG.CURVE_MAX) * (rng:NextInteger(0, 1) == 0 and 1 or -1),
    }
    BallAdded:Fire(ball)
end

-- ═══════════════════════════════════════════════════════════════════
--  SCORING
-- ═══════════════════════════════════════════════════════════════════
local score = { rounds = 0, parried = 0, dead = 0 }

local function flash(ball, color)
    ball.Color = color
end

local function resolveBall(ball, data, parried)
    score.rounds += 1
    if parried then
        score.parried += 1
        flash(ball, Color3.fromRGB(90, 255, 120))
        ParrySuccessAll:Fire(PLAYER_NAME)
    else
        score.dead += 1
        flash(ball, Color3.fromRGB(255, 70, 70))
    end
    data.dead = true
    BallExplode:Fire(ball)
    task.delay(0.15, function() if ball then ball:Destroy() end end)
    balls[ball] = nil
end

-- ═══════════════════════════════════════════════════════════════════
--  AUTO-PARRY BRAIN  (the exact curve-aware predictor the hub ships)
-- ═══════════════════════════════════════════════════════════════════
local History  = setmetatable({}, { __mode = "k" })

local function pushHistory(ball, pos, vel, now)
    local h = History[ball]
    if not h then h = {} History[ball] = h end
    h[#h + 1] = { t = now, p = pos, v = vel }
    while #h > 6 do table.remove(h, 1) end
    return h
end

local function predictImpact(h, pPos)
    local n = #h
    if n < 1 then return math.huge end
    local last = h[n]
    local p, v = last.p, last.v
    local a = Vector3.zero
    if n >= 3 then
        local dt = h[n].t - h[n-1].t
        if dt > 1e-4 then
            a = (h[n].p - 2 * h[n-1].p + h[n-2].p) / (dt * dt)
        end
    end
    local rel   = p - pPos
    local reach = CFG.HIT_RADIUS
    local t = 0.0
    while t < 3.0 do
        local pt = rel + v * t + 0.5 * a * (t * t)
        if pt.Magnitude <= reach then return t end
        t = t + 1/180
    end
    return math.huge
end

local brainBusy = false
local function brainTick(now)
    if not CFG.BRAIN or brainBusy then return end
    local best, bestT = nil, math.huge
    for ball, data in pairs(balls) do
        if ball and ball.Parent and not data.dead then
            local h = pushHistory(ball, ball.Position, data.vel, now)
            local toMe = playerPos() - ball.Position
            if data.vel:Dot(toMe.Unit) > 0 then
                local t = predictImpact(h, playerPos())
                if t < bestT then best, bestT = ball, t end
            end
        end
    end
    if best then
        local pingFloor = math.max(CFG.PING_MS / 1000, 0.03)
        if bestT <= pingFloor or bestT <= CFG.WINDOW - CFG.MARGIN then
            brainBusy = true
            ParryButtonPress:Fire()
            task.delay(CFG.COOLDOWN, function() brainBusy = false end)
        end
    end
end

-- ═══════════════════════════════════════════════════════════════════
--  HUD
-- ═══════════════════════════════════════════════════════════════════
local hudLabel
if Players.LocalPlayer then
    local gui = Instance.new("ScreenGui")
    gui.Name = "SandboxHUD"
    gui.ResetOnSpawn = false
    gui.Parent = Players.LocalPlayer:WaitForChild("PlayerGui")
    hudLabel = Instance.new("TextLabel")
    hudLabel.Size             = UDim2.fromOffset(360, 96)
    hudLabel.Position         = UDim2.fromOffset(12, 12)
    hudLabel.BackgroundColor3 = Color3.fromRGB(10, 10, 10)
    hudLabel.BackgroundTransparency = 0.35
    hudLabel.TextColor3       = Color3.fromRGB(255, 255, 255)
    hudLabel.Font             = Enum.Font.Code
    hudLabel.TextSize         = 16
    hudLabel.TextXAlignment   = Enum.TextXAlignment.Left
    hudLabel.TextYAlignment   = Enum.TextYAlignment.Top
    hudLabel.Text             = "Sandbox starting…"
    hudLabel.Parent           = gui
end

local function updateHud()
    if not hudLabel then return end
    local rate = score.rounds > 0 and (score.parried / score.rounds * 100) or 0
    hudLabel.Text = string.format(
        " BLADE BALL SANDBOX  (%s)\n Rounds %d   Parried %d   Dead %d\n Success %.1f%%\n Ping %dms   Brain %s",
        CFG.BRAIN and "auto" or "manual",
        score.rounds, score.parried, score.dead, rate,
        CFG.PING_MS, CFG.BRAIN and "ON" or "OFF (press Space)"
    )
end

-- ═══════════════════════════════════════════════════════════════════
--  MAIN LOOP
-- ═══════════════════════════════════════════════════════════════════
local lastSpawn = 0
RunService.Heartbeat:Connect(function(dt)
    local now = os.clock()

    if now - lastSpawn > CFG.SPAWN_EVERY then
        lastSpawn = now
        spawnBall()
    end

    -- advance ball physics (homing + curve)
    for ball, data in pairs(balls) do
        if ball and ball.Parent and not data.dead then
            local toMe = (playerPos() - ball.Position)
            local dir  = toMe.Unit
            -- perpendicular curve
            local perp = Vector3.new(-dir.Z, 0, dir.X) * data.curve
            data.vel   = (dir * data.speed) + perp
            -- move kinematically; the hub derives velocity from position deltas
            ball.Position = ball.Position + data.vel * dt
            if toMe.Magnitude <= CFG.HIT_RADIUS then
                resolveBall(ball, data, now <= parryActiveUntil)
            end
        end
    end

    brainTick(now)
    updateHud()
end)

print("[Blade Ball Sandbox] running — replicating parry mechanics. Brain =", CFG.BRAIN)
