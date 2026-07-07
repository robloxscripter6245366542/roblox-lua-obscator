# MoonSec obfuscation CLI

Runs a Lua source file through the [MoonSec REST API](https://cmoonm4n.gitbook.io/moonsec-obfuscator/moonsec-rest-api-docs)
(free tier) and saves the obfuscated result. This is an alternative to the
custom XOR/base64 wrapper in `obfuscate.lua` — MoonSec does real bytecode-level
obfuscation (string/constant encryption, anti-dump, VM bytecode styles) instead
of just wrapping the source.

## Setup

Get a free API key from MoonSec, then either export it or pass it per-call:

```bash
export MOONSEC_API_KEY="your-key-here"
```

## Usage

```bash
# Uses Full_Combined_source.lua by default, writes Full_Combined_source.moonsec.lua
npm run obfuscate:moonsec

# Explicit input/output
node scripts/moonsec_obfuscate.js -i user_scripts/anime_ball_autoparry.lua -o user_scripts/anime_ball_autoparry.moonsec.lua

# Target Roblox specifically, pick a bytecode style, tweak options
node scripts/moonsec_obfuscate.js -i src.lua --platform roblox --bytecode 3 \
  --options "StringEncryption+ConstantEncryption+AntiDump+SmallOutput"
```

Run `node scripts/moonsec_obfuscate.js --help` for the full flag list.

## Options reference

| Flag | Values | Default | Notes |
|------|--------|---------|-------|
| `--platform` | `lua`, `roblox`, `csgo` | `lua` | `lua` targets universal Lua (excludes Roblox APIs); use `roblox` for Roblox-only scripts |
| `--bytecode` | `0`-`6` | `2` | Bytecode glyph style (Arabic, Letters, Symbols, Russian, Whitespace, Chinese, Emoji) |
| `--options` | `+`-joined toggles | `StringEncryption+ConstantEncryption+AntiDump` | Also available: `SmallOutput` |

## Limits (free tier)

- 1 obfuscation request per 5 seconds (the CLI auto-retries on HTTP 429, up to `--retries`, default 3)
- Script size must be between 1 byte and 8MB
- A 403 means the API key is missing or invalid

## Notes

- The API key is never written to disk by this tool — pass it via `MOONSEC_API_KEY` or `--key`.
- Combine with `PROTECTION_SETUP.md`'s key+HWID gating for both code protection and access control.
