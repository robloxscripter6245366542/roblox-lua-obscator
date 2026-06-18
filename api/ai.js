// Volt AI proxy — keeps the DeepSeek API key server-side.
//
//   Client (Volt.lua)  --HTTPS-->  this proxy  --Bearer key-->  DeepSeek
//
// The Roblox client never sees the real key. It only knows this endpoint.
// The key is read from the DEEPSEEK_KEY environment variable, set in the
// Vercel project settings (Settings -> Environment Variables) — it is NEVER
// committed to the repo and never sent to the client.
//
// Optional: set VOLT_PROXY_TOKEN in Vercel env to require a shared token in
// the `x-volt-token` header. This lets you rate-limit / revoke client access
// without rotating the underlying DeepSeek key.

export default async function handler(req, res) {
  // CORS / preflight
  res.setHeader("Access-Control-Allow-Origin", "*");
  res.setHeader("Access-Control-Allow-Methods", "POST, OPTIONS");
  res.setHeader("Access-Control-Allow-Headers", "Content-Type, x-volt-token");
  if (req.method === "OPTIONS") return res.status(204).end();

  if (req.method !== "POST") {
    return res.status(405).json({ error: "POST only" });
  }

  const KEY = process.env.DEEPSEEK_KEY;
  if (!KEY) {
    return res.status(500).json({ error: "server missing DEEPSEEK_KEY env var" });
  }

  // Optional shared-token gate (only enforced if VOLT_PROXY_TOKEN is set).
  const TOKEN = process.env.VOLT_PROXY_TOKEN;
  if (TOKEN && req.headers["x-volt-token"] !== TOKEN) {
    return res.status(401).json({ error: "unauthorized" });
  }

  // Parse the body (Vercel may hand it to us as a string or object).
  let body = req.body;
  if (typeof body === "string") {
    try { body = JSON.parse(body); } catch { body = {}; }
  }
  const messages = Array.isArray(body?.messages) ? body.messages : null;
  if (!messages) {
    return res.status(400).json({ error: "expected { messages: [...] }" });
  }

  try {
    const upstream = await fetch("https://api.deepseek.com/chat/completions", {
      method: "POST",
      headers: {
        "Content-Type": "application/json",
        Authorization: `Bearer ${KEY}`,
      },
      body: JSON.stringify({
        model: body.model || "deepseek-chat",
        messages,
        stream: false,
        max_tokens: body.max_tokens || 800,
        temperature: body.temperature ?? 0.7,
      }),
    });

    const data = await upstream.json().catch(() => null);
    if (!upstream.ok) {
      return res.status(upstream.status).json({
        error: "upstream error",
        status: upstream.status,
        detail: data,
      });
    }

    // Return just the assistant text so the Roblox client stays simple.
    const reply = data?.choices?.[0]?.message?.content || "";
    return res.status(200).json({ reply });
  } catch (e) {
    return res.status(502).json({ error: "proxy fetch failed", detail: String(e) });
  }
}
