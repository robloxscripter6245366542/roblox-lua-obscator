-- luau-vm/test/fuzz.lua
-- Differential fuzzer: generate random, deterministic, terminating Luau programs
-- over the supported subset and check that the VM produces byte-identical output
-- to native execution (both direct and via serialize->deserialize).
--
--   lua5.4 test/fuzz.lua [count] [baseSeed]
--   LUA_BIN=./luau luau test/fuzz.lua 3000
--
-- The generator avoids anything that differs native-vs-VM inherently (table
-- addresses, hash iteration, os/random) and anything non-terminating or
-- error-prone (division/modulo, unbounded loops), so any mismatch is a real bug.
local here = (arg and arg[0] and arg[0]:match('^(.*)/test/')) or '.'
package.path = here .. '/src/?.lua;' .. package.path

local API = require('api')

-- ── deterministic PRNG (Park-Miller) ─────────────────────────────────────────
local function RNG(seed)
  local s = (math.abs(seed) % 2147483646) + 1
  return function(n) -- integer in [1, n]
    s = (s * 16807) % 2147483647
    return 1 + (s % n)
  end
end

-- ── program generator ────────────────────────────────────────────────────────
local function makeGen(rnd)
  local vars = {}       -- integer-valued locals in scope
  local nextVar = 0
  local fns = {}        -- binary integer functions in scope
  local lines = {}
  local budget = 60     -- statement budget to bound size

  local function newVar()
    nextVar = nextVar + 1
    local name = 'v' .. nextVar
    vars[#vars + 1] = name
    return name
  end
  local function anyVar()
    if #vars == 0 then return tostring(rnd(9)) end
    return vars[rnd(#vars)]
  end

  local genExpr
  genExpr = function(depth)
    if depth <= 0 or rnd(3) == 1 then
      if rnd(2) == 1 then return tostring(rnd(20)) else return anyVar() end
    end
    local ops = { '+', '-', '*' }
    local op = ops[rnd(3)]
    return '(' .. genExpr(depth - 1) .. op .. genExpr(depth - 1) .. ')'
  end

  local function genBool()
    local cmp = ({ '<', '<=', '>', '>=', '==', '~=' })[rnd(6)]
    local e = genExpr(2) .. cmp .. genExpr(2)
    if rnd(3) == 1 then e = e .. ' and ' .. genExpr(1) .. '<' .. genExpr(1) end
    if rnd(4) == 1 then e = e .. ' or ' .. genExpr(1) .. '>' .. genExpr(1) end
    return e
  end

  local emit
  local function genBlock(depth, n)
    for _ = 1, n do emit(depth) end
  end

  emit = function(depth)
    if budget <= 0 then return end
    budget = budget - 1
    local choice = rnd(depth > 0 and 7 or 3)
    if choice == 1 then
      -- generate the RHS BEFORE declaring, so it never references the new var
      local rhs = genExpr(2)
      lines[#lines + 1] = 'local ' .. newVar() .. '=' .. rhs
    elseif choice == 2 then
      lines[#lines + 1] = anyVar() .. '=' .. genExpr(3)
    elseif choice == 3 then
      local rhs = genExpr(1)
      lines[#lines + 1] = 'local ' .. newVar() .. '=' .. rhs
    elseif choice == 4 then
      -- block scoping: vars declared inside the branches must not leak out
      lines[#lines + 1] = 'if ' .. genBool() .. ' then'
      local mark = #vars
      genBlock(depth - 1, rnd(2))
      for i = #vars, mark + 1, -1 do vars[i] = nil end
      if rnd(2) == 1 then
        lines[#lines + 1] = 'else'
        genBlock(depth - 1, rnd(2))
        for i = #vars, mark + 1, -1 do vars[i] = nil end
      end
      lines[#lines + 1] = 'end'
    elseif choice == 5 then
      local acc = anyVar()
      local lim = rnd(5)
      lines[#lines + 1] = 'for _i=1,' .. lim .. ' do ' .. acc .. '=' .. acc .. '+_i*' .. rnd(3) .. ' end'
    elseif choice == 6 then
      -- function def + call
      local f = 'f' .. (#fns + 1); fns[#fns + 1] = f
      lines[#lines + 1] = 'local function ' .. f .. '(a,b) return a+b*' .. rnd(5) .. '-' .. rnd(5) .. ' end'
      lines[#lines + 1] = anyVar() .. '=' .. f .. '(' .. genExpr(1) .. ',' .. genExpr(1) .. ')'
    else
      -- closure capturing a counter
      local g = 'g' .. (#fns + 1); fns[#fns + 1] = g
      lines[#lines + 1] = 'local function mk() local c=' .. genExpr(1)
        .. ' return function() c=c+1 return c end end local ' .. g .. '=mk()'
      lines[#lines + 1] = anyVar() .. '=' .. g .. '()+' .. g .. '()'
    end
  end

  return function()
    -- seed a few locals
    for _ = 1, 3 do lines[#lines + 1] = 'local ' .. newVar() .. '=' .. rnd(15) end
    local nstmts = 8 + rnd(20)
    genBlock(3, nstmts)
    -- print everything for a wide observation surface
    local outs = {}
    for _, v in ipairs(vars) do outs[#outs + 1] = v end
    outs[#outs + 1] = '"s"..' .. genExpr(2)
    lines[#lines + 1] = 'print(' .. table.concat(outs, ',') .. ')'
    return table.concat(lines, '\n')
  end
end

-- ── execution (native vs VM) — portable across 5.4 and Luau ──────────────────
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
    local fn = load(src, 'n', 't', env); if not fn then return '<compile>' end
    if not pcall(fn) then return '<error>' end
  else
    local old = print; _G.print = collect(out)
    local fn = compileRef(src)
    local ok = fn and pcall(fn); _G.print = old
    if not ok then return '<error>' end
  end
  return table.concat(out, '\n')
end

local function runVM(src, serialized)
  local out = {}
  local proto
  if not pcall(function() proto = API.compile(src) end) then return '<vm-compile>' end
  if serialized then
    local bytes = API.Serializer.serialize(proto)
    proto = API.Serializer.deserialize(bytes)
  end
  if hasLoadEnv then
    local env = setmetatable({ print = collect(out) }, { __index = _G })
    if not pcall(API.VM.load(proto, env)) then return '<error>' end
  else
    local old = print; _G.print = collect(out)
    local ok = pcall(API.VM.load(proto, _G)); _G.print = old
    if not ok then return '<error>' end
  end
  return table.concat(out, '\n')
end

-- ── driver ───────────────────────────────────────────────────────────────────
local count = tonumber(arg and arg[1]) or 1000
local baseSeed = tonumber(arg and arg[2]) or 1

local pass, fail = 0, 0
local firstFail
for i = 1, count do
  local seed = baseSeed + i
  local rnd = RNG(seed)
  local src = makeGen(rnd)()
  local a = runNative(src)
  local b = runVM(src, false)
  local c = runVM(src, true)
  if a == b and a == c then
    pass = pass + 1
  else
    fail = fail + 1
    if not firstFail then firstFail = { seed = seed, src = src, native = a, vm = b, ser = c } end
  end
end

print(string.format('fuzz: %d programs, %d passed, %d failed  (seeds %d..%d)',
  count, pass, fail, baseSeed + 1, baseSeed + count))
if firstFail then
  print('\nfirst mismatch (seed ' .. firstFail.seed .. '):')
  print('--- source ---\n' .. firstFail.src)
  print('--- native ---\n' .. firstFail.native)
  print('--- vm ---\n' .. firstFail.vm)
  print('--- vm(serialized) ---\n' .. firstFail.ser)
end
if os and os.exit then os.exit(fail == 0 and 0 or 1) end
