const GH_API = 'https://api.github.com'

// Ruby's GitHub bridge: commits one or more files to a repo on a new branch and
// opens a pull request, using the Git Data API so multiple files land in a
// single commit. The token comes ONLY from the environment, never the request.
function token() {
  return process.env.RUBY_GITHUB_TOKEN || process.env.GITHUB_TOKEN || process.env.GH_TOKEN || ''
}

async function gh(method, path, tok, body) {
  const r = await fetch(`${GH_API}${path}`, {
    method,
    headers: {
      Authorization: `Bearer ${tok}`,
      Accept: 'application/vnd.github+json',
      'X-GitHub-Api-Version': '2022-11-28',
      'User-Agent': 'ruby-ai',
      ...(body ? { 'Content-Type': 'application/json' } : {}),
    },
    ...(body ? { body: JSON.stringify(body) } : {}),
  })
  const text = await r.text()
  let data
  try { data = text ? JSON.parse(text) : {} } catch { data = { raw: text } }
  if (!r.ok) {
    const msg = data && data.message ? data.message : `GitHub API ${r.status}`
    const err = new Error(msg)
    err.status = r.status
    throw err
  }
  return data
}

module.exports = async function handler(req, res) {
  if (req.method !== 'POST') return res.status(405).json({ error: 'method not allowed' })

  const tok = token()
  if (!tok) {
    return res.status(501).json({ error: 'GitHub is not connected. Add a RUBY_GITHUB_TOKEN to enable commits & PRs.' })
  }

  const body = req.body || {}
  const repo = typeof body.repo === 'string' ? body.repo.trim().replace(/^https?:\/\/github\.com\//, '').replace(/\.git$/, '') : ''
  if (!/^[^/\s]+\/[^/\s]+$/.test(repo)) {
    return res.status(400).json({ error: 'repo must be in "owner/name" form' })
  }

  const files = Array.isArray(body.files)
    ? body.files.filter((f) => f && typeof f.path === 'string' && f.path.trim() && typeof f.content === 'string')
    : []
  if (files.length === 0) {
    return res.status(400).json({ error: 'at least one file { path, content } is required' })
  }

  const message = typeof body.message === 'string' && body.message.trim() ? body.message.trim() : 'Ruby: update files'
  const prTitle = typeof body.prTitle === 'string' && body.prTitle.trim() ? body.prTitle.trim() : message
  const prBody = typeof body.prBody === 'string' ? body.prBody : 'Opened by Ruby 💎'

  try {
    const [owner, name] = repo.split('/')
    const repoInfo = await gh('GET', `/repos/${owner}/${name}`, tok)
    const base = (typeof body.base === 'string' && body.base.trim()) || repoInfo.default_branch || 'main'

    // Resolve the base branch head commit + its tree.
    const baseRef = await gh('GET', `/repos/${owner}/${name}/git/ref/heads/${encodeURIComponent(base)}`, tok)
    const baseSha = baseRef.object.sha
    const baseCommit = await gh('GET', `/repos/${owner}/${name}/git/commits/${baseSha}`, tok)
    const baseTree = baseCommit.tree.sha

    // Create a new branch.
    const branch = (typeof body.branch === 'string' && body.branch.trim()) || `ruby/${Date.now()}`
    await gh('POST', `/repos/${owner}/${name}/git/refs`, tok, {
      ref: `refs/heads/${branch}`,
      sha: baseSha,
    })

    // Build a tree containing every file as a blob.
    const tree = []
    for (const f of files) {
      const blob = await gh('POST', `/repos/${owner}/${name}/git/blobs`, tok, {
        content: f.content,
        encoding: 'utf-8',
      })
      tree.push({ path: f.path.replace(/^\/+/, ''), mode: '100644', type: 'blob', sha: blob.sha })
    }
    const newTree = await gh('POST', `/repos/${owner}/${name}/git/trees`, tok, {
      base_tree: baseTree,
      tree,
    })
    const commit = await gh('POST', `/repos/${owner}/${name}/git/commits`, tok, {
      message,
      tree: newTree.sha,
      parents: [baseSha],
    })
    await gh('PATCH', `/repos/${owner}/${name}/git/refs/heads/${encodeURIComponent(branch)}`, tok, {
      sha: commit.sha,
    })

    // Open the pull request.
    const pr = await gh('POST', `/repos/${owner}/${name}/pulls`, tok, {
      title: prTitle,
      head: branch,
      base,
      body: prBody,
    })

    return res.json({
      ok: true,
      branch,
      base,
      commit: commit.sha,
      prNumber: pr.number,
      prUrl: pr.html_url,
      files: files.map((f) => f.path),
    })
  } catch (e) {
    const status = e.status && e.status >= 400 && e.status < 600 ? e.status : 502
    return res.status(status).json({ error: `GitHub: ${e.message}` })
  }
}
