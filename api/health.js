module.exports = (_req, res) => {
  res.setHeader('Access-Control-Allow-Origin', '*');
  res.json({ status: 'ok', version: '1.0.0', provider: 'z.ai', model: 'glm-4.7' });
};
