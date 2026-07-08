import { describe, it, expect, beforeEach, afterEach, vi } from 'vitest'
import handler from '../../../api/poll.js'
import { mockReq, mockRes } from '../helpers/http.js'

describe('api/poll proxy handler', () => {
  const originalEnv = { ...process.env }

  beforeEach(() => {
    process.env.SEEDANCE_API_KEY = 'sk-test-key'
    vi.restoreAllMocks()
  })

  afterEach(() => {
    process.env = { ...originalEnv }
    vi.restoreAllMocks()
  })

  it('requires a taskId query param', async () => {
    const res = mockRes()
    await handler(mockReq({ query: {} }), res)
    expect(res.statusCode).toBe(400)
    expect(res.body.error).toMatch(/taskId required/)
  })

  it('fetches the task by id and mirrors status + data', async () => {
    const fetchMock = vi.fn().mockResolvedValue({
      status: 200,
      json: async () => ({ status: 'completed', data: { results: ['url'] } }),
    })
    vi.stubGlobal('fetch', fetchMock)

    const res = mockRes()
    await handler(mockReq({ query: { taskId: 'task-42' } }), res)

    expect(res.statusCode).toBe(200)
    expect(res.body.status).toBe('completed')
    const [url, opts] = fetchMock.mock.calls[0]
    expect(url).toContain('/v1/tasks/task-42')
    expect(opts.headers.Authorization).toBe('Bearer sk-test-key')
  })

  it('returns 502 on network failure', async () => {
    vi.stubGlobal('fetch', vi.fn().mockRejectedValue(new Error('timeout')))
    const res = mockRes()
    await handler(mockReq({ query: { taskId: 'task-42' } }), res)
    expect(res.statusCode).toBe(502)
    expect(res.body.error).toBe('timeout')
  })
})
