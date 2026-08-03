# SwordsController — deobfuscated (from `Blade ball` bytecode)

Source: `ReplicatedStorage.Controllers.SwordsController` (ModuleScript, section
`[807]` in the `Blade ball` MegaDumper capture). Stored as Luau bytecode
(version 9, types v3). Deserialised with a custom Luau bytecode reader
(header → string table → v3 userdata-type table → protos). The two protos that
drive parrying parsed cleanly (their string tables are coherent method names,
confirming correct alignment).

## Proto 12 — the parry input handler (`ParryButtonPress`, linedefined 324)

Reconstructed flow from its constant/string table:

1. **Guards before allowing a parry** (all confirmed strings, in order):
   `Character.Dead`, `workspace.Alive`, `LobbyParry`, **`DoNotParry`**,
   `ChargingAdrenaline`, `Qi-Charge`, `Stunned`, `InLobbyParryCooldown`.
   → validates our `DoNotParry` skip guard, and shows the game itself blocks
   parrying while `InLobbyParryCooldown` / `Stunned` / `ChargingAdrenaline`.
2. **Target selection** — `GetMouseLocation`, `ScreenPointToRay`,
   `CFrame.lookAt`, iterate `workspace.Alive`, `HumanoidRootPart.Position`,
   `WorldToScreenPoint`, pick nearest to cursor, read `Target`. Also branches
   on `GetLastInputType` (`MouseButton1/2`, `Keyboard`, `Gamepad`).
   → confirms the server resolves your parry target by **camera/mouse ray +
   WorldToScreenPoint**, exactly what our `fireParry` payload sends.
3. **Sets the parry window**:
   ```lua
   local track = <GrabParry animation track>
   SetAttribute("ParryTime", math.max(track.Length - track.TimePosition, floor))
   ```
   proven by the ordered constant run `Play → ParryTime → Length →
   TimePosition → max → SetAttribute`.

Numeric constants in this proto:
`[0.0, 0.05, 0.5, 0.625, 0.75, 0.9, 1.0, 1.25, 1.3, 1.5, 2.0, 3.0, 4.0, 5.0, 20.0]`
(`0.5` sits next to `InLobbyParryCooldown`/`delay` → the lobby parry cooldown.)

## Proto 7 — `OnParrySuccess` (linedefined 198)

Sets `ParryTime` the same way (`Play → ParryTime → math → max → SetAttribute`),
increments **`ServerParryCount`**, and picks the success VFX
`SuccessParry1..4` / `SuccessParry%*` by sword/accessory
(`HasAccessoryEquipped`, `InOverdriveMech`). Gamepad rumble via
`GetGamepadConnected` + `VibrationMotor`.

Numeric constants:
`[-1.637, -1.169, -0.905, 0.0, 0.036, 0.137, 0.15, 0.169, 0.25, 0.5, 1.0,
1.570796 (π/2), 2.0, 3.0, 3.141593 (π), 4.0]`
(the π/π-2 values are animation/tween angles, not parry timing.)

## The big finding: `ParryTime` is dynamic, not a constant

`ParryTime` is **the equipped GrabParry animation's remaining length**
(`Length − TimePosition`), floored by `math.max`. There is no single "parry
window number" — it scales with your sword's parry animation (≈0.4–0.5s for the
default sword, longer/shorter for others).

**Applied to the hub:** `derive_parry_reset()` now loads the equipped GrabParry
animation, reads its real `Length`, and sets `__parry_reset` to
`clamp(Length, 0.2, 1.0)` when Auto Parry starts — so the parried-state hold
matches the game's ParryTime for the sword you're actually using, instead of a
guessed constant. The "Parry Reset (s)" slider still overrides if you want.

## Other confirmations
- `DoNotParry` / `DoNotTarget` — real guards in the parry/target path (used).
- `ServerParryCount` — real per-player parry tally (used in the Stats HUD).
- `ParrySuccessClient` — local success bindable (used for instant reset).
- `NoobParryEnabled` — game assist-parry flag (respected via toggle).
