#!/usr/bin/env node
// ============================================================================
//  Vaultix local dev server — run the whole market on your computer:
//      node shop-site/dev-server.js        then open http://localhost:8787
//
//  - Serves the site and the real API code (api/market.js, api/stripe-webhook.js).
//  - Stores data in shop-site/.dev-data.json instead of Upstash.
//  - Without STRIPE_SECRET_KEY it uses a FAKE Stripe: checkout and Stripe onboarding open
//    a local test page with "Pay" / "Finish" buttons, and send signed webhooks back, so the
//    full escrow → wallet → payout flow works offline. No real money, no card numbers.
//  - With a real sk_test_… key it talks to Stripe test mode; forward webhooks with
//    `stripe listen --forward-to localhost:8787/api/stripe-webhook` and set
//    STRIPE_WEBHOOK_SECRET to the secret it prints.
//  - Staff page password: MARKET_ADMIN_KEY (default "admin").
// ============================================================================
const http = require('http')
const fs = require('fs')
const path = require('path')
const crypto = require('crypto')

const PORT = Number(process.env.PORT || 8787)
const ROOT = __dirname
const DB_FILE = process.env.DEV_DB || path.join(ROOT, '.dev-data.json')
const FAKE_STRIPE = !process.env.STRIPE_SECRET_KEY

process.env.UPSTASH_REDIS_REST_URL = 'http://dev-redis.local'
process.env.UPSTASH_REDIS_REST_TOKEN = 'dev'
process.env.MARKET_ADMIN_KEY = process.env.MARKET_ADMIN_KEY || 'admin'
process.env.SITE_URL = process.env.SITE_URL || `http://localhost:${PORT}`
if (FAKE_STRIPE) {
  process.env.STRIPE_SECRET_KEY = 'sk_test_fake_dev'
  process.env.STRIPE_WEBHOOK_SECRET = 'whsec_fake_dev'
}

/* ---------------- fake Upstash (file-backed hashes) ---------------- */
let db = {}
try { db = JSON.parse(fs.readFileSync(DB_FILE, 'utf8')) } catch {}
const save = () => fs.writeFileSync(DB_FILE, JSON.stringify(db))
function redisCmd([cmd, key, ...a]) {
  const h = (db[key] = db[key] || {})
  switch (cmd) {
    case 'HGETALL': return Object.entries(h).flat()
    case 'HGET': return h[a[0]] ?? null
    case 'HSET': h[a[0]] = a[1]; save(); return 1
    case 'HDEL': { const had = a[0] in h; delete h[a[0]]; save(); return had ? 1 : 0 }
    default: throw new Error('dev redis: unsupported ' + cmd)
  }
}

/* ---------------- fake Stripe ---------------- */
const fake = { sessions: {}, accounts: {} }
const json = (obj, status = 200) => ({ ok: status < 400, status, json: async () => obj })
function parseForm(body) {
  const out = {}
  for (const [k, v] of new URLSearchParams(body || '')) {
    const keys = k.replace(/\]/g, '').split('[')
    let o = out
    keys.forEach((kk, i) => { if (i === keys.length - 1) o[kk] = v; else o = o[kk] = o[kk] || {} })
  }
  return out
}
function fakeStripe(url, opts) {
  const p = new URL(url).pathname.replace(/^\/v1/, '')
  const body = parseForm(opts.body)
  const id = (pre) => pre + crypto.randomBytes(8).toString('hex')
  if (p === '/checkout/sessions' && opts.method === 'POST') {
    const s = { id: id('cs_test_'), ...body, payment_intent: id('pi_test_'), amount_total: Object.values(body.line_items || {}).reduce((a, li) => a + Number(li.price_data.unit_amount), 0) }
    s.url = `${process.env.SITE_URL}/__dev/stripe-checkout?session=${s.id}`
    fake.sessions[s.id] = s
    return json(s)
  }
  if (/^\/checkout\/sessions\/[^/]+\/expire$/.test(p)) return json({ id: p.split('/')[3], status: 'expired' })
  if (p === '/refunds') return json({ id: id('re_test_'), status: 'succeeded', payment_intent: body.payment_intent })
  if (p === '/accounts' && opts.method === 'POST') { const a = { id: id('acct_test_'), payouts_enabled: false }; fake.accounts[a.id] = a; return json(a) }
  if (/^\/accounts\/[^/]+$/.test(p)) { const a = fake.accounts[p.split('/')[2]] || { id: p.split('/')[2], payouts_enabled: true }; return json(a) }
  if (p === '/account_links') return json({ url: `${process.env.SITE_URL}/__dev/stripe-onboard?acct=${body.account}&return=${encodeURIComponent(body.return_url)}` })
  if (p === '/transfers') return json({ id: id('tr_test_'), amount: Number(body.amount), destination: body.destination })
  return json({ error: { message: `dev fake Stripe: ${opts.method} ${p} not supported` } }, 400)
}

