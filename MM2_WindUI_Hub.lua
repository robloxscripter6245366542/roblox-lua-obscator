--!nocheck
--[[
============================================================================
 MM2_WindUI_Hub.lua  —  Murder Mystery 2 all-in-one hub (WindUI)
============================================================================
 Built against a full game dump of MM2 (PlaceId 129264514977232) and driven
 by the WindUI library (https://github.com/Footagesus/WindUI).

 Real remotes used (verified in the dump)
 ---------------------------------------------------------------------------
  Gun   : Character.<GunTool>.GunServer.ShootStart:FireServer(hitPos)  -- Vector3
  Knife : Character.<KnifeTool>.KnifeServer.SlashStart:FireServer()    -- no args
  Roles : gun tool -> sheriff/hero ; knife tool (KnifeServer) -> murderer
  Round : ReplicatedStorage.Events.RemoteEvents.UpdateStatus  ("In Game" = live)
  Shield: a ForceField in a character = spawn protection (can't be killed)

 Feature list
 ---------------------------------------------------------------------------
  GUN
   * Auto Shoot Aura — any player within range of you (front OR back) is shot
     with 100% accuracy: fires ShootStart at their exact part position.
   * Silent Aim — a __namecall hook that bends YOUR own shots (and knife
     throws) to the nearest target near your cursor, so a manual click always
     lands. Needs an executor with hookmetamethod (falls back gracefully).
   * hold-to-fire, target part, prefer murderer, match gating, auto-equip gun.
  KNIFE
   * Auto Farm — teleport behind the nearest player and slash; switches on
     kill; skips ForceField players; auto-equip knife.
   * Ranged throw (FlingKnife) — auto-throw the knife at the nearest player
     (a kill everyone sees, no teleport); one-shot throw; DualWield toggle.
  PLAYER  — WalkSpeed, JumpPower, Infinite Jump, Noclip, Fly (+speed).
  VISUALS — player ESP (role-coloured highlight + name), Fullbright.
  MISC    — Anti-AFK, rejoin, config auto-save.

 Everything is pcall-guarded and re-hooks on respawn, so it survives death.
 Requires the matching role to actually deal damage (gun = sheriff/hero,
 knife = murderer). A client script can't assign itself the role.
============================================================================
]]

-- ── Services ────────────────────────────────────────────────────────────
local Players           = game:GetService("Players")
local RunService        = game:GetService("RunService")
local UserInputService  = game:GetService("UserInputService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local HttpService       = game:GetService("HttpService")
local Lighting          = game:GetService("Lighting")
local VirtualUser       = game:GetService("VirtualUser")
local TeleportService   = game:GetService("TeleportService")

local lp     = Players.LocalPlayer
local camera = workspace.CurrentCamera

-- ── Config + persistence ──────────────────────────────────────────────────
local CONFIG_FILE = "MM2_WindUI_Hub.json"
local Config = {
    -- gun
    AutoShoot      = false,
    ShootHold      = false,        -- hold FireKey instead of always-on
    AuraRange      = 60,           -- studs; any player within is shot (front/back)
    ShootPart      = "Head",
    FireInterval   = 0.1,
    PreferMurderer = true,
    GunMatchGated  = true,
    AutoEquipGun   = true,
    -- silent aim (redirect your OWN shots via a __namecall hook)
    SilentAim      = false,
    SilentFOV      = 150,          -- px; nearest player to your cursor within this
    SilentKnife    = true,         -- also redirect FlingKnife throws
    SilentFlick    = true,         -- flick the camera to the target for the shot, then snap back
    -- knife
    KnifeFarm      = false,
    BehindDistance = 2.5,
    SlashInterval  = 0.55,
    SkipShield     = true,
    KnifeMatchGated= true,
    AutoEquipKnife = true,
    -- knife throw (ranged — visible to everyone)
    AutoThrow      = false,
    ThrowRange     = 120,
    ThrowInterval  = 0.6,
    -- player
    WalkEnabled    = false, WalkSpeed = 16,
    JumpEnabled    = false, JumpPower = 50,
    InfiniteJump   = false,
    Noclip         = false,
    Fly            = false,  FlySpeed = 60,
    -- visuals
    ESP            = false,
    ESPNames       = true,
    Fullbright     = false,
    -- misc
    AntiAFK        = true,
}

local function fsOk() return (writefile ~= nil) and (readfile ~= nil) and (isfile ~= nil) end
local saveQueued = false
local function saveConfig()
    if not fsOk() then return end
    pcall(function() writefile(CONFIG_FILE, HttpService:JSONEncode(Config)) end)
end
local function queueSave()
    if saveQueued then return end
    saveQueued = true
    task.delay(0.5, function() saveQueued = false saveConfig() end)
end
local function loadConfig()
    if not fsOk() then return end
    pcall(function()
        if isfile(CONFIG_FILE) then
            local data = HttpService:JSONDecode(readfile(CONFIG_FILE))
            if type(data) == "table" then
                for k, v in pairs(data) do if Config[k] ~= nil then Config[k] = v end end
            end
        end
    end)
end
loadConfig()

-- ── Shared state / helpers ──────────────────────────────────────────────
local lastStatus = nil
local connections = {}
local function track(c) connections[#connections + 1] = c return c end

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

local function myRoot()
    local c = lp.Character
    return c and c:FindFirstChild("HumanoidRootPart")
end
local function myHum()
    local c = lp.Character
    return c and c:FindFirstChildOfClass("Humanoid")
end
local function alive(char)
    local h = char and char:FindFirstChildOfClass("Humanoid")
    return h and h.Health > 0
end
local function shielded(char)
    return char and char:FindFirstChildOfClass("ForceField") ~= nil
end
local function partOf(char, name)
    if not char then return nil end
    return char:FindFirstChild(name) or char:FindFirstChild("Head")
        or char:FindFirstChild("UpperTorso") or char:FindFirstChild("HumanoidRootPart")
end

-- gun tool: found by GunServer.ShootStart (name varies with skins)
local function findGun()
    for _, container in ipairs({ lp.Character, lp:FindFirstChildOfClass("Backpack") }) do
        if container then
            for _, t in ipairs(container:GetChildren()) do
                if t:IsA("Tool") then
                    local gs = t:FindFirstChild("GunServer")
                    local sh = gs and gs:FindFirstChild("ShootStart")
                    if sh then return t, sh, t.Parent == lp.Character end
                end
            end
        end
    end
end
-- knife tool: found by KnifeServer.SlashStart
local function findKnife()
    for _, container in ipairs({ lp.Character, lp:FindFirstChildOfClass("Backpack") }) do
        if container then
            for _, t in ipairs(container:GetChildren()) do
                if t:IsA("Tool") then
                    local ks = t:FindFirstChild("KnifeServer")
                    local sl = ks and ks:FindFirstChild("SlashStart")
                    if sl then return t, sl, t.Parent == lp.Character end
                end
            end
        end
    end
end
-- knife with all its server remotes exposed (for throw / dual wield)
local function findKnifeAll()
    for _, container in ipairs({ lp.Character, lp:FindFirstChildOfClass("Backpack") }) do
        if container then
            for _, t in ipairs(container:GetChildren()) do
                if t:IsA("Tool") then
                    local ks = t:FindFirstChild("KnifeServer")
                    if ks and ks:FindFirstChild("SlashStart") then
                        return {
                            tool     = t,
                            handle   = t:FindFirstChild("Handle"),
                            slash    = ks:FindFirstChild("SlashStart"),
                            fling    = ks:FindFirstChild("FlingKnife"),
                            gone     = ks:FindFirstChild("SetKnifeGoneTime"),
                            dual     = ks:FindFirstChild("DualWield"),
                            equipped = t.Parent == lp.Character,
                        }
                    end
                end
            end
        end
    end
end
local function isMurderer(p)
    for _, container in ipairs({ p.Character, p:FindFirstChildOfClass("Backpack") }) do
        if container then
            for _, t in ipairs(container:GetChildren()) do
                if t:IsA("Tool") and t:FindFirstChild("KnifeServer") then return true end
            end
        end
    end
    return false
end
local function equip(tool)
    local h = myHum()
    if h and tool and tool.Parent ~= lp.Character then pcall(function() h:EquipTool(tool) end) end
end

-- ═══════════════════════════════════════════════════════════════════════
--  WindUI
-- ═══════════════════════════════════════════════════════════════════════
local WindUI = loadstring(game:HttpGet(
    "https://github.com/Footagesus/WindUI/releases/latest/download/main.lua"))()

local Window = WindUI:CreateWindow({
    Title        = "MM2 Hub",
    Icon         = "swords",
    Author       = "WindUI Edition",
    Folder       = "MM2_WindUI_Hub",
    Size         = UDim2.fromOffset(600, 460),
    Transparent  = true,
    SideBarWidth = 180,
})
pcall(function() Window:SetTransparent(true) end)

WindUI:Notify({
    Title = "MM2 Hub", Content = "Loaded. Enable Auto Shoot Aura or Knife Farm.",
    Duration = 5, Icon = "check",
})

local GunTab    = Window:Tab({ Title = "Gun",     Icon = "crosshair" })
local KnifeTab  = Window:Tab({ Title = "Knife",   Icon = "swords" })
local PlayerTab = Window:Tab({ Title = "Player",  Icon = "user" })
local VisualTab = Window:Tab({ Title = "Visuals", Icon = "eye" })
local MiscTab   = Window:Tab({ Title = "Misc",    Icon = "settings" })
local InfoTab   = Window:Tab({ Title = "Info",    Icon = "info" })

-- ─────────────────────────────────────────────────────────────────────────
--  GUN  —  100% accuracy auto-shoot aura
-- ─────────────────────────────────────────────────────────────────────────
GunTab:Section({ Title = "Auto Shoot Aura" })

local fireHeld = false
local lastFire = 0

-- nearest player around us (any direction) within AuraRange
local function auraTarget()
    local root = myRoot()
    if not root then return nil end
    local best, bestD
    for _, p in ipairs(Players:GetPlayers()) do
        if p ~= lp and p.Character and alive(p.Character) and not shielded(p.Character) then
            local part = partOf(p.Character, Config.ShootPart)
            if part then
                local d = (part.Position - root.Position).Magnitude
                if d <= Config.AuraRange then
                    local score = d - (Config.PreferMurderer and isMurderer(p) and 100000 or 0)
                    if not bestD or score < bestD then best, bestD = p, score end
                end
            end
        end
    end
    return best
end

GunTab:Toggle({
    Title = "Auto Shoot Aura", Desc = "Shoot any player near you (front or back) with 100% accuracy.",
    Value = Config.AutoShoot,
    Callback = function(v) Config.AutoShoot = v queueSave() end,
})
GunTab:Toggle({
    Title = "Hold To Fire", Desc = "Only fire while holding right-mouse (instead of always-on).",
    Value = Config.ShootHold,
    Callback = function(v) Config.ShootHold = v queueSave() end,
})
GunTab:Slider({
    Title = "Aura Range (studs)",
    Value = { Min = 10, Max = 300, Default = Config.AuraRange },
    Step = 5, Callback = function(v) Config.AuraRange = v queueSave() end,
})
GunTab:Slider({
    Title = "Fire Interval (ms)", Desc = "Server also gates by ammo / cooldown.",
    Value = { Min = 30, Max = 500, Default = math.floor(Config.FireInterval * 1000) },
    Step = 10, Callback = function(v) Config.FireInterval = v / 1000 queueSave() end,
})
GunTab:Dropdown({
    Title = "Target Part", Values = { "Head", "UpperTorso", "Torso", "HumanoidRootPart" },
    Value = Config.ShootPart,
    Callback = function(v) Config.ShootPart = v queueSave() end,
})
GunTab:Toggle({
    Title = "Prefer Murderer", Desc = "Prioritise the knife holder.",
    Value = Config.PreferMurderer,
    Callback = function(v) Config.PreferMurderer = v queueSave() end,
})
GunTab:Toggle({
    Title = "Only During Round", Desc = "Pause the aura between rounds.",
    Value = Config.GunMatchGated,
    Callback = function(v) Config.GunMatchGated = v queueSave() end,
})
GunTab:Toggle({
    Title = "Auto Equip Gun", Desc = "Keep the gun out and re-equip after respawn.",
    Value = Config.AutoEquipGun,
    Callback = function(v) Config.AutoEquipGun = v queueSave() end,
})

-- gun loop
local lastGunEquip = 0
track(RunService.Heartbeat:Connect(function()
    pcall(function()
        if Config.AutoEquipGun and os.clock() - lastGunEquip >= 0.25 then
            lastGunEquip = os.clock()
            local tool = select(1, findGun())
            if tool then equip(tool) end
        end
        if not Config.AutoShoot then return end
        if Config.ShootHold and not fireHeld then return end
        if Config.GunMatchGated and not matchActive() then return end
        local _, shoot, equipped = findGun()
        if not (shoot and equipped) then return end
        local target = auraTarget()
        if not target then return end
        local part = partOf(target.Character, Config.ShootPart)
        if not part then return end
        if os.clock() - lastFire >= Config.FireInterval then
            lastFire = os.clock()
            shoot:FireServer(part.Position)   -- exact position = 100% accuracy
        end
    end)
end))

-- ── Silent aim (redirect YOUR own shots via a __namecall hook) ────────────
GunTab:Section({ Title = "Silent Aim" })

-- nearest player to your cursor within a screen-space FOV (px); prefers murderer
local function nearestToMouse(fovPx)
    local mp = UserInputService:GetMouseLocation()
    local mouse = Vector2.new(mp.X, mp.Y)
    local best, bestScore
    for _, p in ipairs(Players:GetPlayers()) do
        if p ~= lp and p.Character and alive(p.Character) and not shielded(p.Character) then
            local part = partOf(p.Character, Config.ShootPart)
            if part then
                local sp = camera:WorldToViewportPoint(part.Position)
                if sp.Z > 0 then
                    local d = (Vector2.new(sp.X, sp.Y) - mouse).Magnitude
                    if d <= fovPx then
                        local score = d - (Config.PreferMurderer and isMurderer(p) and 100000 or 0)
                        if not bestScore or score < bestScore then best, bestScore = p, score end
                    end
                end
            end
        end
    end
    return best
end

GunTab:Toggle({
    Title = "Silent Aim", Desc = "Redirect YOUR own shots to the nearest target near your cursor — click anywhere, it hits.",
    Value = Config.SilentAim,
    Callback = function(v) Config.SilentAim = v queueSave() end,
})
GunTab:Slider({
    Title = "Silent Aim FOV (px)",
    Value = { Min = 30, Max = 1000, Default = Config.SilentFOV },
    Step = 10, Callback = function(v) Config.SilentFOV = v queueSave() end,
})
GunTab:Toggle({
    Title = "Silent Knife Throws", Desc = "Also bend FlingKnife throws to the target.",
    Value = Config.SilentKnife,
    Callback = function(v) Config.SilentKnife = v queueSave() end,
})
GunTab:Toggle({
    Title = "Flick Camera", Desc = "Flick the camera to the target for the shot, then snap back.",
    Value = Config.SilentFlick,
    Callback = function(v) Config.SilentFlick = v queueSave() end,
})

-- install the hook once; needs executor metamethod support
do
    local hasHook = (hookmetamethod ~= nil) and (getnamecallmethod ~= nil) and (newcclosure ~= nil)
    if not hasHook then
        WindUI:Notify({
            Title = "Silent Aim", Icon = "alert-triangle", Duration = 7,
            Content = "Your executor lacks hookmetamethod — Silent Aim unavailable (the aura still works).",
        })
    else
        local fromGame = function()
            -- true when the GAME (your own gun/knife script) made the call, not us
            if checkcaller then return not checkcaller() end
            return true
        end
        -- flick the camera to a point for the shot, fire, then snap back
        local function flickFire(self, pos, args)
            local restore = camera.CFrame
            if Config.SilentFlick then
                camera.CFrame = CFrame.new(camera.CFrame.Position, pos)
            end
            local res = oldNamecall(self, table.unpack(args))
            if Config.SilentFlick then camera.CFrame = restore end
            return res
        end
        oldNamecall = hookmetamethod(game, "__namecall", newcclosure(function(self, ...)
            local okm, method = pcall(getnamecallmethod)
            if okm and method == "FireServer" and typeof(self) == "Instance" and Config.SilentAim then
                local nm = self.Name
                if nm == "ShootStart" and fromGame() then
                    local t = nearestToMouse(Config.SilentFOV)
                    local part = t and partOf(t.Character, Config.ShootPart)
                    if part then
                        local args = { ... }
                        args[1] = part.Position          -- bend the reported hit position
                        return flickFire(self, part.Position, args)
                    end
                elseif nm == "FlingKnife" and Config.SilentKnife and fromGame() then
                    local t = nearestToMouse(Config.SilentFOV)
                    local part = t and partOf(t.Character, "UpperTorso")
                    if part then
                        local args = { ... }
                        args[1] = CFrame.new(part.Position)   -- first FlingKnife arg is a CFrame
                        return flickFire(self, part.Position, args)
                    end
                end
            end
            return oldNamecall(self, ...)
        end))
    end
end

-- ─────────────────────────────────────────────────────────────────────────
--  KNIFE  —  teleport-behind auto-farm
-- ─────────────────────────────────────────────────────────────────────────
KnifeTab:Section({ Title = "Knife Auto Farm" })

local lastSlash = 0
local lastKnifeEquip = 0

local function knifeTarget()
    local root = myRoot()
    local best, bestD
    for _, p in ipairs(Players:GetPlayers()) do
        if p ~= lp and p.Character and alive(p.Character)
        and not (Config.SkipShield and shielded(p.Character)) then
            local r = p.Character:FindFirstChild("HumanoidRootPart")
            if r then
                local d = root and (r.Position - root.Position).Magnitude or 0
                if not bestD or d < bestD then best, bestD = p, d end
            end
        end
    end
    return best
end

KnifeTab:Toggle({
    Title = "Knife Auto Farm", Desc = "Teleport behind the nearest player and slash.",
    Value = Config.KnifeFarm,
    Callback = function(v) Config.KnifeFarm = v queueSave() end,
})
KnifeTab:Slider({
    Title = "Behind Distance (studs)",
    Value = { Min = 0, Max = 8, Default = Config.BehindDistance },
    Step = 0.5, Callback = function(v) Config.BehindDistance = v queueSave() end,
})
KnifeTab:Slider({
    Title = "Slash Interval (ms)",
    Value = { Min = 200, Max = 1500, Default = math.floor(Config.SlashInterval * 1000) },
    Step = 25, Callback = function(v) Config.SlashInterval = v / 1000 queueSave() end,
})
KnifeTab:Toggle({
    Title = "Skip Shielded", Desc = "Skip spawn-protected (ForceField) players.",
    Value = Config.SkipShield,
    Callback = function(v) Config.SkipShield = v queueSave() end,
})
KnifeTab:Toggle({
    Title = "Only During Round",
    Value = Config.KnifeMatchGated,
    Callback = function(v) Config.KnifeMatchGated = v queueSave() end,
})
KnifeTab:Toggle({
    Title = "Auto Equip Knife", Desc = "Keep the knife out and re-equip after respawn.",
    Value = Config.AutoEquipKnife,
    Callback = function(v) Config.AutoEquipKnife = v queueSave() end,
})

track(RunService.Heartbeat:Connect(function()
    pcall(function()
        if Config.AutoEquipKnife and os.clock() - lastKnifeEquip >= 0.25 then
            lastKnifeEquip = os.clock()
            local tool = select(1, findKnife())
            if tool then equip(tool) end
        end
        if not Config.KnifeFarm then return end
        if Config.KnifeMatchGated and not matchActive() then return end
        local _, slash, equipped = findKnife()
        if not (slash and equipped) then return end
        local target = knifeTarget()
        local root = myRoot()
        if not (target and root) then return end
        local tr = target.Character:FindFirstChild("HumanoidRootPart")
        if not tr then return end
        root.CFrame = CFrame.new((tr.CFrame * CFrame.new(0, 0, Config.BehindDistance)).Position, tr.Position)
        if os.clock() - lastSlash >= Config.SlashInterval then
            lastSlash = os.clock()
            slash:FireServer()
        end
    end)
end))

-- knife throw (ranged kill — visible to everyone) + dual wield
KnifeTab:Section({ Title = "Knife Throw (ranged — everyone sees)" })

local lastThrow = 0
-- throw the knife at a world position, exactly like the stock KnifeClient:
--   FlingKnife:FireServer(CFrame.new(hitPos), Handle.Position)  then  SetKnifeGoneTime()
local function throwAt(k, pos)
    if not (k and k.fling and k.equipped) then return false end
    local from = (k.handle and k.handle.Position) or (myRoot() and myRoot().Position) or pos
    pcall(function()
        k.fling:FireServer(CFrame.new(pos), from)
        if k.gone then k.gone:FireServer() end
    end)
    return true
end

KnifeTab:Toggle({
    Title = "Auto Throw Knife", Desc = "Throw your knife at the nearest player — ranged, no teleport.",
    Value = Config.AutoThrow,
    Callback = function(v) Config.AutoThrow = v queueSave() end,
})
KnifeTab:Slider({
    Title = "Throw Range (studs)",
    Value = { Min = 20, Max = 400, Default = Config.ThrowRange },
    Step = 10, Callback = function(v) Config.ThrowRange = v queueSave() end,
})
KnifeTab:Slider({
    Title = "Throw Interval (ms)",
    Value = { Min = 300, Max = 2000, Default = math.floor(Config.ThrowInterval * 1000) },
    Step = 50, Callback = function(v) Config.ThrowInterval = v / 1000 queueSave() end,
})
KnifeTab:Button({
    Title = "Throw At Nearest (once)",
    Callback = function()
        local k = findKnifeAll()
        local root = myRoot()
        if not (k and root) then return end
        local best, bd
        for _, p in ipairs(Players:GetPlayers()) do
            if p ~= lp and p.Character and alive(p.Character) and not shielded(p.Character) then
                local part = partOf(p.Character, "UpperTorso")
                if part then
                    local d = (part.Position - root.Position).Magnitude
                    if not bd or d < bd then best, bd = part, d end
                end
            end
        end
        if best then throwAt(k, best.Position) end
    end,
})
KnifeTab:Button({
    Title = "Toggle Dual Wield", Desc = "Fire the DualWield remote (may need the gamepass to take effect).",
    Callback = function()
        local k = findKnifeAll()
        if k and k.dual then pcall(function() k.dual:FireServer() end) end
    end,
})

track(RunService.Heartbeat:Connect(function()
    pcall(function()
        if not Config.AutoThrow then return end
        if Config.KnifeMatchGated and not matchActive() then return end
        local k = findKnifeAll()
        if not (k and k.fling and k.equipped) then return end
        local root = myRoot()
        if not root then return end
        if os.clock() - lastThrow < Config.ThrowInterval then return end
        local best, bd
        for _, p in ipairs(Players:GetPlayers()) do
            if p ~= lp and p.Character and alive(p.Character) and not shielded(p.Character) then
                local part = partOf(p.Character, "UpperTorso")
                if part then
                    local d = (part.Position - root.Position).Magnitude
                    if d <= Config.ThrowRange and (not bd or d < bd) then best, bd = part, d end
                end
            end
        end
        if best then
            lastThrow = os.clock()
            throwAt(k, best.Position)
        end
    end)
end))

-- ─────────────────────────────────────────────────────────────────────────
--  PLAYER  —  movement
-- ─────────────────────────────────────────────────────────────────────────
PlayerTab:Section({ Title = "Movement" })

PlayerTab:Toggle({
    Title = "WalkSpeed", Value = Config.WalkEnabled,
    Callback = function(v) Config.WalkEnabled = v queueSave() end,
})
PlayerTab:Slider({
    Title = "WalkSpeed Value",
    Value = { Min = 16, Max = 200, Default = Config.WalkSpeed },
    Step = 1, Callback = function(v) Config.WalkSpeed = v queueSave() end,
})
PlayerTab:Toggle({
    Title = "JumpPower", Value = Config.JumpEnabled,
    Callback = function(v) Config.JumpEnabled = v queueSave() end,
})
PlayerTab:Slider({
    Title = "JumpPower Value",
    Value = { Min = 50, Max = 350, Default = Config.JumpPower },
    Step = 5, Callback = function(v) Config.JumpPower = v queueSave() end,
})
PlayerTab:Toggle({
    Title = "Infinite Jump", Value = Config.InfiniteJump,
    Callback = function(v) Config.InfiniteJump = v queueSave() end,
})
PlayerTab:Toggle({
    Title = "Noclip", Desc = "Walk through walls.", Value = Config.Noclip,
    Callback = function(v) Config.Noclip = v queueSave() end,
})
PlayerTab:Toggle({
    Title = "Fly", Desc = "WASD + Space/Shift. Camera-relative.", Value = Config.Fly,
    Callback = function(v) Config.Fly = v queueSave() end,
})
PlayerTab:Slider({
    Title = "Fly Speed",
    Value = { Min = 10, Max = 250, Default = Config.FlySpeed },
    Step = 5, Callback = function(v) Config.FlySpeed = v queueSave() end,
})

-- movement loops
track(RunService.Heartbeat:Connect(function()
    pcall(function()
        local h = myHum()
        if h then
            if Config.WalkEnabled then h.WalkSpeed = Config.WalkSpeed end
            if Config.JumpEnabled then
                h.UseJumpPower = true
                h.JumpPower = Config.JumpPower
            end
        end
    end)
end))
track(RunService.Stepped:Connect(function()
    if not Config.Noclip then return end
    local char = lp.Character
    if char then
        for _, p in ipairs(char:GetDescendants()) do
            if p:IsA("BasePart") and p.CanCollide then p.CanCollide = false end
        end
    end
end))
track(UserInputService.JumpRequest:Connect(function()
    if Config.InfiniteJump then
        local h = myHum()
        if h then pcall(function() h:ChangeState(Enum.HumanoidStateType.Jumping) end) end
    end
end))

-- fly
local flyBV, flyBG
local function stopFly()
    if flyBV then flyBV:Destroy() flyBV = nil end
    if flyBG then flyBG:Destroy() flyBG = nil end
end
track(RunService.RenderStepped:Connect(function()
    if not Config.Fly then if flyBV then stopFly() end return end
    local hrp = myRoot()
    if not hrp then return end
    if not flyBV then
        flyBV = Instance.new("BodyVelocity")
        flyBV.MaxForce = Vector3.new(1, 1, 1) * 9e9
        flyBV.Velocity = Vector3.zero
        flyBV.Parent = hrp
        flyBG = Instance.new("BodyGyro")
        flyBG.MaxForce = Vector3.new(1, 1, 1) * 9e9
        flyBG.P = 1e5
        flyBG.Parent = hrp
    end
    flyBG.CFrame = camera.CFrame
    local dir = Vector3.zero
    local cf = camera.CFrame
    if UserInputService:IsKeyDown(Enum.KeyCode.W) then dir += cf.LookVector end
    if UserInputService:IsKeyDown(Enum.KeyCode.S) then dir -= cf.LookVector end
    if UserInputService:IsKeyDown(Enum.KeyCode.A) then dir -= cf.RightVector end
    if UserInputService:IsKeyDown(Enum.KeyCode.D) then dir += cf.RightVector end
    if UserInputService:IsKeyDown(Enum.KeyCode.Space) then dir += Vector3.new(0, 1, 0) end
    if UserInputService:IsKeyDown(Enum.KeyCode.LeftShift) then dir -= Vector3.new(0, 1, 0) end
    flyBV.Velocity = (dir.Magnitude > 0 and dir.Unit or Vector3.zero) * Config.FlySpeed
end))

-- ─────────────────────────────────────────────────────────────────────────
--  VISUALS  —  ESP + fullbright
-- ─────────────────────────────────────────────────────────────────────────
VisualTab:Section({ Title = "ESP" })

local highlights = {}   -- player -> { hl = Highlight, bb = BillboardGui }
local function hasGun(p)
    for _, c in ipairs({ p.Character, p:FindFirstChildOfClass("Backpack") }) do
        if c then
            for _, t in ipairs(c:GetChildren()) do
                if t:IsA("Tool") and t:FindFirstChild("GunServer") then return true end
            end
        end
    end
    return false
end
local function roleColor(p)
    if isMurderer(p) then return Color3.fromRGB(255, 60, 60) end   -- murderer = red
    if hasGun(p)      then return Color3.fromRGB(70, 140, 255) end  -- sheriff/hero = blue
    return Color3.fromRGB(235, 235, 235)                            -- innocent = white
end
local function clearESP(p)
    local e = highlights[p]
    if e then
        if e.hl then e.hl:Destroy() end
        if e.bb then e.bb:Destroy() end
        highlights[p] = nil
    end
end
local function clearAllESP()
    for p in pairs(highlights) do clearESP(p) end
end
track(RunService.Heartbeat:Connect(function()
    pcall(function()
        if not Config.ESP then if next(highlights) then clearAllESP() end return end
        for _, p in ipairs(Players:GetPlayers()) do
            if p ~= lp and p.Character and alive(p.Character) then
                local e = highlights[p]
                if not e then
                    local hl = Instance.new("Highlight")
                    hl.FillTransparency = 0.6
                    hl.OutlineTransparency = 0
                    hl.Parent = p.Character
                    local bb = Instance.new("BillboardGui")
                    bb.Size = UDim2.fromOffset(120, 20)
                    bb.StudsOffset = Vector3.new(0, 3, 0)
                    bb.AlwaysOnTop = true
                    local lbl = Instance.new("TextLabel")
                    lbl.Size = UDim2.fromScale(1, 1)
                    lbl.BackgroundTransparency = 1
                    lbl.Font = Enum.Font.GothamBold
                    lbl.TextSize = 13
                    lbl.TextStrokeTransparency = 0.4
                    lbl.Parent = bb
                    bb.Parent = p.Character
                    e = { hl = hl, bb = bb, lbl = lbl }
                    highlights[p] = e
                end
                e.hl.Adornee = p.Character
                local col = roleColor(p)
                e.hl.FillColor = col
                e.hl.OutlineColor = col
                e.bb.Adornee = p.Character:FindFirstChild("Head") or p.Character:FindFirstChild("HumanoidRootPart")
                e.bb.Enabled = Config.ESPNames
                e.lbl.TextColor3 = col
                e.lbl.Text = p.DisplayName
            else
                clearESP(p)
            end
        end
        for p in pairs(highlights) do
            if not p.Character or not p.Parent then clearESP(p) end
        end
    end)
end))
Players.PlayerRemoving:Connect(clearESP)

VisualTab:Toggle({
    Title = "Player ESP", Desc = "Role-coloured highlight (murderer red / sheriff blue).",
    Value = Config.ESP,
    Callback = function(v) Config.ESP = v if not v then clearAllESP() end queueSave() end,
})
VisualTab:Toggle({
    Title = "ESP Names", Value = Config.ESPNames,
    Callback = function(v) Config.ESPNames = v queueSave() end,
})

VisualTab:Section({ Title = "World" })
local savedLighting
VisualTab:Toggle({
    Title = "Fullbright", Value = Config.Fullbright,
    Callback = function(v)
        Config.Fullbright = v queueSave()
        pcall(function()
            if v then
                savedLighting = savedLighting or {
                    Brightness = Lighting.Brightness, ClockTime = Lighting.ClockTime,
                    FogEnd = Lighting.FogEnd, Ambient = Lighting.Ambient,
                }
                Lighting.Brightness = 2
                Lighting.ClockTime = 14
                Lighting.FogEnd = 1e9
                Lighting.Ambient = Color3.fromRGB(180, 180, 180)
            elseif savedLighting then
                Lighting.Brightness = savedLighting.Brightness
                Lighting.ClockTime = savedLighting.ClockTime
                Lighting.FogEnd = savedLighting.FogEnd
                Lighting.Ambient = savedLighting.Ambient
            end
        end)
    end,
})

-- ─────────────────────────────────────────────────────────────────────────
--  MISC
-- ─────────────────────────────────────────────────────────────────────────
MiscTab:Section({ Title = "Server" })
MiscTab:Toggle({
    Title = "Anti-AFK", Desc = "Never get kicked for idling.", Value = Config.AntiAFK,
    Callback = function(v) Config.AntiAFK = v queueSave() end,
})
MiscTab:Button({
    Title = "Rejoin Server",
    Callback = function()
        pcall(function() TeleportService:Teleport(game.PlaceId, lp) end)
    end,
})
MiscTab:Button({
    Title = "Reset Character",
    Callback = function()
        local h = myHum()
        if h then h.Health = 0 end
    end,
})

pcall(function()
    track(lp.Idled:Connect(function()
        if Config.AntiAFK then
            pcall(function()
                VirtualUser:CaptureController()
                VirtualUser:ClickButton2(Vector2.new())
            end)
        end
    end))
end)

-- ─────────────────────────────────────────────────────────────────────────
--  INFO
-- ─────────────────────────────────────────────────────────────────────────
InfoTab:Section({ Title = "About" })
InfoTab:Paragraph({
    Title = "MM2 Hub",
    Desc = "Gun aura + knife farm built on the real MM2 remotes. Choices auto-save. "
        .. "You need the matching role (gun = sheriff/hero, knife = murderer) to deal damage.",
})

-- ── Respawn: re-equip weapons and reset ESP ──────────────────────────────
track(lp.CharacterAdded:Connect(function(char)
    task.spawn(function()
        char:WaitForChild("Humanoid", 10)
        for _ = 1, 40 do
            if Config.AutoEquipGun then local g = select(1, findGun()) if g then equip(g) end end
            if Config.AutoEquipKnife then local k = select(1, findKnife()) if k then equip(k) end end
            task.wait(0.1)
        end
    end)
end))

warn("[MM2_WindUI_Hub] loaded.")
