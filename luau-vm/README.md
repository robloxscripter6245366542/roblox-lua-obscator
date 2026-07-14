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

Correctness is established by **differential execution** — running each program
natively and through the VM and diffing output — on Lua 5.4 **and a real Luau
VM**, across four layers:

```
test/verify.lua       47/47   curated regression (VM + serialize→deserialize paths)
test/compat.lua      343/343   language-compatibility suite (see below)
test/property.lua   2100/2100  property-based: fixed structures × random inputs
test/fuzz.lua       5000/5000  randomized program generation, seeded/reproducible
test/determinism.lua  10/10    same source ⇒ byte-identical bytecode + stable output
```

`test/compat.lua` runs **343 differential cases** — each executed native, VM, and
VM-serialized — across closures/nested closures, upvalues (shared + per-iteration),
recursion/mutual/deep, metatables (`__index`/`__newindex`/`__call`/`__len`/`__add`/
`__eq`/`__lt`/`__concat`/`__unm`/`__tostring`), `pcall`/`xpcall`, coroutines
(`create`/`resume`/`yield`/`wrap`/`status`), numeric/generic `for`, varargs,
multiple returns, tail calls, `select`, large constant tables, and deep nesting,
plus a **Roblox-API pass-through** section (`Instance.new`, `task.wait`,
`Vector3`) that proves global/field/method lookups forward to the host env
unchanged — the mechanism by which real Roblox APIs work at runtime. It includes
**remotes/signals** (`RemoteEvent:FireServer` + `OnClientEvent:Connect`,
`RemoteFunction.OnServerInvoke` + `:InvokeServer`, `BindableEvent`, multiple
connections, upvalue-capturing handlers), which exercise the host **calling back
into** VM closures — the key requirement for event-driven Roblox code.

The fuzzer found (and drove the fix for) a real register-allocation bug that the
curated tests missed — differential fuzzing is the backbone of correctness here.

### The emitted (hardened) script actually runs on real Luau

The tests above diff native-vs-VM *in one process*. `test/luau_differential.sh`
goes further: it **executes the emitted self-contained bundle on a real Luau
interpreter** and diffs its stdout against the original program (also on Luau).
Compilation runs on lua5.4 (the build step); execution is 100% Luau, so the whole
toolchain — compiler → serializer → interpreter — must agree on the bytecode
format and the runtime must use only Luau-available features.

```
LUAU=/path/to/luau  bash test/luau_differential.sh 200
# luau_differential: 200 matched, 0 differed, 0 bundle-errors (of 200)
```

Measured **200/200** on an mlua-vendored Luau VM, plus a hand-written feature
sweep (metatables `__index`/`__len`, OOP method chaining, closures/upvalues,
varargs/`select`, `bit32`, `pcall`, numeric/generic `for`, string methods).
Luau-compat specifics the emitted loader relies on, all confirmed present:

