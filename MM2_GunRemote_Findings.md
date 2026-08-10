# MM2 Gun Remote — findings

Reconstructed from the full game dump (`Mm2 aim trainer fulllgame. Dump`,
PlaceId `129264514977232`, 58 remotes / 221 scripts).

## Gun (sheriff / hero)

The gun is a `Tool` in the player's character. **Its name varies** — it can be
a skin name (e.g. `Sunny`), so detect it by structure, not by name:

```
Character.<GunTool>.GunServer.ShootStart : RemoteEvent
Character.<GunTool>.GunServer.Lock       : RemoteEvent
```

### Firing (authoritative)

From `GunClient` (`shootGun`, verbatim behaviour):

```lua
-- p24 becomes a Vector3 hit position (mouse hit, or a passed part's position)
v_u_16:FireServer(p24)   -- v_u_16 = GunServer.ShootStart
```

So a shot is just:

```lua
ShootStart:FireServer(hitPosition)   -- hitPosition : Vector3
```

Passing a **target's torso/head position** instead of the mouse hit is a
silent aim — the shot resolves to that point regardless of camera direction.
`ShootStart.OnClientEvent` is server→client and only drives the shoot/reload
animation (`"Shoot"` / `"Reload"`), so it can be ignored for firing.

The stock client has a local debounce (`v_u_11` + `task.wait(0.01)`); calling
the remote directly bypasses it, but the **server** still enforces ammo /
cooldown, so rapid calls beyond the fire rate are simply dropped.

## Murderer

The murderer holds a `Tool` containing `KnifeServer` (with `SlashStart`,
`FlingKnife`, `DualWield`, `SetKnifeGoneTime`). Presence of `KnifeServer`
is a reliable role check to prefer / restrict targeting to the murderer.

## Round / match state

`ReplicatedStorage.Events.RemoteEvents.UpdateStatus` (server→client) drives the
HUD status text. Observed status strings, in order:

```
"Voting"  ->  "Map Chosen"  ->  "Loading"  ->  "In Game"  ->  "Clear"
```

- `"In Game"` = a round is live (the handler also starts the round countdown).
- The map spawns under `workspace.CurrentMap` (a Model child exists) while a
  round runs — a reliable fallback if you join mid-round and miss the event.

`MM2_AimTrainer.lua` uses this for `MatchGated`: auto-shoot only fires while a
round is active and resumes automatically each new round.

## Other notable remotes

- `ReplicatedStorage.Events.RemoteEvents.GunBeam` — server→client beam visual.
- `ReplicatedStorage.Events.RemoteEvents.RoleSelection` — role assignment.
- `Character.Knife.KnifeServer.SlashStart` — murderer melee.

## How `MM2_AimTrainer.lua` uses this

- Finds our gun by scanning Character + Backpack tools for
  `GunServer.ShootStart`; only fires when the tool is **equipped**.
- Silent aim / auto-shoot calls `ShootStart:FireServer(targetPos)`.
- Target position is the configured part (`Head` by default), with optional
  velocity prediction.
- Role check via `KnifeServer` powers `PreferMurderer` / `MurdererOnly`.
