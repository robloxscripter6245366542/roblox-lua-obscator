import { createSceneRenderer, buildScene, animateScene } from './scenes3d.js'
import { speak, stopSpeech, loadVoices } from './voice.js'

const sleep = ms => new Promise(r => setTimeout(r, ms))

export async function makeAIVideo(prompt, { resolution, duration, onStep }) {
  // ── 1. Get video plan from Claude ──────────────────────────────
  onStep('Claude is directing your video…', 5)
  const plan = await fetchPlan(prompt)

  // ── 2. Prepare ────────────────────────────────────────────────
  onStep('Setting up 3D rendering engine…', 12)
  await loadVoices()

  const [w, h] = resolution === '4k' ? [1920, 1080] : resolution === '1080p' ? [1280, 720] : [854, 480]
  const canvas = document.createElement('canvas')
  canvas.width = w; canvas.height = h

  // Overlay canvas for 2D text/transitions
  const overlay = document.createElement('canvas')
  overlay.width = w; overlay.height = h
  const oc = overlay.getContext('2d')

  // Composite canvas (Three.js + overlay merged)
  const composite = document.createElement('canvas')
  composite.width = w; composite.height = h
  const cc = composite.getContext('2d')

  const { renderer, camera } = createSceneRenderer(canvas, w, h)

  // ── 3. Record ─────────────────────────────────────────────────
  const stream = composite.captureStream(30)
  const recorder = new MediaRecorder(stream, { mimeType: 'video/webm;codecs=vp9', videoBitsPerSecond: 12_000_000 })
  const chunks = []
  let recorderError = null
  recorder.ondataavailable = e => { if (e.data.size > 0) chunks.push(e.data) }
  recorder.onerror = e => { recorderError = e.error || new Error('MediaRecorder failed while composing video') }

  const scenes = plan.scenes || []
  const totalDuration = parseInt(duration, 10)
  const timePerScene = totalDuration / scenes.length

  recorder.start()

  // Start narration in background
  if (plan.narration) speak(plan.narration)

  // ── 4. Render each scene ──────────────────────────────────────
  for (let si = 0; si < scenes.length; si++) {
    const scenePlan = scenes[si]
    const palette = scenePlan.palette || ['#7C3AED', '#2563EB', '#ffffff']
    const sceneType = scenePlan.type || 'abstract'

    onStep(`Rendering scene ${si + 1}/${scenes.length}: ${sceneType}…`, 15 + (si / scenes.length) * 70)

    const scene = buildScene(sceneType, palette)
    const sceneMs = timePerScene * 1000
    const startTime = Date.now()
    const fps = 30
    const frameMs = 1000 / fps

    await new Promise(resolve => {
      function frame() {
        const now = Date.now()
        const elapsed = (now - startTime) / 1000
        const t = elapsed / timePerScene // 0→1

        if (now - startTime >= sceneMs) {
          // Fade out last scene
          drawFade(oc, w, h, 1)
          cc.drawImage(canvas, 0, 0)
          cc.drawImage(overlay, 0, 0)
          resolve(); return
        }

        // Animate 3D scene
        animateScene(renderer, scene, camera, sceneType, scenePlan, elapsed)

        // Composite: 3D + 2D overlay
        cc.drawImage(canvas, 0, 0)

        // Fade in
        if (t < 0.08) drawFade(oc, w, h, 1 - t / 0.08)
        // Fade out
        else if (t > 0.88) drawFade(oc, w, h, (t - 0.88) / 0.12)
        else oc.clearRect(0, 0, w, h)

        // HUD overlay
        drawHUD(oc, w, h, plan.title, sceneType, si + 1, scenes.length, t)

        cc.drawImage(overlay, 0, 0)

        setTimeout(frame, frameMs)
      }
      frame()
    })

    // Dispose scene geometry to free memory
    scene.traverse(obj => {
      if (obj.geometry) obj.geometry.dispose()
      if (obj.material) {
        if (Array.isArray(obj.material)) obj.material.forEach(m => m.dispose())
        else obj.material.dispose()
      }
    })
  }

  recorder.stop()
  onStep('Encoding final video…', 96)

  await new Promise((resolve, reject) => {
    if (recorderError) { reject(recorderError); return }
    recorder.onstop = resolve
    recorder.onerror = e => reject(e.error || new Error('MediaRecorder failed while composing video'))
  })
  stopSpeech()
  renderer.dispose()

  return URL.createObjectURL(new Blob(chunks, { type: 'video/webm' }))
}

