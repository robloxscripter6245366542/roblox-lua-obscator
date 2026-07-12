#!/usr/bin/env bash
# luau_differential.sh — prove the EMITTED (hardened) script runs on real Luau.
#
# Compilation runs on lua5.4 (the build step, exactly as the browser/build does);
# EXECUTION of both the original program and the hardened bundle happens on a real
# Luau interpreter, and their stdout is diffed. This is the test that answers
# "does the output actually run in Roblox Luau?" empirically rather than by
# assertion — the whole toolchain (compiler → serializer → VM interpreter) must
# agree on the bytecode format, and the runtime must use only Luau-available
# features (getfenv/_ENV/_G fallback, bit32, table.pack/unpack, string.format).
#
# Requires a Luau CLI. Point LUAU at it (open-source luau, lune, or an mlua-built
# runner). Roblox Luau additionally provides getfenv and script-scoped globals,
# both handled by the emitted env-resolution line.
#
#   LUAU=/path/to/luau  bash test/luau_differential.sh [count] [seedbase]
set -euo pipefail

LUAU="${LUAU:?set LUAU to a Luau interpreter binary}"
N="${1:-200}"
BASE="${2:-5000}"
here="$(cd "$(dirname "$0")/.." && pwd)"
tmp="$(mktemp -d)"; trap 'rm -rf "$tmp"' EXIT

# generate N fuzzer programs (reuse the differential fuzzer's generator)
awk '/-- ── driver/{exit} {print}' "$here/test/fuzz.lua" > "$tmp/gen.lua"
cat >> "$tmp/gen.lua" <<'LUA'
local N,base,dir=tonumber(arg[1]),tonumber(arg[2]),arg[3]
for i=1,N do
  local src=makeGen(RNG(base+i))()
  local f=assert(io.open(string.format('%s/g%04d.luau',dir,i),'w')); f:write(src); f:close()
end
LUA
( cd "$here" && lua5.4 "$tmp/gen.lua" "$N" "$BASE" "$tmp" )

pass=0; fail=0; berr=0
for f in "$tmp"/g*.luau; do
  exp="$("$LUAU" "$f" 2>&1 || true)"
  if ! ( cd "$here" && lua5.4 tools/bundle.lua "$f" 7 ) > "$tmp/out.lua" 2>/dev/null; then
    berr=$((berr+1)); continue
  fi
  got="$("$LUAU" "$tmp/out.lua" 2>&1 || true)"
  if [ "$exp" = "$got" ]; then pass=$((pass+1)); else
    fail=$((fail+1)); [ "$fail" -le 3 ] && printf 'DIFF %s\n  exp: %s\n  got: %s\n' "$(basename "$f")" "$exp" "$got"
  fi
done
echo "luau_differential: $pass matched, $fail differed, $berr bundle-errors (of $N) on $("$LUAU" --version 2>/dev/null || echo Luau)"
[ "$fail" -eq 0 ] && [ "$berr" -eq 0 ]
