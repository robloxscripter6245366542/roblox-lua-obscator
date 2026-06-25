import { Download, Share2, Play } from 'lucide-react'
import clsx from 'clsx'

export default function OutputPanel({ state, settings, onDownload, onShare }) {
  return (
    <div className="flex flex-col gap-4 h-full">
      <div className="flex items-center justify-between">
        <span className="text-xs font-semibold text-[#8b8fa8] tracking-wide uppercase">Output</span>
        {state.videoUrl && (
          <div className="flex gap-2">
            <button onClick={onDownload} className="btn-ghost py-1.5 px-3 text-xs">
              <Download size={13} /> Download
            </button>
            <button onClick={onShare} className="btn-ghost py-1.5 px-3 text-xs">
              <Share2 size={13} /> Share
            </button>
          </div>
        )}
      </div>

      <div className="panel flex-1 flex items-center justify-center relative overflow-hidden min-h-[280px]"
        style={{ aspectRatio: settings.aspect === '9:16' ? '9/16' : settings.aspect === '1:1' ? '1/1' : '16/9' }}>
        {state.status === 'idle' && <IdleState />}
        {state.status === 'loading' && <LoadingState loadState={state} />}
        {state.status === 'done' && <VideoResult url={state.videoUrl} settings={settings} />}
      </div>
    </div>
  )
}

function IdleState() {
  return (
    <div className="text-center px-6 animate-fade-in">
      <div className="w-16 h-16 mx-auto mb-4 rounded-full flex items-center justify-center"
        style={{ background: 'rgba(124,58,237,0.1)', border: '1px dashed rgba(124,58,237,0.3)' }}>
        <Play size={24} className="text-purple-400 ml-1" />
      </div>
      <p className="text-sm font-semibold text-white mb-1">Your video will appear here</p>
      <p className="text-xs text-[#8b8fa8] leading-relaxed max-w-xs">
        Enter a prompt and click Generate to create a 4K video with Seedance 2.0
      </p>
    </div>
  )
}

function LoadingState({ loadState }) {
  const steps = ['Parsing prompt', 'Generating frames', 'Upscaling to 4K', 'Encoding video']
  return (
    <div className="w-full px-6 py-8 text-center animate-fade-in">
      <div className="w-16 h-16 mx-auto mb-5 relative">
        <svg className="w-full h-full animate-spin-slow" viewBox="0 0 64 64" fill="none">
          <circle cx="32" cy="32" r="28" stroke="url(#lg)" strokeWidth="3.5" strokeLinecap="round" strokeDasharray="44 132" />
          <defs>
            <linearGradient id="lg" x1="0" y1="0" x2="64" y2="64" gradientUnits="userSpaceOnUse">
              <stop stopColor="#7C3AED" /><stop offset="1" stopColor="#2563EB" />
            </linearGradient>
          </defs>
        </svg>
      </div>
      <p className="text-sm font-semibold text-white mb-4">{loadState.label}</p>
      <div className="flex flex-col gap-1.5 mb-4 items-start max-w-[180px] mx-auto">
        {steps.map((s, i) => (
          <div key={s} className={clsx('text-xs flex items-center gap-2',
            i < loadState.step ? 'text-emerald-400' : i === loadState.step ? 'text-purple-400' : 'text-[#555872]')}>
            <span className={clsx('w-1.5 h-1.5 rounded-full flex-shrink-0',
              i < loadState.step ? 'bg-emerald-400' : i === loadState.step ? 'bg-purple-400 animate-pulse' : 'bg-[#555872]')} />
            {s}
          </div>
        ))}
      </div>
      <div className="w-full h-1 rounded-full overflow-hidden" style={{ background: '#161925' }}>
        <div className="h-full rounded-full transition-all duration-500"
          style={{ width: `${loadState.progress}%`, background: 'linear-gradient(90deg,#7C3AED,#2563EB)' }} />
      </div>
      <p className="text-xs text-[#555872] mt-2">{loadState.progress}%</p>
    </div>
  )
}

function VideoResult({ url, settings }) {
  const res = settings.resolution === '4k' ? '4K' : settings.resolution.toUpperCase()
  return (
    <div className="w-full h-full relative animate-fade-in">
      <video src={url} controls loop autoPlay playsInline
        className="w-full h-full object-contain rounded-xl" style={{ background: '#000' }} />
      <div className="absolute bottom-3 left-3 flex gap-1.5 flex-wrap">
        {[res, `${settings.duration}s`, settings.style, settings.aspect].map(t => (
          <span key={t} className="text-[11px] font-semibold px-2 py-0.5 rounded-md text-purple-300"
            style={{ background: 'rgba(124,58,237,0.2)', border: '1px solid rgba(124,58,237,0.3)' }}>{t}</span>
        ))}
      </div>
    </div>
  )
}
