#!/usr/bin/env python3
"""
video2lua  -  Convert a video file into a self-contained Roblox Lua player.

The generated .lua file renders full-resolution frames with AssetService's
EditableImage API inside a premium, draggable GUI (play/pause, scrubber,
loop, volume, fullscreen). Audio is played through a Roblox Sound asset:
the tool also extracts the soundtrack so you can upload it and pass the
resulting asset id with --audio-id.

Usage
-----
    python3 video2lua.py input.mp4 -o MyVideo.lua
    python3 video2lua.py clip.mov --width 200 --fps 15 --audio-id 1234567890

Frames are encoded as base64(RLE(RGB)) - one string per frame - and decoded
back to pixel buffers inside Roblox at load time. Keep resolution x fps x
length reasonable: raw pixels add up fast, so the defaults favour a crisp
but lightweight result. Bump --width / --fps for higher fidelity.

Requires: imageio, imageio-ffmpeg, numpy, Pillow
    pip install imageio imageio-ffmpeg numpy Pillow
"""

import argparse
import base64
import os
import subprocess
import sys
from pathlib import Path

try:
    import numpy as np
    import imageio.v3 as iio
    import imageio_ffmpeg
    from PIL import Image
except ImportError as exc:  # pragma: no cover
    sys.exit(
        f"Missing dependency: {exc.name}\n"
        "Install with:  pip install imageio imageio-ffmpeg numpy Pillow"
    )

TEMPLATE = Path(__file__).with_name("player_template.lua")


# --------------------------------------------------------------------------- #
#  Encoding
# --------------------------------------------------------------------------- #
def rle_encode(frame: np.ndarray) -> bytes:
    """Run-length encode an (H, W, 3) uint8 frame.

    Token layout: [count(1-255)][r][g][b] over the row-major pixel stream.
    Fast to expand in Luau and lossless. Fully vectorized so it keeps up with
    full-resolution frames (a per-pixel Python loop cannot).
    """
    flat = frame.reshape(-1, 3)
    n = len(flat)
    if n == 0:
        return b""

    # Run boundaries: a new run starts wherever the colour changes.
    changed = np.any(flat[1:] != flat[:-1], axis=1)
    starts = np.concatenate(([0], np.nonzero(changed)[0] + 1))
    ends = np.concatenate((starts[1:], [n]))
    lengths = (ends - starts).astype(np.int64)
    colors = flat[starts]                       # (R, 3) run colours

    # A run longer than 255 is split into multiple 255-capped tokens.
    ntok = (lengths + 254) // 255               # tokens per run
    total = int(ntok.sum())
    tok_run = np.repeat(np.arange(len(lengths)), ntok)      # run index per token
    run_start_tok = np.zeros(len(lengths), dtype=np.int64)
    if len(lengths) > 1:
        np.cumsum(ntok[:-1], out=run_start_tok[1:])
    within = np.arange(total) - run_start_tok[tok_run]      # token pos within run
    remaining = lengths[tok_run] - within * 255
    counts = np.minimum(remaining, 255).astype(np.uint8)

    out = np.empty((total, 4), dtype=np.uint8)
    out[:, 0] = counts
    out[:, 1:] = colors[tok_run]
    return out.tobytes()


def quantize(frame: np.ndarray, levels: int) -> np.ndarray:
    """Reduce colour depth to `levels` steps per channel to boost RLE.

    levels == 256 is a no-op (full quality).
    """
    if levels >= 256:
        return frame
    step = 255.0 / (levels - 1)
    q = np.round(frame / step) * step
    return np.clip(q, 0, 255).astype(np.uint8)


# --------------------------------------------------------------------------- #
#  Video / audio reading
# --------------------------------------------------------------------------- #
def probe_meta(path: str) -> dict:
    try:
        return iio.immeta(path)
    except Exception:
        return {}


def read_frames(path: str, target_w: int, fps: float, quant: int, max_dim: int):
    """Yield resized, quantized uint8 RGB frames from the video.

    target_w == 0  -> keep the source width (capped to max_dim).
    fps == 0       -> keep the source frame rate (every frame, nothing dropped).
    quant == 256   -> full colour, no quantization (perfect frames).
    max_dim        -> hard cap on width/height (EditableImage tops out at 1024).

    Returns (frames, out_w, out_h, actual_fps, duration).
    """
    reader = iio.imiter(path)
    src_meta = probe_meta(path)
    src_fps = float(src_meta.get("fps", 30.0) or 30.0)

    out_fps = fps if fps and fps > 0 else src_fps
    # Ratio between source fps and desired fps -> frame sampling stride.
    stride = max(src_fps / out_fps, 1.0)

    frames = []
    out_w = out_h = None
    next_take = 0.0
    idx = 0
    for frame in reader:
        if idx + 1e-9 >= next_take:
            img = Image.fromarray(frame).convert("RGB")
            if out_w is None:
                nw, nh = img.width, img.height
                if target_w and target_w > 0:
                    nh = max(1, round(nh * target_w / nw))
                    nw = target_w
                # Scale down to fit the EditableImage limit, keeping aspect.
                scale = min(max_dim / nw, max_dim / nh, 1.0)
                out_w = max(1, round(nw * scale))
                out_h = max(1, round(nh * scale))
            if (img.width, img.height) != (out_w, out_h):
                img = img.resize((out_w, out_h), Image.LANCZOS)
            arr = quantize(np.asarray(img, dtype=np.uint8), quant)
            frames.append(arr)
            next_take += stride
        idx += 1

    duration = len(frames) / out_fps if frames else 0.0
    return frames, out_w, out_h, out_fps, duration


