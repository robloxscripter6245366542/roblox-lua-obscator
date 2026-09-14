-- ============================================================
--  Universal ESP  –  Loadstring Loader
--
--  Paste this ONE LINE into Delta (iOS / iPadOS / Android / PC),
--  Xeno, Solara, Codex, Wave, Fluxus, Synapse X, KRNL, or any
--  executor:
--
--    loadstring(game:HttpGet("https://raw.githubusercontent.com/robloxscripter6245366542/roblox-lua-obscator/main/UniversalESP_Loader.lua"))()
--
--  This loader fetches and runs the latest UniversalESP_TeamCheck.lua,
--  so the link never changes even when the script is updated.
--
--  Features: body-outline ESP with opposite-team detection (ESPs
--  everyone if you're on no team) + a curved draggable on/off button
--  that works on mobile.
-- ============================================================

local URL = "https://raw.githubusercontent.com/robloxscripter6245366542/roblox-lua-obscator/main/UniversalESP_TeamCheck.lua"

local ok, body = pcall(function() return game:HttpGet(URL, true) end)
if not ok or not body then
    -- fallback to any executor-specific HTTP request fn
    local req = (syn and syn.request) or (http and http.request) or http_request or request
        or (fluxus and fluxus.request)
    if req then
        local r = req({ Url = URL, Method = "GET" })
        if r and r.Body then body = r.Body end
    end
end

if not body then
    warn("[Universal ESP] Could not fetch the script (HTTP blocked). Paste UniversalESP_TeamCheck.lua directly instead.")
    return
end

local fn, err = loadstring(body)
if not fn then
    warn("[Universal ESP] Compile error: " .. tostring(err))
    return
end

local ran, result = pcall(fn)
if not ran then
    warn("[Universal ESP] Runtime error: " .. tostring(result))
    return
end

-- The ESP module returns its API table; expose it for convenience.
return result
