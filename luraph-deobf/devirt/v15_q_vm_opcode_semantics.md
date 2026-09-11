# v15 payload-VM opcode semantics — `sample_v15.lua`

Pc variable: `Q`. Built by parsing the exact AST of each dispatch loop's if/elseif chain (see `v15_payload_opcodes.py`), not guesswork.

## mode 0 — `J=n[Q]`

| opcode | dyn. count | category | calls | arrays touched |
|---|---|---|---|---|
| 36 | 0 | JUMP |  | D P W f |
| 38 | 0 | ARITH/MOVE |  | D W f |
| 37 | 0 | RETURN | z | D H P W _ f |
| 35 | 0 | RETURN | z | D H P _ |
| 34 | 0 | ARITH/MOVE |  | B D E W f |
| 32 | 0 | CALL |  | D E W f |
| 33 | 0 | JUMP | BZ LZ MZ mZ | H P W _ f s |
| 31 | 0 | ARITH/MOVE |  | B D P W |
| 29 | 0 | ARITH/MOVE |  | D P f |
| 30 | 0 | JUMP |  | f |
| 27 | 0 | JUMP |  | D P f |
| 28 | 0 | CALL | N | D P W f |
| 26 | 0 | JUMP |  | D P f o |
| 25 | 0 | ARITH/MOVE |  | B D P W l |
| 24 | 0 | CALL | xZ | D P W f |
| 19..20 | 0 | ARITH/MOVE |  | D H P _ |
| 21 | 0 | JUMP | BZ LZ MZ mZ | H P W X f s |
| 22 | 0 | ARITH/MOVE |  | D P f o |
| 23 | 0 | CALL |  | D P f o |
| 13 | 0 | ARITH/MOVE |  | D P W f |
| 12 | 0 | CALL | N xZ z | D P W f |
| 11 | 0 | ARITH/MOVE |  | D E W f |
| 10 | 0 | JUMP |  | D P W f |
| 9 | 0 | JUMP | BZ LZ MZ mZ | H P W c f |
| 15 | 0 | ARITH/MOVE |  | D P W f |
| 14 | 0 | JUMP | BZ LZ MZ mZ | H P W c f s |
| 16 | 0 | CALL | z | D P W f |
| 18 | 0 | ARITH/MOVE |  | D P W f |
| 17 | 0 | ARITH/MOVE |  | D P W f |
| ?<39&<19&<9&<4&<2&~=1 | 0 | ARITH/MOVE |  | D E f o |
| 1 | 0 | ARITH/MOVE |  | D P W f |
| 2 | 0 | ARITH/MOVE |  | D E f o |
| 3 | 0 | CALL | xZ | P f |
| 6 | 0 | JUMP | BZ LZ MZ gZ | H P W _ c f s |
| 8 | 0 | LOOP | GZ MZ OZ | H P W f n s |
| 7 | 0 | CALL | N xZ z | D P S W f |
| 4 | 0 | ARITH/MOVE |  | D I P W |
| 5 | 0 | ARITH/MOVE |  | D P W f |
| 54 | 0 | ARITH/MOVE |  | D P |
| 55 | 0 | ARITH/MOVE |  | B E f o |
| 58 | 0 | LOOP | LZ MZ | P W f n |
| 57 | 0 | CALL |  | D P W f |
| 56 | 0 | ARITH/MOVE |  | D P W f |
| 50 | 0 | CALL | N z | D P W f |
| 49 | 0 | RETURN |  | D H _ |
| 53 | 0 | ARITH/MOVE |  | D P W |
| 52 | 0 | ARITH/MOVE |  | D P f o |
| 51 | 0 | CALL |  | D W f |
| 44 | 0 | ARITH/MOVE |  | D P W f |
| 45 | 0 | ARITH/MOVE |  | B D P W l |
| 48 | 0 | CALL |  | D f o |
| 47 | 0 | LOOP-EXIT|JUMP |  | P W |
| 46 | 0 | ARITH/MOVE |  | D I R W |
| 40 | 0 | CALL |  | D P f o |
| 39 | 0 | ARITH/MOVE |  | D I P W |
| 42 | 0 | ARITH/MOVE |  | D I P |
| 43 | 0 | JUMP |  | D P W f |
| 41 | 0 | ARITH/MOVE |  | B f l o |
| 66 | 0 | ARITH/MOVE |  | D E W f m |
| 67 | 0 | JUMP | hZ m | D W f |
| 68 | 0 | CALL |  | D W f |
| 65 | 0 | LOOP | bZ | D E F H X c f l o t |
| 64 | 0 | JUMP | v | D P W |
| 63 | 0 | CALL |  | D P W f |
| 62 | 0 | JUMP |  | D P W f |
| 61 | 0 | ARITH/MOVE |  | D P W f |
| 59 | 0 | ARITH/MOVE |  | B D P W f |
| 60 | 0 | ARITH/MOVE |  | D P f o |
| 74 | 0 | CALL | m | D P |
| 75 | 0 | ARITH/MOVE |  | D I P W |
| 76 | 0 | ARITH/MOVE |  | D P W f |
| 78 | 0 | ARITH/MOVE |  | C |
| ?>=39&>=59&>=69&>=74&>=76&>=77&~=78 | 0 | CALL | SZ xZ z | D P f |
| 70 | 0 | CALL |  | D f |
| 69 | 0 | JUMP |  | D P |
| 72 | 0 | JUMP | BZ LZ MZ gZ | J P W _ f |
| 73 | 0 | ARITH/MOVE |  | D P W f |
| 71 | 0 | JUMP |  | D P f |

