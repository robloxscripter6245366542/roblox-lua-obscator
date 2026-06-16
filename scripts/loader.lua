-- SangraBB v2.1 | No-UI Blade Ball Auto-Parry
-- UNC executor/device scan → picks correct input method
-- Parry runs in spawned thread so movement is never blocked

local RunService = game:GetService("RunService")
local Players    = game:GetService("Players")
local UIS        = game:GetService("UserInputService")
local lp         = Players.LocalPlayer

if _G.SangraBBActive then _G.SangraBBActive = false task.wait(0.05) end
_G.SangraBBActive = true

-- ─── UNC / Executor / Device Scan ────────────────────────────────────────────
local Device = {}

-- executor identity
do
    local name = ""
    pcall(function()
        if type(identifyexecutor) == "function" then
            name = tostring(identifyexecutor()):lower()
        elseif type(getexecutorname) == "function" then
            name = tostring(getexecutorname()):lower()
        end
    end)
    Device.execName = name
    Device.isXeno    = name:find("xeno")    ~= nil
    Device.isDelta   = name:find("delta")   ~= nil
    Device.isVelocity= name:find("velocity")~= nil
    Device.isKRNL    = name:find("krnl")    ~= nil
    Device.isSolara  = name:find("solara")  ~= nil
    Device.isWave    = name:find("wave")    ~= nil
end

-- platform: mobile = iPad/phone, pc = desktop
do
    local touch  = UIS.TouchEnabled
    local kb     = UIS.KeyboardEnabled
    local mouse  = UIS.MouseEnabled
    Device.isMobile = touch and not kb and not mouse
    Device.isPC     = kb or mouse
    Device.platform = Device.isMobile and "mobile" or "pc"
end

-- UNC capability probe
local UNC = {
    hasVIM         = pcall(function() return game:GetService("VirtualInputManager") end),
    hasNewcclosure = type(newcclosure)    == "function",
    hasHookfunc    = type(hookfunction)   == "function",
    hasGetupvalues = type(getupvalues)    == "function",
    hasGetprotos   = type(getprotos)      == "function",
    hasGetrawmeta  = type(getrawmetatable)== "function",
    hasFiretouch   = type(firetouchinterest)  == "function",
    hasSimclick    = type(simulateclick)  == "function",
}
_G.SangraBB_UNC    = UNC
_G.SangraBB_Device = Device

-- ─── Input: pick correct parry method based on device/UNC ────────────────────
local VIM = pcall(function() return game:GetService("VirtualInputManager") end)
    and game:GetService("VirtualInputManager") or nil

local function doParry()
    -- always spawned so it never blocks PreSimulation / movement
    if Device.isMobile then
        -- mobile: simulate tap at screen centre
        if VIM and VIM.SendTouchEvent then
            local cx = cam and cam.ViewportSize.X / 2 or 0
            local cy = cam and cam.ViewportSize.Y / 2 or 0
            pcall(function() VIM:SendTouchEvent(0, Vector2.new(cx, cy), true,  game) end)
            task.wait(0.05)
            pcall(function() VIM:SendTouchEvent(0, Vector2.new(cx, cy), false, game) end)
        end
    else
        -- pc: mouse click via VIM (most reliable across executors)
        if VIM then
            pcall(function() VIM:SendMouseButtonEvent(0, 0, 0, true,  game, 0) end)
            task.wait(0.04)
            pcall(function() VIM:SendMouseButtonEvent(0, 0, 0, false, game, 0) end)
        end
    end
end

local cam = workspace.CurrentCamera

-- ─── Physics: time-to-impact ──────────────────────────────────────────────────
local function timeToImpact(bPos, bVel, pPos)
    local delta = pPos - bPos
    local closing = bVel:Dot(delta.Unit)
    if closing <= 0 then return math.huge end
    return delta.Magnitude / closing
end

-- ─── Adaptive timing window ───────────────────────────────────────────────────
local window     = 0.52   -- seconds before impact to fire
local adaptAlpha = 0.12   -- EMA learning rate
local parryCount = 0

local function adapt(successETA)
    window = window * (1 - adaptAlpha) + (successETA + 0.02) * adaptAlpha
    window = math.clamp(window, 0.18, 1.1)
end

-- ─── Ball state (metatable) ───────────────────────────────────────────────────
local function newState(ball)
    return setmetatable({ ball = ball, fired = false }, {
        __index = function(s, k)
            if k == "alive" then return s.ball and s.ball.Parent ~= nil end
        end,
    })
end

local states = {}  -- ball → state

local function track(ball)
    if states[ball] then return end
    states[ball] = newState(ball)
    pcall(function()
        ball:GetAttributeChangedSignal("target"):Connect(function()
            if states[ball] then states[ball].fired = false end
        end)
    end)
end

local function untrack(ball)
    states[ball] = nil
end

-- ─── Ball folder watcher ──────────────────────────────────────────────────────
local ballsFolder = workspace:WaitForChild("Balls", 20)
if ballsFolder then
    for _, b in ipairs(ballsFolder:GetChildren()) do track(b) end
    ballsFolder.ChildAdded:Connect(function(b) task.wait() track(b) end)
    ballsFolder.ChildRemoved:Connect(function(b) untrack(b) end)
end

-- background scan for hidden ball containers (memory-style sweep)
task.spawn(function()
    while _G.SangraBBActive do
        for _, obj in ipairs(workspace:GetDescendants()) do
            if not states[obj] then
                local ok, v = pcall(function() return obj:GetAttribute("realBall") end)
                if ok and v ~= nil then track(obj) end
            end
        end
        task.wait(1.5)
    end
end)

-- ─── PreSimulation: parry check (never yields — spawns parry thread) ──────────
local parrying = false

RunService.PreSimulation:Connect(function()
    if not _G.SangraBBActive then return end
    local char = lp.Character
    if not char then return end
    local hrp = char:FindFirstChild("HumanoidRootPart")
    if not hrp then return end
    local ppos = hrp.Position
    local name = lp.Name

    local bestBall, bestETA = nil, math.huge

    for ball, state in pairs(states) do
        if ball and ball.Parent and not state.fired
            and ball:GetAttribute("target") == name
        then
            local vel = ball:FindFirstChild("zoomies")
            if vel then
                local eta = timeToImpact(ball.Position, vel.VectorVelocity, ppos)
                if eta < bestETA then bestBall = ball; bestETA = eta end
            end
        end
    end

    if bestBall and bestETA <= window and not parrying then
        parrying = true
        local capturedETA = bestETA
        local capturedBall = bestBall
        if states[capturedBall] then states[capturedBall].fired = true end
        parryCount += 1
        adapt(capturedETA)
        task.spawn(function()
            doParry()
            task.wait(0.1)
            parrying = false
        end)
    end
end)
