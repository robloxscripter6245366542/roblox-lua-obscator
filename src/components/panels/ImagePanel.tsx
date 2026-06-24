import { useState } from 'react'

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
          {loading && <div className="text-center"><div className="spin mx-auto mb-3"></div><div className="text-sm" style={{ color: 'var(--muted)' }}>Generating with {model}… (30–90 seconds)</div></div>}
          {imgSrc && (
            <div style={{ position: 'relative', width: '100%', height: '100%' }}>
              <img src={imgSrc} alt="Generated" style={{ width: '100%', height: '100%', objectFit: 'contain', borderRadius: 14 }} />
              <button onClick={download} style={{ position: 'absolute', top: 8, right: 8, background: 'rgba(0,0,0,.7)', border: '1px solid rgba(255,255,255,.2)', color: '#fff', padding: '4px 12px', borderRadius: 8, fontSize: 12, cursor: 'pointer', backdropFilter: 'blur(8px)' }}>⬇ Download</button>
            </div>
          )}
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
              onClick={() => { setPrompt(t); }}>
              {t}
            </div>
          ))}
        </div>
      </div>
    </div>
  )
}
