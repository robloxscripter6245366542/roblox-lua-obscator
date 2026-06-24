import { useState, useRef } from 'react'

const VIDEO_MODELS = [
  { val: 'seedance-2.0', label: 'Seedance 2.0 (Best Quality)' },
  { val: 'veo', label: 'Veo (Google DeepMind)' },
  { val: 'seedance-pro', label: 'Seedance Pro' },
  { val: 'wan-pro-1080p', label: 'Wan Pro 1080p' },
  { val: 'grok-video-pro', label: 'Grok Video Pro' },
  { val: 'nova-reel', label: 'Nova Reel (Amazon)' },
]

const VID_EXAMPLES = [
  'A drone soaring over neon cyberpunk city at night, golden hour',
  'Ocean waves crashing at sunset, slow motion cinematic',
  'Galaxy spiral with stars forming in time-lapse, volumetric light',
  'A phoenix rising from flames, feathers trailing sparks',
  'Cherry blossom petals falling in gentle breeze, soft bokeh',
]

export default function VideoPanel() {
  const [prompt, setPrompt] = useState('')
  const [model, setModel] = useState('seedance-2.0')
  const [res, setRes] = useState('1920x1080')
  const [loading, setLoading] = useState(false)
  const [progress, setProgress] = useState(0)
  const [videoSrc, setVideoSrc] = useState('')
  const [error, setError] = useState('')
  const timerRef = useRef<number>()

  const generate = async () => {
    if (!prompt.trim()) { alert('Enter a prompt!'); return }
    setLoading(true); setError(''); setVideoSrc(''); setProgress(0)
    clearInterval(timerRef.current)
    timerRef.current = window.setInterval(() => setProgress(p => Math.min(p + 1, 88)), 1200)
    try {
      const [w, h] = res.split('x')
      // Use our server-side proxy to avoid CORS
      const r = await fetch('/api/video', {
        method: 'POST', headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({ prompt, model, duration: 5, width: parseInt(w), height: parseInt(h) }),
      })
      clearInterval(timerRef.current); setProgress(100)
      if (r.ok) {
        const ct = r.headers.get('content-type') || ''
        if (ct.includes('video') || ct.includes('octet')) {
          const blob = await r.blob()
          setVideoSrc(URL.createObjectURL(blob))
        } else {
          const d = await r.json()
          if (d.url) setVideoSrc(d.url)
          else throw new Error(d.error || 'No video URL')
        }
      } else {
        const d = await r.json().catch(() => ({}))
        throw new Error((d as any).error || `Error ${r.status}`)
      }
    } catch (e: any) {
      setError(e.message || 'Video generation failed — try again in a moment.')
    } finally { clearInterval(timerRef.current); setLoading(false) }
  }

  return (
    <div className="flex flex-col gap-4">
      <div className="glass rounded-2xl p-5 neon-p" style={{ border: '1px solid rgba(236,72,153,.2)' }}>
        <div className="text-xs font-bold mb-3" style={{ color: 'var(--p)' }}>🎬 Video Generation — Seedance 2.0, Veo, Wan Pro, Grok Video</div>
        <div className="flex gap-3 flex-wrap mb-3">
          <input value={prompt} onChange={e => setPrompt(e.target.value)}
            onKeyDown={e => e.key === 'Enter' && generate()}
            type="text" placeholder="A drone soaring over a neon cyberpunk city at golden hour..." className="ai-input" style={{ flex: 1, minWidth: 280 }} />
          <select value={model} onChange={e => setModel(e.target.value)} className="ai-select" style={{ width: 'auto' }}>
            {VIDEO_MODELS.map(m => <option key={m.val} value={m.val}>{m.label}</option>)}
          </select>
          <select value={res} onChange={e => setRes(e.target.value)} className="ai-select" style={{ width: 'auto' }}>
            <option value="1920x1080">1080p HD</option>
            <option value="3840x2160">4K Ultra HD</option>
            <option value="1280x720">720p</option>
          </select>
          <button onClick={generate} className="px-5 py-2.5 rounded-xl font-bold text-black text-sm" style={{ background: 'linear-gradient(135deg,var(--p),var(--v))' }}>Generate →</button>
        </div>
        <div className="text-xs" style={{ color: 'var(--muted)' }}>Each clip is 5 seconds · 1080p quality · Proxied through server (no CORS) · 60–120s generation time</div>
      </div>
      <div className="flex gap-4">
        <div className="flex-1 rounded-2xl flex items-center justify-center neon-p"
          style={{ aspectRatio: '16/9', minHeight: 300, background: 'rgba(255,255,255,.03)', border: '2px dashed rgba(255,255,255,.1)' }}>
          {loading && (
            <div className="text-center w-64">
              <div className="spin mx-auto mb-4"></div>
              <div className="text-sm text-white mb-2">Generating with {model}…</div>
              <div className="text-xs mb-3" style={{ color: 'var(--muted)' }}>Please wait 60–120 seconds</div>
              <div className="progress-bar"><div className="progress-fill" style={{ width: `${progress}%` }}></div></div>
            </div>
          )}
          {videoSrc && <video src={videoSrc} controls autoPlay loop style={{ width: '100%', borderRadius: 14 }} />}
          {error && <div className="text-center p-6"><div className="text-4xl mb-3">⚠️</div><div className="text-sm text-white mb-1">Generation failed</div><div className="text-xs" style={{ color: 'var(--muted)' }}>{error}</div></div>}
          {!loading && !videoSrc && !error && (
            <div className="text-center" style={{ color: 'var(--muted)' }}>
              <div className="text-5xl mb-3">🎬</div>
              <div className="text-sm">Video output appears here</div>
              <div className="text-xs mt-1 opacity-50">Seedance 2.0 · Veo · Wan Pro 1080p</div>
            </div>
          )}
        </div>
        <div className="hidden md:flex flex-col gap-2 flex-shrink-0" style={{ width: 200 }}>
          <div className="text-sm font-bold text-white mb-1">Example prompts</div>
          {VID_EXAMPLES.map((t, i) => (
            <div key={i} className="glass rounded-xl p-2.5 text-xs cursor-pointer"
              style={{ border: '1px solid rgba(255,255,255,.08)', color: 'var(--text)' }}
              onClick={() => setPrompt(t)}>{t}</div>
          ))}
        </div>
      </div>
    </div>
  )
}
