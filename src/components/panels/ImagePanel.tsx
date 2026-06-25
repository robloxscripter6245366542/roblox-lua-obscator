import { useState, useEffect, useRef } from 'react'
import { motion, AnimatePresence } from 'framer-motion'

const MODELS = [
  { val: 'flux-pro',      label: 'Flux Pro',       tag: 'Cinematic · Best Overall',        color: '#06b6d4' },
  { val: 'gptimage',      label: 'GPT Image',      tag: 'Ultra-Clean · Illustrations',     color: '#10a37f' },
  { val: 'flux-realism',  label: 'Flux Realism',   tag: 'Photorealistic · Portraits',      color: '#a78bfa' },
  { val: 'flux-anime',    label: 'Flux Anime',     tag: 'Anime · Manga · Cel-shade',       color: '#f472b6' },
  { val: 'flux-3d',       label: 'Flux 3D',        tag: '3D CGI · Renders · Models',       color: '#f59e0b' },
  { val: 'seedream',      label: 'Seedream',       tag: 'VFX · Glows · Magic',             color: '#a855f7' },
  { val: 'flux',          label: 'Flux Fast',      tag: 'Quick Draft · 5s',                color: '#64748b' },
]

const SIZES = [
  { val: '1920x1080', label: '1920×1080 — Landscape HD (Recommended)' },
  { val: '1024x1024', label: '1024×1024 — Square' },
  { val: '1080x1920', label: '1080×1920 — Portrait / Phone' },
  { val: '2048x2048', label: '2048×2048 — Large Square' },
  { val: '3840x2160', label: '3840×2160 — 4K Ultra HD' },
  { val: '1280x720',  label: '1280×720 — Widescreen' },
]

const EXAMPLES = [
  'A neon-lit cyberpunk Tokyo street at midnight, reflections on wet pavement, Blade Runner',
  'Portrait of a female samurai with flowing silver hair, bioluminescent tattoos, dramatic rim lighting',
  'Anime girl with glowing eyes and detailed hair strands, cherry blossom petals floating, studio quality',
  '3D CGI dragon with iridescent scales and glowing eyes, subsurface scattering, Unreal Engine 5',
  'Magical: glowing cherry blossom petals swirling in golden volumetric light shafts',
  'Abstract holographic 3D portal with neon rings and energy particles, hyperdetailed',
  'Futuristic spaceship hangar interior with dramatic lighting, cinematic, 4K',
  'Manga-style fight scene with speed lines, dramatic shadows, ink splash effects',
]

// Quality boosters automatically appended to every prompt
const QUALITY_BOOST = ', masterpiece, best quality, ultra-detailed, sharp focus, professional, 8K, hyperdetailed'

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
  return {
    x: Math.random() * W,
    y: type === 'spark' ? Math.random() * H : Math.random() * H * 0.8 + H * 0.1,
    vx: (Math.random() - 0.5) * 0.5,
    vy: type === 'spark' ? -(Math.random() * 0.8 + 0.2) : -(Math.random() * 0.6 + 0.1),
    size: type === 'leaf' ? Math.random() * 6 + 3 : type === 'petal' ? Math.random() * 5 + 2 : Math.random() * 2.5 + 0.5,
    alpha: Math.random() * 0.5 + 0.15,
    color: colors[type][Math.floor(Math.random() * colors[type].length)],
    wobble: Math.random() * Math.PI * 2,
    wobbleSpeed: (Math.random() - 0.5) * 0.04,
    wobbleAmp: Math.random() * 1.5 + 0.3,
    type,
  }
}

