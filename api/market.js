// ============================================================================
//  Vaultix marketplace API ("market")
//  One endpoint, action picked by ?action= (GET) or body.action (POST).
//
//  Trust model
//   - Anyone can register as a seller. They get a secret token back (stored in
//     their browser). Only the token holder can post or delete their listings,
//     so nobody can post as someone else.
//   - Every seller starts UNVERIFIED -> their listings show as "Risky".
//   - Only the site owner, holding MARKET_ADMIN_KEY, can mark a seller verified.
//
//  Env vars (Vercel):
//   UPSTASH_REDIS_REST_URL / UPSTASH_REDIS_REST_TOKEN   storage (required)
//   MARKET_ADMIN_KEY                                    admin password (required for admin)
// ============================================================================
const crypto = require('crypto')

const SELLERS = 'mkt:sellers'
const LISTINGS = 'mkt:listings'
const CATEGORIES = ['Accounts', 'Keys', 'Items', 'Services', 'Other']
const MAX_LISTINGS_PER_SELLER = 50

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
  const v = await redis(['HGET', key, id])
  return v ? JSON.parse(v) : null
}
const put = (key, obj) => redis(['HSET', key, obj.id, JSON.stringify(obj)])

const sha = (s) => crypto.createHash('sha256').update(String(s)).digest('hex')
const newId = (p) => p + crypto.randomBytes(6).toString('hex')
function safeEq(a, b) {
  const x = Buffer.from(sha(a)), y = Buffer.from(sha(b))
  return crypto.timingSafeEqual(x, y)
}
function bad(msg, status = 400) { return Object.assign(new Error(msg), { status }) }
function str(v, name, min, max) {
  const s = typeof v === 'string' ? v.trim() : ''
  if (s.length < min || s.length > max) throw bad(`${name} must be ${min}-${max} characters`)
  return s
}

// What the public sees about a seller (no contact hash, no token)
function publicSeller(s) {
  return s && { id: s.id, name: s.name, contact: s.contact, verified: !!s.verified, createdAt: s.createdAt }
}

async function authSeller(body) {
  const s = await getOne(SELLERS, String(body.sellerId || ''))
  if (!s || !body.token || sha(body.token) !== s.tokenHash) throw bad('Not signed in as this seller', 401)
  return s
}
function authAdmin(body) {
  const key = process.env.MARKET_ADMIN_KEY
  if (!key) throw bad('MARKET_ADMIN_KEY is not set on the server', 503)
  if (!body.adminKey || !safeEq(body.adminKey, key)) throw bad('Wrong admin key', 401)
}

async function listPublic() {
  const [sellers, listings] = await Promise.all([getAll(SELLERS), getAll(LISTINGS)])
  const byId = Object.fromEntries(sellers.map((s) => [s.id, s]))
  return listings
    .filter((l) => byId[l.sellerId])
    .map((l) => ({ ...l, seller: publicSeller(byId[l.sellerId]) }))
    .sort((a, b) => b.createdAt - a.createdAt)
}

const actions = {
  async list() {
    return { listings: await listPublic() }
  },

  async register(b) {
    const name = str(b.name, 'Name', 3, 24)
    if (!/^[A-Za-z0-9_.-]+$/.test(name)) throw bad('Name can only use letters, numbers, _ . -')
    const contact = str(b.contact, 'Contact', 3, 80)
    const sellers = await getAll(SELLERS)
    if (sellers.some((s) => s.name.toLowerCase() === name.toLowerCase())) throw bad('That name is taken', 409)
    const token = crypto.randomBytes(24).toString('hex')
    const seller = { id: newId('s_'), name, contact, verified: false, createdAt: Date.now(), tokenHash: sha(token) }
    await put(SELLERS, seller)
    return { seller: publicSeller(seller), token }
  },

  async me(b) {
    return { seller: publicSeller(await authSeller(b)) }
  },

  async post(b) {
    const s = await authSeller(b)
    const mine = (await getAll(LISTINGS)).filter((l) => l.sellerId === s.id)
    if (mine.length >= MAX_LISTINGS_PER_SELLER) throw bad('Listing limit reached')
    const price = Math.round(Number(b.price) * 100) / 100
    if (!(price > 0 && price <= 10000)) throw bad('Price must be between 0.01 and 10000')
    const category = CATEGORIES.includes(b.category) ? b.category : 'Other'
    const listing = {
      id: newId('l_'),
      sellerId: s.id,
      title: str(b.title, 'Title', 3, 70),
      description: str(b.description, 'Description', 10, 1000),
      price,
      category,
      createdAt: Date.now(),
    }
    await put(LISTINGS, listing)
    return { listing: { ...listing, seller: publicSeller(s) } }
  },

  async remove(b) {
    const s = await authSeller(b)
    const l = await getOne(LISTINGS, String(b.listingId || ''))
    if (!l || l.sellerId !== s.id) throw bad('Listing not found', 404)
    await redis(['HDEL', LISTINGS, l.id])
    return { ok: true }
  },

  // ---- admin ----
  async adminSellers(b) {
    authAdmin(b)
    const [sellers, listings] = await Promise.all([getAll(SELLERS), getAll(LISTINGS)])
    return {
      sellers: sellers
        .map((s) => ({ ...publicSeller(s), listings: listings.filter((l) => l.sellerId === s.id).length }))
        .sort((a, b) => b.createdAt - a.createdAt),
    }
  },

  async verify(b) {
    authAdmin(b)
    const s = await getOne(SELLERS, String(b.sellerId || ''))
    if (!s) throw bad('Seller not found', 404)
    s.verified = !!b.verified
    await put(SELLERS, s)
    return { seller: publicSeller(s) }
  },

  async banSeller(b) {
    authAdmin(b)
    const id = String(b.sellerId || '')
    const listings = (await getAll(LISTINGS)).filter((l) => l.sellerId === id)
    for (const l of listings) await redis(['HDEL', LISTINGS, l.id])
    await redis(['HDEL', SELLERS, id])
    return { ok: true, removedListings: listings.length }
  },

  async adminRemove(b) {
    authAdmin(b)
    await redis(['HDEL', LISTINGS, String(b.listingId || '')])
    return { ok: true }
  },
}

module.exports = async function handler(req, res) {
  res.setHeader('Cache-Control', 'no-store')
  try {
    const body = req.method === 'POST' ? (typeof req.body === 'string' ? JSON.parse(req.body || '{}') : req.body || {}) : {}
    const action = req.method === 'GET' ? (req.query && req.query.action) || 'list' : body.action
    if (req.method === 'GET' && action !== 'list') throw bad('Use POST', 405)
    if (req.method !== 'GET' && req.method !== 'POST') throw bad('Method not allowed', 405)
    const fn = Object.prototype.hasOwnProperty.call(actions, action) && actions[action]
    if (!fn) throw bad('Unknown action', 404)
    res.status(200).json(await fn(body))
  } catch (e) {
    res.status(e.status || 500).json({ error: e.status ? e.message : 'Server error' })
  }
}
