"""
Nano AI Code Generator – produces complete, production-quality scripts
for any language, UI, CSS animations, Three.js 3D, Roblox, and more.
"""

import re
import random

# ─── Template registry ────────────────────────────────────────────────────────

def generate(request: str) -> str:
    """Route a generation request to the right template."""
    t = request.lower()

    # Crazy / wild / insane UI
    if any(k in t for k in ["crazy", "wild", "insane", "epic", "cool", "awesome", "sick", "fire",
                              "neon", "cyberpunk", "veo", "vo ai", "futuristic", "glitch", "matrix",
                              "particle", "galaxy", "cosmic", "extreme"]):
        return _gen_crazy_ui(t)

    # 3D / Three.js
    if any(k in t for k in ["3d", "three.js", "threejs", "three js", "webgl", "cube", "scene"]):
        return _gen_threejs(t)

    # React / Next.js / Tailwind / shadcn/ui / v0-style (must be before generic UI)
    if any(k in t for k in ["react", "next.js", "nextjs", "tailwind", "shadcn", "framer", "v0", "component"]):
        return _gen_react_shadcn(t)

    # Animation
    if any(k in t for k in ["animation", "animate", "css anim", "keyframe", "transition", "loading spinner", "spinner"]):
        return _gen_css_animation(t)

    # UI / website / landing page
    if any(k in t for k in ["ui", "landing page", "website", "webpage", "dashboard", "portfolio", "card", "navbar", "modal"]):
        return _gen_html_ui(t)

    # Roblox / Lua game script
    if any(k in t for k in ["roblox", "luau", "obby", "gui", "roblox script", "roblox game"]):
        return _gen_roblox(t)

    # Python scripts
    if any(k in t for k in ["python", "flask", "fastapi", "django", "scraper", "web scraper"]):
        return _gen_python(t)

    # JavaScript / Node
    if any(k in t for k in ["javascript", "node", "express", "vue"]):
        return _gen_javascript(t)

    # REST API
    if any(k in t for k in ["api", "rest api", "endpoint", "server", "backend"]):
        return _gen_rest_api(t)

    # Database
    if any(k in t for k in ["sql", "database", "sqlite", "mysql", "postgres", "schema"]):
        return _gen_sql(t)

    # General: just produce an example in the best matching language
    return _gen_general(request)


# ─── Crazy / Wild UI ─────────────────────────────────────────────────────────

def _gen_crazy_ui(hint: str) -> str:
    if "glitch" in hint or "matrix" in hint:
        return _wrap_output("Matrix Glitch UI", "html", _crazy_glitch())
    if "galaxy" in hint or "cosmic" in hint or "space" in hint:
        return _wrap_output("Cosmic Galaxy UI", "html", _crazy_galaxy())
    if "cyberpunk" in hint or "neon" in hint:
        return _wrap_output("Cyberpunk Neon UI", "html", _crazy_cyberpunk())
    # default: the full mega UI
    return _wrap_output("MEGA Animated UI (Particle + Neon + 3D)", "html", _crazy_mega())


def _crazy_mega() -> str:
    return """<!DOCTYPE html>
<html lang="en">
<head>
<meta charset="UTF-8">
<meta name="viewport" content="width=device-width, initial-scale=1.0">
<title>NANO AI — MEGA UI</title>
<style>
@import url('https://fonts.googleapis.com/css2?family=Orbitron:wght@400;700;900&family=Inter:wght@300;400;600&display=swap');

:root {
  --p1: #7c3aed; --p2: #6c63ff; --a1: #ff6584; --a2: #ff4da6;
  --g1: #00ff88; --g2: #00d4ff; --y1: #ffd700;
  --bg: #03010a; --s1: #0d0820; --s2: #140d2e;
  --text: #f0ecff; --muted: #6b6494;
}
*,*::before,*::after{box-sizing:border-box;margin:0;padding:0}
html{scroll-behavior:smooth}
body{background:var(--bg);color:var(--text);font-family:'Inter',sans-serif;overflow-x:hidden}

/* ── Canvas particle field ─────────────────────────────── */
#particles{position:fixed;top:0;left:0;width:100%;height:100%;z-index:0;pointer-events:none}

/* ── Animated gradient mesh background ────────────────── */
.mesh{
  position:fixed;top:0;left:0;width:100%;height:100%;z-index:0;pointer-events:none;
  background:
    radial-gradient(ellipse at 20% 50%, rgba(108,99,255,.15) 0%, transparent 50%),
    radial-gradient(ellipse at 80% 20%, rgba(255,101,132,.12) 0%, transparent 50%),
    radial-gradient(ellipse at 60% 80%, rgba(0,212,255,.10) 0%, transparent 50%);
  animation:meshMove 8s ease-in-out infinite alternate;
}
@keyframes meshMove{
  0%  {background-position:0% 0%, 100% 0%,  50% 100%}
  100%{background-position:100% 100%,0% 100%,50% 0%}
}

/* ── Main content ──────────────────────────────────────── */
.content{position:relative;z-index:1}

/* ── Nav ───────────────────────────────────────────────── */
nav{
  position:fixed;top:0;width:100%;z-index:100;
  padding:16px 48px;
  display:flex;justify-content:space-between;align-items:center;
  background:rgba(3,1,10,.7);backdrop-filter:blur(20px);
  border-bottom:1px solid rgba(108,99,255,.2);
}
.logo{
  font-family:'Orbitron',sans-serif;font-size:1.3rem;font-weight:900;
  background:linear-gradient(90deg,var(--p2),var(--a1),var(--g2));
  -webkit-background-clip:text;-webkit-text-fill-color:transparent;
  background-clip:text;letter-spacing:4px;
  animation:logoShimmer 3s linear infinite;
  background-size:200% 100%;
}
@keyframes logoShimmer{0%{background-position:0% 50%}100%{background-position:200% 50%}}
.nav-links{display:flex;gap:28px;list-style:none}
.nav-links a{color:var(--muted);text-decoration:none;font-size:.85rem;letter-spacing:1px;transition:all .3s;text-transform:uppercase}
.nav-links a:hover{color:var(--text);text-shadow:0 0 12px var(--p2)}
.nav-cta{
  padding:10px 22px;font-family:'Orbitron',sans-serif;font-size:.75rem;font-weight:700;
  letter-spacing:2px;text-transform:uppercase;
  background:transparent;
  border:1px solid var(--p2);color:var(--p2);
  cursor:pointer;border-radius:4px;
  position:relative;overflow:hidden;transition:all .3s;
}
.nav-cta::before{
  content:'';position:absolute;top:0;left:-100%;width:100%;height:100%;
  background:linear-gradient(90deg,transparent,rgba(108,99,255,.3),transparent);
  transition:left .4s;
}
.nav-cta:hover::before{left:100%}
.nav-cta:hover{background:rgba(108,99,255,.15);box-shadow:0 0 20px rgba(108,99,255,.4)}

/* ── Hero ──────────────────────────────────────────────── */
.hero{
  min-height:100vh;display:flex;align-items:center;justify-content:center;
  text-align:center;padding:120px 40px 80px;flex-direction:column;gap:0;
}
.hero-eyebrow{
  font-family:'Orbitron',sans-serif;font-size:.7rem;letter-spacing:6px;
  text-transform:uppercase;color:var(--p2);margin-bottom:24px;
  animation:fadeUp .8s ease both;
}
.hero-title{
  font-family:'Orbitron',sans-serif;
  font-size:clamp(3rem,8vw,7rem);font-weight:900;line-height:1;
  margin-bottom:24px;
  animation:fadeUp .8s .1s ease both;
}
.hero-title .line1{
  display:block;
  background:linear-gradient(135deg,#fff 0%,var(--p2) 50%,var(--a1) 100%);
  -webkit-background-clip:text;-webkit-text-fill-color:transparent;background-clip:text;
}
.hero-title .line2{
  display:block;font-size:.55em;color:var(--muted);margin-top:8px;
  -webkit-text-fill-color:var(--muted);
}
.hero-glitch{
  position:relative;display:inline-block;
  background:linear-gradient(90deg,var(--g2),var(--g1));
  -webkit-background-clip:text;-webkit-text-fill-color:transparent;background-clip:text;
  animation:glitchColor 4s infinite;
}
.hero-glitch::before,.hero-glitch::after{
  content:attr(data-text);position:absolute;top:0;left:0;width:100%;height:100%;
  background:linear-gradient(90deg,var(--g2),var(--g1));
  -webkit-background-clip:text;-webkit-text-fill-color:transparent;background-clip:text;
}
.hero-glitch::before{
  animation:glitch1 3s infinite;clip-path:polygon(0 0,100% 0,100% 35%,0 35%);
  transform:translateX(-2px);
}
.hero-glitch::after{
  animation:glitch2 3s infinite;clip-path:polygon(0 65%,100% 65%,100% 100%,0 100%);
  transform:translateX(2px);
}
@keyframes glitch1{0%,90%,100%{transform:translateX(-2px) skew(0)}93%{transform:translateX(4px) skew(-5deg)}}
@keyframes glitch2{0%,90%,100%{transform:translateX(2px) skew(0)}93%{transform:translateX(-4px) skew(5deg)}}
@keyframes glitchColor{0%,89%,100%{filter:hue-rotate(0deg)}90%{filter:hue-rotate(90deg)}}

.hero-sub{
  font-size:1.1rem;color:var(--muted);max-width:600px;line-height:1.8;
  margin-bottom:48px;animation:fadeUp .8s .2s ease both;
}
.hero-sub em{font-style:normal;color:var(--text)}

.hero-btns{
  display:flex;gap:16px;flex-wrap:wrap;justify-content:center;
  animation:fadeUp .8s .3s ease both;
}
.btn-primary{
  padding:16px 36px;font-family:'Orbitron',sans-serif;font-size:.8rem;font-weight:700;
  letter-spacing:2px;text-transform:uppercase;
  background:linear-gradient(135deg,var(--p1),var(--p2));
  border:none;color:#fff;border-radius:6px;cursor:pointer;
  position:relative;overflow:hidden;transition:all .3s;
  box-shadow:0 0 30px rgba(108,99,255,.4);
}
.btn-primary::after{
  content:'';position:absolute;top:-50%;left:-50%;width:200%;height:200%;
  background:conic-gradient(transparent 270deg,rgba(255,255,255,.15),transparent);
  animation:spin2 2s linear infinite;
}
@keyframes spin2{to{transform:rotate(360deg)}}
.btn-primary:hover{transform:translateY(-3px);box-shadow:0 0 60px rgba(108,99,255,.6)}
.btn-ghost{
  padding:16px 36px;font-family:'Orbitron',sans-serif;font-size:.8rem;font-weight:700;
  letter-spacing:2px;text-transform:uppercase;
  background:transparent;border:1px solid rgba(255,255,255,.15);
  color:var(--text);border-radius:6px;cursor:pointer;transition:all .3s;
}
.btn-ghost:hover{border-color:var(--p2);background:rgba(108,99,255,.1);transform:translateY(-3px)}

.hero-scroll{
  margin-top:64px;display:flex;flex-direction:column;align-items:center;gap:8px;
  color:var(--muted);font-size:.75rem;letter-spacing:2px;text-transform:uppercase;
  animation:fadeUp .8s .5s ease both;
}
.scroll-line{
  width:1px;height:50px;background:linear-gradient(to bottom,var(--p2),transparent);
  animation:scrollPulse 1.5s ease-in-out infinite;
}
@keyframes scrollPulse{0%,100%{opacity:1;transform:scaleY(1)}50%{opacity:.4;transform:scaleY(.6)}}
@keyframes fadeUp{from{opacity:0;transform:translateY(30px)}to{opacity:1;transform:translateY(0)}}

/* ── Floating stat chips ────────────────────────────────── */
.stat-chips{
  position:absolute;right:60px;top:50%;transform:translateY(-50%);
  display:flex;flex-direction:column;gap:12px;
  animation:fadeUp .8s .4s ease both;
}
.chip{
  padding:10px 16px;background:rgba(255,255,255,.04);
  border:1px solid rgba(108,99,255,.2);border-radius:8px;
  display:flex;align-items:center;gap:10px;font-size:.8rem;
  backdrop-filter:blur(8px);
}
.chip-dot{width:8px;height:8px;border-radius:50%;animation:dotPulse 2s ease-in-out infinite}
.chip-dot.green{background:var(--g1);box-shadow:0 0 8px var(--g1)}
.chip-dot.blue{background:var(--g2);box-shadow:0 0 8px var(--g2);animation-delay:.5s}
.chip-dot.pink{background:var(--a1);box-shadow:0 0 8px var(--a1);animation-delay:1s}
@keyframes dotPulse{0%,100%{opacity:1;transform:scale(1)}50%{opacity:.4;transform:scale(.7)}}

/* ── Features grid ──────────────────────────────────────── */
.features{padding:120px 48px;max-width:1200px;margin:0 auto}
.section-title{
  font-family:'Orbitron',sans-serif;font-size:clamp(1.5rem,3vw,2.5rem);
  font-weight:700;text-align:center;margin-bottom:64px;
  background:linear-gradient(135deg,#fff,var(--muted));
  -webkit-background-clip:text;-webkit-text-fill-color:transparent;background-clip:text;
}
.section-title span{
  background:linear-gradient(90deg,var(--p2),var(--a1));
  -webkit-background-clip:text;-webkit-text-fill-color:transparent;background-clip:text;
}
.feat-grid{display:grid;grid-template-columns:repeat(auto-fit,minmax(300px,1fr));gap:20px}
.feat-card{
  background:linear-gradient(135deg,rgba(13,8,32,.9),rgba(20,13,46,.9));
  border:1px solid rgba(108,99,255,.15);border-radius:16px;padding:32px;
  position:relative;overflow:hidden;
  transition:transform .3s,border-color .3s,box-shadow .3s;
  cursor:default;
}
.feat-card::before{
  content:'';position:absolute;top:0;left:0;right:0;height:1px;
  background:linear-gradient(90deg,transparent,var(--p2),transparent);
  opacity:0;transition:opacity .3s;
}
.feat-card:hover{
  transform:translateY(-8px) scale(1.01);
  border-color:rgba(108,99,255,.5);
  box-shadow:0 20px 60px rgba(108,99,255,.2),inset 0 1px 0 rgba(108,99,255,.2);
}
.feat-card:hover::before{opacity:1}
.feat-card:nth-child(2){border-color:rgba(255,101,132,.15)}
.feat-card:nth-child(2):hover{border-color:rgba(255,101,132,.5);box-shadow:0 20px 60px rgba(255,101,132,.2)}
.feat-card:nth-child(3){border-color:rgba(0,212,255,.15)}
.feat-card:nth-child(3):hover{border-color:rgba(0,212,255,.5);box-shadow:0 20px 60px rgba(0,212,255,.2)}
.feat-num{
  font-family:'Orbitron',sans-serif;font-size:3.5rem;font-weight:900;
  position:absolute;top:16px;right:24px;
  background:linear-gradient(135deg,rgba(255,255,255,.06),transparent);
  -webkit-background-clip:text;-webkit-text-fill-color:transparent;background-clip:text;
}
.feat-icon{font-size:2.2rem;margin-bottom:16px;display:block}
.feat-card h3{font-family:'Orbitron',sans-serif;font-size:.9rem;font-weight:700;letter-spacing:2px;text-transform:uppercase;margin-bottom:12px;color:var(--text)}
.feat-card p{color:var(--muted);font-size:.9rem;line-height:1.7}
.feat-tag{
  display:inline-block;margin-top:16px;padding:3px 10px;
  border-radius:4px;font-size:.7rem;letter-spacing:1px;text-transform:uppercase;
}
.tag-purple{background:rgba(108,99,255,.15);color:var(--p2);border:1px solid rgba(108,99,255,.3)}
.tag-pink{background:rgba(255,101,132,.15);color:var(--a1);border:1px solid rgba(255,101,132,.3)}
.tag-cyan{background:rgba(0,212,255,.1);color:var(--g2);border:1px solid rgba(0,212,255,.2)}

/* ── Stats row ──────────────────────────────────────────── */
.stats-row{
  display:flex;flex-wrap:wrap;gap:1px;
  background:rgba(108,99,255,.1);border:1px solid rgba(108,99,255,.15);
  border-radius:16px;overflow:hidden;margin:80px 48px;
}
.stat{
  flex:1;min-width:180px;padding:40px 32px;
  background:var(--bg);text-align:center;
  transition:background .3s;
}
.stat:hover{background:rgba(108,99,255,.05)}
.stat-num{
  font-family:'Orbitron',sans-serif;font-size:2.5rem;font-weight:900;
  background:linear-gradient(135deg,var(--p2),var(--a1));
  -webkit-background-clip:text;-webkit-text-fill-color:transparent;background-clip:text;
}
.stat-label{color:var(--muted);font-size:.8rem;letter-spacing:2px;text-transform:uppercase;margin-top:6px}

/* ── Terminal demo ──────────────────────────────────────── */
.terminal-wrap{padding:0 48px 120px;max-width:900px;margin:0 auto}
.terminal{
  background:rgba(5,3,15,.95);border:1px solid rgba(108,99,255,.3);
  border-radius:12px;overflow:hidden;
  box-shadow:0 0 80px rgba(108,99,255,.2);
}
.term-header{
  padding:12px 16px;background:rgba(13,8,32,.8);
  display:flex;align-items:center;gap:8px;
  border-bottom:1px solid rgba(108,99,255,.15);
}
.term-dot{width:12px;height:12px;border-radius:50%}
.term-dot.r{background:#ff5f56}.term-dot.y{background:#ffbd2e}.term-dot.g{background:#27c93f}
.term-title{flex:1;text-align:center;font-size:.75rem;color:var(--muted);letter-spacing:2px}
.term-body{padding:24px;font-family:'Courier New',monospace;font-size:.85rem;line-height:1.8}
.term-line{display:flex;gap:12px;margin-bottom:4px}
.term-prompt{color:var(--p2)}.term-cmd{color:var(--text)}
.term-out{color:var(--muted);padding-left:20px;margin-bottom:4px}
.term-out.green{color:var(--g1)}.term-out.cyan{color:var(--g2)}.term-out.pink{color:var(--a1)}
.cursor{
  display:inline-block;width:10px;height:1.1em;background:var(--p2);
  vertical-align:middle;margin-left:4px;animation:blink .8s step-end infinite;
}
@keyframes blink{0%,100%{opacity:1}50%{opacity:0}}

/* ── CTA ────────────────────────────────────────────────── */
.cta-section{
  padding:120px 40px;text-align:center;
  background:radial-gradient(ellipse at center,rgba(108,99,255,.15) 0%,transparent 70%);
}
.cta-section h2{
  font-family:'Orbitron',sans-serif;font-size:clamp(1.8rem,4vw,3.5rem);font-weight:900;
  margin-bottom:20px;letter-spacing:2px;
}
.cta-section p{color:var(--muted);font-size:1.1rem;max-width:500px;margin:0 auto 40px}
.cta-glow{
  padding:18px 48px;font-family:'Orbitron',sans-serif;font-size:.85rem;font-weight:700;
  letter-spacing:3px;text-transform:uppercase;
  background:linear-gradient(135deg,var(--p1),var(--p2),var(--a1));
  border:none;color:#fff;border-radius:8px;cursor:pointer;
  box-shadow:0 0 40px rgba(108,99,255,.5),0 0 80px rgba(108,99,255,.2);
  transition:all .3s;background-size:200% 100%;
  animation:gradShift 3s ease infinite;
}
@keyframes gradShift{0%{background-position:0% 50%}50%{background-position:100% 50%}100%{background-position:0% 50%}}
.cta-glow:hover{transform:translateY(-4px) scale(1.03);box-shadow:0 0 80px rgba(108,99,255,.7),0 0 160px rgba(255,101,132,.3)}

/* ── Scanlines overlay ──────────────────────────────────── */
.scanlines{
  position:fixed;top:0;left:0;width:100%;height:100%;
  background:repeating-linear-gradient(0deg,transparent,transparent 2px,rgba(0,0,0,.03) 2px,rgba(0,0,0,.03) 4px);
  pointer-events:none;z-index:999;
}
</style>
</head>
<body>
<canvas id="particles"></canvas>
<div class="mesh"></div>
<div class="scanlines"></div>

<div class="content">
  <!-- NAV -->
  <nav>
    <div class="logo">NANO AI</div>
    <ul class="nav-links">
      <li><a href="#">Learn</a></li>
      <li><a href="#">Generate</a></li>
      <li><a href="#">WebFetch</a></li>
      <li><a href="#">About</a></li>
    </ul>
    <button class="nav-cta">Launch →</button>
  </nav>

  <!-- HERO -->
  <section class="hero">
    <div class="stat-chips">
      <div class="chip"><span class="chip-dot green"></span>Claude API Active</div>
      <div class="chip"><span class="chip-dot blue"></span>WebFetch Online</div>
      <div class="chip"><span class="chip-dot pink"></span>All Languages</div>
    </div>
    <p class="hero-eyebrow">// The Future of Coding Education</p>
    <h1 class="hero-title">
      <span class="line1">NANO AI</span>
      <span class="line2">Powered by</span>
    </h1>
    <h1 class="hero-title" style="margin-top:-20px">
      <span class="hero-glitch" data-text="CLAUDE">CLAUDE</span>
    </h1>
    <p class="hero-sub">
      The <em>smartest coding AI ever built</em>. Teaches every language,
      generates production code, browses the web, and thinks like Claude.
    </p>
    <div class="hero-btns">
      <button class="btn-primary">Get Started →</button>
      <button class="btn-ghost">View Demo</button>
    </div>
    <div class="hero-scroll">
      <span>Scroll</span>
      <div class="scroll-line"></div>
    </div>
  </section>

  <!-- FEATURES -->
  <section class="features">
    <h2 class="section-title">Everything you need to <span>master code</span></h2>
    <div class="feat-grid">
      <div class="feat-card">
        <div class="feat-num">01</div>
        <span class="feat-icon">🧠</span>
        <h3>Claude-Powered Brain</h3>
        <p>Every question routes through Claude, the world's most capable AI. Get accurate, nuanced answers to any coding question — no topic is off limits.</p>
        <span class="feat-tag tag-purple">AI Engine</span>
      </div>
      <div class="feat-card">
        <div class="feat-num">02</div>
        <span class="feat-icon">⚡</span>
        <h3>Instant Code Generator</h3>
        <p>Generate complete, production-quality scripts instantly. 3D scenes, animated UIs, Roblox games, REST APIs, data pipelines — anything.</p>
        <span class="feat-tag tag-pink">Code Gen</span>
      </div>
      <div class="feat-card">
        <div class="feat-num">03</div>
        <span class="feat-icon">🌐</span>
        <h3>Real WebFetch</h3>
        <p>Nano AI browses the internet. Search docs, fetch any URL, get real-time information from the web without leaving the terminal.</p>
        <span class="feat-tag tag-cyan">Live Web</span>
      </div>
      <div class="feat-card">
        <div class="feat-num">04</div>
        <span class="feat-icon">🎯</span>
        <h3>XP & Level System</h3>
        <p>Earn XP through exercises and quizzes. Level up from Novice to Wizard. Track progress with persistent memory across every session.</p>
        <span class="feat-tag tag-purple">Gamified</span>
      </div>
      <div class="feat-card">
        <div class="feat-num">05</div>
        <span class="feat-icon">📁</span>
        <h3>File System Access</h3>
        <p>Read, write, and analyze code files directly. Nano AI can inspect your project, understand your code, and suggest improvements.</p>
        <span class="feat-tag tag-pink">File I/O</span>
      </div>
      <div class="feat-card">
        <div class="feat-num">06</div>
        <span class="feat-icon">🔄</span>
        <h3>Persistent Memory</h3>
        <p>Nano AI remembers you. Your name, preferred language, mastered topics, and total XP are saved and restored every session.</p>
        <span class="feat-tag tag-cyan">Memory</span>
      </div>
    </div>
  </section>

  <!-- STATS -->
  <div class="stats-row">
    <div class="stat"><div class="stat-num" data-target="10">0</div><div class="stat-label">Languages</div></div>
    <div class="stat"><div class="stat-num" data-target="14">0</div><div class="stat-label">CS Concepts</div></div>
    <div class="stat"><div class="stat-num" data-target="16">0</div><div class="stat-label">Exercises</div></div>
    <div class="stat"><div class="stat-num" data-target="7">0</div><div class="stat-label">XP Levels</div></div>
    <div class="stat"><div class="stat-num" data-target="∞">0</div><div class="stat-label">Questions</div></div>
  </div>

  <!-- TERMINAL DEMO -->
  <div class="terminal-wrap">
    <div class="terminal">
      <div class="term-header">
        <div class="term-dot r"></div><div class="term-dot y"></div><div class="term-dot g"></div>
        <div class="term-title">NANO AI — TERMINAL</div>
      </div>
      <div class="term-body">
        <div class="term-line"><span class="term-prompt">nano@ai</span><span style="color:#555">:~$</span><span class="term-cmd"> python -m ai_tutor</span></div>
        <div class="term-out green">✦ FULL AI MODE  — Claude API active. Ask me literally anything.</div>
        <div class="term-out"></div>
        <div class="term-line"><span class="term-prompt">Nano AI ›</span><span class="term-cmd"> generate a 3D rotating sphere</span></div>
        <div class="term-out cyan">⚡ NANO AI GENERATED — Three.js 3D Scene (sphere)</div>
        <div class="term-out">  Language: html   Lines: 98</div>
        <div class="term-out">  Saved to sphere.html</div>
        <div class="term-out"></div>
        <div class="term-line"><span class="term-prompt">Nano AI ›</span><span class="term-cmd"> what is the difference between TCP and UDP?</span></div>
        <div class="term-out pink">  TCP (Transmission Control Protocol):</div>
        <div class="term-out">  - Connection-oriented: establishes a handshake before sending data</div>
        <div class="term-out">  - Reliable: guarantees delivery, ordering, and error-checking</div>
        <div class="term-out">  - Slower due to overhead — used for HTTP, email, file transfers</div>
        <div class="term-out"></div>
        <div class="term-out pink">  UDP (User Datagram Protocol):</div>
        <div class="term-out">  - Connectionless: fire-and-forget, no handshake</div>
        <div class="term-out">  - Faster, no delivery guarantee — used for video, gaming, DNS</div>
        <div class="term-out"></div>
        <div class="term-line"><span class="term-prompt">Nano AI ›</span><span class="cursor"></span></div>
      </div>
    </div>
  </div>

  <!-- CTA -->
  <section class="cta-section">
    <h2>Ready to become a <br>coding <span style="background:linear-gradient(90deg,#6c63ff,#ff6584);-webkit-background-clip:text;-webkit-text-fill-color:transparent;background-clip:text">wizard?</span></h2>
    <p>One command. Infinite knowledge. Powered by the world's best AI.</p>
    <button class="cta-glow">python -m ai_tutor</button>
  </section>
</div>

<script>
// ── Particle canvas ────────────────────────────────────────────
const canvas = document.getElementById('particles');
const ctx    = canvas.getContext('2d');
let W = canvas.width  = innerWidth;
let H = canvas.height = innerHeight;
let mouse = { x: W/2, y: H/2 };

const COLORS = ['#6c63ff','#ff6584','#00d4ff','#00ff88','#ffd700'];
const particles = Array.from({length: 120}, () => ({
  x: Math.random()*W, y: Math.random()*H,
  vx: (Math.random()-.5)*.4, vy: (Math.random()-.5)*.4,
  r: Math.random()*2+.5,
  c: COLORS[Math.floor(Math.random()*COLORS.length)],
  o: Math.random()*.6+.2,
}));

function drawParticles() {
  ctx.clearRect(0,0,W,H);
  // Draw connections
  for (let i=0; i<particles.length; i++) {
    for (let j=i+1; j<particles.length; j++) {
      const dx = particles[i].x-particles[j].x;
      const dy = particles[i].y-particles[j].y;
      const d  = Math.sqrt(dx*dx+dy*dy);
      if (d < 120) {
        ctx.beginPath();
        ctx.strokeStyle = `rgba(108,99,255,${.15*(1-d/120)})`;
        ctx.lineWidth   = .5;
        ctx.moveTo(particles[i].x, particles[i].y);
        ctx.lineTo(particles[j].x, particles[j].y);
        ctx.stroke();
      }
    }
  }
  // Draw dots
  for (const p of particles) {
    ctx.beginPath();
    ctx.arc(p.x, p.y, p.r, 0, Math.PI*2);
    ctx.fillStyle = p.c + Math.floor(p.o*255).toString(16).padStart(2,'0');
    ctx.fill();
  }
}

function updateParticles() {
  for (const p of particles) {
    p.x += p.vx; p.y += p.vy;
    // mouse repulsion
    const dx = mouse.x-p.x, dy = mouse.y-p.y;
    const d  = Math.sqrt(dx*dx+dy*dy);
    if (d < 100) { p.vx -= dx/d*.05; p.vy -= dy/d*.05; }
    // bounds
    if (p.x<0||p.x>W) p.vx*=-1;
    if (p.y<0||p.y>H) p.vy*=-1;
    // speed limit
    const spd = Math.sqrt(p.vx*p.vx+p.vy*p.vy);
    if (spd > 1.2) { p.vx = p.vx/spd*1.2; p.vy = p.vy/spd*1.2; }
  }
}

(function loop(){
  updateParticles();
  drawParticles();
  requestAnimationFrame(loop);
})();

window.addEventListener('mousemove', e => { mouse.x=e.clientX; mouse.y=e.clientY; });
window.addEventListener('resize',    ()=>{ W=canvas.width=innerWidth; H=canvas.height=innerHeight; });

// ── Counter animation ──────────────────────────────────────────
const counters = document.querySelectorAll('[data-target]');
const io = new IntersectionObserver(entries => {
  entries.forEach(entry => {
    if (!entry.isIntersecting) return;
    const el = entry.target;
    const target = el.dataset.target;
    if (target === '∞') { el.textContent='∞'; return; }
    let current = 0;
    const end = parseInt(target);
    const step = end / 40;
    const timer = setInterval(()=>{
      current = Math.min(current+step, end);
      el.textContent = Math.floor(current) + (current>=end?'+':'');
      if (current >= end) clearInterval(timer);
    }, 40);
    io.unobserve(el);
  });
}, { threshold: .5 });
counters.forEach(c => io.observe(c));

// ── 3D tilt effect on feature cards ───────────────────────────
document.querySelectorAll('.feat-card').forEach(card => {
  card.addEventListener('mousemove', e => {
    const rect = card.getBoundingClientRect();
    const x = (e.clientX - rect.left) / rect.width  - .5;
    const y = (e.clientY - rect.top)  / rect.height - .5;
    card.style.transform = `translateY(-8px) scale(1.01) perspective(600px) rotateY(${x*10}deg) rotateX(${-y*10}deg)`;
  });
  card.addEventListener('mouseleave', () => {
    card.style.transform = '';
  });
});

// ── Typing animation for terminal ─────────────────────────────
// cursor already handled by CSS
</script>
</body>
</html>"""


