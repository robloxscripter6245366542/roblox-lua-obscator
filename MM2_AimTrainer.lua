--!nocheck
--[[
============================================================================
 MM2_AimTrainer.lua  —  Murder Mystery 2 aim-assist / aim trainer
============================================================================
 A hold-to-lock, FOV-based aim assist for practising sheriff aim in MM2.

  * Hold AIM_KEY -> the camera eases onto the best target inside the FOV.
  * Sticky lock  -> stays on one target instead of jittering between them.
  * FOV circle   -> only targets inside the on-screen circle are considered.
  * Smoothing    -> frame-rate-independent ease-in (1.0 = instant snap).
  * Prediction   -> optional velocity lead for moving targets.
  * Priorities   -> optionally lock the Murderer first (detected by knife),
                    skip downed/dead players, skip yourself.
  * Target part  -> Head / Torso / HumanoidRootPart.
  * Survives death: everything re-resolves per frame and re-hooks on respawn.

 Tuning lives entirely in the CONFIG table below. Press TOGGLE_KEY to
 enable/disable, hold AIM_KEY to lock.

 Note: this only nudges YOUR camera — it never touches the shoot remote, so
 you still fire the shot yourself. Meant as a practice/training aid.
============================================================================
]]

-- ── Config ──────────────────────────────────────────────────────────────
local CONFIG = {
    Enabled           = true,
    AIM_KEY           = Enum.UserInputType.MouseButton2, -- hold right-mouse to lock
    TOGGLE_KEY        = Enum.KeyCode.RightShift,          -- toggle whole script

    FOV               = 120,        -- circle radius in px (targets outside are ignored)
    ShowFOV           = true,
    Smoothing         = 0.35,       -- 0.05 (slow/smooth) .. 1.0 (instant snap)
    TargetPart        = "Head",     -- "Head" / "Torso" / "HumanoidRootPart"

    StickyTarget      = true,       -- keep the same target while AIM_KEY held
    Prediction        = false,      -- lead moving targets (MM2 guns are hitscan)
    PredictionAmount  = 0.14,       -- seconds of lead when Prediction is on

    PrioritizeMurderer = true,      -- prefer the knife-holder when in FOV
    IgnoreDead         = true,      -- skip players with Health <= 0
    IgnoreSelf         = true,
}

-- ── Services ────────────────────────────────────────────────────────────
local Players          = game:GetService("Players")
local RunService       = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")

local lp     = Players.LocalPlayer
local camera = workspace.CurrentCamera

-- ── State ───────────────────────────────────────────────────────────────
local enabled     = CONFIG.Enabled
local aiming      = false
local lockedTo    = nil          -- sticky target Player
local connections = {}

local function track(c) connections[#connections + 1] = c return c end

-- ── FOV circle (Drawing if available, no-op otherwise) ───────────────────
local fovCircle
pcall(function()
    if Drawing then
        fovCircle = Drawing.new("Circle")
        fovCircle.Thickness   = 1.5
        fovCircle.NumSides    = 64
        fovCircle.Radius      = CONFIG.FOV
        fovCircle.Filled      = false
        fovCircle.Color       = Color3.fromRGB(255, 255, 255)
        fovCircle.Transparency = 1
        fovCircle.Visible     = false
    end
end)

-- ── Helpers ─────────────────────────────────────────────────────────────
local function getPart(char)
    if not char then return nil end
    local part = char:FindFirstChild(CONFIG.TargetPart)
    return part or char:FindFirstChild("HumanoidRootPart")
end

local function isAlive(char)
    local hum = char and char:FindFirstChildOfClass("Humanoid")
    return hum and hum.Health > 0
end

-- MM2 murderer carries a "Knife" tool (in character while equipped, or backpack).
local function isMurderer(player)
    local char = player.Character
    if char and char:FindFirstChild("Knife") then return true end
    local bp = player:FindFirstChildOfClass("Backpack")
    if bp and bp:FindFirstChild("Knife") then return true end
    return false
end

-- Screen distance from a world position to the crosshair, plus on-screen flag.
local function screenInfo(worldPos)
    local sp, onScreen = camera:WorldToViewportPoint(worldPos)
    if sp.Z <= 0 then return nil end
    local center = camera.ViewportSize / 2
    local delta  = Vector2.new(sp.X, sp.Y) - center
    return delta.Magnitude, onScreen
end

-- Pick the best candidate inside the FOV circle.
local function selectTarget()
    local best, bestScore
    for _, p in ipairs(Players:GetPlayers()) do
        if not (CONFIG.IgnoreSelf and p == lp) then
            local char = p.Character
            local part = getPart(char)
            if part and (not CONFIG.IgnoreDead or isAlive(char)) then
                local dist = screenInfo(part.Position)
                if dist and dist <= CONFIG.FOV then
                    -- lower score = better. Murderer gets a big bonus.
                    local score = dist
                    if CONFIG.PrioritizeMurderer and isMurderer(p) then
                        score = score - 10000
                    end
                    if not bestScore or score < bestScore then
                        best, bestScore = p, score
                    end
                end
            end
        end
    end
    return best
end

-- Aim point for a target, with optional velocity lead.
local function aimPoint(player)
    local part = getPart(player.Character)
    if not part then return nil end
    local pos = part.Position
    if CONFIG.Prediction then
        local vel = part.AssemblyLinearVelocity
        pos = pos + vel * CONFIG.PredictionAmount
    end
    return pos
end

-- ── Aim loop ────────────────────────────────────────────────────────────
track(RunService.RenderStepped:Connect(function(dt)
    if fovCircle then
        fovCircle.Radius  = CONFIG.FOV
        fovCircle.Position = camera.ViewportSize / 2
        fovCircle.Visible = enabled and CONFIG.ShowFOV
    end

    if not (enabled and aiming) then
        lockedTo = nil
        return
    end

    -- resolve target (sticky if still valid)
    local target = lockedTo
    local valid = target and target.Character and getPart(target.Character)
        and (not CONFIG.IgnoreDead or isAlive(target.Character))
    if not (CONFIG.StickyTarget and valid) then
        target = selectTarget()
        lockedTo = target
    end
    if not target then return end

    local point = aimPoint(target)
    if not point then return end

    -- frame-rate-independent ease toward the target
    local desired = CFrame.new(camera.CFrame.Position, point)
    local alpha = 1 - (1 - math.clamp(CONFIG.Smoothing, 0.01, 1)) ^ (dt * 60)
    camera.CFrame = camera.CFrame:Lerp(desired, alpha)
end))

-- ── Input ───────────────────────────────────────────────────────────────
track(UserInputService.InputBegan:Connect(function(input, gp)
    if gp then return end
    if input.KeyCode == CONFIG.TOGGLE_KEY then
        enabled = not enabled
        warn("[MM2_AimTrainer] " .. (enabled and "ENABLED" or "DISABLED"))
        return
    end
    if input.UserInputType == CONFIG.AIM_KEY or input.KeyCode == CONFIG.AIM_KEY then
        aiming = true
    end
end))

track(UserInputService.InputEnded:Connect(function(input)
    if input.UserInputType == CONFIG.AIM_KEY or input.KeyCode == CONFIG.AIM_KEY then
        aiming = false
        lockedTo = nil
    end
end))

-- ── Respawn: keep working after you die ──────────────────────────────────
track(lp.CharacterAdded:Connect(function()
    lockedTo = nil        -- drop any stale lock on respawn
end))

warn(("[MM2_AimTrainer] loaded — aimKey=%s toggle=%s FOV=%d")
    :format(tostring(CONFIG.AIM_KEY), CONFIG.TOGGLE_KEY.Name, CONFIG.FOV))
