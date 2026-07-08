import { describe, it, expect, beforeEach, afterEach, vi } from 'vitest'
import handler from '../../../api/animeballhub.js'
import { mockReq, mockRes } from '../helpers/http.js'

const OK_KEY = 'ABC-123'

describe('api/animeballhub handler', () => {
  const originalEnv = { ...process.env }

  beforeEach(() => {
    // Clean slate: no Upstash configured, one static key.
    delete process.env.UPSTASH_REDIS_REST_URL
    delete process.env.UPSTASH_REDIS_REST_TOKEN
    delete process.env.PROTECTED_SCRIPT_TOKEN
    process.env.PROTECTED_SCRIPT_URL = 'https://private.example/script.lua'
    process.env.ANIMEBALL_KEYS = JSON.stringify({
      [OK_KEY]: { hwid: '', expires: 0, note: 'buyer1' },
    })
    vi.restoreAllMocks()
  })

  afterEach(() => {
    process.env = { ...originalEnv }
    vi.restoreAllMocks()
  })

  it('rejects non-POST methods with 405', async () => {
    const req = mockReq({ method: 'GET' })
    const res = mockRes()
    await handler(req, res)
    expect(res.statusCode).toBe(405)
    expect(res.body).toEqual({ ok: false, error: 'POST only' })
  })

  it('requires both key and hwid', async () => {
    const res = mockRes()
    await handler(mockReq({ body: { key: OK_KEY } }), res)
    expect(res.statusCode).toBe(400)
    expect(res.body.error).toMatch(/key and hwid required/)
  })

  it('parses a stringified JSON body', async () => {
    const res = mockRes()
    await handler(mockReq({ body: JSON.stringify({ key: '', hwid: '' }) }), res)
    // Empty key/hwid -> 400 (proves the string body was parsed, not treated as truthy)
    expect(res.statusCode).toBe(400)
  })

  it('rejects an unknown key with 403 invalid key', async () => {
    const res = mockRes()
    await handler(mockReq({ body: { key: 'NOPE', hwid: 'device-1' } }), res)
    expect(res.statusCode).toBe(403)
    expect(res.body.error).toBe('invalid key')
  })

  it('rejects an expired key', async () => {
    process.env.ANIMEBALL_KEYS = JSON.stringify({
      [OK_KEY]: { hwid: '', expires: 1 }, // expired in 1970
    })
    const res = mockRes()
    await handler(mockReq({ body: { key: OK_KEY, hwid: 'device-1' } }), res)
    expect(res.statusCode).toBe(403)
    expect(res.body.error).toBe('key expired')
  })

  it('honors a static HWID lock and rejects a mismatched device', async () => {
    process.env.ANIMEBALL_KEYS = JSON.stringify({
      [OK_KEY]: { hwid: 'device-A', expires: 0 },
    })
    const res = mockRes()
    await handler(mockReq({ body: { key: OK_KEY, hwid: 'device-B' } }), res)
    expect(res.statusCode).toBe(403)
    expect(res.body.error).toBe('key locked to another device')
  })

  it('serves the protected script for a valid, unlocked key', async () => {
    const fetchMock = vi.fn().mockResolvedValue({
      ok: true,
      text: async () => '-- obfuscated lua --',
    })
    vi.stubGlobal('fetch', fetchMock)

    const res = mockRes()
    await handler(mockReq({ body: { key: OK_KEY, hwid: 'device-1' } }), res)

    expect(res.statusCode).toBe(200)
    expect(res.body).toBe('-- obfuscated lua --')
    expect(res.headers['Content-Type']).toMatch(/text\/plain/)
    expect(res.headers['Cache-Control']).toBe('no-store')
    expect(fetchMock).toHaveBeenCalledWith(
      'https://private.example/script.lua',
      expect.objectContaining({ headers: expect.any(Object) }),
    )
  })

  it('returns 500 when PROTECTED_SCRIPT_URL is unset', async () => {
    delete process.env.PROTECTED_SCRIPT_URL
    const res = mockRes()
    await handler(mockReq({ body: { key: OK_KEY, hwid: 'device-1' } }), res)
    expect(res.statusCode).toBe(500)
    expect(res.body.error).toMatch(/PROTECTED_SCRIPT_URL/)
  })

  it('returns 502 when the upstream script fetch is not ok', async () => {
    vi.stubGlobal('fetch', vi.fn().mockResolvedValue({ ok: false }))
    const res = mockRes()
    await handler(mockReq({ body: { key: OK_KEY, hwid: 'device-1' } }), res)
    expect(res.statusCode).toBe(502)
    expect(res.body.error).toBe('script fetch failed')
  })

  it('returns 502 when the upstream fetch throws', async () => {
    vi.stubGlobal('fetch', vi.fn().mockRejectedValue(new Error('network down')))
    const res = mockRes()
    await handler(mockReq({ body: { key: OK_KEY, hwid: 'device-1' } }), res)
    expect(res.statusCode).toBe(502)
    expect(res.body.error).toBe('network down')
  })

  describe('Upstash auto-bind (lock on first use)', () => {
    beforeEach(() => {
      process.env.UPSTASH_REDIS_REST_URL = 'https://kv.example'
      process.env.UPSTASH_REDIS_REST_TOKEN = 'kv-token'
    })

    it('binds an unlocked key to the first HWID and serves the script', async () => {
      const fetchMock = vi.fn(async (url) => {
        if (url.includes('/get/')) return { ok: true, json: async () => ({ result: null }) }
        if (url.includes('/set/')) return { ok: true }
        return { ok: true, text: async () => 'script' }
      })
      vi.stubGlobal('fetch', fetchMock)

      const res = mockRes()
      await handler(mockReq({ body: { key: OK_KEY, hwid: 'first-device' } }), res)

      expect(res.statusCode).toBe(200)
      const setCall = fetchMock.mock.calls.find(([u]) => u.includes('/set/'))
      expect(setCall[0]).toContain('first-device')
    })

    it('rejects a second device once a key is bound in KV', async () => {
      const fetchMock = vi.fn(async (url) => {
        if (url.includes('/get/')) return { ok: true, json: async () => ({ result: 'first-device' }) }
        return { ok: true, text: async () => 'script' }
      })
      vi.stubGlobal('fetch', fetchMock)

      const res = mockRes()
      await handler(mockReq({ body: { key: OK_KEY, hwid: 'second-device' } }), res)

      expect(res.statusCode).toBe(403)
      expect(res.body.error).toBe('key locked to another device')
    })
  })
})
