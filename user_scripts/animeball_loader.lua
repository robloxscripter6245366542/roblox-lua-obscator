-- ============================================================================
--  Anime Ball Hub - loader / bootstrap  (this is the PUBLIC file you share)
--
--  Authenticates with the animeballhub server using your KEY + this device's
--  HWID and only runs the protected script it returns. The real script never
--  sits at a public URL - it only comes back over an authorized, HWID-locked
--  request.
--
--  Hardening:
--    * SILENT   - no prints/warns (set DEBUG = true to see diagnostics).
--    * EXECUTOR - refuses to run outside a real executor (blocks browser/bot
--                 scraping of the endpoint).
--    * TRIPWIRE - if a dumper/logger has hooked loadstring / the HTTP request /
--                 HttpGet to capture the script, those go from native C
--                 closures to Lua closures; we detect that and run a harmless
--                 DECOY instead of ever authenticating or fetching the real code.
--
--  Usage:  getgenv().AnimeBallKey = "YOUR-KEY"   then run this via loadstring.
-- ============================================================================

local DEBUG = false
local function log(...) if DEBUG then warn(...) end end

local KEY = (getgenv and getgenv().AnimeBallKey) or "PASTE-YOUR-KEY-HERE"
local ENDPOINT = "https://roblox-lua-obscator.vercel.app/api/animeballhub"

-- A fake, non-working script. If tampering is detected, THIS runs instead of the
-- real one - so a logger/dumper captures junk, not your code. Looks plausible,
-- does nothing.
local DECOY = table.concat({
    "local P = game:GetService('Players').LocalPlayer",
    "local ok = pcall(function() return P and P.Name end)",
    "task.wait(math.random())",
    "-- AnimeBall init",
    "if ok then return end",
})
local function runDecoy()
    local fn = loadstring(DECOY)
    if fn then pcall(fn) end
end

-- ---- tamper / environment checks -------------------------------------------
-- A genuine engine/executor function is a C closure. If iscclosure exists and
-- says a function we rely on is NOT a C closure, it's been hooked (typically to
-- log/capture) - treat the environment as unsafe.
local function nativeOk(fn)
    if type(iscclosure) ~= "function" then return true end -- can't tell -> don't false-positive
    local ok, isC = pcall(iscclosure, fn)
    if not ok then return true end
    return isC == true
end

local function environmentSafe()
    -- 1) must actually be an executor
    local looksExec = type(identifyexecutor) == "function"
        or type(getexecutorname) == "function"
        or getgenv ~= nil or syn ~= nil or fluxus ~= nil or krnl ~= nil
        or request ~= nil or http_request ~= nil or (http and http.request)
    if not looksExec then log("no executor") return false end

    -- 2) key functions must still be native (not hooked to capture the script)
    local reqFn = (syn and syn.request) or (http and http.request) or http_request or request
        or (fluxus and fluxus.request)
    if not nativeOk(loadstring) then log("loadstring hooked") return false end
    if type(reqFn) == "function" and not nativeOk(reqFn) then log("request hooked") return false end
    local ok, httpget = pcall(function() return game.HttpGet end)
    if ok and type(httpget) == "function" and not nativeOk(httpget) then log("HttpGet hooked") return false end

    return true
end

-- ---- auth + boot ------------------------------------------------------------
local HttpService = game:GetService("HttpService")

local function getHWID()
    local ok, id = pcall(function()
        return game:GetService("RbxAnalyticsService"):GetClientId()
    end)
    if ok and id and #tostring(id) > 0 then return tostring(id) end
    local fn = gethwid or get_hwid or (syn and syn.gethwid)
    if fn then
        local ok2, h = pcall(fn)
        if ok2 and h then return tostring(h) end
    end
    return "unknown-device"
end

local function httpRequest(opts)
    local r = (syn and syn.request) or (http and http.request) or http_request or request
        or (fluxus and fluxus.request)
    if not r then error("no request fn") end
    return r(opts)
end

local function boot()
    -- Tripwire: if the environment is unsafe, run the decoy and STOP. We never
    -- contact the server or touch the real script in a tampered environment.
    if not environmentSafe() then
        runDecoy()
        return
    end

    local body = HttpService:JSONEncode({ key = KEY, hwid = getHWID() })
    local resp = httpRequest({
        Url = ENDPOINT,
        Method = "POST",
        Headers = { ["Content-Type"] = "application/json" },
        Body = body,
    })

    local status = resp.StatusCode or resp.status_code or 0
    local data = resp.Body or resp.body or ""

    if status == 200 and #data > 0 then
        local fn, err = loadstring(data)
        if fn then
            fn()
        else
            log("load error: " .. tostring(err))
            runDecoy()
        end
    else
        log("auth failed (" .. tostring(status) .. "): " .. tostring(data))
        -- Wrong/missing key or HWID locked elsewhere: run the decoy so a
        -- failed attempt still "runs something" and reveals nothing.
        runDecoy()
    end
end

pcall(boot)
