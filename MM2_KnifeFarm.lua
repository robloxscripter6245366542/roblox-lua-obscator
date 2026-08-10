--!nocheck
--[[
============================================================================
 MM2_KnifeFarm.lua  —  Murder Mystery 2 murderer knife auto-farm
============================================================================
 Built against a full game dump of MM2 (PlaceId 129264514977232).

 How the knife kill works (from the dump's KnifeClient)
 ---------------------------------------------------------------------------
  * The knife is a Tool in your character. Its name varies (skins like
    "Beachy"), so we find it by its  KnifeServer.SlashStart  remote, not by
    the name "Knife".
      Character.<KnifeTool>.KnifeServer.SlashStart : RemoteEvent  (melee)
  * A slash is simply:
      SlashStart:FireServer()          -- NO arguments
    The SERVER does the range / hit check and kills whoever is within knife
    reach of you. So the recipe is: teleport behind a target, then slash.

 What this script does
 ---------------------------------------------------------------------------
  * Auto-farms every player as the murderer:
      teleport behind target  ->  SlashStart:FireServer()  ->  repeat
  * Switches to the next target the instant the current one dies.
  * Skips players with a blue ForceField (classic spawn protection — you
    can't kill them). They re-enter the target pool automatically once the
    shield expires.
  * Match-gated: only farms during a live round (MM2 "In Game" status), and
    resumes each new round.
  * Keeps the knife equipped and re-equips after you respawn.
  * Everything pcall-guarded; survives your own death.

 Requires being the murderer (you must have a knife) — a client script
 cannot assign itself the role, so if you have no knife it simply idles.

 Config is the CONFIG table below. TOGGLE_KEY enables/disables.
============================================================================
]]

-- ── Config ──────────────────────────────────────────────────────────────
local CONFIG = {
    Enabled          = true,
    TOGGLE_KEY       = Enum.KeyCode.RightShift,

    AutoFarm         = true,      -- teleport + slash on its own
    FARM_HOLD_KEY    = Enum.KeyCode.F,  -- when AutoFarm off: hold to farm

    BehindDistance   = 2.5,       -- studs behind the target to stand
    SlashInterval    = 0.55,      -- min seconds between slashes (server also gates)
    SwitchOnKill     = true,      -- retarget instantly when the target dies

    SkipForceField   = true,      -- skip players with spawn shield, return when gone
    MatchGated       = true,      -- only farm during a live round
    AutoEquipKnife   = true,      -- keep the knife out; re-equip after respawn

    ReturnAfterKill  = false,     -- teleport back to your start spot when done
}

-- ── Services ────────────────────────────────────────────────────────────
local Players           = game:GetService("Players")
local RunService        = game:GetService("RunService")
local UserInputService  = game:GetService("UserInputService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local lp = Players.LocalPlayer

-- ── State ───────────────────────────────────────────────────────────────
local enabled     = CONFIG.Enabled
local farmHeld    = false
local lastSlash   = 0
local lastEquip   = 0
local lastStatus  = nil
local homeCFrame  = nil        -- where we were before diving in (for ReturnAfterKill)
local connections = {}
local function track(c) connections[#connections + 1] = c return c end

-- ── Match state (UpdateStatus: In Game / Voting / ... ; CurrentMap fallback) ──
local function matchActive()
    if lastStatus == "In Game" then return true end
    local map = workspace:FindFirstChild("CurrentMap")
    return map ~= nil and map:FindFirstChildOfClass("Model") ~= nil
end

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

-- ── Our knife ────────────────────────────────────────────────────────────
-- Returns: tool, SlashStart remote, isEquipped (tool is in the character).
local function findKnife()
    local char = lp.Character
    local bp   = lp:FindFirstChildOfClass("Backpack")
    for _, container in ipairs({ char, bp }) do
        if container then
            for _, tool in ipairs(container:GetChildren()) do
                if tool:IsA("Tool") then
                    local ks = tool:FindFirstChild("KnifeServer")
                    local slash = ks and ks:FindFirstChild("SlashStart")
                    if slash then
                        return tool, slash, tool.Parent == char
                    end
                end
            end
        end
    end
    return nil, nil, false
end

local function ensureKnifeEquipped()
    local char = lp.Character
    local hum  = char and char:FindFirstChildOfClass("Humanoid")
    if not (hum and hum.Health > 0) then return end
    local tool, _, equipped = findKnife()
    if tool and not equipped then
        pcall(function() hum:EquipTool(tool) end)
    end
end

-- ── Target helpers ───────────────────────────────────────────────────────
local function rootOf(player)
    local c = player.Character
    return c and c:FindFirstChild("HumanoidRootPart"), c
end

local function isAlive(char)
    local hum = char and char:FindFirstChildOfClass("Humanoid")
    return hum and hum.Health > 0
end

local function isShielded(char)
    return char:FindFirstChildOfClass("ForceField") ~= nil
end

-- Nearest valid target to us: alive, not self, not shielded (if configured).
local function pickTarget()
    local myRoot = select(1, rootOf(lp))
    local best, bestDist
    for _, p in ipairs(Players:GetPlayers()) do
        if p ~= lp then
            local root, char = rootOf(p)
            if root and isAlive(char) and not (CONFIG.SkipForceField and isShielded(char)) then
                local d = myRoot and (root.Position - myRoot.Position).Magnitude or 0
                if not bestDist or d < bestDist then
                    best, bestDist = p, d
                end
            end
        end
    end
    return best
end

-- Stand just behind the target, facing them (their back = +Z in their CFrame).
local function teleportBehind(targetRoot)
    local myRoot = select(1, rootOf(lp))
    if not (myRoot and targetRoot) then return false end
    local behind = targetRoot.CFrame * CFrame.new(0, 0, CONFIG.BehindDistance)
    myRoot.CFrame = CFrame.new(behind.Position, targetRoot.Position)
    return true
end

-- ── Main farm loop ───────────────────────────────────────────────────────
track(RunService.Heartbeat:Connect(function()
    if not enabled then return end

    -- keep the knife out (throttled)
    if CONFIG.AutoEquipKnife and os.clock() - lastEquip >= 0.25 then
        ensureKnifeEquipped()
        lastEquip = os.clock()
    end

    local wantFarm = CONFIG.AutoFarm or farmHeld
    if not wantFarm then homeCFrame = nil return end
    if CONFIG.MatchGated and not matchActive() then return end

    -- must actually have the knife equipped to deal damage
    local _, slash, equipped = findKnife()
    if not (slash and equipped) then return end

    local target = pickTarget()
    if not target then
        -- nobody killable right now (all shielded / dead) — hold position
        if CONFIG.ReturnAfterKill and homeCFrame then
            local myRoot = select(1, rootOf(lp))
            if myRoot then myRoot.CFrame = homeCFrame end
            homeCFrame = nil
        end
        return
    end

    local targetRoot = select(1, rootOf(target))
    if not targetRoot then return end

    -- remember where we came from the first time we dive in
    if CONFIG.ReturnAfterKill and not homeCFrame then
        local myRoot = select(1, rootOf(lp))
        if myRoot then homeCFrame = myRoot.CFrame end
    end

    teleportBehind(targetRoot)

    local now = os.clock()
    if now - lastSlash >= CONFIG.SlashInterval then
        pcall(function() slash:FireServer() end)
        lastSlash = now
    end
end))

-- ── Input ───────────────────────────────────────────────────────────────
track(UserInputService.InputBegan:Connect(function(input, gp)
    if gp then return end
    if input.KeyCode == CONFIG.TOGGLE_KEY then
        enabled = not enabled
        warn("[MM2_KnifeFarm] " .. (enabled and "ENABLED" or "DISABLED"))
    elseif input.KeyCode == CONFIG.FARM_HOLD_KEY then
        farmHeld = true
    end
end))

track(UserInputService.InputEnded:Connect(function(input)
    if input.KeyCode == CONFIG.FARM_HOLD_KEY then farmHeld = false end
end))

-- ── Respawn: re-equip and keep farming ────────────────────────────────────
track(lp.CharacterAdded:Connect(function(char)
    homeCFrame = nil
    if CONFIG.AutoEquipKnife then
        task.spawn(function()
            char:WaitForChild("Humanoid", 10)
            for _ = 1, 40 do            -- ~4s: knife/backpack stream in late
                if not enabled then return end
                ensureKnifeEquipped()
                local _, _, equipped = findKnife()
                if equipped then return end
                task.wait(0.1)
            end
        end)
    end
end))

warn(("[MM2_KnifeFarm] loaded — toggle=%s  autoFarm=%s  skipShield=%s")
    :format(CONFIG.TOGGLE_KEY.Name, tostring(CONFIG.AutoFarm),
            tostring(CONFIG.SkipForceField)))
