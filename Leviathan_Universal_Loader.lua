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
--
--  Executor-agnostic: it detects the running executor and picks the matching
--  implementation of each function that differs between them (HTTP request,
--  HttpGet, loadstring), so one line works on Synapse, Script-Ware, Fluxus,
--  KRNL, Delta, Codex, Wave, Solara, AWP, Xeno, Swift, and the rest.
-- ============================================================================

local BASE = "https://raw.githubusercontent.com/robloxscripter6245366542/roblox-lua-obscator/main/"

-- ── Executor compatibility layer ───────────────────────────────────────────
-- Every executor exposes the same capabilities under different names. Resolve
-- each one to whatever this executor actually provides, so the loader (and the
-- hub it runs) always call the right function. Nothing here errors if a given
-- function is missing — each resolver just falls through to the next candidate.
local genv = (getgenv and getgenv()) or _G or {}

-- Name/version, best effort: the UNC identifyexecutor first, then older
-- getexecutorname, then feature-detection by which globals exist.
local function detectExecutor()
    local ok, name, ver = pcall(function()
        if identifyexecutor then return identifyexecutor() end
        if getexecutorname then return getexecutorname() end
        return nil
    end)
    if ok and type(name) == "string" and #name > 0 then
        return ver and (name .. " " .. tostring(ver)) or name
    end
    if syn then return "Synapse" end
    if fluxus then return "Fluxus" end
    if KRNL_LOADED then return "KRNL" end
    if is_sirhurt_closure then return "SirHurt" end
    if secure_load then return "Sentinel" end
    if pebc_execute then return "ProtoSmasher" end
    if Delta or getgenv().Delta then return "Delta" end
    return "Unknown"
end
local EXECUTOR = detectExecutor()

-- Universal HTTP request → returns the executor's response table (has .Body /
-- .StatusCode), or nil. Covers every common request entry point.
local function httpRequest(opts)
    local req = (syn and syn.request)
        or (http and http.request)
        or http_request
        or request
        or (fluxus and fluxus.request)
        or (getgenv and getgenv().request)
        or (Krnl and Krnl.request)
    if not req then return nil end
    local ok, res = pcall(req, opts)
    if ok then return res end
    return nil
end

-- Universal HttpGet: try game:HttpGet both call shapes, then fall back to the
-- request function above. Returns the body string or nil.
local function httpGet(url)
    local ok, body = pcall(function() return game:HttpGet(url, true) end)
    if ok and type(body) == "string" and #body > 0 then return body end
    ok, body = pcall(function() return game:HttpGet(url) end)
    if ok and type(body) == "string" and #body > 0 then return body end
    ok, body = pcall(function() return game:HttpGetAsync(url) end)
    if ok and type(body) == "string" and #body > 0 then return body end
    local res = httpRequest({ Url = url, Method = "GET" })
    if res and type(res.Body) == "string" and #res.Body > 0 then return res.Body end
    return nil
end

-- Universal loadstring (a few executors only expose it via the global env).
local loadstringFn = loadstring or (genv and genv.loadstring) or (getgenv and getgenv().loadstring)

-- Publish the resolved helpers so the hub can reuse the exact same ones instead
-- of re-detecting — "the right function for this executor", shared downstream.
genv.LeviathanExecutor = EXECUTOR
genv.LeviathanHttpGet = httpGet
genv.LeviathanRequest = httpRequest

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

-- Fetch through the executor-agnostic HttpGet (game:HttpGet → request fn).
local body = httpGet(target.url)
if type(body) ~= "string" or #body == 0 then
    return warn(("[Leviathan] Could not fetch the %s hub on %s (HTTP blocked)."):format(target.label, tostring(EXECUTOR)))
end

if type(loadstringFn) ~= "function" then
    return warn(("[Leviathan] %s has no usable loadstring — cannot run the %s hub."):format(tostring(EXECUTOR), target.label))
end

local fn, err = loadstringFn(body)
if not fn then
    return warn(("[Leviathan] %s hub compile error: %s"):format(target.label, tostring(err)))
end

local ran, rerr = pcall(fn)
if not ran then
    warn(("[Leviathan] %s hub runtime error: %s"):format(target.label, tostring(rerr)))
end
