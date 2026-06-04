-- animeball.lua — Anime Ball / Blade Ball auto-parry
-- Uses real game internals: workspace.Balls, Target attribute, AssemblyLinearVelocity
print("[AB] Loading...")

local Players = game:GetService("Players")
local RS      = game:GetService("RunService")
local UIS     = game:GetService("UserInputService")
local SG      = game:GetService("StarterGui")
local cam     = workspace.CurrentCamera
local LP      = Players.LocalPlayer
local PGui    = LP:WaitForChild("PlayerGui", 10)
local VU      = game:GetService("VirtualUser")

local function notify(t, m, d)
    pcall(function() SG:SetCore("SendNotification",{Title=t,Text=m,Duration=d or 4}) end)
    print("[AB] "..t..": "..m)
end

notify("Anime Ball","Loading...", 2)

local function getChar() return LP.Character end
local function getHRP()  local c=getChar(); return c and c:FindFirstChild("HumanoidRootPart") end

-- ── UNC ────────────────────────────────────────────────────────────────────
local HAS_GC    = type(getgc)           == "function"
local HAS_CONNS = type(getconnections)  == "function"
local HAS_ENV   = type(getsenv)         == "function"
local HAS_FIRE  = type(firesignal)      == "function"
local getUV     = (type(debug)=="table" and type(debug.getupvalues)=="function" and debug.getupvalues)
               or (type(getupvalues)=="function" and getupvalues) or nil

-- ── BALL DETECTION — workspace.balls folder (lowercase, confirmed from Dex) ─
-- Ball objects are named "balls2" inside workspace.balls
-- When ball.Target == LP.Name, it is aimed at us → parry now
local ballsFolder = workspace:FindFirstChild("balls") or workspace:FindFirstChild("Balls")
local currentBall = nil
local watchedBalls = {}

local function getBall()
    if currentBall and currentBall.Parent then return currentBall end
    currentBall = nil
    -- Check workspace.balls first
    if ballsFolder then
        for _, v in pairs(ballsFolder:GetChildren()) do
            local p = getBallPart and getBallPart(v) or (v:IsA("BasePart") and v or nil)
            if p then currentBall = p; return p end
        end
    end
    -- Fallback: BallController.CurrentBall via getgc
    if HAS_GC then
        local ok, gc = pcall(getgc, false)
        if ok and gc then
            for _, v in ipairs(gc) do
                if type(v)=="table" and typeof(v.CurrentBall)=="Instance"
                and type(v.GetBallAsync)=="function" then
                    currentBall = v.CurrentBall
                    return currentBall
                end
            end
        end
    end
    return nil
end

-- ── BLOCK FUNCTION ─────────────────────────────────────────────────────────
local blockFn     = nil
local blockRemote = nil
local blockBtn    = nil

LP.CharacterAdded:Connect(function()
    task.wait(2)
    blockFn = nil
    notify("Respawned", "Re-finding Block fn", 3)
end)

local function upSearch(fn)
    if not getUV or type(fn)~="function" then return nil end
    local ok, uvs = pcall(getUV, fn)
    if not ok then return nil end
    for _, uv in pairs(uvs or {}) do
        if type(uv)=="table" and type(uv.Block)=="function" then return uv.Block end
    end
end

local function findBtn()
    if blockBtn and blockBtn.Parent then return blockBtn end
    for _, v in pairs(PGui:GetDescendants()) do
        if v.Name=="Block" and (v:IsA("GuiButton") or v:IsA("TextButton") or v:IsA("ImageButton")) then
            blockBtn = v; return v
        end
    end
end

local function findBlockFn()
    if blockFn then return blockFn end

    -- 1: getconnections TouchTapInWorld → upvalues → v_u_1.Block
    if HAS_CONNS then
        local ok, conns = pcall(getconnections, UIS.TouchTapInWorld)
        if ok and conns then
            for _, c in ipairs(conns) do
                local fn; pcall(function() fn = c.Function end)
                local b = upSearch(fn)
                if b then blockFn=b; notify("Block fn","via TTI upvalues",3); return b end
            end
        end
    end

    -- 2: getconnections on Block button
    local btn = findBtn()
    if btn and HAS_CONNS then
        for _, ev in ipairs({"Activated","MouseButton1Click","MouseButton1Down","InputBegan"}) do
            local ok, conns = pcall(function() return getconnections(btn[ev]) end)
            if ok and conns then
                for _, c in ipairs(conns) do
                    local fn; pcall(function() fn = c.Function end)
                    local b = upSearch(fn) or (type(fn)=="function" and fn or nil)
                    if b then blockFn=b; notify("Block fn","via btn "..ev,3); return b end
                end
            end
        end
    end

    -- 3: getsenv SwordController
    if HAS_ENV then
        for _, pFn in ipairs({
            function() return LP:FindFirstChild("PlayerScripts") and LP.PlayerScripts:FindFirstChild("Scripts") and LP.PlayerScripts.Scripts:FindFirstChild("SwordController") end,
            function() local sp=game:GetService("StarterPlayer"):FindFirstChild("StarterPlayerScripts"); return sp and sp:FindFirstChild("Scripts") and sp.Scripts:FindFirstChild("SwordController") end,
        }) do
            local sc; pcall(function() sc = pFn() end)
            if sc then
                local ok, env = pcall(getsenv, sc)
                if ok and env then
                    for _, v in pairs(env) do
                        if type(v)=="table" and type(v.Block)=="function" then
                            blockFn=v.Block; notify("Block fn","via getsenv",3); return v.Block
                        end
                    end
                end
            end
        end
    end

    -- 4: getgc shape scan {Block, ShowShield}
    if HAS_GC then
        local ok, gc = pcall(getgc, false)
        if ok and gc then
            for _, v in ipairs(gc) do
                if type(v)=="table" and type(v.Block)=="function" and type(v.ShowShield)=="function" then
                    blockFn=v.Block; notify("Block fn","via getgc",3); return v.Block
                end
            end
        end
    end

    return nil
