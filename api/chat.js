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

const PROVIDERS = {
  'glm-5.2': {
    url: 'https://api.z.ai/api/paas/v4/chat/completions',
    envKey: 'Z_AI_API_KEY',
    model: 'glm-5.2',
    type: 'openai',
    label: 'GLM-5.2',
  },
  'groq': {
    url: 'https://api.groq.com/openai/v1/chat/completions',
    envKey: 'GROQ_API_KEY',
    model: 'llama-3.3-70b-versatile',
    type: 'openai',
    label: 'Llama 3.3 70B',
  },
  'gemini': {
    url: 'https://generativelanguage.googleapis.com/v1beta/models/gemini-2.0-flash:streamGenerateContent',
    envKey: 'GEMINI_API_KEY',
    model: 'gemini-2.0-flash',
    type: 'gemini',
    label: 'Gemini 2.0 Flash',
  },
  'mistral': {
    url: 'https://api.mistral.ai/v1/chat/completions',
    envKey: 'MISTRAL_API_KEY',
    model: 'mistral-small-latest',
    type: 'openai',
    label: 'Mistral Small',
  },
  'cerebras': {
    url: 'https://api.cerebras.ai/v1/chat/completions',
    envKey: 'CEREBRAS_API_KEY',
    model: 'llama-3.3-70b',
    type: 'openai',
    label: 'Llama 3.3 (Cerebras)',
  },
  'deepseek': {
    url: 'https://api.deepseek.com/chat/completions',
    envKey: 'DEEPSEEK_API_KEY',
    model: 'deepseek-chat',
    type: 'openai',
    label: 'DeepSeek Chat',
  },
  'cohere': {
    url: 'https://api.cohere.com/v2/chat',
    envKey: 'COHERE_API_KEY',
    model: 'command-r-plus-08-2024',
    type: 'cohere',
    label: 'Cohere Command R+',
  },
};

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

  let messages, provider;
  try {
    ({ messages, provider = 'glm-5.2' } = await req.json());
  } catch {
    return new Response(JSON.stringify({ error: 'Invalid JSON' }), {
      status: 400,
      headers: { 'Content-Type': 'application/json' },
    });
  }

  const cfg = PROVIDERS[provider];
  if (!cfg) {
    return new Response(JSON.stringify({ error: `Unknown provider: ${provider}` }), {
      status: 400,
      headers: { 'Content-Type': 'application/json' },
    });
  }

  const apiKey = process.env[cfg.envKey];
  if (!apiKey) {
    return new Response(
      JSON.stringify({ error: `${cfg.label} is not configured yet. Add ${cfg.envKey} to Vercel env vars.` }),
      { status: 503, headers: { 'Content-Type': 'application/json' } }
    );
  }

  if (cfg.type === 'gemini') return handleGemini(messages, apiKey, cfg);
  if (cfg.type === 'cohere') return handleCohere(messages, apiKey, cfg);
  return handleOpenAI(messages, apiKey, cfg);
}

async function handleOpenAI(messages, apiKey, cfg) {
  const res = await fetch(cfg.url, {
    method: 'POST',
    headers: {
      'Content-Type': 'application/json',
      Authorization: `Bearer ${apiKey}`,
    },
    body: JSON.stringify({
      model: cfg.model,
      messages: [{ role: 'system', content: SYSTEM }, ...messages],
      stream: true,
      temperature: 0.7,
      max_tokens: 8192,
    }),
  });

  if (!res.ok) {
    const err = await res.text().catch(() => res.statusText);
    return new Response(JSON.stringify({ error: err }), {
      status: res.status,
      headers: { 'Content-Type': 'application/json' },
    });
  }

  return new Response(res.body, {
    headers: {
      'Content-Type': 'text/event-stream',
      'Cache-Control': 'no-cache',
      'X-Accel-Buffering': 'no',
      'Access-Control-Allow-Origin': '*',
    },
  });
}

