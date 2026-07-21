# video2lua — web app

A **browser** front-end for [`video2lua`](../video2lua): drop in a video, get a
self-contained Roblox Lua player out. No Python, no install — and the video
never leaves your machine, everything runs client-side.

It produces the **exact same output** as the CLI: it bakes the encoded frames
into the shared [`player_template.lua`](../video2lua/player_template.lua), so
the in-game player, decoder and premium draggable UI are identical.

## Use it

Open `index.html` in a browser (or host the folder on any static server / Vercel):

1. Drop a video onto the page (mp4/webm/mov — anything your browser can decode).
2. Adjust options if you want a lighter file — defaults are maximum quality
   (source resolution capped at 1024 px, source fps with every frame kept, full
   colour).
3. **Convert to Lua** → **Download .lua**.
4. Paste the `.lua` into an executor (or a script where
   `AssetService:CreateEditableImage` is available).

### Sound

Roblox only plays audio from an uploaded asset, so sound is two steps:

1. **Extract audio (.wav)** downloads the soundtrack.
2. Upload it to Roblox (Creator Dashboard → Audio), copy the asset id.
3. Paste the id into **Audio asset id** and convert again.

Browser audio decoding depends on the file's codec; if it can't decode, use the
original video's audio and upload it to Roblox yourself, then paste the id.

## How the frames are captured

The page loads the video off-screen, steps through it by seeking to each frame
time (so no frames are dropped), draws each frame to a canvas at the target
size, then run-length encodes and base64s it — the same `[count][r][g][b]`
token stream the in-game player decodes. Source frame rate is detected with
`requestVideoFrameCallback` when available (falling back to 30 fps).

## Building

`index.html` is generated from `index.template.html` with the current player
template injected. Rebuild after changing the template:

```bash
python3 build.py
```

## Files

| File                  | Purpose                                             |
|-----------------------|-----------------------------------------------------|
| `index.html`          | Built, self-contained web app (this is what you host) |
| `index.template.html` | Source page with a `/*__PLAYER_TEMPLATE__*/` marker |
| `build.py`            | Injects `../video2lua/player_template.lua` into the page |
