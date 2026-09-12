# Ouroboros Hub — `stealanegg.lua` — Deobfuscation Report

**Source:** `https://raw.githubusercontent.com/joustingmatch/Ouroboros/refs/heads/main/games/stealanegg.lua`
**Size:** 516,176 bytes, emitted as a **single line**.
**Target game:** *Steal an Egg* (a "Steal a Brainrot"‑style Roblox game).
**What it is:** A full‑featured cheat / automation "hub" for that game, wrapped in a
custom Luau control‑flow‑flattening obfuscator.

> Scope note: this is a ~0.5 MB VM/CFG‑flattened Luau program. A byte‑exact
> recompile of every one of its 352 embedded functions back to original source is
> not something that can be done reliably by hand. It is also **not necessary** —
> this particular obfuscator left *every identifier, method name, feature label and
> string literal in cleartext* inside its constant table, so the program's complete
> behavior is fully recoverable. This report reconstructs that behavior, documents
> the obfuscation scheme, and hand‑decodes representative functions. See
> `StealAnEgg_constants.txt` for the raw recovered literal pool and
> `StealAnEgg_reconstructed.lua` for a readable behavioral reconstruction.

---

## 1. Obfuscation scheme

The file is protected by a **string‑array + control‑flow‑flattening** obfuscator
(the same family as the other `*_VM_Deobfuscated` samples in this repo, not a full
bytecode VM). Four techniques are stacked:

### 1.1 Constant pool indirection (`acj`)
The script opens with ~92 forward‑declared `local` "register" variables
(`acj`, `Et`, `FS`, `ES`, `Fz`, `Ez`, `Fg`, …) and then builds one giant constant
table:

```lua
acj = { 2785, "MAX_INVENTORY", 2521, 2991364221., function() ... end, 499005.,
        "EspCarriedEggs", 1141, "AutoExecute", "BackgroundColor3", 473, ... }
```

Every literal used anywhere in the program is referenced **indirectly** as
`acj[N]` (4,148 such references). The table mixes three kinds of entries:

* **Real constants** — numbers, and *cleartext* strings (method names, UI labels,
  service names, URLs). These were never encrypted, which is the whole reason the
  program is trivially readable once the pool is dumped.
* **Booleans as integers** — `acj[818]` = `0`, `acj[893]` = `1`. They appear both
  as numeric literals and as the `0/1` operands of the opaque predicates below.
* **Small integers reused as state labels** — the same table doubles as the label
  bank for the flattened control flow.

### 1.2 Helper‑function registry (`Fw` and friends)
Helper functions are not called by name; they live in dispatch tables keyed by the
cleartext strings in the pool. The dominant one is `Fw`:

```lua
Fw[acj[1521]]()          -- Fw["getAreaEggs"]()   (acj[1521] = "getAreaEggs")
Fw[acj[1062.]](x)        -- a typeof/validity helper
acj[2108](Fw[acj[465.]]) -- pcall(Fw["runAuto…"])  ← the runner-dispatch pattern
```

> **Constant pool fully resolved.** The `acj` table splits cleanly into **2,149
> entries** (1,246 strings, 685 numbers, 182 functions, 36 inline exprs). Sample
> resolutions: `acj[818]=0`, `acj[893]=1`, `acj[622]=16777213` (2²⁴−3, the
> opaque-predicate modulus), `acj[2108]=pcall`, `acj[1804]="clock"` (→
> `os.clock()`), `acj[1521]="getAreaEggs"`. The complete de-indirected program —
> every constant substituted back, helpers reading as `Fw["realName"](...)` — is
> in `stealanegg.deindirected.lua`.

This is why the constant pool literally lists the program's entire API surface:
`runAutoSteal`, `pickStealTarget`, `runAutoSellPets`, `runAutoFusePets`,
`sendWebhookEmbed`, `buildSummaryEmbed`, `serverHop`, `netCall`, `netInvoke`,
`getSave`, `collectEggEsp`, … (full list in the constants file).

