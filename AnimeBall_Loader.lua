-- ============================================================
--  AnimeBall_Loader.lua  –  Robust loader + kill switch + perf pass
--
--  A single self-contained file you can run anywhere. It:
--
--   1. ROBUST LOADER  – fetches the target script with auto-retries
--      and clear on-screen messages, instead of silently doing
--      nothing on a network blip / bad fetch.
--
--   2. KILL SWITCH    – a floating DESTROY button (+ End key +
--      getgenv().AnimeBall_Destroy()) that disconnects every loop
--      and hook the target starts and removes the spheres / labels
--      / its UI. Nothing else is needed to stop it short of rejoining.
--
--   3. PERF / CONFIG  – the target auto-saves to disk every 3s
--      forever; this de-dupes writefile so it only touches the disk
--      when a setting actually changed. Same behaviour, far less I/O.
--
--  It does NOT edit the target — everything is done by wrapping the
--  environment the target runs in, so it stays a drop-in loader.
--  Every wrap is pcall-guarded: if anything is unsupported on your
--  executor it silently falls back to just running the target.
-- ============================================================

-- ── Config ────────────────────────────────────────────────
local CONFIG = {
    -- What to load. Override with getgenv().AnimeBall_TargetUrl before running.
    TargetUrl  = "https://raw.githubusercontent.com/robloxscripter6245366542/"
               .. "roblox-lua-obscator/main/user_scripts/anime_ball_autoparry.lua",

    MaxRetries = 5,       -- fetch attempts before giving up
    BaseDelay  = 2,       -- seconds; backoff doubles each retry (2,4,8,...)
    MaxDelay   = 16,      -- cap the backoff so it never waits forever

    -- Instance names the target creates, swept on Destroy as a safety net
    -- (in case some were made before our wrappers were installed).
    SweepNames = { "VisualDetector", "PlayerDetector_", "SpeedLabel" },

    KillKey    = Enum.KeyCode.End,  -- press to trigger the kill switch
}
-- ──────────────────────────────────────────────────────────

local Players    = game:GetService("Players")
local StarterGui = game:GetService("StarterGui")
local UIS        = game:GetService("UserInputService")

-- Grab REAL references up-front so our own wrappers never wrap themselves.
local realTask       = task
local realInstanceNew = Instance.new
local realWritefile  = rawget(getgenv and getgenv() or _G, "writefile") or writefile

local function notify(text, dur)
    print("[AnimeBall_Loader] " .. text)
    pcall(function()
        StarterGui:SetCore("SendNotification", {
            Title = "AnimeBall Loader", Text = text, Duration = dur or 5,
        })
    end)
end

-- ── Lifecycle registry (everything the target spins up) ───
local reg = { conns = {}, threads = {}, insts = {}, alive = true, unhook = nil }
getgenv().AnimeBall = reg

-- ── (2 + wrapping) Managed environment ────────────────────
-- We hand the target a custom function-environment where `task`,
-- `Instance` and `writefile` are our tracked versions, and leave every
-- other global (game, workspace, RunService, ...) untouched so nothing
-- can break from proxying.

