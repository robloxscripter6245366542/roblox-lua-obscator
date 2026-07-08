import { describe, it, expect, beforeEach, afterEach, vi } from 'vitest'
import { renderHook, act } from '@testing-library/react'
import { useTimer } from '../../src/hooks/useTimer.js'

describe('useTimer', () => {
  beforeEach(() => vi.useFakeTimers())
  afterEach(() => vi.useRealTimers())

  it('starts at 30:00, not running, not expired or warning', () => {
    const { result } = renderHook(() => useTimer())
    expect(result.current.seconds).toBe(30 * 60)
    expect(result.current.display).toBe('30:00')
    expect(result.current.expired).toBe(false)
    expect(result.current.warning).toBe(false)
  })

  it('counts down once started', () => {
    const { result } = renderHook(() => useTimer())
    act(() => result.current.start())
    act(() => vi.advanceTimersByTime(3000))
    expect(result.current.seconds).toBe(30 * 60 - 3)
    expect(result.current.display).toBe('29:57')
  })

  it('does not tick before start() is called', () => {
    const { result } = renderHook(() => useTimer())
    act(() => vi.advanceTimersByTime(5000))
    expect(result.current.seconds).toBe(30 * 60)
  })

  it('enters the warning window at 5 minutes remaining', () => {
    const { result } = renderHook(() => useTimer())
    act(() => result.current.start())
    // advance to exactly 5:00 remaining (1500s elapsed)
    act(() => vi.advanceTimersByTime((30 * 60 - 300) * 1000))
    expect(result.current.seconds).toBe(300)
    expect(result.current.warning).toBe(true)
    expect(result.current.expired).toBe(false)
  })

  it('expires at zero and stops ticking', () => {
    const { result } = renderHook(() => useTimer())
    act(() => result.current.start())
    act(() => vi.advanceTimersByTime(30 * 60 * 1000))
    expect(result.current.seconds).toBe(0)
    expect(result.current.display).toBe('00:00')
    expect(result.current.expired).toBe(true)
    expect(result.current.warning).toBe(false)
    // further advancing does not go negative
    act(() => vi.advanceTimersByTime(5000))
    expect(result.current.seconds).toBe(0)
  })

  it('restart() resets the clock back to the full session', () => {
    const { result } = renderHook(() => useTimer())
    act(() => result.current.start())
    act(() => vi.advanceTimersByTime(10_000))
    expect(result.current.seconds).toBe(30 * 60 - 10)
    act(() => result.current.restart())
    expect(result.current.seconds).toBe(30 * 60)
  })
})