def _crazy_cyberpunk() -> str:
    return """<!DOCTYPE html>
<html lang="en">
<head>
<meta charset="UTF-8"><title>NANO AI — Cyberpunk</title>
<style>
@import url('https://fonts.googleapis.com/css2?family=Orbitron:wght@400;700;900&display=swap');
*,*::before,*::after{box-sizing:border-box;margin:0;padding:0}
body{
  background:#050008;color:#e0d0ff;
  font-family:'Orbitron',monospace;min-height:100vh;
  overflow-x:hidden;
}
/* Neon grid floor */
.grid-bg{
  position:fixed;bottom:0;left:0;width:100%;height:60vh;
  background:
    linear-gradient(rgba(255,0,255,.03) 1px,transparent 1px),
    linear-gradient(90deg,rgba(255,0,255,.03) 1px,transparent 1px);
  background-size:60px 60px;
  transform:perspective(400px) rotateX(60deg);
  transform-origin:bottom;pointer-events:none;z-index:0;
}
/* Scanlines */
.scan{
  position:fixed;top:0;left:0;width:100%;height:100%;pointer-events:none;z-index:999;
  background:repeating-linear-gradient(0deg,rgba(0,255,255,.02) 0,rgba(0,255,255,.02) 1px,transparent 1px,transparent 3px);
}
/* Neon title */
.neon-title{
  font-size:clamp(3rem,10vw,8rem);font-weight:900;text-align:center;
  padding:120px 40px 20px;position:relative;z-index:1;
  color:#fff;
  text-shadow:
    0 0 7px #fff,0 0 10px #fff,0 0 21px #fff,
    0 0 42px #bc13fe,0 0 82px #bc13fe,
    0 0 92px #bc13fe,0 0 102px #bc13fe;
  animation:neonFlicker 5s infinite;
}
@keyframes neonFlicker{
  0%,18%,22%,25%,53%,57%,100%{
    text-shadow:0 0 7px #fff,0 0 10px #fff,0 0 21px #fff,
      0 0 42px #bc13fe,0 0 82px #bc13fe,0 0 92px #bc13fe,0 0 102px #bc13fe;
  }
  20%,24%,55%{text-shadow:none}
}
.neon-sub{
  text-align:center;font-size:clamp(.6rem,1.5vw,1rem);
  letter-spacing:6px;color:#00ffff;
  text-shadow:0 0 10px #00ffff,0 0 30px #00ffff;
  position:relative;z-index:1;margin-bottom:80px;
  animation:subPulse 2s ease-in-out infinite;
}
@keyframes subPulse{0%,100%{opacity:1}50%{opacity:.6}}
/* Neon cards */
.cards{display:flex;flex-wrap:wrap;gap:24px;justify-content:center;padding:0 40px 80px;position:relative;z-index:1}
.neon-card{
  width:260px;padding:28px;
  background:rgba(5,0,8,.85);
  position:relative;cursor:pointer;transition:transform .3s;
}
.neon-card::before,.neon-card::after{
  content:'';position:absolute;top:0;left:0;right:0;bottom:0;pointer-events:none;
}
.neon-card::before{
  border:1px solid #bc13fe;
  box-shadow:inset 0 0 20px rgba(188,19,254,.2),0 0 20px rgba(188,19,254,.3);
}
.neon-card:nth-child(2)::before{border-color:#00ffff;box-shadow:inset 0 0 20px rgba(0,255,255,.2),0 0 20px rgba(0,255,255,.3)}
.neon-card:nth-child(3)::before{border-color:#ff0080;box-shadow:inset 0 0 20px rgba(255,0,128,.2),0 0 20px rgba(255,0,128,.3)}
.neon-card:hover{transform:translateY(-8px) scale(1.02)}
.card-icon{font-size:2rem;margin-bottom:12px}
.card-title{font-size:.8rem;letter-spacing:3px;text-transform:uppercase;margin-bottom:10px;color:#bc13fe;text-shadow:0 0 8px #bc13fe}
.neon-card:nth-child(2) .card-title{color:#00ffff;text-shadow:0 0 8px #00ffff}
.neon-card:nth-child(3) .card-title{color:#ff0080;text-shadow:0 0 8px #ff0080}
.card-text{font-size:.75rem;line-height:1.7;color:rgba(224,208,255,.6);font-family:'Courier New',monospace}
/* Neon line divider */
.neon-line{
  width:80%;max-width:600px;height:1px;margin:0 auto 60px;
  background:linear-gradient(90deg,transparent,#bc13fe,#00ffff,#ff0080,transparent);
  position:relative;z-index:1;
  box-shadow:0 0 10px #bc13fe,0 0 20px #00ffff;
  animation:lineScan 3s ease-in-out infinite;
}
@keyframes lineScan{0%{opacity:.4}50%{opacity:1}100%{opacity:.4}}
/* CTA button */
.neon-btn{
  display:block;width:fit-content;margin:0 auto 80px;
  padding:16px 48px;font-size:.85rem;letter-spacing:4px;text-transform:uppercase;
  background:transparent;
  border:1px solid #00ffff;color:#00ffff;cursor:pointer;
  position:relative;z-index:1;transition:all .3s;
  text-shadow:0 0 10px #00ffff;box-shadow:0 0 20px rgba(0,255,255,.3);
}
.neon-btn:hover{
  background:rgba(0,255,255,.1);box-shadow:0 0 40px rgba(0,255,255,.6);
  transform:translateY(-3px);
}
</style>
</head>
<body>
<div class="grid-bg"></div>
<div class="scan"></div>
<h1 class="neon-title">NANO AI</h1>
<p class="neon-sub">// POWERED BY CLAUDE — FULL AI MODE ONLINE</p>
<div class="neon-line"></div>
<div class="cards">
  <div class="neon-card">
    <div class="card-icon">🧠</div>
    <div class="card-title">AI Brain</div>
    <div class="card-text">Claude API integration. Answers any question. No topic out of bounds. Full conversation history.</div>
  </div>
  <div class="neon-card">
    <div class="card-icon">⚡</div>
    <div class="card-title">Code Gen</div>
    <div class="card-text">Generate 3D scenes, UIs, Roblox scripts, APIs, scrapers. Production-ready in seconds.</div>
  </div>
  <div class="neon-card">
    <div class="card-icon">🌐</div>
    <div class="card-title">WebFetch</div>
    <div class="card-text">Real internet access. DuckDuckGo search. Fetch any URL. Live documentation retrieval.</div>
  </div>
</div>
<button class="neon-btn">[ ENTER NANO AI ]</button>
</body>
</html>"""


def _crazy_glitch() -> str:
    return """<!DOCTYPE html>
<html lang="en">
<head>
<meta charset="UTF-8"><title>NANO AI — Matrix Glitch</title>
<style>
@import url('https://fonts.googleapis.com/css2?family=Share+Tech+Mono&display=swap');
*{box-sizing:border-box;margin:0;padding:0}
body{background:#000;color:#0f0;font-family:'Share Tech Mono',monospace;overflow:hidden;height:100vh}
canvas#matrix{position:fixed;top:0;left:0;z-index:0}
.overlay{
  position:relative;z-index:1;
  display:flex;flex-direction:column;align-items:center;justify-content:center;
  height:100vh;text-align:center;padding:40px;
}
.glitch-title{
  font-size:clamp(2.5rem,8vw,6rem);font-weight:bold;
  color:#0f0;text-shadow:0 0 10px #0f0;
  position:relative;letter-spacing:8px;
  animation:glitchMain 4s infinite;
}
.glitch-title::before{
  content:'NANO AI';position:absolute;left:3px;top:0;width:100%;
  color:#0f0;text-shadow:-2px 0 #ff0080;clip-path:polygon(0 30%,100% 30%,100% 50%,0 50%);
  animation:glitchSlice1 3s infinite;
}
.glitch-title::after{
  content:'NANO AI';position:absolute;left:-3px;top:0;width:100%;
  color:#0f0;text-shadow:2px 0 #00ffff;clip-path:polygon(0 60%,100% 60%,100% 80%,0 80%);
  animation:glitchSlice2 3s infinite;
}
@keyframes glitchMain{0%,89%,100%{filter:none}90%{filter:hue-rotate(180deg) brightness(1.5)}93%{filter:invert(.3)}}
@keyframes glitchSlice1{0%,90%,100%{transform:translate(0)}91%{transform:translate(-6px,2px)}93%{transform:translate(4px,-1px)}}
@keyframes glitchSlice2{0%,90%,100%{transform:translate(0)}92%{transform:translate(6px,1px)}94%{transform:translate(-3px,2px)}}
.sub{
  margin-top:16px;font-size:clamp(.7rem,1.5vw,.95rem);
  letter-spacing:4px;color:#0a0;
  text-shadow:0 0 8px #0f0;
  animation:typeSub 3s steps(40) both;overflow:hidden;white-space:nowrap;
}
@keyframes typeSub{from{width:0}to{width:100%}}
.stats{margin-top:48px;display:flex;gap:32px;flex-wrap:wrap;justify-content:center}
.stat{border:1px solid #0a0;padding:12px 20px;text-shadow:0 0 6px #0f0}
.stat-n{font-size:1.8rem;color:#0f0}
.stat-l{font-size:.65rem;letter-spacing:2px;color:#0a0;margin-top:4px}
.cmd{
  margin-top:48px;font-size:.9rem;padding:12px 24px;
  background:rgba(0,255,0,.05);border:1px solid #0a0;
  color:#0f0;text-shadow:0 0 8px #0f0;cursor:pointer;
  transition:all .2s;letter-spacing:2px;
}
.cmd:hover{background:rgba(0,255,0,.15);box-shadow:0 0 20px rgba(0,255,0,.3)}
</style>
</head>
<body>
<canvas id="matrix"></canvas>
<div class="overlay">
  <h1 class="glitch-title">NANO AI</h1>
  <p class="sub">&gt; POWERED_BY_CLAUDE // KNOWS_EVERYTHING // FULLY_ONLINE</p>
  <div class="stats">
    <div class="stat"><div class="stat-n">10+</div><div class="stat-l">LANGUAGES</div></div>
    <div class="stat"><div class="stat-n">∞</div><div class="stat-l">ANSWERS</div></div>
    <div class="stat"><div class="stat-n">100%</div><div class="stat-l">OFFLINE OK</div></div>
    <div class="stat"><div class="stat-n">0ms</div><div class="stat-l">DELAY*</div></div>
  </div>
  <button class="cmd">> python -m ai_tutor _</button>
</div>
<script>
const c = document.getElementById('matrix');
const x = c.getContext('2d');
c.width = innerWidth; c.height = innerHeight;
const cols = Math.floor(c.width/16)+1;
const drops = Array(cols).fill(1);
const chars = 'アイウエオカキクケコサシスセソタチツテトナニヌネノハヒフヘホマミムメモヤユヨラリルレロワヲン0123456789ABCDEF';
function draw(){
  x.fillStyle='rgba(0,0,0,.05)';
  x.fillRect(0,0,c.width,c.height);
  x.fillStyle='#0f0';x.font='16px Share Tech Mono';
  for(let i=0;i<drops.length;i++){
    const t=chars[Math.floor(Math.random()*chars.length)];
    x.fillText(t,i*16,drops[i]*16);
    if(drops[i]*16>c.height&&Math.random()>.975) drops[i]=0;
    drops[i]++;
  }
}
setInterval(draw,33);
window.addEventListener('resize',()=>{c.width=innerWidth;c.height=innerHeight});
</script>
</body>
</html>"""