## mode 1 — `J=P[Q]`

| opcode | dyn. count | category | calls | arrays touched |
|---|---|---|---|---|
| 11 | 0 | ARITH/MOVE |  | D T W f m |
| 12 | 0 | JUMP | v | D W f |
| 14 | 0 | JUMP | BZ LZ MZ mZ | H W c f n |
| 13 | 0 | CALL |  | D W n |
| 8 | 0 | ARITH/MOVE |  | D f n |
| 7 | 0 | JUMP |  | f |
| 10 | 0 | LOOP-EXIT|JUMP |  | f n |
| 9 | 0 | ARITH/MOVE |  | D W |
| 5 | 0 | CALL |  | D W n |
| 6 | 0 | ARITH/MOVE |  | D W f n |
| 4 | 0 | ARITH/MOVE |  | D W f n |
| 3 | 0 | JUMP | BZ LZ MZ gZ | H W _ f n |
| 1 | 0 | ARITH/MOVE |  | D T f |
| 2 | 0 | CALL | m | D n |
| ?<31&<15&<7&<3&<1 | 0 | ARITH/MOVE |  | D W f n |
| 29 | 0 | LOOP | LZ MZ | P W f n |
| 30 | 0 | JUMP |  | D W |
| 28 | 0 | JUMP |  | D W f n |
| 27 | 0 | CALL |  | D f |
| 24 | 0 | CALL |  | D W f n |
| 23 | 0 | CALL | z | D W f n |
| 26 | 0 | JUMP | hZ m | D f n |
| 25 | 0 | ARITH/MOVE |  | D T W f |
| 19 | 0 | ARITH/MOVE |  | B D W l n |
| 20 | 0 | CALL | N xZ z | D S W f n |
| 22 | 0 | ARITH/MOVE |  | D f n o |
| 21 | 0 | JUMP |  | D W f n |
| 15 | 0 | LOOP | bZ | D F H I X c l n o t |
| 16 | 0 | ARITH/MOVE |  | D W f |
| 18 | 0 | ARITH/MOVE |  | D W f n |
| 17 | 0 | JUMP | BZ LZ MZ mZ | H W _ c f n |
| 46 | 0 | ARITH/MOVE |  | D W f n |
| 47 | 0 | ARITH/MOVE |  | C |
| 49 | 0 | JUMP |  | D f n |
| 48 | 0 | ARITH/MOVE |  | D f n o |
| 53 | 0 | ARITH/MOVE |  | D W f n |
| 52 | 0 | ARITH/MOVE |  | D W f n |
| 51 | 0 | ARITH/MOVE |  | B T W l |
| 50 | 0 | ARITH/MOVE |  | B D W f n |
| 54 | 0 | RETURN | N z | D H W _ f n |
| 55 | 0 | ARITH/MOVE |  | D f n |
| 57 | 0 | JUMP |  | D W f n |
| 56 | 0 | RETURN |  | D H _ |
| 58 | 0 | CALL | N xZ z | D W f n |
| 59 | 0 | CALL |  | D W f n |
| 61 | 0 | JUMP |  | D f n |
| ?>=31&>=46&>=54&>=58&>=60&~=61 | 0 | ARITH/MOVE |  | D W f n |
| 31 | 0 | CALL |  | D T W f |
| 32 | 0 | LOOP | GZ MZ OZ | H P W f n s |
| 33 | 0 | CALL |  | D f n o |
| 35 | 0 | ARITH/MOVE |  | B D T W f |
| 34 | 0 | ARITH/MOVE |  | D I T W |
| 36 | 0 | ARITH/MOVE |  | D R T f |
| 37 | 0 | ARITH/MOVE |  | B D W f l |
| 39 | 0 | CALL | xZ | D W f n |
| 41 | 0 | ARITH/MOVE |  | D W f n |
| 40 | 0 | ARITH/MOVE |  | B D W f |
| 43 | 0 | CALL | N | D W f n |
| 42 | 0 | ARITH/MOVE |  | D f n |
| 45 | 0 | CALL | N z | D W f n |
| 44 | 0 | ARITH/MOVE |  | D W f n |

