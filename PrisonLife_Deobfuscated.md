# Prison Life — Deobfuscated API Reference

Recovered from `Prison life dumped` (whole-game client code dump, PlaceId 155615604).

> The dump is hex-encoded Luau **bytecode**, not source. Full bytecode->source
> decompilation isn't possible by hand, but every string constant (remote names,
> method calls, item/team names, asset ids) was extracted from each script's
> constant table below. That recovers the game's real client-facing API — which
> is what's needed to build/verify scripts. Server `Script`s in ServerScriptService
> / ServerStorage are never sent to the client and are not in this dump.

## Confirmed remotes (`ReplicatedStorage.Remotes.*` unless noted)

| Remote | Call | Purpose (inferred from caller) |
|---|---|---|
| `RequestTeamChange` | `InvokeServer(teamName)` | Change team. TeamsMenu joins `Guards` / `Inmates` / `Criminals`. |
| `RequestHere` | `FireServer(Vector3 pos)` | Teleport-to-point. `RequestHere.Client` fires it with `mouse.Hit.Position` on MouseButton3. |
| `GiverPressed` | `FireServer(giver)` | Press a weapon/item giver (ClientItemHandler). |
| `InteractWithItem` | `InvokeServer(item)` | Pick up / interact with an item (ClientItemHandler). |
| `TouchGiver` | `FireServer(giver)` | Touch-based giver pickup. |
| `ArrestPlayer` | `FireServer(player)` | Arrest a player (guards). |
| `ShootEvent` | `InvokeServer(...)` | Fire a gun (GunController). |
| `meleeEvent` | `FireServer(target)` | Melee hit — top-level `ReplicatedStorage.meleeEvent`. |
| `UpdateSetting` | `FireServer(name,value)` | Change a player setting (PlayerSettings). |
| `GetSettings` | `InvokeServer()` | Fetch player settings. |
| `RequestCollisionChange` | `FireServer(...)` | Toggle player/character collision. |
| `ReplicateEvent` | `FireServer / OnClientEvent` | General client<->server replication. |
| `InnocentWarnEvent` | `FireServer(player)` | Warn an innocent (guards). |
| `BuyGamepassRequested` | `FireServer(id)` | Prompt a gamepass purchase (PremiumMenu). |
| `VoiceTeleportRequested` | `FireServer(...)` | Voice-chat area teleport. |
| `mouseLockToggledEvent` | `FireServer(bool)` | Shift-lock toggle relay. |
| `SwitchTeams` | `(event)` | Team switching signal. |

> Arg shapes are inferred from the calling scripts' constant tables; exact operand
> order can't be read from bytecode by hand, so treat calls as best-effort and
> pcall-guard them.

## Teams

`Guards`, `Inmates`, `Criminals` (Hostile), plus `Neutral`. Team change goes through
`RequestTeamChange:InvokeServer(<name>)` in this version (the classic
`workspace.Remote.TeamEvent:FireServer(<BrickColor>)` path may not exist here).

## Item / giver system (`ClientItemHandler`)

Item classes: `single`, `items`, `buttons`, `hats`, `clothes`. Givers live under a
`giver` container; each has a `ToolName` and a `Team_`/`Team_Any` tag gating who can
take it. Pickup path: `GiverPressed` / `InteractWithItem` / `TouchGiver`.
Premium items are gated by `PlayerOwnsAsset` / `isPremium` / `premiumType`.

## Gun system (`ToolScripts.GunController`)

Attributes/fields: `MaxAmmo`, `CurrentAmmo`, `StoredAmmo`, `FireRate`, `Range`,
`Damage`, `ReloadTime`, `Behavior` (`Sniper`/`Shotgun`), `AutoFire`. Shots go through
`ShootEvent`; damage is gated by `canBeDamaged` + `ForceField`. Reload variants:
`ReloadRifle` / `ReloadRevolver` / `ReloadShells` / `ReloadMagazine`.

## Per-script constant summary

### `Players.<you>.Backpack.Crude Knife.MeleeToolScript` (LocalScript)

`Play` `task` `wait` `swing` `Parent` `Humanoid` `findFirstChild` `Health` `GetPlayerFromCharacter` `TeamColor` `Name` `Hammer` `math` `random` `Handle` `HammerSound1` `HammerSound2` `FireServer` `Toilet` `Main` `rubble` `Value` `Emit` `Stop` `LoadAnimation` `Button1Down` `connect` `KeyframeReached` `blade` `CanTouch` `Touched` `Unequipped` `script` `Animation` `game` `Players` `GetService` `LocalPlayer` `ReplicatedStorage` `meleeEvent` `WaitForChild` `Equipped` `333333` `P@o` `zj\"`

### `Players.<you>.Backpack.Handcuffs.HandcuffsClient` (LocalScript)

`Parent` `Model` `FindFirstAncestorOfClass` `Humanoid` `FindFirstChildOfClass` `getCharacterFromPart` `Disconnect` `Adornee` `onUnequipped` `InvokeServer` `clock` `Target` `ForceField` `GetPlayerFromCharacter` `HumanoidRootPart` `FindFirstChild` `Character` `Position` `magnitude` `Team` `Criminals` `Inmates` `GetAttributes` `Hostile` `Tased` `Trespassing` `Health` `rbxassetid://289707987` `Icon` `Button1Down` `connect` `Stepped` `Connect` `Died` `game` `ReplicatedStorage` `GetService` `Players` `RunService` `Teams` `UserInputService` `require` `SharedModules` `TooltipModule` `Remotes` `WaitForChild` `ArrestPlayer` `LocalPlayer` `ArrestHighlight` `Instance` `new` `Highlight` `Color3` `fromRGB` `FillColor` `OutlineColor` `Enum` `HighlightDepthMode` `Occluded` `DepthMode`

### `Players.<you>.PlayerGui.Home.hud.AddedGui.GuiResizeScript` (LocalScript)

`UDim2` `new` `Size` `AbsoluteSize` `Position` `changeGuiSize` `script` `Parent` `tooltip` `WaitForChild` `mousehover` `Changed` `connect` `ffffff` `X~s1"`

### `Players.<you>.PlayerScripts.PlayerScriptsLoader` (LocalScript)

`require` `script` `Parent` `PlayerModule` `WaitForChild` ` @M`

### `Players.<you>.Backpack.Hammer.MeleeToolScript` (LocalScript)

`Play` `task` `wait` `swing` `Parent` `Humanoid` `findFirstChild` `Health` `GetPlayerFromCharacter` `TeamColor` `Name` `Hammer` `math` `random` `Handle` `HammerSound1` `HammerSound2` `FireServer` `Toilet` `Main` `rubble` `Value` `Emit` `Stop` `LoadAnimation` `Button1Down` `connect` `KeyframeReached` `blade` `CanTouch` `Touched` `Unequipped` `script` `Animation` `game` `Players` `GetService` `LocalPlayer` `ReplicatedStorage` `meleeEvent` `WaitForChild` `Equipped` `333333` `P@o` `zj\"`

### `ReplicatedStorage.PlayerSettings` (Script)

`script` `GetAttribute` `UpdateSetting` `FireServer` `game` `ReplicatedStorage` `GetService` `Remotes` `WaitForChild` `PlayerSettings` `GetSettings` `InvokeServer` `playerSettings` `pairs` `SetAttribute` `print` `Server didn't return settings` `Settings_Loaded` `AttributeChanged` `Connect`

### `ReplicatedStorage.Remotes.RequestHere.Client` (Script)

`UserInputType` `Enum` `MouseButton3` `KeyCode` `Hit` `Position` `FireServer` `game` `UserInputService` `GetService` `Players` `LocalPlayer` `GetMouse` `script` `Parent` `InputBegan` `Connect` `p@M`

