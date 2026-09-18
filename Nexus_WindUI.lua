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
  * Murder Mystery 2 (129264514977232 / 142823291)
      auto shoot aura + silent aim (GunServer.ShootStart), knife auto-farm
      + ranged throw (KnifeServer.SlashStart / FlingKnife), role-coloured
      ESP — the real remotes verified in the MM2 dump.
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
}

local function detectGame()
    local id = game.PlaceId
    if GAMES.PrisonLife[id] then return "PrisonLife", "Prison Life" end
    if GAMES.MM2[id]        then return "MM2",        "Murder Mystery 2" end
    return "Universal", "Universal"
end

local GameKey, GameName = detectGame()

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
                    if sg:IsA("ScreenGui") and (sg.Name == "WindUI" or sg:FindFirstChild("UIElements", true) or true) then
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
        if not flying then startFly() end
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
            local isM = false
            for _, container in ipairs({ p.Character, p:FindFirstChildOfClass("Backpack") }) do
                if container then
                    for _, t in ipairs(container:GetChildren()) do
                        if t:IsA("Tool") and t:FindFirstChild("KnifeServer") then isM = true break end
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
                        local score = d - (Config.PreferMurderer and isMurderer(p) and 100000 or 0)
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
            local _, shoot, equipped = findGun()
            if not (shoot and equipped) then return end
            local target = auraTarget()
            if not target then return end
            local part = partOf(target.Character, Config.ShootPart)
            if not part then return end
            if os.clock() - lastFire >= Config.FireInterval then
                lastFire = os.clock()
                shoot:FireServer(part.Position)
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
                            local score = d - (Config.PreferMurderer and isMurderer(p) and 100000 or 0)
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

    local lastSlash, lastKnifeEquip = 0, 0
    track(RunService.Heartbeat:Connect(function()
        pcall(function()
            local k = findKnifeAll()
            if Config.AutoEquipKnife and k and os.clock() - lastKnifeEquip >= 0.25 then
                lastKnifeEquip = os.clock()
                equip(k.tool)
            end
            if not Config.KnifeFarm then return end
            k = findKnifeAll()
            if not (k and k.equipped and k.slash) then return end
            local root = myRoot()
            local target = nearestPlayer(Config.KnifeRange)
            local ehrp = target and target.Character and target.Character:FindFirstChild("HumanoidRootPart")
            if root and ehrp and not shielded(target.Character) then
                if os.clock() - lastSlash >= Config.KnifeInterval then
                    lastSlash = os.clock()
                    root.CFrame = ehrp.CFrame * CFrame.new(0, 0, 2.5)
                    k.slash:FireServer()
                end
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
            local k = findKnifeAll()
            if not (k and k.equipped and k.fling) then return end
            local target = nearestPlayer(Config.ThrowRange)
            local part = target and partOf(target.Character, "Head")
            if part and not shielded(target.Character) then
                if os.clock() - lastThrow >= Config.ThrowInterval then
                    lastThrow = os.clock()
                    k.fling:FireServer(part.Position)
                end
            end
        end)
    end))
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
        .. "Prison Life and Murder Mystery 2 get dedicated tabs driven by the real "
        .. "remotes from their dumps. Config auto-saves.",
})
InfoTab:Button({
    Title = "Unload Nexus",
    Desc = "Disable all features and close.",
    Callback = function()
        _G.NexusWindUIActive = false
        for _, c in ipairs(connections) do pcall(function() c:Disconnect() end) end
        pcall(function() Window:Destroy() end)
    end,
})

warn("[Nexus • Granite] loaded for " .. GameName)