// ── Helpers ────────────────────────────────────────────────────────

function drawFade(ctx, w, h, alpha) {
  ctx.clearRect(0, 0, w, h)
  ctx.fillStyle = `rgba(0,0,0,${Math.max(0, Math.min(1, alpha)).toFixed(3)})`
  ctx.fillRect(0, 0, w, h)
}

function drawHUD(ctx, w, h, title, sceneType, sceneNum, total, t) {
  ctx.clearRect(0, 0, w, h)
  const size = Math.round(w / 55)

  // Scene type chip (bottom left)
  if (t > 0.1 && t < 0.9) {
    const label = `Scene ${sceneNum}/${total}  ·  ${sceneType.replace('_', ' ').toUpperCase()}`
    ctx.font = `600 ${size}px Inter,sans-serif`
    const tw = ctx.measureText(label).width
    ctx.fillStyle = 'rgba(0,0,0,0.55)'
    ctx.beginPath()
    ctx.roundRect(18, h - 48, tw + 22, 30, 6)
    ctx.fill()
    ctx.fillStyle = 'rgba(255,255,255,0.85)'
    ctx.fillText(label, 29, h - 28)
  }

  // Title (center, only first scene)
  if (sceneNum === 1 && t > 0.15 && t < 0.55 && title) {
    const titleSize = Math.round(w / 28)
    ctx.font = `800 ${titleSize}px Inter,sans-serif`
    ctx.textAlign = 'center'
    ctx.fillStyle = `rgba(255,255,255,${Math.min(1, (t - 0.15) / 0.2) * 0.9})`
    ctx.shadowColor = 'rgba(124,58,237,0.8)'
    ctx.shadowBlur = 20
    ctx.fillText(title.toUpperCase(), w / 2, h / 2)
    ctx.shadowBlur = 0
    ctx.textAlign = 'left'
  }

  // AI badge top right
  ctx.font = `700 ${Math.round(w / 72)}px Inter,sans-serif`
  ctx.textAlign = 'right'
  ctx.fillStyle = 'rgba(255,255,255,0.4)'
  ctx.fillText('Powered by Claude AI  ·  3D Engine', w - 18, 28)
  ctx.textAlign = 'left'
}

async function fetchPlan(prompt) {
  try {
    const resp = await fetch('/api/claude-plan', {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({ prompt }),
    })
    if (resp.ok) return await resp.json()
  } catch (e) {
    console.warn('fetchPlan: plan request failed, using fallback plan', e)
  }
  return buildFallbackPlan(prompt)
}

function buildFallbackPlan(prompt) {
  return {
    title: prompt.slice(0, 40),
    narration: `${prompt}. A breathtaking cinematic experience powered by artificial intelligence.`,
    scenes: [
      { type: 'galaxy',   duration: 4, palette: ['#7C3AED','#2563EB','#C4B5FD'], intensity: 0.9, speed: 1.0, camera: 'orbit'      },
      { type: 'abstract', duration: 4, palette: ['#EC4899','#7C3AED','#ffffff'], intensity: 1.0, speed: 1.2, camera: 'zoom_in'    },
      { type: 'nebula',   duration: 4, palette: ['#06B6D4','#10B981','#ffffff'], intensity: 0.8, speed: 0.8, camera: 'fly_through' },
      { type: 'crystal',  duration: 3, palette: ['#F59E0B','#EF4444','#ffffff'], intensity: 0.9, speed: 0.9, camera: 'orbit'      },
    ],
    transition: 'fade',
  }
}