end

-- Keep searching until found
task.spawn(function()
    local n = 0
    while not blockFn do
        findBlockFn()
        n = n + 1
        if n == 4 and not blockFn then notify("Block fn","Not found yet — enter round",5) end
        task.wait(3)
    end
    notify("Parry READY","Block fn locked in!",4)
end)

-- ── BLOCK REMOTE ───────────────────────────────────────────────────────────
local function findRemote()
    if blockRemote and blockRemote.Parent then return blockRemote end
    for _, v in pairs(game:GetService("ReplicatedStorage"):GetDescendants()) do
        if (v:IsA("RemoteEvent") or v:IsA("RemoteFunction")) and v.Name=="Block" then
            blockRemote=v; notify("Remote","Found: "..v:GetFullName(),3); return v
        end
    end
end

-- ── PING ───────────────────────────────────────────────────────────────────
local ping=0.10; local pingT=0
local function getPing()
    if (tick()-pingT)<1 then return ping end; pingT=tick()
    pcall(function()
        ping=math.clamp(game:GetService("Stats").Network.ServerStatsItem["Data Ping"]:GetValue()/1000,0.02,0.6)
    end)
    return ping
end

-- ── FIRE ALL PARRY METHODS ─────────────────────────────────────────────────
local function fireBlock(ball)
    -- 1. Direct Block() function
    pcall(function()
        local fn = findBlockFn()
        if type(fn)=="function" then fn() end
    end)
    -- 2. Remote (handles both RemoteEvent and RemoteFunction)
    pcall(function()
        local r = findRemote(); if not r then return end
        local hrp = getHRP()
        local y = (hrp and ball) and (ball.Position-hrp.Position).Unit.Y or 0
        if r:IsA("RemoteEvent") then r:FireServer(y) else r:InvokeServer(y) end
    end)
    -- 3. VirtualUser button tap
    pcall(function()
        local btn = findBtn(); if not btn then return end
        local pos = btn.AbsolutePosition + btn.AbsoluteSize*0.5
        VU:Button1Down(pos, cam.CFrame); task.wait(0.04); VU:Button1Up(pos, cam.CFrame)
    end)
    -- 4. firesignal ball.Touched
    if HAS_FIRE and ball then
        pcall(function()
            local hrp=getHRP(); if hrp then firesignal(ball.Touched, hrp) end
        end)
    end
    -- 5. getconnections ball.Touched → call each handler
    if HAS_CONNS and ball then
        pcall(function()
            local hrp=getHRP(); if not hrp then return end
            local ok, conns = pcall(getconnections, ball.Touched)
            if ok and conns then
                for _, c in ipairs(conns) do
                    local fn; pcall(function() fn=c.Function end)
                    if type(fn)=="function" then pcall(fn, hrp) end
                end
            end
        end)
    end
end

-- ── BURST ──────────────────────────────────────────────────────────────────
local lastFire   = 0
local burstBall  = nil
local burstActive = false

local function doParry(ball, isClose)
    if not isClose then
        if burstActive then return end
        if ball == burstBall then return end
    end
    local cd = isClose and 0.05 or 0.12
    if (tick()-lastFire) < cd then return end
    lastFire = tick()

    if isClose then
        fireBlock(ball)
        for _, t in ipairs({0.02,0.04,0.06,0.08,0.10,0.13,0.16,0.20}) do
            task.delay(t, function() if ball and ball.Parent then fireBlock(ball) end end)
        end
    else
        burstActive=true; burstBall=ball
        fireBlock(ball)
        task.delay(0.07, function() if ball and ball.Parent then fireBlock(ball) end end)
        task.delay(0.16, function()
            if ball and ball.Parent then fireBlock(ball) end
            burstActive=false
        end)
    end
end

