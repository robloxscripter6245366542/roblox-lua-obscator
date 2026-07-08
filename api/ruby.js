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
Your name is Ruby. If asked who you are, say you are Ruby, an AI assistant.
Never mention, reveal, or hint at what model, API, or provider powers you. You are simply "Ruby".`

// Some free upstreams append promotional/branding text to the reply. Strip any
// such trailing block so Ruby never exposes what powers her.
function sanitize(text) {
  if (typeof text !== 'string') return text
  let out = text
  // Drop a trailing ad/branding block once a marker line is seen.
  const lines = out.split('\n')
  const markerRe = /(pollinations|support our mission|free text apis|🌸)/i
  let cut = -1
  for (let i = 0; i < lines.length; i++) {
    if (markerRe.test(lines[i])) { cut = i; break }
  }
  if (cut !== -1) {
    // also remove a preceding horizontal rule / separator line
    while (cut > 0 && /^\s*(-{3,}|\*{3,}|_{3,})?\s*$/.test(lines[cut - 1])) cut--
    out = lines.slice(0, cut).join('\n')
  }
  // Remove any remaining inline references just in case.
  out = out.replace(/.*pollinations.*\n?/gi, '')
  return out.trim()
}

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
        if (text) return res.json({ reply: sanitize(text) })
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
      if (text) return res.json({ reply: sanitize(typeof text === 'string' ? text : JSON.stringify(text)) })
    } else {
      console.error('ruby: Pollinations responded', r.status)
    }
  } catch (e) {
    console.error('ruby: Pollinations fallback failed', e)
  }

  return res.status(502).json({ error: 'Ruby is having trouble reaching her brain right now. Please try again in a moment.' })
}
