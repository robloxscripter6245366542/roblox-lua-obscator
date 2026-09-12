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

There is no `loadstring`/`load`/`string.dump`/`debug.*` anywhere in the
file, ruling out a native-bytecode-loader theory — whatever `j()` returns
must be one of the file's own 8 statically-defined closures (enumerated via
AST; sizes 65–2807 chars), not dynamically synthesized code. One nearby
small `vararg`-taking function matches the shape of a generic multi-return
forwarding trampoline (`local Q=J[83](...);table.move(Q,1,Q[J.y],g+1,D)`) —
plausibly the calling-convention glue between this VM and a native handler,
though not yet confirmed to be what `j()` specifically returns.

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

## Ways forward

1. Characterize what `j()`'s returned function actually is/does when
   called — the actual stall point, one level deeper than this writeup
   reaches. Requires instrumenting the second call directly (the harness
   already supports this; see the entry-point interception technique used
   above).
2. Characterize the 4 newly-found comparison-chain loops inside
   `sample_v15.lua` itself (bonus finding above) — likely loader sub-steps,
   not yet mapped to a specific purpose.
3. Find more real-world Luraph samples of different version labels to keep
   testing "how many codegen shapes does 'Luraph' actually cover" —
   this file alone already disproved "one shape per major version."
