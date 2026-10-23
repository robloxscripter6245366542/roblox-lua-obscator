# Luraph-format obfuscator — website

A brand-new, **100% client-side** Lua / Roblox **Luau** obfuscator that emits code in
the signature **Luraph output style**. Paste Lua, pick your layers, get protected
output — nothing is uploaded; everything runs in the browser.

> **Separate from Granite Lock.** This site lives entirely in `luraph-site/` and ships
> its **own private copies** of the engine (`engine.web.js`, `engine.ast.js`) and the
> deobfuscator page. It does **not** touch `obfuscator-site/` (Granite Lock),
> `granite-lock/`, or the repo's `vercel.json`. Deploying this site is opt-in (see below).

## Files

- `index.html` — the Luraph-format obfuscator UI (presets, layer toggles, seed, watermark).
- `deobfuscator.html` — a local copy of the Lua deobfuscator, reachable from the nav.
- `engine.web.js` — token-level pipeline (string / number layers). Exposes `Ferret.obfuscate`.
- `engine.ast.js` — real Lua/Luau parser + scope-aware renamer. Exposes `FerretAST.obfuscate`
  (the composed entry point the UI calls). Load **after** `engine.web.js`.

## Presets

| Preset   | Layers |
| :------- | :----- |
| Weak     | rename + minify + banner |
| Medium   | rename + string enc + constant enc + banner |
| Strong   | + control-flow VM wrap + anti-tamper |
| Maximum  | + anti-hook/anti-debug + minify |

## Luraph macros (`LPH_*`)

Luraph lets you annotate your **source** with compile-time macros that steer the
obfuscator. They are transparent at runtime (identity — each returns what it wraps).
This site recognises the standard set — `LPH_JIT`, `LPH_JIT_MAX`, `LPH_NO_VIRTUALIZE`,
`LPH_SKIP`, `LPH_ENCFUNC`, `LPH_ENCSTR`, `LPH_ENCNUM`, `LPH_NO_UPVALUES`, `LPH_CFUNC`,
`LPH_LITERAL`, `LPH_STR`, `LPH_CRASH` — and prepends a local identity shim for each one
your script uses, so a **Luraph-annotated script runs through this tool** instead of
erroring on a `nil` global. The literals/functions those macros wrap are still encrypted
by the layers below.

```lua
local greeting = LPH_ENCSTR("Hello!")
local greet    = LPH_NO_VIRTUALIZE(function(n) return "hi "..n end)
LPH_JIT(function() print(greet("bob")) end)()
```

## Layers ("all the Luraph-format things")

- **Rename identifiers** — a real parser resolves scope, then renames locals, params and
  loop variables. Globals and fields are never touched, so the script still runs.
- **String encryption** — every string literal becomes a per-build XOR-encrypted blob,
  rebuilt at runtime through a decoder. The plaintext never appears in the file.
- **Constant encryption** — numeric literals are rewritten as arithmetic / bitwise
  expressions.
- **Control-flow VM wrap** — folds the chunk into the Luraph-signature
  `return(function(...) … end)(...)` closure; varargs and top-level return values are
  preserved.
- **Anti-tamper** — embeds the watermark and re-verifies its checksum at runtime; editing
  the banner makes the guard quietly `return`.
- **Anti-hook / anti-debug** — a `pcall`-guarded probe that never errors on a clean runtime.
- **Minify** — a token-safe whitespace & comment stripper (respects strings, long strings
  and comments; never alters string contents).
- **Luraph banner** — the classic header with version, serial, watermark, preset and seed.

## Correctness

The pipeline was mirrored in Node and every output run through `lua5.4`:
**10 test scripts × 4 presets = 40/40 pass**, each producing output identical to the
original — including vararg, top-level-return, and `LPH_*` macro cases through the VM
wrapper.

## Running locally

It's a static site — no build step. Serve the folder with any static server:

```sh
cd luraph-site
python3 -m http.server 8080      # then open http://localhost:8080
```

## Deploying (opt-in, does not affect Granite Lock)

The repo's `vercel.json` currently builds Granite Lock (`granite-lock/out`) and is left
**unchanged** on purpose. To publish *this* site instead, point Vercel at `luraph-site`
— for example a `vercel.json` with:

```json
{ "outputDirectory": "luraph-site" }
```

Prefer a **separate Vercel project** for this folder if you want both sites live at once,
so Granite Lock's deployment is untouched.

## Notice

This is an educational, client-side obfuscator that emits code in the Luraph *style /
format*. It is not affiliated with, and does not reproduce, the proprietary Luraph VM.
Like every self-contained obfuscator it raises the effort to read your code and defeats
casual copy-paste, but it is not an unbreakable protection boundary — the decoder and key
must ship with the script to run. Use it to learn the format and to lightly protect
scripts you own.
