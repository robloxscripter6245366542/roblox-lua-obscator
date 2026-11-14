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
//   UPSTASH_REDIS_REST_URL / UPSTASH_REDIS_REST_TOKEN   storage (required)
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
//   MARKET_FEE_PCT / MARKET_FEE_FIXED                   buyer payment fee (default 3% + $0.30)
//   MARKET_COMMISSION_PCT                               cut taken from sellers (default 5%)
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
const MAX_LOGINS = 50
const credsKey = (listingId) => `mkt:creds:${listingId}`
const OWNER_NAMES = String(process.env.MARKET_OWNERS ?? 'Kaitrades').split(',').map((n) => n.trim().toLowerCase()).filter(Boolean)
const isOwnerName = (name) => OWNER_NAMES.includes(String(name || '').toLowerCase())

/* ------------------------------ storage ------------------------------ */
async function redis(cmd) {
  const base = process.env.UPSTASH_REDIS_REST_URL
  const tok = process.env.UPSTASH_REDIS_REST_TOKEN
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
async function stripe(method, path, params, idempotencyKey) {
  const key = process.env.STRIPE_SECRET_KEY
  if (!key) throw bad('Card payments are not set up yet (STRIPE_SECRET_KEY missing)', 503)
  const headers = { Authorization: `Bearer ${key}` }
  let body
  if (params) {
    headers['Content-Type'] = 'application/x-www-form-urlencoded'
    body = new URLSearchParams(formEncode(params)).toString()
  }
  if (idempotencyKey) headers['Idempotency-Key'] = idempotencyKey
  const r = await fetch(`https://api.stripe.com/v1${path}`, { method, headers, body })
  const j = await r.json().catch(() => ({}))
  if (!r.ok) throw bad((j.error && j.error.message) || 'Payment provider error', 502)
  return j
}

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
async function authUser(body) {
  const u = await getOne(SELLERS, body.sellerId)
  if (!u || !body.token || sha(body.token) !== u.tokenHash) throw bad('Please sign in again', 401)
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
    if (u && u.owner && sha(body.ownerToken) === u.tokenHash) return u
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
function walletFor(userId, orders, payouts) {
  const sold = orders.filter((o) => o.sellerId === userId)
  const earned = sum(sold.filter((o) => o.status === 'completed').map((o) => o.sellerNet))
  const pending = sum(sold.filter((o) => ['paid', 'delivered', 'disputed'].includes(o.status)).map((o) => o.sellerNet))
  const spent = sum(orders.filter((o) => o.buyerId === userId && o.method === 'balance' && !['refunded', 'cancelled'].includes(o.status)).map((o) => o.total))
  const mine = payouts.filter((p) => p.userId === userId)
  const withdrawn = sum(mine.filter((p) => p.status === 'paid').map((p) => p.amount))
  const requested = sum(mine.filter((p) => p.status === 'requested').map((p) => p.amount))
  return { available: r2(earned - spent - withdrawn - requested), pending, earned, spent, withdrawn, requested }
}
async function changeStock(listingId, delta) {
  const l = await getOne(LISTINGS, listingId)
  if (!l) return null
  l.stock = Math.max(0, (l.stock ?? 1) + delta)
  l.sold = Math.max(0, (l.sold || 0) - delta)
  await put(LISTINGS, l)
  return l
}
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
  const l = await getOne(LISTINGS, o.listingId)
  o.paidAt = Date.now()
  const soldOut = async () => { o.status = 'paid'; o.stockTaken = false; await refundOrder(o, 'Sold out before your payment finished'); return o }
  if (!l || (l.stock ?? 1) < 1) return soldOut()
  if (l.delivery === 'instant') {
    if (!(await autoDeliver(o, l))) return soldOut()
    o.stockTaken = true
  } else {
    await changeStock(o.listingId, -1)
    o.stockTaken = true
    o.status = 'paid'
  }
  await put(ORDERS, o)
  return o
}
// Called by the Stripe webhook when a checkout is paid.
async function markPaid(orderId, paymentIntent) {
  const o = await getOne(ORDERS, orderId)
  if (!o || o.status !== 'pending') return o
  o.paymentIntent = paymentIntent || o.paymentIntent
  return fulfil(o)
}
async function markExpired(orderId) {
  const o = await getOne(ORDERS, orderId)
  if (o && o.status === 'pending') { o.status = 'cancelled'; o.cancelledAt = Date.now(); await put(ORDERS, o) }
}
async function onStripeAccount(accountId, payoutsEnabled) {
  const u = (await getAll(SELLERS)).find((x) => x.stripeAccount === accountId)
  if (u) { u.stripeReady = !!payoutsEnabled; await put(SELLERS, u) }
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
    return { listings: await listPublic(), fees: { pct: FEE_PCT, fixed: FEE_FIXED, commission: COMMISSION_PCT }, owners: OWNER_NAMES }
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
    const users = await getAll(SELLERS)
    if (users.some((s) => s.name.toLowerCase() === name.toLowerCase())) throw bad('That name is taken', 409)
    // Owner usernames are reserved: claiming one needs the staff password.
    const owner = isOwnerName(name)
    if (owner && !adminKeyOk(b.adminKey)) throw bad('This username is reserved for the site owner. Enter the staff password to claim it.', 403)
    const token = crypto.randomBytes(24).toString('hex')
    const now = Date.now()
    const u = { id: newId('s_'), name, contact, bio: '', verified: owner, verifiedAt: owner ? now : null, owner, createdAt: now, tokenHash: sha(token) }
    await put(SELLERS, u)
    return { seller: publicUser(u), token }
  },

  async me(b) {
    const u = await authUser(b)
    const [orders, payouts] = await Promise.all([loadOrders(), getAll(PAYOUTS)])
    return {
      seller: { ...publicUser(u, orders), contact: u.contact, stripeConnected: !!u.stripeAccount, stripeReady: !!u.stripeReady },
      wallet: walletFor(u.id, orders, payouts),
      payouts: payouts.filter((p) => p.userId === u.id).sort((a, c) => c.createdAt - a.createdAt),
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
    const method = ['card', 'crypto', 'balance'].includes(b.method) ? b.method : 'card'
    const money = feesFor(l.price, method)
    const order = {
      id: newId('o_'), listingId: l.id, buyerId: u.id, sellerId: l.sellerId,
      title: l.title, game: l.game, category: l.category, hasImage: !!l.hasImage,
      ...money, method, status: 'pending', createdAt: Date.now(), messages: [],
    }
    if (method === 'balance') {
      const [orders, payouts] = await Promise.all([loadOrders(), getAll(PAYOUTS)])
      if (walletFor(u.id, orders, payouts).available < money.total) throw bad('Not enough balance')
      await fulfil(order)
      return { orderId: order.id }
    }
    const site = siteUrl(req)
    const session = await stripe('POST', '/checkout/sessions', {
      mode: 'payment',
      client_reference_id: order.id,
      success_url: `${site}/#/order/${order.id}`,
      cancel_url: `${site}/#/checkout/${l.id}`,
      payment_method_types: [method === 'crypto' ? 'crypto' : 'card'],
      line_items: [
        { quantity: 1, price_data: { currency: 'usd', unit_amount: cents(money.price), product_data: { name: `${l.game} · ${l.title}`.slice(0, 200) } } },
        { quantity: 1, price_data: { currency: 'usd', unit_amount: cents(money.fee), product_data: { name: 'Payment fee' } } },
      ],
      metadata: { orderId: order.id },
      payment_intent_data: method === 'crypto' ? undefined : { metadata: { orderId: order.id } },
      expires_at: Math.floor(Date.now() / 1000) + 31 * 60,
    }, `checkout-${order.id}`)
    order.stripeSession = session.id
    await put(ORDERS, order)
    return { orderId: order.id, url: session.url }
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
    if (!['paid', 'delivered'].includes(o.status)) throw bad('This order can’t be disputed now')
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
      const a = await stripe('POST', '/accounts', { type: 'express', capabilities: { transfers: { requested: true } }, metadata: { userId: u.id } }, `acct-${u.id}`)
      u.stripeAccount = a.id
      await put(SELLERS, u)
    }
    const site = siteUrl(req)
    const link = await stripe('POST', '/account_links', {
      account: u.stripeAccount, type: 'account_onboarding',
      refresh_url: `${site}/#/wallet`, return_url: `${site}/#/wallet`,
    })
    return { url: link.url }
  },

  async stripeStatus(b) {
    const u = await authUser(b)
    if (!u.stripeAccount) return { ready: false }
    const a = await stripe('GET', `/accounts/${u.stripeAccount}`)
    u.stripeReady = !!a.payouts_enabled
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
    const [orders, payouts] = await Promise.all([loadOrders(), getAll(PAYOUTS)])
    if (amount > walletFor(u.id, orders, payouts).available) throw bad('That’s more than your available balance')
    const p = { id: newId('p_'), userId: u.id, amount, method: b.method, details, status: 'requested', createdAt: Date.now() }
    await put(PAYOUTS, p)
    return { payout: p }
  },

  // ---- admin ----
  async adminSellers(b) {
    await authAdmin(b)
    const [users, listings, orders, payouts] = await Promise.all([getAll(SELLERS), getAll(LISTINGS), loadOrders(), getAll(PAYOUTS)])
    return {
      sellers: users
        .map((s) => ({
          ...publicUser(s, orders), contact: s.contact,
          listings: listings.filter((l) => l.sellerId === s.id && (l.stock ?? 1) > 0).length,
          balance: walletFor(s.id, orders, payouts).available,
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
    if (b.decision === 'refund') await refundOrder(o, String(b.note || 'Refunded by staff').slice(0, 200))
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
        const t = await stripe('POST', '/transfers', { amount: cents(p.amount), currency: 'usd', destination: u.stripeAccount, metadata: { payoutId: p.id } }, `payout-${p.id}`)
        p.transferId = t.id
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
module.exports.internal = { markPaid, markExpired, onStripeAccount }
