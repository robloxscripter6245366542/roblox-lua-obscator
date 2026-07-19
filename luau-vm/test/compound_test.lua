-- luau-vm/test/compound_test.lua
-- Luau compound assignments (`+= -= *= /= //= %= ^= ..=`). Plain Lua 5.4 has no
-- such syntax, so the reference is the expected Luau result, checked through the
-- VM (direct + serialized) and the full hardened bundle.

package.path = 'src/?.lua;' .. package.path
local API = require('api')
local VM = require('vm')
local Ser = require('serializer')

local pass, fail = 0, 0
local function ok(c, m) if c then pass = pass + 1 else fail = fail + 1; print('FAIL ' .. m) end end

-- run a program through the VM, capturing print output as a string
local function runVM(src, serialized)
  local out = {}
  local env = setmetatable({ print = function(...)
    local t = {}; for i = 1, select('#', ...) do t[i] = tostring((select(i, ...))) end
    out[#out + 1] = table.concat(t, '\t')
  end }, { __index = _G })
  local proto = API.compile(src)
  if serialized then proto = Ser.deserialize(Ser.serialize(proto)) end
  VM.load(proto, env)()
  return table.concat(out, '\n')
end

-- { source, expected } — expected is the Luau result
local cases = {
  { 'local x=5 x+=3 print(x)', '8' },
  { 'local x=5 x-=2 print(x)', '3' },
  { 'local x=5 x*=4 print(x)', '20' },
  { 'local x=20 x/=8 print(x)', '2.5' },
  { 'local x=7 x//=2 print(x)', '3' },
  { 'local x=17 x%=5 print(x)', '2' },
  -- `^` yields a float; lua5.4 prints it as 1024.0 (real Luau prints 1024).
  -- This harness runs on lua5.4, so the expected string uses that form.
  { 'local x=2 x^=10 print(x)', '1024.0' },
  { 'local s="hi" s..=" there" print(s)', 'hi there' },
  { 'local t={n=10} t.n+=5 print(t.n)', '15' },
  { 'local a={1,2,3} a[2]+=100 print(a[2])', '102' },
  { 'local n=0 for i=1,10 do n+=i end print(n)', '55' },
  { 'local c=1 c..="x" c..="y" print(c)', '1xy' },
  { 'local m={x=1} function m:add(d) self.x+=d return self.x end print(m:add(4),m:add(6))', '5\t11' },
  { 'local x=100 x-=10 x/=9 x*=3 print(x)', '30.0' },
}

for i, c in ipairs(cases) do
  local ok1 = pcall(function() return runVM(c[1], false) end)
  local r1 = ok1 and runVM(c[1], false) or 'ERR'
  local r2 = ok1 and runVM(c[1], true) or 'ERR'
  ok(r1 == c[2], 'compound #' .. i .. ' direct: got ' .. tostring(r1) .. ' want ' .. c[2])
  ok(r2 == c[2], 'compound #' .. i .. ' serialized: got ' .. tostring(r2) .. ' want ' .. c[2])
end

-- desugaring must not double-parse: `a += b + c` is `a = a + (b + c)`
ok(runVM('local a=1 local b=2 local c=3 a+=b+c print(a)', false) == '6', 'compound precedence: a += b + c')

print(string.format('compound_test: %d passed, %d failed', pass, fail))
os.exit(fail == 0 and 0 or 1)
