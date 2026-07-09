# ferret — pure-Lua obfuscator

A self-contained Lua obfuscator inspired by [LuaCrypt/ferret](https://github.com/LuaCrypt/ferret),
built for this repo so it runs **anywhere Lua/Luau runs** (no Rust toolchain, no
build step). It is validated against LuaCrypt's public test suite
([robloxscripter6245366542/Lua-crypt](https://github.com/robloxscripter6245366542/Lua-crypt),
~260 real programs).

## What it does

ferret takes readable Lua and emits functionally identical but hard-to-read Lua,
through a multi-stage pipeline that mirrors ferret's crate layout:

| ferret (Rust) crate | this port          | job                                             |
|---------------------|--------------------|-------------------------------------------------|
| `parse`             | `lexer.lua`        | tokenize Lua 5.x source                          |
| `ir` / `core`       | `layers.lua`       | semantic-preserving transform passes             |
| `crypto`            | `layers.lua`,`pack.lua` | XOR keystream + base64 encryption of constants & chunk |
| `vm` / `output`     | `pack.lua`,`emit.lua` | emit a standalone runtime that decrypts & loads |
| `cli`               | `cli.lua`          | `obfuscate input.lua -o output.lua`              |

### Design difference from upstream ferret

Upstream ferret compiles Lua into a **custom register-bytecode VM**. Faithfully
re-implementing that VM in pure Lua would mean re-implementing coroutines,
metatables, `debug.*`, weak tables and `__gc` by hand — which cannot pass
LuaCrypt's own test suite. So this port keeps every transform
**semantics-preserving**: the emitted program is still ordinary Lua that the
host runtime executes directly. That is what lets it pass ~99% of the suite
while remaining a single portable file.

## Layers

Applied in a fixed order; select with `--layers`:

1. **`numbers`** — integer literals become arithmetic (`42` → `(1000042-1000000)`),
   preserving integer/float typing.
2. **`strings`** — every string literal is XOR-encrypted with a per-string salt
   and replaced by a call to a load-time decoder. Identical strings differ in the
   output; the decoder captures `string`/`table` primitives into locals so a later
   `_ENV` swap can't break it.
3. **`pack`** — the whole transformed chunk is XOR+base64 encrypted and wrapped in
   a mangled bootstrap that decrypts and `load()`s it at runtime (ferret's
   "emit a standalone runtime" stage).

Comment/whitespace minification happens for free in the emitter, which preserves
original line breaks so ambiguous call syntax (`a = b` / `(f)()`) never fuses.

## Usage

```sh
# obfuscate (all layers, deterministic with --seed)
lua ferret/cli.lua obfuscate script.lua -o script.obf.lua --seed 7

# lighter pass, no encrypted wrapper (readable structure, encrypted strings)
lua ferret/cli.lua obfuscate script.lua --layers numbers,strings
```

The output runs on Lua 5.1–5.4 and Luau (Roblox executors). `pack` uses
`loadstring or load`, so it works in both classic Lua and Luau environments.

## Validating against the LuaCrypt suite

```sh
# clone the corpus somewhere, then:
lua ferret/run_tests.lua /path/to/Lua-crypt --seed 7
```

The runner obfuscates every program, executes original vs. obfuscated, and diffs
output. It runs each original twice to detect inherent non-determinism
(hash order, `os.time`, addresses) and skips those, and it normalizes chunk paths
and line numbers in tracebacks so it measures **semantics**, not filenames.

### Results (seed 7, Lua 5.4)

```
Total: 263   Pass: 259   Fail: 3   Skip(nondeterministic): 1
Pass rate (of comparable): 98.9%
```

The 3 remaining differences are all in `08_debug/` and are **expected**: those
tests use `debug.getinfo` / `debug.getupvalue` to inspect closure internals
(upvalue count and contents). String obfuscation adds the string-decoder as an
upvalue, so the debug library correctly observes the transformation. A global
decoder would hide it but would break the `_ENV`-swap sandbox tests, so the safe
local decoder is used instead.

## Limitations

- **Luau type-annotation syntax** (`local x: T`, `T?`, `type X = {...}`) is not
  yet parsed — those files are rejected with a clear diagnostic. Plain Lua and
  Luau-without-type-annotations (the usual executor-script case) are fully
  supported; 61/62 of this repo's own scripts obfuscate cleanly.
- This is **semantics-preserving obfuscation**, not a bytecode VM. An authorized
  user who dumps the loaded chunk from memory recovers runnable Lua (as the
  project's `PROTECTION_SETUP.md` already notes for any client-side script).
  Combine with the key/HWID gating for real access control.
- `debug.getupvalue`/`getinfo` on obfuscated closures reflect the added decoder
  upvalue, as above.

## Future work

- Scope-aware **identifier renaming** (needs a full parser; the `pack` layer
  already hides all names inside the encrypted payload, so this mainly hardens
  the `numbers,strings`-only mode).
- Luau front-end (type-annotation stripping, `continue`, compound assignment).
- Control-flow flattening / opaque predicates.

## Files

```
ferret/
  cli.lua         command-line front end
  ferret.lua      pipeline entry (roundtrip / obfuscate)
  lexer.lua       Lua 5.x tokenizer (keeps raw text for faithful re-emit)
  emit.lua        token -> source, safe minifier
  layers.lua      numbers + strings passes and the runtime prelude
  pack.lua        whole-chunk encryption + emitted loader
  rng.lua         deterministic PRNG (seedable, reproducible builds)
  run_tests.lua   corpus validator
```
