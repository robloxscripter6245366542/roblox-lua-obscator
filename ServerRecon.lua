-- ============================================================
--  ServerRecon.lua  –  Maximum client-observable server picture
--
--  This is the "as much as physically possible" server-intelligence
--  collector. It combines every honest technique into one report:
--
--    1. REMOTE MAP     – every remote in the game + a call snippet.
--    2. SHARED CODE     – source of every ModuleScript/LocalScript the
--                         client can reach (the code the server SHARES).
--    3. HANDLER MAP     – for each remote, which client scripts are
--                         connected to it (via getconnections + getinfo),
--                         i.e. how the client reacts to the server.
--    4. LIVE TRAFFIC    – BOTH directions:
--                           outgoing FireServer/InvokeServer (+ returns)
--                           incoming OnClientEvent (what the server pushes)
--
--  ── The hard limit (read this) ───────────────────────────
--  True server Scripts live in ServerScriptService / ServerStorage and
--  are NEVER sent to the client. No tool, language, memory reader or
--  transpiler can recover them from here, because the bytes are not on
--  this machine. This captures the server's INTERFACE and BEHAVIOUR to
--  the fullest extent the client can see — not its source. Any server
--  Script this lists will show class + path but "unavailable" source.
--
--  Use it to study / back up your OWN games.
--
--  Console API (getgenv):
--    ServerRecon_Dump()   -> rebuild report from live traffic + copy/save
--    ServerRecon_Log      -> raw live-traffic log
--    ServerRecon_Stop()   -> stop live capture
-- ============================================================

local StarterGui = game:GetService("StarterGui")

-- ── Config ────────────────────────────────────────────────
local CONFIG = {
    OutputFolder   = "ServerRecon",
    IncludeBindables = true,
    DumpSharedCode = true,    -- decompile all client-reachable scripts
    MapHandlers    = true,    -- map remotes -> connected client functions
    LiveTraffic    = true,    -- hook outgoing + listen incoming
    MaxDecompiles  = 4000,
    MaxArgPreview  = 220,
    MaxDepth       = 3,
    YieldEvery     = 25,
    IgnoreRoots    = { "CoreGui", "CorePackages", "RobloxGui", "RobloxReplicatedStorage", "CoreScripts" },
}
-- ──────────────────────────────────────────────────────────

local getgenv_fn      = getgenv or function() return _G end
local ENV             = getgenv_fn()
local getnil_fn       = rawget(ENV, "getnilinstances")   or getnilinstances
local decompile_fn    = rawget(ENV, "decompile")         or decompile
local getsource_fn    = rawget(ENV, "getscriptsource")   or getscriptsource
local getbytecode_fn  = rawget(ENV, "getscriptbytecode") or getscriptbytecode
local setclipboard_fn = rawget(ENV, "setclipboard")      or setclipboard or toclipboard
local writefile_fn    = rawget(ENV, "writefile")         or writefile
local makefolder_fn   = rawget(ENV, "makefolder")        or makefolder
local isfolder_fn     = rawget(ENV, "isfolder")          or isfolder
local getconnections_fn = rawget(ENV, "getconnections")  or getconnections
local hookmetamethod_fn = rawget(ENV, "hookmetamethod")  or hookmetamethod
local getnamecallmethod_fn = rawget(ENV, "getnamecallmethod") or getnamecallmethod
local checkcaller_fn  = rawget(ENV, "checkcaller")       or checkcaller
local getinfo_fn      = (debug and (debug.getinfo or debug.info))
                        or rawget(ENV, "getinfo")

local REMOTE_CLASSES = {
    RemoteEvent = { call = "FireServer", server = true, signal = "OnClientEvent" },
    UnreliableRemoteEvent = { call = "FireServer", server = true, signal = "OnClientEvent" },
    RemoteFunction = { call = "InvokeServer", server = true, signal = nil },
    BindableEvent = { call = "Fire", server = false, signal = "Event" },
    BindableFunction = { call = "Invoke", server = false, signal = nil },
}

local function notify(text)
    print("[ServerRecon] " .. text)
    pcall(function()
        StarterGui:SetCore("SendNotification", { Title = "ServerRecon", Text = text, Duration = 5 })
    end)
