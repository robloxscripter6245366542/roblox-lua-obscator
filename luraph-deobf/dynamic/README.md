# Dynamic analysis — running the recovered VM under real Luau

The static pass (`../peel.py`) unpacks a Luraph sample to the VM interpreter
source + bytecode. This directory goes one step further: it **executes** the
sample in a real Luau runtime inside a stubbed, network-blocked environment,
so the program's actual behaviour — endpoints, config, method calls — is
captured without understanding the VM at all (weakness **W2**: you own the
environment it runs in).

## Setup

```bash
bash build_luau.sh                 # builds ./luau (official Luau CLI)
python3 run.py ../sample_sigil.lua --luau ./luau --timeout 60
python3 run.py ../sample_sigil.lua --luau ./luau --strings   # + constant dump
```

`run.py` generates a `harness.luau` that: builds a custom writable `env`
(Luau freezes `_G`, so we run the sample via `setfenv`), installs stubs for
the Roblox/executor surface, keeps `loadstring` **real** so the VM compiles,
and routes every compiled chunk through `env` so the program's globals hit
our stubs. A `recorder` object absorbs field reads/writes/calls and logs
them.

## Big finding — the anti-tamper is a `loadstring` return-value probe (W5)

The bootstrap's integrity block runs before the LZMA decode and, on failure,
flips the base-85 header length `D=5 -> 20.0`, which corrupts the stream and
kills decompression with **`table overflow` in function `C`** (the LZMA
loop). The probe is:

```lua
Z = {51095, {0x1B,0x4C,0x75,0x61,0x50}, tostring(loadstring)}
for n,L in Z do
  local X = { pcall(loadstring, <L or char(unpack(L))>, nil, nil) }
  if X[1] and pcall(X[2]) ~= not X[3] then D = 20.0 end   -- X[3] = 2nd return
end
```

It calls `loadstring("\x1bLuaP")` and inspects the **second return value**
(the error message). A naïve stub that returns only `nil` (dropping the
errmsg) makes `not X[3]` true and trips `D=20`. The fix is one line — the
stub must return `(nil, errmsg)` exactly like a real `loadstring`:

```lua
env.loadstring = function(s, cn)
    local f, e = realLoadstring(s, cn)
    if f then pcall(setfenv, f, env) end
    return f, e            -- preserving `e` is what satisfies the probe
end
```

With that, the sample self-unpacks and boots its VM. This is a concrete
instance of the general lesson: **anti-tamper that only poisons a variable
is a one-line bypass** — it must be bound into the decode cryptographically.

## What the run captures (verified)

Booting `sample_sigil.lua` under the harness reproduces the loader's full
behaviour with network blocked:

```
HttpGet   "https://cdn.jnkie.com/SigilUI.lua"
SET Appearance {Title="Sigil", Subtitle="Enter your key to continue", ...}
SET Discord   "discord.gg/jnkie"
SET FileName  "Jnkie_key"
SET Shop      {Title="Get Premium", Link="jnkie.com", ButtonText="Buy", ...}
CALL LaunchJunkie {Service="Mm", Identifier="1027906", Provider="Mm"}
```

i.e. the key-system UI library URL, the Discord, the local key filename, the
shop funnel, and the launched game id — all recovered dynamically.

## Big finding — the whole constant pool falls out of `buffer.readstring`

`run.py --strings` now dumps the VM's decoded constant pool. The v14.7
deserialiser reads string constants out of the bytecode buffer via
**`buffer.readstring`**, so the program reads that global from *its* env —
hand it a logging wrapper and every constant is printed as the VM
deserialises, *before* any spin loop. (String-lib and `table.concat` hooks
catch anything assembled at runtime; `buffer.readstring` is the one that
matters for v14.7.)

Result on the sample: the **complete 165-entry constant pool**, saved to
`sample_constants.txt`. It contains the VM's environment-name table
(`bit32`, `buffer`, `coroutine`, `debug`, `task`, `getfenv`, …), a large set
of Roblox UI API names (`ScreenGui`, `Frame`, `TextButton`, `UIPadding`,
`Path2D`, `GetPositionOnCurve`, …), Luraph's own runtime messages, and a few
watermark/junk constants (`<nLB=>`, `I4Bbh=<`, `JdL>>>`).

