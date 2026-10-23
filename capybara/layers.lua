-- capybara/layers.lua
-- Semantics-preserving, token-level transform passes.
--
-- capybara's signature is the *constant pool*: instead of wrapping every string
-- in its own inline decoder call, all string literals are hoisted into a single
-- encrypted table decoded once at load time, and each use site becomes a bare
-- table index `(P[k])`. This shrinks the surface a reader can pattern-match on
-- and collapses repeated strings behind opaque indices.
--
--   stringPool : string literals  -> (P[k]),  P built from an encrypted blob
--   numberFold : integer literals -> ((A)%(M)) where A%M == n
--
-- Every emitted construct evaluates to a value identical to the source, so the
-- obfuscated program behaves exactly like the original on any Lua 5.1+/Luau.

local Layers = {}

local MOD = 2147483648

-- Pure-arithmetic byte XOR, portable across 5.1 / 5.2 / 5.3 / 5.4 / Luau.
local function bxor(a, b)
    local r, p = 0, 1
    while a > 0 or b > 0 do
        local aa, bb = a % 2, b % 2
        if aa ~= bb then r = r + p end
        a = (a - aa) / 2
        b = (b - bb) / 2
        p = p * 2
    end
    return r
end

-- Per-entry keystream matching the runtime decoder in buildPrelude.
local function encrypt(s, salt)
    local out, st = {}, salt % MOD
    for i = 1, #s do
        st = (st * 1103515245 + 12345) % MOD
        out[i] = string.char(bxor(s:byte(i), st % 256))
    end
    return table.concat(out)
end

-- Hoist every string literal into a shared pool.
-- Returns the rewritten token list and the ordered list of pool entries
-- ({ cipher=, salt= }); identical strings collapse to one entry.
function Layers.stringPool(tokens, rng, names)
    local pool = {}     -- ordered entries
    local index = {}    -- decoded value -> pool position (dedupe)
    local out = {}

    for _, tok in ipairs(tokens) do
        if tok.type == "string" then
            local k = index[tok.value]
            if not k then
                local salt = rng:range(1, MOD - 1000)
                pool[#pool + 1] = { cipher = encrypt(tok.value, salt), salt = salt }
                k = #pool
                index[tok.value] = k
            end
            -- (P[k]) — parenthesized so call-with-string sugar stays valid:
            -- `print "x"` -> `print (P[3])`.
            out[#out + 1] = { type = "symbol", value = "(", raw = "(", line = tok.line }
            out[#out + 1] = { type = "name", value = names.pool, raw = names.pool, line = tok.line }
            out[#out + 1] = { type = "symbol", value = "[", raw = "[", line = tok.line }
            out[#out + 1] = { type = "number", value = k, raw = tostring(k), line = tok.line }
            out[#out + 1] = { type = "symbol", value = "]", raw = "]", line = tok.line }
            out[#out + 1] = { type = "symbol", value = ")", raw = ")", line = tok.line }
        else
            out[#out + 1] = tok
        end
    end
    return out, pool
end

-- Replace plain non-negative decimal integer literals with ((A)%(M)), where
-- M > n and A = n + M*mult, so A % M == n. Touches only ^%d+$ so hex/float/
-- exponent forms keep their exact typing.
function Layers.numberFold(tokens, rng)
    local out = {}
    for _, tok in ipairs(tokens) do
        if tok.type == "number" and type(tok.raw) == "string"
            and tok.raw:match("^%d+$") and #tok.raw <= 9 then
            local n = tonumber(tok.raw)
            local m = n + rng:range(1, 900000)      -- M > n
            local a = n + m * rng:range(1, 40)       -- A % M == n
            local ln = tok.line
            for _, t in ipairs({
                { value = "(", raw = "(", type = "symbol" },
                { value = "(", raw = "(", type = "symbol" },
                { value = a, raw = tostring(a), type = "number" },
                { value = ")", raw = ")", type = "symbol" },
                { value = "%", raw = "%", type = "symbol" },
                { value = "(", raw = "(", type = "symbol" },
                { value = m, raw = tostring(m), type = "number" },
                { value = ")", raw = ")", type = "symbol" },
                { value = ")", raw = ")", type = "symbol" },
            }) do
                t.line = ln
                out[#out + 1] = t
            end
        else
            out[#out + 1] = tok
        end
    end
    return out
end

-- Runtime prelude: a single-line decoder + the fully built pool table.
-- Primitives are captured into locals at load time so later mutation of the
-- global environment cannot break decoding.
function Layers.buildPrelude(names, pool)
    local Emit = require("emit")
    local sc, sb, tc, dec, poolName = names.sc, names.sb, names.tc, names.dec, names.pool
    local L = {}
    local function e(s) L[#L + 1] = s end

    e("local " .. sc .. "=string.char")
    e("local " .. sb .. "=string.byte")
    e("local " .. tc .. "=table.concat")
    e("local function " .. dec .. "(e,s)")
    e("local t={} local st=s%2147483648")
    e("for i=1,#e do")
    e("st=(st*1103515245+12345)%2147483648")
    e("local a,b=" .. sb .. "(e,i),st%256")
    e("local r,p=0,1")
    e("while a>0 or b>0 do")
    e("local aa,bb=a%2,b%2")
    e("if aa~=bb then r=r+p end")
    e("a=(a-aa)/2 b=(b-bb)/2 p=p*2")
    e("end")
    e("t[i]=" .. sc .. "(r)")
    e("end")
    e("return " .. tc .. "(t)")
    e("end")

    -- pool table
    local entries = {}
    for _, ent in ipairs(pool) do
        entries[#entries + 1] = dec .. "(" .. Emit.stringLiteral(ent.cipher) .. "," .. tostring(ent.salt) .. ")"
    end
    e("local " .. poolName .. "={" .. table.concat(entries, ",") .. "}")

    return table.concat(L, "\n")
end

function Layers.makeNames(rng)
    return {
        sc = rng:name(6),
        sb = rng:name(6),
        tc = rng:name(6),
        dec = rng:name(7),
        pool = rng:name(7),
    }
end

return Layers
