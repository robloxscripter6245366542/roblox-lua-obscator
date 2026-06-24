import { motion } from 'framer-motion'

const FEATS = [
  { ic: '🎥', t: 'AI Movie Studio', d: '9 AIs collaborate: Claude scripts, Flux chars, Seedance films, Suno scores, ElevenLabs narrates' },
  { ic: '🎬', t: 'Long-Form Video', d: 'Queue 9hr+ movies — Seedance 2.0 & Veo generate scene-by-scene, clips download as ready' },
  { ic: '✨', t: 'VFX Generator', d: 'Seedream for glows, particles, petals, hair animation, magic effects — 4 variations per prompt' },
  { ic: '👤', t: 'Character Designer', d: 'Flux Realism for portraits, Flux Anime for manga, Flux 3D for CGI — detailed hair, rigging refs' },
  { ic: '🖼️', t: 'Image Generation', d: 'Flux Pro, Flux Realism, Flux Anime, Flux 3D, GPT Image, Seedream — best model for every use' },
  { ic: '⚛️', t: 'React Code Gen', d: 'Full shadcn/ui + Framer Motion + Tailwind components in TypeScript, better than v0.dev' },
  { ic: '💬', t: 'Claude AI Chat', d: '1M token context — code, math step-by-step, science, history, trivia, any topic' },
  { ic: '🎵', t: 'ElevenLabs Speech', d: '8+ voices: nova, alloy, echo, fable, onyx, shimmer, coral, sage — cinematic narration' },
  { ic: '🎼', t: 'Suno + Stable Audio', d: 'Full songs with vocals via Suno AI · Instrumental scores via Stable Audio 2.5 (190s WAV)' },
  { ic: '🎮', t: '3D & 2D Games', d: 'Three.js space shooters with enemies & particles · Canvas platformers with physics' },
  { ic: '🔌', t: 'Zero API Keys', d: 'Pollinations AI is 100% free — no signup, no credit card, no rate limits, forever free' },
  { ic: '🚀', t: 'Backend APIs', d: 'FastAPI, Express, GraphQL, WebSocket — production-ready with auth and databases' },
]

export default function FeaturesSection() {
  return (
    <section className="relative z-10 py-20 px-6">
      <div className="max-w-6xl mx-auto">
        <motion.div initial={{ opacity: 0, y: 20 }} whileInView={{ opacity: 1, y: 0 }} viewport={{ once: true }} className="mb-12">
          <div className="text-xs font-bold tracking-widest uppercase mb-3" style={{ color: '#10b981' }}>— Features</div>
          <h2 className="text-4xl font-black tracking-tight">Everything. <span className="gt">Free forever.</span></h2>
        </motion.div>
        <div className="grid grid-cols-4 gap-4">
          {FEATS.map((f, i) => (
            <motion.div key={i} initial={{ opacity: 0, y: 16 }} whileInView={{ opacity: 1, y: 0 }} transition={{ delay: i * .05 }} viewport={{ once: true }}
              whileHover={{ scale: 1.03, y: -3 }}
              className="glass rounded-2xl p-5 tilt" style={{ border: '1px solid rgba(255,255,255,.08)' }}>
              <div className="text-2xl mb-2">{f.ic}</div>
              <div className="font-bold text-white text-sm mb-1">{f.t}</div>
              <div className="text-xs leading-relaxed" style={{ color: 'var(--muted)' }}>{f.d}</div>
            </motion.div>
          ))}
        </div>
      </div>
    </section>
  )
}
