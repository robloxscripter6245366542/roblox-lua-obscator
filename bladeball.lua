-- bladeball.lua — Blade Ball auto-parry macro
-- Fires Block every frame when ball is incoming, VU tap + remote + direct fn
print("[BB] Loading Blade Ball macro...")

local Players = game:GetService("Players")
local RS      = game:GetService("RunService")
local UIS     = game:GetService("UserInputService")
local SG      = game:GetService("StarterGui")
local cam     = workspace.CurrentCamera
local LP      = Players.LocalPlayer
local PGui    = LP:WaitForChild("PlayerGui", 10)
local VU      = game:GetService("VirtualUser")

local function notify(t, m, d)
    pcall(function()
        SG:SetCore("SendNotification", {Title=t, Text=m, Duration=d or 4})
    end)
    print("[BB] "..t..": "..m)
end

notify("Blade Ball","Macro loading...", 3)

-- ── Helpers ──────────────────────────────────────────────────────────────
local function getChar() return LP.Character end
local function getHRP()
    local c = getChar()
    return c and c:FindFirstChild("HumanoidRootPart")
end

-- ── UNC availability ──────────────────────────────────────────────────────
local HAS_GC    = type(getgc)           == "function"
local HAS_CONNS = type(getconnections)  == "function"
local HAS_ENV   = type(getsenv)         == "function"
local HAS_FIRE  = type(firesignal)      == "function"
local getUV     = (type(debug)=="table" and type(debug.getupvalues)=="function"
                   and debug.getupvalues)
               or (type(getupvalues)=="function" and getupvalues)
               or nil

-- ── Ball detection — Blade Ball specific + generic fallback ───────────────
-- Blade Ball: ball part is named "Blade" and is a small BasePart
local BALL_NAMES = {
    "blade", "ball", "orb", "sphere", "projectile",
    "fireball", "shot", "bullet", "object"
}

local ballCache   = nil
local hookedBalls = {}

local function isBall(v)
    if not v:IsA("BasePart") then return false end
    if v.Anchored then return false end
    -- Not a player character part
    for _, p in pairs(Players:GetPlayers()) do
        if p.Character and v:IsDescendantOf(p.Character) then return false end
    end
    local n = v.Name:lower()
    for _, k in ipairs(BALL_NAMES) do
        if n:find(k, 1, true) then return true end
    end
    -- Small sphere shape
    if v.Shape == Enum.PartType.Ball and v.Size.Magnitude < 10 then return true end
    return false
end

workspace.DescendantAdded:Connect(function(v)
    if isBall(v) then
        ballCache = v
        notify("Ball", v.Name.." spotted", 2)
    end
end)
workspace.DescendantRemoving:Connect(function(v)
    if v == ballCache then ballCache = nil; hookedBalls[v] = nil end
end)
for _, v in pairs(workspace:GetDescendants()) do
    if isBall(v) then ballCache = v; break end
end

local function findBall()
    if ballCache and ballCache.Parent then return ballCache end
    ballCache = nil
    -- Fallback scan
    for _, v in pairs(workspace:GetDescendants()) do
        if isBall(v) then ballCache = v; return v end
    end
    -- getinstances fallback
    if type(getinstances) == "function" then
        local ok, all = pcall(getinstances)
        if ok and all then
            for _, v in ipairs(all) do
                if isBall(v) and v.Parent then ballCache = v; return v end
            end
        end
    end
    return nil
end

-- ── Block button ──────────────────────────────────────────────────────────
local blockBtn = nil
local function findBtn()
    if blockBtn and blockBtn.Parent then return blockBtn end
    for _, v in pairs(PGui:GetDescendants()) do
        if v.Name == "Block" and (v:IsA("GuiButton") or v:IsA("TextButton") or v:IsA("ImageButton")) then
            blockBtn = v
            notify("Found", "Block button: "..v:GetFullName(), 3)
            return v
        end
    end
end

-- ── Block remote (RemoteEvent OR RemoteFunction) ──────────────────────────
local blockRemote = nil
local function findRemote()
    if blockRemote and blockRemote.Parent then return blockRemote end
    for _, v in pairs(game:GetService("ReplicatedStorage"):GetDescendants()) do
        if (v:IsA("RemoteEvent") or v:IsA("RemoteFunction")) and v.Name == "Block" then
            blockRemote = v
            notify("Found", "Block remote: "..v:GetFullName(), 3)
            return v
        end
    end
end

