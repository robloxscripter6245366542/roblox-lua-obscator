#!/usr/bin/env python3
# ============================================================
#  v15_payload_dump_arrays.py  --  full array snapshot for v15's payload VM
#
#  v15_payload_opcodes.py gives per-opcode SEMANTICS as a template (e.g.
#  opcode 28 in some mode is `R[r[w]]=R[k[w]]<E[w]`) but with `w` symbolic --
#  it doesn't say what concrete registers/constants instruction #37 actually
#  uses. That requires the VM's *decoded* instruction data: the parallel
#  arrays (o/r/k/E/V/n and whatever else a mode's opcodes index) that the
#  outer 145-handler loader populates before the payload interpreter starts
#  consuming them.
#
#  This captures that data directly at the source level: inject a one-shot
#  probe right after the target dispatch loop's opcode fetch (same offset
#  math as v15_payload_probe.py) that dumps every candidate array's full
#  contents the first time that loop is entered -- no C-side instrumentation
#  needed, since source-level injection has ordinary LEXICAL access to
#  whatever upvalues are in scope there. Candidates come from the `arrays
#  touched` column of v15_payload_opcodes.py's semantics JSON; any name not
#  actually in scope there just reads as a global nil and is skipped.
#
#  Usage:
#    python3 devirt/v15_payload_dump_arrays.py sample_v15.lua \
#        --luau dynamic/luau --deobf dynamic/deobf_v15.py \
#        --mode 2 --semantics v15_payload_opcode_semantics.json \
#        --timeout 20 --json v15_payload_arrays.json
# ============================================================

import argparse
import json
import os
import re
import subprocess
import sys
import tempfile

from v15_payload_probe import find_vm_groups, pick_payload_vm

DUMP_TAG = "[[VMARR]]"


def build_dump_probe(candidates):
    # dynamic/deobf_v15.py's harness redacts any printed string over 120
    # chars to a bare "<str N>" placeholder (see its `log()` helper) -- so
    # each print here must stay well under that, hence chunking every ~15
    # values instead of concatenating a whole array into one print call.
    names = ",".join(f'"{c}"' for c in candidates)
    refs = ",".join(candidates)
    return (
        "if not __vmarrdump then __vmarrdump=true "
        f"local __names={{{names}}} local __vals={{{refs}}} "
        "for __i=1,#__names do local __t=__vals[__i] "
        "if type(__t)=='table' then "
        "local __max=0 for __k in pairs(__t) do if type(__k)=='number' and __k==math.floor(__k) and __k>__max then __max=__k end end "
        f"print('{DUMP_TAG} '..__names[__i]..' len='..__max) "
        "local __chunk={} local __cn=0 local __seq=0 "
        "for __j=1,__max do local __v=__t[__j] local __s "
        "if type(__v)=='number' then __s=tostring(__v) "
        "elseif type(__v)=='string' then __s='S'..#__v "
        "elseif __v==nil then __s='_' else __s='?' end "
        "__cn=__cn+1 __chunk[__cn]=__s "
        "if __cn>=8 or __j==__max then "
        f"print('{DUMP_TAG}D '..__names[__i]..' '..__seq..' '..table.concat(__chunk,',')) "
        "__chunk={} __cn=0 __seq=__seq+1 end end "
        "end end end;"
    )


def main():
    ap = argparse.ArgumentParser(description="v15 payload-VM full array dump")
    ap.add_argument("sample")
    ap.add_argument("--luau", default="dynamic/luau")
    ap.add_argument("--deobf", default="dynamic/deobf_v15.py")
    ap.add_argument("--mode", type=int, default=None,
                    help="which dispatch block (0-based, in source order) to dump at; "
                         "default: the richest (same pick as v15_payload_probe.py)")
    ap.add_argument("--candidates",
                    default="A,B,C,D,E,F,K,L,N,Q,R,U,V,Z,d,f,g,i,k,n,o,p,q,r,s,t,u,v,x",
                    help="comma-separated identifier names to try dumping")
    ap.add_argument("--timeout", type=int, default=20)
    ap.add_argument("--workdir", default=None)
    ap.add_argument("--json")
    args = ap.parse_args()

    src = open(args.sample, encoding="utf-8", errors="replace").read()
    groups = find_vm_groups(src)
    if not groups:
        sys.exit("!! no candidate dispatch loop found")
    pc = pick_payload_vm(groups)
    blocks = groups[pc]
    mode = args.mode if args.mode is not None else max(
        range(len(blocks)), key=lambda i: blocks[i][4])
    start, end, M, ARR, richness = blocks[mode]
    print(f"[v15-payload-dump] pc-var '{pc}', dumping at mode {mode} "
          f"({M}={ARR}[{pc}]), fetch ends at byte {end}")

    candidates = [c for c in args.candidates.split(",") if c]
    probe = build_dump_probe(candidates)
    patched = src[:end] + probe + src[end:]

    workdir = args.workdir or tempfile.mkdtemp(prefix="v15dump_")
    os.makedirs(workdir, exist_ok=True)
    instrumented = os.path.join(workdir, "dumpprobe_" + os.path.basename(args.sample))
    out_prefix = os.path.join(workdir, "dump_run")
    open(instrumented, "w", encoding="utf-8").write(patched)

    cmd = [sys.executable, args.deobf, instrumented, "--luau", args.luau,
           "--timeout", str(args.timeout), "--out", out_prefix]
    subprocess.run(cmd, stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)
    raw = out_prefix + ".raw.txt"
    if not os.path.exists(raw):
        sys.exit(f"!! expected {raw}, not found")

    lens = {}
    chunks = {}  # name -> {seq: [values]}
    with open(raw, encoding="utf-8", errors="replace") as f:
        for line in f:
            m = re.search(r"\[\[VMARR\]\] (\w+) len=(\d+)", line)
            if m:
                lens[m.group(1)] = int(m.group(2))
                continue
            m = re.search(r"\[\[VMARR\]\]D (\w+) (\d+) (.*)", line)
            if m:
                name, seq, body = m.group(1), int(m.group(2)), m.group(3)
                # the raw line is itself a %q-quoted Lua string (see
                # dynamic/deobf_v15.py's log()); the greedy capture above
                # swallows that closing quote along with our data.
                body = body.rstrip('"')
                vals = []
                for tok in body.split(","):
                    if tok == "_":
                        vals.append(None)
                    elif tok == "?" or tok.startswith("S"):
                        vals.append(tok)
                    else:
                        try:
                            vals.append(int(tok))
                        except ValueError:
                            try:
                                vals.append(float(tok))
                            except ValueError:
                                vals.append(tok)
                chunks.setdefault(name, {})[seq] = vals

    arrays = {}
    for name, seqmap in chunks.items():
        merged = []
        for seq in sorted(seqmap):
            merged.extend(seqmap[seq])
        arrays[name] = merged

    for name, vals in sorted(arrays.items()):
        print(f"  {name}: len={lens.get(name)} captured={len(vals)}")
    if not arrays:
        print("  !! nothing captured -- either the mode/offset is wrong, the run "
              "never reached that dispatch loop, or none of --candidates are in "
              "scope there. Check the raw output:", raw)

    if args.json:
        json.dump({"pc_var": pc, "mode": mode, "opcode_var": M, "fetch_array": ARR,
                   "lengths": lens, "arrays": arrays}, open(args.json, "w"), indent=1)
        print(f"\n  -> {args.json}")
    return 0


if __name__ == "__main__":
    sys.exit(main())
