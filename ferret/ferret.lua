-- ferret/ferret.lua
-- Core obfuscation pipeline. Pure-Lua, Luau-compatible output.
--
-- Inspired by LuaCrypt/ferret's stage design (parse -> transform -> encrypt
-- constants -> emit a standalone runtime). Unlike a bytecode VM, every layer
-- here is semantics-preserving, so obfuscated output runs identically to the
-- source on any Lua 5.1+/Luau runtime.

local Lexer = require("lexer")
local Emit = require("emit")
local Layers = require("layers")
local Rng = require("rng")
local Pack = require("pack")

local Ferret = {}

Ferret.DEFAULT_LAYERS = { "numbers", "strings", "pack" }

-- Faithful reconstruction with no obfuscation (used to validate lex/emit).
function Ferret.roundtrip(src)
    local tokens = Lexer.tokenize(src)
    return Emit.emit(tokens)
end

local function has(set, name)
    for _, v in ipairs(set) do if v == name then return true end end
    return false
end

-- Transform source into obfuscated but semantically identical Lua.
-- opts.seed    : integer, deterministic build (default 1)
-- opts.layers  : list of enabled passes: "numbers","strings","pack"
-- opts.chunkname : name used in lexer diagnostics
function Ferret.obfuscate(src, opts)
    opts = opts or {}
    local rng = Rng.new(opts.seed or 1)
    local names = Layers.makeNames(rng)
    local layers = opts.layers or Ferret.DEFAULT_LAYERS

    local tokens = Lexer.tokenize(src, opts.chunkname)

    -- Fixed pipeline order regardless of list order, so passes never fight.
    if has(layers, "numbers") then
        tokens = Layers.numberEncode(tokens, rng)
    end

    local usedStrings = false
    if has(layers, "strings") then
        tokens = Layers.stringEncrypt(tokens, rng, names)
        usedStrings = true
    end

    local body = Emit.emit(tokens)
    if usedStrings then
        body = Layers.buildPrelude(names) .. "\n" .. body
    end

    -- Final layer: encrypt the whole transformed chunk and emit a loader.
    if has(layers, "pack") then
        body = Pack.wrap(body, rng)
    end

    return body
end

return Ferret
