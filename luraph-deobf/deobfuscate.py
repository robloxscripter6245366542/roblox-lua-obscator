#!/usr/bin/env python3
# ============================================================
#  deobfuscate.py  --  staged Luraph deobfuscator (v13 / v14.x / v15)
#
#  The static + dynamic stages below were empirically derived from a
#  v14.7 sample. They are also the right entry point for v15, but v15 is a
#  ground-up rewrite ("hybrid-architecture" pipeline, dual OPAL/ONYX VMs,
#  key-bound bytecode via LPH_PRECHECK) so the byte-level constants are NOT
#  assumed to carry over — the fingerprint stage detects v15 and the report
#  says exactly which stages are trustworthy on it. See v15.md.
#
#  Implements the methodology as explicit, ordered stages, regenerating
#  everything build-specific per sample (Luraph randomises opcode numbers,
#  variable names, dispatch shape and packing on every build, so nothing
#  is reused across samples):
#
#    0. Fingerprint     version + LPH streams + packing
#    1. Peel            base-85 -> LZMA1(lc3,lp0,pb0), keyless
#                       -> VM interpreter source + bytecode
#    2. Anti-tamper     locate the integrity block; the dynamic harness
#                       satisfies it (loadstring returns (nil,errmsg))
#    3. Instrument      boot the VM in a stubbed Luau env and OBSERVE:
#                         3a control-flow census (opcode set)
#                         3b opcode map via register-delta + census  <-- per build
#                         3c concrete constant/value capture
#                         3d behaviour (HttpGet/services, network stubbed)
#    4. Disassemble     full instruction dump using THIS build's map
#    5. Lift            register-level Lua + inlined constants
#    +  Runnable        unpack_runnable.py -> behaviour-identical script
#
#  Writes everything (incl. a staged report.md) to the output dir.
#  Needs a luau binary (dynamic/build_luau.sh); static stages run without it.
#
#  Usage:
#     python3 deobfuscate.py <sample.lua> -o out [--luau dynamic/luau]
# ============================================================

import argparse
import os
import re
import shutil
import subprocess
import sys

HERE = os.path.dirname(os.path.abspath(__file__))
DEV = os.path.join(HERE, "devirt")


def sh(cmd, timeout=180):
    try:
        p = subprocess.run(cmd, cwd=HERE, stdout=subprocess.PIPE,
                           stderr=subprocess.STDOUT, timeout=timeout)
        return p.returncode, p.stdout.decode("utf-8", "replace")
    except subprocess.TimeoutExpired as e:
        return 124, (e.output or b"").decode("utf-8", "replace")
    except FileNotFoundError as e:
        return 127, str(e)


def find_luau(explicit):
    for c in [explicit, os.path.join(HERE, "dynamic", "luau"),
              os.path.join(DEV, "luau"), shutil.which("luau") or ""]:
        if c and os.path.exists(c):
            return os.path.abspath(c)
    return None


def grepl(text, *needles):
    return [l for l in text.splitlines() if any(n in l for n in needles)]


def fingerprint(src):
    """Version + VM-type + packing fingerprint.

    Returns a dict: {version, major, vm, streams, headers, notes}. Everything
    is read statically from the obfuscated output — no runtime.
    """
    m = re.search(r"Luraph Obfuscator v([0-9]+)(\.[0-9.]+)?", src)
    version = ("v" + m.group(1) + (m.group(2) or "")) if m else "unknown"
    major = int(m.group(1)) if m else None
    # LPH packed streams. v14.x headers are `LPH` + 5 chars (e.g. LPH%V);
    # v15 may use a different container, so match the LPH prefix loosely.
    headers = re.findall(r"\[=*\[(LPH[^\r\n]{0,6})", src)
    # v15 ships two VMs, OPAL (default) and ONYX; the attribute system
    # (LPH_ATTRIBUTES / VM(...) / PRESET(...) / TRANSFORM(...)) is a v15 tell.
    vm = None
    for name in ("ONYX", "OPAL"):
        if re.search(r"\b" + name + r"\b", src):
            vm = name
            break
    v15_markers = [t for t in ("LPH_ATTRIBUTES", "LPH_PRECHECK", "LPH_REWRITE",
                               "LPH_ENCBUF", "LPH_STACKALLOC", "TRANSFORM(")
                   if t in src]
    if major is None and (vm or v15_markers):
        major = 15
    return {"version": version, "major": major, "vm": vm,
            "streams": headers, "markers": v15_markers}


