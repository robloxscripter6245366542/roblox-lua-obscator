#!/usr/bin/env node
// ============================================================================
//  Vaultix production server (used on Render).
//      node shop-site/server.js
//
//  Serves the site plus the API (api/market.js, api/stripe-webhook.js) from one
//  Node process. Settings come from environment variables:
//    PORT                                                 set by Render automatically
//    UPSTASH_REDIS_REST_URL / UPSTASH_REDIS_REST_TOKEN    database (required for real use)
//    MARKET_ADMIN_KEY                                     Staff page password
//    STRIPE_SECRET_KEY / STRIPE_WEBHOOK_SECRET            payments
//    SITE_URL                                             optional, e.g. https://vaultix.onrender.com
//  Without the database settings the site still loads and runs in demo mode.
//
//  shop-site/dev-server.js reuses createServer() with a fake database and fake Stripe.
// ============================================================================
const http = require('http')
const fs = require('fs')
const path = require('path')

const ROOT = __dirname
const MAX_BODY = 1024 * 1024 // 1 MB: listing pictures are ~270 KB at most
const TYPES = {
  '.html': 'text/html; charset=utf-8', '.css': 'text/css; charset=utf-8', '.js': 'text/javascript; charset=utf-8',
  '.svg': 'image/svg+xml', '.png': 'image/png', '.json': 'application/json', '.ico': 'image/x-icon', '.md': 'text/plain; charset=utf-8',
}
// Files that exist in shop-site/ but must never be served (shop-site/api/ holds Vercel entry points)
const PRIVATE = new Set(['server.js', 'dev-server.js'])

function securityHeaders(res) {
  res.setHeader('X-Content-Type-Options', 'nosniff')
  res.setHeader('Referrer-Policy', 'strict-origin-when-cross-origin')
  res.setHeader('X-Frame-Options', 'DENY')
}

function serveStatic(req, res, u) {
  let rel
  try { rel = u.pathname === '/' ? 'index.html' : decodeURIComponent(u.pathname.slice(1)) } catch { rel = '' }
  const file = path.resolve(ROOT, rel)
  const name = path.basename(file)
  const top = rel.split(/[\\/]/)[0]
  if (!rel || !file.startsWith(ROOT + path.sep) || name.startsWith('.') || PRIVATE.has(name) || top === 'api' || rel.split(/[\\/]/).some((p) => p.startsWith('.'))) {
    res.statusCode = 404; return res.end('Not found')
  }
  fs.stat(file, (e, st) => {
    if (e || !st.isFile()) { res.statusCode = 404; return res.end('Not found') }
    res.setHeader('Content-Type', TYPES[path.extname(file)] || 'application/octet-stream')
    // HTML always fresh; other assets can be cached briefly
    res.setHeader('Cache-Control', file.endsWith('.html') ? 'no-cache' : 'public, max-age=300')
    if (req.method === 'HEAD') return res.end()
    fs.createReadStream(file).pipe(res)
  })
}

// Small Vercel-style helpers so api/market.js runs unchanged.
function runMarket(market, req, res, u) {
  let size = 0
  const chunks = []
  req.on('data', (c) => {
    size += c.length
    if (size > MAX_BODY) { res.statusCode = 413; res.end('{"error":"Request too large"}'); req.destroy(); return }
    chunks.push(c)
  })
  req.on('end', () => {
    if (res.writableEnded) return
    const raw = Buffer.concat(chunks).toString('utf8')
    req.query = Object.fromEntries(u.searchParams)
    try { req.body = raw ? JSON.parse(raw) : {} } catch { req.body = {} }
    res.status = (c) => { res.statusCode = c; return res }
    res.json = (o) => { res.setHeader('Content-Type', 'application/json'); res.end(JSON.stringify(o)) }
    market(req, res)
  })
}

function createServer(opts = {}) {
  const market = require('../api/market.js')
  const webhook = require('../api/stripe-webhook.js')
  return http.createServer(async (req, res) => {
    const u = new URL(req.url, 'http://localhost')
    securityHeaders(res)
    try {
      if (opts.extraRoutes && (await opts.extraRoutes(req, res, u)) !== false) return
      if (u.pathname === '/healthz') { res.setHeader('Content-Type', 'text/plain'); return res.end('ok') }
      if (u.pathname === '/api/stripe-webhook') return webhook(req, res)
      if (u.pathname === '/api/market') return runMarket(market, req, res, u)
      if (req.method !== 'GET' && req.method !== 'HEAD') { res.statusCode = 405; return res.end() }
      return serveStatic(req, res, u)
    } catch (e) {
      console.error(e)
      if (!res.headersSent) res.statusCode = 500
      res.end('Server error')
    }
  })
}

module.exports = { createServer }

if (require.main === module) {
  const port = Number(process.env.PORT || 10000)
  const missing = ['MARKET_ADMIN_KEY', 'STRIPE_SECRET_KEY', 'STRIPE_WEBHOOK_SECRET'].filter((k) => !process.env[k])
  if (!(process.env.UPSTASH_REDIS_REST_URL || process.env.KV_REST_API_URL)) missing.unshift('UPSTASH_REDIS_REST_URL (or KV_REST_API_URL)')
  if (!(process.env.UPSTASH_REDIS_REST_TOKEN || process.env.KV_REST_API_TOKEN)) missing.unshift('UPSTASH_REDIS_REST_TOKEN (or KV_REST_API_TOKEN)')
  createServer().listen(port, () => {
    console.log(`Vaultix running on port ${port}`)
    if (missing.length) console.log(`Not set yet: ${missing.join(', ')} — the site runs in demo mode until the database is set, and payments need the Stripe keys.`)
  })
}
