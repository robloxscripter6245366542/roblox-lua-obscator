const ANTHROPIC_API = 'https://api.anthropic.com/v1/messages'
const POLL_TEXT = 'https://text.pollinations.ai/openai'

const SYSTEM = `You are Ruby, a warm, sharp, and helpful AI assistant.
You specialise in Lua and Roblox scripting, but you can help with anything the user asks.
Guidelines:
- Be concise and friendly. Use markdown (headings, bullet points, fenced code blocks) when it helps.
- When you write code, always wrap it in fenced blocks with the correct language tag (e.g. \`\`\`lua).
- Explain your reasoning briefly when it adds value; don't pad answers.
- If a request is ambiguous, make a reasonable assumption and say so.
- Never claim you can do something impossible (like perfectly reversing a VM-based obfuscator). Be honest about limits.
Your name is Ruby. If asked who you are, say you are Ruby, an AI assistant.`

module.exports = async function handler(req, res) {
  if (req.method !== 'POST') return res.status(405).json({ error: 'method not allowed' })

  const body = req.body || {}
  const messages = Array.isArray(body.messages) ? body.messages : null
  if (!messages || messages.length === 0) {
    return res.status(400).json({ error: 'messages array required' })
  }

  // Keep only role/content and cap history to avoid oversized payloads.
  const clean = messages
    .filter((m) => m && (m.role === 'user' || m.role === 'assistant') && typeof m.content === 'string')
    .slice(-20)
    .map((m) => ({ role: m.role, content: m.content.slice(0, 24000) }))

  if (clean.length === 0 || clean[clean.length - 1].role !== 'user') {
    return res.status(400).json({ error: 'last message must be from the user' })
  }

  // Try Anthropic first if a key is configured.
  const anthropicKey = process.env.ANTHROPIC_API_KEY
  if (anthropicKey) {
    try {
      const r = await fetch(ANTHROPIC_API, {
        method: 'POST',
        headers: {
          'x-api-key': anthropicKey,
          'anthropic-version': '2023-06-01',
          'content-type': 'application/json',
        },
        body: JSON.stringify({
          model: 'claude-sonnet-4-6',
          max_tokens: 2000,
          system: SYSTEM,
          messages: clean,
        }),
      })
      if (r.ok) {
        const d = await r.json()
        const text = d.content?.[0]?.text
        if (text) return res.json({ reply: text, provider: 'anthropic' })
      } else {
        console.error('ruby: Anthropic responded', r.status)
      }
    } catch (e) {
      console.error('ruby: Anthropic request failed, falling back', e)
    }
  }

  // Fall back to the free Pollinations OpenAI-compatible proxy.
  try {
    const r = await fetch(POLL_TEXT, {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({
        model: 'openai',
        messages: [{ role: 'system', content: SYSTEM }, ...clean],
      }),
    })
    if (r.ok) {
      const d = await r.json()
      const text = d.choices?.[0]?.message?.content
      if (text) return res.json({ reply: typeof text === 'string' ? text : JSON.stringify(text), provider: 'pollinations' })
    } else {
      console.error('ruby: Pollinations responded', r.status)
    }
  } catch (e) {
    console.error('ruby: Pollinations fallback failed', e)
  }

  return res.status(502).json({ error: 'Ruby is having trouble reaching her brain right now. Please try again in a moment.' })
}
