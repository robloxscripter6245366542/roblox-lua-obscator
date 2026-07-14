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
local function nextByte(st)
  st = (gmul(st, 3218467781) + 2596069031) % 4294967296
  return st, st % 256
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
