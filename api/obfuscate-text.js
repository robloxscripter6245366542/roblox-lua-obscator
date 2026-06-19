module.exports = (req, res) => {
  res.setHeader('Access-Control-Allow-Origin', '*');
  if (req.method === 'OPTIONS') { res.status(200).end(); return; }

  const { code, key = 42 } = req.body || {};
  if (typeof code !== 'string') return res.status(400).json({ error: 'code must be a string' });

  const bytes = Buffer.from(code, 'utf-8');
  const xored = Buffer.alloc(bytes.length);
  for (let i = 0; i < bytes.length; i++) xored[i] = bytes[i] ^ ((key + i) % 256);
  const encoded = xored.toString('base64');

  const loader = `-- Obfuscated with Roblox-Lua-Obscator\nlocal _k,_d=${key},{}\nlocal _b="${encoded}"\nfor c in _b:gmatch(".") do _d[#_d+1]=string.byte(c) end\n`;
  res.json({ obfuscated: loader, originalSize: code.length });
};
