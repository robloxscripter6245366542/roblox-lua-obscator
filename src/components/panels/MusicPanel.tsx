import { useState } from 'react'

const MUSIC_QPS = [
  'Epic orchestral film score with rising strings and drums',
  'Lofi hip-hop chill study beats with vinyl crackle',
  'Dark electronic cyberpunk soundtrack with synth bass',
  'Upbeat pop song with catchy chorus and guitar',
  'Ambient piano meditation with nature sounds',
  'Heavy metal guitar riff with double kick drums',
  'Jazz piano trio, late night bar, warm and mellow',
  'Epic anime battle theme with choir and orchestra',
]

export default function MusicPanel() {
  const [prompt, setPrompt] = useState('')
  const [musicModel, setMusicModel] = useState('stable-audio')
  const [loading, setLoading] = useState(false)
  const [audioSrc, setAudioSrc] = useState('')
  const [error, setError] = useState('')

  const generate = async () => {
    if (!prompt.trim()) { alert('Enter a music prompt!'); return }
    setLoading(true); setError(''); setAudioSrc('')
    try {
      const r = await fetch(`https://text.pollinations.ai/${encodeURIComponent(prompt)}?model=${musicModel}`)
      if (!r.ok) throw new Error()
      const blob = await r.blob()
      setAudioSrc(URL.createObjectURL(blob))
    } catch { setError('Music generation failed. Try a different prompt.') }
    finally { setLoading(false) }
  }

  return (
    <div className="flex flex-col gap-4">
      <div className="glass rounded-2xl p-5" style={{ border: '1px solid rgba(245,158,11,.2)' }}>
        <div className="text-xs font-bold mb-3" style={{ color: 'var(--o)' }}>🎼 AI Music — Suno AI & Stable Audio 2.5 via Pollinations AI</div>
        <div className="flex gap-3 flex-wrap mb-3">
          <input value={prompt} onChange={e => setPrompt(e.target.value)}
            onKeyDown={e => e.key === 'Enter' && generate()}
            type="text" placeholder="An epic orchestral film score with rising strings, powerful drums, cinematic buildup..." className="ai-input" style={{ flex: 1, minWidth: 280 }} />
          <select value={musicModel} onChange={e => setMusicModel(e.target.value)} className="ai-select" style={{ width: 'auto' }}>
            <option value="stable-audio">Stable Audio 2.5 (Best Instrumental)</option>
            <option value="suno">Suno AI (Songs with Vocals)</option>
          </select>
          <button onClick={generate} className="px-5 py-2.5 rounded-xl font-bold text-black text-sm" style={{ background: 'linear-gradient(135deg,var(--o),var(--p))' }}>
            Generate Music →
          </button>
        </div>
        <div className="text-xs" style={{ color: 'var(--muted)' }}>
          Stable Audio 2.5: up to 190s high-quality WAV · Suno AI: full songs with lyrics and vocals
        </div>
      </div>
      <div className="glass rounded-2xl p-6" style={{ border: '1px solid rgba(255,255,255,.08)' }}>
        {loading && (
          <div className="flex items-center gap-3 py-4">
            <div className="spin" style={{ width: 28, height: 28, borderWidth: 2 }}></div>
            <div className="text-sm" style={{ color: 'var(--muted)' }}>Generating music (up to 60s)…</div>
          </div>
        )}
        {audioSrc && (
          <div>
            <div className="text-sm font-bold text-white mb-3">🎼 Generated: <span style={{ color: 'var(--o)' }}>{prompt.slice(0, 55)}…</span></div>
            <audio controls autoPlay className="w-full rounded-xl" style={{ accentColor: 'var(--o)' }}>
              <source src={audioSrc} />
            </audio>
            <div className="text-xs mt-3 opacity-50">{musicModel === 'stable-audio' ? 'Stable Audio 2.5' : 'Suno AI'} · Pollinations AI</div>
          </div>
        )}
        {error && <div className="text-center py-4"><div className="text-3xl mb-2">⚠️</div><div className="text-sm">{error}</div></div>}
        {!loading && !audioSrc && !error && (
          <div className="text-center py-4" style={{ color: 'var(--muted)' }}>
            <div className="text-4xl mb-2">🎼</div>
            <div className="text-sm">Enter a music prompt to generate a track</div>
            <div className="text-xs mt-1 opacity-50">Stable Audio 2.5 · Suno AI</div>
          </div>
        )}
      </div>
      <div className="flex gap-2 flex-wrap">
        {MUSIC_QPS.map((t, i) => (
          <button key={i} className="glass rounded-lg px-3 py-2 text-xs transition-all"
            style={{ border: '1px solid rgba(255,255,255,.08)', color: 'var(--text)' }}
            onMouseEnter={e => (e.currentTarget as HTMLElement).style.borderColor = 'rgba(245,158,11,.4)'}
            onMouseLeave={e => (e.currentTarget as HTMLElement).style.borderColor = 'rgba(255,255,255,.08)'}
            onClick={() => { setPrompt(t); generate() }}>{t}</button>
        ))}
      </div>
    </div>
  )
}
