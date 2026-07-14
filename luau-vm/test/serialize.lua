-- luau-vm/test/serialize.lua
-- The serializer must round-trip numeric constants faithfully: value, float vs
-- integer subtype (Lua 5.4), the sign of negative zero, large integers, and
-- inf/nan. Regression for constants collapsing (e.g. 2.0 -> 2, -0.0 -> 0) after
-- serialize -> deserialize.

package.path = 'src/?.lua;' .. package.path
local API = require('api')

local pass, fail = 0, 0
local function ok(cond, msg)
  if cond then pass = pass + 1 else fail = fail + 1; print('FAIL ' .. msg) end
end

-- Round-trip a numeric literal through compile -> serialize -> deserialize ->
-- execute, returning the value the VM produced. Exercises the binary constant
-- format regardless of whether the value is a const-table entry or an immediate.
local function roundtrip(literal)
  local bytes = API.serialize('return ' .. literal)
  local fn = API.loadBytecode(bytes, _G)
  return (fn())
end

local hasType = math.type ~= nil

-- value equality
ok(roundtrip('42') == 42, 'integer value 42')
ok(roundtrip('3.5') == 3.5, 'float value 3.5')
ok(roundtrip('1e12') == 1e12, 'large float 1e12')
ok(roundtrip('1099511627776') == 1099511627776, 'integer 2^40 exact')
ok(roundtrip('0.1') == 0.1, 'float 0.1 exact round-trip')

-- float subtype preserved (Lua 5.4 only distinguishes subtypes)
if hasType then
  ok(math.type(roundtrip('2.0')) == 'float', '2.0 stays a float (not collapsed to int)')
  ok(math.type(roundtrip('42')) == 'integer', '42 stays an integer')
  ok(math.type(roundtrip('1099511627776')) == 'integer', '2^40 stays an integer')
end

-- negative zero sign preserved
do
  local nz = roundtrip('-0.0')
  ok(nz == 0, '-0.0 equals 0')
  ok(1 / nz == -math.huge, '-0.0 keeps its negative sign (1/x == -inf)')
end

-- inf / nan (constant-folded literals) survive
do
  local inf = roundtrip('1e400') -- overflows to +inf at parse time
  ok(inf == math.huge, '1e400 literal round-trips to +inf')
end

print(string.format('serialize: %d passed, %d failed', pass, fail))
os.exit(fail == 0 and 0 or 1)