### 1.3 Control‑flow flattening (338 dispatch loops)
Every function body was rewritten into a `while true do` state machine. Each basic
block ends by assigning the **next** state number; a binary‑search `if/elseif` tree
picks the block to run. The ordering is scrambled with a `state = BIGNUM - state`
folding step, and Luau `continue`/`break` implement jumps/returns:

```lua
local Yo = 3.
while true do
  Yo = 3573. - Yo                 -- fold: hides the real successor numbering
  if Yo < 3573. then
    if Yo < 3568 then ...
    elseif Yo == 3569 then  <block>; Yo = 7
    ...
  end
end
```

There are 338 such loops (many nested — the auto‑task runners contain a second,
inner flattened loop). `continue` (1,395 uses) restarts the dispatch; `break`
leaves the function.

### 1.4 Opaque predicates (branchless boolean re‑derivation)
Real branches are hidden behind arithmetic that recomputes the same boolean.
The recurring shape is:

```lua
J4 = if cond then acj[893] else acj[818]          -- J4 = cond ? 1 : 0
J2 = C1*J4 + C2*(1-J4)                             -- select C1/C2 on cond
J3 = C3*J4 + C4*(1-J4)                             -- select C3/C4 on cond
next = if (J2*C5 + J3*C6 + J2*J3) % acj[622] == K  -- constant‑folds to `cond`
         then <stateA> else <stateB>
```

Because `J2` and `J3` each take only one of two constant values, the modular
expression collapses to one of two constants, so the comparison is just an
obfuscated restatement of the original `cond`. There are 51 of these. They carry
no logic — they exist purely to defeat static analysis and can be replaced by the
underlying `if cond` when reading.

**Net effect:** strip the four layers and each function is ordinary Luau. Nothing
here is cryptographically strong; it is anti‑readability, not anti‑analysis.

---

## 2. What the script actually does

It is the **"Ouroboros Hub" cheat menu for *Steal an Egg*.** On execute it pulls a
UI library (an *Obsidian*/Linoria fork) from GitHub, builds a tabbed menu, and runs
a set of always‑on background loops driven by `task.spawn` over the `runAuto*`
helpers. Feature groups, taken directly from the recovered labels:

### 2.1 Egg stealing & automation (the core)
* **Auto Steal Egg / Auto Steal All / Steal Big Eggs** — `runAutoSteal`,
  `pickStealTarget`, `isStealCandidate`, `tryCarryEgg`, `stealEgg`. Fires the game
  remotes `RequestCarryAreaEgg`, `RequestDropHeldAreaEgg`, `RequestPlaceEgg`.
* **Priority/target system** — `StealPriority`, `PrioritySlot1..4`, `pickStealTarget`,
  filters by rarity/mutation/size (`StealBigEggScale`, `matchesEggFilters`,
  `matchesMutationFilter`).
* **Placement / return** — `runAutoPlaceEggs`, `Auto Place All/Selected`,
  `runAutoReturn` / `returnToBase`, waypoint pathing (`buildLaneWaypoints`,
  `travelAlong`, `clampToCorridor`, `getZoneLaneCenter`).
* **Inventory guards** — `MAX_INVENTORY`, `eggInventoryFull`,
  `stealBlockedByInventory`, `getUnplacedEggUids`.
* **Hatching** — `runAutoOpenReadyEggs` / `RequestHatchEgg` /
  `RequestCompleteHatchEgg`, `Auto Hatch Ready`, `FuseAutoReveal`.

### 2.2 Pets / economy automation
* **Auto Sell** eggs & pets (`runAutoSellPets`, `SELL_ASSET`, rarity/mutation/scale
  filters, "Never Sell Equipped/Mutated").
* **Auto Fuse pets** (`runAutoFusePets`, `START_FUSE`, `CalculateFusePrice`,
  `pickFuseGroup`, keep‑equipped/mutated/per‑category rules).
* **Auto Equip Best** pets / gear / trail (`runAutoEquipBest*`, `EQUIP_BEST`,
  `REQUEST_EQUIP_STATIC`).
