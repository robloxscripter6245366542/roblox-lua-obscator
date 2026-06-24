import { motion } from 'framer-motion'

const STATS = [
  { val: '9', label: 'AI Modes' },
  { val: '25+', label: 'AI Models' },
  { val: '1M', label: 'Token Context' },
  { val: '9hr+', label: 'Movie Length' },
  { val: '∞', label: 'Usage Limits' },
  { val: '$0', label: 'Cost Forever' },
]

export default function StatsBar() {
  return (
    <div className="relative z-10 py-10 px-6"
      style={{ background: 'rgba(0,0,28,.6)', borderTop: '1px solid rgba(255,255,255,.04)', borderBottom: '1px solid rgba(255,255,255,.04)' }}>
      <div className="max-w-5xl mx-auto grid grid-cols-6 gap-4 text-center">
        {STATS.map((s, i) => (
          <motion.div key={i}
            initial={{ opacity: 0, y: 12 }} whileInView={{ opacity: 1, y: 0 }}
            transition={{ delay: i * .06 }} viewport={{ once: true }}>
            <div className="text-3xl font-black gt">{s.val}</div>
            <div className="text-xs mt-1" style={{ color: 'var(--muted)' }}>{s.label}</div>
          </motion.div>
        ))}
      </div>
    </div>
  )
}
