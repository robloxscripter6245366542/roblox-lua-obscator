# Second real-world Luraph v15.0 sample — `xv3gasx/Murder-Mystery-2/Release.lua`

Source: `https://raw.githubusercontent.com/xv3gasx/Murder-Mystery-2/refs/heads/main/Release.lua`
(public GitHub repo, fetched for analysis; the raw file itself is not vendored
into this repo — someone else's protected script, cited by URL instead, same
as any other third-party sample referenced but not redistributed here).

## Why this sample

`v15.md`'s "Portability across samples" section flagged an open question:
every tool in `devirt/` (`v15_payload_probe.py`, `v15_payload_opcodes.py`,
`v15_payload_dump_arrays.py`, `v15_payload_lift.py`) had only ever been run
against `sample_v15.lua` — a design claim verified by code inspection (no
hardcoded names/values), never by testing against a second real Luraph v15
sample, because none was available. This file is that second sample: its own
header states `-- This file was protected using Luraph Obfuscator v15.0
[https://lura.ph/]`, the same major version as `sample_v15.lua`.

(A third candidate, an obfuscated Lua "SDK" library from `jnkie.com`, was
also checked and ruled **out** — see the "Not Luraph: jnkie.com/sdk/library.lua"
section below. Useful as a negative control: it shares surface-level
obfuscation tricks but not Luraph's actual architecture.)

## Result: same version label, genuinely different codegen shape

`devirt/v15_payload_probe.py`'s `find_vm_groups` — which looks for the
specific shape `while true do local <M>=<ARR>[<PC>];` that `sample_v15.lua`'s
real payload VM uses — finds **zero** candidates in this file. Not a
detection failure: this sample's actual dispatch loop uses a different shape
entirely (see below). "Luraph v15.0" is not one fixed code-generation
template.

Structurally, at a glance:

| | `sample_v15.lua` | this sample |
|---|---|---|
| Size | ~300KB+ | 1,171,987 bytes |
| Shape | 145 sequential `NAME=function()...end` handlers feeding a shared multi-mode register-VM | Returns one `setmetatable({...}, {}):j()(...)` call; the big table mixes numeric-keyed builtin references (`[73]=buffer.tostring`, `[125]=buffer.readu8`, `[22]=table.move`, `[20]=pcall`, ...) with a handful of named-key entries |
| Encoded payload | Spread across the 145 handlers as literal Lua source | 2 large `[==[LPH...]==]` long-bracket string blobs, making up almost the entire file |
| Real dispatch loops found | 2 (`w`: the payload VM, 4 modes; `Q`: dead code, see `v15.md`) | 1 (see below) |

## The real dispatch loop: comparison-chain, not array-fetch

`devirt/chain_dispatch_probe.py` (new tool, this investigation) generically
detects a **second** Luraph dispatch shape:
`while true do if <B><cmp><const> then ... end` — a pre-set state variable
compared via a binary-search-style `if/elseif` chain and reassigned inside
each branch, rather than an opcode fetched from an array each iteration.

This sample has exactly one real instance of that shape: variable `B`,
richness 16, at the only meaningful `while true do` in the whole file (the
file's other two `while`-shaped constructs are noise: one is a bare
assignment loop, the other is a single `if f(z)==0 then...` flag-check with
no dispatch chain at all — confirmed via AST, not text proximity, after an
earlier text-based span-finder broke on Luau's `if...then...else`
*expression* syntax, which never closes with `end` and defeats naive
keyword-depth counting the same way it did once already in `v15.md`'s Q-VM
investigation).

`devirt/v15_payload_opcodes.py`'s AST-based leaf classification
(`walk_dispatch`/`classify_leaf`/`unwrap`) works on this loop **completely
unchanged** — passing `pc_var=m_var='B'` straight in, since that code only
needs an `m_var` name and an `AstStatIf` node, never the array-fetch shape.
Result: **17 opcode branches, 16 `JUMP`-classified + 1 `RETURN`.**

## Dynamic probing: real, bounded work — then silence downstream

Injecting a one-shot-per-value probe at the top of this loop (same
low-overhead technique as `v15_payload_watch.py`) and running it through the
existing `dynamic/deobf_v15.py` harness unmodified:

- **All 17 opcodes fire** within the first ~1,166,422 loop iterations.
- Run at two depths — 30s and the full 300s (10x) budget — both produced
  **byte-for-byte identical output**: same last line, same iteration count,
  zero new opcodes or progress checkpoints in the extra 4.5 minutes. Same
  depth-independence signature `v15.md` established for `sample_v15.lua`'s
  payload VM, obtained the same way (compare two very different depths,
  check for drift).
- Unlike `sample_v15.lua`'s hot loop, **this one isn't stuck** — opcode
  `B=10` (the `RETURN` branch) is the *last* one to fire, meaning the loop
  completes normally. Confirmed by directly intercepting the entry point
  (`setmetatable(...):j()(...)` rewritten to capture `j()`'s return value
  before calling it): it returns a value of type `function`.

So the actual behavior: `j(self)` runs this 17-opcode loop to completion and
hands back a function. That function then gets called with the script's own
arguments — **and that call is where all further observable output stops.**
No `[[URL]]`/`[[SERVICE]]`/`[[REMOTE]]`/etc. tags fire in the tested window,
same silent signature as `sample_v15.lua` post-setup.

**Correction to an earlier claim in this file:** an initial literal-text
grep for `loadstring(` found zero hits and this section originally
concluded there was no `loadstring`/`load` anywhere in the file, ruling out
a native-bytecode-loader theory. That was wrong — the grep only checks for
`loadstring` spelled out as a bare call expression. Luraph never writes it
that way: `loadstring` is reference **99** in the file's big constant-pool
table (`[99]=loadstring`), destructured into a local also confusingly named
`j` (shadowing the outer `j()` function's own name) alongside `pcall`
(`[20]`, local `h`) and `buffer.tostring` (`[73]`, local `L`). The actual
call site, found via AST + regex over `j()`'s body:

```
else local D,g,Q=t[2],e(J,W,170974),e(J,S,885685);
local J,A=h(j,L(g),"Luraph",nil);
if J then B,t,s,F,W,S=3,D,A,Q,A,K;else B,t,s,F,W,S=3,D,J,Q,A,K;end;
```

— which, substituting the aliases, is `pcall(loadstring, buffer.tostring(g),
"Luraph", nil)`. `g` here is a **local** `g` from the line just before
(shadowing yet another `g` — position 91 in the same destructuring, which is
`buffer.readu32`; the false lead this shadow could have caused is exactly
the kind of trap `v15.md`'s Q-VM investigation and this file's own
comparison-chain span-finder bug already ran into twice). `e` is `J.Z`, one
of the file's static closures, called as `e(J, W, 170974)` /
`e(J, S, 885685)` — a base64/bit-unpacking decoder (its own locals are
initialized to `4,6,64,4,14,4,16,3,3,8,8,8,256,2,32,2048`, classic
alphabet-size/bit-width constants) that unpacks a slice of the file's two
`[==[LPH...]==]` blobs into a Luau `buffer`, sized by the literal byte
counts `170974` / `885685` passed in.

**Dynamically confirmed** by instrumenting this exact call site (probe
prints `buffer.len(g)` and a short `buffer.tostring(g)` prefix immediately
after `g` is decoded, before the `loadstring` call runs):

```
[[GLEN]] ok=true len=170974
[[GTS]] ok2=true
[[GHEAD]] 1 return setmetatable({JP=functi
[[GHEAD]] 31 on(t,r,D,J,L,b,p,o,M,H,i,u,q,K
[[GHEAD]] 61 ,A,l)if J<=127 then if J<=126 
[[GHEAD]] 91 then local N,_,I=L-128,(q-128)
```

`buffer.len(g)` is exactly `170974`, matching the literal byte count in the
source — and `buffer.tostring(g)` is **plain Lua source text**, not
bytecode: `return setmetatable({JP=function(...)if J<=127 then if J<=126
then...`. So the real pipeline is: decode an `[==[LPH...]==]` blob with the
file's own bit-unpacker → a 170,974-byte Lua **source string** →
`loadstring(source, "Luraph", nil)` (wrapped in `pcall`, hence the
`if J then ... else ... end` success/failure branch) → the compiled
function is what `j()` returns and what gets called next. This is a genuine
native-bytecode-loader pattern after all — just one layer of indirection
too deep for a literal-text search to find, exactly the same lesson this
whole investigation keeps relearning about trusting text over structure.

It also explains why every static/dynamic probe on the *outer* file goes
silent past this point: **the second stage doesn't exist anywhere in the
original file's parse tree.** It is synthesized at runtime from decoded
bytes, so no amount of AST analysis or instrumentation of the outer
99% of `Release.lua`'s bytes can ever see it — only intercepting the
`loadstring` call itself (as done here) reaches it.

And the decoded string's own opening line — `if J<=127 then if J<=126
then...` — is visibly a **third instance of the comparison-chain dispatch
shape** (after this file's own outer `B` loop and `sample_v15.lua`'s 4
bonus sub-VMs): Luraph nests a whole second VM layer inside the
dynamically-compiled chunk, using the same codegen idiom recursively. That
inner VM is the real payload interpreter; everything analyzed in this file
so far (the outer `B`-loop, `j()`, the whole 1.17MB static file) is outer
scaffolding whose entire job is decoding and loading it. (Only the
`setmetatable({JP=function(...)...` scaffolding line is quoted above, to
show the shape — not vendoring any of the decoded 170,974-byte payload
itself, same policy as not vendoring the outer sample.)

## The third VM layer: a full constant-pool+handler architecture, and why it's silent

The decoded 170,974-byte string isn't one function — its opening
`if J<=127 then...` is just the first of ~183 `=function(...)` entries and
402 `[N]=` numeric keys in one big table literal, dumped in full with a new
tool (`devirt/loadstring_alias_dump.py --full-dump-arg`, below) and
confirmed byte-exact (reassembled length matches the runtime-observed
`#g==170974` exactly). That table is Luraph's familiar
constant-pool-plus-handler-table shape all over again, one layer deeper,
with a real named entry point:

```
z8=function(t,...)local r,D,J,L,b,p,o,M,H,i,u,q=t:Kv();local K,A,l,...=D,J,t[29](...),...
```

`t:Kv()` is a **static initializer** — `Kv=function(t)return true,9,nil,nil,...,nil;end`,
literally hardcoded, not derived from anything — and `t[29]` is `table.pack`.
So `z8` starts its own register-machine state from a fixed constant and
packs `z8`'s **own call arguments** (`...`) into its first working table.
Running the dumped chunk through the same sandbox (`dynamic/deobf_v15.py`,
directly — it's now a standalone valid Lua file) gets past `env-ready` and
into `z8`, then crashes:

```
[[LOG]] RUNTIME	dropkick:1: invalid argument #1 to 'readu8' (buffer expected, got nil)
dropkick:1 function Rv
dropkick:1 function z8
```

Traced concretely, not guessed: `z8` is called as `s(...)` from the outer
file's own `B`-loop (the `setmetatable({...},{}):j()(...)` entry point —
call `j()`, which runs to completion and returns this compiled chunk as a
function, then immediately call *that* with the original script's own
varargs). A bare `loadstring(url)()`-style invocation — exactly the
one-liner this whole sample was fetched from — passes **zero** arguments at
that outermost call, so `t[29](...)` (`table.pack()`) packs an empty
argument list, and by the time that empty result reaches `Rv`'s
`buffer.readu8`, there's no buffer to read. This is a concrete, traced
instance of the same wall every sample in this file has hit: **the real
work needs an input this sandbox (or a bare `loadstring(...)()` call) never
supplies.** Here it's not vague "needs a live client" — it's specifically
"needs a real first call argument," letting us name the exact missing
value for the first time instead of just observing silence.

`chain_dispatch_probe.py`'s regex was hardcoded to `while true do` (Luraph
was assumed to always exit a dispatch loop via `return`, never by
falsifying the loop condition) — but `z8`'s real loop is
`while r do if K<=16 then...`, a plain **variable** as the loop condition.
Broadened the regex to `while \w+ do` (still requires the same richness
filter, so incidental `while x do if y<=n then` snippets aren't
suddenly treated as VMs) and re-validated against every sample already on
file — no change to `sample_v15.lua`'s outer `B`/`F`/`j`/`L` group, MM2's
outer `B` group, or `jnkie`'s `j` group, confirming no regression — and it
now also finds `z8`'s loop (`K`, richness 9) plus **two more** comparison-chain
loops inside this same inner table (`G`, richness 69, `while o do if
G<=118...`; `_`, richness 62, `while L do if _<=162...`), each with a much
larger opcode range than `z8`'s own. This one decoded chunk contains at
least three distinct comparison-chain dispatch loops, not one — consistent
with ~183 handler functions being too many for a single flat dispatch.

**Cross-sample bonus, found while validating the regex broadening:** the
same `while <var> do if <var2><=N> then...` shape, with the exact same
`t:METHOD(...)` self-referential method-call convention (`t:Ev(...)`,
`t:aP(...)`, `t:r(...)`) as `z8`'s handlers, also exists **directly in
`sample_v15.lua`'s own top-level source** — three more comparison-chain
loops (`c`, richness 45; `d`, richness 69; `S`, richness 13) beyond the 4
already flagged in the "bonus finding" section below, each confirmed via
AST (an `AstStatWhile` node sits at that exact offset, so this is real
parsed code, not text inside a string literal). `sample_v15.lua` never goes
through a
`loadstring`-decode step at all (confirmed: no `loadstring`/`load` value-site
found by `loadstring_alias_dump.py`), so this means the *same* self-referential,
method-dispatching comparison-chain sub-VM architecture that MM2 only
reaches by decoding a runtime string is, in `sample_v15.lua`, simply
written directly into the file. That's real evidence this is a shared
Luraph sub-VM template reused across builds regardless of how the
outer file chooses to deliver it (inline vs. decode-at-runtime) — the
single most generalizable finding of this investigation so far.

**The full opcode-to-handler map for this VM, built and verified.**
`v15_payload_opcodes.py`'s `walk_dispatch`/`classify_leaf` were already
proven (above) to work unchanged on a comparison-chain loop given just an
`m_var` name and the dispatch `AstStatIf` node — tied to a real CLI now,
`devirt/chain_opcode_semantics.py`, and run against `K`, `G`, and `_`.
First pass classified **every single branch as a bare, call-less JUMP** —
wrong, and caught before being trusted: `collect_calls` only ever recognized
calls to a **global**-indexed function (`buffer.readu8`), never a
**local**-indexed one, so it completely missed this VM's entire
`t:METHOD(...)` self-referential dispatch style (confirmed via a minimal
repro against `luau-ast`'s own JSON: a method call is `AstExprCall` with
`func.type=="AstExprIndexName"`, `func.op==":"`, and `func.expr.type`
being `AstExprLocal`, not `AstExprGlobal` — the one case the original
function didn't branch on). Fixed by extending `collect_calls` to also
capture local-indexed/method calls, re-validated with zero regressions
against every category already recorded for `sample_v15.lua`'s 4-mode
payload VM (305 opcodes total, byte-identical classification before and
after) and MM2's own outer `B` loop (still 17/16+1) before trusting the
new result.

With that fix: **164 opcode ranges across the three loops resolve to 165
distinct handler names, zero overlap** — `devirt/mm2_inner_opcode_map.md`
has the full table. That's very likely the *entire* dispatch surface of
this VM (~183 handler functions total, minus `z8` itself, the static
`Kv` initializer, and a handful of numeric-keyed library aliases like
`[110]=Vector2.new` that handler bodies reference directly rather than
being dispatched to by opcode). So while no individual handler's own
computation has been decoded yet, the **shape** of this whole VM — how
many opcodes it has and which named function serves each — is now fully
mapped, not just sampled.

## Tooling added (loadstring full-content dump)

`devirt/loadstring_alias_dump.py` gained `--full-dump-arg N --full-dump-out
FILE`: instead of the short, bounded preview described above, it chunks one
whole argument (past `dynamic/deobf_v15.py`'s 120-char-per-print
truncation) and reassembles it in Python with a real Lua `%q` unescaper
(`lua_q_unescape` — the existing array-dump tools' bare `rstrip('"')` is
fine for a human-eyeballed preview but would silently corrupt any escaped
byte in a byte-exact reconstruction). Verified byte-exact on this sample:
1900/1900 chunks captured, reassembled length matches the runtime-reported
`#g` exactly, and the result parses cleanly with `luau-ast`. (First version
of the probe had a scoping bug — the full-dump code referenced `local
__ty` from a block that had already closed, so it silently read back a nil
global instead of erroring; fixed by nesting it inside the same `if
__ok_idx then` block.) The dumped 170,974-byte chunk itself is **not**
vendored anywhere (same policy as the outer sample) — it lives only in a
local scratch directory, cited here by finding, not by content.

## What individual handlers actually compute — the dispatch mechanism itself

164/165 mapped opcodes gives the *shape* of the dispatch (which handler
serves which opcode); reading a handful of the handler bodies themselves —
`Tv`, `BP`, `yv` from this VM's `K` loop — shows the actual *mechanism*,
and it's the same one already known from elsewhere in this project:

```
Tv=function(t,r,D,J,L,b,p,o,M,H)if L<=13 then if L<=12 then return 7,D[4],H,p,M,J;
else local i=t[56](o,H+2);return not(128<=i)and 27 or 4,D,H,p,M,i;end;...
yv=function(t,r)return t[83](r,1,r[t.s]);end
```

`t[56]` resolves to `buffer.readu8`, `t[83]` to `unpack` (`table.unpack`).
So: each handler ends by **returning a computed next-opcode number plus
updated registers** — a continuation-passing, threaded-code interpreter,
where `z8`'s own `while r do if K<=16 then...` loop just does
`K,<registers...> = t:HANDLER(...)` every iteration and the handler itself
decides where to go next. `Tv`'s `not(128<=i)and 27 or 4` is a live example:
fetch one bytecode byte, and its high bit (the `128` threshold) picks
between two different next-opcodes — classic variable-length/LEB128-style
instruction decoding, matching the multi-byte constant-loading pattern
`v15.md` already documented for the *outer* payload VM. `yv` is the
interpreter's own return/multi-value trampoline (unpack a results table
back into real Lua return values).

**Cross-sample confirmation:** `sample_v15.lua`'s own newly-mapped `c`/`d`
loops (see below) show the exact same shape —
`S=function(t,B,L,q,M,m,x,g,G,O)if B<=97 then if B<=96 then local
h=t[94](G,O+1);local j,b=128>h and 38 or 53,g[1];return
j,g[2],b,m,O,q,h,L;...` — with `t[94]` in *that* file independently
resolving to `buffer.readu8` too. Two independently-decoded/embedded VM
instances, in two different real samples, implement identical low-level
dispatch mechanics: byte-fetch, high-bit branch, return-the-next-opcode.
That's the strongest evidence yet that this isn't incidental similarity —
it's the same interpreter template, reused wherever Luraph puts a
handler-dispatch sub-VM, regardless of which outer file it ends up in.

## The `K` loop, fully characterized — not just a sample this time

`K` (9 opcode ranges, 10 handler calls) is small enough to read in full
rather than sample a handful. Doing that gives real per-opcode semantic
categories, not just "it's a threaded interpreter":

- **`Jv`, `Tv`, `WP`, `gP`, `Ev`, `BP` (6 of 9) are all operand-decode
  variants** — each fetches 1+ bytes via `buffer.readu8` and reassembles a
  multi-byte value with the same 7-bit/128-scaled pattern
  (`(byte-128)*16384 + ...*128 + ...`), differing only in how many bytes
  they pull and what they do with the result before returning the next
  opcode. This is the operand-fetch primitive, LEB128-style, appearing
  under six different names because each one is specialized to a
  slightly different operand width/use, not because they're six different
  algorithms.
- **`GP` is a loop-counter/comparison primitive** — accumulates a running
  sum (`p[5] = p[5] + p[1]`-shaped) against a stored limit (`p[2]`) and
  branches on whether it has reached it. The interpreter's for/while-style
  condition check.
- **`XP` is a store** — `r[J]=L` writes a value into a register/array
  slot before computing the next opcode. (Minor Luraph quirk noticed while
  reading it: its own parameter list is `function(t,t,r,D,J,L)` — the
  first `t` is immediately shadowed by the second and never used, i.e.
  this specific handler doesn't actually touch `self`. Harmless, just a
  renaming-pass artifact worth flagging so it isn't mistaken for a bug in
  the reading, not the source.)
- **`Rv` is the vararg-consumption entry point** — `t.W=...` captures the
  handler's own varargs onto the VM state table, then immediately reads a
  buffer from it via `buffer.readu8(t.W, t[95])`. This is the exact code
  path this file's "traced crash" section above already identified as
  where the missing-argument `buffer.readu8(nil,...)` failure originates —
  now confirmed by reading `Rv` itself rather than just its call site.
- **`yv`** (already covered above) **is the return/unpack trampoline.**

So one full VM (not a sample of it) is now genuinely characterized:
mostly operand decoding, one loop-condition check, one store, one
vararg-entry, one return. Still open: the other 155 opcodes across `G`/`_`
(this file) and the ~128 across `sample_v15.lua`'s `c`/`d`/`S` — this is a
proof that full-VM characterization is tractable in reasonable time
(reading 9 short handlers took minutes, not hours), not that it's done.

## Three new opcode categories found scanning `G`/`_` for what `K` didn't have

Sweeping `G`/`_`'s remaining 155 handlers with an automated classifier
(same categories as `K`'s: operand-decode / store / loop-counter /
vararg-entry / return-trampoline, matched by regex against each handler's
source) is a coarse tool, and its first pass proved it: an overly narrow
"reads a buffer byte" pattern initially left 16 (`G`)/17 (`_`) handlers
unclassified, which shrank to 15 total after loosening that regex to catch
a wider range of call shapes — most of the "unclassified" count was just
argument-order the first regex missed, not new behavior. The **real**
signal came from reading the residue by hand rather than trusting either
count: two genuinely new opcode shapes `K` never showed, present even
inside handlers the *looser* regex still lumped into "operand-decode"
(the classifier can tell "calls a buffer function" but not "then writes
the result back to another buffer" or "then branches on the result" — that
distinction only shows up on an actual read):

- **Read → XOR → write buffer decrypt** (`DP`, `e8`, `mP`, and others) —
  `t[59](J,M,(t[46](t[56](o,p+M),r,b)))`. Resolving the aliases: `t[56]` is
  `buffer.readu8`, `t[46]` is `bit32.bxor`, `t[59]` is `buffer.writeu8`.
  So: read a source byte, XOR it against a computed value, write the
  result to a destination buffer — a decrypt-style primitive, structurally
  the same *idea* as `v15.md`'s `sample_v15.lua` `L`-handler RC4 finding
  (read/transform/write into a buffer) but embedded here as ordinary
  dispatched opcodes inside the main VM rather than a separate
  comparison-chain stepper, and using plain modular arithmetic for the
  transform rather than a confirmed RC4 keystream — a related but distinct
  mechanism, not the same one re-found.
- **Conditional table lookup / cache-hit branch** (`i8`, one of its two
  internal sub-cases) — `local q=t[H];if not not q then return
  198,q,...;else return 187,...;end`. Check whether a table slot is
  populated and branch on hit vs. miss — a shape neither `K` nor the
  operand-decode/store/loop-counter categories cover. Notably, `i8`
  contains **both** this lookup shape *and* the read-XOR-write decrypt
  shape in different sub-branches of the same handler — confirmation that
  one handler name doesn't mean one behavior; Luraph's opcode ranges can
  pack multiple distinct operations under a single dispatched name,
  differentiated by a finer-grained condition inside the handler body
  itself.
- **Cons-cell-style pop from an internal list** (`A`, `K`, and others) —
  `local D,H=r[1],p[1];return 85,D,p[2],H,L,b` (`A`); `local M,H=o+1,b[1];
  return 104,b[2],H,M,J,r` (`K`). Both pull a value from `X[1]` and a
  *remaining-list* pointer from `X[2]` (classic car/cdr), rather than
  decoding fresh bytes off the bytecode buffer — a second instruction
  source alongside the buffer, most likely consuming a results list this
  VM already builds elsewhere (`z8`'s `t[29](...)` = `table.pack(...)`,
  `yv`'s `unpack(r,1,r[t.s])` — see "The `K` loop" above). **Cross-sample
  confirmed**, not a one-off: `sample_v15.lua`'s `c`-loop handlers `E`,
  `Y`, `j` show the identical `L[1]`/`G[1]`/`t[1]` extraction shape (see
  `v15.md`), independently, in an unrelated file.

After the regex fix, only 1 name (`_`'s `Hv`) stayed automatically
unclassified — read directly, it turned out to be an ordinary
operand-decode variant, nothing new (with the same harmless duplicate-`t`
parameter-shadowing quirk already noted for `XP`). That doesn't mean
`G`/`_` are fully characterized the way `K` is: the classifier's
"operand-decode" bucket still silently contains an unknown number of
read-XOR-write, conditional-lookup, and list-pop handlers like
`DP`/`e8`/`mP`/`i8`/`A`/`K` that only reading catches, not automated
matching. This was a targeted scan for *new shapes* (found three), not a
claim of exhaustive coverage.

## Cross-sample finding

Two independently-authored real Luraph v15.0 samples now show the **same**
overall behavior signature under this sandbox: boot cleanly, reach a
ready state, do real bounded setup work, then produce zero further
observable effects even at a 10x time budget. That is meaningfully stronger
evidence for "genuine live client state is what's missing" than either
sample alone — it is no longer a property of one specific file's quirks.

## Bonus finding: `sample_v15.lua` also has comparison-chain sub-VMs

Running `chain_dispatch_probe.py --list` against `sample_v15.lua` itself
(as a sanity check before trusting the new detector) found **4 more**
candidate comparison-chain loops inside its own loader
(vars `B`, `F`, `j`, `L`; richness 3–10) that `find_vm_groups`'s
array-fetch-only regex never saw. These are not false positives — they show
the same nested `if X<=N then if X<=N2 then...` binary-search shape as this
sample's real `B` loop, and quick inspection suggests small special-purpose
steppers (byte/modulus arithmetic in one, array-swap/permutation logic in
another) rather than noise. **Not characterized further here** — flagged as
a genuine, previously-uncatalogued piece of `sample_v15.lua`'s own
architecture, worth its own follow-up in `v15.md`.

**Update:** broadening `chain_dispatch_probe.py`'s loop-condition regex
(`while true do` → `while \w+ do`, see above) found **three more** in
`sample_v15.lua` — `c` (richness 45), `d` (richness 69), and `S`
(richness 13) — all using the exact same `t:METHOD(...)` self-referential
dispatch convention as MM2's decoded inner VM, all AST-confirmed as real
`AstStatWhile` statements (not string-literal text coincidences). So
`sample_v15.lua` has (at least) 7 uncatalogued comparison-chain sub-VMs
total, not 4. **Update 2:** all 7 now characterized — `v15.md` has the full
breakdown, but the headline: `F` turned out not to be a new VM at all (the
main payload VM's own lazy-init wrapper), `c`/`d`/`S` are real
handler-dispatch sub-VMs with full opcode maps
(`devirt/sample_v15_chain_opcode_map.md`), and `B`/`L` were identified
concretely (not guessed) as a chained LCG PRNG and an RC4 keystream
generator respectively, by resolving their numeric-keyed calls to actual
`bit32`/`buffer` builtins.

## Not Luraph: `jnkie.com/sdk/library.lua`

Checked as a candidate third sample, ruled out. Its own header/strings
never mention Luraph, and while `chain_dispatch_probe.py` does find 4
instances of its comparison-chain shape (all named `j`, combined richness
86 — matching several of its ~14 returned methods each implementing their
own small state machine), `find_vm_groups` finds nothing, there's no `LPH`
marker, and its overall shape (a flat table of ~14 named utility methods —
JSON encode/decode, an `HttpGet` wrapper, a cache layer, `getfenv` access —
totaling 14.3KB) doesn't match Luraph's constant-pool-plus-handler-table
architecture at all. Useful precisely because it shares surface-level
obfuscation tricks (hex/binary literal constants, XOR-decoded strings, the
same comparison-chain dispatch idiom) without being the same tool —
confirms the comparison-chain shape isn't Luraph-specific, just a common
technique, and that "obfuscated" and "Luraph" are not synonyms.

## Tooling added

- `devirt/chain_dispatch_probe.py` — generic detector + dynamic prober for
  the comparison-chain dispatch shape, the same way `v15_payload_probe.py`
  is generic for the array-fetch shape. Validated against all three files
  above.
- `devirt/loadstring_alias_dump.py` — generic detector + dynamic prober for
  Luraph's indirect (constant-pool-aliased) `loadstring`/`load` call: finds
  where the builtin sits as a table value, follows the destructuring alias
  that pulls it into a short local name (identifier-agnostic on purpose,
  since the constant-pool table itself is often never bound to its own
  name — see the tool's header comment), locates the real call site whether
  the alias is invoked directly or passed as a bare argument to another
  aliased builtin (the actual shape here: `pcall_alias(loadstring_alias,
  source, "Luraph", nil)`), and dumps every argument's type/length/short
  preview at runtime. Reproduces this file's finding standalone:

  ```
  arg=0 type=function
  arg=1 type=string
  arg=1 len=170974
  arg=1 head 1 return setmetatable({JP=functi
  arg=2 type=string
  arg=2 len=6
  arg=2 head 1 Luraph
  arg=3 type=nil
  ```

  Run against `sample_v15.lua` as a negative control: correctly reports no
  `loadstring`/`load` value-site found, matching that sample's
  already-established from-scratch architecture (no dynamic second stage).
- `devirt/chain_opcode_semantics.py` — opcode semantics for the
  comparison-chain shape, the missing counterpart to
  `v15_payload_opcodes.py` (array-fetch shape). Ties chain_dispatch_probe's
  detector to `v15_payload_opcodes.py`'s AST-based `walk_dispatch`, proven
  to work unchanged across shapes. Also fixed a real gap it exposed in
  `collect_calls` (shared code): local-indexed/method calls (`t:METHOD(...)`)
  were never recognized, only global-indexed ones (`buffer.readu8`) — see
  "The full opcode-to-handler map" above. `devirt/mm2_inner_opcode_map.json`
  / `.md` are this tool's output for MM2's inner VM: 164 opcode ranges, 165
  handler names, zero overlap. Also run against `sample_v15.lua`'s own 7
  comparison-chain candidates — `devirt/sample_v15_chain_opcode_map.json`
  / `.md` — which is how `F` got reclassified as not a new VM and `c`/`d`/`S`
  got their own opcode maps (see `v15.md`'s updated item 3).

## Ways forward

1. ~~Characterize what `j()`'s returned function actually is/does when
   called~~ — **done, see above**: it's `loadstring` (aliased through the
   constant table) on a base64/bit-unpacked 170,974-byte Lua source string,
   decoded from one of the file's two `[==[LPH...]==]` blobs.
2. ~~Characterize the inner comparison-chain VM that lives inside that
   decoded string~~ — **done, see "The third VM layer" above**: dumped it
   byte-exact with the new `--full-dump-arg` tooling, confirmed it's a full
   constant-pool+handler table (~183 functions) with (at least) 3 of its own
   comparison-chain dispatch loops (`K`, `G`, `_`), and traced the exact
   runtime crash (`Rv`'s `buffer.readu8(nil,...)`) back to its real entry
   point `z8` never receiving a real first call argument under a bare
   `loadstring(...)()` invocation. ~~**Not done**: per-opcode semantics for
   any of `K`/`G`/`_`~~ — **also done**: 164/165 opcode-to-handler mapping,
   see "The full opcode-to-handler map" above and
   `devirt/mm2_inner_opcode_map.md`. **Still not done**: what each of those
   165 handler functions individually computes (the dispatch *shape* is now
   fully mapped; the *semantics* of any single handler body are not), and
   the `D`/`r`/`i` groups from the first, narrower regex pass haven't been
   run through `chain_opcode_semantics.py` at all yet.
3. ~~Characterize the 7 comparison-chain loops inside `sample_v15.lua`
   itself~~ — **done, see `v15.md` and `devirt/sample_v15_chain_opcode_map.md`**:
   `F` is the payload VM's own lazy-init wrapper, not a new VM; `c`/`d`/`S`
   are real handler-dispatch sub-VMs (opcode maps built, same as MM2's
   inner VM); `B` is a chained LCG PRNG and `L` is RC4 keystream generation
   (both identified concretely via resolved `bit32`/`buffer` builtin
   names, not guessed); `j` remains a small, unconfirmed logging-state-machine
   guess. ~~**Still open**: what any individual handler body actually
   computes~~ — **the `K` loop is now fully done** (see "The `K` loop,
   fully characterized" above): all 9 opcode ranges read and categorized —
   6 operand-decode variants, 1 loop-counter/comparison, 1 store, 1
   vararg-entry (confirmed as the traced crash's actual origin), 1
   return-trampoline. That's proof full-VM characterization is tractable
   in reasonable time, not just a mechanism sample. ~~**Still open**: the
   other ~155 opcodes in this file's `G`/`_` loops~~ — **scanned, not fully
   read** (see "Three new opcode categories" above): an automated pass
   sorted most of `G`/`_` into `K`'s existing categories and found **three
   new ones** — read-XOR-write buffer decrypt, conditional table
   lookup/cache-hit, and a cons-cell-style list-pop (the last one
   cross-sample confirmed against `sample_v15.lua`'s `c` loop) — that only
   surfaced by reading the residue by hand, since the classifier can't
   distinguish "decode an operand" from "decode then write the result to
   another buffer," "decode then branch on a lookup," or "pop from a list
   instead of decoding at all." So `G`/`_` are categorized at a coarser
   grain than `K`, not to the same per-handler depth. ~~**Still open**: the
   ~128 opcodes across `sample_v15.lua`'s `c`/`d`/`S`~~ — **scanned too,
   same result**: near-total automated coverage (127 of 128 into known
   categories after the same classifier), with the one residual (`c`'s
   `E`/`Y`/`j`, initially "unclassified") turning out to be the list-pop
   pattern above, not a fourth new shape. **Still open**: how common all
   three new categories actually are within `G`/`_`/`c`/`d`/`S` specifically
   (only confirmed on the handful read by hand in each, not counted
   exhaustively), and `d`'s one remaining unclassified name (`xA`) wasn't
   fully distinguished from an ordinary decode variant.
4. ~~Find more real-world Luraph samples~~ — **done, see `../sample3.md`**:
   a third real v15.0 sample confirms the same comparison-chain-outer +
   decoded-inner-VM shape this file established, and its inner VM goes
   further — mixing array-fetch and comparison-chain dispatch in one layer
   (not seen before) while its two richest comparison-chain loops use the
   exact same `t:METHOD(...)` template already catalogued here and in
   `v15.md`. Still open: samples of different Luraph *version* labels
   (everything found so far says v15.0) to test whether that varies the
   shape further.
5. (New, opened by item 2's traced crash) Find out what the real first
   argument to the outermost returned function is supposed to be in genuine
   use — is a bare `loadstring(url)()` actually how this script is meant to
   run, or does whatever loads it in practice supply an argument this
   analysis hasn't seen? Answering this would settle whether the "silence
   downstream" signature common to every sample in this project is a
   sandbox limitation or a usage-pattern mismatch.
