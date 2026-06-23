// Vercel serverless function — proxies to OpenRouter (Claude via openrouter.ai)
// Set OPENROUTER_API_KEY in Vercel dashboard → Project → Settings → Environment Variables

const RATE_LIMIT_WINDOW = 60_000; // 1 minute
const RATE_LIMIT_MAX    = 10;     // requests per IP per window
const ipMap = new Map();

function isRateLimited(ip) {
  const now = Date.now();
  const entry = ipMap.get(ip) || { count: 0, start: now };
  if (now - entry.start > RATE_LIMIT_WINDOW) {
    ipMap.set(ip, { count: 1, start: now });
    return false;
  }
  entry.count++;
  ipMap.set(ip, entry);
  return entry.count > RATE_LIMIT_MAX;
}

export default async function handler(req, res) {
  res.setHeader("Access-Control-Allow-Origin", "*");
  res.setHeader("Access-Control-Allow-Methods", "POST, OPTIONS");
  res.setHeader("Access-Control-Allow-Headers", "Content-Type");
  if (req.method === "OPTIONS") return res.status(200).end();
  if (req.method !== "POST") return res.status(405).json({ error: "Method not allowed" });

  const ip = req.headers["x-forwarded-for"]?.split(",")[0]?.trim() || "unknown";
  if (isRateLimited(ip)) {
    return res.status(429).json({ error: "Too many requests — try again in a minute." });
  }

  const key = process.env.OPENROUTER_API_KEY;
  if (!key) {
    return res.status(503).json({ error: "AI not configured yet. Check back soon!" });
  }

  const { messages } = req.body || {};
  if (!messages || !Array.isArray(messages) || messages.length === 0) {
    return res.status(400).json({ error: "No messages provided." });
  }

  const history = messages.slice(-20).map(m => ({
    role: m.role === "assistant" ? "assistant" : "user",
    content: String(m.content).slice(0, 4000),
  }));

  try {
    const apiRes = await fetch("https://openrouter.ai/api/v1/chat/completions", {
      method: "POST",
      headers: {
        "Authorization": `Bearer ${key}`,
        "Content-Type": "application/json",
        "HTTP-Referer": "https://nano-ai.vercel.app",
        "X-Title": "Nano AI",
      },
      body: JSON.stringify({
        model: "anthropic/claude-sonnet-4-5",
        max_tokens: 1024,
        messages: [
          {
            role: "system",
            content: `You are Nano AI — the smartest coding tutor and programming assistant ever built.
You know every programming language, framework, algorithm, and software engineering concept.
Your personality: brilliant, friendly, direct. Give clear answers with real code examples.
Format code with triple backticks and the language name. Keep answers focused and actionable.
You help with Python, JavaScript, Lua, Rust, Go, Java, SQL, HTML, CSS, Three.js, React,
Roblox/Luau, game dev, web dev, AI/ML, algorithms — literally everything.`,
          },
          ...history,
        ],
      }),
    });

    if (!apiRes.ok) {
      const err = await apiRes.json().catch(() => ({}));
      console.error("OpenRouter error:", apiRes.status, err);
      return res.status(502).json({ error: "AI error. Please try again." });
    }

    const data = await apiRes.json();
    const reply = data.choices?.[0]?.message?.content || "";
    return res.status(200).json({ reply });
  } catch (err) {
    console.error("Handler error:", err);
    return res.status(500).json({ error: "Server error. Please try again." });
  }
}
