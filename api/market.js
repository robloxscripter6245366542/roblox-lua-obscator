// ============================================================================
//  Vaultix marketplace API ("market")
//  One endpoint, action picked by ?action= (GET) or body.action (POST).
//
//  Accounts & trust
//   - Anyone can sign up. They get a secret token (stored in their browser); only the token
//     holder can act for that account. Every account can buy and sell.
//   - New sellers are UNVERIFIED -> their listings show as "Risky". Only the site owner
//     (MARKET_ADMIN_KEY) can verify sellers.
//
//  Money (escrow)
//   - Buyers pay on Stripe's hosted checkout (card, Apple Pay, Google Pay, or crypto). Card
//     numbers never touch this server. Buyers can also pay from their Vaultix balance.
//   - The site holds the money. The seller delivers, the buyer confirms (or it auto-confirms
//     3 days after delivery), and only then the seller's share becomes withdrawable.
//   - Disputes are settled by staff: refund the buyer, or release to the seller.
//   - Balances are never stored; they are recalculated from orders and payouts, so they
//     can't drift.
//   - Sellers withdraw via Stripe (bank/debit card, automatic transfer after staff approval),
//     PayPal, crypto or bank transfer (staff send these by hand and mark them paid).
//
//  Env vars (Vercel):
//   UPSTASH_REDIS_REST_URL / UPSTASH_REDIS_REST_TOKEN   storage (required). The names Vercel's Storage
//                                                       tab sets (KV_REST_API_URL / KV_REST_API_TOKEN) work too.
//   MARKET_ADMIN_KEY                                    staff password (required for admin)
//   STRIPE_SECRET_KEY                                   Stripe key (sk_test_… while testing)
//   STRIPE_WEBHOOK_SECRET                               signing secret for api/stripe-webhook
//   MARKET_OWNERS                                       owner usernames, comma-separated (default "Kaitrades").
//                                                       Signing up with one needs MARKET_ADMIN_KEY, so nobody
//                                                       else can grab the name. Owners get staff powers.
//   MARKET_ENCRYPTION_KEY                               encrypts account logins (instant delivery). If
//                                                       unset, a key is derived from MARKET_ADMIN_KEY,
//                                                       so don't change that key once logins are stored.
//   SITE_URL                                            optional, e.g. https://vaultix.example
//   RESEND_API_KEY                                      sends "forgot password" emails (resend.com). Without it,
//                                                       staff reset passwords by hand on the Staff page.
//   MARKET_EMAIL_FROM                                   sender, e.g. "Vaultix <no-reply@your-domain.com>" (a domain
//                                                       verified in Resend; default onboarding@resend.dev, which
//                                                       only delivers to your own Resend login email)
//   MARKET_FEE_PCT / MARKET_FEE_FIXED                   buyer payment fee (default 3% + $0.30)
//   MARKET_COMMISSION_PCT                               cut taken from sellers (default 5%)
//   MARKET_AUTO_PAYOUT_MAX                              Stripe withdrawals up to this many $ per seller per
//                                                       24 h are sent automatically, no staff needed (default
//                                                       200; 0 = staff approve every withdrawal)
//
//  Add funds (no card needed)
//   - A signed-in user asks to add $5-$2,000 by bank transfer or crypto, gets the owner's payment
//     details (set on the Staff page) and a reference code, sends the money and taps "I've sent it".
//   - Staff check it arrived and credit the amount received (or reject). Nothing is automatic.
//   - Added funds can be SPENT on Vaultix but not withdrawn, so nobody can pass money through the
//     site. Purchases use added funds first, then sales earnings.
//
//  Saved cards
//   - Card numbers are stored by Stripe, never here. Each user gets a Stripe Customer; on Stripe's
//     checkout page they can tick "save card". We only keep the customer id and show brand + last 4.
//   - Paying with a saved card creates a PaymentIntent for that card (3-D Secure handled by Stripe).
//
//  Instant delivery (accounts, codes…)
//   - The seller enters one login per item when posting. Each is encrypted (AES-256-GCM) and kept in
//     a Redis list mkt:creds:<listingId>; stock = number of logins left. They are never sent in
//     listings or profiles.
//   - When an order is paid, one login is popped (LPOP is atomic, so two buyers never get the same
//     one) and attached to the order, still encrypted. Only that order's buyer, seller and staff
//     can see it. The money stays in escrow until the buyer confirms the login works.
//
//  Images
//   - Games in shop-site/games.js use their official icon (?action=icons, looked up live and
//     cached, because Roblox icon URLs expire).
//   - Any other game is "Other": the seller must upload their own picture (JPEG/PNG/WebP, max
//     ~200 KB, already resized in the browser). It is served from ?action=image&id=<listingId>.
// ============================================================================
const crypto = require('crypto')
const { GAMES, find: findGame, steamIcon } = require('../shop-site/games.js')

const SELLERS = 'mkt:sellers' // all user accounts (name kept for existing data)
const LISTINGS = 'mkt:listings'
const IMAGES = 'mkt:images'
const ORDERS = 'mkt:orders'
const PAYOUTS = 'mkt:payouts'
const DEPOSITS = 'mkt:deposits'
const SETTINGS = 'mkt:settings'
const MIN_DEPOSIT = 5, MAX_DEPOSIT = 2000, MAX_OPEN_DEPOSITS = 3
const MAX_IMAGE_BYTES = 200 * 1024
const ICON_TTL_MS = 6 * 60 * 60 * 1000
const CATEGORIES = ['Currency', 'Accounts', 'Top ups', 'Items', 'Boosting', 'Gift cards']
const MAX_LISTINGS_PER_SELLER = 50
const AUTO_COMPLETE_MS = 3 * 24 * 60 * 60 * 1000
const MIN_PAYOUT = 10
const FEE_PCT = Number(process.env.MARKET_FEE_PCT ?? 3) / 100
const FEE_FIXED = Number(process.env.MARKET_FEE_FIXED ?? 0.3)
const COMMISSION_PCT = Number(process.env.MARKET_COMMISSION_PCT ?? 5) / 100
const CRYPTO_NETWORKS = ['USDT (TRC20)', 'USDT (ERC20)', 'BTC', 'ETH', 'LTC']
const PAYOUT_METHODS = ['stripe', 'paypal', 'crypto', 'bank']
const AUTO_PAYOUT_MAX = Math.max(0, Number(process.env.MARKET_AUTO_PAYOUT_MAX ?? 200) || 0)
const MAX_LOGINS = 50
const credsKey = (listingId) => `mkt:creds:${listingId}`
const OWNER_NAMES = String(process.env.MARKET_OWNERS ?? 'Kaitrades').split(',').map((n) => n.trim().toLowerCase()).filter(Boolean)
const isOwnerName = (name) => OWNER_NAMES.includes(String(name || '').toLowerCase())

/* ------------------------------ storage ------------------------------ */
async function redis(cmd) {
  const base = process.env.UPSTASH_REDIS_REST_URL || process.env.KV_REST_API_URL
  const tok = process.env.UPSTASH_REDIS_REST_TOKEN || process.env.KV_REST_API_TOKEN
  if (!base || !tok) throw Object.assign(new Error('Storage not configured'), { status: 503 })
  const r = await fetch(base, {
    method: 'POST',
    headers: { Authorization: `Bearer ${tok}`, 'Content-Type': 'application/json' },
    body: JSON.stringify(cmd),
  })
  if (!r.ok) throw Object.assign(new Error('Storage error'), { status: 502 })
  return (await r.json()).result
}
async function getAll(key) {
  const flat = (await redis(['HGETALL', key])) || []
  const out = []
  for (let i = 1; i < flat.length; i += 2) {
    try { out.push(JSON.parse(flat[i])) } catch {}
  }
  return out
}
async function getOne(key, id) {
  const v = await redis(['HGET', key, String(id || '')])
  return v ? JSON.parse(v) : null
}
const put = (key, obj) => redis(['HSET', key, obj.id, JSON.stringify(obj)])

// One change at a time per wallet / listing / request. Two requests sent at the same moment
// (easy from the browser's dev tools) could otherwise both pass a balance or stock check before
// either was saved, and spend the same money, or sell the same item, twice. The lock expires by
// itself after 15s, so a crashed request can't block anyone for long.
async function withLock(name, fn) {
  const key = `mkt:lock:${name}`, me = crypto.randomBytes(8).toString('hex')
  for (let i = 0; ; i++) {
    if (await redis(['SET', key, me, 'NX', 'PX', '15000'])) break
    if (i >= 40) throw bad('Busy with another request. Try again in a moment.', 409)
    await new Promise((r) => setTimeout(r, 75))
  }
  try { return await fn() } finally {
    try { if ((await redis(['GET', key])) === me) await redis(['DEL', key]) } catch {}
  }
}