function LivingPainting({ src, onDownload, modelLabel }: { src: string; onDownload: () => void; modelLabel?: string }) {
  const canvasRef = useRef<HTMLCanvasElement>(null)
  const wrapRef = useRef<HTMLDivElement>(null)

  useEffect(() => {
    const canvas = canvasRef.current
    const wrap = wrapRef.current
    if (!canvas || !wrap) return
    const ctx = canvas.getContext('2d')
    if (!ctx) return
    const resize = () => { canvas.width = wrap.clientWidth || 600; canvas.height = wrap.clientHeight || 420 }
    requestAnimationFrame(resize)
    window.addEventListener('resize', resize)
    const W = () => canvas.width || 600
    const H = () => canvas.height || 420
    const particles: LiveParticle[] = Array.from({ length: 55 }, () => makeLiveParticle(W(), H()))
    let frame = 0
    const handle = { raf: 0 }

    const draw = () => {
      ctx.clearRect(0, 0, W(), H())
      frame++
      if (frame % 300 < 60) {
        const prog = (frame % 300) / 60
        const shimX = -W() * 0.3 + prog * W() * 1.6
        const shimGrad = ctx.createLinearGradient(shimX, 0, shimX + W() * 0.25, H())
        shimGrad.addColorStop(0, 'rgba(255,255,220,0)')
        shimGrad.addColorStop(0.5, 'rgba(255,255,220,0.06)')
        shimGrad.addColorStop(1, 'rgba(255,255,220,0)')
        ctx.fillStyle = shimGrad; ctx.fillRect(0, 0, W(), H())
      }
      const flickerAlpha = 0.04 + Math.sin(frame * 0.07) * 0.02
      const groundGlow = ctx.createRadialGradient(W() * 0.5, H() * 0.9, 0, W() * 0.5, H() * 0.9, W() * 0.5)
      groundGlow.addColorStop(0, `rgba(255,180,60,${flickerAlpha})`); groundGlow.addColorStop(1, 'rgba(255,140,0,0)')
      ctx.fillStyle = groundGlow; ctx.fillRect(0, 0, W(), H())
      for (const p of particles) {
        p.x += p.vx + Math.sin(p.wobble) * p.wobbleAmp; p.y += p.vy; p.wobble += p.wobbleSpeed
        if (p.y < -20 || p.x < -30 || p.x > W() + 30) Object.assign(p, makeLiveParticle(W(), H()), { y: H() + 10 })
        ctx.globalAlpha = p.alpha * (0.6 + Math.sin(frame * 0.025 + p.wobble) * 0.4)
        if (p.type === 'leaf') {
          ctx.save(); ctx.translate(p.x, p.y); ctx.rotate(p.wobble * 2); ctx.scale(1, 0.5)
          ctx.beginPath(); ctx.ellipse(0, 0, p.size, p.size * 2.2, 0, 0, Math.PI * 2); ctx.fillStyle = p.color; ctx.fill()
          ctx.beginPath(); ctx.moveTo(0, -p.size * 2.2); ctx.lineTo(0, p.size * 2.2); ctx.strokeStyle = 'rgba(0,80,0,0.3)'; ctx.lineWidth = 0.5; ctx.stroke(); ctx.restore()
        } else if (p.type === 'petal') {
          ctx.save(); ctx.translate(p.x, p.y); ctx.rotate(p.wobble * 3)
          ctx.beginPath(); ctx.ellipse(0, 0, p.size * 0.4, p.size, 0, 0, Math.PI * 2); ctx.fillStyle = p.color; ctx.shadowColor = '#ff85a2'; ctx.shadowBlur = 4; ctx.fill(); ctx.restore()
        } else if (p.type === 'spark') {
          ctx.beginPath(); ctx.arc(p.x, p.y, p.size, 0, Math.PI * 2); ctx.fillStyle = p.color; ctx.shadowColor = p.color; ctx.shadowBlur = 6; ctx.fill(); ctx.shadowBlur = 0
        } else {
          ctx.beginPath(); ctx.arc(p.x, p.y, p.size, 0, Math.PI * 2); ctx.fillStyle = p.color; ctx.fill()
        }
      }
      ctx.globalAlpha = 1; handle.raf = requestAnimationFrame(draw)
    }
    handle.raf = requestAnimationFrame(draw)
    return () => { cancelAnimationFrame(handle.raf); window.removeEventListener('resize', resize) }
  }, [src])

  return (
    <div ref={wrapRef} style={{ position: 'relative', width: '100%', height: '100%', overflow: 'hidden', borderRadius: 14 }}>
      <img src={src} alt="Generated" style={{ width: '100%', height: '100%', objectFit: 'contain', borderRadius: 14, display: 'block', animation: 'imgFloat 10s ease-in-out infinite', transformOrigin: 'center center' }} />
      <canvas ref={canvasRef} style={{ position: 'absolute', inset: 0, width: '100%', height: '100%', pointerEvents: 'none', borderRadius: 14 }} />
      <div style={{ position: 'absolute', inset: 0, borderRadius: 14, pointerEvents: 'none', background: 'radial-gradient(ellipse at center, transparent 50%, rgba(0,0,0,0.35) 100%)' }} />
      <button onClick={onDownload} style={{ position: 'absolute', top: 10, right: 10, background: 'rgba(0,0,0,.72)', border: '1px solid rgba(255,255,255,.2)', color: '#fff', padding: '5px 14px', borderRadius: 8, fontSize: 12, cursor: 'pointer', backdropFilter: 'blur(10px)', zIndex: 2 }}>⬇ Download</button>
      <div style={{ position: 'absolute', bottom: 10, left: 10, background: 'rgba(0,0,0,.65)', border: '1px solid rgba(255,200,100,.25)', color: 'rgba(255,220,120,.9)', padding: '3px 10px', borderRadius: 8, fontSize: 11, backdropFilter: 'blur(8px)', zIndex: 2 }}>
        🎨 {modelLabel || 'Living Painting'}
      </div>
    </div>
  )
}

