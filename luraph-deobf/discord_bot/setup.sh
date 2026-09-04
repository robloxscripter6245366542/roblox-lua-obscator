#!/usr/bin/env bash
# ============================================================
#  setup.sh -- automates everything for the discord bot EXCEPT
#  the Discord-website steps (making the app, getting a token,
#  inviting the bot), which can't be scripted. Run this first,
#  then follow the printed next steps.
# ============================================================
set -euo pipefail
cd "$(dirname "$0")"

echo "==> Checking Python"
if ! command -v python3 >/dev/null; then
    echo "python3 not found. Install Python 3.9+ first." >&2
    exit 1
fi
python3 --version

echo
echo "==> Installing Python dependencies"
python3 -m pip install -r requirements.txt

echo
echo "==> Building the Luau runtime (enables dynamic/disasm/lift pipeline stages)"
echo "    (skip with --no-luau if you only want static unpacking)"
if [[ "${1:-}" == "--no-luau" ]]; then
    echo "    skipped (--no-luau passed)"
elif [[ -x ../dynamic/luau ]]; then
    echo "    already built at ../dynamic/luau"
else
    bash ../dynamic/build_luau.sh || echo "    build failed -- bot still works, just without dynamic/disasm/lift stages"
fi

echo
echo "==> Setting up .env"
if [[ -f .env ]]; then
    echo "    .env already exists, leaving it alone"
else
    cp .env.example .env
    echo "    created .env from .env.example -- you MUST edit it and set DISCORD_BOT_TOKEN"
fi

cat <<'EOF'

============================================================
 Done with the scriptable part. What's left (Discord website):

 1. https://discord.com/developers/applications -> New Application
 2. Left sidebar -> Bot -> Reset Token -> copy it
 3. Put that token into .env as DISCORD_BOT_TOKEN=...
 4. OAuth2 -> URL Generator -> scopes: bot, applications.commands
    -> bot permissions: Send Messages, Attach Files
    -> open the generated URL, pick your server, authorize

 Then run the bot:
    export $(grep -v '^#' .env | xargs)
    python3 bot.py

 Full details: README.md
============================================================
EOF