def extract_audio(path: str, out_path: str) -> bool:
    """Extract the soundtrack to an mp3 using the bundled ffmpeg."""
    ffmpeg = imageio_ffmpeg.get_ffmpeg_exe()
    try:
        subprocess.run(
            [ffmpeg, "-y", "-i", path, "-vn", "-acodec", "libmp3lame",
             "-q:a", "3", out_path],
            check=True,
            stdout=subprocess.DEVNULL,
            stderr=subprocess.DEVNULL,
        )
        return os.path.exists(out_path) and os.path.getsize(out_path) > 0
    except Exception:
        return False


# --------------------------------------------------------------------------- #
#  Lua generation
# --------------------------------------------------------------------------- #
def build_lua(frames, w, h, fps, duration, title, audio_id) -> str:
    b64_frames = []
    total_bytes = 0
    for f in frames:
        rle = rle_encode(f)
        total_bytes += len(rle)
        b64_frames.append(base64.b64encode(rle).decode("ascii"))

    frames_literal = "{\n\t" + ",\n\t".join(f'"{s}"' for s in b64_frames) + "\n}"

    audio_field = ""
    if audio_id:
        aid = str(audio_id).strip()
        if aid.isdigit():
            audio_field = f"rbxassetid://{aid}"
        else:
            audio_field = aid  # already a full rbxassetid:// string

    template = TEMPLATE.read_text(encoding="utf-8")
    replacements = {
        "__VIDEO2LUA_TITLE__": title.replace('"', "'"),
        "__VIDEO2LUA_WIDTH__": str(w),
        "__VIDEO2LUA_HEIGHT__": str(h),
        "__VIDEO2LUA_FPS__": f"{fps:g}",
        "__VIDEO2LUA_FRAMECOUNT__": str(len(frames)),
        "__VIDEO2LUA_AUDIOID__": audio_field,
        "__VIDEO2LUA_DURATION__": f"{duration:.3f}",
        "__VIDEO2LUA_FRAMES__": frames_literal,
    }
    for k, v in replacements.items():
        template = template.replace(k, v)
    return template, total_bytes


# --------------------------------------------------------------------------- #
#  CLI
# --------------------------------------------------------------------------- #
def main() -> None:
    p = argparse.ArgumentParser(
        prog="video2lua",
        description="Convert a video into a self-contained Roblox Lua player.",
        formatter_class=argparse.ArgumentDefaultsHelpFormatter,
    )
    p.add_argument("input", help="path to the source video (mp4, mov, webm, ...)")
    p.add_argument("-o", "--output", help="output .lua path (default: <input>.lua)")
    p.add_argument("--width", type=int, default=0,
                   help="output frame width in px, height keeps aspect "
                        "(0 = source width, capped to --max-dim)")
    p.add_argument("--fps", type=float, default=0.0,
                   help="playback frames per second (0 = source fps, "
                        "every frame kept)")
    p.add_argument("--colors", type=int, default=256,
                   help="colour levels per channel (256 = full quality / "
                        "perfect frames, lower = smaller file)")
    p.add_argument("--max-dim", type=int, default=1024,
                   help="hard cap on width/height in px "
                        "(EditableImage supports up to 1024)")
    p.add_argument("--max-frames", type=int, default=0,
                   help="cap total frames (0 = no cap)")
    p.add_argument("--audio-id", default="",
                   help="Roblox audio asset id to sync as sound "
                        "(upload the extracted .mp3, then pass its id)")
    p.add_argument("--title", default="",
                   help="window title (default: input file name)")
    p.add_argument("--no-audio", action="store_true",
                   help="skip extracting the soundtrack")
    args = p.parse_args()

    src = args.input
    if not os.path.isfile(src):
        sys.exit(f"Input not found: {src}")

    out_path = args.output or (os.path.splitext(src)[0] + ".lua")
    title = args.title or os.path.splitext(os.path.basename(src))[0]

    wtxt = "source" if args.width == 0 else args.width
    ftxt = "source" if args.fps == 0 else args.fps
    print(f"[video2lua] reading '{src}' @ width={wtxt} fps={ftxt} "
          f"colors={args.colors} max-dim={args.max_dim}")
    frames, w, h, fps, duration = read_frames(
        src, args.width, args.fps, args.colors, args.max_dim
    )
    if not frames:
        sys.exit("No frames could be read from the input video.")

    if args.max_frames and len(frames) > args.max_frames:
        frames = frames[: args.max_frames]
        duration = len(frames) / fps
        print(f"[video2lua] capped to {args.max_frames} frames")

    print(f"[video2lua] {len(frames)} frames  {w}x{h}  "
          f"{duration:.1f}s")

    # Audio extraction (best-effort).
    audio_id = args.audio_id
    if not args.no_audio and not audio_id:
        audio_path = os.path.splitext(out_path)[0] + ".mp3"
        if extract_audio(src, audio_path):
            print(f"[video2lua] soundtrack extracted -> {audio_path}")
            print("            Upload it to Roblox, then regenerate with "
                  "--audio-id <id> to enable sound.")
        else:
            print("[video2lua] no audio track found (or extraction failed)")

    lua, total_bytes = build_lua(frames, w, h, fps, duration, title, audio_id)
    Path(out_path).write_text(lua, encoding="utf-8")

    size_kb = os.path.getsize(out_path) / 1024
    print(f"[video2lua] wrote {out_path}  "
          f"({size_kb:.0f} KB, ~{total_bytes/1024:.0f} KB pixels pre-base64)")
    if size_kb > 4096:
        print("[video2lua] large output (full quality). It still plays - frames "
              "are streamed, not loaded all at once. For a lighter file, lower "
              "--width / --fps / --colors or set --max-frames.")
    if audio_id:
        print(f"[video2lua] audio synced to asset {audio_id}")


if __name__ == "__main__":
    main()
