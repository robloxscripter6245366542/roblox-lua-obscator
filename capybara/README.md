# capybara — pure-Lua obfuscator

A self-contained Lua/Luau obfuscator. It takes readable Lua and emits
functionally identical but hard-to-read Lua, so the output runs **anywhere Lua
5.1+/Luau runs** — no Rust toolchain, no native VM, no build step, just one
folder of `.lua` files.

capybara is an **original implementation** written for this repo. It is inspired
by the general stage design common to modern Lua protectors (lex → transform →
encrypt → emit a standalone runtime), but shares no code with any commercial
service. It is a sibling to this repo's [`ferret`](../ferret) obfuscator; the
two differ mainly in how they hide constants (see below).

## Quick start

```sh
# obfuscate a script (all layers, random seed)
lua capybara/cli.lua obfuscate script.lua -o script.capy.lua

# reproducible build with a fixed seed
lua capybara/cli.lua obfuscate script.lua -o out.lua --seed 7

# only some layers
lua capybara/cli.lua obfuscate script.lua --layers strings,pack

# run the behavioral test suite
lua capybara/run_tests.lua
```

## Layers

Applied in a fixed order; pick a subset with `--layers`:

1. **`numbers`** — each plain integer literal `n` becomes `((A)%(M))` where
   `M > n` and `A = n + M·k`, so `A % M == n`. Only decimal-integer literals are
   touched, so hex / float / exponent forms keep their exact typing.
2. **`strings`** — capybara's signature **constant pool**. Every string literal
   is XOR-encrypted with a per-entry salt and hoisted into a single table `P`
   that a one-time load-time decoder fills; each use site becomes a bare index
   `(P[k])`. Identical strings collapse to one opaque index.
3. **`pack`** — the whole transformed chunk is XOR-encrypted and base64-encoded
   using a **per-build shuffled alphabet**, then wrapped in a mangled bootstrap
   that decodes, decrypts, compiles and runs it. The bootstrap carries its own
   matching alphabet, assembled from `string.char` rather than a literal.

## Design: semantics-preserving, not a bytecode VM

Some protectors compile Lua into a custom register-bytecode VM. Faithfully
re-implementing such a VM in pure Lua means re-implementing coroutines,
metatables, `debug.*`, weak tables and `__gc` by hand. capybara instead keeps
**every transform semantics-preserving**: the emitted program is still ordinary
Lua that the host runtime executes directly. That is what lets a single portable
folder run correctly on real programs while staying dependency-free.

### capybara vs ferret

| | `ferret` | `capybara` |
|---|---|---|
| string hiding | inline per-string decoder call at each site | shared **constant pool** `P[k]` |
| number hiding | `(A - B)` subtraction | `((A) % (M))` modulo |
| whole-chunk pack | base64 + XOR, fixed alphabet | base64 + XOR, **per-build shuffled alphabet** |

## Layout

| file | job |
|---|---|
| `lexer.lua` | tokenize Lua 5.x / Luau source (keeps exact `raw` text) |
| `emit.lua` | re-serialize a token stream to minimal valid Lua |
| `layers.lua` | the `numbers` and `strings` transform passes + runtime prelude |
| `pack.lua` | whole-chunk encryption + standalone bootstrap loader |
| `rng.lua` | deterministic PRNG for reproducible builds |
| `capybara.lua` | the pipeline (`Capybara.obfuscate(src, opts)`) |
| `cli.lua` | `obfuscate <input> -o <output> [--seed N] [--layers L]` |
| `run_tests.lua` | behavioral suite: original vs obfuscated must match |

## Library API

```lua
package.path = "capybara/?.lua;" .. package.path
local Capybara = require("capybara")

local obf = Capybara.obfuscate(source, {
    seed = 7,                         -- deterministic build
    layers = { "numbers", "strings", "pack" },
})
```

`Capybara.roundtrip(src)` lexes and re-emits with no transforms, handy for
checking the lexer/emitter on new inputs.

## Guarantees & limits

- Output is **behaviorally identical** to the input on Lua 5.1 / 5.2 / 5.3 / 5.4
  and Luau — verified by `run_tests.lua`, which runs original and obfuscated
  builds side by side and asserts identical printed output and return values.
- This is **obfuscation, not encryption**: a determined analyst with the output
  can recover behavior. It raises the cost of casual reading and copy-paste
  theft; it is not a DRM guarantee.
- Only obfuscate code you own or are authorized to protect.

## License

MIT — see [LICENSE](./LICENSE).
