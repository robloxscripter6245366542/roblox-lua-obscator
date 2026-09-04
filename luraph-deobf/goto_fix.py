#!/usr/bin/env python3
"""Mechanically eliminate goto/label from a Lua function body by lowering it
to a flat CFG of basic blocks, then emitting that CFG as a pc-dispatch loop
-- the same technique used to fix luraph-deobf/devirt/lift.py's structured
emitter earlier this session, now applied generically to decompiler output
(GameCodeDumper's goto-based control-flow reconstruction), which likewise
doesn't parse under Luau (no goto statement at all).

Design: tokenize properly (so strings/comments can't be mistaken for
keywords), parse into a block tree (do/while/for/repeat/if/function
nesting), then *lower the whole region* containing any goto/label into one
flat list of basic blocks -- every if/elseif/else and every while/for/repeat
becomes explicit pc-branches in that same flat address space, so a goto can
never be "out of scope" relative to its label (the classic bug in a naive
per-nested-block flattener). Only function literals are never flattened
(goto cannot cross a function boundary in Lua), and any block containing no
goto/label anywhere in its transitive non-function descendants is left as
plain, untouched Lua.
"""
import re


# ---------------------------------------------------------------- tokenizer
TOKEN_RE = re.compile(r"""
    (?P<ws>\s+)
  | (?P<longstr>\[(?P<eq1>=*)\[.*?\](?P=eq1)\])
  | (?P<longcomment>--\[(?P<eq2>=*)\[.*?\](?P=eq2)\])
  | (?P<linecomment>--[^\n]*)
  | (?P<dstr>"(?:\\.|[^"\\])*")
  | (?P<sstr>'(?:\\.|[^'\\])*')
  | (?P<name>[A-Za-z_][A-Za-z0-9_]*)
  | (?P<num>0[xX][0-9a-fA-F.]+|\d+\.?\d*(?:[eE][+-]?\d+)?)
  | (?P<op>::|\.\.\.|\.\.|==|~=|<=|>=|//|[-+*/%^#<>=(){}\[\];:,.])
""", re.VERBOSE | re.DOTALL)

KEYWORDS = {
    "and", "break", "continue", "do", "else", "elseif", "end", "false",
    "for", "function", "goto", "if", "in", "local", "nil", "not", "or",
    "repeat", "return", "then", "true", "until", "while",
}


class Tok:
    __slots__ = ("kind", "text", "pos", "nl_before")
    def __init__(self, kind, text, pos, nl_before=False):
        self.kind = kind; self.text = text; self.pos = pos; self.nl_before = nl_before
    def __repr__(self):
        return f"Tok({self.kind!r},{self.text!r})"


def tokenize(src):
    toks = []
    i, n = 0, len(src)
    pending_nl = False
    while i < n:
        m = TOKEN_RE.match(src, i)
        if not m:
            raise SyntaxError(f"tokenizer stuck at {i}: {src[i:i+40]!r}")
        kind = m.lastgroup
        text = m.group()
        if kind in ("ws", "longcomment", "linecomment"):
            if "\n" in text:
                pending_nl = True
        elif kind == "name":
            toks.append(Tok("kw" if text in KEYWORDS else "name", text, i, pending_nl))
            pending_nl = False
        else:
            toks.append(Tok(kind, text, i, pending_nl))
            pending_nl = False
        i = m.end()
    return toks


def retok_join(toks):
    out = []
    for k, t in enumerate(toks):
        if k > 0:
            prev = toks[k - 1]
            need_space = True
            if prev.kind == "op" and prev.text in ("(", "[", ".", ",", ";", ":", "#", "{"):
                need_space = False
            if t.kind == "op" and t.text in (")", "]", ",", ";", ".", ":"):
                need_space = False
            out.append((" " if need_space else "") + t.text)
        else:
            out.append(t.text)
    return "".join(out)


