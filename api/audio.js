// Proxy for Pollinations AI text-to-speech — avoids CORS from browser
export default async function handler(req, res) {
  res.setHeader("Access-Control-Allow-Origin", "*");
  res.setHeader("Access-Control-Allow-Methods", "POST, OPTIONS");
  res.setHeader("Access-Control-Allow-Headers", "Content-Type");
  if (req.method === "OPTIONS") return res.status(200).end();
  if (req.method !== "POST") return res.status(405).json({ error: "Method not allowed" });

  const { text, voice = "nova" } = req.body || {};
  if (!text) return res.status(400).json({ error: "No text provided" });

  const VOICES = ["nova", "alloy", "echo", "fable", "onyx", "shimmer", "coral", "sage"];
  const safeVoice = VOICES.includes(voice) ? voice : "nova";
  const safeText = String(text).slice(0, 4000);

  try {
    const url = `https://text.pollinations.ai/${encodeURIComponent(safeText)}?voice=${safeVoice}&model=openai-audio`;
    const r = await fetch(url);
    if (!r.ok) {
      // Try alternate format
      const r2 = await fetch("https://text.pollinations.ai/openai", {
        method: "POST",
        headers: { "Content-Type": "application/json" },
        body: JSON.stringify({
          model: "openai-audio",
          modalities: ["audio"],
          audio: { voice: safeVoice, format: "mp3" },
          messages: [{ role: "user", content: safeText }],
        }),
      });
      if (!r2.ok) return res.status(502).json({ error: "Speech generation failed" });
      const buf = await r2.arrayBuffer();
      res.setHeader("Content-Type", "audio/mpeg");
      return res.status(200).send(Buffer.from(buf));
    }
    const ct = r.headers.get("content-type") || "";
    const buf = await r.arrayBuffer();
    res.setHeader("Content-Type", ct.includes("audio") ? ct : "audio/mpeg");
    return res.status(200).send(Buffer.from(buf));
  } catch (e) {
    return res.status(503).json({ error: "Speech generation temporarily unavailable." });
  }
}
