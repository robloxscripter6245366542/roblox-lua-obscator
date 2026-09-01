--!nocheck
--[[
============================================================================
 MM2_AimLock.lua  —  FOV circle + aim lock + silent-aim flick
============================================================================
 A small, standalone aim tool (no UI library). Three things only:

  1. FOV CIRCLE — a circle at your crosshair, built from a rounded Frame (no
     Drawing library needed, works on any executor). Only targets inside it
     are eligible.

  2. AIM LOCK — hold AIM_KEY to smoothly lock your camera onto the closest
     target that is:
        * in front of you (on-screen), and
        * inside the FOV circle, and
        * NOT behind a wall (a line-of-sight raycast must reach it).
     Release the key to let go. Sticky while held.

  3. SILENT-AIM FLICK — when you fire the gun, your shot is bent to the
     locked / nearest visible target and the camera does a 1-frame flick to
     them and snaps back, so the shot lands while looking like a real flick.
     Wall-checked too — it never grabs someone you can't see. Uses MM2's
     GunServer.ShootStart; needs hookmetamethod (falls back gracefully).

 Everything is pcall-guarded and re-resolves per frame, so it survives death.
============================================================================
]]

-- ── Config ──────────────────────────────────────────────────────────────
local CONFIG = {
    FOV            = 120,                          -- circle radius (px)
    ShowFOV        = true,
    AIM_KEY        = Enum.UserInputType.MouseButton2, -- hold to aim-lock
    Smoothness     = 0.35,                         -- 0.05 slow .. 1 instant
    TargetPart     = "Head",                       -- Head / UpperTorso / HumanoidRootPart
    WallCheck      = true,                         -- ignore targets behind walls
    SilentFlick    = true,                         -- bend + flick your own shots
    FlickCamera    = true,                         -- do the visible 1-frame flick
    TeamCheckSkipFF= true,                          -- skip ForceField (spawn-shielded) players
}

-- ── Services ────────────────────────────────────────────────────────────
local Players          = game:GetService("Players")
local RunService       = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")

local lp     = Players.LocalPlayer
local camera = workspace.CurrentCamera

-- ── State ───────────────────────────────────────────────────────────────
local aiming   = false
local lockedTo = nil

-- ── FOV circle (built from Frames — works on any executor, no Drawing) ─────
-- A square Frame with a full-corner radius renders as a circle; a UIStroke
-- gives the outline. Centered on the crosshair; radius follows CONFIG.FOV.
local fovFrame
pcall(function()
    local host = game:GetService("CoreGui")
    pcall(function() if gethui then host = gethui() end end)
    if not host then host = lp:WaitForChild("PlayerGui") end

    local gui = Instance.new("ScreenGui")
    gui.Name = "AimLockFOV"
    gui.ResetOnSpawn = false
    gui.IgnoreGuiInset = false          -- so scale-center matches the viewport centre
    gui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
    pcall(function() if syn and syn.protect_gui then syn.protect_gui(gui) end end)
    gui.Parent = host

    fovFrame = Instance.new("Frame")
    fovFrame.Name = "Circle"
    fovFrame.AnchorPoint = Vector2.new(0.5, 0.5)
    fovFrame.Position = UDim2.fromScale(0.5, 0.5)
    fovFrame.Size = UDim2.fromOffset(CONFIG.FOV * 2, CONFIG.FOV * 2)
    fovFrame.BackgroundTransparency = 1
    fovFrame.BorderSizePixel = 0
    fovFrame.Visible = false
    fovFrame.Parent = gui

    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(1, 0)   -- full radius on a square = circle
    corner.Parent = fovFrame

    local stroke = Instance.new("UIStroke")
    stroke.Thickness = 1.5
    stroke.Color = Color3.fromRGB(255, 255, 255)
    stroke.Transparency = 0.1
    stroke.Parent = fovFrame
end)

-- ── Helpers ─────────────────────────────────────────────────────────────
local function partOf(char)
    if not char then return nil end
    return char:FindFirstChild(CONFIG.TargetPart)
        or char:FindFirstChild("Head")
        or char:FindFirstChild("UpperTorso")
        or char:FindFirstChild("HumanoidRootPart")
end
local function alive(char)
    local h = char and char:FindFirstChildOfClass("Humanoid")
    return h and h.Health > 0
end
local function shielded(char)
    return char and char:FindFirstChildOfClass("ForceField") ~= nil
end

