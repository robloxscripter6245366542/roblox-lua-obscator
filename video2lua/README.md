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

- **Maximum quality by default** — full source resolution (capped only at
  EditableImage's 1024 px limit), the source frame rate with **every frame kept**,
  and full colour. No quantization, no dropped frames. It's lossless per frame,
  so the output can be large — and that's fine, the file can be as long as it
  needs to be.
- **Full-quality frames** — every pixel drawn via EditableImage, no decal uploads.
- **Premium GUI, draggable on PC and mobile** — the window drags with both mouse
  and touch; gradient accents, drop shadow, buffering bar, play/pause,
  click/drag scrubber, loop, volume, fullscreen, minimize.
- **Synced audio** — plays a Roblox `Sound` asset locked to the timeline
  (seek, pause and loop all keep audio in sync).
- **Bounded memory** — frames are decoded on demand with a look-ahead buffer and
  old frames are evicted, so even long, high-resolution videos play without
  loading everything into RAM at once.
- **Broad executor support** — probes the several EditableImage API shapes
  Roblox has shipped (`WritePixelsBuffer`/`WritePixels`, `Content.fromObject` /
  direct parenting) so it works across modern executors and Studio; exits
  cleanly with a warning where the API is genuinely absent.
- **Self-contained** — one `.lua` file, no external dependencies at runtime.

## Install (converter side)

```bash
pip install imageio imageio-ffmpeg numpy Pillow
```

`imageio-ffmpeg` bundles its own ffmpeg binary — you do **not** need ffmpeg
installed system-wide.

## Usage

Defaults are already maximum quality — just point it at a video:

```bash
python3 video2lua.py input.mp4 -o MyVideo.lua
```

If you *want* a lighter file, dial it down:

```bash
python3 video2lua.py clip.mov \
    --width 480 \      # frame width in px, height keeps aspect  (0 = source)
    --fps 24 \         # playback fps                            (0 = source)
    --colors 128 \     # colour levels/channel, 256 = full quality (default 256)
    --max-dim 1024 \   # hard cap on w/h; EditableImage max is 1024
    --max-frames 600 \ # hard cap on frame count (0 = unlimited)
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
5. **Decode (in game)** — on load the player buffers the first window of frames
   (progress bar), then decodes the rest on demand just ahead of the playhead,
   evicting frames left behind. Each frame is base64-decoded and expanded into
   an RGBA pixel `buffer` and streamed to the EditableImage on a `Heartbeat`
   clock synced to the audio.

### Sizing guidance

At the default (maximum) settings the file is lossless per frame, so it can get
large: raw pixels are `width × height × fps × seconds` bytes before RLE. RLE
compresses flat / cartoon footage a lot and noisy live action less. If you'd
rather a smaller file, lower `--width`, `--fps`, or `--colors`, or cap length
with `--max-frames`. The converter prints the final size; large is expected and
still plays — decoding is streamed, not loaded all at once.

## Files

| File                  | Purpose                                              |
|-----------------------|------------------------------------------------------|
| `video2lua.py`        | CLI converter (video → Lua)                          |
| `player_template.lua` | The premium in-game player; data markers are filled in |
| `README.md`           | This document                                        |
