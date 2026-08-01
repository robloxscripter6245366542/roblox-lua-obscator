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

## Files
- `run.py` — generate + execute the harness; `--strings` dumps the pool.
- `build_luau.sh` — build the Luau CLI this needs.
- `sample_constants.txt` — the 165-entry pool recovered from the sample.
