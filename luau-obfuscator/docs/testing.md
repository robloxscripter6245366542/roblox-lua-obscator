# Testing & validation

Correctness is defined as **observable behavior equivalence**, verified by
executing programs — not by textual comparison (the generator is intentionally
not idempotent).

## Layers

1. **Unit tests** (`test/unit/*.test.ts`, Vitest)
   - `parser.test.ts` — the generator's output always re-parses; literal forms
     preserved; invalid syntax raises diagnostics.
   - `rename.test.ts` — locals renamed, globals/fields/methods/`self` preserved,
     shadowing kept distinct, recursion consistent, deterministic per seed.
   - `encoding.test.ts` — PRNG/keystream determinism and double-safety, XOR
     involution, base64, config validation.
   - `equivalence.test.ts` — 10 representative programs × 4 pass profiles, each
     executed original-vs-obfuscated on `lua5.4` (skipped if no interpreter).

2. **Corpus regression** (`scripts/corpus.ts`)
   - Runs the LuaCrypt suite: obfuscate every file, execute original vs output,
     diff normalized output. `npm run corpus -- /path/to/Lua-crypt`.

3. **Real-Luau validation**
   - Point `LUA_BIN` at a Luau interpreter to validate against actual Luau
     semantics: `LUA_BIN=./luau npm run corpus -- /path/to/Lua-crypt --only rename,encodeNumbers,encodeStrings`.

## Normalization

Tracebacks embed chunk paths and line numbers, which legitimately change under
obfuscation. `validator.normalizeOutput` collapses `[string "…"]` / `*.lua`
chunk names, `:<n>` line numbers, and `(...tail calls...)` frames, so the
comparison measures behavior, not filenames.

## Expected, non-bug differences

- **Non-deterministic programs** (hash order, `os.time`, table addresses) are
  detected (two original runs disagree) and reported as `skip`.
- **`debug.getlocal` / `getupvalue` / `traceback`** read local *names* and
  closure structure; renaming and string encoding change what they observe. A
  program that prints those values will differ — this is correct obfuscator
  behavior, not a defect.
- **Luau-only unsupported syntax** in a source file (`goto`, `&|~` bitwise) makes
  the *original* fail under Luau too; the obfuscated output fails identically.

## CI

`.github/workflows/ci.yml` runs typecheck, lint, build, tests, coverage, and a
benchmark smoke test on every change, with `lua5.4` installed so the equivalence
suite executes.
