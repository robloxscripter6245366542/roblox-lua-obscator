-- AutoClicker v2.0  (no GUI / keybind toggle)
-- Target: 50,000 CPS via per-frame bursts, time-budgeted so it NEVER crashes/freezes.
-- Works while you walk/run/jump. You can still click manually. Toggle anytime.
--
-- Controls:
--   [E]                  toggle on/off
--   getgenv().AutoClicker:Stop()      stop from console
--   getgenv().AutoClicker:Start()     start from console
--   getgenv().AutoClicker.CPS = 50000 change rate live

local AC = {
    Enabled    = false,
    CPS        = 50000,   -- target clicks per second
    Budget     = 0.004,   -- max seconds spent clicking per frame (keeps game alive -> never crash)
    Method     = "none",
    ClickCount = 0,
}

-- Expose a global handle so you can control it from the console anytime
if type(getgenv) == "function" then
    getgenv().AutoClicker = AC
end

-- ── UNC function resolver ─────────────────────────────────────────────────────
local function resolve(name)
    if type(getgenv) == "function" then
        local v = getgenv()[name]
        if type(v) == "function" then return v end
    end
    if type(_G[name]) == "function" then return _G[name] end
    return nil
end

local fn = {
    mouse1click   = resolve("mouse1click"),
    mouse1press   = resolve("mouse1press"),
    mouse1release = resolve("mouse1release"),
    mouse2click   = resolve("mouse2click"),
    mouse2press   = resolve("mouse2press"),
    mouse2release = resolve("mouse2release"),
    touchTap      = resolve("touchTap"),
    touchStart    = resolve("touchStart"),
    touchEnd      = resolve("touchEnd"),
}

-- Safe touch position: centre of screen, never the joystick corner
local function getSafePos()
    local cam = workspace.CurrentCamera
    local vp  = cam and cam.ViewportSize or Vector2.new(800, 600)
    return Vector2.new(vp.X * 0.5, vp.Y * 0.5)
end

-- ── Single click (NO yields — must be instant for burst loop) ─────────────────
-- For top speed we only use the fastest no-wait methods.
-- mouse1click / mouse2click / touchTap fire instantly with no release delay.
local clickFn, methodName

if fn.mouse1click then
    clickFn = fn.mouse1click
    methodName = "mouse1click"
elseif fn.mouse2click then
    clickFn = fn.mouse2click
    methodName = "mouse2click"
elseif fn.touchTap then
    local pos = getSafePos()
    clickFn = function() fn.touchTap({pos}) end
    methodName = "touchTap"
elseif fn.mouse1press and fn.mouse1release then
    -- press+release with no wait (still instant, just two calls)
    clickFn = function() fn.mouse1press(); fn.mouse1release() end
    methodName = "mouse1press/release"
elseif fn.mouse2press and fn.mouse2release then
    clickFn = function() fn.mouse2press(); fn.mouse2release() end
    methodName = "mouse2press/release"
elseif fn.touchStart and fn.touchEnd then
    local pos = getSafePos()
    clickFn = function() fn.touchStart({pos}); fn.touchEnd({pos}) end
    methodName = "touchStart/End"
else
    -- VirtualInputManager fallback (no waits)
    local vim = game:GetService("VirtualInputManager")
    clickFn = function()
        vim:SendMouseButtonEvent(0, 0, 0, true,  game, 0)
        vim:SendMouseButtonEvent(0, 0, 0, false, game, 0)
    end
    methodName = "VirtualInputManager"
end
AC.Method = methodName

-- ── Burst engine ──────────────────────────────────────────────────────────────
-- We fire on the EARLIEST point of every frame at the highest render priority,
-- so a click lands before AutoParry's reaction tick -> we win the race.
-- Each frame fires up to (CPS / fps) clicks, capped by a time budget so the
-- frame always finishes -> game never hangs or crashes.
local RunSvc = game:GetService("RunService")

local lastClock = os.clock()

local function burst()
    if not AC.Enabled then return end

    local now = os.clock()
    local dt  = now - lastClock
    lastClock = now
    if dt <= 0 then dt = 1/60 end

    -- clicks needed this frame to reach the target rate
    local quota = AC.CPS * dt
    if quota < 1 then quota = 1 end

    local startT = os.clock()
    local fired  = 0
    local budget = AC.Budget

    while fired < quota do
        pcall(clickFn)             -- protected: one bad call can't crash the game
        fired = fired + 1
        if (os.clock() - startT) >= budget then  -- anti-crash time cap
            break
        end
    end

    AC.ClickCount = AC.ClickCount + fired
end

-- Prefer BindToRenderStep at the EARLIEST priority (runs before anything else
-- in the frame, including most AutoParry loops). Fall back to Heartbeat on
-- environments without a render step (e.g. server-side).
local bound = false
local ok = pcall(function()
    RunSvc:BindToRenderStep("AutoClickerBurst", Enum.RenderPriority.First.Value - 1, burst)
    bound = true
end)
if not (ok and bound) then
    RunSvc.Heartbeat:Connect(burst)
end

-- ── Toggle / control API ──────────────────────────────────────────────────────
function AC:Start()
    self.Enabled = true
end

function AC:Stop()
    self.Enabled = false
end

function AC:Toggle()
    self.Enabled = not self.Enabled
    return self.Enabled
end

-- ── Keybind: E (toggle). Responsive even mid-click because the burst loop yields
-- every frame, so InputBegan always gets to run. ──────────────────────────────
local UIS = game:GetService("UserInputService")
UIS.InputBegan:Connect(function(input, gp)
    if gp then return end
    if input.KeyCode == Enum.KeyCode.E then
        local on = AC:Toggle()
        print("[AutoClicker] " .. (on and "ON" or "OFF")
            .. " | " .. AC.ClickCount .. " clicks | " .. AC.Method)
    end
end)

print("[AutoClicker v2] Loaded | Method: " .. AC.Method
    .. " | Target: " .. AC.CPS .. " CPS | Press [E] to toggle"
    .. " | console: getgenv().AutoClicker:Stop()")
