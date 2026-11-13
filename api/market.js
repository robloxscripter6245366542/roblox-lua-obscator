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
//
//  Images
//   - Games in shop-site/games.js use their official icon (?action=icons, looked up live and
//     cached, because Roblox icon URLs expire).
//   - Any other game is "Other": the seller must upload their own picture (JPEG/PNG/WebP, max
//     ~200 KB, already resized in the browser). It is served from ?action=image&id=<listingId>.
// ============================================================================
const crypto = require('crypto')
const { GAMES, find: findGame, steamIcon } = require('../shop-site/games.js')

const SELLERS = 'mkt:sellers'
const LISTINGS = 'mkt:listings'
const IMAGES = 'mkt:images'
const MAX_IMAGE_BYTES = 200 * 1024
const ICON_TTL_MS = 6 * 60 * 60 * 1000
const CATEGORIES = ['Currency', 'Accounts', 'Top ups', 'Items', 'Boosting', 'Gift cards']
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
  // Only cache a complete-ish answer, so a temporary outage is retried on the next request.
  if (Object.keys(icons).length >= GAMES.length * 0.8) iconCache = { at: Date.now(), icons }
  return icons
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
    if (!CATEGORIES.includes(b.category)) throw bad('Pick a category')
    const was = Math.round(Number(b.wasPrice) * 100) / 100
    const known = findGame(b.game)
    // Listed games use their official icon; any other game needs the seller's own picture.
    const image = known ? null : b.image ? parseImage(b.image) : null
    if (!known && !image) throw bad('Add a picture for games that are not in the list')
    const listing = {
      id: newId('l_'),
      sellerId: s.id,
      game: known ? known.name : str(b.game, 'Game', 2, 30),
      hasImage: !!image,
      title: str(b.title, 'Title', 3, 70),
      description: str(b.description, 'Description', 10, 1000),
      price,
      wasPrice: was > price && was <= 100000 ? was : null,
      category: b.category,
      createdAt: Date.now(),
    }
    if (image) await redis(['HSET', IMAGES, listing.id, JSON.stringify(image)])
    await put(LISTINGS, listing)
    return { listing: { ...listing, seller: publicSeller(s) } }
  },

  async remove(b) {
    const s = await authSeller(b)
    const l = await getOne(LISTINGS, String(b.listingId || ''))
    if (!l || l.sellerId !== s.id) throw bad('Listing not found', 404)
    await redis(['HDEL', LISTINGS, l.id])
    await redis(['HDEL', IMAGES, l.id])
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
    for (const l of listings) {
      await redis(['HDEL', LISTINGS, l.id])
      await redis(['HDEL', IMAGES, l.id])
    }
    await redis(['HDEL', SELLERS, id])
    return { ok: true, removedListings: listings.length }
  },

  async adminRemove(b) {
    authAdmin(b)
    await redis(['HDEL', LISTINGS, String(b.listingId || '')])
    await redis(['HDEL', IMAGES, String(b.listingId || '')])
    return { ok: true }
  },
}

const GET_ACTIONS = ['list', 'icons', 'image']

module.exports = async function handler(req, res) {
  res.setHeader('Cache-Control', 'no-store')
  try {
    const body = req.method === 'POST' ? (typeof req.body === 'string' ? JSON.parse(req.body || '{}') : req.body || {}) : {}
    const action = req.method === 'GET' ? (req.query && req.query.action) || 'list' : body.action
    if (req.method === 'GET' && !GET_ACTIONS.includes(action)) throw bad('Use POST', 405)

    if (req.method === 'GET' && action === 'icons') {
      res.setHeader('Cache-Control', 'public, max-age=3600, s-maxage=21600, stale-while-revalidate=86400')
      return res.status(200).json({ icons: await loadIcons() })
    }
    if (req.method === 'GET' && action === 'image') {
      const raw = await redis(['HGET', IMAGES, String((req.query && req.query.id) || '')])
      if (!raw) throw bad('Not found', 404)
      const img = JSON.parse(raw)
      res.setHeader('Content-Type', img.type)
      res.setHeader('X-Content-Type-Options', 'nosniff')
      res.setHeader('Content-Security-Policy', "default-src 'none'")
      res.setHeader('Cache-Control', 'public, max-age=31536000, immutable') // listing images never change
      res.statusCode = 200
      return res.end(Buffer.from(img.data, 'base64'))
    }

    if (req.method !== 'GET' && req.method !== 'POST') throw bad('Method not allowed', 405)
    const fn = Object.prototype.hasOwnProperty.call(actions, action) && actions[action]
    if (!fn) throw bad('Unknown action', 404)
    res.status(200).json(await fn(body))
  } catch (e) {
    res.status(e.status || 500).json({ error: e.status ? e.message : 'Server error' })
  }
}
