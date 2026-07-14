-- luau-vm/src/harden.lua
-- Per-build hardening primitives for the VM bundler. These make two emitted
-- builds of the same source differ, and raise the cost of a generic
-- devirtualizer, without touching the (validated) compiler/VM core:
--
--   * opcode permutation  — the serialized bytecode uses a per-build opcode
--     numbering, so tooling keyed to the canonical opcode set can't read it.
--   * bytecode encryption — a custom GraniteRNG XOR keystream over the whole
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

-- ── GraniteRNG: our own PRNG (not Park-Miller / not any named generator) ──────
-- A full-period LCG over 2^32 (GA % 4 == 1, GC odd) whose raw output is run
-- through a custom multiply-rotate-multiply avalanche so the emitted bytes mix
-- well. Every product stays < 2^53, so the sequence is bit-identical in Lua
-- 5.1-5.4 doubles AND Luau doubles. Uses no bit32 and no recognizable constant.
local GA, GC = 3218467781, 2596069031     -- LCG multiplier / increment
local GM1, GM2 = 3812015801, 1274126177   -- avalanche multipliers (odd)
local TWO32 = 4294967296

-- (a * b) mod 2^32, computed split so the intermediate stays exact in doubles.
local function gmul(a, b)
  local al = a % 65536
  return ((al * b) + (((a - al) / 65536 * b) % 65536) * 65536) % TWO32
end

-- Custom avalanche: multiply, swap the two 16-bit halves, multiply again.
local function gmix(s)
  local x = gmul(s, GM1)
  x = (x % 65536) * 65536 + (x - x % 65536) / 65536
  return gmul(x, GM2)
end

-- Stateful generator. `int`/`byte` advance the LCG and return a mixed value;
-- `next` returns the full mixed 32-bit word (used to draw sub-seeds).
function H.prng(seed)
  local st = seed % TWO32
  local function step() st = (gmul(st, GA) + GC) % TWO32; return gmix(st) end
  return {
    next = function() return step() end,
    int = function(n) return step() % n end,
    byte = function() return step() % 256 end,
  }
end

H.gmul = gmul
H.gmix = gmix

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

-- XOR `data` with a GraniteRNG keystream seeded by `seed`. Symmetric: the
-- emitted bootstrap runs the identical routine to decrypt.
function H.encrypt(data, seed)
  local rng = H.prng(seed)
  local out, len = {}, #data
  for i = 1, len do
    out[i] = string.char(Bit.bxor(data:byte(i), rng.byte()))
  end
  return table.concat(out)
end

-- ── custom multi-stage bytecode cipher ("GraniteCipher") ─────────────────────
-- A per-build, fully custom cipher over the serialized bytecode blob. Chain:
--
--   plaintext bytes
--     │  (1) per-build random seed  -> (2) key schedule: derive sub-seeds
--     ▼
--   (3) byte permutation     keyed Fisher-Yates over byte POSITIONS
--     ▼
--   (4) byte substitution    per-build bijective S-box over byte VALUES
--     ▼
--   (5) stream masking        GraniteRNG keystream XOR with cipher-feedback
--                             chaining (CBC-like), so one flipped byte
--                             avalanches through the rest
--     ▼
--   (6) integrity checksum    custom 32-bit rolling sum prepended
--     ▼
--   (7) base64                (done by the bundler)
--
-- Every stage is regenerable from the sub-seeds alone, so the emitted decoder
-- ships only three small factored seeds + an IV — never the S-box, permutation
-- table, or keystream — and inverts the chain in pure Luau (no loadstring).

-- Deterministic bijective S-box: Fisher-Yates over 0..255 driven by `seed`.
-- Returns the forward map s[v] (0-indexed values held at 0-indexed keys).
function H.sbox(seed)
  local rng = H.prng(seed)
  local s = {}
  for i = 0, 255 do s[i] = i end
  for i = 255, 1, -1 do
    local j = rng.int(i + 1) -- 0..i
    s[i], s[j] = s[j], s[i]
  end
  return s
end

-- Swap partners for a keyed position permutation of `n` bytes. js[i] (i=2..n)
-- is the 1-based partner used at step i. Applying the swaps for i=n..2 permutes;
-- applying them for i=2..n inverts (each swap is its own inverse).
function H.permSwaps(seed, n)
  local rng = H.prng(seed)
  local js = {}
  for i = n, 2, -1 do js[i] = rng.int(i) + 1 end -- 1..i
  return js
end

-- Our own 32-bit integrity checksum ("GraniteSum") — NOT djb2/FNV/CRC. Two
-- coupled accumulators: lane `a` folds each byte with a custom multiplier, lane
-- `b` sums the running `a` (so position matters and one flipped byte avalanches
-- through the tail). Products stay < 2^53, exact in Lua 5.1-5.4 + Luau doubles.
-- Authenticates the *ciphertext* before any decode.
function H.checksum(s)
  local a, b = 19088743, 1985229328
  for i = 1, #s do
    a = (a * 178711 + s:byte(i) + 1) % 4294967296
    b = (b + a) % 4294967296
  end
  return (a + gmul(b, 40503)) % 4294967296
end

-- Seal `plain` with the full chain using per-build sub-seeds drawn from `rng`.
-- Returns the sealed byte string (checksum-prefixed ciphertext) and the params
-- the emitted decoder needs to invert it.
function H.seal(plain, rng)
  local permSeed = rng.next()
  local sboxSeed = rng.next()
  local maskSeed = rng.next()
  local iv = rng.byte()
  local n = #plain

  -- (3) byte permutation
  local a = {}
  for i = 1, n do a[i] = plain:byte(i) end
  local js = H.permSwaps(permSeed, n)
  for i = n, 2, -1 do a[i], a[js[i]] = a[js[i]], a[i] end

  -- (4) byte substitution
  local sbox = H.sbox(sboxSeed)
  for i = 1, n do a[i] = sbox[a[i]] end

  -- (5) stream masking with cipher-feedback chaining
  local mrng = H.prng(maskSeed)
  local prev = iv
  for i = 1, n do
    local c = Bit.bxor(Bit.bxor(a[i], mrng.byte()), prev)
    a[i] = c
    prev = c
  end

  local body = {}
  for i = 1, n do body[i] = string.char(a[i]) end
  local cipher = table.concat(body)

  -- (6) integrity checksum, 4 bytes big-endian, prepended
  local sum = H.checksum(cipher)
  local head = string.char(
    math.floor(sum / 16777216) % 256,
    math.floor(sum / 65536) % 256,
    math.floor(sum / 256) % 256,
    sum % 256)

  return head .. cipher, { permSeed = permSeed, sboxSeed = sboxSeed, maskSeed = maskSeed, iv = iv }
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
