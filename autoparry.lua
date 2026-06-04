-- autoparry.lua  — no GUI, just works
local ok,err = pcall(function()

local Players = game:GetService("Players")
local RS      = game:GetService("RunService")
local UIS     = game:GetService("UserInputService")
local SG      = game:GetService("StarterGui")
local cam     = workspace.CurrentCamera
local LP      = Players.LocalPlayer
local PGui    = LP:WaitForChild("PlayerGui",15)

local function notify(t,m)
    pcall(function() SG:SetCore("SendNotification",{Title=t,Text=m,Duration=3}) end)
end

-- ── Capability flags ────────────────────────────────────────────────────────
local HAS_GC    = type(getgc)           == "function"
local HAS_CONNS = type(getconnections)  == "function"
local HAS_ENV   = type(getsenv)         == "function"
local HAS_UV    = (type(debug)=="table" and type(debug.getupvalues)=="function" and debug.getupvalues)
               or (type(getupvalues)=="function" and getupvalues)
               or nil

-- ── Ball detection ──────────────────────────────────────────────────────────
local BALL_NAMES = {"ball","blade","projectile","orb","sphere","anime","shot",
                    "animeball","animeorb","energy","magic","fire","slash","wave"}

local ballCache  = nil
local hookedBalls = {}

local function isBall(v)
    if not v:IsA("BasePart") or v.Anchored then return false end
    local n = v.Name:lower()
    for _,k in ipairs(BALL_NAMES) do if n:find(k,1,true) then return true end end
    return false
end

workspace.DescendantAdded:Connect(function(v)
    if isBall(v) and v.CanTouch then ballCache = v end
end)
workspace.DescendantRemoving:Connect(function(v)
    if v == ballCache then ballCache = nil; hookedBalls[v] = nil end
end)
for _,v in pairs(workspace:GetDescendants()) do
    if isBall(v) and v.CanTouch then ballCache = v; break end
end

local function findBall()
    if ballCache and ballCache.Parent then return ballCache end
    ballCache = nil; return nil
end

-- ── Character helpers ───────────────────────────────────────────────────────
local function getChar() return LP.Character end
local function getHRP()  local c=getChar(); return c and c:FindFirstChild("HumanoidRootPart") end

-- ── Block function cache ────────────────────────────────────────────────────
local cachedBlockFn     = nil
local cachedBlockRemote = nil
local cachedBlockBtn    = nil

LP.CharacterAdded:Connect(function()
    cachedBlockFn = nil; cachedBlockRemote = nil; cachedBlockBtn = nil
end)

local function upSearch(fn)
    if not HAS_UV or type(fn)~="function" then return nil end
    local ok2,uvs = pcall(HAS_UV, fn)
    if not (ok2 and uvs) then return nil end
    for _,uv in pairs(uvs) do
        if type(uv)=="table" and type(uv.Block)=="function" then return uv.Block end
    end
end

local function findBlockFn()
    if cachedBlockFn then return cachedBlockFn end

    -- 1: TouchTapInWorld upvalues → v_u_1.Block
    if HAS_CONNS then
        local ok2,conns = pcall(getconnections, UIS.TouchTapInWorld)
        if ok2 and conns then
            for _,c in ipairs(conns) do
                local fn; pcall(function() fn=c.Function end)
                local b = upSearch(fn)
                if b then cachedBlockFn=b; print("[AP] Found via TTI upvalues"); return b end
            end
        end
    end

    -- 2: Block button event connections
    if HAS_CONNS then
        local btn
        pcall(function()
            btn = PGui:FindFirstChild("HUD",true)
            if btn then btn = btn:FindFirstChild("Actions",true) end
            if btn then btn = btn:FindFirstChild("MainButtons",true) end
            if btn then btn = btn:FindFirstChild("Block") end
        end)
        if not btn then
            for _,v in pairs(PGui:GetDescendants()) do
                if v.Name=="Block" and (v:IsA("TextButton") or v:IsA("ImageButton")) then btn=v; break end
            end
        end
        if btn then
            cachedBlockBtn = btn
            for _,ev in ipairs({"Activated","MouseButton1Click","MouseButton1Down","InputBegan"}) do
                local ok2,conns = pcall(function() return getconnections(btn[ev]) end)
                if ok2 and conns then
                    for _,c in ipairs(conns) do
                        local fn; pcall(function() fn=c.Function end)
                        local b = upSearch(fn) or fn
                        if type(b)=="function" then
                            cachedBlockFn=b; print("[AP] Found via btn "..ev); return b
                        end
                    end
                end
            end
        end
    end

    -- 3: getsenv SwordController (tries both paths)
    if HAS_ENV then
        for _,pathFn in ipairs({
            function() return LP:WaitForChild("PlayerScripts",1):WaitForChild("Scripts",1):WaitForChild("SwordController",1) end,
            function() return game:GetService("StarterPlayer"):WaitForChild("StarterPlayerScripts",1):WaitForChild("Scripts",1):WaitForChild("SwordController",1) end,
        }) do
            local sc; pcall(function() sc=pathFn() end)
            if sc then
                local ok2,env = pcall(getsenv,sc)
                if ok2 and env then
                    for _,v in pairs(env) do
                        if type(v)=="table" and type(v.Block)=="function" then
                            cachedBlockFn=v.Block; print("[AP] Found via getsenv"); return v.Block
                        end
                    end
                end
            end
        end
    end

    -- 4: getgc table shape scan
    if HAS_GC then
        local ok2,gc = pcall(getgc,false)
        if ok2 and gc then
            for _,v in ipairs(gc) do
                if type(v)=="table" and type(v.Block)=="function"
                and type(v.ShowShield)=="function" then
                    cachedBlockFn=v.Block; print("[AP] Found via getgc"); return v.Block
                end
            end
        end
    end

    return nil
end

-- ── Block remote ────────────────────────────────────────────────────────────
local function findBlockRemote()
    if cachedBlockRemote and cachedBlockRemote.Parent then return cachedBlockRemote end
    for _,v in pairs(game:GetService("ReplicatedStorage"):GetDescendants()) do
        if v:IsA("RemoteFunction") and v.Name=="Block" then cachedBlockRemote=v; return v end
    end
end

-- ── Single parry attempt ────────────────────────────────────────────────────
local function executeParry(ball)
    -- A: real Block() function
    pcall(function()
        local fn = findBlockFn()
        if type(fn)=="function" then fn() end
    end)
    -- B: RemoteFunction (any angle)
    pcall(function()
        local r = findBlockRemote(); if not r then return end
        local hrp = getHRP()
        local y = (hrp and ball) and (ball.Position-hrp.Position).Unit.Y or 0
        r:InvokeServer(y)
    end)
    -- C: fire ball.Touched connections on HRP
    pcall(function()
        if not HAS_CONNS or not ball then return end
        local hrp = getHRP(); if not hrp then return end
        local ok2,conns = pcall(getconnections, ball.Touched)
        if ok2 and conns then
            for _,c in ipairs(conns) do
                local fn; pcall(function() fn=c.Function end)
                if type(fn)=="function" then pcall(fn, hrp) end
            end
        end
    end)
end

-- ── Ping cache ──────────────────────────────────────────────────────────────
local cachedPing=0.10; local pingT=0
local function getPing()
    if (tick()-pingT)<1 then return cachedPing end; pingT=tick()
    pcall(function()
        cachedPing=math.clamp(game:GetService("Stats").Network.ServerStatsItem["Data Ping"]:GetValue()/1000,0.03,0.6)
    end)
    return cachedPing
end

-- ── VirtualUser fallback ────────────────────────────────────────────────────
local VU = game:GetService("VirtualUser")
local function vuTap()
    local btn = cachedBlockBtn
    if not btn then
        for _,v in pairs(PGui:GetDescendants()) do
            if v.Name=="Block" and (v:IsA("TextButton") or v:IsA("ImageButton")) then btn=v; cachedBlockBtn=btn; break end
        end
    end
    if not btn then return end
    local pos = btn.AbsolutePosition + btn.AbsoluteSize*0.5
    pcall(function() VU:Button1Down(pos,cam.CFrame); task.wait(0.04); VU:Button1Up(pos,cam.CFrame) end)
end

-- ── Parry burst ─────────────────────────────────────────────────────────────
local lastParryTime    = 0
local parryBurstActive = false
local lastParryBall    = nil

local function doParry(ball)
    local hrp  = getHRP()
    local dist = hrp and (ball.Position-hrp.Position).Magnitude or 0
    local closeRange = dist < 8

    if not closeRange then
        if parryBurstActive then return end
        if ball == lastParryBall then return end
    end

    local cd = closeRange and 0.06 or dist < 14 and 0.12 or 0.20
    if (tick()-lastParryTime) < cd then return end
    lastParryTime = tick()

    if closeRange then
        -- 10-shot burst over 200ms for clashes
        executeParry(ball)
        for _,t in ipairs({0.02,0.04,0.06,0.08,0.10,0.12,0.14,0.16,0.18,0.20}) do
            task.delay(t, function() if ball.Parent then executeParry(ball) end end)
        end
    else
        parryBurstActive = true; lastParryBall = ball
        executeParry(ball)
        task.delay(0.06, function() if ball.Parent then executeParry(ball) end end)
        task.delay(0.12, function()
            if ball.Parent then executeParry(ball); vuTap() end
            parryBurstActive = false
        end)
    end
end

workspace.DescendantRemoving:Connect(function(v)
    if v==ballCache then parryBurstActive=false; lastParryBall=nil end
end)

-- ── Ball.Touched hook ────────────────────────────────────────────────────────
local function hookBall(ball)
    if hookedBalls[ball] then return end; hookedBalls[ball]=true
    ball.Touched:Connect(function(hit)
        local char=getChar()
        if char and (hit==char or hit:IsDescendantOf(char)) then
            executeParry(ball)
            task.delay(0.03, function() if ball.Parent then executeParry(ball) end end)
            task.delay(0.07, function() if ball.Parent then executeParry(ball) end end)
        end
    end)
end

-- ── Velocity tracking ───────────────────────────────────────────────────────
local velSamples={}; local velSampleT=0; local velAvg=0; local lastPos=nil

local function updateVel(ball)
    if not ball then velAvg=0; return end
    local now=tick(); local dt=now-velSampleT
    if dt>0 and dt<0.5 and lastPos then
        local spd=(ball.Position-lastPos).Magnitude/dt
        table.insert(velSamples,spd)
        if #velSamples>8 then table.remove(velSamples,1) end
        local s=0; for _,v in ipairs(velSamples) do s=s+v end; velAvg=s/#velSamples
    end
    lastPos=ball.Position; velSampleT=now
end

-- ── Pre-warm block fn on ball spawn ────────────────────────────────────────
workspace.DescendantAdded:Connect(function(v)
    if isBall(v) and v.CanTouch then
        ballCache=v
        task.delay(0.05, findBlockFn)
    end
end)

-- ── Main loop ───────────────────────────────────────────────────────────────
local loopT=0
RS.Heartbeat:Connect(function()
    local now=tick()
    if (now-loopT)<0.016 then return end; loopT=now

    local ball=findBall()
    local hrp=getHRP(); if not hrp then return end

    updateVel(ball)
    if ball then hookBall(ball) end

    if ball then
        local dist=(ball.Position-hrp.Position).Magnitude
        local should=false
        if dist<8 then
            should=true
        elseif velAvg>0 then
            local tti=dist/velAvg
            local base=dist<14 and 0.18 or 0.22
            should=tti<(base+getPing())
        else
            should=dist<25
        end
        if should then doParry(ball) end
    end
end)

-- Pre-warm immediately
task.delay(0.2, findBlockFn)
notify("Auto Parry","Active — never miss",3)
print("[AutoParry] Running. Block fn found:", cachedBlockFn~=nil)

end)
if not ok then warn("[AutoParry] Error: "..tostring(err)) end
