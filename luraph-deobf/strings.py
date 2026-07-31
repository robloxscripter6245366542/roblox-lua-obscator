#!/usr/bin/env python3
# ============================================================
#  strings.py  --  pull readable strings / IOCs from peeled stages
#
#  Even when the VM bytecode itself stays encrypted, plaintext often
#  survives in the packed streams: URLs, key-system endpoints, discord
#  invites, service identifiers, error messages. This gives you a fast
#  "what does it talk to / what is it" triage of a Luraph sample.
#
#  Usage:
#     python3 strings.py peeled/stage_0.bin [more.bin ...]
#     python3 peel.py x.lua && python3 strings.py peeled/*.bin
# ============================================================

import re
import sys

MIN_LEN = 5

# printable ASCII runs
ASCII_RUN = re.compile(rb"[\x20-\x7e]{%d,}" % MIN_LEN)

IOC_PATTERNS = {
    "url":      re.compile(r"https?://[^\s\"'<>\\]+"),
    "discord":  re.compile(r"discord(?:\.gg|app\.com)/[A-Za-z0-9]+"),
    "domain":   re.compile(r"\b[a-z0-9.-]+\.(?:com|net|io|gg|xyz|ph|lua)\b", re.I),
    "rbxasset": re.compile(r"rbxassetid://\d+"),
    "keyword":  re.compile(r"\b(key|token|whitelist|hwid|premium|license|verify|"
                           r"loadstring|HttpGet|getgenv|identifier|provider)\b", re.I),
}


def extract(path):
    with open(path, "rb") as f:
        data = f.read()
    runs = [m.group().decode("ascii", "replace") for m in ASCII_RUN.finditer(data)]
    text = "\n".join(runs)

    print(f"\n=== {path}  ({len(data)} bytes, {len(runs)} ascii runs) ===")

    iocs = {name: sorted(set(rx.findall(text))) for name, rx in IOC_PATTERNS.items()}
    any_ioc = False
    for name, hits in iocs.items():
        if hits:
            any_ioc = True
            print(f"  [{name}]")
            for h in hits[:40]:
                print(f"      {h}")
    if not any_ioc:
        print("  (no IOCs matched -- stage likely still encrypted; use sandbox.lua)")

    # a few longest runs give a feel for what survived
    longest = sorted(runs, key=len, reverse=True)[:10]
    if longest:
        print("  [longest readable runs]")
        for s in longest:
            print(f"      {s[:100]!r}")


def main():
    if len(sys.argv) < 2:
        print("usage: python3 strings.py <stage.bin> [...]")
        return 1
    for p in sys.argv[1:]:
        try:
            extract(p)
        except OSError as e:
            print(f"!! {p}: {e}")
    return 0


if __name__ == "__main__":
    sys.exit(main())
