# luraph-deobf

A small, **honest** toolkit for analysing and unpacking Luraph-protected
Lua/Luau scripts (targets v13 / v14.x, e.g. the `LPH%V` / `-- Luraph
Obfuscator v14.7` family). Built as reference material for this repo's
obfuscator work: *knowing exactly where an obfuscator leaks is how you
build one that doesn't.*

It is a **reverse-engineering / security-research** tool. Use it on samples
you are authorised to analyse (your own builds, malware triage, CTF, or
studying a technique). It is not a "steal someone's paid script" button —
and, importantly, it *can't* be: see the honest-scope note at the bottom.

---

## The Luraph weakness map

Luraph is a **VM-virtualisation** obfuscator: it compiles the real Lua into
custom bytecode and ships a Lua interpreter for that bytecode. Layered on
top are packing, string encryption, and anti-tamper. Here is where each
layer is weak and which tool addresses it.

| #  | Weakness | Why it leaks | Tool |
|----|----------|--------------|------|
| **W1** | **Outer packing is reversible encoding, not encryption.** The `[=[LPH…]=]` streams are a base-85 (Ascii85) variant + a `z` zero-run shorthand + a fixed `D`-char header. No key. | Any encoding without a runtime-derived key peels offline. | `peel.py` |
| **W2** | **Code owns no environment; you do.** It must run in a real Lua VM and call real `string.*`, `game:HttpGet`, globals, metatables. | Replace the environment with instrumented copies and every real effect is observable. | `sandbox.lua` |
| **W3** | **Stages decrypt themselves then `loadstring`/`load` them.** | Wrapping the compiler hands you each fully-decrypted stage *before* it runs — no need to break the cipher yourself. | `sandbox.lua` (compiler wrap) |
| **W4** | **Constants decrypt lazily through a single metatable `__index`.** (Visible in the bootstrap: `setmetatable({}, {__index=…})`.) | One choke point. Trace `string.*` / the constant table and the decrypted constant pool falls out as a side effect. | `sandbox.lua` (tracing string lib) |
| **W5** | **Anti-tamper is a value-poison, not a wall.** The integrity block only flips `D` (`D=5` → `D=20.0`) if a check fails; supply the right `D` or patch the check and it's inert. | Detectable, patchable, side-effect-free. | `peel.py -D`, manual patch |
| **W6** | **External effects are in the clear.** URLs, key endpoints, HWID/whitelist calls all hit real APIs eventually. | Log `HttpGet`/`request`/IO in the sandbox → full behavioural profile without reading a line of VM code. | `sandbox.lua` |
| **W7** | **`debug.*` is often still reachable** in executor contexts. | `debug.sethook` gives a call/line trace of the dispatch loop. | `sandbox.lua` (`TraceCalls`) |
| **W8** | **Toolchain fingerprinting.** `LPH%V` header + `Luraph v14.7` comment pin the exact version, so version-specific templates apply. | — | `peel.py` (header report) |

**What stays hard (be honest):** W1–W8 recover the *encoding*, the
*decrypted stages*, the *string/constant pool*, and the *behaviour*. They do
**not** magically reproduce clean source. The genuinely strong part of
Luraph v14.x is the **virtualised control flow**: per-build randomised
opcodes, merged/inlined handlers, flattened flow. Turning that bytecode back
into readable Lua ("devirtualisation") is a manual, version-specific lift —
this toolkit gives you the captured bytecode and a call trace to start from,
not a finished decompiler.

---

## Tools

### `peel.py` — static outer-layer peeler (safe, no execution)
Reverses the base-85 packing on every `[=[…]=]` stream and writes the raw
bytes. Reports entropy + magic so you can see instantly whether a stage is
plaintext bytecode (`\x1bLuaP`) or still an encrypted stream.

```bash
python3 peel.py sample_sigil.lua -o peeled
```

### `strings.py` — IOC / readable-string triage
Pulls URLs, discord invites, domains, `rbxassetid`, and key-system keywords
out of peeled stages. If a stage is still encrypted it says so.

```bash
python3 strings.py peeled/*.bin
```

### `sandbox.lua` — dynamic capture harness (the powerful one)
Runs the target under an instrumented environment. Network and disk are
**stubbed by default** so a hostile sample can be watched without phoning
home. Captures: every decrypted `loadstring`/`load` stage, the decrypted
string/constant pool, every `HttpGet`/service access, and (optionally) a
`debug.sethook` call trace.

```bash
# plain Lua 5.1 / LuaJIT
lua sandbox.lua target.lua        # dumps to ./lph_dump/

# Roblox executor: set CONFIG.TargetFile, run it, read lph_dump/report.txt
```

> Only set `CONFIG.AllowNetwork = true` inside a throwaway VM. With it off,
> the sample cannot exfiltrate or fetch a second-stage payload.

---

## Typical workflow

1. `peel.py` → get the stages, confirm it's Luraph vX, see how many streams.
2. `strings.py` → cheap behavioural hints if any plaintext survived.
3. `sandbox.lua` → run it stubbed; read `report.txt` for the decrypted
   stages, the string pool, and the network/IO trace. This is usually enough
   to answer *"what does this script actually do."*
4. (Only if you need the logic) hand the captured bytecode + call trace to a
   per-version opcode lifter — the hard, manual step.

## Verified against
The `sample_sigil.lua` in this folder (a Luraph v14.7 build): `peel.py`
recovers all 5 packed streams (headers `LPH%V`, `LPH>&`, …); the main
bytecode stream is ~1.35 MB at entropy ~8.0, confirming the inner keystream
— i.e. static peeling stops exactly where the README says it does, and the
sandbox takes over from there.

## Design lessons for *our* obfuscator
- Never ship a reversible outer encoding as if it were protection (W1).
- Kill single choke points: decrypt constants inline/per-use, not through
  one lazy metatable (W4).
- Bind the decrypt key to the integrity state so tampering corrupts the
  payload *cryptographically*, not via a patchable `if` (W5).
- Assume the attacker owns the environment; real protection is the VM lift
  cost (W2), everything else just buys minutes.
