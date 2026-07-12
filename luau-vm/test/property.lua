-- luau-vm/test/property.lua
-- Property-based differential tests: parametric programs run with many random
-- inputs, checking the VM matches native for every input. Complements the
-- fuzzer (which varies program structure) by varying data through fixed
-- structures that exercise specific invariants.
local here = (arg and arg[0] and arg[0]:match('^(.*)/test/')) or '.'
package.path = here .. '/src/?.lua;' .. package.path

local API = require('api')

local hasLoadEnv = _VERSION ~= 'Luau' and load ~= nil
local compileRef = load or loadstring

local function collect(out)
  return function(...)
    local p = {}
    for i = 1, select('#', ...) do p[i] = tostring((select(i, ...))) end
    out[#out + 1] = table.concat(p, '\t')
  end
end
local function runNative(src)
  local out = {}
  if hasLoadEnv then
    local env = setmetatable({ print = collect(out) }, { __index = _G })
    local fn = load(src, 'n', 't', env); if fn then pcall(fn) end
  else
    local old = print; _G.print = collect(out)
    local fn = compileRef(src); if fn then pcall(fn) end; _G.print = old
  end
  return table.concat(out, '\n')
end
local function runVM(src)
  local out = {}
  local proto = API.compile(src)
  if hasLoadEnv then
    local env = setmetatable({ print = collect(out) }, { __index = _G })
    pcall(API.VM.load(proto, env))
  else
    local old = print; _G.print = collect(out)
    pcall(API.VM.load(proto, _G)); _G.print = old
  end
  return table.concat(out, '\n')
end

-- Each property is a function(a, b, c) -> Luau source, checked over random inputs.
local PROPERTIES = {
  ['closure-counter'] = function(a) return ([[
    local function mk() local n=%d return function() n=n+1 return n end end
    local f=mk() local s=0 for _=1,%d do s=s+f() end print(s)]]):format(a, 3 + a % 7)
  end,
  ['recursion=iteration'] = function(a) local n = 1 + a % 12; return ([[
    local function sr(k) if k==0 then return 0 end return k+sr(k-1) end
    local it=0 for i=1,%d do it=it+i end print(sr(%d), it)]]):format(n, n)
  end,
  ['vararg-sum'] = function(a, b, c) return ([[
    local function sum(...) local t=0 for _,v in ipairs({...}) do t=t+v end return t end
    print(sum(%d,%d,%d), (%d+%d+%d))]]):format(a, b, c, a, b, c)
  end,
  ['table-roundtrip'] = function(a) local n = 1 + a % 8; return ([[
    local t={} for i=1,%d do t[i]=i*i end local s=0 for _,v in ipairs(t) do s=s+v end
    print(#t, s)]]):format(n)
  end,
  ['multi-return'] = function(a, b) return ([[
    local function mm() return %d, %d, %d+%d end local x,y,z=mm() print(x,y,z,mm())
  ]]):format(a, b, a, b)
  end,
  ['nested-upvalue'] = function(a, b) return ([[
    local function outer(x) local function inner(y) return x*y-%d end return inner end
    print(outer(%d)(%d))]]):format(a % 5, a, b)
  end,
  ['and-or'] = function(a, b) return ([[
    local x=%d local y=%d print(x>0 and y or -y, x<0 or y*2, (x==y) and "eq" or "ne")
  ]]):format(a - 10, b - 10)
  end,
}

local function rng(seed)
  local s = (math.abs(seed) % 2147483646) + 1
  return function(n) s = (s * 16807) % 2147483647; return s % n end
end

local iterations = tonumber(arg and arg[1]) or 300
local r = rng(12345)
local pass, fail = 0, 0
local failures = {}

for name, gen in pairs(PROPERTIES) do
  for _ = 1, iterations do
    local a, b, c = r(100), r(100), r(100)
    local src = gen(a, b, c)
    local nat, vm = runNative(src), runVM(src)
    if nat == vm then pass = pass + 1
    else fail = fail + 1; failures[#failures + 1] = { name, a, b, c, nat, vm } end
  end
end

print(string.format('property: %d passed, %d failed  (%d props x %d inputs)',
  pass, fail, 0, iterations))
for i = 1, math.min(5, #failures) do
  local f = failures[i]
  print(('FAIL %s(%d,%d,%d)  native=[%s] vm=[%s]'):format(f[1], f[2], f[3], f[4], f[5], f[6]))
end
if os and os.exit then os.exit(fail == 0 and 0 or 1) end
