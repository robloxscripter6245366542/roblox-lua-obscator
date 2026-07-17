# Luraph v14.6 VM-Layer Decode — Technical Analysis

This documents how the **dynamic VM decoder** (`vm_decoder.py`, exposed as
`deobfusc --vm`) defeats the Luraph v14.6 virtual-machine layer, and what it
recovered from the sample Dika-hub script.

## 1. Protection structure

Luraph v14.6 ships the payload as a ~1.5 MB Lua file containing two base85-encoded,
LZMA-compressed blobs plus a pure-Lua bootstrap:

| Blob | base85 → LZMA → | Size | Role |
|------|-----------------|------|------|
| 1 | Luau **VM interpreter** source | ~89 KB | the bytecode interpreter, itself written in Luau |
| 2 | Luraph **custom bytecode** | ~1.2 MB compressed | the actual program (Dika hub) |

The bootstrap `loadstring`s blob 1 (the interpreter), which then LZMA-decompresses
blob 2 in pure Lua and executes the resulting custom bytecode.

### Anti-analysis features
- **Anti-tamper**: a `do Q={6824,…}` block that sets a sentinel (`q=20.0`) when the
  host is not Lua 5.1, corrupting later arithmetic. Stripped before running.
- **Environment checks**: `getfenv`/`setfenv`, `debug.getinfo`, `iscclosure`,
  `islclosure`, `identifyexecutor`, plus the message *"The debug library is required
  on Luau platforms"* — all gate execution.
- **String-constant encryption**: sensitive constants (URLs, license keys, GUI text)
  are **not** stored in plaintext; they are decrypted at runtime. Only index-names
  (`Destroy`, `GetService`, `RequestAsync`, …) survive as readable constants.

## 2. Why the VM runs in stock Lua 5.4

The interpreter is **Luau** source. To execute it in a plain `lua5.4` binary the
decoder preprocesses three Luau-only constructs (`vm_decoder.py::luau_to_lua54`):

| Luau | Lua 5.4 rewrite | count in sample |
|------|------------------|-----------------|
| `continue` | `goto _cont_N` + injected `::_cont_N::` label | 119 |
| `x += e` (and `-= *= /= %=`) | `x = x + (e)` | 382 |
| invalid escapes `\i`, `\<` | literal char | 3 |

and supplies the Luau/Roblox runtime the interpreter expects but Lua 5.4 lacks:

- **`table.create`** — stored by the VM in slot `F[15]` and used to preallocate the
  LZMA output buffer (`F[12]=F[15](n)`). Missing → the decoder crashes immediately.
  *This was the single most important shim.*
- **`bit32.*`** — full reimplementation including `countlz`, `countrz`, `lrotate`,
  `rrotate`, with Luau boolean→0/1 coercion and varargs semantics.
- **`getfenv`/`setfenv`** — reimplemented via the `_ENV` upvalue
  (`debug.getupvalue`/`debug.upvaluejoin`). The VM stores `setfenv` in `F[7]` and
  calls `F[7](closure, env)` to sandbox each decoded function; a no-op stub silently
  breaks it.
- `string.pack`/`unpack`, `table.move/clear/find/freeze`.

## 3. The `F` opcode-primitive table

The interpreter's `:C()` method builds an integer-keyed table `F` that holds the
VM's primitive operations, threaded through an init chain
`a → S → L → s → e → M → Z → Y → O3 → _a`. Key slots (sample):

```
F[7]  = setfenv      F[14] = string.sub    F[15] = table.create
F[13] = byte reader  F[32] = byte reader   F[36] = getfenv
F[38] = closure-builder (wraps a proto with an env)
```

`:C()` finishes with
`F[38](q,F[17])(m, t, m.O, F[39], d, F[30], F[26], F[27], m.E, F[38])` — i.e. it
builds the top-level closure from the decoded proto and runs it. That closure is
the **bytecode interpreter loop** (`while true do local E = A[h] … end`), a single
giant opcode dispatch on `E` over the instruction array `A` with parallel operand
arrays.

## 4. Capturing the decoded bytecode

The interpreter reads its decompressed program byte-by-byte via `string.byte` /
`string.unpack`. The decoder wraps both and records every distinct large string;
the largest is the LZMA output — the **decompressed Luraph bytecode**:

```
decoded_bytecode.bin   2,057,520 bytes   (from 1.2 MB compressed)
```

### Proto serialization format (reverse-engineered)
```
header   : AC 80 06 00
constants: typed records, marker-prefixed —
             0x7C '|'  string : 1-byte length + bytes
             0x0E      int64  : 8-byte little-endian signed
             0xAB      double : 8-byte little-endian float64
instructions: begin after the constant pool (offset 1656 in the sample)
```

Top-level constant pool: **247 entries — 151 strings, 49 ints, 47 doubles**
(`constants.txt`).

## 5. What the payload is

From the recovered constant pool + the globals it requests at runtime, the Dika-hub
payload is a **GUI key-system loader**:

- builds a `ScreenGui` / `Frame` / `TextLabel` / `TextButton` UI, including a
  **`ChallengeGui`** (the key-challenge window) with `UIPadding`, `UIScale`,
  `UISizeConstraint`;
- requests Roblox datatypes `UDim2`, `UDim`, `Vector2`, `Vector3`, `Enum`,
  `Instance`, `Random`;
- performs executor detection (`identifyexecutor`, `islclosure`, `iscclosure`);
- talks to `HttpService` via `RequestAsync` / `GetAsync` / `PostAsync` for the
  key check.

Because it is a GUI key-gate, the HTTP key-check fires only after a **button click**;
a passive run reaches GUI construction and idles. The encrypted URL/key constants
therefore surface only when UI interaction is simulated — out of scope for the
passive decode.

## 6. Status

| Stage | State |
|-------|-------|
| base85 + LZMA unwrap | ✅ done (static + dynamic) |
| Luau VM interpreter recovered & runnable in Lua 5.4 | ✅ done |
| LZMA-decompressed custom bytecode captured | ✅ `decoded_bytecode.bin` |
| Constant pool parsed | ✅ `constants.txt` (247 entries) |
| Per-constant string decryption | ⬜ encrypted; needs runtime UI simulation |
| Full bytecode → Lua source decompilation | ⬜ instruction-stream disassembly TBD |

## 7. Reproduce

```bash
deobfusc --vm path/to/luraph_obfuscated.lua [workdir]
# or directly:
python3 deobfusc-cli/vm_decoder.py path/to/luraph_obfuscated.lua workdir/
```

Artifacts land in `<workdir>/`: `vm_interp.lua`, `vm_interp.fixed.lua`,
`decoded_bytecode.bin`, `constants.txt`, `globals.txt`, `http.txt`.
Requires `lua5.4` (or `lua5.3`) and `python3`.
