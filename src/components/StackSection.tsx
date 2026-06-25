import { motion } from 'framer-motion'

const STACK = [
  { ic: '⚛️', name: 'React 18 + Vite', sub: 'TypeScript · App Router · Hooks', c: '#61dafb', desc: 'Functional components with hooks. Vite for lightning-fast builds. Full TypeScript throughout with proper interfaces and types.' },
  { ic: '🎨', name: 'Tailwind CSS', sub: 'Utility-first · Responsive · Dark-mode', c: '#38bdf8', desc: 'Zero CSS files — all styling via Tailwind utilities. Responsive breakpoints, dark mode tokens, glassmorphism effects.' },
  { ic: '🧩', name: 'shadcn/ui', sub: '40+ components · Radix UI · ARIA', c: '#fff', desc: 'Button, Card, Dialog, DropdownMenu, Input, Badge, Tabs, Sheet, Tooltip — all accessible, keyboard-navigable.' },
  { ic: '✨', name: 'Framer Motion', sub: 'Spring physics · Stagger · AnimatePresence', c: '#ff6bba', desc: 'Spring physics animations, page transitions, list stagger, whileHover/whileTap micro-interactions, AnimatePresence exit animations.' },
  { ic: '🔷', name: 'Three.js 3D', sub: 'Stars · Wireframes · Mouse parallax', c: '#7c3aed', desc: '5000-star particle field, floating wireframe solids, mouse parallax camera movement, real-time WebGL rendering.' },
  { ic: '🤖', name: 'Claude Sonnet 4.6', sub: '1M context · v0.dev killer · Free', c: '#f59e0b', desc: 'Claude via Pollinations AI with a massive v0.dev-expert system prompt. Generates complete React + Tailwind + shadcn components. Free forever.' },
]

export default function StackSection() {
  return (
    <section className="relative z-10 py-20 px-6" style={{ background: 'rgba(0,0,20,.5)' }}>
      <div className="max-w-6xl mx-auto">
        <motion.div initial={{ opacity: 0, y: 20 }} whileInView={{ opacity: 1, y: 0 }} viewport={{ once: true }} className="text-center mb-12">
          <div className="text-xs font-bold tracking-widest uppercase mb-3" style={{ color: 'var(--v)' }}>— Tech Stack</div>
          <h2 className="text-4xl font-black tracking-tight mb-3">The <span className="gt">v0.dev killer</span> stack</h2>
          <p className="text-lg" style={{ color: 'var(--muted)' }}>Omni AI is built with Vite + React + Tailwind — and generates code in the same stack. All free.</p>
        </motion.div>
        <div className="grid grid-cols-3 gap-5">
          {STACK.map((s, i) => (
            <motion.div key={i} initial={{ opacity: 0, y: 20 }} whileInView={{ opacity: 1, y: 0 }} transition={{ delay: i * .08 }} viewport={{ once: true }}
              whileHover={{ scale: 1.02, y: -4 }}
              className="glass rounded-2xl p-6 tilt" style={{ border: '1px solid rgba(255,255,255,.08)' }}>
              <div className="text-3xl mb-3">{s.ic}</div>
              <div className="font-bold text-white mb-1">{s.name}</div>
              <div className="text-xs mb-3" style={{ color: s.c }}>{s.sub}</div>
              <div className="text-sm leading-relaxed" style={{ color: 'var(--muted)' }}>{s.desc}</div>
            </motion.div>
          ))}
        </div>
      </div>
    </section>
  )
}
