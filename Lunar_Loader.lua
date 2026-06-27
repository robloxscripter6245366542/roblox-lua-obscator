-- Paste into any executor:
--   loadstring(game:HttpGet("https://raw.githubusercontent.com/robloxscripter6245366542/roblox-lua-obscator/claude/lunar-loadstring-309e3i/Lunar_Loader.lua"))()

local URL = "https://api.jnkie.com/api/v1/luascripts/public/52276846a0d8e73f3208d9206b7be7c8ea031f62e5707d45d0ec9abfdca35467/download"

local ok, body = pcall(function() return game:HttpGet(URL, true) end)
if not ok or not body then
    local req = (syn and syn.request) or (http and http.request) or http_request or request
        or (fluxus and fluxus.request)
    if req then
        local r = req({ Url = URL, Method = "GET" })
        if r and r.Body then body = r.Body end
    end
end

if not body then
    warn("[Lunar] Could not fetch script (HTTP blocked).")
    return
end

local fn, err = loadstring(body)
if not fn then
    warn("[Lunar] Compile error: " .. tostring(err))
    return
end

local ran, rerr = pcall(fn)
if not ran then
    warn("[Lunar] Runtime error: " .. tostring(rerr))
end
