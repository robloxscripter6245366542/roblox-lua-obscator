import * as vscode from "vscode";
import { Agent } from "./agent";

const SECRET_KEY = "novaAgent.anthropicApiKey";

// Quick-action prompt templates. The current editor selection (or file) is
// appended so the sidebar buttons can "do this and that" to your code.
const QUICK: Record<string, { label: string; prompt: string }> = {
  explain: { label: "Explain", prompt: "Explain what this code does, clearly and concisely:" },
  fix: { label: "Fix bugs", prompt: "Find and fix any bugs in this code. Explain each fix and show the corrected code:" },
  test: { label: "Write tests", prompt: "Write thorough tests for this code:" },
  refactor: { label: "Refactor", prompt: "Refactor this code for readability and simplicity without changing behavior:" },
};

export function activate(context: vscode.ExtensionContext) {
  const provider = new NovaViewProvider(context);
  context.subscriptions.push(
    vscode.window.registerWebviewViewProvider("novaAgent.chat", provider, {
      webviewOptions: { retainContextWhenHidden: true },
    }),
    vscode.commands.registerCommand("novaAgent.focus", () =>
      vscode.commands.executeCommand("novaAgent.chat.focus"),
    ),
    vscode.commands.registerCommand("novaAgent.setApiKey", async () => {
      const key = await vscode.window.showInputBox({
        title: "Anthropic API Key",
        prompt: "Paste your API key (stored in VS Code secret storage).",
        password: true,
        ignoreFocusOut: true,
        placeHolder: "sk-ant-...",
      });
      if (key) {
        await context.secrets.store(SECRET_KEY, key.trim());
        vscode.window.showInformationMessage("Nova Agent: API key saved.");
        provider.post({ type: "keySaved" });
      }
    }),
    vscode.commands.registerCommand("novaAgent.clearApiKey", async () => {
      await context.secrets.delete(SECRET_KEY);
      provider.disconnect();
      vscode.window.showInformationMessage("Nova Agent: API key cleared and disconnected.");
      provider.post({ type: "connection", connected: false });
    }),
    vscode.workspace.onDidChangeConfiguration((e) => {
      if (e.affectsConfiguration("novaAgent")) provider.refreshConfig();
    }),
  );
}

export function deactivate() {}

class NovaViewProvider implements vscode.WebviewViewProvider {
  private view?: vscode.WebviewView;
  private agent?: Agent;

  constructor(private context: vscode.ExtensionContext) {}

  post(msg: any) {
    this.view?.webview.postMessage(msg);
  }

  disconnect() {
    this.agent?.disconnect();
  }

  private cfg() {
    return vscode.workspace.getConfiguration("novaAgent");
  }

  private root(): string {
    return vscode.workspace.workspaceFolders?.[0]?.uri.fsPath ?? process.cwd();
  }

  refreshConfig() {
    const c = this.cfg();
    this.agent?.setBaseUrl(c.get<string>("baseUrl", "") || undefined);
    this.post({
      type: "config",
      models: c.get<string[]>("models", ["claude-opus-5"]),
      model: c.get<string>("model", "claude-opus-5"),
      actions: Object.entries(QUICK).map(([id, q]) => ({ id, label: q.label })),
    });
  }

  private makeAgent(): Agent {
    const c = this.cfg();
    return new Agent(
      () => Promise.resolve(this.context.secrets.get(SECRET_KEY)),
      {
        root: this.root(),
        bashTimeoutMs: c.get<number>("bashTimeoutMs", 120000),
        onActivity: (line) => this.post({ type: "activity", line }),
      },
      {
        onText: (delta) => this.post({ type: "text", delta }),
        onActivity: (line) => this.post({ type: "activity", line }),
        onTurnEnd: () => this.post({ type: "turnEnd" }),
        onError: (message) => this.post({ type: "error", message }),
        onConnectionChange: (connected) => this.post({ type: "connection", connected }),
      },
      {
        model: c.get<string>("model", "claude-opus-5"),
        idleMs: c.get<number>("idleDisconnectMinutes", 5) * 60_000,
        baseURL: c.get<string>("baseUrl", "") || undefined,
      },
    );
  }

