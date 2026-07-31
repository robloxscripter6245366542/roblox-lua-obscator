# Dika Hub — Full Deobfuscation Report

Source: `loadstring(game:HttpGet("https://pastefy.app/F8XKOeST/raw"))()`
which redirects to
`https://api.jnkie.com/api/v1/luascripts/public/65fd1009…e8d1/download`
(1,598,514 bytes — MD5 `892cfb14883809cc97fa022717f066b8`).

The file is a single 100%-printable Lua source with **four stacked layers**.
Three are plain readable Lua; only the last is obfuscated.

```
┌ Layer 1  jnkie SDK wrapper        4 lines   readable   (junkie metadata)
├ Layer 2  Junkie key-system SDK   65 lines   readable   (junkie_sdk_source.lua)
├ Layer 3  Dika key-gate GUI     1561 lines   readable   (dika_keygate_source.lua)
└ Layer 4  Luraph v14.6 hub        ~1.5 MB    OBFUSCATED (decoded_bytecode.bin)
```

---

## Layer 1 — jnkie wrapper (offset 0)

```lua
local Junkie = loadstring(game:HttpGet("https://jnkie.com/sdk/library.lua"))()
Junkie.service    = "dika"
Junkie.identifier = "1005304"
Junkie.provider   = "dika"
```

## Layer 2 — Junkie Key System SDK  → `junkie_sdk_source.lua`

Fetched from `https://jnkie.com/sdk/library.lua`. **Not obfuscated** — its own
header says *"THIS LIBRARY IS NOT SECURED"*. Key verification is **server-side**:

| Function | Request | Purpose |
|----------|---------|---------|
| `Junkie.check_key(key)` | `POST https://api.jnkie.com/api/v1/whitelist/verifyOpen`  body `{key, service="dika", identifier="1005304"}` | returns `{valid, message}` (`KEYLESS` / `KEY_VALID` / invalid) |
| `Junkie.get_key_link()` | `POST https://api.jnkie.com/api/v1/whitelist/getKeyOpen` body `{service, provider, identifier}` | returns the key-purchase link |
| `Junkie.load_script()` | `GET  https://api.jnkie.com/api/v1/luascripts/public/{script_id}/download` | fetches a script body |

Because validation lives on `api.jnkie.com`, the key itself is just a string the
server checks; nothing is verified client-side.

## Layer 3 — Dika key-gate GUI  → `dika_keygate_source.lua`

A 1561-line, fully readable `(function() … end)()` that:

- builds the **"Junkie Key System"** GUI (`ScreenGui` `JunkieKeySystemUI`,
  themed colours, Get-Link / Verify-Key buttons, status text);
- caches a verified key to `verified_key.txt` (`saveVerifiedKey` / `loadVerifiedKey`);
- on launch calls `Junkie.check_key(savedKey or getgenv().SCRIPT_KEY)`:
  - `message == "KEYLESS"` → sets `getgenv().SCRIPT_KEY = "KEYLESS"`, closes;
  - `message == "KEY_VALID"` → saves key, closes;
  - else shows the prompt and waits `while not getgenv().UI_CLOSED do task.wait(0.1) end`;
- on **Verify** click → `Junkie.check_key(key)`; if `valid` →
  `getgenv().SCRIPT_KEY = key`; on **Get Link** → `setclipboard(Junkie.get_key_link())`;
- returns `getgenv().SCRIPT_KEY`.

The hub in Layer 4 reads `getgenv().SCRIPT_KEY` to authenticate.

### Removing the key system
Two equivalent client-side bypasses (server still decides validity for any
real online check the hub itself may perform):

```lua
-- (a) neutralise the SDK
Junkie.check_key   = function() return { valid = true, message = "KEYLESS" } end
Junkie.get_key_link = function() return "" end

-- (b) skip the gate entirely, preset the key the hub expects
getgenv().UI_CLOSED = true
getgenv().SCRIPT_KEY = "KEYLESS"
```

## Layer 4 — Luraph v14.6 hub (offset 69,716 → end)

Marked `-- This file was protected using Luraph Obfuscator v14.6`.
Decoded with the dynamic VM decoder (`deobfusc --vm`):

- base85 → LZMA → ~89 KB Luau **VM interpreter** + ~1.2 MB compressed **custom bytecode**;
- the VM was run in stock Lua 5.4 (after `table.create` / `bit32` / `getfenv`/`setfenv`
  shims) and the LZMA-decompressed bytecode captured:
  **`dika_decoded_bytecode.bin` — 2,057,520 bytes**;
- proto format: header `AC 80 06 00` + typed constant pool
  (`0x7C` string / `0x0E` int64 / `0xAB` double) → **247 constants** (`dika_constants.txt`);
- the hub builds its own GUI (`ScreenGui/Frame/TextLabel/TextButton/UIPadding`),
  detects the executor, and uses `HttpService:RequestAsync/GetAsync/PostAsync`.

Sensitive constants (URLs, keys, hub feature text) are **per-constant encrypted**
by Luraph and only decrypt at runtime, so they are not present as plaintext in the
decoded bytecode. See `../LURAPH_VM_ANALYSIS.md` for the full VM internals.

---

## Status

| Layer | Result |
|-------|--------|
| 1 jnkie wrapper | ✅ readable |
| 2 Junkie SDK | ✅ fully recovered (`junkie_sdk_source.lua`) |
| 3 Dika key-gate GUI | ✅ fully recovered (`dika_keygate_source.lua`) |
| 4 Luraph hub — VM bytecode | ✅ decoded (`dika_decoded_bytecode.bin`, `dika_constants.txt`) |
| 4 Luraph hub — per-constant strings | ⬜ runtime-encrypted |
| 4 Luraph hub — full source decompile | ⬜ 2 MB instruction stream, TBD |
