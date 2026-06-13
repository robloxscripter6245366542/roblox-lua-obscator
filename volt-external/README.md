# Volt — External C++ UI

A fully **external** desktop UI for the Volt remote monitor, written in C++ with
a **100% hand-built UI framework**. No ImGui, no Qt, no Rayfield, no third-party
widget library — every button, toggle, slider, tab, scroll list, and animation
is drawn by Volt's own immediate-mode UI layer on top of raw Direct2D /
DirectWrite (the Windows OS graphics APIs).

The window is a borderless, top-most overlay you drag around by its title bar.
Captured remote-call traffic streams in live from the in-game `Volt.lua`.

```
┌──────────────────────────────────────────────────────────┐
│ ⚡ Volt   Network Monitor          ● connected · 1024   ✕ │
├────┬─────────────────────────────────────────────────────┤
│ ↑  │  Outgoing Calls        [ filter... ] [Pause][Clear] │
│ ↓  │  ┌────────────────────────────────────────────────┐ │
│ ⌗  │  │ ⚡ HitDetectionHeartbeat  FireServer  x318      │ │
│ ▤  │  │ ⚡ RequestSwing  FireServer · "Heavy"… [Copy][⛔]│ │
│ ⚙  │  │ ƒ  PurchaseItem  InvokeServer · "sword"…        │ │
│ ℹ  │  └────────────────────────────────────────────────┘ │
└────┴─────────────────────────────────────────────────────┘
```

## What's in here

| File | Role |
|------|------|
| `src/Theme.h`     | Volt purple palette + layout metrics (pure data) |
| `src/Renderer.*`  | Thin Direct2D/DirectWrite surface — fill/stroke/text/gradient/shadow primitives only |
| `src/UI.*`        | **The custom UI framework** — immediate-mode widgets built by hand |
| `src/Bridge.*`    | Receives live capture from `Volt.lua` (named pipe **or** file tail) |
| `src/Store.cpp`   | In-memory call store + stats |
| `src/App.*`       | Window, message loop, nav rail, and all tab pages |
| `src/main.cpp`    | Entry point |
| `VoltBridge.lua`  | In-game streamer (also inlined into `Volt.lua`) |

### Why this counts as "no other people's UI library"

Direct2D and DirectWrite are part of Windows itself — the same layer browsers
and game launchers use to put pixels and glyphs on screen. They give us only
*"fill a rounded rectangle"* and *"draw this text"*. Everything that makes it a
**UI** — hit-testing, hover/press animation, the toggle knob slide, slider
dragging, tab indicators, scroll regions, the drag-to-move title bar — is
implemented from scratch in `UI.cpp`. You could swap Direct2D for OpenGL or GDI
and the entire widget set would still be ours.

## Build

**Requires:** Windows + MSVC (Visual Studio 2019/2022 with the C++ workload).

### Option A — one-liner batch script
```bat
cd volt-external
build.bat
:: -> build\Volt.exe
```
Run it from an **x64 Native Tools Command Prompt for VS**.

### Option B — CMake
```bat
cd volt-external
cmake -B build -G "Visual Studio 17 2022" -A x64
cmake --build build --config Release
:: -> build\Release\Volt.exe
```

## Run

```bat
:: just launch it — it shows seeded demo rows until a game connects
build\Volt.exe

:: point it at your executor's workspace stream file for live capture:
set VOLT_STREAM=C:\path\to\executor\workspace\VoltStream\stream.jsonl
build\Volt.exe
```

- **Drag** the title bar to move the window.
- **Esc** or the **✕** button closes it.
- Left nav: **Outgoing · Incoming · Explorer · Stats · Settings · About**.

## How live capture works

The external app can't hook Roblox remotes — that happens inside the game
process. So `Volt.lua` keeps doing the `__namecall` hooking and **streams** each
captured call out as a single JSON line. Two transports, whichever your executor
supports:

1. **File tail (default, universal).** `Volt.lua` appends to
   `workspace/VoltStream/stream.jsonl` with `appendfile`. Point `Volt.exe` at
   that file via `VOLT_STREAM`. Every executor can do this.
2. **Named pipe** `\\.\pipe\VoltSpy` for executors with socket/pipe access.

Both feed the same store. Each JSON line looks like:

```json
{"dir":"out","name":"ReplicatedStorage.Remotes.Swing","method":"FireServer",
 "rtype":"RemoteEvent","args":"\"Heavy\", Vector3(0, 0, -1)",
 "source":"CombatClient:121","count":1,"exec":false,"t":12.840}
```

The streamer is already inlined into `Volt.lua` (`VBridge`), so just inject
`Volt.lua` as usual and the external app picks up the traffic. `VoltBridge.lua`
is the same code as a standalone module if you want to reuse it elsewhere.

## Pages

- **Outgoing / Incoming** — live list of captured calls with type chips, repeat
  badges, per-row **Copy** (snippet to clipboard) and **Block** toggles, plus a
  search filter, pause, and clear.
- **Explorer** — Dex-style list of every unique remote seen (extendable to the
  full game tree streamed from `getnilinstances()` on the Lua side).
- **Stats** — total calls, unique remotes, bridged-line counter, and a
  most-active-remotes bar chart.
- **Settings** — capture filters, merge repeats, auto-scroll, max-log slider.
- **About** — what it is.
