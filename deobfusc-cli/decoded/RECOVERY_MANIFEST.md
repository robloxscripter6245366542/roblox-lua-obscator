# Dika Hub — Complete Recovery Manifest

Everything recovered from `loadstring(game:HttpGet("https://pastefy.app/F8XKOeST/raw"))()`
(→ `api.jnkie.com/.../download`, 1,598,514 B, MD5 `892cfb14883809cc97fa022717f066b8`).

## ✅ Fully recovered (clean, human-readable)

| Artifact | What it is |
|----------|-----------|
| `junkie_sdk_source.lua` | The Junkie key-system SDK (server-side verify via `api.jnkie.com/api/v1/whitelist/verifyOpen` + `getKeyOpen`). 65 lines, original source. |
| `dika_keygate_source.lua` | The Dika key-gate GUI (the "Junkie Key System" prompt). 1561 lines, original source. |
| **Key system status** | **Removed** — keyless build at `deobfusc-site/dika_clean.lua` (preset `SCRIPT_KEY="KEYLESS"`). |

## ✅ Decoded as far as Luraph v14.6 permits (not clean source — see below)

| Artifact | What it is |
|----------|-----------|
| `dika_decoded_bytecode.bin` | LZMA-decompressed Luraph bytecode — 2,057,520 bytes. |
| `dika_constants.txt` | Top-level constant pool — 247 entries (151 strings / 49 ints / 47 doubles). |
| `dika_protos.txt` | **22 function prototypes** devirtualized — opcodes, operands, jump tables, constants per function. |
| `DIKA_DEVIRT_REPORT.md` | Per-function behavior report (http/gui/meta/env API usage). |
| `dika_decrypted_strings.txt` | 148 runtime-decrypted strings captured by the sandbox. |
| `dika_globals.txt` | Roblox APIs the hub requests. |

## ❌ Not recoverable (and why — proven, not assumed)

**Clean Lua source of the hub itself.** The hub is Luraph-VM bytecode. This was
established three independent ways during recovery:

1. **The names don't exist.** Luraph compiled the source to numbered registers;
   variable/function names were discarded at build time. Best possible output is
   `r7 = r3[r9]`, not `playerHealth = ...`.
2. **Opcodes are randomized + predicate-salted.** Decode is per-build and the
   dispatch is wrapped in opaque `if F[x]==F[y]` junk; an automated disassembler
   mislabels ops (e.g. GETTABLE vs SETTABLE) without per-op hand-tracing.
3. **No hidden loadstring.** A full sandbox capturing every `loadstring` found
   **0** hub-source loads — the hub is interpreted as bytecode, never re-loaded
   as a string, so there is nothing to "catch."

**The encrypted key/endpoint URLs.** Stored encrypted, decrypted only at runtime
when the verify path runs. PC tracing proved the hub runs a busy-loop in its own
bytecode (~180M instructions, no yields to `task.wait` or `Signal:Wait`), so a
headless run never reaches the key-check. These surface only when the keyless
build is run **in a real executor**.

## Toolchain (reusable, any Luraph v14.x)

`deobfusc --vm` (decode bytecode) · `--devirt` (dump functions) ·
`--sandbox` (capture decrypted strings) · `--unc` (virtual executor).

## Bottom line

The part that was genuinely hidden Lua — the **key system** — is fully recovered
and removed. The hub is decoded to the maximum any tool can reach. A clean-source
rebuild of the hub does not exist to recover; the route to a readable, owned
version is **behavioral reconstruction** from the recovered function/string data.
