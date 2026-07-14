-- luau-vm/src/seal.lua
-- Sealed, streamed code — the runtime JIT/on-demand-decode layer, applied AFTER
-- the build-time GraniteCipher payload has been decoded to proto tables.
--
-- Each proto's instruction array is packed into per-instruction encrypted slices
-- and the plaintext `code` table is dropped. vm.lua then decodes exactly ONE
-- instruction at a time, immediately before executing it. Consequences:
--   * Streamed execution — the whole plaintext instruction stream is never
--     resident; only the current instruction exists, as a short-lived local the
--     GC reclaims (best-effort "memory scrubbing" in a managed runtime).
--   * Ephemeral session key — the key is derived at RUNTIME (per execution), so
--     the in-memory encrypted form differs every run; a memory dump is unstable.
--   * Compact representation — instructions live as opaque encrypted bytes, not
--     an easy-to-inspect {op=,a=,b=} mirror.
--
-- Additive keystream over a GraniteRNG-style split-multiply LCG (products < 2^53,
-- exact on Luau/Lua doubles, no bit library); per-instruction seeds give random
-- access without decrypting neighbours.

local Opcodes = require('opcodes')

local M = {}

-- split-multiply (a*b) mod 2^32, exact in doubles (matches harden.gmul style)
local function gmul(a, b)
  local al = a % 65536
  return ((al * b) + (((a - al) / 65536 * b) % 65536) * 65536) % 4294967296
end

local function putUV(t, x)
  x = math.floor(x)
  while true do
    local b = x % 128; x = math.floor(x / 128)
    if x > 0 then t[#t + 1] = b + 128 else t[#t + 1] = b; break end
  end
end
local function putSV(t, x)
  x = math.floor(x)
  putUV(t, x >= 0 and x * 2 or (-x * 2 - 1)) -- zig-zag
end

-- keystream state for instruction i under session key sk (never zero)
local function seed1(sk, i)
  local s = (gmul(sk, 2654435761) + i * 40503 + 1) % 4294967296
  if s == 0 then s = 1 end
  return s
end
-- independent keystream seed for string constant i (its own domain)
local function seedK(sk, i)
  local s = (gmul(sk, 40503) + i * 2654435761 + 7) % 4294967296
  if s == 0 then s = 1 end
  return s
end
local function nextByte(st)
  st = (gmul(st, 3218467781) + 2596069031) % 4294967296
  return st, st % 256
end

-- Additive mask for numeric constant i (own domain). A 31-bit integer, so for an
-- integer-valued constant with |v| <= 2^52 the sum v+mask stays < 2^53 and is
-- exact in both Lua integers (modular) and Luau doubles; subtracting the same
-- mask recovers v exactly, and Lua's arithmetic preserves the int/float subtype.
local function maskFor(sk, i)
  local st = (gmul(sk, 2246822519) + i * 3266489917 + 11) % 4294967296
  st = (gmul(st, 3218467781) + 2596069031) % 4294967296
  -- math.floor forces an integer subtype on Lua 5.4 (gmul's `/` yields a float),
  -- so an integer constant + mask stays an integer and keeps its subtype.
  return math.floor(st) % 2147483648 + 1 -- integer in 1 .. 2^31
end

-- Seal a proto tree in place: proto.code -> proto.sealed (encrypted slices),
-- plaintext code removed. sk is the runtime-derived session key.
function M.seal(proto, sk)
  local code = proto.code
  local n = #code
  local slices = {}
  for i = 1, n do
    local ins = code[i]
    local raw = { ins.op % 256 }
    for _, f in ipairs(Opcodes.operands[ins.op]) do putSV(raw, ins[f] or 0) end
    local st, kb = seed1(sk, i), nil
    local enc = {}
    for j = 1, #raw do
      st, kb = nextByte(st)
      enc[j] = string.char((raw[j] + kb) % 256) -- additive stream cipher
    end
    slices[i] = table.concat(enc)
  end
  proto.sealed = { slices = slices, n = n, sk = sk }
  proto.code = nil

  -- Constant encryption: string constants (the dump target — URLs, remote names,
  -- keys, messages) are encrypted and stored behind a proxy that decrypts on
  -- access, so they are never resident in plaintext even after a devirtualizer
  -- recovers the bytecode. Non-strings pass through. Strings intern in Lua, so
  -- decrypting the same constant twice yields the same object (identity safe).
  local K = proto.consts
  local realK, hasEnc, nk = {}, false, #K
  for i = 1, nk do
    local v = K[i]
    local t = type(v)
    if t == 'string' then
      hasEnc = true
      local st, kb = seedK(sk, i), nil
      local out = {}
      for j = 1, #v do st, kb = nextByte(st); out[j] = string.char((v:byte(j) + kb) % 256) end
      realK[i] = { s = table.concat(out) }
    elseif t == 'number' and v == v and v <= 4503599627370496 and v >= -4503599627370496
        and math.floor(v) == v then
      -- integer-valued number: hide behind an additive keystream mask (fractional
      -- / inf / nan pass through untouched to avoid any precision or subtype bug)
      hasEnc = true
      realK[i] = { n = v + maskFor(sk, i) }
    else
      realK[i] = v
    end
  end
  if hasEnc then
    proto.consts = setmetatable({}, { __index = function(_, i)
      local e = realK[i]
      if type(e) == 'table' then
        if e.n ~= nil then return e.n - maskFor(sk, i) end -- numeric constant
        local st, kb = seedK(sk, i), nil                   -- string constant
        local enc, o = e.s, {}
        for j = 1, #enc do st, kb = nextByte(st); o[j] = string.char((enc:byte(j) - kb) % 256) end
        return table.concat(o)
      end
      return e
    end })
  end

  for _, child in ipairs(proto.protos) do M.seal(child, sk) end
end

-- Decode a single instruction i from a sealed proto — called right before it
-- runs. Returns a fresh {op=,a=,...} table (a short-lived local at the call site).
function M.decode(sealed, i)
  local s = sealed.slices[i]
  local st, kb = seed1(sealed.sk, i), nil
  local len = #s
  local bytes = {}
  for k = 1, len do
    st, kb = nextByte(st)
    bytes[k] = (s:byte(k) - kb) % 256 -- inverse of additive cipher
  end
  local op = bytes[1]
  local ins = { op = op }
  local rp = 2
  for _, f in ipairs(Opcodes.operands[op]) do
    local x, shift = 0, 1
    while true do
      local bb = bytes[rp]; rp = rp + 1
      x = x + (bb % 128) * shift
      if bb < 128 then break end
      shift = shift * 128
    end
    ins[f] = (x % 2 == 0) and math.floor(x / 2) or -math.floor((x + 1) / 2) -- un-zig-zag
  end
  return ins
end

return M
