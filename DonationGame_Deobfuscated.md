# Donation Game (PlaceId 76653273729321) — deobfuscated

Recovered from a whole-game bytecode dump (1358 compiled scripts). This is a
**PLS-DONATE-style game**: players set up booths/stands and donate **real
Robux** to each other through actual gamepass/product purchases, alongside an
in-game soft currency (**Giftbux**) and a quest/reward loop.

## Method

Scripts are Luau bytecode (no source, no decompiler here). This recovers each
chunk's constant/string pool to reconstruct the remote registry and the
quest/coin/economy flow. Remote argument shapes aren't in a constant pool, so
calls that take args are best-effort.

## Remotes — `ReplicatedStorage.Remotes`

| Remote | Purpose |
| --- | --- |
| `AcceptQuest` | start a quest |
| `CollectCoin` / `coinCollect` | collect one quest coin (client fires on pickup; server validates) |
| `ClaimQuest` | claim a finished quest's reward (robux or giftbux, per quest) |
| `ClaimReward` | claim playtime / login rewards |
| `ClaimBooth` | claim a free booth |
| `GiveGiftbux` | gift the in-game Giftbux currency |
| `ClientGifting` → `StartTransferDonation(recipientId, amount, message)` | **real-Robux donation** — initiates a real purchase; **not wired** |

Quest coins are `Coin_*` parts (under a `QuestCoins` folder) that each carry a
`ProximityPrompt`; collecting one fires `CollectCoin`. The server gates it
("blocked request from server, did not claim", "coin rejected"), so collecting
can't be forged — only automated.

## Real Robux vs. in-game currency

- **Robux** here is the player's real Roblox balance. `RobuxBalance` /
  `NewRobuxBalance` are read-only displays of it; donations move real Robux
  only through Roblox's purchase flow. Nothing client-side can mint it.
- **`FakeRobuxShop`, `RobuxEvent` (raining robux), `RobuxParticles`,
  `FakeRobuxNuke`** are cosmetic/visual only — they change no balance. Their
  effect is to make other players *believe* a donation happened.
- **Giftbux** is the real in-game soft currency and is safe to farm.

## What Nexus wires (Donate: Quests tab)

Self-affecting automation only:

- **Auto Quest** — accept (`AcceptQuest` + QuestGiver prompt), fire every quest
  coin's ProximityPrompt so the game collects them, then `ClaimQuest`.
- **Auto Collect Coins** — fire all coin prompts.
- **Claim All Rewards** — `ClaimReward` / `ClaimBooth`.
- A remote runner for anything else under `ReplicatedStorage.Remotes`.

**Deliberately excluded:** `ClientGifting` / `StartTransferDonation`
(real-Robux donations — can't be given for free) and every fake-robux effect
(they move no balance and exist only to mislead other real players).
