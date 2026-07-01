-- Anime Ball – Clean Loader
-- Paste into any executor (Delta, Xeno, Solara, Codex, Wave, Fluxus, Synapse X, KRNL, etc.):
--
--   loadstring(game:HttpGet("https://raw.githubusercontent.com/robloxscripter6245366542/roblox-lua-obscator/claude/lunar-loadstring-309e3i/AnimeBall_Loader.lua"))()
--
-- Deobfuscated from the original AnimeBall custom-VM obfuscation (Layer 3 cracked).
-- Features: Auto Parry · Auto Spam · Visual spheres · Live stats (Fluent UI)

local URL = "https://raw.githubusercontent.com/robloxscripter6245366542/roblox-lua-obscator/claude/lunar-loadstring-309e3i/user_scripts/AnimeBall_Clean.lua"

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
    warn("[AnimeBall] Could not fetch script (HTTP blocked).")
    return
end

local fn, err = loadstring(body)
if not fn then
    warn("[AnimeBall] Compile error: " .. tostring(err))
    return
end

local ran, rerr = pcall(fn)
if not ran then
    warn("[AnimeBall] Runtime error: " .. tostring(rerr))
end
