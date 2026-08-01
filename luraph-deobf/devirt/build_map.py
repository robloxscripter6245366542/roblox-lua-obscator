#!/usr/bin/env python3
# ============================================================
#  build_map.py  --  synthesise the COMPLETE opcode map
#
#  Merges two independent dynamic signals to classify every opcode the VM
#  executes:
#
#    * control-flow census (cf.json): per opcode, how often the next pc was
#      sequential vs a jump  ->  JMP / conditional-branch / flow-through
#    * register-delta trace (a semantics.py --out dump): what each opcode
#      writes to the register file  ->  NEWTABLE / GETTABLE / LOADK / MOVE /
#      arithmetic / comparison / SETTABLE(no-write) ...
#
#  Together these pin down all 125 opcodes of the sample build (with
#  calibrated confidence) and emit a full opcodes.json plus a printed table.
#
#  Inputs are produced by:
#    python3 semantics.py --vmdir peeled --luau ./luau --steps 14000 --out sem_big.txt
#    (control-flow census: see cf.json produced by the census harness / docs)
#
#  Usage:
#     python3 build_map.py --sem sem_big.txt --cf cf.json --out opcodes.full.json
# ============================================================

import argparse
import json
import re
from collections import defaultdict

LINE_RE = re.compile(r'\[\[S\]\] s=(\d+) pc=(\S+) op=(\S+)((?: [a-d]=\S+)*) E=(.*)')


def parse_sem(path):
    steps = []
    for l in open(path, errors="replace"):
        if not l.startswith("[[S]]"):
            continue
        m = LINE_RE.match(l.rstrip())
        if not m:
            continue
        _, pc, op, ops, E = m.groups()
        operands = dict(re.findall(r'([a-d])=(\S+)', ops))
        regs = {}
        for kv in (E.split(",") if E else []):
            if ":" in kv:
                i, v = kv.split(":", 1)
                if i.lstrip("-").isdigit():
                    regs[int(i)] = v
        steps.append((int(op), operands, regs))
    return steps


def role_of(operands, idx):
    for r in ("a", "b", "c", "d"):
        v = operands.get(r)
        if v and v.lstrip("-").isdigit() and int(v) == idx:
            return r
    return "?"


def analyse_writes(steps):
    """For each op, aggregate register-delta: dst role, value type, and whether
    the destination was previously empty (load) or held a value (compute)."""
    st = defaultdict(lambda: dict(n=0, nowrite=0, dst=defaultdict(int),
                                  vt=defaultdict(int), fresh=0, mutate=0, ex=""))
    for k in range(1, len(steps)):
        pop, pops, pregs = steps[k-1]
        _, _, cregs = steps[k]
        changed = {i: (pregs.get(i), v) for i, v in cregs.items()
                   if pregs.get(i) != v}
        s = st[pop]
        s["n"] += 1
        if not changed:
            s["nowrite"] += 1
            continue
        for idx, (old, new) in changed.items():
            s["dst"][role_of(pops, idx)] += 1
            if new:
                s["vt"][new.split(":")[0].split("#")[0]] += 1
            if old in (None, "nil", "b:false"):
                s["fresh"] += 1
            else:
                s["mutate"] += 1
        if not s["ex"]:
            chs = ", ".join(f"e[{i}]:{o}->{nw}" for i, (o, nw) in list(changed.items())[:2])
            s["ex"] = f"{dict(pops)} => {chs}"
    return st


