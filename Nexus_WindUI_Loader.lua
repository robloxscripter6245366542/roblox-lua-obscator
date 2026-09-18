-- ============================================================
--  NEXUS • Granite (WindUI Edition)  –  Loader
--
--  Paste this ONE LINE into your executor (Delta / Xeno / Solara /
--  Codex / Wave / Fluxus / Synapse / KRNL, iOS / iPadOS / Android / PC):
--
--    loadstring(game:HttpGet("https://raw.githubusercontent.com/robloxscripter6245366542/roblox-lua-obscator/main/Nexus_WindUI_Loader.lua"))()
--
--  Nexus now runs on the WindUI library with an animated "Granite" dark
--  theme and auto-detects the game you're in:
--    * Prison Life        -> team changer, kill aura, teleport remotes
--    * Murder Mystery 2    -> auto shoot aura, silent aim, knife farm
--    * any other game      -> universal player / visual / server tools
--
--  This loader fetches and runs the latest Nexus_WindUI.lua, so the link
--  never changes even when the script is updated.
-- ============================================================

local URL = "https://raw.githubusercontent.com/robloxscripter6245366542/roblox-lua-obscator/main/Nexus_WindUI.lua"

local ok, body = pcall(function()
    return game:HttpGet(URL, true)
end)

if not ok or not body then
    -- fallback to any executor-specific HTTP request fn
    local req = (syn and syn.request) or (http and http.request) or http_request or request
        or (fluxus and fluxus.request)

    if req then
        local r = req({ Url = URL, Method = "GET" })

        if r and r.Body then
            body = r.Body
        end
    end
end

if not body then
    warn("[Nexus • Granite] Could not fetch the script (HTTP blocked). Paste Nexus_WindUI.lua directly instead.")

    return
end

local fn, err = loadstring(body)

if not fn then
    warn("[Nexus • Granite] Compile error: " .. tostring(err))

    return
end

local ran, rerr = pcall(fn)

if not ran then
    warn("[Nexus • Granite] Runtime error: " .. tostring(rerr))
end
