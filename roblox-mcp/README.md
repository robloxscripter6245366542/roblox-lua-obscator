# Nova Roblox MCP — attach an AI agent to Roblox Studio

An [MCP](https://modelcontextprotocol.io) server that connects an AI agent
(Claude Desktop, Cursor, or any MCP client) to **Roblox Studio**, so it can:

- **see** — read the DataModel / instance tree and properties
- **code** — write scripts, read `.Source`, and run Luau inside your edit session
- **build** — create / edit / delete instances, select them in Studio
- **animate** — assemble a `KeyframeSequence` you can save as an animation asset

It mirrors the architecture of the official
[`Roblox/studio-rust-mcp-server`](https://github.com/Roblox/studio-rust-mcp-server),
rewritten in Node so there's no Rust toolchain to install.

## How it works

```
 AI client  ⇄ stdio ⇄  MCP server (this)  ⇄ HTTP long-poll ⇄  Studio plugin
```

Roblox Studio plugins can't receive inbound HTTP, so the server keeps a
**command queue**. Each tool call enqueues a command; the plugin's `GET /poll`
(held open ~25 s) picks it up, runs it in Studio, and `POST`s the result back
to `/result`, which resolves the tool. The bridge binds to `127.0.0.1` only and
is guarded by a shared token.

## Setup

### 1. Server
```bash
cd roblox-mcp/server
npm install
# optional: pick a token/port
export NOVA_MCP_TOKEN="my-secret"   # must match the plugin
export NOVA_MCP_PORT=3005
node index.js                        # or let your MCP client launch it
```

### 2. Studio plugin
1. Studio ▸ **Game Settings ▸ Security ▸ Allow HTTP Requests** → on.
2. Put `plugin/NovaMCPPlugin.server.lua` in your **Local Plugins** folder
   (Plugins tab ▸ Plugins Folder), or right-click it in Explorer ▸
   *Save as Local Plugin*.
3. If you changed the token/port, edit the `TOKEN` / `BASE` constants at the
   top of the plugin to match.
4. Click the **NovaMCP ▸ Connect** toolbar button. The output window prints
   `connecting to http://127.0.0.1:3005`.

### 3. Point your AI client at it
**Claude Desktop** — add to `claude_desktop_config.json`:
```json
{
  "mcpServers": {
    "nova-roblox": {
      "command": "node",
      "args": ["/absolute/path/to/roblox-mcp/server/index.js"],
      "env": { "NOVA_MCP_TOKEN": "my-secret" }
    }
  }
}
```
**Cursor** — add the same block under `mcpServers` in your MCP settings.

Then ask the agent things like *"list what's in Workspace"*, *"make a red
neon part that spins"*, or *"write a LocalScript that opens a NovaUI shop"*.

## Tools

| Tool | What it does |
| --- | --- |
| `studio_status` | Is Studio + the plugin connected? |
| `get_tree` | Instance tree under a path (`path`, `depth`) |
| `get_properties` | Common properties of an instance |
| `create_instance` | `Instance.new` with parent, name, properties |
| `set_property` | Set one property |
| `delete_instance` | Destroy an instance |
| `select` | Select instances so the user sees them |
| `insert_script` | Create a Script / LocalScript / ModuleScript with source |
| `get_source` | Read a script's `.Source` |
| `run_luau` | Execute a Luau snippet in Studio; `return` a value to read it |
| `create_animation` | Build a `KeyframeSequence` from keyframe poses |

### Tagged value types
Properties and animation poses use small tagged objects so the agent can pass
Roblox datatypes over JSON:

```jsonc
{ "__t": "Vector3", "x": 1, "y": 2, "z": 3 }
{ "__t": "Color3",  "r": 255, "g": 0, "b": 0 }        // 0–255
{ "__t": "UDim2",   "xs": 0, "xo": 200, "ys": 0, "yo": 120 }
{ "__t": "CFrame",  "comps": [ /* 12 numbers */ ] }    // or px,py,pz + rx,ry,rz (deg)
{ "__t": "EnumItem","enum": "Material", "name": "Neon" }
{ "__t": "Instance","path": "game.Workspace.Part" }
```

## Security

`run_luau` runs whatever the agent sends **inside your Studio edit session**.
Treat it like giving the agent your keyboard:

- The bridge listens on `127.0.0.1` only and checks `x-nova-token` on every
  request — keep the token private and change it from the default.
- Only connect to a server **you** started, locally. Never expose the port.
- All mutating operations set a `ChangeHistoryService` waypoint, so **Ctrl-Z**
  undoes the agent's edits.
- This is a Studio authoring tool. It is **not** an in-game exploit/executor
  and won't run in published games — keep it that way.
