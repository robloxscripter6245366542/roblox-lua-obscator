#!/usr/bin/env node
/**
 * Nova Roblox MCP server
 * ---------------------------------------------------------------------------
 * Attaches an AI agent (Claude Desktop / Cursor / any MCP client) to Roblox
 * Studio. The MCP client talks to this process over stdio; this process also
 * runs a tiny local HTTP "bridge" that the Studio plugin long-polls.
 *
 *      MCP client  <--stdio-->  THIS SERVER  <--HTTP long-poll-->  Studio plugin
 *
 * Roblox Studio plugins cannot receive inbound HTTP, so the bridge is a queue:
 * a tool call enqueues a command, the plugin's GET /poll picks it up, runs it
 * inside Studio, and POSTs the result back to /result, which resolves the tool.
 *
 * Security: the HTTP bridge binds to 127.0.0.1 only and is guarded by a shared
 * token (NOVA_MCP_TOKEN). It lets the agent run arbitrary Luau *inside your
 * Studio edit session*, so only run it locally and only point Studio at a
 * server you started yourself.
 */

import http from "node:http";
import crypto from "node:crypto";
import fs from "node:fs";
import path from "node:path";
import { fileURLToPath } from "node:url";
import { McpServer } from "@modelcontextprotocol/sdk/server/mcp.js";
import { StdioServerTransport } from "@modelcontextprotocol/sdk/server/stdio.js";
import { z } from "zod";

const __dirname = path.dirname(fileURLToPath(import.meta.url));
const NOVA_DIR = path.resolve(__dirname, "..", "..", "nova-ui");

// Catalog axes (mirror nova-ui/Themes.lua, Shop.lua, Presets.lua) — 24×6×4 = 576.
const THEME_NAMES = [
  "Midnight", "Obsidian", "Graphite", "Nord", "Dracula", "Carbon", "Cyberpunk",
  "Matrix", "DeepSea", "Wine", "Forest", "Ember", "RoseGold", "Neon", "Royal",
  "Slate", "Daylight", "Paper", "Mint", "Sky", "Sakura", "Sand", "Lavender", "Frost",
];
const LAYOUTS = ["Grid", "List", "Carousel", "Featured", "Compact", "Showcase"];
const CARD_STYLES = ["Flat", "Elevated", "Outline", "Glass"];

