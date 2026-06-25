import { useState, useCallback } from 'react'
import Header from './components/Header.jsx'
import Hero from './components/Hero.jsx'
import Generator from './components/Generator.jsx'
import Gallery from './components/Gallery.jsx'
import Pricing from './components/Pricing.jsx'
import ToastContainer from './components/Toast.jsx'
import SessionModal from './components/SessionModal.jsx'
import { useTimer } from './hooks/useTimer.js'

export default function App() {
  const timer = useTimer()
  const [toasts, setToasts] = useState([])

  const addToast = useCallback((message, type = 'info') => {
    const id = Date.now() + Math.random()
    setToasts(t => [...t, { id, message, type }])
  }, [])

  const removeToast = useCallback(id => {
    setToasts(t => t.filter(x => x.id !== id))
  }, [])

  return (
    <div className="min-h-screen" style={{ background: '#08090d' }}>
      {/* Background */}
      <div className="fixed inset-0 bg-grid pointer-events-none" />
      <div className="fixed inset-0 pointer-events-none overflow-hidden">
        <div className="absolute -top-48 -left-36 w-[600px] h-[600px] rounded-full opacity-40"
          style={{ background: 'radial-gradient(circle, #7C3AED 0%, transparent 70%)', filter: 'blur(100px)' }} />
        <div className="absolute -bottom-36 -right-24 w-[500px] h-[500px] rounded-full opacity-35"
          style={{ background: 'radial-gradient(circle, #2563EB 0%, transparent 70%)', filter: 'blur(100px)' }} />
        <div className="absolute top-1/2 left-1/2 -translate-x-1/2 -translate-y-1/2 w-[800px] h-[400px] rounded-full opacity-10"
          style={{ background: 'radial-gradient(ellipse, #7C3AED 0%, transparent 70%)', filter: 'blur(80px)' }} />
      </div>

      <Header timer={timer} />
      <main className="relative z-10">
        <Hero />
        <Generator timer={timer} onToast={addToast} />
        <Gallery />
        <Pricing />
      </main>

      <footer className="relative z-10 border-t py-8 px-6" style={{ borderColor: 'rgba(255,255,255,0.06)' }}>
        <div className="max-w-7xl mx-auto flex items-center justify-between flex-wrap gap-4">
          <div className="flex items-center gap-2.5">
            <div className="w-7 h-7 rounded-full" style={{ background: 'linear-gradient(135deg,#7C3AED,#2563EB)' }}>
              <svg viewBox="0 0 28 28" fill="none" className="w-full h-full">
                <path d="M9 14L14 9L19 14L14 19Z" fill="white" opacity="0.9" />
                <circle cx="14" cy="14" r="2.5" fill="white" />
              </svg>
            </div>
            <span className="font-bold tracking-tight">Seedance <span className="text-[#8b8fa8] font-normal">2.0</span></span>
          </div>
          <p className="text-xs text-[#555872]">© 2025 Seedance AI. All rights reserved. Powered by Seedance 2.0 Ultra.</p>
        </div>
      </footer>

      <ToastContainer toasts={toasts} remove={removeToast} />
      <SessionModal show={timer.expired} onRestart={timer.restart} onUpgrade={() => {
        document.getElementById('pricing')?.scrollIntoView({ behavior: 'smooth' })
      }} />
    </div>
  )
}
