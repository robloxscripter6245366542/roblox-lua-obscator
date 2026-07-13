'use client';
import { useCallback, useEffect, useRef, useState } from 'react';
import { AnimatePresence, motion } from 'framer-motion';

// The engine lives in /public as plain JS and attaches these globals (untouched).
declare global {
  interface Window {
    FerretAST?: { obfuscate: (src: string, opts: any) => string };
    FerretVM?: { compile: (src: string) => string; ready: () => boolean };
    fengari?: unknown;
  }
}

type Engine = 'transform' | 'vm';
type Layer = 'rename' | 'numbers' | 'strings';

const SAMPLE = `-- sample Roblox-style script
local Players = game and game:GetService("Players")
local Config = { name = "granite lock demo", speed = 16, keys = {"a","b","c"} }

local function greet(who)
  return "hello, " .. tostring(who) .. "!"
end

for i = 1, #Config.keys do
  print(i, Config.keys[i], greet(Config.name))
end

local total = 0
for _, n in ipairs({10, 20, 30, 42}) do total = total + n end
print("total =", total, "speed =", Config.speed)
`;

const fmtBytes = (n: number) => (n < 1024 ? `${n} bytes` : `${(n / 1024).toFixed(1)} KB`);

function loadScript(src: string): Promise<void> {
  return new Promise((resolve, reject) => {
    if (document.querySelector(`script[src="${src}"]`)) return resolve();
    const s = document.createElement('script');
    s.src = src;
    s.onload = () => resolve();
    s.onerror = () => reject(new Error(`failed to load ${src}`));
    document.head.appendChild(s);
  });
}

