-- luau-vm/test/genfor_test.lua
-- Luau generalized iteration: `for vars in exp do` where exp is a bare table or
-- an object with an __iter metamethod (no pairs/ipairs). Plain Lua 5.4 has no
-- such form, so the reference is the expected Luau result, checked through the
-- VM directly and via serialize->deserialize. Classic pairs/ipairs/custom
-- iterators must keep working unchanged.

package.path = 'src/?.lua;' .. package.path
local API = require('api')
local VM = require('vm')
local Ser = require('serializer')

local pass, fail = 0, 0
local function ok(c, m) if c then pass = pass + 1 else fail = fail + 1; print('FAIL ' .. m) end end

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

local cases = {
  -- generalized iteration over a hash table (order-independent: sum values)
  { 'local t={a=1,b=2,c=3} local n=0 for k,v in t do n=n+v end print(n)', '6' },
  -- generalized iteration over an array table
  { 'local t={10,20,30,40} local s=0 for i,v in t do s=s+i*v end print(s)', '300' },
  -- key set from generalized iteration (sorted for determinism)
  { 'local t={x=1,y=1,z=1} local ks={} for k in t do ks[#ks+1]=k end table.sort(ks) print(table.concat(ks,","))', 'x,y,z' },
  -- __iter metamethod is honored
  { 'local o=setmetatable({},{__iter=function() local i=0 return function() i=i+1 if i<=3 then return i,i*i end end end})' ..
    ' local s=0 for a,b in o do s=s+b end print(s)', '14' },
  -- classic iterators still work unchanged
  { 'local t={p=5} for k,v in pairs(t) do print(k,v) end', 'p\t5' },
  { 'local t={7,8,9} local s=0 for i,v in ipairs(t) do s=s+v end print(s)', '24' },
  { 'local s=0 for w in string.gmatch("a b c","%a") do s=s+1 end print(s)', '3' },
  -- nested generalized iteration
  { 'local m={{1,2},{3,4}} local s=0 for _,row in m do for _,x in row do s=s+x end end print(s)', '10' },
}

for i, c in ipairs(cases) do
  local r1 = runVM(c[1], false)
  local r2 = runVM(c[1], true)
  ok(r1 == c[2], 'genfor #' .. i .. ' direct: got ' .. tostring(r1) .. ' want ' .. c[2])
  ok(r2 == c[2], 'genfor #' .. i .. ' serialized: got ' .. tostring(r2) .. ' want ' .. c[2])
end

print(string.format('genfor_test: %d passed, %d failed', pass, fail))
os.exit(fail == 0 and 0 or 1)
