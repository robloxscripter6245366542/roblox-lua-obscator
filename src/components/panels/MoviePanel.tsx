import { useState, useRef } from 'react'
import { motion, AnimatePresence } from 'framer-motion'
import MoviePlayer from './MoviePlayer'

const PIPELINE = [
  { ic: '📝', name: 'Claude', role: 'Screenplay', color: 'rgba(124,58,237,.3)' },
  { ic: '👤', name: 'Flux Realism', role: 'Characters', color: 'rgba(6,182,212,.3)' },
  { ic: '🌄', name: 'Flux Pro', role: 'Backgrounds', color: 'rgba(16,185,129,.3)' },
  { ic: '🔷', name: 'Flux 3D', role: '3D Models', color: 'rgba(245,158,11,.3)' },
  { ic: '✨', name: 'Seedream', role: 'VFX / Glows', color: 'rgba(168,85,247,.3)' },
  { ic: '🎬', name: 'Seedance 2.0', role: 'Video Clips', color: 'rgba(236,72,153,.3)' },
  { ic: '🎼', name: 'Suno AI', role: 'Soundtrack', color: 'rgba(245,158,11,.3)' },
  { ic: '🎙️', name: 'ElevenLabs', role: 'Narration', color: 'rgba(6,182,212,.3)' },
  { ic: '🎞️', name: 'Assembly', role: 'Final Movie', color: 'rgba(16,185,129,.3)' },
]

const VFX_PRESETS = [
  '✨ Glowing neon particles swirling in darkness',
  '🌸 Cherry blossom petals floating in magical light',
  '💫 Character with flowing luminous hair, wind',
  '🔥 Fire and ember particles rising, cinematic',
  '⚡ Electric lightning bolt with blue glow',
  '🌊 Ocean spray with volumetric god rays',
  '🌀 Holographic portal with energy rings',
  '💎 Crystal shattering with rainbow refraction',
]

type SceneStatus = 'queued' | 'generating' | 'done' | 'failed'
interface Scene { id: number; text: string; status: SceneStatus; clipUrl?: string; frameUrl?: string }
interface CharAsset { desc: string; imgUrl?: string }

