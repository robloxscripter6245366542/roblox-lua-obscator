-- luau-vm/bench/bench.lua
-- Benchmarks: compile/serialize/execute timing, optimized vs unoptimized
-- bytecode size and instruction count, and interpreter throughput.
local here = (arg and arg[0] and arg[0]:match('^(.*)/bench/')) or '.'
package.path = here .. '/src/?.lua;' .. package.path

local API = require('api')
local Profiler = require('profiler')

local WORKLOADS = {
  ['loop-sum'] = 'local s=0 for i=1,10000 do s=s+i*2-1 end return s',
  ['fib'] = 'local function fib(n) if n<2 then return n end return fib(n-1)+fib(n-2) end return fib(22)',
  ['table-build'] = 'local t={} for i=1,5000 do t[i]={id=i, sq=i*i} end local s=0 for _,v in ipairs(t) do s=s+v.sq end return s',
  ['string-work'] = 'local parts={} for i=1,2000 do parts[i]=("item"..i):upper() end return #table.concat(parts,",")',
}

local function timeIt(fn)
  local t0 = os.clock()
  local v = fn()
  return v, os.clock() - t0
end

print(('%-14s %10s %10s %10s %10s %10s %10s'):format(
  'workload', 'instrs', 'unopt.B', 'opt.B', 'compile.ms', 'exec.ms', 'runs/s'))
print(('-'):rep(84))

for name, src in pairs(WORKLOADS) do
  local protoOpt = API.compile(src, name, { optimize = true })
  local protoRaw = API.compile(src, name, { optimize = false })
  local _, tCompile = timeIt(function() return API.compile(src, name, { optimize = true }) end)
  local bytesOpt = API.Serializer.serialize(protoOpt)
  local bytesRaw = API.Serializer.serialize(protoRaw)

  local fn = API.VM.load(protoOpt, _G)
  local _, tExec = timeIt(fn)
  local tp = Profiler.throughput(fn, 50)

  print(('%-14s %10d %10d %10d %10.2f %10.3f %10.0f'):format(
    name,
    Profiler.instructionCount(protoOpt),
    #bytesRaw, #bytesOpt,
    tCompile * 1000, tExec * 1000, tp.perSecond))
end

-- opcode histogram for the fib workload
print('\nopcode histogram (fib):')
local rows = Profiler.report(API.compile(WORKLOADS['fib'], 'fib'))
for i = 1, math.min(10, #rows) do
  print(('  %-10s %5d  %5.1f%%'):format(rows[i].mnemonic, rows[i].count, rows[i].pct))
end
