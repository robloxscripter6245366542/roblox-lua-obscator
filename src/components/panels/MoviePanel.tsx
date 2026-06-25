import { useState, useRef, useEffect } from 'react'
import { motion, AnimatePresence } from 'framer-motion'
import MoviePlayer from './MoviePlayer'
import AnimeBackground from './AnimeBackground'

const PIPELINE = [
  { ic: '📝', name: 'Claude', role: 'Screenplay', color: 'rgba(124,58,237,.3)' },
  { ic: '👤', name: 'Flux Realism', role: 'Characters', color: 'rgba(6,182,212,.3)' },
  { ic: '🌄', name: 'Flux Pro', role: 'Backgrounds', color: 'rgba(16,185,129,.3)' },
  { ic: '🔷', name: 'Flux 3D', role: '3D Models', color: 'rgba(245,158,11,.3)' },
  { ic: '✨', name: 'Seedream', role: 'VFX / Glows', color: 'rgba(168,85,247,.3)' },
  { ic: '🎬', name: 'Seedance 2.0', role: 'Video Clips', color: 'rgba(236,72,153,.3)' },
  { ic: '🎼', name: 'Suno AI', role: 'Soundtrack', color: 'rgba(245,158,11,.3)' },
  { ic: '🎙️', name: 'ElevenLabs', role: 'Narration', color: 'rgba(6,182,212,.3)' },
  { ic: '🎞️', name: 'Assembly', role: 'Final Movie', color: 'rgba(16,185,129,.3)' },
]

const VFX_PRESETS = [
  '✨ Glowing neon particles swirling in darkness',
  '🌸 Cherry blossom petals floating in magical light',
  '💫 Character with flowing luminous hair, wind',
  '🔥 Fire and ember particles rising, cinematic',
  '⚡ Electric lightning bolt with blue glow',
  '🌊 Ocean spray with volumetric god rays',
  '🌀 Holographic portal with energy rings',
  '💎 Crystal shattering with rainbow refraction',
]

type SceneStatus = 'queued' | 'generating' | 'done' | 'failed'
interface Scene { id: number; text: string; status: SceneStatus; clipUrl?: string }
interface CharAsset { desc: string; imgUrl?: string }

// ─────────────────────────────────────────────
//  AnimatedMovieFrame — canvas overlay for every Flux image
// ─────────────────────────────────────────────
type FrameType = 'background' | 'character' | 'model' | 'vfx'
type Pt = {
  x: number; y: number; vx: number; vy: number
  size: number; alpha: number; color: string; life: number; maxLife: number
  spin: number; kind: 'petal' | 'leaf' | 'pollen' | 'hair' | 'spark' | 'orbit' | 'dot'
  orbitR?: number; orbitCx?: number; orbitCy?: number
}

