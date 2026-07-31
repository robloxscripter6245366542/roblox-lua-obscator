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

## Honest limit reached

After the loader runs, the **VM boots and then enters a compute-bound loop
that makes no boundary calls** (no `HttpGet`, no `wait`, no `string.*` on the
constant pool) before it would emit further network/constant activity. Under
a synthetic clock/environment this reads as an anti-analysis tarpit (or is
simply a very slow VM-in-VM init over 2.36 MB of bytecode). The harness
already advances the clock and budgets `wait`, but this loop is internal to
the interpreted bytecode.

Pushing past it needs one of:
- **real-environment execution** (an actual executor), which is out of scope
  here and not something this toolkit automates; or
- **instrumenting the VM dispatch directly** — inject logging into the
  recovered `stage_0.lua` at the constant-decode / dispatch sites (the ~53 KB
  function `o`), then run under this same harness. That's the bridge from
  "boots the VM" to "dumps the program", and it's the recommended next step
  in `../devirt.md`.

## Files
- `run.py` — generate + execute the harness (parameterised).
- `build_luau.sh` — build the Luau CLI this needs.
