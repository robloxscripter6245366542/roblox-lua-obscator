export async function createVideoTask(_apiKey, { prompt, genType, imageUrls, duration, aspectRatio, resolution, model, audio }) {
  const body = {
    model,
    input: {
      prompt,
      generation_type: genType,
      duration: parseInt(duration, 10),
      aspect_ratio: aspectRatio,
      resolution,
      generate_audio: audio,
      watermark: false,
      seed: -1,
      ...(imageUrls?.length ? { image_urls: imageUrls } : {}),
    },
  }
  const resp = await fetch('/api/generate', {
    method: 'POST',
    headers: { 'Content-Type': 'application/json' },
    body: JSON.stringify(body),
  })
  if (!resp.ok) {
    const err = await resp.json().catch(() => ({}))
    const msg = err.error?.message || err.message || `API error ${resp.status}`
    if (resp.status === 402) throw new Error('Insufficient credits on the Seedance account')
    if (resp.status === 429) throw new Error('Rate limit — please wait a moment and try again')
    throw new Error(msg)
  }
  const data = await resp.json()
  if (!data.taskId) throw new Error('No task ID returned from API')
  return data.taskId
}

export async function pollTask(_apiKey, taskId, onProgress) {
  for (let i = 0; i < 90; i++) {
    await sleep(10000)
    const resp = await fetch(`/api/poll?taskId=${taskId}`)
    const result = await resp.json()
    if (result.status === 'queued') onProgress?.(20)
    else if (result.status === 'generating') onProgress?.(20 + Math.min(60, i * 3))
    else if (result.status === 'completed') {
      onProgress?.(100)
      const url = result.data?.results?.[0]
      if (!url) throw new Error('No video URL in response')
      return url
    } else if (result.status === 'failed') {
      throw new Error(result.data?.failed_reason || 'Generation failed on server')
    }
  }
  throw new Error('Generation timed out')
}

export async function generateDemo(prompt, settings) {
  // Simulate realistic multi-step generation in browser (no API key)
  const steps = [
    { label: 'Parsing prompt & building scene graph…', progress: 12, delay: 700 },
    { label: 'Diffusing keyframes with Seedance 2.0…', progress: 35, delay: 2200 },
    { label: 'Temporal coherence pass…',               progress: 55, delay: 1400 },
    { label: `Upscaling to ${settings.resolution.toUpperCase()}…`, progress: 78, delay: 1600 },
    { label: 'Encoding H.265 · Muxing audio…',         progress: 92, delay: 1000 },
    { label: 'Finalizing…',                             progress: 100, delay: 500 },
  ]
  for (const s of steps) {
    settings.onStep?.(s.label, s.progress)
    await sleep(s.delay)
  }
  return generateCanvasVideo(prompt, settings)
}

function generateCanvasVideo(prompt, { resolution, duration }) {
  return new Promise((resolve, reject) => {
    try {
    const [w, h] = resolution === '4k' ? [1920, 1080] : resolution === '1080p' ? [1280, 720] : [854, 480]
    const canvas = document.createElement('canvas')
    canvas.width = w; canvas.height = h
    const ctx = canvas.getContext('2d')
    const themes = [
      ['#0a003a', '#1a0050', '#7C3AED'],
      ['#001a2a', '#002233', '#0ea5e9'],
      ['#001a10', '#002218', '#10b981'],
      ['#1a0a00', '#2a1000', '#f97316'],
    ]
    const [bg1, bg2, accent] = themes[Math.abs(prompt.charCodeAt(0)) % themes.length]
    const chunks = []
    const stream = canvas.captureStream(30)
    const recorder = new MediaRecorder(stream, { mimeType: 'video/webm;codecs=vp9', videoBitsPerSecond: 10_000_000 })
    recorder.ondataavailable = e => { if (e.data.size > 0) chunks.push(e.data) }
    recorder.onstop = () => resolve(URL.createObjectURL(new Blob(chunks, { type: 'video/webm' })))
    recorder.onerror = e => reject(e.error || new Error('MediaRecorder failed while generating video'))
    recorder.start()
    const totalFrames = 30 * parseInt(duration, 10)
    let frame = 0
    function draw() {
      if (frame >= totalFrames) { recorder.stop(); return }
      const p = frame / totalFrames
      const grd = ctx.createLinearGradient(0, 0, w, h)
      grd.addColorStop(0, bg1); grd.addColorStop(1, bg2)
      ctx.fillStyle = grd; ctx.fillRect(0, 0, w, h)
      for (let i = 0; i < 100; i++) {
        const px = (Math.sin(i * 2.3 + p * Math.PI * 2 + i) * .5 + .5) * w
        const py = (Math.cos(i * 1.7 + p * Math.PI * 2) * .5 + .5) * h
        const a = .3 + Math.sin(i + p * 4) * .2
        ctx.beginPath(); ctx.arc(px, py, 1.5 + Math.sin(i + p * 6), 0, Math.PI * 2)
        ctx.fillStyle = accent + Math.round(a * 255).toString(16).padStart(2, '0'); ctx.fill()
      }
      for (let w2 = 0; w2 < 3; w2++) {
        ctx.beginPath(); ctx.moveTo(0, h * .5)
        for (let x = 0; x <= w; x += 4) {
          ctx.lineTo(x, h * .5 + Math.sin((x / w) * Math.PI * 4 + p * Math.PI * 2 * (w2 + 1)) * (50 + w2 * 30) * Math.sin(p * Math.PI))
        }
        ctx.lineTo(w, h); ctx.lineTo(0, h); ctx.closePath()
        ctx.fillStyle = accent + '18'; ctx.fill()
      }
      const gr = ctx.createRadialGradient(w/2, h/2, 0, w/2, h/2, 300 + Math.sin(p * Math.PI * 2) * 60)
      gr.addColorStop(0, accent + '44'); gr.addColorStop(1, 'transparent')
      ctx.fillStyle = gr; ctx.fillRect(0, 0, w, h)
      ctx.fillStyle = 'rgba(255,255,255,0.55)'; ctx.font = `bold ${w/56}px Inter,sans-serif`; ctx.textAlign = 'center'
      ctx.fillText(`Seedance 2.0 · ${resolution.toUpperCase()} AI Video`, w/2, h - 32)
      ctx.fillStyle = 'rgba(0,0,0,0.55)'; ctx.beginPath(); ctx.roundRect(14, 14, 100, 26, 5); ctx.fill()
      ctx.fillStyle = accent; ctx.font = `bold ${w/80}px Inter,sans-serif`; ctx.textAlign = 'left'
      ctx.fillText(resolution === '4k' ? '4K ULTRA HD' : resolution.toUpperCase(), 22, 32)
      frame++; setTimeout(draw, 1000/30)
    }
    draw()
    } catch (e) {
      reject(e)
    }
  })
}

const sleep = ms => new Promise(r => setTimeout(r, ms))
