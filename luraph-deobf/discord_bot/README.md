# luraph-deobf Discord bot

A thin Discord front-end over `../pipeline.py`. One slash command:

```
/deobfuscate file:<upload a .lua>
```

It runs the full pipeline (static unpack -> IOC triage -> dynamic constant
pool + behaviour capture -> disassembly -> opcode annotation -> lift to
register-level Lua) and replies with `report.md` plus whichever artifacts
came out of it (`stage_0.lua`, `lifted.lua`, `disasm.txt`) as attachments.

## What this can and can't do

- **Static unpack + IOC triage**: works on any v13/v14.x sample, no caveats.
- **Dynamic constants/behaviour**: needs the `luau` binary (see Setup below).
  Runs the sample for real inside `dynamic/run.py`'s sandboxed, network-blocked
  environment.
- **Disassembly / opcode annotation / lift-to-Lua**: also needs `luau`, and is
  build-specific — `devirt/opcodes.json` was reverse-engineered against one
  Luraph build. A script from a *different* build can have its opcodes
  renumbered, so the lift output for such a sample may be partial or wrong.
  `report.md`'s own "Status" table is honest about what actually ran and
  what got skipped for a given input — read that before trusting `lifted.lua`.
- v15 samples with key-bound bytecode (`LPH_PRECHECK`) can't be fully
  unpacked statically at all; see `../v15.md`.

## Setup

```bash
cd luraph-deobf/discord_bot
bash setup.sh          # installs deps, builds luau, creates .env
                        # (pass --no-luau to skip the luau build)
```

That handles everything scriptable. What's left is on Discord's website:

1. https://discord.com/developers/applications -> **New Application**.
2. Left sidebar -> **Bot** -> **Reset Token** -> copy it (you only see it once).
3. Put it in `.env` as `DISCORD_BOT_TOKEN=...`.
4. **OAuth2** -> **URL Generator** -> scopes: `bot`, `applications.commands`;
   bot permissions: **Send Messages**, **Attach Files** -> open the generated
   URL, pick your server, authorize. No privileged gateway intents needed —
   this bot only handles slash-command interactions.

Then run it:

```bash
export $(grep -v '^#' .env | xargs)   # or load .env via your process
                                        # manager (systemd EnvironmentFile=,
                                        # docker --env-file, etc.)
python3 bot.py
```

You should see `logged in as <YourBot>#0000` in the console once it's up.

## Operational notes (read before exposing this publicly)

This executes arbitrary user-submitted Lua under a real Luau interpreter.
`dynamic/run.py`'s harness already blocks the sample's own network access,
but the bot process itself still spends real CPU/RAM per job. Run it on
something disposable (a small VM or container), not your main host, and
keep the guardrails in `.env.example` sane for your hardware:

- `MAX_CONCURRENT_JOBS` caps how many pipeline runs execute at once.
- `JOB_TIMEOUT_SECONDS` hard-kills a run that hangs.
- `MAX_UPLOAD_BYTES` / `MAX_ATTACH_BYTES` bound input/output size.
- `COOLDOWN_SECONDS` rate-limits repeat calls per user.

For stronger isolation than a bare timeout, run the whole bot inside a
container with a memory limit and no outbound network access — the sample
never needs the network to be analyzed, so there's no reason the bot's own
host should offer it any.

## Files

- `bot.py` — the bot itself.
- `setup.sh` — one-shot install/build/configure script; run this first.
- `requirements.txt` — `discord.py`.
- `.env.example` — configuration reference.