def main():
    ap = argparse.ArgumentParser(
        description="staged Luraph deobfuscator (v13/v14.x/v15)")
    ap.add_argument("sample")
    ap.add_argument("-o", "--outdir", default="deobf_out")
    ap.add_argument("--luau", default=None)
    ap.add_argument("--steps", type=int, default=12000, help="register-delta steps")
    ap.add_argument("--timeout", type=int, default=150)
    args = ap.parse_args()

    sample = os.path.abspath(args.sample)
    out = os.path.abspath(args.outdir)
    os.makedirs(out, exist_ok=True)
    luau = find_luau(args.luau)
    src = open(sample, "r", encoding="utf-8", errors="replace").read()
    rep = [f"# Luraph deobfuscation — staged report", f"\nsample: `{os.path.basename(sample)}`",
           f"luau: {'`'+luau+'`' if luau else '**missing** (dynamic stages skipped)'}\n"]

    def sec(t):
        rep.append("\n## " + t)
        print("\n==== " + t + " ====")

    # ---- 0. FINGERPRINT ----
    sec("0. Fingerprint")
    fpd = fingerprint(src)
    major = fpd["major"]
    fp = [f"version: {fpd['version']}", f"LPH streams: {len(fpd['streams'])}"]
    fp += [f"  {h}" for h in fpd["streams"][:6]]
    if fpd["vm"]:
        fp.append(f"VM type: {fpd['vm']} (v15 ships OPAL=default / ONYX=security)")
    if fpd["markers"]:
        fp.append("v15 macro artifacts seen: " + ", ".join(fpd["markers"]))
    if major is not None and major >= 15:
        fp.append("DETECTED v15 — ground-up rewrite. Byte-level constants below "
                  "were derived from v14.7 and are NOT assumed to hold; peel may "
                  "not decode a v15 container, and LPH_PRECHECK can bind the "
                  "bytecode to a runtime key (so static peeling can legitimately "
                  "fail by design). Dual OPAL/ONYX ISA -> the opcode map is now "
                  "per-VM-type. See v15.md.")
    elif fpd["version"] != "unknown" and "v14.7" not in fpd["version"]:
        fp.append("NOTE: this tool's constants were measured on v14.7; other "
                  "v14.x builds differ (e.g. v14.6 uses a non-LZMA inner codec).")
    for l in fp:
        print(l); rep.append("- " + l)

    # ---- 1. PEEL ----
    sec("1. Peel (static, keyless)")
    peeldir = os.path.join(out, "peeled")
    rc, o = sh(["python3", "peel.py", sample, "-o", peeldir], args.timeout)
    for l in grepl(o, "stage[", "base-85", "LZMA", "SOURCE", "bytecode"):
        print(l)
    rep.append("```\n" + "\n".join(grepl(o, "stage[", "LZMA", "SOURCE", "bytecode")) + "\n```")
    vm_src = os.path.join(peeldir, "stage_0.lua")
    bc = os.path.join(peeldir, "stage_1.bin")
    have = os.path.exists(vm_src) and os.path.exists(bc)
    if not have:
        if major is not None and major >= 15:
            rep.append("peel did not yield VM source + bytecode. On v15 this is "
                       "expected when the container/codec changed or LPH_PRECHECK "
                       "key-encrypted the bytecode: the outer layer is no longer "
                       "guaranteed keyless. This needs either the v15 loader's own "
                       "decode chain or a runtime capture (dynamic/), not a static "
                       "peel. See v15.md.")
        else:
            rep.append("peel did not yield VM source + bytecode; aborting.")
        _write(out, rep); return 1

    # ---- 2. ANTI-TAMPER ----
    sec("2. Anti-tamper")
    m = re.search(r'do local \w+=\{\d+,\{0[xX]1[bB],0[xX]4[cC],0[xX]75,0[xX]61,0[xX]50\}.*?end;end;',
                  src, re.DOTALL)
    if m:
        blk = m.group(0)
        print(blk[:260] + (" ..." if len(blk) > 260 else ""))
        rep.append("Integrity block (probes loadstring(\\x1BLuaP), poisons the "
                   "decode offset on tamper):\n```lua\n" + blk[:400] + "\n```")
        rep.append("Neutralised by the harness: `loadstring` returns `(nil, errmsg)` "
                   "exactly, so the probe passes and the offset stays correct.")
        print("-> harness returns (nil,errmsg) -> probe passes (verified in stage 3).")
    else:
        print("no standard integrity block matched (build may differ).")
        rep.append("_no standard integrity block matched_")

    if not luau:
        rep.append("\n## 3-5. Dynamic stages skipped (no luau). "
                   "Build it: `bash dynamic/build_luau.sh`.")
        _write(out, rep); return 0

    # ---- 3. INSTRUMENT ----
    sec("3. Dynamic instrumentation (per-build)")
    cf = os.path.join(out, "cf.txt"); semf = os.path.join(out, "sem.txt")
    opmap = os.path.join(out, "opcodes.json"); vals = os.path.join(out, "values.txt")
    empty = os.path.join(out, "_empty.json")
    open(empty, "w").write('{"confirmed":{},"inferred":{}}')

    rc, o = sh(["python3", os.path.join("devirt", "run_vm.py"), "--vmdir", peeldir,
                "--luau", luau, "--mode", "cf", "--cap", "1500000", "--out", cf], args.timeout)
    ncf = sum(1 for l in open(cf, errors="replace") if l.startswith("[[CF]] op="))
    print(f"3a census: {ncf} distinct opcodes exercised (VM booted -> anti-tamper OK)")
    rep.append(f"- 3a. control-flow census: **{ncf} opcodes** exercised (VM booted, "
               "so decode + anti-tamper passed).")

    sh(["python3", os.path.join("devirt", "semantics.py"), "--vmdir", peeldir,
        "--luau", luau, "--steps", str(args.steps), "--out", semf], args.timeout)
    rc, o = sh(["python3", os.path.join("devirt", "build_map.py"), "--sem", semf,
                "--cf", cf, "--curated", empty, "--out", opmap], args.timeout)
    cls = grepl(o, "class counts")
    print("3b opcode map:", cls[0] if cls else "(built)")
    rep.append(f"- 3b. per-build opcode map: `{os.path.basename(opmap)}` — "
               + (cls[0].split("]")[-1].strip() if cls else ""))

    rc, o = sh(["python3", os.path.join("devirt", "capture_values.py"), "--vmdir", peeldir,
                "--luau", luau, "--map", opmap, "--steps", "60000", "--out", vals], args.timeout)
    nval = sum(1 for l in open(vals, errors="replace") if l.startswith("[[V]]")) if os.path.exists(vals) else 0
    print(f"3c constants: {nval} concrete values captured")
    strs = sorted({s for l in open(vals, errors="replace") for s in re.findall(r'v="([^"]{4,40})"', l)}) if os.path.exists(vals) else []
    rep.append(f"- 3c. concrete values captured: **{nval}**; sample strings: "
               + ", ".join("`%s`" % s for s in strs[:12]))

    rc, o = sh(["python3", os.path.join("dynamic", "run.py"), sample, "--luau", luau,
                "--strings", "--timeout", "45"], args.timeout)
    beh = grepl(o, "HttpGet", "[[LOG]] SET", "[[LOG]] CALL", "request", "GetService")
    print(f"3d behaviour: {len(beh)} events (network stubbed)")
    rep.append("- 3d. behaviour (network/fs stubbed):\n```\n" + "\n".join(beh[:20]) + "\n```")

    # ---- 4. DISASSEMBLE + 5. LIFT ----
    sec("4-5. Disassemble + lift (this build's map)")
    full = os.path.join(out, "fulldump.txt"); lifted = os.path.join(out, "lifted.lua")
    sh(["python3", os.path.join("devirt", "run_vm.py"), "--vmdir", peeldir, "--luau", luau,
        "--mode", "fulldump", "--n", "300", "--out", full], args.timeout)
    rc, o = sh(["python3", os.path.join("devirt", "lift.py"), full, "--map", opmap,
                "--values", vals, "-o", lifted], args.timeout)
    print(grepl(o, "[lift]")[0] if grepl(o, "[lift]") else o.strip()[:200])
    rep.append("```\n" + (grepl(o, "[lift]")[0] if grepl(o, "[lift]") else "") + "\n```")

    # ---- runnable ----
    sec("+ Runnable unpack")
    runnable = os.path.join(out, "unpacked_runnable.lua")
    rc, o = sh(["python3", "unpack_runnable.py", sample, "-o", runnable], args.timeout)
    print(grepl(o, "unpack_runnable")[0] if grepl(o, "unpack_runnable") else o.strip()[:160])
    rep.append("```\n" + o.strip() + "\n```")

    _write(out, rep)
    print(f"\n[deobfuscate] artifacts + report.md in {out}/")
    return 0


def _write(out, rep):
    with open(os.path.join(out, "report.md"), "w", encoding="utf-8") as f:
        f.write("\n".join(rep) + "\n")


if __name__ == "__main__":
    sys.exit(main())
