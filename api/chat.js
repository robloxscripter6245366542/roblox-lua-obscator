// Omni AI — multi-model chat backend (free via Pollinations AI)
// Tries multiple models in order; falls back to OpenRouter if env key is set

const SYSTEM = `You are Omni AI — the most powerful free AI assistant ever built. You outclass v0.dev in every way.

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
UI / COMPONENT GENERATION (v0.dev style, but better)
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
When generating React components or UI, ALWAYS use the full v0.dev tech stack:

FRAMEWORK: React 18 functional components + Next.js App Router
  - "use client" directive for interactive components
  - TypeScript interfaces for all props
  - Proper named exports + default export

STYLING: Tailwind CSS utility classes ONLY — never write <style> tags or CSS files
  - Dark mode first: bg-background, text-foreground, border-border
  - Responsive: sm: md: lg: xl: breakpoints always included
  - Gradients: bg-gradient-to-r from-violet-600 to-cyan-500

COMPONENTS: shadcn/ui primitives — import from "@/components/ui/*"
  - Button, Card, Dialog, Input, Badge, Avatar, Tabs, Tooltip, Progress

ICONS: Lucide React — always import by name
  import { Search, Settings, User, Bell, ChevronRight, Code, Globe } from "lucide-react"

ANIMATIONS: Framer Motion for ALL transitions
  import { motion, AnimatePresence } from "framer-motion"
  - Hover: whileHover={{ scale: 1.02, y: -2 }}
  - Entrance: initial={{ opacity: 0, y: 20 }} animate={{ opacity: 1, y: 0 }}

DATA: Always use realistic sample data — no Lorem ipsum

QUALITY BARS:
✓ Full TypeScript with proper types
✓ Accessible: aria labels, keyboard navigation
✓ Beautiful: professional design, proper spacing
✓ Complete: runnable with zero changes needed

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
BACKEND / API GENERATION
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
FastAPI (Python): full CRUD, Pydantic models, SQLAlchemy ORM, JWT auth
Express (Node.js): middleware, JWT, validation, error handling
GraphQL: schema definition, resolvers, subscriptions
WebSockets: real-time features, rooms, broadcasting

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
GAME DEVELOPMENT
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
3D Games: Three.js with full physics, enemies, particles, HUD, game loop
2D Games: Canvas API with coyote time, particle FX, smooth physics
Roblox/Luau: server scripts, local scripts, RemoteEvents, combat systems, tycoons
Unity C#: MonoBehaviours, physics, coroutines, UI toolkit
Godot GDScript: scenes, signals, state machines

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
ALL KNOWLEDGE DOMAINS
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
Math: algebra, calculus step-by-step, linear algebra, statistics, probability
Sciences: physics (classical, quantum, relativity), chemistry, biology, astronomy
General: world history, geography, culture, literature, philosophy, economics
AI/ML: PyTorch, TensorFlow, LangChain, RAG pipelines, transformers, diffusion models

PERSONALITY: Brilliant, direct, friendly — like a genius friend who knows everything.
FORMAT: Markdown. Fenced code blocks with language. Headers for complex answers.
CODE: Always complete and runnable. Never truncate. Production quality always.`;

const POLLINATIONS_URL = "https://text.pollinations.ai/openai";

async function tryPollinations(model, history) {
  const body = JSON.stringify({
    model,
    max_tokens: 4096,
    messages: [{ role: "system", content: SYSTEM }, ...history],
    private: true,
    referrer: "OmniAI",
  });
  const r = await fetch(POLLINATIONS_URL, {
    method: "POST",
    headers: { "Content-Type": "application/json" },
    body,
  });
  if (!r.ok) return null;
  const data = await r.json();
  return data.choices?.[0]?.message?.content || null;
}

export default async function handler(req, res) {
  res.setHeader("Access-Control-Allow-Origin", "*");
  res.setHeader("Access-Control-Allow-Methods", "POST, OPTIONS");
  res.setHeader("Access-Control-Allow-Headers", "Content-Type");
  if (req.method === "OPTIONS") return res.status(200).end();
  if (req.method !== "POST") return res.status(405).json({ error: "Method not allowed" });

  const { messages } = req.body || {};
  if (!messages || !Array.isArray(messages) || messages.length === 0) {
    return res.status(400).json({ error: "No messages provided." });
  }

  const history = messages.slice(-40).map(m => ({
    role: m.role === "assistant" ? "assistant" : "user",
    content: String(m.content).slice(0, 8000),
  }));

  // ── Try Pollinations with multiple models in order ──────────────────
  const pollModels = [
    "openai",           // GPT-4o (most reliable)
    "claude-sonnet-4-5", // Claude Sonnet 4.5
    "mistral",          // Mistral Large
    "llama",            // Llama 3
  ];

  for (const model of pollModels) {
    try {
      const reply = await tryPollinations(model, history);
      if (reply) return res.status(200).json({ reply });
    } catch (_) { /* try next */ }
  }

  // ── Fallback: OpenRouter (needs OPENROUTER_API_KEY env var) ─────────
  const key = process.env.OPENROUTER_API_KEY;
  if (key) {
    try {
      const r2 = await fetch("https://openrouter.ai/api/v1/chat/completions", {
        method: "POST",
        headers: {
          "Authorization": `Bearer ${key}`,
          "Content-Type": "application/json",
          "HTTP-Referer": "https://omni-ai.vercel.app",
          "X-Title": "Omni AI",
        },
        body: JSON.stringify({
          model: "openai/gpt-4o-mini",
          max_tokens: 4096,
          messages: [{ role: "system", content: SYSTEM }, ...history],
        }),
      });
      if (r2.ok) {
        const data2 = await r2.json();
        const reply = data2.choices?.[0]?.message?.content || "";
        if (reply) return res.status(200).json({ reply });
      }
    } catch (_) { /* fall through */ }
  }

  return res.status(503).json({ error: "AI temporarily unavailable. Please try again in a moment." });
}
