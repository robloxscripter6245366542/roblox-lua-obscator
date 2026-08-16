#!/usr/bin/env bash
# Build [harness + phantom_ballz.lua + epilogue] into one Luau chunk and run it
# under the Luau CLI, in both "fresh" and "restore" modes.
set -euo pipefail
HERE="$(cd "$(dirname "$0")" && pwd)"
REPO="$(cd "$HERE/../../.." && pwd)"
LUAU="${LUAU:-/tmp/claude-0/-home-user-roblox-lua-obscator/3d055537-497b-5f25-bf17-223f476e394f/scratchpad/luau-src/build/luau}"
PHANTOM="$REPO/user_scripts/phantom_ballz.lua"
OUT="$(mktemp -d)"

build() {
  local mode="$1" seed="$2" dest="$3"
  {
    echo "_MODE = \"$mode\""
    cat "$HERE/harness.luau"
    if [ -n "$seed" ]; then
      echo "_DISK[\"Leviathan/Phantom_config.json\"] = '$seed'"
      echo "_FOLDERS[\"Leviathan\"] = true"
    fi
    cat "$PHANTOM"
    cat "$HERE/epilogue.luau"
  } > "$dest"
}

build fresh   "" "$OUT/fresh.luau"
build restore '{"spam":true,"vis":false,"fx":false}' "$OUT/restore.luau"

rc=0
for f in fresh restore; do
  echo "----------------------------------------------------------------"
  "$LUAU" "$OUT/$f.luau" || rc=$?
done
echo "----------------------------------------------------------------"
rm -rf "$OUT"
exit $rc
