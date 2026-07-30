#!/usr/bin/env bash
# Run every Ez Hub Lua script through the headless mock harness.
# Requires: python3 with lupa  (pip install lupa)
set -u
cd "$(dirname "$0")/../.." || exit 1

scripts=(
  "Ez-Hub/Modules/EzLib.lua"
  "Ez-Hub/EzUI.lua"
  "Ez-Hub/NovaUI.lua"
  "Ez-Hub/NovaHub.lua"
  "Ez-Hub/EzHubAcrylic.lua"
  "Ez-Hub/Scripts/Doors.lua"
  "Ez-Hub/Scripts/Rivals.lua"
)

python3 Ez-Hub/test/run.py "${scripts[@]}"
