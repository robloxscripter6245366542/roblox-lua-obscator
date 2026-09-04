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
pip install -r requirements.txt

# Optional but recommended -- enables the dynamic/disasm/lift stages.
# Without this, the bot still works: report.md just marks those stages skipped.
bash ../dynamic/build_luau.sh

cp .env.example .env   # fill in DISCORD_BOT_TOKEN, then load it into the
                        # environment however your process manager does
                        # (systemd EnvironmentFile=, docker --env-file, etc.)
python3 bot.py
```

Discord Developer Portal setup: create an application, add a bot user, grant
it the `applications.commands` and `bot` scopes with the "Send Messages" and
"Attach Files" permissions when generating the invite URL. No privileged
gateway intents are needed — this bot only handles slash-command interactions.

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
- `requirements.txt` — `discord.py`.
- `.env.example` — configuration reference.
