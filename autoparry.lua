-- autoparry.lua v5
print("[AP] Loading...")

-- ── Services (exact same pattern as working test script) ──────────────────
local Players = game:GetService("Players")
local RS      = game:GetService("RunService")
local UIS     = game:GetService("UserInputService")
local SG      = game:GetService("StarterGui")
local cam     = workspace.CurrentCamera
local LP      = Players.LocalPlayer
local PGui    = LP:WaitForChild("PlayerGui", 10)

local VU
pcall(function() VU = game:GetService("VirtualUser") end)

-- ── Notifications (SetCore + on-screen label backup) ─────────────────────
local toastHolder
pcall(function()
    if PGui:FindFirstChild("__AP__") then PGui:FindFirstChild("__AP__"):Destroy() end
    toastHolder = Instance.new("ScreenGui", PGui)
    toastHolder.Name = "__AP__"
    toastHolder.ResetOnSpawn = false
    toastHolder.DisplayOrder = 999
end)

local toastY = 10
local function notify(title, msg, dur)
    dur = dur or 4
    print("[AP] "..title.." | "..msg)
    pcall(function() SG:SetCore("SendNotification",{Title=title,Text=msg,Duration=dur}) end)
    pcall(function()
        if not (toastHolder and toastHolder.Parent) then return end
        local f = Instance.new("Frame", toastHolder)
        f.Size       = UDim2.new(0,300,0,50)
        f.Position   = UDim2.new(0,8,0,toastY)
        f.BackgroundColor3 = Color3.fromRGB(15,12,8)
        f.BorderSizePixel  = 0
        Instance.new("UICorner",f).CornerRadius = UDim.new(0,7)
        local s = Instance.new("UIStroke",f); s.Color=Color3.fromRGB(210,168,95); s.Thickness=1.5
        local t1 = Instance.new("TextLabel",f)
        t1.Size=UDim2.new(1,-8,0,20); t1.Position=UDim2.new(0,4,0,3)
        t1.BackgroundTransparency=1; t1.Text=title
        t1.TextColor3=Color3.fromRGB(210,168,95); t1.Font=Enum.Font.GothamBold
        t1.TextSize=12; t1.TextXAlignment=Enum.TextXAlignment.Left
        local t2 = Instance.new("TextLabel",f)
        t2.Size=UDim2.new(1,-8,0,18); t2.Position=UDim2.new(0,4,0,26)
        t2.BackgroundTransparency=1; t2.Text=msg
        t2.TextColor3=Color3.fromRGB(200,190,170); t2.Font=Enum.Font.Gotham
        t2.TextSize=11; t2.TextXAlignment=Enum.TextXAlignment.Left
        toastY = toastY + 56; if toastY > 400 then toastY = 10 end
        game:GetService("Debris"):AddItem(f, dur)
    end)
end

notify("Auto Parry v5","Starting up...",3)

-- ── Helpers ───────────────────────────────────────────────────────────────
local function getChar() return LP.Character end
local function getHRP()
    local c = getChar()
    return c and c:FindFirstChild("HumanoidRootPart")
end

-- ── UNC capability check ──────────────────────────────────────────────────
local UNC = {
    getgc           = type(getgc)            == "function",
    getsenv         = type(getsenv)          == "function",
    getinstances    = type(getinstances)     == "function",
    getconnections  = type(getconnections)   == "function",
    firesignal      = type(firesignal)       == "function",
    hookmetamethod  = type(hookmetamethod)   == "function",
    hookfunction    = type(hookfunction)     == "function",
    getupvalues     = type(getupvalues)      == "function"
                   or (type(debug)=="table" and type(debug.getupvalues)=="function"),
    readfile        = type(readfile)         == "function",
    writefile       = type(writefile)        == "function",
    request         = type(request)          == "function" or type(http_request)=="function",
    queue_teleport  = type(queue_on_teleport)== "function",
    VirtualUser     = VU ~= nil,
}
local getUV = (type(debug)=="table" and type(debug.getupvalues)=="function" and debug.getupvalues)
           or (type(getupvalues)=="function" and getupvalues) or nil

-- Report missing APIs
local missing = {}
for name,ok in pairs(UNC) do if not ok then table.insert(missing, name) end end
table.sort(missing)
if #missing > 0 then
    notify("Missing APIs", table.concat(missing,", "), 8)
