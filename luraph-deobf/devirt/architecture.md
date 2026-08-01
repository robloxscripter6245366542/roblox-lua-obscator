# Recovered VM architecture (Luraph v14.7 sample)

This is the output of driving + instrumenting the recovered interpreter
(`run_vm.py`). It documents the VM's execution model precisely enough to
build a lifter, and records what's been confirmed vs. what still needs the
per-opcode read.

## Execution model — a register VM

From the dispatch head of the interpreter's core function (`o`, ~53 KB):

```lua
o=function(...)
  local e, ... , C, ... = v[23](n), ... , 1.0, ...   -- e = register file, C = pc
  repeat
    local V = W[C]                 -- V = opcode, W = opcode array
    if V<148 then if V>=74 then ... -- binary-search dispatch on V
      ... e[j[C]] ... C=c[C] ...    -- operands come from parallel arrays [C]
```

So the VM is a **register machine**:

| element | meaning |
|---------|---------|
| `C`         | program counter (1-based) |
| `W[C]`      | opcode of the instruction at `C` |
| `e[...]`    | the register file (`e[reg]`) |
| `j[C] q[C] U[C] c[C]` | the up-to-4 operand fields of instruction `C` (parallel arrays) |
| dispatch    | a **binary search on `V`** (`if V<148 … if V>=74 …`), one leaf per opcode |

Handlers are readable once you reach a leaf, e.g.:

```lua
if e[j[C]] then C=c[C] end              -- TEST reg; if truthy, jump
if e[q[C]]==U[C] then C=j[C] end        -- EQ reg,const; if equal, jump
```

`run_vm.py` auto-detects the (build-specific) names `V/W/C` and the operand
arrays, injects a probe at the dispatch, and reports every executed
instruction. Operand labels `a/b/c/d` map to the detected arrays in
discovery order.

## Instruction sample (disasm mode)

```
pc=1    op=286  a=0   b=965  c=0    d=nil     -- JMP 965
pc=966  op=286  a=0   b=395  c=0    d=nil     -- JMP 395
pc=431  op=182  a=31  b=0    c=0    d=nil
pc=432  op=48   a=0   b=33   c=0    d=nil
pc=434  op=49   a=33  b=1732 c=4    d=880
pc=438  op=228  a=37  b=0    c=30   d=nil
pc=1184 op=285  a=0   b=0    c=14   d=nil
pc=205  op=205  a=26  b=0    c=<string> d=730 -- loads a string constant
```

The pc jumps everywhere and `op=286` is by far the most frequent — Luraph
flattens control flow at the **bytecode** level too (every basic block ends
in a `286` jump to the next), which is why 286 dominates.

## Opcode frequency (whole run, register VM)

125 distinct opcodes are exercised. Top of the histogram:

| op | share | note |
|----|-------|------|
| 286 | ~36% | **JMP** (unconditional; target in an operand field) — confirmed |
| 33  | ~12% | hot; arithmetic/loop body candidate |
| 2   | ~10% | |
| 28  | ~10% | |
| 86  | ~10% | |
| 77  | ~6%  | |
| 197 | ~4%  | |
| 205 | ~3%  | **loads string constants** (one operand is an inline string) |
| … | | 117–125 opcodes total |

(Regenerate with `run_vm.py --mode freq`.)

## Confirmed vs. remaining

**Confirmed (dynamically):**
- register-VM model, operand arrays, dispatch shape (above)
- `286` = unconditional JMP (drives the flattened control flow)
- `205` loads a string constant into a register
- the full constant pool (see `../dynamic/sample_constants.txt`)

**Remaining — the per-opcode semantic map.** Each of the other ~120 opcodes
needs its leaf in `o` read once to record: which registers/constants it
touches, and its effect (MOVE / LOADK / GETTABLE / SETTABLE / CALL / arith /
comparisons / RETURN …). The operand *shape* from `--mode disasm` narrows
each one (how many fields are non-nil, whether an operand is a string/number/
jump-target), and the leaf code gives the exact op. Luraph **randomises the
opcode numbering per build**, so this map is specific to this sample — but it
is fully recoverable from `o` + the disasm trace, which is what this tool
produces.

The last step, `lift.py`, then walks each proto's instructions emitting Lua
per the opcode map and inlining the recovered constants.
