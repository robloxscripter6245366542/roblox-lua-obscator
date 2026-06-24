import { useEffect, useRef } from 'react'

interface Petal {
  x: number; y: number; vx: number; vy: number
  rot: number; rotV: number; size: number; alpha: number; type: number
}
interface Particle {
  x: number; y: number; vx: number; vy: number
  r: number; color: string; alpha: number; pulse: number; pulseSpeed: number
}
interface SpeedLine {
  angle: number; len: number; alpha: number; width: number
}
interface Star {
  x: number; y: number; vx: number; vy: number; life: number; maxLife: number; w: number
}
interface Lightning {
  pts: [number, number][]; alpha: number; color: string
}

function randRange(a: number, b: number) { return a + Math.random() * (b - a) }

const PETAL_COLORS = ['#ffb7c5', '#ff85a2', '#ffd6e0', '#fff0f5', '#ffadc5', '#e8a0bf']
const PARTICLE_COLORS = ['#00d4ff', '#ff00aa', '#ffd700', '#a855f7', '#00ffcc', '#ff6b35']

function makePetal(W: number): Petal {
  return {
    x: Math.random() * W, y: -30,
    vx: randRange(-1.2, 1.2), vy: randRange(0.8, 2.2),
    rot: Math.random() * Math.PI * 2, rotV: randRange(-0.04, 0.04),
    size: randRange(6, 18), alpha: randRange(0.5, 1),
    type: Math.floor(Math.random() * 3),
  }
}

function drawPetal(ctx: CanvasRenderingContext2D, p: Petal) {
  ctx.save()
  ctx.translate(p.x, p.y)
  ctx.rotate(p.rot)
  ctx.globalAlpha = p.alpha
  ctx.fillStyle = PETAL_COLORS[Math.floor(Math.random() * PETAL_COLORS.length) % PETAL_COLORS.length]
  if (p.type === 0) {
    // oval petal
    ctx.beginPath()
    ctx.ellipse(0, 0, p.size * 0.4, p.size, 0, 0, Math.PI * 2)
    ctx.fill()
  } else if (p.type === 1) {
    // heart petal
    ctx.beginPath()
    ctx.moveTo(0, -p.size * 0.5)
    ctx.bezierCurveTo(p.size * 0.6, -p.size, p.size * 0.8, p.size * 0.3, 0, p.size * 0.7)
    ctx.bezierCurveTo(-p.size * 0.8, p.size * 0.3, -p.size * 0.6, -p.size, 0, -p.size * 0.5)
    ctx.fill()
  } else {
    // round petal
    ctx.beginPath()
    ctx.arc(0, 0, p.size * 0.5, 0, Math.PI * 2)
    ctx.fill()
  }
  ctx.restore()
}

function makeLightning(x1: number, y1: number, x2: number, y2: number, segs = 8): [number, number][] {
  const pts: [number, number][] = [[x1, y1]]
  for (let i = 1; i < segs; i++) {
    const t = i / segs
    const mx = x1 + (x2 - x1) * t + randRange(-40, 40)
    const my = y1 + (y2 - y1) * t + randRange(-40, 40)
    pts.push([mx, my])
  }
  pts.push([x2, y2])
  return pts
}

