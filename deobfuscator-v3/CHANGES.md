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
