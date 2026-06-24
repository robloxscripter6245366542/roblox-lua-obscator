import { useState, useEffect, useRef } from 'react'

const MODELS = [
  { val: 'flux-pro', label: 'Flux Pro — Cinematic / Best Overall' },
  { val: 'flux-realism', label: 'Flux Realism — Characters / Hair Detail' },
  { val: 'flux-anime', label: 'Flux Anime — Anime / Manga Style' },
  { val: 'flux-3d', label: 'Flux 3D — 3D Models / CGI Renders' },
  { val: 'gptimage', label: 'GPT Image — Graphics / Logos / Art' },
  { val: 'seedream', label: 'Seedream — VFX / Glows / Magic Effects' },
  { val: 'flux', label: 'Flux Standard — Fast Draft' },
]

const SIZES = [
  { val: '1024x1024', label: 'Square 1024px' },
  { val: '1920x1080', label: 'Landscape 1920×1080' },
  { val: '1080x1920', label: 'Portrait 1080×1920' },
  { val: '2048x2048', label: 'Large 2048px' },
  { val: '3840x2160', label: '4K Ultra 3840×2160' },
]

const EXAMPLES = [
  'A neon-lit cyberpunk Tokyo street at midnight, Blade Runner aesthetic',
  'Portrait of a female warrior with flowing silver hair, bioluminescent tattoos, cinematic',
  'Anime character with glowing blue eyes and detailed hair strands, studio quality',
  '3D CGI rendered dragon with iridescent scales, subsurface scattering',
  'Magical VFX: glowing cherry blossom petals swirling in golden light',
  'Abstract holographic 3D geometric portal with neon light rings',
]

// Particle types for the living painting overlay
interface LiveParticle {
  x: number; y: number; vx: number; vy: number
  size: number; alpha: number; color: string
  wobble: number; wobbleSpeed: number; wobbleAmp: number
  type: 'dust' | 'leaf' | 'petal' | 'spark'
}

function makeLiveParticle(W: number, H: number): LiveParticle {
  const types: LiveParticle['type'][] = ['dust', 'leaf', 'petal', 'spark']
  const type = types[Math.floor(Math.random() * types.length)]
  const colors = {
    dust:  ['#fffde0', '#fff8c0', '#f0e8c0'],
    leaf:  ['#5a9e4a', '#7ec850', '#4d7a3a', '#a8d880'],
    petal: ['#ffb7c5', '#ff85a2', '#ffd6e0', '#ff69b4'],
    spark: ['#ffd700', '#fff8dc', '#ffe680', '#ffffff'],
  }
  const palette = colors[type]
  return {
    x: Math.random() * W,
    y: type === 'spark' ? Math.random() * H : Math.random() * H * 0.8 + H * 0.1,
    vx: (Math.random() - 0.5) * 0.5,
    vy: type === 'spark' ? -(Math.random() * 0.8 + 0.2) : -(Math.random() * 0.6 + 0.1),
    size: type === 'leaf' ? Math.random() * 6 + 3 : type === 'petal' ? Math.random() * 5 + 2 : Math.random() * 2.5 + 0.5,
    alpha: Math.random() * 0.5 + 0.15,
    color: palette[Math.floor(Math.random() * palette.length)],
    wobble: Math.random() * Math.PI * 2,
    wobbleSpeed: (Math.random() - 0.5) * 0.04,
    wobbleAmp: Math.random() * 1.5 + 0.3,
    type,
  }
}

