#!/usr/bin/env python3
"""Token-based Lua/Luau re-indenter.

Purely cosmetic: it reinserts newlines and indentation from the token stream
and never alters semantics. Uses the repo's `luauvmp.lualex` tokenizer so
string / number / long-comment boundaries are respected, and it guarantees the
output tokenises to the *same* token stream as the input (adjacent operators
are always separated so nothing lex-merges, e.g. `-` `-` never becomes `--`).

Typical use: turn a peeled, minified Luraph VM interpreter (one 100 KB line)
into a readable listing.

    python3 beautify_lua.py peeled/stage_0.lua vm_interpreter.lua

Verify equivalence yourself with:

    python3 -c "import sys; sys.path.insert(0,'..'); from luauvmp.lualex import \
tokenize as T; a=[(t.kind,t.val) for t in T(open('peeled/stage_0.lua').read())]; \
b=[(t.kind,t.val) for t in T(open('vm_interpreter.lua').read())]; print(a==b)"
"""
import os
import sys

sys.path.insert(0, os.path.dirname(os.path.dirname(os.path.abspath(__file__))))
from luauvmp.lualex import tokenize  # noqa: E402

INDENT = "  "
OPEN_KW = {"then", "do", "repeat"}      # open a block, matched by end/until
CLOSE_KW = {"end", "until"}             # close a block
REDENT_KW = {"else", "elseif"}          # dedent for the keyword, reindent after
_SEP_KW = {"return", "and", "or", "not", "local", "in", "function", "if",
           "elseif", "while", "for", "until", "else", "then", "do", "repeat"}


def needs_space(prev, cur):
    """True when a space is required between two adjacent tokens, either for
    readability (two identifiers) or, critically, to stop them lex-merging."""
    if prev is None:
        return False
    if prev.kind in ("name", "kw", "num") and cur.kind in ("name", "kw", "num"):
        return True
    # Prevent adjacent operators from lex-merging into a different token:
    #   '-' '-' -> comment,  '[' '[' -> long string,  '=' '=' -> '==', etc.
    if prev.kind == "op" and cur.kind == "op":
        return True
    if prev.kind == "op" and prev.val.endswith("[") and cur.kind == "str" \
            and cur.val.startswith("["):
        return True
    if prev.kind == "op" and prev.val == "-" and cur.kind == "str":
        return True
    if prev.kind == "kw" and prev.val in _SEP_KW:
        return True
    return False


def beautify(src):
    toks = tokenize(src)
    out, line = [], []
    indent = 0
    prev = None
    fn_paren_stack = []
    paren_depth = 0

    def flush():
        if line:
            out.append(INDENT * max(indent, 0) + "".join(line).rstrip())
            line.clear()

    for t in toks:
        # dedent BEFORE emitting closers / re-denters
        if (t.kind == "kw" and t.val in CLOSE_KW) \
                or (t.kind == "kw" and t.val in REDENT_KW) \
                or (t.kind == "op" and t.val == "}"):
            flush()
            indent -= 1

        if needs_space(prev, t) and line:
            line.append(" ")
        line.append(t.val)

        if t.kind == "op" and t.val == "(":
            paren_depth += 1
        elif t.kind == "op" and t.val == ")":
            paren_depth -= 1
            if fn_paren_stack and paren_depth == fn_paren_stack[-1]:
                fn_paren_stack.pop()
                flush()
                indent += 1                       # function body
        elif t.kind == "op" and t.val == "{":
            flush()
            indent += 1
        elif t.kind == "op" and t.val == ";":
            flush()
        elif t.kind == "kw":
            if t.val == "function":
                fn_paren_stack.append(paren_depth)
            elif t.val in OPEN_KW:
                flush()
                indent += 1
            elif t.val == "else":
                flush()
                indent += 1
        prev = t
    flush()
    return "\n".join(out) + "\n"


def main():
    if len(sys.argv) < 2:
        sys.exit("usage: beautify_lua.py <input.lua> [output.lua]")
    src = open(sys.argv[1], "r", encoding="utf-8", errors="replace").read()
    res = beautify(src)
    if len(sys.argv) > 2:
        open(sys.argv[2], "w", encoding="utf-8").write(res)
    else:
        sys.stdout.write(res)
    sys.stderr.write("[beautify] %d bytes -> %d lines\n" % (len(src), res.count("\n")))
    return 0


if __name__ == "__main__":
    sys.exit(main())
