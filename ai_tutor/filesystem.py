"""File system operations for Nano AI – read, write, list, analyze code files."""

import os
import re
from pathlib import Path


_SAFE_EXTENSIONS = {
    ".py", ".js", ".ts", ".lua", ".java", ".cpp", ".c", ".h",
    ".rs", ".go", ".html", ".css", ".sql", ".json", ".md",
    ".txt", ".yaml", ".yml", ".toml", ".sh", ".rb", ".php",
}
_MAX_READ_BYTES = 100_000


def _safe_path(raw: str) -> Path:
    p = Path(raw).expanduser().resolve()
    return p


def read_file(path_str: str) -> str:
    p = _safe_path(path_str)
    if not p.exists():
        return f"\n  ❌ File not found: {p}"
    if p.stat().st_size > _MAX_READ_BYTES:
        return f"\n  ❌ File too large (>{_MAX_READ_BYTES//1000}KB). Use a smaller file."
    try:
        content = p.read_text(encoding="utf-8", errors="replace")
        lines   = content.split("\n")
        preview = "\n".join(f"  {i+1:4d} │ {l}" for i, l in enumerate(lines[:100]))
        suffix  = f"\n  ... ({len(lines)-100} more lines)" if len(lines) > 100 else ""
        return (
            f"\n  📄 FILE: {p}\n"
            f"  {'─'*60}\n"
            f"  Size: {p.stat().st_size:,} bytes  |  Lines: {len(lines)}\n"
            f"  {'─'*60}\n\n"
            + preview + suffix
        )
    except Exception as e:
        return f"\n  ❌ Error reading file: {e}"


def write_file(path_str: str, content: str) -> str:
    p = _safe_path(path_str)
    try:
        p.parent.mkdir(parents=True, exist_ok=True)
        p.write_text(content, encoding="utf-8")
        lines = content.count("\n") + 1
        return (
            f"\n  ✅ Written: {p}\n"
            f"     {lines} lines  |  {len(content):,} bytes"
        )
    except Exception as e:
        return f"\n  ❌ Error writing file: {e}"


def list_dir(path_str: str = ".") -> str:
    p = _safe_path(path_str)
    if not p.is_dir():
        return f"\n  ❌ Not a directory: {p}"
    try:
        entries = sorted(p.iterdir(), key=lambda e: (e.is_file(), e.name.lower()))
        if not entries:
            return f"\n  📁 {p} (empty)"
        out = [f"\n  📁 {p}\n  {'─'*50}"]
        for e in entries[:60]:
            icon = "📄" if e.is_file() else "📁"
            size = f"  {e.stat().st_size:>8,} B" if e.is_file() else "            "
            out.append(f"  {icon} {e.name:<40}{size}")
        if len(entries) > 60:
            out.append(f"  ... {len(entries)-60} more entries")
        return "\n".join(out)
    except Exception as e:
        return f"\n  ❌ Error listing directory: {e}"


def analyze_file(path_str: str) -> str:
    p = _safe_path(path_str)
    if not p.exists():
        return f"\n  ❌ File not found: {p}"
    try:
        content = p.read_text(encoding="utf-8", errors="replace")
    except Exception as e:
        return f"\n  ❌ Cannot read: {e}"

    lines        = content.split("\n")
    code_lines   = [l for l in lines if l.strip() and not l.strip().startswith("#")]
    comment_lines= [l for l in lines if l.strip().startswith("#")]
    blank_lines  = [l for l in lines if not l.strip()]

    # detect language from extension
    ext_lang = {
        ".py": "Python", ".js": "JavaScript", ".ts": "TypeScript",
        ".lua": "Lua", ".java": "Java", ".cpp": "C++", ".rs": "Rust",
        ".go": "Go", ".html": "HTML", ".css": "CSS", ".sql": "SQL",
    }
    lang = ext_lang.get(p.suffix.lower(), "Unknown")

    # count functions / classes
    fns  = len(re.findall(r"^\s*(def |function |local function |func |fn )", content, re.M))
    cls  = len(re.findall(r"^\s*(class )",  content, re.M))
    imps = len(re.findall(r"^\s*(import |require\(|using |#include)", content, re.M))

    return (
        f"\n  🔍 CODE ANALYSIS — {p.name}\n"
        f"  {'─'*55}\n"
        f"  Language:     {lang}\n"
        f"  Total lines:  {len(lines)}\n"
        f"  Code lines:   {len(code_lines)}\n"
        f"  Comments:     {len(comment_lines)}\n"
        f"  Blank lines:  {len(blank_lines)}\n"
        f"  Functions:    {fns}\n"
        f"  Classes:      {cls}\n"
        f"  Imports:      {imps}\n"
        f"  File size:    {p.stat().st_size:,} bytes\n"
        f"  {'─'*55}\n"
        f"  Type 'read {path_str}' to view the full content.\n"
    )
