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

## Opcode semantics — recovered by register-delta analysis

Rather than read 120 obfuscated handler leaves by eye, `semantics.py`
recovers semantics from **ground truth**: it snapshots the register file
`e[]` at every step and diffs consecutive states, so each register write is
attributed to the opcode that produced it. This sidesteps the obfuscation —
we observe what each opcode *does*, never needing to understand its code.

Recovered so far (this build; opcode numbers are per-build):

| op | mnemonic | effect | evidence |
|----|----------|--------|----------|
| 286 | JMP | `C = target` (unconditional) | no reg write; dominates histogram |
| 283 | ADD | `e[a] = e[c] + d` | e[25]: 150 → 22959, d=22809 |
| 205 | LOADK | `e[a] = const` (num/str) | e[25] ← 306 |
| 293/235/192 | LOADK_N | `e[dst] = number const` | e ← 223 / 222 / 3758096397 |
| 264/176 | LOADK_S | `e[dst] = string const` | e ← `"  nc213<< H<="` |
| 31/118/182/48 | NEWTABLE | `e[dst] = {}` | fresh table into reg |
| 52 | MOVE | `e[dst] = e[src]` | table moved e[14]→e[15] |
| 105 | GETTABLE | `e[a] = e[obj][key]` | table#16 → table#17 |
| 168 | GETGLOBAL/CALL | `e[a] = _G[name]`/call | d="Vector3", fn→table |
| 295/216 | COMPARE | `e[dst] = bool` (lt/le/eq) | e ← false / true |
| 49/50/228 | SETTABLE/CALL* | table store / call (no reg write) | *inferred (0-delta) |

Full map with confidence + evidence in `opcodes.json` (14 confirmed, 9
inferred). Feeding it to `annotate.py` labels **~92% of executed
instructions** on the sample, because the hot opcodes (JMP, SETTABLE,
NEWTABLE, LOADK, GETTABLE) cover most of execution.

## Complete map — all 125 opcodes classified (`build_map.py`)

`build_map.py` merges two independent dynamic signals and emits
`opcodes.full.json` covering **every** opcode the build executes:

- **control-flow census** (`run_vm.py --mode cf`): per opcode, next-pc
  sequential vs jump → JMP / conditional-branch / flow-through
- **register-delta** (`semantics.py`): what each opcode writes → NEWTABLE /
  GETTABLE / LOADK / MOVE / ARITH / COMPARE / SETTABLE(no-write)
- **curated overrides**: the hand-verified `opcodes.json` entries win where
  they exist (e.g. 286=JMP, 283=ADD), fixing the few the heuristic rounds off.

Resulting class distribution over the 125 opcodes:

| class | count | class | count |
|-------|-------|-------|-------|
| SETTABLE/CALL (no write) | ~39 | JMP/RETURN | ~11 |
| TEST/BRANCH (conditional) | ~14 | ARITH | ~10 |
| COMPARE (→bool) | ~14 | NEWTABLE | ~8 |
| GETTABLE / CLOSURE | ~6 | LOADK (num/str) | ~7 |
| curated (MOVE/ADD/…) | ~9 | unresolved `op?` | ~8 |

Feeding `opcodes.full.json` to `annotate.py` labels **100% of the executed
instructions** in a 400-instruction disassembly window (only ~8 rare opcodes
remain `op?`, and they didn't appear in that window). Regenerate everything:

```bash
python3 run_vm.py --vmdir peeled --luau ./luau --mode cf  --out cf.txt
python3 semantics.py --vmdir peeled --luau ./luau --steps 14000 --out sem_big.txt >/dev/null
python3 build_map.py --sem sem_big.txt --cf cf.txt --curated opcodes.json --out opcodes.full.json
python3 annotate.py dis.txt --map opcodes.full.json
```

## Remaining

- The ~39 no-register-write ops still bundle SETTABLE with void CALL and a few
  conditional forms; a table-content probe would split those precisely.
- ~8 rare `op?` opcodes need more coverage (they sit off the exercised path).
- `lift.py`: walk each proto emitting Lua per `opcodes.full.json`, inlining
  the recovered constants — now that ~100% of hot instructions carry a
  mnemonic, the output is mostly real Lua with a small residue.

Luraph **randomises the opcode numbering per build**, so this map is specific
to this sample — but the whole chain (`--mode cf` → `semantics.py` →
`build_map.py`) regenerates it for any build automatically.
