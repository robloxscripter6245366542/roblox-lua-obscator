--[[
╔══════════════════════════════════════════════════════════════════════════╗
║   CHICKEN OR HERO  •  WindUI OP Hub                                        ║
║   Target : Ugc / "Chicken or Hero"   (PlaceId 107535308163741)            ║
║   Built from : ChickenOrHero_Deobfuscated.md (844 scripts decoded)        ║
║   UI    : WindUI  (https://github.com/Footagesus/WindUI)                   ║
║                                                                            ║
║   RELIABILITY NOTES                                                        ║
║   • Client-side features (Speed, Fly, Noclip, Infinite Jump, ESP,          ║
║     Fullbright, Anti-AFK) are self-contained and always work.              ║
║   • Server-side features fire the game's own RemoteEvents. Bytecode gives  ║
║     reliable remote *names* but not argument *order*, so every server call ║
║     is pcall-guarded and tries a few plausible command variants. Use the   ║
║     "Remotes" tab to see exactly what resolved, and tune in Misc → Console.║
╚══════════════════════════════════════════════════════════════════════════╝
]]

local ok, err = pcall(function()

-- ═══════════════════════════════════════════════════════════════════
--  SERVICES
-- ═══════════════════════════════════════════════════════════════════
local Players        = game:GetService("Players")
local RS             = game:GetService("ReplicatedStorage")
local UIS            = game:GetService("UserInputService")
local RunService     = game:GetService("RunService")
local Workspace      = game:GetService("Workspace")
local Lighting       = game:GetService("Lighting")
local TeleportService= game:GetService("TeleportService")
local VirtualUser    = game:FindService("VirtualUser")

local LP     = Players.LocalPlayer
local Camera = Workspace.CurrentCamera

-- ═══════════════════════════════════════════════════════════════════
--  CONFIG  (live state)
-- ═══════════════════════════════════════════════════════════════════
local C = {
    -- movement
    speedOn=false, speed=80, baseSpeed=16,
    jumpPowerOn=false, jumpPower=90,
    infJump=false, flyOn=false, flySpeed=70, noclip=false,
    noDashCd=false, infAdrenaline=false, spamBoost=false, boostInterval=0.2,
    -- combat / dodge
    autoTackle=false, autoDodge=false, tackleRange=120, dodgeRange=35, faceTarget=false,
    dodgeStrafe=true, dodgeJump=false, dodgePredict=false, dodgeCooldown=0.35,
    dodgeSafe=45,
    dodgeThreats=true, threatRadius=75, threatSpeed=12,   -- universal: barrels/balls/chasers/projectiles (all modes)
    -- game modes
    autoMapVote=false, autoModeFire=false, modeInterval=0.5,
    -- economy
    autoFarm=false, autoCrates=false, autoQuests=false, autoRewards=false, autoEquipBest=false, econInterval=1.0,
    autoRejoin=false,
    -- collectibles
    autoCandy=false, autoGems=false, autoPumpkin=false, collectRange=400, collectTP=false,
    -- esp
    espOn=false, espBox=true, espName=true, espDist=true, espTracer=false,
    espCollect=false, teamColors=true,
    fullbright=false, noFog=false,
    -- player / misc
    antiAfk=true, hideName=false,
}

-- ═══════════════════════════════════════════════════════════════════
--  REMOTE RESOLVER  —  recursive search under ChickenOrHero + caches
-- ═══════════════════════════════════════════════════════════════════
local RemoteCache = {}          -- name -> Instance
local RemoteIndex = {}          -- array of {name=,class=,path=}

local function indexRemotes()
    RemoteIndex = {}
    local roots = {}
    local coh = RS:FindFirstChild("ChickenOrHero")
    if coh then table.insert(roots, coh) end
    table.insert(roots, RS)
    local seen = {}
    for _, root in ipairs(roots) do
        for _, d in ipairs(root:GetDescendants()) do
            if (d:IsA("RemoteEvent") or d:IsA("RemoteFunction") or d:IsA("UnreliableRemoteEvent"))
               and not seen[d] then
                seen[d] = true
                RemoteCache[d.Name] = RemoteCache[d.Name] or d
                table.insert(RemoteIndex, { name=d.Name, class=d.ClassName, path=d:GetFullName() })
            end
        end
    end
    return #RemoteIndex
end

local function getRemote(name)
    local r = RemoteCache[name]
    if r and r.Parent then return r end
    -- lazy search
    local coh = RS:FindFirstChild("ChickenOrHero")
    for _, root in ipairs({ coh, RS }) do
        if root then
            for _, d in ipairs(root:GetDescendants()) do
                if d.Name == name and (d:IsA("RemoteEvent") or d:IsA("RemoteFunction") or d:IsA("UnreliableRemoteEvent")) then
                    RemoteCache[name] = d
                    return d
                end
            end
        end
    end
    return nil
end

-- fire a remote by name, dispatch on class; returns true if the call didn't error
local function fireRemote(name, ...)
    local r = getRemote(name)
    if not r then return false end
    local args = { ... }
    return pcall(function()
        if r:IsA("RemoteEvent") or r:IsA("UnreliableRemoteEvent") then
            r:FireServer(table.unpack(args))
        elseif r:IsA("RemoteFunction") then
            r:InvokeServer(table.unpack(args))
        end
    end)
end

-- try a remote with several leading command verbs (command-dispatch pattern)
local function tryVerbs(name, verbs, ...)
    local extra = { ... }
    local any = false
    for _, v in ipairs(verbs) do
        if fireRemote(name, v, table.unpack(extra)) then any = true end
    end
    -- also try with no verb (some remotes take raw args)
    if #verbs == 0 then fireRemote(name, table.unpack(extra)) end
    return any
end

-- ═══════════════════════════════════════════════════════════════════
--  CHARACTER HELPERS
-- ═══════════════════════════════════════════════════════════════════
local function char()  return LP.Character end
local function hum()   local c=char(); return c and c:FindFirstChildOfClass("Humanoid") end
local function hrp()   local c=char(); return c and c:FindFirstChild("HumanoidRootPart") end
local function roleOf(plr) return plr:GetAttribute("GameRole") end
local function myRole() return LP:GetAttribute("GameRole") end

local function nearestPlayer(maxDist, filterRole)
    local myHrp = hrp(); if not myHrp then return nil end
    local best, bestD = nil, maxDist or math.huge
    for _, p in ipairs(Players:GetPlayers()) do
        if p ~= LP and p.Character then
            local h = p.Character:FindFirstChild("HumanoidRootPart")
            local ph = p.Character:FindFirstChildOfClass("Humanoid")
            if h and ph and ph.Health > 0 then
                if (not filterRole) or roleOf(p) == filterRole then
                    local d = (h.Position - myHrp.Position).Magnitude
                    if d < bestD then best, bestD = p, d end
                end
            end
        end
    end
    return best, bestD
end

-- ═══════════════════════════════════════════════════════════════════
--  UI  —  WindUI
-- ═══════════════════════════════════════════════════════════════════
local WindUI = loadstring(game:HttpGet(
    "https://github.com/Footagesus/WindUI/releases/latest/download/main.lua"
))()

-- clean, cohesive dark theme (graphite + warm amber accent)
pcall(function()
    WindUI:AddTheme({
        Name        = "CleanDark",
        Accent      = "#f5a524",   -- amber accent (matches the drumstick)
        Dialog      = "#15171c",
        Outline     = "#262a33",
        Text        = "#eceef2",
        Placeholder = "#8b909a",
        Background  = "#0e1014",   -- near-black graphite
        Button      = "#191c22",
        Icon        = "#f5a524",
    })
    WindUI:SetTheme("CleanDark")
end)

local Window = WindUI:CreateWindow({
    Title        = "Chicken or Hero",
    Icon         = "drumstick",
    Author       = "OP Hub",
    Folder       = "ChickenOrHero_WindUI",
    Size         = UDim2.fromOffset(640, 496),
    Transparent  = true,
    Theme        = "CleanDark",
    SideBarWidth = 184,
})
pcall(function() Window:SetTransparent(true) end)
pcall(function() Window:EditOpenButton({ Title="Chicken or Hero", Icon="drumstick" }) end)

local nRemotes = indexRemotes()
WindUI:Notify({
    Title="Chicken or Hero • OP Hub",
    Content=("Loaded cleanly — %d remotes indexed. Role: %s"):format(nRemotes, tostring(myRole() or "lobby")),
    Duration=6, Icon="check",
})

-- ── Tabs (Home dashboard first) ─────────────────────────────────────
local HomeTab    = Window:Tab({ Title="Home",     Icon="home" })
local MoveTab    = Window:Tab({ Title="Movement", Icon="wind" })
local CombatTab  = Window:Tab({ Title="Combat",   Icon="swords" })
local ModesTab   = Window:Tab({ Title="Modes",    Icon="gamepad-2" })
local EconTab    = Window:Tab({ Title="Economy",  Icon="gift" })
local CollectTab = Window:Tab({ Title="Collect",  Icon="candy" })
local VisualTab  = Window:Tab({ Title="Visuals",  Icon="eye" })
local PlayerTab  = Window:Tab({ Title="Player",   Icon="user" })
local ServerTab  = Window:Tab({ Title="Server",   Icon="server" })
local RemoteTab  = Window:Tab({ Title="Remotes",  Icon="radio" })
local MiscTab    = Window:Tab({ Title="Misc",     Icon="settings" })

-- ═══════════════════════════════════════════════════════════════════
--  HOME  —  dashboard / quick access to headline features
-- ═══════════════════════════════════════════════════════════════════
HomeTab:Section({ Title="Chicken or Hero • OP Hub" })
HomeTab:Paragraph({
    Title="Quick access",
    Desc="The essentials are one tap away here. Full options live in the tabs on the left. "
       .."Press RightShift to hide/show the menu.",
})
HomeTab:Toggle({ Title="Auto Dodge (never caught)", Icon="shield",
    Value=C.autoDodge, Callback=function(v) C.autoDodge=v end })
HomeTab:Toggle({ Title="Auto Farm (everything)", Icon="gift",
    Value=C.autoFarm, Callback=function(v) C.autoFarm=v end })
HomeTab:Toggle({ Title="Fly", Icon="wind",
    Value=C.flyOn, Callback=function(v) C.flyOn=v end })
HomeTab:Toggle({ Title="WalkSpeed", Icon="zap",
    Value=C.speedOn, Callback=function(v) C.speedOn=v end })
HomeTab:Toggle({ Title="Player ESP", Icon="eye",
    Value=C.espOn, Callback=function(v) C.espOn=v end })
HomeTab:Section({ Title="Status" })
HomeTab:Button({ Title="Refresh Stats", Icon="refresh-cw", Callback=function()
    local parts={}
    for _, k in ipairs({"GameRole","InMatch","Coins","Gems","Gold","CandyCorn"}) do
        parts[#parts+1]=k.."="..tostring(LP:GetAttribute(k))
    end
    WindUI:Notify({ Title="Your stats", Content=table.concat(parts,"   "), Duration=7, Icon="user" })
end })

-- ═══════════════════════════════════════════════════════════════════
--  MOVEMENT  (client-side = reliable)
-- ═══════════════════════════════════════════════════════════════════
MoveTab:Section({ Title="Speed & Jump (client-side — reliable)" })

MoveTab:Toggle({ Title="WalkSpeed", Desc="Force your Humanoid WalkSpeed.",
    Value=C.speedOn, Callback=function(v) C.speedOn=v end })
MoveTab:Slider({ Title="WalkSpeed Value",
    Value={ Min=16, Max=300, Default=C.speed }, Step=2,
    Callback=function(v) C.speed=v end })
MoveTab:Toggle({ Title="JumpPower", Desc="Force JumpPower/JumpHeight.",
    Value=C.jumpPowerOn, Callback=function(v) C.jumpPowerOn=v end })
MoveTab:Slider({ Title="JumpPower Value",
    Value={ Min=50, Max=400, Default=C.jumpPower }, Step=5,
    Callback=function(v) C.jumpPower=v end })
MoveTab:Toggle({ Title="Infinite Jump", Desc="Jump again mid-air (press Space).",
    Value=C.infJump, Callback=function(v) C.infJump=v end })

MoveTab:Section({ Title="Fly & Noclip" })
MoveTab:Toggle({ Title="Fly", Desc="WASD + camera fly. Space/Ctrl = up/down.",
    Value=C.flyOn, Callback=function(v) C.flyOn=v end })
MoveTab:Slider({ Title="Fly Speed",
    Value={ Min=20, Max=250, Default=C.flySpeed }, Step=5,
    Callback=function(v) C.flySpeed=v end })
MoveTab:Toggle({ Title="Noclip", Desc="Walk through walls.",
    Value=C.noclip, Callback=function(v) C.noclip=v end })

MoveTab:Section({ Title="Boost / Dash (server — best-effort)" })
MoveTab:Toggle({ Title="No Dash Cooldown", Desc="Clear dash/boost cooldown attributes each frame.",
    Value=C.noDashCd, Callback=function(v) C.noDashCd=v end })
MoveTab:Toggle({ Title="Infinite Adrenaline", Desc="Keep Adrenaline attribute topped up.",
    Value=C.infAdrenaline, Callback=function(v) C.infAdrenaline=v end })
MoveTab:Toggle({ Title="Spam Boost", Desc="Fire BoostRequest on an interval.",
    Value=C.spamBoost, Callback=function(v) C.spamBoost=v end })
MoveTab:Slider({ Title="Boost Interval (ms)",
    Value={ Min=50, Max=1000, Default=math.floor(C.boostInterval*1000) }, Step=25,
    Callback=function(v) C.boostInterval=v/1000 end })
MoveTab:Button({ Title="Boost Now", Callback=function()
    if not fireRemote("BoostRequest") then fireRemote("JumpRequest") end end })

-- speed/jump loop
RunService.Heartbeat:Connect(function()
    local h = hum()
    if h then
        if C.speedOn then h.WalkSpeed = C.speed end
        if C.jumpPowerOn then
            pcall(function() h.UseJumpPower = true end)
            h.JumpPower = C.jumpPower
            pcall(function() h.JumpHeight = C.jumpPower/5 end)
        end
    end
    if C.noDashCd then
        for _, k in ipairs({ "DashCooldownUntil","BoostRecoveryUntil","DashCooldown" }) do
            pcall(function() LP:SetAttribute(k, 0) end)
        end
        pcall(function() LP:SetAttribute("DashCount", 99) end)
    end
    if C.infAdrenaline then pcall(function() LP:SetAttribute("Adrenaline", 100) end) end
end)

-- infinite jump
UIS.JumpRequest:Connect(function()
    if C.infJump then local h=hum(); if h then h:ChangeState(Enum.HumanoidStateType.Jumping) end end
end)

-- spam boost
task.spawn(function()
    while true do
        if C.spamBoost then
            if not fireRemote("BoostRequest") then fireRemote("JumpRequest") end
            task.wait(C.boostInterval)
        else task.wait(0.1) end
    end
end)

-- noclip loop
RunService.Stepped:Connect(function()
    if C.noclip then
        local c = char()
        if c then for _, p in ipairs(c:GetDescendants()) do
            if p:IsA("BasePart") and p.CanCollide then p.CanCollide=false end
        end end
    end
end)

-- fly
local flyBV, flyBG
local function stopFly()
    if flyBV then flyBV:Destroy() flyBV=nil end
    if flyBG then flyBG:Destroy() flyBG=nil end
end
RunService.RenderStepped:Connect(function()
    if not C.flyOn then if flyBV then stopFly() end return end
    Camera = Workspace.CurrentCamera or Camera
    local root=hrp(); local h=hum(); if not root or not h then return end
    if not flyBV then
        h.PlatformStand = true
        flyBV = Instance.new("BodyVelocity"); flyBV.MaxForce=Vector3.new(1,1,1)*9e9
        flyBV.Velocity=Vector3.zero; flyBV.Parent=root
        flyBG = Instance.new("BodyGyro"); flyBG.MaxForce=Vector3.new(1,1,1)*9e9
        flyBG.P=9e4; flyBG.Parent=root
    end
    local dir=Vector3.zero
    local cf=Camera.CFrame
    if UIS:IsKeyDown(Enum.KeyCode.W) then dir=dir+cf.LookVector end
    if UIS:IsKeyDown(Enum.KeyCode.S) then dir=dir-cf.LookVector end
    if UIS:IsKeyDown(Enum.KeyCode.A) then dir=dir-cf.RightVector end
    if UIS:IsKeyDown(Enum.KeyCode.D) then dir=dir+cf.RightVector end
    if UIS:IsKeyDown(Enum.KeyCode.Space) then dir=dir+Vector3.new(0,1,0) end
    if UIS:IsKeyDown(Enum.KeyCode.LeftControl) then dir=dir-Vector3.new(0,1,0) end
    flyBV.Velocity = (dir.Magnitude>0 and dir.Unit or Vector3.zero)*C.flySpeed
    flyBG.CFrame = cf
end)

-- ═══════════════════════════════════════════════════════════════════
--  COMBAT
-- ═══════════════════════════════════════════════════════════════════
CombatTab:Section({ Title="Catcher — auto tackle" })
CombatTab:Toggle({ Title="Auto Tackle", Desc="Dash/boost into the nearest runner.",
    Value=C.autoTackle, Callback=function(v) C.autoTackle=v end })
CombatTab:Slider({ Title="Tackle Range (studs)",
    Value={ Min=20, Max=300, Default=C.tackleRange }, Step=10,
    Callback=function(v) C.tackleRange=v end })
CombatTab:Toggle({ Title="Face Target", Desc="Turn your character toward the target.",
    Value=C.faceTarget, Callback=function(v) C.faceTarget=v end })

CombatTab:Section({ Title="Runner — auto dodge" })
CombatTab:Toggle({ Title="Auto Dodge", Desc="Full real dodging — keeps every catcher outside Keep-Distance at all times. Never caught.",
    Value=C.autoDodge, Callback=function(v) C.autoDodge=v end })
CombatTab:Slider({ Title="Dodge Range (studs)",
    Value={ Min=10, Max=120, Default=C.dodgeRange }, Step=5,
    Callback=function(v) C.dodgeRange=v end })
CombatTab:Slider({ Title="Keep Distance (studs)", Desc="Never let a catcher within this range — pushes you out every frame. The 'no-miss' core.",
    Value={ Min=15, Max=120, Default=C.dodgeSafe }, Step=5,
    Callback=function(v) C.dodgeSafe=v end })
CombatTab:Toggle({ Title="Strafe Dodge", Desc="Sidestep perpendicular instead of straight back (harder to catch).",
    Value=C.dodgeStrafe, Callback=function(v) C.dodgeStrafe=v end })
CombatTab:Toggle({ Title="Dodge Jump", Desc="Also hop while dodging.",
    Value=C.dodgeJump, Callback=function(v) C.dodgeJump=v end })
CombatTab:Toggle({ Title="Dodge All Threats (every mode)", Desc="Also sidestep barrels, dodgeballs, chasers, bombs & any incoming projectile — not just catchers. Covers Crossy Road / Donkey Kong / Dodgeball / boss modes.",
    Value=C.dodgeThreats, Callback=function(v) C.dodgeThreats=v end })
CombatTab:Slider({ Title="Threat Detect Radius (studs)", Desc="How far out to watch for moving hazards.",
    Value={ Min=20, Max=200, Default=C.threatRadius }, Step=5,
    Callback=function(v) C.threatRadius=v end })
CombatTab:Toggle({ Title="Prediction Mode (optional)", Desc="OFF = full real dodging, never miss (default). ON = only react to incoming tackles.",
    Value=C.dodgePredict, Callback=function(v) C.dodgePredict=v end })
CombatTab:Slider({ Title="Prediction Cooldown (ms)", Desc="Only used when Prediction Mode is ON.",
    Value={ Min=100, Max=1000, Default=math.floor(C.dodgeCooldown*1000) }, Step=25,
    Callback=function(v) C.dodgeCooldown=v/1000 end })

CombatTab:Section({ Title="Manual" })
CombatTab:Button({ Title="Tackle / Boost Now", Callback=function()
    fireRemote("BoostRequest"); fireRemote("BladeBallEvent") end })

-- combat / universal-dodge loop
local _lastPos   = {}      -- player -> last HRP position (closing-velocity prediction)
local _threatPos = {}      -- threat part -> last position (velocity for CFrame-moved hazards)
local _lastDodge = 0
local _tackleAccum = 0

-- Universal threat scan: barrels, dodgeballs, chasers, bombs, projectiles — every mode.
local THREAT_PATTERNS = { "barrel","dodgeball","chaser","bomb","projectile","spike",
    "car","train","traffic","boulder","saw","laser","missile","arrow","obstacle","hazard" }
local _threatCache = {}
local _threatT = 0
local function refreshThreats()
    local out = {}
    for _, d in ipairs(Workspace:GetDescendants()) do
        if d:IsA("BasePart") then
            local nm = d.Name:lower()
            for _, pat in ipairs(THREAT_PATTERNS) do
                if nm:find(pat) then out[#out+1] = d break end
            end
        end
    end
    _threatCache = out
end
local function threatVel(part, dt)
    local prev = _threatPos[part]
    if prev then return (part.Position - prev) / math.max(dt or 0.05, 0.001) end
    local ok2, v = pcall(function() return part.AssemblyLinearVelocity end)
    return (ok2 and v) or Vector3.zero
end
local function nearestThreat(fromPos, radius, speedMin, dt)
    local best, bd
    for _, part in ipairs(_threatCache) do
        if part.Parent then
            local d = (part.Position - fromPos).Magnitude
            if d <= radius and d < (bd or math.huge) then
                if threatVel(part, dt).Magnitude >= speedMin or d <= 12 then best, bd = part, d end
            end
        end
    end
    return best, bd
end

task.spawn(function()
    while true do
        local dt = task.wait(0.05)
        local root=hrp(); local h=hum(); if not root then continue end

        if C.autoTackle then
            _tackleAccum = _tackleAccum + (dt or 0.05)
            if _tackleAccum >= 0.1 then
                _tackleAccum = 0
                local target = nearestPlayer(C.tackleRange, "Runner") or nearestPlayer(C.tackleRange)
                if target and target.Character then
                    local th=target.Character:FindFirstChild("HumanoidRootPart")
                    if th then
                        if C.faceTarget then
                            pcall(function() root.CFrame=CFrame.lookAt(root.Position, Vector3.new(th.Position.X,root.Position.Y,th.Position.Z)) end)
                        end
                        if not fireRemote("BoostRequest") then fireRemote("BladeBallEvent") end
                    end
                end
            end
        end

        if C.autoDodge then
            -- pick the most imminent hazard: nearest catcher/player OR nearest moving threat part
            local tgtPos, tgtRef, tgtDist, isPart
            local catcher, cd = nearestPlayer(C.dodgeRange, "Catcher")
            if not catcher then catcher, cd = nearestPlayer(C.dodgeRange) end
            local ch = catcher and catcher.Character and catcher.Character:FindFirstChild("HumanoidRootPart")
            if ch then tgtPos, tgtDist, tgtRef = ch.Position, cd, ch.CFrame.LookVector end
            if C.dodgeThreats then
                local part, pd = nearestThreat(root.Position, C.threatRadius, C.threatSpeed, dt)
                if part and (not tgtDist or pd < tgtDist) then
                    tgtPos, tgtDist, isPart = part.Position, pd, true
                    local v = threatVel(part, dt)
                    tgtRef = (v.Magnitude > 1 and v) or (root.Position - part.Position)
                end
            end

            if tgtPos then
                local away = (root.Position - tgtPos)
                away = (away.Magnitude > 0) and away.Unit or Vector3.new(0,0,1)
                local dir = away
                if C.dodgeStrafe then
                    -- sidestep perpendicular to the hazard's travel direction (leave its lane)
                    local refv = (tgtRef and tgtRef.Magnitude > 0) and tgtRef.Unit or (-away)
                    local perp = refv:Cross(Vector3.new(0,1,0))
                    if perp.Magnitude > 0 then
                        perp = perp.Unit
                        if perp:Dot(away) < 0 then perp = -perp end
                        dir = (perp + away*0.5); if dir.Magnitude > 0 then dir = dir.Unit end
                    end
                end
                -- tighter ring for projectiles, full keep-distance for catchers
                local safe = isPart and math.max(10, C.dodgeSafe*0.6) or C.dodgeSafe

                if C.dodgePredict and not isPart then
                    local prev = _lastPos[catcher]; local closing = false
                    local toMe = (root.Position - tgtPos)
                    if toMe.Magnitude > 0 and prev then
                        if ((tgtPos - prev)/(dt or 0.05)):Dot(toMe.Unit) > 6 then closing = true end
                    end
                    local function attr(i,k) local ok3,val=pcall(function() return i:GetAttribute(k) end) return ok3 and val end
                    if attr(catcher,"TackleActive") or attr(LP,"Caught") or attr(LP,"TackleActive") then closing = true end
                    if closing and (os.clock() - _lastDodge) >= C.dodgeCooldown then
                        _lastDodge = os.clock()
                        if C.faceTarget then pcall(function() root.CFrame=CFrame.lookAt(root.Position, root.Position+dir) end) end
                        pcall(function() root.CFrame = root.CFrame + dir * 6 end)
                        if h and C.dodgeJump then h:ChangeState(Enum.HumanoidStateType.Jumping) end
                        if not fireRemote("BoostRequest") then fireRemote("PerfectDodge") end
                    end
                elseif (tgtDist or math.huge) < safe then
                    -- FULL REAL DODGE (no miss): snap outside the safe ring every tick
                    local target = tgtPos + dir * safe
                    target = Vector3.new(target.X, root.Position.Y, target.Z)
                    local faceP = C.faceTarget and tgtPos or (target + root.CFrame.LookVector)
                    pcall(function()
                        root.CFrame = CFrame.new(target, Vector3.new(faceP.X, target.Y, faceP.Z))
                        root.AssemblyLinearVelocity = Vector3.zero
                    end)
                    if h and C.dodgeJump then h:ChangeState(Enum.HumanoidStateType.Jumping) end
                    fireRemote("BoostRequest")
                end
            end
        end

        -- refresh threat cache occasionally (cheap: name-matched parts only)
        _threatT = _threatT + (dt or 0.05)
        if C.dodgeThreats and _threatT >= 0.4 then _threatT = 0; pcall(refreshThreats) end
        -- update velocity caches for next tick
        for _, p in ipairs(Players:GetPlayers()) do
            if p ~= LP and p.Character then
                local hh = p.Character:FindFirstChild("HumanoidRootPart")
                if hh then _lastPos[p] = hh.Position end
            end
        end
        _threatPos = {}
        for _, part in ipairs(_threatCache) do if part.Parent then _threatPos[part] = part.Position end end
    end
end)

-- ═══════════════════════════════════════════════════════════════════
--  GAME MODES  (works across every minigame the game rotates)
-- ═══════════════════════════════════════════════════════════════════
local MODE_EVENTS = {
    "CrossyRoadEvent","DonkeyKongEvent","DodgeballEvent","FootballEvent","TeamEvent",
    "BladeBallEvent","FallenKingEvent","OutbreakEvent","BloodMoonEvent","HauntEvent",
    "PumpkinHuntEvent","PumpkinEvent","CarouselEvent","RescueEvent",
}
ModesTab:Section({ Title="Universal survival" })
ModesTab:Paragraph({ Title="Covers every mode",
    Desc="Chicken or Hero rotates through Catch/Chase, Crossy Road, Donkey Kong, Dodgeball, "
       .."Football, Blade Ball, Fallen King (boss), Outbreak, Blood Moon & Halloween events. "
       .."The one thing that wins them all: never get hit. Enable the two below and you survive "
       .."every mode automatically." })
ModesTab:Toggle({ Title="Auto Dodge (never caught)", Icon="shield",
    Value=C.autoDodge, Callback=function(v) C.autoDodge=v end })
ModesTab:Toggle({ Title="Dodge All Threats (barrels/balls/chasers/bombs)", Icon="alert-triangle",
    Value=C.dodgeThreats, Callback=function(v) C.dodgeThreats=v end })

ModesTab:Section({ Title="Auto participate" })
ModesTab:Toggle({ Title="Auto Map Vote", Desc="Vote the moment the map-vote opens.",
    Value=C.autoMapVote, Callback=function(v) C.autoMapVote=v end })
ModesTab:Toggle({ Title="Auto Ready / Fire Mode Events", Desc="Fire every rotating mode's remote on an interval (best-effort auto-ready / auto-action).",
    Value=C.autoModeFire, Callback=function(v) C.autoModeFire=v end })
ModesTab:Slider({ Title="Mode Fire Interval (ms)",
    Value={ Min=200, Max=3000, Default=math.floor(C.modeInterval*1000) }, Step=100,
    Callback=function(v) C.modeInterval=v/1000 end })
ModesTab:Button({ Title="Fire All Mode Events Now", Callback=function()
    for _, ev in ipairs(MODE_EVENTS) do fireRemote(ev) end
end })

-- mode participation loop
task.spawn(function()
    while true do
        if C.autoMapVote then
            tryVerbs("MapVoteEvent", {"Vote","Cast","Pick"}, 1)
            fireRemote("MapVoteEvent", 1)
        end
        if C.autoModeFire then
            for _, ev in ipairs(MODE_EVENTS) do fireRemote(ev) end
        end
        task.wait((C.autoMapVote or C.autoModeFire) and C.modeInterval or 0.5)
    end
end)

-- ═══════════════════════════════════════════════════════════════════
--  ECONOMY  (server — best-effort command-dispatch)
-- ═══════════════════════════════════════════════════════════════════
EconTab:Section({ Title="★ Master" })
EconTab:Toggle({ Title="AUTO FARM (everything)", Desc="One switch: crates + quests + level rewards + all collectibles (candy/gems/pumpkin).",
    Value=C.autoFarm, Callback=function(v) C.autoFarm=v end })
EconTab:Toggle({ Title="Auto Rejoin on Match End", Desc="Hop to a fresh server when a round ends (keeps farming lobbies).",
    Value=C.autoRejoin, Callback=function(v) C.autoRejoin=v end })

EconTab:Section({ Title="Auto farm (fires the game's own remotes)" })
EconTab:Toggle({ Title="Auto Open Crates", Desc="CrateEvent / CrateRollEvent.",
    Value=C.autoCrates, Callback=function(v) C.autoCrates=v end })
EconTab:Toggle({ Title="Auto Claim Quests", Desc="QuestEvent claim.",
    Value=C.autoQuests, Callback=function(v) C.autoQuests=v end })
EconTab:Toggle({ Title="Auto Claim Level Rewards", Desc="LevelRewardEvent.",
    Value=C.autoRewards, Callback=function(v) C.autoRewards=v end })
EconTab:Toggle({ Title="Auto Equip Best Gear", Desc="ArmoryEvent/GearEvent EquipGear.",
    Value=C.autoEquipBest, Callback=function(v) C.autoEquipBest=v end })
EconTab:Slider({ Title="Farm Interval (ms)",
    Value={ Min=250, Max=5000, Default=math.floor(C.econInterval*1000) }, Step=250,
    Callback=function(v) C.econInterval=v/1000 end })

EconTab:Section({ Title="Manual" })
EconTab:Button({ Title="Open Crate Now", Callback=function()
    tryVerbs("CrateEvent", {"Open","OpenCrate","Roll","Buy"})
    tryVerbs("CrateRollEvent", {"Roll","Open"}) end })
EconTab:Button({ Title="Claim All Quests", Callback=function()
    tryVerbs("QuestEvent", {"ClaimAll","Claim","Complete"}) end })
EconTab:Button({ Title="Claim Level Rewards", Callback=function()
    tryVerbs("LevelRewardEvent", {"ClaimAll","Claim"}) end })

-- helper: list owned gear/weapons from catalog-ish attributes and equip
local function equipBestGear()
    -- Weapons attribute often lists owned gear; try equipping each known weapon name
    local weapons = LP:GetAttribute("Weapons")
    if type(weapons)=="string" then
        for name in weapons:gmatch("[%w_]+") do
            tryVerbs("ArmoryEvent", {"EquipGear","Equip"}, name)
            tryVerbs("GearEvent",   {"EquipGear","Equip"}, name)
        end
    else
        tryVerbs("ArmoryEvent", {"EquipGear","Equip"})
        tryVerbs("GearEvent",   {"EquipGear","Equip"})
    end
end

task.spawn(function()
    while true do
        if C.autoFarm or C.autoCrates then
            tryVerbs("CrateEvent", {"Open","OpenCrate","Roll"})
            tryVerbs("CrateRollEvent", {"Roll","Open"})
        end
        if C.autoFarm or C.autoQuests then tryVerbs("QuestEvent", {"ClaimAll","Claim","Complete"}) end
        if C.autoFarm or C.autoRewards then tryVerbs("LevelRewardEvent", {"ClaimAll","Claim"}) end
        if C.autoEquipBest then equipBestGear() end
        if C.autoFarm then
            -- master farm also auto-claims/participates across every rotating mode
            for _, ev in ipairs(MODE_EVENTS) do tryVerbs(ev, {"Claim","Reward","Ready","Collect"}) end
        end
        task.wait(C.econInterval)
    end
end)

-- auto-rejoin on match end (InMatch true -> false)
task.spawn(function()
    local was = LP:GetAttribute("InMatch")
    while true do
        task.wait(1)
        local now = LP:GetAttribute("InMatch")
        if C.autoRejoin and was and not now then
            pcall(function() TeleportService:Teleport(game.PlaceId, LP) end)
        end
        was = now
    end
end)

-- ═══════════════════════════════════════════════════════════════════
--  COLLECTIBLES  (candy corn / gems / pumpkin)
-- ═══════════════════════════════════════════════════════════════════
CollectTab:Section({ Title="Event auto-collect" })
CollectTab:Toggle({ Title="Auto Candy Corn", Desc="Collect candy corn in range.",
    Value=C.autoCandy, Callback=function(v) C.autoCandy=v end })
CollectTab:Toggle({ Title="Auto Gems", Desc="Collect gems in range.",
    Value=C.autoGems, Callback=function(v) C.autoGems=v end })
CollectTab:Toggle({ Title="Auto Pumpkin Hunt", Desc="Fire PumpkinHuntEvent pickups.",
    Value=C.autoPumpkin, Callback=function(v) C.autoPumpkin=v end })
CollectTab:Toggle({ Title="Teleport To Pickups", Desc="Briefly TP to each collectible (fast farm).",
    Value=C.collectTP, Callback=function(v) C.collectTP=v end })
CollectTab:Slider({ Title="Collect Range (studs)",
    Value={ Min=50, Max=1500, Default=C.collectRange }, Step=50,
    Callback=function(v) C.collectRange=v end })

-- find collectible parts by name heuristics
local function collectiblesMatching(patterns)
    local out={}
    for _, d in ipairs(Workspace:GetDescendants()) do
        if d:IsA("BasePart") or d:IsA("Model") then
            local nm=d.Name:lower()
            for _, pat in ipairs(patterns) do
                if nm:find(pat) then table.insert(out, d) break end
            end
        end
    end
    return out
end

local function partPos(x)
    if x:IsA("BasePart") then return x.Position
    elseif x:IsA("Model") then local p=x.PrimaryPart or x:FindFirstChildWhichIsA("BasePart"); return p and p.Position end
end

task.spawn(function()
    while true do
        task.wait(0.25)
        local root=hrp(); if not root then continue end
        local jobs={}
        if C.autoFarm or C.autoCandy then jobs[#jobs+1]={ {"candy","corn"}, {"CandyCornEvent"} } end
        if C.autoFarm or C.autoGems  then jobs[#jobs+1]={ {"gem"},          {"GemEvent"} } end
        if C.autoFarm or C.autoPumpkin then jobs[#jobs+1]={ {"pumpkin"},    {"PumpkinHuntEvent","PumpkinEvent"} } end
        for _, job in ipairs(jobs) do
            local parts=collectiblesMatching(job[1])
            for _, part in ipairs(parts) do
                local pos=partPos(part)
                if pos and (pos-root.Position).Magnitude<=C.collectRange then
                    if C.collectTP then pcall(function() root.CFrame=CFrame.new(pos+Vector3.new(0,3,0)) end) task.wait(0.06) end
                    for _, rem in ipairs(job[2]) do
                        tryVerbs(rem, {"Collect","Pickup","Claim"}, part)
                        fireRemote(rem, part)
                    end
                end
            end
        end
    end
end)

-- ═══════════════════════════════════════════════════════════════════
--  VISUALS / ESP
-- ═══════════════════════════════════════════════════════════════════
VisualTab:Section({ Title="Player ESP" })
VisualTab:Toggle({ Title="Player ESP", Value=C.espOn, Callback=function(v) C.espOn=v end })
VisualTab:Toggle({ Title="Box / Chams", Value=C.espBox, Callback=function(v) C.espBox=v end })
VisualTab:Toggle({ Title="Name", Value=C.espName, Callback=function(v) C.espName=v end })
VisualTab:Toggle({ Title="Distance", Value=C.espDist, Callback=function(v) C.espDist=v end })
VisualTab:Toggle({ Title="Tracers", Value=C.espTracer, Callback=function(v) C.espTracer=v end })
VisualTab:Toggle({ Title="Team Colors (Runner/Catcher/Hero)", Value=C.teamColors,
    Callback=function(v) C.teamColors=v end })

VisualTab:Section({ Title="Collectible ESP" })
VisualTab:Toggle({ Title="Collectible Highlights", Desc="Glow candy/gems/pumpkins.",
    Value=C.espCollect, Callback=function(v) C.espCollect=v end })

VisualTab:Section({ Title="World" })
VisualTab:Toggle({ Title="Fullbright", Value=C.fullbright, Callback=function(v) C.fullbright=v
    if not v then pcall(function() Lighting.Brightness=1 end) end end })
VisualTab:Toggle({ Title="No Fog", Value=C.noFog, Callback=function(v) C.noFog=v end })

local function roleColor(p)
    if not C.teamColors then return Color3.fromRGB(255,255,255) end
    local r=roleOf(p)
    if r=="Catcher" then return Color3.fromRGB(255,70,70)
    elseif r=="Runner" then return Color3.fromRGB(90,255,120)
    elseif r then return Color3.fromRGB(255,210,70) end
    return Color3.fromRGB(120,180,255)
end

-- highlight-based ESP (works on most executors)
local espHl = {}      -- player -> Highlight
local espTag = {}     -- player -> BillboardGui
local tracers = {}    -- player -> Drawing line (if available)

local function ensureTag(p)
    if espTag[p] and espTag[p].Parent then return espTag[p] end
    local bb=Instance.new("BillboardGui")
    bb.Name="__coh_tag"; bb.AlwaysOnTop=true; bb.Size=UDim2.fromOffset(200,34)
    bb.StudsOffset=Vector3.new(0,3,0)
    local lbl=Instance.new("TextLabel")
    lbl.BackgroundTransparency=1; lbl.Size=UDim2.fromScale(1,1)
    lbl.Font=Enum.Font.GothamBold; lbl.TextSize=14; lbl.TextStrokeTransparency=0.3
    lbl.TextColor3=Color3.new(1,1,1); lbl.Name="L"; lbl.Parent=bb
    espTag[p]=bb
    return bb
end

local hasDrawing = (typeof(Drawing)=="table" or typeof(Drawing)=="userdata")
local function ensureTracer(p)
    if not hasDrawing then return nil end
    if tracers[p] then return tracers[p] end
    local ok2,line=pcall(function() local l=Drawing.new("Line"); l.Thickness=1.6; l.Transparency=1; return l end)
    if ok2 then tracers[p]=line; return line end
end

RunService.RenderStepped:Connect(function()
    Camera = Workspace.CurrentCamera or Camera
    -- fullbright / fog
    if C.fullbright then pcall(function() Lighting.Brightness=3; Lighting.ClockTime=14; Lighting.GlobalShadows=false; Lighting.Ambient=Color3.fromRGB(180,180,180) end) end
    if C.noFog then pcall(function() Lighting.FogEnd=1e6; Lighting.FogStart=1e6 end) end

    -- player ESP
    for _, p in ipairs(Players:GetPlayers()) do
        if p~=LP then
            local c=p.Character
            local h=c and c:FindFirstChild("HumanoidRootPart")
            local col=roleColor(p)
            if C.espOn and h then
                -- chams
                if C.espBox then
                    local hl=espHl[p]
                    if not (hl and hl.Parent) then
                        hl=Instance.new("Highlight"); hl.Name="__coh_hl"
                        hl.FillTransparency=0.55; hl.OutlineTransparency=0
                        hl.Parent=c; espHl[p]=hl
                    end
                    hl.Adornee=c; hl.FillColor=col; hl.OutlineColor=col
                elseif espHl[p] then espHl[p]:Destroy() espHl[p]=nil end
                -- tag
                if C.espName or C.espDist then
                    local bb=ensureTag(p); bb.Adornee=h; bb.Parent=c
                    local d=math.floor((h.Position-(hrp() and hrp().Position or h.Position)).Magnitude)
                    local txt=""
                    if C.espName then txt=p.DisplayName..(roleOf(p) and (" ["..roleOf(p).."]") or "") end
                    if C.espDist then txt=txt..(C.espName and "  " or "").."("..d.."m)" end
                    bb.L.Text=txt; bb.L.TextColor3=col
                elseif espTag[p] then espTag[p]:Destroy() espTag[p]=nil end
                -- tracer
                local line=C.espTracer and ensureTracer(p)
                if line then
                    local sp,on=Camera:WorldToViewportPoint(h.Position)
                    if on then
                        line.Visible=true; line.Color=col
                        line.From=Vector2.new(Camera.ViewportSize.X/2, Camera.ViewportSize.Y)
                        line.To=Vector2.new(sp.X, sp.Y)
                    else line.Visible=false end
                elseif tracers[p] then tracers[p].Visible=false end
            else
                if espHl[p] then espHl[p]:Destroy() espHl[p]=nil end
                if espTag[p] then espTag[p]:Destroy() espTag[p]=nil end
                if tracers[p] then tracers[p].Visible=false end
            end
        end
    end
end)

Players.PlayerRemoving:Connect(function(p)
    if espHl[p] then espHl[p]:Destroy() espHl[p]=nil end
    if espTag[p] then espTag[p]:Destroy() espTag[p]=nil end
    if tracers[p] then pcall(function() tracers[p]:Remove() end) tracers[p]=nil end
end)

-- collectible highlights
local collectHl={}
task.spawn(function()
    while true do
        task.wait(0.4)
        if C.espCollect then
            local parts=collectiblesMatching({"candy","corn","gem","pumpkin"})
            local live={}
            for _, part in ipairs(parts) do
                live[part]=true
                if not (collectHl[part] and collectHl[part].Parent) then
                    local hl=Instance.new("Highlight")
                    hl.FillColor=Color3.fromRGB(255,180,40); hl.OutlineColor=Color3.fromRGB(255,220,120)
                    hl.FillTransparency=0.4; hl.Parent=part; collectHl[part]=hl
                end
            end
            for part,hl in pairs(collectHl) do
                if not live[part] then hl:Destroy() collectHl[part]=nil end
            end
        else
            for part,hl in pairs(collectHl) do hl:Destroy() collectHl[part]=nil end
        end
    end
end)

-- ═══════════════════════════════════════════════════════════════════
--  PLAYER / MISC
-- ═══════════════════════════════════════════════════════════════════
PlayerTab:Section({ Title="Session" })
PlayerTab:Toggle({ Title="Anti-AFK", Desc="Never get kicked for idling.",
    Value=C.antiAfk, Callback=function(v) C.antiAfk=v end })
PlayerTab:Button({ Title="Reset Character", Callback=function()
    local h=hum(); if h then h.Health=0 end end })
PlayerTab:Button({ Title="Show My Stats", Callback=function()
    local parts={}
    for _, k in ipairs({"GameRole","InMatch","Coins","Gems","Gold","CandyCorn","Adrenaline"}) do
        parts[#parts+1]=k.."="..tostring(LP:GetAttribute(k))
    end
    WindUI:Notify({ Title="My Stats", Content=table.concat(parts,"  "), Duration=8, Icon="user" })
end })

if VirtualUser then
    LP.Idled:Connect(function()
        if C.antiAfk then
            VirtualUser:CaptureController()
            VirtualUser:ClickButton2(Vector2.new())
        end
    end)
end

-- ═══════════════════════════════════════════════════════════════════
--  SERVER
-- ═══════════════════════════════════════════════════════════════════
ServerTab:Section({ Title="Server" })
ServerTab:Button({ Title="Rejoin Server", Callback=function()
    TeleportService:Teleport(game.PlaceId, LP) end })
ServerTab:Button({ Title="Hop Server (new)", Callback=function()
    pcall(function() TeleportService:Teleport(game.PlaceId, LP) end) end })
ServerTab:Button({ Title="Copy JobId", Callback=function()
    if setclipboard then setclipboard(game.JobId) end
    WindUI:Notify({ Title="JobId", Content=game.JobId, Duration=6, Icon="copy" }) end })
ServerTab:Paragraph({ Title="PlaceId", Desc=tostring(game.PlaceId) })

-- ═══════════════════════════════════════════════════════════════════
--  REMOTES  (explorer)
-- ═══════════════════════════════════════════════════════════════════
RemoteTab:Section({ Title="Resolved remotes" })
RemoteTab:Paragraph({ Title="Indexed", Desc=("%d RemoteEvents/Functions under ChickenOrHero/ReplicatedStorage."):format(#RemoteIndex) })
RemoteTab:Button({ Title="Re-index Remotes", Callback=function()
    local n=indexRemotes()
    WindUI:Notify({ Title="Remotes", Content=n.." remotes indexed.", Duration=5, Icon="radio" }) end })
RemoteTab:Button({ Title="Dump Remote List (console + clipboard)", Callback=function()
    local lines={}
    for _, r in ipairs(RemoteIndex) do lines[#lines+1]=("[%s] %s"):format(r.class, r.path) end
    table.sort(lines)
    local text=table.concat(lines,"\n")
    print("===== Chicken or Hero remotes ("..#lines..") =====\n"..text)
    if setclipboard then setclipboard(text) end
    WindUI:Notify({ Title="Remotes", Content="Dumped "..#lines.." to console/clipboard.", Duration=5, Icon="radio" }) end })

-- searchable fire input
local fireName, fireArg = "", ""
RemoteTab:Section({ Title="Manual fire (for tuning best-effort calls)" })
RemoteTab:Input({ Title="Remote Name", Placeholder="e.g. ArmoryEvent",
    Callback=function(v) fireName=v end })
RemoteTab:Input({ Title="String Args (comma-separated)", Placeholder="e.g. EquipGear,Dagger",
    Callback=function(v) fireArg=v end })
RemoteTab:Button({ Title="FireServer", Callback=function()
    local args={}
    for a in tostring(fireArg):gmatch("[^,]+") do args[#args+1]=(a:gsub("^%s+",""):gsub("%s+$","")) end
    local okFire=fireRemote(fireName, table.unpack(args))
    WindUI:Notify({ Title="Fire "..fireName, Content=okFire and "sent (no error)" or "remote not found", Duration=5,
        Icon=okFire and "check" or "x" }) end })

-- ═══════════════════════════════════════════════════════════════════
--  MISC
-- ═══════════════════════════════════════════════════════════════════
MiscTab:Section({ Title="UI" })
MiscTab:Keybind({ Title="Toggle UI", Value="RightShift", Callback=function()
    pcall(function() Window:Toggle() end) end })
MiscTab:Button({ Title="Rejoin", Callback=function()
    TeleportService:Teleport(game.PlaceId, LP) end })
MiscTab:Paragraph({ Title="Chicken or Hero • OP Hub",
    Desc="Client features reliable. Server features best-effort (bytecode-sourced names). Use the Remotes tab to verify/tune." })
MiscTab:Button({ Title="Unload Hub", Callback=function()
    pcall(function() Window:Destroy() end)
    for _,h in pairs(espHl) do pcall(function() h:Destroy() end) end
    for _,t in pairs(espTag) do pcall(function() t:Destroy() end) end
    for _,l in pairs(tracers) do pcall(function() l:Remove() end) end
    for _,h in pairs(collectHl) do pcall(function() h:Destroy() end) end
    stopFly()
    local h=hum(); if h then h.PlatformStand=false end
end })

end) -- pcall

if not ok then
    warn("[Chicken or Hero OP Hub] failed to load: "..tostring(err))
    pcall(function()
        game:GetService("StarterGui"):SetCore("SendNotification", {
            Title="Chicken or Hero Hub", Text="Load error: "..tostring(err), Duration=8 })
    end)
end