function LivingPainting({ src, onDownload }: { src: string; onDownload: () => void }) {
  const canvasRef = useRef<HTMLCanvasElement>(null)

  useEffect(() => {
    const canvas = canvasRef.current
    if (!canvas) return
    const ctx = canvas.getContext('2d')
    if (!ctx) return

    const resize = () => {
      canvas.width = canvas.offsetWidth
      canvas.height = canvas.offsetHeight
    }
    resize()

    const W = () => canvas.width
    const H = () => canvas.height

    const particles: LiveParticle[] = Array.from({ length: 55 }, () => makeLiveParticle(W(), H()))
    let frame = 0
    const handle = { raf: 0 }

    const drawLeaf = (ctx: CanvasRenderingContext2D, p: LiveParticle) => {
      ctx.save()
      ctx.translate(p.x, p.y)
      ctx.rotate(p.wobble * 2)
      ctx.scale(1, 0.5)
      ctx.beginPath()
      ctx.ellipse(0, 0, p.size, p.size * 2.2, 0, 0, Math.PI * 2)
      ctx.fillStyle = p.color
      ctx.globalAlpha = p.alpha
      ctx.fill()
      // vein
      ctx.beginPath()
      ctx.moveTo(0, -p.size * 2.2)
      ctx.lineTo(0, p.size * 2.2)
      ctx.strokeStyle = 'rgba(0,80,0,0.3)'
      ctx.lineWidth = 0.5
      ctx.stroke()
      ctx.restore()
    }

    const drawPetal = (ctx: CanvasRenderingContext2D, p: LiveParticle) => {
      ctx.save()
      ctx.translate(p.x, p.y)
      ctx.rotate(p.wobble * 3)
      ctx.beginPath()
      ctx.ellipse(0, 0, p.size * 0.4, p.size, 0, 0, Math.PI * 2)
      ctx.fillStyle = p.color
      ctx.globalAlpha = p.alpha
      ctx.shadowColor = '#ff85a2'
      ctx.shadowBlur = 4
      ctx.fill()
      ctx.restore()
    }

    const draw = () => {
      ctx.clearRect(0, 0, W(), H())
      frame++

      // Subtle light shimmer sweep
      if (frame % 300 < 60) {
        const prog = (frame % 300) / 60
        const shimX = -W() * 0.3 + prog * W() * 1.6
        const shimGrad = ctx.createLinearGradient(shimX, 0, shimX + W() * 0.25, H())
        shimGrad.addColorStop(0, 'rgba(255,255,220,0)')
        shimGrad.addColorStop(0.5, 'rgba(255,255,220,0.06)')
        shimGrad.addColorStop(1, 'rgba(255,255,220,0)')
        ctx.fillStyle = shimGrad
        ctx.fillRect(0, 0, W(), H())
      }

      // Bottom warm glow (ground heat / candlelight flicker)
      const flickerAlpha = 0.04 + Math.sin(frame * 0.07) * 0.02
      const groundGlow = ctx.createRadialGradient(W() * 0.5, H() * 0.9, 0, W() * 0.5, H() * 0.9, W() * 0.5)
      groundGlow.addColorStop(0, `rgba(255,180,60,${flickerAlpha})`)
      groundGlow.addColorStop(1, 'rgba(255,140,0,0)')
      ctx.fillStyle = groundGlow
      ctx.fillRect(0, 0, W(), H())

      for (const p of particles) {
        p.x += p.vx + Math.sin(p.wobble) * p.wobbleAmp
        p.y += p.vy
        p.wobble += p.wobbleSpeed

        // Respawn at bottom when drifted off top
        if (p.y < -20 || p.x < -30 || p.x > W() + 30) {
          const fresh = makeLiveParticle(W(), H())
          Object.assign(p, fresh, { y: H() + 10 })
        }

        ctx.globalAlpha = p.alpha * (0.6 + Math.sin(frame * 0.025 + p.wobble) * 0.4)

        if (p.type === 'leaf') { drawLeaf(ctx, p); continue }
        if (p.type === 'petal') { drawPetal(ctx, p); continue }
        if (p.type === 'spark') {
          // Tiny glowing spark
          ctx.beginPath()
          ctx.arc(p.x, p.y, p.size, 0, Math.PI * 2)
          ctx.fillStyle = p.color
          ctx.shadowColor = p.color
          ctx.shadowBlur = 6
          ctx.fill()
          ctx.shadowBlur = 0
        } else {
          // dust mote
          ctx.beginPath()
          ctx.arc(p.x, p.y, p.size, 0, Math.PI * 2)
          ctx.fillStyle = p.color
          ctx.fill()
        }
      }

      ctx.globalAlpha = 1
      handle.raf = requestAnimationFrame(draw)
    }

    handle.raf = requestAnimationFrame(draw)
    window.addEventListener('resize', resize)
    return () => { cancelAnimationFrame(handle.raf); window.removeEventListener('resize', resize) }
  }, [src])

  return (
    <div style={{ position: 'relative', width: '100%', height: '100%', minHeight: 420, overflow: 'hidden', borderRadius: 14 }}>
      {/* Painting with gentle float + breathe */}
      <img
        src={src}
        alt="Generated"
        style={{
          width: '100%', height: '100%', objectFit: 'contain', borderRadius: 14, display: 'block',
          animation: 'imgFloat 10s ease-in-out infinite',
          transformOrigin: 'center center',
        }}
      />
      {/* Living particle overlay: leaves, petals, dust, sparks */}
      <canvas
        ref={canvasRef}
        style={{ position: 'absolute', inset: 0, width: '100%', height: '100%', pointerEvents: 'none', borderRadius: 14 }}
      />
      {/* Vignette to make particles feel embedded in the scene */}
      <div style={{
        position: 'absolute', inset: 0, borderRadius: 14, pointerEvents: 'none',
        background: 'radial-gradient(ellipse at center, transparent 50%, rgba(0,0,0,0.35) 100%)',
      }} />
      {/* Download button */}
      <button
        onClick={onDownload}
        style={{ position: 'absolute', top: 10, right: 10, background: 'rgba(0,0,0,.72)', border: '1px solid rgba(255,255,255,.2)', color: '#fff', padding: '5px 14px', borderRadius: 8, fontSize: 12, cursor: 'pointer', backdropFilter: 'blur(10px)', zIndex: 2 }}
      >
        ⬇ Download
      </button>
      {/* "Living painting" badge */}
      <div style={{ position: 'absolute', bottom: 10, left: 10, background: 'rgba(0,0,0,.65)', border: '1px solid rgba(255,200,100,.25)', color: 'rgba(255,220,120,.9)', padding: '3px 10px', borderRadius: 8, fontSize: 11, backdropFilter: 'blur(8px)', zIndex: 2 }}>
        🎨 Living Painting
      </div>
    </div>
  )
}