### `ReplicatedStorage.Scripts.BackpackClient` (Script)

`Instance` `new` `ScreenGui` `PlayerGui` `Enabled` `Frame` `Clone` `Enum` `SafeAreaCompatibility` `FullscreenExtension` `ScreenInsets` `None` `AbsolutePosition` `Destroy` `Vector2` `getSafeInset` `Button` `AbsoluteSize` `getTotalWidth` `math` `floor` `min` `max` `pairs` `getSlotFromPosition` `isPointInsideElement` `Tool` `findToolSlot` `UDim2` `fromOffset` `Slot` `Position` `SlotNumber` `Text` `UIDragDetector` `FindFirstChildOfClass` `Dragging` `GetAttribute` `Size` `updateToolbar` `SetAttribute` `table` `remove` `insert` `BoundingUI` `DragStart` `Connect` `DragContinue` `DragEnd` `createDragger` `BackgroundColor3` `resetColors` `Character` `Humanoid` `Parent` `Backpack` `UnequipTools` `EquipTool` `equipTool` `unequipTools`

### `ReplicatedStorage.Scripts.CharacterCollision` (Script)

`CanCollide` `Head` `WaitForChild` `GetPropertyChangedSignal` `Connect` `onCharacterAdded` `game` `Players` `GetService` `LocalPlayer` `CharacterAdded` `KjL`

### `ReplicatedStorage.Scripts.ClientItemHandler` (Script)

`UserId` `PlayerOwnsAsset` `isAuthenticated` `pairs` `GetChildren` `Tool` `IsA` `print` `playerHasTools` `premiumType` `findFirstChild` `Parent` `Value` `isPremium` `HumanoidRootPart` `FindFirstChild` `Position` `magnitude` `isCloseEnoughToCharacter` `Name` `pcall` `giver` `single` `items` `buttons` `hats` `clothes` `GetPlayerFromCharacter` `player` `getItemClass` `BUTTONPART` `MouseOnButton` `Humanoid` `FindFirstChildOfClass` `Health` `Target` `VendingMachineButton` `HasTag` `InvokeServer` `update` `Giver` `TouchGiver` `FireServer` `ToolName` `GetAttribute` `Team_Any` `Team_` `Team` `SuppressTooltip` `Item - ` `Box` `desc` `Hat - ` `Clothes - ` `TextLabel` `Text` `UDim2` `new` `AbsoluteSize` `Visible`

### `ReplicatedStorage.Scripts.GiverHider` (Script)

`pairs` `Giver` `GetTagged` `GetTags` `string` `split` `Team` `Name` `Drop` `HasTag` `GuardRoomCard` `GetChildren` `BasePart` `IsA` `OriginalTransparency` `GetAttribute` `Transparency` `SetAttribute` `updateGiverVisibility` `game` `CollectionService` `GetService` `ReplicatedStorage` `Players` `LocalPlayer` `GetPropertyChangedSignal` `Connect`

### `ReplicatedStorage.Scripts.LocalDoors` (Script)

`scn` `glow` `LocalPlayerOpened` `SetAttribute` `BrickColor` `new` `Bright green` `Enum` `Material` `Neon` `cardScanner` `Sound` `Play` `task` `wait` `Bright red` `SmoothPlastic` `openDoor` `GetAttributes` `Exploded` `ScheduledOpen` `PlayerOpened` `Parent` `block` `WaitForChild` `AttributeChanged` `Connect` `handleDoor` `Disconnect` `Name` `hitbox` `Door` `HasTag` `Tool` `FindFirstChildOfClass` `Key card` `Team` `Guards` `HumanoidRootPart` `Touched` `game` `Teams` `GetService` `CollectionService` `Players` `LocalPlayer` `pairs` `GetTagged` `defer` `GetInstanceAddedSignal` `GetInstanceRemovedSignal` `CharacterAdded` `d0I` `(^tV`

### `ReplicatedStorage.Scripts.Preloader` (Script)

`game` `ContentProvider` `GetService` `rbxassetid://129205074574148` `PreloadAsync`

### `ReplicatedStorage.Scripts.Replication.Announcements` (Script)

`tooltip` `update` `PlayerGui` `Home` `findFirstChild` `gooeys` `messageGui` `Clone` `Desc` `Text` `Visible` `hud` `AnnouncementsFrame` `Parent` `UDim2` `new` `Out` `Quint` `TweenPosition` `task` `wait` `game` `Debris` `AddItem` `ReplicatedStorage` `GetService` `require` `SharedModules` `TooltipModule` `Players` `LocalPlayer` `Remotes` `WaitForChild` `AnnouncementReceived` `OnClientEvent` `connect` `~Bi`

### `ReplicatedStorage.Scripts.Replication.CarSoundReplication` (Script)

`Occupant` `Play` `Stop` `Parent` `Velocity` `Magnitude` `math` `clamp` `Pitch` `task` `wait` `Body` `WaitForChild` `VehicleSeat` `EngineSound` `GetPropertyChangedSignal` `Connect` `defer` `print` `handleCar` `game` `CollectionService` `GetService` `Players` `LocalPlayer` `Vehicle` `GetTagged` `pairs` `GetInstanceAddedSignal` `333333`

### `ReplicatedStorage.Scripts.Replication.ChatMessageHandler` (Script)

`DisplaySystemMessage` `TextChannel` `Name` `Prison` `PrefixText` `Instance` `new` `TextChatMessageProperties` `string` `format` `<font color='#ff5c5c'>%s</font>` `Text` `game` `TextChatService` `GetService` `ReplicatedStorage` `Remotes` `WaitForChild` `MessageReceived` `TextChannels` `OnClientEvent` `Connect` `OnIncomingMessage`

### `ReplicatedStorage.Scripts.Replication.ClientReplicator` (Script)

`table` `unpack` `Taser` `createTaser` `Sniper` `createSniper` `createBullet` `Clone` `Parent` `SoundId` `rbxassetid://82273261` `Volume` `rbxassetid://2935002319` `math` `random` `Pitch` `Play` `AddItem` `gooeys` `WarnGui` `PlayerGui` `Frame` ` more times.` `LocalScript` `Disabled` `game` `ReplicatedStorage` `GetService` `Debris` `Players` `LocalPlayer` `TweenService` `require` `SharedModules` `GunTracers` `Remotes` `WaitForChild` `SoundReplicated` `GunRemotes` `ReplicateEvent` `OnClientEvent` `connect` `Connect` `InnocentWarnEvent`

### `ReplicatedStorage.Scripts.Script` (Script)

``

### `ReplicatedStorage.Scripts.TeamIndicators` (Script)

`pairs` `GetPlayers` `Name` `FindFirstChild` `Team` `Character` `HumanoidRootPart` `Position` `magnitude` `Enabled` `updateVisibility` `game` `Players` `GetService` `Teams` `CollectionService` `LocalPlayer` `workspace` `TeamIndicators` `WaitForChild` `task` `wait` `p@o`

### `ReplicatedStorage.Scripts.ToolScripts.C4Controller` (Script)

`workspace` `CurrentCamera` `ViewportPointToRay` `Origin` `Direction` `Raycast` `getScreenRaycast` `Normal` `Dot` `math` `abs` `CFrame` `lookAt` `Position` `identity` `getCFrameFromResult` `Unit` `Cross` `fromMatrix` `Size` `new` `getSurfaceCFrame` `DoCleaning` `Visible` `unequip` `GetLastInputType` `Enum` `UserInputType` `MouseMovement` `Keyboard` `MouseButton1` `MouseButton2` `MouseButton3` `MouseWheel` `Gamepad1` `GetMouseLocation` `Transparency` `Touch` `Explosive` `FindFirstChild` `Handle` `Place C4` `Text` `Clone` `CanCollide` `CanTouch` `CanQuery` `Anchored` `GhostC4` `Name` `Parent` `GiveTask` `Character` `HumanoidRootPart` `RenderStepped` `Connect` `enterPlacementMode` `Local_Mode` `GetAttribute` `Placement`

