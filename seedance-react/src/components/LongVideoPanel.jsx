import { useState, useRef } from 'react'
import { StopCircle, PlayCircle } from 'lucide-react'
import clsx from 'clsx'
import { generateDemo } from '../lib/seedance.js'

const TARGET_OPTS = [
  { value: 1, label: '1 min' }, { value: 5, label: '5 min' },
  { value: 10, label: '10 min' }, { value: 30, label: '30 min' },
]
const CLIP_OPTS = [
  { value: 5, label: '5s' }, { value: 10, label: '10s' }, { value: 15, label: '15s MAX' },
]
const STATUS_COLORS = { pending: '#555872', running: '#f59e0b', done: '#10b981', failed: '#ef4444' }
const STATUS_LABELS = { pending: 'Queued', running: 'Generating…', done: 'Done ✓', failed: 'Failed' }

export default function LongVideoPanel({ settings, onToast, timer, apiKey, onClipDone }) {
  const [prompt, setPrompt] = useState('')
  const [targetMin, setTargetMin] = useState(10)
  const [clipSecs, setClipSecs] = useState(15)
  const [clips, setClips] = useState([])
  const [running, setRunning] = useState(false)
  const [overall, setOverall] = useState(0)
  const abortRef = useRef(false)

  const totalClips = Math.ceil((targetMin * 60) / clipSecs)

  async function start() {
    if (!prompt.trim()) { onToast('Please enter a story prompt', 'error'); return }
    if (!timer.running) timer.start()
    abortRef.current = false
    setRunning(true)
    setOverall(0)

    const initial = Array.from({ length: totalClips }, (_, i) => ({
      i, status: 'pending', url: null,
    }))
    setClips(initial)

    for (let idx = 0; idx < totalClips; idx++) {
      if (abortRef.current) break
      setClips(c => c.map((cl, i) => i === idx ? { ...cl, status: 'running' } : cl))
      const phase = idx / totalClips
      const phaseLabel = phase < 0.15 ? 'opening establishing shot,' : phase < 0.4 ? 'early scene,' : phase < 0.6 ? 'mid-story,' : phase < 0.85 ? 'climax building,' : 'closing shot,'
      const p = `${prompt.trim()}, ${phaseLabel} scene ${idx + 1}/${totalClips}, ${clipSecs}s, cinematic`
      try {
        const url = await generateDemo(p, { resolution: settings.resolution, duration: String(clipSecs), onStep: () => {} })
        setClips(c => c.map((cl, i) => i === idx ? { ...cl, status: 'done', url } : cl))
        onClipDone(url, p)
      } catch {
        setClips(c => c.map((cl, i) => i === idx ? { ...cl, status: 'failed' } : cl))
      }
      setOverall(Math.round(((idx + 1) / totalClips) * 100))
    }
    setRunning(false)
    onToast(`Long video done! ${totalClips} clips generated.`, 'success')
  }

  function stop() { abortRef.current = true; setRunning(false); onToast('Generation stopped', 'info') }

  return (
    <div className="flex flex-col gap-4">
      <div className="panel">
        <div className="flex items-start justify-between gap-3 mb-4">
          <div>
            <p className="text-sm font-semibold text-white mb-1">Long Video Generation</p>
            <p className="text-xs text-[#8b8fa8] leading-relaxed">
              Generates sequential 15s clips and stitches them — up to 30 minutes.
            </p>
          </div>
          <span className="flex-shrink-0 px-3 py-1 rounded-lg text-sm font-black text-white"
            style={{ background: 'linear-gradient(135deg,#7C3AED,#2563EB)' }}>30 MIN</span>
        </div>

        <label className="text-xs font-semibold text-[#8b8fa8] uppercase tracking-wide block mb-2">Story Prompt</label>
        <textarea value={prompt} onChange={e => setPrompt(e.target.value)}
          className="input-field resize-none mb-4" rows={4}
          placeholder="An epic journey through ancient civilizations: pyramids at sunrise, Colosseum at golden hour, Great Wall under moonlight…" />

        <div className="flex gap-4 flex-wrap">
          <div className="flex flex-col gap-1.5">
            <span className="text-xs font-semibold text-[#8b8fa8] uppercase tracking-wide">Target Length</span>
            <div className="flex gap-1.5">
              {TARGET_OPTS.map(o => (
                <button key={o.value} onClick={() => setTargetMin(o.value)}
                  className={clsx('chip', targetMin === o.value && 'active')}>{o.label}</button>
              ))}
            </div>
          </div>
          <div className="flex flex-col gap-1.5">
            <span className="text-xs font-semibold text-[#8b8fa8] uppercase tracking-wide">Clip Length</span>
            <div className="flex gap-1.5">
              {CLIP_OPTS.map(o => (
                <button key={o.value} onClick={() => setClipSecs(o.value)}
                  className={clsx('chip', clipSecs === o.value && 'active')}>{o.label}</button>
              ))}
            </div>
          </div>
        </div>

        <div className="mt-4 flex items-center gap-2 px-3 py-2.5 rounded-lg text-xs text-purple-300"
          style={{ background: 'rgba(124,58,237,0.08)', border: '1px solid rgba(124,58,237,0.2)' }}>
          <span className="text-purple-400">ℹ</span>
          {targetMin} min = {totalClips} clips × {clipSecs}s each. Auto-stitched into one video.
        </div>
      </div>

      {/* Progress */}
      {clips.length > 0 && (
        <div className="panel">
          <div className="flex items-center justify-between mb-3">
            <span className="text-xs font-semibold text-[#8b8fa8] uppercase tracking-wide">Progress</span>
            <span className="text-sm font-bold text-white">{overall}%</span>
          </div>
          <div className="h-2 rounded-full overflow-hidden mb-4" style={{ background: '#161925' }}>
            <div className="h-full rounded-full transition-all duration-500"
              style={{ width: `${overall}%`, background: 'linear-gradient(90deg,#7C3AED,#2563EB)' }} />
          </div>
          <div className="flex flex-col gap-1.5 max-h-52 overflow-y-auto">
            {clips.map(cl => (
              <div key={cl.i} className="flex items-center gap-3 py-1.5 px-3 rounded-lg text-xs"
                style={{ background: '#161925' }}>
                <span className="font-bold text-[#8b8fa8] w-8">#{cl.i + 1}</span>
                <span className="flex-1 text-[#8b8fa8]">Scene {cl.i + 1} of {totalClips}</span>
                <span className="font-semibold" style={{ color: STATUS_COLORS[cl.status] }}>
                  {STATUS_LABELS[cl.status]}
                </span>
              </div>
            ))}
          </div>
        </div>
      )}

      {running
        ? <button onClick={stop} className="w-full py-4 rounded-xl font-semibold text-base flex items-center justify-center gap-2 transition-all text-red-400"
            style={{ background: 'rgba(239,68,68,0.1)', border: '1px solid rgba(239,68,68,0.25)' }}>
            <StopCircle size={18} /> Stop Generation
          </button>
        : <button onClick={start}
            className="btn-primary w-full py-4 text-base">
            <PlayCircle size={18} /> Start {targetMin}-Minute Video
          </button>
      }
    </div>
  )
}
