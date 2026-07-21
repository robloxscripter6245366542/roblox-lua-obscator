-- ============================================================
--  RemoteSpy.lua  –  Passive remote logger + deliberate replay
--
--  PASSIVE: hooks FireServer / InvokeServer so that whenever the GAME
--  ITSELF calls a remote, it logs the remote path, the method, the
--  arguments, the calling script, and (for InvokeServer) the value the
--  server returned. You learn the exact protocol the server expects
--  without sending a single extra packet.
--
--  REPLAY: a deliberate, one-at-a-time helper to fire ONE remote with
--  arguments YOU choose and read the return. This is for studying your
--  OWN game — not a fuzzer. It does not spam random calls.
--
--  This CANNOT read server source code (that never leaves the server);
--  it shows you the server's interface and its responses, which is the
--  real, working way to understand server behaviour.
--
--  Console API (getgenv):
--    RemoteSpy_Dump()          -> print + copy the whole log to clipboard
--    RemoteSpy_Clear()         -> wipe the log
--    RemoteSpy_Replay(remote, ...) -> fire/invoke one remote you choose
--    RemoteSpy_Stop()          -> unhook and stop logging
--    RemoteSpy_Log             -> the raw log table
--  where `remote` is a full path string ("game.ReplicatedStorage.Events.X")
--  or the Instance itself.
-- ============================================================

local StarterGui = game:GetService("StarterGui")

-- ── Config ────────────────────────────────────────────────
local CONFIG = {
    LogFireServer   = true,   -- RemoteEvent / UnreliableRemoteEvent :FireServer
    LogInvokeServer = true,   -- RemoteFunction :InvokeServer (captures return)
    PrintEachCall   = true,   -- print every captured call to the console
    MaxArgPreview   = 220,    -- truncate each serialized arg to this many chars
    MaxDepth        = 3,      -- table serialization depth
    SaveToFile      = true,   -- also writefile the log on Dump()
}
-- ──────────────────────────────────────────────────────────

local getgenv_fn      = getgenv or function() return _G end
local ENV             = getgenv_fn()
local hookmetamethod_fn = rawget(ENV, "hookmetamethod") or hookmetamethod
local getnamecallmethod_fn = rawget(ENV, "getnamecallmethod") or getnamecallmethod
local checkcaller_fn  = rawget(ENV, "checkcaller") or checkcaller
local getcallingscript_fn = rawget(ENV, "getcallingscript") or getcallingscript
local setclipboard_fn = rawget(ENV, "setclipboard") or setclipboard
                        or rawget(ENV, "toclipboard") or toclipboard
local writefile_fn    = rawget(ENV, "writefile") or writefile

local function notify(text)
    print("[RemoteSpy] " .. text)
    pcall(function()
        StarterGui:SetCore("SendNotification", { Title = "RemoteSpy", Text = text, Duration = 5 })
    end)
end

local function fullPath(inst)
    if typeof(inst) ~= "Instance" then return tostring(inst) end
    local ok, p = pcall(function() return inst:GetFullName() end)
    return (ok and p) or inst.Name
end

