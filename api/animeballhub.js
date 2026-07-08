// ============================================================================
//  Anime Ball Hub — authenticator ("animeballhub")
//  POST { key, hwid }  ->  200 with the protected Lua script, or 4xx on reject.
//
//  Protection model: per-user KEY + HWID lock.
//   - Valid keys live in the ANIMEBALL_KEYS env var (JSON) - never in the repo.
//   - Each key can be locked to one device (HWID). A leaked key is useless on
//     any other machine.
//   - The real (obfuscated) script is fetched from a PRIVATE source
//     (PROTECTED_SCRIPT_URL, optionally with PROTECTED_SCRIPT_TOKEN) only after
//     auth passes, so it never sits at a public URL.
//   - Optional auto-bind: if Upstash Redis REST env vars are set, an unlocked
//     key binds to the first HWID that uses it (true "lock on first use"),
//     dependency-free. Without Upstash it falls back to the static lock in
//     ANIMEBALL_KEYS.
//
//  Env vars to set on Vercel:
//   ANIMEBALL_KEYS          JSON, e.g. {"ABC-123":{"hwid":"","expires":0,"note":"buyer1"}}
//   PROTECTED_SCRIPT_URL    raw URL of the private, obfuscated script
//   PROTECTED_SCRIPT_TOKEN  (optional) auth token for that private URL
//   UPSTASH_REDIS_REST_URL  (optional) enables auto-bind on first use
//   UPSTASH_REDIS_REST_TOKEN(optional) token for the above
// ============================================================================

async function kvGet(k) {
  const base = process.env.UPSTASH_REDIS_REST_URL, tok = process.env.UPSTASH_REDIS_REST_TOKEN
  if (!base || !tok) return undefined
  try {
    const r = await fetch(`${base}/get/${encodeURIComponent(k)}`, { headers: { Authorization: `Bearer ${tok}` } })
    if (!r.ok) return undefined
    const j = await r.json()
    return j && j.result != null ? j.result : undefined
  } catch (e) { console.error('animeballhub: kvGet failed', e); return undefined }
}
async function kvSet(k, v) {
  const base = process.env.UPSTASH_REDIS_REST_URL, tok = process.env.UPSTASH_REDIS_REST_TOKEN
  if (!base || !tok) return false
  try {
    const r = await fetch(`${base}/set/${encodeURIComponent(k)}/${encodeURIComponent(v)}`, {
      headers: { Authorization: `Bearer ${tok}` },
    })
    return r.ok
  } catch (e) { console.error('animeballhub: kvSet failed', e); return false }
}

module.exports = async function handler(req, res) {
  if (req.method !== 'POST') return res.status(405).json({ ok: false, error: 'POST only' })

  let body = req.body
  if (typeof body === 'string') { try { body = JSON.parse(body) } catch (e) { console.warn('animeballhub: invalid JSON body', e); body = {} } }
  const key = ((body && body.key) || '').toString().trim()
  const hwid = ((body && body.hwid) || '').toString().trim()
  if (!key || !hwid) return res.status(400).json({ ok: false, error: 'key and hwid required' })

  // --- validate key ---
  let keys = {}
  try { keys = JSON.parse(process.env.ANIMEBALL_KEYS || '{}') } catch (e) { console.error('animeballhub: ANIMEBALL_KEYS is not valid JSON; all keys will be rejected', e); keys = {} }
  const entry = keys[key]
  if (!entry) return res.status(403).json({ ok: false, error: 'invalid key' })

  // expiry (0 or missing = never expires)
  if (entry.expires && Number(entry.expires) > 0 && Date.now() / 1000 > Number(entry.expires))
    return res.status(403).json({ ok: false, error: 'key expired' })

  // --- HWID lock ---
  // 1) static lock in the key entry always wins if present
  let lockedHwid = (entry.hwid || '').toString().trim()
  // 2) otherwise try auto-bind via Upstash (lock on first use)
  if (!lockedHwid) {
    const stored = await kvGet(`animeball:hwid:${key}`)
    if (stored) {
      lockedHwid = stored.toString().trim()
    } else {
      // first use -> bind this HWID to the key (best-effort; if KV absent, key stays unlocked)
      await kvSet(`animeball:hwid:${key}`, hwid)
      lockedHwid = hwid
    }
  }
  if (lockedHwid && lockedHwid !== hwid)
    return res.status(403).json({ ok: false, error: 'key locked to another device' })

  // --- fetch the protected script from a PRIVATE source ---
  const url = process.env.PROTECTED_SCRIPT_URL
  if (!url) return res.status(500).json({ ok: false, error: 'server not configured (PROTECTED_SCRIPT_URL)' })
  const headers = { 'User-Agent': 'animeballhub' }
  if (process.env.PROTECTED_SCRIPT_TOKEN) headers.Authorization = `token ${process.env.PROTECTED_SCRIPT_TOKEN}`
  try {
    const upstream = await fetch(url, { headers })
    if (!upstream.ok) return res.status(502).json({ ok: false, error: 'script fetch failed' })
    const code = await upstream.text()
    res.setHeader('Content-Type', 'text/plain; charset=utf-8')
    res.setHeader('Cache-Control', 'no-store')
    return res.status(200).send(code)
  } catch (e) {
    return res.status(502).json({ ok: false, error: e.message })
  }
}
