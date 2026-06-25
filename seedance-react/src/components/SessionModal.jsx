import { AlertCircle } from 'lucide-react'

export default function SessionModal({ show, onRestart, onUpgrade }) {
  if (!show) return null
  return (
    <div className="fixed inset-0 z-50 flex items-center justify-center p-6"
      style={{ background: 'rgba(0,0,0,0.75)', backdropFilter: 'blur(8px)' }}>
      <div className="panel max-w-sm w-full text-center p-10"
        style={{ boxShadow: '0 24px 80px rgba(0,0,0,0.7)' }}>
        <div className="w-12 h-12 rounded-full flex items-center justify-center mx-auto mb-5"
          style={{ background: 'rgba(124,58,237,0.12)', border: '1px solid rgba(124,58,237,0.3)' }}>
          <AlertCircle size={22} className="text-purple-400" />
        </div>
        <h3 className="text-xl font-bold mb-2">Free session ended</h3>
        <p className="text-sm text-[#8b8fa8] leading-relaxed mb-7">
          Your 30-minute free session has expired. Add your own API key or upgrade to Pro for unlimited access.
        </p>
        <div className="flex flex-col gap-2.5">
          <button onClick={onUpgrade} className="btn-primary w-full py-3">Upgrade to Pro</button>
          <button onClick={onRestart} className="btn-ghost w-full py-3 justify-center">Start New Session</button>
        </div>
      </div>
    </div>
  )
}