async function handleGemini(messages, apiKey, cfg) {
  const contents = messages.map(m => ({
    role: m.role === 'assistant' ? 'model' : 'user',
    parts: [{ text: m.content }],
  }));

  const res = await fetch(`${cfg.url}?key=${apiKey}&alt=sse`, {
    method: 'POST',
    headers: { 'Content-Type': 'application/json' },
    body: JSON.stringify({
      contents,
      systemInstruction: { parts: [{ text: SYSTEM }] },
      generationConfig: { temperature: 0.7, maxOutputTokens: 8192 },
    }),
  });

  if (!res.ok) {
    const err = await res.text().catch(() => res.statusText);
    return new Response(JSON.stringify({ error: err }), {
      status: res.status,
      headers: { 'Content-Type': 'application/json' },
    });
  }

  // Convert Gemini SSE → OpenAI SSE format
  const { readable, writable } = new TransformStream();
  const writer = writable.getWriter();
  const encoder = new TextEncoder();

  (async () => {
    const reader = res.body.getReader();
    const decoder = new TextDecoder();
    let buf = '';
    try {
      while (true) {
        const { done, value } = await reader.read();
        if (done) break;
        buf += decoder.decode(value, { stream: true });
        const lines = buf.split('\n');
        buf = lines.pop();
        for (const line of lines) {
          if (!line.startsWith('data: ')) continue;
          try {
            const data = JSON.parse(line.slice(6));
            const text = data.candidates?.[0]?.content?.parts?.[0]?.text;
            if (text) {
              const chunk = { choices: [{ delta: { content: text }, index: 0 }] };
              await writer.write(encoder.encode(`data: ${JSON.stringify(chunk)}\n\n`));
            }
          } catch (_) {}
        }
      }
    } finally {
      await writer.write(encoder.encode('data: [DONE]\n\n'));
      await writer.close();
    }
  })();

  return new Response(readable, {
    headers: {
      'Content-Type': 'text/event-stream',
      'Cache-Control': 'no-cache',
      'X-Accel-Buffering': 'no',
      'Access-Control-Allow-Origin': '*',
    },
  });
}

async function handleCohere(messages, apiKey, cfg) {
  // Cohere v2 uses OpenAI-compatible format
  const res = await fetch(cfg.url, {
    method: 'POST',
    headers: {
      'Content-Type': 'application/json',
      Authorization: `Bearer ${apiKey}`,
    },
    body: JSON.stringify({
      model: cfg.model,
      messages: [{ role: 'system', content: SYSTEM }, ...messages],
      stream: true,
    }),
  });

  if (!res.ok) {
    const err = await res.text().catch(() => res.statusText);
    return new Response(JSON.stringify({ error: err }), {
      status: res.status,
      headers: { 'Content-Type': 'application/json' },
    });
  }

  // Cohere streams in its own format — convert to OpenAI SSE
  const { readable, writable } = new TransformStream();
  const writer = writable.getWriter();
  const encoder = new TextEncoder();

  (async () => {
    const reader = res.body.getReader();
    const decoder = new TextDecoder();
    let buf = '';
    try {
      while (true) {
        const { done, value } = await reader.read();
        if (done) break;
        buf += decoder.decode(value, { stream: true });
        const lines = buf.split('\n');
        buf = lines.pop();
        for (const line of lines) {
          if (!line.startsWith('data: ')) continue;
          const d = line.slice(6).trim();
          if (d === '[DONE]') continue;
          try {
            const p = JSON.parse(d);
            // Cohere v2 streaming uses OpenAI-compatible delta format
            const text = p.choices?.[0]?.delta?.content ?? p.delta?.message?.content?.[0]?.text;
            if (text) {
              const chunk = { choices: [{ delta: { content: text }, index: 0 }] };
              await writer.write(encoder.encode(`data: ${JSON.stringify(chunk)}\n\n`));
            }
          } catch (_) {}
        }
      }
    } finally {
      await writer.write(encoder.encode('data: [DONE]\n\n'));
      await writer.close();
    }
  })();

  return new Response(readable, {
    headers: {
      'Content-Type': 'text/event-stream',
      'Cache-Control': 'no-cache',
      'X-Accel-Buffering': 'no',
      'Access-Control-Allow-Origin': '*',
    },
  });
}
