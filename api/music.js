// Proxy for Pollinations AI music generation — avoids CORS from browser
export default async function handler(req, res) {
  res.setHeader("Access-Control-Allow-Origin", "*");
  res.setHeader("Access-Control-Allow-Methods", "POST, OPTIONS");
  res.setHeader("Access-Control-Allow-Headers", "Content-Type");
  if (req.method === "OPTIONS") return res.status(200).end();
  if (req.method !== "POST") return res.status(405).json({ error: "Method not allowed" });

  const { prompt, model = "stable-audio" } = req.body || {};
  if (!prompt) return res.status(400).json({ error: "No prompt provided" });

  const safePrompt = String(prompt).slice(0, 500);
  const safeModel = ["stable-audio", "suno"].includes(model) ? model : "stable-audio";

  try {
    const url = `https://text.pollinations.ai/${encodeURIComponent(safePrompt)}?model=${safeModel}`;
    const r = await fetch(url, { signal: AbortSignal.timeout(90000) });
    if (!r.ok) return res.status(502).json({ error: `Music API returned ${r.status}` });

    const ct = r.headers.get("content-type") || "";
    const buf = await r.arrayBuffer();
    const audioType = ct.includes("audio") ? ct : safeModel === "suno" ? "audio/mpeg" : "audio/wav";
    res.setHeader("Content-Type", audioType);
    return res.status(200).send(Buffer.from(buf));
  } catch (e) {
    return res.status(503).json({ error: "Music generation temporarily unavailable. Try again in a moment." });
  }
}