- **Global environment.** Luau has no `_ENV` (it isn't Lua 5.2), so the loader
  resolves the env as: explicit `_ENV` if a runtime provides one (Lua 5.2+) →
  else `getfenv(1)`, pcall-guarded (Roblox/5.1) → else `_G`. Verified all three
  paths, including with `getfenv` removed (falls through to `_G` and still
  resolves `print`/`math`/`table`). `getfenv` appears only in the one-line
  bootstrap, never in the interpreter loop, so Luau's `getfenv` deopt never
  touches hot code.
- **`bit32`** — native in Luau, but `bitops` deliberately does NOT call it:
  it implements its own 32-bit ops from per-nibble lookup tables (same
  unsigned semantics Luau uses). Confirmed via a `bit32.*` program.
- **`table.pack`/`table.unpack`** — present in Luau; `vm.lua` polyfills them if
  absent. Confirmed via varargs / multiple returns.

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
| `src/bitops.lua` | portable custom bitwise (nibble-table, no bit32) |
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
lua5.4 test/vmcore_test.lua      # hand-assembled VM core checks
lua5.4 test/verify.lua           # native-vs-VM equivalence (VM + serialized)
lua5.4 test/property.lua 300     # property-based differential tests
lua5.4 test/fuzz.lua 5000        # differential fuzzer (seeded, reproducible)
lua5.4 test/determinism.lua      # reproducible-build check
lua5.4 test/harden.lua           # hardening: permutation, encryption, bundle
lua5.4 test/compat.lua           # 338 differential cases across the language surface
lua5.4 test/opcode_coverage.lua  # every emittable opcode, validated + diffed
lua5.4 test/fuzz_bytecode.lua    # malformed-bytecode fuzzer (loader safety)
lua5.4 bench/bench.lua           # timings, sizes, throughput, opcode histogram
```

Bytecode tools:

```sh
lua5.4 tools/disasm.lua input.lua            # human-readable disassembly
lua5.4 tools/disasm.lua bytecode.fvm --bytecode
lua5.4 tools/bundle.lua input.lua [seed]     # hardened self-contained script
```

## Robustness

The container checksum (FNV-1a) catches random corruption, but a *well-formed*
stream can still encode nonsense. [`src/validate.lua`](src/validate.lua) walks a
deserialized proto tree and rejects out-of-range register/constant/proto/upvalue
indices and jump targets that land outside the code, with a precise message
(`Validate.bytecode(bytes)` → `ok, err|proto`). The reader is EOF-safe, so a
truncated stream reports its offset instead of faulting on a `nil`.

`test/fuzz_bytecode.lua` fuzzes the **loader** with malformed bytecode — random
byte flips and checksum-repaired body corruption (so the structural validator,
not the checksum, is the line of defense) — asserting the loader **never crashes
the host** (5000 iterations in CI; accepted-but-corrupt protos are additionally
run under an instruction budget). `test/opcode_coverage.lua` derives its target
set from the compiler itself and asserts a corpus exercises **every** emittable
opcode (50/50), each validated and differential-checked.

Produce a self-contained, hardened protected script:

```sh
lua5.4 tools/bundle.lua input.lua [seed] > out.lua   # runs on Roblox/Luau + Lua 5.1-5.4
```

## Hardening

`tools/bundle.lua` and the website share `src/webbundle.lua`, which wraps a build
with the primitives in [`src/harden.lua`](src/harden.lua):

- **Per-build opcode layout** — the serialized bytecode carries a per-build
  opcode numbering (`Serializer.serialize(proto, opMap)` / `deserialize(bytes,
  invMap)`; `ins.op` stays canonical internally, so the VM and operand layout are
  unchanged). Defeats a devirtualizer keyed to the canonical opcode set.
- **Bytecode compression** — a custom RLE (`Harden.compress`, self-describing
  escape byte, stored fallback) shrinks the serialized blob *before* encryption.
- **Versioned, fingerprinted envelope** — `Harden.envelope` prepends a VM-version
  byte and a build fingerprint (GraniteSum over version+payload). The decoder
  gates on both: a bundle from a mismatched builder or an edited payload fails
  closed instead of running altered bytecode (**VM versioning + anti-tamper**).
- **Multi-round GraniteCipher** — `Harden.seal(plain, rng, rounds)` stacks
  independent cipher layers (default 2), each its own byte permutation → custom
  S-box → cipher-feedback stream mask with per-layer sub-seeds. A ciphertext
  checksum guards the whole blob; the decoder peels the layers in reverse.
- **Custom primitives** — bespoke PRNG, checksum/hash, bitwise ops, and a
  per-build permuted output alphabet (no Park-Miller / DJB2 / FNV-1a / bit32 /
  standard Base64). Sub-seeds are emitted as `(m*q+r)`, not literals.
- **Randomized decoder + junk** — every decoder local is renamed per build and
  inert dead-code statements are interleaved. A best-effort `debug.gethook`
  probe aborts under an active hook (weak by nature — the decoder runs client-side).
- **Comment-stripped runtime** — the bundled interpreter ships without its
  documentation comments (guarded by a re-parse; falls back if stripping fails).
- **Instruction mutation** — each opcode gets several interchangeable byte
  encodings (`harden.opMutationMap`; the serializer picks one per instruction),
  so one opcode appears as different bytes — no byte→opcode frequency map.

### Sealed / streamed execution (`src/seal.lua`)

After the GraniteCipher payload is decoded to proto tables, the *in-memory*
bytecode is sealed: each proto's instruction array becomes per-instruction
encrypted slices and the plaintext `code` table is dropped; the dispatch loop
decodes **one instruction at a time, immediately before it runs**. This gives
**JIT/on-demand decoding + streamed execution** (the whole plaintext stream is
never resident — only the current instruction, a short-lived local the GC
reclaims: best-effort memory scrubbing), an **ephemeral session key** derived at
runtime per execution (so the in-memory encrypted form differs every run), and a
**compact representation** (opaque bytes, not a `{op=,a=,b=}` mirror). Trade-off:
sealed execution re-decodes each instruction every time it runs, so it is slower
than the plain interpreter — the security/speed exchange of streaming.

Same seed → identical output (reproducible); different seed → different opcodes,
aliases, keys, names, and junk. This raises the cost of a *generic* devirtualizer
and a static memory dump, and defeats casual copy-paste. It is **not** cryptography and **not** unbreakable:
any self-contained client-side scheme must carry its decryptor and keys, and the
interpreter is present (it holds none of the user's logic — that lives only in
the encrypted bytecode). Deeper resistance (polymorphic handlers, VM-in-VM) is
future work.

## Performance

Register-based with a **frequency-ordered dispatch** loop and static + dynamic
(`Profiler.dynamic`) profiling. Reordering dispatch hottest-first measured a
**1.5× speedup** on a recursion+loop workload with identical behavior — see
[docs/perf.md](docs/perf.md) for the quantitative dispatch study and the
optimization roadmap (superinstructions, call-buffer reuse, register windows).

## Specification

The bytecode container and instruction encoding are a **versioned spec**
([docs/spec.md](docs/spec.md)): `FVM` magic + version byte + FNV-1a checksum,
varint operands, `%.17g` number round-tripping, and a single operand-layout
table shared by encoder and decoder. Compilation is deterministic → reproducible
builds.

## Scope & limits

- **Supported:** the executable Luau grammar (see the verified list). `goto`/labels
  are rejected with a clear diagnostic (Luau has no `goto`).
- **Bitwise:** `&|~<<>>` operators are Lua 5.3/5.4 syntax; Luau code uses `bit32.*`
  (ordinary calls the VM already runs). The VM's own bitwise is a custom
  nibble-table implementation (no `bit32` dependency) — 32-bit semantics.
- **Tail calls:** `TAILCALL` is result-preserving but does not eliminate host
  stack frames (documented; deep non-recursive tail loops are bounded by host
  stack).
- **Runtime edge case:** a table constructor with a *conflicting* positional and
  keyed index (`{20, [2]=9}`) resolves differently on Lua 5.4 vs Luau; the VM
  matches Lua 5.4. Real code doesn't rely on this.

See [docs/devguide.md](docs/devguide.md) to add opcodes, optimization passes, or
runtime features.