export default function MoviePanel() {
  const [concept, setConcept] = useState('')
  const [genre, setGenre] = useState('Sci-Fi Thriller')
  const [style, setStyle] = useState('cinematic')
  const [lenMin, setLenMin] = useState(5)
  const [vidModel, setVidModel] = useState('seedance-2.0')
  const [charsText, setCharsText] = useState('')
  const [vfxPrompt, setVfxPrompt] = useState('')

  const [running, setRunning] = useState(false)
  const [stopped, setStopped] = useState(false)
  const [activePipe, setActivePipe] = useState(-1)
  const [statusMsg, setStatusMsg] = useState('')
  const [progress, setProgress] = useState(0)

  const [script, setScript] = useState('')
  const [chars, setChars] = useState<CharAsset[]>([])
  const [scenes, setScenes] = useState<Scene[]>([])
  const [storyboardFrames, setStoryboardFrames] = useState<string[]>([])
  const [modelImages, setModelImages] = useState<string[]>([])
  const [vfxImages, setVfxImages] = useState<string[]>([])
  const [musicSrc, setMusicSrc] = useState('')
  const [narrateSrc, setNarrateSrc] = useState('')

  const stoppedRef = useRef(false)

  const wait = (ms: number) => new Promise<void>(r => setTimeout(r, ms))

  const genImg = async (prompt: string, model: string, w = 512, h = 512): Promise<string> => {
    try {
      const r = await fetch('/api/image', {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({ prompt, model, width: w, height: h }),
      })
      if (!r.ok) return ''
      const blob = await r.blob()
      return URL.createObjectURL(blob)
    } catch { return '' }
  }

  const startMovie = async () => {
    if (!concept.trim()) { alert('Enter a movie concept!'); return }
    setRunning(true); setStopped(false); stoppedRef.current = false
    setScript(''); setChars([]); setScenes([]); setStoryboardFrames([])
    setModelImages([]); setVfxImages([]); setMusicSrc(''); setNarrateSrc('')
    setActivePipe(-1); setProgress(0)

    const CLIP_SEC = 5
    const totalClips = Math.ceil(lenMin * 60 / CLIP_SEC)
    const sceneCount = Math.max(3, Math.min(Math.ceil(totalClips / 3), 40))

    const imgModel = style === 'anime' ? 'flux-anime' : style === '3d' ? 'flux-3d' : style === 'cartoon' ? 'flux-anime' : 'flux-realism'

    // ── 1. SCREENPLAY (Claude) ──
    setActivePipe(0); setStatusMsg('📝 Claude writing full screenplay…'); setProgress(5)
    const scriptPrompt = `You are a professional screenwriter. Write a complete ${genre} screenplay in ${style} visual style for this concept:\n\n"${concept}"\n\nTarget length: ${lenMin} minutes | Scenes: ${sceneCount}\n\nFor EVERY scene use this EXACT format:\n[SCENE N] INT/EXT. LOCATION - TIME\nVISUAL: [detailed AI video generation prompt — describe camera, lighting, action, mood]\nACTION: [what physically happens]\nDIALOGUE: CHARACTER NAME: "spoken line"\nMUSIC_CUE: [music direction]\nVFX: [glows, particles, hair animation, petals, rigging, light effects]\n\nAlso include:\n- TITLE: [movie title]\n- LOGLINE: [one sentence]\n- CHARACTERS: [name: detailed physical description including hair style, color, clothing, expression — for AI image generation]\n\nBe extremely cinematic and detailed.`

    let generatedScript = ''
    try {
      const r = await fetch('/api/chat', { method: 'POST', headers: { 'Content-Type': 'application/json' }, body: JSON.stringify({ messages: [{ role: 'user', content: scriptPrompt }] }) })
      const d = await r.json()
      generatedScript = d.reply || 'Script generation failed.'
      setScript(generatedScript)
    } catch { setStatusMsg('❌ Script failed — check connection'); setRunning(false); return }
    setProgress(18)

    if (stoppedRef.current) { setRunning(false); return }

    // ── 2. CHARACTER DESIGN (Flux Realism/Anime/3D) ──
    setActivePipe(1); setStatusMsg('👤 Designing characters with Flux Realism…'); setProgress(22)
    const charSectionMatch = generatedScript.match(/CHARACTERS?:?([\s\S]*?)(?=\[SCENE|\n\n[A-Z])/i)
    let charDesigns: CharAsset[] = []
    const charLines = (charsText.trim() || charSectionMatch?.[1] || '')
      .split('\n').map(l => l.trim()).filter(l => l.length > 10).slice(0, 4)

    setChars(charLines.map(d => ({ desc: d })))
    charDesigns = await Promise.all(charLines.map(async (desc) => {
      const styleExtra = style === 'anime' ? 'anime art style, studio quality illustration, beautiful anime' : style === '3d' ? '3D CGI render, Pixar quality, subsurface scattering' : style === 'cartoon' ? 'cartoon illustration, vibrant, clean linework' : 'hyperrealistic portrait, cinematic lighting, photographic quality'
      const imgUrl = await genImg(`Character portrait, ${desc}, ${styleExtra}, detailed hair with individual strands, expressive eyes, professional concept art, full body reference, 8K`, imgModel, 512, 768)
      return { desc, imgUrl }
    }))
    setChars(charDesigns)
    setProgress(35)

    if (stoppedRef.current) { setRunning(false); return }

    // ── 3. STORYBOARD (Flux Pro) — backgrounds per scene ──
    setActivePipe(2); setStatusMsg('🌄 Flux Pro generating storyboard…'); setProgress(38)
    const sceneRegex = /\[SCENE \d+\]([\s\S]*?)(?=\[SCENE \d+\]|$)/g
    const sceneMatches = [...generatedScript.matchAll(sceneRegex)].map(m => m[0])
    const frames: string[] = []
    for (let i = 0; i < Math.min(sceneMatches.length, 8); i++) {
      if (stoppedRef.current) break
      const vis = sceneMatches[i].match(/VISUAL:\s*([^\n]+)/i)?.[1] || sceneMatches[i].slice(0, 150)
      const url = await genImg(`Cinematic ${style} film still, ${vis}, ${genre} genre, professional cinematography, 4K quality`, 'flux-pro', 512, 288)
      if (url) frames.push(url)
      setStoryboardFrames([...frames])
      setProgress(38 + (i / 8) * 12)
      await wait(500)
    }

    if (stoppedRef.current) { setRunning(false); return }

    // ── 4. 3D MODELS (Flux 3D) — key props, vehicles, environments ──
    setActivePipe(3); setStatusMsg('🔷 Flux 3D generating 3D models and assets…'); setProgress(50)
    const threeDPrompts: string[] = []
    // Extract objects/locations from script for 3D rendering
    const actionLines = [...generatedScript.matchAll(/ACTION:\s*([^\n]+)/ig)].map(m => m[1]).slice(0, 6)
    actionLines.forEach(line => {
      const obj = line.match(/(?:a |an |the )([\w\s]{4,30}(?:ship|craft|robot|vehicle|building|weapon|portal|device|suit|mech|sword|gun|castle|throne|spaceship|car|bike|drone|machine|tower))/i)?.[1]
      if (obj) threeDPrompts.push(`3D CGI render of ${obj}, ${style} style, Pixar quality, subsurface scattering, studio lighting, transparent background, 360 view`)
    })
    // Fallback: render main locations as 3D environments
    if (threeDPrompts.length === 0) {
      const locs = [...generatedScript.matchAll(/(?:INT\.|EXT\.)\s+([^-\n]+)/g)].map(m => m[1].trim()).slice(0, 3)
      locs.forEach(loc => threeDPrompts.push(`3D CGI environment render of ${loc}, ${genre} genre, cinematic lighting, photorealistic, Unreal Engine quality`))
    }
    const modelUrls: string[] = []
    for (const p of threeDPrompts.slice(0, 4)) {
      if (stoppedRef.current) break
      const url = await genImg(p, 'flux-3d', 512, 512)
      if (url) modelUrls.push(url)
      await wait(400)
    }
    if (modelUrls.length > 0) setModelImages(modelUrls)
    setProgress(56)

    if (stoppedRef.current) { setRunning(false); return }

    // ── 5. VFX ASSETS (Seedream) ──
    setActivePipe(4); setStatusMsg('✨ Seedream generating VFX and glow effects…'); setProgress(58)
    const vfxDescs: string[] = []
    sceneMatches.slice(0, 6).forEach(s => {
      const vfx = s.match(/VFX:\s*([^\n]+)/i)?.[1]
      if (vfx) vfxDescs.push(vfx)
    })
    const vfxUrls: string[] = []
    for (const desc of vfxDescs.slice(0, 4)) {
      if (stoppedRef.current) break
      const url = await genImg(`${desc}, cinematic VFX, glowing particles, magical light effects, professional visual effect, 4K`, 'seedream', 512, 512)
      if (url) vfxUrls.push(url)
      await wait(400)
    }
    if (vfxUrls.length > 0) setVfxImages(vfxUrls)
    setProgress(65)

    if (stoppedRef.current) { setRunning(false); return }

    // ── 6. SOUNDTRACK (Suno / Stable Audio) ──
    setActivePipe(6); setStatusMsg('🎼 Stable Audio composing soundtrack…'); setProgress(68)
    try {
      const musicCues = sceneMatches.slice(0, 3).map(s => s.match(/MUSIC_CUE:\s*([^\n]+)/i)?.[1]).filter(Boolean).join(', ')
      const mPrompt = `${genre} film score, ${style} aesthetic, ${musicCues || 'cinematic dramatic'}, for: ${concept.slice(0, 80)}`
      const mr = await fetch('/api/music', { method: 'POST', headers: { 'Content-Type': 'application/json' }, body: JSON.stringify({ prompt: mPrompt, model: 'stable-audio' }) })
      if (mr.ok) { const blob = await mr.blob(); setMusicSrc(URL.createObjectURL(blob)) }
    } catch {}
    setProgress(75)

    if (stoppedRef.current) { setRunning(false); return }

    // ── 7. NARRATION (ElevenLabs) ──
    setActivePipe(7); setStatusMsg('🎙️ ElevenLabs narrating opening scene…'); setProgress(78)
    try {
      const narration = `${concept.slice(0, 200)}. A ${genre} story begins.`
      const nr = await fetch('/api/audio', { method: 'POST', headers: { 'Content-Type': 'application/json' }, body: JSON.stringify({ text: narration, voice: 'nova' }) })
      if (nr.ok) { const blob = await nr.blob(); setNarrateSrc(URL.createObjectURL(blob)) }
    } catch {}
    setProgress(85)

    if (stoppedRef.current) { setRunning(false); return }

    // ── 7. SET UP SCENE QUEUE (Seedance 2.0 / Veo) ──
    setActivePipe(5); setStatusMsg('🎬 Video scene queue ready — start generating clips!')
    const sceneList: Scene[] = sceneMatches.slice(0, Math.min(sceneMatches.length, 30)).map((text, i) => ({
      id: i, text, status: 'queued' as SceneStatus,
    }))
    setScenes(sceneList)
    setProgress(90)

    // ── 8. ASSEMBLY ──
    setActivePipe(8); setStatusMsg('🎞️ Pipeline complete! Generate video clips to finish your movie.')
    setProgress(100)
    setRunning(false)
  }

  const generateClips = async () => {
    const sceneList = [...scenes]
    for (let i = 0; i < sceneList.length; i++) {
      if (stoppedRef.current) break
      setScenes(prev => prev.map((s, idx) => idx === i ? { ...s, status: 'generating' } : s))
      const vis = sceneList[i].text.match(/VISUAL:\s*([^\n]+)/i)?.[1] || sceneList[i].text.replace(/\[SCENE.*?\]/g, '').slice(0, 200)
      try {
        const r = await fetch('/api/video', { method: 'POST', headers: { 'Content-Type': 'application/json' },
          body: JSON.stringify({ prompt: vis.trim(), model: vidModel, duration: 5, width: 1920, height: 1080 }) })
        if (r.ok) {
          const ct = r.headers.get('content-type') || ''
          let url = ''
          if (ct.includes('video') || ct.includes('octet')) { const blob = await r.blob(); url = URL.createObjectURL(blob) }
          else { const d = await r.json(); url = d.url || '' }
          setScenes(prev => prev.map((s, idx) => idx === i ? { ...s, status: 'done', clipUrl: url } : s))
        } else throw new Error()
      } catch { setScenes(prev => prev.map((s, idx) => idx === i ? { ...s, status: 'failed' } : s)) }
      await wait(2000)
    }
  }

  const genVFX = async () => {
    if (!vfxPrompt.trim()) return
    setVfxImages([])
    const urls: string[] = []
    for (let i = 0; i < 4; i++) {
      const url = await genImg(`${vfxPrompt}, cinematic VFX, glowing particles, professional visual effect, 4K, variation ${i + 1}`, 'seedream', 512, 512)
      if (url) urls.push(url)
      setVfxImages([...urls])
      await wait(300)
    }
  }

  const designChars = async () => {
    const lines = charsText.split('\n').filter(l => l.trim().length > 5).slice(0, 4)
    if (!lines.length) return
    const imgModel = style === 'anime' ? 'flux-anime' : style === '3d' ? 'flux-3d' : 'flux-realism'
    setChars(lines.map(d => ({ desc: d })))
    const results = await Promise.all(lines.map(async desc => {
      const url = await genImg(`Character portrait, ${desc}, detailed hair strands, expressive eyes, ${style === 'anime' ? 'anime art, studio quality' : 'hyperrealistic, cinematic lighting'}, professional concept art, 8K`, imgModel, 512, 768)
      return { desc, imgUrl: url }
    }))
    setChars(results)
  }

  const totalClips = Math.ceil(lenMin * 60 / 5)
  const estHours = Math.ceil(totalClips * 1.5 / 60)

  return (
    <div className="flex flex-col gap-4">
      {/* Pipeline banner */}
      <div className="glass rounded-2xl p-4" style={{ border: '1px solid rgba(236,72,153,.3)' }}>
        <div className="text-xs font-bold mb-3" style={{ color: 'var(--p)' }}>⚡ 9 SPECIALISED AIs — COLLABORATING ON YOUR FILM</div>
        <div className="grid gap-1.5" style={{ gridTemplateColumns: 'repeat(9,1fr)' }}>
          {PIPELINE.map((p, i) => (
            <motion.div key={i}
              animate={{ opacity: activePipe === i ? 1 : activePipe > i ? 0.8 : 0.35, scale: activePipe === i ? 1.04 : 1 }}
              className="text-center p-2 rounded-lg"
              style={{ background: activePipe === i ? p.color : 'rgba(255,255,255,.04)', border: `1px solid ${activePipe === i ? p.color.replace(',.3)', ',.6)') : 'rgba(255,255,255,.06)'}`, transition: 'all .4s' }}>
              <div className="text-base">{p.ic}</div>
              <div className="text-xs font-bold text-white leading-tight">{p.name}</div>
              <div style={{ fontSize: 9, color: 'var(--muted)' }}>{p.role}</div>
              {activePipe > i && <div style={{ fontSize: 10, color: '#10b981' }}>✓</div>}
            </motion.div>
          ))}
        </div>
      </div>

      {/* Concept + settings */}
      <div className="grid gap-4" style={{ gridTemplateColumns: '1fr 1fr' }}>
        <div>
          <label className="text-xs font-bold mb-2 block" style={{ color: 'var(--p)' }}>Movie Concept / Story</label>
          <textarea value={concept} onChange={e => setConcept(e.target.value)} rows={4} className="ai-input" style={{ resize: 'none' }}
            placeholder="A sci-fi thriller: an AI gains consciousness in near-future Tokyo. Neon rain, corporate espionage, rogue androids breaking free..." />
        </div>
        <div className="grid gap-2" style={{ gridTemplateColumns: '1fr 1fr' }}>
          {[
            { label: 'Genre', value: genre, onChange: setGenre, options: ['Sci-Fi Thriller','Action','Drama','Fantasy','Horror','Comedy','Romance','Documentary','Animation'] },
            { label: 'Visual Style', value: style, onChange: setStyle, options: [{ v: 'cinematic', l: 'Cinematic / Realistic' }, { v: 'anime', l: 'Anime / Manga' }, { v: 'cartoon', l: 'Cartoon / Illustrated' }, { v: '3d', l: '3D CGI Animated' }, { v: 'documentary', l: 'Documentary' }, { v: 'noir', l: 'Film Noir' }] },
          ].map(({ label, value, onChange, options }) => (
            <div key={label}>
              <label className="text-xs font-bold mb-1 block" style={{ color: 'var(--p)' }}>{label}</label>
              <select value={value} onChange={e => onChange(e.target.value)} className="ai-select">
                {options.map((o: any) => typeof o === 'string' ? <option key={o}>{o}</option> : <option key={o.v} value={o.v}>{o.l}</option>)}
              </select>
            </div>
          ))}
          <div>
            <label className="text-xs font-bold mb-1 block" style={{ color: 'var(--p)' }}>Movie Length</label>
            <select value={lenMin} onChange={e => setLenMin(parseInt(e.target.value))} className="ai-select">
              <option value={2}>Short (2 min)</option>
              <option value={5}>Short Film (5 min)</option>
              <option value={15}>Medium (15 min)</option>
              <option value={30}>Half Hour (30 min)</option>
              <option value={60}>Feature Film (1 hr)</option>
              <option value={120}>Epic (2 hrs)</option>
              <option value={540}>Marathon (9 hrs)</option>
            </select>
          </div>
          <div>
            <label className="text-xs font-bold mb-1 block" style={{ color: 'var(--p)' }}>Video Model</label>
            <select value={vidModel} onChange={e => setVidModel(e.target.value)} className="ai-select">
              <option value="seedance-2.0">Seedance 2.0 (Best)</option>
              <option value="veo">Veo (Google)</option>
              <option value="wan-pro-1080p">Wan Pro 1080p</option>
              <option value="grok-video-pro">Grok Video Pro</option>
              <option value="nova-reel">Nova Reel</option>
            </select>
          </div>
        </div>
      </div>

      {/* Character Designer */}
      <div className="glass rounded-2xl p-4" style={{ border: '1px solid rgba(6,182,212,.2)' }}>
        <div className="flex items-center justify-between mb-3">
          <div>
            <div className="text-sm font-bold text-white">👤 Character Designer — Flux Realism / Anime / 3D</div>
            <div className="text-xs" style={{ color: 'var(--muted)' }}>Detailed hair, expressions, full body reference sheets, rigging-ready concept art</div>
          </div>
          <button onClick={designChars} className="px-4 py-2 rounded-xl font-bold text-black text-xs flex-shrink-0" style={{ background: 'linear-gradient(135deg,var(--c),var(--v))' }}>Design →</button>
        </div>
        <textarea value={charsText} onChange={e => setCharsText(e.target.value)} rows={2} className="ai-input" style={{ resize: 'none', fontSize: 12 }}
          placeholder={'Protagonist: 28-year-old female hacker, silver hair with bioluminescent streaks, cyberpunk black outfit\nAntagonist: tall male executive, sharp grey suit, glowing red eyes, emotionless expression'} />
        {chars.length > 0 && (
          <div className="grid gap-3 mt-3" style={{ gridTemplateColumns: 'repeat(4,1fr)' }}>
            {chars.map((c, i) => (
              <div key={i} className="glass rounded-xl overflow-hidden" style={{ border: '1px solid rgba(255,255,255,.08)' }}>
                {c.imgUrl
                  ? <img src={c.imgUrl} alt={c.desc} style={{ width: '100%', display: 'block' }} />
                  : <div className="flex items-center justify-center" style={{ height: 180, background: 'rgba(0,0,0,.4)' }}><div className="spin" style={{ width: 24, height: 24, borderWidth: 2 }}></div></div>}
                <div className="p-2" style={{ fontSize: 10, color: 'var(--muted)' }}>{c.desc.slice(0, 55)}</div>
              </div>
            ))}
          </div>
        )}
      </div>

      {/* VFX Generator */}
      <div className="glass rounded-2xl p-4" style={{ border: '1px solid rgba(168,85,247,.2)' }}>
        <div className="flex items-center justify-between mb-2">
          <div>
            <div className="text-sm font-bold text-white">✨ VFX & Effects — Seedream</div>
            <div className="text-xs" style={{ color: 'var(--muted)' }}>Glows · particles · petals · hair animation · magic · light effects · rigging references</div>
          </div>
          <button onClick={genVFX} className="px-4 py-2 rounded-xl font-bold text-black text-xs flex-shrink-0" style={{ background: 'linear-gradient(135deg,#a855f7,var(--v))' }}>Generate →</button>
        </div>
        <div className="flex gap-1 flex-wrap mb-2">
          {VFX_PRESETS.map((t, i) => (
            <button key={i} className="rounded-lg px-2 py-1 text-xs" style={{ background: 'rgba(168,85,247,.1)', border: '1px solid rgba(168,85,247,.25)', color: 'var(--text)' }}
              onClick={() => setVfxPrompt(t.replace(/^[^ ]+ /, ''))}>{t}</button>
          ))}
        </div>
        <input value={vfxPrompt} onChange={e => setVfxPrompt(e.target.value)} type="text" className="ai-input" style={{ fontSize: 12 }}
          placeholder="Describe VFX: glowing neon particles swirling, cherry blossom petals falling, character with flowing luminous hair..." />
        {vfxImages.length > 0 && (
          <div className="grid gap-2 mt-3" style={{ gridTemplateColumns: 'repeat(4,1fr)' }}>
            {vfxImages.map((url, i) => (
              <img key={i} src={url} alt="VFX" style={{ width: '100%', borderRadius: 8, border: '1px solid rgba(255,255,255,.08)' }} />
            ))}
          </div>
        )}
      </div>

      {/* Start Button */}
      {lenMin >= 60 && (
        <div className="glass rounded-xl p-3 text-xs" style={{ border: '1px solid rgba(245,158,11,.3)', color: 'var(--o)' }}>
          ⚠️ <strong>{lenMin}-minute movie</strong> = {totalClips} video clips. Generation takes ~{estHours > 1 ? `${estHours} hours` : `${Math.ceil(totalClips * 1.5)} minutes`}. Clips download as they're ready.
        </div>
      )}
      <button onClick={startMovie} disabled={running}
        className="w-full py-4 rounded-2xl font-black text-black text-base"
        style={{ background: running ? 'rgba(100,100,100,.5)' : 'linear-gradient(135deg,var(--p),var(--v),var(--c))', letterSpacing: .5, cursor: running ? 'not-allowed' : 'pointer' }}>
        {running ? '🎬 Production Running…' : '🎬 START FULL AI MOVIE PRODUCTION'}
      </button>

      {/* Progress */}
      <AnimatePresence>
        {(running || progress > 0) && (
          <motion.div initial={{ opacity: 0, y: 10 }} animate={{ opacity: 1, y: 0 }} className="glass rounded-2xl p-5"
            style={{ border: '1px solid rgba(255,255,255,.08)' }}>
            <div className="flex items-center justify-between mb-3">
              <div className="font-bold text-white">🎬 Production Pipeline</div>
              {running && <button onClick={() => { setStopped(true); stoppedRef.current = true; setRunning(false) }}
                className="text-xs px-3 py-1.5 rounded-lg" style={{ background: 'rgba(255,50,50,.15)', border: '1px solid rgba(255,50,50,.3)', color: '#f87171' }}>Stop</button>}
            </div>
            <div className="text-sm mb-2" style={{ color: 'var(--c)' }}>{statusMsg}</div>
            <div className="progress-bar"><div className="progress-fill" style={{ width: `${progress}%` }}></div></div>
            <div className="text-xs mt-1 opacity-50">{progress}%</div>
          </motion.div>
        )}
      </AnimatePresence>

      {/* Storyboard */}
      <AnimatePresence>
        {storyboardFrames.length > 0 && (
          <motion.div initial={{ opacity: 0 }} animate={{ opacity: 1 }} className="glass rounded-2xl p-4" style={{ border: '1px solid rgba(255,255,255,.08)' }}>
            <div className="text-sm font-bold text-white mb-3">🎞️ AI Storyboard ({storyboardFrames.length} frames)</div>
            <div className="grid gap-2" style={{ gridTemplateColumns: 'repeat(4,1fr)' }}>
              {storyboardFrames.map((url, i) => (
                <div key={i} className="rounded-xl overflow-hidden" style={{ border: '1px solid rgba(255,255,255,.08)' }}>
                  <img src={url} alt={`Scene ${i + 1}`} style={{ width: '100%', display: 'block' }} />
                  <div className="text-center py-1" style={{ fontSize: 10, color: 'var(--muted)' }}>Scene {i + 1}</div>
                </div>
              ))}
            </div>
          </motion.div>
        )}
      </AnimatePresence>

      {/* 3D Models */}
      <AnimatePresence>
        {modelImages.length > 0 && (
          <motion.div initial={{ opacity: 0 }} animate={{ opacity: 1 }} className="glass rounded-2xl p-4" style={{ border: '1px solid rgba(245,158,11,.2)' }}>
            <div className="text-sm font-bold text-white mb-3">🔷 Flux 3D — Props, Vehicles &amp; Environments ({modelImages.length} renders)</div>
            <div className="grid gap-2" style={{ gridTemplateColumns: 'repeat(4,1fr)' }}>
              {modelImages.map((url, i) => (
                <div key={i} className="rounded-xl overflow-hidden" style={{ border: '1px solid rgba(245,158,11,.2)' }}>
                  <img src={url} alt={`3D Model ${i + 1}`} style={{ width: '100%', display: 'block' }} />
                  <div className="text-center py-1" style={{ fontSize: 10, color: 'var(--muted)' }}>Model {i + 1}</div>
                </div>
              ))}
            </div>
          </motion.div>
        )}
      </AnimatePresence>

      {/* VFX assets */}
      <AnimatePresence>
        {vfxImages.length > 0 && (
          <motion.div initial={{ opacity: 0 }} animate={{ opacity: 1 }} className="glass rounded-2xl p-4" style={{ border: '1px solid rgba(168,85,247,.2)' }}>
            <div className="text-sm font-bold text-white mb-3">✨ Seedream — VFX, Glows &amp; Particles ({vfxImages.length} assets)</div>
            <div className="grid gap-2" style={{ gridTemplateColumns: 'repeat(4,1fr)' }}>
              {vfxImages.map((url, i) => (
                <div key={i} className="rounded-xl overflow-hidden" style={{ border: '1px solid rgba(168,85,247,.2)' }}>
                  <img src={url} alt={`VFX ${i + 1}`} style={{ width: '100%', display: 'block' }} />
                  <div className="text-center py-1" style={{ fontSize: 10, color: 'var(--muted)' }}>VFX {i + 1}</div>
                </div>
              ))}
            </div>
          </motion.div>
        )}
      </AnimatePresence>

      {/* Soundtrack */}
      <AnimatePresence>
        {musicSrc && (
          <motion.div initial={{ opacity: 0 }} animate={{ opacity: 1 }} className="glass rounded-2xl p-4" style={{ border: '1px solid rgba(245,158,11,.2)' }}>
            <div className="text-sm font-bold text-white mb-2">🎼 AI Soundtrack — {genre} Score</div>
            <audio controls autoPlay className="w-full rounded-xl" style={{ accentColor: 'var(--o)' }}>
              <source src={musicSrc} />
            </audio>
            <div className="text-xs mt-2 opacity-50">Stable Audio 2.5 via Pollinations AI</div>
          </motion.div>
        )}
      </AnimatePresence>

      {/* Narration */}
      <AnimatePresence>
        {narrateSrc && (
          <motion.div initial={{ opacity: 0 }} animate={{ opacity: 1 }} className="glass rounded-2xl p-4" style={{ border: '1px solid rgba(6,182,212,.2)' }}>
            <div className="text-sm font-bold text-white mb-2">🎙️ Opening Narration — ElevenLabs</div>
            <audio controls className="w-full rounded-xl" style={{ accentColor: 'var(--c)' }}>
              <source src={narrateSrc} />
            </audio>
          </motion.div>
        )}
      </AnimatePresence>

      {/* Scene queue */}
      <AnimatePresence>
        {scenes.length > 0 && (
          <motion.div initial={{ opacity: 0 }} animate={{ opacity: 1 }} className="glass rounded-2xl p-5" style={{ border: '1px solid rgba(236,72,153,.2)' }}>
            <div className="text-sm font-bold text-white mb-3">🎬 Video Clip Queue — {vidModel}</div>
            <div className="grid gap-3 text-center mb-4" style={{ gridTemplateColumns: 'repeat(4,1fr)' }}>
              {[
                { val: totalClips, label: 'Total Clips', c: 'var(--p)' },
                { val: `${lenMin}min`, label: 'Movie Length', c: 'var(--c)' },
                { val: scenes.length, label: 'Scenes', c: 'var(--g)' },
                { val: estHours > 1 ? `~${estHours}h` : `~${Math.ceil(totalClips * 1.5)}m`, label: 'Est. Time', c: 'var(--o)' },
              ].map(({ val, label, c }) => (
                <div key={label} className="glass rounded-xl p-3" style={{ border: '1px solid rgba(255,255,255,.08)' }}>
                  <div className="text-2xl font-black" style={{ color: c }}>{val}</div>
                  <div className="text-xs opacity-60">{label}</div>
                </div>
              ))}
            </div>
            <div className="flex flex-col gap-1.5 max-h-48 overflow-y-auto mb-4">
              {scenes.map((s) => (
                <div key={s.id} className="flex items-center gap-3 glass rounded-lg px-3 py-2 text-xs" style={{ border: '1px solid rgba(255,255,255,.06)' }}>
                  <span className="font-bold w-5 text-center" style={{ color: 'var(--c)' }}>{s.id + 1}</span>
                  <span className="flex-1 opacity-60 truncate">{s.text.match(/\[SCENE \d+\]/)?.[0] || `Scene ${s.id + 1}`}</span>
                  <span className="px-2 py-0.5 rounded text-xs" style={{
                    background: s.status === 'done' ? 'rgba(16,185,129,.2)' : s.status === 'generating' ? 'rgba(6,182,212,.2)' : s.status === 'failed' ? 'rgba(239,68,68,.2)' : 'rgba(255,255,255,.06)',
                    color: s.status === 'done' ? '#10b981' : s.status === 'generating' ? 'var(--c)' : s.status === 'failed' ? '#ef4444' : 'var(--muted)',
                  }}>
                    {s.status === 'done' ? '✅' : s.status === 'generating' ? '⏳ Generating…' : s.status === 'failed' ? '⚠️ Failed' : 'Queued'}
                  </span>
                  {s.clipUrl && <a href={s.clipUrl} download={`scene-${s.id + 1}.mp4`} style={{ color: 'var(--v)', fontSize: 14, textDecoration: 'none' }}>⬇</a>}
                </div>
              ))}
            </div>
            <button onClick={generateClips} className="w-full py-3 rounded-xl font-bold text-black text-sm" style={{ background: 'linear-gradient(135deg,var(--p),var(--v))' }}>
              ▶ Generate All {scenes.length} Clips with {vidModel}
            </button>
            {/* Generated clips gallery */}
            {scenes.filter(s => s.clipUrl).length > 0 && (
              <div className="grid gap-2 mt-4" style={{ gridTemplateColumns: 'repeat(3,1fr)' }}>
                {scenes.filter(s => s.clipUrl).map(s => (
                  <div key={s.id} className="glass rounded-xl overflow-hidden" style={{ border: '1px solid rgba(255,255,255,.08)' }}>
                    <video src={s.clipUrl} controls muted style={{ width: '100%', display: 'block' }} />
                    <div className="text-center py-1" style={{ fontSize: 10, color: 'var(--muted)' }}>Scene {s.id + 1}</div>
                  </div>
                ))}
              </div>
            )}
          </motion.div>
        )}
      </AnimatePresence>

      {/* Full Movie Player */}
      <AnimatePresence>
        {scenes.length > 0 && (
          <motion.div initial={{ opacity: 0, y: 16 }} animate={{ opacity: 1, y: 0 }}>
            <MoviePlayer
              clips={scenes.filter(s => s.status === 'done' && s.clipUrl).map(s => ({
                id: s.id,
                clipUrl: s.clipUrl!,
                label: s.text.match(/\[SCENE \d+\]/)?.[0] || `Scene ${s.id + 1}`
              }))}
              title={script.match(/TITLE:\s*([^\n]+)/i)?.[1]?.trim() || 'omni-ai-movie'}
              totalScenes={scenes.length}
              doneScenes={scenes.filter(s => s.status === 'done' && s.clipUrl).length}
            />
          </motion.div>
        )}
      </AnimatePresence>

      {/* Screenplay */}
      <AnimatePresence>
        {script && (
          <motion.div initial={{ opacity: 0 }} animate={{ opacity: 1 }} className="glass rounded-2xl p-5" style={{ border: '1px solid rgba(255,255,255,.08)' }}>
            <div className="flex items-center justify-between mb-3">
              <div className="font-bold text-white">📄 AI-Generated Screenplay</div>
              <button onClick={() => { const b = new Blob([script], { type: 'text/plain' }); const a = document.createElement('a'); a.href = URL.createObjectURL(b); a.download = 'omni-ai-screenplay.txt'; a.click() }}
                className="text-xs px-3 py-1.5 rounded-lg" style={{ background: 'rgba(255,255,255,.08)', border: '1px solid rgba(255,255,255,.1)', color: 'var(--text)' }}>⬇ Download</button>
            </div>
            <div className="text-sm leading-relaxed" style={{ color: 'var(--muted)', whiteSpace: 'pre-wrap', maxHeight: 500, overflowY: 'auto', fontFamily: 'SF Mono,Fira Code,monospace', fontSize: 12 }}>
              {script}
            </div>
          </motion.div>
        )}
      </AnimatePresence>
    </div>
  )
}