* **Auto Buy** trail & upgrades (`runAutoBuyTrail`, `runAutoUpgrades`,
  `REQUEST_PURCHASE`, `REQUEST_UPGRADE`, `REQUEST_BASE_UPGRADE`).
* **Claim** offline earnings & group rewards (`runClaimOfflineEarnings`,
  `runAutoClaimGroupReward`, `REQUEST_CLAIM_ALL`, `REQUEST_REDEEM`).
* **Treadmill training** (`runAutoTreadmillTraining`, `mountTreadmill`/`dismount`).

### 2.3 ESP / visuals
`runEsp` with per‑category collectors: eggs (world/carried/dropped), pets, guards,
machines, plots, players (`collectEggEsp`, `collectGuardEsp`, `collectPetEsp`, …),
drawn via `BillboardGui` + `Highlight` (`drawEspAt`, `espColorFor`,
`withinEspRange`, `EspDistance`). Includes **guard ESP**, distance labels, and a
rarity color map.

### 2.4 Movement / rendering exploits
Fly, NoClip, Infinite Jump, WalkSpeed / JumpPower overrides, Anti‑AFK
(`VirtualUser`/`VirtualInputManager` tap), FPS boost / "Disable 3D Rendering"
(`set_fps_cap`, `enableFpsBoost`, `DisableRendering`), and an **Anti‑Gameplay‑Pause**
(`applyAntiGameplayPause`, `RobloxNetworkPauseNotification`).

### 2.5 Server hopping / rejoin
`runServerHop` / `serverHop` / `fetchServerPage` query the public Roblox web API

```
https://games.roblox.com/v1/games/%d/servers/Public?sortOrder=Asc&excludeFullGames=true&limit=100
```

then `TeleportService` + `queue_on_teleport` to relaunch the script in the next
server. Hop triggers: *No Matching Eggs*, *Timed Interval*, or *After Steal Count*.
Also **Auto Reconnect** on disconnect (`handleDisconnect`, `rejoinServer`,
`TeleportInitFailed`).

### 2.6 Config import/export
Exports the settings table to the clipboard (`buildConfigPayload`,
`encodeConfigObject`, base64/JSON) and imports it back — plus a `SaveManager` /
`ThemeManager` from the UI library.

---

## 3. Network activity — read this before running it

The script makes outbound HTTP and can transmit data off the client. Three
distinct channels:

### 3.1 Self‑fetch / self‑update (loader)
Contains its own raw URL and a `loadstring(game:HttpGet(...))` — the "Copy join
script" feature and re‑execution path point back at
`…/joustingmatch/Ouroboros/main/games/stealanegg.lua`, and the UI library is pulled
live from `…/joustingmatch/ObsidianUltra/main/`. Running the script therefore
**executes whatever is at those URLs at run time**, not just the bytes you fetched.

### 3.2 Discord webhook telemetry (data exfiltration channel)
A full webhook subsystem (`sendWebhookEmbed`, `buildSummaryEmbed`,
`runWebhookSummary`, `trackWebhookEvents`, `httpPost`) POSTs Discord embeds to a
**user‑supplied** webhook URL (`WebhookUrl`, placeholder
`https://discord.com/api/webhooks/...`). It reports:

* **Session summary** — eggs stolen, pets obtained, rebirths, money/sec, runtime,
  *server Job ID*, and the local player name/UserId
  (`**Player** ... **Server** ... **Runtime** ...`).
* **Disconnect alerts** and **egg‑spawn alerts** (with an optional `<@userId>`
  ping via `WebhookPingId`).

This is opt‑in and points wherever the user configures it — but understand that
enabling it streams your account name, UserId and current server ID to that
endpoint on a timer.

