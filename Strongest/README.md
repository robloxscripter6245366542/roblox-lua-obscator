# Strongest

Deobfuscated feature modules for "The Strongest Battlegrounds" animation hub
(originally by khengie_slayer, delivered through the Encrypt X obfuscator).

These were recovered by fully unpacking the loader chain:
loader → GitHub-hosted encrypted payload → decrypt → hub → 6 pastebin modules.

## Modules

| File | Feature |
|------|---------|
| `CamLock_Aimbot_v1.lua`       | CamLock aimbot v1 (nearest-enemy targeting) |
| `CamLock_V3.lua`              | CamLock v3 with smoothing presets (Custom/Smooth/Fast/Instant) + keybind |
| `Auto_Kyoto_Button.lua`      | Auto Kyoto draggable button UI |
| `Auto_Kyoto_AnimTrigger.lua` | Auto Kyoto triggered on animation playback |
| `Auto_Tech_Delay.lua`        | Auto-tech with adjustable delay |
| `Module2_F5k2nV6R.lua`       | Feature module (deobfuscated dump) |

## Notes

- Verified free of credential/exfil code: no `.ROBLOSECURITY`/cookie access,
  no webhooks, no `http_request`/`request`/`syn.request`, no `setclipboard`/`writefile`.
- The only network activity in the original package was a run hit-counter and
  pulling the public WindUI library.
- These are game-cheat scripts. Using them violates Roblox's Terms of Service.