-- ── WATCH BALL — use Target attribute + TTI formula from BallController ────
-- From decompile: (dist - 8) / velocity <= 0.6 is the game's own "BLOCK!" trigger
-- We fire at <= 0.6 + ping to account for latency
local function watchBall(ball)
    if watchedBalls[ball] then return end
    watchedBalls[ball] = true

    -- Fire immediately if already targeting us
    if ball:GetAttribute("Target") == LP.Name then
        notify("Incoming!","Ball targeting you",2)
        doParry(ball, false)
    end

    -- Fire the moment Target changes to our name
    pcall(function()
        ball:GetAttributeChangedSignal("Target"):Connect(function()
            if ball:GetAttribute("Target") == LP.Name then
                notify("Incoming!","Ball targeting you",2)
                -- Fire 3 bursts over 200ms to cover all timing
                doParry(ball, false)
                task.delay(0.08, function() if ball.Parent then doParry(ball, false) end end)
                task.delay(0.18, function() if ball.Parent then doParry(ball, false) end end)
            end
        end)
    end)

    -- Also fire on ball.Touched with player
    pcall(function()
        ball.Touched:Connect(function(hit)
            local char = getChar(); if not char then return end
            if hit==char or hit:IsDescendantOf(char) then
                doParry(ball, true)
            end
        end)
    end)
end

-- ── BROAD FALLBACK — scan workspace when ball not in Balls folder ──────────
-- Ball names confirmed from Dex: "balls2" inside workspace.balls
-- Also handle blue ball / yellow ball variants and generic names
local BALL_NAMES = {
    ["balls2"]=true,["Anime Ball"]=true,["AnimeBall"]=true,["Ball"]=true,
    ["blade"]=true,["BladeBall"]=true,["ball"]=true,["TheBall"]=true,
    ["blue ball"]=true,["yellow ball"]=true,["blue ball0"]=true,["yellow ball2"]=true,
}
local function getBallPart(obj)
    -- obj might be a Model — find the primary or first BasePart inside it
    if obj:IsA("BasePart") then return obj end
    if obj:IsA("Model") then
        return obj.PrimaryPart or obj:FindFirstChildWhichIsA("BasePart", true)
    end
    return nil
end
local function scanWorkspace()
    -- Try workspace.balls first (lowercase, confirmed from Dex)
    if ballsFolder then
        for _, v in pairs(ballsFolder:GetChildren()) do
            local p = getBallPart(v)
            if p then return p end
        end
    end
    -- Broad workspace scan by name or sphere shape + moving
    for _, v in pairs(workspace:GetDescendants()) do
        if BALL_NAMES[v.Name] then
            local p = getBallPart(v)
            if p and p.AssemblyLinearVelocity.Magnitude > 5 then return p end
        elseif v:IsA("BasePart") and v.Shape == Enum.PartType.Ball then
            if v.AssemblyLinearVelocity.Magnitude > 5 then return v end
        end
    end
    return nil
end

-- Watch existing balls
local pendingRemove = {}
if ballsFolder then
    for _, v in pairs(ballsFolder:GetChildren()) do
        local p = getBallPart(v)
        if p then watchBall(p) end
    end
    ballsFolder.ChildAdded:Connect(function(v)
        local p = getBallPart(v)
        if p then
            pendingRemove[p] = nil
            currentBall = p
            watchBall(p)
        end
    end)
    -- Grace period: ball sometimes reparents during clash — wait 0.5s before clearing
    ballsFolder.ChildRemoved:Connect(function(v)
        if v ~= currentBall then return end
        pendingRemove[v] = true
        task.delay(0.5, function()
            if not pendingRemove[v] then return end  -- cancelled by ChildAdded
            pendingRemove[v] = nil
            -- only clear if the ball is truly gone
            if v.Parent == nil then
                if currentBall == v then currentBall = nil end
                watchedBalls[v] = nil
                burstActive = false
                burstBall = nil
            end
        end)
    end)
else
    notify("Warning","workspace.Balls not found — broad scan active",5)
end

-- ── MAIN LOOP — TTI check using game's own formula ─────────────────────────
local loopT = 0
RS.Heartbeat:Connect(function()
    local now = tick()
    if (now-loopT) < 0.016 then return end; loopT=now

    -- If currentBall is gone, try broad scan immediately (no 0.5s gap)
    local ball = (currentBall and currentBall.Parent) and currentBall or scanWorkspace()
    if not currentBall and ball then
        currentBall = ball
        watchBall(ball)
    end

    local hrp = getHRP(); if not hrp or not ball then return end

    local dist = (ball.Position - hrp.Position).Magnitude
    local vel  = ball.AssemblyLinearVelocity.Magnitude

    -- Game's formula: (dist - 8) / vel <= 0.6 + ping
    -- Below 8 studs: always fire (close range clash)
    local fire = false
    if dist < 8 then
        fire = true
    elseif vel > 2 then
        local tti = (dist - 8) / vel
        fire = tti <= (0.6 + getPing())
    else
        fire = dist < 30
    end

    if fire then doParry(ball, dist < 8) end
end)

-- ── STARTUP REPORT ─────────────────────────────────────────────────────────
task.delay(2, function()
    local found = {}
    if ballsFolder then table.insert(found,"Balls folder") end
    if getBall()      then table.insert(found,"Ball")       end
    if findBlockFn()  then table.insert(found,"BlockFn")    end
    if findRemote()   then table.insert(found,"Remote")     end
    if findBtn()      then table.insert(found,"Button")     end
    if #found > 0 then
        notify("Anime Ball", table.concat(found," | "), 6)
    else
        notify("Anime Ball","Join a round — nothing found yet",5)
    end
end)
