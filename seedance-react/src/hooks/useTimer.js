import { useState, useEffect, useRef, useCallback } from 'react'

const SESSION_SECS = 30 * 60

export function useTimer() {
  const [seconds, setSeconds] = useState(SESSION_SECS)
  const [running, setRunning] = useState(false)
  const intervalRef = useRef(null)

  const start = useCallback(() => {
    if (running) return
    setRunning(true)
  }, [running])

  const restart = useCallback(() => {
    clearInterval(intervalRef.current)
    setSeconds(SESSION_SECS)
    setRunning(true)
  }, [])

  useEffect(() => {
    if (!running) return
    intervalRef.current = setInterval(() => {
      setSeconds(s => {
        if (s <= 1) { clearInterval(intervalRef.current); setRunning(false); return 0 }
        return s - 1
      })
    }, 1000)
    return () => clearInterval(intervalRef.current)
  }, [running])

  const display = `${String(Math.floor(seconds / 60)).padStart(2, '0')}:${String(seconds % 60).padStart(2, '0')}`
  const expired = seconds === 0
  const warning = seconds <= 300 && seconds > 0

  return { seconds, display, expired, warning, start, restart }
}