export default function AnimeBackground() {
  const canvasRef = useRef<HTMLCanvasElement>(null)

  useEffect(() => {
    const canvas = canvasRef.current
    if (!canvas) return
    const ctx = canvas.getContext('2d')
    if (!ctx) return

    let W = canvas.offsetWidth
    let H = canvas.offsetHeight
    canvas.width = W
    canvas.height = H

    const resize = () => {
      W = canvas.offsetWidth; H = canvas.offsetHeight
      canvas.width = W; canvas.height = H
    }
    window.addEventListener('resize', resize)

    // State
    const petals: Petal[] = Array.from({ length: 80 }, () => {
      const p = makePetal(W); p.y = Math.random() * H; return p
    })
    const particles: Particle[] = Array.from({ length: 60 }, () => ({
      x: Math.random() * W, y: Math.random() * H,
      vx: randRange(-0.4, 0.4), vy: randRange(-0.4, 0.4),
      r: randRange(2, 8),
      color: PARTICLE_COLORS[Math.floor(Math.random() * PARTICLE_COLORS.length)],
      alpha: randRange(0.3, 0.9),
      pulse: Math.random() * Math.PI * 2,
      pulseSpeed: randRange(0.02, 0.06),
    }))
    const speedLines: SpeedLine[] = Array.from({ length: 80 }, (_, i) => ({
      angle: (i / 80) * Math.PI * 2,
      len: randRange(60, 200),
      alpha: randRange(0.05, 0.25),
      width: randRange(0.5, 2),
    }))
    const stars: Star[] = []
    const lightnings: Lightning[] = []
    let frame = 0
    let speedPulse = 0

    const spawnStar = () => {
      stars.push({
        x: Math.random() * W, y: Math.random() * H * 0.4,
        vx: randRange(8, 20), vy: randRange(1, 4),
        life: 0, maxLife: randRange(20, 50), w: randRange(2, 5),
      })
    }

    const spawnLightning = () => {
      if (particles.length < 2) return
      const a = particles[Math.floor(Math.random() * particles.length)]
      const b = particles[Math.floor(Math.random() * particles.length)]
      lightnings.push({
        pts: makeLightning(a.x, a.y, b.x, b.y),
        alpha: 1,
        color: PARTICLE_COLORS[Math.floor(Math.random() * PARTICLE_COLORS.length)],
      })
    }

    // Manga panel flash state
    let mangaFlash = 0

    const draw = () => {
      ctx.clearRect(0, 0, W, H)
      frame++
      speedPulse = Math.sin(frame * 0.02) * 0.5 + 0.5

      // ── Manga halftone-style gradient bg ──
      const hue = (frame * 0.3) % 360
      const grad = ctx.createRadialGradient(W * 0.5, H * 0.5, 0, W * 0.5, H * 0.5, Math.max(W, H) * 0.8)
      grad.addColorStop(0, `hsla(${hue}, 70%, 8%, 0.6)`)
      grad.addColorStop(0.5, `hsla(${(hue + 60) % 360}, 80%, 5%, 0.7)`)
      grad.addColorStop(1, `hsla(${(hue + 120) % 360}, 90%, 3%, 0.8)`)
      ctx.fillStyle = grad
      ctx.fillRect(0, 0, W, H)

      // ── Speed lines (manga style) from center ──
      const cx = W * 0.5 + Math.sin(frame * 0.01) * W * 0.1
      const cy = H * 0.5 + Math.cos(frame * 0.013) * H * 0.1
      for (const sl of speedLines) {
        const pulseAlpha = sl.alpha * (0.6 + speedPulse * 0.4)
        ctx.beginPath()
        ctx.moveTo(cx, cy)
        const ex = cx + Math.cos(sl.angle) * sl.len * (1 + speedPulse * 0.5)
        const ey = cy + Math.sin(sl.angle) * sl.len * (1 + speedPulse * 0.5)
        ctx.lineTo(ex, ey)
        ctx.strokeStyle = `rgba(255,255,255,${pulseAlpha})`
        ctx.lineWidth = sl.width
        ctx.stroke()
        sl.angle += 0.001
      }

      // Outer speed burst lines
      for (let i = 0; i < 24; i++) {
        const a = (i / 24) * Math.PI * 2 + frame * 0.005
        const inner = Math.max(W, H) * 0.1
        const outer = Math.max(W, H) * (0.8 + speedPulse * 0.3)
        ctx.beginPath()
        ctx.moveTo(cx + Math.cos(a) * inner, cy + Math.sin(a) * inner)
        ctx.lineTo(cx + Math.cos(a) * outer, cy + Math.sin(a) * outer)
        ctx.strokeStyle = `rgba(255,200,255,${0.03 + speedPulse * 0.05})`
        ctx.lineWidth = 1
        ctx.stroke()
      }

      // ── Energy particles ──
      for (const p of particles) {
        p.x += p.vx; p.y += p.vy; p.pulse += p.pulseSpeed
        if (p.x < 0) p.x = W; if (p.x > W) p.x = 0
        if (p.y < 0) p.y = H; if (p.y > H) p.y = 0
        const pulseR = p.r * (1 + Math.sin(p.pulse) * 0.4)
        // Outer glow
        const glow = ctx.createRadialGradient(p.x, p.y, 0, p.x, p.y, pulseR * 5)
        glow.addColorStop(0, p.color + 'cc')
        glow.addColorStop(0.4, p.color + '44')
        glow.addColorStop(1, p.color + '00')
        ctx.beginPath()
        ctx.arc(p.x, p.y, pulseR * 5, 0, Math.PI * 2)
        ctx.fillStyle = glow
        ctx.globalAlpha = p.alpha * 0.5
        ctx.fill()
        // Core
        ctx.beginPath()
        ctx.arc(p.x, p.y, pulseR, 0, Math.PI * 2)
        ctx.fillStyle = '#ffffff'
        ctx.globalAlpha = p.alpha
        ctx.fill()
        ctx.globalAlpha = 1
      }

      // ── Lightning arcs ──
      if (frame % 90 === 0) spawnLightning()
      for (let i = lightnings.length - 1; i >= 0; i--) {
        const lt = lightnings[i]
        lt.alpha -= 0.06
        if (lt.alpha <= 0) { lightnings.splice(i, 1); continue }
        ctx.beginPath()
        ctx.moveTo(lt.pts[0][0], lt.pts[0][1])
        for (let j = 1; j < lt.pts.length; j++) ctx.lineTo(lt.pts[j][0], lt.pts[j][1])
        ctx.strokeStyle = lt.color
        ctx.globalAlpha = lt.alpha
        ctx.lineWidth = 2 + lt.alpha * 2
        ctx.shadowColor = lt.color
        ctx.shadowBlur = 15
        ctx.stroke()
        ctx.shadowBlur = 0
        // Thinner inner arc
        ctx.lineWidth = 0.5
        ctx.strokeStyle = '#ffffff'
        ctx.stroke()
        ctx.globalAlpha = 1
      }

      // ── Sakura petals ──
      for (const p of petals) {
        p.x += p.vx + Math.sin(frame * 0.02 + p.y * 0.01) * 0.6
        p.y += p.vy
        p.rot += p.rotV
        const col = PETAL_COLORS[Math.floor((p.size * 7) % PETAL_COLORS.length)]
        ctx.save()
        ctx.translate(p.x, p.y)
        ctx.rotate(p.rot)
        ctx.globalAlpha = p.alpha
        // Glow
        ctx.shadowColor = '#ffadc5'
        ctx.shadowBlur = 8
        ctx.fillStyle = col
        if (p.type === 0) {
          ctx.beginPath()
          ctx.ellipse(0, 0, p.size * 0.35, p.size * 0.9, 0, 0, Math.PI * 2)
          ctx.fill()
        } else if (p.type === 1) {
          ctx.beginPath()
          ctx.moveTo(0, -p.size * 0.5)
          ctx.bezierCurveTo(p.size * 0.6, -p.size, p.size * 0.8, p.size * 0.3, 0, p.size * 0.7)
          ctx.bezierCurveTo(-p.size * 0.8, p.size * 0.3, -p.size * 0.6, -p.size, 0, -p.size * 0.5)
          ctx.fill()
        } else {
          ctx.beginPath()
          ctx.arc(0, 0, p.size * 0.45, 0, Math.PI * 2)
          ctx.fill()
        }
        ctx.shadowBlur = 0
        ctx.restore()
        if (p.y > H + 40) {
          const np = makePetal(W); petals[petals.indexOf(p)] = np
        }
      }

      // ── Shooting stars ──
      if (frame % 60 === 0 && Math.random() < 0.7) spawnStar()
      for (let i = stars.length - 1; i >= 0; i--) {
        const s = stars[i]
        s.life++; s.x += s.vx; s.y += s.vy
        const prog = s.life / s.maxLife
        const alpha = prog < 0.3 ? prog / 0.3 : 1 - (prog - 0.3) / 0.7
        ctx.beginPath()
        ctx.moveTo(s.x, s.y)
        ctx.lineTo(s.x - s.vx * 6, s.y - s.vy * 6)
        const sg = ctx.createLinearGradient(s.x, s.y, s.x - s.vx * 6, s.y - s.vy * 6)
        sg.addColorStop(0, `rgba(255,255,255,${alpha})`)
        sg.addColorStop(1, 'rgba(255,200,255,0)')
        ctx.strokeStyle = sg
        ctx.lineWidth = s.w
        ctx.stroke()
        if (s.life > s.maxLife || s.x > W + 100) stars.splice(i, 1)
      }

      // ── Manga panel flash ──
      if (frame % 200 === 0) mangaFlash = 1
      if (mangaFlash > 0) {
        mangaFlash -= 0.06
        ctx.strokeStyle = `rgba(255,220,255,${mangaFlash * 0.3})`
        ctx.lineWidth = 3
        const pad = 12
        ctx.strokeRect(pad, pad, W - pad * 2, H - pad * 2)
        ctx.strokeStyle = `rgba(200,100,255,${mangaFlash * 0.2})`
        ctx.lineWidth = 1
        ctx.strokeRect(pad + 8, pad + 8, W - (pad + 8) * 2, H - (pad + 8) * 2)
      }

      // ── Lens flares on particles ──
      if (frame % 3 === 0) {
        const fp = particles[frame % particles.length]
        const fa = 0.6 + Math.sin(frame * 0.1) * 0.4
        ctx.save()
        ctx.translate(fp.x, fp.y)
        ctx.globalAlpha = fa * 0.4
        for (let i = 0; i < 6; i++) {
          const a = (i / 6) * Math.PI * 2
          ctx.beginPath()
          ctx.moveTo(0, 0)
          ctx.lineTo(Math.cos(a) * 20, Math.sin(a) * 20)
          ctx.strokeStyle = fp.color
          ctx.lineWidth = 1
          ctx.stroke()
        }
        ctx.restore()
        ctx.globalAlpha = 1
      }
    }

    let raf: number
    const loop = () => { draw(); raf = requestAnimationFrame(loop) }
    loop()

    return () => { cancelAnimationFrame(raf); window.removeEventListener('resize', resize) }
  }, [])

  return (
    <canvas
      ref={canvasRef}
      style={{ position: 'absolute', inset: 0, width: '100%', height: '100%', pointerEvents: 'none', zIndex: 0, borderRadius: 'inherit' }}
    />
  )
}