export default function Obfuscator() {
  const [engine, setEngine] = useState<Engine>('transform');
  const [layers, setLayers] = useState<Record<Layer, boolean>>({ rename: true, numbers: true, strings: true });
  const [seed, setSeed] = useState(7);
  const [source, setSource] = useState('');
  const [output, setOutput] = useState('');
  const [status, setStatus] = useState<{ kind: 'idle' | 'ok' | 'err' | 'busy'; msg: string }>({ kind: 'idle', msg: 'Ready.' });
  const [outStat, setOutStat] = useState('—');
  const [copied, setCopied] = useState(false);
  const vmReady = useRef(false);

  // base (Transform) engine scripts — load once
  useEffect(() => {
    loadScript('/ferret.web.js').then(() => loadScript('/ferret.ast.js')).catch(() => {});
  }, []);

  const isVM = engine === 'vm';
  const target = isVM
    ? '🧬 Hardened bytecode VM — encrypted, per-build opcodes, no loadstring, source never present'
    : '✅ Pure Luau — runs in vanilla Roblox (LocalScripts)';

  const ensureVM = useCallback(async () => {
    if (vmReady.current && window.FerretVM) return;
    setStatus({ kind: 'busy', msg: '⏳ Loading VM compiler…' });
    await loadScript('/vm/fengari-web.js');
    await loadScript('/vm/modules.js');
    await loadScript('/vm/ferret-vm.js');
    vmReady.current = true;
  }, []);

  const run = useCallback(async () => {
    const src = source;
    if (!src.trim()) { setStatus({ kind: 'err', msg: '✗ Nothing to obfuscate — paste some Lua first.' }); return; }
    const t0 = performance.now();
    try {
      if (isVM) {
        await ensureVM();
        if (!window.FerretVM) throw new Error('Could not load VM compiler.');
        const out = window.FerretVM.compile(src);
        setOutput(out);
        const ms = (performance.now() - t0).toFixed(0);
        setOutStat(`${fmtBytes(out.length)}  (${src.length ? (out.length / src.length).toFixed(1) : '0'}×)`);
        setStatus({ kind: 'ok', msg: `✓ VM-compiled · ${fmtBytes(src.length)} → ${fmtBytes(out.length)} · custom bytecode · ${ms} ms` });
      } else {
        const sel = (Object.keys(layers) as Layer[]).filter((l) => layers[l]);
        if (sel.length === 0) { setStatus({ kind: 'err', msg: '✗ Select at least one layer.' }); return; }
        if (!window.FerretAST) { await loadScript('/ferret.web.js'); await loadScript('/ferret.ast.js'); }
        const out = window.FerretAST!.obfuscate(src, { seed, layers: sel, chunkname: 'input.lua' });
        setOutput(out);
        const ms = (performance.now() - t0).toFixed(0);
        setOutStat(`${fmtBytes(out.length)}  (${src.length ? (out.length / src.length).toFixed(1) : '0'}×)`);
        setStatus({ kind: 'ok', msg: `✓ Obfuscated · ${fmtBytes(src.length)} → ${fmtBytes(out.length)} · ${sel.join(' + ')} · seed ${seed} · ${ms} ms` });
      }
    } catch (e: any) {
      setOutput('');
      setOutStat('—');
      setStatus({ kind: 'err', msg: `✗ ${e?.message ?? e}` });
    }
  }, [source, isVM, ensureVM, layers, seed]);

  const copy = () => {
    if (!output) return;
    navigator.clipboard.writeText(output).then(() => { setCopied(true); setTimeout(() => setCopied(false), 1200); });
  };
  const download = () => {
    if (!output) return;
    const blob = new Blob([output], { type: 'text/plain' });
    const a = document.createElement('a');
    a.href = URL.createObjectURL(blob);
    a.download = isVM ? 'protected.lua' : 'obfuscated.lua';
    a.click();
    URL.revokeObjectURL(a.href);
  };

  // ⌘/Ctrl+Enter to run
  const onKey = (e: React.KeyboardEvent) => { if ((e.metaKey || e.ctrlKey) && e.key === 'Enter') { e.preventDefault(); run(); } };

  return (
    <div className="relative z-10 mx-auto flex h-full max-h-screen w-full flex-col">
      <Nav />
      <Controls
        engine={engine} setEngine={setEngine}
        layers={layers} setLayers={setLayers}
        seed={seed} setSeed={setSeed}
        onSample={() => { setSource(SAMPLE); }}
        onRun={run}
      />

      <main className="grid min-h-0 flex-1 grid-cols-1 gap-4 px-4 pb-3 md:grid-cols-2 md:px-6">
        <Panel title="Source" stat={`${fmtBytes(source.length)}`}
          actions={<button onClick={() => { setSource(''); setOutput(''); setOutStat('—'); setStatus({ kind: 'idle', msg: 'Ready.' }); }} className="chip">Clear</button>}>
          <textarea
            value={source} onChange={(e) => setSource(e.target.value)} onKeyDown={onKey}
            spellCheck={false} placeholder="-- Paste your Lua / Luau script here&#10;&#10;print('hello world')"
            className="code scroll h-full w-full resize-none bg-transparent px-4 py-4 text-[#e9f3ee] outline-none placeholder:text-[#5f7369]"
          />
        </Panel>
        <Panel title="Obfuscated" stat={outStat}
          actions={<>
            <button onClick={download} className="chip">Download</button>
            <button onClick={copy} className="chip chip-accent">{copied ? 'Copied ✓' : 'Copy'}</button>
          </>}>
          <textarea
            value={output} readOnly spellCheck={false}
            placeholder="-- Output appears here — obfuscated or VM-protected, ready to ship"
            className="code scroll h-full w-full resize-none whitespace-pre bg-transparent px-4 py-4 text-[#d7e6de] outline-none placeholder:text-[#5f7369]"
          />
        </Panel>
      </main>

      <StatusBar status={status} target={target} />
    </div>
  );
}

/* ---------------- sub-components ---------------- */

