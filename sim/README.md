# TSB Simulator

A tiny **Luau runtime + Roblox API stub** that lets you actually *run* the Fire
Hub (`Strongest`) outside Roblox to catch runtime bugs — nil indexes, bad API
use, and broken cleanup/respawn paths — without opening the game.

## Run

```bash
sim/run.sh                 # simulate ../Strongest
sim/run.sh path/to/x.lua   # simulate another Luau script
```

First run builds the official Luau CLI via `luraph-deobf/dynamic/build_luau.sh`
(needs git + cmake + a C++ compiler); the binary is gitignored.

## What it does

`prelude.lua` stubs the Roblox environment the hub touches:

- a cooperative **scheduler** so `task.wait/spawn/delay`, `tick`, and
  `RunService.RenderStepped/Heartbeat` behave (virtual clock, stepped by the driver);
- core types with real math: **Vector3**, **CFrame** (incl. `Lerp`), plus
  permissive **Enum**, **Color3**, **UDim2**, `NumberSequence`, … ;
- an **Instance** tree — `Instance.new`, parenting, `FindFirstChild*`,
  `WaitForChild`, `GetChildren/GetDescendants`, `IsA`, `IsDescendantOf`,
  child-access-by-name (`char.Communicate`), attributes + change signals, and
  signals (`AnimationPlayed`, `Running`, `CharacterAdded`, …);
- **services** (`Players`, `RunService`, `TweenService`, `Debris`,
  `VirtualInputManager`, `Workspace`, …), a **mock WindUI** that records every
  Toggle/Button/Dropdown/Input/Keybind, and a stubbed `loadstring`/`HttpGet`;
- a fake **TSB world**: your character (Humanoid+Animator, HumanoidRootPart,
  `Communicate` remote), an enemy player, and a `Weakest Dummy` inside
  `workspace.Live`.

`driver.lua` then exercises the loaded hub: toggles every control on/off, fires
representative **animation** tracks (the dash/counter/attack IDs the techs look
for), sets combat **attributes** (`Combo`, `LastM1Hitted`), simulates a
**respawn** (to hit the character re-hook paths), and runs a **no-character**
nil-safety pass — collecting every error with the control that caused it.

## Scope / caveats

It verifies the script **runs without erroring**, not that gameplay is correct
(no real physics/animations). Cosmetic instance properties are permissive.
Add IDs/props to `prelude.lua`/`driver.lua` to widen coverage.
