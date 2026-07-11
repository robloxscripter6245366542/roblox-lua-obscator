# Architecture

## Pipeline

```
 Luau source
     │  lexer.lua          tokens (name/number/string/keyword/symbol)
     ▼
   tokens
     │  parser.lua         recursive descent + precedence climbing
     ▼
    AST  (tables tagged with `k`)
     │  scope.lua          attach decls; mark `captured`
     ▼
  AST + scope
     │  optimizer.lua      constant folding (runtime-safe), dead-code elim
     ▼
  optimized AST
     │  compiler.lua       register allocation, upvalue resolution, lowering
     ▼
   proto  { code, consts, protos, upvals, numparams, isVararg, maxstack }
     │  optimizer.lua      bytecode peephole (drop NOP / self-MOVE, retarget jumps)
     ▼
 optimized proto
     │  serializer.lua     magic + version + checksum + varint body
     ▼
  binary blob  ──────────▶  serializer.deserialize  ──▶  proto
     │  vm.lua             register interpreter (makeClosure + execute)
     ▼
   result
```

## Register machine vs stack machine

We chose **register-based**. Rationale:

- The interpreter loop is *itself* interpreted Luau, so each dispatched
  instruction costs a full Luau iteration. The dominant cost is the number of
  instructions dispatched, not per-instruction operand handling.
- A register machine emits ~2–3× fewer instructions than a stack machine for the
  same source (no push/pop churn), so it dispatches less and runs faster in this
  hosting model — the same reason Lua/Luau are register VMs.

Costs and how we pay them:

- **Register allocation** — a bump allocator. Locals occupy the low registers of
  a frame; expression temporaries are allocated above `freereg` and freed by
  restoring it. `maxstack` is tracked for the loader.
- **Closing upvalues** — avoided entirely via *cells* (below).

## Closures & upvalues via cells

A variable that is captured by a nested function (detected in `scope.lua`) is
stored in a **cell**: a one-field box `{ v = value }`. The compiler emits
`NEWCELL` at its declaration and accesses it via `GETCELL`/`SETCELL`. A closure
captures the *cell reference* (`CLOSURE` reads upvalue descriptors: `reg` =
capture a parent register holding a cell, `up` = re-capture a parent upvalue).
Inside the closure, `GETUPVAL`/`SETUPVAL` read/write `cell.v`.

This makes upvalue semantics trivially correct — shared mutation between closures
and per-iteration capture in loops both fall out naturally — with none of Lua's
open/closed-upvalue stack bookkeeping.

## Closures are real functions

`makeClosure(proto, upvals, env)` returns an ordinary Lua function that packs its
arguments, calls `execute`, and unpacks the results. Consequences:

- **Uniform calls.** `CALL` just invokes `R[a](args…)` via `table.pack`/`unpack`,
  whether the target is a compiled closure or a host function.
- **Metatables/coroutines/pcall/sort work for free.** A compiled function is a
  normal callable, so `pcall(f)`, `table.sort(t, cmp)`, `coroutine.wrap(f)`, and
  `__call`/`__lt`/… metamethods all operate on it. Because the interpreter is
  pure Lua (no C boundary), `coroutine.yield` from inside interpreted code
  unwinds and resumes the interpreter frames correctly.
- **Native operator semantics.** Arithmetic, comparison, indexing, concat, and
  length use the host's own operators (`R[b] + R[c]`, `R[b][k]`, `#x`, `..`), so
  every metamethod is honored by the host runtime.

## Multi-value convention

Calls, returns, and varargs use a Lua-style count field: a value of `0` means
"to the current frame top" (set by a preceding multi-value producer), otherwise
the field is `count + 1`. The interpreter tracks `top` to thread multiple values
through `f(g())`, `return f()`, `{...}`, and `local a,b = f()`.

## Portability

The VM must *parse and run* under both Lua 5.4 and Luau. Luau lacks the `&|~<<>>`
and `//` operators, so the VM never writes them: bitwise goes through
`bitops.lua` (bit32 or arithmetic) and floor-division uses `math.floor`. The
serializer avoids `string.pack` and encodes numbers as `%.17g` text for exact
double round-tripping.
