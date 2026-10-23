-- capybara/capybara.lua
-- Core obfuscation pipeline. Pure Lua in, Luau-compatible Lua out.
--
-- capybara is an original, semantics-preserving Lua/Luau obfuscator. Every
-- layer rewrites the token stream into constructs whose runtime values are
-- identical to the source, so obfuscated output runs the same on any
-- Lua 5.1+/Luau runtime — no bytecode VM, no native toolchain, no build step.
--
-- Pipeline:
--   lex -> numberFold -> stringPool -> emit -> (prepend prelude) -> pack

local Lexer = require("lexer")
local Emit = require("emit")
local Layers = require("layers")
local Rng = require("rng")
local Pack = require("pack")

local Capybara = {}

Capybara.VERSION = "0.1.0"
Capybara.DEFAULT_LAYERS = { "numbers", "strings", "pack" }

local function has(set, name)
    for _, v in ipairs(set) do if v == name then return true end end
    return false
end

-- Lex then re-emit with no transforms — used to validate the lexer/emitter.
function Capybara.roundtrip(src)
    return Emit.emit(Lexer.tokenize(src))
end

-- Transform `src` into obfuscated but behaviorally identical Lua.
--   opts.seed     : integer, deterministic build (default 1)
--   opts.layers   : subset of {"numbers","strings","pack"} (default all)
--   opts.chunkname: name shown in lexer diagnostics
function Capybara.obfuscate(src, opts)
    opts = opts or {}
    local rng = Rng.new(opts.seed or 1)
    local names = Layers.makeNames(rng)
    local layers = opts.layers or Capybara.DEFAULT_LAYERS

    local tokens = Lexer.tokenize(src, opts.chunkname)

    -- Fixed order regardless of the requested list, so passes never interfere.
    if has(layers, "numbers") then
        tokens = Layers.numberFold(tokens, rng)
    end

    local pool
    if has(layers, "strings") then
        tokens, pool = Layers.stringPool(tokens, rng, names)
    end

    local body = Emit.emit(tokens)
    if pool and #pool > 0 then
        body = Layers.buildPrelude(names, pool) .. "\n" .. body
    end

    if has(layers, "pack") then
        body = Pack.wrap(body, rng)
    end

    return body
end

return Capybara
