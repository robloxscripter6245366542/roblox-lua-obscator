# Anime Ball autoparry — offline sandbox

A tiny virtual Roblox, built from the game dump, that runs
`../anime_ball_autoparry.lua` in **real Lua** so the script can be exercised and
regression-tested *without Roblox* — catching runtime crashes and validating
block timing that static analysis can't see.

## What's here

- **`mock_roblox.lua`** — a mock of the Roblox API the script uses: `Instance`,
  `Vector3` / `CFrame` (full vector math + `fromAxisAngle`), `Color3`, `Enum`,
  `task.*` (a coroutine scheduler with a virtual clock), Signals, services
  (`Players`, `RunService`, `ReplicatedStorage`, `Stats`, `Workspace`), and the
  Anime Ball pieces from the dump — `Framework.RemoteFunction` /
  `SwordService.Block`, `workspace.Balls`, `LinearVelocity`, the
  `workspace[Player].Highlight`, the ping stat, etc. A stub WindUI is served via
  `game:HttpGet` so the UI-heavy load path runs to completion.
- **`test_autoparry.lua`** — builds a **fresh** world per scenario (no state
  bleed), loads the real script into it, then sweeps ball **speed × ping** and
  reports whether each ball would actually be **parried** under the game's block
  model taken from the dump: a block is a **0.6 s shield** that registers
  ~half-a-ping after firing, on a **1 s cooldown** (only a successful parry
  resets it). Ball **staleness** (you see the ball ~half-a-ping behind) and the
  block **register delay** are both modelled, so the timing is faithful.

## Running it

You need a Lua **5.1** interpreter (Roblox's Luau is 5.1-based). Build one:

```sh
curl -sSL https://www.lua.org/ftp/lua-5.1.5.tar.gz | tar xz
# Luau allows up to 200 upvalues; stock Lua 5.1 caps at 60, so bump it to match:
sed -i 's/#define LUAI_MAXUPVALUES\t60/#define LUAI_MAXUPVALUES\t200/' lua-5.1.5/src/luaconf.h
make -C lua-5.1.5 generic
```

Then, from this directory:

```sh
lua-5.1.5/src/lua test_autoparry.lua
```

Expected: **27/27 PARRIED** on the default grid. A wider grid parries everything
except a ~600 studs/s ball at ~450 ms ping — that ball reaches you in less time
than your one-way latency, so it is physically unblockable, not a script bug.

## What the sandbox found

- The script loads and runs with **no runtime error**.
- It reproduced a real **miss**: firing a lone ball's block too early (0.6–1.0 s
  before impact) makes the first block whiff, and the 1 s server cooldown then
  locks out the re-block until after impact. The fix — gating the lone-ball fire
  (and the point-blank path) to the window where the 0.6 s shield actually covers
  impact — is what took the sweep to 27/27.

## Caveats

The server block model (shield duration, cooldown, whether a whiffed block spends
the cooldown) is the best reconstruction from the dump, not observed ground
truth, so treat the *timing* conclusions as strong hypotheses. Crash-detection is
exact. The real confirmation is still an in-game run.
