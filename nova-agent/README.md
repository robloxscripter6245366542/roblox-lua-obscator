# Nova Agent — a fast local AI coding agent for VS Code

Paste your **Anthropic API key** and get a Claude-powered coding agent inside VS
Code that can run `bash`, read and write files, and iterate to completion. It
connects to Claude **only while you're using it** and disconnects when idle — so
there's no background connection sitting open.

- **Fast bash** — the `bash` tool spawns your real shell directly (no MCP hop),
  streamed straight back to Claude.
- **Bring your own key** — your key is stored in VS Code **secret storage**, and
  the extension talks to the Anthropic API directly. Nothing is proxied.
- **Disconnects when Claude isn't on** — the client is created lazily on your
  first message and torn down after `novaAgent.idleDisconnectMinutes` of
  inactivity, or immediately when you close the panel or clear the key.
- **Tiny** — bundled with esbuild into a single file; the packaged `.vsix` is a
  few MB, well under 30 MB.

## Tools the agent has

| Tool | What it does |
| --- | --- |
| `bash` | Run a shell command in the workspace root (build, test, git, install, search…) |
| `read_file` | Read a text file |
| `write_file` | Create/overwrite a text file (makes parent dirs) |
| `list_dir` | List a directory |

The agent loops over tool calls on its own until the task is done, streaming its
reasoning/output to the chat panel.

## Setup

```bash
cd nova-agent
npm install
npm run build          # bundles src → dist/extension.js
```

Then run it:
- Press **F5** in VS Code to launch an Extension Development Host, **or** package
  it: `npm run package` → install the resulting `nova-agent-1.0.0.vsix`
  (`code --install-extension nova-agent-1.0.0.vsix`).

In the host window:
1. Command Palette → **Nova Agent: Set Anthropic API Key** → paste your key.
2. Command Palette → **Nova Agent: Open Chat**.
3. Ask it something: *"run the tests and fix the first failure"*,
   *"create an Express server in server.js and start it"*.

## Settings

| Setting | Default | Meaning |
| --- | --- | --- |
| `novaAgent.model` | `claude-opus-5` | Claude model id |
| `novaAgent.idleDisconnectMinutes` | `5` | Disconnect after N minutes idle (`0` = never) |
| `novaAgent.bashTimeoutMs` | `120000` | Per-command bash timeout |

## Model & API

Uses the official `@anthropic-ai/sdk` with streaming and adaptive thinking, model
`claude-opus-5` by default. The agent loop is a standard tool-use loop: stream a
turn, execute any `tool_use` blocks, return all `tool_result`s in one message,
repeat until the model stops requesting tools.

## Security

- `bash` runs commands **on your machine** with your permissions, in the
  workspace root — the same trust level as your integrated terminal. Review what
  you ask for; don't point it at a repo you don't trust.
- Your API key never leaves secret storage except in the `Authorization` header
  of requests your machine makes directly to `api.anthropic.com`.
- Clearing the key (**Nova Agent: Clear API Key & Disconnect**) removes it and
  tears down the connection immediately.

## Notes

This talks to the Anthropic API directly with your key. It is not affiliated with
Anthropic and is a starting point you can extend (add tools, a sidebar view,
permission prompts before `bash`, etc.).
