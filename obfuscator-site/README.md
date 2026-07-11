# ferret obfuscator — website

A static, **100% client-side** website for the ferret Lua/Luau obfuscator. Paste
Lua, pick layers, get obfuscated output — nothing is uploaded; all work happens
in the browser. Deployed as the repo's Vercel site (`vercel.json` →
`outputDirectory: site`).

## Pages
- `index.html` — the obfuscator UI (input/output panes, layer toggles, seed).
- `deobfuscator.html` — the existing Lua deobfuscator, kept reachable.
- `ferret.web.js` — browser/Node port of the pure-Lua obfuscator in `../ferret/`.

## `ferret.web.js`

A faithful JavaScript port of the Lua pipeline (`lexer → layers → pack`). The
build-time keystream uses `BigInt` so it is **bit-identical** to the Lua runtime
decoder it emits, meaning output generated in the browser runs correctly on Lua
5.1–5.4 and Roblox Luau. It works in both the browser (`window.Ferret`) and Node
(`module.exports`).

```js
Ferret.obfuscate(source, { seed: 7, layers: ["numbers", "strings", "pack"] });
```

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

## Local preview

Any static server works, e.g.:

```sh
cd obfuscator-site && python3 -m http.server 8080   # then open http://localhost:8080
```
