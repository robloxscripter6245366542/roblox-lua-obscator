// Proxy for Pollinations AI image generation — fixes CORS and normalises model names
export default async function handler(req, res) {
  res.setHeader("Access-Control-Allow-Origin", "*");
  res.setHeader("Access-Control-Allow-Methods", "GET, POST, OPTIONS");
  res.setHeader("Access-Control-Allow-Headers", "Content-Type");
  if (req.method === "OPTIONS") return res.status(200).end();

  const params = req.method === "POST" ? req.body : req.query;
  const { prompt, model = "flux-pro", width = 1024, height = 1024, seed } = params || {};
  if (!prompt) return res.status(400).json({ error: "No prompt provided" });

  // Normalise model names to what Pollinations actually supports
  const MODEL_MAP = {
    "flux-pro": "flux-pro",
    "flux-realism": "flux-realism",
    "flux-anime": "flux-anime",
    "flux-3d": "flux-3d",
    "flux": "flux",
    "turbo": "turbo",
    "gptimage": "gptimage",
    "seedimage": "seedream",
    "seedream": "seedream",
  };
  const resolvedModel = MODEL_MAP[model] || "flux-pro";
  const s = seed || Math.floor(Math.random() * 99999);

  const url = `https://image.pollinations.ai/prompt/${encodeURIComponent(String(prompt))}?model=${resolvedModel}&width=${width}&height=${height}&enhance=true&nologo=true&seed=${s}`;

  try {
    const r = await fetch(url, { signal: AbortSignal.timeout(115000) });
    if (!r.ok) {
      // Fallback to flux-pro if the requested model fails
      if (resolvedModel !== "flux-pro") {
        const fallback = await fetch(url.replace(`model=${resolvedModel}`, "model=flux-pro"), { signal: AbortSignal.timeout(115000) });
        if (fallback.ok) {
          const buf = await fallback.arrayBuffer();
          res.setHeader("Content-Type", "image/jpeg");
          return res.status(200).send(Buffer.from(buf));
        }
      }
      return res.status(r.status).json({ error: `Image API returned ${r.status}` });
    }
    const buf = await r.arrayBuffer();
    const ct = r.headers.get("content-type") || "image/jpeg";
    res.setHeader("Content-Type", ct);
    res.setHeader("Cache-Control", "public, max-age=3600");
    return res.status(200).send(Buffer.from(buf));
  } catch (e) {
    return res.status(503).json({ error: "Image generation temporarily unavailable." });
  }
}
