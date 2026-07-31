#!/usr/bin/env node
// Fetches a URL and prints its visible text content.
// Does NOT follow gated redirects, solve timers/captchas, or click through
// ad-shorteners/paywalls — it only reads whatever HTML is served at the URL
// you give it, so a gated page will just print that gate page's text.

const ENTITIES = {
  amp: '&', lt: '<', gt: '>', quot: '"', '#39': "'", nbsp: ' ',
}

function decodeEntities(str) {
  return str.replace(/&(#39|amp|lt|gt|quot|nbsp);/g, (_, name) => ENTITIES[name])
    .replace(/&#(\d+);/g, (_, code) => String.fromCharCode(Number(code)))
}

function htmlToText(html) {
  const withoutNonVisible = html
    .replace(/<script[\s\S]*?<\/script>/gi, ' ')
    .replace(/<style[\s\S]*?<\/style>/gi, ' ')
    .replace(/<!--[\s\S]*?-->/g, ' ')
  const withBreaks = withoutNonVisible.replace(/<(br|\/p|\/div|\/li|\/h[1-6])\s*\/?>/gi, '\n')
  const stripped = withBreaks.replace(/<[^>]+>/g, ' ')
  return decodeEntities(stripped)
    .replace(/[ \t]+/g, ' ')
    .replace(/\n\s*\n\s*/g, '\n\n')
    .split('\n')
    .map((line) => line.trim())
    .filter(Boolean)
    .join('\n')
}

async function urlToText(url) {
  const res = await fetch(url, {
    headers: { 'User-Agent': 'Mozilla/5.0 (compatible; url-to-text/1.0)' },
  })
  const contentType = res.headers.get('content-type') || ''
  const body = await res.text()

  if (!res.ok) {
    throw new Error(`Request failed: ${res.status} ${res.statusText}`)
  }
  if (!contentType.includes('html') && !contentType.includes('text')) {
    return body
  }
  return htmlToText(body)
}

async function main() {
  const url = process.argv[2]
  if (!url) {
    console.error('Usage: node scripts/url-to-text.js <url>')
    process.exit(1)
  }
  try {
    console.log(await urlToText(url))
  } catch (err) {
    console.error(`Error: ${err.message}`)
    process.exit(1)
  }
}

if (require.main === module) {
  main()
}

module.exports = { urlToText, htmlToText }