-- ── Block function (v_u_1.Block from SwordController) ────────────────────
local blockFn = nil

local function upSearch(fn)
    if not getUV or type(fn) ~= "function" then return nil end
    local ok, uvs = pcall(getUV, fn)
    if not ok then return nil end
    for _, uv in pairs(uvs or {}) do
        if type(uv) == "table" and type(uv.Block) == "function" then
            return uv.Block
        end
    end
end

local function findBlockFn()
    if blockFn then return blockFn end

    -- Strategy 1: TouchTapInWorld → upvalues → v_u_1.Block
    if HAS_CONNS then
        local ok, conns = pcall(getconnections, UIS.TouchTapInWorld)
        if ok and conns then
            for _, c in ipairs(conns) do
                local fn; pcall(function() fn = c.Function end)
                local b = upSearch(fn)
                if b then
                    blockFn = b
                    notify("Found","Block fn via TTI", 3)
                    return b
                end
            end
        end
    end

    -- Strategy 2: Block button connections
    local btn = findBtn()
    if btn and HAS_CONNS then
        for _, ev in ipairs({"Activated","MouseButton1Click","MouseButton1Down","InputBegan"}) do
            local ok, conns = pcall(function() return getconnections(btn[ev]) end)
            if ok and conns then
                for _, c in ipairs(conns) do
                    local fn; pcall(function() fn = c.Function end)
                    local b = upSearch(fn) or (type(fn)=="function" and fn or nil)
                    if b then
                        blockFn = b
                        notify("Found","Block fn via btn "..ev, 3)
                        return b
                    end
                end
            end
        end
    end

    -- Strategy 3: getsenv SwordController
    if HAS_ENV then
        local paths = {
            function()
                return LP:FindFirstChild("PlayerScripts")
                    and LP.PlayerScripts:FindFirstChild("Scripts")
                    and LP.PlayerScripts.Scripts:FindFirstChild("SwordController")
            end,
            function()
                local sp = game:GetService("StarterPlayer"):FindFirstChild("StarterPlayerScripts")
                return sp and sp:FindFirstChild("Scripts") and sp.Scripts:FindFirstChild("SwordController")
            end,
        }
        for _, pFn in ipairs(paths) do
            local sc; pcall(function() sc = pFn() end)
            if sc then
                local ok, env = pcall(getsenv, sc)
                if ok and env then
                    for _, v in pairs(env) do
                        if type(v)=="table" and type(v.Block)=="function" then
                            blockFn = v.Block
                            notify("Found","Block fn via getsenv", 3)
                            return v.Block
                        end
                    end
                end
            end
        end
    end

    -- Strategy 4: getgc table scan
    if HAS_GC then
        local ok, gc = pcall(getgc, false)
        if ok and gc then
            for _, v in ipairs(gc) do
                if type(v)=="table" and type(v.Block)=="function"
                and type(v.ShowShield)=="function" then
                    blockFn = v.Block
                    notify("Found","Block fn via getgc", 3)
                    return v.Block
                end
            end
        end
    end

    return nil
end

-- Retry every 3s until found
task.spawn(function()
    while not blockFn do
        findBlockFn()
        task.wait(3)
    end
    notify("Ready","Block fn locked — parry ON!", 4)
end)

-- Clear cache on respawn
LP.CharacterAdded:Connect(function()
    task.wait(1.5)
    blockFn = nil
    findBlockFn()
end)

-- ── Fire parry — all methods at once ─────────────────────────────────────
local function fireBlock(ball)
    -- 1. Direct Block() call
    pcall(function()
        local fn = findBlockFn()
        if type(fn) == "function" then fn() end
    end)

    -- 2. RemoteEvent:FireServer or RemoteFunction:InvokeServer
    pcall(function()
        local r = findRemote(); if not r then return end
        local hrp = getHRP()
        local y = (hrp and ball) and (ball.Position - hrp.Position).Unit.Y or 0
        if r:IsA("RemoteEvent") then
            r:FireServer(y)
        else
            r:InvokeServer(y)
        end
    end)

    -- 3. VirtualUser tap
    pcall(function()
        local btn = findBtn(); if not btn then return end
        local pos = btn.AbsolutePosition + btn.AbsoluteSize * 0.5
        VU:Button1Down(pos, cam.CFrame)
        task.wait(0.04)
        VU:Button1Up(pos, cam.CFrame)
    end)

    -- 4. firesignal on ball.Touched
    if HAS_FIRE and ball then
        pcall(function()
            local hrp = getHRP(); if not hrp then return end
            firesignal(ball.Touched, hrp)
        end)
    end

    -- 5. getconnections on ball.Touched → manually call each handler
    if HAS_CONNS and ball then
        pcall(function()
            local hrp = getHRP(); if not hrp then return end
            local ok, conns = pcall(getconnections, ball.Touched)
            if ok and conns then
                for _, c in ipairs(conns) do
                    local fn; pcall(function() fn = c.Function end)
                    if type(fn) == "function" then pcall(fn, hrp) end
                end
            end
        end)
    end
