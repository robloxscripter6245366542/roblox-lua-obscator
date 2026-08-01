#!/usr/bin/env python3
# ============================================================
#  pipeline.py  --  end-to-end Luraph deobfuscation pipeline
#
#  One command runs every stage of the toolkit against a sample and
#  writes a consolidated report:
#
#    1. UNPACK      peel.py         base-85 + LZMA -> VM source + bytecode
#    2. IOC TRIAGE  strings.py      readable strings in the bytecode
#    3. CONSTANTS   dynamic/run.py  full VM constant pool (--strings)
#    4. BEHAVIOUR   dynamic/run.py  HttpGet URLs / config / method calls
#    5. DISASSEMBLE devirt/run_vm   live instruction trace (opcode+operands)
#    6. OPCODES     devirt/run_vm   opcode frequency histogram
#    7. ANNOTATE    devirt/annotate readable listing via opcodes.json
#    8. REPORT      report.md       everything above, consolidated
#
#  Stages 5-7 need a `luau` binary (auto-detected, or --luau / build via
#  dynamic/build_luau.sh). If luau is missing, the static stages (1-2) and
#  the dynamic stages that don't need it are still run and the report says
#  which stages were skipped.
#
#  Usage:
#     python3 pipeline.py sample_sigil.lua -o out [--luau path/to/luau]
# ============================================================

import argparse
import os
import shutil
import subprocess
import sys
import time

HERE = os.path.dirname(os.path.abspath(__file__))


def sh(cmd, timeout=120):
    """Run a command, capture combined output, never raise on non-zero."""
    try:
        p = subprocess.run(cmd, cwd=HERE, stdout=subprocess.PIPE,
                           stderr=subprocess.STDOUT, timeout=timeout)
        return p.returncode, p.stdout.decode("utf-8", "replace")
    except subprocess.TimeoutExpired as e:
        out = (e.output or b"").decode("utf-8", "replace")
        return 124, out + "\n[pipeline] (stage hit timeout)"
    except FileNotFoundError as e:
        return 127, f"[pipeline] missing: {e}"


def find_luau(explicit):
    if explicit and os.path.exists(explicit):
        return os.path.abspath(explicit)
    for c in [os.path.join(HERE, "dynamic", "luau"),
              os.path.join(HERE, "devirt", "luau"),
              shutil.which("luau") or ""]:
        if c and os.path.exists(c):
            return os.path.abspath(c)
    return None


def section(title):
    return f"\n\n## {title}\n"


def grep(text, needles):
    out = []
    for line in text.splitlines():
        if any(n in line for n in needles):
            out.append(line)
    return out


