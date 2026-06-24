import { useEffect, useRef, useState } from 'react'
import { motion } from 'framer-motion'
import type { Mode } from '../App'

const SEQS = [
  { inp: 'generate a react dashboard', resp: '⚛️ Generated dashboard with KPI cards, Recharts, Framer Motion — 220 lines' },
  { inp: 'create image: neon tokyo city', resp: '🖼️ Flux Pro generating → 4K photorealistic in 8s' },
  { inp: 'generate video: ocean waves', resp: '🎬 Seedance 2.0 (90s)… → HD video ready ▶' },
  { inp: 'speak: Welcome to Omni AI', resp: '🎵 ElevenLabs nova voice → Audio ready ▶' },
  { inp: 'compose epic film score', resp: '🎼 Stable Audio 2.5 (30s)… → WAV ready ▶' },
  { inp: 'make a sci-fi movie 30 min', resp: '🎥 9 AIs collaborating → Script → Characters → Scenes → Music' },
  { inp: 'what is the Higgs boson?', resp: '⚛ Gives particles mass via the Higgs field — discovered CERN 2012' },
]

const MODES = [
  { id: 'chat', ic: '💬', label: 'Chat', sub: 'Claude 4.6' },
  { id: 'image', ic: '🖼️', label: 'Image', sub: 'Flux Pro' },
  { id: 'video', ic: '🎬', label: 'Video', sub: 'Seedance 2.0' },
  { id: 'audio', ic: '🎵', label: 'Speech', sub: 'ElevenLabs' },
  { id: 'music', ic: '🎼', label: 'Music', sub: 'Suno AI' },
  { id: 'code', ic: '⚛️', label: 'Code', sub: 'v0 killer' },
  { id: 'movie', ic: '🎥', label: 'Movie', sub: '9hr films' },
] as { id: Mode; ic: string; label: string; sub: string }[]