end

-- ── ball.Touched hook — fires at exact impact ─────────────────────────────
local function hookBall(ball)
    if hookedBalls[ball] then return end
    hookedBalls[ball] = true
    pcall(function()
        ball.Touched:Connect(function(hit)
            local char = getChar(); if not char then return end
            if hit == char or hit:IsDescendantOf(char) then
                fireBlock(ball)
                task.delay(0.03, function() if ball.Parent then fireBlock(ball) end end)
            end
        end)
    end)
end

-- ── Velocity + TTI tracking ───────────────────────────────────────────────
local velBuf = {}; local velT = 0; local velAvg = 0; local lastPos = nil
local function updateVel(ball)
    if not ball then velAvg = 0; lastPos = nil; return end
    local now = tick(); local dt = now - velT
    if dt > 0.005 and dt < 0.5 and lastPos then
        local spd = (ball.Position - lastPos).Magnitude / dt
        if spd > 1 then
            table.insert(velBuf, spd)
            if #velBuf > 10 then table.remove(velBuf, 1) end
            local s = 0; for _, v in ipairs(velBuf) do s = s + v end
            velAvg = s / #velBuf
        end
    end
    lastPos = ball.Position; velT = now
end

-- Ping compensation
local ping = 0.10; local pingT = 0
local function getPing()
    if (tick()-pingT) < 1 then return ping end; pingT = tick()
    pcall(function()
        ping = math.clamp(
            game:GetService("Stats").Network.ServerStatsItem["Data Ping"]:GetValue() / 1000,
            0.02, 0.6)
    end)
    return ping
end

-- ── Burst throttle ────────────────────────────────────────────────────────
local lastFire   = 0
local burstBall  = nil
local burstActive = false

local function doParry(ball, dist)
    local close = dist < 10
    if not close then
        if burstActive then return end
        if ball == burstBall then return end
    end
    local cd = close and 0.05 or 0.12
    if (tick() - lastFire) < cd then return end
    lastFire = tick()

    if close then
        -- Dense burst for clash
        fireBlock(ball)
        for _, t in ipairs({0.02,0.04,0.06,0.08,0.10,0.12,0.15,0.18,0.20}) do
            task.delay(t, function() if ball and ball.Parent then fireBlock(ball) end end)
        end
    else
        burstActive = true; burstBall = ball
        fireBlock(ball)
        task.delay(0.07, function() if ball and ball.Parent then fireBlock(ball) end end)
        task.delay(0.15, function()
            if ball and ball.Parent then fireBlock(ball) end
            burstActive = false
        end)
    end
end

workspace.DescendantRemoving:Connect(function(v)
    if v == ballCache then burstActive = false; burstBall = nil end
end)

-- ── Main loop 60 Hz ───────────────────────────────────────────────────────
local loopT = 0
RS.Heartbeat:Connect(function()
    local now = tick()
    if (now - loopT) < 0.016 then return end; loopT = now

    local ball = findBall()
    local hrp  = getHRP(); if not hrp then return end

    updateVel(ball)
    if ball then hookBall(ball) end

    if ball then
        local dist = (ball.Position - hrp.Position).Magnitude
        local fire = false
        if dist < 10 then
            fire = true
        elseif velAvg > 2 then
            fire = (dist / velAvg) < (0.22 + getPing())
        else
            fire = dist < 40
        end
        if fire then doParry(ball, dist) end
    end
end)

-- ── Startup report ────────────────────────────────────────────────────────
task.delay(2, function()
    local found = {}
    if findBlockFn() then table.insert(found, "BlockFn") end
    if findRemote()  then table.insert(found, "Remote")  end
    if findBtn()     then table.insert(found, "Button")  end
    if #found > 0 then
        notify("Blade Ball","Ready: "..table.concat(found," + "), 5)
    else
        notify("Blade Ball","Join a round — finding methods...", 5)
    end
end)
