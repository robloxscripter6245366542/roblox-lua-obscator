# Sentinel — Roblox Anti-Cheat Framework

A drop-in, **server-authoritative** anti-cheat for Roblox games. Sentinel treats
the client as untrusted, measures the truth on the server, and funnels every
anomaly through a single suspicion-scoring engine that escalates from a silent
log to a permanent ban.

> **The one principle that makes an anti-cheat actually work:** on Roblox the
> exploiter owns the client completely. No client-side check is unbypassable.
> Real security is the **server validating movement, remotes, and stats** and
> refusing to trust anything the client says. Sentinel is built around that.
> Client-side checks are included as *friction* — they catch lazy cheaters and
> add cost — but they never carry a ban on their own.

---

## What it detects

| Category | Detector | How (server-side unless noted) |
|---|---|---|
| **Speed hacks** | Movement | Samples position; horizontal speed vs `WalkSpeed × tolerance` |
| **Teleport / gotoCFrame** | Movement | Single-tick jump beyond `MaxTeleportDistance` → rollback |
| **Fly / hover** | Movement | Airborne with ~zero vertical velocity too long → rollback |
| **Noclip** | Movement | Character embedded inside a collidable anchored solid → rollback |
| **Infinite jump** | Movement | Jump state entered while airborne and not freshly grounded |
| **WalkSpeed/JumpPower/HipHeight** | Character | Server humanoid value above ceiling → corrected + flagged |
| **God mode** | Character | Health that won't drop after Sentinel-authored damage |
| **Remote spam** | Remotes/Net | Per-player token-bucket rate limiting |
| **Malformed remotes** | Remotes/Net | Argument schema + payload size/depth validation |
| **Remote fishing** | Remotes | Honeypot remote no legit client ever fires |
| **Economy dupe/inject** | Stats | Gains faster than `MaxGainPerSecond`, underflow, external writes |
| **Missing/patched client** | Client | Heartbeat gaps (low weight — friction only) |
| **Known exploit globals** | Client | Client self-reports `getgenv`, `hookfunction`, … (friction only) |

All detections add weight to a **rolling suspicion score** that **decays over
time**, so isolated false positives never stack into a ban. Actions fire when the
score crosses configurable thresholds (`warn → kick → ban` by default).

---

## Install

### With [Rojo](https://rojo.space) (recommended)
```
rojo build sentinel-anticheat -o Sentinel.rbxm   # then drag into Studio
# or, for live sync:
rojo serve sentinel-anticheat
```
The project maps to:
- `ReplicatedStorage/SentinelShared` (Config, Net)
- `ServerScriptService/Sentinel` (server bootstrap + detectors)
- `StarterPlayer/StarterPlayerScripts/SentinelClient` (heartbeat LocalScript)

### Manual (no Rojo)
Recreate that layout in Studio and paste each file into the matching
`ModuleScript` / `Script` / `LocalScript`.

### First run — **stay in DryRun**
`Config.DryRun = true` ships **on**. In DryRun, Sentinel logs everything it
*would* do but never kicks or bans. Run your game like this for a few days,
watch the output / webhook, tune thresholds against real players, then set
`DryRun = false` to enforce. **Do not enable enforcement blind** — you will kick
legitimate players on maps with launch pads, conveyors, or big teleports until
the tolerances fit your game.

---

## Integrating with your game

Sentinel exposes `_G.Sentinel` on the server once loaded.

**Route your remotes through Sentinel** (automatic rate-limit + validation):
```lua
local Sentinel = _G.Sentinel
Sentinel.Net.event({
    name = "BuyItem",
    schema = { "string", "number" },          -- itemId, quantity
    ratePerMinute = 60,
    onServerEvent = function(player, itemId, qty)
        -- runs only after rate + schema pass
    end,
})
```

**Make currency tamper-proof:**
```lua
local coins = Instance.new("IntValue")       -- your leaderstats value
coins.Name = "Coins"; coins.Parent = leaderstats
Sentinel.Stats.watch(player, "Coins", 0, coins)   -- Sentinel now owns it
Sentinel.Stats.add(player, "Coins", 50)           -- validated gain
```

**Authorize a legitimate teleport / powerup so it isn't flagged:**
```lua
Sentinel.allowTeleport(player)                 -- call right before you move them
character:PivotTo(destination)

Sentinel.exempt(player, "WalkSpeed", 50)       -- speed powerup up to 50
```

**Verifiable damage (feeds god-mode detection):**
```lua
Sentinel.damage(player, 25)                    -- instead of Humanoid:TakeDamage
```

**Moderation + telemetry:**
```lua
Sentinel.ban(player, "aimbot", 60 * 60 * 24)   -- 24h ban (0 = permanent)
for _, e in Sentinel.recentEvents() do print(e.name, e.category, e.action) end
```

---

## Tuning

Everything lives in `src/shared/Config.luau`:
- `Score.Thresholds` — when `warn`/`kick`/`ban` fire, and `DecayPerSecond`.
- `Movement.*` — speed tolerance, teleport distance, hover timing, sample rate.
- `Character.*` — property ceilings and whether to auto-correct.
- `Remotes.*` — default rate budgets and payload caps.
- `Stats.*` — max gain rate, currency floor.
- `Telemetry.DiscordWebhook` — alert staff on high-severity actions.

## Limits (be honest with yourself)
- Client-side signals (`MissingClient`, `IntegrityReport`) are trivially
  defeated by a competent exploiter — they are deliberately low-weight.
- Movement heuristics need per-game tuning; exotic mechanics (grapples,
  launchers, flinging) may need higher tolerances or a `allowTeleport` call.
- Sentinel raises the cost of cheating dramatically; it does not make a game
  uncheatable. Nothing on Roblox does. Server authority is the ceiling.
