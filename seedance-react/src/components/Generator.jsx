import { useState, useRef } from 'react'
import { Shuffle, Upload, Wand2, Film, Clock3 } from 'lucide-react'
import clsx from 'clsx'
import SettingsPanel from './SettingsPanel.jsx'
import OutputPanel from './OutputPanel.jsx'
import LongVideoPanel from './LongVideoPanel.jsx'
import { createVideoTask, pollTask } from '../lib/seedance.js'

const RANDOM_PROMPTS = [
  'A majestic dragon soaring over snow-capped mountains at golden hour, cinematic lighting, ultra detailed',
  'Bioluminescent jellyfish drifting through a dark ocean abyss, rays of light filtering from above',
  'A futuristic cyberpunk city at night, neon reflections on wet streets, flying cars in the distance',
  'Timelapse of a flower blooming in an enchanted forest, magical particles floating, slow motion',
  'An astronaut standing on the surface of Mars watching a sunset, red sky, dust swirling',
  'A massive waterfall flowing into a crystal-clear mountain lake, aerial drone shot, sunrise',
  'Ancient ruins being reclaimed by jungle, vines and moss, golden afternoon light, cinematic',
  'A lone wolf running through a snowy pine forest, breath visible in cold air, slow motion',
  'Northern lights dancing over a frozen lake, perfect reflections, starry sky, timelapse',
  'Waves crashing on a tropical beach in slow motion, turquoise water, white sand, aerial view',
]

const DEFAULT_SETTINGS = {
  resolution: '4k', duration: '15', aspect: '16:9',
  style: 'Cinematic', model: 'seedance-2-0', audio: true,
}

const MODES = [
  { id: 'text',  label: 'Text to Video',  icon: Wand2 },
  { id: 'image', label: 'Image to Video', icon: Film },
  { id: 'long',  label: 'Long Video',     icon: Clock3, badge: '30 MIN' },
]

