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
  call `task.wait`s half a ping, gets its verdict from the server, then waits
  the other half to return; it used to wait the whole round trip before the
  server even registered it, 1.5 pings late). It then contrasts a **no-guard control**
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

- **`hook_test.lua`** — the game's server→client calls the script hooks.
  `BallController.Server.ChangeBallColor(ballName, target)` passes the ball's
  **name**, and under **NoHighlight** (or for invisible balls) the game never
  writes the ball's `Target` attribute, so it goes stale. A decoy ball with a
  stale "me" attribute plus my real ball with a stale "them" attribute must
  still get my real ball parried. Also checks that unload restores the hooked
  `ChangeBallColor` / `SwordController.Server.BlockSuccess`. Also covers the
  client game fixes: a clash with the game's Clash visual setting **off**
  (the game never sets `ClashEffect` then) must still be held, and
  `GetBallAsync` must not add a connection per call. Run:
  `lua-5.1.5/src/lua hook_test.lua`. Expected: **ALL HOOK CASES OK**.

- **`return_test.lua`** — fast close **returns**: an opponent 15–25 studs away
  hits the ball straight back at you, 1.2x faster. The return lands in less
  time than your ping, so a block fired after the ball turns can't reach the
  server in time. The ball reaches the opponent from the side, so no shield is
  up by coincidence. Run: `lua-5.1.5/src/lua return_test.lua`. Expected:
  **12 parried, 0 missed** (it was 5/12 before Return Pre-Shield).

- **`pointblank_hold.lua`** — point-blank clash hold at real ping, using a
  **yielding** Block transport: each Invoke takes a full round-trip to return.
  The server is modeled as using up the shield on each parry, so every return
  needs its own fresh block to have arrived. Run:
  `lua-5.1.5/src/lua pointblank_hold.lua`. Expected: **ALL RETURNS HELD**. With
  the old fixed in-flight cap of 2 it held only 36/60 at 200 ms and lost one
  return at 130 ms.

- **`move_return_test.lua`** — you **jump and dash** while the opponent hits
  the ball back at you, outside a clash. The opponent is 30 or 45 studs away.
  You dash sideways, toward them or away, 0.2 s before or right at the hit, at
  60/130/200 ms ping. The return homes on your real position. Run:
  `lua-5.1.5/src/lua move_return_test.lua`. Expected: **36/36 parried** (it was
  33/36 before).

- **`replay_miss1.lua`** — replays the first **real** in-game miss report
  (153 ms). You parry a slow ball, it switches to another target but drifts
  near you, and it comes back fast 0.45–0.8 s later. Run:
  `lua-5.1.5/src/lua replay_miss1.lua`. Expected: **9/9 survived** (it was 6/9
  before; the extra block fired at the ball after the parry used up the
  cooldown its return needed).

- **`replay_miss2.lua`** — replays the second **real** miss report (108 ms):
  a long-range rally with an opponent 45–70 studs away. Run:
  `lua-5.1.5/src/lua replay_miss2.lua`. Expected: **9/9 survived** (it was
  3/9, dying after the first parry at 60–70 studs).

- **`lagspike_clash.lua`** — replays the third **real** miss report (173 ms,
  Clash Speed 95): a 0.15–0.2 s reply delay (lag spike) in the middle of a
  point-blank clash, at 110/170/200 ms. Run:
  `lua-5.1.5/src/lua lagspike_clash.lua`. Expected: **KEPT SENDING THROUGH
  THE SPIKE** (longest gap between sends 0.05 s; it was 0.15–0.22 s before).

- **`replay_miss4.lua`** — replays the fourth **real** miss report (119 ms): a
  fast long-range rally with an opponent 45–60 studs away. The ball speeds up
  to 380–420 studs/s and homes in wide loops, so each round trip takes
  0.23–0.68 s, like the report. Three things from the report are modeled:
  - The ball on screen trails the real one by half a ping plus ~0.1–0.13 s of
    interpolation. Its Target attribute trails by half a ping only.
  - `build(SRC, ping, {shieldLock=true})`: outside a game clash the server
    **refuses a block while your own shield is up**, even after a parry. In
    the report every block for 0.6 s after one went up was rejected.
  - The serve hovers next to the opponent first, which used to leave the parry
    range stuck small.

  Run: `lua-5.1.5/src/lua replay_miss4.lua`. Expected: **OK: every death was
  at the shield gap**, with 25/27 surviving. A shield-gap death is one where the
  script had sent the next block on the first frame the game allows, and
  either the ball arrived within 35 ms after your shield ended (that block
  lands a frame later), or the block landed in the very frame the shield ended
  and was refused (the next try is a round trip away). The script before this
  fix survives **0/27**. My parries reach the script half a ping late here (via
  `server.parried()`), as they do from the real server.

