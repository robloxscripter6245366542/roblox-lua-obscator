--!nocheck
--[[
============================================================================
 No-Cooldown Knife  —  direct-remote melee spam (no cooldown, no equip needed)
 Built from the game dump (PlaceId 18879239467).
============================================================================
 Why v1 still felt like it had a cooldown
 ---------------------------------------------------------------------------
  v1 drove the tool's Activate() path, but onActivate() re-checks the client
  gate attributes (Cooldown / Endlag / Stunned / …) itself, so most swings got
  blocked before firing, and it only worked with the knife equipped.

 What this version does
 ---------------------------------------------------------------------------
  It skips onActivate completely and fires the game's own combat remotes
  DIRECTLY, every frame, at every living player near you:
    * ReplicatedStorage.Remotes.Swing:FireServer(direction)   -- the attack
    * ReplicatedStorage.Remotes.Hit:FireServer(target...)     -- the damage
  Because nothing checks a cooldown attribute, there is no cooldown, and
  because it doesn't use the Tool, it works whether or not the knife is
  equipped. It also keeps clearing the gate + hitDebounce attributes so the
  game's own hitbox (if a tool IS equipped) also keeps connecting.

 Honest caveat (unchanged)
 ---------------------------------------------------------------------------
  The Hit remote's exact argument shape isn't recoverable from a bytecode
  dump, so this tries the common shapes (target character / humanoid / with
  direction). If the SERVER validates a cooldown or an exact arg shape, it
  caps what registers — a client script can't change a server-side check.
  If nothing registers, flip USE_HIT shapes or check the console warnings.

 Controls:  RightShift toggles on/off.  _G.NoCDKnife=false stops.
============================================================================
]]

local Players           = game:GetService("Players")
local RunService        = game:GetService("RunService")
local UserInputService  = game:GetService("UserInputService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local lp     = Players.LocalPlayer
local camera = workspace.CurrentCamera

-- ── config ───────────────────────────────────────────────────────────────
local RANGE      = 60      -- studs; players within this get hit
local INTERVAL   = 0       -- seconds between bursts (0 = every frame)
local DIRECTION  = "Center"  -- getDirectionString uses Right / Left / Center

_G.NoCDKnife = (_G.NoCDKnife ~= false)   -- default on; re-running keeps choice

-- gates the client checks before swinging / between hits
local GATES  = { "Cooldown", "Endlag", "Stunned", "Kicking", "Dropkick", "Ragdoll", "Blocking", "Stun", "Windup", "WINDUP" }
local DEBS   = { "hitDebounce", "hitDebounceL", "hitDebounceR", "Debounce" }
local TIMERS = { "cooldownUntil", "ClientCooldownUntil" }

-- ── helpers ───────────────────────────────────────────────────────────────
local function myRoot()
    local c = lp.Character
    return c and c:FindFirstChild("HumanoidRootPart")
end
local function clearGatesOn(inst)
    if not inst then return end
    for _, a in ipairs(GATES) do if inst:GetAttribute(a) ~= nil then pcall(function() inst:SetAttribute(a, false) end) end end
    for _, a in ipairs(DEBS)  do if inst:GetAttribute(a) ~= nil then pcall(function() inst:SetAttribute(a, false) end) end end
    for _, a in ipairs(TIMERS) do if inst:GetAttribute(a) ~= nil then pcall(function() inst:SetAttribute(a, 0) end) end end
end

local function remote(name)
    local r = ReplicatedStorage:FindFirstChild("Remotes")
    r = r and r:FindFirstChild(name, true)
    if r and r:IsA("RemoteEvent") then return r end
    for _, d in ipairs(ReplicatedStorage:GetDescendants()) do
        if d.Name == name and d:IsA("RemoteEvent") then return d end
    end
end

local swingRemote, hitRemote
local function ensureRemotes()
    if not swingRemote then swingRemote = remote("Swing") end
    if not hitRemote   then hitRemote   = remote("Hit")   end
end

-- fire Hit at one target trying the arg shapes the hitbox is likely to use
local function fireHit(target)
    if not hitRemote then return end
    local char = target.Character
    if not char then return end
    local hum  = char:FindFirstChildOfClass("Humanoid")
    local hrp  = char:FindFirstChild("HumanoidRootPart")
    -- clear the target's hit-debounce so repeat hits land
    for _, a in ipairs(DEBS) do
        if char:GetAttribute(a) ~= nil then pcall(function() char:SetAttribute(a, false) end) end
    end
    pcall(function() hitRemote:FireServer(char) end)
    if hum then pcall(function() hitRemote:FireServer(hum) end) end
    if hum and hrp then pcall(function() hitRemote:FireServer(char, hrp.Position, DIRECTION) end) end
end

local function alive(char)
    local h = char and char:FindFirstChildOfClass("Humanoid")
    return h and h.Health > 0
end

local lastBurst = 0
RunService.Heartbeat:Connect(function()
    if not _G.NoCDKnife then return end
    if os.clock() - lastBurst < INTERVAL then return end
    lastBurst = os.clock()
    pcall(function()
        ensureRemotes()
        -- keep our own gates clear (covers the real hitbox path too)
        clearGatesOn(lp.Character)
        local hh = lp.Character and lp.Character:FindFirstChildOfClass("Humanoid")
        clearGatesOn(hh)

        -- the swing itself (plays the attack + lets the server see a swing)
        if swingRemote then pcall(function() swingRemote:FireServer(DIRECTION) end) end

        -- damage every living player in range, directly
        local root = myRoot()
        if not root then return end
        for _, p in ipairs(Players:GetPlayers()) do
            if p ~= lp and p.Character and alive(p.Character) then
                local ehrp = p.Character:FindFirstChild("HumanoidRootPart")
                if ehrp and (ehrp.Position - root.Position).Magnitude <= RANGE then
                    fireHit(p)
                end
            end
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

warn("[No-CD Knife] loaded — fires Swing/Hit directly (no equip needed). RightShift toggles.")
