--!nocheck
--[[
============================================================================
 MM2_AimTrainer.lua  —  Murder Mystery 2 aim assist / silent aim
============================================================================
 Built against a full game dump of MM2 (PlaceId 129264514977232).

 Real game structure used by this script
 ---------------------------------------------------------------------------
  * The sheriff/hero gun is a Tool in the character. Its name varies (it can
    be a skin like "Sunny"), so we find it by looking for a child Tool that
    contains  GunServer.ShootStart  — not by the name "Gun".
      Character.<GunTool>.GunServer.ShootStart : RemoteEvent
      Character.<GunTool>.GunServer.Lock       : RemoteEvent
  * Firing is authoritative through the remote:
      ShootStart:FireServer(hitPosition)     -- hitPosition is a Vector3
    The stock client just passes the mouse hit; passing a target's torso
    position instead is a "silent aim" — the shot lands there regardless of
    where the camera points.
  * The murderer holds a Tool containing  KnifeServer  (used to tell roles
    apart so we can prefer / restrict to the murderer).

 Features
 ---------------------------------------------------------------------------
  * Camera aim-assist  : hold AIM_KEY to ease the camera onto the best target.
  * Silent aim + auto  : fire ShootStart directly at the target (no camera
                         movement needed) — toggle SilentAim / AutoShoot.
  * FOV circle, sticky lock, smoothing, optional velocity prediction.
  * Target selection    : prefer the Murderer, or restrict to Murderer only,
                         skip dead players and yourself.
  * Survives your death : re-resolves the gun and target every frame and
                         re-hooks on respawn.

 All tuning is in CONFIG. TOGGLE_KEY enables/disables the whole thing.
 Nothing fires unless you have a gun equipped, so an innocent running this
 does nothing.
============================================================================
]]

-- ── Config ──────────────────────────────────────────────────────────────
local CONFIG = {
    Enabled            = true,
    TOGGLE_KEY         = Enum.KeyCode.RightShift,          -- toggle whole script

    -- Camera aim-assist (hold to drag your camera onto the target)
    CameraAssist       = true,
    AIM_KEY            = Enum.UserInputType.MouseButton2,  -- hold right-mouse
    Smoothing          = 0.35,     -- 0.05 slow .. 1.0 instant snap

    -- Silent aim / auto shoot (fire the real ShootStart remote at the target)
    SilentAim          = true,     -- redirect your shots to the locked target
    AutoShoot          = true,     -- fire on your own, no click needed (auto-farm)
    AutoShootHoldKey   = Enum.UserInputType.MouseButton1,  -- while AutoShoot off: hold to silent-fire
    FireInterval       = 0.10,     -- min seconds between auto shots

    -- Match gating: only auto-farm during a live round. MM2 broadcasts round
    -- state on UpdateStatus ("Voting"/"Map Chosen"/"Loading"/"In Game"/"Clear")
    -- and spawns the map under workspace.CurrentMap while a round is running.
    MatchGated         = true,     -- pause auto-shoot until the match starts, resume each round

    -- Targeting
    FOV                = 140,      -- circle radius px; targets outside are ignored
    ShowFOV            = true,
    ShootPart          = "Head",   -- "Head" / "UpperTorso" / "Torso" / "HumanoidRootPart"
    StickyTarget       = true,
    Prediction         = false,    -- MM2 guns are hitscan; leading usually misses
    PredictionAmount   = 0.14,

    PreferMurderer     = true,     -- prioritise the knife holder
    MurdererOnly       = false,    -- only ever target the murderer
    IgnoreDead         = true,
}

-- ── Services ────────────────────────────────────────────────────────────
local Players          = game:GetService("Players")
local RunService       = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local lp     = Players.LocalPlayer
local camera = workspace.CurrentCamera

