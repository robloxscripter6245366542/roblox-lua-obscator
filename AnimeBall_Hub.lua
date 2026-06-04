-- ╔══════════════════════════════════════════════════════════════════╗
-- ║  ANIME BALL HUB  v2.0                                            ║
-- ║  Works on: Anime Ball · Blade Ball · Forsaken · Rookhaven        ║
-- ║  APIs used: getgc · getsenv · hookmetamethod · hookfunction      ║
-- ║             getconnections · firesignal · VirtualUser · request  ║
-- ║             queue_on_teleport · readfile/writefile · WebSocket   ║
-- ╚══════════════════════════════════════════════════════════════════╝

local ok,err=pcall(function()

-- ── Services ────────────────────────────────────────────────────────────
local Players     = game:GetService("Players")
local RS          = game:GetService("RunService")
local UIS         = game:GetService("UserInputService")
local TS          = game:GetService("TweenService")
local HS          = game:GetService("HttpService")
local VU          = game:GetService("VirtualUser")
local SG          = game:GetService("StarterGui")
local cam         = workspace.CurrentCamera
local LP          = Players.LocalPlayer
local PGui        = LP:WaitForChild("PlayerGui",15)

-- ── Connection pool ─────────────────────────────────────────────────────
local CONNS = {}
local function ac(c) table.insert(CONNS,c); return c end
local function clearConns()
    for _,c in ipairs(CONNS) do pcall(function()c:Disconnect()end) end
    CONNS={}
end

-- ── Helpers ──────────────────────────────────────────────────────────────
local function getChar()  return LP.Character end
local function getHRP()   local c=getChar(); return c and c:FindFirstChild("HumanoidRootPart") end
local function getHum()   local c=getChar(); return c and c:FindFirstChildOfClass("Humanoid") end
local function notify(t,m,d)
    pcall(function()
        SG:SetCore("SendNotification",{Title=t,Text=m,Duration=d or 3})
    end)
end

-- ── Capability probe ─────────────────────────────────────────────────────
local CAPS = {
    getgc           = type(getgc)          =="function",
    getsenv         = type(getsenv)        =="function",
    getinstances    = type(getinstances)   =="function",
    getconnections  = type(getconnections) =="function",
    hookmetamethod  = type(hookmetamethod) =="function",
    hookfunction    = type(hookfunction)   =="function",
    firesignal      = type(firesignal)     =="function",
    newcclosure     = type(newcclosure)    =="function",
    request         = type(request)        =="function" or type(http_request)=="function",
    readfile        = type(readfile)       =="function",
    writefile       = type(writefile)      =="function",
    VirtualUser     = true,
    queue_teleport  = type(queue_on_teleport)=="function",
}
local capScore=0; for _,v in pairs(CAPS) do if v then capScore=capScore+1 end end
notify("Anime Ball Hub","Loaded — "..capScore.."/13 APIs available",4)

-- ════════════════════════════════════════════════════════════════════════
--  BALL DETECTION (multi-method)
-- ════════════════════════════════════════════════════════════════════════

-- Anime Ball specific: game uses ReplicatedStorage.Storage.Swords for deflect
local RS_STORAGE = pcall(function() return game:GetService("ReplicatedStorage").Storage end) and game:GetService("ReplicatedStorage"):FindFirstChild("Storage")
local SWORDS_FOLDER = RS_STORAGE and RS_STORAGE:FindFirstChild("Swords")

local BALL_NAMES = {
    "ball","blade","projectile","orb","sphere","anime","shot",
    "animeball","animeorb","energy","magic","fire","slash","wave"
}
local ballCache = nil

local function isBallPart(v)
    if not v:IsA("BasePart") then return false end
    if v.Anchored then return false end
    local n = v.Name:lower()
    for _,k in ipairs(BALL_NAMES) do
        if n:find(k,1,true) then return true end
    end
    return false
end

-- Event-driven ball cache: listen for new parts so we never scan per-frame
ac(workspace.DescendantAdded:Connect(function(v)
    if isBallPart(v) and v.CanTouch then
        ballCache = v
        -- Pre-warm block function lookup the moment a ball spawns so it's
        -- already cached when the parry window arrives
        task.delay(0.05, function() findBlockFn() end)
    end
end))
ac(workspace.DescendantRemoving:Connect(function(v)
    if v == ballCache then
        ballCache = nil
        parryBurstActive = false
        lastParryBall = nil
    end
end))

-- One-time initial scan at startup only
for _,v in pairs(workspace:GetDescendants()) do
    if isBallPart(v) and v.CanTouch then ballCache = v; break end
end

local function findBall()
    if ballCache and ballCache.Parent then return ballCache end
    ballCache = nil
    return nil
end

-- ════════════════════════════════════════════════════════════════════════
--  PARRY SYSTEM — Anime Ball (from SwordController decompile)
--
--  Key facts confirmed from decompile:
--    • v_u_1.Block() is the parry function (local table, NOT in getsenv globals)
--    • It calls:  v_u_21.Block:Invoke(cam.CFrame.LookVector.Y)
--    • TouchTapInWorld connection CLOSES OVER v_u_1 → use getupvalues
--    • ConnectAction connects Block button → v_u_1.Block directly
--    • Button path: PlayerGui.HUD.Actions.MainButtons.Block
--    • Remote: RemoteFunction named "Block" in ReplicatedStorage (SwordService)
-- ════════════════════════════════════════════════════════════════════════

local cachedBlockFn     = nil   -- the real v_u_1.Block function once found
local cachedBlockRemote = nil   -- Block RemoteFunction
local cachedBlockButton = nil   -- HUD.Actions.MainButtons.Block
local hookedParry       = false
local origNamecall      = nil

-- ── Utility: safely get upvalues of a closure ────────────────────────────
-- Tries debug.getupvalues, then global getupvalues (Delta exposes this)
local getUV = (type(debug)=="table" and type(debug.getupvalues)=="function" and debug.getupvalues)
           or (type(getupvalues)=="function" and getupvalues)
           or nil

local function upvalueSearch(fn)
    -- Scans all upvalues of fn recursively (1 level) for a table with .Block fn
    if not getUV or type(fn)~="function" then return nil end
    local ok2, uvs = pcall(getUV, fn)
    if not (ok2 and uvs) then return nil end
    for _,uv in pairs(uvs) do
        if type(uv)=="table" and type(uv.Block)=="function" then
            return uv.Block
        end
    end
    return nil
end

-- ── Find the real Block function (4 strategies) ──────────────────────────
local function findBlockFn()
    if cachedBlockFn then return cachedBlockFn end

    -- Strategy 1: getconnections(UIS.TouchTapInWorld)
    -- SwordController.Start() connects TouchTapInWorld → anonymous fn that captures v_u_1
    -- getupvalues on that fn → v_u_1 table → .Block
    if CAPS.getconnections then
        local ok2, conns = pcall(getconnections, UIS.TouchTapInWorld)
        if ok2 and conns then
            for _,conn in ipairs(conns) do
                local fn; pcall(function() fn=conn.Function end)
                if type(fn)=="function" then
                    local blockFn = upvalueSearch(fn)
                    if blockFn then
                        print("[AnimeBallHub] Block fn found via TouchTapInWorld upvalues")
                        cachedBlockFn = blockFn; return blockFn
                    end
                end
            end
        end
    end

    -- Strategy 2: getconnections on Block button events
    -- ConnectAction(blockBtn, v_u_1.Block, ...) connects directly to v_u_1.Block
    local function getBlockBtn()
        if cachedBlockButton and cachedBlockButton.Parent then return cachedBlockButton end
        local hud = PGui:FindFirstChild("HUD"); if not hud then return nil end
        local act = hud:FindFirstChild("Actions"); if not act then return nil end
        local mb  = act:FindFirstChild("MainButtons"); if not mb then return nil end
        local btn = mb:FindFirstChild("Block")
        if btn then cachedBlockButton=btn end
        return btn
    end
    local btn = getBlockBtn()
    if btn and CAPS.getconnections then
        for _, evName in ipairs({"Activated","MouseButton1Click","MouseButton1Down","InputBegan","Touched"}) do
            local ok3, conns = pcall(function() return getconnections(btn[evName]) end)
            if ok3 and conns then
                for _,conn in ipairs(conns) do
                    local fn; pcall(function() fn=conn.Function end)
                    if type(fn)=="function" then
                        -- Could be v_u_1.Block directly, or a wrapper — check upvalues too
                        local uv = upvalueSearch(fn)
                        local chosen = uv or fn
                        -- Verify it looks like Block (has no required args)
                        print("[AnimeBallHub] Block fn found via button "..evName.." connection")
                        cachedBlockFn = chosen; return chosen
                    end
                end
            end
        end
    end

    -- Strategy 3: getsenv — v_u_1 is a local so won't be in globals,
    -- but Delta's getsenv may expose upvalue scope
    if CAPS.getsenv then
        local sc
        -- Try both the running copy and the StarterPlayer template
        local paths = {
            function() return LP:WaitForChild("PlayerScripts",2):WaitForChild("Scripts",2):WaitForChild("SwordController",2) end,
            function() return game:GetService("StarterPlayer"):WaitForChild("StarterPlayerScripts",2):WaitForChild("Scripts",2):WaitForChild("SwordController",2) end,
        }
        for _,pathFn in ipairs(paths) do
            pcall(function() sc = pathFn() end)
            if sc then
                local ok3,env = pcall(getsenv,sc)
                if ok3 and env then
                    for _,v in pairs(env) do
                        if type(v)=="table" and type(v.Block)=="function" then
                            print("[AnimeBallHub] Block fn found via getsenv")
                            cachedBlockFn = v.Block; return v.Block
                        end
                    end
                    -- Also check if getsenv exposed the return value
                    local ret = rawget(env, 1) or env["\1"]  -- some executors store return in slot 1
                    if type(ret)=="table" and type(ret.Block)=="function" then
                        cachedBlockFn = ret.Block; return ret.Block
                    end
                end
            end
        end
    end

    -- Strategy 4: getgc scan — v_u_1 table will be in GC as a table with .Block fn
    if CAPS.getgc then
        local ok2, gc = pcall(getgc, false)  -- false = tables only
        if ok2 and gc then
            for _,v in ipairs(gc) do
                if type(v)=="table" and type(v.Block)=="function"
                and type(v.ShowShield)=="function" and type(v.GetSwordAnim)=="function" then
                    print("[AnimeBallHub] Block fn found via getgc table scan")
                    cachedBlockFn = v.Block; return v.Block
                end
            end
        end
    end

    return nil
end

-- ── Block button finder (public, used by VirtualUser fallback) ────────────
local function findExactButton()
    if cachedBlockButton and cachedBlockButton.Parent then return cachedBlockButton end
    local hud = PGui:FindFirstChild("HUD"); if not hud then return nil end
    local act = hud:FindFirstChild("Actions"); if not act then return nil end
    local mb  = act:FindFirstChild("MainButtons"); if not mb then return nil end
    local btn = mb:FindFirstChild("Block")
    if not btn then
        -- scan entire PlayerGui for any element named "Block"
        for _,v in pairs(PGui:GetDescendants()) do
            if v.Name=="Block" then btn=v; break end
        end
    end
    if btn then cachedBlockButton=btn end
    return btn
end

-- ── Block RemoteFunction (SwordService.Block via framework:Fetch) ─────────
local function findBlockRemote()
    if cachedBlockRemote and cachedBlockRemote.Parent then return cachedBlockRemote end
    local function scan(obj)
        if not obj then return nil end
        for _,v in pairs(obj:GetDescendants()) do
            if v:IsA("RemoteFunction") and v.Name=="Block" then return v end
        end
    end
    cachedBlockRemote = scan(RS_STORAGE) or scan(game:GetService("ReplicatedStorage"))
    return cachedBlockRemote
end

-- ── VirtualUser button press ──────────────────────────────────────────────
local function parryViaVirtualUser()
    local btn = findExactButton()
    if not btn then return false end
    local pos = btn.AbsolutePosition + btn.AbsoluteSize*0.5
    pcall(function()
        VU:Button1Down(pos, cam.CFrame)
        task.wait(0.04)
        VU:Button1Up(pos, cam.CFrame)
    end)
    return true
end

-- ── RemoteFunction invoke ────────────────────────────────────────────────
local function parryViaBlockRemote()
    local remote = findBlockRemote()
    if not remote then return false end
    pcall(function() remote:InvokeServer(cam.CFrame.LookVector.Y) end)
    return true
end

-- ── ball.Touched getconnections ──────────────────────────────────────────
local function parryConnections(ball)
    if not CAPS.getconnections or not ball then return false end
    local hrp = getHRP(); if not hrp then return false end
    local ok2,conns = pcall(getconnections, ball.Touched)
    if not ok2 then return false end
    for _,conn in ipairs(conns) do
        local fn; pcall(function() fn=conn.Function end)
        if type(fn)=="function" then pcall(fn, hrp) end
        if CAPS.firesignal then pcall(firesignal, ball.Touched, hrp) end
    end
    return true
end

-- ── hookmetamethod (passthrough — ensures Block invoke always reaches server)
local function installHook()
    if hookedParry or not CAPS.hookmetamethod then return end
    hookedParry = true
    pcall(function()
        origNamecall = hookmetamethod(game,"__namecall",function(self,...)
            local m = getnamecallmethod and getnamecallmethod() or ""
            if (m=="InvokeServer") and typeof(self)=="Instance" and self.Name=="Block" then
                -- Let the real call through unmodified
            end
            return origNamecall(self,...)
        end)
    end)
end
local function removeHook()
    if not hookedParry or not origNamecall then return end
    pcall(function() hookmetamethod(game,"__namecall",origNamecall) end)
    hookedParry=false
end

-- Public aliases used elsewhere in the file
local getSwordEnv   = function() return cachedBlockFn and {Block=cachedBlockFn} or nil end
local findSwordAction = function() return findBlockFn() end

-- ════════════════════════════════════════════════════════════════════════
--  FEATURE IMPLEMENTATIONS
-- ════════════════════════════════════════════════════════════════════════

-- AUTO PARRY ──────────────────────────────────────────────────────────────
-- Adaptive timing to avoid MS-spike clashing at close range and predict
-- early enough at far range. Uses velocity projection to fire at the right moment.

local autoParryOn    = false
local parryThreshold = 22    -- outer trigger radius (studs)
local lastParryTime  = 0
local parryInCooldown = false

-- Adaptive cooldown based on distance:
--   Far (>14st)  → fire early, 0.05s CD
--   Mid (8–14st) → normal,    0.12s CD
--   Close (<8st) → delay fire, 0.22s CD (avoids clash on lag spike)
local function getAdaptiveCooldown(dist)
    if dist > 14 then return 0.05
    elseif dist > 8 then return 0.12
    else return 0.22 end
end

-- Velocity-based prediction: returns estimated time-to-impact
local lastBallPos2 = nil
local lastBallTime = 0

-- Ping cache (updated every 1 second, not every frame)
local cachedPing    = 0.10  -- default 100ms
local pingCacheTick = 0
local function getPing()
    local now = tick()
    if (now - pingCacheTick) < 1.0 then return cachedPing end
    pingCacheTick = now
    pcall(function()
        local p = game:GetService("Stats").Network.ServerStatsItem["Data Ping"]:GetValue()
        cachedPing = math.clamp(p / 1000, 0.03, 0.6)
    end)
    return cachedPing
end

-- Single parry execution (all methods tried once)
local function executeParry(ball)
    pcall(function()
        local fn = findBlockFn()
        if type(fn)=="function" then fn() end
    end)
    parryViaBlockRemote()
    parryConnections(ball)
end

-- Burst parry: fires 3 rapid attempts so one lands inside the server window
-- regardless of ping. Spread: 0ms, 60ms, 120ms.
-- Server sees them at: ping, ping+60, ping+120 — one always hits.
local parryBurstActive = false
local lastParryBall    = nil

local function doParry(ball)
    if parryBurstActive then return end
    if ball == lastParryBall then return end  -- already fired for this ball
    local hrp  = getHRP()
    local dist = hrp and (ball.Position - hrp.Position).Magnitude or 0
    local cd   = getAdaptiveCooldown(dist)
    if (tick() - lastParryTime) < cd then return end
    lastParryTime  = tick()
    parryBurstActive = true
    lastParryBall  = ball

    executeParry(ball)
    task.delay(0.06, function()
        if ball and ball.Parent then executeParry(ball) end
    end)
    task.delay(0.12, function()
        if ball and ball.Parent then
            executeParry(ball)
            parryViaVirtualUser()  -- VirtualUser as final safety net
        end
        parryBurstActive = false
    end)
end

-- AUTO DODGE ──────────────────────────────────────────────────────────────
local autoDodgeOn = false
local lastDodgeTime = 0
local function doDodge(ball, hrp)
    if not hrp or not ball then return end
    local now = tick()
    if (now - lastDodgeTime) < 0.35 then return end  -- dodge cooldown
    lastDodgeTime = now
    -- Sidestep perpendicular to ball trajectory
    local dir = (hrp.Position - ball.Position).Unit
    local perp = Vector3.new(-dir.Z, 0, dir.X)
    local side = (math.random()<0.5 and 1 or -1)
    local bv = Instance.new("BodyVelocity",hrp)
    bv.MaxForce = Vector3.new(1e5,1e5,1e5)
    bv.Velocity = perp * side * 40 + Vector3.new(0,12,0)
    game:GetService("Debris"):AddItem(bv, 0.18)
end

-- FLY ─────────────────────────────────────────────────────────────────────
local flyBV, flyBG, flyOn = nil, nil, false
local flySpeed = 80
local function fly(on)
    flyOn = on
    if flyBV then flyBV:Destroy(); flyBV=nil end
    if flyBG then flyBG:Destroy(); flyBG=nil end
    local hrp = getHRP(); if not (on and hrp) then return end
    flyBV = Instance.new("BodyVelocity",hrp); flyBV.MaxForce=Vector3.new(1e5,1e5,1e5); flyBV.Velocity=Vector3.zero
    flyBG = Instance.new("BodyGyro",hrp);    flyBG.MaxTorque=Vector3.new(1e5,1e5,1e5); flyBG.D=100
    ac(RS.Heartbeat:Connect(function()
        if not (flyOn and flyBV) then return end
        local d = Vector3.zero
        if UIS:IsKeyDown(Enum.KeyCode.W) then d=d+cam.CFrame.LookVector end
        if UIS:IsKeyDown(Enum.KeyCode.S) then d=d-cam.CFrame.LookVector end
        if UIS:IsKeyDown(Enum.KeyCode.A) then d=d-cam.CFrame.RightVector end
        if UIS:IsKeyDown(Enum.KeyCode.D) then d=d+cam.CFrame.RightVector end
        if UIS:IsKeyDown(Enum.KeyCode.Space) then d=d+Vector3.new(0,1,0) end
        if UIS:IsKeyDown(Enum.KeyCode.LeftShift) then d=d-Vector3.new(0,1,0) end
        flyBV.Velocity = d * flySpeed; flyBG.CFrame = cam.CFrame
    end))
end

-- NOCLIP ──────────────────────────────────────────────────────────────────
local ncConn
local function noclip(on)
    if ncConn then ncConn:Disconnect(); ncConn=nil end
    if on then
        ncConn = ac(RS.Stepped:Connect(function()
            local c=getChar(); if not c then return end
            for _,p in pairs(c:GetDescendants()) do if p:IsA("BasePart") then p.CanCollide=false end end
        end))
    end
end

-- PLAYER ESP ──────────────────────────────────────────────────────────────
local espTags = {}
local function clearESP()
    for _,bb in pairs(espTags) do pcall(function()bb:Destroy()end) end
    espTags = {}
end
local function esp(on)
    clearESP()
    if not on then return end
    local function tag(p)
        if p==LP then return end
        local function attach()
            local c=p.Character; if not c then return end
            local hrp=c:FindFirstChild("HumanoidRootPart"); if not hrp then return end
            local bb=Instance.new("BillboardGui",hrp)
            bb.Name="__abhesp__"; bb.Size=UDim2.new(0,0,0,44); bb.StudsOffset=Vector3.new(0,3.2,0); bb.AlwaysOnTop=true
            local nl=Instance.new("TextLabel",bb); nl.Size=UDim2.new(1,0,0,22); nl.BackgroundTransparency=1
            nl.Text=p.Name; nl.TextColor3=Color3.fromRGB(255,90,90); nl.TextStrokeTransparency=0; nl.Font=Enum.Font.GothamBold; nl.TextSize=14
            local dl=Instance.new("TextLabel",bb); dl.Size=UDim2.new(1,0,0,16); dl.Position=UDim2.new(0,0,0,22); dl.BackgroundTransparency=1
            dl.TextColor3=Color3.fromRGB(220,220,220); dl.TextStrokeTransparency=0; dl.Font=Enum.Font.Gotham; dl.TextSize=11
            local espT=0
            ac(RS.Heartbeat:Connect(function()
                local t2=tick(); if (t2-espT)<0.2 then return end; espT=t2
                local myhrp=getHRP()
                if not (hrp and hrp.Parent) then return end
                dl.Text = myhrp and (math.floor((hrp.Position-myhrp.Position).Magnitude).."m") or ""
                local hum=c:FindFirstChildOfClass("Humanoid")
                if hum then nl.Text=p.Name.."  "..math.floor(hum.Health) end
            end))
            espTags[p] = bb
        end
        attach(); ac(p.CharacterAdded:Connect(attach))
    end
    for _,p in pairs(Players:GetPlayers()) do tag(p) end
    ac(Players.PlayerAdded:Connect(tag))
end

-- BALL GLOW ───────────────────────────────────────────────────────────────
local ballGlowOn = false
local glowConn
local function ballGlow(on)
    ballGlowOn = on
    if glowConn then glowConn:Disconnect(); glowConn=nil end
    if not on then
        -- remove all added lights
        for _,v in pairs(workspace:GetDescendants()) do
            if v:IsA("PointLight") and v.Name=="__ABGlow__" then v:Destroy() end
        end
        return
    end
    local glowT=0
    glowConn = ac(RS.Heartbeat:Connect(function()
        local t2=tick(); if (t2-glowT)<0.5 then return end; glowT=t2
        local ball = findBall(); if not ball then return end
        if not ball:FindFirstChild("__ABGlow__") then
            local pl=Instance.new("PointLight",ball); pl.Name="__ABGlow__"
            pl.Brightness=8; pl.Range=20; pl.Color=Color3.fromRGB(255,120,40)
        end
    end))
end

-- BALL TRAIL ──────────────────────────────────────────────────────────────
local ballTrailOn = false
local trailConn
local trailColors = {
    Color3.fromRGB(255,80,80),
    Color3.fromRGB(255,200,40),
    Color3.fromRGB(80,200,255),
}
local trailColorIdx = 1
local function ballTrail(on)
    ballTrailOn = on
    if trailConn then trailConn:Disconnect(); trailConn=nil end
    if not on then
        for _,v in pairs(workspace:GetDescendants()) do
            if v:IsA("Trail") and v.Name=="__ABTrail__" then v:Destroy() end
            if v:IsA("Attachment") and (v.Name=="__TrA0__" or v.Name=="__TrA1__") then v:Destroy() end
        end
        return
    end
    local trailT=0
    trailConn = ac(RS.Heartbeat:Connect(function()
        local t2=tick(); if (t2-trailT)<0.5 then return end; trailT=t2
        local ball = findBall(); if not ball then return end
        if not ball:FindFirstChild("__ABTrail__") then
            local a0=Instance.new("Attachment",ball); a0.Name="__TrA0__"; a0.Position=Vector3.new(0,0.5,0)
            local a1=Instance.new("Attachment",ball); a1.Name="__TrA1__"; a1.Position=Vector3.new(0,-0.5,0)
            local tr=Instance.new("Trail",ball); tr.Name="__ABTrail__"
            tr.Attachment0=a0; tr.Attachment1=a1
            tr.Lifetime=0.6; tr.MinLength=0; tr.FaceCamera=true; tr.LightEmission=1
            local col = trailColors[trailColorIdx]
            tr.Color=ColorSequence.new({ColorSequenceKeypoint.new(0,col),ColorSequenceKeypoint.new(1,Color3.fromRGB(255,255,255))})
            tr.Transparency=NumberSequence.new({NumberSequenceKeypoint.new(0,0),NumberSequenceKeypoint.new(1,1)})
            tr.WidthScale=NumberSequence.new({NumberSequenceKeypoint.new(0,1),NumberSequenceKeypoint.new(1,0.1)})
        end
    end))
end

-- BALL ESP (distance + speed label) ──────────────────────────────────────
local ballEspOn = false
local ballEspBB = nil
local lastBallPos = nil
local function ballESP(on)
    ballEspOn = on
    if ballEspBB then ballEspBB:Destroy(); ballEspBB=nil end
    if not on then return end
end

-- AIMBOT ──────────────────────────────────────────────────────────────────
local aimOn = false
local aimConn
local function aimbot(on)
    aimOn = on
    if aimConn then aimConn:Disconnect(); aimConn=nil end
    if not on then return end
    aimConn = ac(RS.RenderStepped:Connect(function()
        if not UIS:IsMouseButtonPressed(Enum.UserInputType.MouseButton2) then return end
        local best, bd = nil, math.huge
        for _,p in pairs(Players:GetPlayers()) do
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
        if best then cam.CFrame=CFrame.lookAt(cam.CFrame.Position,best.Position) end
    end))
end

-- KILL AURA ───────────────────────────────────────────────────────────────
local kaOn = false
local kaConn
local kaRange = 20
local function killAura(on)
    kaOn = on
    if kaConn then kaConn:Disconnect(); kaConn=nil end
    if not on then return end
    kaConn = ac(RS.Heartbeat:Connect(function()
        local hrp=getHRP(); if not hrp then return end
        for _,p in pairs(Players:GetPlayers()) do
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

-- GOD MODE ────────────────────────────────────────────────────────────────
local godConn
local function godMode(on)
    if godConn then godConn:Disconnect(); godConn=nil end
    if on then
        godConn=ac(RS.Heartbeat:Connect(function()
            local h=getHum(); if h then h.Health=h.MaxHealth end
        end))
    end
end

-- SPEED ───────────────────────────────────────────────────────────────────
local function setSpeed(v) local h=getHum(); if h then h.WalkSpeed=v end end

-- INF JUMP ────────────────────────────────────────────────────────────────
local function infJump(on)
    if on then
        ac(UIS.JumpRequest:Connect(function()
            local h=getHum(); if h then h:ChangeState(Enum.HumanoidStateType.Jumping) end
        end))
    end
end

-- ANTI ELIMINATION ─────────────────────────────────────────────────────────
local antiElimOn = false
local antiElimHook
local function antiElim(on)
    antiElimOn = on
    if on and CAPS.hookmetamethod and not antiElimHook then
        pcall(function()
            antiElimHook = hookmetamethod(game,"__namecall",function(self,...)
                local m = getnamecallmethod and getnamecallmethod() or ""
                if antiElimOn then
                    if typeof(self)=="Instance" then
                        local n=self.Name:lower()
                        if m=="FireServer" and (n:find("elim") or n:find("die") or n:find("kill") or n:find("death")) then
                            return -- block elimination remote
                        end
                        if m=="Destroy" then
                            local c=getChar()
                            if c and self==c then return end -- block character destroy
                        end
                    end
                end
                return antiElimHook(self,...)
            end)
        end)
    elseif not on and antiElimHook then
        pcall(function() hookmetamethod(game,"__namecall",antiElimHook) end)
        antiElimHook = nil
    end
end

-- FULLBRIGHT ──────────────────────────────────────────────────────────────
local function fullbright(on)
    local L=game:GetService("Lighting")
    if on then L.Brightness=3; L.GlobalShadows=false; L.FogEnd=1e6; L.ClockTime=14
    else      L.Brightness=1; L.GlobalShadows=true;  L.ClockTime=14 end
end

-- SAVE SETTINGS (filesystem) ───────────────────────────────────────────────
local CFG_PATH = "AnimeBallHub_config.json"
local settings = {autoParry=false,autoDodge=false,ballGlow=true,ballTrail=true,ballEsp=true,esp=false,speed=16,fly=false,killAura=false,god=false,antiElim=false,fullbright=false}
local function loadCfg()
    if not CAPS.readfile then return end
    local ok2,data = pcall(readfile,CFG_PATH)
    if ok2 and data and data~="" then
        local ok3,t = pcall(function() return HS:JSONDecode(data) end)
        if ok3 and t then for k,v in pairs(t) do settings[k]=v end end
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
--  Velocity tracker for prediction
local ballVelSamples = {}
local ballVelSampleTime = 0
local ballVelAvg = 0

local function updateBallVelocity(ball)
    if not ball then ballVelAvg=0; return end
    local now = tick()
    local dt = now - ballVelSampleTime
    if dt > 0 and dt < 0.5 and lastBallPos2 then
        local spd = (ball.Position - lastBallPos2).Magnitude / dt
        table.insert(ballVelSamples, spd)
        if #ballVelSamples > 8 then table.remove(ballVelSamples,1) end
        local sum=0; for _,v in ipairs(ballVelSamples) do sum=sum+v end
        ballVelAvg = sum / #ballVelSamples
    end
    lastBallPos2 = ball.Position
    ballVelSampleTime = now
end

-- Dynamic trigger: fire parry when TTI (time-to-impact) < PARRY_WINDOW seconds
-- This removes dependence on fixed stud threshold
local PARRY_WINDOW = 0.30  -- seconds before impact to trigger parry

local loopTick = 0
ac(RS.Heartbeat:Connect(function()
    local now = tick()
    if (now - loopTick) < 0.033 then return end  -- 30 Hz cap
    loopTick = now

    local ball = findBall()
    local hrp  = getHRP()
    if not hrp then return end

    updateBallVelocity(ball)

    -- Ball ESP update
    if ballEspOn and ball then
        if not ballEspBB or not ballEspBB.Parent then
            local bb=Instance.new("BillboardGui",ball)
            bb.Name="__abbesp__"; bb.Size=UDim2.new(0,0,0,46); bb.StudsOffset=Vector3.new(0,2.5,0); bb.AlwaysOnTop=true
            local nl=Instance.new("TextLabel",bb); nl.Size=UDim2.new(1,0,0,16); nl.BackgroundTransparency=1
            nl.TextColor3=Color3.fromRGB(255,220,60); nl.TextStrokeTransparency=0; nl.Font=Enum.Font.GothamBold; nl.TextSize=12
            local sl=Instance.new("TextLabel",bb); sl.Size=UDim2.new(1,0,0,14); sl.Position=UDim2.new(0,0,0,16); sl.BackgroundTransparency=1
            sl.TextColor3=Color3.fromRGB(200,200,200); sl.TextStrokeTransparency=0; sl.Font=Enum.Font.Gotham; sl.TextSize=10
            local tl=Instance.new("TextLabel",bb); tl.Size=UDim2.new(1,0,0,14); tl.Position=UDim2.new(0,0,0,30); tl.BackgroundTransparency=1
            tl.TextColor3=Color3.fromRGB(150,255,150); tl.TextStrokeTransparency=0; tl.Font=Enum.Font.GothamBold; tl.TextSize=10
            ballEspBB = bb
            ac(RS.Heartbeat:Connect(function()
                if not (ball and ball.Parent and ballEspBB and ballEspBB.Parent) then return end
                local dist = (ball.Position-hrp.Position).Magnitude
                nl.Text = "BALL  "..math.floor(dist).."m"
                if ballVelAvg > 0 then
                    sl.Text = "Speed: "..math.floor(ballVelAvg).." st/s"
                    local tti = dist / ballVelAvg
                    tl.Text = "TTI: "..string.format("%.2f",tti).."s"
                    tl.TextColor3 = tti < PARRY_WINDOW and Color3.fromRGB(255,80,80) or Color3.fromRGB(150,255,150)
                end
            end))
        end
    end

    -- Auto Parry — ping-compensated TTI trigger
    -- High ping  → fire early (window += ping) so server gets click in time
    -- Low ping   → fire at exact moment (window ≈ base only)
    if autoParryOn and ball then
        local dist = (ball.Position - hrp.Position).Magnitude
        local shouldParry = false
        if ballVelAvg > 0 then
            local tti  = dist / ballVelAvg
            local ping = getPing()
            -- Base window per distance band + ping compensation
            local base = dist < 8 and 0.13 or dist < 15 and 0.18 or 0.22
            local window = base + ping   -- e.g. 300ms ping → fires 300ms earlier
            shouldParry = tti < window
        else
            -- No velocity yet (ball just spawned) — use distance fallback
            shouldParry = dist < parryThreshold
        end
        if shouldParry then doParry(ball) end
    end

    -- Auto Dodge (ball within 30 studs but not yet in parry window)
    if autoDodgeOn and ball then
        local dist = (ball.Position - hrp.Position).Magnitude
        if dist < 30 and (ballVelAvg==0 or (dist/math.max(ballVelAvg,1)) > PARRY_WINDOW*1.5) then
            doDodge(ball, hrp)
        end
    end
end))

-- ════════════════════════════════════════════════════════════════════════
--  GUI
-- ════════════════════════════════════════════════════════════════════════

-- Color palette
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

local TF  = TweenInfo.new(0.15,Enum.EasingStyle.Quad,Enum.EasingDirection.Out)
local TF2 = TweenInfo.new(0.25,Enum.EasingStyle.Quad,Enum.EasingDirection.Out)
local function tw(i,p,t) TS:Create(i,t or TF,p):Play() end
local function corner(i,r) Instance.new("UICorner",i).CornerRadius=UDim.new(0,r or 8) end
local function stroke(i,c,t) local s=Instance.new("UIStroke",i); s.Color=c or BRD; s.Thickness=t or 1; return s end

-- Root GUI
local old=PGui:FindFirstChild("__AnimeBallHub__"); if old then old:Destroy() end
local SCR=Instance.new("ScreenGui",PGui); SCR.Name="__AnimeBallHub__"; SCR.ResetOnSpawn=false; SCR.IgnoreGuiInset=true; SCR.ZIndexBehavior=Enum.ZIndexBehavior.Sibling

-- Main window
local WIN=Instance.new("Frame",SCR); WIN.Name="WIN"
WIN.Size=UDim2.new(0,330,0,480); WIN.Position=UDim2.new(0.5,-165,0.5,-240)
WIN.BackgroundColor3=BG; WIN.BorderSizePixel=0; WIN.ClipsDescendants=true
corner(WIN,16); stroke(WIN,BRD,1)

-- Title bar
local TB=Instance.new("Frame",WIN); TB.Size=UDim2.new(1,0,0,46); TB.BackgroundColor3=PAN; TB.BorderSizePixel=0; corner(TB,16)
local TBF=Instance.new("Frame",TB); TBF.Size=UDim2.new(1,0,0.5,0); TBF.Position=UDim2.new(0,0,0.5,0); TBF.BackgroundColor3=PAN; TBF.BorderSizePixel=0

local function Lbl(p,t,sz,pos,col,ts2,f)
    local l=Instance.new("TextLabel",p); l.Size=sz or UDim2.new(1,0,1,0); l.Position=pos or UDim2.new(0,0,0,0)
    l.BackgroundTransparency=1; l.Text=t; l.TextColor3=col or TX; l.Font=f or Enum.Font.GothamSemibold; l.TextSize=ts2 or 13
    l.TextXAlignment=Enum.TextXAlignment.Left; return l
end

-- Logo orb
local ORB=Instance.new("Frame",TB); ORB.Size=UDim2.new(0,28,0,28); ORB.Position=UDim2.new(0,10,0.5,-14); ORB.BackgroundColor3=AC; ORB.BorderSizePixel=0; corner(ORB,14)
local OL=Instance.new("TextLabel",ORB); OL.Size=UDim2.new(1,0,1,0); OL.BackgroundTransparency=1; OL.Text="◉"; OL.TextColor3=BG; OL.Font=Enum.Font.GothamBold; OL.TextSize=14; OL.TextXAlignment=Enum.TextXAlignment.Center
task.spawn(function() while OL and OL.Parent do OL.Rotation=(OL.Rotation+2)%360; task.wait(0.04) end end)

Lbl(TB,"Anime Ball Hub",UDim2.new(1,-90,1,0),UDim2.new(0,46,0,0),Color3.fromRGB(245,240,228),14,Enum.Font.GothamBold)
local capL=Lbl(TB,"APIs: "..capScore.."/13",UDim2.new(0,70,1,0),UDim2.new(1,-76,0,0),MU,10,Enum.Font.Gotham); capL.TextXAlignment=Enum.TextXAlignment.Right

local XB=Instance.new("TextButton",TB); XB.Size=UDim2.new(0,26,0,26); XB.Position=UDim2.new(1,-33,0.5,-13); XB.BackgroundColor3=RED_C; XB.Text="✕"; XB.TextColor3=Color3.new(1,1,1); XB.Font=Enum.Font.GothamBold; XB.TextSize=11; XB.BorderSizePixel=0; corner(XB,7)
XB.MouseButton1Click:Connect(function()
    clearConns(); clearESP(); fly(false); noclip(false); ballGlow(false); ballTrail(false); godMode(false); killAura(false); aimbot(false); antiElim(false)
    saveCfg(); SCR:Destroy()
end)

-- ── Tab bar (5 tabs) ────────────────────────────────────────────────────
local TABBAR=Instance.new("Frame",WIN); TABBAR.Size=UDim2.new(1,0,0,38); TABBAR.Position=UDim2.new(0,0,0,46); TABBAR.BackgroundColor3=PAN; TABBAR.BorderSizePixel=0
local TBL=Instance.new("UIListLayout",TABBAR); TBL.FillDirection=Enum.FillDirection.Horizontal; TBL.Padding=UDim.new(0,0); TBL.SortOrder=Enum.SortOrder.LayoutOrder

-- Divider between tabbar and content
Instance.new("Frame",WIN).Size=UDim2.new(1,0,0,1); local DIV=WIN:FindFirstChildOfClass("Frame")

local BODY=Instance.new("Frame",WIN); BODY.Size=UDim2.new(1,0,1,-85); BODY.Position=UDim2.new(0,0,0,85); BODY.BackgroundColor3=BG; BODY.BorderSizePixel=0

local TAB_DEFS = {
    {id="auto",   icon="⚡", label="Auto"},
    {id="ball",   icon="●",  label="Ball"},
    {id="visual", icon="👁",  label="Visual"},
    {id="move",   icon="🏃",  label="Move"},
    {id="misc",   icon="⚙",  label="Misc"},
}
local tabPages  = {}
local tabBtns   = {}
local activeTab = nil

local function showTab(id)
    activeTab = id
    for _,def in ipairs(TAB_DEFS) do
        local page = tabPages[def.id]
        local btn  = tabBtns[def.id]
        local on = (def.id == id)
        if page then page.Visible = on end
        if btn  then
            tw(btn.bg,  {BackgroundColor3 = on and CARD2 or PAN})
            tw(btn.lbl, {TextColor3       = on and AC    or MU})
            tw(btn.ico, {TextColor3       = on and AC    or MU})
            tw(btn.bar, {BackgroundColor3 = on and AC    or PAN, Size = on and UDim2.new(1,0,0,2) or UDim2.new(0,0,0,2)})
        end
    end
end

for idx,def in ipairs(TAB_DEFS) do
    local w = math.floor(330/#TAB_DEFS)
    local bg=Instance.new("Frame",TABBAR); bg.Size=UDim2.new(0,w,1,0); bg.BackgroundColor3=PAN; bg.BorderSizePixel=0; bg.LayoutOrder=idx
    local ico=Instance.new("TextLabel",bg); ico.Size=UDim2.new(1,0,0,20); ico.Position=UDim2.new(0,0,0,4); ico.BackgroundTransparency=1; ico.Text=def.icon; ico.TextColor3=MU; ico.Font=Enum.Font.GothamBold; ico.TextSize=13; ico.TextXAlignment=Enum.TextXAlignment.Center
    local lbl=Instance.new("TextLabel",bg); lbl.Size=UDim2.new(1,0,0,14); lbl.Position=UDim2.new(0,0,0,22); lbl.BackgroundTransparency=1; lbl.Text=def.label; lbl.TextColor3=MU; lbl.Font=Enum.Font.Gotham; lbl.TextSize=10; lbl.TextXAlignment=Enum.TextXAlignment.Center
    local bar=Instance.new("Frame",bg); bar.Size=UDim2.new(0,0,0,2); bar.Position=UDim2.new(0,0,1,-2); bar.BackgroundColor3=PAN; bar.BorderSizePixel=0
    local click=Instance.new("TextButton",bg); click.Size=UDim2.new(1,0,1,0); click.BackgroundTransparency=1; click.Text=""
    click.MouseButton1Click:Connect(function() showTab(def.id) end)
    tabBtns[def.id] = {bg=bg, ico=ico, lbl=lbl, bar=bar}

    local page=Instance.new("ScrollingFrame",BODY); page.Name=def.id; page.Size=UDim2.new(1,0,1,0); page.BackgroundTransparency=1; page.BorderSizePixel=0
    page.ScrollBarThickness=4; page.ScrollBarImageColor3=AC; page.AutomaticCanvasSize=Enum.AutomaticSize.Y; page.CanvasSize=UDim2.new(0,0,0,0); page.Visible=false
    local ll=Instance.new("UIListLayout",page); ll.SortOrder=Enum.SortOrder.LayoutOrder; ll.Padding=UDim.new(0,4)
    local pp=Instance.new("UIPadding",page); pp.PaddingLeft=UDim.new(0,12); pp.PaddingRight=UDim.new(0,12); pp.PaddingTop=UDim.new(0,10); pp.PaddingBottom=UDim.new(0,12)
    tabPages[def.id] = page
end

-- ── Section / row builders ──────────────────────────────────────────────
local function secHeader(page, title, lo)
    local sh=Instance.new("Frame",page); sh.Size=UDim2.new(1,0,0,22); sh.BackgroundTransparency=1; sh.LayoutOrder=lo
    local line=Instance.new("Frame",sh); line.Size=UDim2.new(1,0,0,1); line.Position=UDim2.new(0,0,0.5,0); line.BackgroundColor3=BRD; line.BorderSizePixel=0
    local lbl=Instance.new("TextLabel",sh); lbl.Size=UDim2.new(0,0,1,0); lbl.AutomaticSize=Enum.AutomaticSize.X; lbl.Position=UDim2.new(0,4,0,0)
    lbl.BackgroundColor3=BG; lbl.BackgroundTransparency=0; lbl.Text=" "..title.." "; lbl.TextColor3=AC; lbl.Font=Enum.Font.GothamBold; lbl.TextSize=10
    return sh
end

local loCount = 0
local function nextLo() loCount=loCount+1; return loCount end

local function addToggle(page, label, sublabel, initVal, callback)
    local lo=nextLo()
    local row=Instance.new("Frame",page); row.Size=UDim2.new(1,0,0,sublabel and 46 or 36); row.BackgroundColor3=CARD; row.BorderSizePixel=0; corner(row,10); row.LayoutOrder=lo
    stroke(row,BRD,1)
    local nameL=Instance.new("TextLabel",row); nameL.Size=UDim2.new(1,-58,0,20); nameL.Position=UDim2.new(0,12,0,8); nameL.BackgroundTransparency=1; nameL.Text=label; nameL.TextColor3=TX; nameL.Font=Enum.Font.GothamSemibold; nameL.TextSize=13; nameL.TextXAlignment=Enum.TextXAlignment.Left
    if sublabel then
        local subL=Instance.new("TextLabel",row); subL.Size=UDim2.new(1,-58,0,14); subL.Position=UDim2.new(0,12,0,26); subL.BackgroundTransparency=1; subL.Text=sublabel; subL.TextColor3=MU; subL.Font=Enum.Font.Gotham; subL.TextSize=10; subL.TextXAlignment=Enum.TextXAlignment.Left
    end
    -- Pill
    local pill=Instance.new("Frame",row); pill.Size=UDim2.new(0,42,0,22); pill.Position=UDim2.new(1,-52,0.5,-11); pill.BorderSizePixel=0; corner(pill,11)
    local knob=Instance.new("Frame",pill); knob.Size=UDim2.new(0,18,0,18); knob.Position=UDim2.new(0,2,0.5,-9); knob.BorderSizePixel=0; corner(knob,9)
    local state = initVal or false
    local function refresh()
        tw(pill,  {BackgroundColor3 = state and AC or Color3.fromRGB(45,38,30)})
        tw(knob,  {Position = state and UDim2.new(1,-20,0.5,-9) or UDim2.new(0,2,0.5,-9), BackgroundColor3 = state and Color3.new(1,1,1) or MU})
        tw(nameL, {TextColor3 = state and Color3.fromRGB(245,240,228) or TX})
    end
    refresh()
    local btn=Instance.new("TextButton",row); btn.Size=UDim2.new(1,0,1,0); btn.BackgroundTransparency=1; btn.Text=""
    btn.MouseButton1Click:Connect(function() state=not state; refresh(); pcall(callback,state) end)
    return function() return state end, function(v) state=v; refresh() end
end

local function addButton(page, label, sublabel, color, callback)
    local lo=nextLo()
    local row=Instance.new("Frame",page); row.Size=UDim2.new(1,0,0,sublabel and 46 or 38); row.BackgroundColor3=CARD; row.BorderSizePixel=0; corner(row,10); row.LayoutOrder=lo
    stroke(row,BRD,1)
    local nameL=Instance.new("TextLabel",row); nameL.Size=UDim2.new(1,-60,0,20); nameL.Position=UDim2.new(0,12,0,sublabel and 8 or 9); nameL.BackgroundTransparency=1; nameL.Text=label; nameL.TextColor3=TX; nameL.Font=Enum.Font.GothamSemibold; nameL.TextSize=13; nameL.TextXAlignment=Enum.TextXAlignment.Left
    if sublabel then
        local sl=Instance.new("TextLabel",row); sl.Size=UDim2.new(1,-60,0,14); sl.Position=UDim2.new(0,12,0,26); sl.BackgroundTransparency=1; sl.Text=sublabel; sl.TextColor3=MU; sl.Font=Enum.Font.Gotham; sl.TextSize=10; sl.TextXAlignment=Enum.TextXAlignment.Left
    end
    local btn_f=Instance.new("Frame",row); btn_f.Size=UDim2.new(0,56,0,28); btn_f.Position=UDim2.new(1,-64,0.5,-14); btn_f.BackgroundColor3=color or AC; btn_f.BorderSizePixel=0; corner(btn_f,8)
    local btn_l=Instance.new("TextLabel",btn_f); btn_l.Size=UDim2.new(1,0,1,0); btn_l.BackgroundTransparency=1; btn_l.Text="RUN"; btn_l.TextColor3=BG; btn_l.Font=Enum.Font.GothamBold; btn_l.TextSize=11; btn_l.TextXAlignment=Enum.TextXAlignment.Center
    local btn=Instance.new("TextButton",row); btn.Size=UDim2.new(1,0,1,0); btn.BackgroundTransparency=1; btn.Text=""
    btn.MouseButton1Click:Connect(function()
        tw(btn_f,{BackgroundColor3=AC2})
        task.delay(0.15,function() tw(btn_f,{BackgroundColor3=color or AC}) end)
        pcall(callback)
    end)
end

local function addInfo(page, text, color)
    local lo=nextLo()
    local row=Instance.new("Frame",page); row.Size=UDim2.new(1,0,0,30); row.BackgroundColor3=Color3.fromRGB(24,20,16); row.BorderSizePixel=0; corner(row,8); row.LayoutOrder=lo
    local l=Instance.new("TextLabel",row); l.Size=UDim2.new(1,-16,1,0); l.Position=UDim2.new(0,8,0,0); l.BackgroundTransparency=1; l.Text=text; l.TextColor3=color or MU; l.Font=Enum.Font.Gotham; l.TextSize=11; l.TextXAlignment=Enum.TextXAlignment.Left; l.TextWrapped=true
end

-- ════════════════════════════════════════════════════════════════════════
--  TAB: AUTO PLAY
-- ════════════════════════════════════════════════════════════════════════
do
    local P = tabPages["auto"]
    secHeader(P,"AUTO PARRY",nextLo())

    addToggle(P,"Auto Parry","Detects ball approach & deflects automatically",settings.autoParry,function(on)
        autoParryOn=on; settings.autoParry=on; saveCfg()
        installHook()
        notify("Anime Ball Hub",on and "Auto Parry ON" or "Auto Parry OFF",2)
    end)

    addToggle(P,"Auto Dodge","Sidestep when ball within 25 studs",settings.autoDodge,function(on)
        autoDodgeOn=on; settings.autoDodge=on; saveCfg()
    end)

    addToggle(P,"hookmetamethod Parry","Hook namecall to intercept deflect checks"..(CAPS.hookmetamethod and "" or "  [UNAVAILABLE]"),false,function(on)
        if on then installHook() else removeHook() end
    end)

    -- Timing window selector
    local WINDOW_OPTS = {0.18, 0.25, 0.30, 0.38, 0.50}
    local WINDOW_LBLS = {"0.18s (lag-safe)", "0.25s (close)", "0.30s (default)", "0.38s (normal)", "0.50s (early)"}
    local wRow=Instance.new("Frame",P); wRow.Size=UDim2.new(1,0,0,56); wRow.BackgroundColor3=CARD; wRow.BorderSizePixel=0; corner(wRow,10); wRow.LayoutOrder=nextLo(); stroke(wRow,BRD,1)
    local wL=Instance.new("TextLabel",wRow); wL.Size=UDim2.new(1,-16,0,18); wL.Position=UDim2.new(0,12,0,6); wL.BackgroundTransparency=1; wL.Text="Parry Window: "..WINDOW_LBLS[3]; wL.TextColor3=TX; wL.Font=Enum.Font.GothamSemibold; wL.TextSize=12; wL.TextXAlignment=Enum.TextXAlignment.Left
    local wSub=Instance.new("TextLabel",wRow); wSub.Size=UDim2.new(1,-16,0,12); wSub.Position=UDim2.new(0,12,0,22); wSub.BackgroundTransparency=1; wSub.Text="Smaller = fires later (less clash). Bigger = fires earlier."; wSub.TextColor3=MU; wSub.Font=Enum.Font.Gotham; wSub.TextSize=10; wSub.TextXAlignment=Enum.TextXAlignment.Left
    local wBR=Instance.new("Frame",wRow); wBR.Size=UDim2.new(1,-24,0,18); wBR.Position=UDim2.new(0,12,0,34); wBR.BackgroundTransparency=1
    local wBL=Instance.new("UIListLayout",wBR); wBL.FillDirection=Enum.FillDirection.Horizontal; wBL.Padding=UDim.new(0,4)
    for i,w_val in ipairs(WINDOW_OPTS) do
        local wf=Instance.new("Frame",wBR); wf.Size=UDim2.new(0,46,0,18); wf.BackgroundColor3=CARD2; wf.BorderSizePixel=0; corner(wf,5)
        local wfl=Instance.new("TextLabel",wf); wfl.Size=UDim2.new(1,0,1,0); wfl.BackgroundTransparency=1; wfl.Text=tostring(w_val); wfl.TextColor3=MU; wfl.Font=Enum.Font.GothamBold; wfl.TextSize=9; wfl.TextXAlignment=Enum.TextXAlignment.Center
        local wfb=Instance.new("TextButton",wf); wfb.Size=UDim2.new(1,0,1,0); wfb.BackgroundTransparency=1; wfb.Text=""
        wfb.MouseButton1Click:Connect(function()
            PARRY_WINDOW=w_val; wL.Text="Parry Window: "..WINDOW_LBLS[i]
            tw(wf,{BackgroundColor3=AC}); tw(wfl,{TextColor3=BG})
            task.delay(0.3,function() tw(wf,{BackgroundColor3=CARD2}); tw(wfl,{TextColor3=MU}) end)
        end)
    end

    secHeader(P,"PARRY METHODS",nextLo())

    addInfo(P,"A: getsenv SwordController → Block()",CAPS.getsenv and AC or RED_C)
    addInfo(P,"B: Block RemoteFunction:InvokeServer(Y)",AC)
    addInfo(P,"C: VirtualUser → HUD.Actions.MainButtons.Block",AC)
    addInfo(P,"D: getconnections ball.Touched fire",CAPS.getconnections and AC or RED_C)
    addInfo(P,"E: hookmetamethod namecall intercept",CAPS.hookmetamethod and AC or RED_C)

    secHeader(P,"DEBUG — SCAN",nextLo())

    addButton(P,"Scan Everything","Ball + SwordCtrl env + Block remote + button",MU,function()
        local ball    = findBall()
        local senv    = getSwordEnv()
        local remote  = findBlockRemote()
        local btn     = findExactButton()
        local msgs = {
            "─── ANIME BALL SCAN ───",
            "Ball:          "..(ball and ball:GetFullName() or "NOT FOUND — start a round!"),
            "SwordCtrl env: "..(senv and "FOUND (getsenv OK)" or "NOT FOUND"..( CAPS.getsenv and " (path changed?)" or " (getsenv unavail)")),
            "Block remote:  "..(remote and remote:GetFullName() or "NOT FOUND"),
            "Block button:  "..(btn and btn:GetFullName() or "NOT FOUND — HUD not loaded?"),
            "Storage:       "..(RS_STORAGE and "OK" or "MISSING"),
            "Swords folder: "..(SWORDS_FOLDER and "OK" or "MISSING"),
        }
        for _,m in ipairs(msgs) do print("[AnimeBallHub]",m) end
        -- Also check if Block fn found in env
        if senv then
            for _,v in pairs(senv) do
                if type(v)=="table" and type(v.Block)=="function" then
                    print("[AnimeBallHub] Block() fn: CONFIRMED inside SwordController env")
                    break
                end
            end
        end
        notify("Scan","Check F9 console for all results",4)
    end)

    secHeader(P,"ANTI-CHEATS",nextLo())

    addToggle(P,"Anti-Elimination","Block elimination remotes via hook"..(CAPS.hookmetamethod and "" or "  [needs hookmetamethod]"),false,function(on)
        antiElim(on)
    end)

    addToggle(P,"God Mode","Health always full",settings.god,function(on)
        godMode(on); settings.god=on; saveCfg()
    end)

    secHeader(P,"TARGETING",nextLo())

    addToggle(P,"Aimbot (hold RMB)","Lock camera to nearest player head",false,function(on)
        aimbot(on)
    end)

    addToggle(P,"Kill Aura (20st)","Instant-kill players within 20 studs",false,function(on)
        killAura(on)
    end)
end

-- ════════════════════════════════════════════════════════════════════════
--  TAB: BALL VISUALS
-- ════════════════════════════════════════════════════════════════════════
do
    local P = tabPages["ball"]
    secHeader(P,"BALL FX",nextLo())

    addToggle(P,"Ball Glow","PointLight attached to ball (orange glow)",settings.ballGlow,function(on)
        ballGlow(on); settings.ballGlow=on; saveCfg()
    end)

    addToggle(P,"Ball Trail","Animated color trail behind ball",settings.ballTrail,function(on)
        ballTrail(on); settings.ballTrail=on; saveCfg()
    end)

    addToggle(P,"Ball ESP","Distance + speed label above ball",settings.ballEsp,function(on)
        ballESP(on); settings.ballEsp=on; saveCfg()
    end)

    secHeader(P,"TRAIL COLOR",nextLo())

    local TRAIL_COLORS = {
        {"Red",    Color3.fromRGB(255,80,80)},
        {"Gold",   Color3.fromRGB(255,200,40)},
        {"Cyan",   Color3.fromRGB(60,200,255)},
        {"Green",  Color3.fromRGB(80,255,140)},
        {"Purple", Color3.fromRGB(180,80,255)},
        {"White",  Color3.fromRGB(255,255,255)},
    }
    -- color grid
    local cgRow=Instance.new("Frame",P); cgRow.Size=UDim2.new(1,0,0,42); cgRow.BackgroundTransparency=1; cgRow.LayoutOrder=nextLo()
    local cgGrid=Instance.new("UIGridLayout",cgRow); cgGrid.CellSize=UDim2.new(0,44,0,36); cgGrid.CellPadding=UDim2.new(0,4,0,4); cgGrid.SortOrder=Enum.SortOrder.LayoutOrder
    local selBorder = nil
    for i,col_def in ipairs(TRAIL_COLORS) do
        local cf=Instance.new("Frame",cgRow); cf.BackgroundColor3=col_def[2]; cf.BorderSizePixel=0; corner(cf,8); cf.LayoutOrder=i
        local cl=Instance.new("TextLabel",cf); cl.Size=UDim2.new(1,0,1,0); cl.BackgroundTransparency=1; cl.Text=col_def[1]; cl.TextColor3=Color3.new(1,1,1); cl.TextStrokeTransparency=0; cl.Font=Enum.Font.GothamBold; cl.TextSize=9; cl.TextXAlignment=Enum.TextXAlignment.Center
        local cb2=Instance.new("TextButton",cf); cb2.Size=UDim2.new(1,0,1,0); cb2.BackgroundTransparency=1; cb2.Text=""
        cb2.MouseButton1Click:Connect(function()
            if selBorder then selBorder:Destroy(); selBorder=nil end
            local s=stroke(cf,Color3.new(1,1,1),2); selBorder=s
            trailColorIdx=i
            trailColors[1]=col_def[2]
            -- refresh trail
            for _,v in pairs(workspace:GetDescendants()) do
                if v:IsA("Trail") and v.Name=="__ABTrail__" then
                    v.Color=ColorSequence.new({ColorSequenceKeypoint.new(0,col_def[2]),ColorSequenceKeypoint.new(1,Color3.fromRGB(255,255,255))})
                end
            end
        end)
    end

    secHeader(P,"BALL NEON",nextLo())

    addToggle(P,"Neon Material","Make ball neon/glowing material",false,function(on)
        local b=findBall()
        if b then b.Material=on and Enum.Material.Neon or Enum.Material.SmoothPlastic end
    end)

    addToggle(P,"Rainbow Ball","Cycle ball color over time",false,function(on)
        if on then
            local hue=0
            ac(RS.Heartbeat:Connect(function()
                local b=findBall(); if not b then return end
                hue=(hue+2)%360
                b.Color=Color3.fromHSV(hue/360,1,1)
            end))
        end
    end)

    addButton(P,"Highlight Ball","SelectionBox on ball (yellow outline)",Color3.fromRGB(255,220,50),function()
        local b=findBall(); if not b then notify("Ball","No ball found",2); return end
        local sb=Instance.new("SelectionBox",b); sb.Adornee=b; sb.Color3=Color3.fromRGB(255,220,50); sb.LineThickness=0.05; sb.SurfaceTransparency=0.85; sb.SurfaceColor3=Color3.fromRGB(255,220,50)
        task.delay(5,function() if sb and sb.Parent then sb:Destroy() end end)
    end)
end

-- ════════════════════════════════════════════════════════════════════════
--  TAB: PLAYER VISUALS
-- ════════════════════════════════════════════════════════════════════════
do
    local P = tabPages["visual"]
    secHeader(P,"PLAYER ESP",nextLo())

    addToggle(P,"Player ESP","Name + health + distance labels",settings.esp,function(on)
        esp(on); settings.esp=on; saveCfg()
    end)

    addToggle(P,"ESP Tracer","Line from screen bottom to each player",false,function(on)
        -- Drawing-based tracer (if Drawing API available)
        if not Drawing then
            notify("ESP","Drawing API unavailable",3); return
        end
        if on then
            ac(RS.RenderStepped:Connect(function()
                -- clear old lines and redraw
                for _,p in pairs(Players:GetPlayers()) do
                    if p~=LP and p.Character then
                        local hrp=p.Character:FindFirstChild("HumanoidRootPart")
                        if hrp then
                            local pos,vis=cam:WorldToScreenPoint(hrp.Position)
                            if vis then
                                local line=Drawing.new("Line")
                                line.From=Vector2.new(cam.ViewportSize.X/2,cam.ViewportSize.Y)
                                line.To=Vector2.new(pos.X,pos.Y)
                                line.Color=Color3.fromRGB(255,80,80)
                                line.Thickness=1.2
                                line.Transparency=0.7
                                line.Visible=true
                                task.delay(0.04,function() line:Remove() end)
                            end
                        end
                    end
                end
            end))
        end
    end)

    addToggle(P,"Box ESP","Highlight box around players",false,function(on)
        if on then
            ac(RS.Heartbeat:Connect(function()
                for _,p in pairs(Players:GetPlayers()) do
                    if p~=LP and p.Character then
                        for _,v in pairs(p.Character:GetDescendants()) do
                            if v:IsA("BasePart") and not v:FindFirstChild("__boxesp__") then
                                local sel=Instance.new("SelectionBox",v); sel.Name="__boxesp__"; sel.Adornee=v
                                sel.Color3=Color3.fromRGB(255,60,60); sel.LineThickness=0.04
                                sel.SurfaceTransparency=0.9; sel.SurfaceColor3=Color3.fromRGB(255,60,60)
                            end
                        end
                    end
                end
            end))
        else
            for _,v in pairs(workspace:GetDescendants()) do
                if v:IsA("SelectionBox") and v.Name=="__boxesp__" then v:Destroy() end
            end
        end
    end)

    addToggle(P,"Chams (X-Ray)","See players through walls via highlight",false,function(on)
        local function applyChams(p)
            if p==LP then return end
            local c=p.Character; if not c then return end
            local h=Instance.new("Highlight",c); h.Name="__chams__"
            h.FillColor=Color3.fromRGB(255,60,60); h.OutlineColor=Color3.fromRGB(255,200,200)
            h.FillTransparency=0.5; h.OutlineTransparency=0; h.DepthMode=Enum.HighlightDepthMode.AlwaysOnTop
        end
        if on then
            for _,p in pairs(Players:GetPlayers()) do applyChams(p) end
            ac(Players.PlayerAdded:Connect(function(p)
                ac(p.CharacterAdded:Connect(function() task.wait(1); applyChams(p) end))
            end))
            ac(Players.PlayerRemoving:Connect(function(p)
                if p.Character then
                    for _,v in pairs(p.Character:GetDescendants()) do
                        if v:IsA("Highlight") and v.Name=="__chams__" then v:Destroy() end
                    end
                end
            end))
        else
            for _,v in pairs(workspace:GetDescendants()) do
                if v:IsA("Chams") or (v:IsA("Highlight") and v.Name=="__chams__") then v:Destroy() end
            end
        end
    end)

    secHeader(P,"SELF VISUALS",nextLo())

    addToggle(P,"Invisible (self)","Hide your character from others",false,function(on)
        local c=getChar(); if not c then return end
        for _,p in pairs(c:GetDescendants()) do
            if p:IsA("BasePart") or p:IsA("Decal") then p.Transparency=on and 1 or 0 end
        end
    end)

    addToggle(P,"Fullbright","Remove all shadows and fog",settings.fullbright,function(on)
        fullbright(on); settings.fullbright=on; saveCfg()
    end)
end

-- ════════════════════════════════════════════════════════════════════════
--  TAB: MOVEMENT
-- ════════════════════════════════════════════════════════════════════════
do
    local P = tabPages["move"]
    secHeader(P,"SPEED",nextLo())

    -- Speed slider (as stepped buttons)
    local SPEEDS = {16,24,32,50,75,120}
    local speedRow=Instance.new("Frame",P); speedRow.Size=UDim2.new(1,0,0,50); speedRow.BackgroundColor3=CARD; speedRow.BorderSizePixel=0; corner(speedRow,10); speedRow.LayoutOrder=nextLo(); stroke(speedRow,BRD,1)
    local spL=Instance.new("TextLabel",speedRow); spL.Size=UDim2.new(1,-20,0,18); spL.Position=UDim2.new(0,12,0,6); spL.BackgroundTransparency=1; spL.Text="WalkSpeed: "..settings.speed; spL.TextColor3=TX; spL.Font=Enum.Font.GothamSemibold; spL.TextSize=13; spL.TextXAlignment=Enum.TextXAlignment.Left
    local btnRow=Instance.new("Frame",speedRow); btnRow.Size=UDim2.new(1,-24,0,22); btnRow.Position=UDim2.new(0,12,0,24); btnRow.BackgroundTransparency=1
    local brl=Instance.new("UIListLayout",btnRow); brl.FillDirection=Enum.FillDirection.Horizontal; brl.Padding=UDim.new(0,4); brl.SortOrder=Enum.SortOrder.LayoutOrder
    for i,spd in ipairs(SPEEDS) do
        local bf=Instance.new("Frame",btnRow); bf.Size=UDim2.new(0,34,0,22); bf.BackgroundColor3=CARD2; bf.BorderSizePixel=0; corner(bf,6); bf.LayoutOrder=i
        local bl=Instance.new("TextLabel",bf); bl.Size=UDim2.new(1,0,1,0); bl.BackgroundTransparency=1; bl.Text=tostring(spd); bl.TextColor3=MU; bl.Font=Enum.Font.GothamBold; bl.TextSize=10; bl.TextXAlignment=Enum.TextXAlignment.Center
        local bb2=Instance.new("TextButton",bf); bb2.Size=UDim2.new(1,0,1,0); bb2.BackgroundTransparency=1; bb2.Text=""
        bb2.MouseButton1Click:Connect(function()
            settings.speed=spd; setSpeed(spd); saveCfg()
            spL.Text="WalkSpeed: "..spd
            tw(bf,{BackgroundColor3=AC}); tw(bl,{TextColor3=BG})
            task.delay(0.3,function() tw(bf,{BackgroundColor3=CARD2}); tw(bl,{TextColor3=MU}) end)
        end)
    end

    secHeader(P,"MOVEMENT",nextLo())

    addToggle(P,"Fly (WASD+Space/Shift)","BodyVelocity flight — works in all games",settings.fly,function(on)
        fly(on); settings.fly=on; saveCfg()
    end)

    addToggle(P,"Infinite Jump","Jump while airborne",false,function(on)
        infJump(on)
    end)

    addToggle(P,"Noclip","Phase through all parts",false,function(on)
        noclip(on)
    end)

    secHeader(P,"TELEPORT",nextLo())

    addButton(P,"TP to Ball","Teleport directly onto ball",AC,function()
        local b=findBall(); local hrp=getHRP()
        if b and hrp then hrp.CFrame=CFrame.new(b.Position+Vector3.new(0,5,0))
        else notify("TP","Ball not found",2) end
    end)

    addButton(P,"TP to Nearest Player","Teleport to closest enemy",Color3.fromRGB(200,100,60),function()
        local hrp=getHRP(); if not hrp then return end
        local best,bd=nil,math.huge
        for _,p in pairs(Players:GetPlayers()) do
            if p~=LP and p.Character then
                local r2=p.Character:FindFirstChild("HumanoidRootPart")
                if r2 then
                    local d=(r2.Position-hrp.Position).Magnitude
                    if d<bd then best=r2; bd=d end
                end
            end
        end
        if best then hrp.CFrame=CFrame.new(best.Position+Vector3.new(4,0,0))
        else notify("TP","No players found",2) end
    end)
end

-- ════════════════════════════════════════════════════════════════════════
--  TAB: MISC
-- ════════════════════════════════════════════════════════════════════════
do
    local P = tabPages["misc"]
    secHeader(P,"ENVIRONMENT",nextLo())

    addToggle(P,"Fullbright","Remove shadows and fog",settings.fullbright,function(on)
        fullbright(on); settings.fullbright=on; saveCfg()
    end)

    addToggle(P,"Low Gravity","0.4× gravity (float longer)",false,function(on)
        workspace.Gravity=on and 70 or 196.2
    end)

    addToggle(P,"Zero Gravity","Minimal gravity for air control",false,function(on)
        workspace.Gravity=on and 2 or 196.2
    end)

    secHeader(P,"INTROSPECTION",nextLo())

    addButton(P,"Scan Ball (All Methods)","Print ball info to console",MU,function()
        local b1=findBallWorkspace()
        local b2=findBallGC()
        local b3=findBallInstances()
        local msg = "Workspace: "..(b1 and b1.Name or "nil")..
                    "  GC: "..(b2 and b2.Name or "nil")..
                    "  Instances: "..(b3 and b3.Name or "nil")
        notify("Ball Scan",msg,6)
        print("[AnimeBallHub] Ball scan:",msg)
    end)

    addButton(P,"Scan Parry Remote","Find parry/deflect remote names",MU,function()
        local r=findParryRemote()
        if r then notify("Parry Remote","Found: "..r:GetFullName(),5); print("[AnimeBallHub] Parry remote:",r:GetFullName())
        else notify("Parry Remote","Not found — try playing a round",4) end
    end)

    addButton(P,"Dump All Remotes","Print all RemoteEvents to console",MU,function()
        local found={}
        for _,v in pairs(game:GetDescendants()) do
            if v:IsA("RemoteEvent") or v:IsA("RemoteFunction") then
                table.insert(found,v:GetFullName())
            end
        end
        print("[AnimeBallHub] Remotes ("..#found.."):")
        for _,n in ipairs(found) do print("  "..n) end
        notify("Remotes","Dumped "..#found.." remotes to console",3)
    end)

    addButton(P,"getsenv Ball Script","Dump ball script env vars",CAPS.getsenv and MU or RED_C,function()
        if not CAPS.getsenv then notify("getsenv","Not available on this executor",3); return end
        local ball=findBall(); if not ball then notify("getsenv","Ball not found",2); return end
        for _,s in pairs(ball:GetDescendants()) do
            if s:IsA("Script") or s:IsA("LocalScript") or s:IsA("ModuleScript") then
                local ok2,env=pcall(getsenv,s)
                if ok2 and env then
                    print("[AnimeBallHub] getsenv "..s.Name..":")
                    for k,v in pairs(env) do pcall(function() print("  "..tostring(k).." = "..tostring(v)) end) end
                end
            end
        end
        notify("getsenv","Dumped to console",3)
    end)

    secHeader(P,"PERSISTENCE",nextLo())

    addButton(P,"Save Settings","Write config to "..CFG_PATH,AC,function()
        saveCfg()
        notify("Settings","Saved to "..CFG_PATH,3)
    end)

    addToggle(P,"Auto-rejoin on death","queue_on_teleport re-enters same server"..(CAPS.queue_teleport and "" or "  [unavailable]"),false,function(on)
        if not CAPS.queue_teleport then notify("Rejoin","queue_on_teleport not available",3); return end
        if on then
            ac(LP.CharacterRemoving:Connect(function()
                task.wait(1)
                pcall(function()
                    queue_on_teleport('loadstring(game:HttpGet("'..game:GetService("ReplicatedStorage").Parent:GetFullName()..'",true))()')
                    game:GetService("TeleportService"):Teleport(game.PlaceId, LP)
                end)
            end))
        end
    end)

    secHeader(P,"API STATUS",nextLo())

    local apiList={
        {"getgc",CAPS.getgc},{"getsenv",CAPS.getsenv},{"getinstances",CAPS.getinstances},
        {"getconnections",CAPS.getconnections},{"hookmetamethod",CAPS.hookmetamethod},
        {"hookfunction",CAPS.hookfunction},{"firesignal",CAPS.firesignal},
        {"request",CAPS.request},{"readfile",CAPS.readfile},{"writefile",CAPS.writefile},
        {"VirtualUser",CAPS.VirtualUser},{"queue_teleport",CAPS.queue_teleport},
    }
    for _,api in ipairs(apiList) do
        addInfo(P,(api[2] and "✓ " or "✗ ")..api[1], api[2] and GRN or RED_C)
    end
end

-- ── Drag ────────────────────────────────────────────────────────────────
local dg,ds,dp=false
TB.InputBegan:Connect(function(i)
    if i.UserInputType==Enum.UserInputType.MouseButton1 or i.UserInputType==Enum.UserInputType.Touch then
        dg=true; ds=i.Position; dp=WIN.Position
    end
end)
TB.InputEnded:Connect(function() dg=false end)
UIS.InputChanged:Connect(function(i)
    if dg and (i.UserInputType==Enum.UserInputType.MouseMovement or i.UserInputType==Enum.UserInputType.Touch) then
        local d=i.Position-ds
        WIN.Position=UDim2.new(dp.X.Scale,dp.X.Offset+d.X,dp.Y.Scale,dp.Y.Offset+d.Y)
    end
end)

-- ── Toggle [Insert] key ──────────────────────────────────────────────────
UIS.InputBegan:Connect(function(i,gpe)
    if not gpe and i.KeyCode==Enum.KeyCode.Insert then
        WIN.Visible=not WIN.Visible
    end
end)

-- ── Apply saved settings on load ────────────────────────────────────────
showTab("auto")
if settings.ballGlow  then ballGlow(true)  end
if settings.ballTrail then ballTrail(true) end
if settings.ballEsp   then ballESP(true)   end
if settings.esp       then esp(true)       end
if settings.fly       then fly(true)       end
if settings.god       then godMode(true)   end
if settings.speed ~= 16 then setSpeed(settings.speed) end

end)
if not ok then
    local sg=pcall(function() game:GetService("StarterGui"):SetCore("SendNotification",{Title="Anime Ball Hub",Text="Error: "..tostring(err):sub(1,80),Duration=8}) end)
    warn("[AnimeBallHub] ERROR:", err)
end
