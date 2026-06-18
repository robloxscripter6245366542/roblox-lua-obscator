-- ============================================================
--  WINDHUB v6.0  --  Delta AutoExec / Direct Install
--
--  HOW TO INSTALL IN DELTA (Direct Install):
--
--  1. Open Delta -> Settings -> Auto Execute -> Enable it
--  2. Tap the autoexec folder icon and create a new script
--  3. Name it "WindHub" and paste this entire file into it
--  4. Save and close. WindHub will load automatically on
--     every game join from now on.
--
--  OR use Delta's Direct Install URL:
--    https://roblox-lua-obscator-git-claude-rem-b354df-saguine-opus-projects.vercel.app/WindHub_AutoExec.lua
--
--  NO KEY SYSTEM. Loads WindHub automatically every game.
-- ============================================================

-- Wait for game to be ready (important for autoexec)
if not game:IsLoaded() then
    game.Loaded:Wait()
end
task.wait(1.5)

-- Fetch and run WindHub via the CDN loader
local CDN = "https://roblox-lua-obscator-git-claude-rem-b354df-saguine-opus-projects.vercel.app/WindHub_Loader.lua"

local body = nil
pcall(function() body = game:HttpGet(CDN, true) end)
if not body or #body < 100 then
    pcall(function()
        local req = rawget(_G,"request") or rawget(_G,"http_request")
            or (rawget(_G,"syn") and rawget(_G,"syn").request)
        if req then
            local r = req({ Url = CDN, Method = "GET" })
            if r and r.Body then body = r.Body end
        end
    end)
end

if not body or #body < 100 then
    warn("[WindHub AutoExec] Failed to fetch loader. Check HTTP is enabled in Delta settings.")
    return
end

local fn, err = loadstring(body)
if not fn then
    warn("[WindHub AutoExec] Loader compile error: " .. tostring(err))
    return
end

local ok2, runErr = pcall(fn)
if not ok2 then
    warn("[WindHub AutoExec] Loader runtime error: " .. tostring(runErr))
end