-- ── Safe value serialization ──────────────────────────────
local function serialize(v, depth)
    depth = depth or 0
    local t = typeof(v)
    if t == "string" then
        local s = ("%q"):format(v)
        if #s > CONFIG.MaxArgPreview then s = s:sub(1, CONFIG.MaxArgPreview) .. '..."' end
        return s
    elseif t == "number" or t == "boolean" or t == "nil" then
        return tostring(v)
    elseif t == "Instance" then
        return ("<%s: %s>"):format(v.ClassName, fullPath(v))
    elseif t == "table" then
        if depth >= CONFIG.MaxDepth then return "{...}" end
        local parts, n = {}, 0
        for k, val in pairs(v) do
            n = n + 1
            if n > 20 then parts[#parts + 1] = "..."; break end
            parts[#parts + 1] = ("[%s]=%s"):format(
                type(k) == "string" and k or serialize(k, depth + 1),
                serialize(val, depth + 1))
        end
        return "{" .. table.concat(parts, ", ") .. "}"
    else
        return ("<%s: %s>"):format(t, tostring(v))
    end
end

local function serializeArgs(args, count)
    local parts = {}
    for i = 1, count do parts[i] = serialize(args[i]) end
    return table.concat(parts, ", ")
end

-- ── Log store ─────────────────────────────────────────────
local Log = {}
getgenv_fn().RemoteSpy_Log = Log

local function record(entry)
    Log[#Log + 1] = entry
    if CONFIG.PrintEachCall then
        print(("[RemoteSpy] %s  %s(%s)%s")
            :format(entry.method, entry.path, entry.args,
                    entry.ret and ("  ->  " .. entry.ret) or ""))
    end
end

-- ── The hook ──────────────────────────────────────────────
local FIRE  = { FireServer = true, fireServer = true }
local INVK  = { InvokeServer = true, invokeServer = true }

local active = true
local oldNamecall

local function install()
    if not (hookmetamethod_fn and getnamecallmethod_fn) then
        notify("Executor lacks hookmetamethod/getnamecallmethod - passive spy unavailable. "
            .. "Replay still works via RemoteSpy_Replay().")
        return false
    end
    local ok, err = pcall(function()
        oldNamecall = hookmetamethod_fn(game, "__namecall", function(self, ...)
            -- Never touch our own calls or when inactive.
            if not active or (checkcaller_fn and checkcaller_fn()) then
                return oldNamecall(self, ...)
            end
            local method = getnamecallmethod_fn()

            if CONFIG.LogFireServer and FIRE[method] and typeof(self) == "Instance" then
                local args = { ... }
                local count = select("#", ...)
                pcall(function()
                    record({
                        time = os.clock(), method = method, path = fullPath(self),
                        class = self.ClassName, args = serializeArgs(args, count),
                        src = getcallingscript_fn and fullPath(getcallingscript_fn()) or "?",
                    })
                end)
                return oldNamecall(self, ...)
            end

            if CONFIG.LogInvokeServer and INVK[method] and typeof(self) == "Instance" then
                local args = { ... }
                local count = select("#", ...)
                local results = { oldNamecall(self, ...) }  -- capture the return
                pcall(function()
                    local retParts = {}
                    for i = 1, select("#", table.unpack(results)) do
                        retParts[i] = serialize(results[i])
                    end
                    record({
                        time = os.clock(), method = method, path = fullPath(self),
                        class = self.ClassName, args = serializeArgs(args, count),
                        ret = table.concat(retParts, ", "),
                        src = getcallingscript_fn and fullPath(getcallingscript_fn()) or "?",
                    })
                end)
                return table.unpack(results)
            end

            return oldNamecall(self, ...)
        end)
    end)
    if not ok then
        notify("Failed to install hook: " .. tostring(err))
        return false
    end
    return true
end

-- ── Console API ───────────────────────────────────────────
getgenv_fn().RemoteSpy_Clear = function()
    for i = #Log, 1, -1 do Log[i] = nil end
    notify("Log cleared.")
end

getgenv_fn().RemoteSpy_Dump = function()
    local out = {}
    out[#out + 1] = "===== RemoteSpy log (" .. #Log .. " calls) ====="
    for i, e in ipairs(Log) do
        out[#out + 1] = ("[%d] %s  %s(%s)%s   {from %s}")
            :format(i, e.method, e.path, e.args,
                    e.ret and ("  ->  " .. e.ret) or "", e.src or "?")
    end
    local text = table.concat(out, "\n")
    print(text)
    if setclipboard_fn then
        pcall(setclipboard_fn, text)
        notify(("Copied %d calls to clipboard."):format(#Log))
    end
    if CONFIG.SaveToFile and writefile_fn then
        pcall(writefile_fn, ("RemoteSpy_%s.txt"):format(tostring(game.PlaceId)), text)
    end
    return text
end

getgenv_fn().RemoteSpy_Stop = function()
    active = false
    notify("Stopped logging (hook left in place, calls ignored).")
end

-- Deliberate, single-remote replay. `remote` = path string or Instance.
getgenv_fn().RemoteSpy_Replay = function(remote, ...)
    local inst = remote
    if type(remote) == "string" then
        -- Resolve a dotted path like game.ReplicatedStorage.Events.X
        local node = game
        for seg in remote:gmatch("[^%.]+") do
            if seg ~= "game" then
                local ok, child = pcall(function() return node:FindFirstChild(seg) end)
                node = ok and child or nil
                if not node then break end
            end
        end
        inst = node
    end
    if typeof(inst) ~= "Instance" then
        notify("Replay: could not resolve remote '" .. tostring(remote) .. "'")
        return
    end
    local cn = inst.ClassName
    local ok, res
    if cn == "RemoteFunction" then
        ok, res = pcall(function(...) return inst:InvokeServer(...) end, ...)
        notify(("Replay InvokeServer %s -> %s"):format(inst.Name, ok and serialize(res) or ("ERROR: " .. tostring(res))))
        return res
    elseif cn == "RemoteEvent" or cn == "UnreliableRemoteEvent" then
        ok, res = pcall(function(...) inst:FireServer(...) end, ...)
        notify(("Replay FireServer %s (%s)"):format(inst.Name, ok and "sent" or ("ERROR: " .. tostring(res))))
    else
        notify("Replay: " .. cn .. " is not a server remote (FireServer/InvokeServer only).")
    end
end

-- ── Go ────────────────────────────────────────────────────
local installed = install()
notify(installed
    and "Logging remotes. RemoteSpy_Dump() to copy, RemoteSpy_Replay(path,...) to test one."
    or  "Replay-only mode. Use RemoteSpy_Replay(path, ...).")