def _crazy_galaxy() -> str:
    return """<!DOCTYPE html>
<html lang="en">
<head>
<meta charset="UTF-8"><title>NANO AI — Cosmic Galaxy</title>
<style>
@import url('https://fonts.googleapis.com/css2?family=Orbitron:wght@400;700;900&display=swap');
*{box-sizing:border-box;margin:0;padding:0}
body{background:#000005;overflow:hidden;height:100vh;font-family:'Orbitron',sans-serif}
canvas#galaxy{position:fixed;top:0;left:0}
.ui{
  position:relative;z-index:1;
  display:flex;flex-direction:column;align-items:center;justify-content:center;
  height:100vh;text-align:center;padding:40px;
}
.cosmic-title{
  font-size:clamp(3rem,8vw,6rem);font-weight:900;
  background:linear-gradient(135deg,#fff 0%,#c77dff 30%,#7b2ff7 50%,#4cc9f0 70%,#fff 100%);
  background-size:200% 200%;
  -webkit-background-clip:text;-webkit-text-fill-color:transparent;background-clip:text;
  letter-spacing:6px;animation:cosmicShimmer 4s ease infinite;
  filter:drop-shadow(0 0 20px rgba(124,45,247,.8));
}
@keyframes cosmicShimmer{0%{background-position:0% 50%}50%{background-position:100% 50%}100%{background-position:0% 50%}}
.cosmic-sub{
  color:rgba(200,180,255,.7);font-size:clamp(.6rem,1.2vw,.85rem);
  letter-spacing:4px;margin-top:12px;
  animation:fadeFloat 3s ease-in-out infinite;
}
@keyframes fadeFloat{0%,100%{opacity:.7;transform:translateY(0)}50%{opacity:1;transform:translateY(-4px)}}
.orbit-ring{
  position:relative;width:300px;height:300px;margin:40px 0;
  animation:orbitSpin 20s linear infinite;
}
.ring{
  position:absolute;top:50%;left:50%;
  border-radius:50%;border:1px solid;
  transform:translate(-50%,-50%);
}
.ring1{width:120px;height:120px;border-color:rgba(124,45,247,.6);animation:ringPulse 2s ease-in-out infinite}
.ring2{width:180px;height:180px;border-color:rgba(76,201,240,.3);animation:ringPulse 2s .5s ease-in-out infinite}
.ring3{width:240px;height:240px;border-color:rgba(199,125,255,.2);animation:ringPulse 2s 1s ease-in-out infinite}
.ring4{width:300px;height:300px;border-color:rgba(124,45,247,.1);animation:ringPulse 2s 1.5s ease-in-out infinite}
.ring-center{
  position:absolute;top:50%;left:50%;transform:translate(-50%,-50%);
  width:40px;height:40px;border-radius:50%;
  background:radial-gradient(circle,#fff,#7b2ff7);
  box-shadow:0 0 20px #7b2ff7,0 0 60px rgba(124,45,247,.5);
  font-size:1.2rem;display:flex;align-items:center;justify-content:center;
}
.orbit-planet{
  position:absolute;width:12px;height:12px;border-radius:50%;
  background:radial-gradient(circle,#4cc9f0,#2196f3);
  box-shadow:0 0 10px #4cc9f0;
  top:calc(50% - 6px);left:calc(50% + 84px);
  animation:orbitPlanet 6s linear infinite;transform-origin:-84px 6px;
}
.orbit-planet2{
  position:absolute;width:8px;height:8px;border-radius:50%;
  background:radial-gradient(circle,#ff6584,#ff0080);
  box-shadow:0 0 8px #ff6584;
  top:calc(50% - 4px);left:calc(50% + 114px);
  animation:orbitPlanet 10s linear infinite reverse;transform-origin:-114px 4px;
}
@keyframes orbitSpin{to{transform:rotate(360deg)}}
@keyframes orbitPlanet{to{transform:rotate(360deg)}}
@keyframes ringPulse{0%,100%{opacity:.6}50%{opacity:1}}
.cta-cosmic{
  padding:14px 40px;
  background:linear-gradient(135deg,rgba(124,45,247,.3),rgba(76,201,240,.2));
  border:1px solid rgba(124,45,247,.6);color:#c77dff;
  font-family:'Orbitron',sans-serif;font-size:.75rem;
  letter-spacing:3px;text-transform:uppercase;cursor:pointer;border-radius:4px;
  box-shadow:0 0 20px rgba(124,45,247,.3),inset 0 0 20px rgba(124,45,247,.1);
  transition:all .3s;
}
.cta-cosmic:hover{box-shadow:0 0 40px rgba(124,45,247,.6);transform:translateY(-3px)}
</style>
</head>
<body>
<canvas id="galaxy"></canvas>
<div class="ui">
  <h1 class="cosmic-title">NANO AI</h1>
  <p class="cosmic-sub">POWERED BY CLAUDE  ·  TRAVERSING THE CODE UNIVERSE</p>
  <div class="orbit-ring">
    <div class="ring ring1"></div>
    <div class="ring ring2"></div>
    <div class="ring ring3"></div>
    <div class="ring ring4"></div>
    <div class="ring-center">🧠</div>
    <div class="orbit-planet"></div>
    <div class="orbit-planet2"></div>
  </div>
  <button class="cta-cosmic">[ LAUNCH NANO AI ]</button>
</div>
<script>
const c = document.getElementById('galaxy');
const ctx = c.getContext('2d');
c.width = innerWidth; c.height = innerHeight;
const stars = Array.from({length:300},()=>({
  x:Math.random()*c.width, y:Math.random()*c.height,
  r:Math.random()*1.5+.3,
  o:Math.random()*.8+.2,
  p:Math.random()*Math.PI*2,
  sp:Math.random()*.02+.005,
}));
const nebula = Array.from({length:6},(_,i)=>({
  x:Math.random()*c.width, y:Math.random()*c.height,
  r:Math.random()*200+100,
  hue: [270,200,320,180,290,240][i],
  o:Math.random()*.08+.03,
}));
function draw(){
  ctx.fillStyle='rgba(0,0,5,.15)';ctx.fillRect(0,0,c.width,c.height);
  // Nebula
  for(const n of nebula){
    const g=ctx.createRadialGradient(n.x,n.y,0,n.x,n.y,n.r);
    g.addColorStop(0,`hsla(${n.hue},80%,60%,${n.o})`);
    g.addColorStop(1,'transparent');
    ctx.fillStyle=g;ctx.beginPath();ctx.arc(n.x,n.y,n.r,0,Math.PI*2);ctx.fill();
  }
  // Stars
  const t=Date.now()/1000;
  for(const s of stars){
    const o=s.o*(0.5+0.5*Math.sin(t*s.sp*10+s.p));
    ctx.beginPath();ctx.arc(s.x,s.y,s.r,0,Math.PI*2);
    ctx.fillStyle=`rgba(255,255,255,${o})`;ctx.fill();
  }
}
setInterval(draw,30);
window.addEventListener('resize',()=>{c.width=innerWidth;c.height=innerHeight});
</script>
</body>
</html>"""


# ─── Three.js 3D ─────────────────────────────────────────────────────────────

def _gen_threejs(hint: str) -> str:
    shape = "cube"
    color = "0x6c63ff"
    if "sphere" in hint:
        shape = "sphere"
    if "torus" in hint or "donut" in hint:
        shape = "torus"
    if "pyramid" in hint or "cone" in hint:
        shape = "cone"

    geometry = {
        "cube":   "new THREE.BoxGeometry(1, 1, 1)",
        "sphere": "new THREE.SphereGeometry(0.7, 32, 32)",
        "torus":  "new THREE.TorusGeometry(0.6, 0.25, 16, 100)",
        "cone":   "new THREE.ConeGeometry(0.6, 1.2, 32)",
    }[shape]

    code = f"""<!DOCTYPE html>
<html lang="en">
<head>
  <meta charset="UTF-8">
  <title>Nano AI — 3D Scene</title>
  <style>
    * {{ margin: 0; padding: 0; box-sizing: border-box; }}
    body {{ background: #0a0a1a; overflow: hidden; }}
    canvas {{ display: block; }}
    #info {{
      position: absolute; top: 20px; left: 50%;
      transform: translateX(-50%);
      color: #aaa; font-family: 'Segoe UI', sans-serif;
      font-size: 14px; pointer-events: none;
    }}
  </style>
</head>
<body>
  <div id="info">Drag to rotate · Scroll to zoom · Generated by Nano AI</div>
  <script src="https://cdn.jsdelivr.net/npm/three@0.160.0/build/three.min.js"></script>
  <script src="https://cdn.jsdelivr.net/npm/three@0.160.0/examples/js/controls/OrbitControls.js"></script>
  <script>
    // ── Scene setup ──────────────────────────────────────────────
    const scene    = new THREE.Scene();
    scene.fog      = new THREE.FogExp2(0x0a0a1a, 0.05);

    const camera   = new THREE.PerspectiveCamera(60, innerWidth / innerHeight, 0.1, 100);
    camera.position.set(0, 0.5, 3);

    const renderer = new THREE.WebGLRenderer({{ antialias: true }});
    renderer.setSize(innerWidth, innerHeight);
    renderer.setPixelRatio(devicePixelRatio);
    renderer.shadowMap.enabled = true;
    document.body.appendChild(renderer.domElement);

    // ── Controls ─────────────────────────────────────────────────
    const controls = new THREE.OrbitControls(camera, renderer.domElement);
    controls.enableDamping = true;
    controls.dampingFactor = 0.05;

    // ── Lights ───────────────────────────────────────────────────
    scene.add(new THREE.AmbientLight(0xffffff, 0.4));
    const dirLight = new THREE.DirectionalLight(0xffffff, 1.2);
    dirLight.position.set(5, 10, 5);
    dirLight.castShadow = true;
    scene.add(dirLight);

    const pointLight = new THREE.PointLight({color}, 2, 10);
    pointLight.position.set(-2, 2, 2);
    scene.add(pointLight);

    // ── Main object ──────────────────────────────────────────────
    const geometry = {geometry};
    const material = new THREE.MeshStandardMaterial({{
      color:     {color},
      metalness: 0.4,
      roughness: 0.3,
      emissive:  0x1a1040,
    }});
    const mesh = new THREE.Mesh(geometry, material);
    mesh.castShadow    = true;
    mesh.receiveShadow = true;
    scene.add(mesh);

    // ── Wireframe overlay ────────────────────────────────────────
    const wire = new THREE.Mesh(
      geometry,
      new THREE.MeshBasicMaterial({{ color: 0xffffff, wireframe: true, opacity: 0.08, transparent: true }})
    );
    scene.add(wire);

    // ── Particle field ───────────────────────────────────────────
    const particleGeo = new THREE.BufferGeometry();
    const count = 1500;
    const pos   = new Float32Array(count * 3);
    for (let i = 0; i < count * 3; i++) pos[i] = (Math.random() - 0.5) * 20;
    particleGeo.setAttribute('position', new THREE.BufferAttribute(pos, 3));
    scene.add(new THREE.Points(
      particleGeo,
      new THREE.PointsMaterial({{ color: 0x6c63ff, size: 0.04, transparent: true, opacity: 0.6 }})
    ));

    // ── Floor ────────────────────────────────────────────────────
    const floor = new THREE.Mesh(
      new THREE.PlaneGeometry(20, 20),
      new THREE.MeshStandardMaterial({{ color: 0x111122, roughness: 1 }})
    );
    floor.rotation.x = -Math.PI / 2;
    floor.position.y = -1.2;
    floor.receiveShadow = true;
    scene.add(floor);

    // ── Grid ─────────────────────────────────────────────────────
    scene.add(new THREE.GridHelper(20, 20, 0x222244, 0x222244));

    // ── Animation loop ───────────────────────────────────────────
    const clock = new THREE.Clock();
    function animate() {{
      requestAnimationFrame(animate);
      const t = clock.getElapsedTime();
      mesh.rotation.x = t * 0.4;
      mesh.rotation.y = t * 0.6;
      wire.rotation.copy(mesh.rotation);
      pointLight.position.x = Math.sin(t) * 3;
      pointLight.position.z = Math.cos(t) * 3;
      controls.update();
      renderer.render(scene, camera);
    }}
    animate();

    // ── Responsive ──────────────────────────────────────────────
    window.addEventListener('resize', () => {{
      camera.aspect = innerWidth / innerHeight;
      camera.updateProjectionMatrix();
      renderer.setSize(innerWidth, innerHeight);
    }});
  </script>
</body>
</html>"""
    return _wrap_output(f"Three.js 3D Scene ({shape})", "html", code)


# ─── CSS Animations ───────────────────────────────────────────────────────────

def _gen_css_animation(hint: str) -> str:
    code = """<!DOCTYPE html>
<html lang="en">
<head>
  <meta charset="UTF-8">
  <title>Nano AI — CSS Animations</title>
  <style>
    *, *::before, *::after { box-sizing: border-box; margin: 0; padding: 0; }

    body {
      min-height: 100vh;
      background: #0d0d1a;
      display: flex;
      flex-wrap: wrap;
      align-items: center;
      justify-content: center;
      gap: 60px;
      padding: 60px 40px;
      font-family: 'Segoe UI', sans-serif;
    }

    h1 {
      width: 100%;
      text-align: center;
      color: #7c6fff;
      font-size: 1.4rem;
      letter-spacing: 4px;
      text-transform: uppercase;
      margin-bottom: -20px;
    }

    .card {
      display: flex;
      flex-direction: column;
      align-items: center;
      gap: 16px;
      color: #888;
      font-size: 0.8rem;
      letter-spacing: 1px;
    }

    /* ── 1. Pulse ring ─────────────────────────────── */
    .pulse {
      width: 70px; height: 70px;
      background: #6c63ff;
      border-radius: 50%;
      animation: pulse 1.5s ease-in-out infinite;
    }
    @keyframes pulse {
      0%, 100% { transform: scale(1);    box-shadow: 0 0 0  0 rgba(108,99,255,.6); }
      50%       { transform: scale(1.1); box-shadow: 0 0 0 20px rgba(108,99,255,0); }
    }

    /* ── 2. Spinner ────────────────────────────────── */
    .spinner {
      width: 60px; height: 60px;
      border: 5px solid #1e1e3a;
      border-top-color: #6c63ff;
      border-right-color: #ff6584;
      border-radius: 50%;
      animation: spin 0.9s linear infinite;
    }
    @keyframes spin { to { transform: rotate(360deg); } }

    /* ── 3. Typing cursor ──────────────────────────── */
    .typing {
      font-size: 1.1rem;
      color: #ccc;
      border-right: 3px solid #6c63ff;
      white-space: nowrap;
      overflow: hidden;
      width: 12ch;
      animation: typing 2.5s steps(12) infinite,
                 blink  0.6s step-end  infinite alternate;
    }
    @keyframes typing {
      0%, 10%  { width: 0; }
      50%, 90% { width: 12ch; }
      100%     { width: 0; }
    }
    @keyframes blink { from { border-color: transparent; } to { border-color: #6c63ff; } }

    /* ── 4. Floating orbs ──────────────────────────── */
    .orbs { position: relative; width: 80px; height: 80px; }
    .orb  {
      position: absolute; width: 20px; height: 20px;
      border-radius: 50%; top: 30px; left: 30px;
      animation: orbit 1.6s linear infinite;
    }
    .orb:nth-child(1) { background: #6c63ff; animation-delay: 0s; }
    .orb:nth-child(2) { background: #ff6584; animation-delay: -.53s; }
    .orb:nth-child(3) { background: #43e97b; animation-delay: -1.06s; }
    @keyframes orbit {
      0%   { transform: rotate(0deg)   translateX(30px) rotate(0deg);   }
      100% { transform: rotate(360deg) translateX(30px) rotate(-360deg); }
    }

    /* ── 5. Morphing blob ──────────────────────────── */
    .blob {
      width: 80px; height: 80px;
      background: linear-gradient(135deg, #6c63ff, #ff6584);
      border-radius: 60% 40% 30% 70% / 60% 30% 70% 40%;
      animation: morph 4s ease-in-out infinite;
    }
    @keyframes morph {
      0%,100% { border-radius: 60% 40% 30% 70% / 60% 30% 70% 40%; }
      25%     { border-radius: 30% 60% 70% 40% / 50% 60% 30% 60%; }
      50%     { border-radius: 50% 50% 20% 80% / 25% 80% 20% 75%; }
      75%     { border-radius: 67% 33% 47% 53% / 37% 20% 80% 63%; }
    }

    /* ── 6. Progress bar ───────────────────────────── */
    .progress-wrap {
      width: 140px; height: 8px;
      background: #1e1e3a;
      border-radius: 4px;
      overflow: hidden;
    }
    .progress-bar {
      height: 100%;
      background: linear-gradient(90deg, #6c63ff, #ff6584);
      border-radius: 4px;
      animation: progress 2s ease-in-out infinite;
    }
    @keyframes progress {
      0%   { width: 0%;    opacity: 1; }
      80%  { width: 100%;  opacity: 1; }
      100% { width: 100%;  opacity: 0; }
    }

    /* ── 7. Glowing text ───────────────────────────── */
    .glow {
      font-size: 1.8rem;
      font-weight: bold;
      color: #fff;
      animation: glow 2s ease-in-out infinite alternate;
      letter-spacing: 4px;
    }
    @keyframes glow {
      from { text-shadow: 0 0 4px #6c63ff, 0 0 10px #6c63ff; }
      to   { text-shadow: 0 0 20px #ff6584, 0 0 60px #ff6584; }
    }

    /* ── 8. Bouncing dots ──────────────────────────── */
    .dots { display: flex; gap: 8px; }
    .dot  {
      width: 14px; height: 14px;
      background: #6c63ff; border-radius: 50%;
      animation: bounce 1s ease-in-out infinite;
    }
    .dot:nth-child(2) { background: #ff6584; animation-delay: .15s; }
    .dot:nth-child(3) { background: #43e97b; animation-delay: .30s; }
    @keyframes bounce {
      0%,100% { transform: translateY(0);    }
      50%     { transform: translateY(-20px); }
    }
  </style>
</head>
<body>
  <h1>Nano AI — CSS Animations</h1>

  <div class="card"><div class="pulse"></div>Pulse Ring</div>
  <div class="card"><div class="spinner"></div>Spinner</div>
  <div class="card"><div class="typing">Hello World!</div>Typing Cursor</div>
  <div class="card"><div class="orbs"><div class="orb"></div><div class="orb"></div><div class="orb"></div></div>Orbit</div>
  <div class="card"><div class="blob"></div>Morphing Blob</div>
  <div class="card"><div class="progress-wrap"><div class="progress-bar"></div></div>Progress</div>
  <div class="card"><div class="glow">NANO</div>Glow Text</div>
  <div class="card"><div class="dots"><div class="dot"></div><div class="dot"></div><div class="dot"></div></div>Bounce</div>
</body>
</html>"""
    return _wrap_output("CSS Animations Showcase", "html", code)


