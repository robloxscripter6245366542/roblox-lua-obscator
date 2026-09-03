# Changes

Imported the v3 (`6Vms`) Luau environment-logger / deobfuscator into the repo
and fixed the bugs found while running it end-to-end on the Linux `lune`/`lute`
runtime.

## Bug fixes

### 1. Crash instead of a clean error when the script fails to compile
`aspect.dumpfile` called `coroutine.create(chunk)` even when the obfuscated
script failed to load, so `chunk` was `nil` and the run died with the confusing
internal error:

```
-- terminated [string "main"]:16057: invalid argument #1 to 'create' (function expected, got nil)
```

The compile step is now guarded: when the payload cannot be loaded, the engine
records the reason and skips execution instead of crashing.

### 2. Load failures were reported to the user as successful dumps
`router.py` (and therefore the Discord bot) treated any produced output file as
success, detecting engine failure only via a leading `--err` line that
`main.luau` **never actually emitted**. A script that failed to compile came
back as a header-only "dump" that looked fine.

`main.luau` now writes a single `--err <reason>` marker line at the top of the
output on a total load failure, and `router.py` parses just that line, so the
router/bot report the real reason.

### 3. Empty failure reason
`luau.load` returns a rich error object whose `tostring` includes a full
`stack traceback:`, and `cleanpath()` deliberately blanks any text containing a
traceback — so every load-failure reason came out empty. The message before the
traceback is now kept, giving useful output such as:

```
--err failed to compile obfuscated script: syntax error: [string "script"]:1: Expected identifier when parsing expression, got '='
```

## New: Luraph engine wired into the router

The repo already had a working Luraph unpacker in `../luraph-deobf/`, but the
unified router only knew two engines (`envlog`, `prom`). Luraph (the `LPH` /
`Luraph Obfuscator v13–v15` family) is now a first-class third engine:

- **Detection** — `router.detect()` recognises Luraph by its banner, its
  `[=[LPH…` / `[==[LPH…` packed-stream headers, and its `LPH_*` v15 macros,
  and routes those scripts to `luraph`. It is checked *before* Prometheus so an
  LPH payload never falls through to the generic engine.
- **Engine** — `router.run(engine="luraph")` drives the `luraph-deobf` staged
  pipeline (fingerprint → peel → anti-tamper, plus the dynamic stages when a
  `luau` binary is present) and `unpack_runnable.py`, then composes a single
  self-describing `.lua`: the analysis report as `--` comments followed by the
  richest recovered artifact — a behaviour-identical runnable unpack (v13/v14.x)
  or the peeled VM source. On v15 (where the bytecode is key-encrypted at rest)
  it emits the analysis with an honest note that a dynamic capture is needed.
- **CLI / bot** — `router.py --luraph`, the interactive `force engine` prompt,
  the Discord `.luraph` command, and the `.d` engine-picker all expose it.
- The toolkit is located as a sibling `luraph-deobf/` (override with the
  `LURAPH_DIR` env var).

### Deep mode — full v13/v14 devirtualization

The Luraph engine now has two tiers:

- **fast** (default) — static peel + a behaviour-identical runnable unpack.
  Kept fast (~2 s) even after a `luau` binary is built, via a new `--static`
  flag on `luraph-deobf/deobfuscate.py`.
- **deep** (`router.py … --deep`) — runs the dynamic stages under real Luau:
  boot the VM, build this build's opcode map (register-delta + census),
  capture concrete constants/behaviour, disassemble, and **lift the bytecode
  to readable register-level Lua** (`lifted.lua`). Verified on the bundled
  `sample_sigil.lua` (Luraph v14.7): 91 protos / 9,179 instructions, 97 %
  opcodes resolved, 1,113 concrete values inlined; the dynamic behaviour
  capture also recovered the real `HttpGet` URL and UI config.

Deep mode needs a one-time build: `bash luraph-deobf/dynamic/build_luau.sh`
(git, cmake, a C++ compiler). The resulting `luau` binary and its `luau-src/`
checkout are gitignored. Without it, `--deep` reports that it needs the build;
fast mode is unaffected.

### v15: state of public tooling (searched)

I searched GitHub/the web for a working Luraph **v15** deobfuscator to lean on.
Findings (Sep 2026): there is **no public tool that fully deobfuscates v15**.
By design — v15's `LPH_PRECHECK` key-encrypts the bytecode with a runtime
value, so full recovery requires a dynamic key capture, not a static pass.
Closest references, none v15-complete:

- `mehCake/luraph-deobfuscator-py` — active, symbolic-execution approach, but
  its README states "NOT WORKING, CURRENTLY BEING WORKED ON"; no v15 claim.
- `PhoenixZeng/LuraphDeobfuscator` (TheGreatSageEqualToHeaven) — established,
  targets older versions.
- `taherfuzan-creator/Luraph-Deobf` — explicitly "NO SUPPORT V15 LURAPH".

So v15 stays at the honest analysis + partial-peel tier; the path forward is
this repo's own `luraph-deobf/dynamic/` (runtime capture), documented in
`luraph-deobf/v15.md`, not an off-the-shelf tool.

### Also fixed: wearedevs mis-detection

wearedevs output opens with `return(function(...)` plus a string table, so it
scored as Prometheus and auto-detect sent it (and the bundled sample) to the
`prom` engine. `detect()` now treats the `wearedevs` banner as an unambiguous
"not Prometheus" signal and routes it to the env logger.

## What is intentionally not committed

`.gitignore` keeps these out of the repo:

- `.env` — contains the real Discord token; use `.env.example` as a template.
- `lune` / `lute` — the ~35 MB native Luau runtimes. Download them from the
  official releases linked in `README.md` and drop them in this folder.
- `.venv/`, `node_modules/`, `__pycache__/`, `.cache/` — dependency trees.
- `v1sexy/samples/` — the large local sample corpus.
- Runtime output (`core/io/dumped_output.lua`, `core/misc/*.txt`, `bot_tmp/`).

## Running

```bash
python3 -m venv .venv && . .venv/bin/activate
python -m pip install -r requirements.txt
cd v1sexy && npm install --omit=dev && cd ..
chmod +x lune lute          # after downloading the runtimes
python3 router.py core/io/obfuscated.lua out.lua
```
