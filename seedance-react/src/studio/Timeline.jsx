import { useRef, useCallback } from 'react'

export default function Timeline({ timeNorm, clip, onScrub }) {
  const barRef = useRef()

  const seek = useCallback((e) => {
    const bar = barRef.current
    if (!bar) return
    const rect = bar.getBoundingClientRect()
    const x = (e.clientX - rect.left) / rect.width
    onScrub(Math.max(0, Math.min(1, x)))
  }, [onScrub])

  const onMouseDown = useCallback((e) => {
    seek(e)
    function onMove(ev) { seek(ev) }
    function onUp() {
      window.removeEventListener('mousemove', onMove)
      window.removeEventListener('mouseup', onUp)
    }
    window.addEventListener('mousemove', onMove)
    window.addEventListener('mouseup', onUp)
  }, [seek])

  if (!clip) return null

  const dur = clip.duration
  const tracks = clip.tracks || []

  // Gather unique keyframe times per track
  const keyframeSets = tracks.map(track => {
    const times = track.times || []
    return { name: track.name.split('.')[0], times: Array.from(times) }
  })

  // Deduplicate by bone name
  const byBone = {}
  keyframeSets.forEach(({ name, times }) => {
    if (!byBone[name]) byBone[name] = new Set()
    times.forEach(t => byBone[name].add(t))
  })
  const boneRows = Object.entries(byBone)

  return (
    <div className="px-4 py-2" style={{ userSelect: 'none' }}>
      {/* Ruler */}
      <div className="relative h-5 mb-1" ref={barRef} onMouseDown={onMouseDown}
        style={{ cursor: 'col-resize' }}>
        <div className="absolute inset-0 rounded" style={{ background: 'rgba(255,255,255,0.04)' }} />
        {/* Tick marks */}
        {Array.from({ length: Math.ceil(dur / 0.1) + 1 }, (_, i) => i * 0.1).map(t => {
          const pct = (t / dur) * 100
          if (pct > 100) return null
          const isMajor = Math.abs(t * 10 - Math.round(t * 10)) < 0.01 && Math.round(t * 10) % 5 === 0
          return (
            <div key={t} className="absolute top-0 flex flex-col items-center pointer-events-none"
              style={{ left: `${pct}%`, transform: 'translateX(-50%)' }}>
              <div style={{
                width: 1,
                height: isMajor ? 8 : 4,
                background: isMajor ? 'rgba(255,255,255,0.3)' : 'rgba(255,255,255,0.12)',
              }} />
              {isMajor && (
                <span style={{ fontSize: 8, color: 'rgba(255,255,255,0.3)', marginTop: 1 }}>
                  {t.toFixed(1)}s
                </span>
              )}
            </div>
          )
        })}
        {/* Playhead */}
        <div className="absolute top-0 h-full pointer-events-none"
          style={{ left: `${timeNorm * 100}%`, transform: 'translateX(-50%)' }}>
          <div className="w-0.5 h-full" style={{ background: '#7C3AED' }} />
          <div className="w-2 h-2 rounded-sm -mt-0.5 -ml-[3px]"
            style={{ background: '#7C3AED', clipPath: 'polygon(50% 100%, 0 0, 100% 0)' }} />
        </div>
      </div>

      {/* Keyframe rows */}
      <div className="space-y-px max-h-20 overflow-y-auto">
        {boneRows.map(([bone, times]) => (
          <div key={bone} className="relative h-4 flex items-center">
            <span className="text-[8px] text-[#555872] w-20 flex-shrink-0 truncate">{bone}</span>
            <div className="relative flex-1 h-1.5 rounded"
              style={{ background: 'rgba(255,255,255,0.04)' }}>
              {Array.from(times).map(t => {
                const pct = (t / dur) * 100
                return (
                  <div key={t} className="absolute top-1/2 -translate-y-1/2 w-1.5 h-1.5 rounded-sm rotate-45 -translate-x-1/2"
                    style={{ left: `${pct}%`, background: '#7C3AED', boxShadow: '0 0 4px rgba(124,58,237,0.6)' }} />
                )
              })}
              {/* Playhead line on this track */}
              <div className="absolute top-0 h-full w-px pointer-events-none"
                style={{ left: `${timeNorm * 100}%`, background: 'rgba(124,58,237,0.5)' }} />
            </div>
          </div>
        ))}
      </div>
    </div>
  )
}