# ─── HTML UI / Landing Page ────────────────────────────────────────────────────

def _gen_html_ui(hint: str) -> str:
    if "dashboard" in hint:
        return _gen_dashboard()
    if "portfolio" in hint:
        return _gen_portfolio()
    if "card" in hint:
        return _gen_cards()
    return _gen_landing_page()


def _gen_landing_page() -> str:
    code = """<!DOCTYPE html>
<html lang="en">
<head>
  <meta charset="UTF-8">
  <meta name="viewport" content="width=device-width, initial-scale=1.0">
  <title>Nano AI — Landing Page</title>
  <style>
    :root {
      --primary: #6c63ff;
      --accent:  #ff6584;
      --bg:      #0d0d1a;
      --surface: #14142a;
      --text:    #e0e0f0;
      --muted:   #888;
    }
    *, *::before, *::after { box-sizing: border-box; margin: 0; padding: 0; }
    html { scroll-behavior: smooth; }
    body { background: var(--bg); color: var(--text); font-family: 'Segoe UI', system-ui, sans-serif; }

    /* Nav */
    nav {
      position: fixed; top: 0; width: 100%; padding: 16px 40px;
      display: flex; justify-content: space-between; align-items: center;
      background: rgba(13,13,26,.8); backdrop-filter: blur(12px);
      border-bottom: 1px solid #1e1e3a; z-index: 100;
    }
    .logo { font-size: 1.4rem; font-weight: 700; color: var(--primary); letter-spacing: 2px; }
    .nav-links { display: flex; gap: 28px; list-style: none; }
    .nav-links a { color: var(--muted); text-decoration: none; font-size: .9rem; transition: color .2s; }
    .nav-links a:hover { color: var(--text); }
    .cta-btn {
      padding: 10px 22px; background: var(--primary); color: #fff;
      border: none; border-radius: 8px; cursor: pointer; font-size: .9rem;
      transition: transform .2s, box-shadow .2s;
    }
    .cta-btn:hover { transform: translateY(-2px); box-shadow: 0 8px 30px rgba(108,99,255,.4); }

    /* Hero */
    .hero {
      min-height: 100vh; display: flex; align-items: center; justify-content: center;
      text-align: center; padding: 120px 40px 80px;
      background: radial-gradient(ellipse at top, #1a1040 0%, var(--bg) 70%);
    }
    .hero-badge {
      display: inline-block; padding: 4px 14px;
      background: rgba(108,99,255,.15); border: 1px solid var(--primary);
      border-radius: 20px; font-size: .8rem; color: var(--primary);
      margin-bottom: 24px; letter-spacing: 1px;
    }
    .hero h1 { font-size: clamp(2.5rem, 6vw, 5rem); line-height: 1.1; margin-bottom: 20px; }
    .hero h1 span { color: var(--primary); }
    .hero p  { font-size: 1.15rem; color: var(--muted); max-width: 560px; margin: 0 auto 36px; line-height: 1.7; }
    .hero-btns { display: flex; gap: 16px; justify-content: center; flex-wrap: wrap; }
    .btn-outline {
      padding: 12px 28px; border: 1px solid #333; color: var(--text);
      background: transparent; border-radius: 8px; cursor: pointer; font-size: 1rem;
      transition: border-color .2s, background .2s;
    }
    .btn-outline:hover { border-color: var(--primary); background: rgba(108,99,255,.1); }
    .btn-primary {
      padding: 12px 28px; background: var(--primary); color: #fff;
      border: none; border-radius: 8px; cursor: pointer; font-size: 1rem;
      transition: transform .2s, box-shadow .2s;
    }
    .btn-primary:hover { transform: translateY(-2px); box-shadow: 0 8px 30px rgba(108,99,255,.5); }

    /* Features */
    .features { padding: 100px 40px; }
    .features h2 { text-align: center; font-size: 2rem; margin-bottom: 60px; }
    .features h2 span { color: var(--primary); }
    .feature-grid { display: grid; grid-template-columns: repeat(auto-fit, minmax(280px, 1fr)); gap: 24px; max-width: 1100px; margin: 0 auto; }
    .feature-card {
      background: var(--surface); border: 1px solid #1e1e3a;
      border-radius: 16px; padding: 32px;
      transition: transform .2s, border-color .2s;
    }
    .feature-card:hover { transform: translateY(-4px); border-color: var(--primary); }
    .feature-icon { font-size: 2rem; margin-bottom: 16px; }
    .feature-card h3 { font-size: 1.1rem; margin-bottom: 10px; }
    .feature-card p { color: var(--muted); font-size: .9rem; line-height: 1.6; }

    /* Footer */
    footer {
      text-align: center; padding: 40px;
      border-top: 1px solid #1e1e3a; color: var(--muted); font-size: .85rem;
    }
  </style>
</head>
<body>
  <nav>
    <div class="logo">NANO AI</div>
    <ul class="nav-links">
      <li><a href="#features">Features</a></li>
      <li><a href="#about">About</a></li>
      <li><a href="#contact">Contact</a></li>
    </ul>
    <button class="cta-btn">Get Started</button>
  </nav>

  <section class="hero">
    <div>
      <div class="hero-badge">✦ AI-Powered Coding</div>
      <h1>The AI that teaches<br><span>every language</span></h1>
      <p>Nano AI knows every programming language, framework, and concept.
         Learn by doing, get instant feedback, and build real projects.</p>
      <div class="hero-btns">
        <button class="btn-primary">Start Learning →</button>
        <button class="btn-outline">View Demo</button>
      </div>
    </div>
  </section>

  <section class="features" id="features">
    <h2>Everything you need to <span>master coding</span></h2>
    <div class="feature-grid">
      <div class="feature-card">
        <div class="feature-icon">🧠</div>
        <h3>AI-Powered Explanations</h3>
        <p>Ask anything about code. Get clear, concise explanations with real examples in any language.</p>
      </div>
      <div class="feature-card">
        <div class="feature-icon">⚡</div>
        <h3>Live Code Generation</h3>
        <p>Generate complete, production-quality scripts, UIs, 3D scenes, and APIs instantly.</p>
      </div>
      <div class="feature-card">
        <div class="feature-icon">🎯</div>
        <h3>Exercises & Quizzes</h3>
        <p>Practice with graded coding challenges from beginner to advanced. Earn XP and level up.</p>
      </div>
      <div class="feature-card">
        <div class="feature-icon">🌐</div>
        <h3>WebFetch</h3>
        <p>Nano AI browses the internet to fetch the latest documentation, tutorials, and answers.</p>
      </div>
      <div class="feature-card">
        <div class="feature-icon">📁</div>
        <h3>File Read & Write</h3>
        <p>Read your existing code, analyze it, and write improved versions directly to disk.</p>
      </div>
      <div class="feature-card">
        <div class="feature-icon">🔄</div>
        <h3>Persistent Memory</h3>
        <p>Nano AI remembers your progress, preferred language, and learned topics across sessions.</p>
      </div>
    </div>
  </section>

  <footer>
    <p>Built by Nano AI &mdash; the smartest coding tutor on Earth &mdash; 2024</p>
  </footer>
</body>
</html>"""
    return _wrap_output("Landing Page UI", "html", code)


def _gen_dashboard() -> str:
    code = """<!DOCTYPE html>
<html lang="en">
<head>
  <meta charset="UTF-8"><title>Nano AI Dashboard</title>
  <style>
    :root { --bg: #0d0d1a; --surface: #14142a; --border: #1e1e3a; --primary: #6c63ff; --accent: #ff6584; --green: #43e97b; --text: #e0e0f0; --muted: #666; }
    * { box-sizing: border-box; margin: 0; padding: 0; }
    body { background: var(--bg); color: var(--text); font-family: 'Segoe UI', system-ui, sans-serif; display: grid; grid-template-columns: 220px 1fr; min-height: 100vh; }
    /* Sidebar */
    .sidebar { background: var(--surface); border-right: 1px solid var(--border); padding: 24px 16px; display: flex; flex-direction: column; gap: 8px; }
    .sidebar-logo { font-size: 1.2rem; font-weight: 700; color: var(--primary); letter-spacing: 2px; padding: 0 8px 20px; }
    .nav-item { padding: 10px 12px; border-radius: 8px; cursor: pointer; font-size: .9rem; color: var(--muted); transition: all .15s; display: flex; gap: 10px; align-items: center; }
    .nav-item:hover, .nav-item.active { background: rgba(108,99,255,.15); color: var(--text); }
    .nav-item.active { color: var(--primary); }
    /* Main */
    .main { padding: 32px; overflow-y: auto; }
    .main-header { display: flex; justify-content: space-between; align-items: center; margin-bottom: 28px; }
    .main-header h1 { font-size: 1.4rem; }
    .badge { padding: 6px 14px; background: rgba(108,99,255,.15); color: var(--primary); border-radius: 20px; font-size: .8rem; }
    /* Stats */
    .stats { display: grid; grid-template-columns: repeat(auto-fit, minmax(180px, 1fr)); gap: 16px; margin-bottom: 28px; }
    .stat-card { background: var(--surface); border: 1px solid var(--border); border-radius: 12px; padding: 20px; }
    .stat-label { font-size: .8rem; color: var(--muted); margin-bottom: 8px; }
    .stat-value { font-size: 2rem; font-weight: 700; }
    .stat-value.purple { color: var(--primary); }
    .stat-value.pink   { color: var(--accent); }
    .stat-value.green  { color: var(--green); }
    .stat-delta { font-size: .8rem; color: var(--green); margin-top: 4px; }
    /* Chart area */
    .charts { display: grid; grid-template-columns: 2fr 1fr; gap: 16px; margin-bottom: 28px; }
    .chart-card { background: var(--surface); border: 1px solid var(--border); border-radius: 12px; padding: 20px; }
    .chart-card h3 { font-size: .95rem; margin-bottom: 16px; color: var(--muted); }
    .bar-chart { display: flex; align-items: flex-end; gap: 10px; height: 120px; }
    .bar { flex: 1; background: var(--primary); border-radius: 4px 4px 0 0; opacity: .7; transition: opacity .2s; cursor: pointer; position: relative; }
    .bar:hover { opacity: 1; }
    .bar::after { content: attr(data-val); position: absolute; top: -20px; left: 50%; transform: translateX(-50%); font-size: .7rem; color: var(--text); }
    .donut-wrap { display: flex; align-items: center; justify-content: center; height: 120px; }
    .donut { width: 100px; height: 100px; border-radius: 50%; background: conic-gradient(var(--primary) 0% 45%, var(--accent) 45% 70%, var(--green) 70% 100%); display: flex; align-items: center; justify-content: center; }
    .donut-inner { width: 60px; height: 60px; background: var(--surface); border-radius: 50%; }
    /* Table */
    table { width: 100%; border-collapse: collapse; }
    th, td { padding: 12px 16px; text-align: left; border-bottom: 1px solid var(--border); font-size: .9rem; }
    th { color: var(--muted); font-weight: 500; }
    .status { padding: 3px 10px; border-radius: 20px; font-size: .75rem; }
    .status.pass { background: rgba(67,233,123,.15); color: var(--green); }
    .status.fail { background: rgba(255,101,132,.15); color: var(--accent); }
    .status.warn { background: rgba(255,193,7,.15); color: #ffc107; }
  </style>
</head>
<body>
  <nav class="sidebar">
    <div class="sidebar-logo">NANO AI</div>
    <div class="nav-item active">📊 Dashboard</div>
    <div class="nav-item">📚 Learn</div>
    <div class="nav-item">🏋️ Exercises</div>
    <div class="nav-item">🧠 Quiz</div>
    <div class="nav-item">📁 Files</div>
    <div class="nav-item">🌐 WebFetch</div>
    <div class="nav-item">⚙️ Settings</div>
  </nav>
  <main class="main">
    <div class="main-header">
      <h1>Dashboard</h1>
      <span class="badge">Level 4 — Developer</span>
    </div>
    <div class="stats">
      <div class="stat-card"><div class="stat-label">Total XP</div><div class="stat-value purple">4,820</div><div class="stat-delta">↑ +120 today</div></div>
      <div class="stat-card"><div class="stat-label">Exercises Done</div><div class="stat-value pink">38</div><div class="stat-delta">↑ +3 today</div></div>
      <div class="stat-card"><div class="stat-label">Quiz Accuracy</div><div class="stat-value green">87%</div><div class="stat-delta">↑ +5% this week</div></div>
      <div class="stat-card"><div class="stat-label">Topics Covered</div><div class="stat-value purple">14</div><div class="stat-delta">All concepts ✓</div></div>
    </div>
    <div class="charts">
      <div class="chart-card">
        <h3>XP This Week</h3>
        <div class="bar-chart">
          <div class="bar" style="height:40%" data-val="180"></div>
          <div class="bar" style="height:65%" data-val="290"></div>
          <div class="bar" style="height:50%" data-val="220"></div>
          <div class="bar" style="height:80%" data-val="360"></div>
          <div class="bar" style="height:55%" data-val="245"></div>
          <div class="bar" style="height:90%" data-val="405"></div>
          <div class="bar" style="height:70%; background:#ff6584" data-val="120"></div>
        </div>
      </div>
      <div class="chart-card">
        <h3>Language Split</h3>
        <div class="donut-wrap"><div class="donut"><div class="donut-inner"></div></div></div>
        <div style="display:flex;gap:12px;justify-content:center;margin-top:12px;font-size:.75rem;color:var(--muted)">
          <span style="color:#6c63ff">● Python</span>
          <span style="color:#ff6584">● JS</span>
          <span style="color:#43e97b">● Lua</span>
        </div>
      </div>
    </div>
    <div class="chart-card">
      <h3>Recent Activity</h3><br>
      <table>
        <tr><th>Exercise</th><th>Language</th><th>Score</th><th>Status</th></tr>
        <tr><td>Binary Search</td><td>Python</td><td>100%</td><td><span class="status pass">Passed</span></td></tr>
        <tr><td>FizzBuzz</td><td>JavaScript</td><td>100%</td><td><span class="status pass">Passed</span></td></tr>
        <tr><td>Linked List</td><td>Python</td><td>60%</td><td><span class="status warn">Partial</span></td></tr>
        <tr><td>Merge Sort</td><td>Python</td><td>0%</td><td><span class="status fail">Skipped</span></td></tr>
      </table>
    </div>
  </main>
</body>
</html>"""
    return _wrap_output("Developer Dashboard UI", "html", code)


def _gen_cards() -> str:
    code = """<!DOCTYPE html>
<html lang="en">
<head>
  <meta charset="UTF-8"><title>Nano AI — Cards</title>
  <style>
    * { box-sizing: border-box; margin: 0; padding: 0; }
    body { min-height: 100vh; background: #0d0d1a; display: flex; flex-wrap: wrap; gap: 24px; align-items: center; justify-content: center; padding: 60px 40px; font-family: 'Segoe UI', system-ui, sans-serif; }

    .card {
      background: #14142a; border: 1px solid #1e1e3a; border-radius: 16px;
      width: 260px; overflow: hidden; transition: transform .25s, box-shadow .25s;
      cursor: pointer;
    }
    .card:hover { transform: translateY(-6px); box-shadow: 0 20px 50px rgba(108,99,255,.2); border-color: #6c63ff; }
    .card-img { width: 100%; height: 140px; object-fit: cover; display: flex; align-items: center; justify-content: center; font-size: 3rem; }
    .card-img.purple { background: linear-gradient(135deg, #3a1c71, #6c63ff); }
    .card-img.pink   { background: linear-gradient(135deg, #6b0f1a, #ff6584); }
    .card-img.green  { background: linear-gradient(135deg, #004d40, #43e97b); }
    .card-body { padding: 20px; }
    .card-tag { font-size: .7rem; color: #6c63ff; letter-spacing: 1px; text-transform: uppercase; margin-bottom: 8px; }
    .card-title { font-size: 1.1rem; margin-bottom: 8px; }
    .card-text { font-size: .85rem; color: #888; line-height: 1.6; }
    .card-footer { padding: 0 20px 20px; display: flex; justify-content: space-between; align-items: center; }
    .avatar { width: 28px; height: 28px; border-radius: 50%; background: linear-gradient(135deg,#6c63ff,#ff6584); display: flex; align-items: center; justify-content: center; font-size: .7rem; color: #fff; }
    .card-btn { padding: 6px 14px; background: rgba(108,99,255,.15); color: #6c63ff; border: 1px solid #6c63ff; border-radius: 20px; font-size: .75rem; cursor: pointer; transition: all .2s; }
    .card-btn:hover { background: #6c63ff; color: #fff; }
  </style>
</head>
<body>
  <div class="card">
    <div class="card-img purple">🧠</div>
    <div class="card-body">
      <div class="card-tag">AI &amp; Machine Learning</div>
      <div class="card-title">Neural Networks from Scratch</div>
      <div class="card-text">Build a neural net using only numpy. Understand backprop and gradient descent.</div>
    </div>
    <div class="card-footer"><div class="avatar">NA</div><button class="card-btn">Learn →</button></div>
  </div>
  <div class="card">
    <div class="card-img pink">⚡</div>
    <div class="card-body">
      <div class="card-tag">Web Development</div>
      <div class="card-title">Build a REST API with FastAPI</div>
      <div class="card-text">Create a full CRUD API with auth, database, and auto-generated docs in Python.</div>
    </div>
    <div class="card-footer"><div class="avatar">NA</div><button class="card-btn">Learn →</button></div>
  </div>
  <div class="card">
    <div class="card-img green">🎮</div>
    <div class="card-body">
      <div class="card-tag">Game Dev — Roblox</div>
      <div class="card-title">Scripting in Luau</div>
      <div class="card-text">Create NPCs, GUIs, weapons, and game loops using Roblox's Luau scripting engine.</div>
    </div>
    <div class="card-footer"><div class="avatar">NA</div><button class="card-btn">Learn →</button></div>
  </div>
</body>
</html>"""
    return _wrap_output("Card Components UI", "html", code)


