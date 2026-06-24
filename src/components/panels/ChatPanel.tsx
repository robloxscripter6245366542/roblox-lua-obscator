import { useState, useRef, useEffect } from 'react'

function mdRender(text: string) {
  text = text.replace(/```(\w*)\n?([\s\S]*?)```/g, (_: string, lang: string, code: string) => {
    return `<pre><code class="hljs language-${lang}">${code.trim().replace(/&/g,'&amp;').replace(/</g,'&lt;').replace(/>/g,'&gt;')}</code></pre>`
  })
  text = text.replace(/`([^`\n]+)`/g, '<code>$1</code>')
  text = text.replace(/\*\*(.*?)\*\*/g, '<strong>$1</strong>')
  text = text.replace(/\*(.*?)\*/g, '<em>$1</em>')
  text = text.replace(/^#{1,4} (.+)/gm, '<strong style="color:#fff;display:block;margin:6px 0 2px">$1</strong>')
  text = text.replace(/^[•\-\*] (.+)/gm, '<div style="padding-left:12px;margin:2px 0">• $1</div>')
  text = text.replace(/\n\n/g, '<br><br>').replace(/\n/g, '<br>')
  return text
}

const QUICK_PROMPTS = [
  { ic: '⚛️', t: 'Build a React analytics dashboard with KPI cards, Recharts, and Framer Motion' },
  { ic: '🎮', t: 'Generate a Three.js 3D space shooter game with enemies and particles' },
  { ic: '🐍', t: 'Create a FastAPI REST backend with JWT auth and CRUD endpoints' },
  { ic: '📐', t: 'Find the derivative of x³ sin(x) step by step' },
  { ic: '🌙', t: 'Write a Roblox Luau combat system with dash, block, and combo attacks' },
  { ic: '🌍', t: 'What are the 8 planets and their key scientific facts?' },
  { ic: '🧠', t: 'Build a RAG chatbot with LangChain, Pinecone and vector search' },
  { ic: '🎨', t: 'Create a landing page with glassmorphism and Framer Motion animations' },
]

type Msg = { role: 'user' | 'assistant'; content: string }

export default function ChatPanel() {
  const [msgs, setMsgs] = useState<Msg[]>([
    { role: 'assistant', content: "Hey! I'm **Omni AI** — powered by Claude Sonnet 4.6. I can write code (React, Next.js, Python, Lua), explain math and science, answer anything, and generate v0.dev-style components with Framer Motion. What do you need? 🚀" },
  ])
  const [input, setInput] = useState('')
  const [loading, setLoading] = useState(false)
  const msgsRef = useRef<HTMLDivElement>(null)
  const inputRef = useRef<HTMLTextAreaElement>(null)

  useEffect(() => { if (msgsRef.current) msgsRef.current.scrollTop = msgsRef.current.scrollHeight }, [msgs, loading])

  const send = async (text?: string) => {
    const txt = (text || input).trim()
    if (!txt || loading) return
    setInput('')
    const history: Msg[] = [...msgs, { role: 'user', content: txt }]
    setMsgs(history)
    setLoading(true)
    try {
      const r = await fetch('/api/chat', { method: 'POST', headers: { 'Content-Type': 'application/json' }, body: JSON.stringify({ messages: history }) })
      const d = await r.json()
      setMsgs([...history, { role: 'assistant', content: d.reply || d.error || 'Something went wrong.' }])
    } catch {
      setMsgs([...history, { role: 'assistant', content: 'Connection error. Please try again.' }])
    } finally { setLoading(false) }
  }

  return (
    <div className="flex gap-5" style={{ height: 580 }}>
      <div className="glass rounded-2xl overflow-hidden flex flex-col neon-v flex-1" style={{ border: '1px solid rgba(124,58,237,.2)' }}>
        <div className="flex items-center gap-3 px-5 py-3" style={{ background: 'rgba(0,0,0,.3)', borderBottom: '1px solid rgba(255,255,255,.06)' }}>
          <div className="w-9 h-9 rounded-full flex items-center justify-center font-black text-sm" style={{ background: 'linear-gradient(135deg,var(--c),var(--v))', color: '#000' }}>O</div>
          <div>
            <div className="text-sm font-bold">Omni AI</div>
            <div className="text-xs flex items-center gap-1" style={{ color: '#10b981' }}>
              <span className="pulse-dot inline-block w-1.5 h-1.5 rounded-full" style={{ background: '#10b981' }}></span>
              Claude Sonnet 4.6 · Pollinations AI · Free
            </div>
          </div>
        </div>
        <div ref={msgsRef} className="flex-1 overflow-y-auto p-4 flex flex-col gap-3" style={{ scrollBehavior: 'smooth' }}>
          {msgs.map((m, i) => (
            <div key={i} className={`msg msg-${m.role === 'assistant' ? 'ai' : 'user'}`}>
              <div className={`bubble ${m.role === 'assistant' ? 'bubble-ai' : 'bubble-user'}`}
                dangerouslySetInnerHTML={{ __html: m.role === 'assistant' ? mdRender(m.content) : m.content.replace(/&/g,'&amp;').replace(/</g,'&lt;').replace(/>/g,'&gt;') }} />
            </div>
          ))}
          {loading && (
            <div className="msg msg-ai">
              <div className="bubble bubble-ai">
                <div className="typing-dots flex gap-1 items-center">
                  <span></span><span></span><span></span>
                </div>
              </div>
            </div>
          )}
        </div>
        <div className="flex gap-2 p-3" style={{ borderTop: '1px solid rgba(255,255,255,.06)', background: 'rgba(0,0,0,.3)' }}>
          <textarea ref={inputRef} value={input} onChange={e => setInput(e.target.value)}
            onKeyDown={e => { if (e.key === 'Enter' && !e.shiftKey) { e.preventDefault(); send() } }}
            rows={1} placeholder="Ask anything — code, math, React, games, science..."
            className="ai-input" style={{ maxHeight: 120, resize: 'none' }} />
          <button onClick={() => send()} disabled={loading}
            className="w-11 h-11 rounded-xl flex items-center justify-center font-black text-black transition-all hover:scale-110 flex-shrink-0"
            style={{ background: 'linear-gradient(135deg,var(--c),var(--v))' }}>↑</button>
        </div>
      </div>
      <div className="hidden md:block flex-shrink-0 overflow-y-auto" style={{ width: 240 }}>
        <div className="text-sm font-bold mb-2 text-white">Quick prompts</div>
        <div className="flex flex-col gap-2">
          {QUICK_PROMPTS.map((q, i) => (
            <div key={i} className="glass rounded-xl p-2.5 text-xs cursor-pointer transition-all flex gap-2 items-start"
              style={{ border: '1px solid rgba(255,255,255,.08)', color: 'var(--text)' }}
              onMouseEnter={e => (e.currentTarget as HTMLElement).style.borderColor = 'rgba(124,58,237,.4)'}
              onMouseLeave={e => (e.currentTarget as HTMLElement).style.borderColor = 'rgba(255,255,255,.08)'}
              onClick={() => send(q.t)}>
              <span className="flex-shrink-0">{q.ic}</span><span>{q.t}</span>
            </div>
          ))}
        </div>
      </div>
    </div>
  )
}
