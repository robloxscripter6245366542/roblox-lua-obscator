#!/usr/bin/env python3
# ============================================================
#  v15_payload_trace_zcalls.py  --  what does t[F[4]] actually compute?
#
#  v15.md's "Payload recovery harness" section traced the payload VM's only
#  real exit gate to a variable `Z`, confirmed nil live, set at exactly 3
#  sites (one per T-mode 1/2/3) by an identical save-call-restore wrapper:
#      <save K=Z>; Y=t[F[4]](t,nil,<arg>,F,nil,nil); H(Y,N); R[<reg>]=Y;
#      <restore>,Z=<arg>,K
#  `t` is the same 127-entry constant/handler pool devirt/v15_opcode_map.md
#  already maps for the outer 145-handler loader stage. This instruments
#  all 3 call sites directly (source-level injection, same technique as
#  every other tool in devirt/) to log, on every invocation: which handler
#  index (F[4]) got called, what it returned (Y), and F's own shape --
#  answering "what does this call actually compute" empirically instead of
#  reading the 145-handler map by hand.
#
#  Usage:
#    python3 devirt/v15_payload_trace_zcalls.py sample_v15.lua \
#        --luau dynamic/luau --deobf dynamic/deobf_v15.py --timeout 60
# ============================================================

import argparse
import os
import re
import subprocess
import sys
import tempfile

TAG = "[[ZCALL]]"

CALL_RE = re.compile(r"Y=t\[F\[4\]\]\(t,nil,(\w+),F,nil,nil\);")


def describe_snippet():
    return (
        "local function __describe(v) "
        "local ty=type(v) "
        "if ty=='table' then local n=0 for _ in pairs(v) do n=n+1 end return 'table(n='..n..')' end "
        "if ty=='function' then return tostring(v) end "
        "if ty=='string' then return (#v<=60 and string.format('%q',v) or ('str,len='..#v)) end "
        "return tostring(v) end "
    )


def build_probe(site_idx, arg_name):
    return (
        f'__zcall_n_{site_idx}=(__zcall_n_{site_idx} or 0)+1 '
        f'if __zcall_n_{site_idx}<=20 then '
        f'print("{TAG} site={site_idx} n="..__zcall_n_{site_idx}.." F[4]="..__describe(F and F[4]) '
        f'.." arg="..__describe({arg_name}).." F="..__describe(F).." Y="..__describe(Y)) end;'
    )


def main():
    ap = argparse.ArgumentParser(description="trace what t[F[4]] computes at each of Z's 3 call sites")
    ap.add_argument("sample")
    ap.add_argument("--luau", default="dynamic/luau")
    ap.add_argument("--deobf", default="dynamic/deobf_v15.py")
    ap.add_argument("--timeout", type=int, default=60)
    ap.add_argument("--workdir", default=None)
    args = ap.parse_args()

    src = open(args.sample, encoding="utf-8", errors="replace").read()
    matches = list(CALL_RE.finditer(src))
    if not matches:
        sys.exit("!! no `Y=t[F[4]](t,nil,<arg>,F,nil,nil);` call sites found -- "
                 "sample structure may differ from the one this was built against")
    print(f"[v15-zcalls] found {len(matches)} call site(s) at offsets "
          f"{[m.start() for m in matches]}")

    patched = src
    for i, m in sorted(enumerate(matches), key=lambda x: -x[1].start()):
        arg_name = m.group(1)
        probe = build_probe(i, arg_name)
        patched = patched[:m.end()] + probe + patched[m.end():]
    patched = describe_snippet() + patched

    workdir = args.workdir or tempfile.mkdtemp(prefix="v15zcalls_")
    os.makedirs(workdir, exist_ok=True)
    instrumented = os.path.join(workdir, "zcalls_" + os.path.basename(args.sample))
    out_prefix = os.path.join(workdir, "zcalls_run")
    open(instrumented, "w", encoding="utf-8").write(patched)

    cmd = [sys.executable, args.deobf, instrumented, "--luau", args.luau,
           "--timeout", str(args.timeout), "--out", out_prefix]
    print(f"[v15-zcalls] running (timeout={args.timeout}s)...")
    subprocess.run(cmd, stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)
    raw = out_prefix + ".raw.txt"
    if not os.path.exists(raw):
        sys.exit(f"!! expected {raw}, not found")

    events = []
    with open(raw, encoding="utf-8", errors="replace") as f:
        for line in f:
            m = re.search(re.escape(TAG) + r" (.*)", line)
            if m:
                events.append(m.group(1).rstrip('"'))

    print(f"\n[v15-zcalls] {args.sample}: {len(events)} call(s) observed (first 20 per site)")
    for e in events:
        print(f"  {e}")
    if not events:
        print("  !! t[F[4]] was never called at any of the 3 sites within the time budget")
    return 0


if __name__ == "__main__":
    sys.exit(main())
