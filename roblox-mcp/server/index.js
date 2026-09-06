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
import { McpServer } from "@modelcontextprotocol/sdk/server/mcp.js";
import { StdioServerTransport } from "@modelcontextprotocol/sdk/server/stdio.js";
import { z } from "zod";

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

// ── go ───────────────────────────────────────────────────────────────────────
const transport = new StdioServerTransport();
await server.connect(transport);
process.stderr.write("[nova-mcp] MCP server ready on stdio\n");
