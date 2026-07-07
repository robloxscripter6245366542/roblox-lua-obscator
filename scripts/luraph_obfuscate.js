#!/usr/bin/env node
// ============================================================================
//  Luraph obfuscation for the Anime Ball script (real custom-bytecode VM).
//
//  Sends user_scripts/anime_ball_autoparry.lua to the Luraph API, waits for the
//  job, and writes the obfuscated result to user_scripts/anime_ball_protected.lua.
//
//  Requires a Luraph subscription WITH API access. Run it locally so your key
//  never leaves your machine:
//
//     LURAPH_API_KEY=your_key   node scripts/luraph_obfuscate.js
//
//  Optional env:
//     LURAPH_NODE     node id to use (default: first from /nodes)
//     LURAPH_OPTIONS  JSON of node options, e.g. '{"INTENSE_VM":true}'
//     LURAPH_IN       input path  (default user_scripts/anime_ball_autoparry.lua)
//     LURAPH_OUT      output path (default user_scripts/anime_ball_protected.lua)
//
//  Node 18+ (has global fetch). This repo's Vercel runtime has it; so does any
//  recent local Node.
// ============================================================================

const fs = require('fs')

const API = 'https://api.lura.ph/v1'
const KEY = process.env.LURAPH_API_KEY
const IN = process.env.LURAPH_IN || 'user_scripts/anime_ball_autoparry.lua'
const OUT = process.env.LURAPH_OUT || 'user_scripts/anime_ball_protected.lua'

if (!KEY) {
  console.error('ERROR: set LURAPH_API_KEY (Luraph subscription with API access).')
  process.exit(1)
}

const headers = { 'Luraph-API-Key': KEY, 'Content-Type': 'application/json' }
const sleep = (ms) => new Promise((r) => setTimeout(r, ms))

async function main() {
  const source = fs.readFileSync(IN, 'utf8')
  console.log(`Source: ${IN} (${source.length} bytes)`)

  // 1) pick a node
  let node = process.env.LURAPH_NODE
  const nodesResp = await fetch(`${API}/obfuscate/nodes`, { headers })
  const nodesText = await nodesResp.text()
  if (!nodesResp.ok) throw new Error(`/nodes ${nodesResp.status}: ${nodesText}`)
  let nodesJson = {}
  try { nodesJson = JSON.parse(nodesText) } catch {}
  const nodeMap = nodesJson.nodes || nodesJson
  if (!node) {
    node = (nodesJson.recommendedId) || Object.keys(nodeMap || {})[0]
  }
  if (!node) throw new Error(`could not determine a node. /nodes returned: ${nodesText}`)
  console.log(`Node: ${node}`)

  // 2) submit
  let options = {}
  if (process.env.LURAPH_OPTIONS) {
    try { options = JSON.parse(process.env.LURAPH_OPTIONS) } catch (e) {
      throw new Error(`LURAPH_OPTIONS is not valid JSON: ${e.message}`)
    }
  }
  const newResp = await fetch(`${API}/obfuscate/new`, {
    method: 'POST',
    headers,
    body: JSON.stringify({
      node,
      script: Buffer.from(source, 'utf8').toString('base64'),
      fileName: 'anime_ball.lua',
      options,
    }),
  })
  const newText = await newResp.text()
  if (!newResp.ok) throw new Error(`/new ${newResp.status}: ${newText}`)
  const jobId = (JSON.parse(newText).jobId) || JSON.parse(newText).id
  if (!jobId) throw new Error(`no jobId in response: ${newText}`)
  console.log(`Job: ${jobId} — waiting...`)

  // 3) poll status
  const deadline = Date.now() + 5 * 60 * 1000
  while (Date.now() < deadline) {
    await sleep(3000)
    const st = await fetch(`${API}/obfuscate/status/${jobId}`, { headers })
    const stText = await st.text()
    let stJson = {}
    try { stJson = JSON.parse(stText) } catch {}
    if (stJson.success === true) { console.log('Done.'); break }
    if (stJson.error) throw new Error(`obfuscation failed: ${stJson.error}`)
    process.stdout.write('.')
  }

  // 4) download
  const dl = await fetch(`${API}/obfuscate/download/${jobId}`, { headers })
  const ct = dl.headers.get('content-type') || ''
  let out
  if (ct.includes('application/json')) {
    const j = JSON.parse(await dl.text())
    out = Buffer.from(j.data || j.script || '', 'base64').toString('utf8')
  } else {
    out = await dl.text()
  }
  if (!out || out.length < 32) throw new Error('downloaded result looks empty')
  fs.writeFileSync(OUT, out)
  console.log(`Wrote ${OUT} (${out.length} bytes).`)
}

main().catch((e) => { console.error('FAILED:', e.message); process.exit(1) })
