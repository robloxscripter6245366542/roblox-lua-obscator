--!nocheck
--[[
============================================================================
 Nexus (WindUI Edition)  —  multi-game hub
============================================================================
 A rebuild of Nexus on top of the WindUI library
 (https://github.com/Footagesus/WindUI) with an animated "Granite" dark
 theme: a slow-drifting grayscale gradient painted over the near-black
 window so the panel looks like living dark stone.

 What changed vs. the old Nexus
 ---------------------------------------------------------------------------
  * UI framework   : custom hand-rolled panel  ->  WindUI
  * Theme          : static black             ->  animated moving Granite
  * Game support   : Prison Life ONLY         ->  auto-detects the game and
                     builds the matching feature set; universal features
                     (player mods, ESP, teleports, server tools) work
                     everywhere, so "many more games" are supported.

 Supported game modules
 ---------------------------------------------------------------------------
  * Prison Life (155615604 / 135564683255158)
      team changer, kill aura (meleeEvent), click / mouse teleport
      (RequestHere), no-collision (RequestCollisionChange), TP to nearest
      giver — the real remotes recovered from the Prison Life dump.
  * Murder Mystery 2 — auto-picks the remote scheme by PlaceId:
      - modern (129264514977232): GunServer.ShootStart /
        KnifeServer.SlashStart / FlingKnife.
      - classic (142823291): Remotes.Gameplay.GunFired / KnifeThrown /
        GetLatestPlayerData, plus auto-collect coins (CoinVisual tag).
      Both give auto shoot aura + silent aim, knife auto-farm + ranged
      throw, and role-aware targeting — real remotes from the MM2 dumps
      (see MM2_ClassicDump_Deobfuscated.md).
  * Any other game
      the Universal tabs (Player / Visuals / Teleport / Server / Misc)
      still give you speed, jump, fly, noclip, infinite jump, ESP,
      fullbright, no-fog, teleports, rejoin, server hop and anti-AFK.

 Everything is pcall-guarded and re-applies on respawn.
============================================================================
]]

-- ── Services ───────────────────────────────────────────────────────────
local Players           = game:GetService("Players")
local RunService        = game:GetService("RunService")
local UserInputService  = game:GetService("UserInputService")
local TweenService      = game:GetService("TweenService")
local Lighting          = game:GetService("Lighting")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local HttpService       = game:GetService("HttpService")
local TeleportService   = game:GetService("TeleportService")
local CoreGui           = game:GetService("CoreGui")

local lp     = Players.LocalPlayer
local camera = workspace.CurrentCamera

-- Single-instance guard: re-running toggles the previous session off.
if _G.NexusWindUIActive then
    _G.NexusWindUIActive = false
    task.wait(0.1)
end
_G.NexusWindUIActive = true

-- ── Game detection ─────────────────────────────────────────────────────
local GAMES = {
    PrisonLife = { [155615604] = true, [135564683255158] = true },
    MM2        = { [129264514977232] = true, [142823291] = true },
    Plus1Forge = { [118805555015549] = true },
    DonateGame = { [76653273729321] = true },
    CloneBuild = { [98456203230140] = true },
}

local function detectGame()
    local id = game.PlaceId
    if GAMES.PrisonLife[id] then return "PrisonLife", "Prison Life" end
    if GAMES.MM2[id]        then return "MM2",        "Murder Mystery 2" end
    if GAMES.Plus1Forge[id] then return "Plus1Forge", "Plus 1 Forge" end
    if GAMES.DonateGame[id] then return "DonateGame", "Donation Game" end
    if GAMES.CloneBuild[id] then return "CloneBuild", "Clone Builders" end
    return "Universal", "Universal"
end

local GameKey, GameName = detectGame()

-- MM2 has two remote schemes: classic (142823291) uses
-- Remotes.Gameplay.GunFired / KnifeThrown; modern (129264514977232) uses
-- GunServer.ShootStart / KnifeServer.SlashStart on the tool.
local MM2Variant = (game.PlaceId == 142823291) and "classic" or "modern"

-- ── Config + persistence ───────────────────────────────────────────────
local CONFIG_FILE = "Nexus_WindUI.json"
local Config = {
    -- player (universal)
    WalkEnabled  = false, WalkSpeed = 16,
    JumpEnabled  = false, JumpPower = 50,
    InfiniteJump = false,
    Noclip       = false,
    Fly          = false, FlySpeed = 60,
    -- visuals (universal)
    ESP          = false,
    ESPNames     = true,
    ESPTeamColor = true,
    Fullbright   = false,
    NoFog        = false,
    -- misc (universal)
    AntiAFK      = true,
    -- prison life
    KillAura       = false,
    KillAuraRange  = 14,
    KillAuraTeam   = true,
    ClickTP        = false,
    -- mm2
    AutoShoot      = false,
    ShootHold      = false,
    AuraRange      = 60,
    FireInterval   = 0.1,
    ShootPart      = "Head",
    PreferMurderer = false,
    GunMatchGated  = false,
    AutoEquipGun   = false,
    SilentAim      = false,
    SilentFOV      = 140,
    SilentKnife    = true,
    KnifeFarm      = false,
    KnifeRange     = 250,
    KnifeInterval  = 0.35,
    AutoEquipKnife = false,
    KnifeThrow     = false,
    ThrowRange     = 120,
    ThrowInterval  = 0.6,
    -- mm2 classic (coins)
    AutoCoins      = false,
    CoinInterval   = 0.15,
    CoinReturn     = true,
    -- mm2 role-aware auto farm
    AutoFarm       = false,
    FarmRange      = 300,
    FarmInterval   = 0.35,
    FarmAutoEquip  = true,
    FarmMatchGated = false,
    FarmCoins      = true,
    -- plus 1 forge
    PFAutoTrain    = false,
    PFTrainInterval= 0.1,
    PFAutoRebirth  = false,
    PFAutoLuck     = false,
    PFAutoUpgrade  = false,
    PFAutoSell     = false,
    PFAutoForge    = false,
    PFLoopInterval = 1.0,
    -- donation game (quests / coins)
    DGAutoQuest    = false,
    DGAutoCoins    = false,
    DGQuestInterval= 0.5,
    -- clone builders
    CBCloneAmount  = 24,
    CBAutoAssign   = false,
    CBPermanent    = true,
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

-- ── Shared helpers ──────────────────────────────────────────────────────
local connections = {}
local function track(c) connections[#connections + 1] = c return c end

local function myChar() return lp.Character end
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
local function nearestPlayer(maxDist)
    local root = myRoot()
    if not root then return nil end
    local best, bestD
    for _, p in ipairs(Players:GetPlayers()) do
        if p ~= lp and p.Character and alive(p.Character) then
            local e = p.Character:FindFirstChild("HumanoidRootPart")
            if e then
                local d = (e.Position - root.Position).Magnitude
                if (not maxDist or d <= maxDist) and (not bestD or d < bestD) then
                    best, bestD = p, d
                end
            end
        end
    end
    return best
end

-- ═══════════════════════════════════════════════════════════════════════
--  WindUI  +  animated Granite dark theme
-- ═══════════════════════════════════════════════════════════════════════
local WindUI = loadstring(game:HttpGet(
    "https://github.com/Footagesus/WindUI/releases/latest/download/main.lua"))()

-- A near-black stone palette. Accent is a cool granite-quartz white so text
-- and toggles stay readable against the dark grain.
pcall(function()
    WindUI:AddTheme({
        Name        = "Granite",
        Accent      = "#c8ccd6",
        Dialog      = "#0c0c0e",
        Outline     = "#3a3a42",
        Text        = "#eef0f6",
        Placeholder = "#8a8a94",
        Background  = "#0a0a0c",
        Button      = "#17171b",
        Icon        = "#d6d8e2",
    })
    WindUI:SetTheme("Granite")
end)

local Window = WindUI:CreateWindow({
    Title        = "Nexus",
    Icon         = "gem",
    Author       = "Granite • " .. GameName,
    Folder       = "Nexus_WindUI",
    Size         = UDim2.fromOffset(620, 470),
    Transparent  = true,
    Theme        = "Granite",
    SideBarWidth = 190,
})
pcall(function() Window:SetTransparent(true) end)

-- ---- Animated moving granite overlay --------------------------------------
-- WindUI parents its GUI to gethui()/CoreGui/PlayerGui. Find the ScreenGui it
-- created, then paint an animated multi-band grayscale UIGradient over the
-- largest rounded frames (window shell + sidebar). The gradient MULTIPLIES the
-- already-dark background, so it only carves darker veins that slowly drift and
-- rotate like living stone; nothing brightens the UI.
do
    local function guiRoot()
        local ok, hui = pcall(function() return gethui() end)
        if ok and hui then return hui end
        local pg = lp:FindFirstChildOfClass("PlayerGui")
        return pg or CoreGui
    end

    local function makeGranite(parent, rot)
        local g = Instance.new("UIGradient")
        g.Rotation = rot
        g.Color = ColorSequence.new({
            ColorSequenceKeypoint.new(0.00, Color3.fromRGB(255, 255, 255)),
            ColorSequenceKeypoint.new(0.28, Color3.fromRGB(150, 150, 160)),
            ColorSequenceKeypoint.new(0.52, Color3.fromRGB(214, 214, 226)),
            ColorSequenceKeypoint.new(0.76, Color3.fromRGB(132, 132, 144)),
            ColorSequenceKeypoint.new(1.00, Color3.fromRGB(238, 238, 250)),
        })
        g.Parent = parent
        return g
    end

    task.spawn(function()
        -- Give WindUI a moment to build its instances.
        local grads = {}
        for _ = 1, 40 do
            if #grads > 0 then break end
            task.wait(0.1)
            pcall(function()
                local root = guiRoot()
                for _, sg in ipairs(root:GetChildren()) do
                    -- only WindUI's own ScreenGui, never the game's UI
                    if sg:IsA("ScreenGui") and sg.Name:lower():find("wind") then
                        -- collect big rounded frames inside this ScreenGui
                        local candidates = {}
                        for _, f in ipairs(sg:GetDescendants()) do
                            if f:IsA("Frame") and f:FindFirstChildOfClass("UICorner")
                                and f.AbsoluteSize.X > 140 and f.AbsoluteSize.Y > 140 then
                                candidates[#candidates + 1] = f
                            end
                        end
                        table.sort(candidates, function(a, b)
                            return (a.AbsoluteSize.X * a.AbsoluteSize.Y) > (b.AbsoluteSize.X * b.AbsoluteSize.Y)
                        end)
                        -- attach granite to the two largest frames (shell + sidebar/body)
                        for i = 1, math.min(2, #candidates) do
                            if not candidates[i]:FindFirstChildOfClass("UIGradient") then
                                grads[#grads + 1] = makeGranite(candidates[i], i == 1 and 25 or 115)
                            end
                        end
                    end
                    if #grads > 0 then break end
                end
            end)
        end

        if #grads == 0 then return end
        local t0 = os.clock()
        track(RunService.Heartbeat:Connect(function()
          pcall(function()
            local t = os.clock() - t0
            for i, g in ipairs(grads) do
                if i == 1 then
                    g.Offset   = Vector2.new(math.sin(t * 0.11) * 0.22, math.sin(t * 0.08 + 1.1) * 0.22)
                    g.Rotation = 25 + math.sin(t * 0.05) * 35
                else
                    g.Offset   = Vector2.new(math.sin(t * 0.09 + 2.0) * 0.18, math.sin(t * 0.07) * 0.18)
                    g.Rotation = 115 + math.sin(t * 0.045 + 0.7) * 30
                end
            end
          end)
        end))
    end)
end

WindUI:Notify({
    Title = "Nexus • Granite",
    Content = ("Loaded for %s. Theme: animated Granite."):format(GameName),
    Duration = 5, Icon = "gem",
})

-- ═══════════════════════════════════════════════════════════════════════
--  UNIVERSAL  —  Player
-- ═══════════════════════════════════════════════════════════════════════
local PlayerTab = Window:Tab({ Title = "Player", Icon = "user" })

PlayerTab:Section({ Title = "Movement" })

PlayerTab:Toggle({
    Title = "WalkSpeed", Desc = "Override your walk speed.",
    Value = Config.WalkEnabled,
    Callback = function(v) Config.WalkEnabled = v queueSave() end,
})
PlayerTab:Slider({
    Title = "Walk Speed",
    Value = { Min = 16, Max = 300, Default = Config.WalkSpeed },
    Step = 1, Callback = function(v) Config.WalkSpeed = v queueSave() end,
})
PlayerTab:Toggle({
    Title = "JumpPower", Desc = "Override your jump power.",
    Value = Config.JumpEnabled,
    Callback = function(v) Config.JumpEnabled = v queueSave() end,
})
PlayerTab:Slider({
    Title = "Jump Power",
    Value = { Min = 50, Max = 500, Default = Config.JumpPower },
    Step = 5, Callback = function(v) Config.JumpPower = v queueSave() end,
})
PlayerTab:Toggle({
    Title = "Infinite Jump", Desc = "Jump again mid-air.",
    Value = Config.InfiniteJump,
    Callback = function(v) Config.InfiniteJump = v queueSave() end,
})
PlayerTab:Toggle({
    Title = "Noclip", Desc = "Walk through walls.",
    Value = Config.Noclip,
    Callback = function(v) Config.Noclip = v queueSave() end,
})

PlayerTab:Section({ Title = "Fly" })
PlayerTab:Toggle({
    Title = "Fly", Desc = "WASD / drag to fly (mobile: use joystick).",
    Value = Config.Fly,
    Callback = function(v) Config.Fly = v queueSave() end,
})
PlayerTab:Slider({
    Title = "Fly Speed",
    Value = { Min = 10, Max = 300, Default = Config.FlySpeed },
    Step = 5, Callback = function(v) Config.FlySpeed = v queueSave() end,
})
PlayerTab:Button({
    Title = "Reset Character", Desc = "Respawn.",
    Callback = function()
        local h = myHum()
        if h then h.Health = 0 end
    end,
})

-- apply walk/jump each heartbeat (survives respawn)
track(RunService.Heartbeat:Connect(function()
    pcall(function()
        local h = myHum()
        if not h then return end
        if Config.WalkEnabled then h.WalkSpeed = Config.WalkSpeed end
        if Config.JumpEnabled then
            h.UseJumpPower = true
            h.JumpPower = Config.JumpPower
        end
    end)
end))

-- infinite jump
track(UserInputService.JumpRequest:Connect(function()
    if not Config.InfiniteJump then return end
    local h = myHum()
    if h then pcall(function() h:ChangeState(Enum.HumanoidStateType.Jumping) end) end
end))

-- noclip
track(RunService.Stepped:Connect(function()
    if not Config.Noclip then return end
    local c = myChar()
    if not c then return end
    for _, part in ipairs(c:GetDescendants()) do
        if part:IsA("BasePart") and part.CanCollide then part.CanCollide = false end
    end
end))

-- fly
do
    local flyBV, flyBG, flying
    local function stopFly()
        flying = false
        if flyBV then flyBV:Destroy() flyBV = nil end
        if flyBG then flyBG:Destroy() flyBG = nil end
    end
    local function startFly()
        local root = myRoot()
        if not root then return end
        stopFly()
        flying = true
        flyBV = Instance.new("BodyVelocity")
        flyBV.MaxForce = Vector3.new(1, 1, 1) * 9e9
        flyBV.Velocity = Vector3.zero
        flyBV.Parent = root
        flyBG = Instance.new("BodyGyro")
        flyBG.MaxTorque = Vector3.new(1, 1, 1) * 9e9
        flyBG.P = 9e4
        flyBG.Parent = root
    end
    track(RunService.Heartbeat:Connect(function()
        if not Config.Fly then
            if flying then stopFly() end
            return
        end
        local root = myRoot()
        if not root then return end
        -- (re)create the body movers if missing or left on an old character
        if not flying or not flyBV or flyBV.Parent ~= root then startFly() end
        if not (flyBV and flyBG) then return end
        local cf = camera.CFrame
        local dir = Vector3.zero
        if UserInputService:IsKeyDown(Enum.KeyCode.W) then dir = dir + cf.LookVector end
        if UserInputService:IsKeyDown(Enum.KeyCode.S) then dir = dir - cf.LookVector end
        if UserInputService:IsKeyDown(Enum.KeyCode.A) then dir = dir - cf.RightVector end
        if UserInputService:IsKeyDown(Enum.KeyCode.D) then dir = dir + cf.RightVector end
        if UserInputService:IsKeyDown(Enum.KeyCode.Space) then dir = dir + Vector3.new(0, 1, 0) end
        if UserInputService:IsKeyDown(Enum.KeyCode.LeftShift) then dir = dir - Vector3.new(0, 1, 0) end
        flyBV.Velocity = dir * Config.FlySpeed
        flyBG.CFrame = cf
    end))
end

-- ═══════════════════════════════════════════════════════════════════════
--  UNIVERSAL  —  Visuals (ESP + light)
-- ═══════════════════════════════════════════════════════════════════════
local VisualTab = Window:Tab({ Title = "Visuals", Icon = "eye" })

VisualTab:Section({ Title = "ESP" })
VisualTab:Toggle({
    Title = "Player ESP", Desc = "Highlight every other player through walls.",
    Value = Config.ESP,
    Callback = function(v) Config.ESP = v queueSave() end,
})
VisualTab:Toggle({
    Title = "ESP Names", Desc = "Show a name tag above each player.",
    Value = Config.ESPNames,
    Callback = function(v) Config.ESPNames = v queueSave() end,
})
VisualTab:Toggle({
    Title = "Team Colour", Desc = "Colour the highlight by the player's team.",
    Value = Config.ESPTeamColor,
    Callback = function(v) Config.ESPTeamColor = v queueSave() end,
})

VisualTab:Section({ Title = "Lighting" })
VisualTab:Toggle({
    Title = "Fullbright", Desc = "Remove darkness.",
    Value = Config.Fullbright,
    Callback = function(v) Config.Fullbright = v queueSave() end,
})
VisualTab:Toggle({
    Title = "No Fog", Desc = "Clear distance fog.",
    Value = Config.NoFog,
    Callback = function(v) Config.NoFog = v queueSave() end,
})

-- ESP driver (Highlight + BillboardGui)
do
    local espFolder
    local tags = {}   -- [player] = {highlight, billboard}
    local function ensureFolder()
        if espFolder and espFolder.Parent then return espFolder end
        espFolder = Instance.new("Folder")
        espFolder.Name = "Nexus_ESP"
        pcall(function()
            local ok, hui = pcall(function() return gethui() end)
            espFolder.Parent = (ok and hui) or CoreGui
        end)
        return espFolder
    end
    local function roleColor(p)
        if not Config.ESPTeamColor then return Color3.fromRGB(200, 200, 210) end
        -- MM2: murderer red, else default; other games: team color
        if GameKey == "MM2" then
            -- modern: KnifeServer tool; classic: tool tagged Weapon_Knife / named knife
            local CS = game:GetService("CollectionService")
            local isM = false
            for _, container in ipairs({ p.Character, p:FindFirstChildOfClass("Backpack") }) do
                if container then
                    for _, t in ipairs(container:GetChildren()) do
                        if t:IsA("Tool") and (t:FindFirstChild("KnifeServer")
                            or CS:HasTag(t, "Weapon_Knife") or t.Name:lower():find("knife")) then
                            isM = true break
                        end
                    end
                end
            end
            if isM then return Color3.fromRGB(255, 70, 70) end
            return Color3.fromRGB(90, 170, 255)
        end
        if p.Team then return p.TeamColor.Color end
        return Color3.fromRGB(90, 170, 255)
    end
    local function clearTag(p)
        local t = tags[p]
        if t then
            if t.highlight then t.highlight:Destroy() end
            if t.billboard then t.billboard:Destroy() end
            tags[p] = nil
        end
    end
    local function makeTag(p)
        local char = p.Character
        if not char then return end
        local hl = Instance.new("Highlight")
        hl.Adornee = char
        hl.FillTransparency = 0.55
        hl.OutlineTransparency = 0
        hl.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
        hl.Parent = ensureFolder()
        local bb = Instance.new("BillboardGui")
        bb.Size = UDim2.fromOffset(200, 22)
        bb.StudsOffset = Vector3.new(0, 3, 0)
        bb.AlwaysOnTop = true
        bb.Parent = ensureFolder()
        local lbl = Instance.new("TextLabel")
        lbl.BackgroundTransparency = 1
        lbl.Size = UDim2.fromScale(1, 1)
        lbl.Font = Enum.Font.GothamMedium
        lbl.TextSize = 14
        lbl.TextStrokeTransparency = 0.4
        lbl.Parent = bb
        tags[p] = { highlight = hl, billboard = bb, label = lbl }
    end
    track(RunService.Heartbeat:Connect(function()
        if not Config.ESP then
            for p in pairs(tags) do clearTag(p) end
            return
        end
        for _, p in ipairs(Players:GetPlayers()) do
            if p ~= lp then
                if p.Character and alive(p.Character) then
                    local t = tags[p]
                    if not t or not (t.highlight and t.highlight.Parent) then
                        clearTag(p) makeTag(p) t = tags[p]
                    end
                    if t then
                        local col = roleColor(p)
                        t.highlight.Adornee = p.Character
                        t.highlight.FillColor = col
                        t.highlight.OutlineColor = col
                        local head = p.Character:FindFirstChild("Head")
                        t.billboard.Adornee = head
                        t.billboard.Enabled = Config.ESPNames and head ~= nil
                        t.label.Text = p.DisplayName
                        t.label.TextColor3 = col
                    end
                else
                    clearTag(p)
                end
            end
        end
    end))
    Players.PlayerRemoving:Connect(clearTag)
end

-- Fullbright / No fog
do
    local saved
    track(RunService.Heartbeat:Connect(function()
        if Config.Fullbright then
            if not saved then
                saved = { b = Lighting.Brightness, a = Lighting.Ambient, o = Lighting.OutdoorAmbient, c = Lighting.ClockTime }
            end
            Lighting.Brightness = 2
            Lighting.ClockTime = 14
            Lighting.Ambient = Color3.fromRGB(178, 178, 178)
            Lighting.OutdoorAmbient = Color3.fromRGB(178, 178, 178)
        elseif saved then
            Lighting.Brightness = saved.b
            Lighting.Ambient = saved.a
            Lighting.OutdoorAmbient = saved.o
            saved = nil
        end
        if Config.NoFog then
            Lighting.FogStart = 0
            Lighting.FogEnd = 1e9
        end
    end))
end

-- ═══════════════════════════════════════════════════════════════════════
--  UNIVERSAL  —  Teleport
-- ═══════════════════════════════════════════════════════════════════════
local TeleportTab = Window:Tab({ Title = "Teleport", Icon = "map-pin" })
local savedWaypoint

TeleportTab:Section({ Title = "Quick teleports" })
TeleportTab:Button({
    Title = "TP to Nearest Player",
    Callback = function()
        local root = myRoot()
        local target = nearestPlayer()
        local e = target and target.Character and target.Character:FindFirstChild("HumanoidRootPart")
        if root and e then
            root.CFrame = e.CFrame * CFrame.new(0, 0, 3)
            WindUI:Notify({ Title = "Teleport", Content = "-> " .. target.DisplayName, Duration = 3 })
        else
            WindUI:Notify({ Title = "Teleport", Content = "No target", Duration = 3, Icon = "alert-triangle" })
        end
    end,
})
TeleportTab:Button({
    Title = "Save Waypoint",
    Callback = function()
        local root = myRoot()
        if root then savedWaypoint = root.CFrame
            WindUI:Notify({ Title = "Waypoint", Content = "Saved current position", Duration = 3 })
        end
    end,
})
TeleportTab:Button({
    Title = "Teleport to Waypoint",
    Callback = function()
        local root = myRoot()
        if root and savedWaypoint then root.CFrame = savedWaypoint
        else WindUI:Notify({ Title = "Waypoint", Content = "None saved", Duration = 3, Icon = "alert-triangle" }) end
    end,
})

-- ═══════════════════════════════════════════════════════════════════════
--  UNIVERSAL  —  Server
-- ═══════════════════════════════════════════════════════════════════════
local ServerTab = Window:Tab({ Title = "Server", Icon = "server" })

ServerTab:Button({
    Title = "Rejoin Server",
    Callback = function()
        WindUI:Notify({ Title = "Rejoin", Content = "Teleporting...", Duration = 3 })
        pcall(function() TeleportService:Teleport(game.PlaceId, lp) end)
    end,
})
ServerTab:Button({
    Title = "Server Hop",
    Callback = function()
        WindUI:Notify({ Title = "Server Hop", Content = "Searching...", Duration = 3 })
        task.spawn(function()
            local ok, servers = pcall(function()
                local body = game:HttpGet("https://games.roblox.com/v1/games/" .. game.PlaceId
                    .. "/servers/Public?sortOrder=Asc&limit=100")
                return HttpService:JSONDecode(body)
            end)
            if ok and servers and servers.data then
                for _, s in ipairs(servers.data) do
                    if type(s) == "table" and s.playing and s.maxPlayers
                        and s.playing < s.maxPlayers and tostring(s.id) ~= tostring(game.JobId) then
                        local done = pcall(function()
                            TeleportService:TeleportToPlaceInstance(game.PlaceId, s.id, lp)
                        end)
                        if done then return end
                    end
                end
            end
            WindUI:Notify({ Title = "Server Hop", Content = "No server found", Duration = 3, Icon = "alert-triangle" })
        end)
    end,
})
ServerTab:Button({
    Title = "Copy Job ID",
    Callback = function()
        if setclipboard then pcall(setclipboard, game.JobId) end
        WindUI:Notify({ Title = "Job ID", Content = game.JobId, Duration = 4 })
    end,
})

-- ═══════════════════════════════════════════════════════════════════════
--  UNIVERSAL  —  Misc
-- ═══════════════════════════════════════════════════════════════════════
local MiscTab = Window:Tab({ Title = "Misc", Icon = "settings" })
MiscTab:Toggle({
    Title = "Anti-AFK", Desc = "Never get kicked for idling.",
    Value = Config.AntiAFK,
    Callback = function(v) Config.AntiAFK = v queueSave() end,
})
do
    local ok, VirtualUser = pcall(function() return game:GetService("VirtualUser") end)
    if ok and VirtualUser then
        track(lp.Idled:Connect(function()
            if not Config.AntiAFK then return end
            pcall(function()
                VirtualUser:CaptureController()
                VirtualUser:ClickButton2(Vector2.new())
            end)
        end))
    end
end

-- ═══════════════════════════════════════════════════════════════════════
--  UNIVERSAL  —  Animations (play any animation on your character)
-- ═══════════════════════════════════════════════════════════════════════
local AnimTab = Window:Tab({ Title = "Anims", Icon = "person-standing" })
do
    local animId, animSpeed, animLoop = "", 1, true
    local currentTrack

    local function myAnimator()
        local char = lp.Character
        local hum = char and char:FindFirstChildOfClass("Humanoid")
        if not hum then return nil end
        return hum:FindFirstChildOfClass("Animator") or hum, hum
    end
    local function stopAnim()
        if currentTrack then pcall(function() currentTrack:Stop() end) currentTrack = nil end
    end
    local function playAnim()
        local id = tostring(animId):gsub("%D", "")   -- keep digits only
        if id == "" then
            WindUI:Notify({ Title = "Anims", Content = "Enter an animation ID first", Duration = 3, Icon = "alert-triangle" })
            return
        end
        local animator = myAnimator()
        if not animator then
            WindUI:Notify({ Title = "Anims", Content = "No character loaded", Duration = 3, Icon = "alert-triangle" })
            return
        end
        stopAnim()
        local anim = Instance.new("Animation")
        anim.AnimationId = "rbxassetid://" .. id
        local ok, track = pcall(function() return animator:LoadAnimation(anim) end)
        if not ok or not track then
            WindUI:Notify({ Title = "Anims", Content = "Couldn't load that animation", Duration = 4, Icon = "alert-triangle" })
            return
        end
        currentTrack = track
        track.Looped = animLoop
        track:Play()
        pcall(function() track:AdjustSpeed(animSpeed) end)
        WindUI:Notify({ Title = "Anims", Content = "Playing " .. id, Duration = 3 })
    end

    AnimTab:Section({ Title = "Play animation" })
    AnimTab:Input({ Title = "Animation ID", Placeholder = "e.g. 507771019 or rbxassetid://...",
        Callback = function(v) animId = v end })
    AnimTab:Slider({ Title = "Speed",
        Value = { Min = 0, Max = 5, Default = 1 }, Step = 0.1,
        Callback = function(v) animSpeed = v if currentTrack then pcall(function() currentTrack:AdjustSpeed(v) end) end end })
    AnimTab:Toggle({ Title = "Loop", Value = true,
        Callback = function(v) animLoop = v if currentTrack then currentTrack.Looped = v end end })
    AnimTab:Button({ Title = "Play", Callback = playAnim })
    AnimTab:Button({ Title = "Stop", Callback = stopAnim })
    AnimTab:Button({ Title = "Stop All Playing Anims", Desc = "Stop every track on your character.",
        Callback = function()
            local animator = myAnimator()
            if animator then
                for _, t in ipairs(animator:GetPlayingAnimationTracks()) do pcall(function() t:Stop() end) end
            end
            stopAnim()
        end })
    -- clear our handle on respawn so a stale track isn't reused
    track(lp.CharacterAdded:Connect(function() currentTrack = nil end))
end

-- ═══════════════════════════════════════════════════════════════════════
--  UNIVERSAL  —  Code (run your own Lua, like a mini executor)
-- ═══════════════════════════════════════════════════════════════════════
local CodeTab = Window:Tab({ Title = "Code", Icon = "code" })
do
    local codeText, scriptUrl = "", ""
    local function runSource(src, label)
        if not src or src == "" then return end
        local fn, err = loadstring(src)
        if not fn then
            WindUI:Notify({ Title = "Code", Content = "Compile error: " .. tostring(err), Duration = 6, Icon = "alert-triangle" })
            warn("[Nexus] compile error:", err)
            return
        end
        local ok, res = pcall(fn)
        if not ok then
            WindUI:Notify({ Title = "Code", Content = "Runtime error: " .. tostring(res), Duration = 6, Icon = "alert-triangle" })
            warn("[Nexus] runtime error:", res)
        else
            WindUI:Notify({ Title = "Code", Content = (label or "Ran") .. " ✓", Duration = 3, Icon = "check" })
        end
    end

    CodeTab:Section({ Title = "Run Lua" })
    CodeTab:Input({ Title = "Code", Placeholder = "print('hi') — paste a line of Lua",
        Callback = function(v) codeText = v end })
    CodeTab:Button({ Title = "Execute", Desc = "loadstring + run the code above (needs an executor).",
        Callback = function()
            if not loadstring then
                WindUI:Notify({ Title = "Code", Content = "loadstring unavailable in this environment", Duration = 5, Icon = "alert-triangle" })
                return
            end
            runSource(codeText, "Executed")
        end })

    CodeTab:Section({ Title = "Run a script from a URL" })
    CodeTab:Input({ Title = "Script URL", Placeholder = "https://.../script.lua",
        Callback = function(v) scriptUrl = v end })
    CodeTab:Button({ Title = "Fetch & Run", Desc = "HttpGet the URL, then loadstring it.",
        Callback = function()
            if scriptUrl == "" then return end
            local ok, body = pcall(function() return game:HttpGet(scriptUrl, true) end)
            if not ok or not body then
                WindUI:Notify({ Title = "Code", Content = "Fetch failed (HTTP blocked?)", Duration = 5, Icon = "alert-triangle" })
                return
            end
            runSource(body, "Ran URL")
        end })
    CodeTab:Paragraph({ Title = "Note",
        Desc = "This runs YOUR own Lua in your session via loadstring — it needs an "
            .. "executor that provides loadstring/HttpGet. WindUI's input is single-line; "
            .. "for a big script, host it and use Fetch & Run. Server-side rules still "
            .. "apply: your code can't do anything the game's server wouldn't let a client do." })
end

-- ═══════════════════════════════════════════════════════════════════════
--  PRISON LIFE  —  real remotes recovered from the dump
-- ═══════════════════════════════════════════════════════════════════════
if GameKey == "PrisonLife" then
    local PLTab = Window:Tab({ Title = "Prison Life", Icon = "shield" })

    local function getRemote(name)
        local remotes = ReplicatedStorage:FindFirstChild("Remotes")
        return remotes and remotes:FindFirstChild(name)
    end

    -- Team change: modern RequestTeamChange, classic workspace.Remote.TeamEvent.
    local function setTeam(teamName, brickColor)
        local done = pcall(function()
            local req = getRemote("RequestTeamChange")
            if not req then error("no RequestTeamChange") end
            if req:IsA("RemoteFunction") then req:InvokeServer(teamName)
            else req:FireServer(teamName) end
        end)
        if not done and brickColor then
            done = pcall(function()
                local rf = workspace:FindFirstChild("Remote")
                local te = rf and rf:FindFirstChild("TeamEvent")
                if not te then error("no TeamEvent") end
                te:FireServer(BrickColor.new(brickColor))
            end)
        end
        WindUI:Notify({ Title = "Team", Content = done and teamName or "remote missing",
            Duration = 3, Icon = done and "check" or "alert-triangle" })
    end
    local function becomeCriminal()
        local hrp = myRoot()
        if not hrp then return end
        local old = hrp.CFrame
        hrp.CFrame = CFrame.new(-919.958, 95.327, 2138.189)
        task.wait(0.14)
        if hrp and hrp.Parent then hrp.CFrame = old end
        WindUI:Notify({ Title = "Team", Content = "Criminal", Duration = 3 })
    end

    PLTab:Section({ Title = "Team Changer" })
    PLTab:Button({ Title = "Neutral",          Callback = function() setTeam("Neutral", "Medium stone grey") end })
    PLTab:Button({ Title = "Prisoner / Inmate", Callback = function() setTeam("Inmates", "Bright orange") end })
    PLTab:Button({ Title = "Police / Guard",    Callback = function() setTeam("Guards",  "Bright blue") end })
    PLTab:Button({ Title = "Criminal", Callback = function()
        if getRemote("RequestTeamChange") then setTeam("Criminals") else becomeCriminal() end
    end })

    PLTab:Section({ Title = "Combat" })
    PLTab:Toggle({
        Title = "Kill Aura", Desc = "Auto-melee nearby players (meleeEvent).",
        Value = false,
        Callback = function(v) Config.KillAura = v end,
    })
    PLTab:Slider({
        Title = "Kill Aura Range",
        Value = { Min = 5, Max = 60, Default = Config.KillAuraRange },
        Step = 1, Callback = function(v) Config.KillAuraRange = v queueSave() end,
    })
    PLTab:Toggle({
        Title = "Team Check", Desc = "Don't hit your own team.",
        Value = Config.KillAuraTeam,
        Callback = function(v) Config.KillAuraTeam = v queueSave() end,
    })
    do
        local lastMelee = 0
        track(RunService.Heartbeat:Connect(function()
            if not Config.KillAura then return end
            if tick() - lastMelee < 0.1 then return end
            local melee = ReplicatedStorage:FindFirstChild("meleeEvent")
            local hrp = myRoot()
            if not melee or not hrp then return end
            local myTeam = lp.Team
            local fired = false
            for _, p in ipairs(Players:GetPlayers()) do
                local same = Config.KillAuraTeam and myTeam ~= nil and p.Team == myTeam
                if p ~= lp and p.Character and not same then
                    local ehrp = p.Character:FindFirstChild("HumanoidRootPart")
                    local hum = p.Character:FindFirstChildOfClass("Humanoid")
                    if ehrp and hum and hum.Health > 0
                        and (ehrp.Position - hrp.Position).Magnitude <= Config.KillAuraRange then
                        pcall(function() melee:FireServer(p) end)
                        fired = true
                    end
                end
            end
            if fired then lastMelee = tick() end
        end))
    end

    PLTab:Section({ Title = "Teleport remotes (dumped)" })
    local function teleportToMouse()
        local req = getRemote("RequestHere")
        if not req then
            WindUI:Notify({ Title = "Click TP", Content = "RequestHere not found", Duration = 3, Icon = "alert-triangle" })
            return
        end
        pcall(function() req:FireServer(lp:GetMouse().Hit.Position) end)
    end
    PLTab:Button({ Title = "Teleport to Mouse", Callback = teleportToMouse })
    PLTab:Toggle({
        Title = "Click Teleport", Desc = "Right-click / tap to teleport there.",
        Value = false,
        Callback = function(v) Config.ClickTP = v end,
    })
    track(UserInputService.InputBegan:Connect(function(input, gpe)
        if gpe or not Config.ClickTP then return end
        if input.UserInputType == Enum.UserInputType.MouseButton2
            or input.UserInputType == Enum.UserInputType.Touch then
            teleportToMouse()
        end
    end))
    PLTab:Button({ Title = "TP to Nearest Giver", Callback = function()
        local hrp = myRoot()
        if not hrp then return end
        local roots = {}
        local pi = workspace:FindFirstChild("Prison_ITEMS")
        if pi and pi:FindFirstChild("giver") then table.insert(roots, pi.giver) end
        local topGiver = workspace:FindFirstChild("giver")
        if topGiver then table.insert(roots, topGiver) end
        local best, bestD
        for _, root in ipairs(roots) do
            for _, g in ipairs(root:GetChildren()) do
                local part = g:IsA("BasePart") and g or g:FindFirstChildWhichIsA("BasePart", true)
                if part then
                    local d = (part.Position - hrp.Position).Magnitude
                    if not bestD or d < bestD then best, bestD = part.Position, d end
                end
            end
        end
        if best then hrp.CFrame = CFrame.new(best + Vector3.new(0, 3, 0))
        else WindUI:Notify({ Title = "TP Giver", Content = "No giver found", Duration = 3, Icon = "alert-triangle" }) end
    end })

    PLTab:Section({ Title = "Utility" })
    PLTab:Toggle({
        Title = "No Player Collision", Desc = "Phase through players (RequestCollisionChange).",
        Value = false,
        Callback = function(v)
            local req = getRemote("RequestCollisionChange")
            if not req then
                WindUI:Notify({ Title = "Collision", Content = "RequestCollisionChange not found", Duration = 3, Icon = "alert-triangle" })
                return
            end
            pcall(function()
                if req:IsA("RemoteFunction") then req:InvokeServer(not v) else req:FireServer(not v) end
            end)
        end,
    })
end

-- ═══════════════════════════════════════════════════════════════════════
--  MURDER MYSTERY 2  —  real remotes verified in the dump
-- ═══════════════════════════════════════════════════════════════════════
if GameKey == "MM2" then
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
    local function findKnifeAll()
        for _, container in ipairs({ lp.Character, lp:FindFirstChildOfClass("Backpack") }) do
            if container then
                for _, t in ipairs(container:GetChildren()) do
                    if t:IsA("Tool") then
                        local ks = t:FindFirstChild("KnifeServer")
                        if ks and ks:FindFirstChild("SlashStart") then
                            return {
                                tool = t, handle = t:FindFirstChild("Handle"),
                                slash = ks:FindFirstChild("SlashStart"),
                                fling = ks:FindFirstChild("FlingKnife"),
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

    -- ── Classic MM2 (142823291) remotes, recovered from the dump ──────────
    -- ReplicatedStorage.Remotes.Gameplay.{GunFired, KnifeThrown,
    -- GetLatestPlayerData}; coins are parts tagged "CoinVisual".
    local CollectionService = game:GetService("CollectionService")
    local function gameplayFolder()
        local r = ReplicatedStorage:FindFirstChild("Remotes")
        return r and r:FindFirstChild("Gameplay")
    end
    local function classicRemote(name)
        local g = gameplayFolder()
        local rem = g and g:FindFirstChild(name)
        if rem then return rem end
        -- fallback: search anywhere for a remote by that name
        for _, d in ipairs(ReplicatedStorage:GetDescendants()) do
            if d.Name == name and (d:IsA("RemoteEvent") or d:IsA("RemoteFunction")) then return d end
        end
    end

    -- Unified combat: fire the gun / throw the knife at a world position,
    -- whichever remote scheme this MM2 uses.
    local function fireGunAt(pos)
        if MM2Variant == "classic" then
            local rem = classicRemote("GunFired")
            if rem then pcall(function() rem:FireServer(pos) end) return true end
            return false
        else
            local _, shoot, equipped = findGun()
            if shoot and equipped then pcall(function() shoot:FireServer(pos) end) return true end
            return false
        end
    end
    local function throwKnifeAt(pos)
        if MM2Variant == "classic" then
            local rem = classicRemote("KnifeThrown")
            if rem then pcall(function() rem:FireServer(pos) end) return true end
            return false
        else
            local k = findKnifeAll()
            if k and k.equipped and k.fling then pcall(function() k.fling:FireServer(pos) end) return true end
            return false
        end
    end

    -- Murderer detection.
    -- classic MM2's GetLatestPlayerData RemoteFunction returns the *caller's*
    -- data (you can't ask it for another player's role), so for others we
    -- detect the murderer by the client-visible knife: a tool tagged
    -- "Weapon_Knife" (or named *knife*) in their character/backpack.
    local function hasKnifeTagged(p)
        for _, container in ipairs({ p.Character, p:FindFirstChildOfClass("Backpack") }) do
            if container then
                for _, t in ipairs(container:GetChildren()) do
                    if t:IsA("Tool") and (CollectionService:HasTag(t, "Weapon_Knife")
                        or t.Name:lower():find("knife")) then
                        return true
                    end
                end
            end
        end
        return false
    end
    -- variant-aware murderer test (classic: knife tag; modern: KnifeServer tool)
    local function isMurdererV(p)
        if MM2Variant == "classic" then return hasKnifeTagged(p) end
        return isMurderer(p)
    end

    -- round state
    local lastStatus
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
            track(ev.OnClientEvent:Connect(function(s)
                if type(s) == "string" then lastStatus = s end
            end))
        end
    end)

    -- ── GUN ──────────────────────────────────────────────────────────────
    local GunTab = Window:Tab({ Title = "Gun", Icon = "crosshair" })
    GunTab:Section({ Title = "Auto Shoot Aura" })

    local fireHeld = false
    local lastFire = 0
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
                        local score = d - (Config.PreferMurderer and isMurdererV(p) and 100000 or 0)
                        if not bestD or score < bestD then best, bestD = p, score end
                    end
                end
            end
        end
        return best
    end

    GunTab:Toggle({ Title = "Auto Shoot Aura", Desc = "Shoot any player near you with 100% accuracy.",
        Value = Config.AutoShoot, Callback = function(v) Config.AutoShoot = v queueSave() end })
    GunTab:Toggle({ Title = "Hold To Fire", Desc = "Only fire while holding right-mouse.",
        Value = Config.ShootHold, Callback = function(v) Config.ShootHold = v queueSave() end })
    GunTab:Slider({ Title = "Aura Range (studs)",
        Value = { Min = 10, Max = 300, Default = Config.AuraRange }, Step = 5,
        Callback = function(v) Config.AuraRange = v queueSave() end })
    GunTab:Slider({ Title = "Fire Interval (ms)",
        Value = { Min = 30, Max = 500, Default = math.floor(Config.FireInterval * 1000) }, Step = 10,
        Callback = function(v) Config.FireInterval = v / 1000 queueSave() end })
    GunTab:Dropdown({ Title = "Target Part",
        Values = { "Head", "UpperTorso", "Torso", "HumanoidRootPart" }, Value = Config.ShootPart,
        Callback = function(v) Config.ShootPart = v queueSave() end })
    GunTab:Toggle({ Title = "Prefer Murderer", Desc = "Prioritise the knife holder.",
        Value = Config.PreferMurderer, Callback = function(v) Config.PreferMurderer = v queueSave() end })
    GunTab:Toggle({ Title = "Only During Round", Desc = "Pause the aura between rounds.",
        Value = Config.GunMatchGated, Callback = function(v) Config.GunMatchGated = v queueSave() end })
    GunTab:Toggle({ Title = "Auto Equip Gun", Desc = "Keep the gun out after respawn.",
        Value = Config.AutoEquipGun, Callback = function(v) Config.AutoEquipGun = v queueSave() end })

    track(UserInputService.InputBegan:Connect(function(i, g)
        if not g and i.UserInputType == Enum.UserInputType.MouseButton2 then fireHeld = true end
    end))
    track(UserInputService.InputEnded:Connect(function(i)
        if i.UserInputType == Enum.UserInputType.MouseButton2 then fireHeld = false end
    end))

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
            -- modern needs the gun tool equipped; classic fires the shared remote
            if MM2Variant == "modern" then
                local _, shoot, equipped = findGun()
                if not (shoot and equipped) then return end
            end
            local target = auraTarget()
            if not target then return end
            local part = partOf(target.Character, Config.ShootPart)
            if not part then return end
            if os.clock() - lastFire >= Config.FireInterval then
                lastFire = os.clock()
                fireGunAt(part.Position)
            end
        end)
    end))

    -- Silent aim
    GunTab:Section({ Title = "Silent Aim" })
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
                            local score = d - (Config.PreferMurderer and isMurdererV(p) and 100000 or 0)
                            if not bestScore or score < bestScore then best, bestScore = p, score end
                        end
                    end
                end
            end
        end
        return best
    end
    GunTab:Toggle({ Title = "Silent Aim", Desc = "Bend YOUR own shots to the target near your cursor.",
        Value = Config.SilentAim, Callback = function(v) Config.SilentAim = v queueSave() end })
    GunTab:Slider({ Title = "Silent Aim FOV (px)",
        Value = { Min = 30, Max = 1000, Default = Config.SilentFOV }, Step = 10,
        Callback = function(v) Config.SilentFOV = v queueSave() end })
    GunTab:Toggle({ Title = "Silent Knife Throws", Desc = "Also bend FlingKnife throws.",
        Value = Config.SilentKnife, Callback = function(v) Config.SilentKnife = v queueSave() end })

    do
        local hasHook = (hookmetamethod ~= nil) and (getnamecallmethod ~= nil) and (newcclosure ~= nil)
        if not hasHook then
            WindUI:Notify({ Title = "Silent Aim", Icon = "alert-triangle", Duration = 7,
                Content = "Executor lacks hookmetamethod — Silent Aim unavailable (aura still works)." })
        else
            local old
            old = hookmetamethod(game, "__namecall", newcclosure(function(self, ...)
                local args = { ... }
                local method = getnamecallmethod()
                if not checkcaller() and method == "FireServer" and Config.SilentAim then
                    if MM2Variant == "classic" then
                        -- classic: bend Remotes.Gameplay.GunFired / KnifeThrown
                        local gunRem = classicRemote("GunFired")
                        if gunRem and self == gunRem and typeof(args[1]) == "Vector3" then
                            local target = nearestToMouse(Config.SilentFOV)
                            local part = target and partOf(target.Character, Config.ShootPart)
                            if part then args[1] = part.Position return old(self, unpack(args)) end
                        end
                        if Config.SilentKnife then
                            local knifeRem = classicRemote("KnifeThrown")
                            if knifeRem and self == knifeRem and typeof(args[1]) == "Vector3" then
                                local target = nearestToMouse(Config.SilentFOV)
                                local part = target and partOf(target.Character, "Head")
                                if part then args[1] = part.Position return old(self, unpack(args)) end
                            end
                        end
                    else
                        local gunTool, shoot = findGun()
                        if shoot and self == shoot and typeof(args[1]) == "Vector3" then
                            local target = nearestToMouse(Config.SilentFOV)
                            local part = target and partOf(target.Character, Config.ShootPart)
                            if part then args[1] = part.Position return old(self, unpack(args)) end
                        end
                        if Config.SilentKnife then
                            local k = findKnifeAll()
                            if k and k.fling and self == k.fling then
                                local target = nearestToMouse(Config.SilentFOV)
                                local part = target and partOf(target.Character, "Head")
                                if part and typeof(args[1]) == "Vector3" then
                                    args[1] = part.Position return old(self, unpack(args))
                                end
                            end
                        end
                    end
                end
                return old(self, ...)
            end))
        end
    end

    -- ── KNIFE ────────────────────────────────────────────────────────────
    local KnifeTab = Window:Tab({ Title = "Knife", Icon = "swords" })
    KnifeTab:Section({ Title = "Auto Farm" })
    KnifeTab:Toggle({ Title = "Knife Auto Farm", Desc = "TP behind the nearest player and slash.",
        Value = Config.KnifeFarm, Callback = function(v) Config.KnifeFarm = v queueSave() end })
    KnifeTab:Slider({ Title = "Farm Range (studs)",
        Value = { Min = 20, Max = 500, Default = Config.KnifeRange }, Step = 10,
        Callback = function(v) Config.KnifeRange = v queueSave() end })
    KnifeTab:Toggle({ Title = "Auto Equip Knife", Desc = "Keep the knife out after respawn.",
        Value = Config.AutoEquipKnife, Callback = function(v) Config.AutoEquipKnife = v queueSave() end })

    -- classic: knife tool is tagged Weapon_Knife (no KnifeServer child)
    local function findClassicKnifeTool()
        for _, container in ipairs({ lp.Character, lp:FindFirstChildOfClass("Backpack") }) do
            if container then
                for _, t in ipairs(container:GetChildren()) do
                    if t:IsA("Tool") and (CollectionService:HasTag(t, "Weapon_Knife")
                        or t.Name:lower():find("knife")) then
                        return t, t.Parent == lp.Character
                    end
                end
            end
        end
    end

    local lastSlash, lastKnifeEquip = 0, 0
    track(RunService.Heartbeat:Connect(function()
        pcall(function()
            if Config.AutoEquipKnife and os.clock() - lastKnifeEquip >= 0.25 then
                lastKnifeEquip = os.clock()
                if MM2Variant == "classic" then
                    local tool = select(1, findClassicKnifeTool())
                    if tool then equip(tool) end
                else
                    local k = findKnifeAll()
                    if k then equip(k.tool) end
                end
            end
            if not Config.KnifeFarm then return end
            local root = myRoot()
            local target = nearestPlayer(Config.KnifeRange)
            local ehrp = target and target.Character and target.Character:FindFirstChild("HumanoidRootPart")
            if not (root and ehrp and not shielded(target.Character)) then return end
            if os.clock() - lastSlash < Config.KnifeInterval then return end
            if MM2Variant == "classic" then
                -- classic: TP close and throw the knife at them (KnifeThrown)
                local _, equipped = findClassicKnifeTool()
                if not equipped then return end
                lastSlash = os.clock()
                root.CFrame = ehrp.CFrame * CFrame.new(0, 0, 2.5)
                throwKnifeAt(ehrp.Position)
            else
                local k = findKnifeAll()
                if not (k and k.equipped and k.slash) then return end
                lastSlash = os.clock()
                root.CFrame = ehrp.CFrame * CFrame.new(0, 0, 2.5)
                k.slash:FireServer()
            end
        end)
    end))

    KnifeTab:Section({ Title = "Ranged Throw" })
    KnifeTab:Toggle({ Title = "Auto Throw (FlingKnife)", Desc = "Throw the knife at the nearest player.",
        Value = Config.KnifeThrow, Callback = function(v) Config.KnifeThrow = v queueSave() end })
    KnifeTab:Slider({ Title = "Throw Range (studs)",
        Value = { Min = 20, Max = 400, Default = Config.ThrowRange }, Step = 10,
        Callback = function(v) Config.ThrowRange = v queueSave() end })

    local lastThrow = 0
    track(RunService.Heartbeat:Connect(function()
        pcall(function()
            if not Config.KnifeThrow then return end
            if MM2Variant == "modern" then
                local k = findKnifeAll()
                if not (k and k.equipped and k.fling) then return end
            end
            local target = nearestPlayer(Config.ThrowRange)
            local part = target and partOf(target.Character, "Head")
            if part and not shielded(target.Character) then
                if os.clock() - lastThrow >= Config.ThrowInterval then
                    lastThrow = os.clock()
                    throwKnifeAt(part.Position)
                end
            end
        end)
    end))

    -- ── AUTO FARM (role-aware: kills as murderer OR sheriff) ──────────────
    -- One toggle that reads which weapon you hold and farms accordingly:
    --   knife  -> teleport to the nearest player and slash / throw
    --   gun    -> shoot the nearest player (murderer prioritised)
    -- Falls back to grabbing the nearest coin when there is no target.
    local AutoFarmTab = Window:Tab({ Title = "Auto Farm", Icon = "swords" })
    AutoFarmTab:Section({ Title = "Play the round for me" })
    AutoFarmTab:Toggle({ Title = "Auto Farm", Desc = "Auto-kill with whatever weapon you're holding.",
        Value = Config.AutoFarm, Callback = function(v) Config.AutoFarm = v queueSave() end })
    AutoFarmTab:Slider({ Title = "Farm Range (studs)",
        Value = { Min = 20, Max = 500, Default = Config.FarmRange }, Step = 10,
        Callback = function(v) Config.FarmRange = v queueSave() end })
    AutoFarmTab:Slider({ Title = "Farm Interval (ms)",
        Value = { Min = 50, Max = 1000, Default = math.floor(Config.FarmInterval * 1000) }, Step = 25,
        Callback = function(v) Config.FarmInterval = v / 1000 queueSave() end })
    AutoFarmTab:Toggle({ Title = "Auto Equip Weapon", Desc = "Keep your weapon out (re-equips after respawn).",
        Value = Config.FarmAutoEquip, Callback = function(v) Config.FarmAutoEquip = v queueSave() end })
    AutoFarmTab:Toggle({ Title = "Only During Round", Desc = "Pause between rounds.",
        Value = Config.FarmMatchGated, Callback = function(v) Config.FarmMatchGated = v queueSave() end })
    AutoFarmTab:Toggle({ Title = "Grab Coins When Idle", Desc = "Collect the nearest coin when there's no target.",
        Value = Config.FarmCoins, Callback = function(v) Config.FarmCoins = v queueSave() end })

    -- client-visible weapon in my own hands/backpack (both variants)
    local function myGunTool()
        if MM2Variant == "modern" then return (findGun()) end
        for _, container in ipairs({ lp.Character, lp:FindFirstChildOfClass("Backpack") }) do
            if container then
                for _, t in ipairs(container:GetChildren()) do
                    if t:IsA("Tool") and (CollectionService:HasTag(t, "Weapon_Gun")
                        or t.Name:lower():find("gun")) then return t end
                end
            end
        end
    end
    local function myKnifeTool()
        if MM2Variant == "modern" then local k = findKnifeAll() return k and k.tool end
        return (findClassicKnifeTool())
    end

    local lastFarm = 0
    track(RunService.Heartbeat:Connect(function()
        pcall(function()
            if not Config.AutoFarm then return end
            if Config.FarmMatchGated and not matchActive() then return end
            local root = myRoot()
            if not root then return end

            local knife = myKnifeTool()
            local gun   = myGunTool()

            if Config.FarmAutoEquip then
                if knife then equip(knife) elseif gun then equip(gun) end
            end
            if os.clock() - lastFarm < Config.FarmInterval then return end

            -- choose a target: as a shooter, prefer the murderer
            local target
            if gun and not knife then
                local best, bestScore
                for _, p in ipairs(Players:GetPlayers()) do
                    if p ~= lp and p.Character and alive(p.Character) and not shielded(p.Character) then
                        local part = partOf(p.Character, Config.ShootPart)
                        if part then
                            local d = (part.Position - root.Position).Magnitude
                            if d <= Config.FarmRange then
                                local score = d - (isMurdererV(p) and 100000 or 0)
                                if not bestScore or score < bestScore then best, bestScore = p, score end
                            end
                        end
                    end
                end
                target = best
            else
                target = nearestPlayer(Config.FarmRange)
            end

            -- no one to kill: grab the nearest coin instead
            if not target then
                if Config.FarmCoins then
                    local best, bestD
                    for _, c in ipairs(CollectionService:GetTagged("CoinVisual")) do
                        if c:IsA("BasePart") and c.Parent then
                            local d = (c.Position - root.Position).Magnitude
                            if not bestD or d < bestD then best, bestD = c, d end
                        end
                    end
                    if best then
                        lastFarm = os.clock()
                        pcall(function() root.CFrame = CFrame.new(best.Position) end)
                    end
                end
                return
            end

            local ehrp = target.Character:FindFirstChild("HumanoidRootPart")
            if not ehrp or shielded(target.Character) then return end
            lastFarm = os.clock()

            if knife then
                pcall(function() root.CFrame = ehrp.CFrame * CFrame.new(0, 0, 2.5) end)
                if MM2Variant == "modern" then
                    local k = findKnifeAll()
                    if k and k.equipped and k.slash then pcall(function() k.slash:FireServer() end)
                    else throwKnifeAt(ehrp.Position) end
                else
                    throwKnifeAt(ehrp.Position)
                end
            elseif gun then
                local part = partOf(target.Character, Config.ShootPart)
                if part then fireGunAt(part.Position) end
            end
        end)
    end))

    -- ── COINS (classic tag: CoinVisual) + ROLE ESP ────────────────────────
    local CoinTab = Window:Tab({ Title = "Coins", Icon = "coins" })
    CoinTab:Section({ Title = "Auto Collect" })
    CoinTab:Toggle({ Title = "Auto Collect Coins", Desc = "Teleport onto every coin (CoinVisual tag).",
        Value = Config.AutoCoins, Callback = function(v) Config.AutoCoins = v queueSave() end })
    CoinTab:Slider({ Title = "Collect Interval (ms)",
        Value = { Min = 50, Max = 1000, Default = math.floor(Config.CoinInterval * 1000) }, Step = 25,
        Callback = function(v) Config.CoinInterval = v / 1000 queueSave() end })
    CoinTab:Toggle({ Title = "Return After Collecting", Desc = "Snap back to your start position each pass.",
        Value = Config.CoinReturn, Callback = function(v) Config.CoinReturn = v queueSave() end })

    local lastCoin = 0
    local collectingCoins = false
    track(RunService.Heartbeat:Connect(function()
        if collectingCoins then return end          -- a pass is still running
        if not Config.AutoCoins then return end
        if os.clock() - lastCoin < Config.CoinInterval then return end
        local root = myRoot()
        if not root then return end
        local coins = CollectionService:GetTagged("CoinVisual")
        if #coins == 0 then return end
        collectingCoins = true
        task.spawn(function()
            pcall(function()
                local home = root.CFrame
                for _, coin in ipairs(coins) do
                    if not Config.AutoCoins then break end
                    if coin:IsA("BasePart") and coin.Parent then
                        local r = myRoot()
                        if r then pcall(function() r.CFrame = CFrame.new(coin.Position) end) end
                        task.wait()
                    end
                end
                if Config.CoinReturn then
                    local r = myRoot()
                    if r then pcall(function() r.CFrame = home end) end
                end
            end)
            lastCoin = os.clock()
            collectingCoins = false
        end)
    end))

    CoinTab:Section({ Title = "Round" })
    CoinTab:Paragraph({ Title = "Variant",
        Desc = MM2Variant == "classic"
            and "Classic MM2 (142823291): GunFired / KnifeThrown / CoinVisual."
            or  "Modern MM2: GunServer.ShootStart / KnifeServer.SlashStart." })
    CoinTab:Button({ Title = "Print My Role", Desc = "Check the role the server assigned you.",
        Callback = function()
            local role = "unknown"
            if MM2Variant == "classic" then
                local rf = classicRemote("GetLatestPlayerData")
                if rf and rf:IsA("RemoteFunction") then
                    pcall(function()
                        local d = rf:InvokeServer(lp)
                        if type(d) == "table" and d.Role then role = d.Role end
                    end)
                end
            end
            WindUI:Notify({ Title = "Your Role", Content = role, Duration = 4 })
        end })
end

-- ═══════════════════════════════════════════════════════════════════════
--  PLUS 1 FORGE  (118805555015549) — forge / train / rebirth simulator
--  Remotes live under ReplicatedStorage.Remote, resolved by name.
--  See Plus1Forge_Deobfuscated.md for the full map.
-- ═══════════════════════════════════════════════════════════════════════
if GameKey == "Plus1Forge" then
    -- resolve a remote by name anywhere under ReplicatedStorage.Remote
    -- (then anywhere in ReplicatedStorage), regardless of subfolder layout.
    local function pfRemote(name)
        local root = ReplicatedStorage:FindFirstChild("Remote") or ReplicatedStorage
        local r = root:FindFirstChild(name, true)
        if r and (r:IsA("RemoteEvent") or r:IsA("RemoteFunction")) then return r end
        for _, d in ipairs(ReplicatedStorage:GetDescendants()) do
            if d.Name == name and (d:IsA("RemoteEvent") or d:IsA("RemoteFunction")) then return d end
        end
    end
    -- fire / invoke a remote by name; returns ok, result
    local function pfFire(name, ...)
        local r = pfRemote(name)
        if not r then return false, "not found: " .. name end
        if r:IsA("RemoteFunction") then
            local ok, res = pcall(function(...) return r:InvokeServer(...) end, ...)
            return ok, res
        else
            local args = { ... }
            pcall(function() r:FireServer(table.unpack(args)) end)
            return true
        end
    end

    -- ── TRAIN ──────────────────────────────────────────────────────────────
    local TrainTab = Window:Tab({ Title = "Forge: Train", Icon = "dumbbell" })
    TrainTab:Section({ Title = "Auto Train" })
    TrainTab:Toggle({ Title = "Auto Train", Desc = "Spam TrainOnceRF to train non-stop.",
        Value = Config.PFAutoTrain, Callback = function(v) Config.PFAutoTrain = v queueSave() end })
    TrainTab:Slider({ Title = "Train Interval (ms)",
        Value = { Min = 30, Max = 1000, Default = math.floor(Config.PFTrainInterval * 1000) }, Step = 10,
        Callback = function(v) Config.PFTrainInterval = v / 1000 queueSave() end })
    TrainTab:Button({ Title = "Enter Auto-Train Area", Desc = "Fire IntoAutoTrainRE.",
        Callback = function() pfFire("IntoAutoTrainRE") WindUI:Notify({ Title = "Train", Content = "IntoAutoTrainRE", Duration = 3 }) end })
    TrainTab:Button({ Title = "Exit Auto-Train Area",
        Callback = function() pfFire("ExitAutoTrainRE") end })

    local lastTrain = 0
    track(RunService.Heartbeat:Connect(function()
        if not Config.PFAutoTrain then return end
        if os.clock() - lastTrain < Config.PFTrainInterval then return end
        lastTrain = os.clock()
        pcall(function() pfFire("TrainOnceRF") end)
    end))

    -- ── AUTO FARM ────────────────────────────────────────────────────────
    local FarmTab = Window:Tab({ Title = "Forge: Farm", Icon = "repeat" })
    FarmTab:Section({ Title = "Auto loops (no-arg remotes)" })
    FarmTab:Toggle({ Title = "Auto Rebirth", Desc = "Fire RebirthRE / TryRebirthRE.",
        Value = Config.PFAutoRebirth, Callback = function(v) Config.PFAutoRebirth = v queueSave() end })
    FarmTab:Toggle({ Title = "Auto Luck Roll", Desc = "Fire LuckOnceRE.",
        Value = Config.PFAutoLuck, Callback = function(v) Config.PFAutoLuck = v queueSave() end })
    FarmTab:Toggle({ Title = "Auto Upgrade", Desc = "Fire UpgradeOnceRE.",
        Value = Config.PFAutoUpgrade, Callback = function(v) Config.PFAutoUpgrade = v queueSave() end })
    FarmTab:Toggle({ Title = "Auto Sell All", Desc = "Fire TrySellAllRE.",
        Value = Config.PFAutoSell, Callback = function(v) Config.PFAutoSell = v queueSave() end })
    FarmTab:Slider({ Title = "Loop Interval (ms)",
        Value = { Min = 200, Max = 5000, Default = math.floor(Config.PFLoopInterval * 1000) }, Step = 100,
        Callback = function(v) Config.PFLoopInterval = v / 1000 queueSave() end })

    FarmTab:Section({ Title = "Claim everything" })
    FarmTab:Button({ Title = "Claim All Rewards", Desc = "Fire every claim remote once.",
        Callback = function()
            for _, n in ipairs({ "TryClaimRE", "TryClaimOfflineRewardRE", "TryClaimLevelRewardRF",
                "TryClaimIndexExpRF", "TryClaimUPDRewardRE", "TryClaimDailyDunTicRE", "ClaimedAllOreRE" }) do
                pfFire(n)
            end
            WindUI:Notify({ Title = "Claim", Content = "Fired all claim remotes", Duration = 3 })
        end })

    FarmTab:Section({ Title = "Codes" })
    local codeInput = ""
    FarmTab:Input({ Title = "Code", Placeholder = "enter a code",
        Callback = function(v) codeInput = v end })
    FarmTab:Button({ Title = "Redeem Code", Desc = "InvokeServer TryUseCodeRF.",
        Callback = function()
            if codeInput == "" then return end
            local ok = pfFire("TryUseCodeRF", codeInput)
            WindUI:Notify({ Title = "Code", Content = ok and ("sent: " .. codeInput) or "failed", Duration = 4 })
        end })

    local lastLoop = 0
    track(RunService.Heartbeat:Connect(function()
        if os.clock() - lastLoop < Config.PFLoopInterval then return end
        lastLoop = os.clock()
        pcall(function()
            if Config.PFAutoRebirth then pfFire("RebirthRE") pfFire("TryRebirthRE") end
            if Config.PFAutoLuck    then pfFire("LuckOnceRE") end
            if Config.PFAutoUpgrade then pfFire("UpgradeOnceRE") end
            if Config.PFAutoSell    then pfFire("TrySellAllRE") end
        end)
    end))

    -- ── FORGE / EQUIP / ABILITIES (modify your sword permanently) ─────────
    local GearTab = Window:Tab({ Title = "Forge: Gear", Icon = "sword" })
    GearTab:Section({ Title = "Weapon (persists server-side)" })
    GearTab:Button({ Title = "Equip Best Weapon", Desc = "GetMyBestRF -> ChangeEquipedIndexRE.",
        Callback = function()
            local ok, best = pfFire("GetMyBestRF")
            -- best shape unknown; try common fields, else just poke ChangeEquipedIndexRE
            local idx = (type(best) == "table" and (best.Index or best.index or best[1])) or best
            pfFire("ChangeEquipedIndexRE", idx)
            WindUI:Notify({ Title = "Equip", Content = "Tried equip best (" .. tostring(idx) .. ")", Duration = 4 })
        end })
    local slotIdx = 1
    GearTab:Slider({ Title = "Equip Slot Index",
        Value = { Min = 1, Max = 50, Default = 1 }, Step = 1,
        Callback = function(v) slotIdx = v end })
    GearTab:Button({ Title = "Change Equipped Weapon", Desc = "ChangeEquipedIndexRE(slot).",
        Callback = function()
            pfFire("ChangeEquipedIndexRE", slotIdx)
            WindUI:Notify({ Title = "Equip", Content = "Slot " .. slotIdx, Duration = 3 })
        end })

    GearTab:Section({ Title = "Forge & enchant" })
    GearTab:Toggle({ Title = "Auto Forge", Desc = "Spam ForgeRF (best-effort args).",
        Value = Config.PFAutoForge, Callback = function(v) Config.PFAutoForge = v queueSave() end })
    GearTab:Button({ Title = "Forge Once", Callback = function() pfFire("ForgeRF") end })
    GearTab:Button({ Title = "Enchant Equipped", Desc = "EnchantRE (best-effort).",
        Callback = function() pfFire("EnchantRE") end })

    local lastForge = 0
    track(RunService.Heartbeat:Connect(function()
        if not Config.PFAutoForge then return end
        if os.clock() - lastForge < 0.5 then return end
        lastForge = os.clock()
        pcall(function() pfFire("ForgeRF") end)
    end))

    -- ── DEV REMOTES (self-affecting; server-gated by IsDevRF) ─────────────
    -- These are the dump's admin remotes. On a live server they're checked
    -- against IsDevRF, so for a normal account they'll simply do nothing.
    -- Only the ones that affect YOUR OWN save are exposed here — never
    -- KickPlayerRE (targets other players) or DestroyDataRE (wipes data).
    local DevTab = Window:Tab({ Title = "Forge: Dev", Icon = "flask-conical" })
    DevTab:Section({ Title = "Access check" })
    DevTab:Button({ Title = "Am I a Dev?", Desc = "Invoke IsDevRF for your account — tells you if the Dev tab will do anything.",
        Callback = function()
            local ok, res = pfFire("IsDevRF")
            local isDev
            if type(res) == "boolean" then isDev = res
            elseif type(res) == "table" then isDev = res.IsDev or res.isDev or res[1] end
            local msg
            if not ok then msg = "IsDevRF not found / errored"
            elseif isDev == true then msg = "YES — you're a dev. The Dev tab will work."
            elseif isDev == false or isDev == nil then msg = "No — normal account. Dev remotes will no-op."
            else msg = "IsDevRF returned: " .. tostring(res) end
            print("[Nexus] IsDevRF ->", res)
            WindUI:Notify({ Title = "Am I a Dev?", Content = msg, Duration = 6,
                Icon = (isDev == true) and "check" or "info" })
        end })

    DevTab:Section({ Title = "Currency  (AddAnyEcoRE)" })
    local ecoType, ecoAmt = "Coin", 1000000
    DevTab:Dropdown({ Title = "Currency", Values = { "Coin", "Diamond", "Gold", "Power", "Points", "Ore" },
        Value = "Coin", Callback = function(v) ecoType = v end })
    DevTab:Input({ Title = "Amount", Placeholder = "1000000",
        Callback = function(v) ecoAmt = tonumber(v) or ecoAmt end })
    DevTab:Button({ Title = "Add Currency", Desc = "AddAnyEcoRE(type, amount) - best-effort.",
        Callback = function()
            -- try (type, amount); fall back to (amount, type)
            pfFire("AddAnyEcoRE", ecoType, ecoAmt)
            pfFire("AddAnyEcoRE", ecoAmt, ecoType)
            WindUI:Notify({ Title = "Dev", Content = ("Tried +%s %s"):format(tostring(ecoAmt), ecoType), Duration = 4 })
        end })
    DevTab:Button({ Title = "Add Funnel", Desc = "AddAnyFunnelRE / AddFunnelWithPemRE(type, amount).",
        Callback = function()
            pfFire("AddAnyFunnelRE", ecoType, ecoAmt)
            pfFire("AddFunnelWithPemRE", ecoType, ecoAmt)
        end })

    DevTab:Section({ Title = "Stats  (SetStatsRE / AddStatsRE)" })
    local statName, statVal = "Power", 1000000
    DevTab:Dropdown({ Title = "Stat", Values = { "Power", "STR", "Attack", "Damage", "Luck", "Speed", "Stamina", "End" },
        Value = "Power", Callback = function(v) statName = v end })
    DevTab:Input({ Title = "Value", Placeholder = "1000000",
        Callback = function(v) statVal = tonumber(v) or statVal end })
    DevTab:Button({ Title = "Set Stat", Desc = "SetStatsRE(stat, value) - best-effort.",
        Callback = function()
            pfFire("SetStatsRE", statName, statVal)
            pfFire("SetStatsRE", statVal, statName)
            WindUI:Notify({ Title = "Dev", Content = ("Set %s = %s"):format(statName, tostring(statVal)), Duration = 4 })
        end })
    DevTab:Button({ Title = "Add Stat", Desc = "AddStatsRE(stat, value) - best-effort.",
        Callback = function()
            pfFire("AddStatsRE", statName, statVal)
            pfFire("AddStatsRE", statVal, statName)
        end })

    DevTab:Section({ Title = "Danger" })
    DevTab:Button({ Title = "Reset Economy (self)", Desc = "ResetEcoRE - resets YOUR economy. Use with care.",
        Callback = function()
            pfFire("ResetEcoRE")
            WindUI:Notify({ Title = "Dev", Content = "ResetEcoRE fired", Duration = 4, Icon = "alert-triangle" })
        end })
    DevTab:Paragraph({ Title = "Heads up",
        Desc = "These are the game's own dev/admin remotes. A live server checks "
            .. "IsDevRF before honouring them, so on a normal account they do nothing "
            .. "(the calls fail silently). Argument order is a best-effort guess from "
            .. "the dump - if a button seems ignored, use Forge: Remotes to try other "
            .. "arg shapes. Only self-affecting remotes are here by design." })

    -- ── DIAGNOSTICS / REMOTE RUNNER ──────────────────────────────────────
    local DiagTab = Window:Tab({ Title = "Forge: Remotes", Icon = "terminal" })
    DiagTab:Section({ Title = "Remote runner (drive any remote)" })
    local rrName, rrArg = "", ""
    DiagTab:Input({ Title = "Remote Name", Placeholder = "e.g. TrainOnceRF",
        Callback = function(v) rrName = v end })
    DiagTab:Input({ Title = "Arg (optional)", Placeholder = "number or text",
        Callback = function(v) rrArg = v end })
    DiagTab:Button({ Title = "Fire / Invoke", Desc = "Send the named remote with the arg.",
        Callback = function()
            if rrName == "" then return end
            local arg = tonumber(rrArg)
            if arg == nil and rrArg ~= "" then arg = rrArg end
            local ok, res = pfFire(rrName, arg)
            WindUI:Notify({ Title = rrName, Content = ok and ("ok " .. tostring(res)) or tostring(res), Duration = 5 })
        end })
    DiagTab:Section({ Title = "Discovery" })
    DiagTab:Button({ Title = "Print Remote Tree", Desc = "List every remote under ReplicatedStorage.Remote (F9 console).",
        Callback = function()
            local root = ReplicatedStorage:FindFirstChild("Remote") or ReplicatedStorage
            local n = 0
            for _, d in ipairs(root:GetDescendants()) do
                if d:IsA("RemoteEvent") or d:IsA("RemoteFunction") then
                    n = n + 1
                    print(("[Nexus] %s  (%s)  %s"):format(d.Name, d.ClassName, d:GetFullName()))
                end
            end
            WindUI:Notify({ Title = "Remotes", Content = n .. " remotes printed to console (F9)", Duration = 5 })
        end })
    DiagTab:Paragraph({ Title = "Note",
        Desc = "Remote argument shapes couldn't be read from the bytecode dump. "
            .. "No-arg loops (train / rebirth / luck / sell / claim) are reliable; "
            .. "forge / equip / stats take best-effort args — use the runner + tree "
            .. "to confirm exact names and args in-game." })
end

-- ═══════════════════════════════════════════════════════════════════════
--  DONATION GAME  (76653273729321) — PLS-DONATE-style
--  Only the self-affecting in-game features: quests, coins, giftbux claims.
--  NOT wired: ClientGifting / StartTransferDonation (real-Robux donations),
--  FakeRobux / RobuxEvent effects (they move no balance and exist only to
--  make other real players think a donation happened).
-- ═══════════════════════════════════════════════════════════════════════
if GameKey == "DonateGame" then
    local function dgRemote(name)
        local root = ReplicatedStorage:FindFirstChild("Remotes") or ReplicatedStorage
        local r = root:FindFirstChild(name, true)
        if r and (r:IsA("RemoteEvent") or r:IsA("RemoteFunction")) then return r end
        for _, d in ipairs(ReplicatedStorage:GetDescendants()) do
            if d.Name == name and (d:IsA("RemoteEvent") or d:IsA("RemoteFunction")) then return d end
        end
    end
    local function dgFire(name, ...)
        local r = dgRemote(name)
        if not r then return false end
        if r:IsA("RemoteFunction") then
            local ok = pcall(function(...) return r:InvokeServer(...) end, ...)
            return ok
        else
            local a = { ... }
            pcall(function() r:FireServer(table.unpack(a)) end)
            return true
        end
    end
    -- fire a ProximityPrompt regardless of distance (executor helper)
    local function fireProx(p)
        if typeof(fireproximityprompt) == "function" then pcall(fireproximityprompt, p) end
    end
    -- every quest/coin ProximityPrompt in the world (quest coins carry prompts)
    local function coinPrompts()
        local out = {}
        for _, d in ipairs(workspace:GetDescendants()) do
            if d:IsA("ProximityPrompt") then
                local par = d.Parent
                local n = (par and par.Name or "") .. " " .. tostring(d.Name)
                if n:lower():find("coin") or n:lower():find("quest") then out[#out + 1] = d end
            end
        end
        return out
    end

    local QuestTab = Window:Tab({ Title = "Donate: Quests", Icon = "scroll" })
    QuestTab:Section({ Title = "Auto Quest" })
    QuestTab:Toggle({ Title = "Auto Quest", Desc = "Accept, collect quest coins, and claim on a loop.",
        Value = Config.DGAutoQuest, Callback = function(v) Config.DGAutoQuest = v queueSave() end })
    QuestTab:Slider({ Title = "Quest Interval (ms)",
        Value = { Min = 100, Max = 3000, Default = math.floor(Config.DGQuestInterval * 1000) }, Step = 50,
        Callback = function(v) Config.DGQuestInterval = v / 1000 queueSave() end })
    QuestTab:Button({ Title = "Accept Nearest Quest", Desc = "Fire the QuestGiver prompt / AcceptQuest.",
        Callback = function()
            dgFire("AcceptQuest")
            local qg = workspace:FindFirstChild("QuestGiver", true)
            if qg then
                for _, d in ipairs(qg:GetDescendants()) do
                    if d:IsA("ProximityPrompt") then fireProx(d) end
                end
            end
            WindUI:Notify({ Title = "Quest", Content = "Accept fired", Duration = 3 })
        end })
    QuestTab:Button({ Title = "Claim Quest", Callback = function() dgFire("ClaimQuest") end })

    QuestTab:Section({ Title = "Coins & rewards" })
    QuestTab:Toggle({ Title = "Auto Collect Coins", Desc = "Fire every quest-coin prompt (lets the game collect them).",
        Value = Config.DGAutoCoins, Callback = function(v) Config.DGAutoCoins = v queueSave() end })
    QuestTab:Button({ Title = "Claim All Rewards", Desc = "ClaimReward / ClaimBooth once.",
        Callback = function()
            dgFire("ClaimReward")
            dgFire("ClaimBooth")
            WindUI:Notify({ Title = "Rewards", Content = "Claim fired", Duration = 3 })
        end })

    local lastQuest, lastCoin = 0, 0
    track(RunService.Heartbeat:Connect(function()
        pcall(function()
            if (Config.DGAutoCoins or Config.DGAutoQuest) and os.clock() - lastCoin >= 0.2 then
                lastCoin = os.clock()
                for _, p in ipairs(coinPrompts()) do fireProx(p) end
            end
            if Config.DGAutoQuest and os.clock() - lastQuest >= Config.DGQuestInterval then
                lastQuest = os.clock()
                dgFire("AcceptQuest")
                local qg = workspace:FindFirstChild("QuestGiver", true)
                if qg then
                    for _, d in ipairs(qg:GetDescendants()) do
                        if d:IsA("ProximityPrompt") then fireProx(d) end
                    end
                end
                dgFire("ClaimQuest")
                dgFire("ClaimReward")
            end
        end)
    end))

    QuestTab:Section({ Title = "Advanced" })
    local dgRRName = ""
    QuestTab:Input({ Title = "Remote Name", Placeholder = "e.g. ClaimQuest",
        Callback = function(v) dgRRName = v end })
    QuestTab:Button({ Title = "Fire Remote", Desc = "Drive any remote under ReplicatedStorage.Remotes.",
        Callback = function()
            if dgRRName ~= "" then
                local ok = dgFire(dgRRName)
                WindUI:Notify({ Title = dgRRName, Content = ok and "fired" or "not found", Duration = 4 })
            end
        end })
    QuestTab:Paragraph({ Title = "What's not here (and why)",
        Desc = "This tab only automates YOUR quests/coins/reward claims — the server "
            .. "still validates every claim, so it can't be inflated. Real-Robux "
            .. "donations (ClientGifting) and the fake-robux effects are deliberately "
            .. "left out: you can't mint real Robux, and the fake ones only exist to "
            .. "mislead other players." })
end

-- ═══════════════════════════════════════════════════════════════════════
--  CLONE BUILDERS  (98456203230140) — CloneForge
--  Clone count (CloneCapacity) and build/work speed are SERVER stats bought
--  via gamepasses/upgrades or granted by the game's Admin remote (dev-gated).
--  Remotes live under ReplicatedStorage.CloneForge.Remotes.
-- ═══════════════════════════════════════════════════════════════════════
if GameKey == "CloneBuild" then
    local function cbRemotesFolder()
        local cf = ReplicatedStorage:FindFirstChild("CloneForge")
        return (cf and cf:FindFirstChild("Remotes")) or ReplicatedStorage
    end
    local function cbRemote(name)
        local root = cbRemotesFolder()
        local r = root:FindFirstChild(name, true)
        if r and (r:IsA("RemoteEvent") or r:IsA("RemoteFunction")) then return r end
        for _, d in ipairs(ReplicatedStorage:GetDescendants()) do
            if d.Name == name and (d:IsA("RemoteEvent") or d:IsA("RemoteFunction")) then return d end
        end
    end
    local function cbFire(name, ...)
        local r = cbRemote(name)
        if not r then return false, "not found: " .. name end
        if r:IsA("RemoteFunction") then
            local ok, res = pcall(function(...) return r:InvokeServer(...) end, ...)
            return ok, res
        else
            local a = { ... }
            pcall(function() r:FireServer(table.unpack(a)) end)
            return true
        end
    end

    -- ── Clones ─────────────────────────────────────────────────────────────
    local CloneTab = Window:Tab({ Title = "Clones", Icon = "users" })
    CloneTab:Section({ Title = "Work faster (no gate)" })
    CloneTab:Button({ Title = "Assign All Clones", Desc = "ReassignAll — put every clone you own on one build so it finishes faster.",
        Callback = function()
            local ok = cbFire("ReassignAll")
            WindUI:Notify({ Title = "Clones", Content = ok and "Assigned all clones" or "ReassignAll not found", Duration = 4 })
        end })
    CloneTab:Toggle({ Title = "Keep Clones Assigned", Desc = "Re-assign all clones every few seconds.",
        Value = Config.CBAutoAssign, Callback = function(v) Config.CBAutoAssign = v queueSave() end })
    do
        local lastAssign = 0
        track(RunService.Heartbeat:Connect(function()
            if not Config.CBAutoAssign then return end
            if os.clock() - lastAssign < 3 then return end
            lastAssign = os.clock()
            pcall(function() cbFire("ReassignAll") end)
        end))
    end

    CloneTab:Section({ Title = "Ad rewards (needs a watched ad; server-checked)" })
    CloneTab:Button({ Title = "Claim +Clone Reward", Callback = function() cbFire("Rewards", "Clone") cbFire("Rewards", { Kind = "Clone" }) end })
    CloneTab:Button({ Title = "Claim Build-Speed Reward", Callback = function() cbFire("Rewards", "Build") cbFire("Rewards", { Kind = "Build" }) end })
    CloneTab:Button({ Title = "Claim Walk-Speed Reward", Callback = function() cbFire("Rewards", "Walk") cbFire("Rewards", { Kind = "Walk" }) end })
    CloneTab:Button({ Title = "Claim Coins Reward", Callback = function() cbFire("Rewards", "Coins") cbFire("Rewards", { Kind = "Coins" }) end })

    -- ── Admin (dev-gated: this is how 24 clones / more speed is granted) ────
    local AdminTab = Window:Tab({ Title = "Clones: Admin", Icon = "shield" })
    AdminTab:Section({ Title = "Access" })
    AdminTab:Button({ Title = "Am I Admin?", Desc = "Probe the Admin remote — tells you if these grants will work.",
        Callback = function()
            local ok, res = cbFire("Admin", { Action = "Ping" })
            WindUI:Notify({ Title = "Admin", Content = ok and ("responded: " .. tostring(res)) or "no access / not found",
                Duration = 5, Icon = ok and "check" or "info" })
            print("[Nexus] Admin ping ->", ok, res)
        end })

    AdminTab:Section({ Title = "Give (server checks admin — no-ops otherwise)" })
    AdminTab:Slider({ Title = "Clone Amount",
        Value = { Min = 1, Max = 200, Default = Config.CBCloneAmount }, Step = 1,
        Callback = function(v) Config.CBCloneAmount = v queueSave() end })
    AdminTab:Toggle({ Title = "Permanent", Desc = "Ask for a permanent grant (vs. temporary).",
        Value = Config.CBPermanent, Callback = function(v) Config.CBPermanent = v queueSave() end })
    local function adminGive(kind, amount)
        -- exact request shape isn't in the dump; try the likely shapes
        cbFire("Admin", { Action = "Give", Kind = kind, Args = amount, Scope = "Server", Permanent = Config.CBPermanent })
        cbFire("Admin", { Action = "Give", Kind = kind, Amount = amount, Permanent = Config.CBPermanent })
        cbFire("Admin", "Give", kind, amount, Config.CBPermanent)
        WindUI:Notify({ Title = "Admin", Content = ("Tried: Give %s %s"):format(tostring(amount), kind), Duration = 4 })
    end
    AdminTab:Button({ Title = "Give Clones", Desc = "Give yourself the set number of clones.",
        Callback = function() adminGive("Clones", Config.CBCloneAmount) end })
    AdminTab:Button({ Title = "Give Build Speed", Callback = function() adminGive("Build", 3) end })
    AdminTab:Button({ Title = "Give Walk Speed", Callback = function() adminGive("Walk", 3) end })

    AdminTab:Section({ Title = "Advanced" })
    local cbRRName = ""
    AdminTab:Input({ Title = "Remote Name", Placeholder = "e.g. Admin / Rewards / ReassignAll",
        Callback = function(v) cbRRName = v end })
    AdminTab:Button({ Title = "Fire Remote", Callback = function()
        if cbRRName ~= "" then
            local ok = cbFire(cbRRName)
            WindUI:Notify({ Title = cbRRName, Content = ok and "fired" or "not found", Duration = 4 })
        end
    end })
    AdminTab:Button({ Title = "Print Remote Tree", Desc = "List every remote under CloneForge.Remotes (F9 console).",
        Callback = function()
            local root = cbRemotesFolder()
            local n = 0
            for _, d in ipairs(root:GetDescendants()) do
                if d:IsA("RemoteEvent") or d:IsA("RemoteFunction") then
                    n = n + 1
                    print(("[Nexus] %s (%s) %s"):format(d.Name, d.ClassName, d:GetFullName()))
                end
            end
            WindUI:Notify({ Title = "Remotes", Content = n .. " printed to console (F9)", Duration = 5 })
        end })
    AdminTab:Paragraph({ Title = "How clone count / speed actually work",
        Desc = "CloneCapacity and build/work speed are server stats. A normal account "
            .. "raises them only through the game's upgrades / gamepasses / ad rewards. "
            .. "The Give buttons use the game's own Admin remote, which the server honors "
            .. "ONLY for game admins — on a normal account they no-op (nothing to bypass; "
            .. "it's a server-side permission check). 'Assign All Clones' and the universal "
            .. "WalkSpeed (Player tab) work for everyone." })

    -- ── ADVANCED BUILDING TOOLS (F3X: Move / Resize / Rotate) ─────────────
    -- The game's builder is a Tool "CloneBuildersF3X" enabled via the
    -- WorldPicking attribute + the Workshop remote. The "Advanced" tier is a
    -- gamepass (Pass_Advanced) checked with UserOwnsGamePassAsync.
    local BuildTab = Window:Tab({ Title = "Clones: Build", Icon = "hammer" })

    local function findBuildTool()
        for _, c in ipairs({ lp.Character, lp:FindFirstChildOfClass("Backpack") }) do
            if c then
                for _, t in ipairs(c:GetChildren()) do
                    if t:IsA("Tool") and (t.Name:find("F3X") or t.Name:lower():find("build")) then
                        return t
                    end
                end
            end
        end
    end

    BuildTab:Section({ Title = "Builder" })
    BuildTab:Button({ Title = "Equip Build Tool", Desc = "Find & equip CloneBuildersF3X (Move / Resize / Rotate).",
        Callback = function()
            local tool = findBuildTool()
            local h = myHum()
            if tool and h then
                pcall(function() h:EquipTool(tool) end)
                WindUI:Notify({ Title = "Build", Content = "Equipped " .. tool.Name, Duration = 4 })
            else
                WindUI:Notify({ Title = "Build", Content = "Build tool not found in backpack", Duration = 4, Icon = "alert-triangle" })
            end
        end })
    BuildTab:Button({ Title = "Open Build Tools", Desc = "Enable world-picking + open the Workshop tools.",
        Callback = function()
            pcall(function() lp:SetAttribute("WorldPicking", true) end)
            pcall(function() lp:SetAttribute("BuildInspectorEnabled", true) end)
            cbFire("Workshop", "OpenTools")
            cbFire("Workshop", { Action = "OpenTools" })
            WindUI:Notify({ Title = "Build", Content = "World-picking on + OpenTools fired", Duration = 4 })
        end })
    BuildTab:Button({ Title = "Close Build Tools",
        Callback = function()
            pcall(function() lp:SetAttribute("WorldPicking", false) end)
            pcall(function() lp:SetAttribute("BuildInspectorEnabled", false) end)
            cbFire("Workshop", "CloseTools")
        end })

    BuildTab:Section({ Title = "Vehicle / ride tuning" })
    local vMax = 100
    BuildTab:Slider({ Title = "Max Speed",
        Value = { Min = 10, Max = 500, Default = 100 }, Step = 10,
        Callback = function(v) vMax = v end })
    BuildTab:Button({ Title = "Tune Vehicle", Desc = "TuneVehicle -> MaxSpeed (best-effort).",
        Callback = function()
            cbFire("TuneVehicle", { MaxSpeed = vMax })
            cbFire("TuneVehicle", vMax)
            WindUI:Notify({ Title = "Vehicle", Content = "MaxSpeed " .. vMax, Duration = 3 })
        end })

    BuildTab:Section({ Title = "Clone assignment" })
    BuildTab:Button({ Title = "Reassign All Clones", Callback = function() cbFire("ReassignAll") end })
    BuildTab:Button({ Title = "Unassign All Clones", Callback = function() cbFire("Unassign") cbFire("ReassignAll", false) end })
    BuildTab:Paragraph({ Title = "Advanced builder note",
        Desc = "Move / Resize / Rotate come from the equipped CloneBuildersF3X tool. "
            .. "The 'Advanced' precision tier is a gamepass (Pass_Advanced) the server "
            .. "checks — basic building works for everyone; advanced needs the pass. Use "
            .. "the Clones: Admin remote runner / Print Remote Tree if a button's arg "
            .. "shape needs adjusting in-game." })
end

-- ═══════════════════════════════════════════════════════════════════════
--  INFO
-- ═══════════════════════════════════════════════════════════════════════
local InfoTab = Window:Tab({ Title = "Info", Icon = "info" })
InfoTab:Section({ Title = "Nexus • Granite (WindUI)" })
InfoTab:Paragraph({
    Title = "Detected game",
    Desc = ("%s  (PlaceId %s)"):format(GameName, tostring(game.PlaceId)),
})
InfoTab:Paragraph({
    Title = "About",
    Desc = "Nexus rebuilt on WindUI with an animated Granite dark theme. "
        .. "Universal player, visual, teleport and server tools work in every game; "
        .. "Prison Life, Murder Mystery 2 and Plus 1 Forge get dedicated tabs driven "
        .. "by the real remotes from their dumps. Config auto-saves.",
})
InfoTab:Button({
    Title = "Unload Nexus",
    Desc = "Disable all features and close.",
    Callback = function()
        _G.NexusWindUIActive = false
        for _, c in ipairs(connections) do pcall(function() c:Disconnect() end) end
        -- WindUI versions differ: try Close then Destroy
        if not pcall(function() Window:Close() end) then
            pcall(function() Window:Destroy() end)
        end
    end,
})

warn("[Nexus • Granite] loaded for " .. GameName)
