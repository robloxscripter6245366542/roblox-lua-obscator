-- luau-vm/src/harden.lua
-- Per-build hardening primitives for the VM bundler. These make two emitted
-- builds of the same source differ, and raise the cost of a generic
-- devirtualizer, without touching the (validated) compiler/VM core:
--
--   * opcode permutation  — the serialized bytecode uses a per-build opcode
--     numbering, so tooling keyed to the canonical opcode set can't read it.
--   * bytecode encryption — a Park-Miller XOR keystream over the whole
--     serialized blob, so a base64 decode no longer reveals the proto tables.
--   * key factoring       — the keystream seed is emitted as an arithmetic
--     expression, not a single grep-able literal.
--   * comment stripping   — the bundled interpreter ships without its
--     self-documenting comments, so opcode semantics aren't handed over.
--
-- None of this is unbreakable (no self-contained client-side obfuscator can
-- be — the key and decoder must be present to run). It defeats automated /
-- canned tooling and casual copy-paste, which is the realistic threat.

local Bit = require('bitops')

local H = {}

-- Park-Miller minimal-standard LCG. Products stay < 2^53, so the sequence is
-- identical in Lua 5.1-5.4 doubles AND Luau doubles (the same reason the ferret
-- keystream uses it). Returns a stateful generator.
function H.prng(seed)
  local st = seed % 2147483647
  if st <= 0 then st = st + 2147483646 end
  return {
    -- next raw state in [1, 2147483646]
    next = function() st = (st * 16807) % 2147483647; return st end,
    -- next integer in [0, n-1]
    int = function(n) st = (st * 16807) % 2147483647; return st % n end,
    -- next byte in [0, 255]
    byte = function() st = (st * 16807) % 2147483647; return st % 256 end,
  }
end

-- Build a per-build opcode permutation for `count` canonical opcodes (1..count).
-- Returns fwd (canonical -> emitted byte) and inv (emitted byte -> canonical),
-- each opcode mapped to a distinct byte in [1, 255].
function H.opPermutation(count, rng)
  local pool = {}
  for b = 1, 255 do pool[b] = b end
  -- Fisher-Yates shuffle the byte pool
  for i = 255, 2, -1 do
    local j = rng.int(i) + 1
    pool[i], pool[j] = pool[j], pool[i]
  end
  local fwd, inv = {}, {}
  for op = 1, count do
    local b = pool[op]
    fwd[op] = b
    inv[b] = op
  end
  return fwd, inv
end

-- XOR `data` with a Park-Miller keystream seeded by `seed`. Symmetric: the
-- emitted bootstrap runs the identical routine to decrypt.
function H.encrypt(data, seed)
  local rng = H.prng(seed)
  local out, len = {}, #data
  for i = 1, len do
    out[i] = string.char(Bit.bxor(data:byte(i), rng.byte()))
  end
  return table.concat(out)
end

-- Emit `seed` as an arithmetic expression `(m*q+r)` rather than a bare literal,
-- so the keystream seed is not directly grep-able in the output. Factors are
-- kept < 2^31 so the product is exact in every target runtime.
function H.factorKey(seed, rng)
  local m = rng.int(40000) + 4096         -- 4096 .. 44095
  local q = math.floor(seed / m)
  local r = seed % m
  return string.format('(%d*%d+%d)', m, q, r)  -- == m*q + r == seed
end

-- Render a { byte = canonical } Lua table literal (the inverse opcode map the
-- bootstrap hands to the deserializer).
function H.invMapLiteral(inv)
  local parts = {}
  for b, op in pairs(inv) do parts[#parts + 1] = string.format('[%d]=%d', b, op) end
  return '{' .. table.concat(parts, ',') .. '}'
end

-- Strip Lua comments (line and long-bracket) and blank/whitespace-only lines
-- from `src`, correctly skipping over string literals and long-bracket strings
-- so code is never touched. Returns the stripped source. Callers should still
-- guard the result with load() and fall back to the original on any surprise.
function H.stripComments(src)
  local out, i, n = {}, 1, #src
  local function peek(k) return src:sub(i + (k or 0), i + (k or 0)) end
  -- match a long-bracket opener at position i: returns level (>=0) or nil
  local function longOpen()
    if peek() ~= '[' then return nil end
    local j, eq = i + 1, 0
    while src:sub(j, j) == '=' do eq = eq + 1; j = j + 1 end
    if src:sub(j, j) == '[' then return eq end
    return nil
  end
  local function skipLong(eq)
    local close = ']' .. string.rep('=', eq) .. ']'
    local at = src:find(close, i, true)
    return at and (at + #close) or (n + 1)
  end
  while i <= n do
    local c = peek()
    if c == '-' and peek(1) == '-' then
      -- comment: long or line
      i = i + 2
      local eq = longOpen()
      if eq ~= nil then
        i = i + eq + 2
        i = skipLong(eq)
      else
        while i <= n and src:sub(i, i) ~= '\n' do i = i + 1 end
      end
    elseif c == '"' or c == "'" then
      out[#out + 1] = c; i = i + 1
      while i <= n do
        local d = src:sub(i, i)
        out[#out + 1] = d; i = i + 1
        if d == '\\' then out[#out + 1] = src:sub(i, i); i = i + 1
        elseif d == c then break end
      end
    else
      local eq = longOpen()
      if eq ~= nil then
        local from = i
        i = i + eq + 2
        local to = skipLong(eq)
        out[#out + 1] = src:sub(from, to - 1)
        i = to
      else
        out[#out + 1] = c; i = i + 1
      end
    end
  end
  -- drop trailing whitespace on each line and blank lines
  local text = table.concat(out)
  local kept = {}
  for line in (text .. '\n'):gmatch('([^\n]*)\n') do
    local trimmed = line:gsub('%s+$', '')
    if trimmed:match('%S') then kept[#kept + 1] = trimmed end
  end
  return table.concat(kept, '\n')
end

return H