def _mk_raw(text):
    """A synthetic token standing in for already-rendered text (used for an
    inline function-expression that needed its own recursive goto/label
    fix -- see try_parse_inline_function). retok_join treats it as an
    atomic unit."""
    return Tok("raw", text, -1)


def try_parse_inline_function(toks, i, stmt):
    """toks[i] is a 'function' keyword. If `stmt` (tokens accumulated so
    far in the CURRENT statement) is non-empty and doesn't end in `local`,
    this `function` is in EXPRESSION position (an anonymous closure passed
    as a value -- e.g. `foo(function() ... end)`, `local x = function()
    ... end`), NOT a statement-level `function name(...) ... end` or
    `local function name(...) ... end` declaration. Those are structurally
    different: an expression-position function is embedded inside a larger
    statement whose text continues *after* the function's closing `end`
    (e.g. a `)` closing the call it's an argument to) -- treating it as a
    fresh top-level block item (the old behaviour) orphans that trailing
    text. Parse it as its own function scope (reusing parse_block, which
    already knows how to find a matching `end`), recursively flatten it if
    it has its own internal goto/label, and splice the result back in as
    one atomic raw token so the surrounding expression's tokens (like that
    trailing `)`) stay attached to the same statement.

    Returns (raw_token, next_index) if this was expression-position, else
    None (caller should fall through to normal statement-level handling).
    """
    if not stmt or (stmt[-1].kind == "kw" and stmt[-1].text == "local"):
        return None
    j = i + 1
    hdr = [toks[i]]
    depth = 0
    while j < len(toks):
        hdr.append(toks[j])
        if toks[j].kind == "op" and toks[j].text == "(":
            depth += 1
        elif toks[j].kind == "op" and toks[j].text == ")":
            depth -= 1
            if depth == 0:
                j += 1
                break
        j += 1
    sub, j = parse_block(toks, j, "function", hdr)
    header_text = retok_join(hdr)
    inner = render_block_or_flatten(sub)
    rendered = f"{header_text}\n{indent(inner)}\nend"
    return _mk_raw(rendered), j


# ---------------------------------------------------------------- block tree
OPENERS = {"do", "while", "for", "repeat", "function"}


class Block:
    def __init__(self, opener):
        self.opener = opener
        self.items = []   # ("stmt",[Tok]) | ("block",Block) | ("if",branches) | ("goto",name) | ("label",name)
        self.header = []
        self.trailer = []  # 'until' condition, for repeat


def _collect_header(toks, j, sub_opener):
    hdr = [toks[j - 1]] if False else []
    return hdr


def parse_block(toks, i, opener, header):
    blk = Block(opener)
    blk.header = header
    stmt = []
    nldepth = [0]

    def flush():
        if stmt:
            blk.items.append(("stmt", stmt[:]))
            stmt.clear()

    while i < len(toks):
        t = toks[i]
        if stmt and nldepth[0] == 0 and t.nl_before:
            flush()
        if t.kind == "op" and t.text in ("(", "{", "["):
            nldepth[0] += 1
        elif t.kind == "op" and t.text in (")", "}", "]"):
            nldepth[0] = max(0, nldepth[0] - 1)
        if t.kind == "kw" and t.text == "end" and opener in (OPENERS - {"repeat"}):
            flush()
            return blk, i + 1
        if t.kind == "kw" and t.text == "until" and opener == "repeat":
            flush()
            j = i + 1
            cond = []
            depth = 0
            while j < len(toks):
                tt = toks[j]
                if tt.kind == "kw" and tt.text in ("end",) and depth == 0:
                    break
                cond.append(tt); j += 1
            blk.trailer = cond
            return blk, j
        if t.kind == "kw" and t.text == "function":
            r = try_parse_inline_function(toks, i, stmt)
            if r is not None:
                raw, i = r
                stmt.append(raw)
                continue
        if t.kind == "kw" and t.text in OPENERS:
            flush()
            sub_opener = t.text
            j = i + 1
            hdr = [t]
            if sub_opener == "function":
                depth = 0
                while j < len(toks):
                    hdr.append(toks[j])
                    if toks[j].kind == "op" and toks[j].text == "(":
                        depth += 1
                    elif toks[j].kind == "op" and toks[j].text == ")":
                        depth -= 1
                        if depth == 0:
                            j += 1
                            break
                    j += 1
            elif sub_opener == "repeat":
                pass
            else:
                while j < len(toks) and not (toks[j].kind == "kw" and toks[j].text == "do"):
                    hdr.append(toks[j]); j += 1
                if j < len(toks):
                    hdr.append(toks[j]); j += 1
            sub, j = parse_block(toks, j, sub_opener, hdr)
            blk.items.append(("block", sub))
            i = j
            continue
        if t.kind == "kw" and t.text == "if":
            flush()
            branches, j = parse_if_chain(toks, i)
            blk.items.append(("if", branches))
            i = j
            continue
        if t.kind == "kw" and t.text == "goto":
            flush()
            blk.items.append(("goto", toks[i + 1].text))
            i += 2
            continue
        if t.kind == "op" and t.text == "::":
            flush()
            blk.items.append(("label", toks[i + 1].text))
            i += 3
            continue
        stmt.append(t); i += 1
    flush()
    return blk, i


