#!/usr/bin/env python3
# ============================================================
#  loadstring_alias_dump.py  --  find + dump Luraph's indirect loadstring call
#
#  mm2.md's investigation of the second real Luraph v15.0 sample found that
#  its outer `j()` function DOES use `loadstring`, contrary to an initial
#  literal-text grep for `loadstring(` (zero hits) that wrongly ruled a
#  native-bytecode-loader theory out. The reason the grep missed it: Luraph
#  never spells `loadstring` as a bare call. It sits as a VALUE inside the
#  file's big constant-pool table (e.g. `[99]=loadstring`), gets destructured
#  into a short local alias alongside `pcall` and other builtins in one big
#  `local a,b,c,...=T[1],T[2],T.x,...` statement, and is invoked only through
#  that alias, e.g. `pcall_alias(loadstring_alias, decoded_source, "Luraph",
#  nil)`. Anyone repeating a literal `loadstring(` search on a new sample
#  will hit the same false negative.
#
#  This generalizes the manual technique used in that investigation:
#    1. find `loadstring`/`load` sitting as a table VALUE (regex on the
#       `key=builtin` shape Luraph's constant-pool tables use -- either a
#       numeric `[N]=` key or a bare `NAME=` key);
#    2. find a destructuring `local ...=SOMEIDENT[key]...` (or
#       `SOMEIDENT.key`) statement pulling that exact key into a local
#       alias, whatever the indexed identifier is named. This deliberately
#       does NOT try to resolve which variable "owns" the table literal
#       itself: in this shape the table is often never bound to a name at
#       all (mm2.md's sample calls it as `setmetatable({...},{}):j()`,
#       i.e. only ever referenced as the implicit self/`J` parameter inside
#       its own methods) -- so matching on the key alone, regardless of
#       which identifier indexes it, is both simpler and more robust than
#       trying to resolve that non-existent binding;
#    3. find the nearest call site using that alias name as a bare
#       identifier, and inject a probe immediately before its enclosing
#       statement that dumps every argument's type + a short, bounded
#       preview (string/buffer previews are truncated -- this is meant to
#       characterize the call, not exfiltrate a target's full decoded
#       payload).
#
#  All three steps are nearest-textual-match heuristics, same tolerance the
#  rest of devirt/ already accepts (v15_payload_probe.py's find_vm_groups,
#  chain_dispatch_probe.py's CHAIN_RE) in exchange for not needing full
#  scope-correct AST binding resolution. It can be fooled by an unrelated
#  same-named local shadowing the real alias between steps 2 and 3 (see
#  mm2.md's own `g`-shadowing trap) -- --list-only output should always be
#  eyeballed against the actual source before trusting a probe run.
#
#  Usage:
#    # just show what it found, don't run anything:
#    python3 devirt/loadstring_alias_dump.py sample.lua --list
#
#    # inject the dump probe and run it:
#    python3 devirt/loadstring_alias_dump.py sample.lua \
#        --luau dynamic/luau --deobf dynamic/deobf_v15.py --timeout 30
# ============================================================

import argparse
import os
import re
import subprocess
import sys
import tempfile

BUILTIN_VALUE_RE = re.compile(
    r'(?:\[(?P<numkey>\d+)\]|\b(?P<namekey>[A-Za-z_]\w*))=(?P<builtin>loadstring|load)\s*[,}]'
)

DUMP_TAG = "[[LSARG]]"


def find_builtin_value_sites(src):
    """Every place loadstring/load appears as a table VALUE (not a bare call
    expression -- `loadstring(` text is deliberately not matched here, since
    that shape is already easy to grep for directly and isn't what this tool
    is for)."""
    return [m for m in BUILTIN_VALUE_RE.finditer(src)]


def key_text(m):
    return f'[{m.group("numkey")}]' if m.group("numkey") else f'.{m.group("namekey")}'


def find_alias(src, key_txt):
    """Find `local a,b,...=X,SOMEIDENT[key] or SOMEIDENT.key,...` and return
    the local name at the same position plus the identifier that indexed it,
    searching the whole file. Deliberately identifier-agnostic on the
    left-hand side of the index (see module docstring) -- matches whatever
    name indexes this exact key, since the table itself is typically never
    bound to its own name in this codegen shape."""
    key_re = (
        r'\.' + re.escape(key_txt[1:]) if key_txt.startswith('.')
        else r'\[' + re.escape(key_txt[1:-1]) + r'\]'
    )
    ident_key_re = re.compile(r'^\s*\w+' + key_re + r'\s*$')
    for m in re.finditer(r'local\s+([\w,\s]+?)=([^;]+?);', src):
        names = [n.strip() for n in m.group(1).split(',')]
        exprs_raw = m.group(2)
        exprs = split_top_level_commas(exprs_raw)
        # Lua allows fewer values than names (`local a,b,c=1,2` leaves c
        # nil) -- Luraph's constant-pool destructures lean on this heavily
        # (declaring 29 names, only initializing 17), so zip positionally
        # rather than requiring equal lengths.
        for name, expr in zip(names, exprs):
            if ident_key_re.match(expr):
                return name, m.start(), m.end()
    return None, None, None