function AnimatedMovieFrame({ src, alt = '', type = 'background' }: { src: string; alt?: string; type?: FrameType }) {
  const canvasRef = useRef<HTMLCanvasElement>(null)
  const wrapRef = useRef<HTMLDivElement>(null)
  const imgRef = useRef<HTMLImageElement>(null)
  const rafRef = useRef(0)

  useEffect(() => {
    const canvas = canvasRef.current
    const wrap = wrapRef.current
    if (!canvas || !wrap) return
    const ctx = canvas.getContext('2d')
    if (!ctx) return

    const resize = () => { canvas.width = wrap.clientWidth || 240; canvas.height = wrap.clientHeight || 180 }
    requestAnimationFrame(resize)
    const ro = new ResizeObserver(resize)
    ro.observe(wrap)

    const pts: Pt[] = []
    const MAX = type === 'vfx' ? 55 : type === 'background' ? 60 : type === 'character' ? 35 : 28

    const spawnBackground = (w: number, h: number): Pt => {
      const r = Math.random()
      if (r < 0.4) { // pink/white cherry blossom petals
        const clrs = ['rgba(255,182,193,', 'rgba(255,210,220,', 'rgba(255,240,245,', 'rgba(230,160,200,']
        return { x: Math.random() * w * 1.2 - w * .1, y: Math.random() * h, vx: (Math.random() - .5) * .5 + .2, vy: -Math.random() * .4 - .1, size: Math.random() * 4 + 1.5, alpha: Math.random() * .7 + .25, color: clrs[Math.floor(Math.random() * clrs.length)], life: 0, maxLife: Math.random() * 300 + 150, spin: Math.random() * Math.PI * 2, kind: 'petal', orbitR: 0, orbitCx: 0, orbitCy: 0 }
      } else if (r < 0.7) { // green/yellow leaves
        const clrs = ['rgba(120,200,80,', 'rgba(80,180,50,', 'rgba(160,220,60,', 'rgba(200,230,80,']
        return { x: Math.random() * w, y: Math.random() * h, vx: (Math.random() - .5) * .4, vy: -Math.random() * .3 - .05, size: Math.random() * 5 + 2, alpha: Math.random() * .6 + .2, color: clrs[Math.floor(Math.random() * clrs.length)], life: 0, maxLife: Math.random() * 400 + 180, spin: Math.random() * Math.PI * 2, kind: 'leaf', orbitR: 0, orbitCx: 0, orbitCy: 0 }
      } else { // white pollen dust
        return { x: Math.random() * w, y: Math.random() * h, vx: (Math.random() - .5) * .3, vy: -Math.random() * .2 - .05, size: Math.random() * 1.5 + .3, alpha: Math.random() * .5 + .15, color: 'rgba(255,255,255,', life: 0, maxLife: Math.random() * 250 + 100, spin: 0, kind: 'pollen', orbitR: 0, orbitCx: 0, orbitCy: 0 }
      }
    }

    const spawnCharacter = (w: number, h: number): Pt => {
      const isHair = Math.random() < 0.6
      if (isHair) {
        const clrs = ['rgba(220,190,255,', 'rgba(180,220,255,', 'rgba(255,200,220,', 'rgba(255,240,180,', 'rgba(200,255,220,']
        return { x: Math.random() * w, y: Math.random() * h * .6, vx: (Math.random() - .5) * .5, vy: -Math.random() * .7 - .15, size: Math.random() * 1.8 + .4, alpha: Math.random() * .8 + .2, color: clrs[Math.floor(Math.random() * clrs.length)], life: 0, maxLife: Math.random() * 200 + 80, spin: (Math.random() - .5) * .06, kind: 'hair', orbitR: 0, orbitCx: 0, orbitCy: 0 }
      }
      const clrs = ['rgba(255,255,200,', 'rgba(200,230,255,', 'rgba(255,200,255,']
      return { x: Math.random() * w, y: Math.random() * h, vx: (Math.random() - .5) * .3, vy: -Math.random() * .4 - .1, size: Math.random() * 1.2 + .3, alpha: Math.random() * .9 + .1, color: clrs[Math.floor(Math.random() * clrs.length)], life: 0, maxLife: Math.random() * 120 + 40, spin: 0, kind: 'spark', orbitR: 0, orbitCx: 0, orbitCy: 0 }
    }

    const spawnModel = (w: number, h: number): Pt => {
      const angle = Math.random() * Math.PI * 2
      const orbitR = Math.random() * Math.min(w, h) * .38 + Math.min(w, h) * .08
      const cx = w / 2, cy = h / 2
      const clrs = ['rgba(80,220,255,', 'rgba(255,180,50,', 'rgba(80,255,180,', 'rgba(200,100,255,']
      return { x: cx + Math.cos(angle) * orbitR, y: cy + Math.sin(angle) * orbitR, vx: 0, vy: 0, size: Math.random() * 2 + .5, alpha: Math.random() * .9 + .1, color: clrs[Math.floor(Math.random() * clrs.length)], life: 0, maxLife: 9999, spin: angle, kind: 'orbit', orbitR, orbitCx: cx, orbitCy: cy }
    }

    const spawnVFX = (w: number, h: number): Pt => {
      const zone = Math.floor(Math.random() * 3)
      const cx = zone === 0 ? w / 2 : zone === 1 ? w * .25 : w * .75
      const cy = zone === 0 ? h / 2 : zone === 1 ? h * .3 : h * .7
      const clrs = ['rgba(255,80,50,', 'rgba(255,210,50,', 'rgba(255,50,210,', 'rgba(80,160,255,', 'rgba(50,255,180,']
      const a = Math.random() * Math.PI * 2
      const spd = Math.random() * 2.2 + .5
      return { x: cx + (Math.random() - .5) * 30, y: cy + (Math.random() - .5) * 30, vx: Math.cos(a) * spd, vy: Math.sin(a) * spd - .4, size: Math.random() * 2.8 + .5, alpha: 1, color: clrs[Math.floor(Math.random() * clrs.length)], life: 0, maxLife: Math.random() * 65 + 20, spin: 0, kind: 'spark', orbitR: 0, orbitCx: 0, orbitCy: 0 }
    }

    let fr = 0
    const RIG_PERIOD = 500

    const tick = () => {
      const w = canvas.width, h = canvas.height
      ctx.clearRect(0, 0, w, h)
      fr++

      // ── Ambient overlays ──
      if (type === 'vfx') {
        // Pulsing radial glow
        const p1 = .10 + Math.sin(fr * .05) * .07
        const g = ctx.createRadialGradient(w / 2, h / 2, 0, w / 2, h / 2, w * .7)
        g.addColorStop(0, `rgba(255,80,200,${p1.toFixed(3)})`)
        g.addColorStop(.55, `rgba(80,50,255,${(p1 * .5).toFixed(3)})`)
        g.addColorStop(1, 'rgba(0,0,0,0)')
        ctx.fillStyle = g; ctx.fillRect(0, 0, w, h)
        // Expanding rings
        for (let ri = 0; ri < 3; ri++) {
          const rPhase = (fr + ri * 166) % 330
          const rr = rPhase / 330
          const ringR = rr * Math.max(w, h) * .7
          const ringA = (rr < .5 ? rr * 2 : 1 - (rr - .5) * 2) * .18
          ctx.strokeStyle = `rgba(255,80,180,${ringA.toFixed(3)})`
          ctx.lineWidth = 1.5
          ctx.beginPath(); ctx.arc(w / 2, h / 2, ringR, 0, Math.PI * 2); ctx.stroke()
        }
      }

      if (type === 'character') {
        // Rim glow top
        const ga = .06 + Math.sin(fr * .025) * .03
        const g = ctx.createLinearGradient(0, 0, 0, h * .4)
        g.addColorStop(0, `rgba(140,180,255,${ga.toFixed(3)})`)
        g.addColorStop(1, 'rgba(0,0,0,0)')
        ctx.fillStyle = g; ctx.fillRect(0, 0, w, h)
        // Edge rim
        const ge = ctx.createRadialGradient(w / 2, h * .3, w * .08, w / 2, h * .3, w * .72)
        ge.addColorStop(.82, 'rgba(0,0,0,0)')
        ge.addColorStop(1, `rgba(100,170,255,${(ga * 1.8).toFixed(3)})`)
        ctx.fillStyle = ge; ctx.fillRect(0, 0, w, h)
      }

      if (type === 'model') {
        // Rotating scan line
        const sy = ((fr * 1.8) % (h + 40)) - 20
        const sg = ctx.createLinearGradient(0, sy - 10, 0, sy + 10)
        sg.addColorStop(0, 'rgba(80,200,255,0)')
        sg.addColorStop(.5, 'rgba(80,200,255,0.15)')
        sg.addColorStop(1, 'rgba(80,200,255,0)')
        ctx.fillStyle = sg; ctx.fillRect(0, sy - 10, w, 20)
        // Second scan (diagonal)
        const sy2 = ((fr * .9 + 150) % (h + 40)) - 20
        const sg2 = ctx.createLinearGradient(0, sy2 - 6, 0, sy2 + 6)
        sg2.addColorStop(0, 'rgba(255,180,50,0)')
        sg2.addColorStop(.5, 'rgba(255,180,50,0.1)')
        sg2.addColorStop(1, 'rgba(255,180,50,0)')
        ctx.fillStyle = sg2; ctx.fillRect(0, sy2 - 6, w, 12)
        // Orbit ring
        const orbitPulse = .08 + Math.sin(fr * .03) * .04
        ctx.strokeStyle = `rgba(80,200,255,${orbitPulse.toFixed(3)})`
        ctx.lineWidth = 1
        ctx.beginPath(); ctx.ellipse(w / 2, h / 2, Math.min(w, h) * .42, Math.min(w, h) * .22, fr * .008, 0, Math.PI * 2); ctx.stroke()
        ctx.strokeStyle = `rgba(255,180,50,${(orbitPulse * .7).toFixed(3)})`
        ctx.beginPath(); ctx.ellipse(w / 2, h / 2, Math.min(w, h) * .3, Math.min(w, h) * .36, -fr * .012, 0, Math.PI * 2); ctx.stroke()
      }

      if (type === 'background') {
        // Moving light shaft
        const shimX = ((fr * .8) % (w + 100)) - 50
        const sg = ctx.createLinearGradient(shimX - 30, 0, shimX + 30, h)
        sg.addColorStop(0, 'rgba(255,255,255,0)')
        sg.addColorStop(.5, `rgba(255,255,240,${(.04 + Math.sin(fr * .02) * .02).toFixed(3)})`)
        sg.addColorStop(1, 'rgba(255,255,255,0)')
        ctx.fillStyle = sg; ctx.fillRect(shimX - 30, 0, 60, h)
      }

      // ── Rigging flash overlay (character & model) ──
      if (type === 'character' || type === 'model') {
        const rp = fr % RIG_PERIOD
        if (rp < 55) {
          const t = rp < 25 ? rp / 25 : 1 - (rp - 25) / 30
          const rigA = t * (type === 'character' ? .22 : .18)
          ctx.strokeStyle = type === 'character' ? `rgba(80,220,255,${rigA.toFixed(3)})` : `rgba(255,200,80,${rigA.toFixed(3)})`
          ctx.lineWidth = .4
          const gs = type === 'character' ? 18 : 22
          for (let gx = 0; gx <= w; gx += gs) { ctx.beginPath(); ctx.moveTo(gx, 0); ctx.lineTo(gx, h); ctx.stroke() }
          for (let gy = 0; gy <= h; gy += gs) { ctx.beginPath(); ctx.moveTo(0, gy); ctx.lineTo(w, gy); ctx.stroke() }

          if (type === 'character') {
            // Skeleton joints
            const jA = rigA * 4
            const joints: [number, number][] = [[w / 2, h * .07], [w / 2, h * .22], [w * .28, h * .34], [w * .72, h * .34], [w * .18, h * .5], [w * .82, h * .5], [w / 2, h * .52], [w * .34, h * .75], [w * .66, h * .75], [w * .3, h * .94], [w * .7, h * .94]]
            ctx.strokeStyle = `rgba(80,240,255,${(jA * .8).toFixed(3)})`; ctx.lineWidth = 1.2
            const bones: [number, number][][] = [[0, 1], [1, 2], [1, 3], [2, 4], [3, 5], [1, 6], [6, 7], [6, 8], [7, 9], [8, 10]]
            bones.forEach(([a, b]) => {
              ctx.beginPath(); ctx.moveTo(joints[a][0], joints[a][1]); ctx.lineTo(joints[b][0], joints[b][1]); ctx.stroke()
            })
            ctx.fillStyle = `rgba(80,240,255,${(jA * 1.2).toFixed(3)})`
            joints.forEach(([jx, jy]) => { ctx.beginPath(); ctx.arc(jx, jy, 2.5, 0, Math.PI * 2); ctx.fill() })
          }
          if (type === 'model') {
            ctx.strokeStyle = `rgba(255,200,80,${(rigA * 2.5).toFixed(3)})`; ctx.lineWidth = 1
            ctx.beginPath(); ctx.arc(w / 2, h / 2, Math.min(w, h) * .35, 0, Math.PI * 2); ctx.stroke()
            ctx.beginPath(); ctx.arc(w / 2, h / 2, Math.min(w, h) * .18, 0, Math.PI * 2); ctx.stroke()
            // cross hairs
            ctx.beginPath(); ctx.moveTo(w / 2 - 20, h / 2); ctx.lineTo(w / 2 + 20, h / 2)
            ctx.moveTo(w / 2, h / 2 - 20); ctx.lineTo(w / 2, h / 2 + 20); ctx.stroke()
          }
        }
      }

      // ── Spawn ──
      const rate = type === 'vfx' ? 1 : type === 'background' ? 3 : 6
      if (pts.length < MAX && fr % rate === 0) {
        if (type === 'background') pts.push(spawnBackground(w, h))
        else if (type === 'character') pts.push(spawnCharacter(w, h))
        else if (type === 'model') pts.push(spawnModel(w, h))
        else pts.push(spawnVFX(w, h))
      }

      // ── Draw particles ──
      for (let i = pts.length - 1; i >= 0; i--) {
        const p = pts[i]
        p.life++

        // Update position
        if (p.kind === 'orbit') {
          const orbitSpeed = .018 + (p.orbitR! / (Math.min(w, h) * .5)) * .008
          p.spin += orbitSpeed
          p.x = p.orbitCx! + Math.cos(p.spin) * p.orbitR!
          p.y = p.orbitCy! + Math.sin(p.spin) * p.orbitR! * .55
          // orbital particles live forever; fade only at edges
          const t = Math.sin(p.spin) * .5 + .5
          const a = p.alpha * (.5 + t * .5)
          ctx.save(); ctx.globalAlpha = a
          ctx.shadowBlur = 7; ctx.shadowColor = p.color + '.9)'
          ctx.fillStyle = p.color + a.toFixed(2) + ')'
          ctx.beginPath(); ctx.arc(p.x, p.y, p.size, 0, Math.PI * 2); ctx.fill()
          ctx.restore()
          // orbit particles never die
          continue
        }

        p.x += p.vx; p.y += p.vy
        if (p.kind === 'hair') p.vx += p.spin * Math.sin(p.life * .09)

        const t = p.life / p.maxLife
        const a = p.alpha * (t < .12 ? t / .12 : t > .78 ? (1 - (t - .78) / .22) : 1)
        if (a <= 0 || p.life >= p.maxLife || p.x < -30 || p.x > w + 30 || p.y < -30 || p.y > h + 30) {
          pts.splice(i, 1); continue
        }

        ctx.save(); ctx.globalAlpha = Math.max(0, a)

        if (p.kind === 'petal') {
          ctx.translate(p.x, p.y); ctx.rotate(p.spin + p.life * .022)
          ctx.fillStyle = p.color + a.toFixed(2) + ')'
          ctx.beginPath(); ctx.ellipse(0, 0, p.size * 1.8, p.size * .65, 0, 0, Math.PI * 2); ctx.fill()
          ctx.strokeStyle = p.color.replace('rgba', 'rgba').replace(/([\d.]+)\)$/, (_: string, n: string) => `${Math.min(1, parseFloat(n) * 1.5)})`); ctx.lineWidth = .3
          ctx.stroke()
        } else if (p.kind === 'leaf') {
          ctx.translate(p.x, p.y); ctx.rotate(p.spin + p.life * .015)
          ctx.fillStyle = p.color + a.toFixed(2) + ')'
          ctx.beginPath()
          ctx.moveTo(0, -p.size * 1.5)
          ctx.bezierCurveTo(p.size * 1.1, -p.size * .5, p.size * 1.1, p.size * .5, 0, p.size * 1.5)
          ctx.bezierCurveTo(-p.size * 1.1, p.size * .5, -p.size * 1.1, -p.size * .5, 0, -p.size * 1.5)
          ctx.fill()
          ctx.strokeStyle = 'rgba(255,255,255,' + (a * .3).toFixed(2) + ')'; ctx.lineWidth = .4
          ctx.beginPath(); ctx.moveTo(0, -p.size * 1.5); ctx.lineTo(0, p.size * 1.5); ctx.stroke()
        } else if (p.kind === 'pollen') {
          ctx.fillStyle = p.color + a.toFixed(2) + ')'
          ctx.beginPath(); ctx.arc(p.x - p.x, p.y - p.y, p.size, 0, Math.PI * 2)
          ctx.restore(); ctx.save(); ctx.globalAlpha = Math.max(0, a)
          ctx.fillStyle = p.color + a.toFixed(2) + ')'
          ctx.beginPath(); ctx.arc(p.x, p.y, p.size, 0, Math.PI * 2); ctx.fill()
        } else if (p.kind === 'hair') {
          ctx.shadowBlur = 5; ctx.shadowColor = p.color + '.8)'
          ctx.fillStyle = p.color + a.toFixed(2) + ')'
          ctx.beginPath(); ctx.arc(p.x, p.y, p.size, 0, Math.PI * 2); ctx.fill()
        } else { // spark
          ctx.shadowBlur = 10; ctx.shadowColor = p.color + '.9)'
          ctx.fillStyle = p.color + a.toFixed(2) + ')'
          ctx.beginPath(); ctx.arc(p.x, p.y, p.size, 0, Math.PI * 2); ctx.fill()
          if (p.kind === 'spark' && (type === 'vfx' || type === 'character')) {
            ctx.strokeStyle = p.color + (a * .4).toFixed(2) + ')'; ctx.lineWidth = p.size * .5
            ctx.beginPath(); ctx.moveTo(p.x - p.vx * 6, p.y - p.vy * 6); ctx.lineTo(p.x, p.y); ctx.stroke()
          }
        }
        ctx.restore()
      }

      rafRef.current = requestAnimationFrame(tick)
    }
    requestAnimationFrame(() => { resize(); rafRef.current = requestAnimationFrame(tick) })
    return () => { cancelAnimationFrame(rafRef.current); ro.disconnect() }
  }, [src, type])

  const onMouseMove = (e: React.MouseEvent<HTMLDivElement>) => {
    if (type !== 'character' && type !== 'model') return
    const r = e.currentTarget.getBoundingClientRect()
    const dx = ((e.clientX - r.left) / r.width - .5) * 2
    const dy = ((e.clientY - r.top) / r.height - .5) * 2
    if (imgRef.current) imgRef.current.style.transform = `perspective(500px) rotateY(${dx * 16}deg) rotateX(${-dy * 11}deg) scale(1.07)`
  }
  const onMouseLeave = () => { if (imgRef.current) imgRef.current.style.transform = '' }

  const imgAnim = type === 'background' ? 'imgFloat 14s ease-in-out infinite' : type === 'model' ? 'imgFloat 8s ease-in-out infinite' : type === 'character' ? 'charBreathe 5s ease-in-out infinite' : undefined

  return (
    <div ref={wrapRef} style={{ position: 'relative', overflow: 'hidden', lineHeight: 0 }} onMouseMove={onMouseMove} onMouseLeave={onMouseLeave}>
      <img ref={imgRef} src={src} alt={alt} style={{ width: '100%', display: 'block', transition: 'transform .35s ease', animation: imgAnim }} />
      <canvas ref={canvasRef} style={{ position: 'absolute', inset: 0, width: '100%', height: '100%', pointerEvents: 'none' }} />
    </div>
  )
}

