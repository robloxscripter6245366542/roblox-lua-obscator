#!/usr/bin/env node
// ============================================================================
//  moonsec_obfuscate.js
//  CLI that sends a Lua source file through the MoonSec REST API (free tier)
//  and writes back the obfuscated script.
//
//  Usage:
//    MOONSEC_API_KEY=xxxx node scripts/moonsec_obfuscate.js [options]
//    node scripts/moonsec_obfuscate.js --key xxxx -i src.lua -o out.lua
//
//  Options:
//    -i, --input     <path>    source file to obfuscate (default: Full_Combined_source.lua)
//    -o, --output     <path>   where to write the obfuscated result
//                              (default: <input> with ".moonsec.lua" suffix)
//    -k, --key        <key>    MoonSec API key (falls back to MOONSEC_API_KEY env var)
//        --options    <list>   "+"-joined feature toggles, e.g. StringEncryption+ConstantEncryption+AntiDump
//        --bytecode   <0-6>    bytecode style (default: 2)
//        --platform   <name>   lua | roblox | csgo (default: lua)
//        --retries    <n>      retries on 429 rate-limit (default: 3)
//
//  API reference:
//    https://cmoonm4n.gitbook.io/moonsec-obfuscator/moonsec-rest-api-docs
// ============================================================================

const fs = require('fs')
const path = require('path')

const DEFAULT_API_URL = 'https://api.f3d.at/v1/obfuscate.php'

function parseArgs(argv) {
  const args = {
    input: 'Full_Combined_source.lua',
    output: null,
    key: process.env.MOONSEC_API_KEY || '',
    url: process.env.MOONSEC_API_URL || DEFAULT_API_URL,
    options: 'StringEncryption+ConstantEncryption+AntiDump',
    bytecode: '2',
    platform: 'lua',
    retries: 3,
  }
  for (let i = 0; i < argv.length; i++) {
    const a = argv[i]
    const next = () => argv[++i]
    switch (a) {
      case '-i': case '--input': args.input = next(); break
      case '-o': case '--output': args.output = next(); break
      case '-k': case '--key': args.key = next(); break
      case '--url': args.url = next(); break
      case '--options': args.options = next(); break
      case '--bytecode': args.bytecode = next(); break
      case '--platform': args.platform = next(); break
      case '--retries': args.retries = parseInt(next(), 10); break
      case '-h': case '--help': args.help = true; break
      default:
        console.error(`Unknown argument: ${a}`)
        process.exit(1)
    }
  }
  if (!args.output) {
    const ext = path.extname(args.input) || '.lua'
    args.output = args.input.slice(0, -ext.length) + '.moonsec' + ext
  }
  return args
}

function printHelp() {
  console.log(`MoonSec obfuscator CLI

Usage: node scripts/moonsec_obfuscate.js [options]

  -i, --input     <path>   source file to obfuscate (default: Full_Combined_source.lua)
  -o, --output    <path>   output path (default: <input>.moonsec.lua)
  -k, --key       <key>    MoonSec API key (or set MOONSEC_API_KEY env var)
      --url       <url>    API endpoint override (or set MOONSEC_API_URL env var;
                            default: ${DEFAULT_API_URL})
      --options   <list>   + joined toggles, e.g. StringEncryption+ConstantEncryption+AntiDump+SmallOutput
      --bytecode  <0-6>    bytecode style (default: 2)
      --platform  <name>   lua | roblox | csgo (default: lua)
      --retries   <n>      retries on HTTP 429 (default: 3)
  -h, --help               show this help
`)
}

function sleep(ms) {
  return new Promise((resolve) => setTimeout(resolve, ms))
}

const STATUS_MESSAGES = {
  400: 'Invalid bytecode parameter.',
  403: 'Missing or invalid MoonSec API key.',
  413: 'Script size invalid (must be between 1 byte and 8MB).',
  429: 'Rate limited — MoonSec allows 1 obfuscation per 5 seconds.',
}

async function obfuscateOnce(source, args) {
  const url = new URL(args.url)
  url.searchParams.set('key', args.key)
  if (args.options) url.searchParams.set('options', args.options)
  if (args.bytecode !== undefined) url.searchParams.set('bytecode', String(args.bytecode))
  if (args.platform) url.searchParams.set('platform', args.platform)

  const res = await fetch(url, {
    method: 'POST',
    headers: { 'Content-Type': 'text/plain' },
    body: source,
  })

  const text = await res.text()
  return {
    status: res.status,
    body: text,
    contentType: res.headers.get('content-type') || '',
    finalUrl: res.url,
  }
}

function looksLikeHtml(text) {
  return /^\s*<(!doctype|html)/i.test(text)
}

async function main() {
  const args = parseArgs(process.argv.slice(2))
  if (args.help) { printHelp(); return }

  if (!args.key) {
    console.error('Error: no API key given. Pass --key <key> or set MOONSEC_API_KEY.')
    process.exit(1)
  }
  if (!fs.existsSync(args.input)) {
    console.error(`Error: input file not found: ${args.input}`)
    process.exit(1)
  }

  const source = fs.readFileSync(args.input, 'utf8')
  const size = Buffer.byteLength(source, 'utf8')
  if (size < 1 || size > 8 * 1024 * 1024) {
    console.error(`Error: script size ${size} bytes is out of MoonSec's allowed range (1B - 8MB).`)
    process.exit(1)
  }

  let attempt = 0
  let result
  for (;;) {
    attempt++
    result = await obfuscateOnce(source, args)
    if (result.status === 429 && attempt <= args.retries) {
      console.warn(`Rate limited, retrying in 5s (attempt ${attempt}/${args.retries})...`)
      await sleep(5000)
      continue
    }
    break
  }

  if (result.status !== 200) {
    const reason = STATUS_MESSAGES[result.status] || 'Obfuscation failed.'
    console.error(`MoonSec API error ${result.status}: ${reason}`)
    if (result.body) console.error(result.body)
    process.exit(1)
  }

  if (result.contentType.includes('text/html') || looksLikeHtml(result.body)) {
    console.error(`MoonSec API returned HTML instead of an obfuscated script — the endpoint`)
    console.error(`(${args.url}) likely redirected somewhere unexpected (final URL: ${result.finalUrl}).`)
    console.error('Refusing to write this response. Verify the endpoint is still live before retrying.')
    process.exit(1)
  }

  fs.writeFileSync(args.output, result.body)
  console.log(`Done -> ${args.output}`)
  console.log(`  Input bytes : ${size}`)
  console.log(`  Output bytes: ${Buffer.byteLength(result.body, 'utf8')}`)
  console.log(`  Options     : ${args.options}`)
  console.log(`  Bytecode    : ${args.bytecode}`)
  console.log(`  Platform    : ${args.platform}`)
}

main().catch((err) => {
  console.error('Unexpected error:', err.message)
  process.exit(1)
})