def parse_if_chain(toks, i):
    branches = []
    i += 1  # skip 'if'
    while True:
        cond = []
        while not (toks[i].kind == "kw" and toks[i].text == "then"):
            cond.append(toks[i]); i += 1
        i += 1
        sub, i = parse_if_body(toks, i)
        branches.append(("if" if not branches else "elseif", cond, sub))
        if toks[i].kind == "kw" and toks[i].text == "elseif":
            i += 1; continue
        elif toks[i].kind == "kw" and toks[i].text == "else":
            i += 1
            sub2, i = parse_if_body(toks, i)
            branches.append(("else", [], sub2))
            return branches, i + 1  # skip 'end'
        elif toks[i].kind == "kw" and toks[i].text == "end":
            return branches, i + 1
        else:
            raise SyntaxError(f"unexpected token in if-chain at {i}: {toks[i]}")


def parse_if_body(toks, i):
    blk = Block("then")
    stmt = []
    nldepth = [0]

    def flush():
        if stmt:
            blk.items.append(("stmt", stmt[:]))
            stmt.clear()

    while True:
        t = toks[i]
        if stmt and nldepth[0] == 0 and t.nl_before:
            flush()
        if t.kind == "op" and t.text in ("(", "{", "["):
            nldepth[0] += 1
        elif t.kind == "op" and t.text in (")", "}", "]"):
            nldepth[0] = max(0, nldepth[0] - 1)
        if t.kind == "kw" and t.text in ("elseif", "else", "end"):
            flush()
            return blk, i
        if t.kind == "kw" and t.text == "function":
            r = try_parse_inline_function(toks, i, stmt)
            if r is not None:
                raw, i = r
                stmt.append(raw)
                continue
        if t.kind == "kw" and t.text in OPENERS:
            flush()
            sub_opener = t.text
            j = i + 1
            hdr = [t]
            if sub_opener == "function":
                depth = 0
                while j < len(toks):
                    hdr.append(toks[j])
                    if toks[j].kind == "op" and toks[j].text == "(":
                        depth += 1
                    elif toks[j].kind == "op" and toks[j].text == ")":
                        depth -= 1
                        if depth == 0:
                            j += 1; break
                    j += 1
            elif sub_opener == "repeat":
                pass
            else:
                while j < len(toks) and not (toks[j].kind == "kw" and toks[j].text == "do"):
                    hdr.append(toks[j]); j += 1
                if j < len(toks):
                    hdr.append(toks[j]); j += 1
            sub, j = parse_block(toks, j, sub_opener, hdr)
            blk.items.append(("block", sub))
            i = j; continue
        if t.kind == "kw" and t.text == "if":
            flush()
            branches, j = parse_if_chain(toks, i)
            blk.items.append(("if", branches))
            i = j; continue
        if t.kind == "kw" and t.text == "goto":
            flush()
            blk.items.append(("goto", toks[i + 1].text))
            i += 2; continue
        if t.kind == "op" and t.text == "::":
            flush()
            blk.items.append(("label", toks[i + 1].text))
            i += 3; continue
        stmt.append(t); i += 1




