# Clone Builders / "CloneForge" (PlaceId 98456203230140) — deobfuscated

Recovered from the `Deobf` whole-game bytecode dump (79 compiled scripts). A
build/tycoon game where **clones** build models for you; you level up clone
count and build speed over time.

## Method

Luau bytecode only (no source, no decompiler here). This recovers each chunk's
constant/string pool to map the client controllers and the remote registry.
Remote argument shapes aren't in a constant pool, so arg-taking calls are
best-effort.

## Remotes — `ReplicatedStorage.CloneForge.Remotes`

| Remote | Kind | Purpose |
| --- | --- | --- |
| `ReassignAll` / `Reassign` / `Unassign` | Event | assign your clones to a build (client action, server-honored) — **works for everyone** |
| `Rewards` | Function | claim an ad reward: **+Clone / Build-speed / Walk-speed / Coins**. Requires a **watched RewardedVideo ad** (`AdService.GetAdAvailabilityNowAsync`); capped ~3/day; server validates the ad completion |
| `Admin` | Function | game admin panel: **Give Clones / Walk / Build**, `Permanent` flag, `Scope` (Server / Global / all live servers), Compensate, Announce, Kick/Mute/Ban. Server checks the caller is a game admin |
| `Commerce` / `Workshop` / `Build` | mixed | shop, workshop tools, build placement |

## How clone count & work speed are set

Both are **server-authoritative stats**:

- **Clone count** = `CloneCapacity` (a server attribute). Raised permanently by
  gamepasses ("+1 clone", "More clones") and upgrades, temporarily by an
  ad reward (`Rewards` → Clone), and by an admin grant (`Admin` → Clones).
- **Build / work speed** = `BuildSpeed` / `WorkerSpeed` (server), raised by
  gamepasses ("3x Building Speed", "All speeds unlocked"), ad rewards
  (`Rewards` → Build), and admin grants (`Admin` → Build).

A client cannot set these directly — there is no un-gated "set capacity"
remote. The only paths are the game's own purchase/reward flow (validated) or
the `Admin` remote (admins only). This is the same server-side wall as any
real currency/permission check.

## What Nexus wires (Clones + Clones: Admin tabs)

- **Assign All Clones** (`ReassignAll`) + keep-assigned loop — legit, no gate;
  makes the clones you already have finish builds faster.
- **Claim ad rewards** (`Rewards`: Clone / Build / Walk / Coins) — best-effort;
  the server still requires a real watched ad.
- **Admin → Give Clones (default 24) / Build Speed / Walk Speed**, with a
  `Permanent` toggle and an amount slider — the game's own admin grant. Works
  **only if your account is a game admin**; otherwise it no-ops server-side.
- **Am I Admin?**, a remote runner, and a Print-Remote-Tree button.
- Universal **WalkSpeed** (Player tab) works regardless.
