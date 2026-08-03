# SwordsController — from decompiled source (`Sword controller dumped`)

The `Sword controller dumped` file is the output of `BladeBall_SwordDumper.lua`.
It is **already fully-decompiled clean Lua** — 45 decompiled modules, **no
Luraph obfuscation** (0 `string.char`, 0 numeric-escape string literals, no
`LPH…` / base-85 streams). So the luraph deobfuscator has nothing to decode
here; the source is readable as-is. These are the source-verified findings.

## The real parry mechanism (huge)

```lua
v_u_127._parryButtonPressConn =
    Remotes.ParryButtonPress.Event:Connect(function()
        Remotes.ParryAttempt:FireServer()
    end)
```

**The current game parry is just `Remotes.ParryAttempt:FireServer()` with no
arguments.** The server validates against ball state; there is no client-sent
CFrame / hash / camera payload on this path (the PRY hash/CFrame remote the hub
also supports is a separate/older path). So the simplest, most future-proof
parry is firing `ParryAttempt:FireServer()` — or the `ParryButtonPress`
bindable, which runs the game's own handler that does exactly that.

Applied: `SwordCtl.native_parry()` fires `ParryButtonPress` and falls back to
`ParryAttempt:FireServer()`; `native_action()` also plays the grab animation to
match a real key press.

## ParryTime — exact formula (confirms the bytecode deobfuscation)

```lua
local v70 = char:GetAttribute("ParryTime") or 0
local v71 = anim.Length == 0 and 1 or (anim.Length - anim.TimePosition) * PlaySpeed
char:SetAttribute("ParryTime", math.max(v70, v71))
```

`ParryTime = (GrabParryAnim.Length − TimePosition) × PlaySpeed`, **fallback 1.0s**
when the animation length isn't loaded. Dynamic, per-sword — exactly what
`derive_parry_reset()` computes.

## Parry guard (what blocks a parry) — source-verified

```lua
if not target
   or (target.Parent ~= workspace.Alive and not (LobbyParry or LobbyTraining))
   or target:GetAttribute("DoNotParry")
   or (target:GetAttribute("ChargingAdrenaline") and Upgrades["Qi-Charge"].Value < 2)
then return end
...
if GetAttribute("LobbyParry") and GetAttribute("InLobbyParryCooldown") then return end
```

Confirms the **`DoNotParry`** guard (already in the hub) and adds
`ChargingAdrenaline` + `InLobbyParryCooldown` as real block conditions.

## Timing constants (source-verified)

- `v_u_80 = 0.5` — post-parry delay (validates the hub's `__parry_reset` 0.5 default)
- `v_u_81 = 1.3`
- `task.delay(0.15, …)` — short post-parry timer
- `ParryTime` fallback `1.0`

## Other confirmed
- `NoobParryHappened.OnClientEvent` resets the parry-cooldown connection.
- `ParrySuccessClient` local bindable (used by the hub for instant reset).
- `ServerParryCount` tallied on success (shown in the Stats HUD).
