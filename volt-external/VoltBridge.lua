-- VoltBridge.lua — streams captured remote calls out to the external C++ UI.
--
-- The external Volt.exe can't see inside the Roblox process, so the in-game
-- Lua side (Volt.lua) keeps doing the __namecall hooking and hands every
-- captured call to this module. We serialize each one as a single JSON line
-- and append it to a file in the executor workspace. Volt.exe tails that file
-- (point it there with the VOLT_STREAM env var or argv[1]) and renders it.
--
-- Transport choice: append-only .jsonl. Every executor supports writefile/
-- appendfile to its workspace, so this works without sockets or pipes.
--
-- Usage from Volt.lua:
--   local Bridge = loadstring(readfile("VoltBridge.lua"))()   -- or inline
--   Bridge.emit("OUT", remote, argsTable, "FireServer", false)

local Bridge = {}

-- ── config ──────────────────────────────────────────────────────────────
local FOLDER   = "VoltStream"
local PATH     = FOLDER .. "/stream.jsonl"
local MAX_BYTES = 2 * 1024 * 1024     -- rotate the log past ~2 MB

-- executor capability probes
local hasAppend = type(appendfile) == "function"
local hasWrite  = type(writefile)  == "function"
local hasFolder = type(makefolder) == "function"
local hasIsFolder = type(isfolder) == "function"
local hasIsFile = type(isfile)    == "function"

Bridge.enabled = (hasAppend or hasWrite)

if hasFolder then
    pcall(function()
        if not (hasIsFolder and isfolder(FOLDER)) then makefolder(FOLDER) end
    end)
end

-- start a fresh stream each session so the C++ side re-reads from zero
pcall(function() if hasWrite then writefile(PATH, "") end end)

-- ── JSON string escaping ────────────────────────────────────────────────
local function esc(s)
    s = tostring(s)
    s = s:gsub('\\', '\\\\'):gsub('"', '\\"')
    s = s:gsub('\n', '\\n'):gsub('\r', '\\r'):gsub('\t', '\\t')
    -- strip other control chars the minimal C++ parser won't expect
    s = s:gsub('[%z\1-\8\11\12\14-\31]', ' ')
    return s
end

-- compact pretty-printer for a packed argument table (table.pack form)
local function summarizeArgs(args)
    if type(args) ~= "table" then return "(no args)" end
    local n = args.n or #args
    if n == 0 then return "(no args)" end
    local parts = {}
    for i = 1, math.min(n, 6) do
        local v = args[i]
        local t = typeof and typeof(v) or type(v)
        local rep
        if t == "string" then
            rep = '"' .. (v:len() > 40 and (v:sub(1, 37) .. "...") or v) .. '"'
        elseif t == "Instance" then
            rep = v.ClassName .. "(" .. v.Name .. ")"
        elseif t == "Vector3" then
            rep = string.format("Vector3(%.1f, %.1f, %.1f)", v.X, v.Y, v.Z)
        elseif t == "table" then
            rep = "{...}"
        elseif v == nil then
            rep = "nil"
        else
            rep = tostring(v)
        end
        parts[#parts + 1] = rep
    end
    if n > 6 then parts[#parts + 1] = string.format("…(+%d)", n - 6) end
    return table.concat(parts, ", ")
end

-- ── append one record ───────────────────────────────────────────────────
local writeAccum = 0

local function appendLine(line)
    if hasAppend then
        pcall(appendfile, PATH, line)
    elseif hasWrite then
        -- no appendfile: read-modify-write (slower, but a universal fallback)
        local prev = ""
        if hasIsFile and isfile(PATH) then pcall(function() prev = readfile(PATH) end) end
        pcall(writefile, PATH, prev .. line)
    end
    writeAccum = writeAccum + #line
    if writeAccum > MAX_BYTES then
        pcall(function() if hasWrite then writefile(PATH, "") end end)
        writeAccum = 0
    end
end

-- dir: "OUT" | "IN"
-- remote: the Instance (for name/class) — may be nil
-- args: packed table (table.pack) or array
-- method: "FireServer" / "InvokeServer" / "OnClientEvent" / ...
-- isExec: bool — call originated from the executor
function Bridge.emit(dir, remote, args, method, isExec, source)
    if not Bridge.enabled then return end

    local name, rtype = "Unknown", "RemoteEvent"
    if remote then
        pcall(function() name = remote:GetFullName() end)
        pcall(function() rtype = remote.ClassName end)
    end

    local rec = string.format(
        '{"dir":"%s","name":"%s","method":"%s","rtype":"%s","args":"%s",' ..
        '"source":"%s","count":1,"exec":%s,"t":%.3f}\n',
        dir == "IN" and "in" or "out",
        esc(name),
        esc(method or "?"),
        esc(rtype),
        esc(summarizeArgs(args)),
        esc(source or ""),
        isExec and "true" or "false",
        (os.clock and os.clock()) or 0
    )
    appendLine(rec)
end

return Bridge
