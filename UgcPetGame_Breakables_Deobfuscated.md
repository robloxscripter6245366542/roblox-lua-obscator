# UGC / Pet game (PlaceId 98459174589830) — Breakables & loot, deobfuscated

Recovered from the whole-game bytecode dump. This is a **Pet-Simulator-style**
game: you break world **chests/breakables** with your pets for coins/diamonds
and **lootbags**, and open **lootboxes** from your inventory.

## Method

Every script is Luau **bytecode** (hex), not source — no decompiler here. This
recovers each chunk's constant/string pool to map the breakable + loot system
and its network remotes. Argument *shapes* aren't in a constant pool, so
arg-taking remote calls are best-effort.

## Breakables ("chests")

World models tagged with attributes `BreakableID` / `BreakableUID`,
`BreakableClass` / `BreakableType`, `health` / `maxHealth`. Classes/tiers seen:
`Normal`, `Legendary`, `Mythical`, `Golden`, `Rainbow`, `Event` (plus Chests /
Diamond Crates / Vaults). Relevant client modules:

| Module | Role |
| --- | --- |
| `Client.BreakableFrontend` | render + targeting; fires `Breakables_PlayerDealDamage` (your click damage) via `Network:UnreliableFire`; `SetTarget` / `manualTarget`; `MaxHitDistance` |
| `Client.BreakablesUtil` | finds breakables under `workspace` (`Breakables`), reads `BreakableID`/`BreakableClass`, computes coin stages, `GetChestRadius` vs `GetNormalRadius` |
| `Client.PlayerPet` | `SetTarget` → `Breakables_JoinPetBulk` / `Breakables_LeavePetBulk` — sends **all your pets** to attack the targeted breakable |

**Damage is server-authoritative.** `Breakables_PlayerDealDamage` is only your
click; the real damage is computed server-side from your pets/stats. A client
can automate the farming (targeting, clicking, moving) but can't inflate damage.

## Lootbags (the drops → inventory)

Breaking a breakable drops a **Lootbag** (`Directory.Lootbags`). The `Lootbags`
LocalScript gives each a **magnet** (`BodyPosition`, `FreeMagnet` /
`DisableMagnet`) that pulls it to you when you're near; attributes
`ReadyForCollection` → `Collected`. Rewards (coins, diamonds, boosts, items,
`isRare` / `diamondBagMaster`) are stored to inventory on collection — so being
near the broken chest collects the bag automatically.

## Lootboxes (open from inventory)

`Client.LootboxCmds`: `Lootbox_RequestOpen` via `Network:Invoke("Lootbox: Open")`
opens a lootbox / card pack you own. `Lootboxes`, `CardItems`, `IsCardPack`,
`Instant`. This is the "take/open items in inventory" path.

## What `AutoFarmChests.lua` wires

Detects PlaceId `98459174589830` territory implicitly (it just looks for
breakables) and:

- **Scans** the world for every live breakable and **scores** them (tier rank +
  chest/crate bonus + log-scaled health) to always pick the **best**.
- **Teleports onto** the best one so your pets farm it and its lootbag magnets
  into your inventory; best-effort also calls `PlayerPet.SetTarget` /
  `BreakableFrontend.SetTarget` and fires `Breakables_JoinPetBulk` +
  `Breakables_PlayerDealDamage`.
- Moves to the next best when it breaks; loops.
- Optional **Open Lootboxes** (`Lootbox_RequestOpen`) for inventory boxes.
- Adjustable hop speed (Safe/Normal/Fast) because the game has abuse detection.
