#!/usr/bin/env bash
# Run the Fire Hub ("Strongest") — or any Roblox Luau script — inside the TSB
# simulator and print any runtime errors it hits.
#
#   sim/run.sh                 # runs against ../Strongest
#   sim/run.sh path/to/file    # runs against another script
set -euo pipefail
here="$(cd "$(dirname "$0")" && pwd)"
root="$(cd "$here/.." && pwd)"
luau="$root/luraph-deobf/dynamic/luau"
if [ ! -x "$luau" ]; then
    echo "Luau CLI not found — building it (one-time)…"
    bash "$root/luraph-deobf/dynamic/build_luau.sh"
fi
target="${1:-$root/Strongest}"
cat "$here/prelude.lua" "$target" "$here/driver.lua" > "$here/combined.lua"
exec "$luau" "$here/combined.lua"