-- Clear line of sight from the camera to a world point? (nothing solid between)
local function canSee(targetChar, worldPos)
    if not CONFIG.WallCheck then return true end
    local params = RaycastParams.new()
    params.FilterType = Enum.RaycastFilterType.Exclude
    params.FilterDescendantsInstances = { lp.Character, camera }
    local origin = camera.CFrame.Position
    local hit = workspace:Raycast(origin, (worldPos - origin), params)
    if not hit then return true end                 -- nothing in the way
    return hit.Instance:IsDescendantOf(targetChar)  -- first thing hit is the target
end

-- Closest eligible target to the crosshair: on-screen, inside FOV, visible.
local function pickTarget()
    local center = camera.ViewportSize / 2
    local best, bestD
    for _, p in ipairs(Players:GetPlayers()) do
        if p ~= lp and p.Character and alive(p.Character)
        and not (CONFIG.TeamCheckSkipFF and shielded(p.Character)) then
            local part = partOf(p.Character)
            if part then
                local sp = camera:WorldToViewportPoint(part.Position)
                if sp.Z > 0 then                          -- in front of us
                    local d = (Vector2.new(sp.X, sp.Y) - center).Magnitude
                    if d <= CONFIG.FOV and canSee(p.Character, part.Position) then
                        if not bestD or d < bestD then best, bestD = p, d end
                    end
                end
            end
        end
    end
    return best
end

-- ── Aim-lock loop ─────────────────────────────────────────────────────────
RunService.RenderStepped:Connect(function(dt)
    if fovFrame then
        fovFrame.Size    = UDim2.fromOffset(CONFIG.FOV * 2, CONFIG.FOV * 2)
        fovFrame.Visible = CONFIG.ShowFOV
    end
    if not aiming then lockedTo = nil return end

    -- keep the locked target while it stays valid & visible, else re-pick
    local t = lockedTo
    local part = t and t.Character and partOf(t.Character)
    local ok = part and alive(t.Character) and canSee(t.Character, part.Position)
    if not ok then
        t = pickTarget()
        lockedTo = t
        part = t and partOf(t.Character)
    end
    if not (t and part) then return end

    local desired = CFrame.new(camera.CFrame.Position, part.Position)
    local alpha = 1 - (1 - math.clamp(CONFIG.Smoothness, 0.01, 1)) ^ (dt * 60)
    camera.CFrame = camera.CFrame:Lerp(desired, alpha)
end)

-- ── Input ───────────────────────────────────────────────────────────────
UserInputService.InputBegan:Connect(function(input, gp)
    if gp then return end
    if input.UserInputType == CONFIG.AIM_KEY or input.KeyCode == CONFIG.AIM_KEY then
        aiming = true
    end
end)
UserInputService.InputEnded:Connect(function(input)
    if input.UserInputType == CONFIG.AIM_KEY or input.KeyCode == CONFIG.AIM_KEY then
        aiming = false
        lockedTo = nil
    end
end)

-- ── Silent-aim flick (MM2 gun) ────────────────────────────────────────────
-- Bends your own ShootStart to the locked/nearest visible target, and flicks
-- the camera to them for the shot, then snaps back.
do
    local hasHook = (hookmetamethod ~= nil) and (getnamecallmethod ~= nil) and (newcclosure ~= nil)
    if hasHook then
        local fromGame = function()
            if checkcaller then return not checkcaller() end
            return true
        end
        local oldNamecall
        oldNamecall = hookmetamethod(game, "__namecall", newcclosure(function(self, ...)
            local okm, method = pcall(getnamecallmethod)
            if CONFIG.SilentFlick and okm and method == "FireServer"
            and typeof(self) == "Instance" and self.Name == "ShootStart" and fromGame() then
                -- prefer the currently locked target, else nearest visible in FOV
                local t = lockedTo
                local part = t and t.Character and partOf(t.Character)
                if not (part and alive(t.Character) and canSee(t.Character, part.Position)) then
                    t = pickTarget()
                    part = t and partOf(t.Character)
                end
                if part then
                    local restore = camera.CFrame
                    if CONFIG.FlickCamera then
                        camera.CFrame = CFrame.new(camera.CFrame.Position, part.Position) -- flick
                    end
                    local args = { ... }
                    args[1] = part.Position                    -- bend the reported hit
                    local res = oldNamecall(self, table.unpack(args))
                    if CONFIG.FlickCamera and not aiming then
                        camera.CFrame = restore                -- snap back (unless aim-locking)
                    end
                    return res
                end
            end
            return oldNamecall(self, ...)
        end))
    else
        warn("[MM2_AimLock] no hookmetamethod — FOV + aim lock active, silent flick off.")
    end
end

warn("[MM2_AimLock] loaded — hold "
    .. tostring(CONFIG.AIM_KEY) .. " to aim lock. FOV=" .. CONFIG.FOV)