else
    notify("All APIs OK","Full UNC support detected",4)
end

-- ── Ball detection ────────────────────────────────────────────────────────
local BALL_NAMES = {
    "ball","blade","projectile","orb","sphere","anime","shot",
    "animeball","animeorb","energy","magic","fire","slash","wave",
    "bullet","hitbox","attack","deflect","bounce","laser","beam",
    "hit","dmg","damage","harm","hurt","object","part"
}

local ballCache  = nil
local hookedBalls = {}

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
    -- Sphere-shaped small part
    if v.Shape == Enum.PartType.Ball and v.Size.Magnitude < 12 then return true end
    -- Small no-collide part (many games use this for hitboxes)
    if not v.CanCollide and v.Size.Magnitude < 6 then return true end
    return false
end

workspace.DescendantAdded:Connect(function(v)
    if isBall(v) then
        if not ballCache then
            notify("Ball Detected", v.Name.." ("..v.ClassName..")", 2)
        end
        ballCache = v
    end
end)
workspace.DescendantRemoving:Connect(function(v)
    if v == ballCache then ballCache = nil; hookedBalls[v]=nil end
end)
for _,v in pairs(workspace:GetDescendants()) do
    if isBall(v) then ballCache = v; break end
end

-- getinstances fallback scan
local instScanT = 0
local function instanceScan()
    if not UNC.getinstances then return end
    if (tick()-instScanT) < 2 then return end; instScanT=tick()
    local ok2,all = pcall(getinstances)
    if ok2 and all then
        for _,v in ipairs(all) do
            if isBall(v) and v.Parent then ballCache=v; return end
        end
    end
end

local function findBall()
    if ballCache and ballCache.Parent then return ballCache end
    ballCache = nil
    instanceScan()
    -- Fallback workspace scan every 1s
    for _,v in pairs(workspace:GetDescendants()) do
        if isBall(v) then ballCache=v; return ballCache end
    end
    return nil
end

-- ── Block function finder ─────────────────────────────────────────────────
local cachedBlockFn     = nil
local cachedBlockRemote = nil
local cachedBlockBtn    = nil

LP.CharacterAdded:Connect(function()
    task.wait(1)
    cachedBlockFn = nil; cachedBlockRemote = nil; cachedBlockBtn = nil
    notify("Respawned","Re-finding Block fn...",3)
end)

local function upSearch(fn)
    if not getUV or type(fn)~="function" then return nil end
    local ok2,uvs = pcall(getUV, fn)
    if not (ok2 and uvs) then return nil end
    for _,uv in pairs(uvs) do
        if type(uv)=="table" and type(uv.Block)=="function" then return uv.Block end
    end
end

local function findBtn()
    if cachedBlockBtn and cachedBlockBtn.Parent then return cachedBlockBtn end
    for _,v in pairs(PGui:GetDescendants()) do
        if v.Name=="Block" and (v:IsA("GuiButton") or v:IsA("TextButton") or v:IsA("ImageButton")) then
            cachedBlockBtn=v; return v
        end
    end
end

