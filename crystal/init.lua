-- Crystal Language Runtime
-- Main entry point: lex -> parse -> compile -> verify -> execute

local lexerModule   = require(script.lexer)
local Parser        = require(script.parser)
local compilerMod   = require(script.compiler)
local vmMod         = require(script.vm)

local Lexer    = lexerModule.Lexer
local Compiler = compilerMod.Compiler
local VM       = vmMod.VM
local disasm   = vmMod.disassemble

local Crystal = {}

-- Shared globals exposed to all Crystal programs
Crystal.globals = {
    print    = print,
    warn     = warn or print,
    wait     = task and task.wait or wait,
    game     = game,
    workspace = workspace,
    script   = script,
    Vector3  = Vector3,
    Color3   = Color3,
    UDim2    = UDim2,
    UDim     = UDim,
    CFrame   = CFrame,
    Enum     = Enum,
    Instance = Instance,
}

-- Override import so Crystal scripts can require other Crystal modules
Crystal.modules = {}

Crystal.globals["__crystal_import__"] = function(path)
    if Crystal.modules[path] then
        return Crystal.modules[path]
    end
    error("Crystal: module '" .. path .. "' not found")
end

-- Register a precompiled module so other scripts can import it
function Crystal.register(name, value)
    Crystal.modules[name] = value
end

-- Compile Crystal source into a bytecode chunk
function Crystal.compile(source, sourceName)
    sourceName = sourceName or "<crystal>"

    -- 1. Lex
    local lexer  = Lexer.new(source)
    local tokens = lexer:tokenize()

    -- 2. Parse
    local parser = Parser.new(tokens)
    local ast    = parser:parse()

    -- 3. Compile → bytecode
    local compiler = Compiler.new()
    local chunk    = compiler:compile(ast)
    chunk.name     = sourceName

    return chunk
end

-- Execute a pre-compiled chunk with an optional globals override
function Crystal.execute(chunk, extraGlobals)
    local g = {}
    for k, v in pairs(Crystal.globals) do g[k] = v end
    if extraGlobals then
        for k, v in pairs(extraGlobals) do g[k] = v end
    end

    local vm = VM.new(g)
    return vm:execute(chunk)
end

-- Compile and immediately run Crystal source
function Crystal.run(source, sourceName, extraGlobals)
    local ok, result = pcall(function()
        local chunk = Crystal.compile(source, sourceName)
        return Crystal.execute(chunk, extraGlobals)
    end)
    if not ok then
        return nil, result
    end
    return result, nil
end

-- Disassemble a chunk for inspection
function Crystal.disassemble(chunk)
    return disasm(chunk)
end

-- Version string
Crystal.VERSION = "1.0.0"
Crystal.LANG    = "Crystal"

return Crystal
