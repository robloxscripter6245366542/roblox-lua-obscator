import * as vscode from "vscode";
import { Agent } from "./agent";

const SECRET_KEY = "novaAgent.anthropicApiKey";

export function activate(context: vscode.ExtensionContext) {
  let panel: vscode.WebviewPanel | undefined;
  let agent: Agent | undefined;

  const getApiKey = () => Promise.resolve(context.secrets.get(SECRET_KEY));

  function workspaceRoot(): string {
    return vscode.workspace.workspaceFolders?.[0]?.uri.fsPath ?? process.cwd();
  }

  function post(msg: any) {
    panel?.webview.postMessage(msg);
  }

  function makeAgent(): Agent {
    const cfg = vscode.workspace.getConfiguration("novaAgent");
    return new Agent(
      getApiKey,
      {
        root: workspaceRoot(),
        bashTimeoutMs: cfg.get<number>("bashTimeoutMs", 120000),
        onActivity: (line) => post({ type: "activity", line }),
      },
      {
        onText: (delta) => post({ type: "text", delta }),
        onActivity: (line) => post({ type: "activity", line }),
        onTurnEnd: () => post({ type: "turnEnd" }),
        onError: (message) => post({ type: "error", message }),
        onConnectionChange: (connected) => post({ type: "connection", connected }),
      },
      {
        model: cfg.get<string>("model", "claude-opus-5"),
        idleMs: cfg.get<number>("idleDisconnectMinutes", 5) * 60_000,
      },
    );
  }

  function openPanel() {
    if (panel) {
      panel.reveal();
      return;
    }
    panel = vscode.window.createWebviewPanel(
      "novaAgent",
      "Nova Agent",
      vscode.ViewColumn.Beside,
      { enableScripts: true, retainContextWhenHidden: true },
    );
    panel.webview.html = getHtml();
    agent = makeAgent();

    panel.webview.onDidReceiveMessage(async (m) => {
      if (m?.type === "send" && typeof m.text === "string" && m.text.trim()) {
        await agent!.send(m.text.trim());
      } else if (m?.type === "reset") {
        agent!.reset();
        post({ type: "cleared" });
      } else if (m?.type === "needKey") {
        post({ type: "connection", connected: false });
        const has = !!(await getApiKey());
        if (!has) vscode.commands.executeCommand("novaAgent.setApiKey");
      }
    });

    panel.onDidDispose(() => {
      agent?.dispose(); // disconnects from Claude when the panel closes
      agent = undefined;
      panel = undefined;
    });
  }

  context.subscriptions.push(
    vscode.commands.registerCommand("novaAgent.open", openPanel),

    vscode.commands.registerCommand("novaAgent.setApiKey", async () => {
      const key = await vscode.window.showInputBox({
        title: "Anthropic API Key",
        prompt: "Paste your Anthropic API key (stored in VS Code secret storage).",
        password: true,
        ignoreFocusOut: true,
        placeHolder: "sk-ant-...",
      });
      if (key) {
        await context.secrets.store(SECRET_KEY, key.trim());
        vscode.window.showInformationMessage("Nova Agent: API key saved.");
        post({ type: "keySaved" });
      }
    }),

    vscode.commands.registerCommand("novaAgent.clearApiKey", async () => {
      await context.secrets.delete(SECRET_KEY);
      agent?.disconnect();
      vscode.window.showInformationMessage("Nova Agent: API key cleared and disconnected.");
      post({ type: "connection", connected: false });
    }),
  );
}

export function deactivate() {}

