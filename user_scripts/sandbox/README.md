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
- **`test_scenarios.lua`** — a broad suite (~230 cases across several pings) that
  stresses **every curve, turn and glitch**: straight; **homing** at 4 turn rates
  (up to `MAX_TURN_RATE`); **side-then-curve-in** and **orbit-then-snap**
  Wind-Shuriken; **spiral-in**; **sharp 90° last-instant turn**; **S-curve weave**;
  **diagonal** and **from-behind** approaches; **accelerating / decelerating**;
  **hover-then-launch**; **close spawns**; **invisible** and **unassigned**
  (no-Target) balls; and glitches — **teleporting** ball, **velocity spike**
  (parry-bounce), **no LinearVelocity**, **flickering / re-assigning Target**,
  **you dashing / strafing**, **15 / 30 / 144 fps**, **frame-jitter**, and a
  **freeze hitch**. Each result is classified **blockable** vs **physically
  unblockable** (a ball whose warning is shorter than the ping round-trip -
  `warning < 2·½ping + 1 frame` - can't be blocked by anything). Run:
  `lua-5.1.5/src/lua test_scenarios.lua`. Expected: **all blockable balls
  parried, NO REAL MISSES**; the unblockables are all high-ping + extreme cases.

- **`edge_test.lua`** — the cases the other suites never touched: **multiple
  balls at once** (2 / 3 / 5 converging — opposite sides, a fan, mixed speeds,
  same-instant and staggered — each one scored), and **glitch / crash physics**
  the script must survive without erroring — **NaN** and **infinite**
  position/velocity, a ball that **spawns already inside you**, a ball **sitting
  on you at zero speed**, **garbage `Target` attributes** (numbers/`nil`),
  **zero ping**, and **you dying mid-flight** (the HumanoidRootPart disappears
  then respawns). Multi-ball cases assert every incoming ball is parried; crash
  cases assert no error escapes. Run: `lua-5.1.5/src/lua edge_test.lua`.
  Expected: **ALL EDGE CASES OK**. (`world.lua` holds the shared mocked-world
  builder these suites load the script into.)

- **`clash_rate.lua`** — confirms the **clash click-storm**: during a point-blank
  clash the script sends the block as fast as it can (to match a fast clicker
  click-for-click), capped only by `MAX_CLASH_INFLIGHT` concurrent requests so it
  can't pile into a backlog. This synchronous transport can't show the cap (a
  synchronous Invoke returns before the next fire, so nothing is ever "in
  flight") — it just confirms the storm is firing hard during a clash. The cap
  itself is proven in `yield_clash.lua`. Run: `lua-5.1.5/src/lua clash_rate.lua`.
  Expected: **clash click-storm firing hard at every ping.**

- **`yield_clash.lua`** — the **faithful yielding-server** clash test. A real
  Roblox block goes through a `RemoteFunction` whose `InvokeServer` **yields for
  a full round-trip** before returning the verdict. Stock Lua 5.1 can't let a
  `coroutine.yield` cross a `pcall` (and the script fires its block inside one),
  so `world.lua` hands the script a **yieldable `pcall`** (a Luau semantic,
  reimplemented in pure Lua via a child coroutine that pumps yields through) and
  a **yielding transport** (`build(SRC, ping, {yieldTransport=true})`, a Block
  call `task.wait`s the round-trip). It then contrasts a **no-guard control**
  (fire a yielding block every frame → pending calls pile into a backlog that
  grows with ping — the "clashing is so slow" lag, reproduced) against the **real
  script**. The script paces block sends at a safe ~30/s (`BLOCK_SEND_INTERVAL`),
  which keeps the 0.6 s shield continuously fresh and covers **every** return
  while staying far under the game's own rate limiter (120/s global, 20 per 0.1 s
  burst — flooding it gets the block dropped / circuit-broken and loses the
  clash). Scored under **both** shield models — persistent 0.6 s shield
  *and* shield-consumed-per-parry. Run: `lua-5.1.5/src/lua yield_clash.lua`.
  Expected: **no-guard backlog grows with ping; the script stays at a small
  backlog with 100% coverage on every return (clash HELD).**

- **`detect_test.lua`** — the **advanced ball-detection** layer: cases the old
  event-only path went "no block" on and the new discovery + reconcile +
  motion-velocity layer must catch. Balls in a **differently-named** container
  (`GameBalls`, not `Balls`); a ball whose **ChildAdded event was missed** (the
  periodic reconcile sweep recovers it); and a **kinematic ball** moved by
  Position each frame with zero physics velocity (velocity recovered from
  motion, so its arrival is predicted). Run: `lua-5.1.5/src/lua detect_test.lua`.
  Expected: **ALL DETECTION CASES OK** — and the same suite run against the
  pre-change script fails all three ("NO BLOCK"), confirming the fix.

- **`decision_test.lua`** — **which ball drives the parry** when several are in
  play. Two cases that were real misses: a **decoy** (a ball aimed at another
  player sitting nearer than the one aimed at you) must not shadow your real
  threat; and **two threats** (a nearer SLOW ball and a farther FAST one, both
  aimed at you) must fire on the one that arrives first. Both were fixed by
  preferring the threatening ball for the arc/shield-window and opening the
  window for the most-imminent *closing* threat (while still falling back to the
  nearest ball of any target when nothing is aimed at you — the dash-in clash).
  Run: `lua-5.1.5/src/lua decision_test.lua`. Expected: **ALL DECISION CASES OK**.

- **`clash_test.lua`** — a dedicated **clash** simulator: a ball ping-pongs
  between you and an opponent who **dashes inside you** (down to 2-3 studs) while
  the exchange speeds up (to 600 studs/s = ~150 reversals/s). It models the real
  clash rule from the dump - a **successful parry resets the block cooldown**, so
  continuous point-blank fire holds a live 0.6 s shield across every return. It
  scores whether you **sustain** the clash (never eat an unshielded return).
  Expected: **ALL CLASHES HELD** at every ping. (The only clash vulnerability is
  the *cold start* at very high ping - the first return arriving faster than the
  round-trip - which is the same latency wall as any first ball.)

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