function Nav() {
  return (
    <motion.header
      initial={{ y: -18, opacity: 0 }} animate={{ y: 0, opacity: 1 }} transition={{ duration: 0.5, ease: 'easeOut' }}
      className="glass sticky top-0 z-20 flex items-center gap-4 rounded-none px-5 py-3.5"
    >
      <div className="flex items-center gap-3">
        <motion.div
          whileHover={{ rotate: -6, scale: 1.05 }} transition={{ type: 'spring', stiffness: 300 }}
          className="grid h-9 w-9 place-items-center rounded-[11px] text-emerald-mint"
          style={{ background: 'linear-gradient(160deg,#065f46,#0b1210)', boxShadow: '0 6px 20px -6px rgba(16,185,129,.55), inset 0 1px 0 rgba(255,255,255,.12), inset 0 0 0 1px rgba(110,231,183,.22)' }}
        >
          <LockMark />
        </motion.div>
        <div className="text-[1.12rem] font-bold tracking-tight">
          <span className="grad-text">Granite</span> Lock
        </div>
      </div>
      <span className="hidden items-center gap-2 rounded-full border border-[rgba(120,220,180,.16)] bg-white/[.02] px-2.5 py-1 text-[.7rem] text-[#9cb2a8] sm:flex">
        <span className="h-1.5 w-1.5 rounded-full bg-emerald-glow shadow-[0_0_8px_#34d399]" />
        Custom bytecode VM · Roblox Luau
      </span>
      <div className="flex-1" />
      <nav className="flex items-center gap-1.5 text-[.82rem]">
        <a href="/deobfuscator.html" className="rounded-lg px-3 py-1.5 text-[#9cb2a8] transition hover:bg-white/5 hover:text-white">Deobfuscator</a>
        <a href="https://github.com/robloxscripter6245366542/roblox-lua-obscator" target="_blank" rel="noopener"
          className="rounded-lg border border-[rgba(120,220,180,.16)] px-3 py-1.5 text-[#9cb2a8] transition hover:bg-white/5 hover:text-white">GitHub ↗</a>
      </nav>
    </motion.header>
  );
}

function Controls(props: {
  engine: Engine; setEngine: (e: Engine) => void;
  layers: Record<Layer, boolean>; setLayers: (l: Record<Layer, boolean>) => void;
  seed: number; setSeed: (n: number) => void;
  onSample: () => void; onRun: () => void;
}) {
  const { engine, setEngine, layers, setLayers, seed, setSeed, onSample, onRun } = props;
  const vm = engine === 'vm';
  return (
    <motion.section
      initial={{ opacity: 0 }} animate={{ opacity: 1 }} transition={{ delay: 0.1, duration: 0.5 }}
      className="relative z-10 flex flex-wrap items-center gap-3.5 px-5 py-3.5 md:px-6"
    >
      <Group label="Engine">
        <Pill checked={!vm} onClick={() => setEngine('transform')} kind="engine">Transform</Pill>
        <Pill checked={vm} onClick={() => setEngine('vm')} kind="engine">VM&nbsp;bytecode</Pill>
      </Group>

      <div className={`flex flex-wrap items-center gap-3.5 transition ${vm ? 'pointer-events-none opacity-30 grayscale' : ''}`}>
        <Group label="Layers">
          {(['rename', 'numbers', 'strings'] as Layer[]).map((l) => (
            <Pill key={l} checked={layers[l]} onClick={() => setLayers({ ...layers, [l]: !layers[l] })}>
              {l[0].toUpperCase() + l.slice(1)}
            </Pill>
          ))}
        </Group>
        <Group label="Seed">
          <div className="flex items-center overflow-hidden rounded-[10px] border border-[rgba(120,220,180,.16)] bg-white/[.03]">
            <input type="number" value={seed} min={0} max={2147483647}
              onChange={(e) => setSeed(parseInt(e.target.value || '0', 10) || 0)}
              className="code w-[110px] bg-transparent px-2.5 py-2 text-[#e9f3ee] outline-none" aria-label="Seed" />
            <button onClick={() => setSeed(Math.floor(Math.random() * 2147483647))}
              className="border-l border-[rgba(120,220,180,.16)] px-2.5 py-2 text-[#9cb2a8] transition hover:bg-white/5 hover:text-white" title="Random seed">🎲</button>
          </div>
        </Group>
      </div>

      <div className="hidden flex-1 md:block" />
      <button onClick={onSample} className="chip !px-4 !py-2 !text-[.85rem]">Load sample</button>
      <motion.button
        whileHover={{ y: -1, filter: 'brightness(1.08)' }} whileTap={{ y: 0, scale: 0.98 }}
        onClick={onRun}
        className="inline-flex items-center gap-2 rounded-[10px] px-4 py-2 text-[.85rem] font-bold text-[#04120c]"
        style={{ background: 'linear-gradient(135deg,#34d399,#059669)', boxShadow: '0 8px 22px -8px rgba(16,185,129,.75)' }}
      >
        Obfuscate <span className="rounded-[5px] border border-black/25 px-1.5 py-px font-mono text-[.68rem] opacity-70">⌘⏎</span>
      </motion.button>
    </motion.section>
  );
}

