# luraph-deobf

A small, **honest** toolkit for analysing and unpacking Luraph-protected
Lua/Luau scripts (targets v13 / v14.x, e.g. the `LPH%V` / `-- Luraph
Obfuscator v14.7` family). Built as reference material for this repo's
obfuscator work: *knowing exactly where an obfuscator leaks is how you
build one that doesn't.*

> **v15 (Aug 2026) is a ground-up rewrite** — dual OPAL/ONYX VMs, a new
> `LPH_ATTRIBUTES` macro system, MBA rewriting (`LPH_REWRITE`), and
> **`LPH_PRECHECK`, which key-encrypts the bytecode with a runtime value** and
> so breaks the "always keyless / fully static" property below. The
> fingerprint stage now detects v15 and reports which stages still apply; the
> byte-level format is auto-probed rather than assumed. Full analysis and the
> "needs a real sample" checklist: **[`v15.md`](v15.md)**.

It is a **reverse-engineering / security-research** tool. Use it on samples
you are authorised to analyse (your own builds, malware triage, CTF, or
studying a technique). It is not a "steal someone's paid script" button —
and, importantly, it *can't* be: see the honest-scope note at the bottom.

---

## Staged deobfuscator (`deobfuscate.py`) — start here

One entry point that runs the full methodology as explicit, ordered stages and
**regenerates everything build-specific per sample** (opcode map included —
Luraph randomises it every build):

```bash
bash dynamic/build_luau.sh                      # once
python3 deobfuscate.py sample.lua -o out        # -> out/report.md + artifacts
```

Stages: **0** fingerprint (version + LPH streams) · **1** peel (base-85 → LZMA,
keyless) → VM source + bytecode · **2** locate/neutralise the anti-tamper
probe · **3** dynamic instrumentation in a stubbed Luau env — control-flow
census, **per-build opcode map** (register-delta), concrete constant capture,
behaviour · **4–5** disassemble + lift using *this build's* map · **+** emit
`unpacked_runnable.lua`. Outputs: `peeled/`, `opcodes.json` (per-build),
`values.txt`, `lifted.lua`, `unpacked_runnable.lua`, `report.md`.

(Prefer this over `pipeline.py`, which used the committed sigil map rather than
regenerating one — wrong opcodes on any other build.)

## Runnable unpacking (`unpack_runnable.py`)

Two distinct "deobfuscation" goals — pick the one you actually want:

- **Readable analysis** (`devirt/lift.py`) — register-level Lua you *read*, not
  run. Best for understanding logic.
- **Unpacked but RUNNABLE** (`unpack_runnable.py`) — strips the base-85 +
  LZMA + anti-tamper shell and re-emits a **self-contained script that runs
  identically**, with the VM interpreter now exposed as plain readable source
  (the program logic stays VM bytecode). Verified: the emitted file errors at
  the *exact same* point as the original when run outside Roblox — i.e.
  behaviour-identical.

```bash
python3 unpack_runnable.py sample.lua -o unpacked_runnable.lua
```

## One-command pipeline

`pipeline.py` runs every stage against a sample and writes a consolidated
`report.md` (unpack → IOCs → constant pool → behaviour → disassembly →
opcode histogram → annotated listing → status):

```bash
bash dynamic/build_luau.sh                    # once: builds dynamic/luau
python3 pipeline.py sample_sigil.lua -o out   # -> out/report.md
```

Static stages run without `luau`; the dynamic stages (constant pool,
behaviour, disassembly) use it and are skipped with a note if it's absent.
What's fully automated vs. the remaining manual "last mile" (the per-build
opcode→source lift) is spelled out in the report's status table and in
`devirt/README.md`.

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
>
> **v15 caveat (measured on a real v15.0 sample):** this holds for v13/v14.x
> only. v15 drops the LZMA layer entirely — the `[=[LPH…]=]` stream is a
> per-build **char-substitution map + base-85** → `buffer.fromstring`, and the
> resulting VM buffer is **XOR-stream-encrypted at rest, decrypted byte-by-byte
> at runtime** (`bit32.bxor` in the `readu8` path). So a static peel recovers
> the *buffer* but not readable bytecode — recovery moves to the runtime path
> (`dynamic/`). `LPH_PRECHECK` can further bind that key to platform values
> (e.g. `game.PlaceId`). See [`v15.md`](v15.md) and `sample_v15.lua`.

| #  | Weakness | Why it leaks | Tool |
|----|----------|--------------|------|
| **W1** | **Outer packing is reversible encoding, not encryption.** The `[=[LPH…]=]` streams are a base-85 (Ascii85) variant + a `z` zero-run shorthand + a fixed `D`-char header. No key. | Any encoding without a runtime-derived key peels offline. | `peel.py` |
| **W1b** | **The "inner encryption" is just LZMA compression.** The bootstrap ships a pure-Lua LZMA range decoder; the high entropy was compression, not a cipher. Keyless. | `python`'s `lzma` decodes the raw stream → VM source + bytecode, statically. | `peel.py` |
| **W2** | **Code owns no environment; you do.** It must run in a real Lua VM and call real `string.*`, `game:HttpGet`, globals, metatables. | Replace the environment with instrumented copies and every real effect is observable. | `sandbox.lua` |
| **W3** | **Program strings live in a VM constant table decoded at runtime.** | Run the interpreter's constant decoder (or the sandbox) to recover URLs/keys the static `strings` pass can't. | `sandbox.lua` |
| **W5** | **Anti-tamper is a value-poison, not a wall.** The integrity block only flips `D` (`D=5` → `D=20.0`) if a check fails; supply the right `D` or patch the check and it's inert. | Detectable, patchable, side-effect-free. | `peel.py -D`, manual patch |
| **W6** | **External effects are in the clear.** URLs, key endpoints, HWID/whitelist calls all hit real APIs eventually. | Log `HttpGet`/`request`/IO in the sandbox → full behavioural profile without reading a line of VM code. | `sandbox.lua` |
| **W7** | **`debug.*` is often still reachable** in executor contexts. | `debug.sethook` gives a call/line trace of the dispatch loop. | `sandbox.lua` (`TraceCalls`) |
| **W8** | **Toolchain fingerprinting.** `LPH%V` header + `Luraph v14.7` comment pin the exact version, so version-specific templates apply. On v15, `LPH_ATTRIBUTES`/`VM(OPAL\|ONYX)` artifacts and the version comment fingerprint the rewrite + which ISA a function uses. | — | `deobfuscate.py` (`fingerprint()`), `peel.py` (header report) |

