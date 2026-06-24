import { motion, AnimatePresence } from 'framer-motion'
import type { Mode } from '../App'
import ChatPanel from './panels/ChatPanel'
import ImagePanel from './panels/ImagePanel'
import VideoPanel from './panels/VideoPanel'
import AudioPanel from './panels/AudioPanel'
import MusicPanel from './panels/MusicPanel'
import CodePanel from './panels/CodePanel'
import MoviePanel from './panels/MoviePanel'

const TABS: { id: Mode; icon: string; label: string }[] = [
  { id: 'chat', icon: '💬', label: 'Chat' },
  { id: 'image', icon: '🖼️', label: 'Image' },
  { id: 'video', icon: '🎬', label: 'Video' },
  { id: 'audio', icon: '🎵', label: 'Speech' },
  { id: 'music', icon: '🎼', label: 'Music' },
  { id: 'code', icon: '⚛️', label: 'Code' },
  { id: 'movie', icon: '🎥', label: 'Movie' },
]

export default function GeneratorSection({ mode, setMode }: { mode: Mode; setMode: (m: Mode) => void }) {
  return (
    <section id="gen" className="relative z-10 py-20 px-6">
      <div className="max-w-7xl mx-auto">
        <motion.div initial={{ opacity: 0, y: 20 }} whileInView={{ opacity: 1, y: 0 }} viewport={{ once: true }} className="mb-8">
          <div className="text-xs font-bold tracking-widest uppercase mb-3" style={{ color: 'var(--c)' }}>— Generate</div>
          <h2 className="text-5xl font-black tracking-tight mb-3">Create <span className="gt">anything</span></h2>
        </motion.div>

        <div className="flex gap-2 mb-6 flex-wrap">
          {TABS.map(t => (
            <motion.button key={t.id}
              onClick={() => setMode(t.id)}
              className="px-3 py-2 rounded-lg text-xs font-bold glass"
              animate={{
                background: mode === t.id ? 'linear-gradient(135deg,#7c3aed,#06b6d4)' : 'rgba(255,255,255,.04)',
                color: mode === t.id ? '#000' : '#e2e8f0',
              }}
              whileHover={{ scale: 1.04 }}
              whileTap={{ scale: .96 }}
              style={{ border: '1px solid rgba(255,255,255,.1)' }}>
              {t.icon} {t.label}
            </motion.button>
          ))}
        </div>

        <AnimatePresence mode="wait">
          <motion.div key={mode}
            initial={{ opacity: 0, y: 12 }}
            animate={{ opacity: 1, y: 0 }}
            exit={{ opacity: 0, y: -8 }}
            transition={{ duration: .2 }}>
            {mode === 'chat' && <ChatPanel />}
            {mode === 'image' && <ImagePanel />}
            {mode === 'video' && <VideoPanel />}
            {mode === 'audio' && <AudioPanel />}
            {mode === 'music' && <MusicPanel />}
            {mode === 'code' && <CodePanel />}
            {mode === 'movie' && <MoviePanel />}
          </motion.div>
        </AnimatePresence>
      </div>
    </section>
  )
}
