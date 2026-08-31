-- ============================================================
--  NEXUS V2  –  Loader (Prison Life)
--
--  Paste this ONE LINE into your executor (Delta / Xeno / Solara /
--  Codex / Wave / Fluxus / Synapse / KRNL, iOS / iPadOS / Android / PC):
--
--    loadstring(game:HttpGet("https://raw.githubusercontent.com/robloxscripter6245366542/roblox-lua-obscator/claude/remove-webhooks-tff7x9/NexusV2_Loader.lua"))()
--
--  This loader fetches and runs the latest NexusV2.lua, so the link
--  never changes even when the script is updated.
-- ============================================================

local URL = "https://raw.githubusercontent.com/robloxscripter6245366542/roblox-lua-obscator/claude/remove-webhooks-tff7x9/NexusV2.lua"

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
    warn("[Nexus V2] Could not fetch the script (HTTP blocked). Paste NexusV2.lua directly instead.")

    return
end

local fn, err = loadstring(body)

if not fn then
    warn("[Nexus V2] Compile error: " .. tostring(err))

    return
end

local ran, rerr = pcall(fn)

if not ran then
    warn("[Nexus V2] Runtime error: " .. tostring(rerr))
end
