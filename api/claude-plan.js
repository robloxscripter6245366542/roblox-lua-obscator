const ANTHROPIC_API = 'https://api.anthropic.com/v1/messages'
const POLL_TEXT = 'https://text.pollinations.ai/'

const SYSTEM = `You are a cinematic AI video director. Given a prompt, produce a detailed video production plan.
Return ONLY valid JSON in this exact shape:
{
  "title": "short punchy title",
  "narration": "50-80 word narration script for a professional voice-over",
  "scenes": [
    {
      "type": "one of: galaxy|neon_city|abstract|crystal|terrain|nebula|space|ocean",
      "duration": 4,
      "palette": ["#hexcolor1","#hexcolor2","#hexcolor3"],
      "mood": "epic|dreamy|tense|serene|mysterious",
      "intensity": 0.8,
      "speed": 1.0,
      "camera": "orbit|zoom_in|fly_through|pan_left|rise"
    }
  ],
  "transition": "fade|dissolve|flash",
  "music_mood": "epic|ambient|tense|uplifting"
}
Generate 4-5 scenes. Each scene should feel visually distinct. Be creative and cinematic.`

module.exports = async function handler(req, res) {
  if (req.method !== 'POST') return res.status(405).end()
  const { prompt } = req.body || {}
  if (!prompt) return res.status(400).json({ error: 'prompt required' })

  // Try Anthropic API first
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
          max_tokens: 1500,
          system: SYSTEM,
          messages: [{ role: 'user', content: `Create a cinematic video plan for: "${prompt}"` }],
        }),
      })
      if (r.ok) {
        const d = await r.json()
        const text = d.content?.[0]?.text
        if (text) return res.json(JSON.parse(text))
      }
    } catch (e) {
      console.error('claude-plan: Anthropic request failed, falling back', e)
    }
  }

  // Fall back to Pollinations Claude proxy (free)
  try {
    const r = await fetch(POLL_TEXT, {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({
        model: 'claude',
        jsonMode: true,
        messages: [
          { role: 'system', content: SYSTEM },
          { role: 'user', content: `Create a cinematic video plan for: "${prompt}"` },
        ],
      }),
    })
    if (r.ok) {
      const d = await r.json()
      if (d.scenes) return res.json(d)
      const text = d.choices?.[0]?.message?.content
      if (text) return res.json(typeof text === 'string' ? JSON.parse(text) : text)
    }
  } catch (e) {
    console.error('claude-plan: Pollinations fallback failed, using static plan', e)
  }

  // Hardcoded fallback plan
  res.json(buildFallback(prompt))
}

function buildFallback(prompt) {
  const p = prompt.toLowerCase()
  const isSpace = /space|galaxy|star|cosmos|universe/.test(p)
  const isNature = /forest|mountain|ocean|river|nature/.test(p)
  const isCity = /city|cyber|neon|urban|future/.test(p)
  const isMystic = /magic|dragon|fantasy|myth|crystal/.test(p)

  const type1 = isSpace ? 'galaxy' : isNature ? 'terrain' : isCity ? 'neon_city' : isMystic ? 'crystal' : 'abstract'
  return {
    title: prompt.slice(0, 40),
    narration: `${prompt}. A breathtaking journey through stunning visuals, where art meets technology in perfect harmony. Experience the future of AI-generated cinema.`,
    scenes: [
      { type: type1,    duration: 4, palette: ['#7C3AED','#2563EB','#ffffff'], mood: 'epic',       intensity: 0.9, speed: 1.0, camera: 'orbit'       },
      { type: 'nebula', duration: 4, palette: ['#EC4899','#7C3AED','#06B6D4'], mood: 'dreamy',     intensity: 0.8, speed: 0.7, camera: 'zoom_in'      },
      { type: 'abstract', duration: 3, palette: ['#10B981','#2563EB','#fff'], mood: 'mysterious',  intensity: 1.0, speed: 1.3, camera: 'fly_through'  },
      { type: 'space',  duration: 4, palette: ['#1E1B4B','#4F46E5','#C4B5FD'], mood: 'serene',    intensity: 0.7, speed: 0.8, camera: 'pan_left'      },
    ],
    transition: 'fade',
    music_mood: 'epic',
  }
}
