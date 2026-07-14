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

-- Hardened-bundle format version. Bumped when the emitted envelope (version +
-- build fingerprint + compression + multi-round cipher) changes shape. Emitted
-- into the sealed payload and gated by the decoder, so a bundle produced by a
-- newer builder refuses to run on a mismatched decoder instead of misbehaving.
H.VM_VERSION = 2

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

-- ── custom bytecode compression ("GraniteRLE") ───────────────────────────────
-- A tiny run-length scheme with a self-describing escape byte, applied to the
-- serialized bytecode BEFORE encryption so the plaintext exposed after a decrypt
-- is still compressed (and smaller). Not zlib/LZ77/any named codec. Layout:
--   flag(1)  0 = stored (raw bytes follow), 1 = RLE
--   RLE body: esc(1) then a stream where `esc,val,count` means val x count and
--             any other byte is a literal (literals are never the esc byte).
-- `esc` is chosen as the least-frequent byte so forced escapes are minimal; the
-- stored fallback guarantees output never grows by more than one byte.
function H.compress(s)
  local n = #s
  if n == 0 then return string.char(0) end
  local freq = {}
  for v = 0, 255 do freq[v] = 0 end
  for i = 1, n do local v = s:byte(i); freq[v] = freq[v] + 1 end
  local esc, best = 0, freq[0]
  for v = 1, 255 do if freq[v] < best then best = freq[v]; esc = v end end
  local out, i = {}, 1
  while i <= n do
    local b = s:byte(i)
    local run = 1
    while i + run <= n and s:byte(i + run) == b and run < 255 do run = run + 1 end
    if run >= 4 or b == esc then
      out[#out + 1] = string.char(esc, b, run)
    else
      for _ = 1, run do out[#out + 1] = string.char(b) end
    end
    i = i + run
  end
  local rle = string.char(esc) .. table.concat(out)
  if #rle + 1 < n + 1 then return string.char(1) .. rle end
  return string.char(0) .. s
end

function H.decompress(s)
  local flag = s:byte(1)
  local rest = s:sub(2)
  if flag == 0 then return rest end
  local esc = rest:byte(1)
  local out, i, n = {}, 2, #rest
  while i <= n do
    local c = rest:byte(i)
    if c == esc then
      local val, cnt = rest:byte(i + 1), rest:byte(i + 2)
      out[#out + 1] = string.rep(string.char(val), cnt)
      i = i + 3
    else
      out[#out + 1] = string.char(c)
      i = i + 1
    end
  end
  return table.concat(out)
end

-- Pack a 32-bit value big-endian.
local function u32be(x)
  x = x % 4294967296
  return string.char(
    math.floor(x / 16777216) % 256,
    math.floor(x / 65536) % 256,
    math.floor(x / 256) % 256,
    x % 256)
end
H.u32be = u32be

-- Wrap already-compressed bytecode in a verifiable envelope: a version byte and
-- a 4-byte build fingerprint (GraniteSum over version+payload). The decoder
-- checks the version (VM versioning) and the fingerprint (anti-tamper: editing
-- the payload, seeds, or version after the fact fails closed with a clear
-- error, instead of silently running altered bytecode).
function H.envelope(payload)
  local v = string.char(H.VM_VERSION)
  local fp = H.checksum(v .. payload)
  return v .. u32be(fp) .. payload
end

-- Apply one cipher round (byte permutation -> S-box -> chained stream mask) to
-- the byte array `a` (length n) in place, using the given sub-seeds/iv.
local function sealRound(a, n, permSeed, sboxSeed, maskSeed, iv)
  local js = H.permSwaps(permSeed, n)
  for i = n, 2, -1 do a[i], a[js[i]] = a[js[i]], a[i] end
  local sbox = H.sbox(sboxSeed)
  for i = 1, n do a[i] = sbox[a[i]] end
  local mrng = H.prng(maskSeed)
  local prev = iv
  for i = 1, n do
    local c = Bit.bxor(Bit.bxor(a[i], mrng.byte()), prev)
    a[i] = c
    prev = c
  end
end

-- Seal `plain` with the full chain using per-build sub-seeds drawn from `rng`.
-- `rounds` (default 1) stacks independent cipher layers, each with its own
-- sub-seeds, so peeling one layer leaves another. Returns the sealed byte
-- string (checksum-prefixed ciphertext) and the per-layer params the emitted
-- decoder needs to invert it (outermost layer last, so the decoder peels the
-- list in reverse).
function H.seal(plain, rng, rounds)
  rounds = rounds or 1
  local n = #plain
  local a = {}
  for i = 1, n do a[i] = plain:byte(i) end

  local layers = {}
  for _ = 1, rounds do
    local L = {
      permSeed = rng.next(),
      sboxSeed = rng.next(),
      maskSeed = rng.next(),
      iv = rng.byte(),
    }
    sealRound(a, n, L.permSeed, L.sboxSeed, L.maskSeed, L.iv)
    layers[#layers + 1] = L
  end

  local body = {}
  for i = 1, n do body[i] = string.char(a[i]) end
  local cipher = table.concat(body)

  -- (6) integrity checksum over the whole ciphertext, 4 bytes big-endian
  local head = u32be(H.checksum(cipher))
  -- Back-compat single-layer fields plus the full layer list.
  local first = layers[1] or {}
  return head .. cipher, {
    rounds = rounds,
    layers = layers,
    permSeed = first.permSeed,
    sboxSeed = first.sboxSeed,
    maskSeed = first.maskSeed,
    iv = first.iv,
  }
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