export default function Generator({ timer, onToast }) {
  const [mode, setMode] = useState('text')
  const [settings, setSettings] = useState(DEFAULT_SETTINGS)
  const [prompt, setPrompt] = useState('')
  const [imagePrompt, setImagePrompt] = useState('')
  const [imagePreview, setImagePreview] = useState(null)
  const [outputState, setOutputState] = useState({ status: 'idle', videoUrl: null, progress: 0, step: 0, label: '' })
  const [queue, setQueue] = useState([])
  const fileRef = useRef()

  function randomPrompt() {
    setPrompt(RANDOM_PROMPTS[Math.floor(Math.random() * RANDOM_PROMPTS.length)])
  }

  function handleFile(file) {
    if (!file?.type.startsWith('image/')) return
    const reader = new FileReader()
    reader.onload = e => setImagePreview(e.target.result)
    reader.readAsDataURL(file)
  }

  async function handleGenerate() {
    const p = mode === 'text' ? prompt.trim() : (imagePrompt.trim() || 'animate the image')
    if (mode === 'text' && !p) { onToast('Please enter a prompt', 'error'); return }
    if (mode === 'image' && !imagePreview) { onToast('Please upload an image', 'error'); return }
    if (!timer.running) timer.start()
    if (timer.expired) { onToast('Session expired — start a new session', 'error'); return }

    setOutputState({ status: 'loading', progress: 0, step: 0, label: 'Initializing Seedance 2.0…' })

    try {
      let url
      const taskId = await createVideoTask(null, {
        prompt: p, genType: mode === 'image' ? 'image-to-video' : 'text-to-video',
        imageUrls: imagePreview ? [imagePreview] : [],
        duration: settings.duration, aspectRatio: settings.aspect,
        resolution: settings.resolution, model: settings.model, audio: settings.audio,
      })
      url = await pollTask(null, taskId, pct =>
        setOutputState(s => ({ ...s, progress: pct, step: Math.floor(pct / 25) })))
      setOutputState({ status: 'done', videoUrl: url, progress: 100, step: 4, label: '' })
      setQueue(q => [{ url, prompt: p, settings: { ...settings }, ts: Date.now() }, ...q].slice(0, 6))
      onToast(`4K video ready! (${settings.resolution.toUpperCase()} · ${settings.duration}s)`, 'success')
    } catch (err) {
      setOutputState({ status: 'idle', videoUrl: null, progress: 0, step: 0, label: '' })
      onToast(err.message || 'Generation failed', 'error')
    }
  }

  function handleDownload() {
    if (!outputState.videoUrl) return
    const a = document.createElement('a'); a.href = outputState.videoUrl
    a.download = `seedance-4k-${Date.now()}.webm`; a.click()
    onToast('Download started!', 'success')
  }
  async function handleShare() {
    try { await navigator.clipboard.writeText(window.location.href); onToast('Link copied!', 'info') } catch {}
  }

  return (
    <section id="generate" className="relative z-10 pb-24 px-6">
      <div className="max-w-7xl mx-auto">
        {/* Mode Tabs */}
        <div className="flex gap-2 mb-6">
          {MODES.map(({ id, label, icon: Icon, badge }) => (
            <button key={id} onClick={() => setMode(id)}
              className={clsx(
                'flex items-center gap-2 px-4 py-2.5 rounded-xl text-sm font-medium transition-all border',
                mode === id
                  ? 'text-white border-purple-500/40'
                  : 'text-[#8b8fa8] border-white/[0.07] hover:text-white hover:border-white/15'
              )}
              style={mode === id ? { background: 'rgba(124,58,237,0.15)' } : { background: '#10121a' }}>
              <Icon size={15} />
              {label}
              {badge && (
                <span className="ml-1 px-1.5 py-px rounded text-[9px] font-black tracking-wider text-white"
                  style={{ background: 'linear-gradient(135deg,#7C3AED,#2563EB)' }}>{badge}</span>
              )}
            </button>
          ))}
        </div>

        <div className="grid grid-cols-1 lg:grid-cols-[420px_1fr] gap-5">
          {/* Left column */}
          <div className="flex flex-col gap-4">
            {/* Text prompt */}
            {mode === 'text' && (
              <div className="panel">
                <label className="text-xs font-semibold text-[#8b8fa8] uppercase tracking-wide block mb-2.5">
                  Describe your video
                </label>
                <textarea value={prompt} onChange={e => setPrompt(e.target.value)}
                  className="input-field resize-none min-h-[120px] leading-relaxed"
                  placeholder="A majestic dragon soaring over snow-capped mountains at golden hour, cinematic lighting, ultra detailed, 4K…" />
                <div className="flex items-center justify-between mt-2.5">
                  <button onClick={randomPrompt} className="btn-ghost py-1.5 px-3 text-xs">
                    <Shuffle size={12} /> Random
                  </button>
                  <span className="text-xs text-[#555872]">{prompt.length} / 500</span>
                </div>
              </div>
            )}

            {/* Image upload */}
            {mode === 'image' && (
              <div className="panel">
                <label className="text-xs font-semibold text-[#8b8fa8] uppercase tracking-wide block mb-2.5">
                  Reference Image
                </label>
                <div
                  onClick={() => fileRef.current?.click()}
                  onDragOver={e => e.preventDefault()}
                  onDrop={e => { e.preventDefault(); handleFile(e.dataTransfer.files[0]) }}
                  className="rounded-xl border-2 border-dashed min-h-[140px] flex items-center justify-center cursor-pointer transition-all mb-4"
                  style={{ borderColor: imagePreview ? 'rgba(124,58,237,0.4)' : 'rgba(255,255,255,0.08)' }}>
                  <input ref={fileRef} type="file" accept="image/*" hidden onChange={e => handleFile(e.target.files[0])} />
                  {imagePreview
                    ? <img src={imagePreview} alt="Preview" className="w-full h-full object-cover rounded-xl max-h-48" />
                    : (
                      <div className="text-center p-6">
                        <Upload size={28} className="mx-auto mb-2 opacity-30" />
                        <p className="text-sm text-[#8b8fa8]">Drop image or <span className="text-purple-400 underline">browse</span></p>
                        <p className="text-xs text-[#555872] mt-1">PNG, JPG up to 10MB</p>
                      </div>
                    )}
                </div>
                <label className="text-xs font-semibold text-[#8b8fa8] uppercase tracking-wide block mb-2">Motion Prompt</label>
                <textarea value={imagePrompt} onChange={e => setImagePrompt(e.target.value)}
                  className="input-field resize-none" rows={3}
                  placeholder="Camera slowly zooms in, leaves blow in the wind…" />
              </div>
            )}

            {/* Long video */}
            {mode === 'long' && (
              <LongVideoPanel settings={settings} onToast={onToast} timer={timer} apiKey={apiKey}
                onClipDone={(url, p) => setQueue(q => [{ url, prompt: p, settings: { ...settings }, ts: Date.now() }, ...q].slice(0, 6))} />
            )}

            {/* Settings */}
            <SettingsPanel settings={settings} onChange={setSettings} />


            {/* Generate Button */}
            {mode !== 'long' && (
              <button onClick={handleGenerate}
                disabled={outputState.status === 'loading'}
                className="btn-primary w-full py-4 text-base">
                {outputState.status === 'loading'
                  ? <><span className="w-4 h-4 border-2 border-white/30 border-t-white rounded-full animate-spin" />Generating…</>
                  : <><Wand2 size={18} />Generate 4K Video</>}
              </button>
            )}
          </div>

          {/* Right column — Output */}
          <div className="flex flex-col gap-4">
            <OutputPanel state={outputState} settings={settings} onDownload={handleDownload} onShare={handleShare} />

            {/* Recent queue */}
            {queue.length > 1 && (
              <div className="flex flex-col gap-2">
                <span className="text-xs font-semibold text-[#8b8fa8] uppercase tracking-wide">Recent</span>
                {queue.slice(1, 4).map((item, i) => (
                  <div key={i} className="panel py-3 px-4 flex items-center gap-3">
                    <div className="w-16 h-10 rounded-lg overflow-hidden flex-shrink-0" style={{ background: '#161925' }}>
                      <video src={item.url} muted autoPlay loop playsInline className="w-full h-full object-cover" />
                    </div>
                    <div className="flex-1 min-w-0">
                      <p className="text-sm font-medium text-white truncate">{item.prompt}</p>
                      <p className="text-xs text-[#8b8fa8] mt-0.5">
                        {item.settings.resolution === '4k' ? '4K' : item.settings.resolution} · {item.settings.duration}s · {item.settings.style}
                      </p>
                    </div>
                    <span className="text-xs font-semibold text-emerald-400 px-2 py-1 rounded-md flex-shrink-0"
                      style={{ background: 'rgba(16,185,129,0.1)', border: '1px solid rgba(16,185,129,0.2)' }}>Done</span>
                  </div>
                ))}
              </div>
            )}
          </div>
        </div>
      </div>
    </section>
  )
}
