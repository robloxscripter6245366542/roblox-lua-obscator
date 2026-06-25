#!/usr/bin/env python3
"""
Nano AI — Powered by Claude
Run: python -m ai_tutor
"""

import sys
import os
try:
    import readline
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
  ║         POWERED BY CLAUDE — KNOWS EVERYTHING                      ║
  ╚════════════════════════════════════════════════════════════════════╝
"""

PROMPT = "\n  Nano AI › "

MODE_FULL  = "  ✦ FULL AI MODE  — Claude API active. Ask me literally anything.\n"
MODE_LOCAL = "  ✦ OFFLINE MODE  — No API key. Built-in knowledge only.\n"


def _setup_claude() -> bool:
    """Try to connect to Claude API. Returns True if successful."""
    from . import claude_client

    # 1. Check environment variable
    if claude_client.setup():
        return True

    # 2. Check saved key
    saved = claude_client.load_saved_key()
    if saved and claude_client.setup(saved):
        return True

    return False


def _prompt_for_key() -> bool:
    """Ask the user for their Anthropic API key."""
    from . import claude_client

    print(
        "\n  To unlock FULL AI mode (Claude-powered), enter your Anthropic API key.\n"
        "  Get a free key at: console.anthropic.com\n"
        "\n  Press ENTER to skip and use offline mode instead."
    )
    try:
        key = input("\n  API Key › ").strip()
    except (EOFError, KeyboardInterrupt):
        return False

    if not key:
        return False

    print("  Connecting to Claude API...")
    if claude_client.setup(key):
        claude_client.save_key(key)
        print("  Connected! Key saved to ~/.nano_ai/config")
        return True
    else:
        print(
            "  Could not connect. Check your key or install the library:\n"
            "    pip install anthropic"
        )
        return False


def _setkey_command() -> bool:
    """Handle 'setkey' command during a session."""
    from . import claude_client
    print(
        "\n  Enter your Anthropic API key (console.anthropic.com):\n"
        "  Press ENTER to cancel."
    )
    try:
        key = input("  API Key › ").strip()
    except (EOFError, KeyboardInterrupt):
        return False
    if not key:
        return False
    print("  Connecting...")
    if claude_client.setup(key):
        claude_client.save_key(key)
        print("  Connected! Nano AI is now in FULL AI mode.")
        return True
    print("  Failed. Check the key and make sure 'anthropic' is installed.")
    return False


def run():
    from .tutor import Tutor
    from . import claude_client

    print(BANNER)

    # ── Claude API setup ──────────────────────────────────────────
    has_claude = _setup_claude()
    if not has_claude:
        has_claude = _prompt_for_key()

    if has_claude:
        print(MODE_FULL)
    else:
        print(MODE_LOCAL)
        print(
            "  Tip: Type 'setkey' at any time to connect Claude API.\n"
        )

    tutor = Tutor()
    name  = tutor.memory.get("user_name")
    if name:
        print(f"  Welcome back, {name}! Your total XP: {tutor.memory.get('total_xp', 0)}\n")
    else:
        print(
            "  Ask me anything: code, math, science, history, bugs, explanations...\n"
            "  Type 'help' for the full command list.\n"
        )

    while True:
        try:
            user_input = input(PROMPT).strip()
        except (EOFError, KeyboardInterrupt):
            print("\n\n  Nano AI signing off. Keep building!\n")
            sys.exit(0)

        if not user_input:
            continue

        # ── Special meta commands ─────────────────────────────────
        if user_input.lower() == "setkey":
            _setkey_command()
            continue

        if user_input.lower() == "clearhistory":
            claude_client.clear_history()
            print("  Conversation history cleared.")
            continue

        if user_input.lower().startswith("setkey "):
            key = user_input[7:].strip()
            if claude_client.setup(key):
                claude_client.save_key(key)
                print("  Connected! Nano AI is now in FULL AI mode.")
            else:
                print("  Failed. Check the key and install: pip install anthropic")
            continue

        response, should_exit = tutor.respond(user_input)
        print(response)

        if should_exit:
            print()
            sys.exit(0)


if __name__ == "__main__":
    run()
