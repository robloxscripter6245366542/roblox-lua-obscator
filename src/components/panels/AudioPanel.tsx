import { useState } from 'react'

const VOICES = [
  { val: 'nova', label: 'Nova — Warm Female' },
  { val: 'alloy', label: 'Alloy — Neutral' },
  { val: 'echo', label: 'Echo — Deep Male' },
  { val: 'fable', label: 'Fable — British' },
  { val: 'onyx', label: 'Onyx — Strong Male' },
  { val: 'shimmer', label: 'Shimmer — Clear Female' },
  { val: 'coral', label: 'Coral — Warm' },
  { val: 'sage', label: 'Sage — Calm' },
]

export default function AudioPanel() {
  const [text, setText] = useState('')
  const [voice, setVoice] = useState('nova')
  const [loading, setLoading] = useState(false)
  const [audioSrc, setAudioSrc] = useState('')
  const [error, setError] = useState('')

  const generate = async () => {
    if (!text.trim()) { alert('Enter some text!'); return }
    setLoading(true); setError('')
    setAudioSrc(prev => { if (prev) URL.revokeObjectURL(prev); return '' })
    try {
      const r = await fetch('/api/audio', {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({ text: text.trim(), voice }),
      })
      if (!r.ok) throw new Error(await r.text())
      const blob = await r.blob()
      setAudioSrc(URL.createObjectURL(blob))
    } catch { setError('Speech generation failed. Try shorter text or a different voice.') }
    finally { setLoading(false) }
  }

  return (
    <div className="flex flex-col gap-4">
      <div className="glass rounded-2xl p-5 neon-g" style={{ border: '1px solid rgba(16,185,129,.2)' }}>
        <div className="text-xs font-bold mb-3" style={{ color: 'var(--g)' }}>🎵 Text-to-Speech — ElevenLabs & OpenAI voices via Pollinations AI</div>
        <div className="flex gap-3 mb-3">
          <textarea value={text} onChange={e => setText(e.target.value)} rows={3}
            placeholder="Type any text here and it will be spoken aloud in the chosen voice..." className="ai-input flex-1" style={{ resize: 'none' }} />
          <div className="flex flex-col gap-2 flex-shrink-0">
            <select value={voice} onChange={e => setVoice(e.target.value)} className="ai-select">
              {VOICES.map(v => <option key={v.val} value={v.val}>{v.label}</option>)}
            </select>
            <button onClick={generate} className="px-5 py-2.5 rounded-xl font-bold text-black text-sm" style={{ background: 'linear-gradient(135deg,var(--g),var(--c))' }}>
              Generate Speech →
            </button>
          </div>
        </div>
      </div>
      <div className="glass rounded-2xl p-6" style={{ border: '1px solid rgba(255,255,255,.08)' }}>
        {loading && <div className="flex justify-center py-4"><div className="spin"></div></div>}
        {audioSrc && (
          <div>
            <div className="text-sm font-bold text-white mb-3">🎵 Voice: <span style={{ color: 'var(--g)' }}>{voice}</span></div>
            <audio controls autoPlay className="w-full rounded-xl" style={{ accentColor: 'var(--v)' }}>
              <source src={audioSrc} />
            </audio>
            <div className="text-xs mt-3 opacity-50">ElevenLabs & OpenAI voices · Pollinations AI</div>
          </div>
        )}
        {error && <div className="text-center py-4"><div className="text-3xl mb-2">⚠️</div><div className="text-sm">{error}</div></div>}
        {!loading && !audioSrc && !error && (
          <div className="text-center py-4" style={{ color: 'var(--muted)' }}>
            <div className="text-4xl mb-2">🎵</div>
            <div className="text-sm">Enter text above to generate speech</div>
            <div className="text-xs mt-1 opacity-50">ElevenLabs voices · OpenAI voices · Pollinations AI</div>
          </div>
        )}
      </div>
    </div>
  )
}