// Serialize a JS value to a Luau literal.
function luaValue(v) {
  if (v === null || v === undefined) return "nil";
  if (typeof v === "number" || typeof v === "boolean") return String(v);
  if (typeof v === "string") {
    return '"' + v.replace(/\\/g, "\\\\").replace(/"/g, '\\"').replace(/\n/g, "\\n").replace(/\r/g, "").replace(/\t/g, "\\t") + '"';
  }
  if (Array.isArray(v)) return "{ " + v.map(luaValue).join(", ") + " }";
  if (typeof v === "object") {
    // {r,g,b} → Color3.fromRGB
    const keys = Object.keys(v);
    if (keys.length === 3 && "r" in v && "g" in v && "b" in v) {
      return `Color3.fromRGB(${v.r}, ${v.g}, ${v.b})`;
    }
    const parts = keys.map((k) => {
      const key = /^[A-Za-z_]\w*$/.test(k) ? k : `[${luaValue(k)}]`;
      return `${key} = ${luaValue(v[k])}`;
    });
    return "{ " + parts.join(", ") + " }";
  }
  return "nil";
}

const PORT = Number(process.env.NOVA_MCP_PORT || 3005);
const HOST = "127.0.0.1";
const TOKEN = process.env.NOVA_MCP_TOKEN || "nova-dev-token";
const CMD_TIMEOUT_MS = Number(process.env.NOVA_MCP_TIMEOUT || 30000);
const POLL_HOLD_MS = 25000; // how long a /poll request is held open

// ── bridge state ───────────────────────────────────────────────────────────
const queue = [];        // commands waiting to be delivered to the plugin
const pending = new Map(); // id -> { resolve, reject, timer }
let waiter = null;        // a single held-open /poll response, if any
let pluginSeen = 0;       // last time the plugin polled (ms epoch)

function deliverToWaiter() {
  if (waiter && queue.length) {
    const cmd = queue.shift();
    const res = waiter.res;
    clearTimeout(waiter.timer);
    waiter = null;
    sendJson(res, 200, cmd);
  }
}

/** Enqueue a command for the plugin and await its result. */
function callStudio(tool, args) {
  const id = crypto.randomUUID();
  const cmd = { id, tool, args: args ?? {} };
  return new Promise((resolve, reject) => {
    const timer = setTimeout(() => {
      pending.delete(id);
      reject(new Error(
        `Timed out after ${CMD_TIMEOUT_MS}ms waiting for Studio. ` +
        (pluginSeen ? "Is the place still open?" : "Is the NovaMCP plugin installed and running in Studio?")
      ));
    }, CMD_TIMEOUT_MS);
    pending.set(id, { resolve, reject, timer });
    queue.push(cmd);
    deliverToWaiter();
  });
}

// ── HTTP bridge ─────────────────────────────────────────────────────────────
function sendJson(res, code, obj) {
  const body = JSON.stringify(obj ?? {});
  res.writeHead(code, { "content-type": "application/json" });
  res.end(body);
}

function readBody(req) {
  return new Promise((resolve, reject) => {
    let data = "";
    req.on("data", (c) => {
      data += c;
      if (data.length > 8 * 1024 * 1024) reject(new Error("body too large"));
    });
    req.on("end", () => resolve(data));
    req.on("error", reject);
  });
}

const httpServer = http.createServer(async (req, res) => {
  if (req.headers["x-nova-token"] !== TOKEN) {
    return sendJson(res, 401, { error: "bad token" });
  }
  pluginSeen = Date.now();

  if (req.method === "GET" && req.url.startsWith("/poll")) {
    if (queue.length) {
      return sendJson(res, 200, queue.shift());
    }
    // hold the request open until a command arrives or we time out
    if (waiter) { // only one poller expected; release the stale one
      clearTimeout(waiter.timer);
      sendJson(waiter.res, 204, {});
    }
    const timer = setTimeout(() => {
      if (waiter && waiter.res === res) waiter = null;
      sendJson(res, 204, {});
    }, POLL_HOLD_MS);
    waiter = { res, timer };
    return;
  }

  if (req.method === "POST" && req.url.startsWith("/result")) {
    try {
      const body = JSON.parse(await readBody(req));
      const p = pending.get(body.id);
      if (p) {
        pending.delete(body.id);
        clearTimeout(p.timer);
        if (body.ok) p.resolve(body.result);
        else p.reject(new Error(body.error || "Studio reported an error"));
      }
      return sendJson(res, 200, { ok: true });
    } catch (e) {
      return sendJson(res, 400, { error: String(e) });
    }
  }

  if (req.method === "GET" && req.url.startsWith("/ping")) {
    return sendJson(res, 200, { ok: true, queued: queue.length });
  }

  return sendJson(res, 404, { error: "not found" });
});

httpServer.listen(PORT, HOST, () => {
  process.stderr.write(`[nova-mcp] bridge on http://${HOST}:${PORT} (token: ${TOKEN})\n`);
});

// ── MCP tools ────────────────────────────────────────────────────────────────
const server = new McpServer({ name: "nova-roblox-mcp", version: "1.0.0" });

const ok = (data) => ({
  content: [{ type: "text", text: typeof data === "string" ? data : JSON.stringify(data, null, 2) }],
});
const fail = (msg) => ({ isError: true, content: [{ type: "text", text: String(msg) }] });

async function tool(toolName, args) {
  try { return ok(await callStudio(toolName, args)); }
  catch (e) { return fail(e.message || e); }
}

// -- see --
server.tool(
  "studio_status",
  "Check whether Studio and the NovaMCP plugin are connected.",
  {},
  async () => {
    const alive = pluginSeen && Date.now() - pluginSeen < 5000;
    return ok({ bridge: "up", pluginConnected: !!alive, lastSeenMsAgo: pluginSeen ? Date.now() - pluginSeen : null });
  }
);

server.tool(
  "get_tree",
  "Get the instance tree under a path (default 'game'). Returns Name/ClassName and children up to `depth`.",
  { path: z.string().default("game"), depth: z.number().int().min(1).max(8).default(3) },
  async ({ path, depth }) => tool("get_tree", { path, depth })
);

server.tool(
  "get_properties",
  "Read common properties of the instance at `path`.",
  { path: z.string() },
  async ({ path }) => tool("get_properties", { path })
);

// -- edit --
server.tool(
  "create_instance",
  "Create an Instance. `properties` values may be tagged types, e.g. {\"Size\":{\"__t\":\"Vector3\",\"x\":1,\"y\":1,\"z\":1}}.",
  {
    className: z.string(),
    parent: z.string().default("game.Workspace"),
    name: z.string().optional(),
    properties: z.record(z.any()).optional(),
  },
  async (a) => tool("create_instance", a)
);

server.tool(
  "set_property",
  "Set one property on an instance. `value` may be a tagged type (see create_instance).",
  { path: z.string(), property: z.string(), value: z.any() },
  async (a) => tool("set_property", a)
);

server.tool(
  "delete_instance",
  "Destroy the instance at `path`.",
  { path: z.string() },
  async (a) => tool("delete_instance", a)
);

server.tool(
  "select",
  "Select instances in Studio (Selection service) so the user sees them.",
  { paths: z.array(z.string()) },
  async (a) => tool("select", a)
);

// -- code --
server.tool(
  "insert_script",
  "Create a Script / LocalScript / ModuleScript with the given Luau source.",
  {
    parent: z.string().default("game.ServerScriptService"),
    name: z.string().default("Script"),
    scriptType: z.enum(["Script", "LocalScript", "ModuleScript"]).default("Script"),
    source: z.string(),
  },
  async (a) => tool("insert_script", a)
);

server.tool(
  "get_source",
  "Read the .Source of the script at `path`.",
  { path: z.string() },
  async (a) => tool("get_source", a)
);

server.tool(
  "run_luau",
  "Execute a Luau snippet inside Studio (run in edit mode via a temporary ModuleScript). Return a value from your code to see it. Use for inspection and edits the structured tools don't cover.",
  { source: z.string() },
  async (a) => tool("run_luau", a)
);

// -- animate --
server.tool(
  "create_animation",
  "Build a KeyframeSequence from poses and parent it (right-click it in Studio to Save to Roblox for an animation asset id). `keyframes` = [{ time, poses: { BoneName: {__t:'CFrame',...} } }].",
  {
    name: z.string().default("NovaAnimation"),
    parent: z.string().default("game.Workspace"),
    keyframes: z.array(z.object({ time: z.number(), poses: z.record(z.any()) })),
  },
  async (a) => tool("create_animation", a)
);

// ── NovaUI: let Claude install the library and build shops / windows ─────────
const MODULES = ["Themes", "NovaUI", "Shop", "Presets", "Animations"];

server.tool(
  "install_novaui",
  "Install the NovaUI library (Themes, NovaUI, Shop, Presets, Animations) as ModuleScripts under a parent (default ReplicatedStorage). Run this once before create_shop / create_window.",
  { parent: z.string().default("game.ReplicatedStorage") },
  async ({ parent }) => {
    try {
      const folder = await callStudio("create_instance", { className: "Folder", parent, name: "NovaUI" });
      const installed = [];
      for (const m of MODULES) {
        const file = path.join(NOVA_DIR, `${m}.lua`);
        if (!fs.existsSync(file)) continue;
        const source = fs.readFileSync(file, "utf8");
        const r = await callStudio("insert_script", { parent: folder.path, name: m, scriptType: "ModuleScript", source });
        installed.push(r.path);
      }
      return ok({ folder: folder.path, installed, note: "Reference it from scripts as require(this folder).Shop / .NovaUI" });
    } catch (e) { return fail(e.message || e); }
  }
);

server.tool(
  "list_shop_variations",
  "List the shop variation catalog: 24 themes × 6 layouts × 4 card styles = 576 combinations.",
  {},
  async () => ok({
    count: THEME_NAMES.length * LAYOUTS.length * CARD_STYLES.length,
    themes: THEME_NAMES, layouts: LAYOUTS, cardStyles: CARD_STYLES,
  })
);

const ITEM = z.object({
  Name: z.string(), Price: z.number().optional(), Image: z.string().optional(),
  Category: z.string().optional(), Badge: z.string().optional(), Currency: z.string().optional(),
  ProductId: z.number().optional(), PurchaseType: z.enum(["Product", "Gamepass"]).optional(),
  Owned: z.boolean().optional(),
});

async function buildShopScript({ title, theme, layout, cardStyle, columns, items, parent, novaPath }) {
  const base = novaPath || 'game:GetService("ReplicatedStorage").NovaUI';
  const cfg = luaValue({
    Title: title || "Shop", Theme: theme || "Midnight",
    Layout: layout || "Grid", CardStyle: cardStyle || "Elevated", Columns: columns || 3,
  });
  const src =
`local Shop = require(${base}.Shop)
local shop = Shop.new(${cfg})
shop:AddItems(${luaValue(items || [])})
shop:Render()
`;
  return callStudio("insert_script", {
    parent: parent || "game.StarterPlayer.StarterPlayerScripts",
    name: (title || "Shop").replace(/[^A-Za-z0-9]/g, "") + "Shop",
    scriptType: "LocalScript",
    source: src,
  });
}

server.tool(
  "create_shop",
  "Generate a shop UI in Studio. Inserts a LocalScript that builds a NovaUI Shop; press Play to see it. Requires install_novaui first. `items` follow the Shop item shape (Name, Price, Image, Category, Badge, ProductId, PurchaseType).",
  {
    title: z.string().default("Item Shop"),
    theme: z.enum(THEME_NAMES).default("Midnight"),
    layout: z.enum(LAYOUTS).default("Grid"),
    cardStyle: z.enum(CARD_STYLES).default("Elevated"),
    columns: z.number().int().min(1).max(6).default(3),
    items: z.array(ITEM).default([]),
    parent: z.string().optional(),
    novaPath: z.string().optional(),
  },
  async (a) => {
    try { return ok(await buildShopScript(a)); }
    catch (e) { return fail(e.message || e); }
  }
);

server.tool(
  "random_shop",
  "Build a shop with a random theme/layout/card-style from the 576-variation catalog and a sample item set — a quick way to spin up one of the hundreds of looks.",
  { parent: z.string().optional(), novaPath: z.string().optional() },
  async ({ parent, novaPath }) => {
    const pick = (arr) => arr[Math.floor(Math.random() * arr.length)];
    const theme = pick(THEME_NAMES), layout = pick(LAYOUTS), cardStyle = pick(CARD_STYLES);
    const items = [
      { Name: "Golden Sword", Price: 99, Category: "Weapons", Badge: "SALE" },
      { Name: "Frost Bow", Price: 149, Category: "Weapons" },
      { Name: "Jetpack", Price: 399, Category: "Gear", Badge: "HOT" },
      { Name: "VIP", Price: 499, Category: "Passes", PurchaseType: "Gamepass", ProductId: 0 },
      { Name: "Coin Pack", Price: 250, Category: "Currency", Currency: "🪙" },
    ];
    try {
      const r = await buildShopScript({ title: `${theme} ${layout} Shop`, theme, layout, cardStyle, items, parent, novaPath });
      return ok({ ...r, variation: `${theme} · ${layout} · ${cardStyle}` });
    } catch (e) { return fail(e.message || e); }
  }
);

// Build a full NovaUI window from a spec: { title, accent, theme, tabs:[{name, groups?,
// components:[{type, ...props}]}] }. `type` maps to a NovaUI Create<Type> call.
function componentLua(c) {
  const t = c.type;
  const rest = { ...c };
  delete rest.type;
  if (t === "Section") return `tab:CreateSection(${luaValue(c.text || c.Name || "Section")})`;
  if (t === "Label") return `tab:CreateLabel(${luaValue(c.text || "")})`;
  if (t === "Paragraph") return `tab:CreateParagraph(${luaValue(c.title || "")}, ${luaValue(c.body || "")})`;
  if (t === "Divider") return `tab:CreateDivider()`;
  // generic: Create<Type>({ props })
  return `tab:Create${t}(${luaValue(rest)})`;
}

server.tool(
  "create_window",
  "Generate a full NovaUI window in Studio from a spec. Inserts a LocalScript; press Play to see it. Requires install_novaui first. Spec: title, accent {r,g,b}, theme, tabs:[{name, components:[{type:'Toggle'|'Slider'|'Dropdown'|'ColorPicker'|'Section'|..., ...props}]}].",
  {
    title: z.string().default("My Game"),
    subTitle: z.string().optional(),
    theme: z.enum(THEME_NAMES).optional(),
    accent: z.object({ r: z.number(), g: z.number(), b: z.number() }).optional(),
    tabs: z.array(z.object({
      name: z.string(),
      components: z.array(z.record(z.any())).default([]),
    })).default([]),
    parent: z.string().optional(),
    novaPath: z.string().optional(),
  },
  async (a) => {
    try {
      const base = a.novaPath || 'game:GetService("ReplicatedStorage").NovaUI';
      const winCfg = { Title: a.title, SubTitle: a.subTitle };
      if (a.theme) winCfg.Theme = a.theme;
      if (a.accent) winCfg.Accent = a.accent;
      const lines = [
        `local NovaUI = require(${base}.NovaUI)`,
        `local Window = NovaUI:CreateWindow(${luaValue(winCfg)})`,
        `local tab`,
      ];
      for (const tabSpec of a.tabs) {
        lines.push(`tab = Window:CreateTab(${luaValue(tabSpec.name)})`);
        for (const comp of tabSpec.components || []) {
          lines.push(componentLua(comp));
        }
      }
      const r = await callStudio("insert_script", {
        parent: a.parent || "game.StarterPlayer.StarterPlayerScripts",
        name: a.title.replace(/[^A-Za-z0-9]/g, "") + "UI",
        scriptType: "LocalScript",
        source: lines.join("\n") + "\n",
      });
      return ok(r);
    } catch (e) { return fail(e.message || e); }
  }
);

// ── go ───────────────────────────────────────────────────────────────────────
const transport = new StdioServerTransport();
await server.connect(transport);
process.stderr.write("[nova-mcp] MCP server ready on stdio\n");
