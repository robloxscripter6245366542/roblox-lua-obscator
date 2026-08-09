# Parry Sandbox (`parry_sandbox.luau`)

Headless simulation harness for the `elopez` (Leviathan) **parry** logic. It runs
the real parry decision math against thousands of generated ball scenarios so
timing/curve changes can be tested **without launching Roblox**.

(Separate from the `Strongest`/TSB simulator documented in `README.md` — this one
is self-contained and only models the parry brain.)

## Run

```sh
# Build the Luau CLI once if you don't have it:
bash luraph-deobf/dynamic/build_luau.sh    # produces ./luau

luau sim/parry_sandbox.luau
```

Expected output:

```
Ran 5274 straight-ball scenarios + 74400 curve checks.
Harness self-check (broken configs must be detectable): OK
PASS — no misses, no skip-risk, no double-parries, no curve errors.
```

## What it checks

For every combination of ball **speed** (15–1200), **ping** (0–550 ms Data Ping),
**start distance**, and accuracy mode (static slider vs. Auto Accuracy), it
simulates the ball closing on the player frame-by-frame at 60 FPS and asserts:

- **No miss** — a ball aimed straight at you is always parried before it reaches you.
- **No skip-risk** — the parry window (`parry_accuracy`) is always ≥ the ball's
  per-frame travel, so a fast ball can't slip through the band between frames.
- **No double-parry** — the same approach never fires two parries closer than the
  120 ms cooldown.
- **Not absurdly early** — the first fire happens within the computed accuracy band.
- **Curve math never crashes** — `isBallCurved` returns a boolean for thousands of
  speed × angle geometries.

A built-in **self-check** feeds known-broken configs (zero cooldown, 1-stud window)
and confirms the harness detects them — so a green run actually means something.

## Keeping it honest

`Model.parryAccuracy` and `Model.isBallCurved` are copied **verbatim** from the
corresponding logic in `elopez`. If you change the parry formula there, mirror the
change here and re-run before shipping.