### `ReplicatedStorage.Scripts.ToolScripts.GunController` (Script)

`MobileCursorOffset` `GetAttribute` `GetAttributeChangedSignal` `Connect` `onSettingsLoaded` `pairs` `Instance` `new` `Animation` `AnimationId` `Visible` `Settings_Loaded` `Once` `init` `Team` `Character` `Guards` `Inmates` `Hostile` `ForceField` `FindFirstChildOfClass` `Humanoid` `FindFirstChild` `Health` `canBeDamaged` `GetLastInputType` `Enum` `UserInputType` `Touch` `lastInputWasTouch` `AbsolutePosition` `AbsoluteSize` `isOutsideBounds` `LoadAnimation` `AnimationPriority` `Action2` `Priority` `loadAnimations` `Play` `playAnimation` `Stop` `stopAnimation` `stopAllAnimations` `Handle` `Clone` `Parent` `AddItem` `warn` `No sound found` `playSound` `GetChildren` `Sound` `IsA` `stopAllSounds` `workspace` `CurrentCamera` `ViewportPointToRay` `Origin` `Direction` `Raycast`

### `ReplicatedStorage.Scripts.ToolScripts.ShieldController` (Script)

`Disconnect` `unequip` `UserInputType` `Enum` `MouseButton1` `Touch` `KeyCode` `ButtonR2` `FireServer` `InputBegan` `Connect` `equip` `Health` `GetAttribute` `Text` `Visible` `Name` `Riot Shield` `Tool` `IsA` `RiotShieldPart` `BasePart` `GetAttributeChangedSignal` `AncestryChanged` `ChildAdded` `ChildRemoved` `game` `UserInputService` `GetService` `ReplicatedStorage` `require` `SharedModules` `Maid` `Players` `LocalPlayer` `Remotes` `WaitForChild` `ShieldEquipped` `PlayerGui` `Home` `hud` `ShieldHealthFrame` `CharacterAdded` `CharacterRemoving` `P@M` `_@b`

### `ReplicatedStorage.Scripts.ToolScripts.SnackController` (Script)

`Disconnect` `Stop` `unequip` `UserInputType` `Enum` `MouseButton1` `Touch` `KeyCode` `ButtonR2` `Quantity` `GetAttribute` `Client_LastConsumedAt` `clock` `SetAttribute` `Play` `SoundName` `Character` `Head` `FindFirstChild` `FireServer` `InputBegan` `Connect` `equip` `ToolType` `Snack` `Tool` `IsA` `Humanoid` `WaitForChild` `Animator` `LoadAnimation` `ChildAdded` `ChildRemoved` `game` `UserInputService` `GetService` `ReplicatedStorage` `require` `SharedModules` `Maid` `Players` `LocalPlayer` `Remotes` `SnackEaten` `script` `EatSnackAnimation` `CharacterAdded` `CharacterRemoving` `P@M`

### `ReplicatedStorage.Scripts.UIController` (Script)

`Team` `Neutral` `close` `open` `out` `require` `script` `Intro` `GameUI` `game` `Players` `GetService` `Teams` `ReplicatedStorage` `LocalPlayer` `SharedModules` `fadeBlack` `CharacterAdded` `Connect` ` @M` ``@o` `p~Ak2`

### `ReplicatedStorage.Scripts.UIController.GameUI` (ModuleScript)

`Visible` `clock` `endCamera` `Completed` `Wait` `InvokeServer` `out` `task` `wait` `MobileCursorOffset` `SetAttribute` `Mobile Cursor Offset: ` `Text` `AnnouncementsShown` `Hide Announcements: ` `OFF` `UseOldBackpack` `Use Old Backpack: ` `GetAttribute` `MouseButton1Click` `Connect` `onSettingsLoaded` `GetMinutesAfterMidnight` `titleBar` `Title` `UDim2` `fromOffset` `TopbarInset` `Height` `Position` `AbsolutePosition` `new` `Scale` `Offset` `AbsoluteSize` `Size` `print` `updateActionButton` `TouchControlFrame` `JumpButton` `GetPropertyChangedSignal` `Enabled` `delay` `handleJumpButton` `Name` `Disconnect` `TouchGui found` `FindFirstChild` `DescendantAdded` `handleTouchGui` `TouchGui` `KeyCode` `Enum` `ButtonSelect` `SwitchTeams` `SelectedObject` `open` `close` `game` `Players`

### `ReplicatedStorage.Scripts.UIController.Intro` (ModuleScript)

`SelectedObject` `GetLastInputType` `Enum` `UserInputType` `Gamepad1` `tick` `table` `insert` `remove` `print` `Activating button!` `Visible` `JoinButton` `KeyCode` `ButtonR1` `navigateForward` `ButtonL1` `navigateBack` `getCurrentPosition` `Guards` `Button` `Container` `RiotPassButton` `BackpackEnabled` `SetAttribute` `workspace` `CurrentCamera` `CameraType` `Scriptable` `CFrame` `new` `CoordinateFrame` `FieldOfView` `open` `Custom` `close` `game` `Players` `GetService` `UserInputService` `ReplicatedStorage` `GuiService` `require` `script` `MenuNavigation` `TeamsMenu` `PremiumMenu` `VoiceChatUI` `LocalPlayer` `PlayerGui` `Home` `WaitForChild` `IntroFrame` `OkFrame` `tb1` `ContentBackground` `MainMenuFrame` `Buttons` `VoiceChatFrame` `TeamsFrame`

### `ReplicatedStorage.Scripts.UIController.Intro.MenuNavigation` (ModuleScript)

`pairs` `Position` `UDim2` `new` `Out` `Quint` `TweenPosition` `tween` `MenuTweenFinished` `TeamsFrame` `Guards` `Button` `Fire` `PremiumFrame` `Container` `RiotPassButton` `error` `MenuTweenBegan` `Scale` `task` `delay` `navigateTo` `navigateForward` `navigateBack` `getCurrentPosition` `LayoutOrder` `HelpFrame` `Visible` `Buttons` `GetChildren` `MouseButton1Click` `connect` `init` `game` `ReplicatedStorage` `GetService` `require` `SharedModules` `Signal` `ffffff` `333333` `tuC8`

### `ReplicatedStorage.Scripts.UIController.Intro.PremiumMenu` (ModuleScript)

`Riot Police` `FireServer` `Mafia` `Sniper` `Enum` `InfoType` `GamePass` `GetProductInfo` `rbxassetid://` `IconImageAssetId` `Image` `Container` `RiotPassButton` `MafiaPassButton` `SniperPassButton` `MouseButton1Click` `connect` `task` `defer` `init` `game` `MarketplaceService` `GetService` `ReplicatedStorage` `Remotes` `WaitForChild` `BuyGamepassRequested` `=~p` `2s~`

### `ReplicatedStorage.Scripts.UIController.Intro.TeamsMenu` (ModuleScript)

