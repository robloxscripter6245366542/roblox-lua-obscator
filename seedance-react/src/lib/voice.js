export function speak(text) {
  return new Promise(resolve => {
    if (!window.speechSynthesis) { resolve(); return }
    window.speechSynthesis.cancel()
    const u = new SpeechSynthesisUtterance(text)
    // Pick best available voice
    const voices = window.speechSynthesis.getVoices()
    const preferred = voices.find(v => v.name.includes('Google') && v.lang.startsWith('en'))
      || voices.find(v => v.lang.startsWith('en-US') && !v.localService)
      || voices.find(v => v.lang.startsWith('en'))
    if (preferred) u.voice = preferred
    u.rate = 0.88
    u.pitch = 1.0
    u.volume = 1.0
    u.onend = resolve
    u.onerror = resolve
    window.speechSynthesis.speak(u)
  })
}

export function stopSpeech() {
  if (window.speechSynthesis) window.speechSynthesis.cancel()
}

export function loadVoices() {
  return new Promise(resolve => {
    const voices = window.speechSynthesis?.getVoices() || []
    if (voices.length > 0) { resolve(voices); return }
    window.speechSynthesis.onvoiceschanged = () => resolve(window.speechSynthesis.getVoices())
    setTimeout(() => resolve([]), 2000)
  })
}