def collect_local_names(item):
    """Collect every name introduced by a `local` statement anywhere in
    `item`'s transitive non-function descendants (so they can be hoisted
    out of the per-pc-state elseif branches, which are separate Lua scopes
    -- a `local` declared inside one branch is NOT visible in another)."""
    names = []
    def walk(it):
        if isinstance(it, Block):
            for x in it.items:
                walk(x)
            return
        kind = it[0]
        if kind == "stmt":
            toks = it[1]
            if toks and toks[0].kind == "kw" and toks[0].text == "local":
                j = 1
                while j < len(toks):
                    if toks[j].kind == "name":
                        names.append(toks[j].text)
                    j += 1
                    if j < len(toks) and toks[j].kind == "op" and toks[j].text == ",":
                        j += 1
                        continue
                    break
        elif kind == "block":
            sub = it[1]
            if sub.opener != "function":
                walk(sub)
        elif kind == "if":
            for _, _, sub in it[1]:
                walk(sub)
    walk(item)
    return names


def strip_local_keyword(toks):
    """`local a, b = x, y` -> `a, b = x, y`; bare `local a, b` (no
    initializer, names already hoisted to nil) -> None (statement dropped,
    nothing to do at this point in the flat CFG)."""
    if not (toks and toks[0].kind == "kw" and toks[0].text == "local"):
        return toks
    rest = toks[1:]
    has_init = any(t.kind == "op" and t.text == "=" for t in rest)
    if not has_init:
        return None
    return rest

# ------------------------------------------------------- goto/label scanning
def contains_goto_or_label(item):
    """True if `item` (a block-item tuple, or a Block) has a goto/label
    anywhere in its transitive descendants, NOT crossing into nested
    function literals (goto can't cross a function boundary in Lua)."""
    if isinstance(item, Block):
        return any(contains_goto_or_label(it) for it in item.items)
    kind = item[0]
    if kind in ("goto", "label"):
        return True
    if kind == "block":
        sub = item[1]
        if sub.opener == "function":
            return False  # separate scope; goto there is handled independently
        return contains_goto_or_label(sub)
    if kind == "if":
        return any(contains_goto_or_label(sub) for _, _, sub in item[1])
    return False


# --------------------------------------------------------------- CFG lowering
class BB:
    """One basic block: an id, a list of plain statement strings, and a
    terminator describing how control leaves it."""
    __slots__ = ("id", "stmts", "term")
    def __init__(self, id_):
        self.id = id_
        self.stmts = []
        self.term = None  # ('goto', target_id) | ('cond', cond_text, then_id, else_id) | ('return',) | ('exit',)