export default function ImagePanel() {
  const [prompt, setPrompt] = useState('')
  const [model, setModel] = useState('flux-pro')
  const [size, setSize] = useState('1024x1024')
  const [loading, setLoading] = useState(false)
  const [imgSrc, setImgSrc] = useState('')
  const [directUrl, setDirectUrl] = useState('')
  const [error, setError] = useState('')

  const generate = () => {
    if (!prompt.trim()) { alert('Enter a prompt!'); return }
    const [w, h] = size.split('x')
    setLoading(true); setError(''); setImgSrc(''); setDirectUrl('')
    const seed = Math.floor(Math.random() * 99999)
    const url = `https://image.pollinations.ai/prompt/${encodeURIComponent(prompt.trim())}?model=${model}&width=${w}&height=${h}&enhance=true&nologo=true&seed=${seed}`
    setDirectUrl(url)
    const img = new window.Image()
    img.onload = () => { setImgSrc(url); setLoading(false) }
    img.onerror = () => { setError('Generation failed — try a different model or prompt.'); setLoading(false) }
    img.src = url
  }

  const download = async () => {
    if (!directUrl) return
    try {
      const r = await fetch('/api/image', {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({ prompt: prompt.trim(), model, width: parseInt(size.split('x')[0]), height: parseInt(size.split('x')[1]) }),
      })
      if (!r.ok) throw new Error()
      const blob = await r.blob()
      const a = document.createElement('a')
      a.href = URL.createObjectURL(blob)
      a.download = `generated-${model}.png`
      a.click()
      setTimeout(() => URL.revokeObjectURL(a.href), 10000)
    } catch { window.open(directUrl, '_blank') }
  }

  return (
    <div className="flex flex-col gap-4">
      <div className="flex gap-3 flex-wrap items-end">
        <input value={prompt} onChange={e => setPrompt(e.target.value)}
          onKeyDown={e => e.key === 'Enter' && generate()}
          type="text" placeholder="A cyberpunk city at midnight with neon reflections..." className="ai-input" style={{ flex: 1, minWidth: 280 }} />
        <select value={model} onChange={e => setModel(e.target.value)} className="ai-select" style={{ width: 'auto' }}>
          {MODELS.map(m => <option key={m.val} value={m.val}>{m.label}</option>)}
        </select>
        <select value={size} onChange={e => setSize(e.target.value)} className="ai-select" style={{ width: 'auto' }}>
          {SIZES.map(s => <option key={s.val} value={s.val}>{s.label}</option>)}
        </select>
        <button onClick={generate} className="px-5 py-2.5 rounded-xl font-bold text-black text-sm transition-all hover:scale-105" style={{ background: 'linear-gradient(135deg,var(--c),var(--v))' }}>Generate →</button>
      </div>
      <div className="flex gap-4" style={{ flexDirection: 'row' }}>
        <div className="flex-1 rounded-2xl overflow-hidden flex items-center justify-center neon-c"
          style={{ minHeight: 420, background: 'rgba(255,255,255,.03)', border: '2px dashed rgba(255,255,255,.1)' }}>
          {loading && (
            <div className="text-center">
              <div className="spin mx-auto mb-3"></div>
              <div className="text-sm" style={{ color: 'var(--muted)' }}>Generating with {model}… (30–90 seconds)</div>
            </div>
          )}
          {imgSrc && <LivingPainting src={imgSrc} onDownload={download} />}
          {error && <div className="text-center p-6"><div className="text-4xl mb-3">⚠️</div><div className="text-sm">{error}</div></div>}
          {!loading && !imgSrc && !error && (
            <div className="text-center" style={{ color: 'var(--muted)' }}>
              <div className="text-5xl mb-3">🖼️</div>
              <div className="text-sm">Enter a prompt and generate</div>
              <div className="text-xs mt-1 opacity-50">Flux Pro · Flux Realism · Flux Anime · Flux 3D · Seedream</div>
            </div>
          )}
        </div>
        <div className="hidden md:flex flex-col gap-2 flex-shrink-0" style={{ width: 220 }}>
          <div className="text-sm font-bold text-white mb-1">Examples</div>
          {EXAMPLES.map((t, i) => (
            <div key={i} className="glass rounded-xl p-2.5 text-xs cursor-pointer transition-all"
              style={{ border: '1px solid rgba(255,255,255,.08)', color: 'var(--text)' }}
              onMouseEnter={e => (e.currentTarget as HTMLElement).style.borderColor = 'rgba(6,182,212,.4)'}
              onMouseLeave={e => (e.currentTarget as HTMLElement).style.borderColor = 'rgba(255,255,255,.08)'}
              onClick={() => setPrompt(t)}>
              {t}
            </div>
          ))}
        </div>
      </div>
    </div>
  )
}
