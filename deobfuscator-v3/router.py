"""Unified entry point: detects which engine a script needs and runs it.

Two engines live in this repo:
  - envlog    lune + main.luau, the Luau environment logger / dumper
  - prom      node + v1sexy/main.js, the Prometheus deobfuscator
"""
import os
import pathlib
import re
import shutil
import signal
import subprocess
import sys
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


def detect(src: str) -> str:
    """Return 'prom' or 'envlog' for the given script source."""
    head = src[:20000]

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


def run(in_path: pathlib.Path, out_path: pathlib.Path, engine=None,
        timeout=100, extra_args=(), lute_bin=None):
    """Run the appropriate engine. Returns (ok, reason, took, engine)."""
    src = in_path.read_text(encoding="utf-8", errors="ignore")
    engine = engine or detect(src)

    started = time.perf_counter()

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
        print("usage: python router.py <input.lua> [out.lua] [--prom|--envlog] [engine args...]")
        return 1

    engine = None
    rest = []
    for a in args:
        if a == "--prom":
            engine = "prom"
        elif a == "--envlog":
            engine = "envlog"
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
