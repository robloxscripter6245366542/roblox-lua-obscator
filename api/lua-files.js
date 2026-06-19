const fs = require('fs');
const path = require('path');

const REPO_ROOT = path.join(__dirname, '..');

module.exports = (_req, res) => {
  res.setHeader('Access-Control-Allow-Origin', '*');
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
};
