import { describe, it, expect, beforeEach, afterEach, vi } from 'vitest'
import handler from '../../../api/github.js'
import { mockReq, mockRes } from '../helpers/http.js'

const okJson = (obj) => ({ ok: true, status: 200, text: async () => JSON.stringify(obj) })
const errJson = (status, obj) => ({ ok: false, status, text: async () => JSON.stringify(obj) })

// Wire up a fetch mock that answers each GitHub API step in order.
function githubHappyPath() {
  return vi
    .fn()
    // GET repo
    .mockResolvedValueOnce(okJson({ default_branch: 'main' }))
    // GET base ref
    .mockResolvedValueOnce(okJson({ object: { sha: 'basesha' } }))
    // GET base commit
    .mockResolvedValueOnce(okJson({ tree: { sha: 'basetree' } }))
    // POST new ref (branch)
    .mockResolvedValueOnce(okJson({ ref: 'refs/heads/ruby/x' }))
    // POST blob
    .mockResolvedValueOnce(okJson({ sha: 'blob1' }))
    // POST tree
    .mockResolvedValueOnce(okJson({ sha: 'newtree' }))
    // POST commit
    .mockResolvedValueOnce(okJson({ sha: 'newcommit', tree: { sha: 'newtree' } }))
    // PATCH ref
    .mockResolvedValueOnce(okJson({ ref: 'refs/heads/ruby/x' }))
    // POST pull
    .mockResolvedValueOnce(okJson({ number: 7, html_url: 'https://github.com/o/r/pull/7' }))
}

const body = () => ({ repo: 'o/r', files: [{ path: 'a.lua', content: 'print(1)' }], message: 'hi' })

describe('api/github handler', () => {
  const originalEnv = { ...process.env }

  beforeEach(() => {
    process.env.RUBY_GITHUB_TOKEN = 'tok'
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

  it('returns 501 when no token is configured', async () => {
    delete process.env.RUBY_GITHUB_TOKEN
    delete process.env.GITHUB_TOKEN
    delete process.env.GH_TOKEN
    const res = mockRes()
    await handler(mockReq({ body: body() }), res)
    expect(res.statusCode).toBe(501)
    expect(res.body.error).toMatch(/not connected/i)
  })

  it('rejects a malformed repo', async () => {
    const res = mockRes()
    await handler(mockReq({ body: { repo: 'notarepo', files: body().files } }), res)
    expect(res.statusCode).toBe(400)
    expect(res.body.error).toMatch(/owner\/name/)
  })

  it('requires at least one valid file', async () => {
    const res = mockRes()
    await handler(mockReq({ body: { repo: 'o/r', files: [] } }), res)
    expect(res.statusCode).toBe(400)
    expect(res.body.error).toMatch(/at least one file/)
  })

  it('commits files and opens a PR on the happy path', async () => {
    const fetchMock = githubHappyPath()
    vi.stubGlobal('fetch', fetchMock)

    const res = mockRes()
    await handler(mockReq({ body: body() }), res)

    expect(res.statusCode).toBe(200)
    expect(res.body).toMatchObject({ ok: true, prNumber: 7, prUrl: 'https://github.com/o/r/pull/7', commit: 'newcommit' })
    // a blob is created per file, then a tree, commit, ref update, and PR
    const calls = fetchMock.mock.calls.map((c) => `${c[1].method} ${c[0]}`)
    expect(calls.some((c) => c.startsWith('POST') && c.includes('/git/blobs'))).toBe(true)
    expect(calls.some((c) => c.startsWith('POST') && c.includes('/pulls'))).toBe(true)
    // the token is sent as a bearer header, never from the body
    expect(fetchMock.mock.calls[0][1].headers.Authorization).toBe('Bearer tok')
  })

  it('surfaces GitHub API errors with their status', async () => {
    const fetchMock = vi.fn().mockResolvedValueOnce(errJson(404, { message: 'Not Found' }))
    vi.stubGlobal('fetch', fetchMock)

    const res = mockRes()
    await handler(mockReq({ body: body() }), res)
    expect(res.statusCode).toBe(404)
    expect(res.body.error).toMatch(/Not Found/)
  })

  it('normalizes a full GitHub URL to owner/name', async () => {
    const fetchMock = githubHappyPath()
    vi.stubGlobal('fetch', fetchMock)

    const res = mockRes()
    await handler(mockReq({ body: { ...body(), repo: 'https://github.com/o/r.git' } }), res)
    expect(res.statusCode).toBe(200)
    expect(fetchMock.mock.calls[0][0]).toContain('/repos/o/r')
  })
})
