# Chicken or Hero — Deobfuscated API Reference

Recovered from the whole-game client code dump `Ugc (PlaceId 107535308163741)`, dumped 2026-11-21 (hex-encoded Luau bytecode, 3-part paste).

> **What this is.** The dump is Luau **bytecode**, not source. Bytecode cannot be reliably decompiled to source by hand, but every string constant a script carries — remote names, command verbs, attribute keys, catalog item names, method calls — lives in its constant table and *is* fully recoverable. Extracting it exposes each script's real client-facing API surface. Numeric constants, operand order and control flow are **not** reconstructed, so remote argument shapes below are inferred from co-located strings and should be treated as best-effort (always `pcall`-guard calls). Server `Script`s in ServerScriptService/ServerStorage are never sent to the client and are not in this dump.

**Scripts decoded:** 844 (403 LocalScript, 439 ModuleScript, 2 Script). Every section decoded with zero failures.

## Game model (inferred from `Game.GameConfig` + client names)

Chicken or Hero is a **round-based catch / chase** game. Config keys recovered from `GameConfig`: `MinPlayers`, `MaxMatchPlayers`, `Countdown`, `SetupTime`, `SelectionTime`, `HeroTime`, `RunTime`, `ResultsTime`, `CleanEscapesToWin`, `LateJoinAsCatcher`, and a `Tackle` block (`Duration`, `Recovery`, `Cooldown`, `DistanceMultiplier`, `BoostStrength`, `MaxDistance`). Players hold a **`GameRole`** attribute (`Runner` / `Catcher` / Hero) and an **`InMatch`** flag. Mechanics present: Blade-Ball style catch (`BladeBallConfig`/`BladeBallPhysics`), tackle (`TackleMotion`/`TacklePrediction`), boost (`BoostRequest`), bosses (`FallenKingBossConfig`, `BossCombat`), ranked (`RankedConfig`/`RankedRanks`/`RankedRegions`), and a Halloween event layer (candy corn, pumpkin hunt, blood moon, haunt, ghost trader).

## Remote index

Comm markers in the dump: `FireServer` in 190 scripts, `OnClientEvent` in 212, `InvokeServer` in 5, `FireAllClients`/`FireClient`/`OnServerEvent` server-side. The game uses a **command-dispatch pattern**: one RemoteEvent per subsystem, with the first argument a command string. Remotes are resolved by child lookup under `ReplicatedStorage.ChickenOrHero.*` (containers seen: `Events`, `Remotes`, `Net`).

| Remote (`*Event` / `*Remote` / `*Request`) | # client scripts | example callers |
|---|---:|---|
| `ArmoryEvent` | 48 | AbilityUpgradeMenu, AbilityUseClient, AlleyOopClient |
| `GearEvent` | 31 | AbilityUseClient, AlleyOopClient, ContentTeamClient |
| `EmoteEvent` | 14 | ContentTeamClient, CursorHintClient, EmoteAnchorClient |
| `BoostRequest` | 14 | CharacterMovementClient, PerfectDodgeClient |
| `FallenKingEvent` | 13 | FallenKingBombClient, FallenKingClient, FallenKingHeartsClient |
| `CrateEvent` | 10 | ContentTeamClient, CrateClient, KusarigamaQuickTest |
| `FootballEvent` | 7 | EventIntroClient, FootballEventClient, FootballEventWorld |
| `AdminEvent` | 6 | AdminClient, AwardNoticeClient, CreatorClient |
| `JourneyEvent` | 6 | EventTopbarClient, JourneyClient, MatchResultPanel |
| `SpectateEvent` | 6 | GuardClient, SpectateClient, SpectateLoadoutClient |
| `OpenRequest` | 5 | CombineScreen, SpinWheelClient, SpinWheelTopbarClient |
| `CombineEvent` | 5 | CombineChatClient, CombineScreen, MergeMachineClient |
| `GAEvent` | 5 | ClientAnalytics, GAClient, ServerAnalytics |
| `QuestEvent` | 5 | QuestClient, QuestTrackerClient, StorefrontClient |
| `SpinWheelEvent` | 4 | AdController, SpinWheelClient |
| `HalloweenShopEvent` | 4 | ArmoryClient, HalloweenStoreClient |
| `StarterPackEvent` | 4 | BalloonOfferClient, StarterPackClient |
| `EventHostRemote` | 4 | EventAudienceClient, JoinEventPrompt |
| `TeamEvent` | 4 | FootballEventClient, FootballEventWorld |
| `TeamEventRemote` | 4 | FootballEventClient, FootballEventWorld |
| `VowAbilityEvent` | 4 | GearUseClient, VowbreakerEffectsClient |
| `KusarigamaEvent` | 4 | KusarigamaClient, KusarigamaQuickTest |
| `JumpRequest` | 3 | EmoteAnchorClient, EmoteParty |
| `PumpkinHuntEvent` | 3 | PumpkinPedestalClient, SacrificeScreen |
| `PumpkinEvent` | 3 | PumpkinPedestalClient, PumpkinScreen |
| `TruckAbilityEvent` | 3 | KnifeAbilities, TruckEffectsClient |
| `TutorialEvent` | 3 | GearStoreClient, TutorialClient |
| `GetEvent` | 3 | Entity, Player, Replicate |
| `FireEvent` | 3 | Entity, Replicate, Sender |
| `SpinWheelAdEvent` | 2 | AdController |
| `AlbieRemote` | 2 | AlbieClient |
| `BladeBallEvent` | 2 | BladeBallClient |
| `CandyCornEvent` | 2 | CandyCornPickupClient |
| `CaughtLoadoutEvent` | 2 | CaughtLoadoutClient |
| `CloneAbilityEvent` | 2 | CloneAbilityClient |
| `CodeEvent` | 2 | CodesClient |
| `ContentTeamRemote` | 2 | ContentTeamClient |
| `CrateRollEvent` | 2 | CrateRollOverheadClient |
| `CrossyRoadEvent` | 2 | CrossyRoadClient |
| `CutsceneEvent` | 2 | CutsceneClient |
| `DodgeballEvent` | 2 | DodgeballClient |
| `DonkeyKongEvent` | 2 | DonkeyKongClient |
| `EventIntroRemote` | 2 | EventIntroClient |
| `GemEvent` | 2 | GemPickupClient |
| `GhostAbilityEvent` | 2 | GhostAbilityClient |
| `GhostTraderEvent` | 2 | GhostTraderClient |
| `GiveawayEvent` | 2 | GiveawayClient |
| `MovementGuardEvent` | 2 | GuardClient |
| `HauntEvent` | 2 | HauntClient |
| `Next Event` | 2 | JoinEventPrompt |
| `PromptEvent` | 2 | JoinEventPrompt |
| `LastRunnerChatEvent` | 2 | LastRunnerChatClient |
| `LateJoinRemote` | 2 | LateJoinClient |
| `LevelRewardEvent` | 2 | LevelRewardClient |
| `MapVoteEvent` | 2 | MapVoteClient |

## Command verbs by subsystem

These are the non-API capitalized constants in each subsystem's client, i.e. the most likely `Event:FireServer("<verb>", ...)` command strings and the catalog/attribute keys they act on. Argument order is not recoverable; guard every call.

**Gear / loadout — `GearEvent`, `ArmoryEvent`**  (`GearStoreClient`)

```
textStroke  GetService  FFlags  awaitUIVersion  NewGui  Interface  Toasts  Presentation  ValleyToast  bundleOnly  workspace  bundled  Bundle  isOnSale  bundleOf  Item  TutorialStep  BuyAdrenaline  tutorialFree  GetTextSize  gmatch  MouseEnter  MouseLeave  SelectionGained  SelectionLost  AbilityUpgradeMenu  equippedGear  equippedForRole  UseRole  Weapons  BundlePanel  Kind  Ability  Free  ArmoryEvent  EquipGear  FireServer  Gems  BuyGearGems  SoldFor  coins  player  Game  TutorialEvent  Adrenaline
```

**Abilities — `ArmoryEvent`**  (`AbilityUpgradeMenu`)

```
floor  reverse  comma  round2  spots  format  studs  speed  Base  Levels  levelId  fields  labelOf  count  Perks  Stats  changes  secondary  Order  Kind  Ability  UseRole  levels  abilitiesFor  abilityLevels  levelOf  abilityTokens  tokensOf  abilities  Burrow  workspace  RewardOnly  short  REWARD  RewardText  UnlockText  bundleOnly  Bundle  isOnSale  BUNDLE  bundle  locked  SOON  SoldFor  coins
```

**Crates — `CrateEvent`, `CrateRollEvent`**  (`CarouselClient`)

```
rider  workspace  Ragdolled  onDeck  carryMine  IsDescendantOf  Angles  angle  BulkMoveMode  FireCFrameChanged  BulkMoveTo  Horses  AncestryChanged  PreSimulation  start  clock  ActiveMapId  Map  model  refresh  GetService  ChickenOrHero  Game  CarouselConfig
```

**Halloween shop — `HalloweenShopEvent`**  (`HauntClient`)

```
IsCollisionGroupRegistered  CoHRagdoll  Default  Animation  AnimationId  animation  playing  Sounds  clock  workspace  range  random  RollOffMinDistance  RollOffMaxDistance  Ended  sound  Emit  fromRGB  NumberSequenceKeypoint  Lifetime  Speed  SpreadAngle  Acceleration  RotSpeed  NormalId  EmissionDirection  Rise  refreshOutline  tracks  IsPlaying  Stop  stopTracks  fadeAway  model  value  HitFrom  Skeleton  SkeletonBreak  SkeletonBreak2  ZombieDeath  Massless  CollisionGroup  AssemblyAngularVelocity  Part0  Part1
```

**Ranked — `TeamEvent`**  (`RankedMenuClient`)

```
nunito  round  sizeFor  parse  RankedRegions  picks  floor  comma  format  clock  DateTime  fromUnixTimestamp  FormatLocalTime  localTime  endsAt  seasonEnds  season  seasonId  ordinal  signed  corner  stroke  authored  fromOffset  image  PhoneSize  UITextSizeConstraint  MinTextSize  fixed  resize  black  ClipsDescendants  fromScale  number  Ring  Mark  markFrame  xMark  clockMark  globeMark  Tile  Glyph  muted  Value  Delta
```

## Player / state attributes (read via `GetAttribute` — reliable)

| Attribute | seen in # scripts | likely meaning |
|---|---:|---|
| `InMatch` | 193 | true during a round |
| `Weapons` | 152 | owned weapons set |
| `GameRole` | 138 | Runner / Catcher / Hero |
| `Session` | 116 | session id/state |
| `Gear` | 106 | owned gear set |
| `Skin` | 96 | equipped skin |
| `Emotes` | 70 | owned emotes |
| `Coins` | 66 | soft currency |
| `Gold` | 63 | currency/score |
| `MovementLocked` | 62 | movement lock |
| `Gems` | 53 | premium currency |
| `PracticeActive` | 48 | practice mode flag |
| `AbilityLevels` | 40 | per-ability unlock level |
| `CandyCorn` | 32 | event currency |
| `GlobalPaused` | 32 | global pause flag |
| `Adrenaline` | 27 | ability charge resource |

## Config module highlights

**`Game.GameConfig`** — Round timings & tackle

```
Movement  MovementConfig  SpeedScale  freeze  MaxMatchPlayers  MinPlayers  Countdown  SetupTime  FirstSetupTime  ResultsTime  PostMatchLobbyTime  SelectionTime  ChoiceTime  HeroTime  RunTime  CleanEscapesToWin  LateJoinAsCatcher  PlayerCollisions  Tick  MapName  Map1  CharacterReadyTimeout  Tackle  Duration  Recovery  Cooldown  DistanceMultiplier  RunDistanceMultiplier  BoostStrength  MaxDistance  Animation  DaggerDive  Distance  Width  Height  Reach  RunnerRadius  Variants  HumanBox  MinSpeedRatio
```

**`Gear.GearCatalog`** — Weapons / abilities catalog

```
random  boxYaw  Items  SpringBox  ShakeSeconds  clamp  identity  Angles  boxShake  ThrowRange  MomentumLead  MomentumMaxSpeed  FlightSeconds  AheadMin  throwReaches  Bundle  Weapons  Bundles  EndsAt  workspace  bundleOnly  Unlock  FallenKing  Game  FallenKingProgress  locked  Pair  Disabled  equippedAbilities  equippedAbility  UseRole  equippedForRole  GetService  FFlags  SalesEnabled  MaxInventory  PackSize  Order  Lifeline  RescueKit
```

**`Crates.CrateCatalog`** — Crate contents

```
Crates  number  Entries  Weight  Kind  Emote  random  poseEmote  Bundles  offer  Order  DuplicateGems  Basic2  Premium2  Ember  Celestial  GymEmote  Common  Rare  Epic  Legendary  Mythical  Basic  Premium  OldBasicCrate  Coins  ProductId  fromRGB  Skin  CopperBite  Rarity  Ashsteel  IronFang  ForestEdge  AmberSting  RoseQuartz  TidalShard  VenomThorn  MoltenFang  StormTalon
```

**`Collectibles.CandyCornConfig`** — Candy-corn spawns

```
freeze  EmptyChance  Layouts  StackValues  MaxGemsPerCrossing  EdgeMargin  SafeMargin  Separation  HoverHeight  PickupRadius  VerticalTolerance  PollInterval  MaxSampleGap  MaxSampleSpeed  PositionSlack  MaxVisibleDistance  Weight  Value
```

**`Collectibles.GemConfig`** — Gem spawns

```
freeze  EmptyChance  Layouts  StackValues  MaxGemsPerCrossing  EdgeMargin  SafeMargin  Separation  HoverHeight  PickupRadius  VerticalTolerance  PollInterval  MaxSampleGap  MaxSampleSpeed  PositionSlack  MaxVisibleDistance  Weight  Value
```

**`Game.RankedConfig`** — Ranked

```
MinLevel  AccountAgeDays  LeaveSafeSeconds  HeroRevealSeconds  EndEventRounds  EndEventChaserShare  MaxRounds  RemoveIdleChasers  PressureStuds  UnpressuredCrossing  IdleChaserRounds  FlagPoints  FlagEasyCrossings  SuspectRPPerMatch  SuspectAverageChange  SuspectCrossings  SuspectSingleChange  SoftPlayStuds  SoftPlaySeconds  FeedMatches  MateMatches  DuoMatches  FlagFeedDays  QuickRunSpeed  QuickRunJumpStuds  TrendMatches  TrendLMS  TrendCatches  TrendQuick  Crossing  CrossingPerChasers  CrossingMax  Hero  HeroPerChaser  HeroMax  EndEventRound  Win  LastCaught  Catch  BountyPerCrossing
```

**`Game.HalloweenShopConfig`** — Halloween shop

```
bit32  lshift  create  DateTime  fromUniversalTime  UnixTimestamp  nthSunday  pacificOffset  Day  ResetHour  dayStart  floor  TitleStart  TitleDays  RotatingTitles  title  badge  color  price  rotating  rotatesAt  RotatingEmotes  emote  Emote  rotation  Emotes  EmoteCatalog  Rarity  Common  rarity  EmotePrices  Items  Knife  stock  Packs  productId  testProductId  packByProduct  GameId  TestUniverseId
```

## Recovered script tree

- **Players.<you>.PlayerGui** (17): ActionBarController, AdClient, AdController, Audio, Boot, ButtonStates, ChoiceSpotlightClient, HUDController, HUDStack, LobbyControlsClient, MatchResultClient, NotificationsController, OutcomeScreenClient, ShowcaseClient, SpinWheelClient, ThemeColors, ThreatIndicatorClient
- **Players.<you>.PlayerScripts** (191): AbilityBuffVisuals, AbilityUseClient, AdrenalineFeelClient, AlbieClient, AlleyOopClient, AnimateVioletRift, ArmoryClient, Attribute, AudioClient, AuthoredScreensSweepClient, AwardNoticeClient, BalloonOfferClient, BladeBallClient, BloodMoonClient, BodyFacingClient, BonkSplatClient, BoostInputClient, BoostVFXClient, BotRenderClient, CameraFeelClient, CandyCornPickupClient, Caption, CarouselClient, CatchFeedbackClient, CatcherReachClient, CaughtLoadoutClient, ChronoClient, ClanClient, Classic, CloneAbilityClient, CodesClient, CombineChatClient, CombineClient, ConnectionQualityClient, Container, ContentTeamClient, CrateClient, CrateDisplayClient, CrateRollOverheadClient, CreatorClient, CrossyRoadClient, CupTrailerClient, CursorHintClient, CutsceneClient, DaggerVisualClient, Default, DisorientClient, DodgeballClient, DonkeyKongClient, Dropdown, EmoteAnchorClient, EmoteClient, EmotePiecesClient, EmoteVFXClient, EventAudienceClient, EventIntroClient, EventTopbarClient, FFALivesClient, FallenKingBombClient, FallenKingBossClient, FallenKingClient, FallenKingHeartsClient, FallenKingReviveClient, FallenKingSpoilsClient, FallenKingStatueClient, FallenKingSummonClient, FootDustClient, FootballEventClient, FootballEventWorld, FootballShowClient, FrostQuakeClient, GAClient, Gamepad, GearJuiceClient, GearUseClient, GemPickupClient, GhostAbilityClient, GhostTraderClient, GiveawayClient, GoodSignal, GuardClient, HalloweenStoreClient, HauntClient, HitReplayClient, HostFlightClient, HoverShowClient, IceBreathClient, IceSkatesClient, Icon, IdleReportClient, Indicator, Janitor, JoinEventPrompt, JourneyClient, KillEffectTestClient, KnifeBonusClient, KnockdownStreakClient, KusarigamaClient, KusarigamaGrabLoopFix, KusarigamaQuickTest, LastRunnerChatClient, LateJoinClient, LeaderboardClient, LegacyUIClient, LevelRewardClient, LifelineClient, LightsOutClient, LikeRewardClient, LobbyKnifeDisplays, LobbyKnifeKeys, LocalLocomotionClient, LockedCameraClient, Map5AmbienceClient, MapLightingClient, MapVoteClient, MeleeInputClient, Menu, MenuScaleClient, MergeDisplayClient, MergeMachineClient, MythicKillClient, NoAbilitiesClient, Notice, OutbreakClient, Overflow, OverheadClient, PerfectDodgeClient, PirateShowClient, PiratesCallClient, PracticeClient, PreRoundDisableClient, PricePrefetchClient, PrivateHostClient, ProServerClient, PumpkinBombClient, PumpkinPedestalClient, PumpkinPeopleClient, PumpkinSacrificeClient, PumpkinsClient, QuestClient, QuestTrackerClient, RainingTokensClient, RankedClient, RankedLoadoutClient, RankedMenuClient, RankedPodiumClient, ReadableTextClient, Reference, RescueClient, ReviveOfferClient, RoleMarkerVisibility, SacrificeBoardsClient, SafezoneSignsClient, SeesawClient, Selection, ServerBrowserClient, SettingsSyncClient, SkateSpinClient, SlapstickClient, SnowFlurryClient, SoulReapClient, SpectateClient, SpectateLoadoutClient, SpikeClient, SpinWheelTopbarClient, StarterPackClient, StudioAbilityTestClient, StudioEmotePreviewClient, StudioKnifePreviewClient, TackleDebugClient, TackleInputClient, TestUIToggleClient, Themes, TimeWarpClient, TournamentResultsClient, TrollClient, TruckAbilityClient, TruckEffectsClient, TutorialClient, Types, UltimateEmoteButton, Utility, VERSION, VIPChatClient, ValleyHudClient, ViewBeaconClient, VowbreakerEffectsClient, WarHornClient, WeaponVFXClient, Widget, WorldShopClient
- **ReplicatedFirst.AdminPresentation.AdminClient** (1): AdminClient
- **ReplicatedFirst.FFlags** (1): FFlags
- **ReplicatedFirst.GAClient** (1): GAClient
- **ReplicatedFirst.LazySound** (1): LazySound
- **ReplicatedFirst.LazySoundsClient** (1): LazySoundsClient
- **ReplicatedFirst.ProportionalUIClient** (1): ProportionalUIClient
- **ReplicatedFirst.ScreenPresentation.IrisController** (1): IrisController
- **ReplicatedFirst.ScreenPresentation.LoadingProgress** (1): LoadingProgress
- **ReplicatedFirst.ScreenPresentation.ReadyHandshake** (1): ReadyHandshake
- **ReplicatedFirst.ScreenPresentation.ScreenConfig** (1): ScreenConfig
- **ReplicatedFirst.ScreenPresentation.ScreenPresentationClient** (1): ScreenPresentationClient
- **ReplicatedFirst.Soundtracks.MusicClient** (1): MusicClient
- **ReplicatedFirst.Soundtracks.MusicConfig** (1): MusicConfig
- **ReplicatedFirst.Soundtracks.MusicController** (1): MusicController
- **ReplicatedFirst.UIProportions** (1): UIProportions
- **ReplicatedStorage.ChickenOrHero.Admin** (5): CommandCatalog, CommandCompletion, EventHostCatalog, EventHostLayout, GiveawayRules
- **ReplicatedStorage.ChickenOrHero.Animation** (14): AnimationConfig, AnimationLibrary, AnimationPolicy, DaggerAnimation, DashAnimation, DashAnimationPolicy, DodgeStyles, IceSkateEffects, IceSkating, LocalLocomotion, LocomotionTracks, MeleeAttackTimeline, StopAnimationPolicy, TackleAnimation
- **ReplicatedStorage.ChickenOrHero.Audio** (10): AudioCatalog, AudioConfig, AudioPlayback, AudioPolicy, DaggerAudio, DefaultCharacterAudio, FantasyKnifeAudio, InterfaceAudio, MovementAudio, ThreatAudio
- **ReplicatedStorage.ChickenOrHero.Bots** (8): BotDirectory, BotFrameCodec, BotNetConfig, ClientBotAnimator, ClientBotKnife, ClientBotKnockdown, ClientBotOutline, ClientBotRenderer
- **ReplicatedStorage.ChickenOrHero.Collectibles** (2): CandyCornConfig, GemConfig
- **ReplicatedStorage.ChickenOrHero.Crates** (5): CrateCatalog, CrateLuck, CrateReel, CrateRollConfig, OverheadRoll
- **ReplicatedStorage.ChickenOrHero.Emotes** (6): DailyEmotes, EmoteCatalog, EmotePieces, EmotePlayback, EmoteSync, EmoteVFX
- **ReplicatedStorage.ChickenOrHero.Game** (43): AbilityRule, BladeBallConfig, BladeBallPhysics, BloodMoonConfig, BossCombat, CandyCorn, CarouselConfig, ChronoSetup, ClanConfig, CombatClaimMath, CombatPrediction, ConnectionQualityConfig, ContactCatchConfig, ContactCatchGeometry, CrossyRoadMotion, DonkeyKongMotion, FallenKingBossConfig, FallenKingConfig, GameConfig, GhostTraderConfig, HalloweenShopConfig, HauntConfig, HitReplayMath, MapLocator, MapVoteConfig, MapVotePolicy, OutbreakConfig, PracticeConfig, PrivateHostCatalog, PumpkinHuntConfig, RandomPrizePolicy, RankedConfig, RankedLoadout, RankedRanks, RankedRegions, RescueConfig, ReviveOfferConfig, TackleCollision, TackleMotion, TacklePrediction, TacklePredictionConfig, TackleProfile, TutorialConfig
- **ReplicatedStorage.ChickenOrHero.Gear** (10): AbilityFlair, AbilityLevels, AbilityUpgradeMenu, AirhornCone, GearCatalog, GearPredictionClient, GearStoreClient, PumpkinSmoke, RufusLeashCast, StarterPackConfig
- **ReplicatedStorage.ChickenOrHero.Interface** (25): AvatarPortrait, CharacterClone, CharacterFrame, CharacterPreview, ClaimPop, ClanHall, ClanMenu, CrateLanes, Cursor, EmotePose, EmoteSound, InputMode, KnifeClipPreview, MatchResultPanel, Panels, Preview, PreviewButton, ProductPrices, Registry, RewardPop, Signal, TeamEventBoard, TeamEventCelebration, Telemetry, Widgets
- **ReplicatedStorage.ChickenOrHero.LegacyUI** (31): AbilityUseClient, ActionBarController, ArmoryClient, BalloonOfferClient, ChoiceSpotlightClient, CloneAbilityClient, CombineClient, ConnectionQualityClient, CrateClient, CursorHintClient, EmoteClient, GearUseClient, GhostAbilityClient, GuardClient, JourneyClient, LikeRewardClient, LobbyControlsClient, MapVoteClient, MatchResultClient, NotificationsController, PerfectDodgeClient, PrivateHostClient, PumpkinSacrificeClient, PumpkinsClient, QuestClient, ServerBrowserClient, SpectateClient, StarterPackClient, TruckAbilityClient, ValleyHudClient, WorldShopClient
- **ReplicatedStorage.ChickenOrHero.Movement** (13): BodyFacingConfig, BodyFacingModel, BoostInput, CameraCollision, CameraFeelConfig, CannonMotion, ControlGate, CrossingBalance, MovementConfig, MovementModel, MovementPresentation, MovementProfiles, StepOverMotion
- **ReplicatedStorage.ChickenOrHero.OldUIReskin** (2): JourneyHalloween, Skin
- **ReplicatedStorage.ChickenOrHero.Presentation** (95): ArmoryStyle, AuthoredScreens, AvatarPortraits, BalloonLift, BoneRattle, BonkSplat, BoostVFXConfig, BundleNotice, CatchMeterModel, CaughtLoadoutCard, ChoiceController, ChoiceSpotlightConfig, ChoiceView, ClanBanner, CombineScreen, CreatorPolicy, CreatorView, CreatorVisibility, CrossingBalanceNotice, CutsceneScreen, DashMeterModel, EclipseCutscene, EmoteWheelPreviews, EmoteWheelView, EquipmentHudLayoutLegacy, EscapeStreakController, FallenKingAltar, FallenKingSpoils, FootDustConfig, FootballShots, FrostbitePillar, FullscreenBackdrop, GhostKeyDrop, GhostTraderView, GiftScreen, GiveawayPicker, GiveawayView, HalloweenCrateShow, HalloweenShopScreen, HoverShots, HudDrawer, HudIcons, HudNavigation, HudStyle, LeaderboardConfig, LeaderboardHeader, LocalHide, LocalLooks, MapPreviewCopy, MapVoteTiming, MapVoteView, MatchSummaryConfig, NotificationDock, NotificationLayout, OverheadConfig, OverheadView, ParticipantDirectory, PirateShots, PostMatchProgress, PracticeScreen, PracticeWorlds, PrivateHostModel, ProUnlockCutscene, PumpkinAltar, PumpkinFloat, PumpkinRoll, PumpkinScreen, QuestNotice, ReachPose, RecapHighlights, RecapRewards, RecapSoloWin, ReviveMarkers, SacrificeScreen, ServerBrowserView, SettingsSync, SoulShock, SpectateCamera, SpectateConfig, SpectateGeometry, SpectateInput, SpectateView, ThreatIndicatorConfig, ThreatIndicatorModel, TouchActionButton, TouchCombatLayout, UIVersionSwap, UpdateLogConfig, ValleyHudView, ValleyPanels, ValleyTheme, ValleyToast, VerifiedName, WarHornFocus, WarbannerBlaze
- **ReplicatedStorage.ChickenOrHero.Progression** (10): JourneyConfig, JourneyMath, JourneySeason1Rewards, JourneySeason2Rewards, JourneySeason3Rewards, JourneySeasons, LevelRewards, ProgressionConfig, ProgressionMath, TeamEventConfig
- **ReplicatedStorage.ChickenOrHero.Trolls** (9): EmoteParty, FloorIsLava, Jump, LootRain, LowGravity, Notify, Spotlight, SwapPlaces, TrollShared
- **ReplicatedStorage.ChickenOrHero.Weapons** (36): BundlePanel, Bundles, CloneAbilityConfig, CloneEchoMotion, CloneSplitEffects, CombineConfig, ComedySkinCatalog, CurrencyTopUp, DaggerConfig, DaggerGrip, DailyEmoteOffers, DualWield, EmoteStoreClient, EventKnivesOffer, FantasySkinCatalog, GiftClient, GiftConfig, KillEffects, KnifeAbilities, KnifeChains, KnifeClips, KnifeDisplayRig, KnifeIconCopy, KnifeIcons, KnifePerks, KnifeVFXSetup, KnifeVisibility, KusarigamaCastHold, KusarigamaConfig, MergeEventInfo, OfferRules, ScythePose, ShopConfig, SkinCatalog, StorefrontClient, WeaponEffects
- **ReplicatedStorage.EmitModule** (1): EmitModule
- **ReplicatedStorage.EmitModule.effects** (12): beam, bezier, camera_shake, lightning, mesh, particle, screen, shockwave_debris, shockwave_line, shockwave_ring, spin, tween_property
- **ReplicatedStorage.EmitModule.emitters** (1): emitters
- **ReplicatedStorage.EmitModule.mod** (8): Oklab, bezier_common, lerp, logger, sRGB, shape, tween, utility
- **ReplicatedStorage.EmitModule.obj** (2): Bezier, ObjectCache
- **ReplicatedStorage.EmitModule.pkg** (2): Promise, Shake
- **ReplicatedStorage.EmitModule.services** (4): caches, effects, enabled_effects, texture_loader
- **ReplicatedStorage.EmitModule.types** (1): types
- **ReplicatedStorage.GA** (1): GA
- **ReplicatedStorage.GA.Client** (3): ClientAnalytics, RemoteConfig, SessionManager
- **ReplicatedStorage.GA.Server** (9): BatchQueue, DeviceBootstrap, DeviceBuffer, EconomyTracker, PlayerTracker, RemoteConfig, ReplayRecorder, ReplayUploader, ServerAnalytics
- **ReplicatedStorage.GA.Shared** (5): Config, EventSchema, ReplayCodec, Signal, Types
- **ReplicatedStorage.SingleAdReward_ServerCode.AdServer** (1): AdServer
- **ReplicatedStorage.SingleAdReward_ServerCode.RewardSelector** (1): RewardSelector
- **ReplicatedStorage.SingleAdReward_ServerCode.SaveData** (1): SaveData
- **ReplicatedStorage.SingleAdReward_ServerCode.Telemetry** (1): Telemetry
- **ReplicatedStorage.chrono** (1): chrono
- **ReplicatedStorage.chrono.Client** (7): ClientClock, InterpolationBuffer, ModelResolver, Player, Receiver, Replicate, Sender
- **ReplicatedStorage.chrono.Server** (6): EntityGrid, Player, Receiver, Replicate, Sender, ServerClock
- **ReplicatedStorage.chrono.Shared** (17): AlignDriver, ApplyMounts, Bin, ClockUnwrap, Config, Entity, Events, Holder, InterpolationMath, ModelHelper, ReplicationRules, Signal, Snapshots, Stats, Ticker, Types, Warn
- **StarterGui.BundleShowcase.ShowcaseClient** (1): ShowcaseClient
- **StarterGui.OutcomeScreen.OutcomeScreenClient** (1): OutcomeScreenClient
- **StarterGui.Single_Ad_HUD_Reward.ClientCode** (7): AdClient, Audio, Boot, ButtonStates, HUDController, HUDStack, ThemeColors
- **StarterGui.SpinWheel.Main** (1): AdController
- **StarterGui.SpinWheel.SpinWheelClient** (1): SpinWheelClient
- **StarterGui.ThreatIndicator.ThreatIndicatorClient** (1): ThreatIndicatorClient
- **StarterPlayer.StarterCharacterScripts.CharacterAnimationClient** (1): CharacterAnimationClient
- **StarterPlayer.StarterCharacterScripts.CharacterMovementClient** (1): CharacterMovementClient
- **StarterPlayer.StarterCharacterScripts.NoDeathClient** (1): NoDeathClient
- **StarterPlayer.StarterPlayerScripts.AbilityBuffVisuals** (1): AbilityBuffVisuals
- **StarterPlayer.StarterPlayerScripts.AdrenalineFeelClient** (1): AdrenalineFeelClient
- **StarterPlayer.StarterPlayerScripts.AlbieClient** (1): AlbieClient
- **StarterPlayer.StarterPlayerScripts.AlleyOopClient** (1): AlleyOopClient
- **StarterPlayer.StarterPlayerScripts.AnimateVioletRift** (1): AnimateVioletRift
- **StarterPlayer.StarterPlayerScripts.AudioClient** (1): AudioClient
- **StarterPlayer.StarterPlayerScripts.AuthoredScreensSweepClient** (1): AuthoredScreensSweepClient
- **StarterPlayer.StarterPlayerScripts.AwardNoticeClient** (1): AwardNoticeClient
- **StarterPlayer.StarterPlayerScripts.BladeBallClient** (1): BladeBallClient
- **StarterPlayer.StarterPlayerScripts.BloodMoonClient** (1): BloodMoonClient
- **StarterPlayer.StarterPlayerScripts.BodyFacingClient** (1): BodyFacingClient
- **StarterPlayer.StarterPlayerScripts.BonkSplatClient** (1): BonkSplatClient
- **StarterPlayer.StarterPlayerScripts.BoostInputClient** (1): BoostInputClient
- **StarterPlayer.StarterPlayerScripts.BoostVFXClient** (1): BoostVFXClient
- **StarterPlayer.StarterPlayerScripts.BotRenderClient** (1): BotRenderClient
- **StarterPlayer.StarterPlayerScripts.CameraFeelClient** (1): CameraFeelClient
- **StarterPlayer.StarterPlayerScripts.CandyCornPickupClient** (1): CandyCornPickupClient
- **StarterPlayer.StarterPlayerScripts.CarouselClient** (1): CarouselClient
- **StarterPlayer.StarterPlayerScripts.CatchFeedbackClient** (1): CatchFeedbackClient
- **StarterPlayer.StarterPlayerScripts.CatcherReachClient** (1): CatcherReachClient
- **StarterPlayer.StarterPlayerScripts.CaughtLoadoutClient** (1): CaughtLoadoutClient
- **StarterPlayer.StarterPlayerScripts.ChronoClient** (1): ChronoClient
- **StarterPlayer.StarterPlayerScripts.ClanClient** (1): ClanClient
- **StarterPlayer.StarterPlayerScripts.CodesClient** (1): CodesClient
- **StarterPlayer.StarterPlayerScripts.CombineChatClient** (1): CombineChatClient
- **StarterPlayer.StarterPlayerScripts.ContentTeamClient** (1): ContentTeamClient
- **StarterPlayer.StarterPlayerScripts.CrateDisplayClient** (1): CrateDisplayClient
- **StarterPlayer.StarterPlayerScripts.CrateRollOverheadClient** (1): CrateRollOverheadClient
- **StarterPlayer.StarterPlayerScripts.CreatorClient** (1): CreatorClient
- **StarterPlayer.StarterPlayerScripts.CrossyRoadClient** (1): CrossyRoadClient
- **StarterPlayer.StarterPlayerScripts.CupTrailerClient** (1): CupTrailerClient
- **StarterPlayer.StarterPlayerScripts.CutsceneClient** (1): CutsceneClient
- **StarterPlayer.StarterPlayerScripts.DaggerVisualClient** (1): DaggerVisualClient
- **StarterPlayer.StarterPlayerScripts.DisorientClient** (1): DisorientClient
- **StarterPlayer.StarterPlayerScripts.DodgeballClient** (1): DodgeballClient
- **StarterPlayer.StarterPlayerScripts.DonkeyKongClient** (1): DonkeyKongClient
- **StarterPlayer.StarterPlayerScripts.EmoteAnchorClient** (1): EmoteAnchorClient
- **StarterPlayer.StarterPlayerScripts.EmotePiecesClient** (1): EmotePiecesClient
- **StarterPlayer.StarterPlayerScripts.EmoteVFXClient** (1): EmoteVFXClient
- **StarterPlayer.StarterPlayerScripts.EventAudienceClient** (1): EventAudienceClient
- **StarterPlayer.StarterPlayerScripts.EventIntroClient** (1): EventIntroClient
- **StarterPlayer.StarterPlayerScripts.EventTopbarClient** (1): EventTopbarClient
- **StarterPlayer.StarterPlayerScripts.FFALivesClient** (1): FFALivesClient
- **StarterPlayer.StarterPlayerScripts.FallenKingBombClient** (1): FallenKingBombClient
- **StarterPlayer.StarterPlayerScripts.FallenKingBossClient** (1): FallenKingBossClient
- **StarterPlayer.StarterPlayerScripts.FallenKingClient** (1): FallenKingClient
- **StarterPlayer.StarterPlayerScripts.FallenKingHeartsClient** (1): FallenKingHeartsClient
- **StarterPlayer.StarterPlayerScripts.FallenKingReviveClient** (1): FallenKingReviveClient
- **StarterPlayer.StarterPlayerScripts.FallenKingSpoilsClient** (1): FallenKingSpoilsClient
- **StarterPlayer.StarterPlayerScripts.FallenKingStatueClient** (1): FallenKingStatueClient
- **StarterPlayer.StarterPlayerScripts.FallenKingSummonClient** (1): FallenKingSummonClient
- **StarterPlayer.StarterPlayerScripts.FootDustClient** (1): FootDustClient
- **StarterPlayer.StarterPlayerScripts.FootballEventClient** (1): FootballEventClient
- **StarterPlayer.StarterPlayerScripts.FootballEventWorld** (1): FootballEventWorld
- **StarterPlayer.StarterPlayerScripts.FootballShowClient** (1): FootballShowClient
- **StarterPlayer.StarterPlayerScripts.FrostQuakeClient** (1): FrostQuakeClient
- **StarterPlayer.StarterPlayerScripts.GAClient** (1): GAClient
- **StarterPlayer.StarterPlayerScripts.GearJuiceClient** (1): GearJuiceClient
- **StarterPlayer.StarterPlayerScripts.GemPickupClient** (1): GemPickupClient
- **StarterPlayer.StarterPlayerScripts.GhostTraderClient** (1): GhostTraderClient
- **StarterPlayer.StarterPlayerScripts.GiveawayClient** (1): GiveawayClient
- **StarterPlayer.StarterPlayerScripts.HalloweenStoreClient** (1): HalloweenStoreClient
- **StarterPlayer.StarterPlayerScripts.HauntClient** (1): HauntClient
- **StarterPlayer.StarterPlayerScripts.HitReplayClient** (1): HitReplayClient
- **StarterPlayer.StarterPlayerScripts.HostFlightClient** (1): HostFlightClient
- **StarterPlayer.StarterPlayerScripts.HoverShowClient** (1): HoverShowClient
- **StarterPlayer.StarterPlayerScripts.IceBreathClient** (1): IceBreathClient
- **StarterPlayer.StarterPlayerScripts.IceSkatesClient** (1): IceSkatesClient
- **StarterPlayer.StarterPlayerScripts.IdleReportClient** (1): IdleReportClient
- **StarterPlayer.StarterPlayerScripts.JoinEventPrompt** (1): JoinEventPrompt
- **StarterPlayer.StarterPlayerScripts.KillEffectTestClient** (1): KillEffectTestClient
- **StarterPlayer.StarterPlayerScripts.KnifeBonusClient** (1): KnifeBonusClient
- **StarterPlayer.StarterPlayerScripts.KnockdownStreakClient** (1): KnockdownStreakClient
- **StarterPlayer.StarterPlayerScripts.KusarigamaClient** (1): KusarigamaClient
- **StarterPlayer.StarterPlayerScripts.KusarigamaGrabLoopFix** (1): KusarigamaGrabLoopFix
- **StarterPlayer.StarterPlayerScripts.KusarigamaQuickTest** (1): KusarigamaQuickTest
- **StarterPlayer.StarterPlayerScripts.LastRunnerChatClient** (1): LastRunnerChatClient
- **StarterPlayer.StarterPlayerScripts.LateJoinClient** (1): LateJoinClient
- **StarterPlayer.StarterPlayerScripts.LeaderboardClient** (1): LeaderboardClient
- **StarterPlayer.StarterPlayerScripts.LegacyUIClient** (1): LegacyUIClient
- **StarterPlayer.StarterPlayerScripts.LevelRewardClient** (1): LevelRewardClient
- **StarterPlayer.StarterPlayerScripts.LifelineClient** (1): LifelineClient
- **StarterPlayer.StarterPlayerScripts.LightsOutClient** (1): LightsOutClient
- **StarterPlayer.StarterPlayerScripts.LobbyKnifeDisplays** (1): LobbyKnifeDisplays
- **StarterPlayer.StarterPlayerScripts.LobbyKnifeKeys** (1): LobbyKnifeKeys
- **StarterPlayer.StarterPlayerScripts.LocalLocomotionClient** (1): LocalLocomotionClient
- **StarterPlayer.StarterPlayerScripts.LockedCameraClient** (1): LockedCameraClient
- **StarterPlayer.StarterPlayerScripts.Map5AmbienceClient** (1): Map5AmbienceClient
- **StarterPlayer.StarterPlayerScripts.MapLightingClient** (1): MapLightingClient
- **StarterPlayer.StarterPlayerScripts.MeleeInputClient** (1): MeleeInputClient
- **StarterPlayer.StarterPlayerScripts.MenuScaleClient** (1): MenuScaleClient
- **StarterPlayer.StarterPlayerScripts.MergeDisplayClient** (1): MergeDisplayClient
- **StarterPlayer.StarterPlayerScripts.MergeMachineClient** (1): MergeMachineClient
- **StarterPlayer.StarterPlayerScripts.MythicKillClient** (1): MythicKillClient
- **StarterPlayer.StarterPlayerScripts.NoAbilitiesClient** (1): NoAbilitiesClient
- **StarterPlayer.StarterPlayerScripts.OutbreakClient** (1): OutbreakClient
- **StarterPlayer.StarterPlayerScripts.OverheadClient** (1): OverheadClient
- **StarterPlayer.StarterPlayerScripts.PirateShowClient** (1): PirateShowClient
- **StarterPlayer.StarterPlayerScripts.PiratesCallClient** (1): PiratesCallClient
- **StarterPlayer.StarterPlayerScripts.PracticeClient** (1): PracticeClient
- **StarterPlayer.StarterPlayerScripts.PreRoundDisableClient** (1): PreRoundDisableClient
- **StarterPlayer.StarterPlayerScripts.PricePrefetchClient** (1): PricePrefetchClient
- **StarterPlayer.StarterPlayerScripts.ProServerClient** (1): ProServerClient
- **StarterPlayer.StarterPlayerScripts.PumpkinBombClient** (1): PumpkinBombClient
- **StarterPlayer.StarterPlayerScripts.PumpkinPedestalClient** (1): PumpkinPedestalClient
- **StarterPlayer.StarterPlayerScripts.PumpkinPeopleClient** (1): PumpkinPeopleClient
- **StarterPlayer.StarterPlayerScripts.QuestTrackerClient** (1): QuestTrackerClient
- **StarterPlayer.StarterPlayerScripts.RainingTokensClient** (1): RainingTokensClient
- **StarterPlayer.StarterPlayerScripts.RankedClient** (1): RankedClient
- **StarterPlayer.StarterPlayerScripts.RankedLoadoutClient** (1): RankedLoadoutClient
- **StarterPlayer.StarterPlayerScripts.RankedMenuClient** (1): RankedMenuClient
- **StarterPlayer.StarterPlayerScripts.RankedPodiumClient** (1): RankedPodiumClient
- **StarterPlayer.StarterPlayerScripts.ReadableTextClient** (1): ReadableTextClient
- **StarterPlayer.StarterPlayerScripts.RescueClient** (1): RescueClient
- **StarterPlayer.StarterPlayerScripts.ReviveOfferClient** (1): ReviveOfferClient
- **StarterPlayer.StarterPlayerScripts.RoleMarkerVisibility** (1): RoleMarkerVisibility
- **StarterPlayer.StarterPlayerScripts.SacrificeBoardsClient** (1): SacrificeBoardsClient
- **StarterPlayer.StarterPlayerScripts.SafezoneSignsClient** (1): SafezoneSignsClient
- **StarterPlayer.StarterPlayerScripts.SeesawClient** (1): SeesawClient
- **StarterPlayer.StarterPlayerScripts.SettingsSyncClient** (1): SettingsSyncClient
- **StarterPlayer.StarterPlayerScripts.SkateSpinClient** (1): SkateSpinClient
- **StarterPlayer.StarterPlayerScripts.SlapstickClient** (1): SlapstickClient
- **StarterPlayer.StarterPlayerScripts.SnowFlurryClient** (1): SnowFlurryClient
- **StarterPlayer.StarterPlayerScripts.SoulReapClient** (1): SoulReapClient
- **StarterPlayer.StarterPlayerScripts.SpectateLoadoutClient** (1): SpectateLoadoutClient
- **StarterPlayer.StarterPlayerScripts.SpikeClient** (1): SpikeClient
- **StarterPlayer.StarterPlayerScripts.SpinWheelTopbarClient** (1): SpinWheelTopbarClient
- **StarterPlayer.StarterPlayerScripts.StudioAbilityTestClient** (1): StudioAbilityTestClient
- **StarterPlayer.StarterPlayerScripts.StudioEmotePreviewClient** (1): StudioEmotePreviewClient
- **StarterPlayer.StarterPlayerScripts.StudioKnifePreviewClient** (1): StudioKnifePreviewClient
- **StarterPlayer.StarterPlayerScripts.TackleDebugClient** (1): TackleDebugClient
- **StarterPlayer.StarterPlayerScripts.TackleInputClient** (1): TackleInputClient
- **StarterPlayer.StarterPlayerScripts.TestUIToggleClient** (1): TestUIToggleClient
- **StarterPlayer.StarterPlayerScripts.TimeWarpClient** (1): TimeWarpClient
- **StarterPlayer.StarterPlayerScripts.TopbarPlus** (21): Attribute, Caption, Classic, Container, Default, Dropdown, Gamepad, GoodSignal, Icon, Indicator, Janitor, Menu, Notice, Overflow, Reference, Selection, Themes, Types, Utility, VERSION, Widget
- **StarterPlayer.StarterPlayerScripts.TournamentResultsClient** (1): TournamentResultsClient
- **StarterPlayer.StarterPlayerScripts.TrollClient** (1): TrollClient
- **StarterPlayer.StarterPlayerScripts.TruckEffectsClient** (1): TruckEffectsClient
- **StarterPlayer.StarterPlayerScripts.TutorialClient** (1): TutorialClient
- **StarterPlayer.StarterPlayerScripts.UltimateEmoteButton** (1): UltimateEmoteButton
- **StarterPlayer.StarterPlayerScripts.VIPChatClient** (1): VIPChatClient
- **StarterPlayer.StarterPlayerScripts.ViewBeaconClient** (1): ViewBeaconClient
- **StarterPlayer.StarterPlayerScripts.VowbreakerEffectsClient** (1): VowbreakerEffectsClient
- **StarterPlayer.StarterPlayerScripts.WarHornClient** (1): WarHornClient
- **StarterPlayer.StarterPlayerScripts.WeaponVFXClient** (1): WeaponVFXClient
- **Workspace.4FACD_556.CharacterAnimationClient** (1): CharacterAnimationClient
- **Workspace.4FACD_556.CharacterMovementClient** (1): CharacterMovementClient
- **Workspace.4FACD_556.NoDeathClient** (1): NoDeathClient
- **Workspace.Calise_503.CharacterAnimationClient** (1): CharacterAnimationClient
- **Workspace.Calise_503.CharacterMovementClient** (1): CharacterMovementClient
- **Workspace.Calise_503.NoDeathClient** (1): NoDeathClient
- **Workspace.Foltyn672804.CharacterAnimationClient** (1): CharacterAnimationClient
- **Workspace.Foltyn672804.CharacterMovementClient** (1): CharacterMovementClient
- **Workspace.Foltyn672804.NoDeathClient** (1): NoDeathClient
- **Workspace.Hehedede4444.CharacterAnimationClient** (1): CharacterAnimationClient
- **Workspace.Hehedede4444.CharacterMovementClient** (1): CharacterMovementClient
- **Workspace.Hehedede4444.NoDeathClient** (1): NoDeathClient
- **Workspace.Noah801760.CharacterAnimationClient** (1): CharacterAnimationClient
- **Workspace.Noah801760.CharacterMovementClient** (1): CharacterMovementClient
- **Workspace.Noah801760.NoDeathClient** (1): NoDeathClient
- **Workspace.WhitneyHubbard39.CharacterAnimationClient** (1): CharacterAnimationClient
- **Workspace.WhitneyHubbard39.CharacterMovementClient** (1): CharacterMovementClient
- **Workspace.WhitneyHubbard39.NoDeathClient** (1): NoDeathClient
- **Workspace.bundaskenyer666.CharacterAnimationClient** (1): CharacterAnimationClient
- **Workspace.bundaskenyer666.CharacterMovementClient** (1): CharacterMovementClient
- **Workspace.bundaskenyer666.NoDeathClient** (1): NoDeathClient
- **Workspace.dvahs6.CharacterAnimationClient** (1): CharacterAnimationClient
- **Workspace.dvahs6.CharacterMovementClient** (1): CharacterMovementClient
- **Workspace.dvahs6.NoDeathClient** (1): NoDeathClient
- **Workspace.edo654l5.CharacterAnimationClient** (1): CharacterAnimationClient
- **Workspace.edo654l5.CharacterMovementClient** (1): CharacterMovementClient
- **Workspace.edo654l5.NoDeathClient** (1): NoDeathClient
- **Workspace.yrjrgdjsbfgdeje.CharacterAnimationClient** (1): CharacterAnimationClient
- **Workspace.yrjrgdjsbfgdeje.CharacterMovementClient** (1): CharacterMovementClient
- **Workspace.yrjrgdjsbfgdeje.NoDeathClient** (1): NoDeathClient
- **zachary080418.CharacterAnimationClient** (1): CharacterAnimationClient
- **zachary080418.CharacterMovementClient** (1): CharacterMovementClient
- **zachary080418.NoDeathClient** (1): NoDeathClient

## Appendix — per-script constant tables

Roblox-API/UI-property noise filtered out; up to 120 constants per script, dedup, original order. Scripts that duplicate between `Players.<you>.*` and `StarterPlayer`/`ReplicatedStorage` are listed once.

### `Players.WhitneyHubbard39.PlayerGui.BundleShowcase.ShowcaseClient` (LocalScript)

`Draw`, `Swing`, `Dive`, `Emote`, `stage`, `upper`, `SoulCall`, `Ability`, `SoulReap`, `SpringBox`, `STAB`, `springBox`, `Items`, `Animation`, `ability`, `FrostQuake`, `level`, `Level`, `Showcase`, `KillEffect`, `killEffect`, `movesFor`, `floor`, `reverse`, `comma`, `workspace`, `lobby`, `KnifeDisplays`, `interactables`, `BundleKey`, `ShopSlot`, `BonkerBundle`, `Versions`, `single`, `listed`, `Current`, `Key`, `standFor`, `ClientReady`, `InMatch`, `ScreenPresentationActive`, `CutsceneActive`, `permitted`, `Dual`, `Full`, `Short`, `labelItems`, `__index`, `applySingle`, `arrange`, `GuiButton`, `fromOffset`, `Timer`, `Swatch`, `fitTiles`, `TopbarInset`, `clamp`, `GetGuiInset`, `Height`, `Row`, `AbsoluteContentSize`, `layout`, `stopEmoteSounds`, `soundIds`, `ShowcaseEmoteSound`, `Ended`, `Debris`, `GetService`, `AddItem`, `emoteSound`, `versions`, `purchased`, `Blade`, `GetProductInfoAsync`, `productId`, `pending`, `fetchPrice`, `OWNED`, `primary`, `disabled`, `thanked`, `PriceInRobux`, `number`, `IsForSale`, `robux`, `buyText`, `panel`, `header`, `Header`, `decoration`, `Legendary`, `Mythical`, `Line`, `Gift`, `Note`, `muted`, `Tag`, `shimmer`, `secondary`, `candy`, `Limited`, `danger`, `fromRGB`, `close`, `dress`, `shown`, `Wearing`, `Try`, `WEARING`, `Buy`, `giftable`, `countdown`, `moves`, `lastMove`, `radius`, `tiles`, `bundle`, `abilityLive`, `paint`, `PreviewRotation`

### `Players.WhitneyHubbard39.PlayerGui.ChoiceSpotlight.ChoiceSpotlightClient` (LocalScript)

`number`, `resolve`, `UserId`, `actorById`, `Phase`, `InMatch`, `ScreenPresentationActive`, `SelectHero`, `HeroChoice`, `ChoiceReveal`, `canFocus`, `focusAt`, `setFocus`, `workspace`, `camera`, `CameraType`, `Scriptable`, `focus`, `Focus`, `subject`, `CameraSubject`, `ChoiceSpotlightActive`, `stopCamera`, `clearMarker`, `GroupTransparency`, `setBanner`, `CameraEnabled`, `RaycastParams`, `RaycastFilterType`, `Exclude`, `FilterType`, `RespectCanCollide`, `ClientBots`, `FilterDescendantsInstances`, `actor`, `actorId`, `started`, `params`, `deadline`, `clock`, `endsAt`, `DeadlineGrace`, `Audio`, `PresentationCues`, `ChoiceFocus`, `ApproachTime`, `Fire`, `startCamera`, `JSONDecode`, `ChoiceMoment`, `Chosen`, `Selected`, `EscapeStreak`, `choice`, `Hero`, `fromRGB`, `format`, `verified`, `userId`, `upper`, `Chicken`, `Description`, `version`, `Highlight`, `Adornee`, `FillTransparency`, `OutlineTransparency`, `HighlightDepthMode`, `Occluded`, `DepthMode`, `FillColor`, `OutlineColor`, `DecisionTemplate`, `ChoiceDecision`, `Head`, `resolvedAt`, `update`, `Angles`, `alive`, `Distance`, `Height`, `Normal`, `lookAt`, `clamp`, `AnswerHoldTime`, `ReturnTime`, `CoHChoiceSpotlight`, `UnbindFromRenderStep`, `GetService`, `ChickenOrHero`, `Game`, `Presentation`, `ParticipantDirectory`, `VerifiedName`, `ChoiceSpotlightConfig`, `FFlags`, `Bots`, `BotDirectory`, `Notifications`, `MainFrame`, `NotificationsF`, `ChoiceAnnouncement`, `Value`

### `Players.WhitneyHubbard39.PlayerGui.HUD.ActionBarController` (LocalScript)

`ReleaseCameraForUI`, `MovementLocked`, `TackleActive`, `PlatformStand`, `MenuIsOpen`, `available`, `GameRole`, `GetImageForKeyCode`, `ButtonL2`, `Space`, `control`, `workspace`, `TackleVariant`, `MaxSpeed`, `cooldown`, `elapsed`, `duration`, `variant`, `grounded`, `paused`, `TackleReadyAt`, `TackleStartedAt`, `TackleDuration`, `Duration`, `FloorMaterial`, `Air`, `reason`, `recovery`, `boosting`, `ready`, `speed`, `DashCooldownUntil`, `clock`, `BoostRecoveryUntil`, `MovementState`, `Boosting`, `DashReady`, `Colors`, `label`, `fromScale`, `CATCH`, `DASH`, `upper`, `update`, `GetService`, `ChickenOrHero`, `Presentation`, `HudStyle`, `DashMeterModel`, `CatchMeterModel`, `Game`, `TackleProfile`, `GameConfig`, `Tackle`, `Movement`, `MovementProfiles`, `BoostInput`, `ControlGate`, `MainFrame`, `BarMainFrame`, `BarBG`, `Bar`, `ControlPrompt`, `MeleeControl`

### `Players.WhitneyHubbard39.PlayerGui.MatchSummaryUI.MatchResultClient` (LocalScript)

`Interface`, `Features`, `MatchResultPanel`, `start`, `GetService`, `ChickenOrHero`, `IsLoaded`, `Loaded`, `HolderFrame`, `MatchResult`, `TouchScale`

### `Players.WhitneyHubbard39.PlayerGui.Misc.LobbyControlsClient` (LocalScript)

`TutorialRouting`, `TutorialSession`, `InMatch`, `Lobby`, `GameRole`, `canAFK`, `AFK`, `MusicMuted`, `setAvailable`, `Selectable`, `fromRGB`, `KeyboardAndMouse`, `SelectedObject`, `update`, `Fire`, `clock`, `SetAFK`, `FireServer`, `toggleAFK`, `toggleMusic`, `AFKResult`, `MenuIsOpen`, `LeftAlt`, `RightAlt`, `ReleaseCursorForControls`, `ChickenOrHero`, `Presentation`, `HudNavigation`, `GetService`, `Game`, `PlayerPreferences`, `MainFrame`, `LobbyControls`, `AFKF`, `AFKButton`, `MusicControls`, `MuteF`, `MuteIB`, `Feedback`, `KeyboardHint`, `register`, `OnClientEvent`, `WindowFocusReleased`

### `Players.WhitneyHubbard39.PlayerGui.Notifications.NotificationsController` (LocalScript)

`PracticeRole`, `PracticeRound`, `format`, `PRACTICE`, `Red`, `PracticeEndsAt`, `Caught`, `Chaser`, `floor`, `Gold`, `practiceBanner`, `workspace`, `Lobby`, `Phase`, `update`, `PracticeActive`, `RunNumber`, `Countdown`, `MapVote`, `RankedLoadout`, `Intermission`, `GameRole`, `AFK`, `InMatch`, `LOBBY`, `Safe`, `Mint`, `HeroChoice`, `HeroRun`, `EndsAt`, `NoticeUntil`, `Announcement`, `Results`, `LateJoinMode`, `AutoJoin`, `PlayButton`, `LateJoinQueued`, `snapshot`, `Prepare`, `eligible`, `matchId`, `QueuedAdminMode`, `CrossyRoad`, `DonkeyKong`, `FFACatchers`, `BladeBall`, `SelectedObject`, `IsDescendantOf`, `destroy`, `GetService`, `ChickenOrHero`, `Presentation`, `HudStyle`, `Colors`, `Game`, `GameAction`, `NotificationLayout`, `apply`, `MainFrame`, `NotificationsF`, `WhatsHappening`, `Location`, `Choices`, `ChoiceController`, `EscapeStreakController`, `CrossingBalanceNotice`, `LOADOUT`, `STARTING`, `SelectHero`, `SELECTION`, `ChoiceReveal`, `CHOICE`, `GroupRun`, `CROSSING`, `FinalRun`, `RunResolution`, `COMPLETE`, `RESULTS`

### `Players.WhitneyHubbard39.PlayerGui.OutcomeScreen.OutcomeScreenClient` (LocalScript)

`stopTweens`, `InMatch`, `GameRole`, `InitialLoadingComplete`, `ScreenPresentationActive`, `MatchSummaryVisible`, `allowed`, `FadeIn`, `HoldTime`, `FadeOut`, `Safe`, `SafeColor`, `CaughtColor`, `PeakTransparency`, `pulse`, `Caught`, `stateChanged`, `GetService`, `Edges`

### `Players.WhitneyHubbard39.PlayerGui.Single_Ad_HUD_Reward.ClientCode.AdClient` (ModuleScript)

`AdAvailabilityResult`, `NoFill`, `GetAdAvailabilityNowAsync`, `AdFormat`, `RewardedVideo`, `format`, `IsAvailable`, `pollAvailability`, `Poll`, `Remotes`, `ShowAd`, `FireServer`, `onAdCompletedCallbacks`, `remove`, `OnAdCompleted`, `onAdFailedCallbacks`, `OnAdFailed`, `completed`, `AdResult`, `OnClientEvent`, `Init`, `AdService`, `GetService`, `Audio`

### `Players.WhitneyHubbard39.PlayerGui.Single_Ad_HUD_Reward.ClientCode.Audio` (ModuleScript)

`volume`, `getSound`, `AdComplete`, `playAdCompleteSound`, `Click`, `playClickSound`, `GetService`

### `Players.WhitneyHubbard39.PlayerGui.Single_Ad_HUD_Reward.ClientCode.Boot` (Script)

`GetService`, `IsDescendantOf`, `SingleAdReward_Remotes`, `AdClient`, `Init`, `HUDController`, `start`

### `Players.WhitneyHubbard39.PlayerGui.Single_Ad_HUD_Reward.ClientCode.ButtonStates` (ModuleScript)

`textColor`, `WatchAd`, `backgroundColor`, `transparency`, `apply`, `fromRGB`, `Unavailable`, `Loading`, `Claimed`, `Cooldown`, `FILL_COLOR`

### `Players.WhitneyHubbard39.PlayerGui.Single_Ad_HUD_Reward.ClientCode.HUDController` (ModuleScript)

`GetProductInfo`, `description`, `Reward`, `Description`, `IconImageAssetId`, `fetchProductInfo`, `clock`, `floor`, `format`, `formatTimer`, `updateProductDisplay`, `cooldownEndsAt`, `cooldownThread`, `IsAvailable`, `claimable`, `apply`, `WatchAd`, `Unavailable`, `cancel`, `startCooldownTimer`, `Cooldown`, `enterCooldown`, `tryBecomeAvailable`, `opening`, `AdRewards`, `LogTelemetry`, `RegisterOpportunity`, `FireServer`, `openPanel`, `closePanel`, `NoticeLabel`, `fromRGB`, `SingleAdRewardEnabled`, `enabled`, `InMatch`, `Lobby`, `GameRole`, `inLobby`, `setEnabled`, `notify`, `refreshIcon`, `checkWhenCooledDown`, `pending`, `Boot`, `GetPlacementInfo`, `InvokeServer`, `eligible`, `Poll`, `secondsLeft`, `number`, `claimsMax`, `claimsUsed`, `windowResetsAt`, `connected`, `retried`, `Claimed`, `Audio`, `playClickSound`, `ShowAd`, `playAdCompleteSound`, `reason`, `RewardAssigned`, `assignedProductId`, `ClaimLimitReached`, `result`, `ShowAdResult`, `ShowInterrupted`, `Fire`, `lobbyChanged`, `devProductId`, `Loading`, `checkEligibility`, `RewardsContainer`, `ContentStack`, `Actions`, `PrimaryButton`, `TitleBody`, `Media`, `ProductImage`, `CloseAffordance`, `HUDButton`, `ButtonStates`, `PlayerScripts`, `TopbarPlus`, `ChickenOrHero`, `Presentation`, `HudNavigation`, `ValleyAdRewards`, `setName`, `align`, `setOrder`, `setImage`, `oneClick`, `BindableEvent`, `noticeChanged`, `OnAdCompleted`, `OnAdFailed`, `selected`, `start`, `GetService`

### `Players.WhitneyHubbard39.PlayerGui.Single_Ad_HUD_Reward.ClientCode.HUDStack` (ModuleScript)

`placementOf`, `Button`, `ScreenInsets`, `TopbarSafeInsets`, `isDefault`, `AdPlacementHUDButton`, `GetTagged`, `getDefaultStack`, `fromOffset`, `updateSlot`, `GetInstanceAddedSignal`, `GetInstanceRemovedSignal`, `place`, `CollectionService`, `GetService`, `fromScale`

### `Players.WhitneyHubbard39.PlayerGui.Single_Ad_HUD_Reward.ClientCode.ThemeColors` (ModuleScript)

`applyText`, `Keypoints`, `Value`, `ToHSV`, `ColorSequenceKeypoint`, `Time`, `applyGradient`, `IsDescendantOf`, `ThemeColor`, `AdThemeTextColor`, `HasTag`, `AdThemeGradientColor`, `apply`, `GetTagged`, `applyAll`, `GetInstanceAddedSignal`, `attach`, `CollectionService`, `GetService`, `__mode`

### `Players.WhitneyHubbard39.PlayerGui.SpinWheel.Main.AdFrame.AdController` (LocalScript)

`GetFullName`, `waitFor`, `WheelSpinAdEnabled`, `switchedOn`, `GetAdAvailabilityNowAsync`, `AdFormat`, `RewardedVideo`, `AdAvailabilityResult`, `IsAvailable`, `isAdAvailable`, `workspace`, `RegisterOpportunity`, `FireServer`, `refresh`, `checkAvailability`, `SpinWheelOpen`, `Boot`, `onOpenChanged`, `clock`, `WatchAd`, `watch`, `nextFreeAt`, `number`, `AdResult`, `NextFreeSpinPos`, `HomePosition`, `placeNextFree`, `switchChanged`, `AdService`, `GetService`, `TimeSkip`, `SpinReady`, `NextFreeSpin`, `ChickenOrHero`, `SpinWheelEvent`, `SpinWheelAds`, `SpinWheelAdEvent`, `LogTelemetry`, `OnClientEvent`

### `Players.WhitneyHubbard39.PlayerGui.SpinWheel.SpinWheelClient` (LocalScript)

`Locked`, `multiButton`, `HomePosition`, `nextFreeHomeNow`, `clock`, `fromScale`, `bounceNextFree`, `AddItem`, `playTick`, `showMessage`, `rewardSound`, `Quart`, `tween`, `SetCore`, `SendNotification`, `Duration`, `notifyReward`, `ChickenOrHero`, `Weapons`, `model`, `Blade`, `Preview`, `fromRGB`, `ThumbAxis`, `ThumbNormal`, `fromMatrix`, `PreviewRotation`, `Angles`, `VectorToWorldSpace`, `lookAt`, `showKnife`, `PrizeImage`, `ImageTransparency`, `sliceArt`, `Spinner`, `lobbyArt`, `Prize`, `GroupTransparency`, `GhostKey`, `CanvasGroup`, `WheelCelebration`, `RewardRing`, `RewardRay`, `RewardConfetti`, `random`, `JackpotCard`, `fromOffset`, `PrizeArt`, `PrizeTitle`, `copies`, `number`, `JackpotTitle`, `celebrate`, `color`, `rarityColor`, `prizeArt`, `percent`, `Item`, `Fallback`, `ItemName`, `Percent`, `format`, `buildOdds`, `workspace`, `serverNow`, `floor`, `durationText`, `SpinAmount`, `credits`, `nextFreeAt`, `count`, `Price`, `discountAvailable`, `FlavorText`, `Discount`, `purchasesAvailable`, `updateLabels`, `TouchGui`, `RewardPop`, `hideGui`, `InMatch`, `SpinWheelOpen`, `track`, `panel_open`, `SpinWheel`, `FireServer`, `openWheel`, `panel_close`, `closeWheel`, `angle`, `message`, `Quint`, `position`, `scale`, `frame`, `spinner`, `ringStroke`, `chipStroke`, `chipPop`, `MultiScale`, `MultiRing`, `MultiChip`, `Pop`, `wheelParts`, `Wheel`, `MultiWheel`, `stageWheels`, `setStageControls`, `tweens`, `stageTween`, `ticker`, `holder`, `resetStage`, `withCommas`, `gearPrize`, `Game`, `GhostTraderConfig`, `KeyIcon`, `keyIcon`, `keysOf`

### `Players.WhitneyHubbard39.PlayerGui.ThreatIndicator.ThreatIndicatorClient` (LocalScript)

`Phase`, `PracticeActive`, `InMatch`, `GameRole`, `MovementLocked`, `ChoiceSpotlightActive`, `ScreenPresentationActive`, `HeroRun`, `GroupRun`, `FinalRun`, `eligible`, `CatcherThreatIntensity`, `CatcherThreatUpdatedAt`, `workspace`, `publishThreat`, `strength`, `RaycastParams`, `RaycastFilterType`, `Exclude`, `FilterType`, `FilterDescendantsInstances`, `RespectCanCollide`, `UserId`, `sample`, `MaxThreats`, `remove`, `sector`, `Angle`, `ArcWidth`, `UpdateInterval`, `FadeInTime`, `FadeOutTime`, `MaxOpacity`, `GetService`, `ChickenOrHero`, `Presentation`, `ThreatIndicatorConfig`, `ThreatIndicatorModel`, `ParticipantDirectory`, `Game`, `Ring`

### `Players.WhitneyHubbard39.PlayerScripts.AbilityBuffVisuals` (LocalScript)

`workspace`, `Cloak`, `level`, `HarderToSpot`, `clamp`, `cloakAlpha`, `shield`, `shieldAlpha`, `shieldFlair`, `dropShield`, `JointInstance`, `Constraint`, `PartType`, `Ball`, `Shape`, `ForceField`, `OneHitShieldBubble`, `CastShadow`, `dress`, `OneHitShield`, `showShield`, `isEffect`, `watches`, `effects`, `showEffect`, `Clear`, `hideEffect`, `added`, `DescendantRemoving`, `removing`, `conceal`, `reveal`, `unlitAt`, `hidden`, `release`, `restore`, `LocalTransparencyModifier`, `DisplayDistanceType`, `Highlight`, `Light`, `Fire`, `Smoke`, `Sparkles`, `HumanoidDisplayDistanceType`, `clock`, `unlight`, `blade`, `light`, `flair`, `resetBlade`, `watch`, `playerAdded`, `GetService`, `ChickenOrHero`, `Presentation`, `PracticeWorlds`, `apart`, `scaled`, `Cloaked`, `HitShielded`, `Ghosted`, `BigDaggerActive`, `EquippedDagger`, `Blade`, `Handle`, `BladeWeld`, `chained`, `BigDaggerGlow`, `Adornee`, `HighlightDepthMode`, `Occluded`, `DepthMode`, `fromRGB`, `FillColor`, `OutlineColor`, `FillTransparency`, `OutlineTransparency`, `PointLight`, `BigDaggerLight`, `Brightness`, `Range`, `Shadows`, `BigDagger`, `amount`, `color`, `AbilityBuffVisuals`, `UnbindFromRenderStep`, `Gear`, `Assets`, `Weapons`, `KnifeChains`, `LocalLooks`, `PumpkinSmoke`, `AbilityLevels`, `AbilityFlair`, `LocalShieldBubbles`, `Last`, `Value`

### `Players.WhitneyHubbard39.PlayerScripts.AbilityUseClient` (LocalScript)

`MoveDirection`, `workspace`, `dashDirection`, `ColorSequenceKeypoint`, `cardColors`, `InMatch`, `PracticeActive`, `playing`, `equippedForRole`, `GameRole`, `Kind`, `Ability`, `abilities`, `loaded`, `UseRole`, `reason`, `Game`, `GlobalPaused`, `MapChanging`, `blocked`, `AfterburnerAt`, `RocketShoes`, `afterburnerReady`, `clock`, `AbilityReadyAt`, `request`, `UseAbility`, `ClearAllChildren`, `IconImage`, `IconRectOffset`, `ImageRectOffset`, `IconRectSize`, `ImageRectSize`, `Gear`, `Assets`, `Preview`, `lookAt`, `preview`, `GetService`, `FFlags`, `AbilityUpgrades`, `available`, `Abilities`, `AbilityUpgradeMenu`, `activate`, `openAbilities`, `ButtonR1`, `forActor`, `ClientReady`, `upper`, `Gold`, `Charges`, `ABILITY`, `Item`, `AbilityIcon`, `Outline`, `Gradient`, `AbilityCharges`, `StartCharges`, `TAP`, `AbilityChargeAt`, `CHASERS`, `RUNNERS`, `EmptyCooldown`, `format`, `Caught`, `CAUGHT`, `ChargeSeconds`, `fromOffset`, `AbilityCooldown`, `Cooldown`, `fromScale`, `clamp`, `ImageTransparency`, `update`, `ChickenOrHero`, `AbilityRule`, `OldUIReskin`, `Skin`, `Presentation`, `EquipmentHudLayoutLegacy`, `Movement`, `ControlGate`, `GearCatalog`, `AbilityLevels`, `GearEvent`, `GearPredictionClient`, `HudNavigation`, `screen`, `AbilityControls`, `Use`, `stroke`, `surface`, `Corner`, `SkinStroke`, `register`, `fromRGB`, `track`, `corner`, `MouseEnter`, `MouseLeave`, `Weapons`, `ArmoryEvent`, `OnClientEvent`, `ChaserEquipped`, `Selectable`, `NextCharge`, `textBody`, `Get`, `FireServer`

### `Players.WhitneyHubbard39.PlayerScripts.AdrenalineFeelClient` (LocalScript)

`AdrenalineFeel`, `GameRole`, `GearBoost`, `clock`, `refresh`, `Adrenaline`, `ownerId`, `UserId`, `GetService`, `ChickenOrHero`, `Gear`, `GearPredictionClient`, `fromRGB`, `fromScale`, `Edge`, `Interactable`, `NumberSequenceKeypoint`

### `Players.WhitneyHubbard39.PlayerScripts.AlbieClient` (LocalScript)

`GameAudio`, `gameSound`, `assetSound`, `AlbieTotal`, `number`, `AlbieChapter`, `heardAll`, `AlbieTalk`, `AlbieNextAt`, `workspace`, `Talk`, `format`, `AlbieNextGems`, `ActionText`, `promptText`, `GetService`, `lower`, `grave`, `PVInstance`, `BaseScript`, `RaycastParams`, `RaycastFilterType`, `Exclude`, `FilterType`, `FilterDescendantsInstances`, `AlbieTombstone`, `tombstone`, `AlbieGoneDay`, `daysGone`, `Gone`, `Memory`, `Vanished`, `Ghost`, `LocalTransparencyModifier`, `Shown`, `AlbieWind`, `fromRGB`, `NumberSequenceKeypoint`, `Lifetime`, `Rate`, `Speed`, `SpreadAngle`, `RotSpeed`, `Acceleration`, `LightEmission`, `presence`, `settle`, `AlbieNPC`, `Animator`, `Animation`, `AnimationId`, `LoadAnimation`, `AnimationPriority`, `Action`, `Priority`, `Torso`, `Neck`, `adopt`, `eyesOn`, `Head`, `clock`, `switchAt`, `random`, `Player`, `Part0`, `PointToObjectSpace`, `atan2`, `clamp`, `pitch`, `Angles`, `tween`, `Button`, `label`, `smooth`, `uiSound`, `CreatorCaptureExempt`, `Advance`, `Selectable`, `fromScale`, `advance`, `Leave`, `LEAVE`, `leave`, `UITextSizeConstraint`, `Next`, `Chapter`, `chapter`, `title`, `Say`, `MaxSize`, `UISizeConstraint`, `FillDirection`, `HorizontalAlignment`, `VerticalAlignment`, `Padding`, `Vertical`, `Speaker`, `speaker`, `Body`, `Stories`, `MinSize`, `menuTitle`, `Sub`, `menuSub`, `Days`, `ScrollBarThickness`, `ScrollBarImageColor3`, `AutomaticCanvasSize`, `ScrollingDirection`, `Done`, `menuLeave`, `Toast`, `Hover`, `sting`, `Click`, `click`, `buildGui`, `floor`, `leftover`, `Adornee`

### `Players.WhitneyHubbard39.PlayerScripts.AlleyOopClient` (LocalScript)

`number`, `GetPlayerByUserId`, `bodyOf`, `RollOffMinDistance`, `RollOffMaxDistance`, `Ended`, `sound`, `PartType`, `Ball`, `Shape`, `Neon`, `CastShadow`, `PointLight`, `Range`, `Brightness`, `LightEmission`, `NumberSequenceKeypoint`, `Lifetime`, `Speed`, `SpreadAngle`, `Rate`, `Emit`, `flash`, `ScaleTo`, `scaleModel`, `clock`, `clamp`, `lookAt`, `AlleyOopHoop`, `popHoop`, `workspace`, `FootballFieldLocal`, `CourtHoop`, `courtHoopAt`, `dropHoop`, `handOf`, `EquippedDagger`, `RootBall`, `Handle`, `LocalTransparencyModifier`, `carriedBall`, `hideLocally`, `giveBack`, `slowAt`, `slowRate`, `Sounds`, `Toss`, `Board`, `Catch`, `Angles`, `RightHand`, `AlleyOopBall`, `direction`, `IsDescendantOf`, `release`, `throw`, `catch`, `ClearAllChildren`, `dunkBall`, `Net`, `swish`, `IsPlaying`, `AdjustSpeed`, `Ragdolled`, `VectorVelocity`, `VelocityConstraintMode`, `Plane`, `PrimaryTangentAxis`, `SecondaryTangentAxis`, `PlaneVelocity`, `AssemblyMass`, `MaxForce`, `FloorMaterial`, `Air`, `LeapSeconds`, `HangSeconds`, `FallSpeed`, `velocity`, `Vector`, `Animator`, `Animation`, `AnimationId`, `LoadAnimation`, `Stop`, `AnimationPriority`, `Action4`, `Priority`, `after`, `courtHoop`, `Rim`, `Pop`, `Swish`, `Rattle`, `Ooh`, `AlleyOopShare`, `actorId`, `character`, `AlleyOop`, `UserId`, `Whoosh`, `isLocal`, `linger`, `HoopSeconds`, `animation`, `audio`, `ContentProvider`, `GetService`, `PreloadAsync`, `Weapons`, `Basketball`, `TricksAnim`, `DunkAnim`, `CrossLeftAnim`, `CrossRightAnim`, `RunAnim`, `Presentation`, `FootballShots`, `Hoops`, `DribbleSounds`, `preload`

### `Players.WhitneyHubbard39.PlayerScripts.AnimateVioletRift` (LocalScript)

`InMatch`, `Spectating`, `refreshAway`, `clock`, `Collecting`, `MergePhase`, `workspace`, `PhaseStarted`, `Charging`, `clamp`, `Collapse`, `Reveal`, `initial`, `Angles`, `orbit`, `phase`, `GetService`, `ChickenOrHero`, `Game`, `MapLocator`, `interactables`, `MergeMachine`, `GetFullName`, `Base_Obsidian`, `format`, `match`, `Neon`, `fromRGB`

### `Players.WhitneyHubbard39.PlayerScripts.ArmoryClient` (LocalScript)

`upgradeMenu`, `ClientReady`, `TutorialRouting`, `ScreenPresentationActive`, `AdminRefreshActive`, `canOpen`, `setAvailable`, `Shop`, `Inventory`, `Abilities`, `Items`, `available`, `LikeReward`, `PanelShade`, `likeRewardShown`, `setWallet`, `loaded`, `coins`, `message`, `build`, `after`, `built`, `whenBuilt`, `activate`, `ArmoryNavigation`, `Fire`, `Emotes`, `Featured`, `Earnable`, `VIP`, `ButtonY`, `Get`, `FireServer`, `clock`, `ThumbAxis`, `ThumbNormal`, `fromMatrix`, `lookAt`, `thumbPose`, `Rarity`, `upper`, `Default`, `STANDARD`, `EXCLUSIVE`, `rarityOf`, `textStroke`, `headerLabel`, `Blade`, `JointInstance`, `Light`, `cross`, `thumbnail`, `cardLabel`, `surface`, `radius`, `Legendary`, `Mythical`, `Thumb`, `fromRGB`, `KnifeName`, `Equipped`, `EQUIPPED`, `green`, `fromOffset`, `corner`, `outline`, `Copies`, `Pick`, `fromScale`, `frame`, `badge`, `copies`, `viewport`, `rarity`, `color`, `legendary`, `tierColor`, `makeCard`, `owned`, `Crate`, `HalloweenCrate`, `groupOf`, `equipped`, `clone`, `danger`, `selected`, `knifeStacks`, `number`, `renderCollection`, `Hero`, `Details`, `Sounds`, `Selection`, `setOpen`, `applyViewStyle`, `permitted`, `floor`, `reverse`, `comma`, `GetGuiInset`, `TopRule`, `Wallet`, `Tabs`, `ActiveLine`, `HeaderRule`, `Field`, `CentreLine`, `CentreCircle`, `PreviewHint`, `Collection`, `Description`, `Action`, `Equip`, `Swing`, `Hit`, `CellSize`, `Storefront`, `layout`, `Weapon`, `ClearAllChildren`

### `Players.WhitneyHubbard39.PlayerScripts.AudioClient` (LocalScript)

`preview`, `alive`, `ChoiceSpotlightActive`, `ChoiceFocusResolve`, `KnifePreview`, `ArmoryOpen`, `ArmoryClose`, `PanelOpen`, `PanelClose`, `ChoiceFocus`, `number`, `clamp`, `GemCollect`, `RecapStop`, `voices`, `remove`, `MatchSummaryVisible`, `DaggerHit`, `CatchImpact`, `GetPlayerByUserId`, `workspace`, `RemoteActionDistance`, `Lobby`, `Phase`, `GameRole`, `PracticeActive`, `Countdown`, `AFK`, `ClientReady`, `PhaseCues`, `RoleRunner`, `RoleCatcher`, `SelectedUserId`, `UserId`, `SelectedHero`, `NoticeUntil`, `NoticeSound`, `GlobalPaused`, `EndsAt`, `CountdownPhases`, `CrossingPhases`, `TimeWarning`, `CountdownFinal`, `template`, `CountdownTick`, `updateState`, `PracticeRound`, `RunStart`, `PracticeResult`, `RunEnd`, `PracticeEndsAt`, `practiceCues`, `UpdateInterval`, `update`, `close`, `destroy`, `GetService`, `ChickenOrHero`, `FFlags`, `ClientBots`, `Bots`, `BotDirectory`, `Audio`, `GameAudio`, `DefaultCharacterAudio`, `start`, `AudioConfig`, `AudioCatalog`, `AudioPlayback`, `DaggerAudio`, `MovementAudio`, `InterfaceAudio`, `Game`, `ThreatAudio`, `Danger`, `RecapOpen`, `RecapTick`, `RecapComplete`, `RecapLevelUp`, `Interface`, `KnifeClipPreview`, `PresentationCues`, `Caught`, `ReachedSafety`, `CatchSuccess`, `Victory`, `Defeat`, `SpawnRefresh`, `LobbyReturn`, `HeroChosen`, `ChickenChosen`, `Events`, `OnClientEvent`

### `Players.WhitneyHubbard39.PlayerScripts.AuthoredScreensSweepClient` (LocalScript)

`UITemplate`, `GetService`

### `Players.WhitneyHubbard39.PlayerScripts.AwardNoticeClient` (LocalScript)

`ClientReady`, `ready`, `layout`, `tween`, `AccessRemoved`, `Gift`, `Purple`, `Blue`, `Gold`, `senderId`, `number`, `format`, `Rank`, `label`, `detail`, `GroupTransparency`, `fromScale`, `Weapons`, `ArmoryEvent`, `CheckRewards`, `FireServer`, `AwardAck`, `present`, `round`, `AutoLocalize`, `UITextSizeConstraint`, `words`, `GameAudio`, `GetService`, `LazySound`, `playLocal`, `gmatch`, `Knife`, `Bundle`, `Perk`, `fromRGB`, `knife`, `Pack`, `currency`, `coins`, `COIN_IMAGE`, `GEM_IMAGE`, `Emote`, `EMOTE_IMAGE`, `DoubleXP`, `reveal`, `fromOffset`, `Body`, `Lid`, `giftBox`, `random`, `confetti`, `destroy`, `ValleyGiftReveal`, `ZIndexBehavior`, `Sibling`, `ImageColor3`, `ImageTransparency`, `PanelOpen`, `Purchase`, `chime`, `presentGift`, `Awards`, `AwardReady`, `remove`, `ChickenOrHero`, `Admin`, `AdminEvent`, `Presentation`, `ValleyPanels`, `ValleyTheme`, `AuthoredScreens`, `whole`, `ValleyAwards`, `ScreenInsets`, `Edge`, `CanvasGroup`, `Card`, `corner`, `stroke`, `Outline`, `Rule`, `Mark`, `Box`, `Ribbon`, `Bow`, `Diamond`, `Avatar`, `Eyebrow`, `Limits`, `MinTextSize`, `Detail`, `GlobalWheelOpen`, `ScreenPresentationActive`, `AdminRefreshActive`, `MatchSummaryVisible`, `BalloonOfferOpen`, `FairPlayNoticeOpen`, `ChoiceSpotlightActive`, `Heavy`, `ExtraBold`, `OnClientEvent`

### `Players.WhitneyHubbard39.PlayerScripts.BalloonOfferClient` (LocalScript)

`authored`, `fromScale`, `textStroke`, `label`, `TutorialActive`, `StarterPackOpen`, `TutorialFinishing`, `CreatorPanelOpen`, `CreatorUIHidden`, `CreatorCameraActive`, `MapVoteOpen`, `CursorHintPending`, `CursorHintOpen`, `EmoteWheelOpen`, `AnnouncementComposerOpen`, `JourneyOpen`, `SettingsOpen`, `UpdateLogOpen`, `ClientReady`, `InMatch`, `ScreenPresentationActive`, `AdminRefreshActive`, `TutorialRouting`, `AdminConsoleActive`, `ServerBrowserOpen`, `MatchSummaryVisible`, `permitted`, `owned`, `BalloonDagger`, `unlocked`, `textSecondary`, `loaded`, `equipped`, `primary`, `secondary`, `radius`, `green`, `update`, `SelectedObject`, `IsDescendantOf`, `BalloonOfferOpen`, `Get`, `FireServer`, `GamepadEnabled`, `Balloon`, `CanSendGameInviteAsync`, `PromptGameInvite`, `clock`, `Equip`, `CheckRewards`, `ButtonB`, `lookAt`, `starterPurchased`, `starterPresented`, `GameId`, `UniverseId`, `starterFirstMatch`, `starterOfferEndsAt`, `workspace`, `starterDone`, `balloonPrompts`, `ArmoryOpen`, `BalloonShown`, `GetService`, `SocialService`, `ChickenOrHero`, `Weapons`, `ArmoryEvent`, `Gear`, `StarterPackEvent`, `StarterPackConfig`, `ArmoryNavigation`, `OldUIReskin`, `Skin`, `Presentation`, `AuthoredScreens`, `clone`, `BalloonOffer`, `ZIndexBehavior`, `Sibling`, `Card`, `fromOffset`, `fromRGB`, `emoteOffer`, `Eyebrow`, `Modal`, `close`, `Description`, `Dagger`, `Blade`, `JointInstance`, `PreviewRotation`, `identity`, `KnifeIcons`, `Progress`, `Invite`, `Claim`, `robux`, `Note`, `textBody`, `OnClientEvent`

### `Players.WhitneyHubbard39.PlayerScripts.BladeBallClient` (LocalScript)

`workspace`, `rootOf`, `BladeHearts`, `number`, `inGame`, `Sounds`, `random`, `WorldPosition`, `Terrain`, `RollOffMinDistance`, `RollOffMaxDistance`, `AddItem`, `sound`, `PartType`, `Ball`, `Shape`, `Neon`, `CastShadow`, `folder`, `burst`, `clock`, `shake`, `Angles`, `Massless`, `BladeBallView`, `Radius`, `SmoothPlastic`, `fromRGB`, `Band`, `Cylinder`, `Part0`, `Part1`, `Carrier`, `Attachment0`, `Attachment1`, `Lifetime`, `LightEmission`, `FaceCamera`, `WidthScale`, `Range`, `Brightness`, `Shadows`, `PointLight`, `Rate`, `Speed`, `SpreadAngle`, `Aim`, `AlwaysOnTop`, `LightInfluence`, `fromOffset`, `fromScale`, `FillColor`, `FillTransparency`, `OutlineColor`, `OutlineTransparency`, `DepthMode`, `HighlightDepthMode`, `Highlight`, `BladeBallHud`, `Hearts`, `bands`, `carrier`, `trail`, `light`, `sparks`, `aimGui`, `hearts`, `edges`, `buildView`, `Head`, `StudsOffset`, `MaxDistance`, `labels`, `shown`, `Adornee`, `heartTag`, `BladeBallArena`, `Box`, `ServeHeight`, `readArena`, `Return`, `Live`, `GetPlayerByUserId`, `AimHeight`, `aimFor`, `shownPos`, `speed`, `Serve`, `clamp`, `apply`, `pickAim`, `MaxSpeed`, `SpeedPerBlock`, `launch`, `CurveSeconds`, `UserId`, `BlockCooldown`, `Block`, `showBlock`, `flatLook`, `FireServer`, `Slash`, `blockRange`, `untilT`, `Window`, `MissCooldown`, `press`, `UseJumpPower`, `HumanoidStateType`, `Jumping`, `GetStateEnabled`, `SetStateEnabled`, `setJump`, `fromAxisAngle`, `StartSpeed`, `BlueSpeed`, `format`, `floor`, `frame`, `HUD`

### `Players.WhitneyHubbard39.PlayerScripts.BloodMoonClient` (LocalScript)

`BloodMoon`, `BloodMoonHidden`, `format`, `clock`, `textStroke`, `label`, `GroupTransparency`, `showBanner`, `workspace`, `InMatch`, `BloodMoonEndsAt`, `number`, `refreshLine`, `CanvasGroup`, `clamp`, `fromOffset`, `place`, `MainFrame`, `NotificationsF`, `EscapeStreak`, `anchorTo`, `Notifications`, `Howl`, `AddItem`, `CandyMultiplier`, `changed`, `WorldPosition`, `Terrain`, `LightEmission`, `NumberSequenceKeypoint`, `Lifetime`, `Speed`, `SpreadAngle`, `Drag`, `Rate`, `Emit`, `burst`, `Highlight`, `BloodMoonFlash`, `FillColor`, `OutlineColor`, `FillTransparency`, `OutlineTransparency`, `HighlightDepthMode`, `Occluded`, `DepthMode`, `flash`, `Ragdolled`, `Torso`, `watch`, `added`, `GetService`, `Debris`, `ChickenOrHero`, `Game`, `BloodMoonConfig`, `Bots`, `ClientBotKnockdown`, `OldUIReskin`, `Skin`, `fromRGB`, `Quint`, `BloodMoonNotice`, `ScreenInsets`, `DeviceSafeInsets`, `Holder`, `Banner`, `Plate`, `fromScale`, `surface`, `radius`, `Sub`, `BloodMoonTimer`, `Timer`, `PaddingLeft`, `PaddingRight`, `Countdown`, `__mode`, `onDown`

### `Players.WhitneyHubbard39.PlayerScripts.BodyFacingClient` (LocalScript)

`animatorFor`, `Animator`, `locomotionAnimator`, `joints`, `motor`, `applied`, `Transform`, `restore`, `number`, `UserId`, `remove`, `character`, `workspace`, `IsDescendantOf`, `humanoid`, `Torso`, `RigType`, `HumanoidRigType`, `RootJoint`, `Neck`, `version`, `MovementReset`, `torso`, `right`, `record`, `overlay`, `enabled`, `IsBot`, `GameRole`, `ClientBot`, `PlatformStand`, `MovementLocked`, `TackleActive`, `ReleaseCameraForUI`, `MenuIsOpen`, `lastTravel`, `gazePitch`, `velocityFor`, `clamp`, `ReachPhase`, `Windup`, `BotPursuitTarget`, `Head`, `atan2`, `BodyFollowRate`, `AnimationPackActive`, `GetPlayingAnimationTracks`, `Animation`, `AnimationId`, `WeightCurrent`, `AnimationAction`, `Stop`, `CoH_Stop`, `MovementThreshold`, `poseScale`, `angle`, `KnifeRunDirs`, `DashVisualFacing`, `pitch`, `Angles`, `VectorToObjectSpace`, `fromAxisAngle`, `FacingTravelAngle`, `FacingGait`, `FacingTorsoYaw`, `GetService`, `ChickenOrHero`, `Presentation`, `ParticipantDirectory`, `Movement`, `BodyFacingConfig`, `BodyFacingModel`, `AnimationPolicy`, `AnimationLibrary`, `prepare`, `animation`, `Idle`, `Walk`, `Run`, `DashAnimationPolicy`, `LocalLocomotion`, `isName`, `PreAnimation`, `PreSimulation`

### `Players.WhitneyHubbard39.PlayerScripts.BonkSplatClient` (LocalScript)

`DaggerHit`, `position`, `HitEffect`, `Splat`, `runner`, `number`, `GetPlayerByUserId`, `Head`, `GetService`, `ChickenOrHero`, `Weapons`, `SkinCatalog`, `Presentation`, `BonkSplat`, `FFlags`, `ClientBots`, `Bots`, `BotDirectory`, `Audio`, `Events`, `OnClientEvent`

### `Players.WhitneyHubbard39.PlayerScripts.BoostInputClient` (LocalScript)

`AdminMatchMode`, `BladeBall`, `bladeBall`, `fighting`, `GameRole`, `bossFighter`, `turning`, `available`, `request`, `TackleActive`, `remaining`, `bossPress`, `UserInputState`, `ContextActionResult`, `Sink`, `ButtonA`, `Pass`, `DashCooldownUntil`, `clock`, `update`, `DASH`, `CoHBoost`, `UnbindAction`, `GetService`, `ChickenOrHero`, `Presentation`, `TouchActionButton`, `Movement`, `BoostInput`, `HUD`, `BoostButton`, `Game`, `LeftShift`, `RightShift`, `ButtonL1`, `BossCombat`, `TacklePrediction`, `Space`, `ButtonR2`, `BindAction`

### `Players.WhitneyHubbard39.PlayerScripts.BoostVFXClient` (LocalScript)

`objects`, `remove`, `lines`, `untilTime`, `lastStamp`, `localBoost`, `BoostEffectAt`, `BoostWindTop`, `BoostWindBottom`, `Attachment0`, `Attachment1`, `TrailLifetime`, `Lifetime`, `trail`, `distance`, `workspace`, `MaxDistance`, `MaxCharacters`, `MovementState`, `Boosting`, `Dashing`, `Dash`, `Duration`, `number`, `FadeTail`, `TackleStartedAt`, `TackleDuration`, `TackleActive`, `clamp`, `MovementLocked`, `WorldPosition`, `GetService`, `ChickenOrHero`, `Presentation`, `ParticipantDirectory`, `BoostVFXConfig`, `Movement`, `MovementConfig`, `WindTrail`

### `Players.WhitneyHubbard39.PlayerScripts.BotRenderClient` (LocalScript)

`GetService`, `FFlags`, `ClientBots`, `ChickenOrHero`, `Bots`, `ClientBotRenderer`, `start`

### `Players.WhitneyHubbard39.PlayerScripts.CameraFeelClient` (LocalScript)

`SpringFrequency`, `spring`, `removeLastEffect`, `boost`, `AdrenalineFOV`, `AdrenalineFOVFrequency`, `clamp`, `boostOnly`, `GameRole`, `DashCount`, `TackleStartedAt`, `workspace`, `MovementReset`, `PlatformStand`, `CameraSubject`, `CameraType`, `Scriptable`, `MenuIsOpen`, `ReleaseCameraForUI`, `ChoiceSpotlightActive`, `CutsceneActive`, `ScreenPresentationActive`, `ReleaseCursorForControls`, `MovementLocked`, `Intensity`, `AdrenalineFeel`, `AdrenalineKick`, `FloorMaterial`, `Air`, `VectorToObjectSpace`, `MaxSpeed`, `Dash`, `Mode`, `RunBoost`, `RunBoostKickScale`, `DashRollKick`, `DashPitchKick`, `pitch`, `DashPullbackKick`, `pullback`, `DashFOV`, `TackleDuration`, `TackleActive`, `number`, `DivePitchKick`, `DivePullbackKick`, `DiveFOV`, `CameraKickAt`, `CameraKickPower`, `LandingKick`, `vertical`, `random`, `StepFrequency`, `RunRollDegrees`, `MaxRollDegrees`, `Acceleration`, `AccelerationPitchDegrees`, `MaxPitchDegrees`, `lateral`, `LateralLag`, `DivePullback`, `MaxPullback`, `RunFOV`, `FOVFrequency`, `BobSide`, `BobHeight`, `constrain`, `Angles`, `ChickenOrHeroCameraFeelReset`, `UnbindFromRenderStep`, `ChickenOrHeroCameraFeel`, `GetService`, `ChickenOrHero`, `Movement`, `CameraFeelConfig`, `MovementProfiles`, `CameraCollision`, `WindowFocused`, `WindowFocusReleased`, `Input`, `Value`

### `Players.WhitneyHubbard39.PlayerScripts.CandyCornPickupClient` (LocalScript)

`GameRole`, `InMatch`, `Phase`, `eligible`, `Sync`, `FireServer`, `refresh`, `CandyCorn`, `LightInfluence`, `AlwaysOnTop`, `MaxVisibleDistance`, `MaxDistance`, `fromScale`, `Candy`, `Amount`, `fromRGB`, `billboard`, `token`, `points`, `Candy_`, `CastShadow`, `position`, `amount`, `Adornee`, `phase`, `GemCollect`, `Fire`, `StudsOffsetWorldSpace`, `collected`, `number`, `bloodMoon`, `GetService`, `BloodMoonHidden`, `SAFE`, `catches`, `rescues`, `RoundCandyCorn`, `fromOffset`, `concat`, `ImageTransparency`, `round`, `Layout`, `Clear`, `Collected`, `clock`, `ChickenOrHero`, `Collectibles`, `CandyCornEvent`, `CandyCornConfig`, `Game`, `Audio`, `PresentationCues`, `GroupRun`, `HeroRun`, `FinalRun`, `ExtraBold`, `LocalRunnerCandyCorn`, `workspace`, `OnClientEvent`

### `Players.WhitneyHubbard39.PlayerScripts.CarouselClient` (LocalScript)

`rider`, `workspace`, `Ragdolled`, `onDeck`, `carryMine`, `IsDescendantOf`, `Angles`, `angle`, `BulkMoveMode`, `FireCFrameChanged`, `BulkMoveTo`, `Horses`, `AncestryChanged`, `PreSimulation`, `start`, `clock`, `ActiveMapId`, `Map`, `model`, `refresh`, `GetService`, `ChickenOrHero`, `Game`, `CarouselConfig`

### `Players.WhitneyHubbard39.PlayerScripts.CatchFeedbackClient` (LocalScript)

`GroupTransparency`, `CatchConfirmed`, `catcher`, `UserId`, `format`, `verified`, `runner`, `fromOffset`, `GetService`, `ChickenOrHero`, `Audio`, `Events`, `Presentation`, `VerifiedName`, `CatchConfirmation`, `CanvasGroup`, `Confirmed`, `fromScale`, `fromRGB`, `UITextSizeConstraint`, `MinTextSize`, `OnClientEvent`

### `Players.WhitneyHubbard39.PlayerScripts.CatcherReachClient` (LocalScript)

`motor`, `applied`, `Transform`, `restore`, `UserId`, `Torso`, `character`, `torso`, `weight`, `ReachTargetUserId`, `DaggerEquipped`, `ClientBot`, `MovementLocked`, `TackleActive`, `ReachPhase`, `ReachDirection`, `Windup`, `Tracking`, `GameRole`, `ReachDistance`, `TrackingWeight`, `WindupWeight`, `ReachFadeRate`, `RootJoint`, `transform`, `GetService`, `ChickenOrHero`, `Presentation`, `ParticipantDirectory`, `ReachPose`, `Game`, `ContactCatchConfig`, `PreAnimation`, `PreSimulation`

### `Players.WhitneyHubbard39.PlayerScripts.CaughtLoadoutClient` (LocalScript)

`workspace`, `ViewportSize`, `screen`, `number`, `floor`, `count`, `GameRole`, `Caught`, `CutsceneActive`, `CreatorUIHidden`, `PracticeActive`, `blocked`, `clock`, `refresh`, `Avatar`, `Bot`, `Wins`, `Catches`, `Knife`, `Ability`, `Emote`, `Owned`, `Offer`, `Bundle`, `shown`, `layout`, `GetService`, `FFlags`, `CaughtLoadout`, `ChickenOrHero`, `Presentation`, `CaughtLoadoutCard`, `Game`, `CaughtLoadoutEvent`, `ZIndexBehavior`, `Sibling`, `UIProportionalExclude`, `OnClientEvent`

### `Players.WhitneyHubbard39.PlayerScripts.ChronoClient` (LocalScript)

`model`, `_player`, `isContextOwner`, `Ragdolled`, `RufusLeashPull`, `interpolation`, `_clientClock`, `_getBuffer`, `ViewReportSeconds`, `FireServer`, `FFlags`, `Chrono`, `GetService`, `ChickenOrHero`, `Game`, `ChronoSetup`, `start`, `chrono`, `Client`, `ClientClock`, `ChronoView`, `Holder`, `idMap`

### `Players.WhitneyHubbard39.PlayerScripts.ClanClient` (LocalScript)

`Triggered`, `ClansPrompt`, `ProximityPrompt`, `Clans`, `found`, `ClanOpen`, `close`, `GetService`, `ChickenOrHero`, `FFlags`, `Interface`, `ClanMenu`, `start`, `ClanHall`, `Game`, `MapLocator`, `interactables`, `Presentation`, `HudNavigation`, `register`, `setAvailable`

### `Players.WhitneyHubbard39.PlayerScripts.CloneAbilityClient` (LocalScript)

`ClientReady`, `EquippedKnife`, `Skin`, `InMatch`, `PracticeActive`, `GameRole`, `GlobalPaused`, `MapChanging`, `knifeBlocked`, `available`, `reason`, `clock`, `CloneAbilityReadyAt`, `workspace`, `Activate`, `FireServer`, `request`, `ButtonL1`, `ClonePulse`, `PartType`, `Ball`, `Shape`, `Neon`, `Blue`, `CastShadow`, `AddItem`, `pulse`, `Fire`, `Split`, `ownerId`, `UserId`, `position`, `Dissolve`, `clamp`, `touchStack`, `factor`, `fromOffset`, `right`, `CloneAbilityActiveUntil`, `format`, `floor`, `CLONE`, `RECHARGING`, `GamepadEnabled`, `fromScale`, `Cooldown`, `GetService`, `Debris`, `ChickenOrHero`, `Weapons`, `CloneAbilityConfig`, `CloneAbilityEvent`, `CloneSplitEffects`, `OldUIReskin`, `Theme`, `Movement`, `ControlGate`, `Presentation`, `EquipmentHudLayoutLegacy`, `HudNavigation`, `Game`, `AbilityRule`, `screen`, `KnifeAbilityHUD`, `HudAccents`, `clone`, `ColorSequenceKeypoint`, `Corner`, `Shimmer`, `CloneHead`, `corner`, `CloneBody`, `track`, `MouseEnter`, `MouseLeave`, `OnClientEvent`

### `Players.WhitneyHubbard39.PlayerScripts.CodesClient` (LocalScript)

`adopt`, `stroke`, `label`, `status`, `setStatus`, `redeemLabel`, `REDEEM`, `redeem`, `setBusy`, `release`, `CodesOpen`, `close`, `clock`, `Redeem`, `FireServer`, `submit`, `fromOffset`, `fitScreen`, `ButtonB`, `opening`, `Codes`, `whole`, `CodesPanel`, `ZIndexBehavior`, `Sibling`, `request`, `Shade`, `Selectable`, `fromScale`, `Panel`, `Header`, `CODES`, `Info`, `CloseButton`, `Field`, `Code`, `ClearTextOnFocus`, `PlaceholderText`, `PlaceholderColor3`, `fromRGB`, `Focused`, `FocusLost`, `KeyboardEnabled`, `CaptureFocus`, `ClaimPop`, `given`, `heading`, `celebrate`, `Result`, `Fire`, `GetService`, `ChickenOrHero`, `Presentation`, `HudNavigation`, `Interface`, `Cursor`, `CodeEvent`, `ExtraBold`, `AuthoredScreens`, `OnClientEvent`, `register`, `setAvailable`

### `Players.WhitneyHubbard39.PlayerScripts.CombineChatClient` (LocalScript)

`escape`, `Announce`, `ChatNotificationsEnabled`, `displayName`, `nameOf`, `clock`, `UltimateLine`, `format`, `TierColors`, `ToHex`, `CombineUltimate`, `DisplaySystemMessage`, `TextChatService`, `GetService`, `ChickenOrHero`, `Weapons`, `CombineConfig`, `CombineEvent`, `TextChannels`, `RBXGeneral`, `OnClientEvent`

### `Players.WhitneyHubbard39.PlayerScripts.CombineClient` (LocalScript)

`opening`, `Combine`, `CombineOpen`, `opened`, `closed`, `setOpen`, `close`, `isOpen`, `setAvailable`, `setHidden`, `GetService`, `ChickenOrHero`, `Presentation`, `HudNavigation`, `ValleyPanels`, `CombineScreen`, `screen`, `Shade`, `fromScale`, `fullscreenShade`, `frame`, `cursorWhileVisible`, `closeButton`, `register`, `start`

### `Players.WhitneyHubbard39.PlayerScripts.ConnectionQualityClient` (LocalScript)

`ServerBrowserOpen`, `visible`, `HighPingWarning`, `clearWarning`, `cancel`, `GetNetworkPing`, `number`, `HighPingMs`, `HighPingSamples`, `PingSampleSeconds`, `updateSampling`, `GetService`, `ChickenOrHero`, `Game`, `ConnectionQualityConfig`, `ServerBrowser`, `Panel`

### `Players.WhitneyHubbard39.PlayerScripts.ContentTeamClient` (LocalScript)

`Gold`, `showTab`, `nextOrder`, `Row`, `label`, `Input`, `fromOffset`, `Box`, `PlaceholderText`, `PlaceholderColor3`, `ClearTextOnFocus`, `fromRGB`, `corner`, `input`, `Grid`, `UIGridLayout`, `Layout`, `CellSize`, `CellPadding`, `FireServer`, `Hold`, `frozen`, `Freeze`, `StartNow`, `clock`, `EndMatch`, `SetMap`, `Modes`, `SetMode`, `starter`, `UserId`, `Starter`, `Lead`, `OFF`, `upper`, `ModeNames`, `RANDOM`, `paint`, `activate`, `CreatorCamera`, `CameraMaxZoomDistance`, `Look`, `david`, `Reset`, `PreviewAction`, `StopPreview`, `PreviewSkin`, `StudioClearAbility`, `StudioResetAbility`, `StudioEquipAbility`, `StudioEquipItem`, `Stop`, `TestPlay`, `workspace`, `ViewportSize`, `clamp`, `opening`, `ContentTeam`, `Sync`, `setOpen`, `ContentTeamButton`, `CONTENT`, `PaddingLeft`, `PaddingRight`, `PaddingTop`, `PaddingBottom`, `addButton`, `ValleyHUD`, `SettingsShade`, `Panel`, `HolderFrame`, `Settings`, `Header`, `fromScale`, `PrivateHost`, `HostPanelShade`, `HostPanel`, `attach`, `GetService`, `ChickenOrHero`, `Game`, `ContentTeamRemote`, `Presentation`, `ValleyPanels`, `HudNavigation`, `Weapons`, `SkinCatalog`, `Gear`, `GearCatalog`, `Emotes`, `EmoteCatalog`, `PrivateHostCatalog`, `Crates`, `CrateEvent`, `GearEvent`, `EmoteEvent`, `Normal`, `screen`, `ContentTeamPanel`, `stroke`, `cursorWhileVisible`, `MATCH`, `LOOK`, `KNIVES`, `ABILITIES`, `EMOTES`, `floor`, `Tab`, `ScrollBarThickness`, `AutomaticCanvasSize`, `Padding`, `Actions`, `Draw`, `Stab`, `Dive`, `Order`, `EquipReady`, `Kind`, `Ability`, `UseRole`

### `Players.WhitneyHubbard39.PlayerScripts.CrateClient` (LocalScript)

`connect`, `fromRGB`, `stroke`, `Gold`, `radius`, `fromScale`, `soundButton`, `Kind`, `Emote`, `Common`, `Entries`, `Rarity`, `rarity`, `Skin`, `prize`, `format`, `percent`, `TutorialCrate`, `Crate`, `TutorialStep`, `tutorialFree`, `offer`, `count`, `currency`, `Free`, `Gems`, `number`, `Coins`, `ProductId`, `offerShown`, `floor`, `fromOffset`, `layoutResults`, `frame`, `Art`, `NameLabel`, `SoundButton`, `layout`, `PreviewRotation`, `Angles`, `Weapons`, `Preview`, `Blade`, `JointInstance`, `cross`, `viewport`, `camera`, `extent`, `preview`, `Mythical`, `Epic`, `Legendary`, `bonus`, `DuplicateGems`, `Rare`, `emoteDisclosure`, `loaded`, `pending`, `InMatch`, `ComingSoon`, `allowed`, `token`, `FREE`, `PriceInRobux`, `robuxAllowed`, `UNAVAILABLE`, `IsForSale`, `secondary`, `shimmer`, `price`, `coins`, `reason`, `render`, `setBusy`, `clock`, `comingSoon`, `GamepadCursorEnabled`, `EnableGamepadCursor`, `DisableGamepadCursor`, `gamepadCursor`, `destroy`, `sound`, `ClearAllChildren`, `clearGrid`, `clearResults`, `cancel`, `stopReveal`, `corner`, `ImageColor3`, `soundId`, `upper`, `Weight`, `UITextSizeConstraint`, `Limit`, `MinTextSize`, `buildCard`, `fetch`, `fetchPrices`, `Open`, `FireServer`, `weights`, `clone`, `current`, `CrateOpen`, `opening`, `Crates`, `duplicate`, `revealTag`, `crate`, `revealOne`, `resultSound`, `textStroke`, `label`, `Result`, `Pop`, `RarityLine`, `NEW`, `Mint`, `resultCell`, `prizes`

### `Players.WhitneyHubbard39.PlayerScripts.CrateDisplayClient` (LocalScript)

`Crates`, `Entries`, `Skin`, `Rarity`, `Epic`, `Legendary`, `Mythical`, `prizes`, `Blade`, `CrateKnife`, `PreviewRotation`, `CastShadow`, `ScaleTo`, `GetScale`, `Angles`, `CrateKnifeRays`, `LightEmission`, `ParticleOrientation`, `FacingCamera`, `Orientation`, `LockedToPart`, `Speed`, `RotSpeed`, `Lifetime`, `Rate`, `ZOffset`, `NumberSequenceKeypoint`, `model`, `offset`, `scale`, `grown`, `knifeCopy`, `knife`, `dropKnife`, `knifeTried`, `random`, `lastKnife`, `clamp`, `shown`, `Emit`, `showKnife`, `dancer`, `track`, `dispose`, `dancing`, `hideDancer`, `dropDancer`, `source`, `dressed`, `EquippedDagger`, `CrateDancer`, `animator`, `height`, `Animator`, `dancerFor`, `dancerTried`, `poseEmote`, `GymEmote`, `lastEmote`, `lookAt`, `showDancer`, `hingeOffset`, `closedOffset`, `restore`, `attachment`, `timer`, `remove`, `format`, `endsText`, `frame`, `round`, `LeavingTimer`, `fromScale`, `StudsOffsetWorldSpace`, `MaxDistance`, `LightInfluence`, `fromRGB`, `Pill`, `SizeConstraint`, `RelativeYY`, `Clock`, `Minute`, `Hour`, `Countdown`, `Bold`, `workspace`, `floor`, `leavingTimer`, `EmoteCrate`, `CrateModel`, `EmberCrate`, `CelestialCrate`, `Body`, `Lid`, `LidHinge`, `BasicCrate`, `PremiumCrate`, `fromMatrix`, `LocalCrateSparkles`, `PointLight`, `Range`, `Brightness`, `Shadows`, `SpreadAngle`, `light`, `sparks`, `phase`, `amplitude`, `lastCycleTime`, `emotes`, `FreeReward`, `ShopModel`, `WorldCFrame`, `EndsAt`, `number`, `endsAt`, `smooth`, `InMatch`, `GetService`, `ChickenOrHero`

### `Players.WhitneyHubbard39.PlayerScripts.CrateRollOverheadClient` (LocalScript)

`GetPolicyInfoForPlayerAsync`, `ArePaidRandomItemsRestricted`, `InMatch`, `Lobby`, `GameRole`, `EventIntroPlaying`, `AdminTransferring`, `ServerBrowserTransferring`, `inLobby`, `Head`, `headOf`, `destroy`, `workspace`, `distanceTo`, `Show`, `number`, `Pumpkin`, `PumpkinRollOverhead`, `Wheel`, `SpinWheelKnifeOverhead`, `CrateRollOverhead`, `GetPlayerByUserId`, `preview`, `SendRadius`, `MaxShows`, `opener`, `IsDescendantOf`, `UserId`, `GetService`, `PolicyService`, `FFlags`, `ChickenOrHero`, `Crates`, `CrateRollConfig`, `OverheadRoll`, `CrateRollEvent`, `OnClientEvent`

### `Players.WhitneyHubbard39.PlayerScripts.CreatorClient` (LocalScript)

`TestUIHidden`, `shown`, `authorized`, `ClientReady`, `lobby`, `CreatorCameraActive`, `hidden`, `CreatorCameraSpeed`, `CreatorFOV`, `KeyboardEnabled`, `render`, `setHidden`, `opening`, `CreatorStudio`, `CreatorPanelOpen`, `panel`, `restore`, `activate`, `CreatorCamera`, `camera`, `CreatorCapture`, `clean`, `refresh`, `Admin`, `AdminEvent`, `Command`, `FireServer`, `value`, `MenuIsOpen`, `destroy`, `GetService`, `ChickenOrHero`, `Presentation`, `Game`, `CreatorPolicy`, `HudNavigation`, `CreatorVisibility`, `CreatorView`, `commands`, `close`, `speeds`, `lenses`, `MenuOpened`, `CreatorAuthorized`, `GameRole`, `PlayerBlockers`, `MapChanging`, `GlobalPaused`, `LastInputTypeChanged`

### `Players.WhitneyHubbard39.PlayerScripts.CrossyRoadClient` (LocalScript)

`floor`, `BodyColors`, `HeadColor3`, `LeftArmColor3`, `RightArmColor3`, `TorsoColor3`, `LeftLegColor3`, `RightLegColor3`, `Head`, `Torso`, `recolor`, `track`, `folder`, `clock`, `paused`, `workspace`, `serverAt`, `LoadAnimation`, `lanes`, `expires`, `Chaser_`, `Highlight`, `HumanoidDisplayDistanceType`, `DisplayDistanceType`, `position`, `width`, `lateral`, `lookAt`, `direction`, `chasers`, `Animator`, `Animation`, `PublishedIds`, `Walk`, `AnimationId`, `speed`, `WalkReferenceSpeed`, `clamp`, `AnimationPriority`, `Movement`, `Priority`, `model`, `AdjustSpeed`, `syncClock`, `Clear`, `CrossyRoadLocal`, `Chasers`, `RedHighlight`, `Adornee`, `fromRGB`, `FillColor`, `OutlineColor`, `FillTransparency`, `OutlineTransparency`, `lastReport`, `Lane`, `index`, `fromMatrix`, `samples`, `across`, `Neon`, `Spawn`, `Clock`, `Phase`, `GroupRun`, `InMatch`, `GameRole`, `previous`, `character`, `reset`, `MovementReset`, `contact`, `Hit`, `before`, `FireServer`, `AdminMatchMode`, `CrossyRoad`, `Sync`, `GetService`, `ChickenOrHero`, `Game`, `CrossyRoadEvent`, `CrossyRoadMotion`, `AnimationConfig`, `CrossyRoadChaserTemplate`, `OnClientEvent`

### `Players.WhitneyHubbard39.PlayerScripts.CupTrailerClient` (LocalScript)

`clamp`, `clamp01`, `easeIn`, `easeIO`, `floor`, `Angles`, `CastShadow`, `SmoothPlastic`, `SurfaceType`, `Smooth`, `TopSurface`, `BottomSurface`, `block`, `Face`, `SurfaceGuiSizingMode`, `PixelsPerStud`, `SizingMode`, `LightInfluence`, `CreatorCaptureExempt`, `surface`, `fromScale`, `AutoLocalize`, `paint`, `create`, `Shape`, `PartType`, `Cylinder`, `fromMatrix`, `workspace`, `BulkMoveMode`, `FireCFrameChanged`, `BulkMoveTo`, `placeRing`, `stripe`, `crowd`, `parts`, `rests`, `fromRGB`, `WoodPlanks`, `NormalId`, `Neon`, `Front`, `lookAt`, `fromHex`, `phase`, `frames`, `buildGym`, `cheer`, `CreateHumanoidModelFromDescriptionAsync`, `HumanoidRigType`, `dressed`, `GetAppliedDescription`, `RETRY_SECONDS`, `GetHumanoidDescriptionFromUserIdAsync`, `UserId`, `clock`, `looks`, `Animation`, `AnimationId`, `assets`, `animator`, `LoadAnimation`, `animation`, `BaseDagger`, `model`, `CupTrailerActor`, `stowed`, `blade`, `showBlade`, `Highlight`, `FillTransparency`, `OutlineColor`, `OutlineTransparency`, `HighlightDepthMode`, `Occluded`, `DepthMode`, `outline`, `clips`, `Idle`, `Walk`, `Run`, `DaggerHold`, `DaggerStab`, `DaggerWindup`, `PublishedIds`, `AnimationPriority`, `Action`, `Movement`, `Action2`, `Priority`, `Length`, `assetId`, `Action4`, `actor`, `IsPlaying`, `Speed`, `AdjustSpeed`, `Stop`, `swing`, `frame`, `LineJoinMode`, `stroke`, `fromOffset`, `cover`, `scale`, `CutsceneScreen`, `CupTrailer`, `Canvas`, `canvas`, `Dark`, `Red`, `Shadow`, `shadow`, `lines`, `Line`, `streaks`, `Streak`, `Ring`, `ringStroke`, `Flash`

### `Players.WhitneyHubbard39.PlayerScripts.CursorHintClient` (LocalScript)

`CursorHintSeen`, `FireServer`, `CursorHintPending`, `CursorHintOpen`, `complete`, `loaded`, `cursorHintSeen`, `LeftAlt`, `RightAlt`, `ClientReady`, `GetService`, `MenuIsOpen`, `permitted`, `layout`, `clock`, `Get`, `KeyboardAndMouse`, `ChickenOrHero`, `Emotes`, `EmoteEvent`, `OldUIReskin`, `Skin`, `Theme`, `screen`, `CursorWelcome`, `fromOffset`, `fromScale`, `surface`, `Gold`, `Eyebrow`, `Body`, `Done`, `panel`, `radius`, `primary`, `OnClientEvent`, `CreatorPanelOpen`, `CreatorUIHidden`, `CreatorCameraActive`, `MapVoteOpen`, `InMatch`, `ScreenPresentationActive`, `TutorialRouting`, `TutorialSession`, `TutorialActive`, `TutorialFinishing`, `BalloonOfferOpen`, `ArmoryOpen`, `ServerBrowserOpen`, `JourneyOpen`, `SettingsOpen`, `UpdateLogOpen`, `AdminConsoleActive`, `AnnouncementComposerOpen`, `EmoteWheelOpen`, `MatchSummaryVisible`, `FairPlayNoticeOpen`, `ConnectionQualityOpen`, `AdminRefreshActive`, `Spectating`

### `Players.WhitneyHubbard39.PlayerScripts.CutsceneClient` (LocalScript)

`preload`, `giveUp`, `Late`, `StartAt`, `number`, `Seconds`, `workspace`, `cancel`, `Missing`, `FromStart`, `GiveUpAt`, `FightAt`, `HandBack`, `Cast`, `Order`, `Keep`, `Hide`, `CutsceneCast`, `Preload`, `Cover`, `cover`, `Limit`, `Fade`, `Until`, `Stop`, `Error`, `GetService`, `ChickenOrHero`, `FFlags`, `Cutscenes`, `Game`, `CutsceneEvent`, `Presentation`, `EclipseCutscene`, `OnClientEvent`

### `Players.WhitneyHubbard39.PlayerScripts.DaggerVisualClient` (LocalScript)

`Actions`, `custom`, `Stow`, `register`, `Animation`, `AnimationId`, `looped`, `Priority`, `priority`, `applyPolicy`, `joints`, `motor`, `applied`, `Transform`, `restore`, `scythe`, `animationPlayed`, `remove`, `animator`, `AnimationPlayed`, `GetPlayingAnimationTracks`, `bindAnimator`, `UserId`, `EquippedDagger`, `Torso`, `Handle`, `animated`, `model`, `torso`, `Animator`, `DaggerDrawStartedAt`, `number`, `workspace`, `DrawDuration`, `FadeOut`, `equip`, `DaggerState`, `Drawing`, `Stowed`, `WeightTarget`, `Stop`, `WeightCurrent`, `Length`, `EmoteProp`, `IdleGrip`, `clamp`, `apply`, `LocalMeleeActive`, `LocalMeleePhase`, `ReachPhase`, `LocalMeleeDirection`, `ReachDirection`, `ReachTargetUserId`, `Tracking`, `Held`, `TackleActive`, `MovementLocked`, `Windup`, `atan2`, `AimLimit`, `AimRate`, `VectorToObjectSpace`, `fromAxisAngle`, `GetService`, `ChickenOrHero`, `Presentation`, `ParticipantDirectory`, `Weapons`, `DaggerConfig`, `KnifeClips`, `ScythePose`, `default`, `freeze`, `PreAnimation`, `PreSimulation`

### `Players.WhitneyHubbard39.PlayerScripts.DisorientClient` (LocalScript)

`ValleyDisorient`, `UnbindFromRenderStep`, `ValleyDisorientUndo`, `workspace`, `color`, `endsAt`, `startedAt`, `Saturation`, `Contrast`, `CameraType`, `Custom`, `Angles`, `BlurEffect`, `Disorient`, `ColorCorrectionEffect`, `SoundGroup`, `EqualizerSoundEffect`, `HighGain`, `MidGain`, `LowGain`, `Value`, `start`, `DisorientedUntil`, `number`, `check`, `GetService`

### `Players.WhitneyHubbard39.PlayerScripts.DodgeballClient` (LocalScript)

`RollOffMaxDistance`, `Ended`, `sound`, `WorldPosition`, `workspace`, `Terrain`, `anchorAt`, `number`, `GetPlayerByUserId`, `bodyOf`, `Animator`, `Animation`, `AnimationId`, `LoadAnimation`, `AnimationPriority`, `Action4`, `Priority`, `Stopped`, `Weapons`, `Dodgeball`, `Blade`, `ClearAllChildren`, `PartType`, `Ball`, `Shape`, `CastShadow`, `Attachment0`, `Attachment1`, `Lifetime`, `LightEmission`, `makeBall`, `origin`, `speed`, `range`, `launch`, `AspectRatio`, `DominantAxis`, `Height`, `square`, `hidePrompt`, `green`, `danger`, `radius`, `fromScale`, `styleCatch`, `pressed`, `Catch`, `FireServer`, `pressCatch`, `arrive`, `hideAt`, `GetLastInputType`, `KeyboardEnabled`, `GamepadEnabled`, `showPrompt`, `ClientReady`, `EquippedKnife`, `InMatch`, `PracticeActive`, `GameRole`, `GlobalPaused`, `MapChanging`, `knifeBlocked`, `available`, `reason`, `clock`, `DodgeballReadyAt`, `Throw`, `throw`, `ButtonL1`, `ButtonX`, `owner`, `UserId`, `Prompt`, `Hit`, `Stun`, `Down`, `End`, `clamp`, `Angles`, `touchStack`, `factor`, `fromOffset`, `right`, `format`, `floor`, `DODGEBALL`, `RECHARGING`, `GetService`, `ChickenOrHero`, `DodgeballEvent`, `OldUIReskin`, `Skin`, `Theme`, `Movement`, `ControlGate`, `Presentation`, `EquipmentHudLayoutLegacy`, `Game`, `AbilityRule`, `fromRGB`, `DodgeballFX`, `screen`, `DodgeballHUD`, `Pulse`, `Button`, `Socket`, `outline`, `Shine`, `stroke`, `Key`, `Letter`, `Corner`, `ColorSequenceKeypoint`, `track`, `corner`, `OnClientEvent`

### `Players.WhitneyHubbard39.PlayerScripts.DonkeyKongClient` (LocalScript)

`clock`, `paused`, `workspace`, `serverAt`, `folder`, `barrels`, `Barrel`, `GetScale`, `Radius`, `ScaleTo`, `RollOffMaxDistance`, `RollOffMinDistance`, `model`, `pivotOffset`, `sound`, `spawnBarrel`, `Clear`, `DonkeyKongBarrels`, `origin`, `lastHit`, `Spawn`, `barrel`, `Clock`, `previous`, `InMatch`, `expires`, `position`, `speed`, `Angles`, `Playing`, `Pause`, `Resume`, `character`, `contact`, `HitRadius`, `Hit`, `FireServer`, `AdminMatchMode`, `DonkeyKong`, `Sync`, `GetService`, `ChickenOrHero`, `Game`, `DonkeyKongEvent`, `DonkeyKongMotion`, `OnClientEvent`

### `Players.WhitneyHubbard39.PlayerScripts.EmoteAnchorClient` (LocalScript)

`MoveDirection`, `moveVector`, `stopWatching`, `MovementReset`, `Ragdolled`, `Caught`, `AssemblyAngularVelocity`, `goHome`, `Stop`, `FireServer`, `sendStop`, `EmoteId`, `JumpRequest`, `refresh`, `follow`, `GetService`, `ChickenOrHero`, `Emotes`, `EmoteEvent`

### `Players.WhitneyHubbard39.PlayerScripts.EmoteClient` (LocalScript)

`destroy`, `picture`, `pictures`, `ClientReady`, `ready`, `emoteSlots`, `equipped`, `entryAt`, `clock`, `Get`, `FireServer`, `refresh`, `setStatus`, `comingSoon`, `dispose`, `track`, `clearPreview`, `EmoteId`, `Stop`, `Animator`, `GetPlayingAnimationTracks`, `ValleyEmote_`, `cancel`, `GamepadCursorEnabled`, `EnableGamepadCursor`, `DisableGamepadCursor`, `gamepadCursor`, `UserInputState`, `ContextActionResult`, `Pass`, `Sink`, `ValleyEmoteWheelBack`, `ContextActionPriority`, `High`, `Value`, `ButtonB`, `BindActionAtPriority`, `UnbindAction`, `bindBack`, `Shade`, `EmoteWheelOpen`, `pause`, `close`, `ComingSoon`, `EmoteName`, `setStop`, `Number`, `Caption`, `Source`, `KeyboardAndMouse`, `EMOTES`, `ultimate`, `EquippedKnife`, `Ultimate`, `ULTIMATE`, `Slots`, `shown`, `available`, `Purple`, `EMPTY`, `render`, `Fire`, `openShop`, `Emotes`, `choose`, `opening`, `SpectateRequestedExit`, `GetMouseLocation`, `layout`, `toggle`, `loaded`, `format`, `quick`, `release`, `hover`, `unhover`, `EmoteCrate`, `pending`, `emotes`, `message`, `NeedKnife`, `Playing`, `badge`, `EmoteStartedAt`, `KeyboardEnabled`, `Open`, `LightsOutDark`, `ValleyHUD`, `MenuToggle`, `fromOffset`, `IsStudio`, `assetId`, `stamp`, `GetService`, `GamepadService`, `ChickenOrHero`, `EmoteEvent`, `Weapons`, `ArmoryEvent`, `ArmoryNavigation`, `EmoteCatalog`, `EmotePlayback`, `Presentation`, `HudNavigation`, `EmoteWheelView`, `ValleyToast`, `OldUIReskin`, `Skin`, `Theme`, `watch`, `fromRGB`, `textMuted`, `StarterPackOpen`, `LikeRewardOpen`, `CreatorPanelOpen`, `CreatorUIHidden`, `CreatorCameraActive`, `MapVoteOpen`, `ReleaseCameraForUI`, `ScreenPresentationActive`

### `Players.WhitneyHubbard39.PlayerScripts.EmotePiecesClient` (LocalScript)

`HIDE_TAG`, `GetTagged`, `PieceEmote`, `CollectionService`, `GetService`, `ChickenOrHero`, `Emotes`, `EmoteCatalog`, `EmotePieces`, `PreSimulation`

### `Players.WhitneyHubbard39.PlayerScripts.EmoteVFXClient` (LocalScript)

`clock`, `EmoteId`, `unmount`, `mount`, `refresh`, `unwatch`, `watch`, `joined`, `workspace`, `update`, `GetService`, `ChickenOrHero`, `Emotes`, `EmoteVFX`, `EmitModule`, `missing`, `CollectionService`, `EmoteVFXRig`, `GetTagged`, `GetInstanceAddedSignal`, `GetInstanceRemovedSignal`

### `Players.WhitneyHubbard39.PlayerScripts.EventAudienceClient` (LocalScript)

`fromRGB`, `PaddingLeft`, `PaddingRight`, `PaddingTop`, `PaddingBottom`, `label`, `fromOffset`, `fromScale`, `resize`, `escape`, `endsAt`, `workspace`, `SetCore`, `SendNotification`, `Duration`, `upper`, `lower`, `number`, `DoubleCoins`, `Coins`, `DoubleGems`, `Gems`, `notifyBoost`, `remove`, `authorName`, `message`, `seconds`, `floor`, `clamp`, `announce`, `applied`, `original`, `lighting`, `Modes`, `GoldenHour`, `Blackout`, `MoonGravity`, `ColorCorrectionEffect`, `EventHostColor`, `ClockTime`, `TintColor`, `Saturation`, `Brightness`, `OutdoorAmbient`, `Confetti`, `EventConfettiLocal`, `Rate`, `Lifetime`, `Speed`, `Acceleration`, `SpreadAngle`, `RotSpeed`, `ColorSequenceKeypoint`, `apply`, `format`, `Rainbow`, `Highlight`, `EventRainbowLocal`, `Adornee`, `FillTransparency`, `OutlineTransparency`, `HighlightDepthMode`, `Occluded`, `DepthMode`, `fromHSV`, `UserId`, `FillColor`, `OutlineColor`, `EventState`, `BoostEnabled`, `Announcement`, `GetService`, `ChickenOrHero`, `Admin`, `EventHostRemote`, `EventHostCatalog`, `EventHostLayout`, `ValleyEventAudience`, `UIProportionalExclude`, `Root`, `EventCountdown`, `HostAnnouncement`, `OnClientEvent`, `PublicSync`, `FireServer`

### `Players.WhitneyHubbard39.PlayerScripts.EventIntroClient` (LocalScript)

`lower`, `LocalizationService`, `GetService`, `RobloxLocaleId`, `SystemLocaleId`, `match`, `lines`, `clamp`, `smooth`, `CastShadow`, `SmoothPlastic`, `SurfaceType`, `Smooth`, `TopSurface`, `BottomSurface`, `block`, `Face`, `SurfaceGuiSizingMode`, `PixelsPerStud`, `SizingMode`, `LightInfluence`, `CreatorCaptureExempt`, `surface`, `fromScale`, `paintText`, `Rate`, `LightEmission`, `emitter`, `folder`, `sweeps`, `fireworks`, `flashes`, `Anchors`, `fromRGB`, `Grass`, `SoccerNet`, `Angles`, `NormalId`, `FOOTBALL`, `Metal`, `ColorSequenceKeypoint`, `Concrete`, `Fabric`, `Flashes`, `Shape`, `ShapeStyle`, `Lifetime`, `Speed`, `ParticleEmitterShape`, `Box`, `ParticleEmitterShapeStyle`, `Neon`, `lookAt`, `SpotLight`, `Front`, `Angle`, `Range`, `Brightness`, `Shadows`, `WorldPosition`, `Attachment0`, `Attachment1`, `Width0`, `Width1`, `FaceCamera`, `Segments`, `Searchlight`, `Tip`, `Phase`, `Lean`, `phase`, `Pyro`, `EmissionDirection`, `SpreadAngle`, `Acceleration`, `NumberSequenceKeypoint`, `Drag`, `PointLight`, `Firework`, `Clash`, `clash`, `RotSpeed`, `buildStage`, `collect`, `Emit`, `burst`, `ClockTime`, `OutdoorAmbient`, `ExposureCompensation`, `Sky`, `SkyboxBk`, `SkyboxDn`, `SkyboxFt`, `SkyboxLf`, `SkyboxRt`, `SkyboxUp`, `StarCount`, `Atmosphere`, `Density`, `Decay`, `Glare`, `Haze`, `BloomEffect`, `EventIntroBloom`, `Intensity`, `Threshold`, `ColorCorrectionEffect`, `EventIntroGrade`, `Contrast`, `Saturation`, `DepthOfFieldEffect`, `EventIntroFocus`, `FarIntensity`, `NearIntensity`, `InFocusRadius`, `FocusDistance`, `nightfall`, `GetAppliedDescription`, `HumanoidRigType`, `CreateHumanoidModelFromDescriptionAsync`

### `Players.WhitneyHubbard39.PlayerScripts.EventTopbarClient` (LocalScript)

`available`, `Journey`, `activate`, `setEnabled`, `refresh`, `Badge`, `EmoteId`, `SkinId`, `Dodge`, `Coins`, `Gems`, `Keys`, `Tokens`, `Spins`, `CandyCorn`, `loaded`, `claims`, `MaxTier`, `Rewards`, `Free`, `Premium`, `TrackId`, `Key`, `premium`, `claimable`, `NoticeLabel`, `fromRGB`, `totalNotices`, `noticeChanged`, `Fire`, `badge`, `FireServer`, `Get`, `KeyboardEnabled`, `setTopbarEnabled`, `InMatch`, `topbar`, `GetService`, `ChickenOrHero`, `Presentation`, `HudNavigation`, `PlayerScripts`, `TopbarPlus`, `ValleyJourney`, `setName`, `align`, `setOrder`, `setImage`, `setLabel`, `oneClick`, `selected`, `Progression`, `JourneyConfig`, `JourneyMath`, `Elements`, `JourneyEvent`, `OnClientEvent`

### `Players.WhitneyHubbard39.PlayerScripts.FFALivesClient` (LocalScript)

`cancel`, `FFALives`, `AdminMatchMode`, `FFACatchers`, `number`, `workspace`, `FFADownUntil`, `FFAImmuneUntil`, `format`, `fromRGB`, `clamp`, `render`, `GetService`, `ChickenOrHero`, `Game`, `Lives`, `fromScale`

### `Players.WhitneyHubbard39.PlayerScripts.FallenKingBombClient` (LocalScript)

`CastShadow`, `AddItem`, `RollOffMinDistance`, `RollOffMaxDistance`, `sound`, `fromOffset`, `AlwaysOnTop`, `LightInfluence`, `StudsOffsetWorldSpace`, `fromScale`, `fromRGB`, `Lifetime`, `Speed`, `SpreadAngle`, `Rate`, `LightEmission`, `floor`, `Emit`, `PointLight`, `Range`, `Brightness`, `burst`, `workspace`, `FallenKingFight`, `FallenKing`, `kingModel`, `HitFlash`, `Highlight`, `HighlightDepthMode`, `Occluded`, `DepthMode`, `FillColor`, `FillTransparency`, `OutlineTransparency`, `OutlineColor`, `flashKing`, `Shrine`, `flashShrine`, `Drag`, `spark`, `commas`, `LineJoinMode`, `label`, `userId`, `UserId`, `combo`, `shrine`, `strike`, `random`, `position`, `MaxDistance`, `percent`, `damage`, `format`, `Dive`, `DIVE`, `SLASH`, `damageNumber`, `Shape`, `Neon`, `PartType`, `Cylinder`, `marker`, `FallenAxes`, `FallenAxesBlue`, `Blade`, `RainKnife`, `JointInstance`, `ScaleTo`, `fallingKnife`, `Angles`, `Burst`, `radius`, `clamp`, `NumberValue`, `Value`, `knifeRain`, `CameraKickPower`, `CameraKickAt`, `clock`, `seconds`, `Ring`, `Line`, `width`, `lookAt`, `Block`, `Disarmed`, `Knife`, `Roar`, `Slam`, `attack`, `smoke`, `Leap`, `Flash`, `FlashWarn`, `Rise`, `Break`, `Shatter`, `Fizzle`, `update`, `HealthBar`, `Pivot`, `shrineBar`, `FallenKingLine`, `caption`, `GetPlayerByUserId`, `characterOf`, `Attack`, `Defeat`, `Stone`, `Bomb`, `Hit`, `Deflect`, `SHIELDED`, `Catch`, `Throw`, `Combo`, `BossBomb`, `ComboLabel`, `StudsOffset`

### `Players.WhitneyHubbard39.PlayerScripts.FallenKingBossClient` (LocalScript)

`showing`, `Notifications`, `MainFrame`, `NotificationsF`, `TextBounds`, `GetGuiInset`, `floor`, `clamp`, `barTop`, `UITextSizeConstraint`, `MinTextSize`, `FallenKingBossBar`, `Bar`, `UISizeConstraint`, `MaxSize`, `MinSize`, `fromRGB`, `fromScale`, `Phases`, `Until`, `Percent`, `Phase`, `build`, `BossPhase`, `format`, `phaseText`, `BossHealth`, `BossActive`, `refresh`, `dropFog`, `BossFogCentre`, `BossFogRadius`, `number`, `lookAt`, `BossFogAt`, `Fog`, `CatchSeconds`, `workspace`, `FallenKingFog`, `CastShadow`, `SmoothPlastic`, `Lifetime`, `Rate`, `Speed`, `SpreadAngle`, `buildFog`, `FogWarning`, `fromOffset`, `refreshFog`, `CutsceneActive`, `MusicMuted`, `MusicVolume`, `musicLevel`, `FallenKingFightMusic`, `musicSound`, `fadeMusic`, `MusicPaused`, `holdMusic`, `FadeIn`, `Stop`, `BossFighting`, `IsLoaded`, `Loaded`, `FadeOut`, `refreshMusic`, `GetService`, `ChickenOrHero`, `Game`, `FallenKingBossConfig`, `Bold`, `LazySound`, `Music`

### `Players.WhitneyHubbard39.PlayerScripts.FallenKingClient` (LocalScript)

`myRoot`, `CastShadow`, `plain`, `PartType`, `Ball`, `Shape`, `Neon`, `IsLoaded`, `Loaded`, `sound`, `LightEmission`, `LightInfluence`, `NumberSequenceKeypoint`, `Lifetime`, `Speed`, `Drag`, `SpreadAngle`, `Emit`, `burst`, `level`, `model`, `Light`, `lightLevel`, `Torso`, `LowerTorso`, `GetScale`, `ScaleTo`, `Lantern`, `swing`, `swingV`, `shakeUntil`, `ensureLantern`, `VectorToObjectSpace`, `clamp`, `Angles`, `random`, `identity`, `override`, `stepLantern`, `dropLantern`, `where`, `Attachment0`, `Attachment1`, `Width0`, `Width1`, `FaceCamera`, `Segments`, `CurveSize0`, `CurveSize1`, `beams`, `clock`, `stepPours`, `lanternPoint`, `WidthScale`, `trailOn`, `Rate`, `Acceleration`, `lanternParticles`, `SoulIcon`, `fromScale`, `MaxDistance`, `Body`, `Victim`, `UserId`, `SoulEssence`, `PointLight`, `Range`, `Brightness`, `ImageTransparency`, `config`, `phase`, `image`, `light`, `parts`, `addSoul`, `quench`, `fadeSoul`, `claimed`, `removeSoul`, `Collected`, `collected`, `FallenKingProgress`, `format`, `percentText`, `workspace`, `FallenKingStone`, `stoneBody`, `overDeposit`, `Heavy`, `fromRGB`, `label`, `FallenKingBoard`, `anchor`, `value`, `buildBoard`, `refreshCauldron`, `FallenKingLiveWon`, `interactable`, `Deposit`, `launchSoul`, `piece`, `Cylinder`, `NormalId`, `EmissionDirection`, `Erupt`, `fromOffset`, `StudsOffsetWorldSpace`, `AlwaysOnTop`, `erupt`, `Launch`, `LanternLevels`, `Charge`, `offered`, `GetService`, `FFlags`, `awaitUIVersion`, `NewGui`, `Interface`, `Toasts`, `Presentation`

### `Players.WhitneyHubbard39.PlayerScripts.FallenKingHeartsClient` (LocalScript)

`halves`, `image`, `ImageTransparency`, `partial`, `fromScale`, `ImageRectOffset`, `still`, `clamp`, `halvesOf`, `playing`, `BossHearts`, `number`, `BossDownedUntil`, `pulse`, `refresh`, `GetPlayerByUserId`, `rootOf`, `RollOffMinDistance`, `RollOffMaxDistance`, `AddItem`, `sound`, `workspace`, `fromRGB`, `Lifetime`, `Speed`, `SpreadAngle`, `NormalId`, `Front`, `EmissionDirection`, `Drag`, `Rate`, `Angles`, `Emit`, `CameraKickPower`, `CameraKickAt`, `clock`, `shake`, `skidDust`, `Stop`, `lookAt`, `Animator`, `direction`, `facing`, `prepare`, `DashBack`, `DashLeft`, `animation`, `LoadAnimation`, `AnimationPriority`, `Action4`, `Priority`, `Length`, `slide`, `landPose`, `Landed`, `position`, `HitSounds`, `Land`, `userId`, `UserId`, `Hurt`, `dodged`, `random`, `fromOffset`, `HUD`, `MainFrame`, `BarMainFrame`, `rowTop`, `GetGuiInset`, `place`, `BossGraceUntil`, `format`, `stopDaze`, `BossDazedUntil`, `Head`, `DazedStars`, `StudsOffset`, `LightInfluence`, `MaxDistance`, `AspectRatio`, `DominantAxis`, `Width`, `Heavy`, `stars`, `Adornee`, `untilAt`, `refreshDaze`, `watchDaze`, `wantsHearts`, `dropRemove`, `Vector3Value`, `HeartPickup`, `Value`, `ImageRectSize`, `PointLight`, `Range`, `Brightness`, `LightEmission`, `board`, `phase`, `dropAdd`, `watchDrops`, `FallenKingFight`, `HeartDrops`, `findFight`, `Heal`, `GetService`, `ChickenOrHero`, `Game`, `FallenKingBossConfig`, `Presentation`, `EquipmentHudLayoutLegacy`, `FallenKingEvent`, `Hearts`, `Count`, `FallenKingHearts`, `Heart`, `Partial`, `ClipsDescendants`, `Dodged`

### `Players.WhitneyHubbard39.PlayerScripts.FallenKingReviveClient` (LocalScript)

`fromScale`, `fromRGB`, `buttonText`, `GetProductInfo`, `PriceInRobux`, `number`, `BossDownedUntil`, `clock`, `waiting`, `UserId`, `PromptProductPurchase`, `ButtonY`, `workspace`, `format`, `clamp`, `GetService`, `ChickenOrHero`, `Game`, `FallenKingBossConfig`, `Respawn`, `GameId`, `ProductId`, `TestProductId`, `FallenKingRevive`, `Heavy`, `Bold`, `Panel`, `UISizeConstraint`, `MinSize`, `MaxSize`, `Timer`, `Revive`, `ClipsDescendants`, `Shine`, `NumberSequenceKeypoint`, `Heart`, `SizeConstraint`, `RelativeYY`, `ImageRectSize`, `ImageRectOffset`, `Sub`, `Badge`, `Bar`, `MouseEnter`, `MouseLeave`, `PromptProductPurchaseFinished`, `DownSeconds`

### `Players.WhitneyHubbard39.PlayerScripts.FallenKingSpoilsClient` (LocalScript)

`Spoils`, `GetService`, `ChickenOrHero`, `Presentation`, `FallenKingSpoils`, `Game`, `FallenKingEvent`, `preload`, `OnClientEvent`

### `Players.WhitneyHubbard39.PlayerScripts.FallenKingStatueClient` (LocalScript)

`FallenKingProgress`, `OverMax`, `clamp`, `progress`, `format`, `percentText`, `GetService`, `FFlags`, `awaitUIVersion`, `NewGui`, `Interface`, `Toasts`, `Presentation`, `ValleyToast`, `floor`, `numberText`, `lobby`, `ThroneName`, `findThrone`, `Light`, `Highlight`, `Fire`, `Smoke`, `Sparkles`, `effect`, `Stages`, `isTier`, `shownTier`, `Stage`, `pieceOn`, `Keypoints`, `ColorSequenceKeypoint`, `Time`, `FillColor`, `OutlineColor`, `SecondaryColor`, `SparkleColor`, `IsPlaying`, `Stop`, `StageShown`, `applyPiece`, `model`, `apply`, `dropThrone`, `setupThrone`, `timerText`, `KingTimer`, `SpawnsAt`, `workspace`, `paintTimer`, `fromOffset`, `MinTextSize`, `UITextSizeConstraint`, `gradient`, `image`, `FillDirection`, `VerticalAlignment`, `Padding`, `Horizontal`, `fitted`, `scale`, `track`, `fromRGB`, `frame`, `stroke`, `Crate`, `Crates`, `rewardImage`, `FallenKingPanel`, `ZIndexBehavior`, `Sibling`, `Shade`, `fromScale`, `Panel`, `panelTop`, `panelBottom`, `purpleLight`, `purple`, `EVENT`, `cardTop`, `cardBottom`, `Reward`, `Line`, `green`, `bottom`, `Personal`, `Sub`, `percent`, `fillWidth`, `nodes`, `stages`, `souls`, `carrying`, `mineFill`, `mineWidth`, `mineNodes`, `rewards`, `buildPanel`, `paintSlot`, `paintNodes`, `stage`, `ImageTransparency`, `Awakened`, `NEXT`, `FallenKingOffered`, `personal`, `FallenKingCarried`, `greenDark`, `Reached`, `paintPanel`, `FallenKingClose`, `UnbindAction`, `FallenKingOpen`, `closePanel`, `UserInputState`, `ContextActionResult`, `Sink`, `InMatch`, `ContextActionPriority`, `High`

### `Players.WhitneyHubbard39.PlayerScripts.FallenKingSummonClient` (LocalScript)

`floor`, `reverse`, `commas`, `InMatch`, `stone`, `clock`, `workspace`, `Filling`, `Unavailable`, `Countdown`, `Summoning`, `Resting`, `SummonPot`, `SummonTarget`, `SummonRestUntil`, `fromScale`, `format`, `clamp`, `SummonEndsAt`, `SOON`, `refresh`, `Closed`, `UNAVAILABLE`, `Summon`, `Burst`, `amount`, `Emit`, `GetService`, `ChickenOrHero`, `Presentation`, `Game`, `FallenKingBossConfig`, `FallenKingAltar`, `fromRGB`, `FallenKingAltarOpen`, `FallenKingSpoilsOpen`, `CutsceneActive`, `PumpkinAltarActive`, `GhostTraderActive`, `FallenKingEvent`, `start`, `FallenKingSummonSpot`, `Middle`, `ProximityPrompt`, `SummonPrompt`, `ActionText`, `ObjectText`, `HoldSeconds`, `HoldDuration`, `PromptDistance`, `MaxActivationDistance`, `RequiresLineOfSight`, `KeyboardKeyCode`, `ButtonY`, `GamepadKeyCode`, `Souls`, `LightEmission`, `LightInfluence`, `Lifetime`, `Speed`, `SpreadAngle`, `Acceleration`, `NumberSequenceKeypoint`, `Rate`, `FallenKingMeterSign`, `MaxDistance`, `AlwaysOnTop`, `Adornee`, `fromEnum`, `Creepster`, `Meter`, `Amount`, `Triggered`, `AttributeChanged`, `OnClientEvent`

### `Players.WhitneyHubbard39.PlayerScripts.FootDustClient` (LocalScript)

`CoHRunner`, `CollisionGroup`, `FootDust`, `AudioSurface`, `Grass`, `dusty`, `attachments`, `remove`, `character`, `distance`, `emitters`, `CoHFootDust`, `Dust`, `Rate`, `Lifetime`, `Speed`, `SpreadAngle`, `NumberSequenceKeypoint`, `RotSpeed`, `Acceleration`, `Drag`, `LightInfluence`, `LightEmission`, `LockedToPart`, `VelocityInheritance`, `create`, `UpdateInterval`, `workspace`, `MaxDistance`, `FilterDescendantsInstances`, `MaxCharacters`, `PlatformStand`, `MovementLocked`, `TackleActive`, `Cloaked`, `FloorMaterial`, `Air`, `GameRole`, `MaxSpeed`, `MinSpeedRatio`, `StepDistance`, `LeftFoot`, `RightFoot`, `Normal`, `fromRGB`, `WorldPosition`, `ParticlesPerStep`, `Emit`, `GetService`, `ChickenOrHero`, `Presentation`, `FootDustConfig`, `Movement`, `MovementProfiles`, `RaycastParams`, `RaycastFilterType`, `Exclude`, `FilterType`, `RespectCanCollide`, `Ground`, `Sand`, `Mud`, `LeafyGrass`, `Dirt`

### `Players.WhitneyHubbard39.PlayerScripts.FootballEventClient` (LocalScript)

`stroke`, `corner`, `gradient`, `label`, `LineJoinMode`, `outline`, `image`, `FillDirection`, `HorizontalAlignment`, `VerticalAlignment`, `Padding`, `Horizontal`, `tweens`, `floor`, `number`, `format`, `short`, `players`, `minutes`, `claimed`, `collected`, `COLLECTED`, `wiped`, `locked`, `LOCKED`, `phase`, `Final`, `Team`, `reached`, `missed`, `MISSED`, `levels`, `teamPoints`, `Participation`, `PersonalLevels`, `points`, `Settling`, `needs`, `compact`, `claimsOpen`, `claim`, `paused`, `cardState`, `clock`, `enabled`, `ClientReady`, `ScreenPresentationActive`, `AdminRefreshActive`, `MatchSummaryVisible`, `permitted`, `phaseAt`, `workspace`, `phaseNow`, `accent`, `Gems`, `Knives`, `knife`, `color`, `titleCase`, `SourceName`, `Emotes`, `emote`, `EMOTE_IMAGE`, `Titles`, `Badges`, `MVP`, `title`, `Abilities`, `IconImage`, `Crates`, `amount`, `poseEmote`, `CrateGems`, `Gear`, `Spins`, `glyph`, `wheel`, `amountColor`, `GEM_IMAGE`, `Coins`, `COIN_IMAGE`, `GemBoostMinutes`, `boost`, `CoinBoostMinutes`, `QuestSkips`, `rewardItems`, `TeamEvent`, `Snapshot`, `StringValue`, `snapshotValue`, `JSONDecode`, `Value`, `decode`, `teams`, `teamTotals`, `thresholds`, `TeamLevels`, `final`, `champion`, `finalChampion`, `boards`, `userId`, `UserId`, `cutoff`, `saved`, `LegendRank`, `rankText`, `window`, `countdown`, `StartsAt`, `EndsAt`, `Upcoming`, `nextAt`, `status`, `delayed`, `ticker`, `ActionText`, `ObjectText`, `ProximityPromptExclusivity`, `OneGlobally`

### `Players.WhitneyHubbard39.PlayerScripts.FootballEventWorld` (LocalScript)

`owned`, `format`, `floor`, `short`, `number`, `workspace`, `recent`, `ClientReady`, `permitted`, `TeamEventTeam`, `Team`, `myTeam`, `Champion`, `Delivered`, `levels`, `rewards`, `reminder`, `claimsOpen`, `wiped`, `points`, `Personal`, `personal`, `PersonalLevels`, `teamClaims`, `Participation`, `claimable`, `TeamEventClaimInFrame`, `endInFrame`, `entry`, `onClose`, `activate`, `FootballEvent`, `failed`, `handle`, `Claim`, `FireServer`, `shown`, `reward`, `onClaim`, `claimHere`, `thresholds`, `present`, `close`, `clock`, `FootballEventOpen`, `remove`, `final`, `window`, `SettleSeconds`, `teams`, `reached`, `TeamLevels`, `remind`, `Teams`, `clamp`, `champion`, `Both`, `celebrateSnapshot`, `joined`, `claimed`, `reveal`, `levelFor`, `celebrateState`, `average`, `phaseAt`, `Upcoming`, `signText`, `above`, `AutoLocalize`, `writeSign`, `CountdownOffer`, `CountdownEnded`, `LayerCollector`, `dress`, `dressPlace`, `dressPlaces`, `watchPlace`, `unwatchPlace`, `JSONDecode`, `Value`, `readSnapshot`, `GetService`, `ChickenOrHero`, `FFlags`, `TeamEventEnabled`, `Progression`, `TeamEventConfig`, `Presentation`, `HudNavigation`, `Interface`, `TeamEventCelebration`, `Weapons`, `SkinCatalog`, `ArmoryEvent`, `OnClientEvent`, `Game`, `TeamEventRemote`, `Football`, `Futbol`, `InMatch`, `MatchSummaryVisible`, `ScreenPresentationActive`, `AdminRefreshActive`, `FootballCutsceneActive`, `Spectating`, `StarterPackOpen`, `LikeRewardOpen`, `EventRsvpOpen`, `CrateOpen`, `SpinWheelOpen`, `ArmoryOpen`, `JourneyOpen`, `CodesOpen`, `SettingsOpen`, `ServerBrowserOpen`, `CombineOpen`, `QuestsOpen`, `UpdateLogOpen`, `BalloonOfferOpen`, `BundleOfferOpen`

### `Players.WhitneyHubbard39.PlayerScripts.FootballShowClient` (LocalScript)

`sequenceSound`, `MusicMuted`, `MusicVolume`, `number`, `clamp`, `musicLevel`, `MusicPaused`, `holdMusic`, `fadeSong`, `Stop`, `IsPlaying`, `random`, `playSting`, `scored`, `startSequence`, `cheer`, `stopSong`, `FootballField`, `FootballRun`, `endSequence`, `JSONDecode`, `decode`, `CastShadow`, `Locked`, `SmoothPlastic`, `piece`, `fromMatrix`, `NormalId`, `Face`, `SurfaceGuiSizingMode`, `PixelsPerStud`, `SizingMode`, `LightInfluence`, `CreatorCaptureExempt`, `fromScale`, `lettering`, `items`, `folder`, `AddItem`, `clearField`, `fromRGB`, `gridiron`, `strip`, `Angles`, `Presentation`, `SoccerNet`, `atan2`, `pitch`, `WoodPlanks`, `court`, `Fabric`, `PartType`, `Cylinder`, `Shape`, `Metal`, `volleyNet`, `Sand`, `sandCourt`, `style`, `Futbol`, `PointToObjectSpace`, `paintEnds`, `block`, `lookAt`, `strut`, `Gear`, `Assets`, `AlleyOopHoop`, `CourtHoop`, `RaycastParams`, `RaycastFilterType`, `Exclude`, `FilterType`, `RespectCanCollide`, `FilterDescendantsInstances`, `PointToWorldSpace`, `workspace`, `Pole`, `Arm`, `Brace`, `Base`, `Pad`, `courtHoop`, `endBack`, `zoneLift`, `halfWidth`, `FootballFieldLocal`, `Basketball`, `Volleyball`, `buildField`, `refreshField`, `GameRole`, `showKeep`, `UITextSizeConstraint`, `textLabel`, `fadeOut`, `flash`, `Lifetime`, `Speed`, `SpreadAngle`, `Acceleration`, `Drag`, `RotSpeed`, `Rate`, `EmissionDirection`, `Emit`, `confetti`, `cover`, `bottom`, `letterbox`, `GetCameras`, `activeCameraController`, `GetCameraToSubjectDistance`, `PlayerScripts`, `PlayerModule`, `Focus`, `CameraMinZoomDistance`, `CameraMaxZoomDistance`, `cameraZoom`, `homeSubject`

### `Players.WhitneyHubbard39.PlayerScripts.FrostQuakeClient` (LocalScript)

`source`, `NumberSequenceKeypoint`, `Quake_`, `TimeScale`, `LightInfluence`, `Acceleration`, `Drag`, `LockedToPart`, `Rate`, `emitter`, `number`, `GetPlayerByUserId`, `workspace`, `ClientBots`, `BotUserId`, `bodyOf`, `AnimationController`, `Animator`, `animatorOf`, `RollOffMinDistance`, `RollOffMaxDistance`, `AddItem`, `sound`, `CastShadow`, `Glass`, `piece`, `EquippedDagger`, `LocalTransparencyModifier`, `hidden`, `hideKnife`, `hammer`, `release`, `clock`, `Blade`, `DaggerSkin`, `DarkIcicle`, `DaggerState`, `Stowed`, `Handle`, `BladeWeld`, `GripC1`, `identity`, `QuakeHammer`, `Massless`, `VFXWeld`, `Part0`, `Part1`, `holdHammer`, `random`, `CameraOffset`, `shake`, `floor`, `clamp`, `levelOf`, `Angles`, `Ice`, `PartType`, `Wedge`, `Shape`, `Reflectance`, `Neon`, `crystal`, `emitters`, `model`, `crystals`, `bursts`, `shards`, `Speed`, `SpreadAngle`, `EmissionDirection`, `Lifetime`, `LightEmission`, `NormalId`, `Emit`, `anchor`, `lookAt`, `PointToObjectSpace`, `segment`, `frost`, `shock`, `Orientation`, `Brightness`, `ParticleOrientation`, `VelocityPerpendicular`, `PointLight`, `fromRGB`, `Range`, `Shadows`, `FrostQuakeIce`, `Sounds`, `Slam`, `Crack`, `Snow`, `PointToWorldSpace`, `WorldPosition`, `glint`, `track`, `Stop`, `holder`, `stopSlide`, `LoadAnimation`, `AnimationPriority`, `Action`, `Priority`, `IceSlideFrost`, `startSlide`, `IceSlide`, `update`, `watch`, `FrostQuake`, `character`, `actorId`, `Action4`, `AncestryChanged`, `Length`, `FrostQuakeSlam`, `length`, `width`, `Width`, `seconds`

### `Players.WhitneyHubbard39.PlayerScripts.GAClient` (LocalScript)

`clock`, `number`, `remove`, `trackInteraction`, `UserId`, `purchase_prompt`, `HighPingWarning`, `GetNetworkPing`, `high_ping`, `floor`, `ScreenOverlay`, `overlayAttribute`, `input_mode`, `UserSettings`, `UserGameSettings`, `GetService`, `SavedQualityLevel`, `client_ready`, `unknown`, `LoadingExit`, `LoadingSeconds`, `InputMode`, `graphics_quality`, `Value`, `workspace`, `ViewportSize`, `screen`, `format`, `ready`, `ClientReady`, `GetTotalMemoryUsageMb`, `memory_mb`, `FFlags`, `GAEnabled`, `Stats`, `GAEvent`, `ChickenOrHero`, `Interface`, `Telemetry`, `setSink`, `Client`, `SessionManager`, `start`, `PromptProductPurchaseFinished`, `PromptGamePassPurchaseFinished`

### `Players.WhitneyHubbard39.PlayerScripts.GearJuiceClient` (LocalScript)

`CastShadow`, `Neon`, `AddItem`, `amount`, `round`, `lookAt`, `burst`, `PartType`, `Ball`, `Shape`, `pulse`, `Range`, `airhornWave`, `cleanup`, `GearSoundOrigin`, `GearActionSound`, `RollOffMaxDistance`, `RollOffMinDistance`, `RollOffMode`, `InverseTapered`, `Ended`, `Played`, `sound`, `Gear`, `Assets`, `JointInstance`, `Constraint`, `GripPoint`, `RightHand`, `HandGripR15`, `HandGripR6`, `WorldCFrame`, `identity`, `Massless`, `Part0`, `Part1`, `RufusLeash`, `Attachment0`, `Attachment1`, `Lifetime`, `LightEmission`, `FaceCamera`, `attached`, `Foot`, `Metal`, `PointLight`, `Brightness`, `shoes`, `tween`, `restore`, `right`, `Angles`, `Elbow`, `Wrist`, `EmergencyAirhorn`, `BananaPeel`, `BearTrap`, `SpringBox`, `PumpkinBomb`, `PumpkinBombChaser`, `Shoulder`, `phase`, `Quart`, `RocketShoes`, `BowlingBall`, `dance`, `RightShoulder`, `LeftShoulder`, `RightElbow`, `LeftElbow`, `RightWrist`, `gesture`, `clock`, `clamp`, `Root`, `Neck`, `number`, `LeftLowerLeg`, `RightLowerLeg`, `PointToObjectSpace`, `RightHip`, `LeftHip`, `trapDance`, `trail`, `ScaleTo`, `Open`, `IsDescendantOf`, `GetScale`, `GetExtentsSize`, `springPop`, `shakeBox`, `workspace`, `Items`, `ShakeSeconds`, `PopAt`, `LandAt`, `Landing`, `boxShake`, `BearTrapClamp`, `clampRig`, `GameRole`, `remove`, `position`, `radius`, `FartCloud`, `Blur`, `BlurEffect`, `FartBlur`, `GetService`, `watchFart`, `Sounds`, `seconds`, `LightInfluence`, `ParticleEmitterShape`, `Box`, `ParticleEmitterShapeStyle`, `ShapeStyle`, `NumberSequenceKeypoint`, `Rate`, `Speed`

### `Players.WhitneyHubbard39.PlayerScripts.GearUseClient` (LocalScript)

`BossHearts`, `inBossFight`, `kitHeals`, `ColorSequenceKeypoint`, `cardColors`, `InMatch`, `blocked`, `noAbilities`, `PracticeActive`, `practising`, `loaded`, `equippedForRole`, `SoulReap`, `soulReapOn`, `equippedGear`, `RescueKit`, `Lifeline`, `Game`, `Ranked`, `rankedOff`, `Kind`, `Ability`, `Caught`, `RescueAvailable`, `VowMarked`, `UseRole`, `GameRole`, `reason`, `Spectating`, `GlobalPaused`, `MapChanging`, `vowBlocked`, `clock`, `vowNotice`, `soulBlocked`, `soulFail`, `Weapons`, `VowAbilityEvent`, `Fizzle`, `FireServer`, `vowFail`, `Gold`, `workspace`, `GearReadyAt`, `request`, `Use`, `ClearAllChildren`, `IconImage`, `Gear`, `Assets`, `Preview`, `lookAt`, `preview`, `activate`, `Items`, `ButtonB`, `ClientReady`, `TAP`, `upper`, `CHASERS`, `RUNNERS`, `format`, `fromScale`, `Cooldown`, `clamp`, `ImageTransparency`, `update`, `GetService`, `ChickenOrHero`, `AbilityRule`, `OldUIReskin`, `Skin`, `Presentation`, `EquipmentHudLayoutLegacy`, `Movement`, `ControlGate`, `GearCatalog`, `FallenKingBossConfig`, `Hearts`, `Count`, `GearEvent`, `GearPredictionClient`, `HudNavigation`, `screen`, `GearControls`, `stroke`, `Outline`, `surface`, `Corner`, `SkinStroke`, `register`, `Gradient`, `Item`, `fromOffset`, `fromRGB`, `Charges`, `track`, `corner`, `VowBlocked`, `MouseEnter`, `MouseLeave`, `ArmoryEvent`, `OnClientEvent`, `Get`

### `Players.WhitneyHubbard39.PlayerScripts.GemPickupClient` (LocalScript)

`GameRole`, `InMatch`, `Phase`, `eligible`, `Sync`, `FireServer`, `refresh`, `token`, `points`, `Gem_`, `CastShadow`, `position`, `Adornee`, `MaxVisibleDistance`, `MaxDistance`, `Amount`, `amount`, `StackLeft`, `StackRight`, `fromScale`, `phase`, `GemCollect`, `Fire`, `Gem`, `fromRGB`, `StudsOffsetWorldSpace`, `collected`, `Layout`, `Clear`, `Collected`, `clock`, `ActiveMapId`, `Map9`, `workspace`, `AlwaysOnTop`, `GetService`, `ChickenOrHero`, `Collectibles`, `GemEvent`, `GemConfig`, `GemBillboard`, `Audio`, `PresentationCues`, `Game`, `GroupRun`, `HeroRun`, `FinalRun`, `LocalRunnerGems`, `OnClientEvent`

### `Players.WhitneyHubbard39.PlayerScripts.GhostAbilityClient` (LocalScript)

`ClientReady`, `EquippedKnife`, `GhostScythe`, `InMatch`, `PracticeActive`, `GameRole`, `GlobalPaused`, `MapChanging`, `knifeBlocked`, `available`, `reason`, `clock`, `GhostAbilityReadyAt`, `workspace`, `Activate`, `FireServer`, `request`, `ButtonL1`, `RollOffMaxDistance`, `AddItem`, `GhostScythePulse`, `PartType`, `Ball`, `Shape`, `Neon`, `fromRGB`, `number`, `GetPlayerByUserId`, `clamp`, `touchStack`, `factor`, `fromOffset`, `right`, `GhostImmuneUntil`, `GHOSTED`, `format`, `floor`, `GHOST`, `RECHARGING`, `GamepadEnabled`, `fromScale`, `GetService`, `Debris`, `ChickenOrHero`, `Weapons`, `GhostAbilityEvent`, `OldUIReskin`, `Skin`, `Theme`, `Movement`, `ControlGate`, `Presentation`, `EquipmentHudLayoutLegacy`, `Game`, `AbilityRule`, `screen`, `GhostAbilityHUD`, `Ghost`, `HudAccents`, `ghost`, `ColorSequenceKeypoint`, `Corner`, `SkinGradient`, `track`, `corner`, `OnClientEvent`

### `Players.WhitneyHubbard39.PlayerScripts.GhostTraderClient` (LocalScript)

`hideShowcase`, `GhostKeyTrader`, `clock`, `FireServer`, `ClientReady`, `InMatch`, `isOpen`, `reason`, `number`, `Count`, `refresh`, `GhostKeysSign`, `Adornee`, `fromScale`, `StudsOffsetWorldSpace`, `MaxDistance`, `LightInfluence`, `AlwaysOnTop`, `ExtraBold`, `Caption`, `Bold`, `fromRGB`, `lanternSign`, `Trader`, `Lantern`, `LanternFrame`, `offset`, `floating`, `PromptSpot`, `workspace`, `IsDescendantOf`, `GetFullName`, `UNAVAILABLE`, `ProximityPrompt`, `TradeKeysPrompt`, `ActionText`, `ObjectText`, `HoldDuration`, `KeyboardKeyCode`, `MaxActivationDistance`, `RequiresLineOfSight`, `parts`, `Triggered`, `PromptShown`, `setup`, `BulkMoveMode`, `FireCFrameChanged`, `BulkMoveTo`, `teardown`, `Angles`, `GhostKeyDrop`, `userId`, `UserId`, `earned`, `Skipped`, `setState`, `Spot`, `Result`, `result`, `reward`, `Refused`, `refused`, `KeyDrop`, `KeyEarned`, `GetService`, `CollectionService`, `ChickenOrHero`, `Presentation`, `Game`, `FFlags`, `GhostTraderShowcase`, `GetInstanceAddedSignal`, `GetTagged`, `Movement`, `ControlGate`, `GhostTraderView`, `GhostTrader`, `GetInstanceRemovedSignal`, `GhostTraderEvent`, `start`, `OnClientEvent`

### `Players.WhitneyHubbard39.PlayerScripts.GiveawayClient` (LocalScript)

`TestUIHidden`, `staffShown`, `GameAudio`, `MatchSummary`, `GetService`, `LazySound`, `AddItem`, `GlobalWheelOpen`, `close`, `Open`, `Reply`, `reply`, `Show`, `workspace`, `endsAt`, `ReleaseFocus`, `UserId`, `Skipped`, `Presentation`, `ValleyPanels`, `screen`, `GiveawayStatus`, `Message`, `fromScale`, `message`, `Gold`, `UITextSizeConstraint`, `Limit`, `MinTextSize`, `clock`, `CountTick`, `LevelUp`, `Sync`, `FireServer`, `GlobalGiveawayOverlay`, `UnbindFromRenderStep`, `destroy`, `Debris`, `ChickenOrHero`, `Admin`, `GiveawayEvent`, `GiveawayView`, `GiveawayPicker`, `OnClientEvent`, `Value`, `ClientReady`

### `Players.WhitneyHubbard39.PlayerScripts.GuardClient` (LocalScript)

`FairPlayNoticeOpen`, `TestUIHidden`, `showToast`, `InMatch`, `Presentation`, `SpectateEvent`, `Start`, `FireServer`, `Warning`, `title`, `message`, `Staff`, `userId`, `clock`, `ChickenOrHero`, `GetService`, `OldUIReskin`, `Skin`, `MovementGuardEvent`, `screen`, `ValleyFairPlay`, `panel`, `Eyebrow`, `Gold`, `Message`, `Acknowledge`, `fromRGB`, `Modal`, `primary`, `StaffAlert`, `fromOffset`, `corner`, `stroke`, `Dismiss`, `DISMISS`, `Watch`, `SPECTATE`, `secondary`, `OnClientEvent`

### `Players.WhitneyHubbard39.PlayerScripts.HalloweenStoreClient` (LocalScript)

`HalloweenShopScreen`, `screenModule`, `Live`, `itemOf`, `HalloweenCrateShow`, `rotation`, `rotationKey`, `workspace`, `Store`, `stock`, `clone`, `model`, `balance`, `setBalance`, `plusButton`, `restricted`, `showPacks`, `owned`, `setOwned`, `setFree`, `setEndsAt`, `endsAt`, `paint`, `ProximityPrompt`, `prompts`, `InMatch`, `showPrompts`, `setBusy`, `release`, `price`, `number`, `ComingSoon`, `Packs`, `Currency`, `field`, `coins`, `Buy`, `FireServer`, `weight`, `crate`, `Entries`, `showOdds`, `Weight`, `Emote`, `Skin`, `rarity`, `color`, `percent`, `upper`, `Rarity`, `format`, `title`, `packProduct`, `productId`, `GetProductInfoAsync`, `PriceInRobux`, `robux`, `setPacks`, `PromptProductPurchase`, `HalloweenShop`, `ZIndexBehavior`, `Sibling`, `frame`, `setCurrency`, `closeButton`, `onBuy`, `onOdds`, `onLocked`, `onBuyPack`, `build`, `setItems`, `opening`, `HalloweenShopOpen`, `opened`, `Get`, `closed`, `reason`, `emote`, `prize`, `receipt`, `onDone`, `Knife`, `duplicate`, `bought`, `GetPlayerByUserId`, `watch`, `IsDescendantOf`, `match`, `Crate`, `CandyCorn`, `stopAll`, `Bought`, `Show`, `GetService`, `ProximityPromptService`, `ChickenOrHero`, `Presentation`, `Game`, `HalloweenShopConfig`, `HudNavigation`, `Weapons`, `SkinCatalog`, `Emotes`, `EmoteCatalog`, `Crates`, `CrateCatalog`, `Common`, `Rare`, `Epic`, `Legendary`, `Mythical`, `fromRGB`, `Unavailable`, `Unknown`, `TooFar`, `Loading`, `Busy`, `Owned`, `Restricted`, `GemsFull`

### `Players.WhitneyHubbard39.PlayerScripts.HauntClient` (LocalScript)

`IsCollisionGroupRegistered`, `CoHRagdoll`, `Default`, `Animation`, `AnimationId`, `animation`, `playing`, `Sounds`, `clock`, `workspace`, `range`, `random`, `RollOffMinDistance`, `RollOffMaxDistance`, `Ended`, `sound`, `Emit`, `fromRGB`, `NumberSequenceKeypoint`, `Lifetime`, `Speed`, `SpreadAngle`, `Acceleration`, `RotSpeed`, `NormalId`, `EmissionDirection`, `Rise`, `refreshOutline`, `tracks`, `IsPlaying`, `Stop`, `stopTracks`, `fadeAway`, `model`, `value`, `HitFrom`, `Skeleton`, `SkeletonBreak`, `SkeletonBreak2`, `ZombieDeath`, `Massless`, `CollisionGroup`, `AssemblyAngularVelocity`, `Part0`, `Part1`, `RootJoint`, `BallSocketConstraint`, `Attachment0`, `Attachment1`, `LimitsEnabled`, `TwistLimitsEnabled`, `UpperAngle`, `TwistLowerAngle`, `TwistUpperAngle`, `Torso`, `Dead`, `Summon`, `summon`, `Bite`, `Throw`, `attack`, `ZombieBite`, `onState`, `Kind`, `HumanoidDisplayDistanceType`, `DisplayDistanceType`, `HumanoidHealthDisplayType`, `AlwaysOff`, `HealthDisplayType`, `Yaw`, `Angles`, `Animator`, `Idle`, `LoadAnimation`, `Walk`, `Attack`, `nextVoice`, `stateConnection`, `build`, `unbuild`, `meshes`, `LocalTransparencyModifier`, `undress`, `ClearAllChildren`, `dress`, `HauntForm`, `refresh`, `watchCharacter`, `watchPlayer`, `number`, `clamp`, `summonUntil`, `GetPlayerByUserId`, `resolve`, `characterOf`, `Highlight`, `Adornee`, `FillColor`, `OutlineColor`, `FillTransparency`, `OutlineTransparency`, `HighlightDepthMode`, `Occluded`, `DepthMode`, `flashModel`, `LightEmission`, `Drag`, `burst`, `soundAt`, `CameraType`, `Scriptable`, `connection`, `PartType`, `Ball`, `Shape`, `SkeletonThrow`, `throwHead`, `stopHead`, `InMatch`, `Spectating`

### `Players.WhitneyHubbard39.PlayerScripts.HitReplayClient` (LocalScript)

`targetId`, `number`, `GetPlayerByUserId`, `DisplayName`, `target`, `targetName`, `format`, `HIT`, `verdict`, `accepted`, `MISS`, `RESULT`, `reason`, `latencyMs`, `TestUIHidden`, `GetService`, `ChickenOrHero`, `Game`, `CombatPrediction`, `start`, `PlaceId`, `HitReplayStatus`, `TestOnlyUI`, `fromScale`, `fromRGB`, `FFlags`, `ClientBots`, `Bots`, `BotDirectory`, `subscribe`

### `Players.WhitneyHubbard39.PlayerScripts.HostFlightClient` (LocalScript)

`Thumbstick1`, `IsKeyDown`, `localMove`, `UserInputState`, `Change`, `ContextActionResult`, `Sink`, `onKey`, `fromOffset`, `fromRGB`, `HostFlightTouch`, `Down`, `touchButtons`, `CoHHostFlight`, `UnbindAction`, `stepped`, `render`, `added`, `collisions`, `velocity`, `align`, `attachment`, `humanoid`, `PlatformStand`, `HumanoidStateType`, `Freefall`, `ChangeState`, `track`, `workspace`, `VectorToWorldSpace`, `MoveDirection`, `VectorVelocity`, `lookAt`, `HostFlightAttachment`, `LinearVelocity`, `HostFlightVelocity`, `Attachment0`, `ActuatorRelativeTo`, `World`, `RelativeTo`, `MaxForce`, `AlignOrientation`, `HostFlightAlign`, `OrientationAlignmentMode`, `OneAttachment`, `Mode`, `MaxTorque`, `Responsiveness`, `ContextActionPriority`, `High`, `Value`, `BindActionAtPriority`, `start`, `HostFlying`, `refresh`, `GetService`, `Space`, `ButtonR2`, `LeftControl`, `ButtonL2`, `LeftShift`, `RightShift`, `ButtonL3`

### `Players.WhitneyHubbard39.PlayerScripts.HoverShowClient` (LocalScript)

`JSONDecode`, `decode`, `MusicMuted`, `MusicVolume`, `number`, `clamp`, `musicLevel`, `fadeSong`, `WorldPosition`, `MusicPaused`, `startSong`, `Stop`, `stopSong`, `HoverRun`, `InMatch`, `Spectating`, `leftMatch`, `origin`, `workspace`, `Terrain`, `RollOffMinDistance`, `RollOffMaxDistance`, `AddItem`, `sound`, `fromScale`, `UITextSizeConstraint`, `textLabel`, `fadeOut`, `cover`, `bottom`, `letterbox`, `flash`, `floorIgnore`, `FilterDescendantsInstances`, `floorAt`, `RaycastParams`, `RaycastFilterType`, `Exclude`, `FilterType`, `AddToFilter`, `groundAt`, `CastShadow`, `stage`, `emitterPart`, `fromRGB`, `Lifetime`, `Speed`, `SpreadAngle`, `Drag`, `Rate`, `Emit`, `smoke`, `PartType`, `Ball`, `Shape`, `Neon`, `PointLight`, `Brightness`, `Range`, `fireball`, `LightEmission`, `Acceleration`, `RotSpeed`, `NormalId`, `EmissionDirection`, `sparkle`, `LocalTransparencyModifier`, `GetCameras`, `activeCameraController`, `GetCameraToSubjectDistance`, `PlayerScripts`, `PlayerModule`, `Focus`, `CameraMinZoomDistance`, `CameraMaxZoomDistance`, `cameraZoom`, `homeSubject`, `RootPart`, `CameraOffset`, `VectorToWorldSpace`, `homeLook`, `ignore`, `Distance`, `lookAt`, `occluders`, `unblocked`, `copyRunner`, `fired`, `timeFlash`, `random`, `FireLine`, `NumberSequenceKeypoint`, `ParticleEmitterShape`, `Box`, `strip`, `emitter`, `fireLine`, `burnOut`, `fireRing`, `Car`, `Door`, `doorAmount`, `doorC0`, `setDoor`, `DoorTime`, `curve`, `Angles`, `swoop`, `track`, `forward`, `floorY`, `Hover`, `right`, `Side`, `carAt`, `carRest`, `Behind`, `High`, `carFrom`, `HoverShowFire`

### `Players.WhitneyHubbard39.PlayerScripts.IceBreathClient` (LocalScript)

`Breath`, `Rate`, `NormalId`, `Front`, `EmissionDirection`, `Speed`, `SpreadAngle`, `Drag`, `Acceleration`, `Lifetime`, `RotSpeed`, `NumberSequenceKeypoint`, `fromRGB`, `LightEmission`, `LightInfluence`, `LockedToPart`, `emitter`, `attachment`, `Cloaked`, `Ghosted`, `LocalTransparencyModifier`, `hidden`, `Emit`, `breathe`, `Head`, `BreathAttachment`, `nextAt`, `random`, `lastAt`, `lastPos`, `visit`, `clock`, `ActiveMapId`, `Map9`, `workspace`, `ClientBots`, `GetService`, `ChickenOrHero`, `Game`, `Angles`, `IceBreath`, `__mode`

### `Players.WhitneyHubbard39.PlayerScripts.IceSkatesClient` (LocalScript)

`dress`, `skating`, `onRinkMatch`, `refresh`, `InMatch`, `IceSkates`, `IceSkatesHidden`, `EquippedKnife`, `watch`, `GetService`, `ChickenOrHero`, `Animation`, `IceSkating`, `enabled`, `Game`, `ActiveMapId`

### `Players.WhitneyHubbard39.PlayerScripts.IdleReportClient` (LocalScript)

`Idled`, `FireServer`, `GetService`, `ChickenOrHero`, `Game`, `PlayerPreferences`

### `Players.WhitneyHubbard39.PlayerScripts.JoinEventPrompt` (LocalScript)

`connect`, `StarterPackOpen`, `UniverseId`, `starterFirstMatch`, `starterPurchased`, `starterPresented`, `starterOfferEndsAt`, `workspace`, `starterHasPriority`, `clock`, `expiresAt`, `ClientReady`, `InMatch`, `loaded`, `starterProgressPending`, `canInvite`, `hideModel`, `DateTime`, `fromUniversalTime`, `Year`, `Month`, `Day`, `Hour`, `Minute`, `Second`, `Millisecond`, `StartTime`, `UnixTimestamp`, `startTimestamp`, `floor`, `format`, `formatRemaining`, `updateTimer`, `warnSometimes`, `GetUpcomingExperienceEventsAsync`, `HasStarted`, `HasEnded`, `getNextEvent`, `GetEventRsvpStatusAsync`, `DisplayTitle`, `RsvpStatus`, `Going`, `UserRsvpStatus`, `ThumbnailIds`, `refreshEvent`, `PromptRsvpToEventAsync`, `EventRsvpOpen`, `track`, `event_rsvp`, `EnumItem`, `failed`, `promptEvent`, `attempts`, `retryAt`, `tryInvite`, `PromptEvent`, `issuedAt`, `number`, `Get`, `FireServer`, `debug`, `traceback`, `xpcall`, `SocialService`, `GetService`, `ChickenOrHero`, `Admin`, `EventHostRemote`, `Weapons`, `ArmoryEvent`, `Gear`, `StarterPackConfig`, `ShopConfig`, `storeUniverse`, `GameId`, `Interface`, `Telemetry`, `EventModel`, `Prompt`, `ProximityPrompt`, `Main`, `Timer`, `ArmoryOpen`, `JourneyOpen`, `EmoteWheelOpen`, `SettingsOpen`, `UpdateLogOpen`, `ServerBrowserOpen`, `LikeRewardOpen`, `MapVoteOpen`, `MatchSummaryVisible`, `AdminConsoleActive`, `AdminPanelOpen`, `ScreenPresentationActive`, `QuestsOpen`, `CrateOpen`, `SpinWheelOpen`, `FootballEventOpen`, `EventKnivesOpen`, `Triggered`, `OnClientEvent`

### `Players.WhitneyHubbard39.PlayerScripts.JourneyClient` (LocalScript)

`workspace`, `JourneyVisible`, `ClientReady`, `canOpen`, `setAvailable`, `Journey`, `available`, `activate`, `round`, `Skin`, `UITextSizeConstraint`, `PhoneCap`, `label`, `Free`, `Premium`, `lanes`, `claims`, `TrackId`, `Key`, `EmoteId`, `emotes`, `SkinId`, `skins`, `complete`, `concat`, `Badge`, `Spins`, `CandyCorn`, `Keys`, `Tokens`, `Note`, `signature`, `KnifeSlot`, `upper`, `NEW`, `Badges`, `Crates`, `CrateCatalog`, `HalloweenEmote`, `KeyCrate`, `Gems`, `Coins`, `Owned`, `rewardText`, `RewardArt`, `Picture`, `fromScale`, `imageArt`, `Light`, `Stowed`, `Blade`, `ThumbAxis`, `ThumbNormal`, `VectorToWorldSpace`, `fromMatrix`, `lookAt`, `Front`, `fromRGB`, `Weapons`, `Purple`, `Fallback`, `emote`, `CrateModels`, `Gear`, `AbilityLevels`, `TokenIcon`, `Game`, `makeArt`, `filled`, `show3D`, `loaded`, `SeasonId`, `FireServer`, `claim`, `input`, `position`, `canvas`, `CanvasPosition`, `dragged`, `Claim`, `MouseMovement`, `EquipBadge`, `badge`, `GetProductInfoAsync`, `rebirths`, `SeasonNumber`, `SeasonName`, `badges`, `effective`, `reward`, `destroy`, `tried`, `accent`, `glyph`, `shown`, `MaxTier`, `ratio`, `format`, `earned`, `needed`, `premium`, `primary`, `robux`, `secondary`, `green`, `EQUIP`, `LOCKED`, `unequip`, `equip`, `locked`, `PremiumPassId`, `PurchasesEnabledUniverses`, `GameId`, `IsForSale`, `PriceInRobux`, `number`, `rebirthCoins`, `RebirthCoins`, `clock`, `reverse`

### `Players.WhitneyHubbard39.PlayerScripts.KillEffectTestClient` (LocalScript)

`workspace`, `Head`, `FocusAngle`, `WarHornTarget`, `Range`, `start`, `HornSeconds`, `HornBoost`, `Duration`, `release`, `warHorn`, `Ragdolled`, `cancel`, `HornPrompt`, `WarHornTest`, `FindFirstAncestor`, `FindFirstAncestorOfClass`, `KillEffectDummy`, `KillEffect`, `module`, `Angles`, `color`, `catcher`, `userId`, `DisplayName`, `UserId`, `GetService`, `IsStudio`, `ProximityPromptService`, `ChickenOrHero`, `Presentation`, `Gear`, `GearCatalog`, `Items`, `WarHorn`, `WarbannerCleaver`, `WarbannerBlaze`, `fromRGB`, `WarHornFocus`, `PromptTriggered`

### `Players.WhitneyHubbard39.PlayerScripts.KnifeBonusClient` (LocalScript)

`EquippedKnife`, `forSkin`, `Key`, `blocked`, `format`, `upper`, `SpeedBonus`, `CooldownReduction`, `DashCooldownReduction`, `Mythical`, `fromRGB`, `Legendary`, `Ranked`, `fromOffset`, `render`, `GetService`, `ChickenOrHero`, `Weapons`, `KnifePerks`, `Game`, `AbilityRule`, `EquippedKnifeBonuses`, `Bonuses`, `watch`

### `Players.WhitneyHubbard39.PlayerScripts.KnockdownStreakClient` (LocalScript)

`workspace`, `ViewportSize`, `Ended`, `KnockdownStreak`, `number`, `GetService`, `fromRGB`, `Streak`, `fromOffset`

### `Players.WhitneyHubbard39.PlayerScripts.KusarigamaClient` (LocalScript)

`textStroke`, `label`, `primary`, `secondary`, `radius`, `shimmer`, `neutral`, `green`, `ImageColor3`, `textSecondary`, `promptStyle`, `victim`, `phase`, `rowTop`, `GetGuiInset`, `fromOffset`, `layoutPrompt`, `resolve`, `character`, `rootOf`, `KusarigamaEscape`, `UnbindAction`, `clearPrompt`, `workspace`, `deadline`, `lastPress`, `sequence`, `FireServer`, `press`, `GetLastInputType`, `ButtonX`, `GetStringForKeyCode`, `inputLabel`, `UserInputState`, `ContextActionResult`, `Sink`, `owner`, `UserId`, `target`, `presses`, `required`, `fromScale`, `BindActionAtPriority`, `showPrompt`, `Terrain`, `RollOffMinDistance`, `RollOffMaxDistance`, `AddItem`, `sound`, `Metal`, `CastShadow`, `HookImpact`, `PartType`, `Ball`, `Neon`, `Shape`, `Rate`, `LightEmission`, `Lifetime`, `Speed`, `SpreadAngle`, `NumberSequenceKeypoint`, `Emit`, `impact`, `Weapons`, `Kusarigama`, `knife`, `Blade`, `Hook`, `offset`, `identity`, `JointInstance`, `Attachment0`, `Attachment1`, `fromRGB`, `Link`, `origin`, `position`, `Windup`, `releaseAt`, `folder`, `blade`, `pieces`, `links`, `trail`, `proxyTracks`, `animationScopes`, `nextRattle`, `create`, `applyLoopPolicy`, `disconnect`, `Stop`, `Length`, `DidLoop`, `Stopped`, `guardHookTrack`, `IsPlaying`, `FinishSeconds`, `clamp`, `stopHookTrack`, `animationsEnded`, `KusarigamaCastId`, `KusarigamaLock`, `Animation`, `AnimationId`, `match`, `Hooked`, `tracks`, `accept`, `IsDescendantOf`, `Animator`, `animator`, `connection`, `AnimationPlayed`, `GetPlayingAnimationTracks`, `watchHookActor`, `Finish`, `Kusarigama_Finish`, `endHookAnimations`, `Animations`

### `Players.WhitneyHubbard39.PlayerScripts.KusarigamaGrabLoopFix` (LocalScript)

`tracks`, `disconnect`, `Stop`, `Animation`, `AnimationId`, `match`, `Length`, `DidLoop`, `Stopped`, `guard`, `workspace`, `IsDescendantOf`, `played`, `removed`, `Animator`, `AnimationPlayed`, `AncestryChanged`, `GetPlayingAnimationTracks`, `watch`, `ChickenOrHero`, `Weapons`, `DaggerConfig`, `DiveFadeOut`

### `Players.WhitneyHubbard39.PlayerScripts.KusarigamaQuickTest` (LocalScript)

`fromOffset`, `InMatch`, `Knives`, `StudioKnifePreview`, `MovementLocked`, `Ragdolled`, `clock`, `ready`, `workspace`, `Preview`, `FireServer`, `throw`, `ClearPreview`, `StopPreview`, `EconomyLoaded`, `StudioTestAbility`, `StudioClearAbility`, `PreviewKnife`, `PreviewSkin`, `Interactable`, `KusarigamaLock`, `GetService`, `IsStudio`, `PlaceId`, `ChickenOrHero`, `Weapons`, `KusarigamaEvent`, `KusarigamaConfig`, `Crates`, `CrateEvent`, `Gear`, `GearEvent`, `KusarigamaQuickTest`, `Panel`, `fromRGB`, `ThrowChain`, `JoinMatch`, `OnClientEvent`

### `Players.WhitneyHubbard39.PlayerScripts.LastRunnerChatClient` (LocalScript)

`nameColor`, `escape`, `ChatNotificationsEnabled`, `displayName`, `username`, `chasers`, `number`, `clock`, `floor`, `format`, `ToHex`, `chaser`, `LastRunnerCrossing`, `DisplaySystemMessage`, `TextChatService`, `GetService`, `ChickenOrHero`, `Game`, `LastRunnerChatEvent`, `TextChannels`, `RBXGeneral`, `fromRGB`, `OnClientEvent`

### `Players.WhitneyHubbard39.PlayerScripts.LateJoinClient` (LocalScript)

`Interface`, `Telemetry`, `label`, `primary`, `fromRGB`, `style`, `LateJoinQueued`, `clock`, `FireServer`, `LateJoinPlay`, `fromOffset`, `fromScale`, `PLAY`, `PaddingTop`, `PaddingBottom`, `PaddingLeft`, `PaddingRight`, `bindStates`, `build`, `Notifications`, `MainFrame`, `NotificationsF`, `banner`, `EscapeStreak`, `ChoiceAnnouncement`, `LateJoin`, `place`, `Phase`, `LateJoinMode`, `PlayButton`, `Lobby`, `GameRole`, `InMatch`, `AFK`, `EscapeStreakState`, `match`, `track`, `late_join_button`, `shown`, `update`, `PlayResult`, `GetService`, `FFlags`, `LateJoinExperiment`, `ChickenOrHero`, `Game`, `LateJoinRemote`, `OldUIReskin`, `Skin`, `Prepare`, `SelectHero`, `HeroChoice`, `ChoiceReveal`, `HeroRun`, `GroupRun`, `FinalRun`, `RunResolution`, `OnClientEvent`, `LateJoinSettled`

### `Players.WhitneyHubbard39.PlayerScripts.LeaderboardClient` (LocalScript)

`reverse`, `floor`, `comma`, `format`, `numberText`, `Place`, `status`, `loading`, `updatedAt`, `members`, `total`, `PLAYER`, `PLAYERS`, `level`, `TeamLevels`, `final`, `winner`, `retrying`, `StatName`, `upper`, `season`, `studio`, `month`, `PageSize`, `statusText`, `generation`, `connection`, `destroy`, `grown`, `model`, `pivot`, `restore`, `source`, `wasEnabled`, `GetUserThumbnailAsync`, `userId`, `ThumbnailType`, `HeadShot`, `ThumbnailSize`, `Size100x100`, `PFP`, `JSONDecode`, `snapshot`, `Value`, `MainFrame`, `entries`, `paint`, `JSONEncode`, `signature`, `template`, `Rank_`, `verified`, `value`, `UserId`, `Username`, `Stat`, `ValueFormat`, `Level`, `Suffix`, `render`, `LeaderboardPart`, `Snapshot`, `Game`, `GlobalLeaderboard_`, `Adornee`, `AutoLocalize`, `build`, `apply`, `SlotFrame`, `attach`, `workspace`, `IsDescendantOf`, `AnimateDistance`, `HoverPeriod`, `HoverStuds`, `lookAt`, `TurnResponsiveness`, `LeaderboardKey`, `StringValue`, `ModelName`, `findIn`, `Container`, `Interactables`, `findBoard`, `GetService`, `ChickenOrHero`, `Presentation`, `LeaderboardConfig`, `Leaderboards`, `Progression`, `ProgressionMath`, `TeamEventConfig`, `Interface`, `TeamEventBoard`, `VerifiedName`, `MapLocator`, `LeaderboardHeader`, `lobby`, `Boards`, `SnapshotBoards`, `EventBoards`

### `Players.WhitneyHubbard39.PlayerScripts.LegacyUIClient` (LocalScript)

`HasTag`, `isKept`, `IsDescendantOf`, `holdsKept`, `GetTagged`, `release`, `HUD`, `arrived`, `GetService`, `CollectionService`, `ChickenOrHero`, `FFlags`, `NoUI`, `TouchGui`, `Freecam`, `LegacyUI`, `Screens`, `awaitUIVersion`, `OldUIReskin`, `OldUIReskinOnly`, `NewGui`, `LegacyUIOnly`, `OldUIReskinKeeps`, `OldUIKeeps`, `NewUIOnly`, `UIPerPlayer`, `UIVersion`, `Switchable`, `Presentation`, `UIVersionSwap`, `swapIn`, `Hud`, `LoadOnOpen`, `PlayerScripts`, `TopbarPlus`

### `Players.WhitneyHubbard39.PlayerScripts.LevelRewardClient` (LocalScript)

`InMatch`, `clock`, `PostMatchProgressOpen`, `RankedResultOpen`, `RankedResultPending`, `given`, `GetService`, `FFlags`, `Game`, `ClanConfig`, `MinLevel`, `Clans`, `Unlock`, `format`, `Interface`, `ClaimPop`, `heading`, `LevelUp`, `ChickenOrHero`, `LevelRewardEvent`, `OnClientEvent`

### `Players.WhitneyHubbard39.PlayerScripts.LifelineClient` (LocalScript)

`workspace`, `GetPlayerByUserId`, `UserId`, `ClientBots`, `BotUserId`, `targetCharacter`, `handEnd`, `remove`, `Lifeline`, `CastShadow`, `GetScale`, `ScaleTo`, `RopeEnd`, `RightHand`, `LifelineHand`, `RopeConstraint`, `LifelineRope`, `Attachment0`, `Attachment1`, `Length`, `targetId`, `create`, `LifelineTargetId`, `number`, `LifelineAt`, `Torso`, `UpperTorso`, `clamp`, `Angles`, `WorldPosition`, `LifelineCuts`, `Brown`, `GetService`, `ChickenOrHero`, `Gear`, `GearCatalog`, `Presentation`, `ParticipantDirectory`, `Items`, `ThrowSeconds`, `Burlap`, `Lifelines`

### `Players.WhitneyHubbard39.PlayerScripts.LightsOutClient` (LocalScript)

`KeyboardEnabled`, `touchOnly`, `InMatch`, `involved`, `LightsOutKeep`, `match`, `FindFirstAncestorWhichIsA`, `AnimationController`, `onRig`, `Highlight`, `Notifications`, `MainFrame`, `NotificationsF`, `hideFeed`, `RoleMarker`, `consider`, `Ended`, `switchSound`, `fadeTo`, `Atmosphere`, `GameRole`, `sightFor`, `FogStart`, `FogEnd`, `applySight`, `nightOn`, `nightOff`, `LightsOutSpotted`, `fromScale`, `edges`, `hideTitle`, `LightsOutTitle`, `fromRGB`, `UITextSizeConstraint`, `MinTextSize`, `showTitle`, `warnSpotted`, `markChaser`, `unmarkChaser`, `unmarkAll`, `clock`, `lastSeen`, `watchChasers`, `clearRunnerMarks`, `LightsOutRunner`, `FillTransparency`, `OutlineColor`, `OutlineTransparency`, `HighlightDepthMode`, `Occluded`, `DepthMode`, `Adornee`, `watchRunners`, `workspace`, `Field`, `Line`, `SafezoneBSide`, `SafezoneASide`, `farZone`, `StartSide`, `VectorToObjectSpace`, `PointToWorldSpace`, `findGoal`, `CastShadow`, `Neon`, `piece`, `LightsOutArrow`, `model`, `WedgePart`, `HeadRight`, `HeadLeft`, `Shaft`, `PointLight`, `Range`, `Brightness`, `Shadows`, `arrow`, `hideArrow`, `clamp`, `nearest`, `FilterDescendantsInstances`, `HipHeight`, `lookAt`, `drawArrow`, `keepGoal`, `LayerCollector`, `LightsOutDark`, `ColorCorrectionEffect`, `GetCoreGuiEnabled`, `SetCoreGuiEnabled`, `start`, `LightsOut`, `refresh`, `GetService`, `ChickenOrHero`, `Game`, `Presentation`, `ParticipantDirectory`, `Contrast`, `Saturation`, `TintColor`, `ClockTime`, `ExposureCompensation`, `OutdoorAmbient`, `FogColor`, `CoreGuiType`, `PlayerList`, `EmotesMenu`, `TouchGui`, `Freecam`, `ChoiceSpotlight`, `ValleyEmotes`, `CatchConfirmation`, `KnockdownStreak`, `OutcomeScreen`, `AdrenalineFeel`, `PerfectDodgeFeedback`, `HauntHud`, `RescueStatus`, `VowSeal`

### `Players.WhitneyHubbard39.PlayerScripts.LikeRewardClient` (LocalScript)

`connect`, `LikeRewardReadyAt`, `number`, `workspace`, `remaining`, `format`, `floor`, `clockText`, `interactable`, `FreeReward`, `likeRewardClaimed`, `IsDescendantOf`, `LocalRewardCountdown`, `fromScale`, `fromRGB`, `syncWorldReward`, `ClientReady`, `InMatch`, `TutorialRouting`, `TutorialActive`, `TutorialFinishing`, `ScreenPresentationActive`, `eligible`, `loaded`, `Selectable`, `primary`, `secondary`, `green`, `sessionOnly`, `render`, `LikeRewardOpen`, `SelectedObject`, `opening`, `LikeReward`, `SpectateRequestedExit`, `clock`, `Get`, `FireServer`, `ClaimLikeReward`, `pending`, `message`, `MatchSummaryVisible`, `ButtonB`, `GetService`, `ChickenOrHero`, `OldUIReskin`, `Skin`, `Presentation`, `HudNavigation`, `Game`, `MapLocator`, `Weapons`, `ArmoryEvent`, `screen`, `panel`, `Panel`, `TopRule`, `fromOffset`, `Gold`, `color`, `Eyebrow`, `Instructions`, `Rewards`, `Claim`, `OnClientEvent`, `ProximityPromptService`, `PromptTriggered`, `interactables`

### `Players.WhitneyHubbard39.PlayerScripts.LobbyKnifeDisplays` (LocalScript)

`BundleKey`, `shown`, `baseBundleOf`, `HallowreaperBundle`, `bundleOf`, `CountdownOffer`, `countdownLabel`, `labels`, `added`, `DescendantRemoving`, `removing`, `watchCountdowns`, `unwatchCountdowns`, `connect`, `isOnSale`, `purchased`, `ShopSlot`, `BonkerBundle`, `Key`, `chooseSwap`, `soundIds`, `EmoteSound`, `RollOffMaxDistance`, `Ended`, `Debris`, `GetService`, `AddItem`, `emoteSound`, `IDLE`, `model`, `PreviewAction`, `Light`, `VowbreakerFX`, `blade`, `Knife`, `PetalsPink`, `floor`, `reverse`, `comma`, `Flagships`, `SkinId`, `flagshipNamed`, `featured`, `workspace`, `flagshipOf`, `Featured`, `ownStand`, `covered`, `Balloon`, `BalloonDagger`, `OfferKey`, `VIP`, `Passes`, `RewardSkinId`, `Earnable`, `ClientReady`, `InMatch`, `ScreenPresentationActive`, `AdminRefreshActive`, `permitted`, `quiet`, `Football`, `Futbol`, `EventKnivesOffer`, `details`, `Fire`, `panel`, `sheen`, `LobbyKnife_`, `Adornee`, `fromScale`, `StudsOffsetWorldSpace`, `AlwaysOnTop`, `LightInfluence`, `Display`, `MaxDistance`, `billboard`, `Gear`, `GearCatalog`, `Ability`, `KnifeAbility`, `Items`, `upper`, `StandLine`, `match`, `ABILITY`, `fromHex`, `abilityOf`, `field`, `number`, `title`, `badge`, `plate`, `knife`, `Extras`, `FillDirection`, `Horizontal`, `HorizontalAlignment`, `VerticalAlignment`, `Padding`, `fromRGB`, `color`, `SizeConstraint`, `RelativeYY`, `Amount`, `label`, `timerPill`, `timer`, `bundleCard`, `stand`, `productId`, `IsForSale`, `PriceInRobux`, `owned`, `HasVIP`, `status`, `Expired`, `Offer`, `Available`, `Currency`

### `Players.WhitneyHubbard39.PlayerScripts.LobbyKnifeKeys` (LocalScript)

`InMatch`, `Lobby`, `GameRole`, `clock`, `KnifeAction`, `FireServer`, `GetService`, `ChickenOrHero`, `Crates`, `CrateEvent`, `Seven`, `Draw`, `Eight`, `Stab`, `Nine`, `Dive`, `KeypadSeven`, `KeypadEight`, `KeypadNine`

### `Players.WhitneyHubbard39.PlayerScripts.LocalLocomotionClient` (LocalScript)

`ChickenOrHero`, `Animation`, `LocalLocomotion`, `start`

### `Players.WhitneyHubbard39.PlayerScripts.LockedCameraClient` (LocalScript)

`AutoRotate`, `CameraOffset`, `releaseCharacter`, `bindCharacter`, `Spectating`, `ChoiceSpotlightActive`, `SpawnFacingVersion`, `SpawnFacing`, `workspace`, `CameraType`, `Scriptable`, `CameraSubject`, `Focus`, `MinZoom`, `MaxZoom`, `clamp`, `lookAt`, `MatchSummaryVisible`, `InMatch`, `ChickenOrHero`, `Game`, `Phase`, `Intermission`, `BossFighting`, `BossHearts`, `number`, `KeyboardAndMouse`, `PracticeActive`, `reason`, `ReleaseCursorForControls`, `cursorReason`, `MouseBehavior`, `LockCenter`, `IsMouseButtonPressed`, `Default`, `MouseIconEnabled`, `MouseEnabled`, `ShoulderOffset`, `TackleActive`, `GearMotion`, `PlatformStand`, `GetState`, `HumanoidStateType`, `Physics`, `ChickenOrHeroLockedCamera`, `UnbindFromRenderStep`, `CoHSpawnFacing`, `GetService`, `Movement`, `MovementConfig`, `CameraMinZoomDistance`, `CameraMaxZoomDistance`, `ControlGate`, `Interface`, `Cursor`, `WindowFocused`, `WindowFocusReleased`, `Value`, `PreSimulation`

### `Players.WhitneyHubbard39.PlayerScripts.Map5AmbienceClient` (LocalScript)

`finish`, `Map5Ambience`, `WorldPosition`, `workspace`, `Terrain`, `volume`, `RollOffMode`, `InverseTapered`, `minDistance`, `RollOffMinDistance`, `maxDistance`, `RollOffMaxDistance`, `Ended`, `Map5`, `Field`, `Grass`, `field`, `listener`, `howlSpot`, `clamp`, `rustleSpot`, `ActiveMapId`, `every`, `GetService`, `ChickenOrHero`, `Game`

### `Players.WhitneyHubbard39.PlayerScripts.MapLightingClient` (LocalScript)

`Atmosphere`, `ClassName`, `keyOf`, `connection`, `stopFade`, `write`, `paintSky`, `Sky`, `number`, `object`, `clock`, `ClockTime`, `glide`, `props`, `clamp`, `GetValue`, `DefaultLighting`, `FogEnd`, `FogStart`, `FogColor`, `apply`, `Configuration`, `lightingFolder`, `PracticeActive`, `MapLightingBase`, `BloodMoonHidden`, `MapLighting`, `Fade`, `refresh`, `changed`, `GetService`, `ChickenOrHero`, `Game`, `Brightness`, `ColorShift_Bottom`, `ColorShift_Top`, `EnvironmentDiffuseScale`, `EnvironmentSpecularScale`, `ExposureCompensation`, `GeographicLatitude`, `OutdoorAmbient`, `ShadowSoftness`, `ShadowColor`, `GlobalShadows`, `LightingStyle`, `PrioritizeLightingQuality`, `Outlines`, `BloomEffect`, `ColorCorrectionEffect`, `BlurEffect`, `SunRaysEffect`, `DepthOfFieldEffect`, `ColorGradingEffect`, `Intensity`, `Threshold`, `Contrast`, `Saturation`, `TintColor`, `Spread`, `FarIntensity`, `FocusDistance`, `InFocusRadius`, `NearIntensity`, `Density`, `Decay`, `Glare`, `Haze`, `TonemapperPreset`, `SkyboxBk`, `SkyboxDn`, `SkyboxFt`, `SkyboxLf`, `SkyboxRt`, `SkyboxUp`, `SunTextureId`, `MoonTextureId`, `SunAngularSize`, `MoonAngularSize`, `StarCount`, `CelestialBodiesShown`, `SkyboxOrientation`

### `Players.WhitneyHubbard39.PlayerScripts.MapVoteClient` (LocalScript)

`ClientReady`, `InitialLoadingComplete`, `AFK`, `InMatch`, `PracticeActive`, `TutorialSession`, `TutorialRouting`, `TutorialActive`, `TutorialFinishing`, `AdminTransferring`, `ServerBrowserTransferring`, `eligible`, `MapVoteOpen`, `opening`, `MapVote`, `SelectedObject`, `IsDescendantOf`, `modal`, `UserInputState`, `phase`, `Voting`, `options`, `ContextActionResult`, `Pass`, `votes`, `UserId`, `DPadLeft`, `onVote`, `Sink`, `cycle`, `MapVoteGamepad`, `DPadRight`, `BindAction`, `UnbindAction`, `bindVote`, `clock`, `ScreenPresentationActive`, `MatchSummaryVisible`, `AfterSummarySeconds`, `Result`, `ValleyHUD`, `MapChanging`, `DrawerOpen`, `canPresent`, `MapVoteJoinedAt`, `openedAt`, `endsAt`, `workspace`, `shouldExpand`, `MapVoteVisible`, `setExpanded`, `setVisible`, `gamepad`, `render`, `GlobalPaused`, `layout`, `JSONDecode`, `Value`, `token`, `Vote`, `FireServer`, `ButtonB`, `destroy`, `GetService`, `ChickenOrHero`, `Game`, `MapVoteState`, `MapVoteEvent`, `MapVoteConfig`, `Presentation`, `MapVoteTiming`, `HudNavigation`, `MapVoteView`, `Closed`, `StarterPackOpen`, `LikeRewardOpen`, `CreatorPanelOpen`, `CreatorCameraActive`, `CreatorUIHidden`, `GlobalWheelOpen`, `TutorialModalActive`, `CursorHintOpen`, `CursorHintPending`, `BalloonOfferOpen`, `ArmoryOpen`, `JourneyOpen`, `SettingsOpen`, `UpdateLogOpen`, `ServerBrowserOpen`, `AdminConsoleActive`, `AnnouncementComposerOpen`, `EmoteWheelOpen`, `FairPlayNoticeOpen`, `ConnectionQualityOpen`, `close`

### `Players.WhitneyHubbard39.PlayerScripts.MeleeInputClient` (LocalScript)

`FireServer`, `reportInput`, `InMatch`, `PracticeActive`, `attacker`, `PlatformStand`, `MovementLocked`, `Ragdolled`, `TackleActive`, `reason`, `Game`, `GlobalPaused`, `MapChanging`, `DaggerEquipped`, `DaggerState`, `Held`, `available`, `ReachStartedAt`, `workspace`, `meleeRemaining`, `number`, `remaining`, `GetService`, `GenerateGUID`, `direction`, `position`, `begin`, `Melee`, `character`, `predicted`, `startedAt`, `starts`, `Windup`, `ActiveDuration`, `meleeBox`, `dispatch`, `request`, `reconcile`, `MouseBehavior`, `LockCenter`, `ContextActionResult`, `Pass`, `UserInputState`, `Sink`, `AdminMatchMode`, `BladeBall`, `BladeHearts`, `update`, `MELEE`, `place`, `fighting`, `Dive`, `Catch`, `anchor`, `CoHMelee`, `UnbindAction`, `ChickenOrHero`, `ContactCatchConfig`, `CombatPrediction`, `start`, `Movement`, `ControlGate`, `Presentation`, `TouchActionButton`, `TouchCombatLayout`, `BossCombat`, `MeleeEvent`, `MeleeInputMode`, `HUD`, `CatchButton`, `MeleeButton`, `BoostButton`, `UISizeConstraint`, `Recovery`, `OnClientEvent`, `ButtonL2`, `BindAction`

### `Players.WhitneyHubbard39.PlayerScripts.MenuScaleClient` (LocalScript)

`FindFirstAncestorWhichIsA`, `NoMenuScale`, `Shade`, `isMenuScale`, `apply`, `connection`, `manage`, `MenuScale`, `addScale`, `consider`, `GetService`, `KeyboardEnabled`, `ValleyArmory`, `Canvas`, `HalloweenShop`, `BalloonOffer`, `Card`, `MatchSummaryUI`, `MatchResult`, `ServerBrowser`, `Panel`, `ValleyHUD`, `HUD`, `AdminUI`, `StaffPanel`, `GlobalGiveaway`, `GiveawayPicker`, `CreatorStudio`, `AdminPanelOld`, `StudioKnifePreview`, `StudioEmotePreview`, `TutorialGuide`, `TutorialDone`, `SpinWheel`, `PostMatchProgress`, `RankedLoadout`, `RankedMenu`, `Combine`, `__mode`

### `Players.WhitneyHubbard39.PlayerScripts.MergeDisplayClient` (LocalScript)

`connect`, `EndsAt`, `number`, `ended`, `isFusion`, `ULTIMATE`, `TierColors`, `tierOf`, `clamp`, `levelOf`, `LocalTransparencyModifier`, `hideStand`, `fromScale`, `StrokeSizingMode`, `ScaledSize`, `label`, `MergeLevel`, `StudsOffsetWorldSpace`, `LightInfluence`, `MaxDistance`, `Adornee`, `Level`, `Heavy`, `Knife`, `ExtraBold`, `level`, `scale`, `board`, `SourceName`, `showLevel`, `scaled`, `JointInstance`, `Part0`, `Part1`, `IsDescendantOf`, `ScaleTo`, `scaleOn`, `weapon`, `chain`, `pieces`, `joint`, `rescale`, `scaleKnife`, `audible`, `Hit`, `HitSoundProfile`, `SoundProfile`, `BaseDagger`, `Knife_`, `knife`, `emoting`, `animator`, `Intro`, `intro`, `tracks`, `sounds`, `emote`, `Pieces`, `build`, `PieceWeld`, `EmoteId`, `startEmote`, `soundIds`, `RollOffMaxDistance`, `Ended`, `emoteSound`, `dispose`, `stopEmote`, `DaggerState`, `Stowed`, `DaggerSkin`, `enter`, `DaggerDrawStartedAt`, `clock`, `Drawing`, `Equip`, `Held`, `ReachPhase`, `Windup`, `ReachStartedAt`, `Swing`, `TackleActive`, `DaggerDive`, `Dive`, `Stop`, `update`, `Sheath`, `seconds`, `Draw`, `DrawDuration`, `Ready`, `Stab`, `Recover`, `emotes`, `bundle`, `assetId`, `IntroLength`, `Length`, `SoundDelay`, `SoundEachLoop`, `SoundPerLoop`, `floor`, `Emote`, `Sheathe`, `stagesFor`, `destroy`, `remove`, `release`, `teardown`, `MergeDisplay`, `Tool`, `ProximityPrompt`, `EquippedDagger`, `GetAttributes`, `Head`, `RigType`, `HumanoidRigType`, `HumanoidDisplayDistanceType`, `DisplayDistanceType`, `AutoRotate`

### `Players.WhitneyHubbard39.PlayerScripts.MergeMachineClient` (LocalScript)

`tween`, `Neon`, `CastShadow`, `Rate`, `LightEmission`, `LightInfluence`, `NumberSequenceKeypoint`, `Lifetime`, `Speed`, `SpreadAngle`, `RotSpeed`, `emitter`, `sound`, `clock`, `clamp`, `Angles`, `Shockwave`, `Arc`, `Emit`, `random`, `lookAt`, `ImpactStreak`, `AddItem`, `burst`, `fromScale`, `StrokeSizingMode`, `ScaledSize`, `LineJoinMode`, `boardLabel`, `TierNames`, `nameOf`, `ColorSequenceKeypoint`, `ImageColor3`, `showBoard`, `hideBoard`, `workspace`, `KnifeSummonRift`, `CrescentSlash`, `RiftSlit`, `InwardShard`, `Sparks`, `Highlight`, `Adornee`, `FillColor`, `OutlineColor`, `FillTransparency`, `OutlineTransparency`, `HighlightDepthMode`, `Occluded`, `DepthMode`, `summonKnife`, `IconCross`, `crossing`, `ThumbAxis`, `ThumbNormal`, `fromMatrix`, `identity`, `restOf`, `IconWeld`, `SpecialMesh`, `offset`, `meshScale`, `tierOf`, `Families`, `Tiers`, `Blade`, `pieces`, `twinSource`, `LeftBlade`, `Massless`, `Part0`, `Part1`, `blade`, `resize`, `isFusion`, `TierColors`, `tierColor`, `Attachment0`, `Attachment1`, `MinLength`, `FaceCamera`, `WidthScale`, `Segments`, `Width0`, `Width1`, `PointLight`, `Range`, `Brightness`, `trail`, `Add`, `RollOffMode`, `InverseTapered`, `RollOffMaxDistance`, `addSlot`, `dropSlot`, `clearSlots`, `setTint`, `ghost`, `showInMiddle`, `dropMiddle`, `SpinWheelOpen`, `SpinSummaryOpen`, `floating`, `refreshKnives`, `released`, `Knives`, `Start`, `result`, `started`, `inputs`, `knives`, `color`, `MergeEventLive`, `locked`, `ObjectText`, `Combine`, `ActionText`, `CombineOpen`, `InMatch`, `promptShown`

### `Players.WhitneyHubbard39.PlayerScripts.MythicKillClient` (LocalScript)

`GetPlayerByUserId`, `workspace`, `ClientBots`, `BotUserId`, `characterOf`, `clock`, `Blade`, `MythicKillParticles`, `Rate`, `particles`, `FillTransparency`, `OutlineTransparency`, `Highlight`, `MythicKillFlash`, `FillColor`, `OutlineColor`, `HighlightDepthMode`, `Occluded`, `DepthMode`, `AddItem`, `flash`, `Ragdolled`, `LifelineHelperId`, `LifelineDragged`, `rescued`, `number`, `Torso`, `UpperTorso`, `Game`, `BloodMoon`, `BloodMoonHidden`, `fromRGB`, `GrinnerBlades`, `cancel`, `PumpkinSovereign`, `AlbiesCutlass`, `DrownedCutlass`, `Soulbinder`, `DarkIcicle`, `WarbannerCleaver`, `userId`, `catcher`, `GetService`, `Debris`, `ChickenOrHero`, `Weapons`, `EclipseFang`, `JackInTheBox`, `GhostPepper`, `WitchfireAthame`, `PrismEdge`, `TrophyBlade`, `Hallowreapers`, `AlbiesHoverboard`, `TheLastDoor`, `FallenAxes`, `FallenAxesBlue`, `Presentation`, `BalloonLift`, `PumpkinRoll`, `BoneRattle`, `SoulShock`, `WarbannerBlaze`, `FrostbitePillar`, `MythicKillEvent`, `OnClientEvent`

### `Players.WhitneyHubbard39.PlayerScripts.NoAbilitiesClient` (LocalScript)

`Notifications`, `MainFrame`, `NotificationsF`, `findBanner`, `shown`, `floor`, `GetTextSize`, `measure`, `middle`, `layout`, `Location`, `TextBounds`, `WhatsHappening`, `clamp`, `fromOffset`, `fromScale`, `place`, `blocked`, `InMatch`, `Spectating`, `render`, `GetService`, `TextService`, `ChickenOrHero`, `Game`, `AbilityRule`, `NoAbilitiesHUD`, `NoAbilities`, `Line`, `watch`

### `Players.WhitneyHubbard39.PlayerScripts.OutbreakClient` (LocalScript)

`place`, `workspace`, `round`, `stroke`, `floor`, `format`, `pctLive`, `ImageColor3`, `fromScale`, `ImageTransparency`, `update`, `World`, `AspectRatio`, `newMap`, `OutbreakInfected`, `UserId`, `infectedHere`, `interactable`, `OutbreakEvent`, `Prompt`, `standParts`, `OutbreakMap`, `Face`, `SizingMode`, `PixelsPerStud`, `LightInfluence`, `MaxDistance`, `ZIndexBehavior`, `NormalId`, `Front`, `SurfaceGuiSizingMode`, `Sibling`, `label`, `ProximityPrompt`, `ObjectText`, `buildStand`, `Claim`, `FireServer`, `claim`, `CLAIM`, `claimButton`, `reward`, `candy`, `coins`, `crate`, `crates`, `rewardIcon`, `OutbreakOpen`, `close`, `Milestone`, `Tier`, `Outbreak`, `Shade`, `fromOffset`, `Milestones`, `detail`, `fromRGB`, `infected`, `Tiers`, `kills`, `title`, `status`, `panel`, `scale`, `mapUpdate`, `nextUnlock`, `youStroke`, `youIcon`, `youText`, `tierFill`, `rewardCards`, `footerText`, `buildWindow`, `progress`, `clock`, `milestones`, `Claimed`, `clamp`, `claimed`, `endsAt`, `startsAt`, `paintWindow`, `InMatch`, `opening`, `Get`, `OutbreakNoticeOpen`, `dismiss`, `lookAt`, `Weapons`, `Knife`, `Blade`, `KnifeIcons`, `DataModelMesh`, `SurfaceAppearance`, `fromAxisAngle`, `PreviewRotation`, `Angles`, `knifeStage`, `ArmoryEvent`, `Equip`, `track`, `outbreak_notice_equip`, `match`, `lobby`, `upper`, `Popup`, `Glow`, `Card`, `ViewportSize`, `Stage`, `ClipsDescendants`, `UITextSizeConstraint`, `EquipNow`, `NumberSequenceKeypoint`, `Timer`, `outbreak_notice`, `showInfected`, `infectedNow`, `EquippedKnife`, `MatchSummaryVisible`

### `Players.WhitneyHubbard39.PlayerScripts.OverheadClient` (LocalScript)

`teamColor`, `format`, `floor`, `ClanTag`, `ClanColor`, `ClanGlow`, `clanTag`, `clock`, `Content`, `DisplayName`, `player`, `shimmer`, `characterConnections`, `statConnections`, `clean`, `Username`, `ClanShimmer`, `GameRole`, `AFK`, `OverheadTitle`, `SpecialRank`, `OverheadTitleColor`, `JourneyTitle`, `JourneyTitleColor`, `fromRGB`, `leaderstats`, `Wins`, `StatsLoaded`, `Value`, `Level`, `Lvl`, `number`, `Tiers`, `RankTier`, `RankIcon`, `LookAsUserId`, `RankChampion`, `ChampionIcon`, `TierIcons`, `layout`, `update`, `IntValue`, `NumberValue`, `bindStat`, `statsAdded`, `Head`, `Adornee`, `HumanoidDisplayDistanceType`, `DisplayDistanceType`, `HumanoidHealthDisplayType`, `AlwaysOff`, `HealthDisplayType`, `adorn`, `Cloaked`, `Ghosted`, `hidden`, `Concealed`, `updateVisibility`, `apply`, `PlayerOverhead_`, `BotUserId`, `UserId`, `Smoked`, `character`, `ShowOwnName`, `LookDisplayName`, `LookVerified`, `OutbreakInfected`, `Player`, `HasVerifiedBadge`, `dropBotTag`, `visibility`, `EquippedKnife`, `botTag`, `OwnerUserId`, `GetPlayerByUserId`, `record`, `CloneOwnerUserId`, `cloneAdded`, `GetService`, `ChickenOrHero`, `Presentation`, `OverheadConfig`, `UITemplates`, `OverheadUI`, `OverheadView`, `VerifiedName`, `FFlags`, `ClientBots`, `Gear`, `PumpkinSmoke`, `Game`, `RankedConfig`, `Gold`, `Silver`, `Bronze`, `Bots`, `Actors`, `BotDirectory`, `Added`, `CharacterChanged`, `Removed`, `OutbreakConfig`, `startsAt`, `endsAt`, `workspace`

### `Players.WhitneyHubbard39.PlayerScripts.PerfectDodgeClient` (LocalScript)

`workspace`, `ViewportSize`, `AbilityControls`, `GearControls`, `GuiButton`, `clamp`, `fromOffset`, `place`, `PerfectDodge`, `Trucked`, `fromRGB`, `fromHex`, `FFCA3A`, `Stop`, `fromScale`, `GetService`, `ChickenOrHero`, `Presentation`, `BoostRequest`, `PerfectDodgeFeedback`, `UIProportionalExclude`, `PerfectDodgeSound`, `OnClientEvent`

### `Players.WhitneyHubbard39.PlayerScripts.PirateShowClient` (LocalScript)

`JSONDecode`, `decode`, `MusicMuted`, `MusicVolume`, `number`, `clamp`, `musicLevel`, `fadeSong`, `WorldPosition`, `MusicPaused`, `startSong`, `Stop`, `stopSong`, `PirateRun`, `InMatch`, `Spectating`, `leftMatch`, `origin`, `workspace`, `Terrain`, `RollOffMinDistance`, `RollOffMaxDistance`, `AddItem`, `sound`, `fromScale`, `UITextSizeConstraint`, `textLabel`, `fadeOut`, `cover`, `bottom`, `letterbox`, `flash`, `floorIgnore`, `FilterDescendantsInstances`, `floorAt`, `RaycastParams`, `RaycastFilterType`, `Exclude`, `FilterType`, `AddToFilter`, `groundAt`, `CastShadow`, `stage`, `emitterPart`, `fromRGB`, `Lifetime`, `Speed`, `SpreadAngle`, `Drag`, `Rate`, `Emit`, `smoke`, `PartType`, `Ball`, `Shape`, `Neon`, `PointLight`, `Brightness`, `Range`, `fireball`, `LightEmission`, `Acceleration`, `RotSpeed`, `NormalId`, `EmissionDirection`, `sparkle`, `LocalTransparencyModifier`, `pathOf`, `EquippedDagger`, `Blade`, `LeftBlade`, `StowedBlade`, `LeftStowedBlade`, `FindFirstAncestor`, `Attachment0`, `Attachment1`, `copyRunner`, `Head`, `IsDescendantOf`, `Accessory`, `FindFirstAncestorWhichIsA`, `Handle`, `JointInstance`, `Part0`, `Part1`, `headOnly`, `GetCameras`, `activeCameraController`, `GetCameraToSubjectDistance`, `PlayerScripts`, `PlayerModule`, `Focus`, `CameraMinZoomDistance`, `CameraMaxZoomDistance`, `cameraZoom`, `homeSubject`, `RootPart`, `CameraOffset`, `VectorToWorldSpace`, `homeLook`, `ignore`, `Distance`, `lookAt`, `occluders`, `unblocked`, `forward`, `right`, `floorY`, `Ship`, `ShipBack`, `ShipSink`, `shipRest`, `Ghost`, `ParticleEmitterShape`, `Box`, `ParticleEmitterShapeStyle`, `ShapeStyle`, `NumberSequenceKeypoint`, `LightInfluence`, `Flag`

### `Players.WhitneyHubbard39.PlayerScripts.PiratesCallClient` (LocalScript)

`IsCollisionGroupRegistered`, `CoHRagdoll`, `Default`, `workspace`, `ClientBots`, `FilterDescendantsInstances`, `refreshFilter`, `random`, `RollOffMinDistance`, `RollOffMaxDistance`, `Ended`, `sound`, `fromRGB`, `NumberSequenceKeypoint`, `Lifetime`, `Speed`, `SpreadAngle`, `Acceleration`, `NormalId`, `EmissionDirection`, `Base`, `amount`, `round`, `Emit`, `broken`, `refreshOutline`, `model`, `remove`, `tracks`, `Stop`, `lookAt`, `direction`, `Sounds`, `Break`, `position`, `flourish`, `ground`, `Massless`, `CollisionGroup`, `AssemblyAngularVelocity`, `shatter`, `clock`, `expires`, `chargeAt`, `speed`, `RiseSeconds`, `clamp`, `forActor`, `PiratesCall`, `Skeleton`, `HumanoidDisplayDistanceType`, `DisplayDistanceType`, `HumanoidHealthDisplayType`, `AlwaysOff`, `HealthDisplayType`, `ChargeSeconds`, `Animator`, `summon`, `LoadAnimation`, `Torso`, `Call`, `build`, `actorId`, `GetPlayerByUserId`, `PirateCharge`, `serverTime`, `AdjustSpeed`, `PirateBreak`, `PirateHit`, `character`, `Impact`, `GetService`, `PhysicsService`, `ChickenOrHero`, `Gear`, `GearCatalog`, `Game`, `HauntConfig`, `GearEvent`, `AbilityFlair`, `Items`, `Crew`, `Highlight`, `Adornee`, `HighlightDepthMode`, `Occluded`, `DepthMode`, `FillColor`, `OutlineColor`, `FillTransparency`, `OutlineTransparency`, `Animation`, `Anims`, `SkeletonSummon`, `AnimationId`, `SkeletonWalk`, `RaycastParams`, `RaycastFilterType`, `Exclude`, `FilterType`, `RespectCanCollide`, `AbilityLevels`, `OnClientEvent`

### `Players.WhitneyHubbard39.PlayerScripts.PracticeClient` (LocalScript)

`GetFullName`, `format`, `await`, `PracticeConfig`, `PracticeEvent`, `OnClientEvent`, `PracticeActive`, `practising`, `Lobby`, `GameRole`, `InMatch`, `ClientReady`, `Spectating`, `ScreenPresentationActive`, `waiting`, `PracticeExperiment`, `PracticeMode`, `PracticeOpen`, `Phase`, `Ranked`, `workspace`, `PrivateServerSettingsOwnerId`, `ProServer`, `MapChanging`, `BossFighting`, `offered`, `UNAVAILABLE`, `PracticeReadyAt`, `number`, `PracticeFull`, `FULL`, `CLOSED`, `refusal`, `setPicker`, `closePicker`, `clock`, `pickerOpen`, `opening`, `Practice`, `pressPractice`, `Start`, `FireServer`, `Leave`, `leave`, `PracticeStay`, `Stay`, `PracticeResult`, `JSONDecode`, `ResultSeconds`, `PracticeRole`, `showResult`, `Notifications`, `MainFrame`, `NotificationsF`, `bannerStack`, `clamp`, `EscapeStreak`, `ChoiceAnnouncement`, `TutorialGuide`, `Objective`, `place`, `GetService`, `HUD`, `BarMainFrame`, `KeyboardEnabled`, `GetGuiInset`, `dockButton`, `PracticeEndsAt`, `PracticeRound`, `clockText`, `RunNumber`, `PracticeLiveRunners`, `liveLine`, `hideResult`, `setAvailable`, `setButton`, `practice`, `PracticeCatches`, `PracticeEscapes`, `score`, `setHud`, `leaving`, `confirm`, `setLeave`, `PracticePullAt`, `WarningSeconds`, `setWarning`, `setStaying`, `setLive`, `setGamepad`, `update`, `ButtonB`, `DPadDown`, `warning`, `FFlags`, `ChickenOrHero`, `Game`, `Presentation`, `PracticeScreen`, `HudNavigation`, `PracticeMatches`, `Prepare`, `SelectHero`, `HeroChoice`, `ChoiceReveal`, `HeroRun`, `GroupRun`, `FinalRun`, `RunResolution`, `Results`, `PracticeWorlds`, `start`, `onPractice`, `onPick`, `onClose`, `onLeave`, `onStay`, `register`, `OVER`, `Intermission`

### `Players.WhitneyHubbard39.PlayerScripts.PreRoundDisableClient` (LocalScript)

`GameRole`, `apply`, `refresh`, `Disable`, `changed`, `track`, `untrack`, `GetService`, `workspace`, `DescendantRemoving`

### `Players.WhitneyHubbard39.PlayerScripts.PricePrefetchClient` (LocalScript)

`number`, `prefetch`, `Game`, `ReviveOfferConfig`, `First`, `ProductId`, `Later`, `Crates`, `CrateCatalog`, `offer`, `Gear`, `StarterPackConfig`, `GearCatalog`, `Items`, `Weapons`, `ShopConfig`, `binding`, `GameId`, `ProductIds`, `PassIds`, `Bundles`, `List`, `productId`, `clock`, `format`, `GetService`, `ChickenOrHero`, `Interface`, `ProductPrices`, `GamePass`, `IsStudio`

### `Players.WhitneyHubbard39.PlayerScripts.PrivateHostClient` (LocalScript)

`Gold`, `ToHex`, `format`, `opening`, `HostPanel`, `HostPanelOpen`, `setOpen`, `DrawerCenter`, `number`, `fromOffset`, `Spectate`, `placeLauncher`, `CreatorCameraActive`, `AFKToggle`, `Selectable`, `showLauncher`, `ValleyHUD`, `HostButton`, `StateDot`, `match`, `awayLook`, `Caption`, `Settings`, `HOST`, `panel`, `stroke`, `secondary`, `Rows`, `AutomaticCanvasSize`, `ScrollingDirection`, `ScrollBarThickness`, `scroll`, `List`, `Padding`, `register`, `setAvailable`, `buildHost`, `setLauncherVisible`, `close`, `isOpen`, `Row`, `primary`, `rowLabel`, `Button`, `rowButton`, `upper`, `section`, `Family`, `Regular`, `FontStyle`, `Italic`, `muted`, `NEXT`, `picker`, `Minus`, `Plus`, `stepper`, `OFF`, `danger`, `toggle`, `action`, `submit`, `Input`, `PlaceholderText`, `PlaceholderColor3`, `ClearTextOnFocus`, `fromRGB`, `corner`, `PaddingLeft`, `PaddingRight`, `input`, `FocusLost`, `status`, `PrivateInviteOpen`, `answerWith`, `accept`, `decline`, `PrivateInvite`, `INVITE`, `Line`, `Join`, `JOIN`, `Decline`, `DECLINE`, `fromName`, `invite`, `closeInvite`, `GetService`, `ChickenOrHero`, `Presentation`, `FFlags`, `HudNavigation`, `HudIcons`, `ValleyHudView`, `PrivateHostModel`, `awaitUIVersion`, `OldUIReskin`, `Skin`, `ValleyPanels`, `screen`, `PrivateHost`, `ScreenInsets`, `DeviceSafeInsets`

### `Players.WhitneyHubbard39.PlayerScripts.ProServerClient` (LocalScript)

`Level`, `level`, `unlocked`, `Light`, `Fire`, `Smoke`, `Sparkles`, `effect`, `LocalTransparencyModifier`, `ProEffectOn`, `shown`, `topOf`, `SmallPodium`, `Podium`, `Star`, `Lock`, `Base`, `ProServersPrompt`, `Billboard`, `BillboardAttachment`, `attachment`, `position`, `fromRGB`, `dress`, `ProServersStand`, `Triggered`, `found`, `clock`, `GetFriendsAsync`, `UserId`, `GetCurrentPage`, `IsFinished`, `AdvanceToNextPageAsync`, `loadFriends`, `joining`, `fromScale`, `centred`, `CreatorCaptureExempt`, `Backdrop`, `ImageColor3`, `ImageTransparency`, `Assets`, `Sunray`, `Rays`, `Aspect`, `Emblem`, `UITextSizeConstraint`, `textStroke`, `teleportScreen`, `failed`, `TELEPORTING`, `floor`, `title`, `spinning`, `buttons`, `status`, `screen`, `showTeleport`, `hideTeleport`, `danger`, `failTeleport`, `request`, `ProTeleportGui`, `Leave`, `SetTeleportGui`, `FireServer`, `clearRows`, `Join`, `friendIds`, `Server`, `fromOffset`, `green`, `radius`, `Region`, `region`, `Legendary`, `Where`, `Lobby`, `phase`, `Map`, `textBody`, `players`, `format`, `PlayersLabel`, `PLAYERS`, `textMuted`, `Friends`, `Layout`, `FillDirection`, `VerticalAlignment`, `Padding`, `Horizontal`, `Friend`, `avatar`, `Corner`, `Outline`, `FULL`, `JOIN`, `disabled`, `primary`, `shimmer`, `userIds`, `render`, `List`, `opening`, `ProServers`, `InMatch`, `JoinRandom`, `Reply`, `blocked`, `runUnlock`, `StatsLoaded`, `GetService`, `ChickenOrHero`, `FFlags`, `Game`, `ProServerRemote`, `OldUIReskin`, `Skin`, `Presentation`

### `Players.WhitneyHubbard39.PlayerScripts.PumpkinBombClient` (LocalScript)

`clamp`, `Rate`, `sharePuffs`, `CastShadow`, `NumberSequenceKeypoint`, `RollOffMinDistance`, `RollOffMaxDistance`, `AddItem`, `sound`, `SmoothPlastic`, `fromRGB`, `random`, `Angles`, `chunks`, `Brightness`, `position`, `actorId`, `GetPlayerByUserId`, `PumpkinBomb`, `GameRole`, `PumpkinSmoke`, `ParticleEmitterShape`, `Box`, `Shape`, `ParticleEmitterShapeStyle`, `ShapeStyle`, `Lifetime`, `Speed`, `SpreadAngle`, `RotSpeed`, `Acceleration`, `Drag`, `LightInfluence`, `LightEmission`, `NormalId`, `EmissionDirection`, `ZOffset`, `amount`, `PointLight`, `Range`, `Shadows`, `Height`, `Emit`, `round`, `flourish`, `ground`, `Sounds`, `Burst`, `Hiss`, `smoke`, `workspace`, `radius`, `Radius`, `seconds`, `Duration`, `GetService`, `Debris`, `ChickenOrHero`, `Gear`, `GearCatalog`, `AbilityFlair`, `GearEvent`, `Items`, `ColorSequenceKeypoint`, `IconImage`, `PumpkinBombLocal`, `OnClientEvent`

### `Players.WhitneyHubbard39.PlayerScripts.PumpkinPedestalClient` (LocalScript)

`Live`, `Pot`, `Goal`, `Phase`, `Filling`, `Cooldown`, `fireLook`, `embers`, `light`, `Rate`, `NumberSequenceKeypoint`, `Speed`, `brightness`, `flash`, `Brightness`, `Range`, `dress`, `PumpkinSacrificeOpen`, `InMatch`, `PumpkinsOpen`, `promptShown`, `ProximityPrompt`, `PumpkinsPrompt`, `HoldDuration`, `PromptDistance`, `MaxActivationDistance`, `RequiresLineOfSight`, `KeyboardKeyCode`, `ButtonY`, `GamepadKeyCode`, `UIOffset`, `pumpkinsPrompt`, `Game`, `PumpkinEvent`, `pumpkinsLive`, `pumpkins`, `count`, `ObjectText`, `Open`, `ActionText`, `PumpkinAltarActive`, `pumpkinsShown`, `PumpkinHuntSign`, `Adornee`, `fromScale`, `StudsOffsetWorldSpace`, `MaxDistance`, `LightInfluence`, `AlwaysOnTop`, `fromEnum`, `Creepster`, `upper`, `EventName`, `fromRGB`, `signShown`, `SacrificePrompt`, `promptOf`, `UNAVAILABLE`, `activate`, `PumpkinSacrifice`, `Pumpkins`, `workspace`, `IsDescendantOf`, `Bowl`, `GetFullName`, `PumpkinFire`, `attachment`, `Fire`, `LightEmission`, `Lifetime`, `SpreadAngle`, `RotSpeed`, `Embers`, `Acceleration`, `PumpkinLight`, `PointLight`, `Glow`, `Shadows`, `Triggered`, `setup`, `teardown`, `Amounts`, `floor`, `clamp`, `Emit`, `burst`, `refreshAll`, `Burst`, `UserId`, `GetService`, `CollectionService`, `ChickenOrHero`, `PumpkinHuntConfig`, `Presentation`, `HudNavigation`, `SacrificeScreen`, `PumpkinScreen`, `counted`, `Tag`, `GetInstanceAddedSignal`, `GetInstanceRemovedSignal`, `GetTagged`, `PumpkinHuntEvent`, `AttributeChanged`, `sacrificed`, `OnClientEvent`

### `Players.WhitneyHubbard39.PlayerScripts.PumpkinPeopleClient` (LocalScript)

`RandomPrizePolicy`, `start`, `restricted`, `BindableEvent`, `GetFullName`, `waitFor`, `Sounds`, `random`, `RollOffMinDistance`, `RollOffMaxDistance`, `Ended`, `sound`, `soundAt`, `Animation`, `AnimationId`, `animation`, `GetPlayerByUserId`, `characterOf`, `emitter`, `Highlight`, `FillColor`, `OutlineColor`, `FillTransparency`, `OutlineTransparency`, `HighlightDepthMode`, `Occluded`, `DepthMode`, `Adornee`, `flashModel`, `LightEmission`, `LightInfluence`, `Lifetime`, `Speed`, `SpreadAngle`, `Acceleration`, `NumberSequenceKeypoint`, `Emit`, `burst`, `ClearAllChildren`, `Neon`, `lookAt`, `AnkleBolt`, `PointLight`, `Brightness`, `Range`, `lightning`, `clock`, `workspace`, `Angles`, `refreshOutline`, `tracks`, `IsPlaying`, `Stop`, `stopTracks`, `shellOf`, `placeHead`, `ScaleTo`, `sizeHead`, `faceParts`, `velocity`, `Spherecast`, `Normal`, `Distance`, `ballStep`, `clamp`, `Collect`, `atan2`, `settle`, `fromAxisAngle`, `RaycastParams`, `RaycastFilterType`, `Exclude`, `FilterType`, `ClientBots`, `FilterDescendantsInstances`, `RespectCanCollide`, `rollHead`, `ImageTransparency`, `Head`, `PumpkinCoins`, `fromScale`, `StudsOffsetWorldSpace`, `AlwaysOnTop`, `commas`, `RestrictedCoins`, `fromRGB`, `plusCoins`, `Coins`, `SpecialMesh`, `Drag`, `Coin`, `PartType`, `Cylinder`, `Shape`, `SmoothPlastic`, `Reflectance`, `CastShadow`, `coinBurst`, `model`, `Haunted`, `value`, `KilledBy`, `HitFrom`, `PumpkinHead`, `AnkleBreak`, `Part0`, `Part1`, `HeadPop`, `UserId`, `breakRig`, `Broken`, `Rise`, `risePending`, `Tell`, `Lunge`, `Walk`, `onState`, `Massless`, `HumanoidDisplayDistanceType`, `DisplayDistanceType`

### `Players.WhitneyHubbard39.PlayerScripts.PumpkinSacrificeClient` (LocalScript)

`ChickenOrHero`, `Presentation`, `PumpkinAltar`, `start`

### `Players.WhitneyHubbard39.PlayerScripts.PumpkinsClient` (LocalScript)

`fromOffset`, `ValleyHUD`, `Wallet`, `opening`, `Pumpkins`, `PumpkinsOpen`, `opened`, `closed`, `setOpen`, `InMatch`, `layout`, `available`, `UNAVAILABLE`, `activate`, `close`, `isOpen`, `setAvailable`, `setHidden`, `setCount`, `GetService`, `ChickenOrHero`, `Presentation`, `HudNavigation`, `ValleyPanels`, `PumpkinScreen`, `screen`, `Shade`, `fromScale`, `fromRGB`, `fullscreenShade`, `frame`, `cursorWhileVisible`, `closeButton`, `Corner`, `Ring`, `Count`, `Bob`, `register`, `start`

### `Players.WhitneyHubbard39.PlayerScripts.QuestClient` (LocalScript)

`label`, `connect`, `QUESTS`, `setLabel`, `setImage`, `IconImage`, `modifyTheme`, `refreshQuestIcon`, `notify`, `Fire`, `updateNotice`, `NoticeLabel`, `fromRGB`, `FireServer`, `action`, `Gold`, `GetService`, `GameAudio`, `Debris`, `AddItem`, `celebrate`, `GetProductInfoAsync`, `IsForSale`, `PriceInRobux`, `number`, `clock`, `skipPrice`, `floor`, `format`, `countdown`, `workspace`, `Daily`, `daily`, `resetsAt`, `event`, `phase`, `Upcoming`, `startsAt`, `endsAt`, `spinResetsAt`, `updateTimer`, `clearCards`, `lookAt`, `Weapons`, `Blade`, `WeaponPreview`, `fromScale`, `Display`, `Knife`, `PreviewRotation`, `identity`, `JointInstance`, `PreviewCamera`, `preview`, `TextBounds`, `clamp`, `fromOffset`, `place`, `ClaimDaily`, `corner`, `stroke`, `claimed`, `complete`, `Blue`, `green`, `Spin`, `rewardAmount`, `rewardCurrency`, `candyCorn`, `journeyXp`, `Gem`, `Reward`, `progress`, `target`, `Progress`, `NewIn`, `ProgressTrack`, `CLAIMED`, `CLAIM`, `Claim`, `loaded`, `primary`, `secondary`, `dailyCard`, `Refresh`, `PromptRefresh`, `PromptAutoComplete`, `UNAVAILABLE`, `robux`, `productButton`, `quests`, `refreshProductId`, `autoCompleteProductId`, `AutoComplete`, `dailyProducts`, `RedeemSkipCredit`, `PromptSkip`, `ClaimEvent`, `SelectedWeapon`, `claimable`, `UNLOCKED`, `locked`, `LOCKED`, `bonus`, `Amount`, `upper`, `Currency`, `Bonus`, `Quest`, `alternateTarget`, `alternateProgress`, `Count`, `QuestTrack`, `OWNED`, `skipProductId`, `skipCredits`, `claimsEnabled`, `SkipQuests`, `eventDetail`, `weapons`

### `Players.WhitneyHubbard39.PlayerScripts.QuestTrackerClient` (LocalScript)

`allowed`, `textStroke`, `GetProductInfoAsync`, `IsForSale`, `PriceInRobux`, `number`, `refresh`, `priceOf`, `daily`, `Refresh`, `refreshProductId`, `autoCompleteProductId`, `AutoComplete`, `quests`, `complete`, `claimed`, `robux`, `secondary`, `PromptRefresh`, `PromptAutoComplete`, `FireServer`, `fromOffset`, `productButton`, `UserId`, `Get`, `claimable`, `clock`, `reward`, `ClaimDaily`, `target`, `count`, `format`, `floor`, `Quest`, `Tick`, `greenDark`, `fromScale`, `Count`, `textSecondary`, `track`, `Reward`, `RewardIcon`, `RewardWheel`, `ImageColor3`, `fromHex`, `NumberValue`, `Claim`, `frame`, `title`, `wheel`, `tickScale`, `value`, `press`, `Claimed`, `rewardAmount`, `rewardCurrency`, `coins`, `spins`, `candyCorn`, `journeyXp`, `rewardText`, `textMuted`, `runner`, `xpLight`, `rewardColor`, `Icons`, `journey`, `rewardIcon`, `duration`, `Spin`, `ordered`, `resetsAt`, `refreshTimer`, `progress`, `green`, `radius`, `Value`, `Time`, `Interactable`, `setOpen`, `QuestTrackerClosed`, `QuestTrackerHidden`, `reveal`, `putAway`, `KeyboardEnabled`, `place`, `Updates`, `anchorTo`, `ValleyHUD`, `Toast`, `message`, `serverNow`, `loaded`, `Daily`, `InMatch`, `GetService`, `ChickenOrHero`, `Quests`, `QuestEvent`, `OldUIReskin`, `Skin`, `Presentation`, `ValleyToast`, `Game`, `CandyCorn`, `ffff00`, `Quint`, `TutorialActive`, `TutorialSession`, `TutorialRouting`, `TutorialFinishing`, `QuestTracker`, `ScreenInsets`, `DeviceSafeInsets`, `ZIndexBehavior`, `Sibling`, `Holder`, `Panel`, `surface`, `panel`

### `Players.WhitneyHubbard39.PlayerScripts.RainingTokensClient` (LocalScript)

`RainingTokens`, `Glints`, `fromRGB`, `LightEmission`, `NumberSequenceKeypoint`, `Lifetime`, `Speed`, `SpreadAngle`, `Rate`, `Clink`, `RollOffMaxDistance`, `attachment`, `sound`, `workspace`, `ensureFolder`, `clock`, `WorldPosition`, `clink`, `Emit`, `sparkle`, `remove`, `CastShadow`, `owner`, `count`, `release`, `character`, `FilterDescendantsInstances`, `position`, `velocity`, `angle`, `floor`, `bounces`, `squash`, `handOf`, `ensureLoop`, `EmoteId`, `nextRain`, `started`, `phase`, `restFrom`, `Angles`, `BulkMoveMode`, `FireCFrameChanged`, `BulkMoveTo`, `RightHand`, `EmoteStartedAt`, `check`, `watch`, `track`, `GetService`, `ChickenOrHero`, `Emotes`, `Assets`, `RainingToken`, `RaycastParams`, `RaycastFilterType`, `Exclude`, `FilterType`

### `Players.WhitneyHubbard39.PlayerScripts.RankedClient` (LocalScript)

`fromScale`, `AspectRatio`, `fromOffset`, `setSize`, `visible`, `ValleyHUD`, `Updates`, `QuestTracker`, `Holder`, `Tab`, `Panel`, `place`, `unwatch`, `watch`, `Ranked`, `RankedEndEvent`, `number`, `EndEventRounds`, `format`, `RANKED`, `refresh`, `UITextSizeConstraint`, `MinTextSize`, `workspace`, `ViewportSize`, `clamp`, `ServerCountryCode`, `ServerSubdivision`, `GetService`, `IsStudio`, `STUDIO`, `serverPlace`, `GetNetworkPing`, `round`, `upper`, `fromRGB`, `RankTier`, `Tiers`, `TierIcons`, `Entry`, `ChampionIcon`, `RankChampion`, `Phase`, `MapVote`, `Countdown`, `RankedNext`, `EndsAt`, `check`, `plain`, `RankedRefreshAt`, `RankedRefreshOn`, `ChickenOrHero`, `Game`, `RankedConfig`, `LoadoutEnabled`, `wipeIn`, `FFlags`, `RankedBadge`, `Pill`, `KeyboardEnabled`, `DominantAxis`, `Height`, `Contextual`, `Heavy`, `RankedIntro`, `Card`, `Tier`, `Rank`, `Net`, `RankedWipe`, `Cover`, `Sub`

### `Players.WhitneyHubbard39.PlayerScripts.RankedLoadoutClient` (LocalScript)

`levels`, `forActor`, `GetService`, `Cooldown`, `cooldownOf`, `connect`, `fromOffset`, `TextStroke`, `Contextual`, `label`, `corner`, `image`, `GetGuiInset`, `HUD`, `MainFrame`, `BarMainFrame`, `rowTop`, `placeOpener`, `Item`, `Items`, `Uses`, `Abilities`, `slotCost`, `clock`, `refuse`, `RankedLoadoutOpen`, `clone`, `clean`, `Credits`, `format`, `Set`, `FireServer`, `change`, `picked`, `option`, `IconImage`, `Coin`, `Cost`, `Glyph`, `NONE`, `MouseEnter`, `optionCard`, `Minus`, `secondary`, `Value`, `Plus`, `stepper`, `MaxUses`, `clamp`, `ClientReady`, `InMatch`, `lobby`, `blocked`, `available`, `dimmed`, `green`, `textSecondary`, `title`, `accent`, `danger`, `Kind`, `Preview`, `Description`, `Phase`, `EndsAt`, `number`, `workspace`, `LOCKED`, `Countdown`, `RankedLoadout`, `RankedReady`, `RankedReadyNeed`, `SelectedObject`, `IsDescendantOf`, `opening`, `Get`, `Ready`, `ButtonB`, `ButtonL1`, `ButtonR1`, `loadout`, `locked`, `ready`, `READY`, `message`, `RankedPickId`, `autoOpen`, `ChickenOrHero`, `Game`, `RankedConfig`, `LoadoutEnabled`, `FFlags`, `Ranked`, `Gear`, `GearCatalog`, `AbilityLevels`, `OldUIReskin`, `Skin`, `Presentation`, `HudNavigation`, `EquipmentHudLayoutLegacy`, `RankedLoadoutEvent`, `Loadout`, `Assets`, `fromRGB`, `ITEM`, `screen`, `Open`, `primary`, `panel`, `Panel`, `ClipsDescendants`, `Eyebrow`, `RANKED`, `LOADOUT`, `Shine`, `Sub`, `Timer`, `LeftCaption`, `Ability`

### `Players.WhitneyHubbard39.PlayerScripts.RankedMenuClient` (LocalScript)

`nunito`, `round`, `sizeFor`, `parse`, `RankedRegions`, `picks`, `floor`, `comma`, `format`, `clock`, `DateTime`, `fromUnixTimestamp`, `FormatLocalTime`, `localTime`, `endsAt`, `seasonEnds`, `season`, `seasonId`, `ordinal`, `signed`, `corner`, `stroke`, `authored`, `fromOffset`, `image`, `PhoneSize`, `UITextSizeConstraint`, `MinTextSize`, `fixed`, `resize`, `black`, `ClipsDescendants`, `fromScale`, `number`, `Ring`, `Mark`, `markFrame`, `xMark`, `clockMark`, `globeMark`, `Tile`, `Glyph`, `muted`, `Value`, `Delta`, `green`, `value`, `delta`, `statTile`, `PaddingLeft`, `TextBounds`, `place`, `CurrencyIcon`, `IconPad`, `currencyIcon`, `currency`, `gradientsOf`, `width`, `RankedWidth`, `Practice`, `Column`, `placePill`, `workspace`, `serverNow`, `Level`, `level`, `placing`, `MinLevel`, `unranked`, `seasonName`, `numbered`, `DAY`, `DAYS`, `HRS`, `MIN`, `MMM`, `upper`, `renderHeader`, `frame`, `label`, `faint`, `downBg`, `downFg`, `paintRecent`, `lastMatch`, `points`, `change`, `minus`, `entry`, `leaver`, `renderLast`, `color`, `TierIcons`, `division`, `divisionName`, `RankChampion`, `Tiers`, `Divisions`, `ChampionTop`, `clamp`, `guard`, `shield`, `history`, `TierRewards`, `Coins`, `renderRanked`, `placed`, `Placements`, `renderLocked`, `peakBg`, `status`, `ImageTransparency`, `renderRewards`, `renderRank`, `GLOBAL`, `describe`, `NEARBY`, `nearby`, `regionCounts`, `bit32`

### `Players.WhitneyHubbard39.PlayerScripts.RankedPodiumClient` (LocalScript)

`workspace`, `Lobby`, `RankedArea`, `Podium`, `Step1`, `Step2`, `Step3`, `findPodium`, `Panel1`, `Num1`, `front`, `token`, `label`, `userId`, `clearSpot`, `spots`, `folder`, `podium`, `clearAll`, `topOf`, `fromScale`, `RankedPodiumLabel`, `LightInfluence`, `MaxDistance`, `Who`, `Tier`, `Adornee`, `StudsOffsetWorldSpace`, `labelFor`, `GetHumanoidDescriptionFromUserIdAsync`, `CreateHumanoidModelFromDescriptionAsync`, `HumanoidRigType`, `IsDescendantOf`, `RankedPodiumFigure`, `Massless`, `HumanoidDisplayDistanceType`, `DisplayDistanceType`, `HumanoidHealthDisplayType`, `AlwaysOff`, `HealthDisplayType`, `BreakJointsOnDeath`, `EvaluateStateMachine`, `lookAt`, `Animator`, `Animation`, `AnimationId`, `LoadAnimation`, `buildRig`, `board`, `entries`, `Step`, `upper`, `format`, `Backdrop`, `season`, `paint`, `JSONDecode`, `GetService`, `FFlags`, `Ranked`, `ChickenOrHero`, `Game`, `fromRGB`, `Heavy`, `RankedBoard`, `Value`, `RankedPodiumLocal`

### `Players.WhitneyHubbard39.PlayerScripts.ReadableTextClient` (LocalScript)

`ProximityPrompts`, `ProximityPromptUI`, `proximityPresentation`, `FindFirstAncestorWhichIsA`, `ScreenOverlay`, `TeleportOverlay`, `Notifications`, `NotificationsF`, `FindFirstAncestor`, `loadingPresentation`, `ValleyArmory`, `Tabs`, `shopTab`, `workspace`, `ViewportSize`, `largeScreen`, `updating`, `UpdatesShade`, `HitboxComparison`, `HitReplayStatus`, `IsDescendantOf`, `authored`, `round`, `clamp`, `appliedSize`, `resize`, `forget`, `ReadableAuthoredSize`, `UITextSizeConstraint`, `apply`, `refresh`, `cameraChanged`, `GetService`, `DescendantRemoving`

### `Players.WhitneyHubbard39.PlayerScripts.RescueClient` (LocalScript)

`HoldSeconds`, `VowReviveExtra`, `holdFor`, `FireServer`, `fromScale`, `cancel`, `character`, `started`, `UserId`, `clock`, `begin`, `ButtonX`, `Cancelled`, `Ragdolled`, `EvaluateStateMachine`, `HumanoidStateType`, `GettingUp`, `SetStateEnabled`, `PlatformStand`, `Physics`, `ChangeState`, `update`, `GetStateEnabled`, `characterAdded`, `GlobalPaused`, `GameRole`, `Caught`, `VowMarked`, `RescueHelperId`, `RescueAvailable`, `reason`, `MovementLocked`, `Range`, `RaycastParams`, `RaycastFilterType`, `Exclude`, `FilterType`, `FilterDescendantsInstances`, `RespectCanCollide`, `CoHRunner`, `CollisionGroup`, `workspace`, `player`, `format`, `clamp`, `Finish`, `FinishGrace`, `destroy`, `GetService`, `ChickenOrHero`, `Game`, `RescueConfig`, `RescueEvent`, `Presentation`, `ParticipantDirectory`, `VerifiedName`, `Movement`, `ControlGate`, `RescueStatus`, `fromRGB`, `UITextSizeConstraint`, `MinTextSize`, `NearbyRescue`, `UISizeConstraint`, `MinSize`, `MaxSize`, `Hold`, `ReviveMarkers`, `OnClientEvent`

### `Players.WhitneyHubbard39.PlayerScripts.ReviveOfferClient` (LocalScript)

`below`, `ReviveOfferOpen`, `Holder`, `close`, `Offer`, `productId`, `PriceInRobux`, `number`, `price`, `Price`, `Buy`, `Off`, `Prices`, `paint`, `Bought`, `Pop`, `bought`, `PromptProductPurchase`, `Caught`, `clone`, `ReviveOffer`, `GamepadEnabled`, `KeyboardEnabled`, `SelectedObject`, `hideAt`, `workspace`, `Show`, `UserId`, `GetService`, `ChickenOrHero`, `Presentation`, `AuthoredScreens`, `Interface`, `ProductPrices`, `Game`, `ReviveOfferEvent`, `OnClientEvent`, `PromptProductPurchaseFinished`

### `Players.WhitneyHubbard39.PlayerScripts.RoleMarkerVisibility` (LocalScript)

`Cloaked`, `Ghosted`, `hidden`, `concealed`, `LightsOutDark`, `LightsOutSpotted`, `apply`, `refreshBody`, `Smoked`, `watchBody`, `RoleMarker`, `track`, `watch`, `watchPlayer`, `watchRigs`, `ClientBots`, `GetService`, `__mode`, `ChickenOrHero`, `Gear`, `PumpkinSmoke`, `workspace`, `GameRole`

### `Players.WhitneyHubbard39.PlayerScripts.SacrificeBoardsClient` (LocalScript)

`format`, `reverse`, `floor`, `numberText`, `status`, `studio`, `retrying`, `loading`, `statusText`, `GetUserThumbnailAsync`, `userId`, `ThumbnailType`, `HeadShot`, `ThumbnailSize`, `Size100x100`, `generation`, `PFP`, `MainFrame`, `entries`, `value`, `number`, `template`, `Rank_`, `Username`, `verified`, `Stat`, `COINS`, `paint`, `boards`, `paintAll`, `JSONDecode`, `Value`, `JSONEncode`, `workspace`, `SacrificeBoards`, `worldFolder`, `SacrificeBoardLeft`, `SacrificeBoardRight`, `SacrificeBoard_`, `Adornee`, `SlotFrame`, `Dust`, `CastShadow`, `LightInfluence`, `Rate`, `ParticleEmitterShape`, `Box`, `Shape`, `ParticleEmitterShapeStyle`, `ShapeStyle`, `NormalId`, `EmissionDirection`, `Lifetime`, `Speed`, `SpreadAngle`, `Drag`, `Acceleration`, `RotSpeed`, `NumberSequenceKeypoint`, `shown`, `hover`, `makeBoard`, `model`, `WorldPosition`, `depth`, `lookAt`, `layout`, `IsDescendantOf`, `bases`, `fadeBoard`, `shownKey`, `setVisible`, `SacrificeBoardsRumble`, `Rumble`, `Attribute`, `RollOffMinDistance`, `RollOffMaxDistance`, `rumbleSource`, `sounds`, `tweens`, `rumbles`, `makeRumble`, `Bowl`, `Presentation`, `SacrificeBoard`, `progress`, `restore`, `nextDust`, `broke`, `__mode`, `setup`, `teardown`, `Rubble`, `Slate`, `Angles`, `position`, `velocity`, `angle`, `chunk`, `Emit`, `burst`, `quiet`, `volume`, `rumble`, `Stop`, `IsPlaying`, `settle`, `InMatch`, `blocked`, `PumpkinSacrificeOpen`, `altarOpen`, `clock`, `distance`, `clamp`, `rising`, `facing`, `sinking`, `fading`, `identity`, `noise`

### `Players.WhitneyHubbard39.PlayerScripts.SafezoneSignsClient` (LocalScript)

`isSign`, `untrack`, `Map3Signs`, `refresh`, `Field`, `track`, `Map3`, `GetService`, `SafezoneASide`, `SafezoneBSide`, `__mode`, `workspace`

### `Players.WhitneyHubbard39.PlayerScripts.SeesawClient` (LocalScript)

`workspace`, `IsDescendantOf`, `connection`, `Main`, `Seesaw`, `VectorToWorldSpace`, `along`, `hinge`, `width`, `angle`, `since`, `fromAxisAngle`, `AncestryChanged`, `track`, `clock`, `GetService`

### `Players.WhitneyHubbard39.PlayerScripts.ServerBrowserClient` (LocalScript)

`layout`, `GetNetworkPing`, `floor`, `Connection`, `Ping`, `updatePing`, `clearRows`, `status`, `current`, `averagePing`, `players`, `ServerBrowserTransferring`, `Join`, `FireServer`, `SelectedObject`, `List`, `IsDescendantOf`, `location`, `countryCode`, `UNKNOWN`, `updatedAt`, `ALL`, `Empty`, `Count`, `format`, `SERVER`, `SERVERS`, `clamp`, `PageLabel`, `PreviousPage`, `NextPage`, `Selectable`, `Templates`, `ServerRow`, `Server_`, `country`, `Details`, `capacity`, `phase`, `subdivision`, `Region`, `region`, `HERE`, `FULL`, `JOIN`, `studio`, `styleRow`, `render`, `styleCountry`, `CanvasPosition`, `Countries`, `Country_`, `renderCountries`, `Refresh`, `REFRESH`, `clock`, `request`, `workspace`, `ServerBrowserAvailable`, `ClientReady`, `InMatch`, `Lobby`, `GameRole`, `TutorialSession`, `TutorialRouting`, `ScreenPresentationActive`, `AdminRefreshActive`, `permitted`, `opening`, `Servers`, `ServerBrowserOpen`, `Shade`, `GamepadEnabled`, `setOpen`, `Open`, `setAvailable`, `availability`, `changePage`, `Sort`, `ButtonB`, `joinReason`, `Joining`, `message`, `JoinResult`, `Error`, `ChickenOrHero`, `Presentation`, `HudNavigation`, `GetService`, `ServerBrowser`, `ServerBrowserShade`, `Panel`, `ServerBrowserView`, `apply`, `KeyboardEnabled`, `ServerBrowserEvent`, `register`, `OnClientEvent`

### `Players.WhitneyHubbard39.PlayerScripts.SettingsSyncClient` (LocalScript)

`ChickenOrHero`, `Presentation`, `SettingsSync`, `start`

### `Players.WhitneyHubbard39.PlayerScripts.SkateSpinClient` (LocalScript)

`number`, `GetPlayerByUserId`, `workspace`, `ClientBots`, `BotUserId`, `bodyOf`, `RollOffMinDistance`, `RollOffMaxDistance`, `AddItem`, `sound`, `AnimationController`, `Animator`, `LoadAnimation`, `AnimationPriority`, `Action4`, `Priority`, `AncestryChanged`, `playClip`, `Blade`, `Handle`, `BladeWeld`, `GripC1`, `SpinSkate`, `SurfaceAppearance`, `Massless`, `Part0`, `Part1`, `holdSkates`, `Emotes`, `Assets`, `TripleAxel`, `IceSpray`, `SpinSpray`, `fromRGB`, `Lifetime`, `Speed`, `SpreadAngle`, `Rate`, `spray`, `clamp`, `lerpColor`, `paletteFor`, `powerFor`, `source`, `NumberSequenceKeypoint`, `Spin_`, `TimeScale`, `LightInfluence`, `Acceleration`, `Drag`, `LockedToPart`, `emitter`, `attachments`, `attach`, `floor`, `beams`, `emitters`, `started`, `nextSlash`, `pulses`, `level`, `power`, `palette`, `radius`, `maxPulses`, `slashGap`, `slashCount`, `clock`, `SpinFxCore`, `SpinFxFeet`, `slash`, `LightEmission`, `Brightness`, `ZOffset`, `frost`, `EmissionDirection`, `NormalId`, `glint`, `RotSpeed`, `shock`, `Orientation`, `ParticleOrientation`, `VelocityPerpendicular`, `shards`, `Emit`, `PointLight`, `SpinIceLight`, `Range`, `Shadows`, `light`, `SpinFxRing`, `skates`, `parts`, `Attachment0`, `Attachment1`, `MinLength`, `FaceCamera`, `WidthScale`, `SpinBeamLow`, `SpinBeamHigh`, `TextureMode`, `Wrap`, `TextureLength`, `TextureSpeed`, `Width0`, `Width1`, `CurveSize0`, `CurveSize1`, `Segments`, `phase`, `iceFx`, `sideFrom`, `sided`, `iceStep`, `iceEnd`, `EquippedDagger`, `LocalTransparencyModifier`, `effects`, `hideKnife`, `track`

### `Players.WhitneyHubbard39.PlayerScripts.SlapstickClient` (LocalScript)

`number`, `GetPlayerByUserId`, `workspace`, `ClientBots`, `BotUserId`, `bodyOf`, `RollOffMinDistance`, `RollOffMaxDistance`, `AddItem`, `sound`, `LightEmission`, `Lifetime`, `Speed`, `SpreadAngle`, `NormalId`, `EmissionDirection`, `Acceleration`, `Rate`, `Emit`, `frost`, `EquippedDagger`, `Blade`, `Puck`, `LocalTransparencyModifier`, `hideStickPuck`, `clock`, `floor`, `finish`, `floorY`, `expires`, `flight`, `speed`, `range`, `origin`, `direction`, `clamp`, `Angles`, `started`, `Weapons`, `HockeyStick`, `JointInstance`, `Massless`, `Attachment0`, `Attachment1`, `newPuck`, `AnimationController`, `Animator`, `LoadAnimation`, `AnimationPriority`, `Action4`, `Priority`, `AncestryChanged`, `playClip`, `ContentProvider`, `GetService`, `PreloadAsync`, `Sounds`, `preload`, `CatcherAbility`, `Slapstick`, `watch`, `character`, `actorId`, `Windup`, `PointToObjectSpace`, `RaycastParams`, `RaycastFilterType`, `Exclude`, `FilterType`, `FilterDescendantsInstances`, `trail`, `windup`, `SlapstickLaunch`, `position`, `Range`, `Slap`, `SlapstickHit`, `Hit`, `SlapstickEnd`, `Debris`, `ChickenOrHero`, `Gear`, `GearCatalog`, `GearEvent`, `Items`, `fromRGB`, `Animation`, `AnimationId`, `OnClientEvent`

### `Players.WhitneyHubbard39.PlayerScripts.SnowFlurryClient` (LocalScript)

`NumberSequenceKeypoint`, `sequence`, `attachment`, `workspace`, `Cloaked`, `Ghosted`, `GameRole`, `MaxSpeed`, `clamp`, `flakes`, `Rate`, `angle`, `SnowFlurry`, `Flakes`, `fromRGB`, `LightEmission`, `Lifetime`, `Speed`, `SpreadAngle`, `RotSpeed`, `Acceleration`, `Drag`, `Mist`, `random`, `IceSkates`, `SnowFlurryHidden`, `refresh`, `watch`, `GetService`, `ChickenOrHero`, `FFlags`, `IceSkating`, `Movement`, `MovementProfiles`

### `Players.WhitneyHubbard39.PlayerScripts.SoulReapClient` (LocalScript)

`GetService`, `GetPlayerByUserId`, `SoulReap`, `reaperFlair`, `forActor`, `Range`, `myRange`, `abilities`, `equippedForRole`, `StudioTestAbility`, `isReaper`, `workspace`, `serverNow`, `number`, `ClientBots`, `BotUserId`, `characterOf`, `rootOf`, `IsPlaying`, `RollOffMode`, `InverseTapered`, `RollOffMaxDistance`, `IsLoaded`, `Loaded`, `sound`, `FFlags`, `awaitUIVersion`, `NewGui`, `Interface`, `Toasts`, `Presentation`, `ValleyToast`, `RigidConstraint`, `droppable`, `Torso`, `Head`, `SpecialMesh`, `MeshType`, `Part0`, `Part1`, `blankRig`, `JointInstance`, `rejoin`, `Attachment0`, `Attachment1`, `IsDescendantOf`, `remove`, `repose`, `UpperTorso`, `weldLoose`, `Archivable`, `SoulGhost`, `CastShadow`, `Massless`, `LocalTransparencyModifier`, `identity`, `Transform`, `HumanoidDisplayDistanceType`, `DisplayDistanceType`, `HumanoidHealthDisplayType`, `AlwaysOff`, `HealthDisplayType`, `BreakJointsOnDeath`, `RequiresNeck`, `PlatformStand`, `Animator`, `Highlight`, `SoulGlow`, `FillColor`, `FillTransparency`, `OutlineColor`, `OutlineTransparency`, `HighlightDepthMode`, `Occluded`, `DepthMode`, `ToEulerAnglesYXZ`, `Angles`, `PointLight`, `Brightness`, `Shadows`, `LightEmission`, `LightInfluence`, `NumberSequenceKeypoint`, `Lifetime`, `Speed`, `SpreadAngle`, `Acceleration`, `Rate`, `ghostFrom`, `buildGhost`, `LoadAnimation`, `Animation`, `AnimationId`, `fadeIn`, `clock`, `ScaleTo`, `GetScale`, `fadeOut`, `Drag`, `Emit`, `burst`, `config`, `Victim`, `Body`, `model`, `blank`, `FloatAnimation`, `track`, `dress`, `shade`, `drift`, `phase`, `nextDress`, `random`, `addSoul`, `stream`, `SoulStream`, `SoulStreamEnd`, `Width0`, `Width1`

### `Players.WhitneyHubbard39.PlayerScripts.SpectateClient` (LocalScript)

`number`, `resolve`, `characterOf`, `connect`, `lobby`, `SpectateAvailable`, `MapChanging`, `ClientReady`, `InMatch`, `Lobby`, `GameRole`, `TutorialSession`, `TutorialRouting`, `ScreenPresentationActive`, `AdminTransferring`, `ServerBrowserTransferring`, `eligible`, `menuOpen`, `GetLastInputType`, `render`, `hintButton`, `setAvailable`, `Spectate`, `TouchGui`, `touchEnabled`, `touchControls`, `Stop`, `FireServer`, `CreatorCameraActive`, `Spectating`, `SpectateMode`, `workspace`, `subject`, `CameraSubject`, `cameraType`, `CameraType`, `Custom`, `focus`, `Focus`, `mouse`, `MouseBehavior`, `MouseIconEnabled`, `setFocus`, `Previous`, `Next`, `Toggle`, `Free`, `Follow`, `action`, `opening`, `Start`, `startWatching`, `Fire`, `CreatorCamera`, `CreatorStart`, `SpectatorStreamingFoci`, `ClientBots`, `clock`, `refreshIgnore`, `position`, `RequestStreamAroundAsync`, `Bounds`, `valid`, `Target`, `creator`, `lookAt`, `clamp`, `CreatorFOV`, `token`, `Scriptable`, `resetPosition`, `label`, `character`, `index`, `total`, `format`, `verified`, `StreamingEnabled`, `UserId`, `sample`, `FootballCutsceneActive`, `CreatorCameraSpeed`, `speedScale`, `alpha`, `LockCurrentPosition`, `Default`, `FocusInterval`, `ValleySpectate`, `UnbindFromRenderStep`, `destroy`, `ChickenOrHero`, `Presentation`, `HudNavigation`, `GetService`, `Game`, `SpectateConfig`, `VerifiedName`, `CreatorPolicy`, `SpectateGeometry`, `SpectateCamera`, `SpectateView`, `SpectateInput`, `ParticipantDirectory`, `FFlags`, `Bots`, `BotDirectory`, `SpectateEvent`, `MapVoteOpen`, `JourneyOpen`, `ArmoryOpen`, `BalloonOfferOpen`, `ServerBrowserOpen`, `FairPlayNoticeOpen`, `ChoiceSpotlightActive`, `AdminConsoleActive`, `SettingsOpen`, `UpdateLogOpen`, `register`, `follow`, `zoomIn`

### `Players.WhitneyHubbard39.PlayerScripts.SpectateLoadoutClient` (LocalScript)

`workspace`, `ViewportSize`, `screen`, `ValleySpectate`, `Controls`, `ControlHint`, `floor`, `number`, `count`, `Avatar`, `Bot`, `Level`, `Wins`, `Catches`, `Knife`, `Ability`, `Emote`, `Owned`, `Offer`, `Bundle`, `clean`, `Spectating`, `SpectateMode`, `Follow`, `following`, `CreatorCameraActive`, `CreatorUIHidden`, `CutsceneActive`, `FootballCutsceneActive`, `PirateCutsceneActive`, `HoverCutsceneActive`, `InMatch`, `blocked`, `shown`, `current`, `update`, `refresh`, `Target`, `loadout`, `Free`, `Stop`, `layout`, `relayout`, `watchBar`, `GetService`, `FFlags`, `SpectateLoadout`, `ChickenOrHero`, `Presentation`, `CaughtLoadoutCard`, `SpectateEvent`, `ZIndexBehavior`, `Sibling`, `UIProportionalExclude`, `OnClientEvent`

### `Players.WhitneyHubbard39.PlayerScripts.SpikeClient` (LocalScript)

`number`, `GetPlayerByUserId`, `workspace`, `ClientBots`, `BotUserId`, `bodyOf`, `RollOffMinDistance`, `RollOffMaxDistance`, `AddItem`, `sound`, `EquippedDagger`, `LocalTransparencyModifier`, `hideKnife`, `clock`, `finish`, `origin`, `direction`, `swept`, `targetRole`, `GameRole`, `reported`, `UserId`, `OverlapParams`, `RaycastFilterType`, `Include`, `FilterType`, `FilterDescendantsInstances`, `forActor`, `Spike`, `HitWidth`, `lookAt`, `GetPartBoundsInBox`, `SpikeHitReport`, `FireServer`, `sweep`, `expires`, `flight`, `speed`, `range`, `clamp`, `Angles`, `started`, `floor`, `aimSent`, `SpikeAim`, `Gear`, `Assets`, `Attachment0`, `Attachment1`, `Lifetime`, `fromRGB`, `LightEmission`, `FaceCamera`, `newBall`, `AnimationController`, `Animator`, `LoadAnimation`, `AnimationPriority`, `Action4`, `Priority`, `AncestryChanged`, `playClip`, `ContentProvider`, `GetService`, `PreloadAsync`, `Sounds`, `preload`, `EquippedKnife`, `Volleyball`, `watch`, `character`, `actorId`, `Toss`, `windup`, `Windup`, `SpikeLaunch`, `position`, `Speed`, `Range`, `SpikeHit`, `Hit`, `SpreadAngle`, `Rate`, `Emit`, `SpikeEnd`, `ClientReady`, `InMatch`, `PracticeActive`, `GlobalPaused`, `MapChanging`, `knifeBlocked`, `available`, `reason`, `KnifeSpikeReadyAt`, `KnifeSpike`, `spike`, `ButtonL1`, `touchStack`, `factor`, `fromOffset`, `right`, `format`, `SPIKE`, `RECHARGING`, `GamepadEnabled`, `fromScale`, `Debris`, `ChickenOrHero`, `GearCatalog`, `GearEvent`, `Items`, `Animation`, `AnimationId`, `AbilityLevels`, `OnClientEvent`, `OldUIReskin`, `Skin`, `Theme`, `Movement`, `ControlGate`

### `Players.WhitneyHubbard39.PlayerScripts.SpinWheelTopbarClient` (LocalScript)

`SpinWheel`, `OpenRequest`, `BindableEvent`, `Fire`, `InMatch`, `setEnabled`, `refresh`, `fromRGB`, `NoticeLabel`, `badge`, `WheelSpins`, `floor`, `totalNotices`, `noticeChanged`, `spins`, `destroy`, `GetService`, `PlayerScripts`, `TopbarPlus`, `ValleySpinWheel`, `setName`, `align`, `setOrder`, `setImage`, `oneClick`, `setLabel`, `setImageScale`, `selected`, `Elements`

### `Players.WhitneyHubbard39.PlayerScripts.StarterPackClient` (LocalScript)

`connect`, `fitOffer`, `adopt`, `fromOffset`, `TextStroke`, `Contextual`, `label`, `popIn`, `ClientReady`, `InMatch`, `lobby`, `starterOfferEndsAt`, `workspace`, `remaining`, `Release`, `FireServer`, `StarterPackOpen`, `SelectedObject`, `IsDescendantOf`, `floor`, `format`, `starterFirstMatch`, `starterPurchased`, `Hold`, `PriceInRobux`, `number`, `loaded`, `IsForSale`, `robux`, `secondary`, `green`, `danger`, `textSecondary`, `render`, `fetch`, `ProductId`, `opening`, `Presented`, `Get`, `Prompt`, `UserId`, `Weapons`, `ArmoryEvent`, `ButtonB`, `GameId`, `UniverseId`, `starterPresented`, `clamp`, `touchStack`, `bottom`, `GetService`, `ChickenOrHero`, `Interface`, `ProductPrices`, `Gear`, `StarterPackConfig`, `OldUIReskin`, `Skin`, `Presentation`, `AuthoredScreens`, `HudNavigation`, `EquipmentHudLayoutLegacy`, `StarterPackEvent`, `screen`, `Open`, `SunRays`, `fromScale`, `Glow`, `Gold`, `Fade`, `NumberSequenceKeypoint`, `PackIcon`, `Timer`, `TimerStroke`, `GearCatalog`, `BananaPeel`, `RescueKit`, `Adrenaline`, `panel`, `Offer`, `ClipsDescendants`, `Eyebrow`, `Shine`, `Description`, `amount`, `accent`, `IconImage`, `AmountEach`, `COINS`, `Assets`, `Coin`, `Coins`, `Card`, `corner`, `Pop`, `Amount`, `ItemName`, `StatusPill`, `Buy`, `fromRGB`, `ArmoryOpen`, `JourneyOpen`, `EmoteWheelOpen`, `SettingsOpen`, `UpdateLogOpen`, `ServerBrowserOpen`, `LikeRewardOpen`, `MapVoteOpen`, `MatchSummaryVisible`, `AdminConsoleActive`, `ScreenPresentationActive`, `TutorialRouting`, `TutorialActive`, `TutorialFinishing`, `TutorialSession`, `EventRsvpOpen`, `OnClientEvent`, `PromptProductPurchaseFinished`

### `Players.WhitneyHubbard39.PlayerScripts.StudioAbilityTestClient` (LocalScript)

`MoveDirection`, `workspace`, `dashDirection`, `StudioEquipAbility`, `FireServer`, `request`, `StudioUseItem`, `StudioTestAbility`, `InMatch`, `UseAbility`, `StudioUseAbility`, `StudioResetAbility`, `StudioClearAbility`, `GameRole`, `AbilityReadyAt`, `fromRGB`, `GlobalPaused`, `MapChanging`, `Interactable`, `UseRole`, `RUNNER`, `CHASER`, `format`, `GetService`, `IsStudio`, `PlaceId`, `ChickenOrHero`, `Gear`, `GearCatalog`, `Presentation`, `ValleyPanels`, `GearEvent`, `GearPredictionClient`, `Game`, `screen`, `StudioAbilityTests`, `TestOnlyUI`, `TestUIHidden`, `Toggle`, `Panel`, `fromOffset`, `cursorWhileVisible`, `corner`, `stroke`, `Gold`, `Order`, `Kind`, `Ability`, `Use`, `Reset`, `Clear`, `ItemsHeading`, `BananaPeel`, `RescueKit`, `Adrenaline`, `BANANA`, `ADRENALINE`, `ItemHelp`, `OnClientEvent`

### `Players.WhitneyHubbard39.PlayerScripts.StudioEmotePreviewClient` (LocalScript)

`connect`, `rarity`, `Special`, `neutral`, `rarityOf`, `secondary`, `textStroke`, `cardLabel`, `fromOffset`, `corner`, `outline`, `badge`, `soundId`, `assetId`, `foreign`, `concat`, `marks`, `InMatch`, `clock`, `TestPlay`, `FireServer`, `match`, `GetProductInfoAsync`, `Asset`, `Creator`, `CreatorTargetId`, `CreatorId`, `AssetTypeId`, `AssetType`, `Animation`, `Value`, `playing`, `showPlaying`, `Stop`, `Stopped`, `Playing`, `message`, `StudioTestPanel`, `Interactable`, `refresh`, `Emotes`, `setOpen`, `workspace`, `ViewportSize`, `GetGuiInset`, `clamp`, `updateScale`, `bindCamera`, `PlaceId`, `GetService`, `ChickenOrHero`, `EmoteCatalog`, `EmoteEvent`, `OldUIReskin`, `Skin`, `screen`, `StudioEmotePreview`, `TestOnlyUI`, `TestUIHidden`, `Legendary`, `Epic`, `Rare`, `Common`, `fromRGB`, `GymJumpingJacks`, `GymPushUps`, `GymSkippingRope`, `GymToeTouches`, `GymAirSquats`, `GymWaterBreak`, `GymDribble`, `GymHeadstand`, `GymFlex`, `GymHulaHoop`, `GymAerobicsGroove`, `GymSneakerSqueak`, `GymPomPomRoutine`, `GymTitleBeltStrut`, `GymHalftimeShow`, `KneeSlide`, `BasketballTricks`, `TrophyLift`, `RainingTokens`, `PreviewControls`, `surface`, `radius`, `textMuted`, `close`, `Reopen`, `STOP`, `primary`, `Legend`, `Entries`, `Ultimate`, `TestHidden`, `AllEmotes`, `ScrollBarThickness`, `AutomaticCanvasSize`, `scroll`, `UIGridLayout`, `CellSize`, `CellPadding`, `PaddingTop`, `PaddingRight`, `EmoteName`, `Rarity`, `Source`, `Marks`, `New`, `NEW`, `PLAYING`, `green`, `Pick`, `fromScale`, `frame`, `OnClientEvent`

### `Players.WhitneyHubbard39.PlayerScripts.StudioKnifePreviewClient` (LocalScript)

`connect`, `Rarity`, `Special`, `neutral`, `rarityOf`, `secondary`, `clock`, `FireServer`, `textStroke`, `cardLabel`, `InMatch`, `PreviewSkin`, `Blade`, `Light`, `JointInstance`, `ThumbAxis`, `ThumbNormal`, `VectorToWorldSpace`, `fromMatrix`, `lookAt`, `thumbnail`, `remove`, `viewport`, `built`, `needs3D`, `build3D`, `StudioKnifePreview`, `cycle`, `StopPreview`, `PreviewAction`, `StudioTestPanel`, `badge`, `Interactable`, `StudioKnifeAction`, `Idle`, `primary`, `refresh`, `Knives`, `setOpen`, `AccessoryType`, `Handle`, `isBack`, `Accessory`, `hideAccessory`, `restoreBack`, `updateBack`, `workspace`, `ViewportSize`, `GetGuiInset`, `clamp`, `updateScale`, `bindCamera`, `GetService`, `PlaceId`, `ChickenOrHero`, `Crates`, `Weapons`, `SkinCatalog`, `KnifeIcons`, `OldUIReskin`, `Skin`, `CrateEvent`, `screen`, `TestOnlyUI`, `TestUIHidden`, `Mythical`, `Legendary`, `Epic`, `Rare`, `Common`, `fromRGB`, `PreviewControls`, `fromOffset`, `surface`, `radius`, `textMuted`, `close`, `Reopen`, `Previous`, `Next`, `Exit`, `EXIT`, `Draw`, `DRAW`, `Stab`, `STAB`, `Dive`, `DIVE`, `IDLE`, `Vowbreaker`, `VOWBREAKER`, `Order`, `StowedBlade`, `BladeWeld`, `EquipReady`, `GripC0`, `GripC1`, `StowedOffset`, `Basketball`, `Dodgeball`, `Volleyball`, `FieldBowie`, `TacticalTanto`, `TrenchKnife`, `Kukri`, `ButterflyKnife`, `ClawKarambit`, `GlacialFang`, `SolarFlare`, `Stormcaller`, `PhoenixTalon`, `Voidrend`, `PrismEdge`, `AllKnives`, `ScrollBarThickness`, `AutomaticCanvasSize`, `scroll`, `UIGridLayout`, `CellSize`, `CellPadding`

### `Players.WhitneyHubbard39.PlayerScripts.TackleDebugClient` (LocalScript)

`workspace`, `PrivateServerHitboxesEnabled`, `HitboxDebug`, `TestUIHidden`, `visibleHitboxes`, `CastShadow`, `Neon`, `clearAll`, `lookAt`, `frame`, `direction`, `forwardStart`, `forwardEnd`, `width`, `height`, `Client`, `Hitbox`, `position`, `clientBox`, `PartType`, `Ball`, `Shape`, `RewindContact`, `expires`, `claimedTarget`, `ClaimedContact`, `rewindTarget`, `ValidatedTarget`, `serverTarget`, `ServerTarget`, `ClaimedStrike`, `claimedOrigin`, `ValidatedStrike`, `rewindOrigin`, `Adornee`, `fromOffset`, `StudsOffset`, `AlwaysOnTop`, `fromScale`, `fromRGB`, `accepted`, `attackKind`, `resolved`, `reason`, `format`, `rewind`, `floor`, `escape`, `remove`, `PlayerPositions`, `snapshots`, `character`, `attackerId`, `number`, `before`, `Server`, `Previous`, `Path`, `targets`, `targetId`, `ServerRunnerRoot`, `client`, `server`, `ClientPlayerRoot`, `ServerPlayerRoot`, `SelectionBox`, `LineThickness`, `SurfaceTransparency`, `debugAttacks`, `GetService`, `ServerIsPrivate`, `PlaceId`, `ChickenOrHero`, `Game`, `CombatPrediction`, `start`, `HitboxDebugEvent`, `HitboxComparison`, `TestOnlyUI`, `Legend`, `OnClientEvent`

### `Players.WhitneyHubbard39.PlayerScripts.TackleInputClient` (LocalScript)

`AdminMatchMode`, `BladeBall`, `bladeBall`, `FloorMaterial`, `Air`, `HumanoidStateType`, `Jumping`, `GetStateEnabled`, `ChangeState`, `attacker`, `PlatformStand`, `MovementLocked`, `reason`, `available`, `remaining`, `TackleActive`, `request`, `ButtonX`, `ContextActionResult`, `Pass`, `fighting`, `UserInputState`, `Sink`, `DashCooldownUntil`, `clock`, `update`, `DASH`, `DIVE`, `CoHTackle`, `UnbindAction`, `GetService`, `ChickenOrHero`, `Movement`, `ControlGate`, `Game`, `TacklePrediction`, `Presentation`, `TouchActionButton`, `HUD`, `CatchButton`, `BoostInput`, `BossCombat`, `Space`, `ButtonR2`, `BindAction`

### `Players.WhitneyHubbard39.PlayerScripts.TestUIToggleClient` (LocalScript)

`restore`, `apply`, `TestOnlyUI`, `changed`, `track`, `untrack`, `TestUIHidden`, `setHidden`, `AdminAuthorized`, `StaffPanel`, `StaffOverlaysWanted`, `TextChannels`, `RBXSystem`, `DisplaySystemMessage`, `GetService`, `TextChatService`, `StudioAbilityTests`, `HitboxComparison`, `HitReplayStatus`, `StudioCheatTest`, `StudioKnifePreview`, `StudioEmotePreview`, `TextChatCommand`, `AdminUIToggleCommand`, `PrimaryAlias`, `SecondaryAlias`, `AutocompleteVisible`, `Triggered`

### `Players.WhitneyHubbard39.PlayerScripts.TimeWarpClient` (LocalScript)

`Highlight`, `FillTransparency`, `OutlineTransparency`, `CastShadow`, `Neon`, `lookAt`, `trail`, `ForceField`, `TimeWarpGhost`, `ghost`, `LightEmission`, `NumberSequenceKeypoint`, `Lifetime`, `Speed`, `SpreadAngle`, `amount`, `round`, `Emit`, `Angles`, `PartType`, `Cylinder`, `Shape`, `flourish`, `ground`, `burst`, `ColorCorrectionEffect`, `TimeWarpTint`, `fromRGB`, `TintColor`, `Saturation`, `objects`, `character`, `destination`, `actorId`, `GetPlayerByUserId`, `TimeWarp`, `Torso`, `UpperTorso`, `TimeWarpSound`, `RollOffMinDistance`, `RollOffMaxDistance`, `Ended`, `FillColor`, `OutlineColor`, `HighlightDepthMode`, `Occluded`, `DepthMode`, `Adornee`, `UserId`, `windup`, `begin`, `position`, `arrive`, `TimeWarpArrive`, `GetService`, `ChickenOrHero`, `Gear`, `GearEvent`, `Interface`, `CharacterClone`, `AbilityFlair`, `TimeWarpFX`, `workspace`, `OnClientEvent`

### `Players.WhitneyHubbard39.PlayerScripts.TopbarPlus.Icon` (ModuleScript)

`iconsDictionary`, `getIcons`, `getIconByUID`, `getIcon`, `boolean`, `topbarEnabled`, `container`, `setTopbarEnabled`, `getModifications`, `baseTheme`, `merge`, `setTheme`, `modifyBaseTheme`, `baseDisplayOrder`, `baseDisplayOrderChanged`, `Fire`, `setDisplayOrder`, `Attribute`, `locked`, `isSelected`, `User`, `deselect`, `handleToggle`, `bindedToggleKeys`, `isViewing`, `viewingStarted`, `Viewing`, `setState`, `viewingEnded`, `desktop`, `mobile`, `overlayDisabled`, `deselectWhenOtherIconSelected`, `AutoDeselect`, `destroy`, `noticeChanged`, `totalNotices`, `childIconsDict`, `HideParentFeature`, `dropdownIcons`, `ChatActive`, `GetCore`, `alignment`, `chatWasPreviouslyActive`, `SetCore`, `PlayerList`, `GetCoreGuiEnabled`, `playerlistWasPreviouslyActive`, `CoreGuiType`, `SetCoreGuiEnabled`, `activeState`, `Deselected`, `stateChanged`, `refresh`, `janitor`, `themesJanitor`, `singleClickJanitor`, `captionJanitor`, `joinJanitor`, `menuJanitor`, `dropdownJanitor`, `generateUID`, `selected`, `deselected`, `toggled`, `notified`, `noticeStarted`, `endNotices`, `toggleKeyAdded`, `fakeToggleKeyChanged`, `alignmentChanged`, `updateSize`, `resizingComplete`, `joinedParent`, `menuSet`, `dropdownSet`, `updateMenu`, `startMenuUpdate`, `childThemeModified`, `indicatorSet`, `dropdownChildAdded`, `menuChildAdded`, `iconModule`, `UID`, `isEnabled`, `enabled`, `joinedFrame`, `parentIconUID`, `originalAlignment`, `appliedTheme`, `appearance`, `cachedInstances`, `cachedNamesToInstances`, `cachedCollectives`, `customBehaviours`, `toggleItems`, `bindedEvents`, `notices`, `menuIcons`, `clock`, `creationTime`, `Widget`, `widget`, `setAlignment`, `setOrder`, `ClickRegion`, `getInstance`, `MouseEnter`, `MouseLeave`, `SelectionGained`, `SelectionLost`, `IconOverlay`, `debug`, `split`, `originsScreenGui`, `localPlayerRespawned`, `iconAdded`, `setName`, `Selected`, `formatStateName`

### `Players.WhitneyHubbard39.PlayerScripts.TopbarPlus.Icon.Attribute` (ModuleScript)

`GetService`, `VERSION`, `getAppVersion`, `getLatestVersion`, `isUpToDate`, `IsStudio`, `format`

### `Players.WhitneyHubbard39.PlayerScripts.TopbarPlus.Icon.Elements.Caption` (ModuleScript)

`fromOffset`, `matchSize`, `KeyboardEnabled`, `CaptionText`, `_hotkey_`, `setCaption`, `updateHotkey`, `getCaptionPosition`, `updateCaret`, `updatePosition`, `joinedFrame`, `match`, `Dropdown`, `GroupTransparency`, `ForceUpdate`, `setCaptionEnabled`, `activeState`, `Viewing`, `captionLastClosedClock`, `clock`, `ClickRegion`, `getInstance`, `CanvasGroup`, `Caption`, `Box`, `Header`, `Medium`, `FontStyle`, `Normal`, `fromRGB`, `Layout`, `Padding`, `CaptionCorner`, `PaddingBottom`, `PaddingLeft`, `PaddingRight`, `PaddingTop`, `Hotkeys`, `fromScale`, `Layout1`, `FillDirection`, `Vertical`, `HorizontalAlignment`, `UIFlexAlignment`, `HorizontalFlex`, `ItemLineAlignment`, `Automatic`, `VerticalFlex`, `Key1`, `ImageTransparency`, `Slice`, `SliceCenter`, `Inset`, `AutoLocalize`, `LabelContent`, `Caret`, `ImageColor3`, `DropShadow`, `captionJanitor`, `clipOutside`, `GetService`, `toggleKeyAdded`, `bindedToggleKeys`, `fakeToggleKeyChanged`, `fakeToggleKey`, `iconModule`, `stateChanged`

### `Players.WhitneyHubbard39.PlayerScripts.TopbarPlus.Icon.Elements.Container` (ModuleScript)

`ForceConvertToOld`, `MenuIsOpen`, `setTopbarEnabled`, `decideToHideTopbar`, `Features`, `Themes`, `Classic`, `modifyBaseTheme`, `insetHeightChanged`, `Fire`, `TopbarInset`, `Height`, `IsTenFootInterface`, `VREnabled`, `isOldTopbar`, `GetGuiInset`, `checkInset`, `StartInset`, `baseDisplayOrder`, `updateCenteredHoldersHeight`, `fromOffset`, `Padding`, `GetService`, `Packages`, `GoodSignal`, `FirstTime`, `TopbarStandard`, `ZIndexBehavior`, `Sibling`, `ScreenInsets`, `TopbarSafeInsets`, `baseDisplayOrderChanged`, `Holders`, `TopbarCentered`, `Clipped`, `IsAHolder`, `ClipsDescendants`, `ScrollBarInset`, `HorizontalScrollBarInset`, `AutomaticCanvasSize`, `ScrollingDirection`, `ScrollBarThickness`, `Selectable`, `ScrollingEnabled`, `ElasticBehavior`, `Never`, `FillDirection`, `Horizontal`, `VerticalAlignment`, `HorizontalAlignment`

### `Players.WhitneyHubbard39.PlayerScripts.TopbarPlus.Icon.Elements.Dropdown` (ModuleScript)

`PreferredTransparency`, `refreshAppearance`, `removeModification`, `joinJanitor`, `Widget`, `BorderSize`, `IconCorners`, `MinimumWidth`, `MinimumHeight`, `IconLabel`, `IconOverlay`, `PaddingLeft`, `fromOffset`, `ContentsList`, `HorizontalAlignment`, `Selection`, `modifyTheme`, `dropdownIcons`, `getIconByUID`, `destroy`, `joinDropdown`, `MaxIcons`, `PaddingTop`, `PaddingBottom`, `updateMaxIcons`, `getInstanceValue`, `Value`, `getTweenInfo`, `isSelected`, `updateVisibility`, `updateChildSize`, `WidgetUID`, `ClickRegion`, `getInstance`, `NextSelectionUp`, `updateMaxIconsListener`, `connectVisibilityListeners`, `Dropdown`, `ClipsDescendants`, `widget`, `GetService`, `setBehaviour`, `janitor`, `DropdownCorner`, `DropdownScroller`, `ScrollBarInset`, `VerticalScrollBarInset`, `VerticalScrollBarPosition`, `ScrollingEnabled`, `AutomaticCanvasSize`, `ScrollBarThickness`, `fromRGB`, `ScrollBarImageColor3`, `ScrollBarImageTransparency`, `Selectable`, `NumberValue`, `DropdownSpeed`, `DropdownPadding`, `DropdownList`, `FillDirection`, `Vertical`, `UIFlexAlignment`, `SpaceEvenly`, `HorizontalFlex`, `dropdownJanitor`, `iconModule`, `dropdownChildAdded`, `dropdownSet`, `toggled`, `AbsoluteCanvasSize`, `childThemeModified`, `Features`, `Themes`

### `Players.WhitneyHubbard39.PlayerScripts.TopbarPlus.Icon.Elements.Indicator` (ModuleScript)

`SelectedObject`, `fromScale`, `selectionChanged`, `GamepadCursorEnabled`, `PaddingRight`, `IndicatorPadding`, `modifyTheme`, `removeModification`, `Indicator`, `updateSize`, `Fire`, `setIndicatorVisible`, `GetImageForKeyCode`, `widget`, `Contents`, `getInstance`, `fromRGB`, `BorderColor3`, `IndicatorButton`, `GetService`, `GamepadService`, `ClickRegion`, `janitor`, `indicatorSet`

### `Players.WhitneyHubbard39.PlayerScripts.TopbarPlus.Icon.Elements.Menu` (ModuleScript)

`menuIcons`, `updateSize`, `Fire`, `removeModification`, `alignment`, `AbsoluteCanvasSize`, `CanvasPosition`, `rightAlignCanvas`, `IconSpot`, `modifyTheme`, `updateAlignent`, `MenuCanvasWidth`, `MaxIcons`, `WidgetUID`, `Padding`, `MenuWidth`, `startMenuUpdate`, `menuJanitor`, `clean`, `toggled`, `Menu`, `selected`, `getStateGroup`, `getThemeValue`, `IconImage`, `Deselected`, `Selected`, `Light`, `FontStyle`, `Normal`, `IconLabel`, `Viewing`, `removeModificationWith`, `MenuGap`, `getInstance`, `alignmentChanged`, `updateMenu`, `MaxWidth`, `totalChildrenChanged`, `getIconByUID`, `destroy`, `joinMenu`, `fromScale`, `ClipsDescendants`, `TopImage`, `BottomImage`, `ScrollBarInset`, `Always`, `HorizontalScrollBarInset`, `ScrollingEnabled`, `ScrollingDirection`, `ScrollBarThickness`, `fromRGB`, `ScrollBarImageColor3`, `ScrollBarImageTransparency`, `Selectable`, `iconModule`, `container`, `TopbarStandard`, `MenuUIListLayout`, `VerticalAlignment`, `Features`, `Themes`, `menuChildAdded`, `menuSet`

### `Players.WhitneyHubbard39.PlayerScripts.TopbarPlus.Icon.Elements.Notice` (ModuleScript)

`getIconByUID`, `parentIconUID`, `dropdownIcons`, `menuIcons`, `isSelected`, `setVisible`, `NoticeHandler`, `Fire`, `noticeChanged`, `totalNotices`, `updateNotice`, `destroy`, `notices`, `deselected`, `notify`, `janitor`, `endNotices`, `generateUID`, `completeSignal`, `clearNoticeEvent`, `notified`, `fromRGB`, `BorderColor3`, `widget`, `NoticeLabel`, `FontSize`, `Size14`, `TextWrap`, `Arial`, `Packages`, `Janitor`, `GoodSignal`, `Utility`, `noticeStarted`, `ClipToJoinedParent`, `clipOutside`

### `Players.WhitneyHubbard39.PlayerScripts.TopbarPlus.Icon.Elements.Selection` (ModuleScript)

`RotationSpeed`, `SelectedObject`, `clock`, `SelectionContainer`, `Selection`, `fromRGB`, `BorderColor3`, `SelectionGradient`, `Collective`, `IconCorners`, `GetService`

### `Players.WhitneyHubbard39.PlayerScripts.TopbarPlus.Icon.Elements.Widget` (ModuleScript)

`isSelected`, `ClipsDescendants`, `PreferredTransparency`, `refreshAppearance`, `TargetWidth`, `getItemWidth`, `iconChanged`, `Fire`, `resizingComplete`, `indicator`, `HorizontalAlignment`, `fromScale`, `Padding`, `TextBounds`, `MinimumWidth`, `MinimumHeight`, `BorderSize`, `clamp`, `menuIcons`, `DesiredWidth`, `updateMenu`, `MenuWidth`, `MaxWidth`, `MenuCanvasWidth`, `Quint`, `fromOffset`, `Time`, `updateParent`, `handleLabelAndImageChangesUnstaggered`, `alignment`, `updateBorderSize`, `LocaleId`, `refresh`, `Value`, `WidgetUID`, `UID`, `Widget`, `IconButton`, `deselected`, `GetService`, `setBehaviour`, `janitor`, `Collective`, `IconCorners`, `Menu`, `MenuUIListLayout`, `MenuGap`, `IconSpot`, `fromRGB`, `OverlayUICorner`, `IconOverlay`, `CorrespondingIconUID`, `ClickRegion`, `Selectable`, `SelectionGroup`, `Features`, `registerButton`, `Contents`, `ContentsList`, `FillDirection`, `Horizontal`, `VerticalAlignment`, `UIFlexAlignment`, `SpaceEvenly`, `VerticalFlex`, `PaddingLeft`, `BorderColor3`, `PaddingCenter`, `PaddingRight`, `IconLabelContainer`, `workspace`, `ViewportSize`, `IconLabel`, `TextWrap`, `AutoLocalize`, `IconImage`, `Stretch`, `IconImageCorner`, `Utility`, `createStagger`, `startMenuUpdate`, `updateSize`, `Indicator`, `IconImageRatio`, `AspectRatio`, `alignmentChanged`, `NumberValue`, `IconImageScale`, `AspectType`, `FitWithinMaxSize`, `DominantAxis`, `Height`, `IconGradient`, `IconSpotGradient`

### `Players.WhitneyHubbard39.PlayerScripts.TopbarPlus.Icon.Features.Gamepad` (ModuleScript)

`SelectedObject`, `CorrespondingIconUID`, `getIconFromSelectedObject`, `ClickRegion`, `getInstance`, `selection`, `janitor`, `IgnoreVisibilityUpdater`, `widget`, `refreshAppearance`, `Selection`, `SelectionImageObject`, `setIndicator`, `parentIconUID`, `ButtonB`, `lastHighlightedIcon`, `highlightKey`, `getIconToHighlight`, `updateSelectedObject`, `preferredInputChanged`, `GamepadCursorEnabled`, `DisableGamepadCursor`, `iconsDictionary`, `Elements`, `highlightIcon`, `start`, `ButtonA`, `ButtonSelect`, `registerButton`, `GamepadService`, `GetService`, `DPadUp`

### `Players.WhitneyHubbard39.PlayerScripts.TopbarPlus.Icon.Features.Overflow` (ModuleScript)

`updateAvailableIcons`, `updateBoundary`, `iconsDictionary`, `container`, `ScreenInsets`, `TopbarSafeInsets`, `Holders`, `IsAHolder`, `createStagger`, `iconAdded`, `iconRemoved`, `iconChanged`, `ViewportSize`, `start`, `widget`, `TargetWidth`, `getWidth`, `getAvailableIcons`, `parentIconUID`, `UID`, `alignment`, `isEnabled`, `Padding`, `reverseTable`, `getRealXPositions`, `secondaryCheck`, `hasRelocatedInOverflow`, `align`, `checkToShiftCentralIcon`, `Deselected`, `setImage`, `Overflow`, `setName`, `setOrder`, `setAlignment`, `autoDeselect`, `isAnOverflow`, `OverflowStart`, `setEnabled`, `closeableOverflowMenus`, `IconSpot`, `getInstance`, `Menu`, `AbsoluteCanvasSize`, `MaxWidth`, `round`, `joinMenu`, `leave`, `overflowAlreadyOpened`, `workspace`, `Utility`

### `Players.WhitneyHubbard39.PlayerScripts.TopbarPlus.Icon.Features.Themes` (ModuleScript)

`getThemeValue`, `getInstanceValue`, `IsAClippedClone`, `OriginalInstance`, `Value`, `getRealInstance`, `HasAClippedClone`, `ClippedClone`, `getClippedClone`, `getStateGroup`, `apply`, `Collective`, `refresh`, `isDestroyed`, `getInstanceOrCollective`, `customBehaviours`, `getModifications`, `statesMatch`, `merge`, `activeState`, `nowSetIt`, `updateRecord`, `generateUID`, `modify`, `Selected`, `Viewing`, `formatStateName`, `Deselected`, `appearance`, `remove`, `rebuild`, `removeWith`, `change`, `themesJanitor`, `clean`, `stateChanged`, `appliedTheme`, `lower`, `copyTable`, `updateDetails`, `Empty`, `generateTheme`, `Utility`, `Default`

### `Players.WhitneyHubbard39.PlayerScripts.TopbarPlus.Icon.Features.Themes.Classic` (ModuleScript)

`Selection`, `Widget`, `MinimumWidth`, `Deselected`, `MinimumHeight`, `BorderSize`, `IconCorners`, `IconButton`, `IconLabel`, `Dropdown`, `NoticeLabel`, `IconSpot`, `fromRGB`, `Selected`, `IconSpotGradient`, `IconOverlay`

### `Players.WhitneyHubbard39.PlayerScripts.TopbarPlus.Icon.Features.Themes.Default` (ModuleScript)

`IconCorners`, `Selection`, `RotationSpeed`, `SelectionGradient`, `ColorSequenceKeypoint`, `fromRGB`, `IconImage`, `Deselected`, `IconLabel`, `fromOffset`, `Widget`, `DesiredWidth`, `MinimumWidth`, `MinimumHeight`, `BorderSize`, `IconButton`, `IconImageScale`, `Value`, `IconImageCorner`, `ImageColor3`, `ImageTransparency`, `IconImageRatio`, `AspectRatio`, `Bold`, `FontStyle`, `Normal`, `IconSpot`, `IconOverlay`, `IconSpotGradient`, `IconGradient`, `ClickRegion`, `Menu`, `ContentsList`, `HorizontalAlignment`, `Dropdown`, `MaxIcons`, `NoticeLabel`, `PaddingLeft`, `PaddingRight`, `Selected`

### `Players.WhitneyHubbard39.PlayerScripts.TopbarPlus.Icon.Packages.GoodSignal` (ModuleScript)

`acquireRunnerThreadAndCallEventHandler`, `yield`, `runEventHandlerInFreeThread`, `_connected`, `_signal`, `_fn`, `_next`, `_handlerListHead`, `format`, `__index`, `__newindex`, `DisconnectAll`, `create`, `resume`, `Fire`, `running`

### `Players.WhitneyHubbard39.PlayerScripts.TopbarPlus.Icon.Packages.Janitor` (ModuleScript)

`getPromiseReference`, `IndicesReference`, `LinkToInstanceIndex`, `CurrentlyCleaning`, `match`, `Promise`, `function`, `format`, `debug`, `traceback`, `Add`, `cancel`, `getStatus`, `Started`, `newproxy`, `finallyCall`, `AddPromise`, `resolve`, `AddObject`, `Get`, `warnUser`, `number`, `Cleanup`, `Connected`, `Connection`, `__tostring`, `ChangedFunction`, `AncestryChanged`, `LinkToInstance`, `LinkToInstances`, `GetService`, `IGNORE_MEMORY_DEBUG`, `ClassName`, `Janitor`, `__index`, `RBXScriptConnection`, `Give`, `GivePromise`, `GiveObject`, `Clean`, `__call`, `lower`

### `Players.WhitneyHubbard39.PlayerScripts.TopbarPlus.Icon.Reference` (ModuleScript)

`objectName`, `ObjectValue`, `Value`, `addToReplicatedStorage`, `getObject`, `GetService`, `TopbarPlusReference`

### `Players.WhitneyHubbard39.PlayerScripts.TopbarPlus.Icon.Utility` (ModuleScript)

`staggeredCallback`, `createStagger`, `floor`, `round`, `reverseTable`, `create`, `copyTable`, `random`, `generateUID`, `setVisible`, `upper`, `lower`, `formatStateName`, `localPlayerRespawned`, `ClippedContainer`, `getClippedContainer`, `FindFirstAncestorWhichIsA`, `match`, `Clipped`, `updateScreenGui`, `ClipHandler`, `updateVisibility`, `UID`, `ClipToJoinedParent`, `getIconByUID`, `joinedFrame`, `parentIconUID`, `DropdownScroller`, `AbsoluteWindowSize`, `checkIfOutsideParentXBounds`, `fromOffset`, `ViewportSize`, `TopbarInset`, `workspace`, `isOldTopbar`, `Height`, `updateProperty`, `Absolute`, `ForceUpdate`, `trackProperty`, `janitor`, `IsAClippedClone`, `ObjectValue`, `OriginalInstance`, `Value`, `HasAClippedClone`, `ClippedClone`, `iconModule`, `container`, `alignmentChanged`, `widget`, `IgnoreVisibilityUpdater`, `AdditionalOffsetX`, `TrackCloneSize`, `clipOutside`, `alignment`, `setAlignment`, `updateAlignent`, `childModifications`, `childModificationsUID`, `modifyTheme`, `isSelected`, `Selectable`, `makeSelectable`, `remove`, `originalAlignment`, `JoinModification`, `removeModification`, `childIconsDict`, `isAnOverflow`, `setEnabled`, `joinJanitor`, `clean`, `leave`, `IconButton`, `ClickRegion`, `getInstance`, `toggled`, `autoDeselect`, `isEnabled`, `joinedParent`, `Fire`, `joinFeature`, `GetService`, `Packages`, `Janitor`

### `Players.WhitneyHubbard39.PlayerScripts.TopbarPlus.Icon.VERSION` (ModuleScript)

`GetService`, `GetProductInfo`, `latestVersion`, `checked`, `match`, `getLatestVersion`, `appVersion`, `getAppVersion`, `isUpToDate`

### `Players.WhitneyHubbard39.PlayerScripts.TournamentResultsClient` (LocalScript)

`workspace`, `ViewportSize`, `round`, `clamp`, `stroke`, `AutomaticCanvasSize`, `ScrollingDirection`, `ScrollBarThickness`, `fromOffset`, `scroll`, `List`, `Padding`, `IsDescendantOf`, `TournamentResultsOpen`, `MatchSummaryVisible`, `setOpen`, `dismiss`, `awaitUIVersion`, `OldUIReskin`, `Skin`, `Presentation`, `ValleyPanels`, `Places`, `screen`, `TournamentResults`, `panel`, `Gold`, `Rules`, `secondary`, `Champion`, `primary`, `MatchHead`, `StandingsHead`, `Match`, `Standings`, `You`, `build`, `Row`, `corner`, `color`, `right`, `ordinal`, `final`, `standings`, `match`, `matches`, `format`, `rules`, `concat`, `total`, `STANDINGS`, `userId`, `UserId`, `survival`, `LMS`, `revives`, `catches`, `points`, `Rank`, `Detail`, `Points`, `gained`, `Gained`, `Total`, `JSONDecode`, `tournament`, `matchId`, `expiresAt`, `number`, `decode`, `Phase`, `Intermission`, `InMatch`, `PracticeActive`, `InitialLoadingComplete`, `cancel`, `evaluate`, `GetService`, `ChickenOrHero`, `FFlags`, `Game`, `MatchSummary`, `fromRGB`, `HostPanelOpen`, `ArmoryOpen`, `JourneyOpen`, `SettingsOpen`, `CrateOpen`, `ServerBrowserOpen`, `ScreenPresentationActive`, `Value`

### `Players.WhitneyHubbard39.PlayerScripts.TrollClient` (LocalScript)

`NewGui`, `Interface`, `Toasts`, `Presentation`, `ValleyToast`, `EscapeStatus`, `fromEnum`, `exempt`, `GameAudio`, `gmatch`, `Ended`, `sound`, `Debug`, `debugOn`, `sayDebug`, `start`, `function`, `GetService`, `ChickenOrHero`, `Trolls`, `TrollShared`, `StateName`, `RemoteName`, `Client`, `player`, `Shared`, `package`, `FFlags`, `awaitUIVersion`, `OnClientEvent`

### `Players.WhitneyHubbard39.PlayerScripts.TruckAbilityClient` (LocalScript)

`ColorSequenceKeypoint`, `AccentDark`, `style`, `forSkin`, `EquippedKnife`, `current`, `ClientReady`, `InMatch`, `PracticeActive`, `allows`, `GameRole`, `GlobalPaused`, `MapChanging`, `knifeBlocked`, `available`, `reason`, `clock`, `ReadyAt`, `workspace`, `Key`, `StepOver`, `request`, `Cannon`, `Weapons`, `Remote`, `Activate`, `FireServer`, `ButtonL1`, `clamp`, `touchStack`, `factor`, `fromOffset`, `right`, `Until`, `upper`, `ActiveLabel`, `format`, `floor`, `ActiveHint`, `RECHARGING`, `TouchHint`, `GamepadEnabled`, `fromScale`, `Cooldown`, `GetService`, `ChickenOrHero`, `OldUIReskin`, `Skin`, `Theme`, `Movement`, `ControlGate`, `Presentation`, `EquipmentHudLayoutLegacy`, `KnifeAbilities`, `StepOverMotion`, `CannonMotion`, `Game`, `AbilityRule`, `screen`, `TruckAbilityHUD`, `Truck`, `Skins`, `Football`, `Base`, `Corner`, `SkinGradient`, `TRUCK`, `track`, `corner`

### `Players.WhitneyHubbard39.PlayerScripts.TruckEffectsClient` (LocalScript)

`GetPlayerByUserId`, `rootOf`, `RollOffMaxDistance`, `AddItem`, `TruckBurst`, `PartType`, `Ball`, `Shape`, `Neon`, `CastShadow`, `workspace`, `burst`, `clock`, `clamp`, `Head`, `TruckStar`, `stars`, `shake`, `Angles`, `random`, `number`, `TruckWhoosh`, `Trucked`, `TruckImpact`, `UserId`, `FakeTowardInput`, `FakeTime`, `stepOver`, `Weapons`, `Skins`, `Futbol`, `Remote`, `OnClientEvent`, `cannonSound`, `CannonSmoke`, `fromRGB`, `Lifetime`, `Speed`, `SpreadAngle`, `Drag`, `Rate`, `Emit`, `smokePuff`, `smooth`, `WorldPosition`, `Flight`, `release`, `Spins`, `blend`, `Poses`, `Neutral`, `Tuck`, `Sounds`, `Blast`, `Presentation`, `PirateShow`, `Cannon`, `GetScale`, `PropScale`, `ScaleTo`, `FilterDescendantsInstances`, `Behind`, `lookAt`, `Muzzle`, `CannonTrail`, `cannonFX`, `AlbiesCutlass`, `CoHTruckShake`, `UnbindFromRenderStep`, `GetService`, `Debris`, `ChickenOrHero`, `TruckAbilityEvent`, `FFlags`, `ClientBots`, `Bots`, `BotDirectory`, `KnifeAbilities`, `GameAudio`, `Value`, `StepOver`, `PirateShots`, `RaycastParams`, `RaycastFilterType`, `Exclude`, `FilterType`, `RespectCanCollide`

### `Players.WhitneyHubbard39.PlayerScripts.TutorialClient` (LocalScript)

`TutorialCrate`, `Crate`, `Halloween`, `setCrate`, `ChatWindowConfiguration`, `ChatInputBarConfiguration`, `window`, `hideChat`, `LayerCollector`, `shown`, `child`, `TutorialKnife`, `newKnife`, `ValleyHUD`, `DrawerClip`, `Panel`, `Navigation`, `Inventory`, `KNIVES`, `MenuToggle`, `MENU`, `menuPath`, `GuiButton`, `upper`, `ABILITIES`, `abilitiesPath`, `GearShop`, `cardButton`, `HalloweenShopOpen`, `HalloweenShop`, `Stage`, `Buy`, `storeCrateBuy`, `AbilityUpgrades`, `ValleyArmory`, `Overlay`, `Canvas`, `upgradeScreen`, `AbilityUpgradesOpen`, `Gear`, `AbilityUpgradeMenu`, `tutorial`, `loaded`, `wantRole`, `RUNNERS`, `CHASERS`, `selected`, `ABILITY`, `owned`, `action`, `FREE`, `EQUIP`, `equip`, `inMenu`, `activeMine`, `CloseButton`, `CLOSE`, `Crates`, `Free`, `Continue`, `CONTINUE`, `Reveal`, `CollectionShade`, `Collection`, `Gems`, `PlayMatch`, `UpgradeRunner`, `UpgradeChaser`, `OneHitShield`, `BearTrap`, `UPGRADE`, `Action`, `ArmoryOpen`, `UpgradeAbilities`, `Tabs`, `Abilities`, `RunnerAbility`, `ChaserAbility`, `GetService`, `FFlags`, `Equip`, `Knife`, `KnifeCollection`, `Details`, `Pick`, `Item`, `BuyAdrenaline`, `Coins`, `Items`, `resolve`, `label`, `gradient`, `Objective`, `fromOffset`, `fromRGB`, `Badge`, `fromScale`, `Count`, `MinTextSize`, `UITextSizeConstraint`, `Progress`, `FillDirection`, `Padding`, `Horizontal`, `Steps`, `banner`, `scale`, `number`, `count`, `objectiveCard`, `outline`, `TutorialGuide`, `ClipToDeviceSafeArea`, `SafeAreaCompatibility`, `ScreenInsets`, `LightsOutKeep`, `ZIndexBehavior`, `Sibling`, `Dim`, `Highlight`

### `Players.WhitneyHubbard39.PlayerScripts.UltimateEmoteButton` (LocalScript)

`EquippedKnife`, `ultimate`, `EmoteId`, `Stop`, `FireServer`, `InMatch`, `PracticeActive`, `reason`, `update`, `STOP`, `ULTIMATE`, `place`, `Melee`, `GetService`, `ChickenOrHero`, `Emotes`, `EmoteCatalog`, `Presentation`, `TouchActionButton`, `TouchCombatLayout`, `Movement`, `ControlGate`, `EmoteEvent`, `HUD`, `CatchButton`, `UltimateEmoteButton`, `fromRGB`, `UISizeConstraint`

### `Players.WhitneyHubbard39.PlayerScripts.VIPChatClient` (LocalScript)

`escape`, `ToHex`, `E4CB89`, `TextSource`, `UserId`, `GetPlayerByUserId`, `OverheadTitle`, `OverheadTitleColor`, `LookAsUserId`, `IsTopWins`, `BoardRankHidden`, `fromRGB`, `Tiers`, `RankTier`, `RankChampion`, `TierColors`, `JourneyTitle`, `JourneyTitleColor`, `LookDisplayName`, `PrefixText`, `DisplayName`, `DeriveNewMessageProperties`, `GetService`, `TextChatService`, `ChatWindowConfiguration`, `ChickenOrHero`, `Game`, `RankedConfig`, `OnChatWindowAdded`

### `Players.WhitneyHubbard39.PlayerScripts.ValleyHudClient` (LocalScript)

`InMatch`, `PracticeActive`, `playing`, `ChickenOrHero`, `Game`, `LobbyResetEvent`, `FireServer`, `SetCore`, `ResetButtonCallback`, `apply`, `Wallet`, `Coins`, `Value`, `fitCandyRow`, `connect`, `HighPingWarning`, `updatePingBadge`, `floor`, `reverse`, `number`, `ClientReady`, `ScreenPresentationActive`, `TutorialRouting`, `TutorialSession`, `AdminRefreshActive`, `ready`, `matchLocked`, `MusicVolume`, `clamp`, `volume`, `setVolume`, `EmoteVolume`, `emoteVolume`, `setEmoteVolume`, `EmoteSlider`, `Knob`, `fromScale`, `ChatNotificationsEnabled`, `ChatNotifications`, `OFF`, `toggle`, `workspace`, `PrivateServerHitboxesEnabled`, `ShowHitboxes`, `PrivateServerBotsDisabled`, `DisableBots`, `MusicMuted`, `MusicSlider`, `Mute`, `EmoteSoundsMuted`, `EmoteSounds`, `SpectatorHints`, `Hints`, `PrivateInvitesOff`, `PrivateInvites`, `HostButtonHidden`, `HostButton`, `HideBoardRank`, `BoardRank`, `RollingDodge`, `RollingDodgeOff`, `IceSkates`, `SnowFlurry`, `Off`, `updateSettings`, `CoreGuiType`, `PlayerList`, `SetCoreGuiEnabled`, `SettingsShade`, `UpdatesShade`, `SettingsOpen`, `UpdateLogOpen`, `SelectedObject`, `IsDescendantOf`, `close`, `GetCoreGuiEnabled`, `opening`, `Shade`, `Settings`, `SpectateRequestedExit`, `clock`, `Panel`, `otherMenu`, `Spectating`, `setAvailable`, `Spectate`, `available`, `isOpen`, `Selectable`, `Servers`, `Updates`, `CursorHint`, `KeyboardAndMouse`, `Order`, `Caption`, `AFK`, `AFKToggle`, `afkMark`, `Mint`, `StateDot`, `awayLook`, `Music`, `musicIcon`, `wallet`, `loaded`, `coins`, `Gems`, `CandyCorn`, `fromOffset`, `refresh`, `activate`, `PrivateServerSettingsOwnerId`, `UserId`, `PrivateServerSettingsEvent`, `Hitboxes`, `layout`, `slide`, `MouseMovement`, `slideEmote`, `DPadLeft`

### `Players.WhitneyHubbard39.PlayerScripts.ViewBeaconClient` (LocalScript)

`workspace`, `FireServer`, `GetService`, `FFlags`, `ClientBots`, `ServerHits`, `ChickenOrHero`, `Bots`, `ViewBeacon`

### `Players.WhitneyHubbard39.PlayerScripts.VowbreakerEffectsClient` (LocalScript)

`forActor`, `GetService`, `BrokenVow`, `SealSeconds`, `sealSeconds`, `emitReady`, `workspace`, `Seconds`, `number`, `Ended`, `playSound`, `eachEffect`, `destroyStream`, `PointLight`, `Brightness`, `stopStream`, `EquippedDagger`, `Blade`, `Knife`, `PetalsPink`, `boost`, `color`, `ActivateSound`, `startStream`, `VowUntil`, `changed`, `watch`, `GetPlayerByUserId`, `ClientBots`, `BotUserId`, `characterOf`, `rootOf`, `Converted`, `follow`, `model`, `stopRevive`, `offset`, `PointToWorldSpace`, `place`, `clock`, `endAt`, `ReviveEffect`, `Head`, `HeadOffset`, `Lift`, `reviveEffect`, `Part2`, `sealed`, `ClientBot`, `KnockLiftHeight`, `KnockLiftTime`, `KnockLiftAt`, `Part1`, `ReviveChime`, `rising`, `ShatterSound`, `Highlight`, `VowRevive`, `FillColor`, `fromRGB`, `OutlineColor`, `FillTransparency`, `OutlineTransparency`, `HighlightDepthMode`, `Occluded`, `DepthMode`, `revived`, `fizzle`, `Torso`, `UpperTorso`, `bodyPart`, `Light`, `setEmitting`, `VowSeal`, `SealVow`, `fromScale`, `UISizeConstraint`, `MinSize`, `MaxSize`, `Hold`, `format`, `frame`, `action`, `buildPrompt`, `Seal`, `FireServer`, `cancelSeal`, `started`, `press`, `beginSeal`, `clamp`, `Finish`, `updatePrompt`, `GameRole`, `Ragdolled`, `Range`, `character`, `lookAt`, `shown`, `parts`, `catcher`, `UserId`, `ReadyToRevive`, `MarkedGlow`, `Terrain`, `marked`, `unmarked`, `ButtonX`, `PlayerScripts`, `PlayerModule`, `GetControls`, `GetMoveVector`, `IsKeyDown`, `moving`, `stopBreakFree`, `BreakFree`, `VowDisplayDown`, `heldDown`, `Sealed`, `Rising`

### `Players.WhitneyHubbard39.PlayerScripts.WarHornClient` (LocalScript)

`number`, `GetPlayerByUserId`, `workspace`, `ClientBots`, `BotUserId`, `bodyOf`, `release`, `WarHorn`, `actorId`, `character`, `start`, `target`, `hunted`, `UserId`, `HornSeconds`, `color`, `seconds`, `Duration`, `HornBoost`, `PlayerScripts`, `PlayerModule`, `GetControls`, `GetMoveVector`, `IsKeyDown`, `moving`, `stopBreakFree`, `clock`, `BreakFree`, `FireServer`, `WarHornDisplayDown`, `changed`, `heldDown`, `GetService`, `ChickenOrHero`, `Gear`, `GearCatalog`, `Presentation`, `WarHornFocus`, `GearEvent`, `AbilityFlair`, `Items`, `OnClientEvent`, `Game`, `WarHornDisplayEvent`, `Down`

### `Players.WhitneyHubbard39.PlayerScripts.WeaponVFXClient` (LocalScript)

`workspace`, `update`, `detail`, `SavedQualityLevel`, `refresh`, `VFXWeld`, `Part0`, `blade`, `LocalTransparencyModifier`, `watchBlade`, `build`, `remove`, `clock`, `CollectionService`, `GetService`, `ChickenOrHero`, `Weapons`, `WeaponEffects`, `CloneEchoMotion`, `UserSettings`, `UserGameSettings`, `Tag`, `GetInstanceAddedSignal`, `GetInstanceRemovedSignal`, `GetTagged`

### `Players.WhitneyHubbard39.PlayerScripts.WorldShopClient` (LocalScript)

`interactable`, `ShopModel`, `IsDescendantOf`, `activate`, `Shop`, `ValleyArmory`, `Overlay`, `Canvas`, `Storefront`, `CanvasPosition`, `GetService`, `ChickenOrHero`, `Presentation`, `HudNavigation`, `Game`, `MapLocator`, `ProximityPromptService`, `PromptTriggered`

### `ReplicatedFirst.AdminPresentation.AdminClient` (LocalScript)

`fitNotice`, `tween`, `TextChannels`, `RBXSystem`, `match`, `offset`, `DisplaySystemMessage`, `chatReply`, `AdminAuthorized`, `reply`, `AdminRefreshActive`, `GroupTransparency`, `AdminTeleportUI`, `UIProportions`, `prepareTeleport`, `workspace`, `ViewportSize`, `SetTeleportGui`, `teleportScreen`, `Content`, `Body`, `MaxVisibleGraphemes`, `clock`, `deadline`, `transfer`, `Retry`, `Dismiss`, `title`, `message`, `showFailure`, `RetryTransfer`, `FireServer`, `Reply`, `Refresh`, `CancelRefresh`, `TransferFailed`, `Announcement`, `StaffPanel`, `StaffPanelOpen`, `AdminConsoleActive`, `GetLocalPlayerTeleportData`, `GetService`, `TextChatService`, `ChickenOrHero`, `Admin`, `AdminEvent`, `AdminUI`, `Console`, `OpenConsole`, `Presentation`, `ValleyTheme`, `UIProportionalGroup`, `UISizeConstraint`, `fromScale`, `UITextSizeConstraint`, `MinTextSize`, `BlurEffect`, `AdminRefreshBlur`, `OnClientEvent`, `destination`, `arrival`, `refreshId`, `Sync`

### `ReplicatedFirst.FFlags` (ModuleScript)

`lower`, `uiVersionOf`, `format`, `settle`, `UIPerPlayer`, `UIVersion`, `peekUIVersion`, `clock`, `awaitUIVersion`, `GetService`, `OldUIReskin`, `UIExperiment`, `NoUI`, `IntermissionExperiment`, `SessionSummaries`, `LateJoinExperiment`, `LateJoinTestMode`, `RunnerBuffExperiment`, `RunnerBuffTestMode`, `TutorialExperiment`, `TutorialTestMode`, `WheelSpinAdTimeSkip`, `TestGameOpen`, `TestGameNoKicks`, `StartLevelTest`, `StartLevelLive`, `HudAdReward`, `ClientBots`, `LocalLocomotion`, `Chrono`, `LoadingScreenEnabled`, `Server929`, `HitModel`, `GAEnabled`, `PrivateServerRewards`, `TestGameOverrides`, `GATesting`, `UISwitchCommand`, `StudioUIVersion`, `PrivateServerStudioPreview`, `ProServers`, `ProServerStudioPreview`, `Ranked`, `Clans`, `RankedStudioPreview`, `BotLobbyWins`, `StartNow`, `EmotesEnabled`, `StarterAbilitiesEnabled`, `AbilityUpgrades`, `KnifeImages`, `Map3Enabled`, `Map4Enabled`, `Map5Enabled`, `Map6Enabled`, `Map7Enabled`, `Map8Enabled`, `Map9Enabled`, `IceSkating`, `Haunt`, `Halloween`, `LightsOut`, `ChaserStandIn`, `BotAutoNodes`, `BonkerDisplayTest`, `VowbreakerDisplayTest`, `GemCratesEverywhere`, `TeamEventEnabled`, `EventIntro`, `JourneyHalloween`, `EventIntroTestNoEvent`, `Albie`, `GiftingEnabled`, `KnifeInventoryLive`, `KnifeInventoryTest`, `CombineLive`, `CombineTest`, `SpinWheelMultiLive`, `SpinWheelMultiTest`, `JourneyArrowLive`, `JourneyArrowTest`, `CaughtLoadoutLive`, `CaughtLoadoutTest`, `CaughtLoadoutBuyLive`, `CaughtLoadoutBuyTest`, `SpectateLoadoutLive`, `SpectateLoadoutTest`, `PumpkinHuntLive`, `PumpkinHuntTest`, `ReviveOfferLive`, `ReviveOfferTest`, `ReviveOfferExperiment`, `PumpkinsLive`, `PumpkinsTest`, `SacrificeBoardsLive`, `SacrificeBoardsTest`, `CrateRollOverheadLive`, `CrateRollOverheadTest`, `PumpkinRollOverheadLive`, `PumpkinRollOverheadTest`, `SpinWheelKnifeOverheadLive`, `SpinWheelKnifeOverheadTest`, `ValleyNoAbilitiesLive`, `ValleyNoAbilitiesTest`, `HalloweenShopLive`, `HalloweenShopTest`, `GhostKeyTraderLive`, `GhostKeyTraderTest`, `CutscenesLive`, `CutscenesTest`, `FallenKingBossLive`, `FallenKingBossTest`, `PracticeMatchesLive`, `PracticeMatchesTest`, `PracticeExperiment`, `PracticeTestMode`, `EmoteWheelPicturesLive`, `EmoteWheelPicturesTest`, `oldui`, `OldUI`

### `ReplicatedFirst.GAClient` (LocalScript)

`GoatSdk`, `ObjectValue`, `clock`, `Value`

### `ReplicatedFirst.LazySound` (ModuleScript)

`Attribute`, `clock`, `IsLoaded`, `GetService`, `PlayLocalSound`, `playLocal`, `Playing`, `stash`, `LazySoundId`, `IdleSeconds`, `__mode`

### `ReplicatedFirst.LazySoundsClient` (LocalScript)

`GameAudio`, `IsDescendantOf`, `inLibrary`, `Playing`, `__mode`, `stash`, `clock`, `watch`, `ClassName`, `added`, `IdleSeconds`, `GetService`, `LazySound`

### `ReplicatedFirst.ProportionalUIClient` (LocalScript)

`GetService`, `UIProportions`, `watch`

### `ReplicatedFirst.ScreenPresentation.IrisController` (ModuleScript)

`config`, `sequence`, `NumberValue`, `value`, `Value`, `panels`, `Mask`, `changed`, `resized`, `Angle`, `fromOffset`, `Blackout`, `tween`, `clock`, `InputBlocker`, `OpenTime`, `CloseTime`, `Quint`, `forceOpen`, `destroy`, `GetService`, `__index`

### `ReplicatedFirst.ScreenPresentation.LoadingProgress` (ModuleScript)

`elapsed`, `finishing`, `MinimumLoadingTime`, `fromScale`, `shine`, `config`, `alive`, `Loading`, `Shine`, `connection`, `LoadingFinishTime`, `tween`, `clock`, `LoadingProgressFinishedAt`, `workspace`, `LoadingFinishHold`, `complete`, `destroy`, `GetService`, `__index`

### `ReplicatedFirst.ScreenPresentation.ReadyHandshake` (ModuleScript)

`ChickenOrHero`, `Game`, `PlayerPreferences`, `player`, `alive`, `remote`, `TransferReady`, `FireServer`, `Ready`, `completeRequested`, `ClientReady`, `transferRequested`, `running`, `complete`, `transferReady`, `__index`

### `ReplicatedFirst.ScreenPresentation.ScreenConfig` (ModuleScript)

`freeze`, `LoadingScreenEnabled`, `CloseTime`, `OpenTime`, `CloseTimeout`, `RevealTimeout`, `StreamTimeout`, `PlacementTimeout`, `RecoveryTimeout`, `LoadingTimeout`, `MinimumLoadingTime`, `LightingSettleTime`, `InitialRecoveryTimeout`, `ReturnMinimumLoadingTime`, `ReturnLightingSettleTime`, `LoadingFinishTime`, `LoadingFinishHold`, `FFlags`

### `ReplicatedFirst.ScreenPresentation.ScreenPresentationClient` (LocalScript)

`GetLocalPlayerTeleportData`, `Loading`, `Eyebrow`, `updateRoutePresentation`, `ChickenOrHero`, `Game`, `IsLoaded`, `PlayerPreferences`, `workspace`, `IsDescendantOf`, `essentialsReady`, `ScreenPresentationActive`, `InitialLoadingComplete`, `complete`, `release`, `forceOpen`, `Shown`, `FireServer`, `failOpen`, `LoadingExit`, `LoadingSeconds`, `clock`, `destroy`, `finishInitial`, `InitialRecoveryTimeout`, `TimedDismissal`, `StreamTimeout`, `RequestStreamAroundAsync`, `RecoveryTimeout`, `Closed`, `Reveal`, `PlacementTimeout`, `MovementReset`, `StreamingEnabled`, `Presentation`, `ScreenTransition`, `OnClientEvent`, `transferReady`, `LoadingTimeout`, `PreloadTotal`, `PreloadFailed`, `PreloadSucceeded`, `PreloadCompleted`, `PreloadTimedOut`, `preload`, `debug`, `traceback`, `xpcall`, `GetService`, `ContentProvider`, `clone`, `ScreenConfig`, `LoadingScreenEnabled`, `cohRefresh`, `ReturnMinimumLoadingTime`, `MinimumLoadingTime`, `ReturnLightingSettleTime`, `LightingSettleTime`, `ScreenOverlay`, `RemoveDefaultLoadingScreen`, `IrisController`, `LoadingProgress`, `ReadyHandshake`, `LoadingStartedAt`, `Skipped`, `LoadingReadyAt`, `Recovered`, `AssetTimeout`, `Ready`

### `ReplicatedFirst.Soundtracks.MusicClient` (LocalScript)

`destroy`, `MusicController`, `JoiningGameMusic`, `MusicConfig`

### `ReplicatedFirst.Soundtracks.MusicConfig` (ModuleScript)

`freeze`, `MasterVolume`, `FadeIn`, `FadeOut`, `MuteFade`, `LoadTimeout`, `TrackGap`, `EmptyRetry`, `PrefetchDelay`, `MapTrackVolume`, `HalloweenLobby`, `MapPlaylists`, `EndsAt`, `Map5`, `Map6`

### `ReplicatedFirst.Soundtracks.MusicController` (ModuleScript)

`usable`, `MusicVolume`, `number`, `clamp`, `MusicMuted`, `outputVolume`, `muteTween`, `MuteFade`, `updateVolume`, `updateEligibility`, `current`, `MusicPaused`, `Pause`, `Resume`, `ActiveMapId`, `setMap`, `GetService`, `ChickenOrHero`, `Game`, `alive`, `LobbyMusicPlayback`, `MasterVolume`, `SoundGroup`, `LocalMusicVolume`, `player`, `theme`, `config`, `folder`, `group`, `themeAttempted`, `lastTrack`, `failed`, `generation`, `random`, `InMatch`, `GameRole`, `Lobby`, `isLobby`, `HalloweenLobby`, `workspace`, `EndsAt`, `Halloween`, `playlist`, `Map`, `wanted`, `MapPlaylists`, `playIndex`, `MapPlaylist`, `currentKind`, `FadeOut`, `retire`, `mapTrack`, `LobbyEligible`, `Stop`, `Retiring`, `fadeIn`, `fadeInSound`, `GameAudio`, `remove`, `nextTrack`, `JoiningTheme`, `PlayOnRemove`, `CurrentTrack`, `IsJoiningTheme`, `Ended`, `clock`, `LoadTimeout`, `IsLoaded`, `LastUnavailableTrack`, `FadeIn`, `TrackSequence`, `ThemePlayCount`, `ThemeStartedAt`, `TimeLength`, `TrackGap`, `EmptyRetry`, `MapTrack_`, `MapTrackVolume`, `destroy`, `LazySound`, `__index`

### `ReplicatedFirst.UIProportions` (ModuleScript)

`ScreenOverlay`, `TeleportOverlay`, `loadingPresentation`, `ProximityPrompts`, `ProximityPromptUI`, `proximityPresentation`, `FindFirstAncestorWhichIsA`, `AbilityControls`, `GearControls`, `UIProportionalExclude`, `HUD`, `CatchButton`, `BoostButton`, `MeleeButton`, `excluded`, `Reference`, `factor`, `SizeConstraint`, `RelativeXX`, `RelativeYY`, `referenceSize`, `resize`, `destroy`, `alive`, `fromScale`, `Value`, `UIAppliedScale`, `ProportionalScale`, `UIReferenceViewport`, `Reveal`, `NumberValue`, `RelativeXY`, `fromOffset`, `UIProportionalGroup`, `prepareTeleport`, `remove`, `DescendantRemoving`, `watch`

### `ReplicatedStorage.ChickenOrHero.Admin.CommandCatalog` (ModuleScript)

`Tiers`, `number`, `Level`, `tierAt`, `BanDays`, `banLimit`, `Wipe`, `canWipe`, `SetRank`, `canSetRank`, `lower`, `contentcreator`, `creator`, `promoter`, `promotionalist`, `CreatorRank`, `tester`, `TesterRank`, `Aliases`, `moderator`, `headadmin`, `srmod`, `seniormod`, `seniormoderator`, `sradmin`, `senioradmin`, `coowner`, `owneradmin`, `Player`, `tierName`, `CreatorOnly`, `commandLevel`, `PermissionOf`, `allowed`, `Usage`, `Description`, `Owner`, `ContentCreator`, `upper`, `Commands`, `concat`, `DisplayName`, `tierDisplay`, `Dev`, `category`, `match`, `Category`, `Command`, `permission`, `Capabilities`, `permissionIds`, `defaultAllows`, `allows`, `banSeconds`, `Helper`, `Moderator`, `SeniorMod`, `Admin`, `SeniorAdmin`, `HeadAdmin`, `OwnerAdmin`, `SoftbanDays`, `GuardExemptLevel`, `Creator`, `Tester`, `TitleRankLevel`, `giftdagger`, `giftknife`, `giftskin`, `commands`, `admins`, `staff`, `setrank`, `admin`, `setadmin`, `unrank`, `unadmin`, `tiers`, `ranks`, `respawn`, `announce`, `restartserver`, `restart`, `refresh`, `refreshserver`, `restartglobal`, `refreshglobal`, `shutdowngame`, `shutdownglobal`, `updategame`, `update`, `unlockserver`, `unlock`, `lockserver`, `cancelglobal`, `cancelupdate`, `status`, `serverinfo`, `history`, `cmdhistory`, `playerhistory`, `phistory`, `globalspin`, `Args`, `ReadOnly`, `sparkles`, `player`, `seconds`, `confetti`, `rainbow`, `ghost`, `bighead`, `launch`, `untroll`, `wheel`, `command`, `players`, `whois`, `titles`, `anticheat`

### `ReplicatedStorage.ChickenOrHero.Admin.CommandCompletion` (ModuleScript)

`lower`, `match`, `Cursor`, `Detail`, `GetService`, `Value`, `JSONDecode`, `Order`, `clamp`, `gmatch`, `Commands`, `allowed`, `Usage`, `Description`, `Args`, `player`, `DisplayName`, `Weapons`, `SkinCatalog`, `Game`, `MapCatalog`, `emote`, `Emotes`, `EmoteCatalog`, `Entries`, `Ultimate`, `CreatorRank`, `setrank`, `TesterRank`, `allows`, `Tiers`, `Level`, `duration`, `banSeconds`, `softban`, `SoftbanDays`, `Permanent`, `Days`, `title`, `toggle`, `seconds`, `command`, `remove`, `suggest`, `CommandCatalog`, `OwnersFriend`, `Collaborator`, `Supporter`, `Developer`, `Tester`, `Creator`, `Artist`, `Animator`, `CommunityStar`, `ValleyLegend`, `EventChampion`

### `ReplicatedStorage.ChickenOrHero.Admin.EventHostCatalog` (ModuleScript)

`freeze`, `Order`, `Durations`, `Modes`, `EventSignup`, `FreeSpin`, `DoubleCoins`, `DoubleGems`, `CrossyRoad`, `DonkeyKong`, `FFACatchers`, `BladeBall`, `Description`, `OneShot`, `MatchMode`

### `ReplicatedStorage.ChickenOrHero.Admin.EventHostLayout` (ModuleScript)

`panel`, `clamp`, `freeze`

### `ReplicatedStorage.ChickenOrHero.Admin.GiveawayRules` (ModuleScript)

`Dagger`, `Coins`, `Gems`, `amount`, `number`, `MaxAmount`, `validPrize`, `upper`, `label`, `version`, `author`, `issuedAt`, `EventSeconds`, `prize`, `validEvent`, `choose`, `Weapons`, `SkinCatalog`, `IntroSeconds`, `SpinSeconds`, `ResultSeconds`, `freeze`

### `ReplicatedStorage.ChickenOrHero.Animation.AnimationConfig` (ModuleScript)

`freeze`, `StudioPreview`, `StudioPreviewClips`, `PublishedIds`, `ClipLengths`, `Tackle`, `CaughtIdle`, `Dash`, `WalkReferenceSpeed`, `RunReferenceSpeed`, `DirectionalReferenceSpeed`, `RunBlendStart`, `RunBlendEnd`, `FadeTime`, `Stop`, `Idle`, `Walk`, `Run`, `Fall`, `Land`, `DiveForward`, `DaggerDive`, `DaggerEquip`, `DaggerHold`, `DaggerFull`, `DaggerStab`, `DaggerStabFullBody`, `DaggerWindup`, `DaggerWindupFullBody`, `DashLeft`, `DashRight`, `DashBack`, `Clip`, `ClipLength`, `FadeIn`, `FadeOut`, `PlaybackRate`, `RecoveryTail`, `MinPlaybackRate`, `MaxPlaybackRate`, `EntrySpeedRatio`, `HoldTime`, `ClipEnd`, `MinBrakeTime`, `MinWeight`, `RetriggerDelay`

### `ReplicatedStorage.ChickenOrHero.Animation.AnimationLibrary` (ModuleScript)

`Animation`, `CoH_`, `AnimationId`, `animation`, `length`, `ClipLengths`, `Duration`, `AnimationClipProvider`, `GetService`, `RegisterAnimationClip`, `Clips`, `PublishedIds`, `IsStudio`, `StudioPreview`, `StudioPreviewClips`, `KeyframeSequence`, `prepare`, `AnimationConfig`

### `ReplicatedStorage.ChickenOrHero.Animation.AnimationPolicy` (ModuleScript)

`clamp`, `smooth`, `atan2`, `angle`, `poseScale`, `RunBlendStart`, `RunBlendEnd`, `Idle`, `Walk`, `Run`, `weights`, `facingWeights`

### `ReplicatedStorage.ChickenOrHero.Animation.DaggerAnimation` (ModuleScript)

`Animator`, `character`, `animator`, `tracks`, `assets`, `attempts`, `retryAt`, `loadedIds`, `knife`, `dagger`, `setDagger`, `EquippedDagger`, `Tool`, `getDagger`, `LoadAnimation`, `Stow`, `MatchCarry`, `Ride`, `noHold`, `default`, `Stop`, `Stab`, `timing`, `Length`, `Animation`, `CoH_`, `AnimationId`, `Actions`, `looped`, `priority`, `Priority`, `ensureStow`, `DaggerAnimationsReady`, `ensure`, `CoH_DaggerStow`, `IsPlaying`, `FadeOut`, `FadeIn`, `stabTiming`, `preparing`, `attackAt`, `stabUntil`, `reset`, `restartStow`, `drawingAt`, `drawPlayed`, `Equip`, `Windup`, `Hold`, `ClientReady`, `stowReady`, `DrawDuration`, `TackleActive`, `ReachStartedAt`, `number`, `sample`, `Recovery`, `strikePhase`, `AdjustSpeed`, `Complete`, `ReachPhase`, `Tracking`, `MovementLocked`, `WindupRate`, `Speed`, `WindupHoldTail`, `update`, `destroy`, `Weapons`, `DaggerConfig`, `KnifeClips`, `Game`, `ContactCatchConfig`, `MeleeAttackTimeline`, `GetService`, `__index`, `DaggerEquip`, `DaggerHold`, `DaggerWindup`, `DaggerStab`

### `ReplicatedStorage.ChickenOrHero.Animation.DashAnimation` (ModuleScript)

`serial`, `DashVisualFacing`, `facing`, `tracks`, `track`, `IsPlaying`, `Dash`, `FadeOut`, `Stop`, `DashAnimationActive`, `release`, `LoadAnimation`, `Animator`, `RigType`, `HumanoidRigType`, `animator`, `retryAt`, `attempts`, `clock`, `prepare`, `style`, `DashLeft`, `DashRight`, `DashBack`, `animation`, `Length`, `loadedAt`, `CoH_`, `AnimationPriority`, `Action`, `Priority`, `endsAt`, `isActive`, `playNamed`, `isName`, `timing`, `LastDashAnimation`, `FadeIn`, `AnimationConfig`, `DashAnimationPolicy`, `AnimationLibrary`, `DodgeStyles`

### `ReplicatedStorage.ChickenOrHero.Animation.DashAnimationPolicy` (ModuleScript)

`isName`, `DashBack`, `DashLeft`, `DashRight`, `selectFacing`, `DodgeStyles`, `knife`, `Duration`, `RecoveryDuration`, `RecoveryTail`, `MinPlaybackRate`, `MaxPlaybackRate`, `clamp`, `timing`, `atan2`

### `ReplicatedStorage.ChickenOrHero.Animation.DodgeStyles` (ModuleScript)

`Styles`, `dodges`, `Order`, `owned`, `DaggerSkin`, `KNIFE`, `CARRIED`, `KnifeRun`, `HELD`, `DaggerState`, `Held`, `Drawing`, `knife`, `DodgeStyle`, `DodgeStyleOff`, `Animation`, `CoH_`, `AnimationId`, `animation`, `GetService`, `IceSkating`, `freeze`, `Rolling`, `Basketball`, `Dodgeball`, `Volleyball`, `Hoverboard`, `IceSkate`, `DashLeft`, `DashRight`, `DashBack`, `Dodges`, `AlbiesHoverboard`

### `ReplicatedStorage.ChickenOrHero.Animation.IceSkateEffects` (ModuleScript)

`RollOffMode`, `InverseTapered`, `RollOffMinDistance`, `RollOffMaxDistance`, `newSound`, `Rate`, `LockedToPart`, `newEmitter`, `NumberSequenceKeypoint`, `sequence`, `IceEdgeL`, `IceEdgeR`, `Attachment0`, `Attachment1`, `FaceCamera`, `Lifetime`, `MinLength`, `LightEmission`, `WidthScale`, `skate`, `trail`, `IceSpray`, `EmissionDirection`, `Acceleration`, `Drag`, `NormalId`, `Front`, `Speed`, `SpreadAngle`, `RotSpeed`, `spray`, `shards`, `burst`, `bladeOf`, `IceFrostMarks`, `workspace`, `markFolderOf`, `Frost`, `CastShadow`, `Glass`, `placeMark`, `fadeMarks`, `WorldPosition`, `lookAt`, `WorldCFrame`, `aimAt`, `blades`, `Emit`, `sounds`, `still`, `lastMark`, `Glide`, `Stop`, `clock`, `character`, `lastPos`, `velocity`, `Cloaked`, `Ghosted`, `lastSpeed`, `FloorMaterial`, `Air`, `clamp`, `nextRay`, `FilterDescendantsInstances`, `grounded`, `IceDepth`, `number`, `groundY`, `IsPlaying`, `Brake`, `brakeFadeAt`, `cooldowns`, `airTime`, `Plant`, `remove`, `IsClient`, `GetService`, `fromRGB`, `RaycastParams`, `RaycastFilterType`, `Exclude`, `FilterType`, `RespectCanCollide`

### `ReplicatedStorage.ChickenOrHero.Animation.IceSkating` (ModuleScript)

`IceSkates`, `IceSkatesLocal`, `Leg`, `Part0`, `Part1`, `GetService`, `IsClient`, `IceSkateEffects`, `dress`, `IceSkating`, `enabled`, `ActiveMapId`, `Map`, `onRink`, `IceSkatesHidden`, `EquippedKnife`, `IceSkate`, `InMatch`, `onRinkMatch`, `skating`, `FFlags`, `Game`, `Map9`, `freeze`, `Idle`, `Run`, `Stop`, `Fall`, `CaughtIdle`, `Clips`, `DashLeft`, `DashRight`, `DashBack`, `Dodges`, `Lengths`

### `ReplicatedStorage.ChickenOrHero.Animation.LocalLocomotion` (ModuleScript)

`Animation`, `AnimationId`, `ContentProvider`, `GetService`, `PreloadAsync`, `KNIFE`, `DashLeft`, `DashRight`, `DashBack`, `animation`, `Weapons`, `preloadKnife`, `Priority`, `AnimationPriority`, `Core`, `Idle`, `isAction`, `LocalLocomotionRigs`, `workspace`, `rigFolder`, `Proxy`, `CastShadow`, `Massless`, `Torso`, `Part0`, `Part1`, `AnimationController`, `Animator`, `buildProxy`, `animator`, `LoadAnimation`, `slide`, `slideUntil`, `intro`, `match`, `Action`, `serial`, `setSlide`, `Dash`, `FadeOut`, `Stop`, `stopSlide`, `Length`, `character`, `Duration`, `RecoveryDuration`, `RecoveryTail`, `clamp`, `FadeIn`, `playSlide`, `played`, `actions`, `release`, `loader`, `destroy`, `proxy`, `AnimationPackActive`, `AnimationPackLoading`, `AnimationAction`, `remove`, `RigType`, `HumanoidRigType`, `Neck`, `RootJoint`, `RaycastParams`, `RaycastFilterType`, `Exclude`, `FilterType`, `FilterDescendantsInstances`, `RespectCanCollide`, `player`, `humanoid`, `proxyRoot`, `joints`, `params`, `stopState`, `cyclePhase`, `airTime`, `wasGrounded`, `actionEnd`, `version`, `extras`, `prepare`, `MovementReset`, `DashAnimationSequence`, `BoostEffectAt`, `dashSignal`, `clock`, `refresh`, `realAnimator`, `AnimationPlayed`, `GetPlayingAnimationTracks`, `watchActions`, `skating`, `tracks`, `SkateStop`, `ready`, `actionTrack`, `actionName`, `endAction`, `startAction`, `smoothSpeed`, `brakeFrames`, `Deceleration`, `Braking`, `peakSpeed`, `entrySpeed`, `MaxSpeed`, `Running`, `Accelerating`, `remoteMode`, `lastPosition`, `velocity`, `remoteVelocity`, `remoteGrounded`, `dropExtra`, `BallJoint`, `ballJoint`, `syncBall`, `Handle`

### `ReplicatedStorage.ChickenOrHero.Animation.LocomotionTracks` (ModuleScript)

`animator`, `assets`, `tracks`, `entries`, `nextCheck`, `LoadAnimation`, `track`, `Length`, `attempt`, `CoH_`, `CaughtIdle`, `AnimationPriority`, `Action2`, `KnifeIdle`, `Action`, `Movement`, `Priority`, `animation`, `knifeAssets`, `skateAssets`, `refresh`, `Stop`, `Animation`, `CoH_Skate`, `AnimationId`, `Skate`, `setSkate`, `dropKnife`, `runId`, `KnifeRun`, `match`, `KnifeLeft`, `KnifeRight`, `KnifeBack`, `setRun`, `ready`, `Idle`, `Walk`, `Run`, `coreReady`, `Fall`, `weights`, `destroy`, `__index`, `Land`, `SkateStop`, `SkateCaught`

### `ReplicatedStorage.ChickenOrHero.Animation.MeleeAttackTimeline` (ModuleScript)

`Windup`, `WindupRate`, `StabContactStart`, `StabContactEnd`, `ActiveDuration`, `Recovery`, `StabDuration`, `Complete`, `sample`, `freeze`

### `ReplicatedStorage.ChickenOrHero.Animation.StopAnimationPolicy` (ModuleScript)

`clamp`, `smooth`, `runTime`, `lastPlayedAt`, `Braking`, `MaxSpeed`, `EntrySpeedRatio`, `angle`, `allowed`, `entrySpeed`, `ClipEnd`, `clipLength`, `Deceleration`, `HoldTime`, `MinBrakeTime`, `RetriggerDelay`, `duration`, `clipEnd`, `weight`, `MaxPlaybackRate`, `MinPlaybackRate`, `MinWeight`, `Running`, `Accelerating`, `speed`

### `ReplicatedStorage.ChickenOrHero.Animation.TackleAnimation` (ModuleScript)

`PublishedIds`, `ByClip`, `EquippedDagger`, `Tool`, `custom`, `resolveId`, `tracks`, `track`, `asset`, `release`, `LoadAnimation`, `Animator`, `RigType`, `HumanoidRigType`, `animator`, `Stop`, `Animation`, `CoH_`, `AnimationId`, `AnimationPriority`, `Action3`, `Priority`, `loadTrack`, `Tackle`, `Clip`, `prepare`, `token`, `IsPlaying`, `FadeOut`, `Length`, `number`, `lengthOf`, `AdjustSpeed`, `DiveFadeOut`, `finish`, `second_`, `Dive`, `ClipLength`, `DiveAnimLength`, `DaggerDive`, `DiveDuration`, `normalize`, `DiveFollowAnim`, `DaggerDiveFollow`, `DiveSplit`, `clamp`, `DiveFollowAnimLength`, `FadeIn`, `AnimationConfig`, `Weapons`, `DaggerConfig`, `KnifeClips`

### `ReplicatedStorage.ChickenOrHero.Audio.AudioCatalog` (ModuleScript)

`Path`, `MinInterval`, `ChoiceFocus`, `ChoiceFocusResolve`, `GemCollect`, `LobbyMusic`, `MatchMusic`, `FootstepGrass`, `FootstepConcrete`, `FootstepSand`, `FootstepDirt`, `FootstepWood`, `FootstepMetal`, `FootstepSnow`, `FootstepWater`, `FootstepPuddle1`, `FootstepPuddle2`, `FootstepPuddle3`, `FootstepPuddle4`, `MovementStart`, `RunStop`, `SharpTurn`, `BoostStart`, `BoostRecovery`, `BoostReady`, `LandSoft`, `LandHard`, `ClothesRustle`, `SprintWind`, `DiveStart`, `DiveLand`, `DiveRecover`, `CatchImpact`, `CatchSuccess`, `CatchReady`, `RecapLevelUp`, `RecapOpen`, `RecapTick`, `RecapComplete`, `DangerPulse`, `Hover`, `Click`, `PanelOpen`, `PanelClose`, `ChoiceSubmitted`, `MatchCountdown`, `CountdownTick`, `CountdownFinal`, `RoundReady`, `RunStart`, `HeroRunStart`, `FinalRunStart`, `RunEnd`, `TimeWarning`, `MatchEnd`, `SpawnRefresh`, `LobbyReturn`, `HeroChosen`, `ChickenChosen`, `RoleRunner`, `RoleCatcher`, `SelectedHero`, `ReachedSafety`, `Caught`, `Victory`, `Defeat`, `Respawn`, `Death`, `Weapons`, `SkinCatalog`, `Skins`, `SoundEvents`, `Knife_`, `SoundProfile`, `Windup`

### `ReplicatedStorage.ChickenOrHero.Audio.AudioConfig` (ModuleScript)

`UpdateInterval`, `Danger`, `MusicFade`, `MaxVoices`, `MaxOneShotSeconds`, `RemoteFootstepGain`, `RemoteMovementGain`, `RemoteFootstepDistance`, `RemoteActionDistance`, `MaxNearbyCharacters`, `MinStepSpeed`, `MinStepInterval`, `FallbackStepDistance`, `FootstepPhases`, `DefaultSurface`, `Grass`, `HardLandingSpeed`, `MinFallTime`, `CountdownPhases`, `CrossingPhases`, `PhaseCues`, `Materials`, `AttackTime`, `ReleaseTime`, `InactiveFadeTime`, `SampleTimeout`, `MinRate`, `MaxRate`, `Countdown`, `Prepare`, `HeroChoice`, `HeroRun`, `GroupRun`, `FinalRun`, `MatchCountdown`, `RoundReady`, `RunStart`, `HeroRunStart`, `FinalRunStart`, `Results`, `MatchEnd`, `LeafyGrass`, `Ground`, `Dirt`, `Mud`, `Sand`, `Sandstone`, `Snow`, `Ice`, `Glacier`, `Wood`, `WoodPlanks`, `Metal`, `CorrodedMetal`, `DiamondPlate`, `Foil`, `Concrete`, `Brick`, `Cobblestone`, `Rock`, `Slate`, `Asphalt`, `Pavement`, `Marble`, `Granite`, `Pebble`, `Water`

### `ReplicatedStorage.ChickenOrHero.Audio.AudioPlayback` (ModuleScript)

`match`, `assetReady`, `GameAudioPlayback`, `library`, `catalog`, `folder`, `voices`, `loops`, `cooldowns`, `random`, `voiceCount`, `music`, `musicToken`, `alive`, `emitters`, `__mode`, `split`, `Path`, `template`, `DebugEvents`, `LastCue`, `LastCuePlayed`, `Cue_`, `trace`, `tween`, `sound`, `remove`, `MaxVoices`, `workspace`, `IsDescendantOf`, `CoH_`, `PlayOnRemove`, `CoHAudioEmitter`, `KnifeMaxSeconds`, `number`, `MaxOneShotSeconds`, `clamp`, `clock`, `deadline`, `knifeFade`, `knife`, `Ended`, `PlaybackRegionsEnabled`, `PlaybackRegion`, `create`, `MinInterval`, `PitchVariation`, `fadeEnd`, `MusicSlot`, `MusicFade`, `setMusic`, `heardAt`, `IsPlaying`, `update`, `destroy`, `GetService`, `LazySound`, `__index`

### `ReplicatedStorage.ChickenOrHero.Audio.AudioPolicy` (ModuleScript)

`Lobby`, `Countdown`, `MatchMusic`, `LobbyMusic`, `music`, `AudioSurface`, `Grass`, `Materials`, `workspace`, `DefaultSurface`, `surface`, `crossed`

### `ReplicatedStorage.ChickenOrHero.Audio.DaggerAudio` (ModuleScript)

`install`, `playback`, `records`, `previewAt`, `remoteTimes`, `Hit`, `DiveHit`, `HitSoundProfile`, `SoundProfile`, `Knife_`, `workspace`, `RemoteActionDistance`, `DaggerSkin`, `clock`, `remove`, `layer`, `DaggerEquipped`, `DaggerDrawStartedAt`, `LocalMeleeActive`, `LocalMeleeStartedAt`, `ReachStartedAt`, `TackleStartedAt`, `DaggerState`, `LocalMeleePhase`, `ReachPhase`, `StudioKnifeActionAt`, `StudioKnifeAction`, `phase`, `windupAt`, `Drawing`, `number`, `Equip`, `GetService`, `IsStudio`, `PlaceId`, `ContentTeam`, `StudioKnifePreview`, `InMatch`, `LobbyKnifeOutUntil`, `Stab`, `Swing`, `lastLocalSwingAt`, `Dive`, `Stowed`, `Held`, `Sheath`, `lastDiveAt`, `StabDelay`, `TackleActive`, `lastSwingAt`, `Tracking`, `Windup`, `prepareStab`, `prepareDive`, `cancelAt`, `update`, `position`, `template`, `catcher`, `UserId`, `KnifeImpactAudio`, `Terrain`, `WorldPosition`, `AddItem`, `previewSerial`, `alive`, `ArmoryOpen`, `BalloonOfferOpen`, `BundleOfferOpen`, `previewVoice`, `create`, `trace`, `SoundEvents`, `preview`, `destroy`, `Debris`, `Presentation`, `ParticipantDirectory`, `Weapons`, `SkinCatalog`, `DaggerConfig`, `FantasyKnifeAudio`, `__index`

### `ReplicatedStorage.ChickenOrHero.Audio.DefaultCharacterAudio` (ModuleScript)

`RbxCharacterSounds`, `disable`, `cleanCharacter`, `AudioPlayer`, `RbxCharacterSoundsEmitter`, `AudioEmitter`, `removeDefault`, `character`, `remove`, `PlayerScripts`, `start`, `GetService`, `Climbing`, `GettingUp`, `Swimming`, `Jumping`, `Landing`, `Splash`, `FreeFalling`, `Running`

### `ReplicatedStorage.ChickenOrHero.Audio.FantasyKnifeAudio` (ModuleScript)

`PlayOnRemove`, `RollOffMaxDistance`, `RollOffMinDistance`, `PitchVariation`, `KnifeMaxSeconds`, `Equip`, `Hit`, `Signature`, `sound`, `library`, `BaseDagger`, `SpoonDagger`, `Sheath`, `Swing`, `Knife_`, `catalog`, `Path`, `MinInterval`, `Windup`, `Dive`, `install`, `layer`, `FantasyCommon`, `FantasyRare`, `MoltenFang`, `SpectralReaper`, `SolarPhoenix`, `VoidSovereign`, `Voidspine`, `StormTalon`, `Moonfang`, `GlacialCrown`, `CelestialDragon`, `EmberCommon`, `EmberRare`, `EmberEpic`, `EmberLegendary`, `CelestialCommon`, `CelestialRare`, `CelestialEpic`, `CelestialLegendary`, `clone`

### `ReplicatedStorage.ChickenOrHero.Audio.InterfaceAudio` (ModuleScript)

`LayerCollector`, `FindFirstAncestorWhichIsA`, `Notifications`, `HUD`, `UseGameAudio`, `belongs`, `Hover`, `Click`, `Options`, `ChoiceSubmitted`, `PanelOpen`, `PanelClose`, `GuiButton`, `buttons`, `MouseEnter`, `SelectionGained`, `Choices`, `panels`, `remove`, `DescendantRemoving`, `destroy`, `__index`

### `ReplicatedStorage.ChickenOrHero.Audio.MovementAudio` (ModuleScript)

`FootstepPuddle`, `GetTagged`, `FilterDescendantsInstances`, `refreshPuddles`, `workspace`, `inPuddle`, `RaycastParams`, `RaycastFilterType`, `Exclude`, `FilterType`, `RespectCanCollide`, `playback`, `records`, `params`, `CoHAudioEmitter`, `remove`, `character`, `lastPosition`, `reset`, `lastMode`, `lastAction`, `dashCount`, `tackleStarted`, `lastReady`, `wasMoving`, `wasGrounded`, `airTime`, `fallSpeed`, `stepDistance`, `lastStep`, `lastJump`, `health`, `MovementReset`, `MovementState`, `AnimationAction`, `DashCount`, `TackleStartedAt`, `DashReady`, `Respawn`, `newRecord`, `MinStepInterval`, `random`, `Footstep`, `template`, `DefaultSurface`, `distance`, `RemoteActionDistance`, `MaxNearbyCharacters`, `clock`, `GameRole`, `MaxSpeed`, `track`, `phase`, `usedBoost`, `usedCatch`, `silentUntil`, `TackleActive`, `diveLanded`, `DaggerEquipped`, `DiveStart`, `RemoteMovementGain`, `TackleDuration`, `DiveLand`, `DiveRecover`, `TackleReadyAt`, `CatchReady`, `GetState`, `HumanoidStateType`, `Swimming`, `Climbing`, `Physics`, `PlatformStand`, `MovementLocked`, `CollisionGroup`, `FloorMaterial`, `Air`, `BoostStart`, `Recovering`, `BoostRecovery`, `BoostReady`, `Stop`, `skating`, `RunStop`, `Death`, `Jumping`, `MinFallTime`, `HardLandingSpeed`, `LandHard`, `LandSoft`, `MinStepSpeed`, `animatorFor`, `Animator`, `GetPlayingAnimationTracks`, `Animation`, `AnimationId`, `CoH_Stop`, `PublishedIds`, `WeightCurrent`, `Length`, `lastSpeed`, `MovementStart`, `Boosting`, `Dashing`, `direction`, `turnAt`, `SharpTurn`, `clamp`, `RemoteFootstepDistance`, `surface`, `RemoteFootstepGain`, `crossed`, `FootstepPhases`, `FallbackStepDistance`, `Clothes`, `ClothesRustle`, `Wind`, `SprintWind`, `update`, `destroy`, `GetService`

### `ReplicatedStorage.ChickenOrHero.Audio.ThreatAudio` (ModuleScript)

`playback`, `player`, `session`, `level`, `Phase`, `PracticeActive`, `DangerAudioMuted`, `InMatch`, `GameRole`, `MovementLocked`, `ChoiceSpotlightActive`, `ScreenPresentationActive`, `HeroRun`, `GroupRun`, `FinalRun`, `CatcherThreatUpdatedAt`, `SampleTimeout`, `CatcherThreatIntensity`, `clamp`, `InactiveFadeTime`, `AttackTime`, `ReleaseTime`, `MinRate`, `MaxRate`, `Danger`, `DangerPulse`, `update`, `destroy`, `__index`

### `ReplicatedStorage.ChickenOrHero.Bots.BotDirectory` (ModuleScript)

`Connected`, `_signal`, `_handlers`, `remove`, `newSignal`, `_fn`, `running`, `yield`, `clone`, `_fire`, `record`, `_posed`, `_position`, `_look`, `_velocity`, `_at`, `_removed`, `Hidden`, `FadeOutAt`, `_flags`, `bit32`, `_body`, `MovementLocked`, `Ragdolled`, `number`, `isActive`, `create`, `clock`, `heard`, `takeRing`, `dropRing`, `visit`, `receive`, `_origin`, `_yaw`, `_speed`, `_ring`, `MaxExtrapolation`, `sample`, `renderAt`, `NetId`, `attach`, `_ref`, `Value`, `_rig`, `CharacterChanged`, `updateCharacter`, `_refChanged`, `bindRef`, `DisplayName`, `CloneOwnerUserId`, `OwnerUserId`, `BotKind`, `Bot`, `Kind`, `AvatarUserId`, `FrameOrigin`, `describe`, `freeze`, `publish`, `PracticeOwner`, `Body`, `ownerOf`, `PracticeActive`, `UserId`, `world`, `ObjectValue`, `IsBot`, `_connections`, `AttributeChanged`, `Added`, `Removed`, `again`, `watchBody`, `track`, `untrack`, `resort`, `_setRig`, `OnClientEvent`, `_watch`, `UnbindFromRenderStep`, `ClientBotPoses`, `_stop`, `records`, `models`, `rings`, `waiting`, `watchers`, `added`, `removed`, `changed`, `_counts`, `workspace`, `Delay`, `Actors`, `BotFrames`, `enabled`, `Input`, `start`, `GetPlayerByUserId`, `resolve`, `ofModel`, `model`, `setFocus`, `Focus`, `focus`, `GetService`, `FFlags`, `BotFrameCodec`, `BotNetConfig`, `ClientBots`, `IsClient`, `RenderDelay`, `Flags`, `Locked`, `SendRate`, `__index`, `_resort`, `_receive`, `_step`

### `ReplicatedStorage.ChickenOrHero.Bots.BotFrameCodec` (ModuleScript)

`round`, `clamp`, `fixed`, `atan2`, `buffer`, `create`, `Header`, `Entry`, `writeu8`, `writef64`, `stamp`, `writeu16`, `writei16`, `putFixed`, `readu8`, `readu16`, `readi16`, `readf64`, `MaxEntries`, `Grounded`, `Boosting`, `Dashing`, `Tackling`, `Ragdolled`, `Locked`, `Flags`

### `ReplicatedStorage.ChickenOrHero.Bots.BotNetConfig` (ModuleScript)

`freeze`, `SendRate`, `KeyframeSeconds`, `RenderDelay`, `MaxExtrapolation`

### `ReplicatedStorage.ChickenOrHero.Bots.ClientBotAnimator` (ModuleScript)

`Length`, `ready`, `clamp`, `smooth`, `character`, `humanoid`, `assets`, `tracks`, `attempts`, `retryAt`, `loadedAt`, `weights`, `phase`, `prepare`, `Animator`, `animator`, `LoadAnimation`, `animation`, `CoH_`, `CaughtIdle`, `AnimationPriority`, `Action2`, `Movement`, `Priority`, `ensure`, `Idle`, `Walk`, `Run`, `Animation`, `CoH_Skate`, `Clips`, `AnimationId`, `length`, `Lengths`, `clone`, `skateSet`, `skating`, `baseAssets`, `Stop`, `setSkating`, `reset`, `start`, `GetPlayingAnimationTracks`, `WeightCurrent`, `Speed`, `inherit`, `IsPlaying`, `decoyTrack`, `CoH_InflatableDecoy`, `decoy`, `atan2`, `RunBlendStart`, `RunBlendEnd`, `ClipLengths`, `WalkReferenceSpeed`, `RunReferenceSpeed`, `WeightTarget`, `DirectionalReferenceSpeed`, `AdjustWeight`, `AdjustSpeed`, `update`, `release`, `destroy`, `AnimationConfig`, `AnimationLibrary`, `DashAnimation`, `BodyFacingConfig`, `IceSkating`, `__index`

### `ReplicatedStorage.ChickenOrHero.Bots.ClientBotKnife` (ModuleScript)

`Handle`, `Blade`, `StowedBlade`, `BladeWeld`, `JointInstance`, `Part0`, `Part1`, `GripC1`, `StowedOffset`, `usable`, `character`, `strip`, `weapon`, `motor`, `blade`, `stowed`, `attach`, `Torso`, `leftStowed`, `chain`, `controller`, `destroy`, `drawAt`, `remove`, `RigType`, `HumanoidRigType`, `DefaultSkin`, `EquippedDagger`, `Massless`, `CollisionGroup`, `StowedDagger`, `position`, `create`, `restartStow`, `DaggerEquipped`, `DaggerState`, `DaggerDrawStartedAt`, `DaggerSkin`, `Held`, `Drawing`, `number`, `CloneStartsHeld`, `GameRole`, `DrawDuration`, `DrawTransfer`, `MovementReset`, `reset`, `ReachStartedAt`, `attackAt`, `update`, `Weapons`, `DaggerConfig`, `DaggerGrip`, `WeaponEffects`, `Animation`, `DaggerAnimation`, `KnifeVisibility`, `DualWield`, `KnifeChains`, `Emotes`, `EmotePieces`, `__index`

### `ReplicatedStorage.ChickenOrHero.Bots.ClientBotKnockdown` (ModuleScript)

`CoHRunner`, `CollisionGroup`, `clamp`, `smooth`, `workspace`, `IceDepth`, `number`, `ground`, `onDown`, `atan2`, `facing`, `turnedAxis`, `started`, `ended`, `angle`, `groundX`, `groundZ`, `stand`, `cframe`, `liftAt`, `begin`, `liftHeight`, `liftTime`, `Rise`, `lifted`, `finish`, `Fall`, `lastX`, `lastZ`, `lastYaw`, `Angles`, `VectorToWorldSpace`, `fromAxisAngle`, `frame`, `identity`, `Transform`, `limbs`, `Limbs`, `RaycastParams`, `RaycastFilterType`, `Exclude`, `FilterType`, `RespectCanCollide`

### `ReplicatedStorage.ChickenOrHero.Bots.ClientBotOutline` (ModuleScript)

`folder`, `groups`, `members`, `Highlight`, `Outline`, `HighlightDepthMode`, `Occluded`, `DepthMode`, `FillColor`, `OutlineColor`, `fillT`, `FillTransparency`, `edgeT`, `OutlineTransparency`, `Adornee`, `group`, `shown`, `joined`, `model`, `flash`, `flashTween`, `cancel`, `style`, `RoleOutline`, `Caught`, `marker`, `markerStyle`, `RoleMarker`, `fromOffset`, `AlwaysOnTop`, `LightInfluence`, `MaxDistance`, `fromScale`, `DownedCenter`, `fromRGB`, `Head`, `StudsOffsetWorldSpace`, `VisualStyle`, `Safe`, `apply`, `settle`, `counts`, `destroy`, `GetService`, `__index`, `Hero`, `colors`, `GearBoost`, `GearBoostCatcher`, `GearSlow`, `Shield`, `styles`

### `ReplicatedStorage.ChickenOrHero.Bots.ClientBotRenderer` (ModuleScript)

`profiled`, `EquippedDagger`, `LayerCollector`, `Highlight`, `Tool`, `ForceField`, `BodyMover`, `Constraint`, `ClassName`, `CaughtRagdoll`, `Fire`, `Smoke`, `Sparkles`, `Light`, `IsDescendantOf`, `strip`, `JointInstance`, `Part0`, `Part1`, `RigidConstraint`, `Attachment0`, `Attachment1`, `remove`, `repose`, `joints`, `EvaluateStateMachine`, `PlatformStand`, `AutoRotate`, `BreakJointsOnDeath`, `RequiresNeck`, `HumanoidDisplayDistanceType`, `DisplayDistanceType`, `HumanoidHealthDisplayType`, `AlwaysOff`, `HealthDisplayType`, `NameDisplayDistance`, `HealthDisplayDistance`, `dormant`, `folder`, `workspace`, `ClientBots`, `directory`, `clock`, `parts`, `frames`, `outline`, `frame`, `start`, `Added`, `Removed`, `ClientBotRigs`, `Input`, `Value`, `bound`, `UnbindFromRenderStep`, `clone`, `actor`, `destroy`, `record`, `FadeOutAt`, `FadeSeconds`, `number`, `fadeAt`, `fadeSeconds`, `fadeChanged`, `model`, `GetAttributes`, `ClientBot`, `BotUserId`, `UserId`, `IsBot`, `mirror`, `profileDirty`, `dirty`, `bodyChanged`, `AttributeChanged`, `bindBody`, `Hidden`, `LocalHidden`, `hidden`, `LookUserId`, `source`, `Look`, `rebuild`, `Owner`, `retryAt`, `Body`, `_removed`, `knock`, `since`, `nextUpdate`, `lastUpdate`, `teardown`, `_setRig`, `RigType`, `HumanoidRigType`, `partialWarned`, `format`, `whole`, `Kind`, `OwnerUserId`, `GetPlayerByUserId`, `Archivable`, `install`, `build`, `AvatarUserId`, `GetHumanoidDescriptionFromUserIdAsync`, `HumanoidDescription`, `CreateHumanoidModelFromDescriptionAsync`, `fallingBack`, `Fallback`, `fallback`, `LocalTransparencyModifier`, `KillEffectHidden`, `lookWarned`, `Animator`, `concat`, `Head`, `IsInflatableDecoy`, `Massless`

### `ReplicatedStorage.ChickenOrHero.Collectibles.CandyCornConfig` (ModuleScript)

`freeze`, `EmptyChance`, `Layouts`, `StackValues`, `MaxGemsPerCrossing`, `EdgeMargin`, `SafeMargin`, `Separation`, `HoverHeight`, `PickupRadius`, `VerticalTolerance`, `PollInterval`, `MaxSampleGap`, `MaxSampleSpeed`, `PositionSlack`, `MaxVisibleDistance`, `Weight`, `Value`

### `ReplicatedStorage.ChickenOrHero.Collectibles.GemConfig` (ModuleScript)

`freeze`, `EmptyChance`, `Layouts`, `StackValues`, `MaxGemsPerCrossing`, `EdgeMargin`, `SafeMargin`, `Separation`, `HoverHeight`, `PickupRadius`, `VerticalTolerance`, `PollInterval`, `MaxSampleGap`, `MaxSampleSpeed`, `PositionSlack`, `MaxVisibleDistance`, `Weight`, `Value`

### `ReplicatedStorage.ChickenOrHero.Crates.CrateCatalog` (ModuleScript)

`Crates`, `number`, `Entries`, `Weight`, `Kind`, `Emote`, `random`, `poseEmote`, `Bundles`, `offer`, `Order`, `DuplicateGems`, `Basic2`, `Premium2`, `Ember`, `Celestial`, `GymEmote`, `Common`, `Rare`, `Epic`, `Legendary`, `Mythical`, `Basic`, `Premium`, `OldBasicCrate`, `Coins`, `ProductId`, `fromRGB`, `Skin`, `CopperBite`, `Rarity`, `Ashsteel`, `IronFang`, `ForestEdge`, `AmberSting`, `RoseQuartz`, `TidalShard`, `VenomThorn`, `MoltenFang`, `StormTalon`, `OldPremiumCrate`, `SpectralReaper`, `Moonfang`, `SolarPhoenix`, `VoidSovereign`, `GlacialCrown`, `CelestialDragon`, `BasicCrate`, `FieldBowie`, `TacticalTanto`, `TrenchKnife`, `Kukri`, `ButterflyKnife`, `ClawKarambit`, `PremiumCrate`, `Gems`, `GlacialFang`, `SolarFlare`, `Stormcaller`, `PhoenixTalon`, `Voidrend`, `PrismEdge`, `EmberCrate`, `EndsAt`, `CelestialCrate`, `EmoteCrate`, `OpenAnywhere`, `BoogieDown`, `Skipping`, `PenguinWalk`, `RussianWalk`, `Distraction`, `OhARat`, `RatDance`, `Caffeinated`, `FastDancer`, `Marisa`, `CaliforniaGirls`, `YaYaYing`, `Marat`, `EDanceSupreme`, `DaBabyDance`, `GymJumpingJacks`, `GymPushUps`, `GymSkippingRope`, `GymToeTouches`, `GymAirSquats`, `GymWaterBreak`, `GymDribble`, `GymHeadstand`, `GymFlex`, `GymHulaHoop`, `GymAerobicsGroove`, `GymSneakerSqueak`, `GymPomPomRoutine`, `GymTitleBeltStrut`, `GymHalftimeShow`, `HalloweenEmoteCrate`, `Halloween`, `CandyCorn`, `ZombieShuffle`, `GhostFloat`, `CandyToss`, `WitchsBrew`, `JumpScare`, `SpiritPossession`, `RiseFromTheGrave`, `HalloweenEmote`, `TrickCrate`, `MummyWrapShiv`, `BedsheetBoo`, `CandyCornCleaver`, `ToffeeAppleStabber`, `PumpkinSpiceShank`, `FakeFinger`, `FunSizeFang`, `JackInTheBox`, `PlasticPitchfork`, `ChatteringTeeth`, `PumpkinPieSlicer`

### `ReplicatedStorage.ChickenOrHero.Crates.CrateLuck` (ModuleScript)

`Boost`, `Rarity`, `boost`, `workspace`, `TrollLuck`, `TrollLuckUntil`, `number`, `floor`, `clamp`, `current`, `ClanLuck`, `ClanLuckUntil`, `Entries`, `create`, `Weight`, `weights`, `remap`, `lucky`, `luckNow`, `check`, `watch`, `revealTag`, `Step`, `freeze`, `Common`, `Rare`, `Epic`, `Legendary`, `Mythical`

### `ReplicatedStorage.ChickenOrHero.Crates.CrateReel` (ModuleScript)

`surface`, `cardSequence`, `prize`, `Skin`, `rarity`, `Common`, `Rarity`, `describe`, `destroy`, `releaseHero`, `generation`, `connection`, `sounds`, `tweens`, `timers`, `cancel`, `ClearAllChildren`, `later`, `sound`, `fromScale`, `upper`, `RarityStamp`, `duplicate`, `Quart`, `fromOffset`, `RarityBurst`, `corner`, `Fade`, `NumberSequenceKeypoint`, `ShockRing`, `stroke`, `Outline`, `SkinOutline`, `Glint`, `Emote`, `WinningEmote`, `WinningKnife`, `Halo`, `ImageColor3`, `clamp`, `floor`, `WinFlash`, `emote`, `crate`, `Gold`, `ReelWindow`, `ClipsDescendants`, `Strip`, `Card`, `Tint`, `RarityLine`, `Art`, `Pointer`, `Diamond`, `CrateTick`, `CrateOpen`, `CrateReward`, `GetService`, `ChickenOrHero`, `OldUIReskin`, `__mode`

### `ReplicatedStorage.ChickenOrHero.Crates.CrateRollConfig` (ModuleScript)

`freeze`, `ReelWidth`, `PumpkinSize`, `WheelWidth`, `NameplateGap`, `HeadOffset`, `MaxDistance`, `SendRadius`, `MaxShows`, `DetailDistance`, `MinCameraDistance`, `HoldSeconds`, `RareHoldSeconds`, `SoundMinDistance`, `SoundMaxDistance`

### `ReplicatedStorage.ChickenOrHero.Crates.OverheadRoll` (ModuleScript)

`fromScale`, `placer`, `corner`, `StrokeSizingMode`, `ScaledSize`, `stroke`, `label`, `tween`, `ImageTransparency`, `fadeOut`, `PreviewRotation`, `Angles`, `Weapons`, `Blade`, `Preview`, `fromRGB`, `viewport`, `VectorToWorldSpace`, `cross`, `camera`, `extent`, `reach`, `knifeView`, `lookAt`, `orbit`, `PreviewCharacter`, `Animator`, `track`, `emoteView`, `Entries`, `Emote`, `Skin`, `rarity`, `Common`, `Rarity`, `prizeOf`, `Adornee`, `SizeOffset`, `StudsOffset`, `StudsOffsetWorldSpace`, `MaxDistance`, `AlwaysOnTop`, `LightInfluence`, `ClipsDescendants`, `ZIndexBehavior`, `HeadOffset`, `Sibling`, `billboard`, `PlayerOverhead_`, `NameplateGap`, `plateParts`, `plateTop`, `muted`, `Stop`, `holder`, `CrateRollSounds`, `RollOffMode`, `RollOffMinDistance`, `RollOffMaxDistance`, `SoundMinDistance`, `SoundMaxDistance`, `destroy`, `soundBank`, `number`, `Count`, `floor`, `countBadge`, `Quart`, `RarityBurst`, `NumberSequenceKeypoint`, `ShockRing`, `Glints`, `Glint`, `burst`, `closed`, `RareGlow`, `ImageColor3`, `rareGlow`, `clamp`, `textSize`, `Card`, `RarityLine`, `Art`, `upper`, `frame`, `fades`, `buildCard`, `setAlpha`, `clock`, `CrateTick`, `WinFlash`, `CrateReward`, `Jackpot`, `reveal`, `WinningEmote`, `WinningKnife`, `Sunray`, `Halo`, `Content`, `CrateOpen`, `DetailDistance`, `MinCameraDistance`, `dispose`, `crate`, `prize`, `Legendary`, `Mythical`, `RareHoldSeconds`, `HoldSeconds`, `ReelWidth`, `CrateRoll_`, `Canvas`, `sounds`, `loops`, `opener`, `__mode`, `create`, `count`, `Pointer`, `Diamond`

### `ReplicatedStorage.ChickenOrHero.Emotes.DailyEmotes` (ModuleScript)

`bit32`, `lshift`, `clone`, `shuffled`, `workspace`, `floor`, `IsStudio`, `StudioDayOffset`, `number`, `secondsLeft`, `basePick`, `Slots`, `HalloweenChance`, `halloweenPick`, `pickAt`, `clamp`, `Cards`, `picks`, `GraceSeconds`, `ProductGrants`, `DailyCard`, `sharedProduct`, `forProduct`, `GetService`, `EmoteCatalog`, `Game`, `CandyCorn`, `Coins`, `Gems`, `Robux`, `Entries`, `Pools`, `Halloween`

### `ReplicatedStorage.ChickenOrHero.Emotes.EmoteCatalog` (ModuleScript)

`Test`, `Entries`, `ProductId`, `number`, `ProductGrants`, `Emote`, `UniverseId`, `ProductUniverse`, `Weapons`, `match`, `showClip`, `format`, `asset`, `whole`, `SkinCatalog`, `KnifeKind`, `knifeKind`, `Ultimate`, `Free`, `emotes`, `OutbreakMilestone`, `Game`, `OutbreakConfig`, `reached`, `workspace`, `owned`, `Knife`, `UnlockedBy`, `PlaysWith`, `Kind`, `ultimate`, `bundle`, `playsWith`, `holdsIdle`, `Prop`, `lower`, `SourceName`, `concat`, `PropDual`, `dualWield`, `Equipped`, `IsDualWield`, `Animation`, `Assets`, `AnimationId`, `assetId`, `soundId`, `ExtraSounds`, `Delay`, `soundIds`, `Intro`, `introId`, `ComingSoon`, `Clips`, `StudioPreview`, `IsStudio`, `available`, `Rarity`, `rarity`, `inCrate`, `DailyShared`, `sharedProduct`, `CrateOnly`, `Halloween`, `Cards`, `Robux`, `CardPrices`, `price`, `GetService`, `PlaceId`, `FFlags`, `Slots`, `Welcome`, `IdleSit`, `Cheers`, `CheerVolume`, `LiveFlagsApply`, `EmotesEnabled`, `Floss`, `Legendary`, `Dougie`, `Rare`, `Laugh`, `SixtySeven`, `OhARat`, `Distraction`, `BoogieDown`, `RatDance`, `Caffeinated`, `CaliforniaGirls`, `YaYaYing`, `Marisa`, `FastDancer`, `Skipping`, `PenguinWalk`, `RussianWalk`, `Marat`, `EDanceSupreme`, `DaBabyDance`, `ScarecrowPose`, `Common`, `Source`, `SpookyTiptoe`, `Anchor`, `PumpkinCarve`, `WerewolfTransform`, `Epic`, `PoltergeistThrow`, `ZombieShuffle`, `GhostFloat`, `CandyToss`, `WitchsBrew`, `JumpScare`, `SpiritPossession`, `RiseFromTheGrave`, `CardTrick`, `Length`, `Pieces`, `PieceJoints`, `Looks`

### `ReplicatedStorage.ChickenOrHero.Emotes.EmotePieces` (ModuleScript)

`Looks`, `Prop`, `BALL_SKINS`, `Knife`, `isBallEmote`, `GetService`, `EquippedKnife`, `BALL_KNIVES`, `equippedBall`, `Weapons`, `Blade`, `ballSource`, `SpecialMesh`, `MeshType`, `FileMesh`, `MeshId`, `TextureID`, `TextureId`, `MeshSize`, `SurfaceAppearance`, `EquippedBall`, `Massless`, `CastShadow`, `ballLook`, `Part0`, `Part1`, `dressBall`, `Shape`, `PartType`, `Ball`, `dressKnife`, `Assets`, `Handle`, `BladeWeld`, `JointInstance`, `looksOf`, `LooksBy`, `RankShowcase`, `RankTier`, `Pieces`, `PieceJoints`, `match`, `EmotePiece`, `identity`, `HidePieces`, `PieceEmote`, `HIDE_TAG`, `AddTag`, `KnifeVisibility`, `BladeLength`, `PieceWeld`, `build`, `clipId`, `Animator`, `Intro`, `Animation`, `GetPlayingAnimationTracks`, `AnimationId`, `WeightCurrent`, `IsPlaying`, `Transform`, `strip`, `EmotePieceHidden`, `Basketball`, `Volleyball`, `Futbol`, `DribbleBall`, `Football`, `Dodgeball`, `__mode`, `freeze`

### `ReplicatedStorage.ChickenOrHero.Emotes.EmotePlayback` (ModuleScript)

`clock`, `Length`, `ContentProvider`, `GetService`, `PreloadAsync`, `Animation`, `AnimationId`, `preload`, `Cheers`, `random`, `cheer`, `finish`, `EmoteId`, `EmoteCheer`, `CheerVolume`, `RollOffMaxDistance`, `DidLoop`, `Stopped`, `AncestryChanged`, `cheering`, `IsPlaying`, `assetId`, `asEmote`, `Animator`, `AnimationPlayed`, `joined`, `HidePieces`, `introId`, `fetchOwned`, `OnClientEvent`, `listen`, `IsClient`, `Entries`, `Knife`, `Kind`, `Prop`, `EmoteEvent`, `owned`, `Weapons`, `ArmoryEvent`, `emotes`, `EmoteSync`, `start`, `watch`, `AnimationClipProvider`, `RegisterAnimationClip`, `LoadAnimation`, `StudioPreview`, `IsStudio`, `Clips`, `ValleyEmote_`, `AnimationPriority`, `Action4`, `Priority`, `ValleyEmoteIntro_`, `intro`, `Stop`, `dispose`, `EmoteCatalog`

### `ReplicatedStorage.ChickenOrHero.Emotes.EmoteSync` (ModuleScript)

`EmoteVolume`, `number`, `clamp`, `EmoteSoundsMuted`, `MusicMuted`, `settingsLevel`, `IsDescendantOf`, `EmoteEffects`, `levelFor`, `Animator`, `assetId`, `ValleyEmote_`, `GetPlayingAnimationTracks`, `Animation`, `AnimationId`, `emoteTrack`, `EmoteBaseVolume`, `target`, `effects`, `register`, `registerExtra`, `leader`, `position`, `group`, `track`, `Length`, `sound`, `TimeLength`, `apply`, `EmoteId`, `EmoteSound`, `EmoteStartedAt`, `UserId`, `collect`, `workspace`, `listener`, `EmoteSoundExtra`, `watch`, `joined`, `IsClient`, `start`, `GetService`, `EmoteCatalog`

### `ReplicatedStorage.ChickenOrHero.Emotes.EmoteVFX` (ModuleScript)

`VFX`, `Assets`, `template`, `EmitAt`, `number`, `EmitIn`, `Intro`, `Loop`, `defaultPhase`, `phase`, `groups`, `collect`, `track`, `scaled`, `scale`, `Bone`, `character`, `folder`, `loopId`, `introId`, `mounted`, `pieces`, `chain`, `assetId`, `GetScale`, `Torso`, `Root`, `RootOffset`, `identity`, `EmoteVFX_`, `Part0`, `Part1`, `mount`, `EquippedDagger`, `Arm`, `rightChain`, `Pieces`, `EmotePiece`, `HolderSize`, `Bones`, `mountLate`, `Animator`, `GetPlayingAnimationTracks`, `Animation`, `AnimationId`, `WeightTarget`, `update`, `unmount`, `EmoteCatalog`, `freeze`

### `ReplicatedStorage.ChickenOrHero.Game.AbilityRule` (ModuleScript)

`PracticeActive`, `practising`, `NoAbilities`, `AbilitiesFor`, `GameRole`, `blocked`, `Ranked`, `knifeBlocked`, `watch`

### `ReplicatedStorage.ChickenOrHero.Game.BladeBallConfig` (ModuleScript)

`freeze`, `Hearts`, `Duration`, `RingRadius`, `RingMin`, `Radius`, `ServeHeight`, `ServeSeconds`, `AimHeight`, `StartSpeed`, `SpeedPerBlock`, `MaxSpeed`, `BlueSpeed`, `SpeedResponse`, `PaceResponse`, `Homing`, `NearHoming`, `NearRange`, `CurveSeconds`, `CurveHoming`, `LookBlend`, `LookUpMax`, `LookDownMax`, `LaunchUp`, `LaunchUpMinScale`, `ArcHeight`, `ArcFrom`, `ArcFull`, `Gravity`, `FloorBounce`, `FloorFriction`, `WallBounce`, `Ceiling`, `BlockRange`, `BlockRangePerSpeed`, `BlockRangeMax`, `Window`, `MissCooldown`, `BlockCooldown`, `MaxRewind`, `HitRadius`, `HitGraceMin`, `HitGraceMax`, `HitSlow`, `HitKnock`, `OvertimeAfter`, `OvertimeRamp`, `SnapshotRate`, `KnockoutRagdoll`, `HitCoins`, `KnockoutCoins`, `WinnerGems`, `Block`, `Slash`, `Hit`, `Serve`, `Sounds`

### `ReplicatedStorage.ChickenOrHero.Game.BladeBallPhysics` (ModuleScript)

`speed`, `floor`, `NearRange`, `clamp`, `Homing`, `NearHoming`, `StartSpeed`, `homing`, `BlockRangeMax`, `BlockRange`, `BlockRangePerSpeed`, `blockRange`, `SpeedResponse`, `ArcFrom`, `ArcFull`, `ArcHeight`, `CurveHoming`, `Gravity`, `PaceResponse`, `Radius`, `FloorFriction`, `FloorBounce`, `Ceiling`, `WallBounce`, `PointToObjectSpace`, `VectorToObjectSpace`, `PointToWorldSpace`, `VectorToWorldSpace`, `LookDownMax`, `LookUpMax`, `LookBlend`, `LaunchUp`, `LaunchUpMinScale`, `launch`, `HitKnock`, `knock`, `freeze`

### `ReplicatedStorage.ChickenOrHero.Game.BloodMoonConfig` (ModuleScript)

`Period`, `Duration`, `window`, `season`, `CandyCorn`, `CountdownSeconds`, `HauntChance`, `CandyMultiplier`, `Fade`, `Howl`, `freeze`

### `ReplicatedStorage.ChickenOrHero.Game.BossCombat` (ModuleScript)

`ChickenOrHero`, `Game`, `BossFighting`, `fighting`, `GameRole`, `attacker`, `record`, `freeze`

### `ReplicatedStorage.ChickenOrHero.Game.CandyCorn` (ModuleScript)

`number`, `whole`, `GetService`, `FFlags`, `Halloween`, `EndsAt`, `candyCornEvent`, `EventId`, `candyCorn`, `balance`, `spend`, `normalize`, `Halloween2026`, `DateTime`, `fromUniversalTime`, `UnixTimestamp`, `freeze`, `KillDrop`, `QuestMin`, `QuestMax`, `QuestJourneyXP`, `Base`, `Safe`, `Rescue`, `Catch`

### `ReplicatedStorage.ChickenOrHero.Game.CarouselConfig` (ModuleScript)

`Turn`, `RoundGrowth`, `rateFor`, `CarouselRate`, `number`, `CarouselAt`, `CarouselAngle`, `angle`, `workspace`, `Map`, `Carousel`, `model`, `PointToObjectSpace`, `atan2`, `floor`, `BobUp`, `BobDown`, `BobPeriod`, `Angles`, `IsDescendantOf`, `Reach`, `FilterDescendantsInstances`, `Probe`, `onDeck`, `carry`, `Map6`, `__mode`, `RaycastParams`, `RaycastFilterType`, `Include`, `FilterType`, `RespectCanCollide`

### `ReplicatedStorage.ChickenOrHero.Game.ChronoSetup` (ModuleScript)

`FFlags`, `Chrono`, `GetService`, `IsServer`, `workspace`, `RankedServer`, `RankedTickRate`, `TickRate`, `ChronoTickRate`, `clock`, `WaitSeconds`, `number`, `chrono`, `Config`, `SetConfig`, `CHECK_NEW_VERSION`, `WARNING_SEVERITY`, `HIGH`, `REPLICATE_DEATHS`, `NONE`, `PLAYER_REPLICATION`, `AUTOMATIC`, `RegisterEntityType`, `PLAYER`, `NAME`, `MODEL_REPLICATION_MODE`, `NATIVE`, `BUFFER`, `HALF_TICK_DISTANCE`, `TICK_RATE`, `ASSEMBLY_ROOT_PART_CHECK`, `STORE_SNAPSHOTS`, `Start`, `start`, `ViewReportSeconds`

### `ReplicatedStorage.ChickenOrHero.Game.ClanConfig` (ModuleScript)

`Levels`, `level`, `nextAt`, `BaseSlots`, `LevelSlots`, `ExtraSlots`, `slots`, `Colors`, `color`, `number`, `Gold`, `Silver`, `Bronze`, `Top10`, `Top25`, `format`, `battleBorder`, `BorderById`, `match`, `fromRGB`, `Animated`, `Plain`, `border`, `PlaceArt`, `LevelArt`, `floor`, `clamp`, `Infill`, `Shop`, `emblemArt`, `Products`, `ProductId`, `TestProductId`, `productKey`, `TestUniverseId`, `productId`, `DayOffset`, `dayEnds`, `WeekOneStart`, `weekEnds`, `target`, `Challenges`, `FeaturedRound`, `FeaturedMap`, `remove`, `BattleWeeks`, `DefaultBattle`, `battle`, `Coins`, `Tokens`, `ClanChampions`, `placeReward`, `NameMin`, `NameMax`, `cleanName`, `upper`, `TagMin`, `TagMax`, `cleanTag`, `CreateCost`, `MinLevel`, `InviteSeconds`, `LogSize`, `MaxRequests`, `freeze`, `Open`, `Invite`, `Locked`, `Joins`, `JoinNames`, `Leader`, `Officer`, `Member`, `Roles`, `GroupSurvivor`, `RankedMatch`, `RankedWin`, `Challenge`, `Points`, `TagColor`, `DecalIcon`, `Shimmer`, `Wall`, `GoldTag`, `Unlocks`, `LuckPerLevel`, `TopLuck`, `LuckBoost`, `BoostSeconds`, `Ice`, `Aurora`, `Violet`, `Ember`, `Rose`, `Crimson`, `Snow`, `GoldColor`, `Icons`, `Default`, `Price`, `Glacier`, `Emblem`, `Ribbon`, `RoyalCrest`, `Inferno`, `ShadowReaper`, `NeonCircuit`, `Sakura`, `GalaxyVoid`, `Thunderstorm`, `GoldenChampion`, `Banners`, `DefaultEmblem`, `EmblemSize`, `BannerById`, `Frost`, `Toxic`, `Royal`, `Borders`, `PlaceColors`

### `ReplicatedStorage.ChickenOrHero.Game.CombatClaimMath` (ModuleScript)

`number`, `finite`, `vector`, `character`, `reset`, `relocation`, `lives`, `compatible`, `position`, `consider`, `clamp`, `locate`, `segment`, `ageLimit`, `freeze`

### `ReplicatedStorage.ChickenOrHero.Game.CombatPrediction` (ModuleScript)

`workspace`, `clock`, `MovementReset`, `CombatRelocation`, `sample`, `number`, `resolve`, `ClientBot`, `ofModel`, `MovementLocked`, `isActive`, `victim`, `UserId`, `BotUserId`, `validIds`, `notify`, `subscribe`, `IsPlaying`, `Stop`, `stopTrack`, `LocalMeleeActive`, `LocalMeleeStartedAt`, `LocalMeleeDirection`, `LocalMeleePhase`, `clearLocal`, `character`, `tracks`, `assets`, `releaseAnimation`, `Animator`, `animator`, `retryAt`, `knife`, `prepareAnimation`, `EquippedDagger`, `default`, `Length`, `Animation`, `CoH_Predicted`, `AnimationId`, `Stab`, `timing`, `LoadAnimation`, `Actions`, `priority`, `Priority`, `looped`, `ensureTracks`, `stabTiming`, `Melee`, `reported`, `nearest`, `blockedBy`, `nearestForward`, `nearestSide`, `width`, `overlap`, `format`, `confirmed`, `unconfirmed`, `diagnose`, `Windup`, `attack`, `endAttack`, `cancel`, `startedAt`, `starts`, `vector`, `direction`, `previous`, `targets`, `targetIds`, `canonicalId`, `updateAttack`, `reason`, `ActiveDuration`, `reconcile`, `start`, `predicted`, `Recovery`, `reset`, `relocation`, `visualElapsed`, `createdAt`, `begin`, `position`, `height`, `forwardStart`, `forwardEnd`, `debugAttacks`, `meleeRemaining`, `bounds`, `BigDaggerActive`, `forActor`, `BigDagger`, `Reach`, `meleeBox`, `AdminMatchMode`, `FFACatchers`, `IsBot`, `GameRole`, `FFAInvincible`, `ClientBots`, `FilterDescendantsInstances`, `updateTargets`, `areset`, `arelocation`, `vreset`, `vrelocation`, `clamp`, `sweep`, `CollisionGroup`, `GetFullName`, `target`, `targetId`, `targetAt`, `origin`, `targetPosition`, `previousOrigin`, `previousTargetPosition`

### `ReplicatedStorage.ChickenOrHero.Game.ConnectionQualityConfig` (ModuleScript)

`freeze`, `HighPingMs`, `HighPingSamples`, `PingSampleSeconds`, `PromptCooldown`, `ChatPromptCooldown`

### `ReplicatedStorage.ChickenOrHero.Game.ContactCatchConfig` (ModuleScript)

`GetService`, `FFlags`, `freeze`, `SampleInterval`, `HandRadius`, `HitHalfWidth`, `RunnerRadius`, `ContactPadding`, `MinForward`, `Height`, `OverlapRadius`, `BoxScale`, `BotBoxScale`, `ReachDistance`, `ReachHalfAngle`, `ReachFadeRate`, `TrackingWeight`, `WindupWeight`, `CommitBaseDistance`, `CommitLeadTime`, `CommitDistance`, `CommitHalfAngle`, `Windup`, `ActiveDuration`, `Recovery`, `WindupAimLimit`, `WindupAimRate`, `MaxObservedSpeed`, `MaxSweepGap`, `MaxSweepDistance`, `ServerHits`

### `ReplicatedStorage.ChickenOrHero.Game.ContactCatchGeometry` (ModuleScript)

`Height`, `ReachDistance`, `ReachHalfAngle`, `inReach`, `MaxObservedSpeed`, `clamp`, `CommitDistance`, `CommitBaseDistance`, `HandRadius`, `CommitLeadTime`, `commitDistance`, `atan2`, `fromAxisAngle`, `WindupAimLimit`, `WindupAimRate`, `Windup`, `steer`, `CommitHalfAngle`, `canCommit`, `sweep`, `bounds`, `Melee`, `contains`, `HitReplayMath`

### `ReplicatedStorage.ChickenOrHero.Game.CrossyRoadMotion` (ModuleScript)

`speed`, `interval`, `direction`, `clamp`, `floor`, `samples`, `center`, `position`, `contact`, `number`, `finite`, `vector`

### `ReplicatedStorage.ChickenOrHero.Game.DonkeyKongMotion` (ModuleScript)

`bounce`, `speed`, `length`, `clamp`, `points`, `floor`, `Radius`, `position`, `contact`, `HitRadius`, `Barrel`

### `ReplicatedStorage.ChickenOrHero.Game.FallenKingBossConfig` (ModuleScript)

`Phases`, `Until`, `phase`, `Summon`, `Luck`, `GameId`, `PlaceId`, `GetService`, `FFlags`, `FallenKingBoss`, `Map1`, `MapId`, `Map7`, `LiveSeconds`, `ShieldCatchUp`, `SummonSeconds`, `SummonHealthPerPlayer`, `SummonHealthMin`, `Cutscene`, `EventStart`, `Seconds`, `HandBack`, `Lead`, `SendLead`, `StudioSendLead`, `CoverFade`, `LightingFade`, `CoverSeconds`, `CoverLimit`, `PreloadSeconds`, `CastSeconds`, `Cast`, `Dress`, `Order`, `Spots`, `KingSpot`, `Keep`, `Hide`, `LateStart`, `Teasers`, `zstrxz`, `graseterga2`, `demlightt`, `tenosicks`, `gabriel`, `NvrLvcky`, `OFFICIALFAYYY`, `stilivs`, `lookAt`, `Rig`, `FallenKingFight`, `Before`, `Intro`, `FadeIn`, `FadeOut`, `Music`, `WalkSpeedLastStand`, `CatchRadius`, `BodyRadius`, `Wall`, `TouchRadius`, `DazeSeconds`, `DazeFlight`, `Grace`, `King`, `Walk`, `TwinSweep`, `GraveLunge`, `SummonCourt`, `ShrineSlam`, `AxeRain`, `DisarmedStart`, `DisarmedLoop`, `ShieldBreakStart`, `ShieldBreakLoop`, `Death`, `Animations`, `Sounds`, `Every`, `LastStandEvery`, `Warn`, `Radius`, `StrikeAt`, `Length`, `Width`, `Speed`, `Count`, `MaxAlive`, `Court`, `KnifeRain`, `PerPlayer`, `Zombies`, `Skeletons`, `Waves`, `IdleSeconds`, `RoarSeconds`, `Knives`, `MaxKnives`, `OnPlayers`, `Circles`, `Disarmed`, `DisarmedMultiplier`, `HitShare`, `RegenShare`, `RegenPerSecond`, `RegenDelay`, `GuardEvery`, `Stun`, `Few`, `FewShare`, `Many`, `ManyShare`, `Shrines`, `FireEvery`, `FireballSpeed`, `FireballRadius`, `Turrets`, `ShrinkSeconds`, `MinRadiusShare`, `CatchSeconds`

### `ReplicatedStorage.ChickenOrHero.Game.FallenKingConfig` (ModuleScript)

`GetService`, `FFlags`, `Halloween`, `IsStudio`, `PlaceId`, `StartsAt`, `EndsAt`, `TrackEndsAt`, `TrackStartsAt`, `clamp`, `OverMax`, `progress`, `Stages`, `stage`, `Personal`, `personal`, `LanternLevels`, `level`, `SpawnsAt`, `Target`, `PickupRadius`, `ClaimSeconds`, `DepositRadius`, `Float`, `SpawnDelay`, `SyncSeconds`, `ThroneName`, `Throne`, `DateTime`, `fromUniversalTime`, `UnixTimestamp`, `Reward`, `Coins`, `Crate`, `HalloweenTrick`, `Crates`, `HalloweenTreat`, `Soulkeeper`, `Sub`, `Emote`, `KneelToTheKing`, `Burrow`, `Ability`, `Line`, `Candy`, `SoulBearer`, `BossBonus`

### `ReplicatedStorage.ChickenOrHero.Game.GameConfig` (ModuleScript)

`Movement`, `MovementConfig`, `SpeedScale`, `freeze`, `MaxMatchPlayers`, `MinPlayers`, `Countdown`, `SetupTime`, `FirstSetupTime`, `ResultsTime`, `PostMatchLobbyTime`, `SelectionTime`, `ChoiceTime`, `HeroTime`, `RunTime`, `CleanEscapesToWin`, `LateJoinAsCatcher`, `PlayerCollisions`, `Tick`, `MapName`, `Map1`, `CharacterReadyTimeout`, `Tackle`, `Duration`, `Recovery`, `Cooldown`, `DistanceMultiplier`, `RunDistanceMultiplier`, `BoostStrength`, `MaxDistance`, `Animation`, `DaggerDive`, `Distance`, `Width`, `Height`, `Reach`, `RunnerRadius`, `Variants`, `HumanBox`, `MinSpeedRatio`

### `ReplicatedStorage.ChickenOrHero.Game.GhostTraderConfig` (ModuleScript)

`Cursed`, `Normal`, `number`, `weight`, `Rewards`, `chance`, `column`, `floor`, `SkipSteps`, `clamp`, `skipStep`, `TestProductId`, `GameId`, `TestUniverseId`, `ProductId`, `skipProduct`, `skipByProduct`, `Cards`, `CooldownSeconds`, `CursedChance`, `KeyCap`, `Reach`, `Zombie`, `Skeleton`, `KeyDrops`, `KeyDropAmount`, `KeyIcon`, `LastManStandingKeys`, `MatchKeysMinPlayers`, `WheelKeys`, `UniverseId`, `Price`, `Common`, `Rare`, `Epic`, `Legendary`, `Mythical`, `fromRGB`, `RarityColors`, `Coins750`, `Kind`, `Coins`, `Amount`, `Rarity`, `Coins2000`, `Candy300`, `Candy`, `Candy1000`, `Gems50`, `Gems`, `Gems150`, `Keys2`, `Keys`, `Keys3`, `TrickOrTreatKey`, `CrateKey`, `Crate`, `TrickOrTreat`, `EmoteCrateKey`, `HalloweenEmote`, `Keyholder`, `TitleId`, `CardTrick`, `Emote`, `EmoteId`, `SkeletonKey`, `Knife`, `Skin`, `Ghostlock`, `LastDoor`, `TheLastDoor`, `freeze`

### `ReplicatedStorage.ChickenOrHero.Game.HalloweenShopConfig` (ModuleScript)

`bit32`, `lshift`, `create`, `DateTime`, `fromUniversalTime`, `UnixTimestamp`, `nthSunday`, `pacificOffset`, `Day`, `ResetHour`, `dayStart`, `floor`, `TitleStart`, `TitleDays`, `RotatingTitles`, `title`, `badge`, `color`, `price`, `rotating`, `rotatesAt`, `RotatingEmotes`, `emote`, `Emote`, `rotation`, `Emotes`, `EmoteCatalog`, `Rarity`, `Common`, `rarity`, `EmotePrices`, `Items`, `Knife`, `stock`, `Packs`, `productId`, `testProductId`, `packByProduct`, `GameId`, `TestUniverseId`, `packProduct`, `HalloweenStore`, `Store`, `freeze`, `field`, `CandyCorn`, `fromRGB`, `coins`, `Coins`, `Currency`, `ComingSoon`, `EndsAt`, `HalloweenEmoteCrate`, `Crate`, `model`, `crate`, `HalloweenEmote`, `TreatCrate`, `HalloweenTreat`, `TrickCrate`, `HalloweenTrick`, `Hexflask`, `knife`, `LIMITED`, `subtitle`, `endsAt`, `HeadlessHorseman`, `Boo`, `VampireLord`, `GraveRobber`, `PumpkinKing`, `MonsterMash`, `TheUndying`, `CandyCollector`, `Hexed`, `BatOutOfHell`, `Cobweb`, `ScarecrowPose`, `SpookyTiptoe`, `PumpkinCarve`, `WerewolfTransform`, `PoltergeistThrow`, `Rare`, `Epic`, `Legendary`, `GraceSeconds`, `CandyHandful`, `Handful`, `amount`, `robux`, `CandyBag`, `CandyCauldron`, `Cauldron`

### `ReplicatedStorage.ChickenOrHero.Game.HauntConfig` (ModuleScript)

`freeze`, `Chance`, `TestChance`, `TestPlaceId`, `Growth`, `Cap`, `Rounds`, `Cooldown`, `AttackDelay`, `CutsceneSeconds`, `HitsToDown`, `ChaserDown`, `Down`, `StrikeReach`, `SpawnClearance`, `Zombie`, `Skeleton`, `Sounds`, `Anims`, `Speed`, `Aggro`, `Reach`, `Windup`, `BiteRange`, `ThrowMin`, `ThrowMax`, `KeepAway`, `HeadSpeed`, `HeadRadius`, `Sting`, `Rise`, `ZombieGroan`, `ZombieGroan2`, `ZombieGasp`, `ZombieBite`, `ZombieDeath`, `SkeletonRattle`, `SkeletonThrow`, `SkeletonBreak`, `SkeletonBreak2`, `KillConfirm`, `KnifeStab`, `Impact`, `Downed`, `Idle`, `ZombieWalk`, `ZombieSummon`, `SkeletonWalk`, `SkeletonSummon`

### `ReplicatedStorage.ChickenOrHero.Game.HitReplayMath` (ModuleScript)

`vector`, `Melee`, `RunnerRadius`, `ContactPadding`, `BoxScale`, `width`, `height`, `overlap`, `HitHalfWidth`, `Height`, `MinForward`, `HandRadius`, `OverlapRadius`, `Width`, `Reach`, `bounds`, `overlapStart`, `number`, `sweep`, `clone`, `character`, `reset`, `relocation`, `position`, `sample`

### `ReplicatedStorage.ChickenOrHero.Game.MapLocator` (ModuleScript)

`ActiveMap`, `Value`, `workspace`, `IsDescendantOf`, `current`, `Lobby`, `lobby`, `activeLobby`, `Interactables`, `interactables`, `interactable`

### `ReplicatedStorage.ChickenOrHero.Game.MapVoteConfig` (ModuleScript)

`freeze`, `DefaultMap`, `Map1`, `FirstMap`, `ForcedMap`, `FirstVoteMap`, `Map9`, `BallotSize`, `VoteSeconds`, `ArrivalBreatherSeconds`, `AfterSummarySeconds`, `BackgroundBlurSize`, `ResultSeconds`, `NoAbilities`, `Maps`, `Map1NoAbilities`, `MapId`, `Every`, `Tag`, `TagColor`, `danger`, `fromRGB`, `Map2`, `Map3`, `FFlag`, `Map3Enabled`, `HOMETOWN`, `LimitedTime`, `Map4`, `Map4Enabled`, `PreviewParts`, `PreviewPerPiece`, `Map5`, `Map5Enabled`, `PreviewKeep`, `PreviewOnField`, `Names`, `Share`, `Tree1`, `Tree2`, `DeadTree`, `Map6`, `Map6Enabled`, `Map7`, `Map7Enabled`, `Map8`, `Map8Enabled`, `Map9Enabled`

### `ReplicatedStorage.ChickenOrHero.Game.MapVotePolicy` (ModuleScript)

`count`, `choose`

### `ReplicatedStorage.ChickenOrHero.Game.OutbreakConfig` (ModuleScript)

`PlaceId`, `TEST_PLACE`, `TestStartsAt`, `StartsAt`, `startsAt`, `Days`, `endsAt`, `GetService`, `FFlags`, `Halloween`, `OutbreakTestPercent`, `number`, `clamp`, `FullAfterDays`, `Curve`, `progress`, `Milestones`, `reached`, `InfectedKnife`, `Knife`, `DateTime`, `fromUniversalTime`, `UnixTimestamp`, `Candy`, `detail`, `reward`, `candy`, `title`, `PatientZero`, `Emote`, `emote`, `kills`, `crate`, `HalloweenTreat`, `PlagueBearer`, `crates`, `count`, `HalloweenTrick`, `HalloweenEmote`, `Tiers`

### `ReplicatedStorage.ChickenOrHero.Game.PracticeConfig` (ModuleScript)

`freeze`, `RoundSeconds`, `WarningSeconds`, `ResultSeconds`, `KnockdownSeconds`, `RunnerBots`, `CatcherBots`, `MaxBots`, `MaxAbilityBots`, `IdleSeconds`, `RestartSeconds`, `MapId`, `Map1`, `LeadSeconds`

### `ReplicatedStorage.ChickenOrHero.Game.PrivateHostCatalog` (ModuleScript)

`freeze`, `Modes`, `ModeNames`, `ModeMaps`, `Actions`, `Tournament`, `Normal`, `DonkeyKong`, `CrossyRoad`, `FFACatchers`, `BladeBall`, `SetMode`, `SetMap`, `SetLead`, `SetStarter`, `Freeze`, `EndMatch`, `Fly`, `Hold`, `Kick`, `Ban`, `Unban`, `Invite`, `Sync`, `TourSet`, `TourStart`, `TourEnd`, `MaxMatches`, `Tiers`, `MaxTop`, `MaxPoints`, `MaxBasePoints`, `MaxLmsPoints`, `MaxCatchPoints`, `MaxRevivePoints`, `IdleSeconds`, `Defaults`, `Abilities`, `AbilityNames`, `matches`, `basePoints`, `points`, `lmsPoints`, `catchPoints`, `revivePoints`, `abilities`, `All`, `Everyone`

### `ReplicatedStorage.ChickenOrHero.Game.PumpkinHuntConfig` (ModuleScript)

`number`, `whole`, `divide`, `Pot`, `Goal`, `KnifeChanceMin`, `KnifeChanceMax`, `chance`, `Tiers`, `From`, `clamp`, `Roll`, `Prizes`, `Weight`, `Knife`, `amount`, `slots`, `Kind`, `Amount`, `weight`, `entry`, `clone`, `ranked`, `percents`, `format`, `percentText`, `chanceText`, `floor`, `reverse`, `commas`, `short`, `Amounts`, `CooldownSeconds`, `HuntSeconds`, `KnifeDuplicateGems`, `PumpkinCap`, `HuntMap`, `check`, `EventName`, `HalloweenEventPedestal`, `Tag`, `PromptDistance`, `Unavailable`, `freeze`, `Map5`, `PerPlayer`, `Speed`, `MirrorSpeed`, `Front`, `Spread`, `Aggro`, `Leash`, `WanderSpeed`, `WanderRadius`, `WanderPause`, `RiseSeconds`, `TellAfter`, `TellWarn`, `LungeSpeed`, `LungeSeconds`, `LungeReach`, `LungeCooldown`, `BreakRange`, `DashAfter`, `SpawnClearance`, `BodyGoneSeconds`, `People`, `HitsToOut`, `HitGrace`, `Idle`, `Walk`, `Rise`, `Lunge`, `Anims`, `PumpkinSovereign`, `RestrictedCoins`, `Spin`, `Spins`, `GemBoost`, `GemBoostMinutes`, `Gems100`, `Gems`, `Candy750`, `CandyCorn`, `Candy250`, `GhostKey`, `GhostKeys`, `Gems50`, `Gems25`, `Plain`, `fromRGB`, `Lucky`, `Blessed`, `MAXED`, `Sacrifice`, `Tell`, `Hit`, `AnkleBreak`, `HeadPop`, `Haunted`, `Collect`, `Coins`, `Sounds`

### `ReplicatedStorage.ChickenOrHero.Game.RandomPrizePolicy` (ModuleScript)

`PlaceId`, `NoRandomPrizesTest`, `boolean`, `testSwitch`, `Player`, `restricted`, `Fire`, `settle`, `GetPolicyInfoForPlayerAsync`, `ArePaidRandomItemsRestricted`, `watch`, `IsServer`, `start`, `GetService`, `PolicyService`, `TestAttribute`, `BindableEvent`, `__mode`

### `ReplicatedStorage.ChickenOrHero.Game.RankedConfig` (ModuleScript)

`MinLevel`, `AccountAgeDays`, `LeaveSafeSeconds`, `HeroRevealSeconds`, `EndEventRounds`, `EndEventChaserShare`, `MaxRounds`, `RemoveIdleChasers`, `PressureStuds`, `UnpressuredCrossing`, `IdleChaserRounds`, `FlagPoints`, `FlagEasyCrossings`, `SuspectRPPerMatch`, `SuspectAverageChange`, `SuspectCrossings`, `SuspectSingleChange`, `SoftPlayStuds`, `SoftPlaySeconds`, `FeedMatches`, `MateMatches`, `DuoMatches`, `FlagFeedDays`, `QuickRunSpeed`, `QuickRunJumpStuds`, `TrendMatches`, `TrendLMS`, `TrendCatches`, `TrendQuick`, `Crossing`, `CrossingPerChasers`, `CrossingMax`, `Hero`, `HeroPerChaser`, `HeroMax`, `EndEventRound`, `Win`, `LastCaught`, `Catch`, `BountyPerCrossing`, `BountyMax`, `EndEventCatch`, `FinalCatch`, `Chaser`, `StartingChaserScale`, `StarterCatches`, `DivisionRP`, `Bronze`, `Divisions`, `Entry`, `Silver`, `Gold`, `Platinum`, `Diamond`, `Master`, `Grandmaster`, `Tiers`, `ChampionTop`, `ChampionMinTier`, `Placements`, `PlacementCap`, `TierShieldMatches`, `PreSeasonEndsUTC`, `SeasonStartHourPT`, `LaterSeasonDay`, `PRE`, `FullResetAfter`, `DivisionReward`, `Coins`, `TierRewards`, `Gems`, `Exclusive`, `SeasonRewards`, `All`, `Champion`, `Emotes`, `RankedShowcase`, `Knives`, `Extras`, `BronzeFang`, `PreseasonIcon`, `Titles`, `SilverTwins`, `Preseason`, `GoldJavelin`, `PlatinumJavelins`, `DiamondReaper`, `PodiumPose`, `MasterReaper`, `GrandmasterReaper`, `VictoryLap`, `ChampionsReaper`, `LegacyIcon`, `PreseasonRewards`, `TierIcons`, `ChampionIcon`, `fromRGB`, `TierColors`, `LobbySize`, `MinLobby`, `QueueFillSeconds`, `BotFillTo`, `BandWidenSeconds`, `NAE`, `Nearby`, `NAW`, `SAM`, `OCE`, `Europe`, `ASIA`, `Asia`, `Oceania`, `Regions`, `Region`, `NEARBY`, `Global`, `GLOBAL`, `SearchWidths`, `DefaultWidth`, `GlobalAfterSeconds`

### `ReplicatedStorage.ChickenOrHero.Game.RankedLoadout` (ModuleScript)

`number`, `level`, `Abilities`, `Kind`, `Ability`, `UseRole`, `ability`, `Items`, `Item`, `Uses`, `MaxUses`, `SoulReap`, `RescueKit`, `clean`, `Credits`, `Default`, `resolve`, `RankedConfig`, `Gear`, `GearCatalog`, `Loadout`, `freeze`

### `ReplicatedStorage.ChickenOrHero.Game.RankedRanks` (ModuleScript)

`tierIndex`, `floor`, `Divisions`, `division`, `divisionName`, `entry`, `Entry`, `DIVISIONS`, `place`, `EntryFullPlayers`, `entryFor`, `label`, `TierColors`, `color`, `month`, `pacificDaylight`, `LaterSeasonDay`, `SeasonStartHourPT`, `seasonStart`, `workspace`, `RankedSeasonShift`, `number`, `shift`, `seasonStarts`, `PRE`, `match`, `seasonNumber`, `season`, `seasonEnds`, `numbered`, `seasonName`, `GRANDMASTER`, `softReset`, `PlacementCap`, `placementRP`, `RankedConfig`, `III`, `Tiers`, `DivisionRP`, `PreSeasonEndsUTC`, `GameId`, `PlaceId`, `freeze`

### `ReplicatedStorage.ChickenOrHero.Game.RankedRegions` (ModuleScript)

`gmatch`, `NAW`, `NAE`, `SAM`, `ASIA`, `OCE`, `byOffset`, `upper`, `number`, `OFFSET`, `bit32`, `parse`, `Regions`, `concat`, `encode`, `Nearby`, `nearby`, `format`, `describe`, `SearchWidths`, `DefaultWidth`, `width`, `GLOBAL`, `NEARBY`, `GlobalAfterSeconds`, `ALL`, `accepts`, `RankedConfig`, `lshift`, `REGION`

### `ReplicatedStorage.ChickenOrHero.Game.RescueConfig` (ModuleScript)

`freeze`, `HoldSeconds`, `Range`, `MoveTolerance`, `MaxRescuesPerCrossing`, `FinishGrace`

### `ReplicatedStorage.ChickenOrHero.Game.ReviveOfferConfig` (ModuleScript)

`First`, `Later`, `offerFor`, `Rounds`, `HideBefore`, `RescueKit`, `Item`, `MEDKIT`, `BoughtText`, `GameId`, `freeze`, `ProductId`, `Price`, `WasPrice`, `Off`, `TestGameAlways`, `StudioAlways`

### `ReplicatedStorage.ChickenOrHero.Game.TackleCollision` (ModuleScript)

`RaycastParams`, `RaycastFilterType`, `Exclude`, `FilterType`, `DashDiveIgnore`, `GetTagged`, `FilterDescendantsInstances`, `RespectCanCollide`, `CollisionGroup`, `IgnoreWater`, `OverlapParams`, `MaxParts`, `params`, `overlap`, `stopped`, `lookAt`, `workspace`, `GetPartsInPart`, `Blockcast`, `Normal`, `Distance`, `clamp`, `limit`, `CollectionService`, `GetService`, `freeze`

### `ReplicatedStorage.ChickenOrHero.Game.TackleMotion` (ModuleScript)

`Duration`, `MotionBlendIn`, `MotionBrake`, `EntrySpeed`, `Distance`, `clamp`, `distance`, `speed`, `freeze`

### `ReplicatedStorage.ChickenOrHero.Game.TacklePrediction` (ModuleScript)

`cancel`, `orientation`, `velocity`, `attachment`, `character`, `TackleActive`, `TacklePredictionId`, `autoRotate`, `AutoRotate`, `finish`, `workspace`, `TackleReadyAt`, `remaining`, `direction`, `started`, `LocalTackleMotion`, `LinearVelocity`, `LocalTackleVelocity`, `Attachment0`, `ActuatorRelativeTo`, `World`, `RelativeTo`, `VelocityConstraintMode`, `Plane`, `PrimaryTangentAxis`, `SecondaryTangentAxis`, `collision`, `limit`, `speed`, `PlaneVelocity`, `ForceLimitsEnabled`, `ForceLimitMode`, `AssemblyMass`, `MaxForce`, `AlignOrientation`, `LocalTackleFacing`, `OrientationAlignmentMode`, `OneAttachment`, `Mode`, `lookAt`, `MaxTorque`, `MaxAngularVelocity`, `Responsiveness`, `TackleVariant`, `TackleStartedAt`, `TackleDirection`, `TackleDuration`, `Duration`, `TackleRecovery`, `Recovery`, `Animation`, `startMotion`, `PlatformStand`, `FloorMaterial`, `Air`, `MovementLocked`, `GearMotion`, `PredictedRocketVelocity`, `DaggerEquipped`, `DaggerState`, `Held`, `attacker`, `reason`, `MaxSpeed`, `GenerateGUID`, `requestedAt`, `elapsed`, `version`, `confirmed`, `MovementReset`, `Cooldown`, `Tackle`, `position`, `FireServer`, `begin`, `predicted`, `startedAt`, `starts`, `bounds`, `request`, `isActive`, `TackleResult`, `readyAt`, `number`, `reconcile`, `TackleEnded`, `ConfirmTimeout`, `Animator`, `prepare`, `GetService`, `ChickenOrHero`, `Game`, `GameAction`, `GameConfig`, `TacklePredictionConfig`, `TackleProfile`, `TackleMotion`, `TackleCollision`, `Movement`, `MovementProfiles`, `TackleAnimation`, `ControlGate`, `CombatPrediction`, `HitReplayMath`, `BossCombat`, `start`, `OnClientEvent`, `PreSimulation`

### `ReplicatedStorage.ChickenOrHero.Game.TacklePredictionConfig` (ModuleScript)

`freeze`, `MaxRequestAge`, `FutureTolerance`, `ConfirmTimeout`, `HistorySeconds`, `HistoryInterval`, `EntrySpeedTolerance`, `PhysicsObservationLag`, `PositionTolerance`, `SideTolerance`, `MaxSampleGap`, `MaxSweepDistance`, `ReplicationAllowance`

### `ReplicatedStorage.ChickenOrHero.Game.TackleProfile` (ModuleScript)

`clamp`, `Variants`, `MinSpeedRatio`, `clone`, `EntrySpeed`, `SpeedRatio`, `Distance`, `DistanceMultiplier`, `Duration`, `RunDistanceMultiplier`, `MotionBlendIn`, `MotionBrake`, `BoostStrength`, `MaxDistance`, `Recovery`, `freeze`

### `ReplicatedStorage.ChickenOrHero.Game.TutorialConfig` (ModuleScript)

`Crates`, `CrateCatalog`, `Halloween`, `GetService`, `FFlags`, `HalloweenShopConfig`, `EndsAt`, `HalloweenShop`, `Order`, `available`, `Crate`, `FallbackCrate`, `crateNow`, `Steps`, `index`, `Knife`, `RunnerAbility`, `ChaserAbility`, `BuyAdrenaline`, `AbilityUpgrades`, `Upgrades`, `PlayMatch`, `UpgradeRunner`, `UpgradeChaser`, `UpgradeTokens`, `HalloweenTreat`, `Basic2`, `OneHitShield`, `BearTrap`, `Adrenaline`, `Item`, `FirstDay`, `TestName`, `TutorialMode`, `ConfigKey`, `DoneText`, `freeze`

### `ReplicatedStorage.ChickenOrHero.Gear.AbilityFlair` (ModuleScript)

`Colors`, `color`, `Player`, `level`, `floor`, `clamp`, `GetPlayerByUserId`, `playerOf`, `levelBy`, `ownerActorId`, `ownerId`, `actorId`, `character`, `NumberSequenceKeypoint`, `Keypoints`, `Time`, `Value`, `Envelope`, `scaled`, `LightEmission`, `LightInfluence`, `Lifetime`, `Speed`, `SpreadAngle`, `RotSpeed`, `ZOffset`, `sparkle`, `AbilityFlair`, `workspace`, `FlairHost`, `CastShadow`, `Glint`, `Drag`, `Prism`, `setup`, `ToHex`, `remove`, `Ember`, `Acceleration`, `emberFor`, `round`, `Emit`, `Neon`, `piece`, `Angles`, `PartType`, `Cylinder`, `Shape`, `AddItem`, `pillar`, `PointLight`, `Brightness`, `Range`, `Shadows`, `flash`, `ground`, `flourish`, `FlairEmbers`, `Rate`, `FlairGlints`, `FlairLight`, `FlairShimmer`, `amount`, `SpotLight`, `SurfaceLight`, `WidthScale`, `Width0`, `Width1`, `boostOne`, `boost`, `dress`, `GetService`, `Debris`, `AbilityLevels`, `fromRGB`, `ColorSequenceKeypoint`, `Cloak`, `OneHitShield`, `TimeWarp`, `Burrow`, `FartCloud`, `SoulReap`, `PumpkinBomb`, `PumpkinBombChaser`, `InflatableDecoy`, `EmergencyAirhorn`, `PocketDoor`, `BigDagger`, `BearTrap`, `BrokenVow`, `KingsDemise`, `SpringBox`, `RufusLeash`, `BowlingBall`, `RocketShoes`, `PiratesCall`, `AlleyOop`, `WarHorn`, `Spike`, `SkateSpin`, `Slapstick`, `FrostQuake`, `freeze`, `Base`

### `ReplicatedStorage.ChickenOrHero.Gear.AbilityLevels` (ModuleScript)

`Packs`, `ProductId`, `TestProductId`, `GameId`, `TestUniverseId`, `productOf`, `freeze`, `offset`, `scale`, `bigger`, `levelId`, `Levels`, `levels`, `Items`, `floor`, `MaxLevel`, `clamp`, `clone`, `Perks`, `Fields`, `Level`, `AbilityLevel_`, `__index`, `AbilityUpgrades`, `Player`, `level`, `forActor`, `Key`, `Costs`, `Tokens`, `number`, `GetService`, `ChickenOrHero`, `Gear`, `GearCatalog`, `FFlags`, `TokenIcon`, `TokensPerUse`, `LiveUniverseId`, `Robux`, `AbilityMaster`, `Emote`, `RainingTokens`, `KingsDemise`, `Spots`, `PiratesCall`, `Cloak`, `OneHitShield`, `TimeWarp`, `Burrow`, `FartCloud`, `SoulReap`, `PumpkinBomb`, `InflatableDecoy`, `EmergencyAirhorn`, `PocketDoor`, `BigDagger`, `BearTrap`, `BrokenVow`, `SpringBox`, `RufusLeash`, `BowlingBall`, `RocketShoes`, `WarHorn`, `AlleyOop`, `SkateSpin`, `FrostQuake`, `Slapstick`, `Cooldown`, `Duration`, `Windup`, `Rewind`, `WindupSeconds`, `GraveSeconds`, `RandomMin`, `Radius`, `SlowLinger`, `SpeedBonus`, `Range`, `TakeSpeed`, `Cap`, `ChargeSeconds`, `KnockbackStuds`, `StartCharges`, `KnockbackSpeed`, `SlowSeconds`, `Width`, `BreakSeconds`, `Reach`, `StunDuration`, `TrapDuration`, `ThrowRange`, `TriggerRadius`, `SealSeconds`, `RiseSeconds`, `BurstRadius`, `Count`, `RagdollSeconds`, `HoldSeconds`, `Speed`, `TripSeconds`, `Trips`, `CarrySeconds`, `KnockSeconds`, `BoostSeconds`, `JumpScale`, `HitEvery`, `Length`, `HitWidth`, `WiderIce`, `Glacier`, `LongerKnock`, `DunkBoost`, `DunkKnock`, `Studs`, `Seconds`, `HarderToSpot`, `SpeedOnUse`, `StunOnBlock`, `ExtendOnBlock`

### `ReplicatedStorage.ChickenOrHero.Gear.AbilityUpgradeMenu` (ModuleScript)

`floor`, `reverse`, `comma`, `round2`, `spots`, `format`, `studs`, `speed`, `Base`, `Levels`, `levelId`, `fields`, `labelOf`, `count`, `Perks`, `Stats`, `changes`, `secondary`, `Order`, `Kind`, `Ability`, `UseRole`, `levels`, `abilitiesFor`, `abilityLevels`, `levelOf`, `abilityTokens`, `tokensOf`, `abilities`, `Burrow`, `workspace`, `RewardOnly`, `short`, `REWARD`, `RewardText`, `UnlockText`, `bundleOnly`, `Bundle`, `isOnSale`, `BUNDLE`, `bundle`, `locked`, `SOON`, `SoldFor`, `coins`, `price`, `Coins`, `product`, `Gems`, `ProductId`, `unlockOf`, `fetch`, `paint`, `pending`, `PriceInRobux`, `number`, `UNAVAILABLE`, `IsForSale`, `SalesEnabled`, `robuxOf`, `tween`, `panel`, `Float`, `scale`, `fromOffset`, `float`, `selected`, `picked`, `cardK`, `unownedGrid`, `corner`, `IconImage`, `Level`, `track`, `fromScale`, `Equipped`, `green`, `level`, `badge`, `buildCard`, `equip`, `robux`, `extra`, `detailX`, `Detail`, `IconBox`, `Ring`, `RingStroke`, `runner`, `Role`, `Bump`, `AllLevels`, `MaxLevel`, `Pip`, `neutral`, `Edge`, `Star`, `frame`, `milestone`, `Pop`, `ScrollBarThickness`, `AutomaticCanvasSize`, `scroll`, `Padding`, `Layout`, `Stat`, `Value`, `label`, `value`, `surface`, `Perk`, `Head`, `MinTextSize`, `UITextSizeConstraint`, `Description`, `Tokens`, `TokenTrack`, `GetTokens`, `primary`, `Action`

### `ReplicatedStorage.ChickenOrHero.Gear.AirhornCone` (ModuleScript)

`MaxHeight`, `Range`, `contains`, `GearCatalog`, `Items`, `EmergencyAirhorn`, `Radius`, `freeze`

### `ReplicatedStorage.ChickenOrHero.Gear.GearCatalog` (ModuleScript)

`random`, `boxYaw`, `Items`, `SpringBox`, `ShakeSeconds`, `clamp`, `identity`, `Angles`, `boxShake`, `ThrowRange`, `MomentumLead`, `MomentumMaxSpeed`, `FlightSeconds`, `AheadMin`, `throwReaches`, `Bundle`, `Weapons`, `Bundles`, `EndsAt`, `workspace`, `bundleOnly`, `Unlock`, `FallenKing`, `Game`, `FallenKingProgress`, `locked`, `Pair`, `Disabled`, `equippedAbilities`, `equippedAbility`, `UseRole`, `equippedForRole`, `GetService`, `FFlags`, `SalesEnabled`, `MaxInventory`, `PackSize`, `Order`, `Lifeline`, `RescueKit`, `Adrenaline`, `BananaPeel`, `InflatableDecoy`, `EmergencyAirhorn`, `PocketDoor`, `RufusLeash`, `BowlingBall`, `RocketShoes`, `BigDagger`, `Cloak`, `OneHitShield`, `BearTrap`, `BrokenVow`, `TimeWarp`, `FartCloud`, `Burrow`, `SoulReap`, `KingsDemise`, `PumpkinBomb`, `PiratesCall`, `WarHorn`, `AlleyOop`, `SkateSpin`, `Slapstick`, `FrostQuake`, `Spike`, `IconImage`, `Kind`, `Ability`, `Cooldown`, `Duration`, `Reach`, `Tag`, `Description`, `Role`, `CHASER`, `RoleItem`, `Gems`, `Coins`, `ProductId`, `Preview`, `fromRGB`, `CLOAK`, `RUNNER`, `Free`, `TriggerRadius`, `TrapDuration`, `StunDuration`, `SealSeconds`, `HowTo`, `VowbreakerBundle`, `Rewind`, `Windup`, `RewindSeconds`, `PumpkinCleaverBundle`, `RiseSeconds`, `SinkSeconds`, `Stagger`, `Spots`, `Sounds`, `UnlockText`, `SoldFor`, `coins`, `offset`, `scale`, `Rise`, `Whisper`, `Sink`, `Speed`, `ChargeSeconds`, `AimRange`, `CatchRadius`, `KnockSpeed`, `KnockSeconds`, `SpectralCutlassBundle`, `Call`, `Break`, `Range`, `FocusAngle`, `HornSeconds`

### `ReplicatedStorage.ChickenOrHero.Gear.GearPredictionClient` (ModuleScript)

`forActor`, `owner`, `levelled`, `count`, `RaycastParams`, `RaycastFilterType`, `Exclude`, `FilterType`, `RespectCanCollide`, `PredictedGearVisual`, `GetTagged`, `workspace`, `ClientBots`, `FilterDescendantsInstances`, `params`, `pivot`, `descendants`, `Archivable`, `GetTags`, `RemoveTag`, `ProximityPrompt`, `ForceField`, `Massless`, `LocalTransparencyModifier`, `HumanoidDisplayDistanceType`, `DisplayDistanceType`, `HumanoidHealthDisplayType`, `AlwaysOff`, `HealthDisplayType`, `PredictedVisual`, `cloneVisual`, `hidden`, `added`, `restore`, `RufusLeash`, `remove`, `proxy`, `server`, `removeSides`, `Light`, `RocketShoes`, `origin`, `direction`, `Items`, `ThrowRange`, `throwReaches`, `Normal`, `RightHand`, `GetExtentsSize`, `lookAt`, `landing`, `Count`, `sides`, `Angles`, `SpreadDegrees`, `VectorToWorldSpace`, `PocketDoor`, `BowlingBall`, `InflatableDecoy`, `clamp`, `started`, `Duration`, `BearTrap`, `SpringBox`, `TrapDuration`, `duration`, `Speed`, `speed`, `range`, `scale`, `ScaleTo`, `HiddenFromRunners`, `GameRole`, `distance`, `prepare`, `trail`, `Attachment0`, `Attachment1`, `Lifetime`, `BananaPeel`, `fromRGB`, `PumpkinBomb`, `PumpkinBombChaser`, `FaceCamera`, `LightEmission`, `BowlingRoll`, `RollOffMaxDistance`, `RollOffMinDistance`, `RollOffMode`, `InverseTapered`, `position`, `display`, `Width`, `update`, `dress`, `color`, `build`, `velocity`, `attachment`, `character`, `CarrySeconds`, `carryEnds`, `stopRocket`, `Ragdolled`, `settleRocket`, `GearMotion`, `Set`, `Cleared`, `watchFlag`, `PredictedRocketAttachment`, `LinearVelocity`, `PredictedRocketVelocity`, `ActuatorRelativeTo`, `World`, `RelativeTo`, `VelocityConstraintMode`, `Plane`, `PrimaryTangentAxis`, `SecondaryTangentAxis`, `PlaneVelocity`

### `ReplicatedStorage.ChickenOrHero.Gear.GearStoreClient` (ModuleScript)

`textStroke`, `GetService`, `FFlags`, `awaitUIVersion`, `NewGui`, `Interface`, `Toasts`, `Presentation`, `ValleyToast`, `bundleOnly`, `workspace`, `bundled`, `Bundle`, `isOnSale`, `bundleOf`, `Item`, `TutorialStep`, `BuyAdrenaline`, `tutorialFree`, `GetTextSize`, `gmatch`, `MouseEnter`, `MouseLeave`, `SelectionGained`, `SelectionLost`, `AbilityUpgradeMenu`, `equippedGear`, `equippedForRole`, `UseRole`, `Weapons`, `BundlePanel`, `Kind`, `Ability`, `Free`, `ArmoryEvent`, `EquipGear`, `FireServer`, `Gems`, `BuyGearGems`, `SoldFor`, `coins`, `player`, `Game`, `TutorialEvent`, `Adrenaline`, `Coins`, `BuyGear`, `PromptProductPurchase`, `ProductId`, `GearShop`, `heading`, `subtitle`, `AbilitiesHeading`, `Gold`, `abilityHeading`, `ItemsHeading`, `itemHeading`, `Release`, `release`, `UpgradeAbilities`, `upgrade`, `primary`, `Order`, `corner`, `stroke`, `Outline`, `fromRGB`, `fromOffset`, `Role`, `Preview`, `AbilityIcon`, `ImageRectOffset`, `ImageRectSize`, `IconImage`, `IconRectOffset`, `IconRectSize`, `Assets`, `JointInstance`, `lookAt`, `camera`, `extent`, `phase`, `Words`, `fromScale`, `Tag`, `Description`, `Stock`, `Robux`, `Equip`, `border`, `scale`, `previewData`, `title`, `stock`, `robux`, `equip`, `preview`, `secondary`, `RunnerHeading`, `RUNNERS`, `ChaserHeading`, `CHASERS`, `teamHeadings`, `abilities`, `listed`, `sequence`, `soulChecked`, `loaded`, `pending`, `RescueKit`, `SoulReap`, `InMatch`, `concat`, `listing`, `layoutWidth`, `layoutPortrait`, `layout`, `SalesEnabled`, `IsStudio`, `PackSize`

### `ReplicatedStorage.ChickenOrHero.Gear.PumpkinSmoke` (ModuleScript)

`remove`, `prune`, `clock`, `Fire`, `position`, `reach`, `height`, `IsClient`, `clamp`, `covers`, `InMatch`, `GameRole`, `Smoked`, `workspace`, `hidden`, `GetService`, `Attribute`, `BindableEvent`, `freeze`

### `ReplicatedStorage.ChickenOrHero.Gear.RufusLeashCast` (ModuleScript)

`clock`, `untilAt`, `parts`, `LocalTransparencyModifier`, `effects`, `EquippedDagger`, `hideKnife`, `Stop`, `AddItem`, `stopTrack`, `clean`, `Length`, `DidLoop`, `Stopped`, `guardTrack`, `RufusLeashCastAt`, `Animator`, `Animation`, `AnimationId`, `LoadAnimation`, `workspace`, `RufusLeash_Throw`, `AnimationPriority`, `Action4`, `Priority`, `number`, `match`, `seenCast`, `tracks`, `accept`, `GetPlayingAnimationTracks`, `IsClient`, `ClientBot`, `AnimationPlayed`, `observe`, `RightHand`, `handOf`, `owner`, `server`, `GearOwnerId`, `ownerId`, `resolve`, `actorCharacter`, `attachment`, `RufusRope`, `Attachment0`, `Attachment1`, `Width0`, `Width1`, `fromRGB`, `FaceCamera`, `LightInfluence`, `Segments`, `UserId`, `proxy`, `LeashTransparency`, `leashPart`, `GripPoint`, `LeashEnd`, `leashEnd`, `leashGrip`, `leashRope`, `prepare`, `leashHandAttachment`, `remove`, `leashHand`, `RufusRopeStart`, `identity`, `lookAt`, `origin`, `direction`, `GearOrigin`, `serverStarted`, `started`, `Windup`, `predicted`, `trail`, `leashReleaseFrom`, `range`, `Speed`, `Spherecast`, `Distance`, `update`, `RufusPullStart`, `RufusPullEnd`, `clamp`, `ChickenOrHero`, `Debris`, `GetService`, `Bots`, `BotDirectory`, `FlightSeconds`, `__mode`

### `ReplicatedStorage.ChickenOrHero.Gear.StarterPackConfig` (ModuleScript)

`freeze`, `ProductId`, `UniverseId`, `Duration`, `Coins`, `AmountEach`

### `ReplicatedStorage.ChickenOrHero.Interface.AvatarPortrait` (ModuleScript)

`viewport`, `framing`, `Torso`, `RootJoint`, `Neck`, `restHead`, `model`, `source`, `tries`, `dressed`, `RETRIES`, `RETRY_SECONDS`, `Head`, `Angles`, `Portrait`, `heads`, `lookAt`, `Animator`, `still`, `Animation`, `AnimationId`, `LoadAnimation`, `track`, `world`, `camera`, `Stop`, `CharacterClone`, `AnimationConfig`, `PublishedIds`, `Idle`, `__index`, `destroy`

### `ReplicatedStorage.ChickenOrHero.Interface.CharacterClone` (ModuleScript)

`RigidConstraint`, `Attachment0`, `Bone`, `Attachment1`, `onBone`, `strip`, `Clothing`, `ShirtGraphic`, `Accessory`, `CharacterMesh`, `Head`, `Torso`, `UpperTorso`, `dressed`, `Archivable`, `HumanoidDisplayDistanceType`, `DisplayDistanceType`, `EvaluateStateMachine`, `Animator`, `CastShadow`, `identity`, `Transform`, `Ragdolled`, `place`, `EquippedDagger`, `Weapons`, `KnifeChains`, `KnifeClips`, `SkinCatalog`, `chains`, `attach`, `followers`, `GetService`, `PreSimulation`, `follow`, `Animation`, `AnimationId`, `LoadAnimation`, `Stow`, `priority`, `Priority`, `track`, `knifeIdle`, `Emotes`, `EmoteCatalog`, `Prop`, `playsWith`, `holdsIdle`, `Stop`, `holdChains`, `dropIdle`, `RETRY_SECONDS`, `RETRIES`, `ForceField`, `ProximityPrompt`, `ClickDetector`, `Light`, `Fire`, `Smoke`, `Sparkles`, `Highlight`, `BodyMover`, `Constraint`

### `ReplicatedStorage.ChickenOrHero.Interface.CharacterFrame` (ModuleScript)

`bodyBox`, `lookAt`

### `ReplicatedStorage.ChickenOrHero.Interface.CharacterPreview` (ModuleScript)

`pressed`, `lastX`, `MouseMovement`, `viewport`, `camera`, `world`, `EquippedKnife`, `source`, `knife`, `model`, `tries`, `dropIdle`, `PreviewCharacter`, `shownYaw`, `Animator`, `animator`, `knifeIdle`, `dressed`, `RETRIES`, `clock`, `RETRY_SECONDS`, `retryAt`, `rebuild`, `emote`, `track`, `holdChains`, `dispose`, `Angles`, `destroy`, `GetService`, `CharacterClone`, `CharacterFrame`, `Emotes`, `EmotePlayback`, `__index`

### `ReplicatedStorage.ChickenOrHero.Interface.ClaimPop` (ModuleScript)

`upper`, `lower`, `titleCase`, `format`, `asset`, `WheelIcon`, `wheel`, `image`, `count`, `color`, `GOLD`, `spins`, `ValleyHUD`, `Wallet`, `HUD`, `Currencies`, `counter`, `knife`, `SourceName`, `emote`, `EMOTE_IMAGE`, `Crates`, `CrateCatalog`, `floor`, `still`, `amount`, `poseEmote`, `crate`, `origin`, `template`, `heading`, `displayOrder`, `RewardPop`, `Gems`, `target`, `amountColor`, `GEM_IMAGE`, `GEM_TEXT`, `Coins`, `COIN_IMAGE`, `RewardSlot`, `fromOffset`, `fromScale`, `View`, `Gear`, `GearCatalog`, `Progression`, `JourneyConfig`, `Knife`, `owned`, `Emote`, `Crate`, `Ability`, `IconImage`, `Spins`, `CoinBoost`, `GemBoost`, `CandyCorn`, `Game`, `fromRGB`, `QuestSkips`, `title`, `GhostKeys`, `GhostTraderConfig`, `KeyIcon`, `Tokens`, `AbilityLevels`, `TokenIcon`, `Cosmetic`, `KillEffect`, `Reward`, `Unlock`, `Unlocked`, `New`, `Badges`, `MVP`, `given`, `SkinId`, `KnifeIcon`, `EmoteId`, `Badge`, `Keys`, `KeyCrate`, `HalloweenEmote`, `journey`, `GetService`, `Weapons`, `SkinCatalog`, `Emotes`, `EmoteCatalog`, `ExtraBold`

### `ReplicatedStorage.ChickenOrHero.Interface.ClanHall` (ModuleScript)

`label`, `format`, `floor`, `reverse`, `comma`, `Face`, `SizingMode`, `LightInfluence`, `ClipsDescendants`, `NormalId`, `SurfaceGuiSizingMode`, `FixedSize`, `surface`, `InvokeServer`, `color`, `score`, `drawTop`, `MEMBERS`, `clone`, `members`, `UserId`, `fromRGB`, `drawMembers`, `build`, `banner`, `decal`, `border`, `level`, `fromScale`, `CLANS`, `drawBanner`, `model`, `unmount`, `Interface`, `ClanMenu`, `ClanHall_Local`, `workspace`, `LeaderboardLeft`, `LeaderboardRight`, `ClanBanner`, `LeaderboardPart`, `TopClans`, `Members`, `Banner`, `RaycastParams`, `RaycastFilterType`, `Include`, `FilterType`, `FilterDescendantsInstances`, `PromptAt`, `WorldPosition`, `ClansPrompt`, `ActionText`, `Open`, `ObjectText`, `Clans`, `MaxActivationDistance`, `RequiresLineOfSight`, `ProximityPrompt`, `Triggered`, `wallAt`, `viewAt`, `mount`, `ClanHallPivot`, `clock`, `Wall`, `ClanId`, `View`, `Game`, `ClanFunction`, `ClanHallDelivery`, `Lobby`, `start`, `GetService`, `ChickenOrHero`, `ClanConfig`, `Presentation`

### `ReplicatedStorage.ChickenOrHero.Interface.ClanMenu` (ModuleScript)

`floor`, `fromOffset`, `primary`, `Button`, `disabled`, `fromRGB`, `neutral`, `track`, `fromScale`, `clamp`, `PlaceholderText`, `ClearTextOnFocus`, `input`, `PaddingLeft`, `PaddingRight`, `FocusLost`, `ScrollBarThickness`, `AutomaticCanvasSize`, `ScrollingDirection`, `scroll`, `Padding`, `PaddingTop`, `scroller`, `reverse`, `comma`, `format`, `clock`, `workspace`, `serverNow`, `color`, `tagText`, `Weapons`, `SkinCatalog`, `knifeName`, `Gear`, `GearCatalog`, `Items`, `abilityName`, `InvokeServer`, `View`, `invites`, `refresh`, `myRole`, `Leader`, `isLeader`, `Officer`, `isOfficer`, `screen`, `confirm`, `Find`, `clans`, `build`, `banner`, `decal`, `border`, `level`, `muted`, `Invites`, `Moderation`, `requests`, `drawNav`, `position`, `place`, `Open`, `green`, `Invite`, `danger`, `JoinNames`, `clanRow`, `search`, `filter`, `Search`, `Browse`, `Overview`, `Join`, `Request`, `Locked`, `Full`, `All`, `Space`, `AnswerInvite`, `Decline`, `Accept`, `newName`, `upper`, `newTag`, `Customize`, `MinLevel`, `TAG`, `DisplayName`, `update`, `Level`, `NameMin`, `NameMax`, `secondary`, `Frostbiters`, `TagMin`, `TagMax`, `FRST`, `CreateCost`, `BaseSlots`, `Stats`, `nextAt`, `points`, `prevAt`, `Members`, `count`, `slots`, `boost`, `Roles`, `selected`, `Kick`, `Transfer`, `action`, `members`, `MEMBER`, `ROLE`, `LVL`, `Unranked`, `Wins`

### `ReplicatedStorage.ChickenOrHero.Interface.CrateLanes` (ModuleScript)

`options`, `container`, `template`, `lanes`, `tweens`, `sounds`, `timers`, `generation`, `LaneTemplate`, `Padding`, `frame`, `connection`, `cancel`, `later`, `CrateLanes`, `sound`, `floor`, `index`, `paint`, `fromOffset`, `place`, `seconds`, `clamp`, `nearest`, `flash`, `clock`, `prizes`, `Lane`, `fromScale`, `Strip`, `create`, `emote`, `crate`, `Card`, `Flash`, `Open`, `Tick`, `Reward`, `GetService`, `Registry`, `__index`

### `ReplicatedStorage.ChickenOrHero.Interface.Cursor` (ModuleScript)

`Fire`, `request`, `release`, `Signal`

### `ReplicatedStorage.ChickenOrHero.Interface.EmotePose` (ModuleScript)

`clock`, `track`, `Length`, `camera`, `viewport`, `PoseCharacter`, `Angles`, `world`, `clone`, `Animator`, `knifeIdle`, `EquippedKnife`, `holdChains`, `RETRIES`, `RETRY_SECONDS`, `destroyed`, `playing`, `dressed`, `clearPose`, `ended`, `Stop`, `dropIdle`, `IsPlaying`, `AdjustSpeed`, `Stopped`, `destroy`, `GetService`, `CharacterClone`, `CharacterFrame`, `Emotes`, `EmotePlayback`, `__index`

### `ReplicatedStorage.ChickenOrHero.Interface.EmoteSound` (ModuleScript)

`silence`, `toggle`, `connection`, `soundId`, `EmotePreviewSound`, `soundIds`, `destroy`, `GetService`, `Emotes`, `EmoteCatalog`, `__index`

### `ReplicatedStorage.ChickenOrHero.Interface.Features.MatchResultPanel` (ModuleScript)

`GetUserThumbnailAsync`, `ThumbnailType`, `AvatarBust`, `ThumbnailSize`, `Size180x180`, `waiting`, `image`, `clock`, `retryAt`, `thumbnail`, `number`, `GetPlayerByUserId`, `UserId`, `characterOf`, `ImageTransparency`, `userId`, `avatarUserId`, `portrait`, `floor`, `format`, `timeText`, `survival`, `metricText`, `participants`, `tookPart`, `soloWinnerUserId`, `caught`, `hasRun`, `soloWinner`, `result`, `outcomeText`, `JSONDecode`, `version`, `matchId`, `expiresAt`, `shownAt`, `rankings`, `MaxParticipants`, `tournament`, `decode`, `corner`, `StrokeSizingMode`, `ScaledSize`, `outline`, `gradient`, `fromScale`, `ClipsDescendants`, `Rays`, `ImageColor3`, `AspectRatio`, `DominantAxis`, `Width`, `emote`, `Shop`, `Preview`, `knife`, `Tile`, `Art`, `Height`, `View`, `fromRGB`, `wheel`, `title`, `color`, `Caption`, `amount`, `caption`, `ChickenOrHero`, `Crates`, `CrateCatalog`, `KeyCrate`, `HalloweenEmote`, `keyIcon`, `SkinId`, `KnifeIcon`, `titleCase`, `SourceName`, `EmoteId`, `EMOTE_IMAGE`, `Badge`, `Badges`, `Spins`, `Gems`, `GEM_IMAGE`, `Coins`, `COIN_IMAGE`, `CandyCorn`, `Keys`, `Tokens`, `Gear`, `AbilityLevels`, `TokenIcon`, `rewardSpecs`, `frame`, `signatures`, `parts`, `frameSize`, `aspect`, `aspectRatio`, `Journey`, `section`, `sectionScale`, `JOURNEY`, `Tier`, `SeasonBar`, `Shine`, `Gain`, `Count`, `count`, `Next`, `Free`, `FREE`, `freeArt`, `freeStatus`, `freePill`, `Premium`, `PREMIUM`, `premiumTitle`, `Note`, `premiumNote`

### `ReplicatedStorage.ChickenOrHero.Interface.InputMode` (ModuleScript)

`Keyboard`, `MouseMovement`, `MouseButton3`, `MouseWheel`, `Console`, `modeFor`, `GetImageForKeyCode`, `image`, `console`, `keyCode`, `fallback`, `apply`, `Fire`, `GetLastInputType`, `LastInputTypeChanged`, `GamepadConnected`, `start`, `badge`, `GetService`, `Signal`

### `ReplicatedStorage.ChickenOrHero.Interface.KnifeClipPreview` (ModuleScript)

`stroke`, `label`, `bundle`, `assetId`, `emote`, `Entries`, `PlaysWith`, `Show`, `GameDay`, `MatchDay`, `Showtime`, `GamePoint`, `List`, `SkinId`, `Ability`, `ability`, `extras`, `Weapons`, `Actions`, `custom`, `template`, `Equip`, `first`, `tracks`, `Animation`, `AnimationId`, `assets`, `animator`, `LoadAnimation`, `Priority`, `model`, `priority`, `looped`, `track`, `IntroLoop`, `CelebrateLoop`, `Run`, `normalize`, `AnimationPriority`, `Action3`, `showClip`, `ToAxisAngle`, `isRest`, `looseBall`, `Transform`, `RootPart`, `EquippedDagger`, `RootFolder`, `RootStow`, `Part0`, `Part1`, `RootC0`, `identity`, `RootC1`, `RootRest`, `ballJoint`, `PreSimulation`, `rootPiece`, `clock`, `token`, `Length`, `ready`, `buttons`, `gradient`, `highlight`, `CastShadow`, `SmoothPlastic`, `GameDayStage`, `fromRGB`, `Grass`, `WorldPivot`, `fieldEnd`, `Angles`, `MatchDayStage`, `Presentation`, `SoccerNet`, `pitchEnd`, `stages`, `stage`, `lines`, `goalBack`, `fromScale`, `shotLabel`, `ClipsDescendants`, `TopBar`, `BottomBar`, `GameAudio`, `sounds`, `FootballSequenceAudio`, `sequence`, `world`, `random`, `velocity`, `confetti`, `connection`, `drive`, `cleanup`, `labels`, `bottom`, `flash`, `IsPlaying`, `Stop`, `camera`, `clone`, `knife`, `Hold`, `endGameDay`, `pieces`, `settle`, `fired`, `smoother`, `orbit`, `frame`, `Sting`, `Song`, `Whistle`, `CrowdBed`, `Blend`, `CatchSpeed`, `CrowdSurge`

### `ReplicatedStorage.ChickenOrHero.Interface.Panels` (ModuleScript)

`ClientReady`, `ready`, `UserInputState`, `ContextActionResult`, `Pass`, `close`, `Sink`, `CoHPanelBack`, `ContextActionPriority`, `High`, `Value`, `ButtonB`, `BindActionAtPriority`, `UnbindAction`, `refreshBack`, `closeWhere`, `Replaced`, `lobbyOnly`, `closeOnMatch`, `InMatch`, `Match`, `NotReady`, `readiness`, `closeOnRespawn`, `Respawn`, `start`, `Button`, `toggle`, `frame`, `attribute`, `cursor`, `canOpen`, `onOpen`, `onClose`, `isOpen`, `closeButton`, `register`, `setAvailable`, `define`, `track`, `panel_blocked`, `opening`, `clock`, `openedAt`, `panel_open`, `request`, `remove`, `release`, `Destroyed`, `panel_close`, `Closed`, `floor`, `Toggle`, `destroy`, `anyOpen`, `GetService`, `Presentation`, `HudNavigation`, `Cursor`, `Telemetry`, `__index`, `ScreenPresentationActive`, `AdminRefreshActive`

### `ReplicatedStorage.ChickenOrHero.Interface.PreviewButton` (ModuleScript)

`style`, `KnifePreview`, `first`, `Fire`, `connection`, `ViewAnimations`, `fromScale`, `UITextSizeConstraint`, `PaddingLeft`, `PaddingRight`, `PaddingTop`, `PaddingBottom`, `PreviewButton`, `fromOffset`, `PREVIEW`, `destroy`, `KnifeClipPreview`, `ExtraBold`, `fromRGB`, `__index`

### `ReplicatedStorage.ChickenOrHero.Interface.ProductPrices` (ModuleScript)

`clock`, `running`, `yield`, `GetProductInfoAsync`, `fetch`, `remove`, `number`, `prefetch`, `GetService`

### `ReplicatedStorage.ChickenOrHero.Interface.Registry` (ModuleScript)

`screen`, `gmatch`, `GetFullName`, `format`, `missing`, `template`, `clone`, `GetService`, `__mode`

### `ReplicatedStorage.ChickenOrHero.Interface.RewardPop` (ModuleScript)

`clamp`, `GetValue`, `tween`, `GameAudio`, `gmatch`, `GetService`, `LazySound`, `playLocal`, `sound`, `ClaimSound`, `GameAudioMixer`, `SoundGroup`, `Ended`, `chime`, `chimedAt`, `clock`, `chimes`, `claimSound`, `UIGridStyleLayout`, `PopScale`, `scaleOf`, `PopFlash`, `fromScale`, `flash`, `press`, `bounce`, `collect`, `input`, `match`, `items`, `preview`, `destroy`, `finish`, `corner`, `StrokeSizingMode`, `ScaledSize`, `outline`, `Item`, `fromOffset`, `color`, `holder`, `scale`, `count`, `amount`, `title`, `floor`, `Picture`, `Amount`, `View`, `image`, `amountColor`, `Caption`, `Glare`, `Ring`, `ringLine`, `glare`, `knife`, `emote`, `picture`, `bezier`, `place`, `LayerCollector`, `landed`, `landedAt`, `still`, `playAt`, `leaving`, `leave`, `number`, `target`, `exitTo`, `exitVia`, `exitDelay`, `exitTime`, `endAt`, `alpha`, `ImageTransparency`, `heading`, `headingLine`, `headingScale`, `start`, `counted`, `round`, `landedAll`, `leaveAt`, `hintLine`, `hintText`, `InMatch`, `RewardPop`, `displayOrder`, `ScreenInsets`, `ZIndexBehavior`, `Sibling`, `workspace`, `ViewportSize`, `Family`, `ExtraBold`, `fromEnum`, `Heavy`, `origin`, `Backdrop`, `Rays`, `ImageColor3`, `template`, `cancel`, `EmotePose`, `Shop`, `Preview`, `Widgets`, `fromRGB`, `ButtonA`, `ButtonB`, `ButtonX`, `ButtonY`

### `ReplicatedStorage.ChickenOrHero.Interface.Shop.Preview` (ModuleScript)

`MouseMovement`, `rotation`, `lastX`, `onChanged`, `onEnded`, `clean`, `viewport`, `world`, `camera`, `extent`, `phase`, `elapsed`, `Any`, `press`, `lookAt`, `destroy`, `KnifeImage`, `Blade`, `PreviewRotation`, `knife`, `Preview`, `GetService`, `Weapons`, `Gear`, `Assets`, `KnifeIcons`, `__index`, `Angles`, `JointInstance`, `Light`, `Fire`, `Smoke`, `Sparkles`

### `ReplicatedStorage.ChickenOrHero.Interface.Signal` (ModuleScript)

`Connected`, `_signal`, `_handlers`, `_handler`, `Fire`, `DisconnectAll`, `__index`

### `ReplicatedStorage.ChickenOrHero.Interface.TeamEventBoard` (ModuleScript)

`stroke`, `corner`, `gradient`, `label`, `Outline`, `LineJoinMode`, `outline`, `tweens`, `Shine`, `fromScale`, `shine`, `Teams`, `Team`, `BoardKey`, `status`, `loading`, `updatedAt`, `final`, `winner`, `retrying`, `delayed`, `medal`, `MainFrame`, `create`, `bottom`, `fromRGB`, `ZIndexBehavior`, `Sibling`, `ClipsDescendants`, `Stadium`, `fromOffset`, `ColorSequenceKeypoint`, `Lights`, `ImageColor3`, `ImageTransparency`, `EventTag`, `PaddingLeft`, `PaddingRight`, `FillDirection`, `VerticalAlignment`, `Padding`, `Horizontal`, `AutoLocalize`, `Versus`, `Glow`, `Badge`, `TeamHeader`, `Watermark`, `Emblem`, `Ball`, `UITextSizeConstraint`, `headerSweep`, `Jumbotron`, `jumboEdge`, `TeamGlow`, `TotalCaption`, `Total`, `total`, `Divider`, `NumberSequenceKeypoint`, `PLAYERS`, `PlayersCaption`, `playersCaption`, `players`, `LEVEL`, `Level`, `level`, `Pip`, `Ribbon`, `Captions`, `captions`, `RANK`, `PLAYER`, `POINTS`, `Banner`, `banner`, `bannerFill`, `bannerEdge`, `bannerText`, `bannerSweep`, `Turf`, `Line`, `Stripe`, `Shade`, `Empty`, `empty`, `ScrollBarImageColor3`, `ScrollBarThickness`, `SlotFrame`, `Edge`, `Rank`, `Number`, `PFP`, `Username`, `Stat`, `YOU`, `You`, `header`, `build`, `floor`, `clamp`, `members`, `format`, `words`, `sport`, `pulse`, `paint`, `destroy`, `GetService`, `Progression`, `TeamEventConfig`, `ExtraBold`, `Heavy`, `FontStyle`, `Italic`, `TeamLevels`, `Football`

### `ReplicatedStorage.ChickenOrHero.Interface.TeamEventCelebration` (ModuleScript)

`clamp`, `GetValue`, `StrokeSizingMode`, `ScaledSize`, `outline`, `GameAudio`, `gmatch`, `GetService`, `LazySound`, `playLocal`, `sound`, `chimedAt`, `chimes`, `RewardPop`, `chime`, `function`, `sounds`, `ClassName`, `items`, `alpha`, `fadeSet`, `setAlpha`, `Team`, `Personal`, `Champion`, `banner`, `number`, `PersonalLevels`, `defaultNote`, `owned`, `duration`, `Crates`, `Entries`, `Emote`, `Rarity`, `emoteRarity`, `knife`, `image`, `color`, `tagColor`, `titleCase`, `SourceName`, `upper`, `KNIFE`, `Common`, `Rare`, `Source`, `emote`, `EMOTE_IMAGE`, `EXCLUSIVE`, `EMOTE`, `Legendary`, `Epic`, `Badges`, `badge`, `TITLE`, `title`, `Kind`, `Ability`, `asset`, `IconImage`, `emoji`, `supply`, `ABILITY`, `Order`, `still`, `poseEmote`, `FREE`, `crate`, `times`, `addGear`, `Gems`, `Coins`, `Spins`, `GemBoost`, `CoinBoost`, `QuestSkips`, `Knife`, `Gear`, `Crate`, `GemBoostMinutes`, `CoinBoostMinutes`, `Knives`, `Emotes`, `Titles`, `Abilities`, `CrateGems`, `amount`, `spins`, `amountColor`, `GEM_IMAGE`, `GEM_TEXT`, `COIN_IMAGE`, `count`, `tiles`, `AddItem`, `peekUIVersion`, `NewGui`, `ValleyHUD`, `Fire`, `TeamEventNotice`, `AutoLocalize`, `fromScale`, `Glow`, `ImageColor3`, `ImageTransparency`, `fromOffset`, `random`, `glowScale`, `Reward`, `holder`, `scale`, `floor`, `Plate`, `UITextSizeConstraint`, `More`, `Picture`, `picture`, `View`, `Amount`

### `ReplicatedStorage.ChickenOrHero.Interface.Telemetry` (ModuleScript)

`setSink`, `track`

### `ReplicatedStorage.ChickenOrHero.Interface.Widgets` (ModuleScript)

`reverse`, `floor`, `number`, `format`, `clock`, `upper`, `lower`, `titleCase`, `ImageTransparency`, `originals`, `GuiButton`, `ImageColor3`, `greyOut`, `Interactable`, `setEnabled`, `gradient`, `stroke`, `lookOf`, `looks`, `setText`, `__mode`, `fromRGB`

### `ReplicatedStorage.ChickenOrHero.Movement.BodyFacingConfig` (ModuleScript)

`freeze`, `BodyFollowRate`, `IdleFollowRate`, `MovementThreshold`, `MaxTravelYaw`, `TorsoLookShare`, `MaxHipTwist`, `MaxHeadYaw`, `MaxHeadPitch`, `SpeedPenaltyEnabled`, `SlowdownStartsAt`, `SideSpeedMultiplier`, `BackSpeedMultiplier`

### `ReplicatedStorage.ChickenOrHero.Movement.BodyFacingModel` (ModuleScript)

`atan2`, `clamp`, `smooth`, `angle`, `SpeedPenaltyEnabled`, `SideSpeedMultiplier`, `BackSpeedMultiplier`, `SlowdownStartsAt`, `speedMultiplier`, `MovementThreshold`, `MaxTravelYaw`, `BodyFollowRate`, `IdleFollowRate`, `worldYaw`, `TorsoLookShare`, `MaxHipTwist`, `MaxHeadYaw`, `torso`, `pitch`, `MaxHeadPitch`, `Idle`, `Backward`, `Forward`

### `ReplicatedStorage.ChickenOrHero.Movement.BoostInput` (ModuleScript)

`clock`, `request`, `consume`, `BladeHearts`, `GameRole`, `number`, `PlatformStand`, `MovementLocked`, `TackleActive`, `movementReason`, `available`, `Space`, `control`, `ControlGate`

### `ReplicatedStorage.ChickenOrHero.Movement.CameraCollision` (ModuleScript)

`workspace`, `avatarAncestor`, `RaycastParams`, `RaycastFilterType`, `Exclude`, `FilterType`, `RespectCanCollide`, `IgnoreWater`, `world`, `params`, `ignored`, `FilterDescendantsInstances`, `Distance`, `constrain`, `__index`

### `ReplicatedStorage.ChickenOrHero.Movement.CameraFeelConfig` (ModuleScript)

`freeze`, `Intensity`, `SpringFrequency`, `FOVFrequency`, `RunFOV`, `DashFOV`, `RunBoostKickScale`, `DiveFOV`, `DivePitchKick`, `DivePullbackKick`, `DivePullback`, `MaxPitchDegrees`, `MaxRollDegrees`, `RunRollDegrees`, `AccelerationPitchDegrees`, `DashRollKick`, `DashPitchKick`, `DashPullbackKick`, `MaxPullback`, `LateralLag`, `BobHeight`, `BobSide`, `StepFrequency`, `LandingKick`, `AdrenalineFOV`, `AdrenalineFOVFrequency`, `AdrenalineKick`

### `ReplicatedStorage.ChickenOrHero.Movement.CannonMotion` (ModuleScript)

`velocity`, `attachment`, `finish`, `CannonAttachment`, `LinearVelocity`, `CannonVelocity`, `Attachment0`, `ActuatorRelativeTo`, `World`, `RelativeTo`, `VelocityConstraintMode`, `Plane`, `PrimaryTangentAxis`, `SecondaryTangentAxis`, `ForceLimitsEnabled`, `ForceLimitMode`, `AssemblyMass`, `MaxForce`, `cannonMomentum`, `PlaneVelocity`, `cannonLaunch`, `HumanoidStateType`, `Freefall`, `ChangeState`, `RaycastParams`, `RaycastFilterType`, `Exclude`, `FilterType`, `RespectCanCollide`, `workspace`, `ClientBots`, `FilterDescendantsInstances`, `character`, `humanoid`, `started`, `forward`, `speed`, `params`, `clock`, `start`, `cancel`, `Ragdolled`, `MovementLocked`, `Flight`, `FloorMaterial`, `Air`, `CarrySeconds`, `Spherecast`, `Normal`, `Rejected`, `EquippedKnife`, `AlbiesCutlass`, `knifeBlocked`, `Skins`, `ReadyAt`, `TackleActive`, `GearMotion`, `RocketUntil`, `MovementState`, `Weapons`, `Remote`, `OnClientEvent`, `MoveDirection`, `Activate`, `FireServer`, `request`, `GetService`, `Game`, `AbilityRule`, `KnifeAbilities`, `Cannon`, `Distance`, `Dashing`, `Boosting`, `Recovering`

### `ReplicatedStorage.ChickenOrHero.Movement.ControlGate` (ModuleScript)

`GlobalPaused`, `PauseExemptUserId`, `UserId`, `PauseFreesEveryone`, `globalPause`, `GlobalPause`, `MapChanging`, `MapChange`, `Spectating`, `AlbieTalking`, `AlbieTalk`, `EventIntroActive`, `EventIntro`, `ProUnlockActive`, `ProUnlock`, `CupTrailerActive`, `CupTrailer`, `PumpkinAltarActive`, `PumpkinAltar`, `GhostTraderActive`, `GhostTrader`, `FallenKingSpoilsOpen`, `FallenKingSpoils`, `FallenKingAltarOpen`, `FallenKingAltar`, `BundleShowcaseOpen`, `BundleShowcase`, `CutsceneActive`, `Cutscene`, `movementReason`, `AdminPanelOpen`, `AdminPanel`, `HostPanelOpen`, `HostPanel`, `TournamentResultsOpen`, `TournamentResults`, `CombineOpen`, `Combine`, `PumpkinSacrificeOpen`, `PumpkinSacrifice`, `ReviveOfferOpen`, `ReviveOffer`, `PumpkinsOpen`, `Pumpkins`, `BossDownedUntil`, `BossDowned`, `HalloweenShopOpen`, `HalloweenShop`, `OutbreakOpen`, `Outbreak`, `OutbreakNoticeOpen`, `OutbreakNotice`, `FallenKingOpen`, `FallenKing`, `PrivateInviteOpen`, `PrivateInvite`, `CrateOpen`, `Crates`, `StarterPackOpen`, `AbilityUpgradesOpen`, `AbilityUpgrades`, `PostMatchProgressOpen`, `PostMatchProgress`, `RankedLoadoutOpen`, `RankedLoadout`, `LikeRewardOpen`, `InMatch`, `LikeReward`, `CreatorPanelOpen`, `CreatorPanel`, `GlobalWheelOpen`, `GiveawayPickerOpen`, `GlobalWheel`, `MapVoteOpen`, `MapVote`, `EmoteWheelOpen`, `Emotes`, `AnnouncementComposerOpen`, `AnnouncementComposer`, `SettingsOpen`, `Settings`, `UpdateLogOpen`, `UpdateLog`, `FairPlayNoticeOpen`, `FairPlayNotice`, `ConnectionQualityOpen`, `ConnectionQuality`, `JourneyOpen`, `Journey`, `BalloonOfferOpen`, `BalloonOffer`, `ArmoryOpen`, `Armory`, `ClanOpen`, `Clan`, `ServerBrowserOpen`, `ServerBrowser`, `AdminRefreshActive`, `AdminRefresh`, `AdminConsoleActive`, `AdminConsole`, `MenuIsOpen`, `RobloxMenu`, `TextInput`, `ScreenPresentationActive`, `ScreenTransition`, `Phase`, `SelectHero`, `LeadUserId`, `HeroChoice`, `SelectedUserId`, `ReleaseCameraForUI`, `Choice`, `ChoiceSpotlightActive`, `ChoiceReveal`, `ChoiceCamera`, `reason`, `GuiButton`, `track`, `DescendantRemoving`

### `ReplicatedStorage.ChickenOrHero.Movement.CrossingBalance` (ModuleScript)

`freeze`, `tuning`, `floor`, `clamp`, `PressureExponent`, `catchers`, `runners`, `pressure`, `runnerScale`, `catcherScale`, `RunnerMaxBonus`, `CatcherMaxReduction`, `calculate`, `MovementConfig`, `CrossingBalance`

### `ReplicatedStorage.ChickenOrHero.Movement.MovementConfig` (ModuleScript)

`freeze`, `SpeedScale`, `CatcherSpeedMultiplier`, `RunnerSpeedMultiplier`, `RunnerAccelerationMultiplier`, `RunnerTurnRetention90`, `CatcherTurnRate`, `CatcherSlowTurnRate`, `CrossingBalance`, `MaxSpeed`, `Acceleration`, `Deceleration`, `InputDeadzone`, `TurnRetention90`, `StopThreshold`, `StallGrace`, `StallSpeed`, `StallSpeedCap`, `JumpEnabled`, `Dash`, `RunnerMaxBonus`, `CatcherMaxReduction`, `PressureExponent`, `RunnerMaxAccelerationBonus`, `RunnerMaxTurnRetention`, `RunnerMaxBrakingBonus`, `RunnerBuff`, `FromRound`, `Mode`, `RunBoost`, `ScaleDistanceWithSpeed`, `Distance`, `Duration`, `Cooldown`, `MinTurnAngle`, `TurnInputGrace`, `InputBuffer`, `MinIntentAngle`, `TouchTurnInputGrace`, `TouchInputBuffer`, `TouchMinIntentAngle`, `RecoveryDuration`, `RecoverySpeedRatio`, `BoostExitSpeedRatio`, `ShoulderOffset`, `MinZoom`, `MaxZoom`

### `ReplicatedStorage.ChickenOrHero.Movement.MovementModel` (ModuleScript)

`atan2`, `angle`, `smooth`, `carryArea`, `armed`, `disarm`, `travelHistory`, `travelClock`, `requestUntil`, `clearTravel`, `Dash`, `TouchTurnInputGrace`, `TurnInputGrace`, `remove`, `outputDirection`, `InputDeadzone`, `StopThreshold`, `direction`, `speed`, `MaxSpeed`, `rememberTravel`, `TouchMinIntentAngle`, `MinIntentAngle`, `MinTurnAngle`, `redirectsTravel`, `redirects`, `stalled`, `Idle`, `turnAngle`, `cooldown`, `recoveryRemaining`, `boostStart`, `boostExit`, `boostLift`, `dashRemaining`, `dashElapsed`, `dashPeak`, `dashExit`, `dashDirection`, `dashFromDirection`, `dashCount`, `lastDashDistance`, `lastDashEntrySpeed`, `outputSpeed`, `entrySpeed`, `carryRemaining`, `carrySeconds`, `suspend`, `carry`, `carryExcess`, `Duration`, `distance`, `Dashing`, `burst`, `Boosting`, `RecoveryDuration`, `boost`, `canBoost`, `clamp`, `Mode`, `RunBoost`, `TouchInputBuffer`, `InputBuffer`, `ScaleDistanceWithSpeed`, `TurnRate`, `SlowTurnRate`, `Angles`, `VectorToWorldSpace`, `TurnRetention90`, `RecoverySpeedRatio`, `Deceleration`, `Acceleration`, `StallSpeed`, `StallGrace`, `StallSpeedCap`, `Recovering`, `Turning`, `Running`, `Accelerating`, `Braking`, `Distance`, `Cooldown`, `BoostExitSpeedRatio`

### `ReplicatedStorage.ChickenOrHero.Movement.MovementProfiles` (ModuleScript)

`CrossingBalance`, `CrossingCatcherSpeedScale`, `CrossingRunnerSpeedScale`, `number`, `CrossingBalanceTuning`, `tuning`, `CatcherMaxReduction`, `RunnerMaxBonus`, `clamp`, `floor`, `CrossingCatcherCount`, `CrossingRunnerCount`, `calculate`, `pressure`, `clone`, `MaxSpeed`, `Acceleration`, `Deceleration`, `StopThreshold`, `StallSpeed`, `StallSpeedCap`, `RunnerMaxAccelerationBonus`, `RunnerMaxBrakingBonus`, `TurnRetention90`, `RunnerMaxTurnRetention`, `Dash`, `Distance`, `freeze`, `baseProfile`, `GearSlow`, `GearBoost`, `FartBoost`, `HornBoost`, `CloakBoost`, `DunkBoost`, `IceSlide`, `forSkin`, `Key`, `Gear`, `AbilityLevels`, `forActor`, `AlleyOop`, `FartCloud`, `WarHorn`, `Level`, `SpeedBonus`, `DashCooldownReduction`, `Cooldown`, `Perks`, `Cloak`, `GearCatalog`, `Items`, `FrostQuake`, `Grip`, `Brake`, `TurnRate`, `SlowTurnRate`, `BoostAcceleration`, `variant`, `BladeHearts`, `bladeDash`, `TrollSpeed`, `MovementConfig`, `Weapons`, `KnifePerks`, `RunnerSpeedMultiplier`, `RunnerAccelerationMultiplier`, `RunnerTurnRetention90`, `CatcherSpeedMultiplier`, `CatcherTurnRate`, `CatcherSlowTurnRate`, `__mode`

### `ReplicatedStorage.ChickenOrHero.Movement.StepOverMotion` (ModuleScript)

`BigTime`, `burst`, `Weapons`, `Futbol`, `StepOverAnim`, `LeftDashAnim`, `RightDashAnim`, `normalize`, `Animation`, `AnimationId`, `LoadAnimation`, `AnimationPriority`, `Action2`, `Priority`, `velocity`, `attachment`, `finish`, `Animator`, `workspace`, `StepOverAttachment`, `LinearVelocity`, `StepOverVelocity`, `Attachment0`, `ActuatorRelativeTo`, `World`, `RelativeTo`, `VelocityConstraintMode`, `Plane`, `PrimaryTangentAxis`, `SecondaryTangentAxis`, `ForceLimitsEnabled`, `ForceLimitMode`, `AssemblyMass`, `MaxForce`, `FakeTowardInput`, `RaycastParams`, `RaycastFilterType`, `Exclude`, `FilterType`, `RespectCanCollide`, `ClientBots`, `FilterDescendantsInstances`, `character`, `started`, `forward`, `right`, `speed`, `params`, `clock`, `FakeTime`, `start`, `IsPlaying`, `Stop`, `cancel`, `Ragdolled`, `MovementLocked`, `Forward`, `CarrySeconds`, `dashed`, `DashClipTime`, `FakeDistance`, `Spherecast`, `Normal`, `PlaneVelocity`, `Rejected`, `FloorMaterial`, `Air`, `EquippedKnife`, `knifeBlocked`, `Skins`, `ReadyAt`, `TackleActive`, `GearMotion`, `RocketUntil`, `MovementState`, `Remote`, `OnClientEvent`, `MoveDirection`, `Activate`, `FireServer`, `request`, `__mode`, `GetService`, `Game`, `AbilityRule`, `KnifeAbilities`, `KnifeClips`, `StepOver`, `stepOverBurstSpeed`, `Dashing`, `Boosting`, `Recovering`

### `ReplicatedStorage.ChickenOrHero.OldUIReskin.JourneyHalloween` (ModuleScript)

`Interactable`, `round`, `fromOffset`, `picture`, `clock`, `heading`, `TextBounds`, `lanternGlow`, `cornerGlow`, `pumpkin`, `speed`, `phase`, `label`, `thread`, `cauldron`, `ghost`, `ImageTransparency`, `embers`, `period`, `frame`, `fromScale`, `panel`, `parts`, `connection`, `preloaded`, `color`, `accent`, `radius`, `night`, `HalloweenGradient`, `shade`, `textStroke`, `fromRGB`, `edition`, `tierText`, `ember`, `progress`, `witch`, `Free`, `route`, `number`, `HalloweenMark`, `Pumpkin`, `WitchHat`, `HalloweenNight`, `ClipsDescendants`, `Moon`, `Halo`, `Face`, `WebLeft`, `Web`, `WebRight`, `Thread`, `Spider`, `Bat`, `Lantern`, `Glow`, `lantern`, `Graveyard`, `Crop`, `NumberSequenceKeypoint`, `Fog`, `Ember`, `HalloweenEdge`, `Tombstone`, `PumpkinGlow`, `Cauldron`, `Ghost`, `__index`, `apply`, `destroy`, `GetService`, `ContentProvider`, `Skin`, `Images`, `Colors`, `fromEnum`, `Creepster`

### `ReplicatedStorage.ChickenOrHero.OldUIReskin.Skin` (ModuleScript)

`bottom`, `colors`, `fades`, `freeze`, `variant`, `Skin`, `isSkin`, `isText`, `isImage`, `CanvasGroup`, `canGradient`, `ClassName`, `LayerCollector`, `FindFirstAncestorWhichIsA`, `ZIndexBehavior`, `skinZ`, `fromScale`, `SizeConstraint`, `RelativeXY`, `Selectable`, `Interactable`, `decor`, `StrokeSizingMode`, `LineJoinMode`, `BorderStrokePosition`, `style`, `SkinOutline`, `outline`, `noOutline`, `Outline`, `findRing`, `SkinStroke`, `currentRing`, `SkinCorner`, `corner`, `applyCorner`, `SkinGradient`, `quietGradients`, `SkinTextStroke`, `Stroke`, `textStroke`, `SkinShimmer`, `GroupTransparency`, `GroupColor3`, `Corner`, `Fade`, `Tile`, `RelativeYY`, `RelativeXX`, `Checker`, `perShort`, `TileSize`, `alpha`, `ImageTransparency`, `shimmer`, `hideShimmer`, `SkinGlow`, `coins`, `GlowGold`, `ImageColor3`, `GlowWhite`, `Sunray`, `Icons`, `resolveIcon`, `Rarity`, `accentOf`, `strokeTransparency`, `SkinKit`, `clone`, `dimOne`, `setEnabled`, `hover`, `press`, `disconnect`, `MouseEnter`, `MouseLeave`, `SelectionGained`, `SelectionLost`, `GuiButton`, `bindStates`, `shade`, `color`, `surface`, `transparency`, `radius`, `panel`, `accent`, `neutral`, `header`, `SkinDecoration`, `decoration`, `DecorationWide`, `Decoration`, `iconName`, `title`, `primary`, `secondary`, `footer`, `equipped`, `green`, `selected`, `playing`, `collected`, `gemWallet`, `amount`, `track`, `barRing`, `noticeRing`, `badge`, `input`, `textMuted`, `PlaceholderColor3`, `ScrollBarImageColor3`, `ScrollBarImageTransparency`, `scroll`, `stroke`, `ImageRectOffset`, `ImageRectSize`, `SkinIcon`, `SkinCloseGlyph`

### `ReplicatedStorage.ChickenOrHero.Presentation.ArmoryStyle` (ModuleScript)

`textStroke`, `Equip`, `Swing`, `Hit`, `sounds`, `Line`, `Circle`, `Halfway`, `stage`, `radius`, `Pitch`, `Index`, `Eyebrow`, `Tagline`, `Description`, `Footnote`, `Loading`, `Timer`, `timer`, `Buy`, `Sounds`, `Token`, `SkinTokenScaled`, `round`, `tokens`, `CoinIcon`, `GemIcon`, `gemWallet`, `Coins`, `Gems`, `Shop`, `Inventory`, `Overlay`, `Canvas`, `panel`, `transparency`, `Brand`, `Edition`, `TopRule`, `HeaderRule`, `color`, `neutral`, `Tabs`, `ActiveLine`, `corner`, `close`, `Details`, `Action`, `Collection`, `ScrollHint`, `Hero`, `PreviewHint`, `Field`, `CentreLine`, `CentreCircle`, `Outline`, `Wallet`, `scroll`, `Selection`, `SkinTile`, `NameLabel`, `Dock`, `Storefront`, `Featured`, `Earnable`, `primary`, `BalloonDagger`, `emoteOffer`, `TopWinsDagger`, `Perks`, `DoubleXP`, `fromHex`, `VIP`, `Promotion`, `PerksHeading`, `Stacking`, `Footer`, `Packs`, `Art`, `coins`, `gemLarge`, `gemText`, `Amount`, `Caption`, `apply`, `Emotes`, `Depth`, `Abilities`, `Items`, `Dimmed`, `equipped`, `secondary`, `action`, `GetService`, `ChickenOrHero`, `OldUIReskin`, `Skin`, `Theme`, `textSecondary`, `chicken`, `green`

### `ReplicatedStorage.ChickenOrHero.Presentation.AuthoredScreens` (ModuleScript)

`AuthoredScreens`, `UITemplate`, `IsRunning`, `clone`, `pieces`, `UIWhole`, `whole`, `FindFirstAncestorOfClass`, `ClassName`, `adopt`, `GetService`, `__mode`

### `ReplicatedStorage.ChickenOrHero.Presentation.AvatarPortraits` (ModuleScript)

`GetUserThumbnailAsync`, `ThumbnailType`, `AvatarBust`, `ThumbnailSize`, `Size180x180`, `pending`, `image`, `clock`, `retryAt`, `waiters`, `request`, `alive`, `tokens`, `Portrait`, `AvatarFallback`, `Avatar`, `avatarColors`, `DefaultColor`, `fromRGB`, `avatarUserId`, `isBot`, `userId`, `number`, `destroy`, `GetService`, `__index`

### `ReplicatedStorage.ChickenOrHero.Presentation.BalloonLift` (ModuleScript)

`RollOffMaxDistance`, `Ended`, `AddItem`, `sound`, `workspace`, `random`, `LightEmission`, `Lifetime`, `Speed`, `SpreadAngle`, `Acceleration`, `Drag`, `Rate`, `Emit`, `confetti`, `FillTransparency`, `OutlineTransparency`, `Highlight`, `FillColor`, `OutlineColor`, `HighlightDepthMode`, `Occluded`, `DepthMode`, `flash`, `Torso`, `Angles`, `Head`, `hanging`, `restore`, `KillEffectHidden`, `onDone`, `finish`, `clock`, `cancel`, `popped`, `Pop`, `clamp`, `Honk`, `PointToWorldSpace`, `VectorToWorldSpace`, `phase`, `Length`, `scale`, `height`, `Archivable`, `JointInstance`, `Constraint`, `ForceField`, `Animator`, `EmotePiece`, `Accessory`, `FindFirstAncestorOfClass`, `Massless`, `LocalTransparencyModifier`, `HumanoidDisplayDistanceType`, `DisplayDistanceType`, `HumanoidHealthDisplayType`, `AlwaysOff`, `HealthDisplayType`, `PlatformStand`, `EvaluateStateMachine`, `BalloonLift`, `parent`, `BotUserId`, `model`, `lookAt`, `Balloon`, `PartType`, `Ball`, `Shape`, `SmoothPlastic`, `Reflectance`, `CastShadow`, `RopeConstraint`, `Attachment0`, `Attachment1`, `Inflate`, `GetService`, `Debris`, `LocalHide`, `fromRGB`

### `ReplicatedStorage.ChickenOrHero.Presentation.BoneRattle` (ModuleScript)

`IsCollisionGroupRegistered`, `CoHRagdoll`, `Default`, `GetService`, `Skeleton`, `Part0`, `Part1`, `offset`, `bones`, `RollOffMinDistance`, `RollOffMaxDistance`, `AddItem`, `sound`, `workspace`, `fromRGB`, `Lifetime`, `Speed`, `SpreadAngle`, `Drag`, `Rate`, `Emit`, `LightEmission`, `Acceleration`, `random`, `Angles`, `twitch`, `restore`, `KillEffectHidden`, `onDone`, `finish`, `Rattle`, `clock`, `cancel`, `shake`, `Break`, `AssemblyAngularVelocity`, `again`, `Torso`, `BoneRattle`, `ClearAllChildren`, `Massless`, `CollisionGroup`, `BotUserId`, `model`, `FallenKingLocal`, `Lantern`, `parent`, `Highlight`, `FillColor`, `OutlineColor`, `FillTransparency`, `OutlineTransparency`, `HighlightDepthMode`, `Occluded`, `DepthMode`, `PhysicsService`, `Debris`, `LocalHide`, `Head`

### `ReplicatedStorage.ChickenOrHero.Presentation.BonkSplat` (ModuleScript)

`clamp`, `smooth`, `backOut`, `workspace`, `FilterDescendantsInstances`, `floorUnder`, `XVector`, `YVector`, `ZVector`, `upright`, `level`, `fromMatrix`, `BonkSplatPart`, `Archivable`, `GetAttributes`, `RequiresNeck`, `BreakJointsOnDeath`, `EvaluateStateMachine`, `HumanoidDisplayDistanceType`, `DisplayDistanceType`, `HumanoidHealthDisplayType`, `AlwaysOff`, `HealthDisplayType`, `character`, `entries`, `faces`, `hidden`, `CastShadow`, `LocalTransparencyModifier`, `SpecialMesh`, `MeshType`, `FileMesh`, `scale`, `offset`, `Highlight`, `outline`, `Adornee`, `JointInstance`, `Constraint`, `Animator`, `Light`, `LayerCollector`, `ForceField`, `ProximityPrompt`, `ClickDetector`, `BonkSplat`, `copyOf`, `realOutline`, `torso`, `floor`, `floorX`, `floorZ`, `takeOver`, `FillColor`, `OutlineColor`, `FillTransparency`, `OutlineTransparency`, `release`, `finish`, `clock`, `started`, `ragdolled`, `Ragdolled`, `phase`, `Fall`, `FallTimeout`, `Squash`, `Flat`, `Pop`, `BonkSplatBonk`, `Terrain`, `WorldPosition`, `Emit`, `BonkSeconds`, `IsDescendantOf`, `Head`, `Torso`, `UpperTorso`, `Range`, `GetService`, `ContentProvider`, `LocalLooks`, `BonkSize`, `Bonk`, `Rate`, `Lifetime`, `Speed`, `RotSpeed`, `LightEmission`, `LightInfluence`, `ZOffset`, `LockedToPart`, `NumberSequenceKeypoint`, `RaycastParams`, `RaycastFilterType`, `Exclude`, `FilterType`, `RespectCanCollide`

### `ReplicatedStorage.ChickenOrHero.Presentation.BoostVFXConfig` (ModuleScript)

`freeze`, `MaxDistance`, `MaxCharacters`, `TrailLifetime`, `FadeTail`

### `ReplicatedStorage.ChickenOrHero.Presentation.BundleNotice` (ModuleScript)

`workspace`, `Pair`, `ShopCard`, `StartsAt`, `EndsAt`, `listed`, `List`, `newest`, `BundleSeen`, `seenIndex`, `SettingsLoaded`, `Key`, `Contextual`, `outline`, `marker`, `update`, `number`, `MenuToggle`, `DrawerClip`, `Panel`, `Navigation`, `Shop`, `NewBundleMark`, `fromOffset`, `NEW`, `attach`, `GetService`, `Weapons`, `Bundles`, `fromRGB`

### `ReplicatedStorage.ChickenOrHero.Presentation.CatchMeterModel` (ModuleScript)

`cooldown`, `Cooldown`, `clamp`, `paused`, `label`, `elapsed`, `duration`, `Red`, `upper`, `Catch`, `variant`, `RECOVERING`, `Gold`, `Recharging`, `Blue`, `format`, `grounded`, `CATCH`, `Mint`, `ready`, `Dive`, `control`, `freeze`

### `ReplicatedStorage.ChickenOrHero.Presentation.CaughtLoadoutCard` (ModuleScript)

`Corner`, `round`, `GetTextSize`, `widthOf`, `heightOf`, `floor`, `reverse`, `number`, `strokes`, `Contextual`, `Shadow`, `tapped`, `Selectable`, `ClipsDescendants`, `Box`, `corner`, `Shade`, `gradient`, `Ring`, `ItemName`, `Pill`, `fromScale`, `pillText`, `tiles`, `current`, `Offer`, `UserId`, `shown`, `bought`, `paint`, `version`, `watching`, `WATCHING`, `heading`, `LastLoadout`, `UIProportionalExclude`, `shadow`, `shadowCorner`, `surface`, `Card`, `cardCorner`, `Outline`, `outline`, `avatar`, `Crop`, `Avatar`, `avatarCorner`, `avatarRing`, `BotHead`, `botView`, `botCorner`, `botHead`, `CaughtBy`, `blueLight`, `catches`, `caughtBy`, `catcher`, `stats`, `Level`, `Wins`, `Catches`, `label`, `value`, `textMuted`, `statDividers`, `StatDivider`, `Rule`, `LOADOUT`, `lastLoadout`, `Knife`, `Assets`, `GlowWhite`, `Glow`, `fromRGB`, `View`, `Ability`, `BUNDLE`, `robuxDark`, `Ribbon`, `ribbon`, `Emote`, `Headshot`, `fallback`, `PromptProductPurchaseFinished`, `Blade`, `World`, `Angles`, `VectorToWorldSpace`, `lookAt`, `drawKnife`, `playing`, `track`, `dispose`, `world`, `camera`, `clearEmote`, `clone`, `drawEmote`, `GetPlayerByUserId`, `Animator`, `dressed`, `botCharacter`, `drawBot`, `Bot`, `ImageTransparency`, `CaughtLoadoutBuy`, `Owned`, `IsForSale`, `PriceInRobux`, `Bundle`, `SalesEnabled`, `GameId`, `IsStudio`, `selling`, `GetProductInfoAsync`, `catcherText`, `format`, `Person`, `ImageColor3`, `hasStats`

### `ReplicatedStorage.ChickenOrHero.Presentation.ChoiceController` (ModuleScript)

`panel`, `buttons`, `SelectedObject`, `press`, `input`, `MouseMovement`, `position`, `dragged`, `filter`, `layout`, `apply`, `player`, `session`, `action`, `template`, `callbacks`, `lifetime`, `pendingUntil`, `MainFrame`, `Choices`, `Templates`, `ChoiceOption`, `Search`, `Reveal`, `IsDescendantOf`, `PlayerPicker`, `Options`, `GuiButton`, `lower`, `SearchText`, `CanvasPosition`, `Empty`, `Count`, `format`, `PickerColumns`, `NextSelectionUp`, `NextSelectionDown`, `NextSelectionLeft`, `NextSelectionRight`, `clock`, `selected`, `ReleaseFocus`, `choose`, `random`, `hover`, `canvas`, `MouseEnter`, `SelectionGained`, `MouseLeave`, `SelectionLost`, `DisplayName`, `UserId`, `SelectHero`, `FireServer`, `HeroChoice`, `LeadUserId`, `SelectedUserId`, `choice`, `ReleaseCameraForUI`, `GameRole`, `concat`, `RunNumber`, `RunnerChoice`, `Mode`, `Player_`, `IsBot`, `Description`, `AvatarUserId`, `Avatar`, `Fallback`, `upper`, `Chicken`, `Hero`, `Value`, `columns`, `EndsAt`, `workspace`, `update`, `destroy`, `GetService`, `ParticipantDirectory`, `VerifiedName`, `ChoiceView`, `__index`

### `ReplicatedStorage.ChickenOrHero.Presentation.ChoiceSpotlightConfig` (ModuleScript)

`freeze`, `CameraEnabled`, `ApproachTime`, `AnswerHoldTime`, `ReturnTime`, `Distance`, `Height`, `DeadlineGrace`

### `ReplicatedStorage.ChickenOrHero.Presentation.ChoiceView` (ModuleScript)

`textStroke`, `Modal`, `Blue`, `neutral`, `Avatar`, `fromOffset`, `Description`, `Choose`, `fromScale`, `Fallback`, `MainFrame`, `Choices`, `UIProportionalGroup`, `Templates`, `ChoiceOption`, `UITextSizeConstraint`, `UISizeConstraint`, `ProportionalScale`, `surface`, `Gold`, `ChoiceScale`, `HeaderBackground`, `TopRule`, `Eyebrow`, `Count`, `PlaceholderText`, `ClearTextOnFocus`, `PlaceholderColor3`, `MultiLine`, `Search`, `input`, `PaddingLeft`, `PaddingRight`, `Inset`, `RANDOM`, `PlayerPicker`, `Options`, `ScrollingEnabled`, `ScrollingDirection`, `AutomaticCanvasSize`, `ClipsDescendants`, `ScrollBarThickness`, `ScrollBarImageColor3`, `scroll`, `ScrollBarInset`, `Always`, `VerticalScrollBarInset`, `Layout`, `UIGridLayout`, `FillDirection`, `Horizontal`, `FillDirectionMaxCells`, `CellPadding`, `CellSize`, `PaddingTop`, `PaddingBottom`, `Padding`, `Empty`, `RunnerChoice`, `Chicken`, `Hero`, `apply`, `Mint`, `selected`, `choice`, `GuiButton`, `floor`, `clamp`, `NotificationsF`, `ValleyHUD`, `Wallet`, `Reveal`, `Value`, `PickerColumns`, `layout`, `GetService`, `ChickenOrHero`, `OldUIReskin`, `Skin`, `Theme`, `fromHex`

### `ReplicatedStorage.ChickenOrHero.Presentation.ClanBanner` (ModuleScript)

`clock`, `color`, `format`, `Icons`, `iconImage`, `ClanBanner`, `fromOffset`, `position`, `anchor`, `zindex`, `AspectRatio`, `Art`, `fromScale`, `Plain`, `Pole`, `fromRGB`, `Cloth`, `Point`, `EmblemSize`, `Emblem`, `Infill`, `Disc`, `Ring`, `Tag`, `update`, `build`, `BannerById`, `Default`, `banner`, `DefaultEmblem`, `decal`, `emblemArt`, `level`, `border`, `Shop`, `Spin`, `Animated`, `ColorSequenceKeypoint`, `Ribbon`, `GetService`, `Game`, `ClanConfig`, `__mode`

### `ReplicatedStorage.ChickenOrHero.Presentation.CombineScreen` (ModuleScript)

`CombineEvent`, `Families`, `gmatch`, `Order`, `openFamilies`, `Fusion`, `Output`, `fusionOpen`, `corner`, `LineJoinMode`, `StrokeSizingMode`, `ScaledSize`, `Outline`, `Ring`, `rings`, `label`, `gradient`, `Halo`, `ColorSequenceKeypoint`, `middle`, `Glow`, `ImageColor3`, `bottom`, `bannerLook`, `clamp`, `cardLook`, `fromRGB`, `Look`, `setLook`, `fromScale`, `CanvasGroup`, `ImageTransparency`, `TileSize`, `Tile`, `NumberSequenceKeypoint`, `Interactable`, `setEnabled`, `ThumbAxis`, `ThumbNormal`, `fromMatrix`, `Angles`, `iconPose`, `lookAt`, `Blade`, `IconCross`, `IconWeld`, `Part0`, `JointInstance`, `Part1`, `matchLength`, `tierOf`, `Tiers`, `Knife`, `World`, `VectorToWorldSpace`, `cross`, `knifeIcon`, `plural`, `TierColors`, `tierColor`, `tierLook`, `stacks`, `owned`, `count`, `format`, `timeLeft`, `EndsAt`, `number`, `workspace`, `endsIn`, `Costs`, `pathProgress`, `forged`, `pathDone`, `Inputs`, `Fuse`, `output`, `title`, `Combine`, `Names`, `equipped`, `Done`, `Wheel`, `Spin`, `concat`, `familyId`, `upper`, `nextStep`, `listen`, `create`, `remove`, `floating`, `lanes`, `links`, `bannerIcons`, `AspectRatio`, `FixedAspectRatio`, `Pop`, `Header`, `Separator`, `EventName`, `Info`, `EndsIn`, `timerText`, `CloseButton`, `Square`, `frame`, `closeButton`, `NextStep`, `SizeConstraint`, `RelativeYY`, `bannerGlow`, `bannerIcon`, `bannerTitle`, `Note`, `bannerNote`, `Action`, `banner`, `Roadmap`, `ultimateCard`

### `ReplicatedStorage.ChickenOrHero.Presentation.CreatorPolicy` (ModuleScript)

`CreatorAuthorized`, `ContentTeam`, `authorized`, `PrivateServerHost`, `camera`, `ClientReady`, `GlobalPaused`, `PauseExemptUserId`, `UserId`, `PauseFreesEveryone`, `Lobby`, `GameRole`, `MapChanging`, `PlayerBlockers`, `InMatch`, `lobby`, `AdminTransferring`, `ServerBrowserTransferring`, `ScreenPresentationActive`, `AdminRefreshActive`, `GlobalWheelOpen`, `FairPlayNoticeOpen`, `freeze`

### `ReplicatedStorage.ChickenOrHero.Presentation.CreatorView` (ModuleScript)

`Mint`, `Key`, `action`, `CAMERA`, `CREATOR`, `status`, `camera`, `Interactable`, `speeds`, `value`, `lenses`, `render`, `destroy`, `screen`, `CreatorStudio`, `Open`, `panel`, `Studio`, `shade`, `close`, `surface`, `InventoryInk`, `Eyebrow`, `CleanFrame`, `SpeedTitle`, `LensTitle`, `SLOW`, `SMOOTH`, `FAST`, `Speed`, `Blue`, `CLOSE`, `NORMAL`, `WIDE`, `Lens`, `Purple`, `Rule`, `fromOffset`, `Movement`, `Recovery`, `Commands`, `commands`, `CommandHint`, `AFK`, `Gold`, `CreatorRestore`, `CreatorCaptureExempt`, `recovery`, `Restore`, `restore`, `ValleyPanels`, `ValleyTheme`

### `ReplicatedStorage.ChickenOrHero.Presentation.CreatorVisibility` (ModuleScript)

`CreatorCaptureExempt`, `eligible`, `ownWrites`, `suppress`, `hidden`, `wanted`, `records`, `connection`, `watch`, `GetCoreGuiEnabled`, `SetCoreGuiEnabled`, `workspace`, `promptEnabled`, `CoreGuiType`, `GetEnumItems`, `All`, `GetCore`, `TopbarEnabled`, `topbar`, `SetCore`, `GetService`, `CreatorUIHidden`, `setHidden`, `destroy`, `ProximityPromptService`

### `ReplicatedStorage.ChickenOrHero.Presentation.CrossingBalanceNotice` (ModuleScript)

`round`, `upper`, `format`, `metric`, `speed`, `baseline`, `acceleration`, `turning`, `CHASER`, `describe`, `fromOffset`, `textStroke`, `UITextSizeConstraint`, `MinTextSize`, `label`, `CanvasGroup`, `CrossingBalanceNotice`, `GroupTransparency`, `MainFrame`, `Caption`, `Stats`, `frame`, `caption`, `stats`, `player`, `tween`, `showing`, `workspace`, `pending`, `JSONDecode`, `number`, `expiresAt`, `InMatch`, `GameRole`, `Lobby`, `Results`, `Intermission`, `ScreenPresentationActive`, `GlobalWheelOpen`, `MatchSummaryVisible`, `Choices`, `Blue`, `untilAt`, `bottom`, `update`, `destroy`, `GetService`, `ChickenOrHero`, `OldUIReskin`, `Skin`, `Theme`, `NotificationDock`, `__index`

### `ReplicatedStorage.ChickenOrHero.Presentation.CutsceneScreen` (ModuleScript)

`GetService`, `ScreenPresentation`, `ScreenOverlay`, `overlay`, `ScreenInsets`, `ClipToDeviceSafeArea`, `SafeAreaCompatibility`, `apply`, `ZIndexBehavior`, `Sibling`, `freeze`

### `ReplicatedStorage.ChickenOrHero.Presentation.DashMeterModel` (ModuleScript)

`cooldown`, `Dash`, `Cooldown`, `clamp`, `label`, `Disabled`, `paused`, `boosting`, `DASHING`, `Mint`, `recovery`, `RECOVERING`, `Gold`, `Recharging`, `Blue`, `DASH`, `format`, `grounded`, `speed`, `StopThreshold`, `ready`

### `ReplicatedStorage.ChickenOrHero.Presentation.EclipseCutscene` (ModuleScript)

`Movement`, `MovementConfig`, `clock`, `EclipseCutscenes`, `Modules`, `number`, `format`, `arrivedFolder`, `IsDescendantOf`, `module`, `function`, `AncestryChanged`, `Preload`, `preload`, `CreatorCaptureExempt`, `EclipseEffectSurface`, `workspace`, `EclipseCutscene_`, `VermillionScreenFlipbook`, `GetCore`, `TopbarEnabled`, `SetCore`, `LayerCollector`, `records`, `connection`, `wanted`, `release`, `destroy`, `CreatorUIHidden`, `setHidden`, `promptEnabled`, `topbar`, `hideHud`, `MusicPaused`, `SoundGroup`, `muteGame`, `CutsceneActive`, `fromScale`, `floor`, `MaxVisibleGraphemes`, `playing`, `sound`, `CutsceneCover`, `Black`, `Loading`, `fromRGB`, `Heavy`, `LoadingHint`, `Medium`, `loading`, `black`, `openSession`, `closeSession`, `CutsceneNotice`, `Panel`, `UISizeConstraint`, `MinSize`, `MaxSize`, `PlayerScripts`, `PlayerModule`, `playerModule`, `GetCameras`, `activeCameraController`, `GetSubjectPosition`, `GetCameraToSubjectDistance`, `Focus`, `lookAt`, `Angles`, `InMatch`, `KeyboardAndMouse`, `CameraOffset`, `VectorToWorldSpace`, `playerCameraPose`, `UnbindFromRenderStep`, `EclipseCutsceneHandBack`, `CameraSubject`, `CameraType`, `Custom`, `finish`, `clamp`, `GetValue`, `Scriptable`, `Value`, `handBack`, `lower`, `IsBot`, `consider`, `rigsIn`, `standIns`, `Handle`, `JointInstance`, `Massless`, `AccessoryWeld`, `Part0`, `Part1`, `attach`, `Accessory`, `ClassName`, `BodyColors`, `Head`, `dress`, `Slot`, `castLooks`, `castAll`, `current`, `coverToken`, `cover`, `Error`, `Stopped`, `Stop`, `Late`, `giveUp`, `UserSettings`, `UserGameSettings`, `GetService`, `SavedQualityLevel`, `KeyboardEnabled`, `particleShare`, `EclipseThinned`, `Rate`

### `ReplicatedStorage.ChickenOrHero.Presentation.EmoteWheelPreviews` (ModuleScript)

`slots`, `poses`, `tried`, `loadedAt`, `madeAt`, `hovered`, `elapsed`, `shutAt`, `destroy`, `Preview`, `dropSlot`, `dropAll`, `EmoteProp`, `dressed`, `copyable`, `EquippedKnife`, `character`, `knife`, `clock`, `shown`, `track`, `Length`, `poseOnly`, `ready`, `GetMouseLocation`, `GetGuiInset`, `inside`, `playing`, `start`, `after`, `unhover`, `Turn`, `hover`, `pause`, `Keep`, `GetService`, `Interface`, `EmotePose`, `CharacterClone`, `__index`

### `ReplicatedStorage.ChickenOrHero.Presentation.EmoteWheelView` (ModuleScript)

`centred`, `ValleyEmotes`, `ZIndexBehavior`, `Sibling`, `Pictures`, `Open`, `Purple`, `Face`, `emoteButton`, `EMOTES`, `Badge`, `fromOffset`, `corner`, `stroke`, `neutral`, `Key`, `Pad`, `ImageColor3`, `PadImage`, `Shade`, `fromScale`, `fullscreenShade`, `shade`, `Wheel`, `Eyebrow`, `Modal`, `close`, `Ring`, `panel`, `transparency`, `Glyph`, `emote`, `EmoteName`, `MyEmotes`, `Stop`, `Mint`, `primary`, `Slots`, `Slot`, `Number`, `Caption`, `Source`, `Preview`, `fromRGB`, `UITextSizeConstraint`, `PictureFit`, `MinTextSize`, `GetEmotes`, `Gold`, `Ultimate`, `ULTIMATE`, `build`, `compactFor`, `floor`, `place`, `stack`, `Picture`, `slotText`, `Compact`, `picture`, `setStop`, `KeyboardAndMouse`, `badge`, `SkinIcon`, `ImageTransparency`, `Outline`, `layout`, `GetService`, `ChickenOrHero`, `OldUIReskin`, `Skin`, `Theme`

### `ReplicatedStorage.ChickenOrHero.Presentation.EquipmentHudLayoutLegacy` (ModuleScript)

`scale`, `UIProportionalExclude`, `register`, `HUD`, `MainFrame`, `BarMainFrame`, `touchStack`, `workspace`, `ViewportSize`, `rectangles`, `Melee`, `MeleeButton`, `GetGuiInset`, `fromOffset`, `right`, `factor`, `bottom`, `clamp`, `update`, `FindFirstAncestorWhichIsA`, `rowTop`, `GetService`, `TouchCombatLayout`

### `ReplicatedStorage.ChickenOrHero.Presentation.EscapeStreakController` (ModuleScript)

`MainFrame`, `NotificationsF`, `EscapeStreak`, `GroupTransparency`, `session`, `player`, `colors`, `snapshot`, `count`, `serial`, `tweens`, `allowed`, `alive`, `pulse`, `Count`, `cancel`, `tween`, `GameRole`, `format`, `updateHint`, `Caption`, `Gold`, `Mint`, `Reveal`, `Segments`, `Segment`, `fromScale`, `RunnerLeft`, `broken`, `EscapeStreakState`, `matchId`, `JSONDecode`, `InMatch`, `Lobby`, `Countdown`, `FinalRun`, `Results`, `event`, `Won`, `Broken`, `Interrupted`, `update`, `destroy`, `GetService`, `__index`

### `ReplicatedStorage.ChickenOrHero.Presentation.FallenKingAltar` (ModuleScript)

`RandomPrizePolicy`, `start`, `restricted`, `BindableEvent`, `floor`, `reverse`, `commas`, `format`, `clock`, `multiplier`, `percent`, `alive`, `workspace`, `FallenKingStone`, `stone`, `Lobby`, `Throne`, `StoneKingSpot`, `spotPart`, `CameraSpot`, `lookAt`, `WorldPosition`, `StonePose`, `Lying`, `cframe`, `PointToWorldSpace`, `ViewportSize`, `clamp`, `shotOf`, `RollOffMaxDistance`, `Ended`, `GetService`, `FFlags`, `awaitUIVersion`, `NewGui`, `Interface`, `Toasts`, `ValleyToast`, `SummonState`, `Closed`, `target`, `endsAt`, `topId`, `topCoins`, `SummonPot`, `SummonTarget`, `SummonEndsAt`, `SummonTop`, `SummonTopId`, `SummonTopCoins`, `FallenKingDeposited`, `snapshot`, `SummonOdds`, `JSONDecode`, `tiers`, `readOdds`, `tierFor`, `LineJoinMode`, `StrokeSizingMode`, `ScaledSize`, `stroke`, `Interactable`, `white`, `label`, `Ring`, `ghost`, `fromRGB`, `setLook`, `Outline`, `fromScale`, `CanvasGroup`, `ImageTransparency`, `TileSize`, `Tile`, `Stripes`, `setEnabled`, `Edge`, `panel`, `Divider`, `divider`, `refresh`, `FallenKingAltar`, `ZIndexBehavior`, `Sibling`, `CreatorCaptureExempt`, `NumberSequenceKeypoint`, `Controls`, `AspectRatio`, `frame`, `Pop`, `Info`, `title`, `subtitle`, `InfoPage`, `infoPage`, `YoursTitle`, `lemon`, `Yours`, `yours`, `LuckTitle`, `luckTitle`, `Luck`, `NextTier`, `nextTier`, `OddsPage`, `oddsPage`, `OddsTitle`, `oddsTitle`, `oddsRows`, `Odds`, `Value`, `value`, `OddsButton`, `oddsButton`, `Offer`, `AmountTitle`, `chips`, `Summon`, `Deposits`, `Amount`

### `ReplicatedStorage.ChickenOrHero.Presentation.FallenKingSpoils` (ModuleScript)

`unitOr`, `clamp`, `smooth`, `backOut`, `CastShadow`, `quiet`, `outroFrom`, `still`, `rarity`, `isHigh`, `GetTextSize`, `width`, `Weight`, `Value`, `heavy`, `floor`, `gmatch`, `sounds`, `folder`, `Warm`, `clock`, `IsPlaying`, `IsLoaded`, `Loaded`, `GhostTraderConfig`, `RarityColors`, `rarityColor`, `ColorMap`, `AssetFetchStatus`, `Success`, `PreloadAsync`, `GhostTraderAssets`, `Cards`, `pending`, `SurfaceAppearance`, `Probe`, `concat`, `checked`, `checkArt`, `VectorToWorldSpace`, `unproject`, `TALLEST`, `ACROSS`, `GAP`, `ROW_Y`, `DEPTH`, `depth`, `scale`, `BANNER_WIDTH`, `bannerW`, `BANNER_SHAPE`, `BANNER_LEAST`, `bannerH`, `BANNER_GAP`, `bannerY`, `KING_WIDTH`, `kingW`, `KING_TALLEST`, `KING_SHAPE`, `kingH`, `KING_GAP`, `kingY`, `layoutFor`, `cardSize`, `model`, `offset`, `layers`, `addLayer`, `remove`, `dropLayer`, `frame`, `workspace`, `BulkMoveMode`, `FireCFrameChanged`, `BulkMoveTo`, `place`, `NormalId`, `Front`, `Face`, `SurfaceGuiSizingMode`, `PixelsPerStud`, `SizingMode`, `LightInfluence`, `Brightness`, `CreatorCaptureExempt`, `AlwaysOnTop`, `ZIndexBehavior`, `Sibling`, `ClipsDescendants`, `Adornee`, `surface`, `LineJoinMode`, `TextStroke`, `textStroke`, `artPart`, `SmoothPlastic`, `Plain`, `fromRGB`, `fromOffset`, `Plate`, `fromScale`, `Keyhole`, `AspectRatio`, `Aspect`, `Slot`, `plainPart`, `plain`, `style`, `setFace`, `RARITY`, `faceGlow`, `stroke`, `Edge`, `label`, `Common`, `accent`, `Print`, `reverse`, `FixedSize`, `PRINT_PIXELS`

### `ReplicatedStorage.ChickenOrHero.Presentation.FootDustConfig` (ModuleScript)

`freeze`, `MaxDistance`, `MaxCharacters`, `UpdateInterval`, `MinSpeedRatio`, `StepDistance`, `ParticlesPerStep`

### `ReplicatedStorage.ChickenOrHero.Presentation.FootballShots` (ModuleScript)

`Volley`, `Lead`, `Run`, `Turn`, `SlowFrom`, `ClipHit`, `SlowRate`, `Fly`, `SetFlight`, `runEnd`, `impact`, `release`, `total`, `SetRelease`, `SetFrom`, `Settle`, `volleyTimes`, `volleyBallClock`, `clamp`, `Lanes`, `Cuts`, `Dash`, `smooth`, `Start`, `laneAt`, `Dunk`, `Leap`, `SlowAt`, `dunkLeap`, `dunkLeapClock`, `LeapZ`, `dunkAt`, `Dodge`, `Finish`, `dodgeAt`, `position`, `diveAt`, `toward`, `Lunge`, `dodgeDefenders`, `smoother`, `number`, `punch`, `lookPoint`, `atan2`, `lookAt`, `orbit`, `glide`, `forward`, `right`, `throw`, `catch`, `spike`, `touchdown`, `juggle`, `tricks`, `freeze`, `Kickoff`, `Touchdown`, `CatchDelay`, `CatchSpeed`, `ThrowAt`, `CatchAt`, `SpikeAt`, `Timing`, `Celebrate`, `JuggleDelay`, `Blend`, `RunUp`, `RunUpDistance`, `Slide`, `NetGap`, `CheerAt`, `Score`, `KickDelay`, `KickCheer`, `KickPause`, `Yaw`, `Goal`, `MatchDay`, `Room`, `TricksDelay`, `TricksSpeed`, `BeatAt`, `TitleAt`, `Bounces`, `DribbleSounds`, `Hoops`, `Hang`, `Drop`, `RimAhead`, `Rise`, `LandAhead`, `ClipDunk`, `ClipHang`, `ClipLength`, `BumpDelay`, `BumpSpeed`, `SpotZ`, `FriendX`, `FriendZ`, `SetHeight`, `Arc`, `TargetZ`, `TargetX`, `Knock`, `Hand`

### `ReplicatedStorage.ChickenOrHero.Presentation.FrostbitePillar` (ModuleScript)

`source`, `NumberSequenceKeypoint`, `TimeScale`, `LightInfluence`, `Acceleration`, `Drag`, `LockedToPart`, `Rate`, `emitter`, `RollOffMinDistance`, `RollOffMaxDistance`, `AddItem`, `sound`, `CastShadow`, `Glass`, `piece`, `Angles`, `Ice`, `PartType`, `Wedge`, `Shape`, `Reflectance`, `Neon`, `crystal`, `restore`, `KillEffectHidden`, `release`, `onDone`, `onCrumble`, `shards`, `EmissionDirection`, `SpreadAngle`, `Speed`, `Lifetime`, `LightEmission`, `NormalId`, `Emit`, `frost`, `Brightness`, `FillTransparency`, `OutlineTransparency`, `finish`, `clock`, `random`, `scale`, `Torso`, `UpperTorso`, `parent`, `workspace`, `cancel`, `FrostbitePillar`, `Archivable`, `JointInstance`, `Constraint`, `Animator`, `Highlight`, `HumanoidDisplayDistanceType`, `DisplayDistanceType`, `HumanoidHealthDisplayType`, `AlwaysOff`, `HealthDisplayType`, `EvaluateStateMachine`, `FrozenBody`, `RaycastParams`, `RaycastFilterType`, `Exclude`, `FilterType`, `ClientBots`, `FilterDescendantsInstances`, `RespectCanCollide`, `BotUserId`, `model`, `FrostbiteTint`, `fromRGB`, `FillColor`, `OutlineColor`, `HighlightDepthMode`, `Occluded`, `DepthMode`, `shock`, `Orientation`, `ParticleOrientation`, `VelocityPerpendicular`, `Snow`, `Cylinder`, `glint`, `PointLight`, `Range`, `Shadows`, `GetService`, `Debris`, `LocalHide`, `Freeze`, `Rise`, `Shatter`, `ChickenOrHero`, `Weapons`, `TheLastDoor`, `Blade`, `Aura2`, `Wolfsbane`, `BladeVFX`, `PlatinumJavelins`, `BansheesCry`, `star_sparkle4_white`

### `ReplicatedStorage.ChickenOrHero.Presentation.FullscreenBackdrop` (ModuleScript)

`fromOffset`, `clamp`, `watch`, `destroy`, `_Edges`, `ScreenInsets`, `SafeAreaCompatibility`, `ClipToDeviceSafeArea`, `ZIndexBehavior`, `Sibling`, `AncestryChanged`, `__mode`

### `ReplicatedStorage.ChickenOrHero.Presentation.GhostKeyDrop` (ModuleScript)

`clamp`, `smooth`, `backOut`, `Game`, `GhostTraderConfig`, `KeyIcon`, `keyIcon`, `screen`, `GhostKeyDrop`, `ZIndexBehavior`, `Sibling`, `clock`, `IsLoaded`, `Loaded`, `IsPlaying`, `GhostKey`, `RollOffMinDistance`, `RollOffMaxDistance`, `GroupTransparency`, `fromScale`, `CanvasGroup`, `KeyPop`, `FillDirection`, `Horizontal`, `HorizontalAlignment`, `VerticalAlignment`, `floor`, `Padding`, `Key`, `fromOffset`, `format`, `LineJoinMode`, `number`, `noticeText`, `target`, `userId`, `GetPlayerByUserId`, `Rate`, `Emit`, `Brightness`, `ImageTransparency`, `finish`, `WorldPosition`, `start`, `seconds`, `Got`, `UserId`, `amount`, `workspace`, `world`, `Terrain`, `Adornee`, `AlwaysOnTop`, `LightInfluence`, `MaxDistance`, `Glow`, `ImageColor3`, `PointLight`, `Range`, `Shadows`, `Sparks`, `LightEmission`, `NumberSequenceKeypoint`, `Lifetime`, `Speed`, `SpreadAngle`, `Rise`, `reason`, `Win`, `earned`, `GetService`, `ChickenOrHero`, `fromRGB`, `fromEnum`, `Creepster`, `LastManStanding`, `freeze`

### `ReplicatedStorage.ChickenOrHero.Presentation.GhostTraderView` (ModuleScript)

`unitOr`, `clamp`, `smooth`, `FindFirstAncestorOfClass`, `IsBot`, `workspace`, `AddToFilter`, `LocalTransparencyModifier`, `othersK`, `saved`, `othersFade`, `start`, `seconds`, `backOut`, `CastShadow`, `quiet`, `alive`, `format`, `clock`, `GetTextSize`, `width`, `Weight`, `Value`, `heavy`, `floor`, `gmatch`, `sounds`, `folder`, `Warm`, `IsPlaying`, `IsLoaded`, `Loaded`, `finishing`, `GhostTraderConfig`, `config`, `RarityColors`, `rarityColor`, `GetService`, `FFlags`, `awaitUIVersion`, `NewGui`, `Interface`, `Toasts`, `ValleyToast`, `ColorMap`, `AssetFetchStatus`, `Success`, `PreloadAsync`, `GhostTraderAssets`, `Cards`, `SurfaceAppearance`, `Probe`, `concat`, `checked`, `checkArt`, `lookAt`, `slotPose`, `identity`, `fromAxisAngle`, `VectorToObjectSpace`, `VectorToWorldSpace`, `aimC0`, `motor`, `aimArm`, `XVector`, `YVector`, `ZVector`, `extent`, `topOf`, `PointToObjectSpace`, `project`, `unproject`, `onScreen`, `panelAt`, `outline`, `covered`, `fanEnvelope`, `areaOf`, `outside`, `bodyBoxes`, `behindBody`, `clearOf`, `studsFor`, `PLACARD_RIGHT`, `PLACARD_LEFT`, `PLACARD`, `PLACARD_GAP`, `PLACARD_SHRINK`, `PLACARD_BOTTOM`, `placardLayout`, `panelBetween`, `camera`, `WorldPosition`, `RaycastParams`, `RaycastFilterType`, `Exclude`, `FilterType`, `FilterDescendantsInstances`, `GetFullName`, `composeShot`, `Table`, `Lantern`, `CardAnchor`, `Trader`, `Head`, `model`, `lantern`, `anchor`, `stand`, `StandSpot`, `CameraSpot`, `spotsOf`, `fanCentre`, `RigType`, `HumanoidRigType`, `R15`, `HipHeight`, `WorldCFrame`, `standFor`, `spots`

### `ReplicatedStorage.ChickenOrHero.Presentation.GiftScreen` (ModuleScript)

`corner`, `Outline`, `Ring`, `rings`, `label`, `fromRGB`, `fromScale`, `CanvasGroup`, `ImageTransparency`, `TileSize`, `Tile`, `fromOffset`, `Stripes`, `close`, `refresh`, `remote`, `FireServer`, `hideBanner`, `scale`, `layout`, `changedPlayers`, `statuses`, `UserId`, `InMatch`, `open_`, `inflight`, `ZIndexBehavior`, `Sibling`, `ValleyGift`, `Selectable`, `Backdrop`, `backdrop`, `Panel`, `panel`, `ImageColor3`, `Eyebrow`, `GIFT`, `title`, `Description`, `PlaceholderText`, `PlaceholderColor3`, `ClearTextOnFocus`, `Search`, `PaddingLeft`, `PaddingRight`, `Padding`, `search`, `ScrollBarThickness`, `ScrollBarImageColor3`, `AutomaticCanvasSize`, `ScrollingDirection`, `List`, `Layout`, `Empty`, `empty`, `Message`, `message`, `Footnote`, `Banner`, `bannerTitle`, `Item`, `bannerItem`, `banner`, `Toast`, `offer`, `upper`, `GamepadEnabled`, `SelectedObject`, `IsDescendantOf`, `clock`, `askedAt`, `Eligible`, `askQueued`, `toastToken`, `showToast`, `userId`, `lower`, `display`, `DisplayName`, `frame`, `avatarId`, `avatar`, `format`, `choose`, `Row`, `Avatar`, `Display`, `Username`, `Gift`, `number`, `Refused`, `Opened`, `Closed`, `Delivered`, `result`, `Gifted`, `AlreadyOwned`, `AtLimit`, `NoRecipient`, `GetService`, `GameAudio`, `Purchase`, `LazySound`, `playLocal`, `receive`, `ChickenOrHero`, `Weapons`, `GiftConfig`, `__index`, `ExtraBold`, `Busy`, `Unavailable`, `Ended`, `Loading`, `Self`, `Waiting`, `Owned`, `Reserved`, `Failed`, `Cooldown`

### `ReplicatedStorage.ChickenOrHero.Presentation.GiveawayPicker` (ModuleScript)

`Dagger`, `amount`, `prize`, `validPrize`, `label`, `Gold`, `preview`, `GiveawayPickerOpen`, `ReleaseFocus`, `visible`, `Preview`, `Launch`, `FireServer`, `fromOffset`, `Eyebrow`, `Gems`, `Coins`, `layout`, `AdminTier`, `Owner`, `message`, `reply`, `destroy`, `screen`, `GiveawayPicker`, `ScreenInsets`, `ClipToDeviceSafeArea`, `panel`, `Picker`, `surface`, `Help`, `Order`, `Default`, `Daggers`, `AutomaticCanvasSize`, `ScrollBarThickness`, `ScrollBarImageColor3`, `ScrollingDirection`, `Layout`, `Padding`, `Amount`, `PlaceholderText`, `ClearTextOnFocus`, `InventoryInk`, `PreviewButton`, `Blue`, `upper`, `ValleyPanels`, `ValleyTheme`, `Weapons`, `SkinCatalog`, `Admin`, `GiveawayRules`, `GiveawayView`

### `ReplicatedStorage.ChickenOrHero.Presentation.GiveawayView` (ModuleScript)

`fromScale`, `fromOffset`, `circle`, `ClearAllChildren`, `Weapons`, `Blade`, `PreviewRotation`, `identity`, `VectorToWorldSpace`, `lookAt`, `fromRGB`, `preview`, `layout`, `GlobalGiveaway`, `ScreenInsets`, `ClipToDeviceSafeArea`, `ZIndexBehavior`, `Sibling`, `Dim`, `Modal`, `cursorWhileVisible`, `Stage`, `Gold`, `WheelWindow`, `ClipsDescendants`, `Wheel`, `InventoryInk`, `stroke`, `Outline`, `InnerRing`, `Seats`, `Hub`, `Words`, `CurrentPlayer`, `corner`, `Pointer`, `Prize`, `surface`, `Preview`, `Amount`, `Caption`, `Selected`, `Note`, `Confetti`, `Purple`, `heroPortrait`, `confetti`, `scale`, `hubText`, `prize`, `amount`, `caption`, `heading`, `title`, `selected`, `pointer`, `winnerIndex`, `winner`, `clamp`, `Player`, `Portrait`, `format`, `display`, `verified`, `Dagger`, `upper`, `excluded`, `finalAngle`, `lastIndex`, `spinAt`, `resultAt`, `floor`, `WINNER`, `ValleyPanels`, `ValleyTheme`, `SkinCatalog`, `KnifeIconCopy`, `KnifeIcons`, `VerifiedName`, `__index`

### `ReplicatedStorage.ChickenOrHero.Presentation.HalloweenCrateShow` (ModuleScript)

`explode`, `risen`, `arrive`, `length`, `timeline`, `clamp`, `outCubic`, `outBack`, `NumberSequenceKeypoint`, `CastShadow`, `SurfaceType`, `Smooth`, `TopSurface`, `BottomSurface`, `newPart`, `solid`, `IsDescendantOf`, `scrub`, `GetTags`, `RemoveTag`, `untag`, `PointToObjectSpace`, `boundsIn`, `remove`, `ToOrientation`, `Angles`, `ProximityPrompt`, `WorldPosition`, `WorldPivot`, `chest`, `offset`, `GlowingInside`, `Neon`, `hinge`, `mouth`, `floor`, `front`, `doorway`, `model`, `parts`, `opening`, `width`, `depth`, `height`, `GetScale`, `crateCopy`, `Blade`, `Knife`, `IconWeld`, `PivotOffset`, `GripPoint`, `knife`, `fromMatrix`, `knifeHero`, `EmoteCopy`, `lookAt`, `emote`, `bottom`, `animator`, `Animator`, `emoteHero`, `viewFrom`, `workspace`, `viewPoint`, `UpperTorso`, `Torso`, `chestOf`, `RaycastParams`, `RaycastFilterType`, `Exclude`, `FilterType`, `RespectCanCollide`, `IgnoreWater`, `FilterDescendantsInstances`, `clock`, `untilAt`, `OverlapParams`, `VectorToWorldSpace`, `radius`, `GetPartBoundsInBox`, `Terrain`, `Distance`, `landing`, `fromScale`, `LineJoinMode`, `StrokeSizingMode`, `ScaledSize`, `PrizeLabel`, `Adornee`, `SizeOffset`, `StudsOffsetWorldSpace`, `MaxDistance`, `AlwaysOnTop`, `LightInfluence`, `ClipsDescendants`, `ZIndexBehavior`, `Sibling`, `upper`, `scale`, `texts`, `labelBoard`, `setLabelAlpha`, `ImageColor3`, `ImageTransparency`, `glowBoard`, `LightEmission`, `Lifetime`, `Speed`, `SpreadAngle`, `Acceleration`, `Drag`, `RotSpeed`, `Rate`, `sparkEmitter`, `seedOf`, `Ring`, `Face`, `SizingMode`, `NormalId`, `SurfaceGuiSizingMode`

### `ReplicatedStorage.ChickenOrHero.Presentation.HalloweenShopScreen` (ModuleScript)

`Interface`, `EmotePose`, `EmoteSound`, `CharacterFrame`, `poseModule`, `merge`, `fromScale`, `corner`, `LineJoinMode`, `StrokeSizingMode`, `black`, `ScaledSize`, `Outline`, `Ring`, `rings`, `border`, `props`, `radius`, `outer`, `cssBox`, `Interactable`, `white`, `label`, `CanvasGroup`, `picture`, `gradient`, `format`, `reverse`, `commas`, `fromRGB`, `GetTextBoundsParams`, `Width`, `GetTextBoundsAsync`, `Family`, `Weight`, `Value`, `textWidth`, `concat`, `breaks`, `gmatch`, `space`, `lines`, `align`, `LineHeight`, `minLines`, `shownSize`, `shownLines`, `ImageColor3`, `ImageTransparency`, `Stretch`, `Soft`, `Twinkle`, `NumberSequenceKeypoint`, `Core`, `scale`, `sparkle`, `atan2`, `AspectRatio`, `Square`, `Short`, `Long`, `checkMark`, `pumpkin`, `TileSize`, `Tile`, `Stripes`, `Gloss`, `texture`, `coinSize`, `COINS`, `Coin`, `Robux`, `robux`, `Amount`, `amount`, `Word`, `Check`, `check`, `priceButton`, `setLook`, `layoutRow`, `Blade`, `bladeOf`, `image`, `World`, `Angles`, `VectorToWorldSpace`, `lookAt`, `camera`, `drawKnife`, `ClassName`, `WorldPivot`, `model`, `drawModel`, `witch`, `ember`, `Ember`, `Halo`, `frame`, `alpha`, `period`, `phase`, `embers`, `animation`, `showPacks`, `tiles`, `owned`, `locked`, `sparkles`, `items`, `whoLabels`, `HalloweenShop`, `FixedAspectRatio`, `Pop`, `Dim`, `Stage`, `stage`, `PanelGlow`, `Panel`, `night`

### `ReplicatedStorage.ChickenOrHero.Presentation.HoverShots` (ModuleScript)

`clamp`, `smooth`, `smoother`, `curve`, `DoorC0`, `Angles`, `DoorAngle`, `doorC0`, `DoorSill`, `lookAt`, `carAt`, `fromEulerAnglesYXZ`, `clone`, `ZVector`, `fromMatrix`, `bpitch`, `broll`, `Torso`, `Head`, `Board`, `gpitch`, `groll`, `solve`, `sample`, `motor`, `board`, `identity`, `RootJoint`, `Neck`, `Transform`, `release`, `freeze`, `Song`, `Crackle`, `Boom`, `Whoosh`, `Door`, `Ignite`, `Sounds`, `fromRGB`, `Cyan`, `Pink`, `Fire`, `Duration`, `Flashes`, `Set`, `Exit`, `Gone`, `Behind`, `High`, `Hover`, `Side`, `Run`, `Intro`, `Slide`, `Spin`, `Spun`, `Lift`, `OutFlashes`, `Ring`, `Finale`, `DoorTime`, `Drop`, `DropLand`, `Getaway`, `GetawayJump`, `GetawayIn`

### `ReplicatedStorage.ChickenOrHero.Presentation.HudDrawer` (ModuleScript)

`connect`, `contains`, `GetGuiInset`, `GetMouseLocation`, `mouseInside`, `version`, `available`, `pinned`, `opened`, `Arrow`, `Modal`, `Value`, `DrawerOpen`, `SelectedObject`, `IsDescendantOf`, `Drawer`, `Fire`, `setOpen`, `DrawerClip`, `setAvailable`, `isOpen`, `leave`, `positionDrawer`, `KeyboardAndMouse`, `MouseBehavior`, `Default`, `MenuIsOpen`, `Order`, `Navigation`, `ButtonB`, `Space`, `destroy`, `ensureDrawer`, `MenuToggle`, `Panel`, `DrawerReveal`, `MouseEnter`, `MouseLeave`, `WindowFocusReleased`, `GetService`

### `ReplicatedStorage.ChickenOrHero.Presentation.HudIcons` (ModuleScript)

`fromOffset`, `outline`, `Shop`, `Inventory`, `Spectate`, `Journey`, `AFK`, `Settings`, `Music`, `Servers`, `Updates`, `Coins`, `Gems`, `SkinAfkOff`, `fromScale`, `Icons`, `afkOff`, `GetService`, `ChickenOrHero`, `OldUIReskin`, `Skin`, `dagger`, `spectate`, `journey`, `music`, `MusicOff`, `scroll`, `Codes`, `Abilities`, `Combine`, `Clans`, `Rank`, `Names`

### `ReplicatedStorage.ChickenOrHero.Presentation.HudNavigation` (ModuleScript)

`handlers`, `Fire`, `register`, `available`, `setAvailable`, `states`, `setState`, `loaded`, `coins`, `wallet`, `Wallet`, `setWallet`, `activate`, `opening`, `BindableEvent`

### `ReplicatedStorage.ChickenOrHero.Presentation.HudStyle` (ModuleScript)

`Corner`, `corner`, `Colors`, `Panel`, `BorderStrokePosition`, `LineJoinMode`, `Inner`, `outline`, `textStroke`, `GetService`, `ChickenOrHero`, `OldUIReskin`, `Skin`, `Surface`, `Blue`, `Mint`, `Gold`, `Red`, `surface`, `textSecondary`, `meter`, `green`, `danger`, `neutral`

### `ReplicatedStorage.ChickenOrHero.Presentation.LeaderboardConfig` (ModuleScript)

`RefreshSeconds`, `WriteSeconds`, `WriteBatchSize`, `WriteSpacing`, `RankTitleDepth`, `RankRefreshSeconds`, `RankPageSpacing`, `Boards`, `SnapshotBoards`, `EventBoards`, `LMS`, `Levels`, `Catches`, `Wins`, `ModelName`, `LeaderboardLMS`, `DataStoreName`, `ChickenOrHero_LMSLeaderboard_v1`, `PageSize`, `Suffix`, `HoverStuds`, `HoverPeriod`, `TurnResponsiveness`, `AnimateDistance`, `LeaderboardLevels`, `ChickenOrHero_XPLeaderboard_v1`, `LEVEL`, `ValueFormat`, `Level`, `LeaderboardCatches`, `ChickenOrHero_CatchesLeaderboard_v1`, `CATCHES`, `LeaderboardWins`, `ChickenOrHero_WinsLeaderboard_v1`, `Ranked`, `RankedLMS`, `Souls`, `LeaderboardRanked`, `Container`, `Interactables`, `Snapshot`, `RankedBoard`, `RANKED`, `LeaderboardRankedLMS`, `RankedLMSBoard`, `StatName`, `SoulsLeaderboard`, `Throne`, `FallenKingBoard`, `SOULS`, `TeamFootball`, `TeamFutbol`, `LeaderboardFootball`, `Place`, `FootballEvent`, `PTS`, `LeaderboardFutbol`

### `ReplicatedStorage.ChickenOrHero.Presentation.LeaderboardHeader` (ModuleScript)

`UITextSizeConstraint`, `limit`, `MainFrame`, `SizingMode`, `SurfaceGuiSizingMode`, `PixelsPerStud`, `Face`, `NormalId`, `Front`, `fromScale`, `UISizeConstraint`, `Grow`, `TitleMax`, `StatusColor`, `Family`, `Heavy`, `Style`, `StatusMax`, `HeaderStroke`, `apply`, `restore`, `fromRGB`

### `ReplicatedStorage.ChickenOrHero.Presentation.LocalHide` (ModuleScript)

`saved`, `holding`, `function`, `ClassName`, `hideable`, `leftover`, `LocalTransparencyModifier`, `model`, `workspace`, `IsBot`, `Bots`, `Actors`, `LocalHidden`, `sweep`, `release`, `restore`, `GetService`, `LocalLooks`, `Fire`, `Smoke`, `Sparkles`, `__index`, `freeze`

### `ReplicatedStorage.ChickenOrHero.Presentation.LocalLooks` (ModuleScript)

`unset`, `__mode`, `release`

### `ReplicatedStorage.ChickenOrHero.Presentation.MapPreviewCopy` (ModuleScript)

`IsTenFootInterface`, `VREnabled`, `MouseEnabled`, `KeyboardEnabled`, `Detail`, `clone`, `GetService`

### `ReplicatedStorage.ChickenOrHero.Presentation.MapVoteTiming` (ModuleScript)

`number`, `ArrivalBreatherSeconds`, `canPresent`, `Voting`, `shouldExpand`

### `ReplicatedStorage.ChickenOrHero.Presentation.MapVoteView` (ModuleScript)

`layout`, `press`, `input`, `MouseMovement`, `position`, `dragged`, `MapVoteUI`, `ScreenInsets`, `ZIndexBehavior`, `DeviceSafeInsets`, `Sibling`, `Shade`, `fromScale`, `fullscreenShade`, `shade`, `BlurEffect`, `MapVoteBlur`, `GetService`, `CanvasGroup`, `Ballot`, `GroupTransparency`, `surface`, `Gold`, `neutral`, `Timer`, `Modal`, `Maps`, `ScrollBarThickness`, `ScrollBarImageColor3`, `ScrollingDirection`, `ClipsDescendants`, `scroll`, `Footer`, `NumberValue`, `Reveal`, `Value`, `Expansion`, `expansion`, `expanded`, `panel`, `heading`, `timer`, `footer`, `reveal`, `records`, `signature`, `shown`, `close`, `tween`, `setVisible`, `CanvasPosition`, `expandTween`, `setExpanded`, `round`, `clamp`, `textSize`, `bottom`, `fromOffset`, `SkinOutline`, `BackgroundBlurSize`, `preview`, `detail`, `votes`, `ribbon`, `badge`, `tagged`, `image`, `MapPreviews`, `previewId`, `previewSource`, `ClearAllChildren`, `clone`, `lookAt`, `canvas`, `result`, `onVote`, `glowBorder`, `accent`, `corner`, `Arena`, `Crop`, `fromRGB`, `Fade`, `NumberSequenceKeypoint`, `Detail`, `Votes`, `limitedTime`, `Tag`, `LimitedTime`, `color`, `tagColor`, `danger`, `SkinTextStroke`, `Winner`, `mapId`, `build`, `options`, `phase`, `Result`, `counts`, `winner`, `gamepad`, `ImageTransparency`, `render`, `PAUSED`, `clock`, `destroy`, `ChickenOrHero`, `OldUIReskin`, `Skin`, `Theme`, `NotificationDock`, `Game`, `MapVoteConfig`, `Presentation`, `MapPreviewCopy`, `__index`

### `ReplicatedStorage.ChickenOrHero.Presentation.MatchSummaryConfig` (ModuleScript)

`freeze`, `BackdropTransparency`, `BackgroundBlurSize`, `FadeIn`, `FadeOut`, `MaxParticipants`, `StageSeconds`, `StageFade`, `SideRevealDelay`, `SoloWinSeconds`, `CountDelay`, `CountDuration`, `CountTickInterval`

### `ReplicatedStorage.ChickenOrHero.Presentation.NotificationDock` (ModuleScript)

`Notifications`, `MainFrame`, `NotificationsF`, `EscapeStreak`, `ChoiceAnnouncement`, `bottom`

### `ReplicatedStorage.ChickenOrHero.Presentation.NotificationLayout` (ModuleScript)

`UITextSizeConstraint`, `label`, `MainFrame`, `clamp`, `ValleyHUD`, `AdminUI`, `Servers`, `Updates`, `OpenBroadcast`, `fromOffset`, `resize`, `NotificationsF`, `UIProportionalGroup`, `Proportions`, `SizeLimits`, `fromScale`, `Location`, `WhatsHappening`, `EscapeStreak`, `Caption`, `Count`, `Segments`, `ChoiceAnnouncement`, `Description`, `apply`

### `ReplicatedStorage.ChickenOrHero.Presentation.OverheadConfig` (ModuleScript)

`ShowOwnName`

### `ReplicatedStorage.ChickenOrHero.Presentation.OverheadView` (ModuleScript)

`GetTextSize`, `textWidth`, `fromScale`, `place`, `separator`, `floor`, `Width`, `SizeOffset`, `StudsOffset`, `HeadOffset`, `StudsOffsetWorldSpace`, `ExtentsOffset`, `ExtentsOffsetWorldSpace`, `MaxDistance`, `AlwaysOnTop`, `LightInfluence`, `ClipsDescendants`, `Content`, `UISizeConstraint`, `UITextSizeConstraint`, `DisplayName`, `SpecialRank`, `JourneyTitle`, `Wins`, `Lvl`, `AFK`, `Username`, `fromRGB`, `Gold`, `TitleDot`, `StatDot1`, `StatDot2`, `RankIcon`, `apply`, `layout`, `TextService`, `GetService`, `ValleyTheme`

### `ReplicatedStorage.ChickenOrHero.Presentation.ParticipantDirectory` (ModuleScript)

`PracticeActive`, `UserId`, `world`, `remove`, `record`, `IsBot`, `Bots`, `Actors`, `DisplayName`, `Value`, `GetService`, `IsClient`, `FFlags`, `ClientBots`, `BotDirectory`

### `ReplicatedStorage.ChickenOrHero.Presentation.PirateShots` (ModuleScript)

`Finale`, `Fire`, `Flight`, `landAt`, `Roll`, `Settle`, `poseAt`, `Joints`, `identity`, `blend`, `motor`, `Root`, `release`, `clamp`, `smooth`, `smoother`, `Angles`, `freeze`, `Song`, `Bell`, `Cannon`, `Blast`, `Fuse`, `Whoosh`, `Thud`, `Coins`, `Sounds`, `fromRGB`, `Gold`, `Ghost`, `Duration`, `ShipIn`, `ShipSet`, `Flag`, `Salute`, `Gap`, `Point`, `ShipBack`, `ShipSink`, `Intro`, `Rise`, `Stand`, `Distance`, `RollDistance`, `Peak`, `Spins`, `RollSpins`, `RootJoint`, `Neck`, `RightArm`, `LeftArm`, `RightLeg`, `LeftLeg`, `Neutral`, `Tuck`, `Hero`, `Poses`

### `ReplicatedStorage.ChickenOrHero.Presentation.PostMatchProgress` (ModuleScript)

`floor`, `reverse`, `comma`, `clamp`, `Before`, `Gain`, `fromScale`, `setBar`, `Gear`, `AbilityUpgradeMenu`, `changes`, `concat`, `nextEffect`, `Badge`, `EmoteId`, `SkinId`, `Dodge`, `Coins`, `Gems`, `Keys`, `Tokens`, `Spins`, `CandyCorn`, `Note`, `knife`, `Knife`, `emote`, `Emote`, `Badges`, `HalloweenEmote`, `KeyCrate`, `Crate`, `image`, `TokenIcon`, `Reward`, `describe`, `Weapons`, `Light`, `Stowed`, `fromRGB`, `Blade`, `ThumbAxis`, `ThumbNormal`, `VectorToWorldSpace`, `fromMatrix`, `lookAt`, `knifeArt`, `Interface`, `EmotePose`, `poses`, `emoteArt`, `destroy`, `proto`, `ImageTransparency`, `imageText`, `Amount`, `claim`, `Claim`, `Claimed`, `LiveColor`, `Claimable`, `setButton`, `KeyboardEnabled`, `close`, `PaddingLeft`, `earned`, `round`, `frame`, `fromOffset`, `ScrollBarThickness`, `layout`, `Progression`, `JourneyEvent`, `claiming`, `clone`, `journey`, `claims`, `before`, `claimOrigin`, `ClaimAll`, `SeasonId`, `FireServer`, `PromptGamePassPurchase`, `PremiumPassId`, `PostMatchProgress`, `PostMatchProgressShade`, `started`, `panel`, `clock`, `MatchSummaryUI`, `MatchResult`, `NextMatch`, `Chip`, `Crossings`, `crossingXP`, `Catches`, `catchXP`, `Win`, `winXP`, `Bonus`, `bonusXP`, `Level`, `level`, `LevelUp`, `Foot`, `format`, `xpBefore`, `summaryRange`, `Next`, `Head`, `Body`, `RewardIcon`, `DominantAxis`, `Height`, `levelIcon`, `levelPad`, `padLevelIcon`, `TokensList`, `abilityTokens`, `number`

### `ReplicatedStorage.ChickenOrHero.Presentation.PracticeScreen` (ModuleScript)

`OldUIReskin`, `Skin`, `GetService`, `FFlags`, `awaitUIVersion`, `NewGui`, `Interface`, `Toasts`, `ValleyToast`, `textStroke`, `label`, `skinButton`, `panel`, `accent`, `surface`, `Corner`, `neutral`, `Ring`, `Selectable`, `fromScale`, `bindStates`, `fromOffset`, `Key`, `GetImageForKeyCode`, `DPadDown`, `KeyRoom`, `Pop`, `popIn`, `onPractice`, `onClose`, `onPick`, `onLeave`, `onStay`, `shown`, `resultVersion`, `ZIndexBehavior`, `Sibling`, `Practice`, `Column`, `FillDirection`, `HorizontalAlignment`, `Padding`, `Vertical`, `Layout`, `scale`, `column`, `PracticeButton`, `primary`, `PRACTICE`, `Caption`, `practice`, `practiceLabel`, `practiceCaption`, `practiceKey`, `practicePop`, `practiceKind`, `PracticeDock`, `dockScale`, `Picker`, `close`, `Sides`, `ImageColor3`, `color`, `Role`, `Against`, `against`, `Goal`, `textBody`, `NextSelectionRight`, `NextSelectionLeft`, `Footer`, `textMuted`, `picker`, `Hud`, `VerticalAlignment`, `Horizontal`, `Score`, `shimmer`, `PaddingLeft`, `PaddingRight`, `Clock`, `What`, `ESCAPES`, `Count`, `Leave`, `LEAVE`, `danger`, `clock`, `count`, `leave`, `leaveLabel`, `leaveKey`, `Live`, `Staying`, `boost`, `staying`, `Result`, `Next`, `result`, `resultTitle`, `resultCount`, `resultPop`, `Warning`, `Body`, `Stay`, `secondary`, `warning`, `warningTitle`, `stayLabel`, `stayKey`, `warningPop`, `floor`, `place`, `dockButton`, `setButton`, `pickerOpen`, `SelectedObject`, `IsDescendantOf`, `setPicker`, `CATCHES`

### `ReplicatedStorage.ChickenOrHero.Presentation.PracticeWorlds` (ModuleScript)

`PracticeActive`, `UserId`, `leftover`, `roots`, `newVeil`, `wanted`, `property`, `connection`, `quiet`, `ClassName`, `looks`, `LocalTransparencyModifier`, `loose`, `Light`, `hideItem`, `release`, `GetFullName`, `IsDescendantOf`, `uncover`, `DescendantRemoving`, `AncestryChanged`, `cover`, `clone`, `reassert`, `workspace`, `players`, `added`, `removing`, `focus`, `veils`, `folders`, `folderWatch`, `watched`, `started`, `hides`, `PlayerOverhead_`, `plateOf`, `sortPlayer`, `PracticeOwner`, `number`, `ownerOf`, `sortFolder`, `sortAll`, `watchPlayer`, `dropPlayer`, `watchFolder`, `dropFolder`, `Worlds`, `worlds`, `watchMap`, `dropMap`, `PracticeMap1`, `start`, `count`, `counts`, `foreign`, `apart`, `GetService`, `LocalLooks`, `Fire`, `Smoke`, `Sparkles`, `Highlight`, `__index`

### `ReplicatedStorage.ChickenOrHero.Presentation.PrivateHostModel` (ModuleScript)

`GetPlayerByUserId`, `DisplayName`, `nameOf`, `cycle`, `lower`, `sorted`, `UserId`, `FireServer`, `activate`, `HostPanel`, `Modes`, `SetMode`, `Normal`, `tournament`, `running`, `SetMap`, `SetLead`, `starter`, `SetStarter`, `clamp`, `TourSet`, `stepper`, `matches`, `basePoints`, `points`, `lmsPoints`, `catchPoints`, `revivePoints`, `Abilities`, `abilities`, `TourStart`, `TourEnd`, `clock`, `frozen`, `Freeze`, `EndMatch`, `flying`, `Fly`, `close`, `CreatorCamera`, `CreatorCameraActive`, `STOP`, `renderCamera`, `Hold`, `status`, `confirmThen`, `Kick`, `Ban`, `userId`, `banIds`, `Unban`, `match`, `Invite`, `HostButtonHidden`, `Fire`, `confirmText`, `ModeNames`, `END`, `KICK`, `BAN`, `Nobody`, `UNBAN`, `banLimit`, `format`, `rewardsOff`, `played`, `finalTop`, `Off`, `AbilityNames`, `rules`, `START`, `standings`, `total`, `gained`, `render`, `Reply`, `message`, `isOpen`, `setLauncherVisible`, `launcher`, `PrivateHostEvent`, `buildHost`, `section`, `picker`, `Mode`, `Map`, `Tournament`, `MaxMatches`, `Matches`, `MaxBasePoints`, `Tiers`, `MaxTop`, `MaxPoints`, `MaxLmsPoints`, `MaxCatchPoints`, `MaxRevivePoints`, `action`, `Game`, `toggle`, `Player`, `Banned`, `input`, `SEND`, `HIDE`, `OnClientEvent`, `Sync`, `Accept`, `Decline`, `closeInvite`, `fromName`, `PrivateInvitesOff`, `invite`, `expiresAt`, `number`, `workspace`, `Result`, `PrivateInviteEvent`, `invites`, `ClientReady`, `PrivateServerRewardsOff`

### `ReplicatedStorage.ChickenOrHero.Presentation.ProUnlockCutscene` (ModuleScript)

`GameAudio`, `sound`, `Ended`, `asset`, `tween`, `ProEffectOn`, `LocalTransparencyModifier`, `workspace`, `stage`, `WorldPivot`, `grounded`, `LightEmission`, `Lifetime`, `Speed`, `SpreadAngle`, `Drag`, `Rate`, `NumberSequenceKeypoint`, `Emit`, `burst`, `lookAt`, `fromScale`, `UITextSizeConstraint`, `PlayerScripts`, `PlayerModule`, `GetControls`, `CreatorCaptureExempt`, `destroy`, `restore`, `Enable`, `CameraType`, `Scriptable`, `Custom`, `CameraSubject`, `ProUnlockActive`, `Fire`, `finish`, `InMatch`, `CutsceneActive`, `IsDescendantOf`, `Value`, `ScaleTo`, `GetScale`, `NumberValue`, `scale`, `clock`, `Angles`, `Shackle`, `Brightness`, `LockBody`, `Chain`, `fromRGB`, `Range`, `PointLight`, `Quart`, `Base`, `Podium`, `Star`, `SmallPodium`, `Lock`, `BindableEvent`, `ProUnlock`, `Flash`, `Skip`, `SKIP`, `CreatorUIHidden`, `setHidden`, `sweep`, `model`, `Disable`, `AncestryChanged`, `GetService`, `CutsceneScreen`, `CreatorVisibility`, `LocalHide`, `LockFace`, `Keyhole`

### `ReplicatedStorage.ChickenOrHero.Presentation.PumpkinAltar` (ModuleScript)

`Game`, `RandomPrizePolicy`, `start`, `restricted`, `BindableEvent`, `alive`, `Tag`, `GetTagged`, `workspace`, `IsDescendantOf`, `Bowl`, `pedestal`, `CameraSpot`, `lookAt`, `WorldPosition`, `shotOf`, `saved`, `remember`, `LocalTransparencyModifier`, `format`, `sweepLeftovers`, `suppress`, `wanted`, `plates`, `PlayerOverhead_`, `connection`, `watchPlate`, `showPlates`, `sweep`, `character`, `model`, `hideAll`, `Knife`, `Blade`, `GripPoint`, `PivotOffset`, `fromMatrix`, `PumpkinAltarShowcase`, `CastShadow`, `ScaleTo`, `Glow`, `PointLight`, `fromRGB`, `Brightness`, `Range`, `Shadows`, `LightEmission`, `LightInfluence`, `NumberSequenceKeypoint`, `Lifetime`, `Speed`, `SpreadAngle`, `Rate`, `buildShowcase`, `frame`, `camera`, `ViewportSize`, `VectorToWorldSpace`, `showcaseCentre`, `showcase`, `stopShowcase`, `inside`, `dragging`, `flick`, `MouseMovement`, `pitch`, `clamp`, `clock`, `fromAxisAngle`, `finishing`, `GetService`, `startShowcase`, `flight`, `leave`, `instant`, `CameraType`, `Scriptable`, `Custom`, `subject`, `CameraSubject`, `restoreCamera`, `abort`, `urgent`, `InMatch`, `MapChanging`, `CutsceneActive`, `offset`, `external`, `restore`, `PumpkinAltarActive`, `finish`, `AncestryChanged`, `enter`, `PumpkinSacrificeOpen`, `closed`, `altarOut`, `altarIn`, `available`, `UNAVAILABLE`, `opening`, `PumpkinSacrifice`, `opened`, `setOpen`, `WorldToViewportPoint`, `GetGuiInset`, `close`, `isOpen`, `setAvailable`, `match`, `respawn`, `altar`, `PumpkinAltar`, `ZIndexBehavior`, `Sibling`, `sparkTarget`, `closeButton`, `register`, `visit`, `CollectionService`, `ChickenOrHero`

### `ReplicatedStorage.ChickenOrHero.Presentation.PumpkinFloat` (ModuleScript)

`backOut`, `smooth`, `clock`, `IsPlaying`, `Sounds`, `parent`, `volume`, `RollOffMode`, `RollOffMinDistance`, `RollOffMaxDistance`, `IsLoaded`, `Loaded`, `sound`, `CastShadow`, `quiet`, `invisible`, `KnifeChanceMin`, `KnifeChanceMax`, `clamp`, `lookOf`, `PumpkinHuntAssets`, `OpeningPumpkin`, `Pumpkin`, `Shell`, `pumpkinSource`, `DataModelMesh`, `SurfaceAppearance`, `SpecialMesh`, `baseSize`, `baseMesh`, `baseOffset`, `baseVertex`, `squash`, `blaze`, `bornAt`, `isPumpkin`, `VertexColor`, `Lamp`, `Shadows`, `PointLight`, `Glow`, `PullShell`, `LightEmission`, `LightInfluence`, `Shape`, `ShapeInOut`, `ShapeStyle`, `Lifetime`, `ParticleEmitterShape`, `Sphere`, `ParticleEmitterShapeInOut`, `Inward`, `ParticleEmitterShapeStyle`, `Surface`, `Pull`, `light`, `shell`, `buildPumpkin`, `strength`, `fading`, `Brightness`, `Range`, `fullF`, `NumberSequenceKeypoint`, `Speed`, `dress`, `Blade`, `GripPoint`, `PivotOffset`, `fromMatrix`, `Knife`, `ScaleTo`, `model`, `scaled`, `middle`, `stand`, `turns`, `knifePrize`, `Picture`, `NormalId`, `Front`, `Face`, `SizingMode`, `ClipsDescendants`, `ZIndexBehavior`, `SurfaceGuiSizingMode`, `FixedSize`, `Sibling`, `fromScale`, `fromRGB`, `Boost`, `StrokeSizingMode`, `LineJoinMode`, `ScaledSize`, `picturePrize`, `SpinWheel`, `Main`, `Wheel`, `PartType`, `Cylinder`, `SmoothPlastic`, `Disc`, `extra`, `spinner`, `offset`, `Angles`, `Spinner`, `wheelPrize`, `knife`, `Spins`, `SPIN`, `Gems`, `GemBoostMinutes`, `CandyCorn`, `GhostKeys`, `CoinBoostMinutes`, `prizeFor`, `stage`, `token`, `hover`

### `ReplicatedStorage.ChickenOrHero.Presentation.PumpkinRoll` (ModuleScript)

`RollOffMaxDistance`, `AddItem`, `sound`, `workspace`, `fromRGB`, `Lifetime`, `Speed`, `SpreadAngle`, `Drag`, `Rate`, `Emit`, `LightEmission`, `Acceleration`, `RaycastParams`, `RaycastFilterType`, `Exclude`, `FilterType`, `FilterDescendantsInstances`, `RespectCanCollide`, `random`, `Spherecast`, `Distance`, `FillTransparency`, `OutlineTransparency`, `WorldPosition`, `Terrain`, `restore`, `KillEffectHidden`, `onDone`, `finish`, `clock`, `cancel`, `ScaleTo`, `fromAxisAngle`, `scale`, `Torso`, `UpperTorso`, `GetService`, `PumpkinHuntAssets`, `Pumpkin`, `CastShadow`, `GetScale`, `PumpkinRoll`, `lookAt`, `BotUserId`, `model`, `FallenKingLocal`, `Lantern`, `parent`, `Highlight`, `FillColor`, `OutlineColor`, `HighlightDepthMode`, `Occluded`, `DepthMode`, `Debris`, `LocalHide`, `Poof`, `Roll`, `Burst`

### `ReplicatedStorage.ChickenOrHero.Presentation.PumpkinScreen` (ModuleScript)

`Game`, `RandomPrizePolicy`, `start`, `restricted`, `BindableEvent`, `count`, `counted`, `Fire`, `fromRGB`, `rarityColor`, `Knife`, `COMMON`, `rarityOf`, `corner`, `LineJoinMode`, `StrokeSizingMode`, `ScaledSize`, `Outline`, `Ring`, `rings`, `white`, `label`, `Interactable`, `picture`, `close`, `setLook`, `fromScale`, `CanvasGroup`, `ImageTransparency`, `TileSize`, `Tile`, `NumberSequenceKeypoint`, `setEnabled`, `Blade`, `World`, `Angles`, `VectorToWorldSpace`, `lookAt`, `knifeIcon`, `Spin`, `SPIN`, `spinToken`, `Spins`, `Gems`, `GemBoostMinutes`, `CandyCorn`, `GhostKeys`, `CoinBoostMinutes`, `Boost`, `prizeIcon`, `knife`, `duplicateGems`, `prizeText`, `Sounds`, `Ended`, `KnifeChanceMin`, `KnifeChanceMax`, `luckOf`, `frame`, `animation`, `rowHeight`, `stacks`, `total`, `embers`, `Pumpkins`, `AspectRatio`, `FixedAspectRatio`, `Pop`, `Dim`, `HalloweenNight`, `ImageColor3`, `Glow`, `MoonGlow`, `moonGlow`, `Moon`, `Fog`, `Bat`, `image`, `speed`, `phase`, `Ember`, `witch`, `ember`, `pumpkin`, `titleStroke`, `Count`, `leftText`, `Next`, `Square`, `stage`, `Halo`, `GlowGold`, `EyeGlow`, `Pumpkin`, `pumpkinScale`, `NextTag`, `NEXT`, `nextTag`, `Reveal`, `Rays`, `revealRays`, `revealIcon`, `revealScale`, `revealName`, `reveal`, `Flash`, `flash`, `Zoom`, `stageScale`, `OpenFX`, `fxLayer`, `OpenFXBack`, `backFx`, `Rays2`, `revealRays2`, `Rarity`, `revealBanner`, `Slam`, `bannerScale`, `BigFlash`

### `ReplicatedStorage.ChickenOrHero.Presentation.QuestNotice` (ModuleScript)

`Daily`, `daily`, `quests`, `concat`, `format`, `event`, `activeWeapon`, `loaded`, `complete`, `claimed`, `claimsEnabled`, `weapons`, `claimable`, `SettingsLoaded`, `QuestsSeen`, `QuestsSeenKey`

### `ReplicatedStorage.ChickenOrHero.Presentation.ReachPose` (ModuleScript)

`atan2`, `clamp`, `lookAt`, `Angles`, `transform`

### `ReplicatedStorage.ChickenOrHero.Presentation.RecapHighlights` (ModuleScript)

`floor`, `format`, `timeText`, `manual`, `workspace`, `StageSeconds`, `manualUntil`, `setStage`, `panel`, `portraits`, `tweens`, `revision`, `First`, `Second`, `Third`, `Stage`, `position`, `Tabs`, `cancel`, `tween`, `GroupTransparency`, `reveal`, `index`, `stageAt`, `rankings`, `StageTitle`, `title`, `color`, `StageFade`, `Empty`, `empty`, `userId`, `award`, `PlayerName`, `verified`, `Rank`, `tiedCount`, `Metric`, `fromScale`, `SideRevealDelay`, `fromRGB`, `Underline`, `RecapOpen`, `participants`, `update`, `shownAt`, `clamp`, `survival`, `value`, `CATCH`, `CATCHES`, `destroy`, `GetService`, `AvatarPortraits`, `VerifiedName`, `__index`, `catches`

### `ReplicatedStorage.ChickenOrHero.Presentation.RecapRewards` (ModuleScript)

`frame`, `player`, `CountDelay`, `started`, `lastTick`, `lastEarned`, `completed`, `levelCue`, `LevelUp`, `update`, `CountDuration`, `clamp`, `crossingXP`, `round`, `catchXP`, `winXP`, `bonusXP`, `Amount`, `Breakdown`, `concat`, `xpBefore`, `StatsLoaded`, `TotalXP`, `earnedXP`, `Level`, `level`, `Progress`, `earned`, `needed`, `format`, `fromScale`, `ratio`, `fromRGB`, `CountTickInterval`, `RecapTick`, `RecapLevelUp`, `RecapComplete`, `destroy`, `Progression`, `ProgressionMath`, `__index`

### `ReplicatedStorage.ChickenOrHero.Presentation.RecapSoloWin` (ModuleScript)

`soloWinnerUserId`, `number`, `participants`, `userId`, `caught`, `hasRun`, `winner`, `frame`, `portraits`, `tweens`, `PlayerName`, `format`, `verified`, `GroupTransparency`, `RevealScale`, `RecapOpen`, `destroy`, `GetService`, `AvatarPortraits`, `VerifiedName`, `__index`

### `ReplicatedStorage.ChickenOrHero.Presentation.ReviveMarkers` (ModuleScript)

`workspace`, `records`, `WorldToViewportPoint`, `fromOffset`, `ReviveMarkers`, `ScreenInsets`, `ClipToDeviceSafeArea`, `folder`, `GetService`, `render`, `Revive`, `ClipsDescendants`, `Circle`, `fromScale`, `fromRGB`, `corner`, `Ring`, `REVIVE`, `label`, `create`, `RescueAvailable`, `Ragdolled`, `RescueHelperId`, `clamp`, `UserId`, `REVIVING`, `HELPING`, `update`, `destroy`, `ValleyPanels`, `__index`

### `ReplicatedStorage.ChickenOrHero.Presentation.SacrificeScreen` (ModuleScript)

`Game`, `RandomPrizePolicy`, `start`, `restricted`, `BindableEvent`, `fromRGB`, `rarityColor`, `corner`, `LineJoinMode`, `StrokeSizingMode`, `ScaledSize`, `Outline`, `Ring`, `rings`, `white`, `label`, `Interactable`, `picture`, `close`, `Look`, `setLook`, `fromScale`, `CanvasGroup`, `ImageTransparency`, `TileSize`, `Tile`, `NumberSequenceKeypoint`, `setEnabled`, `Blade`, `Knife`, `World`, `Angles`, `VectorToWorldSpace`, `lookAt`, `knifeIcon`, `Spin`, `ExtraBold`, `SPIN`, `spinToken`, `clamp`, `Sounds`, `Ended`, `floor`, `format`, `clock`, `frame`, `closed`, `refresh`, `altar`, `coins`, `localPending`, `lastClick`, `embers`, `PumpkinSacrifice`, `AspectRatio`, `FixedAspectRatio`, `Pop`, `Dim`, `HalloweenNight`, `ImageColor3`, `Glow`, `MoonGlow`, `Moon`, `Fog`, `Bat`, `image`, `speed`, `phase`, `Ember`, `witch`, `ember`, `upper`, `EventName`, `pumpkin`, `titleStroke`, `Timer`, `timer`, `Info`, `Pumpkin`, `Square`, `stage`, `Halo`, `GlowGold`, `EyeGlow`, `pumpkinPop`, `ChanceTitle`, `chanceTitle`, `Chance`, `chanceText`, `chancePops`, `track`, `Bar`, `ClipsDescendants`, `Clip`, `fillGradient`, `Flash`, `flash`, `barText`, `Stage`, `stageText`, `Sacrifice`, `SACRIFICE`, `ctaPop`, `CloseButton`, `closeButton`, `status`, `AmountTitle`, `chips`, `Pot`, `Amounts`, `Amount`, `short`, `Coins`, `Coin`, `coinText`, `OddsButton`, `Mark`, `Caption`, `Odds`, `oddsButton`

### `ReplicatedStorage.ChickenOrHero.Presentation.ServerBrowserView` (ModuleScript)

`Mint`, `Blue`, `shimmer`, `styleCountry`, `textStroke`, `label`, `UIProportionalGroup`, `UITextSizeConstraint`, `UISizeConstraint`, `ProportionalScale`, `cleanLegacy`, `current`, `green`, `radius`, `Join`, `primary`, `secondary`, `styleRow`, `Panel`, `Templates`, `ServerRow`, `surface`, `panel`, `transparency`, `TopRule`, `Eyebrow`, `Gold`, `Connection`, `HeaderRule`, `color`, `neutral`, `Count`, `ScrollBarThickness`, `ScrollBarImageColor3`, `ClipsDescendants`, `Countries`, `scroll`, `Padding`, `Layout`, `PreviousPage`, `NextPage`, `PageLabel`, `Refresh`, `Sort`, `close`, `Modal`, `Explanation`, `Empty`, `List`, `ScrollingDirection`, `ScrollingEnabled`, `AutomaticCanvasSize`, `ScrollBarInset`, `Always`, `VerticalScrollBarInset`, `PaddingTop`, `PaddingBottom`, `PaddingLeft`, `PaddingRight`, `fromOffset`, `Details`, `Region`, `Ping`, `apply`, `GetService`, `GetGuiInset`, `FillDirection`, `Horizontal`, `Vertical`, `layout`, `ChickenOrHero`, `OldUIReskin`, `Skin`, `Theme`

### `ReplicatedStorage.ChickenOrHero.Presentation.SettingsSync` (ModuleScript)

`Keys`, `Save`, `FireServer`, `queueSave`, `Loaded`, `QuestsSeenKey`, `BundleSeen`, `SettingsLoaded`, `QuestsSeen`, `SettingsEvent`, `OnClientEvent`, `Get`, `start`, `GetService`, `freeze`, `MusicVolume`, `MusicMuted`, `EmoteVolume`, `EmoteSoundsMuted`, `SpectatorHints`, `ChatNotificationsEnabled`, `AutoRollRunner`, `QuestTrackerClosed`, `HostButtonHidden`, `PrivateInvitesOff`, `HideBoardRank`, `RankedRegions`, `RankedWidth`, `RankedIntroHidden`, `RollingDodgeOff`, `IceSkatesOff`, `SnowFlurryOff`

### `ReplicatedStorage.ChickenOrHero.Presentation.SoulShock` (ModuleScript)

`IsCollisionGroupRegistered`, `CoHRagdoll`, `Default`, `RollOffMinDistance`, `RollOffMaxDistance`, `AddItem`, `sound`, `Massless`, `CastShadow`, `CollisionGroup`, `workspace`, `Lifetime`, `Speed`, `SpreadAngle`, `Drag`, `Rate`, `Emit`, `LightEmission`, `Acceleration`, `frost`, `Soul`, `PointLight`, `Range`, `Brightness`, `fromScale`, `LightInfluence`, `ImageColor3`, `LockedToPart`, `NumberSequenceKeypoint`, `RotSpeed`, `ZOffset`, `board`, `ghost`, `flare`, `light`, `stars`, `shards`, `random`, `WedgePart`, `SmoothPlastic`, `Reflectance`, `Angles`, `AssemblyAngularVelocity`, `shatter`, `restore`, `KillEffectHidden`, `onDone`, `finish`, `clock`, `cancel`, `frozen`, `clamp`, `burst`, `Shatter`, `ImageTransparency`, `Torso`, `SoulShock`, `Head`, `BotUserId`, `model`, `GetService`, `FallenKingLocal`, `Lantern`, `Highlight`, `FillTransparency`, `OutlineColor`, `OutlineTransparency`, `HighlightDepthMode`, `Occluded`, `DepthMode`, `parent`, `Freeze`, `PhysicsService`, `Debris`, `LocalHide`, `fromRGB`, `LeftArm`, `RightArm`, `LeftLeg`, `RightLeg`, `Ice`

### `ReplicatedStorage.ChickenOrHero.Presentation.SpectateCamera` (ModuleScript)

`angles`, `position`, `pitch`, `yawGoal`, `pitchGoal`, `distance`, `distanceGoal`, `velocity`, `clamp`, `OrbitDistance`, `MinPitch`, `MaxPitch`, `MinDistance`, `MaxDistance`, `resetPosition`, `RaycastParams`, `RaycastFilterType`, `Exclude`, `FilterType`, `RespectCanCollide`, `clone`, `FilterDescendantsInstances`, `workspace`, `CameraRadius`, `Spherecast`, `Distance`, `Normal`, `travel`, `alpha`, `LookSmoothness`, `fromOrientation`, `Free`, `VectorToWorldSpace`, `FastSpeed`, `Speed`, `speedScale`, `Acceleration`, `focus`, `FollowSmoothness`, `lookAt`, `SpectateConfig`, `SpectateGeometry`, `__index`

### `ReplicatedStorage.ChickenOrHero.Presentation.SpectateConfig` (ModuleScript)

`freeze`, `Speed`, `FastSpeed`, `Acceleration`, `LookSmoothness`, `FollowSmoothness`, `MouseSensitivity`, `TouchSensitivity`, `GamepadLookSpeed`, `OrbitDistance`, `MinDistance`, `MaxDistance`, `MinPitch`, `MaxPitch`, `FieldInset`, `MinHeight`, `MaxHeight`, `CameraRadius`, `FocusInterval`

### `ReplicatedStorage.ChickenOrHero.Presentation.SpectateGeometry` (ModuleScript)

`number`, `finite`, `vector`, `valid`, `PointToObjectSpace`, `clamp`, `PointToWorldSpace`, `inside`, `UnionOperation`, `FieldInset`, `MinHeight`, `MaxHeight`, `InvisWall`, `bounds`, `WeaponVFX`, `creatorBounds`, `alpha`, `atan2`, `angles`, `deadzone`, `freeze`

### `ReplicatedStorage.ChickenOrHero.Presentation.SpectateInput` (ModuleScript)

`connect`, `CreatorPanelOpen`, `GlobalWheelOpen`, `focused`, `MenuIsOpen`, `blocked`, `touch`, `point`, `stick`, `updatePad`, `padTouch`, `holds`, `ButtonB`, `Stop`, `lookTouch`, `Follow`, `workspace`, `ViewportSize`, `lastTouch`, `ButtonL1`, `Previous`, `ButtonR1`, `Next`, `ButtonY`, `Toggle`, `delta`, `TouchSensitivity`, `MouseMovement`, `LeftAlt`, `IsKeyDown`, `RightAlt`, `Delta`, `MouseSensitivity`, `MouseWheel`, `fromScale`, `reset`, `MouseBehavior`, `Default`, `MouseIconEnabled`, `LeftShift`, `GamepadEnabled`, `Gamepad1`, `GetGamepadState`, `Thumbstick1`, `deadzone`, `Thumbstick2`, `GamepadLookSpeed`, `ButtonR2`, `ButtonL2`, `Free`, `sample`, `destroy`, `WindowFocusReleased`, `WindowFocused`, `GetService`, `SpectateConfig`, `SpectateGeometry`

### `ReplicatedStorage.ChickenOrHero.Presentation.SpectateView` (ModuleScript)

`hintVersion`, `fromOffset`, `scale`, `label`, `follow`, `hintButton`, `zoomIn`, `zoomOut`, `layout`, `touch`, `gamepad`, `Free`, `SpectatorHints`, `Follow`, `skinMode`, `render`, `connection`, `hintConnection`, `destroy`, `screen`, `ValleySpectate`, `Open`, `fromRGB`, `Controls`, `corner`, `stroke`, `Blue`, `panel`, `transparency`, `WATCHING`, `Subject`, `Role`, `Previous`, `secondary`, `Next`, `FOLLOW`, `Exit`, `danger`, `ControlHint`, `HintToggle`, `FlightPad`, `Knob`, `fromScale`, `MOVE`, `Down`, `ZoomIn`, `ZoomOut`, `GetService`, `ChickenOrHero`, `OldUIReskin`, `Skin`

### `ReplicatedStorage.ChickenOrHero.Presentation.ThreatIndicatorConfig` (ModuleScript)

`freeze`, `MaxDistance`, `NearDistance`, `MaxHeightDifference`, `MinClosingSpeed`, `MaxThreats`, `ArcWidth`, `UpdateInterval`, `FadeInTime`, `FadeOutTime`, `MaxOpacity`

### `ReplicatedStorage.ChickenOrHero.Presentation.ThreatIndicatorModel` (ModuleScript)

`MaxHeightDifference`, `MaxDistance`, `NearDistance`, `MinClosingSpeed`, `clamp`, `atan2`, `angle`, `strength`, `distance`, `sample`, `sector`

### `ReplicatedStorage.ChickenOrHero.Presentation.TouchActionButton` (ModuleScript)

`Interactable`, `format`, `update`, `GetService`

### `ReplicatedStorage.ChickenOrHero.Presentation.TouchCombatLayout` (ModuleScript)

`Catch`, `Melee`, `Dive`, `Ability`, `Item`, `rectangles`, `UIProportionalExclude`, `UIProportionalGroup`, `ProportionalScale`, `workspace`, `HUD`, `ViewportSize`, `FindFirstAncestorWhichIsA`, `GetGuiInset`, `fromOffset`, `place`, `GetService`

### `ReplicatedStorage.ChickenOrHero.Presentation.UIVersionSwap` (ModuleScript)

`gmatch`, `Replaces`, `collect`, `OldUIReskin`, `Replacements`, `GetFullName`, `format`, `swapIn`

### `ReplicatedStorage.ChickenOrHero.Presentation.UpdateLogConfig` (ModuleScript)

`Entries`, `Date`, `Items`, `Clans`, `RECENTLY`

### `ReplicatedStorage.ChickenOrHero.Presentation.ValleyHudView` (ModuleScript)

`Colors`, `Gold`, `radius`, `Caption`, `primary`, `stroke`, `StateDot`, `corner`, `skinTile`, `shade`, `panel`, `TopRule`, `color`, `Rule`, `neutral`, `Eyebrow`, `close`, `skinPanel`, `danger`, `toggle`, `Away`, `Mint`, `awayLook`, `MusicOff`, `Music`, `musicIcon`, `Rows`, `scroll`, `secondary`, `EmoteVolume`, `green`, `MusicSlider`, `EmoteSlider`, `Knob`, `outline`, `knobRing`, `skinSettings`, `textStroke`, `skinTimer`, `Wallet`, `Coins`, `Gems`, `coins`, `amount`, `Value`, `Servers`, `Updates`, `Spectate`, `AFKToggle`, `AFK`, `DrawerClip`, `Panel`, `Navigation`, `Order`, `CursorHint`, `MenuToggle`, `Arrow`, `Settings`, `Shade`, `SettingsShade`, `UpdatesShade`, `Entries`, `afkMark`, `Corner`, `fromOffset`, `Labels`, `fromScale`, `fullscreenShade`, `Modal`, `EmoteLabel`, `ensureEmoteSlider`, `EmoteShiftedY`, `shiftForEmote`, `floor`, `track`, `ChatNotifications`, `ChatNotificationsLabel`, `EmoteSounds`, `EmoteSoundsLabel`, `OFF`, `DisableBots`, `DisableBotsLabel`, `BotsNote`, `ShowHitboxes`, `ShowHitboxesLabel`, `PrivateInvites`, `PrivateInvitesLabel`, `HostButton`, `HostButtonLabel`, `BoardRank`, `BoardRankLabel`, `RollingDodge`, `RollingDodgeLabel`, `IceSkates`, `IceSkatesLabel`, `SnowFlurryLabel`, `SnowFlurry`, `ScrollBarThickness`, `ScrollingDirection`, `AutomaticCanvasSize`, `Selectable`, `ClipsDescendants`, `MENU`, `NumberValue`, `DrawerReveal`, `ensureDrawer`, `DrawerWidth`, `DrawerTop`, `DrawerCenter`, `positionDrawer`, `ValleyHUD`, `ScreenInsets`, `ZIndexBehavior`, `DeviceSafeInsets`, `Sibling`, `textSecondary`, `UITextSizeConstraint`, `TextLimits`, `MinTextSize`, `upper`

### `ReplicatedStorage.ChickenOrHero.Presentation.ValleyPanels` (ModuleScript)

`fullscreenShade`, `adopt`, `Corner`, `corner`, `Outline`, `stroke`, `fromOffset`, `fromRGB`, `LayerCollector`, `IsDescendantOf`, `shown`, `request`, `release`, `update`, `watch`, `AncestryChanged`, `cursorWhileVisible`, `whole`, `ZIndexBehavior`, `Sibling`, `screen`, `layout`, `Shade`, `fromScale`, `Gold`, `Modal`, `panel`, `FullscreenBackdrop`, `AuthoredScreens`, `Interface`, `Cursor`, `Blue`, `Purple`

### `ReplicatedStorage.ChickenOrHero.Presentation.ValleyTheme` (ModuleScript)

`Corner`, `surface`, `InventoryInk`, `Gold`, `Mint`, `Gem`, `Blue`, `Purple`, `fromRGB`

### `ReplicatedStorage.ChickenOrHero.Presentation.ValleyToast` (ModuleScript)

`ValleyToast`, `ZIndexBehavior`, `Sibling`, `Message`, `fromOffset`, `UISizeConstraint`, `MaxSize`, `PaddingLeft`, `PaddingRight`, `PaddingTop`, `PaddingBottom`, `Gold`, `build`, `workspace`, `ViewportSize`, `GetService`, `ChickenOrHero`, `OldUIReskin`, `Skin`, `Theme`

### `ReplicatedStorage.ChickenOrHero.Presentation.VerifiedName` (ModuleScript)

`number`, `GetPlayerByUserId`, `Game`, `OutbreakConfig`, `Player`, `OutbreakInfected`, `IsBot`, `function`, `EquippedKnife`, `Knife`, `workspace`, `infected`, `escape`, `format`, `LookDisplayName`, `LookVerified`, `DisplayName`, `HasVerifiedBadge`, `player`, `GetService`

### `ReplicatedStorage.ChickenOrHero.Presentation.WarHornFocus` (ModuleScript)

`WarHorn`, `Sounds`, `Horn`, `HornSpeed`, `RollOffMaxDistance`, `sound`, `PartType`, `Cylinder`, `Shape`, `Metal`, `SmoothPlastic`, `Massless`, `CastShadow`, `Part0`, `Part1`, `piece`, `lookAt`, `Angles`, `along`, `Head`, `Neck`, `fromAxisAngle`, `WarHornProp`, `hornProp`, `workspace`, `ViewportSize`, `isPhone`, `WarHornEdges`, `fromScale`, `edges`, `lower`, `alive`, `catcher`, `target`, `focus`, `raise`, `HornSeconds`, `hunted`, `current`, `focusIn`, `huntedGui`, `start`, `OutlineColor`, `FillTransparency`, `fovCamera`, `preFov`, `setFov`, `releasing`, `clock`, `clamp`, `FocusDistance`, `Highlight`, `WarHornFocus`, `HighlightDepthMode`, `AlwaysOnTop`, `DepthMode`, `FillColor`, `OutlineTransparency`, `highlight`, `ColorCorrectionEffect`, `Brightness`, `Contrast`, `Saturation`, `DepthOfFieldEffect`, `FarIntensity`, `NearIntensity`, `InFocusRadius`, `grade`, `edgeGui`, `edgeFrames`, `WarHornFocusUndo`, `Input`, `Value`, `bound`, `loweredAt`, `raisedAt`, `Transform`, `EquippedDagger`, `saved`, `LocalTransparencyModifier`, `Light`, `Torso`, `shoulder`, `PreSimulation`, `posing`, `Knife`, `knifeBind`, `lowered`, `UnbindFromRenderStep`, `NumberValue`, `release`, `GetService`, `Gear`, `GearCatalog`, `Items`, `__index`, `fromRGB`

### `ReplicatedStorage.ChickenOrHero.Presentation.WarbannerBlaze` (ModuleScript)

`RollOffMaxDistance`, `AddItem`, `sound`, `NumberSequenceKeypoint`, `WarbannerCleaver`, `lower`, `knifeFire`, `LightEmission`, `Rate`, `emitter`, `Flame`, `Lifetime`, `Speed`, `SpreadAngle`, `Acceleration`, `RotSpeed`, `ZOffset`, `ColorSequenceKeypoint`, `fromRGB`, `flame`, `WarbannerBlaze`, `Torso`, `UpperTorso`, `Embers`, `Drag`, `Smoke`, `Emit`, `burst`, `Face`, `SurfaceGuiSizingMode`, `PixelsPerStud`, `SizingMode`, `LightInfluence`, `Ring`, `fromScale`, `SizeConstraint`, `RelativeXX`, `Photo`, `upper`, `photo`, `stroke`, `Shape`, `CastShadow`, `GetUserThumbnailAsync`, `ThumbnailType`, `HeadShot`, `ThumbnailSize`, `Size180x180`, `PartType`, `Cylinder`, `Angles`, `Wood`, `Pole`, `Ball`, `Metal`, `Tip`, `Bar`, `Block`, `Fabric`, `Cloth`, `NormalId`, `userId`, `number`, `Edge`, `WorldPivot`, `banner`, `FillColor`, `FillTransparency`, `random`, `OutlineColor`, `OutlineTransparency`, `Brightness`, `workspace`, `Value`, `WarbannerImpact`, `WorldPosition`, `Terrain`, `Dust`, `EmissionDirection`, `Sparks`, `NumberValue`, `clock`, `cancel`, `Puff`, `Ash`, `ImageTransparency`, `WarbannerCore`, `Ignition`, `PointLight`, `WarbannerLight`, `Range`, `Shadows`, `Highlight`, `WarbannerChar`, `HighlightDepthMode`, `Occluded`, `DepthMode`, `catcher`, `RaycastParams`, `RaycastFilterType`, `Exclude`, `FilterType`, `FilterDescendantsInstances`, `IgnoreWater`, `atan2`, `CFrameValue`, `GetService`, `Debris`, `ChickenOrHero`, `Weapons`, `Whoosh`, `Ignite`, `Crackle`, `Sizzle`, `Slam`, `Head`, `LowerTorso`

### `ReplicatedStorage.ChickenOrHero.Progression.JourneyConfig` (ModuleScript)

`EndsAt`, `number`, `floor`, `format`, `endsIn`, `clone`, `SkinId`, `skins`, `KnifeIcon`, `EmoteId`, `emotes`, `Badge`, `badges`, `Owned`, `effective`, `Rewards`, `Key`, `reward`, `JourneySeasons`, `Seasons`, `ActiveSeason`, `SeasonId`, `SeasonNumber`, `SeasonName`, `TrackId`, `PremiumPassId`, `MaxTier`, `MaxLevel`, `FirstTierXP`, `TierStepXP`, `PurchasesEnabledUniverses`, `RebirthProductId`, `RebirthCoins`, `Badges`, `Number`, `fromRGB`, `FirstSteps`, `QuickFeet`, `III`, `CornerArtist`, `UNTOUCHABLE`, `Untouchable`, `ValleyVeteran`, `ValleyElite`, `NightRunner`, `CrownChaser`, `ValleyRoyalty`, `FIRST`, `First`, `Hidden`, `Outbreak2026`, `PatientZero`, `PlagueBearer`, `Halloween2026`, `HeadlessHorseman`, `CandyCollector`, `Boo`, `COBWEB`, `Cobweb`, `BatOutOfHell`, `MonsterMash`, `GraveRobber`, `HEXED`, `Hexed`, `VampireLord`, `PumpkinKing`, `TheUndying`, `KEYHOLDER`, `Keyholder`, `FallenSubject`, `CrownedInBone`, `KINGSLAYER`, `Kingslayer`, `FvF2026`, `TeamFootball`, `TeamFutbol`, `FootballMvp`, `FutbolMvp`, `FootballChampion`, `FutbolChampion`, `FootballLegend`, `FutbolLegend`, `FootballGoat`, `FutbolGoat`, `FootballElite`, `FutbolElite`, `FootballAllStar`, `FutbolAllStar`, `FootballTeam1`, `FootballTeam3`, `FootballTeam5`, `KICKOFF`, `FutbolTeam1`, `GOLAZO`, `FutbolTeam3`, `FutbolTeam5`, `ROOKIE`, `Rookie`, `MVP`, `VARSITY`, `Varsity`, `HallOfFamer`, `AbilityMaster`, `Preseason`, `ClanChampionsW1`, `ClanChampionsW2`, `ClanChampionsW3`, `ClanChampionsW4`, `ClanChampionsW5`, `ClanChampionsW6`, `ClanChampionsW7`, `ClanChampionsW8`, `VETERAN`, `LevelVeteran`, `ELITE`, `LevelElite`, `CENTURION`, `Centurion`, `STORMCALLER`, `Stormcaller`

### `ReplicatedStorage.ChickenOrHero.Progression.JourneyMath` (ModuleScript)

`MaxTier`, `FirstTierXP`, `TierStepXP`, `totalForTier`, `floor`, `earned`, `needed`, `ratio`, `complete`, `clamp`

### `ReplicatedStorage.ChickenOrHero.Progression.JourneySeason1Rewards` (ModuleScript)

`FirstSteps`, `QuickFeet`, `CornerArtist`, `Untouchable`, `ValleyVeteran`, `ValleyElite`, `NightRunner`, `CrownChaser`, `ValleyRoyalty`, `Free`, `Premium`, `Key`, `Gems`, `Badge`, `free_`, `Coins`, `premium_`, `SnappySkipping`, `AnimePose`, `IdleDance`, `WavyGrooves`, `Jumpstyle`, `SkeletonGrooves`, `WibblyWobbly`, `LoseIt`, `Skeleton`, `BTSDance`, `Flexer`, `Moongazer`, `ElectroShuffle`, `CatDance`, `EmoteId`, `VipersFang`, `SkinId`, `Bloodthorn`, `KnifeIcon`, `Voidspine`, `IceCreamDagger`, `Spins`

### `ReplicatedStorage.ChickenOrHero.Progression.JourneySeason2Rewards` (ModuleScript)

`Coins`, `SkinId`, `SpiderFang`, `CandyCorn`, `Badge`, `TrickOrTreater`, `Keys`, `CornCollector`, `BoneShiv`, `NightStalker`, `Spooky`, `GhoulBlade`, `GhostHunter`, `GraveyardShift`, `FemurShiv`, `WitchingHour`, `CandySnatcher`, `PumpkinPatchBlade`, `Haunted`, `BoneCollector`, `Cursed`, `Nightmare`, `Headless`, `SoulReaper`, `PumpkinHunter`, `ReaperScythe`, `clone`, `s2_free_`, `Key`, `s2_premium_`, `Free`, `Premium`

### `ReplicatedStorage.ChickenOrHero.Progression.JourneySeason3Rewards` (ModuleScript)

`Coins`, `SkinId`, `JavelinSpike`, `Tokens`, `ShuttleShiv`, `Keys`, `KeyCrate`, `GymEmote`, `Badge`, `Rookie`, `EmoteId`, `KneeSlide`, `Gems`, `LockerKey`, `HockeyEdge`, `MVP`, `GoldthornSaber`, `Spins`, `Varsity`, `Premium2`, `Dodgeball`, `HallOfFamer`, `TrophyBlade`, `TrophyLift`, `clone`, `s3_free_`, `Soon`, `_soon`, `Key`, `s3_premium_`, `Free`, `Premium`

### `ReplicatedStorage.ChickenOrHero.Progression.JourneySeasons` (ModuleScript)

`ActiveSeason`, `season_1`, `Seasons`, `season_2`, `season_3`, `Number`, `TrackId`, `valley_journey_1`, `PremiumPassId`, `RewardsModule`, `JourneySeason1Rewards`, `MaxTier`, `FirstTierXP`, `TierStepXP`, `EndsAt`, `valley_journey_2`, `JourneySeason2Rewards`, `valley_journey_3`, `JourneySeason3Rewards`, `PlaceId`, `GetService`, `IsStudio`, `number`

### `ReplicatedStorage.ChickenOrHero.Progression.LevelRewards` (ModuleScript)

`floor`, `MaxLevel`, `level`, `coins`, `tokens`, `Extras`, `PremiumCrate`, `BasicCrate`, `crate`, `Cosmetics`, `cosmetic`, `Unlocks`, `unlock`, `freeze`, `Coins`, `Gems`, `Tokens`, `Crate`, `Cosmetic`, `title`, `given`, `reverse`, `comma`, `Icons`, `KIND_NAMES`, `concat`, `summary`, `summaryRange`, `Basic2`, `Premium2`, `Rookie`, `SprintSparks`, `Emote`, `Salute`, `KillEffect`, `ConfettiPop`, `VictorySpin`, `LevelVeteran`, `Veteran`, `CometTail`, `TauntWave`, `Shatter`, `LevelElite`, `Elite`, `EmberSteps`, `Knife`, `CenturionBlade`, `Centurion`, `KnifeFlip`, `LightningStrike`, `Stormcaller`, `AuroraSteps`, `ThroneSit`, `Ascendant`, `BlackHole`, `GalaxyDust`, `LegendPose`, `Mythic`, `Supernova`, `Paragon`, `GoldNameGlow`

### `ReplicatedStorage.ChickenOrHero.Progression.ProgressionConfig` (ModuleScript)

`freeze`, `CrossingBaseXP`, `CrossingPressureXP`, `CatchXP`, `WinXP`, `FirstLevelXP`, `LevelStepXP`

### `ReplicatedStorage.ChickenOrHero.Progression.ProgressionMath` (ModuleScript)

`CrossingBaseXP`, `CrossingPressureXP`, `round`, `crossing`, `floor`, `FirstLevelXP`, `LevelStepXP`, `totalForLevel`, `number`, `clamp`, `total`, `level`, `earned`, `needed`, `ratio`, `ProgressionConfig`

### `ReplicatedStorage.ChickenOrHero.Progression.TeamEventConfig` (ModuleScript)

`Football`, `Futbol`, `other`, `Teams`, `flagship`, `StartsAt`, `EndsAt`, `window`, `Final`, `Upcoming`, `Settling`, `phaseAt`, `BoostMinActive`, `BoostCap`, `floor`, `boost`, `TeamLevels`, `levelFor`, `gmatch`, `parseThresholds`, `Knives`, `clone`, `Crates`, `OppositeCrate`, `Crate`, `OwnedKnifeCrates`, `shown`, `Team`, `resolve`, `Rewards`, `reward`, `Champion`, `championReward`, `number`, `LegendRank`, `Legend`, `Placement`, `Rank`, `Gems`, `Titles`, `placementReward`, `Weapons`, `ShopConfig`, `FvF2026`, `EventId`, `FOOTBALL`, `TeamFootball`, `Mvp`, `FootballMvp`, `FootballChampion`, `FootballLegend`, `Goat`, `FootballGoat`, `Elite`, `FootballElite`, `AllStar`, `FootballAllStar`, `Emote`, `FootballCatch`, `Board`, `HV_FvF2026_Football_v1`, `BoardKey`, `PersonalKnife`, `SolarPhoenix`, `TeamKnife`, `VoidSovereign`, `EventKnife`, `Hotdog`, `TeamTitle1`, `FootballTeam1`, `TeamTitle3`, `FootballTeam3`, `TeamTitle5`, `FootballTeam5`, `fromRGB`, `SOCCER`, `TeamFutbol`, `FutbolMvp`, `FutbolChampion`, `FutbolLegend`, `FutbolGoat`, `FutbolElite`, `FutbolAllStar`, `FutbolCatch`, `HV_FvF2026_Futbol_v1`, `GlacialCrown`, `CelestialDragon`, `NumberOneFan`, `FutbolTeam1`, `FutbolTeam3`, `FutbolTeam5`, `SettleSeconds`, `UpdateSeconds`, `PersonalLevels`, `Participation`, `ActiveMinPoints`, `ChampionMinPoints`, `MatchCap`, `BotMatchCap`, `Note`, `Personal`, `GemBoostMinutes`, `Spins`, `Coins`, `Celestial`, `Abilities`, `RufusLeash`, `CoinBoostMinutes`, `PocketDoor`, `Emotes`, `InflatableDecoy`, `Ember`, `CrateGems`

### `ReplicatedStorage.ChickenOrHero.Trolls.Client.EmoteParty` (ModuleScript)

`EmoteId`, `EmoteAt`, `number`, `dance`, `EmoteForced`, `party`, `Length`, `loopTime`, `start`, `IsPlaying`, `dispose`, `track`, `stopOwn`, `breakOut`, `UserInputState`, `ContextActionResult`, `Pass`, `CoHTrollDanceJump`, `ContextActionPriority`, `High`, `Value`, `Space`, `ButtonA`, `BindActionAtPriority`, `UnbindAction`, `Animator`, `exempt`, `humanoid`, `EmoteStartedAt`, `since`, `clock`, `Stop`, `FireServer`, `workspace`, `updateOwn`, `ClientBots`, `ownerClone`, `animator`, `updateBots`, `soundId`, `sound`, `TrollPartyMusic`, `TimeLength`, `updateMusic`, `package`, `Emotes`, `EmotePlayback`, `EmoteCatalog`, `EmoteEvent`, `Shared`, `player`, `TrollDance`, `JumpOut`, `fromOffset`, `fromRGB`, `JumpRequest`, `GetService`

### `ReplicatedStorage.ChickenOrHero.Trolls.Client.FloorIsLava` (ModuleScript)

`emitter`, `CastShadow`, `ghost`, `SmoothPlastic`, `Puff`, `Lifetime`, `Speed`, `SpreadAngle`, `Rate`, `LightEmission`, `NumberSequenceKeypoint`, `Emit`, `TrollLavaShake`, `UnbindFromRenderStep`, `teardown`, `pillars`, `Delay`, `FloorY`, `floorY`, `final`, `height`, `offset`, `puffed`, `number`, `lastDelay`, `settled`, `addPillar`, `AreaCFrame`, `AreaSize`, `frame`, `areaFrame`, `fromRGB`, `Neon`, `LavaGlow`, `SpillCFrame`, `SpillWidth`, `WedgePart`, `LavaSpill`, `MaterialVariant`, `spill`, `spillFrame`, `LavaSurface`, `surface`, `clamp`, `Acceleration`, `EmissionDirection`, `NormalId`, `PointLight`, `Range`, `Brightness`, `areas`, `addArea`, `folder`, `Pillars`, `Areas`, `sounds`, `setup`, `LavaFrom`, `LavaTo`, `LavaStart`, `LavaEnd`, `DrainAt`, `Drain`, `DrainFraction`, `lavaTop`, `workspace`, `StartAt`, `PillarRise`, `Angles`, `shake`, `sound`, `exempt`, `Value`, `GetService`, `LavaBurning`, `ClientBots`, `bodies`, `RollOffMaxDistance`, `Ended`, `player`, `Focus`, `Highlight`, `LavaBurn`, `FillColor`, `OutlineColor`, `HighlightDepthMode`, `Occluded`, `DepthMode`, `Adornee`, `FillTransparency`, `OutlineTransparency`, `clock`, `burning`, `TrollLava`, `TrollLavaLocal`, `TrollLavaFlash`, `fromScale`, `__mode`, `Burn`, `start`

### `ReplicatedStorage.ChickenOrHero.Trolls.Client.Jump` (ModuleScript)

`TrollJump`, `exempt`, `MovementLocked`, `Ragdolled`, `TackleActive`, `movementReason`, `UserInputState`, `FloorMaterial`, `Air`, `HumanoidStateType`, `Jumping`, `ChangeState`, `ContextActionResult`, `Pass`, `press`, `CoHTrollJump`, `ContextActionPriority`, `High`, `Value`, `Space`, `BindActionAtPriority`, `UnbindAction`, `UseJumpPower`, `Shared`, `GetStateEnabled`, `SetStateEnabled`, `JumpEnabled`, `package`, `Movement`, `ControlGate`, `MovementConfig`, `player`, `__mode`, `start`, `GetService`

### `ReplicatedStorage.ChickenOrHero.Trolls.Client.LootRain` (ModuleScript)

`Neon`, `fromRGB`, `random`, `PartType`, `Cylinder`, `Shape`, `Metal`, `Reflectance`, `SmoothPlastic`, `Ball`, `weight`, `workspace`, `Focus`, `centre`, `FilterDescendantsInstances`, `CastShadow`, `position`, `floor`, `speed`, `Angles`, `spawnDrop`, `sound`, `LootRainUntil`, `number`, `Sparkles`, `LightEmission`, `NumberSequenceKeypoint`, `Lifetime`, `Speed`, `Rate`, `NormalId`, `EmissionDirection`, `remove`, `BulkMoveMode`, `FireCFrameChanged`, `BulkMoveTo`, `TrollLootRain`, `RaycastParams`, `RaycastFilterType`, `Exclude`, `FilterType`, `RespectCanCollide`, `IgnoreWater`, `start`, `GetService`

### `ReplicatedStorage.ChickenOrHero.Trolls.Client.LowGravity` (ModuleScript)

`Gravity`, `exempt`, `number`, `NormalGravity`, `target`, `workspace`, `apply`, `player`, `TrollExempt`, `start`

### `ReplicatedStorage.ChickenOrHero.Trolls.Client.Notify` (ModuleScript)

`Toast`, `Debug`, `start`

### `ReplicatedStorage.ChickenOrHero.Trolls.Client.Spotlight` (ModuleScript)

`fromScale`, `FredokaOne`, `fromRGB`, `label`, `Head`, `SpotlightBoard`, `Adornee`, `StudsOffsetWorldSpace`, `MaxDistance`, `LightInfluence`, `PlayerName`, `Username`, `board`, `Torso`, `PointLight`, `Range`, `Brightness`, `BeamTop`, `BeamFoot`, `Attachment0`, `Attachment1`, `LightEmission`, `Width0`, `Width1`, `FaceCamera`, `Segments`, `Sparkles`, `Lifetime`, `Rate`, `Speed`, `SpreadAngle`, `lights`, `GetScale`, `place`, `track`, `dispose`, `model`, `SpotlightUserId`, `SpotlightName`, `SpotlightUsername`, `SpotlightCFrame`, `number`, `SpotlightLook`, `HumanoidDescription`, `GetHumanoidDescriptionFromUserIdAsync`, `CreateHumanoidModelFromDescriptionAsync`, `HumanoidRigType`, `ForceField`, `Tool`, `HumanoidDisplayDistanceType`, `DisplayDistanceType`, `HumanoidHealthDisplayType`, `AlwaysOff`, `HealthDisplayType`, `BreakJointsOnDeath`, `HumanoidStateType`, `Dead`, `SetStateEnabled`, `Animator`, `TrollSpotlight`, `ScaleTo`, `cframe`, `build`, `pending`, `clock`, `SpotlightAt`, `SpotlightDance`, `dance`, `IsPlaying`, `Length`, `loopTime`, `package`, `Emotes`, `EmotePlayback`, `Shared`, `TrollSpotlightLocal`, `workspace`, `start`, `GetService`

### `ReplicatedStorage.ChickenOrHero.Trolls.Client.SwapPlaces` (ModuleScript)

`workspace`, `fromRGB`, `NumberSequenceKeypoint`, `Lifetime`, `Speed`, `SpreadAngle`, `Rate`, `LightEmission`, `Emit`, `sound`, `Poof`, `start`

### `ReplicatedStorage.ChickenOrHero.Trolls.TrollShared` (ModuleScript)

`DanceOrder`, `Prop`, `Knife`, `Kind`, `Ultimate`, `Test`, `assetId`, `freeze`, `dances`, `dance`, `DebugAffectsOwners`, `GetService`, `IsStudio`, `PlaceId`, `debug`, `TrollExempt`, `exempt`, `CloneOwnerUserId`, `number`, `GetPlayerByUserId`, `ownerClone`, `workspace`, `loopTime`, `Emotes`, `EmoteCatalog`, `StateName`, `TrollEvent`, `RemoteName`, `EDanceSupreme`, `Floss`, `SixtySeven`, `DaBabyDance`, `RatDance`, `YaYaYing`, `CaliforniaGirls`, `Marat`, `Jumpstyle`, `ElectroShuffle`, `BTSDance`, `CatDance`, `SkeletonGrooves`, `Caffeinated`, `FastDancer`, `BoogieDown`, `Dougie`, `LoseIt`, `WibblyWobbly`, `Skeleton`, `WavyGrooves`, `Marisa`, `IdleDance`

### `ReplicatedStorage.ChickenOrHero.Weapons.BundlePanel` (ModuleScript)

`productId`, `productNow`, `floor`, `reverse`, `comma`, `GameAudio`, `GetService`, `LazySound`, `playLocal`, `sound`, `round`, `border`, `ExtraBold`, `StrokeSizingMode`, `ScaledSize`, `fromScale`, `PreviewRotation`, `Light`, `FindFirstAncestorOfClass`, `cross`, `PreviewZoom`, `clamp`, `camera`, `extent`, `height`, `angle`, `turntable`, `lookAt`, `IsForSale`, `PriceInRobux`, `number`, `offer`, `workspace`, `buyText`, `Interactable`, `buyFill`, `fromRGB`, `countdown`, `timer`, `giftable`, `Key`, `giftShown`, `InMatch`, `giftLive`, `giftFill`, `paint`, `GetProductInfoAsync`, `fetchPrice`, `GetTextBoundsParams`, `Width`, `GetTextBoundsAsync`, `evenSizes`, `PanelClose`, `AbilityInfo`, `Card`, `AspectRatio`, `Heavy`, `KnifeAbility`, `Role`, `Bold`, `Duration`, `ACTIVE`, `COOLDOWN`, `Cooldown`, `SealSeconds`, `HOLD`, `format`, `Chip`, `ToHex`, `HowTo`, `Description`, `InfoNote`, `Step`, `DominantAxis`, `Height`, `Line`, `Note`, `SemiBold`, `abilityCard`, `views`, `poses`, `destroy`, `floaters`, `teardown`, `Big`, `Amount`, `Caption`, `Badge`, `extra`, `destroyed`, `clone`, `dressed`, `close`, `KnifePreview`, `SkinId`, `Fire`, `AbilityIcon`, `IconImage`, `PanelOpen`, `Click`, `GiftOpen`, `buying`, `BundleSource`, `FireServer`, `PromptProductPurchase`, `clock`, `speed`, `image`, `phase`, `ImageTransparency`, `ZIndexBehavior`, `Sibling`, `Panel`, `MaxSize`, `MinSize`, `UISizeConstraint`, `TimerPill`, `Timer`, `Modal`, `Knife`

### `ReplicatedStorage.ChickenOrHero.Weapons.Bundles` (ModuleScript)

`StartsAt`, `EndsAt`, `onSale`, `ShopOrder`, `List`, `workspace`, `Pair`, `ShopCard`, `shopList`, `isOnSale`, `Key`, `single`, `Next`, `shown`, `GameId`, `TestUniverseId`, `DiscountProductId`, `TestDiscountProductId`, `purchased`, `TestProductId`, `ProductId`, `productId`, `byProduct`, `Flag`, `owned`, `SkinId`, `Ability`, `abilities`, `freeze`, `BonkerBundle`, `UniverseId`, `Bonker`, `Gems`, `Item`, `BananaPeel`, `ItemCount`, `bonkerBundlePurchased`, `Contents`, `Blurb`, `StandLine`, `Backdrop`, `Details`, `Reason`, `bonker_bundle`, `fromRGB`, `DateTime`, `fromUniversalTime`, `UnixTimestamp`, `VowbreakerBundle`, `Vowbreaker`, `Emote`, `KarambitSpin`, `BrokenVow`, `vowbreakerBundlePurchased`, `Floaters`, `vowbreaker_bundle`, `PumpkinCleaverBundle`, `PumpkinCleaver`, `TimeWarp`, `pumpkinCleaverBundlePurchased`, `pumpkin_cleaver_bundle`, `HexflaskBundle`, `SoulbinderBundle`, `Soulbinder`, `SoulReap`, `Candy`, `SoulCall`, `soulbinderBundlePurchased`, `soulbinder_bundle`, `SoulbinderBlade`, `soulbinderBladePurchased`, `soulbinder_blade`, `ClownKillerBundle`, `GrinnerBlades`, `SpringBox`, `ClownJuggle`, `clownKillerBundlePurchased`, `clown_killer_bundle`, `Showcase`, `Effects`, `EffectsShort`, `Line`, `BladeLine`, `Note`, `KillEffect`, `BalloonLift`, `GrinnerBlade`, `grinnerBladePurchased`, `grinner_blade`, `Hexflask`, `FartCloud`, `hexflaskBundlePurchased`, `hexflask_bundle`, `HallowreaperBundle`, `Hallowreapers`, `PumpkinBomb`, `Keys`, `hallowreaperBundlePurchased`, `hallowreaper_bundle`, `SpectralCutlassBundle`, `DrownedCutlass`, `PiratesCall`, `spectralCutlassBundlePurchased`, `spectral_cutlass_bundle`, `WarHornBundle`, `WarbannerCleaver`, `WarHorn`, `Coins`, `warHornBundlePurchased`, `war_horn_bundle`, `VolleyballBundle`, `BasketballBundle`, `Basketball`, `AlleyOop`, `BasketballTricks`, `basketballBundlePurchased`, `basketball_bundle`, `IceSkateBundle`, `Volleyball`, `KnifeAbility`

### `ReplicatedStorage.ChickenOrHero.Weapons.CloneAbilityConfig` (ModuleScript)

`freeze`, `Skin`, `CloneDagger`, `Count`, `Duration`, `Cooldown`, `ServerCloneLimit`, `ThinkLevel`, `SplitDuration`, `SwapDistance`, `RunnerRoute`, `ChangeMin`, `ChangeMax`, `SideStrength`, `TurnResponse`, `LookAhead`, `FinishFocusDistance`, `ObstacleInterval`, `JukeChance`, `JukeMin`, `JukeMax`

### `ReplicatedStorage.ChickenOrHero.Weapons.CloneEchoMotion` (ModuleScript)

`CloneEchoVersion`, `orbits`, `echoes`, `phase`, `SurgeOrbit`, `Start`, `End`, `Core`, `Glow`, `radius`, `direction`, `points`, `beams`, `BladeEcho`, `Point`, `attachment`, `EchoRestPosition`, `Edge`, `build`, `fromMatrix`, `WorldToViewportPoint`, `Angles`, `scale`, `CurveSize0`, `CurveSize1`, `floor`, `clamp`, `NumberSequenceKeypoint`, `freeze`

### `ReplicatedStorage.ChickenOrHero.Weapons.CloneSplitEffects` (ModuleScript)

`workspace`, `CloneSplitBurst`, `CastShadow`, `SharedSplitMist`, `Rate`, `Lifetime`, `Speed`, `SpreadAngle`, `RotSpeed`, `Drag`, `LightEmission`, `LightInfluence`, `fromRGB`, `NumberSequenceKeypoint`, `Emit`, `AddItem`, `CloneSplitFlash`, `PartType`, `Ball`, `Shape`, `Neon`, `GetService`, `Debris`

### `ReplicatedStorage.ChickenOrHero.Weapons.CombineConfig` (ModuleScript)

`family`, `tierOf`, `Fusion`, `Output`, `isFusion`, `Families`, `Names`, `nameOf`, `Tiers`, `Costs`, `recipe`, `EndsAt`, `number`, `running`, `GameId`, `PlaceId`, `DevPlace`, `EventName`, `Kitsune`, `Kusarigama`, `Wheel`, `ImmortalKitsune`, `DualImmortalKitsune`, `VoidKusarigama`, `DualVoidKusarigamas`, `Order`, `UltimateVoidBlades`, `Inputs`, `Limit`, `Moonfang`, `SolarPhoenix`, `StormTalon`, `VoidSovereign`, `StandIns`, `StandInTints`, `Animations`, `EclipseFang`, `JackInTheBox`, `DualWield`, `LeftBlades`, `UltimateEmotes`, `MergeEventId`, `BASE`, `UPGRADED`, `DUAL`, `ULTIMATE`, `TierNames`, `fromRGB`, `TierColors`, `DebugNotice`, `UltimateLine`, `Charge`, `Tracks`, `Burst`, `Fanfare`, `Sounds`

### `ReplicatedStorage.ChickenOrHero.Weapons.ComedySkinCatalog` (ModuleScript)

`Order`, `Skins`, `CluckBasher`, `BananaBlade`, `PizzaPunisher`, `Bonker`, `Football`, `Futbol`, `iSlice`, `Description`, `SoundProfile`, `Collection`, `Available`, `EquipReady`, `fromRGB`, `BONKER`, `HitEffect`, `Splat`, `FOOTBALL`, `Show`, `GameDay`, `SportsBall`, `HitSoundProfile`, `BaseDagger`, `FUTBOL`, `MatchDay`, `freeze`

### `ReplicatedStorage.ChickenOrHero.Weapons.CurrencyTopUp` (ModuleScript)

`lower`, `coins`, `currencyOf`, `shortfall`, `PurchasesEnabled`, `Packs`, `ProductIds`, `Key`, `Currency`, `number`, `Amount`, `clock`, `GiftOpen`, `PromptProductPurchase`, `GetService`, `ShopConfig`, `binding`, `GameId`

### `ReplicatedStorage.ChickenOrHero.Weapons.DaggerConfig` (ModuleScript)

`Game`, `ContactCatchConfig`, `freeze`, `DefaultSkin`, `BaseDagger`, `GripInwardStuds`, `DrawDuration`, `DrawTransfer`, `StabDelay`, `StabDuration`, `StabContactStart`, `StabContactEnd`, `FadeIn`, `FadeOut`, `WindupRate`, `WindupHoldTail`, `DiveDuration`, `DiveFadeOut`, `AimLimit`, `AimRate`, `Windup`

### `ReplicatedStorage.ChickenOrHero.Weapons.DaggerGrip` (ModuleScript)

`GripC0`, `identity`, `GripInwardStuds`, `number`, `clamp`, `DaggerConfig`, `freeze`

### `ReplicatedStorage.ChickenOrHero.Weapons.DailyEmoteOffers` (ModuleScript)

`floor`, `reverse`, `comma`, `fromOffset`, `ProductId`, `number`, `ProductUniverse`, `robuxOffer`, `DailyDay`, `todays`, `secondsLeft`, `format`, `countdown`, `UITextSizeConstraint`, `TextLimit`, `Padding`, `PaddingLeft`, `PaddingRight`, `secondary`, `giftLook`, `setEnabled`, `setButton`, `connect`, `shown`, `ComingSoon`, `comingSoon`, `currency`, `coins`, `amount`, `remote`, `BuyEmote`, `FireServer`, `entry`, `robux`, `sharedProduct`, `DailyTarget`, `PromptProductPurchase`, `Daily`, `assign`, `layoutWidth`, `layoutPortrait`, `layout`, `refresh`, `DailyEmotes`, `frame`, `items`, `untilTick`, `ArmoryEvent`, `heading`, `Timer`, `Gold`, `timer`, `Description`, `description`, `textStroke`, `Cards`, `cardsFrame`, `Slots`, `surface`, `rarity`, `viewport`, `Rarity`, `Preview`, `fromRGB`, `NameLabel`, `Buy`, `Robux`, `soundButton`, `sound`, `attach`, `AttributeChanged`, `priceInfo`, `priceText`, `price`, `RARITY`, `Purple`, `upper`, `amountText`, `preview`, `destroy`, `productPrice`, `IsForSale`, `PriceInRobux`, `robuxText`, `emotes`, `loaded`, `pending`, `SOON`, `OWNED`, `setShown`, `EquippedKnife`, `model`, `source`, `knife`, `clock`, `retryAt`, `GetService`, `ChickenOrHero`, `OldUIReskin`, `Skin`, `Theme`, `Presentation`, `ValleyToast`, `ShopConfig`, `EmoteStoreClient`, `CurrencyTopUp`, `GiftClient`, `Emotes`, `EmoteCatalog`, `Interface`, `CharacterPreview`, `EmoteSound`, `__index`, `storeUniverse`, `GameId`, `Coins`, `DailyCoins`, `Gems`, `DailyGems`, `DailyRobux`

### `ReplicatedStorage.ChickenOrHero.Weapons.DualWield` (ModuleScript)

`GetComponents`, `Angles`, `mirror`, `LeftGrip`, `animated`, `IdleGrip`, `Handle`, `BladeWeld`, `identity`, `GripC1`, `Blade`, `IsDescendantOf`, `inside`, `JointInstance`, `Part0`, `Part1`, `Constraint`, `Attachment0`, `Attachment1`, `Massless`, `lookOnly`, `IsDualWield`, `holds`, `LeftBlade`, `LeftBladeFrom`, `attach`, `StowedBlade`, `StowedOffset`, `LeftStowedBlade`, `LeftStowedDagger`, `LeftStowedOffset`, `stowHealthy`, `healthy`, `DaggerGrip`, `KnifeClips`, `KnifeChains`, `freeze`

### `ReplicatedStorage.ChickenOrHero.Weapons.EmoteStoreClient` (ModuleScript)

`clock`, `comingSoon`, `RARITY`, `rarity`, `Purple`, `accent`, `upper`, `Source`, `Free`, `inCrate`, `Route`, `Premium`, `source`, `SoundButton`, `fromOffset`, `corner`, `stroke`, `ImageColor3`, `fromScale`, `soundButton`, `setEnabled`, `textStroke`, `label`, `Slots`, `slotOf`, `connect`, `equip`, `ComingSoon`, `ArmoryNavigation`, `EmoteCrate`, `Fire`, `canvas`, `Emotes`, `remote`, `slots`, `retryAt`, `ArmoryEvent`, `Overview`, `surface`, `Preview`, `fromRGB`, `viewport`, `sourceLabel`, `nameLabel`, `Line1`, `line1`, `Line2`, `line2`, `sound`, `Slot`, `List`, `ScrollBarThickness`, `ScrollBarImageColor3`, `ScrollingDirection`, `VerticalScrollBarInset`, `ScrollBarInset`, `ScrollBar`, `scroll`, `GetEmotes`, `CRATE`, `Plus`, `NameLabel`, `getCard`, `getStatus`, `EquippedHeading`, `equippedHeading`, `unequip`, `Number`, `border`, `addCard`, `painted`, `layoutList`, `rebuild`, `listWidth`, `floor`, `preview`, `selected`, `model`, `refresh`, `loaded`, `pending`, `EquipEmote`, `FireServer`, `emotes`, `emoteSlots`, `Entries`, `concat`, `signature`, `paint`, `freeCrates`, `Emote`, `format`, `soundId`, `available`, `holds`, `primary`, `destroy`, `setOpen`, `layout`, `knife`, `EquippedKnife`, `GetService`, `ChickenOrHero`, `OldUIReskin`, `Skin`, `Theme`, `Presentation`, `ValleyToast`, `EmoteCatalog`, `Interface`, `CharacterPreview`, `EmoteSound`, `__index`, `Common`, `Rare`, `Epic`, `Legendary`, `InventoryInk`

### `ReplicatedStorage.ChickenOrHero.Weapons.EventKnivesOffer` (ModuleScript)

`floor`, `reverse`, `comma`, `format`, `round`, `clock`, `trouble`, `GameAudio`, `GetService`, `LazySound`, `playLocal`, `sound`, `paint`, `repaintAll`, `OnClientEvent`, `watch`, `unwatch`, `match`, `Description`, `forSkin`, `upper`, `ability`, `bundle`, `Knife`, `emoteOf`, `PassIds`, `number`, `passId`, `EquipReady`, `ready`, `loaded`, `pending`, `InMatch`, `owned`, `ownedShared`, `GetProductInfoAsync`, `GamePass`, `loading`, `price`, `hooks`, `status`, `offer`, `Expired`, `PriceInRobux`, `IsForSale`, `PurchasesEnabled`, `statusShared`, `message`, `messageUntil`, `workspace`, `PromptGamePassPurchase`, `purchaseShared`, `giftable`, `giftState`, `purchase`, `options`, `Audio`, `PresentationCues`, `KnifePreview`, `Fire`, `fromOffset`, `corner`, `ColorSequenceKeypoint`, `UITextSizeConstraint`, `glyph`, `Selectable`, `fromScale`, `label`, `Glow`, `ImageColor3`, `ImageTransparency`, `Field`, `Futbol`, `field`, `Shine`, `Interactable`, `shine`, `sweep`, `Countdown`, `Live`, `Caption`, `Clock`, `caption`, `countdown`, `setCountdown`, `Versus`, `badge`, `pulse`, `versus`, `enabled`, `Click`, `knife`, `width`, `height`, `Buy`, `Gift`, `GiftIcon`, `SizeConstraint`, `RelativeYY`, `ICON`, `buyRow`, `Owned`, `Off`, `giftShown`, `GiftOff`, `giftLook`, `paintRow`, `LayerCollector`, `onScreen`, `details`, `color`, `light`, `Watermark`, `Tag`, `LIMITED`, `Eyebrow`, `isNew`, `New`, `KnifeName`, `Tagline`

### `ReplicatedStorage.ChickenOrHero.Weapons.FantasySkinCatalog` (ModuleScript)

`Order`, `Skins`, `Common`, `Rare`, `Epic`, `Legendary`, `Mythical`, `fromRGB`, `CopperBite`, `Ember`, `Ashsteel`, `AmberSting`, `RoseQuartz`, `MoltenFang`, `SpectralReaper`, `SolarPhoenix`, `VoidSovereign`, `IronFang`, `Celestial`, `ForestEdge`, `TidalShard`, `VenomThorn`, `StormTalon`, `Moonfang`, `GlacialCrown`, `CelestialDragon`, `Voidspine`, `Journey`, `Bloodthorn`, `VipersFang`, `Vowbreaker`, `Limited`, `Source`, `Collection`, `Soulbinder`, `Hide`, `SoulbinderBlade`, `GrinnerBlades`, `GrinnerBlade`, `Hallowreapers`, `DrownedCutlass`, `WarbannerCleaver`, `BronzeFang`, `BaseDagger`, `SilverTwins`, `GoldJavelin`, `PlatinumJavelins`, `DiamondReaper`, `MasterReaper`, `GrandmasterReaper`, `ChampionsReaper`, `Basketball`, `SportsBall`, `Showtime`, `Show`, `Volleyball`, `GamePoint`, `IceSkate`, `HockeyStick`, `HockeyEdge`, `DarkIcicle`, `Dodgeball`, `Description`, `Hexflask`, `AlbiesCutlass`, `Exclusive`, `AlbiesHoverboard`, `iSlice`, `Hotdog`, `NumberOneFan`, `FoamFinger`, `SelfieStick`, `Robux`, `Icicle`, `ReaperScythe`, `Halloween`, `HollowMoon`, `Hexbinder`, `PumpkinSovereign`, `ReapersTithe`, `HallowedEmber`, `PumpkinCleaver`, `PumpkinSpiceShank`, `GhoulBlade`, `FunSizeFang`, `FemurShiv`, `Gravewarden`, `Witchroot`, `SpiderFang`, `PumpkinPatchBlade`, `BoneShiv`, `MummyWrapShiv`, `BedsheetBoo`, `CandyCornCleaver`, `FakeFinger`, `ToffeeAppleStabber`, `JackInTheBox`, `LanternWarden`, `CrowboneDirk`, `EclipseFang`, `PlasticPitchfork`, `ChatteringTeeth`, `PumpkinPieSlicer`, `GhostPepper`, `Wolfsbane`, `BansheesCry`, `GlowstickShank`, `AshenSickle`, `CoffinNail`, `WitchfireAthame`, `SkeletonKey`, `Ghostlock`, `TheLastDoor`, `GraveShard`, `ShrineBreaker`, `FallenAxes`, `FallenAxesBlue`, `Nightrend`, `CelestialLegendary`, `RuneboundSword`

### `ReplicatedStorage.ChickenOrHero.Weapons.GiftClient` (ModuleScript)

`Presentation`, `GiftScreen`, `getScreen`, `canGift`, `Fire`, `Opened`, `Delivered`, `receive`, `FireServer`, `function`, `keyOf`, `offer`, `giftable`, `awaitUIVersion`, `NewGui`, `Interface`, `Toasts`, `ValleyToast`, `GiftOpen`, `UNAVAILABLE`, `GiftIcon`, `fromScale`, `SizeConstraint`, `RelativeYY`, `ICON`, `square`, `Hit`, `Selectable`, `Gift`, `clearCopied`, `visible`, `paint`, `attach`, `fromOffset`, `scaled`, `Padding`, `position`, `anchor`, `place`, `Interactable`, `fromRGB`, `CanvasGroup`, `attachScaled`, `GetService`, `ChickenOrHero`, `Weapons`, `GiftConfig`, `FFlags`, `GiftingEnabled`, `GiftEvent`, `BindableEvent`, `changed`, `__mode`, `OnClientEvent`

### `ReplicatedStorage.ChickenOrHero.Weapons.GiftConfig` (ModuleScript)

`floor`, `reverse`, `comma`, `LiveUniverseId`, `TestUniverseId`, `IsStudio`, `sharedProducts`, `Packs`, `Key`, `packOf`, `binding`, `PurchasesEnabled`, `PassGifts`, `GiftProducts`, `number`, `Bundle`, `productId`, `giftOnly`, `details`, `SkinId`, `Details`, `Passes`, `bonus`, `Kind`, `Skin`, `Perk`, `Bonus`, `TestProductId`, `ProductId`, `Ultimate`, `ProductUniverse`, `Emote`, `emote`, `ProductIds`, `ProductGrants`, `UniverseId`, `Currency`, `Amount`, `Pack`, `currency`, `amount`, `coins`, `offer`, `giftOnlyOffer`, `Knife`, `EquipReady`, `flagship`, `AdditionalKnives`, `OfferKey`, `isOnSale`, `ComingSoon`, `onSale`, `GetService`, `ShopConfig`, `OfferRules`, `Bundles`, `SkinCatalog`, `Emotes`, `EmoteCatalog`, `DailyEmotes`, `Football`, `Futbol`, `Spoon`, `VIP`, `DoubleXP`, `Selfie`, `Ghost`, `BonkerBundle`, `SpoonDagger`, `GhostScythe`, `SelfieStick`, `VIPDagger`, `QueueLimit`, `GameId`

### `ReplicatedStorage.ChickenOrHero.Weapons.KillEffects` (ModuleScript)

`freeze`, `GrinnerBlades`, `PumpkinSovereign`, `AlbiesCutlass`, `DrownedCutlass`, `Soulbinder`, `DarkIcicle`, `fromRGB`

### `ReplicatedStorage.ChickenOrHero.Weapons.KnifeAbilities` (ModuleScript)

`Roles`, `allows`, `workspace`, `Gravity`, `Cannon`, `Flight`, `cannonLaunch`, `MaxMomentum`, `clamp`, `cannonMomentum`, `Skins`, `forSkin`, `StepOver`, `FakeTime`, `DashClipTime`, `stepOverTime`, `BigDistance`, `BigTime`, `stepOverBurstSpeed`, `freeze`, `Football`, `Futbol`, `AlbiesCutlass`, `Key`, `Truck`, `Remote`, `TruckAbilityEvent`, `ReadyAt`, `TruckAbilityReadyAt`, `Until`, `TruckUntil`, `Cooldown`, `ActiveLabel`, `Trucking`, `Shoulder`, `TouchHint`, `ActiveHint`, `AccentDark`, `Base`, `HintColor`, `TrackColor`, `fromRGB`, `StepOverEvent`, `StepOverReadyAt`, `StepOverUntil`, `Stepping`, `Juke`, `CannonAbilityEvent`, `CannonReadyAt`, `CannonUntil`, `Airborne`, `FakeDistance`, `Forward`, `CarrySeconds`, `FakeTowardInput`, `Credit`, `Distance`, `Behind`, `BlastRadius`, `BlastSpeed`, `BlastTime`, `Spins`, `PropScale`

### `ReplicatedStorage.ChickenOrHero.Weapons.KnifeChains` (ModuleScript)

`Arm`, `holds`, `Part1`, `Torso`, `pieces`, `torso`, `RootPart`, `Root`, `GripC0`, `GripC1`, `ChainStow`, `ChainGrip`, `Part0`, `chain`, `joint`, `attach`, `identity`, `Transform`, `scaled`, `rescale`, `shown`, `RigidConstraint`, `Attachment0`, `Attachment1`, `Bone`, `bones`, `holder`, `joints`, `followers`, `posed`, `place`, `healthy`, `KnifeVisibility`, `freeze`

### `ReplicatedStorage.ChickenOrHero.Weapons.KnifeClips` (ModuleScript)

`number`, `format`, `match`, `normalize`, `Anim`, `custom`, `Stow`, `PublishedIds`, `Actions`, `default`, `HandleAnimated`, `animated`, `StabContactStart`, `StabContactEnd`, `clamp`, `StabDuration`, `__index`, `timing`, `Animation`, `AnimationConfig`, `DaggerConfig`, `AnimationPriority`, `freeze`, `Equip`, `Hold`, `Windup`, `Stab`, `Dive`, `DaggerEquip`, `priority`, `looped`, `equip`, `Action2`, `DaggerHold`, `Action`, `DaggerWindup`, `DaggerStab`, `DaggerDive`, `Action3`, `ByClip`, `Idle`

### `ReplicatedStorage.ChickenOrHero.Weapons.KnifeDisplayRig` (ModuleScript)

`Game`, `IceSkates`, `DisplaySkates`, `Leg`, `Part0`, `Part1`, `wearSkates`, `scaled`, `_Preview`, `Tool`, `GetAttributes`, `Animator`, `HumanoidDisplayDistanceType`, `DisplayDistanceType`, `AutoRotate`, `BreakJointsOnDeath`, `ScaleTo`, `DisplayKnife`, `Handle`, `Blade`, `StowedBlade`, `DaggerGrip`, `GripC1`, `BladeWeld`, `JointInstance`, `Torso`, `StowedOffset`, `DisplaySheath`, `RootPart`, `RootFolder`, `RootStow`, `RootC0`, `identity`, `RootC1`, `RootRest`, `DualWield`, `attach`, `WeaponEffects`, `position`, `IdleGrip`, `animated`, `Massless`, `LocalTransparencyModifier`, `DisplayScale`, `GetScale`, `LobbyKnifeDisplay`, `LocalAvatarUserId`, `UserId`, `model`, `humanoid`, `animator`, `motor`, `blade`, `stowed`, `leftBlade`, `leftStowed`, `knife`, `rootMotor`, `scythe`, `scale`, `skates`, `basePivot`, `tracks`, `assets`, `rates`, `custom`, `cueFired`, `Dive`, `create`, `soundId`, `SoundDelay`, `Length`, `SoundEachLoop`, `SoundPerLoop`, `floor`, `clamp`, `soundIds`, `emoteCues`, `clone`, `BundleSequence`, `Sequence`, `bundle`, `assetId`, `Intro`, `introId`, `IntroLength`, `label`, `intro`, `introLength`, `duration`, `hidden`, `pieces`, `upper`, `Prop`, `HideProp`, `Pieces`, `BundleTail`, `sequenceFor`, `LoadAnimation`, `match`, `ByClip`, `Animation`, `IceSkating`, `Clips`, `PublishedIds`, `AnimationId`, `Display_`, `AnimationPriority`, `Action4`, `Priority`, `DaggerHold`, `Action`, `Action2`, `Idle`, `CaughtIdle`, `Movement`, `loadTrack`, `stageIndex`, `sequence`, `stage`

### `ReplicatedStorage.ChickenOrHero.Weapons.KnifeIconCopy` (ModuleScript)

`DataModelMesh`, `SurfaceAppearance`, `IsDescendantOf`, `Massless`, `CastShadow`, `IconWeld`, `Part0`, `Part1`, `CombineConfig`, `IsDualWield`, `DualWield`, `LeftBladeFrom`, `LeftBlades`, `twinSource`, `IconCross`, `crossing`, `Blade`, `fromAxisAngle`, `VectorToWorldSpace`, `LeftBlade`, `cross`, `freeze`

### `ReplicatedStorage.ChickenOrHero.Weapons.KnifeIcons` (ModuleScript)

`KnifeImages`, `scene`, `ImageTransparency`, `ImageColor3`, `KnifeImage`, `fromScale`, `FFlags`, `Basketball`, `Volleyball`, `BoneFork`, `BrassboundCutlass`, `ButterflyKnife`, `ClawKarambit`, `Dodgeball`, `FieldBowie`, `GlacialFang`, `GoldthornSaber`, `HarvestCutlass`, `HarvestSickle`, `HockeyEdge`, `JavelinSpike`, `Kukri`, `LockerKey`, `PhoenixTalon`, `PrismEdge`, `ShuttleShiv`, `SolarFlare`, `Stormcaller`, `TacticalTanto`, `TrenchKnife`, `TrophyBlade`, `VanguardAscendant`, `VanguardCharged`, `VanguardShortSword`, `Voidrend`, `AlbiesCutlass`, `AmberSting`, `AshenSickle`, `Ashsteel`, `BalloonDagger`, `BananaBlade`, `BansheesCry`, `BaseDagger`, `BedsheetBoo`, `Bloodthorn`, `BoneShiv`, `Bonker`, `CandyCornCleaver`, `CelestialDragon`, `ChatteringTeeth`, `CloneDagger`, `CluckBasher`, `CoffinNail`, `CopperBite`, `CrowboneDirk`, `DevelopersPencil`, `DrownedCutlass`, `DualImmortalKitsune`, `DualVoidKusarigamas`, `EclipseFang`, `FakeFinger`, `FallenAxes`, `FallenAxesBlue`, `FemurShiv`, `Football`, `ForestEdge`, `FunSizeFang`, `Futbol`, `Ghostlock`, `GhostPepper`, `GhostScythe`, `GhoulBlade`, `GlacialCrown`, `GlowstickShank`, `GraveShard`, `Gravewarden`, `GrinnerBlade`, `GrinnerBlades`, `HallowedEmber`, `Hallowreapers`, `Hexbinder`, `Hexflask`, `HollowMoon`, `Hotdog`, `IceCreamDagger`, `ImmortalKitsune`, `InfectedKnife`, `IronFang`, `iSlice`, `JackInTheBox`, `Kitsune`, `Kusarigama`, `LanternWarden`, `MoltenFang`, `Moonfang`, `MummyWrapShiv`, `Nightrend`, `NumberOneFan`, `OwnersTrident`, `PizzaPunisher`, `PlasticPitchfork`, `PumpkinCleaver`, `PumpkinPatchBlade`, `PumpkinPieSlicer`, `PumpkinSovereign`, `PumpkinSpiceShank`, `ReaperScythe`, `ReapersTithe`, `RoseQuartz`, `RuneboundSword`, `SecretPencil`, `SelfieStick`, `ShrineBreaker`, `SkeletonKey`, `SolarPhoenix`, `Soulbinder`, `SoulbinderBlade`, `SpectralReaper`, `SpiderFang`, `SpoonDagger`

### `ReplicatedStorage.ChickenOrHero.Weapons.KnifePerks` (ModuleScript)

`Skins`, `Rarity`, `forSkin`, `Game`, `AbilityRule`, `blocked`, `noAbilities`, `Ranked`, `ranked`, `EquippedKnife`, `CooldownReduction`, `cooldown`, `FantasySkinCatalog`, `freeze`, `Key`, `SpeedBonus`, `DashCooldownReduction`, `Epic`, `Legendary`, `Mythical`

### `ReplicatedStorage.ChickenOrHero.Weapons.KnifeVFXSetup` (ModuleScript)

`Rarity`, `Epic`, `Legendary`, `KnifeVFXGenerated`, `fromRGB`, `Blade`, `StowedBlade`, `Aura`, `CastShadow`, `Massless`, `WeaponVFX`, `VFXWeld`, `Part0`, `Part1`, `FantasyCrateSkin`, `BladeAxis`, `EdgeTip`, `EdgeHeel`, `BladeStreak`, `Attachment0`, `Attachment1`, `Lifetime`, `MinLength`, `LightEmission`, `FaceCamera`, `NumberSequenceKeypoint`, `WidthScale`, `VFXAuthoredEnabled`, `Motes`, `LightInfluence`, `Rate`, `VFXBaseRate`, `smoke`, `Speed`, `Acceleration`, `SpreadAngle`, `RotSpeed`, `ValleyWeaponVFX`, `AddTag`, `apply`, `CollectionService`, `GetService`, `CopperBite`, `Ashsteel`, `IronFang`, `ForestEdge`, `AmberSting`, `RoseQuartz`, `TidalShard`, `VenomThorn`, `MoltenFang`, `SpectralReaper`, `StormTalon`, `Moonfang`, `SolarPhoenix`, `VoidSovereign`, `Voidspine`, `Bloodthorn`, `VipersFang`, `GlacialCrown`, `CelestialDragon`, `BaseDagger`, `SpoonDagger`, `BalloonDagger`, `Hotdog`, `NumberOneFan`, `SelfieStick`, `Icicle`, `sparkles`

### `ReplicatedStorage.ChickenOrHero.Weapons.KnifeVisibility` (ModuleScript)

`KnifeTransparency`, `number`, `Light`, `KnifeEffectOn`, `boolean`, `partsOf`, `Clear`, `__mode`, `freeze`

### `ReplicatedStorage.ChickenOrHero.Weapons.KusarigamaCastHold` (ModuleScript)

`KusarigamaCastHold`, `Origin`, `LinearVelocity`, `Attachment0`, `ActuatorRelativeTo`, `World`, `RelativeTo`, `VelocityConstraintMode`, `Vector`, `VectorVelocity`, `ForceLimitsEnabled`, `AssemblyAngularVelocity`, `character`, `attachment`, `velocity`, `WorldPosition`, `position`, `release`

### `ReplicatedStorage.ChickenOrHero.Weapons.KusarigamaConfig` (ModuleScript)

`freeze`, `KusarigamaHook`, `Knives`, `PreviewKnife`, `UltimateVoidBlades`, `FreezeCaster`, `Range`, `Cooldown`, `Windup`, `Speed`, `HookRadius`, `EscapeWindow`, `EscapePresses`, `PressesPerSecond`, `PressBurst`, `PullSpeed`, `MinPullSeconds`, `MaxPullSeconds`, `StopDistance`, `StabAt`, `FinishSeconds`, `ReturnSpeed`, `MaxReturnSeconds`, `MaxReelSeconds`, `MaxLifetime`, `Animations`, `Sounds`, `Throw`, `Pull`, `Finish`, `Hooked`, `Hook`, `Reel`, `Stab`, `Break`

### `ReplicatedStorage.ChickenOrHero.Weapons.MergeEventInfo` (ModuleScript)

`round`, `border`, `fromScale`, `ExtraBold`, `StrokeSizingMode`, `ScaledSize`, `GameAudio`, `GetService`, `LazySound`, `playLocal`, `sound`, `ThumbAxis`, `ThumbNormal`, `fromMatrix`, `Angles`, `iconPose`, `Blade`, `Knife`, `fromRGB`, `VectorToWorldSpace`, `cross`, `lookAt`, `knifeIcon`, `tierOf`, `isFusion`, `TierColors`, `clamp`, `tierColor`, `AspectRatio`, `Level`, `Heavy`, `Progression`, `JourneySeason1Rewards`, `number`, `Free`, `Spins`, `remove`, `concat`, `journeyLevels`, `EndsAt`, `floor`, `format`, `countdown`, `Step`, `Number`, `DominantAxis`, `Height`, `Body`, `Lines`, `Bold`, `LineHeight`, `lines`, `Arrow`, `arrow`, `close`, `InMatch`, `MergeEventInfo`, `ZIndexBehavior`, `Sibling`, `Panel`, `MaxSize`, `MinSize`, `UISizeConstraint`, `Merge`, `EventName`, `upper`, `TimerPill`, `Timer`, `Modal`, `Interface`, `WheelIcon`, `TeamEventConfig`, `SPIN`, `Order`, `Families`, `Wheel`, `Tiers`, `MERGE`, `Costs`, `Names`, `Fusion`, `FUSE`, `Inputs`, `Output`, `Where`, `GotIt`, `timer`, `build`, `MergeInfoOpen`, `PanelOpen`, `PanelClose`, `isOpen`, `CombineConfig`, `SkinCatalog`, `KnifeIconCopy`, `KnifeIcons`

### `ReplicatedStorage.ChickenOrHero.Weapons.OfferRules` (ModuleScript)

`Unavailable`, `StartsAt`, `EndsAt`, `number`, `Upcoming`, `Expired`, `status`, `format`, `countdown`, `DateTime`, `fromUniversalTime`, `UnixTimestamp`, `lastSunday`, `ukSaturdayDeadline`

### `ReplicatedStorage.ChickenOrHero.Weapons.ScythePose` (ModuleScript)

`clamp`, `angle`, `WeaponStyle`, `Scythe`, `Handle`, `Blade`, `BladeWeld`, `GripPoint`, `recoveryLift`, `recoveryTurn`, `gripInHandle`, `gripInverse`, `DiveRecoveryLiftDegrees`, `DiveRecoveryTurnDegrees`, `restore`, `number`, `Angles`, `apply`, `freeze`

### `ReplicatedStorage.ChickenOrHero.Weapons.ShopConfig` (ModuleScript)

`New`, `StartsAt`, `NewDays`, `isNew`, `Flagships`, `EndsAt`, `featured`, `featuredAll`, `OfferKey`, `flagship`, `TestUniverseId`, `LiveUniverseId`, `storeUniverse`, `Universes`, `clone`, `PassIds`, `TestPassIds`, `ProductIds`, `PurchasesEnabled`, `binding`, `Promotion`, `promotionActive`, `OfferRules`, `Year`, `Month`, `Day`, `WeekEnding`, `ukSaturdayDeadline`, `FlagshipWeekEnding`, `SkinId`, `DevelopersPencil`, `Price`, `Eyebrow`, `Tagline`, `Description`, `Footnote`, `Earnable`, `MaxDistance`, `PromptDistance`, `AnimationDistance`, `SoundDistance`, `Display`, `CloneDagger`, `Flagship`, `GhostScythe`, `Ghost`, `GhostFlagship`, `Football`, `FOOTBALL`, `FootballFlagship`, `Futbol`, `FUTBOL`, `FutbolFlagship`, `GameId`, `Icicle`, `IcicleKnife`, `Kind`, `Bundle`, `ICICLE`, `AdditionalKnives`, `IceCream`, `Spoon`, `Selfie`, `DoubleXP`, `VIP`, `IceCreamDagger`, `SpoonDagger`, `SelfieStick`, `Multiplier`, `RewardSkinId`, `VIPDagger`, `Passes`, `Key`, `Coins1`, `Currency`, `coins`, `Amount`, `Coins2`, `Coins3`, `Coins4`, `Coins5`, `Coins6`, `Gems1`, `Gems2`, `Gems3`, `Gems4`, `Gems5`, `Gems6`, `Packs`, `UniverseId`, `ProductGrants`

### `ReplicatedStorage.ChickenOrHero.Weapons.SkinCatalog` (ModuleScript)

`Available`, `EquipReady`, `Offer`, `Price`, `number`, `canBuy`, `Skins`, `ShopConfig`, `OfferRules`, `Default`, `BaseDagger`, `Order`, `VIPDagger`, `DevelopersPencil`, `SecretPencil`, `CloneDagger`, `GhostScythe`, `SpoonDagger`, `IceCreamDagger`, `BalloonDagger`, `TopWinsDagger`, `OwnersTrident`, `Description`, `SoundProfile`, `Collection`, `fromRGB`, `DefaultOwned`, `RewardKey`, `FriendReferral`, `TopWins`, `FantasySkinCatalog`, `ComedySkinCatalog`, `Kitsune`, `ImmortalKitsune`, `DualImmortalKitsune`, `Kusarigama`, `VoidKusarigama`, `DualVoidKusarigamas`, `UltimateVoidBlades`, `SourceName`, `Stackable`, `upper`, `CelestialLegendary`, `InfectedKnife`, `Earnable`, `SkinId`, `Currency`, `StartsAt`, `EndsAt`, `Equip`, `Windup`, `Swing`, `Dive`, `Hit`, `Sheath`, `DiveHit`, `SoundEvents`

### `ReplicatedStorage.ChickenOrHero.Weapons.StorefrontClient` (ModuleScript)

`secondary`, `giftLook`, `floor`, `reverse`, `comma`, `fromOffset`, `Gem`, `Pass`, `Bundle`, `primary`, `price`, `paint`, `connect`, `ShopPressScale`, `MouseEnter`, `MouseLeave`, `SelectionGained`, `SelectionLost`, `animateButton`, `purchase`, `binding`, `PassIds`, `ProductIds`, `productId`, `offers`, `Football`, `Futbol`, `flagshipEntry`, `attach`, `offer`, `KnifePreview`, `SkinId`, `Fire`, `PreviewRotation`, `Angles`, `ShopPreview`, `JointInstance`, `cross`, `Weapon`, `PreviewZoom`, `clamp`, `extent`, `camera`, `Loading`, `build`, `dragging`, `lastX`, `Eyebrow`, `Tagline`, `Description`, `Footnote`, `Buy`, `Reward`, `OfferKey`, `Equip`, `Swing`, `Hit`, `Sounds`, `Blade`, `rotation`, `previews`, `pendingPreviews`, `feature`, `QuestOpenRequestedAt`, `clock`, `questState`, `refreshQuest`, `status`, `owned`, `MouseMovement`, `refresh`, `layoutWidth`, `layoutPortrait`, `layout`, `canvas`, `player`, `catalog`, `sections`, `Storefront`, `GameId`, `Coins`, `Gems`, `GuiButton`, `Selectable`, `QuestProgress`, `fromRGB`, `corner`, `stroke`, `Gold`, `textStroke`, `KnifeName`, `fromScale`, `green`, `OpenQuests`, `questCard`, `ChickenOrHero`, `Quests`, `QuestEvent`, `questRemote`, `OnClientEvent`, `Featured`, `GhostFeatured`, `FootballFeatured`, `FutbolFeatured`, `bundleCards`, `LimitedBundle`, `bundle`, `LimitedHeading`, `LIMITED`, `Flagship`, `GhostFlagship`, `FootballFlagship`, `FutbolFlagship`, `EventKnives`, `eventFrame`, `eventOptions`, `Index`, `Key`, `Blurb`, `AdditionalKnives`

### `ReplicatedStorage.ChickenOrHero.Weapons.WeaponEffects` (ModuleScript)

`WeaponVFX`, `VFXWeld`, `Part0`, `Part1`, `position`, `Value`, `detail`, `workspace`, `IsDescendantOf`, `LocalTransparencyModifier`, `MaxDistance`, `FadeStart`, `clamp`, `VFXAuthoredEnabled`, `VFXBaseRate`, `Rate`, `Clear`, `update`, `Tag`, `ValleyWeaponVFX`, `freeze`

### `ReplicatedStorage.EmitModule` (ModuleScript)

`setCollisionGroups`, `COLLISION_GROUPS`, `format`, `setup`, `IsServer`, `scope`, `caches`, `shared`, `shared_part`, `cleanupScope`, `deinit`, `CLEANUP_TAG`, `GetTagged`, `fullEmit`, `number`, `emitWithDepth`, `GetService`, `CollectionService`, `PLUGIN_CONTEXT`, `SERVER_CONTEXT`

### `ReplicatedStorage.EmitModule.effects.beam` (ModuleScript)

`getAttribute`, `Width0`, `Width1`, `StartWidth0`, `StartWidth1`, `getLegacyWidths`, `TextureSpeed`, `scaleNumberSequence`, `setTScale`, `setLengthScale`, `TextureLength`, `CurveSize0`, `CurveSize1`, `Connected`, `effects`, `prepareEmitOnFinish`, `Width0_Start`, `Width0_End`, `Width1_Start`, `Width1_End`, `CurveSize0_Start`, `CurveSize0_End`, `CurveSize1_Start`, `CurveSize1_End`, `EmitDelay`, `Duration`, `EndTransparencyScale`, `getRangeAttribute`, `EffectDuration`, `Length_Scale_Start`, `Length_Scale_End`, `Length_Texture_Start`, `Length_Texture_End`, `Transparency_Scale_Start`, `Transparency_Scale_End`, `Speed_Texture_Start`, `Speed_Texture_End`, `Speed_Start`, `Speed_End`, `emitNested`, `depth`, `Finished`, `fromParams`, `Speed_Texture_Curve`, `default_bezier`, `Speed_Curve`, `Speed_Duration`, `Attachment0`, `Attachment1`, `Transparency_Scale_Curve`, `Length_Texture_Curve`, `Length_Scale_Curve`, `Width0_Curve`, `Width1_Curve`, `CurveSize0_Curve`, `CurveSize1_Curve`, `timer`, `emitOnFinish`, `workspace`, `Terrain`, `await`

### `ReplicatedStorage.EmitModule.effects.bezier` (ModuleScript)

`deinit`, `facePath`, `arcSpace`, `rotSpeedStart`, `rotSpeedEnd`, `minInitRot`, `maxInitRot`, `speedCurve`, `speedDuration`, `easingCurve`, `getAttribute`, `FacePath`, `ArcSpace`, `getRangeAttribute`, `RotSpeed_Start`, `RotSpeed_End`, `MinInitRot`, `MaxInitRot`, `Speed_Curve`, `default_bezier`, `Speed_Duration`, `Easing_Curve`, `linear_bezier`, `readBezierAttributes`, `SpeedOverride`, `speedStart`, `speedEnd`, `SpeedTweening`, `getTransformedOriginExtents`, `updatePos`, `UnbindFromRenderStep`, `syncPosition`, `getRandomId`, `RENDER_PRIORITY`, `depth`, `effects`, `emitOnFinish`, `Finished`, `finally`, `onFinish`, `hitboxEnabled`, `workspace`, `GetPartsInPart`, `shapecast`, `getEffectiveSpeed`, `Connected`, `isSpeedTweening`, `clamp`, `lookAt`, `DEG_TO_RAD`, `fromOrientation`, `projectileEnabled`, `projectileMatchEnd`, `WorldCFrame`, `projectileSpeed`, `timer`, `calculateEmissionCFrame`, `spreadAngle`, `mirror`, `mirrorRot`, `partial`, `emissionDirection`, `createBezierWithEndpoint`, `createPosGetter`, `_getReal`, `copyProperties`, `COPY_PART_PROPERTIES`, `COPY_EXTENDED_PART_PROPERTIES`, `prepareEmitOnFinish`, `emitNested`, `identity`, `fromParams`, `createPropertyTween`, `RotSpeed`, `Points`, `readCommonAttributes`, `drawFuncMap`, `shapeType`, `shapeStyle`, `emitDuration`, `emitDelay`, `emitCount`, `validateParent`, `findEndAttachments`, `getBezierPoints`, `createHitboxParams`, `enabled`, `collisionGroup`, `filterTag`, `filterType`, `ignoreCanCollide`, `hitboxCollisionGroup`, `hitboxFilterTag`, `hitboxFilterType`, `hitboxIgnoreCanCollide`, `vector`, `create`, `duration`, `projectileLifetime`, `await`, `destroyDelay`, `GetService`

### `ReplicatedStorage.EmitModule.effects.camera_shake` (ModuleScript)

`workspace`, `IsRunning`, `ToOrientation`, `fromOrientation`, `identity`, `Angles`, `updateCamera`, `forge_updateCameraShake`, `Last`, `Value`, `UnbindFromRenderStep`, `deinit`, `FindFirstAncestorOfClass`, `FindFirstAncestorWhichIsA`, `getTransformedOriginExtents`, `clamp`, `getAttribute`, `EmitDelay`, `EmitDuration`, `Falloff`, `Amplitude`, `Frequency`, `FadeInTime`, `FadeOutTime`, `SustainTime`, `PositionInfluence`, `RotationInfluence`, `Speed_Start`, `Speed_End`, `Sustain`, `TimeFunction`, `fromParams`, `Speed_Curve`, `default_bezier`, `Speed_Duration`, `running`, `NextRenderName`, `RENDER_PRIORITY`, `depth`, `Start`, `StopSustain`, `yield`, `GetService`

### `ReplicatedStorage.EmitModule.effects.lightning` (ModuleScript)

`deinit`, `segments`, `jaggedness`, `offsetScale`, `refreshRate`, `independentSegments`, `refreshDuringDissipate`, `nestedEffectMode`, `colorSequence`, `colorEasingData`, `colorDuration`, `transparencyStart`, `transparencyEnd`, `fillColorSequence`, `fillColorEasingData`, `fillColorDuration`, `fillTransparencyStart`, `fillTransparencyEnd`, `fillDepthMode`, `fadeInStart`, `fadeInDuration`, `fadeInCurveData`, `fadeOutEnd`, `fadeOutDuration`, `fadeOutCurveData`, `lengthStart`, `lengthEnd`, `dissipateMode`, `dissipateDuration`, `dissipateCurveData`, `widthStart`, `widthEnd`, `getAttribute`, `Segments`, `getRangeAttribute`, `Jaggedness`, `OffsetScale`, `RefreshRate`, `IndependentSegments`, `RefreshDuringDissipate`, `getEnumAttribute`, `NestedEffectMode`, `All`, `Head`, `Tail`, `Color_Curve`, `linear_bezier`, `Color_Duration`, `Transparency_Start`, `Transparency_End`, `Fill_Color`, `Fill_Color_Curve`, `Fill_Color_Duration`, `Fill_Transparency_Start`, `Fill_Transparency_End`, `Fill_DepthMode`, `Occluded`, `AlwaysOnTop`, `Fade_In_Start`, `Fade_In_Duration`, `Fade_In_Curve`, `default_bezier`, `Fade_Out_End`, `Fade_Out_Duration`, `Fade_Out_Curve`, `Length_Start`, `Length_End`, `Dissipate_Mode`, `Retract`, `Dissipate_Duration`, `Dissipate_Curve`, `Width_Start`, `Width_End`, `readLightningAttributes`, `birthTime`, `initialWidth`, `initialTransparency`, `wasVisible`, `createSegmentStates`, `computeJaggedOffset`, `create`, `getPerpendicularVectors`, `generateLightningPoints`, `generateProjectilePoints`, `boltLength`, `distanceTraveled`, `transitionBuffer`, `clamp`, `curvedLengthT`, `curvedTailT`, `getBlendedPosition`, `generateTransitionPoints`, `jaggedOffsets`, `updateTransitionPoints`, `isTransitionComplete`, `SpeedOverride`, `speedStart`, `speedEnd`, `SpeedTweening`, `shouldEmitNested`, `getEffectiveSpeed`, `Connected`, `isSpeedTweening`, `getSpeedDelta`, `getHeadSegmentIndex`, `hitboxEnabled`, `workspace`, `GetPartsInPart`, `shapecast`, `refreshPoints`, `projectileSpeed`, `updatePointsBetweenRefreshes`, `clock`, `start`, `finish`, `getColorWithEasingOklab`, `getEase`, `lookAt`, `FillColor`, `FillTransparency`

### `ReplicatedStorage.EmitModule.effects.mesh` (ModuleScript)

`SpeedOverride`, `SpeedTweening`, `getTransformedOriginExtents`, `fromOrientation`, `updatePos`, `UnbindFromRenderStep`, `identity`, `match`, `round`, `fromSRGB`, `toSRGB`, `format`, `Connected`, `Start`, `End`, `getAttribute`, `Duration`, `getRangeAttribute`, `EffectDuration`, `EmitDelay`, `EmitDuration`, `Flipbook`, `FlipbookFadeOffset`, `Mesh_`, `Decal_`, `StartTransparency`, `EndTransparency`, `ENABLED_VFX_TAG`, `HasTag`, `Decal_StartTransparency`, `Decal_EndTransparency`, `Mesh_StartTransparency`, `Mesh_EndTransparency`, `SyncPosition`, `Speed_Start`, `Speed_End`, `Part_Transparency_Start`, `Part_Transparency_End`, `SpreadAngle`, `Part_RotSpeed_Start`, `Part_RotSpeed_End`, `RotAroundOrigin`, `MinInitRot`, `MaxInitRot`, `vector`, `create`, `DEG_TO_RAD`, `fromParams`, `Speed_Curve`, `default_bezier`, `Speed_Duration`, `FindFirstAncestorOfClass`, `_getReal`, `getRandomId`, `RENDER_PRIORITY`, `depth`, `effects`, `prepareEmitOnFinish`, `emitNested`, `Finished`, `Part_CFrame_Curve`, `Part_RotSpeed_Curve`, `Part_Transparency_Curve`, `Part_Size_Curve`, `SpecialMesh`, `Mesh_Scale_Curve`, `getMeshDecals`, `Transparency_Start`, `Transparency_End`, `Transparency_Curve`, `Color_Curve`, `Flipbook_Change_Duration`, `SyncDuration`, `IsStudio`, `GetTags`, `Flipbook_Change_Curve`, `linear_bezier`, `timer`, `await`, `emitOnFinish`, `GetService`, `CollectionService`

### `ReplicatedStorage.EmitModule.effects.particle` (ModuleScript)

`clamp`, `TimeScale`, `Connected`, `getAttribute`, `EmitDelay`, `EmitCount`, `EmitDuration`, `TimeScale_Duration`, `TimeScale_Start`, `TimeScale_End`, `fromParams`, `TimeScale_Curve`, `default_bezier`, `Emit`, `timer`, `Lifetime`

### `ReplicatedStorage.EmitModule.effects.screen` (ModuleScript)

`Default`, `CollisionGroup`, `workspace`, `ViewportSize`, `fromOrientation`, `frame`, `UnbindFromRenderStep`, `getAttribute`, `PartScale`, `PartDistance`, `OffsetPosition`, `OffsetRotation`, `DEG_TO_RAD`, `ForgeMouseIgnore`, `IsRunning`, `getRandomId`, `RENDER_PRIORITY`, `depth`, `GetService`

### `ReplicatedStorage.EmitModule.effects.shockwave_debris` (ModuleScript)

`workspace`, `StepPhysics`, `PLUGIN_CONTEXT`, `deinit`, `remove`, `fromParams`, `effects`, `emitOnFinish`, `depth`, `Finished`, `getAttribute`, `InheritanceEnabled`, `InheritanceRadius`, `InheritanceMaxResults`, `RayCollisionGroup`, `Default`, `FilterTag`, `FilterType`, `Exclude`, `IgnoreCanCollide`, `OverlapParams`, `MaxParts`, `CollisionGroup`, `RespectCanCollide`, `RaycastFilterType`, `GetTagged`, `FilterDescendantsInstances`, `Terrain`, `AddToFilter`, `EmitDelay`, `getRangeAttribute`, `Amount`, `Lifetime`, `Airtime`, `LinearMagnitude`, `AngularMagnitude`, `SizeScaleEnd`, `MinSize`, `MaxSize`, `MinDirection`, `MaxDirection`, `Size_Curve`, `default_bezier`, `Transparency_Curve`, `Transparency_Duration`, `Size_Duration`, `Transparency_Start`, `Transparency_End`, `getTransformedOriginExtents`, `GetPartBoundsInRadius`, `getRandomId`, `_getReal`, `copyProperties`, `COPY_PART_PROPERTIES`, `COPY_EXTENDED_PART_PROPERTIES`, `prepareEmitOnFinish`, `ForgeDebris`, `VectorToWorldSpace`, `randomUnitVector`, `AssemblyMass`, `getImpulseForce`, `NextUnitVector`, `ApplyAngularImpulse`, `emitNested`, `await`, `GetService`, `CollectionService`

### `ReplicatedStorage.EmitModule.effects.shockwave_line` (ModuleScript)

`deinit`, `deserializePath`, `fromParams`, `getAttribute`, `Offset_End_Curve`, `default_bezier`, `Transparency_Curve`, `effects`, `emitOnFinish`, `depth`, `Finished`, `clamp`, `getEase`, `getTransformedOriginExtents`, `workspace`, `VectorToWorldSpace`, `getRandomId`, `_getReal`, `copyProperties`, `COPY_PART_PROPERTIES`, `COPY_EXTENDED_PART_PROPERTIES`, `prepareEmitOnFinish`, `Normal`, `fromMatrix`, `fromOrientation`, `Offset_Start_Curve`, `emitNested`, `RayDirection`, `RayCollisionGroup`, `Default`, `FilterTag`, `FilterType`, `Exclude`, `IgnoreWater`, `IgnoreCanCollide`, `RaycastParams`, `CollisionGroup`, `RespectCanCollide`, `RaycastFilterType`, `GetTagged`, `FilterDescendantsInstances`, `Terrain`, `AddToFilter`, `EmitDelay`, `Rate_Start`, `Rate_End`, `FixedAmount`, `Scale_Start`, `Scale_End`, `Duration`, `Direction`, `Length`, `getRangeAttribute`, `PartOffset`, `BaseOffset`, `Offset_Start`, `Offset_End`, `Offset_Start_Duration`, `Offset_End_Duration`, `Lifetime`, `SizeScaleStart`, `SizeScaleEnd`, `MinSize`, `MaxSize`, `Size_Curve`, `Size_Duration`, `Size_Start_Curve`, `Size_End_Curve`, `Size_Start_Duration`, `Size_End_Duration`, `Transparency_Duration`, `Transparency_Start`, `Transparency_End`, `SyncPosition`, `Scale_Curve`, `Rate_Curve`, `Path_Curve`, `linear_bezier`, `format`, `RENDER_PRIORITY`, `await`, `CollectionService`, `GetService`

### `ReplicatedStorage.EmitModule.effects.shockwave_ring` (ModuleScript)

`deinit`, `fromParams`, `getAttribute`, `Offset_End_Curve`, `default_bezier`, `Transparency_Curve`, `effects`, `emitOnFinish`, `depth`, `Finished`, `RayDirection`, `RayCollisionGroup`, `Default`, `FilterTag`, `FilterType`, `Exclude`, `IgnoreWater`, `IgnoreCanCollide`, `RaycastParams`, `CollisionGroup`, `RespectCanCollide`, `RaycastFilterType`, `GetTagged`, `FilterDescendantsInstances`, `workspace`, `Terrain`, `AddToFilter`, `EmitDelay`, `Radius`, `Segments`, `getRangeAttribute`, `Lifetime`, `PartOffset`, `BaseOffset`, `Offset_Start`, `Offset_End`, `Offset_Start_Duration`, `Offset_End_Duration`, `SizeScaleStart`, `SizeScaleEnd`, `MinSize`, `MaxSize`, `Size_Curve`, `Size_Duration`, `Size_Start_Curve`, `Size_End_Curve`, `Size_Start_Duration`, `Size_End_Duration`, `Transparency_Duration`, `Transparency_Start`, `Transparency_End`, `getTransformedOriginExtents`, `VectorToWorldSpace`, `getRandomId`, `_getReal`, `copyProperties`, `COPY_PART_PROPERTIES`, `COPY_EXTENDED_PART_PROPERTIES`, `prepareEmitOnFinish`, `Normal`, `fromMatrix`, `fromOrientation`, `Offset_Start_Curve`, `emitNested`, `await`, `CollectionService`, `GetService`

### `ReplicatedStorage.EmitModule.effects.spin` (ModuleScript)

`ScaleTo`, `getTransformedOriginExtents`, `clamp`, `fromOrientation`, `Connected`, `isSpinModelStatic`, `getAttribute`, `SpinRotation`, `DEG_TO_RAD`, `Scale_Start`, `Scale_End`, `EmitDelay`, `SyncPosition`, `SpinDuration`, `SpinSpeed_Duration`, `SpinSpeed_Start`, `SpinSpeed_End`, `fromParams`, `SpinSpeed_Curve`, `default_bezier`, `GetScale`, `Scale_Curve`, `FindFirstAncestorOfClass`, `FindFirstAncestorWhichIsA`, `timer`, `RENDER_PRIORITY`, `depth`

### `ReplicatedStorage.EmitModule.effects.tween_property` (ModuleScript)

`Connected`, `getAttribute`, `EmitDelay`, `ResetOnFinish`, `getRangeAttribute`, `Duration`, `_END_VALUE`, `_START_VALUE`, `Speed_Start`, `Speed_End`, `fromParams`, `Speed_Curve`, `default_bezier`, `Speed_Duration`, `Other`, `Easing_Curve`, `linear_bezier`, `RENDER_PRIORITY`, `depth`, `timer`

### `ReplicatedStorage.EmitModule.emitters` (ModuleScript)

`getAttribute`, `EmitCount`, `EmitDuration`, `workspace`, `IsDescendantOf`, `cloneParticleAncestry`, `Archivable`, `Terrain`, `particle`, `Attachment0`, `Attachment1`, `Length_Scale_Start`, `Length_Scale_End`, `ForgeTempAttachment`, `trail`, `Locked`, `bezier`, `lightning`, `assembleMeshVFX`, `Start`, `await`, `unlock`, `camera_shake`, `tween_property`, `screen`, `shockwave_ring`, `shockwave_debris`, `shockwave_line`, `ClassName`, `RayValue`, `SCREENSHAKE_TAG`, `HasTag`, `BEZIER_TAG`, `LIGHTNING_TAG`, `isMeshVFX`, `findFirstClassWithTag`, `SHOCKWAVE_TAG`, `Rings`, `Debris`, `Lines`, `dispatch`, `check`, `enabled_registry`

### `ReplicatedStorage.EmitModule.mod.bezier_common` (ModuleScript)

`getPointWithinCylinder`, `Surface`, `getPointWithinSphere`, `getPointWithinDisc`, `Keypoints`, `Time`, `Value`, `getColorAtTime`, `fromSRGB`, `toSRGB`, `getColorAtTimeOklab`, `clamp`, `getEase`, `getColorWithEasingOklab`, `OverlapParams`, `MaxParts`, `RaycastFilterType`, `filterType`, `FilterType`, `collisionGroup`, `CollisionGroup`, `ignoreCanCollide`, `RespectCanCollide`, `filterTag`, `GetTagged`, `AddToFilter`, `Exclude`, `FindFirstAncestorOfClass`, `workspace`, `Terrain`, `createHitboxParams`, `FromNormalId`, `emissionDirection`, `partial`, `fromAxisAngle`, `spreadAngle`, `Inward`, `InAndOut`, `fromOrientation`, `mirror`, `WorldPosition`, `mirrorRot`, `DEG_TO_RAD`, `calculateEmissionCFrame`, `createBezierWithEndpoint`, `getPositionArcSpace`, `getPosition`, `createPosGetter`, `emitDelay`, `emitCount`, `emitDuration`, `destroyDelay`, `duration`, `shapeType`, `shapeStyle`, `syncPosition`, `projectileEnabled`, `projectileMatchEnd`, `projectileSpeed`, `projectileLifetime`, `hitboxEnabled`, `hitboxCollisionGroup`, `hitboxFilterTag`, `hitboxFilterType`, `hitboxIgnoreCanCollide`, `speedStart`, `speedEnd`, `getAttribute`, `EmitDelay`, `EmitCount`, `EmitDuration`, `DestroyDelay`, `getRangeAttribute`, `Duration`, `getEnumAttribute`, `Shape`, `Box`, `Cylinder`, `Sphere`, `Disc`, `ShapeStyle`, `NormalId`, `EmissionDirection`, `Front`, `ShapeFace`, `Outward`, `SpreadAngle`, `ShapePartial`, `SyncPosition`, `MirrorPaths`, `MirrorRotation`, `ProjectileEnabled`, `MatchEndDirection`, `ProjectileSpeed`, `ProjectileLifetime`, `HitboxEnabled`, `HitboxCollisionGroup`, `Default`, `HitboxFilterTag`, `HitboxFilterType`, `HitboxIgnoreCanCollide`, `Speed_Start`, `Speed_End`, `readCommonAttributes`, `WorldCFrame`, `getCurrentOriginCFrame`, `End`, `findEndAttachments`, `validateParent`, `getPerpendicularVectors`, `fromParams`, `_Curve`, `default_bezier`, `createPropertyTween`, `CollectionService`, `GetService`, `getPointWithinBox`, `getPointOnBox`, `drawFuncMap`

### `ReplicatedStorage.EmitModule.mod.color.Oklab` (ModuleScript)

`fromLinear`, `toLinear`, `fromSRGB`, `clamp`, `toSRGB`

### `ReplicatedStorage.EmitModule.mod.color.sRGB` (ModuleScript)

`transform`, `inverse`, `fromLinear`, `toLinear`

### `ReplicatedStorage.EmitModule.mod.lerp` (ModuleScript)

`number`, `toSRGB`, `fromSRGB`, `Density`, `Friction`, `Elasticity`, `FrictionWeight`, `ElasticityWeight`, `Time`, `Keypoints`, `Value`, `Envelope`, `NumberSequenceKeypoint`, `floor`, `getColorAtTime`, `ColorSequenceKeypoint`, `Other`

### `ReplicatedStorage.EmitModule.mod.logger` (ModuleScript)

`concat`, `format`, `debug`, `traceback`

### `ReplicatedStorage.EmitModule.mod.shape` (ModuleScript)

`lookAt`, `getSurfaceCFrame`, `debug`, `profilebegin`, `getPointWithinBox`, `FromNormalId`, `profileend`, `getPointOnBox`, `getPointWithinCylinder`, `NormalId`, `fromOrientation`, `Front`, `getPointWithinSphere`, `Angles`, `getPointWithinDisc`

### `ReplicatedStorage.EmitModule.mod.tween` (ModuleScript)

`deserializePath`, `clamp`, `getEase`, `Connected`, `UnbindFromRenderStep`, `format`, `getRandomId`, `fromParams`, `running`, `yield`, `timer`, `GetService`

### `ReplicatedStorage.EmitModule.mod.utility` (ModuleScript)

`running`, `unlock`, `RegisterCollisionGroup`, `Studio`, `match`, `IsStudio`, `CollisionGroupSetCollidable`, `setCollisionGroups`, `getRandomId`, `copyProperties`, `format`, `xpcall`, `cancel`, `reboundfn`, `randomUnitVector`, `workspace`, `Gravity`, `getImpulseForce`, `Start`, `End`, `isMeshVFX`, `getAttribute`, `SpinRotation`, `Scale_Start`, `Scale_End`, `SyncPosition`, `isSpinModelStatic`, `BEZIER_TAG`, `HasTag`, `LIGHTNING_TAG`, `findFirstClassWithTag`, `SHOCKWAVE_TAG`, `shouldSkipNested`, `depth`, `effects`, `cleanupScope`, `createEmitPromise`, `RBXScriptConnection`, `thread`, `status`, `function`, `Terrain`, `AncestryChanged`, `protectParent`, `ClassName`, `findAncestor`, `fromExisting`, `Archivable`, `Locked`, `recurse`, `FindFirstAncestorWhichIsA`, `FindFirstAncestorOfClass`, `cloneParticleAncestry`, `clamp`, `getRangeAttribute`, `getEnumAttribute`, `identity`, `WorldCFrame`, `PositionScale`, `OverrideWorldRotation`, `WorldRotation`, `DEG_TO_RAD`, `fromOrientation`, `getTransformedOriginExtents`, `filter`, `Flipbook`, `FlipbookEnabled`, `deserializeFlipbook`, `FlipbookTextures`, `remove`, `serializeFlipbook`, `buffer`, `getMeshDecals`, `_getReal`, `COPY_PART_PROPERTIES`, `COPY_EXTENDED_PART_PROPERTIES`, `CLEANUP_TAG`, `AddTag`, `assembleMeshVFX`, `WorldPosition`, `PointToObjectSpace`, `vector`, `create`, `getBezierPoints`, `Keypoints`, `Value`, `Envelope`, `NumberSequenceKeypoint`, `Time`, `scaleNumberSequence`, `LeftTangent`, `writef32`, `RightTangent`, `serializePath`, `fromstring`, `readf32`, `deserializePath`, `writef64`, `readf64`, `GetService`, `PhysicsService`, `Plugin`, `IsRunning`, `PLUGIN_CONTEXT`, `IsServer`, `SERVER_CONTEXT`, `BezierParticle`, `LightningBolt`, `Shockwave`, `CameraShake`, `SCREENSHAKE_TAG`, `ConstantVFX`, `ENABLED_VFX_TAG`, `LoadVFXTextures`, `TEXTURE_LOAD_TAG`, `__forge__cleanupOnExit`, `RENDER_PRIORITY`, `StudioSelectable`, `ForgeDebris`, `ForgeMouseIgnore`

### `ReplicatedStorage.EmitModule.obj.Bezier` (ModuleScript)

`cubicBezier`, `cubicBezierDerivative`, `points`, `accuracy`, `point_count`, `cumulative_lengths`, `_recalculate`, `setPoints`, `getSegmentPoints`, `length`, `getPositionArcSpace`, `forSample`, `getSegmentIndex`, `getPosition`, `clamp`, `floor`, `getEasedSegmentIndex`, `getEase`, `vector`, `magnitude`, `__index`

### `ReplicatedStorage.EmitModule.obj.ObjectCache` (ModuleScript)

`reconcile`, `workspace`, `BulkMoveMode`, `FireCFrameChanged`, `BulkMoveTo`, `yield`, `restore_amount`, `_add`, `amount`, `params`, `unused`, `dependents`, `clock`, `added`, `excess_lifetime`, `destroy`, `remove`, `item_map`, `parent`, `scope`, `create`, `part_mode`, `Archivable`, `value`, `__newindex`, `function`, `__index`, `_getReal`, `on_free`, `cleanupScope`

### `ReplicatedStorage.EmitModule.pkg.Promise` (ModuleScript)

`function`, `__call`, `isCallable`, `format`, `__index`, `__newindex`, `makeEnum`, `trace`, `context`, `parent`, `createdTick`, `createdTrace`, `clock`, `debug`, `traceback`, `extend`, `isKind`, `getErrorChain`, `concat`, `__tostring`, `packResult`, `Kind`, `ExecutionError`, `makeErrorHandler`, `xpcall`, `runExecutor`, `createAdvancer`, `isEmpty`, `_resolve`, `resolve`, `_reject`, `reject`, `_status`, `Cancelled`, `_cancellationHook`, `onCancel`, `_source`, `_thread`, `_values`, `_valuesLength`, `_unhandledRejection`, `_queuedResolve`, `_queuedReject`, `_queuedFinally`, `_parent`, `_consumers`, `Started`, `create`, `_new`, `_try`, `cancel`, `resolveOne`, `andThen`, `_all`, `number`, `finally`, `allSettled`, `finalize`, `getStatus`, `AlreadyCancelled`, `Rejected`, `await`, `promisify`, `_getTime`, `TimedOut`, `timeout`, `remove`, `Resolved`, `_andThen`, `catch`, `andThenCall`, `andThenReturn`, `close`, `_consumerCancelled`, `_finalize`, `_finally`, `finallyCall`, `finallyReturn`, `running`, `yield`, `awaitStatus`, `awaitHelper`, `expectHelper`, `expect`, `_unwrap`, `_error`, `_timeEvent`, `_unhandledRejectionCallbacks`, `TEST`, `NotResolvedInTime`, `retry`, `retryWithDelay`, `disconnect`, `boolean`, `fromEvent`, `onUnhandledRejection`, `__mode`, `Error`, `GetService`, `prototype`, `async`, `awaitValue`

### `ReplicatedStorage.EmitModule.pkg.Shake` (ModuleScript)

`Amplitude`, `Frequency`, `FadeInTime`, `FadeOutTime`, `SustainTime`, `Sustain`, `PositionInfluence`, `RotationInfluence`, `IsRunning`, `clock`, `TimeFunction`, `_timeOffset`, `_startTime`, `_running`, `_signalConnections`, `_renderBindings`, `InverseSquare`, `format`, `NextRenderName`, `Start`, `UnbindFromRenderStep`, `Stop`, `IsShaking`, `StopSustain`, `noise`, `Update`, `OnSignal`, `GetService`, `__index`

### `ReplicatedStorage.EmitModule.services.caches` (ModuleScript)

`value`, `ForgeMouseIgnore`, `CollisionGroup`, `AssemblyAngularVelocity`, `ClearAllChildren`, `on_free`, `destroy`, `Locked`, `DO_NOT_REMOVE_ForgeSharedPartCache`, `Archivable`, `workspace`, `Terrain`, `protectParent`, `shared_part`

### `ReplicatedStorage.EmitModule.services.effects` (ModuleScript)

`deinit`, `dispatch`, `caches`, `shared_part`, `QueryDescendants`, `shouldSkipNested`, `createEmitPromise`, `queryAndEmitDescendants`, `unlock`, `cleanupScope`, `setup`, `Finished`, `resolve`, `findFirstClassWithTag`, `SHOCKWAVE_TAG`, `FindFirstAncestorOfClass`, `isSpinModelStatic`, `running`, `depth`, `effects`, `screen`, `finally`, `EmitOnFinish`, `prepareEmitOnFinish`, `emitNested`, `emitOnFinish`, `concat`, `BEZIER_TAG`, `format`, `LIGHTNING_TAG`, `RayValue`

### `ReplicatedStorage.EmitModule.services.enabled_effects` (ModuleScript)

`cleanupScope`, `removeEnabledEffect`, `workspace`, `IsDescendantOf`, `AllowEmitting`, `HasTag`, `getAttribute`, `Rate`, `SpeedOverride`, `clock`, `depth`, `effects`, `onEnabled`, `enabled_registry`, `check`, `AncestryChanged`, `addEnabledEffect`, `ENABLED_VFX_TAG`, `GetTagged`, `GetInstanceAddedSignal`, `GetInstanceRemovedSignal`, `GetService`, `CollectionService`

### `ReplicatedStorage.EmitModule.services.texture_loader` (ModuleScript)

`value`, `on_free`, `cleanupScope`, `getMeshDecals`, `PLUGIN_CONTEXT`, `GetTags`, `match`, `format`, `refresh`, `check`, `workspace`, `Terrain`, `IsDescendantOf`, `isMeshVFX`, `Start`, `reboundfn`, `DescendantRemoving`, `loadTextures`, `destroy`, `DO_NOT_REMOVE_ForgeTextureCache`, `Archivable`, `Locked`, `protectParent`, `TEXTURE_LOAD_TAG`, `GetTagged`, `GetInstanceAddedSignal`, `GetInstanceRemovedSignal`, `CollectionService`, `GetService`

### `ReplicatedStorage.GA` (ModuleScript)

`GetFullName`, `waitForDependency`, `GetService`, `IsServer`, `Server`, `ServerAnalytics`, `Client`, `ClientAnalytics`

### `ReplicatedStorage.GA.Client.ClientAnalytics` (ModuleScript)

`GetFullName`, `waitForDependency`, `GAEvent`, `getRemoteEvent`, `remove`, `checkRateLimit`, `clock`, `format`, `eventType`, `properties`, `clientTimestamp`, `FireServer`, `sendEvent`, `_validEventTypes`, `track`, `EventType`, `INTERACTION`, `action`, `target`, `value`, `trackInteraction`, `PROGRESSION`, `status`, `level`, `score`, `trackProgression`, `clone`, `eventName`, `CUSTOM`, `trackCustom`, `IsTenFootInterface`, `Console`, `VREnabled`, `MouseEnabled`, `Mobile`, `KeyboardEnabled`, `Desktop`, `Unknown`, `detectDevice`, `__goatDeviceAck`, `RemoteEvent`, `OnClientEvent`, `__goatDevice`, `reportDevice`, `_init`, `GetService`, `Shared`, `Types`, `__index`

### `ReplicatedStorage.GA.Client.RemoteConfig` (ModuleScript)

`GetFullName`, `waitForDependency`, `getSignal`, `IsConnected`, `finishPending`, `Fire`, `applyDelta`, `changed`, `removed`, `GoatConfigSync`, `GoatConfigFetch`, `RemoteEvent`, `RemoteFunction`, `OnClientEvent`, `InvokeServer`, `clone`, `_connections`, `_fn`, `_init`, `getAll`, `isReady`, `onChanged`, `DisconnectAll`, `shutdown`, `GetService`, `Shared`, `Signal`

### `ReplicatedStorage.GA.Client.SessionManager` (ModuleScript)

`GetFullName`, `waitForDependency`, `GAEvent`, `getRemoteEvent`, `eventType`, `properties`, `clientTimestamp`, `FireServer`, `sendToServer`, `EventType`, `CUSTOM`, `eventName`, `_sdk_afk_return`, `onUserInput`, `_sdk_afk_start`, `DEFAULT`, `SESSION_HEARTBEAT`, `_sdk_heartbeat`, `isAFK`, `start`, `isPlayerAFK`, `GetService`, `Shared`, `Types`, `Config`, `__index`

### `ReplicatedStorage.GA.Server.BatchQueue` (ModuleScript)

`appId`, `_appId`, `apiKey`, `_apiKey`, `endpoint`, `DEFAULT`, `API_ENDPOINT`, `_endpoint`, `batchSize`, `BATCH_SIZE`, `_batchSize`, `flushInterval`, `FLUSH_INTERVAL`, `_flushInterval`, `maxQueueSize`, `MAX_QUEUE_SIZE`, `_maxQueueSize`, `_queue`, `_flushing`, `_flushScheduled`, `_running`, `_closed`, `Accepted`, `Sent`, `Failed`, `Dropped`, `_stats`, `_warnedAt`, `_unwarned`, `_pausedUntil`, `_pauseSeconds`, `clock`, `format`, `_trouble`, `flush`, `start`, `_deadline`, `unsent`, `dropped`, `clone`, `Queued`, `Flushing`, `getStatus`, `userId`, `sessionId`, `events`, `properties`, `eventType`, `eventId`, `timestamp`, `groupEvents`, `Body`, `StatusCode`, `StatusMessage`, `describe`, `Url`, `Method`, `POST`, `Headers`, `authorizationHeader`, `Authorization`, `RequestAsync`, `JSONEncode`, `sdkVersion`, `clientVersion`, `SDK_VERSION`, `encode`, `Success`, `_sendBatch`, `GetService`, `Shared`, `Config`, `__index`

### `ReplicatedStorage.GA.Server.DeviceBootstrap` (LocalScript)

`GoatSdk`, `ObjectValue`, `clock`, `Value`

### `ReplicatedStorage.GA.Server.DeviceBuffer` (ModuleScript)

`_waitSeconds`, `_maxPerPlayer`, `_maxTotal`, `_emit`, `_deviceForUser`, `_readyForUser`, `_pending`, `_resolved`, `_count`, `_closed`, `_timeouts`, `_capacityFlushes`, `waitSeconds`, `maxPerPlayer`, `maxTotal`, `readyForUser`, `properties`, `device`, `Unknown`, `_send`, `_ready`, `flushUser`, `release`, `sessionId`, `events`, `forgetUser`, `DevicePendingEvents`, `DevicePendingPlayers`, `DeviceTimeouts`, `DeviceCapacityFlushes`, `getStatus`, `close`, `__index`, `Mobile`, `Desktop`, `Console`

### `ReplicatedStorage.GA.Server.EconomyTracker` (ModuleScript)

`_init`, `EconomyFlow`, `SOURCE`, `trackEconomy`, `currencyEarned`, `SINK`, `currencySpent`, `BusinessType`, `GAMEPASS`, `trackBusiness`, `gamepassPurchased`, `DEV_PRODUCT`, `devProductPurchased`, `Shared`, `Types`

### `ReplicatedStorage.GA.Server.PlayerTracker` (ModuleScript)

`_beginSession`, `session_start`, `track`, `added`, `getSessionStartedAt`, `UserId`, `_consumeTeleportFlag`, `session_end`, `sessionDuration`, `_fireRealLeave`, `_onPlayerLeaving`, `_init`, `getActivePlayerCount`, `shutdown`, `GetService`

### `ReplicatedStorage.GA.Server.RemoteConfig` (ModuleScript)

`clock`, `format`, `trouble`, `Url`, `Method`, `GET`, `Headers`, `authorizationHeader`, `Authorization`, `RequestAsync`, `Success`, `JSONDecode`, `Body`, `decode`, `StatusCode`, `StatusMessage`, `fetch`, `makeRequest`, `getBaseSignal`, `JSONEncode`, `encodeVal`, `diffKeys`, `fetchedAt`, `refresh`, `GoatConfigRefresh`, `SubscribeAsync`, `UserId`, `_onPlayerLeaving`, `_ensureTracked`, `gameId`, `isApiKey`, `apiKey`, `filterEffectiveConfig`, `JobId`, `endpoint`, `DEFAULT`, `API_ENDPOINT`, `refreshInterval`, `IsServer`, `clientMirror`, `RemoteEvent`, `GoatConfigSync`, `RemoteFunction`, `GoatConfigFetch`, `OnServerInvoke`, `setEnrollmentGate`, `config`, `abAssignments`, `version`, `number`, `Fire`, `_reconcilePlayers`, `getAll`, `getVersion`, `_fetchEffective`, `getForPlayer`, `group`, `excluded`, `control`, `enrolled`, `gated`, `getABGroup`, `concat`, `UrlEncode`, `fetchAssignments`, `GetPlayerByUserId`, `exclude`, `filter`, `effective`, `track`, `signals`, `random`, `reconcile`, `changed`, `removed`, `FireClient`, `onChanged`, `onChangedForPlayer`, `DisconnectAll`, `clone`, `forget`, `getServerAssignments`, `LastFetchAt`, `Version`, `Stopped`, `getStatus`, `peekAssignments`, `peekAssignmentsByUserId`, `shutdown`, `GetService`, `MessagingService`, `Shared`, `Config`, `Signal`, `__index`

### `ReplicatedStorage.GA.Server.ReplayRecorder` (ModuleScript)

`appId`, `_appId`, `adapter`, `_adapter`, `realLeaveSignal`, `_realLeaveSignal`, `sessionIdFn`, `_sessionIdFn`, `deviceFn`, `_deviceFn`, `window`, `DEFAULT`, `REPLAY_WINDOW_SECONDS`, `_window`, `REPLAY_RATE_HZ`, `_rate`, `byteBudget`, `REPLAY_BYTE_BUDGET`, `_byteBudget`, `formatVersion`, `REPLAY_FORMAT_VERSION`, `_formatVersion`, `sampleRate`, `REPLAY_SAMPLE_RATE`, `_sampleRate`, `maxUploadsPerMinute`, `_maxUploadsPerMinute`, `_uploadTimes`, `_uploadsInFlight`, `configVersion`, `_configVersion`, `gameVersion`, `_gameVersion`, `schema`, `_schema`, `maxEvents`, `_maxEvents`, `floor`, `_maxFrames`, `_frameInterval`, `_maxUncompressedBytes`, `apiKey`, `endpoint`, `REPLAY_ENDPOINT`, `_uploader`, `_buffers`, `_running`, `_connections`, `frames`, `events`, `startClock`, `flagged`, `reason`, `clock`, `_open`, `UserId`, `_onRealLeave`, `GetPlayerByUserId`, `captureFrame`, `remove`, `format`, `_realLeaveConn`, `start`, `unflag`, `logEvent`, `upload`, `frameCount`, `flagReason`, `function`, `number`, `clamp`, `random`, `captureHeader`, `session_end`, `encode`, `header`, `maxBytes`, `droppedFrames`, `sessionId`, `userId`, `serverId`, `capturedAtMs`, `device`, `durationMs`, `sessionDurationMs`, `JobId`, `GetService`, `Shared`, `Config`, `ReplayCodec`, `ReplayUploader`, `__index`

### `ReplicatedStorage.GA.Server.ReplayUploader` (ModuleScript)

`appId`, `_appId`, `apiKey`, `_apiKey`, `endpoint`, `_endpoint`, `Url`, `Method`, `POST`, `Headers`, `Body`, `Compress`, `HttpCompression`, `Gzip`, `RequestAsync`, `JSONDecode`, `authorizationHeader`, `Authorization`, `sessionId`, `userId`, `serverId`, `reason`, `capturedAtMs`, `floor`, `durationMs`, `formatVersion`, `device`, `sessionDurationMs`, `configVersion`, `gameVersion`, `Success`, `replay_id`, `replayId`, `StatusCode`, `format`, `network`, `unreachable`, `upload`, `GetService`, `Shared`, `Config`, `__index`

### `ReplicatedStorage.GA.Server.ServerAnalytics` (ModuleScript)

`RemoteConfig`, `getRemoteConfig`, `clock`, `format`, `trouble`, `hookFailed`, `GenerateGUID`, `getSessionId`, `experiments`, `peekAssignmentsByUserId`, `function`, `enrolled`, `group`, `stampExperiments`, `GetPlayerByUserId`, `clone`, `JobId`, `job_id`, `eventType`, `eventId`, `timestamp`, `properties`, `userId`, `sessionId`, `DateTime`, `UnixTimestampMillis`, `device`, `Unknown`, `enqueueEvent`, `__goatDevice`, `client`, `UserId`, `release`, `__goatDeviceAck`, `FireClient`, `start`, `count`, `interaction_event`, `action`, `target`, `value`, `custom_event`, `eventName`, `isAFK`, `validate`, `eventSource`, `onClientEvent`, `GoatSdk`, `ObjectValue`, `Value`, `DeviceBootstrap`, `GAClient`, `installDeviceBootstrap`, `readyForUser`, `appId`, `isApiKey`, `apiKey`, `options`, `RemoteEvent`, `GAEvent`, `endpoint`, `batchSize`, `flushInterval`, `maxQueueSize`, `waitSeconds`, `maxPerPlayer`, `maxTotal`, `OnServerEvent`, `_init`, `DEFAULT`, `SDK_VERSION`, `setEventEnricher`, `setLateEnricher`, `setMetadataGate`, `Player`, `untracked`, `rejected`, `track`, `getStatus`, `Rejected`, `GetJoinData`, `SourceGameId`, `GameId`, `TeleportData`, `_goatSessions`, `match`, `startedAt`, `number`, `_beginSession`, `getSessionStartedAt`, `markTeleporting`, `prepareTeleport`, `clearTeleporting`, `EventType`, `ECONOMY`, `currency`, `amount`, `source`, `itemId`, `trackEconomy`, `PROGRESSION`, `status`, `level`, `score`, `trackProgression`, `BUSINESS`, `businessType`, `productId`, `receiptId`, `trackBusiness`, `_consumeTeleportFlag`, `sessionIdFn`, `deviceFn`, `captureFrame`, `adapter`, `realLeaveSignal`, `window`, `byteBudget`, `sampleRate`, `maxUploadsPerMinute`

### `ReplicatedStorage.GA.Shared.Config` (ModuleScript)

`Secret`, `isApiKey`, `AddPrefix`, `authorizationHeader`, `API_ENDPOINT`, `BATCH_SIZE`, `FLUSH_INTERVAL`, `MAX_QUEUE_SIZE`, `SESSION_HEARTBEAT`, `SDK_VERSION`, `MAX_PROPERTIES`, `MAX_PROPERTY_KEY_LENGTH`, `MAX_PROPERTY_VALUE_LENGTH`, `REPLAY_ENDPOINT`, `REPLAY_WINDOW_SECONDS`, `REPLAY_RATE_HZ`, `REPLAY_BYTE_BUDGET`, `REPLAY_FORMAT_VERSION`, `REPLAY_SAMPLE_RATE`, `DEFAULT`

### `ReplicatedStorage.GA.Shared.EventSchema` (ModuleScript)

`GetFullName`, `waitForDependency`, `number`, `DEFAULT`, `MAX_PROPERTY_VALUE_LENGTH`, `validateTradeItems`, `MAX_PROPERTIES`, `format`, `MAX_PROPERTY_KEY_LENGTH`, `gaveItems`, `receivedItems`, `boolean`, `validateProperties`, `sessionDuration`, `eventName`, `trade_completed`, `tradeId`, `otherUserId`, `simulated`, `received`, `Items`, `Coins`, `ItemCount`, `_validProgressionStatuses`, `status`, `level`, `score`, `_validEconomyFlows`, `currency`, `amount`, `itemId`, `source`, `action`, `target`, `value`, `_validBusinessTypes`, `businessType`, `productId`, `receiptId`, `_validEventTypes`, `EventType`, `CUSTOM`, `validate`, `Types`, `Config`, `rarity`, `SESSION_START`, `SESSION_END`, `PROGRESSION`, `ECONOMY`, `INTERACTION`, `BUSINESS`

### `ReplicatedStorage.GA.Shared.ReplayCodec` (ModuleScript)

`floor`, `quantizeVec3`, `dequantizeVec3`, `quantizeAngle`, `dequantizeAngle`, `JSONEncode`, `encodedLength`, `frames`, `schema`, `header`, `events`, `FORMAT_VERSION`, `maxBytes`, `number`, `frameCount`, `byteSize`, `durationMs`, `droppedFrames`, `encode`, `JSONDecode`, `decode`, `GetService`

### `ReplicatedStorage.GA.Shared.Signal` (ModuleScript)

`_connected`, `_signal`, `_connections`, `remove`, `_fn`, `IsConnected`, `clone`, `Fire`, `DisconnectAll`, `__index`

### `ReplicatedStorage.GA.Shared.Types` (ModuleScript)

`SESSION_START`, `session_start`, `SESSION_END`, `session_end`, `CUSTOM`, `custom_event`, `PROGRESSION`, `progression_event`, `ECONOMY`, `economy_event`, `INTERACTION`, `interaction_event`, `BUSINESS`, `business_event`, `EventType`, `START`, `start`, `COMPLETE`, `complete`, `FAIL`, `ProgressionStatus`, `SOURCE`, `source`, `SINK`, `EconomyFlow`, `GAMEPASS`, `gamepass`, `DEV_PRODUCT`, `dev_product`, `PREMIUM`, `premium`, `BusinessType`, `_validEventTypes`, `_validProgressionStatuses`, `_validEconomyFlows`, `_validBusinessTypes`

### `ReplicatedStorage.SingleAdReward_ServerCode.AdServer` (ModuleScript)

`Load`, `Unload`, `CanClaim`, `GetActiveClaimCount`, `GetLastClaimTime`, `AddEntry`, `GetCache`, `SetClaimCount`, `Log`, `SetBucket`, `Init`, `AssignPlayer`, `UnassignPlayer`, `HasMultiReward`, `IsAssigned`, `GetReward`, `GetAssignedProductId`, `GetBucket`, `debugPrint`, `GetProductInfo`, `getProductName`, `SingleAdRewardEnabled`, `UserId`, `PlacementId`, `ResetInDays`, `ClaimLimit`, `format`, `floor`, `AdResult`, `devProductId`, `placementId`, `completed`, `claimed`, `reason`, `ClaimLimitReached`, `claimsUsed`, `claimsMax`, `windowResetsAt`, `DevProductId`, `FireClient`, `Cooldown`, `SetDevProductId`, `AdStarted`, `ShowRewardedVideoAdAsync`, `AdIncomplete`, `result`, `ShowAdResult`, `ShowCompleted`, `cooldownEndsAt`, `AdComplete`, `ShowAd`, `HudAdReward`, `GetFullName`, `isSystemEnabled`, `ConfigService`, `GetService`, `GetConfigForPlayerAsync`, `AdMultiSystem`, `GetValue`, `configShows`, `RewardAssigned`, `assignedProductId`, `loadAndAssignPlayer`, `eligible`, `secondsLeft`, `RateLimited`, `Bucket`, `LogTelemetry`, `OnServerEvent`, `GetPlacementInfo`, `OnServerInvoke`, `AdService`, `FFlags`, `ServerScriptService`, `GameServices`, `AdGroup`, `SaveData`, `Telemetry`, `RewardSelector`

### `ReplicatedStorage.SingleAdReward_ServerCode.RewardSelector` (ModuleScript)

`gmatch`, `match`, `parseMultiRewardList`, `ConfigService`, `GetService`, `GetConfigForPlayerAsync`, `HUD_Multi_Reward`, `GetValue`, `format`, `boolean`, `checkBucket`, `DevProductId`, `CreateAdRewardFromDevProductId`, `MultiRewardList`, `devProductId`, `reward`, `Init`, `bucket`, `random`, `AssignPlayer`, `HasMultiReward`, `UnassignPlayer`, `IsAssigned`, `GetReward`, `GetAssignedProductId`, `GetBucket`, `AdService`

### `ReplicatedStorage.SingleAdReward_ServerCode.SaveData` (ModuleScript)

`clamp`, `floor`, `utcWindowStart`, `warnLocalOnly`, `retry`, `GetAsync`, `Load`, `timestamp`, `placementId`, `GetActiveClaimCount`, `GetLastClaimTime`, `CanClaim`, `UpdateAsync`, `productName`, `devProductId`, `format`, `AddEntry`, `SetClaimCount`, `GetCache`, `Unload`, `DataStoreService`, `GetService`, `GetDataStore`, `RewardedAdData`

### `ReplicatedStorage.SingleAdReward_ServerCode.Telemetry` (ModuleScript)

`DevProductId`, `_devProductId`, `PlacementId`, `_placementId`, `Bucket`, `_bucket`, `_productPlacementKey`, `LogCustomEvent`, `HUD`, `Log`, `SetBucket`, `SetDevProductId`, `AnalyticsService`, `GetService`, `AnalyticsCustomFieldKeys`, `CustomField01`, `CustomField02`, `CustomField03`, `Boot`, `RegisterOpportunity`, `AdStarted`, `AdComplete`, `AdIncomplete`, `__index`

### `ReplicatedStorage.chrono` (ModuleScript)

`GetAsync`, `JSONDecode`, `tag_name`, `_GetConfig`, `__VERSION`, `format`, `CheckVersion`, `Server`, `Replicate`, `Client`, `_Lock`, `CHECK_NEW_VERSION`, `Start`, `GetService`, `IsServer`, `Shared`, `Config`, `Stats`, `Player`, `Receiver`, `ServerClock`, `Entity`, `Events`, `Holder`, `ReplicationRules`, `Snapshots`, `Types`, `EntityGrid`, `ServerReceiver`

### `ReplicatedStorage.chrono.Client.ClientClock` (ModuleScript)

`buffer`, `GetBuffer`, `tickRate`, `bufferConst`, `lastClockAt`, `lastClockDuration`, `renderAt`, `Clear`, `GetTargetRenderTime`, `clock`, `GetEstimatedServerTime`, `CheckHasLastClockAt`, `Refresh`, `Register`, `OnSnapShot`, `SetTickRate`, `Update`, `UpdateBuffer`, `_baseTickRate`, `_owner`, `UpdateAll`, `IsServer`, `_EntityConfigs`, `CLIENT_CLOCK`, `TICK_RATE`, `_NORMAL`, `BUFFER`, `NORMAL`, `HALF_TICK_DISTANCE`, `_HALF`, `HALF`, `GetService`, `Shared`, `Warn`, `Config`, `Types`, `InterpolationBuffer`, `_WaitForLock`, `_getBuffer`, `clientClocks`, `serverOwnedClocks`

### `ReplicatedStorage.chrono.Client.InterpolationBuffer` (ModuleScript)

`_GetConfig`, `MIN_BUFFER`, `MAX_BUFFER`, `averageLatency`, `deviation`, `lastLatency`, `clientClock`, `GetEstimatedServerTime`, `Clear`, `format`, `Register`, `GetBuffer`, `Shared`, `Warn`, `Config`, `Types`, `_WaitForLock`

### `ReplicatedStorage.chrono.Client.ModelResolver` (ModuleScript)

`format`, `OnInstanceAdded`, `model`, `_modelMetaData`, `SetModel`, `CollectionService`, `GetService`, `Shared`, `Warn`, `Config`, `Types`, `Entity`, `ModelHelper`, `TAG`, `CHRONO_META_NAME`, `GetInstanceAddedSignal`, `GetInstanceRemovedSignal`, `GetTagged`

### `ReplicatedStorage.chrono.Client.Player` (ModuleScript)

`format`, `model`, `workspace`, `CameraSubject`, `QueryDescendants`, `Disabled`, `newModel`, `_GetConfig`, `PLAYER_REPLICATION`, `AUTOMATIC`, `GetModelReplicationType`, `CUSTOM`, `GetEvent`, `ModelChanged`, `isContextOwner`, `FireServer`, `PlayerOwnedAdded`, `GetEntityFromId`, `GetState`, `HumanoidStateType`, `Dead`, `Shared`, `Warn`, `Events`, `Entity`, `Holder`, `Types`, `Config`, `GetService`, `PlayerCharacterRegistered`, `Remotes`, `Death`, `_WaitForLock`, `OnClientEvent`

### `ReplicatedStorage.chrono.Client.Receiver` (ModuleScript)

`UnmapRotation`, `unwrap`, `buffer`, `readu32`, `readu8`, `bit32`, `ReadTickerHeader`, `readf32`, `readu16`, `fromOrientation`, `DeserializeFull`, `DeserializeYaw`, `GetEntityFromId`, `HandleRemoved`, `mountParentId`, `_Signals`, `EntityMountChanged`, `Fire`, `SetMountId`, `identity`, `mountOffset`, `SetMountOffset`, `latestCFrame`, `SetCFrame`, `_modelMetaData`, `model`, `_player`, `SetAsCharacter`, `RemovePlayerCharacter`, `paused`, `PauseReplication`, `ResumeReplication`, `_lockedCFReplication`, `_GetPart`, `_UnlockPartPhysicsReplication`, `SyncOwnerShip`, `CreateModelFromData`, `SetModel`, `HandleChanges`, `_new`, `config`, `cframe`, `isHalfTicked`, `_data`, `broadPhase`, `_interpolationMode`, `Push`, `networkOwner`, `_SetHumanoidDisabledStates`, `_humanoidDisabledStates`, `_SetHumanoidState`, `_humanoidState`, `RegisterEntity`, `HandleNewEntity`, `_teleport`, `clock`, `_clientClock`, `_baseTickRate`, `SetTickRate`, `OnSnapShot`, `entityConfig`, `CLIENT_CLOCK`, `HALF`, `NORMAL`, `PushCFrameFor`, `medium`, `unwrapFor`, `__unknown`, `HandleClientOwned`, `HandleServerOwned`, `HandleUnreliable`, `HandleReliable`, `quantize`, `serverOwnedClocks`, `Refresh`, `player`, `offset`, `number`, `lastRaw`, `_PAUSE`, `BYTES_RECEIVED_PER_SEC`, `NEW_ENTITIES_PER_SEC`, `ENTITY_CHANGES_PER_SEC`, `ENTITY_REMOVALS_PER_SEC`, `GetService`, `Shared`, `Warn`, `Entity`, `Events`, `Holder`, `ModelHelper`, `Types`, `ClockUnwrap`, `Stats`, `CLIENT`, `ClientClock`, `_SetTickMode`, `Remotes`, `Replicate`, `ReplicateFull`, `ClientClockRelay`, `autoUpdatePos`, `SetData`, `SetConfig`, `SetAutoUpdatePos`, `SetBroadPhase`, `SetInterpolationMode`, `OnClientEvent`

### `ReplicatedStorage.chrono.Client.Replicate` (ModuleScript)

`workspace`, `ViewportSize`, `PrepareFrustumCheck`, `vector`, `magnitude`, `CheckPointInFrustum`, `create`, `CheckBroadPhaseInFrustum`, `entityConfig`, `_interpolationMode`, `INTERPOLATION_MODE`, `interpolation`, `CUSTOM_INTERPOLATION`, `NONE`, `ALIGN`, `GetPrimaryPart`, `isContextOwner`, `_alignDriver`, `ASSEMBLY_ROOT_PART_CHECK`, `AssemblyRootPart`, `_outofBroadPhaseTick`, `snapshot`, `medium`, `debug`, `profilebegin`, `GetTargetRenderTime`, `clock`, `GetAt`, `profileend`, `broadPhase`, `lastCheckedCFrame`, `Update`, `Interpolate`, `SERVER`, `_SHOULD_REPLICATE`, `_PAUSE`, `NAME`, `DEFAULT`, `networkOwner`, `_player`, `latestTime`, `lastReplicatedTime`, `_clientClock`, `CLIENT_CLOCK`, `isHalfTicked`, `HALF`, `NORMAL`, `buffer`, `averageLatency`, `deviation`, `_getBuffer`, `cache`, `value`, `velocity`, `entity`, `isCharacter`, `config`, `lastReceivedTime`, `targetTime`, `bufferedTime`, `currentPosition`, `snapshots`, `CLIENT_ENTITIES`, `updateEntityStats`, `TOTAL_ENTITIES_CULLED`, `UpdateAll`, `destroyed`, `paused`, `mountParentId`, `TOTAL_CLIENT_ENTITIES_CHECKED_THIS_FRAME`, `ENTITIES_MOVED_THIS_FRAME`, `TOTAL_CLIENT_ENTITIES`, `AVG_INTERPOLATION_TIME_MS`, `_IncrementGlobalTick`, `FireServer`, `PreSimulation`, `Remotes`, `ClientHeartbeat`, `ClientLoaded`, `Shared`, `GetService`, `Ticker`, `Warn`, `Stats`, `ApplyMounts`, `AlignDriver`, `ClientClock`, `ModelResolver`, `Entity`, `Holder`, `Config`, `Types`, `Sender`, `CLIENT`, `Player`, `Receiver`, `idMap`, `_WaitForLock`

### `ReplicatedStorage.chrono.Client.Sender` (ModuleScript)

`round`, `MapRotation`, `_events`, `Fire`, `FireEvent`, `ToOrientation`, `buffer`, `writef32`, `writeu16`, `SerializeFull`, `SerializeYaw`, `create`, `quantize`, `writeu32`, `FireServer`, `Flush`, `writeu8`, `WriteEntity`, `FuzzyEq`, `CFrameChanged`, `_cfLockFailed`, `_lockedCFReplication`, `isContextOwner`, `_player`, `_GetPart`, `_LockPartPhysicsReplication`, `CheckLocker`, `destroyed`, `paused`, `entityConfig`, `TICK_RATE`, `isHalfTicked`, `lastReplicatedTime`, `Ticked`, `GetPrimaryPart`, `autoUpdatePosition`, `Push`, `latestCFrame`, `lastCheckedCFrame`, `FULL_ROTATION`, `_teleport`, `CheckEntity`, `clock`, `Update`, `GetService`, `Shared`, `Holder`, `Types`, `Entity`, `ClockUnwrap`, `Remotes`, `Replicate`, `SafeReplicate`, `_clientOwned`

### `ReplicatedStorage.chrono.Server.EntityGrid` (ModuleScript)

`GetPrimaryPart`, `latestCFrame`, `destroyed`, `entityConfig`, `HALF_TICK_DISTANCE`, `NORMAL_TICK_DISTANCE`, `networkOwner`, `_lockedCFReplication`, `modelReplicationMode`, `NATIVE`, `PLAYER`, `Allows`, `vector`, `magnitude`, `_TEMP_NORMAL`, `_TEMP_HALF`, `TICKER`, `_ticker`, `isHalfTicked`, `Check`, `debug`, `profilebegin`, `clock`, `profileend`, `running`, `yield`, `SERVER`, `GRID_UPDATE_SECTIONS`, `ENTITY_GRID_UPDATE_TIME_MS`, `NUMBER_OF_ENTITIES`, `ENTITIES_FULL_TICKED`, `ENTITIES_HALF_TICKED`, `NON_TICKED`, `HALF`, `NORMAL`, `GRID_STATS`, `DoLoop`, `_GetConfig`, `GRID_UPDATE_INTERVAL`, `GRID_MAX_UPDATE_TIME`, `Update`, `UpdatePlayerPosition`, `GetEntityHolder`, `REPLICATED`, `EntityAdded`, `EntityRemoving`, `_Signals`, `PlayerLoaded`, `Fire`, `DisconnectAll`, `GetService`, `Shared`, `Events`, `Config`, `ReplicationRules`, `Stats`, `ALL_ENTITIES`, `Types`, `Holder`, `Ticker`, `Entity`, `Signal`, `_SetTickMode`, `idMap`, `IsServer`, `Remotes`, `ClientLoaded`, `OnServerEvent`

### `ReplicatedStorage.chrono.Server.Player` (ModuleScript)

`PLAYER`, `config`, `modelRepMode`, `_EntityConfigs`, `MODEL_REPLICATION_MODE`, `Archivable`, `RigType`, `HumanoidRigType`, `Head`, `SetModelPrimaryForChrono`, `SetAsCharacter`, `SetNetworkOwner`, `RegisterPlayer`, `UnregisterPlayer`, `OnCharacterAdded`, `IsDescendantOf`, `AncestryChanged`, `OnPlayerAdded`, `GetState`, `HumanoidStateType`, `Dead`, `NONE`, `GetEntityFromId`, `networkOwner`, `PLAYER_CHARACTERS`, `_player`, `model`, `FireAllClients`, `IsServer`, `_GetConfig`, `PLAYER_REPLICATION`, `AUTOMATIC`, `Shared`, `Remotes`, `Death`, `REPLICATE_DEATHS`, `OnServerEvent`, `GetService`, `Warn`, `Config`, `Entity`, `Holder`, `Types`, `_playerChars`, `_WaitForLock`

### `ReplicatedStorage.chrono.Server.Receiver` (ModuleScript)

`_GetConfig`, `MAX_TOTAL_BYTES_PER_FRAME_PER_PLAYER`, `debug`, `profilebegin`, `FireMiddleMans`, `profileend`, `UnmapRotation`, `buffer`, `readf32`, `readu16`, `fromOrientation`, `DeserializeFull`, `DeserializeYaw`, `readu8`, `bit32`, `DeserializeEntityPacket`, `_clientOwned`, `CalculateMaxThroughputForPlayer`, `GetEntityFromId`, `networkOwner`, `_teleport`, `GetNetworkPing`, `clock`, `writeu8`, `lastClientClock`, `FLAGS`, `SERVER_VELOCITY_FIX`, `snapshot`, `GetLatest`, `entityConfig`, `TICK_RATE`, `isHalfTicked`, `CalculateVelocity`, `value`, `Push`, `GetGlobalTick`, `arriveFrame`, `cframeBuffer`, `modelReplicationMode`, `NATIVE`, `_lockedCFReplication`, `_SetPartCFrame`, `HandleEntity`, `medium`, `Player`, `unwrapFor`, `readu32`, `Store`, `create`, `OnReceive`, `priority`, `RegisterMiddleMan`, `UnregisterMiddleMan`, `BYTES_RECEIVED_PER_SEC`, `number`, `seatFullFor`, `lastRaw`, `player`, `offset`, `_GetClientClockRaws`, `GetService`, `Shared`, `Ticker`, `InterpolationMath`, `Warn`, `ServerClock`, `Types`, `Holder`, `Entity`, `Config`, `ClockUnwrap`, `Stats`, `SERVER`, `_WaitForLock`, `Remotes`, `Replicate`, `SafeReplicate`, `IsServer`, `OnServerEvent`, `ClientHeartbeat`

### `ReplicatedStorage.chrono.Server.Replicate` (ModuleScript)

`_EntityConfigs`, `TICKER`, `_events`, `Fire`, `FireEvent`, `round`, `MapRotation`, `ToOrientation`, `buffer`, `writef32`, `writeu16`, `SerializeFull`, `SerializeYaw`, `FuzzyEq`, `CFrameChanged`, `autoUpdatePosition`, `isContextOwner`, `model`, `GetPrimaryPart`, `Entity`, `Push`, `PushLatest`, `lastCheckedCFrame`, `latestCFrame`, `CheckForChanges`, `destroyed`, `isHalfTicked`, `paused`, `cframeBuffer`, `Ticked`, `halfdt`, `lastTicked`, `create`, `CheckEntity`, `_Changes`, `_changes`, `CheckEntityChanges`, `debug`, `profilebegin`, `UpdateTickers`, `clock`, `objects`, `config`, `NAME`, `format`, `CheckUpdate`, `FULL_ROTATION`, `tickedHalf`, `profileend`, `AVG_TICKER_TIME_MS`, `_playerChars`, `networkOwner`, `UpdatePlayerPosition`, `UpdatePlayerPositions`, `_SHOULD_REPLICATE`, `SERVER_ENTITIES`, `idMap`, `_player`, `entityConfig`, `DEFAULT`, `TICK_RATE`, `latestTime`, `isPaused`, `isCharacter`, `tickRate`, `lastPosition`, `modelType`, `interpolationMode`, `GetModelReplicationType`, `_interpolationMode`, `INTERPOLATION_MODE`, `CFRAME`, `updateEntityStats`, `GetEntityHolder`, `FireClient`, `UpdateHeartbeat`, `_GetClientClockRaws`, `FireAllClients`, `UpdateClientClockRelay`, `Update`, `ReplicatePlayer`, `_IncrementGlobalTick`, `mountParentId`, `SetCFrame`, `_GetRootPart`, `HandleModel`, `GetEvent`, `ModelChanged`, `LockChanged`, `NetworkOwnerChanged`, `HandleEntity`, `_GetConfig`, `REPLICATE_CFRAME_SETTERS`, `NONE`, `PLAYER_ENTITIES`, `PlayerOwnedAdded`, `PlayerCharacterRegistered`, `PLAYER_CHARACTERS`, `HandleCFrameSetters`, `IsServer`, `_Signals`, `PlayerLoaded`, `PostSimulation`, `GetService`, `Shared`, `ApplyMounts`, `Warn`, `Bin`, `Holder`, `Events`, `Ticker`, `Config`, `Types`, `EntityGrid`, `Player`, `Sender`, `Receiver`, `Stats`, `SERVER`, `Remotes`

### `ReplicatedStorage.chrono.Server.Sender` (ModuleScript)

`lastTicked`, `config`, `FULL_ROTATION`, `quantize`, `buffer`, `writeu32`, `writeu8`, `WriteTickerHeader`, `create`, `FireClient`, `Flush`, `FlushClientOwned`, `FlushEntities`, `destroyed`, `ReadyModelFromRep`, `entityConfig`, `NAME`, `DEFAULT`, `latestCFrame`, `identity`, `lastClientClock`, `isContextOwner`, `GetPrimaryPart`, `clock`, `_player`, `networkOwner`, `cframe`, `model`, `_modelMetaData`, `paused`, `isHalfTicked`, `_data`, `_lockedCFReplication`, `_interpolationMode`, `_humanoidState`, `_humanoidDisabledStates`, `mountParentId`, `mountOffset`, `broadPhase`, `GetEntityFullData`, `arriveFrame`, `cframeBuffer`, `HandleClientEntities`, `Fire`, `_changes`, `_ticker`, `tickedFrame`, `tickedHalf`, `Handle`, `GetEntityHolder`, `debug`, `profilebegin`, `ReplicatePlayer`, `REPLICATED`, `clone`, `EntityAdded`, `EntityRemoving`, `NORMAL`, `HALF`, `GetGlobalTick`, `_lastId`, `profileend`, `REPLICATE_PLAYER_TIME_MS`, `BYTES_SENT_PER_SEC`, `PACKETS_SENT_PER_SEC`, `GetService`, `Shared`, `Ticker`, `Entity`, `EntityGrid`, `Types`, `ModelHelper`, `ClockUnwrap`, `Stats`, `SERVER`, `Remotes`, `Replicate`, `ReplicateFull`

### `ReplicatedStorage.chrono.Server.ServerClock` (ModuleScript)

`clockOffset`, `oneWayDelay`, `workspace`, `GetNetworkPing`, `clock`, `clamp`, `Store`, `Server`, `ConvertTo`, `GetService`

### `ReplicatedStorage.chrono.Shared.AlignDriver` (ModuleScript)

`__CHRONO_ALIGN`, `Archivable`, `__CHRONO_ALIGN_PART`, `CustomPhysicalProperties`, `Massless`, `RootPriority`, `__CHRONO_ALIGN_WELD`, `Part0`, `Part1`, `__CHRONO_ALIGN_ATTACHMENT`, `AlignPosition`, `PositionAlignmentMode`, `OneAttachment`, `Mode`, `Attachment0`, `ApplyAtCenterOfMass`, `ReactionForceEnabled`, `ActuatorRelativeTo`, `World`, `ForceRelativeTo`, `ForceLimitMode`, `MaxForce`, `MaxVelocity`, `Responsiveness`, `RigidityEnabled`, `AlignOrientation`, `OrientationAlignmentMode`, `AlignType`, `AllAxes`, `PrimaryAxisOnly`, `ReactionTorqueEnabled`, `MaxTorque`, `MaxAngularVelocity`, `container`, `driverPart`, `alignPosition`, `alignOrientation`, `Update`, `GetService`, `IsServer`

### `ReplicatedStorage.chrono.Shared.ApplyMounts` (ModuleScript)

`_GetRootPart`, `isContextOwner`, `AssemblyAngularVelocity`, `SetCFrame`, `identity`, `GetAt`, `GetTargetRenderTime`, `latestCFrame`, `mountParentId`, `GetPrimaryPart`, `GetEntityFromId`, `destroyed`, `mountOffset`, `ResolveWorldCFrame`, `debug`, `profilebegin`, `ApplyMounts`, `profileend`, `Entity`, `Events`, `Holder`, `Types`, `EntityAdded`, `EntityMountChanged`, `EntityRemoved`

### `ReplicatedStorage.chrono.Shared.Bin` (ModuleScript)

`RBXScriptConnection`, `function`, `thread`, `cancel`, `_binCleanup`

### `ReplicatedStorage.chrono.Shared.ClockUnwrap` (ModuleScript)

`floor`, `quantize`, `lastRaw`, `offset`, `unwrap`, `unwrapFor`, `seatFull`, `seatFullFor`, `SCALE`, `WRAP`

### `ReplicatedStorage.chrono.Shared.Config` (ModuleScript)

`RegisterEntityType`, `RegisterEntityModel`, `DEFAULT`, `GetEntityType`, `format`, `GetEntityModel`, `GetBroadPhase`, `GetConfig`, `WaitForLock`, `NONE`, `LOW`, `MEDIUM`, `HIGH`, `WARNING_SEVERITY`, `SetWarningSeverity`, `CLIENT_CLOCK`, `NAME`, `BUFFER`, `NORMAL`, `UpdateBuffer`, `HALF`, `Holder`, `Entity`, `idMap`, `entityConfig`, `_UpdateClockBuffer`, `Warn`, `DEFAULT_NORMAL_TICK_DISTANCE`, `DEFAULT_HALF_TICK_DISTANCE`, `clone`, `AUTO_UPDATE_POSITION`, `FULL_ROTATION`, `NORMAL_TICK_DISTANCE`, `HALF_TICK_DISTANCE`, `MODEL_REPLICATION_MODE`, `DEFAULT_MODEL_REPLICATION_MODE`, `INTERPOLATION_MODE`, `DEFAULT_INTERPOLATION_MODE`, `Ticker`, `TICKER`, `Lock`, `__CHRONO_PRIMARY`, `SetModelPrimaryForChrono`, `Types`, `GetService`, `IsServer`, `__VERSION`, `CHECK_NEW_VERSION`, `MAX_TOTAL_BYTES_PER_FRAME_PER_PLAYER`, `MIN_BUFFER`, `MAX_BUFFER`, `GRID_UPDATE_INTERVAL`, `GRID_MAX_UPDATE_TIME`, `REPLICATE_DEATHS`, `PLAYER_CHARACTERS`, `REPLICATE_CFRAME_SETTERS`, `PLAYER_ENTITIES`, `PLAYER_REPLICATION`, `AUTOMATIC`, `CFRAME`, `NATIVE`, `MAX_SNAPSHOT_COUNT`, `WITH_ROT`, `PLAYER`, `TICK_RATE`, `ASSEMBLY_ROOT_PART_CHECK`, `SetConfig`, `FLAGS`, `_EntityConfigs`, `_GetEntityType`, `_GetEntityModel`, `_GetConfig`, `_Lock`, `_WaitForLock`, `_GetBroadPhase`, `_Base_Config`, `SERVER_VELOCITY_FIX`, `VELOCITY_CALC_FIX`, `SNAPSHOT_INTERPOLATION_FIX`, `SET_CFRAME_FIX`, `FIX_TELEPORT_JITTER`

### `ReplicatedStorage.chrono.Shared.Entity` (ModuleScript)

`SafeDestroy`, `SetNetworkOwner`, `SafeSetNetworkOwner`, `model`, `_chronoPrimary`, `GetFullName`, `format`, `GetPart`, `GetPrimaryPart`, `_lockedCFReplication`, `__CHRONO_LOCKER`, `GetRootPart`, `__CHRONO_WELD`, `Part1`, `Part0`, `Archivable`, `CustomPhysicalProperties`, `__CHRONO_LOCKER_PART`, `Massless`, `RootPriority`, `LockCFReplication`, `SetPartCFrame`, `UnlockCFReplication`, `SetValue`, `_events`, `Fire`, `FireEvent`, `_clientClock`, `_clockBuffer`, `entityConfig`, `BUFFER`, `networkOwner`, `TICK_RATE`, `SERVER`, `SetClock`, `isContextOwner`, `latestTime`, `lastClientClock`, `STORE_SNAPSHOTS`, `snapshot`, `Hermite`, `_cfLockFailed`, `_player`, `Clear`, `NetworkOwnerChanged`, `_Signals`, `PlayerOwnedRemoved`, `PlayerOwnedAdded`, `CheckNetworkOwner`, `SyncOwnerShip`, `modelReplicationMode`, `MODEL_REPLICATION_MODE`, `upper`, `NATIVE`, `CUSTOM`, `NATIVE_WITH_LOCK`, `medium`, `CheckModelReplicationMode`, `_GetEntityModel`, `workspace`, `_GetBroadPhase`, `modelString`, `broadPhase`, `GetEntityStorageInstance`, `__CHRONO_PRIMARY`, `latestCFrame`, `SetCFrame`, `GetModelReplicationType`, `SetModel`, `_GetEntityType`, `DEFAULT`, `registered`, `autoUpdatePosition`, `paused`, `destroyed`, `interpolation`, `AUTO_UPDATE_POSITION`, `_new`, `RegisterEntity`, `ReadyModelFromRep`, `_modelMetaData`, `ModelChanged`, `GetEvent`, `NAME`, `SetConfig`, `SetClockBuffer`, `SetBroadPhase`, `_data`, `GetData`, `GetModel`, `DataChanged`, `SetData`, `isHalfTicked`, `TickChanged`, `NONE`, `HALF`, `NORMAL`, `_SetTickMode`, `mountParentId`, `mountOffset`, `EntityMountChanged`, `ClearMount`, `SetMount`, `lastCheckedCFrame`, `PauseReplication`, `ResumeReplication`, `GetLatest`, `GetTargetRenderTime`, `PushWithCheck`, `PushedSnapShot`, `Push`, `GetAt`, `CLIENT_CLOCK`, `autoUpdatePos`, `SetAutoUpdatePos`, `GetCFrame`, `FLAGS`, `SET_CFRAME_FIX`, `clock`, `_teleport`

### `ReplicatedStorage.chrono.Shared.Events` (ModuleScript)

`Types`, `Signal`, `EntityAdded`, `EntityRemoved`, `PlayerCharacterRegistered`, `PlayerCharacterUnregistered`, `PlayerOwnedAdded`, `PlayerOwnedRemoved`, `EntityMountChanged`, `PlayerLoaded`, `_Signals`

### `ReplicatedStorage.chrono.Shared.Holder` (ModuleScript)

`remove`, `GetNextId`, `ReleaseId`, `_player`, `Fire`, `PlayerCharacterUnregistered`, `RemovePlayerCharacter`, `PlayerCharacterRegistered`, `SetAsCharacter`, `destroyed`, `medium`, `format`, `registered`, `overwriting`, `EntityAdded`, `RegisterEntity`, `EntityRemoved`, `ignoring`, `_lastId`, `UnregisterEntity`, `model`, `GetEntityFromModel`, `GetEntityFromPlayer`, `GetEntityFromId`, `workspace`, `Chrono_EntityStorage`, `getEntityStorageInstance`, `Types`, `Warn`, `Events`, `_Signals`, `GetService`, `IsServer`, `idMap`, `_clientOwned`, `_playerChars`, `GetEntityStorageInstance`

### `ReplicatedStorage.chrono.Shared.InterpolationMath` (ModuleScript)

`Hermite`, `FLAGS`, `SNAPSHOT_INTERPOLATION_FIX`, `VELOCITY_CALC_FIX`, `CalculateVelocity`, `value`, `VelocityAt`, `Types`, `Config`

### `ReplicatedStorage.chrono.Shared.ModelHelper` (ModuleScript)

`model`, `modelString`, `NATIVE`, `modelReplicationMode`, `entityConfig`, `ATTACH_MODEL_META_DATA`, `__CHRONO_MODEL_META_INSTANCE`, `Configuration`, `Archivable`, `__CHRONO_MODEL_META_ID`, `CHRONO_`, `CHRONO_MODEL_REPLICATOR`, `AddTag`, `CUSTOM`, `Shared`, `_CUSTOM_MODEL_REP`, `_ChronoClientModels`, `medium`, `format`, `ReadyModelFromRep`, `TempModel`, `workspace`, `CreateTempModel`, `GetEntityStorageInstance`, `CreateModelFromData`, `Warn`, `Holder`, `Config`, `Types`, `TAG`, `CHRONO_META_NAME`

### `ReplicatedStorage.chrono.Shared.ReplicationRules` (ModuleScript)

`number`, `Player`, `GetEntityFromPlayer`, `GetEntityFromModel`, `GetIdFrom`, `filterType`, `filterPlayers`, `exclude`, `CompileRule`, `function`, `SetReplicationRule`, `Allows`, `include`, `Include`, `Exclude`, `Shared`, `Warn`, `Types`, `Holder`

### `ReplicatedStorage.chrono.Shared.Signal` (ModuleScript)

`acquireRunnerThreadAndCallEventHandler`, `yield`, `runEventHandlerInFreeThread`, `_type_`, `Connection`, `Connected`, `_signal`, `_fn`, `_next`, `_defer`, `_binCleanup`, `_handlerListHead`, `format`, `__index`, `__newindex`, `running`, `Signal`, `DisconnectAll`, `debug`, `profilebegin`, `create`, `resume`, `profileend`, `Fire`

### `ReplicatedStorage.chrono.Shared.Snapshots` (ModuleScript)

`_GetConfig`, `MAX_SNAPSHOT_COUNT`, `GetBufferIndex`, `count`, `cache`, `BinarySearchInsertionPoint`, `ShiftElementsRight`, `GetLatest`, `value`, `velocity`, `Push`, `FLAGS`, `SNAPSHOT_INTERPOLATION_FIX`, `PushWithCheck`, `lockedTime`, `GetAt`, `Clear`, `create`, `New`, `Types`, `Config`, `Warn`, `_WaitForLock`

### `ReplicatedStorage.chrono.Shared.Stats` (ModuleScript)

`processID`, `Player`, `UserId`, `HasPermissionToReplicate`, `IsClient`, `REPLICATE_PERMISSIONS`, `ReplicateStatsForPlayer`, `StopReplicatingStatsForPlayer`, `WARNING_SEVERITY`, `SetWarningSeverity`, `FFLAG`, `FLAGS`, `updateStat`, `REPLICATE_SERVER_STATS`, `SERVER`, `FireClient`, `_SHOULD_REPLICATE`, `DEBUGGER_OPENED`, `UPDATE_STAT`, `FireAllClients`, `CLIENT_STATS_ACTION`, `GetEntityFromId`, `CHANGE_NATIVE`, `GetModelReplicationType`, `NATIVE`, `LockNativeServerCFrameReplication`, `NATIVE_WITH_LOCK`, `UnlockNativeServerCFrameReplication`, `TOGGLE_PAUSE`, `paused`, `ResumeReplication`, `PauseReplication`, `CHANGE_CONFIG`, `SetConfig`, `SET_INTERPOLATION_MODE`, `SetInterpolationMode`, `CLIENT`, `_PAUSE`, `handleServerEvent`, `FireServer`, `GetService`, `Config`, `Entity`, `Holder`, `Types`, `TOTAL_ENTITIES_CULLED`, `ENTITIES_MOVED_THIS_FRAME`, `TOTAL_CLIENT_ENTITIES_CHECKED_THIS_FRAME`, `TOTAL_CLIENT_ENTITIES`, `AVG_INTERPOLATION_TIME_MS`, `BYTES_RECEIVED_PER_SEC`, `NEW_ENTITIES_PER_SEC`, `ENTITY_CHANGES_PER_SEC`, `ENTITY_REMOVALS_PER_SEC`, `CLIENT_ENTITIES`, `AVG_TICKER_TIME_MS`, `ENTITY_GRID_UPDATE_TIME_MS`, `GRID_UPDATE_SECTIONS`, `NUMBER_OF_ENTITIES`, `NON_TICKED`, `ENTITIES_FULL_TICKED`, `ENTITIES_HALF_TICKED`, `REPLICATE_PLAYER_TIME_MS`, `BYTES_SENT_PER_SEC`, `PACKETS_SENT_PER_SEC`, `SERVER_ENTITIES`, `GRID_STATS`, `IsServer`, `RemoteEvent`, `Stats`, `OnServerEvent`, `OnClientEvent`, `_openedDebugger`, `_closedDebugger`, `_updateStat`, `_fireClientStatsEvent`

### `ReplicatedStorage.chrono.Shared.Ticker` (ModuleScript)

`_tickerIndex`, `popSwap`, `_IncrementGlobalTick`, `GetGlobalTick`, `tickedHalf`, `tickHalfRate`, `tickRate`, `lastTicked`, `tickedFrame`, `objects`, `callbacks`, `config`, `halfdt`, `TICK_RATE`, `AddCallback`, `remove`, `RemoveCallback`, `_ticker`, `Add`, `clock`, `CheckUpdate`, `GetService`, `Types`, `Warn`

### `ReplicatedStorage.chrono.Shared.Warn` (ModuleScript)

`NONE`, `LOW`, `MEDIUM`, `HIGH`, `_GetConfig`, `WARNING_SEVERITY`, `checkLevel`, `upper`, `__index`, `Config`

### `StarterPlayer.StarterCharacterScripts.CharacterAnimationClient` (LocalScript)

`Stop`, `FadeOut`, `AnimationAction`, `endAction`, `ready`, `clock`, `FadeIn`, `Length`, `startAction`, `release`, `destroy`, `AnimationPackActive`, `AnimationPackLoading`, `cleanup`, `refresh`, `coreReady`, `GameRole`, `FloorMaterial`, `Air`, `Idle`, `MovementState`, `MovementLocked`, `TackleActive`, `Caught`, `MovementReset`, `DashAnimationSequence`, `PlatformStand`, `Dash`, `Boosting`, `Dashing`, `DashFromDirection`, `DashToDirection`, `isActive`, `angle`, `speed`, `entrySpeed`, `allowed`, `clipLength`, `MovementStopEntrySpeed`, `Ragdolled`, `CaughtIdle`, `Fall`, `weights`, `MaxSpeed`, `Land`, `duration`, `clipEnd`, `weight`, `Braking`, `RunBlendStart`, `RunBlendEnd`, `clamp`, `WalkReferenceSpeed`, `RunReferenceSpeed`, `Run`, `length`, `FadeTime`, `PlaybackRate`, `Walk`, `DirectionalReferenceSpeed`, `IsPlaying`, `WeightTarget`, `AdjustWeight`, `Speed`, `AdjustSpeed`, `GetService`, `RigType`, `HumanoidRigType`, `FFlags`, `LocalLocomotion`, `Animate`, `Animator`, `GetPlayingAnimationTracks`, `Priority`, `AnimationPriority`, `Core`, `ChickenOrHero`, `Animation`, `AnimationConfig`, `AnimationPolicy`, `StopAnimationPolicy`, `DashAnimation`, `DashAnimationPolicy`, `Movement`, `MovementProfiles`, `AnimationLibrary`, `prepare`, `LocomotionTracks`, `tracks`, `PreAnimation`

### `StarterPlayer.StarterCharacterScripts.CharacterMovementClient` (LocalScript)

`MoveDirection`, `InputDeadzone`, `redirects`, `turning`, `cancel`, `UnbindFromRenderStep`, `HumanoidStateType`, `Jumping`, `SetStateEnabled`, `cleanup`, `clock`, `adrenaline`, `Adrenaline`, `ownerId`, `UserId`, `GearBoost`, `MovementBlockReason`, `MovementBlockSince`, `workspace`, `blockReason`, `forActor`, `GetService`, `WarHorn`, `current`, `AimAngle`, `FadeAngle`, `clamp`, `MaxSpeed`, `SpeedBonus`, `hornPace`, `consume`, `GameRole`, `dashRemaining`, `recoveryRemaining`, `armed`, `carryRemaining`, `speed`, `DashReady`, `SpeedCut`, `SpeedCutFactor`, `outputSpeed`, `MovementReset`, `suspend`, `carry`, `rocket`, `rocketActive`, `Carry`, `Boost`, `GearMotion`, `isActive`, `TackleActive`, `Tackle`, `GetState`, `MovementLocked`, `MovementLockReason`, `Match`, `movementReason`, `PlatformStand`, `Swimming`, `Climbing`, `Physics`, `Burrowing`, `Freefall`, `FallingDown`, `Running`, `ChangeState`, `RigType`, `HumanoidRigType`, `direction`, `speedMultiplier`, `HornBoost`, `Burst`, `BurstSeconds`, `FloorMaterial`, `Air`, `Braking`, `MovementStopEntrySpeed`, `FacingPaceMultiplier`, `outputDirection`, `Dashing`, `Boosting`, `Locked`, `DashFromDirection`, `dashFromDirection`, `DashToDirection`, `dashDirection`, `DashAnimationSequence`, `dashCount`, `FireServer`, `BoostRecoveryUntil`, `MovementState`, `MovementSpeed`, `DashCount`, `canBoost`, `DashCooldown`, `cooldown`, `DashCooldownUntil`, `LastDashDistance`, `lastDashDistance`, `LastDashEntrySpeed`, `lastDashEntrySpeed`, `ChickenOrHero`, `Movement`, `MovementProfiles`, `Presentation`, `BoostRequest`, `MovementModel`, `BodyFacingModel`, `BodyFacingConfig`, `BoostInput`, `ControlGate`, `Game`, `TacklePrediction`, `Gear`, `GearPredictionClient`, `StepOverMotion`, `CannonMotion`, `GearCatalog`, `ChickenOrHeroMovement_`, `GenerateGUID`

### `StarterPlayer.StarterCharacterScripts.NoDeathClient` (LocalScript)

`BreakJointsOnDeath`, `HumanoidStateType`, `Dead`, `SetStateEnabled`