export default function Hero({ setMode }: { setMode: (m: Mode) => void }) {
  const tinRef = useRef<HTMLSpanElement>(null)
  const tresRef = useRef<HTMLDivElement>(null)
  const tcurRef = useRef<HTMLSpanElement>(null)
  const seqIdx = useRef(0)

  useEffect(() => {
    let cancelled = false
    const wait = (ms: number) => new Promise<void>(r => setTimeout(r, ms))
    async function loop() {
      while (!cancelled) {
        const s = SEQS[seqIdx.current++ % SEQS.length]
        if (tinRef.current) tinRef.current.textContent = ''
        if (tresRef.current) tresRef.current.textContent = ''
        if (tcurRef.current) tcurRef.current.style.display = 'inline-block'
        for (const ch of s.inp) {
          if (cancelled) return
          if (tinRef.current) tinRef.current.textContent += ch
          await wait(40 + Math.random() * 20)
        }
        await wait(400)
        if (tcurRef.current) tcurRef.current.style.display = 'none'
        await wait(200)
        if (tresRef.current) tresRef.current.textContent = s.resp
        await wait(3200)
      }
    }
    loop()
    return () => { cancelled = true }
  }, [])

  return (
    <section className="relative z-10 flex items-center justify-center text-center px-6"
      style={{ minHeight: '100vh', paddingTop: 100, paddingBottom: 60 }}>
      <div style={{ maxWidth: 960 }}>
        <motion.div initial={{ opacity: 0, y: 20 }} animate={{ opacity: 1, y: 0 }} transition={{ delay: .1 }}
          className="inline-flex items-center gap-2 px-4 py-1.5 rounded-full text-sm mb-8 glass"
          style={{ border: '1px solid rgba(6,182,212,.25)', color: 'var(--c)' }}>
          <span className="pulse-dot inline-block w-2 h-2 rounded-full" style={{ background: '#10b981' }}></span>
          Claude · Flux Pro · Seedance 2.0 · Veo · ElevenLabs · Suno — All Free
        </motion.div>

        <motion.h1
          initial={{ opacity: 0, scale: .92 }} animate={{ opacity: 1, scale: 1 }} transition={{ delay: .2, type: 'spring', stiffness: 120 }}
          className="glitch gt font-black"
          data-text="OMNI AI"
          style={{ fontSize: 'clamp(80px,14vw,150px)', letterSpacing: -5, lineHeight: .88, marginBottom: 24 }}>
          OMNI AI
        </motion.h1>

        <motion.p initial={{ opacity: 0, y: 20 }} animate={{ opacity: 1, y: 0 }} transition={{ delay: .35 }}
          className="text-xl mb-10 mx-auto" style={{ color: 'var(--muted)', maxWidth: 620, lineHeight: 1.6 }}>
          The world's most powerful <strong style={{ color: 'var(--c)' }}>free AI platform</strong>.
          Generate code, images, full-length movies, music, speech — using{' '}
          <strong style={{ color: 'var(--v)' }}>9 AIs working together</strong>.
        </motion.p>

        <motion.div
          initial="hidden" animate="visible"
          variants={{ visible: { transition: { staggerChildren: .06 } } }}
          className="grid gap-2 mb-10"
          style={{ gridTemplateColumns: 'repeat(7,1fr)' }}>
          {MODES.map(m => (
            <motion.div key={m.id}
              variants={{ hidden: { opacity: 0, y: 16 }, visible: { opacity: 1, y: 0 } }}
              whileHover={{ scale: 1.06, y: -3 }}
              whileTap={{ scale: .96 }}
              className="glass rounded-2xl p-3 tilt cursor-pointer"
              style={{ border: '1px solid rgba(255,255,255,.08)' }}
              onClick={() => { setMode(m.id as Mode); document.getElementById('gen')?.scrollIntoView({ behavior: 'smooth' }) }}>
              <div className="text-xl mb-1">{m.ic}</div>
              <div className="text-xs font-bold text-white">{m.label}</div>
              <div className="text-xs opacity-50">{m.sub}</div>
            </motion.div>
          ))}
        </motion.div>

        <motion.div initial={{ opacity: 0, y: 20 }} animate={{ opacity: 1, y: 0 }} transition={{ delay: .6 }}
          className="rounded-2xl p-5 text-left mx-auto"
          style={{ maxWidth: 700, background: 'rgba(0,0,0,.65)', border: '1px solid rgba(6,182,212,.15)', fontFamily: 'SF Mono,Fira Code,monospace', fontSize: 13 }}>
          <div className="flex items-center gap-2 mb-4 pb-3" style={{ borderBottom: '1px solid rgba(255,255,255,.05)' }}>
            <div className="w-3 h-3 rounded-full" style={{ background: '#ff5f57' }}></div>
            <div className="w-3 h-3 rounded-full" style={{ background: '#febc2e' }}></div>
            <div className="w-3 h-3 rounded-full" style={{ background: '#28c840' }}></div>
            <div className="flex-1 text-center text-xs" style={{ color: 'var(--muted)' }}>omni-ai — terminal</div>
          </div>
          <div style={{ color: '#8890c0' }}>🚀 Omni AI v4.0 — 9 AI Modes · 25+ Models · Free Forever</div>
          <div style={{ color: '#8890c0' }}>🤖 Claude · Flux · Seedance 2.0 · Veo · ElevenLabs · Suno · Stable Audio</div>
          <div className="mt-2">
            <span style={{ color: '#10b981' }}>you ❯ </span>
            <span style={{ color: 'var(--c)' }} ref={tinRef}></span>
            <span ref={tcurRef} style={{ display: 'inline-block', width: 8, height: 14, background: 'var(--c)', animation: 'blink 1s step-end infinite', verticalAlign: 'middle' }}></span>
          </div>
          <div className="mt-1" style={{ color: 'var(--c)' }} ref={tresRef}></div>
        </motion.div>
      </div>
    </section>
  )
}
