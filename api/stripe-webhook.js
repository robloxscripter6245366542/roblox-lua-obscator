// ============================================================================
//  Stripe webhook for Vaultix Market.
//  In the Stripe dashboard add an endpoint https://<your-site>/api/stripe-webhook with events:
//    checkout.session.completed, checkout.session.async_payment_succeeded,
//    checkout.session.async_payment_failed, checkout.session.expired, account.updated,
//    payment_intent.succeeded, payment_intent.payment_failed
//  and put its signing secret in STRIPE_WEBHOOK_SECRET.
//  Every request is checked against that secret, so nobody can fake a "paid" event.
// ============================================================================
const crypto = require('crypto')
const { internal } = require('./market.js')

const TOLERANCE_S = 5 * 60

function readRaw(req) {
  // Read the untouched body: the signature is computed over the exact bytes Stripe sent.
  if (Buffer.isBuffer(req.rawBody)) return Promise.resolve(req.rawBody.toString('utf8'))
  return new Promise((resolve, reject) => {
    const chunks = []
    req.on('data', (c) => chunks.push(c))
    req.on('end', () => resolve(Buffer.concat(chunks).toString('utf8')))
    req.on('error', reject)
  })
}

function verify(raw, header, secret) {
  const parts = Object.fromEntries(String(header || '').split(',').map((kv) => kv.split('=')).filter((x) => x.length === 2).map(([k, v]) => [k, v]))
  const sigs = String(header || '').split(',').filter((kv) => kv.startsWith('v1=')).map((kv) => kv.slice(3))
  const t = Number(parts.t)
  if (!t || !sigs.length) return false
  if (Math.abs(Date.now() / 1000 - t) > TOLERANCE_S) return false
  const expected = Buffer.from(crypto.createHmac('sha256', secret).update(`${t}.${raw}`).digest('hex'))
  return sigs.some((s) => {
    const b = Buffer.from(s)
    return b.length === expected.length && crypto.timingSafeEqual(b, expected)
  })
}

async function handler(req, res) {
  const send = (code, obj) => { res.statusCode = code; res.setHeader('Content-Type', 'application/json'); res.end(JSON.stringify(obj)) }
  if (req.method !== 'POST') return send(405, { error: 'POST only' })
  const secret = process.env.STRIPE_WEBHOOK_SECRET
  if (!secret) return send(503, { error: 'STRIPE_WEBHOOK_SECRET not set' })
  const raw = await readRaw(req)
  if (!verify(raw, req.headers['stripe-signature'], secret)) return send(400, { error: 'Bad signature' })

  let evt
  try { evt = JSON.parse(raw) } catch { return send(400, { error: 'Bad JSON' }) }
  const obj = (evt.data && evt.data.object) || {}
  const orderId = (obj.metadata && obj.metadata.orderId) || obj.client_reference_id
  try {
    switch (evt.type) {
      case 'checkout.session.completed':
      case 'checkout.session.async_payment_succeeded':
        // Card payments are "paid" right away; some methods (e.g. crypto) confirm later.
        if (obj.payment_status === 'paid' && orderId) await internal.markPaid(orderId, obj.payment_intent)
        break
      case 'checkout.session.async_payment_failed':
      case 'checkout.session.expired':
        if (orderId) await internal.markExpired(orderId)
        break
      // One-click payments with a saved card (Checkout payments also send this; markPaid ignores repeats).
      case 'payment_intent.succeeded':
        if (orderId) await internal.markPaid(orderId, obj.id)
        break
      case 'payment_intent.payment_failed':
        // Only one-click saved-card orders: on Stripe's checkout page the buyer can still retry.
        if (orderId) await internal.markSavedCardFailed(orderId)
        break
      case 'account.updated':
        await internal.onStripeAccount(obj.id, obj.payouts_enabled)
        break
      default:
        break
    }
  } catch (e) {
    console.error('stripe webhook', e)
    return send(500, { error: 'Handler failed' }) // Stripe retries
  }
  return send(200, { received: true })
}

module.exports = handler
// Vercel: don't parse the body, we need the raw bytes for the signature check.
module.exports.config = { api: { bodyParser: false } }
