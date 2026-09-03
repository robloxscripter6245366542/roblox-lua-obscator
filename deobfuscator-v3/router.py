"""Unified entry point: detects which engine a script needs and runs it.

Three engines live in this repo:
  - envlog    lune + main.luau, the Luau environment logger / dumper
  - prom      node + v1sexy/main.js, the Prometheus deobfuscator
  - luraph    python + ../luraph-deobf, the Luraph (LPH / v13-v15) unpacker
"""
import os
import pathlib
import re
import shutil
import signal
import subprocess
import sys
import tempfile
import time

ROOT = pathlib.Path(__file__).resolve().parent
V1SEXY = ROOT / "v1sexy"

_local = ("lune.exe" if sys.platform == "win32" else "lune")
LUNE = ROOT / _local if (ROOT / _local).is_file() else shutil.which("lune") or "lune"

TIME_RE = re.compile(r"Finished processing in ([\d.]+) seconds", re.I)

# Node prints a version banner and stack frames after the real message, so the
# last log line is almost never the useful one.
ERR_RE = re.compile(r"^(?:\w*Error|error|panic|Uncaught)\b.*", re.M)
NOISE_RE = re.compile(r"^\s*(?:at\s|\^+\s*$|Node\.js v|$)")


def _reason(log: str) -> str:
    m = ERR_RE.search(log)
    if m:
        return m.group(0).strip()[:300]
    lines = [l.strip() for l in log.splitlines()
             if l.strip() and not NOISE_RE.match(l)]
    return lines[-1][:300] if lines else "unknown error"

# Prometheus wraps the whole payload in `return(function(...)` and builds a
# string table that it then un-reverses with an ipairs loop over index pairs.
PROM_WRAPPER = re.compile(r"return\s*\(\s*function\s*\(\s*\.\.\.\s*\)", re.I)
PROM_STRTABLE = re.compile(r"local\s+\w+\s*=\s*\{\s*[\"'`\\]", re.I)
PROM_REVERSE = re.compile(r"for\s+\w+\s*,\s*\w+\s+in\s+ipairs\s*\(\s*\{\s*\{", re.I)
PROM_WATERMARK = re.compile(r"_WATERMARK\s*=", re.I)

# Luraph tells: the version banner comment and the `[=[LPH....` / `[==[LPH....`
# packed-stream headers. v15 also ships distinctive LPH_* macro artifacts.
LURAPH_BANNER = re.compile(r"Luraph\s+Obfuscator", re.I)
LURAPH_STREAM = re.compile(r"\[=*\[\s*LPH")
LURAPH_MACRO = re.compile(
    r"LPH_(?:ATTRIBUTES|PRECHECK|REWRITE|ENCBUF|STACKALLOC|JIT|NO_VIRTUALIZE)")


def _is_luraph(head: str) -> bool:
    if LURAPH_BANNER.search(head):
        return True
    if LURAPH_STREAM.search(head):
        return True
    if LURAPH_MACRO.search(head):
        return True
    return False


def detect(src: str) -> str:
    """Return 'luraph', 'prom', or 'envlog' for the given script source."""
    head = src[:20000]

    # Luraph is the most distinctive family (banner + LPH streams); check it
    # first so an LPH payload never falls through to the generic env logger.
    if _is_luraph(head):
        return "luraph"

    # wearedevs output opens with `return(function(...)` + a string table too,
    # so it scores as Prometheus below — but its banner is an unambiguous tell
    # that it is NOT Prometheus. The env logger is the right engine for it.
    if "wearedevs" in head.lower():
        return "envlog"

    # The wrapper is the one structure every Prometheus payload has. Without it
    # we can't distinguish output from ordinary Lua that merely mentions
    # Prometheus (its own source, for one), so fall back to the general engine.
    m = PROM_WRAPPER.search(head)
    if not m:
        return "envlog"

    # Real output opens with the wrapper; a match buried deep in a big file is
    # far more likely to be an unrelated function than the payload.
    if m.start() > 2000:
        return "envlog"

    score = 1
    if PROM_STRTABLE.search(head):
        score += 1
    if PROM_REVERSE.search(head):
        score += 2
    if PROM_WATERMARK.search(head):
        score += 2

    return "prom" if score >= 2 else "envlog"


def _kill_tree(pid: int):
    if sys.platform == "win32":
        subprocess.run(["taskkill", "/F", "/T", "/PID", str(pid)], capture_output=True)
    else:
        try:
            os.killpg(os.getpgid(pid), signal.SIGKILL)
        except ProcessLookupError:
            pass


def _spawn(cmd, cwd, timeout, env=None):
    kwargs = {}
    if sys.platform == "win32":
        kwargs["creationflags"] = subprocess.CREATE_NEW_PROCESS_GROUP
    else:
        kwargs["start_new_session"] = True

    proc = subprocess.Popen(
        cmd, cwd=str(cwd), env=env,
        stdout=subprocess.PIPE, stderr=subprocess.STDOUT, text=True, **kwargs,
    )
    try:
        log, _ = proc.communicate(timeout=timeout)
    except subprocess.TimeoutExpired:
        _kill_tree(proc.pid)
        try:
            proc.communicate(timeout=5)
        except Exception:
            pass
        return None, "timeout"
    return proc.returncode, log or ""


def _luraph_dir():
    """Locate the sibling luraph-deobf toolkit, or None if it isn't present."""
    cands = []
    env = os.environ.get("LURAPH_DIR")
    if env:
        cands.append(pathlib.Path(env))
    cands += [ROOT.parent / "luraph-deobf", ROOT / "luraph-deobf"]
    for c in cands:
        if (c / "deobfuscate.py").is_file():
            return c
    return None


