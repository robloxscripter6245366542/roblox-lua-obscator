-- ============================================================
--  env_logger.lua  --  executor-side "env logger" / deep dumper
--
--  Runs INSIDE a real Roblox executor, alongside (or wrapping) a
--  Luraph-protected target, and extracts what an offline sandbox
--  CANNOT: the *complete* constant pool, read statically out of the
--  compiled closures via the executor `debug` library -- including
--  constants in code paths that never execute. This is the piece that
--  resolves the cold `K(i)` residue lift.py leaves behind.
--
--  It complements the offline tools (peel.py / sandbox.lua / devirt):
--    * offline: unpack + structure + the constants that *ran*
--    * here:    every constant + every proto + live network/namecall
--
--  HOW IT BEATS THE VM (no VM understanding required):
--    W2  you own the environment  -> hook loadstring/load, getfenv
--    W3  runtime string decrypt   -> capture every compiled stage
--    W4  lazy constant pool       -> debug.getconstants over EVERY proto
--    W6  external effects          -> hookfunction on HttpGet/request +
--                                     __namecall spy on RemoteEvent/Function
--  The constant dump uses debug.getconstants / debug.getprotos /
--  debug.getupvalues (recursively) + a getgc() sweep, so it reads
--  constants directly from bytecode closures -- static, no execution,
--  no key, reaches dead code.
--
--  SAFETY: CONFIG.BlockNetwork defaults TRUE -- HttpGet/request are
--  logged but NOT forwarded, so a hostile target cannot phone home or
--  exfiltrate while you dump it. The constant/proto recovery does not
--  need network, so you still get the full pool with egress blocked.
--  Flip it to false ONLY on a throwaway account in a throwaway place.
--
--  USAGE (executor):
--    1. paste this above the target, or set CONFIG.TargetSource /
--       CONFIG.TargetUrl to have the logger load the target itself.
--    2. run. Dumps land in CONFIG.OutDir via writefile:
--         constants.txt   every unique constant (readable), URLs flagged
--         protos.txt      per-closure constant/upvalue listing
--         stages/         every loadstring/load source captured
--         network.txt     HttpGet/request URLs + RemoteEvent/Function calls
--         report.txt      summary + IOC section
--    3. feed constants.txt back into devirt/lift.py (see bottom note).
-- ============================================================

local CONFIG = {
    OutDir        = "lph_env",
    TargetSource  = nil,     -- string: target script source to run under the logger
    TargetUrl     = nil,     -- string: game:HttpGet this and run it (needs network)
    BlockNetwork  = true,    -- log HttpGet/request but do NOT forward them
    ScanGC        = true,    -- sweep getgc() for VM closures and dump their constants
    MaxProtoDepth = 40,      -- recursion cap for debug.getprotos
    MaxFunctions  = 200000,  -- cap on closures inspected (getgc can be huge)
    MaxStrings    = 200000,  -- cap on unique constants recorded
}

-- ── feature detection (every executor differs) ───────────────
-- getgenv is near-universal in executors; fall back to the global env so the
-- logger still runs (with reduced reach) on odd runtimes and offline checks.
local getgenv = getgenv or function() return (getfenv and getfenv(0)) or _G end

local F = {
    getgc          = rawget(getfenv(), "getgc") or getgc,
    getconstants   = (debug and (debug.getconstants or debug.getconstant and nil)) or getconstants,
    getprotos      = (debug and debug.getprotos) or getprotos,
    getupvalues    = (debug and debug.getupvalues) or getupvalues,
    getinfo        = (debug and debug.getinfo) or getinfo,
    islclosure     = islclosure,
    iscclosure     = iscclosure,
    hookfunction   = hookfunction or replaceclosure,
    hookmetamethod = hookmetamethod,
    getnamecall    = getnamecallmethod,
    getrawmeta     = getrawmetatable,
    setreadonly    = setreadonly,
    newcclosure    = newcclosure or function(f) return f end,
    writefile      = writefile,
    makefolder     = makefolder,
}
-- debug.getconstants may live as debug.getconstants specifically:
if debug and debug.getconstants then F.getconstants = debug.getconstants end

local function has(name) return type(F[name]) == "function" end