def _gen_portfolio() -> str:
    code = """<!DOCTYPE html>
<html lang="en">
<head>
  <meta charset="UTF-8"><title>Portfolio — Nano AI</title>
  <style>
    :root { --primary:#6c63ff; --accent:#ff6584; --bg:#0d0d1a; --surface:#14142a; --text:#e0e0f0; --muted:#777; }
    * { box-sizing: border-box; margin: 0; padding: 0; }
    html { scroll-behavior: smooth; }
    body { background: var(--bg); color: var(--text); font-family: 'Segoe UI', system-ui, sans-serif; }
    section { padding: 80px 40px; max-width: 900px; margin: 0 auto; }
    /* Hero */
    .hero { min-height: 100vh; display: flex; align-items: center; }
    .hero-tag { color: var(--primary); font-size: .9rem; letter-spacing: 2px; margin-bottom: 12px; }
    .hero h1 { font-size: clamp(2.5rem,6vw,4.5rem); line-height: 1.1; margin-bottom: 16px; }
    .hero h1 em { font-style: normal; color: var(--primary); }
    .hero p { color: var(--muted); font-size: 1.1rem; max-width: 500px; line-height: 1.7; margin-bottom: 28px; }
    .hero-btns { display: flex; gap: 12px; flex-wrap: wrap; }
    .btn { padding: 11px 24px; border-radius: 8px; cursor: pointer; font-size: .95rem; transition: all .2s; }
    .btn-fill { background: var(--primary); color: #fff; border: none; }
    .btn-fill:hover { box-shadow: 0 8px 25px rgba(108,99,255,.5); transform: translateY(-2px); }
    .btn-ghost { background: transparent; color: var(--text); border: 1px solid #333; }
    .btn-ghost:hover { border-color: var(--primary); }
    /* About */
    .skills { display: flex; flex-wrap: wrap; gap: 10px; margin-top: 24px; }
    .skill { padding: 6px 14px; background: rgba(108,99,255,.1); border: 1px solid rgba(108,99,255,.3); border-radius: 20px; font-size: .85rem; color: var(--primary); }
    /* Projects */
    .projects { display: grid; grid-template-columns: repeat(auto-fit, minmax(260px,1fr)); gap: 20px; margin-top: 32px; }
    .proj { background: var(--surface); border: 1px solid #1e1e3a; border-radius: 12px; padding: 24px; transition: all .2s; }
    .proj:hover { border-color: var(--primary); transform: translateY(-4px); }
    .proj-top { display: flex; justify-content: space-between; margin-bottom: 14px; }
    .proj-icon { font-size: 1.8rem; }
    .proj-links a { color: var(--muted); font-size: .85rem; margin-left: 12px; text-decoration: none; }
    .proj-links a:hover { color: var(--text); }
    .proj h3 { margin-bottom: 8px; font-size: 1rem; }
    .proj p { color: var(--muted); font-size: .85rem; line-height: 1.6; margin-bottom: 14px; }
    .proj-tags { display: flex; gap: 6px; flex-wrap: wrap; }
    .proj-tag { font-size: .72rem; padding: 2px 8px; background: rgba(255,101,132,.1); color: var(--accent); border-radius: 4px; }
    /* Contact */
    .contact-grid { display: grid; grid-template-columns: 1fr 1fr; gap: 20px; margin-top: 32px; }
    input, textarea { width: 100%; padding: 12px 16px; background: var(--surface); border: 1px solid #1e1e3a; border-radius: 8px; color: var(--text); font-size: .95rem; outline: none; transition: border-color .2s; }
    input:focus, textarea:focus { border-color: var(--primary); }
    textarea { grid-column: 1/-1; resize: vertical; min-height: 120px; }
    .contact-grid button { grid-column: 1/-1; }
  </style>
</head>
<body>
  <section class="hero">
    <div>
      <p class="hero-tag">// HELLO, WORLD</p>
      <h1>I build things<br>with <em>code</em></h1>
      <p>Full-stack developer · AI enthusiast · Open-source contributor. I turn ideas into fast, beautiful, production-ready software.</p>
      <div class="hero-btns">
        <button class="btn btn-fill">View Projects</button>
        <button class="btn btn-ghost">Download CV</button>
      </div>
    </div>
  </section>
  <section>
    <h2>About Me</h2>
    <p style="color:var(--muted);line-height:1.8;margin-top:16px">
      I'm a software engineer who loves building things from scratch. I work across the full stack — from React frontends and Node backends to Python data pipelines and Lua game scripts.
    </p>
    <div class="skills">
      <span class="skill">Python</span><span class="skill">JavaScript</span><span class="skill">TypeScript</span>
      <span class="skill">React</span><span class="skill">Node.js</span><span class="skill">Lua / Roblox</span>
      <span class="skill">Rust</span><span class="skill">SQL</span><span class="skill">Docker</span>
      <span class="skill">Three.js</span><span class="skill">Machine Learning</span>
    </div>
  </section>
  <section>
    <h2>Projects</h2>
    <div class="projects">
      <div class="proj">
        <div class="proj-top"><span class="proj-icon">🧠</span><div class="proj-links"><a href="#">GitHub</a><a href="#">Demo</a></div></div>
        <h3>Nano AI Tutor</h3>
        <p>AI coding tutor that teaches every language, generates code, and browses the web. Fully offline.</p>
        <div class="proj-tags"><span class="proj-tag">Python</span><span class="proj-tag">AI</span><span class="proj-tag">CLI</span></div>
      </div>
      <div class="proj">
        <div class="proj-top"><span class="proj-icon">🎮</span><div class="proj-links"><a href="#">GitHub</a></div></div>
        <h3>Roblox Game Framework</h3>
        <p>Modular Luau framework for Roblox games. Includes NPC AI, inventory, and networking.</p>
        <div class="proj-tags"><span class="proj-tag">Lua</span><span class="proj-tag">Roblox</span><span class="proj-tag">Game Dev</span></div>
      </div>
      <div class="proj">
        <div class="proj-top"><span class="proj-icon">⚡</span><div class="proj-links"><a href="#">GitHub</a><a href="#">Live</a></div></div>
        <h3>Real-time Dashboard</h3>
        <p>WebSocket-powered analytics dashboard with live charts, dark mode, and mobile support.</p>
        <div class="proj-tags"><span class="proj-tag">React</span><span class="proj-tag">Node</span><span class="proj-tag">WebSocket</span></div>
      </div>
    </div>
  </section>
  <section>
    <h2>Contact</h2>
    <form>
      <div class="contact-grid">
        <input type="text" placeholder="Name">
        <input type="email" placeholder="Email">
        <textarea placeholder="Your message..."></textarea>
        <button class="btn btn-fill" type="submit">Send Message →</button>
      </div>
    </form>
  </section>
</body>
</html>"""
    return _wrap_output("Portfolio Website", "html", code)


# ─── Roblox / Lua ─────────────────────────────────────────────────────────────

def _gen_roblox(hint: str) -> str:
    if "gui" in hint or "ui" in hint:
        code = _roblox_gui()
        return _wrap_output("Roblox GUI Script", "lua", code)
    if "npc" in hint or "enemy" in hint:
        code = _roblox_npc()
        return _wrap_output("Roblox NPC AI Script", "lua", code)
    code = _roblox_game_loop()
    return _wrap_output("Roblox Game Loop Script", "lua", code)


def _roblox_gui() -> str:
    return """-- Nano AI — Roblox GUI Script (LocalScript)
local Players      = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")

local player  = Players.LocalPlayer
local gui     = player:WaitForChild("PlayerGui")

-- Create ScreenGui
local screenGui = Instance.new("ScreenGui")
screenGui.Name         = "NanoHUD"
screenGui.ResetOnSpawn = false
screenGui.Parent       = gui

-- Main frame
local frame = Instance.new("Frame")
frame.Size            = UDim2.new(0, 280, 0, 200)
frame.Position        = UDim2.new(0.5, -140, 0.5, -100)
frame.BackgroundColor3 = Color3.fromRGB(13, 13, 26)
frame.BorderSizePixel  = 0
frame.Parent           = screenGui

-- Rounded corners
Instance.new("UICorner", frame).CornerRadius = UDim.new(0, 12)

-- Stroke / border
local stroke = Instance.new("UIStroke", frame)
stroke.Color     = Color3.fromRGB(108, 99, 255)
stroke.Thickness = 2

-- Title label
local title = Instance.new("TextLabel", frame)
title.Size      = UDim2.new(1, 0, 0, 40)
title.Position  = UDim2.new(0, 0, 0, 0)
title.Text      = "⚡ NANO AI HUD"
title.TextColor3 = Color3.fromRGB(108, 99, 255)
title.Font      = Enum.Font.GothamBold
title.TextSize  = 16
title.BackgroundTransparency = 1

-- Stats
local function makeLabel(parent, text, posY)
    local lbl = Instance.new("TextLabel", parent)
    lbl.Size      = UDim2.new(1, -20, 0, 30)
    lbl.Position  = UDim2.new(0, 10, 0, posY)
    lbl.Text      = text
    lbl.TextColor3 = Color3.fromRGB(200, 200, 220)
    lbl.Font      = Enum.Font.Gotham
    lbl.TextSize  = 14
    lbl.TextXAlignment = Enum.TextXAlignment.Left
    lbl.BackgroundTransparency = 1
    return lbl
end

local hpLabel    = makeLabel(frame, "❤️  HP: 100 / 100", 45)
local xpLabel    = makeLabel(frame, "⭐ XP: 0", 75)
local levelLabel = makeLabel(frame, "🏆 Level: 1", 105)

-- Close button
local closeBtn = Instance.new("TextButton", frame)
closeBtn.Size      = UDim2.new(0, 24, 0, 24)
closeBtn.Position  = UDim2.new(1, -28, 0, 8)
closeBtn.Text      = "✕"
closeBtn.TextColor3 = Color3.fromRGB(255, 100, 100)
closeBtn.Font      = Enum.Font.GothamBold
closeBtn.TextSize  = 14
closeBtn.BackgroundTransparency = 1
closeBtn.BorderSizePixel = 0

-- Tween open animation
local tweenInfo = TweenInfo.new(0.3, Enum.EasingStyle.Back, Enum.EasingDirection.Out)
frame.Size = UDim2.new(0, 0, 0, 0)
TweenService:Create(frame, tweenInfo, { Size = UDim2.new(0, 280, 0, 200) }):Play()

-- Toggle visibility on close
closeBtn.MouseButton1Click:Connect(function()
    local tween = TweenService:Create(frame, TweenInfo.new(0.2), { Size = UDim2.new(0, 0, 0, 0) })
    tween:Play()
    tween.Completed:Wait()
    frame.Visible = false
end)

-- Drag the frame
local dragging, dragStart, startPos = false, nil, nil
frame.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 then
        dragging  = true
        dragStart = input.Position
        startPos  = frame.Position
    end
end)
frame.InputEnded:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 then
        dragging = false
    end
end)
UserInputService.InputChanged:Connect(function(input)
    if dragging and input.UserInputType == Enum.UserInputType.MouseMovement then
        local delta = input.Position - dragStart
        frame.Position = UDim2.new(
            startPos.X.Scale, startPos.X.Offset + delta.X,
            startPos.Y.Scale, startPos.Y.Offset + delta.Y
        )
    end
end)

-- Update stats from character
local function updateStats()
    local char = player.Character
    if not char then return end
    local hum = char:FindFirstChildOfClass("Humanoid")
    if hum then
        hpLabel.Text = string.format("❤️  HP: %d / %d", math.floor(hum.Health), math.floor(hum.MaxHealth))
    end
end
game:GetService("RunService").Heartbeat:Connect(updateStats)
print("[NanoAI] GUI loaded successfully!")
"""


def _roblox_npc() -> str:
    return """-- Nano AI — Roblox NPC AI (ServerScript)
local Players      = game:GetService("Players")
local RunService   = game:GetService("RunService")
local PathfindingService = game:GetService("PathfindingService")

local NPC          = script.Parent
local humanoid     = NPC:WaitForChild("Humanoid")
local rootPart     = NPC:WaitForChild("HumanoidRootPart")

-- Config
local DETECT_RANGE  = 50    -- studs to spot a player
local ATTACK_RANGE  = 5     -- studs to deal damage
local ATTACK_DAMAGE = 15
local ATTACK_COOLDOWN = 1.5
local WALK_SPEED    = 14
local CHASE_SPEED   = 18
local WANDER_RADIUS = 20

humanoid.WalkSpeed = WALK_SPEED

local spawnPos    = rootPart.Position
local lastAttack  = 0
local target      = nil

-- ── Utilities ──────────────────────────────────────────────────
local function getClosestPlayer()
    local closest, dist = nil, DETECT_RANGE
    for _, p in ipairs(Players:GetPlayers()) do
        local char = p.Character
        if char and char:FindFirstChild("HumanoidRootPart") then
            local d = (char.HumanoidRootPart.Position - rootPart.Position).Magnitude
            if d < dist then
                closest, dist = char, d
            end
        end
    end
    return closest
end

local function moveTo(position)
    local path = PathfindingService:CreatePath({
        AgentRadius = 2, AgentHeight = 5,
        AgentCanJump = true, AgentCanClimb = false,
    })
    local ok, err = pcall(function() path:ComputeAsync(rootPart.Position, position) end)
    if not ok or path.Status ~= Enum.PathStatus.Success then
        humanoid:MoveTo(position)
        return
    end
    for _, wp in ipairs(path:GetWaypoints()) do
        if wp.Action == Enum.PathWaypointAction.Jump then
            humanoid.Jump = true
        end
        humanoid:MoveTo(wp.Position)
        local reached = humanoid.MoveToFinished:Wait(1)
        if not reached then break end
        if target and (rootPart.Position - target.HumanoidRootPart.Position).Magnitude < ATTACK_RANGE then break end
    end
end

local function wander()
    local angle  = math.random() * 2 * math.pi
    local offset = Vector3.new(math.cos(angle) * WANDER_RADIUS, 0, math.sin(angle) * WANDER_RADIUS)
    moveTo(spawnPos + offset)
end

local function attack()
    if not target then return end
    local dist = (rootPart.Position - target.HumanoidRootPart.Position).Magnitude
    if dist > ATTACK_RANGE then return end
    local now = tick()
    if now - lastAttack < ATTACK_COOLDOWN then return end
    lastAttack = now
    local hum = target:FindFirstChildOfClass("Humanoid")
    if hum and hum.Health > 0 then
        hum:TakeDamage(ATTACK_DAMAGE)
    end
end

-- ── Main loop ──────────────────────────────────────────────────
while true do
    if humanoid.Health <= 0 then break end

    target = getClosestPlayer()

    if target and target:FindFirstChild("HumanoidRootPart") then
        local dist = (rootPart.Position - target.HumanoidRootPart.Position).Magnitude
        humanoid.WalkSpeed = CHASE_SPEED
        if dist <= ATTACK_RANGE then
            humanoid:MoveTo(rootPart.Position)  -- stand still
            attack()
        else
            moveTo(target.HumanoidRootPart.Position)
        end
    else
        humanoid.WalkSpeed = WALK_SPEED
        wander()
        task.wait(math.random(2, 5))
    end

    task.wait(0.1)
end
"""


def _roblox_game_loop() -> str:
    return """-- Nano AI — Roblox Game Loop (ServerScript)
local Players      = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerStorage     = game:GetService("ServerStorage")

-- ── Events ────────────────────────────────────────────────────
local events = Instance.new("Folder", ReplicatedStorage)
events.Name  = "Events"

local roundStarted = Instance.new("RemoteEvent", events)
roundStarted.Name  = "RoundStarted"

local roundEnded   = Instance.new("RemoteEvent", events)
roundEnded.Name    = "RoundEnded"

local updateScore  = Instance.new("RemoteEvent", events)
updateScore.Name   = "UpdateScore"

-- ── Game config ────────────────────────────────────────────────
local CONFIG = {
    LOBBY_TIME   = 15,
    ROUND_TIME   = 120,
    MIN_PLAYERS  = 2,
    MAP_FOLDER   = ServerStorage:FindFirstChild("Maps"),
}

-- ── State ─────────────────────────────────────────────────────
local scores     = {}
local roundActive = false

-- ── Utilities ─────────────────────────────────────────────────
local function teleportToLobby(player)
    local char = player.Character
    if char and char:FindFirstChild("HumanoidRootPart") then
        char.HumanoidRootPart.CFrame = CFrame.new(0, 5, 0)
    end
end

local function killAll()
    for _, player in ipairs(Players:GetPlayers()) do
        local char = player.Character
        if char then
            local hum = char:FindFirstChildOfClass("Humanoid")
            if hum then hum.Health = 0 end
        end
    end
end

local function notifyAll(message, color)
    color = color or Color3.fromRGB(255, 255, 255)
    for _, player in ipairs(Players:GetPlayers()) do
        local gui = player:FindFirstChild("PlayerGui")
        if gui then
            local sg = Instance.new("ScreenGui", gui)
            sg.ResetOnSpawn = false
            local lbl = Instance.new("TextLabel", sg)
            lbl.Size      = UDim2.new(1, 0, 0, 60)
            lbl.Position  = UDim2.new(0, 0, 0.1, 0)
            lbl.Text      = message
            lbl.TextColor3 = color
            lbl.Font      = Enum.Font.GothamBold
            lbl.TextSize  = 28
            lbl.BackgroundTransparency = 1
            game:GetService("Debris"):AddItem(sg, 4)
        end
    end
end

-- ── Player events ─────────────────────────────────────────────
Players.PlayerAdded:Connect(function(player)
    scores[player.UserId] = 0
    player.CharacterAdded:Connect(function(char)
        if not roundActive then
            task.wait(1)
            teleportToLobby(player)
        end
        local hum = char:WaitForChild("Humanoid")
        hum.Died:Connect(function()
            local tag = hum:FindFirstChild("creator")
            if tag and tag.Value and tag.Value ~= player then
                local killer = tag.Value
                scores[killer.UserId] = (scores[killer.UserId] or 0) + 1
                updateScore:FireAll(killer, scores[killer.UserId])
                notifyAll(killer.Name .. " eliminated " .. player.Name, Color3.fromRGB(255, 100, 100))
            end
        end)
    end)
    print("[NanoAI] " .. player.Name .. " joined. Players: " .. #Players:GetPlayers())
end)

Players.PlayerRemoving:Connect(function(player)
    scores[player.UserId] = nil
end)

-- ── Main game loop ────────────────────────────────────────────
while true do
    -- Lobby countdown
    notifyAll("⏳ Waiting for players... (" .. #Players:GetPlayers() .. "/" .. CONFIG.MIN_PLAYERS .. ")")
    repeat task.wait(1) until #Players:GetPlayers() >= CONFIG.MIN_PLAYERS

    for i = CONFIG.LOBBY_TIME, 1, -1 do
        notifyAll("🚀 Round starting in " .. i .. "s!", Color3.fromRGB(108, 99, 255))
        task.wait(1)
    end

    -- Reset scores
    scores = {}
    for _, p in ipairs(Players:GetPlayers()) do
        scores[p.UserId] = 0
    end

    -- Start round
    roundActive = true
    roundStarted:FireAll()
    notifyAll("⚔️  ROUND STARTED! Fight!", Color3.fromRGB(255, 200, 0))

    -- Respawn players in map
    for _, player in ipairs(Players:GetPlayers()) do
        player:LoadCharacter()
        task.wait(0.1)
    end

    -- Round timer
    local timeLeft = CONFIG.ROUND_TIME
    while timeLeft > 0 and roundActive do
        task.wait(1)
        timeLeft -= 1
        if timeLeft % 30 == 0 and timeLeft > 0 then
            notifyAll("⏱  " .. timeLeft .. "s remaining!")
        end
        -- Check win condition (all but one eliminated)
        local alive = {}
        for _, p in ipairs(Players:GetPlayers()) do
            local char = p.Character
            local hum  = char and char:FindFirstChildOfClass("Humanoid")
            if hum and hum.Health > 0 then
                table.insert(alive, p)
            end
        end
        if #alive <= 1 then
            roundActive = false
            if alive[1] then
                notifyAll("🏆 " .. alive[1].Name .. " WINS!", Color3.fromRGB(255, 215, 0))
            end
        end
    end

    -- End round
    roundActive = false
    roundEnded:FireAll()
    notifyAll("🔁 Round over! Returning to lobby...", Color3.fromRGB(108, 99, 255))
    killAll()
    task.wait(3)
    for _, player in ipairs(Players:GetPlayers()) do
        task.wait(0.2)
        player:LoadCharacter()
        task.wait(0.5)
        teleportToLobby(player)
    end
    task.wait(3)
end
"""


# ─── Python scripts ────────────────────────────────────────────────────────────

def _gen_python(hint: str) -> str:
    if "flask" in hint or "web" in hint:
        code = _python_flask()
        return _wrap_output("Flask Web Server", "python", code)
    if "scraper" in hint or "scrape" in hint:
        code = _python_scraper()
        return _wrap_output("Web Scraper", "python", code)
    code = _python_data_pipeline()
    return _wrap_output("Python Data Pipeline", "python", code)


