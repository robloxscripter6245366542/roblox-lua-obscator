import { describe, it, expect, beforeEach, afterEach, vi } from 'vitest'
import handler from '../../../api/claude-plan.js'
import { mockReq, mockRes } from '../helpers/http.js'

describe('api/claude-plan handler', () => {
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

  it('requires a prompt', async () => {
    const res = mockRes()
    await handler(mockReq({ body: {} }), res)
    expect(res.statusCode).toBe(400)
    expect(res.body.error).toMatch(/prompt required/)
  })

  it('returns the Anthropic plan when ANTHROPIC_API_KEY is set and API responds', async () => {
    process.env.ANTHROPIC_API_KEY = 'sk-test'
    const plan = { title: 'From Claude', scenes: [{ type: 'galaxy' }] }
    vi.stubGlobal('fetch', vi.fn().mockResolvedValue({
      ok: true,
      json: async () => ({ content: [{ text: JSON.stringify(plan) }] }),
    }))

    const res = mockRes()
    await handler(mockReq({ body: { prompt: 'a space odyssey' } }), res)
    expect(res.body).toEqual(plan)
  })

  it('falls back to Pollinations when Anthropic key is absent', async () => {
    const pollPlan = { title: 'From Pollinations', scenes: [{ type: 'nebula' }] }
    vi.stubGlobal('fetch', vi.fn().mockResolvedValue({
      ok: true,
      json: async () => pollPlan,
    }))

    const res = mockRes()
    await handler(mockReq({ body: { prompt: 'dreamscape' } }), res)
    expect(res.body).toEqual(pollPlan)
  })

  it('returns the hardcoded fallback when every upstream fails', async () => {
    vi.stubGlobal('fetch', vi.fn().mockRejectedValue(new Error('offline')))
    const res = mockRes()
    await handler(mockReq({ body: { prompt: 'a magical dragon myth' } }), res)

    expect(res.body.title).toBe('a magical dragon myth')
    // "magic/dragon/myth" keywords route the first scene to 'crystal'
    expect(res.body.scenes[0].type).toBe('crystal')
    expect(res.body.scenes).toHaveLength(4)
    expect(res.body.transition).toBe('fade')
  })

  it.each([
    ['journey through the galaxy and stars', 'galaxy'],
    ['a walk in the forest and mountain', 'terrain'],
    ['neon cyber city of the future', 'neon_city'],
    ['ancient fantasy crystal magic', 'crystal'],
    ['just some random words here', 'abstract'],
  ])('keyword routing: %s -> %s', async (prompt, expectedType) => {
    vi.stubGlobal('fetch', vi.fn().mockRejectedValue(new Error('offline')))
    const res = mockRes()
    await handler(mockReq({ body: { prompt } }), res)
    expect(res.body.scenes[0].type).toBe(expectedType)
  })

  it('truncates the fallback title to 40 characters', async () => {
    vi.stubGlobal('fetch', vi.fn().mockRejectedValue(new Error('offline')))
    const longPrompt = 'x'.repeat(100)
    const res = mockRes()
    await handler(mockReq({ body: { prompt: longPrompt } }), res)
    expect(res.body.title).toHaveLength(40)
  })
})
