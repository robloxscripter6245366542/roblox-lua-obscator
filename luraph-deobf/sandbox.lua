-- ============================================================
--  sandbox.lua  --  Luraph dynamic capture harness
--
--  The whole reason a runtime obfuscator can be beaten: the code
--  MUST decrypt and execute in a real Lua VM, and you own that VM.
--  This harness wraps the environment so that every stage the
--  bootstrap decrypts, every string it touches, and every external
--  effect it performs is logged -- without you understanding the VM.
--
--  It targets the Luraph weaknesses catalogued in README.md:
--    W2  environment ownership  -> instrumented globals
--    W3  runtime string decrypt -> loadstring/load stage capture
--    W4  lazy string metatable  -> constant-pool dump
--    W6  external effects        -> HttpGet / IO call trace
--    W7  debug hooks reachable   -> optional line/call tracer
--
--  RUNS IN:
--    * A Roblox executor  (uses writefile / readfile if present)
--    * Plain Lua 5.1 / LuaJIT  (falls back to io.*)
--
--  SAFETY: network + filesystem effects are STUBBED by default so a
--  hostile sample can be observed without letting it phone home or
--  touch disk. Flip CONFIG.AllowNetwork only in a throwaway VM.
--
--  USAGE (executor):
--    1. put the target script's source in a file, e.g. "target.lua"
--    2. set CONFIG.TargetFile
--    3. run this harness; read the dumps in CONFIG.OutDir
--
--  USAGE (plain lua):
--    lua sandbox.lua target.lua
-- ============================================================

local CONFIG = {
    TargetFile   = "target.lua",   -- source of the obfuscated script
    OutDir       = "lph_dump",     -- where captured stages/strings go
    AllowNetwork = false,          -- if true, real HttpGet is used (DANGER)
    TraceCalls   = false,          -- debug.sethook call/line tracer (noisy)
    MaxStrings   = 5000,           -- cap on dumped unique strings
    HttpCache    = {},             -- url -> local file, for offline replay
}

-- ── environment adapters (executor vs plain lua) ─────────────
local hasWrite = type(writefile) == "function"
local hasRead  = type(readfile)  == "function"
local hasFolder= type(makefolder) == "function"

local function ensureDir(path)
    if hasFolder then pcall(makefolder, path) end
    -- plain lua: rely on the shell having created it, or ignore
end

local function saveFile(path, data)
    if hasWrite then
        pcall(writefile, path, data)
    else
        local fh = io.open(path, "wb")
        if fh then fh:write(data); fh:close() end
    end
end

local function loadSource(path)
    if hasRead then
        local ok, s = pcall(readfile, path)
        if ok then return s end
    end
    local fh = io.open(path, "rb")
    if fh then local s = fh:read("*a"); fh:close(); return s end
    return nil
end

ensureDir(CONFIG.OutDir)

-- ── capture state ────────────────────────────────────────────
local stageIndex = 0
local seenStrings = {}
local stringCount = 0
local log = {}

