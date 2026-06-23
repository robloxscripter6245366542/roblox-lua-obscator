// Vercel serverless function — proxies to Claude API
// Set ANTHROPIC_API_KEY in Vercel dashboard → Project → Settings → Environment Variables

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
  // CORS
  res.setHeader("Access-Control-Allow-Origin", "*");
  res.setHeader("Access-Control-Allow-Methods", "POST, OPTIONS");
  res.setHeader("Access-Control-Allow-Headers", "Content-Type");
  if (req.method === "OPTIONS") return res.status(200).end();
  if (req.method !== "POST") return res.status(405).json({ error: "Method not allowed" });

  // Rate limiting
  const ip = req.headers["x-forwarded-for"]?.split(",")[0]?.trim() || "unknown";
  if (isRateLimited(ip)) {
    return res.status(429).json({ error: "Too many requests. Try again in a minute." });
  }

  const key = process.env.ANTHROPIC_API_KEY;
  if (!key) {
    return res.status(503).json({ error: "AI not configured yet. Check back soon!" });
  }

  const { messages } = req.body || {};
  if (!messages || !Array.isArray(messages) || messages.length === 0) {
    return res.status(400).json({ error: "No messages provided." });
  }

  // Keep last 20 messages only
  const history = messages.slice(-20).map(m => ({
    role: m.role === "assistant" ? "assistant" : "user",
    content: String(m.content).slice(0, 4000),
  }));

  try {
    const apiRes = await fetch("https://api.anthropic.com/v1/messages", {
      method: "POST",
      headers: {
        "x-api-key": key,
        "anthropic-version": "2023-06-01",
        "content-type": "application/json",
      },
      body: JSON.stringify({
        model: "claude-sonnet-4-6",
        max_tokens: 1024,
        system: `You are Nano AI — the smartest coding tutor and programming assistant ever built.
You know every programming language, framework, algorithm, and software engineering concept.
Your personality: brilliant, friendly, direct. Give clear answers with real code examples.
Format code with triple backticks and the language name. Keep answers focused and actionable.
You help with Python, JavaScript, Lua, Rust, Go, Java, SQL, HTML, CSS, Three.js, React,
Roblox/Luau, game dev, web dev, AI/ML, algorithms, data structures — literally everything.
Running on Nano AI — a Claude-powered coding tutor at nano-ai.vercel.app`,
        messages: history,
      }),
    });

    if (!apiRes.ok) {
      const err = await apiRes.json().catch(() => ({}));
      console.error("Anthropic API error:", apiRes.status, err);
      return res.status(502).json({ error: "AI error. Please try again." });
    }

    const data = await apiRes.json();
    const reply = data.content?.[0]?.text || "";
    return res.status(200).json({ reply });
  } catch (err) {
    console.error("Handler error:", err);
    return res.status(500).json({ error: "Server error. Please try again." });
  }
}
