"""WebFetch – Nano AI's real internet access module."""

import urllib.request
import urllib.parse
import urllib.error
import html
import re
import json


HEADERS = {
    "User-Agent": (
        "Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 "
        "(KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36"
    )
}

TIMEOUT = 10


def _clean_html(raw: str) -> str:
    """Strip HTML tags and decode entities."""
    raw = re.sub(r"<script[\s\S]*?</script>", " ", raw, flags=re.IGNORECASE)
    raw = re.sub(r"<style[\s\S]*?</style>",   " ", raw, flags=re.IGNORECASE)
    raw = re.sub(r"<[^>]+>", " ", raw)
    raw = html.unescape(raw)
    raw = re.sub(r"\s{3,}", "\n\n", raw)
    return raw.strip()


def fetch_url(url: str, max_chars: int = 3000) -> dict:
    """
    Fetch a URL and return a dict with:
      ok      – bool
      url     – final url after redirects
      content – cleaned text content (truncated)
      error   – error message if ok=False
    """
    try:
        req = urllib.request.Request(url, headers=HEADERS)
        with urllib.request.urlopen(req, timeout=TIMEOUT) as resp:
            charset  = resp.headers.get_content_charset("utf-8")
            raw      = resp.read().decode(charset, errors="replace")
            clean    = _clean_html(raw)
            return {"ok": True, "url": resp.url, "content": clean[:max_chars]}
    except urllib.error.HTTPError as e:
        return {"ok": False, "url": url, "error": f"HTTP {e.code}: {e.reason}", "content": ""}
    except urllib.error.URLError as e:
        return {"ok": False, "url": url, "error": str(e.reason), "content": ""}
    except Exception as e:
        return {"ok": False, "url": url, "error": str(e), "content": ""}


def web_search_ddg(query: str, max_results: int = 5) -> list[dict]:
    """
    Lightweight DuckDuckGo Instant Answer API query.
    Returns list of {title, url, snippet}.
    """
    encoded = urllib.parse.urlencode({"q": query, "format": "json", "no_html": "1"})
    api_url = f"https://api.duckduckgo.com/?{encoded}"
    try:
        req = urllib.request.Request(api_url, headers=HEADERS)
        with urllib.request.urlopen(req, timeout=TIMEOUT) as resp:
            data = json.loads(resp.read().decode("utf-8"))
        results = []
        # Abstract answer
        if data.get("AbstractText"):
            results.append({
                "title":   data.get("Heading", query),
                "url":     data.get("AbstractURL", ""),
                "snippet": data["AbstractText"][:400],
            })
        # Related topics
        for topic in data.get("RelatedTopics", [])[:max_results]:
            if isinstance(topic, dict) and topic.get("Text"):
                results.append({
                    "title":   topic.get("Text", "")[:80],
                    "url":     topic.get("FirstURL", ""),
                    "snippet": topic.get("Text", "")[:300],
                })
        return results[:max_results]
    except Exception as e:
        return [{"title": "Search failed", "url": "", "snippet": str(e)}]


def fetch_docs(topic: str) -> str:
    """Fetch relevant programming documentation."""
    doc_urls = {
        "python":     "https://docs.python.org/3/",
        "javascript": "https://developer.mozilla.org/en-US/docs/Web/JavaScript/Guide",
        "rust":       "https://doc.rust-lang.org/book/",
        "go":         "https://go.dev/doc/",
        "lua":        "https://www.lua.org/manual/5.4/",
    }
    url = doc_urls.get(topic.lower())
    if not url:
        return f"No direct docs URL for {topic}. Try: fetch {topic} documentation"
    result = fetch_url(url, max_chars=2000)
    if result["ok"]:
        return f"From {result['url']}:\n\n{result['content']}"
    return f"Could not fetch docs: {result['error']}"
