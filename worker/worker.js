// ============================================================
//  Claude Hub AI Proxy  —  Cloudflare Worker
//
//  SETUP (5 minutes):
//  1. Sign up free at cloudflare.com  (no credit card needed)
//  2. Go to Workers & Pages → Create Worker → paste this code
//  3. Go to Settings → Variables → Add secret:
//       ANTHROPIC_KEY = your key from console.anthropic.com
//  4. Go to KV → Create namespace → name it "RATE_LIMITS"
//  5. In Worker Settings → Bindings → KV → add binding:
//       Variable: RATE_LIMITS  →  your namespace
//  6. Deploy. Copy your Worker URL (e.g. https://claude-hub.yourname.workers.dev)
//  7. Paste that URL into Claude_Hub.lua  AI_PROXY_URL constant
//
//  Rate limits (you can change these):
//   • 20 free messages per user per session
//   • After that: wait 30 minutes → get 10 more
//   • Keyed by Roblox UserId so each player has their own limit
// ============================================================

const FREE_MSGS     = 20;
const REFILL_MSGS   = 10;
const COOLDOWN_MS   = 30 * 60 * 1000;   // 30 minutes
const MAX_TOKENS    = 400;               // keep costs low
const MODEL         = "claude-haiku-4-5-20251001";  // cheapest Claude

// ── CORS helpers ─────────────────────────────────────────────
function addCors(resp) {
    const r = new Response(resp.body, resp);
    r.headers.set("Access-Control-Allow-Origin",  "*");
    r.headers.set("Access-Control-Allow-Methods", "POST, OPTIONS");
    r.headers.set("Access-Control-Allow-Headers", "Content-Type");
    return r;
}
function jsonResp(data, status = 200) {
    return new Response(JSON.stringify(data), {
        status,
        headers: { "Content-Type": "application/json" },
    });
}

// ── Main handler ──────────────────────────────────────────────
export default {
    async fetch(req, env) {
        // CORS preflight
        if (req.method === "OPTIONS") return addCors(new Response(null));
        if (req.method !== "POST")    return addCors(jsonResp({ error: "POST only" }, 405));

        let body;
        try { body = await req.json(); }
        catch { return addCors(jsonResp({ error: "Invalid JSON" }, 400)); }

        const { msg, sys, uid } = body;
        if (!msg || !uid) return addCors(jsonResp({ error: "Need msg + uid" }, 400));

        // Sanitize uid to prevent key injection
        const safeUid = String(uid).replace(/[^a-zA-Z0-9_-]/g, "").slice(0, 32);
        const kvKey   = "u:" + safeUid;
        const now     = Date.now();

        // ── Rate limit ──────────────────────────────────────────
        let slot = { count: FREE_MSGS, reset: now };
        try {
            const stored = await env.RATE_LIMITS.get(kvKey);
            if (stored) slot = JSON.parse(stored);
        } catch { /* KV miss — use defaults */ }

        // Refill after cooldown if count is 0
        const elapsed = now - slot.reset;
        if (slot.count <= 0 && elapsed >= COOLDOWN_MS) {
            slot.count = REFILL_MSGS;
            slot.reset  = now;
        }

        if (slot.count <= 0) {
            const waitMins = Math.ceil((COOLDOWN_MS - elapsed) / 60000);
            return addCors(jsonResp({
                error:     "rate_limit",
                wait_mins: waitMins,
                message:   `You're out of messages. Wait ${waitMins} more minute${waitMins === 1 ? "" : "s"} to get ${REFILL_MSGS} more.`,
            }, 429));
        }

        // Deduct one message before calling API
        slot.count--;
        try {
            await env.RATE_LIMITS.put(kvKey, JSON.stringify(slot), {
                expirationTtl: 7200,  // auto-clean after 2 hours of inactivity
            });
        } catch { /* non-fatal */ }

        // ── Call Anthropic Claude ───────────────────────────────
        let reply = "";
        try {
            const apiResp = await fetch("https://api.anthropic.com/v1/messages", {
                method: "POST",
                headers: {
                    "x-api-key":          env.ANTHROPIC_KEY,
                    "anthropic-version":  "2023-06-01",
                    "content-type":       "application/json",
                },
                body: JSON.stringify({
                    model:      MODEL,
                    max_tokens: MAX_TOKENS,
                    system:     (sys || "You are Claude, a helpful Roblox assistant.").slice(0, 1000),
                    messages:   [{ role: "user", content: msg.slice(0, 600) }],
                }),
            });

            const data = await apiResp.json();

            if (data?.content?.[0]?.text) {
                reply = data.content[0].text;
            } else if (data?.error) {
                // Anthropic returned an error — refund the message
                slot.count++;
                try { await env.RATE_LIMITS.put(kvKey, JSON.stringify(slot), { expirationTtl: 7200 }); } catch {}
                return addCors(jsonResp({ error: "api_error", message: data.error.message }, 500));
            } else {
                reply = "(no response)";
            }
        } catch (e) {
            // Network error — refund
            slot.count++;
            try { await env.RATE_LIMITS.put(kvKey, JSON.stringify(slot), { expirationTtl: 7200 }); } catch {}
            return addCors(jsonResp({ error: "network_error", message: e.message }, 502));
        }

        return addCors(jsonResp({
            reply,
            remaining: slot.count,
            refill_msgs: REFILL_MSGS,
        }));
    },
};