/* ------------------------------ helpers ------------------------------ */
const sha = (s) => crypto.createHash('sha256').update(String(s)).digest('hex')
const newId = (p) => p + crypto.randomBytes(6).toString('hex')
const r2 = (n) => Math.round(n * 100) / 100
const cents = (n) => Math.round(n * 100)
const sum = (xs) => r2(xs.reduce((a, b) => a + b, 0))
function safeEq(a, b) {
  return crypto.timingSafeEqual(Buffer.from(sha(a)), Buffer.from(sha(b)))
}
function bad(msg, status = 400) { return Object.assign(new Error(msg), { status }) }
function str(v, name, min, max) {
  const s = typeof v === 'string' ? v.trim() : ''
  if (s.length < min || s.length > max) throw bad(`${name} must be ${min}-${max} characters`)
  return s
}
// ---- encryption for account logins ----
function encKey() {
  const k = process.env.MARKET_ENCRYPTION_KEY || (process.env.MARKET_ADMIN_KEY && `vaultix-admin:${process.env.MARKET_ADMIN_KEY}`)
  if (!k) throw bad('Instant delivery needs MARKET_ENCRYPTION_KEY (or MARKET_ADMIN_KEY) on the server', 503)
  return crypto.createHash('sha256').update(k).digest()
}
function encrypt(obj) {
  const iv = crypto.randomBytes(12)
  const c = crypto.createCipheriv('aes-256-gcm', encKey(), iv)
  const ct = Buffer.concat([c.update(JSON.stringify(obj), 'utf8'), c.final()])
  return Buffer.concat([iv, c.getAuthTag(), ct]).toString('base64')
}
function decrypt(b64) {
  try {
    const buf = Buffer.from(String(b64), 'base64')
    const d = crypto.createDecipheriv('aes-256-gcm', encKey(), buf.subarray(0, 12))
    d.setAuthTag(buf.subarray(12, 28))
    return JSON.parse(Buffer.concat([d.update(buf.subarray(28)), d.final()]).toString('utf8'))
  } catch (e) {
    if (e.status) throw e
    return null // wrong key or damaged data
  }
}
// Validate the logins a seller enters for instant delivery.
function parseLogins(list) {
  if (!Array.isArray(list) || !list.length) throw bad('Add at least one account login')
  if (list.length > MAX_LOGINS) throw bad(`You can add up to ${MAX_LOGINS} logins per listing`)
  const opt = (v, max) => (typeof v === 'string' ? v.trim().slice(0, max) : '')
  return list.map((x, i) => {
    const login = opt(x && x.login, 120), password = opt(x && x.password, 200)
    if (!login || !password) throw bad(`Login ${i + 1}: enter a username and password`)
    return { login, password, email: opt(x.email, 120), emailPassword: opt(x.emailPassword, 200), notes: opt(x.notes, 300) }
  })
}

function feesFor(price, method) {
  const fee = method === 'balance' ? 0 : r2(price * FEE_PCT + FEE_FIXED)
  const commission = r2(price * COMMISSION_PCT)
  return { price, fee, total: r2(price + fee), commission, sellerNet: r2(price - commission) }
}
// What Stripe (and the buyer's Stripe receipt) calls a purchase: the order number only, never the
// game or listing title. Staff match it to the order on the Staff page.
const stripeLabel = (order) => `Vaultix Market order ${order.id}`
function siteUrl(req) {
  if (process.env.SITE_URL) return process.env.SITE_URL.replace(/\/$/, '')
  const h = (req && req.headers) || {}
  const host = h['x-forwarded-host'] || h.host
  const proto = h['x-forwarded-proto'] || (/^(localhost|127\.)/.test(host || '') ? 'http' : 'https')
  if (!host) throw bad('SITE_URL is not set', 503)
  return `${proto}://${host}`
}

// Validate an uploaded picture: a data URL whose bytes really are JPEG, PNG or WebP (no SVG/HTML).
function parseImage(dataUrl) {
  const m = /^data:image\/(jpeg|png|webp);base64,([A-Za-z0-9+/]+=*)$/.exec(String(dataUrl || ''))
  if (!m) throw bad('Picture must be a JPEG, PNG or WebP image')
  const buf = Buffer.from(m[2], 'base64')
  if (buf.length > MAX_IMAGE_BYTES) throw bad('Picture is too large (max 200 KB)')
  const magic = {
    jpeg: buf[0] === 0xff && buf[1] === 0xd8 && buf[2] === 0xff,
    png: buf.slice(0, 8).equals(Buffer.from([0x89, 0x50, 0x4e, 0x47, 0x0d, 0x0a, 0x1a, 0x0a])),
    webp: buf.slice(0, 4).toString('latin1') === 'RIFF' && buf.slice(8, 12).toString('latin1') === 'WEBP',
  }
  if (!magic[m[1]]) throw bad('Picture file is not a valid image')
  return { type: `image/${m[1]}`, data: m[2] }
}

