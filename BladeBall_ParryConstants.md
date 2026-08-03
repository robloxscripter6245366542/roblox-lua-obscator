# Blade Ball — Combat constants recovered from bytecode

Source: `Blade ball` (MegaDumper capture). The combat scripts are stored as
raw Luau bytecode (header `09 03` = version 9, types v3, then a length-prefixed
string table, then typed proto constants). Number constants are stored as
typed `NUMBER` doubles in each proto's constant list, referenced by opcodes —
they are **not** stored next to the related string, so exact
string→value binding needs full instruction tracing. What is recoverable
statically is the *set* of numeric constants inside each parry proto.

## `ParryTime` proto (SwordsController parry-state function)

The proto that contains the string constants `ParryTime`, `Parrying`,
`PrimaryPart`, `SetAttribute`, `math`, `max` — i.e. the code doing
`SetAttribute("ParryTime", math.max(...))`. This is a **countdown attribute**
(time you remain in the parry/parrying state), not a fixed hit-radius.

Clean numeric constants found in this proto:

```
0.1, 0.35, 0.5, 0.6, 0.85, 1.0, 1.15, 1.5, 2.0, 3.0
```

`ParryTime`'s value is one of the small ones — **0.35 / 0.5 / 0.6 are the
strongest candidates** for the parry active/cooldown window. (Pin the exact
one with `BladeBall_SwordDumper.lua` in a live round — it disassembles the
proto and ties the LOADK/LOADN to the `SetAttribute("ParryTime", …)` call.)

## Related attributes / remotes confirmed present in bytecode

- Attributes: `ParryTime`, `Parrying`, `ServerParryCount`, `NoobParryEnabled`,
  `DoNotParry`, `DoNotTarget`, `highlighted`, `realBall`, `ComboCounter`,
  `SingularityInOrbit`.
- Remotes / events (SwordsController): `ParryButtonPress`, `ParryAttempt`,
  `ParrySuccess`, `ParrySuccessClient` (local BindableEvent), `NoobParryHappened`.

## Deflection / counter ability set (from the Abilities list)

Every ability below deflects an incoming ball on `AbilityButtonPress` when
equipped and off cooldown. Auto Ability now covers all of them:

```
Raging Deflection, Calming Deflection, Aerodynamic Slash, Rapture,
Fracture, Death Slash, Flash Counter, Parry Counter,
Slashes of Fury, Slash of Duality, Revenge, Guardian Angel
```

Ability-specific success remotes (for reference / future per-ability tuning):
`PlrRagingDeflectiond`, `PlrCalmingDeflectiond`, `RagingDeflectionSuccess2`,
`DeathSlashSuccess2`, `DeathSlashShootActivation` (Death Slash follow-up).