`Button` `AutoButtonColor` `Name` `FindFirstChild` `PlaybackState` `Enum` `Completed` `Wait` `InvokeServer` `out` `Play` `MouseButton1Click` `connect` `Background` `Desc` `TextTransparency` `Create` `ImageColor3` `Color3` `fromRGB` `MouseEnter` `MouseLeave` `handleTeamFrame` `backgroundColorOpen` `BackgroundColor3` `borderColorOpen` `BorderColor3` `TextLabel` `Join` `Text` `enableButton` `disableButton` `Guards` `GetPlayers` `Inmates` `Criminals` `math` `ceil` `Teams Unbalanced` `Team Full` `updateButtons` `PlayerAdded` `Connect` `PlayerRemoved` `init` `game` `TweenService` `GetService` `ReplicatedStorage` `Players` `Teams` `require` `SharedModules` `fadeBlack` `Remotes` `WaitForChild` `RequestTeamChange` `TweenInfo` `new` `EasingStyle`

### `ReplicatedStorage.Scripts.UIController.Intro.VoiceChatUI` (ModuleScript)

`FireServer` `task` `wait` `LocalPlayer` `UserId` `IsVoiceEnabledForUserIdAsync` `Visible` `JoinButton` `game` `PlaceId` `MouseButton1Click` `Connect` `spawn` `init` `Players` `GetService` `VoiceChatService` `ReplicatedStorage` `Remotes` `WaitForChild` `VoiceTeleportRequested` ` @M` `mqN`

### `ReplicatedStorage.SharedModules.ClientSettings` (ModuleScript)

`clientSettings` `UpdateSetting` `FireServer` `set` `GetSettings` `InvokeServer` `print` `Settings loaded successfully` `Server didn't return settings` `game` `ReplicatedStorage` `GetService` `Remotes` `WaitForChild` `UserSettings` `task` `defer` `0@o`

### `ReplicatedStorage.SharedModules.GunTracers` (ModuleScript)

`magnitude` `Instance` `new` `Part` `RayPart` `Name` `Enum` `Material` `Neon` `Anchored` `Transparency` `FormFactor` `Custom` `formFactor` `Vector3` `Size` `CFrame` `CanCollide` `CanQuery` `CanTouch` `BrickColor` `Cyan` `AddItem` `SurfaceLight` `Color3` `fromRGB` `Color` `Range` `Bottom` `Face` `Brightness` `Angle` `Create` `Play` `workspace` `CurrentCamera` `Parent` `createTaser` `Medium stone grey` `createSniper` `Yellow` `createBullet` `game` `Debris` `GetService` `TweenService` `TweenInfo` `EasingStyle` `Quad` `EasingDirection` ` BM` `ffffff` `x+p`

### `ReplicatedStorage.SharedModules.Maid` (ModuleScript)

`_tasks` `setmetatable` `new` `type` `table` `ClassName` `Maid` `isMaid` `__index` `task` `cancel` `error` `string` `format` `Cannot use '%s' as a Maid key` `tostring` `typeof` `function` `Destroy` `Instance` `thread` `coroutine` `running` `pcall` `defer` `RBXScriptConnection` `Disconnect` `__newindex` `Task cannot be false or nil` `debug` `traceback` `GiveTask` `IsPending` `resolved` `Finally` `GivePromise` `next` `DoCleaning` `P@R`

### `ReplicatedStorage.SharedModules.Signal` (ModuleScript)

`coroutine` `yield` `runEventHandlerInFreeThread` `_connected` `_signal` `_fn` `_next` `setmetatable` `new` `_handlerListHead` `Disconnect` `tostring` `format` `__newindex` `Connect` `DisconnectAll` `create` `resume` `task` `spawn` `Fire` `running` `Wait`

### `ReplicatedStorage.SharedModules.ToolProperties` (ModuleScript)

`pairs` `script` `GetChildren` `require` `Name` `P@R`

### `ReplicatedStorage.SharedModules.ToolProperties.AK-47` (ModuleScript)

`Damage` `MaxAmmo` `FireRate` `AutoFire` `Range` `AccurateRange` `ReloadTime` `SecondarySoundId` `SlotType` `Primary` `Icon` `rbxassetid://93481383611512` `ImageRectOffset` `Vector2` `new`

### `ReplicatedStorage.SharedModules.ToolProperties.FAL` (ModuleScript)

`Damage` `MaxAmmo` `FireRate` `AutoFire` `Range` `AccurateRange` `ReloadTime` `SecondarySoundId` `SlotType` `Primary` `Icon` `rbxassetid://93481383611512` `ImageRectOffset` `Vector2` `new` `Hg@`

### `ReplicatedStorage.SharedModules.ToolProperties.M4A1` (ModuleScript)

`Damage` `MaxAmmo` `FireRate` `AutoFire` `Range` `AccurateRange` `ReloadTime` `SecondarySoundId` `SlotType` `Primary` `Icon` `rbxassetid://93481383611512` `ImageRectOffset` `Vector2` `new`

### `ReplicatedStorage.SharedModules.ToolProperties.M700` (ModuleScript)

`Damage` `MaxAmmo` `StoredAmmo` `MaxStoredAmmo` `FireRate` `AutoFire` `Range` `AccurateRange` `ReloadTime` `Behavior` `Sniper` `ShootSoundId` `rbxassetid://84419861201505` `ReloadSoundId` `rbxassetid://73708758290921` `SlotType` `Primary` `Icon` `rbxassetid://93481383611512` `ImageRectOffset` `ChargeTime` `Vector2` `new` `333333` `fnV`

### `ReplicatedStorage.SharedModules.ToolProperties.M9` (ModuleScript)

`Damage` `MaxAmmo` `FireRate` `AutoFire` `Range` `AccurateRange` `ReloadTime` `SecondarySoundId` `SlotType` `Secondary` `rKk`

### `ReplicatedStorage.SharedModules.ToolProperties.MP5` (ModuleScript)

`Damage` `MaxAmmo` `FireRate` `AutoFire` `Range` `AccurateRange` `ReloadTime` `ShootSoundId` `rbxassetid://7698730413` `SecondarySoundId` `SlotType` `Primary` `Icon` `rbxassetid://93481383611512` `ImageRectOffset` `Vector2` `new` ``c@`

### `ReplicatedStorage.SharedModules.ToolProperties.Remington 870` (ModuleScript)

`Damage` `MaxAmmo` `FireRate` `AutoFire` `Range` `AccurateRange` `ReloadTime` `ProjectileCount` `Behavior` `Shotgun` `SlotType` `Primary` `Icon` `rbxassetid://93481383611512` `ImageRectOffset` `Vector2` `new` `ffffff`

### `ReplicatedStorage.SharedModules.ToolProperties.Revolver` (ModuleScript)

`Damage` `MaxAmmo` `FireRate` `AutoFire` `Range` `AccurateRange` `ReloadTime` `ShootSoundId` `rbxassetid://10209803` `SecondarySoundId` `ReloadSoundId` `rbxassetid://104727715547917` `SlotType` `Secondary` `333333`

### `ReplicatedStorage.SharedModules.ToolProperties.Taser` (ModuleScript)

`MaxAmmo` `AutoFire` `Range` `AccurateRange` `FireRate` `ReloadTime` `Behavior` `Taser` `SecondarySoundId` `ReloadSoundId` `rbxassetid://82273261` `ChargeTime` `333333`

### `ReplicatedStorage.SharedModules.TooltipModule` (ModuleScript)

`init` `wait` `Out` `BackgroundTransparency` `TextLabel` `TextTransparency` `ImageLabel` `ImageTransparency` `fadeTheGuis` `Tooltip error: No message given` `Text` `Visible` `spawn` `update` `game` `RunService` `GetService` `RenderStepped` `Players` `LocalPlayer` `PlayerGui` `WaitForChild` `Home` `hud` `AddedGui` `tooltip` `ReplicatedStorage` `Remotes` `TooltipReceived` `OnClientEvent` `connect` `dk#` `sNw`

### `ReplicatedStorage.SharedModules.fadeBlack` (ModuleScript)

