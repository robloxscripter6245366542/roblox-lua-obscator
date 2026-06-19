const express = require('express');
const path = require('path');
const fs = require('fs');

const app = express();
app.use(express.json({ limit: '10mb' }));
app.use(express.static(path.join(__dirname, 'public')));

const API_KEY = 'b31c21a518d248d9beed75edefff5e8b.uWEDrbhP9bIe4jri';
const ZAI_API_URL = 'https://api.z.ai/api/paas/v4/chat/completions';
const REPO_ROOT = path.join(__dirname, '..');

const SYSTEM_PROMPT = `You are an expert AI web developer and Roblox Lua assistant, powered by Z.ai GLM, for the Roblox Lua Obfuscator project. You help users build and modify websites, write Lua scripts, and use the obfuscation tools.

When asked to create or modify a website, return code in these blocks:
\`\`\`html
<!-- full HTML document here -->
\`\`\`
\`\`\`css
/* styles here */
\`\`\`
\`\`\`javascript
// client-side JS here
\`\`\`

When asked to write or modify Lua/backend code, use:
\`\`\`lua
-- lua code here
\`\`\`
\`\`\`javascript-backend
// code to add to server.js backend
\`\`\`

You have access to these backend API endpoints the user can call:
- GET /api/lua-files - lists all Lua files in the repository
- GET /api/lua-file?name=filename.lua - reads a Lua file (up to 50KB)
- POST /api/chat - AI chat (streaming)
- POST /api/obfuscate-text - obfuscates text/code with XOR + base64

Available Lua tools in the repo: Claude_Hub.lua, FE_Hub.lua, Claude_Hub_Lite.lua, Claude_Loader.lua, Full_Combined.lua, MurderMystery2_Hub.lua, obfuscate.lua, SS_Executor.lua, executor_gui.lua, SpellingBee_NerdZone.lua, WindHub.lua, SangraHub.lua, IndraHub_Lite.lua

When adding backend functionality, explain exactly what endpoint/code to add to server.js and how to call it from the frontend.

Always be helpful, creative, and produce complete working code. Explain what changes you're making.`;

// Chat endpoint - proxies to Z.ai GLM with streaming
app.post('/api/chat', async (req, res) => {
  const { messages, model = 'glm-4.7' } = req.body;

  try {
    const response = await fetch(ZAI_API_URL, {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
        'Authorization': `Bearer ${API_KEY}`
      },
      body: JSON.stringify({
        model,
        messages: [
          { role: 'system', content: SYSTEM_PROMPT },
          ...messages
        ],
        stream: true,
        temperature: 0.7,
        max_tokens: 8192
      })
    });

    if (!response.ok) {
      const errText = await response.text();
      return res.status(response.status).json({ error: errText });
    }

    res.setHeader('Content-Type', 'text/event-stream');
    res.setHeader('Cache-Control', 'no-cache');
    res.setHeader('Connection', 'keep-alive');

    const reader = response.body.getReader();
    const decoder = new TextDecoder();

    while (true) {
      const { done, value } = await reader.read();
      if (done) break;
      res.write(decoder.decode(value, { stream: true }));
    }
    res.end();
  } catch (err) {
    if (!res.headersSent) res.status(500).json({ error: err.message });
  }
});

// List all Lua files in the repo
app.get('/api/lua-files', (req, res) => {
  try {
    const files = fs.readdirSync(REPO_ROOT)
      .filter(f => f.endsWith('.lua'))
      .map(f => {
        const stat = fs.statSync(path.join(REPO_ROOT, f));
        return { name: f, size: stat.size, modified: stat.mtime };
      })
      .sort((a, b) => a.name.localeCompare(b.name));
    res.json({ files });
  } catch (e) {
    res.status(500).json({ error: e.message });
  }
});

// Read a specific Lua file (sanitized path)
app.get('/api/lua-file', (req, res) => {
  const { name } = req.query;
  if (!name || /[/\\]|\.\./.test(name) || !name.endsWith('.lua')) {
    return res.status(400).json({ error: 'Invalid filename' });
  }
  try {
    const filePath = path.join(REPO_ROOT, name);
    const content = fs.readFileSync(filePath, 'utf-8');
    res.json({ name, content: content.slice(0, 60000), truncated: content.length > 60000 });
  } catch (e) {
    res.status(404).json({ error: 'File not found' });
  }
});

// Simple XOR + base64 obfuscation (mirrors obfuscate.lua)
app.post('/api/obfuscate-text', (req, res) => {
  const { code, key = 42 } = req.body;
  if (typeof code !== 'string') return res.status(400).json({ error: 'code must be a string' });

  const bytes = Buffer.from(code, 'utf-8');
  const xored = Buffer.alloc(bytes.length);
  for (let i = 0; i < bytes.length; i++) xored[i] = bytes[i] ^ ((key + i) % 256);
  const encoded = xored.toString('base64');

  const loader = `-- Obfuscated with Roblox-Lua-Obscator
local _k,_d=${key},{}
local _b="` + encoded + `"
for c in _b:gmatch(".") do _d[#_d+1]=string.byte(c) end
-- base64 decode + XOR to recover original
`;
  res.json({ obfuscated: loader, originalSize: code.length });
});

// Health / version
app.get('/api/health', (_req, res) => {
  res.json({ status: 'ok', version: '1.0.0', provider: 'z.ai', model: 'glm-4.7' });
});

const PORT = process.env.PORT || 3000;
app.listen(PORT, () => {
  console.log(`\n🚀 AI Website Builder → http://localhost:${PORT}\n`);
});