-- ── State ───────────────────────────────────────────────────────────────
local enabled     = CONFIG.Enabled
local holding     = false        -- AIM_KEY (camera) held
local firingHeld  = false        -- AutoShootHoldKey held
local lockedTo    = nil          -- sticky target Player
local lastFire    = 0
local lastStatus  = nil        -- most recent UpdateStatus string
local connections = {}
local function track(c) connections[#connections + 1] = c return c end

-- ── Match state ──────────────────────────────────────────────────────────
-- A round is live when the last broadcast status is "In Game", or (as a
-- fallback if we joined mid-round and missed the event) a map Model exists
-- under workspace.CurrentMap.
local function matchActive()
    if lastStatus == "In Game" then return true end
    local map = workspace:FindFirstChild("CurrentMap")
    return map ~= nil and map:FindFirstChildOfClass("Model") ~= nil
end

-- Listen for round-state broadcasts. First arg is the status string.
pcall(function()
    local ev = ReplicatedStorage:FindFirstChild("Events")
    ev = ev and ev:FindFirstChild("RemoteEvents")
    ev = ev and ev:FindFirstChild("UpdateStatus")
    if ev then
        track(ev.OnClientEvent:Connect(function(status)
            if type(status) == "string" then lastStatus = status end
        end))
    end
end)

-- ── FOV circle (Drawing if the executor provides it) ─────────────────────
local fovCircle
pcall(function()
    if Drawing then
        fovCircle = Drawing.new("Circle")
        fovCircle.Thickness    = 1.5
        fovCircle.NumSides     = 64
        fovCircle.Filled       = false
        fovCircle.Color        = Color3.fromRGB(255, 255, 255)
        fovCircle.Transparency = 1
        fovCircle.Visible      = false
    end
end)

-- ── Role / gun detection (from the dump structure) ───────────────────────
-- Find our gun tool by its GunServer.ShootStart remote, wherever the tool is.
local function findGunFire()
    local char = lp.Character
    local bp   = lp:FindFirstChildOfClass("Backpack")
    for _, container in ipairs({ char, bp }) do
        if container then
            for _, tool in ipairs(container:GetChildren()) do
                if tool:IsA("Tool") then
                    local gs = tool:FindFirstChild("GunServer")
                    local shoot = gs and gs:FindFirstChild("ShootStart")
                    if shoot then
                        -- second return: is it equipped (in character)?
                        return shoot, tool.Parent == char
                    end
                end
            end
        end
    end
    return nil, false
end

-- Murderer holds a tool containing KnifeServer.
local function isMurderer(player)
    for _, container in ipairs({ player.Character, player:FindFirstChildOfClass("Backpack") }) do
        if container then
            for _, tool in ipairs(container:GetChildren()) do
                if tool:IsA("Tool") and tool:FindFirstChild("KnifeServer") then
                    return true
                end
            end
        end
    end
    return false
end

-- ── Target helpers ───────────────────────────────────────────────────────
local function getPart(char)
    if not char then return nil end
    return char:FindFirstChild(CONFIG.ShootPart)
        or char:FindFirstChild("Head")
        or char:FindFirstChild("UpperTorso")
        or char:FindFirstChild("HumanoidRootPart")
end

local function isAlive(char)
    local hum = char and char:FindFirstChildOfClass("Humanoid")
    return hum and hum.Health > 0
end

local function screenDist(worldPos)
    local sp = camera:WorldToViewportPoint(worldPos)
    if sp.Z <= 0 then return nil end
    local center = camera.ViewportSize / 2
    return (Vector2.new(sp.X, sp.Y) - center).Magnitude
end

local function selectTarget()
    local best, bestScore
    for _, p in ipairs(Players:GetPlayers()) do
        if p ~= lp then
            local char = p.Character
            local part = getPart(char)
            if part and (not CONFIG.IgnoreDead or isAlive(char)) then
                local murd = isMurderer(p)
                if not CONFIG.MurdererOnly or murd then
                    local dist = screenDist(part.Position)
                    if dist and dist <= CONFIG.FOV then
                        local score = dist
                        if CONFIG.PreferMurderer and murd then
                            score = score - 100000   -- always win ties
                        end
                        if not bestScore or score < bestScore then
                            best, bestScore = p, score
                        end
                    end
                end
            end
        end
    end
    return best
end

local function aimPos(player)
    local part = getPart(player.Character)
    if not part then return nil end
    local pos = part.Position
    if CONFIG.Prediction then
        pos = pos + part.AssemblyLinearVelocity * CONFIG.PredictionAmount
    end
    return pos
end

-- Resolve the current target, honouring the sticky lock.
local function resolveTarget()
    local t = lockedTo
    local valid = t and t.Character and getPart(t.Character)
        and (not CONFIG.IgnoreDead or isAlive(t.Character))
        and (not CONFIG.MurdererOnly or isMurderer(t))
    if not (CONFIG.StickyTarget and valid) then
        t = selectTarget()
        lockedTo = t
    end
    return t
end

-- ── Main loop ────────────────────────────────────────────────────────────
track(RunService.RenderStepped:Connect(function(dt)
    if fovCircle then
        fovCircle.Radius   = CONFIG.FOV
        fovCircle.Position  = camera.ViewportSize / 2
        fovCircle.Visible  = enabled and CONFIG.ShowFOV
    end
    if not enabled then lockedTo = nil return end

    local wantCamera = CONFIG.CameraAssist and holding
    local wantShoot  = CONFIG.SilentAim and (CONFIG.AutoShoot or firingHeld)
    -- pause the farm between rounds; a held manual fire still works.
    if wantShoot and CONFIG.MatchGated and CONFIG.AutoShoot and not firingHeld
       and not matchActive() then
        wantShoot = false
    end
    if not (wantCamera or wantShoot) then
        if not CONFIG.StickyTarget then lockedTo = nil end
        return
    end

    local target = resolveTarget()
    if not target then return end
    local point = aimPos(target)
    if not point then return end

    -- camera ease
    if wantCamera then
        local desired = CFrame.new(camera.CFrame.Position, point)
        local alpha = 1 - (1 - math.clamp(CONFIG.Smoothing, 0.01, 1)) ^ (dt * 60)
        camera.CFrame = camera.CFrame:Lerp(desired, alpha)
    end

    -- silent fire through the real remote
    if wantShoot then
        local now = os.clock()
        if now - lastFire >= CONFIG.FireInterval then
            local shoot, equipped = findGunFire()
            if shoot and equipped then
                pcall(function() shoot:FireServer(point) end)
                lastFire = now
            end
        end
    end
end))

-- ── Input ───────────────────────────────────────────────────────────────
local function matches(input, want)
    return input.UserInputType == want or input.KeyCode == want
end

track(UserInputService.InputBegan:Connect(function(input, gp)
    if input.KeyCode == CONFIG.TOGGLE_KEY and not gp then
        enabled = not enabled
        warn("[MM2_AimTrainer] " .. (enabled and "ENABLED" or "DISABLED"))
        return
    end
    if gp then return end
    if matches(input, CONFIG.AIM_KEY)          then holding    = true end
    if matches(input, CONFIG.AutoShootHoldKey) then firingHeld = true end
end))

track(UserInputService.InputEnded:Connect(function(input)
    if matches(input, CONFIG.AIM_KEY) then
        holding = false
        if not CONFIG.StickyTarget then lockedTo = nil end
    end
    if matches(input, CONFIG.AutoShootHoldKey) then firingHeld = false end
end))

-- ── Respawn: keep working after you die ──────────────────────────────────
track(lp.CharacterAdded:Connect(function()
    lockedTo = nil
end))

warn(("[MM2_AimTrainer] loaded — toggle=%s  camera=%s  silentAim=%s  auto=%s")
    :format(CONFIG.TOGGLE_KEY.Name, tostring(CONFIG.CameraAssist),
            tostring(CONFIG.SilentAim), tostring(CONFIG.AutoShoot)))