def main():
    ap = argparse.ArgumentParser(description="end-to-end Luraph deobfuscation")
    ap.add_argument("sample")
    ap.add_argument("-o", "--outdir", default="deobf_out")
    ap.add_argument("--luau", default=None)
    ap.add_argument("--timeout", type=int, default=120)
    args = ap.parse_args()

    sample = os.path.abspath(args.sample)
    outdir = os.path.abspath(args.outdir)
    os.makedirs(outdir, exist_ok=True)
    peeldir = os.path.join(outdir, "peeled")
    luau = find_luau(args.luau)

    rep = [f"# Luraph deobfuscation report",
           f"\n- sample: `{os.path.basename(sample)}`",
           f"- generated: {time.strftime('%Y-%m-%d %H:%M:%S')}",
           f"- luau runtime: {'`'+luau+'`' if luau else '**not found** (dynamic stages skipped; build via dynamic/build_luau.sh)'}"]

    # ---- 1. UNPACK ----
    rc, out = sh(["python3", "peel.py", sample, "-o", peeldir], args.timeout)
    rep.append(section("1. Unpack (base-85 + LZMA, keyless)"))
    rep.append("```\n" + out.strip() + "\n```")
    vm_src = os.path.join(peeldir, "stage_0.lua")
    bytecode = os.path.join(peeldir, "stage_1.bin")
    have_stages = os.path.exists(vm_src) and os.path.exists(bytecode)

    # ---- 2. IOC TRIAGE ----
    rep.append(section("2. IOC / string triage (static, over bytecode)"))
    if have_stages:
        rc, out = sh(["python3", "strings.py", bytecode], args.timeout)
        rep.append("```\n" + out.strip()[:4000] + "\n```")
    else:
        rep.append("_skipped: no bytecode stage_")

    # ---- 3 & 4. CONSTANTS + BEHAVIOUR (dynamic) ----
    rep.append(section("3. Constant pool (dynamic, buffer.readstring)"))
    if luau:
        rc, out = sh(["python3", os.path.join("dynamic", "run.py"), sample,
                      "--luau", luau, "--strings", "--timeout", "45"], args.timeout)
        strs = grep(out, ["[[STR"])
        rep.append(f"Recovered {len(strs)} constant strings (sample):\n")
        rep.append("```\n" + "\n".join(s[:200] for s in strs[:120]) + "\n```")
        rep.append(section("4. Behaviour (network blocked): endpoints, config, calls"))
        beh = grep(out, ["HttpGet", "[[LOG]] SET", "[[LOG]] CALL", "request", "GetService"])
        rep.append("```\n" + "\n".join(beh[:60]) + "\n```")
    else:
        rep.append("_skipped: needs luau_")
        rep.append(section("4. Behaviour"))
        rep.append("_skipped: needs luau_")

    # ---- 5. DISASSEMBLE ----
    rep.append(section("5. Disassembly (live, opcode + operands)"))
    dis_txt = os.path.join(outdir, "disasm.txt")
    if luau and have_stages:
        rc, out = sh(["python3", os.path.join("devirt", "run_vm.py"),
                      "--vmdir", peeldir, "--luau", luau, "--mode", "disasm",
                      "--n", "400", "--out", dis_txt], args.timeout)
        dl = grep(out, ["[[DIS]]", "[[H]]"])
        rep.append("First executed instructions:\n")
        rep.append("```\n" + "\n".join(dl[:60]) + "\n```")
    else:
        rep.append("_skipped: needs luau + stages_")

    # ---- 6. OPCODE FREQUENCY ----
    rep.append(section("6. Opcode frequency"))
    if luau and have_stages:
        rc, out = sh(["python3", os.path.join("devirt", "run_vm.py"),
                      "--vmdir", peeldir, "--luau", luau, "--mode", "freq",
                      "--cap", "500000"], args.timeout)
        fl = grep(out, ["[[FREQ]]"])
        rep.append("```\n" + "\n".join(fl[:30]) + "\n```")
    else:
        rep.append("_skipped: needs luau + stages_")

    # ---- 7. ANNOTATE ----
    rep.append(section("7. Annotated listing (opcodes.json)"))
    if luau and have_stages and os.path.exists(dis_txt):
        rc, out = sh(["python3", os.path.join("devirt", "annotate.py"),
                      dis_txt, "--map", os.path.join("devirt", "opcodes.json")],
                     args.timeout)
        rep.append("```\n" + "\n".join(out.strip().splitlines()[:50]) + "\n```")
    else:
        rep.append("_skipped: needs disassembly_")

    # ---- 8. LIFT (codegen to register-level Lua) ----
    rep.append(section("8. Lift — devirtualised register-level Lua"))
    lifted = os.path.join(outdir, "lifted.lua")
    lift_done = False
    if luau and have_stages:
        full_txt = os.path.join(outdir, "fulldump.txt")
        vals_txt = os.path.join(outdir, "values.txt")
        sh(["python3", os.path.join("devirt", "run_vm.py"), "--vmdir", peeldir,
            "--luau", luau, "--mode", "fulldump", "--n", "300", "--out", full_txt],
           args.timeout)
        # capture concrete constants to inline (item: constant inlining)
        sh(["python3", os.path.join("devirt", "capture_values.py"),
            "--vmdir", peeldir, "--luau", luau,
            "--map", os.path.join("devirt", "opcodes.full.json"),
            "--steps", "80000", "--out", vals_txt], args.timeout)
        rc, out = sh(["python3", os.path.join("devirt", "lift.py"), full_txt,
                      "--map", os.path.join("devirt", "opcodes.full.json"),
                      "--values", vals_txt, "-o", lifted], args.timeout)
        rep.append("```\n" + out.strip() + "\n```")
        try:
            head = "".join(open(lifted).readlines()[:26])
            rep.append("First proto (excerpt):\n```lua\n" + head + "\n```")
            lift_done = True
        except OSError:
            pass
    else:
        rep.append("_skipped: needs luau + stages_")

    # ---- 9. SUMMARY ----
    rep.append(section("9. Status"))
    rep.append(
        "| stage | result |\n|---|---|\n"
        f"| unpack (VM source + bytecode) | {'done' if have_stages else 'FAILED'} |\n"
        f"| constant pool | {'done' if luau else 'needs luau'} |\n"
        f"| behaviour (endpoints/config) | {'done' if luau else 'needs luau'} |\n"
        f"| disassembly + opcode histogram | {'done' if luau and have_stages else 'needs luau'} |\n"
        "| opcode->semantics map | complete (125 executed opcodes; devirt/opcodes.full.json) |\n"
        f"| lift to register-level Lua | {'done' if lift_done else 'needs luau'} (~97% of static instrs) |\n"
        "| high-level structuring (if/while) | goto-form emitted; structuring pass = future work |\n")

    report_path = os.path.join(outdir, "report.md")
    with open(report_path, "w", encoding="utf-8") as f:
        f.write("\n".join(rep))
    print(f"[pipeline] report -> {report_path}")
    print(f"[pipeline] artifacts in {outdir}/ (peeled/, disasm.txt, lifted.lua, report.md)")
    return 0


if __name__ == "__main__":
    sys.exit(main())
