"""Persistent memory – Nano AI learns and remembers across sessions."""

import json
import os
from datetime import datetime
from pathlib import Path

MEMORY_DIR  = Path.home() / ".nano_ai"
MEMORY_FILE = MEMORY_DIR / "memory.json"
HISTORY_FILE = MEMORY_DIR / "history.jsonl"


def _ensure_dir():
    MEMORY_DIR.mkdir(parents=True, exist_ok=True)


def load_memory() -> dict:
    _ensure_dir()
    if MEMORY_FILE.exists():
        try:
            return json.loads(MEMORY_FILE.read_text())
        except Exception:
            pass
    return {
        "preferred_language": None,
        "topics_mastered":    [],
        "total_xp":           0,
        "sessions":           0,
        "known_facts":        {},
        "last_seen":          None,
        "user_name":          None,
        "feedback_corrections": [],
    }


def save_memory(mem: dict):
    _ensure_dir()
    mem["last_seen"] = datetime.now().isoformat()
    MEMORY_FILE.write_text(json.dumps(mem, indent=2))


def log_exchange(user_input: str, response: str):
    """Append a conversation turn to the history log."""
    _ensure_dir()
    entry = {
        "ts":    datetime.now().isoformat(),
        "user":  user_input[:500],
        "nano":  response[:500],
    }
    with open(HISTORY_FILE, "a", encoding="utf-8") as f:
        f.write(json.dumps(entry) + "\n")


def load_history(last_n: int = 20) -> list[dict]:
    if not HISTORY_FILE.exists():
        return []
    lines = HISTORY_FILE.read_text().strip().split("\n")
    result = []
    for line in lines[-last_n:]:
        try:
            result.append(json.loads(line))
        except Exception:
            pass
    return result


def learn_correction(wrong: str, correct: str, mem: dict) -> dict:
    """Record a user correction so Nano AI improves."""
    mem.setdefault("feedback_corrections", []).append({
        "ts":      datetime.now().isoformat(),
        "wrong":   wrong,
        "correct": correct,
    })
    # keep only last 100
    mem["feedback_corrections"] = mem["feedback_corrections"][-100:]
    return mem


def build_user_profile(mem: dict) -> str:
    lang = mem.get("preferred_language") or "not set"
    name = mem.get("user_name") or "friend"
    mastered = mem.get("topics_mastered") or []
    sessions = mem.get("sessions", 0)
    total_xp = mem.get("total_xp", 0)
    last     = mem.get("last_seen", "never")[:10] if mem.get("last_seen") else "never"
    return (
        f"\n  🧠 NANO AI — YOUR PROFILE\n"
        f"  {'─'*50}\n"
        f"  Name:              {name}\n"
        f"  Preferred language:{lang}\n"
        f"  Total XP:          {total_xp}\n"
        f"  Sessions:          {sessions}\n"
        f"  Topics mastered:   {len(mastered)}\n"
        f"  Last session:      {last}\n"
        f"  Topics: {', '.join(mastered[:10]) or 'none yet'}\n"
    )