def _run_luraph(in_path, out_path, timeout):
    """Run the Luraph unpacker and compose a single self-describing .lua file.

    The luraph-deobf staged pipeline writes a directory (report.md + peeled
    artifacts), and unpack_runnable.py emits a behaviour-identical script. We
    assemble the richest available result into out_path:

        report summary (as `-- ` comments)  +  best recovered code

    Best code preference: runnable unpack (v13/v14.x) > peeled VM source >
    an analysis-only note (v15, where static peeling can fail by design).
    Returns (ok, reason).
    """
    lur = _luraph_dir()
    if lur is None:
        return False, "luraph toolkit not found (expected sibling luraph-deobf/)"

    work = pathlib.Path(tempfile.mkdtemp(prefix="luraph_"))
    try:
        code, log = _spawn(
            ["python3", "deobfuscate.py", str(in_path.resolve()), "-o", str(work)],
            cwd=lur, timeout=timeout,
        )
        if code is None:
            return False, "timeout"

        report = work / "report.md"
        peeled_src = work / "peeled" / "stage_0.lua"
        runnable = work / "unpacked_runnable.lua"

        # Best-effort runnable unpack; harmless if it fails (e.g. on v15).
        _spawn(
            ["python3", "unpack_runnable.py", str(in_path.resolve()),
             "-o", str(runnable)],
            cwd=lur, timeout=timeout,
        )

        header = ""
        if report.is_file():
            header = "\n".join(
                "-- " + l for l in report.read_text(errors="ignore").splitlines())

        body, note = None, None
        if runnable.is_file() and runnable.stat().st_size > 1024:
            body = runnable.read_text(errors="ignore")
            note = ("-- [luraph] runnable unpack: base-85 + LZMA + anti-tamper "
                    "shell removed;\n-- the VM interpreter is now plain source "
                    "(the program logic stays VM bytecode).")
        elif peeled_src.is_file() and peeled_src.stat().st_size > 128:
            body = peeled_src.read_text(errors="ignore")
            note = "-- [luraph] recovered VM interpreter / loader source (static peel)."

        if body is None:
            # No code recovered (typically v15). Deliver the analysis report so
            # the user still gets a self-describing artifact explaining why.
            if not header:
                return False, _reason(log)
            body = ("-- (no static code recovery — see the analysis above.\n"
                    "--  v15 key-encrypts the bytecode at rest, so a static peel\n"
                    "--  can legitimately fail by design; a dynamic capture is\n"
                    "--  needed. See luraph-deobf/v15.md.)")
            note = None

        parts = [p for p in (header, note, body) if p]
        out_path.write_text("\n\n".join(parts) + "\n", encoding="utf-8", errors="ignore")
        return True, None
    finally:
        shutil.rmtree(work, ignore_errors=True)


def run(in_path: pathlib.Path, out_path: pathlib.Path, engine=None,
        timeout=100, extra_args=(), lute_bin=None):
    """Run the appropriate engine. Returns (ok, reason, took, engine)."""
    src = in_path.read_text(encoding="utf-8", errors="ignore")
    engine = engine or detect(src)

    started = time.perf_counter()

    if engine == "luraph":
        ok, reason = _run_luraph(in_path, out_path, timeout)
        took = time.perf_counter() - started
        if not ok:
            return False, reason, took, engine
        return True, None, took, engine

    if engine == "prom":
        # main.js resolves ./mods and ./reversing relative to its own dir.
        code, log = _spawn(
            ["node", "main.js", str(in_path.resolve()), str(out_path.resolve()),
             *extra_args],
            cwd=V1SEXY, timeout=timeout,
        )
    else:
        env = os.environ.copy()
        if lute_bin:
            env["HOOKOP_BIN"] = str(lute_bin)
        in_rel = os.path.relpath(in_path, ROOT).replace("\\", "/")
        out_rel = os.path.relpath(out_path, ROOT).replace("\\", "/")
        code, log = _spawn(
            [str(LUNE), "run", "main.luau", in_rel, out_rel, *extra_args],
            cwd=ROOT, timeout=timeout, env=env,
        )

    if code is None:
        return False, "timeout", timeout, engine

    took = time.perf_counter() - started
    m = TIME_RE.search(log)
    if m:
        took = float(m.group(1))

    if code != 0 or not out_path.exists():
        return False, _reason(log), took, engine

    # The Luau engine signals failure in-band by prefixing the output file
    # with a single "--err <reason>" line.
    if engine == "envlog":
        text = out_path.read_text(errors="ignore")
        if text.startswith("--err"):
            reason = text.split("\n", 1)[0][5:].strip()
            return False, reason[:300] or "engine error", took, engine

    return True, None, took, engine


def main():
    args = sys.argv[1:]
    if not args:
        print("usage: python router.py <input.lua> [out.lua] "
              "[--prom|--envlog|--luraph] [engine args...]")
        return 1

    engine = None
    rest = []
    for a in args:
        if a == "--prom":
            engine = "prom"
        elif a == "--envlog":
            engine = "envlog"
        elif a == "--luraph":
            engine = "luraph"
        else:
            rest.append(a)

    in_path = pathlib.Path(rest[0]).resolve()
    out_path = pathlib.Path(rest[1] if len(rest) > 1 else "out.lua").resolve()
    extra = rest[2:]

    if not in_path.is_file():
        print(f"no such file: {in_path}")
        return 1

    ok, reason, took, used = run(in_path, out_path, engine=engine, extra_args=extra)
    if ok:
        print(f"[{used}] done in {took:.2f}s -> {out_path}")
        return 0
    print(f"[{used}] failed after {took:.2f}s: {reason}")
    return 1


if __name__ == "__main__":
    sys.exit(main())