// Official game icons, looked up live and cached per server instance.
let iconCache = { at: 0, icons: null }
async function loadIcons() {
  if (iconCache.icons && Date.now() - iconCache.at < ICON_TTL_MS) return iconCache.icons
  const icons = {}
  const getJson = (url) => fetch(url, { signal: AbortSignal.timeout(6000) }).then((r) => (r.ok ? r.json() : null)).catch(() => null)
  const rbx = GAMES.filter((g) => g.roblox), apl = GAMES.filter((g) => g.apple)
  const [rj, aj] = await Promise.all([
    rbx.length ? getJson(`https://thumbnails.roblox.com/v1/games/icons?universeIds=${rbx.map((g) => g.roblox).join(',')}&size=256x256&format=Png&isCircular=false`) : null,
    apl.length ? getJson(`https://itunes.apple.com/lookup?country=us&id=${apl.map((g) => g.apple).join(',')}`) : null,
  ])
  for (const t of (rj && rj.data) || []) {
    const g = rbx.find((x) => x.roblox === t.targetId)
    if (g && t.state === 'Completed' && /^https:\/\/[a-z0-9.-]+\.rbxcdn\.com\//.test(t.imageUrl)) icons[g.name] = t.imageUrl
  }
  for (const a of (aj && aj.results) || []) {
    const g = apl.find((x) => x.apple === a.trackId)
    const url = a.artworkUrl512 || a.artworkUrl100
    if (g && /^https:\/\/[a-z0-9.-]+\.mzstatic\.com\//.test(url)) icons[g.name] = url.replace(/\/\d+x\d+bb\.(jpg|png)$/, '/256x256bb.jpg')
  }
  for (const g of GAMES) if (g.steam) icons[g.name] = steamIcon(g.steam)
  if (Object.keys(icons).length >= GAMES.length * 0.8) iconCache = { at: Date.now(), icons }
  return icons
}

/* ------------------------------ Stripe ------------------------------ */
function formEncode(obj, prefix = '', out = []) {
  for (const [k, v] of Object.entries(obj)) {
    if (v === undefined || v === null) continue
    const key = prefix ? `${prefix}[${k}]` : k
    if (typeof v === 'object') formEncode(v, key, out)
    else out.push([key, String(v)])
  }
  return out
}
// Pinned so Stripe changes can't silently change responses. Update it on purpose, after testing.
const STRIPE_VERSION = process.env.STRIPE_API_VERSION || '2026-10-28.endive'
// path '/x' calls the v1 API (form-encoded); '/v2/...' calls the v2 API (JSON).
async function stripe(method, path, params, idempotencyKey) {
  const key = process.env.STRIPE_SECRET_KEY
  if (!key) throw bad('Card payments are not set up yet (STRIPE_SECRET_KEY missing)', 503)
  const v2 = path.startsWith('/v2/')
  const headers = { Authorization: `Bearer ${key}`, 'Stripe-Version': STRIPE_VERSION }
  let body
  if (params) {
    if (v2) { headers['Content-Type'] = 'application/json'; body = JSON.stringify(params) }
    else { headers['Content-Type'] = 'application/x-www-form-urlencoded'; body = new URLSearchParams(formEncode(params)).toString() }
  }
  if (idempotencyKey) headers['Idempotency-Key'] = idempotencyKey
  const r = await fetch(`https://api.stripe.com${v2 ? '' : '/v1'}${path}`, { method, headers, body })
  const j = await r.json().catch(() => ({}))
  if (!r.ok) throw Object.assign(bad((j.error && j.error.message) || 'Payment provider error', 502), { stripeStatus: r.status })
  return j
}
// Stripe Tax: off unless STRIPE_TAX=on. Only turn it on after adding a tax registration in
// Stripe (Tax -> Registrations), otherwise Stripe silently collects no tax.
const taxOn = () => /^(on|1|true|yes)$/i.test(process.env.STRIPE_TAX || '')

/* ------------------------------ users ------------------------------ */
function statsFor(userId, orders) {
  const sold = orders.filter((o) => o.sellerId === userId)
  const reviews = sold.filter((o) => o.review)
  const pos = reviews.filter((o) => o.review.positive).length
  return {
    sales: sold.filter((o) => o.status === 'completed').length,
    reviews: reviews.length,
    positive: reviews.length ? Math.round((pos / reviews.length) * 100) : null,
  }
}
// What anyone may see about a user. Contact details are NOT public: only staff and the
// other side of an order see them.
function publicUser(u, orders) {
  if (!u) return null
  return {
    id: u.id, name: u.name, bio: u.bio || '', verified: !!u.verified, verifiedAt: u.verifiedAt || null, owner: !!u.owner,
    createdAt: u.createdAt, ...(orders ? statsFor(u.id, orders) : {}),
  }
}
// ---- passwords & sign-in tokens ----
// Passwords are stored as scrypt hashes with a random salt; never in plain text.
const SCRYPT = { N: 16384, r: 8, p: 1 }
function hashPassword(pw) {
  const salt = crypto.randomBytes(16)
  const h = crypto.scryptSync(String(pw), salt, 32, SCRYPT)
  return `scrypt$${salt.toString('hex')}$${h.toString('hex')}`
}
function checkPassword(pw, stored) {
  const [kind, salt, hex] = String(stored || 'scrypt$00$00').split('$')
  if (kind !== 'scrypt') return false
  const want = Buffer.from(hex, 'hex')
  const got = crypto.scryptSync(String(pw), Buffer.from(salt, 'hex'), 32, SCRYPT)
  return want.length === got.length && crypto.timingSafeEqual(want, got)
}
const DUMMY_HASH = hashPassword('not-a-real-password')
function validPassword(pw) {
  if (typeof pw !== 'string' || pw.length < 8) throw bad('Password must be at least 8 characters')
  if (pw.length > 128) throw bad('Password is too long')
  return pw
}
function validEmail(v) {
  const e = typeof v === 'string' ? v.trim().toLowerCase() : ''
  if (e.length > 120 || !/^[^\s@]+@[^\s@]+\.[^\s@]{2,}$/.test(e)) throw bad('Enter a valid email address')
  return e
}
// Each device that signs in gets its own token; we keep only their hashes (newest 10).
function tokenOk(u, token) {
  if (!u || !token) return false
  const h = sha(token)
  return h === u.tokenHash || (u.tokens || []).includes(h)
}
function newToken(u) {
  const token = crypto.randomBytes(24).toString('hex')
  u.tokens = [sha(token), ...(u.tokens || [])].slice(0, 10)
  return token
}
const MAX_FAILS = 8, LOCK_MS = 15 * 60 * 1000

// ---- email (forgot password) ----
// Sent through Resend's HTTP API when RESEND_API_KEY is set. Without it the site still works and
// "Forgot password" tells people to ask staff, who reset it on the Staff page.
const RESET_MS = 30 * 60 * 1000 // a reset link works for 30 minutes
const emailOn = () => !!process.env.RESEND_API_KEY
async function sendEmail(to, subject, lines) {
  const text = lines.join('\n\n')
  const html = lines.map((l) => {
    const e = l.replace(/&/g, '&amp;').replace(/</g, '&lt;').replace(/>/g, '&gt;')
    return `<p>${e.replace(/(https?:\/\/\S+)/g, '<a href="$1">$1</a>')}</p>`
  }).join('')
  const r = await fetch('https://api.resend.com/emails', {
    method: 'POST',
    headers: { Authorization: `Bearer ${process.env.RESEND_API_KEY}`, 'Content-Type': 'application/json' },
    body: JSON.stringify({ from: process.env.MARKET_EMAIL_FROM || 'Vaultix <onboarding@resend.dev>', to: [to], subject, text, html }),
    signal: AbortSignal.timeout(10000),
  }).catch(() => null)
  if (!r || !r.ok) {
    console.error('Email failed:', r ? r.status : 'network', r ? await r.text().catch(() => '') : '')
    throw bad('Could not send the email right now. Try again in a minute.', 502)
  }
}
// Links in emails always point at our own site: SITE_URL, or the address Vercel / Render give the
// site. Never a Host header from the request, which someone could fake to get links to their site.
function emailBase() {
  const v = process.env.SITE_URL || process.env.RENDER_EXTERNAL_URL
    || (process.env.VERCEL_PROJECT_PRODUCTION_URL && `https://${process.env.VERCEL_PROJECT_PRODUCTION_URL}`)
  if (!v) throw bad('Set SITE_URL on the server so emailed links point at your site', 503)
  return v.replace(/\/$/, '')
}
// "Your password was changed" / "your email was changed" notices, so a takeover doesn't go unnoticed.
// Best effort: a failed notice never blocks the change itself.
async function notify(to, subject, line) {
  if (!emailOn() || !to) return
  try {
    await sendEmail(to, subject, [line,
      `If this wasn't you, reset your password now at ${emailBase()}/#/forgot and message the site owner.`])
  } catch {}
}
async function authUser(body) {
  const u = await getOne(SELLERS, body.sellerId)
  if (!tokenOk(u, body.token)) throw bad('Please sign in again', 401)
  return u
}
function adminKeyOk(given) {
  const key = process.env.MARKET_ADMIN_KEY
  if (!key) throw bad('MARKET_ADMIN_KEY is not set on the server', 503)
  return !!given && safeEq(given, key)
}
// Staff actions: the admin key, or a signed-in owner account (ownerId + ownerToken; separate
// from sellerId, which some staff actions use for the user being acted on).
async function authAdmin(body) {
  if (body.ownerId && body.ownerToken) {
    const u = await getOne(SELLERS, body.ownerId)
    if (u && u.owner && tokenOk(u, body.ownerToken)) return u
  }
  if (!adminKeyOk(body.adminKey)) throw bad(body.adminKey ? 'Wrong admin key' : 'Enter the admin key, or sign in as the owner', 401)
  return null
}

/* ------------------------------ orders & wallet ------------------------------ */
// Auto-confirm orders the buyer didn't answer within 3 days of delivery.
async function loadOrders() {
  const orders = await getAll(ORDERS)
  for (const o of orders) {
    if (o.status === 'delivered' && Date.now() - o.deliveredAt > AUTO_COMPLETE_MS) {
      o.status = 'completed'; o.completedAt = o.deliveredAt + AUTO_COMPLETE_MS; o.autoCompleted = true
      await put(ORDERS, o)
    }
  }
  return orders
}
// available = what can be spent; withdrawable = the part that can be taken out (sales earnings).
// Added funds (credited deposits) are spend-only, and purchases use them first.
function walletFor(userId, orders, payouts, deposits = []) {
  const sold = orders.filter((o) => o.sellerId === userId)
  const earned = sum(sold.filter((o) => o.status === 'completed').map((o) => o.sellerNet))
  const pending = sum(sold.filter((o) => ['paid', 'delivered', 'disputed'].includes(o.status)).map((o) => o.sellerNet))
  const spent = sum(orders.filter((o) => o.buyerId === userId && o.method === 'balance' && !['refunded', 'cancelled'].includes(o.status)).map((o) => o.total))
  const mine = payouts.filter((p) => p.userId === userId)
  const withdrawn = sum(mine.filter((p) => p.status === 'paid').map((p) => p.amount))
  const requested = sum(mine.filter((p) => p.status === 'requested').map((p) => p.amount))
  const added = sum(deposits.filter((d) => d.userId === userId && d.status === 'credited').map((d) => d.credited))
  const credit = r2(Math.max(added - spent, 0))
  const withdrawable = r2(earned - Math.max(spent - added, 0) - withdrawn - requested)
  return { available: r2(withdrawable + credit), withdrawable, credit, added, pending, earned, spent, withdrawn, requested }
}
// Where people send money to add funds (set by staff on the Staff page).
async function depositSettings() {
  const v = await redis(['HGET', SETTINGS, 'deposit'])
  const d = v ? JSON.parse(v) : {}
  return { bank: d.bank || '', crypto: d.crypto || {} }
}
function depositMethods(set) {
  return [...(set.bank ? ['bank'] : []), ...CRYPTO_NETWORKS.filter((n) => set.crypto[n]).map((n) => `crypto:${n}`)]
}
const depositRef = () => 'VX-' + crypto.randomBytes(4).toString('hex').toUpperCase().slice(0, 6)
// Callers that already hold the listing's lock use stockChange; everyone else changeStock.
async function stockChange(listingId, delta) {
  const l = await getOne(LISTINGS, listingId)
  if (!l) return null
  l.stock = Math.max(0, (l.stock ?? 1) + delta)
  l.sold = Math.max(0, (l.sold || 0) - delta)
  await put(LISTINGS, l)
  return l
}
const changeStock = (listingId, delta) => withLock(`listing:${listingId}`, () => stockChange(listingId, delta))
async function refundOrder(o, reason) {
  if (o.method !== 'balance' && o.paymentIntent) {
    await stripe('POST', '/refunds', { payment_intent: o.paymentIntent, metadata: { orderId: o.id } }, `refund-${o.id}`)
  }
  // Did this order take an item out of stock? (Older orders have no flag: they did once paid.)
  const took = o.stockTaken !== undefined ? o.stockTaken : ['paid', 'delivered', 'disputed'].includes(o.status)
  o.status = 'refunded'; o.refundedAt = Date.now(); o.refundReason = reason
  await put(ORDERS, o)
  // A login the buyer has already seen can't be sold again, so it doesn't go back into stock.
  if (took && !o.autoDelivered) await changeStock(o.listingId, +1)
}
// Paid order on an instant-delivery listing: hand over one login right away.
async function autoDeliver(o, l) {
  const enc = await redis(['LPOP', credsKey(l.id)])
  const left = Number(await redis(['LLEN', credsKey(l.id)])) || 0
  const fresh = await getOne(LISTINGS, l.id)
  if (fresh) { fresh.stock = left; fresh.sold = (fresh.sold || 0) + (enc ? 1 : 0); await put(LISTINGS, fresh) }
  if (!enc) return false
  o.loginEnc = enc
  o.autoDelivered = true
  o.status = 'delivered'; o.deliveredAt = Date.now()
  return true
}
// Mark an order paid and take the item out of stock (auto-delivering logins when there are any).
async function fulfil(o) {
  return withLock(`listing:${o.listingId}`, () => fulfilLocked(o))
}
async function fulfilLocked(o) {
  const l = await getOne(LISTINGS, o.listingId)
  o.paidAt = Date.now()
  const soldOut = async () => { o.status = 'paid'; o.stockTaken = false; await refundOrder(o, 'Sold out before your payment finished'); return o }
  if (!l || (l.stock ?? 1) < 1) return soldOut()
  if (l.delivery === 'instant') {
    if (!(await autoDeliver(o, l))) return soldOut()
    o.stockTaken = true
  } else {
    await stockChange(o.listingId, -1)
    o.stockTaken = true
    o.status = 'paid'
  }
  await put(ORDERS, o)
  return o
}
// Called by the Stripe webhook when a checkout is paid.
// Stripe can send the same event twice at once, so one order is marked paid only once.
async function markPaid(orderId, paymentIntent) {
  return withLock(`order:${orderId}`, async () => {
    const o = await getOne(ORDERS, orderId)
    if (!o || o.status !== 'pending') return o
    o.paymentIntent = paymentIntent || o.paymentIntent
    return fulfil(o)
  })
}
async function markExpired(orderId) {
  const o = await getOne(ORDERS, orderId)
  if (o && o.status === 'pending') { o.status = 'cancelled'; o.cancelledAt = Date.now(); await put(ORDERS, o) }
}
async function markSavedCardFailed(orderId) {
  const o = await getOne(ORDERS, orderId)
  if (o && o.status === 'pending' && o.method === 'saved') { o.status = 'cancelled'; o.cancelledAt = Date.now(); await put(ORDERS, o) }
}
// Sellers get paid through Stripe Connect (Accounts v2, "recipient" accounts). They can receive
// money once Stripe marks their stripe_transfers capability active.
async function payoutReady(accountId) {
  const a = await stripe('GET', `/v2/core/accounts/${accountId}?include=configuration.recipient`)
  const t = (((((a.configuration || {}).recipient || {}).capabilities || {}).stripe_balance || {}).stripe_transfers) || {}
  return t.status === 'active'
}
async function onStripeAccount(accountId) {
  const u = (await getAll(SELLERS)).find((x) => x.stripeAccount === accountId)
  if (u) { u.stripeReady = await payoutReady(accountId); await put(SELLERS, u) }
}
// ---- automatic withdrawals ----
// Stripe withdrawals go out straight away, up to AUTO_PAYOUT_MAX per seller per 24 h. Anything
// bigger, PayPal / crypto / bank (sent by hand), or a transfer Stripe refuses waits for staff.
const DAY_MS = 24 * 60 * 60 * 1000
function autoPayoutLeft(userId, payouts) {
  const used = sum(payouts.filter((p) => p.userId === userId && p.auto && Date.now() - p.processedAt < DAY_MS).map((p) => p.amount))
  return r2(AUTO_PAYOUT_MAX - used)
}
async function sendAutoPayout(u, p) {
  try {
    const t = await stripe('POST', '/transfers', { amount: cents(p.amount), currency: 'usd', destination: u.stripeAccount, metadata: { payoutId: p.id } }, p.autoKey)
    Object.assign(p, { status: 'paid', auto: true, transferId: t.id, processedAt: Date.now(), note: 'Sent automatically' })
    delete p.autoKey
  } catch (e) {
    // Stripe answered "no" (e.g. not enough available balance yet): nothing was sent, so staff can
    // retry with a fresh request. Otherwise (timeout, Stripe error 5xx) the transfer MAY have gone
    // through: autoKey stays, so a staff approval repeats this exact request and Stripe won't pay twice.
    if (e.stripeStatus >= 400 && e.stripeStatus < 500) delete p.autoKey
    p.autoError = String(e.message || 'failed').slice(0, 200)
    console.error('auto payout', p.id, p.autoError)
  }
  await put(PAYOUTS, p)
}
// ---- saved cards (Stripe Customer) ----
async function ensureCustomer(u) {
  if (u.stripeCustomer) return u.stripeCustomer
  const c = await stripe('POST', '/customers', { name: u.name, metadata: { userId: u.id } }, `cust-${u.id}`)
  u.stripeCustomer = c.id
  await put(SELLERS, u)
  return c.id
}
const cardView = (pm) => ({
  id: pm.id, brand: (pm.card && pm.card.brand) || 'card', last4: (pm.card && pm.card.last4) || '????',
  expMonth: pm.card && pm.card.exp_month, expYear: pm.card && pm.card.exp_year,
})
async function listCards(u) {
  if (!u.stripeCustomer) return []
  const r = await stripe('GET', `/customers/${u.stripeCustomer}/payment_methods?type=card&limit=10`)
  return (r.data || []).map(cardView)
}
// A saved card may only be used or removed by the user it belongs to.
async function ownCard(u, pmId) {
  if (!u.stripeCustomer || !/^pm_[A-Za-z0-9_]+$/.test(String(pmId || ''))) throw bad('Card not found', 404)
  const pm = await stripe('GET', `/payment_methods/${pmId}`)
  if (pm.customer !== u.stripeCustomer) throw bad('Card not found', 404)
  return pm
}

// Order as seen by its buyer / seller (contact of the other side included).
function orderView(o, users, viewerId) {
  const byId = (id) => users.find((u) => u.id === id)
  const buyer = byId(o.buyerId), seller = byId(o.sellerId)
  const role = viewerId === o.buyerId ? 'buyer' : viewerId === o.sellerId ? 'seller' : 'staff'
  const { loginEnc, ...rest } = o
  let login = null
  if (loginEnc) { try { login = decrypt(loginEnc) || { error: 'Could not read this login. Contact staff.' } } catch { login = { error: 'Server encryption key is missing. Contact staff.' } } }
  return {
    ...rest, role, login,
    buyer: buyer ? { id: buyer.id, name: buyer.name, contact: buyer.contact } : null,
    seller: seller ? { ...publicUser(seller), contact: seller.contact } : null,
    autoCompleteAt: o.status === 'delivered' ? o.deliveredAt + AUTO_COMPLETE_MS : null,
  }
}
async function participantOrder(b) {
  const u = await authUser(b)
  const orders = await loadOrders()
  const o = orders.find((x) => x.id === b.orderId)
  if (!o || (o.buyerId !== u.id && o.sellerId !== u.id)) throw bad('Order not found', 404)
  return { u, o, orders }
}

async function listPublic() {
  const [users, listings, orders] = await Promise.all([getAll(SELLERS), getAll(LISTINGS), loadOrders()])
  const byId = Object.fromEntries(users.map((s) => [s.id, s]))
  return listings
    .filter((l) => byId[l.sellerId] && (l.stock ?? 1) > 0)
    .map((l) => ({ ...l, stock: l.stock ?? 1, seller: publicUser(byId[l.sellerId], orders) }))
    .sort((a, b) => b.createdAt - a.createdAt)
}

/* ------------------------------ actions ------------------------------ */
const actions = {
  async list() {
    return { listings: await listPublic(), fees: { pct: FEE_PCT, fixed: FEE_FIXED, commission: COMMISSION_PCT, autoPayout: AUTO_PAYOUT_MAX }, owners: OWNER_NAMES, emailReset: emailOn() }
  },

  async profile(b) {
    const [u, orders, listings, users] = await Promise.all([getOne(SELLERS, b.id), loadOrders(), getAll(LISTINGS), getAll(SELLERS)])
    if (!u) throw bad('User not found', 404)
    const reviews = orders
      .filter((o) => o.sellerId === u.id && o.review)
      .sort((a, c) => c.review.at - a.review.at)
      .slice(0, 20)
      .map((o) => ({ positive: o.review.positive, text: o.review.text, at: o.review.at, game: o.game, title: o.title, by: (users.find((x) => x.id === o.buyerId) || {}).name || 'buyer' }))
    return {
      user: publicUser(u, orders),
      listings: listings.filter((l) => l.sellerId === u.id && (l.stock ?? 1) > 0).sort((a, c) => c.createdAt - a.createdAt),
      reviews,
    }
  },

  async register(b) {
    const name = str(b.name, 'Name', 3, 24)
    if (!/^[A-Za-z0-9_.-]+$/.test(name)) throw bad('Name can only use letters, numbers, _ . -')
    const contact = str(b.contact, 'Contact', 3, 80)
    const email = validEmail(b.email)
    validPassword(b.password)
    const users = await getAll(SELLERS)
    if (users.some((s) => s.name.toLowerCase() === name.toLowerCase())) throw bad('That name is taken', 409)
    if (users.some((s) => s.email === email)) throw bad('That email already has an account. Sign in instead.', 409)
    // Owner usernames are reserved: claiming one needs the staff password.
    const owner = isOwnerName(name)
    if (owner && !adminKeyOk(b.adminKey)) throw bad('This username is reserved for the site owner. Enter the staff password to claim it.', 403)
    const now = Date.now()
    const u = { id: newId('s_'), name, contact, email, pw: hashPassword(b.password), bio: '', verified: owner, verifiedAt: owner ? now : null, owner, createdAt: now }
    const token = newToken(u)
    await put(SELLERS, u)
    return { seller: publicUser(u), token }
  },

  // Sign in on any device with email (or username) + password.
  async login(b) {
    const id = typeof b.login === 'string' ? b.login.trim().toLowerCase() : ''
    if (!id || typeof b.password !== 'string' || !b.password) throw bad('Enter your email or username and your password')
    const u = (await getAll(SELLERS)).find((x) => x.email === id || x.name.toLowerCase() === id)
    if (u && u.lockUntil > Date.now()) throw bad('Too many wrong passwords. Try again in 15 minutes.', 429)
    // Always run the password check, so a wrong username takes as long as a wrong password.
    const ok = checkPassword(b.password, (u && u.pw) || DUMMY_HASH) && !!(u && u.pw)
    if (!ok) {
      if (u) {
        u.fails = (u.fails || 0) + 1
        if (u.fails >= MAX_FAILS) { u.lockUntil = Date.now() + LOCK_MS; u.fails = 0 }
        await put(SELLERS, u)
      }
      throw bad(u && !u.pw ? 'This account has no password yet. Sign in on the device you made it on and add one under Profile.' : 'Wrong email/username or password', 401)
    }
    u.fails = 0; u.lockUntil = 0
    const token = newToken(u)
    await put(SELLERS, u)
    return { seller: publicUser(u), token }
  },

  // Signs this device out (its token stops working).
  async logout(b) {
    const u = await authUser(b)
    const h = sha(b.token)
    u.tokens = (u.tokens || []).filter((x) => x !== h)
    if (u.tokenHash === h) delete u.tokenHash
    await put(SELLERS, u)
    return { ok: true }
  },

  // Forgot password: email a one-time link (works for 30 minutes) to the account's email.
  // For an email address the answer is the same whether or not it has an account, so this can't be
  // used to find out who's signed up. (Usernames are public anyway.)
  async forgotPassword(b) {
    if (!emailOn()) return { emailOff: true }
    const id = typeof b.login === 'string' ? b.login.trim().toLowerCase() : ''
    if (!id) throw bad('Enter your email or username')
    const u = (await getAll(SELLERS)).find((x) => x.email === id || x.name.toLowerCase() === id)
    if (u && !u.email && u.name.toLowerCase() === id) {
      throw bad('This account has no email yet. Sign in on the device you made it on and add one under Profile, or message the site owner.')
    }
    if (u && u.email) {
      const now = Date.now()
      // At most one email a minute and 5 an hour per account, so nobody can flood someone's inbox.
      const recent = (u.resetSent || []).filter((t) => now - t < 60 * 60 * 1000)
      if (recent.length < 5 && !(recent[0] && now - recent[0] < 60 * 1000)) {
        const token = crypto.randomBytes(32).toString('hex')
        u.reset = { hash: sha(token), exp: now + RESET_MS }
        u.resetSent = [now, ...recent]
        await put(SELLERS, u)
        await sendEmail(u.email, 'Reset your Vaultix password', [
          `Hi ${u.name},`,
          'Someone (hopefully you) asked to reset the password for your Vaultix account. Open this link to choose a new one. It works for 30 minutes and only once:',
          `${emailBase()}/#/reset/${u.id}/${token}`,
          "If you didn't ask for this, ignore this email. Your password stays the same.",
        ])
      }
    }
    return { sent: true }
  },

  // Set a new password from the emailed link. Signs out every device, then signs this one in.
  async resetPassword(b) {
    const u = await getOne(SELLERS, b.userId)
    const r = u && u.reset
    if (!r || typeof b.resetToken !== 'string' || !safeEq(sha(b.resetToken), r.hash)) {
      throw bad('This reset link is not valid (it may have been used already). Ask for a new one.')
    }
    if (Date.now() > r.exp) {
      delete u.reset
      await put(SELLERS, u)
      throw bad('This reset link has expired. Ask for a new one.')
    }
    u.pw = hashPassword(validPassword(b.password))
    delete u.reset; delete u.tokenHash
    u.tokens = []; u.fails = 0; u.lockUntil = 0
    const token = newToken(u)
    await put(SELLERS, u)
    await notify(u.email, 'Your Vaultix password was changed', `Hi ${u.name}, the password for your Vaultix account was just changed with a reset link, and every device was signed out.`)
    return { seller: publicUser(u), token }
  },

  // Add or change the account's email and password.
  async setLogin(b) {
    const u = await authUser(b)
    if (u.pw && !checkPassword(b.currentPassword || '', u.pw)) throw bad('Your current password is wrong', 401)
    const oldEmail = u.email, hadPw = !!u.pw
    if (b.email !== undefined && b.email !== '') {
      const email = validEmail(b.email)
      if ((await getAll(SELLERS)).some((x) => x.id !== u.id && x.email === email)) throw bad('That email is used by another account', 409)
      u.email = email
    }
    if (b.password) u.pw = hashPassword(validPassword(b.password))
    if (!u.email || !u.pw) throw bad('Add both an email and a password')
    // Changing the password signs out every other device (and cancels any reset link).
    if (b.password) { u.tokens = [sha(b.token)]; delete u.tokenHash; delete u.reset }
    if (u.email !== oldEmail) delete u.reset
    await put(SELLERS, u)
    // Tell the old address when the email changes, and the account when its password changes.
    if (oldEmail && u.email !== oldEmail) await notify(oldEmail, 'Your Vaultix email was changed', `Hi ${u.name}, the email on your Vaultix account was changed from this address to ${u.email}.`)
    else if (b.password && hadPw) await notify(u.email, 'Your Vaultix password was changed', `Hi ${u.name}, the password for your Vaultix account was just changed, and every other device was signed out.`)
    return { ok: true }
  },

  async me(b) {
    const u = await authUser(b)
    const [orders, payouts, deposits] = await Promise.all([loadOrders(), getAll(PAYOUTS), getAll(DEPOSITS)])
    return {
      seller: { ...publicUser(u, orders), contact: u.contact, email: u.email || '', hasPassword: !!u.pw, stripeConnected: !!u.stripeAccount, stripeReady: !!u.stripeReady },
      wallet: walletFor(u.id, orders, payouts, deposits),
      payouts: payouts.filter((p) => p.userId === u.id).sort((a, c) => c.createdAt - a.createdAt).map(({ autoKey, autoError, ...p }) => p),
    }
  },

  async updateProfile(b) {
    const u = await authUser(b)
    if (b.contact !== undefined) u.contact = str(b.contact, 'Contact', 3, 80)
    if (b.bio !== undefined) u.bio = typeof b.bio === 'string' ? b.bio.trim().slice(0, 160) : ''
    await put(SELLERS, u)
    return { ok: true }
  },

  async post(b) {
    const s = await authUser(b)
    const mine = (await getAll(LISTINGS)).filter((l) => l.sellerId === s.id && (l.stock ?? 1) > 0)
    if (mine.length >= MAX_LISTINGS_PER_SELLER) throw bad('Listing limit reached')
    const price = r2(Number(b.price))
    if (!(price >= 1 && price <= 10000)) throw bad('Price must be between 1 and 10000')
    if (!CATEGORIES.includes(b.category)) throw bad('Pick a category')
    const instant = b.delivery === 'instant'
    const logins = instant ? parseLogins(b.logins) : null
    const stock = instant ? logins.length : b.stock === undefined || b.stock === '' ? 1 : Math.floor(Number(b.stock))
    if (!(stock >= 1 && stock <= 999)) throw bad('Stock must be between 1 and 999')
    const was = r2(Number(b.wasPrice))
    const known = findGame(b.game)
    const image = known ? null : b.image ? parseImage(b.image) : null
    if (!known && !image) throw bad('Add a picture for games that are not in the list')
    const listing = {
      id: newId('l_'), sellerId: s.id,
      game: known ? known.name : str(b.game, 'Game', 2, 30),
      hasImage: !!image,
      title: str(b.title, 'Title', 3, 70),
      description: str(b.description, 'Description', 10, 1000),
      price, wasPrice: was > price && was <= 100000 ? was : null,
      category: b.category, stock, sold: 0,
      delivery: instant ? 'instant' : 'manual',
      createdAt: Date.now(),
    }
    if (instant) await redis(['RPUSH', credsKey(listing.id), ...logins.map(encrypt)])
    if (image) await redis(['HSET', IMAGES, listing.id, JSON.stringify(image)])
    await put(LISTINGS, listing)
    return { listing: { ...listing, seller: publicUser(s) } }
  },

  // Remove a listing from sale. Kept in storage (stock 0) so past orders still show it.
  async remove(b) {
    const s = await authUser(b)
    const l = await getOne(LISTINGS, b.listingId)
    if (!l || l.sellerId !== s.id) throw bad('Listing not found', 404)
    l.stock = 0; l.removed = true
    await put(LISTINGS, l)
    await redis(['DEL', credsKey(l.id)])
    return { ok: true }
  },

  // ---- buying ----
  async checkout(b, req) {
    const u = await authUser(b)
    const l = await getOne(LISTINGS, b.listingId)
    if (!l || (l.stock ?? 1) < 1) throw bad('This listing is sold out or was removed', 404)
    if (l.sellerId === u.id) throw bad("You can't buy your own listing")
    if (b.acceptFinal !== true) throw bad('Please confirm you understand all sales are final (no refunds once delivered)')
    const method = ['card', 'crypto', 'balance', 'saved'].includes(b.method) ? b.method : 'card'
    const money = feesFor(l.price, method)
    const order = {
      id: newId('o_'), listingId: l.id, buyerId: u.id, sellerId: l.sellerId,
      title: l.title, game: l.game, category: l.category, hasImage: !!l.hasImage,
      ...money, method, status: 'pending', createdAt: Date.now(), messages: [], acceptedFinal: true,
    }
    if (method === 'balance') {
      // Check the balance and save the order as one step (see withLock).
      return withLock(`wallet:${u.id}`, async () => {
        const [orders, payouts, deposits] = await Promise.all([loadOrders(), getAll(PAYOUTS), getAll(DEPOSITS)])
        if (walletFor(u.id, orders, payouts, deposits).available < money.total) throw bad('Not enough balance')
        await fulfil(order)
        return { orderId: order.id }
      })
    }
    const site = siteUrl(req)
    if (method === 'saved' && !taxOn()) {
      // One-click payment with a card the buyer saved before.
      const pm = await ownCard(u, b.paymentMethod)
      await put(ORDERS, order)
      let pi
      try {
        pi = await stripe('POST', '/payment_intents', {
          amount: cents(money.total), currency: 'usd', customer: u.stripeCustomer, payment_method: pm.id,
          confirm: 'true', metadata: { orderId: order.id },
          return_url: `${site}/#/order/${order.id}`,
          description: stripeLabel(order),
        }, `saved-${order.id}`)
      } catch (e) {
        order.status = 'cancelled'; order.cancelledAt = Date.now(); await put(ORDERS, order)
        throw bad(/declin/i.test(e.message) ? e.message : `Payment failed: ${e.message}`, 402)
      }
      order.paymentIntent = pi.id
      await put(ORDERS, order)
      if (pi.status === 'succeeded') { await markPaid(order.id, pi.id); return { orderId: order.id } }
      if (pi.status === 'requires_action' && pi.next_action && pi.next_action.redirect_to_url) {
        return { orderId: order.id, url: pi.next_action.redirect_to_url.url } // bank's 3-D Secure check
      }
      if (pi.status === 'processing') return { orderId: order.id }
      order.status = 'cancelled'; order.cancelledAt = Date.now(); await put(ORDERS, order)
      throw bad('Your card was declined. Try another card.', 402)
    }
    const customer = await ensureCustomer(u)
    const session = await stripe('POST', '/checkout/sessions', {
      mode: 'payment',
      customer,
      integration_identifier: 'vaultix-market-qkzvbrtm',
      automatic_tax: taxOn() ? { enabled: true } : undefined,
      customer_update: taxOn() ? { address: 'auto', name: 'auto' } : undefined,
      // Lets the buyer tick "save my card" on Stripe's page, and shows cards they saved before.
      saved_payment_method_options: { payment_method_save: 'enabled' },
      client_reference_id: order.id,
      success_url: `${site}/#/order/${order.id}`,
      cancel_url: `${site}/#/checkout/${l.id}`,
      line_items: [
        { quantity: 1, price_data: { currency: 'usd', unit_amount: cents(money.price), product_data: { name: stripeLabel(order) } } },
        { quantity: 1, price_data: { currency: 'usd', unit_amount: cents(money.fee), product_data: { name: 'Payment fee' } } },
      ],
      metadata: { orderId: order.id },
      payment_intent_data: { metadata: { orderId: order.id } },
      expires_at: Math.floor(Date.now() / 1000) + 31 * 60,
    }, `checkout-${order.id}`)
    order.stripeSession = session.id
    await put(ORDERS, order)
    return { orderId: order.id, url: session.url }
  },

  // ---- saved cards ----
  async cards(b) {
    const u = await authUser(b)
    return { cards: await listCards(u) }
  },

  // Stripe's secure page in "setup" mode: save a card without buying anything.
  async addCard(b, req) {
    const u = await authUser(b)
    const customer = await ensureCustomer(u)
    const site = siteUrl(req)
    const session = await stripe('POST', '/checkout/sessions', {
      mode: 'setup', customer, currency: 'usd',
      success_url: `${site}/#/cards`, cancel_url: `${site}/#/cards`,
      metadata: { userId: u.id },
    })
    return { url: session.url }
  },

  async removeCard(b) {
    const u = await authUser(b)
    const pm = await ownCard(u, b.paymentMethod)
    await stripe('POST', `/payment_methods/${pm.id}/detach`, {})
    return { ok: true }
  },

  async myOrders(b) {
    const u = await authUser(b)
    const [orders, users] = await Promise.all([loadOrders(), getAll(SELLERS)])
    const mine = orders.filter((o) => o.buyerId === u.id || o.sellerId === u.id).sort((a, c) => c.createdAt - a.createdAt)
    return { orders: mine.map((o) => orderView(o, users, u.id)) }
  },

  async order(b) {
    const { u, o } = await participantOrder(b)
    return { order: orderView(o, await getAll(SELLERS), u.id) }
  },

  async deliver(b) {
    const { u, o } = await participantOrder(b)
    if (o.sellerId !== u.id) throw bad('Only the seller can deliver')
    if (o.status !== 'paid') throw bad('This order is not waiting for delivery')
    o.delivery = str(b.text, 'Delivery details', 1, 2000)
    o.status = 'delivered'; o.deliveredAt = Date.now()
    await put(ORDERS, o)
    return { ok: true }
  },

  async confirm(b) {
    const { u, o } = await participantOrder(b)
    if (o.buyerId !== u.id) throw bad('Only the buyer can confirm')
    if (!['paid', 'delivered'].includes(o.status)) throw bad('This order can’t be confirmed now')
    o.status = 'completed'; o.completedAt = Date.now()
    if (typeof b.positive === 'boolean') o.review = { positive: b.positive, text: String(b.review || '').trim().slice(0, 300), at: Date.now() }
    await put(ORDERS, o)
    return { ok: true }
  },

  async review(b) {
    const { u, o } = await participantOrder(b)
    if (o.buyerId !== u.id || o.status !== 'completed' || o.review) throw bad('You can’t review this order')
    if (typeof b.positive !== 'boolean') throw bad('Choose positive or negative')
    o.review = { positive: b.positive, text: String(b.review || '').trim().slice(0, 300), at: Date.now() }
    await put(ORDERS, o)
    return { ok: true }
  },

  async dispute(b) {
    const { u, o } = await participantOrder(b)
    if (o.buyerId !== u.id) throw bad('Only the buyer can report a problem')
    if (o.status === 'delivered' || o.deliveredAt) throw bad('All sales are final once the item is delivered, so this order can’t be refunded. Message the seller if you need help.')
    if (o.status !== 'paid') throw bad('This order can’t be disputed now')
    o.status = 'disputed'; o.dispute = { reason: str(b.reason, 'Reason', 5, 500), at: Date.now() }
    await put(ORDERS, o)
    return { ok: true }
  },

  async cancel(b) {
    const { u, o } = await participantOrder(b)
    if (o.buyerId === u.id && o.status === 'pending') {
      o.status = 'cancelled'; o.cancelledAt = Date.now()
      if (o.stripeSession) await stripe('POST', `/checkout/sessions/${o.stripeSession}/expire`).catch(() => {})
      await put(ORDERS, o)
      return { ok: true }
    }
    // Seller can't deliver: refund the buyer in full.
    if (o.sellerId === u.id && ['paid', 'disputed'].includes(o.status)) {
      await refundOrder(o, 'Seller cancelled the order')
      return { ok: true }
    }
    throw bad('This order can’t be cancelled now')
  },

  async message(b) {
    const { u, o } = await participantOrder(b)
    if (['pending', 'cancelled'].includes(o.status)) throw bad('Chat opens once the order is paid')
    if ((o.messages || []).length >= 200) throw bad('Message limit reached')
    o.messages = [...(o.messages || []), { from: u.id === o.buyerId ? 'buyer' : 'seller', text: str(b.text, 'Message', 1, 500), at: Date.now() }]
    await put(ORDERS, o)
    return { ok: true }
  },

  // ---- wallet ----
  async stripeConnect(b, req) {
    const u = await authUser(b)
    if (!u.stripeAccount) {
      // Marketplace setup: Vaultix takes the payment and holds it in escrow, then transfers the
      // seller's share. Sellers get Stripe's light Express dashboard.
      const a = await stripe('POST', '/v2/core/accounts', {
        display_name: u.name.slice(0, 100),
        dashboard: 'express',
        defaults: { responsibilities: { fees_collector: 'application', losses_collector: 'application' } },
        configuration: { recipient: { capabilities: { stripe_balance: { stripe_transfers: { requested: true } } } } },
        metadata: { userId: u.id },
      }, `acct2-${u.id}`)
      u.stripeAccount = a.id
      await put(SELLERS, u)
    }
    const site = siteUrl(req)
    const link = await stripe('POST', '/v2/core/account_links', {
      account: u.stripeAccount,
      use_case: { type: 'account_onboarding', account_onboarding: { configurations: ['recipient'], refresh_url: `${site}/#/wallet`, return_url: `${site}/#/wallet` } },
    })
    return { url: link.url }
  },

  async stripeStatus(b) {
    const u = await authUser(b)
    if (!u.stripeAccount) return { ready: false }
    u.stripeReady = await payoutReady(u.stripeAccount)
    await put(SELLERS, u)
    return { ready: u.stripeReady }
  },

  async payout(b) {
    const u = await authUser(b)
    const amount = r2(Number(b.amount))
    if (!(amount >= MIN_PAYOUT)) throw bad(`The minimum withdrawal is $${MIN_PAYOUT}`)
    if (!PAYOUT_METHODS.includes(b.method)) throw bad('Choose a payout method')
    let details = ''
    if (b.method === 'stripe') {
      if (!u.stripeAccount || !u.stripeReady) throw bad('Connect your bank or debit card with Stripe first')
      details = 'Stripe account'
    } else if (b.method === 'paypal') {
      details = str(b.details, 'PayPal email', 5, 120)
      if (!/^[^\s@]+@[^\s@]+\.[^\s@]+$/.test(details)) throw bad('Enter a valid PayPal email')
    } else if (b.method === 'crypto') {
      if (!CRYPTO_NETWORKS.includes(b.network)) throw bad('Choose a coin and network')
      const addr = str(b.details, 'Wallet address', 20, 120)
      if (!/^[A-Za-z0-9:]+$/.test(addr)) throw bad('That wallet address doesn’t look right')
      details = `${b.network}: ${addr}`
    } else {
      details = str(b.details, 'Bank details', 10, 300)
    }
    // Check the balance and save the request as one step (see withLock).
    return withLock(`wallet:${u.id}`, async () => {
      const [orders, payouts, deposits] = await Promise.all([loadOrders(), getAll(PAYOUTS), getAll(DEPOSITS)])
      const w = walletFor(u.id, orders, payouts, deposits)
      if (amount > w.withdrawable) {
        throw bad(w.credit > 0 && amount <= w.available
          ? `You can withdraw up to $${Math.max(w.withdrawable, 0).toFixed(2)}. Added funds can only be spent on Vaultix, not withdrawn.`
          : 'That’s more than your available balance')
      }
      const p = { id: newId('p_'), userId: u.id, amount, method: b.method, details, status: 'requested', createdAt: Date.now() }
      const auto = p.method === 'stripe' && amount <= autoPayoutLeft(u.id, payouts)
      if (auto) p.autoKey = `payout-auto-${p.id}`
      await put(PAYOUTS, p) // saved first: if the transfer call dies, the request still exists
      if (auto) await sendAutoPayout(u, p)
      const { autoKey, autoError, ...view } = p
      return { payout: view }
    })
  },

  // ---- add funds ----
  // The ways to add funds, where to send the money, and my requests.
  async deposits(b) {
    const u = await authUser(b)
    const [set, all] = await Promise.all([depositSettings(), getAll(DEPOSITS)])
    return {
      methods: depositMethods(set), bank: set.bank, crypto: set.crypto, min: MIN_DEPOSIT, max: MAX_DEPOSIT,
      deposits: all.filter((d) => d.userId === u.id).sort((a, c) => c.createdAt - a.createdAt),
    }
  },

  async depositCreate(b) {
    const u = await authUser(b)
    const amount = r2(Number(b.amount))
    if (!(amount >= MIN_DEPOSIT && amount <= MAX_DEPOSIT)) throw bad(`Add between $${MIN_DEPOSIT} and $${MAX_DEPOSIT.toLocaleString('en-US')}`)
    const [set, all] = await Promise.all([depositSettings(), getAll(DEPOSITS)])
    if (!depositMethods(set).includes(b.method)) throw bad('Choose how you’ll send the money')
    if (all.filter((d) => d.userId === u.id && ['waiting', 'sent'].includes(d.status)).length >= MAX_OPEN_DEPOSITS) {
      throw bad('You already have 3 requests waiting. Finish or cancel one first.')
    }
    const crypt = b.method.startsWith('crypto:')
    const d = {
      id: newId('d_'), userId: u.id, amount, method: crypt ? 'crypto' : 'bank', network: crypt ? b.method.slice(7) : null,
      // where to send it, saved with the request so later changes to the settings don't affect it
      sendTo: crypt ? set.crypto[b.method.slice(7)] : set.bank,
      ref: depositRef(), status: 'waiting', createdAt: Date.now(),
    }
    await put(DEPOSITS, d)
    return { deposit: d }
  },

  // "I've sent it", with an optional transaction ID or sender name for staff to match.
  async depositSent(b) {
    const u = await authUser(b)
    const d = await getOne(DEPOSITS, b.depositId)
    if (!d || d.userId !== u.id) throw bad('Request not found', 404)
    if (d.status !== 'waiting') throw bad('This request was already handled')
    d.status = 'sent'; d.sentAt = Date.now()
    d.proof = typeof b.proof === 'string' ? b.proof.trim().slice(0, 200) : ''
    await put(DEPOSITS, d)
    return { deposit: d }
  },

  async depositCancel(b) {
    const u = await authUser(b)
    const d = await getOne(DEPOSITS, b.depositId)
    if (!d || d.userId !== u.id) throw bad('Request not found', 404)
    if (!['waiting', 'sent'].includes(d.status)) throw bad('This request was already handled')
    d.status = 'cancelled'; d.cancelledAt = Date.now()
    await put(DEPOSITS, d)
    return { deposit: d }
  },

  // ---- admin ----
  async adminSellers(b) {
    await authAdmin(b)
    const [users, listings, orders, payouts, deposits] = await Promise.all([getAll(SELLERS), getAll(LISTINGS), loadOrders(), getAll(PAYOUTS), getAll(DEPOSITS)])
    return {
      sellers: users
        .map((s) => ({
          ...publicUser(s, orders), contact: s.contact, email: s.email || '', hasPassword: !!s.pw,
          listings: listings.filter((l) => l.sellerId === s.id && (l.stock ?? 1) > 0).length,
          balance: walletFor(s.id, orders, payouts, deposits).available,
        }))
        .sort((a, c) => c.createdAt - a.createdAt),
    }
  },

  async verify(b) {
    await authAdmin(b)
    const s = await getOne(SELLERS, b.sellerId)
    if (!s) throw bad('Seller not found', 404)
    if (s.owner && !b.verified) throw bad('Owners are always verified')
    s.verified = !!b.verified
    s.verifiedAt = s.verified ? s.verifiedAt || Date.now() : null
    await put(SELLERS, s)
    return { seller: publicUser(s) }
  },

  async banSeller(b) {
    await authAdmin(b)
    const id = String(b.sellerId || '')
    const target = await getOne(SELLERS, id)
    if (target && target.owner) throw bad("Owners can't be banned")
    const orders = await loadOrders()
    if (orders.some((o) => (o.sellerId === id || o.buyerId === id) && ['paid', 'delivered', 'disputed'].includes(o.status))) {
      throw bad('This user has open orders. Refund or release them first.')
    }
    const listings = (await getAll(LISTINGS)).filter((l) => l.sellerId === id)
    for (const l of listings) { l.stock = 0; l.removed = true; await put(LISTINGS, l); await redis(['DEL', credsKey(l.id)]) }
    await redis(['HDEL', SELLERS, id])
    return { ok: true, removedListings: listings.length }
  },

  // ---- staff: review listings ----
  async adminListings(b) {
    await authAdmin(b)
    const [listings, users] = await Promise.all([getAll(LISTINGS), getAll(SELLERS)])
    return {
      listings: listings
        .filter((l) => (l.stock ?? 1) > 0)
        .map((l) => ({ ...l, stock: l.stock ?? 1, seller: publicUser(users.find((u) => u.id === l.sellerId)) }))
        .sort((a, c) => Number(!!a.checked) - Number(!!c.checked) || c.createdAt - a.createdAt),
    }
  },

  // Decrypt the logins still waiting to be sold, so staff can try them.
  // Each comes with a ref (its stored form) used to remove that exact login.
  async adminLogins(b) {
    const staff = await authAdmin(b)
    const l = await getOne(LISTINGS, b.listingId)
    if (!l) throw bad('Listing not found', 404)
    const raw = (await redis(['LRANGE', credsKey(l.id), '0', '-1'])) || []
    l.lastReviewedAt = Date.now(); l.lastReviewedBy = staff ? staff.name : 'staff'
    await put(LISTINGS, l)
    return { logins: raw.map((ref) => ({ ref, ...(decrypt(ref) || { error: 'Could not read this login' }) })) }
  },

  async adminRemoveLogin(b) {
    await authAdmin(b)
    const l = await getOne(LISTINGS, b.listingId)
    if (!l) throw bad('Listing not found', 404)
    const removed = Number(await redis(['LREM', credsKey(l.id), '1', String(b.ref || '')])) || 0
    if (!removed) throw bad('That login was already sold or removed')
    l.stock = Number(await redis(['LLEN', credsKey(l.id)])) || 0
    await put(LISTINGS, l)
    return { ok: true, stock: l.stock }
  },

  async adminCheck(b) {
    const staff = await authAdmin(b)
    const l = await getOne(LISTINGS, b.listingId)
    if (!l) throw bad('Listing not found', 404)
    l.checked = !!b.checked
    l.checkedAt = l.checked ? Date.now() : null
    l.checkedBy = l.checked ? (staff ? staff.name : 'staff') : null
    await put(LISTINGS, l)
    return { ok: true }
  },

  async adminRemove(b) {
    await authAdmin(b)
    const l = await getOne(LISTINGS, b.listingId)
    if (l) { l.stock = 0; l.removed = true; await put(LISTINGS, l); await redis(['DEL', credsKey(l.id)]) }
    return { ok: true }
  },

  // Forgot password without email (no RESEND_API_KEY, or an old account with no email): staff set a
  // temporary password and give it to the user, after checking it's really them.
  async adminResetPassword(b) {
    await authAdmin(b)
    const u = await getOne(SELLERS, b.sellerId)
    if (!u) throw bad('User not found', 404)
    const temp = crypto.randomBytes(9).toString('base64').replace(/[^A-Za-z0-9]/g, 'x')
    u.pw = hashPassword(temp); u.tokens = []; delete u.tokenHash; delete u.reset; u.fails = 0; u.lockUntil = 0
    await put(SELLERS, u)
    return { tempPassword: temp }
  },

  async adminOrders(b) {
    await authAdmin(b)
    const [orders, users] = await Promise.all([loadOrders(), getAll(SELLERS)])
    return { orders: orders.sort((a, c) => c.createdAt - a.createdAt).map((o) => orderView(o, users, null)) }
  },

  // Settle an order: refund the buyer, or release the money to the seller.
  async resolve(b) {
    await authAdmin(b)
    const o = (await loadOrders()).find((x) => x.id === b.orderId)
    if (!o || !['paid', 'delivered', 'disputed'].includes(o.status)) throw bad('Only open orders can be settled')
    if (b.decision === 'refund') {
      if (o.deliveredAt) throw bad('All sales are final: this order was delivered, so it can’t be refunded')
      await refundOrder(o, String(b.note || 'Refunded by staff').slice(0, 200))
    }
    else if (b.decision === 'release') { o.status = 'completed'; o.completedAt = Date.now(); o.releasedByStaff = true; await put(ORDERS, o) }
    else throw bad('Choose refund or release')
    return { ok: true }
  },

  async adminPayouts(b) {
    await authAdmin(b)
    const [payouts, users] = await Promise.all([getAll(PAYOUTS), getAll(SELLERS)])
    return {
      payouts: payouts.sort((a, c) => c.createdAt - a.createdAt)
        .map((p) => ({ ...p, user: (users.find((u) => u.id === p.userId) || {}).name || '(deleted)' })),
    }
  },

  // Add-funds requests, and where people send the money.
  async adminDeposits(b) {
    await authAdmin(b)
    const [deposits, users, set] = await Promise.all([getAll(DEPOSITS), getAll(SELLERS), depositSettings()])
    const order = { sent: 0, waiting: 1 }
    return {
      settings: set,
      deposits: deposits
        .sort((a, c) => (order[a.status] ?? 2) - (order[c.status] ?? 2) || c.createdAt - a.createdAt)
        .map((d) => ({ ...d, user: (users.find((u) => u.id === d.userId) || {}).name || '(deleted)' })),
    }
  },

  // Credit the amount that actually arrived (it can differ from what they asked for), or reject.
  async depositDecision(b) {
    const staff = await authAdmin(b)
    // One decision per request, even if staff click twice at once (see withLock).
    return withLock(`deposit:${b.depositId}`, async () => {
      const d = await getOne(DEPOSITS, b.depositId)
      if (!d || !['waiting', 'sent'].includes(d.status)) throw bad('This request was already handled')
      if (b.decision === 'credit') {
        const amount = r2(Number(b.amount ?? d.amount))
        if (!(amount > 0 && amount <= MAX_DEPOSIT * 2)) throw bad('Enter the amount that arrived')
        d.status = 'credited'; d.credited = amount
      } else if (b.decision === 'reject') {
        d.status = 'rejected'
      } else throw bad('Choose credit or reject')
      d.note = String(b.note || '').slice(0, 200)
      d.decidedAt = Date.now(); d.decidedBy = staff ? staff.name : 'staff'
      await put(DEPOSITS, d)
      return { deposit: d }
    })
  },

  async adminSetDeposit(b) {
    await authAdmin(b)
    const bank = typeof b.bank === 'string' ? b.bank.trim().slice(0, 400) : ''
    const cryptoIn = (b.crypto && typeof b.crypto === 'object') ? b.crypto : {}
    const out = {}
    for (const n of CRYPTO_NETWORKS) {
      const a = typeof cryptoIn[n] === 'string' ? cryptoIn[n].trim() : ''
      if (!a) continue
      if (a.length < 20 || a.length > 120 || !/^[A-Za-z0-9:]+$/.test(a)) throw bad(`The ${n} address doesn’t look right`)
      out[n] = a
    }
    await redis(['HSET', SETTINGS, 'deposit', JSON.stringify({ bank, crypto: out })])
    return { settings: { bank, crypto: out } }
  },

  // Approve (pay) or reject a withdrawal. Stripe payouts are transferred automatically;
  // PayPal / crypto / bank are sent by staff, then marked paid here.
  async payoutDecision(b) {
    await authAdmin(b)
    const p = await getOne(PAYOUTS, b.payoutId)
    if (!p || p.status !== 'requested') throw bad('This payout was already handled')
    if (b.decision === 'reject') {
      p.status = 'rejected'; p.note = String(b.note || '').slice(0, 200)
    } else if (b.decision === 'paid') {
      if (p.method === 'stripe') {
        const u = await getOne(SELLERS, p.userId)
        if (!u || !u.stripeAccount) throw bad('User has no Stripe account')
        if (!(await payoutReady(u.stripeAccount))) throw bad('This seller has not finished Stripe setup yet, so Stripe can not pay them')
        // Same key as an unfinished automatic attempt, so Stripe never pays the same withdrawal twice.
        const t = await stripe('POST', '/transfers', { amount: cents(p.amount), currency: 'usd', destination: u.stripeAccount, metadata: { payoutId: p.id } }, p.autoKey || `payout-${p.id}`)
        p.transferId = t.id; delete p.autoKey
      }
      p.status = 'paid'; p.note = String(b.note || '').slice(0, 200)
    } else throw bad('Choose paid or reject')
    p.processedAt = Date.now()
    await put(PAYOUTS, p)
    return { payout: p }
  },
}

const GET_ACTIONS = ['list', 'icons', 'image', 'profile']

async function handler(req, res) {
  res.setHeader('Cache-Control', 'no-store')
  try {
    const body = req.method === 'POST' ? (typeof req.body === 'string' ? JSON.parse(req.body || '{}') : req.body || {}) : {}
    const q = req.query || {}
    const action = req.method === 'GET' ? q.action || 'list' : body.action
    if (req.method === 'GET' && !GET_ACTIONS.includes(action)) throw bad('Use POST', 405)

    if (req.method === 'GET' && action === 'icons') {
      res.setHeader('Cache-Control', 'public, max-age=3600, s-maxage=21600, stale-while-revalidate=86400')
      return res.status(200).json({ icons: await loadIcons() })
    }
    if (req.method === 'GET' && action === 'image') {
      const raw = await redis(['HGET', IMAGES, String(q.id || '')])
      if (!raw) throw bad('Not found', 404)
      const img = JSON.parse(raw)
      res.setHeader('Content-Type', img.type)
      res.setHeader('X-Content-Type-Options', 'nosniff')
      res.setHeader('Content-Security-Policy', "default-src 'none'")
      res.setHeader('Cache-Control', 'public, max-age=31536000, immutable') // listing images never change
      res.statusCode = 200
      return res.end(Buffer.from(img.data, 'base64'))
    }
    if (req.method === 'GET' && action === 'profile') return res.status(200).json(await actions.profile({ id: q.id }))

    if (req.method !== 'GET' && req.method !== 'POST') throw bad('Method not allowed', 405)
    const fn = Object.prototype.hasOwnProperty.call(actions, action) && actions[action]
    if (!fn) throw bad('Unknown action', 404)
    res.status(200).json(await fn(body, req))
  } catch (e) {
    if (!e.status) console.error(e)
    res.status(e.status || 500).json({ error: e.status ? e.message : 'Server error' })
  }
}

module.exports = handler
// Used by api/stripe-webhook.js
module.exports.internal = { markPaid, markExpired, markSavedCardFailed, onStripeAccount }
