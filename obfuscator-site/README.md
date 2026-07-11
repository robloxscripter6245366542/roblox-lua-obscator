# ferret obfuscator — website

A static, **100% client-side** website for the ferret Lua/Luau obfuscator. Paste
Lua, pick layers, get obfuscated output — nothing is uploaded; all work happens
in the browser. Deployed as the repo's Vercel site (`vercel.json` →
`outputDirectory: obfuscator-site`).

## Pages / files
- `index.html` — the obfuscator UI (input/output panes, layer toggles, seed).
- `deobfuscator.html` — the existing Lua deobfuscator, kept reachable.
- `ferret.web.js` — browser/Node port of the token-level pipeline in `../ferret/`
  (numbers / strings / pack).
- `ferret.ast.js` — AST front end: a real Lua/Luau parser, scope resolver,
  scope-aware renamer, and Luau code generator. Adds the `rename` layer and is
  the composed entry point the site calls (`FerretAST.obfuscate`).

## `ferret.web.js` (token layers)

A faithful JavaScript port of the Lua pipeline (`lexer → layers → pack`). The
runtime keystream is a Park-Miller generator whose products stay below 2^53, so
it is exact in plain JS numbers, Lua 5.1–5.4, **and Luau's doubles** — output
generated in the browser decodes identically on Roblox. Works in both the
browser (`window.Ferret`) and Node (`module.exports`).

```js
FerretAST.obfuscate(source, { seed: 7, layers: ["rename","numbers","strings","pack"] });
```

## `ferret.ast.js` (rename layer)

Renaming variables safely needs structure, so this parses the source into an
AST, resolves every identifier to its binding (respecting block scope,
shadowing, `repeat…until` visibility, loop vars, params, and upvalues), renames
only **locals** — never globals, fields, method names, `self`, or table keys —
to opaque names, and regenerates valid Luau. The renamed source then flows
through the token layers.

- AST round-trip (parse → generate): **262/262 (100%)**
- rename, lua5.4: **258/263 (98.5%)** · rename, real Luau: **252/263 (95.8%)**

Residuals are `debug.getlocal`/`getupvalue`/`traceback` (which read local names,
so renaming changes what they observe) and Luau-unsupported syntax (`goto`,
`&|~`) where the original already fails.

## Parity with the Lua implementation

`validate_js.js` runs the JS port over a corpus, executes each output with
`lua5.4`, and diffs it against the original — the same methodology as
`../ferret/run_tests.lua`.

```sh
node obfuscator-site/validate_js.js /path/to/Lua-crypt 7
# Total: 263  Pass: 259  Fail: 3  Skip: 1  → 98.9%
```

Results match the Lua version exactly: the only differences are the 3 `08_debug`
tests that inspect closure upvalues (they observe the string decoder by design).

Set `LUA_BIN` to validate against a different runtime — e.g. a real Luau VM:

```sh
LUA_BIN=./luau node obfuscator-site/validate_js.js /path/to/Lua-crypt 7 numbers,strings
# Luau: 260/263 (98.9%) — numbers,strings output runs in vanilla Roblox
```

**Roblox targeting:** `numbers,strings` is pure Luau and runs in vanilla Roblox
LocalScripts/ModuleScripts. The `pack` layer's loader calls `loadstring or load`,
so packed output needs an executor (or a server with `LoadStringEnabled`). The UI
shows which target the current layer selection produces.

## Verified on a real Luau VM

The obfuscated output was validated on an actual Luau interpreter (`mlua`,
Luau 0.663), which surfaced and fixed a keystream-precision bug that only
manifests under Luau's doubles (see the repo's `ferret/README.md`).

## Local preview

Any static server works, e.g.:

```sh
cd obfuscator-site && python3 -m http.server 8080   # then open http://localhost:8080
```