`out` `Play` `fadeBlack` `game` `TweenService` `GetService` `Players` `LocalPlayer` `Instance` `new` `ScreenGui` `PlayerGui` `Enum` `ScreenInsets` `None` `DisplayOrder` `Frame` `UDim2` `fromScale` `Size` `Color3` `BackgroundColor3` `BackgroundTransparency` `TweenInfo` `EasingStyle` `Linear` `EasingDirection` `Out` `Create` `/FT`

### `ReplicatedStorage.SharedModules.isInsideDynThumbFrame` (ModuleScript)

`Name` `DynamicThumbstickFrame` `Disconnect` `PlayerGui` `TouchGui` `WaitForChild` `FindFirstChild` `DescendantAdded` `Connect` `AbsolutePosition` `AbsoluteSize` `isInside` `Visible` `game` `Players` `GetService` `LocalPlayer` `task` `spawn`

### `ReplicatedStorage.SharedModules.throwPart` (ModuleScript)

`tick` `Vector3` `new` `Lerp` `CFrame` `task` `wait` `Position` `Magnitude` `math` `sqrt` `atan` `Unit` `sin` `cos` `spawn`

### `ReplicatedStorage.ToolScripts.EatScript` (LocalScript)

`Quantity` `GetAttribute` `EatSound` `FindFirstChild` `Play` `FireServer` `task` `wait` `Character` `Humanoid` `script` `Animation` `LoadAnimation` `Button1Down` `Connect` `game` `ReplicatedStorage` `GetService` `Players` `Remotes` `WaitForChild` `EatFood` `LocalPlayer` `Parent` `Handle` `Equipped` `connect` `0@M`

### `ReplicatedStorage.ToolScripts.MeleeToolScript` (LocalScript)

`Play` `task` `wait` `swing` `Parent` `Humanoid` `findFirstChild` `Health` `GetPlayerFromCharacter` `TeamColor` `Name` `Hammer` `math` `random` `Handle` `HammerSound1` `HammerSound2` `FireServer` `Toilet` `Main` `rubble` `Value` `Emit` `Stop` `LoadAnimation` `Button1Down` `connect` `KeyframeReached` `blade` `CanTouch` `Touched` `Unequipped` `script` `Animation` `game` `Players` `GetService` `LocalPlayer` `ReplicatedStorage` `meleeEvent` `WaitForChild` `Equipped` `333333` `P@o` `zj\"`

### `ReplicatedStorage.Tools.Handcuffs.HandcuffsClient` (LocalScript)

`Parent` `Model` `FindFirstAncestorOfClass` `Humanoid` `FindFirstChildOfClass` `getCharacterFromPart` `Disconnect` `Adornee` `onUnequipped` `InvokeServer` `clock` `Target` `ForceField` `GetPlayerFromCharacter` `HumanoidRootPart` `FindFirstChild` `Character` `Position` `magnitude` `Team` `Criminals` `Inmates` `GetAttributes` `Hostile` `Tased` `Trespassing` `Health` `rbxassetid://289707987` `Icon` `Button1Down` `connect` `Stepped` `Connect` `Died` `game` `ReplicatedStorage` `GetService` `Players` `RunService` `Teams` `UserInputService` `require` `SharedModules` `TooltipModule` `Remotes` `WaitForChild` `ArrestPlayer` `LocalPlayer` `ArrestHighlight` `Instance` `new` `Highlight` `Color3` `fromRGB` `FillColor` `OutlineColor` `Enum` `HighlightDepthMode` `Occluded` `DepthMode`

### `ReplicatedStorage.gooeys.WarnGui.Frame.LocalScript` (LocalScript)

`script` `Parent` `UDim2` `new` `Out` `Quint` `TweenPosition` `wait` `Frame` `Color3` `BackgroundColor3` `Destroy` `______` `333333` `ffffff` `01]N`

### `ReplicatedStorage.gooeys.camGui.Frame.LocalScript` (LocalScript)

`script` `Parent` `UDim2` `new` `TweenPosition` `ffffff`

### `StarterGui.Home.hud.AddedGui.GuiResizeScript` (LocalScript)

`UDim2` `new` `Size` `AbsoluteSize` `Position` `changeGuiSize` `script` `Parent` `tooltip` `WaitForChild` `mousehover` `Changed` `connect` `ffffff` `X~s1"`

### `StarterPlayer.StarterCharacterScripts.AntiJump` (LocalScript)

`Jump` `GetState` `Enum` `HumanoidStateType` `Freefall` `Jumping` `Landed` `clock` `math` `min` `game` `RunService` `GetService` `script` `Parent` `Humanoid` `WaitForChild` `GetPropertyChangedSignal` `Connect` `ffffff` `"7J`

### `StarterPlayer.StarterCharacterScripts.ClientInputHandler` (LocalScript)

`CFrame` `new` `Position` `workspace` `Unit` `Raycast` `Instance` `Parent` `GetPlayerFromCharacter` `Team` `Guards` `FireServer` `math` `random` `Pitch` `Play` `trimboi` `HasTag` `CheckHit` `GetMarkerReachedSignal` `Connect` `listenForHits` `pcall` `SetCore` `ResetButtonCallback` `task` `wait` `defer` `setResetButton` `Animation` `AnimationId` `createAnim` `type` `string` `pairs` `table` `isBusy` `isCamera` `BackpackEnabled` `SetAttribute` `startCamera` `Humanoid` `CameraSubject` `Custom` `CameraType` `RenderStepped` `Wait` `CameraOffset` `Vector3` `moveCamOffset` `isFighting` `Stop` `fight` `finish` `isTazed` `print` `Disabling reset button` `UnequipTools` `WalkSpeed` `JumpHeight`

### `StarterPlayer.StarterPlayerScripts.PlayerScriptsLoader` (LocalScript)

`require` `script` `Parent` `PlayerModule` `WaitForChild` ` @M`

### `Workspace.Ahduy19.AntiJump` (LocalScript)

`Jump` `GetState` `Enum` `HumanoidStateType` `Freefall` `Jumping` `Landed` `clock` `math` `min` `game` `RunService` `GetService` `script` `Parent` `Humanoid` `WaitForChild` `GetPropertyChangedSignal` `Connect` `ffffff` `"7J`

### `Workspace.Ahduy19.ClientInputHandler` (LocalScript)

`CFrame` `new` `Position` `workspace` `Unit` `Raycast` `Instance` `Parent` `GetPlayerFromCharacter` `Team` `Guards` `FireServer` `math` `random` `Pitch` `Play` `trimboi` `HasTag` `CheckHit` `GetMarkerReachedSignal` `Connect` `listenForHits` `pcall` `SetCore` `ResetButtonCallback` `task` `wait` `defer` `setResetButton` `Animation` `AnimationId` `createAnim` `type` `string` `pairs` `table` `isBusy` `isCamera` `BackpackEnabled` `SetAttribute` `startCamera` `Humanoid` `CameraSubject` `Custom` `CameraType` `RenderStepped` `Wait` `CameraOffset` `Vector3` `moveCamOffset` `isFighting` `Stop` `fight` `finish` `isTazed` `print` `Disabling reset button` `UnequipTools` `WalkSpeed` `JumpHeight`

### `Workspace.Alex_11f3.AntiJump` (LocalScript)

`Jump` `GetState` `Enum` `HumanoidStateType` `Freefall` `Jumping` `Landed` `clock` `math` `min` `game` `RunService` `GetService` `script` `Parent` `Humanoid` `WaitForChild` `GetPropertyChangedSignal` `Connect` `ffffff` `"7J`

### `Workspace.Alex_11f3.ClientInputHandler` (LocalScript)

