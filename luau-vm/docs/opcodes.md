# Instruction set

Register-based. `R[x]` is a frame register, `K[x]` a constant, `U[x]` an upvalue
cell. `RK` is not used — constants are materialized with `LOADK`/`LOADINT`, which
keeps operands uniform and the compiler simple. Operand fields: `a`, `b`, `c`
(registers/counts), `bx` (constant/proto index), `sbx` (signed immediate/offset).

Operand layouts are declared in `src/opcodes.lua` (`Opcodes.operands`) and drive
the serializer, so encoding and semantics can never drift.

## Data movement / constants
| Op | Operands | Effect |
|----|----------|--------|
| `MOVE` | a b | `R[a] = R[b]` |
| `LOADK` | a bx | `R[a] = K[bx]` |
| `LOADINT` | a sbx | `R[a] = sbx` (small-integer immediate; avoids a constant) |
| `LOADBOOL` | a b | `R[a] = (b ~= 0)` |
| `LOADNIL` | a b | `R[a..a+b] = nil` |

## Globals
| `GETGLOBAL` | a bx | `R[a] = ENV[K[bx]]` |
| `SETGLOBAL` | a bx | `ENV[K[bx]] = R[a]` |

## Cells & upvalues
| `NEWCELL` | a | `R[a] = { v = R[a] }` (box a captured local) |
| `GETCELL` | a b | `R[a] = R[b].v` |
| `SETCELL` | a b | `R[a].v = R[b]` |
| `GETUPVAL` | a b | `R[a] = U[b].v` |
| `SETUPVAL` | a b | `U[b].v = R[a]` |

## Tables
| `NEWTABLE` | a | `R[a] = {}` |
| `GETTABLE` | a b c | `R[a] = R[b][R[c]]` |
| `SETTABLE` | a b c | `R[a][R[b]] = R[c]` |
| `GETFIELD` | a b bx | `R[a] = R[b][K[bx]]` |
| `SETFIELD` | a bx c | `R[a][K[bx]] = R[c]` |
| `SELF` | a b c | `R[a+1] = R[b]; R[a] = R[b][K[c]]` (method prep) |
| `SETLIST` | a b c | `R[a][c+i] = R[a+i]`, i=1..b (b=0 → up to top) |

## Arithmetic / bitwise / concat / unary
`ADD SUB MUL DIV MOD POW IDIV` and `BAND BOR BXOR SHL SHR` : `a b c` → `R[a] = R[b] op R[c]`
(bitwise via `bitops`, 32-bit; `IDIV` via `math.floor`).
`CONCAT` : `a b c` → `R[a] = R[b] .. … .. R[c]`.
`UNM NOT LEN BNOT` : `a b` → `R[a] = op R[b]`.

## Comparison
`EQ LT LE` : `a b c` → `R[a] = R[b] op R[c]`. The compiler derives `~= > >= <`
by swapping operands / negating with `NOT`.

## Control flow
| `JMP` | sbx | `pc += sbx` |
| `JMPIF` | a sbx | `if R[a] then pc += sbx` |
| `JMPIFNOT` | a sbx | `if not R[a] then pc += sbx` |

## Calls / returns
| `CALL` | a b c | call `R[a]` with `b-1` args (b=0 → to top); keep `c-1` results (c=0 → all, set top) |
| `TAILCALL` | a b | `return R[a](b-1 args)` (result-preserving; no host frame elision) |
| `RETURN` | a b | return `R[a..a+b-2]` (b=0 → to top) |

## Closures / varargs
| `CLOSURE` | a bx | `R[a] = closure(protos[bx], captured upvals)` |
| `VARARG` | a b | `R[a..a+b-2] = ...` (b=0 → to top) |

## Loops
| `FORPREP` | a sbx | numeric-for init; jump to the matching `FORLOOP` |
| `FORLOOP` | a sbx | step + test; if continuing set loop var `R[a+3]` and jump to body |
| `TFORCALL` | a c | generic-for: call iterator `R[a](R[a+1],R[a+2])`, `c` results into `R[a+3..]` |
| `TFORLOOP` | a sbx | if `R[a+3] ~= nil` then `R[a+2] = R[a+3]`; jump to body |

`NOP` — placeholder removed by the peephole pass.

## Superinstruction opportunities (future)

Fusing frequently paired ops reduces dispatch: `LOADK`+`CALL` for builtin calls,
`GETGLOBAL`+`CALL` (a global function call is the hottest pattern), `ADD`/`SUB`
with an immediate (`ADDI`), and `EQ`/`LT`+`JMPIFNOT` into a compare-and-branch.
These slot in behind the existing operand-layout table without touching the
compiler's structure — see the dev guide.
