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

## Ways forward

1. ~~Characterize what `j()`'s returned function actually is/does when
   called~~ — **done, see above**: it's `loadstring` (aliased through the
   constant table) on a base64/bit-unpacked 170,974-byte Lua source string,
   decoded from one of the file's two `[==[LPH...]==]` blobs.
2. Characterize the **inner** comparison-chain VM that lives inside that
   decoded 170,974-byte string (`JP=function(t,r,D,J,L,b,p,o,M,H,i,u,q,K,A,l)
   if J<=127 then if J<=126 then...`) — this is the real payload
   interpreter, invisible to any analysis of the outer static file since it
   is synthesized at runtime. Same tooling applies in principle
   (`chain_dispatch_probe.py`, `v15_payload_opcodes.py`'s AST leaf
   classifier) but needs a harness change first: today's tools all take a
   file path and parse it statically; this target only exists as an
   in-memory string produced by `loadstring` at runtime, so reaching it
   means either (a) intercepting and dumping the full decoded string to a
   file first (straightforward, same technique as the `[[GHEAD]]` probe
   above, just uncapped), then running the existing static tools against
   that dumped file, or (b) instrumenting *inside* the dynamically-loaded
   chunk directly, which the current source-splicing approach can't do
   without (a).
3. Characterize the 4 newly-found comparison-chain loops inside
   `sample_v15.lua` itself (bonus finding above) — likely loader sub-steps,
   not yet mapped to a specific purpose.
4. Find more real-world Luraph samples of different version labels to keep
   testing "how many codegen shapes does 'Luraph' actually cover" —
   this file alone already disproved "one shape per major version," and now
   shows the shape can also nest inside itself across a dynamic-load
   boundary.
