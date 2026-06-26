import { Clock, Boxes } from 'lucide-react'
import clsx from 'clsx'

export default function Header({ timer, onOpenStudio }) {
  return (
    <header className="sticky top-0 z-50 glass border-b border-white/[0.07]">
      <div className="max-w-7xl mx-auto px-6 h-16 flex items-center gap-8">
        <Logo />
        <nav className="hidden md:flex gap-1 ml-auto mr-4">
          {['Generate', 'Gallery', 'Pricing'].map(link => (
            <a key={link} href={`#${link.toLowerCase()}`}
              className="px-3 py-1.5 rounded-lg text-sm font-medium text-[#8b8fa8] hover:text-white hover:bg-white/5 transition-all">
              {link}
            </a>
          ))}
          <button onClick={onOpenStudio}
            className="flex items-center gap-1.5 px-3 py-1.5 rounded-lg text-sm font-semibold transition-all"
            style={{ background: 'rgba(124,58,237,0.12)', border: '1px solid rgba(124,58,237,0.3)', color: '#a78bfa' }}>
            <Boxes size={14} />
            Studio
          </button>
        </nav>
        <div className="flex items-center gap-3">
          <span className="hidden sm:flex items-center px-2.5 py-1 rounded-md text-[11px] font-black tracking-widest text-white"
            style={{ background: 'linear-gradient(135deg,#7C3AED,#2563EB)' }}>4K</span>
          <TimerBadge timer={timer} />
        </div>
      </div>
    </header>
  )
}

function Logo() {
  return (
    <div className="flex items-center gap-2.5">
      <div className="w-8 h-8 rounded-full flex-shrink-0" style={{ background: 'linear-gradient(135deg,#7C3AED,#2563EB)' }}>
        <svg viewBox="0 0 32 32" fill="none" className="w-full h-full">
          <path d="M10 16L16 10L22 16L16 22Z" fill="white" opacity="0.9" />
          <circle cx="16" cy="16" r="3" fill="white" />
        </svg>
      </div>
      <span className="text-[17px] font-bold tracking-tight">Seedance <span className="text-[#8b8fa8] font-normal">2.0</span></span>
    </div>
  )
}

function TimerBadge({ timer }) {
  return (
    <div className={clsx(
      'flex items-center gap-1.5 px-3 py-1.5 rounded-lg border text-sm font-semibold transition-all',
      timer.expired
        ? 'bg-red-500/10 border-red-500/25 text-red-400'
        : timer.warning
        ? 'bg-yellow-500/10 border-yellow-500/25 text-yellow-400'
        : 'bg-emerald-500/10 border-emerald-500/25 text-emerald-400'
    )}>
      <Clock size={13} />
      <span>{timer.display}</span>
      <span className="text-[10px] font-bold tracking-wider opacity-70">FREE</span>
    </div>
  )
}
