# Third real-world Luraph v15.0 sample — cross-sample architecture confirmation

Source: cited by URL only, per this project's standing policy — the raw file
is someone else's protected script and is not vendored into this repo (same
as `mm2.md`'s sample). Header confirms `-- This file was protected using
Luraph Obfuscator v15.0 [https://lura.ph/]`.

**Scope note.** This writeup stays at the same level as `mm2.md`: Luraph's
own obfuscation architecture (dispatch shapes, opcode counts, generic
algorithmic building blocks) — not the specific script's actual runtime
behavior or purpose. The filename this sample was found under strongly
suggests it automates something against a live multiplayer game; this
project catalogues obfuscation formats, not gameplay exploits, so no attempt
was made here to trace what the decoded VM's opcodes actually do to a game
or other players, only how Luraph itself is structured.

## Structurally: same two-layer shape as `mm2.md`'s sample, confirmed a third time

Running the exact same generic tools used for the second sample, unmodified:

- `find_vm_groups` (array-fetch shape): **zero** candidates in the outer
  file — same as `mm2.md`'s sample, not `sample_v15.lua`'s own shape.
- `chain_dispatch_probe.py` (comparison-chain shape): **one** real candidate,
  var `d`, richness 17 (`mm2.md`'s sample: var `B`, richness 16 — same
  order of magnitude).
- `loadstring_alias_dump.py`: finds `loadstring` sitting as a constant-pool
  table value, resolves its destructuring alias, and locates the real call
  site — `r(p, G(s), L, nil)`, i.e. `pcall(loadstring, decoded_source,
  chunkname, nil)`. Exactly the same indirect-alias pattern as `mm2.md`'s
  sample's `h(j, L(g), "Luraph", nil)`.
- `--full-dump-arg` on that call site: byte-exact dump, 1961/1961 chunks,
  176,487 bytes reassembled (matches the runtime-reported length exactly),
  parses cleanly with `luau-ast`. The decoded string is, again, **not** one
  function but another full constant-pool+handler table (`return
  setmetatable({[0]=buffer.fromstring,[56]=buffer.len,cU=function(...)...`) —
  188 `=function(` entries, 442 `[N]=` numeric keys (larger than the second
  sample's ~183-handler inner VM). No further nested `loadstring` — this is
  the terminal VM layer, same depth as the second sample.

So: three independently-obtained real Luraph v15.0 files now split into two
distinct top-level families — `sample_v15.lua`'s from-scratch 145-handler
loader with an array-fetch payload VM, and now **two** samples sharing the
comparison-chain-outer-wrapper-plus-decoded-inner-VM shape. That shape looks
like the more common one in the wild, on this admittedly small sample of
three.

## New: the inner VM mixes BOTH dispatch shapes in one layer

`mm2.md`'s second sample's inner VM was purely comparison-chain (`K`, `G`,
`_`). This one's inner VM has **both**:

- array-fetch groups: `b` (4 instances), `l` (2), `jR` (4) — the
  `sample_v15.lua`-style shape, inside a file that otherwise looks nothing
  like `sample_v15.lua`.
- comparison-chain groups: `z` (richness 70), `d` (63), `R` (11), `O` (9),
  `Y` (9), `P` (8), `n` (6).

Not seen before: a single VM layer using both codegen idioms side by side,
rather than one idiom per layer. Inspecting the two richest comparison-chain
loops (`z`, `d`) shows the identical self-referential `W:METHOD(...)`
handler-dispatch convention already catalogued in `mm2.md` (that sample's
inner VM) and `v15.md` (`sample_v15.lua`'s own `c`/`d`/`S` sub-VMs):

```
while P do if z<=118 then if z<=58 then ... z,K,y,c,f,N,o=W:fy(o,q,c,r,_,z,l,N,y,f,x,X,K);...
while Q do if d<=163 then if d<=81 then ... d,Y,F,n,g=W:Y(g,w,D,p,i,j,z,n,d);continue;...
```

Fourth and fifth confirmed instance of that exact template (after
`sample_v15.lua`'s `c`/`d`/`S` and the second sample's `K`/`G`/`_`) — now
seen in a *third*, independently-obtained file. This is the strongest
version yet of the "shared, reusable sub-VM template" finding from
`mm2.md`: it isn't a quirk of one obfuscator build, it recurs across at
least three unrelated real samples.

## Not characterized here

Per the scope note above: no opcode-to-handler map was built for this
sample's `z`/`d`/array-fetch groups (the existing `chain_opcode_semantics.py`
/ `v15_payload_opcodes.py` tooling would apply unchanged, per the pattern
established twice already), and no attempt was made to identify what any
handler computes. Both would be straightforward extensions of the existing
pipeline if this sample becomes a priority; the goal here was purely to
confirm the architecture generalizes, which it does.