- **`replay_miss5.lua`** — replays the fifth **real** miss report (126 ms): a
  **slow** long-range rally. The opponent is 60–67 studs away, the ball goes
  100–126 studs/s, and each round trip takes ~1 s. In the report a shield
  parried the ball while the ball on screen still showed it 22 studs out, so
  another block went out. It landed just after the parry, was accepted (a
  parry resets the cooldown) and started a fresh 1 s cooldown. Every block for
  the return a second later was refused. Each case runs under both server rules
  (the default, where a parry resets the cooldown at once, and `shieldLock`). Run:
  `lua-5.1.5/src/lua replay_miss5.lua`. Expected: **OK: every death was at the
  shield gap**, with 17/18 surviving (every 80 and 126 ms case). The script
  before this fix survives 8/18, and under the default rule it dies right after
  the first parry at every ping, as in the report.

- **`replay_miss6.lua`** — replays the sixth **real** miss report (158 ms): an
  **ability launch**. Another player's ability holds the ball still (speed 0,
  its target cleared) about 110–140 studs from you. It then aims the ball at you
  and shoots it at 450–500 studs/s, starting 30–80° off the line and swinging
  in. As in the report, the ball reports its launch velocity for up to 0.2 s
  while still held, its velocity updates at 30 Hz, and you may be moving toward
  it. Run: `lua-5.1.5/src/lua replay_miss6.lua`. Expected: **15/15 parried**.
  The script before this fix parries 7/15 and misses the report's own case at
  158 ms: its turn-rate estimator threw out the 30 Hz heading jumps as
  "bounces", and the launch looked like a curve that would miss.

- **`replay_miss7.lua`** — replays the seventh **real** miss report (134 ms): a
  **close** rally. The opponent is 30–35 studs away and the ball speeds up to
  100–125 studs/s. In the report a block landed as the ball reached me and the
  game answered **"parried"** (an instant parry, with the ball already in
  range). That uses the block up and leaves no shield, but the script recorded
  it as a 0.6 s shield. It then held fire for the return 0.43 s later, "my
  shield already covers it". The sandbox server now answers false ("shield up")
  for a normal block. A test can set `server.instantNow`; when that says the
  ball is in range as a block lands, the server answers true and the test hits
  the ball back on the spot, with no shield left. Run:
  `lua-5.1.5/src/lua replay_miss7.lua`. Expected: **OK: every death was at the
  shield gap**, with 18/18 surviving. The script
  before this fix survives 4/18.

- **`replay_miss8.lua`** — replays the eighth **real** miss report (159 ms): a
  **fast** rally at 255–285 studs/s, with a return every ~0.45 s. In the report a
  shield parried the ball, and the return 0.45 s later, well inside that
  shield's 0.6 s, hit me. The **parry had used the shield up**. The script
  still counted it as up: it held fire (H=1) and its shield lock kept the next
  block back until too late. Each case runs under three server rules: the
  default (a parry resets the cooldown and the shield lasts), `shieldLock`, and
  `{consume=true}` (a shield that parries ends there). Run:
  `lua-5.1.5/src/lua replay_miss8.lua`. Expected: **OK: every death was at the
  shield gap**, with 24/27 surviving (9/9 under the default rule and 9/9
  under consume). The script before this fix survives 13/27, and 0/9 under
  consume.

- **`replay_miss9.lua`** — replays the ninth **real** miss report (156 ms): a
  **fast close** rally. The opponent is ~28 studs away, the ball reaches 180–220
  studs/s, and it comes back every ~0.2 s. There is also a **stray ball**
  ~1400 studs away with no target. Two things in the report:
  - A ball with no target counted as a threat at any distance. So whenever the
    rally ball was aimed at the opponent, the parry loop watched the stray ball
    instead.
  - The opponent was just past 25 studs, so the long-rally rules applied: hold
    while the ball flies to them, one block at a time, shield lock and cover
    hold. Those stop the stream of blocks that holds a fast exchange when a
    parry uses the shield up.

  Each case runs under the three server rules. Run:
  `lua-5.1.5/src/lua replay_miss9.lua`. Expected: **27/27 survived**. The script
  before this fix survives 13/27, and 0/9 when a parry uses the shield up.

- **`ability_test.lua`** — ball tricks from the game's own ability list
  (`AbilityInfo` in the 2026-10-31 dump). Each case aims the ball at you, then
  an ability changes it:
  - **Stasis** ("Stop the ball in mid air for 4 seconds or until parried!"):
    the ball freezes 60 studs out, then carries on at 300 studs/s. From that
    close it lands before you could even see it move again, so the script
    times a block for the moment it is released, 4 s after it stopped.
  - **Time Shift**: the ball reappears ~100 studs away at a new angle and 2x
    speed.
  - **Instant Transmission** ("teleports you to the player you hit the ball
    to"): the hitter appears next to you, so your parry turns into a
    point-blank return. With an opponent within 18 studs the script now
    treats the incoming ball as a clash and keeps blocks streaming, even
    though the ball on screen still looks 40+ studs out.
  - **Almighty Attraction**: the ball is pulled to a caster next to you, then
    aimed at you.

  Each case runs at pings 90/150/200, with a parried shield that lasts and one
  that is used up. Run: `lua-5.1.5/src/lua ability_test.lua`. Expected:
  **22/24 parried**. The two misses are Time Shift at 200 ms, which can't be
  blocked: the ball lands ~0.31 s after the shift, you see it 0.22 s after it,
  and a block takes 0.10 s more to land. The script before this fix parries
  13/24 (Stasis 0/6, Instant Transmission 3/6).
