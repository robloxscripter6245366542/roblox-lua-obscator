# Granite Lock — web app

Premium **emerald-glass** front end for the Granite Lock obfuscator, built as a
statically-exported **Next.js** app.

- **Next.js 14 (App Router) + TypeScript + Tailwind CSS** — component-based UI,
  responsive grid/flex, accessible controls.
- **Three.js WebGL** animated emerald "granite" shader background (domain-warped
  fBm fluid, pointer-reactive, `prefers-reduced-motion` aware, graceful CSS
  fallback if WebGL is unavailable).
- **Framer Motion** entrance/hover animations.
- **Engine untouched.** The obfuscator itself — the AST Transform engine
  (`ferret.web.js` / `ferret.ast.js`) and the hardened custom-bytecode **VM**
  engine (`vm/`, Fengari + embedded `luau-vm` modules) — is copied verbatim into
  `public/` and loaded as-is at runtime. This app is a UI shell; the validated
  engine code is unchanged.

## Develop

```sh
cd granite-lock
npm install
npm run dev      # http://localhost:3000
npm run build    # static export -> ./out
```

## Deploy

`output: 'export'` produces a fully static site in `out/`. The repo-root
`vercel.json` builds this app and serves `granite-lock/out`.

## Updating the engine

The engine assets in `public/` are copies of `../obfuscator-site/{vm,ferret.web.js,ferret.ast.js}`.
When the VM changes, re-run `obfuscator-site/vm/build-modules.js` and copy the
updated files into `public/` (they are intentionally verbatim, never edited here).
