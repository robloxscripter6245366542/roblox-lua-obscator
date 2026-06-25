export default function Hero() {
  return (
    <section className="relative z-10 pt-24 pb-16 px-6 text-center">
      <div className="max-w-3xl mx-auto">
        <div className="inline-flex items-center gap-2 px-4 py-1.5 rounded-full border mb-8 text-[13px] font-medium text-purple-300"
          style={{ background: 'rgba(124,58,237,0.1)', borderColor: 'rgba(124,58,237,0.3)' }}>
          <span className="w-2 h-2 rounded-full bg-emerald-400 animate-pulse-slow" />
          Seedance 2.0 Pro · 4K Ultra HD · 30 min Free
        </div>

        <h1 className="text-5xl sm:text-6xl lg:text-7xl font-black tracking-tighter leading-[1.05] mb-6">
          Turn Any Idea Into<br />
          <span className="text-gradient">Cinematic 4K Video</span>
        </h1>

        <p className="text-[17px] text-[#8b8fa8] leading-relaxed max-w-xl mx-auto mb-10">
          Generate stunning 4K videos in seconds with Seedance 2.0 — the world's most advanced AI video model.
          No account needed. 30 minutes free, unlimited generations.
        </p>

        <div className="inline-flex items-stretch rounded-2xl overflow-hidden border divide-x"
          style={{ background: '#10121a', borderColor: 'rgba(255,255,255,0.07)', divideColor: 'rgba(255,255,255,0.07)' }}>
          {[
            { num: '4K', label: 'Ultra HD' },
            { num: '30m', label: 'Free Usage' },
            { num: '∞', label: 'Generations' },
            { num: '15s', label: 'Max Clip' },
          ].map(({ num, label }, i) => (
            <div key={i} className="px-6 py-4 text-center" style={{ borderColor: 'rgba(255,255,255,0.07)' }}>
              <div className="text-2xl font-black tracking-tight">{num}</div>
              <div className="text-xs text-[#8b8fa8] font-medium mt-0.5">{label}</div>
            </div>
          ))}
        </div>
      </div>
    </section>
  )
}