// ─────────────────────────────────────────────
//  Main panel
// ─────────────────────────────────────────────
export default function MoviePanel() {
  const [concept, setConcept] = useState('')
  const [genre, setGenre] = useState('Sci-Fi Thriller')
  const [style, setStyle] = useState('cinematic')
  const [lenMin, setLenMin] = useState(5)
  const [vidModel, setVidModel] = useState('seedance-2.0')
  const [charsText, setCharsText] = useState('')
  const [vfxPrompt, setVfxPrompt] = useState('')

  const [running, setRunning] = useState(false)
  const [stopped, setStopped] = useState(false)
  const [activePipe, setActivePipe] = useState(-1)
  const [statusMsg, setStatusMsg] = useState('')
  const [progress, setProgress] = useState(0)

  const [script, setScript] = useState('')
  const [chars, setChars] = useState<CharAsset[]>([])
  const [scenes, setScenes] = useState<Scene[]>([])
  const scenesRef = useRef<Scene[]>([])
  const setScenesSynced = (updater: Scene[] | ((prev: Scene[]) => Scene[])) => {
    setScenes(prev => {
      const next = typeof updater === 'function' ? updater(prev) : updater
      scenesRef.current = next
      return next
    })
  }
  const [storyboardFrames, setStoryboardFrames] = useState<string[]>([])
  const [modelImages, setModelImages] = useState<string[]>([])
  const [vfxImages, setVfxImages] = useState<string[]>([])
  const [musicSrc, setMusicSrc] = useState('')
  const [narrateSrc, setNarrateSrc] = useState('')
  const stoppedRef = useRef(false)

  const wait = (ms: number) => new Promise<void>(r => setTimeout(r, ms))

  const genImg = async (prompt: string, model: string, w = 768, h = 768): Promise<string> => {
    try {
      const r = await fetch('/api/image', {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({ prompt, model, width: w, height: h }),
      })
      if (!r.ok) return ''
      const blob = await r.blob()
      return URL.createObjectURL(blob)
    } catch { return '' }
  }

  const startMovie = async () => {
    if (!concept.trim()) { alert('Enter a movie concept!'); return }
    setRunning(true); setStopped(false); stoppedRef.current = false
    setScript(''); setChars([]); setScenesSynced([]); setStoryboardFrames([])
    setModelImages([]); setVfxImages([]); setMusicSrc(''); setNarrateSrc('')
    setActivePipe(-1); setProgress(0)

    const CLIP_SEC = 5
    const totalClips = Math.ceil(lenMin * 60 / CLIP_SEC)
    const sceneCount = Math.max(3, Math.min(Math.ceil(totalClips / 3), 40))
    const imgModel = style === 'anime' ? 'flux-anime' : style === '3d' ? 'flux-3d' : style === 'cartoon' ? 'flux-anime' : 'flux-realism'

    // ── 1. SCREENPLAY ──
    setActivePipe(0); setStatusMsg('📝 Claude writing full screenplay…'); setProgress(5)
    const scriptPrompt = `You are a professional screenwriter. Write a complete ${genre} screenplay in ${style} visual style for this concept:\n\n"${concept}"\n\nTarget length: ${lenMin} minutes | Scenes: ${sceneCount}\n\nFor EVERY scene use this EXACT format:\n[SCENE N] INT/EXT. LOCATION - TIME\nVISUAL: [detailed AI video generation prompt — describe camera, lighting, action, mood]\nACTION: [what physically happens]\nDIALOGUE: CHARACTER NAME: "spoken line"\nMUSIC_CUE: [music direction]\nVFX: [glows, particles, hair animation, petals, rigging, light effects]\n\nAlso include:\n- TITLE: [movie title]\n- LOGLINE: [one sentence]\n- CHARACTERS: [name: detailed physical description including hair style, color, clothing, expression — for AI image generation]\n\nBe extremely cinematic and detailed.`
    let generatedScript = ''
    try {
      const r = await fetch('/api/chat', { method: 'POST', headers: { 'Content-Type': 'application/json' }, body: JSON.stringify({ messages: [{ role: 'user', content: scriptPrompt }] }) })
      if (!r.ok) throw new Error(`Chat API returned ${r.status}`)
      const d = await r.json()
      if (!d.reply) throw new Error(d.error || 'Empty reply')
      generatedScript = d.reply
      setScript(generatedScript)
    } catch (e: any) {
      setStatusMsg(`❌ Script failed — ${e.message || 'check connection'}`)
      setActivePipe(-1); setProgress(0); setRunning(false); return
    }
    setProgress(18)
    if (stoppedRef.current) { setRunning(false); return }

    // ── 2. CHARACTERS (Flux — 4K portrait) ──
    setActivePipe(1); setStatusMsg('👤 Designing characters with Flux — 4K portrait rendering…'); setProgress(22)
    const charSectionMatch = generatedScript.match(/CHARACTERS?:?([\s\S]*?)(?=\[SCENE|\n\n[A-Z])/i)
    const charLines = (charsText.trim() || charSectionMatch?.[1] || '')
      .split('\n').map(l => l.trim()).filter(l => l.length > 10).slice(0, 4)
    setChars(charLines.map(d => ({ desc: d })))
    const charDesigns: CharAsset[] = await Promise.all(charLines.map(async (desc) => {
      const styleExtra = style === 'anime' ? 'anime art style, studio quality illustration, beautiful anime, dynamic hair strands' : style === '3d' ? '3D CGI render, Pixar quality, subsurface scattering, physically based rendering' : style === 'cartoon' ? 'cartoon illustration, vibrant, clean linework, expressive' : 'hyperrealistic portrait, cinematic lighting, photographic, golden ratio composition'
      const imgUrl = await genImg(`Character portrait, full body rigging reference sheet, ${desc}, ${styleExtra}, individual hair strands flowing, expressive eyes, dynamic pose, professional concept art, 4K ultra detail, 8K`, imgModel, 768, 1024)
      return { desc, imgUrl }
    }))
    setChars(charDesigns)
    setProgress(35)
    if (stoppedRef.current) { setRunning(false); return }

    // ── 3. STORYBOARD (Flux Pro — 4K widescreen) ──
    setActivePipe(2); setStatusMsg('🌄 Flux Pro generating 4K storyboard backgrounds…'); setProgress(38)
    const sceneRegex = /\[SCENE \d+\]([\s\S]*?)(?=\[SCENE \d+\]|$)/g
    const sceneMatches = [...generatedScript.matchAll(sceneRegex)].map(m => m[0])
    const frames: string[] = []
    for (let i = 0; i < Math.min(sceneMatches.length, 8); i++) {
      if (stoppedRef.current) break
      const vis = sceneMatches[i].match(/VISUAL:\s*([^\n]+)/i)?.[1] || sceneMatches[i].slice(0, 150)
      const url = await genImg(`Cinematic ${style} film background environment, ${vis}, ${genre} genre, professional cinematography, dramatic lighting, ultra detailed foliage, flowing flowers and leaves, atmospheric depth, 4K ultra HD quality`, 'flux-pro', 768, 432)
      if (url) frames.push(url)
      setStoryboardFrames([...frames])
      setProgress(38 + (i / 8) * 12)
      await wait(500)
    }
    if (stoppedRef.current) { setRunning(false); return }

    // ── 4. 3D MODELS (Flux 3D — 4K renders) ──
    setActivePipe(3); setStatusMsg('🔷 Flux 3D generating 4K 3D models and assets…'); setProgress(50)
    const threeDPrompts: string[] = []
    const actionLines = [...generatedScript.matchAll(/ACTION:\s*([^\n]+)/ig)].map(m => m[1]).slice(0, 6)
    actionLines.forEach(line => {
      const obj = line.match(/(?:a |an |the )([\w\s]{4,30}(?:ship|craft|robot|vehicle|building|weapon|portal|device|suit|mech|sword|gun|castle|throne|spaceship|car|bike|drone|machine|tower))/i)?.[1]
      if (obj) threeDPrompts.push(`Full 3D CGI render of ${obj}, ${style} style, physically based rendering, subsurface scattering, professional studio lighting, 360 turntable view, rigging bones visible, Unreal Engine 5 quality, 4K ultra detail`)
    })
    if (threeDPrompts.length === 0) {
      const locs = [...generatedScript.matchAll(/(?:INT\.|EXT\.)\s+([^-\n]+)/g)].map(m => m[1].trim()).slice(0, 3)
      locs.forEach(loc => threeDPrompts.push(`3D CGI environment render of ${loc}, ${genre} genre, cinematic lighting, ultra detailed foliage and particles, photorealistic, Unreal Engine 5, 4K`))
    }
    const modelUrls: string[] = []
    for (const p of threeDPrompts.slice(0, 4)) {
      if (stoppedRef.current) break
      const url = await genImg(p, 'flux-3d', 768, 768)
      if (url) modelUrls.push(url)
      await wait(400)
    }
    if (modelUrls.length > 0) setModelImages(modelUrls)
    setProgress(56)
    if (stoppedRef.current) { setRunning(false); return }

    // ── 5. VFX (Seedream — 4K) ──
    setActivePipe(4); setStatusMsg('✨ Seedream generating 4K VFX and particle effects…'); setProgress(58)
    const vfxDescs: string[] = []
    sceneMatches.slice(0, 6).forEach(s => { const vfx = s.match(/VFX:\s*([^\n]+)/i)?.[1]; if (vfx) vfxDescs.push(vfx) })
    const vfxUrls: string[] = []
    for (const desc of vfxDescs.slice(0, 4)) {
      if (stoppedRef.current) break
      const url = await genImg(`${desc}, cinematic VFX, glowing particles, flower petals floating, magical light effects, sparkling dust, professional visual effect, 4K maximum detail`, 'seedream', 768, 768)
      if (url) vfxUrls.push(url)
      await wait(400)
    }
    if (vfxUrls.length > 0) setVfxImages(vfxUrls)
    setProgress(65)
    if (stoppedRef.current) { setRunning(false); return }

    // ── 6. SOUNDTRACK ──
    setActivePipe(6); setStatusMsg('🎼 Stable Audio composing soundtrack…'); setProgress(68)
    try {
      const musicCues = sceneMatches.slice(0, 3).map(s => s.match(/MUSIC_CUE:\s*([^\n]+)/i)?.[1]).filter(Boolean).join(', ')
      const mPrompt = `${genre} film score, ${style} aesthetic, ${musicCues || 'cinematic dramatic'}, for: ${concept.slice(0, 80)}`
      const mr = await fetch('/api/music', { method: 'POST', headers: { 'Content-Type': 'application/json' }, body: JSON.stringify({ prompt: mPrompt, model: 'stable-audio' }) })
      if (mr.ok) { const blob = await mr.blob(); setMusicSrc(URL.createObjectURL(blob)) }
    } catch {}
    setProgress(75)
    if (stoppedRef.current) { setRunning(false); return }

    // ── 7. NARRATION ──
    setActivePipe(7); setStatusMsg('🎙️ ElevenLabs narrating opening scene…'); setProgress(78)
    try {
      const nr = await fetch('/api/audio', { method: 'POST', headers: { 'Content-Type': 'application/json' }, body: JSON.stringify({ text: `${concept.slice(0, 200)}. A ${genre} story begins.`, voice: 'nova' }) })
      if (nr.ok) { const blob = await nr.blob(); setNarrateSrc(URL.createObjectURL(blob)) }
    } catch {}
    setProgress(85)
    if (stoppedRef.current) { setRunning(false); return }

    // ── 8. SCENE QUEUE ──
    setActivePipe(5); setStatusMsg('🎬 Video scene queue ready — click Generate Clips to start!')
    const builtScenes: Scene[] = sceneMatches.slice(0, Math.min(sceneMatches.length, 30)).map((text, i) => ({ id: i, text, status: 'queued' as SceneStatus }))
    setScenesSynced(builtScenes)
    setProgress(90)

    // ── 9. DONE ──
    setActivePipe(8); setStatusMsg('🎞️ Pipeline complete! Generate video clips to finish your movie.')
    setProgress(100); setRunning(false)
  }

  const generateClips = async () => {
    const sceneList = [...scenesRef.current]
    if (!sceneList.length) return
    for (let i = 0; i < sceneList.length; i++) {
      if (stoppedRef.current) break
      setScenesSynced(prev => prev.map((s, idx) => idx === i ? { ...s, status: 'generating' } : s))
      const vis = sceneList[i].text.match(/VISUAL:\s*([^\n]+)/i)?.[1] || sceneList[i].text.replace(/\[SCENE.*?\]/g, '').slice(0, 200)
      try {
        const r = await fetch('/api/video', { method: 'POST', headers: { 'Content-Type': 'application/json' }, body: JSON.stringify({ prompt: vis.trim(), model: vidModel, duration: 5, width: 1920, height: 1080 }) })
        if (r.ok) {
          const ct = r.headers.get('content-type') || ''
          let url = ''
          if (ct.includes('video') || ct.includes('octet')) { const blob = await r.blob(); url = URL.createObjectURL(blob) }
          else { const d = await r.json(); url = d.url || '' }
          setScenesSynced(prev => prev.map((s, idx) => idx === i ? { ...s, status: 'done', clipUrl: url } : s))
        } else throw new Error()
      } catch { setScenesSynced(prev => prev.map((s, idx) => idx === i ? { ...s, status: 'failed' } : s)) }
      await wait(2000)
    }
  }

  const genVFX = async () => {
    if (!vfxPrompt.trim()) return
    setVfxImages([])
    const urls: string[] = []
    for (let i = 0; i < 4; i++) {
      const url = await genImg(`${vfxPrompt}, cinematic VFX, glowing particles, flower petals floating, magical light, sparkling dust, 4K maximum detail, variation ${i + 1}`, 'seedream', 768, 768)
      if (url) urls.push(url)
      setVfxImages([...urls])
      await wait(300)
    }
  }

  const designChars = async () => {
    const lines = charsText.split('\n').filter(l => l.trim().length > 5).slice(0, 4)
    if (!lines.length) return
    const imgModel = style === 'anime' ? 'flux-anime' : style === '3d' ? 'flux-3d' : 'flux-realism'
    setChars(lines.map(d => ({ desc: d })))
    const results = await Promise.all(lines.map(async desc => {
      const url = await genImg(`Character portrait, full body rigging reference, ${desc}, individual hair strands, expressive eyes, dynamic pose, ${style === 'anime' ? 'anime art, studio quality, flowing hair' : 'hyperrealistic, cinematic lighting, photographic quality'}, professional concept art, 4K ultra detail`, imgModel, 768, 1024)
      return { desc, imgUrl: url }
    }))
    setChars(results)
  }

  const totalClips = Math.ceil(lenMin * 60 / 5)
  const estHours = Math.ceil(totalClips * 1.5 / 60)

  return (
    <div className="flex flex-col gap-4" style={{ position: 'relative' }}>
      <div style={{ position: 'fixed', inset: 0, zIndex: 0, pointerEvents: 'none', overflow: 'hidden' }}>
        <AnimeBackground />
      </div>

      <div style={{ position: 'relative', zIndex: 1, display: 'flex', gap: 20, alignItems: 'flex-start' }}>

        {/* ── LEFT controls ── */}
        <div style={{ flex: '1 1 0', minWidth: 0, display: 'flex', flexDirection: 'column', gap: 16 }}>

          {/* Pipeline banner */}
          <div className="glass rounded-2xl p-4" style={{ border: '1px solid rgba(236,72,153,.3)' }}>
            <div className="text-xs font-bold mb-3" style={{ color: 'var(--p)' }}>⚡ 9 SPECIALISED AIs — COLLABORATING ON YOUR FILM</div>
            <div className="grid gap-1.5" style={{ gridTemplateColumns: 'repeat(9,1fr)' }}>
              {PIPELINE.map((p, i) => (
                <motion.div key={i}
                  animate={{ opacity: activePipe === i ? 1 : activePipe > i ? 0.8 : 0.35, scale: activePipe === i ? 1.04 : 1 }}
                  className="text-center p-2 rounded-lg"
                  style={{ background: activePipe === i ? p.color : 'rgba(255,255,255,.04)', border: `1px solid ${activePipe === i ? p.color.replace(',.3)', ',.6)') : 'rgba(255,255,255,.06)'}`, transition: 'all .4s' }}>
                  <div className="text-base">{p.ic}</div>
                  <div className="text-xs font-bold text-white leading-tight">{p.name}</div>
                  <div style={{ fontSize: 9, color: 'var(--muted)' }}>{p.role}</div>
                  {activePipe > i && <div style={{ fontSize: 10, color: '#10b981' }}>✓</div>}
                </motion.div>
              ))}
            </div>
          </div>

          {/* Concept + settings */}
          <div className="grid gap-4" style={{ gridTemplateColumns: '1fr 1fr' }}>
            <div>
              <label className="text-xs font-bold mb-2 block" style={{ color: 'var(--p)' }}>Movie Concept / Story</label>
              <textarea value={concept} onChange={e => setConcept(e.target.value)} rows={4} className="ai-input" style={{ resize: 'none' }}
                placeholder="A sci-fi thriller: an AI gains consciousness in near-future Tokyo. Neon rain, corporate espionage, rogue androids breaking free..." />
            </div>
            <div className="grid gap-2" style={{ gridTemplateColumns: '1fr 1fr' }}>
              {[
                { label: 'Genre', value: genre, onChange: setGenre, options: ['Sci-Fi Thriller','Action','Drama','Fantasy','Horror','Comedy','Romance','Documentary','Animation'] },
                { label: 'Visual Style', value: style, onChange: setStyle, options: [{ v: 'cinematic', l: 'Cinematic / Realistic' }, { v: 'anime', l: 'Anime / Manga' }, { v: 'cartoon', l: 'Cartoon / Illustrated' }, { v: '3d', l: '3D CGI Animated' }, { v: 'documentary', l: 'Documentary' }, { v: 'noir', l: 'Film Noir' }] },
              ].map(({ label, value, onChange, options }) => (
                <div key={label}>
                  <label className="text-xs font-bold mb-1 block" style={{ color: 'var(--p)' }}>{label}</label>
                  <select value={value} onChange={e => onChange(e.target.value)} className="ai-select">
                    {options.map((o: any) => typeof o === 'string' ? <option key={o}>{o}</option> : <option key={o.v} value={o.v}>{o.l}</option>)}
                  </select>
                </div>
              ))}
              <div>
                <label className="text-xs font-bold mb-1 block" style={{ color: 'var(--p)' }}>Movie Length</label>
                <select value={lenMin} onChange={e => setLenMin(parseInt(e.target.value))} className="ai-select">
                  <option value={2}>Short (2 min)</option><option value={5}>Short Film (5 min)</option>
                  <option value={15}>Medium (15 min)</option><option value={30}>Half Hour (30 min)</option>
                  <option value={60}>Feature Film (1 hr)</option><option value={120}>Epic (2 hrs)</option>
                  <option value={540}>Marathon (9 hrs)</option>
                </select>
              </div>
              <div>
                <label className="text-xs font-bold mb-1 block" style={{ color: 'var(--p)' }}>Video Model</label>
                <select value={vidModel} onChange={e => setVidModel(e.target.value)} className="ai-select">
                  <option value="seedance-2.0">Seedance 2.0 (Best)</option><option value="veo">Veo (Google)</option>
                  <option value="wan-pro-1080p">Wan Pro 1080p</option><option value="grok-video-pro">Grok Video Pro</option>
                  <option value="nova-reel">Nova Reel</option>
                </select>
              </div>
            </div>
          </div>

          {/* Character Designer */}
          <div className="glass rounded-2xl p-4" style={{ border: '1px solid rgba(6,182,212,.2)' }}>
            <div className="flex items-center justify-between mb-3">
              <div>
                <div className="text-sm font-bold text-white">👤 Character Designer — Flux Realism / Anime / 3D · 4K</div>
                <div className="text-xs" style={{ color: 'var(--muted)' }}>Detailed hair strands, rigging reference sheets, animated canvas overlay with skeleton rig flash</div>
              </div>
              <button onClick={designChars} className="px-4 py-2 rounded-xl font-bold text-black text-xs flex-shrink-0" style={{ background: 'linear-gradient(135deg,var(--c),var(--v))' }}>Design →</button>
            </div>
            <textarea value={charsText} onChange={e => setCharsText(e.target.value)} rows={2} className="ai-input" style={{ resize: 'none', fontSize: 12 }}
              placeholder={'Protagonist: 28-year-old female hacker, silver hair with bioluminescent streaks, cyberpunk black outfit\nAntagonist: tall male executive, sharp grey suit, glowing red eyes, emotionless expression'} />
            {chars.length > 0 && (
              <div className="grid gap-3 mt-3" style={{ gridTemplateColumns: 'repeat(4,1fr)' }}>
                {chars.map((c, i) => (
                  <div key={i} className="glass rounded-xl overflow-hidden" style={{ border: '1px solid rgba(6,182,212,.3)' }}>
                    {c.imgUrl
                      ? <AnimatedMovieFrame src={c.imgUrl} alt={c.desc} type="character" />
                      : <div className="flex items-center justify-center" style={{ height: 180, background: 'rgba(0,0,0,.4)' }}><div className="spin" style={{ width: 24, height: 24, borderWidth: 2 }}></div></div>}
                    <div className="p-2" style={{ fontSize: 10, color: 'var(--muted)' }}>{c.desc.slice(0, 55)}</div>
                  </div>
                ))}
              </div>
            )}
          </div>

          {/* VFX Generator */}
          <div className="glass rounded-2xl p-4" style={{ border: '1px solid rgba(168,85,247,.2)' }}>
            <div className="flex items-center justify-between mb-2">
              <div>
                <div className="text-sm font-bold text-white">✨ VFX &amp; Effects — Seedream · 4K</div>
                <div className="text-xs" style={{ color: 'var(--muted)' }}>Flower petals · leaves · glows · particles · magic · animated canvas overlay</div>
              </div>
              <button onClick={genVFX} className="px-4 py-2 rounded-xl font-bold text-black text-xs flex-shrink-0" style={{ background: 'linear-gradient(135deg,#a855f7,var(--v))' }}>Generate →</button>
            </div>
            <div className="flex gap-1 flex-wrap mb-2">
              {VFX_PRESETS.map((t, i) => (
                <button key={i} className="rounded-lg px-2 py-1 text-xs" style={{ background: 'rgba(168,85,247,.1)', border: '1px solid rgba(168,85,247,.25)', color: 'var(--text)' }}
                  onClick={() => setVfxPrompt(t.replace(/^[^ ]+ /, ''))}>{t}</button>
              ))}
            </div>
            <input value={vfxPrompt} onChange={e => setVfxPrompt(e.target.value)} type="text" className="ai-input" style={{ fontSize: 12 }}
              placeholder="Describe VFX: glowing neon particles swirling, cherry blossom petals falling, character with flowing luminous hair..." />
            {vfxImages.length > 0 && (
              <div className="grid gap-2 mt-3" style={{ gridTemplateColumns: 'repeat(4,1fr)' }}>
                {vfxImages.map((url, i) => (
                  <div key={i} style={{ borderRadius: 8, overflow: 'hidden', border: '1px solid rgba(168,85,247,.3)' }}>
                    <AnimatedMovieFrame src={url} alt={`VFX ${i + 1}`} type="vfx" />
                  </div>
                ))}
              </div>
            )}
          </div>

          {/* Start button */}
          {lenMin >= 60 && (
            <div className="glass rounded-xl p-3 text-xs" style={{ border: '1px solid rgba(245,158,11,.3)', color: 'var(--o)' }}>
              ⚠️ <strong>{lenMin}-minute movie</strong> = {totalClips} video clips. ~{estHours > 1 ? `${estHours} hours` : `${Math.ceil(totalClips * 1.5)} minutes`} generation time.
            </div>
          )}
          <button onClick={startMovie} disabled={running} className="w-full py-4 rounded-2xl font-black text-black text-base"
            style={{ background: running ? 'rgba(100,100,100,.5)' : 'linear-gradient(135deg,var(--p),var(--v),var(--c))', letterSpacing: .5, cursor: running ? 'not-allowed' : 'pointer' }}>
            {running ? '🎬 Production Running…' : '🎬 START FULL AI MOVIE PRODUCTION · 4K'}
          </button>

          {/* Progress */}
          <AnimatePresence>
            {(running || progress > 0) && (
              <motion.div initial={{ opacity: 0, y: 10 }} animate={{ opacity: 1, y: 0 }} className="glass rounded-2xl p-5" style={{ border: '1px solid rgba(255,255,255,.08)' }}>
                <div className="flex items-center justify-between mb-3">
                  <div className="font-bold text-white">🎬 Production Pipeline</div>
                  {running && <button onClick={() => { setStopped(true); stoppedRef.current = true; setRunning(false) }}
                    className="text-xs px-3 py-1.5 rounded-lg" style={{ background: 'rgba(255,50,50,.15)', border: '1px solid rgba(255,50,50,.3)', color: '#f87171' }}>Stop</button>}
                </div>
                <div className="text-sm mb-2" style={{ color: 'var(--c)' }}>{statusMsg}</div>
                <div className="progress-bar"><div className="progress-fill" style={{ width: `${progress}%` }}></div></div>
                <div className="text-xs mt-1 opacity-50">{progress}%</div>
              </motion.div>
            )}
          </AnimatePresence>

          {/* Storyboard */}
          <AnimatePresence>
            {storyboardFrames.length > 0 && (
              <motion.div initial={{ opacity: 0 }} animate={{ opacity: 1 }} className="glass rounded-2xl p-4" style={{ border: '1px solid rgba(16,185,129,.2)' }}>
                <div className="text-sm font-bold text-white mb-3">🎞️ AI Storyboard — 4K Backgrounds ({storyboardFrames.length} frames)</div>
                <div className="grid gap-2" style={{ gridTemplateColumns: 'repeat(4,1fr)' }}>
                  {storyboardFrames.map((url, i) => (
                    <div key={i} className="rounded-xl overflow-hidden" style={{ border: '1px solid rgba(16,185,129,.3)' }}>
                      <AnimatedMovieFrame src={url} alt={`Scene ${i + 1}`} type="background" />
                      <div className="text-center py-1" style={{ fontSize: 10, color: 'var(--muted)' }}>Scene {i + 1}</div>
                    </div>
                  ))}
                </div>
              </motion.div>
            )}
          </AnimatePresence>

          {/* 3D Models */}
          <AnimatePresence>
            {modelImages.length > 0 && (
              <motion.div initial={{ opacity: 0 }} animate={{ opacity: 1 }} className="glass rounded-2xl p-4" style={{ border: '1px solid rgba(245,158,11,.2)' }}>
                <div className="text-sm font-bold text-white mb-3">🔷 Flux 3D — 4K Props, Vehicles &amp; Environments ({modelImages.length} renders)</div>
                <div className="grid gap-2" style={{ gridTemplateColumns: 'repeat(4,1fr)' }}>
                  {modelImages.map((url, i) => (
                    <div key={i} className="rounded-xl overflow-hidden" style={{ border: '1px solid rgba(245,158,11,.3)' }}>
                      <AnimatedMovieFrame src={url} alt={`3D Model ${i + 1}`} type="model" />
                      <div className="text-center py-1" style={{ fontSize: 10, color: 'var(--muted)' }}>Model {i + 1}</div>
                    </div>
                  ))}
                </div>
              </motion.div>
            )}
          </AnimatePresence>

          {/* VFX assets */}
          <AnimatePresence>
            {vfxImages.length > 0 && (
              <motion.div initial={{ opacity: 0 }} animate={{ opacity: 1 }} className="glass rounded-2xl p-4" style={{ border: '1px solid rgba(168,85,247,.2)' }}>
                <div className="text-sm font-bold text-white mb-3">✨ Seedream — 4K VFX, Glows &amp; Particles ({vfxImages.length} assets)</div>
                <div className="grid gap-2" style={{ gridTemplateColumns: 'repeat(4,1fr)' }}>
                  {vfxImages.map((url, i) => (
                    <div key={i} className="rounded-xl overflow-hidden" style={{ border: '1px solid rgba(168,85,247,.3)' }}>
                      <AnimatedMovieFrame src={url} alt={`VFX ${i + 1}`} type="vfx" />
                      <div className="text-center py-1" style={{ fontSize: 10, color: 'var(--muted)' }}>VFX {i + 1}</div>
                    </div>
                  ))}
                </div>
              </motion.div>
            )}
          </AnimatePresence>

          {/* Scene queue */}
          <AnimatePresence>
            {scenes.length > 0 && (
              <motion.div initial={{ opacity: 0 }} animate={{ opacity: 1 }} className="glass rounded-2xl p-5" style={{ border: '1px solid rgba(236,72,153,.2)' }}>
                <div className="text-sm font-bold text-white mb-3">🎬 Video Clip Queue — {vidModel}</div>
                <div className="grid gap-3 text-center mb-4" style={{ gridTemplateColumns: 'repeat(4,1fr)' }}>
                  {[
                    { val: totalClips, label: 'Total Clips', c: 'var(--p)' },
                    { val: `${lenMin}min`, label: 'Movie Length', c: 'var(--c)' },
                    { val: scenes.length, label: 'Scenes', c: 'var(--g)' },
                    { val: estHours > 1 ? `~${estHours}h` : `~${Math.ceil(totalClips * 1.5)}m`, label: 'Est. Time', c: 'var(--o)' },
                  ].map(({ val, label, c }) => (
                    <div key={label} className="glass rounded-xl p-3" style={{ border: '1px solid rgba(255,255,255,.08)' }}>
                      <div className="text-2xl font-black" style={{ color: c }}>{val}</div>
                      <div className="text-xs opacity-60">{label}</div>
                    </div>
                  ))}
                </div>
                <div className="flex flex-col gap-1.5 max-h-48 overflow-y-auto mb-4">
                  {scenes.map(s => (
                    <div key={s.id} className="flex items-center gap-3 glass rounded-lg px-3 py-2 text-xs" style={{ border: '1px solid rgba(255,255,255,.06)' }}>
                      <span className="font-bold w-5 text-center" style={{ color: 'var(--c)' }}>{s.id + 1}</span>
                      <span className="flex-1 opacity-60 truncate">{s.text.match(/\[SCENE \d+\]/)?.[0] || `Scene ${s.id + 1}`}</span>
                      <span className="px-2 py-0.5 rounded text-xs" style={{ background: s.status === 'done' ? 'rgba(16,185,129,.2)' : s.status === 'generating' ? 'rgba(6,182,212,.2)' : s.status === 'failed' ? 'rgba(239,68,68,.2)' : 'rgba(255,255,255,.06)', color: s.status === 'done' ? '#10b981' : s.status === 'generating' ? 'var(--c)' : s.status === 'failed' ? '#ef4444' : 'var(--muted)' }}>
                        {s.status === 'done' ? '✅' : s.status === 'generating' ? '⏳ Generating…' : s.status === 'failed' ? '⚠️ Failed' : 'Queued'}
                      </span>
                      {s.clipUrl && <a href={s.clipUrl} download={`scene-${s.id + 1}.mp4`} style={{ color: 'var(--v)', fontSize: 14, textDecoration: 'none' }}>⬇</a>}
                    </div>
                  ))}
                </div>
                <button onClick={generateClips} className="w-full py-3 rounded-xl font-bold text-black text-sm" style={{ background: 'linear-gradient(135deg,var(--p),var(--v))' }}>
                  ▶ Generate All {scenes.length} Clips with {vidModel}
                </button>
                {scenes.filter(s => s.clipUrl).length > 0 && (
                  <div className="grid gap-2 mt-4" style={{ gridTemplateColumns: 'repeat(3,1fr)' }}>
                    {scenes.filter(s => s.clipUrl).map(s => (
                      <div key={s.id} className="glass rounded-xl overflow-hidden" style={{ border: '1px solid rgba(255,255,255,.08)' }}>
                        <video src={s.clipUrl} controls muted style={{ width: '100%', display: 'block' }} />
                        <div className="text-center py-1" style={{ fontSize: 10, color: 'var(--muted)' }}>Scene {s.id + 1}</div>
                      </div>
                    ))}
                  </div>
                )}
              </motion.div>
            )}
          </AnimatePresence>

          {/* Screenplay */}
          <AnimatePresence>
            {script && (
              <motion.div initial={{ opacity: 0 }} animate={{ opacity: 1 }} className="glass rounded-2xl p-5" style={{ border: '1px solid rgba(255,255,255,.08)' }}>
                <div className="flex items-center justify-between mb-3">
                  <div className="font-bold text-white">📄 AI-Generated Screenplay</div>
                  <button onClick={() => { const b = new Blob([script], { type: 'text/plain' }); const a = document.createElement('a'); a.href = URL.createObjectURL(b); a.download = 'omni-ai-screenplay.txt'; a.click() }}
                    className="text-xs px-3 py-1.5 rounded-lg" style={{ background: 'rgba(255,255,255,.08)', border: '1px solid rgba(255,255,255,.1)', color: 'var(--text)' }}>⬇ Download</button>
                </div>
                <div className="text-sm leading-relaxed" style={{ color: 'var(--muted)', whiteSpace: 'pre-wrap', maxHeight: 500, overflowY: 'auto', fontFamily: 'SF Mono,Fira Code,monospace', fontSize: 12 }}>{script}</div>
              </motion.div>
            )}
          </AnimatePresence>

        </div>{/* end left column */}

        {/* ── RIGHT sticky preview ── */}
        <div style={{ width: 420, flexShrink: 0, position: 'sticky', top: 20 }}>
          <div className="flex flex-col gap-3">

            <MoviePlayer
              clips={scenes.filter(s => s.status === 'done' && s.clipUrl).map(s => ({ id: s.id, clipUrl: s.clipUrl!, label: s.text.match(/\[SCENE \d+\]/)?.[0] || `Scene ${s.id + 1}` }))}
              title={script.match(/TITLE:\s*([^\n]+)/i)?.[1]?.trim() || 'omni-ai-movie'}
              totalScenes={scenes.length}
              doneScenes={scenes.filter(s => s.status === 'done' && s.clipUrl).length}
            />

            {storyboardFrames.length > 0 && (
              <motion.div initial={{ opacity: 0 }} animate={{ opacity: 1 }} className="glass rounded-2xl p-3" style={{ border: '1px solid rgba(16,185,129,.2)' }}>
                <div className="text-xs font-bold text-white mb-2">🎞️ 4K Storyboard — animated backgrounds</div>
                <div className="grid gap-1.5" style={{ gridTemplateColumns: 'repeat(2,1fr)' }}>
                  {storyboardFrames.slice(0, 4).map((url, i) => (
                    <div key={i} className="rounded-lg overflow-hidden" style={{ border: '1px solid rgba(16,185,129,.3)' }}>
                      <AnimatedMovieFrame src={url} alt={`Frame ${i + 1}`} type="background" />
                      <div className="text-center py-0.5" style={{ fontSize: 9, color: 'var(--muted)' }}>Scene {i + 1}</div>
                    </div>
                  ))}
                </div>
              </motion.div>
            )}

            {chars.filter(c => c.imgUrl).length > 0 && (
              <motion.div initial={{ opacity: 0 }} animate={{ opacity: 1 }} className="glass rounded-2xl p-3" style={{ border: '1px solid rgba(6,182,212,.2)' }}>
                <div className="text-xs font-bold text-white mb-2">👤 Characters — 3D tilt · rig flash · hair particles</div>
                <div className="flex gap-2 overflow-x-auto">
                  {chars.filter(c => c.imgUrl).map((c, i) => (
                    <div key={i} className="flex-shrink-0 rounded-lg overflow-hidden" style={{ width: 80, border: '1px solid rgba(6,182,212,.3)' }}>
                      <AnimatedMovieFrame src={c.imgUrl!} alt={c.desc} type="character" />
                    </div>
                  ))}
                </div>
              </motion.div>
            )}

            {vfxImages.length > 0 && (
              <motion.div initial={{ opacity: 0 }} animate={{ opacity: 1 }} className="glass rounded-2xl p-3" style={{ border: '1px solid rgba(168,85,247,.2)' }}>
                <div className="text-xs font-bold text-white mb-2">✨ VFX — spark trails · pulsing rings · glow bursts</div>
                <div className="grid gap-1.5" style={{ gridTemplateColumns: 'repeat(2,1fr)' }}>
                  {vfxImages.slice(0, 4).map((url, i) => (
                    <div key={i} className="rounded-lg overflow-hidden" style={{ border: '1px solid rgba(168,85,247,.3)' }}>
                      <AnimatedMovieFrame src={url} alt={`VFX ${i + 1}`} type="vfx" />
                    </div>
                  ))}
                </div>
              </motion.div>
            )}

            {musicSrc && (
              <motion.div initial={{ opacity: 0 }} animate={{ opacity: 1 }} className="glass rounded-2xl p-3" style={{ border: '1px solid rgba(245,158,11,.2)' }}>
                <div className="text-xs font-bold text-white mb-2">🎼 Soundtrack</div>
                <audio controls className="w-full rounded-xl" style={{ accentColor: 'var(--o)' }}><source src={musicSrc} /></audio>
              </motion.div>
            )}
            {narrateSrc && (
              <motion.div initial={{ opacity: 0 }} animate={{ opacity: 1 }} className="glass rounded-2xl p-3" style={{ border: '1px solid rgba(6,182,212,.2)' }}>
                <div className="text-xs font-bold text-white mb-2">🎙️ Narration</div>
                <audio controls className="w-full rounded-xl" style={{ accentColor: 'var(--c)' }}><source src={narrateSrc} /></audio>
              </motion.div>
            )}

            {scenes.length === 0 && storyboardFrames.length === 0 && (
              <div className="glass rounded-2xl p-6 text-center" style={{ border: '1px solid rgba(236,72,153,.2)' }}>
                <div className="text-4xl mb-3">🎥</div>
                <div className="text-sm font-bold text-white mb-1">Movie Preview</div>
                <div className="text-xs opacity-50">Click "Start Full AI Movie Production" to begin — 4K animated frames appear here as they generate.</div>
              </div>
            )}

          </div>
        </div>

      </div>
    </div>
  )
}