local function findBlockFn()
    if cachedBlockFn then return cachedBlockFn end

    -- 1: getconnections(TouchTapInWorld) → upvalues → v_u_1.Block
    if UNC.getconnections then
        local ok2,conns = pcall(getconnections, UIS.TouchTapInWorld)
        if ok2 and conns then
            for _,c in ipairs(conns) do
                local fn; pcall(function() fn=c.Function end)
                local b = upSearch(fn)
                if b then cachedBlockFn=b; notify("Block fn","Found via TouchTapInWorld",3); return b end
            end
        end
    end

    -- 2: getconnections on Block button
    local btn = findBtn()
    if btn and UNC.getconnections then
        for _,ev in ipairs({"Activated","MouseButton1Click","MouseButton1Down","InputBegan"}) do
            local ok2,conns = pcall(function() return getconnections(btn[ev]) end)
            if ok2 and conns then
                for _,c in ipairs(conns) do
                    local fn; pcall(function() fn=c.Function end)
                    local b = upSearch(fn) or (type(fn)=="function" and fn or nil)
                    if b then cachedBlockFn=b; notify("Block fn","Found via btn "..ev,3); return b end
                end
            end
        end
    end

    -- 3: getsenv SwordController (both paths)
    if UNC.getsenv then
        for _,pathFn in ipairs({
            function()
                return LP:FindFirstChild("PlayerScripts")
                    and LP.PlayerScripts:FindFirstChild("Scripts")
                    and LP.PlayerScripts.Scripts:FindFirstChild("SwordController")
            end,
            function()
                local sp = game:GetService("StarterPlayer"):FindFirstChild("StarterPlayerScripts")
                return sp and sp:FindFirstChild("Scripts") and sp.Scripts:FindFirstChild("SwordController")
            end,
        }) do
            local sc; pcall(function() sc=pathFn() end)
            if sc then
                local ok2,env = pcall(getsenv, sc)
                if ok2 and env then
                    for _,v in pairs(env) do
                        if type(v)=="table" and type(v.Block)=="function" then
                            cachedBlockFn=v.Block; notify("Block fn","Found via getsenv",3); return v.Block
                        end
                    end
                end
            end
        end
    end

    -- 4: getgc table shape scan (v_u_1 has Block+ShowShield+GetSwordAnim)
    if UNC.getgc then
        local ok2,gc = pcall(getgc, false)
        if ok2 and gc then
            for _,v in ipairs(gc) do
                if type(v)=="table" and type(v.Block)=="function"
                and type(v.ShowShield)=="function" then
                    cachedBlockFn=v.Block; notify("Block fn","Found via getgc",3); return v.Block
                end
            end
        end
    end

    return nil
end

-- Keep retrying until found
task.spawn(function()
    local attempts = 0
    while not cachedBlockFn do
        findBlockFn()
        attempts += 1
        if attempts == 4 and not cachedBlockFn then
            notify("Block fn","Not found yet — enter a round",5)
        end
        task.wait(3)
    end
end)

-- ── Block remote ──────────────────────────────────────────────────────────
local function findBlockRemote()
    if cachedBlockRemote and cachedBlockRemote.Parent then return cachedBlockRemote end
    for _,v in pairs(game:GetService("ReplicatedStorage"):GetDescendants()) do
        if v:IsA("RemoteFunction") and v.Name=="Block" then
            cachedBlockRemote=v; return v
        end
    end
end

-- ── Ping ──────────────────────────────────────────────────────────────────
local cachedPing=0.10; local pingT=0
local function getPing()
    if (tick()-pingT)<1 then return cachedPing end; pingT=tick()
    pcall(function()
        cachedPing=math.clamp(
            game:GetService("Stats").Network.ServerStatsItem["Data Ping"]:GetValue()/1000,
            0.02, 0.6)
    end)
    return cachedPing
end