function Group({ label, children }: { label: string; children: React.ReactNode }) {
  return (
    <div className="flex items-center gap-2">
      <span className="text-[.68rem] font-bold uppercase tracking-[.09em] text-[#5f7369]">{label}</span>
      {children}
    </div>
  );
}

function Pill({ checked, onClick, children, kind }: { checked: boolean; onClick: () => void; children: React.ReactNode; kind?: 'engine' }) {
  return (
    <button onClick={onClick} aria-pressed={checked}
      className={`inline-flex items-center gap-2 rounded-[10px] border px-3 py-2 text-[.82rem] font-semibold transition
        ${checked
          ? 'border-[rgba(52,211,153,.55)] text-white'
          : 'border-[rgba(120,220,180,.16)] text-[#9cb2a8] hover:text-white'}`}
      style={checked
        ? { background: 'linear-gradient(180deg,rgba(52,211,153,.16),rgba(5,150,105,.05))', boxShadow: '0 0 0 1px rgba(52,211,153,.15),0 6px 18px -10px rgba(16,185,129,.6)' }
        : { background: 'rgba(30,38,33,.5)' }}
    >
      <span className={`h-[9px] w-[9px] rounded-full transition ${checked ? 'bg-emerald-mint shadow-[0_0_8px_#6ee7b7]' : 'bg-[#5f7369]'}`} />
      {children}
    </button>
  );
}

function Panel({ title, stat, actions, children }: { title: string; stat: string; actions?: React.ReactNode; children: React.ReactNode }) {
  return (
    <motion.section
      initial={{ opacity: 0, y: 14 }} animate={{ opacity: 1, y: 0 }} transition={{ duration: 0.5, ease: 'easeOut' }}
      className="glass flex min-w-0 flex-col overflow-hidden rounded-2xl"
    >
      <div className="flex items-center gap-2.5 border-b border-white/[.06] bg-gradient-to-b from-white/[.03] to-transparent px-4 py-2.5">
        <span className="text-[.72rem] font-bold uppercase tracking-[.08em] text-[#9cb2a8]">{title}</span>
        <span className="code text-[.72rem] text-[#5f7369]">{stat}</span>
        <div className="flex-1" />
        {actions}
      </div>
      {children}
    </motion.section>
  );
}

function StatusBar({ status, target }: { status: { kind: string; msg: string }; target: string }) {
  const color = status.kind === 'ok' ? 'text-emerald-glow' : status.kind === 'err' ? 'text-[#fb7185]' : 'text-[#9cb2a8]';
  return (
    <footer className="glass z-20 flex flex-wrap items-center gap-3.5 rounded-none px-5 py-2.5 text-[.78rem] text-[#9cb2a8]">
      <AnimatePresence mode="wait">
        <motion.span key={status.msg} initial={{ opacity: 0, y: 4 }} animate={{ opacity: 1, y: 0 }} exit={{ opacity: 0 }} transition={{ duration: 0.2 }}
          className={`font-semibold ${color}`}>{status.msg}</motion.span>
      </AnimatePresence>
      <div className="flex-1" />
      <span className="hidden text-[#7c9084] sm:inline" dangerouslySetInnerHTML={{ __html: target }} />
      <span className="opacity-40">·</span>
      <span className="flex items-center gap-1.5 text-[#5f7369]">
        <LockSmall /> 100% in-browser
      </span>
    </footer>
  );
}

function LockMark() {
  return (
    <svg viewBox="0 0 24 24" width="19" height="19" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round">
      <rect x="3.5" y="11" width="17" height="10.5" rx="3" />
      <path d="M7.5 11V7.2a4.5 4.5 0 0 1 9 0V11" />
      <circle cx="12" cy="16" r="1.4" fill="currentColor" stroke="none" />
    </svg>
  );
}
function LockSmall() {
  return (
    <svg width="13" height="13" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round" className="opacity-70">
      <rect x="3" y="11" width="18" height="11" rx="2" /><path d="M7 11V7a5 5 0 0 1 10 0v4" />
    </svg>
  );
}
