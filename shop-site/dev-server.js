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
//  - Without RESEND_API_KEY, emails ("forgot password" links, change notices) aren't sent: they're
//    printed here and listed at http://localhost:8787/__dev/mail so you can click the links.
// ============================================================================
const fs = require('fs')
const path = require('path')
const crypto = require('crypto')

const PORT = Number(process.env.PORT || 8787)
const ROOT = __dirname
const DB_FILE = process.env.DEV_DB || path.join(ROOT, '.dev-data.json')
const FAKE_STRIPE = !process.env.STRIPE_SECRET_KEY
const FAKE_EMAIL = !process.env.RESEND_API_KEY

process.env.UPSTASH_REDIS_REST_URL = 'http://dev-redis.local'
process.env.UPSTASH_REDIS_REST_TOKEN = 'dev'
process.env.MARKET_ADMIN_KEY = process.env.MARKET_ADMIN_KEY || 'admin'
process.env.SITE_URL = process.env.SITE_URL || `http://localhost:${PORT}`
if (FAKE_STRIPE) {
  process.env.STRIPE_SECRET_KEY = 'sk_test_fake_dev'
  process.env.STRIPE_WEBHOOK_SECRET = 'whsec_fake_dev'
}
if (FAKE_EMAIL) process.env.RESEND_API_KEY = 're_fake_dev'

/* ---------------- fake Upstash (file-backed hashes) ---------------- */
let db = {}
try { db = JSON.parse(fs.readFileSync(DB_FILE, 'utf8')) } catch {}
const save = () => fs.writeFileSync(DB_FILE, JSON.stringify(db))
const locks = {} // SET NX PX / GET for api/market.js's locks (not saved to the file)
function redisCmd([cmd, key, ...a]) {
  if (cmd === 'SET') {
    const cur = locks[key], px = a.indexOf('PX')
    if (a.includes('NX') && cur && cur.exp > Date.now()) return null
    locks[key] = { v: a[0], exp: px >= 0 ? Date.now() + Number(a[px + 1]) : Infinity }
    return 'OK'
  }
  if (cmd === 'GET') { const cur = locks[key]; return cur && cur.exp > Date.now() ? cur.v : null }
  if (cmd === 'DEL' && key in locks) { delete locks[key]; return 1 }
  if (['RPUSH', 'LPOP', 'LLEN', 'LRANGE', 'LREM'].includes(cmd)) {
    const l = (db[key] = Array.isArray(db[key]) ? db[key] : [])
    if (cmd === 'RPUSH') { l.push(...a); save(); return l.length }
    if (cmd === 'LPOP') { const v = l.length ? l.shift() : null; save(); return v }
    if (cmd === 'LRANGE') { const s = Number(a[0]), e = Number(a[1]); return l.slice(s, e === -1 ? undefined : e + 1) }
    if (cmd === 'LREM') { const i = l.indexOf(a[1]); if (i < 0) return 0; l.splice(i, 1); save(); return 1 }
    return l.length
  }
  if (cmd === 'DEL') { const had = key in db; delete db[key]; save(); return had ? 1 : 0 }
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
const fake = { sessions: {}, accounts: {}, customers: {}, pms: {}, intents: {} }
// Test cards like Stripe's: 4242 works, 3155 asks for a 3-D Secure check, 0002 is declined.
const TEST_CARDS = { '4242': 'visa', '4444': 'mastercard', '3155': 'visa', '0002': 'visa' }
function newPm(customer, last4) {
  const pm = { id: 'pm_test_' + crypto.randomBytes(8).toString('hex'), customer: customer || null, card: { brand: TEST_CARDS[last4] || 'visa', last4, exp_month: 12, exp_year: 2030 } }
  fake.pms[pm.id] = pm
  return pm
}
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
  const body = String(opts.body || '').startsWith('{') ? JSON.parse(opts.body) : parseForm(opts.body)
  const id = (pre) => pre + crypto.randomBytes(8).toString('hex')
  if (p === '/checkout/sessions' && opts.method === 'POST') {
    const s = { id: id('cs_test_'), ...body, payment_intent: id('pi_test_'), amount_total: Object.values(body.line_items || {}).reduce((a, li) => a + Number(li.price_data.unit_amount), 0) }
    s.url = `${process.env.SITE_URL}/__dev/stripe-checkout?session=${s.id}`
    fake.sessions[s.id] = s
    return json(s)
  }
  if (p === '/customers' && opts.method === 'POST') { const c = { id: id('cus_test_') }; fake.customers[c.id] = c; return json(c) }
  if (/^\/customers\/[^/]+\/payment_methods$/.test(p)) { const cid = p.split('/')[2]; return json({ data: Object.values(fake.pms).filter((m) => m.customer === cid) }) }
  if (/^\/payment_methods\/[^/]+\/detach$/.test(p)) { const m = fake.pms[p.split('/')[2]]; if (!m) return json({ error: { message: 'No such payment method' } }, 404); m.customer = null; return json(m) }
  if (/^\/payment_methods\/[^/]+$/.test(p)) { const m = fake.pms[p.split('/')[2]]; return m ? json(m) : json({ error: { message: 'No such payment method' } }, 404) }
  if (p === '/payment_intents' && opts.method === 'POST') {
    const m = fake.pms[body.payment_method]
    if (!m || m.customer !== body.customer) return json({ error: { message: 'No such payment method' } }, 400)
    if (m.card.last4 === '0002') return json({ error: { message: 'Your card was declined.' } }, 402)
    const pi = { id: id('pi_test_'), amount: Number(body.amount), metadata: body.metadata || {}, status: 'succeeded' }
    if (m.card.last4 === '3155') {
      pi.status = 'requires_action'
      pi.next_action = { redirect_to_url: { url: `${process.env.SITE_URL}/__dev/stripe-3ds?pi=${pi.id}&return=${encodeURIComponent(body.return_url)}` } }
    }
    fake.intents[pi.id] = pi
    return json(pi)
  }
  if (/^\/checkout\/sessions\/[^/]+\/expire$/.test(p)) return json({ id: p.split('/')[3], status: 'expired' })
  if (p === '/refunds') return json({ id: id('re_test_'), status: 'succeeded', payment_intent: body.payment_intent })
  // Connect, Accounts v2 (recipient accounts)
  const v2acct = (a) => ({ id: a.id, configuration: { recipient: { capabilities: { stripe_balance: { stripe_transfers: { status: a.ready ? 'active' : 'restricted' } } } } } })
  if (p === '/v2/core/accounts' && opts.method === 'POST') { const a = { id: id('acct_test_'), ready: false }; fake.accounts[a.id] = a; return json(v2acct(a)) }
  if (/^\/v2\/core\/accounts\/[^/]+$/.test(p)) { const aid = p.split('/')[4]; return json(v2acct(fake.accounts[aid] || { id: aid, ready: true })) }
  if (p === '/v2/core/account_links') { const ao = body.use_case.account_onboarding; return json({ url: `${process.env.SITE_URL}/__dev/stripe-onboard?acct=${body.account}&return=${encodeURIComponent(ao.return_url)}` }) }
  if (p === '/transfers') return json({ id: id('tr_test_'), amount: Number(body.amount), destination: body.destination })
  return json({ error: { message: `dev fake Stripe: ${opts.method} ${p} not supported` } }, 400)
}

