-- autoparry.lua  v4 — no GUI, custom toast notifications, bulletproof startup
print("[AP] Script starting...")

local ok,err = pcall(function()

local Players = game:GetService("Players")
local RS      = game:GetService("RunService")
local UIS     = game:GetService("UserInputService")
local VU      = pcall(game.GetService,game,"VirtualUser") and game:GetService("VirtualUser") or nil
local cam     = workspace.CurrentCamera
local LP      = Players.LocalPlayer
if not LP then
    repeat task.wait() until Players.LocalPlayer
    LP = Players.LocalPlayer
end
local PGui = LP:FindFirstChildOfClass("PlayerGui")
if not PGui then
    task.spawn(function()
        repeat task.wait() until LP:FindFirstChildOfClass("PlayerGui")
        PGui = LP:FindFirstChildOfClass("PlayerGui")
    end)
end

-- ── Custom toast — works even if SetCore is disabled ─────────────────────────
local toastGui
local function notify(title, msg, dur)
    dur = dur or 4
    print("[AP] "..title..": "..msg)
    pcall(function()
        -- Try SetCore first
        game:GetService("StarterGui"):SetCore("SendNotification",{Title=title,Text=msg,Duration=dur})
    end)
    -- Also show custom label on screen (always visible)
    pcall(function()
        local pg = LP:FindFirstChildOfClass("PlayerGui"); if not pg then return end
        if not toastGui or not toastGui.Parent then
            toastGui = Instance.new("ScreenGui", pg)
            toastGui.Name = "__APToast__"
            toastGui.ResetOnSpawn = false
            toastGui.DisplayOrder = 999
        end
        local f = Instance.new("Frame", toastGui)
        f.Size = UDim2.new(0,320,0,54)
        f.Position = UDim2.new(0.5,-160,0,12)
        f.BackgroundColor3 = Color3.fromRGB(18,14,10)
        f.BorderSizePixel = 0
        Instance.new("UICorner",f).CornerRadius = UDim.new(0,8)
        local stroke = Instance.new("UIStroke",f)
        stroke.Color = Color3.fromRGB(210,168,95); stroke.Thickness = 1.5
        local tl = Instance.new("TextLabel",f)
        tl.Size = UDim2.new(1,-12,0,22); tl.Position = UDim2.new(0,6,0,4)
        tl.BackgroundTransparency = 1
        tl.Text = title; tl.TextColor3 = Color3.fromRGB(210,168,95)
        tl.Font = Enum.Font.GothamBold; tl.TextSize = 13; tl.TextXAlignment = Enum.TextXAlignment.Left
        local ml = Instance.new("TextLabel",f)
        ml.Size = UDim2.new(1,-12,0,18); ml.Position = UDim2.new(0,6,0,28)
        ml.BackgroundTransparency = 1
        ml.Text = msg; ml.TextColor3 = Color3.fromRGB(210,200,180)
        ml.Font = Enum.Font.Gotham; ml.TextSize = 11; ml.TextXAlignment = Enum.TextXAlignment.Left
        game:GetService("Debris"):AddItem(f, dur)
    end)
end

local function getChar() return LP.Character end
local function getHRP()  local c=getChar(); return c and c:FindFirstChild("HumanoidRootPart") end

-- ─────────────────────────────────────────────────────────────────────────────
--  CAPABILITY FLAGS
-- ─────────────────────────────────────────────────────────────────────────────
local HAS_GC    = type(getgc)          == "function"
local HAS_CONNS = type(getconnections) == "function"
local HAS_ENV   = type(getsenv)        == "function"
local HAS_UV    = (type(debug)=="table" and type(debug.getupvalues)=="function" and debug.getupvalues)
               or (type(getupvalues)=="function" and getupvalues) or nil

-- ─────────────────────────────────────────────────────────────────────────────
--  BALL DETECTION  — wide net, name + shape + size, plus periodic scan fallback
-- ─────────────────────────────────────────────────────────────────────────────
local BALL_NAMES = {
    "ball","blade","projectile","orb","sphere","anime","shot","animeball",
    "animeorb","energy","magic","fire","slash","wave","bullet","hitbox",
    "attack","weapon","sword","deflect","bounce","laser","beam"
}

local ballCache = nil

local function isPlayerPart(v)
    for _,p in pairs(Players:GetPlayers()) do
        if p.Character and v:IsDescendantOf(p.Character) then return true end
    end
    return false
end

local function isBall(v)
    if not v:IsA("BasePart") then return false end
    if v.Anchored then return false end
    if isPlayerPart(v) then return false end
    -- Name match
    local n = v.Name:lower()
    for _,k in ipairs(BALL_NAMES) do
        if n:find(k,1,true) then return true end
    end
    -- Sphere-shaped small part (most ball games use this)
    if v.Shape == Enum.PartType.Ball and v.Size.Magnitude < 10 then return true end
    -- Small fast-moving unanchored part
    if v.Size.Magnitude < 4 and not v.CanCollide then return true end
    return false
end

-- Event-driven primary detection
local lastBallName = ""
workspace.DescendantAdded:Connect(function(v)
    if isBall(v) then
        ballCache = v
        if v.Name ~= lastBallName then
            lastBallName = v.Name
            print("[AP] Ball detected: "..v.Name.." ("..v.ClassName..")")
        end
    end
end)
workspace.DescendantRemoving:Connect(function(v)
    if v == ballCache then ballCache = nil end
end)

-- One-time startup scan
for _,v in pairs(workspace:GetDescendants()) do
    if isBall(v) then ballCache = v; break end
end

-- Periodic scan fallback every 0.5s in case DescendantAdded missed it
local scanT = 0
local function scanForBall()
    if (tick()-scanT) < 0.5 then return end; scanT=tick()
    if ballCache and ballCache.Parent then return end
    for _,v in pairs(workspace:GetDescendants()) do
        if isBall(v) then ballCache=v; return end
    end
    ballCache = nil
end

local function findBall()
    scanForBall()
    if ballCache and ballCache.Parent then return ballCache end
    ballCache = nil; return nil
end

-- ─────────────────────────────────────────────────────────────────────────────
--  BLOCK FUNCTION FINDER  — all 4 strategies, retried every 3s until found
-- ─────────────────────────────────────────────────────────────────────────────
local cachedBlockFn     = nil
local cachedBlockRemote = nil
local cachedBlockBtn    = nil

LP.CharacterAdded:Connect(function()
    cachedBlockFn=nil; cachedBlockRemote=nil; cachedBlockBtn=nil
    task.delay(1, function()
        -- Re-find after spawn (sword controller re-runs)
        cachedBlockFn = nil
    end)
end)

local function upSearch(fn)
    if not HAS_UV or type(fn)~="function" then return nil end
    local ok2,uvs = pcall(HAS_UV,fn)
    if not (ok2 and uvs) then return nil end
    for _,uv in pairs(uvs) do
        if type(uv)=="table" and type(uv.Block)=="function" then return uv.Block end
    end
end

local function findBlockFn()
    if cachedBlockFn then return cachedBlockFn end

    -- Strategy 1: TouchTapInWorld connection upvalues → v_u_1.Block
    if HAS_CONNS then
        local ok2,conns = pcall(getconnections, UIS.TouchTapInWorld)
        if ok2 and conns then
            for _,c in ipairs(conns) do
                local fn; pcall(function() fn=c.Function end)
                local b = upSearch(fn)
                if b then cachedBlockFn=b; print("[AP] Block via TTI upvalues ✓"); return b end
            end
        end
    end

    -- Strategy 2: Block HUD button connections
    if HAS_CONNS then
        local btn = cachedBlockBtn
        if not (btn and btn.Parent) then
            for _,v in pairs((LP:FindFirstChildOfClass("PlayerGui") or {GetDescendants=function() return {} end}):GetDescendants()) do
                if v.Name=="Block" and (v:IsA("TextButton") or v:IsA("ImageButton") or v:IsA("GuiButton")) then
                    btn=v; cachedBlockBtn=btn; break
                end
            end
        end
        if btn then
            for _,ev in ipairs({"Activated","MouseButton1Click","MouseButton1Down","InputBegan","Touched"}) do
                local ok2,conns = pcall(function() return getconnections(btn[ev]) end)
                if ok2 and conns then
                    for _,c in ipairs(conns) do
                        local fn; pcall(function() fn=c.Function end)
                        local b = upSearch(fn) or (type(fn)=="function" and fn or nil)
                        if b then cachedBlockFn=b; print("[AP] Block via btn "..ev.." ✓"); return b end
                    end
                end
            end
        end
    end

    -- Strategy 3: getsenv SwordController
    if HAS_ENV then
        for _,pathFn in ipairs({
            function() return LP:FindFirstChild("PlayerScripts") and LP.PlayerScripts:FindFirstChild("Scripts") and LP.PlayerScripts.Scripts:FindFirstChild("SwordController") end,
            function() return game:GetService("StarterPlayer"):FindFirstChild("StarterPlayerScripts") and game:GetService("StarterPlayer").StarterPlayerScripts:FindFirstChild("Scripts") and game:GetService("StarterPlayer").StarterPlayerScripts.Scripts:FindFirstChild("SwordController") end,
        }) do
            local sc; pcall(function() sc=pathFn() end)
            if sc then
                local ok2,env = pcall(getsenv,sc)
                if ok2 and env then
                    for _,v in pairs(env) do
                        if type(v)=="table" and type(v.Block)=="function" then
                            cachedBlockFn=v.Block; print("[AP] Block via getsenv ✓"); return v.Block
                        end
                    end
                end
            end
        end
    end

    -- Strategy 4: getgc table shape match
    if HAS_GC then
        local ok2,gc = pcall(getgc,false)
        if ok2 and gc then
            for _,v in ipairs(gc) do
                if type(v)=="table" and type(v.Block)=="function"
                and type(v.ShowShield)=="function" then
                    cachedBlockFn=v.Block; print("[AP] Block via getgc ✓"); return v.Block
                end
            end
        end
    end

    return nil
end

-- Retry finding block fn every 3s until found, notify result
local function keepFindingBlockFn()
    if cachedBlockFn then return end
    task.spawn(function()
        local attempts = 0
        while not cachedBlockFn do
            findBlockFn()
            attempts = attempts + 1
            if attempts == 3 and not cachedBlockFn then
                notify("Auto Parry","Block fn not found yet — stay in round",4)
            end
            task.wait(3)
        end
        notify("Auto Parry ✓","Block fn locked — parry active!",4)
        print("[AP] Block fn locked in ✓")
    end)
end

-- ─────────────────────────────────────────────────────────────────────────────
--  BLOCK REMOTE
-- ─────────────────────────────────────────────────────────────────────────────
local function findBlockRemote()
    if cachedBlockRemote and cachedBlockRemote.Parent then return cachedBlockRemote end
    for _,v in pairs(game:GetService("ReplicatedStorage"):GetDescendants()) do
        if v:IsA("RemoteFunction") and v.Name=="Block" then
            cachedBlockRemote=v; return v
        end
    end
end

-- ─────────────────────────────────────────────────────────────────────────────
--  VIRTUALUSER fallback — tap the Block button on screen
-- ─────────────────────────────────────────────────────────────────────────────
local function vuTap()
    if not VU then return end
    local btn = cachedBlockBtn
    if not (btn and btn.Parent) then
        local pg = LP:FindFirstChildOfClass("PlayerGui")
        if pg then
            for _,v in pairs(pg:GetDescendants()) do
                if v.Name=="Block" and (v:IsA("TextButton") or v:IsA("ImageButton") or v:IsA("GuiButton")) then
                    btn=v; cachedBlockBtn=btn; break
                end
            end
        end
    end
    if not btn then return end
    pcall(function()
        local pos = btn.AbsolutePosition + btn.AbsoluteSize*0.5
        VU:Button1Down(pos, cam.CFrame)
        task.wait(0.04)
        VU:Button1Up(pos, cam.CFrame)
    end)
end

-- ─────────────────────────────────────────────────────────────────────────────
--  SINGLE PARRY SHOT — fires every available method once
-- ─────────────────────────────────────────────────────────────────────────────
local function fireParry(ball)
    -- A: real v_u_1.Block()
    pcall(function()
        local fn = findBlockFn()
        if type(fn)=="function" then fn() end
    end)
    -- B: RemoteFunction with real angle
    pcall(function()
        local r = findBlockRemote(); if not r then return end
        local hrp = getHRP()
        local y = (hrp and ball) and (ball.Position-hrp.Position).Unit.Y or 0
        r:InvokeServer(y)
    end)
    -- C: VirtualUser tap
    vuTap()
    -- D: fire ball.Touched connections on player
    pcall(function()
        if not HAS_CONNS or not ball then return end
        local hrp=getHRP(); if not hrp then return end
        local ok2,conns=pcall(getconnections,ball.Touched)
        if ok2 and conns then
            for _,c in ipairs(conns) do
                local fn; pcall(function() fn=c.Function end)
                if type(fn)=="function" then pcall(fn,hrp) end
            end
        end
    end)
end

-- ─────────────────────────────────────────────────────────────────────────────
--  PING CACHE
-- ─────────────────────────────────────────────────────────────────────────────
local ping=0.10; local pingT=0
local function getPing()
    if (tick()-pingT)<1 then return ping end; pingT=tick()
    pcall(function()
        ping=math.clamp(game:GetService("Stats").Network.ServerStatsItem["Data Ping"]:GetValue()/1000,0.03,0.6)
    end)
    return ping
end

-- ─────────────────────────────────────────────────────────────────────────────
--  PARRY THROTTLE — prevents duplicate bursts per ball
-- ─────────────────────────────────────────────────────────────────────────────
local lastParryTime = 0
local lastBurstBall = nil
local burstActive   = false

local function doParry(ball, dist)
    local closeRange = dist < 8

    if not closeRange then
        if burstActive then return end
        if ball == lastBurstBall then return end
    end

    local cd = closeRange and 0.05 or dist < 16 and 0.10 or 0.18
    if (tick()-lastParryTime) < cd then return end
    lastParryTime = tick()

    if closeRange then
        -- Dense 10-shot burst — covers any server window even on 300ms ping
        fireParry(ball)
        for _,t in ipairs({0.02,0.04,0.06,0.08,0.10,0.12,0.14,0.16,0.18,0.20}) do
            task.delay(t, function() if ball and ball.Parent then fireParry(ball) end end)
        end
    else
        burstActive=true; lastBurstBall=ball
        fireParry(ball)
        task.delay(0.06, function() if ball and ball.Parent then fireParry(ball) end end)
        task.delay(0.14, function()
            if ball and ball.Parent then fireParry(ball) end
            burstActive=false
        end)
    end
end

workspace.DescendantRemoving:Connect(function(v)
    if v==ballCache then
        ballCache=nil; burstActive=false; lastBurstBall=nil
    end
end)

-- ─────────────────────────────────────────────────────────────────────────────
--  BALL.TOUCHED hook — fires at exact collision moment (never miss backup)
-- ─────────────────────────────────────────────────────────────────────────────
local hookedBalls = {}
local function hookBall(ball)
    if hookedBalls[ball] then return end; hookedBalls[ball]=true
    ball.Touched:Connect(function(hit)
        local char=getChar()
        if not char then return end
        if hit==char or hit:IsDescendantOf(char) then
            fireParry(ball)
            task.delay(0.04, function() if ball.Parent then fireParry(ball) end end)
            task.delay(0.09, function() if ball.Parent then fireParry(ball) end end)
        end
    end)
end

-- ─────────────────────────────────────────────────────────────────────────────
--  VELOCITY TRACKING
-- ─────────────────────────────────────────────────────────────────────────────
local velSamples={}; local velT=0; local velAvg=0; local lastPos=nil

local function updateVel(ball)
    if not ball then velAvg=0; lastPos=nil; return end
    local now=tick(); local dt=now-velT
    if dt>0.005 and dt<0.5 and lastPos then
        local spd=(ball.Position-lastPos).Magnitude/dt
        if spd>1 then
            table.insert(velSamples,spd)
            if #velSamples>10 then table.remove(velSamples,1) end
            local s=0; for _,v in ipairs(velSamples) do s=s+v end
            velAvg=s/#velSamples
        end
    end
    lastPos=ball.Position; velT=now
end

-- ─────────────────────────────────────────────────────────────────────────────
--  MAIN LOOP  — 60 Hz
-- ─────────────────────────────────────────────────────────────────────────────
local loopT = 0
RS.Heartbeat:Connect(function()
    local now = tick()
    if (now-loopT) < 0.016 then return end; loopT=now

    local ball = findBall()
    local hrp  = getHRP(); if not hrp then return end

    updateVel(ball)
    if ball then hookBall(ball) end

    if ball then
        local dist = (ball.Position-hrp.Position).Magnitude
        local fire = false

        if dist < 8 then
            -- Clash zone: always fire
            fire = true
        elseif velAvg > 2 then
            -- TTI-based with ping compensation
            local tti  = dist / velAvg
            local base = dist < 16 and 0.18 or 0.25
            fire = tti < (base + getPing())
        else
            -- No velocity data yet: use wide distance threshold
            fire = dist < 35
        end

        if fire then doParry(ball, dist) end
    end
end)

-- ─────────────────────────────────────────────────────────────────────────────
--  STARTUP CHECKS — notify which APIs are missing
-- ─────────────────────────────────────────────────────────────────────────────
local missing = {}
if not HAS_GC    then table.insert(missing,"getgc") end
if not HAS_CONNS then table.insert(missing,"getconnections") end
if not HAS_ENV   then table.insert(missing,"getsenv") end
if not HAS_UV    then table.insert(missing,"getupvalues") end
if type(firesignal)~="function"     then table.insert(missing,"firesignal") end
if type(hookmetamethod)~="function" then table.insert(missing,"hookmetamethod") end
if type(hookfunction)~="function"   then table.insert(missing,"hookfunction") end
if type(queue_on_teleport)~="function" then table.insert(missing,"queue_on_teleport") end
if type(readfile)~="function"  then table.insert(missing,"readfile") end
if type(writefile)~="function" then table.insert(missing,"writefile") end

-- Show missing APIs in one notification (staggered so they don't stack)
task.spawn(function()
    if #missing == 0 then
        notify("Auto Parry ✓","All APIs available — full power",4)
        print("[AP] All APIs available")
    else
        -- Split into groups of 3 so text fits
        local lines = {}
        for i=1,#missing,3 do
            table.insert(lines, table.concat({missing[i], missing[i+1] or "", missing[i+2] or ""}," "):gsub("%s+$",""))
        end
        notify("Auto Parry","Missing "..#missing.." APIs:",5)
        task.wait(1)
        for _,line in ipairs(lines) do
            notify("Not Available",line,5)
            task.wait(1.2)
        end
        -- Critical warning if getconnections missing (needed for Block fn strategy 1+2)
        if not HAS_CONNS then
            task.wait(0.5)
            notify("⚠ Warning","getconnections missing — parry may be weaker",6)
        end
        if not HAS_GC then
            task.wait(0.5)
            notify("⚠ Warning","getgc missing — Block fn harder to find",6)
        end
    end
    print("[AP] Missing APIs ("..#missing.."): "..table.concat(missing,", "))
end)

-- ─────────────────────────────────────────────────────────────────────────────
--  DIAGNOSIS — after 10s, report everything that might stop parry from working
-- ─────────────────────────────────────────────────────────────────────────────
task.delay(10, function()
    local problems = {}
    if not cachedBlockFn    then table.insert(problems,"Block fn NOT found") end
    if not findBall()       then table.insert(problems,"No ball detected") end
    if not findBlockRemote() then table.insert(problems,"Block remote NOT found") end
    if not cachedBlockBtn   then
        -- try to find it now
        for _,v in pairs((LP:FindFirstChildOfClass("PlayerGui") or {GetDescendants=function() return {} end}):GetDescendants()) do
            if v.Name=="Block" and (v:IsA("TextButton") or v:IsA("ImageButton") or v:IsA("GuiButton")) then
                cachedBlockBtn=v; break
            end
        end
        if not cachedBlockBtn then table.insert(problems,"Block button NOT found") end
    end

    if #problems == 0 then
        notify("Auto Parry ✓","Everything ready — parry is active",4)
        print("[AP] Diagnosis: all OK")
    else
        for i,p in ipairs(problems) do
            task.delay((i-1)*1.5, function()
                notify("Parry Issue",p,6)
                print("[AP] PROBLEM: "..p)
            end)
        end
        task.delay(#problems*1.5, function()
            notify("Parry Tip","Join a round then re-run if issues persist",6)
        end)
    end
end)

-- ─────────────────────────────────────────────────────────────────────────────
--  START
-- ─────────────────────────────────────────────────────────────────────────────
task.spawn(keepFindingBlockFn)
notify("Auto Parry","Started — join a round to activate",3)

-- Fire one test parry after 1s to confirm methods work in lobby
task.delay(1, function()
    local fired = {}
    -- Block fn
    pcall(function()
        local fn = findBlockFn()
        if type(fn)=="function" then fn(); table.insert(fired,"BlockFn") end
    end)
    -- Remote
    pcall(function()
        local r = findBlockRemote()
        if r then r:InvokeServer(0); table.insert(fired,"Remote") end
    end)
    -- VirtualUser
    local btn = cachedBlockBtn
    if not btn then
        for _,v in pairs((LP:FindFirstChildOfClass("PlayerGui") or {GetDescendants=function() return {} end}):GetDescendants()) do
            if v.Name=="Block" and (v:IsA("TextButton") or v:IsA("ImageButton") or v:IsA("GuiButton")) then
                btn=v; cachedBlockBtn=btn; break
            end
        end
    end
    if btn then
        pcall(function()
            local pos = btn.AbsolutePosition + btn.AbsoluteSize*0.5
            VU:Button1Down(pos, cam.CFrame); task.wait(0.04); VU:Button1Up(pos, cam.CFrame)
        end)
        table.insert(fired,"VirtualUser")
    end

    if #fired > 0 then
        notify("Auto Parry — Test","Fired: "..table.concat(fired,", "),4)
        print("[AP] Test fire OK: "..table.concat(fired,", "))
    else
        notify("Auto Parry — Test","No methods fired yet (join a round first)",5)
        print("[AP] Test fire: nothing fired — no sword in lobby")
    end
end)
print("[AP] Started. GC="..tostring(HAS_GC).." CONNS="..tostring(HAS_CONNS).." ENV="..tostring(HAS_ENV).." UV="..tostring(HAS_UV~=nil))

end)
if not ok then warn("[AutoParry] CRASH: "..tostring(err)) end