-- ── Single parry execution — ALL methods ─────────────────────────────────
local function fireParry(ball)
    -- 1. Real Block() function (most accurate)
    pcall(function()
        local fn = findBlockFn()
        if type(fn)=="function" then fn() end
    end)

    -- 2. RemoteFunction InvokeServer with real ball direction
    pcall(function()
        local r = findBlockRemote(); if not r then return end
        local hrp = getHRP()
        local y = (hrp and ball) and (ball.Position-hrp.Position).Unit.Y or 0
        r:InvokeServer(y)
    end)

    -- 3. VirtualUser tap on Block button
    if VU then
        pcall(function()
            local btn = findBtn(); if not btn then return end
            local pos = btn.AbsolutePosition + btn.AbsoluteSize*0.5
            VU:Button1Down(pos, cam.CFrame)
            task.wait(0.04)
            VU:Button1Up(pos, cam.CFrame)
        end)
    end

    -- 4. firesignal on ball.Touched → fires the game's own parry handler
    if UNC.firesignal and ball then
        pcall(function()
            local hrp = getHRP(); if not hrp then return end
            firesignal(ball.Touched, hrp)
        end)
    end

    -- 5. getconnections on ball.Touched → call each handler with HRP
    if UNC.getconnections and ball then
        pcall(function()
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

    -- 6. hookmetamethod passthrough (ensures Block remote isn't blocked)
    -- Already installed globally below — no per-shot work needed
end

-- ── hookmetamethod — let all Block:InvokeServer calls pass through ────────
if UNC.hookmetamethod then
    pcall(function()
        local orig = hookmetamethod(game,"__namecall",newcclosure and newcclosure(function(self,...)
            local m = getnamecallmethod and getnamecallmethod() or ""
            if m=="InvokeServer" and typeof(self)=="Instance" and self.Name=="Block" then
                if not cachedBlockRemote then cachedBlockRemote=self end
            end
            return orig(self,...)
        end) or function(self,...)
            local m = getnamecallmethod and getnamecallmethod() or ""
            if m=="InvokeServer" and typeof(self)=="Instance" and self.Name=="Block" then
                if not cachedBlockRemote then cachedBlockRemote=self end
            end
            return orig(self,...)
        end)
    end)
end

-- ── Burst logic ───────────────────────────────────────────────────────────
local lastParryTime = 0
local burstActive   = false
local lastBurstBall = nil

local function doParry(ball, dist)
    local close = dist < 8
    if not close then
        if burstActive then return end
        if ball == lastBurstBall then return end
    end
    local cd = close and 0.05 or dist < 16 and 0.10 or 0.18
    if (tick()-lastParryTime) < cd then return end
    lastParryTime = tick()

    if close then
        fireParry(ball)
        for _,t in ipairs({0.02,0.04,0.06,0.08,0.10,0.12,0.15,0.18,0.20}) do
            task.delay(t, function() if ball and ball.Parent then fireParry(ball) end end)
        end
    else
        burstActive=true; lastBurstBall=ball
        fireParry(ball)
        task.delay(0.07, function() if ball and ball.Parent then fireParry(ball) end end)
        task.delay(0.15, function()
            if ball and ball.Parent then fireParry(ball) end
            burstActive=false
        end)
    end
end

workspace.DescendantRemoving:Connect(function(v)
    if v==ballCache then burstActive=false; lastBurstBall=nil end
end)

-- ── ball.Touched hook — fires at exact impact ─────────────────────────────
local function hookBall(ball)
    if hookedBalls[ball] then return end; hookedBalls[ball]=true
    pcall(function()
        ball.Touched:Connect(function(hit)
            local char=getChar(); if not char then return end
            if hit==char or hit:IsDescendantOf(char) then
                fireParry(ball)
                task.delay(0.04, function() if ball.Parent then fireParry(ball) end end)
            end
        end)
    end)
end

-- ── Velocity tracking ─────────────────────────────────────────────────────
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

-- ── Main loop — 60 Hz ─────────────────────────────────────────────────────
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
            fire = true
        elseif velAvg > 2 then
            local tti = dist/velAvg
            fire = tti < (0.22 + getPing())
        else
            fire = dist < 35
        end
        if fire then doParry(ball, dist) end
    end
end)

-- ── Diagnosis after 12s ───────────────────────────────────────────────────
task.delay(12, function()
    local problems = {}
    if not cachedBlockFn     then table.insert(problems,"No Block fn — need a round") end
    if not findBall()        then table.insert(problems,"No ball — check ball name") end
    if not findBlockRemote() then table.insert(problems,"No Block remote") end
    if not findBtn()         then table.insert(problems,"No Block button in HUD") end
    if #problems == 0 then
        notify("All OK","Parry is fully active",4)
    else
        for i,p in ipairs(problems) do
            task.delay((i-1)*1.8, function() notify("Issue "..i, p, 6) end)
        end
    end
end)

-- ── Test fire on load ─────────────────────────────────────────────────────
task.delay(1.5, function()
    local fired = {}
    pcall(function()
        local fn=findBlockFn(); if type(fn)=="function" then fn(); table.insert(fired,"BlockFn") end
    end)
    pcall(function()
        local r=findBlockRemote(); if r then r:InvokeServer(0); table.insert(fired,"Remote") end
    end)
    if VU then
        local btn=findBtn()
        if btn then
            pcall(function()
                local pos=btn.AbsolutePosition+btn.AbsoluteSize*0.5
                VU:Button1Down(pos,cam.CFrame); task.wait(0.04); VU:Button1Up(pos,cam.CFrame)
            end)
            table.insert(fired,"VU")
        end
    end
    if #fired>0 then
        notify("Test Fire","Fired: "..table.concat(fired,"+"),4)
    else
        notify("Test Fire","No methods yet — join a round",5)
    end
end)

notify("Auto Parry v5","Active! Watching for ball...",4)
print("[AP] Done loading. UNC score: "..#(function() local t={} for _,v in pairs(UNC) do if v then t[#t+1]=1 end end return t end)().."/13")