## mode 2 — `J=f[Q]`

| opcode | dyn. count | category | calls | arrays touched |
|---|---|---|---|---|
| 27 | 0 | JUMP | v | D P W |
| 26 | 0 | ARITH/MOVE |  | D P |
| 24 | 0 | ARITH/MOVE |  | D P T |
| 25 | 0 | ARITH/MOVE |  | D P W n |
| 31 | 0 | JUMP | BZ LZ MZ gZ | H P W _ c n |
| 30 | 0 | ARITH/MOVE |  | D E W n |
| 28 | 0 | ARITH/MOVE |  | B D P T W |
| 29 | 0 | JUMP |  | D W n |
| 21 | 0 | ARITH/MOVE |  | D P W n |
| 20 | 0 | ARITH/MOVE |  | D P m n o |
| 23 | 0 | JUMP | BZ LZ MZ mZ | H P W _ n |
| 22 | 0 | ARITH/MOVE |  | D P n |
| 19 | 0 | ARITH/MOVE |  | B D P n o |
| 17 | 0 | CALL |  | D P n o |
| 16 | 0 | CALL | xZ | D P W n |
| 9 | 0 | ARITH/MOVE |  | B E T W |
| 8 | 0 | CALL |  | D P T |
| 10 | 0 | JUMP |  | D P W n |
| 11 | 0 | ARITH/MOVE |  | B D E W l n |
| 15 | 0 | ARITH/MOVE |  | B D P W |
| 14 | 0 | ARITH/MOVE |  | B D P W n |
| 13 | 0 | ARITH/MOVE |  | C |
| 12 | 0 | ARITH/MOVE |  | D E n o |
| 6 | 0 | ARITH/MOVE |  | D P W n |
| 7 | 0 | ARITH/MOVE |  | B D P W l |
| 4 | 0 | JUMP | N xZ z | D P W n |
| 5 | 0 | ARITH/MOVE |  | D P n o |
| 2 | 0 | LOOP | bZ | D F H P T X c l o t |
| 3 | 0 | ARITH/MOVE |  | B P l o |
| 1 | 0 | ARITH/MOVE |  | D E R W |
| ?<32&<16&<8&<4&<2&~=1 | 0 | ARITH/MOVE |  | D P n o |
| 54 | 0 | LOOP-EXIT|JUMP |  | P W |
| 55 | 0 | ARITH/MOVE |  | D P W n |
| 52 | 0 | ARITH/MOVE |  | D W n |
| 53 | 0 | ARITH/MOVE |  | D P W n |
| 48 | 0 | JUMP |  | D W n |
| 49 | 0 | ARITH/MOVE |  | D P W n |
| 50 | 0 | JUMP |  | P |
| 51 | 0 | CALL |  | D P W n |
| ?>=32&>=48&>=56&>=60&>=62&>=63&~=64 | 0 | RETURN |  | D H _ |
| 64 | 0 | ARITH/MOVE |  | D H _ n |
| 62 | 0 | LOOP | LZ MZ | P W f n |
| 61 | 0 | JUMP |  | D P |
| 60 | 0 | ARITH/MOVE |  | D P W n |
| 58 | 0 | CALL | N xZ z | D P W n |
| 59 | 0 | LOOP | GZ MZ OZ | H P W f n s |
| 57 | 0 | JUMP | hZ m | D W n |
| 56 | 0 | ARITH/MOVE |  | D P W n |
| 37 | 0 | JUMP | BZ LZ MZ mZ | H P W c n |
| 36 | 0 | JUMP |  | D P W n |
| 39 | 0 | JUMP |  | D P W n |
| 38 | 0 | ARITH/MOVE |  | D P W n |
| 33 | 0 | ARITH/MOVE |  | D E W n |
| 32 | 0 | ARITH/MOVE |  | D P n o |
| 35 | 0 | CALL | N xZ z | D P S W n |
| 34 | 0 | CALL |  | D W |
| 46 | 0 | RETURN | z | D H W _ |
| 47 | 0 | CALL |  | D E W n |
| 45 | 0 | CALL |  | D P W |
| 44 | 0 | JUMP |  | D P n o |
| 42 | 0 | ARITH/MOVE |  | D W n |
| 43 | 0 | ARITH/MOVE |  | B D P W l |
| 41 | 0 | CALL | z | D P W n |
| 40 | 0 | CALL |  | D P W n |

## mode 3 — `J=n[Q]`

