# Developer guide

How to extend the VM. Each change is local and validated the same way: add a case
to `test/cases.lua` and run `lua5.4 test/verify.lua` (and a Luau build).

## Add an opcode

1. **Declare it** in `src/opcodes.lua` with `def('MYOP')`, and add its operand
   layout to the `operands` table (which fields it uses). The serializer picks it
   up automatically.
2. **Implement it** in `src/vm.lua` inside the dispatch chain:
   `elseif op == Op.MYOP then …`.
3. **Emit it** from `src/compiler.lua` where appropriate.
4. Add a regression case and run `test/verify.lua`.

## Add a superinstruction

Superinstructions fuse a hot pair to cut dispatch. Example: `GETGLOBAL`+`CALL`.

1. Add `GCALL` in `opcodes.lua` with operands `{a, bx, b, c}`.
2. Implement it in `vm.lua` (inline the global fetch then the call).
3. Add a bytecode peephole rule in `optimizer.lua`: when a `GETGLOBAL a,bx` is
   immediately followed by `CALL a,…`, replace the pair with `GCALL`. Reuse the
   existing jump-retargeting (fusing shifts indices exactly like removal does).
4. Verify output is unchanged and measure with `bench/bench.lua`.

## Add an optimization pass

AST passes live in `src/optimizer.lua` (`optimizeAST`); bytecode passes run after
compilation (`peephole`). Rules:

- **Semantics-preserving AND runtime-neutral.** Only transform when the result is
  identical on both Lua 5.4 and Luau. Numeric folding is restricted to integer
  `+`/`-`/`*` and literal concat for exactly this reason (`/` and `^` differ in
  typing/printing across runtimes).
- Bytecode passes that change instruction indices must recompute jump `sbx` via
  the absolute-target remap already used by `peephole`.

## Add a runtime feature (e.g. a builtin)

The VM runs against an `env` table (the globals). To expose a builtin, put it in
the env you pass to `VM.load(proto, env)` — it is reachable via `GETGLOBAL` and
callable via `CALL` with no VM changes. Metatable behavior needs nothing special:
operators and indexing use host semantics.

## Testing & CI

- `test/vmcore_test.lua` — hand-assembled bytecode exercising the interpreter
  directly (no compiler), so VM bugs are isolated from compiler bugs.
- `test/verify.lua` — the equivalence oracle: runs each program natively and via
  the VM (both direct and serialize→deserialize) and diffs output. Portable to
  Lua 5.4 and Luau. Cases the reference runtime can't compile (e.g. 5.4 bitwise
  under Luau) are skipped.
- `bench/bench.lua` — timings, bytecode sizes (opt vs unopt), throughput, and an
  opcode histogram.

CI (`.github/workflows/ci.yml`) installs `lua5.4` and runs the core + verify
suites and a benchmark smoke test on every change.
