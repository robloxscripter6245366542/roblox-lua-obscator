import { useState, useEffect, useRef, useCallback } from 'react'
import { motion, AnimatePresence } from 'framer-motion'
import ThreeBackground from './components/ThreeBackground'
import Nav from './components/Nav'
import Hero from './components/Hero'
import StatsBar from './components/StatsBar'
import GeneratorSection from './components/GeneratorSection'
import StackSection from './components/StackSection'
import FeaturesSection from './components/FeaturesSection'
import ModelsSection from './components/ModelsSection'
import Footer from './components/Footer'

export type Mode = 'chat' | 'image' | 'video' | 'audio' | 'music' | 'code' | 'movie'

export default function App() {
  const [mode, setMode] = useState<Mode>('chat')

  return (
    <div className="min-h-screen" style={{ background: 'var(--bg)', color: 'var(--text)' }}>
      <ThreeBackground />
      <Nav mode={mode} setMode={setMode} />
      <Hero setMode={setMode} />
      <StatsBar />
      <GeneratorSection mode={mode} setMode={setMode} />
      <StackSection />
      <FeaturesSection />
      <ModelsSection />
      <Footer />
    </div>
  )
}