local function note(line)
    log[#log + 1] = line
    print("[lph] " .. line)
end

local function dumpStage(kind, chunk)
    stageIndex = stageIndex + 1
    local path = CONFIG.OutDir .. "/stage_" .. stageIndex .. "_" .. kind .. ".txt"
    saveFile(path, tostring(chunk))
    note(("captured %s stage #%d  (%d bytes) -> %s")
        :format(kind, stageIndex, #tostring(chunk), path))
    return path
end

local function recordString(s)
    if type(s) ~= "string" then return end
    if #s < 4 or #s > 4096 then return end
    if seenStrings[s] then return end
    -- keep only strings that look meaningful (printable-ish)
    if not s:find("[%w%p]") then return end
    seenStrings[s] = true
    stringCount = stringCount + 1
    if stringCount <= CONFIG.MaxStrings then
        log[#log + 1] = "STR\t" .. s:gsub("[\r\n\t]", " ")
    end
end

-- ── instrumented sandbox environment ─────────────────────────
-- We build a fake _G. Reads pass through to the real global; the
-- interesting hooks are on loadstring/load and on game:HttpGet.

local realLoadstring = loadstring or load
local realLoad = load

-- Wrap a compiler so every source it is handed is dumped first.
local function wrapCompiler(fn, label)
    return function(src, ...)
        if type(src) == "string" then
            dumpStage(label, src)
            -- also scavenge readable string literals out of the decrypted stage
            for token in src:gmatch('"([^"]+)"') do recordString(token) end
            for token in src:gmatch("'([^']+)'") do recordString(token) end
        end
        return fn(src, ...)
    end
end

-- Fake HttpGet: serve from cache, or return empty (blocked) unless allowed.
local function fakeHttpGet(_self, url, ...)
    note("HttpGet " .. tostring(url))
    local cached = CONFIG.HttpCache[url]
    if cached then
        local s = loadSource(cached)
        if s then note("  served from cache: " .. cached); return s end
    end
    if CONFIG.AllowNetwork and type(game) == "userdata" then
        return game:HttpGetAsync(url)
    end
    note("  [blocked] returning empty body")
    return ""
end

-- Build a proxy 'game' that logs service/method access but is otherwise inert.
local function makeFakeGame()
    local fake = {}
    function fake:HttpGet(url, ...)   return fakeHttpGet(self, url, ...) end
    function fake:HttpGetAsync(url, ...) return fakeHttpGet(self, url, ...) end
    function fake:GetService(name)
        note("GetService " .. tostring(name))
        return setmetatable({}, { __index = function(_, k)
            note("  " .. tostring(name) .. "." .. tostring(k) .. " accessed")
            return function() end
        end })
    end
    return setmetatable(fake, { __index = function(_, k)
        note("game." .. tostring(k) .. " accessed"); return function() end
    end })
end

-- A string library whose functions record the values passing through them.
-- The VM decrypts constants by calling string.sub/char/byte/pack -- so this
-- catches the decrypted constant pool as a side effect (weakness W4).
local function makeTracingStringLib()
    local realstr = string
    local proxy = {}
    for k, v in pairs(realstr) do
        if type(v) == "function" then
            proxy[k] = function(...)
                local r = v(...)
                recordString(r)
                return r
            end
        else
            proxy[k] = v
        end
    end
    return proxy
end

local function buildEnv()
    local env = setmetatable({}, { __index = _G })
    env._G = env
    env.game = makeFakeGame()
    env.loadstring = wrapCompiler(realLoadstring, "loadstring")
    env.load = wrapCompiler(realLoad, "load")
    env.string = makeTracingStringLib()
    -- block the obvious egress / disk sinks unless explicitly allowed
    if not CONFIG.AllowNetwork then
        env.request = function() note("request() blocked"); return {} end
        env.http_request = env.request
        env.syn = { request = env.request }
    end
    env.writefile = function(p, d) note("writefile " .. tostring(p) .. " (captured, not written)"); recordString(d) end
    return env
end

-- ── run ──────────────────────────────────────────────────────
local function flushLog()
    saveFile(CONFIG.OutDir .. "/report.txt", table.concat(log, "\n"))
    note(("done. %d stages, %d unique strings. Report -> %s/report.txt")
        :format(stageIndex, stringCount, CONFIG.OutDir))
end

local function main(argFile)
    local target = argFile or CONFIG.TargetFile
    local src = loadSource(target)
    if not src then
        note("could not read target '" .. tostring(target) .. "'")
        return
    end
    note("loaded target: " .. target .. " (" .. #src .. " bytes)")

    local env = buildEnv()
    local chunk, err
    if setfenv then                       -- Lua 5.1 / Luau
        chunk, err = realLoadstring(src)
        if chunk then setfenv(chunk, env) end
    else                                  -- Lua 5.2+
        chunk, err = load(src, "=target", "t", env)
    end
    if not chunk then note("compile error: " .. tostring(err)); flushLog(); return end

    if CONFIG.TraceCalls and debug and debug.sethook then
        debug.sethook(function(ev)
            local i = debug.getinfo(2, "nS")
            if i and i.short_src ~= "=[C]" then
                log[#log + 1] = "CALL\t" .. (i.name or "?") .. "\t" .. tostring(i.currentline)
            end
        end, "c")
    end

    local ok, runErr = pcall(chunk)
    if debug and debug.sethook then debug.sethook() end
    if not ok then note("runtime (expected under stubs): " .. tostring(runErr)) end
    flushLog()
end

main(arg and arg[1] or nil)
