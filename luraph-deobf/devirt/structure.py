#!/usr/bin/env python3
"""Local control-flow *structuring* backend — the offline replacement for the
lua.expert post-pass.

The devirtualiser recovers register-level Lua whose control flow is a
trace-linearised jump chain (`goto L_pc`). Folding that back into real
`if`/`while`/`for` is a relooper problem, and the tool that does it for Luau is
**medal** (https://github.com/shrimp-nz/medal) via its `luau-lifter` binary.

This module takes *valid Luau* source (e.g. luauvmp's `program.decompiled.luau`,
which is what the lua.expert post-pass also consumes), compiles it to standard
Luau bytecode locally with Lune — the exact bytes lua.expert would have received —
and then runs medal on those bytes **locally** instead of uploading them. The
result is structured Luau, produced with no network call.

    python3 structure.py program.decompiled.luau -o program.structured.lua \\
        --lifter /path/to/medal/target/release/luau-lifter

medal opcode key: it computes `opcode = (byte * key) % 256`. Lune's
`luau.compile` emits *unencrypted* bytecode, so the identity key (1) is correct;
`--encrypted` selects medal's 203 key for Roblox-executor-encrypted dumps.
"""
import argparse
import os
import subprocess
import sys
import tempfile

sys.path.insert(0, os.path.dirname(os.path.dirname(os.path.abspath(__file__))))
from luauvmp.lua_expert import compile_source_to_bytecode, LuaExpertError  # noqa: E402


def structure(source_path, lifter, *, runtime="lune", encrypted=False, timeout=180):
    """Compile Luau source to luauc and run medal's luau-lifter on it locally."""
    if not os.path.isfile(lifter):
        raise SystemExit(
            "medal luau-lifter binary not found: %s\n"
            "build it once with:\n"
            "  git clone https://github.com/shrimp-nz/medal && cd medal\n"
            "  cargo +nightly build --release -p luau-lifter" % lifter
        )
    bytecode = compile_source_to_bytecode(source_path, runtime=runtime, timeout=timeout)
    with tempfile.NamedTemporaryFile(suffix=".luac", delete=False) as fh:
        fh.write(bytecode)
        luac_path = fh.name
    try:
        cmd = [lifter, luac_path] + (["-e"] if encrypted else [])
        result = subprocess.run(cmd, text=True, capture_output=True, timeout=timeout)
    finally:
        os.unlink(luac_path)
    if result.returncode != 0:
        detail = "\n".join(x for x in (result.stdout, result.stderr) if x).strip()
        raise SystemExit("medal luau-lifter failed: %s" % (detail or "unknown error"))
    return result.stdout


def main():
    ap = argparse.ArgumentParser(description=__doc__,
                                 formatter_class=argparse.RawDescriptionHelpFormatter)
    ap.add_argument("source", help="valid Luau source (e.g. program.decompiled.luau)")
    ap.add_argument("-o", "--out", default=None, help="output file (default: stdout)")
    ap.add_argument("--lifter", default=os.environ.get("MEDAL_LIFTER", "luau-lifter"),
                    help="path to medal's luau-lifter binary (or $MEDAL_LIFTER)")
    ap.add_argument("--runtime", default="lune", help="Lune command for compilation")
    ap.add_argument("--encrypted", action="store_true",
                    help="input is a Roblox-executor-encrypted dump (medal key 203)")
    ap.add_argument("--timeout", type=int, default=180)
    args = ap.parse_args()

    try:
        out = structure(args.source, args.lifter, runtime=args.runtime,
                        encrypted=args.encrypted, timeout=args.timeout)
    except LuaExpertError as exc:
        raise SystemExit("compile-to-luauc failed: %s" % exc)

    if args.out:
        with open(args.out, "w", encoding="utf-8") as fh:
            fh.write(out)
        sys.stderr.write("[structure] wrote %s (%d bytes)\n" % (args.out, len(out)))
    else:
        sys.stdout.write(out)
    return 0


if __name__ == "__main__":
    sys.exit(main())
