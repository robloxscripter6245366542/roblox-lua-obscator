import { useState, useEffect, useRef } from 'react'

const TYPE_INSTR: Record<string, string> = {
  react: 'Generate a COMPLETE React functional component. Use: React 18 hooks, Tailwind CSS (no CSS files), shadcn/ui components from "@/components/ui/*", Lucide React icons, Framer Motion animations (motion.div, AnimatePresence, whileHover, whileTap, spring). TypeScript. All imports at top. Production-ready and beautiful.',
  nextjs: 'Generate a complete Next.js App Router page with "use client", TypeScript, Tailwind, shadcn/ui, Lucide, and Framer Motion.',
  threejs: 'Generate a complete self-contained HTML file with Three.js CDN. Make it visually stunning with lighting, materials, particles, and smooth animation.',
  canvas: 'Generate a complete self-contained HTML Canvas 2D game with smooth physics, particles, game loop, score, lives, and responsive controls.',
  python: 'Generate complete Python FastAPI code with Pydantic models, proper types, CRUD endpoints, error handling, and JWT auth.',
  lua: 'Generate complete Roblox Luau script with server/client separation, RemoteEvents, and proper Roblox API usage.',
}

const CODE_QPS = ['SaaS pricing page', 'Analytics dashboard', 'Login auth form', 'E-commerce card grid', 'Real-time chat UI', 'Calendar & booking']

const STARTER = `// Omni AI Code Generator — v0.dev killer
// Enter a prompt above → get complete React + Tailwind + shadcn/ui + Framer Motion code

import { motion } from "framer-motion"
import { Zap, Star, ArrowRight } from "lucide-react"
import { Button } from "@/components/ui/button"
import { Badge } from "@/components/ui/badge"

export default function HeroSection() {
  return (
    <motion.section
      initial={{ opacity: 0 }}
      animate={{ opacity: 1 }}
      className="min-h-screen bg-background flex items-center justify-center p-8"
    >
      <div className="text-center max-w-3xl">
        <motion.div initial={{ y: 20, opacity: 0 }} animate={{ y: 0, opacity: 1 }} transition={{ delay: 0.1 }}>
          <Badge variant="secondary" className="mb-6 gap-2">
            <Zap className="w-3 h-3" /> Powered by Omni AI
          </Badge>
        </motion.div>
        <motion.h1
          initial={{ y: 30, opacity: 0 }} animate={{ y: 0, opacity: 1 }}
          transition={{ delay: 0.2, type: "spring" }}
          className="text-6xl font-black tracking-tight mb-6 bg-gradient-to-r from-violet-600 to-cyan-500 bg-clip-text text-transparent"
        >
          Build anything
        </motion.h1>
        <motion.div className="flex gap-3 justify-center" initial={{ y: 20, opacity: 0 }} animate={{ y: 0, opacity: 1 }} transition={{ delay: 0.3 }}>
          <motion.div whileHover={{ scale: 1.05 }} whileTap={{ scale: 0.97 }}>
            <Button size="lg" className="gap-2">Get Started <ArrowRight className="w-4 h-4" /></Button>
          </motion.div>
        </motion.div>
      </div>
    </motion.section>
  )
}`

export default function CodePanel() {
  const [prompt, setPrompt] = useState('')
  const [type, setType] = useState('react')
  const [code, setCode] = useState(STARTER)
  const [loading, setLoading] = useState(false)
  const codeRef = useRef<HTMLElement>(null)

  useEffect(() => {
    if (codeRef.current && (window as any).hljs) {
      codeRef.current.removeAttribute('data-highlighted')
      ;(window as any).hljs.highlightElement(codeRef.current)
    }
  }, [code])

  const generate = async () => {
    if (!prompt.trim()) { alert('Enter a prompt!'); return }
    setCode('// Generating with Claude Sonnet 4.6…\n// Please wait…')
    setLoading(true)
    try {
      const full = `${TYPE_INSTR[type]}\n\nTask: ${prompt}`
      const r = await fetch('/api/chat', { method: 'POST', headers: { 'Content-Type': 'application/json' }, body: JSON.stringify({ messages: [{ role: 'user', content: full }] }) })
      const d = await r.json()
      const reply = d.reply || d.error || 'Error.'
      const match = reply.match(/```(?:\w+)?\n?([\s\S]+?)```/)
      setCode(match ? match[1].trim() : reply)
    } catch { setCode('// Error connecting. Please try again.') }
    finally { setLoading(false) }
  }

  const copyCode = () => { navigator.clipboard.writeText(code); alert('Copied!') }

  return (
    <div className="flex flex-col gap-3">
      <div className="glass rounded-2xl p-4" style={{ border: '1px solid rgba(124,58,237,.2)' }}>
        <div className="text-xs font-bold mb-2" style={{ color: 'var(--v)' }}>⚛️ React Component Generator — Tailwind · shadcn/ui · Lucide · Framer Motion · Better than v0.dev</div>
        <div className="flex gap-3">
          <textarea value={prompt} onChange={e => setPrompt(e.target.value)}
            onKeyDown={e => e.key === 'Enter' && !e.shiftKey && (e.preventDefault(), generate())}
            rows={2} placeholder="Build an analytics dashboard with KPI cards, area charts, dark theme, Framer Motion entrance animations, and shadcn/ui components..."
            className="ai-input flex-1" style={{ resize: 'none' }} />
          <div className="flex flex-col gap-2 flex-shrink-0">
            <select value={type} onChange={e => setType(e.target.value)} className="ai-select text-xs">
              <option value="react">React + Tailwind + shadcn</option>
              <option value="nextjs">Next.js App Router</option>
              <option value="threejs">Three.js 3D Scene</option>
              <option value="canvas">Canvas 2D Game</option>
              <option value="python">Python FastAPI</option>
              <option value="lua">Roblox Luau</option>
            </select>
            <button onClick={generate} disabled={loading} className="px-5 py-2 rounded-xl font-bold text-black text-sm" style={{ background: 'linear-gradient(135deg,var(--c),var(--v))' }}>
              {loading ? '…' : 'Generate ↑'}
            </button>
          </div>
        </div>
      </div>
      <div className="flex gap-2 flex-wrap">
        {CODE_QPS.map((t, i) => (
          <button key={i} className="glass rounded-lg px-3 py-1.5 text-xs transition-all"
            style={{ border: '1px solid rgba(255,255,255,.08)', color: 'var(--text)' }}
            onClick={() => { setPrompt(`${t} with React, Tailwind CSS, shadcn/ui, Lucide icons, and Framer Motion animations`); generate() }}>{t}</button>
        ))}
      </div>
      <div className="rounded-xl overflow-hidden" style={{ minHeight: 400, background: 'rgba(0,0,0,.6)', border: '1px solid rgba(255,255,255,.07)' }}>
        <div className="flex items-center justify-between px-4 py-2" style={{ borderBottom: '1px solid rgba(255,255,255,.06)', background: 'rgba(0,0,0,.4)' }}>
          <span className="text-xs font-mono" style={{ color: 'var(--muted)' }}>generated.tsx</span>
          <button onClick={copyCode} className="text-xs px-3 py-1 rounded" style={{ background: 'rgba(124,58,237,.15)', border: '1px solid rgba(124,58,237,.3)', color: 'var(--v)' }}>Copy</button>
        </div>
        <pre style={{ padding: 20, fontSize: 12.5, lineHeight: 1.65, overflow: 'auto' }}>
          <code className="language-tsx" ref={codeRef}>{code}</code>
        </pre>
      </div>
    </div>
  )
}