class CFGBuilder:
    def __init__(self):
        self.blocks = {}
        self.next_id = 1
        self.label_ids = {}   # user label name -> block id (allocated lazily, on first reference or definition)

    def new_id(self):
        i = self.next_id; self.next_id += 1
        return i

    def new_block(self):
        i = self.new_id()
        bb = BB(i)
        self.blocks[i] = bb
        return bb

    def label_id(self, name):
        if name not in self.label_ids:
            self.label_ids[name] = self.new_id()
        return self.label_ids[name]

    def lower_block(self, block, entry, fallthrough, break_target):
        """Lower `block`'s items into the CFG, starting at basic block
        `entry` (already created, empty). `fallthrough`: id to jump to if
        control reaches the end of this block normally. `break_target`: id
        a bare `break` should jump to (id of "after the innermost loop"),
        or None if not inside a loop being lowered here."""
        cur = entry
        n = len(block.items)
        for idx, it in enumerate(block.items):
            kind = it[0]
            if kind == "label":
                target = self.blocks[self.label_id(it[1])] if self.label_id(it[1]) in self.blocks else None
                lid = self.label_id(it[1])
                if lid not in self.blocks:
                    self.blocks[lid] = BB(lid)
                nb = self.blocks[lid]
                cur.term = ("goto", nb.id)
                cur = nb
            elif kind == "goto":
                cur.term = ("goto", self.label_id(it[1]))
                cur = self.new_block()  # unreachable tail; keeps invariants simple
            elif kind == "stmt":
                toks = it[1]
                if toks and toks[0].kind == "kw" and toks[0].text == "break":
                    if break_target is None:
                        raise ValueError("break outside of a lowered loop")
                    cur.term = ("goto", break_target)
                    cur = self.new_block()
                    continue
                if toks and toks[0].kind == "kw" and toks[0].text == "continue":
                    # Luau's native `continue` -- jumps to the end of the
                    # current loop iteration, i.e. exactly `fallthrough`
                    # (for a `for` loop, lower_for already points body's
                    # fallthrough at the increment block, not straight to
                    # `top`, so this correctly still increments).
                    cur.term = ("goto", fallthrough)
                    cur = self.new_block()
                    continue
                if toks and toks[0].kind == "kw" and toks[0].text == "return":
                    text = retok_join(toks)
                    cur.stmts.append(text)
                    cur.term = ("return",)
                    cur = self.new_block()
                    continue
                stripped = strip_local_keyword(toks)
                if stripped is None:
                    continue  # bare `local name[, name2]` with no initializer -- already hoisted to nil
                text = retok_join(stripped)
                if not text.strip():
                    continue
                cur.stmts.append(text)
            elif kind == "if":
                cur = self.lower_if(it[1], cur, fallthrough, break_target)
            elif kind == "block":
                cur = self.lower_nested(it[1], cur, fallthrough, break_target)
            else:
                raise ValueError(f"bad item kind {kind}")
        if cur.term is None:
            cur.term = ("goto", fallthrough)
        return cur

    def lower_if(self, branches, entry, fallthrough, break_target):
        """branches: [(kind, cond_tokens, Block), ...]. Emits a chain of
        conditional basic blocks; every arm rejoins at a fresh `after` id."""
        after = self.new_block()
        cur = entry
        has_else = branches[-1][0] == "else"
        for i, (kind, cond, sub) in enumerate(branches):
            is_last = (i == len(branches) - 1)
            then_bb = self.new_block()
            if kind == "else":
                cur.term = ("goto", then_bb.id)
                tail = self.lower_block(sub, then_bb, after.id, break_target)
                if tail.term is None:
                    tail.term = ("goto", after.id)
                break
            cond_text = retok_join(cond)
            if is_last and not has_else:
                else_bb = after
            else:
                else_bb = self.new_block()
            cur.term = ("cond", cond_text, then_bb.id, else_bb.id)
            tail = self.lower_block(sub, then_bb, after.id, break_target)
            if tail.term is None:
                tail.term = ("goto", after.id)
            cur = else_bb
            if is_last and not has_else:
                break
        return after

    @staticmethod
    def split_commas(toks):
        """Split a token list on top-level commas (respecting bracket depth)."""
        parts, cur, depth = [], [], 0
        for t in toks:
            if t.kind == "op" and t.text in ("(", "{", "["):
                depth += 1
            elif t.kind == "op" and t.text in (")", "}", "]"):
                depth -= 1
            if depth == 0 and t.kind == "op" and t.text == ",":
                parts.append(cur); cur = []
            else:
                cur.append(t)
        parts.append(cur)
        return parts

    def lower_for(self, clause_toks, sub, entry):
        """Desugar `for <clause> do BODY end` (numeric or generic) into
        Lua's own equivalent (Lua manual 3.3.5: numeric for evaluates its
        three control expressions once, then loops while the variable is
        in range, stepping after each iteration; generic for evaluates the
        iterator triple once, then loops calling it until the first result
        is nil), expressed with the same top/body/after CFG shape as a
        `while` loop -- so it flows through the exact same flattening this
        lowering already does for `while`."""
        depth = 0
        eq_pos = in_pos = None
        for idx, t in enumerate(clause_toks):
            if t.kind == "op" and t.text in ("(", "{", "["):
                depth += 1
            elif t.kind == "op" and t.text in (")", "}", "]"):
                depth -= 1
            elif depth == 0 and t.kind == "op" and t.text == "=" and eq_pos is None and in_pos is None:
                eq_pos = idx
            elif depth == 0 and t.kind == "kw" and t.text == "in" and in_pos is None:
                in_pos = idx

        uid = self.new_id()
        top = self.new_block()
        body = self.new_block()
        after = self.new_block()

        if in_pos is not None:
            names = [retok_join(p) for p in self.split_commas(clause_toks[:in_pos])]
            explist = retok_join(clause_toks[in_pos + 1:])
            f, s, v = f"__forf{uid}", f"__fors{uid}", f"__forv{uid}"
            entry.stmts.append(f"local {f}, {s}, {v} = {explist}")
            entry.term = ("goto", top.id)
            top.stmts.append(f"local {', '.join(names)} = {f}({s}, {v})")
            top.term = ("cond", f"{names[0]} == nil", after.id, body.id)
            body.stmts.append(f"{v} = {names[0]}")
            tail = self.lower_block(sub, body, top.id, after.id)
            if tail.term is None:
                tail.term = ("goto", top.id)
            return after

        if eq_pos is not None:
            var = retok_join(clause_toks[:eq_pos])
            rest = self.split_commas(clause_toks[eq_pos + 1:])
            start = retok_join(rest[0])
            stop = retok_join(rest[1])
            step = retok_join(rest[2]) if len(rest) > 2 else "1"
            st, sp = f"__forstop{uid}", f"__forstep{uid}"
            entry.stmts.append(f"local {var} = {start}")
            entry.stmts.append(f"local {st} = {stop}")
            entry.stmts.append(f"local {sp} = {step}")
            entry.term = ("goto", top.id)
            cond = f"(({sp} > 0 and {var} <= {st}) or ({sp} <= 0 and {var} >= {st}))"
            top.term = ("cond", cond, body.id, after.id)
            incr = self.new_block()
            incr.stmts.append(f"{var} = {var} + {sp}")
            incr.term = ("goto", top.id)
            tail = self.lower_block(sub, body, incr.id, after.id)
            if tail.term is None:
                tail.term = ("goto", incr.id)
            return after

        raise ValueError("malformed for-loop clause (no top-level '=' or 'in')")

    def lower_nested(self, sub, entry, fallthrough, break_target):
        opener = sub.opener
        if opener == "function":
            # goto cannot cross a function boundary, so this closure is its
            # own independent scope for flattening purposes -- but it may
            # still contain its OWN internal goto/label (a nested closure
            # can itself be/contain the real VM dispatch loop). Recurse:
            # check and flatten *this* function's body on its own terms,
            # exactly as fix_function_body does for the outermost function.
            header = retok_join(sub.header)
            inner = render_block_or_flatten(sub)
            entry.stmts.append(f"{header}\n{indent(inner)}\nend")
            return entry
        if opener == "do":
            after = self.new_block()
            body = self.new_block()
            entry.term = ("goto", body.id)
            tail = self.lower_block(sub, body, after.id, break_target)
            if tail.term is None:
                tail.term = ("goto", after.id)
            return after
        if opener == "while":
            cond_toks = sub.header[1:-1]  # strip 'while' ... 'do'
            cond_text = retok_join(cond_toks)
            top = self.new_block()
            body = self.new_block()
            after = self.new_block()
            entry.term = ("goto", top.id)
            top.term = ("cond", cond_text, body.id, after.id)
            tail = self.lower_block(sub, body, top.id, after.id)
            if tail.term is None:
                tail.term = ("goto", top.id)
            return after
        if opener == "repeat":
            top = self.new_block()
            after = self.new_block()
            entry.term = ("goto", top.id)
            cond_text = retok_join(sub.trailer)
            tail = self.lower_block(sub, top, None, after.id)  # fallthrough patched below
            # 'until cond': loop back to top unless cond true
            check = self.new_block()
            if tail.term is None:
                tail.term = ("goto", check.id)
            else:
                # tail already terminated (e.g. via goto/return); the
                # 'until' check only applies to the natural fallthrough
                # path, so give lower_block the check block as fallthrough
                # instead of patching after the fact.
                pass
            check.term = ("cond", cond_text, after.id, top.id)
            return after
        if opener == "for":
            # A `for` loop's own iteration/exit can't be re-expressed as a
            # plain pc-goto while staying a real Lua `for`, so -- exactly
            # like `while` above -- desugar it to Lua's own defined
            # semantics (Lua manual 3.3.5) using ordinary locals + a
            # `while`-shaped CFG, which the rest of this lowering already
            # knows how to flatten.
            clause = sub.header[1:-1]  # strip 'for' ... 'do'
            return self.lower_for(clause, sub, entry)
        raise ValueError(f"unhandled nested opener {opener!r}")


