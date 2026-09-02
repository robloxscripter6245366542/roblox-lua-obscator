--!nocheck
--[[
============================================================================
 MM2_AutoShoot.lua  —  closest-player auto-shoot (no FOV circle, no silent aim)
============================================================================
 Dead simple: finds the CLOSEST player to you and fires the gun at them
 automatically, as fast as you set. No FOV circle, no silent-aim hook.

 From the MM2 dump: the gun fires GunServer.ShootStart:FireServer(hitPos)
 with hitPos a Vector3. This fires it at the closest player's exact part
 position (100% accuracy). No hookmetamethod needed — runs on any executor.

 Requires the gun equipped (sheriff/hero) for shots to register. Auto-saves.
============================================================================
]]

-- ── Services ────────────────────────────────────────────────────────────
local Players     = game:GetService("Players")
local RunService  = game:GetService("RunService")
local HttpService = game:GetService("HttpService")

local lp     = Players.LocalPlayer
local camera = workspace.CurrentCamera

-- ── Config + persistence ──────────────────────────────────────────────────
local CONFIG_FILE = "MM2_AutoShoot.json"
local Config = {
    Enabled        = true,
    FireInterval   = 0.05,      -- seconds between shots (~20/s; server also gates)
    TargetPart     = "Head",
    MaxDistance    = 0,         -- 0 = unlimited; else only shoot within this many studs
    PreferMurderer = true,
    SkipShield     = true,      -- skip spawn-shielded (ForceField) players
    VisibleOnly    = false,     -- only shoot players you can see (wall check)
    TeamCheck      = true,      -- skip players on YOUR team (only shoot enemies)
    MurdererOnly   = false,     -- only ever shoot the murderer (knife holder)
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
pcall(function()
    if fsOk() and isfile(CONFIG_FILE) then
        local data = HttpService:JSONDecode(readfile(CONFIG_FILE))
        if type(data) == "table" then
            for k, v in pairs(data) do if Config[k] ~= nil then Config[k] = v end end
        end
    end
end)

-- ── Helpers ────────────────────────────────────────────────────────────────
local function myRoot()
    local c = lp.Character
    return c and c:FindFirstChild("HumanoidRootPart")
end
local function partOf(char)
    if not char then return nil end
    return char:FindFirstChild(Config.TargetPart)
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
local function isMurderer(p)
    local c = p.Character
    if not c then return false end
    for _, t in ipairs(c:GetChildren()) do
        if t:IsA("Tool") and t:FindFirstChild("KnifeServer") then return true end
    end
    return false
end
-- an enemy = not on your team. If either side has no team (Neutral/lobby, or
-- the game tracks roles without Teams), we DON'T skip — so it never silently
-- refuses to shoot when teams aren't set.
local function enemy(p)
    if not Config.TeamCheck then return true end
    local mt = lp.Team
    if mt == nil or p.Team == nil then return true end
    return p.Team ~= mt
end
local function findGun()
    for _, container in ipairs({ lp.Character, lp:FindFirstChildOfClass("Backpack") }) do
        if container then
            for _, t in ipairs(container:GetChildren()) do
                if t:IsA("Tool") then
                    local gs = t:FindFirstChild("GunServer")
                    local sh = gs and gs:FindFirstChild("ShootStart")
                    if sh then return sh, t.Parent == lp.Character end
                end
            end
        end
    end
end
local function canSee(targetChar, worldPos)
    if not Config.VisibleOnly then return true end
    local params = RaycastParams.new()
    params.FilterType = Enum.RaycastFilterType.Exclude
    params.FilterDescendantsInstances = { lp.Character, camera }
    local origin = camera.CFrame.Position
    local hit = workspace:Raycast(origin, (worldPos - origin), params)
    if not hit then return true end
    return hit.Instance:IsDescendantOf(targetChar)
end

-- the CLOSEST player to you (by world distance); prefers the murderer
local function closestPlayer()
    local root = myRoot()
    if not root then return nil end
    local best, bestScore
    for _, p in ipairs(Players:GetPlayers()) do
        if p ~= lp and p.Character and alive(p.Character)
        and not (Config.SkipShield and shielded(p.Character))
        and enemy(p)
        and (not Config.MurdererOnly or isMurderer(p)) then
            local part = partOf(p.Character)
            if part then
                local d = (part.Position - root.Position).Magnitude
                if (Config.MaxDistance <= 0 or d <= Config.MaxDistance)
                and canSee(p.Character, part.Position) then
                    local score = d - (Config.PreferMurderer and isMurderer(p) and 1e6 or 0)
                    if not bestScore or score < bestScore then best, bestScore = p, score end
                end
            end
        end
    end
    return best
end

-- ── Auto-shoot loop ─────────────────────────────────────────────────────────
local lastShot = 0
RunService.Heartbeat:Connect(function()
    if not Config.Enabled then return end
    if os.clock() - lastShot < Config.FireInterval then return end
    local shoot, equipped = findGun()
    if not (shoot and equipped) then return end
    local t = closestPlayer()
    local part = t and partOf(t.Character)
    if not part then return end
    lastShot = os.clock()
    pcall(function() shoot:FireServer(part.Position) end)   -- exact position = 100% accuracy
end)

-- ═══════════════════════════════════════════════════════════════════════
--  UI  —  single WindUI panel
-- ═══════════════════════════════════════════════════════════════════════
local WindUI = loadstring(game:HttpGet(
    "https://github.com/Footagesus/WindUI/releases/latest/download/main.lua"))()

local Window = WindUI:CreateWindow({
    Title        = "Auto Shoot",
    Icon         = "crosshair",
    Author       = "Gun",
    Folder       = "MM2_AutoShoot",
    Size         = UDim2.fromOffset(400, 280),
    Transparent  = true,
    SideBarWidth = 130,
})
pcall(function() Window:SetTransparent(true) end)

local Tab = Window:Tab({ Title = "Auto Shoot", Icon = "crosshair" })
Tab:Section({ Title = "Gun" })

Tab:Toggle({
    Title = "Auto Shoot", Desc = "Find the closest player and shoot them automatically.",
    Value = Config.Enabled,
    Callback = function(v) Config.Enabled = v queueSave() end,
})
Tab:Slider({
    Title = "Fire Rate (ms)", Desc = "Lower = faster (server also gates ammo/cooldown).",
    Value = { Min = 20, Max = 500, Default = math.floor(Config.FireInterval * 1000) },
    Step = 5, Callback = function(v) Config.FireInterval = v / 1000 queueSave() end,
})
Tab:Slider({
    Title = "Max Distance (0 = any)", Desc = "Only shoot players within this many studs.",
    Value = { Min = 0, Max = 500, Default = Config.MaxDistance },
    Step = 10, Callback = function(v) Config.MaxDistance = v queueSave() end,
})
Tab:Dropdown({
    Title = "Target Part", Values = { "Head", "UpperTorso", "Torso", "HumanoidRootPart" },
    Value = Config.TargetPart,
    Callback = function(v) Config.TargetPart = v queueSave() end,
})
Tab:Toggle({
    Title = "Team Check", Desc = "Only shoot enemies (skip players on your team).",
    Value = Config.TeamCheck,
    Callback = function(v) Config.TeamCheck = v queueSave() end,
})
Tab:Toggle({
    Title = "Murderer Only", Desc = "Only shoot the murderer (knife holder).",
    Value = Config.MurdererOnly,
    Callback = function(v) Config.MurdererOnly = v queueSave() end,
})
Tab:Toggle({
    Title = "Prefer Murderer", Desc = "Shoot the knife holder first.",
    Value = Config.PreferMurderer,
    Callback = function(v) Config.PreferMurderer = v queueSave() end,
})
Tab:Toggle({
    Title = "Skip Shielded", Desc = "Skip spawn-protected (ForceField) players.",
    Value = Config.SkipShield,
    Callback = function(v) Config.SkipShield = v queueSave() end,
})
Tab:Toggle({
    Title = "Visible Only", Desc = "Only shoot players you can see (wall check).",
    Value = Config.VisibleOnly,
    Callback = function(v) Config.VisibleOnly = v queueSave() end,
})

WindUI:Notify({ Title = "Auto Shoot", Icon = "check", Duration = 4,
    Content = "Loaded. Enable Auto Shoot — the closest player gets fired on." })