def _python_flask() -> str:
    return '''"""
Nano AI — Flask REST API with auth, CRUD, and rate limiting
Run: pip install flask flask-jwt-extended && python app.py
"""
from flask import Flask, request, jsonify, g
from functools import wraps
import hashlib, secrets, time, json, os
from datetime import datetime, timedelta

app = Flask(__name__)
app.config["SECRET_KEY"] = secrets.token_hex(32)

# ── In-memory store (swap for a real DB in production) ──────────
USERS = {}       # {username: {password_hash, created}}
TOKENS = {}      # {token: {username, expires}}
ITEMS  = {}      # {id: {title, body, owner, created}}
RATE   = {}      # {ip: [timestamps]}

# ── Helpers ──────────────────────────────────────────────────────
def hash_pw(pw: str) -> str:
    return hashlib.sha256(pw.encode()).hexdigest()

def new_token(username: str) -> str:
    token   = secrets.token_hex(32)
    expires = datetime.utcnow() + timedelta(hours=24)
    TOKENS[token] = {"username": username, "expires": expires}
    return token

def rate_limit(max_per_minute=60):
    """Decorator: limit requests per IP."""
    def decorator(f):
        @wraps(f)
        def wrapper(*args, **kwargs):
            ip  = request.remote_addr
            now = time.time()
            RATE.setdefault(ip, [])
            RATE[ip] = [t for t in RATE[ip] if now - t < 60]
            if len(RATE[ip]) >= max_per_minute:
                return jsonify(error="Rate limit exceeded"), 429
            RATE[ip].append(now)
            return f(*args, **kwargs)
        return wrapper
    return decorator

def auth_required(f):
    """Decorator: require valid bearer token."""
    @wraps(f)
    def wrapper(*args, **kwargs):
        token = request.headers.get("Authorization", "").removeprefix("Bearer ").strip()
        info  = TOKENS.get(token)
        if not info or datetime.utcnow() > info["expires"]:
            return jsonify(error="Unauthorized"), 401
        g.username = info["username"]
        return f(*args, **kwargs)
    return wrapper

# ── Auth routes ──────────────────────────────────────────────────
@app.post("/auth/register")
@rate_limit(10)
def register():
    data = request.json or {}
    u, p = data.get("username","").strip(), data.get("password","")
    if not u or not p or len(p) < 6:
        return jsonify(error="username and password (min 6 chars) required"), 400
    if u in USERS:
        return jsonify(error="Username already exists"), 409
    USERS[u] = {"password_hash": hash_pw(p), "created": datetime.utcnow().isoformat()}
    return jsonify(message="Registered successfully"), 201

@app.post("/auth/login")
@rate_limit(10)
def login():
    data = request.json or {}
    u, p = data.get("username",""), data.get("password","")
    user = USERS.get(u)
    if not user or user["password_hash"] != hash_pw(p):
        return jsonify(error="Invalid credentials"), 401
    token = new_token(u)
    return jsonify(token=token, expires_in="24h")

@app.post("/auth/logout")
@auth_required
def logout():
    token = request.headers.get("Authorization","").removeprefix("Bearer ").strip()
    TOKENS.pop(token, None)
    return jsonify(message="Logged out")

# ── CRUD routes ──────────────────────────────────────────────────
@app.get("/items")
@auth_required
@rate_limit()
def list_items():
    user_items = [{"id":k,**v} for k,v in ITEMS.items() if v["owner"]==g.username]
    return jsonify(items=user_items, count=len(user_items))

@app.post("/items")
@auth_required
def create_item():
    data  = request.json or {}
    title = data.get("title","").strip()
    body  = data.get("body","")
    if not title:
        return jsonify(error="title is required"), 400
    item_id = secrets.token_hex(8)
    ITEMS[item_id] = {"title":title,"body":body,"owner":g.username,"created":datetime.utcnow().isoformat()}
    return jsonify(id=item_id, **ITEMS[item_id]), 201

@app.get("/items/<item_id>")
@auth_required
def get_item(item_id):
    item = ITEMS.get(item_id)
    if not item or item["owner"] != g.username:
        return jsonify(error="Not found"), 404
    return jsonify(id=item_id, **item)

@app.put("/items/<item_id>")
@auth_required
def update_item(item_id):
    item = ITEMS.get(item_id)
    if not item or item["owner"] != g.username:
        return jsonify(error="Not found"), 404
    data = request.json or {}
    if "title" in data: item["title"] = data["title"]
    if "body"  in data: item["body"]  = data["body"]
    return jsonify(id=item_id, **item)

@app.delete("/items/<item_id>")
@auth_required
def delete_item(item_id):
    item = ITEMS.get(item_id)
    if not item or item["owner"] != g.username:
        return jsonify(error="Not found"), 404
    del ITEMS[item_id]
    return jsonify(message="Deleted")

# ── Health ────────────────────────────────────────────────────────
@app.get("/health")
def health():
    return jsonify(status="ok", users=len(USERS), items=len(ITEMS))

if __name__ == "__main__":
    print("🚀 Nano AI Flask API running at http://localhost:5000")
    app.run(debug=True, port=5000)
'''


def _python_scraper() -> str:
    return '''"""
Nano AI — Web Scraper (urllib only, no external deps)
Scrapes a page, extracts headings and links, saves to JSON.
"""
import urllib.request, urllib.parse, html, re, json, time, sys
from datetime import datetime

HEADERS = {
    "User-Agent": "Mozilla/5.0 (compatible; NanoAI-Scraper/1.0)"
}

def fetch(url: str) -> str:
    req = urllib.request.Request(url, headers=HEADERS)
    with urllib.request.urlopen(req, timeout=10) as resp:
        return resp.read().decode(resp.headers.get_content_charset("utf-8"), errors="replace")

def clean(text: str) -> str:
    text = re.sub(r"<[^>]+>", " ", text)
    text = html.unescape(text)
    return re.sub(r"\\s+", " ", text).strip()

def scrape(url: str) -> dict:
    print(f"Fetching: {url}")
    raw = fetch(url)

    title_m = re.search(r"<title[^>]*>(.*?)</title>", raw, re.I|re.S)
    title   = clean(title_m.group(1)) if title_m else "No title"

    headings = re.findall(r"<h[1-3][^>]*>(.*?)</h[1-3]>", raw, re.I|re.S)
    headings = [clean(h) for h in headings][:20]

    links = re.findall(r'href=["\\'](https?://[^"\\'\\s>]+)', raw, re.I)
    links = list(dict.fromkeys(links))[:30]  # unique, preserve order

    paragraphs = re.findall(r"<p[^>]*>(.*?)</p>", raw, re.I|re.S)
    paragraphs = [clean(p) for p in paragraphs if len(clean(p)) > 40][:10]

    return {
        "url":        url,
        "title":      title,
        "scraped_at": datetime.utcnow().isoformat(),
        "headings":   headings,
        "links":      links,
        "paragraphs": paragraphs,
    }

def crawl(start_url: str, max_pages: int = 5, delay: float = 1.0) -> list:
    visited = set()
    queue   = [start_url]
    results = []
    base    = "{u.scheme}://{u.netloc}".format(u=urllib.parse.urlparse(start_url))

    while queue and len(results) < max_pages:
        url = queue.pop(0)
        if url in visited: continue
        visited.add(url)
        try:
            data = scrape(url)
            results.append(data)
            # Enqueue same-domain links
            for link in data["links"]:
                if link.startswith(base) and link not in visited:
                    queue.append(link)
            time.sleep(delay)
        except Exception as e:
            print(f"  Error scraping {url}: {e}")

    return results

if __name__ == "__main__":
    target  = sys.argv[1] if len(sys.argv) > 1 else "https://example.com"
    pages   = int(sys.argv[2]) if len(sys.argv) > 2 else 3
    results = crawl(target, max_pages=pages)

    out_file = "scraped_data.json"
    with open(out_file, "w", encoding="utf-8") as f:
        json.dump(results, f, indent=2, ensure_ascii=False)

    print(f"\\nScraped {len(results)} pages → {out_file}")
    for r in results:
        print(f"  • {r[\'title\'][:60]} ({len(r[\'links\'])} links)")
'''


def _python_data_pipeline() -> str:
    return '''"""
Nano AI — Data Processing Pipeline (stdlib only)
Reads CSV, cleans data, analyses, and outputs report.
"""
import csv, json, statistics, re
from collections import Counter, defaultdict
from datetime import datetime
from pathlib import Path

# ── Sample data generator ─────────────────────────────────────
SAMPLE_CSV = """name,age,city,score,date
Alice,28,New York,92,2024-01-15
Bob,35,London,78,2024-01-16
Carol,22,Tokyo,95,2024-01-16
Dave,,Paris,65,2024-01-17
Eve,29,New York,88,2024-01-18
Frank,41,London,,2024-01-18
Grace,19,Tokyo,91,2024-01-19
Henry,55,Paris,72,2024-01-20
Iris,33,New York,84,2024-01-20
Jack,27,London,79,2024-01-21
"""

# ── Loader ────────────────────────────────────────────────────
def load_csv(path=None, raw=None) -> list[dict]:
    if raw:
        import io
        reader = csv.DictReader(io.StringIO(raw))
    else:
        reader = csv.DictReader(open(path, encoding="utf-8"))
    return list(reader)

# ── Cleaner ───────────────────────────────────────────────────
def clean(records: list[dict]) -> list[dict]:
    cleaned, skipped = [], 0
    for row in records:
        try:
            age   = int(row["age"]) if row.get("age") else None
            score = float(row["score"]) if row.get("score") else None
            cleaned.append({
                "name":  row["name"].strip().title(),
                "age":   age,
                "city":  row["city"].strip(),
                "score": score,
                "date":  datetime.strptime(row["date"], "%Y-%m-%d"),
            })
        except Exception:
            skipped += 1
    print(f"  Loaded {len(cleaned)} rows, skipped {skipped} invalid")
    return cleaned

# ── Analyser ──────────────────────────────────────────────────
def analyse(records: list[dict]) -> dict:
    scores  = [r["score"] for r in records if r["score"] is not None]
    ages    = [r["age"]   for r in records if r["age"]   is not None]
    cities  = Counter(r["city"] for r in records)
    by_city = defaultdict(list)
    for r in records:
        if r["score"]: by_city[r["city"]].append(r["score"])

    city_avg = {c: round(statistics.mean(sc), 1) for c, sc in by_city.items()}
    top      = max(records, key=lambda r: r["score"] or 0)
    low      = min(records, key=lambda r: r["score"] or 999)

    return {
        "total_records": len(records),
        "scores": {
            "mean":   round(statistics.mean(scores), 2),
            "median": statistics.median(scores),
            "stdev":  round(statistics.stdev(scores), 2),
            "min":    min(scores), "max": max(scores),
        },
        "ages": {
            "mean":   round(statistics.mean(ages), 1),
            "min":    min(ages), "max": max(ages),
        },
        "city_distribution": dict(cities),
        "avg_score_by_city": city_avg,
        "top_scorer": {"name": top["name"], "score": top["score"]},
        "lowest_scorer": {"name": low["name"], "score": low["score"]},
    }

# ── Reporter ──────────────────────────────────────────────────
def report(analysis: dict) -> str:
    a = analysis
    lines = [
        "=" * 55,
        "  NANO AI — DATA PIPELINE REPORT",
        f"  Generated: {datetime.now().strftime(\'%Y-%m-%d %H:%M:%S\')}",
        "=" * 55,
        f"  Total records:  {a[\'total_records\']}",
        "",
        "  SCORE STATISTICS:",
        f"    Mean:    {a[\'scores\'][\'mean\']}",
        f"    Median:  {a[\'scores\'][\'median\']}",
        f"    Std Dev: {a[\'scores\'][\'stdev\']}",
        f"    Range:   {a[\'scores\'][\'min\']} – {a[\'scores\'][\'max\']}",
        "",
        "  AGE STATS:",
        f"    Mean: {a[\'ages\'][\'mean\']}  Range: {a[\'ages\'][\'min\']}–{a[\'ages\'][\'max\']}",
        "",
        "  CITY DISTRIBUTION:",
    ]
    for city, count in sorted(a["city_distribution"].items(), key=lambda x:-x[1]):
        avg  = a["avg_score_by_city"].get(city, "N/A")
        bar  = "█" * count
        lines.append(f"    {city:<12} {bar} ({count})  avg score: {avg}")
    lines += [
        "",
        f"  🏆 Top scorer:    {a[\'top_scorer\'][\'name\']} ({a[\'top_scorer\'][\'score\']})",
        f"  📉 Lowest scorer: {a[\'lowest_scorer\'][\'name\']} ({a[\'lowest_scorer\'][\'score\']})",
        "=" * 55,
    ]
    return "\\n".join(lines)

# ── Main ──────────────────────────────────────────────────────
if __name__ == "__main__":
    print("\\n[Nano AI] Data Pipeline\\n")
    raw     = load_csv(raw=SAMPLE_CSV)
    cleaned = clean(raw)
    result  = analyse(cleaned)
    print(report(result))

    Path("analysis.json").write_text(json.dumps(result, indent=2, default=str))
    print("\\n  Full analysis saved to analysis.json")
'''


# ─── JavaScript / Node ────────────────────────────────────────────────────────

def _gen_javascript(hint: str) -> str:
    if "react" in hint:
        code = _js_react_app()
        return _wrap_output("React App (vanilla)", "html", code)
    code = _js_node_api()
    return _wrap_output("Node.js Express API", "javascript", code)


def _js_react_app() -> str:
    code = """<!DOCTYPE html>
<html lang="en">
<head>
  <meta charset="UTF-8"><title>Nano AI — React App</title>
  <script src="https://unpkg.com/react@18/umd/react.development.js"></script>
  <script src="https://unpkg.com/react-dom@18/umd/react-dom.development.js"></script>
  <script src="https://unpkg.com/@babel/standalone/babel.min.js"></script>
  <style>
    *, *::before, *::after { box-sizing: border-box; margin: 0; padding: 0; }
    body { background: #0d0d1a; color: #e0e0f0; font-family: 'Segoe UI', system-ui, sans-serif; min-height: 100vh; padding: 40px; }
    .container { max-width: 600px; margin: 0 auto; }
    h1 { color: #6c63ff; font-size: 1.6rem; margin-bottom: 24px; text-align: center; }
    .input-row { display: flex; gap: 10px; margin-bottom: 24px; }
    input { flex: 1; padding: 12px 16px; background: #14142a; border: 1px solid #1e1e3a; border-radius: 8px; color: #e0e0f0; font-size: 1rem; outline: none; }
    input:focus { border-color: #6c63ff; }
    button { padding: 12px 20px; background: #6c63ff; color: #fff; border: none; border-radius: 8px; cursor: pointer; font-size: 1rem; transition: opacity .2s; }
    button:hover { opacity: .85; }
    .todo-item { display: flex; align-items: center; gap: 12px; padding: 14px 16px; background: #14142a; border: 1px solid #1e1e3a; border-radius: 10px; margin-bottom: 10px; transition: border-color .2s; }
    .todo-item:hover { border-color: #6c63ff; }
    .todo-item.done span { text-decoration: line-through; color: #555; }
    .todo-check { width: 20px; height: 20px; border: 2px solid #6c63ff; border-radius: 50%; cursor: pointer; display: flex; align-items: center; justify-content: center; flex-shrink: 0; transition: background .2s; }
    .todo-check.checked { background: #6c63ff; }
    .todo-item span { flex: 1; }
    .del-btn { background: rgba(255,101,132,.15); color: #ff6584; border: 1px solid rgba(255,101,132,.3); padding: 4px 10px; border-radius: 6px; cursor: pointer; font-size: .8rem; }
    .del-btn:hover { background: rgba(255,101,132,.3); }
    .stats { text-align: center; color: #555; font-size: .85rem; margin-top: 16px; }
    .filter-row { display: flex; gap: 8px; margin-bottom: 16px; justify-content: center; }
    .filter-btn { padding: 6px 14px; background: transparent; border: 1px solid #1e1e3a; border-radius: 20px; color: #888; cursor: pointer; font-size: .8rem; transition: all .2s; }
    .filter-btn.active { border-color: #6c63ff; color: #6c63ff; background: rgba(108,99,255,.1); }
    .empty { text-align: center; color: #333; padding: 40px; }
  </style>
</head>
<body>
<div id="root"></div>
<script type="text/babel">
const { useState, useMemo } = React;

function TodoApp() {
  const [todos,  setTodos]  = useState([
    { id: 1, text: 'Learn React hooks',  done: true  },
    { id: 2, text: 'Build a cool app',   done: false },
    { id: 3, text: 'Ship to production', done: false },
  ]);
  const [input,  setInput]  = useState('');
  const [filter, setFilter] = useState('all');

  const addTodo = () => {
    const text = input.trim();
    if (!text) return;
    setTodos(prev => [...prev, { id: Date.now(), text, done: false }]);
    setInput('');
  };

  const toggle = id => setTodos(prev => prev.map(t => t.id === id ? { ...t, done: !t.done } : t));
  const remove = id => setTodos(prev => prev.filter(t => t.id !== id));

  const visible = useMemo(() => {
    if (filter === 'active')    return todos.filter(t => !t.done);
    if (filter === 'completed') return todos.filter(t =>  t.done);
    return todos;
  }, [todos, filter]);

  const done  = todos.filter(t =>  t.done).length;
  const total = todos.length;

  return (
    <div className="container">
      <h1>⚡ Nano AI Todo</h1>
      <div className="input-row">
        <input
          value={input}
          onChange={e => setInput(e.target.value)}
          onKeyDown={e => e.key === 'Enter' && addTodo()}
          placeholder="Add a new task..."
        />
        <button onClick={addTodo}>Add</button>
      </div>
      <div className="filter-row">
        {['all','active','completed'].map(f => (
          <button key={f} className={`filter-btn ${filter===f?'active':''}`} onClick={() => setFilter(f)}>
            {f.charAt(0).toUpperCase()+f.slice(1)}
          </button>
        ))}
      </div>
      {visible.length === 0
        ? <div className="empty">No tasks here 🎉</div>
        : visible.map(t => (
            <div key={t.id} className={`todo-item ${t.done?'done':''}`}>
              <div className={`todo-check ${t.done?'checked':''}`} onClick={() => toggle(t.id)}>
                {t.done && '✓'}
              </div>
              <span>{t.text}</span>
              <button className="del-btn" onClick={() => remove(t.id)}>Delete</button>
            </div>
          ))
      }
      <div className="stats">{done} of {total} tasks completed</div>
    </div>
  );
}

ReactDOM.createRoot(document.getElementById('root')).render(<TodoApp />);
</script>
</body>
</html>"""
    return _wrap_output("React Todo App (CDN)", "html", code)


def _js_node_api() -> str:
    return """// Nano AI — Node.js Express REST API
// Run: npm install express && node server.js

const express = require('express');
const crypto  = require('crypto');

const app  = express();
const PORT = process.env.PORT || 3000;

app.use(express.json());

// ── In-memory store ──────────────────────────────────────────
const users = new Map();  // Map<id, User>
const items = new Map();  // Map<id, Item>

// ── Helpers ──────────────────────────────────────────────────
const uid   = () => crypto.randomBytes(8).toString('hex');
const hash  = pw => crypto.createHash('sha256').update(pw).digest('hex');
const ok    = (res, data, status = 200) => res.status(status).json(data);
const err   = (res, msg, status = 400) => res.status(status).json({ error: msg });

// ── Middleware: request logger ────────────────────────────────
app.use((req, _res, next) => {
  console.log(`${new Date().toISOString()} ${req.method} ${req.path}`);
  next();
});

// ── Users ────────────────────────────────────────────────────
app.post('/users', (req, res) => {
  const { name, email, password } = req.body || {};
  if (!name || !email || !password)
    return err(res, 'name, email, and password are required');
  if ([...users.values()].find(u => u.email === email))
    return err(res, 'Email already registered', 409);

  const id   = uid();
  const user = { id, name, email, passwordHash: hash(password), createdAt: new Date() };
  users.set(id, user);
  const { passwordHash, ...safeUser } = user;
  return ok(res, safeUser, 201);
});

app.get('/users', (_req, res) => {
  const list = [...users.values()].map(({ passwordHash, ...u }) => u);
  return ok(res, { users: list, count: list.length });
});

app.get('/users/:id', (req, res) => {
  const user = users.get(req.params.id);
  if (!user) return err(res, 'User not found', 404);
  const { passwordHash, ...safeUser } = user;
  return ok(res, safeUser);
});

app.put('/users/:id', (req, res) => {
  const user = users.get(req.params.id);
  if (!user) return err(res, 'User not found', 404);
  const { name, email } = req.body || {};
  if (name)  user.name  = name;
  if (email) user.email = email;
  user.updatedAt = new Date();
  const { passwordHash, ...safeUser } = user;
  return ok(res, safeUser);
});

app.delete('/users/:id', (req, res) => {
  if (!users.delete(req.params.id))
    return err(res, 'User not found', 404);
  return ok(res, { message: 'Deleted' });
});

// ── Items (owned by users) ────────────────────────────────────
app.post('/users/:userId/items', (req, res) => {
  if (!users.has(req.params.userId))
    return err(res, 'User not found', 404);
  const { title, body = '' } = req.body || {};
  if (!title) return err(res, 'title is required');
  const id   = uid();
  const item = { id, userId: req.params.userId, title, body, createdAt: new Date() };
  items.set(id, item);
  return ok(res, item, 201);
});

app.get('/users/:userId/items', (req, res) => {
  const list = [...items.values()].filter(i => i.userId === req.params.userId);
  return ok(res, { items: list, count: list.length });
});

app.delete('/items/:id', (req, res) => {
  if (!items.delete(req.params.id)) return err(res, 'Not found', 404);
  return ok(res, { message: 'Deleted' });
});

// ── Health ────────────────────────────────────────────────────
app.get('/health', (_req, res) =>
  ok(res, { status: 'ok', users: users.size, items: items.size, uptime: process.uptime() })
);

// ── 404 ───────────────────────────────────────────────────────
app.use((req, res) => err(res, `Route ${req.method} ${req.path} not found`, 404));

// ── Start ─────────────────────────────────────────────────────
app.listen(PORT, () =>
  console.log(`🚀 Nano AI Node API → http://localhost:${PORT}`)
);"""


