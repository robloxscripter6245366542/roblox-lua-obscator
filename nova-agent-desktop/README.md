# Nova Agent — standalone desktop app (.exe)

Nova Agent as its own **Windows desktop app** (Electron): a Claude coding agent
with a fast `bash` tool + file tools, a red chat window, model picker, a folder
to work in, and a **command-approval** prompt. No VS Code required.

It reuses the same agent core as the VS Code extension (`agent.ts` + `tools.ts`);
only the shell around it is different.

## Build & run

```bash
cd nova-agent-desktop
npm install
npm start            # build + launch the app locally
```

Produce the installer / portable `.exe`:

```bash
npm run dist          # NSIS installer + portable .exe  → release/
npm run dist:portable # just the portable .exe
```

Output lands in `release/` (e.g. `NovaAgent-1.0.0.exe`). Building a **Windows**
`.exe` is most reliable **on Windows**; cross-building from macOS/Linux needs
Wine and extra electron-builder setup.

## Using it

1. Launch the app → click **API Key** → paste your Anthropic key (stored locally,
   encrypted with the OS keychain via Electron `safeStorage` when available).
2. Click **Folder** → pick the project folder the agent works in.
3. Pick a **model** from the dropdown, type a task, hit **Enter**.
4. When the agent wants to run a shell command, a native dialog asks
   **Allow / Allow all (session) / Deny**.

## Size note

Electron bundles Chromium, so the packaged app is **~70–90 MB** — it will **not**
be under 30 MB. If you need a sub‑30 MB standalone exe, the app has to use the
OS's built‑in WebView instead of bundling Chromium — that means a **Tauri**
(Rust) build. The UI (`renderer/index.html`) and the agent logic port over; the
shell (`main.ts`/`preload.ts`) would be replaced by Tauri's Rust `main.rs` +
commands. Say the word and I'll scaffold the Tauri version.

## Files
- `src/main.ts` — Electron main: window, settings (key/model/folder), IPC, the
  bash-approval dialog, and the agent wiring.
- `src/preload.ts` — safe `window.nova` bridge (contextIsolation on).
- `src/agent.ts` / `src/tools.ts` — the agent loop + tools (shared with the extension).
- `renderer/index.html` — the red chat UI.

## Security
`bash` runs commands on your machine with your permissions in the chosen folder.
The approval dialog is on by default. Your API key is stored locally (encrypted
where the OS supports it) and sent only to the Anthropic API.