def mnemonic(op, cf, w):
    """Combine control-flow + write signals into a mnemonic + confidence."""
    seq, jmp = (cf.get("seq", 0), cf.get("jmp", 0)) if cf else (0, 0)
    total_j = seq + jmp
    # --- control transfer opcodes ---
    if total_j and jmp == total_j and jmp > 0 and seq == 0:
        return "JMP/RETURN", "always transfers control", "high"
    if total_j and jmp > 0 and seq > 0:
        pct = jmp * 100 // total_j
        return "TEST/BRANCH", f"conditional jump (taken {pct}%)", "high"
    # --- data opcodes (flow-through) ---
    if not w or w["n"] == 0:
        # not sampled in the register-delta window, but the control-flow
        # census tells us how it behaves.
        if total_j and jmp == 0 and seq > 0:
            return "DATAOP", "flow-through data op (no register-delta sample)", "low"
        if total_j and jmp > 0:
            return "JMP/RETURN", "control transfer (unsampled)", "low"
        return "op?", "unobserved", "none"
    nowrite_ratio = w["nowrite"] / w["n"]
    if nowrite_ratio >= 0.8:
        return "SETTABLE/CALL", "no register write (table store or void call)", "med"
    vt = max(w["vt"], key=w["vt"].get) if w["vt"] else None
    fresh, mutate = w["fresh"], w["mutate"]
    if vt == "t":
        if fresh >= mutate:
            return "NEWTABLE", "e[dst] = {}", "high"
        return "GETTABLE", "e[dst] = e[obj][key] (table)", "med"
    if vt == "f":
        return "GETTABLE/CLOSURE", "e[dst] = function (field/closure)", "med"
    if vt == "s":
        return "LOADK_S", "e[dst] = string constant", "high"
    if vt == "b":
        return "COMPARE", "e[dst] = boolean", "high"
    if vt == "n":
        if mutate > fresh:
            return "ARITH", "e[dst] = <numeric op on regs>", "med"
        return "LOADK_N", "e[dst] = number constant", "high"
    return "op?", "mixed", "low"


def main():
    ap = argparse.ArgumentParser(description="synthesise the complete opcode map")
    ap.add_argument("--sem", default="sem_big.txt")
    ap.add_argument("--cf", default="cf.json")
    ap.add_argument("--curated", default="opcodes.json",
                    help="hand-verified map whose 'confirmed' entries override")
    ap.add_argument("--out", default="opcodes.full.json")
    args = ap.parse_args()

    steps = parse_sem(args.sem)
    writes = analyse_writes(steps)
    cf = {}
    if args.cf:
        raw = open(args.cf, errors="replace").read().strip()
        if raw.startswith("{"):
            cf = {int(k): v for k, v in json.loads(raw).items()}
        else:  # [[CF]] op=N seq=.. jmp=.. lines from run_vm.py --mode cf
            for m in re.finditer(r"\[\[CF\]\] op=(\d+) seq=(\d+) jmp=(\d+)", raw):
                op, sq, jp = map(int, m.groups()); cf[op] = {"seq": sq, "jmp": jp}

    curated = {}
    try:
        cm = json.load(open(args.curated))
        curated = {**cm.get("inferred", {}), **cm.get("confirmed", {})}
    except (FileNotFoundError, ValueError):
        pass

    all_ops = sorted(set(cf) | set(writes))
    table = {}
    print(f"{'op':>4} {'mnemonic':<16} {'conf':<5} effect")
    counts = defaultdict(int)
    for op in all_ops:
        cur = curated.get(str(op))
        if cur:  # hand-verified entry wins
            name = cur["name"]; eff = cur.get("effect", ""); conf = "curated"
        else:
            name, eff, conf = mnemonic(op, cf.get(op), writes.get(op))
        counts[name.split("/")[0]] += 1
        d = cf.get(op, {})
        w = writes.get(op, {})
        ex = w.get("ex", "")
        dst = max(w["dst"], key=w["dst"].get) if w.get("dst") else None
        wt = max(w["vt"], key=w["vt"].get) if w.get("vt") else None
        table[str(op)] = {"name": name, "effect": eff, "confidence": conf,
                          "dst": dst, "wtype": wt,
                          "cf": {"seq": d.get("seq", 0), "jmp": d.get("jmp", 0)},
                          "example": ex}
        print(f"{op:>4} {name:<16} {conf:<5} {eff}")
    json.dump(table, open(args.out, "w"), indent=1)
    print(f"\n[build_map] {len(all_ops)} opcodes -> {args.out}")
    print("[build_map] class counts:",
          ", ".join(f"{k}={v}" for k, v in sorted(counts.items(), key=lambda x: -x[1])))
    return 0


if __name__ == "__main__":
    import sys
    sys.exit(main())