  /** Current editor selection, or the whole active file, as context. */
  private selectionContext(): string {
    const ed = vscode.window.activeTextEditor;
    if (!ed) return "";
    const sel = ed.selection;
    const text = sel && !sel.isEmpty ? ed.document.getText(sel) : ed.document.getText();
    const rel = vscode.workspace.asRelativePath(ed.document.uri);
    const capped = text.length > 12000 ? text.slice(0, 12000) + "\n…[truncated]" : text;
    return `\n\nFile: ${rel}\n\`\`\`\n${capped}\n\`\`\``;
  }

  resolveWebviewView(view: vscode.WebviewView) {
    this.view = view;
    view.webview.options = { enableScripts: true };
    view.webview.html = getHtml();
    this.agent = this.makeAgent();

    view.webview.onDidReceiveMessage(async (m) => {
      if (m?.type === "ready") {
        this.refreshConfig();
        const hasKey = !!(await this.context.secrets.get(SECRET_KEY));
        this.post({ type: "hasKey", hasKey });
      } else if (m?.type === "send" && typeof m.text === "string" && m.text.trim()) {
        await this.agent!.send(m.text.trim());
      } else if (m?.type === "quickAction" && QUICK[m.action]) {
        const prompt = QUICK[m.action].prompt + this.selectionContext();
        this.post({ type: "echo", text: QUICK[m.action].label });
        await this.agent!.send(prompt);
      } else if (m?.type === "setModel" && typeof m.model === "string") {
        this.agent!.setModel(m.model);
        await this.cfg().update("model", m.model, vscode.ConfigurationTarget.Global);
      } else if (m?.type === "reset") {
        this.agent!.reset();
        this.post({ type: "cleared" });
      } else if (m?.type === "needKey") {
        vscode.commands.executeCommand("novaAgent.setApiKey");
      }
    });

    view.onDidDispose(() => {
      this.agent?.dispose();
      this.agent = undefined;
      this.view = undefined;
    });
  }
}

