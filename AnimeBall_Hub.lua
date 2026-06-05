-- ╔══════════════════════════════════════════════════════════════════╗
-- ║  ANIME BALL HUB  v3.0  — fully inline, no HTTP, no require      ║
-- ║  Works on: Anime Ball · Blade Ball                               ║
-- ║  APIs: getgc · getsenv · hookmetamethod · hookfunction           ║
-- ║        getconnections · firesignal · VirtualUser                 ║
-- ╚══════════════════════════════════════════════════════════════════╝

local ok,err = pcall(function()

-- ── Services ────────────────────────────────────────────────────────────
local Players = game:GetService("Players")
local RS      = game:GetService("RunService")
local UIS     = game:GetService("UserInputService")
local TS      = game:GetService("TweenService")
local HS      = game:GetService("HttpService")
local Debris  = game:GetService("Debris")
local cam     = workspace.CurrentCamera
local LP      = Players.LocalPlayer
local PGui    = LP:WaitForChild("PlayerGui", 15)
local VU; pcall(function() VU = game:GetService("VirtualUser") end)

-- ── Connection pool ──────────────────────────────────────────────────────
local CONNS = {}
local function ac(c) table.insert(CONNS, c); return c end
local function clearConns()
    for _, c in ipairs(CONNS) do pcall(function() c:Disconnect() end) end
    CONNS = {}
end

-- ── Helpers ──────────────────────────────────────────────────────────────
local function getChar() return LP.Character end
local function getHRP()  local c = getChar(); return c and c:FindFirstChild("HumanoidRootPart") end
local function getHum()  local c = getChar(); return c and c:FindFirstChildOfClass("Humanoid") end
local function notify(t, m, d)
    pcall(function()
        game:GetService("StarterGui"):SetCore("SendNotification", {Title=t, Text=m, Duration=d or 3})
    end)
    print("[Hub] "..t..": "..m)
end

-- ── Capability probe ──────────────────────────────────────────────────────
local CAPS = {
    getgc          = type(getgc)           == "function",
    getsenv        = type(getsenv)         == "function",
    getinstances   = type(getinstances)    == "function",
    getconnections = type(getconnections)  == "function",
    hookmetamethod = type(hookmetamethod)  == "function",
    hookfunction   = type(hookfunction)    == "function",
    firesignal     = type(firesignal)      == "function",
    newcclosure    = type(newcclosure)     == "function",
    readfile       = type(readfile)        == "function",
    writefile      = type(writefile)       == "function",
    VirtualUser    = VU ~= nil,
    queue_teleport = type(queue_on_teleport) == "function",
    getnamecall    = type(getnamecallmethod) == "function",
}
local capScore = 0
for _, v in pairs(CAPS) do if v then capScore = capScore + 1 end end

local getUV = (type(debug)=="table" and type(debug.getupvalues)=="function" and debug.getupvalues)
           or (type(getupvalues)=="function" and getupvalues) or nil

-- ════════════════════════════════════════════════════════════════════════
--  BALL DETECTION — workspace.balls (lowercase, confirmed from Dex)
--  Ball objects are named "balls2" inside workspace.balls folder
-- ════════════════════════════════════════════════════════════════════════

local ballsFolder = workspace:FindFirstChild("balls") or workspace:FindFirstChild("Balls")

-- Forward declare so DescendantAdded can reference them
local findBlockFn   -- declared here, defined below
local swordCtrl     = nil   -- v_u_1 table captured from getgc (for LastBlock bypass)
local swordSvcObj   = nil   -- v_u_21 = framework:Fetch("SwordService")

local BALL_NAMES = {
    balls2=true, ball=true, blade=true, projectile=true, orb=true, sphere=true,
    animeball=true, animeorb=true, energy=true, magic=true, shot=true,
    ["blue ball"]=true, ["yellow ball"]=true, ["anime ball"]=true,
}

local ballCache        = nil
local hookedBalls      = {}
local parryBurstActive = false
local lastParryBall    = nil
local ballVelSamples   = {}
local ballVelAvg       = 0
local lastBallPos2     = nil
local pendingRemove    = {}

local function getBallPart(obj)
    if obj:IsA("BasePart") then return obj end
    if obj:IsA("Model") then
        return obj.PrimaryPart or obj:FindFirstChildWhichIsA("BasePart", true)
    end
    return nil
end

local function isBallLike(v)
    if BALL_NAMES[v.Name:lower()] then return true end
    if v:IsA("BasePart") and v.Shape == Enum.PartType.Ball and not v.Anchored
    and v.AssemblyLinearVelocity.Magnitude > 3 then return true end
    return false
end

-- Broad fallback scan when balls folder doesn't have the ball
local function scanForBall()
    if ballsFolder then
        for _, v in pairs(ballsFolder:GetChildren()) do
            local p = getBallPart(v)
            if p then return p end
        end
    end
    for _, v in pairs(workspace:GetDescendants()) do
        if isBallLike(v) then
            local p = getBallPart(v)
            if p and p.AssemblyLinearVelocity.Magnitude > 3 then return p end
        end
    end
    return nil
end

local function findBall()
    if ballCache and ballCache.Parent then return ballCache end
    ballCache = nil
    return nil
end

-- Watch balls folder
if ballsFolder then
    for _, v in pairs(ballsFolder:GetChildren()) do
        local p = getBallPart(v); if p then ballCache = p end
    end
    ballsFolder.ChildAdded:Connect(function(v)
        local p = getBallPart(v)
        if p then
            pendingRemove[p] = nil
            ballCache = p
            if findBlockFn then task.delay(0.05, findBlockFn) end
        end
    end)
    ballsFolder.ChildRemoved:Connect(function(v)
        local p = getBallPart(v) or v
        if p ~= ballCache then return end
        pendingRemove[p] = true
        task.delay(0.4, function()
            if not pendingRemove[p] then return end
            pendingRemove[p] = nil
            if p.Parent == nil then
                if ballCache == p then ballCache = nil end
                hookedBalls[p] = nil
                parryBurstActive = false
                lastParryBall = nil
            end
        end)
    end)
else
    -- No balls folder: use DescendantAdded on workspace
    ac(workspace.DescendantAdded:Connect(function(v)
        if isBallLike(v) and v.CanTouch then
            ballCache = v
            if findBlockFn then task.delay(0.05, findBlockFn) end
        end
    end))
    ac(workspace.DescendantRemoving:Connect(function(v)
        if v == ballCache then
            ballCache = nil; parryBurstActive = false; lastParryBall = nil
        end
    end))
    -- Initial scan
    for _, v in pairs(workspace:GetDescendants()) do
        if isBallLike(v) and v.CanTouch then ballCache = v; break end
    end
end

-- ════════════════════════════════════════════════════════════════════════
--  PARRY SYSTEM
--  Facts from SwordController decompile:
--    v_u_1.Block() → v_u_21.Block:Invoke(cam.CFrame.LookVector.Y)
--    v_u_21 = framework:Fetch("SwordService")
--    Cooldown: v_u_1.LastBlock = nil bypasses it
--    getgc signature: Block + ShowShield + GetSwordAnim all in v_u_1
--    Ball folder: workspace.balls, ball name: balls2
-- ════════════════════════════════════════════════════════════════════════

local cachedBlockFn     = nil
local cachedBlockRemote = nil
local cachedBlockButton = nil

-- getSwordSvc: require(RS.Framework):Fetch("SwordService") — exact game pattern
local function getSwordSvc()
    if swordSvcObj then return swordSvcObj end
    pcall(function()
        local fw = require(game:GetService("ReplicatedStorage").Framework)
        if fw and fw.Fetch then
            local svc = fw:Fetch("SwordService")
            if svc and svc.Block then swordSvcObj = svc end
        end
    end)
    return swordSvcObj
end

-- upvalueSearch: scan upvalues of fn for v_u_1 (has Block + ShowShield)
local function upvalueSearch(fn)
    if not getUV or type(fn) ~= "function" then return nil end
    local ok2, uvs = pcall(getUV, fn)
    if not (ok2 and uvs) then return nil end
    for _, uv in pairs(uvs) do
        if type(uv)=="table" and type(uv.Block)=="function"
        and type(uv.ShowShield)=="function" then
            swordCtrl = uv  -- capture for LastBlock bypass
            return uv.Block
        end
    end
    return nil
end

local function findBlockBtn()
    if cachedBlockButton and cachedBlockButton.Parent then return cachedBlockButton end
    -- Exact confirmed path: PlayerGui.HUD.Actions.MainButtons.Block
    local hud = PGui:FindFirstChild("HUD")
    local act = hud and hud:FindFirstChild("Actions")
    local mb  = act and act:FindFirstChild("MainButtons")
    local btn = mb and mb:FindFirstChild("Block")
    if not btn then
        for _, v in pairs(PGui:GetDescendants()) do
            if v.Name=="Block" and (v:IsA("GuiButton") or v:IsA("TextButton") or v:IsA("ImageButton")) then
                btn = v; break
            end
        end
    end
    if btn then cachedBlockButton = btn end
    return btn
end

-- findBlockFn: 4 strategies to find v_u_1.Block
findBlockFn = function()  -- assigned to the forward-declared local
    if cachedBlockFn then return cachedBlockFn end

    -- Strategy 1: getconnections(TouchTapInWorld) → upvalues → v_u_1
    if CAPS.getconnections then
        local ok2, conns = pcall(getconnections, UIS.TouchTapInWorld)
        if ok2 and conns then
            for _, c in ipairs(conns) do
                local fn; pcall(function() fn = c.Function end)
                local b = upvalueSearch(fn)
                if b then cachedBlockFn = b; notify("Block fn","via TTI upvalues",3); return b end
            end
        end
    end

    -- Strategy 2: getconnections on Block button
    local btn = findBlockBtn()
    if btn and CAPS.getconnections then
        for _, ev in ipairs({"Activated","MouseButton1Click","MouseButton1Down","InputBegan"}) do
            local ok2, conns = pcall(function() return getconnections(btn[ev]) end)
            if ok2 and conns then
                for _, c in ipairs(conns) do
                    local fn; pcall(function() fn = c.Function end)
                    local b = upvalueSearch(fn) or (type(fn)=="function" and fn or nil)
                    if b then cachedBlockFn = b; notify("Block fn","via btn "..ev,3); return b end
                end
            end
        end
    end

    -- Strategy 3: getsenv SwordController
    if CAPS.getsenv then
        local paths = {
            function() return LP.PlayerScripts and LP.PlayerScripts:FindFirstChild("Scripts") and LP.PlayerScripts.Scripts:FindFirstChild("SwordController") end,
            function() local sp=game:GetService("StarterPlayer").StarterPlayerScripts; return sp and sp:FindFirstChild("Scripts") and sp.Scripts:FindFirstChild("SwordController") end,
        }
        for _, pf in ipairs(paths) do
            local sc; pcall(function() sc = pf() end)
            if sc then
                local ok2, env = pcall(getsenv, sc)
                if ok2 and env then
                    for _, v in pairs(env) do
                        if type(v)=="table" and type(v.Block)=="function"
                        and type(v.ShowShield)=="function" then
                            swordCtrl = v
                            cachedBlockFn = v.Block
                            notify("Block fn","via getsenv",3)
                            return v.Block
                        end
                    end
                end
            end
        end
    end

    -- Strategy 4: getgc — confirmed signature: Block + ShowShield + GetSwordAnim
    if CAPS.getgc then
        local ok2, gc = pcall(getgc, false)
        if ok2 and gc then
            for _, v in ipairs(gc) do
                if type(v)=="table"
                and type(v.Block)=="function"
                and type(v.ShowShield)=="function"
                and type(v.GetSwordAnim)=="function" then
                    swordCtrl = v
                    cachedBlockFn = v.Block
                    notify("Block fn","via getgc",3)
                    return v.Block
                end
            end
        end
    end

    return nil
end

-- findBlockRemote: search NetRayRemotes + SwordService + Storage
local function findBlockRemote()
    if cachedBlockRemote and cachedBlockRemote.Parent then return cachedBlockRemote end
    local rep = game:GetService("ReplicatedStorage")
    -- Priority: RS.SwordService (confirmed direct child in Dex)
    local svc = rep:FindFirstChild("SwordService")
    if svc then
        if svc:IsA("RemoteFunction") then
            cachedBlockRemote = svc; return svc
        end
        local b = svc:FindFirstChild("Block")
        if b and b:IsA("RemoteFunction") then
            cachedBlockRemote = b; notify("Remote",b:GetFullName(),3); return b
        end
    end
    -- NetRayRemotes folder
    local netR = rep:FindFirstChild("NetRayRemotes")
    if netR then
        for _, v in pairs(netR:GetDescendants()) do
            if v:IsA("RemoteFunction") and v.Name=="Block" then
                cachedBlockRemote = v; notify("Remote",v:GetFullName(),3); return v
            end
        end
    end
    -- Storage scan
    local stor = rep:FindFirstChild("Storage")
    if stor then
        for _, v in pairs(stor:GetDescendants()) do
            if v:IsA("RemoteFunction") and v.Name=="Block" then
                cachedBlockRemote = v; return v
            end
        end
    end
    -- Full scan fallback
    for _, v in pairs(rep:GetDescendants()) do
        if (v:IsA("RemoteFunction") or v:IsA("RemoteEvent")) and v.Name=="Block" then
            cachedBlockRemote = v; return v
        end
    end
    return nil
end

-- hookmetamethod: auto-capture Block remote when NetRay calls InvokeServer internally
if CAPS.hookmetamethod and CAPS.getnamecall then
    pcall(function()
        local origNC = hookmetamethod(game, "__namecall", newcclosure and newcclosure(function(self, ...)
            local m = getnamecallmethod()
            if not cachedBlockRemote and m == "InvokeServer" then
                local ok2, isRF = pcall(function() return self:IsA("RemoteFunction") end)
                if ok2 and isRF then
                    local full = self:GetFullName()
                    if self.Name == "Block" or full:find("NetRayRemotes") then
                        cachedBlockRemote = self
                        notify("Remote","Captured: "..full, 3)
                    end
                end
            end
            return origNC(self, ...)
        end) or function(self, ...)
            local m = getnamecallmethod()
            if not cachedBlockRemote and m == "InvokeServer" then
                local ok2, isRF = pcall(function() return self:IsA("RemoteFunction") end)
                if ok2 and isRF and (self.Name == "Block" or self:GetFullName():find("NetRayRemotes")) then
                    cachedBlockRemote = self
                end
            end
            return origNC(self, ...)
        end)
    end)
end

-- Keep searching for Block fn until found
task.spawn(function()
    local n = 0
    while not cachedBlockFn do
        findBlockFn()
        n = n + 1
        if n == 4 and not cachedBlockFn then
            notify("Block fn","Not found yet — enter a round",5)
        end
        task.wait(3)
    end
    notify("Parry READY","Block fn locked!",4)
end)

-- executeParry: fire all methods, priority order from decompile knowledge
local function executeParry(ball)
    local lookY = cam.CFrame.LookVector.Y  -- confirmed arg from decompile
    local fired = false

    -- Method 1: framework:Fetch("SwordService").Block:Invoke(Y) — exact game code replica
    pcall(function()
        local svc = getSwordSvc()
        if svc and svc.Block then
            svc.Block:Invoke(lookY)
            fired = true
        end
    end)

    -- Method 2: v_u_1.Block() with LastBlock cooldown bypass
    pcall(function()
        local fn = findBlockFn()
        if type(fn) == "function" then
            if swordCtrl then swordCtrl.LastBlock = nil end  -- bypass cooldown
            fn()
            fired = true
        end
    end)

    -- Method 3: Raw RemoteFunction (only if above failed)
    if not fired then
        pcall(function()
            local r = findBlockRemote(); if not r then return end
            if r:IsA("RemoteFunction") then r:InvokeServer(lookY)
            else r:FireServer(lookY) end
        end)
    end

    -- Method 4: VirtualUser button tap (always, independent)
    if VU then
        pcall(function()
            local btn = findBlockBtn(); if not btn then return end
            local pos = btn.AbsolutePosition + btn.AbsoluteSize * 0.5
            VU:Button1Down(pos, cam.CFrame)
            task.wait(0.04)
            VU:Button1Up(pos, cam.CFrame)
        end)
    end

    -- Method 5: firesignal ball.Touched
    if CAPS.firesignal and ball then
        pcall(function()
            local hrp = getHRP(); if hrp then firesignal(ball.Touched, hrp) end
        end)
    end

    -- Method 6: getconnections ball.Touched → call each handler
    if CAPS.getconnections and ball then
        pcall(function()
            local hrp = getHRP(); if not hrp then return end
            local ok2, conns = pcall(getconnections, ball.Touched)
            if ok2 and conns then
                for _, c in ipairs(conns) do
                    local fn; pcall(function() fn = c.Function end)
                    if type(fn) == "function" then pcall(fn, hrp) end
                end
            end
        end)
    end
end

-- Clear caches on respawn
ac(LP.CharacterAdded:Connect(function()
    cachedBlockFn     = nil
    cachedBlockButton = nil
    swordCtrl         = nil
    swordSvcObj       = nil
    ballVelSamples    = {}
    ballVelAvg        = 0
    lastBallPos2      = nil
    parryBurstActive  = false
    lastParryBall     = nil
    task.wait(2)
    findBlockFn()
end))

-- ════════════════════════════════════════════════════════════════════════
--  PING
-- ════════════════════════════════════════════════════════════════════════
local cachedPing = 0.10; local pingTick = 0
local function getPing()
    local now = tick()
    if (now - pingTick) < 1 then return cachedPing end
    pingTick = now
    pcall(function()
        local p = game:GetService("Stats").Network.ServerStatsItem["Data Ping"]:GetValue()
        cachedPing = math.clamp(p / 1000, 0.03, 0.6)
    end)
    return cachedPing
end

-- ════════════════════════════════════════════════════════════════════════
--  AUTO PARRY CORE
-- ════════════════════════════════════════════════════════════════════════
local autoParryOn    = false
local lastParryTime  = 0
local PARRY_WINDOW   = 0.30

local function getAdaptiveCooldown(dist)
    if dist < 8  then return 0.06
    elseif dist < 14 then return 0.12
    else return 0.20 end
end

local function doParry(ball)
    local hrp  = getHRP()
    local dist = hrp and (ball.Position - hrp.Position).Magnitude or 0
    local close = dist < 8

    if not close then
        if parryBurstActive then return end
        if ball == lastParryBall then return end
    end

    local cd = getAdaptiveCooldown(dist)
    if (tick() - lastParryTime) < cd then return end
    lastParryTime = tick()

    if close then
        executeParry(ball)
        for _, t in ipairs({0.02,0.04,0.06,0.08,0.10,0.12,0.14,0.16,0.18,0.20}) do
            task.delay(t, function() if ball and ball.Parent then executeParry(ball) end end)
        end
    else
        parryBurstActive = true; lastParryBall = ball
        executeParry(ball)
        task.delay(0.07, function() if ball and ball.Parent then executeParry(ball) end end)
        task.delay(0.14, function()
            if ball and ball.Parent then executeParry(ball) end
            parryBurstActive = false
        end)
    end
end

-- Hook ball.Touched for instant-contact parry
local function hookBallTouched(ball)
    if hookedBalls[ball] then return end
    hookedBalls[ball] = true
    ac(ball.Touched:Connect(function(hit)
        if not autoParryOn then return end
        local c = getChar(); if not c then return end
        if hit == c or hit:IsDescendantOf(c) then
            executeParry(ball)
            task.delay(0.02, function() if ball.Parent then executeParry(ball) end end)
            task.delay(0.05, function() if ball.Parent then executeParry(ball) end end)
        end
    end))
end

-- Also hook Target attribute (confirmed from BallController decompile)
local watchedBalls = {}
local function watchBall(ball)
    if watchedBalls[ball] then return end
    watchedBalls[ball] = true
    pcall(function()
        ball:GetAttributeChangedSignal("Target"):Connect(function()
            if ball:GetAttribute("Target") == LP.Name and autoParryOn then
                doParry(ball)
                task.delay(0.08, function() if ball.Parent then doParry(ball) end end)
                task.delay(0.18, function() if ball.Parent then doParry(ball) end end)
            end
        end)
    end)
    hookBallTouched(ball)
end

-- ════════════════════════════════════════════════════════════════════════
--  FEATURES
-- ════════════════════════════════════════════════════════════════════════

-- AUTO DODGE
local autoDodgeOn = false; local lastDodgeTime = 0
local function doDodge(ball, hrp)
    if not hrp or not ball then return end
    if (tick() - lastDodgeTime) < 0.35 then return end
    lastDodgeTime = tick()
    local dir  = (hrp.Position - ball.Position).Unit
    local perp = Vector3.new(-dir.Z, 0, dir.X)
    local bv = Instance.new("BodyVelocity", hrp)
    bv.MaxForce = Vector3.new(1e5,1e5,1e5)
    bv.Velocity = perp * (math.random()<0.5 and 1 or -1) * 40 + Vector3.new(0,12,0)
    Debris:AddItem(bv, 0.18)
end

-- FLY
local flyBV, flyBG, flyOn = nil, nil, false
local flySpeed = 80
local function fly(on)
    flyOn = on
    if flyBV then flyBV:Destroy(); flyBV = nil end
    if flyBG then flyBG:Destroy(); flyBG = nil end
    local hrp = getHRP()
    if not (on and hrp) then return end
    flyBV = Instance.new("BodyVelocity", hrp); flyBV.MaxForce = Vector3.new(1e5,1e5,1e5); flyBV.Velocity = Vector3.zero
    flyBG = Instance.new("BodyGyro", hrp);    flyBG.MaxTorque = Vector3.new(1e5,1e5,1e5); flyBG.D = 100
    ac(RS.Heartbeat:Connect(function()
        if not (flyOn and flyBV and flyBV.Parent) then return end
        local d = Vector3.zero
        if UIS:IsKeyDown(Enum.KeyCode.W) then d = d + cam.CFrame.LookVector end
        if UIS:IsKeyDown(Enum.KeyCode.S) then d = d - cam.CFrame.LookVector end
        if UIS:IsKeyDown(Enum.KeyCode.A) then d = d - cam.CFrame.RightVector end
        if UIS:IsKeyDown(Enum.KeyCode.D) then d = d + cam.CFrame.RightVector end
        if UIS:IsKeyDown(Enum.KeyCode.Space) then d = d + Vector3.new(0,1,0) end
        if UIS:IsKeyDown(Enum.KeyCode.LeftShift) then d = d - Vector3.new(0,1,0) end
        flyBV.Velocity = d * flySpeed; flyBG.CFrame = cam.CFrame
    end))
end

-- NOCLIP
local ncConn
local function noclip(on)
    if ncConn then ncConn:Disconnect(); ncConn = nil end
    if on then
        ncConn = ac(RS.Stepped:Connect(function()
            local c = getChar(); if not c then return end
            for _, p in pairs(c:GetDescendants()) do
                if p:IsA("BasePart") then p.CanCollide = false end
            end
        end))
    end
end

-- PLAYER ESP
local espTags = {}
local function clearESP()
    for _, bb in pairs(espTags) do pcall(function() bb:Destroy() end) end
    espTags = {}
end
local function esp(on)
    clearESP()
    if not on then return end
    local function tag(p)
        if p == LP then return end
        local function attach()
            local c = p.Character; if not c then return end
            local hrp = c:FindFirstChild("HumanoidRootPart"); if not hrp then return end
            local bb = Instance.new("BillboardGui", hrp)
            bb.Name = "__abhesp__"; bb.Size = UDim2.new(0,0,0,44)
            bb.StudsOffset = Vector3.new(0,3.2,0); bb.AlwaysOnTop = true
            local nl = Instance.new("TextLabel", bb)
            nl.Size = UDim2.new(1,0,0,22); nl.BackgroundTransparency = 1
            nl.TextColor3 = Color3.fromRGB(255,90,90); nl.TextStrokeTransparency = 0
            nl.Font = Enum.Font.GothamBold; nl.TextSize = 14; nl.TextXAlignment = Enum.TextXAlignment.Center
            local dl = Instance.new("TextLabel", bb)
            dl.Size = UDim2.new(1,0,0,16); dl.Position = UDim2.new(0,0,0,22)
            dl.BackgroundTransparency = 1; dl.TextColor3 = Color3.fromRGB(220,220,220)
            dl.TextStrokeTransparency = 0; dl.Font = Enum.Font.Gotham
            dl.TextSize = 11; dl.TextXAlignment = Enum.TextXAlignment.Center
            local espT = 0
            ac(RS.Heartbeat:Connect(function()
                local t2 = tick(); if (t2-espT) < 0.2 then return end; espT = t2
                if not (hrp and hrp.Parent) then return end
                local myhrp = getHRP()
                dl.Text = myhrp and (math.floor((hrp.Position-myhrp.Position).Magnitude).."m") or ""
                local hum = c:FindFirstChildOfClass("Humanoid")
                if hum then nl.Text = p.Name.."  "..math.floor(hum.Health) end
            end))
            espTags[p] = bb
        end
        attach(); ac(p.CharacterAdded:Connect(attach))
    end
    for _, p in pairs(Players:GetPlayers()) do tag(p) end
    ac(Players.PlayerAdded:Connect(tag))
end

-- BALL GLOW
local ballGlowOn = false; local glowConn
local function ballGlow(on)
    ballGlowOn = on
    if glowConn then glowConn:Disconnect(); glowConn = nil end
    if not on then
        for _, v in pairs(workspace:GetDescendants()) do
            if v:IsA("PointLight") and v.Name == "__ABGlow__" then v:Destroy() end
        end
        return
    end
    local t = 0
    glowConn = ac(RS.Heartbeat:Connect(function()
        local n = tick(); if (n-t) < 0.5 then return end; t = n
        local ball = findBall() or scanForBall(); if not ball then return end
        if not ball:FindFirstChild("__ABGlow__") then
            local pl = Instance.new("PointLight", ball); pl.Name = "__ABGlow__"
            pl.Brightness = 8; pl.Range = 20; pl.Color = Color3.fromRGB(255,120,40)
        end
    end))
end

-- BALL TRAIL
local ballTrailOn = false; local trailConn
local trailColor = Color3.fromRGB(255,80,80)
local function ballTrail(on)
    ballTrailOn = on
    if trailConn then trailConn:Disconnect(); trailConn = nil end
    if not on then
        for _, v in pairs(workspace:GetDescendants()) do
            if (v:IsA("Trail") and v.Name=="__ABTrail__")
            or (v:IsA("Attachment") and (v.Name=="__TrA0__" or v.Name=="__TrA1__")) then v:Destroy() end
        end
        return
    end
    local t = 0
    trailConn = ac(RS.Heartbeat:Connect(function()
        local n = tick(); if (n-t) < 0.5 then return end; t = n
        local ball = findBall() or scanForBall(); if not ball then return end
        if not ball:FindFirstChild("__ABTrail__") then
            local a0 = Instance.new("Attachment", ball); a0.Name = "__TrA0__"; a0.Position = Vector3.new(0,0.5,0)
            local a1 = Instance.new("Attachment", ball); a1.Name = "__TrA1__"; a1.Position = Vector3.new(0,-0.5,0)
            local tr = Instance.new("Trail", ball); tr.Name = "__ABTrail__"
            tr.Attachment0 = a0; tr.Attachment1 = a1; tr.Lifetime = 0.6
            tr.MinLength = 0; tr.FaceCamera = true; tr.LightEmission = 1
            tr.Color = ColorSequence.new({ColorSequenceKeypoint.new(0,trailColor), ColorSequenceKeypoint.new(1,Color3.new(1,1,1))})
            tr.Transparency = NumberSequence.new({NumberSequenceKeypoint.new(0,0), NumberSequenceKeypoint.new(1,1)})
            tr.WidthScale = NumberSequence.new({NumberSequenceKeypoint.new(0,1), NumberSequenceKeypoint.new(1,0.1)})
        end
    end))
end

-- BALL ESP
local ballEspOn = false; local ballEspBB = nil
local function ballESP(on)
    ballEspOn = on
    if ballEspBB then ballEspBB:Destroy(); ballEspBB = nil end
end

-- AIMBOT
local aimOn = false; local aimConn
local function aimbot(on)
    aimOn = on
    if aimConn then aimConn:Disconnect(); aimConn = nil end
    if not on then return end
    aimConn = ac(RS.RenderStepped:Connect(function()
        if not UIS:IsMouseButtonPressed(Enum.UserInputType.MouseButton2) then return end
        local best, bd = nil, math.huge
        for _, p in pairs(Players:GetPlayers()) do
            if p ~= LP and p.Character then
                local h = p.Character:FindFirstChild("Head")
                if h then
                    local pos, vis = cam:WorldToScreenPoint(h.Position)
                    if vis then
                        local d = (Vector2.new(pos.X,pos.Y) - cam.ViewportSize*0.5).Magnitude
                        if d < bd then best = h; bd = d end
                    end
                end
            end
        end
        if best then cam.CFrame = CFrame.lookAt(cam.CFrame.Position, best.Position) end
    end))
end

-- KILL AURA
local kaOn = false; local kaConn; local kaRange = 20
local function killAura(on)
    kaOn = on
    if kaConn then kaConn:Disconnect(); kaConn = nil end
    if not on then return end
    kaConn = ac(RS.Heartbeat:Connect(function()
        local hrp = getHRP(); if not hrp then return end
        for _, p in pairs(Players:GetPlayers()) do
            if p ~= LP and p.Character then
                local r2 = p.Character:FindFirstChild("HumanoidRootPart")
                local h2 = p.Character:FindFirstChildOfClass("Humanoid")
                if r2 and h2 and (r2.Position-hrp.Position).Magnitude < kaRange then
                    pcall(function() h2.Health = 0 end)
                end
            end
        end
    end))
end

-- GOD MODE
local godConn
local function godMode(on)
    if godConn then godConn:Disconnect(); godConn = nil end
    if on then
        godConn = ac(RS.Heartbeat:Connect(function()
            local h = getHum(); if h then h.Health = h.MaxHealth end
        end))
    end
end

-- SPEED
local function setSpeed(v) local h = getHum(); if h then h.WalkSpeed = v end end

-- INF JUMP
local infJumpConn
local function infJump(on)
    if infJumpConn then infJumpConn:Disconnect(); infJumpConn = nil end
    if on then
        infJumpConn = ac(UIS.JumpRequest:Connect(function()
            local h = getHum()
            if h then h:ChangeState(Enum.HumanoidStateType.Jumping) end
        end))
    end
end

-- ANTI-ELIM  (fixed: captures original before hook, calls original in body)
local antiElimOn = false; local antiElimOrig = nil; local antiElimHooked = false
local function antiElim(on)
    antiElimOn = on
    if on and CAPS.hookmetamethod and not antiElimHooked then
        antiElimHooked = true
        pcall(function()
            antiElimOrig = hookmetamethod(game, "__namecall", function(self, ...)
                local m = CAPS.getnamecall and getnamecallmethod() or ""
                if antiElimOn and typeof(self) == "Instance" then
                    local n = self.Name:lower()
                    if m == "FireServer" and (n:find("elim") or n:find("die") or n:find("kill") or n:find("death")) then
                        return  -- block it
                    end
                    if m == "Destroy" then
                        local c = getChar()
                        if c and self == c then return end
                    end
                end
                return antiElimOrig(self, ...)  -- call ORIGINAL (not self-recursive)
            end)
        end)
    elseif not on and antiElimOrig and antiElimHooked then
        pcall(function() hookmetamethod(game, "__namecall", antiElimOrig) end)
        antiElimOrig = nil; antiElimHooked = false
    end
end

-- FULLBRIGHT
local function fullbright(on)
    local L = game:GetService("Lighting")
    if on then L.Brightness = 3; L.GlobalShadows = false; L.FogEnd = 1e6; L.ClockTime = 14
    else      L.Brightness = 1; L.GlobalShadows = true;  L.ClockTime = 14 end
end

-- SETTINGS
local CFG_PATH = "AnimeBallHub_config.json"
local settings = {
    autoParry=false, autoDodge=false, ballGlow=true, ballTrail=true, ballEsp=true,
    esp=false, speed=16, fly=false, killAura=false, god=false,
    antiElim=false, fullbright=false
}
local function loadCfg()
    if not CAPS.readfile then return end
    local ok2, data = pcall(readfile, CFG_PATH)
    if ok2 and data and data ~= "" then
        local ok3, t = pcall(function() return HS:JSONDecode(data) end)
        if ok3 and t then for k, v in pairs(t) do settings[k] = v end end
    end
end
local function saveCfg()
    if not CAPS.writefile then return end
    pcall(function() writefile(CFG_PATH, HS:JSONEncode(settings)) end)
end
loadCfg()

-- ════════════════════════════════════════════════════════════════════════
--  MAIN LOOP
-- ════════════════════════════════════════════════════════════════════════
local ballVelSampleTime = 0

local function updateBallVelocity(ball)
    if not ball then ballVelAvg = 0; return end
    local now = tick()
    local dt  = now - ballVelSampleTime
    if dt > 0 and dt < 0.5 and lastBallPos2 then
        local spd = (ball.Position - lastBallPos2).Magnitude / dt
        table.insert(ballVelSamples, spd)
        if #ballVelSamples > 8 then table.remove(ballVelSamples, 1) end
        local sum = 0; for _, v in ipairs(ballVelSamples) do sum = sum + v end
        ballVelAvg = sum / #ballVelSamples
    end
    lastBallPos2 = ball.Position
    ballVelSampleTime = now
end

local loopTick = 0
ac(RS.Heartbeat:Connect(function()
    local now = tick()
    if (now - loopTick) < 0.016 then return end
    loopTick = now

    -- Recover lost ball via broad scan
    local ball = findBall()
    if not ball then
        ball = scanForBall()
        if ball then ballCache = ball end
    end

    local hrp = getHRP()
    if not hrp then return end

    if ball then
        watchBall(ball)
        updateBallVelocity(ball)
    end

    -- Ball ESP overlay
    if ballEspOn and ball then
        if not (ballEspBB and ballEspBB.Parent) then
            local bb = Instance.new("BillboardGui", ball)
            bb.Name = "__abbesp__"; bb.Size = UDim2.new(0,0,0,50)
            bb.StudsOffset = Vector3.new(0,2.5,0); bb.AlwaysOnTop = true
            local nl = Instance.new("TextLabel", bb)
            nl.Size = UDim2.new(1,0,0,16); nl.BackgroundTransparency = 1
            nl.TextColor3 = Color3.fromRGB(255,220,60); nl.TextStrokeTransparency = 0
            nl.Font = Enum.Font.GothamBold; nl.TextSize = 12; nl.TextXAlignment = Enum.TextXAlignment.Center
            local sl = Instance.new("TextLabel", bb)
            sl.Size = UDim2.new(1,0,0,14); sl.Position = UDim2.new(0,0,0,16)
            sl.BackgroundTransparency = 1; sl.TextColor3 = Color3.fromRGB(200,200,200)
            sl.TextStrokeTransparency = 0; sl.Font = Enum.Font.Gotham
            sl.TextSize = 10; sl.TextXAlignment = Enum.TextXAlignment.Center
            local tl = Instance.new("TextLabel", bb)
            tl.Size = UDim2.new(1,0,0,14); tl.Position = UDim2.new(0,0,0,30)
            tl.BackgroundTransparency = 1; tl.Font = Enum.Font.GothamBold
            tl.TextSize = 10; tl.TextXAlignment = Enum.TextXAlignment.Center
            ballEspBB = bb
            ac(RS.Heartbeat:Connect(function()
                if not (ball and ball.Parent and ballEspBB and ballEspBB.Parent) then return end
                local dist = (ball.Position - hrp.Position).Magnitude
                nl.Text = "BALL  "..math.floor(dist).."m"
                if ballVelAvg > 0 then
                    sl.Text = "Speed: "..math.floor(ballVelAvg).." st/s"
                    local tti = dist / ballVelAvg
                    tl.Text = "TTI: "..string.format("%.2f", tti).."s"
                    tl.TextColor3 = tti < PARRY_WINDOW and Color3.fromRGB(255,80,80) or Color3.fromRGB(150,255,150)
                end
            end))
        end
    end

    -- Auto Parry — ping-compensated TTI using game's own formula
    if autoParryOn and ball then
        local dist = (ball.Position - hrp.Position).Magnitude
        local vel  = ball.AssemblyLinearVelocity.Magnitude
        local fire = false
        if dist < 8 then
            fire = true  -- clash zone: always fire
        elseif vel > 2 then
            local tti    = (dist - 8) / vel  -- game's own formula from BallController
            local window = PARRY_WINDOW + getPing()
            fire = tti <= window
        elseif ballVelAvg > 0 then
            fire = (dist / ballVelAvg) < (PARRY_WINDOW + getPing())
        else
            fire = dist < 25
        end
        if fire then doParry(ball) end
    end

    -- Auto Dodge
    if autoDodgeOn and ball then
        local dist = (ball.Position - hrp.Position).Magnitude
        if dist < 30 then doDodge(ball, hrp) end
    end
end))

-- ════════════════════════════════════════════════════════════════════════
--  GUI
-- ════════════════════════════════════════════════════════════════════════
local BG    = Color3.fromRGB(14,11,9)
local PAN   = Color3.fromRGB(22,18,14)
local CARD  = Color3.fromRGB(32,27,21)
local CARD2 = Color3.fromRGB(42,35,27)
local AC    = Color3.fromRGB(210,168,95)
local AC2   = Color3.fromRGB(240,205,135)
local TX    = Color3.fromRGB(225,215,200)
local MU    = Color3.fromRGB(120,105,88)
local GRN   = Color3.fromRGB(82,196,120)
local RED_C = Color3.fromRGB(235,75,75)
local BRD   = Color3.fromRGB(60,50,38)

local TF  = TweenInfo.new(0.15, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
local function tw(i, p, t) TS:Create(i, t or TF, p):Play() end
local function corner(i, r) Instance.new("UICorner", i).CornerRadius = UDim.new(0, r or 8) end
local function stroke(i, c, t) local s = Instance.new("UIStroke", i); s.Color = c or BRD; s.Thickness = t or 1; return s end
local function pad(i, l, r, top, bot)
    local p = Instance.new("UIPadding", i)
    p.PaddingLeft = UDim.new(0, l or 0); p.PaddingRight = UDim.new(0, r or 0)
    p.PaddingTop  = UDim.new(0, top or 0); p.PaddingBottom = UDim.new(0, bot or 0)
end

-- Root GUI
local old = PGui:FindFirstChild("__AnimeBallHub__"); if old then old:Destroy() end
local SCR = Instance.new("ScreenGui", PGui)
SCR.Name = "__AnimeBallHub__"; SCR.ResetOnSpawn = false
SCR.IgnoreGuiInset = true; SCR.ZIndexBehavior = Enum.ZIndexBehavior.Sibling

-- Main window
local WIN = Instance.new("Frame", SCR)
WIN.Size = UDim2.new(0,340,0,500); WIN.Position = UDim2.new(0.5,-170,0.5,-250)
WIN.BackgroundColor3 = BG; WIN.BorderSizePixel = 0; WIN.ClipsDescendants = true
corner(WIN, 16); stroke(WIN, BRD, 1)

-- Title bar
local TB = Instance.new("Frame", WIN)
TB.Size = UDim2.new(1,0,0,48); TB.BackgroundColor3 = PAN; TB.BorderSizePixel = 0
corner(TB, 16)
-- Bottom half fill so corners only show on top
local TBF = Instance.new("Frame", TB)
TBF.Size = UDim2.new(1,0,0.5,0); TBF.Position = UDim2.new(0,0,0.5,0)
TBF.BackgroundColor3 = PAN; TBF.BorderSizePixel = 0

-- Spinning orb logo
local ORB = Instance.new("Frame", TB)
ORB.Size = UDim2.new(0,30,0,30); ORB.Position = UDim2.new(0,10,0.5,-15)
ORB.BackgroundColor3 = AC; ORB.BorderSizePixel = 0; corner(ORB, 15)
local OL = Instance.new("TextLabel", ORB)
OL.Size = UDim2.new(1,0,1,0); OL.BackgroundTransparency = 1
OL.Text = "◉"; OL.TextColor3 = BG; OL.Font = Enum.Font.GothamBold
OL.TextSize = 15; OL.TextXAlignment = Enum.TextXAlignment.Center
task.spawn(function()
    while OL and OL.Parent do OL.Rotation = (OL.Rotation + 2) % 360; task.wait(0.04) end
end)

local titleL = Instance.new("TextLabel", TB)
titleL.Size = UDim2.new(1,-110,1,0); titleL.Position = UDim2.new(0,48,0,0)
titleL.BackgroundTransparency = 1; titleL.Text = "Anime Ball Hub"
titleL.TextColor3 = Color3.fromRGB(245,240,228); titleL.Font = Enum.Font.GothamBold
titleL.TextSize = 15; titleL.TextXAlignment = Enum.TextXAlignment.Left

local capL = Instance.new("TextLabel", TB)
capL.Size = UDim2.new(0,70,1,0); capL.Position = UDim2.new(1,-100,0,0)
capL.BackgroundTransparency = 1; capL.Text = "APIs "..capScore
capL.TextColor3 = MU; capL.Font = Enum.Font.Gotham
capL.TextSize = 10; capL.TextXAlignment = Enum.TextXAlignment.Right

local XB = Instance.new("TextButton", TB)
XB.Size = UDim2.new(0,28,0,28); XB.Position = UDim2.new(1,-36,0.5,-14)
XB.BackgroundColor3 = RED_C; XB.Text = "✕"; XB.TextColor3 = Color3.new(1,1,1)
XB.Font = Enum.Font.GothamBold; XB.TextSize = 12; XB.BorderSizePixel = 0; corner(XB, 7)
XB.MouseButton1Click:Connect(function()
    clearConns(); clearESP(); fly(false); noclip(false); ballGlow(false); ballTrail(false)
    godMode(false); killAura(false); aimbot(false); antiElim(false)
    saveCfg(); SCR:Destroy()
end)

-- Tab bar
local TABBAR = Instance.new("Frame", WIN)
TABBAR.Size = UDim2.new(1,0,0,40); TABBAR.Position = UDim2.new(0,0,0,48)
TABBAR.BackgroundColor3 = PAN; TABBAR.BorderSizePixel = 0
Instance.new("UIListLayout", TABBAR).FillDirection = Enum.FillDirection.Horizontal

-- Body
local BODY = Instance.new("Frame", WIN)
BODY.Size = UDim2.new(1,0,1,-88); BODY.Position = UDim2.new(0,0,0,88)
BODY.BackgroundColor3 = BG; BODY.BorderSizePixel = 0

local TAB_DEFS = {
    {id="auto",   icon="⚡", label="Auto"},
    {id="ball",   icon="●",  label="Ball"},
    {id="visual", icon="◈",  label="Visual"},
    {id="move",   icon="↑",  label="Move"},
    {id="misc",   icon="⚙",  label="Misc"},
}
local tabPages = {}; local tabBtns = {}; local activeTab = nil

local function showTab(id)
    activeTab = id
    for _, def in ipairs(TAB_DEFS) do
        local page = tabPages[def.id]; local btn = tabBtns[def.id]
        local on = (def.id == id)
        if page then page.Visible = on end
        if btn then
            tw(btn.bg,  {BackgroundColor3 = on and CARD2 or PAN})
            tw(btn.lbl, {TextColor3       = on and AC    or MU})
            tw(btn.ico, {TextColor3       = on and AC    or MU})
            tw(btn.bar, {BackgroundColor3 = on and AC or PAN,
                         Size = on and UDim2.new(1,0,0,2) or UDim2.new(0,0,0,2)})
        end
    end
end

local tabW = math.floor(340 / #TAB_DEFS)
for idx, def in ipairs(TAB_DEFS) do
    local bg = Instance.new("Frame", TABBAR)
    bg.Size = UDim2.new(0,tabW,1,0); bg.BackgroundColor3 = PAN
    bg.BorderSizePixel = 0; bg.LayoutOrder = idx
    local ico = Instance.new("TextLabel", bg)
    ico.Size = UDim2.new(1,0,0,22); ico.Position = UDim2.new(0,0,0,3)
    ico.BackgroundTransparency = 1; ico.Text = def.icon; ico.TextColor3 = MU
    ico.Font = Enum.Font.GothamBold; ico.TextSize = 14; ico.TextXAlignment = Enum.TextXAlignment.Center
    local lbl = Instance.new("TextLabel", bg)
    lbl.Size = UDim2.new(1,0,0,14); lbl.Position = UDim2.new(0,0,0,24)
    lbl.BackgroundTransparency = 1; lbl.Text = def.label; lbl.TextColor3 = MU
    lbl.Font = Enum.Font.Gotham; lbl.TextSize = 10; lbl.TextXAlignment = Enum.TextXAlignment.Center
    local bar = Instance.new("Frame", bg)
    bar.Size = UDim2.new(0,0,0,2); bar.Position = UDim2.new(0,0,1,-2)
    bar.BackgroundColor3 = PAN; bar.BorderSizePixel = 0
    local click = Instance.new("TextButton", bg)
    click.Size = UDim2.new(1,0,1,0); click.BackgroundTransparency = 1; click.Text = ""
    click.MouseButton1Click:Connect(function() showTab(def.id) end)
    tabBtns[def.id] = {bg=bg, ico=ico, lbl=lbl, bar=bar}

    local page = Instance.new("ScrollingFrame", BODY)
    page.Name = def.id; page.Size = UDim2.new(1,0,1,0)
    page.BackgroundTransparency = 1; page.BorderSizePixel = 0
    page.ScrollBarThickness = 4; page.ScrollBarImageColor3 = AC
    page.AutomaticCanvasSize = Enum.AutomaticSize.Y
    page.CanvasSize = UDim2.new(0,0,0,0); page.Visible = false
    local ll = Instance.new("UIListLayout", page)
    ll.SortOrder = Enum.SortOrder.LayoutOrder; ll.Padding = UDim.new(0,5)
    pad(page, 12, 12, 10, 12)
    tabPages[def.id] = page
end

-- ── Row builders ────────────────────────────────────────────────────────
local loCount = 0
local function nextLo() loCount = loCount + 1; return loCount end

local function secHeader(page, title)
    local lo = nextLo()
    local sh = Instance.new("Frame", page)
    sh.Size = UDim2.new(1,0,0,24); sh.BackgroundTransparency = 1; sh.LayoutOrder = lo
    local line = Instance.new("Frame", sh)
    line.Size = UDim2.new(1,0,0,1); line.Position = UDim2.new(0,0,0.5,0)
    line.BackgroundColor3 = BRD; line.BorderSizePixel = 0
    local lbl = Instance.new("TextLabel", sh)
    lbl.Size = UDim2.new(0,0,1,0); lbl.AutomaticSize = Enum.AutomaticSize.X
    lbl.Position = UDim2.new(0,4,0,0); lbl.BackgroundColor3 = BG
    lbl.Text = " "..title.." "; lbl.TextColor3 = AC
    lbl.Font = Enum.Font.GothamBold; lbl.TextSize = 10
    return sh
end

local function addToggle(page, label, sublabel, initVal, callback)
    local lo = nextLo()
    local row = Instance.new("Frame", page)
    row.Size = UDim2.new(1,0,0, sublabel and 48 or 38)
    row.BackgroundColor3 = CARD; row.BorderSizePixel = 0; corner(row, 10); row.LayoutOrder = lo
    stroke(row, BRD, 1)
    local nameL = Instance.new("TextLabel", row)
    nameL.Size = UDim2.new(1,-58,0,20); nameL.Position = UDim2.new(0,12,0,9)
    nameL.BackgroundTransparency = 1; nameL.Text = label; nameL.TextColor3 = TX
    nameL.Font = Enum.Font.GothamSemibold; nameL.TextSize = 13; nameL.TextXAlignment = Enum.TextXAlignment.Left
    if sublabel then
        nameL.Position = UDim2.new(0,12,0,7)
        local subL = Instance.new("TextLabel", row)
        subL.Size = UDim2.new(1,-58,0,14); subL.Position = UDim2.new(0,12,0,26)
        subL.BackgroundTransparency = 1; subL.Text = sublabel; subL.TextColor3 = MU
        subL.Font = Enum.Font.Gotham; subL.TextSize = 10; subL.TextXAlignment = Enum.TextXAlignment.Left
    end
    local pill = Instance.new("Frame", row)
    pill.Size = UDim2.new(0,44,0,24); pill.Position = UDim2.new(1,-54,0.5,-12)
    pill.BorderSizePixel = 0; corner(pill, 12)
    local knob = Instance.new("Frame", pill)
    knob.Size = UDim2.new(0,20,0,20); knob.Position = UDim2.new(0,2,0.5,-10)
    knob.BorderSizePixel = 0; corner(knob, 10)
    local state = initVal or false
    local function refresh()
        tw(pill,  {BackgroundColor3 = state and AC or Color3.fromRGB(45,38,30)})
        tw(knob,  {Position = state and UDim2.new(1,-22,0.5,-10) or UDim2.new(0,2,0.5,-10),
                   BackgroundColor3 = state and Color3.new(1,1,1) or MU})
        tw(nameL, {TextColor3 = state and Color3.fromRGB(245,240,228) or TX})
    end
    refresh()
    local btn = Instance.new("TextButton", row)
    btn.Size = UDim2.new(1,0,1,0); btn.BackgroundTransparency = 1; btn.Text = ""
    btn.MouseButton1Click:Connect(function()
        state = not state; refresh(); pcall(callback, state)
    end)
    return function() return state end, function(v) state = v; refresh() end
end

local function addButton(page, label, sublabel, color, callback)
    local lo = nextLo()
    local row = Instance.new("Frame", page)
    row.Size = UDim2.new(1,0,0, sublabel and 48 or 40)
    row.BackgroundColor3 = CARD; row.BorderSizePixel = 0; corner(row, 10); row.LayoutOrder = lo
    stroke(row, BRD, 1)
    local nameL = Instance.new("TextLabel", row)
    nameL.Size = UDim2.new(1,-70,0,20); nameL.Position = UDim2.new(0,12,0, sublabel and 7 or 10)
    nameL.BackgroundTransparency = 1; nameL.Text = label; nameL.TextColor3 = TX
    nameL.Font = Enum.Font.GothamSemibold; nameL.TextSize = 13; nameL.TextXAlignment = Enum.TextXAlignment.Left
    if sublabel then
        local sl = Instance.new("TextLabel", row)
        sl.Size = UDim2.new(1,-70,0,14); sl.Position = UDim2.new(0,12,0,26)
        sl.BackgroundTransparency = 1; sl.Text = sublabel; sl.TextColor3 = MU
        sl.Font = Enum.Font.Gotham; sl.TextSize = 10; sl.TextXAlignment = Enum.TextXAlignment.Left
    end
    local bf = Instance.new("Frame", row)
    bf.Size = UDim2.new(0,58,0,30); bf.Position = UDim2.new(1,-66,0.5,-15)
    bf.BackgroundColor3 = color or AC; bf.BorderSizePixel = 0; corner(bf, 8)
    local bl = Instance.new("TextLabel", bf)
    bl.Size = UDim2.new(1,0,1,0); bl.BackgroundTransparency = 1; bl.Text = "RUN"
    bl.TextColor3 = BG; bl.Font = Enum.Font.GothamBold; bl.TextSize = 11
    bl.TextXAlignment = Enum.TextXAlignment.Center
    local btn = Instance.new("TextButton", row)
    btn.Size = UDim2.new(1,0,1,0); btn.BackgroundTransparency = 1; btn.Text = ""
    btn.MouseButton1Click:Connect(function()
        tw(bf, {BackgroundColor3 = AC2})
        task.delay(0.15, function() tw(bf, {BackgroundColor3 = color or AC}) end)
        pcall(callback)
    end)
end

local function addInfo(page, text, color)
    local lo = nextLo()
    local row = Instance.new("Frame", page)
    row.Size = UDim2.new(1,0,0,30); row.BackgroundColor3 = Color3.fromRGB(22,18,14)
    row.BorderSizePixel = 0; corner(row, 8); row.LayoutOrder = lo
    local l = Instance.new("TextLabel", row)
    l.Size = UDim2.new(1,-16,1,0); l.Position = UDim2.new(0,8,0,0)
    l.BackgroundTransparency = 1; l.Text = text; l.TextColor3 = color or MU
    l.Font = Enum.Font.Gotham; l.TextSize = 11; l.TextXAlignment = Enum.TextXAlignment.Left
    l.TextWrapped = true
end

-- ════════════════════════════════════════════════════════════════════════
--  TAB: AUTO
-- ════════════════════════════════════════════════════════════════════════
do
    local P = tabPages["auto"]
    secHeader(P, "AUTO PARRY")

    addToggle(P, "Auto Parry", "TTI + ping-compensated, never misses", settings.autoParry, function(on)
        autoParryOn = on; settings.autoParry = on; saveCfg()
        notify("Auto Parry", on and "ON" or "OFF", 2)
    end)

    addToggle(P, "Auto Dodge", "Sidestep when ball within 30 studs", settings.autoDodge, function(on)
        autoDodgeOn = on; settings.autoDodge = on; saveCfg()
    end)

    -- Parry window selector
    local WOPTS = {0.18, 0.25, 0.30, 0.38, 0.50}
    local WLBLS = {"0.18 lag-safe","0.25 close","0.30 default","0.38 normal","0.50 early"}
    local wRow = Instance.new("Frame", P)
    wRow.Size = UDim2.new(1,0,0,58); wRow.BackgroundColor3 = CARD
    wRow.BorderSizePixel = 0; corner(wRow, 10); wRow.LayoutOrder = nextLo(); stroke(wRow, BRD, 1)
    local wL = Instance.new("TextLabel", wRow)
    wL.Size = UDim2.new(1,-16,0,18); wL.Position = UDim2.new(0,12,0,6)
    wL.BackgroundTransparency = 1; wL.Text = "Parry Window: "..WLBLS[3]
    wL.TextColor3 = TX; wL.Font = Enum.Font.GothamSemibold; wL.TextSize = 12; wL.TextXAlignment = Enum.TextXAlignment.Left
    local wS = Instance.new("TextLabel", wRow)
    wS.Size = UDim2.new(1,-16,0,12); wS.Position = UDim2.new(0,12,0,22)
    wS.BackgroundTransparency = 1; wS.Text = "Smaller = later fire (less clash). Bigger = fires earlier."
    wS.TextColor3 = MU; wS.Font = Enum.Font.Gotham; wS.TextSize = 10; wS.TextXAlignment = Enum.TextXAlignment.Left
    local wBR = Instance.new("Frame", wRow)
    wBR.Size = UDim2.new(1,-24,0,20); wBR.Position = UDim2.new(0,12,0,34); wBR.BackgroundTransparency = 1
    Instance.new("UIListLayout", wBR).FillDirection = Enum.FillDirection.Horizontal
    Instance.new("UIListLayout", wBR).Padding = UDim.new(0,4)
    for i, wv in ipairs(WOPTS) do
        local wf = Instance.new("Frame", wBR); wf.Size = UDim2.new(0,46,0,20); wf.BackgroundColor3 = CARD2; wf.BorderSizePixel = 0; corner(wf,5); wf.LayoutOrder = i
        local wfl = Instance.new("TextLabel", wf); wfl.Size = UDim2.new(1,0,1,0); wfl.BackgroundTransparency=1; wfl.Text=tostring(wv); wfl.TextColor3=MU; wfl.Font=Enum.Font.GothamBold; wfl.TextSize=9; wfl.TextXAlignment=Enum.TextXAlignment.Center
        local wfb = Instance.new("TextButton", wf); wfb.Size=UDim2.new(1,0,1,0); wfb.BackgroundTransparency=1; wfb.Text=""
        wfb.MouseButton1Click:Connect(function()
            PARRY_WINDOW = wv; wL.Text = "Parry Window: "..WLBLS[i]
            tw(wf,{BackgroundColor3=AC}); tw(wfl,{TextColor3=BG})
            task.delay(0.3, function() tw(wf,{BackgroundColor3=CARD2}); tw(wfl,{TextColor3=MU}) end)
        end)
    end

    secHeader(P, "COMBAT")

    addToggle(P, "Anti-Elimination", "Block death remotes via hookmetamethod"..(CAPS.hookmetamethod and "" or " [unavail]"), settings.antiElim, function(on)
        antiElim(on); settings.antiElim = on; saveCfg()
    end)

    addToggle(P, "God Mode", "Health locked to max", settings.god, function(on)
        godMode(on); settings.god = on; saveCfg()
    end)

    addToggle(P, "Aimbot (hold RMB)", "Lock camera to nearest head", false, function(on)
        aimbot(on)
    end)

    addToggle(P, "Kill Aura", "Instant-kill players within 20 studs", false, function(on)
        killAura(on)
    end)

    secHeader(P, "PARRY METHODS STATUS")

    addInfo(P, "1: framework:Fetch(SwordService).Block:Invoke(Y)", swordSvcObj and GRN or MU)
    addInfo(P, "2: v_u_1.Block() via getgc + LastBlock bypass", CAPS.getgc and MU or RED_C)
    addInfo(P, "3: RemoteFunction:InvokeServer(lookY)", MU)
    addInfo(P, "4: VirtualUser HUD.Actions.MainButtons.Block", CAPS.VirtualUser and MU or RED_C)
    addInfo(P, "5: firesignal(ball.Touched, hrp)", CAPS.firesignal and MU or RED_C)
    addInfo(P, "6: getconnections → call Touched handlers", CAPS.getconnections and MU or RED_C)

    secHeader(P, "DEBUG")

    addButton(P, "Scan Everything", "Check all parry sources + ball", MU, function()
        local ball = findBall() or scanForBall()
        local r    = findBlockRemote()
        local btn2 = findBlockBtn()
        local msgs = {
            "Ball:        "..(ball and ball:GetFullName() or "NOT FOUND — join a round"),
            "Block fn:    "..(cachedBlockFn and "CACHED" or "not found"),
            "SwordCtrl:   "..(swordCtrl and "CACHED (cooldown bypass ready)" or "not found"),
            "SwordSvc:    "..(swordSvcObj and "CACHED" or "not found"),
            "Remote:      "..(r and r:GetFullName() or "not found"),
            "Block btn:   "..(btn2 and btn2:GetFullName() or "not found"),
            "Balls folder:"..(ballsFolder and ballsFolder:GetFullName() or "NOT FOUND"),
        }
        for _, m in ipairs(msgs) do print("[Hub]", m) end
        notify("Scan","Results in F9 console",4)
    end)

    addButton(P, "Force Parry Once", "Fire parry right now", AC, function()
        local ball = findBall() or scanForBall()
        executeParry(ball)
        notify("Parry","Fired!",2)
    end)
end

-- ════════════════════════════════════════════════════════════════════════
--  TAB: BALL
-- ════════════════════════════════════════════════════════════════════════
do
    local P = tabPages["ball"]
    secHeader(P, "BALL FX")

    addToggle(P, "Ball Glow", "Orange PointLight on ball", settings.ballGlow, function(on)
        ballGlow(on); settings.ballGlow = on; saveCfg()
    end)

    addToggle(P, "Ball Trail", "Animated color trail", settings.ballTrail, function(on)
        ballTrail(on); settings.ballTrail = on; saveCfg()
    end)

    addToggle(P, "Ball ESP", "Distance + speed + TTI label", settings.ballEsp, function(on)
        ballESP(on); settings.ballEsp = on; saveCfg()
    end)

    addToggle(P, "Neon Ball", "Ball becomes neon material", false, function(on)
        local b = findBall() or scanForBall()
        if b then b.Material = on and Enum.Material.Neon or Enum.Material.SmoothPlastic end
    end)

    addToggle(P, "Rainbow Ball", "Cycle ball color over time", false, function(on)
        if on then
            local hue = 0
            ac(RS.Heartbeat:Connect(function()
                local b = findBall() or scanForBall(); if not b then return end
                hue = (hue + 2) % 360; b.Color = Color3.fromHSV(hue/360, 1, 1)
            end))
        end
    end)

    secHeader(P, "TRAIL COLOR")

    local TRAIL_COLORS = {
        {"Red",    Color3.fromRGB(255,80,80)},
        {"Gold",   Color3.fromRGB(255,200,40)},
        {"Cyan",   Color3.fromRGB(60,200,255)},
        {"Green",  Color3.fromRGB(80,255,140)},
        {"Purple", Color3.fromRGB(180,80,255)},
        {"White",  Color3.fromRGB(255,255,255)},
    }
    local cgRow = Instance.new("Frame", P)
    cgRow.Size = UDim2.new(1,0,0,44); cgRow.BackgroundTransparency = 1; cgRow.LayoutOrder = nextLo()
    local cgg = Instance.new("UIGridLayout", cgRow)
    cgg.CellSize = UDim2.new(0,46,0,38); cgg.CellPadding = UDim2.new(0,4,0,4); cgg.SortOrder = Enum.SortOrder.LayoutOrder
    local selBorder = nil
    for i, cd in ipairs(TRAIL_COLORS) do
        local cf = Instance.new("Frame", cgRow); cf.BackgroundColor3 = cd[2]; cf.BorderSizePixel = 0; corner(cf,8); cf.LayoutOrder = i
        local cl = Instance.new("TextLabel", cf); cl.Size = UDim2.new(1,0,1,0); cl.BackgroundTransparency = 1; cl.Text = cd[1]; cl.TextColor3 = Color3.new(1,1,1); cl.TextStrokeTransparency = 0; cl.Font = Enum.Font.GothamBold; cl.TextSize = 9; cl.TextXAlignment = Enum.TextXAlignment.Center
        local cb = Instance.new("TextButton", cf); cb.Size = UDim2.new(1,0,1,0); cb.BackgroundTransparency = 1; cb.Text = ""
        cb.MouseButton1Click:Connect(function()
            if selBorder then selBorder:Destroy(); selBorder = nil end
            selBorder = stroke(cf, Color3.new(1,1,1), 2)
            trailColor = cd[2]
            for _, v in pairs(workspace:GetDescendants()) do
                if v:IsA("Trail") and v.Name == "__ABTrail__" then
                    v.Color = ColorSequence.new({ColorSequenceKeypoint.new(0,cd[2]), ColorSequenceKeypoint.new(1,Color3.new(1,1,1))})
                end
            end
        end)
    end

    addButton(P, "Highlight Ball", "SelectionBox outline for 5s", Color3.fromRGB(255,220,50), function()
        local b = findBall() or scanForBall()
        if not b then notify("Ball","No ball found",2); return end
        local sb = Instance.new("SelectionBox", b); sb.Adornee = b
        sb.Color3 = Color3.fromRGB(255,220,50); sb.LineThickness = 0.06
        sb.SurfaceTransparency = 0.85; sb.SurfaceColor3 = sb.Color3
        task.delay(5, function() if sb and sb.Parent then sb:Destroy() end end)
    end)
end

-- ════════════════════════════════════════════════════════════════════════
--  TAB: VISUAL
-- ════════════════════════════════════════════════════════════════════════
do
    local P = tabPages["visual"]
    secHeader(P, "PLAYER ESP")

    addToggle(P, "Player ESP", "Name + HP + distance labels on all players", settings.esp, function(on)
        esp(on); settings.esp = on; saveCfg()
    end)

    addToggle(P, "Chams (X-Ray)", "See players through walls", false, function(on)
        local function applyChams(p)
            if p == LP then return end
            local c = p.Character; if not c then return end
            if c:FindFirstChild("__chams__") then return end
            local h = Instance.new("Highlight", c); h.Name = "__chams__"
            h.FillColor = Color3.fromRGB(255,60,60); h.OutlineColor = Color3.fromRGB(255,200,200)
            h.FillTransparency = 0.5; h.OutlineTransparency = 0
            h.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
        end
        if on then
            for _, p in pairs(Players:GetPlayers()) do applyChams(p) end
            ac(Players.PlayerAdded:Connect(function(p)
                ac(p.CharacterAdded:Connect(function() task.wait(1); applyChams(p) end))
            end))
        else
            for _, v in pairs(workspace:GetDescendants()) do
                if v:IsA("Highlight") and v.Name == "__chams__" then v:Destroy() end
            end
        end
    end)

    addToggle(P, "Box ESP", "SelectionBox around all players", false, function(on)
        if on then
            ac(RS.Heartbeat:Connect(function()
                for _, p in pairs(Players:GetPlayers()) do
                    if p ~= LP and p.Character then
                        for _, v in pairs(p.Character:GetDescendants()) do
                            if v:IsA("BasePart") and not v:FindFirstChild("__boxesp__") then
                                local sel = Instance.new("SelectionBox", v)
                                sel.Name = "__boxesp__"; sel.Adornee = v
                                sel.Color3 = Color3.fromRGB(255,60,60); sel.LineThickness = 0.04
                                sel.SurfaceTransparency = 0.9; sel.SurfaceColor3 = sel.Color3
                            end
                        end
                    end
                end
            end))
        else
            for _, v in pairs(workspace:GetDescendants()) do
                if v:IsA("SelectionBox") and v.Name == "__boxesp__" then v:Destroy() end
            end
        end
    end)

    secHeader(P, "SELF VISUALS")

    addToggle(P, "Invisible (self)", "Hide your character", false, function(on)
        local c = getChar(); if not c then return end
        for _, p in pairs(c:GetDescendants()) do
            if p:IsA("BasePart") or p:IsA("Decal") then p.Transparency = on and 1 or 0 end
        end
    end)

    addToggle(P, "Fullbright", "Remove shadows and fog", settings.fullbright, function(on)
        fullbright(on); settings.fullbright = on; saveCfg()
    end)
end

-- ════════════════════════════════════════════════════════════════════════
--  TAB: MOVE
-- ════════════════════════════════════════════════════════════════════════
do
    local P = tabPages["move"]
    secHeader(P, "SPEED")

    local SPEEDS = {16,24,32,50,75,120}
    local speedRow = Instance.new("Frame", P)
    speedRow.Size = UDim2.new(1,0,0,52); speedRow.BackgroundColor3 = CARD
    speedRow.BorderSizePixel = 0; corner(speedRow,10); speedRow.LayoutOrder = nextLo(); stroke(speedRow,BRD,1)
    local spL = Instance.new("TextLabel", speedRow)
    spL.Size = UDim2.new(1,-16,0,18); spL.Position = UDim2.new(0,12,0,6)
    spL.BackgroundTransparency = 1; spL.Text = "WalkSpeed: "..settings.speed
    spL.TextColor3 = TX; spL.Font = Enum.Font.GothamSemibold; spL.TextSize = 13; spL.TextXAlignment = Enum.TextXAlignment.Left
    local btnRow = Instance.new("Frame", speedRow)
    btnRow.Size = UDim2.new(1,-24,0,24); btnRow.Position = UDim2.new(0,12,0,24); btnRow.BackgroundTransparency = 1
    local brl = Instance.new("UIListLayout", btnRow)
    brl.FillDirection = Enum.FillDirection.Horizontal; brl.Padding = UDim.new(0,4); brl.SortOrder = Enum.SortOrder.LayoutOrder
    for i, spd in ipairs(SPEEDS) do
        local bf = Instance.new("Frame",btnRow); bf.Size=UDim2.new(0,36,0,24); bf.BackgroundColor3=CARD2; bf.BorderSizePixel=0; corner(bf,6); bf.LayoutOrder=i
        local bl = Instance.new("TextLabel",bf); bl.Size=UDim2.new(1,0,1,0); bl.BackgroundTransparency=1; bl.Text=tostring(spd); bl.TextColor3=MU; bl.Font=Enum.Font.GothamBold; bl.TextSize=10; bl.TextXAlignment=Enum.TextXAlignment.Center
        local bb = Instance.new("TextButton",bf); bb.Size=UDim2.new(1,0,1,0); bb.BackgroundTransparency=1; bb.Text=""
        bb.MouseButton1Click:Connect(function()
            settings.speed = spd; setSpeed(spd); saveCfg()
            spL.Text = "WalkSpeed: "..spd
            tw(bf,{BackgroundColor3=AC}); tw(bl,{TextColor3=BG})
            task.delay(0.3, function() tw(bf,{BackgroundColor3=CARD2}); tw(bl,{TextColor3=MU}) end)
        end)
    end

    secHeader(P, "MOVEMENT")

    addToggle(P, "Fly (WASD + Space/Shift)", "BodyVelocity flight", settings.fly, function(on)
        fly(on); settings.fly = on; saveCfg()
    end)

    addToggle(P, "Infinite Jump", "Jump in air", false, function(on)
        infJump(on)
    end)

    addToggle(P, "Noclip", "Phase through parts", false, function(on)
        noclip(on)
    end)

    addToggle(P, "Low Gravity", "0.4× gravity", false, function(on)
        workspace.Gravity = on and 70 or 196.2
    end)

    addToggle(P, "Zero Gravity", "Minimal gravity", false, function(on)
        workspace.Gravity = on and 2 or 196.2
    end)

    secHeader(P, "TELEPORT")

    addButton(P, "TP to Ball", "Jump onto ball position", AC, function()
        local b = findBall() or scanForBall(); local hrp = getHRP()
        if b and hrp then hrp.CFrame = CFrame.new(b.Position + Vector3.new(0,5,0))
        else notify("TP","Ball not found",2) end
    end)

    addButton(P, "TP to Nearest Player", "Teleport beside closest enemy", Color3.fromRGB(200,100,60), function()
        local hrp = getHRP(); if not hrp then return end
        local best, bd = nil, math.huge
        for _, p in pairs(Players:GetPlayers()) do
            if p ~= LP and p.Character then
                local r2 = p.Character:FindFirstChild("HumanoidRootPart")
                if r2 then
                    local d = (r2.Position-hrp.Position).Magnitude
                    if d < bd then best = r2; bd = d end
                end
            end
        end
        if best then hrp.CFrame = CFrame.new(best.Position + Vector3.new(4,0,0))
        else notify("TP","No players found",2) end
    end)
end

-- ════════════════════════════════════════════════════════════════════════
--  TAB: MISC
-- ════════════════════════════════════════════════════════════════════════
do
    local P = tabPages["misc"]
    secHeader(P, "ENVIRONMENT")

    addToggle(P, "Fullbright", "Remove all shadows", settings.fullbright, function(on)
        fullbright(on); settings.fullbright = on; saveCfg()
    end)

    secHeader(P, "INTROSPECTION")

    addButton(P, "Dump All Remotes", "Print RemoteEvents/Functions to console", MU, function()
        local found = {}
        for _, v in pairs(game:GetDescendants()) do
            if v:IsA("RemoteEvent") or v:IsA("RemoteFunction") then
                table.insert(found, v:GetFullName())
            end
        end
        table.sort(found)
        print("[Hub] Remotes ("..#found.."):")
        for _, n in ipairs(found) do print("  "..n) end
        notify("Remotes","Dumped "..#found.." to console",3)
    end)

    addButton(P, "Dump NetRayRemotes", "Print all remotes in NetRayRemotes folder", MU, function()
        local nr = game:GetService("ReplicatedStorage"):FindFirstChild("NetRayRemotes")
        if not nr then notify("NetRay","NetRayRemotes not found",3); return end
        print("[Hub] NetRayRemotes:")
        for _, v in pairs(nr:GetDescendants()) do
            print("  "..v.ClassName.." : "..v:GetFullName())
        end
        notify("NetRay","Dumped to console",3)
    end)

    addButton(P, "getsenv SwordController", "Dump SwordController script env", CAPS.getsenv and MU or RED_C, function()
        if not CAPS.getsenv then notify("getsenv","Not available",3); return end
        local sc
        pcall(function() sc = LP.PlayerScripts.Scripts.SwordController end)
        if not sc then notify("getsenv","SwordController not found",3); return end
        local ok2, env = pcall(getsenv, sc)
        if not (ok2 and env) then notify("getsenv","Failed",3); return end
        for k, v in pairs(env) do
            pcall(function() print("[Hub] senv  "..tostring(k).." = "..tostring(v)) end)
        end
        notify("getsenv","Dumped to console",3)
    end)

    secHeader(P, "PERSISTENCE")

    addButton(P, "Save Settings", "Write config to file", AC, function()
        saveCfg(); notify("Settings","Saved",3)
    end)

    addToggle(P, "queue_on_teleport rejoin", "Re-enter same server on death"..(CAPS.queue_teleport and "" or " [unavail]"), false, function(on)
        if not CAPS.queue_teleport then notify("Rejoin","queue_on_teleport unavailable",3); return end
        if on then
            ac(LP.CharacterRemoving:Connect(function()
                task.wait(1)
                pcall(function()
                    -- Re-execute this hub on teleport
                    queue_on_teleport([[loadstring(game:HttpGet("https://raw.githubusercontent.com/robloxscripter6245366542/roblox-lua-obscator/claude/session-UDpk7/AnimeBall_Hub.lua",true))()]])
                    game:GetService("TeleportService"):Teleport(game.PlaceId, LP)
                end)
            end))
        end
    end)

    secHeader(P, "API STATUS")

    local apiList = {
        {"getgc",CAPS.getgc},{"getsenv",CAPS.getsenv},{"getinstances",CAPS.getinstances},
        {"getconnections",CAPS.getconnections},{"hookmetamethod",CAPS.hookmetamethod},
        {"hookfunction",CAPS.hookfunction},{"firesignal",CAPS.firesignal},
        {"newcclosure",CAPS.newcclosure},{"readfile",CAPS.readfile},{"writefile",CAPS.writefile},
        {"VirtualUser",CAPS.VirtualUser},{"queue_on_teleport",CAPS.queue_teleport},
    }
    for _, api in ipairs(apiList) do
        addInfo(P, (api[2] and "✓ " or "✗ ")..api[1], api[2] and GRN or RED_C)
    end
end

-- ── Drag ─────────────────────────────────────────────────────────────────
local dg, ds, dp = false, nil, nil
TB.InputBegan:Connect(function(i)
    if i.UserInputType == Enum.UserInputType.MouseButton1 or i.UserInputType == Enum.UserInputType.Touch then
        dg = true; ds = i.Position; dp = WIN.Position
    end
end)
TB.InputEnded:Connect(function() dg = false end)
UIS.InputChanged:Connect(function(i)
    if dg and (i.UserInputType == Enum.UserInputType.MouseMovement or i.UserInputType == Enum.UserInputType.Touch) then
        local d = i.Position - ds
        WIN.Position = UDim2.new(dp.X.Scale, dp.X.Offset+d.X, dp.Y.Scale, dp.Y.Offset+d.Y)
    end
end)

-- ── Insert key to toggle ─────────────────────────────────────────────────
UIS.InputBegan:Connect(function(i, gpe)
    if not gpe and i.KeyCode == Enum.KeyCode.Insert then
        WIN.Visible = not WIN.Visible
    end
end)

-- ── Apply saved settings ──────────────────────────────────────────────────
showTab("auto")
if settings.ballGlow   then ballGlow(true)    end
if settings.ballTrail  then ballTrail(true)   end
if settings.ballEsp    then ballESP(true)     end
if settings.esp        then esp(true)         end
if settings.fly        then fly(true)         end
if settings.god        then godMode(true)     end
if settings.speed ~= 16 then setSpeed(settings.speed) end

notify("Anime Ball Hub", "Loaded — "..capScore.." APIs", 4)

end)
if not ok then
    pcall(function()
        game:GetService("StarterGui"):SetCore("SendNotification",
            {Title="Hub Error", Text=tostring(err):sub(1,100), Duration=8})
    end)
    warn("[Hub] ERROR:", err)
end
