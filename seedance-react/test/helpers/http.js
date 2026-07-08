import { vi } from 'vitest'

// Minimal mock of the Vercel-style (req, res) handler contract used by api/*.js.
// res.status(code).json(obj) / res.send(str) / res.end() all record what was sent.
export function mockRes() {
  const res = {
    statusCode: 200,
    body: undefined,
    headers: {},
    ended: false,
    status(code) {
      this.statusCode = code
      return this
    },
    json(obj) {
      this.body = obj
      this.ended = true
      return this
    },
    send(data) {
      this.body = data
      this.ended = true
      return this
    },
    end() {
      this.ended = true
      return this
    },
    setHeader(k, v) {
      this.headers[k] = v
      return this
    },
  }
  vi.spyOn(res, 'status')
  vi.spyOn(res, 'json')
  vi.spyOn(res, 'send')
  vi.spyOn(res, 'setHeader')
  return res
}

export function mockReq({ method = 'POST', body, query = {} } = {}) {
  return { method, body, query }
}
