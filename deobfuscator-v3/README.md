# Linux support

This project now includes native Linux x86_64 builds of **Lune** and **Lute** instead of the original Windows `.exe` files.

## Requirements

For a local Linux run, install Python 3.10 or newer, Node.js 20 or newer, and the Python dependencies:

```bash
python3 -m venv .venv
. .venv/bin/activate
python -m pip install -r requirements.txt
cd v1sexy
npm install --omit=dev
cd ..
```

The Prometheus obfuscator menu also uses the `lua` command, so install Lua 5.1 if that menu option is needed. The bundled `lune` and `lute` files are already executable; if permissions were lost during copying, run:

```bash
chmod +x lune lute
```

Set the Discord settings in `.env`. On Linux, `HOOKOP_BIN` should be `lute`, not `lute.exe`.

## Run

Use the interactive menu with:

```bash
python3 bot.py
```

To start the Discord bot directly:

```bash
python3 bot.py bot
```

To run the command-line router directly:

```bash
python3 router.py input.lua output.lua
```

## Engines

The router auto-detects which of three engines a script needs, or you can force
one with a flag:

| Engine   | Handles                                  | Force flag  |
| -------- | ---------------------------------------- | ----------- |
| `envlog` | generic / wearedevs — Luau env logger    | `--envlog`  |
| `prom`   | Prometheus output                        | `--prom`    |
| `luraph` | Luraph `LPH` / v13–v15 packed scripts    | `--luraph`  |

The `luraph` engine drives the sibling **`luraph-deobf/`** toolkit (kept in the
repo root; override its location with the `LURAPH_DIR` env var). Its static
stages (fingerprint / peel / anti-tamper) need only Python; the dynamic stages
additionally need a `luau` binary — build one with
`bash ../luraph-deobf/dynamic/build_luau.sh`. For v13/v14.x it emits a
behaviour-identical runnable unpack; for v15 (key-encrypted bytecode) it emits
an analysis report explaining what a dynamic capture would still need.

## Docker

The Dockerfile installs the Linux Lune runtime, copies the native `lute` binary, installs the Python and Node dependencies, and starts the bot with:

```bash
docker compose up --build -d
```

Keep `.env` private because it contains the Discord token and channel configuration.

## Portability details

The Python launcher retains its Windows fallback logic, but Linux selects the extensionless `lune` and `lute` binaries. Process-tree termination uses `taskkill` on Windows and process groups on Linux. The bot also imports `asyncio` explicitly so its queue can be initialized correctly on a clean Linux installation.

The native runtime files were obtained from the official releases of [Lune](https://github.com/lune-org/lune/releases/tag/v0.8.9) and [Lute](https://github.com/luau-lang/lute/releases/tag/v1.0.0).
