# v15 opcode/handler map — `sample_v15.lua`

- handlers defined: **145**, library slots: 83
- exercised (dynamic): **68**, never exercised: **77**
- MOVE/UNKNOWN (need manual semantics): **0**

| handler | arity | category | calls | successors | libs |
|---|---|---|---|---|---|
| `Mu` | 11 | FETCH|TABLE/CONST|BRANCH | 33363 | 5,8,23,33 | buffer.readu32 buffer.readu8 q |
| `Nu` | 10 | FETCH|BRANCH | 33246 | 0,10,13,19 | buffer.readu8 |
| `Lu` | 8 | FETCH|STORE/DECRYPT|BRANCH | 33026 | 14,19,37 | buffer.readu8 buffer.writeu32 |
| `ou` | 12 | FETCH|STRING|TABLE/CONST|BRANCH | 32932 | 14,23,37 | buffer.fromstring buffer.readu8 string.gsub string.sub |
| `hu` | 11 | FETCH|BRANCH | 32932 | 5,16,29 | buffer.readu8 |
| `j` | 10 | FETCH|BRANCH | 24807 | 11,46,69,112,114,140 | buffer.readu8 |
| `s` | 11 | FETCH|STORE/DECRYPT|BITWISE|BRANCH | 20532 | 19,51 | bit32.bxor buffer.readu8 buffer.writeu8 |
| `F` | 10 | FETCH|BRANCH | 11664 | 22,34,42,137,160,165 | buffer.readu8 |
| `Q` | 7 | FETCH|BRANCH | 6492 | 66,73 | buffer.readu8 |
| `o` | 10 | FETCH|BRANCH | 4277 | 56,133,140,157 | buffer.readu8 |
| `A` | 11 | FETCH|TABLE/CONST|BRANCH | 4277 | 42,117,137,159 | buffer.readu32 buffer.readu8 table.create |
| `z` | 11 | FETCH|BRANCH | 4276 | 8,41 | buffer.fill buffer.readu8 |
| `J` | 14 | FETCH|BRANCH | 4275 | 101,166 | buffer.readu8 |
| `L` | 10 | FETCH|TABLE/CONST|BRANCH | 4275 | 69 | buffer.readu8 table.create |
| `m` | 10 | FETCH|BRANCH | 4275 | 100,143,155,160 | buffer.readu8 |
| `S` | 10 | FETCH|BRANCH | 4275 | 112 | buffer.readu8 |
| `h` | 10 | FETCH|BRANCH | 4275 | 34,113,160 | buffer.readu8 |
| `x` | 10 | FETCH|BRANCH | 4275 | 27,81,135,144 | buffer.readu8 |
| `f` | 10 | FETCH|TABLE/CONST|BRANCH | 3788 | 64,133,157 | buffer.readu8 |
| `V` | 9 | FETCH|BRANCH | 3695 | 18,81,89 | buffer.readu8 |
| `Su` | 9 | FETCH|STORE/DECRYPT|BITWISE|BRANCH | 2341 | 6,124,159,238 | bit32.bxor buffer.create buffer.readu8 buffer.writeu8 |
| `Yu` | 13 | FETCH|STORE/DECRYPT|BITWISE|BRANCH | 2341 | 27,41,159 | bit32.bxor buffer.readf32 buffer.readu8 buffer.writeu8 vector.create |
| `k` | 11 | FETCH|BRANCH | 1746 | 18,64,113 | buffer.readu8 |
| `n` | 10 | TABLE/CONST|BRANCH | 1160 | 34,101,133 | table.create |
| `ku` | 7 | FETCH|BRANCH | 711 | 7,25 | buffer.readu8 |
| `X` | 12 | FETCH|BRANCH | 480 | 64,93,162 | buffer.readu8 |
| `ju` | 8 | FETCH|BRANCH | 397 | 5,14,19,26 | buffer.readu8 |
| `Ju` | 9 | FETCH|BRANCH | 382 | 1,2 | buffer.readu8 |
| `wu` | 3 | BITWISE | 374 |  | bit32.band bit32.lshift bit32.rshift |
| `fu` | 2 | ARITH | 282 |  |  |
| `Z` | 12 | FETCH|BRANCH | 13 | 73,89,143 | buffer.readu8 |
| `GA` | 6 | FETCH|BRANCH | 12 |  | buffer.readu8 |
| `t` | 12 | FETCH|TABLE/CONST|BRANCH | 11 | 135 | buffer.readu8 |
| `M` | 9 | FETCH|BRANCH | 10 | 3,127 | buffer.readu8 |
| `tA` | 12 | FETCH|BRANCH | 6 | 17,72,110,128 | buffer.readu8 |
| `YA` | 11 | FETCH|TABLE/CONST|BRANCH | 6 | 27,147,222 | buffer.create buffer.readu8 buffer.tostring |
| `NA` | 11 | FETCH|TABLE/CONST|BRANCH | 6 | 128,159 | buffer.readu8 table.create |
| `xA` | 7 | CALL/OTHER|BRANCH | 6 | 147,159,193 |  |
| `Au` | 1 | RESUME | 6 | 146 |  |
| `MA` | 13 | FETCH|STORE/DECRYPT|BITWISE|BRANCH | 6 | 49,144,194 | bit32.bxor buffer.create buffer.readu8 buffer.writeu8 |
| `KA` | 8 | BRANCH | 6 | 1,2 |  |
| `hA` | 12 | FETCH|TABLE/CONST|BRANCH | 6 | 109,128,159,185 | buffer.create buffer.readu8 buffer.tostring |
| `bu` | 11 | FETCH|TABLE/CONST|BRANCH | 5 | 100,185,228 | buffer.create buffer.readu8 |
| `R` | 11 | FETCH|BRANCH | 3 | 21,73,93,143 | buffer.readu8 |
| `I` | 12 | FETCH|TABLE/CONST|BRANCH | 3 | 19,51,78,136,143 | buffer.create buffer.readu32 buffer.readu8 |
| `D` | 8 | FETCH|TABLE/CONST|BRANCH | 2 | 65,159 | buffer.readu8 table.create |
| `i` | 9 | FETCH|BRANCH | 2 | 113,140 | buffer.readu8 |
| `d` | 10 | FETCH|BRANCH | 2 | 17,113,142 | buffer.readu8 |
| `P` | 10 | FETCH|BRANCH | 2 | 34 | buffer.readu8 |
| `ru` | 7 | FETCH|BRANCH | 2 | 0,1,24 | buffer.readu8 |
| `N` | 10 | FETCH|BRANCH | 2 | 18,55 | buffer.readu8 |
| `p` | 9 | FETCH|BRANCH | 2 | 1,2 | buffer.readu8 |
| `H` | 9 | FETCH|BRANCH | 1 | 140 | buffer.readu8 |
| `K` | 3 | TABLE/CONST | 1 |  |  |
| `Y` | 12 | BRANCH | 1 | 3,18,33,81,162,167 | H M |
| `XA` | 2 | CALL/OTHER | 1 |  |  |
| `53` | 6 | FETCH|STORE/DECRYPT|BITWISE|STRING|TABLE/CONST|BRANCH | 1 | 0,1,2,3,5,6,7,8 | M bit32.band bit32.bnot bit32.bor bit32.bxor bit32.lshift |
| `WA` | 7 | FETCH|BRANCH | 1 | 159 | buffer.readu8 |
| `au` | 8 | FETCH|BRANCH | 1 | 112 | buffer.readu8 |
| `wA` | 11 | FETCH|TABLE/CONST|BRANCH | 1 | 19,185,195 | buffer.create buffer.readu8 buffer.tostring |
| `y` | 9 | BRANCH | 1 | 55,127 | setmetatable |
| `Ku` | 1 | RESUME | 1 | 27 |  |
| `U` | 2 | RESUME | 1 | 36 | M |
| `u` | 11 | FETCH|BRANCH | 1 | 66,93,98,117 | buffer.readu8 |
| `c` | 11 | FETCH|BRANCH | 1 | 55,81 | buffer.readu8 |
| `Gu` | 7 | FETCH|BRANCH | 1 | 2,5,18 | buffer.copy buffer.create buffer.readu8 |
| `O` | 10 | FETCH|BRANCH | 1 | 85,127 | buffer.readu8 setmetatable |
| `Uu` | 8 | FETCH|TABLE/CONST|BRANCH | 1 | 26,28,32 | buffer.readu8 table.create |
| `Fu` | 9 | FETCH|BRANCH | - | 13 | buffer.readu8 |
| `Zu` | 13 | FETCH|STORE/DECRYPT|BITWISE | - | 159 | Vector2.new Vector3.new bit32.bxor buffer.readf32 buffer.readu8 buffer.writeu8 |
| `bA` | 11 | FETCH|STORE/DECRYPT|BITWISE|BRANCH | - | 34,64,112,159,226 | bit32.bxor buffer.readu32 buffer.readu8 buffer.writeu8 |
| `cu` | 10 | FETCH|TABLE/CONST|BRANCH | - | 32,71,177,193,196 | buffer.readu8 table.create |
| `FA` | 9 | FETCH|BRANCH | - | 165,187,226 | buffer.readu8 |
| `_A` | 15 | FETCH|STORE/DECRYPT|BITWISE|BRANCH | - | 13,37,128,154 | bit32.bxor buffer.readu8 buffer.writeu8 |
| `rA` | 12 | FETCH|STORE/DECRYPT|BITWISE|BRANCH | - | 13,67,91 | bit32.bxor buffer.create buffer.readu8 buffer.writeu8 |
| `BA` | 12 | FETCH|STORE/DECRYPT|BITWISE|BRANCH | - | 68,86,173,238 | bit32.bxor buffer.create buffer.readu8 buffer.writeu8 |
| `Iu` | 13 | FETCH|STORE/DECRYPT|BITWISE|STRING|TABLE/CONST|BRANCH | - | 39,96 | bit32.bxor buffer.readu8 buffer.writeu8 string.sub |
| `uu` | 11 | FETCH|STORE/DECRYPT|BITWISE|BRANCH | - | 60,121,147,232 | bit32.bxor buffer.create buffer.readu8 buffer.writeu8 |
| `gu` | 14 | FETCH|STORE/DECRYPT|BITWISE|BRANCH | - | 32,98,224 | bit32.bxor buffer.readu8 buffer.writeu8 |
| `e` | 2 | CALL/OTHER | - |  |  |
| `Qu` | 13 | FETCH|STORE/DECRYPT|BITWISE|BRANCH | - | 49,113 | bit32.bxor buffer.readu8 buffer.writeu8 |
| `G` | 12 | FETCH|TABLE/CONST|BRANCH | - | 79,89,160 | buffer.readu8 table.create |
| `E` | 9 | BRANCH | - | 3,66 |  |
| `28` | 6 | CALL/OTHER | - |  | M |
| `QA` | 10 | FETCH|TABLE/CONST|BRANCH | - | 159,181 | buffer.create buffer.fill buffer.readu8 |
| `Vu` | 8 | FETCH|BRANCH | - | 224 | buffer.readu8 |
| `vu` | 9 | FETCH|BRANCH | - | 138,159 | buffer.readu8 |
| `nA` | 15 | FETCH|STORE/DECRYPT|BITWISE|BRANCH | - | 41,159,219 | bit32.bxor buffer.readi16 buffer.readu8 buffer.writeu8 |
| `oA` | 6 | FETCH | - |  | buffer.readu8 |
| `nu` | 13 | FETCH|STORE/DECRYPT|BITWISE|BRANCH | - | 36,49 | bit32.bxor buffer.readu8 buffer.writeu8 |
| `B` | 13 | FETCH|BRANCH | - | 42,64 | buffer.readu8 |
| `Eu` | 13 | FETCH|STORE/DECRYPT|BITWISE|BRANCH | - | 2,39,99,122,159 | bit32.bxor buffer.readf32 buffer.readu8 buffer.writeu8 vector.create |
| `vA` | 15 | FETCH|STORE/DECRYPT|TABLE/CONST|BRANCH | - | 93,138,193,228 | buffer.create buffer.readu8 buffer.writeu8 |
| `EA` | 12 | FETCH|STORE/DECRYPT|BITWISE|BRANCH | - | 198 | bit32.bxor buffer.readu8 buffer.writeu8 |
| `pu` | 14 | FETCH|STORE/DECRYPT|BITWISE|BRANCH | - | 73,101,159 | bit32.bxor buffer.create buffer.readstring buffer.readu8 buffer.writeu8 |
| `Pu` | 11 | FETCH|STORE/DECRYPT|BITWISE|BRANCH | - | 41,201 | bit32.bxor buffer.readu8 buffer.writeu8 |
| `b` | 8 | FETCH|BRANCH | - | 3 | buffer.readu8 |
| `r` | 8 | FETCH|BRANCH | - | 127 | buffer.readu8 setmetatable |
| `iA` | 14 | FETCH|STORE/DECRYPT|BITWISE|BRANCH | - | 53,133,150,168 | bit32.bxor buffer.readu8 buffer.writeu8 |
| `yA` | 13 | FETCH|STORE/DECRYPT|BITWISE|STRING|BRANCH | - | 159,238 | bit32.bxor buffer.readf64 buffer.readu8 buffer.writeu8 string.sub |
| `113` | 4 | CALL/OTHER | - |  | M |
| `dA` | 13 | FETCH|STORE/DECRYPT|BITWISE|BRANCH | - | 121,195 | bit32.bxor buffer.readu8 buffer.writeu8 |
| `tu` | 4 | CALL/OTHER | - |  | coroutine.yield |
| `TA` | 13 | FETCH|STORE/DECRYPT|BITWISE|BRANCH | - | 19,233 | bit32.bxor buffer.readu8 buffer.writeu8 |
| `Ru` | 8 | TABLE/CONST|BRANCH | - | 31,108,167,228 | table.create |
| `SA` | 8 | FETCH|BRANCH | - | 41,193 | buffer.readu8 |
| `w` | 10 | FETCH|BRANCH | - | 55,93 | buffer.readu8 |
| `46` | 9 | FETCH|STORE/DECRYPT|BITWISE|STRING|TABLE/CONST|BRANCH | - | 0,1,2,3,5,6,7,8 | M bit32.band bit32.bnot bit32.bor bit32.bxor bit32.lshift |
| `du` | 9 | FETCH|BITWISE|BRANCH | - | 71,238 | bit32.band bit32.rshift buffer.readu8 |
| `CA` | 7 | FETCH|BRANCH | - | 83,122,219,232 | buffer.readu8 |
| `C` | 8 | FETCH|BRANCH | - | 89,135 | buffer.readu8 |
| `lA` | 14 | FETCH|STORE/DECRYPT|BITWISE|BRANCH | - | 56,57,88,162 | bit32.bxor buffer.readu8 buffer.writeu8 |
| `LA` | 13 | FETCH|STORE/DECRYPT|BITWISE|BRANCH | - | 50,55,172 | bit32.bxor buffer.create buffer.readu8 buffer.writeu8 |
| `fA` | 10 | FETCH|STORE/DECRYPT|BITWISE|BRANCH | - | 121,168,181 | bit32.bxor buffer.readu8 buffer.writeu8 |
| `kA` | 8 | FETCH|BRANCH | - | 66,104,159 | buffer.readu8 |
| `Tu` | 8 | FETCH|BRANCH | - | 112,133,135 | buffer.readu8 |
| `Xu` | 7 | FETCH|STORE/DECRYPT|BITWISE|BRANCH | - | 158,159,190 | bit32.bxor buffer.create buffer.readu8 buffer.writeu8 |
| `pA` | 11 | FETCH|STORE/DECRYPT|BITWISE|BRANCH | - | 0,94 | bit32.bxor buffer.readu8 buffer.writeu8 |
| `xu` | 6 | FETCH|BRANCH | - | 128,159 | buffer.readu8 |
| `g` | 10 | FETCH|TABLE/CONST|BRANCH | - | 66,79,85 | buffer.readu32 |
| `Hu` | 10 | FETCH|STORE/DECRYPT|BITWISE|STRING|BRANCH | - | 159,219 | bit32.bxor buffer.create buffer.readu8 buffer.writeu8 string.rep |
| `AA` | 8 | FETCH|BITWISE|BRANCH | - | 19,33 | bit32.bxor buffer.readu8 |
| `Cu` | 6 | BRANCH | - | 159,185,224 |  |
| `qA` | 14 | FETCH|STORE/DECRYPT|BITWISE|BRANCH | - | 43,159 | bit32.bxor buffer.create buffer.readu16 buffer.readu8 buffer.writeu8 |
| `cA` | 7 | FETCH|BRANCH | - | 32,168 | buffer.readu8 |
| `l` | 2 | CALL/OTHER | - |  |  |
| `su` | 7 | BRANCH | - | 10,153,224 |  |
| `eA` | 11 | FETCH|STORE/DECRYPT|BITWISE|BRANCH | - | 51,115 | bit32.bxor buffer.readu8 buffer.writeu8 |
| `Bu` | 14 | FETCH|STORE/DECRYPT|BITWISE|BRANCH | - | 100,122,159 | bit32.bxor buffer.readi32 buffer.readu8 buffer.writeu8 |
| `iu` | 4 | STRING | - |  | error string.match type |
| `JA` | 14 | FETCH|STORE/DECRYPT|BITWISE|BRANCH | - | 159,219 | bit32.bxor buffer.readu32 buffer.readu8 buffer.writeu8 |
| `UA` | 13 | FETCH|STORE/DECRYPT|BITWISE|BRANCH | - | 109,168,231 | bit32.bxor buffer.readu8 buffer.writeu8 |
| `OA` | 9 | FETCH|BRANCH | - | 73,128,226,228 | buffer.readu8 |
| `zu` | 13 | FETCH|STORE/DECRYPT|BRANCH | - | 128,186 | buffer.create buffer.readu8 buffer.writeu8 |
| `q` | 2 | STORE-NIL | - |  |  |
| `jA` | 13 | FETCH|STORE/DECRYPT|BITWISE|BRANCH | - | 75,135,147,218 | bit32.bxor buffer.readu8 buffer.writeu8 |
| `HA` | 10 | FETCH|STORE/DECRYPT|BITWISE|BRANCH | - | 3,212 | bit32.bxor buffer.create buffer.readu8 buffer.writeu8 |
| `v` | 11 | BRANCH | - | 42,61,73,149 |  |
| `DA` | 6 | CALL/OTHER|BRANCH | - | 13,167 |  |
| `VA` | 8 | BRANCH | - | 23,108,222 |  |
| `mu` | 11 | FETCH|STORE/DECRYPT|BITWISE|BRANCH | - | 95,191,204 | bit32.bxor buffer.create buffer.readu8 buffer.writeu8 |
| `75` | 3 | FETCH|STORE/DECRYPT|BITWISE|TABLE/CONST|BRANCH | - |  | bit32.band bit32.bor bit32.bxor bit32.lshift buffer.create buffer.len |
| `aA` | 14 | FETCH|STORE/DECRYPT|BITWISE|BRANCH | - | 7,32 | bit32.bxor buffer.readu8 buffer.writeu8 |
| `ZA` | 14 | FETCH|STORE/DECRYPT|BITWISE|BRANCH | - | 73,121,159 | bit32.bxor buffer.readf32 buffer.readu8 buffer.writeu8 |
| `sA` | 8 | TABLE/CONST|BRANCH | - | 33,49,73,159 | buffer.copy buffer.create table.create |