**What stays hard (be honest):** W1–W8 recover the *encoding*, the
*decompressed VM source*, the *bytecode*, and the *behaviour*. They do
**not** by themselves reproduce the original program as clean source. The
genuinely strong part of Luraph v14.x is the **virtualised control flow**:
the interpreter is control-flow-flattened and the bytecode is a custom
tagged encoding. Lifting it back to Lua ("devirtualisation") is still a
manual project — but it is no longer *blind*, because the interpreter is now
in front of you as source. `devirt.md` lays out the roadmap and where the
dispatch core lives.

**v15 raises this bar further:** two ISAs (OPAL/ONYX) mean the opcode map is
per-VM-type as well as per-build, arithmetic may be MBA-rewritten
(`LPH_REWRITE`), and functions can be inlined/unrolled or AST-obfuscated while
*non*-virtualized (`TRANSFORM`). The lift roadmap still applies per ISA; see
[`v15.md`](v15.md) for the delta and what a real v15 sample is needed to pin
down.

---

## Tools

### `peel.py` — static unpacker (safe, no execution)
Reverses **both** keyless layers on every `LPH…` stream: an outer encoding
(base-85 or base64 — auto-detected), then raw LZMA1 if present. Writes
`stage_N.lua` when a stage decompresses to Lua source and `stage_N.bin` for
bytecode, and labels each. `--no-lzma` stops after the outer encoding.

Finds `LPH…` streams both as original-source long-bracket strings
(`[=[LPH…]=]`) and as plain quoted string literals (`"LPH…"`) — the shape
an executor decompiler re-emits them as (e.g. `v830("LPH}!!M...")` in
GameCodeDumper output) — same payload, different quoting; verified
byte-identical against a live runtime decode on a real sample.

Handles two variant shapes beyond the original base-85+LZMA case, both
covered by synthetic round-trip tests (base64 auto-detection only trusts a
strong signal — a clean LZMA decode or directly-readable output — never a
weak heuristic, since base64 decoding rarely errors even on wrong input):
- **base64 instead of base-85** for the outer layer.
- **No compression layer at all** — the outer-decoded bytes are already
  the final Lua source or bytecode, no LZMA needed.

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

### `goto_fix.py` — make GameCodeDumper decompiler output runnable under Luau
Executor decompilers (what `GameCodeDumper.lua` calls via `decompile()`)
reconstruct control flow as Lua 5.x-style `goto`/`::label::`, which Luau
doesn't support at all — the decompiled VM interpreter source fails to
compile until every goto/label is gone. `goto_fix.py` lowers each region
that uses them to a flat CFG of basic blocks and emits it as a
`local pc = N; while true do ... end` dispatch loop (hoisting locals so they
survive across states, handling nested closures/loops/`continue`, and using
a balanced dispatch tree so deep VMs don't blow Luau's parser recursion
limit). Regions with no goto/label are left untouched.

```bash
python3 goto_fix.py decompiled_script.lua -o fixed.lua
```

Verified end-to-end on a real Luraph-obfuscated VM interpreter dumped from
a live game (a ~3,500-line decompiled script with 1,147 dispatch states):
`fixed.lua` compiled and ran cleanly under real Luau with zero syntax
errors. Note this only fixes goto/label — unrelated decompiler artifacts
(e.g. a trailing `-- name: X` comment swallowing a function's `end`) are a
separate class of bug and still need their own fix.

### `devirt.md`
The deep writeup: the full bootstrap chain, the bytecode-format
observations, and the step-by-step roadmap for lifting the bytecode using
the now-recovered interpreter source.

### `dynamic/` — run the recovered VM under real Luau
`dynamic/run.py` executes the sample in a real Luau runtime inside a
stubbed, network-blocked environment and logs everything it does — HttpGet
URLs, config, method calls. It self-unpacks and boots the VM, and its stub
**satisfies the W5 anti-tamper** (the `loadstring` second-return-value probe
— see `dynamic/README.md`). Verified capture on the sample: the SigilUI URL,
the Discord, the key filename, the shop funnel, and `LaunchJunkie{Service=Mm,
Identifier=1027906}`. `dynamic/build_luau.sh` builds the Luau CLI it needs.

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
  payload *cryptographically*, not via a patchable `if` (W5). **v15 does
  exactly this** with `LPH_PRECHECK` (the check's return value keys the
  bytecode) — this is the single most important upgrade to copy, because it
  converts our biggest static leak into a runtime-only recovery.
- Decode program strings per-use, not into one recoverable constant table
  (W3). v15's per-macro user keys on `LPH_ENCSTR/ENCNUM/ENCBUF` push in this
  direction.
- Ship more than one ISA and pick per function (v15 OPAL/ONYX): it multiplies
  the per-build, now per-VM-type, cost of the opcode-map lift.
