import { Play } from 'lucide-react'

const ITEMS = [
  { prompt: 'Dragon soaring over mountains at golden hour', tags: ['4K', 'Cinematic'], gradient: 'from-purple-950 to-blue-950' },
  { prompt: 'Bioluminescent jellyfish in the deep ocean', tags: ['4K', 'Realistic'], gradient: 'from-blue-950 to-teal-950' },
  { prompt: 'Cyberpunk city at night with neon lights', tags: ['4K', 'Cinematic'], gradient: 'from-purple-950 to-pink-950' },
  { prompt: 'Flower blooming in an enchanted forest', tags: ['1080p', 'Anime'], gradient: 'from-green-950 to-emerald-950' },
  { prompt: 'Astronaut watching Mars sunset', tags: ['4K', '3D Render'], gradient: 'from-orange-950 to-red-950' },
  { prompt: 'Northern lights over a frozen lake', tags: ['4K', 'Cinematic'], gradient: 'from-indigo-950 to-blue-950' },
]

export default function Gallery() {
  return (
    <section id="gallery" className="relative z-10 py-20 px-6">
      <div className="max-w-7xl mx-auto">
        <div className="text-center mb-12">
          <h2 className="text-4xl font-black tracking-tight mb-3">Community Creations</h2>
          <p className="text-[#8b8fa8]">Made with Seedance 2.5 · 4K Ultra HD</p>
        </div>
        <div className="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-3 gap-4">
          {ITEMS.map((item, i) => (
            <GalleryCard key={i} item={item} />
          ))}
        </div>
      </div>
    </section>
  )
}

function GalleryCard({ item }) {
  return (
    <div className="group panel p-0 overflow-hidden cursor-pointer transition-all duration-200 hover:-translate-y-1"
      style={{ borderColor: 'rgba(255,255,255,0.07)' }}
      onMouseEnter={e => e.currentTarget.style.borderColor = 'rgba(255,255,255,0.15)'}
      onMouseLeave={e => e.currentTarget.style.borderColor = 'rgba(255,255,255,0.07)'}>
      <div className={`relative aspect-video bg-gradient-to-br ${item.gradient} flex items-center justify-center`}>
        <div className="absolute inset-0 flex items-center justify-center opacity-0 group-hover:opacity-100 transition-opacity"
          style={{ background: 'rgba(0,0,0,0.3)' }}>
          <div className="w-12 h-12 rounded-full flex items-center justify-center"
            style={{ background: 'rgba(0,0,0,0.5)' }}>
            <Play size={20} className="text-white ml-0.5" />
          </div>
        </div>
        {/* Shimmer overlay */}
        <div className="absolute inset-0 opacity-20"
          style={{ background: 'radial-gradient(ellipse at 50% 50%, rgba(124,58,237,0.5) 0%, transparent 70%)' }} />
      </div>
      <div className="p-4">
        <p className="text-sm font-medium text-white mb-2.5 line-clamp-1">{item.prompt}</p>
        <div className="flex gap-1.5 flex-wrap">
          {item.tags.map(t => (
            <span key={t} className="text-[11px] font-semibold px-2 py-0.5 rounded-md text-purple-300"
              style={{ background: 'rgba(124,58,237,0.15)', border: '1px solid rgba(124,58,237,0.25)' }}>{t}</span>
          ))}
        </div>
      </div>
    </div>
  )
}
