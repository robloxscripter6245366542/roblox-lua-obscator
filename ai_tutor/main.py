#!/usr/bin/env python3
"""
Nano AI — The Smartest Coding AI in the World
Run: python -m ai_tutor
"""

import sys
try:
    import readline  # enables up/down arrow key history
except ImportError:
    pass

BANNER = r"""
  ╔════════════════════════════════════════════════════════════════════╗
  ║                                                                    ║
  ║  ███╗   ██╗ █████╗ ███╗   ██╗ ██████╗      █████╗ ██╗            ║
  ║  ████╗  ██║██╔══██╗████╗  ██║██╔═══██╗    ██╔══██╗██║            ║
  ║  ██╔██╗ ██║███████║██╔██╗ ██║██║   ██║    ███████║██║            ║
  ║  ██║╚██╗██║██╔══██║██║╚██╗██║██║   ██║    ██╔══██║██║            ║
  ║  ██║ ╚████║██║  ██║██║ ╚████║╚██████╔╝    ██║  ██║██║            ║
  ║  ╚═╝  ╚═══╝╚═╝  ╚═╝╚═╝  ╚═══╝ ╚═════╝     ╚═╝  ╚═╝╚═╝            ║
  ║                                                                    ║
  ║      THE SMARTEST CODING AI EVER BUILT — FULLY OFFLINE            ║
  ║                                                                    ║
  ║  ✦ Knows every language  ✦ Generates complete production code     ║
  ║  ✦ Teaches & quizzes     ✦ Fetches the web  ✦ Reads/writes files  ║
  ║  ✦ 3D / UI / Animations  ✦ Roblox scripts   ✦ Remembers you       ║
  ╚════════════════════════════════════════════════════════════════════╝
"""

HELP_HINT = """
  QUICK START — try any of these:
    teach me Python            → full language tutorial
    what is recursion?         → concept explanation
    generate a 3D rotating cube → Three.js 3D scene
    generate a landing page    → complete HTML/CSS/JS UI
    generate a Roblox NPC AI   → ready-to-run Lua script
    generate a React todo app  → React app (CDN, no build)
    generate a Flask API       → production Python server
    quiz me on loops           → test your knowledge
    exercise                   → coding challenge + XP
    search Python asyncio      → live web search
    fetch https://example.com  → browse any URL
    read myfile.py             → view a file
    list files                 → directory listing
    compare Python vs Rust     → language comparison
    career advice              → where to start
    topics                     → everything I can teach
    help                       → full command list
"""

PROMPT = "\n  Nano AI › "


def run():
    from .tutor import Tutor

    print(BANNER)
    print(HELP_HINT)

    tutor = Tutor()
    name  = tutor.memory.get("user_name")
    if name:
        print(f"  Welcome back, {name}! Your XP: {tutor.memory.get('total_xp',0)}\n")

    while True:
        try:
            user_input = input(PROMPT).strip()
        except (EOFError, KeyboardInterrupt):
            print("\n\n  Nano AI signing off. Keep building!\n")
            sys.exit(0)

        if not user_input:
            continue

        response, should_exit = tutor.respond(user_input)
        print(response)

        if should_exit:
            print()
            sys.exit(0)


if __name__ == "__main__":
    run()
