-- Crystal Language Runtime
-- Full pipeline: analyze → auto-fix → inject HTTPS (if missing) → compile → VM execute
-- Also exposes: Crystal.obfuscate(src) → obfuscated Lua stronger than Luraph

local lexerModule  = require(script.lexer)
local Parser       = require(script.parser)
local compilerMod  = require(script.compiler)
local vmMod        = require(script.vm)
local Obfuscator   = require(script.obfuscator)
local Analyzer     = require(script.analyzer)
local HTTP         = require(script.http)

local Lexer    = lexerModule.Lexer
local Compiler = compilerMod.Compiler
local VM       = vmMod.VM
local disasm   = vmMod.disassemble

local Crystal = {}

-- ── Globals injected into every Crystal program ───────────────────────────────

Crystal.globals = {
    print     = print,
    warn      = warn or print,
    wait      = task and task.wait or wait,
    game      = game,
    workspace = workspace,
    script    = script,
    Vector3   = Vector3,
    Color3    = Color3,
    UDim2     = UDim2,
    UDim      = UDim,
    CFrame    = CFrame,
    Enum      = Enum,
    Instance  = Instance,
    task      = task,
    bit32     = bit32,
    math      = math,
    string    = string,
    table     = table,
    os        = { clock = os.clock, time = os.time },
    tostring  = tostring,
    tonumber  = tonumber,
    type      = type,
    pairs     = pairs,
    ipairs    = ipairs,
    select    = select,
    pcall     = pcall,
    xpcall    = xpcall,
    error     = error,
    assert    = assert,
    setmetatable = setmetatable,
    getmetatable = getmetatable,
    rawget    = rawget,
    rawset    = rawset,
    unpack    = table.unpack or unpack,
    -- Built-in Glass UI
    UI        = require(script.ui.glass),
    -- Built-in HTTP/HTTPS
    HTTP      = HTTP,
}

-- ── Module registry ───────────────────────────────────────────────────────────

Crystal.modules = {}

Crystal.globals["__crystal_import__"] = function(path)
    if Crystal.modules[path] then return Crystal.modules[path] end
    error("Crystal: module '" .. path .. "' not found")
end

function Crystal.register(name, value)
    Crystal.modules[name] = value
end

-- ── Smart prepare pipeline ────────────────────────────────────────────────────
-- Runs analyzer: auto-fix bugs, inject HTTPS only if not already present

function Crystal.prepare(luaSrc, options)
    options = options or {}
    -- options.injectHTTPS  (default true)
    -- options.autoFix      (default true)
    -- options.fixes        (table of fix name → bool)

    local result = Analyzer.prepare(luaSrc, {
        injectHTTPS = options.injectHTTPS ~= false,
        fixes       = options.fixes,
    })

    return result
end

-- ── Compile Crystal source → bytecode chunk ───────────────────────────────────

function Crystal.compile(source, sourceName)
    sourceName = sourceName or "<crystal>"
    local lexer    = Lexer.new(source)
    local tokens   = lexer:tokenize()
    local parser   = Parser.new(tokens)
    local ast      = parser:parse()
    local compiler = Compiler.new()
    local chunk    = compiler:compile(ast)
    chunk.name     = sourceName
    return chunk
end

-- ── Execute a compiled chunk ───────────────────────────────────────────────────

function Crystal.execute(chunk, extraGlobals)
    local g = {}
    for k, v in pairs(Crystal.globals) do g[k] = v end
    if extraGlobals then
        for k, v in pairs(extraGlobals) do g[k] = v end
    end
    local vm = VM.new(g)
    return vm:execute(chunk)
end

-- ── Run Crystal source (compile + execute) ────────────────────────────────────

function Crystal.run(source, sourceName, extraGlobals)
    local ok, result = pcall(function()
        local chunk = Crystal.compile(source, sourceName)
        return Crystal.execute(chunk, extraGlobals)
    end)
    if not ok then return nil, result end
    return result, nil
end

-- ── Obfuscate a Lua script (stronger than Luraph 14.7) ───────────────────────
-- Crystal.obfuscate(src, strength?)
--   strength: "fast" | "balanced" | "max" (default "max")
--
-- What happens:
--   1. Analyzer auto-fixes any bugs in the script
--   2. HTTPS is injected if the script needs it but doesn't have it yet
--   3. Multi-layer obfuscation runs (name mangling → string encryption →
--      number splitting → dead code → anti-debug → VM wrap + bytecode cipher)
--   4. Returns the obfuscated, self-contained Lua string ready to execute

function Crystal.obfuscate(src, strength, options)
    strength = strength or "max"
    options  = options  or {}

    -- Step 1: Analyze + auto-fix + smart HTTPS injection
    local prepared = Crystal.prepare(src, {
        injectHTTPS = options.injectHTTPS ~= false,
        autoFix     = options.autoFix     ~= false,
        fixes       = options.fixes,
    })

    local fixedSrc = prepared.source
    local log      = prepared.fixLog or {}

    -- Report what was done
    if prepared.wasFixed then
        for _, msg in ipairs(log) do
            (warn or print)(msg)
        end
    end
    if prepared.httpsInjected then
        (warn or print)("[Crystal] HTTPS auto-injected (was not present in script)")
    end
    if not prepared.valid then
        (warn or print)("[Crystal] Syntax warning before obfuscation: " .. tostring(prepared.syntaxError))
    end

    -- Step 2: Obfuscate with chosen strength
    local presets = {
        fast     = Obfuscator.FAST,
        balanced = Obfuscator.BALANCED,
        max      = Obfuscator.MAX,
    }
    local preset = presets[strength] or Obfuscator.MAX

    local ob     = Obfuscator.new(preset)
    local result = ob:obfuscate(fixedSrc, options.name or "script")

    return result, {
        originalLength  = #src,
        outputLength    = #result,
        wasFixed        = prepared.wasFixed,
        fixLog          = log,
        httpsInjected   = prepared.httpsInjected,
        featuresFound   = prepared.features,
        strength        = strength,
    }
end

-- ── Obfuscate + immediately load/run (for executor use) ───────────────────────
-- Crystal.obfuscateAndRun(src) — fixes, obfuscates, then executes in-place

function Crystal.obfuscateAndRun(src, strength, options)
    local obfSrc, info = Crystal.obfuscate(src, strength, options)
    local fn, err = load(obfSrc, "@crystal_obf", "t", getfenv and getfenv() or _ENV)
    if not fn then
        error("[Crystal] Failed to load obfuscated script: " .. tostring(err))
    end
    return fn(), info
end

-- ── Disassembler ─────────────────────────────────────────────────────────────

function Crystal.disassemble(chunk)
    return disasm(chunk)
end

-- ── Analyzer access ───────────────────────────────────────────────────────────

Crystal.Analyzer    = Analyzer
Crystal.Obfuscator  = Obfuscator
Crystal.HTTP        = HTTP

-- ── Version ───────────────────────────────────────────────────────────────────

Crystal.VERSION = "1.0.0"
Crystal.LANG    = "Crystal"
Crystal.BUILD   = "anti-tamper+custom-vm+obf-max"

return Crystal
