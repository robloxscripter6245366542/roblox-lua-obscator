export const config = { runtime: 'edge' };

const SYSTEM = `You are NexusAI, an expert full-stack developer. When asked to build anything you always respond with a complete, self-contained HTML file that works perfectly in a browser.

Rules:
1. Output ONE complete HTML file inside a \`\`\`html … \`\`\` code block.
2. Embed ALL CSS in <style> tags and ALL JS in <script> tags — no external files except CDN libraries.
3. You MAY load CDN libraries (Chart.js, Three.js, etc.) via <script src>.
4. Make it beautiful: modern design, smooth animations, professional, responsive.
5. Make it fully functional — not a mockup. Real working buttons, data, interactions.
6. When asked for changes, output the FULL updated HTML file.
7. After the code block write 1-2 sentences describing what you built.

Design philosophy: premium, polished, cinematic. Think Vercel + Linear + Stripe quality.`;

export default async function handler(req) {
  if (req.method === 'OPTIONS') {
    return new Response(null, {
      headers: {
        'Access-Control-Allow-Origin': '*',
        'Access-Control-Allow-Methods': 'POST, OPTIONS',
        'Access-Control-Allow-Headers': 'Content-Type',
      },
    });
  }

  if (req.method !== 'POST') {
    return new Response('Method not allowed', { status: 405 });
  }

  let messages;
  try {
    ({ messages } = await req.json());
  } catch {
    return new Response(JSON.stringify({ error: 'Invalid JSON' }), {
      status: 400,
      headers: { 'Content-Type': 'application/json' },
    });
  }

  const apiKey = process.env.Z_AI_API_KEY;
  if (!apiKey) {
    return new Response(JSON.stringify({ error: 'API key not configured' }), {
      status: 500,
      headers: { 'Content-Type': 'application/json' },
    });
  }

  const upstream = await fetch('https://api.z.ai/api/paas/v4/chat/completions', {
    method: 'POST',
    headers: {
      'Content-Type': 'application/json',
      Authorization: `Bearer ${apiKey}`,
    },
    body: JSON.stringify({
      model: 'glm-5.2',
      messages: [{ role: 'system', content: SYSTEM }, ...messages],
      stream: true,
      temperature: 0.7,
    }),
  });

  if (!upstream.ok) {
    const err = await upstream.text().catch(() => upstream.statusText);
    return new Response(JSON.stringify({ error: err }), {
      status: upstream.status,
      headers: { 'Content-Type': 'application/json' },
    });
  }

  return new Response(upstream.body, {
    headers: {
      'Content-Type': 'text/event-stream',
      'Cache-Control': 'no-cache',
      'X-Accel-Buffering': 'no',
      'Access-Control-Allow-Origin': '*',
    },
  });
}