`CFrame` `new` `Position` `workspace` `Unit` `Raycast` `Instance` `Parent` `GetPlayerFromCharacter` `Team` `Guards` `FireServer` `math` `random` `Pitch` `Play` `trimboi` `HasTag` `CheckHit` `GetMarkerReachedSignal` `Connect` `listenForHits` `pcall` `SetCore` `ResetButtonCallback` `task` `wait` `defer` `setResetButton` `Animation` `AnimationId` `createAnim` `type` `string` `pairs` `table` `isBusy` `isCamera` `BackpackEnabled` `SetAttribute` `startCamera` `Humanoid` `CameraSubject` `Custom` `CameraType` `RenderStepped` `Wait` `CameraOffset` `Vector3` `moveCamOffset` `isFighting` `Stop` `fight` `finish` `isTazed` `print` `Disabling reset button` `UnequipTools` `WalkSpeed` `JumpHeight`

### `Workspace.CarContainer.Sedan.Body.VehicleSeat.Screen.CarControlLoop` (LocalScript)

`wait` `script` `Parent` `CarSeat` `Value` `Motor` `RWD` `Velocity` `magnitude` `SteerFloat` `DesiredAngle` `Throttle` `Torque` `MaxSpeed` `Destroy` ` @M` `33333`

### `Workspace.City_buildings.Model.Apt.Modules.CircleClick` (ModuleScript)

`ClipsDescendants` `script` `Circle` `WaitForChild` `Clone` `Parent` `AbsolutePosition` `UDim2` `new` `Position` `AbsoluteSize` `Out` `Quad` `TweenSizeAndPosition` `ImageTransparency` `wait` `Destroy` `coroutine` `resume` `create` `CircleClick` `333333`

### `Workspace.MattZion1706.AntiJump` (LocalScript)

`Jump` `GetState` `Enum` `HumanoidStateType` `Freefall` `Jumping` `Landed` `clock` `math` `min` `game` `RunService` `GetService` `script` `Parent` `Humanoid` `WaitForChild` `GetPropertyChangedSignal` `Connect` `ffffff` `"7J`

### `Workspace.MattZion1706.ClientInputHandler` (LocalScript)

`CFrame` `new` `Position` `workspace` `Unit` `Raycast` `Instance` `Parent` `GetPlayerFromCharacter` `Team` `Guards` `FireServer` `math` `random` `Pitch` `Play` `trimboi` `HasTag` `CheckHit` `GetMarkerReachedSignal` `Connect` `listenForHits` `pcall` `SetCore` `ResetButtonCallback` `task` `wait` `defer` `setResetButton` `Animation` `AnimationId` `createAnim` `type` `string` `pairs` `table` `isBusy` `isCamera` `BackpackEnabled` `SetAttribute` `startCamera` `Humanoid` `CameraSubject` `Custom` `CameraType` `RenderStepped` `Wait` `CameraOffset` `Vector3` `moveCamOffset` `isFighting` `Stop` `fight` `finish` `isTazed` `print` `Disabling reset button` `UnequipTools` `WalkSpeed` `JumpHeight`

### `Workspace.Meowmew153.AntiJump` (LocalScript)

`Jump` `GetState` `Enum` `HumanoidStateType` `Freefall` `Jumping` `Landed` `clock` `math` `min` `game` `RunService` `GetService` `script` `Parent` `Humanoid` `WaitForChild` `GetPropertyChangedSignal` `Connect` `ffffff` `"7J`

### `Workspace.Meowmew153.ClientInputHandler` (LocalScript)

`CFrame` `new` `Position` `workspace` `Unit` `Raycast` `Instance` `Parent` `GetPlayerFromCharacter` `Team` `Guards` `FireServer` `math` `random` `Pitch` `Play` `trimboi` `HasTag` `CheckHit` `GetMarkerReachedSignal` `Connect` `listenForHits` `pcall` `SetCore` `ResetButtonCallback` `task` `wait` `defer` `setResetButton` `Animation` `AnimationId` `createAnim` `type` `string` `pairs` `table` `isBusy` `isCamera` `BackpackEnabled` `SetAttribute` `startCamera` `Humanoid` `CameraSubject` `Custom` `CameraType` `RenderStepped` `Wait` `CameraOffset` `Vector3` `moveCamOffset` `isFighting` `Stop` `fight` `finish` `isTazed` `print` `Disabling reset button` `UnequipTools` `WalkSpeed` `JumpHeight`

### `Workspace.NairoldAr.AntiJump` (LocalScript)

`Jump` `GetState` `Enum` `HumanoidStateType` `Freefall` `Jumping` `Landed` `clock` `math` `min` `game` `RunService` `GetService` `script` `Parent` `Humanoid` `WaitForChild` `GetPropertyChangedSignal` `Connect` `ffffff` `"7J`

### `Workspace.NairoldAr.ClientInputHandler` (LocalScript)

`CFrame` `new` `Position` `workspace` `Unit` `Raycast` `Instance` `Parent` `GetPlayerFromCharacter` `Team` `Guards` `FireServer` `math` `random` `Pitch` `Play` `trimboi` `HasTag` `CheckHit` `GetMarkerReachedSignal` `Connect` `listenForHits` `pcall` `SetCore` `ResetButtonCallback` `task` `wait` `defer` `setResetButton` `Animation` `AnimationId` `createAnim` `type` `string` `pairs` `table` `isBusy` `isCamera` `BackpackEnabled` `SetAttribute` `startCamera` `Humanoid` `CameraSubject` `Custom` `CameraType` `RenderStepped` `Wait` `CameraOffset` `Vector3` `moveCamOffset` `isFighting` `Stop` `fight` `finish` `isTazed` `print` `Disabling reset button` `UnequipTools` `WalkSpeed` `JumpHeight`

### `Workspace.Pnwed_19.AntiJump` (LocalScript)

`Jump` `GetState` `Enum` `HumanoidStateType` `Freefall` `Jumping` `Landed` `clock` `math` `min` `game` `RunService` `GetService` `script` `Parent` `Humanoid` `WaitForChild` `GetPropertyChangedSignal` `Connect` `ffffff` `"7J`

### `Workspace.Pnwed_19.ClientInputHandler` (LocalScript)

`CFrame` `new` `Position` `workspace` `Unit` `Raycast` `Instance` `Parent` `GetPlayerFromCharacter` `Team` `Guards` `FireServer` `math` `random` `Pitch` `Play` `trimboi` `HasTag` `CheckHit` `GetMarkerReachedSignal` `Connect` `listenForHits` `pcall` `SetCore` `ResetButtonCallback` `task` `wait` `defer` `setResetButton` `Animation` `AnimationId` `createAnim` `type` `string` `pairs` `table` `isBusy` `isCamera` `BackpackEnabled` `SetAttribute` `startCamera` `Humanoid` `CameraSubject` `Custom` `CameraType` `RenderStepped` `Wait` `CameraOffset` `Vector3` `moveCamOffset` `isFighting` `Stop` `fight` `finish` `isTazed` `print` `Disabling reset button` `UnequipTools` `WalkSpeed` `JumpHeight`

### `Workspace.Reohrbrna8728.AntiJump` (LocalScript)

`Jump` `GetState` `Enum` `HumanoidStateType` `Freefall` `Jumping` `Landed` `clock` `math` `min` `game` `RunService` `GetService` `script` `Parent` `Humanoid` `WaitForChild` `GetPropertyChangedSignal` `Connect` `ffffff` `"7J`

### `Workspace.Reohrbrna8728.ClientInputHandler` (LocalScript)