end

local function fullPath(inst)
    if typeof(inst) ~= "Instance" then return tostring(inst) end
    local ok, p = pcall(function() return inst:GetFullName() end)
    return (ok and p) or inst.Name
end
local function lower(s) return (tostring(s):lower()) end
local function isIgnored(path)
    local p = lower(path)
    for _, r in ipairs(CONFIG.IgnoreRoots) do
        r = lower(r)
        if p == r or p:sub(1, #r + 1) == r .. "." then return true end
    end
    return false
end
local function toHex(s) return (s:gsub(".", function(c) return string.format("%02x", string.byte(c)) end)) end

local function pathExpr(inst)
    local parts, cur = {}, inst
    while cur and cur ~= game do
        local name = cur.Name
        parts[#parts + 1] = name
        local okp, p = pcall(function() return cur.Parent end)
        if not okp then break end
        cur = p
    end
    if #parts == 0 then return "nil" end
    local out = ('game:GetService("%s")'):format(parts[#parts])
    for i = #parts - 1, 1, -1 do
        local n = parts[i]
        out = out .. (n:match("^[%a_][%w_]*$") and ("." .. n) or ('["%s"]'):format(n))
    end
    return out
end

-- ── Value serialization for traffic logs ──────────────────
local function serialize(v, depth)
    depth = depth or 0
    local t = typeof(v)
    if t == "string" then
        local s = ("%q"):format(v)
        if #s > CONFIG.MaxArgPreview then s = s:sub(1, CONFIG.MaxArgPreview) .. '..."' end
        return s
    elseif t == "number" or t == "boolean" or t == "nil" then return tostring(v)
    elseif t == "Instance" then return ("<%s: %s>"):format(v.ClassName, fullPath(v))
    elseif t == "table" then
        if depth >= CONFIG.MaxDepth then return "{...}" end
        local parts, n = {}, 0
        for k, val in pairs(v) do
            n = n + 1
            if n > 20 then parts[#parts + 1] = "..."; break end
            parts[#parts + 1] = ("[%s]=%s"):format(
                type(k) == "string" and k or serialize(k, depth + 1), serialize(val, depth + 1))
        end
        return "{" .. table.concat(parts, ", ") .. "}"
    else return ("<%s: %s>"):format(t, tostring(v)) end
end
local function serializeArgs(args, count)
    local p = {}
    for i = 1, count do p[i] = serialize(args[i]) end
    return table.concat(p, ", ")
end

-- ── Script source (decompile with fallbacks) ──────────────
local function getScriptCode(scr)
    if decompile_fn then
        local ok, src = pcall(decompile_fn, scr)
        if ok and type(src) == "string" and #src > 0 then return src, "decompile" end
    end
    if getsource_fn then
        local ok, src = pcall(getsource_fn, scr)
        if ok and type(src) == "string" and #src > 0 then return src, "source" end
    end
    local ok, src = pcall(function() return scr.Source end)
    if ok and type(src) == "string" and #src > 0 then return src, "Source" end
    if getbytecode_fn then
        local okb, bc = pcall(getbytecode_fn, scr)
        if okb and type(bc) == "string" and #bc > 0 then return toHex(bc), "bytecode" end
    end
    return nil, "unavailable"
end

-- ── Collect remotes + scripts ─────────────────────────────
local function collect()
    local seen, remotes, scripts = {}, {}, {}
    local n = 0
    local function consider(inst)
        if not inst or seen[inst] then return end
        seen[inst] = true
        n = n + 1
        if n % 2000 == 0 then task.wait() end
        local ok, cn = pcall(function() return inst.ClassName end)
        if not ok then return end
        if REMOTE_CLASSES[cn] and (CONFIG.IncludeBindables or REMOTE_CLASSES[cn].server) then
            remotes[#remotes + 1] = { obj = inst, cn = cn, info = REMOTE_CLASSES[cn] }
        end
        local oks, isSrc = pcall(function() return inst:IsA("LuaSourceContainer") end)
        if oks and isSrc then scripts[#scripts + 1] = inst end
    end
    local ok, desc = pcall(function() return game:GetDescendants() end)
    if ok then for _, o in ipairs(desc) do consider(o) end end
    if getnil_fn then
        local okn, nils = pcall(getnil_fn)
        if okn and type(nils) == "table" then
            for _, o in ipairs(nils) do consider(o)
                pcall(function() for _, d in ipairs(o:GetDescendants()) do consider(d) end end)
            end
        end
    end
    return remotes, scripts
end

-- ── Handler mapping: remote -> connected client functions ──
local function mapHandlers(remote)
    if not (CONFIG.MapHandlers and getconnections_fn and remote.info.signal) then return {} end
    local out = {}
    pcall(function()
        local sig = remote.obj[remote.info.signal]
        for _, conn in ipairs(getconnections_fn(sig)) do
            local fn = conn.Function
            if fn and getinfo_fn then
                local ok, info = pcall(getinfo_fn, fn)
                if ok and type(info) == "table" then
                    out[#out + 1] = ("%s:%s"):format(
                        tostring(info.short_src or info.source or "?"),
                        tostring(info.linedefined or info.currentline or "?"))
                end
            end
        end
    end)
    return out
end

-- ── Live traffic capture ──────────────────────────────────
local Log = {}
getgenv_fn().ServerRecon_Log = Log
local active = true
local function logCall(dir, method, inst, args, count, ret)
    Log[#Log + 1] = {
        dir = dir, method = method, path = fullPath(inst),
        args = serializeArgs(args, count), ret = ret,
    }
    print(("[ServerRecon] %s %s %s(%s)%s"):format(
        dir, method, fullPath(inst), serializeArgs(args, count),
        ret and ("  ->  " .. ret) or ""))
end

local oldNamecall
local function installOutgoing()
    if not (hookmetamethod_fn and getnamecallmethod_fn) then return false end
    local ok = pcall(function()
        oldNamecall = hookmetamethod_fn(game, "__namecall", function(self, ...)
            if not active or (checkcaller_fn and checkcaller_fn()) then return oldNamecall(self, ...) end
            local m = getnamecallmethod_fn()
            if (m == "FireServer" or m == "fireServer") and typeof(self) == "Instance" then
                local a, c = { ... }, select("#", ...)
                pcall(logCall, "OUT", m, self, a, c, nil)
                return oldNamecall(self, ...)
            elseif (m == "InvokeServer" or m == "invokeServer") and typeof(self) == "Instance" then
                local a, c = { ... }, select("#", ...)
                local res = { oldNamecall(self, ...) }
                pcall(function()
                    local rp = {}
                    for i = 1, select("#", table.unpack(res)) do rp[i] = serialize(res[i]) end
                    logCall("OUT", m, self, a, c, table.concat(rp, ", "))
                end)
                return table.unpack(res)
            end
            return oldNamecall(self, ...)
        end)
    end)
    return ok
end

local function installIncoming(remotes)
    -- Listen alongside the game on every server->client event.
    for _, r in ipairs(remotes) do
        if r.info.server and r.info.signal == "OnClientEvent" then
            pcall(function()
                r.obj.OnClientEvent:Connect(function(...)
                    if active then
                        local a, c = { ... }, select("#", ...)
                        pcall(logCall, "IN ", "OnClientEvent", r.obj, a, c, nil)
                    end
                end)
            end)
        end
    end
end

-- ── Build the static report ───────────────────────────────
local function buildReport(remotes, scripts)
    local kR, kS, skipped = {}, {}, 0
    for _, r in ipairs(remotes) do
        local p = fullPath(r.obj)
        if isIgnored(p) then skipped = skipped + 1 else r.path = p; kR[#kR + 1] = r end
    end
    for _, s in ipairs(scripts) do
        local p = fullPath(s)
        if not isIgnored(p) then kS[#kS + 1] = { obj = s, path = p } end
    end
    table.sort(kR, function(a, b) return a.path < b.path end)
    table.sort(kS, function(a, b) return a.path < b.path end)

    local out = {}
    out[#out + 1] = "============================================================"
    out[#out + 1] = "  ServerRecon  –  maximum client-observable server picture"
    out[#out + 1] = ("  %s (PlaceId %s)"):format(game.Name ~= "" and game.Name or "Game", tostring(game.PlaceId))
    out[#out + 1] = ("  Remotes: %d  |  Scripts: %d"):format(#kR, #kS)
    out[#out + 1] = "  Generated: " .. os.date("!%Y-%m-%d %H:%M:%S UTC")
    out[#out + 1] = "  NOTE: server Script SOURCE cannot be dumped from a client."
    out[#out + 1] = "============================================================\n"

    out[#out + 1] = ("##### REMOTE MAP + HANDLERS (%d) #####"):format(#kR)
    for i, r in ipairs(kR) do
        out[#out + 1] = ("[%d] (%s)  %s"):format(i, r.cn, r.path)
        out[#out + 1] = ("    call: %s:%s()"):format(pathExpr(r.obj), r.info.call)
        local h = mapHandlers(r)
        if #h > 0 then out[#out + 1] = "    client handlers: " .. table.concat(h, " , ") end
    end
    out[#out + 1] = ""

    if CONFIG.DumpSharedCode then
        out[#out + 1] = ("##### SHARED CODE (%d scripts) #####\n"):format(#kS)
        local done, ops = 0, 0
        for i, s in ipairs(kS) do
            local cn = "Script"; pcall(function() cn = s.obj.ClassName end)
            local code, method
            if done < CONFIG.MaxDecompiles then
                code, method = getScriptCode(s.obj); done = done + 1
                ops = ops + 1; if ops % CONFIG.YieldEvery == 0 then task.wait() end
            else method = "skipped (cap)" end
            out[#out + 1] = "------------------------------------------------------------"
            out[#out + 1] = ("[%d] %s  (%s)  [via %s]"):format(i, s.path, cn, tostring(method))
            out[#out + 1] = "------------------------------------------------------------"
            out[#out + 1] = code or ("-- unavailable (protected/server-side) [" .. tostring(method) .. "]")
            out[#out + 1] = ""
        end
    end
    return table.concat(out, "\n"), #kR, #kS
end

-- ── Dump (report + live traffic) ──────────────────────────
local baseReport = ""
getgenv_fn().ServerRecon_Dump = function()
    local traffic = { "\n##### LIVE TRAFFIC (" .. #Log .. " calls) #####" }
    for i, e in ipairs(Log) do
        traffic[#traffic + 1] = ("[%d] %s %s  %s(%s)%s")
            :format(i, e.dir, e.method, e.path, e.args, e.ret and ("  ->  " .. e.ret) or "")
    end
    local text = baseReport .. "\n" .. table.concat(traffic, "\n")
    if setclipboard_fn then pcall(setclipboard_fn, (text:gsub("%z", "?"))) end
    if writefile_fn then pcall(writefile_fn, ("%s_%s.txt"):format(CONFIG.OutputFolder, tostring(game.PlaceId)), text) end
    notify(("Dumped: %d remotes/code + %d live calls -> clipboard & file."):format(1, #Log))
    return text
end
getgenv_fn().ServerRecon_Stop = function() active = false; notify("Live capture stopped.") end

-- ── Go ────────────────────────────────────────────────────
local function run()
    notify("Scanning game for remotes, code & handlers...")
    local remotes, scripts = collect()

    baseReport = select(1, buildReport(remotes, scripts))

    if CONFIG.LiveTraffic then
        local hooked = installOutgoing()
        installIncoming(remotes)
        notify(hooked
            and "Live capture ON (in+out). Play, then run ServerRecon_Dump()."
            or  "Outgoing hook unavailable; incoming capture ON. Run ServerRecon_Dump().")
    end

    -- Immediate first dump so you get the static picture right away.
    getgenv_fn().ServerRecon_Dump()
    print(baseReport)
    notify("Initial report copied. Keep playing; ServerRecon_Dump() again for updated traffic.")
end

local ok, err = pcall(run)
if not ok then warn("[ServerRecon] Error: " .. tostring(err)); notify("Error: " .. tostring(err)) end
