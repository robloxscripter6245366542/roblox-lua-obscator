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
top are packing, compression, and anti-tamper. Here is where each layer is
weak and which tool addresses it.

> **Headline finding (v14.7):** the outer protection uses **no cryptographic
> key**. The packed `[=[LPH…]=]` streams are `base-85 → LZMA1(lc3,lp0,pb0)`,
> both fully reversible offline. So the whole thing unpacks *statically* to
> the **VM interpreter source** + the **bytecode** — no runtime needed.
> See `devirt.md`.

| #  | Weakness | Why it leaks | Tool |
|----|----------|--------------|------|
| **W1** | **Outer packing is reversible encoding, not encryption.** The `[=[LPH…]=]` streams are a base-85 (Ascii85) variant + a `z` zero-run shorthand + a fixed `D`-char header. No key. | Any encoding without a runtime-derived key peels offline. | `peel.py` |
| **W1b** | **The "inner encryption" is just LZMA compression.** The bootstrap ships a pure-Lua LZMA range decoder; the high entropy was compression, not a cipher. Keyless. | `python`'s `lzma` decodes the raw stream → VM source + bytecode, statically. | `peel.py` |
| **W2** | **Code owns no environment; you do.** It must run in a real Lua VM and call real `string.*`, `game:HttpGet`, globals, metatables. | Replace the environment with instrumented copies and every real effect is observable. | `sandbox.lua` |
| **W3** | **Program strings live in a VM constant table decoded at runtime.** | Run the interpreter's constant decoder (or the sandbox) to recover URLs/keys the static `strings` pass can't. | `sandbox.lua` |
| **W5** | **Anti-tamper is a value-poison, not a wall.** The integrity block only flips `D` (`D=5` → `D=20.0`) if a check fails; supply the right `D` or patch the check and it's inert. | Detectable, patchable, side-effect-free. | `peel.py -D`, manual patch |
| **W6** | **External effects are in the clear.** URLs, key endpoints, HWID/whitelist calls all hit real APIs eventually. | Log `HttpGet`/`request`/IO in the sandbox → full behavioural profile without reading a line of VM code. | `sandbox.lua` |
| **W7** | **`debug.*` is often still reachable** in executor contexts. | `debug.sethook` gives a call/line trace of the dispatch loop. | `sandbox.lua` (`TraceCalls`) |
| **W8** | **Toolchain fingerprinting.** `LPH%V` header + `Luraph v14.7` comment pin the exact version, so version-specific templates apply. | — | `peel.py` (header report) |

**What stays hard (be honest):** W1–W8 recover the *encoding*, the
*decompressed VM source*, the *bytecode*, and the *behaviour*. They do
**not** by themselves reproduce the original program as clean source. The
genuinely strong part of Luraph v14.x is the **virtualised control flow**:
the interpreter is control-flow-flattened and the bytecode is a custom
tagged encoding. Lifting it back to Lua ("devirtualisation") is still a
manual project — but it is no longer *blind*, because the interpreter is now
in front of you as source. `devirt.md` lays out the roadmap and where the
dispatch core lives.

---

## Tools

### `peel.py` — static unpacker (safe, no execution)
Reverses **both** keyless layers on every `LPH…` stream: base-85, then raw
LZMA1. Writes `stage_N.lua` when a stage decompresses to Lua source and
`stage_N.bin` for bytecode, and labels each. `--no-lzma` stops after base-85.

```bash
python3 peel.py sample_sigil.lua -o peeled
#   peeled/stage_0.lua  <- the VM interpreter, readable source
#   peeled/stage_1.bin  <- the VM bytecode program
```

### `strings.py` — IOC / readable-string triage
Pulls URLs, discord invites, domains, `rbxassetid`, and key-system keywords
out of any stage. On the raw bytecode it surfaces the plaintext that
survives (Luraph's own runtime messages); the program's own strings need the
constant decoder / sandbox.

```bash
python3 strings.py peeled/stage_1.bin
```

### `sandbox.lua` — dynamic capture harness
Runs the target under an instrumented environment. Network and disk are
**stubbed by default** so a hostile sample can be watched without phoning
home. Captures: every `loadstring`/`load` stage, the string/constant pool as
the VM touches it, every `HttpGet`/service access, and (optionally) a
`debug.sethook` call trace. Its job is the *program's* runtime strings and
behaviour — the packing is already handled statically by `peel.py`.

```bash
# plain Lua 5.1 / LuaJIT
lua sandbox.lua target.lua        # dumps to ./lph_dump/

# Roblox executor: set CONFIG.TargetFile, run it, read lph_dump/report.txt
```

> Only set `CONFIG.AllowNetwork = true` inside a throwaway VM. With it off,
> the sample cannot exfiltrate or fetch a second-stage payload.

### `devirt.md`
The deep writeup: the full bootstrap chain, the bytecode-format
observations, and the step-by-step roadmap for lifting the bytecode using
the now-recovered interpreter source.

---

## Typical workflow

1. `peel.py` → unpack statically to VM source (`stage_0.lua`) + bytecode
   (`stage_1.bin`). Read the source directly.
2. `strings.py` → plaintext triage over the bytecode.
3. `sandbox.lua` → run stubbed to recover the *program's* runtime strings
   (URLs/keys) and its network/IO behaviour.
4. `devirt.md` → follow the roadmap to lift the bytecode to Lua (the one
   remaining hard step; no longer blind).

## Verified against
`sample_sigil.lua` in this folder (a Luraph v14.7 build). `peel.py` recovers
the **2** real `LPH` streams and unpacks them fully:
- stage 0: 25,876 B → **99,942 B of Lua source** (the VM interpreter).
- stage 1: 1,347,424 B → **2,363,120 B of bytecode**.

`strings.py` on the bytecode surfaces Luraph's own runtime messages. The
`[[…]]` "streams" a naïve scan reports are false positives inside the encoded
data — the `LPH` header filter drops them.

## Design lessons for *our* obfuscator
- Never ship a reversible outer encoding/compression as if it were
  protection — no key means fully static recovery (W1/W1b).
- Ship the interpreter *itself* obfuscated only via flattening/renaming and
  an attacker eventually reads it; the real cost is the VM lift, so invest
  there (per-build opcode shuffling, handler merging) not in the packing.
- Bind any integrity check into the decode key so tampering corrupts the
  payload *cryptographically*, not via a patchable `if` (W5).
- Decode program strings per-use, not into one recoverable constant table
  (W3).
