# deathball.lua — Luraph v14.7 deobfuscation report

Source: `https://raw.githubusercontent.com/lakamkam5-lab/deathball/refs/heads/main/deathballl.lua`
Analysed with this repo's `luraph-deobf` toolkit (`peel.py`, `dynamic/run.py`,
`devirt/run_vm.py` dispatch probe). Network and filesystem were stubbed
throughout — nothing was executed against a live game or endpoint.

---

## TL;DR (read this first)

This file is **not recoverable to clean, readable Lua source by an automatic
tool**, and no honest tool in this repo claims otherwise. It is a
**Luraph Obfuscator v14.7 VM build**: the real program was compiled to a
custom bytecode and ships with a hand-obfuscated interpreter that runs it.
The outer packing peels statically, the interpreter and bytecode are fully in
hand, and the program's API surface is recovered — but turning the bytecode
back into the original `local x = ...` source is build-specific reverse
engineering (Luraph randomises the opcode numbering on every build), which is
manual, week-scale work, not a one-shot pass.

**What "missing variables become placeholders" would mean here:** a
devirtualised *register-level* listing (`reg[3] = reg[1] + K2`, goto-form),
not the original variable names — those are destroyed at compile time and
cannot be resurrected, only re-invented as placeholders. That last-mile lift
needs a per-build opcode→semantics map; see "Honest limits" below.

---

## 0. Fingerprint

| field | value |
|---|---|
| protector | **Luraph Obfuscator v14.7** (header comment + `LPH#` stream) |
| packed streams | **1** long-bracket stream, header `LPH#!!` |
| outer encoding | base-85 (Ascii85 variant), **no LZMA layer** in this build |
| packing shape | **inverted** vs. the repo's `sample_sigil.lua`: here the VM
  interpreter ships as cleartext-obfuscated Lua (the `return({...}):p()(...)`
  table) and the `LPH#` stream is the **bytecode**, embedded inside it |
| VM model | register machine; dispatch `repeat local y=(s[f]) ...`, opcode
  array `s`, pc `f`, operand arrays `E,_,t,S`, register file `o` |

The identifiers are single/short letters with hex/binary numeric literals
(`0X4C`, `0B1001100`) — cosmetic renaming over a real virtualised interpreter.

## 1. Static unpack (`peel.py`) — DONE

The single `LPH#!!…` stream base-85-decodes, keylessly, to **85,236 bytes**
of VM bytecode (`bytecode.bin`). Unlike the v14.7 sigil sample, this build's
stream is **not** LZMA-compressed on top (entropy ≈ 6.07, decodes straight to
the tagged bytecode). No key, no runtime needed for this step.

## 2. Anti-tamper — NEUTRALISED

Standard v14.7 probe: the bootstrap calls `loadstring("\x1bLuaP")` and reads
the **second** return value (the error message); a stub that drops it poisons
the decode offset. The dynamic harness returns `(nil, errmsg)` exactly, so the
probe passes and the VM boots (confirmed: it deserialised and dispatched).

## 3. Dynamic instrumentation (stubbed Luau) — PARTIAL

Booting the recovered VM under the Luau CLI in a network-blocked env:

- **Constant/API surface — recovered** (`constants.txt`). The interpreter
  materialises the Roblox API names the program binds. Notable:
  - **Network:** `HttpService` · `GetAsync` · `PostAsync` · `RequestAsync`
    → the script *does* make HTTP calls (typical key-system / config fetch).
  - **UI / drawing:** `ScreenGui` · `UDim` / `UDim2` · `Vector2` / `Vector3` ·
    `Path2D` / `Path2DControlPoint` (`GetPositionOnCurve*`,
    `SetControlPoints`) · `MouseBehavior` (`LockCenter`, `LockCurrentPosition`).
  - **Environment / executor detection:** `identifyexecutor` · `islclosure` ·
    `iscclosure` · `debug.getinfo`.
  - **Runtime:** `coroutine` (`wrap`/`resume`/`yield`) · `task`
    (`spawn`/`wait`/`delay`/`cancel`) · `RunService` (`IsClient`/`IsServer`/
    `IsStudio`) · `Random` (`NextInteger`/`NextNumber`/`NextUnitVector`) ·
    `bit32` · `utf8` · `pcall`/`xpcall` · `setfenv`/`getfenv` · metatables.
  - One opaque token surfaced verbatim: **`qLAOhmVRA`** (candidate key/seed/id).
- **Program behaviour (concrete HttpGet URLs, config values) — NOT captured.**
  The VM is slow enough under the CLI that it did not run past
  deserialisation into the program's own logic within a multi-minute budget,
  and Luraph decodes the program's *own* string constants lazily per-use
  (weakness W3), so the specific URLs/keys/feature strings did not materialise.
  The multi-word strings that *did* surface are all Luraph's **own** runtime
  messages, not the script's.

## 4. Disassembly (`devirt/run_vm.py` dispatch probe) — DONE

Injecting the operand probe directly at this build's dispatch and dumping each
proto's full instruction array on first entry yields the complete static
listing (`disassembly.txt`):

- **15 protos, 6,769 instructions**, **189 distinct opcodes**.
- proto sizes: `[415, 4865, 96, 55, 31, 116, 78, 307, 96, 76, 245, 93, 106, 138, 52]`
  — **proto 2 (4,865 instr) is the program body**; the rest are bootstrap/helpers.
- hottest opcodes: `154`×1857, `119`×624, `20`×515, `167`×482, `165`×465,
  `120`×229 (load/move/arith-class ops dominate, as expected of a register VM).
- operands are shown with constants already resolved where the VM inlined them
  (e.g. `op=166 … b=coroutine`), so the listing already reads as "op + real
  globals" rather than opaque indices.

## Honest limits (what this is NOT)

- **No clean source.** The original `.lua` (named locals, functions, comments)
  is gone — Luraph compiled it away. The recoverable ceiling for v14.7 with
  these tools is: bytecode + interpreter + disassembly + API/behaviour, all of
  which are here.
- **No mnemonic lift shipped.** `devirt/lift.py` can emit register-level Lua,
  but only with a **correct per-build opcode map**. This repo's committed map
  (`devirt/opcodes.full.json`) is for the *sigil* build; Luraph renumbers
  opcodes every build, so applying it here would produce confidently-wrong
  mnemonics. Recovering *this* build's map is the register-delta step in
  `devirt/semantics.py` and is the remaining manual mile — deliberately not
  faked here.
- Everything above was produced with network and disk **stubbed**; no request
  was made to any endpoint the script references.

## Artifacts in this folder

| file | what it is |
|---|---|
| `deathball.lua` | the original obfuscated sample (as downloaded) |
| `bytecode.bin` | 85,236 B VM bytecode, base-85-peeled from the `LPH#` stream |
| `disassembly.txt` | full 6,769-instruction listing, 15 protos, resolved operands |
| `constants.txt` | recovered constant / API surface (base-85 fragments filtered out) |
| `report.md` | this file |

## Reproduce

```bash
cd luraph-deobf
bash dynamic/build_luau.sh                          # once
python3 peel.py samples/deathball/deathball.lua -o /tmp/peeled   # -> bytecode
# disassembly: dispatch probe injected into the sample (it self-boots);
# see report §4 (find_dispatch locates y=s[f], operands E,_,t,S, regfile o).
```
