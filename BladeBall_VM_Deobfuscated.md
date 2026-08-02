# Blade Ball — VM Bytecode Deobfuscation

Constant/string tables extracted from the protected Luau **bytecode version 9** blobs in the `Blade ball` MegaDumper dump (PlaceId 16281300371).

> **What this is:** Luau bytecode cannot be reliably decompiled back to source, but its constant (string) table *is* fully recoverable. Every identifier a script references — remotes fired, attributes read, methods called, instances touched — lives in that table. Extracting it exposes each script's full API surface and behaviour even though exact control flow is not reconstructed. Numeric constants and instruction order are not included.

**Scripts decoded:** 671 / 682 VM-bytecode scripts.


---

## Remote usage index

Which decoded scripts reference each game remote:

- **AbilityButtonHold** — 1 script(s): Bunny Leap
- **AbilityButtonPress** — 57 script(s): Absolute Confidence, Aerodynamic Slash, Blade Trap, Blink, Bounty, Calming Deflection, Chieftain's Totem, Continuity Zero … (+49)
- **AcceptPartyInvite** — 1 script(s): RankedSelectionController
- **Blinked** — 1 script(s): Blink
- **BotAbility** — 1 script(s): Serpent Shadow Clone
- **ChangedAfkMode** — 3 script(s): ShowRoomController, TutorialSkipPromptController, HUDController
- **ChangeSwordColor** — 1 script(s): HUDController
- **ClientPulse** — 1 script(s): ClientPulsed
- **CloakJump** — 2 script(s): Wind Cloak, BaseUIS
- **DashFired** — 4 script(s): Dash, Ninja Dash, Qi-Charge, Titan Blade
- **Data** — 107 script(s): Aerodynamic Slash, Blade Trap, Bunny Leap, Death Slash, Doppelganger, Dragon Spirit, Dribble, Event Horizon … (+99)
- **DeathSlashSuccess2** — 1 script(s): Death Slash
- **DoubleJump** — 2 script(s): Doppelganger, BaseUIS
- **DualityInitialActivation** — 1 script(s): Slash of Duality
- **DualityShootActivation** — 1 script(s): Slash of Duality
- **DualitySwitchTarget** — 1 script(s): DualityChoice
- **EndCD** — 56 script(s): Absolute Confidence, Aerodynamic Slash, Blade Trap, Bounty, Bunny Leap, Calming Deflection, Chieftain's Totem, Continuity Zero … (+48)
- **FetchTop100Leaderboard** — 1 script(s): RankedSelectionController
- **FireSwordInfo** — 1 script(s): SwordsController
- **ForceAbilityActivate** — 1 script(s): Force
- **Freeze** — 16 script(s): Freeze, Index, SwordForge, SquadRoyaleInviteController, IndexController, InventoryController, TradePINCodeController, TradePlazaController … (+8)
- **getAFKStatus** — 2 script(s): ShowRoomController, HUDController
- **GetPlayerTimezone** — 1 script(s): DailyLoginController
- **Infinity** — 3 script(s): Infinity, InfinityTrial, inspect
- **JoinQueue** — 1 script(s): RankedSelectionController
- **KeybindM2** — 36 script(s): Blink, Bunny Leap, Calming Deflection, Continuity Zero, Death Slash, Dragon Spirit, Dribble, Flash Counter … (+28)
- **LeaveParty** — 1 script(s): RankedSelectionController
- **LeaveQueue** — 1 script(s): RankedSelectionController
- **M1Stop** — 4 script(s): Death Slash, Slash of Duality, BaseUIS, SwordsController
- **MuteMusic** — 1 script(s): HUDController
- **NoobParryHappened** — 1 script(s): SwordsController
- **Notification** — 1 script(s): GlobalMessageController
- **OnDeath** — 1 script(s): BaseUIS
- **OnPlayerKilled** — 1 script(s): ShopPurchaseAbilityTutorialController
- **ParryAttempt** — 1 script(s): SwordsController
- **ParryButtonPress** — 1 script(s): SwordsController
- **ParrySuccess** — 4 script(s): Dragon Spirit, Dribble, ServerTypeController, SwordsController
- **ParrySuccessClient** — 3 script(s): Index, SwordForge, ShowRoom3D
- **Phantom** — 1 script(s): Phantom
- **PlaceContinuityPortal** — 1 script(s): Continuity Zero
- **Platform** — 6 script(s): Freeze Trap, Platform, BaseUIS, GameAnalytics, Events, HttpApi
- **PlrAdrenalined** — 1 script(s): Qi-Charge
- **PlrBountiedFunction** — 1 script(s): Bounty
- **PlrBunnyCancelled** — 1 script(s): Bunny Leap
- **PlrBunnyLeaped** — 1 script(s): Bunny Leap
- **PlrCalmingDeflectiond** — 1 script(s): Calming Deflection
- **PlrConfidenceTaunted** — 1 script(s): Absolute Confidence
- **PlrDashed** — 2 script(s): Dash, Titan Blade
- **PlrDragonSummoned** — 1 script(s): Dragon Spirit
- **PlrFlashCountered** — 1 script(s): Flash Counter
- **PlrForcefielded** — 1 script(s): Forcefield
- **PlrFreezeTrapped** — 1 script(s): Freeze Trap
- **PlrHellHooked** — 1 script(s): Hell Hook
- **PlrInvisibilityd** — 1 script(s): Invisibility
- **PlrPulled** — 1 script(s): Pull
- **PlrPulsed** — 1 script(s): Pulse
- **PlrQuasared** — 1 script(s): Quasar
- **PlrRagingDeflectiond** — 1 script(s): Raging Deflection
- **PlrRaptured** — 1 script(s): Rapture
- **PlrRevenged** — 1 script(s): Revenge
- **PlrSuperJumped** — 1 script(s): Super Jump
- **PlrUsedScopophobia** — 1 script(s): Scopophobia
- **PlrWaypointed** — 1 script(s): Waypoint
- **QuantumArenaDash** — 1 script(s): Quantum Arena
- **RagingDeflectionSuccess2** — 2 script(s): Calming Deflection, Raging Deflection
- **RaptureSuccess** — 1 script(s): Rapture
- **RequestReflectionData** — 1 script(s): BaseUIS
- **RequestTeleportToMain** — 1 script(s): HUDController
- **ResetFOV** — 4 script(s): Phase Bypass, BaseUIS, BlackHole, SettingsController
- **RoundEnded** — 6 script(s): Continuity Zero, ServerTypeController, SinglePassBounty, TokenDropController, ShopPurchaseAbilityTutorialController, SpectateController
- **SendPartyInvite** — 1 script(s): RankedSelectionController
- **Set** — 21 script(s): TournamentEventController, TournamentEventInviteController, TournamentEventLeaderboardController, IndexController, InventoryController, TradePINCodeController, TradeRequestController, TradeTabController … (+13)
- **SetGift** — 10 script(s): TournamentEventController, DuoPassController, GenericGachaController, GiftInventoryController, LimitedSwordPacksController, SealCrateController, ShopController, Console … (+2)
- **ShadowFollow** — 1 script(s): Shadow Step
- **Store** — 4 script(s): ShopController, GameAnalytics, Events, State
- **Swapped** — 1 script(s): Swap
- **SwitchMode** — 1 script(s): RankedSelectionController
- **SyncDragonSpirit** — 1 script(s): Dragon Spirit
- **SyncFractureBoost** — 1 script(s): Fracture
- **Telekinesis** — 1 script(s): Telekinesis
- **TemporarilyDisableSFX** — 1 script(s): HUDController
- **ThunderDash** — 1 script(s): Thunder Dash
- **Update** — 8 script(s): SettingsController, SliderNode, ShowRoomController, StPatricksDayEventController, TournamentEventController, TradingSignController, InviteRewardsController, InviteRewardsButton
- **UpdateFractureBoostDB** — 1 script(s): Fracture
- **UpdateSpectateCount** — 1 script(s): SpectateController
- **UpdateSpins** — 1 script(s): TournamentCrateController
- **UpdateVotes** — 1 script(s): VotingController
- **UseContinuityPortal** — 1 script(s): Continuity Zero
- **VisualBindableCD** — 58 script(s): Absolute Confidence, Aerodynamic Slash, Blade Trap, Blink, Bounty, Bunny Leap, Calming Deflection, Chieftain's Totem … (+50)
- **WaypointCombust** — 1 script(s): Waypoint
- **WindCloak** — 1 script(s): Wind Cloak
- **XtraJumped** — 1 script(s): BaseUIS

---

## Per-script constant tables

### [1] 7icbvx.Abilities.Absolute Confidence
`LocalScript` · bytecode v9 · 2160 bytes · 57 constants
- **Remotes:** AbilityButtonPress, EndCD, PlrConfidenceTaunted, VisualBindableCD
- **Services:** Debris, Players, ReplicatedStorage, UserInputService, game, workspace
- **Key API:** Connect, Fire, FireServer, GetService, LoadAnimation, OnClientEvent, WaitForChild
- Constants: `Parent`, `workspace`, `Alive`, `Ability`, `Red`, `Visible`, `getAbilityCooldown`, `script`, `Name`, `playAnimationTrack`, `PlrConfidenceTaunted`, `FireServer`, `VisualBindableCD`, `Fire`, `task`, `delay`, `ability`, `UseBind`, `Thread`, `SafeCancel`, `game`, `Debris`, `GetService`, `Players`, `ReplicatedStorage`, `require`, `UserInputService`, `WaitForChild`, `Common`, `Controllers`, `Packages`, `Remotes`, `Shared`, `LocalPlayer`, `Character`, `CharacterAdded`, `Wait`, `Humanoid`, `Animator`, `Pose`, `LoadAnimation`, `Abilities`, `AbilityUtils`, `SettingsController`, `Utils`, `PlayerGui`, `Hotbar`, `Vector`, `iconId`, `Image`, `InputBegan`, `Connect`, `AbilityButtonPress`, `Event`, `EndCD`, `OnClientEvent`

### [2] 7icbvx.Abilities.Aerodynamic Slash
`LocalScript` · bytecode v9 · 3805 bytes · 91 constants
- **Remotes:** AbilityButtonPress, Data, EndCD, VisualBindableCD
- **Services:** Debris, Players, ReplicatedStorage, UserInputService, game, workspace
- **Key API:** Connect, FindFirstChild, Fire, GetChildren, GetService, InvokeServer, LoadAnimation, OnClientEvent, Stop, WaitForChild
- Constants: `Misc`, `DataAbilities`, `script`, `Name`, `FindFirstChild`, `GetAttributes`, `AbilityUpgrades`, `Get`, `Icon`, `Icon%*`, `format`, `Vector`, `WaitForChild`, `Image`, `updateIcon`, `OnChange`, `CFrame`, `X`, `Y`, `InvokeServer`, `Character`, `Parent`, `workspace`, `Alive`, `Red`, `Visible`, `GetChildren`, `GetPivot`, `Position`, `WorldToScreenPoint`, `xpcall`, `warn`, `playAnimationTrack`, `task`, `delay`, `type`, `number`, `Remotes`, `VisualBindableCD`, `Fire`, `ability`, `Ability`, `UseBind`, `coroutine`, `status`, `suspended`, `pcall`, `cancel`, `spawn`, `Stop`, `game`, `ReplicatedStorage`, `GetService`, `require`, `UserInputService`, `Players`, `Debris`, `Packages`, `Net`, `Replion`, `Controllers`, `SettingsController`, `Shared`, `AbilityUtils`, `LocalPlayer`, `CharacterAdded`, `Wait`, `Humanoid`, `Animator`, `AerodynamicSlash`, `RemoteFunction`, `CurrentCamera`, `GetMouse`, `PlayerGui`, `Hotbar`, `Upgrades`, `attempt`, `LoadAnimation`, `success`, `Client`, `Data`, `AwaitReplion`, `InputBegan`, `Connect`, `AbilityButtonPress`, `Event`, `EndCD`, `OnClientEvent`, `AerodynamicSlashEvent`, `RemoteEvent`

### [3] 7icbvx.Abilities.Blade Trap
`LocalScript` · bytecode v9 · 3404 bytes · 88 constants
- **Remotes:** AbilityButtonPress, Data, EndCD, VisualBindableCD
- **Services:** Debris, Players, ReplicatedStorage, UserInputService, game, workspace
- **Key API:** Connect, FindFirstChild, Fire, GetChildren, GetService, InvokeServer, OnClientEvent, Play, WaitForChild
- Constants: `Misc`, `DataAbilities`, `script`, `Name`, `FindFirstChild`, `GetAttributes`, `AbilityUpgrades`, `Get`, `Icon`, `Icon%*`, `format`, `Vector`, `WaitForChild`, `Image`, `updateIcon`, `OnChange`, `InvokeServer`, `Character`, `Parent`, `workspace`, `Alive`, `Red`, `Visible`, `Map`, `GetChildren`, `BottomCircle`, `BALLSPAWN`, `GetPivot`, `Position`, `Magnitude`, `error`, `Play`, `FloorMaterial`, `Enum`, `Material`, `Air`, `xpcall`, `warn`, `getAbilityCooldown`, `type`, `number`, `Remotes`, `VisualBindableCD`, `Fire`, `task`, `delay`, `ability`, `Ability`, `UseBind`, `coroutine`, `status`, `suspended`, `pcall`, `cancel`, `spawn`, `game`, `ReplicatedStorage`, `GetService`, `require`, `UserInputService`, `Players`, `Debris`, `Packages`, `Net`, `Replion`, `Controllers`, `SettingsController`, `LocalPlayer`, `CharacterAdded`, `Wait`, `Humanoid`, `BladeTrap`, `RemoteFunction`, `PlayerGui`, `Hotbar`, `Upgrades`, `Shared`, `Abilities`, `Client`, `Data`, `AwaitReplion`, `InputBegan`, `Connect`, `AbilityButtonPress`, `Event`, `EndCD`, `OnClientEvent`

### [4] 7icbvx.Abilities.Blink
`LocalScript` · bytecode v9 · 3975 bytes · 91 constants
- **Remotes:** AbilityButtonPress, Blinked, KeybindM2, VisualBindableCD
- **Services:** Debris, Players, ReplicatedStorage, UserInputService, game, workspace
- **Key API:** Connect, FindFirstChild, Fire, FireServer, GetService, OnClientEvent, Play, WaitForChild, new
- Constants: `Hotbar`, `WaitForChild`, `Ability`, `ready`, `counts`, `tostring`, `Text`, `updateRemainingLabel`, `game`, `Players`, `LocalPlayer`, `Character`, `task`, `wait`, `math`, `clamp`, `defer`, `Remotes`, `VisualBindableCD`, `Fire`, `Misc`, `error`, `Play`, `Parent`, `workspace`, `Alive`, `PlayerGui`, `Red`, `Visible`, `MoveDirection`, `PrimaryPart`, `FREEZER`, `FindFirstChild`, `spawn`, `Upgrades`, `script`, `Name`, `Value`, `HumanoidRootPart`, `Position`, `RaycastParams`, `new`, `Enum`, `RaycastFilterType`, `Exclude`, `FilterType`, `Runtime`, `Dead`, `Balls`, `FilterDescendantsInstances`, `Head`, `CFrame`, `Left Arm`, `Right Arm`, `Right Leg`, `Left Leg`, `Torso`, `Blinked`, `FireServer`, `Unit`, `Raycast`, `Instance`, `ability`, `UseBind`, `UserInputType`, `MouseButton2`, `CharacterAdded`, `Wait`, `Humanoid`, `Debris`, `GetService`, `require`, `ReplicatedStorage`, `UserInputService`, `Controllers`, `SettingsController`, `CurrentCamera`, `FieldOfView`, `Vector`, `Shared`, `Abilities`, `iconId`, `Image`, `ChildAdded`, `Connect`, `InputBegan`, `AbilityButtonPress`, `Event`, `KeybindM2`, `OnClientEvent`

### [5] 7icbvx.Abilities.Bounty
`LocalScript` · bytecode v9 · 6499 bytes · 109 constants
- **Remotes:** AbilityButtonPress, EndCD, PlrBountiedFunction, VisualBindableCD
- **Services:** Debris, Players, ReplicatedStorage, UserInputService, game, workspace
- **Key API:** Connect, FindFirstChild, Fire, GetAttribute, GetChildren, GetService, InvokeServer, IsA, OnClientEvent, Play, WaitForChild, new
- Constants: `Value`, `Adornee`, `Enabled`, `updateTarget`, `ObjectValue`, `IsA`, `string`, `find`, `Name`, `CurrentBounty`, `Instance`, `new`, `Highlight`, `BountyHighlight`, `FillTransparency`, `Color3`, `fromRGB`, `OutlineColor`, `Parent`, `Changed`, `Connect`, `task`, `spawn`, `onBountyValueAdded`, `math`, `max`, `getMaxUsesLeft`, `Hotbar`, `FindFirstChild`, `Ability`, `ready`, `counts`, `tostring`, `Text`, `updateRemainingLabel`, `BountyUses`, `GetAttribute`, `workspace`, `Alive`, `GameActive`, `Character`, `PlayerGui`, `Red`, `Visible`, `Dead`, `Misc`, `error`, `Play`, `getAbilityCooldown`, `script`, `next`, `GetChildren`, `AreCharactersEnemies`, `IsBountyTarget`, `IsEncryptedClone`, `IsDoppelganger`, `IsBoss`, `Invisible`, `HumanoidRootPart`, `Position`, `WorldToScreenPoint`, `Vector2`, `X`, `Y`, `Magnitude`, `ShowdownActive`, `Remotes`, `VisualBindableCD`, `Fire`, `delay`, `PlrBountiedFunction`, `InvokeServer`, `ability`, `UseBind`, `Thread`, `SafeCancel`, `game`, `Players`, `LocalPlayer`, `CharacterAdded`, `Wait`, `require`, `ReplicatedStorage`, `GetService`, `UserInputService`, `WaitForChild`, `Humanoid`, `Debris`, `Controllers`, `SettingsController`, `Shared`, `ThreadSafeTargetingHelper`, `Common`, `Utils`, `Abilities`, `CurrentCamera`, `GetMouse`, `Vector`, `iconId`, `Image`, `ChildAdded`, `Upgrades`, `GetAttributeChangedSignal`, `InputBegan`, `AbilityButtonPress`, `Event`, `EndCD`, `OnClientEvent`

### [7] 7icbvx.Abilities.Bunny Leap
`LocalScript` · bytecode v9 · 4463 bytes · 83 constants
- **Remotes:** AbilityButtonHold, Data, EndCD, KeybindM2, PlrBunnyCancelled, PlrBunnyLeaped, VisualBindableCD
- **Services:** Debris, Players, ReplicatedStorage, UserInputService, game, workspace
- **Key API:** Connect, FindFirstChild, Fire, FireServer, GetAttribute, GetService, OnClientEvent, WaitForChild
- Constants: `Misc`, `DataAbilities`, `FindFirstChild`, `GetAttributes`, `AbilityUpgrades`, `Get`, `Icon`, `Vector`, `Image`, `updateIcon`, `workspace`, `GameActive`, `GetAttribute`, `Parent`, `Alive`, `Red`, `Visible`, `Dead`, `getAbilityCooldown`, `task`, `delay`, `Remotes`, `PlrBunnyLeaped`, `FireServer`, `VisualBindableCD`, `Fire`, `activateBasic`, `activateHop`, `CAN_BUNNY_SLAM`, `PlrBunnyCancelled`, `activateSlam`, `wait`, `ability`, `Thread`, `SafeCancel`, `Ability`, `UseBind`, `Enum`, `UserInputType`, `MouseButton2`, `game`, `Debris`, `GetService`, `Players`, `ReplicatedStorage`, `require`, `UserInputService`, `WaitForChild`, `Assets`, `Controllers`, `Packages`, `Shared`, `script`, `Name`, `Abilities`, `Net`, `Replion`, `SettingsController`, `Common`, `Utils`, `LocalPlayer`, `Character`, `CharacterAdded`, `Wait`, `Humanoid`, `Upgrades`, `PlayerGui`, `Hotbar`, `Client`, `Data`, `WaitReplion`, `spawn`, `OnChange`, `Destroying`, `Connect`, `InputBegan`, `InputEnded`, `AbilityButtonHold`, `Event`, `EndCD`, `OnClientEvent`, `KeybindM2`

### [8] 7icbvx.Abilities.Calming Deflection
`LocalScript` · bytecode v9 · 3450 bytes · 78 constants
- **Remotes:** AbilityButtonPress, EndCD, KeybindM2, PlrCalmingDeflectiond, RagingDeflectionSuccess2, VisualBindableCD
- **Services:** Debris, Players, ReplicatedStorage, UserInputService, game, workspace
- **Key API:** Connect, Fire, FireServer, GetChildren, GetService, LoadAnimation, OnClientEvent, Stop, WaitForChild
- Constants: `Character`, `Parent`, `workspace`, `Alive`, `PlayerGui`, `Hotbar`, `Ability`, `Red`, `Visible`, `getAbilityCooldown`, `script`, `Name`, `task`, `delay`, `next`, `GetChildren`, `HumanoidRootPart`, `Position`, `WorldToScreenPoint`, `Remotes`, `PlrCalmingDeflectiond`, `CurrentCamera`, `CFrame`, `X`, `Y`, `FireServer`, `VisualBindableCD`, `Fire`, `playAnimationTrack`, `wait`, `Stop`, `ability`, `UseBind`, `Initial Calming Deflect Debuff`, `RemoveModifierFor`, `Thread`, `SafeCancel`, `Enum`, `UserInputType`, `MouseButton2`, `game`, `ReplicatedStorage`, `GetService`, `Players`, `LocalPlayer`, `CharacterAdded`, `Wait`, `require`, `UserInputService`, `WaitForChild`, `Humanoid`, `Debris`, `Controllers`, `SettingsController`, `Common`, `Utils`, `Shared`, `SpeedModifiers`, `AbilityUtils`, `Abilities`, `attempt`, `Animator`, `FindFirstChildOfClass`, `LoadAnimation`, `success`, `GetMouse`, `Vector`, `iconId`, `Image`, `InputBegan`, `Connect`, `AbilityButtonPress`, `Event`, `RagingDeflectionSuccess2`, `OnClientEvent`, `EndCD`, `KeybindM2`

### [9] 7icbvx.Abilities.Chieftain's Totem
`LocalScript` · bytecode v9 · 2026 bytes · 55 constants
- **Remotes:** AbilityButtonPress, EndCD, VisualBindableCD
- **Services:** Debris, Players, ReplicatedStorage, UserInputService, game, workspace
- **Key API:** Connect, Fire, FireServer, GetService, OnClientEvent, WaitForChild
- Constants: `Character`, `Parent`, `workspace`, `Alive`, `Red`, `Visible`, `getAbilityCooldown`, `script`, `Name`, `FireServer`, `Remotes`, `VisualBindableCD`, `Fire`, `task`, `delay`, `ability`, `Ability`, `UseBind`, `Thread`, `SafeCancel`, `game`, `ReplicatedStorage`, `GetService`, `require`, `UserInputService`, `WaitForChild`, `Players`, `Debris`, `Packages`, `Net`, `Common`, `Utils`, `Controllers`, `SettingsController`, `Shared`, `Abilities`, `LocalPlayer`, `CharacterAdded`, `Wait`, `Humanoid`, `ChieftainsTotemActivate`, `RemoteEvent`, `PlayerGui`, `Hotbar`, `Vector`, `iconId`, `Image`, `cooldown`, `InputBegan`, `Connect`, `AbilityButtonPress`, `Event`, `EndCD`, `OnClientEvent`

### [10] 7icbvx.Abilities.Continuity Zero
`LocalScript` · bytecode v9 · 3759 bytes · 85 constants
- **Remotes:** AbilityButtonPress, EndCD, KeybindM2, PlaceContinuityPortal, RoundEnded, UseContinuityPortal, VisualBindableCD
- **Services:** Debris, Players, ReplicatedStorage, UserInputService, Workspace, game, workspace
- **Key API:** Connect, Destroy, FindFirstChild, Fire, FireServer, GetAttribute, GetChildren, GetService, OnClientEvent, WaitForChild, new
- Constants: `Character`, `Parent`, `workspace`, `Alive`, `PlayerGui`, `Hotbar`, `Ability`, `Red`, `Visible`, `GameActive`, `GetAttribute`, `UIGradient`, `Offset`, `Y`, `PortalFor_%*`, `Name`, `format`, `Runtime`, `FindFirstChild`, `Remotes`, `PlaceContinuityPortal`, `GetPivot`, `Fire`, `task`, `delay`, `VisualBindableCD`, `Balls`, `GetChildren`, `realBall`, `Position`, `WorldToScreenPoint`, `Vector2`, `new`, `X`, `Magnitude`, `UseContinuityPortal`, `CFrame`, `FireServer`, `getAbilityCooldown`, `script`, `ability`, `UseBind`, `Thread`, `SafeCancel`, `Enum`, `UserInputType`, `MouseButton2`, `next`, `PortalFor_`, `find`, `Destroy`, `game`, `ReplicatedStorage`, `GetService`, `Players`, `LocalPlayer`, `CharacterAdded`, `Wait`, `require`, `UserInputService`, `WaitForChild`, `Humanoid`, `Debris`, `Workspace`, `CurrentCamera`, `FieldOfView`, `Controllers`, `SettingsController`, `Common`, `Utils`, `Shared`, `Abilities`, `GetMouse`, `Vector`, `iconId`, `Image`, `InputBegan`, `Connect`, `AbilityButtonPress`, `Event`, `EndCD`, `OnClientEvent`, `KeybindM2`, `RoundEnded`

### [11] 7icbvx.Abilities.Dash
`LocalScript` · bytecode v9 · 5557 bytes · 126 constants
- **Remotes:** AbilityButtonPress, DashFired, EndCD, PlrDashed, VisualBindableCD
- **Services:** Debris, Players, ReplicatedStorage, RunService, TweenService, UserInputService, Workspace, game, workspace
- **Key API:** Connect, Create, Disconnect, FindFirstChild, Fire, FireServer, GetAttribute, GetDescendants, GetService, IsA, LoadAnimation, OnClientEvent, Play, SetAttribute, WaitForChild, new
- Constants: `cooldownThread`, `BasePart`, `IsA`, `Massless`, `DashSetMassless`, `SetAttribute`, `ipairs`, `GetDescendants`, `DescendantAdded`, `Connect`, `GetAttribute`, `Enabled`, `Disconnect`, `PrimaryPart`, `AssemblyLinearVelocity`, `AssemblyAngularVelocity`, `Character`, `Parent`, `workspace`, `Alive`, `PlayerGui`, `Hotbar`, `Ability`, `Red`, `Visible`, `MoveDirection`, `Upgrades`, `script`, `Name`, `Value`, `getAbilityCooldown`, `task`, `delay`, `FieldOfView`, `game`, `Workspace`, `CurrentCamera`, `TweenInfo`, `new`, `Enum`, `EasingStyle`, `Linear`, `EasingDirection`, `Out`, `TweenService`, `GetService`, `Create`, `Play`, `X`, `math`, `deg`, `Y`, `Z`, `GetScale`, `Remotes`, `DashFired`, `Fire`, `VisualBindableCD`, `PlrDashed`, `FireServer`, `playAnimationTrack`, `HumanoidRootPart`, `CFrame`, `rightVector`, `lookVector`, `Dot`, `random`, `clamp`, `Instance`, `Attachment`, `LinearVelocity`, `Dash`, `ForceLimitMode`, `PerAxis`, `MaxAxesForce`, `Attachment0`, `VectorVelocity`, `AddItem`, `defer`, `Colliders`, `FindFirstChild`, `Pin`, `RigidConstraint`, `FindFirstChildWhichIsA`, `wait`, `ability`, `UseBind`, `RunService`, `RenderStepped`, `Wait`, `UserSettings`, `UserGameSettings`, `RotationType`, `MovementRelative`, `spawn`, `Thread`, `SafeCancel`, `ReplicatedStorage`, `Players`, `LocalPlayer`, `CharacterAdded`, `require`, `UserInputService`, `WaitForChild`, `Humanoid`, `Debris`, `Controllers`, `SettingsController`, `Shared`, `GetAbilityCooldownMultiplier`, `Common`, `Utils`, `AbilityUtils`, `Abilities`, `Animator`, `FindFirstChildOfClass`, `LoadAnimation`, `Vector`, `iconId`, `Image`, `InputBegan`, `AbilityButtonPress`, `Event`, `EndCD`, `OnClientEvent`

### [12] 7icbvx.Abilities.Death Slash
`LocalScript` · bytecode v9 · 5723 bytes · 122 constants
- **Remotes:** AbilityButtonPress, Data, DeathSlashSuccess2, EndCD, KeybindM2, M1Stop, VisualBindableCD
- **Services:** Players, ReplicatedStorage, UserInputService, game, workspace
- **Key API:** Connect, Disconnect, FindFirstChild, Fire, FireServer, GetAttribute, GetChildren, GetService, InvokeServer, LoadAnimation, OnClientEvent, Stop, WaitForChild
- Constants: `DataAbilities`, `FindFirstChild`, `GetAttributes`, `AbilityUpgrades`, `Get`, `Icon`, `Image`, `UpdateIcon`, `Disconnect`, `Parent`, `workspace`, `Alive`, `Ability`, `Red`, `Visible`, `getAbilityCooldown`, `script`, `Name`, `getAbilityUpgrade`, `task`, `delay`, `InvokeServer`, `Thread`, `SafeCancel`, `ToggleUIOn`, `M1Stop`, `Fire`, `playAnimationTrack`, `Initial Death Slash Use`, `Utils`, `MinDebuff`, `Priority`, `DEBUFF`, `SetModifierFor`, `VisualBindableCD`, `DoubleJumping`, `GetAttribute`, `wait`, `next`, `Balls`, `GetChildren`, `realBall`, `string`, `find`, `SingularityInOrbit`, `FuryCatch`, `Frozen`, `Position`, `Magnitude`, `FireServer`, `OnClientEvent`, `Connect`, `os`, `clock`, `activateUI`, `HumanoidRootPart`, `WorldToScreenPoint`, `CurrentCamera`, `CFrame`, `X`, `Y`, `Stop`, `ability`, `UseBind`, `Enum`, `UserInputType`, `MouseButton2`, `CurrentlyEquippedAbility`, `Death Slash`, `ToggleUIOff`, `game`, `Players`, `GetService`, `ReplicatedStorage`, `require`, `UserInputService`, `WaitForChild`, `Common`, `Controllers`, `Misc`, `Packages`, `Remotes`, `Shared`, `LocalPlayer`, `GetMouse`, `Character`, `CharacterAdded`, `Wait`, `Humanoid`, `Animator`, `charge`, `LoadAnimation`, `charge_hold`, `swinga`, `Abilities`, `AbilityUtils`, `Net`, `Replion`, `SettingsController`, `SpeedModifiers`, `JumpModifiers`, `TimingUIHandler`, `NewAbilities/ActivePrimarySlot`, `RemoteFunction`, `DeathSlashShootPreActivation`, `RemoteEvent`, `DeathSlashShootActivation`, `PlayerGui`, `Hotbar`, `Vector`, `Client`, `Data`, `WaitReplion`, `OnChange`, `InputBegan`, `AbilityButtonPress`, `Event`, `EndCD`, `DeathSlashSuccess2`, `KeybindM2`, `GetAttributeChangedSignal`

### [13] 7icbvx.Abilities.Death Slash.TimingUIHandler
`ModuleScript` · bytecode v9 · 2808 bytes · 64 constants
- **Services:** Players, ReplicatedStorage, SoundService, TweenService, UserInputService, game
- **Key API:** Connect, Create, Fire, GetService, Play, WaitForChild, new
- Constants: `Parent`, `Enabled`, `ToggleUIOn`, `ToggleUIOff`, `Ability`, `UseBind`, `UserInputType`, `Enum`, `MouseButton1`, `Touch`, `getTimingInput`, `Fire`, `giveFeedback`, `task`, `wait`, `Visible`, `Size`, `BackgroundColor3`, `Maid`, `new`, `UDim2`, `Create`, `Play`, `InputBegan`, `Connect`, `GiveTask`, `Completed`, `Wait`, `DoCleaning`, `Cancel`, `spawn`, `activateUI`, `X`, `Scale`, `script`, `Success`, `PlayLocalSound`, `Color3`, `Failure`, `game`, `Players`, `GetService`, `TweenService`, `require`, `ReplicatedStorage`, `UserInputService`, `WaitForChild`, `SoundService`, `Controllers`, `SettingsController`, `Common`, `Utils`, `LocalPlayer`, `PlayerGui`, `DeathSlashTimer`, `Frame`, `ImageLabel`, `Circle`, `Inner`, `fromRGB`, `TweenInfo`, `EasingStyle`, `Linear`, `Signal`

### [14] 7icbvx.Abilities.Displace
`LocalScript` · bytecode v9 · 2596 bytes · 69 constants
- **Remotes:** AbilityButtonPress, EndCD, VisualBindableCD
- **Services:** Debris, Players, ReplicatedStorage, TweenService, UserInputService, game, workspace
- **Key API:** Connect, Create, Fire, FireServer, GetChildren, GetService, OnClientEvent, Play, WaitForChild, new
- Constants: `Character`, `Parent`, `workspace`, `Alive`, `PlayerGui`, `Hotbar`, `Ability`, `Red`, `Visible`, `Balls`, `GetChildren`, `TweenInfo`, `new`, `Enum`, `EasingStyle`, `Linear`, `EasingDirection`, `Out`, `FieldOfView`, `Create`, `Play`, `getAbilityCooldown`, `script`, `Name`, `FireServer`, `Remotes`, `VisualBindableCD`, `Fire`, `task`, `delay`, `ability`, `UseBind`, `UserInputType`, `Thread`, `SafeCancel`, `game`, `TweenService`, `GetService`, `require`, `ReplicatedStorage`, `UserInputService`, `WaitForChild`, `Players`, `Debris`, `CurrentCamera`, `LocalPlayer`, `CharacterAdded`, `Wait`, `Humanoid`, `Controllers`, `SettingsController`, `Packages`, `Net`, `Common`, `Utils`, `Shared`, `Abilities`, `Displace`, `RemoteEvent`, `Vector`, `iconId`, `Image`, `InputBegan`, `Connect`, `AbilityButtonPress`, `Event`, `EndCD`, `OnClientEvent`

### [15] 7icbvx.Abilities.Doppelganger
`LocalScript` · bytecode v9 · 7023 bytes · 135 constants
- **Remotes:** AbilityButtonPress, Data, DoubleJump, EndCD, VisualBindableCD
- **Services:** Debris, Players, ReplicatedStorage, UserInputService, game, workspace
- **Key API:** Connect, FindFirstChild, Fire, FireServer, GetAttribute, GetChildren, GetService, InvokeServer, LoadAnimation, OnClientEvent, Play, Stop, WaitForChild, new
- Constants: `Misc`, `DataAbilities`, `script`, `Name`, `FindFirstChild`, `GetAttributes`, `AbilityUpgrades`, `Get`, `Icon`, `Vector`, `Image`, `updateIcon`, `GetPivot`, `Position`, `X`, `Z`, `Y`, `Vector3`, `new`, `CFrame`, `getMirrorPlayerPosition`, `RaycastParams`, `IgnoreWater`, `RespectCanCollide`, `Enum`, `RaycastFilterType`, `Include`, `FilterType`, `workspace`, `Map`, `FilterDescendantsInstances`, `math`, `cos`, `sin`, `Raycast`, `getBotMirrorLocation`, `Parent`, `Alive`, `Upgrades`, `Value`, `GetChildren`, `IsDoppelganger`, `GetAttribute`, `DoppelgangerOwner`, `FireServer`, `Character`, `Red`, `Visible`, `AreCharactersEnemies`, `error`, `Play`, `InvokeServer`, `Remotes`, `VisualBindableCD`, `Fire`, `task`, `wait`, `getAbilityUpgrade`, `getAbilityCooldown`, `delay`, `ability`, `os`, `clock`, `FloorMaterial`, `Material`, `Air`, `spawn`, `Instance`, `BodyVelocity`, `Dash`, `PrimaryPart`, `MaxForce`, `Velocity`, `AddItem`, `Stop`, `botJumpRequest`, `Dead`, `Jump`, `Humanoid`, `WaitForChild`, `Animator`, `LoadAnimation`, `FLOOR`, `JumpRequest`, `Event`, `Connect`, `MoveTo`, `setDoppelganger`, `Ability`, `UseBind`, `Thread`, `SafeCancel`, `game`, `Debris`, `GetService`, `Players`, `ReplicatedStorage`, `require`, `UserInputService`, `Assets`, `Tutorial`, `Controllers`, `Packages`, `Shared`, `Animations`, `DoubleJump`, `Abilities`, `AbilityUtils`, `Net`, `Replion`, `SettingsController`, `ThreadSafeTargetingHelper`, `Common`, `Utils`, `LocalPlayer`, `CharacterAdded`, `Wait`, `HumanoidRootPart`, `NewAbilities/ActivePrimarySlot`, `RemoteFunction`, `DoppelgangerSwap`, `RemoteEvent`, `PlayerGui`, `Hotbar`, `Client`, `Data`, `WaitReplion`, `OnChange`, `Destroying`, `ChildAdded`, `InputBegan`, `AbilityButtonPress`, `EndCD`, `OnClientEvent`

### [16] 7icbvx.Abilities.Dragon Spirit
`LocalScript` · bytecode v9 · 4864 bytes · 92 constants
- **Remotes:** AbilityButtonPress, Data, EndCD, KeybindM2, ParrySuccess, PlrDragonSummoned, SyncDragonSpirit, VisualBindableCD
- **Services:** Debris, Players, ReplicatedStorage, UserInputService, game, workspace
- **Key API:** Connect, FindFirstChild, Fire, GetAttribute, GetChildren, GetService, InvokeServer, OnClientEvent, Play, WaitForChild
- Constants: `Misc`, `DataAbilities`, `script`, `Name`, `FindFirstChild`, `GetAttributes`, `AbilityUpgrades`, `Get`, `Icon`, `Image`, `updateIcon`, `OnChange`, `Hotbar`, `WaitForChild`, `Ability`, `ready`, `counts`, `tostring`, `Text`, `updateRemainingLabel`, `game`, `Players`, `LocalPlayer`, `Character`, `Upgrades`, `Value`, `Remotes`, `VisualBindableCD`, `Fire`, `error`, `Play`, `workspace`, `Balls`, `GetChildren`, `next`, `realBall`, `GetAttribute`, `target`, `Parent`, `Alive`, `PlayerGui`, `Red`, `Visible`, `GoldenAbilities`, `ShowdownActive`, `PlrDragonSummoned`, `InvokeServer`, `task`, `delay`, `defer`, `ability`, `UseBind`, `Thread`, `SafeCancel`, `Enum`, `UserInputType`, `MouseButton2`, `ReplicatedStorage`, `GetService`, `CharacterAdded`, `Wait`, `Humanoid`, `Debris`, `require`, `UserInputService`, `Controllers`, `SettingsController`, `Packages`, `Replion`, `Common`, `Utils`, `CurrentCamera`, `FieldOfView`, `Vector`, `Shared`, `Abilities`, `Client`, `Data`, `AwaitReplion`, `Dead`, `ChildAdded`, `Connect`, `Changed`, `ParrySuccess`, `OnClientEvent`, `SyncDragonSpirit`, `InputBegan`, `AbilityButtonPress`, `Event`, `EndCD`, `KeybindM2`

### [17] 7icbvx.Abilities.Dribble
`LocalScript` · bytecode v9 · 3873 bytes · 85 constants
- **Remotes:** AbilityButtonPress, Data, EndCD, KeybindM2, ParrySuccess, VisualBindableCD
- **Services:** Players, ReplicatedStorage, UserInputService, game, workspace
- **Key API:** Connect, FindFirstChild, Fire, GetService, InvokeServer, OnClientEvent, Play, WaitForChild
- Constants: `AbilityUpgrades`, `Get`, `DataAbilities`, `FindFirstChild`, `GetAttributes`, `Icon`, `Image`, `UpdateIcon`, `Hotbar`, `WaitForChild`, `Ability`, `ready`, `counts`, `tostring`, `Text`, `updateRemainingLabel`, `Character`, `getAbilityUpgrade`, `task`, `wait`, `math`, `clamp`, `defer`, `VisualBindableCD`, `Fire`, `error`, `Play`, `Parent`, `workspace`, `Alive`, `Red`, `Visible`, `delay`, `spawn`, `CFrame`, `InvokeServer`, `ability`, `UseBind`, `Thread`, `SafeCancel`, `Enum`, `UserInputType`, `MouseButton2`, `game`, `Players`, `GetService`, `ReplicatedStorage`, `require`, `UserInputService`, `Common`, `Controllers`, `Misc`, `Packages`, `Remotes`, `Shared`, `script`, `Name`, `CurrentCamera`, `LocalPlayer`, `CharacterAdded`, `Wait`, `AbilityUtils`, `Net`, `Replion`, `SettingsController`, `Utils`, `NewAbilities/ActivePrimarySlot`, `RemoteFunction`, `PlayerGui`, `Vector`, `Client`, `Data`, `WaitReplion`, `OnChange`, `Dead`, `ChildAdded`, `Connect`, `ParrySuccess`, `OnClientEvent`, `InputBegan`, `AbilityButtonPress`, `Event`, `EndCD`, `KeybindM2`

### [18] 7icbvx.Abilities.Encrypted Clone
`LocalScript` · bytecode v9 · 2659 bytes · 65 constants
- **Remotes:** AbilityButtonPress, EndCD, VisualBindableCD
- **Services:** Debris, Players, ReplicatedStorage, UserInputService, game, workspace
- **Key API:** Connect, Fire, FireServer, GetAttribute, GetChildren, GetService, OnClientEvent, Play, WaitForChild
- Constants: `Parent`, `workspace`, `Alive`, `Upgrades`, `script`, `Name`, `Value`, `GetChildren`, `IsEncryptedClone`, `GetAttribute`, `EncryptedCloneOwner`, `FireServer`, `Character`, `Red`, `Visible`, `AreCharactersEnemies`, `Misc`, `error`, `Play`, `getAbilityCooldown`, `Remotes`, `VisualBindableCD`, `Fire`, `task`, `delay`, `ability`, `Ability`, `UseBind`, `Thread`, `SafeCancel`, `game`, `ReplicatedStorage`, `GetService`, `require`, `UserInputService`, `WaitForChild`, `Players`, `Debris`, `Packages`, `Net`, `Controllers`, `SettingsController`, `Shared`, `ThreadSafeTargetingHelper`, `Common`, `Utils`, `Abilities`, `LocalPlayer`, `CharacterAdded`, `Wait`, `Humanoid`, `EncryptedClone`, `RemoteEvent`, `PlayerGui`, `Hotbar`, `Vector`, `iconId`, `Image`, `InputBegan`, `Connect`, `AbilityButtonPress`, `Event`, `EndCD`, `OnClientEvent`

### [19] 7icbvx.Abilities.Event Horizon
`LocalScript` · bytecode v9 · 2647 bytes · 68 constants
- **Remotes:** AbilityButtonPress, Data, EndCD, VisualBindableCD
- **Services:** Players, ReplicatedStorage, UserInputService, game, workspace
- **Key API:** Connect, FindFirstChild, Fire, GetAttribute, GetService, InvokeServer, OnClientEvent, WaitForChild
- Constants: `DataAbilities`, `FindFirstChild`, `GetAttributes`, `AbilityUpgrades`, `Get`, `Icon`, `Image`, `UpdateIcon`, `Parent`, `workspace`, `Alive`, `Ability`, `Red`, `Visible`, `EventHorizonInUse`, `GetAttribute`, `getAbilityCooldown`, `script`, `Name`, `task`, `delay`, `VisualBindableCD`, `Fire`, `InvokeServer`, `ability`, `UseBind`, `Thread`, `SafeCancel`, `game`, `Players`, `GetService`, `ReplicatedStorage`, `require`, `UserInputService`, `WaitForChild`, `Common`, `Controllers`, `Misc`, `Packages`, `Remotes`, `Shared`, `LocalPlayer`, `Character`, `CharacterAdded`, `Wait`, `CurrentCamera`, `Abilities`, `AbilityUtils`, `Net`, `Replion`, `SettingsController`, `Utils`, `NewAbilities/ActivePrimarySlot`, `RemoteFunction`, `PlayerGui`, `Hotbar`, `Vector`, `Client`, `Data`, `WaitReplion`, `OnChange`, `InputBegan`, `Connect`, `AbilityButtonPress`, `Event`, `EndCD`, `OnClientEvent`

### [20] 7icbvx.Abilities.Flash Counter
`LocalScript` · bytecode v9 · 3358 bytes · 81 constants
- **Remotes:** AbilityButtonPress, EndCD, KeybindM2, PlrFlashCountered, VisualBindableCD
- **Services:** Debris, Players, ReplicatedStorage, UserInputService, game, workspace
- **Key API:** Connect, Fire, FireServer, GetAttribute, GetChildren, GetService, LoadAnimation, OnClientEvent, Play, Stop, WaitForChild
- Constants: `Character`, `Parent`, `workspace`, `Alive`, `PlayerGui`, `Hotbar`, `Ability`, `Red`, `Visible`, `Balls`, `GetChildren`, `Misc`, `error`, `Play`, `next`, `realBall`, `GetAttribute`, `from`, `getAbilityCooldown`, `script`, `Name`, `task`, `delay`, `Remotes`, `PlrFlashCountered`, `FireServer`, `VisualBindableCD`, `Fire`, `Initial Flash Counter Debuff`, `Utils`, `MinDebuff`, `Priority`, `DEBUFF`, `SetModifierFor`, `playAnimationTrack`, `wait`, `Stop`, `ability`, `UseBind`, `Thread`, `SafeCancel`, `Enum`, `UserInputType`, `MouseButton2`, `game`, `ReplicatedStorage`, `GetService`, `Players`, `LocalPlayer`, `CharacterAdded`, `Wait`, `require`, `UserInputService`, `WaitForChild`, `Humanoid`, `Debris`, `Controllers`, `SettingsController`, `Common`, `Shared`, `AbilityUtils`, `Abilities`, `SpeedModifiers`, `attempt`, `Animator`, `FindFirstChildOfClass`, `LoadAnimation`, `success`, `CurrentCamera`, `GetMouse`, `Vector`, `iconId`, `Image`, `InputBegan`, `Connect`, `AbilityButtonPress`, `Event`, `EndCD`, `OnClientEvent`, `KeybindM2`

### [21] 7icbvx.Abilities.Force
`LocalScript` · bytecode v9 · 4950 bytes · 97 constants
- **Remotes:** AbilityButtonPress, EndCD, ForceAbilityActivate, KeybindM2, VisualBindableCD
- **Services:** Debris, Players, ReplicatedStorage, TweenService, UserInputService, Workspace, game, workspace
- **Key API:** Clone, Connect, Create, Fire, FireServer, GetChildren, GetService, OnClientEvent, Play, WaitForChild, new
- Constants: `task`, `wait`, `Play`, `Misc`, `Wave`, `Clone`, `workspace`, `Runtime`, `Parent`, `Size`, `Transparency`, `Vector3`, `new`, `CFrame`, `Angles`, `Color`, `game`, `TweenService`, `TweenInfo`, `Enum`, `EasingStyle`, `Quad`, `EasingDirection`, `Out`, `Create`, `AddItem`, `spawn`, `shockwave`, `HumanoidRootPart`, `forcePart`, `Color3`, `forcePart2`, `forcePart3`, `Players`, `LocalPlayer`, `Character`, `Position`, `hit`, `PlaybackSpeed`, `pairs`, `At2`, `GetChildren`, `Name`, `tonumber`, `Emit`, `USEFORCE`, `Alive`, `PlayerGui`, `Hotbar`, `Ability`, `Red`, `Visible`, `getAbilityCooldown`, `script`, `Upgrades`, `Value`, `delay`, `Remotes`, `VisualBindableCD`, `Fire`, `ForceAbilityActivate`, `FireServer`, `ability`, `UseBind`, `Thread`, `SafeCancel`, `UserInputType`, `MouseButton2`, `ReplicatedStorage`, `GetService`, `CharacterAdded`, `Wait`, `require`, `UserInputService`, `WaitForChild`, `Humanoid`, `Debris`, `Workspace`, `CurrentCamera`, `FieldOfView`, `Controllers`, `SettingsController`, `Common`, `Utils`, `Shared`, `Abilities`, `Vector`, `iconId`, `Image`, `InputBegan`, `Connect`, `AbilityButtonPress`, `Event`, `EndCD`, `OnClientEvent`, `KeybindM2`

### [22] 7icbvx.Abilities.Forcefield
`LocalScript` · bytecode v9 · 2417 bytes · 58 constants
- **Remotes:** AbilityButtonPress, EndCD, KeybindM2, PlrForcefielded, VisualBindableCD
- **Services:** Debris, Players, ReplicatedStorage, UserInputService, game, workspace
- **Key API:** Connect, Fire, FireServer, GetService, OnClientEvent, WaitForChild
- Constants: `Character`, `Parent`, `workspace`, `Alive`, `PlayerGui`, `Hotbar`, `Ability`, `Red`, `Visible`, `getAbilityCooldown`, `script`, `Name`, `Upgrades`, `Value`, `ShowdownActive`, `Remotes`, `PlrForcefielded`, `FireServer`, `VisualBindableCD`, `Fire`, `task`, `delay`, `ability`, `UseBind`, `Thread`, `SafeCancel`, `Enum`, `UserInputType`, `MouseButton2`, `game`, `ReplicatedStorage`, `GetService`, `Players`, `LocalPlayer`, `CharacterAdded`, `Wait`, `require`, `UserInputService`, `WaitForChild`, `Humanoid`, `Debris`, `Controllers`, `SettingsController`, `Common`, `Utils`, `Shared`, `Abilities`, `Vector`, `iconId`, `Image`, `InputBegan`, `Connect`, `AbilityButtonPress`, `Event`, `EndCD`, `OnClientEvent`, `KeybindM2`

### [23] 7icbvx.Abilities.Fracture
`LocalScript` · bytecode v9 · 6155 bytes · 128 constants
- **Remotes:** AbilityButtonPress, Data, EndCD, SyncFractureBoost, UpdateFractureBoostDB, VisualBindableCD
- **Services:** Debris, Players, ReplicatedStorage, UserInputService, game, workspace
- **Key API:** Connect, FindFirstChild, Fire, GetAttribute, GetChildren, GetService, InvokeServer, LoadAnimation, OnClientEvent, Stop, WaitForChild, new
- Constants: `Misc`, `DataAbilities`, `script`, `Name`, `FindFirstChild`, `GetAttributes`, `AbilityUpgrades`, `Get`, `Icon`, `Icon%*`, `format`, `Vector`, `WaitForChild`, `Image`, `updateIcon`, `OnChange`, `Visible`, `Red`, `UDim2`, `fromScale`, `Position`, `UIGradient`, `Enabled`, `workspace`, `ShowdownActive`, `Value`, `UsedFracture`, `GetAttribute`, `tostring`, `Text`, `updateRemainingLabel`, `task`, `defer`, `Background`, `Bar`, `Color3`, `fromRGB`, `BackgroundColor3`, `Size`, `fastTween`, `TweenInfo`, `new`, `Enum`, `EasingStyle`, `Linear`, `wait`, `updateDB`, `CFrame`, `X`, `Y`, `InvokeServer`, `Character`, `Parent`, `Alive`, `GetChildren`, `GetPivot`, `WorldToScreenPoint`, `xpcall`, `warn`, `playAnimationTrack`, `delay`, `getAbilityCooldown`, `type`, `number`, `Remotes`, `VisualBindableCD`, `Fire`, `ability`, `Ability`, `UseBind`, `coroutine`, `status`, `suspended`, `pcall`, `cancel`, `spawn`, `IsPlaying`, `Stop`, `game`, `ReplicatedStorage`, `GetService`, `require`, `UserInputService`, `Players`, `Debris`, `Packages`, `Net`, `Replion`, `Controllers`, `SettingsController`, `Shared`, `AbilityUtils`, `Abilities`, `FastUtils`, `DisableFractureUI`, `LocalPlayer`, `CharacterAdded`, `Wait`, `Humanoid`, `Animator`, `FractureSlash`, `RemoteFunction`, `CurrentCamera`, `GetMouse`, `PlayerGui`, `Hotbar`, `ready`, `counts`, `DurationOld`, `Upgrades`, `attempt`, `LoadAnimation`, `success`, `Client`, `Data`, `AwaitReplion`, `GetAttributeChangedSignal`, `Connect`, `SyncFractureBoost`, `OnClientEvent`, `UpdateFractureBoostDB`, `InputBegan`, `AbilityButtonPress`, `Event`, `EndCD`, `FractureSlashEvent`, `RemoteEvent`

### [24] 7icbvx.Abilities.Fracture.DisableFractureUI
`ModuleScript` · bytecode v9 · 970 bytes · 22 constants
- **Services:** Players, ReplicatedStorage, game
- **Key API:** Connect, Disconnect, GetAttribute, GetService, WaitForChild
- Constants: `script`, `game`, `IsDescendantOf`, `Disconnect`, `Visible`, `CurrentlyEquippedAbility`, `GetAttribute`, `Fracture`, `ReplicatedStorage`, `GetService`, `Players`, `LocalPlayer`, `PlayerGui`, `WaitForChild`, `Hotbar`, `Ability`, `ready`, `counts`, `DurationOld`, `AncestryChanged`, `Connect`, `GetAttributeChangedSignal`

### [25] 7icbvx.Abilities.Freeze
`LocalScript` · bytecode v9 · 2343 bytes · 57 constants
- **Remotes:** AbilityButtonPress, EndCD, Freeze, KeybindM2, VisualBindableCD
- **Services:** Debris, Players, ReplicatedStorage, UserInputService, game, workspace
- **Key API:** Connect, Fire, FireServer, GetService, OnClientEvent, WaitForChild
- Constants: `Character`, `Parent`, `workspace`, `Alive`, `PlayerGui`, `Hotbar`, `Ability`, `Red`, `Visible`, `getAbilityCooldown`, `script`, `Name`, `Remotes`, `VisualBindableCD`, `Fire`, `Freeze`, `FireServer`, `task`, `delay`, `ability`, `UseBind`, `Thread`, `SafeCancel`, `Enum`, `UserInputType`, `MouseButton2`, `game`, `ReplicatedStorage`, `GetService`, `Players`, `LocalPlayer`, `CharacterAdded`, `Wait`, `require`, `UserInputService`, `WaitForChild`, `Humanoid`, `Debris`, `Controllers`, `SettingsController`, `Common`, `Utils`, `Shared`, `Abilities`, `CurrentCamera`, `GetMouse`, `Vector`, `iconId`, `Image`, `InputBegan`, `Connect`, `AbilityButtonPress`, `Event`, `EndCD`, `OnClientEvent`, `KeybindM2`

### [26] 7icbvx.Abilities.Freeze Trap
`LocalScript` · bytecode v9 · 2509 bytes · 63 constants
- **Remotes:** AbilityButtonPress, EndCD, KeybindM2, Platform, PlrFreezeTrapped, VisualBindableCD
- **Services:** Debris, Players, ReplicatedStorage, RunService, UserInputService, game, workspace
- **Key API:** Connect, Fire, FireServer, GetService, LoadAnimation, OnClientEvent, WaitForChild
- Constants: `Character`, `Parent`, `workspace`, `Alive`, `PlayerGui`, `Hotbar`, `Ability`, `Red`, `Visible`, `FloorMaterial`, `Enum`, `Material`, `Air`, `getAbilityCooldown`, `script`, `Name`, `Remotes`, `VisualBindableCD`, `Fire`, `PlrFreezeTrapped`, `FireServer`, `task`, `delay`, `ability`, `UseBind`, `Thread`, `SafeCancel`, `UserInputType`, `MouseButton2`, `game`, `ReplicatedStorage`, `GetService`, `Players`, `LocalPlayer`, `CharacterAdded`, `Wait`, `require`, `UserInputService`, `WaitForChild`, `Humanoid`, `Debris`, `RunService`, `Controllers`, `SettingsController`, `Common`, `Utils`, `Shared`, `Abilities`, `Platform`, `Animator`, `FindFirstChildOfClass`, `LoadAnimation`, `Vector`, `iconId`, `Image`, `InputBegan`, `Connect`, `AbilityButtonPress`, `Event`, `EndCD`, `OnClientEvent`, `KeybindM2`

### [27] 7icbvx.Abilities.Gale's Edge
`LocalScript` · bytecode v9 · 4574 bytes · 112 constants
- **Remotes:** AbilityButtonPress, Data, EndCD, VisualBindableCD
- **Services:** Debris, Players, ReplicatedStorage, UserInputService, game, workspace
- **Key API:** Connect, FindFirstChild, Fire, GetAttribute, GetService, InvokeServer, LoadAnimation, OnClientEvent, WaitForChild, new
- Constants: `Misc`, `DataAbilities`, `script`, `Name`, `FindFirstChild`, `GetAttributes`, `AbilityUpgrades`, `Get`, `Icon`, `Icon%*`, `format`, `Vector`, `WaitForChild`, `Image`, `updateIcon`, `OnChange`, `IsShiftlockActive`, `GetAttribute`, `TouchEnabled`, `Character`, `HumanoidRootPart`, `X`, `Y`, `ViewportPointToRay`, `Origin`, `Direction`, `workspace`, `Raycast`, `Position`, `Unit`, `Z`, `math`, `atan2`, `getRotationYaw`, `InvokeServer`, `task`, `spawn`, `Parent`, `Alive`, `Red`, `Visible`, `xpcall`, `warn`, `playAnimationTrack`, `delay`, `getAbilityCooldown`, `type`, `number`, `Remotes`, `VisualBindableCD`, `Fire`, `ability`, `Ability`, `UseBind`, `coroutine`, `status`, `suspended`, `pcall`, `cancel`, `game`, `ReplicatedStorage`, `GetService`, `require`, `UserInputService`, `Players`, `Debris`, `Packages`, `Net`, `Replion`, `Controllers`, `SettingsController`, `Shared`, `AbilityUtils`, `Abilities`, `Gale's Edge`, `LocalPlayer`, `CharacterAdded`, `Wait`, `Humanoid`, `Animator`, `GalesEdge`, `RemoteFunction`, `CurrentCamera`, `GetMouse`, `PlayerGui`, `Hotbar`, `Upgrades`, `attempt`, `LoadAnimation`, `Client`, `Data`, `AwaitReplion`, `RaycastParams`, `new`, `LockedParts`, `CollisionGroup`, `Enum`, `RaycastFilterType`, `Exclude`, `FilterType`, `Runtime`, `Dead`, `Balls`, `TrainingBalls`, `FilterDescendantsInstances`, `InputBegan`, `Connect`, `AbilityButtonPress`, `Event`, `EndCD`, `OnClientEvent`

### [28] 7icbvx.Abilities.Golden Ball
`LocalScript` · bytecode v9 · 806 bytes · 26 constants
- **Services:** Debris, Players, ReplicatedStorage, UserInputService, game
- **Key API:** GetService, WaitForChild
- Constants: `game`, `ReplicatedStorage`, `GetService`, `require`, `UserInputService`, `WaitForChild`, `Players`, `Debris`, `Packages`, `Net`, `Replion`, `ServerInfo`, `LocalPlayer`, `Character`, `CharacterAdded`, `Wait`, `PlayerGui`, `Hotbar`, `Ability`, `Vector`, `Golden Ball`, `Shared`, `Abilities`, `iconId`, `Image`

### [29] 7icbvx.Abilities.Guardian Angel
`LocalScript` · bytecode v9 · 1975 bytes · 50 constants
- **Remotes:** VisualBindableCD
- **Services:** Debris, Players, ReplicatedStorage, UserInputService, game, workspace
- **Key API:** Connect, Fire, GetAttribute, GetService, WaitForChild
- Constants: `GuardianAngelParriesLeft`, `GetAttribute`, `Upgrades`, `Guardian Angel`, `WaitForChild`, `Value`, `math`, `min`, `GuardianAngelNextUse`, `workspace`, `ShowdownActive`, `isTrainingServer`, `Remotes`, `VisualBindableCD`, `Fire`, `GetServerTimeNow`, `Hotbar`, `Ability`, `ready`, `counts`, `tostring`, `Text`, `update`, `game`, `ReplicatedStorage`, `GetService`, `require`, `UserInputService`, `Players`, `Debris`, `Packages`, `Net`, `Replion`, `ServerInfo`, `Shared`, `Abilities`, `LocalPlayer`, `Character`, `CharacterAdded`, `Wait`, `PlayerGui`, `Vector`, `iconId`, `Image`, `task`, `spawn`, `GetPropertyChangedSignal`, `Connect`, `GetAttributeChangedSignal`

### [30] 7icbvx.Abilities.Hell Hook
`LocalScript` · bytecode v9 · 3436 bytes · 83 constants
- **Remotes:** AbilityButtonPress, EndCD, KeybindM2, PlrHellHooked, VisualBindableCD
- **Services:** Debris, Players, ReplicatedStorage, UserInputService, game, workspace
- **Key API:** Connect, Fire, FireServer, GetAttribute, GetChildren, GetService, LoadAnimation, OnClientEvent, WaitForChild, new
- Constants: `workspace`, `GameActive`, `GetAttribute`, `Character`, `Parent`, `Alive`, `PlayerGui`, `Hotbar`, `Ability`, `Red`, `Visible`, `Dead`, `getAbilityCooldown`, `script`, `Name`, `Upgrades`, `Value`, `next`, `GetChildren`, `AreCharactersEnemies`, `Invisible`, `IsEncryptedClone`, `IsBoss`, `HumanoidRootPart`, `Position`, `WorldToScreenPoint`, `Vector2`, `new`, `X`, `Y`, `Magnitude`, `Remotes`, `VisualBindableCD`, `Fire`, `playAnimationTrack`, `PlrHellHooked`, `FireServer`, `task`, `delay`, `ability`, `UseBind`, `Thread`, `SafeCancel`, `Enum`, `UserInputType`, `MouseButton2`, `game`, `ReplicatedStorage`, `GetService`, `Players`, `LocalPlayer`, `CharacterAdded`, `Wait`, `require`, `UserInputService`, `WaitForChild`, `Humanoid`, `Debris`, `Controllers`, `SettingsController`, `Shared`, `ThreadSafeTargetingHelper`, `Common`, `Utils`, `AbilityUtils`, `Abilities`, `CurrentCamera`, `GetMouse`, `Vector`, `iconId`, `Image`, `Animator`, `FindFirstChildOfClass`, `Grab`, `LoadAnimation`, `InputBegan`, `Connect`, `AbilityButtonPress`, `Event`, `EndCD`, `OnClientEvent`, `KeybindM2`

### [31] 7icbvx.Abilities.Infinity
`LocalScript` · bytecode v9 · 2328 bytes · 58 constants
- **Remotes:** AbilityButtonPress, EndCD, Infinity, KeybindM2, VisualBindableCD
- **Services:** Debris, Players, ReplicatedStorage, UserInputService, Workspace, game, workspace
- **Key API:** Connect, Fire, FireServer, GetService, OnClientEvent, WaitForChild
- Constants: `Character`, `Parent`, `workspace`, `Alive`, `PlayerGui`, `Hotbar`, `Ability`, `Red`, `Visible`, `getAbilityCooldown`, `script`, `Name`, `Remotes`, `Infinity`, `FireServer`, `VisualBindableCD`, `Fire`, `task`, `delay`, `ability`, `UseBind`, `Thread`, `SafeCancel`, `Enum`, `UserInputType`, `MouseButton2`, `game`, `ReplicatedStorage`, `GetService`, `Players`, `LocalPlayer`, `CharacterAdded`, `Wait`, `require`, `UserInputService`, `WaitForChild`, `Humanoid`, `Debris`, `Workspace`, `CurrentCamera`, `FieldOfView`, `Controllers`, `SettingsController`, `Common`, `Utils`, `Shared`, `Abilities`, `Vector`, `iconId`, `Image`, `InputBegan`, `Connect`, `AbilityButtonPress`, `Event`, `EndCD`, `OnClientEvent`, `KeybindM2`

### [32] 7icbvx.Abilities.Invisibility
`LocalScript` · bytecode v9 · 2668 bytes · 65 constants
- **Remotes:** AbilityButtonPress, EndCD, KeybindM2, PlrInvisibilityd, VisualBindableCD
- **Services:** Debris, Players, ReplicatedStorage, UserInputService, game, workspace
- **Key API:** Connect, Fire, FireServer, GetAttribute, GetService, OnClientEvent, Play, WaitForChild
- Constants: `Character`, `Parent`, `workspace`, `Alive`, `PlayerGui`, `Hotbar`, `Ability`, `Red`, `Visible`, `ShowdownActive`, `Value`, `GetPlayerTeam`, `GetCharactersOnTeam`, `Invisible`, `GetAttribute`, `getAbilityCooldown`, `script`, `Name`, `Remotes`, `PlrInvisibilityd`, `FireServer`, `VisualBindableCD`, `Fire`, `task`, `delay`, `Misc`, `error`, `Play`, `ability`, `UseBind`, `Thread`, `SafeCancel`, `Enum`, `UserInputType`, `MouseButton2`, `game`, `ReplicatedStorage`, `GetService`, `Players`, `LocalPlayer`, `CharacterAdded`, `Wait`, `require`, `UserInputService`, `WaitForChild`, `Humanoid`, `Debris`, `Controllers`, `SettingsController`, `Shared`, `ThreadSafeTargetingHelper`, `Common`, `Utils`, `Abilities`, `Vector`, `iconId`, `Image`, `InputBegan`, `Connect`, `AbilityButtonPress`, `Event`, `EndCD`, `OnClientEvent`, `KeybindM2`

### [33] 7icbvx.Abilities.Luck
`LocalScript` · bytecode v9 · 826 bytes · 27 constants
- **Services:** Debris, Players, ReplicatedStorage, UserInputService, Workspace, game
- **Key API:** GetService, WaitForChild
- Constants: `game`, `Players`, `LocalPlayer`, `Character`, `CharacterAdded`, `Wait`, `require`, `ReplicatedStorage`, `GetService`, `UserInputService`, `WaitForChild`, `Humanoid`, `Debris`, `Workspace`, `CurrentCamera`, `FieldOfView`, `PlayerGui`, `Hotbar`, `Ability`, `Vector`, `Shared`, `Abilities`, `script`, `Name`, `iconId`, `Image`

### [34] 7icbvx.Abilities.Martyrdom
`LocalScript` · bytecode v9 · 826 bytes · 27 constants
- **Services:** Debris, Players, ReplicatedStorage, UserInputService, Workspace, game
- **Key API:** GetService, WaitForChild
- Constants: `game`, `Players`, `LocalPlayer`, `Character`, `CharacterAdded`, `Wait`, `require`, `ReplicatedStorage`, `GetService`, `UserInputService`, `WaitForChild`, `Humanoid`, `Debris`, `Workspace`, `CurrentCamera`, `FieldOfView`, `PlayerGui`, `Hotbar`, `Ability`, `Vector`, `Shared`, `Abilities`, `script`, `Name`, `iconId`, `Image`

### [35] 7icbvx.Abilities.Misfortune
`LocalScript` · bytecode v9 · 461 bytes · 17 constants
- **Services:** Players, ReplicatedStorage, game
- **Key API:** WaitForChild
- Constants: `game`, `Players`, `LocalPlayer`, `PlayerGui`, `WaitForChild`, `Hotbar`, `Ability`, `Vector`, `require`, `ReplicatedStorage`, `Shared`, `Abilities`, `script`, `Name`, `iconId`, `Image`

### [36] 7icbvx.Abilities.Nab
`LocalScript` · bytecode v9 · 2327 bytes · 61 constants
- **Remotes:** Data, VisualBindableCD
- **Services:** Debris, Players, ReplicatedStorage, UserInputService, game, workspace
- **Key API:** Connect, FindFirstChild, Fire, GetAttribute, GetService, WaitForChild
- Constants: `Misc`, `DataAbilities`, `script`, `Name`, `FindFirstChild`, `GetAttributes`, `AbilityUpgrades`, `Get`, `Icon`, `Icon%*`, `format`, `Vector`, `WaitForChild`, `Image`, `updateIcon`, `OnChange`, `NabCharge`, `GetAttribute`, `workspace`, `ShowdownActive`, `Value`, `abilityData`, `minCharge`, `Remotes`, `VisualBindableCD`, `Fire`, `Hotbar`, `Ability`, `ready`, `counts`, `tostring`, `Text`, `update`, `game`, `ReplicatedStorage`, `GetService`, `require`, `UserInputService`, `Players`, `Debris`, `Packages`, `Net`, `Replion`, `ServerInfo`, `Shared`, `Abilities`, `Nab`, `LocalPlayer`, `Character`, `CharacterAdded`, `Wait`, `PlayerGui`, `Client`, `Data`, `AwaitReplion`, `task`, `spawn`, `GetPropertyChangedSignal`, `Connect`, `GetAttributeChangedSignal`

### [37] 7icbvx.Abilities.Necromancer
`LocalScript` · bytecode v9 · 3635 bytes · 76 constants
- **Remotes:** AbilityButtonPress, Data, EndCD, VisualBindableCD
- **Services:** Players, ReplicatedStorage, UserInputService, Workspace, game
- **Key API:** Connect, FindFirstChild, Fire, GetAttribute, GetService, InvokeServer, OnClientEvent, Play, WaitForChild
- Constants: `DataAbilities`, `FindFirstChild`, `GetAttributes`, `AbilityUpgrades`, `Get`, `Icon`, `Vector`, `Image`, `updateIcon`, `Thread`, `SafeCancel`, `cancelUpdateThread`, `task`, `wait`, `GetServerTimeNow`, `NecromancersCooldown`, `GetAttribute`, `NecromancersLeft`, `NecromancersActive`, `tostring`, `Text`, `Remotes`, `VisualBindableCD`, `Fire`, `spawn`, `update`, `error`, `Play`, `InvokeServer`, `ability`, `Ability`, `UseBind`, `game`, `Players`, `GetService`, `ReplicatedStorage`, `require`, `UserInputService`, `WaitForChild`, `Workspace`, `Controllers`, `Packages`, `Misc`, `script`, `Name`, `Net`, `Replion`, `SettingsController`, `Common`, `Utils`, `LocalPlayer`, `Character`, `CharacterAdded`, `Wait`, `NewAbilities/ActivePrimarySlot`, `RemoteFunction`, `PlayerGui`, `Hotbar`, `ready`, `counts`, `Client`, `Data`, `WaitReplion`, `OnChange`, `Destroying`, `Connect`, `InputBegan`, `GetAttributeChangedSignal`, `Alive`, `ChildAdded`, `ChildRemoved`, `AbilityButtonPress`, `Event`, `EndCD`, `OnClientEvent`

### [38] 7icbvx.Abilities.Ninja Dash
`LocalScript` · bytecode v9 · 5541 bytes · 125 constants
- **Remotes:** AbilityButtonPress, DashFired, EndCD, VisualBindableCD
- **Services:** Debris, Players, ReplicatedStorage, RunService, TweenService, UserInputService, Workspace, game, workspace
- **Key API:** Connect, Create, Disconnect, FindFirstChild, Fire, FireServer, GetAttribute, GetDescendants, GetService, IsA, LoadAnimation, OnClientEvent, Play, SetAttribute, WaitForChild, new
- Constants: `cooldownThread`, `BasePart`, `IsA`, `Massless`, `DashSetMassless`, `SetAttribute`, `ipairs`, `Character`, `GetDescendants`, `DescendantAdded`, `Connect`, `GetAttribute`, `Enabled`, `Disconnect`, `PrimaryPart`, `AssemblyLinearVelocity`, `AssemblyAngularVelocity`, `Parent`, `workspace`, `Alive`, `PlayerGui`, `Hotbar`, `Ability`, `Red`, `Visible`, `MoveDirection`, `Upgrades`, `script`, `Name`, `Value`, `getAbilityCooldown`, `task`, `delay`, `FieldOfView`, `game`, `Workspace`, `CurrentCamera`, `TweenInfo`, `new`, `Enum`, `EasingStyle`, `Linear`, `EasingDirection`, `Out`, `TweenService`, `GetService`, `Create`, `Play`, `X`, `math`, `deg`, `Y`, `Z`, `GetScale`, `max`, `Remotes`, `DashFired`, `Fire`, `VisualBindableCD`, `FireServer`, `playAnimationTrack`, `HumanoidRootPart`, `CFrame`, `rightVector`, `lookVector`, `Dot`, `random`, `clamp`, `Instance`, `BodyVelocity`, `Dash`, `MaxForce`, `Velocity`, `AddItem`, `spawn`, `Colliders`, `FindFirstChild`, `Pin`, `RigidConstraint`, `FindFirstChildWhichIsA`, `wait`, `ability`, `UseBind`, `RunService`, `RenderStepped`, `Wait`, `UserSettings`, `UserGameSettings`, `RotationType`, `MovementRelative`, `Thread`, `SafeCancel`, `ReplicatedStorage`, `Players`, `LocalPlayer`, `CharacterAdded`, `require`, `UserInputService`, `WaitForChild`, `Humanoid`, `Debris`, `Controllers`, `SettingsController`, `Shared`, `GetAbilityCooldownMultiplier`, `Common`, `Utils`, `AbilityUtils`, `Abilities`, `Packages`, `Net`, `NinjaDash`, `RemoteEvent`, `Animator`, `FindFirstChildOfClass`, `LoadAnimation`, `Vector`, `iconId`, `Image`, `InputBegan`, `AbilityButtonPress`, `Event`, `EndCD`, `OnClientEvent`

### [39] 7icbvx.Abilities.Parry Counter
`LocalScript` · bytecode v9 · 808 bytes · 26 constants
- **Services:** Debris, Players, ReplicatedStorage, UserInputService, game
- **Key API:** GetService, WaitForChild
- Constants: `game`, `ReplicatedStorage`, `GetService`, `require`, `UserInputService`, `WaitForChild`, `Players`, `Debris`, `Packages`, `Net`, `Replion`, `ServerInfo`, `LocalPlayer`, `Character`, `CharacterAdded`, `Wait`, `PlayerGui`, `Hotbar`, `Ability`, `Vector`, `Parry Counter`, `Shared`, `Abilities`, `iconId`, `Image`

### [40] 7icbvx.Abilities.Phantom
`LocalScript` · bytecode v9 · 3605 bytes · 88 constants
- **Remotes:** AbilityButtonPress, Data, EndCD, KeybindM2, Phantom, VisualBindableCD
- **Services:** Debris, Players, ReplicatedStorage, TweenService, UserInputService, game, workspace
- **Key API:** Connect, Create, Fire, FireServer, GetAttribute, GetChildren, GetService, OnClientEvent, Play, WaitForChild, new
- Constants: `Character`, `AreCharactersEnemies`, `onSameTeam`, `Parent`, `workspace`, `Alive`, `PlayerGui`, `Hotbar`, `Ability`, `Red`, `Visible`, `next`, `GetChildren`, `Invisible`, `GetAttribute`, `IsEncryptedClone`, `SingularityInOrbit`, `HumanoidRootPart`, `Position`, `WorldToScreenPoint`, `Vector2`, `new`, `X`, `Y`, `Magnitude`, `TweenInfo`, `Enum`, `EasingStyle`, `Linear`, `EasingDirection`, `Out`, `FieldOfView`, `Create`, `Play`, `require`, `Packages`, `Replion`, `Client`, `Data`, `WaitReplion`, `getAbilityCooldown`, `script`, `Name`, `Remotes`, `Phantom`, `FireServer`, `VisualBindableCD`, `Fire`, `task`, `delay`, `ability`, `UseBind`, `Thread`, `SafeCancel`, `UserInputType`, `MouseButton2`, `game`, `Debris`, `GetService`, `TweenService`, `ReplicatedStorage`, `UserInputService`, `WaitForChild`, `Players`, `Controllers`, `SettingsController`, `Shared`, `ThreadSafeTargetingHelper`, `Common`, `Utils`, `Abilities`, `LocalPlayer`, `CharacterAdded`, `Wait`, `Humanoid`, `CurrentCamera`, `GetMouse`, `Vector`, `iconId`, `Image`, `InputBegan`, `Connect`, `AbilityButtonPress`, `Event`, `EndCD`, `OnClientEvent`, `KeybindM2`

### [41] 7icbvx.Abilities.Phase Bypass
`LocalScript` · bytecode v9 · 4008 bytes · 95 constants
- **Remotes:** AbilityButtonPress, Data, EndCD, KeybindM2, ResetFOV, VisualBindableCD
- **Services:** Lighting, Players, ReplicatedStorage, UserInputService, game, workspace
- **Key API:** Connect, Destroy, FindFirstChild, Fire, GetService, InvokeServer, OnClientEvent, WaitForChild, new
- Constants: `Misc`, `DataAbilities`, `FindFirstChild`, `GetAttributes`, `AbilityUpgrades`, `Get`, `Icon`, `Vector`, `Image`, `updateIcon`, `Remotes`, `ResetFOV`, `Fire`, `Enabled`, `Parent`, `workspace`, `Alive`, `CFrame`, `cc2`, `CurrentCamera`, `FieldOfView`, `fastTween`, `TweenInfo`, `new`, `Enum`, `EasingStyle`, `Linear`, `Add`, `applyEffects`, `Red`, `Visible`, `getAbilityCooldown`, `InvokeServer`, `cooldown`, `VisualBindableCD`, `Clean`, `task`, `delay`, `ability`, `Thread`, `SafeCancel`, `Ability`, `UseBind`, `UserInputType`, `MouseButton2`, `script`, `game`, `IsDescendantOf`, `Destroy`, `Lighting`, `GetService`, `Players`, `ReplicatedStorage`, `require`, `UserInputService`, `WaitForChild`, `Controllers`, `Packages`, `Shared`, `Name`, `Abilities`, `FastUtils`, `Net`, `Replion`, `SettingsController`, `Trove`, `Common`, `Utils`, `LocalPlayer`, `Character`, `CharacterAdded`, `Wait`, `HumanoidRootPart`, `Humanoid`, `NewAbilities/ActivePrimarySlot`, `RemoteFunction`, `PhaseBypass/ApplyEffects`, `RemoteEvent`, `PlayerGui`, `Hotbar`, `Client`, `Data`, `WaitReplion`, `spawn`, `OnChange`, `Destroying`, `Connect`, `InputBegan`, `AbilityButtonPress`, `Event`, `EndCD`, `OnClientEvent`, `KeybindM2`, `AncestryChanged`

### [42] 7icbvx.Abilities.Phase Bypass.FixDisable
`LocalScript` · bytecode v9 · 771 bytes · 24 constants
- **Services:** Lighting, TweenService, game, workspace
- **Key API:** Connect, Create, GetService, Play, new
- Constants: `script`, `Parent`, `Enabled`, `task`, `wait`, `game`, `Lighting`, `cc2`, `TweenService`, `GetService`, `workspace`, `CurrentCamera`, `TweenInfo`, `new`, `Enum`, `EasingStyle`, `Linear`, `EasingDirection`, `Out`, `FieldOfView`, `Create`, `Play`, `GetPropertyChangedSignal`, `Connect`

### [43] 7icbvx.Abilities.Pinpoint
`LocalScript` · bytecode v9 · 1422 bytes · 41 constants
- **Remotes:** Data
- **Services:** Debris, Players, ReplicatedStorage, UserInputService, game
- **Key API:** FindFirstChild, GetService, WaitForChild
- Constants: `Misc`, `DataAbilities`, `script`, `Name`, `FindFirstChild`, `GetAttributes`, `AbilityUpgrades`, `Get`, `Icon`, `Icon%*`, `format`, `Vector`, `WaitForChild`, `Image`, `updateIcon`, `OnChange`, `game`, `ReplicatedStorage`, `GetService`, `require`, `UserInputService`, `Players`, `Debris`, `Packages`, `Net`, `Replion`, `ServerInfo`, `Shared`, `Abilities`, `Nab`, `LocalPlayer`, `Character`, `CharacterAdded`, `Wait`, `PlayerGui`, `Hotbar`, `Ability`, `Client`, `Data`, `AwaitReplion`

### [44] 7icbvx.Abilities.Platform
`LocalScript` · bytecode v9 · 4602 bytes · 95 constants
- **Remotes:** AbilityButtonPress, EndCD, KeybindM2, Platform, VisualBindableCD
- **Services:** Debris, Players, ReplicatedStorage, RunService, UserInputService, game, workspace
- **Key API:** Connect, Disconnect, FindFirstChild, Fire, FireServer, GetService, LoadAnimation, OnClientEvent, Play, WaitForChild, new
- Constants: `task`, `wait`, `Remotes`, `Platform`, `FireServer`, `Character`, `Parent`, `workspace`, `Alive`, `PlayerGui`, `Hotbar`, `Ability`, `Red`, `Visible`, `FloorMaterial`, `Enum`, `Material`, `Air`, `getAbilityCooldown`, `script`, `Name`, `Initial Platform Debuff`, `Utils`, `MinDebuff`, `Priority`, `DEBUFF`, `SetModifierFor`, `VisualBindableCD`, `Fire`, `Play`, `spawn`, `delay`, `ability`, `UseBind`, `Thread`, `SafeCancel`, `UserInputType`, `MouseButton2`, `PrimaryPart`, `Disconnect`, `CFrame`, `Position`, `Raycast`, `Instance`, `GetPartBoundsInBox`, `HasTag`, `OwnerCharacter`, `FindFirstChild`, `Value`, `Inverse`, `PreSimulation`, `Connect`, `startPlatformUpdate`, `game`, `ReplicatedStorage`, `GetService`, `Players`, `LocalPlayer`, `CharacterAdded`, `Wait`, `require`, `UserInputService`, `WaitForChild`, `Humanoid`, `Debris`, `RunService`, `Controllers`, `SettingsController`, `Shared`, `Abilities`, `SpeedModifiers`, `Common`, `Animator`, `FindFirstChildOfClass`, `LoadAnimation`, `Vector`, `iconId`, `Image`, `InputBegan`, `AbilityButtonPress`, `Event`, `EndCD`, `OnClientEvent`, `KeybindM2`, `RaycastParams`, `new`, `RaycastFilterType`, `Include`, `FilterType`, `Runtime`, `FilterDescendantsInstances`, `OverlapParams`, `AncestryChanged`, `IsDescendantOf`

### [45] 7icbvx.Abilities.Pull
`LocalScript` · bytecode v9 · 3447 bytes · 84 constants
- **Remotes:** AbilityButtonPress, EndCD, KeybindM2, PlrPulled, VisualBindableCD
- **Services:** Debris, Players, ReplicatedStorage, TweenService, UserInputService, Workspace, game, workspace
- **Key API:** Connect, Create, Fire, FireServer, GetAttribute, GetChildren, GetService, LoadAnimation, OnClientEvent, Play, WaitForChild, new
- Constants: `workspace`, `Balls`, `GetChildren`, `Character`, `Parent`, `Alive`, `PlayerGui`, `Hotbar`, `Ability`, `Red`, `Visible`, `FieldOfView`, `game`, `Workspace`, `CurrentCamera`, `TweenInfo`, `new`, `Enum`, `EasingStyle`, `Quart`, `EasingDirection`, `In`, `TweenService`, `GetService`, `Create`, `Play`, `realBall`, `GetAttribute`, `Position`, `WorldToScreenPoint`, `Vector2`, `X`, `Y`, `Magnitude`, `getAbilityCooldown`, `script`, `Name`, `Remotes`, `PlrPulled`, `FireServer`, `VisualBindableCD`, `Fire`, `playAnimationTrack`, `task`, `delay`, `ability`, `UseBind`, `Thread`, `SafeCancel`, `UserInputType`, `MouseButton2`, `ReplicatedStorage`, `Players`, `LocalPlayer`, `CharacterAdded`, `Wait`, `require`, `UserInputService`, `WaitForChild`, `Humanoid`, `Debris`, `Controllers`, `SettingsController`, `Common`, `Utils`, `Shared`, `AbilityUtils`, `Abilities`, `Pull`, `Animator`, `FindFirstChildOfClass`, `LoadAnimation`, `GetMouse`, `Vector`, `iconId`, `Image`, `InputBegan`, `Connect`, `AbilityButtonPress`, `Event`, `EndCD`, `OnClientEvent`, `KeybindM2`

### [46] 7icbvx.Abilities.Pulse
`LocalScript` · bytecode v9 · 2247 bytes · 55 constants
- **Remotes:** AbilityButtonPress, EndCD, KeybindM2, PlrPulsed, VisualBindableCD
- **Services:** Debris, Players, ReplicatedStorage, UserInputService, game, workspace
- **Key API:** Connect, Fire, FireServer, GetService, OnClientEvent, WaitForChild
- Constants: `Character`, `Parent`, `workspace`, `Alive`, `PlayerGui`, `Hotbar`, `Ability`, `Red`, `Visible`, `getAbilityCooldown`, `script`, `Name`, `Remotes`, `PlrPulsed`, `FireServer`, `VisualBindableCD`, `Fire`, `task`, `delay`, `ability`, `UseBind`, `Thread`, `SafeCancel`, `Enum`, `UserInputType`, `MouseButton2`, `game`, `ReplicatedStorage`, `GetService`, `Players`, `LocalPlayer`, `CharacterAdded`, `Wait`, `require`, `UserInputService`, `WaitForChild`, `Humanoid`, `Debris`, `Controllers`, `SettingsController`, `Common`, `Utils`, `Shared`, `Abilities`, `Vector`, `iconId`, `Image`, `InputBegan`, `Connect`, `AbilityButtonPress`, `Event`, `EndCD`, `OnClientEvent`, `KeybindM2`

### [47] 7icbvx.Abilities.Qi-Charge
`LocalScript` · bytecode v9 · 5972 bytes · 99 constants
- **Remotes:** AbilityButtonPress, DashFired, Data, EndCD, KeybindM2, PlrAdrenalined
- **Services:** Debris, Players, ReplicatedStorage, UserInputService, game, workspace
- **Key API:** Connect, Destroy, FireServer, GetAttribute, GetService, OnClientEvent, WaitForChild, new
- Constants: `Bg`, `UDim2`, `fromScale`, `Position`, `Enum`, `EasingDirection`, `InOut`, `EasingStyle`, `Sine`, `TweenPosition`, `Adrenaline`, `GetAttribute`, `AdrenalineChargeProgress`, `TextLabel`, `%*%%`, `format`, `Text`, `Fill`, `Meter`, `Vector2`, `new`, `Offset`, `FillGlow`, `ImageTransparency`, `ImageColor3`, `math`, `random`, `task`, `wait`, `clamp`, `Character`, `Parent`, `workspace`, `Alive`, `PlayerGui`, `Hotbar`, `Ability`, `Red`, `Visible`, `Remotes`, `PlrAdrenalined`, `FireServer`, `ChargingAdrenaline`, `coroutine`, `close`, `Qi-Charge`, `Upgrades`, `Value`, `spawn`, `ability`, `UseBind`, `UserInputType`, `MouseButton2`, `Name`, `Destroy`, `Enabled`, `game`, `ReplicatedStorage`, `GetService`, `Players`, `LocalPlayer`, `CharacterAdded`, `Wait`, `require`, `UserInputService`, `WaitForChild`, `Humanoid`, `Debris`, `Controllers`, `SettingsController`, `Packages`, `Replion`, `Shared`, `Inventory`, `Client`, `AbilityUtils`, `Trove`, `Vector`, `QiAbilityMeter`, `Abilities`, `script`, `iconId`, `Image`, `Color3`, `InputBegan`, `Connect`, `InputEnded`, `AbilityButtonPress`, `Event`, `DashFired`, `EndCD`, `OnClientEvent`, `KeybindM2`, `GetAttributeChangedSignal`, `Data`, `WaitReplion`, `onEquip`, `AncestryChanged`

### [48] 7icbvx.Abilities.Quad Jump
`LocalScript` · bytecode v9 · 826 bytes · 27 constants
- **Services:** Debris, Players, ReplicatedStorage, UserInputService, Workspace, game
- **Key API:** GetService, WaitForChild
- Constants: `game`, `Players`, `LocalPlayer`, `Character`, `CharacterAdded`, `Wait`, `require`, `ReplicatedStorage`, `GetService`, `UserInputService`, `WaitForChild`, `Humanoid`, `Debris`, `Workspace`, `CurrentCamera`, `FieldOfView`, `PlayerGui`, `Hotbar`, `Ability`, `Vector`, `Shared`, `Abilities`, `script`, `Name`, `iconId`, `Image`

### [49] 7icbvx.Abilities.Quantum Arena
`LocalScript` · bytecode v9 · 6352 bytes · 110 constants
- **Remotes:** AbilityButtonPress, Data, EndCD, KeybindM2, QuantumArenaDash, VisualBindableCD
- **Services:** Players, ReplicatedStorage, UserInputService, game, workspace
- **Key API:** Connect, FindFirstChild, Fire, FireServer, GetAttribute, GetService, InvokeServer, OnClientEvent, Play, WaitForChild, new
- Constants: `Misc`, `DataAbilities`, `FindFirstChild`, `GetAttributes`, `AbilityUpgrades`, `Get`, `Icon`, `Vector`, `Image`, `updateIcon`, `RootPart`, `MoveDirection`, `WalkToPoint`, `Position`, `getMoveDirection`, `QuantumArenaCharge`, `GetAttribute`, `QuantumArenaUses`, `math`, `clamp`, `getKillsProgress`, `workspace`, `QuantumArenaActive`, `UserId`, `Alive`, `IsDescendantOf`, `Dead`, `Remotes`, `VisualBindableCD`, `Fire`, `QuantumArenaFreeCharge`, `GetServerTimeNow`, `min`, `updateKillProgress`, `Parent`, `Red`, `Visible`, `error`, `Play`, `RaycastParams`, `new`, `Enum`, `RaycastFilterType`, `Exclude`, `FilterType`, `Runtime`, `Balls`, `TrainingBalls`, `FilterDescendantsInstances`, `GetPivot`, `Raycast`, `Rotation`, `PivotTo`, `FireServer`, `task`, `delay`, `InvokeServer`, `ability`, `Thread`, `SafeCancel`, `Ability`, `UseBind`, `UserInputType`, `MouseButton2`, `game`, `Players`, `GetService`, `ReplicatedStorage`, `require`, `UserInputService`, `WaitForChild`, `Assets`, `Controllers`, `Packages`, `Shared`, `script`, `Name`, `Abilities`, `Net`, `Replion`, `SettingsController`, `Common`, `Utils`, `LocalPlayer`, `Character`, `CharacterAdded`, `Wait`, `Humanoid`, `NewAbilities/ActivePrimarySlot`, `RemoteFunction`, `QuantumArenaDash`, `RemoteEvent`, `PlayerGui`, `Hotbar`, `Client`, `Data`, `WaitReplion`, `spawn`, `OnChange`, `GetAttributeChangedSignal`, `Connect`, `Destroying`, `InputBegan`, `AbilityButtonPress`, `Event`, `EndCD`, `OnClientEvent`, `KeybindM2`, `AncestryChanged`

### [50] 7icbvx.Abilities.Quasar
`LocalScript` · bytecode v9 · 3361 bytes · 80 constants
- **Remotes:** AbilityButtonPress, EndCD, KeybindM2, PlrQuasared, VisualBindableCD
- **Services:** Debris, Players, ReplicatedStorage, UserInputService, game, workspace
- **Key API:** Connect, Fire, FireServer, GetAttribute, GetChildren, GetService, LoadAnimation, OnClientEvent, WaitForChild, new
- Constants: `workspace`, `GameActive`, `GetAttribute`, `Character`, `Parent`, `Alive`, `PlayerGui`, `Hotbar`, `Ability`, `Red`, `Visible`, `Dead`, `getAbilityCooldown`, `script`, `Name`, `GetChildren`, `AreCharactersEnemies`, `IsEncryptedClone`, `IsDoppelganger`, `Invisible`, `HumanoidRootPart`, `Position`, `WorldToScreenPoint`, `Vector2`, `new`, `X`, `Y`, `Magnitude`, `Remotes`, `VisualBindableCD`, `Fire`, `playAnimationTrack`, `PlrQuasared`, `FireServer`, `task`, `delay`, `ability`, `UseBind`, `Thread`, `SafeCancel`, `Enum`, `UserInputType`, `MouseButton2`, `game`, `ReplicatedStorage`, `GetService`, `Players`, `LocalPlayer`, `CharacterAdded`, `Wait`, `require`, `UserInputService`, `WaitForChild`, `Humanoid`, `Debris`, `Controllers`, `SettingsController`, `Shared`, `ThreadSafeTargetingHelper`, `Common`, `Utils`, `AbilityUtils`, `Abilities`, `CurrentCamera`, `GetMouse`, `Vector`, `iconId`, `Image`, `Animator`, `FindFirstChildOfClass`, `Grab`, `LoadAnimation`, `InputBegan`, `Connect`, `AbilityButtonPress`, `Event`, `EndCD`, `OnClientEvent`, `KeybindM2`

### [51] 7icbvx.Abilities.Raging Deflection
`LocalScript` · bytecode v9 · 3723 bytes · 84 constants
- **Remotes:** AbilityButtonPress, EndCD, KeybindM2, PlrRagingDeflectiond, RagingDeflectionSuccess2, VisualBindableCD
- **Services:** Debris, Players, ReplicatedStorage, UserInputService, game, workspace
- **Key API:** Connect, Fire, FireServer, GetChildren, GetService, LoadAnimation, OnClientEvent, Stop, WaitForChild
- Constants: `Character`, `Parent`, `workspace`, `Alive`, `PlayerGui`, `Hotbar`, `Ability`, `Red`, `Visible`, `Upgrades`, `script`, `Name`, `Value`, `getAbilityCooldown`, `next`, `GetChildren`, `HumanoidRootPart`, `Position`, `WorldToScreenPoint`, `Remotes`, `PlrRagingDeflectiond`, `CurrentCamera`, `CFrame`, `X`, `Y`, `FireServer`, `VisualBindableCD`, `Fire`, `task`, `delay`, `Initial Raging Deflect Debuff`, `Utils`, `MinDebuff`, `Priority`, `DEBUFF`, `SetModifierFor`, `playAnimationTrack`, `wait`, `Stop`, `ability`, `UseBind`, `RemoveModifierFor`, `Thread`, `SafeCancel`, `Enum`, `UserInputType`, `MouseButton2`, `game`, `ReplicatedStorage`, `GetService`, `Players`, `LocalPlayer`, `CharacterAdded`, `Wait`, `require`, `UserInputService`, `WaitForChild`, `Humanoid`, `Debris`, `Controllers`, `SettingsController`, `Common`, `Shared`, `AbilityUtils`, `Abilities`, `SpeedModifiers`, `attempt`, `Animator`, `FindFirstChildOfClass`, `LoadAnimation`, `success`, `GetMouse`, `Vector`, `iconId`, `Image`, `InputBegan`, `Connect`, `AbilityButtonPress`, `Event`, `RagingDeflectionSuccess2`, `OnClientEvent`, `EndCD`, `KeybindM2`

### [52] 7icbvx.Abilities.Rapture
`LocalScript` · bytecode v9 · 3599 bytes · 82 constants
- **Remotes:** AbilityButtonPress, EndCD, KeybindM2, PlrRaptured, RaptureSuccess, VisualBindableCD
- **Services:** Debris, Players, ReplicatedStorage, UserInputService, game, workspace
- **Key API:** Connect, Fire, FireServer, GetChildren, GetService, LoadAnimation, OnClientEvent, Stop, WaitForChild
- Constants: `Character`, `Parent`, `workspace`, `Alive`, `PlayerGui`, `Hotbar`, `Ability`, `Red`, `Visible`, `getAbilityCooldown`, `script`, `Name`, `next`, `GetChildren`, `HumanoidRootPart`, `Position`, `WorldToScreenPoint`, `task`, `delay`, `Remotes`, `PlrRaptured`, `CurrentCamera`, `CFrame`, `X`, `Y`, `FireServer`, `VisualBindableCD`, `Fire`, `Initial Rapture Debuff`, `Utils`, `MinDebuff`, `Priority`, `DEBUFF`, `SetModifierFor`, `playAnimationTrack`, `wait`, `Stop`, `ability`, `UseBind`, `RemoveModifierFor`, `Thread`, `SafeCancel`, `Enum`, `UserInputType`, `MouseButton2`, `game`, `ReplicatedStorage`, `GetService`, `Players`, `LocalPlayer`, `CharacterAdded`, `Wait`, `require`, `UserInputService`, `WaitForChild`, `Humanoid`, `Debris`, `Controllers`, `SettingsController`, `Common`, `Shared`, `Abilities`, `SpeedModifiers`, `AbilityUtils`, `attempt`, `Animator`, `FindFirstChildOfClass`, `LoadAnimation`, `success`, `GetMouse`, `Vector`, `iconId`, `Image`, `InputBegan`, `Connect`, `AbilityButtonPress`, `Event`, `RaptureSuccess`, `OnClientEvent`, `EndCD`, `KeybindM2`

### [53] 7icbvx.Abilities.Reaper
`LocalScript` · bytecode v9 · 826 bytes · 27 constants
- **Services:** Debris, Players, ReplicatedStorage, UserInputService, Workspace, game
- **Key API:** GetService, WaitForChild
- Constants: `game`, `Players`, `LocalPlayer`, `Character`, `CharacterAdded`, `Wait`, `require`, `ReplicatedStorage`, `GetService`, `UserInputService`, `WaitForChild`, `Humanoid`, `Debris`, `Workspace`, `CurrentCamera`, `FieldOfView`, `PlayerGui`, `Hotbar`, `Ability`, `Vector`, `Shared`, `Abilities`, `script`, `Name`, `iconId`, `Image`

### [54] 7icbvx.Abilities.Revenge
`LocalScript` · bytecode v9 · 3284 bytes · 82 constants
- **Remotes:** AbilityButtonPress, EndCD, KeybindM2, PlrRevenged, VisualBindableCD
- **Services:** Debris, Players, ReplicatedStorage, UserInputService, game, workspace
- **Key API:** Connect, Fire, FireServer, GetAttribute, GetChildren, GetService, LoadAnimation, OnClientEvent, Play, Stop, WaitForChild
- Constants: `Character`, `Parent`, `workspace`, `Alive`, `PlayerGui`, `Hotbar`, `Ability`, `Red`, `Visible`, `getAbilityCooldown`, `script`, `Name`, `Upgrades`, `Value`, `next`, `GetChildren`, `HumanoidRootPart`, `Position`, `WorldToScreenPoint`, `Remotes`, `PlrRevenged`, `CurrentCamera`, `CFrame`, `X`, `Y`, `FireServer`, `task`, `delay`, `VisualBindableCD`, `Fire`, `Initial Revenge Debuff`, `Utils`, `MinDebuff`, `Priority`, `DEBUFF`, `SetModifierFor`, `IgnoreAbilityAnimations`, `GetAttribute`, `Play`, `wait`, `Stop`, `ability`, `UseBind`, `Thread`, `SafeCancel`, `Enum`, `UserInputType`, `MouseButton2`, `game`, `ReplicatedStorage`, `GetService`, `Players`, `LocalPlayer`, `CharacterAdded`, `Wait`, `require`, `UserInputService`, `WaitForChild`, `Humanoid`, `Debris`, `Controllers`, `SettingsController`, `Shared`, `Abilities`, `SpeedModifiers`, `Common`, `attempt`, `Animator`, `FindFirstChildOfClass`, `LoadAnimation`, `GetMouse`, `Vector`, `iconId`, `Image`, `InputBegan`, `Connect`, `AbilityButtonPress`, `Event`, `EndCD`, `OnClientEvent`, `KeybindM2`

### [55] 7icbvx.Abilities.Scopophobia
`LocalScript` · bytecode v9 · 2256 bytes · 55 constants
- **Remotes:** AbilityButtonPress, EndCD, KeybindM2, PlrUsedScopophobia, VisualBindableCD
- **Services:** Debris, Players, ReplicatedStorage, UserInputService, game, workspace
- **Key API:** Connect, Fire, FireServer, GetService, OnClientEvent, WaitForChild
- Constants: `Character`, `Parent`, `workspace`, `Alive`, `PlayerGui`, `Hotbar`, `Ability`, `Red`, `Visible`, `getAbilityCooldown`, `script`, `Name`, `Remotes`, `PlrUsedScopophobia`, `FireServer`, `VisualBindableCD`, `Fire`, `task`, `delay`, `ability`, `UseBind`, `Thread`, `SafeCancel`, `Enum`, `UserInputType`, `MouseButton2`, `game`, `ReplicatedStorage`, `GetService`, `Players`, `LocalPlayer`, `CharacterAdded`, `Wait`, `require`, `UserInputService`, `WaitForChild`, `Humanoid`, `Debris`, `Controllers`, `SettingsController`, `Common`, `Utils`, `Shared`, `Abilities`, `Vector`, `iconId`, `Image`, `InputBegan`, `Connect`, `AbilityButtonPress`, `Event`, `EndCD`, `OnClientEvent`, `KeybindM2`

### [56] 7icbvx.Abilities.Serpent Shadow Clone
`LocalScript` · bytecode v9 · 3845 bytes · 91 constants
- **Remotes:** AbilityButtonPress, BotAbility, EndCD, KeybindM2, VisualBindableCD
- **Services:** Debris, Players, ReplicatedStorage, UserInputService, game, workspace
- **Key API:** Clone, Connect, FindFirstChild, Fire, FireServer, GetAttribute, GetDescendants, GetService, IsA, OnClientEvent, WaitForChild, new
- Constants: `Character`, `Parent`, `workspace`, `Alive`, `PlayerGui`, `Hotbar`, `Ability`, `Red`, `Visible`, `IsDescendantOf`, `getAbilityCooldown`, `script`, `Name`, `Remotes`, `VisualBindableCD`, `Fire`, `BotAbility`, `FireServer`, `task`, `delay`, `ability`, `ipairs`, `GetDescendants`, `ParticleEmitter`, `IsA`, `Lifetime`, `Max`, `getParticleLifetime`, `Emit`, `GROUND`, `FindFirstChild`, `RaycastParams`, `new`, `Enum`, `RaycastFilterType`, `Include`, `FilterType`, `IgnoreWater`, `RespectCanCollide`, `Map`, `WaitForChild`, `FilterDescendantsInstances`, `Clone`, `CFrame`, `CurrentCamera`, `BasePart`, `Position`, `Raycast`, `EmitCount`, `GetAttribute`, `EmitDelay`, `AddItem`, `playVFXFromContainer`, `UseBind`, `Thread`, `SafeCancel`, `UserInputType`, `MouseButton2`, `Assets`, `Abilities`, `game`, `Debris`, `GetService`, `Players`, `ReplicatedStorage`, `require`, `UserInputService`, `Controllers`, `SettingsController`, `Common`, `Utils`, `Packages`, `Net`, `Shared`, `LocalPlayer`, `CharacterAdded`, `Wait`, `Humanoid`, `PlayBotParticles`, `RemoteEvent`, `Vector`, `iconId`, `Image`, `AbilityButtonPress`, `Event`, `Connect`, `InputBegan`, `EndCD`, `OnClientEvent`, `KeybindM2`

### [57] 7icbvx.Abilities.Shadow Step
`LocalScript` · bytecode v9 · 2883 bytes · 69 constants
- **Remotes:** AbilityButtonPress, EndCD, KeybindM2, ShadowFollow, VisualBindableCD
- **Services:** Debris, Players, ReplicatedStorage, UserInputService, Workspace, game, workspace
- **Key API:** Connect, Fire, FireServer, GetService, OnClientEvent, WaitForChild, new
- Constants: `Character`, `Parent`, `workspace`, `Alive`, `PlayerGui`, `Hotbar`, `Ability`, `Red`, `Visible`, `fastTween`, `CurrentCamera`, `TweenInfo`, `new`, `Enum`, `EasingStyle`, `Linear`, `EasingDirection`, `Out`, `FieldOfView`, `getAbilityCooldown`, `script`, `Name`, `Upgrades`, `Value`, `Remotes`, `ShadowFollow`, `FireServer`, `task`, `delay`, `VisualBindableCD`, `Fire`, `wait`, `ability`, `UseBind`, `Thread`, `SafeCancel`, `UserInputType`, `MouseButton2`, `game`, `ReplicatedStorage`, `GetService`, `Players`, `LocalPlayer`, `CharacterAdded`, `Wait`, `require`, `UserInputService`, `WaitForChild`, `Humanoid`, `Debris`, `Workspace`, `Controllers`, `SettingsController`, `Common`, `Utils`, `Shared`, `Abilities`, `FastUtils`, `Vector`, `iconId`, `Image`, `InputBegan`, `Connect`, `AbilityButtonPress`, `Event`, `EndCD`, `OnClientEvent`, `KeybindM2`

### [58] 7icbvx.Abilities.Singularity
`LocalScript` · bytecode v9 · 3621 bytes · 85 constants
- **Remotes:** AbilityButtonPress, Data, EndCD, VisualBindableCD
- **Services:** Debris, Players, ReplicatedStorage, UserInputService, game, workspace
- **Key API:** Connect, FindFirstChild, Fire, GetAttribute, GetService, InvokeServer, OnClientEvent, Play, WaitForChild
- Constants: `Misc`, `DataAbilities`, `script`, `Name`, `FindFirstChild`, `GetAttributes`, `AbilityUpgrades`, `Get`, `Icon`, `Vector`, `Image`, `updateIcon`, `pcall`, `GetRankInGroup`, `game`, `CreatorId`, `getRank`, `isTestGame`, `FFlag`, `GetInstantFFlag`, `SingulariyyMinGroupRank`, `error`, `Play`, `This ability is currently disabled!`, `SendNotification`, `Parent`, `workspace`, `Alive`, `Red`, `Visible`, `getAbilityCooldown`, `InvokeServer`, `Remotes`, `VisualBindableCD`, `Fire`, `task`, `wait`, `IS_EVENT_SINGULARITY`, `GetAttribute`, `Enabled`, `delay`, `ability`, `Ability`, `UseBind`, `Thread`, `SafeCancel`, `Debris`, `GetService`, `Players`, `ReplicatedStorage`, `require`, `UserInputService`, `WaitForChild`, `Controllers`, `Packages`, `Shared`, `Abilities`, `Net`, `NotificationController`, `Replion`, `ServerInfo`, `SettingsController`, `Common`, `Utils`, `LocalPlayer`, `Character`, `CharacterAdded`, `Wait`, `Humanoid`, `NewAbilities/ActivePrimarySlot`, `RemoteFunction`, `PlayerGui`, `Hotbar`, `Client`, `Data`, `WaitReplion`, `spawn`, `OnChange`, `InputBegan`, `Connect`, `AbilityButtonPress`, `Event`, `EndCD`, `OnClientEvent`

### [59] 7icbvx.Abilities.Slash of Duality
`LocalScript` · bytecode v9 · 5375 bytes · 101 constants
- **Remotes:** AbilityButtonPress, Data, DualityInitialActivation, DualityShootActivation, EndCD, M1Stop, VisualBindableCD
- **Services:** Players, ReplicatedStorage, UserInputService, game, workspace
- **Key API:** Connect, Disconnect, FindFirstChild, Fire, FireServer, GetAttribute, GetService, LoadAnimation, OnClientEvent, WaitForChild
- Constants: `Misc`, `DataAbilities`, `script`, `Name`, `FindFirstChild`, `GetAttributes`, `AbilityUpgrades`, `Get`, `Icon`, `Image`, `updateIcon`, `Parent`, `workspace`, `Alive`, `toggleOff`, `playAnimationTrack`, `Character`, `DualityDualEnd`, `GetAttribute`, `PlayerGui`, `Hotbar`, `Ability`, `Red`, `Visible`, `opened`, `getAvailable`, `Humanoid`, `getTargetByCamera`, `toggleOn`, `Remotes`, `DualityInitialActivation`, `FireServer`, `AncestryChanged`, `Connect`, `select`, `Disconnect`, `DualityShootActivation`, `ability`, `UseBind`, `Block`, `Thread`, `SafeCancel`, `task`, `spawn`, `Slash of Duality`, `Upgrades`, `Value`, `getAbilityCooldown`, `isBothInCooldow`, `getLowestCooldown`, `VisualBindableCD`, `Fire`, `delay`, `Enabled`, `GetPropertyChangedSignal`, `CurrentlyEquippedAbility`, `game`, `ReplicatedStorage`, `GetService`, `Players`, `LocalPlayer`, `CharacterAdded`, `Wait`, `WaitForChild`, `require`, `UserInputService`, `Controllers`, `SettingsController`, `Shared`, `ThreadSafeTargetingHelper`, `charge`, `Animator`, `FindFirstChildOfClass`, `LoadAnimation`, `charge_hold`, `swinga`, `Packages`, `Replion`, `AbilityUtils`, `Abilities`, `SpeedModifiers`, `JumpModifiers`, `Common`, `Utils`, `CurrentCamera`, `GetMouse`, `Vector`, `Client`, `Data`, `WaitReplion`, `OnChange`, `DualityChoice`, `M1Stop`, `InputBegan`, `AbilityButtonPress`, `Event`, `EndCD`, `OnClientEvent`, `onChoiceChange`, `GetAttributeChangedSignal`

### [60] 7icbvx.Abilities.Slash of Duality.DualityChoice
`ModuleScript` · bytecode v9 · 23019 bytes · 193 constants
- **Remotes:** AbilityButtonPress, DualitySwitchTarget
- **Services:** Players, ReplicatedStorage, RunService, StarterGui, UserInputService, game, workspace
- **Key API:** Clone, Connect, Destroy, Disconnect, FindFirstChild, Fire, FireServer, GetAttribute, GetChildren, GetService, SetAttribute, WaitForChild, new
- Constants: `script`, `workspace`, `IsDescendantOf`, `Destroy`, `Parent`, `Enabled`, `setUp`, `Clean`, `opened`, `Adornee`, `SlashOfDualityCDs`, `Visible`, `coroutine`, `resume`, `math`, `random`, `Name`, `toggleOff`, `LocalPlayer`, `Upgrades`, `Value`, `next`, `SelectedOverlay`, `isAvailable`, `Timer`, `UDim2`, `fromScale`, `Position`, `Frame`, `Label`, `OriginalText`, `GetAttribute`, `Text`, `SetAttribute`, `Size`, `Enum`, `EasingDirection`, `InOut`, `EasingStyle`, `Linear`, `TweenSize`, `toggleOn`, `Alive`, `GetChildren`, `AreCharactersEnemies`, `Invisible`, `HumanoidRootPart`, `WorldToScreenPoint`, `Vector2`, `new`, `X`, `Y`, `Magnitude`, `getTargetByCamera`, `CFrame`, `LookVector`, `ipairs`, `table`, `insert`, `RaycastParams`, `RaycastFilterType`, `Include`, `FilterType`, `FilterDescendantsInstances`, `Raycast`, `Instance`, `Model`, `FindFirstAncestorOfClass`, `getTargetByRay`, `Dual`, `DualityCooldown`, `isSomeInCooldow`, `getAvailable`, `LightDualityCooldown`, `DarkDualityCooldown`, `GetServerTimeNow`, `max`, `getHighestEnd`, `min`, `getLowestEnd`, `getHighestCooldown`, `getLowestCooldown`, `isBothInCooldow`, `FindFirstChild`, `Background`, `Bar`, `Color3`, `fromRGB`, `BackgroundColor3`, `Duration`, `READY`, `resetCooldownFrames`, `CurrentlyEquippedAbility`, `Slash of Duality`, `checkCDsVisibility`, `Ability`, `UseBind`, `Block`, `Remove`, `string`, `format`, `%0.1fs`, `floor`, `pairs`, `fastTween`, `TweenInfo`, `Add`, `Heartbeat`, `Connect`, `updateDualAvailable`, `onChoiceChange`, `Fire`, `typeof`, `number`, `Waiting`, `task`, `wait`, `Light`, `Dark`, `DualitySecondTarget`, `Switch to Target 1`, `Switch to Target 2`, `updateSwitchTarget`, `GetAttributeChangedSignal`, `DualityDualEnd`, `Remotes`, `DualitySwitchTarget`, `FireServer`, `delay`, `toggleTarget`, `Selection`, `Character`, `CharacterAdded`, `Wait`, `AncestryChanged`, `Activated`, `InputBegan`, `ChildAdded`, `ChildRemoved`, `AbilityButtonPress`, `Event`, `Head`, `SelectSecondTarget`, `running`, `yield`, `UIScale`, `Scale`, `Sine`, `Out`, `RenderStepped`, `TweenPosition`, `spawn`, `unpack`, `select`, `game`, `Disconnect`, `ReplicatedStorage`, `GetService`, `Players`, `RunService`, `StarterGui`, `require`, `UserInputService`, `WaitForChild`, `Controllers`, `SettingsController`, `Shared`, `FastUtils`, `Packages`, `Promise`, `Signal`, `ThreadSafeTargetingHelper`, `Trove`, `CurrentCamera`, `GetMouse`, `PlayerGui`, `DualityChoice`, `ProgressBar`, `Fill`, `Hotbar`, `Highlight`, `FillTransparency`, `FillColor`, `OutlineColor`, `PREVIEW_SECOND_DUALITY_SELECTION`, `Misc`, `DualityBillboard`, `Clone`, `PREVIEW_DualityBillboard`, `Choices`, `SwitchTarget`, `Extend`, `GetPropertyChangedSignal`

### [61] 7icbvx.Abilities.Slashes of Fury
`LocalScript` · bytecode v9 · 6450 bytes · 137 constants
- **Remotes:** AbilityButtonPress, Data, EndCD, VisualBindableCD
- **Services:** Debris, Players, ReplicatedStorage, UserInputService, game, workspace
- **Key API:** Clone, Connect, Destroy, FindFirstChild, Fire, FireServer, GetAttribute, GetChildren, GetService, OnClientEvent, Play, WaitForChild, new
- Constants: `Misc`, `DataAbilities`, `script`, `Name`, `FindFirstChild`, `GetAttributes`, `AbilityUpgrades`, `Get`, `Icon`, `Vector`, `Image`, `updateIcon`, `pcall`, `GetRankInGroup`, `game`, `CreatorId`, `getRank`, `Character`, `Parent`, `workspace`, `Alive`, `Red`, `Visible`, `Balls`, `GetChildren`, `error`, `Play`, `isTestGame`, `FFlag`, `GetInstantFFlag`, `SlashesOfFuryMinGroupRank`, `This ability is currently disabled!`, `SendNotification`, `FireServer`, `Remotes`, `VisualBindableCD`, `Fire`, `ability`, `Ability`, `UseBind`, `Thread`, `SafeCancel`, `FuryCatch`, `GetAttribute`, `Destroy`, `GetServerTimeNow`, `task`, `delay`, `print`, `ended`, `Enabled`, `tostring`, `Cancel`, `Instance`, `new`, `Highlight`, `FuryHighlight`, `Color3`, `fromRGB`, `FillColor`, `FillTransparency`, `OutlineColor`, `realBall`, `ComboCounter`, `Assets`, `Clone`, `TextLabel`, `UIScale`, `Scale`, `%*`, `format`, `Text`, `fromHSV`, `math`, `min`, `Lerp`, `TextColor3`, `StudsOffset`, `fastTween`, `TweenInfo`, `Enum`, `EasingStyle`, `Sine`, `EasingDirection`, `InOut`, `PlayerGui`, `FuryTimer`, `Selection`, `ProgressBar`, `Fill`, `UDim2`, `fromScale`, `Size`, `Linear`, `ReplicatedStorage`, `GetService`, `require`, `UserInputService`, `WaitForChild`, `Players`, `Debris`, `Packages`, `Net`, `Controllers`, `SettingsController`, `Shared`, `ThreadSafeTargetingHelper`, `FastUtils`, `Common`, `Utils`, `Replion`, `ServerInfo`, `NotificationController`, `Abilities`, `LocalPlayer`, `CharacterAdded`, `Wait`, `Humanoid`, `SlashesOfFuryActivate`, `RemoteEvent`, `Hotbar`, `Client`, `Data`, `WaitReplion`, `spawn`, `OnChange`, `InputBegan`, `Connect`, `AbilityButtonPress`, `Event`, `EndCD`, `OnClientEvent`, `GetAttributeChangedSignal`, `VFXController`, `SlashesOfFuryEnd`, `SlashesOfFuryParry`

### [62] 7icbvx.Abilities.Super Jump
`LocalScript` · bytecode v9 · 3646 bytes · 91 constants
- **Remotes:** AbilityButtonPress, EndCD, KeybindM2, PlrSuperJumped, VisualBindableCD
- **Services:** Debris, Players, ReplicatedStorage, TweenService, UserInputService, Workspace, game, workspace
- **Key API:** Connect, Create, Fire, FireServer, GetService, LoadAnimation, OnClientEvent, Play, WaitForChild, new
- Constants: `Character`, `Parent`, `workspace`, `Alive`, `PlayerGui`, `Hotbar`, `Ability`, `Red`, `Visible`, `PrimaryPart`, `GetPivot`, `Position`, `Spherecast`, `print`, `things above`, `getAbilityCooldown`, `script`, `Name`, `Upgrades`, `Value`, `playAnimationTrack`, `FieldOfView`, `game`, `Workspace`, `CurrentCamera`, `TweenInfo`, `new`, `Enum`, `EasingStyle`, `Linear`, `EasingDirection`, `Out`, `TweenService`, `GetService`, `Create`, `Play`, `Remotes`, `PlrSuperJumped`, `FireServer`, `VisualBindableCD`, `Fire`, `Instance`, `BodyVelocity`, `Dash`, `HumanoidRootPart`, `MaxForce`, `Vector3`, `Velocity`, `AddItem`, `task`, `delay`, `ability`, `UseBind`, `Thread`, `SafeCancel`, `UserInputType`, `MouseButton2`, `ReplicatedStorage`, `Players`, `LocalPlayer`, `CharacterAdded`, `Wait`, `require`, `UserInputService`, `WaitForChild`, `Humanoid`, `Debris`, `Controllers`, `SettingsController`, `Common`, `Utils`, `Shared`, `AbilityUtils`, `Abilities`, `SuperJump`, `Animator`, `FindFirstChildOfClass`, `LoadAnimation`, `Vector`, `iconId`, `Image`, `RaycastParams`, `CollisionGroup`, `InputBegan`, `Connect`, `AbilityButtonPress`, `Event`, `EndCD`, `OnClientEvent`, `KeybindM2`

### [63] 7icbvx.Abilities.Swap
`LocalScript` · bytecode v9 · 3681 bytes · 87 constants
- **Remotes:** AbilityButtonPress, EndCD, Swapped, VisualBindableCD
- **Services:** Debris, Players, ReplicatedStorage, TweenService, UserInputService, game, workspace
- **Key API:** Connect, Create, FindFirstChild, Fire, FireServer, GetAttribute, GetChildren, GetService, OnClientEvent, Play, WaitForChild, new
- Constants: `Character`, `Parent`, `workspace`, `Alive`, `PlayerGui`, `Hotbar`, `Ability`, `Red`, `Visible`, `TweenInfo`, `new`, `Enum`, `EasingStyle`, `Linear`, `EasingDirection`, `Out`, `FieldOfView`, `Create`, `Play`, `UserInputType`, `MouseButton1`, `Keyboard`, `MouseButton2`, `GetMouseLocation`, `X`, `Y`, `ViewportSize`, `ipairs`, `GetChildren`, `Dead`, `GetAttribute`, `Invisible`, `DoNotTarget`, `IsEncryptedClone`, `IsBoss`, `HumanoidRootPart`, `FindFirstChild`, `Position`, `WorldToScreenPoint`, `Distance`, `Player`, `Vector2`, `Magnitude`, `getAbilityCooldown`, `script`, `Name`, `Remotes`, `Swapped`, `FireServer`, `VisualBindableCD`, `Fire`, `task`, `delay`, `ability`, `UseBind`, `Thread`, `SafeCancel`, `game`, `TweenService`, `GetService`, `require`, `ReplicatedStorage`, `UserInputService`, `WaitForChild`, `Players`, `Debris`, `CurrentCamera`, `LocalPlayer`, `CharacterAdded`, `Wait`, `Humanoid`, `Controllers`, `SettingsController`, `Common`, `Utils`, `Shared`, `Abilities`, `Vector`, `iconId`, `Image`, `InputBegan`, `Connect`, `AbilityButtonPress`, `Event`, `EndCD`, `OnClientEvent`

### [64] 7icbvx.Abilities.Tact
`LocalScript` · bytecode v9 · 826 bytes · 27 constants
- **Services:** Debris, Players, ReplicatedStorage, UserInputService, Workspace, game
- **Key API:** GetService, WaitForChild
- Constants: `game`, `Players`, `LocalPlayer`, `Character`, `CharacterAdded`, `Wait`, `require`, `ReplicatedStorage`, `GetService`, `UserInputService`, `WaitForChild`, `Humanoid`, `Debris`, `Workspace`, `CurrentCamera`, `FieldOfView`, `PlayerGui`, `Hotbar`, `Ability`, `Vector`, `Shared`, `Abilities`, `script`, `Name`, `iconId`, `Image`

### [65] 7icbvx.Abilities.Telekinesis
`LocalScript` · bytecode v9 · 3310 bytes · 81 constants
- **Remotes:** AbilityButtonPress, EndCD, KeybindM2, Telekinesis, VisualBindableCD
- **Services:** Debris, Players, ReplicatedStorage, TweenService, UserInputService, Workspace, game, workspace
- **Key API:** Connect, Create, Fire, FireServer, GetChildren, GetService, LoadAnimation, OnClientEvent, Play, WaitForChild, new
- Constants: `Character`, `Parent`, `workspace`, `Alive`, `PlayerGui`, `Hotbar`, `Ability`, `Red`, `Visible`, `FieldOfView`, `game`, `Workspace`, `CurrentCamera`, `TweenInfo`, `new`, `Enum`, `EasingStyle`, `Quart`, `EasingDirection`, `In`, `TweenService`, `GetService`, `Create`, `Play`, `getAbilityCooldown`, `script`, `Name`, `Remotes`, `VisualBindableCD`, `Fire`, `next`, `GetChildren`, `HumanoidRootPart`, `Position`, `WorldToScreenPoint`, `task`, `delay`, `Telekinesis`, `CFrame`, `X`, `Y`, `FireServer`, `playAnimationTrack`, `ability`, `UseBind`, `Thread`, `SafeCancel`, `UserInputType`, `MouseButton2`, `ReplicatedStorage`, `Players`, `LocalPlayer`, `CharacterAdded`, `Wait`, `require`, `UserInputService`, `WaitForChild`, `Humanoid`, `Debris`, `Controllers`, `SettingsController`, `Common`, `Utils`, `Shared`, `AbilityUtils`, `Abilities`, `Animator`, `FindFirstChildOfClass`, `LoadAnimation`, `GetMouse`, `Vector`, `iconId`, `Image`, `InputBegan`, `Connect`, `AbilityButtonPress`, `Event`, `EndCD`, `OnClientEvent`, `KeybindM2`

### [66] 7icbvx.Abilities.Thunder Dash
`LocalScript` · bytecode v9 · 3652 bytes · 89 constants
- **Remotes:** AbilityButtonPress, EndCD, KeybindM2, ThunderDash, VisualBindableCD
- **Services:** Debris, Players, ReplicatedStorage, UserInputService, Workspace, game, workspace
- **Key API:** Connect, FindFirstChild, Fire, FireServer, GetService, OnClientEvent, Play, WaitForChild, new
- Constants: `Character`, `Parent`, `workspace`, `Alive`, `PlayerGui`, `Hotbar`, `Ability`, `Red`, `Visible`, `MoveDirection`, `Misc`, `error`, `Play`, `PrimaryPart`, `FREEZER`, `FindFirstChild`, `getAbilityCooldown`, `script`, `Name`, `Upgrades`, `Value`, `HumanoidRootPart`, `Position`, `Head`, `CFrame`, `Left Arm`, `Right Arm`, `Right Leg`, `Left Leg`, `Torso`, `Remotes`, `VisualBindableCD`, `Fire`, `ThunderDash`, `FireServer`, `RaycastParams`, `new`, `Enum`, `RaycastFilterType`, `Exclude`, `FilterType`, `Runtime`, `Dead`, `Balls`, `TrainingBalls`, `FilterDescendantsInstances`, `Unit`, `Raycast`, `Instance`, `task`, `delay`, `ability`, `UseBind`, `Thread`, `SafeCancel`, `UserInputType`, `MouseButton2`, `game`, `ReplicatedStorage`, `GetService`, `Players`, `LocalPlayer`, `CharacterAdded`, `Wait`, `require`, `UserInputService`, `WaitForChild`, `Humanoid`, `Debris`, `Workspace`, `CurrentCamera`, `FieldOfView`, `Controllers`, `SettingsController`, `Common`, `Utils`, `Shared`, `Abilities`, `Vector`, `iconId`, `Image`, `InputBegan`, `Connect`, `AbilityButtonPress`, `Event`, `EndCD`, `OnClientEvent`, `KeybindM2`

### [67] 7icbvx.Abilities.Time Hole
`LocalScript` · bytecode v9 · 1988 bytes · 54 constants
- **Remotes:** AbilityButtonPress, EndCD, VisualBindableCD
- **Services:** Debris, Players, ReplicatedStorage, UserInputService, game, workspace
- **Key API:** Connect, Fire, FireServer, GetService, OnClientEvent, WaitForChild
- Constants: `Character`, `Parent`, `workspace`, `Alive`, `Red`, `Visible`, `getAbilityCooldown`, `script`, `Name`, `FireServer`, `Remotes`, `VisualBindableCD`, `Fire`, `task`, `delay`, `ability`, `Ability`, `UseBind`, `Thread`, `SafeCancel`, `game`, `ReplicatedStorage`, `GetService`, `require`, `UserInputService`, `WaitForChild`, `Players`, `Debris`, `Packages`, `Net`, `Controllers`, `SettingsController`, `Common`, `Utils`, `Shared`, `Abilities`, `LocalPlayer`, `CharacterAdded`, `Wait`, `Humanoid`, `TimeHoleActivate`, `RemoteEvent`, `PlayerGui`, `Hotbar`, `Vector`, `iconId`, `Image`, `InputBegan`, `Connect`, `AbilityButtonPress`, `Event`, `EndCD`, `OnClientEvent`

### [68] 7icbvx.Abilities.Titan Blade
`LocalScript` · bytecode v9 · 6486 bytes · 132 constants
- **Remotes:** AbilityButtonPress, DashFired, Data, EndCD, KeybindM2, PlrDashed, VisualBindableCD
- **Services:** Debris, Players, ReplicatedStorage, TweenService, UserInputService, game, workspace
- **Key API:** Connect, Create, Disconnect, FindFirstChild, Fire, FireServer, GetAttribute, GetDescendants, GetService, InvokeServer, IsA, LoadAnimation, OnClientEvent, Play, SetAttribute, WaitForChild, new
- Constants: `Misc`, `DataAbilities`, `FindFirstChild`, `GetAttributes`, `AbilityUpgrades`, `Get`, `Icon`, `Vector`, `Image`, `updateIcon`, `BasePart`, `IsA`, `Massless`, `DashSetMassless`, `SetAttribute`, `ipairs`, `GetDescendants`, `DescendantAdded`, `Connect`, `GetAttribute`, `Enabled`, `Disconnect`, `AssemblyLinearVelocity`, `AssemblyAngularVelocity`, `Parent`, `workspace`, `Alive`, `Red`, `Visible`, `MoveDirection`, `task`, `delay`, `FieldOfView`, `CurrentCamera`, `TweenInfo`, `new`, `Enum`, `EasingStyle`, `Linear`, `EasingDirection`, `Out`, `Create`, `Play`, `GetScale`, `Remotes`, `DashFired`, `Fire`, `VisualBindableCD`, `PlrDashed`, `FireServer`, `playAnimationTrack`, `CFrame`, `RightVector`, `LookVector`, `Dot`, `math`, `random`, `clamp`, `Instance`, `Attachment`, `LinearVelocity`, `Dash`, `Name`, `ForceLimitMode`, `PerAxis`, `MaxAxesForce`, `Attachment0`, `VectorVelocity`, `AddItem`, `defer`, `Colliders`, `Pin`, `RigidConstraint`, `FindFirstChildWhichIsA`, `wait`, `dash`, `InvokeServer`, `InTitanBlade`, `script`, `getAbilityCooldown`, `spawn`, `ability`, `Thread`, `SafeCancel`, `Ability`, `UseBind`, `UserInputType`, `MouseButton2`, `game`, `Debris`, `GetService`, `Players`, `ReplicatedStorage`, `TweenService`, `require`, `UserInputService`, `WaitForChild`, `Assets`, `Controllers`, `Packages`, `Shared`, `Abilities`, `AbilityUtils`, `Net`, `Replion`, `SettingsController`, `Common`, `Utils`, `LocalPlayer`, `Character`, `CharacterAdded`, `Wait`, `HumanoidRootPart`, `Humanoid`, `Animator`, `LoadAnimation`, `NewAbilities/ActivePrimarySlot`, `RemoteFunction`, `PlayerGui`, `Hotbar`, `Client`, `Data`, `WaitReplion`, `OnChange`, `Destroying`, `InputBegan`, `AbilityButtonPress`, `Event`, `EndCD`, `OnClientEvent`, `KeybindM2`

### [69] 7icbvx.Abilities.Tsunami
`LocalScript` · bytecode v9 · 11479 bytes · 104 constants
- **Remotes:** AbilityButtonPress, Data, EndCD, VisualBindableCD
- **Services:** Players, ReplicatedStorage, UserInputService, game, workspace
- **Key API:** Connect, Disconnect, FindFirstChild, Fire, GetAttribute, GetService, InvokeServer, IsA, OnClientEvent, Play, WaitForChild, new
- Constants: `AbilityUpgrades`, `Get`, `Value`, `type`, `number`, `math`, `max`, `getUpgradeLevel`, `uses`, `getMaxUsesLeft`, `TsunamiUses`, `GetAttribute`, `getDisplayedUsesLeft`, `ready`, `FindFirstChild`, `counts`, `TextLabel`, `IsA`, `tostring`, `Text`, `updateRemainingLabel`, `VisualBindableCD`, `Fire`, `refreshUsesLeft`, `Disconnect`, `TsunamiCharges`, `GetAttributeChangedSignal`, `Connect`, `updateCharacter`, `DataAbilities`, `GetAttributes`, `Icon`, `Icon%*`, `format`, `Image`, `updateIcon`, `workspace`, `CurrentCamera`, `HumanoidRootPart`, `CFrame`, `LookVector`, `BasePart`, `X`, `Z`, `Vector3`, `new`, `Magnitude`, `Unit`, `getDirectionPayload`, `Parent`, `Alive`, `Red`, `Visible`, `Misc`, `error`, `Play`, `task`, `delay`, `InvokeServer`, `clamp`, `ability`, `Ability`, `UseBind`, `game`, `Players`, `GetService`, `ReplicatedStorage`, `require`, `UserInputService`, `WaitForChild`, `Common`, `Controllers`, `Packages`, `Remotes`, `Shared`, `script`, `Name`, `LocalPlayer`, `Character`, `CharacterAdded`, `Wait`, `Abilities`, `Net`, `Replion`, `SettingsController`, `Utils`, `NewAbilities/ActivePrimarySlot`, `RemoteFunction`, `PlayerGui`, `Hotbar`, `Vector`, `Client`, `Data`, `WaitReplion`, `Tsunami`, `Upgrades`, `OnChange`, `Changed`, `InputBegan`, `AbilityButtonPress`, `Event`, `EndCD`, `OnClientEvent`

### [70] 7icbvx.Abilities.Virus
`LocalScript` · bytecode v9 · 466 bytes · 17 constants
- **Services:** Players, ReplicatedStorage, game
- **Key API:** GetService, WaitForChild
- Constants: `game`, `Players`, `GetService`, `ReplicatedStorage`, `LocalPlayer`, `PlayerGui`, `WaitForChild`, `Hotbar`, `Ability`, `Vector`, `require`, `Virus`, `Shared`, `Abilities`, `iconId`, `Image`

### [71] 7icbvx.Abilities.Water Dragon
`LocalScript` · bytecode v9 · 4050 bytes · 85 constants
- **Remotes:** AbilityButtonPress, Data, EndCD, VisualBindableCD
- **Services:** Debris, Players, ReplicatedStorage, UserInputService, game, workspace
- **Key API:** Connect, FindFirstChild, Fire, GetAttribute, GetChildren, GetService, InvokeServer, OnClientEvent, Play, WaitForChild
- Constants: `Value`, `getMaxUsesLeft`, `Misc`, `DataAbilities`, `script`, `Name`, `FindFirstChild`, `GetAttributes`, `AbilityUpgrades`, `Get`, `Icon`, `Icon%*`, `format`, `Vector`, `WaitForChild`, `Image`, `updateIcon`, `OnChange`, `Hotbar`, `Ability`, `ready`, `counts`, `tostring`, `Text`, `updateRemainingLabel`, `InvokeServer`, `Character`, `Parent`, `workspace`, `Alive`, `Red`, `Visible`, `error`, `Play`, `Balls`, `GetChildren`, `realBall`, `GetAttribute`, `target`, `Remotes`, `VisualBindableCD`, `Fire`, `task`, `delay`, `xpcall`, `warn`, `math`, `clamp`, `ability`, `UseBind`, `Thread`, `SafeCancel`, `game`, `ReplicatedStorage`, `GetService`, `require`, `UserInputService`, `Players`, `Debris`, `Packages`, `Net`, `Replion`, `Common`, `Utils`, `Controllers`, `SettingsController`, `LocalPlayer`, `CharacterAdded`, `Wait`, `Humanoid`, `WaterDragon`, `RemoteFunction`, `PlayerGui`, `Upgrades`, `WaterDragonUses`, `Client`, `Data`, `AwaitReplion`, `InputBegan`, `Connect`, `AbilityButtonPress`, `Event`, `EndCD`, `OnClientEvent`

### [72] 7icbvx.Abilities.Waypoint
`LocalScript` · bytecode v9 · 3119 bytes · 74 constants
- **Remotes:** AbilityButtonPress, EndCD, KeybindM2, PlrWaypointed, VisualBindableCD, WaypointCombust
- **Services:** Debris, Players, ReplicatedStorage, UserInputService, Workspace, game, workspace
- **Key API:** Connect, FindFirstChild, Fire, FireServer, GetAttribute, GetService, OnClientEvent, Play, WaitForChild
- Constants: `Character`, `Parent`, `workspace`, `Alive`, `PlayerGui`, `Hotbar`, `Ability`, `Red`, `Visible`, `UIGradient`, `Offset`, `Y`, `WaypointFor_%*`, `Name`, `format`, `PrimaryPart`, `FREEZER`, `FindFirstChild`, `Misc`, `error`, `Play`, `getAbilityCooldown`, `script`, `Runtime`, `print`, `Remotes`, `PlrWaypointed`, `FireServer`, `VisualBindableCD`, `Fire`, `task`, `delay`, `Destroyed`, `GetAttribute`, `WaypointCombust`, `ability`, `UseBind`, `Thread`, `SafeCancel`, `Enum`, `UserInputType`, `MouseButton2`, `game`, `ReplicatedStorage`, `GetService`, `Players`, `LocalPlayer`, `CharacterAdded`, `Wait`, `require`, `UserInputService`, `WaitForChild`, `Humanoid`, `Debris`, `Workspace`, `CurrentCamera`, `FieldOfView`, `Controllers`, `SettingsController`, `Common`, `Utils`, `Shared`, `Abilities`, `Vector`, `iconId`, `Image`, `InputBegan`, `Connect`, `AbilityButtonPress`, `Event`, `EndCD`, `OnClientEvent`, `KeybindM2`

### [73] 7icbvx.Abilities.Wind Cloak
`LocalScript` · bytecode v9 · 2992 bytes · 72 constants
- **Remotes:** AbilityButtonPress, CloakJump, EndCD, KeybindM2, VisualBindableCD, WindCloak
- **Services:** Debris, Players, ReplicatedStorage, UserInputService, Workspace, game, workspace
- **Key API:** Connect, FindFirstChild, Fire, FireServer, GetService, OnClientEvent, WaitForChild
- Constants: `Character`, `Parent`, `workspace`, `Alive`, `PlayerGui`, `Hotbar`, `Ability`, `Red`, `Visible`, `getAbilityCooldown`, `script`, `Name`, `Upgrades`, `Value`, `Remotes`, `WindCloak`, `FireServer`, `VisualBindableCD`, `Fire`, `task`, `delay`, `ability`, `UseBind`, `Thread`, `SafeCancel`, `Enum`, `UserInputType`, `MouseButton2`, `Torso`, `Whirlwinds`, `FindFirstChild`, `MaxWhirlwinds`, `os`, `clock`, `FloorMaterial`, `Material`, `Air`, `CloakJump`, `wait`, `game`, `ReplicatedStorage`, `GetService`, `Players`, `LocalPlayer`, `CharacterAdded`, `Wait`, `require`, `UserInputService`, `WaitForChild`, `Humanoid`, `Debris`, `Workspace`, `CurrentCamera`, `FieldOfView`, `Controllers`, `SettingsController`, `Common`, `Utils`, `Shared`, `Abilities`, `Vector`, `iconId`, `Image`, `InputBegan`, `Connect`, `AbilityButtonPress`, `Event`, `EndCD`, `OnClientEvent`, `KeybindM2`, `JumpRequest`

### [74] 7icbvx.Abilities.Zeus' Storm
`LocalScript` · bytecode v9 · 2367 bytes · 60 constants
- **Remotes:** AbilityButtonPress, EndCD, VisualBindableCD
- **Services:** Debris, Players, ReplicatedStorage, UserInputService, game, workspace
- **Key API:** Connect, Fire, GetService, InvokeServer, OnClientEvent, WaitForChild
- Constants: `cooldownThread`, `Character`, `Parent`, `workspace`, `Alive`, `PlayerGui`, `Hotbar`, `Ability`, `Red`, `Visible`, `Upgrades`, `Value`, `getAbilityCooldown`, `task`, `delay`, `Remotes`, `VisualBindableCD`, `Fire`, `InvokeServer`, `wait`, `ability`, `UseBind`, `Thread`, `SafeCancel`, `game`, `ReplicatedStorage`, `GetService`, `Players`, `LocalPlayer`, `CharacterAdded`, `Wait`, `require`, `UserInputService`, `WaitForChild`, `Humanoid`, `Debris`, `Controllers`, `SettingsController`, `Shared`, `GetAbilityCooldownMultiplier`, `Common`, `Utils`, `AbilityUtils`, `Abilities`, `Packages`, `Net`, `script`, `Name`, `NewAbilities/ActivePrimarySlot`, `RemoteFunction`, `Vector`, `iconId`, `Image`, `InputBegan`, `Connect`, `AbilityButtonPress`, `Event`, `EndCD`, `OnClientEvent`

### [75] 7icbvx.BaseUIS
`LocalScript` · bytecode v9 · 9837 bytes · 184 constants
- **Remotes:** CloakJump, Data, DoubleJump, KeybindM2, M1Stop, OnDeath, Platform, RequestReflectionData, ResetFOV, XtraJumped
- **Services:** CollectionService, Debris, Players, ReplicatedStorage, UserInputService, game, workspace
- **Key API:** Clone, Connect, Destroy, FindFirstChild, Fire, FireServer, GetAttribute, GetChildren, GetDescendants, GetService, IsA, LoadAnimation, OnClientEvent, OnClientInvoke, Once, Play, SetAttribute, Stop, WaitForChild, new
- Constants: `Destroy`, `warn`, `PlayEmote event is deprecated, switch to EmoteController:Play() instead`, `Play`, `FireServer`, `ipairs`, `GetChildren`, `HumanoidRootPart`, `FindFirstChild`, `Name`, `Position`, `WorldToScreenPoint`, `GetLastInputType`, `Enum`, `UserInputType`, `MouseButton1`, `Keyboard`, `MouseButton2`, `X`, `Y`, `ViewportSize`, `refCFrame`, `people`, `mouseposition`, `workspace`, `CurrentCamera`, `CFrame`, `PULSED`, `GetAttribute`, `Parent`, `getEquippedAbility`, `AbilityBlockPassive`, `AbilityBlockCharges`, `Quad Jump`, `getJumpCapValue`, `Character`, `Alive`, `IsDoppelganger`, `DoppelgangerOwner`, `getDoppelgangerBot`, `Fire`, `tryRequestDoppelNormalJump`, `task`, `wait`, `JumpRequest`, `os`, `clock`, `JumpDB`, `FloorMaterial`, `Material`, `Air`, `spawn`, `Instance`, `new`, `BodyVelocity`, `Dash`, `MaxForce`, `Velocity`, `Upgrades`, `Value`, `Vector3`, `AddItem`, `Torso`, `Whirlwinds`, `MaxWhirlwinds`, `Remotes`, `CloakJump`, `DoubleJump`, `SwordAnimationProfile`, `AnimationProfile`, `Default`, `Stop`, `Shared`, `Abilities`, `Activated`, `XtraJumped`, `CurrentlySelectedMap`, `table`, `find`, `Gamepad`, `Vector2`, `thumbstickDelta`, `Touch`, `OnDeath`, `Highlight`, `FindFirstChildOfClass`, `ParticleShine`, `OwnerCharacter`, `LocalPlayer`, `BasePart`, `IsA`, `CanCollide`, `defer`, `script`, `Blink`, `Enabled`, `counts`, `Visible`, `ResetFOV`, `Slash of Duality`, `DualityChoice`, `require`, `toggleOff`, `Death Slash`, `M1Stop`, `TimingUIHandler`, `ToggleUIOff`, `Slashes of Fury`, `PlayerGui`, `FuryTimer`, `FuryHighlight`, `Balls`, `ComboCounter`, `Raging Deflection`, `SpeedModifiers`, `Initial Raging Deflect Debuff`, `RemoveModifierFor`, `NinjaDash`, `GetDescendants`, `DashSetMassless`, `SetAttribute`, `Massless`, `GetPropertyChangedSignal`, `Connect`, `game`, `Debris`, `GetService`, `ReplicatedStorage`, `UserInputService`, `WaitForChild`, `Players`, `ClientStarted`, `GetAttributeChangedSignal`, `Wait`, `Packages`, `Net`, `Replion`, `UseBall2`, `Controllers`, `EmoteController`, `Inventory`, `Client`, `AbilityUtils`, `GetMouse`, `CharacterAdded`, `Humanoid`, `Data`, `WaitReplion`, `Animator`, `WindowFocused`, `RemoteEvent`, `DoubleJumps`, `LoadAnimation`, `AnimationPriority`, `Action2`, `Priority`, `Twirl`, `Clone`, `Destroying`, `Once`, `Hotbar`, `MoonMap`, `ZeroGravityArena`, `Dead`, `PlayEmote`, `Event`, `WindowFocusReleased`, `InputBegan`, `RequestReflectionData`, `OnClientInvoke`, `EmoteWheelController`, `zero`, `InputChanged`, `Died`, `KeybindM2`, `OnClientEvent`, `CollectionService`, `Platform`, `GetInstanceAddedSignal`, `Ability`, `ready`, `FieldOfView`, `Observers`, `observeChildren`

### [76] 7icbvx.ClientPulsed
`LocalScript` · bytecode v9 · 1233 bytes · 33 constants
- **Remotes:** ClientPulse
- **Services:** Players, ReplicatedStorage, game, workspace
- **Key API:** Connect, GetAttribute, GetService, OnClientEvent, WaitForChild
- Constants: `PULSED`, `GetAttribute`, `Visible`, `update`, `Character`, `task`, `wait`, `game`, `ReplicatedStorage`, `GetService`, `Players`, `workspace`, `ClientModulesLoaded`, `GetAttributeChangedSignal`, `Wait`, `require`, `Shared`, `LTM`, `getCurrentLTM`, `ServerInfo`, `isLTMServer`, `Id`, `Flying`, `LocalPlayer`, `PlayerGui`, `Hotbar`, `WaitForChild`, `Ability`, `Red`, `Remotes`, `ClientPulse`, `OnClientEvent`, `Connect`

### [77] 7icbvx.CustomSwimmingLogic
`LocalScript` · bytecode v9 · 9745 bytes · 96 constants
- **Services:** CollectionService, Players, ReplicatedStorage, RunService, UserInputService, game, workspace
- **Key API:** Connect, Destroy, Disconnect, FindFirstChild, GetAttribute, GetService, IsA, WaitForChild, new
- Constants: `CFrame`, `PointToObjectSpace`, `Size`, `X`, `math`, `abs`, `Y`, `Z`, `IsInsideBrick`, `MoveDirection`, `Magnitude`, `PrimaryPart`, `AssemblyLinearVelocity`, `AssemblyMass`, `Instance`, `new`, `Attachment`, `Position`, `WorldPosition`, `Parent`, `table`, `insert`, `VectorForce`, `SwimmingForce`, `Name`, `Enum`, `ActuatorRelativeTo`, `World`, `RelativeTo`, `workspace`, `Gravity`, `Force`, `Attachment0`, `ApplyAtCenterOfMass`, `Heartbeat`, `Connect`, `ipairs`, `Destroy`, `Disconnect`, `clear`, `SetAntiGravityState`, `task`, `delay`, `ApplyDelayedGravity`, `HumanoidStateType`, `Running`, `SetStateEnabled`, `RunningNoPhysics`, `GettingUp`, `Jumping`, `Freefall`, `FallingDown`, `ChangeState`, `_SetCharacterSwimState`, `SetCharacterSwimState`, `_LeaveSwimState`, `TouchEnabled`, `LeaveSwimState`, `GetKeysPressed`, `KeyCode`, `GetPressedKeys`, `find`, `IsJumpKeyPressed`, `PlayingFinisher`, `GetAttribute`, `Head`, `FindFirstChild`, `Swimming`, `SingularityGravity`, `SwimHeartbeat`, `remove`, `destroySwimPart`, `BasePart`, `IsA`, `createSwimPart`, `game`, `RunService`, `GetService`, `require`, `ReplicatedStorage`, `UserInputService`, `WaitForChild`, `CollectionService`, `Players`, `Spawn`, `Space`, `ButtonA`, `LocalPlayer`, `Character`, `Humanoid`, `HumanoidRootPart`, `TouchTapInWorld`, `CUSTOM_WATER_PART`, `GetInstanceRemovedSignal`, `GetInstanceAddedSignal`, `GetTagged`

### [79] 7icbvx.OnFrame
`LocalScript` · bytecode v9 · 1300 bytes · 29 constants
- **Services:** Players, RunService, game
- **Key API:** Connect, GetAttribute, GetService, WaitForChild
- Constants: `HumanoidRootPart`, `WaitForChild`, `RootJoint`, `C0`, `originalC0`, `setupCharacter`, `InOverdriveMech`, `GetAttribute`, `AssemblyLinearVelocity`, `Magnitude`, `Unit`, `CFrame`, `LookVector`, `Dot`, `RightVector`, `Angles`, `math`, `min`, `Lerp`, `game`, `Players`, `GetService`, `RunService`, `LocalPlayer`, `Character`, `CharacterAdded`, `Wait`, `Connect`, `RenderStepped`

### [80] 7icbvx.spinnywheel
`LocalScript` · bytecode v9 · 812 bytes · 22 constants
- **Services:** ReplicatedStorage, RunService, game, workspace
- **Key API:** Connect, GetAttribute, GetService, WaitForChild
- Constants: `CFrame`, `Angles`, `game`, `ReplicatedStorage`, `GetService`, `workspace`, `ClientModulesLoaded`, `GetAttribute`, `GetAttributeChangedSignal`, `Wait`, `require`, `ServerInfo`, `isDuelLobbyServer`, `isDungeonsLobbyServer`, `Spawn`, `WaitForChild`, `Spinnyy`, `task`, `wait`, `RunService`, `RenderStepped`, `Connect`

### [81] LocalPointers
`LocalScript` · bytecode v9 · 1504 bytes · 35 constants
- **Services:** Players, ReplicatedStorage, RunService, UserInputService, game, workspace
- **Key API:** Connect, FindFirstChild, FireServer, GetService, WaitForChild
- Constants: `GetMouseLocation`, `workspace`, `CurrentCamera`, `X`, `Y`, `ScreenPointToRay`, `CFrame`, `lookAt`, `Origin`, `Direction`, `getPointer`, `getLook`, `Pointer`, `FindFirstChild`, `Value`, `Look`, `game`, `Players`, `GetService`, `LocalPlayer`, `require`, `ReplicatedStorage`, `UserInputService`, `WaitForChild`, `GuiService`, `RunService`, `script`, `Parent`, `PreSimulation`, `Connect`, `task`, `wait`, `SetPointer`, `FireServer`, `SetLook`

### [260] Players.Gezzz163.PlayerScripts.EffectScripts.ClientFX.FXs.BlackHole
`ModuleScript` · bytecode v9 · 13704 bytes · 121 constants
- **Remotes:** Data, ResetFOV
- **Services:** Debris, Lighting, Players, ReplicatedStorage, RunService, game, workspace
- **Key API:** Connect, Destroy, Disconnect, FindFirstChild, Fire, GetAttribute, GetChildren, GetService, IsA, Stop, new
- Constants: `Parent`, `isAlive`, `task`, `wait`, `Clean`, `Destroy`, `Enabled`, `PivotTo`, `CFrame`, `Position`, `Vector2`, `new`, `X`, `Z`, `Magnitude`, `Y`, `math`, `atan2`, `Angles`, `pcall`, `clamp`, `Lerp`, `Brightness`, `Saturation`, `Contrast`, `Stop`, `StopSustained`, `delay`, `fastTween`, `TweenInfo`, `Enum`, `EasingStyle`, `Sine`, `EasingDirection`, `Out`, `CameraShakeInstance`, `PositionInfluence`, `RotationInfluence`, `ShakeSustain`, `Size`, `InOut`, `Motor6D`, `FindFirstChild`, `C1`, `SunRays`, `Character`, `workspace`, `Alive`, `Instance`, `ColorCorrectionEffect`, `AddItem`, `In`, `FieldOfView`, `Settings.Misc.FOV.Current`, `Get`, `Back`, `clean`, `Add`, `HumanoidRootPart`, `GetChildren`, `BasePart`, `IsA`, `Transparency`, `Center`, `GlassPart`, `OutlinePart`, `identity`, `BloomEffect`, `Intensity`, `Threshold`, `Attachment`, `FindFirstChildWhichIsA`, `ParticleEmitter`, `EmitDuration`, `GetAttribute`, `RenderPriority`, `Last`, `Value`, `Start`, `Shake`, `Remotes`, `ResetFOV`, `Fire`, `ScaleTo`, `fastScaleToTween`, `Elastic`, `Terrain`, `Clouds`, `SpawnBlackHoleSpawn`, `DespawnBlackHoleSpawn`, `Health`, `Disconnect`, `map`, `max`, `Unit`, `Vector3`, `Humanoid`, `RenderStepped`, `Connect`, `HandleBlackHole`, `Execute`, `game`, `Debris`, `GetService`, `Lighting`, `Players`, `ReplicatedStorage`, `RunService`, `Packages`, `Shared`, `CurrentCamera`, `LocalPlayer`, `require`, `ClientGameModules`, `CameraShaker`, `FastUtils`, `Trove`, `Replion`, `Client`, `Data`, `WaitReplion`

### [766] ReplicatedStorage.Controllers.ServerSelectionController.ServerSelectionController
`Script` · bytecode v9 · 787 bytes · 19 constants
- **Key API:** GetAttribute, SetAttribute
- Constants: `debug`, `setmemorycategory`, `Name`, `Start`, `script`, `Parent`, `require`, `Loaded`, `SetAttribute`, `Init`, `GetAttribute`, `GetAttributeChangedSignal`, `Wait`, `pcall`, `task`, `spawn`, `error`, `%*:Init() - %*`, `format`

### [767] ReplicatedStorage.Controllers.ServerSelectionController.UserThumbnailCache
`ModuleScript` · bytecode v9 · 664 bytes · 9 constants
- Constants: `ContainsThreshold`, `Append`, `Get`, `table`, `clear`, `Dump`, `task`, `wait`, `defer`

### [768] ReplicatedStorage.Controllers.ServerTypeController
`ModuleScript` · bytecode v9 · 4047 bytes · 80 constants
- **Remotes:** ParrySuccess, RoundEnded
- **Services:** Players, ReplicatedStorage, StarterGui, UserInputService, game, workspace
- **Key API:** Connect, GetService, OnClientEvent, WaitForChild, new
- Constants: `Enum`, `CoreGuiType`, `Health`, `Init`, `updateParryCounter`, `isProServer`, `setServerType`, `Pro`, `isTrainingServer`, `Training`, `Remotes`, `ParrySuccess`, `OnClientEvent`, `Connect`, `RoundEnded`, `task`, `defer`, `updateFormFactor`, `workspace`, `CurrentCamera`, `ViewportSize`, `GetPropertyChangedSignal`, `Start`, `IsTenFootInterface`, `BG`, `UDim2`, `new`, `Position`, `Vector2`, `zero`, `AnchorPoint`, `TouchEnabled`, `Y`, `CounterLabel`, `AddCommas`, `Text`, `Tip`, `UIGradient`, `Gradient`, `Color`, `UIStroke`, `StrokeColor`, `StrokeThickness`, `Thickness`, `Enabled`, `require`, `game`, `Players`, `GetService`, `LocalPlayer`, `PlayerScripts`, `WaitForChild`, `ClientLoader`, `ControllerIsolator`, `CreateRequire`, `script`, `GuiService`, `ReplicatedStorage`, `UserInputService`, `StarterGui`, `Packages`, `Signal`, `Common`, `Utils`, `Utilities`, `ValueConvertor`, `ClientGameModules`, `CoreCall`, `ServerInfo`, `PlayerGui`, `ServerType`, `ParryCounter`, `RankedLobby`, `THIS IS A PRO SERVER. <font color="rgb(254, 200, 42)">+1.5X COINS</font>`, `Color3`, `fromRGB`, `ColorSequence`, `EARN <font color="rgb(254, 200, 42)">+1.5X COINS</font> IN RANKED`, `THIS IS A TRAINING SERVER.`, `ColorSequenceKeypoint`

### [769] ReplicatedStorage.Controllers.ServerTypeController.ServerTypeController
`Script` · bytecode v9 · 787 bytes · 19 constants
- **Key API:** GetAttribute, SetAttribute
- Constants: `debug`, `setmemorycategory`, `Name`, `Start`, `script`, `Parent`, `require`, `Loaded`, `SetAttribute`, `Init`, `GetAttribute`, `GetAttributeChangedSignal`, `Wait`, `pcall`, `task`, `spawn`, `error`, `%*:Init() - %*`, `format`

### [770] ReplicatedStorage.Controllers.SettingsController
`ModuleScript` · bytecode v9 · 51844 bytes · 462 constants
- **Remotes:** Data, ResetFOV, Update
- **Services:** CollectionService, Lighting, Players, ReplicatedStorage, RunService, SoundService, UserInputService, game, workspace
- **Key API:** Clone, Connect, Destroy, Disconnect, FindFirstChild, FireServer, GetAttribute, GetDescendants, GetService, Invoke, IsA, SetAttribute, WaitForChild, new
- Constants: `MouseIcon`, `FindFirstChild`, `Instance`, `new`, `ImageLabel`, `Name`, `BackgroundTransparency`, `Vector2`, `AnchorPoint`, `UDim2`, `fromScale`, `Position`, `Size`, `Enum`, `ScaleType`, `Fit`, `Visible`, `ZIndex`, `UIAspectRatioConstraint`, `AspectRatio`, `Parent`, `getHotbarMouseIcon`, `ControllerIcon`, `Text`, `ImageTransparency`, `Image`, `applyHotbarBind`, `TextBox`, `setBindDisplay`, `Color3`, `fromHex`, `string`, `format`, `%06x`, `decToColor3`, `fromRGB`, `Settings.Accessibility.Highlight Color.Current`, `Get`, `getHighlight`, `IsType`, `GetStringForKeyCode`, `CanGetStringForKeyCode`, `CustomGetStringForKeyCode`, `GetLastInputType`, `Keybinds`, `Default`, `find`, `Gamepad`, `Console`, `PC`, `GetDefault`, `debug`, `profilebegin`, `SettingsController:GetBinds`, `profileend`, `Data`, `Settings`, `UserInputType`, `Focus`, `GetConnectedGamepads`, `IsTenFootInterface`, `GetBinds`, `Keyboard`, `KeyCode`, `FireServer`, `Disconnect`, `Active`, `task`, `wait`, `InputBegan`, `Connect`, `BindConnection`, `GetTagged`, `IsDescendantOf`, `GetBindButton`, `GetBindButtons`, `table`, `insert`, `UpdateHotbar`, `GetMappedImageForKeyCode`, `TouchEnabled`, `KeyboardEnabled`, `GamepadEnabled`, `Block`, `UI_BlockBind`, `F`, `Ability`, `UI_AbilityBind`, `Q`, `UI_TradingSignBind`, `1`, `ClassName`, `BasePart`, `IsA`, `Material`, `Neon`, `ParticleEmitter`, `Trail`, `Lifetime`, `Beam`, `Enabled`, `SetType`, `workspace`, `shouldUpdateObject`, `SettingsController.UpdateObject`, `IgnoreLowGraphics`, `GetAttribute`, `SmoothPlastic`, `NumberRange`, `Clear`, `UpdateObject`, `ExceptionVFX`, `HasTag`, `GetDescendants`, `RefreshSword`, `SwordModel`, `RefreshSwords`, `FXName`, `ParticleShine`, `RefreshParryFX`, `ParryFX`, `RefreshParryFXs`, `RefreshExplosion`, `ExplosionVFX`, `RefreshExplosions`, `Misc`, `Gray Sky`, `WaterWaveSize`, `WaterWaveSpeed`, `WaterReflectance`, `WaterTransparency`, `RefreshQuality`, `Destroy`, `disconnect`, `New`, `Current`, `SetColor`, `Finished`, `Canceled`, `Button`, `BackgroundColor3`, `ResetButton`, `update`, `OnChange`, `Touch`, `Bind1`, `Keybind1`, `clear`, `Bind2`, `Keybind2`, `Bind3`, `Keybind3`, `Reset`, `TextLabel`, `X`, `Scale`, `TextBounds`, `AbsoluteSize`, `Y`, `VREnabled`, `CurrentCamera`, `GamepadZoomSteps`, `tonumber`, `SetAttribute`, `updateMaxZoom`, `Volume`, `RequireSettingEnable`, `updateVisibility`, `SetTimeOfDay`, `RemoteEvent`, `Time Of Day`, `next`, `AdjustMusicVolume`, `Clone`, `LayoutOrder`, `DoNotDisplay`, `TemplateType`, `Slider`, `Type`, `Color`, `SubSlide`, `TimeOfDay`, `%*/%*`, `Sub`, `Frame`, `DisplayName`, `Activated`, `Client`, `AwaitReplion`, `OnGuiClose`, `Max`, `Update`, `LastInputTypeChanged`, `SelectionGained`, `SelectionLost`, `Icon`, `GetPropertyChangedSignal`, `Tooltip`, `http://www.roblox.com/asset/?id=14892548930`, `VREnabledChanged`, `rbxasset://textures/ui/ScreenshotHud/Camera.png`, `Max Zoom`, `Server Region`, `Server Region: `, `Region`, `Value`, `Server Version`, `Server Version: `, `ServerVersion`, `LoadSettings`, `Music`, `SFX`, `UI`, `UpdateAllSliders`, `UpdateAllKeybinds`, `cancel`, `delay`, `ScheduleUpdateAllKeybinds`, `UpdateAllMisc`, `SettingsController:Usebind`, `MouseBehavior`, `LockCenter`, `MouseButton2`, `UseBind`, `Init`, `Close`, `CreatorCodes`, `Open`, `ClearCreatorCode`, `Invoke`, `CreatorCodes.Active`, `Label`, `SUPPORT-A-CREATOR: %*`, `NONE`, `updateCreatorCode`, `User`, `IsOpen`, `deselect`, `select`, `None`, `Titles`, `EquippedTitle`, `rbxassetid://101973108838865`, `rbxassetid://72246188791319`, `HoverImage`, `rbxassetid://137266342109996`, `rbxassetid://75518436288869`, `fromOffset`, `updateSize`, `EquipTitle`, `updateAllTitles`, `updateAllTitleSizes`, `Header`, `TitleList`, `defer`, `DescendantAdded`, `print`, `ObjectsValueCache GC`, `clone`, `game`, `FOV`, `FieldOfView`, `fastTween`, `TweenInfo`, `updateFov`, `Settings.Misc.Highlight Players.Enabled`, `IsFocusedByBall`, `Highlight`, `GrayHighlight`, `HighlightDepthMode`, `Occluded`, `DepthMode`, `FillColor`, `FillTransparency`, `OutlineColor`, `OutlineTransparency`, `GetAttributeChangedSignal`, `Atmosphere`, `InTheRisingEvent`, `ClockTime`, `DoNotChangeNight`, `ForceNight`, `Settings.Misc.Time Of Day.Enabled`, `Settings.Misc.Time Of Day.Current`, `isBossFightServer`, `Ambient`, `updateLighting`, `pcall`, `Brightness`, `GlobalShadows`, `Terrain`, `WaterColor`, `Density`, `updateGraySky`, `HumanoidRootPart`, `RenderStepped`, `FindFirstChildWhichIsA`, `Keypoints`, `ColorSequence`, `setColor`, `realBall`, `highlighted`, `RainbowBall`, `os`, `clock`, `math`, `round`, `fromHSV`, `DribbleActive`, `Lerp`, `Collider`, `observeReplionPath`, `BeforeDestroy`, `observeChildren`, `observeAttribute`, `observeBall`, `DisableBallColor`, `updateBallColorAtt`, `MouseButton1`, `ButtonA`, `ButtonX`, `getReplionPathState`, `Settings.Misc.Remove Emotes SFX.Enabled`, `RemoveSFX_Save`, `Computed`, `ButtonR1`, `WaitReplion`, `Low Graphics`, `Weapon VFX`, `Explosion VFX`, `ToggleKeybind`, `ToggleMisc`, `ToggleDevice`, `PlayerGui`, `WaitForChild`, `HUD`, `UIListLayout`, `SettingSlider`, `SettingKeybind`, `SettingToggle`, `CloseButton`, `CreatorCode`, `Cancel`, `SettingColor`, `SettingSubSlider`, `SettingTimeOfDay`, `OnDescendantChange`, `Settings.Volume`, `Settings.Keybinds`, `Settings.Misc`, `WaitForIcon`, `toggled`, `OnClose`, `OnOpen`, `typeof`, `pairs`, `SettingOpenMenu`, `SettingTitles`, `Tag`, `Template`, `TextColor3`, `Selected`, `spawn`, `observeTag`, `ObjectVFX`, `GetInstanceAddedSignal`, `EmoteVFXStorage`, `Settings.Misc.FOV.Current`, `Remotes`, `ResetFOV`, `Event`, `getCurrentLTM`, `isLTMServer`, `getGameMode`, `SquadRoyale`, `observeCharacters`, `ColoredHighlight`, `PlayerTargetHighlight`, `ChildAdded`, `Clouds`, `FakeSky`, `ColorShift_Bottom`, `ColorShift_Top`, `EnvironmentDiffuseScale`, `EnvironmentSpecularScale`, `FogColor`, `FogStart`, `FogEnd`, `GeographicLatitude`, `OutdoorAmbient`, `observeCharacter`, `Settings.Misc.Gray Sky.Enabled`, `Map`, `observeDescendants`, `Balls`, `TrainingBalls`, `Accessibility/Highlight Color`, `MouseEnter`, `MouseMoved`, `MouseLeave`, `CanvasPosition`, `EmoteSFX`, `Start`, `require`, `Players`, `GetService`, `LocalPlayer`, `PlayerScripts`, `ClientLoader`, `ControllerIsolator`, `CreateRequire`, `script`, `SoundService`, `ReplicatedStorage`, `UserInputService`, `GuiService`, `CollectionService`, `Lighting`, `RunService`, `Shared`, `VRService`, `Packages`, `Replion`, `Net`, `Common`, `SettingsInfo`, `ClientGameModules`, `GuiHandler`, `SliderNode`, `Controllers`, `GamepadIconController`, `ReplicatedInstances`, `Swords`, `TopBarController`, `TooltipController`, `FrameCap`, `ServerInfo`, `ReplionUtils`, `Observers`, `LTM`, `FastUtils`, `Statable`, `TitleData`, `GetMouse`, `Runtime`, `Scroll`, `MouseWheel`, `Mouse 1`, `Mouse 2`, `Mouse 3`, `MouseButton3`, `rbxassetid://127900005477571`, `rbxassetid://140199660699461`, `rbxassetid://84550204392976`, `Tap Screen To Block`, `Button Layouts`, `EditButtonLayout`, `VR Parry Sensitivity`, `VR Hand Switch Sensitivity`, `Hide UI During Match`, `GetEnumItems`

### [771] ReplicatedStorage.Controllers.SettingsController.SettingsController
`Script` · bytecode v9 · 787 bytes · 19 constants
- **Key API:** GetAttribute, SetAttribute
- Constants: `debug`, `setmemorycategory`, `Name`, `Start`, `script`, `Parent`, `require`, `Loaded`, `SetAttribute`, `Init`, `GetAttribute`, `GetAttributeChangedSignal`, `Wait`, `pcall`, `task`, `spawn`, `error`, `%*:Init() - %*`, `format`

### [772] ReplicatedStorage.Controllers.SettingsController.SliderNode
`ModuleScript` · bytecode v9 · 6330 bytes · 107 constants
- **Remotes:** Data, Update
- **Services:** Players, ReplicatedStorage, UserInputService, game
- **Key API:** Connect, Disconnect, GetService, WaitForChild, new
- Constants: `Disconnect`, `buttonDown`, `setValue`, `textBox`, `Text`, `DeformatValue`, `stopDrag`, `UserInputType`, `Enum`, `MouseMovement`, `Touch`, `settingInfo`, `TemplateType`, `SubSlide`, `UpdateBarSize`, `MouseButton1`, `Gamepad1`, `InputChanged`, `Connect`, `InputEnded`, `startDrag`, `Default`, `Time Of Day`, `Update`, `InputBegan`, `isSelected`, `selectionInputConn`, `OnTextFocusLost`, `%s`, `gsub`, `max`, `FormatValue`, `setmetatable`, `Client`, `Data`, `WaitReplion`, `dataReplion`, `LocalPlayer`, `PlayerGui`, `WaitForChild`, `playerGui`, `frame`, `SliderBarContainer`, `barContainer`, `Frame`, `Bar`, `bar`, `TextBoxContainer`, `TextBox`, `settingType`, `GetMouse`, `mouse`, `MouseButton1Down`, `QuickButton`, `Activated`, `Icon`, `Image`, `SlashLine`, `Color3`, `fromRGB`, `BackgroundColor3`, `rbxassetid://14986300321`, `Visible`, `SelectionGained`, `SelectionLost`, `FocusLost`, `GetPropertyChangedSignal`, `new`, `string`, `format`, `%02i:%02i`, `tostring`, `(%d+):(%d+)`, `match`, `tonumber`, `X`, `AbsolutePosition`, `AbsoluteSize`, `math`, `clamp`, `UDim2`, `Size`, `floor`, `Settings`, `Get`, `Current`, `KeyCode`, `DPadRight`, `Volume`, `Misc`, `Max`, `DPadLeft`, `game`, `Players`, `GetService`, `require`, `ReplicatedStorage`, `UserInputService`, `Packages`, `Net`, `Replion`, `Common`, `SettingsInfo`, `ClientGameModules`, `GuiHandler`, `__index`

### [773] ReplicatedStorage.Controllers.ShowRoomController
`ModuleScript` · bytecode v9 · 6754 bytes · 128 constants
- **Remotes:** ChangedAfkMode, getAFKStatus, Update
- **Services:** Players, ReplicatedStorage, RunService, StarterGui, TweenService, game, workspace
- **Key API:** Clone, Connect, Destroy, FindFirstChild, Fire, FireServer, GetService, InvokeServer, Once, WaitForChild, new
- Constants: `FeaturesToggle`, `LimitedSwords`, `Value`, `warn`, `ShowRoom %* not found`, `format`, `ShowRooms`, `Template`, `Clone`, `Misc`, `Parent`, `BeforeInit`, `typeof`, `function`, `Instance`, `Trove`, `Info`, `new`, `AfterInit`, `Get`, `ShowRoom`, `IgnoreCamera`, `Enum`, `CameraType`, `Scriptable`, `Custom`, `GetCameraCFrameFor`, `CFrame`, `Character`, `Humanoid`, `FindFirstChildWhichIsA`, `CameraSubject`, `Update`, `GiftingUI`, `IsOpen`, `Close`, `task`, `delay`, `Add`, `Unlock`, `workspace`, `Alive`, `IsDescendantOf`, `ShowRoomOpened`, `Fire`, `_cameraCFrame`, `BeforeShow`, `UI`, `announcer`, `Enabled`, `TouchGui`, `FindFirstChild`, `Hide`, `defer`, `CoreGuiType`, `Chat`, `isTestGame`, `AFKWorld`, `PlayerList`, `isRankedLobbyServer`, `RankedSelection`, `CloseCurrent`, `Utils`, `MinDebuff`, `Priority`, `ADD`, `SetModifierFor`, `Changed`, `Connect`, `OnGuiClose`, `isDuelLobbyServer`, `AncestryChanged`, `Once`, `getAFKStatus`, `InvokeServer`, `_lastAFKStatus`, `ChangedAfkMode`, `FireServer`, `Open`, `Lock`, `IsUICovered`, `Showroom`, `SetTag`, `AfterShow`, `Destroy`, `Battlepass`, `RemoveModifierFor`, `Show`, `ShowRoomClosed`, `script`, `Init`, `require`, `game`, `Players`, `GetService`, `LocalPlayer`, `PlayerScripts`, `WaitForChild`, `ClientLoader`, `ControllerIsolator`, `CreateRequire`, `ReplicatedStorage`, `TweenService`, `RunService`, `StarterGui`, `Packages`, `Signal`, `Replion`, `Shared`, `LimitedSwordEvent`, `Common`, `MarketplaceService`, `Controllers`, `GiftingController`, `HUDController`, `UIStateController`, `ClientGameModules`, `CoreCall`, `GuiHandler`, `SpeedModifiers`, `JumpModifiers`, `Net`, `ServerInfo`, `ShowRoomUtility`, `Remotes`, `PlayerGui`, `CurrentCamera`, `LimitedSwordShowRoom`

### [774] ReplicatedStorage.Controllers.ShowRoomController.ShowRoomController
`Script` · bytecode v9 · 787 bytes · 19 constants
- **Key API:** GetAttribute, SetAttribute
- Constants: `debug`, `setmemorycategory`, `Name`, `Start`, `script`, `Parent`, `require`, `Loaded`, `SetAttribute`, `Init`, `GetAttribute`, `GetAttributeChangedSignal`, `Wait`, `pcall`, `task`, `spawn`, `error`, `%*:Init() - %*`, `format`

### [775] ReplicatedStorage.Controllers.ShowRoomController.ShowRoomUtility
`ModuleScript` · bytecode v9 · 844 bytes · 24 constants
- **Key API:** FindFirstChild, WaitForChild
- Constants: `CFrame`, `Size`, `ViewportSize`, `X`, `Y`, `math`, `min`, `FieldOfView`, `rad`, `tan`, `atan`, `Magnitude`, `sin`, `GetPartFitDistance`, `Camera`, `WaitForChild`, `lookAt`, `Position`, `LookAt`, `FindFirstChild`, `WorldPosition`, `CameraViewport`, `LookVector`, `GetCameraCFrameFor`

### [776] ReplicatedStorage.Controllers.ShowRoomController.ShowRooms
`ModuleScript` · bytecode v9 · 497 bytes · 9 constants
- Constants: `SwordPacks`, `Battlepass`, `AFK`, `Finisher`, `Index`, `SwordAccessory`, `SwordForge`, `require`, `script`

### [777] ReplicatedStorage.Controllers.ShowRoomController.ShowRooms.AFK
`ModuleScript` · bytecode v9 · 3693 bytes · 81 constants
- **Services:** Players, ReplicatedStorage, RunService, TweenService, UserInputService, game, workspace
- **Key API:** Connect, Destroy, GetService, LoadAnimation, Play, SetAttribute, Stop, WaitForChild, new
- Constants: `UserId`, `GetHumanoidDescriptionFromUserId`, `Humanoid`, `ApplyDescription`, `Stop`, `Destroy`, `clearLastEmote`, `ClearAllChildren`, `clearVFX`, `clearCurrentEmote`, `TimePosition`, `Animator`, `LoadAnimation`, `Looped`, `Play`, `Pin`, `GetMarkerReachedSignal`, `Connect`, `GOTO`, `loadAnimation`, `string`, `match`, `Emote`, `AnimationId`, `(%d+)`, `tonumber`, `PassiveRNGEmote`, `SetAttribute`, `type`, `function`, `updateEmote`, `Instance`, `Trove`, `Character`, `FindFirstChildWhichIsA`, `GetAppliedDescription`, `pcall`, `Rig`, `new`, `Folder`, `EmoteVFX_Storage`, `Name`, `Parent`, `Info`, `SetEmote`, `Misc`, `Emotes`, `Emote183`, `AfterInit`, `Camera`, `CFrame`, `Angles`, `BeforeShow`, `game`, `ReplicatedStorage`, `GetService`, `require`, `UserInputService`, `WaitForChild`, `GamepadService`, `TweenService`, `RunService`, `Players`, `Packages`, `Signal`, `Common`, `Utils`, `script`, `ShowRoomUtility`, `Templates`, `ShowRoom3D`, `Shared`, `RNG`, `EmoteTypes`, `Passive`, `LocalPlayer`, `workspace`, `CurrentCamera`, `Template`, `ShowRooms`, `AFK`

### [778] ReplicatedStorage.Controllers.ShowRoomController.ShowRooms.Battlepass
`ModuleScript` · bytecode v9 · 6875 bytes · 112 constants
- **Services:** Players, ReplicatedStorage, RunService, TweenService, UserInputService, game, workspace
- **Key API:** Clone, Connect, Destroy, FindFirstChild, GetService, LoadAnimation, Play, Stop, WaitForChild, new
- Constants: `Parent`, `new`, `Add`, `Trove`, `Object`, `Current`, `createShowRoom`, `CFrame`, `X`, `getShowRoomPosition`, `getBgPosition`, `Humanoid`, `ApplyDescription`, `Stop`, `Destroy`, `Play`, `Length`, `math`, `max`, `task`, `wait`, `TimePosition`, `Type`, `Sword`, `Emote`, `Value`, `GetSword`, `Clone`, `GetPivot`, `PivotTo`, `pcall`, `EquipSwordTo`, `ScaleTo`, `Animator`, `Idle`, `AnimationType`, `SwordType`, `GetAnimations`, `LoadAnimation`, `Parry`, `GrabParry`, `SuccessParry`, `table`, `create`, `Looped`, `spawn`, `Misc`, `Emotes`, `FindFirstChild`, `Pin`, `GetMarkerReachedSignal`, `Connect`, `GOTO`, `GetInstance`, `Instance`, `Folder`, `Physics`, `WeldModelToChar`, `createReward`, `Rendered`, `clear`, `print`, `Failed to find rendered ShowRoom`, `GetCameraCFrameFor`, `Model`, `Bg`, `Free`, `Premium`, `1`, `2`, `Character`, `FindFirstChildWhichIsA`, `GetAppliedDescription`, `ShowRoom`, `NPC`, `GetExtentsSize`, `Extend`, `Info`, `Render`, `AfterInit`, `game`, `ReplicatedStorage`, `GetService`, `require`, `UserInputService`, `WaitForChild`, `GamepadService`, `TweenService`, `RunService`, `Players`, `Packages`, `Common`, `Utils`, `script`, `ShowRoomUtility`, `Templates`, `ShowRoom3D`, `Controllers`, `UI`, `LimitedSwordPacksController`, `ShowRoomController`, `Shared`, `SwordAPI`, `ReplicatedInstances`, `EmoteAccessories`, `Swords`, `LocalPlayer`, `workspace`, `CurrentCamera`, `Template`, `ShowRooms`, `Battlepass`

### [779] ReplicatedStorage.Controllers.ShowRoomController.ShowRooms.Finisher
`ModuleScript` · bytecode v9 · 4959 bytes · 107 constants
- **Services:** Lighting, Players, ReplicatedStorage, RunService, UserInputService, game, workspace
- **Key API:** Connect, Disconnect, FindFirstChild, GetAttribute, GetService, SetAttribute, WaitForChild
- Constants: `AdvanceToNextPageAsync`, `UserId`, `GetFriendsAsync`, `GetCurrentPage`, `table`, `move`, `IsFinished`, `pcall`, `timeout`, `await`, `math`, `random`, `No friend found`, `assert`, `Id`, `GetHumanoidDescriptionFromUserId`, `Humanoid`, `ApplyDescription`, `Misc`, `NoobHumanoidDescription`, `loadFriendFor`, `Thread`, `SafeResume`, `os`, `clock`, `workspace`, `GetServerTimeNow`, `PlayFinisher`, `type`, `Trove`, `Add`, `coroutine`, `running`, `yield`, `DataFinishers`, `task`, `wait`, `Duration`, `GetAttribute`, `Enum`, `CoreGuiType`, `Chat`, `PlayerList`, `LobbySwordName`, `SetAttribute`, `PivotTo`, `xpcall`, `warn`, `Close`, `spawn`, `Instance`, `Character`, `FindFirstChildWhichIsA`, `NPC`, `NPC2`, `Base Sword`, `GiveSwordNPC`, `AddTag`, `GetPivot`, `Info`, `AfterInit`, `Density`, `Disconnect`, `CameraType`, `Scriptable`, `ShowRoom`, `Camera`, `CFrame`, `GetPropertyChangedSignal`, `Connect`, `Changed`, `BeforeShow`, `game`, `ReplicatedStorage`, `GetService`, `require`, `UserInputService`, `WaitForChild`, `GamepadService`, `RunService`, `Lighting`, `Players`, `Packages`, `Promise`, `Signal`, `Common`, `Utils`, `Shared`, `FastUtils`, `script`, `Parent`, `Controllers`, `FinishersController`, `ReplicatedInstances`, `Swords`, `SwordAPI`, `ClientGameModules`, `CoreCall`, `Atmosphere`, `FindFirstChild`, `LocalPlayer`, `CurrentCamera`, `try`, `catch`, `Template`, `ShowRooms`, `Finisher`

### [780] ReplicatedStorage.Controllers.ShowRoomController.ShowRooms.Index
`ModuleScript` · bytecode v9 · 15412 bytes · 203 constants
- **Remotes:** Freeze, ParrySuccessClient
- **Services:** Lighting, Players, ReplicatedStorage, RunService, TweenService, UserInputService, game, workspace
- **Key API:** Clone, Connect, Destroy, Disconnect, FindFirstChild, Fire, GetAttribute, GetChildren, GetService, LoadAnimation, Play, SetAttribute, Stop, WaitForChild, new
- Constants: `math`, `abs`, `exp`, `sign`, `clamp`, `thumbstickCurve`, `Humanoid`, `ApplyDescription`, `HumanoidRootPart`, `Position`, `PlayExplosion`, `Add`, `xpcall`, `warn`, `playExplosion`, `Stop`, `Destroy`, `AnimatedAccessory`, `HasTag`, `RemoveTag`, `Animator`, `FindFirstChildWhichIsA`, `Walk`, `FindFirstChild`, `LoadAnimation`, `Play`, `walk`, `id`, `Instance`, `new`, `Animation`, `AnimationId`, `GetSword`, `AccessoryUnlockable`, `Accessory`, `GetScale`, `EquipSwordTo`, `GetChildren`, `_swordAccessory`, `GetAttribute`, `observeChildren`, `equipSword`, `Remotes`, `ParrySuccessClient`, `SlashEffect`, `SlashName`, `Name`, `Fire`, `parry`, `workspace`, `GetServerTimeNow`, `PassiveRNGEmote`, `SetAttribute`, `Clean`, `playEmote`, `Base Sword`, `Idle`, `AnimationType`, `SwordType`, `GetAnimations`, `renderSword`, `Nothing`, `Sword`, `Parry`, `SuccessParry`, `table`, `create`, `Looped`, `Emote`, `GetInstance`, `HideSword`, `Misc`, `Emotes`, `render`, `Camera%*`, `format`, `CFrame`, `identity`, `getCameraCFrame`, `ShowRoom`, `Info`, `CurrentCamera`, `updateCamera`, `Explosion`, `Dictionary`, `equals`, `Object`, `Trove`, `Character`, `GetAppliedDescription`, `Parent`, `GetPivot`, `GetExtentsSize`, `Clone`, `PivotTo`, `NPC`, `task`, `spawn`, `pcall`, `Right`, `UpdateCamera`, `GetCameraCFrame`, `PreviewClicked`, `SetCamera`, `Render`, `Zoom`, `AfterInit`, `applyDeltaToZoom`, `GetMouseLocation`, `clear`, `UserInputType`, `Enum`, `MouseButton1`, `Touch`, `KeyCode`, `Thumbstick1`, `GamepadCursorEnabled`, `Y`, `MouseWheel`, `Z`, `Thumbstick2`, `X`, `Vector3`, `Vector2`, `floor`, `roundVector2`, `UserInputState`, `Begin`, `Change`, `Magnitude`, `End`, `GetCameraYInvertValue`, `GamepadCameraSensitivity`, `zero`, `MouseSensitivity`, `rad`, `goal`, `update`, `Angles`, `FieldOfView`, `tan`, `Bg`, `ViewportSize`, `Size`, `Density`, `Disconnect`, `defer`, `InputBegan`, `Connect`, `InputChanged`, `InputEnded`, `TouchPinch`, `PostSimulation`, `GetPropertyChangedSignal`, `BeforeShow`, `game`, `ReplicatedStorage`, `GetService`, `require`, `UserInputService`, `WaitForChild`, `GamepadService`, `TweenService`, `RunService`, `Lighting`, `Players`, `Packages`, `Spring`, `Freeze`, `Common`, `Utils`, `script`, `ShowRoomUtility`, `Templates`, `ShowRoom3D`, `Controllers`, `UI`, `LimitedSwordPacksController`, `ShowRoomController`, `EmoteController`, `VFXController`, `Shared`, `SwordAPI`, `ReplicatedInstances`, `EmoteAccessories`, `EmoteVFX`, `Swords`, `RNG`, `EmoteTypes`, `EnableAndEmit`, `Inventory`, `InventoryTypes`, `EmotesShared`, `ServerInfo`, `AnimationProfiles`, `Observers`, `Atmosphere`, `UserSettings`, `GameSettings`, `LocalPlayer`, `Template`, `ShowRooms`, `Index`

### [781] ReplicatedStorage.Controllers.ShowRoomController.ShowRooms.SwordAccessory
`ModuleScript` · bytecode v9 · 1362 bytes · 34 constants
- **Services:** Players, ReplicatedStorage, RunService, TweenService, UserInputService, game
- **Key API:** GetService, WaitForChild
- Constants: `GamepadEnabled`, `EnableGamepadCursor`, `DisableGamepadCursor`, `pcall`, `Trove`, `Add`, `task`, `defer`, `Info`, `ShowRoom`, `BeforeShow`, `game`, `ReplicatedStorage`, `GetService`, `require`, `UserInputService`, `WaitForChild`, `GamepadService`, `TweenService`, `RunService`, `Players`, `Packages`, `script`, `Parent`, `Templates`, `ShowRoom3D`, `Controllers`, `UI`, `LimitedSwordPacksController`, `ShowRoomController`, `Template`, `Misc`, `ShowRooms`, `SwordAccessory`

### [782] ReplicatedStorage.Controllers.ShowRoomController.ShowRooms.SwordForge
`ModuleScript` · bytecode v9 · 18268 bytes · 251 constants
- **Remotes:** Freeze, ParrySuccessClient
- **Services:** Lighting, Players, ReplicatedStorage, RunService, TweenService, UserInputService, game, workspace
- **Key API:** Clone, Connect, Destroy, Disconnect, FindFirstChild, Fire, GetAttribute, GetChildren, GetService, IsA, LoadAnimation, Play, SetAttribute, Stop, WaitForChild, new
- Constants: `math`, `abs`, `exp`, `sign`, `clamp`, `thumbstickCurve`, `Visual`, `Anvil`, `VFX`, `PlayEffects`, `IsPlaying`, `Stop`, `Destroy`, `Clean`, `Instance`, `ShowRoom`, `SwordForgeNPC`, `Humanoid`, `Animator`, `warn`, `No SwordForgeNPC animator found`, `Forging`, `GetAttribute`, `UI`, `SwordForge`, `script`, `Hammer`, `LoadAnimation`, `Hit`, `GetMarkerReachedSignal`, `Connect`, `Add`, `Play`, `ApplyDescription`, `HumanoidRootPart`, `Position`, `PlayExplosion`, `xpcall`, `playExplosion`, `AnimatedAccessory`, `HasTag`, `RemoveTag`, `FindFirstChildWhichIsA`, `Walk`, `FindFirstChild`, `walk`, `id`, `new`, `Animation`, `AnimationId`, `GetSword`, `AccessoryUnlockable`, `Accessory`, `GetScale`, `EquipSwordTo`, `GetChildren`, `_swordAccessory`, `observeChildren`, `equipSword`, `Remotes`, `ParrySuccessClient`, `SlashEffect`, `SlashName`, `Name`, `Fire`, `parry`, `workspace`, `GetServerTimeNow`, `PassiveRNGEmote`, `SetAttribute`, `playEmote`, `Base Sword`, `Idle`, `AnimationType`, `SwordType`, `GetAnimations`, `renderSword`, `setMode`, `Frame`, `BTools`, `GuiButton`, `IsA`, `Icon`, `Color3`, `fromRGB`, `ImageColor3`, `setAction`, `KeyCode`, `Enum`, `Two`, `Move`, `Three`, `Scale`, `Four`, `Rotate`, `L`, `toggleWorld`, `detach`, `Character`, `Nothing`, `sord`, `DELETE_ME`, `_G`, `SWORD_FORGE_SAVE`, `Mesh`, `Anchored`, `Parent`, `Weld`, `Part0`, `Part1`, `CFrame`, `ToObjectSpace`, `C0`, `identity`, `C1`, `Sword`, `GetPivot`, `PivotTo`, `require`, `Drag`, `attach`, `PlayerGui`, `InputBegan`, `Activated`, `Parry`, `SuccessParry`, `table`, `create`, `Looped`, `Emote`, `GetInstance`, `HideSword`, `Misc`, `Emotes`, `render`, `Camera%*`, `format`, `getCameraCFrame`, `Info`, `CurrentCamera`, `updateCamera`, `Explosion`, `Dictionary`, `equals`, `Object`, `Trove`, `GetAppliedDescription`, `GetAttributeChangedSignal`, `GetExtentsSize`, `Clone`, `NPC`, `task`, `spawn`, `pcall`, `Right`, `UpdateCamera`, `GetCameraCFrame`, `PreviewClicked`, `SetCamera`, `Render`, `Zoom`, `AfterInit`, `applyDeltaToZoom`, `GetMouseLocation`, `clear`, `UserInputType`, `MouseButton1`, `Touch`, `Thumbstick1`, `GamepadCursorEnabled`, `Y`, `MouseWheel`, `Z`, `Thumbstick2`, `X`, `Vector3`, `Vector2`, `floor`, `roundVector2`, `UserInputState`, `Begin`, `Change`, `Magnitude`, `End`, `GetCameraYInvertValue`, `GamepadCameraSensitivity`, `zero`, `MouseSensitivity`, `rad`, `goal`, `update`, `Angles`, `FieldOfView`, `tan`, `Bg`, `ViewportSize`, `Size`, `Visible`, `Density`, `Disconnect`, `defer`, `InputChanged`, `InputEnded`, `TouchPinch`, `PostSimulation`, `GetPropertyChangedSignal`, `BeforeShow`, `game`, `ReplicatedStorage`, `GetService`, `UserInputService`, `WaitForChild`, `GamepadService`, `TweenService`, `RunService`, `Lighting`, `Players`, `Packages`, `Spring`, `Freeze`, `Common`, `Utils`, `ShowRoomUtility`, `Templates`, `ShowRoom3D`, `Controllers`, `LimitedSwordPacksController`, `ShowRoomController`, `EmoteController`, `VFXController`, `Shared`, `SwordAPI`, `ReplicatedInstances`, `EmoteAccessories`, `EmoteVFX`, `Swords`, `RNG`, `EmoteTypes`, `EnableAndEmit`, `Inventory`, `InventoryTypes`, `EmotesShared`, `ServerInfo`, `AnimationProfiles`, `Observers`, `Atmosphere`, `UserSettings`, `GameSettings`, `LocalPlayer`, `Template`, `ShowRooms`

### [783] ReplicatedStorage.Controllers.ShowRoomController.ShowRooms.SwordForge.Drag
`ModuleScript` · bytecode v9 · 5287 bytes · 76 constants
- **Services:** Players, ReplicatedStorage, RunService, UserInputService, game, workspace
- **Key API:** Connect, Destroy, Disconnect, GetService, WaitForChild, new
- Constants: `Destroy`, `clear`, `CFrame`, `Vector3`, `FromNormalId`, `new`, `Instance`, `Handles`, `Adornee`, `Enum`, `HandlesStyle`, `Movement`, `Style`, `Faces`, `Color3`, `Parent`, `MouseButton1Down`, `Connect`, `MouseDrag`, `MouseButton1Up`, `createMoveHandle`, `Size`, `Abs`, `X`, `math`, `max`, `Y`, `Z`, `Resize`, `createScaleHandle`, `Position`, `Axis`, `fromAxisAngle`, `Angles`, `Connected`, `Disconnect`, `PreRender`, `NormalId`, `Left`, `Right`, `table`, `insert`, `Top`, `Bottom`, `Front`, `Back`, `ArcHandles`, `fromRGB`, `setMode`, `attach`, `Move`, `Visible`, `Scale`, `Rotate`, `toggleWorld`, `detach`, `game`, `RunService`, `GetService`, `require`, `ReplicatedStorage`, `UserInputService`, `WaitForChild`, `Players`, `LocalPlayer`, `PlayerGui`, `Part`, `_drag_fake_part`, `Name`, `Transparency`, `Anchored`, `CanCollide`, `CanQuery`, `CanTouch`, `workspace`, `CurrentCamera`

### [784] ReplicatedStorage.Controllers.ShowRoomController.ShowRooms.SwordPacks
`ModuleScript` · bytecode v9 · 1882 bytes · 44 constants
- **Services:** Players, ReplicatedStorage, RunService, TweenService, UserInputService, game
- **Key API:** Connect, GetService, WaitForChild
- Constants: `GamepadEnabled`, `EnableGamepadCursor`, `ShowRoom`, `Type`, `SelectColors`, `Rewards`, `Color`, `CurrentlySelectedColor`, `CurrentlyColorTypeForcedShowRoom`, `moveToShowRoom`, `DisableGamepadCursor`, `pcall`, `GetActiveBundles`, `Trove`, `BundleChanged`, `Connect`, `Add`, `task`, `defer`, `Info`, `BeforeShow`, `game`, `ReplicatedStorage`, `GetService`, `require`, `UserInputService`, `WaitForChild`, `GamepadService`, `TweenService`, `RunService`, `Players`, `Packages`, `script`, `Parent`, `Templates`, `ShowRoom3D`, `Controllers`, `UI`, `LimitedSwordPacksController`, `ShowRoomController`, `Template`, `Misc`, `ShowRooms`, `SwordPacks`

### [785] ReplicatedStorage.Controllers.ShowRoomController.ShowRooms.SwordPacks.ShowRooms.Dual Withered Blade
`ModuleScript` · bytecode v9 · 492 bytes · 13 constants
- Constants: `require`, `../Types`, `Sword`, `BeamColor`, `PadColor`, `NeonColor`, `TextColor`, `UIGradient`, `UIStroke`, `script`, `Name`, `Color3`, `fromRGB`

### [786] ReplicatedStorage.Controllers.ShowRoomController.ShowRooms.SwordPacks.ShowRooms.Oni Ghost
`ModuleScript` · bytecode v9 · 492 bytes · 13 constants
- Constants: `require`, `../Types`, `Sword`, `BeamColor`, `PadColor`, `NeonColor`, `TextColor`, `UIGradient`, `UIStroke`, `script`, `Name`, `Color3`, `fromRGB`

### [787] ReplicatedStorage.Controllers.ShowRoomController.ShowRooms.SwordPacks.ShowRooms.Star Wand
`ModuleScript` · bytecode v9 · 492 bytes · 13 constants
- Constants: `require`, `../Types`, `Sword`, `BeamColor`, `PadColor`, `NeonColor`, `TextColor`, `UIGradient`, `UIStroke`, `script`, `Name`, `Color3`, `fromRGB`

### [788] ReplicatedStorage.Controllers.ShowRoomController.ShowRooms.SwordPacks.ShowRooms.Withered Chakram
`ModuleScript` · bytecode v9 · 492 bytes · 13 constants
- Constants: `require`, `../Types`, `Sword`, `BeamColor`, `PadColor`, `NeonColor`, `TextColor`, `UIGradient`, `UIStroke`, `script`, `Name`, `Color3`, `fromRGB`

### [790] ReplicatedStorage.Controllers.ShowRoomController.ShowRooms.Templates.ShowRoom3D
`ModuleScript` · bytecode v9 · 27121 bytes · 324 constants
- **Remotes:** ParrySuccessClient
- **Services:** Players, ReplicatedStorage, RunService, TweenService, UserInputService, game, workspace
- **Key API:** Clone, Connect, Create, Destroy, FindFirstChild, Fire, GetAttribute, GetChildren, GetDescendants, GetService, IsA, LoadAnimation, Once, Play, SetAttribute, Stop, WaitForChild, new
- Constants: `CurrentEmote`, `SetAttribute`, `Play`, `Instance`, `new`, `Folder`, `Add`, `EmoteVFX_Storage`, `Name`, `Parent`, `EmoteScale`, `GetCollection`, `VFX`, `Emote`, `Misc`, `Emotes`, `Animation`, `FX`, `createFromEmoteName`, `AnimationId`, `createAnimationObject`, `CFrame`, `os`, `clock`, `math`, `sin`, `C1`, `Stop`, `Destroy`, `getInstance`, `Swords`, `warn`, `Can't find sword`, `RenderAccessoryOnly`, `GetAttribute`, `GetInstance`, `Main`, `Attachment`, `Clone`, `RenderedSword`, `Sword`, `PivotTo`, `Chroma Blade`, `Chroma Scythe`, `Dual Chroma Set`, `Santa's Greatsword`, `Polar Bear`, `Penguin`, `Sea Turtle`, `Ace`, `GetChildren`, `1`, `Model`, `IsA`, `The Curse`, `sord`, `Torso`, `Part0`, `Angles`, `C0`, `HumanoidRootPart`, `RootPart`, `Part1`, `GetScale`, `ScaleTo`, `IsDual`, `SwordWelds`, `FindFirstChild`, `Black Ninja Katana`, `Red Ninja Katana`, `Green Ninja Katana`, `Blue Ninja Katana`, `Pink Ninja Katana`, `Chroma Ninja Katana`, `Wonderwisp Greatsword`, `Moonflower Greatsword`, `Moonflower Katana`, `Serpent's Greatsword`, `Blossom Katana`, `Hollow Oath Katana`, `Pink Oni Katana`, `Black Oni Katana`, `Blue Oni Katana`, `Purple Oni Katana`, `Red Oni Katana`, `Chroma Oni Katana`, `Gold Vanity Spear`, `Deathwarden Lance`, `Proyection Sorcery Katana`, `Astral Seraph Blade`, `fromOrientation`, `Starlit Halo Wings`, `Shark`, `PostSimulation`, `Connect`, `Serpent`, `Higanbana Katana`, `Regret Blades`, `Red Moon Katana`, `Brutality Affection Bat`, `Wolf Greatsword`, `Gyaru Katana`, `Gravelight`, `Phantom Pact`, `Night Raver`, `Dual Vaporwave Crusher`, `Ornament Crushers`, `Kitty Launcher`, `Snowball Launcher`, `Soulrender Scythe`, `Jolly Scythe Set`, `Venomlight Scythe`, `Ocean Guitar`, `Candycane Sniper`, `Malice Parasol`, `Harmonic Staff`, `Frostbound Lantern`, `The Conjurer`, `Harmonic Fan`, `Cat Paw`, `Shatterflight Bird`, `Desert Claws`, `Aetherial Lance`, `Sakura Parasol`, `Dual Harmonic Set`, `dosdos2`, `Guardian of the Underworld`, `Riftflare Katana`, `Enabled`, `SwordPacksVFX`, `HoloPose`, `AnimationController`, `Animator`, `LoadAnimation`, `AdjustSpeed`, `addSwordToHoloPad`, `AnimatedAccessory`, `HasTag`, `RemoveTag`, `FindFirstChildWhichIsA`, `Walk`, `walk`, `id`, `Humanoid`, `Clean`, `GetSword`, `IgnoreAccessory`, `Emote711`, `GetOrForceEquipSwordTo`, `assert`, `EquippedSword`, `_swordAccessory`, `observeChildren`, `GetPivot`, `addSwordToNPC`, `Info`, `Selected`, `No ShowRoom name found`, `InnerShowRooms`, `No ShowRoom found for`, `NPCS`, `IsShown`, `HoloPads`, `TweenInfo`, `Enum`, `EasingStyle`, `Quint`, `GetCameraCFrameFor`, `Create`, `Completed`, `Once`, `moveToShowRoom`, `IsHovering`, `Light`, `BottomLight`, `Beam`, `Brightness`, `updateHovering`, `Crimson Eclipse`, `Dual Crimson Eclipse`, `GetDescendants`, `ParticleEmitter`, `Rate`, `updateSword`, `GetAttributeChangedSignal`, `task`, `spawn`, `createHoloPad`, `loadAnimation`, `InputStart`, `GetMouseLocation`, `X`, `rad`, `Inverse`, `Position`, `LastSword`, `LastEmote`, `LastIgnoreAccessory`, `TimePosition`, `Looped`, `Pin`, `GetMarkerReachedSignal`, `GOTO`, `loadAnimationObject`, `BillboardGui`, `RankedLabel`, `string`, `upper`, `Text`, `EmoteName`, `Slash`, `SwordAccessories`, `Seed`, `Random`, `NextNumber`, `Physics`, `ResizePart`, `BasePart`, `CanCollide`, `Anchored`, `CanQuery`, `CanTouch`, `Massless`, `Transparency`, `CreateWeld`, `NoEmote`, `Idle`, `AnimationType`, `SwordType`, `GetAnimations`, `IdleAnimation`, `PolarBearEmote`, `Weld`, `Emote710`, `PenguinEmote`, `type`, `table`, `insert`, `Emote_Storage`, `typeof`, `HideSword`, `RigModelToChar`, `SlashName`, `ServerParryCount`, `HasAccessoryEquipped`, `Parry`, `SuccessParry`, `Hitman`, `Fallen Angel`, `Prismatic Odachi`, `SuccessParry%*`, `format`, `Cloud`, `create`, `Remotes`, `ParrySuccessClient`, `Fire`, `coroutine`, `running`, `wait`, `tryUpdateSword`, `FindFirstChildOfClass`, `ApplyDescriptionAsync`, `GetPlayingAnimationTracks`, `Extend`, `identity`, `select`, `ToOrientation`, `Heartbeat`, `createNPC`, `Selection`, `Y`, `ViewportPointToRay`, `Raycast`, `Origin`, `Direction`, `updateSelection`, `UserInputType`, `MouseButton1`, `Touch`, `KeyCode`, `ButtonA`, `ButtonX`, `NPC`, `Trove`, `Character`, `GetAppliedDescription`, `InputBegan`, `InputChanged`, `InputEnded`, `game`, `ReplicatedStorage`, `GetService`, `require`, `UserInputService`, `WaitForChild`, `GamepadService`, `TweenService`, `RunService`, `Players`, `Packages`, `Common`, `Utils`, `script`, `ShowRoomUtility`, `Controllers`, `ShowRoomController`, `Shared`, `ReplicatedInstances`, `EmoteAccessories`, `EmoteVFX`, `SwordAPI`, `EmoteTypes`, `EnableAndEmit`, `AnimationProfiles`, `Observers`, `ReplicatedInstancesUtils`, `EmotesShared`, `LocalPlayer`, `workspace`, `CurrentCamera`, `Vector2`, `Ray`

### [791] ReplicatedStorage.Controllers.SinglePass.SinglePassAnimationController
`ModuleScript` · bytecode v9 · 4795 bytes · 110 constants
- **Remotes:** Data
- **Services:** Players, ReplicatedStorage, RunService, StarterGui, TweenService, game
- **Key API:** Clone, Connect, Create, Destroy, GetChildren, GetService, IsA, OnClientEvent, Play, Stop, WaitForChild, new
- Constants: `SwordTemplate`, `Unique`, `Clone`, `Value`, `LayoutOrder`, `ImageLabel`, `Icon`, `Image`, `NameOfWeapon`, `DisplayName`, `Text`, `Visible`, `Hover`, `HoverImage`, `Parent`, `createTemplate`, `Open`, `Client`, `Data`, `WaitReplion`, `OnClientEvent`, `Connect`, `Start`, `task`, `wait`, `SinglePass`, `Lock`, `UnboxGui`, `MainFrame`, `UDim2`, `fromScale`, `Position`, `TweenInfo`, `new`, `Enum`, `EasingStyle`, `Back`, `Create`, `Play`, `Items`, `Reward`, `Probability`, `Purple`, `Yellow`, `Green`, `getPicker`, `AbsoluteSize`, `X`, `AbsolutePosition`, `Sine`, `fromOffset`, `Misc`, `spinwheel`, `TimePosition`, `Completed`, `Wait`, `Destroy`, `Stop`, `reward`, `string`, `format`, `Rolled: %s`, `EasingDirection`, `In`, `Unlock`, `GetChildren`, `GuiObject`, `IsA`, `require`, `game`, `Players`, `GetService`, `LocalPlayer`, `PlayerScripts`, `WaitForChild`, `ClientLoader`, `ControllerIsolator`, `CreateRequire`, `script`, `RunService`, `ReplicatedStorage`, `StarterGui`, `TweenService`, `Random`, `PlayerGui`, `Packages`, `Replion`, `Signal`, `ClientGameModules`, `GuiHandler`, `Net`, `Shared`, `SinglePassCrate`, `WeightRandom`, `Common`, `RewardInfo`, `rbxassetid://93776847894210`, `rbxassetid://78049756345053`, `rbxassetid://76646398204401`, `rbxassetid://109871120647836`, `rbxassetid://85495068885632`, `rbxassetid://129630194296730`, `OpenSinglePassCrate`, `RemoteEvent`, `WeaponsClipping`, `Scroller`, `Mover`, `Unlocked`, `Fade`

### [792] ReplicatedStorage.Controllers.SinglePass.SinglePassBounty
`ModuleScript` · bytecode v9 · 2407 bytes · 59 constants
- **Remotes:** Data, RoundEnded
- **Services:** Players, ReplicatedStorage, game
- **Key API:** Clone, Connect, FindFirstChild, GetService, OnClientEvent, WaitForChild, new
- Constants: `task`, `wait`, `Clean`, `Client`, `Data`, `WaitReplion`, `Remotes`, `RoundEnded`, `OnClientEvent`, `Connect`, `SinglePass.Bounty`, `UpdateBounty`, `OnChange`, `GetExpect`, `Start`, `bountyVisual`, `drawBountyOverhead`, `Bounty`, `Username`, `NO TARGET`, `Text`, `ProfilePicture`, `Headshot`, `Color3`, `fromRGB`, `ImageColor3`, `rbxassetid://18444806692`, `Image`, `resetBountyVisual`, `SinglePass`, `Interaction`, `Get`, `GetPlayerByUserId`, `DisplayName`, `rbxthumb://type=AvatarHeadShot&id=%*&w=150&h=150`, `format`, `Character`, `Head`, `FindFirstChild`, `script`, `BountyDisplay`, `Clone`, `Parent`, `Add`, `game`, `ReplicatedStorage`, `GetService`, `Players`, `require`, `Packages`, `Replion`, `Trove`, `LocalPlayer`, `PlayerGui`, `WaitForChild`, `MainFrame`, `Main`, `Pages`, `new`

### [793] ReplicatedStorage.Controllers.SinglePass.SinglePassController
`ModuleScript` · bytecode v9 · 5124 bytes · 106 constants
- **Remotes:** Data
- **Services:** Players, ReplicatedStorage, game
- **Key API:** Connect, FindFirstChild, Fire, GetChildren, GetService, Invoke, IsA, WaitForChild, new
- Constants: `SinglePass`, `Close`, `Active`, `Inactive`, `HoverImage`, `Image`, `Odds`, `Visible`, `IsOpen`, `SetPage`, `YouContributed`, `Label`, `You contributed: %*`, `ValueConvertor`, `AddCommas`, `format`, `Text`, `AmountInput`, `InputBox`, `TextBox`, `tonumber`, `CNYEvent_ContributeToMilestone`, `Invoke`, `TopContributorPrizes`, `TopContributors`, `SideBtns`, `Currency`, `List1`, `Amount`, `Loaded`, `Get`, `Values`, `GlobalNumberKey`, `ContributedGlobally`, `TOTAL CONTRIBUTED GLOBALLY: %*`, `ShrinkNumber`, `???`, `updateGlobalNumbers`, `EventEnded`, `MouseButton1Click`, `Connect`, `ipairs`, `GetChildren`, `ImageButton`, `IsA`, `Name`, `FindFirstChild`, `OnGuiOpen`, `OnGuiClose`, `Data`, `WaitReplion`, `Headshot`, `rbxthumb://type=AvatarHeadShot&id=%*&w=100&h=100`, `UserId`, `observeReplionPath`, `CNYEvent.TotalContributed`, `Contribute`, `Activated`, `ViewRanking`, `Back`, `CNYEvent.Lanterns`, `Page`, `Milestone`, `GlobalNumbers`, `OnChange`, `task`, `spawn`, `Thread`, `Every`, `Start`, `Fire`, `require`, `game`, `Players`, `GetService`, `LocalPlayer`, `PlayerScripts`, `WaitForChild`, `ClientLoader`, `ControllerIsolator`, `CreateRequire`, `script`, `ReplicatedStorage`, `Packages`, `Net`, `Signal`, `Shared`, `CNYEvent`, `CNYEventItemData`, `ClientGameModules`, `GuiHandler`, `ReplionUtils`, `Replion`, `Client`, `Common`, `Utils`, `PlayerGui`, `MainFrame`, `Main`, `Pages`, `rbxassetid://84751211463829`, `rbxassetid://89617647046839`, `rbxassetid://88952034919639`, `rbxassetid://127132942458152`, `new`, `PageChanged`

### [794] ReplicatedStorage.Controllers.SinglePass.SinglePassController.SinglePassController
`Script` · bytecode v9 · 787 bytes · 19 constants
- **Key API:** GetAttribute, SetAttribute
- Constants: `debug`, `setmemorycategory`, `Name`, `Start`, `script`, `Parent`, `require`, `Loaded`, `SetAttribute`, `Init`, `GetAttribute`, `GetAttributeChangedSignal`, `Wait`, `pcall`, `task`, `spawn`, `error`, `%*:Init() - %*`, `format`

### [795] ReplicatedStorage.Controllers.SinglePass.SinglePassCrateController
`ModuleScript` · bytecode v9 · 4936 bytes · 116 constants
- **Remotes:** Data
- **Services:** Players, ReplicatedStorage, RunService, StarterGui, TweenService, game
- **Key API:** Clone, Connect, Create, Destroy, GetChildren, GetService, IsA, OnClientEvent, Play, Stop, WaitForChild, new
- Constants: `SwordTemplate`, `Unique`, `Clone`, `Value`, `ImageLabel`, `Icon`, `Image`, `NameOfWeapon`, `DisplayName`, `Text`, `Hover`, `HoverImage`, `UIStroke`, `Color`, `Visible`, `LayoutOrder`, `Parent`, `createTemplate`, `Open`, `Client`, `Data`, `WaitReplion`, `OnClientEvent`, `Connect`, `Start`, `task`, `wait`, `SinglePass`, `Lock`, `UnboxGui`, `MainFrame`, `UDim2`, `fromScale`, `Position`, `TweenInfo`, `new`, `Enum`, `EasingStyle`, `Back`, `Create`, `Play`, `Items`, `Reward`, `Probability`, `Purple`, `Yellow`, `Green`, `getPicker`, `BrightColor`, `BackgroundColor3`, `Top`, `Bottom`, `NextNumber`, `Sine`, `Misc`, `spinwheel`, `TimePosition`, `Completed`, `Wait`, `Destroy`, `Stop`, `reward`, `string`, `format`, `Rolled: %s`, `EasingDirection`, `In`, `Unlock`, `GetChildren`, `GuiObject`, `IsA`, `require`, `game`, `Players`, `GetService`, `LocalPlayer`, `PlayerScripts`, `WaitForChild`, `ClientLoader`, `ControllerIsolator`, `CreateRequire`, `script`, `RunService`, `ReplicatedStorage`, `StarterGui`, `TweenService`, `Random`, `PlayerGui`, `Packages`, `Replion`, `Signal`, `ClientGameModules`, `GuiHandler`, `Net`, `Shared`, `CNYEvent`, `CNYEventCrate`, `WeightRandom`, `Common`, `RewardInfo`, `rbxassetid://18661160677`, `rbxassetid://18661241239`, `Color3`, `fromRGB`, `rbxassetid://18661165809`, `rbxassetid://18661237514`, `rbxassetid://18661163512`, `rbxassetid://18661242616`, `OpenSummerCrate`, `RemoteEvent`, `WeaponsClipping`, `Scroller`, `Mover`, `Unlocked`, `UnlockedBG`

### [796] ReplicatedStorage.Controllers.SinglePass.SinglePassCurrencyPurchaseController
`ModuleScript` · bytecode v9 · 2363 bytes · 59 constants
- **Services:** Players, ReplicatedStorage, game
- **Key API:** Connect, GetService, WaitForChild
- Constants: `Visible`, `Value`, `Buy`, `Cost`, ` %*`, `ValueConvertor`, `PriceInRobux`, `AddCommas`, `format`, `Text`, `???`, `ProductId`, `Enum`, `InfoType`, `Product`, `PromptPurchase`, `MainFrame`, `Main`, `SideBtns`, `Currency`, `Add`, `Activated`, `Connect`, `Close`, `LanternProducts`, `table`, `insert`, `sort`, `tostring`, `Amount`, `GetProductInfoAsync`, `andThen`, `catch`, `Start`, `require`, `game`, `Players`, `GetService`, `LocalPlayer`, `PlayerScripts`, `WaitForChild`, `ClientLoader`, `ControllerIsolator`, `CreateRequire`, `script`, `ReplicatedStorage`, `Common`, `MarketplaceService`, `Shared`, `CNYEvent`, `CNYEventItemData`, `Utils`, `Controllers`, `Trading`, `TradeTokensController`, `PlayerGui`, `SinglePass`, `Pages`, `TurkeyCoins`

### [797] ReplicatedStorage.Controllers.SinglePass.SinglePassDailyRewardsController
`ModuleScript` · bytecode v9 · 5650 bytes · 120 constants
- **Remotes:** Data
- **Services:** CollectionService, Players, ReplicatedStorage, SoundService, game
- **Key API:** Clone, Connect, Destroy, Disconnect, GetChildren, GetService, InvokeServer, IsA, Play, WaitForChild
- Constants: `CNYEvent.ExclusiveDailyRewardBundle`, `Get`, `Disconnect`, `_G`, `SendNotification`, `You already purchased this!`, `Enum`, `InfoType`, `Product`, `PromptPurchase`, `ipairs`, `Free`, `Claim`, `Visible`, `position`, `premium`, `table`, `insert`, `Premium`, `InvokeServer`, `SFX`, `LTMSpin_ClaimSpins`, `Play`, `task`, `wait`, `List`, `GetChildren`, `GuiObject`, `IsA`, `Destroy`, `Client`, `Data`, `WaitReplion`, `UpdateAllRewardTiles`, `OnChange`, `CNYEvent.ClaimedDailyRewards`, `CNYEvent.DailyLoginStreak`, `BottomButtons`, `UnlockButton`, `Activated`, `Connect`, `Label`, `DevProduct`, `Unlock :robux:%s`, `ClaimAllButton`, `Fade`, `TextLabel`, `Get +%*`, `ExclusiveCurrencyReward`, `AddCommas`, `format`, `Text`, `Start`, `Exclusive`, `Clone`, `LayoutOrder`, `Day`, `Day %*`, `Reward`, `Vector`, `Icon`, `Image`, `Amount`, `DisplayName`, `ExclusiveReward`, `Parent`, `Claimed`, `LockIcon`, `UpdateRewardTile`, `LeftReward`, `RewardLabel`, `UpdateFinalReward`, `CNYEvent`, `DailyLoginStreak`, `ClaimedDailyRewards`, `ExclusiveDailyRewardBundle`, `RewardsList`, `PremiumPass`, `LockedCover`, `require`, `game`, `Players`, `GetService`, `LocalPlayer`, `PlayerScripts`, `WaitForChild`, `ClientLoader`, `ControllerIsolator`, `CreateRequire`, `script`, `CollectionService`, `ReplicatedStorage`, `SoundService`, `Packages`, `Net`, `Replion`, `Common`, `Utils`, `Utilities`, `Thread`, `ValueConvertor`, `Shared`, `CNYEventItemData`, `MarketplaceService`, `ClientGameModules`, `CreatePriceLabel`, `Controllers`, `Trading`, `TradeTokensController`, `PlayerGui`, `DailyRewards`, `CNYEvent_ClaimDailyLogin`, `RemoteFunction`, `SinglePass`, `MainFrame`, `Main`, `Pages`, `Frame`, `RewardTemplate`

### [798] ReplicatedStorage.Controllers.SinglePass.SinglePassGoalsController
`ModuleScript` · bytecode v9 · 4255 bytes · 95 constants
- **Remotes:** Data
- **Services:** Players, ReplicatedStorage, game
- **Key API:** Clone, Connect, GetService, InvokeServer, Play, WaitForChild
- Constants: `GetMilestoneXP`, `CNYEvent.ClaimedMilestones`, `Get`, `Loaded`, `Values`, `GlobalNumberKey`, `CNYEvent.TotalContributed`, `Global`, `math`, `clamp`, `Local`, `ProgressBar`, `Fill`, `UDim2`, `fromScale`, `Size`, `Visible`, `Label`, `ValueConvertor`, `ShrinkNumber`, `%*/%*`, `format`, `Text`, `Locked`, `Claimed`, `Claim`, `Milestones`, `ContributeInfo`, `Amount`, `AddCommas`, `updateTile`, `InvokeServer`, `Misc`, `error`, `Play`, `Client`, `Data`, `WaitReplion`, `GlobalNumbers`, `Clone`, `Reward`, `DisplayName`, `Vector`, `Icon`, `Icons`, `DEFAULT_MISSING`, `GetIcon`, `Image`, `OnChange`, `FFlag`, `task`, `spawn`, `Rewards`, `Parent`, `Activated`, `Connect`, `Start`, `require`, `game`, `Players`, `GetService`, `LocalPlayer`, `PlayerScripts`, `WaitForChild`, `ClientLoader`, `ControllerIsolator`, `CreateRequire`, `script`, `ReplicatedStorage`, `Packages`, `Replion`, `Trove`, `Net`, `Common`, `Utils`, `Shared`, `FastUtils`, `Utilities`, `RewardInfo`, `NewQuests`, `Quests`, `QuestUtility`, `CNYEvent`, `CNYEventItemData`, `CNYEvent_ClaimMilestone`, `RemoteFunction`, `PlayerGui`, `SinglePass`, `MainFrame`, `Main`, `Pages`, `Milestone`, `UIListLayout`, `Template`

### [799] ReplicatedStorage.Controllers.SinglePass.SinglePassLeaderboard
`ModuleScript` · bytecode v9 · 3375 bytes · 80 constants
- **Remotes:** Data
- **Services:** Players, ReplicatedStorage, game
- **Key API:** Clone, Connect, FindFirstChild, GetService, WaitForChild, new
- Constants: `Enabled`, `Visible`, `isLeaderboardVisible`, `task`, `spawn`, `UpdateLeaderboard`, `requestUpdate`, `Client`, `Data`, `WaitReplion`, `SinglePassLeaderboard`, `ipairs`, `Rewards`, `Item%*`, `format`, `Holder`, `FindFirstChild`, `Vector`, `Icon`, `Image`, `Leaderboard`, `OnChange`, `GetPropertyChangedSignal`, `Connect`, `Start`, `Username`, `PlayerUsername1`, `Text`, `Clean`, `GetExpect`, `relieve`, `Clone`, `ProfilePicture`, `Placement`, `#%*`, `Item3`, `Item2`, `Item1`, `Headshot`, `rbxthumb://type=AvatarHeadShot&id=%*&w=100&h=100`, `UserId`, `math`, `abs`, `KillsCounter`, `Kills`, `AddCommas`, `[Loading...]`, `GetDisplayName`, `AddPromise`, `andThen`, `PlayerUsername2`, `@%*`, `Name`, `ScrollingFrame`, `Parent`, `game`, `ReplicatedStorage`, `GetService`, `Players`, `require`, `Packages`, `Replion`, `Trove`, `Reliever`, `Shared`, `SinglePass`, `Common`, `Utils`, `Utilities`, `ValueConvertor`, `PlayerUtility`, `LocalPlayer`, `PlayerGui`, `WaitForChild`, `MainFrame`, `Main`, `Pages`, `Template`, `new`

### [800] ReplicatedStorage.Controllers.SinglePass.SinglePassQuestsController
`ModuleScript` · bytecode v9 · 3836 bytes · 92 constants
- **Remotes:** Data
- **Services:** CollectionService, Players, ReplicatedStorage, game
- **Key API:** Clone, Connect, Disconnect, GetService, InvokeServer, WaitForChild
- Constants: `CNYEvent`, `Get`, `Quests`, `QuestTier`, `OnQuestsChanged`, `Daily`, `Main`, `onQuestChanged`, `Client`, `Data`, `WaitReplion`, `CNYEvent.Quests.Main.Daily.Quests`, `OnChange`, `CNYEvent.Quests.Main.Daily`, `CNYEvent.Quests.Main`, `CNYEvent.QuestTier`, `CNYEvent.Quests.XP`, `CNYEvent.Lanterns`, `Start`, `RedeemQuestsType`, `QuestId`, `InvokeServer`, `Connected`, `Disconnect`, `GetQuestData`, `Arguments`, `value`, `typeof`, `function`, `%*_%*`, `format`, `Clone`, `Title`, `DisplayName`, `Text`, `Reward`, `+%*`, `Check`, `Redeemed`, `Visible`, `Claim`, `MouseButton1Click`, `Connect`, `QuestList`, `Parent`, `Progress`, `math`, `clamp`, `Claimed`, `Amount`, `Progress: %*/%*`, `floor`, `Fill`, `UDim2`, `fromScale`, `Size`, `LayoutOrder`, `UpdateQuestTile`, `ipairs`, `require`, `game`, `Players`, `GetService`, `LocalPlayer`, `PlayerScripts`, `WaitForChild`, `ClientLoader`, `ControllerIsolator`, `CreateRequire`, `script`, `CollectionService`, `ReplicatedStorage`, `Packages`, `Net`, `Signal`, `Replion`, `Common`, `Utils`, `Utilities`, `Thread`, `ValueConvertor`, `Shared`, `NewQuests`, `QuestUtility`, `CNYEventItemData`, `ServerInfo`, `PlayerGui`, `SinglePass`, `MainFrame`, `Pages`, `UIListLayout`, `QuestTemplate`

### [801] ReplicatedStorage.Controllers.SinglePass.SinglePassShopController
`ModuleScript` · bytecode v9 · 5080 bytes · 115 constants
- **Remotes:** Data
- **Services:** Players, ReplicatedStorage, game
- **Key API:** Clone, Connect, GetService, InvokeServer, Play, WaitForChild
- Constants: `Odds`, `Visible`, `CNYEvent.Lanterns`, `Get`, `Cost`, `Sounds`, `error`, `Play`, `You don't have enough Lanterns!`, `SendNotification`, `InvokeServer`, `An unexpected error has occured.`, `Purchase`, `Client`, `Data`, `WaitReplion`, `Close`, `Activated`, `Connect`, `ItemShop`, `Clone`, `Name`, `CustomReward`, `OddsButton`, `Title`, `UDim2`, `fromScale`, `Size`, `LayoutOrder`, `CustomDisplayName`, `Reward`, `typeof`, `table`, `DisplayName`, `Text`, `Vector`, `CustomImage`, `Icon`, `Image`, `Buy`, `ValueConvertor`, `AddCommas`, `ItemType`, `Value`, `FindItems`, `Parent`, `insert`, `Explosion`, `InventoryChanged`, `OnChange`, `Sword`, `Emote`, `SetOdds`, `Start`, `ipairs`, `Claimed`, `Items`, `GetTier`, `Probability`, `Percentage`, `%*%%`, `format`, `TextColor3`, `UIStroke`, `Stroke`, `Color`, `Label`, `List`, `SecretTier`, `HighTier`, `MidTier`, `LowTier`, `require`, `game`, `Players`, `GetService`, `LocalPlayer`, `PlayerScripts`, `WaitForChild`, `ClientLoader`, `ControllerIsolator`, `CreateRequire`, `script`, `ReplicatedStorage`, `Packages`, `Net`, `Signal`, `ClientGameModules`, `GuiHandler`, `Common`, `Utils`, `RewardInfo`, `Shared`, `Inventory`, `SinglePass`, `SinglePassRemotes`, `Replion`, `Controllers`, `NotificationController`, `CNYEvent`, `CNYEventItemData`, `CNYEventCrate`, `PlayerGui`, `CNYEvent_PurchaseShopItem`, `RemoteFunction`, `Color3`, `fromRGB`, `MainFrame`, `Main`, `Pages`, `Shop`, `ShopTemplate`, `UIGridLayout`, `OddTemplate`

### [802] ReplicatedStorage.Controllers.SinglePass.SinglePassTopPrizesController
`ModuleScript` · bytecode v9 · 7316 bytes · 128 constants
- **Remotes:** Data
- **Services:** Players, ReplicatedStorage, UserInputService, game, workspace
- **Key API:** Clone, Connect, FindFirstChild, FireServer, GetService, Invoke, WaitForChild
- Constants: `workspace`, `GetServerTimeNow`, `DateTime`, `fromUnixTimestamp`, `YYYYMMDD`, `en-us`, `FormatUniversalTime`, `getToday`, `CNYEvent`, `DailyRewards`, `LeaderboardId`, `warn`, `Invalid DailyLeaderboards for CNYEvent %*}`, `format`, `Rank`, `getRankReward`, `Data`, `DailyLeaderboard`, `Reward%*`, `FindFirstChild`, `Rewards`, `SeasonPassData`, `Season`, `Claimed`, `ClaimButton`, `Visible`, `tostring`, `UpdateRewards`, `Headshot`, `userId`, `Enum`, `ThumbnailType`, `HeadShot`, `ThumbnailSize`, `Size150x150`, `GetUserThumbnailAsync`, `Image`, `DailyLeaderboard-CNYEvent`, `WaitReplion`, `Leaderboard`, `GetExpect`, `Rank%*`, `UserId`, `LayoutOrder`, `Username`, `username`, `Text`, `Points`, `ValueConvertor`, `points`, `AddCommas`, `task`, `spawn`, `UpdateLeaderboard`, `SetDailyLeaderboardReplication`, `RemoteEvent`, `FireServer`, `ClaimDailyLeaderboardReward`, `Invoke`, `Enabled`, `print`, `A`, `PreviewReward`, `SinglePass`, `IsOpen`, `Name`, `OnGuiOpen`, `OnGuiClose`, `Vector`, `Icon`, `ItemName`, `DisplayName`, `Claim`, `Activated`, `Connect`, `CanPreview`, `Inspect`, `DailyLeaderboards.CNYEvent`, `OnDescendantChange`, `rbxassetid://0`, `upper`, `Template`, `Parent`, `Clone`, `Placement`, `#%*`, `OnChange`, `WindowFocused`, `WindowFocusReleased`, `Start`, `require`, `game`, `Players`, `GetService`, `LocalPlayer`, `PlayerScripts`, `WaitForChild`, `ClientLoader`, `ControllerIsolator`, `CreateRequire`, `script`, `ReplicatedStorage`, `UserInputService`, `ClientGameModules`, `GuiHandler`, `Shared`, `DailyLeaderboards`, `Common`, `Utils`, `Packages`, `Net`, `FFlagClient`, `Replion`, `Controllers`, `Trading`, `IndexController`, `Battlepass`, `BattlepassViewController`, `@game/ReplicatedStorage/Shared/InfiniteBattlepass/InfiniteBattlepassData`, `PlayerGui`, `Client`, `MainFrame`, `Main`, `Pages`, `TopContributorPrizes`, `TopContributors`, `ScrollingFrame`

### [803] ReplicatedStorage.Controllers.SquadRoyale.SquadRoyaleInviteController
`ModuleScript` · bytecode v9 · 9851 bytes · 139 constants
- **Remotes:** Freeze
- **Services:** Players, ReplicatedStorage, RunService, UserInputService, game
- **Key API:** Clone, Connect, Destroy, Disconnect, FindFirstChild, FireServer, GetAttribute, GetChildren, GetPlayers, GetService, IsA, OnClientEvent, Once, Play, WaitForChild
- Constants: `GetChildren`, `ImageButton`, `IsA`, `PlayerName`, `FindFirstChild`, `DisplayName`, `string`, `find`, `lower`, `Text`, `Visible`, `updateSearchResults`, `Disconnect`, `PlayerRemoving`, `Connect`, `Invite`, `%* invited you to a Squad Royale party!`, `Name`, `format`, `onPartyInvite`, `IsFocused`, `InSquadRoyaleInvite`, `GetAttribute`, `%* is already in a party!`, `SendNotification`, `Misc`, `error`, `Play`, `FireServer`, `UserId`, `tostring`, `UIListLayout`, `Player`, `Clone`, `@%*`, `GetAttributeChangedSignal`, `Activated`, `Parent`, `createPlayerCard`, `Member`, `%* 👑`, `PlayerIcon`, `rbxthumb://type=AvatarHeadShot&id=%*&w=60&h=60`, `Image`, `RemovePlayerButton`, `LayoutOrder`, `UDim2`, `fromScale`, `Position`, `Size`, `updatePartyMembers`, `Destroying`, `Once`, `createPartyMemberCardInList`, `PlayerList`, `List`, `PlayerImage`, `rbxthumb://type=AvatarHeadShot&id=%*&w=100&h=100`, `Kick`, `Owner`, `createPartyMemberCard`, `updatePartyMemberCard`, `Destroy`, `removePartyMemberCard`, `Parties`, `Get`, `Members`, `tonumber`, `GetPlayerByUserId`, `Dictionary`, `count`, `Add_%*`, `GuiObject`, `Add_%d*`, `Buttons`, `Leave`, `Autofill`, `SquadRoyaleAutofill`, `rbxassetid://75616120281849`, `rbxassetid://134300140675607`, `Open`, `Close`, `math`, `max`, `Enabled`, `isLTMServer`, `Client`, `SquadRoyaleParties`, `WaitReplion`, `CloseButton`, `ReadyButton`, `DeclineButton`, `OnClientEvent`, `Add`, `task`, `spawn`, `OnChange`, `GetPropertyChangedSignal`, `GetPlayers`, `PlayerAdded`, `PostSimulation`, `Start`, `require`, `game`, `Players`, `GetService`, `LocalPlayer`, `PlayerScripts`, `WaitForChild`, `ClientLoader`, `ControllerIsolator`, `CreateRequire`, `script`, `ReplicatedStorage`, `UserInputService`, `RunService`, `ServerInfo`, `Packages`, `Net`, `Freeze`, `Replion`, `ClientGameModules`, `GuiHandler`, `Controllers`, `NotificationController`, `SquadRoyaleInvite`, `RemoteEvent`, `SquadRoyaleInviteAccept`, `SquadRoyaleInviteLeave`, `SquadRoyaleInviteReady`, `SetSquadRoyaleAutofill`, `PlayerGui`, `Main`, `SquadRoyaleInvitePrompt`, `SquadRoyaleInviteList`, `SearchBar`, `SearchBox`, `TeammatesPanel`, `Template`

### [804] ReplicatedStorage.Controllers.StPatricksDayEventController
`ModuleScript` · bytecode v9 · 5506 bytes · 119 constants
- **Remotes:** Data, Update
- **Services:** Players, ReplicatedStorage, RunService, game, workspace
- **Key API:** Connect, Disconnect, GetChildren, GetService, IsA, WaitForChild
- Constants: `IsDataReady`, `StPatricksDayEventEndTime`, `GetKey`, `GetEndTime`, `workspace`, `GetServerTimeNow`, `GetRemaining`, `game`, `PlaceId`, `Default`, `MobileServers`, `IsActive`, `Client`, `Data`, `GetReplion`, `StPatricksDayEvent.HasLuck`, `Get`, `HasLuck`, `Loaded`, `StPatricksDayEvent`, `IsOpen`, `StPatricksEventGlobalMilestones`, `StPatricksEventLocalMilestones`, `type`, `table`, `Values`, `StPatricksDayEventClovers_%*`, `VERSION`, `format`, `StPatricksDayEvent.Clover`, `Progression`, `Bar`, `Items`, `GetChildren`, `GuiObject`, `IsA`, `Name`, `tonumber`, `number`, `Info`, `Visible`, `Label`, `Contribute 💥 %*`, `ValueConvertor`, `AddCommas`, `Text`, `ShrinkNumber`, `Holder`, `Lock`, `Check`, `StPatricksDayEvent.Rewards`, `Find`, `math`, `min`, `UDim2`, `fromScale`, `Size`, `X`, `Scale`, `max`, `Position`, `YouContributed`, `TextLabel`, `You Contributed: 💥 %*`, `Update`, `Close`, `update`, `Rotation`, `Loading`, `Disconnect`, `WaitReplion`, `GlobalNumbers`, `Activated`, `Connect`, `OnGuiOpen`, `OnChange`, `Thread`, `Every`, `task`, `spawn`, `2`, `Vector`, `createSwordReward`, `Viridian Edge`, `AddFromRewardInfo`, `RadialBar`, `Top`, `PostSimulation`, `Start`, `require`, `Players`, `GetService`, `LocalPlayer`, `PlayerScripts`, `WaitForChild`, `ClientLoader`, `ControllerIsolator`, `CreateRequire`, `script`, `ReplicatedStorage`, `RunService`, `Shared`, `UniverseIds`, `Common`, `RewardInfo`, `Packages`, `Replion`, `Trove`, `Utils`, `Net`, `ClientGameModules`, `GuiHandler`, `FFlagClient`, `Controllers`, `HoverInfoController`, `StPatricksDayEventData`, `PlayerGui`, `Frame`, `Fill`

### [805] ReplicatedStorage.Controllers.SubscriptionController
`ModuleScript` · bytecode v9 · 659 bytes · 17 constants
- **Services:** Players, ReplicatedStorage, game
- **Key API:** GetService, WaitForChild
- Constants: `Init`, `Start`, `require`, `game`, `Players`, `GetService`, `LocalPlayer`, `PlayerScripts`, `WaitForChild`, `ClientLoader`, `ControllerIsolator`, `CreateRequire`, `script`, `ReplicatedStorage`, `Packages`, `Replion`, `Net`

### [806] ReplicatedStorage.Controllers.SwordForgeController
`ModuleScript` · bytecode v9 · 6426 bytes · 124 constants
- **Services:** Players, ReplicatedStorage, RunService, game, workspace
- **Key API:** Clone, Connect, Disconnect, GetAttribute, GetService, InvokeServer, SetAttribute, WaitForChild, new
- Constants: `Header`, `Title`, `Describe the sword you want to forge`, `Text`, `PlaceholderText`, `Active`, `Input`, `Visible`, `BTools`, `LowerButtons`, `CloseButton`, `Forging`, `SetAttribute`, `_resetUI`, `LoadGeneratedMeshAsync`, `STUDIO`, `script`, `Test`, `Clone`, `pcall`, `warn`, `Failed to load generated MeshId for %*`, `format`, `CreateMesh`, `Failed to forge sword!`, `SendNotification`, `GeneratedMesh`, `Name`, `Anchored`, `CanCollide`, `CanQuery`, `CanTouch`, `workspace`, `Parent`, `CurrentCamera`, `CFrame`, `new`, `PivotTo`, `SwordForge`, `Get`, `SwordForge showroom not found`, `assert`, `Info`, `Render`, `Sword`, `Mesh`, `Adjust the grip of your sword`, `LoadSword`, `_G`, `SWORD_FORGE_SAVE`, `UI`, `Open`, `Nothing`, `Close`, `Your sword is already being forged, check back in a few seconds!`, `Forging...`, `Check back soon for your finished sword!`, `task`, `wait`, `InvokeServer`, `print`, `Forge success:`, `Your sword has been forged!`, `Moderation failed`, `Your sword did not pass moderation. Please try again.`, `WindowName`, `GetAttribute`, `GetPlayerFromCharacter`, `_currentGui`, `_lockId`, `tick`, `IsOpen`, `onTouch`, `Hitbox`, `WaitForChild`, `Touched`, `Connect`, `Disconnect`, `OnGuiClose`, `spawn`, `Activated`, `isTestGame`, `OnGuiOpen`, `Forge`, `Confirm`, `Clear`, `observeTagNoAncestry`, `SwordForgeNPC`, `Start`, `require`, `game`, `Players`, `GetService`, `LocalPlayer`, `PlayerScripts`, `ClientLoader`, `ControllerIsolator`, `CreateRequire`, `GenerationService`, `ReplicatedStorage`, `RunService`, `Common`, `Utils`, `Packages`, `Replion`, `Net`, `Observers`, `ClientGameModules`, `GuiHandler`, `Controllers`, `ShowRoomController`, `NotificationController`, `ServerInfo`, `HUDController`, `SwordForge/Request`, `RemoteFunction`, `SwordForge/UpdateStatus`, `RemoteEvent`, `IsStudio`, `PlayerGui`, `Frame`, `Textbox`, `TextBox`

### [807] ReplicatedStorage.Controllers.SwordsController
`ModuleScript` · bytecode v9 · 25821 bytes · 327 constants
- **Remotes:** Data, FireSwordInfo, M1Stop, NoobParryHappened, ParryAttempt, ParryButtonPress, ParrySuccess
- **Services:** CollectionService, Debris, Players, ReplicatedStorage, RunService, StarterGui, TweenService, UserInputService, game, workspace
- **Key API:** Clone, Connect, Create, Destroy, Disconnect, FindFirstChild, Fire, FireServer, GetAttribute, GetChildren, GetDescendants, GetService, IsA, LoadAnimation, OnClientEvent, Play, SetAttribute, Stop, WaitForChild, new
- Constants: `GetMouseLocation`, `X`, `Y`, `ScreenPointToRay`, `CFrame`, `lookAt`, `Origin`, `Direction`, `Destroy`, `Motor6D`, `FindFirstChild`, `Enabled`, `Character`, `Torso`, `Right Arm`, `Part1`, `Adjustment6D`, `Instance`, `new`, `Name`, `Parent`, `Part0`, `C0`, `C1`, `task`, `delay`, `_changeSwordMotorRightArm`, `Enum`, `UserInputType`, `Gamepad1`, `VibrationMotor`, `Large`, `SetMotor`, `wait`, `Base Sword`, `CharacterSword`, `Single`, `SwordType`, `AnimationCollection`, `workspace`, `IsDescendantOf`, `Humanoid`, `WaitForChild`, `Animator`, `os`, `clock`, `GetPlayingAnimationTracks`, `GrabParry`, `GetAttribute`, `Parry`, `StopFadeTime`, `Stop`, `InOverdriveMech`, `HasAccessoryEquipped`, `SuccessParry`, `Hollow Oath Katana`, `Gyaru Katana`, `Riftflare Katana`, `Hitman`, `Oni Ghost`, `Fallen Angel`, `Prismatic Odachi`, `Pink Oni Katana`, `Black Oni Katana`, `Blue Oni Katana`, `Purple Oni Katana`, `Red Oni Katana`, `Chroma Oni Katana`, `SuccessParry1`, `SuccessParry2`, `SuccessParry3`, `SuccessParry4`, `ServerParryCount`, `SuccessParry%*`, `format`, `Phantom Pact`, `Starlit Halo Wings`, `Guardian of the Underworld`, `Regret Blades`, `Cloud`, `CurrentlyPlayingAnimation`, `walk`, `CloudStars`, `GetAnimations`, `LoadAnimation`, `Serpent's Fang`, `Angles`, `Length`, `Serpent's Lance`, `Laser Twinblade`, `TimePosition`, `PlaySpeed`, `PlayFadeTime`, `PlayWeight`, `Play`, `ParryTime`, `math`, `max`, `SetAttribute`, `GetGamepadConnected`, `Highlight`, `FindFirstChildWhichIsA`, `ParticleShine`, `spawn`, `OnParrySuccess`, `PluginManager`, `CreatePlugin`, `Deactivate`, `_emoteSlot`, `xpcall`, `COAL`, `Alpha Mode`, `random`, `print`, `alpha sike`, `Stunned`, `LobbyTraining`, `Dead`, `Alive`, `LobbyParry`, `DoNotParry`, `ChargingAdrenaline`, `Qi-Charge`, `Upgrades`, `Value`, `InLobbyParryCooldown`, `_currentEmote`, `timesParried`, `Get`, `isRankedMatchServer`, `isMedalServer`, `isClanWarServer`, `isTournamentMatchServer`, `TotalStats.Kills`, `GetChildren`, `GetPlayerFromCharacter`, `HumanoidRootPart`, `Position`, `WorldToScreenPoint`, `LobbyTrainingTarget`, `GetTagged`, `CurrentlySelectedMode`, `Hovergoal`, `Soccer`, `GetPlayerTeam`, `HovergoalGoal`, `Goal%*`, `tostring`, `Target`, `IsTheRisingZombie`, `GetLastInputType`, `MouseButton1`, `MouseButton2`, `Keyboard`, `ViewportSize`, `UpdateIdle`, `OnCharacterSwordUpdate`, `Fire`, `SetSword`, `Idle`, `GetSword`, `warn`, `Failed to find sword info for:`, `Failed to find sword info, and Base Sword doesn't exists??`, `assert`, `AnimationType`, `UpdateSwordFor`, `CancelEmoteOnParry`, `GetKey`, `CurrentlyEquippedSword`, `_accessoryUpdateConn`, `Disconnect`, `GetAttributeChangedSignal`, `Connect`, `Block`, `UseBind`, `Settings`, `Misc`, `Tap Screen To Block`, `Remotes`, `ParryAttempt`, `FireServer`, `IsMobile`, `MouseButton1Up`, `Activated`, `Observe`, `VREnabled`, `CameraMaxZoomDistance`, `game`, `IsDescendentOf`, `LeftHand`, `RightHand`, `Model`, `_VR_ORBS`, `Body Colors`, `Part`, `CanCollide`, `Anchored`, `Transparency`, `LeftArmColor3`, `Color`, `Material`, `SmoothPlastic`, `Size`, `PartType`, `Ball`, `Shape`, `VREnableControllerModels`, `SetCore`, `VRLaserPointerMode`, `pcall`, `Head`, `PivotTo`, `Fist`, `Cestus`, `Cestus2`, `blade`, `blade1`, `VR Hand Switch Sensitivity`, `Current`, `VR Parry Sensitivity`, `min`, `GetSpeedOf`, `GetDirectionOf`, `LookVector`, `RightVector`, `Dot`, `Flash`, `FillTransparency`, `TweenInfo`, `Create`, `getInstance`, `Swords`, `Clone`, `Color3`, `OutlineColor`, `FillColor`, `OutlineTransparency`, `Beam`, `IsA`, `ParticleEmitter`, `Lifetime`, `NumberRange`, `DescendantAdded`, `GetDescendants`, `Client`, `Data`, `WaitReplion`, `DataUpdatedEvent`, `_equippedSwordConn`, `FireSwordInfo`, `OnClientEvent`, `_swordInfoConn`, `CharacterAdded`, `_onCharacterAddedConn`, `CharacterAppearanceLoaded`, `_onCharacterAppearanceConn`, `_onSwordUpdateConn`, `ParrySuccess`, `_parrySuccessConn`, `NoobParryHappened`, `_parryCooldownResetConn`, `M1Stop`, `Event`, `_m1StopConn`, `InputBegan`, `TouchTapInWorld`, `ParryButtonPress`, `_parryButtonPressConn`, `observeTag`, `BlockButton`, `IsMotorSupported`, `HapticsEnabled`, `GetRemoteConfigValue`, `andThen`, `isDungeonsMatchServer`, `FFlag`, `GetInstantFFlag`, `NoobParryEnabled`, `VREnabledChanged`, `CFrameChanged`, `SpeedChanged`, `CharacterRemoving`, `require`, `Players`, `GetService`, `LocalPlayer`, `PlayerScripts`, `ClientLoader`, `ControllerIsolator`, `CreateRequire`, `script`, `ReplicatedStorage`, `CollectionService`, `UserInputService`, `HapticService`, `TweenService`, `StarterGui`, `RunService`, `Debris`, `Packages`, `Replion`, `Signal`, `Net`, `Shared`, `ReplicatedInstances`, `DebugFlags`, `Common`, `Utils`, `UseBall2`, `Controllers`, `AnimationController`, `AnalyticsController`, `SettingsController`, `EmoteController`, `ReplicatedInstancesUtils`, `VRService`, `Observers`, `ClientGameModules`, `DeviceListener`, `FFlagClient`, `ServerInfo`, `ThreadSafeTargetingHelper`, `SwordAPI`, `PRY`, `CurrentCamera`, `defer`

### [808] ReplicatedStorage.Controllers.SwordsController .PRY
`ModuleScript` · bytecode v9 · 145024 bytes · 240 constants
- **Services:** game, workspace
- **Key API:** FireServer
- Constants: `na`, `oa`, `Ea`, `O`, `k`, `Ta`, `Ia`, `_`, `R`, `Ha`, `la`, `q`, `X`, `wS`, `r`, `V`, `Pa`, `Gh`, `Da`, `JS`, `AS`, `pS`, `sS`, `HS`, `o`, `z`, `D`, `H`, `P`, `j`, `GS`, `tS`, `gS`, `eS`, `KS`, `oS`, `da`, `e`, `bnot`, `La`, `Qh`, `ma`, `A`, `Sa`, `G`, `ES`, `lS`, `readf64`, `writeu32`, `copy`, `F`, `ba`, `Ca`, `fa`, `Qa`, `qa`, `OS`, `W`, `LS`, `fS`, `aS`, `cS`, `VS`, `MS`, `vS`, `error`, `n`, `y`, `YS`, `Aa`, `pa`, `sa`, `ta`, `Ma`, `va`, `Ra`, `_a`, `xa`, `ia`, `d`, `m`, `Fa`, `S`, `readi16`, `g`, `Z`, `Ua`, `Ya`, `Xa`, `ea`, `ca`, `Wa`, `zS`, `ya`, `c`, `Na`, `ra`, `za`, `b`, `C`, `QS`, `NS`, `U`, `unpack`, `bor`, `ja`, `hS`, `Za`, `Ja`, `Ba`, `bS`, `kS`, `readu8`, `mS`, `DS`, `Ga`, `ua`, `ha`, `wa`, `E`, `Y`, `rS`, `_S`, `TS`, `l`, `SS`, `CS`, `M`, `tostring`, `v`, `ZS`, `US`, `K`, `bxor`, `xS`, `qS`, `!!!!!`, `I`, `coroutine`, `yield`, `pcall`, `L`, `RS`, `XS`, `ka`, `FS`, `PS`, `jS`, `ga`, `dS`, `x`, `i`, `IS`, `getfenv`, `debug`, `info`, `s`, `[C]`, `FireServer`, `game`, `JobId`, `494kjkdf`, `writefile`, `64565gfdd`, `TIME`, `workspace`, `GetServerTimeNow`, `math`, `floor`, `string`, `byte`, `bit32`, `char`, `table`, `concat`, `random`, `RemoteEvent`, `Q`, `iS`, `band`, `a`, `rshift`, `Ka`, `aa`, `readu16`, `N`, `nS`, `BS`, `p`, `match`, `WS`, `yS`, `Va`, `#`, `<i8`, `
       `, `>i8`, `       `, `       `, `:(%d+)[:
]`, `Luraph Script:`, `(internal)`, `: `, `J`, `B`, `w`, `T`, `create`, `t`, `u`, `h`, `uS`, `Oa`, `readi32`, `readu32`, `f`, `_G`, `5455ef47-de02-4074-808c-8d82c2cd12ec`, `BAC_HASH`, `90fa5062-066f-4376-b9e9-8adc47fbd983`, `BAC_FAKE_1`, `2983784e-7f10-4278-a8d1-259db4906a2b`, `BAC_FAKE_2`, `wrap`, `setfenv`, `lrotate`, `lshift`, `select`, `sub`, `gsub`, `buffer`, `countrz`, `readf32`, `LPH@!!\IZHXfWW#@h(MAPNTXF\[%'Eb/]s+(Hj3:h)CnC1BhF3+E8)6Xse>#%IjI:Lb8P(h3ta&7ZMd%q?&Y-"AB6"_30p&7Z/Z$=a?O$Y+Ek+CbXd>@T0n+(I!7@:OFiF(6J*%V&LK!b27@"Cilj;e%Ij(1U-M5@[o-!FlOJCL\,i3b'(<11L>s6t9J3'OuDu3+Hf8Ch#_?.Ut>G'4XdIARd<%6=UU;@:K:I!b3Nd&S!>$87O;_"(QI`4(C<]=(>*;&n;2WI:F4+Ht*Im1Lgf&%V'os)e0%]"(NB^(h6BP/Rq^h'OqkfEarEc"Ci'S0k7%i$=dRU2e+=I%qAjSH]:*s!=t/!@8[<TD/Ws&/rbs&&R])[?+=jSs8W-!m>Wi1!BQ2MNC*`l0oZ3'EsBo#@rc^1NS\/V-Y!0(J??\(lAcFC@gUFFF`2;=ASu4(iaX0Bc3^/'Ec5"c@;p:'BObU`J,fR3NR)+J9k+3(LPSB/!C)RuH"$p%&k?MT@lrn-#Q0SGN<'0A#gNHG@<Q^+B6%F$:Q7nTqB9>Po3[2d@fc.[U&p-s@<)RtFCf*/%*jrEFD5/b6ZR*7A8GsnV2aMF!Z[1$-Y*$`l\GONc9Yt5@ps<ZNKdpgN+2reN=U;ojc'i+!HsG4N<*sWU5a?tA$0;kNRhTK:Q5^pNQ>U.I>nLf@u"Op&jD:EFbn4NcG*l<F`1E0F\EouDIjr!DfTQ8DIm[&De'u4DBO"3F!,RCDfBZ<C`mh?+Cno!C`mb:F(A]tDJ=-5F<E,IATD?qATD^$F`2OJATD3%@;^31+D#@uFWbUE9H[nfE+*d0+EJoD85Mu-?VaF(5upf^;aj\[@;R,7/oPc?N=Wa_3F`(;c;F\&;fbM9Bk2@.F:$62ARf.hCL^d^\mq+;Dfc91Bl\<:#E<A6@pidIcAc=7FCf(iG&Cl'@f[g6FTg!$c8]EXE-ZO0c=V!+DKTt)B5VF$AeBE#s&$SrcN!qEFCf(iDe<m$N=5!1-]JcB`f5cZ^KG2>NDsC^H=I!UN=-bd#0m>J@<+h)#gR!u6$-[.@r?R5Eb,F"@rcL.AJ`YMEc5u=+Dtm9DfTl0@;$d(Bl%<tVMJl&@tS9IVHisV\rHZ'!VME[c4X$7DfTk'ATV@&c2euGF('.n!?@)7A;GM@!Q^8u!KFEqLl#UB,)s8hNP&a%R>h5j!F:ZeASqUqY_u"q+_(Zq$I8QZ@rl?PASuC(;.F]X;I]f@N<OonZMF^XLkoP%R:E64c2l:ODg5^o8#Tp<BMi"#N=r+JhhVbSQKj:LN<Ffl$B5'E"4N54UQ(aQ7gdNBAQ*\^@qg+,NN$E!JqsGtcF[T8Ch7,\.#<.W$T=!AQXe9MNPA;GG@NXg@f\NJ+9Bd&"jU7\1N[>?4Ts%cNEnnUC.A^e@n+9R:(,A;8T]2gB4Z1&"O;%!A8Ygb"4"DdqJ^"dp9R&PAOd-RBkTkUATD<t!JHGM!(WSiN<fLa`/%iu@sDM2^E\PVN<*OK,)ls@NJD!E[>dCGN<3\qgLCTR@;HJ"Bl%m4ARo@iASu3o!V_RaNL=dB"jR..F_kJe&#kP"qMfK)%P*M>cG(-NASHDn</kF);[q"RFE1f3Cf#.`Eb0N)@#aSa<<USJc>@8`;fbM9ATi**"87^p"jXPd@ru-r!M59ai_:pn@t\>iK1c!FfT!#cNR_M>).N_gNEahj=H*=m!M,2pA)MimcA5udD..;f@;'jr0!gOZAOdBYF)OlsDeX<-6Z,\;ATi*:N=KT\9ScA`6Ntc[ASuF&.r-hK<Q3b&Ld18/PDu/MG6H1l@rPjsLjihY"D3fo%*h%HCh[QMD.QUUA7]q&c%oY8NM'd7o8O/^cELd^F`'VRE-YE"<#<hkD'3D'FCB9&ASbga+EM6>CL_:!"O:OhASkjg6]J$S!VD?aRUaQO@mded";?cPAOd'PDIlL`@q]ss!C;\f@kkHPNIkXcb`)X?D?S5l@rus,@rc(:f11X!CB5rFlk:ee5M2>0DFF]R"3tb+c=1p;@:N4>16#j],T2RB$dN^$ASu3uBkCpe@q9.g8'kaf0suB:S7C/\N/^SBNOE=*$&o/iEsBnjDJ=-5!K`:RN<)M.4_"Lg@krt%!?dBcH#s27G%5*&^Q$NKiB#8)L#IZ;]nYLQiJrTML>et_O+cJpiM_IhK].H:ZA%7oiMhRjL#J2JWeTK4N6II-iJrTML>f%a@gC;aFDc5>De"*0MN).VcHp&5@;p)hF)>?+;926t#L4#QAp%cc@qBIg@g:5YARfUd!IB`AL]J*Ig5(`n:(GR=<HNIs<ci%nDffK#A&DesA!LOl!=k)lN<(,\>E(Q,!@Ee>L1=1m"O?1?A8Z*n98uSSA-L6\Eb/io@hBfB8Y]ct!(YgSN;rtZ3/mqg@n'r::C,88Eb0?8@sDoY!>pfh@hIXY"=]=&N@QQ>98rsV!@a!/5E4r<\;,kN@<;[uc=Lg$G@>LrNHA`Qejf`_N<3*lQAlF^!=+TQ$dRF8E--1mG&h.m@qB.a%<.;A9Ojf,L]IO9R#R)4O$H29*K=c`!!#+^Q=E^@*XZ1C!Ul"$Deod+FE:u$B5VF(mUO%BA$VV\@l7b+!Dnd%Qt;+E!Mk]Q!!!!h#D8!:Mk]Gu5R`W9N<*"<Y`/Y`c<k&^Ch7YlNHAZAiF?nsc@^e+mRLC\c=oHEDJqlKFCSm"brfNJNBYS1#L3peAoqU*NHT2N%*f63D00?%FCB9&ASbgaNAopX#L3hTCi=6$c>I'%$I2`S@q0RoF`VJ;H-TuA>:hEL?#q;rATAo!DK9lAFCfM9G&Cl'DKTP>DeX<'/hSPiEZce`EclJ8F!VrH/hSb)DIjq>F!*#EASlO#@<>q"-tR4(,$Q1:>p=>9/g*;"I3:-p+F>4^DJ<Hb+F%I.AS3,KDImF%/gr,k.4Hl%.4KZfcK8UZ@;TW]7qcCS#GX[:qY/?mWO=&0F*.c6@:XCipl/^(F9p.sD09`7NH/T>4C\L\N=2PA/7Uj;%*jQ:DId?s@;U%'AU8',"-'0fcEC^YBjl2g"4`BQ=cN)a@s_\mLkK90<fOZr7L@?Q<c)bqAT_ftDds!sFCAZsKT1Om"D<]&,E;8(NS%_S"cX(N!DJIR6]D=_#UGB1@rMUsNGNE>15uXrG6H1l@ru-m@0Y"hEb0<5!S!*NAOI0VDIm=!FDbMtDf'&`B5VF,A&ucJ"@nFbAOdZaDIHLdFDbZ&F[L%B6"P4[AP?TSBQRm)N<+KfiJdq1#W.MAJ,fR3A+sIs"#Q!t)Int@F(YX$Vdj1YXGn61!JHFHN<+HeXCDgi#L5,8FCSl_Lbj'i1h5&,f8AQXS]1F2emj7N/n:;Zq@GfLc+B;aNKB<ZO(/5+@nF4j7L7:,:2Ooic=Lj$ATK4TDImF%@j!.BDf0H$BO`0,AS5mhG&Ck6DJsQ0FDbZ,+D,O7AThd#@W*B,FCSlsN=2YDDdtGZN=;YCl\uBZNN-IhFGKtNqVPfXJGSUR]48chq`MAYcELe"FC@uY6UW\CEcc2;Dbt7gNHB&P@uV*s!G%0!)3)=>!==_d/>ONeNFub'EK($_#s4,a1l[Z.NQGZ2"jU@\D.uC<iiu!/2i'_dBa2l.Eb0<0&iN7%EFVe-DFFiVF@g=lN'(rgc98`kEc6..@;p:'#`WD*?O+jcA8Z*g#0qI)@;p+,.?/+QN@89GEK(#U[$c^VN<X`hUkfJ8cJ`9EF)Ok]H#l8nUgmnPL]NNq[>k1:A-^B\7qZ[_EVa9NNSC0+T48)YN<a'TH]<G-ND!ae=H*S'c@9=*ATD8bNFd3?"O7%ZEa`WkDe94!FCB$,7g>TF:Cn#cc2eB6Df0"e$9O5hN<,u;7Z@]YA"dB?Es^-0FE2;5@rcWt@hE+.c;e@$FC@uMNC5O8g5Ts,8#]u+#jV2,@gY8V@rl.U$($YNN<r.8#0mDo@:O8$QXaiJA'*J]NGW2'm:-A7Bi>/[s,CT9qa$#CNOd#ak)Bq1Wt:'i`/T7VBaW,qCh%:&EclGA@p3ARA(+pP!A0;e@kkcY@ua'_8n0Juc2qa?D.-0B"9XWpN=r^[>)`oi1"qTfXRdb7MjnM:\IWc[$I1m!;f6_UBm+N.Q>:&Ab12DN7mGL7E%ct&N=@@sc&F(bNBgt\7q2Q3h2TQedTlVLhi7UY!Rm$=N=!F\</h7>Lk&tEs,GAV:"i)>/4VlfN?A1`k!oG=Li]98#0u,@F`V,7VN#/(c@oa36ZYg)DImNuA#3[WA(>'0cBMg$>shfuY`2._NU((<5E,]<!=t.sNLa:0dtfa]H0^I0JRcZ/@g8un$g`ithMme1"9a]35%@;s#E=1B6O1m=ASuC(:<mrk+D#4cF^eomBl"o)Ea`utF(lbBEFj/5ATDL-DJpY.@<G6dCiCM>De=*"/otlMASb0c+D#V&DImd*F!+m6DfBZ<F<G[GASYdij+o=06"Tne4G_]Ic:ha?@V''R#%hLjN<I@_B4EAac4&-\DJi#ODaJJU$\44]NDt:b(6&]g#`"B?`ab<EH&Z]O&Aa>,6">FT4_r\[pa1IL@mB/N"C$j#E^g5XNFcs8^5W.67>Hj'N=\43O^eE:N=r.KeVsSk!Gm_rC5niq!C;\IDajrVEb/ct7f`gR7.X.TAQB&]Ec6&0&Nl%.o@<($!H=%BTtLhLl]othc>6uT@;p8k3K7p#!NqC_@f[I,+C'o$L]Yh\KS\C!bJo@bATJ:*FCf<2@UX@eFH'jJ!T/koAOHdKDfTr@&Cc\bZt"r&c2gRtEck%[NG*9>6]D-R70UtVF)?&;!'D62@m9qnAc^3;</kj,cM1lMDKTOsDeX<'!F:\&>)`O-&r4a5#mgnF5V=/c.PE1r/hSb-/hSb/+<VdL/hS7h.P*,',pOfk/jMZK#mgnF+=\c^0.\4g,paca5X6YC,pklB0/"_%-n$`%,pOW_-mKr].Om)"+>,2r+<VdL-nd5)#mr:3+<Vd5/g)Vs5X7R\5X7S"+=ng(-7CJh-9sg]-71&d5X7R]-9sg]/1N%m/hSb//hSb/5X6VF+>,'-/gDni+:/>]/g)es5X7R]5X7S"-m0W^+<W3]-7C>d5X7R],pklB/hAJ#+<VdL+<VdL+<VdL.P*1p-m^)d-9sgG.Nfi`#mgqi0-Dej5X7S"+=]WA+=JQd0.&"s,;1T#5UIg(-mh2E5X7R]5X7S"5X7S"/1Ml0/hSb/-8-o&5X7S"5X7S",q^;g+<Ust+<VmO5X7RZ0.K4P/g)H*0.nOq/1rJ%0.\S+/hAJ*.OZr$5X7S"5X7S"5X7S"5X7R\5X7S"/gEVH5X7RZ-9sg]$7-fI0-DAD5UITr5X7S"-pU$_+<s,t.OHJl5X7R]-8-T/5X7S"/gVes5X6VH5X7S"5VFEK/1;i1/1_nd/hSb-,q:#[,="LZ#mr.)/g)8]5X7R]5X7S"5X7S",q(/m5X7S"+>+m(/0H&X,="L@.OIDG5UJ*+5X7S",;(Mo5X7S"5X6YL5X6_D0.8/4/1)br$7mhQ+>5,c5U[`t,pjrc5X7R]+=o/m-mLu.5X7S"+<VdX+<VdL5X6P:5UJ$85VF6,5X7S",pO]e5X7S"+<W't.NfiV5X7S",qLB./g)bm+<W<E,:kJm-9sg]0/"^u5X7RZ5U@O+5UJ`]/grtM+<VdL5X6YI0.JS&,p4<[+=]WA5U@Nq5X7S"+<Vsq+<VdL5X6_?/h/7r-7(8s0-CTS5X6tU+<W3^5X6YE+<W3[00h05-7UPh5X7S"5X6Y@-m^)a-9rk*5VF605X7S"+>,!+5X7RZ5X6Y@,pam'5X7S"/1*VI5Un08,mkkM5UJ*0-8$Dc,="LZ5X6tF-7(oB-9sg]+<W9i-nd+o/1N;$0.n@i5X7R]5X7S"/3lHc/gr%r5X6VK5UIs*,:GfB/hSb),:4ro$84Xo-8$T0-8$Df-9sg]+<VdV5UJ-,5X7S"5X7S"5X7S"-9sg]0-`_I5X6VD5X7S"5X7S"+<W3^5X7R_5X7S"5X7S"5V+QR5X7S".OHbm/1)\N/g)Gd+<W-\5VF6&/grtM-nHJ`5X7S"-nco40/"t30-DYf5X7R]5X7S"5X7S"5X7S"/0H&`5X7R]5X7S"+=nj)-9sgE-pTF8,q]NX-pT",5X6tF+=KK?5X7Ra00hcf+<VdL5U@m&5X7S"/g`hK+=9?)+=n`g5X6YK5X7S",;()`0.%tp5X6PF+=]WA5Umm!.PE,6+:9SF/h\P(5X7RZ5X7S"+<VdX5X6YG-7gbq-mh2E+<VdX,q(;e5UIdB5X7S"5X7S"/1N8#5VF6&5X7S"5X7S"+<W3^+<VdL5X7R\$8*qr/g)W/5X7R\5X7S"+<W't+<VdL+<W9Z5X6_?5X7S"+=KK?+<VdL.P;hd5UId*5X7S"5X7S"-9sg]+<W3`.P<A,+<Vsq5X6tF0.n@n5Th0V-8$Dj5X7S"/g`hK+<VdL+<VdL+<VdL-8-to.R66a5X6YK5X7S"+=nj)/1N,#+<VdZ.P*1p/gr%p,="L?.R5:&5V+$#/0H6(-4(#(5VF625X7S"+<W.!+<VdL+<VdL+<VdL+<VdL,;()]5X7S"5X7S"5UA$45X7S"5X6kK5X7S",qL/c+<W9b+<VdL,sWe0$6q)E0-DAD5X6eA,="LZ+<VdL+<VdL+<VdL+<VdL+<VdL+<VdL+<VdL+<VdL+<VdL+<VdL+<VdL+<VdL+<VdL+<VdL,p4<Q/1r87+:/B"+=JW\5X6YK+=]WA+<VdL+<VdL+<VdL+<VdL+<VdL+<VdL+<VdL+<VdL+<VdL+<VdL+<VdL+<VdL+<VdL+<VdL-9rdu$6q)S+<Vd5+>+un5X6YI+<W4#+<VdL+<VdL+<VdL+<VdL+<VdL+<VdL+<VdL+<VdL+<VdL+<VdL+<VdL+<VdL+<VdL-m0WT/1r87#mgq`/gDJ]5UA$*0-D`0+>5uF+<VdL+<VdL+<VdL+<VdL+<VdL+<VdL+<VdL+<VdL+<VdL+<VdL+<VdL+<VdL5VF6&-nHtt#mgnF+<W<i/gWb--9rk"/0c\s+<VdL+<VdL+<VdL+<VdL+<VdL+<VdL+<VdL+<VdL+<VdL+<VdL+<VdL5VF6&0.ne@#mgnF-n6>^5U.Bo/g)bm5X6_?,sX^\+<W3g+<VdL+<VdL+<VdL+<VdL+<VdL+<VdL+<VdL+<VdL+<VdL5VF6&.P<8;#mgnF+>5AS-9rk"5Umm-5X7S"-pU$_,sWk$+<W9i+<VdL+<VdL+<VdL+<VdL+<VdL+<VdL+<VdL,9S*O+=ocC#mgqe+<Uss/g)Vg,="L@5U[a--9sg]5X6eO5X7S"/gWbJ/h\[s+<VdL+<VdL+<VdL+<VdL/h.td/h//"/3lHI#mr=.#mgnE/g)W/5X7R\/0HJi5V=045X7S"5X7S",q^`65X7S"/g)H*5X7R]5U.C$-8$nt.P*&75X6V<.Ng>j#mgnF+<Uss+<W<[5X6YG/1!PH.NfiV5X6YE/g`hK5X6P:.R66a5X6P:-m0g$+=]WA+<W9f5X6tF+=]WA#mgqe#mgnE/gEV(5U.m(5X7S"/1;i1+<VdZ+<VdL+<VdL+<VdL+<VdL/g)8Z,q(5o5X7R]/g`hK#mr(5#mgnE-6NU$+<W9b,qgkn5X7S"5X7S"5X7S"5X7S"5X7S"5X7S"5X7S"5X7S"/grtM$7I;F#mgnE#mgnE,:jr[+>,,s+<VdL/hS7h/1`>'/1`>'/hSb/+<VdL+<VdL0.\4g@gWPfBb8RQFDbZ#AU.m%F^o!-NH/rZ+cR-`7;t`t#`W'H1\cq1R#N(q!BQ2Jc4Q8"BQIto@ru<s@uFjsMdf1F-t@W@@oE]ZDImC"c=qDkF)FPT@r>^s@mX[:c<=^%@<?Pp7rrfp%;5=E!#Q!ez%*ehQDI[9r@;U%'AU8',%*jlCF`Ctj6$.0Z@r?R5RZ4jf!S*/>A)G4\@ggSQATDg6Bl%m/TjqYO'9,n"M#Cfi*b15)ac4,H4HX+S=b$JPe782^Jn&D&N=0?X$:b+F@p1or):rYYd&M0LQ:F0?qIJcDVsH+i`4`_X6OD&WF)tc+ASkjN@h1ha!L$"i?Xj*:Y_]Dkl57gdZ0\0pYd<W&l\N:@^?h\NTY9WsNKUs@!'C9.NB]Z.$dK'HBmFc6@:X1c@qBIcN@n]t-=[X3@ge<V@q9(`f;OM4X#t*+c9A8.D08AaBl@ltCi;[OBle!)GuS["VIO1V!!!!]jA/90mpg"=l&@T2D?eBTAR]M!kc4K"4_+EU"jWWJ@;]n&!="Nqer<sF7hO#V@8q>[DImHu6Z,\AATi*:c2f2MFCeA^FDc"a:i(&jFDbf2!FCb,N==<r+H9g*6j_->9jr-PCh7-q@mhl-Lmqm`3B["mNBQ<^D2eSB49Nk0Mdn_\%#pH\NB(JOO(/E1<E3$]!!#,G*fW?K:^52GDImis!F^t0L_&=$G@UWY]8-K"A*%4E!HF+Q@gF9<!Z+A5^Pr@24:5[$58flXL]LG6fT#1U_?l#L7ftW.@+?3>(QHIF:^G>IFD5f7NG`ZKL5c3d!L8WRAOd]bF)OlsDeX<-6Z,\;ATi*:9Oi*/FD#K&NMg9"I#S0N!I9YFc2j;l,q(e^>:D(5>m_$%CLb1jN<>]1"O7&KDe<m$c2pq(FCB"h@g1.kATMd+N=iXZd:31l6]JrmLfS!g%nE]-@p<HdNLF@#22r.Jeej2QNE])9=(;L5qKKCELl"6h5=[pD@t**L!De]_F1-6^&U9:0q-u0iOcAF3&-e+$7focO(Q2[kF%HJZ#))tA!sGb+)ZpNCEs'.'F!g$<!JqbmHNOr<4/R?tepB)t"%@8K)ZpKJErs(&F!B1(!Jq-Fk&V9op&U!X48*_@3T^A:M&O*LF#hMH!JrAYL3"9A!s+6I)ZpPYSoYse`W:nu.cte>7a;$kM*\jsF$Q;t!Jq6Q!uJEKRkVPqHV8\r7<:]]eoN)(ScO[:97$aN!uT&\F"@5/!Jq$+k&VuKV?)Mo&pj]j!uKhs%'Fpr.@rtL2mrsT*qfVk+TdC>L3#5L`W:o\"h&I]&Y9#[M$;IO",6mY3K?OLM)(B<EsdX&!Jq$KQ?,!>^&a'#1>[']%`SO+M*A(`"")S"SpO+Wc:)dj#**aV,1ZdOHV8\f7<:KWSoZ70L&m,397$aNEs7;FEugQ8rW.jf4J$UY7+MBqM$B8e%*&GNLBAItrYkqE!NpK*#-.c]&!IO1Es8<k!NHL]!fIEOrWj!l3OV",]+!.&8I2@&Y&bVT[K24C97$aVHP$1'&Z0n/-,)fhM$j6'"!c@tpB+'8!uh=I)Zp/f`cDp0XoXAB97$acEtOFZEuP$HXoXAc4Q^]3$MFLWM&sZX%c7?hY6,^GHQ*%m7<9QZ$ek^*q^r!:$+k6Z$gRhn%D*)@j#i>-'H>%!%f6d+[RgS%97$aZEso-tEsf?E!Jr7kHNOh>",?tO-,pl+M$)=MF#16*!JrYQHNPUt%$q&h'ttUhM%A0YF!Js2!JppHVK3m2[K23f6&p"PLB@R6!uh=DQ3*6PlN74i-gj>&3gKi26\YVu*<$!)!S[X33!05G!tOc%P61n+!s+\h6NQKT!UBgd!JqH7!g=28!JqH7!UC_[!JrJ$!g<Z>cN?-/!uh=OQ3"l*Rf``n+21)C$&/K(^'2\*6ikIV6_4>%b6n?oRja!l1knF"-2%A_Q3#/S6ikIk&s`RAb6n?o_^L6?2WdF/"J,X`!K-u83!031!sSE$EufuS!Jq!Bk&Wr)NWFtA-e<>S+J&UjHV8\f7<8]o!trWV&VgH-*nD84)O:KK0pVisM(Z5X!u'MlmX%TRHSBdY7<:&@)ZtKj7<:Y>c>uC>`W:o*+m*i0:BLWS&#L9JM%>>^qZl-^/d&-TbB"'gb5nULUBn19,`W-7"L\g;6O;]dSk04J97$aIErku]"3L^7)5\>TM&a6N!u'MlhKqnB"%@8n)Zp5>k&VI/c2ibf'@q44/`m(jM$&cZ"TJQ)/*7cQHV8\fejXX,mK)o@!s+5u)Zp09F$.`pF$&5I!Jqb]Q?*AHc2ib'97$b/EsTd4!Mole!s9JEQ9t]=Q3$:TrW.i\7KMfl!S[X33!05G)Zs7G!s.EalN75G!L?(R/'\1Ul[AkkM&*5pP6'D="#pAa)Zp56F"#mlF!-c;!JpltQ?+RjNWFt=0?/&M'A`bHHV8\f0RF?0EtR8UF$IZ5!JqWD!ss_b!u'N1l[)9OR1@[QZOPXi!LS3</qsDEHO9iG7<9cH!tFDqq]FQ3=rkK_Erj"%Et+F(!JrVHHNObL,h@<8m/o%h^)I.T+SKk024ai*M$L2)F"Y0-!Jqe^!s*uU#e#(!#bFJ+HV8\f7<9`o!tL@o"kNhqK``7r!uh=H)Zp89!g<]g!s8Rir^-_Pc2m54`W:ntXoaduNWFt<`W>BlgB!-g!s4Ye#gWT4%^$`QM#knC"!Em1k'KaJ"%@8Y)Zp4pHNPaprWL\Co5K$fUB^;u#O<uMJo_=;XpO\#>S!Sp#b)!]HO^M6#/^e+ZNRU88IDd6!stS%F!C;s!Jps)HNQ9g43i1G0D7hUM*8Ro#Iad9pB)?:p)=)7%K:Df'A`bH9*^(OHQ:mh"Q]_>+0HOb=;?j;b7C@0%uW%AWX+N(ZOaAC#R-t($_&d*P8$6iZO"/L+i[(\"&!tC)Zp,%!UBgilN7&QM&MrdlQsgWM*d4'P6'D="#pAa)Zp?!&d*1W!sZ.8!V6C4!s;s6r^-_PmK)naQ2ugqL&pT@gB!.!!s4Ye!R1^+(Z$)5M$<<gEuU\O!Js+nc>s8_!s+6>)Zp6!!s,S-_ZKu[!s+\g6NNYY!QtZ/!M^([,IRWrb<uBSb<EW@!QtiO!Q.!RRi_PtM)5,3dfG@-"#pA`)Zp2JHNQ6f"ibm^.&KFS"&!tC)Zp9$c>t#W^&a'<(qt&N-f+l\M#i?PEuCPM!Jru%hK'BcScO[(2YM2J=p"e^LBAIt!uh=E6NQKT!s.uqo*>8'M&"SBlN3paM(7'WP6'D="#pAa!uh>*6NQKT!UBgd!Jq_L!UC'k!Js54!g<Z>[f\Sl!uh=CQ3*6PlN74iir_XLr\O]XrW2$aQ2ugJrW89#L&m,:ecG))gB!-;])n/s%bk(o"3V4="MY%Q#kf2>M(m4rEuhCa!Jq]nmW06-!s+5n)ZpB%)Zp<I!UBgiP61nS!s+\h1]md=!TOFa!JqNa!g<rY!JqNa!UC)i!JqK(!g<Z>g&j;:ef+\n"eKcT3jo'G1Y)WV5)oZ#M&bZ!Et3p*!Jq<[mW0)FErh+5E=93r!sI$SmW1!"h>rHR97$aSHPDKe"0DYZ,DI->M(b09!tLn'Q?u8O"#,'a)ZpA?!UBgilN7&QM)X8llR2Z4M*_+AP6'D="#pAa)Zp2'"p4r0ZP*hd#g63U.VfRD"PX'3ZSDp;lO2/MEs"oA53@:rM$CD0F"?qb!JqreHNP2S,gLa0*4A:W"&!tC)ZpH<!t*id#1<Sm3n>5PRnJ)1F$?0&%Gh--!JsiuL3"$jc2ibW97$auErk-E"185"1"I9GM(l)R"$>??Y'Wfgp-j$*97$a[F!TUhF"I#R!JqlcHNPq81WFc7M??:gHQ*%o7<9lKNcPo+c2ib'#-N"u)YO2gM&tf#P:NL2HV8\m0RFB1)ZpNO!sdN^!t+`@[X1YoSjd]K&'f53$\e\=23%gOEu;?0!Jro+!stt0lN75."dVLV&EX#Z2P'r+,/sZL!S[X33!05G!s\;u"R^UU+J)#CM(sa+EsUV'!Jro#`cF*4L&m,8M0<r,!nm_W3i3huM*&FmEt\HQ!JprFb6&WbVL(r@Y!mC:97$aOEuWDO#LroF!s9JE"%*+TQ3*6PP7Y_7M#s7MP7Y_7M'&SrlTaM4M'^FJP6'D="#pAa)ZpGiF$58)Et>EB!Jq$SeoN(-!s+62)ZpDcQ?,0cp&U!r6Defh&"WfYHV8\f7<:qa!sQ@?)7Fl2(=koq!U^&J,H_''M$2CNEtJ<O!Jq!*hK(L8`W:o5$c[67Z3(,a!uh=I!KML<EsoF'""X@>Y'WfgejXW^M/IAs"L8+1!Rhti#."NoM?<m@!#l"Bzd?#RQo:H*f!uh=CGT-jN"24jnBE&'4#.#6N#*T1m#,;8S#+I.G"&j(>!s+CB#.jsV"Tc:1!U.i3T*$#7di/C/$U)3.!s/9Q!J:U2Q3.?O#4#1k;]MqB!tLq*!sYeFqbmXC#."C7#.jng0FJoh#.k)7_]K)p$Q\X>#."CcNrpp8)Zp/*$i:'bgF`l?"nQL4gBH>5D$bh%qZ?rL!s+#X7KWhco)f0NP6$:>"oAB(pB(GK)Zp-<#4;_SRkP&iWs41b%`9n##1F!U%'otd#l=dkK+<N=%KqCb#f?n*K2r-(UBnaDVZTL")Zp/:!NbGdm,&`ab;J\g`rcPN@iGM^0FJ*Q+(JLo"*3Q,9ZI5S"#Cku"&fH%!s5L#Xp3>o0F!^D!sZXFRYLtrdi/Ai#)`Qd!o!a.K*IMA#+G\q$BBQ;.K0O@VZQsV)Zp/)L'%X\^B7Ct)Zp,G#G)-hBE<b;"+&8q!N<aP1BuDd"&/Fk!Or(J#.k>irrW:u)Zp-/#4$()^B6%i)Zp/6!OmgdmfOL2!uh>HHm8ir%_`.JZU>"u"5X+ars#5sV?6k_!g)"7#.k\sLsH/.!uh=D1Nij&;aR>`!NN=*T*$#7)Zp/$L'%^VhZHeAgD^5S!WBJ3!s,8$/-?*O"*M'TWriGC#.&=S#*T8Z#,;8S"HtA=K*J(Q#-.h,`rc;Dq\oW$#/^NG#0R%"0FK_W#0R47diSe;$T,j-FJf3pRfaT3%0qpu!J.uf#.kfV;ZkkYJ"HqG!s,8$!s/Dq!h55i#/^Y"VZQsr)Zp,V"!QP(?3cB-K-N&X.08H6!W*+S!Ls2.%D)bdK3AM<o)nReqZB.fqaLYl$Nl+fL'N>b"#()b)ZpkZ&;(n5!NR;p#b(n=pNmq(#bqFhNrps9)Zp,g&>!'\cN=D._]&[h$Nl+fIua[cUB;G;!M&lgf`)$_%iYTO#4"59f)l&M)Zp,j7_UkF!Mp"d!Qa.##br=@;_*k1!URQ'"T',?K*K3q`WjTeP;!A-b6H,o#1FXu;\m(L!sZXF`K(*P],LhQ$OF`Tr20WN!uh=C-jJ-&"L\Nhb6'F+X"4>W;f2[A")mo9L'HZW"#()b/-?+*dfTZ0gAup20)bqWdfT\N#1Ft)#/`0]!sFfV!J:U2ir]M'!s+#Y!s5%FRD/hCVAfU="QqQELA(doUDj::!tVjF"Hrk`K*JXaqZ`Mj/dV%M%BBT#doQacqZY.F#,?#CK*K3q])r-9#/_hn0FJ#l!sZ(6"RQ:B#*Tu.-3f))"7?BZ#1G76#3uKZH,g"/"bR`r0FIu;"muIKQ&c#GP8aT*$N]r%ecR]^T*&"E)Zp-."*MWd!sbS?ZVq$nUBS7:#HKHdSI5stRfrThF9fM`Q3.Au#J3n<;ZkkY#FbfGK*)3Q"j7kjK*R;:!s/9"!J:W@Q3.A]`rf6DgD^5)(tJco])sQ^!s;C*o2,af(]sjE!s[cfB`A/c"4J1kK*KL$!sYM$!J:U*#0R)NrW^h""#()l)ZsBd",7$/"#'q;/-?*o!J$dEVoK_Y1Bu\:^B4M5!uh=T!s4@`q[)!r/e7af%^Q7iP?.t3ZNJqb#.n^QE@qIE#1EYVB;Yh[(0;FW!s]%:)ZtE\_ZL%*dfG(*#0R)N#.">_K*Kd,b6%hI#1Ft)0FJ?h!sZXFL'GOHX"Xn`-'eW;Vmcb,T,Rk5ZNA]DY6,"6q\oVX#)`Qd"e,OFK*IMAc3Ba="#()d/-?*7"24jnV<7qZ`Z#!\)#lAp5Hb05Nrp=')Zp,E#D35u"!7c#/-?+J"#9fX1BPi@"*\#M)Zq4T!sI$SecrH"N\ChY#.mM1c3D0")__X(#/^Y_ps0$aLDp<r__gLf^B4]F)Zp.tQ3.?_#5_=&;\A^*.gF`1gBQ,S'aCE;!P&.3`rd7_Ri;HK*9I>-UBTs^E>$h,0WkVdk6!CG],LibQO!KoVZUU+k8OLib:_(9!s,5&)Zq7e-M@`&!s,5S!s.ZT,i0IZ"#DV="&fAX)ZpP)!se,oo)f(O&`,k[UM^@4Sd;(l6jTOr.'<iNUC.@&lR&J76InR13S"H,#NGiA3!0Ge"*'q8!s[L!"&gB*-a*`TaHlu4UDj:9UD'd9#bscn#bs5Z[KrW970iEL#P/Uh!Jr,Z#ce3jpB*AW)Zp,7#jVQp!s8RiL-l6ac3W_@Q2uh.c3V;k[K24NL'Y[0ZN5nM!sn2u0&HajP62a+""XNZ)ZtED",7#t#-0Ec;[15D"*V-U#/^N^_ZKl@"!IaN!s./3!sREu!J:RIqZ?r\!s+#X7KWhc#Gq[jmfP6O1E-EO"&gNK)ZpJO"+I-MpG39uhZJ'^)Zp,C#,;8&#+G]C#+J'a0FK/OUB:X_!s+#Y)Zr:uZNKN?"HtJMK*K3q#0R)L!s8N*"*+Uh!s+P)K5^o3MZJh@$Nl+dL'3\oRkP3P$Nl+d<f[>:!hL>5!M@+_1ku0W"1&pK0FJ-J"1&*1],q-]$Nl+c"2b3p!s+Sf!s45W!sREu!J:RIqZ?uU!s+#X7KWhc!U.i3!s9JE"%*=bQ3`r^UB@Y"V`;[%#bqJ&"TdGo!RJL_2jYHcV)&.4RdU=Z!uh=D)Zp2rP61rOlN)VC#Fbf"#1EU*K*S.R"2Y-@"kssuK*C9;!s=G^!J:RA!sR]e&,u`$`rd7_)Zp,oSc]1tNrr;aP8aTo#/^NGb6%ct!rrE-EX'\hMe31B_ZMRs""XNY)ZsosgB$O,"(hW>)Zq:n2SK@`!s]%"!s+(Y!K-mr#+IT\Y6+g%)Zp.r155t%"d:VJ"cEPR`W_P@RkP3X$TmJSRg#!0'a9L!!QDMM#-/[FZHi]O\cZUHZPruP#+G]!#(lr/K*JXaQ3Or%"#()m!s,is1BjWpG6,Fe!R:'8!Q,iYK*L'4gB.NY#30_.3!0BN_?S`s!s+2Y!s,aS@YY%)#JM,ZG=eto!Q`"XQNJ0/q\oW?#Eo5j#FbaH;[&HhQ3.Ae#HLc,;[&HhQ3.AuP64_eqg9n!#Fberm/mBAef+\uY6MTE"*XdM)Zq=?"0Mg&Nrq'DQQ$$-1Ca&#[fZZ-!uh=Z-a*`LL@53R!uh=D)Zqk)`WHFG[f]P5q\oWE"g\:6"(M@a!J:Qf!JUcqZNDlh1FrV3;^f'V"";ItnV72cWuD-A#EAljM2qa;1E-Ds;]M)*!Ku=B.D?`'!JH4a(XE2-#GW4?;[.sY%*Jsh#HKHb%Z:_$%eB^l"dTD:!sc/S"&fH=)Zt,q"4d\*"#'qC/-?*o!Mc7h#1FLnK*0j1Eea_t#4ic9;[&HhQ3.?ggB1@X"+2U'!s,!s!s?^c!J:U"!sZpNTsk+I1E-Ds$]6b.7cske(uH87#.lSOVZQsrP8aTa#/^NGb6%ct!rrE-EX'\h!LUV("kssuK*D,S!s5e0!J:T/!sSQ(!sRFK!J:RQK*)/?!s+#Y)Zr7,Aci7d!sYf)"&fu<)Zt6_#PL:;!s]%")ZqnZc2mt&!s^Uh)Zp56Rnb`*LB@bcZPs!1P66gLUB<1SRk+XG"O7)RViLpY!uh=C6O:R3!sm'Pb9G5?M''_C_\N.OM)M4:lNjft"#pAg!s-BU!sYeF"&g2R)Zr=NQSTniWWRGJq\oV=#."C7#.jng0FKPR#.k)7_]K)p$STL(#."Cc#,<^O0FIu;!s,S-#/^N^QNJc@1E-FG;Zar@!Q__P;4ed0#;ZJ]!V+bD"Hsc,K*K3q#0R)L!s8N*"*+Uh)Zp5+"!RC@>jhb6#,<+>0FIu;joYggrrZ1>)Zp,*'#k1T!s]%B!s44<NWIlRP;!@KgB#b(NrpI))Zp,U!M80N#-/[F;`j+Dh?*tg#.me_X&F0D!fR'_P6%N_$Oa*>Q3/osf)nqR!uh>7gNEZ$#1EYX#0R%"K*L'4#iu-hVZRk?)Zp,r",7#<P63KH!L!Ti<W`Pq"4[KP0EW6r!KI<3.(095"#DV="&f9@!s+RW&=N\?#4ic9;[^#9Sc]2o#D5qU;ZWHl!fPA,29$R;(lnm%a0u.p!uh=C!!<GK#,;:L]1N:NRgF]T"02h=%,2$1lNW7W;@]0)#hom-dqf8q#)af4DW_*UX1'#Mb6Ql)!s,5&!s,gE1BkK3G6.<E!PZSVhZFf")Zp/$_ZL%*!s+#Y!!<GK#0R)NAd6_)"#'qC)Zq;Y!s8bn#3uA:!sK)/!s-X'!sGqL!J:UBo)f3W!s+#Y-jJu>#3uK:"!7a5)Zp4sUB:X_!s+#Y!!<G+#-.h.NWuh10F!^F!sYM&!sFf=!J:TO!J]2.ZND-K!L!Th".fTNC@;7'#0Rqf0FL&+#/^Y?P91"P#0R)O#,;3OK*Kd,gBPOr*sT%U!sZpN$Gllr".L53$C_+Oo,<fjKG1Bk!sRE[!J:RIqZ?kg!s+#X7KWhc!M?h'!s9JE"%*=b1]n!K#brl`UEgK/UH%BA#bscn#br3U[KrW970i-3#P0P8!JqcX#ce3j[f\SlgD^5`"nMg""'YeY!J:RQ!sS8u9s4Xg"T',?K*A"P!s@!Q!J:QV[K?]>UB=F7""XNX)Zrij!tk80\YfNKq\oV<"fh_."&f5Q!J:Q^h?*qnWrl9Pq^_gQ"fh_.VZQsP)Zp,m!sXM_!sZ@Vdo-F9(qp(VCp*q><kfRU#.l))l1Y8b1E-Ds[Ef)D[f[EI)Zp,?ir]FbMZJG5UCG*D!jaK\"R?TQireUKD%,_8!sIWdSc^c<LBCHU)Zp,V!J$45"8a#>K*M2TFpEX##/`,&#D386#5\KEcN?W=)Zp,;!sZXF)Q*Zg_OhbLisFiK!s,5%)Zr(W#_kaNbl\2,!uh=P)ZsE-#f?`HlN75V!s+\n@06eY#f?h3!JrbL#g5-?!JrbL#jVNR!JrbL#f@:0!JqJM#jVc&^B6Ft)Zp.n!P4m*r<!u@P8aT3#/^NGb6%ct!rrE-EX'\h!epp."#'qC!s+1Dh?L#"BO1WA!tW?QF.WOR"1&pK0P_'F$F:5[P:RTh#."C7!n.1&K*Jpi!sY4q!J:To#.js>^';J'"#(*$/-?*_!WMNi`rd7_)Zp,`gB.Q$!s+#Y+Thr'!TV3&_ZLh[""XNY)ZpG^#6&Y`!s]%2)Zq@P#f?`H_^20IM(G5(_^EG)M)*'VlNjft"#pAg)ZpDM!sZXFM2q`iP8aT)^';IZ!s<NY""4Ak&=3U=;P+$pUB;G;%2%k0"$-A`!sFf,!J:TO!sYe.WriG(Y6/eLRi;GA0"(id!sFfd!J:TO!sYe.b-qHQ!uh=C)Zt/:"l:us!s,5S!s+CZB`A/R"Hsc,K*KL$!s6pP!J:U*gB.Yt!s+#Y!s457ZR`0tM*:hBZSM4TM&,4XZQo/EM(%cr+KkkJ"kssuK*C9;!s>"n!J:RA!sR]eL'?U,lS&\K$Nl+eXogI6Y6.]()Zp-6b6%nEdfG(*$OZk;dg!]D*sU0u$N:7ab6'F+""XNY)Zp;Zb6%m2dfG(*#1EYU#,;3OK*L'4dfT[Q#2:O10FKqe"(CX#8?W+7"Hsc,K*K3q#0R)L!s8N*drGZ9MZSnCf)m]2q\oW\"g\:6!NQ6RK*Ajhc3;)d"#()e/-?'^"&cT1^(8I-V$<D<[GM&eUDj:9"O7)TOcKTChAZOt[g&<,T*':&)Zp,"FoqgK"5X72BE=R"!u9u$S'M0U!uh=C!s/:[#g3;h])uID"#L)c6O:R3#eL2I!Jq)b#g3;C!Jq)b#fA-p!JrJl#jVc&T*%%T)Zp-7!nIIo!s]%")ZpP<qZ6Ho1BEL=;_j(0!V"D;"k+Cm0FIu;"'M5uhL*?_#6j-@""WO:!sXr.!J:W@"O77A#E(8D#Fbsf#Eo63#+J'a3Mm%F#Eo70MZZENdocbW#)`QdLB@R0f,Fg3(rcTm!s,5S!s.Zd#3,e)#-12q;]tc9"$Ngi#)`R&+9R&p!KIAJ",7#LiWCkB!uh=S"*ObK)Zp9::'$sLNroVC)Zp,d!V"tK];HSMRfpG+!s,5&)ZpnNMZX"WP6$:@3VEO[!sb;oUJjMQ"dT5q!sbl*"&f>WHn,G[!uR""jS&`qq\oV<UB]0N#1IMq"hOuf^':>WOp9AZ;r7ZXfE3&pNWml4M[G@C/e6V:]*O<N)ZcK9F9A+=")O##`Wj="70_L$6KSKQX$m6IgGkc/#/`k6#29a8p'.Qd70_K[!T(!^2SL+4(:=@9\@2QaP8aT)Xp2KB,85&2"&T970'<GN)"%E\%`\dC3i<((",e*#0FKtf#He.b2n&lf"kssuK*KL$[Kb1]__;HWdg"8*b6&gj"%E@s)ZsmM"(TXZ!T&kV/HZ9R!t1_'!s\?9qbm`s#.=U<pBKq^!N#s.MZX'>dfG(+#Eo5o#.">_K*RkJ#E&Zb[f\/`)Zp,6m09<fk5u/()Zp,h]09qi!s,5&!s,=/c3=(ab:j;-qZZQorrX>H)Zp-)!Rg]E]`T2UZPru["dT5q!scG:"&h).Hn,GkUB:PoWr[hX"dT5q\$#m41E-Ds"&iM.)ZpS:FoqgKUB:X_!s+#Y!!<G+"$a6s#,;8>#,<^OX&D1a0]iHA!sZ)1UJj8J")$3i"#BtT"&fBk!s//BL'G7/__;H#$Nl+f!sZq&"&f6')ZpekUB:X_])dNg!se-"%%@9O&!IF>#-25>]*S_CRgGPf",gdm+q<jb%]]`udkLpAM[cEh!s8T."*+UH)ZtAp!S+@U!s9JEmR%6NUDrVBUB<^d!UAhRT'labCE!?V1GB1`;aJt:"%0O"lN75.!s+\n@06eY#f?`HlN--8M)a>tb;cp2M)a>t_`4LoM+#>hlNjft"#pAg)Zpn1Q3.?7#.meDV?:;2#/^NDcN?W=)Zp,+"g\Yr!JV>i3tR$["60EY!g=>9mRGMR#6q46!OJs3#)aE&K*IMARfdF,UB,uO$NcUug&D..!uh=C!s+/&Sg;W$#6r?S!W([UQNJ0/f,FeoK+O>UQNIHt!uh>\UNQ_ALDI#s!uD!f)ZpW1#3,ooo5PT73VEOZ!s[daVZV2H[i5DQ1I-tAY6+g%P8aT3#,;8'WriBT!rrE-EX&QH!VQ`("#'qC/-?*OUB:X_!s+#Y!s,s1[GM'*_]&[Y$TYX"!sZ(c#.&RW#.#2=ZNd`iE@&='[K?`O#.%59ZZuWT#,;8)#-.cW;\#)q!R75=Nrp='!uh>9!!<GK#0R)NL'H+I0F!F=!ufbnqZVlsR1Hn31C`XNUB-_igBGk-"7$:)"cEP:4p*S_dFSJ!Ri;G1$SdA>"cEI:"#DJ1"&f6W!s.rlis)h/EBqeR#4hpI"j6q.K*M2T!s/9"!J:W0Q3.AM`rf6D)Zp,m!QVAG",e*#0FJ`3!p]pB1EQ^W;]Y!&!T*hY#.#6N#*T.L#,;8SncLEFZPruJ$S\^f#,;8SpB)rK!uh>f)Zp\Hb6%m2dfG(*#1EYV#.jngK*L'4I]!8K#-/[F;[90%ir]LLlN)VB$Nof$lNYNd*sV$8$XO&/lNZZ/*sV<@!s[cf0WtRJ#*Tu.K*L?<p'0g`0F!FZ$XO&/lNZZ/*sV<@!s[cf"lBDOLBAIt)Zp,T$+ge]!MBbr6f&*DUI5B_UI(OX#bqb5#Q#='#P1\Z!Jq\S#ce3jK`a::b8UNe#0R)Nb6%ct"!IaN)Zq\<!sQ"5NWV'gk6"Wfiu8(&#0R)Q#-.cW;[)Rk""s<M!skY@"&h/X!s-j-c=NUe!s^Ua)Zp5.!sP;!#.jsV!s<oqL+!84#.mM0h2_XOk8OL(!k&-D!s,5S!s+Up!sJK?!J:TG%u(:`#*U_K#,;BtL'F\#"#()n!s+sZlNY6G*sV$8!s[K^!sZq""&g]3)Zpi2_ZL%*!s+#Y!!<GK#0R)N%&F&HQNJ0/)Zp,n#-.on"*[Cn!s.BL#/^N^_ZKlX"!IaN)ZprUcN_i#!t>:C)Zt#VFoqgK%]]f/!Mosc",7#\#.#uk0FIu;",7#l_ZMS#!L!Ti",7$'k6!CG!uh>h!s-LCRfTr:G>"h<"$QYd#,;8>!t?3d)ZrM&%IP?o[fZjk!uh=p/-?'VWriM%'*3^hK*AR`']/un#*Tu.K*L?<c3ES8__;H$lNZYZ#4io@lS&]Qo*4LbRKFW9U)O1I1Ht4CQNI8b!uh=sj)tM,K*(?D!g>5D#,;F8MZf5FD$#n2!sYe.WriG(#.&=S#*T4F#,;8S#+I.G;[CAF!t48o%uLH.Of'-#K.l'^LB@bd1E-Eh%Dj7EiJ.MKWuD-A!T!n_is)hgEBq5B^&nT2#3/WHj*:_/#1EYYpB(GKP8aTQ#4hp"#5\FR#/`c^FpEXR[0&)jb8UNn#294^gB.J/"!IaN!s+(Qii`G'!uh=C!s.9Q`4#gfRi;G1"kEb[!sFfd!J:TOM[$3a!s*u[EX&QH"Khs8"#'qC!s*u!`WNgl1GB1^;Z`6e")%')!sS!0gJ\:$"%0g,_ZKq:""XNY)ZpY/0^]4AUI5B_UDS^k#bqb5#b)4io087(M)V::Ws@Yc"#pAg)Zt/r!oAEn!s,5S)Zpef"eGfPgZJZ;;\fH90FIu;$Nl,fV?8V.pB+>!)Zp,%",6lH3!1iB!KI5V",6lX!jaQg0FIu;!P@4k"K*1@#.$OK`rc@=)Zp,[!sSE$1H)rd"*YLV!s,P(V?jpU!s^Ua!s-KP!sJK?!J:R)gB.Vs!s+#X7KWhC#Nc+EE0gZ*[f[QO)Zp,."$EahRg8X+G80TP!uSlW!sYeFP>`I`#Eo5o#FbaH0FJ!N#FbsV"!7c;!s,"N#-.hF!s8N*ZZ68NMZ_N7UB<1SUFZKO!U^$o!sYf)ZVrp1"Khh2`s/;;V?6k8"7cNpL]\RuNWb7@!K[Ba!KI;HRfU#$!s+DbNWc+J[KA;dK`b6X!uh=VNX![7!s[K\"&f6o)Zt8eUB:X_!s+#Y!!<G+#-.h.'t49c"kssuK*I59!sPG#!J:T?!sXYcXogILY6.].)Zp,OZNCDa])dNg$U;'(ZNC:`k6!+:P8aUK#/^NGb6%ct!rrE-EX'\h"RZKC"#'qC/-?*o"!>Yf#."CN!t?!s!s+&C!sFf,!J:U:4IucC"4Jq3K*LoL\$#l7q\oV<"fh_."%rZI!J:Q^".f\.Wrk$`""XNX)ZqC_QNio]`rccmXr@Im`.p,XpB,U?)Zp,7])r35_Z>Ao$O3a<_Zl;Y*sTUe"!cD"!P4mBV)&dn]se(Edi/Ai$S(9C!s/9Q!J:U2Q3.?O#4#1k;[&Hh!ug8'!sY56P>_Rt#,;8'WriBT!rrE-)Zq4dl3>-.pB(j*)Zp,F%KYJ=rrWK^)Zp,Z!sYM&!sY5G"&f?*)Zp2m5F)Y6!s,5S)Zp2?#P/$"UE#ReU^!t-#bqJ&!sKXi!s*u!!sc.O]2Jie5LooA!sc_B.oQVS;$Wiu#E&Zd!sQjf!J:W@Rf`]gUB,uP"dT5q!sbl*"&fDY)Zr+`WriM%P6$:>"g\:5"hOef0FL=(!TW>F#br=@;_5oj!tge#S"Bd%!P\^;)TF,@hZF*>WuD.H!fd?e!sXrf!J:W8,5)8*RkP'D0FM1l#EoCV"!7c;7KWmR!tOJr!TK^jV)&.lL#2t5!uh=CP8aU=#,;8'WriBT!rrE-EX&QH!tp@kg?/PWdMi8hRg74DOokpn^Dd8#Xp3WkmfP?t[i5E7ZR*m&^B4]FrYkqq#g+q(]U&_E!uh=C"*ObK=T\l?!sS?"1FMT0"*Yj5!s+nc6*CA0V#qY=!uh=[EX&QH!JUfb"#'q;/-?*O"'Vl1"hOjU"hQ;f0FIu;!PSXl$-E?K#L47j#k%teZ1e?Edi/Ai+4^Mu#.jt9#/bg5;`Eh@!sZ(6!sYeW"&fGb)ZqL__ZL+t!s+#Y)Zq7s&Z,`$m/o$ML)U4?cJLD`WWRGGdi/B)MZNMU_ZMRs""XNY!s-12!P#<P#.k\CVZQsr)Zp,uqZ@%dK)pT/$O"`[K*LWq*s[E'!s\W)qZaArEC8jmecQ/8#5_=_"*jtN)Zq/%#-.d5G6-+k"(^Qs!skY@"&h:I)ZpP$mPAdjLBB=6!uh=H!s+5X!s@!k!J:TWZNCE$!s+#Y-jH^S"L\N@VZSU\)Zp,m'([(>j'E1iUB[b)VuoBrNWn/<4MLt!!s9JEZZ68NP6T;:UB<1S""XNY)ZsQ9b6%m2UB,uO/dBc/dfT\l#2:O1;]=d#"$Ngi!sJK?!J:Q6P61oFRfS-F$Sn"O"cEI:Oom6;!uh=`)ZsLB#+Gh2G6+9/!Ntkn#(misK*LoL`Wl;@].aTs#D3*_#4hkJo6CE?#/^NIVZQsP)Zp,?])r)W6NMfD!s8bF#.kff#+G]l!sKLE)Zp;Z+m&k_41>;jpB)?:c5Qj@(5amM+dW:T#,<+>(lf$:_ZL!\#/_hnK*Jpi!sFeg!J:To#0R4_gMmp^$f1siL<fs#!uh=C/-?*o!OS0q!s9JEZZ68NP6SH"UB<1S""XNY)ZqA[!s>(r!s8WE!sYNDX&B1V!T!n_!sZ)1UJh3]")$d$#,;3rK*Kd,gBPOrE@&='lN7@')ZbQq;$PbW!s8bNmK57*[f]Pj],LhR$SL!6"fh_Z"T'_PK*A:X!s6pP!J:Q^V?7"6Wrl911FrV3"&i5&)Zr-f!sm'P_ZL!L"5ZBN,F/VY's7Ro%b:p'#dXPg3!0HP"':Nc#.#'a"*XqA)ZpYgb6%nEUB,uN"k*PW"ks'10FJ*1!sQjM`odFTK,Xmn"mZ6mkQ:j<NWo"TlN74i"Ht5;K*CiK!sk(k!J:RQ"#HPO,`2[C(rdKs.]ioeA#BEQ"Hsc,K*J(Q#-.h,!s8N*ZZ68NP66ODUB<1SP:Qe?#,;8'WriBT!rrE-!s+=8VB_-@!MqRY"$uqhRf]0#G7(V["!#8^!sFf,!J:TO!sYe.WriG(eH9gr!uh=^7KWhk"euUO1G/s&&"=!N#3u;\*p*X,.H^eT"Hsc,K*K3q#0R)L!s8N*drGZ9#*WX'#/^NsiWC_6!uh=Zaj11/LB@td!uh=u/-?*o"(T@R5N`+f"kssuK*D,S!s4)U!J:T/!sSQ(UX'$3Ri;G1"I9,o!sFfd!J:TO!sYe.WriG(`rg>d)Zp,$!NYqsJccqodi/B0.[C/?!sR^`"&f?2)ZrpW",7'X#+I:S;]Op%`WHF?#-1ZZ;ZVUT"n`(h[fN?.1DJt\NroEZ!uh>c)Zpi?1Cd9CPb/$_!uh=C/-?*g")a_5]*+]EG@Q[<!QE@e!s9JE!L=#W#f?`HlN--8M'&#h_`Y@.M)^e,lNjft"#pAg!s+CJ!p]q-o)Y$W$Nl+bL'%6+K.mZ8$Nl+c'TW>MJ$0dnV)&8J/YrOM#MpC%5E?#L.E)C5#)aE&K*Kd,!sZXD!J:U2&'bC>`re"')Zp,*o)f0NMZJG6"oAB*o)f#G1I_HM;[):c"!4!8_ZKu[])tD+`\[c'^'M=QXoXA(mKg]uZN5n8!sn2u,bbB#"T',?K*@/8!s>"n!J:Q>Sc].cMZZm'""XNX)Zp07"bm5f"#'qC/-?*OXoeltl2sreP8aTU#/^NGb6%ct!rrE-EX'\h#0mG%"#'qC/-?*o!stCuL'Ft'0F!^C!sYM&.@L>iY6,^GP8aU6#E&Zg#Eo1@0FJ$/#EoA`Ri_m!0FM1l#EoCV"!7c;)Zqhh#0R4BG6+G1)Zs@J"(d5iedq]uV$>+"^RkT/],LhQV?Zo%qZCgu"%E@s!s,.*!sREu!J:T7P61up!s+#YIKKeD!up\2!sREu!J:To1r]aC#*U_K#0R4o#/^NbNrqiR)Zp,D#*&no"#'q;/-?*OUB:X_!s+#Y)ZptX/VXP+UI5B_UFGU:#bqb5#P/hIo*<i8M'1pcWs@Yc"#pAg)Zp;8rA+V[f)p47)Zp,N#.o$8]`VjKr>Phm1BYo8",?s``rd7_L)U4V@@o=\8`'Vo#NHa*0FIoa!eUN;hB)fO!fI-iGc(X:,G#hV1J8A`;\+Tb"!+cO#+G]6"HtA=K*IeI!sRuk!J:TO!M5>SZND-KUFZKONWufo!s<N[]-mli$Nl+f!sYe["&gt0)ZsL2#4;]%"#'qC/-?*O[K?`'\cYk8!uh=V)Zr74*p-8m!Mp"4""![D!sJK?!J:QV"g\:u"hOef0FIpL"$E1X!sYeFZVq<n43dp4[g&U+!N#rpMZX+ZgAup1"d9#k"e,OF0FJrA!sOSbL'<JdP;!@H$Nl+eecR]^f)nqb)Zp,1h?+%YM??cm!uh=sPBI$1#,;8'WriBT!rrE-)Zp];!s4)W!s4+(!J:FE;cWuV!uZ[m_ZKu[!s:mr!L=#W#jVZf!Js"s#fAOV!JrM=#jVc&g&j;:c5Qj&bL\NW]`WHZ!uh=C)ZpP1o)f0N.fk8+K*D,S"nMfs"#ECK"&fDa)ZpG!o)f0N9*'YKK*D,S"nMfs"#ECK"&gB*)ZpGIMZX+Zo)XIJ#*T,m#+GXG;\8p1!sXYc"(q]e1Bb]:G6,UZ!QCZ5B>5Af#-11a%A*_-#-/[F;ZhaVZNC@-])dNgUD/Fe#/`,!0FK\n!sZ(6.DGs9"#Cku"&f6o)ZqMgMZX+ZK)pT/#*T,m#+GXG0FJ'0!s45[#4hp9bl]L!V],^\],&\#q?$s,!uh=O)Zr@_o)f3WZN5[_#5\K,lN70?""XNY)ZqM?".fTN/?].S&X=:;/HZ9R!ug/$1BZbY"*Z*:o,@c@UB0Z`!s<ogL(di#)__X%0FIu;$Nl,.",8<[cN>j/ZPruo^'<U%#4lh";^7;)!s8bf!s[e2!J:U2!M[mBk5uY*)Zp,,#0R,BG6*GZ"#RCfSlOYeV$>ZZ&H)\3MZXn#q^_gR#)`Qd!W)nMK*IMA]8m$p1E-Ds(E;1"!tV[>b6HE7JPtY8OiIP)!uh=C)ZqS)"24g5U'!(W!uh=JP61r_L'4OX1GB1=;ZrBg!u-FkIP\_X!s,5S)Zsa9"3)Ye!Mp"$""W(-c6gRN!MqRS"$Fm3!sJK?!J:Q^])r4p_Z>An$PV(p"g\:b"T'_PK*AR`BX\'E#5]>A"iCPVqZDa/<sHhT%uUX]dqoK94l-8Fb6%iF#0SD!K*J(Q!sFeg!J:U""!b8WT/.N-"*Xd,)ZpqWjoYh"#-1ZPV?9]iL'Gg%dkD.3$Nl+f!s[L6"&f?*)Zs"<#-.h.is)i1R1$n8qZZQlQj/`a^&c+P$4aBC!sYM&0]`Bf!eVEo0FKf4!UBcM1EQ[N;[/6a"!Hk2X!tb%!MAfb0p_udir^5&1I_HM;Zi$^"#5Q5!sFf,!J:TO!sYe.WriG(k6#`/)Zp,V#+H+j!Jrdj#+Ha<!Jqu.#+IE/!JrPn!JQ:2#-/[F+RK<O-'\RG#-/[F$AJbc!sZAW_c$Yl6EUCpWrjSF#,>$"UDO(8#)`Qf#+GXG;^(9*!s@'U!OJ[CV)&>T/G0)G#6#PD1=ZSuH(P1_"Hsc,K*K3q#0R)L!s8N*drGZ9P6H[FNrq'?)Zp,%#-J0R])s_p""XNY)Zq@c+SGmn2hqK6+5.Y9!s^VO)Zs<J"P*dp!KmZ1h?*u*#/a@AK*Kd,!s[K\b>SN"!uZju"9&=uG6mXn!L21<!s9JEZZ68NP6-ICUB<1S""XNY)Zq;/#*s;e!Mp"4!se8s,_Z=>#,<+>#3uJgh?LS:$O43F#.k"u"*YNW!s+1tJYrShq\oV<#4hp$LB@R0)Zp,F#.krU"*YdS!s,KY?2"F?"MPfW3/%R;"'#GI]*I13G;/jt"+&Q$ecR]IcN@*3WZ)$Q1C)JG'TW>$V#qY=b8UO9#3,di%.aLP!m;%*RfU\b<sIsn#O;Sh")SS/-jJ]6dfTg7!s+#Y)Zr@?)O:J`!o#C:",d6PXogI%VZTj")Zp,Pb6%m2dfG(*#1EYV#/^IoK*L'4#e^<@"kssuK*CiKqZC=/!s+#X7KWhc"$W%R!sQR]"%ig$!s,Nj!sJK?!J:T_2Qd7r#,<j[#.k)O/XHP];9p0`V)&@J*L['2+lXFC#.jp(]`S;3NuJ0?1BcQ&cN=3E!uh>aP61u`c3#j'mfQKBmi)?LWrq4+!s,5&)Zp+p!sQ"5!sQ#[!J:QV#4;RL0u=#kqZ@c>"XgDU"+L7PWu17DG?U=;!J$L="Hsc,K*J(Q!sRuk!J:TW$[)`\ZNcUI*sT%U!s@]g!s[L!"&h1^/-?+"D?C*D'UJo#:QHFs#-.gNiWB4X!uh=aEX&QH!epoc"#'qC/-?*O!N+HN#.#6N)>49pir]C'#3.*9K*Jpi)i=^u2!,_ZWilWENrsS,)Zp+t5->(\"04*`"nMoXSc^bjh#gS>!uh=r!s,Kq!JY)'@iI*0L2.l@F"dt(0FIu;"*g^Gp(G+ZV$6HOVuHi"P8aT)#.jsA#/^Io3!0B.[g'GHP6$IX#0R)O#,;3OK*Kd,gBPOrE@II`lN7?t)ZbQq;$PbW!s8bN!sFfJ!J:U""!H"o!sFf,!J:T_#.k)7!s<Nq_^G`$$'kYt'Z'rN..S;ZV)'ID\X*C!jr4C''uDa/M:ViRq\oV<#.js?#/^Io0FK1m#/^Y/b9$r+$RM)C)qkBJ#,<+>UNlqD#*T,n`rc?pP8aTf#/^NGb6%ct!rrE-EX'\h"%JUZ#,;8>hZGD3!uh>+!s*q=*YeGiiWBEAVAfUu*h>(g8`'Vo!s9JE!K%)VQ3.>l\cYk@MAlXWWs5.$r<!9/!uh=a6O:R3#jVQp#DN8F/rg5'089La7BQp6#dXPg3!0HP""M=ngD.%6WY<Pm!P5H8#;\9P!L8EB"Hsc,K*LoL!sZ@<!J:UR6A>_t"#'qs!s+VCdg)'U$Q7,";a(:>!tVsF"QKS'N<;WP!uh=`IKKf/7YV,JX$m6IgCN-F`rea7!uh>i/-?*o"&kNg(u595!mV_eG8,Wb"$c5VN]-PL!s^Uc)Zt3N"5Xg4!Mp!i"*h9WL'Hr_gFs!;*l\9d(S:e.*VLES!JLJ/L5,kTq\oV<"e,Ss!kSJcK*A"Pjoqdd"#()h/-?'F*:<nb&ul%41Cb?+"*Y*`)ZqA1ir]FbgAup0"R?-jir]=7X%!0o"QKRe"NpguK*:KB!g3Wd.aK%9#+Ggg^B4M5RMu>]1BEddrrW:u!uh=r/-?*7"jR=1!S]:9#)`\<&)RI2#)4'!9Xb5<'nQO3#/_A^0FIu;ecQ-"]`V2!!uh>%7KWkT",7$?#4!rN;ZWHl"#IUmK,jk0G::cB""DOuZNd`TE@&='[K?`O#.%59"*jtN)Zs0.#jVQp!s8RiQ9tqqrWpCFScOZUrWqgYScOZUjp8jYZN5n2!sn2u0<t[>#.GNR#;ZLS"$W%R!sYM>X&Cm97#h?R!sZ)1UJhDp""LDW!QtM@0FJ$O#*o?I%(uaAUB;G;X*t-T$OF0FSd)MT"#()d-jH^S!tg+eWs%8uG6Wp/"&G6c!sREu!J:T7!P8QbK.[4`P7F>r#(ot]#E&u5L'F,a"#()b/-?*71WBMQ!pp(g%A+RA#+Gh2%dF-$#-/[FNfOD,hZINm!uh>T/-?*o_ZL%*!s+#Y!!<GK#0R)N^'<%o0F!^A!sZXF*N&uj"#Cku"&h;,)Zr7oZNC>oUB,uO/dAol])r.TT*$JG)Zp,=#P/$"#Q"Tj6I'!A"0Mp)`X&=b6jTPV'8?dfUC.@&q_4<A#gPjD5.1^f#NGiA3!0Ge")\&?#g3;h!s;s6Q9tqq[Kt%[c2ibKjp8j[ZN5mn!sn2u/AD9H#2:(!0FKtV#1Ee2JH;=f%]og6rrX2BVAfUQap3P$eH:"ZZPs!&K*odB!s<NG",h=)K*LWD!s[K\!J:UJqZ@&/!s+#Y/-?+BlN76I!s+#Y)Zq"iXoem/Mb?tLEC8jnmK3]`#E)MHMg5C,#5\K-ao_Zsef+];RKg)"[f^h)di/B;b6+=?^B6.o!uh>`PBI$1#,;8'WriBT!rrE-)Zq26&*"c/"(E@Y)Zt6G#E&emRrKg16N.&l!sa`G#E*j0K*R#2K"hBg1E-DsBJI(f!u^q;Xp+A8!s^Uk!s+4uEUNuKQbOIA1C(VprrW:u!uh>C7KWkTL'%X\#*Vt@K*L?<c3ES8"#()c)Zp\u#DOW#mfNeNq\oWT"hOj>!il?SK*B-pecj4t"#(*1/-?'f""_IpmKV,Z__;H#dg"8*#2:4(dkD/9gBQ+2b6&gjb=2R<$Nl+f$GQZsB9sP>/HZ9R!NGeq#G)k:G:CBb"$4a1#-.hF!t@>i)Zt#^FoqgK!sR-UL'?%/gFs!;$Nl+ejo[CnT*&"3ZPru`#0$`L_ZIGK/cpY5!Lj;*!M'J]"1&<7_fS5Z*p*P/WWoe.!N#r](S1^b6'VONNrp='h\uZ,!KI2D!Mp"$!K=bq!s9JE#*X340FIu;Rf`cib5m5"#,;8$#-.cW0FJZa#-.pn"!7`J)Zpb5Q3.Au#J3n<;[:#=.gMOG!s/:H!J:WPQ3.Amf)nqTRi;GA8WO>c<4;sC!s9JE"#G*&"&h@s)ZpA\1qs=FZPs21P6SH"UB<1S""XNY)ZrBsjoYmarrZ1?)Zp,9#.#bm"*Y41)Zqk/!sZUEdgC^H/JRLVh?*u:hZHe*!uh=K)Zq)QQNkV8PlhJE!uh=W)Zr=,#-.m@G6*NO!t<]^^3[g=V$=Oo(%hY0!s9JE!L="\#P/$"UI4`BUd4>R#bqJ&!sLRF)Zq\Jh?*u"#0TpIdo0i\"5X+a,1coq"Hsc,K*K3q#0R)L!s8N*drGZ9P6-ICr<"_X!uh=h6O32b#b(nu+T;D-#bqs6#bqKM!sLK_)ZqDO!sP.r!sJKP!J:QFUB:[`!s+#X)Zs9Q_D=EJ`rgMriu8(g#D3*_o)f#G""XNY)Zp>[!sZ(6.?=Q^#2:(!;a%hs"#Q>H!sYeFqbmTW#."C7"j6q!K*Jpic3D/e"#()d/-?*_"";Itr]m"n#6q43!s6.<qZ?p>"k.JqK*Hr1"nMfs"HtA=K*CiK:8\0p#.#6N-\_ki!sbT@P>ap4Gln-RMZX3JWr[hX#5/-'H^=h5RKFK2!uh>0/-?(9ir]J>'*3^hK*CQC!sS8s"&fr[/-?(9"!l"k[Q*Ok#6pXu""Ltd#,;8>!t?4G!s++:#4hp9%0;!O!JTtEP62a+qg9n!#Fber#GV<P;[&HhNWTNejTAE^!uh=YZZZEQmKUQ5#1IQ.;^/(@!s8bF!sXs7!J:U"!sn`*0]`BU#br=@#bsZa^'LK%$OELY1%#=BL.)B;NX,/,irOu_!skq47*brp&<.V2V)&@j$0hTn#E'N'#0R&8Q3W=%70_cU"%J%Jegdd@#6qdG"#cSMXogI!Z3+#-iYqtH]*F?8!s,5&)Zqh8!sZpN!sJKP!J:U"-dDqFpB*)WUDj:p/dBc/dfT\l#2:O1;`=%G!sZpNS=]m71E-Ds;Zrs"!sOG^#/^N^mfP*C)Zp,/",7$/#2:g>0FIu;Sc]1tU'"<tP8aTJ#4hp"#3,`:K*M2T!s\&l!J:W0"";S"Jd0+3!N#rW-I+L6!s,5S!s,'M#/^N^`rdjp)Zp+u16r"u*OPuJ*L[oL#-.m`q?$bp^Dd8(!sZAG@eTt:b6&[c""XNY!s+kB4gtM4"kssuK*K3qh?M.(P;!A"b6H,oh#e`'!uh>$!s+mhNWV'VjTAF=V],^F!o<s2!Mp!i"&>`r#E&['#-12q;a@Jf"#S^6!s-Ra!J:U"dfTZ8gAup2*L6d3b8VC!#0TjJK*IeI!s[3T!J:TO""Vt*p'07jBLAd`"$O[,V@r>:V$>Bi-/AY(!s9JE"%*=b@06c3#br$h!M_++7Eu16UI5B_UC4dA#bqb5#Q$6Yo-ph2M&#.XWs@Yc"#pAg)ZqJ6#P/$"#O;IZ#+IFO$Hi^MZRUuQ:d2#c#Q"P6UMgC\UGB7`#bscn#brEc^'LJA70i,j#P0GE!Jq6!#ce3j(BZW!Eq^LTV)&.<(\\"4+.aDR0:`:,7@F=&#+HP60FJ'0#+G_,q]?$3#,;8'#+GXGK*J@Y/%5T]#(misK*Jpi`Wj<]"#()e-jI9c!JZX;&DA'*V)'Il'tj\MrrX2B!uh>=/-?(!#5/-T7_Jn&_ZLh[P:Qe?#/^NGb6%ct!rrE-EX'\h".f_G"#'qC)Zp9'!sOSb!sOU3!J:O@!sOSbech7d"#()n)ZpQD(X<5s")&,&)Zp5^#0mG%"#'qC/-?*o"$s$klNYfW*sV$8!s[cf.(TLM!s9JE"%*=bQ3`r^UBT3LUE[,PNX2B\6jTP:/>`]JUC.@&Rl&t-(VW<D7,A1?#NGiA3!0Ge!u^J.#3u@1!t@ot!s+=H!s7d-!J:RQK*$Q*!s+Dd7KWhk"%9$hRf`a3!s+\n6O32b%F[;^UEgu%UE#j2#bscn#broYrWo8,70oA@#P/D%!Js1@#ce3j]`U4rgD^5-,`Vs2#0R*IpB)rK)Zp+r#.js>!sZXk"&g`$/-?*_ZNC>o])dNg$QQkb!s6Y"!J:Tob6%sD'*3^i;$Oo?!s8b6!sJK]!J:T_""gDQVHrX0#7#l-!u:)'#eL0X!s:@^"%*@3@06eY#eL8+!JrD*#g3C;!JrD*#fA4]!JrD:#jVc&XTLNbZPruc!KI6e!scG:_c$`)"GR!`#GVB"!W.6pK*SFZ!sc.5]2Jm!"dT5q!sc_Bb68'8"dT5qWrjkN!s,#!*!_Z0Rf`i;qZ2<S#GVA%pB(GKRi;G@],n!_"-XQ5+,_20(mb>(])ruS%3D,G"%e7Mo)f(6lN9KZb;9;+Rg>bi+kCN9"I9ASis3IuDZk[p2<G1>UI5B_UHbme#bqb5#O<+ro-q[JM)2"6Ws@Yc"#pAg)Zqb6V$<DahZJ'B!uh>>)Zp>6"#."_]+W+&G96D]!sm3T`WJ"9]`V1Y!uh=N)Zq7UUB:X_!s+#Y!!<G+#-.h.Xp24Q0F!^D!sYM&6(J*/"4J1kK*Kd,!sZXD!J:U2#1EYV)WCiIeH6`mhAZPGdKZ`R`rgNC],Li3UB\=2%]_2m#/^T@P6@(ND$KS5!sZpNb6%hH#1ISs#*T)U#/^NsM?>C3ZPs!.ZP8E(#.lPn$KD;J%%@9cQjX,a[K48H$4imR+1;Bk",8K;'*cWQdn9o5VZRS:)Zp+rpBIAp!t>9l)Zt;nir]M''*3^i;$PbW!s8bN!sJK]!J:U"2mrq>#/`,&#1Ee*[KbJ."#(*A)Zt*+)TFCj!s,5S)Zq2$!K>n<#Fue9#;ZV!""2+kL''4NhZHe3)Zp,("bm&q!R!/)0FIu;",6j*WWOp_U)O1:1I%HF0ZO8#"Hsc,K*K3q`WjTedkD.2#1EYVmfNTC!uh>eHn,GSMZX"WP6$:@"dT5q6/McC"kssuK*KL$rW^gP__;H*dg"8*b6&gj"%E@s)ZqO`!u."&!sZX^b>T@W/Cjn-!s[4Q"&f9@)ZpW1!sP_-8u2V@#/_A^;]VG3!sZ(6!sYeW"&f98)ZpW)0"(u=#,<j[#29?g6LP!u!s9JE#.&ITZS2c1UB[1lV#qG:di/B\#)`Qd"02HTK*IMA#+G\q*KGRN27<^YdK9N,],Li.#*T,l%a+m*"iCP^RfqIuPl^1Tdf\n:8Hm!;#+J&I!Jqtc#+H3Z!JrS7#+Ij6!Jr$"!sXYc<Wb-/0&ct3-\<9>#+GbPcN=3E!uh>b!s+OfQ7MMFV$6Gl09$&7lN8(."#L)b6O32b#bqWbUEheLUGVBE#bscn#br<h[KrW970i-I#P/r/!Jq\K#ce3jVZSm\lPfqLGln-P!sR]eV?8VDr<#t$!uh=lEX&QH!epoc"#'q;/-?*O"(:j*NaVT#V$<tO990/U"#Cku"&f;f)ZsH^"$rI[N_l/`V$=g@32-KU"d9l-"cEM<D?Z4M"d:VJ"cEM<ech6`"#(*K!s+2?<Wb,s""+0Q]0jFS1E*+p"&Hl<#g3;hmfP*CWZ)%`#;Zic"%hq`!sXZ&!J:TGUB:^aWr[hW+P$W!6BVFL_ZLh[!rru=+Thqd!scLAc3!h]V$6H6NOJujP8aT)#/^NGb6%ct!rrE-EX'\hP@b$J_ZMRs""XNY)Zpr?1tFD=!Mp"L"!jcHmKV,Z0F!F<!sZXF!sFf=!J:To!sZpN3R7d-Nrp='^)I/:rs+/Zf)p4\!uh>=)ZqSL"4d[_"#'qC/-?*OSc]1dSHDe=L)U4\Mm"oBq?(pB!uh=o6O:R3!slL@]0V0.M&5jk_\.t1M%>UPlNjft"#pAg)Zr>!"6M<!!Mp!i!u:)'!W<*>!s9JE!L="\#P/$"UB.MbUB-qlNX2B\6jTP/-LM/7UC.@&Rh<XG.^hbO0ocM1#NGiA3!0Ge""sTU9q;A*#.#6N;_"@@p&bNJWWQ00UDj:MUD9(##bscn#br'1Sd;)!70o@i#P04,!Js./#ce3jZ3*&giu8(K#0UT_:7hVBUB;G;P:Qe?#,;8'WriBT!rrE-EX&QH!JUfb"#'qC)Zp8'!se]*o)f)'#)bhR$*so4Wt:#':^i'`"4IXYUMgNmUD1uZ#bscn#br66rWo8,70i]8#P/SB!JrA1#ce3jSHChRmMc6k_?R%G[0(V4!uh>)Hn,GsWriD"ZN5[`"dT5q!scG:_c$Sr$-iVX!sd"J"&f<Y)ZsiA!sYe.WriG(#.&=S#*T/?#,;8S"HtA=K*J(Q#-.h,!s8N*ZZ68NP6&r5V#rCUUDj:m!fd?e!sYf)ZVr+2"L\C:')r&4"Hsc,K*J(Q#-.h,!s8N*"*+UHWuD-e"dT5q!sc/2]2Jm9"dT5q!sc_B"&fAh)Zp-+#.k)'"*$>u7KWk,!sS?"L&plbq_/B[$Nl+a[KA<>o`J+u!uh>8)Zpk]"#-8JScY)p1GB1Q;]:r(!uRI/)#==R!s9JEZZ68NP6UFZUB<1S""XNY)ZpBB9B?AqScP\j.+0mS&=3KC"T',?K*A"P!s-RG!J:QV4QZgRUB<1X1FrV3;]5Q:!s@WehDq,G!MqRd"&n@b%QiA`!s,6>)ZqkD#G*ZmQNIIK!uh>Z)ZrBs",7#L#,<j[0FIu;L'%X\#.%50;`r>-"$tWCp'.Q:70_Ku4n])\X$m6IgH+a,#-1/s#29pm*Oc,>_ZLh[/.MI[_ZL&=o)XII"j6uL"k*L);]aKl!sQRE^'2D*q_/BZ"j6uN!rE"NK*B^+Q3H"D"#()c/-?(!#.=Ui7_Jn&`rd7_!uh>YQ3`r^o)f'q.ult%)o`/Y#bqEq#brKumKfRU$OEL?4,sTAQ:2(KmK`>AirOue!skq4$F^*s#4!31V?9>L1I-s$"*ZZ_)Zr`mZNC;fUB,uO#.jsA_ZKpl!L!Ti!t(Y&#/^N^T*$VHoc!uC1BYWMOok`]dMi8u])ouG!s,5&)ZtK&"!?>$mKU!:0F!^D!sYM&!sYMOX&B4g37\09E9@=%*qL<Q#h'!9#K$S0+57@]is_,E2[?An"N(?5gFEeu"nMg""(M@a!J:RQ!sS8u!sRFK!J:RIqZ?kO!s+#X)Zsrt_ZL%*!s/B*!!<GK#0R)N)p/8'"#Cku"&f?j)Zq=Z",6o9"-YDH0FIu;",6oI"/@OX0FIu;",6oYJcd\7h&?GU!skYb"SDjKg&i8r],Lh["dT5q!sc_Bb>ST$"dT5q(s`:_hZFf")Zp+l#b(nu!s8RiejB]6^'LJdUB.+jUE%Pb#bscn#brPtc3U0Q70oA3#P0UO!Jq,k#ce3jRKGMOV&KLX1BR7m*n:>t!s9JE#-2nL;[;Fe"!Yki!skY@"&gQ')ZpJr\d"o3h#e)g!uh>@)Zs9I""1JY#,;8>!t?'-)Zq1QWreprZN6'h$Nl+dL'5+B1GB1=;`j+D"'Y^,Sk#4g#6q4?")d9(%fZVM%)!S^!MqS1"#b`5c3D`:0F!F9!sZXF!sFf=!J:To"$4*tL'<b[,mB20"m,uP"d:VJ"cEPM,520c!s9JE#,?>D;ZkkY&`*_mjT@1Eo,@cA$Nl+eQ3/osdK<E$WuD-q]a!U'SHEOfP8aTK#,;8'WriBT!rrE-EX&QHP@b$*UB<1SP:Qe?#,;8'WriBT!rrE-)ZrQm/_2,T!Mp"d"%B[$lN75.!s+\n6O:R3#jWkP!Jrko#f@.t!Jqr-#jVc&P?8@]ZOW0$Y6/JKRi;G8blt6S\cZUtq\oW("cEHc!m:UsK*@G@echND"#()c/-?'6"%9-kmVS"(#6q4G"!.CD!sJK?!J:TO1>W59#*U_K#-.s/h?L;."#(*<)ZtJ[#OY!K!s,5S)ZrRcMZX+ZK)pT/#*T,n#+GXG0FJ'0!sXYcmK56r[0'>l!uh><1]n#q#f?`H]/IAjM+3L2_`n&#M'TM8lNjft"#pAg)ZsH^Wrigs#.#$K#*T)U#,;8SjT@%9VAfUkhZhO3U'#T?WuD-X%BD8cRh)PP<s>o;$B#&aF);&4K*AjhjorX'"#(*(/-?'^!JU\46Ce3W"kssuK*D,S!s7K`!J:T/!sSQ(!sRFK!J:RQK*)2@!s+#Y7KWhk"$VbJgBQ+G'aCE;"%i.f#,;8>Wr_eo$Oj0Bjp&.G"#(*+)ZpPI!sZ(6Q3/ooiWE*\di/Ardf\G2k5u(rMAlXqdgO_LhZF)f!uh>@)Zs]m!s6mQ``)^Q!s^Ub)Zt3N7^WGqP6%N_#/^NGb6%ct!rrE-"*,%W)Zrrk#0R)N!s[4&"&hAN/-?*o!smcddfT[k#2:O10FL"7!sZpN"2t?n])ruS_gV[l$R"jA!gj'D!KIB-#0R4g]+kO^#."C9^B4Lh!uh>1)Zr.\_ZL%*!s+#Y!!<GK#0R)N$g.V4GNTnI#.m:c\cVu0jr4D.2tAa,36_PL"Hsc,K*K3q#0R)L!s8N*"*+Uh)Zp1r')ht01GAmb;Zj`9"$(r8!s8WE!s-Sg!J:TG!sYMVRi<"Cf)nkSdi/BU4QZ_M.d@+7!s9JE"%*@31]n#q#eL8+!JrA9#fB$\!Jq*M#jVc&LBBL<UDj:S"#0!EciX<GNX!B%@CH=>eH6`m!uh>J)Zr'oT*D=u_?15b!uh=d9:lE`6EL>!_?1_ZiYqtY1BH'*^B4M5di/BrP6R$O_ZMRs""XNYP8aTj#3,di#.jngK*LWD#3,ddN<;WPb8UOe$O*s@_ZQqn*s9[g"*<?%7\p.I#."Q3^B4M5N>hsU!skYj;>gSK<Q?$\#2:KM`<-.;P8aTp#/^NGb6%ct!rrE-EX'\h"-*T7"#'q;)ZqOs"$!src3CTo"#()d/-?*OUB:\SRfS-G#-.h1ZNC5\"+C=V)ZsQqo)f0N6NMfCK*D,S"nMfs"#ECK"&f?*)Zs=+_ZL%*!s+#Y!!<GK#0R)NmKV-\0F!F9!sZXF/`-X]XTKLEb8UOF(qp(V&,cT/!TP+$0FL(90[9bV9D&Bc!s9JE"%*=bQ3`r^UF2'&UF*\\p'@Do6jTPD'^c7%UC.@&RhYi-%A#uo0#e.f#NGiA3!0Ge"$3mn!sREu!J:RQK*)/'!s+#Y7KWhk5OJV07u[UL#.#6N5e[J]!sb<8Mc2p5Gln-Rir]OE!s+#Y)Zrd^$GIRP^B4]s],LiL0FN%.#,;C7!u2$HP62$$,D$!u!s9JE"%*=b@06c3#bq^/!MfbiOpIfbhZF#oPoBf+1BQ])3nFH=9Ca#(#;ZU>"!E:"qZaAGEBq5Bh?+"@#5_=Lqfr8G#3u?qh#d\1gD^54"nMg""/>mL,R+&I!sS8u%cRR[:RW4)#-.mHQNI8b!uh>3/-?'V"muIK*Vok:"Hsc,K*J(Q#-.h,!s8N*ZZ68NP6(@]U'!(RY8[Q`dk8p,!s,5&)ZpoD1Cd:9Z3(-(UDj;D6H0*5'7p<b<lu?`V)&A5.,k=0"KNIDK*:3:!s?.9!J:O@!sIWdL'6O+lS&\K$Nl+dL'7*%q_/B[$Nl+d$FKsi!eqWr'*cWQ#/^Y_L*HoG#0TX?9*0h]!ttmf)Zr;&"!d(5!s5eJ!J:R9lN74co)XII6LFpZ!s?_F!J:RQ"!bqj[KXPf"#()e/-?'^42(eQ$KV@gUB;G;""XNY)Zrjk!sZpNb6%hH#1ISs#)`]R+NFR<Jccqo!uh>"/-?*OUB:X_!s+#Y!!<G+#-.h.7$e!r!s9JEX!e1QL'F[_#.nj^;ZhaVXoemG"!^`2UJV5r(]sjEP62#aUB,uO"eGf#!sYf)ZVqV4#-J%4T*D&h!N#rt!fdK6"#'qC/-?*o""LDTdfuQd*sU0u-dDqNb6'F+""XNY)Zs0V"$5<AgBPP7E>5P[P9URlgB1:ZLd\u^!sZpL"&gSu)ZqGU""9T?!sFf,!J:U"dfT^$UB,uO#294a!s8RV""42V)Zqh##.l))"*[&5)Zr=A*r]^-!s]%B)Zr[N_ZL%*!s+#Y!!<GK#0R)N-3hq>"#'qC/-?*o""p,H!s[3n_c&dS)U8Eh2nB)i@/:fE#-.mH4P^)E"Hsc,K*K3q#0R)L!s8N*drGZ9P6-aKWWOpZ1E-ER;ZZ:g!s@We!s8WEA#]WS=cXL(V)&A-62q#f\cWlRjr4D5f*8hgN<=AKdi/B="g.q4#I=M2!W.6pK*T!j!sc^Eb>S_m'rD'<!sd:R"&hG8)ZpJm7`GY5X$m6IgBuL9#-1/s#2:p4L'F\I70_L3"#9`Vo)f(6!s:mq!L="\#br*BUEg3'UH.0:#bscn#bsN]V?iq)70oA9#P0=/!Jr4Z#ce3j`</(%bo6aA1BPj+jT>O[M]2aR)[jppQ3/osf)nr)ZPs!&+T;HI!sZA9X&B/H"&k6bncJoiq\oW@#5\K)!QtLrK*R#2M\lNs!s+De-jPA,!s\W):RqSW5K=]F#0R5MM?<mUN>hsUo/P;K!s,5&)ZqG;.gDaNo)f'p#,?2LK*IeI5_fFBUB;G;%5P3n"'YX*ZNC:K#.#]^K*J(Q8+H`_"#Cku"&fel)Zq(f""hXt^/_0P#6q43!t^4ihGNYZ#6q41""fiA!skY@"&f6G)Zs]@`WHF7"HuagK*J(Q#-.h,SHAioRi;G55+Vi\!sFfd!J:TO!sYe.WriG(#.&=S#*T)U#,;8Saoa0sP8aT[$QI@pmK57!k6"XI7N2F`G=;!X""D@pekP]SV$=Oc1R\CH!hL>5G@[$r"'2E(!T4&!!KI9RqZ<\u!s+Da)Zpc0ecQ-2"HuaeK*LoL!s[3T!J:UR"%C'/!sZ(NUJjCc!s70\M?<mVlPfp3$S9j5L'I6'.kh>5;$PJg])r8d!s+#Y)Zrpe"!W=!!sJK?!J:UJqZ@&GK)pT/$T3qL#4hpN`<.XnWuD.+$O4$?UB-Q4*s&DC"'LZe!sFf,!J:TO!sYe.WriG(#.&=S#*T(B#,;8S[0%r^QQ$$/1BH&]pB(Gm!uh>?-jI![#.mMT_b4STV#qA8ZPruL$Nl[s"/@(p1EQ_*;^n"7")$<i!sSQ@1K-!a;ZkSQ"!"]N!s4Z*!J:K\!T!pj"2cf#0FL+"!s8Y3!s>lT!J:KT"#H)B^(fiO`<NpV4i[X*"5=as0FIu;#EAoH"#DV="&fEL)Zrm1[fZ^7!sFeg!J:TW#."N/!s<Nq]-mli(nLg6#-.i)#-09W;[2Xl"":PZ!s+l1!J:Qf"4dXnZNDlh""XNX)Zp`Gb6%s<dfG(*7IC6^b6%iF#0SD!K*J(Q8&#-,!n/(j0FL$u$U+XHL''4cSHDdl!uh>;)ZpQ:ncnC^WWN].],LiG$U*VVZNd`i*sT=]#."N?"*#c])Zr+f"(.T$!sYeFP>aZ:#E&Zg#Eo1@#5]Xj?3crR#EphL#Fbs^#E&[+r<#Lk!uh>I)Zp58o)f2TP6$:?isN*p&$%;c#5\_UM[%(#D%Gq:#0$n#o)gZS""XNY)Zq/+^&nY9k6"XMar:FU1BjX[!n@AXqZ@c>qaLYk$Nl+eL'E8a"#()b)ZpA_#DQo_XTJeaq\oW4#HIq-#I=G`;aL*ZXoep@#K'IP;[&HhNWTO0Wrl9$qg9n!#I=L5Jcc%+dMi97dfuZ^!s,5&)ZqbA"#e[3$O4Kfo`I_eb8UO?#0R)Nb6%ct"!IaN)ZsNV#5\VB"*$>u7KWkl""O<QmKJdnRkP3R$T$?;Rg#!0V?Mk]Q3EHQRkP3i$Q._(Rg#!0'a9L!0[9iceH7K5U)O1M],CT]!s,5&)Zq.`%*f+&!Mp"d"&IMN!skY@"&fVg)Zq/5#-.um!V69n#-/'RqZk;:$jjNH$.AqHb75!9lO:*."Hu^hCg.5+!JUfb"#'qC/-?*OUB:X_!s+#Y!!<G+#-.h.L'Fu)0F!^C!sYM&>I">^"3VVcK*L?<#3,dd[0%QS!uh>%6O32b!se]*P7#KA/dL\G#bqutX#gT>[K4hb$_nIX"5=7%#bqJn!sKU`)Zp?4qZ@#f!s+#XEWu=BK*);3!s+#Y/-?(I!sR-U)2A;s!g=Q*0FIu;",6lH!i%FW0FIu;(S1^b7u@CI%uhM1#/_"d"j-oP'Up$D$2YJ'!sRFV!J:R9lN743!s+#X7KWhS"RZ@JC%VR,l2qt-P8aU%#/^NGb6%ct!rrE-EX'\h#.=`b"#'q;/-?*o"%)qgD5%+O"7$m.0FJ'(2YI5/)<V*#QNJ0/iu8(]2"h"U#0R*I#1IrE;\,/r!sZXF&rcuE'nmS/V)'Z_6)k"fM?=e"P8aU6$RqAFL'=&#P;!@GMZoRR"cF*!K*:cJh?,P7mfQJh!uh=[/-?*GL'%XL#,>*];]NdZD?C*Dbm'Y9!N#rk/X?[;UI5B_UEfaD#bqb5#Q#Iko0/I/M)*WeWs@Yc"#pAg)Zpl%`WHLAN<<)bP8aT/#/^NGb6%ct!rrE-EX'\h!PSce"#'q;/-?*o_ZL%*!s+#Y)Zpo1b6%m2dfG(*$QQkb!s6Y"!J:U2"$l\bXo[8rj"LiD$Nl+a!UBhA!s+Sf)Zqmr!se,oo)f(O2jQf9*0(<"#bqEq#bs6%Q3a6R$OELn-+4)Sp-f5PQ3[!lirOuP!skq47ZRX2!s9JEdrGZ9P6T;:_ZMRs""XNY)Zs!l!nIRV!uEVm)Zs$u])r8$_Z>Ao$Nl+f#0R*&!s+Sf)Zpk2$H!=rdk1_!UBCB$"Humk%Jp:/#-.iC!s8N*ZZ68NP67B\UB<1S""XNY)Zqt\)^Fc$;832e8b*f&#D3&KrrW:u!uh>9)Zq5GFoqgKh?*tW#-1Z)0FKIm4Pg:KOomBGRi;Gt'rD'<!sbT"X&B1f-C+`=#E&[_!W.6pK*RSB!sb:rUJjD."g.q4!sbl*ZVq$n2:_j7P63=6!s;C*b8^``#D3*^o`G5I!uh=r6O32b#b(nu6LFl?#4;blUB:Op"\Og]"'UQa+IWBOJ--_mNWuNbNWV'<RKHImgD^5Y"lf[g!Q+qjK*CQC!sS8s"&f]l)Zs-@48&`E!Mp$R)Zrt?!T#u&!Mp"4!se8s"ks+u!t@G_)ZqCTo)f0NMZJG6"oAB'o)f#G1I_HM;Z_s]"$Wmj!s8WEjp&G@lS&\S]*>kRPli*4UDj:EZNcm*#+I4J$EF?:"G6`G"-*Pc!sX[*!J:TOWriQi!s+#Y)Zr3n7_LTQ=2b8c!s9JEZZ68NP6C:XUB<1SRk+XG!fd?e;Xsog"T',?K*@_H!s4Ye!J:QN!M0IqZ3)cgUDj;=4IuW\%IXBt-)MU`9WA>M37S+T"fiRE0FJ*Y!sP.rL'=%t"#()b)Zq#L#jVQp!s8RiL-l6aV?lJmh>rH\p'APWZN5mk!sn2u/Cst`hGY?q1GBb""&hAc)ZpW)Sc]2?!R"D*K*Kd,!sQRC!J:U2#3,eI%&3jm%"eV^P6U>*SID7p$`bKQo5l563lV7+mKWPeK.mZS$Qe^@#3,e>Oop(^!uh=X7KWmZ"!I%7L'`JORkP3P#5/-'0WG4R[PJj)(FGCL!t<EV!f-pt!KIABP62#IlN)VB#+G\u#,;3O0FL4E!sXqk30aRs_ZLh[""XNY)Zq:n(Y/es#+I:S#."N?NX!*;"#()t)ZpboiWd!sT*#7%eJeTKRi(QKVZR/.di/B/$Nl+eL'?<cj"LiC%.43$4IQ@N$I'Ll1Bchr"%Jmb-3gdq"#'qC/-?*OL'%XT[f]P1eJeT6*X8ZX61"b1!s9JE"I"!2K*J(Q#-.h,!s8N*ZZ68NP6R$ORKG5JUDj:Zq[9h:#,<OL"hOu6^':>WOp7[*!sYe,ZVq$n40AYi#)*.X_ZLh["Y8jB"";+jhAM@nV$?NX&s<=t#.#6N#*T)%#,;8Sh#f21!uh>;)Zq>H3UQs\!lH]"0FK\V%>+`*!LX,W&'G9SZN6F$K*-i0!n.JY0FIu;",6m3!oksB0FIu;!sbG#!sFf,!J:TO!sYe.WriG(o`K4=P8aU5#/^NGb6%ct!rrE-EX'\h!R:nu"#'qC)Zs97p&bMg"HuagK*J(Q#-.h,!s8N*ZZ68NP6SH"UB<1S""XNY)Zrjka"mmrVZV,O!uh=e)Zsp1""]]>[NX`OV$=OF1q`tl"Hsc,K*J(Q#-.h,!s8N*ZZ68NP6-aKUB<1SRk+XG"eGf#>2fW_E2"9R#+GjPN<93X!uh=[)ZsXD(UaUEUI5B_UH%rQ#bqb5#Q$dCo/651M'`-+Ws@Yc"#pAg)Zq2!!s6%9ZTnU31BEL=;aJt:"!RC@Q8bNWV$?6:1?nrBMZXn#!L!TjecQ,WLBCHYgD^55#/^NH#0R%"0FL%`"oALf"!7`j)ZpPIV$<[seH66n],LhT$Nl+f'*c'&#.mD.0FIu;!uhHVV?8VFPljrO[Mo<9<95n@%#P.2XTKLE1E-En;`j+D"*<`0"cEI%#L`hY"60^blOL6R<sGE/$i:'j")SO+!!<G+#-.h.Xp24Q0F!F<!sYM&(UjJt`\SP9(C-!<"%8[^&%cTr!KdTP#3,i]o.LB=Rg>bt(8YCD#3uMc,,GAHGFBHQ#0SQX#H\(5p2_/T"#(Z4)Zr)"MZX%XZN5[_#*T,kMZX!4"%E@s)ZrdnD?C+/!s\?qqboH)+SGmA5l(R]]`T2U[Mo<[6_Z@AA`X#<C:tPg#-0_l[0$H+!uh>R6O:R3#f?tg!JrXn#fA'N!Jrh>#jVc&`re:'!uh=^6O32b#brF>!M`*7.eX.CUI5B_UF>gA#bqb5#P/;Bo0M5%M*%:6Ws@Yc"#pAg)Zt9>Q3.Dfo`J,1!uh>M7KWklc3"9OaobR(1E-Ek;a%hs"&>Bh[R,Qb!MqS3!tN'JrbePO#6pY%""imB#1EYn#1G+*;[&Hhc3"9ol2ssHdi/Aj$Nl+fL'HBdj"LiC$Nl+f!m1U!V#qY=qATN\!skYo5JdLS&cN^O/H,jCMZX!:1FrV4;Zs6*"*3K*!s?^c!J:RQ!sSQ(-`mIoq?%Z=!uh=k)Zr!U"'Llk1C^K+"*[7m)ZqGP"),(E"k*PmgB!K?!gWol!sR^`"&hS4)ZrLqFoqgK!sXnj!sYeFgJ\6P#."C8"j6q!K*JpiL'GNr0FZ\<")5%C/'7r5#*Tu.K*R;:c3KO6K.mZ9P6[9VMZY%+"%E@t)Zp>N#br3AY6-?Yq\oVt"j6uN"1&#\K*B^+josK?"#()f)ZsK:FoqgK!sYM&UB6I)!Jr--#,;4emK&/VSd(qoWr\%Z$Nl+fL'Ft<1GB1=;_ZK!"&Z'#WriGC#.&=S#*T)U#,;8Sh#f21Q5]p$-A=5\5Fhn##1FLn;ZWHl^&nSo#3/WO;Zrs"5fErVqZ3Pr"g\:6!P8AbK*Ajhc3;)d"#()`)Zp27WWqbk[f[(bl5KgYK,jk&QNIHtUDj:k3Q;.,EP_fVLBAItWuD-igD$Lh#/`k6#2:DXL'F\I70_L/6`pX"ZUG)QgG&U2dK;oBUDj;,UGe,<#bscn#br!_L'XO^70i]4#P0G5!JrP&#ce3jPliuJgD^5D"oAB*!qQGFK*Hr1"oAB&"ku3CK*D,S!s8?#!J:T/"!Qq339:5]27FM,#;ZX?"(UEp(mZrs")&7')ZqI^!sOSb!sJKP!J:Q6P61pI!s+#X)Zr0]!sm'P_ZL!L])tD+VDJA\ed0GeXoXA*ed/kk[K242Sd<5'ZN5n,]*R^."P[#a$G-M3#KHp\!s9JE!L=#W!slL@_ZKut!KKMQ%c.K'#DN89%c.KW4jF(b%+Y^%#dXPg3!0HP"%.YB"g\:M"T'_PK*AR`!s-jO!J:Qf#*&l)ZNDlhq^_gQ"g\:6!eUN+K*AjhXp)]D"#()`/-?'^"!`L%RfTQ/M_64b]*>SP"T)7(D#pDI_ZKtHb5m5!$O2n#"hOjj"#DJ1"&hXC)Zson")+D2!skY@"&h/()Zsr7!sZXF7^W=f,j-*K!s^V')Zrq0#."N?],q6h$U*VVZNd`i*sT=]"+?.26e)8X#6#PD;=+Rg+N4G,K``7rb8UO&_]SaoRfTQ$q\.^()3[W!+/9Y4!sJL5!J:QV"g\:]"hOef0FL>#"#uGG!sFf,!J:TO!sYe.WriG(M?@l'WZ)$SlN*Rf!s,5&)Zs%3!slL@_ZKut"dVL]-12&V"dT1G-12&N7]lcK7(*B=#dXPg$_n!ndgtJ@B`a2&"&mnU!s8WE8>630"'Z]H!J:Q^#4;Z,Wrk$`X"4>V$Nl+e[KA<>SHDeTgD^5]"nMg"!g<Y;K*D,S"nMfsZ3*Pu!uh>L)Zr@E!PST@"#DV="&g,()ZrBk!u0Pn"nMg8"#ECK"&fel)Zqkq.,G'T"#DV="&fB3)ZpAo1WBMQHL_/:`<.%]Ri;G\!NlM/!sFfd!J:TO!sYe.;X+>aCr.+n#1F0mN<93Xq\oVW"j6uN"g\5^K*B^+p''1O"#(*E/-?(!0"(j<7_Jn&"G7WqK*LWDrW_rpdkD.=#5\K)#3,`:K*R#2qZ?p$N<:R5b8UO-#-.h,ZTA2?'*A=@;$O'?"&u*!`bD7gV$>ZT(ki%m@CdB[#;[Co!su(3Gi]#HZ3)$J_]&]+$RaL,Wr\D<*s0=]!knam%dF-p/<1YO!lYAe+/]3biWC,%WuD.50FN%.#-.rl"!7`J/-?*G!TRgHWWOgTh&?H@1BsFZ/E-a:!Lar0#;ZGL"#Yr<*XT+kJcc66ZPru^"lf[d!p]l>K*CQC!O)Y,!KI?T"mZ6mD!_<Q#5]>AM[%p/o)fX,#3/Pb"$$Gc)Zrap(QM)[!s]%R)Zra(!s6(:"#BtA"&f?J)ZpYoUB:X_!s+#Y!!<G+#-.h.NWuh10F!^C"";1l#295!!t@-))Zrm,)TFM+!s,5S)ZrNl7@k*K!s]%")Zp5SqZ@;N_Z>Ak"g\:3"hOef0FJBa"$t06!sFf,!J:To!sZpNb6%hHmfRS7P8aTE#/^NGb6%ct!rrE-EX'\h#0mG%"#'q;/-?*o!uI:+HL_.WXTKLE2]DjI#-.cbncJohRi;Gp*52LZ!sFfd!J:TO!sYe.-(P,<rrX2B\f1_^Ws&-)!s,5&)ZpE(!s\&nL'Hs5o.UOS$Nl+f!sYe["&f5T)ZsO67[=1p"NrJ,0FK;#",6s-"PYU<0FIu;0%L+\;R-C'"T',?K*@/8!s4A]!J:Q>$W[G#%AEqY"7mH6K*J(Q#-1AtUB:T#UIG=i!lb<HA'G*S!s9JE_^G`$1!Tk*#."D1[0%r^P8aTP#E&Zg#Eo1@0FJ!N#EoCF"!7c37KWmR!u9o"!sYM>X&B&E$*F@7!sZ)1UJh<H"#Kl[("32\&VCYlk&Z,u!MqRR"'aR`#3u@1lN7+h"!IaN)ZtPp!t(Y&!s8WE!sYNDX&Bq&3W9*b!sZ)1"&fs&)Zre!qG%6qV#tBYP8aTo#294_"mZ2AK*L?<Fp@75eH7K5!uh>,)ZtSt6&l/m#1G760FJi>!s8bF!sZ)W94iGOZP*PT]*>SG"--+\'*c'A#."N?]1rRB"24jA!sYf)9."odWtP]DZNdH7#-1K'#-/$D!sZ)""&f<Y)ZpDc""8p,!sJK?!J:T?])r/1_Z>An$Nl[u"g\:b"T'_PK*AR`!s,.t!J:Qf"%/4RL,"i1V$=O8AASEL#0Rqf;]Y!&#1EbAj)G^_$P1Me!s[4.#1Ii"K*K3q8s08WUB;G;%=<s:!unfR!sYeFZVqh"7FhPFXTkP!!N#rb4p)"i!sFfd!J:To#0R4W\cZq)!uh><6O:R3!slL@#g3<,#6&$5$hak<"5X'8$hakL2U2>[)=@dJ#dXPg$Hi_@K+ElBBa:+/!s,k5!sFf,!J:TO!sYe.WriG(#.&=S#*T8"#,;8Sbl]L!ZPs!)P69A?UB<1SP:Qe?#,;8'Y6+fX],Lh[!T!n^!sJL"!J:Qnb6%h+dfG()$Q8pI)TMq6#*Tu.K*L?<mKVtXgFs!;lNZYZh#e`'!uh>i)Zr_"#0$a$8Wj0S!L=Z,G=eej"'GC%mK8@dP;!A+MZ\S4Oold.!uh>H)Zs<@!Oa/b!Mp"D)ZrM2.DApL!s]%2)Zr?j!tt>1gJ[ke"(hW>)Zq\j(S1^b=S2bp'qH9G"dTCO)V"pGr<!u@!uh=n)Zq)V!s\?!5fEgVRfaT3"*bI\)ZtSI"TBh*!Mp"$!tq4.c3qf70F[7J!P8Ar"!7Q])Zt$$gB.W6irOc:$UMK2is)84*sUa0!s\2r!sXr.!J:UR"7?DH#4!rN#D386*Jsq@"T',?K*BF#!s?FA!J:R)"h"Thb6'F+""XNX!uh=i)ZsE#"$s3pN_8+H!s^Uc)ZpAJ5ct:6"#DV="&f`])Zs1<_ZL&=K)pT."j6uM"k*L)0FKu1!sQRE%IXBMb6&[cX"4>W#Nc*mGgump#,<+>'SZh8!s[M"j&6NW(<-F\#0R*IPllCY!uh>\)ZsH)o)f0NWr[hV"oAB&o)f#G"%E@r)ZsBJ!sYk0!s[L!!J:U"!uJoY`X\OYis.@C$U=%^V?8V.LBCH[_]&[ggEM@V#-1/s#2:Wah?L#L70_L85)'9B"%<FK[Mo<P)UC2ECqTpp!s9JE"I"!2K*J(Q#-.h,eH5dReJeTd#+bjO!s]%2)Zq)#(]F]8UI5B_UESJ"#bqb5#b)*[o.Hn/M(tk4Ws@Yc"#pAg)ZsBW"#Yc7K9ZNXr>Ph>Wr]Y6)?U3K"Hsc,K*JXa!s6pP!J:Tg_ZL+<!s+#Y)ZtE?!sXqk!sFf=!J:T?Rf`i[UB,uOCI3a[#*T-Cbl]L!!uh>A"*ObKP62#YQ3/oDl2ss)P8aU6#."C7#,;3O'SZh(!sZqg"&gBB)Zrp5L'%[E#FeWp;^\^MQ3.AeaobQhgD^6:"nMg"!n.1&K*D,S"nMfsg&jeH!uh=e)Zs?1.gN*W!s/:H!J:W`Q3.B(#K'ID;[&HhQ3.B8#LcTT;[&Hh!tX8k!sREu!J:RI"oAC##(lr/0FIu;!sS8u''03HOolX*)Zp+o#M'U[!Mp"T""g5L!s8WE!sY6<"&fHe)ZtE2!s[K^H\)>hjs(fI1GB1a;_uu,"!+cO!sFf,!J:To!sZpNb6%hH#1ISs#)`ST#/^Ns"HtA=K*K3q+T2BCKX)O!Rg7dN!s,5&)ZqRQ#+I$T!Jqc(!sXYc0;8P"M?=e"di/Bh#,;8'#-.cW0FJc,!sZ(6/%l%6"hP]U0FKu9"g\9bq]?!R"hOj>!UBc=K*B-pp'&V?"#(*@)Zrn/!sYe.WriG(#.&=S#*T)5#,;8Sh#f21WuD.3"QKRe"N(7mK*:KB"QKRbh#g+KRi;H:",6m^!sFfd!J:TO!sYe.<P8J7"g]-M0FKau#0R4_"!7a=)Zr@E"%7_C#2;ci!ttb=_bgWe3<K?f&!I6fK.[D@_Ztf&"Humk".Kah!sZqcdn<VO!s8W0#1Ee*.K'?UqZ@c>"(;9:6O32b#bqOR!N.*TN<l9]RKE]u],Li6$UMK2]*>#a*sT=]6,!Q@ZNDlhZRc1_$Nl+f!sZ@k_c$`Y0_PSQ2pDG'ao`RbZPrupP6R$OUB<1SP:Qe?#,;8'WriBT!rrE-EX&QH"*<`0WtFA2%19uc)?'^'!o#C:!p]pJ>f?de>)aI'#2:)oZ3(-(!uh>F)Zqdo.D?\uh#dm<gD^5m"nMg""$6O9!J:RQ!sS8u<Wb-I>NGrc#.kfVK*IMA!sXYa!J:Tg_ZL+,b5m5"$O4TT#.jsko`H`I!uh=GKt7J`ncK=%!uh=\!s+&!P6L7kE>$h,"JuBuP;!K9Gln-Q"*]n1!J^FiV)&[S-iF,J_?1_Z)Zp+p!sFA]!sFf,!J:TO#hojLirOi9Wr]g5"7ld%$_mp,lNY65B*$0`%\j8eK-C]8ZNU.9#cfZj!Y<1Q#-.h.!r<">!N$e<G9""H"%o9i9*9nf!ttmVHm8ir1R86GZU>"u"5X+a]`t61!N#r(_ZL%*!s+#Y!!<GK#0R)NSd*Ya0F!^C!sZXF.]ie("Hsc,K*J(Q#-.h,!s8N*"*+UH)ZsFF"i^X#7a2$6"kssuK*D,S!s=/V!J:T/!sSQ()=dl!,b>qW9*:Xc)l<]nC97S:"3VVcK*L?<#3,ddjT?Y.)Zp+uZNC9(b5m4t#(m!Y!j_o[K*I59!sR-S!J:T?!s8a[qZ?qGh#f&/!uh>`7KWhc"jR3+*h<C3"#Cku"&fBS)ZrRClN7?To)XIJ$O"`Zo*45/*sV<@!uf;a!sZpf"&f8])Zq7sL'%Y'#*r1P#,;COgB1A$UB,uO#3,di!s8RVdjPFTWs7;_r<!c<!uh=Q&]Y*VD!D*3$+1]S#;ZO\!J?@6g&i8r!uh>D)ZpDkFoqgKh?*tW#-1Z)0FL"g-(Y=I#.lPs0FKIm+1;Bk",8K;'*cWQ#/^NF>FGXB#*Tu.K*M2TmK\@Fo.UOSK*R#5[0%KURi;G6!fd?e!sFfd!J:TO!sYe.WriG(h#h[%)Zp+r`WHFO#,>*$V?7*r-3hp""#'qC/-?*o""LDTRi@&#""aTZ)Zp0!!ObG1!s,5S)Zr:`#btf#aoa3t!uh=r)ZqI^FoqgKlN7?To)XIJ$Nof$o*45/*sV<@!s\&n"1eS("KNIDK*JXa!sYM$!J:Tg!sZ(6!sYeq"&fT9)Zr?r!sYM&#,;8OWr\Cd"-s#n<k8B3"g/dHCu#;rMY.'qq\oV<"e,Ss!lG%kK*A"Pp'%Jt"#(**)ZpD5#jVQp!s8RiSjNe$mKi,IL&m,ErWpCXZN5nN!sn2u*Q8+?OGt1]1BGJrl2q'`lPfqG"dT5pE.nBm$2PSC#2:][_?0h8!uh>R)Zr;##I=L_Rf`ai"j7kjK*S.R:$Mf]dfUNk"WN.*""8j*!sY56!J:Tg!s8b>$F^*A#0Rqf#1Ee"_ZKuc!s9qU""4Ac)Zs$-"jR=AMZYX@1FrV4;Zj0)"(Hia[VF&+!MqRW"''pT"jI,g!s9JEZZ68NP6&r5UB<1S4"LI<K*J(Q#-.h,!s8N*ZZ68NP6H[FUB<1S""XNY)Zt?=FoqgK!fdKNlS&OdgBElI#4"\^;[(/C[K?a*#5_=%;]+?n;<eAO!s,8$/-?'n_ZL&=lN)VA"j6uL"k*L)0FJ`3")@B/#eL0X!s:@^!L=#W#f?`H]*4KfM'Jl'lPdbDM'Jl'_`!5MM'Sr(lNjft"#pAg)Zt!SlN7@7])dNg#4hp$#1EU*K*M2TlN8(,#2;uZgGo?<$0D<o!s[dalVfM"4h_"&?^1^l#/_A^;_d,2!sZ(6!sYeWP>_L:#."C7#,;3OE@qI-"!XHA;VD3l#-/[F;a#j;ZNC>o])dNg$QQkb!s6Y"!J:Tob6%s<'*3^i;$Oo?!s8b6J$fA=HNP2h!J>h'0FIr:*L6_Y!J<gf0FIr:$YBEtMZJGaK,&_6$Nc=h!J;=F"!7Pr!K.!J!L!PE0FIu;",6iG!M_=V0FIu;)pSOA0sUm[UB;G;%0Q8-"'+Fb!sREu"&h;$)Zs1/b9dGJ_?2IrqATMm#;[E"!uJ?I#,;8>#,<^O0FIu;Q3.>l[0'>RWuD.j$O4lW!NR.nZQB4K$Nl+aL&nn?"#()b!s+.I]*?Ftg]bk%!sZXD!J:UR#4hp!!s\?F!J:UB!JmQS#(misK*JXamKU9("#(*&-jI![!uI4)#,;8>"HtA=K*J(Q#-.h,!s8N*ZZ68NP6(@]UB<1S""XNY)Zs9L!K#n?Wrj:C!Jm`[=OI9\"3qhfG@AHH"$sU&!UaG:6Q7]e"#D$/"&f6W)Zs-(UB-A)""aT\)Zqh3$_&-r!L+;Q!JAW!RfaT3""XNX)ZrWo!KH(@#4ic9!s+ABqZ?kr"(;9:6O32bdg2]^$C5Q;#aPRVZOXl38I2'n2kC;MUI5B_UEGR&#bqb5#Q$7To,=c#M*122Ws@Yc"#pAg!s*qXVHs$;V$=O7!N-###_j9#G:]1=!sY"m!sXr.!J:W8"O779#2:g>#EoCV#E&[+`</R3)Zp,,NWG0B#6qd`")tpU!skY@"&g?9)Zrq-"!5#U^':n_0F!^A!sYM&!sY5G"&hIf)ZrBs"4dLRRj0Tp*s&DC!lb<u2Tc,#"Hsc,K*K3q#0R)L!s8N*drGZ9P6UFZr<"_XgD^58#)`Qe"iC@nK*IMA#)`Qal2sKXUDj;Z6LFp]6M^d_Smr]A)__X%1EU+";_j(0"'O%S_ZKu[b6(*;"(;9;Q3cdYb6=14M'i3-lNNRTM'i3-_\/gIM$om\lNjft"#pAg)ZrWjZNC@-K)pT."hOj;"iC@n0FIrB"$WO`=+p_q!m;Mb0FJJQ!VQUO:7VJcGD-t<V)&=1(A\+6M?=e"!uh>@@06c3#P/$"^)?o;57"#FN<l9]!sJ^Z)Zr.<+3nGodK9_1ef+]3N<[9$aochu!uh>C/-?'V#*&dAOd-#Iq\oV<"fh_."$6O9!J:Q^"-*PsWrk$`1FrV3;[90%!K5q>N]S0^)__X%6Q\BO0FIu;P64G[7GS%HeH6`m)Zp,,!TOUcgF*9T$UNnZ#0R*&#-09W;\.F]"*i>ub>89[dfJV6$Nl+cL'-0aj"LiC$Nl+cL'-`qo.UOS$Nl+cL'.<,1GB1=;[0B,"$O3tQ3+rCP;!@K_ZI.F"#D##"&h(;)Zt&U""KH9#,;8>#,<^O;b!&TXoem/dK<E6]c.&`1BQ,s:\k.u$G%/Y#.k)*Plh&`b8UO9#3,di#.">_K*LWDir]Aah#f&0$6'(n-mToT'bLj*!!"_kNW9%Z"KMA#)Zs^T"Ife"CG$"T&"<jJ$2Xao)u]r?"&B#@!J^ar$i:kF#I=K$)NJSq[VH=fCC=oE77.47p,`>alN)hF7K[]6!s/,u!uD%Y")BJ-!NuSW!s9JE!L<bm!K.$^ZNeuJM#uf?!K/i:!JpmW!s,`T!Oi.jK**%p"#L)\6NN)I!ODk1#1`g@!N#mM"MOnn!N#n("J,XN#)3/b!i?!T!KI2=Z[2_0=9[^c$1eK#")/4f!uh>*"%,-Pp0e%j%fU5iCBFU5!s.q7CE!?b;`UEO)ZqYo'+51k!s92M"5<nc!t,3G.K]^FC',CWTE?,8".]StzXc4+s&s!+t&+:G>!Ms:,!stS%ZP'_d""aTULDp=3,8Au<f)l&M!uh=N)Zp/>!trWVMZX>+)Zf78gMfM!ZNo4eP=$r-SHG&cWsjU]F9CA.!s64>%-I^3$+CiUV'?*)!P\^;"!\`e"&fB3)Zp3:"o\g`3WfU3mfOL26Q6+<@hfqE%JpRO$&^#\!M'Pg#g3P'"*=[s.iSRt.0JE/P63TC!s=8YrrWor!uh=C)ZpWF"5X,!#3Q(e"h,EQV'?&M!p9XdQ5U\E!Mq"G!sdE[rWW$8!Mq"A!s.!U$PNU]`WIFchZHd]ZPruO4O+$0&*F$n"!\`e'2p3C!J=#IE_?K:K+e>[")e8BrX-+R!s^%R)Zp9$!sO_f!LEm-!tuUU!J:WP;cWun*ju/L!OW#.9*6+8VZRA;(E3GX#9sH8!s+8]!lkB^!N$e<G6uS?)ZtBg!sFYe!s42rVZRSo,9$^p;Z`6e!sS,q<s&Kr`rd7_!uh=H)g2;c)e'aR!J:a^!s9JUK0o_s#4DWpY6,^GgD^5%])g(qNrqrncPlrm,7"2XLB@RR,9$^l;]M)*!sJ?#)`pD+!uhmg6N\h@WWN9SRi;G1$a'R8!fBWLf)_`N@m$n&NroEZ,9$^i;a#j;K/3TC!f@'\ao`Rb!uh=C6NPX<!W)s$#2TBH1[Y;@*i8sp+-$BN!Q+qp3!03Y!s,+uqZ?p>!s+\g6NPX<!s.-Yq^2#FM%/SJgBNB5M%/SJdm0c2M$1g!qZ4S8=:^;j#Fbm\")/1m)ZpDM!sR9Y\k<,E[f['?!uh=EQ3$jbdfT[Q#DPSH-gh$44,*cm#c7XO!Q+qp3!03Y!s.KcrW:4]!Mq"B!sn>tRf\<`!u!a,)Zp,+9*5XX%dO.J/h7Hb;\KW;"-Z)R")S:\"%EAc)Zp2ENWT<g\cYkT!uh=E)ZpAL!Rh,Q!S[]Db6)/TL,8u5c2lZ(NWFtQc2l)hXoX@q7KLs>!Q+qp3!03Y!s4/Y!TF2#1G]sP"!^PkL/SSJ'0?9t!sF;[ecaSD!sBhM)Zp/A,9&-`!s@?],6m9L"*Xk7!uh=q6NPX<!Rh4<!Jq#P!Rh8(!Jq'$!W)o8/H[s7"77$0!s^%d)Zp8!)jURN3s,jhPlh&>!uh=Gc5Qjh!Mq"_"kNj#!JMHpV'?29!f[9_Nrp='!uh=F'6XH[!J<`A3s,S>)`pD#!uhmg6N\h@NroE8!uh=H6NPX<!W)s$#F5CV-ADQu$Dmi\M%0R8qZ4S8=94<\"PX3_")/28)Zp6+#0m;qb<&'i)ZpfU]`S6R,9$^f;^gK)!s6.<dfT[kgB0eDemSX]^&csmjoL;AjoNpT_Z>T?!s/9"!Ug+M!s9JE"%**AN\gibp&VK%ZNF>k"U+c)!sFkk4$u@Sc3#:5Pljqc!uh=G!J<H9"kEc#"%<;j!uhmm"o8<'Z3)$J!uh=G6NPX<!W)s$gB.JBk$\>mh?!KSh>rH<h>u@7joL;DrW1J/_Z>TM!s/9""MY$u"TB>BG6F?Z!sS?"!sZ(N!J:IF!sR!Q"6Tb*4$sqh$Nh+_6NNk_;a6iU!s?4=!S[\q!s;s6hEq=mecFM/Q2ugO[K4hk_Z>T+UB15mP<2kWB`t15!s=\g!QkK`!s9JE!L<c`!Rh,Qq_*ssM*n]Pdjg(QM&iGoqZ4S8"#pA`)Zp0,!s>8"+mrDN!s,5C)Zp,H!sITcqZ?p>!s+\g1]md%!Rh,Qb6-loM&P4OqZNJkM&P4OdfnS/!JsPP!W)o8*<S8'!kfNTV'A1t!PJR9"5OmuV.1I1!P/@6)\X.m"![mM"&gq/)Zp,;N>jrH#F,Al",7`sZjNi9ecR,tK`b6U,9$^f;`==O!s:n(!sOqlqZ?p>!s+\g6NPX<!W*+V!JqAR!Ri@W!Jq6I!W)o8Jcdt7,9$^d;_GK\)ZrM2!s-RIdfT\/!hMa["3(Ab0ZF-M!O`$X!Q+qp%[-qjP6.deBa:C<!sR3W^&oT!'*7D"'*A=U!J<`A!s6.<ecR-9V#sXb!uh=C!uh>:L0Y/h',(HM)Zp1s^&oSnJcepRPoBf2V.4ZR"N:HDPlhs-iu8()ZOFhYZN8k_ZS86W!OE.77=-W+!J;6/!Jr+WMZLG2#0U*R"mZSL#PA15!s9JE"%*+<Q3$jbqZ<VqM)=>qdgO_-M$BgXqZ4S8"#pA`)ZpDC3s,S>FotANXohU$"'\\d92cG"V?7'gNWQ<`!Mq#%!sbh.$3^PO!VcbNzXKWfI!LElkT*$#7!uh=F@06Q-!s.]io)f(O"dVLV5`Pm2"dT1G5`PmB#_iA:!q$*\!TO3;$MsmoRg"^PBarN#!s=;\!UBh,!s:@^!L<eV!V6BqRfo<MM$grulN?h]M$grto)mhMM*7F2RfVOM"#pAa$QB0W;ZkkY!s92=EYANW"5X,!#JUXF'*4s4!s8XP.rot=^E7fL/H^>+!t3]_Mdli.!s8W0CBH2!!t,25!s;D9>>lMG;[X<j>6=s0qZ2WX>6rC]gB*""$jjNR"1nT7o*u,N]*uRZ%tdad!fI,d"(MFL@fm)@;Zd,!"'Z-Q"(ME8@flf8""sas!K.%!!t,25HVjg%Eu4u]!u3>5)Zp8Y!s<<@;/67A**WLI'e<Ke!sSE$"&fRH>7'm'!s8X(T*'+<$QB0K'*A>`!s8RV!J:IV!l"hX1BSQu!t>:/!uh>L6NNqa!Rj2t!M^U23rTDkdm*r_dkAuI!RhDW!M^=:UB9"8M$:$_gB!K==:;_A$(D=?").eJ)Zp/V)Zt!\!NQ@@"',Mf"*ObK)ZpB'!s<$8;.B\9*)cqA!s;a8!s.ck"g8"I"&g-@>>k]k;`h,a"5X,i")e9?o)f(6!KKMJ%-@T^2Wb$s"1A7%!TO3;3!05O!scRC!oHoq'*4s4UB:UFHNpMQZNpA"$kB<J#*T;8o*u,.Ws\.o&!Klo&"<`d!WN7<VZRk?',q#W!s8R^"3UcSHNO@I"KqnI!s9JE)Zt*o!t,25$W.21"$H_g!uh=W#1!PG!P\^G!s9JE_ZOq+$NgJ:;#u:O*-22aOF%';!J;$d!s8W-"*+Ep)Zp2%!s/9$o)f)'"l;TI/'\1m"5X'8']oGf!q$)G#c7Xo!TO3;"N(;1!fJ:*")/,>)Zp,(!s4Mc!lG*Z!t>:2)Zp2"H7O>`!s<T`!s<l`)ZqGi)Zt!\%3JLN!s?:?!La*0>lu#JEt]Jpo,n*uEt%pVdghj>$kA1*$G-A'o4ngDj&14-o*_T*Es$4[!sJ^o)Zp5(!s.!U!s8WE!t,K[!tu=M"+gUWlN8(."#L)\Q3*NXo)f'q!rbOf(<usH#F5CI(<uuN#F5CI&B4d@7J6b=5GeJQ!TO3;3!05O)Zt9d!V6Bq!W)sd"hnCI348kb#6"X[*j,P8!TO3;3!05O!s-@C!s8WE"#Btg"&f<Y!s8We6ZP6j;ZkkY!sG/NZ3(-)!uh=C)Zp,M.shErEruHQgB.N[UIoS.CBO/5o)Y<h%L\a/"iCeudo$SNZNA#HHP:2t<s&O,!s9JE!L<eV!V6Bq!W)sd"dWR!.u"*%"l99:.u"+p!o<s7+Pm.j!TO3;3!05O!sX_e!s8WE"J#X<!s9JEHNS;8!sJgj!uh>LQ3*NXo)f'qqZB1d`aJrMc2sIRScOZLV?35Uh>rHAV?34jQ2ugGjoP>_XoX@`p&Xb+irP!*_ZH;.!Lm0l#D3/3"bHhjPlhs-!uh=H)Zp3@"5X,I!jXU\!s,8$!s8XH"*/Gb)Zp8\IKM)&"dT6HXogaao`J,S"<.FG)'K_8zXGeD)$'t_s$1Af8#BLB`!s4ekRf`a3UB<jaY$hD5joM4\XoX@fecD6]MZJYB!s-:?#O_aS>8nL`>6=s0T*$5=lPfp-!R:cP$Nl,^LBA3"!uh=K)Zp63K-LI3`WJR/k6"WaEuP2f2YITd!fL8]lRiI4HN`@;"OgRV"(Q1P!J:E*.!l$uK3JG)#c@b*!s9JE$NkPS!s,(t6NNYY!s+SfRg#*7M$iAGP6KeDM$iAGRlK7*M%JME_Z>Yr=9=*U!oj`R")/(:)Zp?>cZ9/rAHR,]UB;G;"(;946NNYY!M]nV!Jr7[!LkIN!JpsA!Q+qrNrq?DQQ$#2EsM[I!M';t92-?-Z3+\@di/AiCBWB!Q322JhZHdr!uh=H)Zp326T,4RNroEZRi;G1ZO<N3"04$V=(;TL_ZYlr"*8;`"&fEL)Zp;:!k&9Yf)l8!I2`7mV*cB^!QP9C&(;I""4IC*!K.%4di2@=D$bh)K/3TS"$6Sc""OD9!s+$I!uh>$)Zp0!)Zp<IK1c:sgB0543rss<!J=SY)Zqht!s6.<#3Q(-!ra,@G644S!sG4u>7T[4L&mJ?'4VCPCC:6!#id-CF"Rg;%EejK#HIlr#-J*("MY%\",7`s!u!0m!L!UAP63lK`WJR/pB+>%!uh=G@06P*!Lj/nUBfXCM(Pk2Rj%2#M#mSV_Z>Yr=9>f0&).D[").h;)Zp0<!s>.t9*)%3RKI.(!uh=E6NNYY!s,/!!L!Uo"dUtI2V%nm"dT1G2V%o((rcT5!q$)Y!K-u83!03!)ZtQl%,2c&NWgNbG7AUS!s>.t"(D?O!L!U)!s:@^Q9t\B[K2QqScOZ[^&a]AMZJYA!s-:?"&B"YdgWi-!J;m,K/3TS"$6Sc"%**Q"&gJb)Zp1oFoqgKM]2ou"%*%q"&gi')Zp01L^-QT!j;\,!nS@n#=ARd!sF;[b6%hc)Zs@I!t,)2L&loO'.XFm1CF;>$Nl+s"%*_`mfQKp1E-DtK*8dg>6?qf9*53I!JggU3fX:4]`SL\!uh=E>8mYb!u5T])Zp,0RWA_"cNA@n!uh=C6NNYY!s+SfP61_?M#kTsRkCiEM$3eY_Z>Yr"#pA`!uh=a)Zp/I;KE*B"6BW/!ppp/#BL-9!sJQ)h?3Ei!Mr.A!s-.='3bPX[KCRN8cquq:BMO<!s9JEQ9t\BScP;arW.i\V?*.hMZJY\RfUD-"fk`4#eLK!"O[Bd(mZ*CG66bk!s+)X!f@(!!s9JE!L<c(!Lj/n!L!UQ"dUtI"HEMP"g.l_"HEMH!TjE>"HEN##L3@,0(o=8!K-u83!03!!s=Mb!UTt.q?%Z="<.FDQj!N3!!20_z"KRk,)ZsFL+3P/3"!/,."#L*YSjQ]aNWG%cMZLR\MaNd2!K0>H!K.DAL&m2?L.,#H!QJ=LlXKsP"%WM()Zp1t!s?:?"31K_!s9JE'6Xb9'7UYt!J;U!"p4rPK,Xn#)Zq#['*[]O'.F9@$A/e_"JZ!f=rS!1"3UeY"%!:b)Zp,5%<j$!!s+_j$NgJM!s=9`",7I&;\L)P%[.%E!h1De!M'MV#_NMK"*>ON)Zp,U!NQ;)dfT\>`W;A+ecF5)ScOZKNWH1&RfS?s!s-jO!WN6]3Wg<'mM?fE"!BZF!uh>J)Zp,#!s+/Z")S,ZdfT[k!s+\g1]mcR!NQ;)dfSZ!M$DN3dfdAcM$Ml<UB[RrM$Ml<Ws?'6M$Ml<Ws,X,M'&;idfGp=]3'C\dg#+H'a&.Z""P;m1K,RE;\>#l!s*ueeH5iL!uh=C6NO4i!s,_1ZNZY'M$!YWWs8P(!Jr]8!Rh(=X&oh+UBCB"`<0f`$QB0K!s8W=)Zp,h!s-OHc2mb\!Mqk'!s.rp4Ttm+zXFM5i".oYu6Q6sH"%s^t;c=s];aR>`!t*?VUB-8lF)YmqE-hVd!M][b"![iI)ZpBG!s55"_ZL!L!s+\h1]mfC!h08o_ZnsbM&GFWP6I6QM&GFWUBQqaM*K8eRfr]kM$M$%_ZG_s=95/u"QKRD").r9)Zp8)"Q(F+#QFl8T*$#7!uh=I%0cc)!sXM_!g<^*!s:@^Y!W8[`WD>-NWFtCecM<EMZJYB!s6@A!hTQS!s9JE!L<f)!h08oRg#*FM$<k[_ZtnsM&OY@Rgo&lM$CZq_ZG_s"#pAa)Zp1t!sXegk9C'J<s&m:".pM7V)pT<#M0%Y!J;<n;[1ML(p3sV[g^_aL)U3u'5I[PEruN!!s=8k^B5-r!uh=H)Zp,8)Zp]T>mg`:'*A>k!s=8k"!\Hu"&f_b)Zp2O!s4Yg_ZKut!s+\h6NW_Z!lG7t!Jr)i!g<\W!Jr)i!h0;K!Jpm7!lG(tZWIR0q[8kp%0L;PL3":9!Kn*<,/+/+!ga!fUB;G;"(;956NW_Z!i#hB!Jr2<!i#q%!JqJ]!h0G/!JqJ]!h0;SMZJYUqZ=Y:%?"<r")1sY)Zp,K!h08o!i#ib#G,?+#M&sG#IXYi#M&sO!o<s7.+SHh!fI)9"g\9J1C!/I").o0!uh>LFor,Y"5X,)_[*#K!Kel9_]'-0$`bo`"60cqh?,QAV'An@!N#r"!s-OH!s+#n"&fB3)Zp/>!s6=AL&n%g-NT\Y$1e1m'-e%"!M^g8VZQs_bo6`c3tI&I[0$H+Ri;G2Erh1/MZJ`2CEJ93P61oA",7Hi'*4R)`WH6omO_?nV#c2r""+0O!qud9""P;m1K+sQ;`X7J!s,DH!J:EM;]b''CB9W?"%iZ7`WGfP!s]JR)Zp/61H&_b)Zq8dFoqgK!s,5#'13EP]`S;9!uh=C@06S+!h08oUB1?]M)2:9!h153!Js7B!lG(tRof]TP7-[_Z3+eL\f1_QqZ=2,DZ^4I!ra,@G8^L7!s6LF`WHkn$d3K;UB:S_b6%hI!s:mk!L<cX!W*Q0!M^jI3:6hEqa:YKq_3a*!W*6*!V6lBb6a1tM#k$cK)rRb"#pAa)Zp/T!s-XKo,,pq*<hoDFoqgK%'qJ(,:3W$!sSi0)Zp5s!s.Zh5,N*7V@t<j!Kq4A!s52!Rf`a3P64/RQ8A[Fp&^E]XoXAC^&jcFMZJY`])okO$-QEO"k*pE!V->,9`l=:6N\80"+Cc5$NLQ-!J=;Q"5X,aL'(pa"!^_I"%,pY"%*n-!s+#n)Zp2-mK3p19**HAV?6k4!o3qZ"TfVF!!!!MkpZT4f)l/VlPfp0_[jWf""SNq6NMg<!J=SY7KZQk"i^XCjo\gd[f]PLL)U4!'/K^m.@(&t!WN7#f)lrob8UNdb8ZHB!R"RG!QtfCrW11M701:0!Lk[D!Jq38%%@9UcN?-/!uh=E6NQKT!g<]g#K?e12!+k'$e>?86&#F+!S[X3!qQJWZN6OtB`mZ)!sd]cp&eeDs&2iX!N#r&)ZpNO!s@E_#F>N3DZ^p\"%sR8,6<EQ!J<`A9*59NecSha"'\\-"&gB:!uh>O)Zp/V!"1"R%.43Z!s=9V#6PVi4+8+N"*Xk))Zp27!UBgiP61nSScP,Y`WD>,p&U!N^&dO%L&m,7c2m5sgB!-4!s4Ye!ri?^`rd7_!uh=FQ3"l*Rf``n-B:Fo,j#-Nb6%dC;$#)G!s4MclN75.o)h>\"(;941]md=!UBoT!Jpu_!V6J\!Jpu_!TO?L!Jpu_!UBsH!JrV8!g<Z>P?7k?]+!-oh#h@#iu8($b73bG"M68i=$m><q[NE1""S3j6NMg\!J>_$!J:JIEruGq:BN-M!O!FEV/$7c"Kqn.!s9JE!L<eN!UBgiP6Zh0M$3eZlNtQ3M(['SP6'D==:>!-#l=o)").u:)Zp,=FoqgKT`YZ)'.X.cQNI8\b8UNb#dsg9"(_R5"&B"<!ttbU!s=9?",7I6!u!0e',q$B!J<01!s5S,!L3a+X(<4P""aTb)Zp-&h?*f%o`HNLeJeSk4!1$q!jr+8"!\`e1BE+q!J=#I@oEI3;*u9)K-LIc!WN6&"(N8P;c<n/V?6kn%-o\M!s+$Ih\uYfCB_]YQNI8b!uh=D6NQKT!UBoT!Jr>P!UDe,!Jrt2!g<Z>gK4i9.g)7J"&]58RgeU%%0=KT)ZrS4!UBgiP61nSecD'<^&jK&Q2ugFecG(;mK&.LmK)W;gB!-pWreIc%F\Di"7$,K"/Q*6bl\me!uh=E1]md=!UBgilNc96!JqQm!TO?Lc2ib;^&dO$gB!-Yo)b*V%tdsg&%`#B!W<+78cp"7;Zds@iWBWc!uh=E)Zp-+%AO%&!sT^f!uh>J)Zp25+nbrjm/qcP!uh=C!rs8j\f1`LCB`i%SHAnh"<.FG!W6I3!!!(V,6.]D!sG[>)Zp,m)ZsFL"5X+fRf`akRfa`?"+C=Y-3FFt!M]`!b6%i6`W;A+p&W?&%KVCq"3(A:!L!P@3!03)!s@uo"j[8iWrj:C"(;946NNqa!NQBi!Js%,!M_O?!Jpu_!QtM-VZSm\!uh=G)Zp/&!sH(@!J:EM!J:iiNWFc#$NYlK#JL4k2=<n;M';:cMZK:J3";>X)ZpNO*l\9ic3"_Y!uk/e"&h(;!uh>GUDj;2)*7p.)*7p6)*7p>)*7pF)*7pN!s>_/!iH,>!J;<n;_F@<!s8K)!Lj01!s:@^"%**aQ3#/2UBB?RM$DN3b6Hf(M#iV;Rg#qqM%/kRUBQqaM%/kRUBRe$M#sg\b5me-=:MkC!kSoR").er!uh=W)Zp,3!M]`!!NQ;iRfd($L,8u5p&UWeQ2ugEp&V2t`W:nuScPShP6$LF])g(Ub>VLDBa_6P)ZplY`WH6oXTMK:!uh=C"(;:9Y!Z+ip&Te)!s,;A!N,sN!nRMX!O!FEV'@&$!f@'\'*B0U!t>:7)Zp/F,:f'0AHMt0!s9JE"%**a1]mcJ!Lj2J!Jq0/!M^^5!Jq,C!QtM-UK@`l"+q6o!uD&R!s8WE!t,3S",6iM!u!1@!KI7D)(Pdk!s4/YK)r(n""aTU)Zp-#)Zqr"%2'$N)Zs7G'a"go!s-7@qZET4;ZkkW"bQl/dfGRM07*d3"mZHc,@CPI;ZkkY!s.s+)4LZ(+1iTS".B<HQie90!KJZ2"cFl5P=$Q<"OgHZ%YFh8"![n^!s8Wb!W<+"$3M4L]`T2U#9*aH%LNCA!!O,Nz"KSO@!s83!!hTQ6B*0(TUB;G;"#L)\Q3#G:WriG)!p2iN#/1,e"hk"o54/HH2#[N4(mY3'!Lj+H3!031!sFqm$O)h8rr[HU,9$^c!J;m)"p4rX!Rh,QUB:O_"#L)\6NO4i!RjH6!Jq!Z!M]h$!Jq!Z!M]bR!JpmO!NQFe!Jq!:!Rh(=doZjEWsH$@0*>nqrrX2BWuD-CcRUdTXtpFdXrD-["",#k.iSRrOp_GrXpqE4!Kn*"".(Mo8co*F)8dBq)N,<q'3tu-7frdj!s9JE"%**i1]mcR!M][U!Jpl\!NQ=2!Jpu_!Rh(=qcF-1P6e2jT*&d;!uh=D)Zp,UK*qbp"'l!0"!%I_K*)2p!s+\gQ:"jY^&a-BP6&rbM\kLW!K0>H!K.ZCc2ih270/#Ck$(*29*'kP=E=M,%^QJ"").n%.iSR4Op_Gr.g;4>"*Xdr!uh>$)dO*Z:BTGU"dT68!J^bU,9n-0eH7$8!uh=C!uh=\6NO4i!Rh,QUB:O_hD><8h>sARjoL;Ch>u(.rW.i[p&V2rRfS?KMZM9-Mc3^cBa(7:!s+hm!V-=3'a#BW"dU)0G64<K)Zpu\SI5Ue%0LeU3suu0$1gnBCB^k&:,=sFXucm[)Zcc=-Q<5l)ZrD/,9%jP)ZrD/zX;_->NroNe!uh=Q)ZpZ'!s<Th+Tlcf!sRQa)[P%7Nrps9!uh=E@06S#!kSO:!s8RiQ9t_;mK/RUL&m-!mK/j^joL<,mK1!$c2ibi`WD>AK)pf_gB+tg%[0utBb-t#!t3ug$Nl,&$'Q#qRf`ak_Z\]r$EGc]='H$dis_+Z%F/f$!u#/PNb\Zg,?"[F"&f5h>>k^F;ZaZ8"24kI#G4pn!s,8$6NWGR!g<eR!JrRl!g=G'!Jqod!kSMdpB*AWk8OL5K-%0+%0Hh9"1&pKKhDHigB[TV#QrNX!LjMpq[!MfUB8=?%%Cl:&%_n4]+*L=0`pqJ!S[XE6NRCCK)q_LWrkuq!s+#T/->pB!s\c-"RcF3pB)?:!uh=K!)!?^!M]`q")@pi!J:ER!s+kn$&8U6"4nIo#AXY6!sFqm"*5\+"*4PH"g8"OHNP2h!t>Lu)Zp/>!tgRr$hj`BrrX2B!uh=P)Zp,]!tMdB!s8WE6O\`nVZSLQ1E-E-EAEg^!t2"/eciN%.05VD!tY,.1C*@f"#C;H!uh>?K)dD`o*($V"QM*E=$m5)isaBEhBQkA;[Z5#&1[k>Hm:]T!sYY*!Lj01"$6KU!J:EJ!NQ;iRf`\D""XNT)Zp5P!sOG^"$H`*%&[k[!N#nhVeZC3!s.!U,9$_:!s8XP"!Ibn)Zp>S!s8K)!iH,>N<:+%3u\8(!J;U!K.@$k^&p.l^B7Ct!uh=DL3<Y$'5IsXEsi))$_IM7MZXn#"#L)]6NWGR!fI8;!Jr/s!g<f%!Jq2E!kSMdN<;-B!uh=C)Zp;r1Y)Xa"dVe[[f["Z!uh=J""XP$)ZWNXK)pT,MZZ$A!s+#T)Zp30!tt^h!u1ni!n%/i!s9JE"%*-RQ3+Z#P6U.MM&V0N]/\XJM&V0NP69)2M&;N[])mTc"#pAa)Zp3@'(uFu!s\jj!uh>?)ZpJO@g//[$+C!E;Zds@>6=j]!t,)j,6<F,$Yok$!stS%,6W]>Nrps9!uh=H%0OpT!sA2u^'092!MqRU!s4Vf$Nl,&",7IV1D<Ch;[CAF!t1_'!h092!s;s6Q9t_;ecM<EV?)N:joU_UK)pfT!s6(9#gWT4mfOL2,9$^c!s8We"!Ib.)Zp4s!kSO:!s8RiL-l$+ScZM/mK&.dV?2qfK)pfO!s6(9"K_bc)>b?T&ZZ;gP61nQ!s:ml!L<f!!kSN2!Jq/t!g=q-!Jqij!kSMdg&j;:>8mYG!K.G_HNO;$HNPf$"'Yau!J:E*!K.&$HNO;$"&g`Q!s+%$)Zp8a!sSE$P7mR.G6Pqd!sQOD.g4ZImfP-D!uh=IQ3+Z#P61mf!Tl`N$2t"<"dT1G$2t!i"dT1G.\6^*#_iA:2r4V"!eUN13!05o!s@?]"$99t$(h;OY6,^G)]Jka$Yop3"bm+8"-3O_$18`7G6>6g)ZrD/1C)JqrrW:u!uh=I)Zp3=!#n!%)[4+e$OtAe)]KG`SHD_Nbo6`h1FCBNiWB4X!uh=C)g_Xa"3(J\T*#=61E-E%;\+Tb/H\Wq!s8K)P61n+!s:ml!L<f!!kT,S!Jq'T!g=S;!Jq`7!kSMd=p$_dh#eSu!uh=Hb5b1^'+2&Vb6-KO<rmp^!eWiRMZXo8!s+#T)Zp>>,7=t+!s92M',q%!,6J;R%F,!,!u!0m)Zp9$!J:TJ"*XhF)Zp;m!sR*T$NgJM!ttcB)ZpHJC'+Kh$aUcSh?rRqp&fXB!J=;\;[DLfjoYXBl?cGZ!N#r&dPE/Obl`.o!uh=F@06S#!g<]gRg#*FM$(a!P6HsIM$)$)])mTc=9GT*$H!%Z")/,.)Zp5.;[W\^$Nl+s@fmBKCB9V$;[15D4luifAcmBY"k<]Rm/n:0',q#WP>_XN"dVLVLB@ogHQ*%f)[6BHGlnB-EZ5)_,7=U.$Nl+s"#CT@"&gB*)Zp8g!g<]g])r.&`W;A,ScZM/ecCUNQ3*6XK)pfC!s6(9#f6['!r!W9:,<.K!s@Nb#O2C1CBGLX!t>?i)Zp01.g+XL>6?)];Zd,!6N^7,"#Bt1"&f>g)Zp/>WsHiMRfaT4"(;956NWGR!h0@Z!Jqc0!g=bP!Jpu?!kSMdX&oYVRg$D/Z3+eD!uh=G6NP(,!UBgi#He)n&`s4kV?-:,6ilm93JIS+o*YTjlRi):$)U,l"NCJ[!ODf`!o!bQ!j`8:")/#;)Zp/,!s:V0+Tje.!sIE^!s8WE97$baK6qA6@fbBdK)pl4"+(+N97$alK*,T`!s+#T)ZpDH!s;IH+TkXF!sG%pP9-S?G7!pC!s5;$"#9rt!UTt."+hHoV)&A%#gEGPK``7r!uh=E)Zp;X!s4qoP61nqMZZ<J"#L)]Q3+Z#MZoCIM'o_5Rg#)YM'o_5!kU>k!Jr24!g>dM!Jr[g!kSMdRKGMO,9$^h!s8XH"!Ibf)ZpB:!sRK_"X"-k!TbR@0e=_4!!!(V-ia5I!sG[/)Zp,E1]pYY6X'Wp)O;8\"+:3.OEU_`"kNhW"%+"01K+L4<Y!jd,;Ui#"p4rX!Rh,Q!s8Ri"%**i@06P:!ODrq!Jq&Q!Rh2F!Jq&Q!NQ=Z!Jq$[!Rh(=K3/HOdfoUQ%0L;H!j<OF%)W+(!nRN3%g*aQ^B5DW!uh=C',q$R,6J#u!J<01"NCO*!s:&P,*ja)8cpFk$Nh=M'+4mE$^1Yp!g<Y;$G.60!M'J5hI?]S"!_mi,?"i]"&TFV!uh>_Q3#G:WriG)!Tl`M"Qfa6"dT1G"Qf`c"1A5e)"%F*!Lj+H"/>nG]*!snBb'/+!s4Mc!LEm-*2=GT!L"RWWriH?!s:mk!L<c8!s,_1dh&*ZM$A\8ZNZWqM$A\8Wr\4]!Jqiu!Rh(=F'&S*$G-W1"#U0pXoXG"6ii2i(5;jJM[KQD;_>-Q>6D<&!Jpp@!s+TY!Ug+M!K.m!;[0B,)ZrD/!NQ;)!M]`a!s:@^!L<c8!Rh8(!Jq$3!RhUO!Jq&9!M][U!Jq&9!NQFe!JpoU!Rh(=o`I/U$QB0K-Sls\,;Ui#!s:=m3sDquG67l*1D:]0!uh=E6NMg$;Za*(!s9"]+,2Q\.k;u'1D:uh#NGmg/d'!9#Q"VpgCmXMD%GqC!WE0g!s:>X!KmP1[0%?M!uh=D)Zp04V?6jWSHDe[!uh=C!uh=\!#6(Lz"Kd7p!sOG^!s\oIk;rbbf)lHj@iGLR!J;U!!tDF9h?Wco!MsQ7!sakh!s42r'a#+*%.>,;V,J#h&C1FZ,6Jke'*&9$!J;m)+"JQ\)ZpTQ!t"]("K)>@@fmYP!t>@a)ZpW>#_ieDQNIIs!uh=Q@06Q%!UBgio*)9aM#kTslO:3&M'T5)P6'D==:(/m#a5aN").o()ZpJoK.@$3"2=p=hZFf".iSR"""PU#)ZpTM!t_X<1CNdn!t>Rg)ZpM8"Ju8o!rk>\)Zcf<!J;U!!s7on#e'mT!L4T+V0a0$"(D?5!s42rWtPWBUBU5kZXYTjSHAZnP66^DF:S!F!sP"nlN75.!s:mk!L<eN!g<eR!JqTc!UCMu!Jqot!g<Z>^B6Ft1E-E(;[8<b)7BW/Q30KQmfQK,!uh=L)Zp,K!UBgi!V6C\!KLRj7%OGN#MoK<*VKO"!S[X3$d/U8]*5fKBarf$)Zs(B!t)L>!ga!."%sR84&Z?D!N#r6!g<]g!s8Ri`^9dm[K;Wth>rHErW2<rgB!-N!s4Ye#6+cbhZFf"!uh=M%0<1b!sIK`!VZ[8!s9JE"(kgP",7I.L(bd6'.X.e!s/?&!uD%Y#bM2<l2qt-!uh=C6NQKT!UBoT!Jq9J!UBmN!Jq!Z!g<Z>Jcdt7!uh=CqfW&D'dGL@#fZs.c3$F4!s.a0)Zp/DK51Q6!s<<>T-FFB[fZd8.iSQr#3uZ'#bM2Lir^5&"#L)\6NQKT!TO?t!Jrk/!UE":!JrJt!g<Z>mfPNO!uh=D1]md=!g<]g!s8RiejBK(mK)>PL&m,?L'!PDmK&/1p&XIcgB!-7!s4Ye"-NaG,6JkeDZ^.P",7`sCD11[;ZhaV)Zqr"K.@$3!s=8Y"(N!KMcU"H@h-Bc#MX#H!M'DC%YG"="*=tN)ZpDE#,VHZ!s,6.)Zp0'!su.5mK6Z4T*&!q!uh=G)Zp+r!sY(olN75.!s:mk!L<eN!g>0q!Jr.X!UDqp!Js8=!g<Z>@os2h#kJ8t$)[l>,6Jke!sJ_Z)Zp+p!UBgi!V6C\!KLRj0!56H1qj!I*2Wc&!S[X33!05G!s7Wf.g$.ul2q'>!uh=E)Zp;rY6q$,Y6+q0!uh=E1FP$]!J;U!o)f)L%^QfZ"e-%?%AQ!;!M';@%D*.W6Z`OP;aS2#!sOA\!s=8s!s,r:)Zp,+f-pVsOooA&!uh=G6NQKT!UC!I!JrW3!UC$j!JqQ"!g<Z>rrY4_!uh=D)Zp2:>72YX!s5"q60:BN70=Z2g&i8r!uh=D)Zp,EK.@$3!ri?'"!\`e>60@\cNXIR;[15BPlh&`=rRPFV,K_;"0r"0"SNc:G66Ah)Zrt?6N[FF"gnFG"!\`e,?#VK!J=ka"p4s;FoqgK#Km4E""jW',?HZO%/UIn3s.!Ml2q'>!uh=D'*&Cb!J;m)#GqT-"hb":]`T2U,9$^f!J;<n!#$RZ!sQ(7!TsP(hA$t3!Mr^W!s@uo%ZXI,")%c4.iSRD!u3%:)Zp8O!s=D_>6os&"*XdB)Zp/a)Zq8dAQ&iZ"J#X=!s9JE^-_qe^&dO)rW.iiecG(>gB!-\!s4Ye#-@te"f<4@"*[pQ)Zp,-!sP\,!hD+d!s,8$)Zp2%$*+*o"#CFI)Zp-#!s[!P"HNX(!hC84#>56o!s6^L!M]`9!s;s6`^9crecEr/!Qu`;!Quq#rW121$N\F1"SMl>c:%c/[K2jIK)pfl!s-jU!f$k;!W!`;!s`$O)Zp5K!UBgi!TO8L"dUtI!p0OD#OVVL!j2Ri!S[X33!05G!s?4=h?-t$"!^_F.fk94!J>.i7UlN&)ZqAg!t"8q!t,3Sao_[<!uh=DQ3*6PlN74i-MBe-6gb#>1mS0!"QfaN!S[X33!05G)Zp<I"-s#=!s,6F)Zp;uFoqgK!scLA'-dSu!u1n<"gS4L)OhZJ+1hU'Q321SQ"*`G!N#r";e?,A!skG"!V6C4!s;s6^-_qe`W>Z9V?)M[`W>B+ScOZSXo[i0gB!-PRf\cSRsS6C")2fd;]>f\!kgIW#3l:,WWO1B2(A\0V/$1i"Jl2$!s9JE"%*+TQ3*6PP6ZgCM(Q^KP6TkEM&r5ilTLg?M)<caP6'D="#pAa)ZpD+K.@$;!s=8Y")AQ["&fHe!uh>"GQEm0zX/$s?!TsOf!QQ,]""aU*)Zp0A)ZplY!s4ek!ri?A!s9JE"%**aQ3#/2b:A;JM)E9RUC+^9M$L`qb5me-=:2)0!Lj4u")/#3)Zp3"!s?RG"8aSf!QPA0)Zs.D@09^96W4'h!J</)!M^6m1%kX#K1$!GK13KT!J:a\79_@Hp/;=46NN#G3!02>)Zq)_)Zrt?"p4rX:+Ih>"p4rX>oNkJ"V2OS!s,;%"5Y7A"g/CM.lAOr.jH8`,69;&!u`[?!sK,a!uh>Z@06P2!s+knUB:TT!s:mk!L<c0!QtNC!Jpp(!Lj;E!Jpp(!NQ8#!Jq&Q!M_N,!Jq$3!QtM-ZWI[;b6,?WB*2iYf)lro_]&[Yq\G)*/H[sOWrj:C"(;946NNqa!s+knRg6Ya!Ju7+!NQC,NWFucNWGmYP6$L@Wr^BE%f9?7!m;)&""+1bh?]Si!U:U+'*I)I1Fjse!R1^A%(dG\$%i?:,6b4],9o&j,m-gK""P;m"&f<Y.iSR"$S)>9.k:e+b9J5hhCAU."$n.6)Zp,s!M]`!b6%i6L&mS@rW11IQ2ugIrW/btrW.i\^&au1P6$LEZN85M$N!p1!lG5K"*F][!!!!<)?9a;!sG^u)ZpW.&,R;U4(C?5$Y'8s.q<&h%JKsD"!\`e"&fB[1LDX?;[)"[!s+`5.pE%O6NN*D9-7AB!u5#B9,dtW;ZkkY"5X,Y"5[6\f)lRO!uh=F)ZpE@#QI-n$]bB!gB/As"#L)\6NQ3L!S[dD!JqW<!S[dD!Jr/K!TPQA!Jq#p!fI*.QNK2L!uh=I)Zp0)5!)+>9*=$49+A38$Rl2D"R?*##I=H$>"\t(!qQlU4$j.p$W@53+&c)G+&cB2'jD>E)Zs(B,:a&S1BS9j"$6O9.oQVS.sV4!!J;$f)Zqr"!tV"+"5X\12$5No!s-%:)Zp5`!s,M+#Fe("!M9i$!sY(o;e%m."5Zru3suJ?@ioK%"#aY))ZpJg!fI-_!s8Ri"%*+L@06Pr!fKL=!Jqc0!UBoT!Jqc0!TOTs!Jr9!!fI*.VZSm\!uh=K6[f,!;[)"[?V;%7"5X,Y"m86Oh>sJU!Qmb3%Hdh;!s9JE!L<eF!TO7aMZV0kM$E)Dj"cVqM'q]lMZM9-"#pAa)ZpM8!s+r[gB.JR"#L)\6NQ3L!fI-_"dT1T!S.;+"dT1G5aDJ03fX5t2=:M*!Rh(+#*T+H_["@eBap7-!s-.=!ic>A!Q,iY;_="3!sS,q$D.D>$]c5/V%X#u!qcWrlN8(."(;946NQ3L!UBoT!JqVq!TP$b!Jqu&!fI*.63B1L#I>?O)Zp>3!s,t8SPr`3!s,+u)Zp+m!TO7a!UBhT"dWR!*Sph_!r`4W7.pZI-ADPX$e>@=!Rh(+3!05?!su.5Q6RUn,6L17!sJbF)Zp-8!Q,&D[f\2a],LhXZP'SPqZ3`71EsOA'*A8u^,'+P(B]FE!s?"7!UBh,!s;s6VF(CEXo[hh`W:o"NWJ/RdfG:.gB*96Rj2#<")/,K)Zp3:!s.-Yir]B?#1c-B'=Iqr&B4a-2RWYH!Rh(+3!05?)ZplYSc]#2Pljqg!uh=C1B7e=")obH1B8(M"!]l`)Zp,X)tj?R!s,5;)Zp/q!s@-W!uD%Y"g8"Ig&i8r!uh=D!uh>$)Zp2R!sakh;e%m.4(Co*"5ZZc`rc]B!uh=I!JCP*ZTA9L#4jGJ=#15Jdg+&0"$:?.6W4/k;['<+Hm:-D!s4ekha7Jbk5u.qUDj::#3u?m.r,1(CB:JO"$13:)Zp<-3jo,PZO+6B/e,u1M[bS3CB9t2"l9ID9*6tl"&f5Q"&f<Y)Zp6A!s/6#ir]B&gB0eDr\O]XecFM0mK&.Rp&X1TdfG:P!s4A]"JPuXr\YVs!Mp`"!s52!V?i)!6ik1p/EQuN_[?L_],[[K'?3HA5c+RG!J:E03!03)!s=Mb"(MEPCBG4M"'YeY!J:d/%`8BY@k2&7%0HX3WWO1B!uh=F]648Y_[3pV$MuF`<tc(=gC1\U2$7\)!s9JE"%*+LQ3)sHM[&#=M$M<-j"p*(M*7F2MZM9-"#pAa)Zp5VFoqgK?UHmW!sG>#"m#h*7fs\4!s9JE!UpMUT`YZ)"![mK.g$Fb"#Bt14&Z7<;ZkkY,9mH:#.4P\eH6`m@iGLP&6f=@!!@!=K6%,.HNRIQq?$bN!uh=E@fR0X.jJh>P%,]M!M';n!s;U,!L<eF!s.-Y!UBhE!s;s6SjNP=c2rn8Q2uh,c2m57`W:o\c2lZ#NWFu$`W>*'dfG:k!s4A]"I0'K@nRaChFeSF;[Z5#$W@53!s4VfP61n+!s:mk!L<bu3j&M$"$Rdo!L3]'#GM;(eH6`m!uh=G'3ttJ0FJ!>$O*[P!hTQK!s9JEhEq>(mK)>QmK&/.mK)?*dfG:B!s4A]#/(*uJccqo',q#S"+Lsd!uh>"@06Pr!TO7alN,!mM$NGLir]2\M%cH]MZM9-=9bN%"PXC_")/%I',q$r5m>^N)Zqr"!UV*6"7cO'hEr4a!t\*-)ZpAG'g$2@!S[[.MZJM>Rfe9F$e#@e#mBR(%-n/ib@_<KK*1]KP?T460b0ZS!Rh4Y@fct#")oc#@fR0X.jJh>P%,]M#PnN'2$4d""-jf-V&LZ!!Vum!Jccqo"rdXNg]IC)3!.S2!!!+`+ohTC!sGXgL0YGp',q#U"4dQ!")e9?b8lK[OVGtZQ3/?4)[fRj:BL\$?NV5L!ui0].fk8QB*JG?!Mq"V)ZqPlK0'/K!s:%S)ZqU9(BX\j!N$e<"*Z=A!uh>/,9$_';a#j;K.@$C1BS!c=p"eX!ui0]9`oka"TfVF!!!(O#QOi)!sG[A)Zp63K-LI3$S);[#3Q'g*31"\)M8=]#1im3V+V?-"NLTF!s9JEEs"dV/D`2c.Gb*+h>sZ&S,oZ.c2jsH$N[:>#PJ2!HU^GFCB98e3!0PP!s5q6!s;I@.g&^qmfNTC!uh=G@06PZ!QtQI!Q,","g0Za#L3@f"dT1G#L3A!%B]_g"Qfa.!P8Ah&&SG>Rgf0rBah$J!s.imecPjj!MqRQ!sAQ*b6%hc_ZN7,Q8A[Ec2kfdmK&.pXoZ]N])d`tRfW*]%&6o/"02UC!LEn&k5uY*$QB0M!J;<n!sHXHb6%hc!s:mk!L<cX!V6Gc!JplL!QtT-!Jq'\!QtPA!Jqij!V6?(Mc^>@dfY4)4TfC,"j7he!s-:iqg/eLdk`TbSIF6XgBic=F9@g;!s-.="#9rt!ga!.a"nY:!N#r$!s.*XXogI!Nrr;c!uh=C6NP@4!s-jQdfl%GM'C4G!R"4=!JrZ4!V6?(UK@i/o+%5mG6;Of"#Cku4&Z=F;\-;="0M_n"*+KBo)f(6!s+\g6NP@4!V6NH!Jq!Z!R!m.!Jpoe!V6?(rrY4_!uh=C)Zp,(!s+qp"%iY7"%NG4`W>0?)$][N!s.Zh!t,2Mrau8*!MrEu)ZpNOFoqgK+Y"uE!s.!U!lY6\""P;m)ZbRi!J=SY@flb\K`_@..iSQk!J<H9#+I[V"*+Je"m.BU!s,5k)Zp/L!s-jQo)f)'!s+\g6NP@4!Rh(0!Jq!R!V6Q9!Jq!R!QtQ<!JrGS!V6?(gK4j\dgYOIZ3+eE!uh=CL0YGp',q#U,6J%&!s=8kncKOURi;G2!V/#W!j)P6Z3)$J!uh=DjT:)=!!!!"T-"%5DZ^-C_ZLh["(;946NOe$!P8N$!JpiS!Q,0!!JpiS!P8E)!Jq'<!TO3]o2l<OP6Z^F(B\@S%0IOO&d''T_b1pNK*9p5"&f:&!uD%_!T*tu$Nh=M9*(^g!J=;Q"LA9T&%bG4$mQ8Z%J'bXRgoth)[2E4b6tp[C]sV@"[Z,i)Zs(B".Kjs,9m`r]6OJ\3@e2;N\bn^4(n]s`rc@&!uh=C"%-i+.l7?<#ibrTX$#6V:^a-'%)WRmRr8AoRgbS`!LlIX!LjV>rW/JrmR:Uf1[]#`UK[bU=:2qH"g\I*")/82!uh>\6NOe$!TO7a#DN8F"3pr-"dT1G"3pqZ/Zo,2#_iB?+.`Li#Q=b9!NQ6X3!03A!s,;%!N-#=^]PMXNX:UE9.0lCK`_@9!uh=C!uh><p)O5;9+(h@$AJrS)tkrn'*/aK0G>.lK-LI3c3#Qtb;3'1rW\)e"*+JE])r-S_ZN7,L1(/bmK(30^&a'SmK'p(Wr\%^!s.E_!La*Mo`H-8!uh=CQ3$"J])r-9ZNEPq^,,omh>uXaQ2ugHh>sqdQ2ugH^&bhHWr\%]dfJJ0".NC&"cE\>!R1^\!!!r?z"KKrl)Zp<I>mg`:)%-NKT`YZ)UDBU*C)DjN!!"8F!rr<$!sGZq)Zp5p49Grn!s.]i#)`ik!J:O0)Zs.D#I=nm"#_".)Zp2_4#76@3s-u5"%**A"&f`E/-?3r=T]TF!s,;%MZNPk""aTU)Zp-(-lW6j!J_Tr!J^a\#MU1"NZ/%]X!8hi"T&91%J'mYZO$.T$Wehb%%@[[ZO!=C/ckhR!ojI]b8XM=D%;I+@ljbp;'R"^!&HD5K0'/["#C#["$H`U"*t%g[fZYo!uh=C1]mcR!NQ;)!ODkq"dWR!-M@J8"dT1G#G(t&!j2Q\#IXZ6!Lj+H$'PD=gB<F:B`YOF)Zs7G^&nCo!K0ks!K/"bScOa;$NZ.u$I/[1hF.Ht29&i&P=kq5"#pA`UDj:mT`YZ*>6=s.K*)3C^&aN#c2ih?!s,2+"`49u!s,;%WriGCUB<jaQ8A[E^&au4NWFt@V?*_#RfS?PgB#b(%%C?#"T&Y'")7pP!ODkI!s;s6"%**i1]mcR!OE$F!Jq&q!NQBi!Jq&q!NQ6]!JplL!M]ga!Jq#8!NQC\!Jq!:!NQ=Z!JplT!Rh(=P?7pnq[9_@%0L;Fao`RbM]2a!.*_nq")S-=Ld_RgA-1rr!pfr]!fR0XzWmr$g"!7UJ!t,2M!t,22!t,2S%0HX)'S@>,'$CE1PQ:fa!!!!"Wr`8$%g)s8pB)?:!uh=FL0YGp',q#U,6J%&!s=8k"#CT@"&f8])Zp/V!s,G)ZNC:d"dVLV!mUhI#Q=a\"/Z+*!M][P"4I;*"lg7u")/:pf,Fes1C/^;[fZZ-1E-Ds;]tc9K.@$;!T*t[!s9JE!L<c@!ODk1!P8G$#2Wbj#3Gs@"dT1G#3Gru#3GrC"3(AJ!M][P=Bbg\$(D-o")/%1!uh=Q*XnMS&gIq!!tPJ;!t,2MmfNTa,9$^d!J<H9K0o_[9*6[F"$6O9Y60%P"+LCS)Zp2/1H!0*rrW:u1E-Dt;[&`pK,Xn#"!\H[!tPJ9"%<;2!o?6_!s,5S)Zp,#!ODk1gB.OFh>roCrW1aW^&a&mrW0>1XoX@]:'%[1!M][P!K.!5HO-ZS")/8*$QB0QV?7(@UCY6C/cpq:$0)8KgETc]D#rB%+Tje.!s.ck!P8FQ!s;s6!L<c@!ODk1]*Gc3M&rMpgB=)KM&rMpZR5AHM&OY?ZNK%bM'("DgB"&M=:W4L"T&[m")/1E!uh=OiYqu'1C)b;Ook`]3u\8'!J;U!"muIK!eLMQq?%Z=!uh=CQ2umG@flf6P6$D*,Sc%75ir*2!LO#-1nF`3P7%DTM[>CE$)U,lM$:%l#_Q%VPliuJ!uh=D)Zp+u!s,5#dfo%V7Ln_r!TaIe!!!(O)uos=!sG[R)Zp;r6Xp3#1]pqak$o[nP6%F+P;K]K!L!Qc!L"AoScP#_r^C$[+mrhDRo9?E"+:7P)Zp63!s=kl!s:=u1BZKZ1G^mEQ4H7`!Mq:M!sbG#"SW!;mfOL2!uh=E)Zp5`!ODk1!NQ;i!i@dV']oFs3fX5tM+.NPgB"&M=:W4L$Mt"m")/:()Zp8Q!s8o5EXMsO!s92=!sJ?#1@@4C"g/Ce2$B+)E'$-;4f0Gk6Q8C."0VeO!s9JE"%**qQ3#_BZNmo>M$L`qgB=)KM$DN3gB>4kM$BgXZNK%bM$<kZgB"&M=:CAo"+p`/")/20$QB0W'*A=e!J<01#F5HRc3$F4.g&]OB*3N+f)lro!uh=D)Zp/&!s+qp.g$G("#Bt14&Z7<;[8lrHm9j<,9`p/$R6lD!J1CuQ9-#f4!uff$O-\8'*A=m!J<H9!j2Vm!K@1[!s9JE!L<c@!s-"9ZNC;<Wrk]ihD><8h>u@8Q2ugVh>t4lh>rHI[K3E4ecCU@Q3";nUB-39o)[SH%c^XpBgW$X!s64>!hTQ6!s9JE"%**q@06PB!P8E1!Jpl\!ODj!!Jq&i!S[XMK3/>a!sH4@"'l"C!i5u<!J_TrV'?/0"'#F(6T[@K!s:W(,6aA;!M0gc!l@#$!S7DWmfOL2!uh=C6NOLq!s,G)Wrf.TM$iAGZN@!)M$iAGZTj`VM$:TogB"&M=:F3j#+G^i").u2Ri;GGgB<]FZ3,%aoc!u7.kgl&SHAnh!uh=E)Zp,kEYANW"5X,!"!\1P"18454'*@'U&utL3u\8'-SkplQ9,>@2Zmh!"-XZ+;ZkkYQ3.;so`J+r8-P1X1BZJqqZWH:CB^"*!s>Y-!s:V(ZNC:6])tD$VI9Q-p&Vc,[K23ic2k6VUB-2qqZ5FP$+j:G$]>/J!L3b$V#qY=!ZM4D!!!lW)uos=!sGXSL)U4:'+50L)%-NKT`YZ)!t>>5M[%?DFU#Gj!!XPIz"KLnn)Zs.D!!<T2'+6V1P61j,"%EA'UO3.OZPq"!!s,;)VF,\4!Od=U!N#mSM#jK#!MaE2%g+cn2$4d"(BYTY#6PnI:BMO<!s9JE!s+]d^-aCQ-e;K'^0:W5>=;[<$X4p[;[)#^.fmXY!Jpis!s?^c"'PddUB:T;!s+\ghEuVl#JPNe0!553#1`gM"5X'8M$O$,!MaE2Mc^"TZNU./%0L;Ta9!:_!!!0('`\46!sGZY)Zp,e!s=;\"$6T(6N[EISjB5@!tB<,"Te@=)ZpNO!s7on!hTQ6!tuUU.fk8I;`]X8Gln-f)Zs^TF"ZTr(s[1jp2^U_hF0L.#)5JLHSY\Z70=Y7UN7@V;`i83)ZrD/>mg`:'*[5#&'G%_9`kJ"")AhX?NUK73Wg<'!s9JE!L<bu!L!Tf]*,i8M$LHiP6I6QM$KUQP6J)i!Js8H!P8AbZWIG/Ws,7-'a&.QF);iuSHCGG!uh=C6NNAQ!P8F9"3pq5#1`ge!i?!T#2TBE!J:E03!02n)Zr5*!L!TfP6Kf1M$Eq[P6TkEM$BgX])dNb=9?A@$F9hu")/7O)Zp,P1X6)D!J1DP'U'I<(s<&?!R_'Wf`<#o!!!!"\/52G[fZc6!uh=G6NOLq!S[\Y"dT1T,d%0S!TjE>,d%1&"HEM>#M&p^!M][P#1EV-dg:Y/Bb-+&!s6dN!p9Y)!L"H);_u,i!s?"79*5hH%c[SB"!Ib>)Zp63"O7(`!s,5c)Zp1t!ODk1!NQ;i#1bU5#2TB]"82bP,0g4q!M][P3!039)Zq/a!s92M!sG4u"KqnH"7mH6;[):c%YFo]1G02j&*!r]K51LYF9Kku7[=-<"6V15K)qhOZN7rR!s;UB"%**q@06PB!P8Hj!Jqij!ODrq!JrMM!OE]i!Js%4!S[XMUK@igq[V'YrrZs@!uh=D1]mcZ!ODk1Ws+eVM$!YWZN6p(M$8n?gB"&M=:"d)"k*VO").k$P8aU82T>h'!uD&<rZa?@bl]a(D]8cZ/HZ$;)Zs(B!s7onjoVG"!Mr-e!s-(;)ZpHe!tt]f)ZbRAZ82^&.g#kS_Zd(h/d]E"%>tRgUFTCZD%*HO!s/E(!QkK`!L"H)!L#bANWG>3$NZGFM[fcO"nk@cM$NHY!Lm!g:BNQY"!\`e`rejZ!uh=C1]mcZ!ODk1ZNmp+M)F]%Ws?'6M$M<,ZNd9-M&OY?gB"&M"#pA`!uh>:L0Y/h',(HM)Zp1s")7oO!s8WE""+1o"*+J_gCjZ.b9Huj;[):h)Zr;,T`YZ)I4GC#"%iY)!K@1#*s3Ga'*B0U+p/!(%0IOON<:+%!uh=D"%-Q#Q2umGK/pXHV^fCe!L!Td!sJe')Zp1r!K[He!!!&])uos=!sGY%)Zp.s)Zp<I6[Jn;!s+#VK*@QL!Jr]82L>P_/<0afM$:&/!MaE2]3#DmqZ<5lpB,+7!uh=C"%+R@!L?XdmTUX5$G.QD6sD77>9`K>1tGk=!S0\<M#l0XX(*(L#kM.%&).5V!NuT>Es!?`!s:@^!hMc+M$!ZtHO&C.!Jq,CirPoj%F\D_"4I;J"'#G;HNO?hHNgQ>!Jpm?c?fkpCB98!3!02V)ZplY)Zqht)ZpNO#QkG:'+Og@!t,22!t,3#RKESab8UNaZNZg-)?U!R$Nh=M'*A4:lN7+p7L,t!)ZsgWkQ-nM!!;Kgz"KRh')ZtQl!s.im)[OV+,6J.&-e8EahZEoWP8aT+K.@$7!s:%S"$Zkl!m^rf!tuUU"!`:/"&fKF)Zp2?"I9-7!im8=NrpI;!uh=E!uh>,$XF,B!J;$f)Zp1sjoZhAhZHe,p)=)8G7>c!!s7?^9*588HNKL#HX@lg7!gGUHOB1f!rdNS!N&:YM#mTK!J<H7AHOmoUB;G;"(;941]mcB!Lj/n_ZL!.Q3!9P^&a],L&m,9^&c+VQ2ugIh>sATh>rH:h>rfBIK>9/"g.lq!K-u8=??Q$UMC:M`rg#V!uh=C6NNYY!s+SfP6Kf"M#iV;Rg.FEM$CZp_Z>Yr=:N.K!Q,8>")/1u!uh=o!uh>/(E3G]#9u+o)ZrM2(V9tM!M0bd7jA94!u1o^_ZKu[!s+\g6NNYY!Q-nR!JpiC!LjD`MZJZ`Wr^*=$N!p1BahU`)Zq_q#L3@P9`kVF;?Ij?#L47j"*\K))Zp,(,7!oO"$H_k4Ttm+zXGe"s!M9Gs!s9JE"*Od);ZJ=@;[&Hh!s6LF#Hn4K$-sOmV.0\K!u_7B$_IM?#i?R'1Bchr!t)dF"%r_8$KhLB9*6+8#b(fE#`AnVq[\T;$Wg77#K$kC>6@609*53IQNJc@!uh=E"'lQB$NgJM!J;U!!sH(8!t,2MCBFU2ErZ<;;ZqgWK6m\F#lau-"HFE'"*\ZV!uh>,Q3"T"P61mf"dVLV%FtQl#,VEX%FtQD!QG.s*Mrk$!J:E03!02n)ZspZ!%UtM'3c,^!)mA0K51Ps"m5sgQ?jJP!s_I`)Zp,%>7I>`"%r^s.n]sq'*<mg"$7/p!s+$Y""XOI)Zp>K!L!Tf!Lj0YMZ[AiehdI0XoY!rQ2ugcXoXFaV?)MsXoX^fp&U!nL&mJ>K)pfpgB"ne&'J&b%@[ci!P\_N;Zds@!ep\*!u"lP$NNh0!J>.i;.B\A3<K@^5ILYe!SRWS'*B0U!sJpr)Zp/^)Zp<I!L!Tf])r.&Q3!9Pp&U?\joL<&p&Vc+h>rHs%KVaq!J:E0#`A_qo*"qmBa^sE)ZpNO-lW6j!Q>u["G['_!im7B'[$j\c3##+o-70Q;\Ipq"-*I6!fn:!!s,8$6NNAQ!L!\Q!Jq!Z!L!]\!Jr#G!P8AbC'-Et1'8Ht9*6+870<uVncKg5!uh=D!uh>d!t@sD)Zp/F%Dr[VK)pZV3t9@?CBWAtis>mYZOc'u%\mYC#ic5\1C:B3__D8:]+(eD(u>;s)\[9+!J>_$/-BYi)Zt*_!s@uo])r-S!s+\g6NNAQ!s+knRg#*dM$:$_]*H=VM(Yq3Rg#)YM(6LGP9S9QM$MT4])dNb"#pA`)Zp,p)Zr#$!s+knP61nq#1c-B"82bb!L<bC!KI2E!J:E03!02n!s-XKP61n+!s:mk!L<bu!P8N$!JqAr!L!c>K)pfE!s-"7!hocV!tuUU"&i',`</+&!uh=C4*C].qZ?p>ZNp(1$1fbT=!J3MM[-j%%.7s?)\X_892QWi;[/Ni7FhQ>!Oi/0U&u>:b8UNclO:r<42(\(b7d5V1C_e7!QtLt"1n`[9+R3lRgBD]%D+t5MZh49+p7EA#b)@JdkM'5isVUi!t,/6!s+$QqATMq@g85$l2q'`P8aT+gB#1rK1dg!SHHb;RgnriF@MQ&!s79\9*588"$6T5!r<!Mr<!u@>8mYF;Zs6*!sI%FCBFU7`<.Xn!uh=F'*'OU!J=;QK3JF."'l!0$TeG0'-64:9*5hp!t,)J!s+$Q!rsQM!LbN#!s8<$$*+.I!s.^T"TcS8!s-gP"N:H^$QB>O"TjcSL]Xphf`C:<YZPiF!!!!#mMGp((BXf?Nrp='!uh=C)Zp,=)Zs.DQ;[kf.g#kS>8.!'>9k<)6sCkl>91^f#F8R%"5ZIFM#tsQ$bI>Y'a$DtZTB*.Fq<U=6[Jn;VL&?@joL;>#JPNhUMBme"#pA`!uh>L!rr]:"+:OZ!T"1dT`YZ)HNO?NUB:TcQ3!9PjoM4Xh>rH8"l=S.UMBme=96#7$bHQ5")/:(!uh=O!ZM4f!*fThz"Kfo`!s5q6"&f:@"'Z]E@fm)@!s8RV"$7o8!s+$a""XOQ)Zp_>*uc^<!tgRr$SJk,3su^;0")j;$PR:`"!;;G)ZpcJ*9I?E$h%S(3ru2\;^RM,.@(''&AL#"!s,8$)Zp2O!s=Sd$O<gR4!PDKY6,kVh\uY/@l21,[fZZ-!uh=L6NR&d!i#i"7@jOG.`MOb+6ET\$.].S!UBcC3!05W!u'8g4'Me+$SReG@nRJFcN>8!Y8[QX9-p/?T*#+j!uh=N"'lQB[K$CK'-dkf!tC"f$Pi(KpB)'J;]>fK;['T3!)$MuK4>!N"'Yj.&B=lB"f<4@G7NM7!tXi&&GH8G*s3Ga&_e6,(=Nr/$J,@cY<s62!N#r/!W)s$!eUSB#2Wbj4153C7K*=EM+.OCUB0Z]"#pAa)Zp\-!sH@@"%r_8mK6*5^B7CS!uh=T)Zp]H!scRCmL[,P!Ms9j)Zs(BVc*cmiWFB;!uh=C)ZpH!)ZsOO!s.uqqZ?pW"dVLV5h5u-&G?-]#F5Df!UBcC3!05W!taVt6ORKFK+5.#;\>l8)ZsgW!J:W`XoZ3<'/L"$+#>\t3su.Fh?-+Y"%uPn;c<kN;[2pt!s52!qZ?p>"5ZBG+g(kC2!+gq.aA(l!UBcC3!05W!s>G'$I8enSm*-9"#*@[>6%$#!J>.iEsi0&!nRMf"%sR8UJih3!s6(@%)W+"#R7%sMc1/P!g<ot%a,1=lNsV)+q3K4%?h13].j]2o*)0$3s,Nf6N^\";ZgB:^B6"h$QB0Y!J=;Q-qaXE/-@s9'0?SF+$2Ol'13.N!s?RGK*,<s"&!\9!J:E2!s+#V$c`?="2YuZ#?(g"!s/6#qZ?p>!s:mk!L<e^!i#pb!JqZm!W*)P!JqZm!W+h4!JrJ\!i#e^`re:'!uh=C1]mcR!NQ;)gGb-[UF<POV?,EP6j\J^26Hu7gC"&:UG91X$/S)O"NCJC!Lj+H#O;ENCCe<b").i&)ZpMH/-BAa7[=-dh?.OlI03D1)l=PV'3bs1+'VqW24e#V!QY@_!s+Et)ZpJ_3su.F$Nl+s"%s:p;c>pK;[iX-!sdE[#5\KA$N[dO!J<01-n>B%/-?gn#He.JXofnIcN@)YXW%?D1C(&bQNI8b!uh=O1]mdM!s4)WqZ?q/#)5JG&@MXm"5X'8&@MW2#)3/8&@MW:!q$)G+8u<<!UBcC$BkOd_[</@Bb/r*!sAB%WstgC*tA)R!s;1HK2Vk69*57s"O@/u$ca1gV+Um(!o3qZeH6`mrYkqB"M[k;#c@cK!s9JE6N^]u)Zs4F*52CT!tume)Zp81"&fQm$\JJ6#3-'VCCel"b6\EsWt1s.!S_5t%-%K^qZ<N:0b:l)WtPQP"*4MP"&g043rfq@K)pT,HNO?N")@ue!N-#Nh#eSu.iSQk;ZWHl!s>YE!s8S$!L<c8!NQ;)gG6K1,R3rC0tmgDgI)(sgG7ml!S[t_701jQ!NQRi!Jr.p!TO3MJcdt7$QB0P"!:0/""XO9)Zp3@;ZVLQMZ[/`L&lo-!L!ln!J:IfU&uqK!uh=C"*ObK3rf@U!J=;QK3JFF"GHpY"-jf-#?q8\!s,e3"Hij+,7>FmrrX>^!uh=D6NR&d!s.uqUB:TTQ3!9QXo\+t`W:o'Xob@!V?)M\rW2mblN)i.!s54u"k!K4o)fp6"#L)\6NR&d!V6NP!JqVQ!W+[-!JqoD!i#e^o2l70ZO?X7^B80P!uh=F)Zp?)B*13tK0o_S$QS:0Z3(b5!uh=D"Ttl"!sZLB;ZaBH"*Xm])Zp?<K2Vk6"%*.k$Nl,7",7IV;\Me3;[):c!sH:>"O.#fo)fp6"#L)\6NR&d!V6QQ!Jq&9!W*%d!Jq&9!W*&o!Js*s!i#e^X&oJIo*NkSN<<l'!uh=G$NOB]!J<01;(D_^3<K@&T`YZ)"m#ge"'Z]H92cnOV?6peW\X_XV#q/2!uh=E)Zp2*"2[D-"d]<#!s9JE"%*+dQ3*f`UBQqaM*1J5q_-M$M&P4OUB0Z]"#pAa)Zp/iFoqgK!';t=.m#7+!sPM'"'PdG`WE7]!MrFS!s,5#NX3K@!MqS8!s+PeHNfiW"#C(?)Zp/Q!(15uK51QF$O<g8@fmBc_?2=k!uh=C!)!?F,DH5WK**f#"%E@n)Zp<("MG<"9*6+8"$6Jb6NMg<!J=SY/-ANI!s>Y-[KH@F!s_a7)Zp/i!satkUB:T;!s+\h1]mdM!W)s$qZ2^EM$!AOo*(E\M$!AOUE?'.M$!APq];=0M';9fUB0Z]=9uM?"T&DH")/+S)Zp/QbtAGn]`V%2!uh=E%0Dt;!sugH!s;aH9*8CD"&f5Q"&fE,)Zp,CFoqgK)[cb&$Nl+s",7I6K+faC!knaB!K@1[@fmYP!t>=s)Zp5>1K+MD>6?)M""OD)!s+$a""XOQ)Zp2=!s.uqqZ?pW"dVLV2oYmi$Dmi\"J,Yk!UBcC"PX!Qdgq@=Baj#'!sYb-!r<!<mRnK$(C%PS)ZpNO"9&[sN<9Da!uh=D"%EAs)Zp;0/B.gu!s,5k!uh>2"*ObK3rhW8!J=#I;[Wi5"%*/(1ID6q9*6sMSHAnF!uh=FQ2h"K'13-H!$b,=!stt0!f.7(K`UB@700=f!Vc_T!W3#3!Mfe`zX3W'l#2]LcIfgVl!s9JE!s+]tN^Gl1*enGSrbDP06itP!CHTUP&[lH_4&/4S.fkK%=9ml-$]>;.").e:)Zp0A!s[cf$QB0JV?8%C!s;I'hZG8G!uh=D@06Oo!ODk1!s8RiQ9t\2c2j+4Q2ugpc2k6TXoXA3c2ih,V?)N+XoXG%HNAs,3!02f!s@-W!ttbU$QB0JecR,srrZ1(!uh=G1]mc2!K.$^K*C+!M)N'KM[-rsM)N'KMZosYM$BOP!OI+R#6Qpfo)fp6p&ibI$QB0Kh?+u&!s;I*T*$J\!uh=Fj!YiK1CiFP!Rh('#X\pqb9ICY%%@P0#_NE+K+6":+qMR!di/OE$*u>j"If\o!ttb<'*A=f'*A>HMZX&fK*+IAQ8A[EXoX.Y`W:oJh>rNdHNAsV3!02f!sGM(!nRMn,6Jke'*A4J""Xk]!rrE:,6/)j;[.sY!s-7@MZX&#P64/Q`aJrMNWG=E[K23c`W:u"HNAs?#."?:K*nY]")2fW!uh>$)Zp,=!s8o%!ttbW$QB0JXofmK%0KN4'a#BW!s9JE,:b/]!s/<%")\2S!uh>GK.%Z@'*IP'"7lPI#La(@,6m06K*_mSK*/Fe%JscI!S[_RWsRf10aj`d"T&Rj!s/M0""XNf)Zp-8!s+SfMZX&i"dVLV222-q"g.l_!QG.u!N#mS+3jnFZ[2_0=:;G9#J1H:").h;!uh>R6NN)I!ODk1ZShiMM$Jb9!K0\R!Jr))!s,`T!TF2@XTKLEb8UNc!sn2u!ttb=P75&S!JLUW#J1A-3sYoR#mI(;$aU&$dq8oDirc=e"f!7C0cLS&o)fAY)Zp-N"![dR"&fH=,:FK5!s8WM""XNf)Zp,k!s/&s"6'D%#*Tu.$%iA]"0r"<"pZ(L"UtqK!!!cI(B=F8!sG[K)Zp5X!TO7ais,KM!Jr]8!TOC`!Jpld!TPc7!Jq-&!fI*.ZWIR@ZO`6*T*&d<$QB0N*sL\?"p4sC$0D=o#6.=p!s,8$)Zp2O6N[FFXoh<1"&i,^"&fKf!uh>')Zp-@>n[;B$O)h8',qlEh?+uEmfQJh!uh=F)Zp-(5->*V!s-/H!uh=a)Zp63!sS,q"#9rt)\YRX!s=9=',qU#f)oc'NuJ0)3t\n)"%iY#!nRMn6Q6sH6N[Dm,6K(kmfO"S!uh=F@06P"!L!Tfo0Vk4HP!=_h[\rSOokjg!uh=C!uh>/"*ObK!uh=\)Zp5p)Zrk<$BkPK""b%Y)Zp,X!s.-Yir]B?#6$sj']&lF'=Ipu#6"Y`!Rh(+%Dr7*)[`WJ")/4.)Zp3*!TO7a!S[]D"dUtI%^lDm#,VEX%^lDu!QG.s"HENC!Rh(+%>t:Go**TFBb-sL)ZspZ!"3QEK6%,^")@u>!P/A&IfgVlPlhs-!uh=C)Zp.s"7mJD")&"I)Zp/4.$anQ!Mp.H)ZsXR!s.]iir]Bl"dVLV#M&qA/<0af!p0OD!Rh(+$I]'7dgh"4B`YgP!s6FD7\4?6!s,6.)Zp+r!TO7a!UBhT"dWR!#/1-(#6"X[#/1,u"HEM>$GHQ$!Rh(+3!05?!s7Hap&W&M6ik1Q6]M2b_[?L_Rg,_j#)5PI29#Z\!J:E0#/^Jb"%<;Ojo[+Q"#Ek<,?"i-V?6n-!t>>5m2H-HN<9=c!uh=CQ3)sHir]AalN9KTVI9Q-rW2<c`W:oQQ3)sL`W:nsc2lr_dfG:IK*$r3$enbm$F:)_!kJJJ"f<4@G6506!s5;$!s8WE!t,3S%(cP6;]DS9!s.*X!s-:Y"&f`u)Zp2:%YG;P!t>=C)Zp07"-`rl!Ta?@zX.:F7"8;m#"90;B#873:!s@uoo+TjtQj0#d!P\^;rrX2B!uh=E6NNYY!Lj>.!Jq$C!Lj7Y!Jpm'NWGVuMZJY<irR$u%@^H1$%iDV"1JAH'*B0U!u"-+"&f67)Zp09!Lj/n!L!UQ!s:@^!L<c(!s,/!P69ZM!Jr]8!M]n6!Jps9!L!\Q!JpsQ!Q,,u!Js#6!Lj2J!Jpp(!Q+qrZWIY%lNP05%0L;S)Zq#]o)etC$NMs`K.@J='*Esi)Zpa0!s+i8!MKT'>mg`:!!<l:K,Xn#!TsOc)Zq#]!u!3f"&fBC!"0-lEt\Y1,:`j0!t+W"irOcg-n>B)$3N3h!"0_J,81-u)_2"(1BS!b!s8RVEW[^?)Zq#]7ft:E!s9JE-e:XXUCXe[$^Q,?VL(^XHOG0378![4IS0^]#-.c]_#j^j")S,@!JLUpncKg5!uh=C)Zp,0)Zqr")ZqYo1(s]f"!n%n_ZKu[!s+\g1]mcB!Lj/nP6.UKM*R(%_Z[[SM*R(%!LlOZ!Jpi;!Q+qrRofg2lOUl@_?4KY#9*aG!f-mPU]KZ_!Q8LLzX+M8i!lkBG`rd7_$QB0LRf`a+qZi#["ktX3<uVP%M[IW@)ZspZY6,pM!uh=C@06Oo!K.$^ZNC:sjoLbKQ3";mXoX@rNWG=IQ2ugFNWG%Ah>rH9mK&4JHNAse"R?)pUB.]'").i=!uh=O!uh=W"(;:!hEs@,+nf[YSd4jCCIDqj$YqW66Nm*u3s4>.!JpoU$_qbnUCPILB`j8(!s,k5!t,2MK*).J"#L)\Q3";oMZX%^!QIJ-!O`#]38O[m"6KWj55##6"Ps0;Z[2_0"#pA`!uh>4!sMR9)Zp,+)=%F3"'PfM!uh>O"'l9:'*A=MK*1]I!tPJ7!M'<3!t-%M!s-Oh)^lX-$_%X<C'+Kh70=J2704D1!!!&](B=F8m-O'>m(JOLa01heMOLi2l_!R/L:i5HL80dAKS>!9U#CZXiSibSL:i6!L80dAKS>!9U#CZXiSibSL:i6!L80dAKS>!9U#CZXiSibSL:i6!L80dAKS>!9!/]'U!!"2Cs8W*!!!!-$!!!6(s1H\Y!!5(Ys8LLJ!#kM0!&mONs7#+M!&C>Ls74;4!!!B+!!!3'!!!'#s8W*!s1&F8!!0A)s0qS"!!&_m4CKW<4rXbU51Im!4\L#24`[aA5-.e<_Bt%5rc$(K(KmcuL]+CbVh;p'io<h1G3j3mI6mWBX__#S#)8oGc9#X<.7Z-#T,1gpAkWONAenu357Gg=CR$*Gc!Efcc99H3B"q@Jc4aeB4cu'8cHQocp2OpPc3%[BphLrUA'WSDL^.Ml#L<<kA2YprAdn<jc6Hq'A.NhfcK1FkDucpB#L6"V4@$X%c2\<K]<MeVJZ3O,hl!I8;@!5oAiF=VJ.g-gRj$Hi0JU]c\S0G:V<A&M[LUS1:1JJJV_$dT"XDM$Anbj?c7ij^bfYbLkr*D$cKbFKen\:n:>#,WB"(1>L`g::%*nNpp?Lf8Os4N6N__p2*bGUg-WLJu>Rnr<B#%D8%#^*r#gS9=b350TD5kq_?=m8N;"=_6AeJ^*c9u8Rc@H93,JmV18\o89AieO4AnGWic3\)+GAXf&Lb>m]#\k9=`ZFc"d,C^rSn:W-Lh9UuDrM5OO17Q^.b%P3c=rp]QEi7S#3s0Zj##HW4:GhI^An66F7og`:llUr>M0G1miU`k_2DPN/S<ni6"WAo#L3fk2Xlc1Ac[)iAsHt8Ad`3gAh%CVAntufc=^`DZanTm,RZ(N(!beGW4B^%GreKTHNR!sU)dT?12#M;\-(%=!G8tn&S<"p%q[V03M-N$N4Pf/?tL?i,0kLHoqmP.Yu4BU4Uru)H+J2*AX695+bG2?Xa]$kl0;pVG%O+K/].k>@IYFoon_89p0ELRiXlF@WV#aXAe\jbc3S#\WeN23B"Y9!$O2SNeHU]a-NaLO&sF7:'Vc+i!t,2Uh?s]q$NkAL'a#'N!Wa5B!!!!&z!!!"`!!!!i!!!!i!!!!iWn%:Q""+0R!t,2M^'b<Q$NkAM$Nij#!s,(tUDj:E],UV[!WdBS!!!!'z!!!"&!!!"&!!!"&zzWmCkK!t,J>s8W-!#QOi(/KG]91arkJ!$rdOz"KRI^!s=Sd!s\oI"/c5?!O`pL"%s"(!KIg!;%"<V)Zp<I!s.QeLC42'%0Hb9)g`M+)Zp'J!sJb8)Zp/N/HZpo)ZqPl)&!)[)Zr,')Zr;,!K.$^P61iMG$tIR!QG/(#-Iu`!M0=MZ[2_0*XL3qUC!DG70@iG!s9JE!s+]t!L,YJ%C6/^!M]jRCBff7#0(FHY%nD\Y!lh'!rb7cF"79J"#pe&!uh=I)Zp+u*2=Ij!Lj\e!K.$^K*).=Fu0:%"P*U+"h"Gg#-IubZ[2_0*Wq#q"7loT"*t*f)Zp,#!K.$^P61iMmU61uXoXF`FodF'"0MZgMe3!HM$:To!OI+R*<S8'63A//!O`pL"%s"(!KIg)7KX###1Eq^'*A9/I00W`"'-?CL)Wc),;:&>;Zm"$)ZspZ*>B(ez9E5%m9E5%m7K<Dg8,rVi7K<Dg7K<Dg9E5%m9E5%m9E5%m<WE+"<WE+"<WE+";?-[s;?-[s:&k7o,6.]D,6.]D-3+#G8cShk9)nql.f]PL-3+#G=TAF%1B7CT,6.]D=9&=$=o\O&=9&=$=9&=$9E5%m9E5%m;?-[s;?-[s;?-[sz"KT3P!s,;%dfT[k!s+Ve1]md%p&W?[joL;A7KLs=!Q+qp3!03Y!sY(o.glFuV?8V]%BED2V?7"j"*XhJ"+(+hK*)34L&mM>mK'WpZN6g%K*%VF!OH>F!ODjQNWHHoIRSSb"bm&1#,;3U3!02n)Zs(B!s?"7'*A=U!uh>J"![i""&fB#!uh=lQ3$jb!S[\W!s;s6!L*W6!s-RI!S_cS!Jq!:h>u)KFodF'"l9:'"nhtR"l9:Wds_=SM$2B1qZ4S8*XK@Y#3,m!"*tK9!uh>*PQB58!QtQG#-Kcb"J,Y;drkbKM$0[VdfeM.M$0+FqZ4S8"#pA`)Zp,-)ZrD/)ZpNO!s?RG@p<.VV@&Lf$O=!AGln.A#Q"trh>r[9ZNmf<UB->ZgB[Td#6PJAc;PYa>;/tZ"Oda2"bQiKEsV)!$KDKj%^U:N#b)7o>?_,Y^0;gD!KpXi!s+8]!s7<u%uX(J0LH&Q9*WiQ"7#u?QW!ps$2ZdbRq3*,K*('>"%+1?!oA2)91qn[0M;VYN)Kfl"f>K)'*Ae-QNLT)!uh=DQ3$jbdfT[Q!s+Ve@06Pb!s-RIqZDj8M$:m"!S\q%!Jq!"!QtVKV?)NKScR:B_Z>SrZN9q(lY@ONH4S1+!s+/ZZQ.^=TGb?CdfT[Q!s+Ve1]md%!s.-Yb66C)M$3eYgB?(.M$3eY!Ri(j!Jps)!W)o8r<#"]EuP2_"iCA1%^Q38O!=t+ZNc]rN=;9eP6:CW%h.J),6e&k.g$_E,6It*>lt]A,6Jke!t>=n>8mZB$X3[u;ZdN9)cJgH!qcX1\cWlR!#l"@!!!!<z!!!!&!!!!(!!!"%!!!!2!!!!6!!!""!!!!#!!!#!!!!!R!!!!F!!!""!!!!n!!!!N!!!"#!!!#)!!!#)!!!#'!!!#'!!!#'!!!"3!!!!_!!!"%!!!"K!!!!f!!!"#!!!"Y!!!!l!!!"$!!!"e!!!""!!!""!!!#/!!!#(!!!"+!!!"$!!!##!!!#:!!!"2!!!"'!!!##!!!##!!!##!!!#)!!!#)!!!#)!!!#)X7[S8",?s]!N$e<9+q>aEAeID"HER/!s938!sO^1,7@-`"*"F/)ZpB/;a(:nHm;8d!smK\9*8K>97$^=!J^`WmK&e@"P[Gh"IfLOL.`0j!s<NE9*6S8!sJbH)Zp09!slpLUB:T;!s+VeQ3#/2!NQ;'"3+aO!L<c0"1A5e!L<be!VQPN!p0O,"4dL0"4dLJ!L!P@3!03)!s?:?!s7<u!NHQtis=Bqb5n7E1C&OCD@2"!!LjJO!lG8t!JUr^X$[0)!N$A24%hX;0KT;q"eGf`4p+GV,;TF#"+LE#"#Ejpk$&dM]5)Bg&I.8(!ojOW>>GEg"*jtN!JCPb)ZsFL*pXTB"&frp)Zp,3!M]`!!s8Rg!L<c0!QtSb!JppP!M]eK!Jpj&!QtM->m!%gf)lro!uh=E!uh>/)Zp2'P65S&HRJss!qlYTW>GYg!J:IT")B%^!K7&3!s8RV!hTQ!!s9JE!L*V[!QtQI#,VEe!nICq"5X'8"NCJ;!L!P@3!03)!sFA]mK6*$JcepT!uh=C)Zp-.!s,G)UB:U,!s+VeQ3#/2b6,`bM#t*dWrfF)M#t*dUB9iaM$)T8b5me-"#pA`!uh>L)Zp,;3s)9@6N^XK"7ANL?3,pNT*jT\9*2^+!J^i:((9.dlOJh`%fr.091o@n!iAUSWWN9Y\f1_Q/H[d1!s,\0mK56aY6.],QQ$#./H\WJ!s,;%!N-#=ncKg5hAZOt91o?g0M?:V;Zd&t!KL)O"'[HX"&fAp!uh>2PQ@N]b6%hIecD';ecEqtL&m,6%KW=,!L!P@!kSKV#hs,9"*tCI)Zp+u!M]`!UNQ[&M$2rAUBTc\M$CZpb5me-"#pA`!uh=Y)Zp,0!R_+71E-Mh9eusEGln-nP63<;1BUqa1DVc>3s/eC!qHFd!s9JE!N$k>$VLj0)f[bD;Zj`9Gln-V)ZpNO!s@fjrW=qq,6@B:,C'@nE<DLOP6[j=#3uj0!Nlah,6Jl\)Zp1>^*=R:1D=a/"*"Bs""5r-!sN-i)Zp1o!sFkk;Zg&>"L_6%+9O;r!s+Ed)b'p.E<G?%!S.?_!mLgGWrj:C"(;941]mcJ!M]`!UNQ[&!JrE0joLrpFodF'"m,id!lb7t#+bjj!L!P@!n.1ngBP82H4Po7!s5J)!*fLCz!!E9%!!E9%!!E9%!!E9%!!iQ)!!iQ)!!iQ)!&OZU!&OZU!&OZU!%n6O!%n6O!%n6O!%n6O!&OZU!&OZU!&OZU!&OZU!!3-#!%S$L!$)%>!"o83!'L;^!%@mJ!"/c,!+Z'0!+l32!+l32!+l32!+l32!,MW8!,MW8!1Elfz!+u93!&srY!#GV8!#>P7!%n6O!&OZU!13`d!3-#!z!E9%!!E]=%!E]=%!&OZU!/COS!([(i!!E9%!&OZU!&OZU!1*Zc!)ijt!"/c,!$hOE!$hOE!%%[G!%%[G!%IsK!%IsK!%IsK!%IsK!%\*M!%\*M!%\*M!#>P7!#>P7!#>P7!#>P7!&OZU!&OZU!#>P7!6kKD!-8,?!#bh;!9jI`!-eJD!"/c,!&OZU!#>P7!#>P7!#,D5!#bh;!$VCC!$VCC!$hOE!$hOE!<iH'!/COS!!*'"!#>P7!>>G5!07*[!!E9%!#,D5!#>P7!#>P7!#>P7!#>P7!!iQ)!($Yc!($Yc!(6ee!($Yc!+Z'0!+Z'0!+Z'0!BU8]!2TYq!!*'")?9a;!!!!'`, `type`, `countlz`, `move`, `readstring`, `rrotate`

### [809] ReplicatedStorage.Controllers.SwordsController .SwordsController
`Script` · bytecode v9 · 787 bytes · 19 constants
- **Key API:** GetAttribute, SetAttribute
- Constants: `debug`, `setmemorycategory`, `Name`, `Start`, `script`, `Parent`, `require`, `Loaded`, `SetAttribute`, `Init`, `GetAttribute`, `GetAttributeChangedSignal`, `Wait`, `pcall`, `task`, `spawn`, `error`, `%*:Init() - %*`, `format`

### [810] ReplicatedStorage.Controllers.TagModeController
`ModuleScript` · bytecode v9 · 5324 bytes · 89 constants
- **Services:** Players, ReplicatedStorage, RunService, game, workspace
- **Key API:** Clone, Connect, Destroy, FindFirstChild, GetAttribute, GetChildren, GetService, IsA, OnClientEvent, WaitForChild, new
- Constants: `GetChildren`, `TeamId`, `GetAttribute`, `GetTeamByTeamId`, `GetTeamAmount`, `Enabled`, `YourTeam`, `Visible`, `TeamsLeft`, `TEAMS LEFT: `, `tostring`, `Text`, `updateTeamsLeft`, `matchTrove`, `Add`, `workspace`, `Alive`, `TeamColor`, `print`, `Grid`, `Frame`, `IsA`, `Name`, `Destroy`, `CreatePlayerFrame`, `ChildRemoved`, `Connect`, `UpdateRoundKillCount`, `Content`, `PlayerIcon`, `Color`, `ImageColor3`, `LayoutOrder`, `updateTeam`, `Leader`, `Crown`, `updateLeader`, `Score`, `TotalKills`, `updateKills`, `GetPlayerFromCharacter`, `FindFirstChild`, `UIGridLayout`, `Player_Tag`, `Clone`, `Thumbnail`, `rbxthumb://type=AvatarHeadShot&id=%*&w=150&h=150`, `UserId`, `format`, `Image`, `Dead`, `Parent`, `GetAttributeChangedSignal`, `CurrentlySelectedMode`, `GameActive`, `Tag`, `Clean`, `ChildAdded`, `checkGameActive`, `OnClientEvent`, `Start`, `require`, `game`, `Players`, `GetService`, `LocalPlayer`, `PlayerScripts`, `WaitForChild`, `ClientLoader`, `ControllerIsolator`, `CreateRequire`, `script`, `ReplicatedStorage`, `RunService`, `Teams`, `PlayerGui`, `RoundKillCount`, `TagModeCurrentLeader`, `Shared`, `FastUtils`, `Packages`, `Net`, `Replion`, `Trove`, `Client`, `TagMode/OnPlayerLeft`, `RemoteEvent`, `TagMode/MatchEnded`, `new`

### [811] ReplicatedStorage.Controllers.TeamsOverheadController
`ModuleScript` · bytecode v9 · 728 bytes · 20 constants
- **Services:** Players, ReplicatedStorage, game
- **Key API:** GetService, WaitForChild, new
- Constants: `Start`, `require`, `game`, `Players`, `GetService`, `LocalPlayer`, `PlayerScripts`, `WaitForChild`, `ClientLoader`, `ControllerIsolator`, `CreateRequire`, `script`, `ReplicatedStorage`, `PlayerGui`, `Packages`, `Net`, `Common`, `Utils`, `Maid`, `new`

### [812] ReplicatedStorage.Controllers.TokenDropController
`ModuleScript` · bytecode v9 · 7580 bytes · 134 constants
- **Remotes:** RoundEnded
- **Services:** Debris, Players, ReplicatedStorage, TweenService, game, workspace
- **Key API:** Clone, Connect, Create, Destroy, FindFirstChild, FireServer, GetAttribute, GetService, InvokeServer, OnClientEvent, Once, Play, SetAttribute, WaitForChild, new
- Constants: `Assets`, `TokenDropVFX`, `Clone`, `CFrame`, `workspace`, `Runtime`, `Parent`, `DestroyToken`, `Visual`, `PlayEffects`, `AddItem`, `Model`, `Trove`, `Claimed`, `GetAttribute`, `SetAttribute`, `ID`, `FireServer`, `Sounds`, `CollectToken`, `Play`, `Character`, `GetPivot`, `TweenInfo`, `new`, `Enum`, `EasingStyle`, `Quad`, `Position`, `Create`, `Add`, `Completed`, `Once`, `Center`, `FindFirstChild`, `Glow`, `Enabled`, `ClaimToken`, `IsDescendantOf`, `InvokeServer`, `CustomTokenModel`, `Reward`, `Type`, `LimitedEgg`, `LimitedEggUGC`, `WaitForChild`, `Size`, `TokenDrop`, `Token-%*`, `format`, `Name`, `Token`, `Icon`, `Image`, `UpdatePosition`, `AttachToInstance`, `Touched`, `Connect`, `CreateToken`, `Destroy`, `NextNumber`, `Sine`, `EasingDirection`, `In`, `TweenOut`, `LegoBrick`, `Y`, `SpawnPivot`, `Raycast`, `Instance`, `Distance`, `PivotTo`, `UDim2`, `fromScale`, `Random`, `Vector3`, `TweenPop`, `Remove`, `Cubic`, `task`, `delay`, `GetServerTimeNow`, `pairs`, `Expiration`, `FadingOut`, `ImageTransparency`, `winners`, `table`, `find`, `wait`, `OnClientEvent`, `Thread`, `Every`, `isDungeonsMatchServer`, `Dungeons_CurrentZone`, `GetAttributeChangedSignal`, `Remotes`, `RoundEnded`, `Start`, `require`, `game`, `Players`, `GetService`, `LocalPlayer`, `PlayerScripts`, `ClientLoader`, `ControllerIsolator`, `CreateRequire`, `script`, `ReplicatedStorage`, `TweenService`, `Debris`, `ServerInfo`, `Packages`, `Net`, `Common`, `RewardInfo`, `Utils`, `Shared`, `FastUtils`, `SpawnToken`, `RemoteEvent`, `UpdateTokenPosition`, `CanClaimToken`, `RemoteFunction`, `RaycastParams`, `CollisionGroup`, `RaycastFilterType`, `Exclude`, `FilterType`, `Alive`, `Dead`, `FilterDescendantsInstances`

### [813] ReplicatedStorage.Controllers.TournamentCrateController
`ModuleScript` · bytecode v9 · 13581 bytes · 220 constants
- **Remotes:** Data, UpdateSpins
- **Services:** Players, ReplicatedStorage, RunService, StarterGui, TweenService, UserInputService, game, workspace
- **Key API:** Clone, Connect, Create, Destroy, FindFirstChild, Fire, FireServer, GetAttribute, GetChildren, GetDescendants, GetService, IsA, OnClientEvent, Play, SetAttribute, WaitForChild, new
- Constants: `Visible`, `Sword/Explosion`, `Text`, `DefaultSecret`, `RewardPool`, `Reward`, `Vector`, `Icon`, `Image`, `Title`, `DisplayName`, `Label`, `%*%%`, `Probability`, `format`, `Selected`, `FindFirstChild`, `LoadItems`, `ToggleChances`, `Destroy`, `TweenInfo`, `new`, `Enum`, `EasingStyle`, `Sine`, `EasingDirection`, `Out`, `Create`, `Play`, `Completed`, `Connect`, `ApplyTween`, `Circular`, `Replacement`, `ImageTransparency`, `bink`, `Clone`, `Parent`, `Volume`, `task`, `delay`, `TimeLength`, `wait`, `math`, `min`, `tick`, `Sounds`, `SecretOpened`, `Random`, `NextNumber`, `UDim2`, `Position`, `FireServer`, `reward`, `GetDescendants`, `TextLabel`, `IsA`, `TextBox`, `TextButton`, `TextTransparency`, `ImageLabel`, `ImageButton`, `UIStroke`, `Transparency`, `Size`, `fromScale`, `TournamentTickets`, `Get`, `Spin`, `DailyLoginStreaks`, `Streak`, `Tickets`, `GetTickets`, `TournamentClaimedStreaks`, `Day%*`, `Name`, `Color3`, `fromRGB`, `ImageColor3`, `CLAIMED!`, `TournamentLoginStreak`, `tonumber`, `s`, `%* Ticket%*`, `CanClaim`, `SetAttribute`, `update`, `GetAttribute`, `LTMSpin_ClaimSpins`, `%* Days`, `updateStreaks`, `1`, `2`, `3`, `5`, `4`, `7`, `Activated`, `OnChange`, `spawn`, `SetupStreaks`, `InfoType`, `Product`, `PromptPurchase`, `GetChildren`, `BuyButton`, `Price`, `DevProduct`, `%s`, `SetupTicketShop`, `BalanceText`, `BalanceTextChanged`, `Fire`, `UpdateSpins`, `Init`, `KeyCode`, `J`, `UserId`, `TournamentsCrate`, `Open`, `Close`, `CoreGuiType`, `PlayerList`, `GetPolicyInfo`, `ArePaidRandomItemsRestricted`, `ReflectPolicy`, `DateTime`, `fromUnixTimestamp`, `workspace`, `GetServerTimeNow`, `ValueConvertor`, `UnixTimestamp`, `FormatTimeWithDaysFull`, `Client`, `Data`, `WaitReplion`, `ProcessTournamentRoll`, `RemoteEvent`, `ClaimTournamentReward`, `ClaimTournamentStreak`, `PlayerGui`, `WaitForChild`, `Crates`, `Main`, `Left`, `Right`, `Odds`, `Items`, `LeftList`, `RightList`, `SpinButtons`, `Spin1`, `Spin10`, `Secret`, `Glow`, `Item`, `QuestionMark`, `Desc2`, `Currency`, `Add`, `DayCount`, `List`, `TicketsShop`, `Frame`, `Timer`, `Amount`, `CloseButton`, `Crate1`, `Crate2`, `Crate3`, `Crate4`, `Crate5`, `Crate6`, `Crate7`, `Crate8`, `IsStudio`, `InputBegan`, `OnGuiOpen`, `OnGuiClose`, `OnClientEvent`, `PolicyInfoAdded`, `Thread`, `Every`, `Start`, `require`, `game`, `Players`, `GetService`, `LocalPlayer`, `PlayerScripts`, `ClientLoader`, `ControllerIsolator`, `CreateRequire`, `script`, `RunService`, `TweenService`, `ReplicatedStorage`, `UserInputService`, `StarterGui`, `ClientGameModules`, `Common`, `Packages`, `Replion`, `Net`, `Utils`, `GuiHandler`, `Shared`, `Policy`, `TournamentCrateData`, `MarketplaceService`, `Signal`, `CreatePriceLabel`, `CoreCall`, `Controllers`, `Trading`, `TradeTokensController`, `Assets`, `UI`, `HalloweenGacha`

### [814] ReplicatedStorage.Controllers.Tournaments.Event.TournamentCrateController
`ModuleScript` · bytecode v9 · 8818 bytes · 169 constants
- **Remotes:** Data
- **Services:** Players, ReplicatedStorage, SoundService, TweenService, game, workspace
- **Key API:** Clone, Connect, Create, Destroy, FindFirstChild, FireServer, GetChildren, GetService, OnClientEvent, Once, Play, WaitForChild, new
- Constants: `Destroy`, `Instance`, `new`, `Sound`, `SoundId`, `Parent`, `Volume`, `PlaybackSpeed`, `TimePosition`, `Play`, `Ended`, `Once`, `fastAudio`, `Loaded`, `Get`, `Claimed`, `LOADING...`, `Text`, `Stock`, `Reward`, `Value`, `math`, `ceil`, `clamp`, `Client`, `Data`, `WaitReplion`, `Replacement`, `ReceivedTournamentEventFFAOrbitSpear`, `Remove`, `AddFromRewardInfo`, `Inspect`, `CanPreview`, `Visible`, `NameLabel`, `DisplayName`, `Icon`, `Icons`, `DEFAULT_MISSING`, `GetIcon`, `Image`, `Percent`, `Position`, `%*/%* LEFT`, `ValueConvertor`, `AddCommas`, `ShrinkNumber`, `format`, `updateBigReward`, `PreviewReward`, `GetChildren`, `FireServer`, `Enum`, `InfoType`, `Product`, `PromptPurchase`, `GetPolicyInfo`, `ArePaidRandomItemsRestricted`, `Buttons`, `Robux`, `SpinQueue`, `Index`, `FastSpin`, `table`, `insert`, `Items`, `Chance`, `FFlag`, `GetInstantFFlag`, `TournamentEventGrandPrizeChance`, `getWeights`, `relativeWeights`, `options`, `round`, `find`, `FindFirstChild`, `%*%%`, `updateChances`, `workspace`, `GetServerTimeNow`, `TournamentEventLuckStartTime`, `TournamentEventLuckEndTime`, `HasLuck`, `MainFrame`, `Frame`, `LeftButtons`, `EventCrate`, `Clover`, `Spinning`, `remove`, `DoSpinAnimation`, `LimitedStockItems`, `InitialStock`, `Activated`, `Connect`, `ViewOdds`, `Spin`, `DevProduct`, `%s`, `task`, `spawn`, `OnClientEvent`, `OnChange`, `Thread`, `Every`, `Start`, `Glow`, `Misc`, `reward`, `Clone`, `script`, `clone`, `Name`, `ClearAllChildren`, `Size`, `ImageTransparency`, `UDim2`, `fromScale`, `Create`, `Completed`, `endAnimation`, `NextInteger`, `DoItemGlow`, `wait`, `rbxassetid://6895079853`, `require`, `game`, `Players`, `GetService`, `LocalPlayer`, `PlayerScripts`, `WaitForChild`, `ClientLoader`, `ControllerIsolator`, `CreateRequire`, `ReplicatedStorage`, `SoundService`, `TweenService`, `Packages`, `Net`, `Replion`, `Common`, `Utils`, `Controllers`, `Trading`, `TradeTokensController`, `NotificationController`, `ClientGameModules`, `GuiHandler`, `Shared`, `TournamentEvent`, `TournamentEventCrate`, `StPatricksDayEventController`, `WeightRandom`, `CreatePriceLabel`, `Policy`, `HoverInfoController`, `IndexController`, `RewardInfo`, `PlayerGui`, `Views`, `Container`, `7`, `ProcessTournamentEventRoll`, `RemoteEvent`, `TweenInfo`, `EasingStyle`, `Linear`, `Random`

### [815] ReplicatedStorage.Controllers.Tournaments.Event.TournamentEventBracketsController
`ModuleScript` · bytecode v9 · 3175 bytes · 72 constants
- **Services:** Players, ReplicatedStorage, game
- **Key API:** Connect, Destroy, FindFirstChild, GetService, WaitForChild, new
- Constants: `Name`, `Close`, `Label`, `Failed to load`, `Text`, `tonumber`, `Headshot`, `Visible`, `rbxthumb://type=AvatarHeadShot&id=%*&w=420&h=420`, `format`, `Image`, `Loading`, `GetPlayerByUserId`, `GetUsername`, `AddPromise`, `andThen`, `catch`, `N/A`, `updateBracketBox`, `%*_%*`, `FindFirstChild`, `warn`, `Player frame for "%*"" not found
%*`, `tostring`, `updateGroup`, `Destroy`, `Groups`, `GetExpect`, `GroupsPerTournament`, `Brackets`, `Left`, `GroupWinners`, `Get`, `Winners`, `updateBrackets`, `isTournamentEventServer`, `isMedalTournamentMatch`, `ShowBrackets`, `Activated`, `Connect`, `new`, `Client`, `TournamentEvent`, `WaitReplion`, `OnChange`, `task`, `spawn`, `Start`, `require`, `game`, `Players`, `GetService`, `LocalPlayer`, `PlayerScripts`, `WaitForChild`, `ClientLoader`, `ControllerIsolator`, `CreateRequire`, `script`, `ReplicatedStorage`, `Packages`, `Trove`, `ServerInfo`, `Replion`, `Shared`, `PlayerUtility`, `ClientGameModules`, `GuiHandler`, `TournamentEventData`, `PlayerGui`, `TournamentEventBrackets`

### [816] ReplicatedStorage.Controllers.Tournaments.Event.TournamentEventController
`ModuleScript` · bytecode v9 · 16571 bytes · 246 constants
- **Remotes:** Data, Set, SetGift, Update
- **Services:** Players, ReplicatedStorage, UserInputService, game, workspace
- **Key API:** Clone, Connect, Destroy, Disconnect, FindFirstChild, FireServer, GetAttribute, GetChildren, GetService, InvokeServer, IsA, Play, SetAttribute, WaitForChild, new
- Constants: `Set`, `State`, `MouseEnter`, `Connect`, `MouseLeave`, `GuiButton`, `IsA`, `Activated`, `getHoveredState`, `Client`, `PartyReplionChannel`, `GetReplion`, `players`, `Get`, `TournamentEventStrikes`, `Strikes`, `MaxStrikes`, `PlayersPerParty`, `Max`, `MyTeam`, `PlayersList`, `Player%*`, `format`, `Leave`, `Visible`, `AddPlayer`, `PlayButton`, `ResetStrikes`, `Headshot`, `rbxthumb://type=AvatarHeadShot&id=%*&w=100&h=100`, `UserId`, `Image`, `PlayerName`, `DisplayName`, `Text`, `Update`, `QueuePartition`, `GetAttribute`, `NumPlayers`, `LastUpdate`, `workspace`, `GetServerTimeNow`, `FFlag`, `GetFFlag`, `TournamentEventQueueCountEnabled`, `Frame`, `Timer`, `UDim2`, `fromScale`, `Position`, `Size`, `PlayersInQueue`, `%*+ players in queue`, `UpdatePlayersInQueue`, `CurrentPage`, `OpenView`, `Tags`, `table`, `find`, `TournamentEventParty`, `Destroy`, `OnReplionAdded`, `OnReplionRemoved`, `ObserveReplion`, `TournamentEvent%*Currency`, `TournamentId`, `MainFrame`, `LeftButtons`, `Currency`, `Coins`, `Amount`, `updateTickets`, `TournamentEvent`, `Close`, `Character`, `Name`, `CrateSpin`, `TournamentEventCrate`, `Open`, `TextLabel`, `Font`, `new`, `rbxasset://fonts/families/SourceSansPro.json`, `Enum`, `FontWeight`, `Bold`, `FontStyle`, `Normal`, `FontFace`, `UIStroke`, `Color3`, `fromRGB`, `Color`, `AutoFill`, `InvokeServer`, `Sounds`, `error`, `Play`, `Failed to join queue!`, `SendNotification`, `FireServer`, `ResetTournamentEventStrikes`, `SetGift`, `Disconnect`, `OnDataChange`, `Invite`, `EndTime`, `SetAttribute`, `UnixTimestamp`, `ValueConvertor`, `FormatTimeWithDaysFull`, `Connected`, `Thread`, `Every`, `onQueueTypeChanged`, `Enabled`, `ShowQueue`, `Cancel`, `Active`, `InTournamentEventQueue`, `Hide`, `Show`, `fromOffset`, `TopbarInset`, `Height`, `TouchEnabled`, `TweenInfo`, `EasingStyle`, `Sine`, `AnchorPoint`, `Vector2`, `TournamentReplion`, `DailyStrikes`, `tostring`, `rbxassetid://101827596158319`, `rbxassetid://85902594598634`, `HoverImage`, `rbxassetid://101102630128430`, `rbxassetid://96437766135441`, `CloseText`, `TournamentEventStrikesReset`, `math`, `max`, `ceil`, `DailyStrikesTimer`, `Daily Strikes (Resets in %*)`, `FormatTimeHHMMSS`, `TeamsLeft`, `TEAMS LEFT: %*`, `Content`, `Score`, `Dead`, `Alive`, `observeProperty`, `Parent`, `observeCharacter`, `observeAttribute`, `Kills`, `Data`, `WaitReplion`, `OnChange`, `ChildAdded`, `Views`, `GetChildren`, `GuiObject`, `setPropertyComputed`, `FindFirstChild`, `Time`, `TournamentEventTimer`, `AddTag`, `Computed`, `GiftStrikes`, `observeTagNoAncestry`, `TournamentEventEndTime`, `MatchmakingPlayerCounts`, `GetAttributeChangedSignal`, `observeReplionPath`, `ServerInfo`, `isTournamentEventServer`, `RoundKillCount`, `WaitForChild`, `UIPadding`, `UDim`, `PaddingTop`, `YourTeam`, `TournamentEventTeamsAlive`, `Teams`, `Grid`, `UIGridLayout`, `Player`, `Clone`, `LayoutOrder`, `PlayerIcon`, `Thumbnail`, `rbxthumb://type=AvatarHeadShot&id=%*&w=150&h=150`, `0`, `observePlayer`, `Start`, `string`, `%.2i:%.2i`, `floor`, `require`, `game`, `Players`, `GetService`, `LocalPlayer`, `PlayerScripts`, `ClientLoader`, `ControllerIsolator`, `CreateRequire`, `script`, `ReplicatedStorage`, `UserInputService`, `GuiService`, `Packages`, `Net`, `Replion`, `Shared`, `ReplionUtils`, `Statable`, `ClientGameModules`, `GuiHandler`, `Observers`, `Common`, `Utils`, `FastUtils`, `fastTween`, `TournamentEventData`, `Controllers`, `NotificationController`, `GiftingController`, `PlayerGui`, `JoinTournamentEventQueue`, `RemoteFunction`, `LeaveTournamentEventQueue`, `TournamentEventWaiting`, `RequestTournamentEventStrikeReset`, `RemoteEvent`, `JoinTournamentEventParty`, `LeaveTournamentEventParty`, `SendTournamentEventInvite`, `TournamentReturnToLobby`, `TournamentGetRewards`, `TournamentEventReturnToLobby`, `TournamentEventGetRewards`, `Remotes`

### [817] ReplicatedStorage.Controllers.Tournaments.Event.TournamentEventController.TournamentEventController
`Script` · bytecode v9 · 787 bytes · 19 constants
- **Key API:** GetAttribute, SetAttribute
- Constants: `debug`, `setmemorycategory`, `Name`, `Start`, `script`, `Parent`, `require`, `Loaded`, `SetAttribute`, `Init`, `GetAttribute`, `GetAttributeChangedSignal`, `Wait`, `pcall`, `task`, `spawn`, `error`, `%*:Init() - %*`, `format`

### [818] ReplicatedStorage.Controllers.Tournaments.Event.TournamentEventCrateController
`ModuleScript` · bytecode v9 · 11129 bytes · 195 constants
- **Services:** Players, ReplicatedStorage, RunService, StarterGui, TweenService, UserInputService, game
- **Key API:** Clone, Connect, Destroy, FindFirstChild, Fire, FireServer, GetAttribute, GetDescendants, GetService, IsA, Play, SetAttribute, WaitForChild, new
- Constants: `Crates`, `Left`, `Items`, `Secret`, `Glow`, `Visible`, `Selected`, `FindFirstChild`, `QuestionMark`, `Desc2`, `Sword/Explosion`, `Text`, `defaultSecret`, `Label`, `ToggleChances`, `Destroy`, `Reward`, `Value`, `Icons`, `Get%*Icon`, `Type`, `format`, `typeof`, `function`, `%*Skin`, `Network`, `Events`, `ShowAwardItem`, `type`, `number`, `You received %*!`, `ValueConvertor`, `%*`, `%%s %*`, `DisplayName`, `Color3`, `new`, `FormatMarkupColor`, `task`, `wait`, `TweenInfo`, `Enum`, `EasingStyle`, `Circular`, `EasingDirection`, `Out`, `Fire`, `fastTween`, `SpinButtons`, `Spin1`, `ImageColor3`, `UI_ButtonHoverAnimation2`, `RemoveTag`, `Spin10`, `Index`, `Replacement`, `IsSecret`, `ImageTransparency`, `bink`, `Clone`, `Volume`, `Parent`, `Play`, `delay`, `TimeLength`, `math`, `min`, `Sounds`, `SecretOpened`, `os`, `clock`, `Random`, `NextNumber`, `UDim2`, `fromScale`, `fromOffset`, `Position`, `Item`, `Icon`, `DEFAULT_MISSING`, `GetIcon`, `Image`, `Sine`, `GetDescendants`, `TextLabel`, `IsA`, `TextBox`, `TextButton`, `TextTransparency`, `ImageLabel`, `ImageButton`, `UIStroke`, `Transparency`, `Size`, `Completed`, `Connect`, `Time`, `reward`, `spawn`, `AddTag`, `Spin`, `LoginStreaks`, `Streak`, `Tickets`, `getTicketsForStreak`, `TournamentEventClaimedStreaks`, `Day%*`, `Name`, `Get`, `fromRGB`, `CLAIMED!`, `TournamentEventLoginStreak`, `tonumber`, `s`, `%* Ticket%*`, `+%* (Click to claim)`, `CanClaim`, `SetAttribute`, `update`, `GetAttribute`, `LTMSpin_ClaimSpins`, `FireServer`, `Right`, `Main`, `DayCount`, `%* Days`, `updateStreaks`, `1`, `List`, `2`, `3`, `4`, `Activated`, `OnChange`, `SetupStreaks`, `Close`, `TournamentEvent`, `Open`, `TicketsShop`, `CoreGuiType`, `PlayerList`, `GetExpect`, `InfoType`, `Product`, `PromptPurchase`, `updateTickets`, `GetPolicyInfo`, `ArePaidRandomItemsRestricted`, `updatePolicy`, `Start`, `require`, `game`, `Players`, `GetService`, `LocalPlayer`, `PlayerScripts`, `WaitForChild`, `ClientLoader`, `ControllerIsolator`, `CreateRequire`, `script`, `RunService`, `TweenService`, `ReplicatedStorage`, `UserInputService`, `StarterGui`, `ClientGameModules`, `Common`, `Packages`, `Replion`, `Net`, `Utils`, `GuiHandler`, `Shared`, `Policy`, `FastUtils`, `TournamentEventCrate`, `TournamentEventData`, `MarketplaceService`, `Signal`, `CreatePriceLabel`, `CoreCall`, `Controllers`, `Trading`, `TradeTokensController`, `TournamentEvent%*Currency`, `TournamentId`, `ProcessTournamentEventRoll`, `RemoteEvent`, `ClaimTournamentEventStreak`, `PlayerGui`, `Assets`, `UI`, `HalloweenGacha`

### [819] ReplicatedStorage.Controllers.Tournaments.Event.TournamentEventInviteController
`ModuleScript` · bytecode v9 · 3758 bytes · 87 constants
- **Remotes:** Set
- **Services:** Players, ReplicatedStorage, game
- **Key API:** Clone, Connect, Destroy, Disconnect, FireServer, GetAttribute, GetService, InvokeServer, OnClientEvent, Play, WaitForChild
- Constants: `TournamentEventInvite`, `Open`, `Prompt`, `CurrentPage`, `Play`, `Set`, `UDim2`, `fromOffset`, `UIListLayout`, `AbsoluteContentSize`, `Y`, `CanvasSize`, `InTournamentEventParty`, `GetAttribute`, `Visible`, `InvokeServer`, `SendNotification`, `Misc`, `error`, `Destroy`, `Disconnect`, `Player`, `Clone`, `Username`, `%* (@%*)`, `DisplayName`, `Name`, `format`, `Text`, `PlayerPortrait`, `rbxthumb://type=AvatarHeadShot&id=%*&w=100&h=100`, `UserId`, `Image`, `Parent`, `GetAttributeChangedSignal`, `Connect`, `Invite`, `Activated`, `FireServer`, `Enabled`, `Sounds`, `Failed to accept invite!`, `Main`, `@%* Invited You to a Tournament Event!`, `TournamentEvent`, `WaitForChild`, `MainFrame`, `Frame`, `Views`, `Players`, `Close`, `GetPropertyChangedSignal`, `observePlayer`, `TournamentEventPartyInvite`, `DeclineButton`, `ReadyButton`, `OnClientEvent`, `Start`, `require`, `game`, `GetService`, `LocalPlayer`, `PlayerScripts`, `ClientLoader`, `ControllerIsolator`, `CreateRequire`, `script`, `ReplicatedStorage`, `Packages`, `Net`, `Shared`, `Statable`, `ClientGameModules`, `GuiHandler`, `Observers`, `Common`, `Utils`, `Controllers`, `NotificationController`, `./TournamentEventController`, `PlayerGui`, `JoinTournamentEventParty`, `RemoteFunction`, `LeaveTournamentEventParty`, `SendTournamentEventInvite`, `TournamentEventInviteNotification`, `RemoteEvent`

### [820] ReplicatedStorage.Controllers.Tournaments.Event.TournamentEventLeaderboardController
`ModuleScript` · bytecode v9 · 4522 bytes · 110 constants
- **Remotes:** Data, Set
- **Services:** Players, ReplicatedStorage, RunService, TweenService, game, workspace
- **Key API:** Clone, FindFirstChild, GetService, Invoke, WaitForChild
- Constants: `CurrentPage`, `Leaderboard`, `workspace`, `GetServerTimeNow`, `GetTournamentEventTopPlayers`, `Invoke`, `buffer`, `readu8`, `table`, `create`, `readf64`, `readu32`, `readstring`, `userId`, `score`, `country`, `insert`, `Set`, `PlayerName`, `@%*%*`, `Emoji`, `format`, `Text`, `ProfilePicture`, `Visible`, `PlaceHolder`, `Image`, `relieve`, `tostring`, `FindFirstChild`, `UIListLayout`, `Template%*`, `math`, `clamp`, `Clone`, `RankLabel`, `#%*`, `Name`, `Parent`, `Top`, `Icon`, `Reward`, `Icons`, `DEFAULT_MISSING`, `GetIcon`, `LayoutOrder`, `AddFromRewardInfo`, `Rewards`, `Kills`, `Amount`, `???`, `GetUsername`, `andThen`, `GetPlayerHeadshot`, `UDim2`, `fromOffset`, `AbsoluteContentSize`, `Y`, `CanvasSize`, `renderLeaderboard`, `task`, `spawn`, `State`, `Computed`, `Client`, `Data`, `WaitReplion`, `Start`, `require`, `game`, `Players`, `GetService`, `LocalPlayer`, `PlayerScripts`, `WaitForChild`, `ClientLoader`, `ControllerIsolator`, `CreateRequire`, `script`, `RunService`, `TweenService`, `ReplicatedStorage`, `ClientGameModules`, `Common`, `Packages`, `Replion`, `Net`, `Reliever`, `Utils`, `GuiHandler`, `Shared`, `Statable`, `PlayerUtility`, `PlayerData`, `CountryIcons`, `TournamentEvent`, `TournamentEventTopRewards`, `Controllers`, `Tournaments`, `Event`, `TournamentEventController`, `HoverInfoController`, `PlayerGui`, `MainFrame`, `Frame`, `Views`, `List`, `ScrollingFrame`

### [821] ReplicatedStorage.Controllers.Tournaments.Event.TournamentEventShopController
`ModuleScript` · bytecode v9 · 4001 bytes · 102 constants
- **Remotes:** Data
- **Services:** Players, ReplicatedStorage, RunService, TweenService, game
- **Key API:** Clone, Connect, Destroy, FindFirstChild, GetChildren, GetService, InvokeServer, IsA, Play, WaitForChild
- Constants: `FindFirstChild`, `RewardInfo`, `playerOwnsItem`, `Reward`, `Owned`, `Visible`, `Active`, `_update`, `InvokeServer`, `Sounds`, `Purchase`, `Play`, `error`, `SendNotification`, `PreviewReward`, `Stock`, `LimitedStockId`, `Get`, `InitialStock`, `%*/%* LEFT`, `ValueConvertor`, `AddCommas`, `ShrinkNumber`, `format`, `Text`, `updateStock`, `update`, `Client`, `Data`, `WaitReplion`, `LimitedStockItems`, `GetChildren`, `GuiObject`, `IsA`, `Destroy`, `Clone`, `Name`, `LayoutOrder`, `ItemName`, `DisplayName`, `Vector`, `Icon`, `Image`, `Price`, `Activated`, `Connect`, `AddFromRewardInfo`, `Inspect`, `CanPreview`, `StockLeft`, `Missing stock label for `, `assert`, `OnChange`, `Parent`, `SwordSkins.Unlocked`, `Emotes.Unlocked`, `ExplosionSkins.Unlocked`, `Start`, `require`, `game`, `Players`, `GetService`, `LocalPlayer`, `PlayerScripts`, `WaitForChild`, `ClientLoader`, `ControllerIsolator`, `CreateRequire`, `script`, `RunService`, `TweenService`, `ReplicatedStorage`, `ClientGameModules`, `Common`, `Packages`, `Replion`, `Net`, `Utils`, `GuiHandler`, `Shared`, `TournamentEvent`, `TournamentEventData`, `TournamentEventShop`, `Controllers`, `Tournaments`, `Event`, `TournamentEventController`, `NotificationController`, `HoverInfoController`, `Trading`, `IndexController`, `PurchaseTournamentEventItem`, `RemoteFunction`, `PlayerGui`, `MainFrame`, `Frame`, `Views`, `Shop`, `Container`, `UIGridLayout`, `Template`

### [822] ReplicatedStorage.Controllers.Tournaments.Event.TournamentEventUIEndController
`ModuleScript` · bytecode v9 · 3538 bytes · 80 constants
- **Services:** Players, ReplicatedStorage, RunService, game
- **Key API:** Clone, Connect, FireServer, GetService, InvokeServer, WaitForChild, new
- Constants: `Remotes`, `TournamentGetRewards`, `InvokeServer`, `UIListLayout`, `RewardTemplate`, `Clone`, `Add`, `LayoutOrder`, `Reward`, `Icon`, `Image`, `Text`, `DisplayName`, `Parent`, `TournamentReplion`, `Clean`, `Enabled`, `Winners`, `Get`, `print`, `typeof`, `UserId`, `Find`, `YouWin`, `Visible`, `YouLost`, `RewardFrame`, `task`, `delay`, `Prompt`, `Groups`, `table`, `find`, `observeReplionPath`, `MatchEnded`, `GroupWinners`, `TournamentReturnToLobby`, `FireServer`, `TournamentEvent`, `ObserveReplion`, `LobbyButton`, `Activated`, `Connect`, `LeaveButton`, `Start`, `require`, `game`, `Players`, `GetService`, `LocalPlayer`, `PlayerScripts`, `WaitForChild`, `ClientLoader`, `ControllerIsolator`, `CreateRequire`, `script`, `ReplicatedStorage`, `Packages`, `Net`, `Common`, `Utils`, `Trove`, `Replion`, `Shared`, `TournamentData`, `Controllers`, `UI`, `SpectateController`, `Tournaments`, `Event`, `TournamentEventController`, `TournamentsUIController`, `ReplionUtils`, `PlayerGui`, `EventTournamentEnd`, `RunService`, `IsStudio`, `GameId`, `new`

### [823] ReplicatedStorage.Controllers.Tournaments.TournamentsController
`ModuleScript` · bytecode v9 · 2174 bytes · 41 constants
- **Services:** Players, ReplicatedStorage, game
- **Key API:** Destroy, GetService, WaitForChild
- Constants: `_channel`, `Tournament`, `Destroy`, `Client`, `GetReplion`, `OnReplionAdded`, `OnReplionRemoved`, `ObserveReplion`, `HandleReplion`, `TournamentReplion`, `Start`, `require`, `game`, `Players`, `GetService`, `LocalPlayer`, `PlayerScripts`, `WaitForChild`, `ClientLoader`, `ControllerIsolator`, `CreateRequire`, `script`, `ReplicatedStorage`, `Packages`, `Net`, `Replion`, `Shared`, `TournamentData`, `CreateTournamentRoom`, `JoinTournamentRoom`, `SearchTournamentRooms`, `JoinGlobalTournament`, `TournamentGoToNextServer`, `TournamentReturnToLobby`, `GetEventTournamentLeaderboard`, `TournamentGetRewards`, `LeaveGlobalTournamentQueue`, `TournamentSpectate`, `RemoteFunction`, `RemoteEvent`, `Remotes`

### [824] ReplicatedStorage.Controllers.Tournaments.TournamentsController.TournamentsController
`Script` · bytecode v9 · 787 bytes · 19 constants
- **Key API:** GetAttribute, SetAttribute
- Constants: `debug`, `setmemorycategory`, `Name`, `Start`, `script`, `Parent`, `require`, `Loaded`, `SetAttribute`, `Init`, `GetAttribute`, `GetAttributeChangedSignal`, `Wait`, `pcall`, `task`, `spawn`, `error`, `%*:Init() - %*`, `format`

### [825] ReplicatedStorage.Controllers.Tournaments.UI.TournamentDisconnectController
`ModuleScript` · bytecode v9 · 2580 bytes · 60 constants
- **Remotes:** Data
- **Services:** Players, ReplicatedStorage, game, workspace
- **Key API:** Connect, FireServer, GetAttribute, GetService, WaitForChild
- Constants: `_currentMatch`, `Enabled`, `ShowRejoin`, `Close`, `os`, `clock`, `MatchUUID`, `FireServer`, `InTournamentQueue`, `GetAttribute`, `workspace`, `GetServerTimeNow`, `TournamentMatchHistory`, `Get`, `Canceled`, `InProgress`, `FinalsStartTime`, `StartTime`, `MAX_REJOIN_TIME`, `searchForMatch`, `Client`, `Data`, `WaitReplion`, `isTournamentLobbyServer`, `isTournamentMatchServer`, `Main`, `Abandon`, `Activated`, `Connect`, `CloseButton`, `Rejoin`, `OnChange`, `task`, `spawn`, `Start`, `require`, `game`, `Players`, `GetService`, `LocalPlayer`, `PlayerScripts`, `WaitForChild`, `ClientLoader`, `ControllerIsolator`, `CreateRequire`, `script`, `ReplicatedStorage`, `Packages`, `Replion`, `Net`, `ClientGameModules`, `GuiHandler`, `Shared`, `RankedSeasonData`, `ServerInfo`, `TournamentData`, `RejoinTournamentMatch`, `RemoteEvent`, `PlayerGui`, `TournamentMatchDisconnected`

### [826] ReplicatedStorage.Controllers.Tournaments.UI.TournamentsUIBracketsController
`ModuleScript` · bytecode v9 · 6980 bytes · 112 constants
- **Services:** HttpService, Players, ReplicatedStorage, TweenService, UserInputService, game
- **Key API:** Connect, Create, Destroy, Disconnect, GetService, Once, Play, WaitForChild, new
- Constants: `Destroy`, `Create`, `Completed`, `Once`, `Play`, `fastTween`, `Name`, `Close`, `Label`, `Failed to load`, `Text`, `tonumber`, `NA`, `Visible`, `Headshot`, `rbxthumb://type=AvatarHeadShot&id=%*&w=420&h=420`, `format`, `Image`, `Loading`, `GetPlayerByUserId`, `GetUsername`, `AddPromise`, `andThen`, `catch`, `setBracketBox`, `Left`, `BoxTop`, `BoxBtm`, `Right`, `brackets4`, `List`, `Box1`, `Box2`, `Box3`, `Box4`, `1`, `Box`, `2`, `brackets8`, `BottomList`, `TopList`, `3`, `brackets12`, `4`, `brackets16`, `PlayersBracket`, `Get`, `BracketWinners`, `print`, `Players Bracket:`, `JSONEncode`, `Winners Bracket:`, `table`, `insert`, `sort`, `math`, `abs`, `updateBrackets`, `Disconnect`, `OnChange`, `task`, `spawn`, `string`, `upper`, `EVENT`, `TournamentType`, `Title`, `<stroke color="rgb(0,0,0)" joins="round" thickness="2">Tournament Type: <font color="rgb(255, 17, 17)">%*</font></stroke>`, `isTournamentMatchServer`, `Activated`, `Connect`, `Variants`, `8`, `12`, `16`, `new`, `observeClientReplion`, `Tournament`, `Start`, `require`, `game`, `Players`, `GetService`, `LocalPlayer`, `PlayerScripts`, `WaitForChild`, `ClientLoader`, `ControllerIsolator`, `CreateRequire`, `script`, `ReplicatedStorage`, `UserInputService`, `TweenService`, `HttpService`, `GuiService`, `Packages`, `Net`, `Trove`, `Common`, `Utils`, `ServerInfo`, `Shared`, `ReplionUtils`, `PlayerUtility`, `ClientGameModules`, `GuiHandler`, `Controllers`, `Tournaments`, `TournamentsController`, `PlayerGui`, `TournamentBrackets`

### [827] ReplicatedStorage.Controllers.Tournaments.UI.TournamentsUIController
`ModuleScript` · bytecode v9 · 7263 bytes · 124 constants
- **Services:** Players, ReplicatedStorage, TweenService, UserInputService, game
- **Key API:** Connect, Create, Destroy, Disconnect, GetAttribute, GetChildren, GetPlayers, GetService, InvokeServer, IsA, Once, Play, WaitForChild, new
- Constants: `Destroy`, `Create`, `Completed`, `Once`, `Play`, `fastTween`, `GetChildren`, `GuiObject`, `IsA`, `Name`, `Visible`, `TopButtons`, `GuiButton`, `TextLabel`, `Color3`, `fromRGB`, `TextColor3`, `SwitchView`, `Timer`, `string`, `format`, `%.2i:%.2i`, `math`, `floor`, `Text`, `Enabled`, `Thread`, `Every`, `Frame`, `Cancel`, `Activated`, `PromptQueue`, `Remotes`, `LeaveGlobalTournamentQueue`, `InvokeServer`, `Disconnect`, `PromptGlobal`, `Close`, `InTournamentQueue`, `GetAttribute`, `Hide`, `Show`, `UDim2`, `fromOffset`, `TopbarInset`, `Height`, `TouchEnabled`, `TweenInfo`, `new`, `Enum`, `EasingStyle`, `Sine`, `Position`, `fromScale`, `AnchorPoint`, `Vector2`, `TournamentBrackets`, `Open`, `TournamentEventBrackets`, `roomCode`, `Get`, `RoomCode`, `<stroke color="rgb(0,0,0)" joins="round" thickness="2">Room Code: #<font color="rgb(255, 200, 33 )">%*</font> (%*/%* Players)</stroke>`, `GetPlayers`, `players`, `<stroke color="rgb(0,0,0)" joins="round" thickness="2">%*/%* Players</stroke>`, `update`, `observeReplionPath`, `PlayerAdded`, `Connect`, `PlayerRemoving`, `Custom`, `isTournamentMatchServer`, `GetAttributeChangedSignal`, `HUD`, `WaitForChild`, `LeftFrame`, `GetLeftFrameContent`, `AFK`, `Brackets`, `isTournamentEventServer`, `ShowBrackets`, `isMedalTournamentMatch`, `isTournamentLobbyServer`, `TournamentRoomCode`, `observeClientReplion`, `TournamentLobby`, `Start`, `require`, `game`, `Players`, `GetService`, `LocalPlayer`, `PlayerScripts`, `ClientLoader`, `ControllerIsolator`, `CreateRequire`, `script`, `ReplicatedStorage`, `UserInputService`, `TweenService`, `GuiService`, `Packages`, `Net`, `Common`, `Utils`, `ServerInfo`, `Shared`, `ReplionUtils`, `ClientGameModules`, `GuiHandler`, `Controllers`, `Tournaments`, `TournamentsController`, `UI`, `HUDController`, `TournamentEvent`, `TournamentEventData`, `PlayerGui`, `MainFrame`, `Tabs`, `ScreenGui`, `TabsFolder`, `TournamentWaiting`

### [828] ReplicatedStorage.Controllers.Tournaments.UI.TournamentsUIController.TournamentsUIController
`Script` · bytecode v9 · 787 bytes · 19 constants
- **Key API:** GetAttribute, SetAttribute
- Constants: `debug`, `setmemorycategory`, `Name`, `Start`, `script`, `Parent`, `require`, `Loaded`, `SetAttribute`, `Init`, `GetAttribute`, `GetAttributeChangedSignal`, `Wait`, `pcall`, `task`, `spawn`, `error`, `%*:Init() - %*`, `format`

### [829] ReplicatedStorage.Controllers.Tournaments.UI.TournamentsUICustomController
`ModuleScript` · bytecode v9 · 8757 bytes · 112 constants
- **Services:** Players, ReplicatedStorage, RunService, game
- **Key API:** Connect, Disconnect, GetAttribute, GetService, InvokeServer, SetAttribute, WaitForChild, new
- Constants: `Value`, `GetAttribute`, `ValueConvertor`, `AddCommas`, `Text`, `SetAttribute`, `update`, `math`, `max`, `min`, `Disconnect`, `Controls`, `TextLabel`, `FindFirstChildWhichIsA`, `PriceList`, `<`, `Activated`, `Connect`, `>`, `handleIntOption`, `Label`, `DisplayName`, `MapImage`, `Image`, `Index`, `handleMapOption`, `TextColor3`, `Color3`, `new`, `Name`, `handleOptionsOption`, `Rooms`, `SwitchView`, `Visible`, `TextBox`, `string`, `upper`, `String`, `Trim`, `gsub`, `%p`, `sub`, `Error`, `Remotes`, `JoinTournamentRoom`, `InvokeServer`, `task`, `cancel`, `delay`, `Players`, `Rounds`, `CoinTournaments`, `Prize`, `EntryFee`, `Amount`, `TrueValue`, `CreateButton`, `updatePrize`, `CreateTournamentRoom`, `Privacy`, `Map`, `Title`, `List`, `BrowseRooms`, `CreateRoom`, `JoinRoom`, `Close`, `GetPropertyChangedSignal`, `Enter`, `%*'s Room`, `format`, `Public`, `fromRGB`, `Private`, `GetAttributeChangedSignal`, `DisabledInTraining`, `TrainingMode`, `table`, `insert`, `Start`, `require`, `game`, `GetService`, `LocalPlayer`, `PlayerScripts`, `WaitForChild`, `ClientLoader`, `ControllerIsolator`, `CreateRequire`, `script`, `ReplicatedStorage`, `Packages`, `Net`, `Common`, `Utils`, `Shared`, `MapData`, `ClientGameModules`, `GuiHandler`, `TournamentData`, `Controllers`, `Tournaments`, `TournamentsController`, `UI`, `TournamentsUIController`, `TabsFolder`, `Custom`, `RunService`, `IsStudio`, `GameId`, `print`

### [830] ReplicatedStorage.Controllers.Tournaments.UI.TournamentsUIEndController
`ModuleScript` · bytecode v9 · 4229 bytes · 92 constants
- **Services:** Players, ReplicatedStorage, RunService, game
- **Key API:** Clone, Connect, FireServer, GetAttribute, GetService, InvokeServer, WaitForChild, new
- Constants: `Remotes`, `TournamentGetRewards`, `InvokeServer`, `UIListLayout`, `RewardTemplate`, `Clone`, `Add`, `LayoutOrder`, `Reward`, `Icon`, `Image`, `Text`, `DisplayName`, `Parent`, `TournamentReturnToLobby`, `FireServer`, `TournamentReplion`, `Clean`, `Enabled`, `PlayersWin`, `Get`, `Name`, `WinsNeededToWin`, `YouWin`, `Visible`, `YouLost`, `RewardFrame`, `IsFinalServer`, `task`, `delay`, `FinalButton`, `LobbyButton`, `Leave`, `Go to Final`, `IsSpectator`, `GetAttribute`, `spectate should be visible:`, `is spectator:`, `SpectateButton`, `LeaveButton`, `UDim2`, `fromScale`, `Position`, `WinFade`, `Title`, `Match ended`, `You Lost`, `Prompt`, `observeReplionPath`, `MatchEnded`, `TournamentGoToNextServer`, `clicked spectate`, `TournamentSpectate`, `ObserveReplion`, `Activated`, `Connect`, `Start`, `require`, `game`, `Players`, `GetService`, `LocalPlayer`, `PlayerScripts`, `WaitForChild`, `ClientLoader`, `ControllerIsolator`, `CreateRequire`, `script`, `ReplicatedStorage`, `Packages`, `Net`, `Common`, `Utils`, `Trove`, `Replion`, `Shared`, `ReplionUtils`, `TournamentData`, `Controllers`, `UI`, `SpectateController`, `Tournaments`, `TournamentsController`, `TournamentsUIController`, `PlayerGui`, `TournamentEnd`, `RunService`, `IsStudio`, `GameId`, `print`, `new`

### [831] ReplicatedStorage.Controllers.Tournaments.UI.TournamentsUIEventController
`ModuleScript` · bytecode v9 · 7198 bytes · 142 constants
- **Remotes:** Data
- **Services:** Players, ReplicatedStorage, game, workspace
- **Key API:** Clone, Connect, Disconnect, FireServer, GetService, Invoke, InvokeServer, Play, WaitForChild, new
- Constants: `Trophies`, `GetUsername`, `await`, `IsDescendantOf`, `PlayerName`, `Text`, `Clean`, `Remotes`, `GetEventTournamentLeaderboard`, `InvokeServer`, `table`, `insert`, `sort`, `Clone`, `Add`, `Rank`, `#%*`, `format`, `LayoutOrder`, `tostring`, `UserId`, `Name`, `...`, `task`, `spawn`, `Headshot`, `ProfilePicture`, `rbxthumb://type=AvatarHeadShot&id=%*&w=150&h=150`, `Image`, `TrophyCounter`, `Amount`, `ValueConvertor`, `AddCommas`, `LostCount`, `LostBox%*`, `X`, `StrikesLeft`, `DailyStrikes`, `Visible`, `Parent`, `UpdateLeaderboard`, `TournamentStrikeEnabled`, `GetKey`, `_strikeTournamentEnabled`, `ScreenGui`, `TopButtons`, `Event`, `updateEventVisible`, `TournamentReturnToLobby`, `FireServer`, `Info`, `HasOpenedTournamentsUI`, `Get`, `OpenedTournamentUIFirstTime`, `Invoke`, `TrophyViewer`, `Enum`, `InfoType`, `Product`, `PromptPurchase`, `LastTournamentStrikesReset`, `workspace`, `GetServerTimeNow`, `PlayButton`, `Label`, `Resets in:%*`, `FormatTimeHHMMSS`, `Disconnect`, `Thread`, `Every`, `Play`, `JoinGlobalTournament`, `type`, `Tournaments`, `Close`, `PromptGlobal`, `TournamentStrikes`, `Buy`, `TournamentStrikesPurchased`, `TournamentTrophies`, `LocalPlayer`, `updateLocalPlayer`, `TOURNAMENTS_RELEASE_UNIX`, `math`, `ceil`, `FormatTimeWithDaysFull`, `DataUpdatedEvent`, `Connect`, `LeaveButton`, `Activated`, `isTournamentMatchServer`, `InfoButton`, `Frame`, `Client`, `Data`, `WaitReplion`, `OnGuiOpen`, `observeReplionPath`, `TournamentTickets`, `BuyAttempts`, `OnChange`, `Timer`, `Time`, `Start`, `require`, `game`, `Players`, `GetService`, `PlayerScripts`, `WaitForChild`, `ClientLoader`, `ControllerIsolator`, `CreateRequire`, `script`, `ReplicatedStorage`, `Packages`, `Net`, `Common`, `Utils`, `Trove`, `Replion`, `Shared`, `ReplionUtils`, `ServerInfo`, `PlayerUtility`, `ClientGameModules`, `GuiHandler`, `TournamentData`, `MarketplaceService`, `Controllers`, `TournamentsController`, `UI`, `TournamentsUIController`, `FFlagClient`, `Trading`, `TradeTokensController`, `TabsFolder`, `ScrollingFrame`, `UIListLayout`, `Template`, `new`

### [832] ReplicatedStorage.Controllers.Tournaments.UI.TournamentsUIEventController.TournamentsUIEventController
`Script` · bytecode v9 · 787 bytes · 19 constants
- **Key API:** GetAttribute, SetAttribute
- Constants: `debug`, `setmemorycategory`, `Name`, `Start`, `script`, `Parent`, `require`, `Loaded`, `SetAttribute`, `Init`, `GetAttribute`, `GetAttributeChangedSignal`, `Wait`, `pcall`, `task`, `spawn`, `error`, `%*:Init() - %*`, `format`

### [833] ReplicatedStorage.Controllers.Tournaments.UI.TournamentsUIPlayController
`ModuleScript` · bytecode v9 · 2940 bytes · 65 constants
- **Services:** Players, ReplicatedStorage, game
- **Key API:** Connect, FindFirstChild, GetService, InvokeServer, Play, WaitForChild
- Constants: `Body`, `<stroke thickness="3" color="rgb(4,13,26)">The entry fee is <font color="rgb(254, 201, 43)">%* Coins</font>. Would you like to proceed?</stroke>`, `ValueConvertor`, `EntryFee`, `AddCommas`, `format`, `Text`, `CoinsPopup`, `SwitchView`, `Play`, `Remotes`, `JoinGlobalTournament`, `type`, `Coin`, `index`, `InvokeServer`, `pcall`, `Tournaments`, `Close`, `PromptGlobal`, `Visible`, `CoinTournaments`, `List`, `Option%*`, `FindFirstChild`, `Amount`, `Prize`, `Reward`, `MapImage`, `Map`, `Image`, `Activated`, `Connect`, `Buttons`, `Decline`, `Accept`, `GetPropertyChangedSignal`, `Start`, `require`, `game`, `Players`, `GetService`, `LocalPlayer`, `PlayerScripts`, `WaitForChild`, `ClientLoader`, `ControllerIsolator`, `CreateRequire`, `script`, `ReplicatedStorage`, `Packages`, `Net`, `Common`, `Utils`, `ClientGameModules`, `GuiHandler`, `Shared`, `TournamentData`, `MapData`, `Controllers`, `TournamentsController`, `UI`, `TournamentsUIController`, `FFlagClient`, `TabsFolder`

### [834] ReplicatedStorage.Controllers.Tournaments.UI.TournamentsUIRoomsController
`ModuleScript` · bytecode v9 · 2464 bytes · 66 constants
- **Services:** Players, ReplicatedStorage, game
- **Key API:** Clone, Connect, GetService, InvokeServer, WaitForChild, new
- Constants: `Remotes`, `JoinTournamentRoom`, `partitionKey`, `InvokeServer`, `Clean`, `NoRoomsAvailable`, `Visible`, `Clone`, `Add`, `LayoutOrder`, `RoomName`, `name`, `Text`, `Location`, `region`, `PlayerCount`, `%*/%*`, `playersInRoom`, `players`, `format`, `Color3`, `fromRGB`, `new`, `TextColor3`, `JoinButton`, `SpectateButton`, `Parent`, `Activated`, `Connect`, `RenderList`, `SearchTournamentRooms`, `UpdateRooms`, `Tournaments`, `OnGuiOpen`, `Start`, `require`, `game`, `Players`, `GetService`, `LocalPlayer`, `PlayerScripts`, `WaitForChild`, `ClientLoader`, `ControllerIsolator`, `CreateRequire`, `script`, `ReplicatedStorage`, `Packages`, `Net`, `Common`, `Utils`, `Trove`, `ClientGameModules`, `GuiHandler`, `Shared`, `TournamentData`, `MapData`, `Controllers`, `TournamentsController`, `UI`, `TournamentsUIController`, `TabsFolder`, `Rooms`, `ScrollingFrame`, `UIListLayout`, `Template`

### [835] ReplicatedStorage.Controllers.Tournaments.UI.TournamentsUITopController
`ModuleScript` · bytecode v9 · 3951 bytes · 88 constants
- **Services:** Players, ReplicatedStorage, RunService, game, workspace
- **Key API:** Connect, Disconnect, FindFirstChild, GetService, WaitForChild, new
- Constants: `Player`, `UserId`, `### updating tourney top`, `PlayersWin`, `Get`, `PlayerGui`, `announcer`, `UIPadding`, `UDim`, `new`, `PaddingTop`, `next`, `Enabled`, `FindFirstChild`, `Wins`, `table`, `insert`, `sort`, `Frame`, `Headshot`, `rbxthumb://type=AvatarHeadShot&id=%*&w=100&h=100`, `format`, `Image`, `WinsAm`, `ValueConvertor`, `AddCommas`, `Text`, `Dead`, `Character`, `IsDescendantOf`, `Visible`, `Crown`, `tostring`, `Color3`, `BackgroundColor3`, `find`, `update`, `Disconnect`, `IsSpectator`, `GetAttributeChangedSignal`, `Connect`, `Add`, `Clean`, `workspace`, `Alive`, `WaitForChild`, `AncestryChanged`, `ChildAdded`, `ChildRemoved`, `observeReplionPath`, `observePlayer`, `ObserveReplion`, `Start`, `require`, `game`, `Players`, `GetService`, `LocalPlayer`, `PlayerScripts`, `ClientLoader`, `ControllerIsolator`, `CreateRequire`, `script`, `ReplicatedStorage`, `Packages`, `Net`, `Common`, `Utils`, `Trove`, `Replion`, `Shared`, `ReplionUtils`, `Observers`, `TournamentData`, `Controllers`, `Tournaments`, `TournamentsController`, `UI`, `TournamentsUIController`, `TournamentsTop`, `RunService`, `IsStudio`, `GameId`, `print`, `Red`, `Blue`, `Green`, `Yellow`

### [836] ReplicatedStorage.Controllers.Trading.ExistCounterController
`ModuleScript` · bytecode v9 · 2786 bytes · 53 constants
- **Remotes:** Data
- **Services:** Players, ReplicatedStorage, game
- **Key API:** Connect, GetService, WaitForChild
- Constants: `_enabled`, `IsEnabled`, `Client`, `ClientExistCount`, `WaitReplion`, `KeyToItem`, `Sword`, `Finisher`, `Accessory`, `SwordAccessory`, `Items`, `Name`, `Get`, `GetItem`, `ItemToKey`, `typeof`, `table`, `OnChange`, `OnUpdated`, `Enabled`, `updateEnabled`, `Data`, `DataUpdatedEvent`, `Connect`, `Start`, `require`, `game`, `Players`, `GetService`, `LocalPlayer`, `PlayerScripts`, `WaitForChild`, `ClientLoader`, `ControllerIsolator`, `CreateRequire`, `script`, `ReplicatedStorage`, `Packages`, `Replion`, `Net`, `Shared`, `Inventory`, `InventoryTypes`, `Signal`, `ServerInfo`, `ClientGameModules`, `FFlagClient`, `UntradableItems`, `Internal`, `DefaultItems`, `Controllers`, `Trading`, `RAPController`

### [837] ReplicatedStorage.Controllers.Trading.ExistCounterController.ExistCounterController
`Script` · bytecode v9 · 787 bytes · 19 constants
- **Key API:** GetAttribute, SetAttribute
- Constants: `debug`, `setmemorycategory`, `Name`, `Start`, `script`, `Parent`, `require`, `Loaded`, `SetAttribute`, `Init`, `GetAttribute`, `GetAttributeChangedSignal`, `Wait`, `pcall`, `task`, `spawn`, `error`, `%*:Init() - %*`, `format`

### [838] ReplicatedStorage.Controllers.Trading.IndexController
`ModuleScript` · bytecode v9 · 25126 bytes · 321 constants
- **Remotes:** Data, Freeze, Set
- **Services:** Players, ReplicatedStorage, RunService, StarterGui, UserInputService, game, workspace
- **Key API:** Clone, Connect, Destroy, FindFirstChild, Fire, FireServer, GetAttribute, GetChildren, GetService, InvokeServer, IsA, Once, WaitForChild, new
- Constants: `Index`, `ItemToKey`, `Render`, `Open`, `openRapChart`, `Blackout`, `BackgroundTransparency`, `Spinner`, `ImageTransparency`, `Rotation`, `Enabled`, `fastTween`, `TweenInfo`, `new`, `Enum`, `EasingStyle`, `Linear`, `EasingDirection`, `Out`, `setSearch`, `Sine`, `Completed`, `Once`, `removeSearch`, `Get`, `GetCurrentPage`, `table`, `insert`, `Set`, `SetPage`, `remove`, `Back`, `UI`, `Fire`, `Index showroom not found`, `assert`, `isTradingPlazaServer`, `Info`, `Sword`, `Name`, `Base Sword`, `_lastUI`, `_onCloseCallback`, `Close`, `FireServer`, `Clean`, `os`, `clock`, `Preview`, `_currentGui`, `Trade`, `PreviewClicked`, `Add`, `Teleport`, `InvokeServer`, `GUID`, `warn`, `Failed to teleport to listing!
%*`, `No data`, `format`, `pcall`, `task`, `wait`, `delay`, `PromptType`, `Ok`, `Description`, `Internal server error [1]`, `CreatePrompt`, `type`, `Accept`, `A seller has been found!
Would you like to teleport to their server?`, `AcceptButtonText`, `Yes`, `DeclineButtonText`, `No`, `No users selling this item are online :(`, `Internal server error [2]`, `GetRAPAsync`, `Rap`, `Amount`, `ValueConvertor`, `ShrinkNumber`, `Text`, `GetChildren`, `ClassName`, `UIListLayout`, `Template`, `Destroy`, `destroyOld`, `NoResults`, `Visible`, `Loading`, `fullClearOnlineSellers`, `OnlineSellers`, `Failed to teleport to listing`, `Failed to load online sellers for %* %*`, `FindFirstChild`, `Price`, `Clone`, `LayoutOrder`, `AddCommas`, `ProfilePicture`, `Headshot`, `rbxthumb://type=AvatarHeadShot&id=%*&w=100&h=100`, `Seller`, `UserId`, `Image`, `Parent`, `Join`, `Activated`, `Connect`, `Remove`, `updateOnlineSellers`, `%*
%*`, `debug`, `traceback`, `FFlag`, `GetFFlag`, `IndexCanRefreshOnlineSellers`, `xpcall`, `IndexOnlineSellersRefreshTime`, `Character`, `workspace`, `Alive`, `IsDescendantOf`, `string`, `ItemPreview`, `Item`, `Vector`, `Icon`, `Icons`, `DEFAULT_MISSING`, `GetIcon`, `ItemName`, `DisplayName`, `Owned`, `FindItemsWithKey`, `Unowned`, `Extend`, `GetFavoriteState`, `setPropertyComputed`, `FavoritedTemplate`, `Finisher`, `Label`, `Preview Finisher`, `RapButton`, `ShowSellers`, `Explosion`, `Emote`, `IsEnabled`, `ShouldShowRAP`, `GetRAP`, `---`, `spawn`, `Type`, `Value`, `SwordAccessory`, `Accessory`, `PreviewReward`, `find`, `CanPreview`, `Controllers`, `Trading`, `RAPChartController`, `Init`, `updateFavorited`, `State`, `Client`, `Data`, `WaitReplion`, `IndexFavorites`, `OnChange`, `Id`, `InventoryTypes`, `List`, `map`, `pairs`, `TradableItemTypes`, `HasFinisher`, `_Finisher`, `AccessoryUnlockable`, `_Accessory`, `FakeCaller`, `CustomType`, `Replion`, `Tokens`, `Inventory`, `Equipped`, `EquippedList`, `CreateFakeReplion`, `GetFakeCaller`, `rbxassetid://18123223527`, `rbxassetid://18123248161`, `rbxassetid://18123872657`, `rbxassetid://18123874724`, `HoverImage`, `UIStroke`, `Color3`, `fromRGB`, `Color`, `ItemsList`, `Vector2`, `zero`, `CanvasPosition`, `All`, `Favorites`, `ViewOnlineSellers`, `GetAttribute`, `SaleListingsMode`, `updateState`, `SetCamera`, `Middle`, `Right`, `Find Seller`, `< Show Sellers`, `RapChart`, `previewItem`, `Phone`, `Tablet`, `UDim2`, `fromScale`, `FindItems`, `ShownItems`, `Computed`, `GetVisibleState`, `setPropertyState`, `ActivationButton`, `OnSlotCreated`, `Wait`, `OnGuiOpen`, `OnGuiClose`, `Main`, `Top`, `ImageButton`, `IsA`, `FocusLost`, `ItemSearch`, `Search`, `Sort`, `CreateSortOptions`, `GetAttributeChangedSignal`, `Hide`, `UIGridLayout`, `CellSize`, `ItemTemplate`, `Container`, `Caller`, `SearchFilter`, `SortOption`, `SortOrder`, `Dictionary`, `merge`, `InventoryType`, `PageVisible`, `CreateInventory`, `Start`, `require`, `game`, `Players`, `GetService`, `LocalPlayer`, `PlayerScripts`, `WaitForChild`, `ClientLoader`, `ControllerIsolator`, `CreateRequire`, `script`, `ProximityPromptService`, `ServerScriptService`, `ReplicatedStorage`, `UserInputService`, `StarterGui`, `RunService`, `Packages`, `Freeze`, `Trove`, `Net`, `ClientGameModules`, `DeviceListener`, `GuiHandler`, `Common`, `Utils`, `FinishersController`, `InventoryController`, `ShowRoomController`, `RAPController`, `PromptController`, `Shared`, `FastUtils`, `Internal`, `DefaultItems`, `TradeInfo`, `UntradableItems`, `IndexData`, `ItemInfo`, `Statable`, `RewardInfo`, `Signal`, `ServerInfo`, `rbxassetid://15697987058`, `rbxassetid://15697983062`, `rbxassetid://15697981750`, `Default`, `Alphabetical`, `RAP`, `Creation Date`, `Exists`, `PlayerGui`, `IndexScreenBlackout`, `Left`, `MainLabel`, `SearchBox`, `CurrentCamera`, `TradePlaza/TeleportToListing`, `RemoteFunction`, `TradePlaza/GetItemListings`, `Index/Favorite`, `RemoteEvent`, `Most`

### [839] ReplicatedStorage.Controllers.Trading.IndexController.IndexController
`Script` · bytecode v9 · 787 bytes · 19 constants
- **Key API:** GetAttribute, SetAttribute
- Constants: `debug`, `setmemorycategory`, `Name`, `Start`, `script`, `Parent`, `require`, `Loaded`, `SetAttribute`, `Init`, `GetAttribute`, `GetAttributeChangedSignal`, `Wait`, `pcall`, `task`, `spawn`, `error`, `%*:Init() - %*`, `format`

### [840] ReplicatedStorage.Controllers.Trading.InventoryController
`ModuleScript` · bytecode v9 · 21196 bytes · 232 constants
- **Remotes:** Data, Freeze, Set
- **Services:** Players, ReplicatedStorage, RunService, StarterGui, UserInputService, game
- **Key API:** Clone, Connect, Destroy, FindFirstChild, GetAttribute, GetChildren, GetService, IsA, SetAttribute, WaitForChild, new
- Constants: `Get`, `Set`, `updateFavorited`, `State`, `Client`, `Data`, `WaitReplion`, `GetLegacyInventoryPath`, `Favorites`, `OnChange`, `GetFavoriteState`, `Name`, `rbxassetid://18123223527`, `rbxassetid://18123248161`, `Image`, `rbxassetid://18123872657`, `rbxassetid://18123874724`, `HoverImage`, `Label`, `UIStroke`, `Color3`, `fromRGB`, `Color`, `new`, `GetChildren`, `ImageButton`, `IsA`, `Computed`, `Add`, `Activated`, `Connect`, `CreateTabOptions`, `Text`, `SearchBox`, `FocusLost`, `Search`, `CreateSearchBox`, `debug`, `profilebegin`, `toggleSort`, `Most`, `Least`, `profileend`, `FilterPopUp`, `Visible`, `getReplionPathState`, `AllItemsLoaded`, `ItemRAP`, `setPropertyComputed`, `os`, `clock`, `UIListLayout`, `Template`, `Clone`, `Parent`, `RAP`, `task`, `spawn`, `Arrow`, `Rotation`, `CreateSortOptions`, `Enum`, `SortOrder`, `LayoutOrder`, `Sort`, `FavoritedTemplate`, `Remove`, `ItemName`, `Position`, `updateIcons`, `ItemsMatching`, `Emote`, `string`, `find`, `Emote1058`, `Stack`, `x67`, `ShowCreatedAt`, `Item`, `CreatedAt`, `x%*`, `format`, `Finisher`, `SwordAccessory`, `Lock`, `TradeLock`, `Ability`, `HasInteractedWithTrading`, `Type`, `Trial`, `updateLock`, `assert`, `Destroy`, `ItemInfo`, `DisplayName`, `Vector`, `Icon`, `IsFavorited`, `setPropertyState`, `ItemKey`, `AllowAbilityInfo`, `Rarity`, `SlotColors`, `Default`, `StrokeColor`, `OnSlotCreated`, `Sword`, `Misc`, `DataFinishers`, `FindFirstChild`, `GetAttribute`, `Accessory`, `GetCollection`, `CanTradeInstant`, `Constructor`, `Id`, `ItemToKey`, `itemToKey`, `FindItemsWithKey`, `tryRemoveSlot`, `trove:Destroy`, `Trove`, `updateSlot`, `findItemsWithKey`, `List`, `equals`, `byte`, `char`, `IsEnabled`, `FastGetRAP`, `ShouldShowRAP`, `updateRAP`, `OnRAPUpdated`, `updateExistCounter`, `OnUpdated`, `lower`, `sub`, `Alphabetical`, `%*%*%*|%*`, `#`, `~`, `type`, `function`, `Exists`, `Creation Date`, `AddInstance`, `RemoveInstance`, `createSlot`, `warn`, `Failed to find info for %*: "%*"`, `getFilteredItemKey`, `GetFilteredItemKey`, `Extend`, `gsub`, `.`, `RarityOrder`, `Base Sword`, `Explosion Normal`, `GetVisibleState`, `Insert`, `Change`, `onChange`, `ItemTemplate`, `Container`, `Caller`, `InventoryType`, `SearchFilter`, `PageVisible`, `ScrollingFrame`, `UIGridLayout`, `FindFirstChildWhichIsA`, `Container is not a scrolling frame, it needs to be a ScrollingFrame with UIGridLayout`, `SortOption`, `SortMode`, `UseFavorites`, `ChangeNameStroke`, `AllowedIcons`, `Favorited`, `ClientExistCount`, `ExistCounterReplionChannel`, `table`, `Size`, `remove`, `SetAttribute`, `WatchOnChange`, `TriggerUpdate`, `CreateInventory`, `Start`, `require`, `game`, `Players`, `GetService`, `LocalPlayer`, `PlayerScripts`, `WaitForChild`, `ClientLoader`, `ControllerIsolator`, `CreateRequire`, `script`, `ServerScriptService`, `ReplicatedStorage`, `UserInputService`, `StarterGui`, `RunService`, `Packages`, `Replion`, `Freeze`, `Common`, `Utils`, `Shared`, `Inventory`, `InventoryTypes`, `Controllers`, `UI`, `ShopControllerAPI`, `Trading`, `TradeController`, `ExistCounterController`, `RAPController`, `TradeInfo`, `Statable`, `ServerInfo`, `VirtualGridScroll`, `HoverInfoController`, `ReplicatedInstances`, `SwordAccessories`, `Icons`, `DEFAULT_MISSING`, `GetIcon`, `Explosion`, `PlayerGui`

### [841] ReplicatedStorage.Controllers.Trading.InventoryController.InventoryController
`Script` · bytecode v9 · 787 bytes · 19 constants
- **Key API:** GetAttribute, SetAttribute
- Constants: `debug`, `setmemorycategory`, `Name`, `Start`, `script`, `Parent`, `require`, `Loaded`, `SetAttribute`, `Init`, `GetAttribute`, `GetAttributeChangedSignal`, `Wait`, `pcall`, `task`, `spawn`, `error`, `%*:Init() - %*`, `format`

### [842] ReplicatedStorage.Controllers.Trading.RAPChartController
`ModuleScript` · bytecode v9 · 10695 bytes · 190 constants
- **Services:** Players, ReplicatedStorage, UserInputService, game
- **Key API:** Clone, Connect, Destroy, FindFirstChild, GetAttribute, GetChildren, GetService, InvokeServer, IsA, SetAttribute, WaitForChild, new
- Constants: `Frame`, `Chart`, `HoverInfo`, `List`, `RAP`, `Label`, `GetAttribute`, `Text`, `Count`, `%* %*`, `1`, `Sale`, `Sales`, `format`, `Date`, `AbsoluteSize`, `X`, `Y`, `math`, `max`, `UIScale`, `Scale`, `UDim2`, `new`, `Position`, `Offset`, `Visible`, `selectPoint`, `Booth`, `GetChildren`, `GuiObject`, `IsA`, `SearchFrame`, `FindFirstChild`, `Inventory`, `Holder`, `Pages`, `Index`, `GetCurrentPage`, `RapChart`, `SetPage`, `Back`, `ControllerShop`, `Controllers`, `UI`, `ShopControllerAPI`, `Variants`, `Console`, `FrameUIHiddenDynArgs`, `RAPChart`, `SetTag`, `Main`, `toggleVisibility`, `min`, `UnixTimestamp`, `getExtrema`, `Open`, `_renderedItemKey`, `Close`, `Loading`, `NoData`, `KeyToItem`, `warn`, `Invalid ItemKey: %*`, `_IGNORE_ATTRIBUTES`, `ItemToKey`, `Name`, `GetItemInfo`, `INVALID ITEM COULD NOT BE FOUND: %* called "%*"`, `Top`, `ItemName`, `"%*" RAP History`, `DisplayName`, `ItemFrame`, `Vector`, `Icon`, `Icons`, `DEFAULT_MISSING`, `GetIcon`, `Image`, `Rarity`, `SlotColors`, `Default`, `HoverImage`, `_breakdown`, `_renderedBreakdown`, `DateTime`, `now`, `fromUnixTimestamp`, `InvokeServer`, `Failed to load RAP History for item: %*`, `Path2D`, `Destroy`, `ToUniversalTime`, `fromUniversalTime`, `Year`, `Month`, `Day`, `Hour`, `Daily`, `table`, `insert`, `sort`, `XAxis`, `Label%*`, `MMM D`, `SystemLocaleId`, `FormatUniversalTime`, `log10`, `round`, `ceil`, `YAxis`, `ValueConvertor`, `ShrinkNumber`, `AddCommas`, `Clone`, `fromScale`, `clamp`, `Circle`, `Amount`, `l`, `SetAttribute`, `MouseEnter`, `Connect`, `MouseLeave`, `Parent`, `Path2DControlPoint`, `Instance`, `Color3`, `fromRGB`, `Thickness`, `ZIndex`, `SetControlPoints`, `_renderedItemType`, `TimePeriod`, `TextLabel`, `Render`, `Hourly`, `pairs`, `BackButton`, `Failed to find BackButton for %* RAPChart`, `Activated`, `RAPHistory.ViewHourly`, `HasPermission`, `WindowFocusReleased`, `Start`, `require`, `game`, `Players`, `GetService`, `LocalPlayer`, `PlayerScripts`, `WaitForChild`, `ClientLoader`, `ControllerIsolator`, `CreateRequire`, `script`, `LocalizationService`, `ReplicatedStorage`, `UserInputService`, `Packages`, `Replion`, `Net`, `Common`, `Utils`, `ClientGameModules`, `GuiHandler`, `Shared`, `InventoryTypes`, `Client`, `Trading`, `RAPController`, `TradeInfo`, `ItemInfo`, `IndexController`, `AdminPanel`, `AdminPanelUIController`, `PlayerGui`, `BoothInventory`, `MainFrame`, `Shop`, `Left`, `MainLabel`, `PointTemplate`, `RequestRAPHistory`, `RemoteFunction`, `ScreenGui`, `Viewport_Size_Reference`, `IgnoreGuiInset`

### [843] ReplicatedStorage.Controllers.Trading.RAPChartController.RAPChartController
`Script` · bytecode v9 · 787 bytes · 19 constants
- **Key API:** GetAttribute, SetAttribute
- Constants: `debug`, `setmemorycategory`, `Name`, `Start`, `script`, `Parent`, `require`, `Loaded`, `SetAttribute`, `Init`, `GetAttribute`, `GetAttributeChangedSignal`, `Wait`, `pcall`, `task`, `spawn`, `error`, `%*:Init() - %*`, `format`

### [844] ReplicatedStorage.Controllers.Trading.RAPController
`ModuleScript` · bytecode v9 · 4615 bytes · 83 constants
- **Remotes:** Data
- **Services:** Players, ReplicatedStorage, game, workspace
- **Key API:** Connect, GetAttribute, GetService, Invoke, WaitForChild
- Constants: `_enabled`, `IsEnabled`, `HoverInfoDebugEnabled`, `GetAttribute`, `table`, `find`, `typeof`, `ShouldShowRAP`, `ItemToKey`, `GetFilteredItemKey`, `UUIDToKey`, `GetRAPAsync`, `GetItemRAPAsync`, `RequestItemRAP`, `Invoke`, `Client`, `ItemRAP`, `WaitReplion`, `Name`, `Items`, `Get`, `LastUpdate`, `workspace`, `GetServerTimeNow`, `task`, `wait`, `xpcall`, `warn`, `FastGetRAPAsync`, `KeyToItem`, `GetReplion`, `FastGetRAP`, `GetRAP`, `GetItemRAP`, `OnDescendantChange`, `OnRAPUpdated`, `RAPServiceEnabled`, `GetKey`, `Enabled`, `TotalStats.Wins`, `GetExpect`, `updateEnabled`, `Data`, `DataUpdatedEvent`, `Connect`, `OnChange`, `Start`, `require`, `game`, `Players`, `GetService`, `LocalPlayer`, `PlayerScripts`, `WaitForChild`, `ClientLoader`, `ControllerIsolator`, `CreateRequire`, `script`, `ReplicatedStorage`, `Packages`, `Replion`, `Net`, `Shared`, `Inventory`, `InventoryTypes`, `Signal`, `Statable`, `Trading`, `TradeInfo`, `ServerInfo`, `ClientGameModules`, `FFlagClient`, `UntradableItems`, `Internal`, `DefaultItems`, `Id`, `TradeLock`, `Kills`, `Serial`, `IsSelected`, `Description`, `IsCustom`, `_IGNORE_ATTRIBUTES`

### [845] ReplicatedStorage.Controllers.Trading.RAPController.RAPController
`Script` · bytecode v9 · 787 bytes · 19 constants
- **Key API:** GetAttribute, SetAttribute
- Constants: `debug`, `setmemorycategory`, `Name`, `Start`, `script`, `Parent`, `require`, `Loaded`, `SetAttribute`, `Init`, `GetAttribute`, `GetAttributeChangedSignal`, `Wait`, `pcall`, `task`, `spawn`, `error`, `%*:Init() - %*`, `format`

### [846] ReplicatedStorage.Controllers.Trading.TradeController
`ModuleScript` · bytecode v9 · 5009 bytes · 78 constants
- **Remotes:** Data
- **Services:** Players, ReplicatedStorage, RunService, game, workspace
- **Key API:** Connect, Destroy, GetAttribute, GetService, WaitForChild, new
- Constants: `CanTradeInstant`, `task`, `spawn`, `Destroy`, `update`, `Client`, `Data`, `WaitReplion`, `new`, `__globalUpdatesInitialized`, `GetAttributeChangedSignal`, `Connect`, `Add`, `TradeBanned`, `OnChange`, `TradeLockedUntil`, `TotalStats.Wins`, `AddPromise`, `andThen`, `DateTime`, `now`, `UnixTimestamp`, `JoinedTimestamp`, `GetAttribute`, `LastSession`, `Get`, `FFlag`, `GetInstantFFlag`, `TradeJoinCooldown`, `IsStudio`, `delay`, `ListenForCanTrade`, `GetReplion`, `You are still loading!`, `You can't trade before getting 1 Win!`, `await`, `IsPaidItemTradingAllowed`, `You are restricted from trading due to Roblox policy!`, `HasTradeRequirements`, `GetFFlag`, `TradingEnabled`, `TradingSystemEnabled`, `Trading is currently disabled!`, `workspace`, `GetServerTimeNow`, `You are unable to trade!`, `You are unable to trade for %*`, `ValueConvertor`, `FormatShortTime`, `format`, `You can't trade for %* seconds!`, `math`, `ceil`, `CanTrade`, `HasTradeRequirementsInstant`, `require`, `game`, `Players`, `GetService`, `LocalPlayer`, `PlayerScripts`, `WaitForChild`, `ClientLoader`, `ControllerIsolator`, `CreateRequire`, `script`, `ReplicatedStorage`, `PolicyService`, `RunService`, `Packages`, `Replion`, `Promise`, `Signal`, `Trove`, `Common`, `Utils`, `retryWithDelay`, `GetPolicyInfoForPlayerAsync`

### [847] ReplicatedStorage.Controllers.Trading.TradeController.TradeController
`Script` · bytecode v9 · 787 bytes · 19 constants
- **Key API:** GetAttribute, SetAttribute
- Constants: `debug`, `setmemorycategory`, `Name`, `Start`, `script`, `Parent`, `require`, `Loaded`, `SetAttribute`, `Init`, `GetAttribute`, `GetAttributeChangedSignal`, `Wait`, `pcall`, `task`, `spawn`, `error`, `%*:Init() - %*`, `format`

### [848] ReplicatedStorage.Controllers.Trading.TradePINCodeController
`ModuleScript` · bytecode v9 · 15516 bytes · 192 constants
- **Remotes:** Freeze, Set
- **Services:** ContextActionService, Players, ReplicatedStorage, UserInputService, game
- **Key API:** Connect, FireServer, GetChildren, GetService, Invoke, InvokeServer, IsA, Play, WaitForChild
- Constants: `Text`, `string`, `len`, `tonumber`, `PlaceholderColor3`, `_getPINCode`, `_clearPINBoxes`, `_clearRecoveryBoxes`, `Get`, `SetPIN`, `CheckPIN`, `_currentTextBoxIndex`, `match`, `^%d?`, `CaptureFocus`, `NextSelectionRight`, `NextSelectionLeft`, `Focused`, `Connect`, `GetPropertyChangedSignal`, `_setupPINBox`, `ResetPIN`, `String`, `RemoveWhitespace`, `SaveRecoveryPhrase`, `_setupRecoveryBox`, `table`, `insert`, `_getRecoveryWords`, `Set`, `Visible`, `SuccesfullyChanged`, `TextEditable`, `%*. %*`, `???`, `format`, `ShowRecoveryPhrase`, `_isBeingUsed`, `%*.`, `PlaceholderText`, `TryResetPINWithPhrase`, `PINRecovery`, `TryResetPINWithPIN`, `Info`, `Enabled`, `Disabled`, `SetPin`, `ResetPin`, `TriesLeft`, `PinOrPhrase`, `Main`, `Label`, `Enter your 4-digit PIN`, `Enter your 4-digit PIN to reset your PIN`, `Set a 4-Digit Trading PIN that must be entered to trade when you join the game.`, `ResetText`, `RetriesLeft`, `Close`, `Buttons`, `Cancel`, `Check`, `SafetyWarn`, `DoNotShare`, `Label1`, `Misc`, `error`, `Play`, `_G`, `SendNotification`, `You already have a pin, if you've forgotten it, you should reset it.`, `TradeRequest`, `IsOpen`, `CurrentTab`, `TradeSettings`, `ResetPINCode`, `option`, `Phrase`, `value`, `Invoke`, `cancelRecovery`, `<stroke color="rgb(0,0,0)" joins="round" thickness="2">You have<font color="rgb(255, 58, 58)"> (%*) </font>attempts remaining today </stroke>`, `RespondPINCheck`, `_confirmationStep`, `InvokeServer`, `pinCode`, `Enter your 4-digit trading PIN again`, `The PINs are not the same!`, `type`, `Your PIN has been successfully set!`, `PIN`, `task`, `spawn`, `cancelSetPin`, `GetFocusedTextBox`, `find`, `KeyCode`, `Enum`, `Backspace`, `Tab`, `TouchEnabled`, `KeyboardEnabled`, `Selectable`, `Active`, `updateDevice`, `%D`, `gsub`, `sub`, `boolean`, `TradePINWarning`, `Unlock`, `TradePINResetWarn`, `FireServer`, `PINResetWarnsLeft`, `TradePINCode`, `Client`, `Inventory`, `WaitReplion`, `ScrollingFrame`, `TradingPin`, `getReplionPathState`, `Computed`, `Activated`, `ResetWithPin`, `ResetWithRecoveryPhrase`, `State`, `Checkbox`, `setPropertyState`, `ToggleImage`, `Confirm`, `PINResetRetries`, `PINCheckRetries`, `InputBegan`, `MobileTextBox`, `LastInputTypeChanged`, `RequestPINCheck`, `isTradingPlazaServer`, `PINWarnTradePlaza`, `Open`, `Lock`, `Yes`, `OnGuiOpen`, `Start`, `require`, `game`, `Players`, `GetService`, `LocalPlayer`, `PlayerScripts`, `WaitForChild`, `ClientLoader`, `ControllerIsolator`, `CreateRequire`, `script`, `ReplicatedStorage`, `UserInputService`, `ContextActionService`, `Packages`, `Replion`, `Net`, `Freeze`, `Shared`, `Statable`, `Parent`, `TradeRequestController`, `ServerInfo`, `ClientGameModules`, `GuiHandler`, `Common`, `Utils`, `Color3`, `fromRGB`, `SetPINCode`, `RemoteFunction`, `CancelSetPINCode`, `RemoteEvent`, `UpdatePINResetWarn`, `PlayerGui`, `TradeSetPIN`, `TradePINRecovery`, `Views`, `Pin`, `Boxes`, `GetChildren`, `ImageLabel`, `IsA`, `TextBox`, `FindFirstChildWhichIsA`, `TextBox not found!`, `assert`, `Name`, `Invalid TextBox name!`

### [849] ReplicatedStorage.Controllers.Trading.TradePINCodeController.TradePINCodeController
`Script` · bytecode v9 · 787 bytes · 19 constants
- **Key API:** GetAttribute, SetAttribute
- Constants: `debug`, `setmemorycategory`, `Name`, `Start`, `script`, `Parent`, `require`, `Loaded`, `SetAttribute`, `Init`, `GetAttribute`, `GetAttributeChangedSignal`, `Wait`, `pcall`, `task`, `spawn`, `error`, `%*:Init() - %*`, `format`

### [850] ReplicatedStorage.Controllers.Trading.TradePlazaController
`ModuleScript` · bytecode v9 · 7391 bytes · 155 constants
- **Remotes:** Freeze
- **Services:** Players, ReplicatedStorage, RunService, StarterGui, UserInputService, game, workspace
- **Key API:** Connect, FindFirstChild, FireServer, GetService, WaitForChild, new
- Constants: `RaycastParams`, `new`, `Enum`, `RaycastFilterType`, `Exclude`, `FilterType`, `FilterDescendantsInstances`, `workspace`, `Raycast`, `Position`, `Magnitude`, `raycast`, `os`, `clock`, `FireServer`, `Clean`, `Heartbeat`, `Connect`, `Add`, `wentIdle`, `GetKeysPressed`, `Character`, `Humanoid`, `FindFirstChild`, `Trade Plaza AFK`, `Utils`, `MinDebuff`, `Priority`, `DEBUFF`, `SetModifierFor`, `HumanoidStateType`, `Jumping`, `ChangeState`, `task`, `delay`, `Extend`, `WindowFocusReleased`, `InputBegan`, `InputEnded`, `Idled`, `_trackIdle`, `UserId`, `IsFriendsWith`, `pcall`, `areFriends`, `PromptSendFriendRequest`, `SetCore`, `xpcall`, `warn`, `ViewInventory`, `SendTrade`, `Active`, `rbxassetid://18860669626`, `rbxassetid://18711594643`, `Image`, `rbxassetid://18860669386`, `rbxassetid://18711664706`, `HoverImage`, `Label`, `UIStroke`, `Color3`, `fromRGB`, `Color`, `updateAddFriend`, `hasPendingRequest`, `didInvite`, `isInMatch`, `options`, `CanViewInventory`, `CanInvite`, `rbxassetid://18711611169`, `rbxassetid://18711662604`, `Sent`, `Text`, `In Match`, `Disabled`, `Accept Trade`, `Send Trade`, `Not Accepting`, `rbxassetid://18860945893`, `rbxassetid://18711624747`, `rbxassetid://18860945505`, `rbxassetid://18711660772`, `GetPlayerStates`, `ProfilePicture`, `Headshot`, `rbxthumb://type=AvatarHeadShot&id=%*&w=150&h=150`, `format`, `Username1`, `DisplayName`, `Username2`, `@%*`, `Name`, `ListOfButtons`, `ButtonsList`, `AddFriend`, `Inventory`, `Activated`, `PlayerFriendedEvent`, `GetCore`, `Event`, `PlayerUnfriendedEvent`, `spawn`, `Computed`, `AttachToInstance`, `Open`, `ViewPlayer`, `Start`, `require`, `game`, `Players`, `GetService`, `LocalPlayer`, `PlayerScripts`, `WaitForChild`, `ClientLoader`, `ControllerIsolator`, `CreateRequire`, `script`, `ServerScriptService`, `ReplicatedStorage`, `UserInputService`, `GamepadService`, `StarterGui`, `RunService`, `Packages`, `Replion`, `Freeze`, `Trove`, `Observers`, `ClientGameModules`, `GuiHandler`, `Shared`, `Statable`, `Controllers`, `Trading`, `TradeRequestController`, `ViewInventoryController`, `DeviceListener`, `JumpModifiers`, `ServerInfo`, `Common`, `Net`, `PlayerGui`, `PlayerProfile`, `CurrentCamera`, `TradePlaza/AFKRejoin`, `RemoteEvent`, `Instance`, `Highlight`, `FillTransparency`, `OutlineTransparency`, `OutlineColor`, `Parent`, `RaycastResult`

### [851] ReplicatedStorage.Controllers.Trading.TradeRequestController
`ModuleScript` · bytecode v9 · 36420 bytes · 391 constants
- **Remotes:** Data, Freeze, Set
- **Services:** Players, ReplicatedStorage, RunService, StarterGui, UserInputService, game, workspace
- **Key API:** Clone, Connect, Destroy, Disconnect, FindFirstChild, FireServer, GetAttribute, GetChildren, GetPlayers, GetService, InvokeServer, IsA, OnClientEvent, Once, Play, SetAttribute, WaitForChild, new
- Constants: `Set`, `OpenPage`, `GetPlayerStates`, `isInviting`, `didInvite`, `Get`, `isInMatch`, `options`, `CanInvite`, `task`, `delay`, `Remotes`, `SendTradeRequest`, `InvokeServer`, `TradeRequestExpiration`, `Misc`, `error`, `Play`, `SendTrade`, `Username`, `@%*`, `[LOADING]`, `format`, `string`, `lower`, `sub`, `find`, `TradeItemsHistory`, `Clean`, `Users`, `UserId`, `tostring`, `tonumber`, `ProfilePicture`, `Headshot`, `rbxthumb://type=AvatarHeadShot&id=%*&w=150&h=150`, `Image`, `State`, `GetUser`, `andThen`, `AddPromise`, `setPropertyComputed`, `Text`, `Add`, `Tokens`, `Amount`, `ValueConvertor`, `AddCommas`, `Items`, `Id`, `ItemToKey`, `Name`, `GetItemInfo`, `warn`, `Failed to find info for %*: "%*"`, `ScrollingFrame`, `UIGridLayout`, `Template`, `Clone`, `ItemName`, `DisplayName`, `Vector`, `Icon`, `Icons`, `DEFAULT_MISSING`, `GetIcon`, `Rarity`, `SlotColors`, `Default`, `HoverImage`, `UIStroke`, `StrokeColor`, `Color`, `Visible`, `Parent`, `Stack`, `FindFirstChild`, `Finisher`, `SwordAccessory`, `Sword`, `DataFinishers`, `GetAttribute`, `Accessory`, `GetCollection`, `table`, `remove`, `Position`, `SetAttribute`, `Label`, `x%*`, `ShowTrade`, `Controllers`, `Trading`, `TradeTabController`, `Init`, `HasTradeRequirementsInstant`, `TradingEnabled`, `GetKey`, `TradingSystemEnabled`, `Character`, `workspace`, `Alive`, `LeftFrame`, `Bottom`, `BottomOptions`, `TradeButton`, `IsMobile`, `updateButtonVisibility`, `Open`, `HasInteractedWithTrading`, `SetUIOpen`, `FireServer`, `retryWithDelay`, `GetPolicyInfoForPlayerAsync`, `await`, `IsPaidItemTradingAllowed`, `TotalStats.Wins`, `rbxassetid://18349747903`, `rbxassetid://18349766782`, `rbxassetid://18349971549`, `rbxassetid://18349973767`, `Color3`, `fromRGB`, `TradePinEnter`, `GetChildren`, `ImageLabel`, `IsA`, `Close`, `PlayersList`, `TokensInfo`, `TradingTokensEnabled`, `Tokens are disabled!`, `SendNotification`, `TradingTokensPurchasesEnabled`, `Token purchases are disabled!`, `TokensShop`, `getReplionPathState`, `TradeReplionState`, `Destroy`, `clear`, `Disconnect`, `GetPropertyChangedSignal`, `Connect`, `CanViewInventory`, `AllowRequests`, `Friends`, `UserFriends`, `Everyone`, `ViewInventory`, `From`, `To`, `Inventory`, `Interaction`, `UDim2`, `fromScale`, `Size`, `rbxassetid://18349866093`, `rbxassetid://18349978039`, `SENT`, `rbxassetid://18349871268`, `rbxassetid://18349982582`, `IN MATCH`, `rbxassetid://18349847684`, `rbxassetid://18349979827`, `ACCEPT`, `SEND`, `NOT ACCEPTING`, `typeof`, `Instance`, `observeCharacter`, `Buttons`, `TextPreview`, `TextReveal`, `TextHoverReveal`, `AddTag`, `Computed`, `hasPendingRequest`, `Activated`, `observePlayer`, `List`, `removeValue`, `Thread`, `SafeCancel`, `RespondToTradeRequest`, `Description`, `Trade request from %* (@%*)
do you want to accept?`, `insert`, `Destroying`, `Once`, `Time`, `GetServerTimeNow`, `No`, `Yes`, `TradingTokensDisclaimer`, `3`, `Disclaimer`, `updateDisclaimer`, `Main`, `ProductId`, `PromptProductPurchase`, `TradeRequest`, `TradeHistoryPage`, `TradeHistoryIds`, `math`, `max`, `TradeIdToStatus`, `Status`, `Completed`, `Page`, `getTradeState`, `userId`, `username`, `Trade with @%*`, `+???`, `floor`, `%*%*`, `+`, `-`, `abs`, `ItemsHistory`, `Item`, `UIListLayout`, `LayoutOrder`, `SmallerSlotColors`, `filterTime`, `TradeHistory`, `new`, `DateTime`, `fromUnixTimestamp`, `l LT`, `ToLocalTime`, `Day`, `UnixTimestamp`, `LT`, `Yesterday `, `SystemLocaleId`, `FormatLocalTime`, `TextLabel`, `pcall`, `AttachToInstance`, `View`, `GetTradeHistoryPage`, `xpcall`, `type`, `Dictionary`, `set`, `wait`, `tryFetchPage`, `Wait`, `count`, `clone`, `Top`, `FilterPopUp`, `key`, `TextBox`, `Trade`, `Unlock`, `Trade Completed!`, `Trade Failed!`, `TradeCompleted`, `TradeSettings`, `Check`, `rbxassetid://18365905187`, `rbxassetid://18350075191`, `rbxassetid://18365913217`, `rbxassetid://18350101265`, `SetSetting`, `Disable`, `Enable`, `Enabled`, `Disabled`, `TextColor3`, `SetFriendState`, `PlayerFriendedEvent`, `GetCore`, `Event`, `PlayerUnfriendedEvent`, `Client`, `TradeList`, `WaitReplion`, `Data`, `GetInventoryVersion`, `New`, `OnChange`, `ChildAdded`, `ChildRemoved`, `DataUpdatedEvent`, `Observe`, `spawn`, `CanTradeInstant`, `ListenForCanTrade`, `OnGuiOpen`, `Views`, `TopButtons`, `ImageButton`, `Currency`, `About`, `AddMore`, `Coins`, `GetPlayers`, `IsStudio`, `ReceivedTradeRequest`, `OnClientEvent`, `ItemsList`, `assert`, `Bonus`, `BonusName`, `BonusIcon`, `BuyButton`, `%*`, `Ok`, `TemplateExpanded`, `AddToPageHistory`, `ItemSearch`, `SearchBox`, `FocusLost`, `Search`, `Filter`, `SearchPlayer`, `SearchButton`, `TradeStatus`, `Settings`, `Buttons frame not found for %*`, `Type`, `Option`, `Options`, `Toggle`, `WaitForChild`, `CurrentState`, `Start`, `require`, `game`, `Players`, `GetService`, `LocalPlayer`, `PlayerScripts`, `ClientLoader`, `ControllerIsolator`, `CreateRequire`, `script`, `ReplicatedStorage`, `PolicyService`, `LocalizationService`, `UserInputService`, `StarterGui`, `RunService`, `Packages`, `Replion`, `Promise`, `Freeze`, `Net`, `ClientGameModules`, `GuiHandler`, `Observers`, `Shared`, `TradeInfo`, `InventoryTypes`, `UI`, `ShopControllerAPI`, `NotificationController`, `TradeController`, `Trove`, `DeepCopy`, `Common`, `Utils`, `ServerInfo`, `TradingTokens`, `Statable`, `MarketplaceService`, `PlayerUtility`, `ItemInfo`, `ViewInventoryController`, `FFlagClient`, `DeviceListener`, `HoverInfoController`, `ReplicatedInstances`, `SwordAccessories`, `PlayerGui`, `HUD`, `TradeIncoming`, `ItemsReceived`, `ItemsSent`, `Last 7 Days`, `Last 14 Days`, `Last 30 Days`, `Last 60 Days`, `SpyderSammy`, `CurrentPage`, `CurrentTab`, `FakePlayer`

### [852] ReplicatedStorage.Controllers.Trading.TradeRequestController.TradeRequestController
`Script` · bytecode v9 · 787 bytes · 19 constants
- **Key API:** GetAttribute, SetAttribute
- Constants: `debug`, `setmemorycategory`, `Name`, `Start`, `script`, `Parent`, `require`, `Loaded`, `SetAttribute`, `Init`, `GetAttribute`, `GetAttributeChangedSignal`, `Wait`, `pcall`, `task`, `spawn`, `error`, `%*:Init() - %*`, `format`

### [853] ReplicatedStorage.Controllers.Trading.TradeTabController
`ModuleScript` · bytecode v9 · 30706 bytes · 379 constants
- **Remotes:** Data, Freeze, Set
- **Services:** Players, ReplicatedStorage, RunService, game, workspace
- **Key API:** Clone, Connect, Destroy, Disconnect, FindFirstChild, GetAttribute, GetChildren, GetService, InvokeServer, IsA, OnClientEvent, Once, Play, WaitForChild, new
- Constants: `InvokeServer`, `Misc`, `error`, `Play`, `type`, `string`, `warn`, `Request failed for %*:
%*`, `GetFullName`, `format`, `Request failed for %*:
no output`, `table`, `unpack`, `invokeServer`, `List`, `removeValue`, `FindItemsWithKey`, `LOCAL`, `Get`, `Remotes`, `AddItemToTrade`, `TradeLock`, `ActivationButton`, `Activated`, `Connect`, `Add`, `OnSlotCreated`, `Insert`, `TriggerUpdate`, `Remove`, `onChange`, ` %*`, `Checkmark`, `Visible`, `RemoveItemFromTrade`, `setPropertyComputed`, `find`, `TradableItemTypes`, `ItemTemplate`, `Container`, `Caller`, `SearchFilter`, `InventoryType`, `PageVisible`, `Computed`, `new`, `CreateInventory`, `OnChange`, `Dictionary`, `merge`, `SortMode`, `SortOption`, `None`, `State`, `Name`, `createInventory`, `FFlag`, `GetInstantFFlag`, `TradingEnabled`, `TradingSystemEnabled`, `Trading is currently disabled!`, `Client`, `Data`, `GetReplion`, `You are still loading!`, `TradeLockedUntil`, `workspace`, `GetServerTimeNow`, `TradeBanned`, `You are unable to trade!`, `You are unable to trade for %*`, `ValueConvertor`, `FormatShortTime`, `TotalStats.Wins`, `IsStudio`, `You can't trade before getting 1 Win!`, `__globalUpdatesInitialized`, `GetAttribute`, `DateTime`, `now`, `UnixTimestamp`, `JoinedTimestamp`, `LastSession`, `TradeJoinCooldown`, `You can't trade for %* seconds!`, `math`, `ceil`, `retryWithDelay`, `GetPolicyInfoForPlayerAsync`, `await`, `IsPaidItemTradingAllowed`, `You are restricted from trading due to Roblox policy!`, `CanTrade`, `UserId`, `tostring`, `Items`, `_IGNORE_ATTRIBUTES`, `ItemToKey`, `GetRAP`, `Tokens`, `GetTradeValue`, `CloseCurrent`, `Trade`, `Lock`, `Set`, `StartTrade`, `Unlock`, `Clear`, `[OnReplionAddedWithTag] There is a Trade running already`, `[OnReplionRemovedWithTag] Failed to clear Trade`, `Enabled`, `CancelTrade`, `rbxassetid://18123223527`, `rbxassetid://18123248161`, `Image`, `rbxassetid://18123872657`, `rbxassetid://18123874724`, `HoverImage`, `Label`, `UIStroke`, `Color3`, `fromRGB`, `Color`, `Left`, `Vector2`, `zero`, `CanvasPosition`, `Text`, `AddCommas`, `lower`, `match`, `^([%%d%%.]*)[%*]$`, `tonumber`, `gsub`, `%D+`, `min`, `max`, `clamp`, `AddTokensToTrade`, `Green`, `Active`, `rbxassetid://18123799353`, `rbxassetid://18123825435`, `Red`, `rbxassetid://18123810348`, `rbxassetid://18123830153`, `rbxassetid://18526787517`, `rbxassetid://18526787649`, `createButton`, `ClearItemsFromTrade`, `clearTrade`, `Amount`, `showUnfairTradeWarning`, `hideUnfairTradeWarning`, `ReadyUp`, `Ready`, `ConfirmTrade`, `TradeSettings`, `UnfairTradeWarning`, `Players`, `TimeoutFFlag`, `UnfairTradeWarningPercent`, `%*s`, `floor`, `Disabled`, `⌛ %*`, `Confirmed`, `Cancel`, `Unready`, `Confirm`, `Decline`, `TextEditable`, `UDim2`, `fromScale`, `Position`, `ConfirmedTime`, `ConfirmedCountdown`, `LastChange`, `ItemChangeCountdown`, `getCountdown`, `Disconnect`, `updateCountdown`, `RightChat`, `Frame`, `MiscChat`, `Parent`, `ChatList`, `updateChatMessages`, `Chat`, `Templates`, `Sender`, `Player1`, `Player2`, `FindFirstChild`, `Clone`, `Message`, `Time`, `LayoutOrder`, `%*-%*`, `createChatMessage`, `Instance`, `TextChatMessageProperties`, `TextSource`, `PrefixText`, `GetPlayerByUserId`, `[%*]`, `DisplayName`, `MessageId`, `%* %*`, `Timestamp`, `TradeChat`, `TextChannel`, `IsA`, `OnIncomingMessage`, `MessageReceived`, `Destroying`, `Once`, `PC`, `Phone`, `Tablet`, `Thread`, `SafeCancel`, `cancelCooldown`, `Text Channel not found! Please report to the devs!`, `task`, `delay`, `Cooldown`, `MaxMessageLength`, `Text too long (%*/%*)`, `MinMessageLength`, `Text too small (%*/%*)`, `os`, `clock`, `Please wait before sending another message`, `pcall`, `SendAsync`, `spawn`, `[TradeChat] - Failed to send message %*`, `sendText`, `SendNotification`, `Please wait before sending another message!`, `QuickMessages`, `Failed to find quick message!`, `SendChatMessage`, `Something went wrong!`, `sendQuickText`, `CaptureFocus`, `GetExpect`, `FakePlayer`, `GetPlayerStates`, `options`, `CanViewInventory`, `ViewInventory`, `IsOpen`, `Open`, `concat`, `shift`, `ModifyPath`, `pairs`, `Destroy`, `clear`, `Sword`, `getReplionPathState`, `TradeId`, `Processing`, `CanChat`, `Right`, `Top`, `ProfilePicture`, `Headshot`, `rbxthumb://type=AvatarHeadShot&id=%*&w=100&h=100`, `ReadyOverlay`, `ConfirmedOverlay`, `Labels`, `PlayerName`, `%*'s Value:`, `TokenOffer`, `Title`, `Chat with %*`, `rbxassetid://18860669626`, `rbxassetid://18711611169`, `rbxassetid://18860669386`, `rbxassetid://18711662604`, `EnterAmount`, `Type`, `FakeCaller`, `CustomType`, `Trading`, `Replion`, `PostSimulation`, `Processing Trade`, `Countdown starts when both players confirm`, `WaitReplion`, `Inventory`, `OnReplionAddedWithTag`, `OnReplionRemovedWithTag`, `GetPropertyChangedSignal`, `SideButtons`, `GetChildren`, `ImageButton`, `Currency`, `Coins`, `k`, `m`, `b`, `t`, `FocusLost`, `Close`, `Buttons`, `No`, `Yes`, `ChildAdded`, `ReceiveChatMessage`, `OnClientEvent`, `getPropertyState`, `Black`, `ZIndex`, `Size`, `UIGridLayout`, `CellSize`, `ChatButton`, `EnterText`, `SendButton`, `QuickWords`, `QuickMessageTemplate`, `Message_%*`, `"%*"`, `ItemSearch`, `Search`, `Start`, `require`, `game`, `GetService`, `LocalPlayer`, `PlayerScripts`, `WaitForChild`, `ClientLoader`, `ControllerIsolator`, `CreateRequire`, `script`, `ReplicatedStorage`, `TextChatService`, `PolicyService`, `RunService`, `Packages`, `Freeze`, `Trove`, `Net`, `Shared`, `Statable`, `TradeInfo`, `Common`, `MarketplaceService`, `ClientGameModules`, `GuiHandler`, `Utils`, `DeviceListener`, `Controllers`, `UI`, `ShopControllerAPI`, `ItemInfo`, `Promise`, `FFlagClient`, `InventoryTypes`, `RAPController`, `HoverInfoController`, `InventoryController`, `TradeRequestController`, `ViewInventoryController`, `NotificationController`, `FrameCap`, `PlayerGui`, `Main`, `Bottom`, `Accept`, `SearchBox`, `Template`, `TradeReplionState`

### [854] ReplicatedStorage.Controllers.Trading.TradeTokensController
`ModuleScript` · bytecode v9 · 7376 bytes · 124 constants
- **Services:** Players, ReplicatedStorage, game
- **Key API:** Clone, Connect, Destroy, GetService, InvokeServer, Once, Play, WaitForChild
- Constants: `Enum`, `InfoType`, `GamePass`, `PromptGamePassPurchase`, `Product`, `PromptProductPurchase`, `promptPurchase`, `tonumber`, `_currentProductId`, `_currentProductInfoType`, `_isLoading`, `TradingTokensEnabled`, `GetKey`, `GetServerProductInfo`, `timeout`, `await`, `GetProductInfoAsync`, `Tokens`, `Get`, `UserBasePriceInRobux`, `canBePurchasedWithTokens`, `Frame`, `Buttons`, `BuyRobux`, `Label`, `Buy With %* Robux`, `ValueConvertor`, `PriceInRobux`, `AddCommas`, `format`, `Text`, `BuyToken`, `Amount`, `%* Tokens`, `Enabled`, `PromptPurchase`, `List`, `cancel`, `task`, `spawn`, `_currentConfirmationPrompt`, `Destroy`, `onClick`, `TradingEnabled`, `Tokens disabled!`, `Processing other purchase!`, `<stroke color="#081749">Buy "<font color="#78ff62">%*</font>" for</stroke>`, `Name`, `Clone`, `Visible`, `ProductId`, `???`, `andThen`, `Destroying`, `Once`, `Price`, `ItemInfo`, `ItemName`, `Vector`, `rbxasset://textures/ui/GuiImagePlaceholder.png`, `Icon`, `Image`, `ItemKey`, `Type`, `Add`, `Cancel`, `Activated`, `Connect`, `Sell`, `Close`, `Parent`, `PromptConfirmation`, `Remotes`, `PurchaseProductWithTokens`, `productId`, `type`, `InvokeServer`, `Misc`, `error`, `Play`, `_G`, `SendNotification`, `reward`, `updateTokens`, `Client`, `Inventory`, `WaitReplion`, `OnChange`, `PromptTokenPurchase`, `Start`, `require`, `game`, `Players`, `GetService`, `LocalPlayer`, `PlayerScripts`, `WaitForChild`, `ClientLoader`, `ControllerIsolator`, `CreateRequire`, `script`, `ReplicatedStorage`, `Packages`, `Replion`, `Net`, `Shared`, `Statable`, `Common`, `MarketplaceService`, `Trading`, `TradeInfo`, `TradeTokensUtils`, `ClientGameModules`, `FFlagClient`, `Controllers`, `HoverInfoController`, `Utils`, `Assets`, `UI`, `Trade`, `ConfirmationPrompt`, `PlayerGui`, `PopUpTokensBuy`, `TokensPromptConfirmation`

### [855] ReplicatedStorage.Controllers.Trading.TradeTokensController.TradeTokensController
`Script` · bytecode v9 · 787 bytes · 19 constants
- **Key API:** GetAttribute, SetAttribute
- Constants: `debug`, `setmemorycategory`, `Name`, `Start`, `script`, `Parent`, `require`, `Loaded`, `SetAttribute`, `Init`, `GetAttribute`, `GetAttributeChangedSignal`, `Wait`, `pcall`, `task`, `spawn`, `error`, `%*:Init() - %*`, `format`

### [856] ReplicatedStorage.Controllers.Trading.TradingSignController
`ModuleScript` · bytecode v9 · 4445 bytes · 108 constants
- **Remotes:** Data, Update
- **Services:** Players, ReplicatedStorage, RunService, UserInputService, game, workspace
- **Key API:** Clone, Connect, Destroy, FireServer, GetAttribute, GetService, LoadAnimation, Play, SetAttribute, Stop, WaitForChild, new
- Constants: `Data`, `GetReplion`, `Hotbar`, `WaitForChild`, `ToggleTradingSign`, `GamePasses`, `TradingSign`, `Find`, `Visible`, `Update`, `HasBooth`, `GetAttribute`, `Claim a booth first!`, `SendNotification`, `FireServer`, `Toggle`, `IsTenFootInterface`, `Ability`, `GetBinds`, `KeyCode`, `Enum`, `One`, `Name`, `Bind1`, `UserInputType`, `Bind2`, `AmountSoldGui`, `Frame`, `List`, `Amount`, `ValueConvertor`, `AddCommas`, `Text`, `CanvasGroup`, `GroupTransparency`, `Destroy`, `Stop`, `Assets`, `Clone`, `Right Arm`, `Instance`, `new`, `RigidConstraint`, `RightGripAttachment`, `Attachment0`, `PrimaryPart`, `Attachment`, `Attachment1`, `Parent`, `workspace`, `Runtime`, `Gui`, `SurfaceGui`, `Adornee`, `ScrollingFrame`, `MaxListingItems`, `SetAttribute`, `ListingsUI_%*`, `UserId`, `format`, `AddTag`, `Animator`, `FindFirstChildWhichIsA`, `LoadAnimation`, `Play`, `observeAttribute`, `BoothEarnedTokens`, `TradingSignEquipped`, `WaitReplion`, `OnChange`, `Button`, `Activated`, `Connect`, `InputBegan`, `observeCharacters`, `Start`, `require`, `game`, `Players`, `GetService`, `LocalPlayer`, `PlayerScripts`, `ClientLoader`, `ControllerIsolator`, `CreateRequire`, `script`, `ReplicatedStorage`, `ServerInfo`, `isTradingPlazaServer`, `GuiService`, `RunService`, `ServerScriptService`, `UserInputService`, `Packages`, `Net`, `Replion`, `Client`, `Common`, `Utils`, `Observers`, `MarketplaceService`, `Controllers`, `SettingsController`, `NotificationController`, `TradingSign/Toggle`, `RemoteEvent`, `PlayerGui`, `TradeSignAnim`

### [857] ReplicatedStorage.Controllers.TrainingModeController
`ModuleScript` · bytecode v9 · 14400 bytes · 203 constants
- **Services:** Players, ReplicatedStorage, UserInputService, game
- **Key API:** Clone, Connect, Destroy, Disconnect, FindFirstChild, Fire, FireServer, GetChildren, GetService, IsA, SetAttribute, WaitForChild, new
- Constants: `mapN`, `CheckIcon`, `Visible`, `updateVisual`, `FireServer`, `observeReplionPath`, `Activated`, `Connect`, `registerCheckbox`, `Enabled`, `MapSelectionEnded`, `Wait`, `PromptMapSelection`, `TrainingModeServerPanel`, `Close`, `IsOpen`, `Open`, `Fire`, `IntValue`, `IsA`, `Name`, `serverOwner`, `task`, `wait`, `Active`, `delay`, `ServerSelection`, `Difficulties`, `GetChildren`, `ImageTransparency`, `updateDifficultyVisual`, `Difficulty`, `Counter`, `Count`, `%*/%*`, `format`, `Text`, `Cursor`, `UDim2`, `fromScale`, `Position`, `updateCounterVisual`, `GetMouseLocation`, `X`, `AbsolutePosition`, `AbsoluteSize`, `math`, `round`, `clamp`, `abs`, `updateCounter`, `UserInputType`, `Enum`, `MouseMovement`, `Touch`, `InputChanged`, `MouseButton1`, `Disconnect`, `NumberOfBots`, `changeBotAmount`, `Device`, `Console`, `reflectLatestInputMode`, `Modes`, `updateGameModeVisual`, `Custom`, `ChangeRules`, `CleanRules`, `GameMode`, `TrainingMode`, `MapFrame`, `Map`, `Thumbnail`, `Image`, `Label`, `DisplayName`, `updateMapVisual`, `Toggle`, `rbxassetid://16789391160`, `Remove`, `Color3`, `fromRGB`, `TextStrokeColor3`, `Size`, `Parent`, `rbxassetid://16789408068`, `Add`, `Destroy`, `Clone`, `AvatarFrame`, `rbxthumb://type=AvatarHeadShot&id=%*&w=150&h=150`, `UserId`, `!%*`, `Username`, `@%*`, `observeAttribute`, `InRoundQueue`, `Reset`, `Controllers`, `CustomModeRulesController`, `GuiUtils`, `getActivatedSignal`, `onPermissionsChanged`, `ServerInfo`, `FindFirstChild`, `Value`, `GetPropertyChangedSignal`, `ChildAdded`, `MouseButton1Down`, `InputEnded`, `BotIncrease`, `BotDecrease`, `Observe`, `Respawn`, `CheckFrame`, `BotsMove`, `Move`, `CloseButton`, `DisabledInTraining`, `Assets`, `MapTemplate`, `HoverImage`, `Title`, `Maps`, `Container`, `ChangeMap`, `ChangeAbilitiesMiddleRound`, `Abilitymidround`, `AutoStart`, `StartRound`, `EndRound`, `Players`, `observePlayer`, `observeClientReplion`, `TrainingConfiguration`, `Start`, `isTrainingServer`, `game`, `PrivateServerId`, `PrivateServerOwnerId`, `HasEditPermissions`, `TouchEnabled`, `KeyboardEnabled`, `GamepadEnabled`, `IsTenFootInterface`, `AnchorPoint`, `Vector2`, `new`, `updateSettingsButton`, `ServerAdminAccess`, `SetAttribute`, `isDungeonsLobbyServer`, `isDungeonsMatchServer`, `isTradingPlazaServer`, `require`, `GetService`, `LocalPlayer`, `PlayerScripts`, `WaitForChild`, `ClientLoader`, `ControllerIsolator`, `CreateRequire`, `script`, `GuiService`, `ReplicatedStorage`, `UserInputService`, `Shared`, `ReplionUtils`, `MapData`, `Packages`, `Signal`, `Common`, `Utils`, `Net`, `ClientGameModules`, `GuiHandler`, `Observers`, `DeviceListener`, `UpdateTrainingConfiguration`, `RemoteEvent`, `CustomModeStartMatch`, `CustomModeEndMatch`, `CustomModeResetPlayer`, `CustomModeTogglePlayer`, `PlayerGui`, `HUD`, `LeftFrame`, `ClanButton`, `SettingsButton`, `BackButton`, `AFK`, `HelpGuidePage`, `CustomModeUI`, `Frame`, `Bots`, `Game`, `Server`, `PlayerPanel`, `NotPlaying`, `Playing`, `PlayerTemplate`, `MapSelector`

### [858] ReplicatedStorage.Controllers.Tutorial.TutorialController
`ModuleScript` · bytecode v9 · 20402 bytes · 255 constants
- **Services:** Players, ReplicatedStorage, RunService, StarterGui, TweenService, UserInputService, game, workspace
- **Key API:** Clone, Connect, Create, Destroy, Disconnect, FindFirstChild, FireServer, GetAttribute, GetChildren, GetService, InvokeServer, IsA, LoadAnimation, Play, Stop, WaitForChild, new
- Constants: `Instance`, `new`, `ImageLabel`, `Image`, `script`, `Parent`, `pcall`, `PreloadAsync`, `Destroy`, `preloadImage`, `Enum`, `AssetFetchStatus`, `Success`, `%*Color`, `format`, `Disconnect`, `FindFirstChildOfClass`, `%*Template`, `GetAssetFetchStatus`, `warn`, `Default clothing has not yet been loaded, changing the character's BodyColors instead`, `BodyColors`, `FindFirstChildWhichIsA`, `Torso`, `LeftLeg`, `RightLeg`, `BrickColor`, `Really black`, `GetAssetFetchStatusChangedSignal`, `Connect`, `Add`, `createDefaultClothing`, `AttachToInstance`, `Shirt`, `Pants`, `pairs`, `tonumber`, `Failed to find %* Instance %* when applying HumanoidDescription '%*' - applying default`, `Name`, `string`, `match`, `%d+`, `Failed to set texture for %* %* when applying HumanoidDescription '%*' - applying default`, `http://www.roblox.com/asset/?id=%*`, `Failure`, `TimedOut`, `Failed to fetch texture %* for %* %* when applying HumanoidDescription '%*' - applying default`, `None`, `task`, `spawn`, `Loading`, `validateClothing`, `hidePlayerListOnJoin`, `Init`, `Animation`, `AnimationId`, `createAnimation`, `Time`, `Center`, `ImageTransparency`, `fastTween`, `GetChildren`, `Frame`, `IsA`, `BackgroundTransparency`, `tweenToTransparency`, `workspace`, `Balls`, `GetPivot`, `Position`, `WorldToViewportPoint`, `UDim2`, `fromOffset`, `X`, `Y`, `Z`, `math`, `clamp`, `fromScale`, `Size`, `os`, `clock`, `Character`, `CFrame`, `identity`, `lookAt`, `Lerp`, `CameraType`, `Custom`, `Enabled`, `wait`, `Scriptable`, `TextLabel`, `<stroke color="rgb(0,0,0)" joins="round" thickness="2">%* ON THE <font color="rgb(118, 189, 255)">SCREEN</font> TO BLOCK THE BALL<font color="rgb(255, 58, 58)"></font> <font color="rgb(255, 58, 58)"></font></stroke>`, `TouchEnabled`, `TAP`, `CLICK`, `Text`, `PostSimulation`, `FireServer`, `MainFrame`, `FadeTitle`, `Title`, `<stroke color="rgb(2, 75, 0)" joins="round" thickness="4">%*<font color="rgb(255, 58, 58)"></font></stroke>`, `Black`, `TweenInfo`, `EasingStyle`, `Linear`, `Create`, `PlayButton`, `Quart`, `CoreGuiType`, `Chat`, `PlayerList`, `GetPropertyChangedSignal`, `Play`, `Completed`, `Wait`, `delay`, `Show`, `setShow`, `Hide`, `setHide`, `GetServerTimeNow`, `table`, `clone`, `Count`, `NextInteger`, `insert`, `Random`, `generateNewPositions`, `NextUnitVector`, `Margin`, `NextNumber`, `getFinalPosition`, `GetHumanoidDescriptionFromUserIdAsync`, `tostring`, `FindFirstChild`, `HumanoidDescription`, `WaitForChild`, `getHumanoidDescription`, `WalkToPoint`, `Magnitude`, `GetState`, `HumanoidStateType`, `Stop`, `IsPlaying`, `Jump`, `Emoter`, `AFK`, `Wanderer`, `Part`, `MoveTo`, `Jumpy`, `MoveToFinished`, `RandomUserHumanoidDescriptions`, `Id`, `ApplyDescriptionAsync`, `Model`, `Bot`, `Clone`, `Pivot`, `SpawnLocation`, `random`, `GetExtentsSize`, `PivotTo`, `Dead`, `Base Sword`, `Sword`, `EquipSwordTo`, `Humanoid`, `GetAppliedDescription`, `Animator`, `rbxassetid://180435571`, `LoadAnimation`, `rbxassetid://13772440420`, `rbxassetid://13772468608`, `rbxassetid://125750702`, `rbxassetid://14351095988`, `rbxassetid://14351086764`, `GetHumanoidDisplayName`, `DisplayName`, `HumanoidDisplayDistanceType`, `Viewer`, `DisplayDistanceType`, `createBot`, `InvokeServer`, `GameActive`, `GetAttribute`, `clear`, `AB_IsOneBotTutorial`, `onGameStateChange`, `RespawnTime`, `Sine`, `EasingDirection`, `Out`, `ShowParryTutorial`, `TutorialCompleted`, `UpdateCoreGuiState`, `MouseButton1Click`, `isTutorialServer`, `isNewPlayerLobbyServer`, `Spawn`, `TutorialBotPositions`, `ExplosionCrate`, `SwordCrate`, `Wheel`, `LobbyWall`, `LobbyWall2`, `WanderPoint%*`, `TutorialBotDied`, `GetAttributeChangedSignal`, `Start`, `require`, `game`, `Players`, `GetService`, `LocalPlayer`, `PlayerScripts`, `ClientLoader`, `ControllerIsolator`, `CreateRequire`, `ReplicatedStorage`, `UserInputService`, `ContentProvider`, `TweenService`, `StarterGui`, `RunService`, `Packages`, `Net`, `Trove`, `ServerInfo`, `Common`, `Utils`, `Shared`, `FastUtils`, `UseNewLobby`, `PlayerNameUtility`, `ClientGameModules`, `CoreCall`, `ReplicatedInstances`, `Swords`, `PlayerGui`, `TutorialWon`, `ParryTutorialUI`, `TutorialGetRandomUsers`, `RemoteFunction`, `TutorialTeleport`, `RemoteEvent`, `Assets`, `HumanoidDescriptionCache`, `Tutorial`, `CurrentCamera`, `http://www.roblox.com/asset/?id=607785311`, `http://www.roblox.com/asset/?id=382538502`

### [859] ReplicatedStorage.Controllers.Tutorial.TutorialController.TutorialController
`Script` · bytecode v9 · 787 bytes · 19 constants
- **Key API:** GetAttribute, SetAttribute
- Constants: `debug`, `setmemorycategory`, `Name`, `Start`, `script`, `Parent`, `require`, `Loaded`, `SetAttribute`, `Init`, `GetAttribute`, `GetAttributeChangedSignal`, `Wait`, `pcall`, `task`, `spawn`, `error`, `%*:Init() - %*`, `format`

### [860] ReplicatedStorage.Controllers.Tutorial.TutorialSkipPromptController
`ModuleScript` · bytecode v9 · 4204 bytes · 85 constants
- **Remotes:** ChangedAfkMode
- **Services:** Players, ReplicatedStorage, TweenService, game
- **Key API:** Connect, Create, Disconnect, FireServer, GetService, OnClientEvent, Play, WaitForChild, new
- Constants: `Name`, `IsOpen`, `Unlock`, `Close`, `Connected`, `Disconnect`, `Remotes`, `ChangedAfkMode`, `FireServer`, `exit`, `Play`, `Active`, `Black`, `BackgroundTransparency`, `Title`, `UDim2`, `fromScale`, `Position`, `TextGlow`, `ImageTransparency`, `Label`, `TextTransparency`, `UIStroke`, `Transparency`, `TweenInfo`, `new`, `Enum`, `EasingStyle`, `Quint`, `EasingDirection`, `Out`, `Create`, `task`, `wait`, `Quad`, `delay`, `tweenIn`, `os`, `clock`, `math`, `max`, `Timer`, `%*s`, `ceil`, `format`, `Text`, `Open`, `Lock`, `Thread`, `Every`, `show`, `Main`, `Buttons`, `Lose`, `Activated`, `Connect`, `OnClientEvent`, `Start`, `require`, `game`, `Players`, `GetService`, `LocalPlayer`, `PlayerScripts`, `WaitForChild`, `ClientLoader`, `ControllerIsolator`, `CreateRequire`, `script`, `ReplicatedStorage`, `TweenService`, `Packages`, `Replion`, `Net`, `Common`, `Utils`, `ClientGameModules`, `GuiHandler`, `Shared`, `FastUtils`, `PlayerGui`, `TutorialSkipPrompt`, `TutorialTeleport`, `RemoteEvent`, `ShowTutorialSkipPrompt`

### [861] ReplicatedStorage.Controllers.UI.AFKController
`ModuleScript` · bytecode v9 · 25490 bytes · 304 constants
- **Remotes:** Data
- **Services:** Debris, HttpService, Players, ReplicatedStorage, RunService, TweenService, UserInputService, Workspace, game, workspace
- **Key API:** Clone, Connect, Create, Destroy, FireServer, GetAttribute, GetChildren, GetPlayers, GetService, IsA, OnClientEvent, Play, SetAttribute, WaitForChild, new
- Constants: `Humanoid`, `WaitForChild`, `charAdded`, `os`, `clock`, `FireServer`, `Clean`, `Heartbeat`, `Connect`, `Add`, `idle`, `GetKeysPressed`, `Enum`, `HumanoidStateType`, `Jumping`, `ChangeState`, `_idleTrove`, `CharacterAdded`, `Character`, `task`, `spawn`, `IsHost`, `GetAttribute`, `Extend`, `WindowFocusReleased`, `InputBegan`, `InputEnded`, `Idled`, `_trackIdle`, `Instance`, `new`, `Sound`, `game`, `Workspace`, `Parent`, `Volume`, `wait`, `TimePosition`, `math`, `random`, `rbxassetid://`, `tostring`, `SoundId`, `PlaybackSpeed`, `Play`, `Ended`, `Wait`, `MusicHandler`, `Invite`, `@%* Invited You to AFK World!`, `format`, `Text`, `Enabled`, `Visible`, `@[Loading] Invited You to AFK World!`, `GetUsername`, `andThen`, `processInvite`, `AFKBackgroundMusic`, `GetKey`, `setTopbarEnabled`, `All luck boost multipliers stack together!`, `You will automatically rejoin, no need for a macro!`, `Buy Premium to get better rewards!`, `workspace`, `GetServerTimeNow`, `AFKWorldLuckEndTime`, `🍀 Note: Global 2x luck boost is currently active! 🍀`, `Color3`, `fromRGB`, `TextColor3`, `Note: `, `Name`, `AFKWorld`, `InviteRewards`, `AFK`, `Open`, `_currentGui`, `Unlock`, `RarityColors`, `Rarity`, `Color`, `StrokeColor`, `Secret`, `Clone`, `Emote`, `TextLabel`, `<stroke color="#%*" joins="round" thickness="2"><font color="#%*">%*</font><font color="#%*">(1 in %*)</font></stroke>`, `ToHex`, `EmoteName`, `ValueConvertor`, `Chance`, `NothingChance`, `AddCommas`, `Right`, `Main`, `ScrollList`, `ScrollingFrame`, `Frame`, `table`, `insert`, `Destroy`, `remove`, `LayoutOrder`, `addToHistory`, `List`, `FindItems`, `Owned`, `%*/%* OWNED (<font color="rgb(44, 239, 41)">%*%%</font>)`, `floor`, `updateOwned`, `BestFinds`, `Get`, `UDim2`, `fromScale`, `Position`, `Size`, `Title`, `<stroke color="#22377f" joins="round" thickness="2.5"><font color="#ff3838">Best</font><font color="#ffffff"> Finds</font></stroke>`, `pairs`, `GetChildren`, `isA`, `sort`, `updateBestFinds`, `findEmote`, `Equipped`, `SetAttribute`, `Try`, `Label`, `showEquippedEmote`, `Info`, `SetEmote`, `Activated`, `ChildAdded`, `Nothing`, `UIStroke`, `<stroke color="rgb(0,0,0)" joins="round" thickness="2"><font color="rgb(44, 239, 41)">1</font> in <font color="rgb(44, 239, 41)">%*</font></stroke>`, `TweenInfo`, `max`, `EasingStyle`, `Sine`, `EasingDirection`, `Out`, `Create`, `Center`, `Bottom`, `renderText`, `LuckRoll`, `Legendary`, `getPicker`, `AddItem`, `delay`, `Effect`, `AFKCoinDuration`, `AFKStarDuration`, `AFKSpinDuration`, `%02d:%02d to next reward`, `Cancel`, `Fill`, `Linear`, `clamp`, `JoinTime`, `Time`, `AFKCoinsEarned`, `earnedCredits`, `Desc1`, `AFKStarsEarned`, `earnedStars`, `PromptPremiumPurchase`, `pcall`, `RNGLuckTime`, `Left`, `Ends In: %*`, `FormatTimeWithDays`, `updateLuckTime`, `InfoType`, `Product`, `PromptPurchase`, `Default`, `CanSendGameInviteAsync`, `GetPlayers`, `min`, `string`, `+%d%%`, `updateFriendLuck`, `Type`, `PromptFriendInvite`, `CanInvite`, `PlayerAdded`, `PlayerRemoving`, `isAFKServer`, `PromptAFKInvite`, `RemoteEvent`, `ReadyButton`, `DeclineButton`, `OnClientEvent`, `Client`, `Data`, `WaitReplion`, `Earn Coins & %*
 Roll for Emotes`, `SeasonData`, `Currency`, `OnOpen`, `%* Earned: `, `Stars`, `Amount`, `2x %*`, `ScreenGui`, `IsA`, `TeleportUI`, `PopUpTokensBuy`, `GetPropertyChangedSignal`, `DisplayOrder`, `updateMembershipUI`, `Emotes.Unlocked`, `OnChange`, `GetAttributeChangedSignal`, `Buy`, `BuyList`, `Buy1`, `DevProduct`, `%s`, `Buy3`, `Buy10`, `MembershipType`, `Start`, `Premium`, `isPremium`, `PerMinute`, `+2`, `+4`, `+1`, `PremiumSupporter`, `require`, `Players`, `GetService`, `LocalPlayer`, `PlayerScripts`, `ClientLoader`, `ControllerIsolator`, `CreateRequire`, `script`, `ReplicatedStorage`, `TweenService`, `Debris`, `HttpService`, `SocialService`, `UserInputService`, `RunService`, `PlayerGui`, `Packages`, `Net`, `Signal`, `Replion`, `Common`, `MarketplaceService`, `ClientGameModules`, `FFlagClient`, `Trove`, `Utils`, `Shared`, `RNG`, `Emotes`, `PlaytimeLuck`, `ServerInfo`, `GuiHandler`, `CreatePriceLabel`, `Controllers`, `ShowRoomController`, `Icon`, `UI`, `InviteRewardsController`, `PlayerUtility`, `Inventory`, `Trading`, `TradeTokensController`, `@game/ReplicatedStorage/Shared/InfiniteBattlepass/InfiniteBattlepassData`, `TimeIncremented`, `SpinAnimation`, `SetSpinHistory`, `PlayerSpawned`, `PlaceTeleport`, `AFKInvite`, `Holder`, `Effects`, `Tier5.story`, `Tier4.story`, `Tier3.story`, `Tier2.story`, `Tier1.story`, `CoinsEarned`, `StarsEarned`, `ProgressBar`, `Note`, `PremiumRewards`, `BackToGame`, `ExtraLuck`, `FriendBoost`, `rbxassetid://16759110468`, `rbxassetid://16759476678`, `Template`, `CurrentCamera`, `AFKRejoin`

### [862] ReplicatedStorage.Controllers.UI.AFKController.Effects.Tier1.story
`ModuleScript` · bytecode v9 · 501 bytes · 13 constants
- **Services:** ReplicatedStorage, game
- **Key API:** GetService, new
- Constants: `Clean`, `new`, `fastAudio`, `rbxassetid://7254180774`, `Add`, `game`, `ReplicatedStorage`, `GetService`, `require`, `Packages`, `Trove`, `Shared`, `FastUtils`

### [863] ReplicatedStorage.Controllers.UI.AFKController.Effects.Tier2.story
`ModuleScript` · bytecode v9 · 870 bytes · 24 constants
- **Services:** ReplicatedStorage, game
- **Key API:** GetService, new
- Constants: `Clean`, `new`, `fastAudio`, `rbxassetid://16757430922`, `Add`, `Instance`, `Frame`, `Color3`, `BackgroundColor3`, `BackgroundTransparency`, `UDim2`, `fromScale`, `Size`, `Parent`, `fastTween`, `TweenInfo`, `game`, `ReplicatedStorage`, `GetService`, `require`, `Packages`, `Trove`, `Shared`, `FastUtils`

### [864] ReplicatedStorage.Controllers.UI.AFKController.Effects.Tier3.story
`ModuleScript` · bytecode v9 · 2371 bytes · 48 constants
- **Services:** ReplicatedStorage, game
- **Key API:** GetService, new
- Constants: `Clean`, `new`, `Instance`, `Frame`, `Add`, `Color3`, `BackgroundColor3`, `BackgroundTransparency`, `UDim2`, `fromScale`, `Size`, `ZIndex`, `Parent`, `ImageLabel`, `Vector2`, `AnchorPoint`, `Position`, `rbxassetid://16745733577`, `Image`, `Enum`, `ScaleType`, `Fit`, `ImageTransparency`, `fastAudio`, `rbxassetid://16757431504`, `fastTween`, `TweenInfo`, `task`, `wait`, `EasingStyle`, `Exponential`, `EasingDirection`, `In`, `Rotation`, `Completed`, `Wait`, `Sine`, `InOut`, `fromRGB`, `delay`, `game`, `ReplicatedStorage`, `GetService`, `require`, `Packages`, `Trove`, `Shared`, `FastUtils`

### [865] ReplicatedStorage.Controllers.UI.AFKController.Effects.Tier4.story
`ModuleScript` · bytecode v9 · 3615 bytes · 58 constants
- **Services:** ReplicatedStorage, game
- **Key API:** Destroy, GetService, new
- Constants: `Vector2`, `zero`, `UDim2`, `fromScale`, `math`, `random`, `Position`, `createStar`, `Destroy`, `Clean`, `new`, `fastAudio`, `rbxassetid://16757431297`, `Add`, `Instance`, `Frame`, `Color3`, `BackgroundColor3`, `BackgroundTransparency`, `Size`, `ZIndex`, `Parent`, `ImageLabel`, `AnchorPoint`, `rbxassetid://16746234145`, `Image`, `Enum`, `ScaleType`, `Crop`, `ImageTransparency`, `fastTween`, `TweenInfo`, `EasingStyle`, `Sine`, `EasingDirection`, `InOut`, `rbxassetid://16661396780`, `Fit`, `Rotation`, `rbxassetid://16745821408`, `task`, `delay`, `wait`, `Exponential`, `In`, `Completed`, `Wait`, `fromRGB`, `game`, `ReplicatedStorage`, `GetService`, `require`, `Packages`, `Trove`, `Shared`, `FastUtils`, `Starry.story`, `script`

### [866] ReplicatedStorage.Controllers.UI.AFKController.Effects.Tier4.story.Starry.story
`ModuleScript` · bytecode v9 · 3764 bytes · 73 constants
- **Services:** ReplicatedStorage, SoundService, TweenService, UserInputService, game
- **Key API:** Clone, Create, Destroy, GetService, Once, Play, WaitForChild, new
- Constants: `Destroy`, `Create`, `Play`, `Completed`, `Once`, `fastTween`, `Instance`, `new`, `Sound`, `SoundId`, `Parent`, `NextNumber`, `Volume`, `PlaybackSpeed`, `Ended`, `fastAudio`, `ScreenGui`, `FindFirstAncestorWhichIsA`, `task`, `wait`, `UDim2`, `fromOffset`, `Size`, `math`, `random`, `AbsoluteSize`, `X`, `Y`, `Position`, `Rotation`, `ImageTransparency`, `Label`, `AngularTween`, `FadeTween`, `SizeTween`, `table`, `insert`, `remove`, `Clone`, `Color`, `ImageColor3`, `TweenInfo`, `Time`, `Enum`, `EasingStyle`, `Linear`, `EasingDirection`, `Out`, `spawn`, `delay`, `createStar`, `game`, `ReplicatedStorage`, `GetService`, `SoundService`, `require`, `UserInputService`, `WaitForChild`, `TweenService`, `Sine`, `In`, `Random`, `Color3`, `rbxassetid://9126076151`, `rbxassetid://9126072436`, `ImageLabel`, `Active`, `BackgroundTransparency`, `BorderSizePixel`, `Vector2`, `AnchorPoint`, `rbxassetid://15897574705`, `Image`

### [867] ReplicatedStorage.Controllers.UI.AFKController.Effects.Tier5.story
`ModuleScript` · bytecode v9 · 4365 bytes · 61 constants
- **Services:** ReplicatedStorage, game
- **Key API:** Destroy, GetService, Once, new
- Constants: `Vector2`, `zero`, `UDim2`, `fromScale`, `math`, `random`, `Position`, `createStar`, `Destroy`, `Clean`, `new`, `fastAudio`, `rbxassetid://16757431094`, `Add`, `Instance`, `Frame`, `Color3`, `BackgroundColor3`, `BackgroundTransparency`, `Size`, `ZIndex`, `Parent`, `ImageLabel`, `AnchorPoint`, `rbxassetid://16745821408`, `Image`, `Enum`, `ScaleType`, `Fit`, `fastTween`, `TweenInfo`, `task`, `wait`, `EasingStyle`, `Sine`, `EasingDirection`, `InOut`, `ImageTransparency`, `fromRGB`, `rbxassetid://16746041143`, `ImageColor3`, `rbxassetid://16746234145`, `Crop`, `Rotation`, `rbxassetid://15219972940`, `Linear`, `Out`, `Completed`, `Once`, `delay`, `Volume`, `game`, `ReplicatedStorage`, `GetService`, `require`, `Packages`, `Trove`, `Shared`, `FastUtils`, `Starry.story`, `script`

### [868] ReplicatedStorage.Controllers.UI.AFKController.Effects.Tier5.story.Starry.story
`ModuleScript` · bytecode v9 · 3764 bytes · 73 constants
- **Services:** ReplicatedStorage, SoundService, TweenService, UserInputService, game
- **Key API:** Clone, Create, Destroy, GetService, Once, Play, WaitForChild, new
- Constants: `Destroy`, `Create`, `Play`, `Completed`, `Once`, `fastTween`, `Instance`, `new`, `Sound`, `SoundId`, `Parent`, `NextNumber`, `Volume`, `PlaybackSpeed`, `Ended`, `fastAudio`, `ScreenGui`, `FindFirstAncestorWhichIsA`, `task`, `wait`, `UDim2`, `fromOffset`, `Size`, `math`, `random`, `AbsoluteSize`, `X`, `Y`, `Position`, `Rotation`, `ImageTransparency`, `Label`, `AngularTween`, `FadeTween`, `SizeTween`, `table`, `insert`, `remove`, `Clone`, `Color`, `ImageColor3`, `TweenInfo`, `Time`, `Enum`, `EasingStyle`, `Linear`, `EasingDirection`, `Out`, `spawn`, `delay`, `createStar`, `game`, `ReplicatedStorage`, `GetService`, `SoundService`, `require`, `UserInputService`, `WaitForChild`, `TweenService`, `Sine`, `In`, `Random`, `Color3`, `rbxassetid://9126076151`, `rbxassetid://9126072436`, `ImageLabel`, `Active`, `BackgroundTransparency`, `BorderSizePixel`, `Vector2`, `AnchorPoint`, `rbxassetid://15897574705`, `Image`

### [869] ReplicatedStorage.Controllers.UI.AbilityBanVotingController
`ModuleScript` · bytecode v9 · 6301 bytes · 128 constants
- **Remotes:** Data
- **Services:** Players, ReplicatedStorage, game, workspace
- **Key API:** Clone, Connect, Destroy, Disconnect, FindFirstChild, FireServer, GetAttribute, GetChildren, GetService, IsA, OnClientEvent, WaitForChild
- Constants: `Client`, `AbilityBanVoting`, `GetReplion`, `VoteStartTime`, `Get`, `workspace`, `GetServerTimeNow`, `math`, `round`, `max`, `Title`, `string`, `format`, `Vote for an ability to ban (%ss)`, `tostring`, `Text`, `_timerThread`, `Connected`, `Disconnect`, `Open`, `Every`, `_updateVoting`, `Name`, `ScrollingFrame`, `GetChildren`, `GuiObject`, `IsA`, `VoteCount`, `Votes: %*`, `SelectedOverlay`, `table`, `find`, `Visible`, `_updateVoteCount`, `WaitReplion`, `BannedAbilities`, `Find`, `DisabledOverlay`, `Active`, `Selectable`, `_updateBannedAbilities`, `os`, `clock`, `FireServer`, `UDim2`, `fromOffset`, `UIGridLayout`, `AbsoluteContentSize`, `Y`, `CanvasSize`, `updateCanvas`, `Template`, `Destroy`, `Clone`, `Order`, `GetAttribute`, `LayoutOrder`, `Vector`, `Icon`, `Image`, `Votes: 0`, `Activated`, `Connect`, `Parent`, `task`, `wait`, `GetPropertyChangedSignal`, `_createAbilityFrames`, `IsOpen`, `Lock`, `Unlock`, `Close`, `Ability`, `GoTo`, `_openShop`, `Data`, `GetEquipped`, `Dash`, `_updateItemStatus`, `Misc`, `DataAbilities`, `FindFirstChild`, `Hidden`, `insert`, `isRankedMatchServer`, `isNoAbilityRankedMatchServer`, `isClanWarServer`, `isDuelMatchServer`, `OnChange`, `Votes`, `GetExpect`, `SelectAbility`, `OnClientEvent`, `Start`, `require`, `game`, `Players`, `GetService`, `LocalPlayer`, `PlayerScripts`, `WaitForChild`, `ClientLoader`, `ControllerIsolator`, `CreateRequire`, `script`, `ReplicatedStorage`, `Packages`, `Replion`, `Net`, `Common`, `Utils`, `Utilities`, `Thread`, `Shared`, `Inventory`, `ClientGameModules`, `GuiHandler`, `Controllers`, `UI`, `ShopController`, `ServerInfo`, `PlayerGui`, `Vote`, `AbilityBanned`, `UpdateAbilityBanVotes`, `RemoteEvent`, `UpdateAbilityBanned`

### [870] ReplicatedStorage.Controllers.UI.AbilityVotingController
`ModuleScript` · bytecode v9 · 5626 bytes · 117 constants
- **Services:** Players, ReplicatedStorage, game, workspace
- **Key API:** Clone, Connect, Destroy, Disconnect, FireServer, GetAttribute, GetChildren, GetService, IsA, OnClientEvent, WaitForChild
- Constants: `Client`, `AbilityVoting`, `GetReplion`, `VoteStartTime`, `Get`, `workspace`, `GetServerTimeNow`, `math`, `round`, `max`, `Title`, `string`, `format`, `Vote for an ability for everyone to use (%ss)`, `tostring`, `Text`, `Name`, `IsOpen`, `Close`, `_timerThread`, `Connected`, `Disconnect`, `_initialized`, `_createAbilityFrames`, `Character`, `Parent`, `Alive`, `Open`, `Every`, `_updateVoting`, `ScrollingFrame`, `GetChildren`, `GuiObject`, `IsA`, `VoteCount`, `Votes: %*`, `SelectedOverlay`, `table`, `find`, `Visible`, `_updateVoteCount`, `os`, `clock`, `SelectedAbilities`, `Find`, `FireServer`, `UDim2`, `fromOffset`, `UIGridLayout`, `AbsoluteContentSize`, `Y`, `CanvasSize`, `updateCanvas`, `Template`, `BlockedAbilities`, `Destroy`, `Clone`, `Order`, `GetAttribute`, `LayoutOrder`, `Vector`, `Icon`, `Image`, `Votes: 0`, `Activated`, `Connect`, `task`, `wait`, `GetPropertyChangedSignal`, `Lock`, `Unlock`, `Active`, `Votes`, `Misc`, `DataAbilities`, `Dash`, `Hidden`, `insert`, `WaitReplion`, `OnChange`, `GetExpect`, `OnClientEvent`, `Start`, `require`, `game`, `Players`, `GetService`, `LocalPlayer`, `PlayerScripts`, `WaitForChild`, `ClientLoader`, `ControllerIsolator`, `CreateRequire`, `script`, `ReplicatedStorage`, `Packages`, `Replion`, `Net`, `Common`, `Utils`, `Utilities`, `Thread`, `Shared`, `Inventory`, `ClientGameModules`, `GuiHandler`, `Controllers`, `UI`, `ShopController`, `ServerInfo`, `LTM`, `PlayerGui`, `Vote`, `UpdateAbilityVotes`, `RemoteEvent`, `UpdateAbilityVoteSelected`

### [871] ReplicatedStorage.Controllers.UI.CodesController
`ModuleScript` · bytecode v9 · 3119 bytes · 74 constants
- **Services:** Players, ReplicatedStorage, TweenService, game
- **Key API:** Connect, Create, GetService, Invoke, WaitForChild, new
- Constants: `codeGUI`, `Open`, `Close`, `Toggle`, `User`, `deselect`, `os`, `clock`, `RedeemCode`, `Text`, `Invoke`, `invalid`, `Invalid code!`, `Color3`, `new`, `TextColor3`, `already claimed`, `Already claimed!`, `succesful`, `Successfully claimed!`, `EXPIRED`, `Expired!`, `string`, `match`, `@Message:(.*)`, `TextBox`, `GetPolicyInfo`, `table`, `find`, `AllowedExternalLinkReferences`, `YouTube`, `TwitterFrame`, `Visible`, `reflectPolicy`, `Icons`, `Create`, `setImage`, `CODES`, `setLabel`, `Extra`, `AddDropdown`, `toggled`, `Connect`, `OnClose`, `ImageButton`, `Activated`, `Focused`, `PolicyInfoAdded`, `CloseButton`, `Start`, `require`, `game`, `Players`, `GetService`, `LocalPlayer`, `PlayerScripts`, `WaitForChild`, `ClientLoader`, `ControllerIsolator`, `CreateRequire`, `script`, `ReplicatedStorage`, `TweenService`, `Packages`, `Replion`, `Net`, `Shared`, `Policy`, `ClientGameModules`, `GuiHandler`, `Parent`, `TopBarController`, `PlayerGui`, `Frame`

### [872] ReplicatedStorage.Controllers.UI.CreatorCodesController
`ModuleScript` · bytecode v9 · 2434 bytes · 56 constants
- **Remotes:** Data
- **Services:** Players, ReplicatedStorage, game
- **Key API:** Connect, GetService, Invoke, Play, WaitForChild
- Constants: `Settings`, `Open`, `CreatorCodes.Active`, `Get`, `Text`, `updateText`, `TextEditable`, `ClearCreatorCode`, `Invoke`, `SetCreatorCode`, `Color3`, `fromRGB`, `TextColor3`, `task`, `wait`, `Sounds`, `error`, `Play`, `submitCode`, `PlayerGui`, `WaitForChild`, `CreatorCodes`, `Main`, `CodeBar`, `TextBox`, `Close`, `Activated`, `Connect`, `Client`, `Data`, `WaitReplion`, `OKButton`, `FocusLost`, `Cancel`, `OnGuiOpen`, `OnChange`, `Start`, `require`, `game`, `Players`, `GetService`, `LocalPlayer`, `PlayerScripts`, `ClientLoader`, `ControllerIsolator`, `CreateRequire`, `script`, `ReplicatedStorage`, `Packages`, `Replion`, `Net`, `ClientGameModules`, `GuiHandler`, `Common`, `Utils`

### [873] ReplicatedStorage.Controllers.UI.CyberPackController
`ModuleScript` · bytecode v9 · 5161 bytes · 105 constants
- **Remotes:** Data
- **Services:** Players, ReplicatedStorage, RunService, UserInputService, game, workspace
- **Key API:** Connect, GetAttribute, GetService, WaitForChild, new
- Constants: `procedStarterPack2`, `Get`, `starterPack2`, `GetAttribute`, `workspace`, `GetServerTimeNow`, `GetTimeLeft`, `OwnsCyberPack`, `HasPack`, `IsActive`, `Controllers`, `NotificationController`, `Init`, `CyberPack`, `IsOpen`, `Close`, `Open`, `Enum`, `InfoType`, `Product`, `PromptPurchase`, `starterPack2popup`, `Character`, `Parent`, `Alive`, `GameActive`, `_currentGui`, `task`, `wait`, `List`, `Fade`, `Timer`, `string`, `format`, `%02i:%02i`, `Text`, `Frame`, `TimerBox`, `<stroke color="rgb(89, 0, 0)" joins="round" thickness="2"><font color="rgb(235, 174, 94)">Offer ends: </font> `, `ValueConvertor`, `FormatTimeWithDays`, `</stroke>`, `Thread`, `Every`, `UpdateThread`, `countdown`, `Buy`, `Active`, `Label`, `OWNED`, `Color3`, `new`, `ImageColor3`, `Icon`, `Visible`, `checkIfBought`, `Client`, `Data`, `WaitReplion`, `Activated`, `Connect`, `X`, `GetAttributeChangedSignal`, `GiveTask`, `OnChange`, `spawn`, `OnGuiOpen`, `Start`, `require`, `game`, `Players`, `GetService`, `LocalPlayer`, `PlayerScripts`, `WaitForChild`, `ClientLoader`, `ControllerIsolator`, `CreateRequire`, `script`, `LocalizationService`, `ReplicatedStorage`, `UserInputService`, `GuiService`, `PlayerGui`, `Packages`, `Net`, `ServerInfo`, `Common`, `MarketplaceService`, `Utils`, `ClientGameModules`, `GuiHandler`, `Replion`, `CreatePriceLabel`, `Trading`, `TradeTokensController`, `Remotes`, `isHuntPrivateServer`, `RightHUD`, `Maid`, `RunService`, `IsStudio`, `GameId`, `UserId`, `print`

### [874] ReplicatedStorage.Controllers.UI.DailyLoginController
`ModuleScript` · bytecode v9 · 16371 bytes · 206 constants
- **Remotes:** Data, GetPlayerTimezone
- **Services:** Players, ReplicatedStorage, game, workspace
- **Key API:** Connect, Destroy, Disconnect, FindFirstChild, Fire, GetAttribute, GetChildren, GetDescendants, GetService, InvokeServer, IsA, OnClientInvoke, SetAttribute, WaitForChild, new
- Constants: `workspace`, `GetServerTimeNow`, `TimezoneOffsetInHours`, `Get`, `math`, `floor`, `getCurrentDay`, `getDayStartTimestamp`, `CurrentDailyLoginType`, `Longterm`, `DailyLogin_%*_Rewards`, `format`, `getDailyLoginGuiName`, `Controllers`, `UI`, `TopBarController`, `DailyLogin`, `GetIcon`, `notify`, `_notify`, `os`, `time`, `round`, `OnClientInvoke`, `User`, `warn`, `NO DAILY LOGIN GUI NAME`, `clearNotices`, `Open`, `Close`, `Name`, `DailyLogin_%w+_Rewards`, `match`, `isSelected`, `deselect`, `DailyLoginData.DailyLogin.StartDay`, `Top`, `Today`, `Text`, `Tomorrow`, `Day %*`, `Vector`, `Color3`, `new`, `ImageColor3`, `UIGradient`, `script`, `DarkBackground`, `Color`, `LightBackground`, `QuestionMark`, `Visible`, `Bottom`, `Get in %*`, `ValueConvertor`, `FormatShortTime`, `Unnamed`, `DisplayName`, `updateFrame`, `Network`, `ClaimLoginReward`, `CashOut`, `Fire`, `Wait`, `Rewards`, `Box%*`, `rbxassetid://0`, `Icon`, `Image`, `Label`, `DailyLoginData.DailyLogin.LastWait`, `DailyLoginData.DailyLogin.CashedOut`, `YouWaited`, `Come back in %*`, `task`, `spawn`, `Claimed`, `Available`, `Claimable`, `Active`, `Parent`, `Default`, `rbxassetid://15343677462`, `rbxassetid://15343776517`, `setFrameStyle`, `RewardName`, `???`, `GetAttribute`, `Lock`, `Lock2`, `setFrameLocked`, `DailyLoginData.D30`, `DaysClaimedStreak`, `NextClaim`, `D30`, `DailyLoginData.D30.CurrentMonth`, `DailyLoginData.D30.DaysClaimedStreak`, `DailyLoginData.D30.NextClaim`, `Type`, `MonthVariant`, `Value`, `Day`, `Desc`, `FindFirstChild`, `Play %* days in a row to unlock this rare item!`, `UIScale`, `Destroy`, `Sword`, `Instance`, `Scale`, `updateRewards`, `Data`, `DailyLoginData`, `Next reward in: %*`, `FormatTime`, `rbxassetid://15343840909`, `rbxassetid://15343871405`, `setConsecutiveFrameStyle`, `DailyLoginData.D30.ConsecutiveStreak`, `tonumber`, `%* Consecutive Days`, `ConsecutiveRewards`, `Day%*`, `Reward`, `rbxassetid://00000`, `updateConsecutive`, `Country`, `coroutine`, `running`, `OnChange`, `TH`, `VN`, `TW`, `SG`, `HK`, `Page`, `CloseButton`, `Activated`, `Connect`, `GetDescendants`, `^Day(%d+)$`, `LayoutOrder`, `SetAttribute`, `NextRewardIn`, `Thread`, `Every`, `Consecutive`, `ConsecutiveDays`, `DailyLoginData.Longterm.CurrentMonth`, `DailyLoginData.Longterm.DaysClaimedStreak`, `DailyLoginData.Longterm.NextClaim`, `TopBar`, `DayCounterTextLabel`, `ImageLabel`, `AmountTextLabel`, `ClaimedCover`, `Green`, `UIStroke`, `fromRGB`, `TopBarDefault`, `TopBarGreen`, `Highlights`, `GetChildren`, `Frame`, `IsA`, `%d+`, `Claim`, `Next claim in: %*`, `Disconnect`, `Client`, `WaitReplion`, `InvokeServer`, `wait`, `LegacyModernized`, `WaitForChild`, `WaitForIcon`, `toggled`, `OnClose`, `D%*`, `CashOutEnd`, `OnOpen`, `Start`, `require`, `game`, `Players`, `GetService`, `LocalPlayer`, `PlayerScripts`, `ClientLoader`, `ControllerIsolator`, `CreateRequire`, `ReplicatedStorage`, `PlayerGui`, `Packages`, `Replion`, `Net`, `Common`, `Utils`, `DailyLoginInfo`, `ClientGameModules`, `GuiHandler`, `Remotes`, `GetPlayerTimezone`, `AnalyticsController`, `UDim2`

### [875] ReplicatedStorage.Controllers.UI.DailyLoginController.DailyLoginController
`Script` · bytecode v9 · 787 bytes · 19 constants
- **Key API:** GetAttribute, SetAttribute
- Constants: `debug`, `setmemorycategory`, `Name`, `Start`, `script`, `Parent`, `require`, `Loaded`, `SetAttribute`, `Init`, `GetAttribute`, `GetAttributeChangedSignal`, `Wait`, `pcall`, `task`, `spawn`, `error`, `%*:Init() - %*`, `format`

### [876] ReplicatedStorage.Controllers.UI.DeathScreenController
`ModuleScript` · bytecode v9 · 8494 bytes · 84 constants
- **Services:** Players, ReplicatedStorage, RunService, TweenService, game
- **Key API:** Connect, Create, Disconnect, GetService, OnClientEvent, Once, Play, WaitForChild, new
- Constants: `script`, `Parent`, `SpectateController`, `Init`, `leaveDeathScreen`, `deathScreenStart`, `task`, `wait`, `CharacterAutoLoads`, `OnClientEvent`, `Connect`, `GetPropertyChangedSignal`, `Start`, `Leave`, `Enabled`, `BG`, `TweenInfo`, `new`, `Enum`, `EasingStyle`, `Quart`, `BackgroundTransparency`, `Create`, `Content`, `Denomination`, `TextTransparency`, `Play`, `Header1`, `Header2`, `RespawnTimer`, `Subheader`, `UIStroke`, `Transparency`, `Position`, `UDim2`, `fromScale`, `UIScale`, `Scale`, `Completed`, `Once`, `deathScreenEnd`, `os`, `clock`, `math`, `floor`, `max`, `Text`, `Second`, `Seconds`, `Disconnect`, `RespawnTime`, `ELIMINATED`, `<stroke color="rgb(0,0,0)" joins="Round" thickness="4">YOU WILL <font color="rgb(73, 211, 31)">RESPAWN</font> IN</stroke>`, `Color3`, `fromRGB`, `TextColor3`, `STUNNED`, `<stroke color="rgb(0,0,0)" joins="Round" thickness="4">YOU WILL BE BACK IN</stroke>`, `Visible`, `Wait`, `Heartbeat`, `require`, `game`, `Players`, `GetService`, `LocalPlayer`, `PlayerScripts`, `WaitForChild`, `ClientLoader`, `ControllerIsolator`, `CreateRequire`, `TweenService`, `RunService`, `ReplicatedStorage`, `Packages`, `Net`, `PlayerGui`, `StunnedEvent`, `RemoteEvent`, `CustomRespawnEvent`, `CustomRespawnFinished`, `DisableRespawnScreen`, `DeathScreen`

### [877] ReplicatedStorage.Controllers.UI.DialogueController
`ModuleScript` · bytecode v9 · 6943 bytes · 126 constants
- **Remotes:** Data
- **Services:** Players, ReplicatedStorage, SoundService, TweenService, game
- **Key API:** Clone, Connect, Destroy, Fire, GetService, Play, WaitForChild, new
- Constants: `_skip`, `Skip`, `Ended`, `Wait`, `Completed`, `Fire`, `_maid`, `Destroy`, `pairs`, `_queue`, `table`, `remove`, `Volume`, `LoweringVolume`, `RaisingVolume`, `Thread`, `LoopFor`, `math`, `abs`, `min`, `Connect`, `updateVolume`, `Client`, `Data`, `GetReplion`, `Settings`, `Get`, `Music`, `Current`, `Maid`, `new`, `GetPropertyChangedSignal`, `OnVolumeChange`, `GiveTask`, `disableMusic`, `<br%s*/>`, `gsub`, `<[^<>]->`, `removeTags`, `utf8`, `graphemes`, `MaxVisibleGraphemes`, `os`, `clock`, `task`, `wait`, `Rendering`, `Label`, `BackgroundTransparency`, `Title`, `TextTransparency`, `Content`, `TextStrokeTransparency`, `FadeAway`, `DisableMusic`, `Delay`, `DelayFade`, `ContentText`, `Visible`, `_dialogueData`, `TextSpeed`, `spawn`, `Duration`, `Sound`, `Sounds`, `Play`, `TimeLength`, `clamp`, `Show`, `setmetatable`, `ScreenGui`, `List`, `DialogueFrame`, `Clone`, `dialogue`, `Name`, `: `, `Text`, `TitleColor`, `Color3`, `fromRGB`, `TextColor3`, `N/A`, `TextColor`, `Parent`, `warn`, `Dialog has not loaded.`, `dialogueHasNotLoaded`, `RequiresInput`, `CreateDialogue`, `SendText`, `QuickSend`, `insert`, `Enabled`, `next`, `unpack`, `Streamer`, `PlayerGui`, `Dialogue`, `Sync`, `Loaded`, `Start`, `require`, `game`, `Players`, `GetService`, `LocalPlayer`, `PlayerScripts`, `WaitForChild`, `ClientLoader`, `ControllerIsolator`, `CreateRequire`, `script`, `SoundService`, `ReplicatedStorage`, `TweenService`, `Common`, `Utils`, `Packages`, `Replion`, `Net`, `Signal`, `__index`, `SentText`

### [878] ReplicatedStorage.Controllers.UI.DuoPassController
`ModuleScript` · bytecode v9 · 21523 bytes · 283 constants
- **Remotes:** Data, SetGift
- **Services:** Players, ReplicatedStorage, RunService, SoundService, StarterGui, TweenService, UserInputService, game, workspace
- **Key API:** Clone, Connect, Create, Destroy, FindFirstChild, Fire, FireServer, GetAttribute, GetPlayers, GetService, InvokeServer, OnClientEvent, Play, WaitForChild, new
- Constants: `typeof`, `Instance`, `UserId`, `IsFriendsWith`, `Menu`, `Visible`, `GetCurrentPage`, `Client`, `Data`, `GetReplion`, `IsRestrictedPage`, `DuoPass.DuoId`, `Get`, `Main`, `UseMainFrame`, `MainFrame`, `Remotes`, `SetReplication`, `Leaderboard`, `FireServer`, `OnPageChange`, `Fire`, `SetPage`, `pageButton`, `Welcome`, `IsEnabled`, `GetFFlagKey`, `Enabled`, `GetKey`, `workspace`, `GetServerTimeNow`, `EndTime`, `EnabledSignal`, `updateFlags`, `Name`, `Close`, `Invite`, `InviteList`, `Message`, `GetPlayers`, `IsInDuo`, `GetAttribute`, `CanInvite`, `ImageTransparency`, `Label`, `IN DUO`, `LOADING`, `INVITED`, `CAN'T INVITE`, `INVITE`, `Text`, `updateInviteStatus`, `SendInvite`, `InvokeServer`, `task`, `delay`, `new`, `Add`, `Clone`, `Username`, `PlayerPortrait`, `rbxthumb://type=AvatarHeadShot&id=%*&w=100&h=100`, `format`, `Image`, `ScrollingFrame`, `Parent`, `GetAttributeChangedSignal`, `Connect`, `spawn`, `Activated`, `RemoveInvite`, `OnClientEvent`, `onPlayerAdded`, `Clean`, `Destroy`, `ReadyButton`, `Active`, `DeclineButton`, `PlaybackState`, `Enum`, `Playing`, `Delayed`, `Completed`, `Wait`, `TweenInfo`, `EasingStyle`, `Back`, `EasingDirection`, `In`, `Position`, `UDim2`, `fromScale`, `Create`, `Play`, `Open`, `Character`, `Dead`, `wait`, `_cleaning`, `%* Invited You to join their Duo!`, `Quint`, `Out`, `GetPolicyInfo`, `ArePaidRandomItemsRestricted`, `TopButtons`, `GiftShop`, `close`, `IsOpen`, `updateIsEnabled`, `Disband`, `UI`, `error`, `LeaveDuo`, `leaveDuo`, `PromptSendFriendRequest`, `SetCore`, `GetPlayerByUserId`, `pcall`, `PlayerTwo`, `AddFriend`, `Counter`, `Offlineframe`, `IsRestricted`, `ProfilePicture`, `Headshot`, `andThen`, `onDuoUpdate`, `onPlayerUpdate`, `PreviewReward`, `DuoPass.Kills`, `GetExpect`, `DuoPass.DuoKills`, `TotalKills`, `Amount`, `ValueConvertor`, `AddCommas`, `PlayerOne`, `math`, `min`, `Frame`, `ProgressBar`, `Holder`, `Sine`, `TweenPosition`, `Fill`, `%*/%*`, `ClaimedFrame`, `onKillsUpdate`, `Chance`, `Reward`, `table`, `insert`, `sort`, `OddsList`, `RewardsList`, `FindFirstChild`, `Vector`, `Icon`, `Icons`, `DEFAULT_MISSING`, `GetIcon`, `Percentage`, `%*%%`, `floor`, `setOdds`, `NormalPresentCredits`, `Credits`, `PurchaseNormalGift`, `NormalPresent`, `InfoType`, `Product`, `GetProductInfo`, `DuoPass.RobuxPresents`, `GiftsList`, `GiftTwo`, `ButtonsBottom`, `Buy`, `Open %* for Free`, `PriceInRobux`, ` %*`, `Failed to load`, `OpenRobuxGift`, `updateRobuxPresents`, `PromptPurchase`, `RobuxPresent`, `DuoPass Golden Present`, `SetGift`, `Type`, `List`, `Value`, `Items`, `UIListLayout`, `Template`, `createRewardFrame`, `Placement`, `%*.`, `LeaderboardRewards`, `Rank`, `KillsCounter`, `Points`, `PlayerUsername`, `string`, `gsub`, `/`, ` & `, `Players`, `Player1`, `Id`, `Player2`, `DuoId`, `updateLeaderboard`, `WaitReplion`, `OnGuiOpen`, `OnGuiClose`, `Thread`, `Every`, `DataUpdatedEvent`, `PlayButton`, `YourTeam`, `InviteReceived`, `PlayerRemoving`, `PlayerAdded`, `Gift`, `DuoKillsPass`, `ConfirmationFrame`, `Leave`, `Stay`, `OnChange`, `RewardsPerKills`, `Rewards`, `GrandReward`, `CanPreview`, `Inspect`, `LayoutOrder`, `DisplayName`, `GiftOne`, `InfoButton`, `DuoPassLeaderboard`, `Start`, `require`, `game`, `GetService`, `LocalPlayer`, `PlayerScripts`, `WaitForChild`, `ClientLoader`, `ControllerIsolator`, `CreateRequire`, `script`, `ReplicatedStorage`, `UserInputService`, `SoundService`, `TweenService`, `StarterGui`, `RunService`, `Packages`, `Promise`, `Replion`, `Signal`, `Trove`, `Common`, `Utils`, `Controllers`, `Trading`, `IndexController`, `GiftingController`, `ClientGameModules`, `FFlagClient`, `GuiHandler`, `Shared`, `Policy`, `MarketplaceService`, `TradeTokensController`, `DuoPassData`, `RewardInfo`, `PlayerGui`, `DuoPassMenu`, `DuoPassHud`, `InvitePrompt`, `Pass`, `InviteFriendsFrame`, `promisify`

### [879] ReplicatedStorage.Controllers.UI.EditButtonLayoutController
`ModuleScript` · bytecode v9 · 6880 bytes · 115 constants
- **Remotes:** Data
- **Services:** Players, ReplicatedStorage, game
- **Key API:** Clone, Connect, Destroy, FindFirstChild, FireServer, GetAttribute, GetChildren, GetService, WaitForChild
- Constants: `string`, `format`, `%.1f`, `tonumber`, `%.2f`, `%.3f`, `roundDecimals`, `Client`, `Data`, `WaitReplion`, `Settings`, `Misc`, `ButtonScale`, `Current`, `Get`, `getCurrentScale`, `Name`, `UIScale`, `Scale`, `math`, `clamp`, `%s Button Size: %sx`, `Text`, `FireServer`, `editScale`, `find`, `Elemental`, `sub`, `New`, `GetChildren`, `DONOTSHOW`, `GetAttribute`, `Clone`, `UI_Draggable`, `AddTag`, `Position`, `Ability%*%*`, `FindFirstChildOfClass`, `Ability %*`, `Visible`, `Parent`, `table`, `insert`, `setupAbilityContainer`, `Device`, `Phone`, `Tablet`, `onOpen`, `Destroy`, `onClose`, `FindFirstChild`, `ButtonPosition`, `Default`, `UDim2`, `fromScale`, `X`, `Y`, `AbsolutePosition`, `AbsoluteSize`, `TopbarInset`, `Height`, `AnchorPoint`, `Close`, `round`, `convertToScale`, `Reset`, `Activated`, `Connect`, `Exit`, `OnGuiOpen`, `OnGuiClose`, `DragStarted`, `DragEnded`, `Buttons`, `Increase`, `Decrease`, `Start`, `Init`, `require`, `game`, `Players`, `GetService`, `LocalPlayer`, `PlayerScripts`, `WaitForChild`, `ClientLoader`, `ControllerIsolator`, `CreateRequire`, `script`, `GuiService`, `ReplicatedStorage`, `Packages`, `Replion`, `Common`, `SettingsInfo`, `ClientGameModules`, `GuiHandler`, `UIBindersLegacy`, `Draggable`, `Utils`, `Net`, `ServerInfo`, `Controllers`, `AnalyticsController`, `DeviceListener`, `SetButtonScale`, `RemoteEvent`, `SetButtonPosition`, `PlayerGui`, `Hotbar`, `EditButtonLayout`, `EditScaleLabel`, `Ability`, `Block`

### [880] ReplicatedStorage.Controllers.UI.GenericGachaController
`ModuleScript` · bytecode v9 · 55629 bytes · 522 constants
- **Remotes:** Data, SetGift
- **Services:** CollectionService, Players, ReplicatedStorage, RunService, SoundService, StarterGui, TweenService, UserInputService, game, workspace
- **Key API:** Clone, Connect, Create, Destroy, Disconnect, FindFirstChild, Fire, FireServer, GetAttribute, GetChildren, GetService, Invoke, InvokeServer, IsA, OnClientEvent, Once, Play, SetAttribute, WaitForChild, new
- Constants: `Destroy`, `Instance`, `new`, `Sound`, `SoundId`, `Parent`, `Volume`, `PlaybackSpeed`, `TimePosition`, `Play`, `Ended`, `Once`, `fastAudio`, `Done`, `BigRewardState`, `getGachaIdentifier`, `GachaData`, `SelectedItem`, `GetExpect`, `%*BigRewards`, `format`, `BigRewards`, `Get`, `Path`, `string`, `split`, `.`, `Finishers`, `task`, `spawn`, `error`, `Failed to check if player owns item from old path: %*!`, `Finishers.Unlocked`, `Value`, `Find`, `FindItems`, `table`, `find`, `%*_%*`, `Type`, `getCurrentGachaData`, `match`, `RewardKey`, `_(%d+)`, `tonumber`, `SpecialBigRewardsData`, `Failed to get Big Rewards for country %*`, `assert`, `BigRewardData`, `PhysicalBigRewardData`, `playerOwnsBigReward`, `ArePaidRandomItemsRestricted`, `Unavailable in your region!`, `SendNotification`, `policyDisabled`, `getCurrentGachaIdentifier`, `DataReplion`, `Failed to get Big Rewards for item %*`, `BaseItems`, `CalculateCurrentBucket`, `Big_Reward_%*`, `Reward`, `Low_Tier_Sword`, `Chance`, `Items`, `ChancesFFlag`, `GetKey`, `type`, `workspace`, `GetServerTimeNow`, `IsDataReady`, `%*LuckStartTime`, `%*LuckEndTime`, `getWeights`, `relativeWeights`, `math`, `round`, `options`, `GetChances`, `PittyAmount`, `Card_Reward_%*`, `Pitty`, `PityRewardBucket`, `LeftSide`, `WaitForChild`, `GetChildren`, `Name`, `(%d+)Reward`, `%*Reward`, `FindFirstChild`, `Level%*`, `Arrow`, `Visible`, `Check`, `Vector`, `Icon`, `Image`, `%dReward`, `%d`, `Glow`, `ImageId`, `UpdateLeftSide`, `%*DidReset`, `DidReset`, `RewardPity`, `GuranteeText`, `BulkRewards`, `BG`, `Top`, `Main`, `Bar`, `BarProgress`, `Progress`, `ProgressBarFrame`, `Text`, `Fade`, `Title`, `Wheel`, `Icons`, `1`, `InnerIcon`, `BestPrize1`, `BestPrize2`, `Completed`, `PityForItems`, `TotalSpins`, `ipairs`, `DisplayName`, `UDim2`, `fromScale`, `Size`, `Y`, `Scale`, `FINISHED`, `Chances`, `Ring`, `0%`, `PityRewardBucketFFlag`, `max`, `%d/%d`, `min`, `<stroke color="#000000" thickness="2">Only <font color="#3256ff">%d</font> spins for guaranteed</stroke>`, `%*%%`, `UpdatePittyFrame`, `SetVisibility`, `LocalPlayer`, `PlayerGui`, `announcer`, `Enabled`, `TouchGui`, `Enum`, `CoreGuiType`, `Chat`, `PlayerList`, `HideUI`, `ShowUI`, `AnnouncementBox`, `ScrollingFrame`, `RewardAnnouncementTemplate`, `Clone`, `_announcmentQueue`, `LayoutOrder`, `<stroke color="#000000" thickness="2">%s obtained <font color="rgb(155, 243, 143)">%s</font>!</stroke>`, `insert`, `remove`, `InsertName`, `CrateMain`, `RadialBar`, `CrateSpinRequirement`, `_spriteSheet`, `UpdateLabel`, `Color3`, `fromRGB`, `ImageColor3`, `UpdateMysteryCrateFrame`, `EventEndTimeStamp`, `UnixTimestamp`, `IsActive`, `Open`, `Header`, `Timer`, `Time`, `FormatTimeWithDays`, `IsOpen`, `Close`, `UpdateCountdownFrame`, `SkipAnimation`, `Checkbox`, `ToggleImage`, `_skipping`, `SetDisableWheel`, `DoAnimation`, `ShowBigRewardAnimation`, `Big_Reward`, `SimpleReward`, `ShowRewardScreen`, `os`, `clock`, `_lastRewardSoundTime`, `_rewardSoundCooldown`, `CanPlayRewardSound`, `_lastRewardGlowSoundTime`, `_rewardGlowSoundCooldown`, `CanPlayRewardGlowSound`, `ZIndex`, `TweenInfo`, `EasingStyle`, `Sine`, `EasingDirection`, `Out`, `Create`, `ImageTransparency`, `rbxassetid://6895079853`, `Connect`, `DoItemGlow`, `Misc`, `reward`, `script`, `pairs`, `endAnimation`, `floor`, `random`, `Position`, `bink`, `delay`, `TimeLength`, `TweenPosition`, `wait`, `In`, `NumberValue`, `Changed`, `DoSpinAnimation`, `ToggleChances`, `FrameAlliases`, `tostring`, `FirstReward`, `0`, `Credits`, `RewardQuantity`, `Ball`, `UpdateSciFiSpinner`, `LastPurchaseTimeStamp`, `IsFirstOfDaySaleEligible`, `OpenButtons`, `Open1`, `Open10`, `OpenBulk`, `UpdateFTPSpins`, `UpdateChromeGachaRequirements`, `Grid`, `(%u)`, ` %1`, `gsub`, `^ `, `rbxassetid://000000000`, `%*|%*|%*`, `_gridQueue`, `GetAttribute`, `RewardCount`, `SetAttribute`, `Label`, `%* <font color="rgb(0, 255, 48)">x%*</font>`, `Common`, `Rarity`, `GridRewardTemplate`, `AddRewardToBulkGrid`, `clear`, `ClearBulkFrame`, `GiftButton`, `RedBanner`, `Price`, `Discount`, ` `, `OneSpinPrice`, `FirstOfTheDayOneSpin`, `DevProduct`, `:robux:%s`, `OneSpinProductID`, `TenSpinsProductID`, `UpdateDiscountFrames`, `UpdateGachaOdds`, `GachaEvents`, `MaxEventCurrencySpins`, `EventCurrencySpinPrice`, `EventCurrencyPath`, `EliminationsToGetSpin`, `SpinsLeft`, `CurrentKills`, `EliminationsSpins`, `MaxEliminationSpinPerDay`, `EventCurrencySpins`, `Spin`, `Spin (%*)`, `abs`, `elimination`, `eliminations`, `Desc1`, `<stroke color="rgb(0, 0, 0)" joins="round" thickness="2">Get <font color="rgb(0, 255, 48)">%*</font> more %* 💀 for a spin!</stroke>`, `Desc2`, `(%* %* Spins Left Today)`, `SeasonData`, `Currency`, `s$`, `(%* Eliminations Spins Left Today)`, `LastSpunTimeStamp`, `time`, `_urgentLastSpins`, `CheckForSpinLastSpin`, `TwoHundredFiftySpinsProductID`, `InfoType`, `Product`, `PromptPurchase`, `FiftySpinsProductID`, `GiftTwoHundredFifty%*`, `SetGift`, `GiftFifty%*`, `GiftTen%*`, `GiftOne%*`, `SpinShop`, `Bottom`, `250`, `Gift`, `50`, `10`, `MouseButton1Click`, `ProductId`, `HookSpinShop`, `FireServer`, `RegisterMultiGachaButtons`, `InvokeServer`, `shouldShowBulk`, `GiftTenSpinsProductID`, `Alive`, `Disconnect`, `AncestryChanged`, `Destroying`, `Countries`, `CountryChosen`, `Subheader`, `SELECTED: %*`, `upper`, `color`, `typeof`, `ColorSequence`, `SoccarColor`, `GetTagged`, `UIGradient`, `FindFirstChildWhichIsA`, `%*Offset`, `offset`, `%*Rotation`, `rotation`, `Color`, `Vector2`, `zero`, `Offset`, `Rotation`, `ImageLabel`, `IsA`, `ImageButton`, `TextLabel`, `TextColor3`, `updateChromeTheme`, `next`, `GenericGacha/SetItem`, `Invoke`, `Preview`, `Character`, `Dead`, `Finisher`, `Hook`, `TrackChanges`, `Activated`, `defer`, `OnChange`, `OnClientEvent`, `CharacterAdded`, `OnDescendantChange`, `CountryButtons`, `GuiButton`, `TryButton`, `RECONCILE_BUTTONS`, `MegaReward`, `CloseButton`, `Options`, `OneSpin`, `TenSpins`, `Spawn`, `GenericGacha`, `WindowName`, `RECONCILE_UI_CONFIGURATION`, `IsDescendantOf`, `Select`, `Fire`, `FireDragonGacha`, `Frost`, `IceDragonGacha`, `Thread`, `SafeResume`, `coroutine`, `running`, `yield`, `unpack`, `Data`, `DisableWheelSpin`, `pcall`, `updateQueue`, `LastLoginStamp`, `FTPCountdown`, `Countdown`, `FormatTimeHHMMSS`, `NumberSequence`, `Transparency`, `SlowFlash`, `Quad`, `Keypoints`, `Linear`, `InOut`, `PlaybackState`, `Playing`, `Cancel`, `All`, `Every`, `DoSmallAnimation`, `StopSmallAnimation`, `CheckMysteryCrate`, `RequiredKillsForFreeSpin`, `CurrentKillRotation`, `enableHUD`, `hideHUD`, `getFirstTimeGacha`, `FireDragonSelect`, `WaitForData`, `Client`, `Inventory`, `WaitReplion`, `GetPolicyInfo`, `PolicyInfoAdded`, `Wait`, `GenericGachaSpinStarted`, `RemoteEvent`, `GenericGachaBigRewardNotify`, `GachaDisableWheelAnimation`, `GetPlayersRewardQueue`, `RemoteFunction`, `GenericGachaFTPSpin`, `RightHUD`, `OnGuiOpen`, `OnGuiClose`, `SelectOverlay`, `Add`, `FirstTimeDragonGacha`, `Start`, `require`, `game`, `Players`, `GetService`, `PlayerScripts`, `ClientLoader`, `ControllerIsolator`, `CreateRequire`, `ReplicatedStorage`, `SoundService`, `TweenService`, `StarterGui`, `RunService`, `UserInputService`, `MarketplaceService`, `CollectionService`, `GuiService`, `Packages`, `Replion`, `Net`, `Shared`, `Policy`, `ClientGameModules`, `FFlagClient`, `WeightRandom`, `Utils`, `Utilities`, `Trove`, `GuiHandler`, `LootboxData`, `ValueConvertor`, `Controllers`, `GiftingController`, `UI`, `HUDController`, `RadialSpriteSheetGenerator`, `BigRewardAnimation`, `SpectateController`, `MysteryCrateAnimation`, `ServerInfo`, `CreatePriceLabel`, `CoreCall`, `FinishersController`, `ShowRoomController`, `NotificationController`, `DeepCopy`, `Trading`, `TradeTokensController`, `@game/ReplicatedStorage/Shared/InfiniteBattlepass/InfiniteBattlepassData`, `ChangeSelectedGachaType`, `ProductPurchaseProcessed`, `ActiveGacha`, `SoccerGacha`, `IsTenFootInterface`, `Brazil`, `England`, `France`, `Germany`, `USA`, `ColorSequenceKeypoint`, `Gui`, `SwordSkins`, `Sword`, `Abilities`, `Ability`, `Identifier`, `rbxassetid://15431907789`, `rbxassetid://15431883359`

### [881] ReplicatedStorage.Controllers.UI.GenericGachaController.BigRewardAnimation
`ModuleScript` · bytecode v9 · 6140 bytes · 82 constants
- **Services:** Players, ReplicatedStorage, TweenService, game
- **Key API:** Clone, Create, Destroy, FindFirstChild, GetService, Once, Play, WaitForChild, new
- Constants: `task`, `wait`, `Clone`, `ZIndex`, `Parent`, `TweenInfo`, `new`, `Enum`, `EasingStyle`, `Quad`, `EasingDirection`, `Out`, `Size`, `ImageTransparency`, `UDim2`, `fromScale`, `Create`, `Play`, `Completed`, `Once`, `Position`, `Vector`, `bounceIcon`, `YellowLine1`, `YellowLine2`, `YellowLine3`, `YellowLine4`, `YellowLine5`, `drawYellowLines`, `delay`, `mainHeaders`, `TextTransparency`, `UIStroke`, `FindFirstChildWhichIsA`, `Transparency`, `getGachaIdentifier`, `getCurrentGachaData`, `ChromeGacha`, `SoccerGacha`, `Items`, `RewardKey`, `Main`, `FindFirstChild`, `Visible`, `Frame2`, `WaitForChild`, `Frame`, `YellowLines`, `Icon`, `Title`, `TitleBG`, `Description`, `Header`, `ClickToContinue`, `SimpleReward`, `Sword`, `GetSword`, `Unknown description`, `Text`, `DisplayName`, `ImageId`, `Image`, `FTPCountdown`, `Destroy`, `DoAnimation`, `GachaEvents`, `game`, `TweenService`, `GetService`, `ReplicatedStorage`, `Players`, `require`, `Shared`, `ReplicatedInstances`, `Swords`, `LootboxData`, `LocalPlayer`, `PlayerGui`, `ActiveGacha`, `Gui`, `MegaReward`

### [882] ReplicatedStorage.Controllers.UI.GenericGachaController.GenericGachaController
`Script` · bytecode v9 · 787 bytes · 19 constants
- **Key API:** GetAttribute, SetAttribute
- Constants: `debug`, `setmemorycategory`, `Name`, `Start`, `script`, `Parent`, `require`, `Loaded`, `SetAttribute`, `Init`, `GetAttribute`, `GetAttributeChangedSignal`, `Wait`, `pcall`, `task`, `spawn`, `error`, `%*:Init() - %*`, `format`

### [883] ReplicatedStorage.Controllers.UI.GenericGachaController.MysteryCrateAnimation
`ModuleScript` · bytecode v9 · 5093 bytes · 73 constants
- **Services:** ReplicatedStorage, TweenService, game
- **Key API:** Clone, Connect, Create, Destroy, GetChildren, GetService, Play, new
- Constants: `TweenInfo`, `new`, `Enum`, `EasingStyle`, `Quad`, `EasingDirection`, `Out`, `Rotation`, `Create`, `Play`, `Completed`, `Wait`, `task`, `wait`, `HookSmallAnimation`, `DoSmallAnimation`, `StopSmallAnimation`, `Crate`, `Visible`, `rbxassetid://15452080089`, `Image`, `Size`, `UDim2`, `fromScale`, `delay`, `stopShakingAndExplode`, `Connect`, `doShake`, `shakeImageLabel`, `Sine`, `In`, `Position`, `ImageTransparency`, `stars`, `GetChildren`, `X`, `Scale`, `Offset`, `Back`, `fallingStars`, `ItemGlow`, `Linear`, `InOut`, `startRotation`, `Icon`, `Title`, `TextTransparency`, `UIStroke`, `Transparency`, `rewardIcon`, `Destroy`, `Clone`, `Parent`, `DisplayName`, `RewardKey`, `Text`, `ImageId`, `DEFAULT_MISSING`, `GetIcon`, `DoAnimation`, `game`, `TweenService`, `GetService`, `ReplicatedStorage`, `require`, `Shared`, `LootboxData`, `GachaEvents`, `MatrixGacha`, `Common`, `Utils`, `Utilities`, `Icons`

### [884] ReplicatedStorage.Controllers.UI.GiftInventoryController
`ModuleScript` · bytecode v9 · 3566 bytes · 78 constants
- **Remotes:** Data, SetGift
- **Services:** Players, ReplicatedStorage, game
- **Key API:** Clone, Connect, Destroy, FindFirstChild, GetChildren, GetService, IsA, WaitForChild
- Constants: `GiftInventory`, `Get`, `setEnabled`, `Close`, `notify`, `_updateVisibility`, `SetGift`, `FindFirstChild`, `Clone`, `Name`, `Title`, `DisplayName`, `name`, `Text`, `Icon`, `type`, `Sword`, `GetSword`, `rbxassetid://15798994355`, `Image`, `Activated`, `Connect`, `Parent`, `Amount`, `x%*`, `format`, `Visible`, `GetChildren`, `GuiObject`, `IsA`, `Destroy`, `_updateGifts`, `User`, `IsOpen`, `Open`, `deselect`, `select`, `clearNotices`, `pairs`, `productId`, `tostring`, `PlayerGui`, `WaitForChild`, `Main`, `ScrollingFrame`, `Template`, `WaitForIcon`, `toggled`, `OnGuiClose`, `OnGuiOpen`, `Client`, `Data`, `WaitReplion`, `OnChange`, `Start`, `require`, `game`, `Players`, `GetService`, `LocalPlayer`, `PlayerScripts`, `ClientLoader`, `ControllerIsolator`, `CreateRequire`, `script`, `ReplicatedStorage`, `Packages`, `Replion`, `Controllers`, `UI`, `TopBarController`, `ClientGameModules`, `GuiHandler`, `GiftingController`, `Shared`, `ReplicatedInstances`, `Swords`, `GiftProductsId`

### [885] ReplicatedStorage.Controllers.UI.GlobalMessageController
`ModuleScript` · bytecode v9 · 4303 bytes · 89 constants
- **Remotes:** Notification
- **Services:** Players, ReplicatedStorage, TweenService, game, workspace
- **Key API:** Clone, Connect, Create, Destroy, FireServer, GetService, Play, WaitForChild, new
- Constants: `EnqueueBatch`, `Queue`, `BatchQueue`, `Running`, `MaxListening`, `IsProcessing`, `CreateGlobalMessages`, `Connect`, `FireServer`, `Start`, `Name`, `Picture`, `CallerName`, `Caller`, `GetNameFromUserIdAsync`, `Enum`, `ThumbnailType`, `AvatarBust`, `ThumbnailSize`, `Size180x180`, `GetUserThumbnailAsync`, `Message`, `warn`, `[GlobalMessage] Tried to display invalid message:`, `Clone`, `Frame`, `Message from `, `pcall`, `Title`, `%* `, `format`, `Text`, `Image`, `Destroy`, `DoNotDisplayTitle`, `Visible`, `GroupTransparency`, `UIScale`, `Scale`, `Parent`, `TweenInfo`, `new`, `EasingStyle`, `Sine`, `Create`, `Play`, `Elastic`, `Assets`, `UI`, `Notification`, `task`, `wait`, `Duration`, `Rotation`, `DisplayMessage`, `[GlobalMessage] Error while displaying message:`, `_tryRunNext`, `table`, `remove`, `spawn`, `insert`, `Push`, `workspace`, `GetServerTimeNow`, `Timestamp`, `Messages`, `_processBatch`, `_tryProcessNextBatch`, `require`, `game`, `Players`, `GetService`, `LocalPlayer`, `PlayerScripts`, `WaitForChild`, `ClientLoader`, `ControllerIsolator`, `CreateRequire`, `script`, `ReplicatedStorage`, `TweenService`, `PlayerGui`, `Packages`, `Net`, `GlobalMessageUI`, `UIListLayout`, `Template`, `GetGlobalMessages`, `RemoteEvent`

### [886] ReplicatedStorage.Controllers.UI.HUDController
`ModuleScript` · bytecode v9 · 32021 bytes · 437 constants
- **Remotes:** ChangedAfkMode, ChangeSwordColor, Data, getAFKStatus, MuteMusic, RequestTeleportToMain, TemporarilyDisableSFX
- **Services:** Debris, Players, ReplicatedStorage, RunService, SoundService, TweenService, UserInputService, game, workspace
- **Key API:** Clone, Connect, Create, Destroy, Disconnect, FindFirstChild, FireServer, GetAttribute, GetChildren, GetDescendants, GetService, InvokeServer, IsA, OnClientEvent, Play, SetAttribute, WaitForChild, new
- Constants: `hideAllUI`, `Middle`, `ShiftlockButton`, `getMissingContent`, `GetLeftFrameContent`, `Enabled`, `CurrentState`, `SetHUDScreenGui`, `SetTag`, `HideHotbar`, `Show`, `Hide`, `GetAttribute`, `SetAttribute`, `setAttributeOnce`, `Visible`, `CondenseHiddenOriginal`, `Position`, `CondensedPositionOriginal`, `AnchorPoint`, `CondensedAnchorPointOriginal`, `Size`, `CondensedSizeOriginal`, `table`, `find`, `Condense`, `Expand`, `Open`, `Close`, `_toggleState`, `Toggle`, `_isTraining`, `Character`, `workspace`, `Alive`, `IsDescendantOf`, `RespawnOverride`, `Misc`, `error`, `Play`, `string`, `match`, `Name`, `(%w+)Page$`, `%* is not a valid page button!`, `format`, `assert`, `OnlyDead`, `ExcludeDeadInTrainingMode`, `GuiUtils`, `getActivatedSignal`, `Connect`, `_setupPageButton`, `_colorPicker`, `ChangeSwordColor`, `FireServer`, `Client`, `Data`, `WaitReplion`, `GamePasses`, `VIP`, `Find`, `Subscriptions`, `VIPPlus`, `Active`, `Get`, `PromptGamePassPurchase`, `SlashColor`, `GetExpect`, `Color3`, `new`, `New`, `UDim2`, `SetColor`, `Finished`, `Canceled`, `OpenColorPicker`, `AFK`, `AFKText`, `UIGradient`, `ColorSequence`, `Color`, `UpdateAFK`, `Sound`, `IsA`, `Volume`, `typeof`, `RBXScriptConnection`, `Connected`, `Disconnect`, `Music`, `GetChildren`, `ChildAdded`, `MusicButton`, `IMG`, `ImageColor3`, `UpdateMusic`, `script`, `Parent`, `ShopControllerAPI`, `OpenRobuxPage`, `ShopController`, `Robux`, `GoTo`, `OpenCoinsPurchase`, `_currency`, `os`, `clock`, `_lastCurrencyChange`, `Credits`, `CreditsSingle`, `GetIcon`, `MoneyFrame`, `ImageLabel`, `Image`, `_currencyTween`, `Cancel`, `Destroy`, `_currencyAmountValue`, `Tokens`, `Inventory`, `GetReplion`, `Value`, `SetCurrency`, `getAFKStatus`, `InvokeServer`, `_isAFK`, `Init`, `IsCovered`, `Buttons`, `VisibleCount`, `Instance`, `HackyBackToMainEnabled`, `game`, `ReplicatedStorage`, `Remotes`, `RequestTeleportToMain`, `ChangedAfkMode`, `Back`, `Text`, `BrickColor`, `Bright red`, `TextColor3`, `updateAFK`, `RankMenu`, `ClansEnabled`, `GetKey`, `ClansStartingUp`, `ClanId`, `_G`, `SendNotification`, `Clans are temporarily unavailable!`, `ClanReplion`, `Clans loading...`, `Clans`, `ClanUIEnabled`, `isBossFightServer`, `isDungeonsMatchServer`, `isTournamentLobbyServer`, `isTournamentMatchServer`, `isTutorialServer`, `isAFKServer`, `isRhythmServer`, `Kills`, `FeaturesToggle`, `updateFlags`, `pairs`, `Players`, `LocalPlayer`, `PlayerGui`, `ScreenGui`, `BillboardGui`, `Hidden`, `HideAllUI`, `RemoteEvent`, `OnClientEvent`, `fromScale`, `SettingsButton`, `RankButton`, `math`, `round`, `MoneyLabel`, `commify`, `SFX`, `task`, `wait`, `tonumber`, `Coins`, `PrimaryPart`, `MoneyGet`, `Clone`, `CFrame`, `WeldConstraint`, `Part1`, `AddItem`, `At2`, `sparkles`, `Emit`, `ParticleEmitter`, `Purchase`, `TweenInfo`, `Create`, `TokensShop`, `OpenPage`, `TradeRequest`, `MusicEnabled`, `MuteMusic`, `updateVisibility`, `Main`, `GameActive`, `GameEnded`, `WaitingForPlayers`, `RankedPlacements`, `updateRankedPlacementVisibility`, `%*ms`, `Boosts`, `Coins2x`, `GetServerTimeNow`, `StartsAt`, `EndsAt`, `Multiplier`, `Thread`, `Every`, `max`, `min`, `DisplayName`, `%*x Coins`, `LayoutOrder`, `ValueConvertor`, `FormatTimeWithDays`, `update`, `BackToolTip`, `CurrentlyEquippedAbility`, `Icon`, `DataAbilities`, `FindFirstChild`, `ForceAbility`, `GoldenAbilities`, `GetAttributes`, `Events`, `GoldenAbilityIcon`, `updateIcon`, `DoNotDisplayBoost`, `getCanShow`, `endTime`, `FormatShortTime`, `RenderStepped`, `experationTime`, `Trials`, `Abilities`, `TimeLeft`, `instance`, `connection`, `clear`, `name`, `insert`, `sort`, `rbxassetid://6034407076`, `UpdateAbilityHUDIcon`, `Ability`, `Block`, `reflectGameHudVisibility`, `Show UI`, `setLabel`, `setImage`, `ToggleHUD`, `Hide UI`, `Settings`, `Hide UI During Match`, `HideDuringMatch`, `select`, `deselect`, `GetLastInputType`, `Enum`, `UserInputType`, `Touch`, `ServerAdminAccess`, `isSelected`, `IsMobile`, `MobileSize`, `OriginalSize`, `UIListLayout`, `HorizontalAlignment`, `Right`, `ShopPage`, `BossUI`, `WaitForChild`, `GetPropertyChangedSignal`, `spawn`, `Left`, `UIPadding`, `UDim`, `PaddingBottom`, `PaddingTop`, `InvisiblePaddingTop_DoNotDelete`, `onDeviceChanged`, `ipairs`, `Bottom`, `updateBottomVisible`, `remove`, `delay`, `IsUICoveredState`, `Top`, `Bottom2`, `GuiButton`, `QueryDescendants`, `UIComponent`, `getPropertyState`, `EmotePC`, `Computed`, `TouchEnabled`, `KeyboardEnabled`, `GamepadEnabled`, `GuiService`, `GetService`, `IsTenFootInterface`, `Page$`, `GetAttributeChangedSignal`, `isRankedLobbyServer`, `RankedLobby`, `isMedalTournamentLobby`, `MedalTournamentLobby`, `Wheel`, `BottomOptions`, `ClanButton`, `HelpGuidePage`, `HelpGuideButtonEnabled`, `GetRemoteConfigValue`, `andThen`, `warn`, `catch`, `TotalStats.Wins`, `OnChange`, `DataUpdatedEvent`, `isDungeonsLobbyServer`, `isTradingPlazaServer`, `DungeonRunes`, `SwitchCurrency`, `Activated`, `OpenShop`, `NumberValue`, `TemporarilyDisableSFX`, `isRankedMatchServer`, `RankedMatch`, `OnDataChange`, `ServerInfoLabel`, `PingLabel`, `GameId`, `TEST SERVER | Version %s`, `PlaceVersion`, ` (BALL 2 ENABLED)`, `Ranked`, `Ranked Lobby`, `Ranked Match`, ` | `, `IsStudio`, `PostSimulation`, `Show Ping`, `isTrainingServer`, `Tooltip`, `RunService`, `GlobalBoosts`, `Boost`, `MouseEnter`, `MouseLeave`, `WindowFocusReleased`, `ServerEvents`, `EditButtonLayout`, `WaitForIcon`, `selected`, `bindEvent`, `deselected`, `Conch/HideUI`, `Dead`, `GetDescendants`, `ImageButton`, `TextButton`, `Frame`, `Observe`, `Start`, `require`, `PlayerScripts`, `ClientLoader`, `ControllerIsolator`, `CreateRequire`, `SoundService`, `TweenService`, `Debris`, `UserInputService`, `Shared`, `UseBall2`, `Packages`, `Replion`, `Net`, `Common`, `Utils`, `Signal`, `BoostsInfo`, `ServerEventBoosts`, `AbilityIcons`, `TopBarController`, `ClientGameModules`, `FFlagClient`, `DynArgs`, `Controllers`, `UI`, `UIStateController`, `Ping`, `Utilities`, `Icons`, `Statable`, `GuiHandler`, `TextUtility`, `MarketplaceService`, `AnalyticsController`, `GetServerType`, `ServerInfo`, `Trading`, `TradeRequestController`, `DeviceListener`, `ClanController`, `fromRGB`, `DailyQuestsPage`, `Emote`, `WelcomeBackButton`, `GetMouse`, `HUD`, `Hotbar`, `LeftFrame`, `RightFrame`, `ClansPageOpened`, `MiddleStack`, `Or`, `HotBarHidden`, `Condensed`, `InsertDynArgs`

### [887] ReplicatedStorage.Controllers.UI.HUDController.HUDController
`Script` · bytecode v9 · 787 bytes · 19 constants
- **Key API:** GetAttribute, SetAttribute
- Constants: `debug`, `setmemorycategory`, `Name`, `Start`, `script`, `Parent`, `require`, `Loaded`, `SetAttribute`, `Init`, `GetAttribute`, `GetAttributeChangedSignal`, `Wait`, `pcall`, `task`, `spawn`, `error`, `%*:Init() - %*`, `format`

### [888] ReplicatedStorage.Controllers.UI.HalloweenGachaLuckIncreaseController
`ModuleScript` · bytecode v9 · 3658 bytes · 84 constants
- **Remotes:** Data
- **Services:** Players, ReplicatedStorage, game, workspace
- **Key API:** Connect, Fire, GetService, WaitForChild
- Constants: `Name`, `IsOpen`, `workspace`, `GetServerTimeNow`, `HalloweenGachaLuckEndTime`, `GetKey`, `HasLuck`, `GetRemaining`, `math`, `max`, `isEnabled`, `X2 LUCK - %*`, `ValueConvertor`, `FormatTimeHHMMSS`, `format`, `Text`, `EVENT ENDED`, `Close`, `updateTimer`, `_currentGui`, `Character`, `Parent`, `Dead`, `task`, `wait`, `Open`, `Network`, `GachaLuckPopup`, `Fire`, `LuckIncreaseEvent`, `WaitForChild`, `Frame`, `TextLabel`, `Every %* rolls is guaranteed
to open the grand chest
with high tier rewards!`, `HalloweenGachaSpinAmountForChest`, `SpinGacha`, `OpenView`, `Client`, `Data`, `WaitReplion`, `WaitForData`, `Timer`, `HalloweenGachaLuckId`, `Get`, `InfGachaTimesSpun%*`, `Season`, `HaveOpenedInfGacha%*`, `delay`, `pcall`, `Thread`, `Every`, `OnGuiOpen`, `spawn`, `MouseButton1Click`, `Connect`, `GetNow`, `Start`, `require`, `game`, `Players`, `GetService`, `LocalPlayer`, `PlayerScripts`, `ClientLoader`, `ControllerIsolator`, `CreateRequire`, `script`, `ReplicatedStorage`, `Common`, `Utils`, `Packages`, `Replion`, `Net`, `ClientGameModules`, `GuiHandler`, `FFlagClient`, `Controllers`, `StPatricksDayEventController`, `Battlepass`, `BattlepassViewController`, `@game/ReplicatedStorage/Shared/InfiniteBattlepass/InfiniteBattlepassData`, `PlayerGui`, `GachaLuckIncrease`, `GachaItemsData`

### [889] ReplicatedStorage.Controllers.UI.HellfirePackController
`ModuleScript` · bytecode v9 · 3864 bytes · 82 constants
- **Remotes:** Data
- **Services:** Players, ReplicatedStorage, UserInputService, game, workspace
- **Key API:** Connect, GetService, WaitForChild, new
- Constants: `LimitedPacks.Hellfire Blade Level 1`, `Get`, `workspace`, `GetServerTimeNow`, `GetTimeLeft`, `Sword`, `Hellfire Blade Level 1`, `FindItems`, `Hellfire Blade Level 2`, `HasPack`, `IsActive`, `Name`, `IsOpen`, `Close`, `Open`, `Enum`, `InfoType`, `Product`, `PromptPurchase`, `List`, `HellfirePack`, `ItemTimer`, `ValueConvertor`, `FormatTimeWithDays`, `Text`, `Window`, `%* Left`, `FormatTime`, `format`, `Remove`, `Thread`, `Every`, `Add`, `PurchaseButton`, `TextLabel`, `update`, `Client`, `Data`, `WaitReplion`, `Visible`, `Activated`, `Connect`, `CloseButton`, `new`, `OnChange`, `task`, `spawn`, `Start`, `require`, `game`, `Players`, `GetService`, `LocalPlayer`, `PlayerScripts`, `WaitForChild`, `ClientLoader`, `ControllerIsolator`, `CreateRequire`, `script`, `LocalizationService`, `ReplicatedStorage`, `UserInputService`, `GuiService`, `PlayerGui`, `Packages`, `Trove`, `Net`, `Common`, `MarketplaceService`, `ServerInfo`, `Utils`, `Shared`, `Inventory`, `ClientGameModules`, `GuiHandler`, `Replion`, `CreatePriceLabel`, `Controllers`, `Trading`, `TradeTokensController`, `isHuntPrivateServer`, `RightHUD`

### [890] ReplicatedStorage.Controllers.UI.InviteRewardsController
`ModuleScript` · bytecode v9 · 7783 bytes · 145 constants
- **Remotes:** Data, Update
- **Services:** HttpService, Players, ReplicatedStorage, StarterGui, game, workspace
- **Key API:** Clone, Connect, Create, Disconnect, FindFirstChild, FireServer, GetAttribute, GetService, Invoke, InvokeServer, WaitForChild, new
- Constants: `CanSendGameInviteAsync`, `GetUserThumbnailAsync`, `GetFriendsAsync`, `PromptOptions`, `Type`, `AFK`, `IsOnline`, `TrySendAFKInviteLocally`, `Id`, `Invoke`, `CurrentInvitePrompt`, `GetInviteData`, `Instance`, `new`, `ExperienceInviteOptions`, `Add`, `JSONEncode`, `LaunchData`, `InviteUser`, `PromptGameInvite`, `PlayerProfile`, `Headshot`, `Image`, `Clone`, `Name`, `Icons`, `DEFAULT_MISSING`, `GetIcon`, `Username`, `@%*`, `format`, `Text`, `Status`, `Online`, `Offline`, `Color3`, `fromRGB`, `TextColor3`, `LayoutOrder`, `Parent`, `InviteButton`, `UI_ButtonHoverAnimation2`, `AddTag`, `Activated`, `Connect`, `Enum`, `ThumbnailType`, `HeadShot`, `ThumbnailSize`, `Size100x100`, `AddPromise`, `andThen`, `Create`, `Clean`, `Clear`, `Client`, `Data`, `WaitReplion`, `InviteRewards.ClaimedRewards`, `Find`, `HasRewards`, `update`, `Disconnect`, `OnArrayInsert`, `OnGuiOpen`, `task`, `spawn`, `Watch`, `UserId`, `retryWithDelay`, `await`, `GetCurrentPage`, `HasFriends`, `Pages`, `IterPagesAsync`, `Update`, `isPrivateServer`, `workspace`, `AreInvitesEnabled`, `GetAttribute`, `CanInvite`, `IsOpen`, `Default`, `Open`, `PromptFriendInvite`, `InvokeServer`, `FireServer`, `Close`, `Invites`, `Frame`, `UDim2`, `fromScale`, `Position`, `Reward%*`, `FindFirstChild`, `Visible`, `onUpdate`, `CoreGuiType`, `PlayerList`, `GameInvitePromptClosed`, `CantInvite`, `CantInvite2`, `table`, `clone`, `insert`, `sort`, `OnGuiClose`, `Start`, `require`, `game`, `Players`, `GetService`, `LocalPlayer`, `PlayerScripts`, `WaitForChild`, `ClientLoader`, `ControllerIsolator`, `CreateRequire`, `script`, `ReplicatedStorage`, `SocialService`, `HttpService`, `StarterGui`, `ClientGameModules`, `GuiHandler`, `CoreCall`, `Packages`, `Promise`, `Replion`, `Signal`, `Trove`, `Net`, `ServerInfo`, `Common`, `Utils`, `Shared`, `InviteRewards`, `PromptFriendInviteClosed`, `RemoteEvent`, `SendAFKFriendInvite`, `RemoteFunction`, `PlayerGui`, `ScrollingFrame`, `Template`, `promisify`

### [891] ReplicatedStorage.Controllers.UI.InviteRewardsController.InviteRewardsController
`Script` · bytecode v9 · 787 bytes · 19 constants
- **Key API:** GetAttribute, SetAttribute
- Constants: `debug`, `setmemorycategory`, `Name`, `Start`, `script`, `Parent`, `require`, `Loaded`, `SetAttribute`, `Init`, `GetAttribute`, `GetAttributeChangedSignal`, `Wait`, `pcall`, `task`, `spawn`, `error`, `%*:Init() - %*`, `format`

### [892] ReplicatedStorage.Controllers.UI.LeaderboardRewardsController
`ModuleScript` · bytecode v9 · 2935 bytes · 69 constants
- **Services:** Players, ReplicatedStorage, game
- **Key API:** Clone, Connect, Destroy, GetChildren, GetService, InvokeServer, IsA, OnClientEvent, WaitForChild
- Constants: `PlaceLabel`, `string`, `format`, `<stroke color="rgb(0,0,0)" joins="miter" thickness="2">You scored <font color="rgb(255,25,25)">%s Elo</font> and placed <font color="rgb(255,25,25)">#%s</font>!</stroke>`, `ValueConvertor`, `AddCommas`, `Text`, `SeasonLabel`, `(Season %s - Ranked %s)`, `script`, `RewardTemplate`, `Clone`, `Icon`, `Sword`, `Viewport`, `Visible`, `NameLabel`, `RandomAbilities`, `Random Ability`, `Ability`, `SetSwordIconAsViewportByName`, `Image`, `RewardList`, `Parent`, `_currentGui`, `task`, `wait`, `LeaderboardRewards`, `Open`, `open`, `delay`, `InvokeServer`, `Close`, `GetChildren`, `GuiBase2d`, `IsA`, `Destroy`, `OnClientEvent`, `Connect`, `ClaimButton`, `Activated`, `Start`, `require`, `game`, `Players`, `GetService`, `LocalPlayer`, `PlayerScripts`, `WaitForChild`, `ClientLoader`, `ControllerIsolator`, `CreateRequire`, `ReplicatedStorage`, `Packages`, `Replion`, `Net`, `ClientGameModules`, `GuiHandler`, `Shared`, `RankedSeasonData`, `Common`, `Utils`, `Icons`, `ClaimRankedLeaderboardReward`, `RemoteFunction`, `ShowLeaderboardReward`, `RemoteEvent`, `PlayerGui`, `Window`

### [893] ReplicatedStorage.Controllers.UI.LimitedSwordPacksController
`ModuleScript` · bytecode v9 · 32002 bytes · 299 constants
- **Remotes:** Data, SetGift
- **Services:** Players, ReplicatedStorage, game, workspace
- **Key API:** Clone, Connect, Destroy, Disconnect, FindFirstChild, Fire, GetAttribute, GetChildren, GetService, InvokeServer, IsA, Play, SetAttribute, WaitForChild, new
- Constants: `FFlagStartTime`, `GetKey`, `RootFFlagStartTime`, `getStartDate`, `FFlagEndTime`, `RootFFlagEndTime`, `getEndDate`, `pairs`, `Rewards`, `Item`, `ProductId`, `GiftName`, `productId`, `GetItemFromProductId`, `GetRewardFromProductId`, `PriceInRobux`, `UserBasePriceInRobux`, `cancel`, `GetAttribute`, `Tokens`, `Get`, `Id`, `Price`, `BuyToken`, `Visible`, `Enum`, `InfoType`, `Product`, `GetProductInfoAsync`, `timeout`, `andThen`, `table`, `insert`, `all`, `await`, `TradingTokensBuyProductsDisabledList`, `TradingTokensBuyProductsEnabled`, `TradingTokensEnabled`, `find`, `Coins`, `Amount`, `ValueConvertor`, `AddCommas`, `Text`, `updateTokens`, `_G`, `SendNotification`, `Remotes`, `PurchaseProductWithTokens`, `type`, `InvokeServer`, `Misc`, `error`, `Play`, `reward`, `Icon`, `Name`, `DisplayName`, `PromptConfirmation`, `promptTokenPurchase`, `PromptPurchase`, `PromptProductPurchase`, `UDim2`, `fromScale`, `Position`, `updatePosition`, `Buttons`, `Buy`, `SetGift`, `Gift`, `BundleRewardData`, `Color`, `CurrentlySelectedColor`, `Chroma`, `CurrentlyColorTypeForcedShowRoom`, `_bundleChanged`, `Fire`, `RewardType`, `ShowBuyButtons`, `createListReward`, `createSwordReward`, `Chroma Oni Katana`, `createExplosionReward`, `Chroma Oni Katana Explosion`, `createEmoteReward`, `Emote966`, `Type`, `List`, `Value`, `Info`, `Selected`, `Instance`, `InnerShowRooms`, `FindFirstChild`, `NPCS`, `1`, `os`, `clock`, `Explosion`, `HumanoidRootPart`, `CFrame`, `new`, `PlayExplosion`, `Sword`, `SwordAccessory`, `IsShown`, `SetAttribute`, `Polar Bear`, `Winter Wolf`, `IgnoreAccessory`, `Emote`, `Slash`, `NoEmote`, `GetInstance`, `HideSword`, `Emote711`, `try`, `Client`, `Inventory`, `WaitReplion`, `SwordBuyButtons`, `WaitForChild`, `SingleGift`, `SingleBuy`, `DualBuy`, `DualGift`, `PackBuyButtons`, `SelectColorBuyButtons`, `OnChange`, `GetAttributeChangedSignal`, `Connect`, `task`, `spawn`, `Activated`, `GetPropertyChangedSignal`, `SwordPacks`, `InfoLabel`, `GetChildren`, `tonumber`, `Try`, `TryTop`, `SelectColor`, `ColorsList`, `GuiButton`, `IsA`, `SetupSwordBuyButtons`, `ItemPrice`, `Failed to load`, `DiscountedFrom`, `Worth`, `Label`, `Top bar`, `fade`, `Timer`, `Stock`, `ImageLabel`, `TextLabel`, `SelectColors`, `Bundle`, `Bottom Bar`, `ScrollingFrame`, `GuiObject`, `SelGlow`, `CurrentlySelectedBundle`, `math`, `ceil`, `LayoutOrder`, `QuantityLeft`, `Parent`, `InitialStock`, `%*/%*`, `format`, `%* LEFT`, `DEFAULT_MISSING`, `GetIcon`, `Image`, `Obtain`, `Active`, `RobuxIcon`, `Loading`, `???`, `playerOwnsItem`, `GetInventoryVersion`, `Old`, `PURCHASED`, `catch`, `Polar Bear Mount`, `Winter Wolf Mount`, `SOLD OUT`, `ItemIcon`, `ItemName`, `MISSING_DISPLAY_NAME`, `CurrentDayRewardIndex`, `0/%*`, `LockedFrame`, `LimitedSwordsBlackFridayDiscountActive`, `%*_%*`, `Discount`, `%*%% OFF`, `floor`, `???% OFF`, `updateBlackFridayFrames`, `Disconnect`, `TemplateSword`, `TemplateExplosion`, `Clone`, `SwordIcon`, `SwordName`, `animateButtonHover`, `DataUpdatedEvent`, `Destroying`, `CreateBundleOfType`, `workspace`, `GetServerTimeNow`, `GetActiveBundles`, `debug`, `profilebegin`, `LimitedSwordEventPacks:UpdateBundleBar`, `ShowRooms`, `Destroy`, `ShowRoom`, `TemplateType`, `string`, `Available In %s`, `FormatTimeWithDays`, `TextBgQuantity`, `Quantity`, `TextBg`, `clear`, `profileend`, `UpdateBundleBar`, `LimitedSwordEventPacks:UpdateCountdown`, `max`, `IsOpen`, `Close`, `UpdateCountdown`, `BundleChanged`, `defer`, `Loaded`, `updateButtons`, `update`, `1_%*`, `BlackFridayBanner`, `next`, `ShowSelectColorInfoLabel`, `updateInfoLabel`, `LimitedStockItems`, `Every`, `ShowRoomOpened`, `LimitedSword_ShowRoom`, `Frame`, `Hook`, `WaitForData`, `Data`, `Start`, `require`, `game`, `Players`, `GetService`, `LocalPlayer`, `PlayerScripts`, `ClientLoader`, `ControllerIsolator`, `CreateRequire`, `script`, `ReplicatedStorage`, `Common`, `MarketplaceService`, `Packages`, `Net`, `Promise`, `ClientGameModules`, `GuiHandler`, `Signal`, `Utils`, `Utilities`, `Thread`, `Replion`, `Shared`, `LimitedSwordPacksData`, `UiPresets`, `Icons`, `FFlagClient`, `Controllers`, `GiftingController`, `VFXController`, `ReplicatedInstances`, `EmoteVFX`, `EmoteAccessories`, `RewardInfo`, `Trading`, `TradeTokensController`, `TradeInfo`, `GiftProductsId`, `ShowRoomController`, `PlayerGui`, `LimitedSword_SwordPacks`, `Black`

### [894] ReplicatedStorage.Controllers.UI.LimitedSwordPacksController.LimitedSwordPacksController
`Script` · bytecode v9 · 787 bytes · 19 constants
- **Key API:** GetAttribute, SetAttribute
- Constants: `debug`, `setmemorycategory`, `Name`, `Start`, `script`, `Parent`, `require`, `Loaded`, `SetAttribute`, `Init`, `GetAttribute`, `GetAttributeChangedSignal`, `Wait`, `pcall`, `task`, `spawn`, `error`, `%*:Init() - %*`, `format`

### [895] ReplicatedStorage.Controllers.UI.ModerationHistoryController
`ModuleScript` · bytecode v9 · 4081 bytes · 99 constants
- **Remotes:** Set
- **Services:** Players, ReplicatedStorage, game
- **Key API:** Clone, Connect, Destroy, FireServer, GetChildren, GetService, Invoke, IsA, WaitForChild
- Constants: `typeof`, `number`, `os`, `date`, `%m/%d/%Y
%H:%M:%S`, `string`, `(%d+)%-(%d+)%-(%d+)T(%d+):(%d+):(%d+)`, `match`, `format`, `%s/%s/%s
%s:%s:%s`, `00`, `0000`, `Unknown`, `formatTimestamp`, `Open`, `Conch/ModLogs/View/Response`, `RemoteEvent`, `FireServer`, `GetNameFromUserIdAsync`, `GetUserIdFromNameAsync`, `ProfileImage`, `Enum`, `ThumbnailType`, `HeadShot`, `ThumbnailSize`, `Size100x100`, `GetUserThumbnailAsync`, `Image`, `Logs`, `Clear`, `Safe`, `NoLogs`, `Visible`, `Type`, `Banned`, `Unbanned`, `Clone`, `Entry_`, `Name`, `Moderator`, `pcall`, `User`, `TextLabel`, `Text`, `Date`, `Timestamp`, `Action`, `Reason`, `Length`, `Permanent`, `Parent`, `Username`, `Status`, `Color3`, `fromRGB`, `TextColor3`, `Computed`, `Conch/ModLogs/View`, `Connect`, `xpcall`, `warn`, `Activated`, `Close`, `Start`, `ModLogs/Get`, `Invoke`, `UserId`, `Set`, `ModerationHistory`, `IsOpen`, `GetChildren`, `Frame`, `IsA`, `Destroy`, `require`, `game`, `Players`, `GetService`, `LocalPlayer`, `PlayerScripts`, `WaitForChild`, `ClientLoader`, `ControllerIsolator`, `CreateRequire`, `script`, `ReplicatedStorage`, `ClientGameModules`, `GuiHandler`, `Shared`, `Statable`, `Packages`, `Net`, `PlayerGui`, `Console`, `List`, `UIListLayout`, `Template`, `State`

### [896] ReplicatedStorage.Controllers.UI.MonthlyLeaderboardRewardsController
`ModuleScript` · bytecode v9 · 2859 bytes · 74 constants
- **Remotes:** Data
- **Services:** Players, ReplicatedStorage, SoundService, game, workspace
- **Key API:** Clone, Connect, Destroy, GetChildren, GetService, IsA, OnClientEvent, Play, WaitForChild
- Constants: `Client`, `Data`, `WaitReplion`, `warn`, `Failed to find MonthlyLeaderboard rewards for %*!`, `format`, `Country`, `GetExpect`, `LeaderboardName`, `Monthly Wins (%*)`, `Text`, `Placement`, `<stroke color="rgb(0,0,0)" joins="miter" thickness="2">You placed <font color="rgb(255,25,25)">#%*</font> and won:</stroke>`, `ValueConvertor`, `AddCommas`, `RewardList`, `GetChildren`, `GuiObject`, `IsA`, `Destroy`, `Rank`, `Clone`, `Icon`, `Reward`, `Image`, `NameLabel`, `Top %*`, `AddFromRewardInfo`, `Parent`, `Character`, `workspace`, `Alive`, `task`, `wait`, `Enabled`, `Open`, `SFX`, `LTMSpin_ClaimSpins`, `Play`, `ClaimButton`, `Activated`, `Connect`, `OnClientEvent`, `Start`, `require`, `game`, `Players`, `GetService`, `LocalPlayer`, `PlayerScripts`, `WaitForChild`, `ClientLoader`, `ControllerIsolator`, `CreateRequire`, `script`, `ReplicatedStorage`, `SoundService`, `Shared`, `MonthlyLeaderboardRewards`, `Controllers`, `HoverInfoController`, `GetCountryFlagEmoji`, `Common`, `RewardInfo`, `Packages`, `Replion`, `Utils`, `Net`, `PlayerGui`, `Window`, `UIListLayout`, `RewardTemplate`, `ReceiveMonthlyLeaderboardRewards`, `RemoteEvent`

### [897] ReplicatedStorage.Controllers.UI.PersonalStatsController
`ModuleScript` · bytecode v9 · 4991 bytes · 105 constants
- **Remotes:** Data
- **Services:** Players, ReplicatedStorage, game
- **Key API:** Clone, Connect, Destroy, FindFirstChild, GetChildren, GetService, IsA, WaitForChild, new
- Constants: `next`, `unpack`, `math`, `floor`, `abs`, `tostring`, `ConvertTimeToUnits`, `SumModes`, `-`, `MakeStat`, `Losses`, `Kills`, `Wins`, `Matches`, `TimePlayed`, `BestWinStreak`, `LoadPersonalStats`, `Parent`, `Header`, `Personal Stats`, `Text`, `Deaths`, `StatNumber`, `Eliminations`, `GamesPlayed`, `GamesWon`, `WinStreak`, `typeof`, `table`, `warn`, `Ability Data is not a table...`, `FindFirstChild`, `TimeCounter`, ` Rounds`, `LayoutOrder`, `BarFrame`, `Progress`, `UDim2`, `fromScale`, `Size`, `UpdatePersonalStats`, `Attempted to update UI, but replion returned nothing`, `Attempted to update ability usage, but replion returned nothing`, `TotalStats`, `Get`, `TotalAbilityUsage`, `Error Getting Personal Stats`, `Error Getting Ability Stats`, `GetChildren`, `Frame`, `IsA`, `Destroy`, `Clone`, `Name`, `Ability`, `Icon`, `Image`, `0 Rounds`, `ClearAllChildren`, `OnChange`, `Add`, `new`, `Client`, `Data`, `AwaitReplion`, `StatsLoader`, `PersonalStats`, `Close`, `task`, `spawn`, `Page`, `CloseButton`, `Activated`, `Connect`, `Start`, `require`, `game`, `Players`, `GetService`, `LocalPlayer`, `PlayerScripts`, `WaitForChild`, `ClientLoader`, `ControllerIsolator`, `CreateRequire`, `script`, `ReplicatedStorage`, `Remotes`, `Shared`, `ClientGameModules`, `GuiHandler`, `Packages`, `Net`, `Replion`, `Trove`, `PlayerGui`, `Windows`, `Statistics`, `AbilityStats`, `AbilityIcons`, `Template`, `Seconds`, `Minutes`, `Hours`

### [898] ReplicatedStorage.Controllers.UI.PlaytimeRewardsController
`ModuleScript` · bytecode v9 · 6191 bytes · 127 constants
- **Remotes:** Data
- **Services:** Players, ReplicatedStorage, game, workspace
- **Key API:** Connect, Create, GetService, InvokeServer, Play, WaitForChild
- Constants: `Rayburst`, `Blue`, `Color3`, `fromRGB`, `Orange`, `ImageColor3`, `UIStroke`, `Color`, `ItemName`, `ItemNameShadow`, `Label`, `TextColor3`, `Visible`, `Active`, `setFrameStyle`, `User`, `PlaytimeRewards`, `Open`, `Close`, `deselect`, `PlaytimeRewardsData.TimerStart`, `Get`, `PlaytimeRewardsData.ClaimedRewards`, `workspace`, `GetServerTimeNow`, `Duration`, `tostring`, `InvokeServer`, `Misc`, `reward`, `Play`, `error`, `claim`, `CloseCurrent`, `Rewards`, `RewardsList`, `BackgroundColor3`, `Gold`, `Enabled`, `Grey`, `ClaimButton`, `Green`, `Claimed`, `Text`, `Claim`, `Notify`, `UDim2`, `fromScale`, `Size`, `math`, `clamp`, `task`, `delay`, `Come back another time!`, `You can claim now!`, `Next reward: %*`, `ValueConvertor`, `FormatTime`, `format`, `updateRewards`, `Client`, `Data`, `WaitReplion`, `WaitForChild`, `Create`, `setImage`, `PLAYTIME AWARDS`, `setLabel`, `Playtime Awards`, `setCaption`, `Notice`, `NoticeLabel`, `NoticeUIStroke`, `modifyTheme`, `toggled`, `Connect`, `Extra`, `AddDropdown`, `OnClose`, `Page`, `List`, `DailyTimerTitle`, `Main`, `Timer`, `CloseButton`, `Activated`, `Top`, `%* Mins`, `round`, `Reward`, `DisplayName`, `Icon`, `rbxassetid://0`, `Image`, `Progress`, `Fill`, `Dots`, `OnChange`, `OnDescendantChange`, `Thread`, `Every`, `Start`, `require`, `game`, `Players`, `GetService`, `LocalPlayer`, `PlayerScripts`, `ClientLoader`, `ControllerIsolator`, `CreateRequire`, `script`, `ReplicatedStorage`, `PlayerGui`, `Packages`, `Replion`, `Net`, `Common`, `Utils`, `PlaytimeRewardsInfo`, `ClientGameModules`, `GuiHandler`, `Parent`, `TopBarController`, `ClaimPlaytimeReward`, `RemoteFunction`

### [899] ReplicatedStorage.Controllers.UI.PlaytimeRewardsController.PlaytimeRewardsController
`Script` · bytecode v9 · 787 bytes · 19 constants
- **Key API:** GetAttribute, SetAttribute
- Constants: `debug`, `setmemorycategory`, `Name`, `Start`, `script`, `Parent`, `require`, `Loaded`, `SetAttribute`, `Init`, `GetAttribute`, `GetAttributeChangedSignal`, `Wait`, `pcall`, `task`, `spawn`, `error`, `%*:Init() - %*`, `format`

### [900] ReplicatedStorage.Controllers.UI.QuestsController
`ModuleScript` · bytecode v9 · 8445 bytes · 151 constants
- **Remotes:** Data
- **Services:** Players, ReplicatedStorage, TweenService, game, workspace
- **Key API:** Clone, Connect, FindFirstChild, FireServer, GetChildren, GetService, IsA, WaitForChild, new
- Constants: `Client`, `Data`, `WaitReplion`, `workspace`, `GetServerTimeNow`, `EndTimestamp`, `ThemedQuests`, `Quests`, `Limited`, `Get`, `Redeemed`, `isThemedQuestsEnabled`, `CurrentQuests`, `GetExpect`, `QuestStats`, `stat`, `goal`, `math`, `min`, `QuestsAwarded`, `Find`, `Daily`, `BG`, `Checks`, `GetChildren`, `UIListLayout`, `IsA`, `Check`, `Visible`, `Intermediate`, `Color3`, `new`, `ImageColor3`, `fromRGB`, `AutoCompleteButton`, `updateNumClaimableQuests`, `AwardedQuests`, `FireServer`, `ProgressBar`, `Bar`, `UDim2`, `fromScale`, `Enum`, `EasingDirection`, `Out`, `EasingStyle`, `Quart`, `TweenSize`, `ProgressValue`, `%*/%*`, `format`, `Text`, `Active`, `updateQuestProgress`, `CompletedOverlay`, `updateQuestClaimed`, `script`, `QuestTemplate`, `Clone`, `Name`, `QuestTitle`, `string`, `text`, `next`, `rewards`, `Rewards`, `Amount`, `+%*`, `commify`, `amount`, `Activated`, `Connect`, `Parent`, `GiveTask`, `OnArrayInsert`, `OnChange`, `_questsMaid`, `_createQuest`, `Enabled`, `Condensed`, `CurrentState`, `Holder`, `Arrow`, `_updateQuestArrowVisibility`, `IsMobile`, `SetToggleEnabled`, `Close`, `DailyQuests`, `DailyQuestChestClaimed`, `updateDailyChest`, `Open`, `GuiObject`, `FindFirstChildWhichIsA`, `EnableGamepadCursor`, `DoCleaning`, `InfoType`, `Product`, `PromptPurchase`, `DontShowDailyQuestChest`, `task`, `spawn`, `StateChanged`, `OnGuiOpen`, `OnGuiClose`, `RefreshQuestsButton`, `CloseButton`, `Opened`, `Start`, `require`, `game`, `Players`, `GetService`, `LocalPlayer`, `PlayerScripts`, `WaitForChild`, `ClientLoader`, `ControllerIsolator`, `CreateRequire`, `ReplicatedStorage`, `GamepadService`, `TweenService`, `Packages`, `Replion`, `Net`, `ClientGameModules`, `TextUtility`, `Common`, `Utils`, `Maid`, `GuiHandler`, `MarketplaceService`, `Controllers`, `Trading`, `TradeTokensController`, `DeviceListener`, `UI`, `HUDController`, `Shared`, `NewQuests`, `ThemedQuestsData`, `PlayerGui`, `NewDailyQuests`, `HUD`, `LeftFrame`, `DailyQuestsPage`, `FindFirstChild`, `Alert`, `QuestArrow`, `ClaimDailyQuest`, `RemoteEvent`, `ClaimDailyChest`

### [901] ReplicatedStorage.Controllers.UI.QuestsController.QuestsController
`Script` · bytecode v9 · 787 bytes · 19 constants
- **Key API:** GetAttribute, SetAttribute
- Constants: `debug`, `setmemorycategory`, `Name`, `Start`, `script`, `Parent`, `require`, `Loaded`, `SetAttribute`, `Init`, `GetAttribute`, `GetAttributeChangedSignal`, `Wait`, `pcall`, `task`, `spawn`, `error`, `%*:Init() - %*`, `format`

### [902] ReplicatedStorage.Controllers.UI.RankedDisconnectController
`ModuleScript` · bytecode v9 · 2865 bytes · 68 constants
- **Remotes:** Data
- **Services:** Players, ReplicatedStorage, game, workspace
- **Key API:** Connect, FireServer, GetAttribute, GetService, WaitForChild
- Constants: `_currentMatch`, `Enabled`, `ShowRejoin`, `Close`, `os`, `clock`, `ID`, `FireServer`, `InRankedQueue`, `GetAttribute`, `MatchFound`, `IsOpen`, `ChooseMap`, `RankedTypes`, `GetCurrentSeason`, `Season%*`, `format`, `RankedMatchHistory`, `Get`, `workspace`, `GetServerTimeNow`, `InProgress`, `Canceled`, `EndTime`, `StartTime`, `string`, `split`, `|`, `Duel`, `searchForMatch`, `Client`, `Data`, `WaitReplion`, `isRankedMatchServer`, `Main`, `Abandon`, `Activated`, `Connect`, `CloseButton`, `Rejoin`, `OnChange`, `task`, `spawn`, `Start`, `require`, `game`, `Players`, `GetService`, `LocalPlayer`, `PlayerScripts`, `WaitForChild`, `ClientLoader`, `ControllerIsolator`, `CreateRequire`, `script`, `ReplicatedStorage`, `Packages`, `Replion`, `Net`, `ClientGameModules`, `GuiHandler`, `Shared`, `RankedSeasonData`, `ServerInfo`, `RejoinRankedMatch`, `RemoteEvent`, `PlayerGui`, `RankedMatchDisconnected`

### [903] ReplicatedStorage.Controllers.UI.RankedSelectionController
`ModuleScript` · bytecode v9 · 45968 bytes · 495 constants
- **Remotes:** AcceptPartyInvite, Data, FetchTop100Leaderboard, JoinQueue, LeaveParty, LeaveQueue, SendPartyInvite, SwitchMode
- **Services:** Players, ReplicatedStorage, RunService, Stats, game, workspace
- **Key API:** Clone, Connect, Destroy, Disconnect, FindFirstChild, Fire, FireServer, GetAttribute, GetChildren, GetPlayers, GetService, InvokeServer, IsA, OnClientEvent, Once, Play, WaitForChild, new
- Constants: `PartyServiceCreatePartyWait`, `RemoteFunction`, `GetCountryRegionForPlayerAsync`, `rawset`, `__index`, `GetChildren`, `ClassName`, `IsA`, `string`, `find`, `lower`, `PlayerName`, `Text`, `PlayerDisplay`, `Visible`, `SearchResults`, `UserId`, `Enum`, `ThumbnailType`, `HeadShot`, `ThumbnailSize`, `Size420x420`, `GetUserThumbnailAsync`, `Image`, `SetPlayerIcon`, `math`, `floor`, `format`, `%02d:%02d:%02d`, `%02d:%02d`, `%02d`, `Hours`, `Minutes`, `Seconds`, `FormatTime`, `table`, `unpack`, `abs`, `tostring`, `sub`, `%* Year%*`, `s`, `ConvertTimeToUnits`, `next`, `ConvertTimeToUnits2`, `GetUsername`, `FetchUsernames`, `Duo`, `FFA`, `SumModes`, `-`, `MakeStat`, `_leaveQueue`, `_toggleWindow`, `Name`, `_selectMode`, `_selectRegion`, `_updateQueues`, `_openedFromPartyButton`, `Enabled`, `_joinQueue`, `LeaveParty`, `FireServer`, `Ranked`, `Dropdown`, `AcceptPartyInvite`, `_currentInvite`, `RankedRewardList`, `Open`, `_updateLeaderboardRewards`, `Tabs`, `GuiObject`, `_clearLeaderboard`, `NoAbility`, `Header`, `WaitForChild`, `Personal Ranked No Ability Stats`, `Personal Ranked Ability Stats`, `ImageButton`, `Mode`, `FindFirstChild`, `GetCurrentSeason`, `Rewards`, `IsStudio`, `warn`, `No Ranked Season rewards found for Season`, `_updateLocalElo`, `_updateRewardsDisplay`, `_updateParty`, `_onPartyInvite`, `_reflectDisabledModes`, `_updateRegionVisibility`, `_updateSearchingText`, `_deployPlayerCard`, `_destroyPlayerCard`, `_inviteTimer`, `max`, `Bar`, `BarProgress`, `UDim2`, `fromScale`, `Size`, `tick`, `rep`, `.`, `Client`, `Data`, `WaitReplion`, `PartyData`, `_selectedMode`, `Auto`, `_selectedRegion`, `_G`, `LeaveRankedQueue`, `Clone`, `Parent`, `GuiButton`, `Activated`, `Connect`, `LockedOverlay`, `Contents`, `Modes`, `Queue`, `GetAttributeChangedSignal`, `Invite`, `Region`, `RankList`, `DisabledOverlay`, `JoinRanked`, `SeasonChanged`, `Parties`, `OnChange`, `Elo`, `OnDescendantChange`, `SwitchMode`, `OnClientEvent`, `SendPartyInvite`, `DataUpdatedEvent`, `FFlag`, `GetPropertyChangedSignal`, `InRankedQueue`, `InParty`, `PlayerAdded`, `PlayerRemoving`, `GetPlayers`, `task`, `defer`, `_loadMatchHistory`, `_loadLeaderboard`, `_loadStatistics`, `_loadInitialWindow`, `_loadAutoQueue`, `Heartbeat`, `Start`, `_autoQueueLoaded`, `WaitForData`, `GetRankedType`, `GetLocalPlayerTeleportData`, `AutoQueue`, `AutoQueueRankType`, `Fire`, `AutoQueueMode`, `IsRankedRestricted`, `AutoQueueTeamData`, `remove`, `InvokeServer`, `_initialWindowLoaded`, `Season`, `_loadHistoryPlacements`, `_loadSeasonData`, `Season %*`, `RankedMatchHistory`, `Get`, `increasePage`, `SeasonSelect`, `Back`, `Next`, `_matchHistoryLoaded`, `AwaitReplion`, `match`, `StartTime`, `_clearHistoryPlacements`, `workspace`, `GetServerTimeNow`, `mode`, `insert`, `sort`, `min`, `Kills`, `Deaths`, `Points`, `Abandoned`, `RatingChange`, `RatingAdjusted`, `Placements`, `EndTime`, ` Ago`, `Teams`, `tonumber`, `2v2 Duos`, `Duel`, `1v1s`, `Free for All`, `LayoutOrder`, `Content`, `GameType`, `TimeSince`, `ELOChange`, `RankIcon`, `GetRank`, `Icon`, `#ffffff`, `#0cf01f`, `#ff4943`, `<stroke color="#1A2B6D" joins="miter" thickness="2"><b>%*</b> <font color="%*">(%*%*)</font></stroke>`, `+`, `<stroke color="#1A2B6D" joins="miter" thickness="2"><b>%*</b><font color="#ffffff"> (+0)</font></stroke>`, `Canceled`, `<stroke color="#1A2B6D" joins="miter" thickness="2"><b><font color="#f57e2a">Canceled</font></b></stroke>`, `<stroke color="#1A2B6D" joins="miter" thickness="2"><b><font color="#ff4943">Abandoned</font></b></stroke>`, `InProgress`, `<stroke color="#1A2B6D" joins="miter" thickness="2"><b><font color="#0cf01f">In Progress</font></b></stroke>`, `<stroke color="#1A2B6D" joins="miter" thickness="2"><b><font color="#f7d708">%*</font></b>/%*</stroke>`, `#`, `<stroke color="#1A2B6D" joins="miter" thickness="2"><b><font color="#f57e2a">Unknown Status</font></b></stroke>`, `PlaceNumber`, `ClearAllChildren`, `BackgroundTransparency`, `NoMatchesPlayed`, `Frame`, `Destroy`, `FetchTop100Leaderboard`, `EloFFA`, `EloDuo`, `EloDuel`, `_registerLeaderboards`, `LeaderboardRankedEnabled`, `GetKey`, `wait`, `Normal`, `_playerList`, `_drawingFrames`, `_leaderboardMode`, `GLOBAL`, `_leaderboardFilter`, `_awaitingLeaderboardLoad`, `_leaderboardRenderDirty`, `_pendingLeaderboardMode`, `_hookLazyLeaderboardRender`, `delay`, `_initiateLeaderboardTimer`, `os`, `clock`, `Main`, `_toggleLeaderboardFrame`, `script`, `MatchToRegion`, `CreateLabelFrom`, `Loading`, `_renderLeaderboard`, `Sorter`, `_requestLeaderboardRender`, `_loadLeaderboardPlayerList`, `onVisibilityChanged`, `Player`, `Country`, `AveragePlacement`, `MostUsedAbility`, `Games`, `IdsToAbilities`, `RegisterPlayer`, `key`, `value`, `Once`, `_registerLeaderboard`, `_awaitLeaderboardLoad`, `GetSeasonEndTime`, `ValueConvertor`, `FormatTimeWithDaysFull`, `new`, `_stats`, `_loadPersonalStats`, `_abilityUsage`, `_loadAbilityStats`, `loadAllStats`, `Season%s`, `RankedStats`, `Add`, `Clean`, `RankedAbilityUsage`, `_statisticsLoaded`, `_prepareAbilityStats`, `TimeCounter`, `BarFrame`, ` Rounds`, `Progress`, `updateAbility`, `typeof`, `Losses`, `Wins`, `Matches`, `TimePlayed`, `WinStreak`, `Personal Ranked Stats`, `Personal Stats`, `StatNumber`, `Eliminations`, `GamesPlayed`, `GamesWon`, `Ability`, `0 Rounds`, `Title`, `LeaderboardRewards`, `Color3`, `BackgroundColor3`, `GetAttribute`, `PlayerQueue`, `%s Players in queue`, `Season%*`, `rankedTypeFFA`, `%* Elo`, `TextColor`, `TextColor3`, `_deployPlayParty`, `GetFFlag`, `RankedRegionSelectEnabled`, `QuestionMark`, `fromRGB`, `ImageColor3`, `Top%*`, `Top%*Text`, `Sword`, `Rotation`, `%* %*`, `Rank`, `Top`, `UIListLayout`, `VerticalAlignment`, `Sounds`, `error`, `Play`, `rbxassetid://130220287908778`, `rbxassetid://92962016976974`, `Only the party leader can change the region!`, `SendNotification`, `rbxassetid://120602131579300`, `rbxassetid://73882225834596`, `rbxassetid://105327464056132`, `rbxassetid://122849015433885`, `HoverImage`, `RankedModeEnabled`, `RankedFFAEnabled`, `RankedDuoEnabled`, `RankedDuelEnabled`, `Disabled`, `@%*`, `DisplayName`, `IsFocused`, `Box`, `_deployPartyMemberCard`, `Kick`, `Label`, `Leave`, `Banner`, `PlayerRankIcon`, `PlayerRank`, `PlayerElo`, `???`, `👑`, `PlayerAvatarIcon`, `CurrentMode`, `No Ability %*`, `_leaveConnection`, `Disconnect`, `Members`, `GetPlayerByUserId`, `_displayParty`, `JoinQueue`, `QueueType`, `QueueGameMode`, `LeaveQueue`, `require`, `game`, `Players`, `GetService`, `LocalPlayer`, `PlayerScripts`, `ClientLoader`, `ControllerIsolator`, `CreateRequire`, `RunService`, `TeleportService`, `ReplicatedStorage`, `LocalizationService`, `PlayerGui`, `Remotes`, `Packages`, `Net`, `Common`, `Utils`, `Trove`, `Signal`, `Replion`, `Shared`, `RankData`, `AbilityIds`, `PlayerData`, `ClientGameModules`, `GuiHandler`, `ServerInfo`, `FFlagClient`, `RegionIcons`, `AbilityIcons`, `PlayerUtility`, `ParseRankedValue`, `RankedSeasonData`, `Controllers`, `RankedQueueController`, `NotificationController`, `RankedSignalController`, `RankedPenaltyController`, `HoverInfo`, `PlayerTemplate`, `RegionTemplate`, `AbilityTemplate`, `PlacementTemplate`, `RankedSelection`, `RankedSelectionClient`, `Page`, `PlayInfo`, `Searching`, `PartyInvitePrompt`, `Windows`, `CloseButton`, `Party`, `Statistics`, `History`, `Gamemodes`, `Leaderboard`, `List`, `RegionSelection`, `ModeButton`, `PlayButton`, `CancelButton`, `Template`, `InviteTemplate`, `Scroll`, `PlayerList`, `Options`, `MyPartyButton`, `InvitesButton`, `SearchBarBox`, `Type`, `AbilityStats`, `PersonalStats`, `CurrentElo`, `Bottom`, `ModeSelector`, `RegionSelector`, `Items`, `TimerBox`, `Timer`, `PartyButton`, `LeaveButton`, `Periods`, `PlaceTeleport`, `RemoteEvent`, `isRankedLobbyServer`, `GetOpenMainMenuSignal`, `GetUpdateRankedMenuSignal`, `Days`, `Weeks`, `Months`, `Years`, `NA`, `EU`, `LATAM`, `MENA`, `OCE`, `ASEAN`, `ASIA`, `AF`, `pcall`, `GetCountryRegionForPlayerAsync failed: `, `RankedButton`, `HistoryButton`, `StatisticsButton`, `Stats`, `Ranks`, `GLOBALFFA`, `GLOBAL1v1s`, `GLOBAL2v2 Duos`, `setmetatable`

### [904] ReplicatedStorage.Controllers.UI.RankedSelectionController.RankedSelectionController
`Script` · bytecode v9 · 787 bytes · 19 constants
- **Key API:** GetAttribute, SetAttribute
- Constants: `debug`, `setmemorycategory`, `Name`, `Start`, `script`, `Parent`, `require`, `Loaded`, `SetAttribute`, `Init`, `GetAttribute`, `GetAttributeChangedSignal`, `Wait`, `pcall`, `task`, `spawn`, `error`, `%*:Init() - %*`, `format`

### [905] ReplicatedStorage.Controllers.UI.SealCrateController
`ModuleScript` · bytecode v9 · 12484 bytes · 206 constants
- **Remotes:** Data, SetGift
- **Services:** Players, ReplicatedStorage, RunService, TweenService, game, workspace
- **Key API:** Clone, Connect, FindFirstChild, GetChildren, GetService, InvokeServer, SetAttribute, WaitForChild, new
- Constants: `math`, `floor`, `ceil`, `shorten`, `Parent`, `GetPivot`, `Value`, `CFrame`, `Angles`, `rad`, `PivotTo`, `ScaleTo`, `Lid`, `FindFirstChild`, `Main`, `Attachment`, `WorldCFrame`, `ToObjectSpace`, `GetScale`, `Instance`, `new`, `CFrameValue`, `Add`, `NumberValue`, `Heartbeat`, `Connect`, `fastTween`, `TweenInfo`, `Enum`, `EasingStyle`, `Bounce`, `identity`, `Completed`, `Wait`, `Quad`, `task`, `wait`, `DoCrateAnimation`, `IsActive`, `Views`, `GetChildren`, `Name`, `Visible`, `SealCrates`, `IsOpen`, `Open`, `lookAt`, `Position`, `workspace`, `CurrentCamera`, `Card`, `Title`, `TextLabel`, `DisplayName`, `Text`, `Vector`, `Icon`, `Image`, `fastAudio`, `rbxassetid://130120626829936`, `rbxassetid://126310880215822`, `rbxassetid://71807111169811`, `Clean`, `Activated`, `spawn`, `script`, `Rolling`, `SetAttribute`, `Darkness`, `10`, `3`, `1`, `Lock`, `tonumber`, `min`, `Model`, `tostring`, `Clone`, `delay`, `Visualize`, `rbxassetid://101020618689938`, `coroutine`, `running`, `defer`, `yield`, `Unlock`, `Close`, `Clear`, `Render`, `GetServerTimeNow`, `FFlag`, `GetInstantFFlag`, `SealCrateLuckStartTime`, `SealCrateLuckEndTime`, `HasLuck`, `getWeights`, `Rewards`, `relativeWeights`, `options`, `string`, `format`, `%.1f`, `(%.0+)$`, `gsub`, `Chance`, `%*%%`, `Free`, `???`, `updateChance`, `Reminder`, `Info`, `OPEN %* MORE FREE CRATES FOR %* SLIME CRATES`, `OpenedFreeCrateRequirement`, `OpenedFreeCrateChromaRewardAmount`, `Stock`, `LimitedStockRewardId`, `Get`, `InitialStock`, `GrandPrize`, `Left`, `%* Left`, `ValueConvertor`, `AddCommas`, `updateStock`, `Chroma`, `InvokeServer`, `SealChroma_10`, `SetGift`, `FreeCrateKillsRequirement`, `clamp`, `Bar`, `Fill`, `UDim2`, `fromScale`, `Size`, `KillCounter`, `Total`, `%*/%*`, `Character`, `Alive`, `SealCrate.FreeCrates`, `Client`, `Data`, `WaitReplion`, `LimitedStockItems`, `Crates`, `table`, `insert`, `sort`, `CrateDisplay`, `OnChange`, `Thread`, `Every`, `Label`, `%*:%*`, `Type`, `CrateOpenButton`, `Slime`, `observeReplionPath`, `SealCrate.OpenedFreeCrates`, `BigReward`, `PlaySealCrateAnimation`, `Buttons`, `Buy1`, `Buy3`, `Buy10`, `Gift`, `SealCrate.FreeCrateKills`, `Start`, `require`, `game`, `Players`, `GetService`, `LocalPlayer`, `PlayerScripts`, `WaitForChild`, `ClientLoader`, `ControllerIsolator`, `CreateRequire`, `ReplicatedStorage`, `RunService`, `TweenService`, `Common`, `MarketplaceService`, `Packages`, `Replion`, `Net`, `Shared`, `SealCrate`, `WeightRandom`, `ClientGameModules`, `GuiHandler`, `RewardInfo`, `ReplionUtils`, `Trove`, `FastUtils`, `Controllers`, `GiftingController`, `VisualizerController`, `Utils`, `StPatricksDayEventController`, `PlayerGui`, `OpenSealCrate`, `RemoteFunction`, `ClickDetector`

### [906] ReplicatedStorage.Controllers.UI.ShopController
`ModuleScript` · bytecode v9 · 89285 bytes · 745 constants
- **Remotes:** Data, Freeze, Set, SetGift, Store
- **Services:** Players, ReplicatedStorage, RunService, TweenService, game, workspace
- **Key API:** Clone, Connect, Destroy, Disconnect, FindFirstChild, Fire, FireServer, GetAttribute, GetChildren, GetService, Invoke, InvokeServer, IsA, OnClientEvent, Play, SetAttribute, WaitForChild, new
- Constants: `Client`, `Data`, `WaitReplion`, `GetLegacyInventoryPath`, `Favorites`, `Get`, `refreshFavoriteMap`, `Shop`, `IsOpen`, `_page`, `Name`, `Robux`, `SearchFrame`, `Visible`, `HideHotbar`, `ShopSearch`, `SetTag`, `InventorySearchEnabled`, `GetKey`, `CheckSearchVisibility`, `Sword`, `Base Sword`, `Explosion`, `Explosion Normal`, `isBaseItem`, `RarityOrder`, `getRarityOrder`, `Ability`, `Favorited`, `FindFirstChild`, `Clone`, `Parent`, `GetInventoryVersion`, `New`, `Stack`, `script`, `NewInventory`, `Label`, `Text`, `Lock`, `Finisher`, `SwordAccessory`, `prepareSlotTemplate`, `NameOfWeapon`, `Characters`, `NameOfAbility`, `applyItemNameLabel`, `Position`, `updateIconsLayout`, `string`, `byte`, `char`, `gsub`, `.`, `invertName`, `Type`, `Default`, `Most`, `IsFavorited`, `Alphabetical`, `InvertedAlphabeticalName`, `AlphabeticalName`, `InvertedName`, `#`, `Item`, `TradeLock`, `~`, `tostring`, `%*%*%*|%*`, `format`, `Name_`, `OriginalLayoutOrder`, `LayoutOrder`, `RAP`, `RAPKey`, `IsEnabled`, `FastGetRAP`, `Exists`, `EffectiveKey`, `Creation Date`, `CreatedAt`, `updateVirtualItemSortValues`, `KeyToItem`, `ItemToKey`, `Rarity`, `DisplayName`, `Key`, `InventoryKey`, `ExplosionConfig`, `AbilityConfig`, `CharacterConfig`, `ItemInfo`, `LowerSearchName`, `Hidden`, `AlwaysVisible`, `NonPurchaseable`, `OwnsItem`, `ItemsMatching`, `InDeleteMulti`, `ForceHide`, `Section`, `Unowned`, `lower`, `State`, `GetFilteredItemKey`, `relieve`, `buildVirtualItem`, `Unlocked`, `Find`, `ByKey`, `ByName`, `table`, `clone`, `FindItemsWithKey`, `FindItems`, `GetAttributes`, `List`, `equals`, `Set`, `N/A`, `Country`, `Unique`, `Secret`, `SessionCount`, `IsAbilityAllowed`, `isHuntPrivateServer`, `_multiDelete`, `find`, `Owned`, `_inventoryPages`, `MarkDirty`, `updateVirtualItemOwnership`, `Remove`, `setPropertyComputed`, `Add`, `Shadow`, `Enabled`, `constructCommonBindings`, `ViewportFrame`, `ClearAllChildren`, `relayoutIcons`, `x%*`, `Accessory`, `HasInteractedWithTrading`, `updateLock`, `_addToMultiDelete`, `type`, `name`, `data`, `key`, `Select`, `SetAttribute`, `Icon`, `IconLabel`, `Image`, `SetSwordIconAsViewportByName`, `Misc`, `DataFinishers`, `GetAttribute`, `Icons`, `DEFAULT_MISSING`, `GetIcon`, `GetCollection`, `remove`, `Computed`, `OnChange`, `Activated`, `Connect`, `constructSwordSlot`, `Open`, `pack`, `configData`, `Pack`, `NameLabel`, `upper`, `TitleText`, `TitleTextColor`, `TextColor3`, `Color3`, `new`, `UIGradient`, `Color`, `ColorSequence`, `TitleTextStrokeColor`, `TextStrokeColor3`, `RedirectGUI_If_Unowned`, `constructExplosionSlot`, `AbilityUpgrades`, `getCurrentIcon`, `ImageLabel`, `_selectedItem`, `updateAbilityEnabled`, `AbilityBanVoting`, `AwaitReplion`, `BannedAbilities`, `NotifyAbilityBlocked`, `Upgrade`, `UnavailableReason`, `Price`, `ImageColor3`, `GetAttributeChangedSignal`, `Red`, `isRankedMatchServer`, `task`, `spawn`, `constructAbilitySlot`, `Character`, `SetSwordIconAsViewport`, `constructCharacterSlot`, `Destroy`, `virtualScrollConstructor`, `sub`, `virtualItemMatchesSearch`, `Normal`, `ExplosionTemplates`, `UIGridLayout`, `SortOrder`, `Enum`, `Constructor`, `RefreshQueued`, `RecomputeSort`, `InvalidateAll`, `InvalidatedItems`, `_virtualItems`, `insert`, `SetItems`, `Invalidate`, `refreshNow`, `BatchDepth`, `defer`, `queueRefresh`, `math`, `max`, `favoritesChanged`, `ItemRAP`, `ClientExistCount`, `Items`, `Clean`, `bindMetricUpdates`, `HeaderTitle`, `!Random`, `Random`, `AbilityTemplate`, `Container`, `Padding`, `Layout`, `Id`, `Template`, `Sort`, `Prefix`, `Static`, `Scroll`, `ScrollingFrame`, `RandomButton`, `Trove`, `BeginBatch`, `EndBatch`, `OnDescendantChange`, `setupInventoryPage`, `registerVirtualItem`, `unregisterVirtualItem`, `_createSwordSlot`, `Order`, `_createExplosionSlot`, `_createCharacterSlot`, `_createAbilitySlot`, `_updateItemStatus`, `GamePass`, `DevProduct`, `Settings.Misc.%sRandomizer`, `.Current`, `GetExpect`, `.UseFavorites`, `UseFavoritesLabel`, `Star`, `HoverImage`, `fromRGB`, `Favorites Only: On`, `Favorites Only: Off`, `reflectRandomizerState`, `OwnedLabel`, `Upgrades`, `Disconnect`, `UpgradesInfoButton`, `ValueConvertor`, `GetRAPAsync`, `AddCommas`, `Dictionary`, `Rap`, `Coins`, `Amount`, `Inventory`, `Close`, `InfoBG`, `Delete`, `itemSelected`, `Fire`, `SubscriptionRewards`, `GetChildren`, `GamePasses`, `PriceTag`, `TextLabel`, `Purchase`, `Descriptor`, `Already purchased!`, `description`, `imageColor`, `image`, `Namer`, `displayName`, `Subscription`, `Subscribe`, `Subscriptions`, `SubscriptionInfo`, `Active`, `Already subscribed!`, `Description`, `GetEquipped`, `GetItem`, `DataAbilities`, `Could not find AbilityData for "%*"`, `assert`, `MaxUpgradePrice`, `UpgradePrice%*`, `GiftButton`, `No description found!`, `Equipped`, `Equip`, `next`, `KillRequirement1`, `KillRequirement2`, `TotalStats.Kills`, `UseLegacyUpgradeProgression`, `AbilityUpgradeProgression`, `clamp`, `NewAbilityUpgradeProgression`, `Progress`, `%*/%* Eliminations`, `Fill`, `UDim2`, `fromScale`, `Size`, `pairs`, `Description1`, `Description2`, `Description3`, `delay`, `UpgradeDesc`, `_selectionMaid`, `OnUpgradesPressed`, `NonUpgradable`, `CustomUpgrade`, `Upg`, `Upg%*`, `MaxUpgrade`, `MAX`, `custom`, `UPGRADE`, `CANNOT UPGRADE`, `AmountText`, `commify`, `PackDescription`, `unlocked`, `GetRenderedSlot`, `Equips`, `HasFinisher`, `Finishers`, `rbxassetid://15452502387`, `rbxassetid://14783051124`, `UNEQUIP`, `rbxassetid://15452544682`, `EQUIP`, `ObtainFinisher`, `OBTAIN IN %* SPINS`, `Nebula`, `NEBULA`, `SCI FI`, `AnimationStyles`, `ShowSwordAccessory`, `Base`, `AccessoryToggleable`, `AccessoryUnlockable`, `AnimationStyle`, `select`, `EQUIP %* STYLE`, `UNEQUIP ACCESSORY`, `EQUIP ACCESSORY`, `CanAwaken`, `ToAwaken`, `rbxassetid://0`, `weaponViewport`, `GetSword`, `Instance`, `BackgroundTransparency`, `_canDelete`, `UpgradeButton`, `GetExplosionIcon`, `After finishing an opponent, the ball will explode into this effect.`, `Randomizer`, `ImageLabelz`, `categoryName`, `SafeGetLegacyInventoryPath`, `Settings.Misc.%sRandomizer.Current`, `FireServer`, `ShouldShowRAP`, `---`, `ExistCount`, `Exist`, `%* Exist%*`, `ShrinkNumber`, `s`, `GiveTask`, `InventoryLimit`, `%*/%*`, `fromHSV`, `_updateInventoryLimit`, `_updateMultiDelete`, `removeItem`, `DeleteItems`, `ContentsCanvas`, `GuiObject`, `IsA`, `InventoryType`, `UIListLayout`, `Button`, `SmallerSlotColors`, `Vector`, `IsDeleteable`, `SendNotification`, `_updateMultiDeleteVisbility`, `DoCleaning`, `rbxassetid://14782684812`, `Could not find "%*!"`, `rbxassetid://14782680596`, `_loadInventoryPage`, `GoTo`, `isDungeonsMatchServer`, `isDungeonsLobbyServer`, `_currency`, `Credits`, `SetCurrency`, `_lastCurrencyChange`, `OnGuiOpen`, `OnGuiClose`, `GetPropertyChangedSignal`, `Value`, `DataExplosions`, `createDynamicSlot`, `ItemByKey`, `rebuildIndexAndSync`, `Insert`, `createInventory`, `wait`, `ChildAdded`, `xpcall`, `debug`, `traceback`, `Loaded`, `warn`, `[ShopController] Failed to lazily load %*:
%*`, `isRegionalTournamentMatch`, `Loading`, `SearchBG`, `SearchInput`, `doSearchAction`, `OnSearched`, `getPropertyState`, `WaitForChild`, `ClearTextOnFocus`, `CreateSortOptions`, `Search`, `MouseButton1Click`, `FocusLost`, `setPropertyState`, `RequestFavoriteItem`, `RemoteEvent`, `productId`, `InfoType`, `PromptPurchase`, `Product`, `VIPPlus`, `InvokeServer`, `purchaseable`, `Store`, `RequestBuyCharacter`, `RequestEquipCharacter`, `BattlepassGacha`, `SpinGacha`, `OpenView`, `ProgressiveRewards`, `OBTAIN IN SELECTION CRATE`, `BattlepassSelectionCrate`, `OBTAIN IN MERCHANT`, `MerchantFinisher`, `OBTAIN IN JACK-O-LANTERN SPINS`, `SecretUpgrade`, `error`, `Play`, `Render`, `Failed to render RAP chart`, `Failed to load RAP history. Try again later`, `SetGift`, `NewInventoryEnabled`, `checkIfExtraEnabled`, `WaitForData`, `updateItem`, `updateSelected`, `typeof`, `Check`, `count`, `reflectRandomizerVisibility`, `reflect`, `Settings.Misc.%sRandomizer.UseFavorites`, `ClaimProgressiveReward`, `Invoke`, `TargetProdctId`, `<stroke color="rgb(8, 76, 28)" thickness="%*">%*<font size="16">%*</font></stroke>`, `Buy`, `UIStroke`, `Thickness`, ``, `PriceLabel`, `updateText`, `ProductPriceLabel`, `RemoveTag`, `%s`, `FREE`, `updateProduct`, `coroutine`, `running`, `status`, `suspended`, `Thread`, `SafeCancel`, `ProgressiveRewards.Claimed`, `ProgressiveRewards.Rewards`, `JumpToIndex`, `CurrentPage`, `tonumber`, `rbxassetid://18453026315`, `rbxassetid://18468467098`, `rbxassetid://18453540357`, `rbxassetid://18468473058`, `Sounds`, `SummerPackPurchase`, `SummerPackScroll`, `TweenTime`, `RewardsList`, `Index`, `Reward`, `ProductIds`, `%*
PERMANENT`, `???`, `updateSlots`, `workspace`, `GetServerTimeNow`, `ProgressiveRewards.LastReset`, `%*`, `ResetTime`, `FormatTimeHHMMSS`, `FFlag`, `GetInstantFFlag`, `BlackFridaySaleEndTime`, `BlackFridaySaleEnabled`, `Timer`, `FormatTimeWithDaysFull`, `deactivateMultiDelete`, `activateMultiDelete`, `RequestDelete`, `PromptType`, `Single`, `Are you sure you want to delete x%* items? This cannot be undone.`, `PromptConfirmation`, `x1 %*`, `Selector`, `ItemKey`, `Are you sure you want to delete %*? This cannot be undone.`, `number`, `Not enough coins!`, `CoinReward`, `ProductId`, `RankProductsAsync`, `pcall`, `MarketplaceService:RankProductsAsync() failed: %*`, `ProductIdentifier`, `SmallCoins`, `sortShopByProductRank`, `Configs`, `ShopProductRankSorting`, `runExperiments`, `%*_Configs`, `ExplosionSkins`, `Abilities`, `SwordSkins`, `CloseButton`, `GuiButton`, `Disabled`, `VisualName`, `Bottomtext`, `Alive`, `Back`, `DataUpdatedEvent`, `OnEquip`, `Characters.CurrentlySelected`, `Characters.Unlocked`, `OnArrayInsert`, `OnArrayRemove`, `GetFFlag`, `AbilityPriceReductionEnabled`, `Settings.Misc.%*Randomizer.Current`, `ToggleFavorites`, `SummerPack`, `Main`, `UIPageLayout`, `BlackFridaySale`, `Every`, `Buttons`, `Cancel`, `OnClientEvent`, `IsStudio`, `PlayerConfigs`, `OnReplionAddedWithTag`, `Start`, `require`, `game`, `Players`, `GetService`, `LocalPlayer`, `PlayerScripts`, `ClientLoader`, `ControllerIsolator`, `CreateRequire`, `ReplicatedStorage`, `LocalizationService`, `TweenService`, `RunService`, `Packages`, `Replion`, `Net`, `Freeze`, `Shared`, `Signal`, `ClientGameModules`, `TextUtility`, `Common`, `GeolocationWhitelist`, `ReplicatedInstances`, `Swords`, `Utils`, `Maid`, `LimitedSwordEvent`, `FFlagClient`, `ServerInfo`, `CustomMode`, `CustomModeUtils`, `AbilityController`, `GiftingController`, `ReducedAbilityPrices`, `Controllers`, `AnalyticsController`, `HotbarController`, `UI`, `HUDController`, `GuiHandler`, `MarketplaceService`, `CreatePriceLabel`, `UIStateController`, `GachaItemsData`, `Battlepass`, `BattlepassViewController`, `Internal`, `Limits`, `InventoryTypes`, `Trading`, `TradeTokensController`, `ProgressiveRewardsData`, `ReplionUtils`, `NotificationController`, `RAPChartController`, `RAPController`, `TradeInfo`, `DefaultItems`, `DeleteItemPromptController`, `DeleteItemUtils`, `HoverInfoController`, `Statable`, `InventoryController`, `ShopControllerAPI`, `ExistCounterController`, `GenericGachaController`, `SwordAccessories`, `ABTestController`, `SectionedVirtualScroll`, `Reliever`, `ConfigureRandomizerEvent`, `SecretAwaken`, `RequestEquipFinisher`, `RemoteFunction`, `EquipSwordAccessory`, `RequestChangeAnimationStyle`, `RequestEquipAbility`, `RequestEquipSword`, `RequestEquipExplosion`, `RequestAbilityUpgrade`, `RequestBuyAbility`, `OpenCoinsTab`, `Rare`, `Legendary`, `Limited`, `LimitedU`, `MedCoins`, `BigCoins`, `HugeCoins`, `MassiveCoins`, `FastUnbox`, `VIP`, `2xCoins`, `TradingSign`, `rbxassetid://15697987058`, `rbxassetid://15697983062`, `rbxassetid://15697981750`, `IsCustomModeServer`, `IsMultiplayerCustomMode`, `Emote`, `PlayerGui`, `SwordTemplates`, `FavoritedTemplate`, `Hotbar`, `Holder`, `Pages`, `FrameSelectionButtons`, `ExtraBtns`, `Extra`, `BuyButton`, `Favorite`, `KillsProgressBar`, `RapButton`, `RandomizerInfo`, `ToggleRandom`, `InviteRewardsHolder`, `EquipAccessory`, `ChangeStyle`, `Remotes`, `Least`

### [907] ReplicatedStorage.Controllers.UI.ShopController.ShopController
`Script` · bytecode v9 · 787 bytes · 19 constants
- **Key API:** GetAttribute, SetAttribute
- Constants: `debug`, `setmemorycategory`, `Name`, `Start`, `script`, `Parent`, `require`, `Loaded`, `SetAttribute`, `Init`, `GetAttribute`, `GetAttributeChangedSignal`, `Wait`, `pcall`, `task`, `spawn`, `error`, `%*:Init() - %*`, `format`

### [908] ReplicatedStorage.Controllers.UI.ShopControllerAPI
`ModuleScript` · bytecode v9 · 18626 bytes · 202 constants
- **Remotes:** Data, Set
- **Services:** Players, ReplicatedStorage, RunService, UserInputService, game
- **Key API:** Connect, Disconnect, FindFirstChild, FireServer, GetService, InvokeServer, WaitForChild
- Constants: `table`, `find`, `Get`, `finds`, `Set`, `type`, `concat`, `.`, `State`, `OnChange`, `_conn`, `getReplionArrayPresenceState`, `getValue`, `typeof`, `insert`, `string`, `getReplionDictionaryPresenceState`, `clone`, `Id`, `ItemType`, `ItemToKey`, `parseItemKey`, `KeyToItem`, `ParseItemKey`, `GetItemBaseOwnedState`, `GetEquipped`, `GetItem`, `GetEquippedItem`, `Sword`, `FindItemsWithKey`, `SetTag`, `updateCopies`, `updateFavorited`, `IsEnabled`, `FastGetRAP`, `Name`, `ShouldShowRAP`, `updateRAP`, `Finisher`, `OnInventoryChange`, `Computed`, `Client`, `Data`, `WaitReplion`, `GetLegacyInventoryPath`, `Favorites`, `Finishers.Equipped`, `GetFilteredItemKey`, `OnRAPUpdated`, `ItemInfo`, `ParsedItemKey`, `RAP`, `OwnedCopies`, `IsEquipped`, `IsFavorited`, `IsFinisherEquipped`, `HasAccessory`, `AccessoryUnlockable`, `Accessory`, `GetSwordData`, `Explosion`, `GetExplosionData`, `Ability`, `Upgrade`, `MaxUpgrade`, `GetAbilityData`, `Emote`, `GetEmoteData`, `Booth`, `FindItems`, `GetBoothData`, `Insert`, `Remove`, `Change`, `Disconnect`, `ObserveItemsStates`, `Attributes`, `Price`, `MaxUpgradePrice`, `UpgradePrice%*`, `format`, `GetAbilityUpgradePrice`, `DevProduct`, `ProductInfo`, `GetDevProductData`, `GamePass`, `Owns`, `GamePasses`, `GetGamePassData`, `GetItemData`, `ItemInfos`, `pcall`, `warn`, `Failed to whitelistFilter
%*`, `GetItemsList`, `GetItemInfo`, `InvokeServer`, `RequestAbilityUpgrade`, `RequestAbilityPurchase`, `RequestFinisherEquip`, `SetEquipped`, `RequestFavoriteItem`, `RemoteEvent`, `FireServer`, `ToggleFavorited`, `EquipSwordAccessory`, `ToggleSwordAccessory`, `RequestChangeAnimationStyle`, `ToggleSwordStyle`, `Enabled`, `Open`, `Close`, `Default`, `script`, `Variants`, `ActiveVariant`, `Start`, `Shop`, `OnGuiOpen`, `OnGuiClose`, `GetPropertyChangedSignal`, `Connect`, `Load`, `OpenRobuxPage`, `updateEquipped`, `GetEquippedList`, `Inventory`, `OnEquip`, `IsTenFootInterface`, `Enum`, `UserInputType`, `IsStudio`, `Gamepad2`, `Gamepad1`, `GetGamepadConnected`, `FindFirstChild`, `game`, `GameId`, `Console`, `TouchEnabled`, `Mobile`, `require`, `Players`, `GetService`, `LocalPlayer`, `PlayerScripts`, `WaitForChild`, `ClientLoader`, `ControllerIsolator`, `CreateRequire`, `ReplicatedStorage`, `RunService`, `GuiService`, `UserInputService`, `PlayerGui`, `ForceVariant`, `Shared`, `Packages`, `Replion`, `Net`, `Promise`, `Controllers`, `AnalyticsController`, `ClientGameModules`, `GuiHandler`, `ReplicatedInstances`, `Swords`, `Statable`, `CustomMode`, `CustomModeUtils`, `AbilityController`, `Common`, `MarketplaceService`, `InventoryTypes`, `DynArgs`, `Trading`, `RAPController`, `ServerInfo`, `IsCustomModeServer`, `IsMultiplayerCustomMode`, `isHuntPrivateServer`, `NewShop`, `Holder`, `RequestEquipAbility`, `RemoteFunction`, `RequestEquipSword`, `RequestEquipExplosion`, `RequestEquipFinisher`, `RequestBuyAbility`, `Or`, `LinkState`, `OwnedBases`, `IsSinglePlayerMode`, `Normal`, `Duo`, `Rare`, `Legendary`, `Limited`, `LimitedU`, `Unique`, `Secret`, `RarityOrder`

### [909] ReplicatedStorage.Controllers.UI.ShopControllerAPI.ForceVariant
`ModuleScript` · bytecode v9 · 549 bytes · 17 constants
- **Services:** ReplicatedStorage, RunService, UserInputService, game
- **Key API:** GetService, WaitForChild
- Constants: `game`, `ReplicatedStorage`, `GetService`, `require`, `UserInputService`, `WaitForChild`, `RunService`, `ServerInfo`, `isTestGame`, `Enum`, `UserInputType`, `IsStudio`, `Gamepad2`, `Gamepad1`, `GetGamepadConnected`, `Console`

### [910] ReplicatedStorage.Controllers.UI.ShopControllerAPI.ShopControllerAPI
`Script` · bytecode v9 · 787 bytes · 19 constants
- **Key API:** GetAttribute, SetAttribute
- Constants: `debug`, `setmemorycategory`, `Name`, `Start`, `script`, `Parent`, `require`, `Loaded`, `SetAttribute`, `Init`, `GetAttribute`, `GetAttributeChangedSignal`, `Wait`, `pcall`, `task`, `spawn`, `error`, `%*:Init() - %*`, `format`

### [911] ReplicatedStorage.Controllers.UI.ShopControllerAPI.Signal
`ModuleScript` · bytecode v9 · 3717 bytes · 47 constants
- **Key API:** Connect, Destroy, Disconnect, Fire, Once, new
- Constants: `acquireRunnerThreadAndCallEventHandler`, `coroutine`, `yield`, `runEventHandlerInFreeThread`, `Connected`, `_signal`, `_fn`, `_next`, `setmetatable`, `new`, `_handlerListHead`, `Disconnect`, `error`, `Attempt to get Connection::%s (not a valid member)`, `tostring`, `format`, `__index`, `Attempt to set Connection::%s (not a valid member)`, `__newindex`, `_proxyHandler`, `Fire`, `typeof`, `RBXScriptSignal`, `Argument #1 to Signal.Wrap must be a RBXScriptSignal; got `, `assert`, `Connect`, `Wrap`, `type`, `table`, `getmetatable`, `Is`, `Once`, `insert`, `GetConnections`, `DisconnectAll`, `create`, `resume`, `task`, `spawn`, `defer`, `FireDeferred`, `running`, `Wait`, `rawget`, `Destroy`, `Attempt to get Signal::%s (not a valid member)`, `Attempt to set Signal::%s (not a valid member)`

### [912] ReplicatedStorage.Controllers.UI.ShopControllerAPI.Variants.Console
`ModuleScript` · bytecode v9 · 61830 bytes · 565 constants
- **Remotes:** Data, Freeze, Set, SetGift
- **Services:** ContextActionService, Players, ReplicatedStorage, game, workspace
- **Key API:** Clone, Connect, Destroy, FindFirstChild, FireServer, GetAttribute, GetChildren, GetService, Invoke, IsA, Play, SetAttribute, WaitForChild, new
- Constants: `All`, `OwnedCopies`, `Owned`, `Unowned`, `Sword`, `GetEquippedItem`, `Name`, `Base Sword`, `ParseItemKey`, `GetItemData`, `Set`, `Ability`, `Dash`, `Explosion`, `Explosion Normal`, `SetSelectedItems`, `ControllerShop`, `Open`, `Hide`, `Close`, `Enum`, `CoreGuiType`, `Chat`, `Show`, `SwitchPage`, `Robux`, `OpenRobuxPage`, `typeof`, `Color3`, `TextColor3`, `new`, `UIGradient`, `FindFirstChildWhichIsA`, `Instance`, `Color`, `applyColor`, `Get`, `UpdateItem`, `UIListLayout`, `Template`, `Clone`, `Button`, `Item`, `Vector`, `ItemInfo`, `Icon`, `Image`, `Label`, `DisplayName`, `Text`, `Parent`, `Activated`, `Connect`, `Visible`, `x%*`, `format`, `update`, `__deletingItemsConn`, `UpdateDeletingItems`, `State`, `GetDeletingItemState`, `useOwnedCopies`, `GET_FN`, `getOwnedCopies`, `PageInfo`, `PageName`, `ItemState`, `ItemType`, `ParsedItemKey`, `FindItemsWithKey`, `SetEquipped`, `Pack`, `Menu`, `RequestAbilityPurchase`, `IsInventorey`, `DevProduct`, `ProductId`, `InfoType`, `Product`, `PromptPurchase`, `GamePass`, `Owns`, `EquipCurrent`, `Upgrade`, `CustomUpgrade`, `RequestAbilityUpgrade`, `KeyToItem`, `GetAbilityData`, `SetGift`, `GiftName`, `UpgradeCurrent`, `NonUpgradable`, `Equip`, `IsEquipped`, `Equipped`, `Price`, `Purchase for %* Coins`, `Attributes`, `Description%*`, `FindFirstChild`, `UpgradeInfo`, `UpgradeDesc`, `OwnedLabel`, `MaxUpgrade`, `UDim2`, `fromScale`, `Size`, `Position`, `Destroy`, `MidUpgrade`, `Max`, `ImageLabel`, `UpgradeCost`, `GetAbilityUpgradePrice`, `KillRequirements`, `UseLegacyUpgradeProgression`, `getReplionPathState`, `DataReplion`, `TotalStats.Kills`, `AbilityUpgradeProgression.%*`, `math`, `clamp`, `NewAbilityUpgradeProgression.%*`, `Progress`, `%*/%* Elims`, `Fill`, `Templates`, `AbilityUpgradeTemplate`, `LayoutOrder`, `rbxassetid://15645666568`, `ToggleFavorited`, `IsFavorited`, `rbxassetid://15697987058`, `rbxassetid://15697983062`, `pairs`, `isHuntPrivateServer`, `Dictionary`, `count`, `updateShuffle`, `Shuffle`, `SetTag`, `Abilities`, `FireServer`, `Settings.Misc.AbilitiesRandomizer.UseFavorites`, `GetExpect`, `Settings.Misc.AbilitiesRandomizer`, `Current`, `UseFavorites`, `Checkmark`, `UseFavoritesLabel`, `Star`, `HoverImage`, `fromRGB`, `          Favorites Only: On`, `          Favorites Only: Off`, `Pages`, `WaitForChild`, `Right`, `EquipButton`, `UpgradeButton`, `Upgrades`, `ArrowButton`, `Favorite`, `UpgradesInfo`, `PurchaseButton`, `KillsProgressBar`, `Computed`, `animateButtonClick`, `RandomizerView`, `FrameUI`, `Scrolling`, `!!!Shuffle`, `OnInventoryChange`, `SelectedAbilityHandler`, `SecretUpgrade`, `SwordSkins`, `Settings.Misc.SwordSkinsRandomizer.UseFavorites`, `Settings.Misc.SwordSkinsRandomizer`, `CanAwaken`, `ToAwaken`, `SetAttribute`, `AccessoryToggleable`, `HasAccessory`, `getAttributeState`, `ShowSwordAccessory`, `Unequip Accessory`, `Equip Accessory`, `UIStroke`, `rbxassetid://15452502387`, `rbxassetid://15452544682`, `rbxassetid://14783051124`, `ToggleSwordAccessory`, `AnimationStyles`, `Accessory`, `Base`, `Default`, `AnimationStyle`, `table`, `find`, `select`, `next`, `EQUIP %* STYLE`, `string`, `upper`, `ToggleSwordStyle`, `HasFinisher`, `Finisher`, `IsFinisherEquipped`, `Unequip Finisher`, `Equip Finisher`, `ObtainFinisher`, `rbxassetid://15790014217`, `rbxassetid://15790016390`, `Unobtainable`, `RequestFinisherEquip`, `FinisherUI`, `SetSwordIconAsViewportByName`, `ItemIcon`, `ItemViewport`, `Add`, `Buttons`, `SubButtons`, `AccessoryButton`, `StyleButton`, `FinisherButton`, `SelectedSwordHandler`, `Btn`, `ExplosionSkins`, `Settings.Misc.ExplosionSkinsRandomizer.UseFavorites`, `Settings.Misc.ExplosionSkinsRandomizer`, `ItemTitle`, `SelectedExplosion`, `CoinReward`, `AddCommas`, `Purchase`, `Purchased`, `SelectedRobux`, `Desc`, `AltIcon`, `Description`, `GeneralHandler`, `Rap`, `Coins`, `Amount`, `---`, `IsEnabled`, `ShouldShowRAP`, `ValueConvertor`, `RAP`, `ExistCount`, `%* Exist%*`, `ShrinkNumber`, `s`, `SetupPageRight`, `Settings.Misc.SwordSkinsRandomizer.Current`, `updateExistCounter`, `Client`, `ClientExistCount`, `WaitReplion`, `OnUpdated`, `byte`, `char`, `SortDirection`, `Ascending`, `#`, `%*%*|%*`, `Exists`, `Creation Date`, `CreatedAt`, `Hidden`, `AlwaysVisible`, `Stack`, `SwordTemplate`, `ViewportFrame`, `ItemName`, `Rarity`, `Normal`, `ImageColor3`, `Misc`, `DataFinishers`, `script`, `NewInventory`, `GetAttribute`, `Icons`, `DEFAULT_MISSING`, `GetIcon`, `SwordAccessory`, `setPropertyComputed`, `task`, `spawn`, `lower`, `gsub`, `.`, `RarityOrder`, `%*%*`, `OriginalLayoutOrder`, `RenderSword`, `Settings.Misc.ExplosionSkinsRandomizer.Current`, `ExplosionTemplate`, `Title`, `StrokeColor`, `TextStrokeColor3`, `GetExplosionIcon`, `RenderExplosion`, `Settings.Misc.AbilitiesRandomizer.Current`, `IsAllowed`, `Red`, `Active`, `AbilityTemplate`, `GetAbilityIcon`, `ItemLevel`, `Lv. %s`, `tostring`, `Order`, `RenderAbility`, `DevProductTemplate`, `TitleText`, `CoinAmount`, `%d Coins`, `Medium`, `Big`, `rbxassetid://15645383004`, `rbxassetid://15645383170`, `Massive`, `Huge`, `rbxassetid://15645401974`, `rbxassetid://15645402097`, `Cost`, `:robux: %s`, `Itemicon`, `Items`, `RenderDevProduct`, `GamePassTemplate`, `ItemPrice`, `RenderGamePass`, `AlwaysShow`, `OwnedBases`, `defer`, `HasInteractedWithTrading`, `IsDeleteable`, `SendNotification`, `You don't own this item!`, `sub`, `warn`, `Player owns non-existent sword "%*"`, `insert`, `concat`, `|`, `TradeLock`, `Value`, `Lock`, `animateButtonHover`, `RenderSlot`, `HandlePageChange`, `GetCurrentPage`, `max`, `rbxassetid://15643806432`, `rbxassetid://15643737651`, `getPropertyState`, `Enabled`, `ScrollingEnabled`, `Input`, `Box`, `PagesSearchs`, `updateInput`, `rbxassetid://18123223527`, `rbxassetid://18123248161`, `rbxassetid://18123872657`, `rbxassetid://18123874724`, `Descending`, `Alphabetical`, `UIGridLayout`, `SortOrder`, `Sort`, `Arrow`, `Rotation`, `List`, `GetChildren`, `IsA`, `ImageTransparency`, `IsOpen`, `ContextActionResult`, `Pass`, `UserInputState`, `Begin`, `KeyCode`, `ButtonR2`, `Sink`, `ButtonR1`, `floor`, `wait`, `Unlock`, `GiftingUI`, `ClaimProgressiveReward`, `Invoke`, `error`, `Play`, `TargetProdctId`, `<stroke color="rgb(8, 76, 28)" thickness="%*">%*<font size="16">%*</font></stroke>`, `Buy`, `Thickness`, ``, `PriceLabel`, `updateText`, `ProductPriceLabel`, `RemoveTag`, `%s`, `FREE`, `updateProduct`, `coroutine`, `running`, `status`, `suspended`, `Thread`, `SafeCancel`, `ProgressiveRewards.Claimed`, `ProgressiveRewards.Rewards`, `JumpToIndex`, `CurrentPage`, `tonumber`, `rbxassetid://18453026315`, `rbxassetid://18468467098`, `rbxassetid://18453540357`, `rbxassetid://18468473058`, `Sounds`, `SummerPackPurchase`, `delay`, `SummerPackScroll`, `TweenTime`, `print`, `RewardsList`, `Type`, `Index`, `Reward`, `ProductIds`, `%*
PERMANENT`, `???`, `updateSlots`, `workspace`, `GetServerTimeNow`, `ProgressiveRewards.LastReset`, `%*`, `ResetTime`, `FormatTimeHHMMSS`, `FFlag`, `GetInstantFFlag`, `BlackFridaySaleEndTime`, `BlackFridaySaleEnabled`, `Timer`, `FormatTimeWithDaysFull`, `Render`, `Failed to render RAP chart`, `Failed to load RAP history. Try again later`, `RequestDelete`, `PromptType`, `Single`, `Are you sure you want to delete x%* items? This cannot be undone.`, `PromptConfirmation`, `Data`, `Top`, `Tabs`, `CoinValue`, `ConsoleKeys`, `L1`, `R1`, `Circle`, `GuiButton`, `PopUpTokensBuy`, `Frame`, `setPropertyState`, `SearchFrame`, `Changed`, `Search`, `GuiObject`, `Delete`, `Sorting`, `L2`, `R2`, `Gift`, `ConsoleShopTabChanged`, `ButtonL2`, `BindActionAtPriority`, `ConsoleShopPurchaseButton`, `ButtonX`, `ConsoleShopUpgradeButton`, `ButtonY`, `ConsoleShopInnerTabChanged`, `ButtonL1`, `Credits`, `OnChange`, `OnGuiClose`, `ObserveItemsStates`, `IsSinglePlayerMode`, `SummerPack`, `Main`, `UIPageLayout`, `GetPropertyChangedSignal`, `GetAttributeChangedSignal`, `BlackFridaySale`, `Every`, `RapButton`, `Cancel`, `Start`, `game`, `ReplicatedStorage`, `GetService`, `Players`, `require`, `Common`, `MarketplaceService`, `LocalPlayer`, `ContextActionService`, `Packages`, `Net`, `Utils`, `Utilities`, `Trove`, `Freeze`, `Replion`, `Shared`, `DynArgs`, `ClientGameModules`, `CoreCall`, `Statable`, `Observers`, `Inventory`, `GuiHandler`, `ServerInfo`, `GachaItemsData`, `InventoryTypes`, `DeleteItemUtils`, `CreatePriceLabel`, `Controllers`, `HoverInfoController`, `Trading`, `TradeTokensController`, `ProgressiveRewardsData`, `NotificationController`, `DeleteItemPromptController`, `UiPresets`, `UI`, `HUDController`, `GiftingController`, `HalloweenGachaNPCController`, `RAPController`, `RAPChartController`, `ExistCounterController`, `PlayerGui`, `DeleteItems`, `ContentsCanvas`, `ScrollingFrame`, `Or`, `LinkState`, `AddStatable`, `Limited`, `LimitedU`, `Rare`, `Legendary`, `Unique`, `rbxassetid://15697981750`, `ConfigureRandomizerEvent`, `RemoteEvent`, `FrameUIHiddenDynArgs`, `ItemTypesTemplates`

### [913] ReplicatedStorage.Controllers.UI.ShopControllerAPI.Variants.Default
`ModuleScript` · bytecode v9 · 7896 bytes · 124 constants
- **Remotes:** Set
- **Services:** Players, ReplicatedStorage, game
- **Key API:** Clone, Connect, Destroy, FindFirstChild, GetChildren, GetService, IsA, WaitForChild, new
- Constants: `typeof`, `Color3`, `TextColor3`, `new`, `UIGradient`, `FindFirstChildWhichIsA`, `Instance`, `Color`, `applyColor`, `NewShop`, `Open`, `Close`, `SwitchPage`, `Owns`, `List`, `Owned`, `Unowned`, `Parent`, `Sword`, `Set`, `IsFavorited`, `Visible`, `Name`, `Base Sword`, `Rarity`, `LayoutOrder`, `Hidden`, `AlwaysVisible`, `Explosion`, `Destroy`, `ItemInfo`, `ItemType`, `Template`, `FindFirstChild`, `Clone`, `Add`, `Favorited`, `NameOfWeapon`, `DisplayName`, `Text`, `Computed`, `Activated`, `Connect`, `setPropertyComputed`, `ViewportFrame`, `SetSwordIconAsViewportByName`, `Order`, `NameOfExplosion`, `Title`, `StrokeColor`, `TextStrokeColor3`, `SubText`, `ImageLabel`, `Icon`, `Image`, `RenderSlot`, `Active`, `Get`, `SetEquipped`, `ToggleFavorited`, `Upgrade`, `TargetPage`, `Description`, `IconLabel`, `UDim2`, `Size`, `View`, `Favorite`, `Equip`, `PriceTag`, `TextLabel`, `IsEquipped`, `Equipped`, `UpgradeLevel`, `Upgrades`, `Label`, `MAX`, `Pages`, `GetChildren`, `Frame`, `IsA`, `Tabs`, `GetItemsList`, `GetItemData`, `Start`, `game`, `ReplicatedStorage`, `GetService`, `Players`, `LocalPlayer`, `require`, `ClientGameModules`, `GuiHandler`, `Packages`, `Trove`, `Common`, `Utils`, `Utilities`, `Icons`, `Shared`, `Statable`, `script`, `PlayerGui`, `WaitForChild`, `Holder`, `FavoritedTemplate`, `Swords`, `Info`, `Normal`, `Explosions`, `ExplosionTemplate`, `State`, `Rare`, `Legendary`, `Limited`, `LimitedU`, `Unique`, `rbxassetid://15697987058`, `HoverImage`, `rbxassetid://15697983062`, `rbxassetid://15697981750`, `rbxassetid://14782680596`, `rbxassetid://14782685409`, `rbxassetid://14782684812`

### [914] ReplicatedStorage.Controllers.UI.ShopControllerAPI.Variants.Mobile
`ModuleScript` · bytecode v9 · 20597 bytes · 258 constants
- **Remotes:** Data, Set, SetGift
- **Services:** ContextActionService, Players, ReplicatedStorage, game
- **Key API:** Clone, Connect, Destroy, FindFirstChild, GetChildren, GetService, IsA, SetAttribute, WaitForChild, new
- Constants: `Base Sword`, `DataReplion`, `SwordSkins`, `CurrentlySelected`, `Get`, `Sword`, `Swords`, `GetSwordData`, `Set`, `Dash`, `Abilities`, `Ability`, `GetAbilityData`, `Explosion Normal`, `ExplosionSkins`, `Explosion`, `Explosions`, `GetExplosionData`, `SetSelectedItems`, `MobileShop`, `Open`, `Hide`, `Enum`, `CoreGuiType`, `Chat`, `Close`, `Show`, `typeof`, `Color3`, `TextColor3`, `new`, `UIGradient`, `FindFirstChildWhichIsA`, `Instance`, `Color`, `applyColor`, `warn`, `Setting Page too`, `SetCurrentPage`, `Owns`, `Visible`, `ItemInfo`, `Upgrade`, `NonUpgradable`, `Frame`, `Icon`, `Equip`, `IsEquipped`, `Equipped`, `Text`, `Price`, `Destroy`, `CustomUpgrade`, `?`, `UpgradeLevel`, `MaxUpgrade`, `UpgradeCost`, `Max`, `UpgradePrice`, `Templates`, `AbilityUpgradeTemplate`, `Clone`, `LayoutOrder`, `rbxassetid://15645666568`, `Image`, `Parent`, `UpgradeInfo`, `AbilityUpgradeInfoTemplate`, `fade`, `TextLabel`, `Upgrade `, `Upgrades`, `ScrollingFrame`, `Black`, `RequestAbilityPurchase`, `SetEquipped`, `TimeHole`, `OpenPhantomUpgrade`, `RequestAbilityUpgrade`, `WaitForChild`, `Right`, `Btns`, `UpgradeButton`, `ArrowButton`, `Computed`, `animateButtonClick`, `Activated`, `Connect`, `SelectedAbilityHandler`, `HasFinisher`, `OwnsFinisher`, `Label`, `OBTAIN IN SCI FI SPINS`, `IsFinisherEquipped`, `Unequip`, `HasAwaken`, `SciFiGacha`, `RequestFinisherEquip`, `ToAwaken`, `Name`, `SetAttribute`, `SetSwordIconAsViewportByName`, `ItemIcon`, `ItemViewport`, `Add`, `Pages`, `PurchaseButton`, `FinisherButton`, `SecretUpgrade`, `SelectedSwordHandler`, `Title`, `UIStroke`, `StrokeColor`, `ItemTitle`, `SelectedExplosion`, `Desc`, `Attributes`, `AltIcon`, `Description`, `DisplayName`, `GeneralHandler`, `PageInfo`, `PageName`, `ItemState`, `SetupPageRight`, `Rarity`, `math`, `abs`, `IsFavorited`, `rbxassetid://15697987058`, `rbxassetid://15697983062`, `ToggleFavorited`, `Hidden`, `AlwaysVisible`, `EquipButton`, `Favorite`, `setPropertyComputed`, `ViewportFrame`, `ItemName`, `Normal`, `ImageColor3`, `Items`, `RenderSword`, `UDim2`, `fromScale`, `ItemSubText`, `SubText`, `Position`, `GetExplosionIcon`, `RenderExplosion`, `string`, `format`, `Lv. %d`, `Order`, `ItemLevel`, `Limited`, `RenderAbility`, `ProductInfo`, ` %d`, `PriceInRobux`, `PRICE_UNAVALIABLE!`, `SetGift`, `ProductId`, `InfoType`, `Product`, `PromptPurchase`, `CoinAmount`, `CoinReward`, `BuyButton`, `GiftButton`, `DEFAULT_MISSING`, `GetIcon`, `Coins`, `RenderDevProduct`, `GiftName`, `Purchased`, `LocalPlayer`, `PromptGamePassPurchase`, `GamePass`, `Fade`, `Passes`, `RenderGamePass`, `ItemType`, `Template`, `animateButtonHover`, `DevProduct`, `RenderSlot`, `HandlePageChange`, `rbxassetid://15643806432`, `rbxassetid://15643737651`, `rbxassetid://14782685409`, `HoverImage`, `task`, `wait`, `Lock`, `Unlock`, `GiftingUI`, `IsOpen`, `AddCommas`, `isElementalServer`, `Data`, `WaitReplion`, `Tabs`, `Money`, `fromRGB`, `GetChildren`, `IsA`, `FindFirstChild`, `OnGuiClose`, `Credits`, `OnChange`, `GetItemsList`, `GetItemData`, `Start`, `game`, `ReplicatedStorage`, `GetService`, `Players`, `require`, `Common`, `MarketplaceService`, `ContextActionService`, `ClientGameModules`, `GuiHandler`, `Packages`, `Replion`, `Client`, `Trove`, `Utils`, `Utilities`, `Icons`, `Shared`, `Statable`, `CoreCall`, `ValueConvertor`, `ServerInfo`, `script`, `Controllers`, `GiftingController`, `UI`, `HUDController`, `HalloweenGachaNPCController`, `UiPresets`, `Trading`, `TradeTokensController`, `PlayerGui`, `Main`, `State`, `Rare`, `Legendary`, `LimitedU`, `Unique`, `Secret`, `SwordTemplate`, `ExplosionTemplate`, `AbilityTemplate`, `DevProductTemplate`, `GamePassTemplate`

### [915] ReplicatedStorage.Controllers.UI.ShopPurchaseAbilityTutorialController
`ModuleScript` · bytecode v9 · 3924 bytes · 89 constants
- **Remotes:** Data, Freeze, OnPlayerKilled, RoundEnded
- **Services:** Players, ReplicatedStorage, TweenService, game, workspace
- **Key API:** Clone, Connect, Destroy, FireServer, GetService, OnClientEvent, Once, WaitForChild, new
- Constants: `script`, `Arrow`, `Clone`, `Visible`, `ImageTransparency`, `Parent`, `CreateArrowOnElement`, `CheckPoints`, `CurrentCheckPoint`, `CheckPointTrove`, `Destroy`, `FireServer`, `typeof`, `function`, `SetTutorialCheckPoint`, `name`, `Invisibility`, `AbilitySelected`, `AbilityShopOpened`, `itemSelected`, `Connect`, `Start`, `StartTutorial`, `Replion`, `Credits`, `Get`, `Ability`, `FindItems`, `Dictionary`, `count`, `AbilityTutorialCheckPoint`, `Finished`, `BoughtDifferentAbility`, `FinishedDidNotEquip`, `AbilityTutorialEnabled`, `GetRemoteConfigValue`, `andThen`, `CheckTutorialEligibility`, `workspace`, `Dead`, `Humanoid`, `FindFirstChildOfClass`, `Health`, `table`, `find`, `allParticipantsEver`, `LocalPlayer`, `Character`, `CharacterAdded`, `Wait`, `AncestryChanged`, `Once`, `Remotes`, `RoundEnded`, `OnPlayerKilled`, `Client`, `Data`, `WaitReplion`, `OnClientEvent`, `require`, `game`, `Players`, `GetService`, `PlayerScripts`, `WaitForChild`, `ClientLoader`, `ControllerIsolator`, `CreateRequire`, `ReplicatedStorage`, `TweenService`, `Packages`, `Net`, `Signal`, `Trove`, `ClientGameModules`, `GuiHandler`, `Controllers`, `UI`, `ShopController`, `AnalyticsController`, `Shared`, `Inventory`, `Freeze`, `GameId`, `PlayerGui`, `TUTORIAL_CHECKPOINT_STARTED`, `RemoteEvent`, `new`, `TutorialFinishedTrove`

### [916] ReplicatedStorage.Controllers.UI.ShopPurchaseAbilityTutorialController.CheckPoints
`ModuleScript` · bytecode v9 · 4582 bytes · 80 constants
- **Remotes:** Data
- **Services:** Players, ReplicatedStorage, TweenService, game, workspace
- **Key API:** Connect, Create, GetService, Play, WaitForChild, new
- Constants: `AbilityShopOpened`, `SetTutorialCheckPoint`, `workspace`, `Alive`, `RoundStarted`, `Character`, `HUD`, `WaitForChild`, `LeftFrame`, `Middle`, `ShopPage`, `properties`, `CreateArrowOnElement`, `Add`, `TweenInfo`, `new`, `Enum`, `EasingStyle`, `Quad`, `EasingDirection`, `In`, `Position`, `UDim2`, `fromScale`, `Create`, `Play`, `Shop`, `OnGuiOpen`, `AncestryChanged`, `Connect`, `name`, `Invisibility`, `AbilitySelected`, `BoughtDifferentAbility`, `Holder`, `Pages`, `Ability`, `Unowned`, `InfoBG`, `BuyButton`, `Client`, `Data`, `WaitReplion`, `GoTo`, `Rotation`, `AbsolutePosition`, `Y`, `AbsoluteSize`, `Abilities`, `CanvasPosition`, `Vector2`, `itemSelected`, `OnChange`, `EquipAbility`, `Size`, `Activated`, `FinishedDidNotEquip`, `Finished`, `OnGuiClose`, `game`, `Players`, `GetService`, `ReplicatedStorage`, `TweenService`, `require`, `Packages`, `Replion`, `Signal`, `Shared`, `Inventory`, `ClientGameModules`, `GuiHandler`, `Controllers`, `UI`, `ShopController`, `script`, `Parent`, `LocalPlayer`, `PlayerGui`, `Start`

### [917] ReplicatedStorage.Controllers.UI.SoftShutdownController
`ModuleScript` · bytecode v9 · 4114 bytes · 82 constants
- **Services:** Players, ReplicatedStorage, RunService, StarterGui, game, workspace
- **Key API:** Connect, Disconnect, GetAttribute, GetChildren, GetService, IsA, WaitForChild, new
- Constants: `target`, `animateObject`, `SetCoreGuiEnabled`, `_lastChange`, `_logoConn`, `Disconnect`, `Enabled`, `tick`, `math`, `sin`, `LoadingLabel`, `RobloxLogo`, `Rotation`, `_isVisible`, `workspace`, `GetServerTimeNow`, `TouchControlsEnabled`, `GetChildren`, `ScreenGui`, `IsA`, `_screenGuiStates`, `task`, `spawn`, `UIScale`, `Scale`, `Size`, `BackgroundTransparency`, `ImageLabelContainer`, `ImageLabel`, `ImageTransparency`, `LabelContainer`, `TitleLabel`, `TextTransparency`, `SubtitleLabel`, `Frame`, `completed`, `RenderStepped`, `Connect`, `SetVisible`, `IsServerClosing`, `GetAttribute`, `GetAttributeChangedSignal`, `Start`, `require`, `game`, `Players`, `GetService`, `LocalPlayer`, `PlayerScripts`, `WaitForChild`, `ClientLoader`, `ControllerIsolator`, `CreateRequire`, `script`, `RunService`, `ReplicatedStorage`, `GuiService`, `StarterGui`, `Packages`, `Trove`, `Common`, `Utils`, `Spring`, `Enum`, `CoreGuiType`, `PlayerList`, `Health`, `Backpack`, `Chat`, `EmotesMenu`, `All`, `PlayerGui`, `SoftShutdown`, `Holder`, `ContentContainer`, `Instance`, `new`, `BlurEffect`, `SoftShutdownBlue`, `Name`, `CurrentCamera`, `Parent`

### [918] ReplicatedStorage.Controllers.UI.SpectateController
`ModuleScript` · bytecode v9 · 17181 bytes · 197 constants
- **Remotes:** RoundEnded, UpdateSpectateCount
- **Services:** Players, ReplicatedStorage, StarterGui, TweenService, UserInputService, game, workspace
- **Key API:** Connect, Create, Disconnect, FireServer, GetAttribute, GetChildren, GetService, IsA, OnClientEvent, Once, Play, WaitForChild, new
- Constants: `Character`, `TeamColor`, `ipairs`, `teamVIP`, `GetAttribute`, `GetPlayerFromCharacter`, `_getAliveTeammate`, `Next`, `Enabled`, `SpectateTeammate`, `LocalPlayer`, `Humanoid`, `FindFirstChildWhichIsA`, `CameraSubject`, `_resetCamera`, `isSpectateDisabled`, `Leave`, `SpectateCount`, `Text`, `IsUICovered`, `CurrentState`, `_updateVisibility`, `SetVisibility`, `Options`, `Visible`, `SetOptionsVisibility`, `FireServer`, `ChangedSpectating`, `UpdateBallSpectating`, `UserId`, `IsFriendsWith`, `DoCleaning`, `Died`, `Once`, `GiveTask`, `Destroying`, `PlayerName`, `DisplayName`, `type`, `string`, `Name`, `GetPropertyChangedSignal`, `Connect`, `pcall`, `CancelSpectateButton`, `ConfettiButton`, `AddFriendButton`, `_isSpectating`, `GetCurrentlySpectating`, `Spectate`, `workspace`, `Balls`, `GetChildren`, `realBall`, `getFakeBall`, `IsDescendantOf`, `SpectateBall`, `CurrentlySelectedMode`, `AbilityGame`, `CrownClash`, `LuckyBlocks`, `UDim2`, `fromScale`, `Position`, `updateSpectatePosition`, `isDuelMatchServer`, `isRankedMatchServer`, `isTrainingServer`, `isTournamentMatchServer`, `getCurrentLTM`, `isLTMServer`, `getGameMode`, `Flying`, `table`, `find`, `serverProfiles`, `GetAttributeChangedSignal`, `task`, `spawn`, `defer`, `Init`, `tostring`, `setLabel`, ` WATCHING`, `setCaption`, `setEnabled`, `updateSpectators`, `delay`, `PromptSendFriendRequest`, `SetCore`, `print`, `Error sending friend request: `, `Vector2`, `new`, `Offset`, `Play`, `PlayerFriendedEvent`, `GetCore`, `Event`, `PlayerUnfriendedEvent`, `CharacterAutoLoads`, `wait`, `Watching: %*`, `1`, `format`, `Model`, `IsA`, `Bot`, `insert`, `remove`, `Frame`, `Parent`, `Connected`, `Disconnect`, `AncestryChanged`, `onCharAdded`, `KeyCode`, `Enum`, `LeftShift`, `RightShift`, `Create`, `setImage`, `setOrder`, `disableStateOverlay`, `Spectators`, `lock`, `RightButton`, `Activated`, `LeftButton`, `OnClientEvent`, `Remotes`, `RoundEnded`, `ChildAdded`, `ChildRemoved`, `NotStartMatch`, `DisableSpectateFinisher`, `PlayingFinisher`, `IsUICoveredState`, `isMedalTournamentMatch`, `CharacterAdded`, `InputBegan`, `Start`, `Alive`, `Dead`, `os`, `clock`, `Wheel`, `require`, `game`, `Players`, `GetService`, `PlayerScripts`, `WaitForChild`, `ClientLoader`, `ControllerIsolator`, `CreateRequire`, `script`, `ReplicatedStorage`, `ProximityPromptService`, `UserInputService`, `StarterGui`, `TweenService`, `Packages`, `Net`, `Replion`, `Shared`, `LTM`, `ServerInfo`, `@game/ReplicatedStorage/Types/Templates`, `Common`, `Utils`, `Maid`, `TopBarController`, `Controllers`, `UI`, `UIStateController`, `TouchEnabled`, `UpdateSpectateCount`, `RemoteEvent`, `CustomRespawnEvent`, `CustomRespawnFinished`, `VFXConfettiEvent`, `SpectateChanged`, `PlayerGui`, `Holder`, `Buttons`, `RankedQueue`, `voter`, `Shop`, `EmoteWheel`, `CurrentCamera`, `isHuntPrivateServer`, `UIGradient`, `TweenInfo`, `EasingStyle`, `Linear`

### [919] ReplicatedStorage.Controllers.UI.SpectateController.SpectateController
`Script` · bytecode v9 · 787 bytes · 19 constants
- **Key API:** GetAttribute, SetAttribute
- Constants: `debug`, `setmemorycategory`, `Name`, `Start`, `script`, `Parent`, `require`, `Loaded`, `SetAttribute`, `Init`, `GetAttribute`, `GetAttributeChangedSignal`, `Wait`, `pcall`, `task`, `spawn`, `error`, `%*:Init() - %*`, `format`

### [920] ReplicatedStorage.Controllers.UI.ThemedQuestsController
`ModuleScript` · bytecode v9 · 7217 bytes · 138 constants
- **Remotes:** Data
- **Services:** Players, ReplicatedStorage, TweenService, game, workspace
- **Key API:** Clone, Connect, FindFirstChild, FireServer, GetChildren, GetService, IsA, WaitForChild
- Constants: `Get`, `callback`, `OnChange`, `observePath`, `ThemedQuests`, `Limited`, `Quests`, `getQuestInfo`, `Enabled`, `Condensed`, `CurrentState`, `Visible`, `Holder`, `Arrow`, `_updateQuestArrowVisibility`, `IsMobile`, `SetToggleEnabled`, `Close`, `QuestId`, `FireServer`, `UIListLayout`, `Template`, `Clone`, `BG`, `QuestTitle`, `DisplayName`, `Text`, `Intermediate`, `Activated`, `Connect`, `Parent`, `Redeemed`, `CompletedOverlay`, `Arguments`, `value`, `Progress`, `Active`, `Color3`, `fromRGB`, `ImageColor3`, `Bar`, `ProgressValue`, `%*/%*`, `math`, `min`, `format`, `target`, `Fill`, `Size`, `UDim2`, `fromScale`, `BigReward`, `Opened`, `Checks`, `GetChildren`, `Frame`, `IsA`, `Check`, `LayoutOrder`, `untracked`, `Loaded`, `Stock`, `reward`, `Value`, `ceil`, `clamp`, `replacement`, `ThemedQuestsReceivedHonkaiReward`, `Crate`, `Remove`, `AddFromRewardInfo`, `Icon`, `Icons`, `DEFAULT_MISSING`, `GetIcon`, `Image`, `updateBigReward`, `workspace`, `GetServerTimeNow`, `EndTimestamp`, `task`, `wait`, `Client`, `LimitedStockItems`, `WaitReplion`, `Data`, `atom`, `effect`, `OnGuiOpen`, `Rewards`, `InitialStock`, `OnGuiClose`, `CloseButton`, `StateChanged`, `spawn`, `Start`, `require`, `game`, `Players`, `GetService`, `LocalPlayer`, `PlayerScripts`, `WaitForChild`, `ClientLoader`, `ControllerIsolator`, `CreateRequire`, `script`, `ReplicatedStorage`, `TweenService`, `Packages`, `Replion`, `Net`, `Charm`, `Common`, `Utils`, `ClientGameModules`, `GuiHandler`, `DeviceListener`, `MarketplaceService`, `Controllers`, `UI`, `HUDController`, `Shared`, `ThemedQuestsData`, `Spring`, `RewardInfo`, `HoverInfoController`, `NewQuests`, `PlayerGui`, `HUD`, `LeftFrame`, `DailyQuestsPage`, `FindFirstChild`, `Alert`, `QuestArrow`, `ThemedQuests/Claim`, `RemoteEvent`, `ThemedQuests/Opened`

### [921] ReplicatedStorage.Controllers.UI.TooltipController
`ModuleScript` · bytecode v9 · 1769 bytes · 35 constants
- **Services:** Players, ReplicatedStorage, UserInputService, game
- **Key API:** Connect, GetService, WaitForChild
- Constants: `current`, `UDim2`, `fromOffset`, `AbsolutePosition`, `X`, `AbsoluteSize`, `Y`, `Position`, `Parent`, `Text`, `BackToolTip`, `tooltip`, `tooltips`, `MouseEnter`, `Connect`, `MouseLeave`, `New`, `UpdateTooltip`, `WindowFocusReleased`, `Start`, `require`, `game`, `Players`, `GetService`, `LocalPlayer`, `PlayerScripts`, `WaitForChild`, `ClientLoader`, `ControllerIsolator`, `CreateRequire`, `script`, `ReplicatedStorage`, `UserInputService`, `PlayerGui`, `Tooltip`

### [922] ReplicatedStorage.Controllers.UI.TooltipController.TooltipController
`Script` · bytecode v9 · 787 bytes · 19 constants
- **Key API:** GetAttribute, SetAttribute
- Constants: `debug`, `setmemorycategory`, `Name`, `Start`, `script`, `Parent`, `require`, `Loaded`, `SetAttribute`, `Init`, `GetAttribute`, `GetAttributeChangedSignal`, `Wait`, `pcall`, `task`, `spawn`, `error`, `%*:Init() - %*`, `format`

### [923] ReplicatedStorage.Controllers.UI.TopBarController
`ModuleScript` · bytecode v9 · 8582 bytes · 178 constants
- **Remotes:** Data, Freeze
- **Services:** Players, ReplicatedStorage, SoundService, StarterGui, Stats, TweenService, UserInputService, game, workspace
- **Key API:** Connect, Create, FireServer, GetAttribute, GetService, WaitForChild, new
- Constants: `CanSendGameInviteAsync`, `getIcon`, `Icon %* already exist!`, `format`, `assert`, `new`, `setName`, `table`, `insert`, `GetGuiInset`, `Y`, `setRight`, `setLeft`, `Create`, `%* is not a valid TopBar icon!`, `GetIcon`, `task`, `wait`, `WaitForIcon`, `find`, `dropdownIcons`, `joinDropdown`, `AddDropdown`, `print`, `removing`, `List`, `remove`, `setDropdown`, `RemoveDropdown`, `notify`, `Notify`, `Instance`, `Sound`, `rbxassetid://4590662766`, `SoundId`, `PlayLocalSound`, `modifyBaseTheme`, `Widget`, `MinimumWidth`, `Deselected`, `MinimumHeight`, `TouchEnabled`, `KeyboardEnabled`, `GamepadEnabled`, `IsTenFootInterface`, `DailyLogin`, `setImage`, `setLabel`, `Login Rewards`, `setCaption`, `Notice`, `BackgroundColor3`, `Color3`, `fromRGB`, `NoticeLabel`, `TextColor3`, `NoticeUIStroke`, `Color`, `modifyTheme`, `Extra`, `EXTRA`, `These are special offers from the developers!`, `Dropdown`, `MaxIcons`, `notified`, `Connect`, `Init`, `PromptFriendInvite`, `deselect`, `isSelected`, `HasFriends`, `workspace`, `AreInvitesEnabled`, `GetAttribute`, `AttributeChanged`, `Wait`, `InviteFriends`, `INVITE FRIENDS`, `disableStateOverlay`, `selected`, `bindEvent`, `PersonalStats`, `Open`, `Close`, `User`, `OpenColorPicker`, `GamePasses`, `VIP`, `Find`, `Subscriptions.VIPPlus.Active`, `Get`, `setEnabled`, `updateVIP`, `enabled`, `ViewportSize`, `X`, `DAILY LOGIN`, `GIFT INVENTORY`, `updateButtonPosition`, `DevConsoleVisible`, `SetCore`, `pcall`, `GetRankInGroup`, `RequestLogs`, `RemoteEvent`, `FireServer`, `isTutorialServer`, `setTopbarEnabled`, `retryWithDelay`, `andThen`, `warn`, `catch`, `Value`, `PlayerStats`, `Stats`, `View stats`, `deselected`, `OnGuiClose`, `ToggleHUD`, `Hide UI`, `Toggle HUD`, `Settings`, `GiftInventory`, `Gift Inventory`, `ColorSlash`, `SLASH COLOR`, `Set the slash color!`, `setOrder`, `Controllers`, `UI`, `HUDController`, `toggled`, `Client`, `Data`, `WaitReplion`, `OnChange`, `CurrentCamera`, `GetPropertyChangedSignal`, `isTestGame`, `DevConsole`, `setWidth`, `🖥 DEV CONSOLE`, `Developer Console`, `Start`, `require`, `game`, `Players`, `GetService`, `LocalPlayer`, `PlayerScripts`, `WaitForChild`, `ClientLoader`, `ControllerIsolator`, `CreateRequire`, `script`, `ReplicatedStorage`, `TweenService`, `SocialService`, `SoundService`, `GuiService`, `UserInputService`, `LocalizationService`, `StarterGui`, `Packages`, `Replion`, `Net`, `Promise`, `Freeze`, `Conch`, `InviteRewardsController`, `ClientGameModules`, `GuiHandler`, `Icon`, `ServerInfo`, `isRankedLobby`, `promisify`, `Vector2`

### [924] ReplicatedStorage.Controllers.UI.TopBarController.TopBarController
`Script` · bytecode v9 · 787 bytes · 19 constants
- **Key API:** GetAttribute, SetAttribute
- Constants: `debug`, `setmemorycategory`, `Name`, `Start`, `script`, `Parent`, `require`, `Loaded`, `SetAttribute`, `Init`, `GetAttribute`, `GetAttributeChangedSignal`, `Wait`, `pcall`, `task`, `spawn`, `error`, `%*:Init() - %*`, `format`

### [925] ReplicatedStorage.Controllers.UI.TrioPassController
`ModuleScript` · bytecode v9 · 18872 bytes · 254 constants
- **Remotes:** Data
- **Services:** Players, ReplicatedStorage, RunService, SoundService, StarterGui, TweenService, UserInputService, game, workspace
- **Key API:** Clone, Connect, Create, Destroy, Fire, FireServer, GetAttribute, GetChildren, GetPlayers, GetService, InvokeServer, OnClientEvent, Play, WaitForChild, new
- Constants: `typeof`, `Instance`, `UserId`, `IsFriendsWith`, `TotalKills`, `SecondPlayerKills`, `FirstPlayerKills`, `decode`, `Menu`, `Visible`, `GetCurrentPage`, `math`, `abs`, `table`, `insert`, `sort`, `SortUserIds`, `Client`, `Data`, `GetReplion`, `IsRestrictedPage`, `TrioPass.Players`, `Get`, `Main`, `Invite`, `UseMainFrame`, `MainFrame`, `InviteFriendsOverlay`, `Remotes`, `SetReplication`, `Leaderboard`, `FireServer`, `OnPageChange`, `Fire`, `SetPage`, `pageButton`, `IsEnabled`, `SilentVeilTrioPassEnabled`, `GetKey`, `workspace`, `GetServerTimeNow`, `SilentVeilTrioPassEndTime`, `EnabledSignal`, `updateFlags`, `Name`, `Close`, `InviteList`, `Message`, `GetPlayers`, `IsInTrio`, `GetAttribute`, `CanTrioInvite`, `ImageTransparency`, `Label`, `In Trio`, `Loading`, `Invited`, `Can't Invite`, `Text`, `updateInviteStatus`, `SendInvite`, `InvokeServer`, `task`, `delay`, `new`, `Add`, `Clone`, `Username`, `PlayerPortrait`, `rbxthumb://type=AvatarHeadShot&id=%*&w=100&h=100`, `format`, `Image`, `ScrollingFrame`, `Parent`, `GetAttributeChangedSignal`, `Connect`, `spawn`, `Activated`, `RemoveInvite`, `OnClientEvent`, `onPlayerAdded`, `Clean`, `Destroy`, `ReadyButton`, `Active`, `DeclineButton`, `PlaybackState`, `Enum`, `Playing`, `Delayed`, `Completed`, `Wait`, `TweenInfo`, `EasingStyle`, `Back`, `EasingDirection`, `In`, `Position`, `UDim2`, `fromScale`, `Create`, `Play`, `Open`, `Character`, `Dead`, `wait`, `_cleaning`, `Title`, `Trio Invite`, `%* Invited You to join their Trio!`, `Quint`, `Out`, `close`, `IsOpen`, `updateIsEnabled`, `Disband`, `UI`, `error`, `LeaveTrio`, `leaveTrio`, `PlayerName`, `clone`, `Players`, `GetChildren`, `tonumber`, `Headshot`, `Loading...`, `GetUsername`, `andThen`, `Player%*`, `UserLeft`, `LocalPlayer`, `Leave`, `find`, `remove`, `YourTeam`, `rbxassetid://131716186918910`, `HoverImage`, `rbxassetid://80844669979306`, `rbxassetid://87079562812709`, `rbxassetid://81477580179569`, `onTrioUpdate`, `Kills`, `PreviewReward`, `TrioPass.EncodedKills`, `TotalAmount`, `ValueConvertor`, `AddCommas`, `1`, `Amount`, `2`, `3`, `min`, `Frame`, `ProgressBar`, `Fill`, `Sine`, `TweenSize`, `%*/%*`, `ClaimedFrame`, `onKillsUpdate`, `GetExpect`, `Placement`, `%*.`, `Holder`, `Item2`, `Item1`, `string`, `split`, `/`, `KillsCounter`, `Points`, `PlayerUsername`, `concat`, ` & `, `updateLeaderboard`, `Enabled`, `WaitReplion`, `OnGuiOpen`, `OnGuiClose`, `Thread`, `Every`, `DataUpdatedEvent`, `InviteReceived`, `PlayerRemoving`, `PlayerAdded`, `TopButtons`, `TrioKillsPass`, `ConfirmationFrame`, `Stay`, `TrioPass`, `OnDescendantChange`, `OnChange`, `RewardsPerKills`, `Reward`, `Rewards`, `GrandReward`, `LayoutOrder`, `DisplayName`, `Vector`, `Icon`, `Icons`, `DEFAULT_MISSING`, `GetIcon`, `CanPreview`, `Inspect`, `TrioPass.Kills`, `TrioPassLeaderboard`, `Start`, `require`, `game`, `GetService`, `PlayerScripts`, `WaitForChild`, `ClientLoader`, `ControllerIsolator`, `CreateRequire`, `script`, `ReplicatedStorage`, `UserInputService`, `SoundService`, `TweenService`, `StarterGui`, `RunService`, `Packages`, `Promise`, `Replion`, `Signal`, `Trove`, `Common`, `Utils`, `Shared`, `PlayerUtility`, `Controllers`, `Trading`, `IndexController`, `GiftingController`, `ClientGameModules`, `FFlagClient`, `GuiHandler`, `Policy`, `MarketplaceService`, `TrioPassData`, `PlayerGui`, `TrioPassMenu`, `TrioPassHud`, `Template`, `InvitePrompt`, `Pass`, `Template1`, `Template2`, `InviteFriendsFrame`, `promisify`

### [926] ReplicatedStorage.Controllers.UI.UIStateController
`ModuleScript` · bytecode v9 · 1036 bytes · 26 constants
- **Services:** Players, ReplicatedStorage, game
- **Key API:** GetService, WaitForChild
- Constants: `HideHotbarState`, `require`, `game`, `Players`, `GetService`, `LocalPlayer`, `PlayerScripts`, `WaitForChild`, `ClientLoader`, `ControllerIsolator`, `CreateRequire`, `script`, `ReplicatedStorage`, `PlayerGui`, `Shared`, `DynArgs`, `Statable`, `IsUICovered`, `IsUICoveredState`, `HideHotbar`, `Or`, `State`, `LinkState`, `setPropertyComputed`, `Hotbar`, `Enabled`

### [927] ReplicatedStorage.Controllers.UI.UIStateController.UIStateController
`Script` · bytecode v9 · 787 bytes · 19 constants
- **Key API:** GetAttribute, SetAttribute
- Constants: `debug`, `setmemorycategory`, `Name`, `Start`, `script`, `Parent`, `require`, `Loaded`, `SetAttribute`, `Init`, `GetAttribute`, `GetAttributeChangedSignal`, `Wait`, `pcall`, `task`, `spawn`, `error`, `%*:Init() - %*`, `format`

### [928] ReplicatedStorage.Controllers.UI.UpdateLogController
`ModuleScript` · bytecode v9 · 4153 bytes · 107 constants
- **Remotes:** Data
- **Services:** Players, ReplicatedStorage, game, workspace
- **Key API:** Clone, Connect, Create, Destroy, FindFirstChild, FireServer, GetChildren, GetService, IsA, WaitForChild, new
- Constants: `ScrollingFrame`, `Info`, `Thumbnail`, `Icon`, `rbxassetid://16123339130`, `Image`, `Description`, `SubDescription`, `Text`, `SubtextLabel`, `Subtext`, `ItemIcons`, `Item%*`, `format`, `FindFirstChild`, `Visible`, `GetChildren`, `GuiObject`, `IsA`, `Destroy`, `Clone`, `Name`, `LayoutOrder`, `string`, `gsub`, `Header`, `Title`, `workspace`, `GetServerTimeNow`, `Date`, `UnixTimestamp`, `math`, `floor`, `Today`, `%*d ago`, `%*w ago`, `round`, `Size`, `UDim2`, `new`, `Parent`, `Render`, `FireServer`, `Close`, `close`, `User`, `IsOpen`, `Open`, `deselect`, `clearNotices`, `select`, `UpdateLog`, `Create`, `setImage`, `NEWS`, `setLabel`, `View the update log!`, `setCaption`, `setOrder`, `Extra`, `AddDropdown`, `Activated`, `Connect`, `toggled`, `OnGuiClose`, `OnGuiOpen`, `Client`, `Data`, `WaitReplion`, `SessionCount`, `GetExpect`, `TotalStats.Wins`, `ViewedUpdateLogs`, `tostring`, `Get`, `notify`, `Start`, `require`, `game`, `Players`, `GetService`, `LocalPlayer`, `PlayerScripts`, `WaitForChild`, `ClientLoader`, `ControllerIsolator`, `CreateRequire`, `script`, `ReplicatedStorage`, `Packages`, `Replion`, `Net`, `ClientGameModules`, `GuiHandler`, `Shared`, `UpdateLogs`, `Controllers`, `UI`, `TopBarController`, `PlayerGui`, `Main`, `Content`, `Template`, `ViewedUpdateLog`, `RemoteEvent`

### [929] ReplicatedStorage.Controllers.UI.VotingController
`ModuleScript` · bytecode v9 · 4785 bytes · 94 constants
- **Remotes:** UpdateVotes
- **Services:** Players, ReplicatedStorage, game, workspace
- **Key API:** Connect, FindFirstChild, FireServer, GetAttribute, GetChildren, GetService, IsA, WaitForChild
- Constants: `IsUICovered`, `CurrentState`, `workspace`, `NotStartMatch`, `GetAttribute`, `Enabled`, `_updateVoting`, `table`, `clone`, `getLTM`, `Default`, `Text`, `getModeName`, `GetChildren`, `GuiButton`, `IsA`, `find`, `Position`, `tostring`, `Disabled`, `Name`, `Visible`, `Check`, `Counter`, `Texter`, `0`, `FindFirstChild`, `Modes`, `DisplayName`, `Client`, `Voting`, `GetReplion`, `Votes`, `GetExpect`, `_updateVoteCount`, `_updateModes`, `FFA`, `2Teams`, `4Teams`, `Randomizer`, `NoAbilityFFA`, `getProfiles`, `IsActive`, `Id`, `_getVoteCount`, `Get`, `os`, `clock`, `tonumber`, `print`, `--------------------------`, `FireServer`, `Active`, `WaitReplion`, `Activated`, `Connect`, `OnChange`, `GetAttributeChangedSignal`, `Start`, `require`, `game`, `Players`, `GetService`, `LocalPlayer`, `PlayerScripts`, `WaitForChild`, `ClientLoader`, `ControllerIsolator`, `CreateRequire`, `script`, `ReplicatedStorage`, `Packages`, `Replion`, `Net`, `Shared`, `GameModes`, `LTM`, `Controllers`, `UI`, `UIStateController`, `Color3`, `fromRGB`, `PlayerGui`, `voter`, `Frame`, `LobbyLTM`, `warn`, `[!] [voter] Could not find special voting button for lobby LTM! Missing button:`, `1`, `2`, `3`, `UpdateVotes`, `RemoteEvent`, `StateChanged`

### [930] ReplicatedStorage.Controllers.VFXController
`ModuleScript` · bytecode v9 · 6418 bytes · 136 constants
- **Remotes:** Data
- **Services:** Debris, Players, ReplicatedStorage, RunService, TweenService, game, workspace
- **Key API:** Clone, Connect, Destroy, Disconnect, FindFirstChild, Fire, GetAttribute, GetDescendants, GetService, IsA, OnClientEvent, WaitForChild, new
- Constants: `os`, `clock`, `Connected`, `Disconnect`, `Destroy`, `CFrame`, `new`, `Position`, `PVInstance`, `IsA`, `Attachment`, `Clone`, `BillboardGui`, `CanvasGroup`, `TextLabel`, `-%*`, `math`, `round`, `format`, `Text`, `WorldCFrame`, `GetPivot`, `AlwaysOnTop`, `PivotTo`, `workspace`, `Runtime`, `Parent`, `random`, `Vector3`, `UDim2`, `fromScale`, `Size`, `Rotation`, `fastTween`, `TweenInfo`, `Enum`, `EasingStyle`, `Back`, `EasingDirection`, `Out`, `Sine`, `InOut`, `GroupTransparency`, `PostSimulation`, `Connect`, `DamageVFX`, `string`, `split`, `Name`, `Specific`, `warn`, `Failed to locate explosion callback for`, `HumanoidRootPart`, `FindFirstChild`, `GetDescendants`, `ParticleEmitter`, `Beam`, `_particleWasEnabled`, `GetAttribute`, `Enabled`, `FindFirstChildWhichIsA`, `xpcall`, `Ball`, `Variant`, `Instance`, `ExplodePosition`, `EmissionMultiplier`, `Character`, `AttributionCharacter`, `Kill`, `PlayExplosionFromInstance`, `SavedQualityLevel`, `Value`, `OnEmissionMultiplierUpdate`, `Fire`, `UpdateEmissionMultiplier`, `Trail`, `Light`, `GetPropertyChangedSignal`, `setDisableEffect`, `GetInstance`, `%* %*`, `Explosion not found for`, `ExplosionVFX`, `AddTag`, `AddItem`, `Client`, `Data`, `GetReplion`, `Settings`, `Misc`, `Explosion VFX`, `Get`, `ChildAdded`, `PlayExplosion`, `updateEmissionMultiplier`, `task`, `spawn`, `Changed`, `OnClientEvent`, `AwaitReplion`, `OnChange`, `Start`, `require`, `game`, `Players`, `GetService`, `LocalPlayer`, `PlayerScripts`, `WaitForChild`, `ClientLoader`, `ControllerIsolator`, `CreateRequire`, `script`, `UserSettings`, `UserGameSettings`, `ReplicatedStorage`, `TweenService`, `RunService`, `Debris`, `Packages`, `Replion`, `Signal`, `Net`, `Shared`, `FastUtils`, `Common`, `Utils`, `ReplicatedInstances`, `Explosions`, `Types`, `Assets`, `DamageEffect`, `VFXExplode`, `RemoteEvent`

### [931] ReplicatedStorage.Controllers.VFXController.Explosions
`ModuleScript` · bytecode v9 · 107161 bytes · 488 constants
- **Services:** Debris, Players, ReplicatedStorage, RunService, TweenService, game, workspace
- **Key API:** Clone, Connect, Create, Destroy, Disconnect, FindFirstChild, Fire, GetAttribute, GetChildren, GetDescendants, GetService, IsA, LoadAnimation, Once, Play, Stop, WaitForChild, new
- Constants: `Instance`, `new`, `Parent`, `createInstance`, `CFrame`, `identity`, `typeof`, `string`, `match`, `([%d%.%-]*), ([%d%.%-]*), ([%d%.%-]*)`, `tonumber`, `parseCFrame`, `Vector3`, `parseVector`, `Enabled`, `task`, `wait`, `EmissionMultiplier`, `EmitCount`, `GetAttribute`, `Emit`, `Width0`, `Width1`, `Create`, `Play`, `EnableTime`, `print`, `Attempted to enable beam without EnableTime attribute`, `Duration`, `FadeInTime`, `FadeOutTime`, `TweenInfo`, `Enum`, `EasingStyle`, `Linear`, `EasingDirection`, `InOut`, `delay`, `Transparency`, `ExplodePosition`, `AddItem`, `GetDescendants`, `ParticleEmitter`, `IsA`, `EmitDelay`, `Beam`, `spawn`, `Sound`, `BasePart`, `Name`, `GROUND`, `workspace`, `Dead`, `Alive`, `MapBounds`, `Runtime`, `FilterDescendantsInstances`, `Groundfx`, `FindFirstChild`, `Raycast`, `Position`, `Normal`, `Unit`, `ToObjectSpace`, `Void Blast`, `Light`, `ToWorldSpace`, `autoPlay`, `PivotTo`, `Visual`, `PlayEffects`, `depth`, `child`, `GetPivot`, `useGroundXZ`, `X`, `offsetX`, `Y`, `offsetY`, `Z`, `Angles`, `ToEulerAnglesXYZ`, `CFrameValue`, `Value`, `Changed`, `Connect`, `Sine`, `swordDebris`, `stickToGround`, `Size`, `Sound1`, `Quad`, `Out`, `Range`, `Clone`, `pairs`, `GetChildren`, `In`, `Rate`, `Cubic`, `Volume`, `PointLight`, `Fire`, `Flash`, `Flash2`, `d`, `smoke`, `zippies`, `zoippers1`, `Sound2`, `Sound3`, `Ff`, `ChargeATT`, `ExplodeATT`, `shockwave`, `fireshockwave`, `sfx`, `math`, `random`, `PlaybackSpeed`, `att`, `fire`, `fireflies`, `zapper`, `splishies`, `Water`, `bing`, `flip`, `drops`, `GroundFx`, `RaycastParams`, `RaycastFilterType`, `Exclude`, `FilterType`, `Misc`, `Wave`, `Leaves`, `Vanity`, `Color`, `Connection`, `game`, `TweenService`, `wavezz`, `Upz`, `Fp`, `Downroots`, `Branches`, `Particlepart`, `Tree`, `pew`, `yAxis`, `MoveTo`, `magic`, `pigeon`, `glitch`, `Particle2`, `Particle1`, `Specs1`, `Specs2`, `shatter`, `Wind`, `Attachment`, `25`, `du`, `duoso`, `un`, `mee`, `colorme`, `boo`, `boospecs`, `fromOrientation`, `BodyExplosion`, `IsDescendantOf`, `Tombstone`, `NumberValue`, `Back`, `Egg`, `GetExtentsSize`, `Character`, `Humanoid`, `FindFirstChildWhichIsA`, `GetAppliedDescription`, `ApplyDescription`, `Accessory`, `Physics`, `ResizePart`, `pcall`, `Torso`, `Frame58`, `Frame336`, `Destroy`, `Thread`, `SafeCancel`, `Player`, `AnimationController`, `Animator`, `Animation`, `LoadAnimation`, `[Anchored=true]`, `QueryDescendants`, `HumanoidRootPart`, `Anchored`, `CanCollide`, `Length`, `Enable`, `Disable`, `GetPlayingAnimationTracks`, `IsPlaying`, `table`, `insert`, `Stopped`, `Once`, `Sword`, `Sword1`, `Sword2`, `TurnOffVisuals`, `Decal`, `Trail`, `Blade`, `UFO`, `Pyramid`, `Lightning`, `Scythe`, `1`, `Meshes/907_Prince Blade.016`, `Parasol`, `Stop`, `NebulaSniper`, `Umbrella`, `Katana`, `Star`, `update`, `Vector3Value`, `Rotation`, `Lantern`, `lookAt`, `select`, `ToOrientation`, `sin`, `VanishTransition`, `Disconnect`, `lantern 1`, `PostSimulation`, `Destroying`, `HeartRocket`, `Completed`, `Main`, `Coffin`, `MoonFlower`, `Anchor`, `Looped`, `Book`, `Texture`, `Highlight`, `addTransparencyObject`, `ClassName`, `OutlineTransparency`, `FillTransparency`, `Kill`, `Assets`, `R6`, `Billboard`, `BillboardGui`, `InfoBillboard`, `Active`, `ExtentsOffsetWorldSpace`, `MaxDistance`, `UDim2`, `ZIndexBehavior`, `Sibling`, `TextLabel`, `Vector2`, `AnchorPoint`, `Color3`, `fromRGB`, `BackgroundColor3`, `BackgroundTransparency`, `BorderColor3`, `Font`, `rbxasset://fonts/families/FredokaOne.json`, `FontFace`, `fromScale`, `ValueConvertor`, `AddCommas`, `Text`, `TextColor3`, `TextScaled`, `TextSize`, `TextStrokeColor3`, `TextWrapped`, `ZIndex`, `UIStroke`, `Thickness`, `UIGradient`, `ColorSequence`, `ColorSequenceKeypoint`, `Head`, `DescendantAdded`, `PrimaryPart`, `fastTween`, `HighlightDepthMode`, `Occluded`, `DepthMode`, `FillColor`, `OutlineColor`, `WorldCFrame`, `reachifyring`, `Brightness`, `NormalId`, `EmissionDirection`, `NumberRange`, `FlipbookFramerate`, `ParticleFlipbookLayout`, `Grid4x4`, `FlipbookLayout`, `Lifetime`, `LightEmission`, `ParticleOrientation`, `FacingCameraWorldUp`, `Orientation`, `NumberSequence`, `NumberSequenceKeypoint`, `Speed`, `http://www.roblox.com/asset/?id=119787067018418`, `TimeScale`, `ZOffset`, `Mask`, `Chicken`, `EnableME`, `NextUnitVector`, `Mass`, `ApplyImpulse`, `Part`, `Magnitude`, `Dragon`, `Built`, `Broken`, `Random`, `foot_L`, `foot_R`, `Lerp`, `AttachToInstance`, `sort`, `clamp`, `Add`, `Bird`, `Turtle`, `AnimationId`, `rbxassetid://132899069696898`, `LookVector`, `ReplicatedStorage`, `GetService`, `RunService`, `Players`, `Debris`, `require`, `script`, `Types`, `Shared`, `FastUtils`, `Packages`, `Trove`, `Common`, `Utils`, `StudioLogger`, `ReplicatedInstances`, `Explosions`, `LocalPlayer`, `CurrentCamera`, `PlayerScripts`, `WaitForChild`, `EffectScripts`, `ClientFX`, `Shake`, `IgnoreWater`, `RespectCanCollide`, `Blackhole`, `Explosion`, `Waterblast`, `Sakura`, `Matrix`, `Arctic`, `Runic`, `Exorcist`, `Viper’s`, `Christmas`, `Firework`, `RIP`, `Specific`, `Slime Egg`, `Chocolate Egg`, `Cherry Blossom Tree`, `T-Rex Explosion`, `Vampire Light`, `Bridal Revival`, `Eggsplosive Exit`, `Kitty Katana Explosion`, `Judgement`, `Fox Katana Explosion`, `Poisoned Bunny Explosion`, `Devil's Curse`, `Eternal`, `UFO Abduction`, `Pyramid Scheme`, `Zeus' Punishment`, `Chroma Blade Explosion`, `Chroma Scythe Explosion`, `Dual Chroma Set Explosion`, `Yin Yang Parasol Explosion`, `Jellyfish Explosion`, `Cosmic Accuracy`, `Dual Yin Yang Greatsword Explosion`, `Yin Yang Greatsword Explosion`, `Beach Party`, `Ghostly Revenge`, `Tropical Splash`, `Shark Feast`, `Champion's Triumph`, `Katana Black Explosion`, `Katana Red Explosion`, `Katana Blue Explosion`, `Katana Green Explosion`, `Katana Pink Explosion`, `Katana Chroma Explosion`, `Black Ninja Star Explosion`, `Blue Ninja Star Explosion`, `Green Ninja Star Explosion`, `Pink Ninja Star Explosion`, `Red Ninja Star Explosion`, `Chroma Ninja Star Explosion`, `Chroma Oni Katana Explosion`, `Stormbane Explosion`, `Red Oni Katana Explosion`, `Blue Oni Katana Explosion`, `Pink Oni Katana Explosion`, `Purple Oni Katana Explosion`, `Black Oni Katana Explosion`, `Ghostwisp`, `Dual Ghostwisp`, `Soul Lantern`, `Frostbound Enlightenment`, `Kitty Rocket`, `Seraphim Gate`, `Coffin Explosion`, `Moon Discovery`, `Great Moon Landing`, `Serpent Anchor`, `Astraea Guidance`, `Soulforge Explosion`, `Medic Waveform`, `Holiday Treeburst`, `Santa's Greatplosion`, `Sweet Headshot`, `Bell Light`, `Soul Counter`, `Lily Strike`, `Serpent's Judgment`, `Lunar Lantern`, `The Curse Explosion`, `Floppy Chicken Explosion`, `Blossom Katana Explosion`, `Master Builder`, `Paw Punch`, `Shatterflight Bird Explosion`, `Prismatic Odachi Explosion`, `Sakura's Requiem Explosion`, `Fallen Angel Explosion`, `Hollow Oath Explosion`, `Calamity Guardian Explosion`, `Spinalis Explosion`, `Star Wand Explosion`, `Oni Ghost Explosion`, `Ethereal Bombardment Explosion`, `Riftflare Katana Explosion`, `Phantom Pact`, `Night Raver`, `Cross Admiration`, `Gyaru's Selfie`, `Higanbana Explosion`, `Wolf Greatsword Explosion`, `Regret Blades Explosion`, `Pearl Angel Katana Explosion`, `Prismatic Cloud Rain`, `Tiger Katana Explosion`, `Red Moon Katana Explosion`, `Proyection Sorcery Explosion`, `Sea Turtle Explosion`, `GetCollection`

### [933] ReplicatedStorage.Controllers.VFXController.VFXController
`Script` · bytecode v9 · 787 bytes · 19 constants
- **Key API:** GetAttribute, SetAttribute
- Constants: `debug`, `setmemorycategory`, `Name`, `Start`, `script`, `Parent`, `require`, `Loaded`, `SetAttribute`, `Init`, `GetAttribute`, `GetAttributeChangedSignal`, `Wait`, `pcall`, `task`, `spawn`, `error`, `%*:Init() - %*`, `format`

### [934] ReplicatedStorage.Controllers.ValentinesBundleController
`ModuleScript` · bytecode v9 · 5600 bytes · 111 constants
- **Remotes:** Data, SetGift
- **Services:** Players, ReplicatedStorage, game, workspace
- **Key API:** Connect, Disconnect, FindFirstChild, GetAttribute, GetChildren, GetService, WaitForChild
- Constants: `workspace`, `GetServerTimeNow`, `ValueConvertor`, `FormatTimeWithDays`, `Countdown`, `EndTime`, `UnixTimestamp`, `GetExpireTime`, `isLTMServer`, `IsActive`, `Text`, `EXPIRED!`, `Connected`, `Disconnect`, `updateTimer`, `Thread`, `Every`, `task`, `spawn`, `createOrUpdateTimer`, `ValentinesBundle`, `Open`, `OnGuiOpen`, `ValentinesBundleFirstJoinTime`, `OnChange`, `Activated`, `Connect`, `StartHUD`, `IsOpen`, `Close`, `ProductId`, `Enum`, `InfoType`, `Product`, `PromptPurchase`, `GiftName`, `SetGift`, `Character`, `Parent`, `Alive`, `GameActive`, `GetAttribute`, `_currentGui`, `wait`, `Main`, `Timer`, `Title`, `TitleShadow`, `Bundles`, `tostring`, `FindFirstChild`, `ButtonsBottom`, `Buy`, `Amount`, `DevProduct`, `Gift`, `Items`, `GetChildren`, `Name`, `tonumber`, `Rewards`, `Vector`, `Icon`, `Icons`, `DEFAULT_MISSING`, `GetIcon`, `Image`, `SakuraLabel`, `TBD`, `DisplayName`, `ValentinesBundleAppear`, `Get`, `StartMenu`, `CoreGuiType`, `PlayerList`, `Client`, `Data`, `WaitReplion`, `OnGuiClose`, `Start`, `require`, `game`, `Players`, `GetService`, `LocalPlayer`, `PlayerScripts`, `WaitForChild`, `ClientLoader`, `ControllerIsolator`, `CreateRequire`, `script`, `ReplicatedStorage`, `Packages`, `Replion`, `ServerInfo`, `Common`, `MarketplaceService`, `Utils`, `Shared`, `Policy`, `ClientGameModules`, `GuiHandler`, `CreatePriceLabel`, `CoreCall`, `Controllers`, `GiftingController`, `Trading`, `TradeTokensController`, `PlayerGui`, `RightHUD`, `List`

### [935] ReplicatedStorage.Controllers.ViewInventoryController
`ModuleScript` · bytecode v9 · 5192 bytes · 119 constants
- **Remotes:** Freeze, Set
- **Services:** Players, ReplicatedStorage, game
- **Key API:** Connect, GetChildren, GetService, InvokeServer, IsA, Play, WaitForChild, new
- Constants: `Get`, `Set`, `Player`, `ViewInventory`, `IsOpen`, `Open`, `Remotes`, `typeof`, `Instance`, `InvokeServer`, `task`, `delay`, `ViewInventoryCooldownPerPlayer`, `Misc`, `error`, `Play`, `warn`, `Clean`, `Sword`, `Default`, `Most`, `Inventory`, `Username`, `@%*'s Inventory`, `Name`, `format`, `Text`, `ProfilePicture`, `Headshot`, `rbxthumb://type=AvatarHeadShot&id=%*&w=150&h=150`, `UserId`, `Image`, `ItemTemplate`, `Container`, `Caller`, `SortOption`, `SortOrder`, `SearchFilter`, `WatchOnChange`, `ScrollingFrame`, `UIGridLayout`, `Template`, `Type`, `FakeCaller`, `CustomType`, `Replion`, `CreateFakeReplion`, `TradableItemTypes`, `Computed`, `Dictionary`, `merge`, `InventoryType`, `PageVisible`, `CreateInventory`, `Add`, `SearchBox`, `Close`, `rbxassetid://18123223527`, `rbxassetid://18123248161`, `rbxassetid://18123872657`, `rbxassetid://18123874724`, `HoverImage`, `Label`, `UIStroke`, `Color3`, `fromRGB`, `Color`, `Vector2`, `zero`, `CanvasPosition`, `Sort`, `CreateSortOptions`, `ItemSearch`, `setPropertyState`, `FocusLost`, `Connect`, `Search`, `Activated`, `TopButtons`, `GetChildren`, `ImageButton`, `IsA`, `PlayerRemoving`, `Start`, `require`, `game`, `Players`, `GetService`, `LocalPlayer`, `PlayerScripts`, `WaitForChild`, `ClientLoader`, `ControllerIsolator`, `CreateRequire`, `script`, `ReplicatedStorage`, `Packages`, `Freeze`, `Trove`, `Shared`, `InventoryTypes`, `Trading`, `TradeInfo`, `Client`, `Statable`, `ItemInfo`, `Controllers`, `UI`, `ShopControllerAPI`, `InventoryController`, `ClientGameModules`, `GuiHandler`, `Common`, `Utils`, `PlayerGui`, `Main`, `State`, `new`

### [936] ReplicatedStorage.Controllers.ViewInventoryController.ViewInventoryController
`Script` · bytecode v9 · 787 bytes · 19 constants
- **Key API:** GetAttribute, SetAttribute
- Constants: `debug`, `setmemorycategory`, `Name`, `Start`, `script`, `Parent`, `require`, `Loaded`, `SetAttribute`, `Init`, `GetAttribute`, `GetAttributeChangedSignal`, `Wait`, `pcall`, `task`, `spawn`, `error`, `%*:Init() - %*`, `format`

### [937] ReplicatedStorage.Controllers.VisualizerController
`ModuleScript` · bytecode v9 · 2887 bytes · 72 constants
- **Services:** Lighting, Players, ReplicatedStorage, RunService, UserInputService, game, workspace
- **Key API:** Connect, GetDescendants, GetService, IsA, WaitForChild, new
- Constants: `Clean`, `workspace`, `Parent`, `GetExtentsSize`, `X`, `Y`, `Z`, `math`, `max`, `ViewportSize`, `min`, `GetDescendants`, `BasePart`, `IsA`, `Anchored`, `GetScale`, `ScaleTo`, `CastShadow`, `Visualize`, `Clear`, `CFrame`, `Position`, `LookVector`, `lookAt`, `PivotTo`, `FieldOfView`, `rad`, `tan`, `Vector3`, `new`, `Size`, `UserInputType`, `Enum`, `MouseButton1`, `Touch`, `KeyCode`, `ButtonR2`, `PreRender`, `Connect`, `InputBegan`, `Start`, `require`, `game`, `Players`, `GetService`, `LocalPlayer`, `PlayerScripts`, `WaitForChild`, `ClientLoader`, `ControllerIsolator`, `CreateRequire`, `script`, `Lighting`, `ReplicatedStorage`, `RunService`, `UserInputService`, `Packages`, `Observers`, `Trove`, `CurrentCamera`, `Instance`, `Part`, `Black`, `Name`, `Material`, `SmoothPlastic`, `Color3`, `Color`, `Transparency`, `CanCollide`, `CanQuery`, `CanTouch`

### [938] ReplicatedStorage.Controllers.WelcomeBackController
`ModuleScript` · bytecode v9 · 2653 bytes · 55 constants
- **Remotes:** Data
- **Services:** Players, ReplicatedStorage, game, workspace
- **Key API:** Disconnect, GetChildren, GetService, IsA, WaitForChild
- Constants: `Disconnect`, `EventEnded`, `LoadEventControllers`, `isRankedMatchServer`, `isDuelMatchServer`, `isTournamentMatchServer`, `isDungeonsMatchServer`, `isDungeonsLobbyServer`, `isTradingPlazaServer`, `isTrainingServer`, `isTutorialServer`, `isHuntPrivateServer`, `task`, `wait`, `Client`, `Data`, `WaitReplion`, `WelcomeBackEvent`, `OnChange`, `Start`, `ipairs`, `Name`, `ScriptSource`, `GetEventController`, `GetChildren`, `ModuleScript`, `IsA`, `_Initialized`, `_Started`, `table`, `insert`, `Init`, `typeof`, `function`, `spawn`, `workspace`, `GetServerTimeNow`, `WelcomeBackEvent.EventEndTime`, `Get`, `require`, `game`, `Players`, `GetService`, `LocalPlayer`, `PlayerScripts`, `WaitForChild`, `ClientLoader`, `ControllerIsolator`, `CreateRequire`, `script`, `ReplicatedStorage`, `Packages`, `Replion`, `ServerInfo`, `EventControllers`

### [939] ReplicatedStorage.Controllers.WelcomeBackController.EventControllers.Crate
`ModuleScript` · bytecode v9 · 4740 bytes · 101 constants
- **Remotes:** Data
- **Services:** Players, ReplicatedStorage, SoundService, TweenService, game
- **Key API:** Clone, Connect, Create, Destroy, GetService, InvokeServer, OnClientEvent, Once, Play, WaitForChild, new
- Constants: `WelcomeBackEvent.ReturnCrateKeys`, `Get`, `InvokeServer`, `task`, `wait`, `Client`, `Data`, `WaitReplion`, `Buy`, `MouseButton1Click`, `Connect`, `OnClientEvent`, `RollForItem`, `UpdateCurrency`, `OnChange`, `Rewards`, `Clone`, `LayoutOrder`, `Percentage`, `%*%%`, `Chance`, `AddCommas`, `format`, `Text`, `ItemName`, `Reward`, `DisplayName`, `Vector`, `Icon`, `Image`, `Items`, `Parent`, `Start`, `Destroy`, `math`, `random`, `sqrt`, `Cancel`, `Selection`, `Visible`, `ImageTransparency`, `FastTween`, `TweenInfo`, `new`, `FastAudio`, `rbxassetid://6895079853`, `ipairs`, `ZIndex`, `Enum`, `EasingStyle`, `Quart`, `Size`, `UDim2`, `fromScale`, `Completed`, `Once`, `table`, `clear`, `Create`, `Play`, `Instance`, `Sound`, `SoundId`, `Volume`, `PlaybackSpeed`, `TimePosition`, `Ended`, `Cost`, `Spin - %*`, `game`, `TweenService`, `GetService`, `SoundService`, `ReplicatedStorage`, `Players`, `require`, `Shared`, `Policy`, `Packages`, `Net`, `Replion`, `Common`, `Utils`, `Utilities`, `ValueConvertor`, `WelcomeBackData`, `WelcomeBackCrate`, `LocalPlayer`, `PlayerGui`, `PurchaseReturnCrateKey`, `RemoteFunction`, `OpenReturnCrate`, `RolledReturnCrate`, `RemoteEvent`, `NewWelcomeBack`, `WaitForChild`, `Frame`, `Views`, `Crate`, `Template`

### [940] ReplicatedStorage.Controllers.WelcomeBackController.EventControllers.Login
`ModuleScript` · bytecode v9 · 6359 bytes · 107 constants
- **Remotes:** Data
- **Services:** Players, ReplicatedStorage, game
- **Key API:** Clone, Connect, Disconnect, FindFirstChild, Fire, GetAttribute, GetService, InvokeServer, WaitForChild, new
- Constants: `ChangeSelectionCrateItem`, `ToggleSelectionCrate`, `Client`, `Data`, `WaitReplion`, `WelcomeBackEvent.ClaimedSelectionCrate`, `UpdateFinalRewardFrame`, `OnChange`, `UpdateAllSelectionTiles`, `WelcomeBackEvent.DailyLoginStreak`, `Connect`, `UpdateSelectionFrame`, `UpdateSelectionCount`, `Frame`, `Close`, `MouseButton1Click`, `Collect`, `UpdateAllShopTiles`, `WelcomeBackEvent.ClaimedDailyRewards`, `Start`, `Fire`, `Visible`, `Label2`, `Selected: %*/1`, `format`, `Text`, `Get`, `Options`, `Claim`, `Spacer`, `View`, `Force`, `Continuity Zero`, `Vector`, `Reward`, `Icon`, `Image`, `Clone`, `ItemName`, `string`, `find`, `Emote`, `Misc`, `Emotes`, `FindFirstChild`, `EmoteName`, `GetAttribute`, `Items`, `Parent`, `Sel`, `UpdateSelectionTile`, `math`, `max`, `Claimed reward!`, `Claimable now!`, `Label1`, `<stroke color="rgb(3, 31, 65)" joins="round" thickness="2.5">%*</stroke>`, `<stroke color="rgb(3, 31, 65)" joins="round" thickness="2.5">Claimable in <font color="rgb(255, 200, 33 )">%*</font> days</stroke>`, `CollectGrey`, `InvokeServer`, `Disconnect`, `Day7`, `LayoutOrder`, `TextLabel`, `Day %*`, `Days`, `SWORD_SELECTION_CRATE`, `rbxassetid://17302327393`, `typeof`, `table`, `DisplayName`, `Check`, `Claimed`, `UpdateShopTile`, `ipairs`, `game`, `ReplicatedStorage`, `GetService`, `Players`, `require`, `Packages`, `Signal`, `Net`, `Replion`, `Common`, `Utils`, `Utilities`, `ValueConvertor`, `Shared`, `WelcomeBackData`, `LocalPlayer`, `PlayerGui`, `WelcomeBackDailyRewards`, `GetSelectionCrateRewards`, `ClaimWelcomeBackDailyReward`, `RemoteFunction`, `RedeemWelcomeBackSelectionCrate`, `NewWelcomeBack`, `WaitForChild`, `ChangeFinalQuest`, `RewardSelectionCrate`, `Views`, `Login`, `DayTemplate`, `CrateTemplate`, `new`

### [941] ReplicatedStorage.Controllers.WelcomeBackController.EventControllers.Main
`ModuleScript` · bytecode v9 · 5126 bytes · 109 constants
- **Remotes:** Data
- **Services:** CollectionService, Players, ReplicatedStorage, game, workspace
- **Key API:** Connect, FindFirstChild, Fire, GetChildren, GetService, SetAttribute, WaitForChild, new
- Constants: `workspace`, `GetServerTimeNow`, `WelcomeBackEvent.EventEndTime`, `Get`, `math`, `max`, `GetRemainingEventTime`, `Fire`, `SetNotificationStatus`, `require`, `script`, `Parent`, `View`, `Init`, `WelcomeBackButton`, `GetTagged`, `ipairs`, `IsMobile`, `Vector2`, `new`, `AnchorPoint`, `UDim2`, `fromScale`, `Position`, `MovingPosition`, `SetAttribute`, `UpdateMobilePosition`, `ImageLabel`, `Visible`, `OpenView`, `_selectedView`, `Selected`, `Unselected`, `Image`, `HoverImage`, `UIStroke`, `FindFirstChildWhichIsA`, `UIStrokeColor`, `Color`, `Character`, `CharacterChanged`, `Client`, `Data`, `WaitReplion`, `Observe`, `Connect`, `Every`, `UpdateButtons`, `MouseButton1Click`, `ToggleButton`, `GetChildren`, `Name`, `CreateView`, `FindFirstChild`, `OnViewOpen`, `OnViewClosed`, `table`, `insert`, `OnCreditsChanged`, `WelcomeBackEvent.ReturnCoins`, `OnChange`, `Timer`, `EndTime`, `GachaSpinExpiresTime`, `AddTag`, `Login`, `GetPropertyChangedSignal`, `Start`, `Frame`, `TopFrame`, `Currency`, `Amount`, `AddCommas`, `Text`, `FormatTimeWithDaysFull`, `NewWelcomeBack`, `IsOpen`, `Close`, `Open`, `game`, `CollectionService`, `GetService`, `ReplicatedStorage`, `Players`, `Packages`, `Signal`, `Replion`, `ClientGameModules`, `GuiHandler`, `Common`, `Utils`, `Utilities`, `Thread`, `ValueConvertor`, `Shared`, `WelcomeBackData`, `LocalPlayer`, `PlayerGui`, `DeviceListener`, `Alive`, `WaitForChild`, `SideBtns`, `Views`, `rbxassetid://17259974055`, `rbxassetid://17259974925`, `Color3`, `fromRGB`, `rbxassetid://17259976762`, `rbxassetid://17259977737`

### [942] ReplicatedStorage.Controllers.WelcomeBackController.EventControllers.Quests
`ModuleScript` · bytecode v9 · 8242 bytes · 149 constants
- **Remotes:** Data
- **Services:** Players, ReplicatedStorage, game
- **Key API:** Clone, Connect, Destroy, Disconnect, FindFirstChild, GetChildren, GetService, InvokeServer, IsA, Once, WaitForChild
- Constants: `WelcomeBackEvent.Quests.Main.Daily`, `Get`, `OnQuestsChanged`, `SelectButton`, `Client`, `Data`, `WaitReplion`, `WelcomeBackEvent.ClaimedMilestones`, `UpdateAllMilestoneTiles`, `OnChange`, `WelcomeBackEvent.Quests.XP`, `OnXPChanged`, `ipairs`, `Days`, `GetChildren`, `ImageButton`, `IsA`, `string`, `gsub`, `Name`, `Day`, `tonumber`, `MouseButton1Click`, `Connect`, `WelcomeBackEvent.Quests.Main.Daily.CurrentDay`, `Start`, `SelectDayButton`, `DestroyQuestTiles`, `RedeemQuestsType`, `WelcomeBack`, `Daily`, `QuestId`, `InvokeServer`, `Connected`, `Disconnect`, `Identifier`, `GetQuestData`, `Arguments`, `value`, `typeof`, `function`, `Redeemed`, `Claimed!`, `%*/%*`, `Progress`, `math`, `min`, `format`, `Destroy`, `Clone`, `SecondCurrency`, `ItemReward`, `SecondReward`, `table`, `Amount`, `+%*`, `Value`, `Text`, `Claimed`, `Visible`, `Claim`, `Destroying`, `Once`, `Scrolling`, `Content`, `Parent`, `clamp`, `Unclaimed`, `LayoutOrder`, `Title`, `%* (%* XP)`, `DisplayName`, `Reward`, `ProgressBar`, `Fill`, `UDim2`, `fromScale`, `Size`, `UpdateQuestTile`, `Quests`, `OrderedDay`, `UUID`, `REPLICA`, `GENERATED`, `insert`, `PreviousDay`, `clear`, `_G`, `SendNotification`, `You do not have a reward selected!`, `ItemName`, `Vector`, `Icon`, `Image`, `cycleFinalReward`, `Change`, `TopItems`, `XP`, `UpdateMilestoneTile`, `Places`, `Circle%*`, `FindFirstChild`, `tostring`, `Selected`, `Unselected`, `HoverImage`, `UIStroke`, `FindFirstChildWhichIsA`, `UIStrokeColor`, `Color`, `game`, `ReplicatedStorage`, `GetService`, `Players`, `require`, `Packages`, `Net`, `Replion`, `Common`, `Utils`, `Utilities`, `ValueConvertor`, `Shared`, `WelcomeBackData`, `NewQuests`, `QuestUtility`, `LocalPlayer`, `PlayerGui`, `PurchaseWelcomeBackShopItem`, `RemoteFunction`, `ClaimWelcomeBackMilestone`, `RedeemWelcomeBackFinalMilestone`, `NewWelcomeBack`, `WaitForChild`, `Frame`, `Views`, `MaxMilestoneXP`, `WelcomeBackMilestones`, `MilestoneFinalRewards`, `rbxassetid://17260717560`, `rbxassetid://17260717844`, `Color3`, `fromRGB`, `rbxassetid://17260716134`, `rbxassetid://17260716555`, `MilestoneTemplate`, `QuestTemplate`, `ClaimedTemplate`

### [943] ReplicatedStorage.Controllers.WelcomeBackController.EventControllers.Shop
`ModuleScript` · bytecode v9 · 2235 bytes · 61 constants
- **Remotes:** Data
- **Services:** Players, ReplicatedStorage, game
- **Key API:** Clone, Connect, Disconnect, GetService, InvokeServer, WaitForChild
- Constants: `Client`, `Data`, `WaitReplion`, `UpdateAllShopTiles`, `Emote`, `OnChange`, `Explosion`, `Sword`, `Start`, `WelcomeBackEventShopItems`, `Reward`, `Value`, `Get`, `OwnsShopItem`, `InvokeServer`, `Disconnect`, `Clone`, `Vector`, `Icon`, `Image`, `Title`, `DisplayName`, `Text`, `Buy`, `Cost`, `AddCommas`, `MouseButton1Click`, `Connect`, `Items`, `Parent`, `Visible`, `Claimed`, `UpdateShopTile`, `ipairs`, `game`, `ReplicatedStorage`, `GetService`, `Players`, `require`, `Packages`, `Net`, `Replion`, `Common`, `Utils`, `Utilities`, `ValueConvertor`, `Shared`, `WelcomeBackData`, `Inventory`, `LocalPlayer`, `PlayerGui`, `WelcomeBackReturnCoinShop`, `PurchaseWelcomeBackShopItem`, `RemoteFunction`, `NewWelcomeBack`, `WaitForChild`, `Frame`, `Views`, `Shop`, `Template`

### [944] ReplicatedStorage.Controllers.WelcomeBackController.EventControllers.View
`ModuleScript` · bytecode v9 · 2903 bytes · 54 constants
- **Services:** Players, ReplicatedStorage, StarterGui, game
- **Key API:** Connect, Fire, GetService, WaitForChild, new
- Constants: `_frame`, `_openSignal`, `_closeSignal`, `new`, `Visible`, `_views`, `CreateView`, `GetView`, `OnViewOpen`, `OnViewClosed`, `Fire`, `_popView`, `_pushView`, `_selectedView`, `NONE`, `_renderToView`, `LastView`, `OpenView`, `CloseView`, `NewWelcomeBack`, `Open`, `Close`, `Enum`, `CoreGuiType`, `PlayerList`, `Chat`, `IsUICovered`, `WelcomeBack`, `SetTag`, `pcall`, `Frame`, `TopFrame`, `MouseButton1Click`, `Connect`, `OnGuiOpen`, `OnGuiClose`, `Start`, `game`, `ReplicatedStorage`, `GetService`, `StarterGui`, `Players`, `require`, `Packages`, `Signal`, `ClientGameModules`, `CoreCall`, `GuiHandler`, `Controllers`, `UI`, `UIStateController`, `LocalPlayer`, `PlayerGui`, `WaitForChild`

### [945] ReplicatedStorage.Controllers.WelcomeBackController.WelcomeBackController
`Script` · bytecode v9 · 787 bytes · 19 constants
- **Key API:** GetAttribute, SetAttribute
- Constants: `debug`, `setmemorycategory`, `Name`, `Start`, `script`, `Parent`, `require`, `Loaded`, `SetAttribute`, `Init`, `GetAttribute`, `GetAttributeChangedSignal`, `Wait`, `pcall`, `task`, `spawn`, `error`, `%*:Init() - %*`, `format`

### [946] ReplicatedStorage.Gacha.Hitbox.BillboardGui.SpecialTimer
`Script` · bytecode v9 · 1041 bytes · 28 constants
- **Services:** ReplicatedStorage, game, workspace
- **Key API:** Destroy, Disconnect, GetAttribute, GetService, WaitForChild
- Constants: `getTimestamps`, `endTimestamp`, `os`, `time`, `TimerLabel`, `ValueConvertor`, `FormatTimeWithDaysFull`, `Text`, `Parent`, `Destroy`, `Disconnect`, `game`, `ReplicatedStorage`, `GetService`, `workspace`, `ClientModulesLoaded`, `GetAttribute`, `GetAttributeChangedSignal`, `Wait`, `Spawn`, `WaitForChild`, `require`, `Common`, `Utils`, `@game/ReplicatedStorage/Shared/InfiniteBattlepass/InfiniteBattlepassData`, `script`, `Thread`, `Every`

### [947] ReplicatedStorage.Misc.DragonMoves.BigDragon.Serpent
`ModuleScript` · bytecode v9 · 1612 bytes · 31 constants
- **Services:** RunService, game
- **Key API:** Connect, Disconnect, FindFirstChild, GetDescendants, GetService, IsA
- Constants: `Name`, `Position`, `Parent`, `WorldPosition`, `Magnitude`, `Unit`, `math`, `abs`, `A`, `FindFirstChild`, `Bone`, `FindFirstChildWhichIsA`, `Attachment`, `WorldCFrame`, `CFrame`, `lookAt`, `moveSegment`, `Disconnect`, `Heartbeat`, `Connect`, `Jaw`, `Top`, `EyesFlare`, `FireUP`, `Night.eff`, `next`, `GetDescendants`, `IsA`, `game`, `RunService`, `GetService`

### [948] ReplicatedStorage.Misc.DragonMoves.FixDragon2.Serpent
`ModuleScript` · bytecode v9 · 1598 bytes · 31 constants
- **Services:** RunService, game
- **Key API:** Connect, Disconnect, FindFirstChild, GetDescendants, GetService, IsA
- Constants: `Name`, `Position`, `Parent`, `WorldPosition`, `Magnitude`, `Unit`, `math`, `abs`, `A`, `FindFirstChild`, `Bone`, `FindFirstChildWhichIsA`, `Attachment`, `WorldCFrame`, `CFrame`, `lookAt`, `moveSegment`, `Disconnect`, `Heartbeat`, `Connect`, `Jaw`, `Top`, `EyesFlare`, `FireUP`, `Night.eff`, `next`, `GetDescendants`, `IsA`, `game`, `RunService`, `GetService`

### [949] ReplicatedStorage.Misc.HellHook.Hook.Segment
`ModuleScript` · bytecode v9 · 1353 bytes · 19 constants
- **Services:** RunService, game
- **Key API:** Connect, Disconnect, GetService, new
- Constants: `Bone`, `FindFirstChildWhichIsA`, `collectBones`, `CFrame`, `Position`, `Lerp`, `lookAt`, `Angles`, `WorldCFrame`, `LookVector`, `adjust`, `Parent`, `Disconnect`, `Heartbeat`, `Connect`, `new`, `game`, `RunService`, `GetService`

### [950] ReplicatedStorage.Misc.HellHook.MaxHook.Segment
`ModuleScript` · bytecode v9 · 1353 bytes · 19 constants
- **Services:** RunService, game
- **Key API:** Connect, Disconnect, GetService, new
- Constants: `Bone`, `FindFirstChildWhichIsA`, `collectBones`, `CFrame`, `Position`, `Lerp`, `lookAt`, `Angles`, `WorldCFrame`, `LookVector`, `adjust`, `Parent`, `Disconnect`, `Heartbeat`, `Connect`, `new`, `game`, `RunService`, `GetService`

### [952] ReplicatedStorage.Misc.LightningBolt
`ModuleScript` · bytecode v9 · 5960 bytes · 89 constants
- **Services:** Debris, RunService, game, workspace
- **Key API:** Clone, Connect, Destroy, GetService, new
- Constants: `math`, `abs`, `clamp`, `DiscretePulse`, `noise`, `NoiseBetween`, `CubicBezier`, `setmetatable`, `Enabled`, `Attachment0`, `Attachment1`, `CurveSize0`, `CurveSize1`, `MinRadius`, `MaxRadius`, `Frequency`, `AnimationSpeed`, `Thickness`, `MinThicknessMultiplier`, `MaxThicknessMultiplier`, `MinTransparency`, `MaxTransparency`, `PulseSpeed`, `PulseLength`, `FadeLength`, `ContractFrom`, `Color3`, `new`, `Color`, `ColorOffsetSpeed`, `Parts`, `workspace`, `CurrentCamera`, `WorldPosition`, `WorldAxis`, `CFrame`, `lookAt`, `Position`, `Clone`, `Magnitude`, `Vector3`, `Size`, `Parent`, `AddItem`, `PartsHidden`, `DisabledTransparency`, `StartT`, `random`, `RanNum`, `RefIndex`, `Destroy`, `wait`, `pairs`, `exp`, `Angles`, `acos`, `Transparency`, `max`, `typeof`, `Keypoints`, `Time`, `Value`, `lerp`, `game`, `RunService`, `GetService`, `Debris`, `Instance`, `Part`, `TopSurface`, `BottomSurface`, `Anchored`, `CanCollide`, `Cylinder`, `Shape`, `BoltPart`, `Name`, `Enum`, `Material`, `Neon`, `CastShadow`, `Locked`, `os`, `clock`, `Random`, `Inverse`, `__index`, `Heartbeat`, `Connect`

### [953] ReplicatedStorage.Misc.LightningBolt.LightningExplosion
`ModuleScript` · bytecode v9 · 4464 bytes · 84 constants
- **Services:** RunService, game, workspace
- **Key API:** Clone, Connect, Destroy, GetService, new
- Constants: `CFrame`, `lookAt`, `Vector3`, `new`, `Angles`, `NextNumber`, `math`, `cos`, `acos`, `LookVector`, `RandomVectorOffsetBetween`, `setmetatable`, `Size`, `NumBolts`, `ColorSequence`, `Color3`, `Color`, `BoltColor`, `UpVector`, `workspace`, `CurrentCamera`, `Instance`, `Part`, `LightningExplosion`, `Name`, `Anchored`, `CanCollide`, `Locked`, `CastShadow`, `Transparency`, `inverse`, `Parent`, `Attachment`, `script`, `ExplosionBrightspot`, `Clone`, `GlareEmitter`, `PlasmaEmitter`, `clamp`, `NumberSequence`, `NumberRange`, `Speed`, `typeof`, `toHSV`, `fromHSV`, `Keypoints`, `Value`, `ColorSequenceKeypoint`, `Time`, `Enabled`, `WorldPosition`, `WorldAxis`, `AnimationSpeed`, `Thickness`, `PulseLength`, `ColorOffsetSpeed`, `Frequency`, `MinRadius`, `MaxRadius`, `FadeLength`, `PulseSpeed`, `MinThicknessMultiplier`, `MaxThicknessMultiplier`, `MinDistance`, `MaxDistance`, `Unit`, `Velocity`, `Bolts`, `StartT`, `RefIndex`, `Destroy`, `pairs`, `Attachment1`, `require`, `LightningSparks`, `Random`, `os`, `clock`, `__index`, `game`, `RunService`, `GetService`, `Heartbeat`, `Connect`

### [954] ReplicatedStorage.Misc.LightningBolt.LightningSparks
`ModuleScript` · bytecode v9 · 3433 bytes · 63 constants
- **Services:** RunService, game
- **Key API:** Connect, Destroy, GetService, new
- Constants: `setmetatable`, `Enabled`, `LightningBolt`, `MaxSparkCount`, `MinSpeed`, `MaxSpeed`, `MinDistance`, `MaxDistance`, `MinPartsPerSpark`, `MaxPartsPerSpark`, `SparksN`, `SlotTable`, `RefIndex`, `new`, `pairs`, `Parts`, `Parent`, `Destroy`, `CFrame`, `lookAt`, `Vector3`, `Angles`, `NextNumber`, `math`, `cos`, `acos`, `LookVector`, `RandomVectorOffset`, `Transparency`, `ceil`, `NextInteger`, `abs`, `floor`, `Position`, `RightVector`, `Size`, `X`, `WorldPosition`, `Unit`, `WorldAxis`, `MinRadius`, `MaxRadius`, `AnimationSpeed`, `Y`, `Thickness`, `MinThicknessMultiplier`, `MaxThicknessMultiplier`, `PulseLength`, `PulseSpeed`, `FadeLength`, `Color3`, `toHSV`, `Color`, `fromHSV`, `require`, `script`, `Random`, `__index`, `game`, `RunService`, `GetService`, `Heartbeat`, `Connect`

### [955] ReplicatedStorage.Observers.Accessories.AccessoryNebulaSniper
`ModuleScript` · bytecode v9 · 935 bytes · 23 constants
- **Services:** ReplicatedStorage, RunService, TweenService, game, workspace
- **Key API:** Connect, Disconnect, GetAttribute, GetService, new
- Constants: `CFrame`, `Angles`, `workspace`, `GetServerTimeNow`, `new`, `C0`, `Disconnect`, `Folder`, `FindFirstAncestorWhichIsA`, `Seed`, `GetAttribute`, `PostSimulation`, `Connect`, `game`, `ReplicatedStorage`, `GetService`, `TweenService`, `RunService`, `require`, `Packages`, `Observers`, `observeTag`, `AccessoryNebulaSniper`

### [956] ReplicatedStorage.Observers.Accessories.AccessoryVoidGuardian
`ModuleScript` · bytecode v9 · 992 bytes · 24 constants
- **Services:** ReplicatedStorage, RunService, TweenService, game, workspace
- **Key API:** Connect, Disconnect, GetAttribute, GetService, new
- Constants: `CFrame`, `Angles`, `workspace`, `GetServerTimeNow`, `new`, `C0`, `Disconnect`, `Folder`, `FindFirstAncestorWhichIsA`, `Seed`, `GetAttribute`, `Side`, `PostSimulation`, `Connect`, `game`, `ReplicatedStorage`, `GetService`, `TweenService`, `RunService`, `require`, `Packages`, `Observers`, `observeTag`, `AccessoryVoidGuardian`

### [957] ReplicatedStorage.Observers.Accessories.HiganbanaAccessory
`ModuleScript` · bytecode v9 · 1564 bytes · 34 constants
- **Services:** ReplicatedStorage, RunService, game, workspace
- **Key API:** Connect, Disconnect, GetAttribute, GetService, new
- Constants: `CurrentEmote`, `GetAttribute`, `C0`, `os`, `clock`, `math`, `sin`, `cos`, `CFrame`, `new`, `Angles`, `Disconnect`, `Model`, `FindFirstAncestorWhichIsA`, `Folder`, `Seed`, `HeightFrequency`, `HeightTravel`, `SwayFrequency`, `SwayAngle`, `YawFrequency`, `YawAngle`, `PostSimulation`, `Connect`, `game`, `ReplicatedStorage`, `GetService`, `RunService`, `require`, `Packages`, `Observers`, `observeTag`, `HiganbanaAccessory`, `workspace`

### [958] ReplicatedStorage.Observers.Accessories.ProyectionAccessory
`ModuleScript` · bytecode v9 · 2688 bytes · 56 constants
- **Services:** Players, TweenService, game
- **Key API:** Clone, Destroy, GetChildren, GetService, WaitForChild, new
- Constants: `Enabling particles`, `info`, `Enabled`, `enableParticles`, `Attaching trails`, `Clone`, `Add`, `GetChildren`, `BasePart[Name="%*"]`, `Name`, `format`, `QueryDescendants`, `Could not find part`, `in character`, `warn`, `ParticleEmitter`, `table`, `insert`, `>Attachment`, `Parent`, `Destroy`, `Attached trails`, `attachTrails`, `Starting accessory`, `MoveDirection`, `Magnitude`, `task`, `wait`, `Stopping accessory`, `Cleaning up accessory`, `GetPlayerFromCharacter`, `Humanoid`, `WaitForChild`, `HumanoidRootPart`, `IsDescendantOf`, `Accessory is not a descendant of character`, `new`, `delay`, `spawn`, `game`, `TweenService`, `GetService`, `Players`, `require`, `@game/ReplicatedStorage/Packages/Observers`, `@game/ReplicatedStorage/Packages/Trove`, `@game/ReplicatedStorage/Common/Utils/Utilities/Inst`, `@game/ReplicatedStorage/Common/Logger`, `namespace`, `Accessories`, `enabled`, `ProyectionAccessory`, `scope`, `script`, `Trails`, `observeTag`

### [959] ReplicatedStorage.Observers.Attacks.Attacks.LavaRing
`ModuleScript` · bytecode v9 · 2417 bytes · 64 constants
- **Services:** Players, ReplicatedStorage, RunService, SoundService, game, workspace
- **Key API:** Clone, Connect, Destroy, GetAttribute, GetDescendants, GetService, IsA, Once, Play, new
- Constants: `Value`, `ScaleTo`, `Dungeons_HitboxDamage`, `RemoveTag`, `Destroy`, `Duration`, `GetAttribute`, `MaxSize`, `new`, `Model`, `IsA`, `Instance`, `NumberValue`, `Add`, `GetPropertyChangedSignal`, `Connect`, `MaxScale`, `Size`, `Y`, `Vector3`, `fastTween`, `TweenInfo`, `Enum`, `EasingStyle`, `Sine`, `GetDescendants`, `BasePart`, `table`, `insert`, `math`, `max`, `FadeDelay`, `EasingDirection`, `In`, `Transparency`, `task`, `delay`, `NoSound`, `Misc`, `LavaBrickSFX`, `Clone`, `Parent`, `Ended`, `Once`, `Play`, `game`, `ReplicatedStorage`, `GetService`, `SoundService`, `RunService`, `Players`, `require`, `Packages`, `Net`, `Trove`, `Observers`, `ServerInfo`, `Shared`, `FastUtils`, `RequestSelfDamage`, `RemoteEvent`, `observeTag`, `Dungeons_LavaRingAttack`, `workspace`

### [960] ReplicatedStorage.Observers.Attacks.Attacks.PurpleBalls
`ModuleScript` · bytecode v9 · 1436 bytes · 37 constants
- **Services:** Players, ReplicatedStorage, RunService, TweenService, game, workspace
- **Key API:** Destroy, GetAttribute, GetService, new
- Constants: `Destroy`, `new`, `Size`, `fastTween`, `TweenInfo`, `Enum`, `EasingStyle`, `Sine`, `EasingDirection`, `InOut`, `Add`, `Position`, `Target`, `GetAttribute`, `In`, `Transparency`, `game`, `ReplicatedStorage`, `GetService`, `RunService`, `TweenService`, `Players`, `require`, `Packages`, `Net`, `Trove`, `Observers`, `ServerInfo`, `Common`, `Utils`, `Shared`, `FastUtils`, `RequestSelfDamage`, `RemoteEvent`, `observeTag`, `Dungeons_PurpleBallAttack`, `workspace`

### [961] ReplicatedStorage.Observers.Attacks.Attacks.Serpent_BlueBeam
`ModuleScript` · bytecode v9 · 1311 bytes · 34 constants
- **Services:** Players, ReplicatedStorage, RunService, SoundService, game, workspace
- **Key API:** Destroy, GetAttribute, GetService, new
- Constants: `TotalTargets`, `GetAttribute`, `task`, `wait`, `TargetDelay%*`, `format`, `TargetTime%*`, `fastTween`, `TweenInfo`, `new`, `Enum`, `EasingStyle`, `Sine`, `CFrame`, `Target%*`, `Add`, `Destroy`, `spawn`, `game`, `ReplicatedStorage`, `GetService`, `SoundService`, `RunService`, `Players`, `require`, `Packages`, `Trove`, `Observers`, `ServerInfo`, `Shared`, `FastUtils`, `observeTag`, `Dungeons_SerpentBlueBeam`, `workspace`

### [962] ReplicatedStorage.Observers.Attacks.Attacks.Skulls
`ModuleScript` · bytecode v9 · 2468 bytes · 57 constants
- **Services:** Players, ReplicatedStorage, RunService, TweenService, game, workspace
- **Key API:** Connect, Destroy, GetAttribute, GetDescendants, GetService, IsA, Play, new
- Constants: `PrimaryPart`, `CFrame`, `new`, `fromOrientation`, `PivotTo`, `Holder`, `Beam`, `Play`, `GetDescendants`, `ParticleEmitter`, `IsA`, `Enabled`, `Thread`, `LoopFor`, `Add`, `Ended`, `Wait`, `fastTween`, `TweenInfo`, `Enum`, `EasingStyle`, `Sine`, `EasingDirection`, `In`, `Volume`, `Back`, `X`, `HiddenY`, `GetAttribute`, `Z`, `Destroy`, `MoveTo`, `InOut`, `Completed`, `Connect`, `game`, `ReplicatedStorage`, `GetService`, `RunService`, `TweenService`, `Players`, `require`, `Packages`, `Net`, `Trove`, `ServerInfo`, `Common`, `Utils`, `Shared`, `FastUtils`, `Observers`, `SpeedModifiers`, `RequestSelfDamage`, `RemoteEvent`, `observeTag`, `Dungeons_SkullAttack`, `workspace`

### [963] ReplicatedStorage.Observers.Attacks.Classic.BallForceFieldBounce
`ModuleScript` · bytecode v9 · 1352 bytes · 32 constants
- **Services:** Players, ReplicatedStorage, RunService, SoundService, game, workspace
- **Key API:** Connect, FindFirstChild, GetService
- Constants: `Character`, `HumanoidRootPart`, `FindFirstChild`, `Position`, `Magnitude`, `Size`, `Unit`, `AssemblyLinearVelocity`, `table`, `find`, `remove`, `insert`, `game`, `ReplicatedStorage`, `GetService`, `SoundService`, `RunService`, `Players`, `require`, `Packages`, `Net`, `Trove`, `Observers`, `ServerInfo`, `Shared`, `FastUtils`, `LocalPlayer`, `PostSimulation`, `Connect`, `observeTag`, `BallForceFieldBounce`, `workspace`

### [964] ReplicatedStorage.Observers.Attacks.Cupid.CupidArrowRain
`ModuleScript` · bytecode v9 · 2975 bytes · 61 constants
- **Services:** ReplicatedStorage, RunService, TweenService, game, workspace
- **Key API:** Clone, Connect, Destroy, FindFirstChild, GetAttribute, GetDescendants, GetService, IsA, Play, new
- Constants: `lerp`, `quadBezier`, `CFrame`, `new`, `GetPivot`, `Position`, `Angles`, `PivotTo`, `_cleaning`, `Remove`, `BasePart`, `IsA`, `Anchored`, `GetDescendants`, `ParticleEmitter`, `Enabled`, `Assets`, `CupidBoss`, `HeartExplosion`, `Clone`, `HideInCutscene`, `AddTag`, `workspace`, `Runtime`, `Parent`, `Rate`, `Emit`, `Beam`, `PointLight`, `Sounds`, `ExplosionHit`, `Add`, `Play`, `Transparency`, `task`, `wait`, `Clean`, `Destroy`, `TravelTime`, `GetAttribute`, `Target`, `Magnitude`, `ArrowShaft`, `FindFirstChild`, `Rotation`, `PostSimulation`, `Connect`, `game`, `ReplicatedStorage`, `GetService`, `TweenService`, `RunService`, `require`, `Packages`, `Observers`, `Trove`, `ServerInfo`, `Common`, `Utils`, `observeTag`, `CupidArrowRain`

### [965] ReplicatedStorage.Observers.Attacks.Cupid.CupidHeartWall
`ModuleScript` · bytecode v9 · 1568 bytes · 36 constants
- **Services:** ReplicatedStorage, RunService, TweenService, game, workspace
- **Key API:** Connect, Destroy, GetAttribute, GetService, new
- Constants: `lerp`, `Lerp`, `ScaleTo`, `CFrame`, `new`, `PivotTo`, `_cleaning`, `Remove`, `Clean`, `Destroy`, `TargetScale`, `GetAttribute`, `TravelTime`, `TargetPosition`, `GetPivot`, `Position`, `Rotation`, `GetScale`, `PostSimulation`, `Connect`, `Add`, `game`, `ReplicatedStorage`, `GetService`, `TweenService`, `RunService`, `require`, `Packages`, `Observers`, `Trove`, `ServerInfo`, `Common`, `Utils`, `observeTag`, `CupidHeartWall`, `workspace`

### [966] ReplicatedStorage.Observers.Attacks.Cupid.CupidVanishingCloud
`ModuleScript` · bytecode v9 · 2217 bytes · 53 constants
- **Services:** Debris, ReplicatedStorage, RunService, TweenService, game, workspace
- **Key API:** Destroy, GetAttribute, GetService, Play, SetAttribute, new
- Constants: `lerp`, `fastTween`, `TweenInfo`, `new`, `Transparency`, `Play`, `RedHighlightFlash`, `RemoveTag`, `Destroy`, `workspace`, `GetServerTimeNow`, `StartTime`, `GetAttribute`, `Duration`, `FadeTime`, `FadeDelay`, `Instance`, `Highlight`, `Add`, `Color3`, `fromRGB`, `HighlightColor`, `SetAttribute`, `FillColor`, `OutlineColor`, `FillTransparency`, `OutlineTransparency`, `Adornee`, `Enabled`, `Parent`, `task`, `wait`, `EndTime`, `AddTag`, `AddItem`, `delay`, `game`, `ReplicatedStorage`, `GetService`, `TweenService`, `RunService`, `Debris`, `require`, `Packages`, `Observers`, `Trove`, `ServerInfo`, `Common`, `Utils`, `Shared`, `FastUtils`, `observeTag`, `CupidVanishingCloud`

### [967] ReplicatedStorage.Observers.Attacks.Evil Elf.EvilElfFakeGift
`ModuleScript` · bytecode v9 · 1342 bytes · 35 constants
- **Services:** ReplicatedStorage, RunService, TweenService, game
- **Key API:** Destroy, GetAttribute, GetService, Play, new
- Constants: `fastTween`, `TweenInfo`, `new`, `Enum`, `EasingStyle`, `Back`, `EasingDirection`, `Out`, `CFrame`, `Add`, `Play`, `Destroy`, `TargetCFrame`, `GetAttribute`, `Size`, `Y`, `Duration`, `Quad`, `task`, `delay`, `game`, `ReplicatedStorage`, `GetService`, `TweenService`, `RunService`, `require`, `Packages`, `Observers`, `Trove`, `Common`, `Utils`, `Shared`, `FastUtils`, `observeTagNoAncestry`, `EvilElfFakeGift`

### [968] ReplicatedStorage.Observers.Attacks.Evil Elf.EvilElfIcePlatform
`ModuleScript` · bytecode v9 · 1508 bytes · 36 constants
- **Services:** ReplicatedStorage, RunService, TweenService, game
- **Key API:** Destroy, GetAttribute, GetService, Play, new
- Constants: `PhysicalProperties`, `new`, `Enum`, `Material`, `Plastic`, `CustomPhysicalProperties`, `fastTween`, `TweenInfo`, `Transparency`, `Add`, `Play`, `Destroy`, `MaxSize`, `GetAttribute`, `Duration`, `CanCollide`, `EasingStyle`, `Sine`, `Size`, `task`, `delay`, `game`, `ReplicatedStorage`, `GetService`, `TweenService`, `RunService`, `require`, `Packages`, `Observers`, `Trove`, `Common`, `Utils`, `Shared`, `FastUtils`, `observeTagNoAncestry`, `EvilElfIcePlatform`

### [969] ReplicatedStorage.Observers.Attacks.Evil Elf.EvilElfSnowball
`ModuleScript` · bytecode v9 · 2439 bytes · 58 constants
- **Services:** ReplicatedStorage, RunService, TweenService, game, workspace
- **Key API:** Clone, Connect, Create, Destroy, GetAttribute, GetDescendants, GetService, IsA, Play, new
- Constants: `lerp`, `quadBezier`, `CFrame`, `new`, `lookAt`, `PivotTo`, `_cleaning`, `Remove`, `GetDescendants`, `ParticleEmitter`, `IsA`, `Enabled`, `Assets`, `EvilElfBoss`, `SnowExplosion`, `Clone`, `Position`, `workspace`, `Runtime`, `Parent`, `Visual`, `PlayEffects`, `Sound`, `Play`, `task`, `wait`, `TweenInfo`, `Enum`, `EasingStyle`, `Sine`, `EasingDirection`, `Out`, `Transparency`, `Create`, `Clean`, `Destroy`, `TravelTime`, `GetAttribute`, `GetPivot`, `Target`, `Magnitude`, `PostSimulation`, `Connect`, `Add`, `game`, `ReplicatedStorage`, `GetService`, `TweenService`, `RunService`, `require`, `Packages`, `Observers`, `Trove`, `ServerInfo`, `Common`, `Utils`, `observeTagNoAncestry`, `EvilElfSnowball`

### [970] ReplicatedStorage.Observers.Attacks.Evil Elf.RedHighlightFlash
`ModuleScript` · bytecode v9 · 1847 bytes · 46 constants
- **Services:** ReplicatedStorage, RunService, TweenService, game, workspace
- **Key API:** Clone, Connect, Destroy, GetAttribute, GetService, Play, new
- Constants: `FillTransparency`, `OutlineTransparency`, `Play`, `Destroy`, `new`, `HighlightDuration`, `GetAttribute`, `EndTime`, `workspace`, `GetServerTimeNow`, `math`, `max`, `Highlight`, `FindFirstChildWhichIsA`, `Instance`, `Add`, `HighlightColor`, `Color3`, `fromRGB`, `FillColor`, `OutlineColor`, `Enum`, `HighlightDepthMode`, `Occluded`, `DepthMode`, `Parent`, `Assets`, `Sounds`, `CupidBoss`, `Tick`, `Clone`, `Heartbeat`, `Connect`, `game`, `ReplicatedStorage`, `GetService`, `TweenService`, `RunService`, `require`, `Packages`, `Observers`, `Trove`, `Common`, `Utils`, `observeTagNoAncestry`, `RedHighlightFlash`

### [971] ReplicatedStorage.Observers.Attacks.FallingPlatform
`ModuleScript` · bytecode v9 · 4809 bytes · 78 constants
- **Services:** Players, ReplicatedStorage, RunService, TweenService, game, workspace
- **Key API:** Connect, Destroy, Disconnect, GetAttribute, GetService, IsA, SetAttribute, WaitForChild, new
- Constants: `Falling`, `SetAttribute`, `Parent`, `Humanoid`, `FindFirstChildOfClass`, `GetAttribute`, `coroutine`, `status`, `dead`, `pcall`, `task`, `cancel`, `workspace`, `GetServerTimeNow`, `delay`, `Disconnect`, `PivotTo`, `isActive`, `getTimeUntil`, `CFrame`, `new`, `NextNumber`, `Value`, `Lerp`, `running`, `Size`, `Magnitude`, `identity`, `PostSimulation`, `Connect`, `wait`, `fastTween`, `TweenInfo`, `Enum`, `EasingStyle`, `Sine`, `EasingDirection`, `In`, `Completed`, `Wait`, `math`, `min`, `Out`, `Cancel`, `Destroy`, `updateFalling`, `defer`, `requestUpdateFalling`, `Model`, `IsA`, `Main`, `WaitForChild`, `warn`, `Failed to find BasePart for FallingPlatform:`, `FallHeight`, `X`, `Z`, `Touched`, `Instance`, `CFrameValue`, `GetPivot`, `Changed`, `GetAttributeChangedSignal`, `game`, `ReplicatedStorage`, `GetService`, `RunService`, `TweenService`, `Players`, `require`, `Packages`, `Observers`, `Shared`, `FastUtils`, `IsServer`, `Random`, `observeTag`, `Boss_FallingPlatform`

### [972] ReplicatedStorage.Observers.Attacks.HitboxDamage
`ModuleScript` · bytecode v9 · 5147 bytes · 83 constants
- **Services:** Players, ReplicatedStorage, RunService, TweenService, game, workspace
- **Key API:** Connect, Disconnect, FindFirstChild, FireServer, GetAttribute, GetDescendants, GetService, IsA, SetAttribute, new
- Constants: `Thread`, `SafeCancel`, `Disconnect`, `cancelAll`, `cancelDamage`, `cancelSlow`, `EnableVFX`, `GetAttribute`, `DisableVFX`, `GetDescendants`, `ParticleEmitter`, `IsA`, `Beam`, `Enabled`, `Visual`, `TurnOffVisuals`, `cleanup`, `LastHitboxDamage`, `SetAttribute`, `Damage`, `Character`, `os`, `clock`, `task`, `delay`, `FireServer`, `RemoteEvent`, `FindFirstChildWhichIsA`, `damage`, `LocalPlayer`, `HitboxDamage%*`, `format`, `Utils`, `MinDebuff`, `SlowSpeedValue`, `Priority`, `DEBUFF`, `SetModifierFor`, `SlowDuration`, `slow`, `PlayEffects`, `OverlapParams`, `new`, `MaxParts`, `Enum`, `RaycastFilterType`, `Include`, `FilterType`, `HumanoidRootPart`, `FindFirstChild`, `FilterDescendantsInstances`, `workspace`, `GetPartsInPart`, `DamageCooldown`, `SlowSpeed`, `SlowCooldown`, `VFXWaitTime`, `DamageTimeout`, `SlowTimeout`, `PostSimulation`, `Connect`, `DamageRootOnly`, `math`, `random`, `DamageHitbox`, `WaitTime`, `game`, `ReplicatedStorage`, `GetService`, `RunService`, `TweenService`, `Players`, `require`, `Packages`, `Net`, `Observers`, `ServerInfo`, `Common`, `Shared`, `SpeedModifiers`, `RequestSelfDamage`, `observeTag`, `Dungeons_HitboxDamage`

### [973] ReplicatedStorage.Observers.Attacks.HitboxFill
`ModuleScript` · bytecode v9 · 1437 bytes · 35 constants
- **Services:** ReplicatedStorage, RunService, TweenService, game, workspace
- **Key API:** Create, Destroy, Disconnect, GetAttribute, GetService, Once, Play, WaitForChild, new
- Constants: `Destroy`, `TweenInfo`, `new`, `Enum`, `EasingStyle`, `Sine`, `EasingDirection`, `Out`, `Transparency`, `Create`, `Play`, `task`, `delay`, `Cancel`, `Disconnect`, `Red`, `WaitForChild`, `Fill`, `WaitTime`, `GetAttribute`, `Size`, `Completed`, `Once`, `game`, `ReplicatedStorage`, `GetService`, `TweenService`, `RunService`, `require`, `Packages`, `Observers`, `ServerInfo`, `observeTag`, `HitboxFill`, `workspace`

### [974] ReplicatedStorage.Observers.Attacks.Horseman.HorsemanFireBall
`ModuleScript` · bytecode v9 · 2658 bytes · 61 constants
- **Services:** ReplicatedStorage, RunService, TweenService, game, workspace
- **Key API:** Clone, Connect, Create, Destroy, GetAttribute, GetDescendants, GetService, IsA, Play, new
- Constants: `lerp`, `quadBezier`, `CFrame`, `new`, `lookAt`, `PivotTo`, `_cleaning`, `Remove`, `BasePart`, `IsA`, `Anchored`, `GetDescendants`, `ParticleEmitter`, `Enabled`, `Assets`, `PhoenixBoss`, `FireBallImpact`, `Clone`, `Position`, `workspace`, `Runtime`, `Parent`, `Visual`, `PlayEffects`, `Sounds`, `FireballHit`, `Add`, `Play`, `task`, `wait`, `TweenInfo`, `Enum`, `EasingStyle`, `Sine`, `EasingDirection`, `Out`, `Transparency`, `Create`, `Clean`, `Destroy`, `TravelTime`, `GetAttribute`, `GetPivot`, `Target`, `Magnitude`, `PostSimulation`, `Connect`, `game`, `ReplicatedStorage`, `GetService`, `TweenService`, `RunService`, `require`, `Packages`, `Observers`, `Trove`, `ServerInfo`, `Common`, `Utils`, `observeTag`, `HorsemanFireBall`

### [975] ReplicatedStorage.Observers.Attacks.Omega.DroneProjectile
`ModuleScript` · bytecode v9 · 2605 bytes · 58 constants
- **Services:** ReplicatedStorage, RunService, TweenService, game, workspace
- **Key API:** Clone, Connect, Destroy, GetAttribute, GetDescendants, GetService, IsA, Play, new
- Constants: `lerp`, `quadBezier`, `CFrame`, `new`, `lookAt`, `PivotTo`, `_cleaning`, `Remove`, `Assets`, `PhoenixBoss`, `FireBallImpact`, `Clone`, `workspace`, `Runtime`, `Parent`, `Visual`, `PlayEffects`, `Sounds`, `FireballHit`, `Add`, `Play`, `GetDescendants`, `BasePart`, `IsA`, `Transparency`, `ParticleEmitter`, `Trail`, `Beam`, `BillboardGui`, `Enabled`, `task`, `wait`, `Clean`, `Destroy`, `TravelTime`, `GetAttribute`, `GetPivot`, `Position`, `Target`, `Magnitude`, `PostSimulation`, `Connect`, `game`, `ReplicatedStorage`, `GetService`, `TweenService`, `RunService`, `require`, `Packages`, `Observers`, `Trove`, `ServerInfo`, `Common`, `Utils`, `isBossFightServer`, `isDungeonsMatchServer`, `observeTag`, `DroneProjectile`

### [976] ReplicatedStorage.Observers.Attacks.Phase 2.Boulder
`ModuleScript` · bytecode v9 · 2430 bytes · 58 constants
- **Services:** ReplicatedStorage, RunService, TweenService, game, workspace
- **Key API:** Clone, Connect, Create, Destroy, GetAttribute, GetDescendants, GetService, IsA, Play, new
- Constants: `lerp`, `quadBezier`, `CFrame`, `new`, `lookAt`, `PivotTo`, `_cleaning`, `Remove`, `GetDescendants`, `ParticleEmitter`, `IsA`, `Enabled`, `Assets`, `GalaxyBoss`, `BoulderHit`, `Clone`, `workspace`, `Runtime`, `Parent`, `Visual`, `PlayEffects`, `task`, `wait`, `TweenInfo`, `Enum`, `EasingStyle`, `Sine`, `EasingDirection`, `Out`, `Transparency`, `Create`, `Play`, `Clean`, `Destroy`, `TravelTime`, `GetAttribute`, `GetPivot`, `Position`, `Target`, `Magnitude`, `PostSimulation`, `Connect`, `Add`, `game`, `ReplicatedStorage`, `GetService`, `TweenService`, `RunService`, `require`, `Packages`, `Observers`, `Trove`, `ServerInfo`, `Common`, `Utils`, `isBossFightServer`, `observeTag`, `GalaxyBossBoulder`

### [977] ReplicatedStorage.Observers.Attacks.Phoenix.PhoenixFireBall
`ModuleScript` · bytecode v9 · 2634 bytes · 61 constants
- **Services:** ReplicatedStorage, RunService, TweenService, game, workspace
- **Key API:** Clone, Connect, Create, Destroy, GetAttribute, GetDescendants, GetService, IsA, Play, new
- Constants: `lerp`, `quadBezier`, `CFrame`, `new`, `lookAt`, `PivotTo`, `_cleaning`, `Remove`, `GetDescendants`, `ParticleEmitter`, `IsA`, `Enabled`, `Assets`, `PhoenixBoss`, `FireBallImpact`, `Clone`, `Position`, `workspace`, `Runtime`, `Parent`, `Visual`, `PlayEffects`, `Sounds`, `FireballHit`, `Add`, `Play`, `task`, `wait`, `TweenInfo`, `Enum`, `EasingStyle`, `Sine`, `EasingDirection`, `Out`, `Transparency`, `Create`, `Clean`, `Destroy`, `TravelTime`, `GetAttribute`, `GetPivot`, `Target`, `Magnitude`, `PostSimulation`, `Connect`, `game`, `ReplicatedStorage`, `GetService`, `TweenService`, `RunService`, `require`, `Packages`, `Observers`, `Trove`, `ServerInfo`, `Common`, `Utils`, `isBossFightServer`, `isDungeonsMatchServer`, `observeTag`, `PhoenixFireBall`

### [978] ReplicatedStorage.Observers.Attacks.SkeletonDeathMove
`ModuleScript` · bytecode v9 · 1857 bytes · 50 constants
- **Services:** ReplicatedStorage, RunService, TweenService, game, workspace
- **Key API:** Clone, Connect, Create, Destroy, GetService, LoadAnimation, Once, Play, WaitForChild, new
- Constants: `TimePosition`, `Destroy`, `Enum`, `PlaybackState`, `Completed`, `Skelly`, `WaitForChild`, `Circle.001`, `Root`, `Humanoid`, `FindFirstChildWhichIsA`, `Animator`, `Death`, `LoadAnimation`, `Play`, `Pin`, `GetMarkerReachedSignal`, `Connect`, `GOTO`, `Wait`, `task`, `wait`, `RGGround`, `Clone`, `Parent`, `Ended`, `TweenInfo`, `new`, `EasingStyle`, `Linear`, `EasingDirection`, `InOut`, `CFrame`, `Create`, `Once`, `game`, `ReplicatedStorage`, `GetService`, `TweenService`, `RunService`, `require`, `Packages`, `Observers`, `ServerInfo`, `isBossFightServer`, `Assets`, `GalaxyBoss`, `observeTag`, `GalaxyBossSkeletonDeathMove`, `workspace`

### [979] ReplicatedStorage.Observers.CharacterSmartBone
`ModuleScript` · bytecode v9 · 1527 bytes · 27 constants
- **Services:** ReplicatedStorage, game, workspace
- **Key API:** Connect, GetAttribute, GetService, SetAttribute
- Constants: `GetAttribute`, `SetAttribute`, `apply_dt`, `SavedQualityLevel`, `Value`, `Gravity`, `Force`, `SmartBone`, `AddTag`, `RemoveTag`, `workspace`, `CurrentCamera`, `IsDescendantOf`, `game`, `ReplicatedStorage`, `GetService`, `require`, `Packages`, `Observers`, `UserSettings`, `GameSettings`, `Changed`, `Connect`, `observeTag`, `CharacterSmartBone`, `Alive`, `Dead`

### [980] ReplicatedStorage.Observers.Lobby.AFK
`ModuleScript` · bytecode v9 · 1396 bytes · 38 constants
- **Services:** Players, ReplicatedStorage, game
- **Key API:** Clone, Connect, Destroy, FindFirstChild, FireServer, GetAttribute, GetService, WaitForChild
- Constants: `UserId`, `GetHumanoidDescriptionFromUserId`, `pcall`, `task`, `wait`, `Humanoid`, `ApplyDescription`, `__isTeleporting`, `GetAttribute`, `AFK`, `FireServer`, `Rig`, `WaitForChild`, `Clone`, `ClientRig`, `Name`, `Parent`, `Destroy`, `defer`, `Head`, `FindFirstChild`, `ProximityPrompt`, `Triggered`, `Connect`, `game`, `ReplicatedStorage`, `GetService`, `Players`, `require`, `Packages`, `Observers`, `Net`, `LocalPlayer`, `script`, `InfoBillboard`, `PlaceTeleport`, `RemoteEvent`, `observeTagNoAncestry`

### [981] ReplicatedStorage.Observers.Lobby.Analytics.TrackImpressions
`ModuleScript` · bytecode v9 · 2322 bytes · 53 constants
- **Services:** Players, ReplicatedStorage, game, workspace
- **Key API:** Connect, Destroy, GetAttribute, GetService, IsA, new
- Constants: `CFrame`, `Position`, `Magnitude`, `MaximumViewDistance`, `isInRange`, `WorldToScreenPoint`, `isVisible`, `os`, `clock`, `ImpressionCooldown`, `MinimumExposureTime`, `TrackImpression`, `workspace`, `IsDescendantOf`, `Destroy`, `ImpressionType`, `GetAttribute`, `warn`, `TrackImpressions Observer is missing ImpressionType attribute on %*`, `GetFullName`, `format`, `Impressions`, `Type`, `Model`, `PVInstance`, `IsA`, `new`, `GetPivot`, `Every`, `Add`, `AncestryChanged`, `Connect`, `game`, `ReplicatedStorage`, `GetService`, `Players`, `require`, `Packages`, `Observers`, `Trove`, `Controllers`, `AnalyticsController`, `Shared`, `Analytics`, `ImpressionTrackingData`, `Common`, `Utils`, `Utilities`, `Thread`, `LocalPlayer`, `CurrentCamera`, `observeTagNoAncestry`, `TrackImpressions`

### [982] ReplicatedStorage.Observers.Lobby.Battlepass.BattlepassNPC
`ModuleScript` · bytecode v9 · 688 bytes · 14 constants
- **Key API:** Disconnect, SetAttribute
- Constants: `getTimestamps`, `EndTime`, `endTimestamp`, `SetAttribute`, `updateEndtimestamp`, `Disconnect`, `FFlag`, `OnChange`, `require`, `@game/ReplicatedStorage/Packages/Observers`, `@game/ReplicatedStorage/Common/Utils`, `@game/ReplicatedStorage/Shared/InfiniteBattlepass/InfiniteBattlepassData`, `observeTagNoAncestry`, `BattlepassNPC`

### [983] ReplicatedStorage.Observers.Lobby.BattlepassEvent.BattlepassEventEndTime
`ModuleScript` · bytecode v9 · 1110 bytes · 27 constants
- **Services:** ReplicatedStorage, game, workspace
- **Key API:** Connect, Disconnect, GetAttribute, GetService, SetAttribute
- Constants: `IsDataReady`, `GetFFlagKey`, `EndTime`, `GetKey`, `workspace`, `BattlepassEventEnabled`, `GetAttribute`, `SetAttribute`, `updateEndTime`, `Disconnect`, `DataUpdatedEvent`, `Connect`, `GetAttributeChangedSignal`, `task`, `spawn`, `game`, `ReplicatedStorage`, `GetService`, `require`, `ClientGameModules`, `FFlagClient`, `Shared`, `BattlepassEventData`, `Packages`, `Observers`, `observeTagNoAncestry`, `BattlepassEventEndTime`

### [984] ReplicatedStorage.Observers.Lobby.BossFightExpiresTime
`ModuleScript` · bytecode v9 · 1061 bytes · 30 constants
- **Services:** ReplicatedStorage, game, workspace
- **Key API:** Disconnect, GetService
- Constants: `FFlag`, `GetFFlag`, `%*BossEndTime`, `Name`, `format`, `ValueConvertor`, `workspace`, `GetServerTimeNow`, `math`, `max`, `FormatTimeWithDaysFull`, `Text`, `Enabled`, `Disconnect`, `BillboardGui`, `FindFirstAncestorWhichIsA`, `Thread`, `Every`, `game`, `ReplicatedStorage`, `GetService`, `require`, `Packages`, `Observers`, `Shared`, `BossPortalData`, `Common`, `Utils`, `observeTagNoAncestry`, `BossFightExpiresTime`

### [985] ReplicatedStorage.Observers.Lobby.CapsuleMachine
`ModuleScript` · bytecode v9 · 1843 bytes · 42 constants
- **Remotes:** Data
- **Services:** ReplicatedStorage, RunService, TweenService, game, workspace
- **Key API:** Connect, Destroy, Disconnect, GetService, WaitForChild
- Constants: `workspace`, `Spawn`, `WaitForChild`, `BackBoard`, `Destroy`, `task`, `spawn`, `destroyMachine`, `TotalStats.Wins`, `GetExpect`, `Parent`, `update`, `OnChange`, `GetPivot`, `CFrame`, `Angles`, `PivotTo`, `Disconnect`, `GetPolicyInfo`, `isLTMServer`, `ArePaidRandomItemsRestricted`, `Items`, `Client`, `Data`, `AwaitReplion`, `PostSimulation`, `Connect`, `game`, `ReplicatedStorage`, `GetService`, `TweenService`, `RunService`, `require`, `Packages`, `Observers`, `Replion`, `ServerInfo`, `Shared`, `UseNewLobby`, `Policy`, `observeTag`, `CapsuleMachine`

### [986] ReplicatedStorage.Observers.Lobby.CoinCrateOwnedAmount
`ModuleScript` · bytecode v9 · 1273 bytes · 35 constants
- **Remotes:** Data
- **Services:** Players, ReplicatedStorage, game
- **Key API:** GetService
- Constants: `Rewards`, `playerOwnsItem`, `Reward`, `Owned: %*/%*`, `format`, `Text`, `updateLabel`, `Client`, `Data`, `WaitReplion`, `ExplosionSkins.Unlocked`, `OnChange`, `SwordSkins.Unlocked`, `Emotes.Unlocked`, `SetupLabel`, `task`, `delay`, `game`, `ReplicatedStorage`, `GetService`, `Players`, `LocalPlayer`, `require`, `Packages`, `Replion`, `Observers`, `Shared`, `GenericCoinCrateData`, `Common`, `Utils`, `Utilities`, `RewardInfo`, `Inventory`, `observeTagNoAncestry`, `CoinCrateOwnedAmount`

### [987] ReplicatedStorage.Observers.Lobby.CommunityServerDisclaimer
`ModuleScript` · bytecode v9 · 896 bytes · 24 constants
- **Services:** Players, ReplicatedStorage, game
- **Key API:** GetAttribute, GetService
- Constants: `Text`, `CommunityServerAllowed`, `GetAttribute`, `CommunityServerBanned`, `GetPolicyInfo`, `USING_DEFAULT_POLICY`, `PolicyInfoAdded`, `Wait`, `table`, `find`, `AllowedExternalLinkReferences`, `Discord`, `game`, `PolicyService`, `GetService`, `ReplicatedStorage`, `Players`, `require`, `Shared`, `Policy`, `Packages`, `Observers`, `observeTagNoAncestry`, `CommunityServerDisclaimer`

### [988] ReplicatedStorage.Observers.Lobby.CrateOwnedCount
`ModuleScript` · bytecode v9 · 1795 bytes · 39 constants
- **Remotes:** Data
- **Services:** Players, ReplicatedStorage, game
- **Key API:** GetService
- Constants: `ItemType`, `Reward`, `Value`, `FindItems`, `OwnsCrateItem`, `RewardPool`, `Owned: %*/%*`, `format`, `Text`, `updateLabel`, `getCurrentLTM`, `getGameMode`, `Profiles`, `Client`, `Data`, `WaitReplion`, `ExplosionSkins.Unlocked`, `OnChange`, `SwordSkins.Unlocked`, `Emotes.Unlocked`, `OnModeChange`, `SetupLabel`, `task`, `delay`, `game`, `ReplicatedStorage`, `GetService`, `Players`, `LocalPlayer`, `require`, `Packages`, `Replion`, `Observers`, `Shared`, `LTM`, `LTMCrateData`, `Inventory`, `observeTagNoAncestry`, `CrateOwnedCount`

### [989] ReplicatedStorage.Observers.Lobby.DuoPass.DuoPassExpiresTime
`ModuleScript` · bytecode v9 · 981 bytes · 27 constants
- **Services:** ReplicatedStorage, game, workspace
- **Key API:** Disconnect, GetService
- Constants: `IsDataReady`, `GetFFlagKey`, `EndTime`, `GetKey`, `LOADING`, `ValueConvertor`, `workspace`, `GetServerTimeNow`, `FormatTimeWithDaysFull`, `Text`, `Disconnect`, `Thread`, `Every`, `game`, `ReplicatedStorage`, `GetService`, `require`, `ClientGameModules`, `FFlagClient`, `Shared`, `DuoPassData`, `Packages`, `Observers`, `Common`, `Utils`, `observeTagNoAncestry`, `DuoPassExpiresTime`

### [990] ReplicatedStorage.Observers.Lobby.DuoPass.DuoPassNPC
`ModuleScript` · bytecode v9 · 1200 bytes · 33 constants
- **Services:** ReplicatedStorage, game
- **Key API:** Connect, Disconnect, GetService, SetAttribute
- Constants: `IsDataReady`, `GetFFlagKey`, `EndTime`, `GetKey`, `IsEnabled`, `SetAttribute`, `updateEndTime`, `Disconnect`, `UIPromptNPC`, `HasTag`, `warn`, `DuoPassNPC tag should be used with UIPromptNPC! %*`, `GetFullName`, `format`, `EnabledSignal`, `Connect`, `task`, `spawn`, `game`, `ReplicatedStorage`, `GetService`, `require`, `ClientGameModules`, `FFlagClient`, `Controllers`, `UI`, `DuoPassController`, `Shared`, `DuoPassData`, `Packages`, `Observers`, `observeTagNoAncestry`, `DuoPassNPC`

### [991] ReplicatedStorage.Observers.Lobby.EasterEvent.AdminTimer
`ModuleScript` · bytecode v9 · 1203 bytes · 26 constants
- **Services:** ReplicatedStorage, game, workspace
- **Key API:** Disconnect, GetService
- Constants: `workspace`, `GetServerTimeNow`, `AdminEvent`, `StartTime`, `GetTimeElapsed`, `IterationTime`, `getCurrentIteration`, `ValueConvertor`, `FormatTimeWithDaysFull`, `Text`, `Disconnect`, `Thread`, `Every`, `game`, `ReplicatedStorage`, `GetService`, `require`, `Packages`, `Observers`, `Common`, `Utils`, `Shared`, `Easter`, `EasterEvent`, `observeTagNoAncestry`, `EasterAdminEventExpiresTime`

### [992] ReplicatedStorage.Observers.Lobby.EasterEvent.NPC
`ModuleScript` · bytecode v9 · 543 bytes · 14 constants
- **Services:** ReplicatedStorage, game
- **Key API:** GetService, SetAttribute
- Constants: `EndTime`, `SetAttribute`, `UnixTimestamp`, `game`, `ReplicatedStorage`, `GetService`, `require`, `Packages`, `Observers`, `Shared`, `Easter`, `EasterEvent`, `observeTagNoAncestry`, `EasterEventEndTime`

### [993] ReplicatedStorage.Observers.Lobby.EasterEvent.Stock
`ModuleScript` · bytecode v9 · 1036 bytes · 29 constants
- **Services:** ReplicatedStorage, game
- **Key API:** Connect, Disconnect, GetService, OnClientEvent
- Constants: `LimitedEgg2026`, `RemainingStock`, `Visible`, `%*/%* Left`, `ValueConvertor`, `AddCommas`, `Stock`, `ShrinkNumber`, `format`, `Text`, `Disconnect`, `OnClientEvent`, `Connect`, `game`, `ReplicatedStorage`, `GetService`, `require`, `Packages`, `Observers`, `Common`, `Utils`, `Shared`, `Easter`, `EasterEvent`, `Net`, `UGCStockUpdated`, `RemoteEvent`, `observeTagNoAncestry`, `EasterEventStock`

### [994] ReplicatedStorage.Observers.Lobby.EasterEvent.Timer
`ModuleScript` · bytecode v9 · 824 bytes · 23 constants
- **Services:** ReplicatedStorage, game, workspace
- **Key API:** Disconnect, GetService
- Constants: `ValueConvertor`, `EndTime`, `UnixTimestamp`, `workspace`, `GetServerTimeNow`, `FormatTimeWithDaysFull`, `Text`, `Disconnect`, `Thread`, `Every`, `game`, `ReplicatedStorage`, `GetService`, `require`, `Packages`, `Observers`, `Common`, `Utils`, `Shared`, `Easter`, `EasterEvent`, `observeTagNoAncestry`, `EasterEventExpiresTime`

### [995] ReplicatedStorage.Observers.Lobby.GachaSpinSetup.EasterSpinExpiresTime
`ModuleScript` · bytecode v9 · 718 bytes · 18 constants
- **Services:** ReplicatedStorage, game, workspace
- **Key API:** Disconnect, GetService
- Constants: `workspace`, `GetServerTimeNow`, `ValueConvertor`, `FormatTimeWithDaysFull`, `Text`, `Disconnect`, `Thread`, `Every`, `game`, `ReplicatedStorage`, `GetService`, `require`, `Packages`, `Observers`, `Common`, `Utils`, `observeTagNoAncestry`, `EasterSpinExpiresTime`

### [996] ReplicatedStorage.Observers.Lobby.GachaSpinSetup.GachaSpinExpiresTime
`ModuleScript` · bytecode v9 · 815 bytes · 22 constants
- **Services:** ReplicatedStorage, game, workspace
- **Key API:** Disconnect, GetAttribute, GetService
- Constants: `workspace`, `GetServerTimeNow`, `math`, `max`, `ValueConvertor`, `FormatTimeWithDaysFull`, `Text`, `Disconnect`, `EndTime`, `GetAttribute`, `Thread`, `Every`, `game`, `ReplicatedStorage`, `GetService`, `require`, `Packages`, `Observers`, `Common`, `Utils`, `observeTagNoAncestry`, `GachaSpinExpiresTime`

### [997] ReplicatedStorage.Observers.Lobby.GachaSpinSetup.HourlyWheelSpinEndTime
`ModuleScript` · bytecode v9 · 538 bytes · 14 constants
- **Services:** ReplicatedStorage, game
- **Key API:** GetService, SetAttribute
- Constants: `EndTime`, `SetAttribute`, `End`, `UnixTimestamp`, `game`, `ReplicatedStorage`, `GetService`, `require`, `Packages`, `Observers`, `Shared`, `HourlyWheelData`, `observeTagNoAncestry`, `HourlyWheelSpinEndTime`

### [998] ReplicatedStorage.Observers.Lobby.GachaSpinSetup.SummerSpinEndTime
`ModuleScript` · bytecode v9 · 533 bytes · 14 constants
- **Services:** ReplicatedStorage, game
- **Key API:** GetService, SetAttribute
- Constants: `EndTime`, `SetAttribute`, `End`, `UnixTimestamp`, `game`, `ReplicatedStorage`, `GetService`, `require`, `Packages`, `Observers`, `Shared`, `SummerWheelData`, `observeTagNoAncestry`, `SummerSpinEndTime`

### [999] ReplicatedStorage.Observers.Lobby.GachaSpinSetup.SynthSpinEndTime
`ModuleScript` · bytecode v9 · 531 bytes · 14 constants
- **Services:** ReplicatedStorage, game
- **Key API:** GetService, SetAttribute
- Constants: `EndTime`, `SetAttribute`, `End`, `UnixTimestamp`, `game`, `ReplicatedStorage`, `GetService`, `require`, `Packages`, `Observers`, `Shared`, `SynthWheelData`, `observeTagNoAncestry`, `SynthSpinEndTime`

### [1000] ReplicatedStorage.Observers.Lobby.GenericCoinCrateEndTime
`ModuleScript` · bytecode v9 · 475 bytes · 12 constants
- **Services:** ReplicatedStorage, game
- **Key API:** GetService, SetAttribute
- Constants: `EndTime`, `SetAttribute`, `game`, `ReplicatedStorage`, `GetService`, `require`, `Packages`, `Observers`, `Shared`, `GenericCoinCrateData`, `observeTagNoAncestry`, `GenericCoinCrateEndTime`

### [1001] ReplicatedStorage.Observers.Lobby.GenericCrateContents
`ModuleScript` · bytecode v9 · 1115 bytes · 33 constants
- **Services:** Players, ReplicatedStorage, game
- **Key API:** FindFirstChild, GetService
- Constants: `Chance`, `Rates`, `Content`, `FindFirstChild`, `Title`, `Reward`, `DisplayName`, `Text`, `Percent`, `%*%%`, `format`, `Icon`, `Image`, `game`, `ReplicatedStorage`, `GetService`, `require`, `Common`, `Utils`, `Packages`, `Observers`, `Shared`, `GenericCrateData`, `Players`, `LocalPlayer`, `PlayerGui`, `Rewards`, `table`, `insert`, `sort`, `observeTag`, `GenericCrateContents`

### [1002] ReplicatedStorage.Observers.Lobby.GenericCrateEndTime
`ModuleScript` · bytecode v9 · 467 bytes · 12 constants
- **Services:** ReplicatedStorage, game
- **Key API:** GetService, SetAttribute
- Constants: `EndTime`, `SetAttribute`, `game`, `ReplicatedStorage`, `GetService`, `require`, `Packages`, `Observers`, `Shared`, `GenericCrateData`, `observeTagNoAncestry`, `GenericCrateEndTime`

### [1003] ReplicatedStorage.Observers.Lobby.GenericCrateOwnedAmount
`ModuleScript` · bytecode v9 · 1272 bytes · 35 constants
- **Remotes:** Data
- **Services:** Players, ReplicatedStorage, game
- **Key API:** GetService
- Constants: `Rewards`, `playerOwnsItem`, `Reward`, `Owned: %*/%*`, `format`, `Text`, `updateLabel`, `Client`, `Data`, `WaitReplion`, `ExplosionSkins.Unlocked`, `OnChange`, `SwordSkins.Unlocked`, `Emotes.Unlocked`, `SetupLabel`, `task`, `delay`, `game`, `ReplicatedStorage`, `GetService`, `Players`, `LocalPlayer`, `require`, `Packages`, `Replion`, `Observers`, `Shared`, `GenericCrateData`, `Common`, `Utils`, `Utilities`, `RewardInfo`, `Inventory`, `observeTagNoAncestry`, `GenericCrateOwnedAmount`

### [1004] ReplicatedStorage.Observers.Lobby.GenericGacha.NPC
`ModuleScript` · bytecode v9 · 1116 bytes · 28 constants
- **Services:** ReplicatedStorage, game, workspace
- **Key API:** Disconnect, GetService, SetAttribute
- Constants: `GetFFlag`, `UpdateTime-9/27/25`, `workspace`, `GetServerTimeNow`, `EventEndTimeStamp`, `UnixTimestamp`, `Disconnect`, `EndTime`, `SetAttribute`, `Connected`, `Every`, `game`, `ReplicatedStorage`, `GetService`, `require`, `Packages`, `Observers`, `Common`, `Utils`, `FFlag`, `Thread`, `Shared`, `LootboxData`, `GachaEvents`, `ActiveGacha`, `Name`, `observeTagNoAncestry`, `GenericGachaNPC`

### [1005] ReplicatedStorage.Observers.Lobby.GenericGacha.Timer
`ModuleScript` · bytecode v9 · 886 bytes · 25 constants
- **Services:** ReplicatedStorage, game, workspace
- **Key API:** Disconnect, GetService
- Constants: `ValueConvertor`, `EventEndTimeStamp`, `UnixTimestamp`, `workspace`, `GetServerTimeNow`, `FormatTimeWithDaysFull`, `Text`, `Disconnect`, `Thread`, `Every`, `game`, `ReplicatedStorage`, `GetService`, `require`, `Packages`, `Observers`, `Common`, `Utils`, `Shared`, `LootboxData`, `GachaEvents`, `ActiveGacha`, `Name`, `observeTagNoAncestry`, `GenericGachaExpiresTime`

### [1006] ReplicatedStorage.Observers.Lobby.GenericGachaLuck.Billboard
`ModuleScript` · bytecode v9 · 1562 bytes · 37 constants
- **Services:** ReplicatedStorage, game, workspace
- **Key API:** Disconnect, GetService
- Constants: `Enabled`, `workspace`, `GetServerTimeNow`, `GachaEvents`, `IceDragonGacha`, `EventEndTimeStamp`, `UnixTimestamp`, `IsDataReady`, `%*LuckEndTime`, `Identifier`, `format`, `GetKey`, `%*LuckStartTime`, `Disconnect`, `pcall`, `warn`, `Tag "GenericGachaLuckEnabled" was used in a object that doesn't has a .Enabled property: %*`, `GetFullName`, `Thread`, `Every`, `game`, `ReplicatedStorage`, `GetService`, `require`, `Common`, `Utils`, `Packages`, `Observers`, `Shared`, `LootboxData`, `ClientGameModules`, `FFlagClient`, `Controllers`, `UI`, `GenericGachaController`, `observeTag`, `GenericGachaLuckEnabled`

### [1007] ReplicatedStorage.Observers.Lobby.GenericGachaLuck.Timer
`ModuleScript` · bytecode v9 · 1035 bytes · 28 constants
- **Services:** ReplicatedStorage, game, workspace
- **Key API:** Disconnect, GetService
- Constants: `ValueConvertor`, `IsDataReady`, `%*LuckEndTime`, `Identifier`, `format`, `GetKey`, `workspace`, `GetServerTimeNow`, `FormatTimeHHMMSS`, `Text`, `Disconnect`, `Thread`, `Every`, `game`, `ReplicatedStorage`, `GetService`, `require`, `Common`, `Utils`, `Packages`, `Observers`, `ClientGameModules`, `FFlagClient`, `Controllers`, `UI`, `GenericGachaController`, `observeTag`, `GenericGachaLuckTimer`

### [1008] ReplicatedStorage.Observers.Lobby.GiveSwordNPC
`ModuleScript` · bytecode v9 · 2135 bytes · 49 constants
- **Services:** ReplicatedStorage, game, workspace
- **Key API:** Connect, Destroy, GetAttribute, GetService, LoadAnimation, Play, Stop, WaitForChild, new
- Constants: `Humanoid`, `WaitForChild`, `Animator`, `LoadAnimation`, `Add`, `loadAnimation`, `GetSword`, `Idle`, `AnimationType`, `SwordType`, `GetAnimations`, `Play`, `table`, `insert`, `ScaleSword`, `GetAttribute`, `EquipSwordTo`, `EquippedSword`, `Name`, `createSword`, `IsPlaying`, `Stop`, `Destroy`, `clear`, `cleanAnimations`, `Clean`, `Sword`, `LobbySwordName`, `updateSword`, `workspace`, `Spawn`, `new`, `GetAttributeChangedSignal`, `Connect`, `game`, `ReplicatedStorage`, `GetService`, `require`, `Packages`, `Observers`, `Shared`, `ReplicatedInstances`, `Swords`, `SwordAPI`, `Common`, `Utils`, `Trove`, `observeTag`, `GiveSwordNPC`

### [1009] ReplicatedStorage.Observers.Lobby.HalloweenGachaLuck.Billboard
`ModuleScript` · bytecode v9 · 1521 bytes · 34 constants
- **Services:** ReplicatedStorage, game, workspace
- **Key API:** Disconnect, GetService
- Constants: `Enabled`, `workspace`, `GetServerTimeNow`, `IsDataReady`, `HalloweenGachaLuckEndTime`, `GetKey`, `HasLuck`, `GetRemaining`, `math`, `max`, `isEnabled`, `Disconnect`, `pcall`, `warn`, `Tag "HalloweenGachaLuckEnabled" was used in a object that doesn't has a .Enabled property: %*`, `GetFullName`, `format`, `Thread`, `Every`, `game`, `ReplicatedStorage`, `GetService`, `require`, `Common`, `Utils`, `Packages`, `Observers`, `ClientGameModules`, `FFlagClient`, `Controllers`, `StPatricksDayEventController`, `@game/ReplicatedStorage/Shared/InfiniteBattlepass/InfiniteBattlepassData`, `observeTag`, `HalloweenGachaLuckEnabled`

### [1010] ReplicatedStorage.Observers.Lobby.HalloweenGachaLuck.Timer
`ModuleScript` · bytecode v9 · 1130 bytes · 29 constants
- **Services:** ReplicatedStorage, game, workspace
- **Key API:** Disconnect, GetService
- Constants: `IsDataReady`, `HalloweenGachaLuckEndTime`, `GetKey`, `workspace`, `GetServerTimeNow`, `HasLuck`, `GetRemaining`, `math`, `max`, `ValueConvertor`, `FormatTimeHHMMSS`, `Text`, `Disconnect`, `Thread`, `Every`, `game`, `ReplicatedStorage`, `GetService`, `require`, `Common`, `Utils`, `Packages`, `Observers`, `ClientGameModules`, `FFlagClient`, `Controllers`, `StPatricksDayEventController`, `observeTag`, `HalloweenGachaLuckTimer`

### [1011] ReplicatedStorage.Observers.Lobby.HourlyWheelSpinRewardIn
`ModuleScript` · bytecode v9 · 625 bytes · 16 constants
- **Services:** ReplicatedStorage, game
- **Key API:** Connect, Disconnect, GetService
- Constants: `Text`, `Disconnect`, `RewardTextChanged`, `Connect`, `game`, `ReplicatedStorage`, `GetService`, `require`, `Packages`, `Observers`, `Common`, `Utils`, `Controllers`, `HourlyWheelController`, `observeTagNoAncestry`, `HourlyWheelSpinRewardIn`

### [1012] ReplicatedStorage.Observers.Lobby.InfinityTrial
`ModuleScript` · bytecode v9 · 1041 bytes · 27 constants
- **Remotes:** Infinity
- **Services:** ReplicatedStorage, game
- **Key API:** Destroy, GetAttribute, GetService, SetAttribute
- Constants: `TradeLock`, `Type`, `Trial`, `Ability`, `Infinity`, `FindItems`, `EndTime`, `SetAttribute`, `updateOwned`, `Destroy`, `Client`, `Inventory`, `WaitReplion`, `GetAttribute`, `OnChange`, `task`, `spawn`, `game`, `ReplicatedStorage`, `GetService`, `require`, `Shared`, `Packages`, `Replion`, `Observers`, `observeTagNoAncestry`, `InfinityTrial`

### [1013] ReplicatedStorage.Observers.Lobby.LoadPlayerCharacter
`ModuleScript` · bytecode v9 · 1818 bytes · 41 constants
- **Services:** Players, ReplicatedStorage, game
- **Key API:** Clone, Destroy, GetService, WaitForChild
- Constants: `pcall`, `GetHumanoidDescriptionFromUserId`, `UserId`, `task`, `wait`, `math`, `min`, `spawn`, `table`, `clear`, `coroutine`, `running`, `insert`, `yield`, `getLocalDescription`, `Humanoid`, `ApplyDescription`, `Parent`, `warn`, `[LoadPlayerCharacter] ApplyDescription falhou:`, `xpcall`, `NPCStudio`, `WaitForChild`, `Clone`, `NPC`, `Name`, `Destroy`, `defer`, `game`, `ReplicatedStorage`, `GetService`, `Players`, `LocalPlayer`, `require`, `Shared`, `LobbyLimitedSwords`, `NPCLobbyAnimation`, `Packages`, `Observers`, `observeTagNoAncestry`, `LoadPlayerCharacter`

### [1014] ReplicatedStorage.Observers.Lobby.LobbyTraining.MovingTarget
`ModuleScript` · bytecode v9 · 1096 bytes · 26 constants
- **Services:** Players, ReplicatedStorage, RunService, game, workspace
- **Key API:** Connect, Disconnect, GetService
- Constants: `math`, `cos`, `easeInOutSine`, `Character`, `Parent`, `workspace`, `Dead`, `PivotTo`, `Disconnect`, `pcall`, `PostSimulation`, `Connect`, `game`, `ReplicatedStorage`, `GetService`, `RunService`, `Players`, `LocalPlayer`, `require`, `Packages`, `Observers`, `Shared`, `LobbyTraining`, `MovingTargets`, `observeTag`, `LobbyTrainingMovingTarget`

### [1015] ReplicatedStorage.Observers.Lobby.LobbyTraining.SFX
`ModuleScript` · bytecode v9 · 1058 bytes · 26 constants
- **Services:** Players, ReplicatedStorage, game, workspace
- **Key API:** Connect, GetAttribute, GetService
- Constants: `LobbyTraining`, `GetAttribute`, `Character`, `Parent`, `workspace`, `Dead`, `Volume`, `updateVolume`, `table`, `find`, `remove`, `insert`, `task`, `spawn`, `game`, `ReplicatedStorage`, `GetService`, `Players`, `LocalPlayer`, `require`, `Packages`, `Observers`, `GetAttributeChangedSignal`, `Connect`, `observeTag`, `LobbyTrainingSFX`

### [1016] ReplicatedStorage.Observers.Lobby.LobbyTraining.Target
`ModuleScript` · bytecode v9 · 4991 bytes · 81 constants
- **Services:** ReplicatedStorage, RunService, TweenService, game, workspace
- **Key API:** Clone, Connect, Create, Destroy, Disconnect, FindFirstChild, GetAttribute, GetChildren, GetDescendants, GetService, IsA, Play, SetAttribute, new
- Constants: `Physics`, `CreateMotor`, `CFrame`, `ToObjectSpace`, `C0`, `Anchored`, `weld`, `Clone`, `GetPivot`, `PivotTo`, `Model`, `IsA`, `Size`, `X`, `ScaleTo`, `BasePart`, `GetDescendants`, `clone`, `Random`, `new`, `NextUnitVector`, `ApplyImpulse`, `TweenInfo`, `Enum`, `EasingStyle`, `Sine`, `EasingDirection`, `Out`, `Transparency`, `Create`, `Play`, `Enabled`, `task`, `defer`, `delay`, `AssemblyAngularVelocity`, `Position`, `Unit`, `Health`, `GetAttribute`, `MaxHealth`, `wait`, `Highlight`, `FindFirstChildWhichIsA`, `Parent`, `GetChildren`, `DefaultCFrame`, `SetAttribute`, `Motor6D`, `CanCollide`, `workspace`, `Runtime`, `updateHealth`, `updateHighlight`, `Disconnect`, `Destroy`, `Stand`, `FindFirstChild`, `Broken`, `Normal`, `High`, `Mid`, `Sound`, `GetAttributeChangedSignal`, `Connect`, `spawn`, `ChildAdded`, `game`, `ReplicatedStorage`, `GetService`, `TweenService`, `RunService`, `require`, `Packages`, `Observers`, `Common`, `Utils`, `Misc`, `Targets`, `observeTag`, `LobbyTrainingClientTarget`

### [1017] ReplicatedStorage.Observers.Lobby.MerchantNPC
`ModuleScript` · bytecode v9 · 2027 bytes · 54 constants
- **Services:** ReplicatedStorage, game, workspace
- **Key API:** Destroy, Disconnect, GetService, SetAttribute
- Constants: `EndTime`, `SetAttribute`, `Items`, `Get`, `ItemID`, `Reward`, `Type`, `Sword`, `Value`, `DefaultNPCSword`, `LobbySwordName`, `GiveSwordNPC`, `AddTag`, `ArrivalTime`, `Duration`, `workspace`, `GetServerTimeNow`, `ValueConvertor`, `FormatTimeHHMMSS`, `Text`, `Disconnect`, `FeaturesToggle`, `Merchant`, `task`, `defer`, `Destroy`, `Client`, `MerchantShop`, `WaitReplion`, `HumanoidRootPart`, `BillboardGui`, `Timer`, `Time`, `isTutorialServer`, `isNewPlayerLobbyServer`, `observeReplionPath`, `Active`, `Thread`, `Every`, `game`, `ReplicatedStorage`, `GetService`, `require`, `Packages`, `Observers`, `Shared`, `MerchantShopData`, `Replion`, `ServerInfo`, `ReplionUtils`, `Common`, `Utils`, `observeTagNoAncestry`, `MerchantNPC`

### [1018] ReplicatedStorage.Observers.Lobby.ModelOffsets
`ModuleScript` · bytecode v9 · 466 bytes · 14 constants
- **Services:** ReplicatedStorage, game
- **Key API:** GetAttribute, GetService, IsA
- Constants: `Model`, `IsA`, `Offset`, `GetAttribute`, `GetPivot`, `PivotTo`, `game`, `ReplicatedStorage`, `GetService`, `require`, `Packages`, `Observers`, `observeTagNoAncestry`, `ModelOffset`

### [1019] ReplicatedStorage.Observers.Lobby.ModelVisibility
`ModuleScript` · bytecode v9 · 5316 bytes · 90 constants
- **Remotes:** Data
- **Services:** Players, ReplicatedStorage, RunService, game, workspace
- **Key API:** Connect, Destroy, GetAttribute, GetService, new
- Constants: `Time`, `GetAttribute`, `Wins`, `Kills`, `TournamentTickets`, `StartTime`, `EndTime`, `table`, `clear`, `string`, `split`, `;`, `updateAttributes`, `NeedPlayerAttribute`, `TotalStats.Wins`, `Get`, `TotalStats.Kills`, `TimePlayed`, `workspace`, `GetServerTimeNow`, `JoinedTimestamp`, `tonumber`, `Parent`, `updateParent`, `Destroy`, `IsClient`, `GetPolicyInfo`, `PolicyInfoAdded`, `Wait`, `HasPaidRandomItems`, `HasTag`, `ArePaidRandomItemsRestricted`, `ShowInLTM`, `isMedalServer`, `isLTMServer`, `HideInElemental`, `isElementalServer`, `HideInLTM`, `HideInTutorial`, `isTutorialServer`, `HideInNewPlayerLobby`, `isNewPlayerLobbyServer`, `isNewPlayerLobbyTestServer`, `HideInRanked`, `isRankedMatchServer`, `HideInTest`, `isTestGame`, `HideInDuelMatch`, `isDuelMatchServer`, `HideInTournamentEvent`, `isTournamentEventServer`, `HideInMedal`, `HideInBossFight`, `isBossFightServer`, `HideInRegionalTournament`, `isRegionalTournamentMatch`, `HideInRBBattles`, `isRBBattlesServer`, `HideModel`, `HideInTradingPlaza`, `isTradingPlazaServer`, `HideInDuelLobby`, `isDuelLobbyServer`, `Client`, `Data`, `WaitReplion`, `new`, `GetAttributeChangedSignal`, `Connect`, `Add`, `Thread`, `Every`, `game`, `ReplicatedStorage`, `GetService`, `Players`, `RunService`, `require`, `Packages`, `Observers`, `Replion`, `Trove`, `Common`, `Utils`, `ServerInfo`, `Shared`, `Policy`, `LocalPlayer`, `observeTagNoAncestry`, `ModelVisibility`

### [1020] ReplicatedStorage.Observers.Lobby.PlayAnimationNPC
`ModuleScript` · bytecode v9 · 2398 bytes · 55 constants
- **Services:** Players, ReplicatedStorage, game, workspace
- **Key API:** Connect, Destroy, Fire, GetAttribute, GetChildren, GetService, IsA, LoadAnimation, Once, Play, WaitForChild, new
- Constants: `Animation`, `IsA`, `LoadAnimation`, `Looped`, `GetAttribute`, `table`, `insert`, `loadAnimation`, `Fire`, `TimePosition`, `UsingEmotes`, `WaitForChild`, `AnimationController`, `FindFirstChildWhichIsA`, `Humanoid`, `Animator`, `SetStateEnabled`, `GetChildren`, `new`, `ChildAdded`, `Once`, `Wait`, `Destroy`, `Pin`, `GetMarkerReachedSignal`, `Connect`, `GOTO`, `Play`, `usingEmotes`, `task`, `spawn`, `game`, `ReplicatedStorage`, `GetService`, `Players`, `require`, `Packages`, `Observers`, `Signal`, `Enum`, `HumanoidStateType`, `FallingDown`, `Ragdoll`, `GettingUp`, `Jumping`, `Swimming`, `Freefall`, `Flying`, `Running`, `Climbing`, `Physics`, `LocalPlayer`, `observeTag`, `PlayAnimationNPC`, `workspace`

### [1021] ReplicatedStorage.Observers.Lobby.PlayerSlashColor
`ModuleScript` · bytecode v9 · 2393 bytes · 48 constants
- **Services:** Players, ReplicatedStorage, game, workspace
- **Key API:** Connect, Disconnect, GetAttribute, GetDescendants, GetService, IsA, SetAttribute, new
- Constants: `Original%*`, `format`, `GetAttribute`, `pcall`, `SetAttribute`, `error`, `Unable to fetch value of %*!`, `getOriginalValue`, `Brightness`, `LightInfluence`, `ColorSequence`, `new`, `Color`, `ParticleEmitter`, `Beam`, `TesterSword`, `HasTag`, `IsA`, `ClassName`, `registerDescendant`, `SlashColor`, `ToHex`, `ipairs`, `GetDescendants`, `recolorSword`, `Disconnect`, `Parent`, `GetPlayerFromCharacter`, `task`, `defer`, `AncestryChanged`, `Connect`, `ChildAdded`, `DescendantAdded`, `GetAttributeChangedSignal`, `game`, `ReplicatedStorage`, `GetService`, `Players`, `require`, `Packages`, `Observers`, `Color3`, `BasePart`, `Light`, `observeTag`, `PlayerSlashColor`, `workspace`

### [1022] ReplicatedStorage.Observers.Lobby.ProTradePlazaPortal
`ModuleScript` · bytecode v9 · 2760 bytes · 66 constants
- **Services:** Players, ReplicatedStorage, game
- **Key API:** Connect, Destroy, FireServer, GetService, WaitForChild, new
- Constants: `Enabled`, `task`, `delay`, `ProTradingPlaza`, `Accessible`, `You need %* RAP to join the Pro Trade Plaza!`, `ValueConvertor`, `ShrinkNumber`, `format`, `SendNotification`, `FireServer`, `Frame`, `LockedOverlay`, `Visible`, `LockIcon`, `Requirement`, `%* RAP REQUIRED`, `Text`, `Pro Trade Plaza`, `Normal Trade Plaza`, `Title`, `ObjectText`, `updateLock`, `Prompt`, `WaitForChild`, `ProximityPrompt`, `Triggered`, `Connect`, `Add`, `Center`, `ProTradePlaza`, `TotalRAP`, `GetAttributeChangedSignal`, `Client`, `Inventory`, `WaitReplion`, `Tokens`, `OnChange`, `Destroy`, `new`, `spawn`, `game`, `ReplicatedStorage`, `GetService`, `Players`, `require`, `Packages`, `Observers`, `Net`, `Shared`, `UniverseIds`, `ServerInfo`, `Common`, `Utils`, `Replion`, `Trove`, `Controllers`, `NotificationController`, `@game/ReplicatedStorage/Types/Templates/Lobbies`, `LocalPlayer`, `PlaceTeleport`, `RemoteEvent`, `isProTradingPlazaServer`, `TradingPlaza`, `observeTagNoAncestry`, `ProTradePlazaPortal`

### [1023] ReplicatedStorage.Observers.Lobby.SantaMarketEndTime
`ModuleScript` · bytecode v9 · 610 bytes · 16 constants
- **Services:** ReplicatedStorage, game
- **Key API:** GetService, SetAttribute
- Constants: `EndTime`, `SetAttribute`, `EndTimestamp`, `game`, `ReplicatedStorage`, `GetService`, `require`, `ClientGameModules`, `FFlagClient`, `Shared`, `SantaMarket`, `SantaMarketData`, `Packages`, `Observers`, `observeTagNoAncestry`, `SantaMarketEndTime`

### [1024] ReplicatedStorage.Observers.Lobby.SealCrateLuck.Billboard
`ModuleScript` · bytecode v9 · 1226 bytes · 28 constants
- **Services:** ReplicatedStorage, game, workspace
- **Key API:** Disconnect, GetService
- Constants: `Enabled`, `workspace`, `GetServerTimeNow`, `FFlag`, `GetInstantFFlag`, `SealCrateLuckStartTime`, `SealCrateLuckEndTime`, `HasLuck`, `Disconnect`, `pcall`, `warn`, `Tag "SealCrateLuckEnabled" was used in a object that doesn't has a .Enabled property: %*`, `GetFullName`, `format`, `Thread`, `Every`, `game`, `ReplicatedStorage`, `GetService`, `require`, `Common`, `Utils`, `Packages`, `Observers`, `Controllers`, `StPatricksDayEventController`, `observeTag`, `SealCrateLuckEnabled`

### [1025] ReplicatedStorage.Observers.Lobby.SealCrateLuck.Timer
`ModuleScript` · bytecode v9 · 1005 bytes · 27 constants
- **Services:** ReplicatedStorage, game, workspace
- **Key API:** Disconnect, GetService
- Constants: `FFlag`, `GetInstantFFlag`, `SealCrateLuckEndTime`, `ValueConvertor`, `workspace`, `GetServerTimeNow`, `HasLuck`, `GetRemaining`, `math`, `max`, `FormatTimeHHMMSS`, `Text`, `Disconnect`, `Thread`, `Every`, `game`, `ReplicatedStorage`, `GetService`, `require`, `Common`, `Utils`, `Packages`, `Observers`, `Controllers`, `StPatricksDayEventController`, `observeTag`, `SealCrateLuckTimer`

### [1026] ReplicatedStorage.Observers.Lobby.ShowOnPolicyDisabled
`ModuleScript` · bytecode v9 · 926 bytes · 23 constants
- **Services:** Players, ReplicatedStorage, game
- **Key API:** GetAttribute, GetService
- Constants: `LocalPlayer`, `GetPolicyInfoForPlayerAsync`, `pcall`, `Visible`, `ArePaidRandomItemsRestricted`, `PolicyType`, `GetAttribute`, `warn`, `Invalid PolicyType "%*" on %*`, `GetFullName`, `format`, `game`, `ReplicatedStorage`, `GetService`, `Players`, `require`, `Packages`, `Observers`, `Common`, `Utils`, `PolicyService`, `observeTagNoAncestry`, `ShowOnPolicyDisabled`

### [1027] ReplicatedStorage.Observers.Lobby.SinglePass.SinglePassEndTime
`ModuleScript` · bytecode v9 · 1127 bytes · 28 constants
- **Services:** ReplicatedStorage, game, workspace
- **Key API:** Connect, GetService, SetAttribute
- Constants: `EndTime`, `SetAttribute`, `updateEndTime`, `Get`, `ipairs`, `updateFlags`, `table`, `find`, `remove`, `insert`, `game`, `ReplicatedStorage`, `GetService`, `require`, `Packages`, `Observers`, `ClientGameModules`, `FFlagClient`, `Shared`, `SinglePass`, `SinglePassFFlags`, `DataUpdatedEvent`, `Connect`, `task`, `spawn`, `observeTag`, `SinglePassEndTime`, `workspace`

### [1028] ReplicatedStorage.Observers.Lobby.SinglePassBountyDisplay
`ModuleScript` · bytecode v9 · 1828 bytes · 42 constants
- **Remotes:** Data
- **Services:** Players, ReplicatedStorage, game
- **Key API:** GetService, WaitForChild
- Constants: `Username`, `NO TARGET`, `Text`, `Headshot`, `Color3`, `fromRGB`, `ImageColor3`, `rbxassetid://18444806692`, `Image`, `resetBountyVisual`, `GetPlayerByUserId`, `print`, `(bounty client) Failed to find player with userId:`, `%* (@%*)`, `DisplayName`, `Name`, `format`, `rbxthumb://type=AvatarHeadShot&id=%*&w=150&h=150`, `Enabled`, `onBountyUserIdChanged`, `Client`, `Data`, `WaitReplion`, `SinglePass.Bounty`, `OnChange`, `GetExpect`, `Profile`, `WaitForChild`, `ProfilePicture`, `Content`, `task`, `spawn`, `game`, `ReplicatedStorage`, `GetService`, `Players`, `require`, `Packages`, `Replion`, `Observers`, `observeTagNoAncestry`, `SinglePassBountyDisplay`

### [1029] ReplicatedStorage.Observers.Lobby.SpecialTrainingEndTime
`ModuleScript` · bytecode v9 · 941 bytes · 26 constants
- **Services:** ReplicatedStorage, game, workspace
- **Key API:** Disconnect, GetService, IsA, SetAttribute
- Constants: `ValueConvertor`, `EndTimestamp`, `workspace`, `GetServerTimeNow`, `FormatTimeWithDaysFull`, `Text`, `Disconnect`, `Model`, `IsA`, `EndTime`, `SetAttribute`, `Thread`, `Every`, `game`, `ReplicatedStorage`, `GetService`, `require`, `Packages`, `Observers`, `Common`, `Utils`, `Shared`, `SpecialTrainingEvent`, `SpecialTrainingEventData`, `observeTagNoAncestry`, `SpecialTrainingEndTime`

### [1030] ReplicatedStorage.Observers.Lobby.StPatricksDayEventVisibility
`ModuleScript` · bytecode v9 · 948 bytes · 22 constants
- **Services:** ReplicatedStorage, game
- **Key API:** Connect, Disconnect, GetService, SetAttribute
- Constants: `EndTime`, `GetEndTime`, `SetAttribute`, `Disconnect`, `GetRemaining`, `IsActive`, `DataUpdatedEvent`, `Connect`, `game`, `ReplicatedStorage`, `GetService`, `require`, `Packages`, `Observers`, `Common`, `Utils`, `Controllers`, `StPatricksDayEventController`, `ClientGameModules`, `FFlagClient`, `observeTagNoAncestry`, `StPatricksDayEventVisibility`

### [1031] ReplicatedStorage.Observers.Lobby.TextEndTime
`ModuleScript` · bytecode v9 · 1028 bytes · 25 constants
- **Services:** ReplicatedStorage, game, workspace
- **Key API:** Disconnect, GetAttribute, GetService
- Constants: `EndTime`, `GetAttribute`, `workspace`, `GetServerTimeNow`, `math`, `max`, `FormatTimeWithMS`, `Text`, `FormatTimeWithDaysFull`, `Disconnect`, `Miliseconds`, `Every`, `game`, `ReplicatedStorage`, `GetService`, `require`, `Packages`, `Observers`, `Common`, `Utils`, `Utilities`, `Thread`, `ValueConvertor`, `observeTagNoAncestry`, `TextEndTime`

### [1032] ReplicatedStorage.Observers.Lobby.TextStartsTime
`ModuleScript` · bytecode v9 · 863 bytes · 23 constants
- **Services:** ReplicatedStorage, game, workspace
- **Key API:** Disconnect, GetAttribute, GetService
- Constants: `StartTime`, `GetAttribute`, `workspace`, `GetServerTimeNow`, `math`, `max`, `FormatTimeWithDaysFull`, `Text`, `Disconnect`, `Every`, `game`, `ReplicatedStorage`, `GetService`, `require`, `Packages`, `Observers`, `Common`, `Utils`, `Utilities`, `Thread`, `ValueConvertor`, `observeTagNoAncestry`, `TextStartTime`

### [1033] ReplicatedStorage.Observers.Lobby.TheHunt.Timer
`ModuleScript` · bytecode v9 · 861 bytes · 24 constants
- **Services:** ReplicatedStorage, game, workspace
- **Key API:** Disconnect, GetService
- Constants: `ValueConvertor`, `workspace`, `GetServerTimeNow`, `FormatTimeWithDays`, `ENDS IN: %*`, `upper`, `format`, `Text`, `Disconnect`, `Thread`, `Every`, `game`, `ReplicatedStorage`, `GetService`, `require`, `Packages`, `Observers`, `Common`, `Utils`, `DateTime`, `fromUniversalTime`, `UnixTimestamp`, `observeTagNoAncestry`, `TheHuntQuestExpiresTime`

### [1034] ReplicatedStorage.Observers.Lobby.TimeModelVisibilityAB
`ModuleScript` · bytecode v9 · 597 bytes · 16 constants
- **Services:** ReplicatedStorage, game
- **Key API:** GetService
- Constants: `isTestGame`, `game`, `ReplicatedStorage`, `GetService`, `require`, `Packages`, `Observers`, `ServerInfo`, `Controllers`, `AnalyticsController`, `GachaNPC`, `IceDragonGacha`, `FireDragonGacha`, `ChromaGacha`, `observeTagNoAncestry`, `TimeModelVisibilityAB`

### [1035] ReplicatedStorage.Observers.Lobby.TournamentCrate.Balance
`ModuleScript` · bytecode v9 · 666 bytes · 17 constants
- **Services:** ReplicatedStorage, game
- **Key API:** Connect, Disconnect, GetService
- Constants: `Text`, `Disconnect`, `BalanceText`, `BalanceTextChanged`, `Connect`, `game`, `ReplicatedStorage`, `GetService`, `require`, `Packages`, `Observers`, `Common`, `Utils`, `Controllers`, `TournamentCrateController`, `observeTagNoAncestry`, `TournamentCrateNPC`

### [1036] ReplicatedStorage.Observers.Lobby.TournamentCrate.Timer
`ModuleScript` · bytecode v9 · 810 bytes · 22 constants
- **Services:** ReplicatedStorage, game, workspace
- **Key API:** Disconnect, GetService
- Constants: `ValueConvertor`, `TimeLength`, `UnixTimestamp`, `workspace`, `GetServerTimeNow`, `FormatTimeWithDays`, `Text`, `Disconnect`, `Thread`, `Every`, `game`, `ReplicatedStorage`, `GetService`, `require`, `Packages`, `Observers`, `Common`, `Utils`, `Shared`, `TournamentCrateData`, `observeTagNoAncestry`, `TournamentCrateTimer`

### [1037] ReplicatedStorage.Observers.Lobby.TournamentEventEndTime
`ModuleScript` · bytecode v9 · 1417 bytes · 32 constants
- **Services:** ReplicatedStorage, game, workspace
- **Key API:** Disconnect, GetAttribute, GetService, IsA, SetAttribute
- Constants: `FFlag`, `GetFFlag`, `UpdateTime-9/27/25`, `workspace`, `GetServerTimeNow`, `Disconnect`, `EndTime`, `SetAttribute`, `math`, `max`, `ValueConvertor`, `FormatTimeWithDaysFull`, `Text`, `GetAttribute`, `UnixTimestamp`, `Thread`, `Every`, `TextLabel`, `IsA`, `game`, `ReplicatedStorage`, `GetService`, `require`, `Packages`, `Observers`, `Common`, `Utils`, `Shared`, `TournamentEvent`, `TournamentEventData`, `observeTagNoAncestry`, `TournamentEventEndTime`

### [1038] ReplicatedStorage.Observers.Lobby.TournamentEventLuck.Billboard
`ModuleScript` · bytecode v9 · 1250 bytes · 28 constants
- **Services:** ReplicatedStorage, game, workspace
- **Key API:** Disconnect, GetService
- Constants: `Enabled`, `workspace`, `GetServerTimeNow`, `FFlag`, `GetInstantFFlag`, `TournamentEventLuckStartTime`, `TournamentEventLuckEndTime`, `HasLuck`, `Disconnect`, `pcall`, `warn`, `Tag "TournamentEventLuckEnabled" was used in a object that doesn't has a .Enabled property: %*`, `GetFullName`, `format`, `Thread`, `Every`, `game`, `ReplicatedStorage`, `GetService`, `require`, `Common`, `Utils`, `Packages`, `Observers`, `Controllers`, `StPatricksDayEventController`, `observeTag`, `TournamentEventLuckEnabled`

### [1039] ReplicatedStorage.Observers.Lobby.TournamentEventLuck.Timer
`ModuleScript` · bytecode v9 · 1017 bytes · 27 constants
- **Services:** ReplicatedStorage, game, workspace
- **Key API:** Disconnect, GetService
- Constants: `ValueConvertor`, `FFlag`, `GetInstantFFlag`, `TournamentEventLuckEndTime`, `workspace`, `GetServerTimeNow`, `HasLuck`, `GetRemaining`, `math`, `max`, `FormatTimeHHMMSS`, `Text`, `Disconnect`, `Thread`, `Every`, `game`, `ReplicatedStorage`, `GetService`, `require`, `Common`, `Utils`, `Packages`, `Observers`, `Controllers`, `StPatricksDayEventController`, `observeTag`, `TournamentEventLuckTimer`

### [1040] ReplicatedStorage.Observers.Lobby.Training.NPC
`ModuleScript` · bytecode v9 · 732 bytes · 20 constants
- **Services:** ReplicatedStorage, game
- **Key API:** GetService, SetAttribute
- Constants: `EndTime`, `SetAttribute`, `UIPromptNPC`, `HasTag`, `warn`, `TrainingNPC tag should be used with UIPromptNPC! %*`, `GetFullName`, `format`, `MAXEVENTTIME`, `UnixTimestamp`, `game`, `ReplicatedStorage`, `GetService`, `require`, `Shared`, `SpecialTrainingData`, `Packages`, `Observers`, `observeTagNoAncestry`, `TrainingNPC`

### [1041] ReplicatedStorage.Observers.Lobby.Training.Timer
`ModuleScript` · bytecode v9 · 815 bytes · 22 constants
- **Services:** ReplicatedStorage, game, workspace
- **Key API:** Disconnect, GetService
- Constants: `ValueConvertor`, `MAXEVENTTIME`, `UnixTimestamp`, `workspace`, `GetServerTimeNow`, `FormatTimeWithDaysFull`, `Text`, `Disconnect`, `Thread`, `Every`, `game`, `ReplicatedStorage`, `GetService`, `require`, `Packages`, `Observers`, `Common`, `Utils`, `Shared`, `SpecialTrainingData`, `observeTagNoAncestry`, `TrainingExpiresTime`

### [1042] ReplicatedStorage.Observers.Lobby.TrioPass.NPC
`ModuleScript` · bytecode v9 · 1128 bytes · 31 constants
- **Services:** ReplicatedStorage, game
- **Key API:** Connect, Disconnect, GetService, SetAttribute
- Constants: `IsDataReady`, `SilentVeilTrioPassEndTime`, `GetKey`, `EndTime`, `IsEnabled`, `SetAttribute`, `updateEndTime`, `Disconnect`, `UIPromptNPC`, `HasTag`, `warn`, `DuoPassNPC tag should be used with UIPromptNPC! %*`, `GetFullName`, `format`, `EnabledSignal`, `Connect`, `task`, `spawn`, `game`, `ReplicatedStorage`, `GetService`, `require`, `ClientGameModules`, `FFlagClient`, `Controllers`, `UI`, `TrioPassController`, `Packages`, `Observers`, `observeTagNoAncestry`, `TrioPassNPC`

### [1043] ReplicatedStorage.Observers.Lobby.TrioPass.Timer
`ModuleScript` · bytecode v9 · 894 bytes · 24 constants
- **Services:** ReplicatedStorage, game, workspace
- **Key API:** Disconnect, GetService
- Constants: `IsDataReady`, `SilentVeilTrioPassEndTime`, `GetKey`, `LOADING`, `ValueConvertor`, `workspace`, `GetServerTimeNow`, `FormatTimeWithDays`, `Text`, `Disconnect`, `Thread`, `Every`, `game`, `ReplicatedStorage`, `GetService`, `require`, `ClientGameModules`, `FFlagClient`, `Packages`, `Observers`, `Common`, `Utils`, `observeTagNoAncestry`, `TrioPassExpiresTime`

### [1044] ReplicatedStorage.Observers.Lobby.UIPromptNPC
`ModuleScript` · bytecode v9 · 1829 bytes · 46 constants
- **Services:** Players, ReplicatedStorage, game
- **Key API:** Connect, Destroy, Disconnect, FindFirstChild, GetAttribute, GetService, LoadAnimation, Play, Stop, WaitForChild
- Constants: `WindowName`, `GetAttribute`, `Parent`, `GetPlayerFromCharacter`, `_currentGui`, `_lockId`, `tick`, `IsOpen`, `LimitedSword_SwordPacks`, `SwordPacks`, `Open`, `onTouch`, `Hitbox`, `WaitForChild`, `Touched`, `Connect`, `Disconnect`, `Stop`, `Destroy`, `warn`, `UIPromptNPC is missing WindowName attribute:`, `GetFullName`, `IdleAnimation`, `FindFirstChild`, `Animator`, `FindFirstChildWhichIsA`, `LoadAnimation`, `Play`, `OnGuiClose`, `task`, `spawn`, `game`, `ReplicatedStorage`, `GetService`, `Players`, `require`, `Packages`, `Observers`, `ClientGameModules`, `GuiHandler`, `Controllers`, `ShowRoomController`, `LocalPlayer`, `observeTagNoAncestry`, `UIPromptNPC`

### [1045] ReplicatedStorage.Observers.Lobby.WavingNPC
`ModuleScript` · bytecode v9 · 1076 bytes · 28 constants
- **Services:** ReplicatedStorage, game
- **Key API:** Destroy, Disconnect, FindFirstChild, GetAttribute, GetService, IsA, LoadAnimation, Play, Stop, WaitForChild
- Constants: `Play`, `Disconnect`, `Stop`, `Destroy`, `Humanoid`, `WaitForChild`, `Animator`, `script`, `Wave`, `Idle`, `FindFirstChild`, `Animation`, `IsA`, `LoadAnimation`, `WaveDelay`, `GetAttribute`, `Thread`, `Every`, `game`, `ReplicatedStorage`, `GetService`, `require`, `Packages`, `Observers`, `Common`, `Utils`, `observeTagNoAncestry`, `WavingNPC`

### [1046] ReplicatedStorage.Observers.Misc.BeamLOD
`ModuleScript` · bytecode v9 · 1518 bytes · 34 constants
- **Services:** ReplicatedStorage, RunService, game, workspace
- **Key API:** Connect, Disconnect, GetAttribute, GetService
- Constants: `CFrame`, `SavedQualityLevel`, `Value`, `math`, `clamp`, `Attachment0`, `Attachment1`, `Position`, `WorldPosition`, `Magnitude`, `max`, `Segments`, `updateBeams`, `GetAttribute`, `Disconnect`, `GetAttributeChangedSignal`, `Connect`, `game`, `ReplicatedStorage`, `GetService`, `RunService`, `require`, `Packages`, `Observers`, `Common`, `Utils`, `workspace`, `CurrentCamera`, `UserSettings`, `GameSettings`, `Thread`, `Every`, `observeTag`, `BeamLOD`

### [1047] ReplicatedStorage.Observers.Misc.ClassicHealthBar
`ModuleScript` · bytecode v9 · 1049 bytes · 29 constants
- **Services:** ReplicatedStorage, game
- **Key API:** Connect, Disconnect, GetAttribute, GetService, WaitForChild
- Constants: `Health`, `GetAttribute`, `MaxHealth`, `Fill`, `UDim2`, `fromScale`, `Enum`, `EasingDirection`, `Out`, `EasingStyle`, `Sine`, `TweenSize`, `onHealthUpdate`, `Disconnect`, `HealthBarHolder`, `WaitForChild`, `Value`, `GetAttributeChangedSignal`, `Connect`, `task`, `spawn`, `game`, `ReplicatedStorage`, `GetService`, `require`, `Packages`, `Observers`, `observeTagNoAncestry`, `ClassicHealthBar`

### [1048] ReplicatedStorage.Observers.Misc.ExistCountLabel
`ModuleScript` · bytecode v9 · 1887 bytes · 50 constants
- **Remotes:** Data
- **Services:** Players, ReplicatedStorage, RunService, game, workspace
- **Key API:** Destroy, GetAttribute, GetService, new
- Constants: `Get`, `string`, `format`, `ValueConvertor`, `AddCommas`, `???`, `Text`, `updateText`, `Settings`, `Misc`, `Hide Exist Count Label`, `Enabled`, `Visible`, `Destroy`, `ItemType`, `GetAttribute`, `assert`, `ItemName`, `Name`, `ItemToKey`, `new`, `OnUpdated`, `Add`, `task`, `spawn`, `Client`, `Data`, `GetReplion`, `OnDescendantChange`, `game`, `ReplicatedStorage`, `GetService`, `RunService`, `Players`, `LocalPlayer`, `require`, `Packages`, `Observers`, `Replion`, `Trove`, `Common`, `Utils`, `Shared`, `Inventory`, `Controllers`, `Trading`, `ExistCounterController`, `observeTag`, `ExistCountLabel`, `workspace`

### [1049] ReplicatedStorage.Observers.Misc.FeaturesToggleDestroy
`ModuleScript` · bytecode v9 · 664 bytes · 20 constants
- **Services:** ReplicatedStorage, game
- **Key API:** Destroy, FindFirstChild, GetAttribute, GetService
- Constants: `FeatureEnvironment`, `GetAttribute`, `warn`, `Tag with no FeatureEnvironment %*`, `GetFullName`, `format`, `FindFirstChild`, `Value`, `task`, `defer`, `Destroy`, `game`, `ReplicatedStorage`, `GetService`, `require`, `Packages`, `Observers`, `FeaturesToggle`, `observeTagNoAncestry`, `FeaturesToggleDestroy`

### [1050] ReplicatedStorage.Observers.Misc.FlatHealthBar
`ModuleScript` · bytecode v9 · 1298 bytes · 35 constants
- **Services:** ReplicatedStorage, game
- **Key API:** Connect, Disconnect, GetAttribute, GetService, WaitForChild
- Constants: `Health`, `GetAttribute`, `MaxHealth`, `ProgressBar`, `TextLabel`, `%*/%*`, `format`, `Text`, `Holder`, `UDim2`, `fromScale`, `Enum`, `EasingDirection`, `Out`, `EasingStyle`, `Sine`, `TweenPosition`, `Fill`, `onHealthUpdate`, `Disconnect`, `HealthBarHolder`, `WaitForChild`, `Value`, `GetAttributeChangedSignal`, `Connect`, `task`, `spawn`, `game`, `ReplicatedStorage`, `GetService`, `require`, `Packages`, `Observers`, `observeTagNoAncestry`, `FlatHealthBar`

### [1051] ReplicatedStorage.Observers.Misc.LiveEventHealthBar
`ModuleScript` · bytecode v9 · 1161 bytes · 28 constants
- **Services:** ReplicatedStorage, game
- **Key API:** Connect, Disconnect, GetAttribute, GetService, WaitForChild, new
- Constants: `Health`, `GetAttribute`, `MaxHealth`, `Frame`, `BossHealth`, `UDim2`, `new`, `TileSize`, `Bars`, `fromScale`, `Size`, `onHealthUpdate`, `Disconnect`, `HealthBarHolder`, `WaitForChild`, `Value`, `GetAttributeChangedSignal`, `Connect`, `task`, `spawn`, `game`, `ReplicatedStorage`, `GetService`, `require`, `Packages`, `Observers`, `observeTagNoAncestry`, `LiveEventHealthBar`

### [1052] ReplicatedStorage.Observers.Misc.LuckyBlock
`ModuleScript` · bytecode v9 · 1549 bytes · 35 constants
- **Services:** Debris, Players, ReplicatedStorage, RunService, game, workspace
- **Key API:** Connect, Destroy, GetAttribute, GetService, new
- Constants: `workspace`, `GetServerTimeNow`, `math`, `clamp`, `Lerp`, `CFrame`, `Angles`, `new`, `sin`, `PivotTo`, `Destroy`, `AnimationTimeout`, `GetAttribute`, `StartTime`, `TargetPivot`, `max`, `PostSimulation`, `Connect`, `Add`, `game`, `ReplicatedStorage`, `GetService`, `RunService`, `Players`, `Debris`, `LocalPlayer`, `require`, `Packages`, `Observers`, `Common`, `Utils`, `Trove`, `Runtime`, `observeTag`, `LuckyBlock`

### [1053] ReplicatedStorage.Observers.Misc.NewYearsTimer
`ModuleScript` · bytecode v9 · 951 bytes · 25 constants
- **Services:** ReplicatedStorage, game, workspace
- **Key API:** Disconnect, GetAttribute, GetService
- Constants: `workspace`, `GetServerTimeNow`, `StartTime`, `GetAttribute`, `NewYearsEvent`, `Starts in: %*`, `ValueConvertor`, `FormatTimeWithDaysFull`, `format`, `Text`, `Happening now!`, `updateTimer`, `Disconnect`, `Thread`, `Every`, `game`, `ReplicatedStorage`, `GetService`, `require`, `Packages`, `Observers`, `Common`, `Utils`, `observeTag`, `NewYearsEventTimer`

### [1054] ReplicatedStorage.Observers.Misc.PumpkinSword
`ModuleScript` · bytecode v9 · 2972 bytes · 59 constants
- **Services:** Debris, Players, ReplicatedStorage, RunService, game, workspace
- **Key API:** Clone, Connect, Destroy, Disconnect, GetAttribute, GetService, LoadAnimation, Once, Play, Stop, WaitForChild, new
- Constants: `Dead`, `GetAttribute`, `PumpkinSword`, `RemoveTag`, `Visual`, `PlayEffects`, `Destroy`, `Play`, `script`, `SneezeEmit`, `Clone`, `Parent`, `Physics`, `CreateWeld`, `CFrame`, `new`, `fromOrientation`, `C0`, `task`, `delay`, `AddItem`, `SneezeSFX`, `Ended`, `Once`, `Thread`, `SafeCancel`, `setIdle`, `SpinSFX`, `Stop`, `Disconnect`, `IsClient`, `sord`, `WaitForChild`, `Humanoid`, `Animator`, `IsDescendantOf`, `GetAttributeChangedSignal`, `Connect`, `Spin`, `LoadAnimation`, `Sneeze`, `Every`, `Parrying`, `Running`, `game`, `ReplicatedStorage`, `GetService`, `RunService`, `Players`, `Debris`, `LocalPlayer`, `require`, `Packages`, `Observers`, `Common`, `Utils`, `workspace`, `Alive`, `observeTag`

### [1055] ReplicatedStorage.Observers.Misc.SeraphimSwordFollow
`ModuleScript` · bytecode v9 · 2890 bytes · 51 constants
- **Services:** Players, ReplicatedStorage, RunService, game, workspace
- **Key API:** Connect, Disconnect, GetAttribute, GetService, IsA, SetAttribute, WaitForChild, new
- Constants: `CurrentEmote`, `GetAttribute`, `Dead`, `SeraphimSwordFollow`, `RemoveTag`, `Enabled`, `PivotTo`, `PrimaryPart`, `Character`, `ParryTime`, `Parrying`, `math`, `max`, `SetAttribute`, `GetJoints`, `Motor6D`, `IsA`, `Part0`, `Name`, `Torso`, `LowerTorso`, `sin`, `CFrame`, `new`, `min`, `Lerp`, `Angles`, `Disconnect`, `sord`, `WaitForChild`, `Parent`, `Humanoid`, `FindFirstChildWhichIsA`, `workspace`, `Alive`, `IsDescendantOf`, `GetAttributeChangedSignal`, `Connect`, `GetPivot`, `PreRender`, `PreAnimation`, `game`, `ReplicatedStorage`, `GetService`, `RunService`, `Players`, `LocalPlayer`, `require`, `Packages`, `Observers`, `observeTag`

### [1056] ReplicatedStorage.Observers.Misc.SerialLabel
`ModuleScript` · bytecode v9 · 2408 bytes · 60 constants
- **Remotes:** Data
- **Services:** Players, ReplicatedStorage, RunService, game, workspace
- **Key API:** Connect, Destroy, GetAttribute, GetService, new
- Constants: `Get`, `Settings`, `Misc`, `Hide Serial Label`, `Enabled`, `Visible`, `string`, `format`, `ValueConvertor`, `AddCommas`, `???`, `Text`, `updateText`, `CurrentEmoteSerial`, `GetAttribute`, `CurrentEmotePassiveSerial`, `Destroy`, `ItemType`, `assert`, `ItemName`, `new`, `Name`, `ItemToKey`, `Client`, `Data`, `GetReplion`, `Emote`, `workspace`, `Alive`, `IsDescendantOf`, `Dead`, `Model`, `FindFirstAncestorWhichIsA`, `GetAttributeChangedSignal`, `Connect`, `Add`, `OnUpdated`, `task`, `spawn`, `OnDescendantChange`, `game`, `ReplicatedStorage`, `GetService`, `RunService`, `Players`, `LocalPlayer`, `require`, `Packages`, `Observers`, `Trove`, `Replion`, `Common`, `Utils`, `Shared`, `Inventory`, `Controllers`, `Trading`, `ExistCounterController`, `observeTag`, `SerialLabel`

### [1057] ReplicatedStorage.Observers.Misc.TweenColor
`ModuleScript` · bytecode v9 · 452 bytes · 14 constants
- **Services:** Players, ReplicatedStorage, game, workspace
- **Key API:** GetService
- Constants: `game`, `ReplicatedStorage`, `GetService`, `Players`, `require`, `Packages`, `Observers`, `Shared`, `TweenColor`, `LocalPlayer`, `PlayerGui`, `observeTag`, `Watch`, `workspace`

### [1059] ReplicatedStorage.Observers.TradingPlaza.Index
`ModuleScript` · bytecode v9 · 968 bytes · 26 constants
- **Services:** Players, ReplicatedStorage, game, workspace
- **Key API:** Connect, Destroy, GetService, new
- Constants: `Open`, `Destroy`, `new`, `ProximityPrompt`, `FindFirstChildWhichIsA`, `Triggered`, `Connect`, `Add`, `game`, `ReplicatedStorage`, `GetService`, `Players`, `require`, `Packages`, `Observers`, `Replion`, `Trove`, `Controllers`, `ShowRoomController`, `Trading`, `IndexController`, `ServerInfo`, `LocalPlayer`, `observeTag`, `Index`, `workspace`

### [1060] ReplicatedStorage.Observers.TradingPlaza.IndexBook
`ModuleScript` · bytecode v9 · 1688 bytes · 46 constants
- **Services:** Players, ReplicatedStorage, RunService, TweenService, game, workspace
- **Key API:** Connect, Disconnect, GetAttribute, GetService, IsA, SetAttribute, new
- Constants: `Character`, `GetPivot`, `CFrame`, `identity`, `Position`, `lookAt`, `ToOrientation`, `fromOrientation`, `Angles`, `Rotation`, `GetJoints`, `Weld`, `IsA`, `Motor6D`, `Name`, `IgnoreFloat`, `DefaultC0`, `GetAttribute`, `C0`, `SetAttribute`, `new`, `os`, `clock`, `math`, `sin`, `Lerp`, `Disconnect`, `Folder`, `FindFirstAncestorWhichIsA`, `BasePart`, `WorldPosition`, `PostSimulation`, `Connect`, `game`, `ReplicatedStorage`, `GetService`, `TweenService`, `RunService`, `Players`, `LocalPlayer`, `require`, `Packages`, `Observers`, `observeTag`, `IndexBook`, `workspace`

### [1061] ReplicatedStorage.Observers.TradingPlaza.LiveSale.LiveSaleFrame
`ModuleScript` · bytecode v9 · 1294 bytes · 33 constants
- **Services:** ReplicatedStorage, UserInputService, game, workspace
- **Key API:** GetAttribute, GetService, WaitForChild, new
- Constants: `Cancel`, `Parent`, `Priority`, `GetAttribute`, `workspace`, `GetServerTimeNow`, `barTweenEndTime`, `Bar`, `WaitForChild`, `Visible`, `barTweenDuration`, `UDim2`, `new`, `Size`, `fastTween`, `TweenInfo`, `Enum`, `EasingStyle`, `Quad`, `EasingDirection`, `In`, `GroupTransparency`, `game`, `ReplicatedStorage`, `GetService`, `require`, `UserInputService`, `Packages`, `Observers`, `Shared`, `FastUtils`, `observeTagNoAncestry`, `LiveSaleFrame`

### [1062] ReplicatedStorage.Observers.TradingPlaza.LiveSale.LiveSaleSurfaceGui
`ModuleScript` · bytecode v9 · 507 bytes · 14 constants
- **Services:** Players, ReplicatedStorage, game
- **Key API:** GetService
- Constants: `Parent`, `Adornee`, `ResetOnSpawn`, `game`, `ReplicatedStorage`, `GetService`, `Players`, `require`, `Packages`, `Observers`, `LocalPlayer`, `PlayerGui`, `observeTagNoAncestry`, `LiveSaleSurfaceGui`

### [1063] ReplicatedStorage.Observers.UI.AdminPanelButton
`ModuleScript` · bytecode v9 · 1434 bytes · 36 constants
- **Services:** ReplicatedStorage, game
- **Key API:** Clone, Connect, Destroy, GetService, new
- Constants: `Visible`, `Destroy`, `Maid`, `new`, `Instance`, `Frame`, `Active`, `UDim2`, `Size`, `Position`, `Color3`, `fromRGB`, `BackgroundColor3`, `BackgroundTransparency`, `Cover`, `UICorner`, `FindFirstChildOfClass`, `Clone`, `Parent`, `Corner`, `MouseEnter`, `Connect`, `GiveTask`, `MouseLeave`, `MouseButton1Down`, `MouseButton1Up`, `game`, `ReplicatedStorage`, `GetService`, `require`, `Packages`, `Observers`, `Common`, `Utils`, `observeTagNoAncestry`, `UI_AdminPanelButton`

### [1064] ReplicatedStorage.Observers.UI.AssignGradient
`ModuleScript` · bytecode v9 · 1000 bytes · 24 constants
- **Services:** ReplicatedStorage, TweenService, game
- **Key API:** Connect, Destroy, GetAttribute, GetService, new
- Constants: `Color`, `GetColorGradient`, `Parent`, `UpdateColor`, `Destroy`, `Maid`, `new`, `GradientColor`, `GetAttribute`, `GetAttributeChangedSignal`, `Connect`, `OnGradientColorChange`, `game`, `ReplicatedStorage`, `GetService`, `TweenService`, `require`, `Packages`, `Observers`, `Common`, `Utils`, `ColorsUtil`, `observeTagNoAncestry`, `UI_AssignGradient`

### [1065] ReplicatedStorage.Observers.UI.AutomaticCanvasSize
`ModuleScript` · bytecode v9 · 2079 bytes · 42 constants
- **Services:** ReplicatedStorage, game
- **Key API:** Connect, Destroy, FindFirstChild, GetAttribute, GetService, IsA, new
- Constants: `ScrollingDirection`, `Enum`, `Y`, `XY`, `X`, `UDim2`, `new`, `AbsoluteContentSize`, `CanvasSize`, `Offset`, `UpdateSize`, `pcall`, `task`, `cancel`, `delay`, `ChildAdded`, `Connect`, `UILayoutChanged`, `Name`, `IsA`, `UIListLayout`, `UIGridLayout`, `GetPropertyChangedSignal`, `TrackingSizeChanges`, `ChildRemoved`, `Validate`, `Destroy`, `Maid`, `UI_Source`, `GetAttribute`, `FindFirstChild`, `FindFirstChildOfClass`, `game`, `ReplicatedStorage`, `GetService`, `require`, `Packages`, `Observers`, `Common`, `Utils`, `observeTagNoAncestry`, `UI_AutomaticCanvasSize`

### [1066] ReplicatedStorage.Observers.UI.ButtonHoverAnimation
`ModuleScript` · bytecode v9 · 780 bytes · 18 constants
- **Services:** ReplicatedStorage, game
- **Key API:** Connect, Disconnect, GetService
- Constants: `Exit`, `exit`, `Enter`, `Disconnect`, `MouseEnter`, `Connect`, `MouseLeave`, `Activated`, `game`, `ReplicatedStorage`, `GetService`, `require`, `Packages`, `Observers`, `ClientGameModules`, `UIHover`, `observeTagNoAncestry`, `UI_ButtonHoverAnimation`

### [1067] ReplicatedStorage.Observers.UI.ButtonHoverAnimation2
`ModuleScript` · bytecode v9 · 1293 bytes · 30 constants
- **Services:** ReplicatedStorage, game
- **Key API:** Connect, Disconnect, GetService, new
- Constants: `Exit`, `exit`, `Enter`, `Disconnect`, `MouseEnter`, `Connect`, `MouseLeave`, `Activated`, `AnchorPoint`, `Magnitude`, `Size`, `Position`, `UDim2`, `new`, `X`, `Scale`, `Offset`, `Y`, `game`, `ReplicatedStorage`, `GetService`, `require`, `Packages`, `Observers`, `ClientGameModules`, `UIHover`, `Vector2`, `one`, `observeTagNoAncestry`, `UI_ButtonHoverAnimation2`

### [1068] ReplicatedStorage.Observers.UI.Buttons.InviteRewardsButton
`ModuleScript` · bytecode v9 · 2780 bytes · 61 constants
- **Remotes:** Data, Update
- **Services:** ReplicatedStorage, UserInputService, game
- **Key API:** Connect, Destroy, FindFirstChild, Fire, GetService, Once, WaitForChild, new
- Constants: `HasFriends`, `Fire`, `Invites`, `InviteRewards.ClaimedRewards`, `Id`, `Find`, `Reward%*`, `format`, `FindFirstChild`, `Visible`, `CanInvite`, `HasRewards`, `Update`, `update`, `getAttributeState`, `MobileOnly`, `Add`, `Computed`, `Watch`, `Once`, `PromptFriendInvite`, `Destroy`, `new`, `UI_ButtonHoverAnimation`, `AddTag`, `Client`, `Data`, `AwaitReplion`, `Activated`, `Connect`, `game`, `ReplicatedStorage`, `GetService`, `GuiService`, `require`, `UserInputService`, `WaitForChild`, `Packages`, `Trove`, `Signal`, `Replion`, `Observers`, `ClientGameModules`, `UIHover`, `Shared`, `InviteRewards`, `Statable`, `Controllers`, `UI`, `InviteRewardsController`, `task`, `spawn`, `table`, `clone`, `insert`, `sort`, `IsTenFootInterface`, `TouchEnabled`, `KeyboardEnabled`, `observeTagNoAncestry`, `UI_InviteRewardsButton`

### [1069] ReplicatedStorage.Observers.UI.CopyFrom
`ModuleScript` · bytecode v9 · 1963 bytes · 34 constants
- **Services:** ReplicatedStorage, TweenService, game
- **Key API:** Destroy, GetAttribute, GetService, IsA, new
- Constants: `Visible`, `Image`, `HoverImage`, `Text`, `Clean`, `new`, `observeProperty`, `Add`, `GuiButton`, `IsA`, `GuiUtils`, `mirrorActivated`, `IgnoreImages`, `GetAttribute`, `ImageLabel`, `ImageButton`, `TextLabel`, `TextButton`, `Destroy`, `Parent`, `Value`, `game`, `ReplicatedStorage`, `GetService`, `TweenService`, `require`, `Packages`, `Observers`, `Common`, `Utils`, `ColorsUtil`, `Trove`, `observeTagNoAncestry`, `UI_CopyFrom`

### [1070] ReplicatedStorage.Observers.UI.CoveredUI
`ModuleScript` · bytecode v9 · 894 bytes · 22 constants
- **Services:** ReplicatedStorage, TweenService, game
- **Key API:** Connect, Disconnect, GetService
- Constants: `IsUICovered`, `UI_%*`, `Name`, `format`, `Enabled`, `SetTag`, `update`, `Disconnect`, `GetPropertyChangedSignal`, `Connect`, `game`, `ReplicatedStorage`, `GetService`, `TweenService`, `require`, `Controllers`, `UI`, `UIStateController`, `Packages`, `Observers`, `observeTagNoAncestry`, `UI_CoveredUI`

### [1071] ReplicatedStorage.Observers.UI.DynamicUIStroke
`ModuleScript` · bytecode v9 · 1823 bytes · 30 constants
- **Services:** ReplicatedStorage, game, workspace
- **Key API:** Connect, Disconnect, GetAttribute, GetService, SetAttribute
- Constants: `getThicknessSize`, `StrokeThickness`, `GetAttribute`, `Thickness`, `updateStrokeThickness`, `ViewportSize`, `X`, `Y`, `math`, `min`, `updateStrokes`, `task`, `cancel`, `delay`, `Disconnect`, `IsDescendantOf`, `SetAttribute`, `GetAttributeChangedSignal`, `Connect`, `game`, `ReplicatedStorage`, `GetService`, `require`, `Packages`, `Observers`, `workspace`, `CurrentCamera`, `GetPropertyChangedSignal`, `observeTagNoAncestry`, `UI_DynamicUIStroke`

### [1072] ReplicatedStorage.Observers.UI.FFlagVisibility
`ModuleScript` · bytecode v9 · 1127 bytes · 31 constants
- **Services:** ReplicatedStorage, UserInputService, game
- **Key API:** Connect, Destroy, GetAttribute, GetService, IsA, WaitForChild
- Constants: `IsDataReady`, `GetKey`, `LayerCollector`, `IsA`, `Enabled`, `GuiObject`, `Visible`, `onUpdate`, `Destroy`, `FFlagKey`, `GetAttribute`, `warn`, `"FFlagKey" Attribute not found for %*`, `GetFullName`, `format`, `DataUpdatedEvent`, `Connect`, `task`, `spawn`, `game`, `ReplicatedStorage`, `GetService`, `require`, `UserInputService`, `WaitForChild`, `Packages`, `Observers`, `ClientGameModules`, `FFlagClient`, `observeTagNoAncestry`, `FFlagVisibility`

### [1073] ReplicatedStorage.Observers.UI.GamepadIcon
`ModuleScript` · bytecode v9 · 1608 bytes · 39 constants
- **Remotes:** Set
- **Services:** ReplicatedStorage, UserInputService, game
- **Key API:** Connect, Destroy, FindFirstChild, GetService, WaitForChild, new
- Constants: `Enum`, `KeyCode`, `ButtonB`, `GetStringForKeyCode`, `ButtonCircle`, `PS`, `Set`, `XBOX`, `updateConsoleType`, `getAttributeState`, `FindFirstChild`, `Image`, `rbxassetid://6034407076`, `Destroy`, `Maid`, `new`, `setPropertyComputed`, `propertyComputed`, `game`, `ReplicatedStorage`, `GetService`, `require`, `UserInputService`, `WaitForChild`, `GuiService`, `Packages`, `Observers`, `Common`, `Utils`, `Shared`, `Statable`, `State`, `script`, `GamepadConnected`, `Connect`, `GamepadDisconnected`, `observeTagNoAncestry`, `UI_GamepadIcon`

### [1074] ReplicatedStorage.Observers.UI.GridRescale_Y
`ModuleScript` · bytecode v9 · 1139 bytes · 28 constants
- **Services:** ReplicatedStorage, TweenService, game
- **Key API:** Connect, Destroy, GetAttribute, GetService, new
- Constants: `UDim2`, `new`, `CellSize`, `X`, `Scale`, `Offset`, `AbsoluteCellSize`, `UpdateSize`, `Destroy`, `Maid`, `UI_GridRatio`, `GetAttribute`, `AbsoluteContentSize`, `GetPropertyChangedSignal`, `Connect`, `GiveTask`, `game`, `ReplicatedStorage`, `GetService`, `TweenService`, `require`, `Packages`, `Observers`, `Common`, `Utils`, `ColorsUtil`, `observeTagNoAncestry`, `UI_GridRescale_Y`

### [1075] ReplicatedStorage.Observers.UI.HoverInfo
`ModuleScript` · bytecode v9 · 1237 bytes · 22 constants
- **Services:** ReplicatedStorage, game
- **Key API:** Connect, Disconnect, GetAttribute, GetService
- Constants: `ItemKey`, `GetAttribute`, `ItemType`, `Add`, `Remove`, `updateInfo`, `task`, `defer`, `requestUpdateInfo`, `Disconnect`, `GetAttributeChangedSignal`, `Connect`, `game`, `ReplicatedStorage`, `GetService`, `require`, `Packages`, `Observers`, `Controllers`, `HoverInfoController`, `observeTagNoAncestry`, `HoverInfo`

### [1076] ReplicatedStorage.Observers.UI.MobileConfiguration
`ModuleScript` · bytecode v9 · 2027 bytes · 34 constants
- **Services:** Players, ReplicatedStorage, game
- **Key API:** Connect, Destroy, GetAttribute, GetService, WaitForChild, new
- Constants: `Position`, `IsMobile`, `ResetPosition`, `UpdatePosition`, `MovingPosition`, `GetAttribute`, `Size`, `ResetSize`, `UpdateSize`, `MovingSize`, `Destroy`, `Maid`, `new`, `GetAttributeChangedSignal`, `Connect`, `OnMovingPositionChanged`, `OnMovingSizeChanged`, `game`, `ReplicatedStorage`, `GetService`, `Players`, `LocalPlayer`, `require`, `Packages`, `Observers`, `Common`, `Utils`, `PlayerScripts`, `Client`, `WaitForChild`, `DeviceChecker`, `observeTagNoAncestry`, `UI_MobileConfiguration`, `UDim2`

### [1077] ReplicatedStorage.Observers.UI.MobileOnly
`ModuleScript` · bytecode v9 · 743 bytes · 21 constants
- **Services:** ReplicatedStorage, UserInputService, game
- **Key API:** Connect, Disconnect, GetService, WaitForChild
- Constants: `Enum`, `UserInputType`, `Touch`, `Visible`, `update`, `Disconnect`, `LastInputTypeChanged`, `Connect`, `task`, `spawn`, `GetLastInputType`, `game`, `ReplicatedStorage`, `GetService`, `require`, `UserInputService`, `WaitForChild`, `Packages`, `Observers`, `observeTagNoAncestry`, `MobileOnly`

### [1078] ReplicatedStorage.Observers.UI.MovingGradient
`ModuleScript` · bytecode v9 · 1483 bytes · 34 constants
- **Services:** Players, ReplicatedStorage, RunService, TweenService, game
- **Key API:** Connect, Disconnect, GetService, new
- Constants: `Vector2`, `new`, `Offset`, `X`, `Rotation`, `Disconnect`, `Parent`, `Visible`, `RenderStepped`, `Connect`, `updateVisibility`, `coroutine`, `status`, `suspended`, `pcall`, `task`, `cancel`, `GetPropertyChangedSignal`, `defer`, `game`, `ReplicatedStorage`, `GetService`, `TweenService`, `RunService`, `Players`, `require`, `Controllers`, `UI`, `UIStateController`, `Packages`, `Observers`, `observeTag`, `MovingGradient`, `LocalPlayer`

### [1079] ReplicatedStorage.Observers.UI.PlayerCounterSign
`ModuleScript` · bytecode v9 · 2340 bytes · 51 constants
- **Services:** Players, ReplicatedStorage, game, workspace
- **Key API:** Destroy, FindFirstChild, Fire, GetAttribute, GetChildren, GetPlayers, GetService, WaitForChild, new
- Constants: `WaitForChild`, `Fire`, `FindFirstChild`, `new`, `task`, `defer`, `Wait`, `Destroy`, `infiniteYieldForChild`, `GetPlayers`, `GetChildren`, `workspace`, `AFK_Players`, `GetAttribute`, `string`, `format`, `IN SERVER: %s`, `tostring`, `Text`, `ALIVE: %s`, `PLAYING: %s`, `count`, `Parent`, `wait`, `Maid`, `Spawn`, `Name`, `NewPlayerCounter`, `GUI`, `SurfaceGui`, `Bottom`, `Server`, `Alive`, `Playing`, `InServer`, `rats`, `Common`, `game`, `ReplicatedStorage`, `GetService`, `Players`, `require`, `Packages`, `Observers`, `Utils`, `Signal`, `Replion`, `Shared`, `UseNewLobby`, `observeTagNoAncestry`, `UI_PlayerCounterSign`

### [1080] ReplicatedStorage.Observers.UI.ProductPriceLabel
`ModuleScript` · bytecode v9 · 1852 bytes · 47 constants
- **Services:** CollectionService, ReplicatedStorage, game
- **Key API:** Connect, Disconnect, GetAttribute, GetService
- Constants: `PriceInRobux`, `string`, `format`, `AddCommas`, `Text`, `ProductId`, `GetAttribute`, `tonumber`, `warn`, `Invalid ProductId for %*: %*`, `GetFullName`, `ProductPriceLabel`, `HasTag`, `%s`, `PriceFormat`, `DevProduct`, `ProductType`, `GetProductInfoAsync`, `andThen`, `catch`, `updatePriceLabel`, `GetTagged`, `task`, `spawn`, `Disconnect`, `GetAttributeChangedSignal`, `Connect`, `game`, `ReplicatedStorage`, `GetService`, `CollectionService`, `require`, `Common`, `MarketplaceService`, `Packages`, `Observers`, `Utils`, `Utilities`, `Thread`, `ValueConvertor`, `GamePass`, `Enum`, `InfoType`, `Product`, `Every`, `observeTagNoAncestry`

### [1081] ReplicatedStorage.Observers.UI.PumpkinsCounter
`ModuleScript` · bytecode v9 · 1572 bytes · 42 constants
- **Remotes:** Data
- **Services:** ReplicatedStorage, game
- **Key API:** Connect, Destroy, FindFirstChild, GetService, WaitForChild, new
- Constants: `Get`, `tostring`, `Text`, `update`, `GetPolicyInfo`, `ArePaidRandomItemsRestricted`, `Visible`, `reflectPolicy`, `Destroy`, `Maid`, `new`, `Client`, `Data`, `WaitReplion`, `Add`, `FindFirstChild`, `Amount`, `WaitForChild`, `OnChange`, `ReplionChange`, `Activated`, `Connect`, `buyActivated`, `UI_ButtonHoverAnimation2`, `AddTag`, `game`, `ReplicatedStorage`, `GetService`, `require`, `Shared`, `Policy`, `Packages`, `Replion`, `@game/ReplicatedStorage/Shared/InfiniteBattlepass/InfiniteBattlepassData`, `SeasonData`, `Currency`, `Name`, `Observers`, `Common`, `Utils`, `observeTagNoAncestry`, `UI_PumpkinsCounter`

### [1082] ReplicatedStorage.Observers.UI.ResizeYWithContentGridLayout
`ModuleScript` · bytecode v9 · 1235 bytes · 30 constants
- **Services:** ReplicatedStorage, game
- **Key API:** Connect, Destroy, GetService, new
- Constants: `Destroy`, `UDim2`, `new`, `Size`, `X`, `Scale`, `Offset`, `math`, `ceil`, `AbsoluteContentSize`, `Y`, `task`, `delay`, `UpdateSize`, `Maid`, `UIGridLayout`, `FindFirstChildOfClass`, `GetPropertyChangedSignal`, `Connect`, `GiveTask`, `game`, `ReplicatedStorage`, `GetService`, `require`, `Packages`, `Observers`, `Common`, `Utils`, `observeTagNoAncestry`, `UI_ResizeYWithContentGridLayout`

### [1083] ReplicatedStorage.Observers.UI.ResizeYWithUILayout
`ModuleScript` · bytecode v9 · 1312 bytes · 32 constants
- **Services:** ReplicatedStorage, game
- **Key API:** Connect, Destroy, GetAttribute, GetService, IsA, new
- Constants: `Parent`, `UDim2`, `new`, `Size`, `X`, `Scale`, `Offset`, `Y`, `AbsoluteContentSize`, `UpdateSize`, `Destroy`, `Maid`, `UI_Extra`, `GetAttribute`, `UI_Source`, `Name`, `IsA`, `UIListLayout`, `UIGridLayout`, `GetPropertyChangedSignal`, `Connect`, `GiveTask`, `game`, `ReplicatedStorage`, `GetService`, `require`, `Packages`, `Observers`, `Common`, `Utils`, `observeTag`, `UI_ResizeYWithUILayout`

### [1084] ReplicatedStorage.Observers.UI.SGAwards
`ModuleScript` · bytecode v9 · 1080 bytes · 28 constants
- **Services:** ReplicatedStorage, game
- **Key API:** Connect, Destroy, FindFirstChild, GetAttribute, GetService, new
- Constants: `UDim2`, `new`, `AbsoluteContentSize`, `Y`, `CanvasSize`, `UpdateSize`, `Destroy`, `Maid`, `UI_Extra`, `GetAttribute`, `UIListLayout`, `UI_Source`, `FindFirstChild`, `FindFirstChildOfClass`, `UIGridLayout`, `GetPropertyChangedSignal`, `Connect`, `GiveTask`, `game`, `ReplicatedStorage`, `GetService`, `require`, `Packages`, `Observers`, `Common`, `Utils`, `observeTagNoAncestry`, `UI_Scrolling_Y`

### [1085] ReplicatedStorage.Observers.UI.SGDailyLogin
`ModuleScript` · bytecode v9 · 5782 bytes · 115 constants
- **Remotes:** Data, Freeze
- **Services:** Players, ReplicatedStorage, StarterGui, game, workspace
- **Key API:** Connect, Destroy, Disconnect, FindFirstChild, Fire, GetAttribute, GetChildren, GetService, IsA, SetAttribute, WaitForChild, new
- Constants: `CurrentDailyLoginType`, `Get`, `Longterm`, `setEnabled`, `updateIcon`, `Name`, `Close`, `workspace`, `GetServerTimeNow`, `BottomBar`, `TomorrowTextLabel`, `Visible`, `ClaimButton`, `_notify`, `ValueConvertor`, `FormatTime`, `Text`, `Disconnect`, `UIStroke`, `Color3`, `fromRGB`, `Color`, `StrokeThickness`, `SetAttribute`, `TopBar`, `BackgroundColor3`, `ImageColor3`, `pairs`, `Content`, `GetChildren`, `Frame`, `IsA`, `tonumber`, `Bar`, `FindFirstChild`, `Thread`, `Every`, `ClearLastClaimButton`, `CLAIMED`, `UpdateTimer`, `Credits`, `ItemIcon`, `ImageLabel`, `Icons`, `GetIcon`, `Image`, `AmountTextLabel`, `AddCommas`, `SwordSkins`, `next`, `GetSwordIcon`, `SetSwordIconAsViewportByName`, `updateRewardFrame`, `Network`, `ClaimLoginReward`, `Fire`, `HasFreezeDailyLoginReward`, `GetAttribute`, `createAbilityReward`, `Freeze`, `2`, `RewardInfo`, `playerOwnsItem`, `Icon`, `DisplayName`, `DailyLogin`, `DailyLoginStreak`, `WaitForIcon`, `OnChange`, `CloseButton`, `MouseButton1Click`, `Connect`, `DailyLoginStreakChanged`, `DailyLoginChanged`, `Parent`, `MouseButton1Down`, `GiveTask`, `GetAttributeChangedSignal`, `Abilities`, `Unlocked`, `Destroy`, `Maid`, `new`, `WaitForChild`, `Client`, `Data`, `AwaitReplion`, `game`, `ReplicatedStorage`, `GetService`, `LocalizationService`, `StarterGui`, `Players`, `require`, `Packages`, `Observers`, `Common`, `Utils`, `DailyLoginInfo`, `Legacy`, `Rewards`, `Shared`, `ReplicatedInstances`, `Swords`, `Replion`, `ClientGameModules`, `GuiHandler`, `Controllers`, `UI`, `TopBarController`, `DailyLoginController`, `ItemInfo`, `LocalPlayer`, `observeTagNoAncestry`, `UI_SGDailyLogin`

### [1086] ReplicatedStorage.Observers.UI.Scrolling_Y
`ModuleScript` · bytecode v9 · 1080 bytes · 28 constants
- **Services:** ReplicatedStorage, game
- **Key API:** Connect, Destroy, FindFirstChild, GetAttribute, GetService, new
- Constants: `UDim2`, `new`, `AbsoluteContentSize`, `Y`, `CanvasSize`, `UpdateSize`, `Destroy`, `Maid`, `UI_Extra`, `GetAttribute`, `UIListLayout`, `UI_Source`, `FindFirstChild`, `FindFirstChildOfClass`, `UIGridLayout`, `GetPropertyChangedSignal`, `Connect`, `GiveTask`, `game`, `ReplicatedStorage`, `GetService`, `require`, `Packages`, `Observers`, `Common`, `Utils`, `observeTagNoAncestry`, `UI_Scrolling_Y`

### [1087] ReplicatedStorage.Observers.UI.SeasonPassCurrencyIcon
`ModuleScript` · bytecode v9 · 580 bytes · 16 constants
- **Services:** ReplicatedStorage, game
- **Key API:** GetService, IsA
- Constants: `ImageLabel`, `IsA`, `ImageButton`, `SeasonData`, `Currency`, `Icon`, `Image`, `game`, `ReplicatedStorage`, `GetService`, `require`, `Packages`, `Observers`, `@game/ReplicatedStorage/Shared/InfiniteBattlepass/InfiniteBattlepassData`, `observeTagNoAncestry`, `UI_SeasonPassCurrencyIcon`

### [1088] ReplicatedStorage.Observers.UI.SeasonPassCurrencyName
`ModuleScript` · bytecode v9 · 590 bytes · 18 constants
- **Services:** ReplicatedStorage, game
- **Key API:** GetAttribute, GetService
- Constants: `string`, `format`, `%s`, `Pattern`, `GetAttribute`, `SeasonData`, `Currency`, `Name`, `Text`, `game`, `ReplicatedStorage`, `GetService`, `require`, `Packages`, `Observers`, `@game/ReplicatedStorage/Shared/InfiniteBattlepass/InfiniteBattlepassData`, `observeTagNoAncestry`, `UI_SeasonPassCurrencyName`

### [1089] ReplicatedStorage.Observers.UI.SpecialTextBox
`ModuleScript` · bytecode v9 · 1225 bytes · 29 constants
- **Services:** ReplicatedStorage, game
- **Key API:** Connect, Destroy, GetService, WaitForChild, new
- Constants: `Color3`, `fromRGB`, `BackgroundColor3`, `UDim2`, `new`, `Size`, `X`, `Scale`, `Offset`, `Y`, `Destroy`, `Maid`, `Box`, `WaitForChild`, `FocusedBar`, `Focused`, `Connect`, `GiveTask`, `FocusLost`, `game`, `ReplicatedStorage`, `GetService`, `require`, `Packages`, `Observers`, `Common`, `Utils`, `observeTagNoAncestry`, `UI_SpecialTextBox`

### [1090] ReplicatedStorage.Observers.UI.Spinner
`ModuleScript` · bytecode v9 · 724 bytes · 23 constants
- **Services:** ReplicatedStorage, TweenService, game
- **Key API:** Create, Destroy, GetService, Play, new
- Constants: `PlaybackState`, `Enum`, `Playing`, `Cancel`, `Destroy`, `TweenInfo`, `new`, `EasingStyle`, `Linear`, `EasingDirection`, `Out`, `Rotation`, `Create`, `Play`, `game`, `ReplicatedStorage`, `GetService`, `TweenService`, `require`, `Packages`, `Observers`, `observeTagNoAncestry`, `UI_Spinner`

### [1091] ReplicatedStorage.Observers.UI.SurfaceGuiFocus
`ModuleScript` · bytecode v9 · 898 bytes · 25 constants
- **Services:** ReplicatedStorage, game
- **Key API:** Connect, Destroy, Disconnect, GetService, new
- Constants: `AlwaysOnTop`, `Disconnect`, `Destroy`, `Instance`, `new`, `Frame`, `Active`, `SurfaceGuiFocus`, `Name`, `ZIndex`, `UDim2`, `fromScale`, `Size`, `BackgroundTransparency`, `Parent`, `MouseEnter`, `Connect`, `MouseLeave`, `game`, `ReplicatedStorage`, `GetService`, `require`, `Packages`, `Observers`, `observeTagNoAncestry`

### [1092] ReplicatedStorage.Observers.UI.TestKeyOpenUI
`ModuleScript` · bytecode v9 · 925 bytes · 21 constants
- **Services:** ReplicatedStorage, UserInputService, game
- **Key API:** Connect, Disconnect, GetAttribute, GetService, WaitForChild
- Constants: `script`, `KeyCode`, `Name`, `GetAttribute`, `Open`, `Disconnect`, `game`, `ReplicatedStorage`, `GetService`, `require`, `UserInputService`, `WaitForChild`, `ServerInfo`, `ClientGameModules`, `GuiHandler`, `Packages`, `Observers`, `isTestGame`, `isMedalServer`, `InputBegan`, `Connect`

### [1093] ReplicatedStorage.Observers.UI.TextAlign
`ModuleScript` · bytecode v9 · 1696 bytes · 39 constants
- **Services:** ReplicatedStorage, game
- **Key API:** Connect, Destroy, GetChildren, GetService, IsA, new
- Constants: `ContentText`, `AbsoluteSize`, `Y`, `tostring`, `Font`, `Vector2`, `new`, `GetTextSize`, `UDim2`, `X`, `Size`, `Scale`, `Offset`, `UpdateSize`, `TextLabel`, `IsA`, `TextBox`, `TextButton`, `Maid`, `GetPropertyChangedSignal`, `Connect`, `GiveTask`, `Validate`, `Destroy`, `pairs`, `GetChildren`, `ChildAdded`, `ChildRemoved`, `game`, `ReplicatedStorage`, `GetService`, `TextService`, `require`, `Packages`, `Observers`, `Common`, `Utils`, `observeTagNoAncestry`, `UI_TextAlign`

### [1094] ReplicatedStorage.Observers.UI.TextBoxContentResizeY
`ModuleScript` · bytecode v9 · 2529 bytes · 53 constants
- **Services:** ReplicatedStorage, game
- **Key API:** Connect, Destroy, GetAttribute, GetService, new
- Constants: `GetTextBoundsAsync`, `ContentText`, `PlaceholderText`, `Text`, `AbsoluteSize`, `X`, `AbsoluteCanvasSize`, `Y`, `ScrollBarThickness`, `Width`, `pcall`, `MaxSize`, `GetAttribute`, `math`, `max`, `UDim2`, `new`, `Size`, `CursorPosition`, `Vector2`, `CanvasPosition`, `updateSize`, `ScrollingFrame`, `FindFirstAncestorWhichIsA`, `TextSize`, `FontFace`, `Font`, `PreloadAsync`, `updateFont`, `Destroy`, `Instance`, `GetTextBoundsParams`, `Archivable`, `GetPropertyChangedSignal`, `Connect`, `Add`, `AncestryChanged`, `task`, `defer`, `game`, `ReplicatedStorage`, `GetService`, `ContentProvider`, `TextService`, `require`, `Packages`, `Trove`, `Observers`, `Common`, `Utils`, `observeTagNoAncestry`, `UI_TextBoxContentResizeY`

### [1095] ReplicatedStorage.Observers.UI.TextContentResize
`ModuleScript` · bytecode v9 · 1080 bytes · 28 constants
- **Services:** ReplicatedStorage, game
- **Key API:** Connect, Destroy, FindFirstChild, GetAttribute, GetService, new
- Constants: `UDim2`, `new`, `AbsoluteContentSize`, `Y`, `CanvasSize`, `UpdateSize`, `Destroy`, `Maid`, `UI_Extra`, `GetAttribute`, `UIListLayout`, `UI_Source`, `FindFirstChild`, `FindFirstChildOfClass`, `UIGridLayout`, `GetPropertyChangedSignal`, `Connect`, `GiveTask`, `game`, `ReplicatedStorage`, `GetService`, `require`, `Packages`, `Observers`, `Common`, `Utils`, `observeTagNoAncestry`, `UI_Scrolling_Y`

### [1096] ReplicatedStorage.Observers.UI.TextHoverReveal
`ModuleScript` · bytecode v9 · 1203 bytes · 23 constants
- **Services:** ReplicatedStorage, game
- **Key API:** Connect, Disconnect, GetAttribute, GetService
- Constants: `TextPreview`, `GetAttribute`, `TextReveal`, `%s`, `RevealFormat`, `format`, `Text`, `update`, `Disconnect`, `next`, `MouseEnter`, `Connect`, `MouseLeave`, `GetAttributeChangedSignal`, `game`, `ReplicatedStorage`, `GetService`, `require`, `Packages`, `Observers`, `observeTagNoAncestry`, `TextHoverReveal`

### [1097] ReplicatedStorage.Observers.UI.TouchWindow
`ModuleScript` · bytecode v9 · 1080 bytes · 28 constants
- **Services:** ReplicatedStorage, game
- **Key API:** Connect, Destroy, FindFirstChild, GetAttribute, GetService, new
- Constants: `UDim2`, `new`, `AbsoluteContentSize`, `Y`, `CanvasSize`, `UpdateSize`, `Destroy`, `Maid`, `UI_Extra`, `GetAttribute`, `UIListLayout`, `UI_Source`, `FindFirstChild`, `FindFirstChildOfClass`, `UIGridLayout`, `GetPropertyChangedSignal`, `Connect`, `GiveTask`, `game`, `ReplicatedStorage`, `GetService`, `require`, `Packages`, `Observers`, `Common`, `Utils`, `observeTagNoAncestry`, `UI_Scrolling_Y`

### [1098] ReplicatedStorage.Observers.UI.UpdateBoard
`ModuleScript` · bytecode v9 · 6378 bytes · 122 constants
- **Remotes:** Data
- **Services:** Players, ReplicatedStorage, game
- **Key API:** Clone, Connect, Destroy, Fire, GetDescendants, GetService, IsA, SetAttribute, WaitForChild, new
- Constants: `GetDescendants`, `BasePart`, `IsA`, `Transparency`, `CanCollide`, `setPartsHidden`, `captureOriginalParts`, `Color3`, `new`, `BackgroundColor3`, `UIStroke`, `ColorConfig`, `SlowChroma`, `SetAttribute`, `TweenColor`, `AddTag`, `Glow`, `applyRainbow`, `???%`, `math`, `floor`, `tostring`, `%`, `formatChanceText`, `Stock`, `LimitedStockRewardId`, `Get`, `MainFrame`, `%* Left`, `ValueConvertor`, `AddCommas`, `format`, `Text`, `updateStock`, `Contents`, `Reward`, `Value`, `Loaded`, `InitialStock`, `Chance`, `Clone`, `Item`, `Name`, `Visible`, `LayoutOrder`, `Icon`, `Image`, `Rarity`, `CustomTierColor`, `R`, `G`, `B`, `ImageColor3`, `BillboardGui`, `Rewards`, `Parent`, `OnChange`, `createRewardFramesForCrate`, `Network`, `ClaimUpdateGift`, `Fire`, `CurrentCrate`, `UpdateCrate`, `Crates`, `Enabled`, `ProximityPrompt`, `Owned`, `Owned: %*`, `updateAmount`, `os`, `time`, `Settings`, `UPDATE_RELEASE_TIME`, `Content`, `TimerLabel`, `UPDATE IN 
`, `FormatTimeWithDaysFull`, `UPDATING...
Thanks for waiting <3`, `Active`, `Destroy`, `onUpdateGiftChanged`, `Maid`, `Thread`, `Every`, `TimerUpdate`, `UpdateGift`, `OnUpdateGiftChanged`, `PlayerGui`, `Crate`, `WaitForChild`, `ItemFrame`, `Triggered`, `Connect`, `task`, `wait`, `Client`, `Data`, `AwaitReplion`, `game`, `Players`, `GetService`, `ReplicatedStorage`, `LocalPlayer`, `Packages`, `Shared`, `require`, `Observers`, `Common`, `Utils`, `UpdateGiftRewards`, `Replion`, `ReplicatedInstances`, `Swords`, `@game/ReplicatedStorage/Types/Templates/Lobbies`, `MIN_TIME_TO_SHOW`, `MIN_TIME_FOR_UPDATE`, `TIME_TO_UNLOCK_UPDATE_GIFT`, `TIME_TO_CLAIM_UPDATE_GIFT`, `LimitedStockItems`, `WaitReplion`, `observeTagNoAncestry`, `UI_UpdateBoard`

### [1099] ReplicatedStorage.Observers.UI.WigglyWiggly
`ModuleScript` · bytecode v9 · 1186 bytes · 29 constants
- **Services:** ReplicatedStorage, RunService, game
- **Key API:** Connect, Destroy, GetService, new
- Constants: `next`, `os`, `clock`, `math`, `sin`, `pairs`, `Rotation`, `GuiUtils`, `IsGuiObjectVisible`, `Destroy`, `Maid`, `new`, `Visible`, `GetPropertyChangedSignal`, `Connect`, `GiveTask`, `Remove`, `game`, `ReplicatedStorage`, `GetService`, `RunService`, `require`, `Packages`, `Observers`, `Common`, `Utils`, `Heartbeat`, `observeTagNoAncestry`, `UI_WigglyWiggly`

### [1100] ReplicatedStorage.Observers.UI.WindowWeeklySpins
`ModuleScript` · bytecode v9 · 2808 bytes · 66 constants
- **Remotes:** Data
- **Services:** ReplicatedStorage, game
- **Key API:** Connect, Destroy, Fire, GetChildren, GetService, IsA, new
- Constants: `WeeklySpins`, `Get`, `pairs`, `Bar`, `List`, `GetChildren`, `Frame`, `IsA`, `Name`, `tonumber`, `Button`, `ClaimNow`, `Visible`, `UpdateAvailableRewards`, `TotalWeeklySpinsAmount`, `Total Weekly Spins: `, `Text`, `ValueConvertor`, `GetPercentageFromNumbers`, `BarProgress`, `UDim2`, `new`, `Size`, `WeeklySpinsRewardTier`, `UpdateWeeklyRolls`, `LayerCollector`, `FindFirstAncestorWhichIsA`, `Enabled`, `ResetTimer`, `Settings`, `WEEK_TIME`, `os`, `time`, `WEEKLY_SPIN_START`, `FormatTimeWithDays`, `Network`, `ClaimWeeklySpinReward`, `Fire`, `OnChange`, `OnWeeklySpinsChanged`, `WeeklySpinsID`, `OnWeeklySpinsIDChanged`, `OnWeeklySpinsRewardTierChanged`, `Thread`, `Every`, `Reset`, `Activated`, `Connect`, `GiveTask`, `Destroy`, `Maid`, `Client`, `Data`, `AwaitReplion`, `OnDataLoaded`, `game`, `ReplicatedStorage`, `GetService`, `require`, `Packages`, `Observers`, `Common`, `Utils`, `Replion`, `observeTagNoAncestry`, `UI_WindowWeeklySpins`

### [1101] ReplicatedStorage.Packages.Charm
`ModuleScript` · bytecode v9 · 14663 bytes · 97 constants
- Constants: `debug`, `info`, `n`, `isO2`, `type`, `string`, `error`, `traceback`, `tostring`, `coroutine`, `status`, `dead`, `Attempted to yield in an effect or scope`, `create`, `resume`, `strict`, `s`, `wrapUserSpace`, `table`, `isfrozen`, `getmetatable`, `freeze`, `deepFreeze`, `getActiveSub`, `setActiveSub`, `depsTail`, `nextDep`, `deps`, `purgeDeps`, `pcall`, `insert`, `Errors occurred during effect cleanup:

%*`, `concat`, `format`, `runCleanups`, `flags`, `bit32`, `btest`, `cleanups`, `fn`, `run`, `bor`, `flush`, `startBatch`, `endBatch`, `value`, `getter`, `band`, `updateComputed`, `pendingValue`, `currentValue`, `updateSignal`, `subs`, `stopEffect`, `update`, `sub`, `notify`, `unwatched`, `signalGetter`, `function`, `frozen`, `signalSetter`, `signal`, `#`, `select`, `atomOper`, `atom`, `computedOper`, `computed`, `trackInnerEffects`, `effect`, `effectScope`, `dep`, `trigger`, `warn`, `onCleanup() can only be called inside an effect or a scope.`, `onCleanup`, `unpack`, `untracked`, `batch`, `isSignal`, `listen`, `subscribe`, `updateScopes`, `observe`, `clone`, `mapped`, `require`, `@self/system`, `link`, `unlink`, `propagate`, `checkDirty`, `shallowPropagate`, `createReactiveSystem`, `ReactiveFlags`

### [1102] ReplicatedStorage.Packages.Charm.system
`ModuleScript` · bytecode v9 · 3101 bytes · 33 constants
- Constants: `depsTail`, `prevDep`, `isValidLink`, `dep`, `nextDep`, `deps`, `version`, `subsTail`, `sub`, `prevSub`, `nextSub`, `subs`, `link`, `unlink`, `flags`, `bit32`, `band`, `bor`, `btest`, `propagate`, `shallowPropagate`, `checkDirty`, `createReactiveSystem`, `table`, `freeze`, `None`, `Mutable`, `Watching`, `RecursedCheck`, `Recursed`, `Dirty`, `Pending`, `ReactiveFlags`

### [1103] ReplicatedStorage.Packages.Chroma
`ModuleScript` · bytecode v9 · 4292 bytes · 55 constants
- **Key API:** WaitForChild
- Constants: `require`, `script`, `chroma`, `WaitForChild`, `io`, `cmyk`, `css`, `gl`, `hcg`, `hex`, `hsi`, `hsl`, `hsv`, `lab`, `lch`, `named`, `num`, `rgb`, `temp`, `oklab`, `oklch`, `roblox`, `ops`, `alpha`, `clipped`, `darken`, `get`, `luminance`, `mix`, `premultiply`, `saturate`, `set`, `interpolator`, `lrgb`, `generator`, `average`, `bezier`, `blend`, `cubehelix`, `interpolate`, `random`, `scale`, `utils`, `analyze`, `contrast`, `delta-e`, `deltaE`, `distance`, `limits`, `valid`, `scales`, `colors`, `w3cx11`, `colorbrewer`, `brewer`

### [1104] ReplicatedStorage.Packages.Chroma.Color
`ModuleScript` · bytecode v9 · 1734 bytes · 39 constants
- **Key API:** WaitForChild, new
- Constants: `toString`, `__tostring`, `p`, `setmetatable`, `table`, `pack`, `type`, `getmetatable`, `sorted`, `sort`, `autodetect`, `test`, `format`, `n`, `unpack`, `_rgb`, `tostring`, `{ `, `concat`, `, `, ` }`, `error`, `unknown format: %*`, `insert`, `new`, `hex`, `require`, `script`, `Parent`, `types`, `WaitForChild`, `color-types`, `utils`, `last`, `clip_rgb`, `io`, `input`, `__index`

### [1105] ReplicatedStorage.Packages.Chroma.chroma
`ModuleScript` · bytecode v9 · 936 bytes · 18 constants
- **Key API:** WaitForChild, new
- Constants: `Color`, `new`, `__call`, `require`, `script`, `Parent`, `types`, `WaitForChild`, `blend-types`, `brewer-types`, `cubehelix-types`, `interpolation-mode`, `scale-types`, `utils`, `analyze`, `setmetatable`, `2.4.2`, `version`

### [1106] ReplicatedStorage.Packages.Chroma.colors.colorbrewer
`ModuleScript` · bytecode v9 · 6481 bytes · 340 constants
- Constants: `#fff7ec`, `#fee8c8`, `#fdd49e`, `#fdbb84`, `#fc8d59`, `#ef6548`, `#d7301f`, `#b30000`, `#7f0000`, `OrRd`, `#fff7fb`, `#ece7f2`, `#d0d1e6`, `#a6bddb`, `#74a9cf`, `#3690c0`, `#0570b0`, `#045a8d`, `#023858`, `PuBu`, `#f7fcfd`, `#e0ecf4`, `#bfd3e6`, `#9ebcda`, `#8c96c6`, `#8c6bb1`, `#88419d`, `#810f7c`, `#4d004b`, `BuPu`, `#fff5eb`, `#fee6ce`, `#fdd0a2`, `#fdae6b`, `#fd8d3c`, `#f16913`, `#d94801`, `#a63603`, `#7f2704`, `Oranges`, `#e5f5f9`, `#ccece6`, `#99d8c9`, `#66c2a4`, `#41ae76`, `#238b45`, `#006d2c`, `#00441b`, `BuGn`, `#ffffe5`, `#fff7bc`, `#fee391`, `#fec44f`, `#fe9929`, `#ec7014`, `#cc4c02`, `#993404`, `#662506`, `YlOrBr`, `#f7fcb9`, `#d9f0a3`, `#addd8e`, `#78c679`, `#41ab5d`, `#238443`, `#006837`, `#004529`, `YlGn`, `#fff5f0`, `#fee0d2`, `#fcbba1`, `#fc9272`, `#fb6a4a`, `#ef3b2c`, `#cb181d`, `#a50f15`, `#67000d`, `Reds`, `#fff7f3`, `#fde0dd`, `#fcc5c0`, `#fa9fb5`, `#f768a1`, `#dd3497`, `#ae017e`, `#7a0177`, `#49006a`, `RdPu`, `#f7fcf5`, `#e5f5e0`, `#c7e9c0`, `#a1d99b`, `#74c476`, `Greens`, `#ffffd9`, `#edf8b1`, `#c7e9b4`, `#7fcdbb`, `#41b6c4`, `#1d91c0`, `#225ea8`, `#253494`, `#081d58`, `YlGnBu`, `#fcfbfd`, `#efedf5`, `#dadaeb`, `#bcbddc`, `#9e9ac8`, `#807dba`, `#6a51a3`, `#54278f`, `#3f007d`, `Purples`, `#f7fcf0`, `#e0f3db`, `#ccebc5`, `#a8ddb5`, `#7bccc4`, `#4eb3d3`, `#2b8cbe`, `#0868ac`, `#084081`, `GnBu`, `#ffffff`, `#f0f0f0`, `#d9d9d9`, `#bdbdbd`, `#969696`, `#737373`, `#525252`, `#252525`, `#000000`, `Greys`, `#ffffcc`, `#ffeda0`, `#fed976`, `#feb24c`, `#fc4e2a`, `#e31a1c`, `#bd0026`, `#800026`, `YlOrRd`, `#f7f4f9`, `#e7e1ef`, `#d4b9da`, `#c994c7`, `#df65b0`, `#e7298a`, `#ce1256`, `#980043`, `#67001f`, `PuRd`, `#f7fbff`, `#deebf7`, `#c6dbef`, `#9ecae1`, `#6baed6`, `#4292c6`, `#2171b5`, `#08519c`, `#08306b`, `Blues`, `#ece2f0`, `#67a9cf`, `#02818a`, `#016c59`, `#014636`, `PuBuGn`, `#440154`, `#482777`, `#3f4a8a`, `#31678e`, `#26838f`, `#1f9d8a`, `#6cce5a`, `#b6de2b`, `#fee825`, `Viridis`, `#9e0142`, `#d53e4f`, `#f46d43`, `#fdae61`, `#fee08b`, `#ffffbf`, `#e6f598`, `#abdda4`, `#66c2a5`, `#3288bd`, `#5e4fa2`, `Spectral`, `#a50026`, `#d73027`, `#d9ef8b`, `#a6d96a`, `#66bd63`, `#1a9850`, `RdYlGn`, `#b2182b`, `#d6604d`, `#f4a582`, `#fddbc7`, `#f7f7f7`, `#d1e5f0`, `#92c5de`, `#4393c3`, `#2166ac`, `#053061`, `RdBu`, `#8e0152`, `#c51b7d`, `#de77ae`, `#f1b6da`, `#fde0ef`, `#e6f5d0`, `#b8e186`, `#7fbc41`, `#4d9221`, `#276419`, `PiYG`, `#40004b`, `#762a83`, `#9970ab`, `#c2a5cf`, `#e7d4e8`, `#d9f0d3`, `#a6dba0`, `#5aae61`, `#1b7837`, `PRGn`, `#fee090`, `#e0f3f8`, `#abd9e9`, `#74add1`, `#4575b4`, `#313695`, `RdYlBu`, `#543005`, `#8c510a`, `#bf812d`, `#dfc27d`, `#f6e8c3`, `#f5f5f5`, `#c7eae5`, `#80cdc1`, `#35978f`, `#01665e`, `#003c30`, `BrBG`, `#e0e0e0`, `#bababa`, `#878787`, `#4d4d4d`, `#1a1a1a`, `RdGy`, `#7f3b08`, `#b35806`, `#e08214`, `#fdb863`, `#fee0b6`, `#d8daeb`, `#b2abd2`, `#8073ac`, `#542788`, `#2d004b`, `PuOr`, `#fc8d62`, `#8da0cb`, `#e78ac3`, `#a6d854`, `#ffd92f`, `#e5c494`, `#b3b3b3`, `Set2`, `#7fc97f`, `#beaed4`, `#fdc086`, `#ffff99`, `#386cb0`, `#f0027f`, `#bf5b17`, `#666666`, `Accent`, `#e41a1c`, `#377eb8`, `#4daf4a`, `#984ea3`, `#ff7f00`, `#ffff33`, `#a65628`, `#f781bf`, `#999999`, `Set1`, `#8dd3c7`, `#ffffb3`, `#bebada`, `#fb8072`, `#80b1d3`, `#fdb462`, `#b3de69`, `#fccde5`, `#bc80bd`, `#ffed6f`, `Set3`, `#1b9e77`, `#d95f02`, `#7570b3`, `#66a61e`, `#e6ab02`, `#a6761d`, `Dark2`, `#a6cee3`, `#1f78b4`, `#b2df8a`, `#33a02c`, `#fb9a99`, `#fdbf6f`, `#cab2d6`, `#6a3d9a`, `#b15928`, `Paired`, `#b3e2cd`, `#fdcdac`, `#cbd5e8`, `#f4cae4`, `#e6f5c9`, `#fff2ae`, `#f1e2cc`, `#cccccc`, `Pastel2`, `#fbb4ae`, `#b3cde3`, `#decbe4`, `#fed9a6`, `#e5d8bd`, `#fddaec`, `#f2f2f2`, `Pastel1`, `string`, `lower`

### [1107] ReplicatedStorage.Packages.Chroma.colors.w3cx11
`ModuleScript` · bytecode v9 · 5857 bytes · 299 constants
- Constants: `#f0f8ff`, `aliceblue`, `#faebd7`, `antiquewhite`, `#00ffff`, `aqua`, `#7fffd4`, `aquamarine`, `#f0ffff`, `azure`, `#f5f5dc`, `beige`, `#ffe4c4`, `bisque`, `#000000`, `black`, `#ffebcd`, `blanchedalmond`, `#0000ff`, `blue`, `#8a2be2`, `blueviolet`, `#a52a2a`, `brown`, `#deb887`, `burlywood`, `#5f9ea0`, `cadetblue`, `#7fff00`, `chartreuse`, `#d2691e`, `chocolate`, `#ff7f50`, `coral`, `#6495ed`, `cornflower`, `cornflowerblue`, `#fff8dc`, `cornsilk`, `#dc143c`, `crimson`, `cyan`, `#00008b`, `darkblue`, `#008b8b`, `darkcyan`, `#b8860b`, `darkgoldenrod`, `#a9a9a9`, `darkgray`, `#006400`, `darkgreen`, `darkgrey`, `#bdb76b`, `darkkhaki`, `#8b008b`, `darkmagenta`, `#556b2f`, `darkolivegreen`, `#ff8c00`, `darkorange`, `#9932cc`, `darkorchid`, `#8b0000`, `darkred`, `#e9967a`, `darksalmon`, `#8fbc8f`, `darkseagreen`, `#483d8b`, `darkslateblue`, `#2f4f4f`, `darkslategray`, `darkslategrey`, `#00ced1`, `darkturquoise`, `#9400d3`, `darkviolet`, `#ff1493`, `deeppink`, `#00bfff`, `deepskyblue`, `#696969`, `dimgray`, `dimgrey`, `#1e90ff`, `dodgerblue`, `#b22222`, `firebrick`, `#fffaf0`, `floralwhite`, `#228b22`, `forestgreen`, `#ff00ff`, `fuchsia`, `#dcdcdc`, `gainsboro`, `#f8f8ff`, `ghostwhite`, `#ffd700`, `gold`, `#daa520`, `goldenrod`, `#808080`, `gray`, `#008000`, `green`, `#adff2f`, `greenyellow`, `grey`, `#f0fff0`, `honeydew`, `#ff69b4`, `hotpink`, `#cd5c5c`, `indianred`, `#4b0082`, `indigo`, `#fffff0`, `ivory`, `#f0e68c`, `khaki`, `#ffff54`, `laserlemon`, `#e6e6fa`, `lavender`, `#fff0f5`, `lavenderblush`, `#7cfc00`, `lawngreen`, `#fffacd`, `lemonchiffon`, `#add8e6`, `lightblue`, `#f08080`, `lightcoral`, `#e0ffff`, `lightcyan`, `#fafad2`, `lightgoldenrod`, `lightgoldenrodyellow`, `#d3d3d3`, `lightgray`, `#90ee90`, `lightgreen`, `lightgrey`, `#ffb6c1`, `lightpink`, `#ffa07a`, `lightsalmon`, `#20b2aa`, `lightseagreen`, `#87cefa`, `lightskyblue`, `#778899`, `lightslategray`, `lightslategrey`, `#b0c4de`, `lightsteelblue`, `#ffffe0`, `lightyellow`, `#00ff00`, `lime`, `#32cd32`, `limegreen`, `#faf0e6`, `linen`, `magenta`, `#800000`, `maroon`, `#7f0000`, `maroon2`, `#b03060`, `maroon3`, `#66cdaa`, `mediumaquamarine`, `#0000cd`, `mediumblue`, `#ba55d3`, `mediumorchid`, `#9370db`, `mediumpurple`, `#3cb371`, `mediumseagreen`, `#7b68ee`, `mediumslateblue`, `#00fa9a`, `mediumspringgreen`, `#48d1cc`, `mediumturquoise`, `#c71585`, `mediumvioletred`, `#191970`, `midnightblue`, `#f5fffa`, `mintcream`, `#ffe4e1`, `mistyrose`, `#ffe4b5`, `moccasin`, `#ffdead`, `navajowhite`, `#000080`, `navy`, `#fdf5e6`, `oldlace`, `#808000`, `olive`, `#6b8e23`, `olivedrab`, `#ffa500`, `orange`, `#ff4500`, `orangered`, `#da70d6`, `orchid`, `#eee8aa`, `palegoldenrod`, `#98fb98`, `palegreen`, `#afeeee`, `paleturquoise`, `#db7093`, `palevioletred`, `#ffefd5`, `papayawhip`, `#ffdab9`, `peachpuff`, `#cd853f`, `peru`, `#ffc0cb`, `pink`, `#dda0dd`, `plum`, `#b0e0e6`, `powderblue`, `#800080`, `purple`, `#7f007f`, `purple2`, `#a020f0`, `purple3`, `#663399`, `rebeccapurple`, `#ff0000`, `red`, `#bc8f8f`, `rosybrown`, `#4169e1`, `royalblue`, `#8b4513`, `saddlebrown`, `#fa8072`, `salmon`, `#f4a460`, `sandybrown`, `#2e8b57`, `seagreen`, `#fff5ee`, `seashell`, `#a0522d`, `sienna`, `#c0c0c0`, `silver`, `#87ceeb`, `skyblue`, `#6a5acd`, `slateblue`, `#708090`, `slategray`, `slategrey`, `#fffafa`, `snow`, `#00ff7f`, `springgreen`, `#4682b4`, `steelblue`, `#d2b48c`, `tan`, `#008080`, `teal`, `#d8bfd8`, `thistle`, `#ff6347`, `tomato`, `#40e0d0`, `turquoise`, `#ee82ee`, `violet`, `#f5deb3`, `wheat`, `#ffffff`, `white`, `#f5f5f5`, `whitesmoke`, `#ffff00`, `yellow`, `#9acd32`, `yellowgreen`

### [1108] ReplicatedStorage.Packages.Chroma.generator.average
`ModuleScript` · bytecode v9 · 2870 bytes · 36 constants
- **Key API:** WaitForChild, new
- Constants: `new`, `lrgb`, `table`, `create`, `reduce`, `map`, `remove`, `get`, `isNaN`, `insert`, `string`, `sub`, `h`, `alpha`, `average`, `_rgb`, `_average_lrgb`, `require`, `script`, `Parent`, `node_modules`, `WaitForChild`, `.luau-aliases`, `@jsdotlua`, `collections`, `number`, `Color`, `utils`, `clip_rgb`, `Array`, `math`, `pow`, `sqrt`, `cos`, `sin`, `atan2`

### [1109] ReplicatedStorage.Packages.Chroma.generator.bezier
`ModuleScript` · bytecode v9 · 3214 bytes · 23 constants
- **Key API:** WaitForChild, new
- Constants: `binom_row`, `new`, `lab`, `map`, `I`, `reduce`, `error`, `No point in running bezier with only one color.`, `bezier`, `__call`, `setmetatable`, `scale`, `require`, `script`, `Parent`, `node_modules`, `WaitForChild`, `.luau-aliases`, `@jsdotlua`, `collections`, `Array`, `Color`, `io`

### [1110] ReplicatedStorage.Packages.Chroma.generator.blend
`ModuleScript` · bytecode v9 · 2003 bytes · 25 constants
- **Key API:** WaitForChild
- Constants: `error`, `unknown blend mode %*`, `format`, `blendFn`, `rgb`, `blend_f`, `each`, `normal`, `multiply`, `darken`, `lighten`, `screen`, `overlay`, `burn`, `dodge`, `require`, `script`, `Parent`, `io`, `WaitForChild`, `types`, `blend-types`, `chroma`, `__call`, `setmetatable`

### [1111] ReplicatedStorage.Packages.Chroma.generator.cubehelix
`ModuleScript` · bytecode v9 · 2276 bytes · 26 constants
- **Key API:** WaitForChild
- Constants: `callF`, `start`, `rotations`, `gamma`, `type`, `table`, `hue`, `lightness`, `scale`, `__call`, `setmetatable`, `cubehelix`, `require`, `script`, `Parent`, `types`, `WaitForChild`, `cubehelix-types`, `chroma`, `utils`, `clip_rgb`, `TWOPI`, `math`, `pow`, `sin`, `cos`

### [1112] ReplicatedStorage.Packages.Chroma.generator.mix
`ModuleScript` · bytecode v9 · 781 bytes · 16 constants
- **Key API:** WaitForChild, new
- Constants: `lrgb`, `error`, `interpolation mode %* is not defined`, `format`, `new`, `alpha`, `mix`, `require`, `script`, `Parent`, `Color`, `WaitForChild`, `types`, `interpolation-mode`, `interpolator`

### [1113] ReplicatedStorage.Packages.Chroma.generator.random
`ModuleScript` · bytecode v9 · 540 bytes · 18 constants
- **Key API:** WaitForChild, new
- Constants: `table`, `create`, `math`, `random`, `new`, `#%*`, `concat`, `format`, `hex`, `require`, `script`, `Parent`, `Color`, `WaitForChild`, `string`, `split`, `0123456789abcdef`

### [1114] ReplicatedStorage.Packages.Chroma.generator.scale
`ModuleScript` · bytecode v9 · 7880 bytes · 69 constants
- **Key API:** WaitForChild
- Constants: `type`, `table`, `getmetatable`, `__call`, `function`, `isCallable`, `#fff`, `#000`, `string`, `brewer`, `lower`, `clone`, `insert`, `setColors`, `getClass`, `tMapLightness`, `tMapDomain`, `isNaN`, `math`, `max`, `min`, `floor`, `interpolate`, `getColor`, `resetCache`, `callF`, `analyze`, `limits`, `e`, `classes`, `map`, `every`, `domain`, `mode`, `range`, `out`, `spread`, `lab`, `abs`, `correctLightness`, `number`, `padding`, `#`, `select`, `hex`, `colors`, `cache`, `gamma`, `nodata`, `rgb`, `#ccc`, `setmetatable`, `scale`, `__range__`, `require`, `script`, `Parent`, `node_modules`, `WaitForChild`, `.luau-aliases`, `@jsdotlua`, `collections`, `Array`, `types`, `brewer-types`, `scale-types`, `chroma`, `pow`

### [1115] ReplicatedStorage.Packages.Chroma.interpolator
`ModuleScript` · bytecode v9 · 160 bytes · 5 constants
- **Key API:** WaitForChild
- Constants: `require`, `script`, `Parent`, `Color`, `WaitForChild`

### [1116] ReplicatedStorage.Packages.Chroma.interpolator._hsx
`ModuleScript` · bytecode v9 · 1846 bytes · 28 constants
- **Key API:** WaitForChild, new
- Constants: `hsl`, `hsv`, `hcg`, `hsi`, `lch`, `hcl`, `oklch`, `reverse`, `string`, `sub`, `h`, `table`, `unpack`, `isNaN`, `NaN`, `new`, `_hsx`, `require`, `script`, `Parent`, `node_modules`, `WaitForChild`, `.luau-aliases`, `@jsdotlua`, `collections`, `number`, `Array`, `Color`

### [1117] ReplicatedStorage.Packages.Chroma.interpolator.hcg
`ModuleScript` · bytecode v9 · 463 bytes · 8 constants
- **Key API:** WaitForChild
- Constants: `hcg`, `require`, `script`, `Parent`, `io`, `WaitForChild`, `Color`, `_hsx`

### [1118] ReplicatedStorage.Packages.Chroma.interpolator.hsi
`ModuleScript` · bytecode v9 · 463 bytes · 8 constants
- **Key API:** WaitForChild
- Constants: `hsi`, `require`, `script`, `Parent`, `io`, `WaitForChild`, `Color`, `_hsx`

### [1119] ReplicatedStorage.Packages.Chroma.interpolator.hsl
`ModuleScript` · bytecode v9 · 463 bytes · 8 constants
- **Key API:** WaitForChild
- Constants: `hsl`, `require`, `script`, `Parent`, `io`, `WaitForChild`, `Color`, `_hsx`

### [1120] ReplicatedStorage.Packages.Chroma.interpolator.hsv
`ModuleScript` · bytecode v9 · 463 bytes · 8 constants
- **Key API:** WaitForChild
- Constants: `hsv`, `require`, `script`, `Parent`, `io`, `WaitForChild`, `Color`, `_hsx`

### [1121] ReplicatedStorage.Packages.Chroma.interpolator.lab
`ModuleScript` · bytecode v9 · 522 bytes · 8 constants
- **Key API:** WaitForChild, new
- Constants: `lab`, `new`, `require`, `script`, `Parent`, `io`, `WaitForChild`, `Color`

### [1122] ReplicatedStorage.Packages.Chroma.interpolator.lch
`ModuleScript` · bytecode v9 · 514 bytes · 9 constants
- **Key API:** WaitForChild
- Constants: `lch`, `require`, `script`, `Parent`, `io`, `WaitForChild`, `Color`, `_hsx`, `hcl`

### [1123] ReplicatedStorage.Packages.Chroma.interpolator.lrgb
`ModuleScript` · bytecode v9 · 789 bytes · 14 constants
- **Key API:** WaitForChild, new
- Constants: `_rgb`, `table`, `unpack`, `new`, `rgb`, `lrgb`, `require`, `script`, `Parent`, `Color`, `WaitForChild`, `math`, `sqrt`, `pow`

### [1124] ReplicatedStorage.Packages.Chroma.interpolator.num
`ModuleScript` · bytecode v9 · 447 bytes · 8 constants
- **Key API:** WaitForChild, new
- Constants: `num`, `new`, `require`, `script`, `Parent`, `io`, `WaitForChild`, `Color`

### [1125] ReplicatedStorage.Packages.Chroma.interpolator.oklab
`ModuleScript` · bytecode v9 · 524 bytes · 8 constants
- **Key API:** WaitForChild, new
- Constants: `oklab`, `new`, `require`, `script`, `Parent`, `io`, `WaitForChild`, `Color`

### [1126] ReplicatedStorage.Packages.Chroma.interpolator.oklch
`ModuleScript` · bytecode v9 · 471 bytes · 9 constants
- **Key API:** WaitForChild
- Constants: `oklch`, `require`, `script`, `Parent`, `io`, `WaitForChild`, `lch`, `Color`, `_hsx`

### [1127] ReplicatedStorage.Packages.Chroma.interpolator.rgb
`ModuleScript` · bytecode v9 · 429 bytes · 8 constants
- **Key API:** WaitForChild, new
- Constants: `_rgb`, `new`, `rgb`, `require`, `script`, `Parent`, `Color`, `WaitForChild`

### [1128] ReplicatedStorage.Packages.Chroma.io.cmyk
`ModuleScript` · bytecode v9 · 1137 bytes · 23 constants
- **Key API:** WaitForChild, new
- Constants: `_rgb`, `cmyk`, `table`, `pack`, `n`, `new`, `unpack`, `type`, `test`, `require`, `script`, `Parent`, `Color`, `WaitForChild`, `chroma`, `input`, `rgb2cmyk`, `utils`, `format`, `cmyk2rgb`, `autodetect`, `p`, `insert`

### [1129] ReplicatedStorage.Packages.Chroma.io.cmyk.cmyk2rgb
`ModuleScript` · bytecode v9 · 646 bytes · 10 constants
- **Key API:** WaitForChild
- Constants: `table`, `pack`, `cmyk`, `unpack`, `cmyk2rgb`, `require`, `script`, `Parent`, `utils`, `WaitForChild`

### [1130] ReplicatedStorage.Packages.Chroma.io.cmyk.rgb2cmyk
`ModuleScript` · bytecode v9 · 617 bytes · 12 constants
- **Key API:** WaitForChild
- Constants: `table`, `pack`, `rgb`, `unpack`, `rgb2cmyk`, `require`, `script`, `Parent`, `utils`, `WaitForChild`, `math`, `max`

### [1131] ReplicatedStorage.Packages.Chroma.io.css
`ModuleScript` · bytecode v9 · 1111 bytes · 25 constants
- **Key API:** WaitForChild, new
- Constants: `_rgb`, `css`, `table`, `pack`, `n`, `new`, `unpack`, `#`, `select`, `type`, `string`, `test`, `require`, `script`, `Parent`, `Color`, `WaitForChild`, `chroma`, `css2rgb`, `input`, `rgb2css`, `format`, `autodetect`, `p`, `insert`

### [1132] ReplicatedStorage.Packages.Chroma.io.css.css2rgb
`ModuleScript` · bytecode v9 · 3108 bytes · 30 constants
- **Key API:** WaitForChild
- Constants: `trim`, `string`, `lower`, `format`, `named`, `pcall`, `exec`, `tonumber`, `css2rgb`, `test`, `css2rgbTest`, `require`, `script`, `Parent`, `node_modules`, `WaitForChild`, `.luau-aliases`, `luau-regexp`, `@jsdotlua`, `hsl`, `hsl2rgb`, `input`, `^rgb\(\s*(-?\d+),\s*(-?\d+)\s*,\s*(-?\d+)\s*\)$`, `^rgba\(\s*(-?\d+),\s*(-?\d+)\s*,\s*(-?\d+)\s*,\s*([01]|[01]?\.\d+)\)$`, `^rgb\(\s*(-?\d+(?:\.\d+)?)%,\s*(-?\d+(?:\.\d+)?)%\s*,\s*(-?\d+(?:\.\d+)?)%\s*\)$`, `^rgba\(\s*(-?\d+(?:\.\d+)?)%,\s*(-?\d+(?:\.\d+)?)%\s*,\s*(-?\d+(?:\.\d+)?)%\s*,\s*([01]|[01]?\.\d+)\)$`, `^hsl\(\s*(-?\d+(?:\.\d+)?),\s*(-?\d+(?:\.\d+)?)%\s*,\s*(-?\d+(?:\.\d+)?)%\s*\)$`, `^hsla\(\s*(-?\d+(?:\.\d+)?),\s*(-?\d+(?:\.\d+)?)%\s*,\s*(-?\d+(?:\.\d+)?)%\s*,\s*([01]|[01]?\.\d+)\)$`, `math`, `round`

### [1133] ReplicatedStorage.Packages.Chroma.io.css.hsl2css
`ModuleScript` · bytecode v9 · 1209 bytes · 27 constants
- **Key API:** WaitForChild
- Constants: `math`, `round`, `rnd`, `table`, `pack`, `hsla`, `lsa`, `isNaN`, `tostring`, `%`, `%*(%*)`, `concat`, `,`, `format`, `hsl2css`, `require`, `script`, `Parent`, `node_modules`, `WaitForChild`, `.luau-aliases`, `@jsdotlua`, `number`, `utils`, `unpack`, `last`

### [1134] ReplicatedStorage.Packages.Chroma.io.css.rgb2css
`ModuleScript` · bytecode v9 · 1145 bytes · 24 constants
- **Key API:** WaitForChild
- Constants: `table`, `pack`, `rgba`, `rgb`, `string`, `sub`, `hsl`, `tostring`, `%*(%*)`, `concat`, `,`, `format`, `rgb2css`, `require`, `script`, `Parent`, `hsl2css`, `WaitForChild`, `utils`, `round.roblox`, `rgb2hsl`, `unpack`, `last`

### [1135] ReplicatedStorage.Packages.Chroma.io.gl
`ModuleScript` · bytecode v9 · 934 bytes · 17 constants
- **Key API:** WaitForChild, new
- Constants: `table`, `pack`, `rgba`, `n`, `gl`, `new`, `unpack`, `_rgb`, `require`, `script`, `Parent`, `Color`, `WaitForChild`, `chroma`, `input`, `utils`, `format`

### [1136] ReplicatedStorage.Packages.Chroma.io.hcg
`ModuleScript` · bytecode v9 · 1134 bytes · 23 constants
- **Key API:** WaitForChild, new
- Constants: `_rgb`, `hcg`, `table`, `pack`, `n`, `new`, `unpack`, `type`, `test`, `require`, `script`, `Parent`, `Color`, `WaitForChild`, `chroma`, `input`, `rgb2hcg`, `utils`, `format`, `hcg2rgb`, `autodetect`, `p`, `insert`

### [1137] ReplicatedStorage.Packages.Chroma.io.hcg.hcg2rgb
`ModuleScript` · bytecode v9 · 911 bytes · 12 constants
- **Key API:** WaitForChild
- Constants: `table`, `pack`, `hcg`, `unpack`, `hcg2rgb`, `require`, `script`, `Parent`, `utils`, `WaitForChild`, `math`, `floor`

### [1138] ReplicatedStorage.Packages.Chroma.io.hcg.rgb2hcg
`ModuleScript` · bytecode v9 · 927 bytes · 18 constants
- **Key API:** WaitForChild
- Constants: `table`, `pack`, `rgb`, `unpack`, `math`, `min`, `max`, `NaN`, `rgb2hcg`, `require`, `script`, `Parent`, `node_modules`, `WaitForChild`, `.luau-aliases`, `@jsdotlua`, `number`, `utils`

### [1139] ReplicatedStorage.Packages.Chroma.io.hex
`ModuleScript` · bytecode v9 · 1097 bytes · 23 constants
- **Key API:** WaitForChild, new
- Constants: `_rgb`, `hex`, `table`, `pack`, `n`, `new`, `unpack`, `type`, `string`, `test`, `require`, `script`, `Parent`, `Color`, `WaitForChild`, `chroma`, `input`, `rgb2hex`, `format`, `hex2rgb`, `autodetect`, `p`, `insert`

### [1140] ReplicatedStorage.Packages.Chroma.io.hex.hex2rgb
`ModuleScript` · bytecode v9 · 1637 bytes · 24 constants
- **Key API:** WaitForChild
- Constants: `test`, `string`, `sub`, `split`, `tonumber`, `bit32`, `arshift`, `band`, `math`, `round`, `error`, `unknown hex color: %*`, `format`, `hex2rgb`, `require`, `script`, `Parent`, `node_modules`, `WaitForChild`, `.luau-aliases`, `luau-regexp`, `^#?([A-Fa-f0-9]{6}|[A-Fa-f0-9]{3})$`, `^#?([A-Fa-f0-9]{8}|[A-Fa-f0-9]{4})$`

### [1141] ReplicatedStorage.Packages.Chroma.io.hex.rgb2hex
`ModuleScript` · bytecode v9 · 1243 bytes · 29 constants
- **Key API:** WaitForChild
- Constants: `table`, `pack`, `rgba`, `unpack`, `auto`, `rgb`, `bit32`, `lshift`, `bor`, `000000`, `string`, `format`, `%x`, `sub`, `0`, `lower`, `#%*%*`, `argb`, `#%*`, `rgb2hex`, `require`, `script`, `Parent`, `utils`, `WaitForChild`, `last`, `math`, `round`

### [1142] ReplicatedStorage.Packages.Chroma.io.hsi
`ModuleScript` · bytecode v9 · 1134 bytes · 23 constants
- **Key API:** WaitForChild, new
- Constants: `_rgb`, `hsi`, `table`, `pack`, `n`, `new`, `unpack`, `type`, `test`, `require`, `script`, `Parent`, `Color`, `WaitForChild`, `chroma`, `input`, `rgb2hsi`, `utils`, `format`, `hsi2rgb`, `autodetect`, `p`, `insert`

### [1143] ReplicatedStorage.Packages.Chroma.io.hsi.hsi2rgb
`ModuleScript` · bytecode v9 · 1369 bytes · 20 constants
- **Key API:** WaitForChild
- Constants: `table`, `pack`, `hsi`, `unpack`, `isNaN`, `hsi2rgb`, `require`, `script`, `Parent`, `node_modules`, `WaitForChild`, `.luau-aliases`, `@jsdotlua`, `number`, `utils`, `limit`, `TWOPI`, `PITHIRD`, `math`, `cos`

### [1144] ReplicatedStorage.Packages.Chroma.io.hsi.rgb2hsi
`ModuleScript` · bytecode v9 · 1032 bytes · 20 constants
- **Key API:** WaitForChild
- Constants: `table`, `pack`, `rgb`, `unpack`, `NaN`, `rgb2hsi`, `require`, `script`, `Parent`, `node_modules`, `WaitForChild`, `.luau-aliases`, `@jsdotlua`, `number`, `utils`, `TWOPI`, `math`, `min`, `sqrt`, `acos`

### [1145] ReplicatedStorage.Packages.Chroma.io.hsl
`ModuleScript` · bytecode v9 · 1134 bytes · 23 constants
- **Key API:** WaitForChild, new
- Constants: `_rgb`, `hsl`, `table`, `pack`, `n`, `new`, `unpack`, `type`, `test`, `require`, `script`, `Parent`, `Color`, `WaitForChild`, `chroma`, `input`, `rgb2hsl`, `utils`, `format`, `hsl2rgb`, `autodetect`, `p`, `insert`

### [1146] ReplicatedStorage.Packages.Chroma.io.hsl.hsl2rgb
`ModuleScript` · bytecode v9 · 1158 bytes · 12 constants
- **Key API:** WaitForChild
- Constants: `table`, `pack`, `hsl`, `unpack`, `hsl2rgb`, `require`, `script`, `Parent`, `utils`, `WaitForChild`, `math`, `round`

### [1147] ReplicatedStorage.Packages.Chroma.io.hsl.rgb2hsl
`ModuleScript` · bytecode v9 · 1093 bytes · 18 constants
- **Key API:** WaitForChild
- Constants: `table`, `pack`, `rgba`, `unpack`, `math`, `min`, `max`, `NaN`, `rgb2hsl`, `require`, `script`, `Parent`, `node_modules`, `WaitForChild`, `.luau-aliases`, `@jsdotlua`, `number`, `utils`

### [1148] ReplicatedStorage.Packages.Chroma.io.hsv
`ModuleScript` · bytecode v9 · 1134 bytes · 23 constants
- **Key API:** WaitForChild, new
- Constants: `_rgb`, `hsv`, `table`, `pack`, `n`, `new`, `unpack`, `type`, `test`, `require`, `script`, `Parent`, `Color`, `WaitForChild`, `chroma`, `input`, `rgb2hsv`, `utils`, `format`, `hsv2rgb`, `autodetect`, `p`, `insert`

### [1149] ReplicatedStorage.Packages.Chroma.io.hsv.hsv2rgb
`ModuleScript` · bytecode v9 · 911 bytes · 12 constants
- **Key API:** WaitForChild
- Constants: `table`, `pack`, `hsv`, `unpack`, `hsv2rgb`, `require`, `script`, `Parent`, `utils`, `WaitForChild`, `math`, `floor`

### [1150] ReplicatedStorage.Packages.Chroma.io.hsv.rgb2hsv
`ModuleScript` · bytecode v9 · 938 bytes · 18 constants
- **Key API:** WaitForChild
- Constants: `table`, `pack`, `rgb`, `unpack`, `NaN`, `rgb2hsl`, `require`, `script`, `Parent`, `node_modules`, `WaitForChild`, `.luau-aliases`, `@jsdotlua`, `number`, `utils`, `math`, `min`, `max`

### [1151] ReplicatedStorage.Packages.Chroma.io.input
`ModuleScript` · bytecode v9 · 129 bytes · 3 constants
- Constants: `sorted`, `format`, `autodetect`

### [1152] ReplicatedStorage.Packages.Chroma.io.lab
`ModuleScript` · bytecode v9 · 1134 bytes · 23 constants
- **Key API:** WaitForChild, new
- Constants: `_rgb`, `lab`, `table`, `pack`, `n`, `new`, `unpack`, `type`, `test`, `require`, `script`, `Parent`, `Color`, `WaitForChild`, `chroma`, `input`, `rgb2lab`, `utils`, `format`, `lab2rgb`, `autodetect`, `p`, `insert`

### [1153] ReplicatedStorage.Packages.Chroma.io.lab.lab-constants
`ModuleScript` · bytecode v9 · 193 bytes · 8 constants
- Constants: `Kn`, `Xn`, `Yn`, `Zn`, `t0`, `t1`, `t2`, `t3`

### [1154] ReplicatedStorage.Packages.Chroma.io.lab.lab2rgb
`ModuleScript` · bytecode v9 · 1628 bytes · 26 constants
- **Key API:** WaitForChild
- Constants: `table`, `pack`, `lab`, `unpack`, `isNaN`, `Yn`, `Xn`, `Zn`, `lab2rgb`, `xyz_rgb`, `t1`, `t2`, `t0`, `lab_xyz`, `require`, `script`, `Parent`, `node_modules`, `WaitForChild`, `.luau-aliases`, `@jsdotlua`, `number`, `lab-constants`, `utils`, `math`, `pow`

### [1155] ReplicatedStorage.Packages.Chroma.io.lab.rgb2lab
`ModuleScript` · bytecode v9 · 1964 bytes · 22 constants
- **Key API:** WaitForChild
- Constants: `table`, `pack`, `rgb`, `unpack`, `rgb2lab`, `rgb_xyz`, `t3`, `t2`, `t0`, `xyz_lab`, `Xn`, `Yn`, `Zn`, `rgb2xyz`, `require`, `script`, `Parent`, `lab-constants`, `WaitForChild`, `utils`, `math`, `pow`

### [1156] ReplicatedStorage.Packages.Chroma.io.lch
`ModuleScript` · bytecode v9 · 1772 bytes · 31 constants
- **Key API:** WaitForChild, new
- Constants: `_rgb`, `lch`, `reverse`, `hcl`, `table`, `pack`, `n`, `new`, `unpack`, `type`, `test`, `require`, `script`, `Parent`, `node_modules`, `WaitForChild`, `.luau-aliases`, `@jsdotlua`, `collections`, `Color`, `chroma`, `input`, `rgb2lch`, `utils`, `Array`, `format`, `lch2rgb`, `hcl2rgb`, `autodetect`, `p`, `insert`

### [1157] ReplicatedStorage.Packages.Chroma.io.lch.hcl2rgb
`ModuleScript` · bytecode v9 · 705 bytes · 17 constants
- **Key API:** WaitForChild
- Constants: `reverse`, `table`, `pack`, `hcl`, `unpack`, `hcl2rgb`, `require`, `script`, `Parent`, `node_modules`, `WaitForChild`, `.luau-aliases`, `@jsdotlua`, `collections`, `Array`, `utils`, `lch2rgb`

### [1158] ReplicatedStorage.Packages.Chroma.io.lch.lab2lch
`ModuleScript` · bytecode v9 · 870 bytes · 20 constants
- **Key API:** WaitForChild
- Constants: `table`, `pack`, `lab`, `unpack`, `NaN`, `lab2lch`, `require`, `script`, `Parent`, `node_modules`, `WaitForChild`, `.luau-aliases`, `@jsdotlua`, `number`, `utils`, `RAD2DEG`, `math`, `sqrt`, `atan2`, `round`

### [1159] ReplicatedStorage.Packages.Chroma.io.lch.lch2lab
`ModuleScript` · bytecode v9 · 774 bytes · 19 constants
- **Key API:** WaitForChild
- Constants: `table`, `pack`, `lch`, `unpack`, `isNaN`, `lch2lab`, `require`, `script`, `Parent`, `node_modules`, `WaitForChild`, `.luau-aliases`, `@jsdotlua`, `number`, `utils`, `DEG2RAD`, `math`, `sin`, `cos`

### [1160] ReplicatedStorage.Packages.Chroma.io.lch.lch2rgb
`ModuleScript` · bytecode v9 · 726 bytes · 13 constants
- **Key API:** WaitForChild
- Constants: `table`, `pack`, `lch`, `unpack`, `lch2rgb`, `require`, `script`, `Parent`, `utils`, `WaitForChild`, `lab`, `lab2rgb`, `lch2lab`

### [1161] ReplicatedStorage.Packages.Chroma.io.lch.rgb2lch
`ModuleScript` · bytecode v9 · 626 bytes · 13 constants
- **Key API:** WaitForChild
- Constants: `table`, `pack`, `rgb`, `unpack`, `rgb2lch`, `require`, `script`, `Parent`, `utils`, `WaitForChild`, `lab2lch`, `lab`, `rgb2lab`

### [1162] ReplicatedStorage.Packages.Chroma.io.named
`ModuleScript` · bytecode v9 · 1285 bytes · 28 constants
- **Key API:** WaitForChild
- Constants: `_rgb`, `rgb`, `string`, `lower`, `name`, `error`, `unknown color name: %*`, `format`, `#`, `select`, `type`, `named`, `test`, `require`, `script`, `Parent`, `Color`, `WaitForChild`, `hex`, `hex2rgb`, `input`, `rgb2hex`, `colors`, `w3cx11`, `autodetect`, `p`, `table`, `insert`

### [1163] ReplicatedStorage.Packages.Chroma.io.num
`ModuleScript` · bytecode v9 · 1094 bytes · 23 constants
- **Key API:** WaitForChild, new
- Constants: `_rgb`, `num`, `table`, `pack`, `n`, `new`, `unpack`, `type`, `number`, `test`, `require`, `script`, `Parent`, `Color`, `WaitForChild`, `chroma`, `input`, `rgb2num`, `format`, `num2rgb`, `autodetect`, `p`, `insert`

### [1164] ReplicatedStorage.Packages.Chroma.io.num.num2rgb
`ModuleScript` · bytecode v9 · 531 bytes · 9 constants
- Constants: `number`, `bit32`, `arshift`, `band`, `error`, `unknown num color: %*'`, `format`, `num2rgb`, `type`

### [1165] ReplicatedStorage.Packages.Chroma.io.num.rgb2num
`ModuleScript` · bytecode v9 · 490 bytes · 12 constants
- **Key API:** WaitForChild
- Constants: `table`, `pack`, `rgb`, `unpack`, `bit32`, `lshift`, `rgb2num`, `require`, `script`, `Parent`, `utils`, `WaitForChild`

### [1166] ReplicatedStorage.Packages.Chroma.io.oklab
`ModuleScript` · bytecode v9 · 1140 bytes · 23 constants
- **Key API:** WaitForChild, new
- Constants: `_rgb`, `oklab`, `table`, `pack`, `n`, `new`, `unpack`, `type`, `test`, `require`, `script`, `Parent`, `Color`, `WaitForChild`, `chroma`, `input`, `rgb2oklab`, `utils`, `format`, `oklab2rgb`, `autodetect`, `p`, `insert`

### [1167] ReplicatedStorage.Packages.Chroma.io.oklab.oklab2rgb
`ModuleScript` · bytecode v9 · 1191 bytes · 15 constants
- **Key API:** WaitForChild
- Constants: `table`, `pack`, `lab`, `unpack`, `oklab2rgb`, `math`, `abs`, `lrgb2rgb`, `require`, `script`, `Parent`, `utils`, `WaitForChild`, `pow`, `sign`

### [1168] ReplicatedStorage.Packages.Chroma.io.oklab.rgb2oklab
`ModuleScript` · bytecode v9 · 1243 bytes · 16 constants
- **Key API:** WaitForChild
- Constants: `cbrt`, `table`, `pack`, `rgb`, `unpack`, `rgb2oklab`, `math`, `abs`, `rgb2lrgb`, `require`, `script`, `Parent`, `utils`, `WaitForChild`, `pow`, `sign`

### [1169] ReplicatedStorage.Packages.Chroma.io.oklch
`ModuleScript` · bytecode v9 · 1140 bytes · 23 constants
- **Key API:** WaitForChild, new
- Constants: `_rgb`, `oklch`, `table`, `pack`, `n`, `new`, `unpack`, `type`, `test`, `require`, `script`, `Parent`, `Color`, `WaitForChild`, `chroma`, `input`, `rgb2oklch`, `utils`, `format`, `oklch2rgb`, `autodetect`, `p`, `insert`

### [1170] ReplicatedStorage.Packages.Chroma.io.oklch.oklch2rgb
`ModuleScript` · bytecode v9 · 702 bytes · 13 constants
- **Key API:** WaitForChild
- Constants: `table`, `pack`, `lch`, `oklch2rgb`, `require`, `script`, `Parent`, `utils`, `WaitForChild`, `unpack`, `lch2lab`, `oklab`, `oklab2rgb`

### [1171] ReplicatedStorage.Packages.Chroma.io.oklch.rgb2oklch
`ModuleScript` · bytecode v9 · 621 bytes · 14 constants
- **Key API:** WaitForChild
- Constants: `table`, `pack`, `rgb`, `rgb2oklch`, `require`, `script`, `Parent`, `utils`, `WaitForChild`, `unpack`, `lch`, `lab2lch`, `oklab`, `rgb2oklab`

### [1172] ReplicatedStorage.Packages.Chroma.io.rgb
`ModuleScript` · bytecode v9 · 1665 bytes · 25 constants
- **Key API:** WaitForChild, new
- Constants: `_rgb`, `rgb`, `rgba`, `table`, `pack`, `n`, `new`, `unpack`, `type`, `number`, `test`, `require`, `script`, `Parent`, `Color`, `WaitForChild`, `chroma`, `input`, `utils`, `math`, `round`, `format`, `autodetect`, `p`, `insert`

### [1173] ReplicatedStorage.Packages.Chroma.io.roblox
`ModuleScript` · bytecode v9 · 1170 bytes · 27 constants
- **Key API:** WaitForChild, new
- Constants: `R`, `G`, `B`, `table`, `pack`, `n`, `roblox`, `new`, `unpack`, `_rgb`, `Color3`, `fromRGB`, `type`, `userdata`, `typeof`, `test`, `require`, `script`, `Parent`, `Color`, `WaitForChild`, `chroma`, `input`, `format`, `autodetect`, `p`, `insert`

### [1174] ReplicatedStorage.Packages.Chroma.io.temp
`ModuleScript` · bytecode v9 · 965 bytes · 19 constants
- **Key API:** WaitForChild, new
- Constants: `_rgb`, `temperature`, `table`, `pack`, `n`, `temp`, `new`, `unpack`, `require`, `script`, `Parent`, `Color`, `WaitForChild`, `chroma`, `input`, `rgb2temperature`, `kelvin`, `format`, `temperature2rgb`

### [1175] ReplicatedStorage.Packages.Chroma.io.temp.rgb2temperature
`ModuleScript` · bytecode v9 · 611 bytes · 13 constants
- **Key API:** WaitForChild
- Constants: `table`, `pack`, `rgb`, `rgb2temperature`, `require`, `script`, `Parent`, `temperature2rgb`, `WaitForChild`, `utils`, `unpack`, `math`, `round`

### [1176] ReplicatedStorage.Packages.Chroma.io.temp.temperature2rgb
`ModuleScript` · bytecode v9 · 885 bytes · 3 constants
- Constants: `temperature2rgb`, `math`, `log`

### [1177] ReplicatedStorage.Packages.Chroma.node_modules..luau-aliases.@jsdotlua.collections
`ModuleScript` · bytecode v9 · 234 bytes · 7 constants
- **Key API:** WaitForChild
- Constants: `require`, `script`, `Parent`, `@jsdotlua`, `WaitForChild`, `collections`, `src`

### [1178] ReplicatedStorage.Packages.Chroma.node_modules..luau-aliases.@jsdotlua.es7-types
`ModuleScript` · bytecode v9 · 232 bytes · 7 constants
- **Key API:** WaitForChild
- Constants: `require`, `script`, `Parent`, `@jsdotlua`, `WaitForChild`, `es7-types`, `src`

### [1179] ReplicatedStorage.Packages.Chroma.node_modules..luau-aliases.@jsdotlua.instance-of
`ModuleScript` · bytecode v9 · 234 bytes · 7 constants
- **Key API:** WaitForChild
- Constants: `require`, `script`, `Parent`, `@jsdotlua`, `WaitForChild`, `instance-of`, `src`

### [1180] ReplicatedStorage.Packages.Chroma.node_modules..luau-aliases.@jsdotlua.number
`ModuleScript` · bytecode v9 · 229 bytes · 7 constants
- **Key API:** WaitForChild
- Constants: `require`, `script`, `Parent`, `@jsdotlua`, `WaitForChild`, `number`, `src`

### [1181] ReplicatedStorage.Packages.Chroma.node_modules..luau-aliases.@jsdotlua.string
`ModuleScript` · bytecode v9 · 229 bytes · 7 constants
- **Key API:** WaitForChild
- Constants: `require`, `script`, `Parent`, `@jsdotlua`, `WaitForChild`, `string`, `src`

### [1182] ReplicatedStorage.Packages.Chroma.node_modules..luau-aliases.luau-regexp
`ModuleScript` · bytecode v9 · 192 bytes · 6 constants
- **Key API:** WaitForChild
- Constants: `require`, `script`, `Parent`, `luau-regexp`, `WaitForChild`, `src`

### [1183] ReplicatedStorage.Packages.Chroma.node_modules.@jsdotlua.collections.package
`ModuleScript` · bytecode v9 · 606 bytes · 25 constants
- Constants: `dependencies`, `devDependencies`, `license`, `MIT`, `main`, `src/init.lua`, `name`, `@jsdotlua/collections`, `repository`, `scripts`, `version`, `1.2.7`, `^1.2.7`, `@jsdotlua/es7-types`, `@jsdotlua/instance-of`, `@jsdotlua/number`, `^0.1.1`, `npmluau`, `directory`, `modules/collections`, `type`, `git`, `url`, `https://github.com/jsdotlua/luau-polyfill.git`, `prepare`

### [1184] ReplicatedStorage.Packages.Chroma.node_modules.@jsdotlua.collections.src
`ModuleScript` · bytecode v9 · 740 bytes · 15 constants
- **Remotes:** Set
- **Key API:** WaitForChild
- Constants: `require`, `script`, `Array`, `WaitForChild`, `Map`, `Object`, `Set`, `WeakMap`, `inspect`, `Parent`, `.luau-aliases`, `@jsdotlua`, `es7-types`, `coerceToMap`, `coerceToTable`

### [1185] ReplicatedStorage.Packages.Chroma.node_modules.@jsdotlua.collections.src.Array
`ModuleScript` · bytecode v9 · 1707 bytes · 29 constants
- **Key API:** WaitForChild
- Constants: `require`, `script`, `Parent`, `.luau-aliases`, `WaitForChild`, `@jsdotlua`, `es7-types`, `concat`, `every`, `filter`, `find`, `findIndex`, `flat`, `flatMap`, `forEach`, `from`, `includes`, `indexOf`, `isArray`, `join`, `map`, `reduce`, `reverse`, `shift`, `slice`, `some`, `sort`, `splice`, `unshift`

### [1186] ReplicatedStorage.Packages.Chroma.node_modules.@jsdotlua.collections.src.Array.concat
`ModuleScript` · bytecode v9 · 736 bytes · 14 constants
- **Key API:** WaitForChild
- Constants: `table`, `clone`, `#`, `select`, `typeof`, `concat`, `require`, `script`, `Parent`, `isArray`, `WaitForChild`, `.luau-aliases`, `@jsdotlua`, `es7-types`

### [1187] ReplicatedStorage.Packages.Chroma.node_modules.@jsdotlua.collections.src.Array.every
`ModuleScript` · bytecode v9 · 484 bytes · 7 constants
- **Key API:** WaitForChild
- Constants: `require`, `script`, `Parent`, `.luau-aliases`, `WaitForChild`, `@jsdotlua`, `es7-types`

### [1188] ReplicatedStorage.Packages.Chroma.node_modules.@jsdotlua.collections.src.Array.filter
`ModuleScript` · bytecode v9 · 534 bytes · 7 constants
- **Key API:** WaitForChild
- Constants: `require`, `script`, `Parent`, `.luau-aliases`, `WaitForChild`, `@jsdotlua`, `es7-types`

### [1189] ReplicatedStorage.Packages.Chroma.node_modules.@jsdotlua.collections.src.Array.find
`ModuleScript` · bytecode v9 · 394 bytes · 7 constants
- **Key API:** WaitForChild
- Constants: `require`, `script`, `Parent`, `.luau-aliases`, `WaitForChild`, `@jsdotlua`, `es7-types`

### [1190] ReplicatedStorage.Packages.Chroma.node_modules.@jsdotlua.collections.src.Array.findIndex
`ModuleScript` · bytecode v9 · 394 bytes · 7 constants
- **Key API:** WaitForChild
- Constants: `require`, `script`, `Parent`, `.luau-aliases`, `WaitForChild`, `@jsdotlua`, `es7-types`

### [1191] ReplicatedStorage.Packages.Chroma.node_modules.@jsdotlua.collections.src.Array.flat
`ModuleScript` · bytecode v9 · 650 bytes · 11 constants
- **Key API:** WaitForChild
- Constants: `table`, `insert`, `flat`, `require`, `script`, `Parent`, `isArray`, `WaitForChild`, `.luau-aliases`, `@jsdotlua`, `es7-types`

### [1192] ReplicatedStorage.Packages.Chroma.node_modules.@jsdotlua.collections.src.Array.flatMap
`ModuleScript` · bytecode v9 · 501 bytes · 10 constants
- **Key API:** WaitForChild
- Constants: `flatMap`, `require`, `script`, `Parent`, `flat`, `WaitForChild`, `map`, `.luau-aliases`, `@jsdotlua`, `es7-types`

### [1193] ReplicatedStorage.Packages.Chroma.node_modules.@jsdotlua.collections.src.Array.forEach
`ModuleScript` · bytecode v9 · 459 bytes · 7 constants
- **Key API:** WaitForChild
- Constants: `require`, `script`, `Parent`, `.luau-aliases`, `WaitForChild`, `@jsdotlua`, `es7-types`

### [1194] ReplicatedStorage.Packages.Chroma.node_modules.@jsdotlua.collections.src.Array.from
`ModuleScript` · bytecode v9 · 1350 bytes · 20 constants
- **Remotes:** Set
- **Key API:** WaitForChild
- Constants: `error`, `cannot create array from a nil value`, `typeof`, `table`, `string`, `require`, `script`, `Parent`, `Set`, `WaitForChild`, `Map`, `isArray`, `.luau-aliases`, `@jsdotlua`, `instance-of`, `es7-types`, `fromString`, `fromSet`, `fromMap`, `fromArray`

### [1195] ReplicatedStorage.Packages.Chroma.node_modules.@jsdotlua.collections.src.Array.from.fromArray
`ModuleScript` · bytecode v9 · 540 bytes · 10 constants
- **Key API:** WaitForChild
- Constants: `table`, `create`, `clone`, `require`, `script`, `Parent`, `.luau-aliases`, `WaitForChild`, `@jsdotlua`, `es7-types`

### [1196] ReplicatedStorage.Packages.Chroma.node_modules.@jsdotlua.collections.src.Array.from.fromMap
`ModuleScript` · bytecode v9 · 510 bytes · 7 constants
- **Key API:** WaitForChild
- Constants: `require`, `script`, `Parent`, `.luau-aliases`, `WaitForChild`, `@jsdotlua`, `es7-types`

### [1197] ReplicatedStorage.Packages.Chroma.node_modules.@jsdotlua.collections.src.Array.from.fromSet
`ModuleScript` · bytecode v9 · 525 bytes · 10 constants
- **Key API:** WaitForChild
- Constants: `table`, `clone`, `_array`, `require`, `script`, `Parent`, `.luau-aliases`, `WaitForChild`, `@jsdotlua`, `es7-types`

### [1198] ReplicatedStorage.Packages.Chroma.node_modules.@jsdotlua.collections.src.Array.from.fromString
`ModuleScript` · bytecode v9 · 662 bytes · 11 constants
- **Key API:** WaitForChild
- Constants: `table`, `create`, `string`, `sub`, `require`, `script`, `Parent`, `.luau-aliases`, `WaitForChild`, `@jsdotlua`, `es7-types`

### [1199] ReplicatedStorage.Packages.Chroma.node_modules.@jsdotlua.collections.src.Array.includes
`ModuleScript` · bytecode v9 · 449 bytes · 8 constants
- **Key API:** WaitForChild
- Constants: `require`, `script`, `Parent`, `.luau-aliases`, `WaitForChild`, `@jsdotlua`, `es7-types`, `indexOf`

### [1200] ReplicatedStorage.Packages.Chroma.node_modules.@jsdotlua.collections.src.Array.indexOf
`ModuleScript` · bytecode v9 · 503 bytes · 10 constants
- **Key API:** WaitForChild
- Constants: `math`, `abs`, `max`, `require`, `script`, `Parent`, `.luau-aliases`, `WaitForChild`, `@jsdotlua`, `es7-types`

### [1201] ReplicatedStorage.Packages.Chroma.node_modules.@jsdotlua.collections.src.Array.isArray
`ModuleScript` · bytecode v9 · 457 bytes · 5 constants
- Constants: `typeof`, `table`, `next`, `pairs`, `number`

### [1202] ReplicatedStorage.Packages.Chroma.node_modules.@jsdotlua.collections.src.Array.join
`ModuleScript` · bytecode v9 · 565 bytes · 13 constants
- **Key API:** WaitForChild
- Constants: `tostring`, `table`, `concat`, `,`, `require`, `script`, `Parent`, `.luau-aliases`, `WaitForChild`, `@jsdotlua`, `es7-types`, `map`

### [1203] ReplicatedStorage.Packages.Chroma.node_modules.@jsdotlua.collections.src.Array.map
`ModuleScript` · bytecode v9 · 479 bytes · 7 constants
- **Key API:** WaitForChild
- Constants: `require`, `script`, `Parent`, `.luau-aliases`, `WaitForChild`, `@jsdotlua`, `es7-types`

### [1204] ReplicatedStorage.Packages.Chroma.node_modules.@jsdotlua.collections.src.Array.reduce
`ModuleScript` · bytecode v9 · 528 bytes · 9 constants
- **Key API:** WaitForChild
- Constants: `error`, `reduce of empty array with no initial value`, `require`, `script`, `Parent`, `.luau-aliases`, `WaitForChild`, `@jsdotlua`, `es7-types`

### [1205] ReplicatedStorage.Packages.Chroma.node_modules.@jsdotlua.collections.src.Array.reverse
`ModuleScript` · bytecode v9 · 381 bytes · 7 constants
- **Key API:** WaitForChild
- Constants: `require`, `script`, `Parent`, `.luau-aliases`, `WaitForChild`, `@jsdotlua`, `es7-types`

### [1206] ReplicatedStorage.Packages.Chroma.node_modules.@jsdotlua.collections.src.Array.shift
`ModuleScript` · bytecode v9 · 459 bytes · 10 constants
- **Key API:** WaitForChild
- Constants: `table`, `remove`, `require`, `script`, `Parent`, `isArray`, `WaitForChild`, `.luau-aliases`, `@jsdotlua`, `es7-types`

### [1207] ReplicatedStorage.Packages.Chroma.node_modules.@jsdotlua.collections.src.Array.slice
`ModuleScript` · bytecode v9 · 843 bytes · 16 constants
- **Key API:** WaitForChild
- Constants: `typeof`, `table`, `error`, `string`, `format`, `Array.slice called on %s`, `math`, `abs`, `max`, `require`, `script`, `Parent`, `.luau-aliases`, `WaitForChild`, `@jsdotlua`, `es7-types`

### [1208] ReplicatedStorage.Packages.Chroma.node_modules.@jsdotlua.collections.src.Array.some
`ModuleScript` · bytecode v9 · 754 bytes · 15 constants
- **Key API:** WaitForChild
- Constants: `typeof`, `table`, `error`, `string`, `format`, `Array.some called on %s`, `function`, `callback is not a function`, `require`, `script`, `Parent`, `.luau-aliases`, `WaitForChild`, `@jsdotlua`, `es7-types`

### [1209] ReplicatedStorage.Packages.Chroma.node_modules.@jsdotlua.collections.src.Array.sort
`ModuleScript` · bytecode v9 · 1151 bytes · 20 constants
- **Key API:** WaitForChild
- Constants: `type`, `tostring`, `typeof`, `number`, `error`, `invalid result from compare function, expected number but got %s`, `format`, `function`, `invalid argument to Array.sort: compareFunction must be a function`, `table`, `sort`, `require`, `script`, `Parent`, `Object`, `WaitForChild`, `None`, `.luau-aliases`, `@jsdotlua`, `es7-types`

### [1210] ReplicatedStorage.Packages.Chroma.node_modules.@jsdotlua.collections.src.Array.splice
`ModuleScript` · bytecode v9 · 978 bytes · 16 constants
- **Key API:** WaitForChild
- Constants: `#`, `select`, `table`, `insert`, `math`, `abs`, `max`, `min`, `remove`, `require`, `script`, `Parent`, `.luau-aliases`, `WaitForChild`, `@jsdotlua`, `es7-types`

### [1211] ReplicatedStorage.Packages.Chroma.node_modules.@jsdotlua.collections.src.Array.unshift
`ModuleScript` · bytecode v9 · 572 bytes · 12 constants
- **Key API:** WaitForChild
- Constants: `#`, `select`, `table`, `insert`, `require`, `script`, `Parent`, `isArray`, `WaitForChild`, `.luau-aliases`, `@jsdotlua`, `es7-types`

### [1212] ReplicatedStorage.Packages.Chroma.node_modules.@jsdotlua.collections.src.Map
`ModuleScript` · bytecode v9 · 487 bytes · 10 constants
- **Key API:** WaitForChild
- Constants: `require`, `script`, `Parent`, `.luau-aliases`, `WaitForChild`, `@jsdotlua`, `es7-types`, `Map`, `coerceToMap`, `coerceToTable`

### [1213] ReplicatedStorage.Packages.Chroma.node_modules.@jsdotlua.collections.src.Map.Map
`ModuleScript` · bytecode v9 · 3140 bytes · 42 constants
- **Key API:** WaitForChild, new
- Constants: `table`, `create`, `insert`, `clone`, `_array`, `_map`, `error`, ``%s` `%s` is not iterable, cannot make Map using it`, `typeof`, `tostring`, `format`, `size`, `setmetatable`, `new`, `set`, `get`, `clear`, `find`, `remove`, `delete`, `forEach`, `has`, `keys`, `values`, `entries`, `ipairs`, `next`, `__iter`, `rawget`, `__index`, `__newindex`, `require`, `script`, `Parent`, `Array`, `WaitForChild`, `map`, `isArray`, `.luau-aliases`, `@jsdotlua`, `instance-of`, `es7-types`

### [1214] ReplicatedStorage.Packages.Chroma.node_modules.@jsdotlua.collections.src.Map.coerceToMap
`ModuleScript` · bytecode v9 · 724 bytes · 13 constants
- **Key API:** WaitForChild, new
- Constants: `new`, `entries`, `coerceToMap`, `require`, `script`, `Parent`, `Map`, `WaitForChild`, `Object`, `.luau-aliases`, `@jsdotlua`, `instance-of`, `es7-types`

### [1215] ReplicatedStorage.Packages.Chroma.node_modules.@jsdotlua.collections.src.Map.coerceToTable
`ModuleScript` · bytecode v9 · 779 bytes · 13 constants
- **Key API:** WaitForChild
- Constants: `entries`, `coerceToTable`, `require`, `script`, `Parent`, `Map`, `WaitForChild`, `.luau-aliases`, `@jsdotlua`, `instance-of`, `Array`, `reduce`, `es7-types`

### [1216] ReplicatedStorage.Packages.Chroma.node_modules.@jsdotlua.collections.src.Object
`ModuleScript` · bytecode v9 · 763 bytes · 13 constants
- **Key API:** WaitForChild
- Constants: `assign`, `entries`, `freeze`, `is`, `isFrozen`, `keys`, `preventExtensions`, `seal`, `values`, `None`, `require`, `script`, `WaitForChild`

### [1217] ReplicatedStorage.Packages.Chroma.node_modules.@jsdotlua.collections.src.Object.None
`ModuleScript` · bytecode v9 · 188 bytes · 4 constants
- Constants: `Object.None`, `newproxy`, `getmetatable`, `__tostring`

### [1218] ReplicatedStorage.Packages.Chroma.node_modules.@jsdotlua.collections.src.Object.assign
`ModuleScript` · bytecode v9 · 987 bytes · 13 constants
- **Key API:** WaitForChild
- Constants: `typeof`, `table`, `pairs`, `#`, `select`, `require`, `script`, `Parent`, `None`, `WaitForChild`, `.luau-aliases`, `@jsdotlua`, `es7-types`

### [1219] ReplicatedStorage.Packages.Chroma.node_modules.@jsdotlua.collections.src.Object.entries
`ModuleScript` · bytecode v9 · 810 bytes · 17 constants
- **Key API:** WaitForChild
- Constants: `cannot get entries from a nil value`, `assert`, `typeof`, `table`, `pairs`, `insert`, `string`, `len`, `tostring`, `sub`, `require`, `script`, `Parent`, `.luau-aliases`, `WaitForChild`, `@jsdotlua`, `es7-types`

### [1220] ReplicatedStorage.Packages.Chroma.node_modules.@jsdotlua.collections.src.Object.freeze
`ModuleScript` · bytecode v9 · 359 bytes · 9 constants
- **Key API:** WaitForChild
- Constants: `table`, `freeze`, `require`, `script`, `Parent`, `.luau-aliases`, `WaitForChild`, `@jsdotlua`, `es7-types`

### [1222] ReplicatedStorage.Packages.Chroma.node_modules.@jsdotlua.collections.src.Object.isFrozen
`ModuleScript` · bytecode v9 · 361 bytes · 9 constants
- **Key API:** WaitForChild
- Constants: `table`, `isfrozen`, `require`, `script`, `Parent`, `.luau-aliases`, `WaitForChild`, `@jsdotlua`, `es7-types`

### [1223] ReplicatedStorage.Packages.Chroma.node_modules.@jsdotlua.collections.src.Object.keys
`ModuleScript` · bytecode v9 · 983 bytes · 19 constants
- **Remotes:** Set
- **Key API:** WaitForChild
- Constants: `error`, `cannot extract keys from a nil value`, `typeof`, `table`, `pairs`, `insert`, `string`, `len`, `create`, `tostring`, `require`, `script`, `Parent`, `Set`, `WaitForChild`, `.luau-aliases`, `@jsdotlua`, `es7-types`, `instance-of`

### [1224] ReplicatedStorage.Packages.Chroma.node_modules.@jsdotlua.collections.src.Object.preventExtensions
`ModuleScript` · bytecode v9 · 704 bytes · 16 constants
- **Key API:** WaitForChild
- Constants: `%q (%s) is not a valid member of %s`, `tostring`, `typeof`, `format`, `error`, `__newindex`, `__metatable`, `setmetatable`, `preventExtensions`, `require`, `script`, `Parent`, `.luau-aliases`, `WaitForChild`, `@jsdotlua`, `es7-types`

### [1225] ReplicatedStorage.Packages.Chroma.node_modules.@jsdotlua.collections.src.Object.seal
`ModuleScript` · bytecode v9 · 359 bytes · 9 constants
- **Key API:** WaitForChild
- Constants: `table`, `freeze`, `require`, `script`, `Parent`, `.luau-aliases`, `WaitForChild`, `@jsdotlua`, `es7-types`

### [1226] ReplicatedStorage.Packages.Chroma.node_modules.@jsdotlua.collections.src.Object.values
`ModuleScript` · bytecode v9 · 715 bytes · 17 constants
- **Key API:** WaitForChild
- Constants: `error`, `cannot extract values from a nil value`, `typeof`, `table`, `pairs`, `insert`, `string`, `len`, `create`, `sub`, `require`, `script`, `Parent`, `.luau-aliases`, `WaitForChild`, `@jsdotlua`, `es7-types`

### [1227] ReplicatedStorage.Packages.Chroma.node_modules.@jsdotlua.collections.src.Set
`ModuleScript` · bytecode v9 · 2802 bytes · 46 constants
- **Key API:** WaitForChild, new
- Constants: `next`, `_array`, `__iter`, `Set `, `(`, `tostring`, `) `, `__tostring`, `typeof`, `table`, `clone`, `getmetatable`, `rawget`, `string`, `error`, `cannot create array from value of type `%s``, `format`, `create`, `insert`, `size`, `_map`, `setmetatable`, `new`, `add`, `clear`, `find`, `remove`, `delete`, `function`, `callback is not a function`, `forEach`, `has`, `ipairs`, `require`, `script`, `Parent`, `inspect`, `WaitForChild`, `Array`, `isArray`, `from`, `fromString`, `.luau-aliases`, `@jsdotlua`, `es7-types`, `__index`

### [1228] ReplicatedStorage.Packages.Chroma.node_modules.@jsdotlua.collections.src.WeakMap
`ModuleScript` · bytecode v9 · 709 bytes · 16 constants
- **Key API:** WaitForChild, new
- Constants: `__mode`, `k`, `setmetatable`, `_weakMap`, `new`, `get`, `set`, `has`, `require`, `script`, `Parent`, `.luau-aliases`, `WaitForChild`, `@jsdotlua`, `es7-types`, `__index`

### [1229] ReplicatedStorage.Packages.Chroma.node_modules.@jsdotlua.collections.src.inspect
`ModuleScript` · bytecode v9 · 3999 bytes · 68 constants
- **Remotes:** Infinity
- **Services:** HttpService, game
- **Key API:** GetService, WaitForChild
- Constants: `depth`, `inspect`, `type`, `number`, `math`, `floor`, `isIndexKey`, `rawget`, `getTableLength`, `string`, `sortKeysForPrinting`, `next`, `rawpairs`, `table`, `sort`, `getFragmentedKeys`, `typeof`, `JSONEncode`, `NaN`, `Infinity`, `-Infinity`, `tostring`, `function`, `[function`, `debug`, `info`, `n`, `]`, `formatValue`, `find`, `[Circular]`, `unpack`, `insert`, `toJSON`, `formatObjectValue`, `getmetatable`, `__tostring`, `{}`, `[`, `: `, `{ `, `concat`, `, `, ` }`, `formatObject`, `[]`, `[Array]`, `min`, `... 1 more item`, `... %s more items`, `format`, `formatArray`, `Object`, `getObjectTag`, `game`, `HttpService`, `GetService`, `require`, `script`, `Parent`, `Array`, `WaitForChild`, `isArray`, `.luau-aliases`, `@jsdotlua`, `es7-types`

### [1230] ReplicatedStorage.Packages.Chroma.node_modules.@jsdotlua.es7-types.package
`ModuleScript` · bytecode v9 · 430 bytes · 20 constants
- Constants: `devDependencies`, `license`, `MIT`, `main`, `src/init.lua`, `name`, `@jsdotlua/es7-types`, `repository`, `scripts`, `version`, `1.2.7`, `npmluau`, `^0.1.1`, `directory`, `modules/es7-types`, `type`, `git`, `url`, `https://github.com/jsdotlua/luau-polyfill.git`, `prepare`

### [1232] ReplicatedStorage.Packages.Chroma.node_modules.@jsdotlua.instance-of.package
`ModuleScript` · bytecode v9 · 590 bytes · 25 constants
- Constants: `devDependencies`, `license`, `MIT`, `main`, `src/init.lua`, `name`, `@jsdotlua/instance-of`, `repository`, `scripts`, `version`, `1.2.7`, `^1.2.7`, `@jsdotlua/collections`, `^3.6.1-rc.2`, `@jsdotlua/jest-globals`, `@jsdotlua/luau-polyfill`, `^0.1.1`, `npmluau`, `directory`, `modules/instance-of`, `type`, `git`, `url`, `https://github.com/jsdotlua/luau-polyfill.git`, `prepare`

### [1233] ReplicatedStorage.Packages.Chroma.node_modules.@jsdotlua.instance-of.src
`ModuleScript` · bytecode v9 · 136 bytes · 4 constants
- **Key API:** WaitForChild
- Constants: `require`, `script`, `instanceof`, `WaitForChild`

### [1234] ReplicatedStorage.Packages.Chroma.node_modules.@jsdotlua.instance-of.src.instanceof
`ModuleScript` · bytecode v9 · 625 bytes · 7 constants
- **Key API:** new
- Constants: `new`, `typeof`, `table`, `pcall`, `getmetatable`, `__index`, `instanceof`

### [1235] ReplicatedStorage.Packages.Chroma.node_modules.@jsdotlua.number.package
`ModuleScript` · bytecode v9 · 370 bytes · 18 constants
- Constants: `license`, `MIT`, `main`, `src/init.lua`, `name`, `@jsdotlua/number`, `repository`, `scripts`, `version`, `1.2.7`, `directory`, `modules/number`, `type`, `git`, `url`, `https://github.com/jsdotlua/luau-polyfill.git`, `prepare`, `npmluau`

### [1236] ReplicatedStorage.Packages.Chroma.node_modules.@jsdotlua.number.src
`ModuleScript` · bytecode v9 · 650 bytes · 11 constants
- **Key API:** WaitForChild
- Constants: `isFinite`, `isInteger`, `isNaN`, `isSafeInteger`, `MAX_SAFE_INTEGER`, `MIN_SAFE_INTEGER`, `NaN`, `toExponential`, `require`, `script`, `WaitForChild`

### [1239] ReplicatedStorage.Packages.Chroma.node_modules.@jsdotlua.number.src.isFinite
`ModuleScript` · bytecode v9 · 196 bytes · 2 constants
- Constants: `typeof`, `number`

### [1240] ReplicatedStorage.Packages.Chroma.node_modules.@jsdotlua.number.src.isInteger
`ModuleScript` · bytecode v9 · 215 bytes · 4 constants
- Constants: `type`, `number`, `math`, `floor`

### [1241] ReplicatedStorage.Packages.Chroma.node_modules.@jsdotlua.number.src.isNaN
`ModuleScript` · bytecode v9 · 146 bytes · 2 constants
- Constants: `type`, `number`

### [1242] ReplicatedStorage.Packages.Chroma.node_modules.@jsdotlua.number.src.isSafeInteger
`ModuleScript` · bytecode v9 · 381 bytes · 8 constants
- **Key API:** WaitForChild
- Constants: `math`, `abs`, `require`, `script`, `Parent`, `isInteger`, `WaitForChild`, `MAX_SAFE_INTEGER`

### [1243] ReplicatedStorage.Packages.Chroma.node_modules.@jsdotlua.number.src.toExponential
`ModuleScript` · bytecode v9 · 767 bytes · 19 constants
- Constants: `typeof`, `string`, `tonumber`, `number`, `nan`, `error`, `TypeError: fractionDigits must be a number between 0 and 100`, `RangeError: fractionDigits must be between 0 and 100`, `%e`, `%.`, `tostring`, `e`, `format`, `%+0`, `+`, `gsub`, `%-0`, `-`, `0*e`

### [1244] ReplicatedStorage.Packages.Chroma.node_modules.@jsdotlua.string.package
`ModuleScript` · bytecode v9 · 544 bytes · 24 constants
- Constants: `dependencies`, `devDependencies`, `license`, `MIT`, `main`, `src/init.lua`, `name`, `@jsdotlua/string`, `repository`, `scripts`, `version`, `1.2.7`, `^1.2.7`, `@jsdotlua/es7-types`, `@jsdotlua/number`, `npmluau`, `^0.1.1`, `directory`, `modules/string`, `type`, `git`, `url`, `https://github.com/jsdotlua/luau-polyfill.git`, `prepare`

### [1245] ReplicatedStorage.Packages.Chroma.node_modules.@jsdotlua.string.src
`ModuleScript` · bytecode v9 · 1108 bytes · 18 constants
- **Key API:** WaitForChild
- Constants: `charCodeAt`, `endsWith`, `findOr`, `includes`, `indexOf`, `lastIndexOf`, `slice`, `split`, `startsWith`, `substr`, `trim`, `trimEnd`, `trimStart`, `trimRight`, `trimLeft`, `require`, `script`, `WaitForChild`

### [1246] ReplicatedStorage.Packages.Chroma.node_modules.@jsdotlua.string.src.charCodeAt
`ModuleScript` · bytecode v9 · 609 bytes · 14 constants
- **Key API:** WaitForChild
- Constants: `type`, `number`, `string`, `len`, `utf8`, `offset`, `codepoint`, `require`, `script`, `Parent`, `.luau-aliases`, `WaitForChild`, `@jsdotlua`, `NaN`

### [1247] ReplicatedStorage.Packages.Chroma.node_modules.@jsdotlua.string.src.endsWith
`ModuleScript` · bytecode v9 · 292 bytes · 3 constants
- Constants: `len`, `find`, `endsWith`

### [1248] ReplicatedStorage.Packages.Chroma.node_modules.@jsdotlua.string.src.findOr
`ModuleScript` · bytecode v9 · 908 bytes · 21 constants
- Constants: `utf8`, `offset`, `%%%1`, `gsub`, `string`, `find`, `sub`, `len`, `error`, `string `%s` has an invalid byte at position %s`, `tostring`, `format`, `index`, `match`, `table`, `insert`, `findOr`, `([`, `$%^()-[].?`, `(.)`, `])`

### [1249] ReplicatedStorage.Packages.Chroma.node_modules.@jsdotlua.string.src.includes
`ModuleScript` · bytecode v9 · 734 bytes · 17 constants
- Constants: `utf8`, `len`, `string `%s` has an invalid byte at position %s`, `tostring`, `format`, `assert`, `tonumber`, `offset`, `%%%1`, `gsub`, `string`, `find`, `includes`, `([`, `$%^()-[].?`, `(.)`, `])`

### [1250] ReplicatedStorage.Packages.Chroma.node_modules.@jsdotlua.string.src.indexOf
`ModuleScript` · bytecode v9 · 489 bytes · 8 constants
- Constants: `%%%1`, `gsub`, `string`, `sub`, `([`, `$%^()-[].?`, `(.)`, `])`

### [1251] ReplicatedStorage.Packages.Chroma.node_modules.@jsdotlua.string.src.lastIndexOf
`ModuleScript` · bytecode v9 · 373 bytes · 5 constants
- Constants: `string`, `len`, `find`, `lastIndexOf`

### [1252] ReplicatedStorage.Packages.Chroma.node_modules.@jsdotlua.string.src.slice
`ModuleScript` · bytecode v9 · 867 bytes · 16 constants
- Constants: `utf8`, `len`, `string `%s` has an invalid byte at position %s`, `tostring`, `format`, `assert`, `tonumber`, `typeof`, `number`, `startIndexStr should be a number`, `lastIndexStr should convert to number`, `offset`, `string`, `sub`, `slice`

### [1253] ReplicatedStorage.Packages.Chroma.node_modules.@jsdotlua.string.src.split
`ModuleScript` · bytecode v9 · 1682 bytes · 27 constants
- **Key API:** WaitForChild
- Constants: `typeof`, `string`, `.`, `gmatch`, `table`, `insert`, `utf8`, `len`, `string `%s` has an invalid byte at position %s`, `tostring`, `format`, `assert`, `index`, `match`, `split`, `require`, `script`, `Parent`, `findOr`, `WaitForChild`, `slice`, `.luau-aliases`, `@jsdotlua`, `es7-types`, `number`, `MAX_SAFE_INTEGER`

### [1254] ReplicatedStorage.Packages.Chroma.node_modules.@jsdotlua.string.src.startsWith
`ModuleScript` · bytecode v9 · 329 bytes · 4 constants
- Constants: `string`, `len`, `find`, `startsWith`

### [1255] ReplicatedStorage.Packages.Chroma.node_modules.@jsdotlua.string.src.substr
`ModuleScript` · bytecode v9 · 195 bytes · 3 constants
- Constants: `string`, `sub`

### [1256] ReplicatedStorage.Packages.Chroma.node_modules.@jsdotlua.string.src.trim
`ModuleScript` · bytecode v9 · 315 bytes · 6 constants
- **Key API:** WaitForChild
- Constants: `require`, `script`, `Parent`, `trimStart`, `WaitForChild`, `trimEnd`

### [1257] ReplicatedStorage.Packages.Chroma.node_modules.@jsdotlua.string.src.trimEnd
`ModuleScript` · bytecode v9 · 115 bytes · 3 constants
- Constants: `[%s]+$`, `gsub`

### [1258] ReplicatedStorage.Packages.Chroma.node_modules.@jsdotlua.string.src.trimStart
`ModuleScript` · bytecode v9 · 115 bytes · 3 constants
- Constants: `^[%s]+`, `gsub`

### [1259] ReplicatedStorage.Packages.Chroma.node_modules.luau-regexp.package
`ModuleScript` · bytecode v9 · 685 bytes · 27 constants
- Constants: `dependencies`, `devDependencies`, `license`, `MIT`, `main`, `src/init.lua`, `name`, `luau-regexp`, `repository`, `scripts`, `version`, `0.2.1`, `npmluau`, `^0.1.0`, `type`, `git`, `url`, `https://github.com/jsdotlua/luau-regexp.git`, `sh ./bin/build-assets.sh`, `build-assets`, `stylua src/init.lua src/__tests__ `, `format`, `selene src/init.lua src/__tests__`, `lint`, `prepare`, `stylua src/init.lua src/__tests__ --check`, `style-check`

### [1260] ReplicatedStorage.Packages.Chroma.node_modules.luau-regexp.src
`ModuleScript` · bytecode v9 · 139 bytes · 4 constants
- **Key API:** WaitForChild
- Constants: `require`, `script`, `Regexp.global`, `WaitForChild`

### [1261] ReplicatedStorage.Packages.Chroma.node_modules.luau-regexp.src.RegEx
`ModuleScript` · bytecode v9 · 73672 bytes · 302 constants
- **Key API:** new
- Constants: `utf8`, `offset`, `string`, `sub`, `len`, `n`, `s`, `codepoint`, `math`, `ceil`, `table`, `create`, `pack`, `move`, `to_str_arr`, `char`, `unpack`, `concat`, `from_str_arr`, `utf8_sub`, `#`, `select`, `error`, `missing argument #1 (Match expected)`, `name`, `Match`, `format`, `invalid argument #1 to %q (Match expected, got %s)`, `typeof`, `group`, `span`, `missing argument #1 (RegEx expected)`, `missing argument #2 (string expected)`, `RegEx`, `type`, `number`, `invalid argument #1 to %q (RegEx expected, got %s)`, `fromstring`, `invalid argument #3 to 'sub' (string expected, got %s)`, `invalid argument #2 to %q (string expected, got %s)`, `split`, `nil`, `tonumber`, `invalid argument #3 to %q (number expected, got %s)`, `floor`, `max`, `match`, `matchiter`, `check_re`, `spans`, `Match (%d..%d, empty)`, `Match (%d..%d): %s`, `input`, `match_tostr`, `source`, `newproxy`, `getmetatable`, `__metatable`, `setmetatable`, `__index`, `__tostring`, `group_id`, `new_match`, `pairs`, `newline`, `is_newline`, `ignoreCase`, `charset`, `ipairs`, `range`, `class`, `xdigit`, `ascii`, `vertical_tab`, `unicode`, `Cn`, `alnum`, `L`, `Nl`, `Nd`, `alpha`, `blank`, `Zs`, `cntrl`, `Cc`, `digit`, `graph`, `P`, `C`, `lower`, `Ll`, `print`, `punct`, `space`, `Z`, `upper`, `Lu`, `word`, `Pc`, `category`, `Xan`, `Xwd`, `^[LN]`, `find`, `Xps`, `Xsp`, `Xuc`, `dotAll`, `newline_seq`, `tkn_char_match`, `count`, `quantifier`, `find_alternation`, `alternation`, `insert`, `ACCEPT`, `PRUNE`, `SKIP`, `remove`, `matchStart`, `jmp`, `lazy`, `recurmatch`, `FAIL`, `backref`, `possessive`, `min`, `multiline`, `clear`, `greedy`, `sign`, `group_n`, `re_rawfind`, `token`, `flags`, `verb_flags`, `condition`, `insert_tokenized_sub`, `invalid argument #5 to 'sub' (string expected, got %s)`, `l`, `o`, `u`, `gmatch`, `charpattern`, `invalid regular expression substitution flag `, `function`, `invalid argument #2 to 'sub' (string/function%s expected, got %s)`, `/table`, `invalid argument #4 to 'sub' (number expected, got %s)`, `malformed substitution pattern`, `replacement string must not end with a trailing backslash`, `reference to non-existent subpattern`, `subst_string`, `invalid replacement value (a %s)`, `invalid argument #3 to 'split' (number expected, got %s)`, `re_index`, `pattern_repr`, `flag_repr`, `re_tostr`, `options.unicodeData cannot be turned off while having unicode flag`, `not_empty`, `quantifier doesn't follow a repeatable pattern`, `positive_lookahead:`, `negative_lookhead:`, `positive_lookbehind:`, `negative_lookbehind:`, `^[pn]l[ab]:$`, `^n`, `b`, `atomic:`, `F`, `BSR_ANYCRLF`, `BSR_UNICODE`, `NOTEMPTY`, `NOTEMPTY_ATSTART`, `unknown or malformed verb`, `this verb must be placed at the beginning of the regex`, `unterminated parenthetical`, `invalid group structure`, `missing character in subpattern`, `subpattern name must not begin with a digit`, `invalid character in subpattern`, `subpattern name already exists`, `different names for subpatterns of the same number aren't permitted`, `unmatched ) in regular expression`, `lookbehind assertion is not fixed width`, `unterminated character class`, `invalid range in character class`, `POSIX collating elements aren't supported`, `unknown POSIX class name`, `malformed hexadecimal character`, `character offset too large`, `malformed Unicode code point`, `invalid escape sequence`, `options.unicodeData cannot be turned off when using \p`, `malformed octal code`, `POSIX named classes are only support within a character set`, `pattern may not end with a trailing backslash`, `malformed reference code`, `malformed hexadecimal code`, `numbers out of order in {} quantifier`, `ungreedy`, `extended`, `reference to a non-existent or invalid subpattern`, `tokenize_ptn`, `pruge`, `%s|%s`, `new_re`, `\`, `.`, `escape_fslash`, `sort_flag_chr`, `missing argument #1 (string expected)`, `invalid argument #1 (string expected, got %s)`, `invalid argument #2 (string expected, got %s)`, `anchored`, `caseless`, `dotall`, `invalid regular expression flag `, `sort`, `/%s/`, `(\*)/`, `gsub`, `new`, `empty regex`, `delimiter must not be alphanumeric or a backslash`, `no ending delimiter ('%s') found`, `invalid argument #1 to 'escape' (string expected, got %s)`, `invalid argument #3 to 'escape' (string expected, got %s)`, `^[%a\]$`, `delimiter have not be alphanumeric`, `[ 
	]`, `[\%s#()%%%%*+.?[%%]^{|%s]`, `%s`, `^[%%%]]$`, `%`, `\%1`, `escape`, `missing argument #1`, `Attempt to modify a readonly table`, `readonly_table`, `cacheSize`, `unicodeData`, `__mode`, `k`, `a`, `i`, `m`, `U`, `x`, `Cf`, `Co`, `Cs`, `Lm`, `Lo`, `Lt`, `M`, `Mc`, `Me`, `Mn`, `N`, `No`, `Pd`, `Pe`, `Pf`, `Pi`, `Po`, `Ps`, `S`, `Sc`, `Sk`, `Sm`, `So`, `Zl`, `Zp`, `groups`, `groupdict`, `grouparr`, `CR`, `LF`, `CRLF`, `ANYRLF`, `ANY`, `NUL`, `test`, `matchall`, `expected number for options.cacheSize, got %s`, `cache size cannot be a negative number or a NaN`, `cache size too large`, `\x00`, ` `, `\n`, `\t`, `\r`, `\f`, `/The\s*metatable\s*is\s*(?:locked|inaccessible)(?#Nice try :])/i`, `__newindex`

### [1262] ReplicatedStorage.Packages.Chroma.node_modules.luau-regexp.src.Regexp.global
`ModuleScript` · bytecode v9 · 1189 bytes · 29 constants
- **Key API:** WaitForChild, new
- Constants: `_innerRegEx`, `tostring`, `__tostring`, `match`, `span`, `grouparr`, `n`, `index`, `input`, `exec`, `test`, `new`, `source`, `ignoreCase`, `global`, `multiline`, `i`, `find`, `g`, `m`, `setmetatable`, `require`, `script`, `Parent`, `RegEx`, `WaitForChild`, `__index`, `__call`

### [1263] ReplicatedStorage.Packages.Chroma.ops.alpha
`ModuleScript` · bytecode v9 · 466 bytes · 11 constants
- **Key API:** WaitForChild, new
- Constants: `type`, `number`, `_rgb`, `new`, `rgb`, `alpha`, `require`, `script`, `Parent`, `Color`, `WaitForChild`

### [1264] ReplicatedStorage.Packages.Chroma.ops.clipped
`ModuleScript` · bytecode v9 · 298 bytes · 8 constants
- **Key API:** WaitForChild
- Constants: `_rgb`, `_clipped`, `clipped`, `require`, `script`, `Parent`, `Color`, `WaitForChild`

### [1265] ReplicatedStorage.Packages.Chroma.ops.darken
`ModuleScript` · bytecode v9 · 778 bytes · 15 constants
- **Key API:** WaitForChild, new
- Constants: `lab`, `Kn`, `new`, `alpha`, `darken`, `brighten`, `require`, `script`, `Parent`, `io`, `WaitForChild`, `Color`, `lab-constants`, `darker`, `brighter`

### [1266] ReplicatedStorage.Packages.Chroma.ops.get
`ModuleScript` · bytecode v9 · 604 bytes · 16 constants
- **Key API:** WaitForChild
- Constants: `string`, `split`, `.`, `find`, `sub`, `ok`, `error`, `unknown channel %* in mode %*`, `format`, `get`, `require`, `script`, `Parent`, `Color`, `WaitForChild`

### [1267] ReplicatedStorage.Packages.Chroma.ops.luminance
`ModuleScript` · bytecode v9 · 1680 bytes · 20 constants
- **Key API:** WaitForChild, new
- Constants: `interpolate`, `luminance`, `math`, `abs`, `test`, `type`, `number`, `new`, `_rgb`, `rgb`, `rgb2luminance`, `luminance_x`, `require`, `script`, `Parent`, `Color`, `WaitForChild`, `types`, `interpolation-mode`, `pow`

### [1268] ReplicatedStorage.Packages.Chroma.ops.mix
`ModuleScript` · bytecode v9 · 534 bytes · 10 constants
- **Key API:** WaitForChild
- Constants: `interpolate`, `require`, `script`, `Parent`, `Color`, `WaitForChild`, `types`, `interpolation-mode`, `generator`, `mix`

### [1269] ReplicatedStorage.Packages.Chroma.ops.premultiply
`ModuleScript` · bytecode v9 · 445 bytes · 9 constants
- **Key API:** WaitForChild, new
- Constants: `_rgb`, `new`, `rgb`, `premultiply`, `require`, `script`, `Parent`, `Color`, `WaitForChild`

### [1270] ReplicatedStorage.Packages.Chroma.ops.saturate
`ModuleScript` · bytecode v9 · 758 bytes · 14 constants
- **Key API:** WaitForChild, new
- Constants: `lch`, `Kn`, `new`, `alpha`, `saturate`, `desaturate`, `require`, `script`, `Parent`, `io`, `WaitForChild`, `Color`, `lab`, `lab-constants`

### [1271] ReplicatedStorage.Packages.Chroma.ops.set
`ModuleScript` · bytecode v9 · 1231 bytes · 26 constants
- **Key API:** WaitForChild, new
- Constants: `string`, `split`, `.`, `find`, `sub`, `ok`, `type`, `+`, `tonumber`, `-`, `*`, `/`, `number`, `error`, `unsupported value for Color.set`, `new`, `_rgb`, `unknown channel %* in mode %*`, `format`, `set`, `require`, `script`, `Parent`, `Color`, `WaitForChild`

### [1272] ReplicatedStorage.Packages.Chroma.types.blend-types
`ModuleScript` · bytecode v9 · 161 bytes · 5 constants
- **Key API:** WaitForChild
- Constants: `require`, `script`, `Parent`, `color-types`, `WaitForChild`

### [1274] ReplicatedStorage.Packages.Chroma.types.color-types
`ModuleScript` · bytecode v9 · 168 bytes · 5 constants
- **Key API:** WaitForChild
- Constants: `require`, `script`, `Parent`, `interpolation-mode`, `WaitForChild`

### [1275] ReplicatedStorage.Packages.Chroma.types.cubehelix-types
`ModuleScript` · bytecode v9 · 161 bytes · 5 constants
- **Key API:** WaitForChild
- Constants: `require`, `script`, `Parent`, `color-types`, `WaitForChild`

### [1277] ReplicatedStorage.Packages.Chroma.types.scale-types
`ModuleScript` · bytecode v9 · 237 bytes · 6 constants
- **Key API:** WaitForChild
- Constants: `require`, `script`, `Parent`, `color-types`, `WaitForChild`, `interpolation-mode`

### [1278] ReplicatedStorage.Packages.Chroma.utils
`ModuleScript` · bytecode v9 · 564 bytes · 13 constants
- **Key API:** WaitForChild
- Constants: `clip_rgb`, `limit`, `type`, `unpack`, `last`, `PI`, `TWOPI`, `PITHIRD`, `DEG2RAD`, `RAD2DEG`, `require`, `script`, `WaitForChild`

### [1279] ReplicatedStorage.Packages.Chroma.utils.analyze
`ModuleScript` · bytecode v9 · 3754 bytes · 42 constants
- **Key API:** WaitForChild
- Constants: `min`, `max`, `sum`, `values`, `count`, `next`, `type`, `string`, `table`, `isNaN`, `insert`, `domain`, `limits`, `analyze`, `equal`, `sort`, `sub`, `c`, `e`, `l`, `error`, `Logarithmic scales are only possible for values > 0`, `q`, `k`, `create`, `find`, `require`, `script`, `Parent`, `node_modules`, `WaitForChild`, `.luau-aliases`, `@jsdotlua`, `collections`, `number`, `Object`, `math`, `log`, `pow`, `floor`, `abs`

### [1280] ReplicatedStorage.Packages.Chroma.utils.clip_rgb
`ModuleScript` · bytecode v9 · 454 bytes · 8 constants
- **Key API:** WaitForChild
- Constants: `_clipped`, `_unclipped`, `clip_rgb`, `require`, `script`, `Parent`, `limit`, `WaitForChild`

### [1281] ReplicatedStorage.Packages.Chroma.utils.contrast
`ModuleScript` · bytecode v9 · 474 bytes · 9 constants
- **Key API:** WaitForChild, new
- Constants: `new`, `luminance`, `contrast`, `require`, `script`, `Parent`, `Color`, `WaitForChild`, `ops`

### [1282] ReplicatedStorage.Packages.Chroma.utils.delta-e
`ModuleScript` · bytecode v9 · 2587 bytes · 20 constants
- **Key API:** WaitForChild, new
- Constants: `rad2deg`, `deg2rad`, `new`, `lab`, `deltaE`, `require`, `script`, `Parent`, `Color`, `WaitForChild`, `math`, `sqrt`, `pow`, `min`, `max`, `atan2`, `abs`, `cos`, `sin`, `exp`

### [1283] ReplicatedStorage.Packages.Chroma.utils.distance
`ModuleScript` · bytecode v9 · 493 bytes · 11 constants
- **Key API:** WaitForChild, new
- Constants: `lab`, `new`, `get`, `math`, `sqrt`, `distance`, `require`, `script`, `Parent`, `Color`, `WaitForChild`

### [1284] ReplicatedStorage.Packages.Chroma.utils.last
`ModuleScript` · bytecode v9 · 311 bytes · 6 constants
- Constants: `#`, `select`, `string`, `lower`, `last`, `type`

### [1285] ReplicatedStorage.Packages.Chroma.utils.limit
`ModuleScript` · bytecode v9 · 174 bytes · 1 constants
- Constants: `limit`

### [1286] ReplicatedStorage.Packages.Chroma.utils.round.roblox
`ModuleScript` · bytecode v9 · 150 bytes · 2 constants
- Constants: `math`, `round`

### [1287] ReplicatedStorage.Packages.Chroma.utils.scales
`ModuleScript` · bytecode v9 · 745 bytes · 17 constants
- **Key API:** WaitForChild
- Constants: `hsl`, `cool`, `#000`, `#f00`, `#ff0`, `#fff`, `mode`, `rgb`, `hot`, `require`, `script`, `Parent`, `chroma`, `WaitForChild`, `io`, `generator`, `scale`

### [1288] ReplicatedStorage.Packages.Chroma.utils.type
`ModuleScript` · bytecode v9 · 159 bytes · 3 constants
- Constants: `object`, `tostring`, `typeFn`

### [1289] ReplicatedStorage.Packages.Chroma.utils.unpack
`ModuleScript` · bytecode v9 · 876 bytes · 19 constants
- **Key API:** WaitForChild
- Constants: `n`, `table`, `unpack`, `type`, `next`, `string`, `map`, `filter`, `split`, `require`, `script`, `Parent`, `node_modules`, `WaitForChild`, `.luau-aliases`, `@jsdotlua`, `collections`, `Array`

### [1290] ReplicatedStorage.Packages.Chroma.utils.valid
`ModuleScript` · bytecode v9 · 285 bytes · 8 constants
- **Key API:** WaitForChild, new
- Constants: `pcall`, `new`, `valid`, `require`, `script`, `Parent`, `Color`, `WaitForChild`

### [1291] ReplicatedStorage.Packages.Conch
`ModuleScript` · bytecode v9 · 178 bytes · 7 constants
- Constants: `require`, `script`, `Parent`, `Vendor`, `Conch`, `conch`, `lib`

### [1292] ReplicatedStorage.Packages.Cooldown
`ModuleScript` · bytecode v9 · 1219 bytes · 22 constants
- **Services:** Players, game
- **Key API:** Connect, GetService, IsA, new
- Constants: `Remove`, `setmetatable`, `_list`, `_timeList`, `_timeBetween`, `PlayerRemoving`, `Connect`, `new`, `tick`, `CanFire`, `SetTimeBetween`, `typeof`, `Instance`, `_watchInstance`, `AddTimestamp`, `Player`, `IsA`, `Destroying`, `game`, `Players`, `GetService`, `__index`

### [1293] ReplicatedStorage.Packages.Flashcast
`ModuleScript` · bytecode v9 · 2920 bytes · 46 constants
- **Services:** RunService, game, workspace
- **Key API:** Connect, Disconnect, GetService, new
- Constants: `desiredFramerate`, `setDesiredFramerate`, `table`, `insert`, `beforeStep`, `afterStep`, `_beforeStepCallbacks`, `_afterStepCallbacks`, `createBehavior`, `getBullets`, `position`, `worldRoot`, `raycastParams`, `Raycast`, `raycastResults`, `distanceTraveled`, `Magnitude`, `touched`, `move`, `find`, `remove`, `stop`, `isStopped`, `behavior`, `direction`, `os`, `clock`, `lastTick`, `data`, `spawnBullet`, `task`, `spawn`, `stepBullet`, `step`, `clear`, `Disconnect`, `destroy`, `workspace`, `event`, `PostSimulation`, `Connect`, `createFlashcast`, `game`, `RunService`, `GetService`, `new`

### [1294] ReplicatedStorage.Packages.Freeze
`ModuleScript` · bytecode v9 · 180 bytes · 6 constants
- Constants: `require`, `freeze`, `duckarmor_freeze@0.1.4`, `script`, `Parent`, `_Index`

### [1295] ReplicatedStorage.Packages.Freeze.Freeze
`Script` · bytecode v9 · 315 bytes · 8 constants
- **Key API:** SetAttribute
- Constants: `script`, `Target`, `Value`, `Changed`, `Wait`, `require`, `Loaded`, `SetAttribute`

### [1296] ReplicatedStorage.Packages.GameAnalytics
`ModuleScript` · bytecode v9 · 299 bytes · 8 constants
- **Services:** RunService, game
- **Key API:** GetService
- Constants: `game`, `RunService`, `GetService`, `IsServer`, `require`, `script`, `GameAnalytics`, `GameAnalyticsClient`

### [1297] ReplicatedStorage.Packages.GameAnalytics.GameAnalytics
`ModuleScript` · bytecode v9 · 22312 bytes · 289 constants
- **Remotes:** Platform, Store
- **Services:** Players, ReplicatedStorage, RunService, game
- **Key API:** Connect, FindFirstChild, Fire, GetPlayers, GetService, WaitForChild, new
- Constants: `Func`, `Args`, `table`, `insert`, `Added event to initialization queue`, `i`, `Initialization queue already cleared.`, `w`, `addToInitializationQueue`, `isPlayerReady`, `Added event to player initialization queue`, `Player initialization queue already cleared.`, `addToInitializationQueueByUserId`, `playerId`, `needsInitialized`, `shouldWarn`, `message`, `Initialized`, ` SDK is not initialized`, `isEnabled`, ` SDK is disabled`, `sessionIsStarted`, ` Session has not started yet`, `isSdkReady`, `Available custom dimensions must be set before SDK is initialized`, `setAvailableCustomDimensions01`, `configureAvailableCustomDimensions01`, `setAvailableCustomDimensions02`, `configureAvailableCustomDimensions02`, `setAvailableCustomDimensions03`, `configureAvailableCustomDimensions03`, `Available resource currencies must be set before SDK is initialized`, `setAvailableResourceCurrencies`, `configureAvailableResourceCurrencies`, `Available resource item types must be set before SDK is initialized`, `setAvailableResourceItemTypes`, `configureAvailableResourceItemTypes`, `Build version must be set before SDK is initialized.`, `setBuild`, `configureBuild`, `Available gamepasses must be set before SDK is initialized.`, `setAvailableGamepasses`, `configureAvailableGamepasses`, `isEventSubmissionEnabled`, `Cannot start new session. SDK is not initialized yet.`, `startNewSession`, `performTaskOnGAThread`, `endSession`, `string`, `gsub`, `[^A-Za-z0-9%s%-_%.%(%)!%?]`, `filterForBusinessEvent`, `Could not add business event`, `addBusinessEvent`, `amount`, `itemType`, `itemId`, `cartType`, `math`, `floor`, `gamepassId`, `USD`, `Gamepass`, `Website`, `GetPlayerByUserId`, `GetPlayerDataFromCache`, `OwnedGamepasses`, `PlayerCache`, `SavePlayerData`, `Could not add resource event`, `addResourceEvent`, `flowType`, `currency`, `Could not add progression event`, `addProgressionEvent`, `progressionStatus`, `progression01`, `progression02`, `progression03`, `score`, `Could not add design event`, `addDesignEvent`, `eventId`, `value`, `Could not add error event`, `addErrorEvent`, `severity`, `IsStudio`, `setDebugLog`, `Debug logging enabled`, `Debug logging disabled`, `setEnabledDebugLog can only be used in studio`, `setEnabledDebugLog`, `setInfoLog`, `Info logging enabled`, `Info logging disabled`, `setEnabledInfoLog`, `setVerboseLog`, `Verbose logging enabled`, `ii`, `Verbose logging disabled`, `setEnabledVerboseLog`, `setEventSubmission`, `Event submission enabled`, `Event submission disabled`, `setEnabledEventSubmission`, `_availableCustomDimensions01`, `validateDimension`, `Could not set custom01 dimension value to '`, `'. Value not found in available custom01 dimension values`, `Could not set custom01 dimension`, `setCustomDimension01`, `_availableCustomDimensions02`, `Could not set custom02 dimension value to '`, `'. Value not found in available custom02 dimension values`, `Could not set custom02 dimension`, `setCustomDimension02`, `_availableCustomDimensions03`, `Could not set custom03 dimension value to '`, `'. Value not found in available custom03 dimension values`, `Could not set custom03 dimension`, `setCustomDimension03`, `ReportErrors`, `setEnabledReportErrors`, `UseCustomUserId`, `setEnabledCustomUserId`, `AutomaticSendBusinessEvents`, `setEnabledAutomaticSendBusinessEvents`, `ipairs`, `PlayerTeleporting`, `SessionID`, `Sessions`, `SessionStart`, `tostring`, `gameanalyticsData`, `addGameAnalyticsTeleportData`, `key`, `defaultValue`, `getRemoteConfigsStringValue`, `getRemoteConfigsValueAsString`, `isRemoteConfigsReady`, `getRemoteConfigsContentAsString`, `GetCountryRegionForPlayerAsync`, `GetJoinData`, `TeleportData`, `GetPlayerData`, `UserId`, `unknown`, `invokeClient`, `getPlatform`, `pairs`, `BasePlayerData`, `typeof`, `copyTable`, `pcall`, `CountryCode`, `Console`, `uwp_console`, `Mobile`, `uwp_mobile`, `Desktop`, `uwp_desktop`, `Platform`, ` 0.0.0`, `OS`, `event_validation`, `player_joined`, `string_empty_or_null`, `country_code`, `addSdkErrorEvent`, `getCustomUserId`, `isStringNullOrEmpty`, `Using custom id: `, `CustomUserId`, `OnPlayerReadyEvent`, `WaitForChild`, `Fire`, `_availableGamepasses`, `UserOwnsGamePassAsync`, `Enum`, `InfoType`, `GamePass`, `GetProductInfo`, `PriceInRobux`, `Name`, `unpack`, `Player initialization queue called #`, ` events`, `PlayerJoined`, `DataStoreQueue`, `RemoveKey`, `PlayerRemoved`, `ProductId`, `Product`, `PlayerId`, `DeveloperProduct`, `CurrencySpent`, `ProcessReceiptCallback`, `GamepassPurchased`, `gameKey`, `secretKey`, `initialize`, `initServer`, `Initialize '`, `' option missing`, `e`, `enableInfoLog`, `enableVerboseLog`, `availableCustomDimensions01`, `availableCustomDimensions02`, `availableCustomDimensions03`, `availableResourceCurrencies`, `availableResourceItemTypes`, `build`, `availableGamepasses`, `enableDebugLog`, `automaticSendBusinessEvents`, `reportErrors`, `useCustomUserId`, `SDK already initialized. Can only be called once.`, `validateKeys`, `SDK failed initialize. Game key or secret key is invalid. Can only contain characters A-z 0-9, gameKey is 32 length, secretKey is 40 length. Failed keys - gameKey: `, `, secretKey: `, `GameKey`, `SecretKey`, `PlayerAdded`, `Connect`, `PlayerRemoving`, `GetPlayers`, `coroutine`, `wrap`, `task`, `spawn`, `Server initialization queue called #`, `processEventQueue`, `os`, `time`, `GetErrorDataStore`, `wait`, `AutoSaveData`, `currentCount`, `countInDS`, `IncrementErrorCount`, `(null)`, `: message=`, `, trace=`, `sub`, `[LocalPlayer]`, `EGAErrorSeverity`, `error`, `ErrorHandler`, `GetFullName`, `ErrorHandlerFromServer`, `ErrorHandlerFromClient`, `require`, `script`, `GAResourceFlowType`, `GAProgressionStatus`, `GAErrorSeverity`, `EGAResourceFlowType`, `EGAProgressionStatus`, `Logger`, `Threading`, `State`, `Validation`, `Store`, `Events`, `Utilities`, `game`, `Players`, `GetService`, `MarketplaceService`, `RunService`, `ReplicatedStorage`, `LocalizationService`, `ScriptContext`, `Postie`, `GameAnalyticsRemoteConfigs`, `FindFirstChild`, `Instance`, `new`, `RemoteEvent`, `Parent`, `BindableEvent`, `Error`, `GameAnalyticsError`, `OnServerEvent`, `PromptGamePassPurchaseFinished`

### [1298] ReplicatedStorage.Packages.GameAnalytics.GameAnalytics.Events
`ModuleScript` · bytecode v9 · 11006 bytes · 189 constants
- **Remotes:** Platform, Store
- **Services:** HttpService, game
- **Key API:** GetService
- Constants: `GetPlayerDataFromCache`, `CurrentCustomDimension01`, `custom_01`, `CurrentCustomDimension02`, `custom_02`, `CurrentCustomDimension03`, `custom_03`, `addDimensionsToEvent`, `os`, `time`, `ClientServerTimeOffset`, `validateClientTs`, `getClientTsAdjusted`, `pairs`, `Length`, `DummyId`, `OS`, `uwp_desktop 0.0.0`, `Platform`, `uwp_desktop`, `SessionID`, `Sessions`, `CustomUserId`, `Server`, `v`, `tostring`, `user_id`, `client_ts`, `roblox `, `SdkVersion`, `sdk_version`, `os_version`, `unknown`, `manufacturer`, `device`, `platform`, `session_id`, `session_num`, `CountryCode`, `isStringNullOrEmpty`, `country_code`, `Build`, `validateBuild`, `build`, `Configurations`, `configurations`, `AbId`, `ab_id`, `AbVariantId`, `ab_variant_id`, `getEventAnnotations`, `JSONEncode`, `Event added to queue: `, `ii`, `EventsQueue`, `addEventToStore`, `More than %d events queued! Sending %d.`, `format`, `w`, `DROPPING EVENTS: More than %d events queued!`, `table`, `create`, `math`, `min`, `dequeueMaxEvents`, `Event queue: No events to send`, `i`, `Event queue: Sending `, ` events.`, `GameKey`, `SecretKey`, `sendEventsInArray`, `statusCode`, `body`, `EGAHTTPApiResponse`, `Ok`, `Event queue: `, ` events sent.`, `NoResponse`, `Event queue: Failed to send events to collector - Retrying next time`, `BadRequest`, ` events sent. `, ` events failed GA server validation.`, `Event queue: Failed to send events.`, `processEvents`, `processEventQueue`, `ProcessEventsInterval`, `scheduleTimer`, `Validation fail - configure build: Cannot be null, empty or above 32 length. String: `, `Set build version: `, `setBuild`, `validateResourceCurrencies`, `_availableResourceCurrencies`, `Set available resource currencies: (`, `concat`, `, `, `)`, `setAvailableResourceCurrencies`, `_availableResourceItemTypes`, `Set available resource item types: (`, `setAvailableResourceItemTypes`, `user`, `category`, `Add SESSION START event`, `addSessionStartEvent`, `SessionStart`, `Session length was calculated to be less then 0. Should not be possible. Resetting to 0.`, `session_end`, `length`, `Add SESSION END event.`, `addSessionEndEvent`, `validateBusinessEvent`, `Transactions`, `:`, `event_id`, `business`, `currency`, `amount`, `transaction_num`, `cart_type`, `Add BUSINESS event: {currency:`, `, amount:`, `, itemType:`, `, itemId:`, `, cartType:`, `}`, `addBusinessEvent`, `validateResourceEvent`, `Sink`, `resource`, `Add RESOURCE event: {currency:`, `addResourceEvent`, `validateProgressionEvent`, `progression`, `Start`, `score`, `Fail`, `ProgressionTries`, `Complete`, `attempt_num`, `Add PROGRESSION event: {status:`, `, progression01:`, `, progression02:`, `, progression03:`, `, score:`, `, attempt:`, `addProgressionEvent`, `validateDesignEvent`, `design`, `value`, `Add DESIGN event: {eventId:`, `, value:`, `addDesignEvent`, `validateErrorEvent`, `error`, `severity`, `message`, `Add ERROR event: {severity:`, `, message:`, `addErrorEvent`, `sdk_error`, `error_category`, `error_area`, `error_action`, `error_parameter`, `reason`, `Add SDK ERROR event: {error_category:`, `, error_area:`, `, error_action:`, `addSdkErrorEvent`, `require`, `script`, `Parent`, `Store`, `Logger`, `Version`, `Validation`, `Threading`, `HttpApi`, `Utilities`, `GAResourceFlowType`, `GAProgressionStatus`, `GAErrorSeverity`, `game`, `HttpService`, `GetService`, `GenerateGUID`, `lower`

### [1299] ReplicatedStorage.Packages.GameAnalytics.GameAnalytics.GAErrorSeverity
`ModuleScript` · bytecode v9 · 471 bytes · 13 constants
- Constants: `error`, `Attempt to modify read-only table: `, `, key=`, `, value=`, `__newindex`, `__index`, `__metatable`, `setmetatable`, `readonlytable`, `debug`, `info`, `warning`, `critical`

### [1300] ReplicatedStorage.Packages.GameAnalytics.GameAnalytics.GAProgressionStatus
`ModuleScript` · bytecode v9 · 449 bytes · 12 constants
- Constants: `error`, `Attempt to modify read-only table: `, `, key=`, `, value=`, `__newindex`, `__index`, `__metatable`, `setmetatable`, `readonlytable`, `Start`, `Complete`, `Fail`

### [1301] ReplicatedStorage.Packages.GameAnalytics.GameAnalytics.GAResourceFlowType
`ModuleScript` · bytecode v9 · 434 bytes · 11 constants
- Constants: `error`, `Attempt to modify read-only table: `, `, key=`, `, value=`, `__newindex`, `__index`, `__metatable`, `setmetatable`, `readonlytable`, `Source`, `Sink`

### [1302] ReplicatedStorage.Packages.GameAnalytics.GameAnalytics.HttpApi
`ModuleScript` · bytecode v9 · 6865 bytes · 112 constants
- **Remotes:** Platform
- **Services:** HttpService, RunService, game
- **Key API:** GetService
- Constants: `tostring`, `CustomUserId`, `user_id`, `roblox `, `SdkVersion`, `sdk_version`, `OS`, `os_version`, `Platform`, `platform`, `build`, `Sessions`, `session_num`, `random_salt`, `getInitAnnotations`, `Error encoding, invalid SecretKey`, `w`, `hmac`, `sha256`, `IsStudio`, `16813a12f718bc5c620f56944e1abc3ea13ccbac`, `base64_encode`, `encode`, `StatusCode`, `Body`, ` request. failed. Might be no connection. Status code: `, `d`, `EGAHTTPApiResponse`, `NoResponse`, `Ok`, `Created`, ` request. 401 - Unauthorized.`, `Unauthorized`, ` request. 400 - Bad Request.`, `BadRequest`, ` request. 500 - Internal Server Error.`, `InternalServerError`, `UnknownResponseCode`, `processRequestResponse`, `Url`, `Method`, `POST`, `Headers`, `Authorization`, `application/json`, `Content-Type`, `RequestAsync`, `JSONDecode`, `/`, `initializeUrlPath`, `?game_key=`, `&interval_seconds=0&configs_hash=`, `ConfigsHash`, `/5c6bcb5402204249437fb5a7a80a4959/`, `Sending 'init' URL: `, `JSONEncode`, `"country_code":"unknown"`, `"country_code":null`, `gsub`, `init payload: `, `pcall`, `Failed Init Call. error: `, `statusCode`, `body`, `init request content: `, `Init`, `Failed Init Call. URL: `, `, JSONString: `, `, Authorization: `, `Failed Init Call. Json decoding failed: `, `JsonDecodeFailed`, `Failed Init Call. Bad request. Response: `, `validateAndCleanInitRequestResponse`, `BadResponse`, `initRequest`, `sendEventsInArray called with missing eventArray`, `eventsUrlPath`, `Sending 'events' URL: `, `Failed Events Call. error: `, `body: `, `Events`, `Failed Events Call. URL: `, `Failed Events Call. Json decoding failed`, `Failed Events Call. Bad request. Response: `, `sendEventsInArray`, `game`, `RunService`, `GetService`, `require`, `script`, `Parent`, `Validation`, `Version`, `HashLib`, `protocol`, `https`, `hostName`, `api.gameanalytics.com`, `version`, `v2`, `remoteConfigsVersion`, `v1`, `init`, `events`, `RequestTimeout`, `JsonEncodeFailed`, `HttpService`, `Logger`, `://`, `sandbox-`, `/remote_configs/`

### [1303] ReplicatedStorage.Packages.GameAnalytics.GameAnalytics.HttpApi.HashLib
`ModuleScript` · bytecode v9 · 30461 bytes · 108 constants
- Constants: `string`, `byte`, `sha256_feed_64`, `sha512_feed_128`, `md5_feed_64`, `sha1_feed_64`, `keccak_feed`, `table`, `create`, `math`, `max`, `min`, `floor`, `mul`, `next_bit`, `sub`, `error`, `Adding more chunks is not allowed after receiving the result`, `�`, `rep`, ` `, `char`, `concat`, `format`, `%08x`, `partial`, `sha256ext`, `ceil`, `pack`, `unpack`, `sha512ext`, `gsub`, `(..)(..)(..)(..)`, `%4%3%2%1`, `md5`, `sha1`, `        `, `(..)(..)(..)(..)(..)(..)(..)(..)`, `%8%7%6%5%4%3%2%1`, `get_next_qwords_of_digest`, `get_next_part_of_digest`, `type`, `number`, `Argument 'digest_size_in_bytes' must be a number`, `keccak`, `tonumber`, `HexToBinFunction`, `%x%x`, `hex2bin`, `bin2base64`, `gmatch`, `%s+`, `()(.)`, `base642bin`, `.`, `pad_and_xor`, `\`, `Unknown hash function`, `6`, `hmac`, `sha224`, `sha256`, `sha512_224`, `sha512_256`, `sha384`, `sha512`, `sha3_224`, `sha3_256`, `sha3_384`, `sha3_512`, `shake128`, `shake256`, `require`, `script`, `Base64`, `ipairs`, `bit32`, `band`, `bor`, `bxor`, `lshift`, `rshift`, `lrotate`, `rrotate`, `sqrt`, `SHA-512/`, `tostring`, `X`, `sin`, `abs`, `modf`, `+`, `-`, `/`, `_`, `=`, `AZ`, `az`, `09`, `%02x`, `hex_to_bin`, `base64_to_bin`, `bin_to_base64`, `base64_encode`, `base64_decode`, `Encode`, `Decode`

### [1304] ReplicatedStorage.Packages.GameAnalytics.GameAnalytics.HttpApi.HashLib.Base64
`ModuleScript` · bytecode v9 · 2474 bytes · 14 constants
- Constants: `string`, `byte`, `table`, `unpack`, `char`, `concat`, `Encode`, `Decode`, `insert`, `ipairs`, `bit32`, `rshift`, `lshift`, `band`

### [1305] ReplicatedStorage.Packages.GameAnalytics.GameAnalytics.Logger
`ModuleScript` · bytecode v9 · 1128 bytes · 24 constants
- **Services:** RunService, game
- **Key API:** GetService
- Constants: `_debugEnabled`, `setDebugLog`, `_infoLogEnabled`, `setInfoLog`, `_infoLogAdvancedEnabled`, `setVerboseLog`, `Info/GameAnalytics: `, `print`, `i`, `Warning/GameAnalytics: `, `warn`, `w`, `Error/GameAnalytics: `, `error`, `task`, `spawn`, `e`, `Debug/GameAnalytics: `, `d`, `Verbose/GameAnalytics: `, `ii`, `game`, `RunService`, `GetService`

### [1306] ReplicatedStorage.Packages.GameAnalytics.GameAnalytics.Postie
`ModuleScript` · bytecode v9 · 2678 bytes · 33 constants
- **Services:** HttpService, ReplicatedStorage, RunService, game
- **Key API:** Connect, FindFirstChild, FireServer, GetService, OnClientEvent, new
- Constants: `task`, `spawn`, `Postie.invokeClient can only be called from the server`, `assert`, `coroutine`, `running`, `GenerateGUID`, `delay`, `FireClient`, `yield`, `invokeClient`, `Postie.invokeServer can only be called from the client`, `FireServer`, `invokeServer`, `setCallback`, `getCallback`, `game`, `HttpService`, `GetService`, `RunService`, `ReplicatedStorage`, `PostieSent`, `FindFirstChild`, `Instance`, `new`, `RemoteEvent`, `Name`, `Parent`, `PostieReceived`, `IsServer`, `OnServerEvent`, `Connect`, `OnClientEvent`

### [1307] ReplicatedStorage.Packages.GameAnalytics.GameAnalytics.State
`ModuleScript` · bytecode v9 · 7670 bytes · 123 constants
- **Remotes:** Store
- **Services:** HttpService, ReplicatedStorage, game
- **Key API:** GetService, WaitForChild
- Constants: `GetPlayerDataFromCache`, `os`, `time`, `ClientServerTimeOffset`, `validateClientTs`, `getClientTsAdjusted`, `UserId`, `SdkConfig`, `configs`, `pairs`, `key`, `start_ts`, `end_ts`, `value`, `Configurations`, `configuration added: key=`, `, value=`, `d`, `Remote configs populated`, `i`, `RemoteConfigsIsReady`, `game`, `ReplicatedStorage`, `GetService`, `GameAnalyticsRemoteConfigs`, `WaitForChild`, `FireClient`, `populateConfigurations`, `SessionStart`, `sessionIsStarted`, `InitAuthorized`, `isEnabled`, `_availableCustomDimensions01`, `CurrentCustomDimension01`, `validateDimension`, `Invalid dimension01 found in variable. Setting to nil. Invalid dimension: `, `_availableCustomDimensions02`, `CurrentCustomDimension02`, `Invalid dimension02 found in variable. Setting to nil. Invalid dimension: `, `_availableCustomDimensions03`, `CurrentCustomDimension03`, `Invalid dimension03 found in variable. Setting to nil. Invalid dimension: `, `validateAndFixCurrentDimensions`, `validateCustomDimensions`, `Set available custom01 dimension values: (`, `table`, `concat`, `, `, `)`, `setAvailableCustomDimensions01`, `Set available custom02 dimension values: (`, `setAvailableCustomDimensions02`, `Set available custom03 dimension values: (`, `setAvailableCustomDimensions03`, `_availableGamepasses`, `Set available game passes: (`, `setAvailableGamepasses`, `_enableEventSubmission`, `setEventSubmission`, `isEventSubmissionEnabled`, `setCustomDimension01`, `setCustomDimension02`, `setCustomDimension03`, `Starting a new session.`, `GameKey`, `SecretKey`, `Build`, `initRequest`, `statusCode`, `body`, `EGAHTTPApiResponse`, `Ok`, `Created`, `server_ts`, `time_offset`, `ab_id`, `ab_variant_id`, `Unauthorized`, `Initialize SDK failed - Unauthorized`, `w`, `NoResponse`, `RequestTimeout`, `Init call (session start) failed - no response. Could be offline or timeout.`, `BadResponse`, `JsonEncodeFailed`, `JsonDecodeFailed`, `Init call (session start) failed - bad response. Could be bad response from proxy or GA servers.`, `BadRequest`, `UnknownResponseCode`, `Init call (session start) failed - bad request or unknown response.`, `configs_hash`, `ConfigsHash`, `AbId`, `AbVariantId`, `Could not start session: SDK is disabled.`, `SessionID`, `string`, `lower`, `GenerateGUID`, `addSessionStartEvent`, `startNewSession`, `Initialized`, `Ending session.`, `addSessionEndEvent`, `PlayerCache`, `endSession`, `getRemoteConfigsStringValue`, `isRemoteConfigsReady`, `JSONEncode`, `getRemoteConfigsContentAsString`, `require`, `script`, `Parent`, `Validation`, `Logger`, `HttpApi`, `Store`, `Events`, `HttpService`, `ReportErrors`, `UseCustomUserId`, `AutomaticSendBusinessEvents`

### [1308] ReplicatedStorage.Packages.GameAnalytics.GameAnalytics.Store
`ModuleScript` · bytecode v9 · 2522 bytes · 51 constants
- **Services:** RunService, game
- **Key API:** GetService
- Constants: `IsStudio`, `PlayerDS`, `GetAsync`, `UserId`, `AddRequest`, `GetPlayerData`, `PlayerCache`, `tonumber`, `tostring`, `GetPlayerDataFromCache`, `GA_ErrorDS_1.0.0`, `GetDataStore`, `pcall`, `GetErrorDataStore`, `SetAsync`, `pairs`, `DataToSave`, `SavePlayerData`, `IncrementAsync`, `_`, `IncrementErrorCount`, `game`, `DataStoreService`, `GetService`, `RunService`, `require`, `script`, `DataStoreQueue`, `AutoSaveData`, `BasePlayerData`, `EventsQueue`, `GA_PlayerDS_1.0.0`, `Sessions`, `Transactions`, `ProgressionTries`, `CurrentCustomDimension01`, `CurrentCustomDimension02`, `CurrentCustomDimension03`, `ConfigsHash`, `AbId`, `AbVariantId`, `InitAuthorized`, `SdkConfig`, `ClientServerTimeOffset`, `Configurations`, `RemoteConfigsIsReady`, `PlayerTeleporting`, `OwnedGamepasses`, `CountryCode`, `CustomUserId`

### [1309] ReplicatedStorage.Packages.GameAnalytics.GameAnalytics.Store.DataStoreQueue
`ModuleScript` · bytecode v9 · 1458 bytes · 26 constants
- **Key API:** Fire, new
- Constants: `Key`, `DateTime`, `now`, `UnixTimestamp`, `pcall`, `Func`, `warn`, `Delay`, `task`, `wait`, `Event`, `Fire`, `Process`, `QR`, `Queue`, `table`, `remove`, `delay`, `Instance`, `new`, `BindableEvent`, `insert`, `Wait`, `AddRequest`, `RemoveKey`, `spawn`

### [1310] ReplicatedStorage.Packages.GameAnalytics.GameAnalytics.Threading
`ModuleScript` · bytecode v9 · 2083 bytes · 32 constants
- **Services:** RunService, game
- **Key API:** GetService
- Constants: `tick`, `_hasScheduledBlockRun`, `_scheduledBlock`, `deadline`, `getScheduledBlock`, `Starting GA thread`, `d`, `_endThread`, `_canSafelyClose`, `_blocks`, `pairs`, `pcall`, `block`, `e`, `task`, `wait`, `GA thread stopped`, `IsStudio`, `spawn`, `game`, `BindToClose`, `run`, `_isRunning`, `scheduleTimer`, `performTaskOnGAThread`, `stopThread`, `require`, `script`, `Parent`, `Logger`, `RunService`, `GetService`

### [1311] ReplicatedStorage.Packages.GameAnalytics.GameAnalytics.Utilities
`ModuleScript` · bytecode v9 · 557 bytes · 7 constants
- Constants: `isStringNullOrEmpty`, `ipairs`, `stringArrayContainsString`, `pairs`, `typeof`, `table`, `copyTable`

### [1312] ReplicatedStorage.Packages.GameAnalytics.GameAnalytics.Validation
`ModuleScript` · bytecode v9 · 11044 bytes · 101 constants
- Constants: `custom dimensions`, `validateArrayOfStrings`, `validateCustomDimensions`, `isStringNullOrEmpty`, `stringArrayContainsString`, `validateDimension`, `resource currencies`, `pairs`, `string`, `find`, `^[A-Za-z]+$`, `resource currencies validation failed: a resource currency can only be A-Z, a-z. String was: `, `w`, `validateResourceCurrencies`, `resource item types`, `validateEventPartCharacters`, `resource item types validation failed: a resource item type cannot contain other characters than A-z, 0-9, -_., ()!?. String was: `, `validateResourceItemTypes`, `^[A-Za-z0-9%s%-_%.%(%)!%?]+$`, `Array`, ` validation failed: array cannot be nil.`, ` validation failed: array cannot be empty.`, ` validation failed: array cannot exceed `, `tostring`, ` values. It has `, ` values.`, `ipairs`, ` validation failed: contained an empty string.`, ` validation failed: a string exceeded max allowed length (which is: `, `). String was: `, `validateShortString`, `validateBuild`, `^[A-Za-z0-9]+$`, `validateKeys`, `validateInitRequestResponse failed - no response dictionary.`, `server_ts`, `configs`, `ab_id`, `ab_variant_id`, `validateAndCleanInitRequestResponse`, `validateClientTs`, `^[A-Z]+$`, `validateCurrency`, `validateEventPartLength`, `Validation fail - business event - currency: Cannot be (null) and need to be A-Z, 3 characters and in the standard at openexchangerates.org. Failed currency: `, `Validation fail - business event - amount: Cannot be less then 0. Failed amount: `, `Validation fail - business event - cartType. Cannot be above 32 length. String: `, `Validation fail - business event - itemType: Cannot be (null), empty or above 64 characters. String: `, `Validation fail - business event - itemType: Cannot contain other characters than A-z, 0-9, -_., ()!?. String: `, `Validation fail - business event - itemId. Cannot be (null), empty or above 64 characters. String: `, `Validation fail - business event - itemId: Cannot contain other characters than A-z, 0-9, -_., ()!?. String: `, `validateBusinessEvent`, `Source`, `Sink`, `Validation fail - resource event - flowType: Invalid flow type `, `Validation fail - resource event - currency: Cannot be (null)`, `Validation fail - resource event - currency: Not found in list of pre-defined available resource currencies. String: `, `Validation fail - resource event - amount: Float amount cannot be 0 or negative. Value: `, `Validation fail - resource event - itemType: Cannot be (null)`, `Validation fail - resource event - itemType: Cannot be (null), empty or above 64 characters. String: `, `Validation fail - resource event - itemType: Cannot contain other characters than A-z, 0-9, -_., ()!?. String: `, `Validation fail - resource event - itemType: Not found in list of pre-defined available resource itemTypes. String: `, `Validation fail - resource event - itemId: Cannot be (null), empty or above 64 characters. String: `, `Validation fail - resource event - itemId: Cannot contain other characters than A-z, 0-9, -_., ()!?. String: `, `validateResourceEvent`, `Start`, `Complete`, `Fail`, `Validation fail - progression event: Invalid progression status `, `Validation fail - progression event: 03 found but 01+02 are invalid. Progression must be set as either 01, 01+02 or 01+02+03.`, `Validation fail - progression event: 02 found but not 01. Progression must be set as either 01, 01+02 or 01+02+03`, `Validation fail - progression event: progression01 not valid. Progressions must be set as either 01, 01+02 or 01+02+03`, `Validation fail - progression event - progression01: Cannot be (null), empty or above 64 characters. String: `, `Validation fail - progression event - progression01: Cannot contain other characters than A-z, 0-9, -_., ()!?. String: `, `Validation fail - progression event - progression02: Cannot be empty or above 64 characters. String: `, `Validation fail - progression event - progression02: Cannot contain other characters than A-z, 0-9, -_., ()!?. String: `, `Validation fail - progression event - progression03: Cannot be empty or above 64 characters. String: `, `Validation fail - progression event - progression03: Cannot contain other characters than A-z, 0-9, -_., ()!?. String: `, `validateProgressionEvent`, `gmatch`, `([^:]+)`, `validateEventIdLength`, `validateEventIdCharacters`, `Validation fail - design event - eventId: Cannot be (null) or empty. Only 5 event parts allowed seperated by :. Each part need to be 32 characters or less. String: `, `Validation fail - design event - eventId: Non valid characters. Only allowed A-z, 0-9, -_., ()!?. String: `, `validateDesignEvent`, `validateLongString`, `debug`, `info`, `warning`, `error`, `critical`, `Validation fail - error event - severity: Severity was unsupported value `, `Validation fail - error event - message: Message cannot be above 8192 characters.`, `validateErrorEvent`, `require`, `script`, `Parent`, `Logger`, `Utilities`

### [1313] ReplicatedStorage.Packages.GameAnalytics.GameAnalytics.Version
`ModuleScript` · bytecode v9 · 67 bytes · 2 constants
- Constants: `SdkVersion`, `2.2.3`

### [1314] ReplicatedStorage.Packages.GameAnalytics.GameAnalyticsClient
`ModuleScript` · bytecode v9 · 1098 bytes · 27 constants
- **Services:** ReplicatedStorage, UserInputService, game
- **Key API:** Connect, FireServer, GetService, WaitForChild
- Constants: `GetFullName`, `pcall`, `GameAnalyticsError`, `FireServer`, `IsTenFootInterface`, `Console`, `TouchEnabled`, `MouseEnabled`, `Mobile`, `Desktop`, `getPlatform`, `require`, `script`, `Parent`, `GameAnalytics`, `Postie`, `Error`, `Connect`, `setCallback`, `initClient`, `game`, `GuiService`, `GetService`, `ReplicatedStorage`, `UserInputService`, `WaitForChild`, `ScriptContext`

### [1315] ReplicatedStorage.Packages.JSONDencode
`ModuleScript` · bytecode v9 · 12295 bytes · 95 constants
- Constants: `[%z-\"]`, `"`, `writeString`, `string`, `number`, `null`, `boolean`, `true`, `false`, `nil`, `table`, `error`, `JSON encode error: unsupported value type %q`, `JSON encode error: nesting exceeds %d levels`, `JSON encode error: circular table reference`, `[`, `,`, `]`, `{`, `JSON encode error: object keys must be strings`, `:`, `}`, `[]`, `encode`, `JSON decode error at byte %d: %s`, `fail`, `skipWhitespace`, `incomplete Unicode escape`, `invalid hexadecimal digit`, `hexDigit`, `hexCodeUnit`, `unescaped control character in string`, `unterminated string`, `unterminated escape sequence`, `high surrogate must be followed by a low surrogate`, `invalid low surrogate`, `unexpected low surrogate`, `invalid escape sequence`, `parseString`, `leading zero in number`, `invalid number`, `expected digit after decimal point`, `expected exponent digits`, `number is outside the supported range`, `parseNumber`, `nesting exceeds %d levels`, `expected comma or closing bracket`, `expected a string property name`, `expected colon after property name`, `expected comma or closing brace`, `expected a value`, `unexpected token`, `JSON decode error: expected string, got %s`, `trailing content`, `decode`, `JSONDencode.Object expects a table or nil`, `Object`, `IsObject`, `JSONEncode`, `JSONDecode`, `byte`, `char`, `find`, `format`, `gsub`, `sub`, `concat`, `create`, `tonumber`, `tostring`, `type`, `pairs`, `next`, `getmetatable`, `setmetatable`, `utf8`, `\"`, `\\`, `\`, `\b`, ``, `\f`, `\n`, `\r`, `\t`, `\u%04x`, `/`, `Encode`, `Decode`, `freeze`

### [1316] ReplicatedStorage.Packages.Loader
`ModuleScript` · bytecode v9 · 180 bytes · 6 constants
- Constants: `require`, `loader`, `sleitnick_loader@2.0.0`, `script`, `Parent`, `_Index`

### [1317] ReplicatedStorage.Packages.Loader.Loader
`Script` · bytecode v9 · 315 bytes · 8 constants
- **Key API:** SetAttribute
- Constants: `script`, `Target`, `Value`, `Changed`, `Wait`, `require`, `Loaded`, `SetAttribute`

### [1318] ReplicatedStorage.Packages.Moonlite
`ModuleScript` · bytecode v9 · 18194 bytes · 214 constants
- **Remotes:** Set
- **Services:** HttpService, ReplicatedStorage, RunService, game, workspace
- **Key API:** Connect, Destroy, FindFirstChild, Fire, GetAttribute, GetChildren, GetDescendants, GetService, IsA, Play, Stop, new
- Constants: `type`, `number`, `math`, `lerp`, `Lerp`, `table`, `concat`, `InstanceNames`, `.`, `toPath`, `InstanceTypes`, `game`, `CoreGui`, `ReplicatedStorage`, `FindFirstChild`, `ClassName`, `resolveAnimPath`, `GetDescendants`, `Motor6D`, `IsA`, `Active`, `Part1`, `Name`, `Joint`, `Children`, `Bone`, `Part0`, `Parent`, `%*.%*`, `format`, `resolveJoints`, `Type`, `Params`, `StringValue`, `Value`, `assert`, `GetChildren`, `ValueBase`, `parseEase`, `Style`, `No style in legacy ease!`, `Direction`, `No direction in legacy ease!`, `parseEaseOld`, `tonumber`, `EnumType`, `Enum`, `Vector2`, `new`, `X`, `Y`, `ColorSequence`, `NumberSequence`, `NumberRange`, `GetAttribute`, `readValue`, `Get`, `_scratch`, `pcall`, `Default`, `getPropValue`, `Set`, `setPropValue`, `Bad frame number`, `Values`, `No value folder!`, `0`, `No starting value!`, `max`, `Eases`, `Ease`, `Bad index on ease @%*`, `GetFullName`, `FrameIndex`, `FrameCount`, `parseKeyframePack`, `insert`, `sort`, `Next`, `Prev`, `Time`, `unpackKeyframes`, `readValueBase`, `Inverse`, `_data`, `_save`, `This track is already compiled from source`, `find`, `Items`, `Path`, `ItemType`, `Override`, `_root`, `tostring`, `Rig`, `MarkerTrack`, `_joint`, `_hier`, `default`, `_keyframes`, `Transform`, `Static`, `Sequence`, `CFrame`, `identity`, `Props`, `Target`, `Folder`, `_markers`, `name`, `width`, `KFMarkers`, `Val`, `StartMarkers`, `EndMarkers`, `Frames`, `min`, `compileItem`, `Keypoints`, `Min`, `typeof`, `getInterpolator`, `expandFrames`, `_buffer`, `_elements`, `FrameRate`, `compileFrames`, `clear`, `_compiled`, `compileRouting`, `RestoreDefaults`, `workspace`, `CurrentCamera`, `AttachToPart`, `LookAtPart`, `restoreTrack`, `TimePosition`, `floor`, `Looped`, `CurrentFrame`, `_onLoop`, `Fire`, `_completed`, `PlaybackState`, `Completed`, `_locks`, `_markerSignals`, `_endMarkerSignals`, `stepTrack`, `Instance`, `BindableEvent`, `JSONDecode`, `OnLoop`, `_overrides`, `Event`, `Information`, `Length`, `FPS`, `setmetatable`, `require`, `_source`, `_moduleInfo`, `CreatePlayer`, `debug`, `profilebegin`, `Compile Frames`, `Compiled`, `profileend`, `Compile`, `Destroy`, `IsPlaying`, `GetTimeLength`, `GetMarkerReachedSignal`, `GetMarkerEndedSignal`, `GetSetting`, `SetSetting`, `clone`, `GetElements`, `LockElement`, `next`, `UnlockElement`, `IsElementLocked`, `lower`, `ReplaceElementByPath`, `FindElement`, `FindElementOfType`, `task`, `spawn`, `Cancelled`, `Stop`, `Reset`, `Track is not compiled.`, `Playing`, `Play`, `script`, `Types`, `Specials`, `EaseFuncs`, `RunService`, `GetService`, `HttpService`, `IsServer`, `IsStudio`, `warn`, `Moonlite should NOT be used on the server! Rig transforms will not be replicated.`, `__index`, `boolean`, `string`, `nil`, `__mode`, `k`, `_resolveAnimPath`, `PreSimulation`, `Connect`

### [1319] ReplicatedStorage.Packages.Moonlite.EaseFuncs
`ModuleScript` · bytecode v9 · 10215 bytes · 77 constants
- **Services:** HttpService, game
- **Key API:** GetService
- Constants: `Linear`, `Constant`, `math`, `cos`, `InSine`, `sin`, `OutSine`, `InOutSine`, `OutInSine`, `pow`, `InQuad`, `OutQuad`, `InOutQuad`, `OutInQuad`, `InCubic`, `OutCubic`, `InOutCubic`, `OutInCubic`, `InQuart`, `OutQuart`, `InOutQuart`, `OutInQuart`, `InQuint`, `OutQuint`, `InOutQuint`, `OutInQuint`, `InSextic`, `OutSextic`, `InOutSextic`, `OutInSextic`, `InExpo`, `OutExpo`, `InOutExpo`, `OutInExpo`, `sqrt`, `InCirc`, `OutCirc`, `InOutCirc`, `OutInCirc`, `InBack`, `OutBack`, `InOutBack`, `OutInBack`, `OutBounce`, `InBounce`, `InOutBounce`, `OutInBounce`, `abs`, `ElasticBlend`, `ElasticBend`, `asin`, `InElastic`, `OutElastic`, `InOutElastic`, `OutInElastic`, `%*%*%*%*%*`, `Type`, `Params`, `Direction`, `Overshoot`, `Amplitude`, `Period`, `format`, `hash`, `In`, `%*%*`, `Elastic`, `Back`, `get`, `script`, `Parent`, `require`, `Types`, `game`, `HttpService`, `GetService`, `Get`

### [1320] ReplicatedStorage.Packages.Moonlite.Moonlite
`Script` · bytecode v9 · 315 bytes · 8 constants
- **Key API:** SetAttribute
- Constants: `script`, `Target`, `Value`, `Changed`, `Wait`, `require`, `Loaded`, `SetAttribute`

### [1321] ReplicatedStorage.Packages.Moonlite.Specials
`ModuleScript` · bytecode v9 · 10642 bytes · 118 constants
- **Remotes:** Set
- **Services:** RunService, game, workspace
- **Key API:** Clone, Connect, Destroy, GetAttribute, GetDescendants, GetService, IsA, Play, SetAttribute, Stop, new
- Constants: `__moonlite_%*`, `format`, `GetAttribute`, `getValue`, `SetAttribute`, `setValue`, `Get`, `Set`, `assert`, `BoundProp`, `Default`, `LazyAction`, `_cameraAttachToPart`, `_cameraLookAtPart`, `CFrame`, `new`, `Position`, `updateCamera`, `_cameraRenderBound`, `MoonliteRenderCamera`, `BindToRenderStep`, `KeepCameraType`, `Enum`, `CameraType`, `Scriptable`, `UnbindFromRenderStep`, `Custom`, `setCameraActive`, `_activeCamera`, `_updateCamera`, `workspace`, `Terrain`, `GetMaterialColor`, `SetMaterialColor`, `GetPivot`, `PivotTo`, `__moonlite_Color`, `GetDescendants`, `BasePart`, `IsA`, `Color`, `GetScale`, `ScaleTo`, `__moonlite_Reflectance`, `Reflectance`, `__moonlite_BaseReflectance`, `__moonlite_Transparency`, `LocalTransparencyModifier`, `pcall`, `AddAccessory`, `ChangeState`, `HumanoidStateType`, `None`, `EquipTool`, `Jump`, `MoveTo`, `MoveToDefault`, `typeof`, `Vector3`, `RootPart`, `Move`, `MoveDefault`, `LookVector`, `PlayEmote`, `RemoveAccessories`, `Sit`, `TakeDamage`, `UnequipTools`, `Clear`, `Emit`, `EmitCount`, `type`, `number`, `Clone`, `Parent`, `PlayOnRemove`, `Destroy`, `TimePosition`, `SetTime`, `Play`, `Resume`, `Pause`, `Stop`, `_target`, `ClassName`, `_work`, `rawset`, `__index`, `setmetatable`, `Destroying`, `Connect`, `get`, `pairs`, `static`, `script`, `game`, `RunService`, `GetService`, `require`, `Types`, `Camera`, `Humanoid`, `ParticleEmitter`, `Sound`, `AttachToPart`, `LookAtPart`, `PlayOnce`, `Material`, `GetEnumItems`, `MC_%*`, `Name`, `Color3`, `Scale`, `Transparency`, `Model`, `Static`, `Index`

### [1323] ReplicatedStorage.Packages.Net
`ModuleScript` · bytecode v9 · 174 bytes · 6 constants
- Constants: `require`, `net`, `sleitnick_net@0.1.0`, `script`, `Parent`, `_Index`

### [1324] ReplicatedStorage.Packages.Net.Net
`Script` · bytecode v9 · 315 bytes · 8 constants
- **Key API:** SetAttribute
- Constants: `script`, `Target`, `Value`, `Changed`, `Wait`, `require`, `Loaded`, `SetAttribute`

### [1325] ReplicatedStorage.Packages.Observers
`ModuleScript` · bytecode v9 · 675 bytes · 11 constants
- Constants: `observeTag`, `observeTagNoAncestry`, `observeAttribute`, `observeProperty`, `observePlayer`, `observeCharacter`, `observeCharacters`, `observeChildren`, `observeDescendants`, `require`, `script`

### [1326] ReplicatedStorage.Packages.Observers.Observers
`Script` · bytecode v9 · 315 bytes · 8 constants
- **Key API:** SetAttribute
- Constants: `script`, `Target`, `Value`, `Changed`, `Wait`, `require`, `Loaded`, `SetAttribute`

### [1327] ReplicatedStorage.Packages.Observers.observeAttribute
`ModuleScript` · bytecode v9 · 1016 bytes · 13 constants
- **Key API:** Connect, Disconnect, GetAttribute
- Constants: `defaultGuard`, `typeof`, `function`, `Connected`, `task`, `spawn`, `GetAttribute`, `OnAttributeChanged`, `Disconnect`, `GetAttributeChangedSignal`, `Connect`, `defer`, `observeAttribute`

### [1328] ReplicatedStorage.Packages.Observers.observeCharacter
`ModuleScript` · bytecode v9 · 1086 bytes · 14 constants
- **Key API:** Connect, Disconnect
- Constants: `typeof`, `function`, `Connected`, `Parent`, `task`, `spawn`, `Disconnect`, `defer`, `AncestryChanged`, `Connect`, `OnCharacterAdded`, `Character`, `CharacterAdded`, `observeCharacter`

### [1329] ReplicatedStorage.Packages.Observers.observeCharacters
`ModuleScript` · bytecode v9 · 355 bytes · 6 constants
- Constants: `observeCharacters`, `require`, `script`, `Parent`, `observePlayer`, `observeCharacter`

### [1330] ReplicatedStorage.Packages.Observers.observeChildren
`ModuleScript` · bytecode v9 · 1059 bytes · 15 constants
- **Key API:** Connect, Disconnect, GetChildren
- Constants: `typeof`, `function`, `task`, `spawn`, `OnInstanceRemoved`, `Connected`, `OnInstanceAdded`, `GetChildren`, `Disconnect`, `next`, `ChildAdded`, `Connect`, `ChildRemoved`, `defer`, `observeChildren`

### [1331] ReplicatedStorage.Packages.Observers.observeDescendants
`ModuleScript` · bytecode v9 · 1043 bytes · 15 constants
- **Key API:** Connect, Disconnect, GetDescendants
- Constants: `typeof`, `function`, `task`, `spawn`, `OnInstanceRemoved`, `Connected`, `OnInstanceAdded`, `GetDescendants`, `Disconnect`, `next`, `DescendantAdded`, `Connect`, `DescendantRemoving`, `defer`, `observeChildren`

### [1332] ReplicatedStorage.Packages.Observers.observePlayer
`ModuleScript` · bytecode v9 · 1290 bytes · 19 constants
- **Services:** Players, game
- **Key API:** Connect, Disconnect, GetPlayers, GetService
- Constants: `typeof`, `function`, `Connected`, `Parent`, `task`, `spawn`, `OnPlayerAdded`, `OnPlayerRemoving`, `GetPlayers`, `Disconnect`, `next`, `PlayerAdded`, `Connect`, `PlayerRemoving`, `defer`, `observePlayer`, `game`, `Players`, `GetService`

### [1333] ReplicatedStorage.Packages.Observers.observeProperty
`ModuleScript` · bytecode v9 · 972 bytes · 9 constants
- **Key API:** Connect, Disconnect
- Constants: `Connected`, `task`, `spawn`, `OnPropertyChanged`, `Disconnect`, `GetPropertyChangedSignal`, `Connect`, `defer`, `observeProperty`

### [1334] ReplicatedStorage.Packages.Observers.observeTag
`ModuleScript` · bytecode v9 · 3653 bytes · 43 constants
- **Services:** CollectionService, game
- **Key API:** Connect, Disconnect, GetService
- Constants: `IsDescendantOf`, `IsGoodAncestor`, `typeof`, `nil`, `function`, `callback must return a function`, `assert`, `__inflight__`, `xpcall`, `debug`, `traceback`, `string`, `split`, `find`, `: `, `sub`, `warn`, `error while calling observeTag("%*") callback:%*
%*`, `format`, `type`, `task`, `spawn`, `defer`, `AttemptStartup`, `__dead__`, `AttemptCleanup`, `OnAncestryChanged`, `Connected`, `AncestryChanged`, `Connect`, `OnInstanceAdded`, `Disconnect`, `OnInstanceRemoved`, `GetTagged`, `next`, `GetInstanceAddedSignal`, `GetInstanceRemovedSignal`, `observeTag`, `game`, `CollectionService`, `GetService`

### [1335] ReplicatedStorage.Packages.Observers.observeTagNoAncestry
`ModuleScript` · bytecode v9 · 1954 bytes · 36 constants
- **Services:** CollectionService, game
- **Key API:** Connect, Disconnect, GetService
- Constants: `typeof`, `nil`, `function`, `callback must return a function`, `assert`, `xpcall`, `debug`, `traceback`, `string`, `split`, `find`, `: `, `sub`, `warn`, `error while calling observeTag("%*") callback:%*
%*`, `format`, `type`, `HasTag`, `task`, `spawn`, `Connected`, `defer`, `OnInstanceAdded`, `OnInstanceRemoved`, `GetTagged`, `Disconnect`, `next`, `GetInstanceAddedSignal`, `Connect`, `GetInstanceRemovedSignal`, `observeTagNoAncestry`, `game`, `CollectionService`, `GetService`

### [1336] ReplicatedStorage.Packages.Promise
`ModuleScript` · bytecode v9 · 179 bytes · 6 constants
- Constants: `require`, `promise`, `evaera_promise@4.0.0`, `script`, `Parent`, `_Index`

### [1337] ReplicatedStorage.Packages.Reliever
`ModuleScript` · bytecode v9 · 746 bytes · 14 constants
- **Services:** RunService, game
- **Key API:** Connect, GetService
- Constants: `os`, `clock`, `task`, `defer`, `wait`, `relieve`, `setMax`, `game`, `RunService`, `GetService`, `IsServer`, `Heartbeat`, `Connect`, `PreRender`

### [1338] ReplicatedStorage.Packages.RemotePacketSizeCounter
`ModuleScript` · bytecode v9 · 3603 bytes · 54 constants
- Constants: `math`, `log`, `ceil`, `max`, `GetVLQSize`, `typeof`, `string`, `buffer`, `len`, `table`, `next`, `CFrame`, `Rotation`, `NumberSequence`, `ColorSequence`, `Keypoints`, `warn`, `[PacketSizeCounter]: Unsupported data type: `, `GetDataByteSize`, `RemoteType`, `RemoteFunction`, `RunContext`, `Client`, `ipairs`, `PacketData`, `GetPacketSize`, `nil`, `EnumItem`, `boolean`, `number`, `UDim`, `UDim2`, `Ray`, `Faces`, `Axes`, `BrickColor`, `Color3`, `Vector2`, `Vector3`, `Instance`, `Vector2int16`, `Vector3int16`, `NumberSequenceKeypoint`, `ColorSequenceKeypoint`, `NumberRange`, `Rect`, `PhysicalProperties`, `Color3uint8`, `Angles`, `BaseRemoteOverhead`, `RemoteFunctionOverhead`, `ClientToServerOverhead`, `TypeOverhead`, `freeze`

### [1339] ReplicatedStorage.Packages.Replion
`ModuleScript` · bytecode v9 · 341 bytes · 12 constants
- **Services:** RunService, game
- **Key API:** GetService
- Constants: `_G`, `game`, `RunService`, `GetService`, `IsStudio`, `__DEV__`, `require`, `replion`, `ytrev_replion@2.0.0-rc.1`, `script`, `Parent`, `_Index`

### [1340] ReplicatedStorage.Packages.Replion.Replion
`Script` · bytecode v9 · 315 bytes · 8 constants
- **Key API:** SetAttribute
- Constants: `script`, `Target`, `Value`, `Changed`, `Wait`, `require`, `Loaded`, `SetAttribute`

### [1341] ReplicatedStorage.Packages.Serialization
`ModuleScript` · bytecode v9 · 2972 bytes · 52 constants
- **Services:** ReplicatedStorage, game
- **Key API:** GetService
- Constants: `typeof`, `nil`, `ser`, `table`, `error`, `not found for %*`, `format`, `function`, `string`, `find`, `number`, `des`, `any`, `game`, `ServerScriptService`, `GetService`, `ReplicatedStorage`, `require`, `script`, `Parent`, `Squash`, `T`, `uint`, `vlq`, `boolean`, `Vector2`, `array`, `map`, `opt`, `record`, `Information`, `Compiled`, `Looped`, `Length`, `FPS`, `Path`, `Props`, `InstanceNames`, `InstanceTypes`, `ItemType`, `Default`, `Static`, `Sequence`, `Ease`, `Time`, `Value`, `Params`, `Type`, `Direction`, `Overshoot`, `Amplitude`, `Period`

### [1342] ReplicatedStorage.Packages.Serialization.Serialization
`Script` · bytecode v9 · 315 bytes · 8 constants
- **Key API:** SetAttribute
- Constants: `script`, `Target`, `Value`, `Changed`, `Wait`, `require`, `Loaded`, `SetAttribute`

### [1343] ReplicatedStorage.Packages.Signal
`ModuleScript` · bytecode v9 · 180 bytes · 6 constants
- Constants: `require`, `signal`, `sleitnick_signal@2.0.3`, `script`, `Parent`, `_Index`

### [1344] ReplicatedStorage.Packages.Signal.Signal
`Script` · bytecode v9 · 315 bytes · 8 constants
- **Key API:** SetAttribute
- Constants: `script`, `Target`, `Value`, `Changed`, `Wait`, `require`, `Loaded`, `SetAttribute`

### [1345] ReplicatedStorage.Packages.SmartBone
`ModuleScript` · bytecode v9 · 11688 bytes · 196 constants
- **Services:** CollectionService, HttpService, Players, RunService, game, workspace
- **Key API:** Clone, Connect, Destroy, Disconnect, GetAttribute, GetChildren, GetDescendants, GetService, IsA, SetAttribute, Stop, WaitForChild, new
- Constants: `GetAttributes`, `SetAttribute`, `CopyPasteAttributes`, `ID`, `BoneTrees`, `ColliderObjects`, `ShouldDestroy`, `GenerateGUID`, `setmetatable`, `new`, `GatherBoneSettings`, `Root`, `RootPart`, `¬`, `Bones`, `Position`, `Magnitude`, `FreeLength`, `Weight`, `HeirarchyLength`, `HasChild`, `Settings`, `AnchorDepth`, `Anchoring bone`, `Anchored`, `ParentIndex`, `table`, `insert`, `m_AppendBone`, `Adding bone: %*; %*; %*`, `Name`, `format`, `GetChildren`, `Bone`, `IsA`, `string`, `sub`, `_end`, `_Tail`, `Adding tail bone`, `Parent`, `WorldPosition`, `WorldCFrame`, `UpVector`, `Unit`, `Instance`, `AddChildren`, `GatherObjectSettings`, `Creating bone tree %*; %*`, `m_CreateBoneTree`, `shared`, `FrameCounter`, `FRUSTUM_FREQ`, `GetCFrames`, `workspace`, `CurrentCamera`, `FAR_PLANE`, `CFrame`, `Size`, `BoundingBoxCFrame`, `BoundingBoxSize`, `ObjectInFrustum`, `InView`, `m_UpdateViewFrustum`, `Colliders`, `Destroyed`, `Deleting Collider Object`, `Destroy`, `remove`, `m_CleanColliders`, `PreUpdate`, `UpdateRate`, `math`, `floor`, `InWorkspace`, `IsSkippingUpdates`, `SkipUpdate`, `task`, `synchronize`, `ApplyTransform`, `Skipping BoneTree, InView: %*, Update Rate == 0: %*, InWorkspace: %*`, `Step`, `AccumulatedDelta`, `StepPhysics`, `Constrain`, `SolveTransform`, `m_UpdateBoneTree`, `m_CheckDestroy`, `Roots`, `GetAttribute`, `warn`, `[SmartBone2::LoadObject] Cannot load an object with no roots defined %*`, `,`, `split`, `GetDescendants`, `[SmartBone2::LoadObject] Duplicate bones of name: %* in RootPart: %*`, `[SmartBone2::LoadObject] Couldn't find Root Bone of name: %* in RootPart: %*`, `LoadObject`, `[SmartBone2::LoadColliderModule] No collider module passed in`, `assert`, `require`, `JSONDecode`, `LoadColliderModule`, `LoadRawCollider`, `DeltaTime is zero or sub zero, not updating.`, `StepBoneTrees`, `DrawDebug`, `DEBUG_OVERLAY_ENABLED`, `Color3`, `Begin`, `SmartBone Instance ID: %*`, `Text`, `Frame Counter: %*`, `DEBUG_OVERLAY_TREE`, `DEBUG_OVERLAY_MAX_TREES`, `DEBUG_OVERLAY_TREE_OFFSET`, `Bone Tree %*`, `DrawOverlay`, `End`, `Deleting SmartBone Object`, `Key`, `Raw`, `SmartCollider`, `GetTagged`, `BasePart`, `ColliderKey`, `tostring`, `Adding collider: %*, Collider Key: %*`, `YIELD_ON_COLLIDER_GATHER`, `wait`, `GatherColliders`, `Setup Object: %*`, `GetCollider`, `Actor`, `Clone`, `Enabled`, `Setup`, `script`, `SendMessage`, `Runtime Started`, `SetupObject`, `Render`, `Running`, `RESET_BONE_ON_DESTROY`, `connection`, `Disconnect`, `Stop`, `IsClient`, `Smartbone.Start() can only be called in client context.`, `Cannot call Smartbone.Start() multiple times`, `STARTUP_PRINT_ENABLED`, `LOG_VERBOSE`, `print`, `SmartBone2 v%* Starting`, `VERSION`, `LocalPlayer`, `PlayerScripts`, `WaitForChild`, `Folder`, `SmartBone-Actors`, `BindableEvent`, `OverlayEvent`, `Event`, `Connect`, `SmartBone`, `GetInstanceAddedSignal`, `PlayerGui`, `ScreenGui`, `SmartBoneDebugOverlay`, `IgnoreGuiInset`, `ResetOnSpawn`, `BackFrame`, `RenderStepped`, `Start`, `game`, `CollectionService`, `GetService`, `HttpService`, `Players`, `RunService`, `Components`, `Dependencies`, `Debug`, `ImOverlay`, `Config`, `Frustum`, `Utilities`, `BoneTree`, `Collision`, `ColliderObject`, `Runtime`, `SB_INDENT_LOG`, `SB_UNINDENT_LOG`, `SB_VERBOSE_LOG`, `SB_VERBOSE_WARN`, `__index`

### [1346] ReplicatedStorage.Packages.SmartBone.Components.Bone
`ModuleScript` · bytecode v9 · 18194 bytes · 205 constants
- **Key API:** Connect, Destroy, Disconnect, FindFirstChild, GetAttribute, IsA, WaitForChild, new
- Constants: `Magnitude`, `Unit`, `SafeUnit`, `IsNaN`, `Frame`, `shared`, `FrameCounter`, `CFrame`, `Parent`, `Bone`, `IsA`, `TransformedCFrame`, `QueryTransformedWorldCFrameNonSmartbone`, `SolvedAnimatedCFrame`, `ParentIndex`, `Bones`, `AnimatedWorldCFrame`, `QueryTransformedWorldCFrame`, `ClipVector`, `CurrentPhysicalProperties`, `Friction`, `FrictionWeight`, `GetFriction`, `EaseInExpo`, `math`, `noise`, `clamp`, `GetNoise`, `sin`, `SampleGust`, `cos`, `SampleSin`, `WindOffset`, `Vector3`, `new`, `SampleNoise`, `Settings`, `WindType`, `Sine`, `Noise`, `Hybrid`, `os`, `clock`, `HeirarchyLength`, `TransformOffset`, `Position`, `Root`, `WorldPosition`, `WindInfluence`, `WindSpeed`, `WindStrength`, `WindDirection`, `Dot`, `abs`, `min`, `max`, `FreeLength`, `Weight`, `SolveWind`, `GatherBoneSettings`, `¬`, `TransformedWorldCFrame`, `ToObjectSpace`, `Inverse`, `Transform`, `LocalTransform`, `RootPart`, `RootBone`, `Radius`, `RotationLimit`, `Force`, `Gravity`, `HasChild`, `StartingCFrame`, `identity`, `LocalTransformOffset`, `RestPosition`, `CalculatedWorldCFrame`, `LastPosition`, `WeldPosition`, `WeldCFrame`, `ActiveWeld`, `RigidWeld`, `Anchored`, `AxisLocked`, `NumberRange`, `XAxisLimits`, `YAxisLimits`, `ZAxisLimits`, `IsSkippingUpdates`, `CollisionHits`, `CollisionsData`, `setmetatable`, `AttributeChanged`, `Connect`, `AttributeConnection`, `ClipVelocity`, `SmartWeld`, `FindFirstChild`, `ObjectValue`, `Value`, `Rigid`, `GetAttribute`, `Attachment`, `WorldCFrame`, `BasePart`, `PreUpdate`, `ObjectAcceleration`, `Inertia`, `Damping`, `StepPhysics`, `Constraint`, `Spring`, `Distance`, `Rope`, `Constrain`, `RESET_TRANSFORM_ON_SKIP`, `SkipUpdate`, `GetRotationBetween`, `UpVector`, `Rotation`, `Lerp`, `warn`, `If you see this report this as a bug, (NaN Calc world cframe)`, `SolveTransform`, `AnchorsRotate`, `ApplyTransform`, `Color3`, `fromRGB`, `PushProperty`, `AlwaysOnTop`, `Sphere`, `Draw`, `Ray`, `PointToObjectSpace`, `RightVector`, `LookVector`, `Arrow`, `Min`, `X`, `Max`, `Plane`, `Y`, `Z`, `VolumeArrow`, `ClosestPoint`, `Normal`, `rad`, `tan`, `lookAt`, `Cone`, `DrawDebug`, `Text`, `Bone: %*`, `Name`, `format`, `DEBUG_OVERLAY_BONE_INFO`, `DEBUG_OVERLAY_BONE_NUMERICS`, `Free Length: %*`, `Weight: %*`, `Parent Index: %*`, `Heirarchy Length: %*`, `Radius: %*`, `Friction: %*`, `Rotation Limit: %*`, `DEBUG_OVERLAY_BONE_CONSTRAIN`, `Anchored: %*`, `Axis Locked: %*, %*, %*`, `X Axis Limit: %*`, `Y Axis Limit: %*`, `Z Axis Limit: %*`, `DEBUG_OVERLAY_BONE_WELD`, `Active Weld: %*`, `Rigid Weld: %*`, `Weld Position: %*`, `string`, `%.3f, %.3f, %.3f`, `DEBUG_OVERLAY_BONE_FORCES`, `-, -, -`, `Force: %*`, `Gravity: %*`, `DrawOverlay`, `RESET_BONE_ON_DESTROY`, `task`, `synchronize`, `Disconnect`, `Destroy`, `script`, `Dependencies`, `WaitForChild`, `require`, `Config`, `Debug`, `Gizmo`, `Utilities`, `Constraints`, `AxisConstraint`, `CollisionConstraint`, `DistanceConstraint`, `FrictionConstraint`, `RopeConstraint`, `RotationConstraint`, `SpringConstraint`, `SB_ASSERT_CB`, `__index`

### [1347] ReplicatedStorage.Packages.SmartBone.Components.BoneTree
`ModuleScript` · bytecode v9 · 8609 bytes · 122 constants
- **Services:** Lighting, game, workspace
- **Key API:** Destroy, Disconnect, GetAttribute, GetService, IsA, WaitForChild, new
- Constants: `Magnitude`, `Unit`, `SafeUnit`, `map`, `game`, `IsDescendantOf`, `Destroyed`, `workspace`, `InWorkspace`, `GetAttribute`, `WindOffset`, `Root`, `RootPart`, `RootPartSize`, `Bones`, `Settings`, `UpdateRate`, `InView`, `AccumulatedDelta`, `BoundingBoxCFrame`, `BoundingBoxSize`, `IsSkippingUpdates`, `Force`, `ObjectMove`, `ObjectVelocity`, `ObjectAcceleration`, `ObjectPreviousPosition`, `NextNumber`, `Bone`, `IsA`, `Size`, `CFrame`, `Position`, `setmetatable`, `AncestryChanged`, `ConnectParallel`, `DestroyConnection`, `AttributeChanged`, `AttributeConnection`, `new`, `LastPosition`, `Min`, `Max`, `UpdateBoundingBox`, `CurrentCamera`, `ActivationDistance`, `ThrottleDistance`, `UpdateThrottling`, `PreUpdate`, `Gravity`, `MatchWorkspaceWind`, `GlobalWind`, `WindDirection`, `WindSpeed`, `WindStrength`, `StepPhysics`, `Constrain`, `SkipUpdate`, `SolveTransform`, `ApplyTransform`, `Color3`, `fromRGB`, `Y`, `Vector3`, `SetStyle`, `Arrow`, `Draw`, `PushProperty`, `AlwaysOnTop`, `Box`, `VolumeBox`, `Transparency`, `TransformedWorldCFrame`, `ParentIndex`, `DrawDebug`, `Ray`, `DEBUG_OVERLAY_TREE_INFO`, `DEBUG_OVERLAY_TREE_OBJECTS`, `Text`, `Root Part: %*`, `Name`, `format`, `Root Bone: %*`, `Root Part Size: %*`, `string`, `%.3f, %.3f, %.3f`, `X`, `Z`, `DEBUG_OVERLAY_TREE_NUMERICS`, `Update Rate: %*`, `%.3f`, `In View: %*`, `Accumulated Delta: %*`, `Force: %*`, `DEBUG_OVERLAY_BONE`, `DEBUG_OVERLAY_MAX_BONES`, `DEBUG_OVERLAY_BONE_OFFSET`, `Begin`, `Bone %*`, `DrawOverlay`, `End`, `Destroy BoneTree`, `task`, `synchronize`, `Disconnect`, `Destroy`, `desynchronize`, `Lighting`, `GetService`, `script`, `Parent`, `Dependencies`, `WaitForChild`, `require`, `Config`, `DefaultObjectSettings`, `Debug`, `Gizmo`, `Utilities`, `Random`, `SB_VERBOSE_LOG`, `__index`

### [1348] ReplicatedStorage.Packages.SmartBone.Components.Collision.Collider
`ModuleScript` · bytecode v9 · 4543 bytes · 66 constants
- **Services:** HttpService, game
- **Key API:** Destroy, GetService, WaitForChild, new
- Constants: `Type`, `Box`, `Scale`, `Offset`, `Rotation`, `Radius`, `PreviousScale`, `PreviousOffset`, `PreviousRotation`, `PreviousObjectPosition`, `PreviousObjectRotation`, `m_Object`, `InNarrowphase`, `Transform`, `Size`, `GUID`, `CFrame`, `identity`, `GenerateGUID`, `setmetatable`, `new`, `UpdateTransform`, `SetObject`, `Angles`, `X`, `Y`, `Z`, `math`, `max`, `sqrt`, `Position`, `Magnitude`, `Capsule`, `Sphere`, `Cylinder`, `GetClosestPoint`, `Step`, `Color3`, `m_Awake`, `SetStyle`, `Draw`, `VolumeBox`, `PushProperty`, `Transparency`, `UpVector`, `VolumeCylinder`, `VolumeSphere`, `min`, `DrawDebug`, `Collider destroying, object: %*`, `format`, `Destroy`, `game`, `HttpService`, `GetService`, `script`, `Parent`, `Dependencies`, `WaitForChild`, `Colliders`, `require`, `Utilities`, `SB_VERBOSE_LOG`, `Debug`, `Gizmo`, `__index`

### [1349] ReplicatedStorage.Packages.SmartBone.Components.Collision.ColliderObject
`ModuleScript` · bytecode v9 · 2772 bytes · 57 constants
- **Services:** workspace
- **Key API:** Connect, Destroy, Disconnect, WaitForChild, new
- Constants: `Parent`, `Destroyed`, `m_Object`, `m_Awake`, `m_LastSleepCycle`, `Colliders`, `setmetatable`, `m_LoadColliderTable`, `GetPropertyChangedSignal`, `Connect`, `DestroyConnection`, `new`, `ScaleX`, `ScaleY`, `ScaleZ`, `Vector3`, `OffsetX`, `OffsetY`, `OffsetZ`, `RotationX`, `RotationY`, `RotationZ`, `Scale`, `Offset`, `Rotation`, `Type`, `SetObject`, `table`, `insert`, `m_LoadCollider`, `GetObject`, `os`, `clock`, `workspace`, `IsDescendantOf`, `GetClosestPoint`, `ClosestPoint`, `Normal`, `GetCollisions`, `Step`, `DrawDebug`, `InNarrowphase`, `task`, `synchronize`, `Collider object destroying, object: %*`, `format`, `Disconnect`, `Destroy`, `desynchronize`, `require`, `script`, `Collider`, `WaitForChild`, `Dependencies`, `Utilities`, `SB_VERBOSE_LOG`, `__index`

### [1350] ReplicatedStorage.Packages.SmartBone.Components.Collision.Colliders.Box
`ModuleScript` · bytecode v9 · 1610 bytes · 19 constants
- **Key API:** new
- Constants: `Magnitude`, `Unit`, `SafeUnit`, `pointToObjectSpace`, `x`, `y`, `z`, `math`, `clamp`, `Vector3`, `new`, `max`, `XVector`, `YVector`, `ZVector`, `warn`, `CLOSEST POINT ON BOX FAIL`, `Position`, `ClosestPointFunc`

### [1351] ReplicatedStorage.Packages.SmartBone.Components.Collision.Colliders.Capsule
`ModuleScript` · bytecode v9 · 1309 bytes · 15 constants
- Constants: `Magnitude`, `Unit`, `SafeUnit`, `Dot`, `math`, `clamp`, `solve`, `Position`, `UpVector`, `ClosestPointFunc`, `Y`, `Z`, `X`, `CFrame`, `Angles`

### [1352] ReplicatedStorage.Packages.SmartBone.Components.Collision.Colliders.Cylinder
`ModuleScript` · bytecode v9 · 2154 bytes · 16 constants
- Constants: `Magnitude`, `Unit`, `SafeUnit`, `Dot`, `math`, `clamp`, `solve`, `ProjectOnPlane`, `GetFinalProj`, `Y`, `Z`, `X`, `Position`, `RightVector`, `min`, `ClosestPointFunc`

### [1353] ReplicatedStorage.Packages.SmartBone.Components.Collision.Colliders.Sphere
`ModuleScript` · bytecode v9 · 769 bytes · 10 constants
- Constants: `Magnitude`, `Unit`, `SafeUnit`, `ClosestPointFunc`, `Position`, `X`, `Y`, `Z`, `math`, `min`

### [1354] ReplicatedStorage.Packages.SmartBone.Components.Collision.Colliders.Triangle
`ModuleScript` · bytecode v9 · 2444 bytes · 15 constants
- **Key API:** new
- Constants: `Magnitude`, `Unit`, `SafeUnit`, `ClosestPointOnLineSegment`, `Dot`, `ProjectOnPlane`, `SameSide`, `PointInTriangle`, `math`, `min`, `ClosestPointOnTri`, `Vector3`, `new`, `Cross`, `clamp`

### [1355] ReplicatedStorage.Packages.SmartBone.Components.Constraints.AxisConstraint
`ModuleScript` · bytecode v9 · 1707 bytes · 21 constants
- **Key API:** new
- Constants: `Magnitude`, `Unit`, `SafeUnit`, `Inverse`, `X`, `Y`, `Z`, `XAxisLimits`, `YAxisLimits`, `ZAxisLimits`, `AxisLocked`, `Min`, `Max`, `Vector3`, `new`, `Radius`, `RightVector`, `UpVector`, `LookVector`, `Dot`, `ClipVelocity`

### [1356] ReplicatedStorage.Packages.SmartBone.Components.Constraints.AxisConstraint.spec
`ModuleScript` · bytecode v9 · 3630 bytes · 34 constants
- **Key API:** WaitForChild, new
- Constants: `ClipVelocity`, `AxisLocked`, `CFrame`, `identity`, `expect`, `X`, `to`, `equal`, `Y`, `Z`, `it`, `Should lock X Axis`, `Should lock Y Axis`, `Should lock Z Axis`, `NumberRange`, `new`, `XAxisLimits`, `Min Limit`, `Max Limit`, `YAxisLimits`, `ZAxisLimits`, `describe`, `Should limit X Axis`, `Should limit Y Axis`, `Should limit Z Axis`, `Radius`, `afterEach`, `Axis Lock`, `Axis Limit`, `require`, `script`, `Parent`, `AxisConstraint`, `WaitForChild`

### [1357] ReplicatedStorage.Packages.SmartBone.Components.Constraints.CollisionConstraint
`ModuleScript` · bytecode v9 · 500 bytes · 9 constants
- Constants: `Radius`, `GetCollisions`, `GetObject`, `table`, `insert`, `ClosestPoint`, `Normal`, `CollisionsData`, `CollisionHits`

### [1358] ReplicatedStorage.Packages.SmartBone.Components.Constraints.DistanceConstraint
`ModuleScript` · bytecode v9 · 410 bytes · 7 constants
- Constants: `Magnitude`, `Unit`, `SafeUnit`, `Bones`, `ParentIndex`, `FreeLength`, `Position`

### [1359] ReplicatedStorage.Packages.SmartBone.Components.Constraints.DistanceContraint.spec
`ModuleScript` · bytecode v9 · 1018 bytes · 22 constants
- **Key API:** WaitForChild
- Constants: `Position`, `FreeLength`, `ParentIndex`, `CreateBone`, `expect`, `Magnitude`, `to`, `equal`, `Callback`, `Bones`, `it`, `Should limit to %* studs #%*`, `format`, `math`, `random`, `describe`, `Distance Constraint`, `require`, `script`, `Parent`, `DistanceConstraint`, `WaitForChild`

### [1360] ReplicatedStorage.Packages.SmartBone.Components.Constraints.FrictionConstraint
`ModuleScript` · bytecode v9 · 132 bytes · 2 constants
- Constants: `Friction`, `Lerp`

### [1361] ReplicatedStorage.Packages.SmartBone.Components.Constraints.RopeConstraint
`ModuleScript` · bytecode v9 · 450 bytes · 7 constants
- Constants: `Magnitude`, `Unit`, `SafeUnit`, `Bones`, `ParentIndex`, `FreeLength`, `Position`

### [1362] ReplicatedStorage.Packages.SmartBone.Components.Constraints.RopeConstraint.spec
`ModuleScript` · bytecode v9 · 1502 bytes · 24 constants
- **Key API:** WaitForChild
- Constants: `Position`, `FreeLength`, `ParentIndex`, `CreateBone`, `expect`, `Magnitude`, `to`, `equal`, `math`, `random`, `LimitCallback`, `SameCallback`, `it`, `Should stay the same #%*`, `format`, `Should limit to %* studs #%*`, `Bones`, `describe`, `Rope Constraint`, `require`, `script`, `Parent`, `RopeConstraint`, `WaitForChild`

### [1363] ReplicatedStorage.Packages.SmartBone.Components.Constraints.RotationConstraint
`ModuleScript` · bytecode v9 · 842 bytes · 14 constants
- Constants: `Magnitude`, `Unit`, `SafeUnit`, `ParentIndex`, `Bones`, `RotationLimit`, `Position`, `math`, `rad`, `Dot`, `acos`, `Cross`, `CFrame`, `fromAxisAngle`

### [1364] ReplicatedStorage.Packages.SmartBone.Components.Constraints.SpringConstraint
`ModuleScript` · bytecode v9 · 694 bytes · 13 constants
- **Key API:** new
- Constants: `Settings`, `Stiffness`, `Elasticity`, `Bones`, `ParentIndex`, `FreeLength`, `CFrame`, `new`, `Position`, `TransformOffset`, `Rotation`, `LocalTransformOffset`, `Magnitude`

### [1365] ReplicatedStorage.Packages.SmartBone.Dependencies.Config
`ModuleScript` · bytecode v9 · 818 bytes · 25 constants
- Constants: `VERSION`, `0.5.0`, `RESET_TRANSFORM_ON_SKIP`, `YIELD_ON_COLLIDER_GATHER`, `ALLOW_LIVE_GAME_DEBUG`, `FAR_PLANE`, `FRUSTUM_FREQ`, `LOG_VERBOSE`, `RESET_BONE_ON_DESTROY`, `STARTUP_PRINT_ENABLED`, `DEBUG_OVERLAY_ENABLED`, `DEBUG_OVERLAY_TREE`, `DEBUG_OVERLAY_TREE_INFO`, `DEBUG_OVERLAY_TREE_OBJECTS`, `DEBUG_OVERLAY_TREE_NUMERICS`, `DEBUG_OVERLAY_TREE_OFFSET`, `DEBUG_OVERLAY_MAX_TREES`, `DEBUG_OVERLAY_BONE`, `DEBUG_OVERLAY_BONE_OFFSET`, `DEBUG_OVERLAY_MAX_BONES`, `DEBUG_OVERLAY_BONE_INFO`, `DEBUG_OVERLAY_BONE_NUMERICS`, `DEBUG_OVERLAY_BONE_CONSTRAIN`, `DEBUG_OVERLAY_BONE_WELD`, `DEBUG_OVERLAY_BONE_FORCES`

### [1366] ReplicatedStorage.Packages.SmartBone.Dependencies.Debug.DebugUi
`ModuleScript` · bytecode v9 · 10950 bytes · 177 constants
- **Key API:** new
- Constants: `PushConfig`, `TextColor`, `_config`, `TextDisabledColor`, `Text`, `PopConfig`, `infoText`, `(?)`, `ContentWidth`, `UDim`, `new`, `hovered`, `Tooltip`, `helpMarker`, `Window`, `Editing bone: %*`, `Bone`, `Name`, `format`, `isOpened`, `value`, `InputNum`, `Radius`, `%.3f`, `number`, `Rotation Limit`, `RotationLimit`, `Checkbox`, `Anchored`, `isChecked`, `Axis Lock`, `Indent`, `SameLine`, `X: `, `AxisLocked`, `Y: `, `Z: `, `End`, `State`, `Vector2`, `XAxisLimits`, `Min`, `Max`, `YAxisLimits`, `ZAxisLimits`, `Axis Limits`, `DragVector2`, `X Axis Limit`, `Min: %.2f`, `Max: %.2f`, `Y Axis Limit`, `Z Axis Limit`, `NumberRange`, `get`, `X`, `Y`, `closed`, `BoneEditor`, `Editing collider of type: %*`, `Type`, `Scale`, `Offset`, `Rotation`, `Combo`, `Collider Type`, `index`, `Selectable`, `Box`, `Sphere`, `Capsule`, `DragVector3`, `ColliderEditor`, `BoneTrees`, `RootPart`, `table`, `insert`, `%* - %*`, `ID`, `ParentIndex`, `PushId`, `PopId`, `GUID`, `ColliderObjects`, `%* BoneTree%*`, `s`, `%* Collider%*`, `SmartBone Runtime Editor. %*, %*`, `Args`, `NoClose`, `Tree`, `Debug Gizmos`, `isUncollapsed`, `Separator`, `Simulated Objects`, `%* - Root Part`, `BoneTree #%*`, `string`, `%.1f`, `UpdateRate`, `Settings`, `Throttled Update Rate: %* / %* fps`, `In View: %*`, `InView`, `Constraint`, `WindType`, `ActivationDistance`, `ThrottleDistance`, `The constraint used, distance is more flowy while spring is more rigid.`, `Constraint Type`, `Distance`, `Spring`, `The wind solver used, sine is a smoother wind, noise is more chaotic and hybrid is a mix of the two.`, `Wind Type`, `Sine`, `Noise`, `Hybrid`, `The target update rate for the bone tree`, `SliderNum`, `Update Rate`, `The distance at which the bone tree stops updating`, `Activation Distance`, `The distance at which the bone tree starts throttling its update rate`, `Throttle Distance`, `Table`, `NextColumn`, `Bone #`, `Bone Name`, `Parent #`, `Edit`, `Bones`, `tostring`, `SmallButton`, `clicked`, `Active Colliders`, `m_Object`, `Colliders adorned to this object`, `Colliders`, `Draw Internal Bone`, `Draws a sphere with the specified radius of the bone around where SmartBone believes the bone is.`, `DRAW_BONE`, `Draw Physical Bone`, `Draws the actual bone objects CFrame with axis arrows.`, `DRAW_PHYSICAL_BONE`, `Draw Root Part`, `Draws a bounding box and fills in the root part.`, `DRAW_ROOT_PART`, `Draw Bounding Box`, `Draws the bounding box used for frustum culling.`, `DRAW_BOUNDING_BOX`, `Draw Axis Limits`, `Draws the axis limits for each bone.`, `DRAW_AXIS_LIMITS`, `Draw Rotation Limits`, `Draws the rotation limits for each bone.`, `DRAW_ROTATION_LIMITS`, `Draw Acceleration Info`, `Draws the acceleration and the required values to derive it.`, `DRAW_ACCELERATION_INFO`, `Draw Colliders`, `Draws all the colliders this root object can collide with.`, `DRAW_COLLIDERS`, `Draw Collider Influence`, `Shows the sphere of influence around each collider.`, `DRAW_COLLIDER_INFLUENCE`, `Draw Collider Awake`, `Shows if a collider is awake or asleep.`, `DRAW_COLLIDER_AWAKE`, `Draw Collider BroadPhase`, `Shows if a collider isn't reaching NarrowPhase.`, `DRAW_COLLIDER_BROADPHASE`, `Draw Fill Colliders`, `Fills all colliders this root object can collide with.`, `DRAW_FILL_COLLIDERS`, `Draw Contacts`, `Draws the position and normal of the points which bones collide with colliders.`, `DRAW_CONTACTS`

### [1367] ReplicatedStorage.Packages.SmartBone.Dependencies.Debug.Gizmo
`ModuleScript` · bytecode v9 · 945 bytes · 27 constants
- **Services:** RunService, game
- **Key API:** Create, GetService, WaitForChild
- Constants: `Draw`, `Create`, `SetStyle`, `AddDebrisInSeconds`, `PushProperty`, `PopProperty`, `AddDebrisInFrames`, `SetEnabled`, `DoCleaning`, `ScheduleCleaning`, `TweenProperties`, `__index`, `script`, `Parent`, `require`, `Config`, `WaitForChild`, `Gizmo`, `game`, `RunService`, `GetService`, `IsStudio`, `ALLOW_LIVE_GAME_DEBUG`, `Init`, `setmetatable`, `table`, `freeze`
