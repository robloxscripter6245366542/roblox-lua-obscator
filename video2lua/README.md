# video2lua

Turn a **video file into a single self-contained Roblox Lua script** that plays
the video, frame by frame, inside a premium in-game GUI — with synced sound.

Frames are rendered at full resolution using Roblox's `AssetService`
**EditableImage** API (real per-pixel drawing, not a decal slideshow), so the
picture stays crisp and every frame is intact. The player ships as one `.lua`
file you can paste into an executor or drop into a Script.

```
┌──────────────────────────────────────────┐
│ ● MyVideo                          –   ✕ │  ← draggable title bar
├──────────────────────────────────────────┤
│                                          │
│            [ full-quality video ]        │  ← EditableImage surface
│                                          │
├──────────────────────────────────────────┤
│ ▓▓▓▓▓▓▓▓▓░░░░░░░░░░░░░░░░░░  ◍            │  ← scrubber (click / drag to seek)
│ ❚❚  0:12 / 0:30            🔊  ↻  ⛶      │  ← play · time · volume · loop · fullscreen
└──────────────────────────────────────────┘
```

## Features

- **Full-quality frames** — every pixel drawn via EditableImage, no decal uploads.
- **Premium GUI** — draggable window, gradient accents, drop shadow, animated
  loading bar, play/pause, click-and-drag scrubber, loop, fullscreen, minimize.
- **Synced audio** — plays a Roblox `Sound` asset locked to the timeline
  (seek, pause and loop all keep audio in sync).
- **Self-contained** — one `.lua` file, no external dependencies at runtime.
- **Tunable size** — width, fps and colour depth are all adjustable so you can
  trade file size against fidelity.

## Install (converter side)

```bash
pip install imageio imageio-ffmpeg numpy Pillow
```

`imageio-ffmpeg` bundles its own ffmpeg binary — you do **not** need ffmpeg
installed system-wide.

## Usage

```bash
python3 video2lua.py input.mp4 -o MyVideo.lua
```

Common options:

```bash
python3 video2lua.py clip.mov \
    --width 200 \      # frame width in px (height keeps aspect)   default 160
    --fps 15 \         # playback frames per second                default 12
    --colors 128 \     # colour levels/channel, 256 = full quality default 64
    --max-frames 300 \ # hard cap on frame count (0 = unlimited)
    --title "My Clip"
```

Run `python3 video2lua.py --help` for the full list.

### Adding sound

Roblox can only play audio from an **uploaded audio asset**, so sound is a
two-step flow:

1. Run the converter once. It extracts the soundtrack next to the output, e.g.
   `MyVideo.mp3`, and prints upload instructions.
2. Upload that `.mp3` to Roblox (Creator Dashboard → Audio) and copy its asset id.
3. Re-run with the id:

   ```bash
   python3 video2lua.py input.mp4 -o MyVideo.lua --audio-id 1234567890
   ```

The generated player then plays that sound in lock-step with the video. Without
`--audio-id` the video plays silently and the volume button is disabled.

## Running the result in Roblox

Paste the generated `.lua` into an executor, or put it in a `LocalScript` /
`Script` where `AssetService:CreateEditableImage` is available. On load you'll
see the decode progress bar, then playback starts automatically.

> **Requires EditableImage.** The script uses
> `AssetService:CreateEditableImage`. In Roblox Studio this needs the
> EditableImage/EditableMesh beta feature enabled; most modern executors expose
> it. If the API is missing the script warns and exits cleanly instead of
> erroring.

## How it works

1. **Extract** — `imageio` (via the bundled ffmpeg) reads the video; frames are
   resampled to the target fps and resized to the target width with Lanczos.
2. **Quantize** — optional colour-depth reduction (`--colors`) to shrink the file.
3. **Encode** — each frame is run-length encoded over its RGB pixels
   (`[count][r][g][b]` tokens) and base64'd into one string per frame.
4. **Emit** — the strings are baked into `player_template.lua` alongside the
   metadata (size, fps, duration, audio id).
5. **Decode (in game)** — on load the player base64-decodes and expands every
   frame into an RGBA pixel `buffer`, showing a progress bar, then streams them
   to the EditableImage on a `Heartbeat` clock synced to the audio.

### Sizing guidance

Raw pixels add up fast: `width × height × fps × seconds` bytes before
compression. RLE helps a lot on flat / cartoon-style footage and less on noisy
live action. If the output is too large, lower `--width`, `--fps`, or
`--colors`, or cap length with `--max-frames`. The converter prints the final
size and warns past ~4 MB.

## Files

| File                  | Purpose                                              |
|-----------------------|------------------------------------------------------|
| `video2lua.py`        | CLI converter (video → Lua)                          |
| `player_template.lua` | The premium in-game player; data markers are filled in |
| `README.md`           | This document                                        |