-- task wrapper: record every spawned thread so we can cancel the loops.
local taskWrap = setmetatable({}, { __index = realTask })
local function trackThread(th)
    if type(th) == "thread" then reg.threads[#reg.threads + 1] = th end
    return th
end
taskWrap.spawn = function(...) return trackThread(realTask.spawn(...)) end
taskWrap.defer = function(...) return trackThread(realTask.defer(...)) end
taskWrap.delay = function(...) return trackThread(realTask.delay(...)) end

-- Instance wrapper: record every created instance (spheres, labels, the
-- whole UI) so Destroy can remove them. Returns the REAL instance, so the
-- target behaves exactly as before.
local instanceWrap = setmetatable({}, { __index = Instance })
instanceWrap.new = function(...)
    local inst = realInstanceNew(...)
    reg.insts[#reg.insts + 1] = inst
    return inst
end

-- writefile de-dupe: skip the disk write when the content is unchanged.
-- This turns the target's every-3s "save" into a no-op unless a setting
-- actually changed — identical behaviour, a fraction of the I/O.
local lastWritten = {}
local function writeDedupe(path, content, ...)
    if lastWritten[path] == content then return end
    lastWritten[path] = content
    if realWritefile then return realWritefile(path, content, ...) end
end

-- Capture every :Connect the target makes (loops/hooks) via a namecall
-- hook, so we can disconnect them all later. Guarded — not every executor
-- exposes hookmetamethod/getnamecallmethod.
local function installConnectHook()
    local hookmeta = rawget(getgenv(), "hookmetamethod") or hookmetamethod
    local getncm   = rawget(getgenv(), "getnamecallmethod") or getnamecallmethod
    if not (hookmeta and getncm) then return end
    local ok = pcall(function()
        local old
        old = hookmeta(game, "__namecall", function(self, ...)
            local res = old(self, ...)
            if reg.alive then
                local m = getncm()
                if (m == "Connect" or m == "ConnectParallel" or m == "Once")
                   and typeof(res) == "RBXScriptConnection" then
                    reg.conns[#reg.conns + 1] = res
                end
            end
            return res
        end)
        reg.unhook = old  -- keep the original around (restored on Destroy)
    end)
    if not ok then reg.unhook = nil end
end

-- Build a fenv that only overrides the three globals we manage.
local function managedEnv()
    local base = getfenv(1)
    local overrides = { task = taskWrap, Instance = instanceWrap, writefile = writeDedupe }
    return setmetatable({}, {
        __index    = function(_, k) local o = overrides[k]; if o ~= nil then return o end return base[k] end,
        __newindex = function(_, k, v) base[k] = v end,
    })
end

-- ── (1) Robust fetch with retries ─────────────────────────
local function fetchSource(url)
    local httpget = rawget(getgenv(), "httpget") or function(u)
        return game:HttpGetAsync(u)
    end
    local delay = CONFIG.BaseDelay
    local lastErr = "unknown error"
    for attempt = 1, CONFIG.MaxRetries do
        local ok, res = pcall(httpget, url)
        if ok and type(res) == "string" and #res > 0 and not res:match("^%s*[<{]") then
            return res
        end
        lastErr = (ok and "empty / non-Lua response") or tostring(res)
        if attempt < CONFIG.MaxRetries then
            notify(("Fetch failed (%s). Retry %d/%d in %ds...")
                :format(lastErr:sub(1, 60), attempt, CONFIG.MaxRetries, delay), 4)
            realTask.wait(delay)
            delay = math.min(delay * 2, CONFIG.MaxDelay)
        end
    end
    return nil, lastErr
end

-- ── (2) Kill switch ───────────────────────────────────────
local function destroy()
    if not reg.alive then return end
    reg.alive = false
    getgenv().AnimeBall_KILL = true

    -- Disconnect every captured connection (loops/hooks).
    for _, c in ipairs(reg.conns) do pcall(function() c:Disconnect() end) end
    -- Cancel every spawned thread (the while-loops, incl. the auto-save).
    local self = coroutine.running()
    for _, th in ipairs(reg.threads) do
        if th ~= self then pcall(realTask.cancel, th) end
    end
    -- Destroy every created instance (spheres, labels, the whole UI).
    for _, inst in ipairs(reg.insts) do pcall(function() inst:Destroy() end) end

    -- Safety-net sweep for anything made before our wrappers were live.
    pcall(function()
        for _, obj in ipairs(workspace:GetDescendants()) do
            for _, n in ipairs(CONFIG.SweepNames) do
                if obj.Name == n or obj.Name:sub(1, #n) == n then
                    pcall(function() obj:Destroy() end)
                    break
                end
            end
        end
    end)

    -- Restore the namecall hook if we installed one.
    if reg.unhook then
        local restore = rawget(getgenv(), "hookmetamethod") or hookmetamethod
        pcall(function() restore(game, "__namecall", reg.unhook) end)
    end

    notify("Destroyed - all loops, hooks, spheres & UI removed.", 5)
end
getgenv().AnimeBall_Destroy = destroy

-- Floating DESTROY button (built with the REAL Instance.new so it isn't
-- swept along with the target's stuff). Falls back to key/global if the
-- executor blocks GUI creation.
local function buildButton()
    local ok = pcall(function()
        local gui = realInstanceNew("ScreenGui")
        gui.Name = "AnimeBall_KillSwitch"
        gui.ResetOnSpawn = false
        gui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
        local parent = (gethui and gethui()) or game:GetService("CoreGui")
        pcall(function() if syn and syn.protect_gui then syn.protect_gui(gui) end end)
        gui.Parent = parent

        local btn = realInstanceNew("TextButton")
        btn.Size = UDim2.new(0, 120, 0, 34)
        btn.Position = UDim2.new(0, 12, 0, 120)
        btn.BackgroundColor3 = Color3.fromRGB(180, 30, 40)
        btn.TextColor3 = Color3.fromRGB(255, 255, 255)
        btn.Font = Enum.Font.GothamBold
        btn.TextSize = 15
        btn.Text = "DESTROY"
        btn.AutoButtonColor = true
        btn.Parent = gui
        realInstanceNew("UICorner").Parent = btn

        -- Simple drag so it never blocks the target's own UI.
        local dragging, dragStart, startPos
        btn.InputBegan:Connect(function(i)
            if i.UserInputType == Enum.UserInputType.MouseButton1
               or i.UserInputType == Enum.UserInputType.Touch then
                dragging = true; dragStart = i.Position; startPos = btn.Position
            end
        end)
        UIS.InputChanged:Connect(function(i)
            if dragging and (i.UserInputType == Enum.UserInputType.MouseMovement
               or i.UserInputType == Enum.UserInputType.Touch) then
                local d = i.Position - dragStart
                btn.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + d.X,
                                         startPos.Y.Scale, startPos.Y.Offset + d.Y)
            end
        end)
        UIS.InputEnded:Connect(function(i)
            if i.UserInputType == Enum.UserInputType.MouseButton1
               or i.UserInputType == Enum.UserInputType.Touch then dragging = false end
        end)

        btn.MouseButton1Click:Connect(function()
            destroy()
            pcall(function() gui:Destroy() end)
        end)
    end)
    if not ok then
        notify("Couldn't build the button - press End or run getgenv().AnimeBall_Destroy()", 6)
    end
end

-- End key always works as a fallback trigger.
UIS.InputBegan:Connect(function(input, gpe)
    if not gpe and input.KeyCode == CONFIG.KillKey then destroy() end
end)

-- ── Go ────────────────────────────────────────────────────
local function main()
    local url = getgenv().AnimeBall_TargetUrl or CONFIG.TargetUrl
    notify("Fetching target...", 3)

    local src, err = fetchSource(url)
    if not src then
        notify("Load FAILED after " .. CONFIG.MaxRetries .. " tries: " .. tostring(err), 8)
        return
    end

    local chunk, compileErr = loadstring(src)
    if not chunk then
        notify("Target has a syntax error: " .. tostring(compileErr), 8)
        return
    end

    installConnectHook()
    pcall(setfenv, chunk, managedEnv())  -- best-effort; harmless if unsupported

    buildButton()
    notify("Loaded. Press End or the DESTROY button to unload.", 5)

    local ok, runErr = pcall(chunk)
    if not ok then
        notify("Target errored while running: " .. tostring(runErr), 8)
    end
end

main()
