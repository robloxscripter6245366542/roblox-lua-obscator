# Strongest Hub — External Module Dumps

Decompiled dumps of the pastebin modules that the `Strongest` hub pulls in at
runtime via `loadstring(game:HttpGet("https://pastebin.com/raw/<id>"))()`.

They are captured for reference/analysis. These are **control-flow dumps**, not
clean source: many function bodies are stubbed or flattened by the obfuscator,
so they document structure and behavior rather than serving as drop-in scripts.

| File | Pastebin ID | Hub button (`Strongest`) |
| :--- | :--- | :--- |
| `aimbot_v1_pWd9ji4D.dump.lua` | `pWd9ji4D` | aimbot v1 — CamLock (`BladLock`) |
| `aimbot_v2_F5k2nV6R.dump.lua` | `F5k2nV6R` | aimbot v2 |
| `aimbot_v3_aa2XJ5Wm.dump.lua` | `aa2XJ5Wm` | aimbot v3 — Camlock UI V3 |
| `kyoto_v1_XHJZ9Vky.dump.lua` | `XHJZ9Vky` | kyoto v1 — Auto Kyoto |
| `kyoto_v2_3K7VebmS.dump.lua` | `3K7VebmS` | kyoto v2 — Auto Kyoto |
| `kyoto_v3_SdXEbFrp.dump.lua` | `SdXEbFrp` | kyoto v3 — Auto Kyoto (delay UI) |

Not yet dumped: the Saitama tableflip payload (`iFWQZtvc`).