-- ── output plumbing ──────────────────────────────────────────
if has("makefolder") then pcall(F.makefolder, CONFIG.OutDir) end
local buffers = { constants = {}, protos = {}, network = {}, report = {} }
local function push(buf, line) local b = buffers[buf]; b[#b + 1] = line end
local function say(line) push("report", line); print("[env] " .. line) end

local function flush()
    if not has("writefile") then
        say("no writefile in this executor -- printing report only")
        return
    end
    for name, b in pairs(buffers) do
        pcall(F.writefile, CONFIG.OutDir .. "/" .. name .. ".txt", table.concat(b, "\n"))
    end
end

-- ── constant / string bookkeeping ────────────────────────────
local seenStr, nStr = {}, 0
local URL_PATTERNS = { "https?://[%w%.%-_/%?%%&=:@~#%+]+", "discord%.[%w]+/[%w%-]+", "dsc%.gg/[%w]+" }
local iocs = {}

local function looksReadable(s) return #s >= 2 and #s <= 4096 and s:find("[%w]") ~= nil end

local function record(s, origin)
    if type(s) ~= "string" or seenStr[s] or not looksReadable(s) then return end
    seenStr[s] = true; nStr = nStr + 1
    if nStr <= CONFIG.MaxStrings then
        push("constants", string.format("%q", s):gsub("[\r\n]", " "))
    end
    for _, pat in ipairs(URL_PATTERNS) do
        for m in s:gmatch(pat) do
            if not iocs[m] then iocs[m] = true; push("network", "[IOC] " .. m); say("IOC " .. m) end
        end
    end
    if s:find("webhook") or s:find("api%.") then
        if not iocs[s] then iocs[s] = true; push("network", "[IOC?] " .. s) end
    end
end

-- ── deep constant dump: read constants straight from a closure ──
local seenFn = {}
local nFn, nProtoDumps = 0, 0

local function dumpClosure(fn, depth, label)
    if type(fn) ~= "function" or seenFn[fn] then return end
    if has("iscclosure") and F.iscclosure(fn) then return end     -- C funcs have no Lua constants
    if has("islclosure") and not F.islclosure(fn) then return end
    seenFn[fn] = true; nFn = nFn + 1
    if nFn > CONFIG.MaxFunctions then return end

    local info = has("getinfo") and select(2, pcall(F.getinfo, fn)) or nil
    local tag = label or (info and (info.short_src or info.source) or "?")

    if has("getconstants") then
        local ok, consts = pcall(F.getconstants, fn)
        if ok and type(consts) == "table" then
            nProtoDumps = nProtoDumps + 1
            local nk = 0
            for _, k in pairs(consts) do
                nk = nk + 1
                if type(k) == "string" then record(k, tag)
                elseif type(k) == "function" then dumpClosure(k, depth, tag)  -- inline func-consts
                end
            end
            if nk > 0 then push("protos", ("closure#%d [%s]  %d constants"):format(nProtoDumps, tostring(tag), nk)) end
        end
    end

    if has("getupvalues") then
        local ok, ups = pcall(F.getupvalues, fn)
        if ok and type(ups) == "table" then
            for _, u in pairs(ups) do
                if type(u) == "string" then record(u, tag .. ":upval")
                elseif type(u) == "function" then dumpClosure(u, depth, tag) end
            end
        end
    end

    if has("getprotos") and depth < CONFIG.MaxProtoDepth then
        local ok, protos = pcall(F.getprotos, fn)
        if ok and type(protos) == "table" then
            for _, p in ipairs(protos) do dumpClosure(p, depth + 1, tag) end
        end
    end
end

-- ── hooks: compiler capture + live network / namecall spy ─────
local stageN = 0
local realLoadstring = loadstring or load
local realLoad = load

local function captureStage(src)
    if type(src) ~= "string" then return end
    stageN = stageN + 1
    if has("writefile") then
        pcall(F.writefile, CONFIG.OutDir .. "/stages/stage_" .. stageN .. ".lua", src)
    end
    for tok in src:gmatch('"([^"]*)"') do record(tok, "stage" .. stageN) end
    for tok in src:gmatch("'([^']*)'") do record(tok, "stage" .. stageN) end
    say(("captured compile stage #%d (%d bytes)"):format(stageN, #src))
end

local function wrapCompiler(fn)
    return function(src, ...)
        captureStage(src)
        local f = fn(src, ...)
        if type(f) == "function" then dumpClosure(f, 0, "loadstring#" .. stageN) end
        return f
    end
end
-- expose wrapped compilers to any code that reads them from _G
getgenv().loadstring = wrapCompiler(realLoadstring)
if realLoad then getgenv().load = wrapCompiler(realLoad) end

-- HttpGet / request: log (and optionally block) every egress
local function hookHttp()
    if not has("hookfunction") then return end
    local function wrapReq(orig, name)
        return function(a, b, ...)
            local url = (type(a) == "table" and a.Url) or b or a
            push("network", name .. "  " .. tostring(url)); say(name .. " " .. tostring(url))
            record(tostring(url), name)
            if CONFIG.BlockNetwork then return name == "request" and { StatusCode = 200, Body = "", Headers = {} } or "" end
            return orig(a, b, ...)
        end
    end
    for _, n in ipairs({ "request", "http_request" }) do
        local g = rawget(getfenv(), n) or (getgenv() and getgenv()[n])
        if type(g) == "function" then pcall(function() getgenv()[n] = wrapReq(g, "request") end) end
    end
    if syn and type(syn.request) == "function" then pcall(function() syn.request = wrapReq(syn.request, "request") end) end
    -- HttpGet lives on the DataModel; hook via metamethod path below if available
end

-- __namecall spy: catches RemoteEvent/Function traffic + game:HttpGet
local function hookNamecall()
    if not (has("hookmetamethod") and has("getnamecall")) then return end
    local old
    old = F.hookmetamethod(game, "__namecall", function(self, ...)
        local method = F.getnamecall()
        if method == "HttpGet" or method == "HttpGetAsync" then
            local url = (...)
            push("network", "HttpGet  " .. tostring(url)); record(tostring(url), method)
            if CONFIG.BlockNetwork then return "" end
        elseif method == "FireServer" or method == "InvokeServer" then
            local ok, cls = pcall(function() return self.ClassName end)
            push("network", ("%s:%s(%s)"):format(tostring(ok and cls or "Remote"), method, tostring((...))))
        end
        return old(self, ...)
    end)
end

-- ── run ──────────────────────────────────────────────────────
local function scanGC()
    if not (CONFIG.ScanGC and has("getgc")) then return end
    say("sweeping getgc() for Lua closures ...")
    local ok, gc = pcall(F.getgc, true)
    if not ok or type(gc) ~= "table" then ok, gc = pcall(F.getgc) end
    if type(gc) ~= "table" then say("getgc unavailable"); return end
    for _, v in pairs(gc) do
        if type(v) == "function" then dumpClosure(v, 0, "gc") end
        if nFn > CONFIG.MaxFunctions then break end
    end
end

local function runTarget()
    local src = CONFIG.TargetSource
    if not src and CONFIG.TargetUrl and type(game) == "userdata" then
        local ok, body = pcall(function() return game:HttpGet(CONFIG.TargetUrl) end)
        if ok then src = body end
    end
    if not src then return end
    say("running target under the logger (" .. #src .. " bytes)")
    local f = getgenv().loadstring(src)          -- wrapped: captures + deep-dumps
    if type(f) == "function" then pcall(f) end
end

local function main()
    say("env_logger: capabilities -> " ..
        table.concat({
            has("getgc") and "getgc" or "-",
            has("getconstants") and "getconstants" or "-",
            has("getprotos") and "getprotos" or "-",
            has("getupvalues") and "getupvalues" or "-",
            has("hookmetamethod") and "namecall" or "-",
            has("hookfunction") and "hookfn" or "-",
        }, " "))
    hookHttp(); hookNamecall()
    runTarget()      -- if a target was supplied, run it (populates closures)
    scanGC()         -- then sweep memory for every VM closure and dump constants
    say(("done. %d closures inspected, %d proto dumps, %d unique constants, %d stages.")
        :format(nFn, nProtoDumps, nStr, stageN))
    if next(iocs) == nil then push("network", "(no URL/webhook constant observed)") end
    flush()
end

main()

-- ── feeding results back into the offline lift ────────────────
--  constants.txt is the *complete* readable constant pool (cold code
--  included). To resolve lift.py's K(i) with it, pass it as an extra
--  decoded source once converted to the (op,operand)/value shape, or
--  simply read it alongside lifted.lua: every K(i) string the payload
--  can ever use is now enumerated here. This is the recovery step that
--  offline execution cannot reach.
