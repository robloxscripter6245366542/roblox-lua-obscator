import { useState, useRef, useEffect } from 'react'
import { motion } from 'framer-motion'

interface Clip { id: number; clipUrl: string; label: string }

export default function MoviePlayer({ clips, title }: { clips: Clip[]; title: string }) {
  const videoRef = useRef<HTMLVideoElement>(null)
  const [current, setCurrent] = useState(0)
  const [playing, setPlaying] = useState(false)
  const [isRecording, setIsRecording] = useState(false)
  const [recordPct, setRecordPct] = useState(0)
  const [recordDone, setRecordDone] = useState(false)
  const chunksRef = useRef<BlobPart[]>([])
  const recorderRef = useRef<MediaRecorder | null>(null)

  useEffect(() => {
    // Auto-load first clip
    if (videoRef.current && clips[0]) {
      videoRef.current.src = clips[0].clipUrl
    }
  }, [clips])

  const goTo = (idx: number) => {
    if (!videoRef.current || idx < 0 || idx >= clips.length) return
    setCurrent(idx)
    videoRef.current.src = clips[idx].clipUrl
    videoRef.current.play()
    setPlaying(true)
  }

  const onEnded = () => {
    if (current < clips.length - 1) {
      goTo(current + 1)
    } else {
      setPlaying(false)
    }
  }

  const togglePlay = () => {
    if (!videoRef.current) return
    if (videoRef.current.paused) { videoRef.current.play(); setPlaying(true) }
    else { videoRef.current.pause(); setPlaying(false) }
  }

  // Download full movie by playing through clips and recording via captureStream
  const downloadFullMovie = async () => {
    if (!videoRef.current || clips.length === 0 || isRecording) return
    setIsRecording(true); setRecordDone(false); setRecordPct(0)
    chunksRef.current = []

    const stream = (videoRef.current as any).captureStream?.()
    if (!stream) {
      alert('Your browser doesn\'t support captureStream. Try Chrome.')
      setIsRecording(false); return
    }

    const mime = MediaRecorder.isTypeSupported('video/webm;codecs=vp9,opus')
      ? 'video/webm;codecs=vp9,opus'
      : MediaRecorder.isTypeSupported('video/webm')
      ? 'video/webm'
      : 'video/mp4'

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

  // Download each clip separately (staggered so browser doesn't block)
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

  return (
    <motion.div initial={{ opacity: 0, y: 12 }} animate={{ opacity: 1, y: 0 }} className="glass rounded-2xl overflow-hidden"
      style={{ border: '1px solid rgba(236,72,153,.3)' }}>
      {/* Header */}
      <div className="flex items-center justify-between px-5 py-3" style={{ background: 'rgba(0,0,0,.5)', borderBottom: '1px solid rgba(255,255,255,.06)' }}>
        <div>
          <div className="font-bold text-white flex items-center gap-2">🎥 Full Movie Preview</div>
          <div className="text-xs" style={{ color: 'var(--muted)' }}>{clips.length} scenes · {Math.round(clips.length * 5 / 60 * 10) / 10} min · Scene {current + 1} of {clips.length}</div>
        </div>
        <div className="flex gap-2">
          <button onClick={downloadFullMovie} disabled={isRecording}
            className="flex items-center gap-1.5 px-3 py-1.5 rounded-lg text-xs font-bold text-black"
            style={{ background: isRecording ? 'rgba(100,100,100,.5)' : 'linear-gradient(135deg,var(--p),var(--v))', cursor: isRecording ? 'not-allowed' : 'pointer' }}>
            {isRecording ? `⏺ Recording… ${recordPct}%` : recordDone ? '✅ Downloaded!' : '⬇ Download Full Movie'}
          </button>
          <button onClick={downloadAllClips}
            className="px-3 py-1.5 rounded-lg text-xs font-bold"
            style={{ background: 'rgba(255,255,255,.08)', border: '1px solid rgba(255,255,255,.12)', color: 'var(--text)' }}>
            ⬇ All Clips
          </button>
        </div>
      </div>

      {/* Video player */}
      <div style={{ background: '#000', position: 'relative' }}>
        <video ref={videoRef} onEnded={onEnded} onPlay={() => setPlaying(true)} onPause={() => setPlaying(false)}
          controls style={{ width: '100%', display: 'block', maxHeight: 520, background: '#000' }} />
        {/* Scene overlay */}
        <div style={{ position: 'absolute', bottom: 60, left: 12, background: 'rgba(0,0,0,.65)', padding: '4px 10px', borderRadius: 8, fontSize: 11, color: '#fff', backdropFilter: 'blur(8px)', border: '1px solid rgba(255,255,255,.1)' }}>
          {clips[current]?.label}
        </div>
      </div>

      {/* Recording progress */}
      {isRecording && (
        <div className="px-5 py-2" style={{ borderTop: '1px solid rgba(255,255,255,.06)', background: 'rgba(236,72,153,.06)' }}>
          <div className="flex items-center gap-2 mb-1">
            <span className="text-xs font-bold" style={{ color: 'var(--p)' }}>⏺ Recording full movie to file… {recordPct}%</span>
          </div>
          <div className="progress-bar"><div className="progress-fill" style={{ width: `${recordPct}%`, background: 'linear-gradient(90deg,var(--p),var(--v))' }}></div></div>
          <div className="text-xs mt-1 opacity-50">Playing through all {clips.length} scenes — do not close this tab</div>
        </div>
      )}

      {/* Scene selector thumbnails */}
      <div className="p-4" style={{ borderTop: '1px solid rgba(255,255,255,.06)', background: 'rgba(0,0,0,.3)' }}>
        <div className="text-xs font-bold text-white mb-2">Scenes</div>
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

      {/* iMovie tip */}
      <div className="px-5 py-3 flex items-start gap-2" style={{ background: 'rgba(16,185,129,.04)', borderTop: '1px solid rgba(16,185,129,.12)' }}>
        <span className="text-base flex-shrink-0">💡</span>
        <div className="text-xs" style={{ color: 'var(--muted)' }}>
          <strong style={{ color: '#10b981' }}>iMovie / DaVinci Resolve:</strong> Click "All Clips" above to download each scene as an individual MP4 file. Then drag them into iMovie in order and they'll assemble into your full movie timeline.
          <br/><strong style={{ color: 'var(--p)' }}>Single file:</strong> Click "Download Full Movie" — it records the playback and saves as a .webm file (plays in VLC, Chrome, Firefox; convert to MP4 with Handbrake).
        </div>
      </div>
    </motion.div>
  )
}