| opcode | dyn. count | category | calls | arrays touched |
|---|---|---|---|---|
| 56 | 0 | ARITH/MOVE |  | D H _ f |
| 57 | 0 | JUMP |  | D P W f |
| 55 | 0 | LOOP | GZ MZ OZ | H L P W f n |
| 54 | 0 | JUMP |  | D P W |
| 58 | 0 | LOOP | LZ MZ | P W f n |
| 59 | 0 | CALL |  | D E W f |
| 60 | 0 | ARITH/MOVE |  | B E f o |
| 62 | 0 | CALL | N xZ z | D P S W f |
| 61 | 0 | ARITH/MOVE |  | B D P W l |
| 65 | 0 | CALL |  | D P W f |
| 66 | 0 | JUMP | BZ LZ MZ gZ | L P W c f p |
| 67 | 0 | ARITH/MOVE |  | D P W f |
| 63 | 0 | ARITH/MOVE |  | D P W |
| 64 | 0 | JUMP |  | D P W f |
| 68 | 0 | ARITH/MOVE |  | D P W f |
| 69 | 0 | CALL |  | D P W f |
| 70 | 0 | ARITH/MOVE |  | D P W f |
| ?>=36&>=54&>=63&>=68&>=70&>=71&~=72 | 0 | ARITH/MOVE |  | D I P W |
| 72 | 0 | CALL |  | D E W f |
| 39 | 0 | ARITH/MOVE |  | D P W f |
| 38 | 0 | RETURN | z | D I L p |
| 37 | 0 | ARITH/MOVE |  | B D P W l |
| 36 | 0 | JUMP | BZ LZ MZ gZ | L P W f h p |
| 40 | 0 | JUMP | BZ LZ MZ mZ | L P W f p |
| 41 | 0 | JUMP | v | D W f |
| 42 | 0 | ARITH/MOVE |  | D P f o |
| 43 | 0 | ARITH/MOVE |  | D f |
| 44 | 0 | JUMP | hZ m | D P W |
| 51 | 0 | ARITH/MOVE |  | D P W f |
| 52 | 0 | ARITH/MOVE |  | D P f o |
| 53 | 0 | ARITH/MOVE |  | D E W f |
| 49 | 0 | CALL |  | D W f |
| 50 | 0 | JUMP |  | D P W f |
| 46 | 0 | ARITH/MOVE |  | D P W f |
| 45 | 0 | ARITH/MOVE |  | B D E W f |
| 47 | 0 | JUMP |  | P |
| 48 | 0 | ARITH/MOVE |  | D P W f |
| 10 | 0 | CALL |  | D E f |
| 9 | 0 | CALL | N xZ z | D P W f |
| 12 | 0 | JUMP |  | D f |
| 11 | 0 | ARITH/MOVE |  | D P W f |
| 13 | 0 | ARITH/MOVE |  | D P W f |
| 14 | 0 | ARITH/MOVE |  | D E W f m |
| 17 | 0 | ARITH/MOVE |  | D P W f |
| 16 | 0 | ARITH/MOVE |  | D P R o |
| ?<36&<18&<9&<4&<2&~=1 | 0 | CALL |  | D W |
| 1 | 0 | RETURN |  | D L p |
| 2 | 0 | ARITH/MOVE |  | D P W f |
| 3 | 0 | ARITH/MOVE |  | D I P o |
| 7 | 0 | ARITH/MOVE |  | D P f o |
| 8 | 0 | ARITH/MOVE |  | D P W f |
| 6 | 0 | ARITH/MOVE |  | B I W l |
| 5 | 0 | RETURN | z | D L f p |
| 4 | 0 | ARITH/MOVE |  | D P W f |
| 23 | 0 | ARITH/MOVE |  | D P W |
| 22 | 0 | JUMP | BZ LZ MZ mZ | H L P W f h |
| 26 | 0 | ARITH/MOVE |  | D P W f |
| 25 | 0 | ARITH/MOVE |  | D P W |
| 24 | 0 | CALL | z | D P W f |
| 21 | 0 | ARITH/MOVE |  | D E f |
| 20 | 0 | CALL | N | D P W f |
| 18 | 0 | LOOP | bZ | D E L _ c f h l o t |
| 19 | 0 | ARITH/MOVE |  | D P W f |
| 33 | 0 | JUMP | BZ LZ MZ mZ | H L P W c f |
| 35 | 0 | ARITH/MOVE |  | D P W f |
| 34 | 0 | ARITH/MOVE |  | D P W f |
| 31 | 0 | CALL |  | D W f |
| 32 | 0 | ARITH/MOVE |  | D E W f |
| 30 | 0 | JUMP | BZ LZ MZ mZ | L P W b f l |
| 29 | 0 | CALL |  | D I P W |
| 27 | 0 | ARITH/MOVE |  | B D W f |
| 28 | 0 | ARITH/MOVE |  | C |