# ─── REST API (generic) ────────────────────────────────────────────────────────

def _gen_rest_api(hint: str) -> str:
    if "node" in hint or "javascript" in hint or "express" in hint:
        return _wrap_output("Node.js Express API", "javascript", _js_node_api())
    return _wrap_output("Flask REST API", "python", _python_flask())


# ─── SQL ──────────────────────────────────────────────────────────────────────

def _gen_sql(hint: str) -> str:
    code = """-- Nano AI — Complete SQL Schema + Sample Queries
-- Compatible with SQLite, PostgreSQL, MySQL

-- ── Schema ────────────────────────────────────────────────────
CREATE TABLE users (
    id         INTEGER PRIMARY KEY AUTOINCREMENT,
    username   TEXT    NOT NULL UNIQUE,
    email      TEXT    NOT NULL UNIQUE,
    created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
    is_active  BOOLEAN DEFAULT 1
);

CREATE TABLE categories (
    id   INTEGER PRIMARY KEY AUTOINCREMENT,
    name TEXT NOT NULL UNIQUE
);

CREATE TABLE posts (
    id          INTEGER PRIMARY KEY AUTOINCREMENT,
    user_id     INTEGER NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    category_id INTEGER REFERENCES categories(id) ON DELETE SET NULL,
    title       TEXT    NOT NULL,
    body        TEXT    NOT NULL DEFAULT '',
    views       INTEGER NOT NULL DEFAULT 0,
    created_at  DATETIME DEFAULT CURRENT_TIMESTAMP,
    updated_at  DATETIME DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE comments (
    id         INTEGER PRIMARY KEY AUTOINCREMENT,
    post_id    INTEGER NOT NULL REFERENCES posts(id) ON DELETE CASCADE,
    user_id    INTEGER NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    body       TEXT    NOT NULL,
    created_at DATETIME DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE tags (
    id   INTEGER PRIMARY KEY AUTOINCREMENT,
    name TEXT NOT NULL UNIQUE
);

CREATE TABLE post_tags (
    post_id INTEGER NOT NULL REFERENCES posts(id) ON DELETE CASCADE,
    tag_id  INTEGER NOT NULL REFERENCES tags(id)  ON DELETE CASCADE,
    PRIMARY KEY (post_id, tag_id)
);

-- ── Indexes ───────────────────────────────────────────────────
CREATE INDEX idx_posts_user     ON posts(user_id);
CREATE INDEX idx_posts_category ON posts(category_id);
CREATE INDEX idx_posts_created  ON posts(created_at);
CREATE INDEX idx_comments_post  ON comments(post_id);

-- ── Seed data ─────────────────────────────────────────────────
INSERT INTO users (username, email) VALUES
  ('alice', 'alice@example.com'),
  ('bob',   'bob@example.com'),
  ('carol', 'carol@example.com');

INSERT INTO categories (name) VALUES ('Tech'), ('Science'), ('Gaming'), ('Art');

INSERT INTO posts (user_id, category_id, title, body, views) VALUES
  (1, 1, 'Getting started with Python', 'Python is a great first language...', 420),
  (2, 1, 'Why Rust is taking over',     'Rust eliminates memory bugs...', 810),
  (1, 3, 'Roblox scripting in 2024',    'Luau is fast and type-safe...', 330),
  (3, 2, 'Quantum computing explained', 'Qubits can be both 0 and 1...', 610);

INSERT INTO comments (post_id, user_id, body) VALUES
  (1, 2, 'Great intro!'), (1, 3, 'Saved me hours'), (2, 1, 'Love Rust!');

INSERT INTO tags (name) VALUES ('python'),('rust'),('lua'),('tutorial'),('beginner');
INSERT INTO post_tags VALUES (1,1),(1,4),(1,5),(2,2),(3,3),(3,4);

-- ── Useful queries ────────────────────────────────────────────

-- Posts with author name, category, comment count
SELECT
    p.id,
    p.title,
    u.username  AS author,
    c.name      AS category,
    COUNT(cm.id) AS comment_count,
    p.views
FROM posts p
JOIN users      u  ON u.id  = p.user_id
LEFT JOIN categories c  ON c.id  = p.category_id
LEFT JOIN comments   cm ON cm.post_id = p.id
GROUP BY p.id
ORDER BY p.views DESC;

-- Top authors by post count
SELECT u.username, COUNT(p.id) AS posts
FROM users u
LEFT JOIN posts p ON p.user_id = u.id
GROUP BY u.id
ORDER BY posts DESC;

-- Posts with all their tags (comma-separated)
SELECT p.title, GROUP_CONCAT(t.name, ', ') AS tags
FROM posts p
JOIN post_tags pt ON pt.post_id = p.id
JOIN tags     t   ON t.id       = pt.tag_id
GROUP BY p.id;

-- Full-text search simulation
SELECT * FROM posts
WHERE title LIKE '%python%' OR body LIKE '%python%';

-- Pagination (page 2, 10 per page)
SELECT * FROM posts ORDER BY created_at DESC LIMIT 10 OFFSET 10;

-- Transaction example
BEGIN;
UPDATE posts SET views = views + 1 WHERE id = 1;
INSERT INTO comments (post_id, user_id, body) VALUES (1, 3, 'New comment!');
COMMIT;
"""
    return _wrap_output("Complete SQL Schema + Queries", "sql", code)


# ─── General fallback ─────────────────────────────────────────────────────────

def _gen_react_shadcn(hint: str) -> str:
    if "dashboard" in hint:
        return _wrap_output("React + Tailwind Dashboard (shadcn/ui style)", "html", _react_dashboard())
    if "landing" in hint or "hero" in hint:
        return _wrap_output("React + Tailwind Landing Page", "html", _react_landing())
    if "card" in hint:
        return _wrap_output("React shadcn/ui Card Components", "html", _react_cards())
    return _wrap_output("React + Tailwind + shadcn/ui App (v0 style)", "html", _react_app())


def _react_app() -> str:
    return """<!DOCTYPE html>
<html lang="en" class="dark">
<head>
<meta charset="UTF-8">
<meta name="viewport" content="width=device-width,initial-scale=1">
<title>Nano AI — React App</title>
<script src="https://cdn.tailwindcss.com"></script>
<script>
  tailwind.config = {
    darkMode: 'class',
    theme: {
      extend: {
        colors: {
          border: 'hsl(240 3.7% 15.9%)',
          input:  'hsl(240 3.7% 15.9%)',
          ring:   'hsl(240 4.9% 83.9%)',
          background: 'hsl(240 10% 3.9%)',
          foreground:  'hsl(0 0% 98%)',
          primary:    { DEFAULT:'hsl(0 0% 98%)',   foreground:'hsl(240 5.9% 10%)' },
          secondary:  { DEFAULT:'hsl(240 3.7% 15.9%)', foreground:'hsl(0 0% 98%)' },
          muted:      { DEFAULT:'hsl(240 3.7% 15.9%)', foreground:'hsl(240 5% 64.9%)' },
          accent:     { DEFAULT:'hsl(240 3.7% 15.9%)', foreground:'hsl(0 0% 98%)' },
          card:       { DEFAULT:'hsl(240 10% 3.9%)',   foreground:'hsl(0 0% 98%)' },
        },
        borderRadius: { lg:'0.5rem', md:'calc(0.5rem - 2px)', sm:'calc(0.5rem - 4px)' },
        animation: {
          'fade-in':    'fadeIn .4s ease both',
          'slide-up':   'slideUp .5s ease both',
          'slide-right':'slideRight .4s ease both',
          'pulse-slow': 'pulse 3s infinite',
        },
        keyframes: {
          fadeIn:   { from:{opacity:'0'},            to:{opacity:'1'} },
          slideUp:  { from:{opacity:'0',transform:'translateY(16px)'}, to:{opacity:'1',transform:'translateY(0)'} },
          slideRight:{ from:{opacity:'0',transform:'translateX(-16px)'},to:{opacity:'1',transform:'translateX(0)'} },
        },
      }
    }
  }
</script>
<script src="https://unpkg.com/react@18/umd/react.development.js"></script>
<script src="https://unpkg.com/react-dom@18/umd/react-dom.development.js"></script>
<script src="https://unpkg.com/@babel/standalone/babel.min.js"></script>
<script src="https://unpkg.com/lucide@latest/dist/umd/lucide.js"></script>
<style>
  body { background: hsl(240 10% 3.9%); margin: 0; font-family: 'Inter', system-ui, sans-serif; }
  * { box-sizing: border-box; }
  .animate-delay-1 { animation-delay: .1s; }
  .animate-delay-2 { animation-delay: .2s; }
  .animate-delay-3 { animation-delay: .3s; }
</style>
</head>
<body>
<div id="root"></div>
<script type="text/babel">
const { useState, useEffect, useRef } = React;

// ── shadcn/ui-style primitives ──────────────────────────────────────────────

function Button({ children, variant = 'default', size = 'default', className = '', onClick, disabled }) {
  const base = 'inline-flex items-center justify-center gap-2 rounded-md text-sm font-medium transition-colors focus-visible:outline-none focus-visible:ring-1 focus-visible:ring-ring disabled:pointer-events-none disabled:opacity-50';
  const variants = {
    default:   'bg-primary text-primary-foreground shadow hover:bg-primary/90',
    secondary: 'bg-secondary text-secondary-foreground shadow-sm hover:bg-secondary/80',
    outline:   'border border-input bg-transparent shadow-sm hover:bg-accent hover:text-accent-foreground',
    ghost:     'hover:bg-accent hover:text-accent-foreground',
    destructive:'bg-red-500/90 text-white shadow-sm hover:bg-red-500',
  };
  const sizes = { default:'h-9 px-4 py-2', sm:'h-8 rounded-md px-3 text-xs', lg:'h-10 rounded-md px-8', icon:'h-9 w-9' };
  return (
    <button
      disabled={disabled}
      onClick={onClick}
      className={`${base} ${variants[variant]} ${sizes[size]} ${className}`}
    >{children}</button>
  );
}

function Card({ children, className = '' }) {
  return (
    <div className={`rounded-xl border border-white/10 bg-card text-card-foreground shadow-sm ${className}`}>
      {children}
    </div>
  );
}
function CardHeader({ children, className = '' }) {
  return <div className={`flex flex-col space-y-1.5 p-6 ${className}`}>{children}</div>;
}
function CardTitle({ children, className = '' }) {
  return <h3 className={`font-semibold leading-none tracking-tight text-foreground ${className}`}>{children}</h3>;
}
function CardDescription({ children }) {
  return <p className="text-sm text-muted-foreground">{children}</p>;
}
function CardContent({ children, className = '' }) {
  return <div className={`p-6 pt-0 ${className}`}>{children}</div>;
}

function Badge({ children, variant = 'default' }) {
  const base = 'inline-flex items-center rounded-full border px-2.5 py-0.5 text-xs font-semibold transition-colors';
  const v = {
    default:     'border-transparent bg-primary text-primary-foreground',
    secondary:   'border-transparent bg-secondary text-secondary-foreground',
    destructive: 'border-transparent bg-red-500/20 text-red-400 border-red-500/30',
    success:     'border-transparent bg-green-500/20 text-green-400 border-green-500/30',
    outline:     'text-foreground border-white/20',
  };
  return <span className={`${base} ${v[variant]}`}>{children}</span>;
}

function Separator({ className = '' }) {
  return <div className={`shrink-0 bg-border h-px w-full ${className}`} />;
}

// ── Animated counter ────────────────────────────────────────────────────────
function AnimatedNumber({ target, duration = 1200 }) {
  const [val, setVal] = useState(0);
  useEffect(() => {
    let start = null;
    const step = (ts) => {
      if (!start) start = ts;
      const prog = Math.min((ts - start) / duration, 1);
      setVal(Math.floor(prog * target));
      if (prog < 1) requestAnimationFrame(step);
    };
    requestAnimationFrame(step);
  }, [target]);
  return <>{val.toLocaleString()}</>;
}

// ── Framer-Motion-style entrance wrapper ─────────────────────────────────
function Motion({ children, delay = 0, className = '' }) {
  const ref = useRef(null);
  const [visible, setVisible] = useState(false);
  useEffect(() => {
    const t = setTimeout(() => setVisible(true), delay);
    return () => clearTimeout(t);
  }, []);
  return (
    <div
      ref={ref}
      style={{ transition: `opacity .5s ${delay}ms ease, transform .5s ${delay}ms ease`,
               opacity: visible ? 1 : 0,
               transform: visible ? 'translateY(0)' : 'translateY(20px)' }}
      className={className}
    >{children}</div>
  );
}

// ── Icon helper (Lucide) ─────────────────────────────────────────────────
function Icon({ name, size = 16, className = '' }) {
  const ref = useRef(null);
  useEffect(() => {
    if (ref.current && window.lucide) {
      ref.current.innerHTML = '';
      const svg = window.lucide.createElement(name);
      if (svg) { svg.setAttribute('width', size); svg.setAttribute('height', size); ref.current.appendChild(svg); }
    }
  }, [name, size]);
  return <span ref={ref} className={`inline-flex items-center justify-center ${className}`} />;
}

// ── Stats card ────────────────────────────────────────────────────────────
function StatCard({ label, value, icon, change, delay }) {
  return (
    <Motion delay={delay}>
      <Card className="hover:border-white/20 transition-all duration-300 hover:-translate-y-1 hover:shadow-lg hover:shadow-white/5">
        <CardHeader className="flex flex-row items-center justify-between pb-2">
          <CardTitle className="text-sm font-medium text-muted-foreground">{label}</CardTitle>
          <div className="h-8 w-8 rounded-full bg-secondary flex items-center justify-center">
            <Icon name={icon} size={15} className="text-foreground/70" />
          </div>
        </CardHeader>
        <CardContent>
          <div className="text-2xl font-bold text-foreground">
            <AnimatedNumber target={value} />
          </div>
          <p className="text-xs text-muted-foreground mt-1">
            <span className="text-green-400">+{change}%</span> from last month
          </p>
        </CardContent>
      </Card>
    </Motion>
  );
}

// ── Activity feed ─────────────────────────────────────────────────────────
const ACTIVITY = [
  { user: 'Alice Chen',   action: 'deployed', target: 'v2.4.1',   time: '2m ago',  badge: 'success' },
  { user: 'Bob Nakamura', action: 'opened PR', target: '#142',    time: '8m ago',  badge: 'default' },
  { user: 'Cleo Santos',  action: 'reviewed', target: 'API docs', time: '15m ago', badge: 'outline' },
  { user: 'Dan Osei',     action: 'closed',   target: 'Issue #89',time: '1h ago',  badge: 'destructive' },
  { user: 'Ena Park',     action: 'merged',   target: 'feat/auth', time: '2h ago', badge: 'success' },
];

function ActivityRow({ item, delay }) {
  return (
    <Motion delay={delay}>
      <div className="flex items-center gap-3 py-3">
        <div className="h-8 w-8 rounded-full bg-gradient-to-br from-violet-500/30 to-fuchsia-500/30 border border-white/10 flex items-center justify-center text-xs font-semibold text-foreground">
          {item.user[0]}
        </div>
        <div className="flex-1 min-w-0">
          <p className="text-sm text-foreground truncate">
            <span className="font-medium">{item.user}</span>
            <span className="text-muted-foreground mx-1">{item.action}</span>
            <span className="font-medium">{item.target}</span>
          </p>
          <p className="text-xs text-muted-foreground">{item.time}</p>
        </div>
        <Badge variant={item.badge}>{item.action}</Badge>
      </div>
    </Motion>
  );
}

// ── Nav ───────────────────────────────────────────────────────────────────
function Nav({ active, setActive }) {
  const tabs = [
    { id: 'overview',  label: 'Overview',  icon: 'layout-dashboard' },
    { id: 'projects',  label: 'Projects',  icon: 'folder-open' },
    { id: 'analytics', label: 'Analytics', icon: 'bar-chart-2' },
    { id: 'settings',  label: 'Settings',  icon: 'settings' },
  ];
  return (
    <nav className="fixed left-0 top-0 h-full w-56 border-r border-border bg-background/95 backdrop-blur flex flex-col p-4 gap-1 z-40">
      <div className="mb-6 px-2 py-1">
        <span className="text-lg font-bold tracking-tight text-foreground">nano</span>
        <span className="text-lg font-bold tracking-tight text-violet-400">ai</span>
        <span className="ml-2 text-xs text-muted-foreground font-normal">dashboard</span>
      </div>
      {tabs.map(t => (
        <button
          key={t.id}
          onClick={() => setActive(t.id)}
          className={`flex items-center gap-3 rounded-lg px-3 py-2 text-sm font-medium transition-colors w-full text-left ${
            active === t.id
              ? 'bg-secondary text-foreground'
              : 'text-muted-foreground hover:bg-secondary/50 hover:text-foreground'
          }`}
        >
          <Icon name={t.icon} size={15} />
          {t.label}
        </button>
      ))}
      <div className="mt-auto">
        <Separator className="mb-4" />
        <div className="flex items-center gap-3 px-3 py-2 rounded-lg bg-secondary/50">
          <div className="h-7 w-7 rounded-full bg-gradient-to-br from-violet-500 to-fuchsia-500 flex items-center justify-center text-xs font-bold text-white">N</div>
          <div>
            <p className="text-xs font-medium text-foreground">Nano AI</p>
            <p className="text-xs text-muted-foreground">claude-sonnet-4-6</p>
          </div>
        </div>
      </div>
    </nav>
  );
}

// ── Overview page ─────────────────────────────────────────────────────────
function Overview() {
  const stats = [
    { label: 'Total Requests', value: 48291, icon: 'zap',       change: 12.5, delay: 0   },
    { label: 'Active Users',   value: 2847,  icon: 'users',     change: 8.1,  delay: 80  },
    { label: 'Code Generated', value: 15032, icon: 'code-2',    change: 23.4, delay: 160 },
    { label: 'Avg Response ms',value: 342,   icon: 'timer',     change: 4.2,  delay: 240 },
  ];
  return (
    <div className="space-y-6">
      <Motion delay={0}>
        <div className="flex items-center justify-between">
          <div>
            <h1 className="text-2xl font-bold tracking-tight text-foreground">Overview</h1>
            <p className="text-muted-foreground text-sm">Welcome back — here's what's happening.</p>
          </div>
          <div className="flex gap-2">
            <Button variant="outline" size="sm"><Icon name="calendar" size={14} className="mr-1" />Jun 2025</Button>
            <Button size="sm"><Icon name="plus" size={14} className="mr-1" />New Project</Button>
          </div>
        </div>
      </Motion>

      <div className="grid grid-cols-2 xl:grid-cols-4 gap-4">
        {stats.map(s => <StatCard key={s.label} {...s} />)}
      </div>

      <div className="grid grid-cols-3 gap-4">
        <Motion delay={100} className="col-span-2">
          <Card>
            <CardHeader>
              <CardTitle>Recent Activity</CardTitle>
              <CardDescription>Latest events across your projects</CardDescription>
            </CardHeader>
            <CardContent>
              <div className="divide-y divide-border">
                {ACTIVITY.map((a, i) => <ActivityRow key={i} item={a} delay={i * 60} />)}
              </div>
            </CardContent>
          </Card>
        </Motion>

        <Motion delay={200}>
          <Card>
            <CardHeader>
              <CardTitle>Quick Actions</CardTitle>
              <CardDescription>Jump right in</CardDescription>
            </CardHeader>
            <CardContent className="flex flex-col gap-2">
              {[
                { label: 'Generate UI',   icon: 'sparkles',    variant: 'default' },
                { label: 'Ask Claude',    icon: 'message-square', variant: 'secondary' },
                { label: 'Run Exercise',  icon: 'play',        variant: 'outline' },
                { label: 'View Docs',     icon: 'book-open',   variant: 'ghost' },
              ].map(a => (
                <Button key={a.label} variant={a.variant} className="w-full justify-start gap-2">
                  <Icon name={a.icon} size={14} />
                  {a.label}
                </Button>
              ))}
            </CardContent>
          </Card>
        </Motion>
      </div>
    </div>
  );
}

// ── Root App ──────────────────────────────────────────────────────────────
function App() {
  const [active, setActive] = useState('overview');
  return (
    <div className="min-h-screen bg-background text-foreground">
      <Nav active={active} setActive={setActive} />
      <main className="ml-56 p-8 min-h-screen">
        {active === 'overview' && <Overview />}
        {active !== 'overview' && (
          <Motion delay={0}>
            <div className="flex flex-col items-center justify-center h-64 gap-3 text-muted-foreground">
              <Icon name="construction" size={40} className="opacity-30" />
              <p className="text-sm">"{active}" page — coming soon</p>
              <Button variant="outline" size="sm" onClick={() => setActive('overview')}>
                Back to Overview
              </Button>
            </div>
          </Motion>
        )}
      </main>
    </div>
  );
}

ReactDOM.createRoot(document.getElementById('root')).render(<App />);
</script>
</body>
</html>"""


