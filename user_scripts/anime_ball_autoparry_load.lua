-- Anime Ball autoparry — robust loader.
-- Use this instead of a bare loadstring(game:HttpGet(url))(): it retries the
-- download on transient network hiccups, reports a clear on-screen message if
-- it can never fetch / compile / run the script, and never silently no-ops.
--
--   loadstring(game:HttpGet("https://raw.githubusercontent.com/robloxscripter6245366542/roblox-lua-obscator/main/user_scripts/anime_ball_autoparry_load.lua"))()

local URL = "https://raw.githubusercontent.com/robloxscripter6245366542/roblox-lua-obscator/main/user_scripts/anime_ball_autoparry.lua"
local MAX_TRIES = 4

-- Toast to the Roblox notification system (falls back to warn) so a failure is
-- visible in-game, not just buried in the console.
local function notify(title, content)
    pcall(function()
        game:GetService("StarterGui"):SetCore("SendNotification", {
            Title = "[AnimeBall] " .. title,
            Text = content,
            Duration = 6,
        })
    end)
    warn("[AnimeBall] " .. title .. ": " .. content)
end

-- Download with retries + exponential backoff (1s, 2s, 4s). HttpGet can throw
-- (blocked, rate-limited, offline) or return an empty/garbage body, so both are
-- treated as a failed attempt.
local source
for attempt = 1, MAX_TRIES do
    local ok, res = pcall(function() return game:HttpGet(URL) end)
    if ok and type(res) == "string" and #res > 32 then
        source = res
        break
    end
    if attempt < MAX_TRIES then
        notify("Download failed", string.format("attempt %d/%d — retrying...", attempt, MAX_TRIES))
        task.wait(2 ^ (attempt - 1))
    end
end

if not source then
    return notify("Load aborted",
        "couldn't download the script after " .. MAX_TRIES .. " tries. Check your internet or that your executor allows HTTP requests.")
end

-- Compile and run as two separate guarded steps so the failure message tells you
-- WHICH stage broke (a bad download vs. a script error).
local chunk, compileErr = loadstring(source)
if not chunk then
    return notify("Compile error", tostring(compileErr))
end

local ok, runErr = pcall(chunk)
if not ok then
    return notify("Runtime error", tostring(runErr))
end
