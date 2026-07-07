-- ============================================================================
--  Anime Ball Hub - loader / bootstrap  (this is the PUBLIC file you share)
--
--  It authenticates with the animeballhub server using your KEY + this device's
--  HWID, and only runs the protected script the server returns. The real script
--  is never exposed at a public URL - it only comes back over an authorized,
--  HWID-locked request.
--
--  Usage: set your key, then run this via loadstring/HttpGet. Or set the key
--  from your executor first:  getgenv().AnimeBallKey = "YOUR-KEY"
-- ============================================================================

local KEY = (getgenv and getgenv().AnimeBallKey) or "PASTE-YOUR-KEY-HERE"

-- Your Vercel deployment domain + the authenticator route. Verify the domain
-- matches your project's production URL.
local ENDPOINT = "https://roblox-lua-obscator.vercel.app/api/animeballhub"

local HttpService = game:GetService("HttpService")

-- Stable per-device id. RbxAnalyticsService:GetClientId() exists in every
-- executor and is tied to the install; fall back to an executor gethwid().
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

-- Executor HTTP request function (POST). game:HttpGet only does GET, so we need
-- the executor's request() to send the key in a POST body.
local function httpRequest(opts)
    local r = (syn and syn.request)
        or (http and http.request)
        or http_request
        or request
        or (fluxus and fluxus.request)
    if not r then error("[AnimeBall] your executor has no HTTP request function") end
    return r(opts)
end

local function boot()
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
            warn("[AnimeBall] failed to load protected script: " .. tostring(err))
        end
    else
        warn("[AnimeBall] authentication failed (" .. tostring(status) .. "): " .. tostring(data))
        warn("[AnimeBall] check your key, or your HWID may be locked to another device.")
    end
end

local ok, err = pcall(boot)
if not ok then warn("[AnimeBall] loader error: " .. tostring(err)) end
