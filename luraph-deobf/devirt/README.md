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
- **`semantics.py`** — recovers opcode semantics by **register-delta
  analysis**: snapshots the register file each step and diffs consecutive
  states, attributing every write to its opcode. Sidesteps the obfuscation
  entirely (observe effects, don't read handlers). Regenerates the opcode map
  for any build. Produced the 14 confirmed + 9 inferred entries in
  `opcodes.json`.
- **`build_map.py`** — synthesises the **complete** opcode map: merges the
  control-flow census (`run_vm.py --mode cf`) + the register-delta trace +
  the curated `opcodes.json` overrides into `opcodes.full.json`, classifying
  **all 125 executed opcodes** of the build (confirmed entries win).
- **`annotate.py`** — renders a `disasm` trace through a map (`opcodes.json`
  or the complete `opcodes.full.json`) into a readable listing. With the full
  map it labels **100% of the executed instructions** on the sample.
- **`lift.py`** — the codegen. Consumes a full instruction dump
  (`run_vm.py --mode fulldump`, i.e. *every* instruction of every proto, not
  just executed ones) + `opcodes.full.json` and emits **register-level Lua**:
  one `function protoN` each, `e[]` registers, `::L_pc::` block labels, and
  control flow rebuilt as `goto`/`if…goto` (Lua 5.4). Verified: the output
  **compiles as Lua 5.4** and lifts **~97%** of all static instructions
  (residue = opcodes that never execute — see below).

## Quick start

```bash
bash ../dynamic/build_luau.sh        # builds ../dynamic/luau
python3 ../peel.py ../sample_sigil.lua -o peeled
L=../dynamic/luau
# 1) recover the complete opcode map
python3 run_vm.py --vmdir peeled --luau $L --mode cf   --out cf.txt
python3 semantics.py --vmdir peeled --luau $L --steps 14000 --out sem_big.txt >/dev/null
python3 build_map.py --sem sem_big.txt --cf cf.txt --curated opcodes.json --out opcodes.full.json
# 2) dump every instruction and lift to Lua
python3 run_vm.py --vmdir peeled --luau $L --mode fulldump --out full.txt
python3 lift.py full.txt --map opcodes.full.json -o lifted.lua   # -> compiles as Lua 5.4
```

## What's confirmed on the sample

- The VM is a **register machine**; dispatch is a binary search on the opcode
  in the ~53 KB function `o`.
- `286` = unconditional **JMP** and dominates the histogram — Luraph flattens
  control flow at the bytecode level (every block ends in a jump).
- `205` loads a string constant into a register.
- 125 distinct opcodes are exercised; the full constant pool is already
  recovered (`../dynamic/sample_constants.txt`).

## Status of the four devirtualisation tasks

1. **lift.py — codegen.** ✅ Done. Emits register-level Lua for **~97%** of all
   static instructions; output compiles as Lua 5.4.
2. **SETTABLE vs CALL precision.** ✅ Resolved for the hot ops via
   operand-register typing (the register a no-write op indexes is a table →
   SETTABLE, a function → CALL). Nailed **op49 = SETTABLE** (`e[a][K(b)]=e[c]`,
   table in 1149/1149) and **op50 = CALL** (void call; the most common no-write
   op — it was *not* SETTABLE), plus several more. The long tail of rare
   no-write ops whose operand-a register wasn't populated in-window stays
   `SETTABLE/CALL`.
3. **Rare `op?` opcodes.** ✅ The 8 executed-but-unsampled ops are now
   classified from the control-flow census (all flow-through data ops). Zero
   `op?` remain among **executed** opcodes.
4. **High-level structuring (if/while).** ◻ Partial. Control flow is emitted
   faithfully as basic blocks + `goto` (Lua 5.4) — correct and readable, but
   not yet folded into `if`/`while`/`for`. That reducer is a separate pass on
   top of the lifted CFG and is the main remaining beautification step.

### The honest residue
`lift.py` reaches ~97%, not 100%, because **112 opcodes appear in the
bytecode but never execute** (~217 instructions, dead/untaken paths under the
stubbed environment). Dynamic profiling can't reach them; resolving them needs
either different inputs to trigger those paths or reading their handler leaves
in `o` statically. Everything that *runs* is classified.
