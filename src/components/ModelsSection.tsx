import { motion } from 'framer-motion'

const MODELS = [
  { ic: '💬', name: 'Claude Sonnet 4.6', provider: 'Anthropic via Pollinations', mode: 'Text / Code', c: 'var(--v)' },
  { ic: '🖼️', name: 'Flux Pro', provider: 'Black Forest Labs', mode: 'Image — Cinematic', c: 'var(--c)' },
  { ic: '👤', name: 'Flux Realism', provider: 'Black Forest Labs', mode: 'Image — Characters', c: '#a78bfa' },
  { ic: '🎌', name: 'Flux Anime', provider: 'Black Forest Labs', mode: 'Image — Anime Style', c: '#f472b6' },
  { ic: '🔷', name: 'Flux 3D', provider: 'Black Forest Labs', mode: 'Image — 3D Renders', c: 'var(--o)' },
  { ic: '✨', name: 'Seedream', provider: 'ByteDance', mode: 'Image — VFX / Glows', c: '#a855f7' },
  { ic: '🖼️', name: 'GPT Image Large', provider: 'OpenAI', mode: 'Image — Graphics', c: '#10a37f' },
  { ic: '🎬', name: 'Seedance 2.0', provider: 'ByteDance', mode: 'Video — Best Quality', c: 'var(--p)' },
  { ic: '🎬', name: 'Veo', provider: 'Google DeepMind', mode: 'Video — Cinematic', c: 'var(--g)' },
  { ic: '🎬', name: 'Wan Pro 1080p', provider: 'Alibaba DAMO', mode: 'Video — 1080p', c: 'var(--o)' },
  { ic: '🎵', name: 'ElevenLabs', provider: 'ElevenLabs', mode: 'Speech — 8 voices', c: '#a855f7' },
  { ic: '🎼', name: 'Stable Audio 2.5', provider: 'Stability AI', mode: 'Music — Instrumental', c: 'var(--o)' },
]

export default function ModelsSection() {
  return (
    <section className="relative z-10 py-20 px-6" style={{ background: 'rgba(0,0,20,.5)' }}>
      <div className="max-w-6xl mx-auto">
        <motion.div initial={{ opacity: 0, y: 20 }} whileInView={{ opacity: 1, y: 0 }} viewport={{ once: true }} className="text-center mb-12">
          <div className="text-xs font-bold tracking-widest uppercase mb-3" style={{ color: 'var(--c)' }}>— AI Models</div>
          <h2 className="text-4xl font-black tracking-tight">25+ models. <span className="gt">Zero cost.</span></h2>
          <p className="text-base mt-2" style={{ color: 'var(--muted)' }}>All powered by Pollinations AI — completely free, no API key, no signup, unlimited usage.</p>
        </motion.div>
        <div className="grid grid-cols-4 gap-4">
          {MODELS.map((m, i) => (
            <motion.div key={i} initial={{ opacity: 0, y: 16 }} whileInView={{ opacity: 1, y: 0 }} transition={{ delay: i * .05 }} viewport={{ once: true }}
              whileHover={{ scale: 1.04, y: -3 }}
              className="glass rounded-2xl p-5 text-center tilt" style={{ border: '1px solid rgba(255,255,255,.08)' }}>
              <div className="text-3xl mb-2">{m.ic}</div>
              <div className="font-bold text-white text-sm">{m.name}</div>
              <div className="text-xs mt-1" style={{ color: 'var(--muted)' }}>{m.provider}</div>
              <div className="text-xs font-bold mt-2 px-2 py-0.5 rounded-full inline-block"
                style={{ color: m.c, background: m.c.replace('var(--', 'rgba(').replace(')', '') + '18)', border: `1px solid ${m.c}40` }}>
                {m.mode}
              </div>
            </motion.div>
          ))}
        </div>
      </div>
    </section>
  )
}
