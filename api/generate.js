export default async function handler(req, res) {
  if (req.method !== 'POST') return res.status(405).end()

  const apiKey = process.env.SEEDANCE_API_KEY
  if (!apiKey) return res.status(500).json({ error: 'API key not configured on server' })

  const upstream = await fetch('https://api.seedance2.ai/v1/videos/generations', {
    method: 'POST',
    headers: { Authorization: `Bearer ${apiKey}`, 'Content-Type': 'application/json' },
    body: JSON.stringify(req.body),
  })

  const data = await upstream.json()
  res.status(upstream.status).json(data)
}
