// Proxy for Pollinations AI video generation — fixes CORS when called from the browser
export default async function handler(req, res) {
  res.setHeader("Access-Control-Allow-Origin", "*");
  res.setHeader("Access-Control-Allow-Methods", "POST, OPTIONS");
  res.setHeader("Access-Control-Allow-Headers", "Content-Type");
  if (req.method === "OPTIONS") return res.status(200).end();
  if (req.method !== "POST") return res.status(405).json({ error: "Method not allowed" });

  const { prompt, model = "seedance-2.0", duration = 5, width = 1920, height = 1080 } = req.body || {};
  if (!prompt) return res.status(400).json({ error: "No prompt" });

  try {
    const r = await fetch("https://video.pollinations.ai/", {
      method: "POST",
      headers: { "Content-Type": "application/json" },
      body: JSON.stringify({ prompt, model, duration, width, height }),
      signal: AbortSignal.timeout(110000),
    });
    if (!r.ok) return res.status(r.status).json({ error: `Video API returned ${r.status}` });

    const ct = r.headers.get("content-type") || "";
    if (ct.includes("video") || ct.includes("octet-stream")) {
      const buffer = await r.arrayBuffer();
      res.setHeader("Content-Type", "video/mp4");
      res.setHeader("Content-Disposition", "inline");
      return res.status(200).send(Buffer.from(buffer));
    }
    const data = await r.json();
    return res.status(200).json(data);
  } catch (e) {
    return res.status(503).json({ error: "Video generation temporarily unavailable. Try again in a moment." });
  }
}
