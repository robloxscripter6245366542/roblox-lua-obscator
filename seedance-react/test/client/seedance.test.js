import { describe, it, expect, beforeEach, afterEach, vi } from 'vitest'
import { createVideoTask, pollTask } from '../../src/lib/seedance.js'

const baseOpts = {
  prompt: 'a cat',
  genType: 'text-to-video',
  imageUrls: [],
  duration: '5',
  aspectRatio: '16:9',
  resolution: '1080p',
  model: 'seedance-2',
  audio: true,
}

describe('createVideoTask', () => {
  afterEach(() => vi.restoreAllMocks())

  it('posts a normalized body to /api/generate and returns the taskId', async () => {
    const fetchMock = vi.fn().mockResolvedValue({
      ok: true,
      json: async () => ({ taskId: 'abc' }),
    })
    vi.stubGlobal('fetch', fetchMock)

    const id = await createVideoTask('key', baseOpts)
    expect(id).toBe('abc')

    const [url, opts] = fetchMock.mock.calls[0]
    expect(url).toBe('/api/generate')
    const sent = JSON.parse(opts.body)
    expect(sent.model).toBe('seedance-2')
    expect(sent.input.duration).toBe(5) // parsed to int
    expect(sent.input.generation_type).toBe('text-to-video')
    expect(sent.input.watermark).toBe(false)
    // no image_urls key when imageUrls is empty
    expect(sent.input).not.toHaveProperty('image_urls')
  })

  it('includes image_urls only when provided', async () => {
    const fetchMock = vi.fn().mockResolvedValue({ ok: true, json: async () => ({ taskId: 'x' }) })
    vi.stubGlobal('fetch', fetchMock)
    await createVideoTask('key', { ...baseOpts, imageUrls: ['http://img/1.png'] })
    const sent = JSON.parse(fetchMock.mock.calls[0][1].body)
    expect(sent.input.image_urls).toEqual(['http://img/1.png'])
  })

  it('maps 402 to an insufficient-credits error', async () => {
    vi.stubGlobal('fetch', vi.fn().mockResolvedValue({
      ok: false, status: 402, json: async () => ({}),
    }))
    await expect(createVideoTask('key', baseOpts)).rejects.toThrow(/Insufficient credits/)
  })

  it('maps 429 to a rate-limit error', async () => {
    vi.stubGlobal('fetch', vi.fn().mockResolvedValue({
      ok: false, status: 429, json: async () => ({}),
    }))
    await expect(createVideoTask('key', baseOpts)).rejects.toThrow(/Rate limit/)
  })

  it('surfaces the server error message for other failures', async () => {
    vi.stubGlobal('fetch', vi.fn().mockResolvedValue({
      ok: false, status: 500, json: async () => ({ error: { message: 'kaboom' } }),
    }))
    await expect(createVideoTask('key', baseOpts)).rejects.toThrow('kaboom')
  })

  it('throws when no taskId is returned', async () => {
    vi.stubGlobal('fetch', vi.fn().mockResolvedValue({ ok: true, json: async () => ({}) }))
    await expect(createVideoTask('key', baseOpts)).rejects.toThrow(/No task ID/)
  })
})

describe('pollTask', () => {
  beforeEach(() => vi.useFakeTimers())
  afterEach(() => {
    vi.useRealTimers()
    vi.restoreAllMocks()
  })

  it('resolves with the video URL once the task completes', async () => {
    let call = 0
    vi.stubGlobal('fetch', vi.fn(async () => {
      call++
      if (call < 2) return { json: async () => ({ status: 'generating' }) }
      return { json: async () => ({ status: 'completed', data: { results: ['https://video/out.mp4'] } }) }
    }))
    const onProgress = vi.fn()

    const promise = pollTask('key', 'task-1', onProgress)
    await vi.runAllTimersAsync()
    await expect(promise).resolves.toBe('https://video/out.mp4')
    expect(onProgress).toHaveBeenCalledWith(100)
  })

  it('rejects when the task fails, surfacing the failure reason', async () => {
    vi.stubGlobal('fetch', vi.fn(async () => ({
      json: async () => ({ status: 'failed', data: { failed_reason: 'bad prompt' } }),
    })))
    const promise = pollTask('key', 'task-1')
    const assertion = expect(promise).rejects.toThrow('bad prompt')
    await vi.runAllTimersAsync()
    await assertion
  })

  it('rejects when a completed task has no video URL', async () => {
    vi.stubGlobal('fetch', vi.fn(async () => ({
      json: async () => ({ status: 'completed', data: { results: [] } }),
    })))
    const promise = pollTask('key', 'task-1')
    const assertion = expect(promise).rejects.toThrow(/No video URL/)
    await vi.runAllTimersAsync()
    await assertion
  })
})
