#!/usr/bin/env python3
# ============================================================
#  annotate.py  --  render a disasm trace using the opcode map
#
#  Takes the output of `run_vm.py --mode disasm` and `opcodes.json` and
#  produces an annotated, human-readable instruction listing: known
#  opcodes are labelled with their mnemonic + decoded effect, unknown
#  ones are left raw with their operand shape so they can be resolved.
#
#  This is the front of the lifter: once opcodes.json is filled in from
#  func `o`, the annotated listing is a near-disassembly, and emitting Lua
#  per instruction (lift.py) becomes mechanical.
#
#  Usage:
#     python3 run_vm.py --mode disasm --n 400 --out dis.txt
#     python3 annotate.py dis.txt --map opcodes.json
# ============================================================

import argparse
import json
import re
import sys


def load_map(path):
    with open(path) as f:
        m = json.load(f)
    return m.get("confirmed", {}), m.get("shape_hints", {})


DIS_RE = re.compile(
    r'\[\[DIS\]\] pc=(\S+) op=(\S+) a=(\S+) b=(\S+) c=(\S+)(?: d=(\S+))?')


def fmt_operands(conf_entry, a, b, c, d):
    """Render operands using the confirmed map's operand roles, if any."""
    roles = conf_entry.get("operands", {}) if conf_entry else {}
    vals = {"a": a, "b": b, "c": c, "d": d}
    parts = []
    for k in ("a", "b", "c", "d"):
        v = vals[k]
        if v in (None, "nil"):
            continue
        role = roles.get(k)
        parts.append(f"{role}={v}" if role else f"{k}={v}")
    return " ".join(parts)


def main():
    ap = argparse.ArgumentParser(description="annotate a Luraph disasm trace")
    ap.add_argument("trace", help="output of run_vm.py --mode disasm")
    ap.add_argument("--map", default="opcodes.json")
    args = ap.parse_args()

    confirmed, hints = load_map(args.map)
    known = unknown = 0
    for line in open(args.trace, errors="replace"):
        m = DIS_RE.match(line.strip())
        if not m:
            continue
        pc, op, a, b, c, d = m.groups()
        entry = confirmed.get(op)
        operand_str = fmt_operands(entry, a, b, c, d)
        if entry:
            known += 1
            name = entry["name"]
            eff = entry.get("effect", "")
            print(f"{pc:>6}:  {name:<12} {operand_str:<34} ; {eff}")
        else:
            unknown += 1
            hint = hints.get(op, "")
            note = f" ; ? {hint}" if hint else " ; ?"
            print(f"{pc:>6}:  op{op:<10} {operand_str:<34}{note}")

    total = known + unknown
    if total:
        sys.stderr.write(
            f"\n[annotate] {known}/{total} instructions labelled "
            f"({known*100//total}%); {len(confirmed)} opcodes in map, "
            f"~125 distinct in this build.\n")
    return 0


if __name__ == "__main__":
    sys.exit(main())
