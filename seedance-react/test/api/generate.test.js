import { describe, it, expect, beforeEach, afterEach, vi } from 'vitest'
import handler from '../../../api/generate.js'
import { mockReq, mockRes } from '../helpers/http.js'

describe('api/generate proxy handler', () => {
  const originalEnv = { ...process.env }

  beforeEach(() => {
    process.env.SEEDANCE_API_KEY = 'sk-test-key'
    vi.restoreAllMocks()
  })

  afterEach(() => {
    process.env = { ...originalEnv }
    vi.restoreAllMocks()
  })

  it('rejects non-POST methods with 405', async () => {
    const res = mockRes()
    await handler(mockReq({ method: 'GET' }), res)
    expect(res.statusCode).toBe(405)
  })

  it('forwards the request body upstream and mirrors status + data', async () => {
    const fetchMock = vi.fn().mockResolvedValue({
      status: 200,
      json: async () => ({ taskId: 't-1' }),
    })
    vi.stubGlobal('fetch', fetchMock)

    const res = mockRes()
    const body = { model: 'seedance-2', input: { prompt: 'hi' } }
    await handler(mockReq({ body }), res)

    expect(res.statusCode).toBe(200)
    expect(res.body).toEqual({ taskId: 't-1' })
    const [url, opts] = fetchMock.mock.calls[0]
    expect(url).toContain('/v1/videos/generations')
    expect(opts.method).toBe('POST')
    expect(opts.headers.Authorization).toBe('Bearer sk-test-key')
    expect(JSON.parse(opts.body)).toEqual(body)
  })

  it('propagates a non-200 upstream status', async () => {
    vi.stubGlobal('fetch', vi.fn().mockResolvedValue({
      status: 402,
      json: async () => ({ error: 'no credits' }),
    }))
    const res = mockRes()
    await handler(mockReq({ body: {} }), res)
    expect(res.statusCode).toBe(402)
    expect(res.body).toEqual({ error: 'no credits' })
  })

  it('returns 502 on network failure', async () => {
    vi.stubGlobal('fetch', vi.fn().mockRejectedValue(new Error('boom')))
    const res = mockRes()
    await handler(mockReq({ body: {} }), res)
    expect(res.statusCode).toBe(502)
    expect(res.body.error).toBe('boom')
  })

  it('falls back to the embedded key when SEEDANCE_API_KEY is unset', async () => {
    delete process.env.SEEDANCE_API_KEY
    const fetchMock = vi.fn().mockResolvedValue({ status: 200, json: async () => ({}) })
    vi.stubGlobal('fetch', fetchMock)
    const res = mockRes()
    await handler(mockReq({ body: {} }), res)
    const [, opts] = fetchMock.mock.calls[0]
    expect(opts.headers.Authorization).toMatch(/^Bearer sk_live_/)
  })
})
