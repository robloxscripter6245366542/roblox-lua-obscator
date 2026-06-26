const POLL_TEXT = 'https://text.pollinations.ai'
const POLL_IMAGE = 'https://image.pollinations.ai/prompt'

export async function generateAIVideo(prompt, { resolution, duration, onStep }) {
  onStep('Planning scenes with AI…', 8)
  const scenes = await generateScenes(prompt)

  const images = []
  for (let i = 0; i < scenes.length; i++) {
    onStep(`Generating scene ${i + 1} of ${scenes.length}…`, 15 + (i / scenes.length) * 55)
    const img = await loadPollinationsImage(scenes[i], i)
    images.push(img)
  }

  onStep('Assembling video…', 75)
  const url = await assembleVideo(images, resolution, parseInt(duration, 10))
  onStep('Finalizing…', 98)
  return url
}

async function generateScenes(prompt) {
  try {
    const resp = await fetch(`${POLL_TEXT}/`, {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({
        model: 'openai',
        jsonMode: true,
        messages: [{
          role: 'system',
          content: 'You generate cinematic scene descriptions for AI image generation. Always respond with a valid JSON array of strings only.',
        }, {
          role: 'user',
          content: `Create 4 vivid cinematic scene descriptions for a video about: "${prompt}". Each scene should be a single detailed prompt for image generation, rich with lighting, mood, and visual detail. Return ONLY a JSON array of 4 strings.`,
        }],
      }),
    })
    if (!resp.ok) throw new Error()
    const json = await resp.json()
    const arr = Array.isArray(json) ? json : (json.choices?.[0]?.message?.content && JSON.parse(json.choices[0].message.content))
    if (Array.isArray(arr) && arr.length >= 2) return arr.slice(0, 4)
  } catch {}
  return fallbackScenes(prompt)
}

function fallbackScenes(prompt) {
  return [
    `${prompt}, cinematic establishing shot, golden hour, dramatic sky, ultra detailed`,
    `${prompt}, extreme close up, cinematic lighting, shallow depth of field, 8K`,
    `${prompt}, wide aerial view, epic scale, volumetric light, photorealistic`,
    `${prompt}, dramatic finale, perfect golden ratio composition, cinematic grade`,
  ]
}

function loadPollinationsImage(scene, seed) {
  return new Promise((resolve, reject) => {
    const q = encodeURIComponent(`${scene}, cinematic, photorealistic, 8K, dramatic lighting, ultra detailed`)
    const tryLoad = (w, h, extra = '') => new Promise((res, rej) => {
      const img = new Image()
      img.crossOrigin = 'anonymous'
      img.src = `${POLL_IMAGE}/${q}?width=${w}&height=${h}&seed=${seed * 31 + 7}&nologo=true${extra}`
      img.onload = () => res(img)
      img.onerror = rej
    })
    tryLoad(1920, 1080, '&enhance=true')
      .catch(() => tryLoad(1280, 720))
      .catch(() => tryLoad(854, 480))
      .then(resolve)
      .catch(reject)
  })
}

function assembleVideo(images, resolution, durationSec) {
  return new Promise(resolve => {
    const [w, h] = resolution === '4k' ? [1920, 1080] : resolution === '1080p' ? [1280, 720] : [854, 480]
    const canvas = document.createElement('canvas')
    canvas.width = w; canvas.height = h
    const ctx = canvas.getContext('2d')

    const totalMs = durationSec * 1000
    const msPerScene = totalMs / images.length
    const fps = 30

    const stream = canvas.captureStream(fps)
    const recorder = new MediaRecorder(stream, { mimeType: 'video/webm;codecs=vp9', videoBitsPerSecond: 10_000_000 })
    const chunks = []
    recorder.ondataavailable = e => { if (e.data.size > 0) chunks.push(e.data) }
    recorder.onstop = () => resolve(URL.createObjectURL(new Blob(chunks, { type: 'video/webm' })))
    recorder.start()

    const start = Date.now()
    let sceneStart = Date.now()
    let si = 0

    function draw() {
      const now = Date.now()
      if (now - start >= totalMs) { recorder.stop(); return }

      if (now - sceneStart >= msPerScene && si < images.length - 1) {
        si++; sceneStart = now
      }

      const t = Math.min((now - sceneStart) / msPerScene, 1)
      const img = images[si]

      // Ken Burns: slow zoom + subtle pan
      const zoom = 1 + t * 0.07
      const panX = Math.sin(si * 1.3) * t * 30
      const panY = Math.cos(si * 0.9) * t * 15

      ctx.save()
      ctx.translate(w / 2 + panX, h / 2 + panY)
      ctx.scale(zoom, zoom)
      ctx.drawImage(img, -w / 2, -h / 2, w, h)
      ctx.restore()

      // Fade out
      if (t > 0.82 && si < images.length - 1) {
        ctx.fillStyle = `rgba(0,0,0,${((t - 0.82) / 0.18).toFixed(2)})`
        ctx.fillRect(0, 0, w, h)
      }
      // Fade in
      if (t < 0.12 && si > 0) {
        ctx.fillStyle = `rgba(0,0,0,${(1 - t / 0.12).toFixed(2)})`
        ctx.fillRect(0, 0, w, h)
      }

      // Subtle watermark
      ctx.fillStyle = 'rgba(255,255,255,0.35)'
      ctx.font = `bold ${Math.round(w / 72)}px Inter,sans-serif`
      ctx.textAlign = 'center'
      ctx.fillText(`AI Video · ${resolution === '4k' ? '4K' : resolution.toUpperCase()} · Powered by Pollinations`, w / 2, h - 18)

      setTimeout(draw, 1000 / fps)
    }
    draw()
  })
}