const realFetch = global.fetch
global.fetch = async (url, opts = {}) => {
  const u = String(url)
  if (u.startsWith('http://dev-redis.local')) {
    try { return json({ result: redisCmd(JSON.parse(opts.body)) }) } catch (e) { return json({ error: e.message }, 400) }
  }
  if (FAKE_STRIPE && u.startsWith('https://api.stripe.com/')) return fakeStripe(u, { method: opts.method || 'GET', body: opts.body })
  return realFetch(url, opts)
}

const market = require('../api/market.js')
const webhook = require('../api/stripe-webhook.js')

async function sendWebhook(type, object) {
  const payload = JSON.stringify({ id: 'evt_' + crypto.randomBytes(8).toString('hex'), type, data: { object } })
  const t = Math.floor(Date.now() / 1000)
  const sig = crypto.createHmac('sha256', process.env.STRIPE_WEBHOOK_SECRET).update(`${t}.${payload}`).digest('hex')
  const r = await realFetch(`http://localhost:${PORT}/api/stripe-webhook`, { method: 'POST', headers: { 'Stripe-Signature': `t=${t},v1=${sig}`, 'Content-Type': 'application/json' }, body: payload })
  if (!r.ok) console.error('webhook failed', r.status, await r.text())
}

/* ---------------- dev-only fake Stripe pages ---------------- */
const page = (title, inner) => `<!doctype html><meta charset="utf-8"><meta name="viewport" content="width=device-width,initial-scale=1"><title>${title}</title>
<style>body{margin:0;min-height:100vh;display:grid;place-items:center;background:#f6f8fa;font:16px system-ui;color:#1a1f36}.c{background:#fff;padding:32px;border-radius:12px;box-shadow:0 8px 30px rgba(0,0,0,.08);width:min(420px,100% - 32px)}
.tag{display:inline-block;background:#ffefc6;color:#7a4b00;border-radius:6px;padding:3px 8px;font-size:12px;font-weight:700;margin-bottom:12px}h1{font-size:22px;margin:0 0 6px}p{color:#5a6275}
button{width:100%;height:46px;border:0;border-radius:8px;font-size:16px;font-weight:600;cursor:pointer;margin-top:10px}.pay{background:#635bff;color:#fff}.no{background:#eef0f4;color:#1a1f36}</style><div class="c">${inner}</div>`
const esc = (s) => String(s).replace(/[&<>"']/g, (c) => ({ '&': '&amp;', '<': '&lt;', '>': '&gt;', '"': '&quot;', "'": '&#39;' }[c]))

async function devRoutes(req, res, u) {
  if (u.pathname === '/__dev/stripe-checkout') {
    const s = fake.sessions[u.searchParams.get('session')]
    if (!s) { res.statusCode = 404; return res.end('Unknown session') }
    const method = (s.payment_method_types || {})[0] === 'crypto' ? 'crypto' : 'card / Apple Pay / Google Pay'
    res.setHeader('Content-Type', 'text/html')
    return res.end(page('Test checkout', `<span class="tag">FAKE STRIPE · DEV ONLY</span><h1>Pay $${(s.amount_total / 100).toFixed(2)}</h1>
      <p>This stands in for Stripe's secure checkout page (${esc(method)}). No card is charged.</p>
      <form method="post" action="/__dev/stripe-pay"><input type="hidden" name="session" value="${esc(s.id)}"><button class="pay" id="pay">Pay (test)</button></form>
      <a href="${esc(s.cancel_url)}"><button class="no">Cancel</button></a>`))
  }
  if (u.pathname === '/__dev/stripe-pay' && req.method === 'POST') {
    const body = await new Promise((r) => { let d = ''; req.on('data', (c) => (d += c)); req.on('end', () => r(d)) })
    const s = fake.sessions[new URLSearchParams(body).get('session')]
    if (!s) { res.statusCode = 404; return res.end('Unknown session') }
    await sendWebhook('checkout.session.completed', { id: s.id, object: 'checkout.session', payment_status: 'paid', payment_intent: s.payment_intent, client_reference_id: s.client_reference_id, metadata: s.metadata })
    res.statusCode = 303; res.setHeader('Location', s.success_url); return res.end()
  }
  if (u.pathname === '/__dev/stripe-onboard') {
    const acct = u.searchParams.get('acct'), ret = u.searchParams.get('return')
    if (req.method === 'POST') {
      fake.accounts[acct] = { id: acct, payouts_enabled: true }
      await sendWebhook('account.updated', { id: acct, object: 'account', payouts_enabled: true })
      res.statusCode = 303; res.setHeader('Location', ret); return res.end()
    }
    res.setHeader('Content-Type', 'text/html')
    return res.end(page('Test onboarding', `<span class="tag">FAKE STRIPE · DEV ONLY</span><h1>Connect payouts</h1>
      <p>Stands in for Stripe's onboarding, where sellers add their bank account or debit card.</p>
      <form method="post"><button class="pay" id="finish">Finish (test)</button></form>`))
  }
  return false
}

/* ---------------- server ---------------- */
const TYPES = { '.html': 'text/html', '.css': 'text/css', '.js': 'text/javascript', '.svg': 'image/svg+xml', '.png': 'image/png', '.json': 'application/json' }
http.createServer(async (req, res) => {
  const u = new URL(req.url, `http://localhost:${PORT}`)
  try {
    if (u.pathname.startsWith('/__dev/')) { if ((await devRoutes(req, res, u)) !== false) return }
    if (u.pathname === '/api/stripe-webhook') return webhook(req, res)
    if (u.pathname === '/api/market') {
      let raw = ''
      req.on('data', (c) => (raw += c))
      req.on('end', () => {
        req.query = Object.fromEntries(u.searchParams)
        try { req.body = raw ? JSON.parse(raw) : {} } catch { req.body = {} }
        res.status = (c) => { res.statusCode = c; return res }
        res.json = (o) => { res.setHeader('Content-Type', 'application/json'); res.end(JSON.stringify(o)) }
        market(req, res)
      })
      return
    }
    const rel = u.pathname === '/' ? 'index.html' : decodeURIComponent(u.pathname.slice(1))
    const file = path.resolve(ROOT, rel)
    if (!file.startsWith(ROOT + path.sep) || path.basename(file).startsWith('.') || file.endsWith('dev-server.js')) { res.statusCode = 404; return res.end() }
    fs.readFile(file, (e, d) => {
      if (e) { res.statusCode = 404; return res.end('Not found') }
      res.setHeader('Content-Type', TYPES[path.extname(file)] || 'application/octet-stream')
      res.end(d)
    })
  } catch (e) {
    console.error(e); res.statusCode = 500; res.end('Server error')
  }
}).listen(PORT, () => {
  console.log(`Vaultix dev server: http://localhost:${PORT}`)
  console.log(`  data file : ${DB_FILE}`)
  console.log(`  Stripe    : ${FAKE_STRIPE ? 'FAKE (test pages, no real Stripe)' : 'real Stripe test mode'}`)
  console.log(`  staff key : ${process.env.MARKET_ADMIN_KEY}`)
})
