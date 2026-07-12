# Performance & dispatch study

## Dispatch: quantitative comparison

The interpreter loop is itself interpreted Luau, so **dispatch cost dominates** —
each executed instruction pays a full pass through the branch selection. Two
strategies were considered.

### A. Linear `if/elseif`, ordered by frequency (chosen)

Each branch is one comparison; the Nth opcode in the chain costs N comparisons.
Ordering the chain **hottest-first** minimizes the expected comparisons per
instruction. The dynamic profiler (`Profiler.dynamic`) shows the actual
execution mix for a recursion+loop workload:

```
LOADINT 3946   RETURN 1974   LT 1973   CALL 1973   JMPIFNOT 1973   GETUPVAL 1972
```

These are precisely the opcodes now at the front of the chain.

### B. Table-of-handlers dispatch (rejected, with reasoning)

`handlers[op](state)` is O(1) selection, but in Lua each instruction becomes a
function call plus shared-state passing (registers/pc/top can't be plain
upvalues without allocating ~50 closures per frame). The call + state overhead
per instruction exceeds the comparison cost saved, and it complicates control
flow (handlers must return pc deltas). For a Lua-hosted VM, ordered `if/elseif`
is the stronger engineering choice; the same reasoning is why other Lua-in-Lua
interpreters use it.

### Measured result

Workload: `fib(24)` + a 300k-iteration accumulation loop, Lua 5.4.

| Dispatch order | Time | Speedup |
|----------------|------|---------|
| definition order (before) | 0.664 s | 1.00× |
| frequency order (after) | 0.443 s | **1.50×** |

Correctness was unchanged (differential suite 47/47, fuzzer 3000/3000) — the
reorder is a pure branch-ordering change.

## Profiling infrastructure

- **Static** (`Profiler.histogram` / `report` / `instructionCount` /
  `protoCount`): opcode mix, instruction and function counts of compiled
  bytecode.
- **Dynamic** (`Profiler.dynamic(VM, fn)`): counts opcodes actually executed via
  the VM's `setProfile` hook (one nil-check per instruction when disabled — see
  `vm.lua`). Returns `{mnemonic -> count}` and the total.
- **Throughput** (`Profiler.throughput`): runs a callable N times and reports
  runs/second.
- `bench/bench.lua` combines these: per-workload instruction counts, optimized
  vs unoptimized bytecode size, compile/exec timing, and an opcode histogram.

## Further gains (roadmap)

Ranked by expected ROID (return on implementation difficulty):

1. **Superinstructions** for hot pairs — `GETGLOBAL`+`CALL` (global calls are the
   single hottest pattern), `LT`/`EQ`+`JMPIFNOT` (compare-and-branch), immediate
   arithmetic (`ADDI`). Cuts dispatch count directly; slots in behind the
   operand-layout table + a peephole rule.
2. **Argument/result reuse** — avoid the per-call `table.pack`/`unpack`
   allocation for fixed-arity calls by writing args directly into a reused
   buffer.
3. **Register-window frames** — reuse a shared register array across calls
   instead of allocating `R = {}` per frame.

Each is gated by the differential fuzzer + property suite before adoption.
