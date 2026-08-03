-- ============================================================
--  ⚔️  BLADE BALL HUB  –  Loadstring Loader
--
--  Paste this ONE LINE into Delta (iOS / iPadOS / Android / PC),
--  Xeno, Solara, Codex, Wave, Fluxus, Synapse X, KRNL, or any
--  executor:
--
--    loadstring(game:HttpGet("https://raw.githubusercontent.com/robloxscripter6245366542/roblox-lua-obscator/main/BladeBall_Loader.lua"))()
--
--  This loader fetches and runs the latest "Blade ball claude" hub,
--  so the link never changes even when the hub is updated.
--
--  Parry routing: defaults to the safe Native/Direct sword-controller
--  actions (no honeypot Remote fallback).
-- ============================================================

local URL = "https://raw.githubusercontent.com/robloxscripter6245366542/roblox-lua-obscator/main/Blade%20ball%20claude"

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
    warn("[Blade Ball Hub] Could not fetch the hub (HTTP blocked). Paste the hub source directly instead.")
    return
end

local fn, err = loadstring(body)
if not fn then
    warn("[Blade Ball Hub] Compile error: " .. tostring(err))
    return
end

local ran, rerr = pcall(fn)
if not ran then
    warn("[Blade Ball Hub] Runtime error: " .. tostring(rerr))
end
