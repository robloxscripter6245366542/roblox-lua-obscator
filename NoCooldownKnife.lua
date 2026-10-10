--!nocheck
--[[
============================================================================
 No-Cooldown Knife  —  spam melee with the client cooldown removed
 Built from the game dump (PlaceId 18879239467).
============================================================================
 How the game gates attacks (recovered from the client dump)
 ---------------------------------------------------------------------------
  * Each melee module's onActivate() checks CHARACTER / HUMANOID attributes
    before it swings: Cooldown, Endlag, Stunned, Kicking, Dropkick, Ragdoll,
    Blocking. If any is set it refuses to swing.
  * The swing fires ReplicatedStorage.Remotes.Swing:FireServer(direction).
  * Hits come from a client RaycastHitboxV4; the hitbox module fires
    ReplicatedStorage.Remotes.Hit:FireServer(...) on each detected target and
    uses hitDebounce / hitDebounceL / hitDebounceR so it won't re-hit the same
    target during one swing.

 What this does
 ---------------------------------------------------------------------------
  * Every frame it clears those gate attributes (so onActivate never blocks)
    and resets the hitDebounce flags (so the hitbox can keep connecting), then
    re-triggers the equipped tool's Activate() — i.e. it swings as fast as the
    client loop runs. Equip the knife (or any melee) and toggle it on.

 Honest caveat
 ---------------------------------------------------------------------------
  The cooldown in this game is CLIENT-side, so removing it lets you spam the
  swing/hit remotes with no delay. Whether EVERY hit "registers" as damage is
  up to the SERVER: if the server trusts the client hit reports (common for
  RaycastHitbox games) they all land; if it runs its own cooldown it will cap
  them. A client script can't change a server-side check. Also fire the Swing
  remote directly (below) if Activate() isn't enough on your executor.

 Controls:  RightShift toggles it on/off.  Set _G.NoCDKnife=false to stop.
============================================================================
]]

local Players          = game:GetService("Players")
local RunService       = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local ReplicatedStorage= game:GetService("ReplicatedStorage")
local lp = Players.LocalPlayer

-- boolean state-gates (truthy = blocked) and the hit-debounce flags
local GATES = { "Cooldown", "Endlag", "Stunned", "Kicking", "Dropkick", "Ragdoll", "Blocking", "Stun", "Windup", "WINDUP" }
local DEBS  = { "hitDebounce", "hitDebounceL", "hitDebounceR", "Debounce" }
-- time-based cooldown attributes (compared against tick()) → push into the past
local TIMERS = { "cooldownUntil", "ClientCooldownUntil" }

_G.NoCDKnife = (_G.NoCDKnife ~= false)   -- default on; re-running keeps your choice

local function char() return lp.Character end
local function hum()
    local c = char()
    return c and c:FindFirstChildOfClass("Humanoid")
end
local function equippedTool()
    local c = char()
    if not c then return nil end
    return c:FindFirstChildOfClass("Tool")
end

-- the game's Remotes.Swing / Remotes.Hit (best-effort direct fire)
local function remote(name)
    local r = ReplicatedStorage:FindFirstChild("Remotes")
    r = r and r:FindFirstChild(name, true)
    if r and (r:IsA("RemoteEvent") or r:IsA("RemoteFunction")) then return r end
    for _, d in ipairs(ReplicatedStorage:GetDescendants()) do
        if d.Name == name and (d:IsA("RemoteEvent") or d:IsA("RemoteFunction")) then return d end
    end
end

local function clearGates()
    for _, inst in ipairs({ char(), hum() }) do
        if inst then
            for _, a in ipairs(GATES) do
                if inst:GetAttribute(a) ~= nil then pcall(function() inst:SetAttribute(a, false) end) end
            end
            for _, a in ipairs(DEBS) do
                if inst:GetAttribute(a) ~= nil then pcall(function() inst:SetAttribute(a, false) end) end
            end
            for _, a in ipairs(TIMERS) do
                if inst:GetAttribute(a) ~= nil then pcall(function() inst:SetAttribute(a, 0) end) end
            end
        end
    end
end

-- reset the hitbox debounces that live on OTHER characters too (so you can
-- keep hitting the same person): clear hitDebounce* on every character.
local function clearAllDebounces()
    for _, p in ipairs(Players:GetPlayers()) do
        if p ~= lp and p.Character then
            for _, a in ipairs(DEBS) do
                if p.Character:GetAttribute(a) ~= nil then
                    pcall(function() p.Character:SetAttribute(a, false) end)
                end
            end
        end
    end
end

local lastDir = "Center"
local swingRemote

RunService.Heartbeat:Connect(function()
    if not _G.NoCDKnife then return end
    pcall(function()
        clearGates()
        clearAllDebounces()
        local tool = equippedTool()
        if not tool then return end
        -- drive the game's own activation path (fires Swing + runs the hitbox
        -- with the correct args); spam it every frame
        pcall(function() tool:Activate() end)
        -- also fire the Swing remote directly as a fallback
        if not swingRemote then swingRemote = remote("Swing") end
        if swingRemote and swingRemote:IsA("RemoteEvent") then
            pcall(function() swingRemote:FireServer(lastDir) end)
        end
    end)
end)

UserInputService.InputBegan:Connect(function(input, gpe)
    if gpe then return end
    if input.KeyCode == Enum.KeyCode.RightShift then
        _G.NoCDKnife = not _G.NoCDKnife
        warn("[No-CD Knife] " .. (_G.NoCDKnife and "ON" or "OFF"))
    end
end)

warn("[No-CD Knife] loaded — equip your knife; RightShift toggles. _G.NoCDKnife=false to stop.")