function getHtml(): string {
  return /* html */ `<!doctype html>
<html>
<head>
<meta charset="utf-8" />
<meta http-equiv="Content-Security-Policy"
  content="default-src 'none'; style-src 'unsafe-inline'; script-src 'unsafe-inline';" />
<style>
  :root { color-scheme: light dark; }
  body { margin: 0; font: 13px/1.5 var(--vscode-font-family, system-ui); color: var(--vscode-foreground); background: var(--vscode-editor-background); display: flex; flex-direction: column; height: 100vh; }
  header { display: flex; align-items: center; gap: 8px; padding: 8px 12px; border-bottom: 1px solid var(--vscode-panel-border, #3334); }
  header b { font-size: 13px; }
  .dot { width: 8px; height: 8px; border-radius: 50%; background: #888; }
  .dot.on { background: #3fb950; }
  #log { flex: 1; overflow-y: auto; padding: 12px; }
  .msg { margin: 0 0 12px; white-space: pre-wrap; word-wrap: break-word; }
  .msg.user { color: var(--vscode-textLink-foreground); }
  .msg.assistant { }
  .act { font-family: var(--vscode-editor-font-family, monospace); font-size: 12px; opacity: .75; border-left: 2px solid var(--vscode-panel-border, #3335); padding: 2px 8px; margin: 4px 0; white-space: pre-wrap; }
  .err { color: var(--vscode-errorForeground, #f66); }
  footer { border-top: 1px solid var(--vscode-panel-border, #3334); padding: 8px; display: flex; gap: 8px; }
  textarea { flex: 1; resize: none; height: 44px; background: var(--vscode-input-background); color: var(--vscode-input-foreground); border: 1px solid var(--vscode-input-border, #3335); border-radius: 6px; padding: 8px; font: inherit; }
  button { background: var(--vscode-button-background); color: var(--vscode-button-foreground); border: 0; border-radius: 6px; padding: 0 14px; cursor: pointer; }
  button.secondary { background: transparent; color: var(--vscode-foreground); border: 1px solid var(--vscode-panel-border, #3335); }
</style>
</head>
<body>
  <header>
    <span class="dot" id="dot"></span>
    <b>Nova Agent</b>
    <span style="flex:1"></span>
    <button class="secondary" id="clear">New chat</button>
  </header>
  <div id="log"></div>
  <footer>
    <textarea id="input" placeholder="Ask Nova to build, run, or fix something…  (Enter to send, Shift+Enter for newline)"></textarea>
    <button id="send">Send</button>
  </footer>
<script>
  const vscode = acquireVsCodeApi();
  const log = document.getElementById('log');
  const input = document.getElementById('input');
  const dot = document.getElementById('dot');
  let current = null; // current assistant bubble

  function add(cls, text) {
    const d = document.createElement('div');
    d.className = 'msg ' + cls;
    d.textContent = text;
    log.appendChild(d);
    log.scrollTop = log.scrollHeight;
    return d;
  }
  function send() {
    const text = input.value.trim();
    if (!text) return;
    add('user', text);
    input.value = '';
    current = null;
    vscode.postMessage({ type: 'send', text });
  }
  document.getElementById('send').onclick = send;
  document.getElementById('clear').onclick = () => { log.innerHTML=''; current=null; vscode.postMessage({type:'reset'}); };
  input.addEventListener('keydown', (e) => {
    if (e.key === 'Enter' && !e.shiftKey) { e.preventDefault(); send(); }
  });

  window.addEventListener('message', (ev) => {
    const m = ev.data;
    if (m.type === 'text') {
      if (!current) current = add('assistant', '');
      current.textContent += m.delta;
      log.scrollTop = log.scrollHeight;
    } else if (m.type === 'activity') {
      const d = document.createElement('div'); d.className='act'; d.textContent=m.line;
      log.appendChild(d); log.scrollTop = log.scrollHeight; current = null;
    } else if (m.type === 'error') {
      add('msg err', m.message); current = null;
    } else if (m.type === 'turnEnd') {
      current = null;
    } else if (m.type === 'connection') {
      dot.className = 'dot' + (m.connected ? ' on' : '');
    }
  });

  vscode.postMessage({ type: 'needKey' });
</script>
</body>
</html>`;
}
