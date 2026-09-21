# "Plus 1 Forge" (PlaceId 118805555015549) — deobfuscated

Recovered from `Plus 1 forge` (whole-game code dump: 627 compiled scripts,
mostly under `ReplicatedStorage`). A forge / train / rebirth **simulator**:
you train to gain power, forge & enchant weapons and armor, rebirth for
multipliers, roll classes/races for abilities, and claim rewards.

## Method

Every script is stored as **Luau bytecode** (hex), not source. There is no
Luau decompiler here, so this recovers each chunk's **constant/string pool**
and reconstructs the API surface: the remote registry, every remote name by
system, the config module layout, and the client control flow verbs
(`InvokeServer`, `FireServer`, `require`, `TryGetRemoteEvent`).

> Remote *argument shapes* (which index, which UUID, how many args) can't be
> read from a constant pool. Calls below are marked **(args best-effort)**
> where they take parameters; they're fired pcall-guarded. No-arg remotes
> (train, rebirth, claim, sell, luck) are the reliable ones.

## Remote registry

Remotes live under **`ReplicatedStorage.Remote`** and are resolved by name
through `Utils.CommunicationUtils`:

```lua
CommunicationUtils.TryGetRemoteEvent(category, name)     -- RemoteEvent
CommunicationUtils.TryGetRemoteFunction(category, name)  -- RemoteFunction
CommunicationUtils.TryGetBindableEvent(category, name)   -- client-only BindableEvent
```

Naming convention: `…RE` = RemoteEvent, `…RF` = RemoteFunction,
`…BE` = BindableEvent (client-internal, not a server call). Nexus resolves a
remote by searching `ReplicatedStorage.Remote` (then all of ReplicatedStorage)
for a descendant of that name, so it works regardless of the exact subfolder.

## Systems → remotes

### Training  (`CTRL.TrainCTRL`, `Config.TrainArea`)
- `TrainOnceRF` — **InvokeServer()**, one train tick. Spam it = auto-train.
- `IntoAutoTrainRE` / `ExitAutoTrainRE` — enter / leave an auto-train area
  (area id from the `AutoTrainAreaID` attribute) **(args best-effort)**.
- `ATKOnceBE`, `AttackDummyBE`, `DummyHitBE` — client attack/hit (BindableEvents).

### Rebirth  (`Config.Rebirth`)
- `RebirthRE` / `TryRebirthRE` — rebirth for a power multiplier (no args).
- `PlayerRebirthBE` — client rebirth signal. `DungeonRebirthRE` — dungeon variant.

### Forge & Equipment  (`Utils.ForgeUtils`, `Config.Weapon`, `Config.Armor`)
- `ForgeRF` — **InvokeServer(...)** forge a weapon/armor from ore **(args best-effort)**.
- `GetWeaponRE` / `GetArmorRE` / `GetOreRE` / `GetOreRF` — grant/read items.
- `TryEquipItemRE` / `TryUnEquipItemRE` — equip / unequip an item **(args best-effort: uuid)**.
- `ChangeEquipedIndexRE` — **change which weapon slot is equipped** (this is the
  "modify what sword you have" action; it persists server-side) **(args best-effort: index)**.
- `GetMyBestRF` — returns your best item (used to auto-equip best).
- `EnchantRE` / `UnEnchantRE` — enchant/disenchant equipment (adds affixes/abilities).

### Stats / power  (`AddStatsRE`, `SetStatsRE`, `DelStatsRE`)
- Modify your stat allocation. `SetStatsRE` **(args best-effort)** is the closest
  thing to "modify your power permanently" from the client — but the server
  validates it, so it only moves points you actually own.

### Classes / Races (abilities)  (`Utils.ClassUtils`, `Config.Class`)
- `LuckOnceRE` — roll once (luck-gated). `ShowRollRE` / `ShowLuckResultRE` — result UI.
- `UseAnySkillRE` / `UseSkillByIndexBE` — use a class/race skill.
- `SetIndexLockRE` / `TryUnlockIndexRE` — lock/unlock an ability slot **(args best-effort)**.

### Upgrades & potions  (`Config.Upgrade`)
- `UpgradeOnceRE` — upgrade once (ore pack / luck / train) **(args best-effort: which)**.
- `LuckOnceRE`, `TryUsePotionRE` — luck roll / consume a potion.

### Selling & ore  (economy)
- `TrySellAllRE` / `TrySellItemRE` — sell all / one item.
- `PickupOreBE`, `KillSuperLootRE`, `RefreshSuperLootRE`, `ClaimedAllOreRE`.

### Rewards / claims
- `TryClaimRE`, `TryClaimOfflineRewardRE`, `TryClaimLevelRewardRF`,
  `TryClaimIndexExpRF`, `TryClaimUPDRewardRE`, `TryClaimDailyDunTicRE` — mostly no-arg.

### Codes
- `TryUseCodeRF` — **InvokeServer(code)** redeem a code. `AddCodeRE`.

### Dungeon / rounds
- `TryIntoDungeonRF`, `StartRoundRE`, `CompleteRoundRF`, `StageFinishedRF`,
  `ExitDungeonRE`, `DungeonGiveUpBE`.

### Dev-gated (server checks `IsDevRF` — will reject normal players)
- `AddAnyEcoRE`, `AddAnyFunnelRE`, `AddFunnelWithPemRE`, `ResetEcoRE`,
  `KickPlayerRE`, `DestroyDataRE`. Listed for completeness; not exposed as
  headline features because the server rejects them for non-devs.

## What Nexus wires from this

`Nexus_WindUI.lua` detects PlaceId `118805555015549` as **Plus 1 Forge** and adds:
- **Auto Train** (spam `TrainOnceRF`; + enter/exit auto-train area).
- **Auto Rebirth / Upgrade / Luck / Sell All / Claim All** (the no-arg loops).
- **Auto Use Code** (input + `TryUseCodeRF`).
- **Equip Best / Change Weapon Slot / Auto Forge / Enchant** — the "modify your
  sword/ability" actions (`GetMyBestRF`, `ChangeEquipedIndexRE`, `ForgeRF`,
  `EnchantRE`), args best-effort.
- **Remote Runner + Remote list** — fire any remote by name with a typed arg,
  and dump the `ReplicatedStorage.Remote` tree, so unverified arg shapes can be
  confirmed in-game.
