# devirt — Luraph v14.7 devirtualisation toolkit

The last mile: turning the recovered bytecode back toward Lua source. This
directory drives the recovered VM, instruments its dispatch, and builds up a
per-opcode map for the sample.

**Honest framing.** A *complete, correct* decompilation of a Luraph v14.7 VM
is build-specific reverse engineering (Luraph randomises the opcode numbering
per build) and is genuinely week-scale work, not a one-shot script. What's
here is the real, working machinery that makes it tractable and mechanical:
you can already run the VM, get a live disassembly with operands, profile the
opcodes, and render an annotated listing. Filling the opcode map from the
interpreter source is the remaining manual step, and the tools point exactly
at it.

## Pipeline

```
peel.py  ->  stage_0.lua (VM source) + stage_1.bin (bytecode)
   |
run_vm.py --mode disasm   ->  live instruction trace (opcode + 4 operands)
run_vm.py --mode freq     ->  opcode histogram (which ops matter)
run_vm.py --mode trace    ->  pc/op stream (control-flow reconstruction)
   |
annotate.py + opcodes.json ->  annotated listing (mnemonics + effects)
   |
(fill opcodes.json from func `o`)  ->  lift to Lua   [remaining manual mile]
```

## Files

- **`run_vm.py`** — generates a self-contained Luau harness that runs the
  recovered VM over the bytecode in a stubbed, network-blocked environment,
  and **injects a probe at the dispatch** so every executed instruction is
  reported. Auto-detects the build-specific dispatch variables. Modes:
  `disasm` / `freq` / `trace`. This is the engine; it works today.
- **`architecture.md`** — the recovered VM model (register machine; `W[C]`
  opcode, `e[]` registers, `j/q/U/c[C]` operand arrays, binary-search
  dispatch), a sample disassembly, the opcode frequency table, and what's
  confirmed vs. remaining.
- **`opcodes.json`** — the per-build opcode map. Seeded with confirmed
  entries (`286`=JMP, `205`=load-string-constant) and operand-shape hints for
  the hot ones; extend it by reading each leaf in func `o`.
- **`annotate.py`** — renders a `disasm` trace through `opcodes.json` into a
  readable listing (mnemonic + effect for known ops; operand shape + hint for
  unknown ops).

## Quick start

```bash
bash ../dynamic/build_luau.sh        # builds ../dynamic/luau
python3 ../peel.py ../sample_sigil.lua -o peeled
python3 run_vm.py --vmdir peeled --luau ../dynamic/luau --mode disasm --n 400 --out dis.txt
python3 annotate.py dis.txt --map opcodes.json
python3 run_vm.py --vmdir peeled --luau ../dynamic/luau --mode freq
```

## What's confirmed on the sample

- The VM is a **register machine**; dispatch is a binary search on the opcode
  in the ~53 KB function `o`.
- `286` = unconditional **JMP** and dominates the histogram — Luraph flattens
  control flow at the bytecode level (every block ends in a jump).
- `205` loads a string constant into a register.
- 125 distinct opcodes are exercised; the full constant pool is already
  recovered (`../dynamic/sample_constants.txt`).

## What's left

Read the remaining ~120 opcode leaves in `o` (the disasm operand shapes tell
you what to look for) to complete `opcodes.json`, then a `lift.py` walks each
proto emitting Lua per opcode and inlining constants. The inputs a lifter
needs — the interpreter *as source*, a live *disassembly*, and the *constant
pool* — are all produced here.