const devMail = [] // fake outbox (newest first), shown at /__dev/mail
const realFetch = global.fetch
global.fetch = async (url, opts = {}) => {
  const u = String(url)
  if (u.startsWith('http://dev-redis.local')) {
    try { return json({ result: redisCmd(JSON.parse(opts.body)) }) } catch (e) { return json({ error: e.message }, 400) }
  }
  if (FAKE_STRIPE && u.startsWith('https://api.stripe.com/')) return fakeStripe(u, { method: opts.method || 'GET', body: opts.body })
  if (FAKE_EMAIL && u === 'https://api.resend.com/emails') {
    const m = JSON.parse(opts.body)
    devMail.unshift({ at: new Date().toISOString(), to: m.to.join(', '), subject: m.subject, text: m.text })
    console.log(`\n[dev email] to ${m.to.join(', ')}: ${m.subject}\n${m.text}\n`)
    return json({ id: 'email_dev_' + crypto.randomBytes(6).toString('hex') })
  }
  return realFetch(url, opts)
}

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
  if (u.pathname === '/__dev/mail') {
    if (u.searchParams.get('format') === 'json') { res.setHeader('Content-Type', 'application/json'); return res.end(JSON.stringify(devMail)) }
    res.setHeader('Content-Type', 'text/html')
    const link = (t) => esc(t).replace(/(https?:\/\/\S+)/g, '<a href="$1">$1</a>')
    return res.end(page('Dev outbox', `<span class="tag">FAKE EMAIL · DEV ONLY</span><h1>Emails the site sent</h1>
      ${devMail.length ? devMail.map((m) => `<div style="border-top:1px solid #333;padding:10px 0"><b>${esc(m.subject)}</b><br><small>to ${esc(m.to)} · ${esc(m.at)}</small>
        ${m.text.split('\n\n').map((l) => `<p>${link(l)}</p>`).join('')}</div>`).join('') : '<p>Nothing yet. Use "Forgot your password?" on the site.</p>'}`))
  }
  if (u.pathname === '/__dev/stripe-checkout') {
    const s = fake.sessions[u.searchParams.get('session')]
    if (!s) { res.statusCode = 404; return res.end('Unknown session') }
    const method = (s.payment_method_types || {})[0] === 'crypto' ? 'crypto' : 'card / Apple Pay / Google Pay'
    const cardPick = `<select name="card" id="card" style="width:100%;height:42px;margin-top:8px">
        <option value="4242">Visa •••• 4242 (works)</option><option value="4444">Mastercard •••• 4444 (works)</option>
        <option value="3155">Visa •••• 3155 (asks for 3-D Secure)</option><option value="0002">Visa •••• 0002 (declined later)</option></select>`
    res.setHeader('Content-Type', 'text/html')
    if (s.mode === 'setup') {
      return res.end(page('Save a card', `<span class="tag">FAKE STRIPE · DEV ONLY</span><h1>Save a card</h1>
        <p>Stands in for Stripe's secure page. Pick a test card to save. Nothing is charged.</p>
        <form method="post" action="/__dev/stripe-pay"><input type="hidden" name="session" value="${esc(s.id)}">${cardPick}<button class="pay" id="pay">Save card (test)</button></form>
        <a href="${esc(s.cancel_url)}"><button class="no">Cancel</button></a>`))
    }
    const canSave = s.customer && s.saved_payment_method_options && s.saved_payment_method_options.payment_method_save === 'enabled'
    return res.end(page('Test checkout', `<span class="tag">FAKE STRIPE · DEV ONLY</span><h1>Pay $${(s.amount_total / 100).toFixed(2)}</h1>
      <p>This stands in for Stripe's secure checkout page (${esc(method)}). No card is charged.</p>
      <form method="post" action="/__dev/stripe-pay"><input type="hidden" name="session" value="${esc(s.id)}">
        ${canSave ? `${cardPick}<label style="display:flex;gap:8px;margin-top:12px;align-items:center"><input type="checkbox" name="save" id="save" value="1"> Save my card for future purchases</label>` : ''}
        <button class="pay" id="pay">Pay (test)</button></form>
      <a href="${esc(s.cancel_url)}"><button class="no">Cancel</button></a>`))
  }
  if (u.pathname === '/__dev/stripe-pay' && req.method === 'POST') {
    const body = await new Promise((r) => { let d = ''; req.on('data', (c) => (d += c)); req.on('end', () => r(d)) })
    const form = new URLSearchParams(body)
    const s = fake.sessions[form.get('session')]
    if (!s) { res.statusCode = 404; return res.end('Unknown session') }
    if (s.mode === 'setup') { newPm(s.customer, form.get('card') || '4242'); res.statusCode = 303; res.setHeader('Location', s.success_url); return res.end() }
    if (form.get('save') && s.customer) newPm(s.customer, form.get('card') || '4242')
    await sendWebhook('checkout.session.completed', { id: s.id, object: 'checkout.session', payment_status: 'paid', payment_intent: s.payment_intent, client_reference_id: s.client_reference_id, metadata: s.metadata })
    res.statusCode = 303; res.setHeader('Location', s.success_url); return res.end()
  }
  if (u.pathname === '/__dev/stripe-3ds') {
    const pi = fake.intents[u.searchParams.get('pi')], ret = u.searchParams.get('return')
    if (!pi) { res.statusCode = 404; return res.end('Unknown payment') }
    if (req.method === 'POST') {
      pi.status = 'succeeded'
      await sendWebhook('payment_intent.succeeded', { id: pi.id, object: 'payment_intent', status: 'succeeded', metadata: pi.metadata })
      res.statusCode = 303; res.setHeader('Location', ret); return res.end()
    }
    res.setHeader('Content-Type', 'text/html')
    return res.end(page('Bank check', `<span class="tag">FAKE BANK · DEV ONLY</span><h1>Confirm it's you</h1>
      <p>Stands in for your bank's 3-D Secure check.</p>
      <form method="post"><button class="pay" id="approve">Approve (test)</button></form>`))
  }
  if (u.pathname === '/__dev/stripe-onboard') {
    const acct = u.searchParams.get('acct'), ret = u.searchParams.get('return')
    if (req.method === 'POST') {
      fake.accounts[acct] = { id: acct, ready: true }
      await sendWebhook('account.updated', { id: acct, object: 'account' })
      res.statusCode = 303; res.setHeader('Location', ret); return res.end()
    }
    res.setHeader('Content-Type', 'text/html')
    return res.end(page('Test onboarding', `<span class="tag">FAKE STRIPE · DEV ONLY</span><h1>Connect payouts</h1>
      <p>Stands in for Stripe's onboarding, where sellers add their bank account or debit card.</p>
      <form method="post"><button class="pay" id="finish">Finish (test)</button></form>`))
  }
  return false
}

/* ---------------- server (shared with production: server.js) ---------------- */
require('./server.js')
  .createServer({ extraRoutes: (req, res, u) => (u.pathname.startsWith('/__dev/') ? devRoutes(req, res, u) : false) })
  .listen(PORT, () => {
    console.log(`Vaultix dev server: http://localhost:${PORT}`)
    console.log(`  data file : ${DB_FILE}`)
    console.log(`  Stripe    : ${FAKE_STRIPE ? 'FAKE (test pages, no real Stripe)' : 'real Stripe test mode'}`)
    console.log(`  email     : ${FAKE_EMAIL ? `FAKE (printed here and at http://localhost:${PORT}/__dev/mail)` : 'real (Resend)'}`)
    console.log(`  staff key : ${process.env.MARKET_ADMIN_KEY}`)
  })