// Single model battle card
function BattleCard({ model, prompt, size, seed, onSelect }: {
  model: typeof MODELS[0]; prompt: string; size: string; seed: number; onSelect: (url: string) => void
}) {
  const [state, setState] = useState<'loading' | 'done' | 'error'>('loading')
  const [url, setUrl] = useState('')
  const [loadTime, setLoadTime] = useState(0)
  const startRef = useRef(Date.now())

  useEffect(() => {
    const [w, h] = size.split('x')
    startRef.current = Date.now()
    const imgUrl = `https://image.pollinations.ai/prompt/${encodeURIComponent(prompt + QUALITY_BOOST)}?model=${model.val}&width=${w}&height=${h}&enhance=true&nologo=true&seed=${seed}`
    const img = new window.Image()
    img.onload = () => { setUrl(imgUrl); setState('done'); setLoadTime(Math.round((Date.now() - startRef.current) / 1000)) }
    img.onerror = () => setState('error')
    img.src = imgUrl
  }, [prompt, model.val, size, seed])

  return (
    <motion.div
      initial={{ opacity: 0, scale: .95 }} animate={{ opacity: 1, scale: 1 }}
      className="glass rounded-xl overflow-hidden"
      style={{ border: `1px solid ${model.color}30`, position: 'relative' }}>
      <div className="flex items-center justify-between px-3 py-2" style={{ borderBottom: `1px solid ${model.color}20`, background: `${model.color}10` }}>
        <div>
          <span className="font-bold text-white text-xs">{model.label}</span>
          <span className="text-xs ml-2" style={{ color: model.color }}>{model.tag}</span>
        </div>
        {state === 'done' && <span className="text-xs opacity-40">{loadTime}s</span>}
      </div>
      <div style={{ height: 220, background: 'rgba(0,0,0,.4)', position: 'relative' }}>
        {state === 'loading' && (
          <div className="flex flex-col items-center justify-center h-full gap-2">
            <div className="spin" style={{ width: 24, height: 24, borderWidth: 2, borderColor: model.color }}></div>
            <div className="text-xs opacity-40">Generating…</div>
          </div>
        )}
        {state === 'done' && (
          <>
            <img src={url} alt={model.label} style={{ width: '100%', height: '100%', objectFit: 'cover', display: 'block' }} />
            <div style={{ position: 'absolute', inset: 0, background: 'linear-gradient(to top, rgba(0,0,0,.6) 0%, transparent 60%)', pointerEvents: 'none' }} />
            <button onClick={() => onSelect(url)}
              className="absolute bottom-2 left-1/2 font-bold text-xs px-4 py-1.5 rounded-lg"
              style={{ transform: 'translateX(-50%)', background: model.color, color: '#000', opacity: .9 }}>
              ✓ Use This
            </button>
          </>
        )}
        {state === 'error' && (
          <div className="flex items-center justify-center h-full text-xs opacity-40">Generation failed</div>
        )}
      </div>
    </motion.div>
  )
}

