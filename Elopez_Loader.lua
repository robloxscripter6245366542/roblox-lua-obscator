-- ============================================================
--  🐉  LEVIATHAN HUB  –  Loadstring Loader
--
--  Paste this ONE LINE into Delta (iOS / iPadOS / Android / PC),
--  Xeno, Solara, Codex, Wave, Fluxus, Synapse X, KRNL, or any
--  executor:
--
--    loadstring(game:HttpGet("https://raw.githubusercontent.com/robloxscripter6245366542/roblox-lua-obscator/main/Elopez_Loader.lua"))()
--
--  This loader fetches and runs the latest "elopez" (Leviathan)
--  Blade Ball hub, so the link never changes even when the hub is
--  updated.
-- ============================================================

local URL = "https://raw.githubusercontent.com/robloxscripter6245366542/roblox-lua-obscator/main/elopez"

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
    warn("[Leviathan Hub] Could not fetch the hub (HTTP blocked). Paste the hub source directly instead.")
    return
end

local fn, err = loadstring(body)
if not fn then
    warn("[Leviathan Hub] Compile error: " .. tostring(err))
    return
end

local ran, rerr = pcall(fn)
if not ran then
    warn("[Leviathan Hub] Runtime error: " .. tostring(rerr))
end
