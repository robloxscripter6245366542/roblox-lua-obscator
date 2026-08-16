-- ============================================================================
--  🐉  LEVIATHAN — Universal Loader
--
--  One line for every game. It verifies the PlaceId / GameId (with a
--  game-structure fallback for place variants) and runs the matching hub:
--    • Blade Ball    ->  elopez (Leviathan)
--    • Anime Ball    ->  anime_ball_autoparry (Leviathan UI)
--    • Phantom Ball  ->  phantom_ballz (Leviathan UI)
--
--    loadstring(game:HttpGet("https://raw.githubusercontent.com/robloxscripter6245366542/roblox-lua-obscator/main/Leviathan_Universal_Loader.lua"))()
-- ============================================================================

local BASE = "https://raw.githubusercontent.com/robloxscripter6245366542/roblox-lua-obscator/main/"

local TARGETS = {
    BladeBall = {
        label = "Blade Ball",
        url = BASE .. "elopez",
        -- Known PlaceId(s).
        places = { [13772394625] = true },
        -- Fallback signature: Blade Ball's networking + runtime layout.
        detect = function()
            local rs = game:GetService("ReplicatedStorage")
            return workspace:FindFirstChild("Runtime") ~= nil
                and rs:FindFirstChild("Packages") ~= nil
                and workspace:FindFirstChild("Balls") ~= nil
        end,
    },
    AnimeBall = {
        label = "Anime Ball",
        url = BASE .. "user_scripts/anime_ball_autoparry.lua",
        places = { [14861721759] = true },
        -- Fallback signature: Anime Ball's Framework.RemoteFunction ("SwordService").
        detect = function()
            local rs = game:GetService("ReplicatedStorage")
            local fw = rs:FindFirstChild("Framework")
            return fw ~= nil and fw:FindFirstChild("RemoteFunction") ~= nil
        end,
    },
    PhantomBall = {
        label = "Phantom Ball",
        url = BASE .. "user_scripts/phantom_ballz.lua",
        -- Phantom identifies by GameId (universe), not PlaceId — it works across
        -- every place in that universe.
        games = { [4538598064] = true },
        -- Fallback signature: ReplicatedStorage.TS + Remotes.BallSyncData.
        detect = function()
            local rs = game:GetService("ReplicatedStorage")
            local ts = rs:FindFirstChild("TS")
            local remotes = rs:FindFirstChild("Remotes")
            return ts ~= nil and remotes ~= nil
                and remotes:FindFirstChild("BallSyncData") ~= nil
        end,
    },
}

-- Order matters only for the structure fallback (checked in this order).
local ORDER = { "PhantomBall", "AnimeBall", "BladeBall" }

local function pick()
    local placeId = game.PlaceId
    local gameId = game.GameId
    -- 1) Exact PlaceId / GameId match.
    for _, name in ipairs(ORDER) do
        local t = TARGETS[name]
        if (t.places and t.places[placeId]) or (t.games and t.games[gameId]) then
            return t
        end
    end
    -- 2) Structure fallback (place variants / private servers with other IDs).
    for _, name in ipairs(ORDER) do
        local ok, matched = pcall(TARGETS[name].detect)
        if ok and matched then
            return TARGETS[name]
        end
    end
    return nil
end

local target = pick()
if not target then
    return warn(("[Leviathan] Unsupported game (PlaceId %s / GameId %s) — no matching hub."):format(tostring(game.PlaceId), tostring(game.GameId)))
end

-- Robust fetch: HttpGet, then any executor request fn as a fallback.
local ok, body = pcall(function() return game:HttpGet(target.url, true) end)
if not ok or type(body) ~= "string" or #body == 0 then
    local req = (syn and syn.request) or (http and http.request) or http_request or request
        or (fluxus and fluxus.request)
    if req then
        local r = req({ Url = target.url, Method = "GET" })
        if r and r.Body then body = r.Body end
    end
end
if type(body) ~= "string" or #body == 0 then
    return warn(("[Leviathan] Could not fetch the %s hub (HTTP blocked)."):format(target.label))
end

local fn, err = loadstring(body)
if not fn then
    return warn(("[Leviathan] %s hub compile error: %s"):format(target.label, tostring(err)))
end

local ran, rerr = pcall(fn)
if not ran then
    warn(("[Leviathan] %s hub runtime error: %s"):format(target.label, tostring(rerr)))
end
