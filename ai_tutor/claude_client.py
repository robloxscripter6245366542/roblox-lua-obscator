"""
Claude API integration — gives Nano AI the full intelligence of Claude.
Handles conversation history, streaming, and graceful fallback.
"""

import os
import sys

_client  = None
_model   = "claude-sonnet-4-6"
_history = []   # conversation memory for this session

SYSTEM_PROMPT = """\
You are Nano AI — the smartest coding tutor and programming assistant ever built.
You know every programming language, framework, algorithm, data structure, design
pattern, and software engineering concept in existence.

Your personality:
- Brilliant but friendly and approachable
- Give clear, direct answers with real code examples
- Use the right language for the question (Python by default unless specified)
- Format code in plain text blocks (no markdown — this is a terminal)
- Keep answers focused and actionable
- When asked to generate code, produce complete, production-quality scripts
- You can help with Roblox/Lua, game dev, web dev, AI/ML, systems programming — anything

Special capabilities you have:
- WebFetch: you can tell the user to type "search <query>" or "fetch <url>"
- File I/O: you can tell the user to type "read <file>" or "list files"
- Code generation: "generate a 3D scene", "generate a landing page", etc.
- Exercises: "exercise" for coding challenges, "quiz me on <topic>" for quizzes

You are running inside Nano AI, a Python CLI tutor. Keep responses concise and
terminal-friendly (no markdown headers like ##, no bold with **, use plain text).
Indent code blocks with 4 spaces. Use ASCII art sparingly."""


def setup(api_key: str | None = None) -> bool:
    """
    Initialize the Claude client.
    Returns True if successful, False if anthropic isn't installed or no key.
    """
    global _client
    key = api_key or os.environ.get("ANTHROPIC_API_KEY", "").strip()
    if not key:
        return False
    try:
        import anthropic
        _client = anthropic.Anthropic(api_key=key)
        # Quick test
        _client.messages.create(
            model=_model,
            max_tokens=10,
            messages=[{"role": "user", "content": "hi"}],
        )
        return True
    except ImportError:
        return False
    except Exception:
        _client = None
        return False


def is_ready() -> bool:
    return _client is not None


def ask(user_message: str, max_tokens: int = 1500) -> str:
    """Send a message and return Claude's response."""
    if not _client:
        return ""

    _history.append({"role": "user", "content": user_message})

    try:
        response = _client.messages.create(
            model=_model,
            max_tokens=max_tokens,
            system=SYSTEM_PROMPT,
            messages=_history,
        )
        reply = response.content[0].text
        _history.append({"role": "assistant", "content": reply})
        # Keep last 40 turns to avoid context bloat
        if len(_history) > 40:
            del _history[:2]
        return reply
    except Exception as e:
        _history.pop()   # remove the user message we just added
        return f"[Claude API error: {e}]"


def clear_history():
    """Reset conversation context."""
    _history.clear()


def save_key(api_key: str) -> bool:
    """Persist the API key to ~/.nano_ai/config and current env."""
    from pathlib import Path
    try:
        cfg = Path.home() / ".nano_ai" / "config"
        cfg.parent.mkdir(parents=True, exist_ok=True)
        cfg.write_text(f"ANTHROPIC_API_KEY={api_key}\n")
        os.environ["ANTHROPIC_API_KEY"] = api_key
        return True
    except Exception:
        return False


def load_saved_key() -> str | None:
    """Load a previously saved API key."""
    from pathlib import Path
    cfg = Path.home() / ".nano_ai" / "config"
    if cfg.exists():
        for line in cfg.read_text().splitlines():
            if line.startswith("ANTHROPIC_API_KEY="):
                return line.split("=", 1)[1].strip()
    return None
