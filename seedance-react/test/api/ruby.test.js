import { describe, it, expect, beforeEach, afterEach, vi } from 'vitest'
import handler from '../../../api/ruby.js'
import { mockReq, mockRes } from '../helpers/http.js'

const userMsg = (content) => ({ messages: [{ role: 'user', content }] })

describe('api/ruby handler', () => {
  const originalEnv = { ...process.env }

  beforeEach(() => {
    delete process.env.ANTHROPIC_API_KEY
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

  it('requires a non-empty messages array', async () => {
    const res = mockRes()
    await handler(mockReq({ body: {} }), res)
    expect(res.statusCode).toBe(400)
    expect(res.body.error).toMatch(/messages array required/)
  })

  it('rejects when the last message is not from the user', async () => {
    const res = mockRes()
    await handler(mockReq({ body: { messages: [{ role: 'assistant', content: 'hi' }] } }), res)
    expect(res.statusCode).toBe(400)
    expect(res.body.error).toMatch(/last message must be from the user/)
  })

  it('returns the Anthropic reply when ANTHROPIC_API_KEY is set and API responds', async () => {
    process.env.ANTHROPIC_API_KEY = 'sk-test'
    vi.stubGlobal('fetch', vi.fn().mockResolvedValue({
      ok: true,
      json: async () => ({ content: [{ text: 'Hello from Claude' }] }),
    }))

    const res = mockRes()
    await handler(mockReq({ body: userMsg('hi') }), res)
    expect(res.body).toEqual({ reply: 'Hello from Claude', provider: 'anthropic' })
  })

  it('falls back to Pollinations when Anthropic key is absent', async () => {
    vi.stubGlobal('fetch', vi.fn().mockResolvedValue({
      ok: true,
      json: async () => ({ choices: [{ message: { content: 'Hello from Pollinations' } }] }),
    }))

    const res = mockRes()
    await handler(mockReq({ body: userMsg('hi') }), res)
    expect(res.body).toEqual({ reply: 'Hello from Pollinations', provider: 'pollinations' })
  })

  it('falls back to Pollinations when Anthropic responds with an error', async () => {
    process.env.ANTHROPIC_API_KEY = 'sk-test'
    const fetchMock = vi
      .fn()
      .mockResolvedValueOnce({ ok: false, status: 500, json: async () => ({}) })
      .mockResolvedValueOnce({
        ok: true,
        json: async () => ({ choices: [{ message: { content: 'recovered' } }] }),
      })
    vi.stubGlobal('fetch', fetchMock)

    const res = mockRes()
    await handler(mockReq({ body: userMsg('hi') }), res)
    expect(res.body).toEqual({ reply: 'recovered', provider: 'pollinations' })
    expect(fetchMock).toHaveBeenCalledTimes(2)
  })

  it('returns 502 when every upstream fails', async () => {
    vi.stubGlobal('fetch', vi.fn().mockRejectedValue(new Error('offline')))
    const res = mockRes()
    await handler(mockReq({ body: userMsg('hi') }), res)
    expect(res.statusCode).toBe(502)
    expect(res.body.error).toMatch(/trouble/)
  })

  it('caps history to the last 20 messages sent upstream', async () => {
    const many = Array.from({ length: 30 }, (_, i) => ({
      role: i % 2 === 0 ? 'user' : 'assistant',
      content: `m${i}`,
    }))
    // ensure the final message is from the user
    many.push({ role: 'user', content: 'final' })

    const fetchMock = vi.fn().mockResolvedValue({
      ok: true,
      json: async () => ({ choices: [{ message: { content: 'ok' } }] }),
    })
    vi.stubGlobal('fetch', fetchMock)

    const res = mockRes()
    await handler(mockReq({ body: { messages: many } }), res)

    const sent = JSON.parse(fetchMock.mock.calls[0][1].body)
    // system prompt + capped history (<= 20)
    const nonSystem = sent.messages.filter((m) => m.role !== 'system')
    expect(nonSystem.length).toBeLessThanOrEqual(20)
    expect(nonSystem[nonSystem.length - 1].content).toBe('final')
    expect(res.body.reply).toBe('ok')
  })
})