export default function ImagePanel() {
  const [prompt, setPrompt] = useState('')
  const [model, setModel] = useState('flux-pro')
  const [size, setSize] = useState('1920x1080')
  const [loading, setLoading] = useState(false)
  const [imgSrc, setImgSrc] = useState('')
  const [directUrl, setDirectUrl] = useState('')
  const [error, setError] = useState('')
  const [battleMode, setBattleMode] = useState(false)
  const [battleSeed, setBattleSeed] = useState(0)
  const [selectedModel, setSelectedModel] = useState('')

  const generate = () => {
    if (!prompt.trim()) { alert('Enter a prompt!'); return }
    const [w, h] = size.split('x')
    setLoading(true); setError(''); setImgSrc(''); setDirectUrl(''); setBattleMode(false)
    const seed = Math.floor(Math.random() * 99999)
    const url = `https://image.pollinations.ai/prompt/${encodeURIComponent(prompt.trim() + QUALITY_BOOST)}?model=${model}&width=${w}&height=${h}&enhance=true&nologo=true&seed=${seed}`
    setDirectUrl(url)
    const img = new window.Image()
    img.onload = () => { setImgSrc(url); setLoading(false) }
    img.onerror = () => { setError('Generation failed — try a different model or prompt.'); setLoading(false) }
    img.src = url
  }

  const renderAll = () => {
    if (!prompt.trim()) { alert('Enter a prompt first!'); return }
    setLoading(false); setImgSrc(''); setError(''); setDirectUrl('')
    setBattleSeed(Math.floor(Math.random() * 99999))
    setBattleMode(true)
    setSelectedModel('')
  }

  const handleBattleSelect = (url: string, modelVal: string) => {
    setImgSrc(url); setDirectUrl(url); setSelectedModel(modelVal); setBattleMode(false)
  }

  const download = async () => {
    if (!directUrl) return
    try {
      const r = await fetch('/api/image', {
        method: 'POST', headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({ prompt: prompt.trim() + QUALITY_BOOST, model: selectedModel || model, width: parseInt(size.split('x')[0]), height: parseInt(size.split('x')[1]) }),
      })
      if (!r.ok) throw new Error()
      const blob = await r.blob()
      const a = document.createElement('a'); a.href = URL.createObjectURL(blob); a.download = `omni-ai-${selectedModel || model}.png`; a.click()
      setTimeout(() => URL.revokeObjectURL(a.href), 10000)
    } catch { window.open(directUrl, '_blank') }
  }

  const modelInfo = MODELS.find(m => m.val === (selectedModel || model))

  return (
    <div className="flex flex-col gap-4">
      {/* Controls */}
      <div className="glass rounded-2xl p-4" style={{ border: '1px solid rgba(6,182,212,.15)' }}>
        <div className="flex gap-2 mb-3 flex-wrap">
          <input value={prompt} onChange={e => setPrompt(e.target.value)}
            onKeyDown={e => e.key === 'Enter' && generate()}
            type="text" placeholder="Describe anything — the AI enhances your prompt automatically…" className="ai-input" style={{ flex: 1, minWidth: 280 }} />
        </div>
        <div className="flex gap-2 flex-wrap items-end">
          <select value={model} onChange={e => setModel(e.target.value)} className="ai-select" style={{ flex: '1 1 200px' }}>
            {MODELS.map(m => <option key={m.val} value={m.val}>{m.label} — {m.tag}</option>)}
          </select>
          <select value={size} onChange={e => setSize(e.target.value)} className="ai-select" style={{ flex: '1 1 200px' }}>
            {SIZES.map(s => <option key={s.val} value={s.val}>{s.label}</option>)}
          </select>
          <button onClick={generate} disabled={loading}
            className="px-5 py-2.5 rounded-xl font-bold text-black text-sm"
            style={{ background: loading ? 'rgba(100,100,100,.5)' : 'linear-gradient(135deg,var(--c),var(--v))', cursor: loading ? 'not-allowed' : 'pointer' }}>
            {loading ? '⏳ Generating…' : '→ Generate'}
          </button>
          <button onClick={renderAll}
            className="px-5 py-2.5 rounded-xl font-bold text-sm"
            style={{ background: 'linear-gradient(135deg,#f59e0b,#ec4899,#8b5cf6)', color: '#000' }}>
            🏆 Render ALL 7 Models
          </button>
        </div>
        <div className="text-xs mt-2 opacity-40">✨ AI auto-enhances every prompt · enhance=true · nologo · 4K quality booster injected</div>
      </div>

      {/* Main output */}
      <div className="flex gap-4" style={{ alignItems: 'flex-start' }}>
        <div style={{ flex: 1, minWidth: 0 }}>
          {/* Single result */}
          <AnimatePresence>
            {(loading || imgSrc || error) && !battleMode && (
              <motion.div initial={{ opacity: 0, y: 12 }} animate={{ opacity: 1, y: 0 }} className="rounded-2xl overflow-hidden" style={{ height: 460, background: 'rgba(255,255,255,.03)', border: '2px solid rgba(6,182,212,.15)' }}>
                {loading && <div className="flex flex-col items-center justify-center h-full gap-3"><div className="spin mx-auto" style={{ width: 32, height: 32, borderWidth: 3 }}></div><div className="text-sm opacity-50">Generating with {model}… (30–90s)</div></div>}
                {imgSrc && <LivingPainting src={imgSrc} onDownload={download} modelLabel={modelInfo?.label + ' · ' + modelInfo?.tag} />}
                {error && <div className="flex flex-col items-center justify-center h-full gap-3"><div className="text-4xl">⚠️</div><div className="text-sm">{error}</div></div>}
              </motion.div>
            )}
          </AnimatePresence>

          {/* Battle mode — all 7 models */}
          <AnimatePresence>
            {battleMode && (
              <motion.div initial={{ opacity: 0 }} animate={{ opacity: 1 }}>
                <div className="flex items-center justify-between mb-3">
                  <div className="font-bold text-white">🏆 All 7 Models — Best Graphics Battle</div>
                  <div className="text-xs opacity-50">All rendering in parallel · click "Use This" to select winner</div>
                </div>
                <div className="grid gap-3" style={{ gridTemplateColumns: 'repeat(4, 1fr)' }}>
                  {MODELS.map(m => (
                    <BattleCard key={m.val} model={m} prompt={prompt.trim()} size={size} seed={battleSeed}
                      onSelect={(url) => handleBattleSelect(url, m.val)} />
                  ))}
                </div>
              </motion.div>
            )}
          </AnimatePresence>

          {/* Empty state */}
          {!loading && !imgSrc && !error && !battleMode && (
            <div className="rounded-2xl flex flex-col items-center justify-center" style={{ height: 460, background: 'rgba(255,255,255,.03)', border: '2px dashed rgba(255,255,255,.08)' }}>
              <div className="text-6xl mb-4">🎨</div>
              <div className="text-base font-bold text-white mb-1">World-class AI image generation</div>
              <div className="text-sm opacity-50 mb-4">Flux Pro · GPT Image · Flux Realism · Flux Anime · Flux 3D · Seedream</div>
              <button onClick={renderAll} className="px-6 py-3 rounded-xl font-bold text-sm"
                style={{ background: 'linear-gradient(135deg,#f59e0b,#ec4899,#8b5cf6)', color: '#000' }}>
                🏆 Try All 7 Models At Once
              </button>
            </div>
          )}
        </div>

        {/* Examples sidebar */}
        <div className="hidden md:flex flex-col gap-2 flex-shrink-0" style={{ width: 240 }}>
          <div className="text-sm font-bold text-white mb-1">Example Prompts</div>
          {EXAMPLES.map((t, i) => (
            <div key={i} className="glass rounded-xl p-2.5 text-xs cursor-pointer transition-all"
              style={{ border: '1px solid rgba(255,255,255,.08)', color: 'var(--text)', lineHeight: 1.5 }}
              onMouseEnter={e => (e.currentTarget as HTMLElement).style.borderColor = 'rgba(6,182,212,.4)'}
              onMouseLeave={e => (e.currentTarget as HTMLElement).style.borderColor = 'rgba(255,255,255,.08)'}
              onClick={() => setPrompt(t)}>
              {t}
            </div>
          ))}
          <div className="mt-2 glass rounded-xl p-3" style={{ border: '1px solid rgba(255,255,255,.06)' }}>
            <div className="text-xs font-bold text-white mb-1.5">Quality Tips</div>
            {[
              '🏆 Render All 7 — pick the winner',
              '🔍 enhance=true is always on',
              '📐 1920×1080 for cinematic shots',
              '🎌 Flux Anime for manga/anime',
              '👤 Flux Realism for portraits',
              '✨ Seedream for VFX/magic',
            ].map((tip, i) => <div key={i} className="text-xs opacity-50 mb-1">{tip}</div>)}
          </div>
        </div>
      </div>
    </div>
  )
}