def _react_dashboard() -> str:
    return _react_app()


def _react_landing() -> str:
    return """<!DOCTYPE html>
<html lang="en" class="dark">
<head>
<meta charset="UTF-8">
<meta name="viewport" content="width=device-width,initial-scale=1">
<title>Nano AI — React Landing</title>
<script src="https://cdn.tailwindcss.com"></script>
<script>
  tailwind.config = {
    darkMode:'class',
    theme:{extend:{
      colors:{
        border:'hsl(240 3.7% 15.9%)',
        background:'hsl(240 10% 3.9%)',
        foreground:'hsl(0 0% 98%)',
        muted:{DEFAULT:'hsl(240 3.7% 15.9%)',foreground:'hsl(240 5% 64.9%)'},
        card:{DEFAULT:'hsl(240 10% 3.9%)',foreground:'hsl(0 0% 98%)'},
      }
    }}
  }
</script>
<script src="https://unpkg.com/react@18/umd/react.development.js"></script>
<script src="https://unpkg.com/react-dom@18/umd/react-dom.development.js"></script>
<script src="https://unpkg.com/@babel/standalone/babel.min.js"></script>
<script src="https://unpkg.com/lucide@latest/dist/umd/lucide.js"></script>
<style>body{background:hsl(240 10% 3.9%);margin:0;font-family:'Inter',system-ui,sans-serif}*{box-sizing:border-box}</style>
</head>
<body>
<div id="root"></div>
<script type="text/babel">
const { useState, useEffect, useRef } = React;

function Icon({ name, size=16, className='' }) {
  const ref = useRef(null);
  useEffect(() => {
    if (ref.current && window.lucide) {
      ref.current.innerHTML = '';
      const svg = window.lucide.createElement(name);
      if (svg) { svg.setAttribute('width',size); svg.setAttribute('height',size); ref.current.appendChild(svg); }
    }
  }, [name, size]);
  return <span ref={ref} className={`inline-flex items-center justify-center ${className}`} />;
}

function Motion({ children, delay=0, y=20 }) {
  const [v,setV] = useState(false);
  useEffect(() => { const t=setTimeout(()=>setV(true),delay); return ()=>clearTimeout(t); }, []);
  return (
    <div style={{transition:`opacity .6s ${delay}ms ease, transform .6s ${delay}ms ease`,
                  opacity:v?1:0,transform:v?'none':`translateY(${y}px)`}}>
      {children}
    </div>
  );
}

function GradientText({ children, className='' }) {
  return (
    <span className={`bg-gradient-to-r from-violet-400 via-fuchsia-400 to-pink-400 bg-clip-text text-transparent ${className}`}>
      {children}
    </span>
  );
}

const FEATURES = [
  { icon:'brain',    title:'Claude-Powered',   desc:'Every answer backed by Claude claude-sonnet-4-6 — the world\'s most capable AI.' },
  { icon:'code-2',   title:'Any Language',      desc:'Python, Lua, TypeScript, Rust, Go — complete production-quality code on demand.' },
  { icon:'zap',      title:'Instant Generation',desc:'Full UI, 3D scenes, APIs, and games generated in seconds from plain English.' },
  { icon:'sparkles', title:'Crazy UIs',          desc:'Particle systems, matrix rain, galaxy canvases, neon glitch — insane visuals.' },
  { icon:'book-open',title:'Built-in Tutor',     desc:'Exercises, quizzes, XP leveling, and step-by-step concept explanations.' },
  { icon:'wifi',     title:'WebFetch',           desc:'Search the web, fetch URLs, pull live docs — all from the terminal.' },
];

function FeatureCard({ icon, title, desc, delay }) {
  const [hover, setHover] = useState(false);
  return (
    <Motion delay={delay}>
      <div
        onMouseEnter={()=>setHover(true)} onMouseLeave={()=>setHover(false)}
        style={{transition:'transform .3s ease, box-shadow .3s ease',
                transform:hover?'translateY(-4px)':'none',
                boxShadow:hover?'0 20px 40px rgba(139,92,246,.15)':'none'}}
        className="rounded-xl border border-white/10 bg-card p-6 cursor-default"
      >
        <div className="mb-4 inline-flex h-10 w-10 items-center justify-center rounded-lg bg-violet-500/10 border border-violet-500/20">
          <Icon name={icon} size={18} className="text-violet-400" />
        </div>
        <h3 className="font-semibold text-foreground mb-1.5">{title}</h3>
        <p className="text-sm text-muted-foreground leading-relaxed">{desc}</p>
      </div>
    </Motion>
  );
}

function App() {
  return (
    <div className="text-foreground min-h-screen overflow-x-hidden">
      {/* Nav */}
      <nav className="fixed top-0 w-full z-50 border-b border-white/5 bg-background/80 backdrop-blur">
        <div className="max-w-6xl mx-auto px-6 h-14 flex items-center justify-between">
          <span className="font-bold tracking-tight">nano<span className="text-violet-400">ai</span></span>
          <div className="flex items-center gap-2">
            <button className="text-sm text-muted-foreground hover:text-foreground transition-colors px-3 py-1.5">Docs</button>
            <button className="text-sm text-muted-foreground hover:text-foreground transition-colors px-3 py-1.5">GitHub</button>
            <button className="inline-flex items-center gap-1.5 rounded-md bg-violet-600 hover:bg-violet-500 px-3 py-1.5 text-sm font-medium text-white transition-colors">
              <Icon name="terminal" size={13} />
              Get Started
            </button>
          </div>
        </div>
      </nav>

      {/* Hero */}
      <section className="pt-32 pb-24 px-6 text-center max-w-4xl mx-auto">
        <Motion delay={0}>
          <div className="inline-flex items-center gap-2 rounded-full border border-violet-500/30 bg-violet-500/10 px-3 py-1 text-xs text-violet-300 mb-8">
            <Icon name="sparkles" size={11} className="text-violet-400" />
            Powered by Claude claude-sonnet-4-6
          </div>
        </Motion>
        <Motion delay={100}>
          <h1 className="text-5xl sm:text-6xl font-bold tracking-tight text-foreground mb-6 leading-tight">
            The AI tutor that<br/><GradientText>knows everything.</GradientText>
          </h1>
        </Motion>
        <Motion delay={200}>
          <p className="text-lg text-muted-foreground mb-10 max-w-xl mx-auto leading-relaxed">
            Ask any coding question. Generate any UI, game, or API. Learn with exercises and quizzes.
            All from your terminal, powered by Claude.
          </p>
        </Motion>
        <Motion delay={300}>
          <div className="flex flex-col sm:flex-row gap-3 justify-center">
            <button className="inline-flex items-center gap-2 rounded-lg bg-white text-black px-6 py-2.5 text-sm font-semibold hover:bg-white/90 transition-colors">
              <Icon name="download" size={15} />
              pip install nano-ai
            </button>
            <button className="inline-flex items-center gap-2 rounded-lg border border-white/20 bg-white/5 px-6 py-2.5 text-sm font-medium text-foreground hover:bg-white/10 transition-colors">
              <Icon name="play" size={15} />
              See Demo
            </button>
          </div>
        </Motion>

        {/* Terminal mockup */}
        <Motion delay={400}>
          <div className="mt-14 rounded-xl border border-white/10 bg-black/60 text-left p-4 font-mono text-sm shadow-2xl shadow-violet-900/10">
            <div className="flex gap-1.5 mb-3">
              <div className="h-3 w-3 rounded-full bg-red-500/80" />
              <div className="h-3 w-3 rounded-full bg-yellow-500/80" />
              <div className="h-3 w-3 rounded-full bg-green-500/80" />
            </div>
            <div className="space-y-1.5 text-xs sm:text-sm">
              <p><span className="text-violet-400">$</span> <span className="text-white">python -m ai_tutor</span></p>
              <p className="text-green-400">  ✦ FULL AI MODE — Claude API active.</p>
              <p><span className="text-violet-400">  Nano AI ›</span> <span className="text-white">generate a crazy galaxy UI</span></p>
              <p className="text-yellow-300">  ⚡ NANO AI GENERATED — COSMIC GALAXY UI</p>
              <p className="text-muted-foreground">  Language: html   Lines: 120</p>
              <p><span className="text-violet-400">  Nano AI ›</span> <span className="text-white animate-pulse">▊</span></p>
            </div>
          </div>
        </Motion>
      </section>

      {/* Features */}
      <section className="pb-24 px-6 max-w-6xl mx-auto">
        <Motion delay={0}>
          <div className="text-center mb-12">
            <h2 className="text-3xl font-bold tracking-tight text-foreground mb-3">Everything you need</h2>
            <p className="text-muted-foreground">One CLI, infinite possibilities.</p>
          </div>
        </Motion>
        <div className="grid sm:grid-cols-2 lg:grid-cols-3 gap-4">
          {FEATURES.map((f,i) => <FeatureCard key={f.title} {...f} delay={i*80} />)}
        </div>
      </section>

      {/* Footer */}
      <footer className="border-t border-white/5 py-8 text-center text-xs text-muted-foreground">
        <p>Built with React + Tailwind + Lucide · Generated by <span className="text-violet-400">Nano AI</span></p>
      </footer>
    </div>
  );
}

ReactDOM.createRoot(document.getElementById('root')).render(<App />);
</script>
</body>
</html>"""


def _react_cards() -> str:
    return """<!DOCTYPE html>
<html lang="en" class="dark">
<head>
<meta charset="UTF-8">
<meta name="viewport" content="width=device-width,initial-scale=1">
<title>shadcn/ui Card Components</title>
<script src="https://cdn.tailwindcss.com"></script>
<script>tailwind.config={darkMode:'class',theme:{extend:{colors:{border:'hsl(240 3.7% 15.9%)',background:'hsl(240 10% 3.9%)',foreground:'hsl(0 0% 98%)',muted:{DEFAULT:'hsl(240 3.7% 15.9%)',foreground:'hsl(240 5% 64.9%)'},card:{DEFAULT:'hsl(240 10% 3.9%)',foreground:'hsl(0 0% 98%)'},}}}}</script>
<script src="https://unpkg.com/react@18/umd/react.development.js"></script>
<script src="https://unpkg.com/react-dom@18/umd/react-dom.development.js"></script>
<script src="https://unpkg.com/@babel/standalone/babel.min.js"></script>
<script src="https://unpkg.com/lucide@latest/dist/umd/lucide.js"></script>
<style>body{background:hsl(240 10% 3.9%);margin:0;font-family:system-ui,sans-serif}*{box-sizing:border-box}</style>
</head>
<body>
<div id="root"></div>
<script type="text/babel">
const { useState, useEffect, useRef } = React;

function Icon({ name, size=16, className='' }) {
  const ref = useRef(null);
  useEffect(() => {
    if (ref.current && window.lucide) {
      ref.current.innerHTML = '';
      const svg = window.lucide.createElement(name);
      if (svg) { svg.setAttribute('width',size); svg.setAttribute('height',size); ref.current.appendChild(svg); }
    }
  }, [name, size]);
  return <span ref={ref} className={`inline-flex items-center justify-center ${className}`} />;
}

const CARDS = [
  { title:'Notification', desc:'You have 3 unread messages.', icon:'bell', color:'from-violet-500/20 to-fuchsia-500/20', border:'border-violet-500/20',
    content: <div className="space-y-2">
      {['Alice starred your project','Bob left a comment','Deploy succeeded'].map((m,i)=>
        <div key={i} className="flex items-center gap-2 text-sm text-foreground/80 p-2 rounded-lg bg-white/5">
          <div className="h-2 w-2 rounded-full bg-violet-400 shrink-0"/>
          {m}
        </div>)}
    </div>
  },
  { title:'Progress', desc:'Your weekly coding streak.', icon:'trending-up', color:'from-green-500/20 to-teal-500/20', border:'border-green-500/20',
    content: <div className="space-y-3">
      {[{lang:'Python',pct:87},{lang:'TypeScript',pct:72},{lang:'Rust',pct:43}].map(({lang,pct})=>
        <div key={lang}>
          <div className="flex justify-between text-xs text-foreground/70 mb-1"><span>{lang}</span><span>{pct}%</span></div>
          <div className="h-1.5 w-full rounded-full bg-white/10"><div className="h-full rounded-full bg-gradient-to-r from-green-400 to-teal-400 transition-all duration-1000" style={{width:`${pct}%`}}/></div>
        </div>)}
    </div>
  },
  { title:'Generate', desc:'Create code with Nano AI.', icon:'sparkles', color:'from-pink-500/20 to-rose-500/20', border:'border-pink-500/20',
    content: <div className="space-y-2">
      {['generate a React dashboard','generate a 3D scene','generate a Flask API'].map(cmd=>
        <button key={cmd} className="w-full text-left text-xs font-mono p-2 rounded-lg bg-white/5 hover:bg-white/10 transition-colors text-foreground/80 hover:text-foreground">
          {'> '}{cmd}
        </button>)}
    </div>
  },
  { title:'Stats', desc:"Today's Nano AI usage.", icon:'bar-chart-2', color:'from-blue-500/20 to-cyan-500/20', border:'border-blue-500/20',
    content: <div className="grid grid-cols-2 gap-2">
      {[{k:'Questions',v:24},{k:'Generated',v:8},{k:'XP Earned',v:420},{k:'Streak',v:'7d'}].map(({k,v})=>
        <div key={k} className="rounded-lg bg-white/5 p-3 text-center">
          <div className="text-lg font-bold text-foreground">{v}</div>
          <div className="text-xs text-foreground/50">{k}</div>
        </div>)}
    </div>
  },
];

function ShowcaseCard({ card, delay }) {
  const [vis, setVis] = useState(false);
  useEffect(() => { const t=setTimeout(()=>setVis(true),delay); return()=>clearTimeout(t); }, []);
  return (
    <div style={{transition:`opacity .5s ${delay}ms, transform .5s ${delay}ms`,opacity:vis?1:0,transform:vis?'none':'translateY(24px)'}}>
      <div className={`rounded-2xl border ${card.border} bg-gradient-to-br ${card.color} backdrop-blur p-5 hover:-translate-y-1 transition-transform duration-300`}>
        <div className="flex items-center gap-2 mb-1">
          <Icon name={card.icon} size={16} className="text-foreground/70" />
          <h3 className="font-semibold text-sm text-foreground">{card.title}</h3>
        </div>
        <p className="text-xs text-foreground/50 mb-4">{card.desc}</p>
        {card.content}
      </div>
    </div>
  );
}

function App() {
  return (
    <div className="min-h-screen p-8 text-foreground">
      <div className="max-w-4xl mx-auto">
        <div className="mb-8 text-center">
          <h1 className="text-3xl font-bold text-foreground mb-2">shadcn/ui Cards</h1>
          <p className="text-muted-foreground text-sm">Component showcase · Generated by Nano AI</p>
        </div>
        <div className="grid sm:grid-cols-2 gap-4">
          {CARDS.map((c,i) => <ShowcaseCard key={c.title} card={c} delay={i*120} />)}
        </div>
      </div>
    </div>
  );
}

ReactDOM.createRoot(document.getElementById('root')).render(<App />);
</script>
</body>
</html>"""


def _gen_general(request: str) -> str:
    r = request.lower()
    # Detect language
    lang_map = {
        "python": ("python", "def hello():\n    print('Hello, World!')\n\nhello()"),
        "java":   ("java",   'public class Main {\n    public static void main(String[] args) {\n        System.out.println("Hello, World!");\n    }\n}'),
        "rust":   ("rust",   'fn main() {\n    println!("Hello, World!");\n}'),
        "go":     ("go",     'package main\nimport "fmt"\nfunc main() { fmt.Println("Hello, World!") }'),
        "c++":    ("cpp",    '#include<iostream>\nint main(){std::cout<<"Hello, World!"<<std::endl;return 0;}'),
        "lua":    ("lua",    'print("Hello, World!")'),
    }
    for kw, (lang, snippet) in lang_map.items():
        if kw in r:
            return _wrap_output(f"Hello World in {lang.title()}", lang, snippet)

    return (
        "\n  🛠️  CODE GENERATOR\n"
        "  ─────────────────────────────────────────\n\n"
        "  I can generate complete, production-quality code.\n"
        "  Try one of these:\n\n"
        "    generate a 3D rotating cube\n"
        "    generate CSS animations\n"
        "    generate a landing page\n"
        "    generate a React dashboard (Tailwind + shadcn/ui)\n"
        "    generate a React landing page\n"
        "    generate a React card component\n"
        "    generate a Flask API\n"
        "    generate a Node.js Express server\n"
        "    generate a Python web scraper\n"
        "    generate a SQL schema\n"
        "    generate a Roblox game loop\n"
        "    generate a Roblox GUI script\n"
        "    generate a Roblox NPC AI\n"
        "    generate a portfolio website\n"
        "    generate a dashboard UI\n"
    )


# ─── Output wrapper ───────────────────────────────────────────────────────────

def _wrap_output(title: str, lang: str, code: str) -> str:
    lines = code.strip().split("\n")
    header = (
        f"\n  ⚡ NANO AI GENERATED — {title.upper()}\n"
        f"  {'─'*65}\n"
        f"  Language: {lang}   Lines: {len(lines)}\n"
        f"  {'─'*65}\n\n"
    )
    body = "\n".join("  " + l for l in lines)
    footer = (
        f"\n\n  {'─'*65}\n"
        f"  Copy the code above. Save as a .{_ext(lang)} file and run it!\n"
        f"  Type 'generate [something else]' for more code.\n"
    )
    return header + body + footer


def _ext(lang: str) -> str:
    return {
        "python": "py", "javascript": "js", "typescript": "ts",
        "lua": "lua", "java": "java", "rust": "rs", "go": "go",
        "html": "html", "css": "css", "sql": "sql", "cpp": "cpp",
    }.get(lang.lower(), lang[:3])