`CFrame` `new` `Position` `workspace` `Unit` `Raycast` `Instance` `Parent` `GetPlayerFromCharacter` `Team` `Guards` `FireServer` `math` `random` `Pitch` `Play` `trimboi` `HasTag` `CheckHit` `GetMarkerReachedSignal` `Connect` `listenForHits` `pcall` `SetCore` `ResetButtonCallback` `task` `wait` `defer` `setResetButton` `Animation` `AnimationId` `createAnim` `type` `string` `pairs` `table` `isBusy` `isCamera` `BackpackEnabled` `SetAttribute` `startCamera` `Humanoid` `CameraSubject` `Custom` `CameraType` `RenderStepped` `Wait` `CameraOffset` `Vector3` `moveCamOffset` `isFighting` `Stop` `fight` `finish` `isTazed` `print` `Disabling reset button` `UnequipTools` `WalkSpeed` `JumpHeight`

### `Workspace.Ry02237.AntiJump` (LocalScript)

`Jump` `GetState` `Enum` `HumanoidStateType` `Freefall` `Jumping` `Landed` `clock` `math` `min` `game` `RunService` `GetService` `script` `Parent` `Humanoid` `WaitForChild` `GetPropertyChangedSignal` `Connect` `ffffff` `"7J`

### `Workspace.Ry02237.ClientInputHandler` (LocalScript)

`CFrame` `new` `Position` `workspace` `Unit` `Raycast` `Instance` `Parent` `GetPlayerFromCharacter` `Team` `Guards` `FireServer` `math` `random` `Pitch` `Play` `trimboi` `HasTag` `CheckHit` `GetMarkerReachedSignal` `Connect` `listenForHits` `pcall` `SetCore` `ResetButtonCallback` `task` `wait` `defer` `setResetButton` `Animation` `AnimationId` `createAnim` `type` `string` `pairs` `table` `isBusy` `isCamera` `BackpackEnabled` `SetAttribute` `startCamera` `Humanoid` `CameraSubject` `Custom` `CameraType` `RenderStepped` `Wait` `CameraOffset` `Vector3` `moveCamOffset` `isFighting` `Stop` `fight` `finish` `isTazed` `print` `Disabling reset button` `UnequipTools` `WalkSpeed` `JumpHeight`

### `Workspace.Theyab_10Z.AntiJump` (LocalScript)

`Jump` `GetState` `Enum` `HumanoidStateType` `Freefall` `Jumping` `Landed` `clock` `math` `min` `game` `RunService` `GetService` `script` `Parent` `Humanoid` `WaitForChild` `GetPropertyChangedSignal` `Connect` `ffffff` `"7J`

### `Workspace.Theyab_10Z.ClientInputHandler` (LocalScript)

`CFrame` `new` `Position` `workspace` `Unit` `Raycast` `Instance` `Parent` `GetPlayerFromCharacter` `Team` `Guards` `FireServer` `math` `random` `Pitch` `Play` `trimboi` `HasTag` `CheckHit` `GetMarkerReachedSignal` `Connect` `listenForHits` `pcall` `SetCore` `ResetButtonCallback` `task` `wait` `defer` `setResetButton` `Animation` `AnimationId` `createAnim` `type` `string` `pairs` `table` `isBusy` `isCamera` `BackpackEnabled` `SetAttribute` `startCamera` `Humanoid` `CameraSubject` `Custom` `CameraType` `RenderStepped` `Wait` `CameraOffset` `Vector3` `moveCamOffset` `isFighting` `Stop` `fight` `finish` `isTazed` `print` `Disabling reset button` `UnequipTools` `WalkSpeed` `JumpHeight`

### `Workspace.Zxcvqisss.AntiJump` (LocalScript)

`Jump` `GetState` `Enum` `HumanoidStateType` `Freefall` `Jumping` `Landed` `clock` `math` `min` `game` `RunService` `GetService` `script` `Parent` `Humanoid` `WaitForChild` `GetPropertyChangedSignal` `Connect` `ffffff` `"7J`

### `Workspace.Zxcvqisss.ClientInputHandler` (LocalScript)

`CFrame` `new` `Position` `workspace` `Unit` `Raycast` `Instance` `Parent` `GetPlayerFromCharacter` `Team` `Guards` `FireServer` `math` `random` `Pitch` `Play` `trimboi` `HasTag` `CheckHit` `GetMarkerReachedSignal` `Connect` `listenForHits` `pcall` `SetCore` `ResetButtonCallback` `task` `wait` `defer` `setResetButton` `Animation` `AnimationId` `createAnim` `type` `string` `pairs` `table` `isBusy` `isCamera` `BackpackEnabled` `SetAttribute` `startCamera` `Humanoid` `CameraSubject` `Custom` `CameraType` `RenderStepped` `Wait` `CameraOffset` `Vector3` `moveCamOffset` `isFighting` `Stop` `fight` `finish` `isTazed` `print` `Disabling reset button` `UnequipTools` `WalkSpeed` `JumpHeight`

### `Workspace.begginer_740.AntiJump` (LocalScript)

`Jump` `GetState` `Enum` `HumanoidStateType` `Freefall` `Jumping` `Landed` `clock` `math` `min` `game` `RunService` `GetService` `script` `Parent` `Humanoid` `WaitForChild` `GetPropertyChangedSignal` `Connect` `ffffff` `"7J`

### `Workspace.begginer_740.ClientInputHandler` (LocalScript)

`CFrame` `new` `Position` `workspace` `Unit` `Raycast` `Instance` `Parent` `GetPlayerFromCharacter` `Team` `Guards` `FireServer` `math` `random` `Pitch` `Play` `trimboi` `HasTag` `CheckHit` `GetMarkerReachedSignal` `Connect` `listenForHits` `pcall` `SetCore` `ResetButtonCallback` `task` `wait` `defer` `setResetButton` `Animation` `AnimationId` `createAnim` `type` `string` `pairs` `table` `isBusy` `isCamera` `BackpackEnabled` `SetAttribute` `startCamera` `Humanoid` `CameraSubject` `Custom` `CameraType` `RenderStepped` `Wait` `CameraOffset` `Vector3` `moveCamOffset` `isFighting` `Stop` `fight` `finish` `isTazed` `print` `Disabling reset button` `UnequipTools` `WalkSpeed` `JumpHeight`

### `Workspace.cOOlkiddK1ng031.AntiJump` (LocalScript)

`Jump` `GetState` `Enum` `HumanoidStateType` `Freefall` `Jumping` `Landed` `clock` `math` `min` `game` `RunService` `GetService` `script` `Parent` `Humanoid` `WaitForChild` `GetPropertyChangedSignal` `Connect` `ffffff` `"7J`

### `Workspace.cOOlkiddK1ng031.ClientInputHandler` (LocalScript)

`CFrame` `new` `Position` `workspace` `Unit` `Raycast` `Instance` `Parent` `GetPlayerFromCharacter` `Team` `Guards` `FireServer` `math` `random` `Pitch` `Play` `trimboi` `HasTag` `CheckHit` `GetMarkerReachedSignal` `Connect` `listenForHits` `pcall` `SetCore` `ResetButtonCallback` `task` `wait` `defer` `setResetButton` `Animation` `AnimationId` `createAnim` `type` `string` `pairs` `table` `isBusy` `isCamera` `BackpackEnabled` `SetAttribute` `startCamera` `Humanoid` `CameraSubject` `Custom` `CameraType` `RenderStepped` `Wait` `CameraOffset` `Vector3` `moveCamOffset` `isFighting` `Stop` `fight` `finish` `isTazed` `print` `Disabling reset button` `UnequipTools` `WalkSpeed` `JumpHeight`

### `Workspace.kenzo_mania5.AntiJump` (LocalScript)

`Jump` `GetState` `Enum` `HumanoidStateType` `Freefall` `Jumping` `Landed` `clock` `math` `min` `game` `RunService` `GetService` `script` `Parent` `Humanoid` `WaitForChild` `GetPropertyChangedSignal` `Connect` `ffffff` `"7J`

