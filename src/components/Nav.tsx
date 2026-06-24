import { motion } from 'framer-motion'
import type { Mode } from '../App'

const MODES: { id: Mode; label: string; icon: string }[] = [
  { id: 'chat', label: 'Chat', icon: '💬' },
  { id: 'image', label: 'Image', icon: '🖼️' },
  { id: 'video', label: 'Video', icon: '🎬' },
  { id: 'audio', label: 'Speech', icon: '🎵' },
  { id: 'music', label: 'Music', icon: '🎼' },
  { id: 'code', label: 'Code', icon: '⚛️' },
  { id: 'movie', label: 'Movie', icon: '🎥' },
]

export default function Nav({ mode, setMode }: { mode: Mode; setMode: (m: Mode) => void }) {
  return (
    <nav className="fixed top-0 left-0 right-0 z-50 px-5 py-3"
      style={{ backdropFilter: 'blur(24px)', background: 'rgba(5,5,16,0.9)', borderBottom: '1px solid rgba(255,255,255,.06)' }}>
      <div className="max-w-7xl mx-auto flex items-center justify-between">
        <div className="flex items-center gap-2">
          <span className="text-xl font-black tracking-tight gt">⚡ OMNI AI</span>
          <span className="text-xs font-bold px-2 py-0.5 rounded border"
            style={{ color: '#10b981', borderColor: 'rgba(16,185,129,.3)', letterSpacing: 1 }}>FREE</span>
        </div>
        <div className="hidden md:flex items-center gap-1">
          {MODES.map(m => (
            <motion.button
              key={m.id}
              onClick={() => { setMode(m.id); document.getElementById('gen')?.scrollIntoView({ behavior: 'smooth' }) }}
              className="px-3 py-1.5 rounded-lg text-xs font-bold transition-all"
              animate={{
                background: mode === m.id ? 'linear-gradient(135deg,#7c3aed,#06b6d4)' : 'rgba(255,255,255,.04)',
                color: mode === m.id ? '#000' : '#64748b',
              }}
              whileHover={{ scale: 1.05 }}
              whileTap={{ scale: 0.95 }}
            >
              {m.icon} {m.label}
            </motion.button>
          ))}
        </div>
        <a href="https://github.com/robloxscripter6245366542/roblox-lua-obscator" target="_blank"
          className="text-xs font-bold px-3 py-2 rounded-lg glass transition-all hover:scale-105"
          style={{ border: '1px solid rgba(255,255,255,.1)' }}>GitHub →</a>
      </div>
    </nav>
  )
}
