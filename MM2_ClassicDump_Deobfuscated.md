# Murder Mystery 2 (Classic, PlaceId 142823291) — deobfuscated

Recovered from `Mm2 dump` (whole-game code dump, 380 compiled scripts across
`Players`, `ReplicatedStorage`, `ReplicatedFirst`, `StarterGui`,
`StarterPlayer`, `Workspace`).

## Method

Every script in the dump is stored as **Luau bytecode** (hex), not source.
There is no Luau decompiler in this repo, so "deobfuscation" here means
recovering each chunk's **constant/string pool** from the bytecode and
reconstructing the game's API surface from it: service names, remote names,
`CollectionService` tags, role values, method names and the call verbs
(`FireServer`, `InvokeServer`, `Fire`, `OnClientEvent`) each script uses.

That is enough to drive every gameplay feature from an external script,
because MM2 gates all real actions through named remotes — the exact Lua
control flow inside each chunk is not needed to call them.

> Argument *shapes* for a few remotes cannot be read from the bytecode with
> certainty (the constant pool holds names, not call signatures). Those are
> marked **(arg shape best-effort)** below and are fired pcall-guarded so a
> wrong shape fails silently instead of erroring.

## Remote map — `ReplicatedStorage.Remotes`

MM2 keeps its remotes under `ReplicatedStorage.Remotes`, split into
sub-folders. The gameplay ones live in `Remotes.Gameplay`.

| Path | Kind | Fired by | Purpose |
| --- | --- | --- | --- |
| `Remotes.Gameplay.GunFired` | RemoteEvent | `WeaponService` on shoot | Fire the sheriff/hero gun at a world target **(arg shape best-effort: target position/CFrame)** |
| `Remotes.Gameplay.KnifeThrown` | RemoteEvent | `WeaponService` on throw | Throw the murderer knife **(arg shape best-effort: target position/CFrame)** |
| `Remotes.Gameplay.GiveWeapon` | RemoteEvent (`OnClientEvent`) | server → client | Server hands you a weapon; `GameplayControlsScript` listens |
| `Remotes.Gameplay.GetLatestPlayerData` | RemoteFunction (`InvokeServer`) | `CurrentRoundClient` | Returns your `PlayerData` incl. `.Role` and `.Perk` |
| `Remotes.Gameplay.GetCurrentPlayerData` | RemoteFunction | client | Cached player data |
| `Remotes.Gameplay.PlayerDataChanged` | RemoteEvent (`OnClientEvent`) | server → client | Role / data updates mid-round |
| `Remotes.Gameplay.CoinCollected` | RemoteEvent (`OnClientEvent`) | server → client | A coin was collected |
| `Remotes.Gameplay.CoinsStarted` | RemoteEvent (`OnClientEvent`) | server → client | Coins spawned for the round |
| `Remotes.Inventory.*` | mixed | `BoxController` etc. | `UpdateSalvageClient`, `CrateComplete`, `HatchEgg`, salvage/box opening |
| `Remotes.ClientTweenEvents.GetClientTween` | RemoteFunction | `ClientTween` | Server-driven tweens (cosmetic) |

### Combat path (from `ClientServices.WeaponService`)

The weapon module resolves the target and then fires the remote:

1. `GetMouseTargetCFrame` / `GetTargetPosition` — raycast from the camera
   (`ViewportPointToRay`) using `WeaponRaycast` + a `GetWeaponIgnoreList`
   filter, honouring `MouseLock` / `PreferredInput` (gamepad vs mouse).
2. Gun → `GunFired` fires with that target.
3. Knife → `ThrowKnife` / `KnifeThrown` fires with that target.

An external hub can skip the raycast and fire the remote with a target
position it computes itself (aura / silent aim).

## CollectionService tags

| Tag | Applied to | Use |
| --- | --- | --- |
| `CoinVisual` | each coin part (attribute `CoinID`) | walk/teleport onto them to auto-collect (server credits on pickup) |
| `Weapon_Gun` | equipped gun tool | detect who is armed / auto-equip |
| `Weapon_Knife` | equipped knife tool | detect the murderer / auto-equip |
| `Character` | living characters | ESP / target enumeration |

## Roles (`PlayerData.Role`)

`Waiting`, `Innocent`, `Sheriff`, `Hero`, `Murderer`, `Victim`.

`CurrentRoundClient` exposes `CheckIfMurderer` and `GetMurdererPerk`.
Role is authoritative from `GetLatestPlayerData:InvokeServer()`, so ESP can
colour the murderer (red) and sheriff/hero (blue) reliably instead of
guessing from the held tool.

## Perks (`ClientServices.PerkService`, `Remotes ... ActivatePerk`)

Perks are activatable abilities with cooldowns, e.g.:

- **Sprint** — 50% temporary speed boost.
- **X-Ray** — see through walls briefly (30s cooldown).
- **Haste** — murderer walkspeed 17 → 18 while holding the knife.

`ActivatePerk` fires the perk; `PerkIsActive` / `GetEquippedPerk` report state.

## Feature inventory (what the dump contains)

Cosmetic/meta systems (not exploit-relevant but present): Shop (`ShopService`,
`ShopScript*`), Inventory/Trading (`TradeModule`, `AcceptTrade`,
`SendTradeRequest`), Crafting (`CraftModule`, `GetCraftingResult`), Pets
(`PetsNew`, `weldPet`), Emotes (`EmoteController`, `playAvatarEmote`),
Gifting (`GiftInventory`), Codes (`RedeemCode`), Mystery boxes / eggs
(`MysteryBoxService`, `HatchEgg`), Battle pass (`BattlePass`), Spectate
(`SpectateService`, `beginSpectate`, `NavigateSpectate`).

Gameplay systems an exploit hub drives: **Gun** (`GunFired`), **Knife throw**
(`KnifeThrown`/`ThrowKnife`), **Coins** (`CoinVisual` tag), **Roles**
(`GetLatestPlayerData`), **Perks** (`ActivatePerk`), **Equip**
(`EquipService.EquipItem` / `GiveWeapon`), **Traps** (`PlaceTrapLocal`,
`TrapHitLocal`).

## What Nexus wires from this

`Nexus_WindUI.lua` detects PlaceId `142823291` as **MM2 (classic)** and builds
its Gun / Knife / Coins / Visuals features on the remotes above:

- **Auto Shoot Aura + Silent Aim** → `Remotes.Gameplay.GunFired`.
- **Knife Auto-Throw** → `Remotes.Gameplay.KnifeThrown`.
- **Auto-Collect Coins** → teleport onto every `CoinVisual`-tagged part.
- **Role ESP** (murderer red / sheriff blue) → `GetLatestPlayerData`.
- **Auto-Equip / Activate Perk** → `EquipService` / `ActivatePerk`.

Modern MM2 (`129264514977232`) uses a different scheme
(`GunServer.ShootStart` / `KnifeServer.SlashStart`); Nexus keeps that path too
and picks the right one per PlaceId.
