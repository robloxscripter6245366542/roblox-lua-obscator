import clsx from 'clsx'

function ChipGroup({ label, options, value, onChange }) {
  return (
    <div className="flex flex-col gap-2">
      <span className="text-xs font-semibold text-[#8b8fa8] tracking-wide uppercase">{label}</span>
      <div className="flex flex-wrap gap-1.5">
        {options.map(opt => (
          <button key={opt.value}
            onClick={() => onChange(opt.value)}
            className={clsx('chip', value === opt.value && 'active')}>
            {opt.label}
            {opt.tag && <span className="ml-1.5 px-1 py-px rounded text-[9px] font-black tracking-wider text-white"
              style={{ background: 'linear-gradient(135deg,#7C3AED,#2563EB)' }}>{opt.tag}</span>}
          </button>
        ))}
      </div>
    </div>
  )
}

export default function SettingsPanel({ settings, onChange }) {
  const is4kMax = settings.resolution === '4k' && settings.model === 'seedance-2-0'

  function applyPreset(name) {
    const presets = {
      max:   { resolution: '4k',    duration: '15', model: 'seedance-2-0',      audio: true, aspect: '16:9' },
      fast:  { resolution: '1080p', duration: '5',  model: 'seedance-2-0-fast', audio: true, aspect: '16:9' },
      quick: { resolution: '4k',    duration: '5',  model: 'seedance-2-0',      audio: true, aspect: '16:9' },
    }
    onChange({ ...settings, ...presets[name] })
  }

  return (
    <div className="panel flex flex-col gap-5">
      {/* Preset Bar */}
      <div>
        <div className="flex items-center justify-between mb-2.5">
          <span className="text-xs font-semibold text-[#8b8fa8] tracking-wide uppercase">Presets</span>
          {is4kMax && (
            <span className="flex items-center gap-1.5 text-[11px] font-bold tracking-wide text-purple-300 px-2.5 py-1 rounded-md"
              style={{ background: 'rgba(124,58,237,0.12)', border: '1px solid rgba(124,58,237,0.3)' }}>
              <span className="w-1.5 h-1.5 rounded-full bg-purple-400 animate-pulse-slow" />
              4K MAX
            </span>
          )}
        </div>
        <div className="flex gap-2 flex-wrap">
          {[
            { name: 'max', label: '⭐ 4K MAX QUALITY' },
            { name: 'fast', label: '⚡ Fast 1080p' },
            { name: 'quick', label: '⏱ Quick 5s' },
          ].map(({ name, label }) => (
            <button key={name} onClick={() => applyPreset(name)}
              className="px-3 py-1.5 rounded-lg text-xs font-semibold transition-all border"
              style={{ background: '#161925', borderColor: 'rgba(255,255,255,0.07)', color: '#8b8fa8' }}
              onMouseEnter={e => { e.currentTarget.style.color = '#f0f1f5'; e.currentTarget.style.borderColor = 'rgba(255,255,255,0.15)' }}
              onMouseLeave={e => { e.currentTarget.style.color = '#8b8fa8'; e.currentTarget.style.borderColor = 'rgba(255,255,255,0.07)' }}>
              {label}
            </button>
          ))}
        </div>
      </div>

      <div className="h-px" style={{ background: 'rgba(255,255,255,0.06)' }} />

      <ChipGroup label="Resolution"
        value={settings.resolution}
        onChange={v => onChange({ ...settings, resolution: v, ...(v === '4k' ? { model: 'seedance-2-0' } : {}) })}
        options={[
          { value: '4k', label: '4K', tag: 'MAX' },
          { value: '1080p', label: '1080p' },
          { value: '720p', label: '720p' },
          { value: '480p', label: '480p' },
        ]} />

      <ChipGroup label="Duration"
        value={settings.duration}
        onChange={v => onChange({ ...settings, duration: v })}
        options={[
          { value: '5', label: '5s' },
          { value: '10', label: '10s' },
          { value: '15', label: '15s', tag: 'MAX' },
        ]} />

      <ChipGroup label="Aspect Ratio"
        value={settings.aspect}
        onChange={v => onChange({ ...settings, aspect: v })}
        options={[
          { value: '16:9', label: '16:9' },
          { value: '9:16', label: '9:16' },
          { value: '1:1', label: '1:1' },
          { value: '21:9', label: '21:9' },
          { value: '4:3', label: '4:3' },
        ]} />

      <ChipGroup label="Style"
        value={settings.style}
        onChange={v => onChange({ ...settings, style: v })}
        options={[
          { value: 'Cinematic', label: 'Cinematic' },
          { value: 'Anime', label: 'Anime' },
          { value: 'Realistic', label: 'Realistic' },
          { value: '3D Render', label: '3D' },
        ]} />

      <ChipGroup label="Speed"
        value={settings.model}
        onChange={v => onChange({ ...settings, model: v })}
        options={[
          { value: 'seedance-2-0', label: 'Quality' },
          { value: 'seedance-2-0-fast', label: 'Fast' },
        ]} />

      <ChipGroup label="Audio"
        value={String(settings.audio)}
        onChange={v => onChange({ ...settings, audio: v === 'true' })}
        options={[
          { value: 'true', label: 'Generate Audio' },
          { value: 'false', label: 'Silent' },
        ]} />
    </div>
  )
}