### 3.3 Donation / monetization block
The UI carries a "Donations" tab with hard‑coded crypto addresses and payment
links (BTC/ETH/LTC/USDT/Solana wallets, PayPal `TheTruckerGOD`, Venmo
`miserablemusic`) and a Discord invite `discord.gg/ehKVq7pf7v`, alongside marketing
copy ("keyless, no linkvertise", "join the Discord for dupe methods / early
access"). These are static strings shown in the menu; they are the author's
payment handles.

### 3.4 "Anti‑cheat bypass" strings
Two leftover strings — `[CrazyHub] Anti-Cheat Bypassed successfully!` and
`[Bypass] Blocked detection …` — indicate a bundled/borrowed anti‑detection stub
(the `CrazyHub` tag suggests copied code). Functionally the script leans on
`applyGhostGodmode` / `setGhostState` / `OuroborosDesyncGhost` (a client‑side
desync/ghost trick) rather than any real server‑side AC defeat.

---

## 4. Worked decode example

The obfuscated player‑lookup helper (one of the smaller functions) illustrates all
four layers at once. Obfuscated form (state machine + opaque predicate, abbreviated):

```lua
function(sb)
  local Wl,Wm,Wn,Wp,Wr,Ws,Wt
  local Wk = 0.
  while true do
    Wk = 8651 - Wk
    if Wk < 8651 then break
    elseif Wk < 10631 then
      if Wk == 8651 then
        Wm = false
        for sd, se in acj[815](Fw[acj[1521.]]()) do          -- ipairs(getPlayers())
          local Wq = se
          local Wl = acj[818]                                -- inner state = 0
          while true do
            if Wl < 2 then
              if Wl < 1 then
                Wt = if Wq[acj[167]] == sb then 1 else 0      -- match UserId?
                Wr = C1*Wt + C2*(1-Wt)                        -- opaque predicate:
                Ws = C3*Wt + C4*(1-Wt)                        --   re-derives the
                Wl = if (Wr*C5 + Ws*C6 + Wr*Ws) % acj[622]    --   same boolean
                       == K then 1 else 3
              else return Wq end                              -- match → return player
            elseif Wl < 3. then Wm = true; Wl = 2             -- no match → advance
            elseif Wl < 4 then break
            else Wl = 2 end
          end
          if Wm then break end
        end
        return nil
      else break end
    else break end
  end
end
```

Stripped of the two state machines and the opaque predicate, it is simply:

```lua
local function findPlayerByUserId(userId)
    for _, plr in ipairs(Players:GetPlayers()) do
        if plr.UserId == userId then
            return plr
        end
    end
    return nil
end
```

Every other function in the file reduces the same way. `StealAnEgg_reconstructed.lua`
applies this to the program's architecture and its main automation loops.

---

## 5. Summary

| | |
|---|---|
| **Identity** | Ouroboros Hub cheat menu for *Steal an Egg* |
| **Obfuscation** | String‑array indirection + control‑flow flattening (338 loops) + opaque predicates (51) + helper‑registry dispatch. No encryption; identifiers left in cleartext. |
| **Recoverability** | Behavior 100% recoverable from the constant pool; exact per‑function source recoverable by unflattening. |
| **Capabilities** | Auto‑steal/sell/fuse/equip/buy/claim, ESP, fly/noclip/inf‑jump/speed, FPS boost, anti‑AFK, server hop, auto‑reconnect, config import/export. |
| **Network** | Self‑fetches loader + UI lib from GitHub at run time; opt‑in Discord‑webhook telemetry (player name, UserId, Job ID, stats); static crypto/PayPal/Venmo donation handles. |
| **Risk to a runner** | Executes remote code fetched at run time (contents can change after you read this); can stream account identity + server ID to a webhook if that feature is enabled; is a ToS‑violating game exploit. |

*Artifacts in this change: `StealAnEgg_Deobfuscated.md` (this file),
`StealAnEgg_constants.txt` (recovered literal pool),
`stealanegg.deindirected.lua` (full source with all 2,149 constants resolved;
control flow still flattened — the ground-truth reference),
`StealAnEgg_reconstructed.lua` (clean, readable rewrite built from the decoded logic).*
