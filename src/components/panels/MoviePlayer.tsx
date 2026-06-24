import { useState, useRef, useEffect } from 'react'
import { motion } from 'framer-motion'

interface Clip { id: number; clipUrl: string; label: string }

interface Props {
  clips: Clip[]
  title: string
  totalScenes?: number
  doneScenes?: number
}

export default function MoviePlayer({ clips, title, totalScenes = 0, doneScenes = 0 }: Props) {
  const videoRef = useRef<HTMLVideoElement>(null)
  const [current, setCurrent] = useState(0)
  const [isRecording, setIsRecording] = useState(false)
  const [recordPct, setRecordPct] = useState(0)
  const [recordDone, setRecordDone] = useState(false)
  const chunksRef = useRef<BlobPart[]>([])
  const recorderRef = useRef<MediaRecorder | null>(null)

  // Load / update first clip whenever clips list changes
  useEffect(() => {
    if (videoRef.current && clips[current]) {
      videoRef.current.src = clips[current].clipUrl
    } else if (videoRef.current && clips[0]) {
      setCurrent(0)
      videoRef.current.src = clips[0].clipUrl
    }
  }, [clips])

  const goTo = (idx: number) => {
    if (!videoRef.current || idx < 0 || idx >= clips.length) return
    setCurrent(idx)
    videoRef.current.src = clips[idx].clipUrl
    videoRef.current.play()
  }

  const onEnded = () => {
    if (current < clips.length - 1) goTo(current + 1)
  }

  const downloadFullMovie = async () => {
    if (!videoRef.current || clips.length === 0 || isRecording) return
    setIsRecording(true); setRecordDone(false); setRecordPct(0)
    chunksRef.current = []

    const stream = (videoRef.current as any).captureStream?.()
    if (!stream) {
      alert("Your browser doesn't support captureStream. Try Chrome.")
      setIsRecording(false); return
    }

    const mime = MediaRecorder.isTypeSupported('video/webm;codecs=vp9,opus')
      ? 'video/webm;codecs=vp9,opus'
      : MediaRecorder.isTypeSupported('video/webm') ? 'video/webm' : 'video/mp4'

    const recorder = new MediaRecorder(stream, { mimeType: mime })
    recorderRef.current = recorder
    recorder.ondataavailable = e => { if (e.data.size > 0) chunksRef.current.push(e.data) }
    recorder.onstop = () => {
      const blob = new Blob(chunksRef.current, { type: mime })
      const a = document.createElement('a')
      a.href = URL.createObjectURL(blob)
      a.download = `${title || 'omni-ai-movie'}.webm`
      a.click()
      setIsRecording(false); setRecordDone(true); setRecordPct(100)
    }

    recorder.start(100)
    for (let i = 0; i < clips.length; i++) {
      setCurrent(i)
      setRecordPct(Math.round((i / clips.length) * 100))
      await new Promise<void>(resolve => {
        if (!videoRef.current) { resolve(); return }
        videoRef.current.src = clips[i].clipUrl
        videoRef.current.muted = false
        const onEnd = () => { videoRef.current?.removeEventListener('ended', onEnd); resolve() }
        const onErr = () => { videoRef.current?.removeEventListener('error', onErr); resolve() }
        videoRef.current.addEventListener('ended', onEnd, { once: true })
        videoRef.current.addEventListener('error', onErr, { once: true })
        videoRef.current.play().catch(resolve)
      })
    }
    recorder.stop()
  }

  const downloadAllClips = () => {
    clips.forEach((c, i) => {
      setTimeout(() => {
        const a = document.createElement('a')
        a.href = c.clipUrl
        a.download = `${title || 'omni-ai'}-scene-${c.id + 1}.mp4`
        document.body.appendChild(a); a.click(); document.body.removeChild(a)
      }, i * 600)
    })
  }

  const pct = totalScenes > 0 ? Math.round((doneScenes / totalScenes) * 100) : 0
  const hasClips = clips.length > 0

  return (
    <motion.div initial={{ opacity: 0, y: 12 }} animate={{ opacity: 1, y: 0 }} className="glass rounded-2xl overflow-hidden"
      style={{ border: '1px solid rgba(236,72,153,.3)' }}>

      {/* Header */}
      <div className="flex items-center justify-between px-5 py-3"
        style={{ background: 'rgba(0,0,0,.5)', borderBottom: '1px solid rgba(255,255,255,.06)' }}>
        <div>
          <div className="font-bold text-white flex items-center gap-2">🎥 Full Movie Preview</div>
          <div className="text-xs" style={{ color: 'var(--muted)' }}>
            {hasClips
              ? `${clips.length} clip${clips.length !== 1 ? 's' : ''} ready · Scene ${current + 1} of ${clips.length}`
              : totalScenes > 0
                ? `⏳ Generating clips… ${doneScenes} / ${totalScenes} ready`
                : 'Start production to generate clips'}
          </div>
        </div>
        <div className="flex gap-2">
          <button onClick={downloadFullMovie} disabled={isRecording || !hasClips}
            className="flex items-center gap-1.5 px-3 py-1.5 rounded-lg text-xs font-bold text-black"
            style={{ background: !hasClips ? 'rgba(100,100,100,.3)' : isRecording ? 'rgba(100,100,100,.5)' : 'linear-gradient(135deg,var(--p),var(--v))', cursor: !hasClips || isRecording ? 'not-allowed' : 'pointer', opacity: !hasClips ? 0.5 : 1 }}>
            {isRecording ? `⏺ Recording… ${recordPct}%` : recordDone ? '✅ Downloaded!' : '⬇ Download Full Movie'}
          </button>
          <button onClick={downloadAllClips} disabled={!hasClips}
            className="px-3 py-1.5 rounded-lg text-xs font-bold"
            style={{ background: 'rgba(255,255,255,.08)', border: '1px solid rgba(255,255,255,.12)', color: 'var(--text)', opacity: !hasClips ? 0.5 : 1, cursor: !hasClips ? 'not-allowed' : 'pointer' }}>
            ⬇ All Clips
          </button>
        </div>
      </div>

      {/* Video player / empty state */}
      <div style={{ background: '#000', position: 'relative', minHeight: hasClips ? undefined : 280 }}>
        {hasClips ? (
          <>
            <video ref={videoRef} onEnded={onEnded} onPlay={() => {}} onPause={() => {}}
              controls style={{ width: '100%', display: 'block', maxHeight: 520, background: '#000' }} />
            <div style={{ position: 'absolute', bottom: 60, left: 12, background: 'rgba(0,0,0,.65)', padding: '4px 10px', borderRadius: 8, fontSize: 11, color: '#fff', backdropFilter: 'blur(8px)', border: '1px solid rgba(255,255,255,.1)' }}>
              {clips[current]?.label}
            </div>
          </>
        ) : (
          <div className="flex flex-col items-center justify-center h-full" style={{ minHeight: 280, color: 'var(--muted)' }}>
            <div className="text-5xl mb-4">🎬</div>
            {totalScenes > 0 ? (
              <>
                <div className="text-sm font-bold text-white mb-2">Generating video clips…</div>
                <div className="text-xs mb-4" style={{ color: 'var(--muted)' }}>{doneScenes} of {totalScenes} scenes ready</div>
                <div style={{ width: 240 }}>
                  <div className="progress-bar"><div className="progress-fill" style={{ width: `${pct}%`, background: 'linear-gradient(90deg,var(--p),var(--v))' }}></div></div>
                  <div className="text-xs text-center mt-1" style={{ color: 'var(--muted)' }}>{pct}%</div>
                </div>
                <div className="text-xs mt-3 opacity-40">Clips appear here as they finish — each takes 60–120 seconds</div>
              </>
            ) : (
              <>
                <div className="text-sm">Movie preview appears here</div>
                <div className="text-xs mt-1 opacity-50">Click "Start Full AI Movie Production" then "Generate All Clips"</div>
              </>
            )}
          </div>
        )}
      </div>

      {/* Clip generation progress bar */}
      {totalScenes > 0 && !hasClips && (
        <div className="px-5 py-2" style={{ borderTop: '1px solid rgba(255,255,255,.06)', background: 'rgba(236,72,153,.04)' }}>
          <div className="text-xs opacity-50">Click "Generate All Clips" in the scene queue above to start rendering</div>
        </div>
      )}

      {/* Recording progress */}
      {isRecording && (
        <div className="px-5 py-2" style={{ borderTop: '1px solid rgba(255,255,255,.06)', background: 'rgba(236,72,153,.06)' }}>
          <div className="flex items-center gap-2 mb-1">
            <span className="text-xs font-bold" style={{ color: 'var(--p)' }}>⏺ Recording full movie… {recordPct}%</span>
          </div>
          <div className="progress-bar"><div className="progress-fill" style={{ width: `${recordPct}%`, background: 'linear-gradient(90deg,var(--p),var(--v))' }}></div></div>
          <div className="text-xs mt-1 opacity-50">Playing through all {clips.length} scenes — do not close this tab</div>
        </div>
      )}

      {/* Scene thumbnail strip */}
      {hasClips && (
        <div className="p-4" style={{ borderTop: '1px solid rgba(255,255,255,.06)', background: 'rgba(0,0,0,.3)' }}>
          <div className="text-xs font-bold text-white mb-2">Scenes ({clips.length})</div>
          <div className="flex gap-2 overflow-x-auto pb-2" style={{ scrollbarWidth: 'thin' }}>
            {clips.map((c, i) => (
              <div key={c.id} onClick={() => goTo(i)} className="flex-shrink-0 cursor-pointer rounded-lg overflow-hidden transition-all"
                style={{ width: 100, border: `2px solid ${i === current ? 'var(--p)' : 'rgba(255,255,255,.1)'}`, opacity: i === current ? 1 : 0.6 }}>
                <video src={c.clipUrl} muted style={{ width: '100%', display: 'block', pointerEvents: 'none' }} />
                <div style={{ padding: '3px 6px', fontSize: 10, color: 'var(--muted)', background: 'rgba(0,0,0,.8)', textAlign: 'center' }}>
                  {i === current ? '▶ ' : ''}{i + 1}
                </div>
              </div>
            ))}
          </div>
        </div>
      )}

      {/* iMovie tip */}
      <div className="px-5 py-3 flex items-start gap-2" style={{ background: 'rgba(16,185,129,.04)', borderTop: '1px solid rgba(16,185,129,.12)' }}>
        <span className="text-base flex-shrink-0">💡</span>
        <div className="text-xs" style={{ color: 'var(--muted)' }}>
          <strong style={{ color: '#10b981' }}>iMovie / DaVinci Resolve:</strong> Click "All Clips" to download each scene as an MP4 — drag them into iMovie in order to assemble your movie.
          <br /><strong style={{ color: 'var(--p)' }}>Single file:</strong> "Download Full Movie" records the playback as a .webm file (plays in VLC/Chrome; convert to MP4 with Handbrake).
        </div>
      </div>
    </motion.div>
  )
}