def split_top_level_commas(s):
    parts = []
    depth = 0
    cur = []
    for c in s:
        if c in '([{':
            depth += 1
        elif c in ')]}':
            depth -= 1
        if c == ',' and depth == 0:
            parts.append(''.join(cur))
            cur = []
        else:
            cur.append(c)
    parts.append(''.join(cur))
    return parts


def find_call_site(src, alias_name, after_offset, window=20_000):
    """Find the nearest real reference to `alias_name` after its
    declaration and return the enclosing call's (call_start, args_start,
    args_end) -- whether the alias is called directly (`alias_name(...)`,
    as if it were itself loadstring/pcall) or, the far more common Luraph
    shape, passed as a bare ARGUMENT to another aliased builtin (e.g.
    `pcall_alias(loadstring_alias, source, ...)`, see mm2.md). Bounded to a
    window right after the declaration, since Luraph uses an alias close to
    where it's destructured -- and, critically, skips any match immediately
    preceded by `.` or `:` (a field/method access, never a plain local
    reference) to avoid exactly the kind of shadow/false-match this tool's
    own module docstring warns about: an unrelated `obj:alias_name()`
    method call elsewhere in the file matching the bare name by pure text
    coincidence."""
    pat = re.compile(r'\b' + re.escape(alias_name) + r'\b')
    end = min(len(src), after_offset + window)
    for m in pat.finditer(src, after_offset, end):
        if m.start() > 0 and src[m.start() - 1] in '.:':
            continue  # field/method access, not our local
        pos = m.end()
        if pos < len(src) and src[pos] == '(':
            # direct call: alias_name(...)
            depth = 0
            i = pos
            args_start = pos + 1
            while i < len(src):
                if src[i] == '(':
                    depth += 1
                elif src[i] == ')':
                    depth -= 1
                    if depth == 0:
                        return m.start(), args_start, i
                i += 1
            continue
        # otherwise: alias used as a bare argument inside an ENCLOSING
        # call -- walk left to find that call's open paren, then forward
        # to find its matching close paren.
        depth = 0
        i = m.start() - 1
        open_paren = None
        while i >= 0:
            if src[i] == ')':
                depth += 1
            elif src[i] == '(':
                if depth == 0:
                    open_paren = i
                    break
                depth -= 1
            elif src[i] == ';':
                break  # ran off the start of the statement, no enclosing call
            i -= 1
        if open_paren is None:
            continue
        depth = 0
        j = open_paren
        args_start = open_paren + 1
        while j < len(src):
            if src[j] == '(':
                depth += 1
            elif src[j] == ')':
                depth -= 1
                if depth == 0:
                    return open_paren, args_start, j
            j += 1
    return None


def callee_name_before(src, open_paren_offset):
    """The identifier (if any) immediately before an open-paren offset --
    used only for the human-readable --list summary, so a shadowed alias
    misidentifying this isn't a correctness problem, just a label."""
    j = open_paren_offset - 1
    while j >= 0 and src[j] in ' \t\n':
        j -= 1
    k = j
    while k >= 0 and (src[k].isalnum() or src[k] == '_'):
        k -= 1
    return src[k + 1:j + 1] or None


def find_statement_start(src, offset):
    """Walk left to the start of the enclosing statement (previous `;` or
    block opener), a bounded heuristic -- good enough for Luraph's fully
    `;`-terminated minified output."""
    i = src.rfind(';', 0, offset)
    j = src.rfind('do', 0, offset)
    k = src.rfind('then', 0, offset)
    l = src.rfind('else', 0, offset)
    start = max(i, j, k, l)
    return start + 1 if start != -1 else 0