def render_verbatim_block(block):
    # `contains_goto_or_label` deliberately doesn't count a nested function
    # literal's internals against its *parent* block -- but that means a
    # goto/label-free parent can still contain a nested function that has
    # its own internal goto/label needing its own independent flattening.
    # Route through render_block_or_flatten (not render_plain directly) so
    # that recursion happens no matter how deep the nesting.
    header = retok_join(block.header)
    inner = render_block_or_flatten(block)
    if block.opener == "repeat":
        return f"repeat\n{indent(inner)}\nuntil {retok_join(block.trailer)}"
    return f"{header}\n{indent(inner)}\nend"


def render_plain(block):
    out = []
    for it in block.items:
        kind = it[0]
        if kind == "stmt":
            text = retok_join(it[1])
            if text.strip():
                out.append(text)
        elif kind == "block":
            out.append(render_verbatim_block(it[1]))
        elif kind == "if":
            out.append(render_if_plain(it[1]))
        else:
            raise ValueError("render_plain hit goto/label -- caller should have flattened")
    return "\n".join(out)


def render_if_plain(branches):
    out = []
    for i, (kind, cond, sub) in enumerate(branches):
        if kind == "if":
            out.append(f"if {retok_join(cond)} then")
        elif kind == "elseif":
            out.append(f"elseif {retok_join(cond)} then")
        else:
            out.append("else")
        out.append(indent(render_plain(sub)))
    out.append("end")
    return "\n".join(out)