### `Workspace.kenzo_mania5.ClientInputHandler` (LocalScript)

`CFrame` `new` `Position` `workspace` `Unit` `Raycast` `Instance` `Parent` `GetPlayerFromCharacter` `Team` `Guards` `FireServer` `math` `random` `Pitch` `Play` `trimboi` `HasTag` `CheckHit` `GetMarkerReachedSignal` `Connect` `listenForHits` `pcall` `SetCore` `ResetButtonCallback` `task` `wait` `defer` `setResetButton` `Animation` `AnimationId` `createAnim` `type` `string` `pairs` `table` `isBusy` `isCamera` `BackpackEnabled` `SetAttribute` `startCamera` `Humanoid` `CameraSubject` `Custom` `CameraType` `RenderStepped` `Wait` `CameraOffset` `Vector3` `moveCamOffset` `isFighting` `Stop` `fight` `finish` `isTazed` `print` `Disabling reset button` `UnequipTools` `WalkSpeed` `JumpHeight`

### `Workspace.ninja243934.AntiJump` (LocalScript)

`Jump` `GetState` `Enum` `HumanoidStateType` `Freefall` `Jumping` `Landed` `clock` `math` `min` `game` `RunService` `GetService` `script` `Parent` `Humanoid` `WaitForChild` `GetPropertyChangedSignal` `Connect` `ffffff` `"7J`

### `Workspace.ninja243934.ClientInputHandler` (LocalScript)

`CFrame` `new` `Position` `workspace` `Unit` `Raycast` `Instance` `Parent` `GetPlayerFromCharacter` `Team` `Guards` `FireServer` `math` `random` `Pitch` `Play` `trimboi` `HasTag` `CheckHit` `GetMarkerReachedSignal` `Connect` `listenForHits` `pcall` `SetCore` `ResetButtonCallback` `task` `wait` `defer` `setResetButton` `Animation` `AnimationId` `createAnim` `type` `string` `pairs` `table` `isBusy` `isCamera` `BackpackEnabled` `SetAttribute` `startCamera` `Humanoid` `CameraSubject` `Custom` `CameraType` `RenderStepped` `Wait` `CameraOffset` `Vector3` `moveCamOffset` `isFighting` `Stop` `fight` `finish` `isTazed` `print` `Disabling reset button` `UnequipTools` `WalkSpeed` `JumpHeight`

### `Workspace.phaf168.AntiJump` (LocalScript)

`Jump` `GetState` `Enum` `HumanoidStateType` `Freefall` `Jumping` `Landed` `clock` `math` `min` `game` `RunService` `GetService` `script` `Parent` `Humanoid` `WaitForChild` `GetPropertyChangedSignal` `Connect` `ffffff` `"7J`

### `Workspace.phaf168.ClientInputHandler` (LocalScript)

`CFrame` `new` `Position` `workspace` `Unit` `Raycast` `Instance` `Parent` `GetPlayerFromCharacter` `Team` `Guards` `FireServer` `math` `random` `Pitch` `Play` `trimboi` `HasTag` `CheckHit` `GetMarkerReachedSignal` `Connect` `listenForHits` `pcall` `SetCore` `ResetButtonCallback` `task` `wait` `defer` `setResetButton` `Animation` `AnimationId` `createAnim` `type` `string` `pairs` `table` `isBusy` `isCamera` `BackpackEnabled` `SetAttribute` `startCamera` `Humanoid` `CameraSubject` `Custom` `CameraType` `RenderStepped` `Wait` `CameraOffset` `Vector3` `moveCamOffset` `isFighting` `Stop` `fight` `finish` `isTazed` `print` `Disabling reset button` `UnequipTools` `WalkSpeed` `JumpHeight`

### `Workspace.realdual_burst.AntiJump` (LocalScript)

`Jump` `GetState` `Enum` `HumanoidStateType` `Freefall` `Jumping` `Landed` `clock` `math` `min` `game` `RunService` `GetService` `script` `Parent` `Humanoid` `WaitForChild` `GetPropertyChangedSignal` `Connect` `ffffff` `"7J`

### `Workspace.realdual_burst.ClientInputHandler` (LocalScript)

`CFrame` `new` `Position` `workspace` `Unit` `Raycast` `Instance` `Parent` `GetPlayerFromCharacter` `Team` `Guards` `FireServer` `math` `random` `Pitch` `Play` `trimboi` `HasTag` `CheckHit` `GetMarkerReachedSignal` `Connect` `listenForHits` `pcall` `SetCore` `ResetButtonCallback` `task` `wait` `defer` `setResetButton` `Animation` `AnimationId` `createAnim` `type` `string` `pairs` `table` `isBusy` `isCamera` `BackpackEnabled` `SetAttribute` `startCamera` `Humanoid` `CameraSubject` `Custom` `CameraType` `RenderStepped` `Wait` `CameraOffset` `Vector3` `moveCamOffset` `isFighting` `Stop` `fight` `finish` `isTazed` `print` `Disabling reset button` `UnequipTools` `WalkSpeed` `JumpHeight`

### `Workspace.tr5zdhtdth.AntiJump` (LocalScript)

`Jump` `GetState` `Enum` `HumanoidStateType` `Freefall` `Jumping` `Landed` `clock` `math` `min` `game` `RunService` `GetService` `script` `Parent` `Humanoid` `WaitForChild` `GetPropertyChangedSignal` `Connect` `ffffff` `"7J`

### `Workspace.tr5zdhtdth.ClientInputHandler` (LocalScript)

`CFrame` `new` `Position` `workspace` `Unit` `Raycast` `Instance` `Parent` `GetPlayerFromCharacter` `Team` `Guards` `FireServer` `math` `random` `Pitch` `Play` `trimboi` `HasTag` `CheckHit` `GetMarkerReachedSignal` `Connect` `listenForHits` `pcall` `SetCore` `ResetButtonCallback` `task` `wait` `defer` `setResetButton` `Animation` `AnimationId` `createAnim` `type` `string` `pairs` `table` `isBusy` `isCamera` `BackpackEnabled` `SetAttribute` `startCamera` `Humanoid` `CameraSubject` `Custom` `CameraType` `RenderStepped` `Wait` `CameraOffset` `Vector3` `moveCamOffset` `isFighting` `Stop` `fight` `finish` `isTazed` `print` `Disabling reset button` `UnequipTools` `WalkSpeed` `JumpHeight`

## Server-side reachability (what is NOT in the dump)

The dump contains **no server-side code**. Every one of the 103 scripts is
client-reachable: 54 `LocalScript`, 19 `Script` (client / shared `RunContext`),
30 `ModuleScript`. Nothing under `ServerScriptService` or `ServerStorage` appears,
because Roblox never replicates those to clients — so the server's authoritative
logic (what actually validates a shot, an arrest, a team change, a purchase)
cannot be read from a client dump. This is not a bypassable protection; the bytes
are not on the machine.

The only server-authoritative surface reachable from the client is the **remotes**
listed above — that is the complete set of "server-side actions" an exploit can
trigger. Notable server-gated markers seen in the client code:

- `isAuthenticated` / `PlayerOwnsAsset` / `isPremium` / `premiumType` — the server
  gates premium items; the client only asks (`BuyGamepassRequested`).
- `adminSprintSpeed` — an admin/guard sprint-speed attribute set by the server.
- No cash/economy remote is exposed (Prison Life has no client-callable money grant);
  progression is arrest/round based and validated server-side.

Bottom line: additional "server-side" features can only be built on the documented
remotes — there is no hidden server script to lift logic from.