def build_dump_probe(alias_name, args_text):
    args = split_top_level_commas(args_text)
    args = [a.strip() for a in args if a.strip()]
    lines = []
    lines.append(f' if not __lsdump_{alias_name} then __lsdump_{alias_name}=true')
    for idx, a in enumerate(args):
        tmp = f'__a{idx}'
        lines.append(f' local __ok_{idx},{tmp}=pcall(function() return ({a}) end)')
        lines.append(
            f' if __ok_{idx} then local __ty=type({tmp}) '
            f'print("{DUMP_TAG} arg={idx} type="..__ty) '
            f'if __ty=="string" then print("{DUMP_TAG} arg={idx} len="..#{tmp}) '
            f'for __i=1,math.min(#{tmp},90),30 do print("{DUMP_TAG} arg={idx} head "..__i.." ".. '
            f'{tmp}:sub(__i,__i+29):gsub("[^%g ]",".")) end '
            f'elseif __ty=="buffer" then local __ok3,__bl=pcall(buffer.len,{tmp}) '
            f'print("{DUMP_TAG} arg={idx} buflen="..tostring(__bl)) '
            f'elseif __ty=="number" or __ty=="boolean" then '
            f'print("{DUMP_TAG} arg={idx} val="..tostring({tmp})) end '
            f'else print("{DUMP_TAG} arg={idx} eval-failed="..tostring({tmp})) end'
        )
    lines.append(' end;')
    return ' '.join(lines)


def main():
    ap = argparse.ArgumentParser(
        description="find + dump Luraph's indirect (constant-pool-aliased) loadstring call")
    ap.add_argument("sample")
    ap.add_argument("--list", action="store_true",
                     help="only show what was detected, don't inject/run anything")
    ap.add_argument("--which", type=int, default=0,
                     help="if multiple loadstring/load value-sites are found, which one (0-based)")
    ap.add_argument("--luau", default="dynamic/luau")
    ap.add_argument("--deobf", default="dynamic/deobf_v15.py")
    ap.add_argument("--timeout", type=int, default=30)
    ap.add_argument("--workdir", default=None)
    args = ap.parse_args()

    src = open(args.sample, encoding="utf-8", errors="replace").read()
    sites = find_builtin_value_sites(src)
    if not sites:
        sys.exit("!! no `loadstring`/`load` found sitting as a table value "
                  "(if it's a bare `loadstring(...)` call, you don't need this tool)")

    print(f"[loadstring-alias] {len(sites)} value-site(s) found:")
    for i, m in enumerate(sites):
        print(f"  [{i}] {m.group('builtin')} at key {key_text(m)}, offset {m.start()}")

    m = sites[args.which]
    builtin, key_txt = m.group("builtin"), key_text(m)
    print(f"[loadstring-alias] site [{args.which}]: key {key_txt}")

    alias, decl_start, decl_end = find_alias(src, key_txt)
    if not alias:
        sys.exit(f"!! could not find a destructuring alias for key {key_txt}")
    print(f"[loadstring-alias] alias local name: '{alias}' (declared at offset {decl_start})")

    call = find_call_site(src, alias, decl_end)
    if not call:
        sys.exit(f"!! could not find a call site using alias '{alias}' after its declaration")
    call_start, args_start, args_end = call
    args_text = src[args_start:args_end]
    callee = callee_name_before(src, call_start) or "?"
    tag = "direct call" if callee == alias else f"'{alias}' passed as an argument"
    print(f"[loadstring-alias] call site at offset {call_start} ({tag}): "
          f"{callee}({args_text[:200]}...)")

    if args.list:
        return 0

    stmt_start = find_statement_start(src, call_start)
    probe = build_dump_probe(alias, args_text)
    patched = src[:stmt_start] + probe + src[stmt_start:]

    workdir = args.workdir or tempfile.mkdtemp(prefix="lsalias_")
    os.makedirs(workdir, exist_ok=True)
    instrumented = os.path.join(workdir, "lsprobe_" + os.path.basename(args.sample))
    out_prefix = os.path.join(workdir, "ls_run")
    open(instrumented, "w", encoding="utf-8").write(patched)

    cmd = [sys.executable, args.deobf, instrumented, "--luau", args.luau,
           "--timeout", str(args.timeout), "--out", out_prefix]
    print(f"[loadstring-alias] running (timeout={args.timeout}s)...")
    subprocess.run(cmd, stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)
    raw = out_prefix + ".raw.txt"
    if not os.path.exists(raw):
        sys.exit(f"!! expected {raw}, not found")

    print()
    with open(raw, encoding="utf-8", errors="replace") as f:
        for line in f:
            m2 = re.search(re.escape(DUMP_TAG) + r" (.*)", line)
            if m2:
                print("  " + m2.group(1).rstrip('"'))
    return 0


if __name__ == "__main__":
    sys.exit(main())
