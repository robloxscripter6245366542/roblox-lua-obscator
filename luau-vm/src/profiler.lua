-- luau-vm/src/profiler.lua
-- Static analysis + throughput measurement for compiled protos.

local Opcodes = require('opcodes')

local Profiler = {}

-- Opcode frequency histogram across a proto tree (static).
function Profiler.histogram(proto, acc)
  acc = acc or {}
  for _, ins in ipairs(proto.code) do acc[ins.op] = (acc[ins.op] or 0) + 1 end
  for _, child in ipairs(proto.protos) do Profiler.histogram(child, acc) end
  return acc
end

-- Total instruction count across the tree.
function Profiler.instructionCount(proto)
  local n = #proto.code
  for _, child in ipairs(proto.protos) do n = n + Profiler.instructionCount(child) end
  return n
end

-- Number of nested protos (functions).
function Profiler.protoCount(proto)
  local n = 1
  for _, child in ipairs(proto.protos) do n = n + Profiler.protoCount(child) end
  return n
end

-- Sorted [{mnemonic, count, pct}] most-frequent first.
function Profiler.report(proto)
  local h = Profiler.histogram(proto)
  local total = 0
  for _, c in pairs(h) do total = total + c end
  local rows = {}
  for op, c in pairs(h) do
    rows[#rows + 1] = { mnemonic = Opcodes.mnemonic(op), count = c, pct = 100 * c / total }
  end
  table.sort(rows, function(a, b) return a.count > b.count end)
  return rows, total
end

-- Dynamic opcode histogram: run `fn` with the VM's profiler hook enabled and
-- return {mnemonic->count} of opcodes actually executed, plus the total.
function Profiler.dynamic(VM, fn)
  local counters = {}
  VM.setProfile(counters)
  local ok, err = pcall(fn)
  VM.setProfile(nil)
  if not ok then error(err) end
  local named, total = {}, 0
  for op, c in pairs(counters) do named[Opcodes.mnemonic(op)] = c; total = total + c end
  return named, total
end

-- Measure wall-clock throughput of a callable over `iterations` runs.
function Profiler.throughput(fn, iterations)
  iterations = iterations or 1000
  local t0 = os.clock()
  for _ = 1, iterations do fn() end
  local dt = os.clock() - t0
  return { iterations = iterations, seconds = dt, perSecond = dt > 0 and iterations / dt or 0 }
end

return Profiler
