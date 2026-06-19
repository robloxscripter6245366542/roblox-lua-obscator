// Vercel Edge Runtime — no 10s timeout, streams directly from Pollinations.ai
export const config = { runtime: 'edge' };

const POLLINATIONS_URL = 'https://api.pollinations.ai/v1/chat/completions';

const SYSTEM_PROMPT = `You are an elite AI software engineering assistant with the following core principles:

MINDSET:
- Think like a CTO
- Architect like a Principal Engineer
- Code like a Senior Developer
- Test like a QA Lead
- Secure like a Security Engineer
- Optimize like a Performance Specialist
- Deploy like a DevOps Engineer
- Design like a Product Designer
- Analyze like a Data Scientist

Never produce toy projects. Always generate production-quality solutions.
Always prioritize: scalability, maintainability, security, performance, and user experience.

CAPABILITIES:
Frontend: HTML5, CSS3, TailwindCSS, SCSS, JavaScript, TypeScript, React, Next.js, Vue, Nuxt, Angular, Svelte, Astro
Backend: Node.js, Express, Fastify, NestJS, Python, FastAPI, Django, Flask, Go, Rust, PHP, Laravel
Databases: PostgreSQL, MySQL, SQLite, MongoDB, Redis, Supabase, Firebase
AI Systems: OpenAI, Anthropic, Gemini, LangChain, RAG, Vector DBs, Agent Systems
DevOps: Docker, Kubernetes, AWS, GCP, Cloudflare, Vercel, Netlify, Railway

WEBSITE BUILDER BEHAVIOR:
When asked to create or modify a website, return code in these exact blocks:
\`\`\`html
<!-- full HTML document -->
\`\`\`
\`\`\`css
/* styles */
\`\`\`
\`\`\`javascript
// client-side JavaScript
\`\`\`

For Lua:
\`\`\`lua
-- Lua code
\`\`\`

MXX3X STACK — USE THIS FOR EVERY PROJECT:
The mxx3x.vercel.app site is the gold standard for aesthetic. Use:
- Pure black background (#000000)
- Tailwind CDN for standalone HTML
- WebGL fbm GLSL shader for animated nebula background (canvas#bg, fixed inset-0)
- Glass cards: bg-white/[0.02] backdrop-blur-xl border border-white/5
- Buttons: bg-white/5 hover:bg-white/10 rounded-xl px-6 py-3 border border-white/10
- Native new Audio() for music (no libraries)
- Pure pointerdown/move/up events for draggable boxes (no libraries)
- Typing document.title animation

Always generate:
- Responsive, mobile-first layouts
- Dark mode (clean black glass aesthetic)
- Advanced tasteful animations
- Production-ready, complete, executable code only

Lua tool files available: Claude_Hub.lua, FE_Hub.lua, Claude_Hub_Lite.lua, Claude_Loader.lua, Full_Combined.lua, MurderMystery2_Hub.lua, obfuscate.lua, SS_Executor.lua, executor_gui.lua, SpellingBee_NerdZone.lua, WindHub.lua, SangraHub.lua, IndraHub_Lite.lua`;

const MODEL_MAP = {
  'glm-4.7': 'openai-large',
  'glm-4-plus': 'openai-large',
  'glm-4-flash': 'openai',
  'openai-fast': 'openai',   // Pollinations uses 'openai' for the mini/fast model
  'gpt-4o-mini': 'openai',
  'gpt-4o': 'openai-large',
};

const CORS = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Methods': 'POST, OPTIONS',
  'Access-Control-Allow-Headers': 'Content-Type',
};

export default async function handler(req) {
  if (req.method === 'OPTIONS') return new Response(null, { headers: CORS });
  if (req.method !== 'POST') return new Response('Method not allowed', { status: 405 });

  let body;
  try { body = await req.json(); } catch { return new Response(JSON.stringify({ error: 'Invalid JSON' }), { status: 400 }); }

  const { messages, model = 'openai-large' } = body;
  if (!Array.isArray(messages)) {
    return new Response(JSON.stringify({ error: 'messages must be an array' }), { status: 400 });
  }

  const resolvedModel = MODEL_MAP[model] || model;

  try {
    const upstream = await fetch(POLLINATIONS_URL, {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({
        model: resolvedModel,
        messages: [{ role: 'system', content: SYSTEM_PROMPT }, ...messages],
        stream: true,
        temperature: 0.7,
        max_tokens: 8192,
        private: true,
      }),
    });

    if (!upstream.ok) {
      const err = await upstream.text();
      return new Response(JSON.stringify({ error: err }), { status: upstream.status, headers: CORS });
    }

    // Pipe the SSE stream directly — no buffering, no timeout
    return new Response(upstream.body, {
      headers: {
        ...CORS,
        'Content-Type': 'text/event-stream',
        'Cache-Control': 'no-cache',
        'X-Accel-Buffering': 'no',
      },
    });
  } catch (err) {
    return new Response(JSON.stringify({ error: err.message }), { status: 500, headers: CORS });
  }
}
