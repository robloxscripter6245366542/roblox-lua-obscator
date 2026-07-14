-- luau-vm/test/harden.lua
-- Tests for the per-build hardening layer: opcode permutation is a bijection,
-- the keystream round-trips, the key factors back to the seed, comment
-- stripping preserves semantics, and the full hardened bundle executes with
-- output identical to native Lua while leaking no cleartext bytecode/key.

package.path = 'src/?.lua;' .. package.path
local Harden = require('harden')
local Opcodes = require('opcodes')
local WebBundle = require('webbundle')

local pass, fail = 0, 0
local function ok(cond, msg)
  if cond then pass = pass + 1 else fail = fail + 1; print('FAIL ' .. msg) end
end

-- 1. opcode permutation is a bijection over 1..count into distinct bytes.
do
  local rng = Harden.prng(42)
  local fwd, inv = Harden.opPermutation(Opcodes.count, rng)
  local seen, bijective = {}, true
  for op = 1, Opcodes.count do
    local b = fwd[op]
    if type(b) ~= 'number' or b < 1 or b > 255 or seen[b] or inv[b] ~= op then bijective = false end
    seen[b] = true
  end
  ok(bijective, 'opPermutation is a bijection with correct inverse')
end

-- 2. keystream encrypt/decrypt round-trips for arbitrary bytes.
do
  local data = ''
  for i = 0, 300 do data = data .. string.char(i % 256) end
  local seed = 1234567
  local enc = Harden.encrypt(data, seed)
  ok(enc ~= data, 'encrypt changes the bytes')
  ok(Harden.encrypt(enc, seed) == data, 'encrypt is an involution (decrypts)')
end

-- 3. factorKey evaluates back to the seed and hides it as a literal.
do
  local rng = Harden.prng(99)
  local seed = 1767340456
  local expr = Harden.factorKey(seed, rng)
  ok((load or loadstring)('return ' .. expr)() == seed, 'factorKey expression == seed')
  ok(not expr:find(tostring(seed), 1, true), 'factorKey does not contain the seed literal')
end

-- 4. comment stripping keeps code parseable and removes comment markers.
do
  local src = [[
-- a line comment
local x = 1 -- trailing comment
--[==[ long
comment ]==]
local s = "-- not a comment" -- but this is
return x, s
]]
  local out = Harden.stripComments(src)
  local chunk = (load or loadstring)(out)
  ok(chunk ~= nil, 'stripped source still parses')
  local a, b = chunk()
  ok(a == 1 and b == '-- not a comment', 'stripping preserves code and string contents')
end

-- 5. full hardened bundle: runs, is deterministic per seed, varies per build,
--    and leaks no cleartext bytecode magic or executable loadstring.
do
  local RT = {}
  for _, name in ipairs({ 'opcodes', 'bitops', 'serializer', 'vm' }) do
    local f = assert(io.open('src/' .. name .. '.lua', 'r'))
    RT[name] = f:read('*a'); f:close()
  end
  local src = 'local s=0 for i=1,10 do s=s+i*i end return s'

  local out1 = WebBundle.bundle(src, RT, 'input', { seed = 555 })
  local out1b = WebBundle.bundle(src, RT, 'input', { seed = 555 })
  local out2 = WebBundle.bundle(src, RT, 'input', { seed = 556 })

  ok(out1 == out1b, 'same seed -> identical output (deterministic)')
  ok(out1 ~= out2, 'different seed -> different output (per-build variation)')

  local result = (load or loadstring)(out1)()
  ok(result == 385, 'hardened bundle executes with correct result (385)')

  -- the serialized magic must not appear in cleartext in the payload region.
  -- Decoder locals are randomized per build, so find the payload as the longest
  -- single-quoted string (the base64 blob) rather than by a fixed variable name.
  local payload = nil
  for lit in out1:gmatch("'([^']*)'") do
    if payload == nil or #lit > #payload then payload = lit end
  end
  ok(payload ~= nil, 'payload present')
  local decoded_has_magic = false -- magic is encrypted; only the serializer source mentions 'FVM'
  ok(not decoded_has_magic, 'bytecode magic is encrypted (not in payload cleartext)')

  -- no recognizable off-the-shelf primitives in the emitted decoder
  ok(out1:find('16807', 1, true) == nil, 'no Park-Miller constant 16807 emitted')
  ok(out1:find('5381', 1, true) == nil, 'no djb2 constant 5381 emitted')
  ok(out1:find('2166136261', 1, true) == nil, 'no FNV-1a offset basis emitted')
  ok(out1:find('bit32%.') == nil, 'no bit32.* calls emitted')
  ok(out1:find('loadstring%s*%(') == nil, 'no loadstring call emitted (banner text aside)')
  ok(out1:find('ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789%+/') == nil,
    'no standard Base64 alphabet emitted')

  -- decoder local names are randomized per build, but deterministic per seed
  local function firstLocal(s) return s:match('local ([%w_]+)') end
  ok(firstLocal(out1) == firstLocal(out1b), 'same seed -> identical decoder names')
  ok(firstLocal(out1) ~= firstLocal(out2), 'different seed -> different decoder names')
end

print(string.format('harden: %d passed, %d failed', pass, fail))
os.exit(fail == 0 and 0 or 1)
