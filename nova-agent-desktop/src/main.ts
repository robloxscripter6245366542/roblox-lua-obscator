import { app, BrowserWindow, ipcMain, dialog, safeStorage } from "electron";
import * as path from "node:path";
import * as fs from "node:fs";
import { Agent, type AgentEvents } from "./agent";
import type { ToolContext } from "./tools";

const MODELS = ["claude-opus-5", "claude-sonnet-5", "claude-haiku-4-5"];

interface Settings {
  apiKeyEnc?: string;   // base64 of safeStorage-encrypted key
  apiKeyPlain?: string; // fallback when encryption is unavailable
  model: string;
  baseURL: string;
  workDir: string;
  requireBashApproval: boolean;
  autoApprove: string[];
}

let win: BrowserWindow | null = null;
let agent: Agent | null = null;
let sessionAllowAll = false;

const settingsPath = () => path.join(app.getPath("userData"), "settings.json");

function loadSettings(): Settings {
  const defaults: Settings = {
    model: "claude-opus-5",
    baseURL: "",
    workDir: app.getPath("home"),
    requireBashApproval: true,
    autoApprove: [],
  };
  try {
    return { ...defaults, ...JSON.parse(fs.readFileSync(settingsPath(), "utf8")) };
  } catch {
    return defaults;
  }
}
function saveSettings(s: Settings) {
  try { fs.writeFileSync(settingsPath(), JSON.stringify(s, null, 2)); } catch {}
}

let settings = { ...loadSettings() } as Settings; // populated in whenReady (needs app paths)

function setApiKey(key: string) {
  if (safeStorage.isEncryptionAvailable()) {
    settings.apiKeyEnc = safeStorage.encryptString(key).toString("base64");
    delete settings.apiKeyPlain;
  } else {
    settings.apiKeyPlain = key;
  }
  saveSettings(settings);
}
async function getApiKey(): Promise<string | undefined> {
  if (settings.apiKeyEnc && safeStorage.isEncryptionAvailable()) {
    try { return safeStorage.decryptString(Buffer.from(settings.apiKeyEnc, "base64")); } catch { return undefined; }
  }
  return settings.apiKeyPlain || undefined;
}

// Mutable tool context so a folder change takes effect live.
const ctx: ToolContext = {
  root: "",
  bashTimeoutMs: 120000,
  onActivity: (line) => win?.webContents.send("nova:event", { type: "activity", line }),
  confirmBash: async (command) => {
    if (!settings.requireBashApproval || sessionAllowAll) return true;
    for (const p of settings.autoApprove) {
      let hit = false;
      try { hit = new RegExp(p).test(command); } catch { hit = command.startsWith(p); }
      if (hit) return true;
    }
    const { response } = await dialog.showMessageBox(win!, {
      type: "warning",
      title: "Run shell command?",
      message: "Nova Agent wants to run a shell command:",
      detail: command,
      buttons: ["Allow", "Allow all (session)", "Deny"],
      defaultId: 0,
      cancelId: 2,
    });
    if (response === 1) sessionAllowAll = true;
    return response === 0 || response === 1;
  },
};

const events: AgentEvents = {
  onText: (delta) => win?.webContents.send("nova:event", { type: "text", delta }),
  onActivity: (line) => win?.webContents.send("nova:event", { type: "activity", line }),
  onTurnEnd: () => win?.webContents.send("nova:event", { type: "turnEnd" }),
  onError: (message) => win?.webContents.send("nova:event", { type: "error", message }),
  onConnectionChange: (connected) => win?.webContents.send("nova:event", { type: "connection", connected }),
};

function makeAgent() {
  ctx.root = settings.workDir;
  agent = new Agent(getApiKey, ctx, events, {
    model: settings.model,
    idleMs: 5 * 60_000,
    baseURL: settings.baseURL || undefined,
  });
}

function createWindow() {
  win = new BrowserWindow({
    width: 460, height: 680, minWidth: 360, minHeight: 480,
    backgroundColor: "#141019",
    title: "Nova Agent",
    webPreferences: { preload: path.join(__dirname, "preload.js"), contextIsolation: true, nodeIntegration: false },
  });
  win.setMenuBarVisibility(false);
  win.loadFile(path.join(__dirname, "..", "renderer", "index.html"));
  win.on("closed", () => { win = null; });
}

app.whenReady().then(() => {
  settings = loadSettings();
  makeAgent();
  createWindow();
  app.on("activate", () => { if (BrowserWindow.getAllWindows().length === 0) createWindow(); });
});
app.on("window-all-closed", () => { agent?.dispose(); if (process.platform !== "darwin") app.quit(); });

// ── IPC ──────────────────────────────────────────────────────────────────
ipcMain.handle("settings:get", async () => ({
  models: MODELS,
  model: settings.model,
  baseURL: settings.baseURL,
  workDir: settings.workDir,
  requireBashApproval: settings.requireBashApproval,
  hasKey: !!(await getApiKey()),
}));
ipcMain.handle("settings:setKey", (_e, key: string) => { setApiKey(String(key || "").trim()); return true; });
ipcMain.handle("settings:setModel", (_e, m: string) => { settings.model = m; saveSettings(settings); agent?.setModel(m); return true; });
ipcMain.handle("settings:setBaseUrl", (_e, u: string) => { settings.baseURL = String(u || ""); saveSettings(settings); agent?.setBaseUrl(settings.baseURL || undefined); return true; });
ipcMain.handle("settings:setApproval", (_e, on: boolean) => { settings.requireBashApproval = !!on; saveSettings(settings); return true; });
ipcMain.handle("settings:pickFolder", async () => {
  const r = await dialog.showOpenDialog(win!, { properties: ["openDirectory"] });
  if (!r.canceled && r.filePaths[0]) {
    settings.workDir = r.filePaths[0];
    ctx.root = settings.workDir;
    saveSettings(settings);
  }
  return settings.workDir;
});
ipcMain.on("agent:send", (_e, text: string) => { agent?.send(String(text || "")); });
ipcMain.on("agent:reset", () => { sessionAllowAll = false; agent?.reset(); });
