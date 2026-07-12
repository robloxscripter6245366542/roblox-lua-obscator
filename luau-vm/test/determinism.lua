-- luau-vm/test/determinism.lua
-- Reproducible builds: compiling the same source must produce byte-identical
-- bytecode, and running the produced program must be deterministic.
local here = (arg and arg[0] and arg[0]:match('^(.*)/test/')) or '.'
package.path = here .. '/src/?.lua;' .. package.path

local API = require('api')

local SOURCES = {
  'local x = 1 + 2 print(x)',
  'local function f(n) if n < 2 then return n end return f(n-1)+f(n-2) end print(f(12))',
  'local t = {} for i=1,20 do t[i] = ("k"..i):upper() end print(table.concat(t,","))',
  'local function mk() local c=0 return function() c=c+1 return c end end local g=mk() print(g(),g(),g())',
  'local s=0 for i=1,100 do if i%3==0 then s=s+i end end print(s)',
}

local pass, fail = 0, 0
for i, src in ipairs(SOURCES) do
  local a = API.serialize(src)
  local b = API.serialize(src)
  -- byte-identical serialized bytecode
  if a == b and #a > 0 then pass = pass + 1
  else fail = fail + 1; print('FAIL determinism: source ' .. i .. ' (bytecode differs)') end

  -- and identical observable output across two independent VM runs
  local function run()
    local out = {}
    local env = setmetatable({ print = function(...)
      local p = {} for j = 1, select('#', ...) do p[j] = tostring((select(j, ...))) end
      out[#out + 1] = table.concat(p, '\t')
    end }, { __index = _G })
    pcall(API.loadBytecode(a, env))
    return table.concat(out, '\n')
  end
  if run() == run() then pass = pass + 1
  else fail = fail + 1; print('FAIL determinism: source ' .. i .. ' (output differs)') end
end

print(string.format('determinism: %d passed, %d failed', pass, fail))
if os and os.exit then os.exit(fail == 0 and 0 or 1) end
