const fs = require('fs');
const path = require('path');

const REPO_ROOT = path.join(__dirname, '..');

module.exports = (req, res) => {
  res.setHeader('Access-Control-Allow-Origin', '*');
  const { name } = req.query;
  if (!name || /[/\\]|\.\./.test(name) || !name.endsWith('.lua')) {
    return res.status(400).json({ error: 'Invalid filename' });
  }
  try {
    const filePath = path.join(REPO_ROOT, name);
    const content = fs.readFileSync(filePath, 'utf-8');
    res.json({ name, content: content.slice(0, 60000), truncated: content.length > 60000 });
  } catch {
    res.status(404).json({ error: 'File not found' });
  }
};