**What this tells us about the sample:** the Luraph-protected blob is a **UI
library**, not the key checker. There are no URLs/tokens/HWID strings in its
constant pool — the network/key logic lives in the separately-fetched
`cdn.jnkie.com/SigilUI.lua` (captured by the loader run above), not in the
protected blob. So for *this* sample the constant pool is fully recovered and
there is nothing further hidden in it.

## The spin loop, and how the harness avoids it

A universal chainable stub for unknown globals makes execution spin forever
(loop conditions that read a missing global become permanently truthy).
`run.py` instead resolves unknown globals to real libs, else **`nil`**: the
deserialiser still completes (full pool emitted) and the program then errors
cleanly at the first genuinely-missing global, rather than tarpitting. Common
Roblox datatypes (`Instance`, `Vector3`, `Path2DControlPoint`, …) are stubbed
explicitly so UI construction proceeds.

## What still needs the opcode lifter

Constant-pool + behaviour are now recovered. Full *source* reconstruction
still needs devirtualising the bytecode (mapping the custom opcodes in the
~53 KB dispatch function `o` back to Lua) — see `../devirt.md`. That's the
last mile and it's a manual per-version lift; everything up to it is
automated here.

## v15 — `run_v15.py` (VM trace harness)

v15 has no separate VM-source + bytecode to boot: the whole program is one
`return setmetatable({…}, {}):XA()(...)` where the table's fields are ~155
threaded "continuation" handlers (each returns `next_handler_id, regs…`) and
the driver (`XA` → the `while true` loop in one handler) fetches handlers out
of the table into locals before calling them. `run_v15.py` exploits exactly
that: it reuses `run.py`'s stubbed env, then **wraps `setmetatable`** so that
when the big handler table is created, every VM handler field is replaced with
a tracer *before* the driver reads it — cached std-lib primitives
(`buffer`/`bit32`/`string`/…) are identity-checked and left real so the hot
decrypt loop keeps full speed.

```bash
python3 run_v15.py ../sample_v15.lua --luau ./luau --out v15_trace
#   v15_trace.hist.txt   per-handler call histogram
#   v15_trace.seq.txt    handler-transition trace = executed opcode stream
#   v15_trace.writebuf.bin  most-written buffer (VM scratch/registers)
```

**Verified on `../sample_v15.lua` (Luraph v15.0):** the VM boots and runs to
completion (erroring only at a stubbed service, i.e. after the VM ran). The
histogram is dominated by a 5-handler cycle (`Mu Nu Lu ou hu`, ~33 K calls
each) and `XA` fires exactly once (the bootstrap). The sequence trace shows a
tight repeat `ou->23 Lu->37 Nu->13 Mu->8 hu->29 …` — the per-instruction
decode/dispatch loop, and effectively the executed opcode stream.

**What this proves (dynamically):** v15 decrypts the bytecode **lazily, per
read** (`bit32.bxor` in the `readu8` path). There is no monolithic decrypted
buffer to dump — the `writeu8` reconstruction yields the VM's low-entropy
scratch/register space (~0.46 bits/byte), not plaintext bytecode. So static
recovery stops at the encrypted buffer (see `../v15.md`); the *dynamic* trace
is where the instruction stream becomes observable.

## v15 opcode map — `../devirt/v15_opcodes.py`

Feed this harness's `<out>.hist.txt` into `../devirt/v15_opcodes.py` to build
the opcode map: it statically classifies all 145 handlers (arity, library
slots, `next_handler_id` successors, category) and marks which the trace
exercised. On the sample: **145 defined, 0 unclassified, 68 exercised, 77
never hit** (the remaining opcodes). Committed output:
`../devirt/v15_opcode_map.md` + `../devirt/v15_opcodes.json`.

## What still needs the opcode lifter

Constant-pool + behaviour are recovered (v14.7); the v15 handler trace and a
fully-classified handler map are recovered. Full *source* reconstruction still
needs (a) samples that exercise the remaining 77 v15 handlers and (b) assigning
each handler an exact Lua operation + codegen — for v14.7 the analogous step is
mapping the opcodes in the ~53 KB dispatch `o`. See `../devirt.md` and
`../v15.md`. That's the last mile and it's a manual per-version lift;
everything up to it is automated here.

## Files
- `run.py` — generate + execute the harness; `--strings` dumps the pool.
- `run_v15.py` — v15 VM trace harness (handler histogram + dispatch trace).
- `build_luau.sh` — build the Luau CLI this needs.
- `sample_constants.txt` — the 165-entry pool recovered from the sample.
