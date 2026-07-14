-- luau-vm/test/cipher.lua
-- Tests for the custom multi-stage bytecode cipher (GraniteCipher): the build-
-- time seal in harden.lua and an independent reimplementation of the emitted
-- pure-Luau decoder must be exact inverses, the S-box/permutation are
-- bijections, and the integrity checksum catches tampering.

package.path = 'src/?.lua;' .. package.path
local Harden = require('harden')
local Bit = require('bitops')

local pass, fail = 0, 0
local function ok(cond, msg)
  if cond then pass = pass + 1 else fail = fail + 1; print('FAIL ' .. msg) end
end

-- Independent inverse of Harden.seal, mirroring exactly what webbundle.lua
-- emits. If this diverges from the emitted decoder, the differential/bundle
-- tests catch it; here it pins the build-time chain to its own inverse.
local function unseal(sealed, cp)
  local c = sealed:sub(5)
  -- GraniteSum checksum (mirrors harden.lua / the emitted decoder)
  local a, b = 19088743, 1985229328
  for i = 1, #c do
    a = (a * 178711 + c:byte(i) + 1) % 4294967296
    b = (b + a) % 4294967296
  end
  local h = (a + Harden.gmul(b, 40503)) % 4294967296
  local want = sealed:byte(1) * 16777216 + sealed:byte(2) * 65536
    + sealed:byte(3) * 256 + sealed:byte(4)
  if h ~= want then error('cipher: integrity check failed') end
  local n = #c
  local t = {}
  for i = 1, n do t[i] = c:byte(i) end
  -- inverse stream mask (cipher-feedback)
  local mr = Harden.prng(cp.maskSeed)
  local prev = cp.iv
  for i = 1, n do
    local k = mr.byte()
    local cur = t[i]
    t[i] = Bit.bxor(Bit.bxor(cur, k), prev)
    prev = cur
  end
  -- inverse S-box
  local sb = Harden.sbox(cp.sboxSeed)
  local inv = {}
  for i = 0, 255 do inv[sb[i]] = i end
  for i = 1, n do t[i] = inv[t[i]] end
  -- inverse permutation
  local ps = Harden.permSwaps(cp.permSeed, n)
  for i = 2, n do t[i], t[ps[i]] = t[ps[i]], t[i] end
  local bb = {}
  for i = 1, n do bb[i] = string.char(t[i]) end
  return table.concat(bb)
end

-- 1. round-trip over a range of sizes / byte distributions
do
  local samples = {
    '',
    'x',
    'FVM\1\0\0\0hello world 0123456789',
    string.rep('\255\0\128\1\127', 400),
  }
  for _, plain in ipairs(samples) do
    local sealed, cp = Harden.seal(plain, Harden.prng(4242))
    ok(unseal(sealed, cp) == plain, 'round-trip preserves bytes (len ' .. #plain .. ')')
    if #plain > 0 then
      ok(sealed:sub(5) ~= plain, 'ciphertext differs from plaintext (len ' .. #plain .. ')')
    end
  end
end

-- 2. every byte value survives the S-box + inverse (avalanche/coverage)
do
  local plain = {}
  for i = 0, 255 do plain[i + 1] = string.char(i) end
  plain = table.concat(plain)
  local sealed, cp = Harden.seal(plain, Harden.prng(7))
  ok(unseal(sealed, cp) == plain, 'all 256 byte values round-trip')
end

-- 3. deterministic per seed, varies per seed
do
  local a = Harden.seal('bytecode blob', Harden.prng(100))
  local b = Harden.seal('bytecode blob', Harden.prng(100))
  local c = Harden.seal('bytecode blob', Harden.prng(101))
  ok(a == b, 'same seed -> identical sealed output')
  ok(a ~= c, 'different seed -> different sealed output')
end

-- 4. S-box is a bijection with a well-defined inverse
do
  local sb = Harden.sbox(31337)
  local seen, bijective = {}, true
  for i = 0, 255 do
    local v = sb[i]
    if type(v) ~= 'number' or v < 0 or v > 255 or seen[v] then bijective = false end
    seen[v] = true
  end
  ok(bijective, 'S-box is a bijection over 0..255')
end

-- 5. integrity checksum detects tampering with any stage of the ciphertext
do
  local sealed, cp = Harden.seal('some serialized bytecode goes here', Harden.prng(9))
  local i = 7
  local tampered = sealed:sub(1, i - 1)
    .. string.char((sealed:byte(i) + 1) % 256) .. sealed:sub(i + 1)
  ok(not pcall(unseal, tampered, cp), 'tampered ciphertext fails the integrity check')
  local hdr = sealed:sub(1, 1)
  local badhdr = string.char((hdr:byte(1) + 1) % 256) .. sealed:sub(2)
  ok(not pcall(unseal, badhdr, cp), 'tampered checksum header fails the integrity check')
end

print(string.format('cipher: %d passed, %d failed', pass, fail))
os.exit(fail == 0 and 0 or 1)
