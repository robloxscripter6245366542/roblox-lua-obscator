# Ez Hub test sandbox

A headless harness for testing the Ez Hub Lua scripts **without Roblox**. It runs
each script under a real Lua VM (via `lupa`) inside a **mock Roblox + Luau
environment**, so bugs that a syntax check can't see get caught before they ship.

## What it does

1. Installs a fake Roblox API — `game`, services, `Instance.new`, signals,
   `Enum`, `Vector2/3`, `CFrame`, `UDim2`, `Color3`, `task.*`, `typeof`,
   `TweenService:Create`, executor globals (`gethui`, `Drawing`, `mouse1click`,
   `fireproximityprompt`, `loadstring`, …) and the Luau stdlib extras
   (`math.clamp`, `math.round`, …).
2. **Load test** — executes the whole script and reports the exact error + line
   if it crashes while building its UI.
3. **Callback test** — fires every connected signal once (button clicks,
   toggles, input handlers, the aimbot/ESP render loops) with a synthetic event
   and reports any error raised inside those callbacks.

## Run it

```bash
pip install lupa
Ez-Hub/test/test_all.sh
# or a single file:
python3 Ez-Hub/test/run.py Ez-Hub/Scripts/Rivals.lua
```

`PASS` = the script loads and its callbacks run with no Lua errors.

## What it does NOT prove

This catches **crashes** (nil calls, wrong methods/arity, bad member access),
which are the "it errored / did nothing / white-screened" class of bugs. It does
**not** prove a feature actually works in-game, because the mock returns fake
data and does not simulate the real game, rendering, physics, remotes, executor
functions, or anti-cheat. A `PASS` means "no crash bugs in these code paths",
not "aimbot locks on in Rivals". Real behaviour still has to be confirmed in a
real executor.
