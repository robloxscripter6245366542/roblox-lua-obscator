module.exports = async function handler(req, res) {
  const { taskId } = req.query
  if (!taskId) return res.status(400).json({ error: 'taskId required' })

  const apiKey = process.env.SEEDANCE_API_KEY
  if (!apiKey) return res.status(500).json({ error: 'server not configured (SEEDANCE_API_KEY)' })

  try {
    const upstream = await fetch(`https://api.seedance2.ai/v1/tasks/${encodeURIComponent(taskId)}`, {
      headers: { Authorization: `Bearer ${apiKey}` },
    })
    const data = await upstream.json()
    res.status(upstream.status).json(data)
  } catch (err) {
    res.status(502).json({ error: err.message })
  }
}
