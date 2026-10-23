# Luarmor V4 ("superflow") — Analysis & Toolkit

Target chain (from `loadstring(game:HttpGet("https://moondiety.com/loader"))()`):

```
moondiety.com/loader
  → api.luarmor.net/files/v3/loaders/d677…57d.lua   (Luarmor v3 loader, project "marbeg")
  → cdn.luarmor.net/v4_init_marbeg.lua               (real payload, 602,650 B)
  → Luarmor V4 "superflow" custom register VM
```

## 1. CDN fingerprint gate

The v4 init CDN serves a **fake "executor not supported" stub** (327 B, a
`LocalPlayer:Kick(...)`) to ordinary requests. It releases the real 602 KB
payload only to a recognized executor User-Agent:

```
curl -A "Roblox/WinInet" https://cdn.luarmor.net/v4_init_marbeg.lua
```

(Plain UAs — `synapse`, `Krnl`, `Fluxus`, … — all get the stub; `Roblox/WinInet`
gets the payload.)

## 2. Bootstrap data dependency

The v3 loader defines a global `_bsdata0 = { … }` (bsdata array: ints + base85
blob + `\xNN` key strings) and then runs the v4 init **in the same environment**.
The v4 superflow VM indexes `_bsdata0` directly, so to run the init standalone
you must prepend the v3 loader's `_bsdata0 = {...};` definition.

## 3. The "superflow" VM (distinct from Luraph)

`superflow_bytecode = { "\179\213…" }` followed by `return({ <methods> }):A()(...)`.
A register VM whose methods (`Pm`, `L3`, `p3`, `Um`, `K`, `A`, …) read a state
table and a byte stream. Differences from Luraph:

- **Luau number syntax**: binary literals (`0b11000`) and underscore separators,
  including trailing (`0X61__`, `0b101__1111_`, `0X0059D_4`). Invalid in Lua 5.4.
- **`continue`** (124×) and **compound assignments** (121×) like Luau/Luraph.
- **Native `buffer` library**: decode/interpretation runs through Luau `buffer`
  (`buffer.create/readu8/writeu8/…`), not `string.byte`.

### Made runnable in Lua 5.4
- `vm_decoder.normalize_luau_numbers()` — binary + underscore number literals.
- `vm_decoder.luau_to_lua54()` — also fixes `continue`/compound/escapes.
- `buffer_shim.lua` — byte-accurate Luau `buffer` library for Lua 5.4.
- Prepend `_bsdata0` from the v3 loader.

With those, the 602 KB superflow VM **parses and executes** in stock `lua5.4`.

## 4. Status & ceiling (same as Luraph)

The superflow VM **runs** but busy-loops headlessly: it interprets the Luarmor
bootstrapper (executor + `script_key` checks) internally, keeping data in
`buffer`/registers rather than emitting a `loadstring` chunk — so a passive run
reaches no decoded source. Key validation is **server-side** against
`luarmor.net`, so the protected hub only decrypts with a valid key on a real
executor.

| Stage | State |
|-------|-------|
| Chain mapped + payload fetched (UA gate bypassed) | ✅ |
| Luau syntax → Lua 5.4 (numbers/continue/compound) | ✅ |
| `buffer` library shimmed; `_bsdata0` provided | ✅ |
| Superflow VM parses + executes in lua5.4 | ✅ |
| Clean hub source | ❌ custom VM, names destroyed (same as Luraph) |
| Encrypted key/script | ❌ server-side `script_key`, real-executor only |

## 5. Reusable pieces added to the toolkit

- `buffer_shim.lua` — Luau `buffer` for any Lua 5.4 VM analysis.
- `vm_decoder.normalize_luau_numbers()` — binary/underscore number support.
- The `Roblox/WinInet` UA trick for Luarmor CDN payloads.
