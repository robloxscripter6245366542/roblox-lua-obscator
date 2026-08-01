# Devirtualisation notes — Luraph v14.7

This is the "go deeper" writeup: what the static unpacker (`peel.py`)
recovers, the big finding that makes it possible, and the roadmap for the
one hard step that's left.

## TL;DR — the big finding

**Luraph's outer protection uses no cryptographic key.** The two packed
`[=[LPH…]=]` streams are:

```
base-85 (Ascii85 variant)   ->   LZMA1 (lc=3, lp=0, pb=0, raw)
```

Both layers are fully reversible offline. The pure-Lua LZMA decoder shipped
in the bootstrap (function `n`, a textbook range coder) is the entire "inner
encryption" — it's just **compression entropy**, which is why the peeled
bytes looked random. Python's own `lzma` module decodes the raw stream once
you supply `lc=3,lp=0,pb=0` and a large enough `dict_size`.

Peeling the v14.7 sample therefore yields, **statically, with no runtime**:

| Stage | Size (peeled → LZMA) | What it is |
|-------|----------------------|------------|
| 0 | 25,876 B → **99,942 B** | the **VM interpreter, as Lua source** |
| 1 | 1,347,424 B → **2,363,120 B** | the **VM bytecode** program |

Two earlier assumptions were wrong and are now corrected in the tooling:
1. There is **no runtime keystream** on the packing — it's LZMA. (`sandbox.lua`
   is still useful, but for the *program's* runtime strings/behaviour, not to
   get past the packing.)
2. `peel.py` had an Ascii85 off-by-one (`sub(n,5)` keeps from the 5th char =
   drops 4, not 5). Fixed — before the fix the whole stream was misaligned.

## Bootstrap chain (recovered, plain Lua)

```
Z         = base-85 decoder (sub header, 'z'->!!!!!, 5 chars -> <I4)
v, V      = Z(stream0), Z(stream1)          -- base-85 decoded
n         = pure-Lua LZMA decoder (range coder)
Q         = n(v)                            -- decompress -> VM SOURCE
v         = buffer.fromstring(n(V))         -- decompress -> BYTECODE buffer
Vfn       = loadstring(Q, "Luraph  ")       -- compile the VM interpreter
return Vfn(v)                               -- run interpreter over bytecode
```

The integrity block near the top (`D=5` → `D=20.0` on tamper) only poisons
the base-85 header length; supply `D=5` and it's inert (weakness W5).

## Bytecode format (stage_1.bin) — observations

- 2.36 MB after decompression. Byte histogram is dominated by small values:
  `0x02` ≈ 20% of the stream, `0x01` next — consistent with a
  **variable-length integer / tagged operand** encoding, not fixed-width
  Lua 5.1 opcodes.
- Plaintext that survives in the constant region: Luraph's own runtime error
  strings (`"…does not support load or loadstring…"`, the debug-library
  message) and the Luraph ASCII-art banner. The *program's* own strings
  (URLs, key logic) are in the VM constant table under a per-build transform,
  so they come out by running the interpreter's constant decoder, not by
  `strings`.

## Devirtualisation roadmap (the hard step)

We now have the interpreter **in source**, which is what makes lifting
tractable. In the recovered `stage_0.lua`:

- ~175 handler functions, heavy **control-flow flattening**
  (`while true do if v>21 … continue`) and numeric-literal obfuscation
  (`21.0`, `1.0`).
- The **VM execution core is the ~53 KB function `o`** (largest by far) —
  this is the dispatch loop. The deserialiser that turns stage_1 into the
  in-memory proto table is a separate cluster of handlers.

Suggested order of attack:

1. **De-flatten the source.** The handlers are state machines keyed on a
   numeric register. Resolve each `if/elseif` ladder into a normal block
   sequence — this alone makes `o` readable.
2. **Recover the deserialiser.** Trace how `o`/its helpers consume the
   bytecode buffer: opcode field width, operand encoding (the varint tag
   above), and how constants/protos/upvalues are laid out.
3. **Map opcodes → semantics.** The handler bodies *are* the semantics
   (they call real `string.*`, table ops, arithmetic). Build an
   opcode→Lua-op table by reading each branch of `o`.
4. **Lift.** Walk the deserialised protos emitting Lua per opcode; reattach
   nested protos; recover the constant table (incl. the string transform) so
   URLs/keys come back as literals.

Steps 1–2 are mechanical given the source. Step 3 is the labour. Step 4 is
codegen. This is a real project, but it is no longer *blind* — every rule you
need is sitting in `stage_0.lua`.

## Reproduce

```bash
python3 peel.py sample_sigil.lua -o out
#   out/stage_0.lua  <- read this: the VM interpreter
#   out/stage_1.bin  <- the bytecode to lift
python3 strings.py out/stage_1.bin      # plaintext triage
```
