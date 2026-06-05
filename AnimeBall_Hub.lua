-- ╔══════════════════════════════════════════════════════════════════════╗
-- ║  ANIME BALL HUB  v4.0  — Best-in-class UI + Unbreakable Parry Core  ║
-- ║  Works on: Anime Ball · Blade Ball                                   ║
-- ║  Executor: Delta (iPad/iOS) + all PC executors                       ║
-- ╚══════════════════════════════════════════════════════════════════════╝

local ok, err = pcall(function()

-- ── Services ─────────────────────────────────────────────────────────────────
local Players   = game:GetService("Players")
local RS        = game:GetService("RunService")
local UIS       = game:GetService("UserInputService")
local TS        = game:GetService("TweenService")
local HS        = game:GetService("HttpService")
local Debris    = game:GetService("Debris")
local Lighting  = game:GetService("Lighting")
local cam       = workspace.CurrentCamera
local LP        = Players.LocalPlayer
local PGui      = LP:WaitForChild("PlayerGui", 15)
local VU; pcall(function() VU = game:GetService("VirtualUser") end)

-- ── Connections ───────────────────────────────────────────────────────────────
local CONNS = {}
local function ac(c) CONNS[#CONNS+1] = c; return c end
local function clearConns()
    for _, c in ipairs(CONNS) do pcall(function() c:Disconnect() end) end
    CONNS = {}
end

-- ── Helpers ───────────────────────────────────────────────────────────────────
local function getChar() return LP.Character end
local function getHRP()  local c = getChar(); return c and c:FindFirstChild("HumanoidRootPart") end
local function getHum()  local c = getChar(); return c and c:FindFirstChildOfClass("Humanoid") end

local function notify(title, text, dur)
    pcall(function()
        game:GetService("StarterGui"):SetCore("SendNotification",
            {Title=title, Text=text, Duration=dur or 3})
    end)
    print("[Hub] "..title..": "..text)
end

-- ── Executor capabilities ─────────────────────────────────────────────────────
local CAPS = {
    getgc          = type(getgc)            == "function",
    getsenv        = type(getsenv)          == "function",
    getinstances   = type(getinstances)     == "function",
    getconnections = type(getconnections)   == "function",
    hookmetamethod = type(hookmetamethod)   == "function",
    hookfunction   = type(hookfunction)     == "function",
    firesignal     = type(firesignal)       == "function",
    newcclosure    = type(newcclosure)      == "function",
    readfile       = type(readfile)         == "function",
    writefile      = type(writefile)        == "function",
    VirtualUser    = VU ~= nil,
    queue_teleport = type(queue_on_teleport) == "function",
    getnamecall    = type(getnamecallmethod) == "function",
}
local capScore = 0
for _, v in pairs(CAPS) do if v then capScore = capScore + 1 end end

local getUV = (type(debug)=="table" and type(debug.getupvalues)=="function" and debug.getupvalues)
           or (type(getupvalues)=="function" and getupvalues) or nil

-- ══════════════════════════════════════════════════════════════════════════════
--  BALL DETECTION
-- ══════════════════════════════════════════════════════════════════════════════
local ballsFolder = workspace:FindFirstChild("balls") or workspace:FindFirstChild("Balls")

local findBlockFn   -- forward declare
local swordCtrl     = nil
local swordSvcObj   = nil

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

-- ── Live stats shared with UI ─────────────────────────────────────────────────
local STATS = {
    ball        = false,
    ballDist    = 0,
    ballSpeed   = 0,
    tti         = 999,
    ping        = 0,
    parryFired  = 0,
    parryOk     = false,
}

local function getBallPart(obj)
    if not obj then return nil end
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

local function scanForBall()
    if ballsFolder then
        for _, v in pairs(ballsFolder:GetChildren()) do
            local p = getBallPart(v); if p then return p end
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
    ballCache = nil; return nil
end

if ballsFolder then
    for _, v in pairs(ballsFolder:GetChildren()) do
        local p = getBallPart(v); if p then ballCache = p end
    end
    ballsFolder.ChildAdded:Connect(function(v)
        local p = getBallPart(v)
        if p then pendingRemove[p]=nil; ballCache=p
            if findBlockFn then task.delay(0.05, findBlockFn) end end
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
                hookedBalls[p] = nil; parryBurstActive = false; lastParryBall = nil
            end
        end)
    end)
else
    ac(workspace.DescendantAdded:Connect(function(v)
        if isBallLike(v) and v.CanTouch then
            ballCache = v
            if findBlockFn then task.delay(0.05, findBlockFn) end
        end
    end))
    ac(workspace.DescendantRemoving:Connect(function(v)
        if v == ballCache then ballCache=nil; parryBurstActive=false; lastParryBall=nil end
    end))
    for _, v in pairs(workspace:GetDescendants()) do
        if isBallLike(v) and v.CanTouch then ballCache = v; break end
    end
end

-- ══════════════════════════════════════════════════════════════════════════════
--  PARRY SYSTEM
-- ══════════════════════════════════════════════════════════════════════════════
local cachedBlockFn     = nil
local cachedBlockRemote = nil
local cachedBlockButton = nil

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

local function upvalueSearch(fn)
    if not getUV or type(fn)~="function" then return nil end
    local ok2, uvs = pcall(getUV, fn)
    if not (ok2 and uvs) then return nil end
    for _, uv in pairs(uvs) do
        if type(uv)=="table" and type(uv.Block)=="function"
        and type(uv.ShowShield)=="function" then
            swordCtrl = uv; return uv.Block
        end
    end
    return nil
end

local function findBlockBtn()
    if cachedBlockButton and cachedBlockButton.Parent then return cachedBlockButton end
    local hud = PGui:FindFirstChild("HUD")
    local act = hud and hud:FindFirstChild("Actions")
    local mb  = act and act:FindFirstChild("MainButtons")
    local btn = mb and mb:FindFirstChild("Block")
    if not btn then
        for _, v in pairs(PGui:GetDescendants()) do
            if v.Name=="Block" and (v:IsA("GuiButton") or v:IsA("TextButton") or v:IsA("ImageButton")) then
                btn=v; break
            end
        end
    end
    if btn then cachedBlockButton = btn end
    return btn
end

findBlockFn = function()
    if cachedBlockFn then return cachedBlockFn end
    -- Strategy 1: getconnections(TouchTapInWorld) → upvalues → v_u_1
    if CAPS.getconnections then
        local ok2, conns = pcall(getconnections, UIS.TouchTapInWorld)
        if ok2 and conns then
            for _, c in ipairs(conns) do
                local fn; pcall(function() fn = c.Function end)
                local b = upvalueSearch(fn)
                if b then cachedBlockFn=b; return b end
            end
        end
    end
    -- Strategy 2: Block button connections
    local btn = findBlockBtn()
    if btn and CAPS.getconnections then
        for _, ev in ipairs({"Activated","MouseButton1Click","MouseButton1Down","InputBegan"}) do
            local ok2, conns = pcall(function() return getconnections(btn[ev]) end)
            if ok2 and conns then
                for _, c in ipairs(conns) do
                    local fn; pcall(function() fn = c.Function end)
                    local b = upvalueSearch(fn) or (type(fn)=="function" and fn or nil)
                    if b then cachedBlockFn=b; return b end
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
                        if type(v)=="table" and type(v.Block)=="function" and type(v.ShowShield)=="function" then
                            swordCtrl=v; cachedBlockFn=v.Block; return v.Block
                        end
                    end
                end
            end
        end
    end
    -- Strategy 4: getgc — Block + ShowShield + GetSwordAnim
    if CAPS.getgc then
        local ok2, gc = pcall(getgc, false)
        if ok2 and gc then
            for _, v in ipairs(gc) do
                if type(v)=="table" and type(v.Block)=="function"
                and type(v.ShowShield)=="function" and type(v.GetSwordAnim)=="function" then
                    swordCtrl=v; cachedBlockFn=v.Block; return v.Block
                end
            end
        end
    end
    return nil
end

local function findBlockRemote()
    if cachedBlockRemote and cachedBlockRemote.Parent then return cachedBlockRemote end
    local rep = game:GetService("ReplicatedStorage")
    local svc = rep:FindFirstChild("SwordService")
    if svc then
        if svc:IsA("RemoteFunction") then cachedBlockRemote=svc; return svc end
        local b = svc:FindFirstChild("Block")
        if b and b:IsA("RemoteFunction") then cachedBlockRemote=b; return b end
    end
    local netR = rep:FindFirstChild("NetRayRemotes")
    if netR then
        for _, v in pairs(netR:GetDescendants()) do
            if v:IsA("RemoteFunction") and v.Name=="Block" then cachedBlockRemote=v; return v end
        end
    end
    for _, v in pairs(rep:GetDescendants()) do
        if (v:IsA("RemoteFunction") or v:IsA("RemoteEvent")) and v.Name=="Block" then
            cachedBlockRemote=v; return v
        end
    end
    return nil
end

-- hookmetamethod auto-capture Block remote
if CAPS.hookmetamethod and CAPS.getnamecall then
    pcall(function()
        local origNC = hookmetamethod(game, "__namecall", newcclosure and newcclosure(function(self, ...)
            local m = getnamecallmethod()
            if not cachedBlockRemote and m=="InvokeServer" then
                local ok2, isRF = pcall(function() return self:IsA("RemoteFunction") end)
                if ok2 and isRF and (self.Name=="Block" or self:GetFullName():find("NetRayRemotes")) then
                    cachedBlockRemote = self
                end
            end
            return origNC(self, ...)
        end) or function(self, ...)
            local m = getnamecallmethod()
            if not cachedBlockRemote and m=="InvokeServer" then
                local ok2, isRF = pcall(function() return self:IsA("RemoteFunction") end)
                if ok2 and isRF and (self.Name=="Block" or self:GetFullName():find("NetRayRemotes")) then
                    cachedBlockRemote = self
                end
            end
            return origNC(self, ...)
        end)
    end)
end

-- Background scan until Block fn found
task.spawn(function()
    local n = 0
    while not cachedBlockFn do
        findBlockFn(); n = n + 1
        if n == 5 and not cachedBlockFn then
            notify("Hub", "Enter a round to lock Block fn", 4)
        end
        task.wait(3)
    end
    notify("READY", "Block fn locked! Parry active.", 3)
    STATS.parryOk = true
end)

local function executeParry(ball)
    local lookY = cam.CFrame.LookVector.Y
    local fired = false
    STATS.parryFired = STATS.parryFired + 1

    -- Method 1: framework:Fetch("SwordService").Block:Invoke(Y)
    pcall(function()
        local svc = getSwordSvc()
        if svc and svc.Block then svc.Block:Invoke(lookY); fired=true end
    end)

    -- Method 2: v_u_1.Block() + LastBlock bypass
    pcall(function()
        local fn = findBlockFn()
        if type(fn)=="function" then
            if swordCtrl then swordCtrl.LastBlock = nil end
            fn(); fired=true
        end
    end)

    -- Method 3: Raw RemoteFunction (if above failed)
    if not fired then
        pcall(function()
            local r = findBlockRemote(); if not r then return end
            if r:IsA("RemoteFunction") then r:InvokeServer(lookY)
            else r:FireServer(lookY) end
        end)
    end

    -- Method 4: VirtualUser
    if VU then
        pcall(function()
            local btn = findBlockBtn(); if not btn then return end
            local pos = btn.AbsolutePosition + btn.AbsoluteSize*0.5
            VU:Button1Down(pos, cam.CFrame)
            task.wait(0.04)
            VU:Button1Up(pos, cam.CFrame)
        end)
    end

    -- Method 5: firesignal
    if CAPS.firesignal and ball then
        pcall(function()
            local hrp = getHRP(); if hrp then firesignal(ball.Touched, hrp) end
        end)
    end

    -- Method 6: getconnections
    if CAPS.getconnections and ball then
        pcall(function()
            local hrp = getHRP(); if not hrp then return end
            local ok2, conns = pcall(getconnections, ball.Touched)
            if ok2 and conns then
                for _, c in ipairs(conns) do
                    local fn; pcall(function() fn = c.Function end)
                    if type(fn)=="function" then pcall(fn, hrp) end
                end
            end
        end)
    end
end

ac(LP.CharacterAdded:Connect(function()
    cachedBlockFn=nil; cachedBlockButton=nil; swordCtrl=nil; swordSvcObj=nil
    ballVelSamples={}; ballVelAvg=0; lastBallPos2=nil
    parryBurstActive=false; lastParryBall=nil
    STATS.parryOk = false
    task.wait(2); findBlockFn()
    STATS.parryOk = cachedBlockFn ~= nil
end))

-- ── Ping ──────────────────────────────────────────────────────────────────────
local cachedPing=0.10; local pingTick=0
local function getPing()
    local now = tick()
    if (now-pingTick) < 1 then return cachedPing end
    pingTick = now
    pcall(function()
        local p = game:GetService("Stats").Network.ServerStatsItem["Data Ping"]:GetValue()
        cachedPing = math.clamp(p/1000, 0.03, 0.6)
        STATS.ping  = math.floor(p)
    end)
    return cachedPing
end

-- ══════════════════════════════════════════════════════════════════════════════
--  AUTO PARRY CORE
-- ══════════════════════════════════════════════════════════════════════════════
local autoParryOn   = false
local lastParryTime = 0
local PARRY_WINDOW  = 0.30

local function getAdaptiveCooldown(dist)
    if dist < 8  then return 0.05
    elseif dist < 14 then return 0.10
    else return 0.18 end
end

local function doParry(ball)
    local hrp  = getHRP(); if not hrp then return end
    local dist = (ball.Position - hrp.Position).Magnitude
    local close = dist < 8
    if not close then
        if parryBurstActive then return end
        if ball == lastParryBall then return end
    end
    local cd = getAdaptiveCooldown(dist)
    if (tick()-lastParryTime) < cd then return end
    lastParryTime = tick()
    if close then
        executeParry(ball)
        for _, t in ipairs({0.02,0.04,0.06,0.08,0.10,0.12,0.14,0.16,0.18,0.20}) do
            task.delay(t, function() if ball and ball.Parent then executeParry(ball) end end)
        end
    else
        parryBurstActive=true; lastParryBall=ball
        executeParry(ball)
        task.delay(0.07, function() if ball and ball.Parent then executeParry(ball) end end)
        task.delay(0.14, function()
            if ball and ball.Parent then executeParry(ball) end
            parryBurstActive=false
        end)
    end
end

local function hookBallTouched(ball)
    if hookedBalls[ball] then return end
    hookedBalls[ball] = true
    ac(ball.Touched:Connect(function(hit)
        if not autoParryOn then return end
        local c = getChar(); if not c then return end
        if hit==c or hit:IsDescendantOf(c) then
            executeParry(ball)
            task.delay(0.02, function() if ball.Parent then executeParry(ball) end end)
            task.delay(0.05, function() if ball.Parent then executeParry(ball) end end)
        end
    end))
end

local watchedBalls = {}
local function watchBall(ball)
    if watchedBalls[ball] then return end
    watchedBalls[ball] = true
    pcall(function()
        ball:GetAttributeChangedSignal("Target"):Connect(function()
            if ball:GetAttribute("Target")==LP.Name and autoParryOn then
                doParry(ball)
                task.delay(0.08, function() if ball.Parent then doParry(ball) end end)
                task.delay(0.18, function() if ball.Parent then doParry(ball) end end)
            end
        end)
    end)
    hookBallTouched(ball)
end

-- ══════════════════════════════════════════════════════════════════════════════
--  FEATURES
-- ══════════════════════════════════════════════════════════════════════════════
local autoDodgeOn = false; local lastDodgeTime = 0
local function doDodge(ball, hrp)
    if not hrp or not ball then return end
    if (tick()-lastDodgeTime) < 0.35 then return end
    lastDodgeTime = tick()
    local dir  = (hrp.Position-ball.Position).Unit
    local perp = Vector3.new(-dir.Z, 0, dir.X)
    local bv = Instance.new("BodyVelocity", hrp)
    bv.MaxForce = Vector3.new(1e5,1e5,1e5)
    bv.Velocity = perp*(math.random()<0.5 and 1 or -1)*40 + Vector3.new(0,12,0)
    Debris:AddItem(bv, 0.18)
end

local flyBV, flyBG, flyOn = nil, nil, false; local flySpeed = 80
local function fly(on)
    flyOn = on
    if flyBV then flyBV:Destroy(); flyBV=nil end
    if flyBG then flyBG:Destroy(); flyBG=nil end
    local hrp = getHRP(); if not (on and hrp) then return end
    flyBV = Instance.new("BodyVelocity", hrp); flyBV.MaxForce = Vector3.new(1e5,1e5,1e5); flyBV.Velocity = Vector3.zero
    flyBG = Instance.new("BodyGyro", hrp);    flyBG.MaxTorque = Vector3.new(1e5,1e5,1e5); flyBG.D = 100
    ac(RS.Heartbeat:Connect(function()
        if not (flyOn and flyBV and flyBV.Parent) then return end
        local d = Vector3.zero
        if UIS:IsKeyDown(Enum.KeyCode.W) then d=d+cam.CFrame.LookVector end
        if UIS:IsKeyDown(Enum.KeyCode.S) then d=d-cam.CFrame.LookVector end
        if UIS:IsKeyDown(Enum.KeyCode.A) then d=d-cam.CFrame.RightVector end
        if UIS:IsKeyDown(Enum.KeyCode.D) then d=d+cam.CFrame.RightVector end
        if UIS:IsKeyDown(Enum.KeyCode.Space) then d=d+Vector3.new(0,1,0) end
        if UIS:IsKeyDown(Enum.KeyCode.LeftShift) then d=d-Vector3.new(0,1,0) end
        flyBV.Velocity = d*flySpeed; flyBG.CFrame = cam.CFrame
    end))
end

local ncConn
local function noclip(on)
    if ncConn then ncConn:Disconnect(); ncConn=nil end
    if on then
        ncConn = ac(RS.Stepped:Connect(function()
            local c = getChar(); if not c then return end
            for _, p in pairs(c:GetDescendants()) do
                if p:IsA("BasePart") then p.CanCollide = false end
            end
        end))
    end
end

local espTags = {}
local function clearESP()
    for _, bb in pairs(espTags) do pcall(function() bb:Destroy() end) end; espTags={}
end
local function esp(on)
    clearESP(); if not on then return end
    local function tag(p)
        if p==LP then return end
        local function attach()
            local c=p.Character; if not c then return end
            local hrp=c:FindFirstChild("HumanoidRootPart"); if not hrp then return end
            local bb=Instance.new("BillboardGui",hrp); bb.Name="__abhesp__"
            bb.Size=UDim2.new(0,0,0,44); bb.StudsOffset=Vector3.new(0,3.2,0); bb.AlwaysOnTop=true
            local nl=Instance.new("TextLabel",bb); nl.Size=UDim2.new(1,0,0,22); nl.BackgroundTransparency=1
            nl.TextColor3=Color3.fromRGB(255,90,90); nl.TextStrokeTransparency=0
            nl.Font=Enum.Font.GothamBold; nl.TextSize=14; nl.TextXAlignment=Enum.TextXAlignment.Center
            local dl=Instance.new("TextLabel",bb); dl.Size=UDim2.new(1,0,0,16); dl.Position=UDim2.new(0,0,0,22)
            dl.BackgroundTransparency=1; dl.TextColor3=Color3.fromRGB(220,220,220); dl.TextStrokeTransparency=0
            dl.Font=Enum.Font.Gotham; dl.TextSize=11; dl.TextXAlignment=Enum.TextXAlignment.Center
            local t0=0
            ac(RS.Heartbeat:Connect(function()
                local t2=tick(); if (t2-t0)<0.2 then return end; t0=t2
                if not (hrp and hrp.Parent) then return end
                local myhrp=getHRP()
                dl.Text=myhrp and (math.floor((hrp.Position-myhrp.Position).Magnitude).."m") or ""
                local hum=c:FindFirstChildOfClass("Humanoid")
                if hum then nl.Text=p.Name.."  "..math.floor(hum.Health) end
            end))
            espTags[p]=bb
        end
        attach(); ac(p.CharacterAdded:Connect(attach))
    end
    for _, p in pairs(Players:GetPlayers()) do tag(p) end
    ac(Players.PlayerAdded:Connect(tag))
end

local ballGlowOn=false; local glowConn
local function ballGlow(on)
    ballGlowOn=on
    if glowConn then glowConn:Disconnect(); glowConn=nil end
    if not on then
        for _, v in pairs(workspace:GetDescendants()) do
            if v:IsA("PointLight") and v.Name=="__ABGlow__" then v:Destroy() end
        end; return
    end
    local t=0; glowConn=ac(RS.Heartbeat:Connect(function()
        local n=tick(); if (n-t)<0.5 then return end; t=n
        local ball=findBall() or scanForBall(); if not ball then return end
        if not ball:FindFirstChild("__ABGlow__") then
            local pl=Instance.new("PointLight",ball); pl.Name="__ABGlow__"
            pl.Brightness=8; pl.Range=20; pl.Color=Color3.fromRGB(255,120,40)
        end
    end))
end

local ballTrailOn=false; local trailConn; local trailColor=Color3.fromRGB(120,80,255)
local function ballTrail(on)
    ballTrailOn=on
    if trailConn then trailConn:Disconnect(); trailConn=nil end
    if not on then
        for _, v in pairs(workspace:GetDescendants()) do
            if (v:IsA("Trail") and v.Name=="__ABTrail__")
            or (v:IsA("Attachment") and (v.Name=="__TrA0__" or v.Name=="__TrA1__")) then v:Destroy() end
        end; return
    end
    local t=0; trailConn=ac(RS.Heartbeat:Connect(function()
        local n=tick(); if (n-t)<0.5 then return end; t=n
        local ball=findBall() or scanForBall(); if not ball then return end
        if not ball:FindFirstChild("__ABTrail__") then
            local a0=Instance.new("Attachment",ball); a0.Name="__TrA0__"; a0.Position=Vector3.new(0,0.5,0)
            local a1=Instance.new("Attachment",ball); a1.Name="__TrA1__"; a1.Position=Vector3.new(0,-0.5,0)
            local tr=Instance.new("Trail",ball); tr.Name="__ABTrail__"
            tr.Attachment0=a0; tr.Attachment1=a1; tr.Lifetime=0.8
            tr.MinLength=0; tr.FaceCamera=true; tr.LightEmission=1
            tr.Color=ColorSequence.new({ColorSequenceKeypoint.new(0,trailColor),ColorSequenceKeypoint.new(1,Color3.new(1,1,1))})
            tr.Transparency=NumberSequence.new({NumberSequenceKeypoint.new(0,0),NumberSequenceKeypoint.new(1,1)})
            tr.WidthScale=NumberSequence.new({NumberSequenceKeypoint.new(0,1.2),NumberSequenceKeypoint.new(1,0)})
        end
    end))
end

local ballEspOn=false; local ballEspBB=nil
local function ballESP(on)
    ballEspOn=on
    if not on and ballEspBB then ballEspBB:Destroy(); ballEspBB=nil end
end

local aimOn=false; local aimConn
local function aimbot(on)
    aimOn=on
    if aimConn then aimConn:Disconnect(); aimConn=nil end
    if not on then return end
    aimConn=ac(RS.RenderStepped:Connect(function()
        if not UIS:IsMouseButtonPressed(Enum.UserInputType.MouseButton2) then return end
        local best,bd=nil,math.huge
        for _, p in pairs(Players:GetPlayers()) do
            if p~=LP and p.Character then
                local h=p.Character:FindFirstChild("Head")
                if h then
                    local pos,vis=cam:WorldToScreenPoint(h.Position)
                    if vis then
                        local d=(Vector2.new(pos.X,pos.Y)-cam.ViewportSize*0.5).Magnitude
                        if d<bd then best=h; bd=d end
                    end
                end
            end
        end
        if best then cam.CFrame=CFrame.lookAt(cam.CFrame.Position, best.Position) end
    end))
end

local kaOn=false; local kaConn; local kaRange=20
local function killAura(on)
    kaOn=on
    if kaConn then kaConn:Disconnect(); kaConn=nil end
    if not on then return end
    kaConn=ac(RS.Heartbeat:Connect(function()
        local hrp=getHRP(); if not hrp then return end
        for _, p in pairs(Players:GetPlayers()) do
            if p~=LP and p.Character then
                local r2=p.Character:FindFirstChild("HumanoidRootPart")
                local h2=p.Character:FindFirstChildOfClass("Humanoid")
                if r2 and h2 and (r2.Position-hrp.Position).Magnitude<kaRange then
                    pcall(function() h2.Health=0 end)
                end
            end
        end
    end))
end

local godConn
local function godMode(on)
    if godConn then godConn:Disconnect(); godConn=nil end
    if on then godConn=ac(RS.Heartbeat:Connect(function()
        local h=getHum(); if h then h.Health=h.MaxHealth end
    end)) end
end

local function setSpeed(v) local h=getHum(); if h then h.WalkSpeed=v end end

local infJumpConn
local function infJump(on)
    if infJumpConn then infJumpConn:Disconnect(); infJumpConn=nil end
    if on then infJumpConn=ac(UIS.JumpRequest:Connect(function()
        local h=getHum(); if h then h:ChangeState(Enum.HumanoidStateType.Jumping) end
    end)) end
end

local antiElimOn=false; local antiElimOrig=nil; local antiElimHooked=false
local function antiElim(on)
    antiElimOn=on
    if on and CAPS.hookmetamethod and not antiElimHooked then
        antiElimHooked=true
        pcall(function()
            antiElimOrig=hookmetamethod(game,"__namecall",function(self,...)
                local m=CAPS.getnamecall and getnamecallmethod() or ""
                if antiElimOn and typeof(self)=="Instance" then
                    local n=self.Name:lower()
                    if m=="FireServer" and (n:find("elim") or n:find("die") or n:find("kill") or n:find("death")) then return end
                    if m=="Destroy" then local c=getChar(); if c and self==c then return end end
                end
                return antiElimOrig(self,...)
            end)
        end)
    elseif not on and antiElimOrig and antiElimHooked then
        pcall(function() hookmetamethod(game,"__namecall",antiElimOrig) end)
        antiElimOrig=nil; antiElimHooked=false
    end
end

local function fullbright(on)
    if on then Lighting.Brightness=3; Lighting.GlobalShadows=false; Lighting.FogEnd=1e6; Lighting.ClockTime=14
    else      Lighting.Brightness=1; Lighting.GlobalShadows=true;  Lighting.ClockTime=14 end
end

-- ── Config ────────────────────────────────────────────────────────────────────
local CFG_PATH = "AnimeBallHub_config.json"
local settings = {
    autoParry=false, autoDodge=false, ballGlow=true, ballTrail=true, ballEsp=true,
    esp=false, speed=16, fly=false, killAura=false, god=false,
    antiElim=false, fullbright=false, infJump=false, noclip=false,
}
local function loadCfg()
    if not CAPS.readfile then return end
    local ok2, data = pcall(readfile, CFG_PATH)
    if ok2 and data and data~="" then
        local ok3, t = pcall(function() return HS:JSONDecode(data) end)
        if ok3 and t then for k, v in pairs(t) do settings[k]=v end end
    end
end
local function saveCfg()
    if not CAPS.writefile then return end
    pcall(function() writefile(CFG_PATH, HS:JSONEncode(settings)) end)
end
loadCfg()

-- ── Main heartbeat loop ───────────────────────────────────────────────────────
local ballVelSampleTime=0; local loopTick=0
ac(RS.Heartbeat:Connect(function()
    local now=tick()
    if (now-loopTick)<0.016 then return end; loopTick=now

    local ball=findBall()
    if not ball then ball=scanForBall(); if ball then ballCache=ball end end

    local hrp=getHRP(); if not hrp then return end

    if ball then
        watchBall(ball); STATS.ball=true
        -- velocity sampling
        local dt=now-ballVelSampleTime
        if dt>0 and dt<0.5 and lastBallPos2 then
            local spd=(ball.Position-lastBallPos2).Magnitude/dt
            ballVelSamples[#ballVelSamples+1]=spd
            if #ballVelSamples>8 then table.remove(ballVelSamples,1) end
            local sum=0; for _,v in ipairs(ballVelSamples) do sum=sum+v end
            ballVelAvg=sum/#ballVelSamples
        end
        lastBallPos2=ball.Position; ballVelSampleTime=now

        -- live stats
        local dist=(ball.Position-hrp.Position).Magnitude
        local vel=ball.AssemblyLinearVelocity.Magnitude
        STATS.ballDist=math.floor(dist)
        STATS.ballSpeed=math.floor(vel>0 and vel or ballVelAvg)
        if vel>2 then STATS.tti=math.floor(((dist-8)/vel)*100)/100
        elseif ballVelAvg>0 then STATS.tti=math.floor((dist/ballVelAvg)*100)/100
        else STATS.tti=99 end

        -- Ball ESP
        if ballEspOn then
            if not (ballEspBB and ballEspBB.Parent) then
                local bb=Instance.new("BillboardGui",ball); bb.Name="__abbesp__"
                bb.Size=UDim2.new(0,0,0,54); bb.StudsOffset=Vector3.new(0,2.5,0); bb.AlwaysOnTop=true
                local nl=Instance.new("TextLabel",bb); nl.Size=UDim2.new(1,0,0,18); nl.BackgroundTransparency=1
                nl.TextColor3=Color3.fromRGB(120,220,255); nl.TextStrokeTransparency=0
                nl.Font=Enum.Font.GothamBold; nl.TextSize=13; nl.TextXAlignment=Enum.TextXAlignment.Center
                local sl=Instance.new("TextLabel",bb); sl.Size=UDim2.new(1,0,0,14); sl.Position=UDim2.new(0,0,0,18)
                sl.BackgroundTransparency=1; sl.TextColor3=Color3.fromRGB(200,200,200); sl.TextStrokeTransparency=0
                sl.Font=Enum.Font.Gotham; sl.TextSize=10; sl.TextXAlignment=Enum.TextXAlignment.Center
                local tl=Instance.new("TextLabel",bb); tl.Size=UDim2.new(1,0,0,14); tl.Position=UDim2.new(0,0,0,32)
                tl.BackgroundTransparency=1; tl.Font=Enum.Font.GothamBold
                tl.TextSize=10; tl.TextXAlignment=Enum.TextXAlignment.Center
                ballEspBB=bb
                ac(RS.Heartbeat:Connect(function()
                    if not (ball and ball.Parent and ballEspBB and ballEspBB.Parent) then return end
                    nl.Text="⬤ BALL  "..STATS.ballDist.."m"
                    sl.Text="Speed: "..STATS.ballSpeed.." st/s"
                    local tti2=STATS.tti
                    tl.Text="TTI: "..string.format("%.2f",tti2).."s"
                    tl.TextColor3=tti2<PARRY_WINDOW+0.1 and Color3.fromRGB(255,80,80) or Color3.fromRGB(120,255,150)
                end))
            end
        end

        -- Auto Parry
        if autoParryOn then
            local vel2=ball.AssemblyLinearVelocity.Magnitude
            local fire=false
            if dist<8 then fire=true
            elseif vel2>2 then
                local tti=(dist-8)/vel2
                fire=tti<=(PARRY_WINDOW+getPing())
            elseif ballVelAvg>0 then
                fire=(dist/ballVelAvg)<=(PARRY_WINDOW+getPing())
            else fire=dist<25 end
            if fire then doParry(ball) end
        end

        -- Auto Dodge
        if autoDodgeOn and dist<30 then doDodge(ball,hrp) end
    else
        STATS.ball=false; STATS.ballDist=0; STATS.ballSpeed=0; STATS.tti=99
        if ballEspBB and ballEspBB.Parent then ballEspBB:Destroy(); ballEspBB=nil end
    end
end))

-- ══════════════════════════════════════════════════════════════════════════════
--  ██████╗ ██╗   ██╗██╗
--  ██╔════╝ ██║   ██║██║
--  ██║  ███╗██║   ██║██║
--  ██║   ██║██║   ██║██║
--  ╚██████╔╝╚██████╔╝██║
--   ╚═════╝  ╚═════╝ ╚═╝
--  WORLD-CLASS UI — v4.0
-- ══════════════════════════════════════════════════════════════════════════════

-- ── Palette ───────────────────────────────────────────────────────────────────
local C = {
    BG      = Color3.fromRGB(8,   8,  14),   -- near-black bg
    PANEL   = Color3.fromRGB(12,  12,  20),   -- sidebar
    CARD    = Color3.fromRGB(18,  18,  28),   -- card bg
    CARD2   = Color3.fromRGB(24,  24,  38),   -- card hover / button
    BORDER  = Color3.fromRGB(40,  40,  65),   -- subtle border
    BORDER2 = Color3.fromRGB(70,  70, 110),   -- active border
    ACC1    = Color3.fromRGB(120,  80, 255),  -- purple accent
    ACC2    = Color3.fromRGB( 60, 180, 255),  -- blue accent
    ACC3    = Color3.fromRGB(255,  80, 140),  -- pink accent
    GRN     = Color3.fromRGB( 80, 220, 130),  -- green / ok
    RED     = Color3.fromRGB(255,  75,  75),  -- red / danger
    YEL     = Color3.fromRGB(255, 210,  60),  -- yellow / warn
    TX      = Color3.fromRGB(220, 220, 240),  -- primary text
    TX2     = Color3.fromRGB(130, 130, 160),  -- secondary text
    TX3     = Color3.fromRGB( 70,  70,  95),  -- muted text
    WHITE   = Color3.fromRGB(255, 255, 255),
    BLACK   = Color3.fromRGB(  0,   0,   0),
}

-- ── Tween helpers ─────────────────────────────────────────────────────────────
local TF_FAST  = TweenInfo.new(0.12, Enum.EasingStyle.Quad,   Enum.EasingDirection.Out)
local TF_MED   = TweenInfo.new(0.20, Enum.EasingStyle.Quad,   Enum.EasingDirection.Out)
local TF_SLOW  = TweenInfo.new(0.35, Enum.EasingStyle.Quint,  Enum.EasingDirection.Out)
local TF_SPRING= TweenInfo.new(0.25, Enum.EasingStyle.Back,   Enum.EasingDirection.Out)
local function tw(i,p,tf) if i and i.Parent then TS:Create(i, tf or TF_FAST, p):Play() end end

-- ── UI primitives ─────────────────────────────────────────────────────────────
local function corner(i, r)
    local c2 = Instance.new("UICorner", i); c2.CornerRadius = UDim.new(0, r or 8); return c2
end
local function stroke(i, col, t)
    local s = Instance.new("UIStroke", i); s.Color = col or C.BORDER; s.Thickness = t or 1; return s
end
local function pad(i, l, r2, tp, bo)
    local p = Instance.new("UIPadding", i)
    p.PaddingLeft=UDim.new(0,l or 0); p.PaddingRight=UDim.new(0,r2 or 0)
    p.PaddingTop=UDim.new(0,tp or 0); p.PaddingBottom=UDim.new(0,bo or 0)
end
local function listV(i, gap)
    local l = Instance.new("UIListLayout", i)
    l.SortOrder=Enum.SortOrder.LayoutOrder; l.Padding=UDim.new(0,gap or 0); return l
end
local function grad(i, c1, c2b, rot)
    local g = Instance.new("UIGradient", i)
    g.Color=ColorSequence.new(c1, c2b); g.Rotation=rot or 90; return g
end

-- ── Root ──────────────────────────────────────────────────────────────────────
local old = PGui:FindFirstChild("__ABHUB4__"); if old then old:Destroy() end
local SCR = Instance.new("ScreenGui", PGui)
SCR.Name="__ABHUB4__"; SCR.ResetOnSpawn=false
SCR.IgnoreGuiInset=true; SCR.ZIndexBehavior=Enum.ZIndexBehavior.Sibling

-- ── Backdrop shadow ───────────────────────────────────────────────────────────
local SHADOW = Instance.new("Frame", SCR)
SHADOW.Size=UDim2.new(0,380,0,540); SHADOW.Position=UDim2.new(0.5,-186,0.5,-268)
SHADOW.BackgroundColor3=Color3.fromRGB(0,0,0); SHADOW.BackgroundTransparency=0.55
SHADOW.BorderSizePixel=0; corner(SHADOW, 20)

-- ── Main window ───────────────────────────────────────────────────────────────
local WIN = Instance.new("Frame", SCR)
WIN.Size=UDim2.new(0,372,0,530); WIN.Position=UDim2.new(0.5,-186,0.5,-265)
WIN.BackgroundColor3=C.BG; WIN.BorderSizePixel=0; WIN.ClipsDescendants=true
corner(WIN, 16); stroke(WIN, C.BORDER, 1.5)

-- Thin top gradient accent line
local TOPLINE = Instance.new("Frame", WIN)
TOPLINE.Size=UDim2.new(1,0,0,2); TOPLINE.Position=UDim2.new(0,0,0,0)
TOPLINE.BackgroundColor3=C.ACC1; TOPLINE.BorderSizePixel=0
grad(TOPLINE, C.ACC1, C.ACC2)

-- ── Title bar ─────────────────────────────────────────────────────────────────
local TBAR = Instance.new("Frame", WIN)
TBAR.Size=UDim2.new(1,0,0,52); TBAR.Position=UDim2.new(0,0,0,2)
TBAR.BackgroundColor3=C.BG; TBAR.BorderSizePixel=0

-- Logo orb (animated)
local LOGO_RING = Instance.new("Frame", TBAR)
LOGO_RING.Size=UDim2.new(0,34,0,34); LOGO_RING.Position=UDim2.new(0,14,0.5,-17)
LOGO_RING.BackgroundColor3=C.ACC1; LOGO_RING.BorderSizePixel=0; corner(LOGO_RING,17)
grad(LOGO_RING, C.ACC1, C.ACC2, 135)
local LOGO_INNER = Instance.new("Frame", LOGO_RING)
LOGO_INNER.Size=UDim2.new(0,26,0,26); LOGO_INNER.Position=UDim2.new(0.5,-13,0.5,-13)
LOGO_INNER.BackgroundColor3=C.BG; LOGO_INNER.BorderSizePixel=0; corner(LOGO_INNER,13)
local LOGO_DOT = Instance.new("Frame", LOGO_INNER)
LOGO_DOT.Size=UDim2.new(0,10,0,10); LOGO_DOT.Position=UDim2.new(0.5,-5,0.5,-5)
LOGO_DOT.BackgroundColor3=C.ACC2; LOGO_DOT.BorderSizePixel=0; corner(LOGO_DOT,5)
task.spawn(function()
    local h=0
    while LOGO_RING and LOGO_RING.Parent do
        h=(h+1)%360
        local c1=Color3.fromHSV(h/360,0.7,1)
        local c2b=Color3.fromHSV(((h+60)%360)/360,0.8,1)
        if LOGO_RING and LOGO_RING.Parent then
            local g2=LOGO_RING:FindFirstChildOfClass("UIGradient")
            if g2 then g2.Color=ColorSequence.new(c1,c2b) end
        end
        task.wait(0.05)
    end
end)

-- Title text
local TITLE = Instance.new("TextLabel", TBAR)
TITLE.Size=UDim2.new(0,150,0,22); TITLE.Position=UDim2.new(0,56,0,8)
TITLE.BackgroundTransparency=1; TITLE.Text="Anime Ball Hub"
TITLE.TextColor3=C.TX; TITLE.Font=Enum.Font.GothamBold; TITLE.TextSize=15
TITLE.TextXAlignment=Enum.TextXAlignment.Left

local SUBTITLE = Instance.new("TextLabel", TBAR)
SUBTITLE.Size=UDim2.new(0,150,0,14); SUBTITLE.Position=UDim2.new(0,56,0,28)
SUBTITLE.BackgroundTransparency=1; SUBTITLE.Text="v4.0  ·  "..capScore.." APIs"
SUBTITLE.TextColor3=C.TX3; SUBTITLE.Font=Enum.Font.Gotham; SUBTITLE.TextSize=10
SUBTITLE.TextXAlignment=Enum.TextXAlignment.Left

-- Minimize button
local MINBTN = Instance.new("TextButton", TBAR)
MINBTN.Size=UDim2.new(0,28,0,28); MINBTN.Position=UDim2.new(1,-66,0.5,-14)
MINBTN.BackgroundColor3=C.CARD2; MINBTN.Text="—"; MINBTN.TextColor3=C.TX2
MINBTN.Font=Enum.Font.GothamBold; MINBTN.TextSize=13; MINBTN.BorderSizePixel=0; corner(MINBTN,7)

-- Close button
local CLOSEBTN = Instance.new("TextButton", TBAR)
CLOSEBTN.Size=UDim2.new(0,28,0,28); CLOSEBTN.Position=UDim2.new(1,-32,0.5,-14)
CLOSEBTN.BackgroundColor3=C.RED; CLOSEBTN.Text="✕"; CLOSEBTN.TextColor3=C.WHITE
CLOSEBTN.Font=Enum.Font.GothamBold; CLOSEBTN.TextSize=12; CLOSEBTN.BorderSizePixel=0; corner(CLOSEBTN,7)

CLOSEBTN.MouseButton1Click:Connect(function()
    clearConns(); clearESP(); fly(false); noclip(false); ballGlow(false); ballTrail(false)
    godMode(false); killAura(false); aimbot(false); antiElim(false)
    saveCfg(); SCR:Destroy()
end)

-- ── Live Status Bar ───────────────────────────────────────────────────────────
local SBAR = Instance.new("Frame", WIN)
SBAR.Size=UDim2.new(1,0,0,32); SBAR.Position=UDim2.new(0,0,0,54)
SBAR.BackgroundColor3=C.PANEL; SBAR.BorderSizePixel=0
local SBAR_LINE = Instance.new("Frame", SBAR)
SBAR_LINE.Size=UDim2.new(1,0,0,1); SBAR_LINE.Position=UDim2.new(0,0,1,-1)
SBAR_LINE.BackgroundColor3=C.BORDER; SBAR_LINE.BorderSizePixel=0

local function makeStatPill(parent, xOffset, label, color)
    local pill = Instance.new("Frame", parent)
    pill.Size=UDim2.new(0,80,0,20); pill.Position=UDim2.new(0,xOffset,0.5,-10)
    pill.BackgroundColor3=C.CARD2; pill.BorderSizePixel=0; corner(pill,10)
    local lbl = Instance.new("TextLabel", pill)
    lbl.Size=UDim2.new(1,0,1,0); lbl.BackgroundTransparency=1
    lbl.Text=label; lbl.TextColor3=color or C.TX2
    lbl.Font=Enum.Font.GothamBold; lbl.TextSize=10; lbl.TextXAlignment=Enum.TextXAlignment.Center
    return lbl
end

local statBall  = makeStatPill(SBAR, 8,   "⬤ NO BALL", C.RED)
local statTTI   = makeStatPill(SBAR, 96,  "TTI: --",   C.TX2)
local statPing  = makeStatPill(SBAR, 184, "PING: --",  C.TX2)
local statReady = makeStatPill(SBAR, 272, "SEARCHING", C.YEL)

-- Update status bar every 0.2s
task.spawn(function()
    while SCR and SCR.Parent do
        pcall(function()
            statBall.Text  = STATS.ball and ("⬤ "..STATS.ballDist.."m  "..STATS.ballSpeed.."st/s") or "⬤ NO BALL"
            statBall.TextColor3 = STATS.ball and C.GRN or C.RED
            statTTI.Text   = STATS.tti<90 and ("TTI "..string.format("%.2f",STATS.tti).."s") or "TTI --"
            statTTI.TextColor3 = STATS.tti<PARRY_WINDOW and C.RED or (STATS.tti<1 and C.YEL or C.TX2)
            statPing.Text  = STATS.ping>0 and (STATS.ping.."ms") or "PING --"
            statPing.TextColor3= STATS.ping>150 and C.RED or (STATS.ping>80 and C.YEL or C.TX2)
            if cachedBlockFn then
                statReady.Text="✓ READY"; statReady.TextColor3=C.GRN
            elseif autoParryOn then
                statReady.Text="PARRY ON"; statReady.TextColor3=C.YEL
            else
                statReady.Text="IDLE"; statReady.TextColor3=C.TX3
            end
        end)
        task.wait(0.2)
    end
end)

-- ── Sidebar tabs ──────────────────────────────────────────────────────────────
local SIDEBAR = Instance.new("Frame", WIN)
SIDEBAR.Size=UDim2.new(0,56,1,-86); SIDEBAR.Position=UDim2.new(0,0,0,86)
SIDEBAR.BackgroundColor3=C.PANEL; SIDEBAR.BorderSizePixel=0
local SIDE_LINE = Instance.new("Frame", SIDEBAR)
SIDE_LINE.Size=UDim2.new(0,1,1,0); SIDE_LINE.Position=UDim2.new(1,-1,0,0)
SIDE_LINE.BackgroundColor3=C.BORDER; SIDE_LINE.BorderSizePixel=0

-- ── Content area ──────────────────────────────────────────────────────────────
local CONTENT = Instance.new("Frame", WIN)
CONTENT.Size=UDim2.new(1,-58,1,-86); CONTENT.Position=UDim2.new(0,58,0,86)
CONTENT.BackgroundColor3=C.BG; CONTENT.BorderSizePixel=0

local TAB_DEFS = {
    {id="parry",  icon="⚡", label="Parry"},
    {id="visual", icon="◈",  label="Visual"},
    {id="move",   icon="↑",  label="Move"},
    {id="ball",   icon="●",  label="Ball"},
    {id="misc",   icon="⚙",  label="Misc"},
}
local tabPages={}; local tabBtns={}; local activeTabId=nil

local function showTab(id)
    activeTabId=id
    for _, def in ipairs(TAB_DEFS) do
        local page=tabPages[def.id]; local btn=tabBtns[def.id]
        local on=(def.id==id)
        if page then page.Visible=on end
        if btn then
            tw(btn.bg, {BackgroundColor3=on and C.CARD or C.PANEL})
            tw(btn.ico,{TextColor3=on and C.ACC2 or C.TX3})
            tw(btn.lbl,{TextColor3=on and C.TX   or C.TX3})
            if on then
                if not btn.bar.Parent then btn.bar.Parent=btn.bg end
            end
            tw(btn.bar,{BackgroundColor3=on and C.ACC1 or C.PANEL,
                         Size=on and UDim2.new(0,3,0,28) or UDim2.new(0,2,0,0)})
        end
    end
end

for idx, def in ipairs(TAB_DEFS) do
    -- sidebar button
    local bg = Instance.new("Frame", SIDEBAR)
    bg.Size=UDim2.new(1,0,0,56); bg.BackgroundColor3=C.PANEL; bg.BorderSizePixel=0
    bg.LayoutOrder=idx; bg.Position=UDim2.new(0,0,0,(idx-1)*56)
    corner(bg,0)

    local bar = Instance.new("Frame", bg)
    bar.Size=UDim2.new(0,3,0,0); bar.Position=UDim2.new(0,0,0.5,0); bar.AnchorPoint=Vector2.new(0,0.5)
    bar.BackgroundColor3=C.PANEL; bar.BorderSizePixel=0; corner(bar,2)

    local ico = Instance.new("TextLabel", bg)
    ico.Size=UDim2.new(1,0,0,26); ico.Position=UDim2.new(0,0,0,10)
    ico.BackgroundTransparency=1; ico.Text=def.icon; ico.TextColor3=C.TX3
    ico.Font=Enum.Font.GothamBold; ico.TextSize=16; ico.TextXAlignment=Enum.TextXAlignment.Center

    local lbl = Instance.new("TextLabel", bg)
    lbl.Size=UDim2.new(1,0,0,14); lbl.Position=UDim2.new(0,0,0,35)
    lbl.BackgroundTransparency=1; lbl.Text=def.label; lbl.TextColor3=C.TX3
    lbl.Font=Enum.Font.Gotham; lbl.TextSize=9; lbl.TextXAlignment=Enum.TextXAlignment.Center

    local click = Instance.new("TextButton", bg)
    click.Size=UDim2.new(1,0,1,0); click.BackgroundTransparency=1; click.Text=""
    click.MouseButton1Click:Connect(function() showTab(def.id) end)

    tabBtns[def.id]={bg=bg,ico=ico,lbl=lbl,bar=bar}

    -- content page
    local page = Instance.new("ScrollingFrame", CONTENT)
    page.Name=def.id; page.Size=UDim2.new(1,0,1,0)
    page.BackgroundTransparency=1; page.BorderSizePixel=0
    page.ScrollBarThickness=3; page.ScrollBarImageColor3=C.ACC1
    page.AutomaticCanvasSize=Enum.AutomaticSize.Y
    page.CanvasSize=UDim2.new(0,0,0,0); page.Visible=false
    listV(page, 6)
    pad(page, 10, 10, 10, 14)
    tabPages[def.id]=page
end

-- ── Row builders ──────────────────────────────────────────────────────────────
local loCount=0
local function nextLo() loCount=loCount+1; return loCount end

local function secHeader(page, title)
    local sh = Instance.new("Frame", page)
    sh.Size=UDim2.new(1,0,0,22); sh.BackgroundTransparency=1; sh.LayoutOrder=nextLo()
    local line = Instance.new("Frame", sh)
    line.Size=UDim2.new(1,0,0,1); line.Position=UDim2.new(0,0,0.5,0)
    line.BackgroundColor3=C.BORDER; line.BorderSizePixel=0
    local lbl = Instance.new("TextLabel", sh)
    lbl.Size=UDim2.new(0,0,1,0); lbl.AutomaticSize=Enum.AutomaticSize.X
    lbl.Position=UDim2.new(0,0,0,0); lbl.BackgroundColor3=C.BG
    lbl.Text=" "..title.." "; lbl.TextColor3=C.ACC1
    lbl.Font=Enum.Font.GothamBold; lbl.TextSize=10
    return sh
end

local function addToggle(page, label, sublabel, init, callback)
    local lo=nextLo()
    local row = Instance.new("Frame", page)
    row.Size=UDim2.new(1,0,0,sublabel and 50 or 40)
    row.BackgroundColor3=C.CARD; row.BorderSizePixel=0; corner(row,10); row.LayoutOrder=lo
    stroke(row, C.BORDER)

    local nameL = Instance.new("TextLabel", row)
    nameL.Size=UDim2.new(1,-58,0,20); nameL.Position=UDim2.new(0,12,0,sublabel and 8 or 10)
    nameL.BackgroundTransparency=1; nameL.Text=label; nameL.TextColor3=C.TX
    nameL.Font=Enum.Font.GothamSemibold; nameL.TextSize=13; nameL.TextXAlignment=Enum.TextXAlignment.Left

    if sublabel then
        local sl = Instance.new("TextLabel", row)
        sl.Size=UDim2.new(1,-58,0,14); sl.Position=UDim2.new(0,12,0,27)
        sl.BackgroundTransparency=1; sl.Text=sublabel; sl.TextColor3=C.TX3
        sl.Font=Enum.Font.Gotham; sl.TextSize=9.5; sl.TextXAlignment=Enum.TextXAlignment.Left
    end

    local pill = Instance.new("Frame", row)
    pill.Size=UDim2.new(0,42,0,22); pill.Position=UDim2.new(1,-52,0.5,-11)
    pill.BorderSizePixel=0; corner(pill,11)

    local knob = Instance.new("Frame", pill)
    knob.Size=UDim2.new(0,18,0,18); knob.Position=UDim2.new(0,2,0.5,-9)
    knob.BorderSizePixel=0; corner(knob,9)

    local state = init or false
    local function refresh(animate)
        local tf = animate and TF_SPRING or TF_FAST
        tw(pill, {BackgroundColor3=state and C.ACC1 or C.CARD2}, tf)
        tw(knob, {Position=state and UDim2.new(1,-20,0.5,-9) or UDim2.new(0,2,0.5,-9),
                  BackgroundColor3=state and C.WHITE or C.TX3}, tf)
        tw(nameL,{TextColor3=state and C.TX or C.TX2})
    end
    refresh(false)

    local click = Instance.new("TextButton", row)
    click.Size=UDim2.new(1,0,1,0); click.BackgroundTransparency=1; click.Text=""
    click.MouseButton1Click:Connect(function()
        state=not state; refresh(true); pcall(callback, state)
    end)

    -- hover effect
    click.MouseEnter:Connect(function() tw(row,{BackgroundColor3=C.CARD2}) end)
    click.MouseLeave:Connect(function() tw(row,{BackgroundColor3=C.CARD}) end)

    return function() return state end, function(v) state=v; refresh(true) end
end

local function addButton(page, label, sublabel, accentColor, callback)
    local lo=nextLo()
    local row = Instance.new("Frame", page)
    row.Size=UDim2.new(1,0,0,sublabel and 50 or 42)
    row.BackgroundColor3=C.CARD; row.BorderSizePixel=0; corner(row,10); row.LayoutOrder=lo
    stroke(row, C.BORDER)

    local nameL = Instance.new("TextLabel", row)
    nameL.Size=UDim2.new(1,-74,0,20)
    nameL.Position=UDim2.new(0,12,0,sublabel and 8 or 11)
    nameL.BackgroundTransparency=1; nameL.Text=label; nameL.TextColor3=C.TX
    nameL.Font=Enum.Font.GothamSemibold; nameL.TextSize=13; nameL.TextXAlignment=Enum.TextXAlignment.Left

    if sublabel then
        local sl=Instance.new("TextLabel",row)
        sl.Size=UDim2.new(1,-74,0,14); sl.Position=UDim2.new(0,12,0,27)
        sl.BackgroundTransparency=1; sl.Text=sublabel; sl.TextColor3=C.TX3
        sl.Font=Enum.Font.Gotham; sl.TextSize=9.5; sl.TextXAlignment=Enum.TextXAlignment.Left
    end

    local ac2=accentColor or C.ACC1
    local bf = Instance.new("Frame", row)
    bf.Size=UDim2.new(0,54,0,28); bf.Position=UDim2.new(1,-62,0.5,-14)
    bf.BackgroundColor3=ac2; bf.BorderSizePixel=0; corner(bf,8)
    local bl = Instance.new("TextLabel", bf)
    bl.Size=UDim2.new(1,0,1,0); bl.BackgroundTransparency=1; bl.Text="RUN"
    bl.TextColor3=C.WHITE; bl.Font=Enum.Font.GothamBold; bl.TextSize=11
    bl.TextXAlignment=Enum.TextXAlignment.Center

    local click = Instance.new("TextButton", row)
    click.Size=UDim2.new(1,0,1,0); click.BackgroundTransparency=1; click.Text=""
    click.MouseButton1Click:Connect(function()
        tw(bf,{BackgroundColor3=C.WHITE}); tw(bl,{TextColor3=ac2})
        task.delay(0.18, function()
            tw(bf,{BackgroundColor3=ac2}); tw(bl,{TextColor3=C.WHITE})
        end)
        pcall(callback)
    end)
    click.MouseEnter:Connect(function() tw(row,{BackgroundColor3=C.CARD2}) end)
    click.MouseLeave:Connect(function() tw(row,{BackgroundColor3=C.CARD}) end)
end

local function addInfo(page, text, textColor, bgColor)
    local lo=nextLo()
    local row = Instance.new("Frame", page)
    row.Size=UDim2.new(1,0,0,30); row.BackgroundColor3=bgColor or C.CARD
    row.BorderSizePixel=0; corner(row,8); row.LayoutOrder=lo
    local l = Instance.new("TextLabel", row)
    l.Size=UDim2.new(1,-16,1,0); l.Position=UDim2.new(0,10,0,0)
    l.BackgroundTransparency=1; l.Text=text; l.TextColor3=textColor or C.TX2
    l.Font=Enum.Font.Gotham; l.TextSize=11; l.TextXAlignment=Enum.TextXAlignment.Left
    l.TextWrapped=true
    return l
end

local function addColorRow(page, label, colors, onPick)
    local lo=nextLo()
    local outer = Instance.new("Frame", page)
    outer.Size=UDim2.new(1,0,0,58); outer.BackgroundColor3=C.CARD
    outer.BorderSizePixel=0; corner(outer,10); outer.LayoutOrder=lo; stroke(outer,C.BORDER)
    local hdr = Instance.new("TextLabel", outer)
    hdr.Size=UDim2.new(1,0,0,18); hdr.Position=UDim2.new(0,12,0,6)
    hdr.BackgroundTransparency=1; hdr.Text=label; hdr.TextColor3=C.TX2
    hdr.Font=Enum.Font.GothamSemibold; hdr.TextSize=11; hdr.TextXAlignment=Enum.TextXAlignment.Left
    local row2 = Instance.new("Frame", outer)
    row2.Size=UDim2.new(1,-24,0,26); row2.Position=UDim2.new(0,12,0,26)
    row2.BackgroundTransparency=1
    local ll = Instance.new("UIListLayout", row2)
    ll.FillDirection=Enum.FillDirection.Horizontal; ll.Padding=UDim.new(0,6)
    local selB=nil
    for i, cd in ipairs(colors) do
        local cf=Instance.new("Frame",row2); cf.Size=UDim2.new(0,26,0,26); cf.BackgroundColor3=cd[2]; cf.BorderSizePixel=0; corner(cf,13); cf.LayoutOrder=i
        local cb=Instance.new("TextButton",cf); cb.Size=UDim2.new(1,0,1,0); cb.BackgroundTransparency=1; cb.Text=""
        cb.MouseButton1Click:Connect(function()
            if selB then selB:Destroy(); selB=nil end
            selB=stroke(cf,C.WHITE,2); onPick(cd[2])
        end)
    end
end

-- ══════════════════════════════════════════════════════════════════════════════
--  TAB: PARRY
-- ══════════════════════════════════════════════════════════════════════════════
do
    local P=tabPages["parry"]
    secHeader(P, "AUTO PARRY")

    addToggle(P, "Auto Parry", "TTI+ping compensated, 6-method burst", settings.autoParry, function(on)
        autoParryOn=on; settings.autoParry=on; saveCfg()
        notify("Auto Parry", on and "ENABLED" or "disabled", 2)
    end)

    addToggle(P, "Auto Dodge", "BodyVelocity sidestep when ball<30 studs", settings.autoDodge, function(on)
        autoDodgeOn=on; settings.autoDodge=on; saveCfg()
    end)

    secHeader(P, "PARRY WINDOW")

    -- Parry window selector (compact pill row)
    local wRow = Instance.new("Frame", P)
    wRow.Size=UDim2.new(1,0,0,60); wRow.BackgroundColor3=C.CARD
    wRow.BorderSizePixel=0; corner(wRow,10); wRow.LayoutOrder=nextLo(); stroke(wRow,C.BORDER)
    local wLbl = Instance.new("TextLabel", wRow)
    wLbl.Size=UDim2.new(1,-16,0,18); wLbl.Position=UDim2.new(0,12,0,6)
    wLbl.BackgroundTransparency=1; wLbl.Text="Window: 0.30s (default)"
    wLbl.TextColor3=C.TX; wLbl.Font=Enum.Font.GothamSemibold; wLbl.TextSize=12; wLbl.TextXAlignment=Enum.TextXAlignment.Left
    local wSub = Instance.new("TextLabel", wRow)
    wSub.Size=UDim2.new(1,-16,0,12); wSub.Position=UDim2.new(0,12,0,22)
    wSub.BackgroundTransparency=1; wSub.Text="Bigger = fires earlier (good for high ping)"
    wSub.TextColor3=C.TX3; wSub.Font=Enum.Font.Gotham; wSub.TextSize=9.5; wSub.TextXAlignment=Enum.TextXAlignment.Left
    local wBR = Instance.new("Frame", wRow)
    wBR.Size=UDim2.new(1,-24,0,20); wBR.Position=UDim2.new(0,12,0,36); wBR.BackgroundTransparency=1
    local wLL = Instance.new("UIListLayout", wBR)
    wLL.FillDirection=Enum.FillDirection.Horizontal; wLL.Padding=UDim.new(0,5)
    local WOPTS={{0.18,"lag-safe"},{0.25,"close"},{0.30,"default"},{0.38,"normal"},{0.50,"early"}}
    for i, wv in ipairs(WOPTS) do
        local wf=Instance.new("Frame",wBR); wf.Size=UDim2.new(0,52,0,20); wf.BackgroundColor3=C.CARD2; wf.BorderSizePixel=0; corner(wf,6); wf.LayoutOrder=i
        local wfl=Instance.new("TextLabel",wf); wfl.Size=UDim2.new(1,0,1,0); wfl.BackgroundTransparency=1
        wfl.Text=tostring(wv[1]); wfl.TextColor3=C.TX3; wfl.Font=Enum.Font.GothamBold; wfl.TextSize=9.5; wfl.TextXAlignment=Enum.TextXAlignment.Center
        local wfb=Instance.new("TextButton",wf); wfb.Size=UDim2.new(1,0,1,0); wfb.BackgroundTransparency=1; wfb.Text=""
        wfb.MouseButton1Click:Connect(function()
            PARRY_WINDOW=wv[1]; wLbl.Text="Window: "..wv[1].."s  ("..wv[2]..")"
            tw(wf,{BackgroundColor3=C.ACC1},TF_SPRING); tw(wfl,{TextColor3=C.WHITE})
            task.delay(0.4, function() tw(wf,{BackgroundColor3=C.CARD2}); tw(wfl,{TextColor3=C.TX3}) end)
        end)
    end

    secHeader(P, "COMBAT")

    addToggle(P, "Anti-Elimination", "Block death FireServer via hookmetamethod"..(CAPS.hookmetamethod and "" or "  [N/A]"), settings.antiElim, function(on)
        antiElim(on); settings.antiElim=on; saveCfg()
    end)
    addToggle(P, "God Mode", "Health locked to max every frame", settings.god, function(on)
        godMode(on); settings.god=on; saveCfg()
    end)
    addToggle(P, "Aimbot  (hold RMB)", "Snap camera to nearest player head", false, aimbot)
    addToggle(P, "Kill Aura", "Set nearby player HP to 0", false, killAura)

    secHeader(P, "DEBUG / TOOLS")

    addButton(P, "Force Parry Once", "Fire all 6 methods right now", C.ACC1, function()
        local ball=findBall() or scanForBall(); executeParry(ball)
        notify("Parry","Fired!",2)
    end)

    addButton(P, "Scan Sources", "Check ball + block fn + remotes", C.TX3, function()
        local ball=findBall() or scanForBall(); local r=findBlockRemote(); local btn2=findBlockBtn()
        local msgs={
            "Ball:        "..(ball and ball:GetFullName() or "NOT FOUND — join a round"),
            "Block fn:    "..(cachedBlockFn and "CACHED ✓" or "not found"),
            "SwordCtrl:   "..(swordCtrl and "CACHED (cooldown bypass ready)" or "not found"),
            "SwordSvc:    "..(swordSvcObj and "CACHED ✓" or "not found"),
            "Remote:      "..(r and r:GetFullName() or "not found"),
            "Block btn:   "..(btn2 and btn2:GetFullName() or "not found"),
            "Balls folder:"..(ballsFolder and ballsFolder:GetFullName() or "NOT FOUND"),
        }
        for _, m in ipairs(msgs) do print("[Hub]", m) end
        notify("Scan","See F9 console",4)
    end)

    addButton(P, "Re-lock Block fn", "Force search all 4 strategies", C.ACC2, function()
        cachedBlockFn=nil; findBlockFn()
        notify("Block fn", cachedBlockFn and "Locked!" or "Not found — try in a round", 3)
        STATS.parryOk = cachedBlockFn~=nil
    end)

    secHeader(P, "PARRY METHODS")
    local function methodRow(txt, ok2)
        addInfo(P, (ok2 and "✓ " or "○ ")..txt, ok2 and C.GRN or C.TX3)
    end
    methodRow("framework:Fetch(SwordService).Block:Invoke(Y)", swordSvcObj~=nil)
    methodRow("v_u_1.Block() + LastBlock=nil bypass", CAPS.getgc)
    methodRow("RemoteFunction:InvokeServer(lookY)", true)
    methodRow("VirtualUser HUD.Actions.MainButtons.Block", CAPS.VirtualUser)
    methodRow("firesignal(ball.Touched, hrp)", CAPS.firesignal)
    methodRow("getconnections → call Touched handlers", CAPS.getconnections)
end

-- ══════════════════════════════════════════════════════════════════════════════
--  TAB: VISUAL
-- ══════════════════════════════════════════════════════════════════════════════
do
    local P=tabPages["visual"]
    secHeader(P, "PLAYER ESP")

    addToggle(P, "Name + HP ESP", "BillboardGui name / health / distance", settings.esp, function(on)
        esp(on); settings.esp=on; saveCfg()
    end)
    addToggle(P, "Chams / X-Ray", "Highlight through walls", false, function(on)
        local function applyChams(p)
            if p==LP then return end
            local c=p.Character; if not c then return end
            if c:FindFirstChild("__chams__") then return end
            local h=Instance.new("Highlight",c); h.Name="__chams__"
            h.FillColor=Color3.fromRGB(120,80,255); h.OutlineColor=C.ACC2
            h.FillTransparency=0.45; h.OutlineTransparency=0
            h.DepthMode=Enum.HighlightDepthMode.AlwaysOnTop
        end
        if on then
            for _, p in pairs(Players:GetPlayers()) do applyChams(p) end
            ac(Players.PlayerAdded:Connect(function(p)
                ac(p.CharacterAdded:Connect(function() task.wait(1); applyChams(p) end))
            end))
        else
            for _, v in pairs(workspace:GetDescendants()) do
                if v:IsA("Highlight") and v.Name=="__chams__" then v:Destroy() end
            end
        end
    end)
    addToggle(P, "Box ESP", "SelectionBox on every player part", false, function(on)
        if on then
            ac(RS.Heartbeat:Connect(function()
                for _, p in pairs(Players:GetPlayers()) do
                    if p~=LP and p.Character then
                        for _, v in pairs(p.Character:GetDescendants()) do
                            if v:IsA("BasePart") and not v:FindFirstChild("__bxesp__") then
                                local s=Instance.new("SelectionBox",v); s.Name="__bxesp__"; s.Adornee=v
                                s.Color3=C.ACC3; s.LineThickness=0.04; s.SurfaceTransparency=0.9; s.SurfaceColor3=s.Color3
                            end
                        end
                    end
                end
            end))
        else
            for _, v in pairs(workspace:GetDescendants()) do
                if v:IsA("SelectionBox") and v.Name=="__bxesp__" then v:Destroy() end
            end
        end
    end)

    secHeader(P, "SELF")
    addToggle(P, "Invisible (self)", "Make your character fully transparent", false, function(on)
        local c=getChar(); if not c then return end
        for _, p in pairs(c:GetDescendants()) do
            if p:IsA("BasePart") or p:IsA("Decal") then p.Transparency=on and 1 or 0 end
        end
    end)
    addToggle(P, "Fullbright", "Disable shadows + max brightness", settings.fullbright, function(on)
        fullbright(on); settings.fullbright=on; saveCfg()
    end)

    secHeader(P, "WORLD")
    addButton(P, "Toggle Day/Night", "Flip clock time 14 ↔ 0", C.TX3, function()
        Lighting.ClockTime = Lighting.ClockTime > 6 and 0 or 14
    end)
    addButton(P, "Remove Fog", "Set FogEnd to 1e6", C.TX3, function()
        Lighting.FogEnd=1e6; notify("Fog","Removed",2)
    end)
end

-- ══════════════════════════════════════════════════════════════════════════════
--  TAB: MOVE
-- ══════════════════════════════════════════════════════════════════════════════
do
    local P=tabPages["move"]
    secHeader(P, "SPEED")

    local SPEEDS={{16,"Default"},{24,"Fast"},{32,"Faster"},{50,"Sprint"},{75,"Turbo"},{120,"Insane"}}
    local speedCard = Instance.new("Frame", P)
    speedCard.Size=UDim2.new(1,0,0,78); speedCard.BackgroundColor3=C.CARD
    speedCard.BorderSizePixel=0; corner(speedCard,10); speedCard.LayoutOrder=nextLo(); stroke(speedCard,C.BORDER)
    local spHdr=Instance.new("TextLabel",speedCard); spHdr.Size=UDim2.new(1,0,0,18); spHdr.Position=UDim2.new(0,12,0,6)
    spHdr.BackgroundTransparency=1; spHdr.Text="WalkSpeed: "..settings.speed; spHdr.TextColor3=C.TX
    spHdr.Font=Enum.Font.GothamSemibold; spHdr.TextSize=12; spHdr.TextXAlignment=Enum.TextXAlignment.Left
    local spRow=Instance.new("Frame",speedCard); spRow.Size=UDim2.new(1,-24,0,24); spRow.Position=UDim2.new(0,12,0,26)
    spRow.BackgroundTransparency=1
    local spLL=Instance.new("UIListLayout",spRow); spLL.FillDirection=Enum.FillDirection.Horizontal; spLL.Padding=UDim.new(0,5)
    for i, sv in ipairs(SPEEDS) do
        local sf=Instance.new("Frame",spRow); sf.Size=UDim2.new(0,46,0,24); sf.BackgroundColor3=C.CARD2; sf.BorderSizePixel=0; corner(sf,7); sf.LayoutOrder=i
        local sl=Instance.new("TextLabel",sf); sl.Size=UDim2.new(1,0,0.55,0); sl.BackgroundTransparency=1
        sl.Text=tostring(sv[1]); sl.TextColor3=C.TX3; sl.Font=Enum.Font.GothamBold; sl.TextSize=10; sl.TextXAlignment=Enum.TextXAlignment.Center
        local sl2=Instance.new("TextLabel",sf); sl2.Size=UDim2.new(1,0,0.45,0); sl2.Position=UDim2.new(0,0,0.55,0)
        sl2.BackgroundTransparency=1; sl2.Text=sv[2]; sl2.TextColor3=C.TX3
        sl2.Font=Enum.Font.Gotham; sl2.TextSize=8; sl2.TextXAlignment=Enum.TextXAlignment.Center
        local sb=Instance.new("TextButton",sf); sb.Size=UDim2.new(1,0,1,0); sb.BackgroundTransparency=1; sb.Text=""
        sb.MouseButton1Click:Connect(function()
            settings.speed=sv[1]; setSpeed(sv[1]); saveCfg(); spHdr.Text="WalkSpeed: "..sv[1]
            tw(sf,{BackgroundColor3=C.ACC1},TF_SPRING); tw(sl,{TextColor3=C.WHITE}); tw(sl2,{TextColor3=C.WHITE})
            task.delay(0.4, function() tw(sf,{BackgroundColor3=C.CARD2}); tw(sl,{TextColor3=C.TX3}); tw(sl2,{TextColor3=C.TX3}) end)
        end)
    end
    -- reset button
    local rsBtn=Instance.new("TextButton",speedCard); rsBtn.Size=UDim2.new(0,60,0,20); rsBtn.Position=UDim2.new(1,-72,0,52)
    rsBtn.BackgroundColor3=C.CARD2; rsBtn.Text="Reset"; rsBtn.TextColor3=C.TX3
    rsBtn.Font=Enum.Font.Gotham; rsBtn.TextSize=10; rsBtn.BorderSizePixel=0; corner(rsBtn,6)
    rsBtn.MouseButton1Click:Connect(function()
        settings.speed=16; setSpeed(16); saveCfg(); spHdr.Text="WalkSpeed: 16"
    end)

    secHeader(P, "MOVEMENT")
    addToggle(P, "Fly  (WASD + Space/Shift)", "BodyVelocity free flight", settings.fly, function(on)
        fly(on); settings.fly=on; saveCfg()
    end)
    addToggle(P, "Infinite Jump", "Jump again while in air", settings.infJump, function(on)
        infJump(on); settings.infJump=on; saveCfg()
    end)
    addToggle(P, "Noclip", "Phase through all parts", settings.noclip, function(on)
        noclip(on); settings.noclip=on; saveCfg()
    end)
    addToggle(P, "Low Gravity  (0.4×)", "workspace.Gravity = 70", false, function(on)
        workspace.Gravity = on and 70 or 196.2
    end)
    addToggle(P, "Zero Gravity", "workspace.Gravity = 2", false, function(on)
        workspace.Gravity = on and 2 or 196.2
    end)

    secHeader(P, "TELEPORT")
    addButton(P, "TP to Ball", "Jump to ball position +5Y", C.ACC1, function()
        local b=findBall() or scanForBall(); local hrp=getHRP()
        if b and hrp then hrp.CFrame=CFrame.new(b.Position+Vector3.new(0,5,0))
        else notify("TP","Ball not found",2) end
    end)
    addButton(P, "TP to Nearest Player", "Teleport beside closest enemy", C.ACC3, function()
        local hrp=getHRP(); if not hrp then return end
        local best,bd=nil,math.huge
        for _, p in pairs(Players:GetPlayers()) do
            if p~=LP and p.Character then
                local r2=p.Character:FindFirstChild("HumanoidRootPart")
                if r2 then local d=(r2.Position-hrp.Position).Magnitude; if d<bd then best=r2; bd=d end end
            end
        end
        if best then hrp.CFrame=CFrame.new(best.Position+Vector3.new(4,0,0))
        else notify("TP","No players found",2) end
    end)
    addButton(P, "TP to Spawn", "Teleport to spawn point", C.TX3, function()
        local hrp=getHRP(); if not hrp then return end
        local sp=workspace:FindFirstChild("SpawnLocation") or workspace:FindFirstChildOfClass("SpawnLocation")
        if sp then hrp.CFrame=CFrame.new(sp.Position+Vector3.new(0,5,0))
        else hrp.CFrame=CFrame.new(Vector3.new(0,10,0)) end
    end)
end

-- ══════════════════════════════════════════════════════════════════════════════
--  TAB: BALL
-- ══════════════════════════════════════════════════════════════════════════════
do
    local P=tabPages["ball"]
    secHeader(P, "BALL FX")
    addToggle(P, "Ball Glow", "Orange PointLight follows ball", settings.ballGlow, function(on)
        ballGlow(on); settings.ballGlow=on; saveCfg()
    end)
    addToggle(P, "Ball Trail", "Animated gradient trail", settings.ballTrail, function(on)
        ballTrail(on); settings.ballTrail=on; saveCfg()
    end)
    addToggle(P, "Ball ESP", "Distance + speed + TTI overlay", settings.ballEsp, function(on)
        ballESP(on); settings.ballEsp=on; saveCfg()
    end)
    addToggle(P, "Neon Ball", "Ball material → Neon", false, function(on)
        local b=findBall() or scanForBall()
        if b then b.Material=on and Enum.Material.Neon or Enum.Material.SmoothPlastic end
    end)
    addToggle(P, "Rainbow Ball", "Cycle ball color via HSV", false, function(on)
        if on then
            local hue=0
            ac(RS.Heartbeat:Connect(function()
                local b=findBall() or scanForBall(); if not b then return end
                hue=(hue+2)%360; b.Color=Color3.fromHSV(hue/360,1,1)
            end))
        end
    end)
    addToggle(P, "Giant Ball", "Ball size × 5", false, function(on)
        local b=findBall() or scanForBall()
        if b then b.Size=on and b.Size*5 or b.Size/5 end
    end)

    secHeader(P, "TRAIL COLOR")
    local TRAIL_COLORS={
        {"Purple",Color3.fromRGB(120,80,255)}, {"Blue",Color3.fromRGB(60,180,255)},
        {"Pink",Color3.fromRGB(255,80,180)},   {"Red",Color3.fromRGB(255,80,80)},
        {"Green",Color3.fromRGB(80,220,130)},  {"Gold",Color3.fromRGB(255,200,40)},
        {"White",Color3.fromRGB(255,255,255)}, {"Cyan",Color3.fromRGB(0,240,240)},
    }
    addColorRow(P, "Trail Color", TRAIL_COLORS, function(c2)
        trailColor=c2
        for _, v in pairs(workspace:GetDescendants()) do
            if v:IsA("Trail") and v.Name=="__ABTrail__" then
                v.Color=ColorSequence.new({ColorSequenceKeypoint.new(0,c2),ColorSequenceKeypoint.new(1,Color3.new(1,1,1))})
            end
        end
    end)

    addButton(P, "Highlight Ball (5s)", "SelectionBox outline for 5 seconds", C.YEL, function()
        local b=findBall() or scanForBall()
        if not b then notify("Ball","Not found",2); return end
        local sb=Instance.new("SelectionBox",b); sb.Adornee=b
        sb.Color3=C.YEL; sb.LineThickness=0.07; sb.SurfaceTransparency=0.85; sb.SurfaceColor3=sb.Color3
        task.delay(5, function() if sb and sb.Parent then sb:Destroy() end end)
    end)
end

-- ══════════════════════════════════════════════════════════════════════════════
--  TAB: MISC
-- ══════════════════════════════════════════════════════════════════════════════
do
    local P=tabPages["misc"]
    secHeader(P, "TOOLS")

    addButton(P, "Dump All Remotes", "Print every Remote to F9 console", C.TX3, function()
        local found={}
        for _, v in pairs(game:GetDescendants()) do
            if v:IsA("RemoteEvent") or v:IsA("RemoteFunction") then found[#found+1]=v:GetFullName() end
        end
        table.sort(found)
        print("[Hub] === Remotes ("..#found..") ===")
        for _, n in ipairs(found) do print("  "..n) end
        notify("Remotes","Dumped "..#found.." → F9",3)
    end)

    addButton(P, "Dump NetRayRemotes", "Print NetRayRemotes folder contents", C.TX3, function()
        local nr=game:GetService("ReplicatedStorage"):FindFirstChild("NetRayRemotes")
        if not nr then notify("NetRay","Not found",3); return end
        print("[Hub] NetRayRemotes:")
        for _, v in pairs(nr:GetDescendants()) do
            print("  ["..v.ClassName.."] "..v:GetFullName())
        end
        notify("NetRay","Dumped → F9",3)
    end)

    addButton(P, "getsenv SwordController", "Dump script env for SwordController", CAPS.getsenv and C.TX3 or C.RED, function()
        if not CAPS.getsenv then notify("getsenv","Not available on this executor",3); return end
        local sc; pcall(function() sc=LP.PlayerScripts.Scripts.SwordController end)
        if not sc then notify("getsenv","SwordController not found",3); return end
        local ok2, env = pcall(getsenv, sc); if not (ok2 and env) then notify("getsenv","Failed",3); return end
        for k, v in pairs(env) do pcall(function() print("[Hub] "..tostring(k).." = "..tostring(v)) end) end
        notify("getsenv","Dumped → F9",3)
    end)

    addButton(P, "Copy Load URL", "Print loadstring URL to console", C.ACC1, function()
        local url="loadstring(game:HttpGet(\"https://raw.githubusercontent.com/robloxscripter6245366542/roblox-lua-obscator/claude/session-UDpk7/AnimeBall_Hub.lua\",true))()"
        print("[Hub] "..url)
        setclipboard and pcall(function() setclipboard(url) end)
        notify("URL","Copied to clipboard + console",3)
    end)

    secHeader(P, "PERSISTENCE")
    addButton(P, "Save Settings", "Write config to file", C.GRN, function()
        saveCfg(); notify("Settings","Saved",3)
    end)
    addButton(P, "Load Settings", "Read saved config", C.ACC2, function()
        loadCfg(); notify("Settings","Loaded",3)
    end)
    addToggle(P, "Auto-rejoin on death"..(CAPS.queue_teleport and "" or "  [N/A]"), "Re-execute hub after teleport", false, function(on)
        if not CAPS.queue_teleport then notify("Rejoin","queue_on_teleport unavailable",3); return end
        if on then
            ac(LP.CharacterRemoving:Connect(function()
                task.wait(1)
                pcall(function()
                    queue_on_teleport([[loadstring(game:HttpGet("https://raw.githubusercontent.com/robloxscripter6245366542/roblox-lua-obscator/claude/session-UDpk7/AnimeBall_Hub.lua",true))()]])
                    game:GetService("TeleportService"):Teleport(game.PlaceId, LP)
                end)
            end))
        end
    end)

    secHeader(P, "API STATUS")
    local function apiRow(name, avail)
        addInfo(P, (avail and "✓  " or "✗  ")..name, avail and C.GRN or C.RED,
            avail and Color3.fromRGB(12,22,16) or Color3.fromRGB(22,12,12))
    end
    local apiList={
        {"getgc",CAPS.getgc},{"getsenv",CAPS.getsenv},{"getinstances",CAPS.getinstances},
        {"getconnections",CAPS.getconnections},{"hookmetamethod",CAPS.hookmetamethod},
        {"hookfunction",CAPS.hookfunction},{"firesignal",CAPS.firesignal},
        {"newcclosure",CAPS.newcclosure},{"readfile",CAPS.readfile},{"writefile",CAPS.writefile},
        {"VirtualUser",CAPS.VirtualUser},{"queue_on_teleport",CAPS.queue_teleport},
    }
    for _, a in ipairs(apiList) do apiRow(a[1], a[2]) end
end

-- ══════════════════════════════════════════════════════════════════════════════
--  DRAG
-- ══════════════════════════════════════════════════════════════════════════════
local dragging=false; local dragStart=nil; local winStart=nil
TBAR.InputBegan:Connect(function(i)
    if i.UserInputType==Enum.UserInputType.MouseButton1 or i.UserInputType==Enum.UserInputType.Touch then
        dragging=true; dragStart=i.Position; winStart=WIN.Position
    end
end)
TBAR.InputEnded:Connect(function() dragging=false end)
UIS.InputChanged:Connect(function(i)
    if dragging and (i.UserInputType==Enum.UserInputType.MouseMovement or i.UserInputType==Enum.UserInputType.Touch) then
        local d=i.Position-dragStart
        WIN.Position=UDim2.new(winStart.X.Scale, winStart.X.Offset+d.X, winStart.Y.Scale, winStart.Y.Offset+d.Y)
        SHADOW.Position=WIN.Position+UDim2.new(0,-4,0,-4)
    end
end)

-- ══════════════════════════════════════════════════════════════════════════════
--  MINIMIZE / RESTORE
-- ══════════════════════════════════════════════════════════════════════════════
local minimized = false

-- Floating restore orb
local ORB = Instance.new("Frame", SCR)
ORB.Size=UDim2.new(0,50,0,50); ORB.Position=UDim2.new(0,20,0.5,-25)
ORB.BackgroundColor3=C.ACC1; ORB.BorderSizePixel=0; ORB.Visible=false; corner(ORB,25)
grad(ORB, C.ACC1, C.ACC2, 135)
local ORBL = Instance.new("TextLabel", ORB)
ORBL.Size=UDim2.new(1,0,1,0); ORBL.BackgroundTransparency=1
ORBL.Text="⚡"; ORBL.TextColor3=C.WHITE; ORBL.Font=Enum.Font.GothamBold
ORBL.TextSize=22; ORBL.TextXAlignment=Enum.TextXAlignment.Center
local ORB_BTN = Instance.new("TextButton", ORB)
ORB_BTN.Size=UDim2.new(1,0,1,0); ORB_BTN.BackgroundTransparency=1; ORB_BTN.Text=""
-- Pulse animation on orb
task.spawn(function()
    local s=true
    while ORB and ORB.Parent do
        if minimized then
            tw(ORB, {BackgroundTransparency=s and 0 or 0.25}, TF_MED)
            s=not s; task.wait(0.8)
        else task.wait(0.1) end
    end
end)

-- Orb drag
local orbDrag=false; local orbDS=nil; local orbPS=nil
ORB.InputBegan:Connect(function(i)
    if i.UserInputType==Enum.UserInputType.MouseButton1 or i.UserInputType==Enum.UserInputType.Touch then
        orbDrag=true; orbDS=i.Position; orbPS=ORB.Position
    end
end)
ORB.InputEnded:Connect(function() orbDrag=false end)
UIS.InputChanged:Connect(function(i)
    if orbDrag and (i.UserInputType==Enum.UserInputType.MouseMovement or i.UserInputType==Enum.UserInputType.Touch) then
        local d=i.Position-orbDS
        ORB.Position=UDim2.new(orbPS.X.Scale,orbPS.X.Offset+d.X, orbPS.Y.Scale,orbPS.Y.Offset+d.Y)
    end
end)

local function setMinimized(v)
    minimized=v
    if v then
        tw(WIN,  {Size=UDim2.new(0,372,0,0), BackgroundTransparency=1}, TF_SLOW)
        tw(SHADOW,{BackgroundTransparency=1}, TF_MED)
        task.delay(0.35, function() WIN.Visible=false; SHADOW.Visible=false end)
        ORB.Visible=true
        tw(ORB, {Size=UDim2.new(0,50,0,50), BackgroundTransparency=0}, TF_SPRING)
    else
        WIN.Visible=true; SHADOW.Visible=true
        WIN.Size=UDim2.new(0,372,0,0); WIN.BackgroundTransparency=1
        tw(WIN,  {Size=UDim2.new(0,372,0,530), BackgroundTransparency=0}, TF_SLOW)
        tw(SHADOW,{BackgroundTransparency=0.55}, TF_MED)
        tw(ORB,  {Size=UDim2.new(0,0,0,0)}, TF_MED)
        task.delay(0.2, function() ORB.Visible=false end)
    end
end

MINBTN.MouseButton1Click:Connect(function() setMinimized(true) end)
ORB_BTN.MouseButton1Click:Connect(function() if not orbDrag then setMinimized(false) end end)

-- ── Keybind: Insert or RShift to toggle ──────────────────────────────────────
UIS.InputBegan:Connect(function(i, gpe)
    if not gpe then
        if i.KeyCode==Enum.KeyCode.Insert or i.KeyCode==Enum.KeyCode.RightShift then
            setMinimized(not minimized)
        end
    end
end)

-- ── Open animation ────────────────────────────────────────────────────────────
WIN.Size=UDim2.new(0,0,0,0); WIN.BackgroundTransparency=1
task.wait(0.05)
WIN.Size=UDim2.new(0,372,0,0); WIN.Visible=true
tw(WIN, {Size=UDim2.new(0,372,0,530), BackgroundTransparency=0}, TF_SLOW)

-- ── Show first tab ────────────────────────────────────────────────────────────
task.wait(0.1)
showTab("parry")

-- ── Apply saved settings ──────────────────────────────────────────────────────
if settings.ballGlow   then ballGlow(true)    end
if settings.ballTrail  then ballTrail(true)   end
if settings.ballEsp    then ballESP(true)     end
if settings.esp        then esp(true)         end
if settings.fly        then fly(true)         end
if settings.god        then godMode(true)     end
if settings.infJump    then infJump(true)     end
if settings.noclip     then noclip(true)      end
if settings.fullbright then fullbright(true)  end
if settings.speed~=16  then setSpeed(settings.speed) end

notify("Anime Ball Hub", "v4.0 loaded  ·  "..capScore.." APIs  ·  RShift to hide", 5)

end)
if not ok then
    pcall(function()
        game:GetService("StarterGui"):SetCore("SendNotification",
            {Title="Hub Error", Text=tostring(err):sub(1,120), Duration=10})
    end)
    warn("[Hub v4.0] STARTUP ERROR:", err)
end