def indent(text, n=1):
    pad = "  " * n
    return "\n".join(pad + l if l else l for l in text.split("\n"))


PC_VAR = "__pc"


def _emit_block_body(bb, indent_n):
    pad = "  " * indent_n
    lines = []
    for s in bb.stmts:
        for sl in s.split("\n"):
            lines.append(pad + sl)
    term = bb.term
    if term is None:
        lines.append(pad + "break")
    elif term[0] == "goto":
        lines.append(f"{pad}{PC_VAR} = {term[1]}")
    elif term[0] == "return":
        pass  # 'return ...' statement already appended above
    elif term[0] == "exit":
        lines.append(pad + "break")
    elif term[0] == "cond":
        _, cond_text, then_id, else_id = term
        lines.append(f"{pad}if {cond_text} then {PC_VAR} = {then_id} else {PC_VAR} = {else_id} end")
    else:
        raise ValueError(f"bad terminator {term}")
    return lines


def _emit_dispatch_tree(cfg, ids, indent_n):
    """Balanced binary search over sorted pc ids, not a linear if/elseif
    chain -- Luau's parser has a fixed expression/statement recursion
    limit, and a real-world VM dispatch loop can easily have 1000+ states
    (l1 in the CameraController sample has 1147), which blows a linear
    chain's O(N) nesting depth. Binary search keeps it O(log N): ~11
    levels for 1147 states, well within any reasonable limit, with
    identical semantics (still one flat function body, so `return`
    continues to return from the real enclosing function -- no closures,
    no trampoline needed)."""
    pad = "  " * indent_n
    if len(ids) == 1:
        bid = ids[0]
        lines = [f"{pad}if {PC_VAR} == {bid} then"]
        lines += _emit_block_body(cfg.blocks[bid], indent_n + 1)
        lines.append(f"{pad}else")
        lines.append(f"{pad}  break")
        lines.append(f"{pad}end")
        return lines
    mid = len(ids) // 2
    left, right = ids[:mid], ids[mid:]
    pivot = right[0]
    lines = [f"{pad}if {PC_VAR} < {pivot} then"]
    lines += _emit_dispatch_tree(cfg, left, indent_n + 1)
    lines.append(f"{pad}else")
    lines += _emit_dispatch_tree(cfg, right, indent_n + 1)
    lines.append(f"{pad}end")
    return lines