function getHtml(): string {
  return /* html */ `<!doctype html>
<html>
<head>
<meta charset="utf-8" />
<meta http-equiv="Content-Security-Policy"
  content="default-src 'none'; style-src 'unsafe-inline'; script-src 'unsafe-inline';" />
<style>
  :root { color-scheme: light dark; }
  body { margin: 0; font: 12px/1.5 var(--vscode-font-family, system-ui); color: var(--vscode-foreground); background: var(--vscode-sideBar-background, var(--vscode-editor-background)); display: flex; flex-direction: column; height: 100vh; }
  .bar { display: flex; align-items: center; gap: 6px; padding: 6px 8px; border-bottom: 1px solid var(--vscode-panel-border, #3334); }
  .dot { width: 8px; height: 8px; border-radius: 50%; background: #888; flex: none; }
  .dot.on { background: #3fb950; }
  select { flex: 1; background: var(--vscode-dropdown-background); color: var(--vscode-dropdown-foreground); border: 1px solid var(--vscode-dropdown-border, #3335); border-radius: 4px; padding: 2px 4px; font: inherit; }
  .chips { display: flex; flex-wrap: wrap; gap: 4px; padding: 6px 8px; border-bottom: 1px solid var(--vscode-panel-border, #3334); }
  .chip { background: transparent; color: var(--vscode-foreground); border: 1px solid var(--vscode-panel-border, #3336); border-radius: 12px; padding: 2px 10px; cursor: pointer; font: inherit; }
  .chip:hover { background: var(--vscode-list-hoverBackground); }
  #log { flex: 1; overflow-y: auto; padding: 8px; }
  .msg { margin: 0 0 10px; white-space: pre-wrap; word-wrap: break-word; }
  .msg.user { color: var(--vscode-textLink-foreground); }
  .act { font-family: var(--vscode-editor-font-family, monospace); font-size: 11px; opacity: .75; border-left: 2px solid var(--vscode-panel-border, #3335); padding: 2px 6px; margin: 3px 0; white-space: pre-wrap; }
  .err { color: var(--vscode-errorForeground, #f66); }
  footer { border-top: 1px solid var(--vscode-panel-border, #3334); padding: 6px; display: flex; gap: 6px; }
  textarea { flex: 1; resize: none; height: 40px; background: var(--vscode-input-background); color: var(--vscode-input-foreground); border: 1px solid var(--vscode-input-border, #3335); border-radius: 6px; padding: 6px; font: inherit; }
  button.send { background: var(--vscode-button-background); color: var(--vscode-button-foreground); border: 0; border-radius: 6px; padding: 0 12px; cursor: pointer; }
</style>
</head>
<body>
  <div class="bar">
    <span class="dot" id="dot"></span>
    <select id="model" title="Model"></select>
    <button class="chip" id="clear" title="New chat">New</button>
  </div>
  <div class="chips" id="chips"></div>
  <div id="log"></div>
  <footer>
    <textarea id="input" placeholder="Tell Nova what to do…  (Enter to send)"></textarea>
    <button class="send" id="sendBtn">Send</button>
  </footer>
<script>
  const vscode = acquireVsCodeApi();
  const log = document.getElementById('log');
  const input = document.getElementById('input');
  const dot = document.getElementById('dot');
  const modelSel = document.getElementById('model');
  const chips = document.getElementById('chips');
  let current = null;

  function add(cls, text) {
    const d = document.createElement('div'); d.className = 'msg ' + cls; d.textContent = text;
    log.appendChild(d); log.scrollTop = log.scrollHeight; return d;
  }
  function send() {
    const text = input.value.trim(); if (!text) return;
    add('user', text); input.value = ''; current = null;
    vscode.postMessage({ type: 'send', text });
  }
  document.getElementById('sendBtn').onclick = send;
  document.getElementById('clear').onclick = () => { log.innerHTML=''; current=null; vscode.postMessage({type:'reset'}); };
  input.addEventListener('keydown', (e) => { if (e.key === 'Enter' && !e.shiftKey) { e.preventDefault(); send(); } });
  modelSel.onchange = () => vscode.postMessage({ type: 'setModel', model: modelSel.value });

  window.addEventListener('message', (ev) => {
    const m = ev.data;
    if (m.type === 'text') {
      if (!current) current = add('assistant', '');
      current.textContent += m.delta; log.scrollTop = log.scrollHeight;
    } else if (m.type === 'activity') {
      const d = document.createElement('div'); d.className='act'; d.textContent=m.line;
      log.appendChild(d); log.scrollTop = log.scrollHeight; current = null;
    } else if (m.type === 'echo') {
      add('user', m.text); current = null;
    } else if (m.type === 'error') { add('msg err', m.message); current = null; }
    else if (m.type === 'turnEnd') { current = null; }
    else if (m.type === 'connection') { dot.className = 'dot' + (m.connected ? ' on' : ''); }
    else if (m.type === 'hasKey') { if (!m.hasKey) add('msg err', 'No API key set — run “Nova Agent: Set Anthropic API Key”.'); }
    else if (m.type === 'config') {
      modelSel.innerHTML = '';
      (m.models || []).forEach((id) => {
        const o = document.createElement('option'); o.value = id; o.textContent = id;
        if (id === m.model) o.selected = true; modelSel.appendChild(o);
      });
      chips.innerHTML = '';
      (m.actions || []).forEach((a) => {
        const b = document.createElement('button'); b.className='chip'; b.textContent=a.label;
        b.onclick = () => vscode.postMessage({ type: 'quickAction', action: a.id });
        chips.appendChild(b);
      });
    }
  });

  vscode.postMessage({ type: 'ready' });
</script>
</body>
</html>`;
}
