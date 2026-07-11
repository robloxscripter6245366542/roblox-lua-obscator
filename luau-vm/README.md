# ferret-vm — a custom bytecode VM for Luau, in pure Luau

A complete **compiler + virtual machine** that executes its own custom bytecode
entirely in pure Luau — **no `loadstring`, no native bytecode, no external
executables**. Luau source is compiled to a private register-based instruction
set, optionally serialized to a versioned binary blob, and interpreted by a
hand-written VM that preserves Luau semantics.

Built as the strongest protection layer for the ferret obfuscator: unlike
encrypt-then-`loadstring`, the original program never exists in a runnable form
in the output — only the custom VM knows how to run the bytecode.

## Verified

Every feature is checked by executing the program **natively** and **through the
VM** and diffing output — on Lua 5.4 **and a real Luau VM**:

```
lua5.4 test/verify.lua     ->  47 passed, 0 failed        (VM + serialized paths)
luau   test/verify.lua     ->  46 passed, 0 failed, 1 skipped  (bitwise: not Luau syntax)
```

Covers closures, upvalues (shared + per-iteration capture), recursion, deep
recursion, varargs, multiple returns, tables/constructors, metatables
(`__index`/`__newindex`/`__add`/`__call`/`__eq`/`__lt`), method calls,
numeric/generic `for`, `while`/`repeat`, `and`/`or` short-circuit, `pcall`,
**coroutines** (`wrap`/`create`/`resume`/`yield`), `table.sort` with a closure
comparator, and string methods.

## Pipeline

```
source ─▶ lexer ─▶ parser ─▶ AST ─▶ scope (capture) ─▶ optimizer(AST)
      ─▶ compiler ─▶ bytecode proto ─▶ optimizer(peephole)
      ─▶ serializer ─▶ [binary blob] ─▶ loader ─▶ VM interpreter ─▶ result
```

| Module | Role |
|--------|------|
| `src/lexer.lua` | tokenizer |
| `src/parser.lua` | recursive-descent parser → AST |
| `src/scope.lua` | capture analysis (which locals become cells) |
| `src/optimizer.lua` | runtime-safe constant folding, DCE, bytecode peephole |
| `src/compiler.lua` | AST → register bytecode (allocation, upvalues, multi-values) |
| `src/opcodes.lua` | instruction set + operand layouts |
| `src/vm.lua` | register interpreter |
| `src/bitops.lua` | portable bitwise (bit32 or arithmetic) |
| `src/serializer.lua` | compact versioned binary format + checksum + loader |
| `src/profiler.lua` | opcode histogram, instruction counts, throughput |
| `src/api.lua` | `compile` / `load` / `serialize` / `loadBytecode` |

## Architecture: register-based

The VM is **register-based** (like Luau natively), not stack-based. In a VM whose
interpreter loop is itself interpreted Luau, dispatch dominates cost, so the win
is executing *fewer* instructions — a register machine emits ~2–3× fewer than a
stack machine. Tradeoffs (register allocation, closing upvalues) are handled by:

- a simple bump allocator (locals low, temporaries above `freereg`),
- **cell-boxed captured locals**: variables closed over become `{v=…}` boxes, so
  closures share them as upvalues with no open/closed-upvalue machinery.

Every closure is compiled to a **real Lua function** wrapping the interpreter, so
VM and host functions are called identically — which is why metatables, `pcall`,
coroutines, and `table.sort(cmp)` all work: a compiled function is an ordinary
callable, and operators/table access use the host's native semantics (honoring
metamethods). See [docs/architecture.md](docs/architecture.md).

## Instruction set

~60 register opcodes across data movement, globals, cells/upvalues, tables,
arithmetic/bitwise/concat, comparison, control flow, calls, closures, varargs,
and loop iteration. Multi-value calls/returns/varargs use a Lua-style count
convention (`0` = "to top"). Full listing with operands and semantics in
[docs/opcodes.md](docs/opcodes.md).

## Usage

```lua
package.path = 'src/?.lua;' .. package.path
local API = require('api')

-- compile + run directly
local fn = API.load('local x = 21 print(x * 2)', _G)
fn()  --> 42

-- compile to a portable binary blob, then load it (no loadstring anywhere)
local bytes = API.serialize('return 1 + 2')
local f = API.loadBytecode(bytes, _G)
print(f())  --> 3
```

## Tooling

```sh
lua5.4 test/vmcore_test.lua   # hand-assembled VM core checks
lua5.4 test/verify.lua        # native-vs-VM equivalence (VM + serialized)
lua5.4 bench/bench.lua        # timings, sizes, throughput, opcode histogram
```

## Scope & limits

- **Supported:** the executable Luau grammar (see the verified list). `goto`/labels
  are rejected with a clear diagnostic (Luau has no `goto`).
- **Bitwise:** `&|~<<>>` operators are Lua 5.3/5.4 syntax; Luau code uses `bit32.*`
  (ordinary calls the VM already runs). The VM's own bitwise uses `bit32` when
  present, else arithmetic — 32-bit semantics.
- **Tail calls:** `TAILCALL` is result-preserving but does not eliminate host
  stack frames (documented; deep non-recursive tail loops are bounded by host
  stack).
- **Runtime edge case:** a table constructor with a *conflicting* positional and
  keyed index (`{20, [2]=9}`) resolves differently on Lua 5.4 vs Luau; the VM
  matches Lua 5.4. Real code doesn't rely on this.

See [docs/devguide.md](docs/devguide.md) to add opcodes, optimization passes, or
runtime features.