def emit_dispatch(cfg, entry_id):
    lines = [f"local {PC_VAR} = {entry_id}", "while true do"]
    ids = sorted(cfg.blocks.keys())
    lines += _emit_dispatch_tree(cfg, ids, 1)
    lines.append("end")
    return "\n".join(lines)


def flatten_region(block):
    """block: the smallest Block we've chosen to fully flatten (it and all
    its transitive non-function descendants become one flat CFG). Returns
    Lua source text for the pc-dispatch loop implementing it exactly.

    Every `local` declared anywhere inside is hoisted to one shared
    declaration before the loop -- each pc-state's `elseif` arm is its own
    Lua scope, so a `local` re-declared inside one arm would NOT be visible
    from another, silently turning later reads into nil. Hoisting (and
    reducing every in-place `local X = ...` to a plain assignment) is what
    makes the state machine's variables actually persist across states,
    matching what a real register/upvalue slot in the original bytecode
    would do.
    """
    names = []
    seen = set()
    for n in collect_local_names(block):
        if n not in seen:
            seen.add(n); names.append(n)

    cfg = CFGBuilder()
    entry = cfg.new_block()
    exit_bb = cfg.new_block()
    exit_bb.term = ("exit",)
    tail = cfg.lower_block(block, entry, exit_bb.id, break_target=None)
    if tail.term is None:
        tail.term = ("goto", exit_bb.id)
    body = emit_dispatch(cfg, entry.id)
    if names:
        return f"local {', '.join(names)}\n{body}"
    return body


def render_block_or_flatten(block):
    if contains_goto_or_label(block):
        return flatten_region(block)
    return render_plain(block)


def fix_function_body(src_body):
    toks = tokenize(src_body)
    top, i = parse_block(toks, 0, "do", [])
    assert i == len(toks), f"did not consume all tokens ({i}/{len(toks)})"
    return render_block_or_flatten(top)


def main():
    import argparse
    ap = argparse.ArgumentParser(
        description="Eliminate goto/label from a Lua/Luau source file "
                     "(e.g. GameCodeDumper decompiler output) by lowering "
                     "any region that uses them to a pc-dispatch loop.")
    ap.add_argument("infile")
    ap.add_argument("-o", "--out", help="output path (default: stdout)")
    args = ap.parse_args()
    with open(args.infile, "r", encoding="utf-8", errors="replace") as f:
        src = f.read()
    fixed = fix_function_body(src)
    if args.out:
        with open(args.out, "w", encoding="utf-8") as f:
            f.write(fixed)
    else:
        print(fixed)
    return 0


if __name__ == "__main__":
    import sys
    sys.exit(main())
