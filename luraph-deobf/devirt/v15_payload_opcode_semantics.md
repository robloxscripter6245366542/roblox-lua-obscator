# v15 payload-VM opcode semantics — `../sample_v15.lua`

Pc variable: `w`. Built by parsing the exact AST of each dispatch loop's if/elseif chain (see `v15_payload_opcodes.py`), not guesswork.

## mode 0 — `M=o[w]`

| opcode | dyn. count | category | calls | arrays touched |
|---|---|---|---|---|
| 48 | 140018 | ARITH/MOVE |  | E R k |
| 40 | 119998 | JUMP |  | E R k r |
| 51 | 99988 | JUMP |  | E R k r |
| 49 | 39997 | ARITH/MOVE |  | E R k r |
| 50 | 20047 | CALL | G | E k |
| 6 | 19995 | ARITH/MOVE |  | E R k r |
| 22 | 19995 | ARITH/MOVE |  | E R k r |
| 52 | 50 | JUMP | S b h j | A E f k r |
| 19 | 46 | RETURN |  |  |
| 53 | 40 | ARITH/MOVE |  | E R k |
| 1 | 0 | CALL | m | E R V k |
| 2 | 0 | CALL | g x | E R k r |
| ?<28&<14&<7&<3&<1 | 0 | ARITH/MOVE |  | R k |
| 3..4 | 0 | ARITH/MOVE |  | B F R k r |
| 5 | 0 | ARITH/MOVE |  | E R k r |
| 9 | 0 | ARITH/MOVE |  | E R k r |
| 8 | 0 | CALL |  | R k |
| 7 | 0 | CALL | q | E R k |
| 13 | 0 | CALL | Q | R k |
| 12 | 0 | ARITH/MOVE |  | E R k |
| 10 | 0 | ARITH/MOVE |  | E R V |
| 11 | 0 | ARITH/MOVE |  | E R k r |
| 16 | 0 | ARITH/MOVE |  | E R k r |
| 15 | 0 | ARITH/MOVE |  | E R k r |
| 14 | 0 | ARITH/MOVE |  | E R r |
| 20 | 0 | ARITH/MOVE |  | B E F R k r |
| 18 | 0 | CALL | m | E R k r |
| 17 | 0 | ARITH/MOVE |  | E R V n |
| 21 | 0 | ARITH/MOVE |  | E R k r |
| 23 | 0 | ARITH/MOVE |  | E R k r |
| 24 | 0 | ARITH/MOVE |  | B F n r |
| 25 | 0 | ARITH/MOVE |  | E R k r |
| 26 | 0 | CALL | G | E R i k r |
| 27 | 0 | LOOP-EXIT|JUMP |  | E r |
| 47 | 0 | ARITH/MOVE |  | E R k r |
| 45 | 0 | ARITH/MOVE |  | E R k r |
| 46 | 0 | ARITH/MOVE |  | E R n r |
| 44 | 0 | ARITH/MOVE |  | R k r t |
| 43 | 0 | CALL |  | E R k |
| 42 | 0 | ARITH/MOVE |  | E R k r |
| ?>=28&>=42&>=49&>=52&>=54&~=55 | 0 | CALL |  | E R k |
| 55 | 0 | ARITH/MOVE |  | B E F R k |
| 41 | 0 | JUMP | S b h j | A E U f k r |
| 39 | 0 | JUMP | S b h j | E U f k r |
| 38 | 0 | ARITH/MOVE |  | E R k r |
| 35 | 0 | CALL | G | E R k r |
| 36 | 0 | LOOP | j m | E k o r |
| 37 | 0 | CALL | G p x | E R r |
| 34 | 0 | ARITH/MOVE |  | E R k r |
| 33 | 0 | CALL |  | E R k r |
| 31 | 0 | ARITH/MOVE |  | B E F R V k |
| 32 | 0 | ARITH/MOVE |  | B E F R k r |
| 28 | 0 | ARITH/MOVE |  | E R k r |
| 29..30 | 0 | JUMP |  | E R |

## mode 1 — `M=E[w]`

| opcode | dyn. count | category | calls | arrays touched |
|---|---|---|---|---|
| 21 | 74 | ARITH/MOVE |  | R k r |
| 54 | 60 | JUMP |  | o |
| 13 | 60 | JUMP |  | R r |
| 24 | 49 | ARITH/MOVE |  | R o r |
| 58 | 46 | JUMP | S b h j | A f k o p r |
| 14 | 34 | JUMP |  | R k o r |
| 20 | 30 | JUMP |  | R k o r |
| 28 | 16 | ARITH/MOVE |  | R k o r |
| 25 | 14 | ARITH/MOVE |  | B F R k o |
| 44 | 9 | ARITH/MOVE |  | R k o r |
| 42 | 7 | LOOP-EXIT|JUMP |  | k o |
| 40 | 7 | ARITH/MOVE |  | R k o r |
| 27 | 7 | LOOP | j m | E k o r |
| 43 | 0 | ARITH/MOVE |  | R k o r |
| 41 | 0 | ARITH/MOVE |  | R k o |
| 37 | 0 | JUMP | S b h j | A f k o p r |
| 36 | 0 | ARITH/MOVE |  | R k o r |
| 38 | 0 | CALL |  | R o r |
| 39 | 0 | ARITH/MOVE |  | R n r v |
| 30 | 0 | ARITH/MOVE |  | R k |
| 29 | 0 | ARITH/MOVE |  | R k o r |
| 34 | 0 | ARITH/MOVE |  | R k o r |
| 35 | 0 | ARITH/MOVE |  | B F R k o r |
| 32 | 0 | CALL |  | R k r v |
| 33 | 0 | ARITH/MOVE |  | R k o r |
| 50 | 0 | ARITH/MOVE |  | R o r t |
| 49 | 0 | ARITH/MOVE |  | R k o r |
| 48 | 0 | ARITH/MOVE |  | C |
| 47 | 0 | ARITH/MOVE |  | R k o |
| 46 | 0 | CALL | G | R k o r |
| 45 | 0 | JUMP | e | R k r |
| 53 | 0 | ARITH/MOVE |  | B F R k o r |
| 52 | 0 | ARITH/MOVE |  | R n o r |
| 51 | 0 | ARITH/MOVE |  | Q R k r v |
| ?>=29&>=44&>=51&>=55&>=57&~=58 | 0 | ARITH/MOVE |  | R k o r |
| 56 | 0 | RETURN |  | R Z f n |
| 55 | 0 | ARITH/MOVE |  | R k o r |
| 7 | 0 | ARITH/MOVE |  | R k o r |
| 8 | 0 | RETURN |  | R Z f |
| 9 | 0 | CALL | G | R k o r |
| 11 | 0 | CALL |  | R k o r |
| 10 | 0 | ARITH/MOVE |  | B F R k o |
| 12 | 0 | CALL |  | R r |
| 1 | 0 | LOOP | H | F K R U V f k p t v |
| 2 | 0 | JUMP |  | R k o r |
| ?<29&<14&<7&<3&<1 | 0 | ARITH/MOVE |  | R n r |
| 4 | 0 | JUMP | Q c | R k o |
| 3 | 0 | ARITH/MOVE |  | R V k o |
| 5 | 0 | ARITH/MOVE |  | R k o r |
| 6 | 0 | ARITH/MOVE |  | R Z f k |
| 23 | 0 | ARITH/MOVE |  | R k o r |
| 22 | 0 | CALL |  | R k o r |
| 26 | 0 | ARITH/MOVE |  | R k o r |
| 15 | 0 | CALL | q | R o r |
| 16 | 0 | LOOP | X m s | E U k o p r |
| 18 | 0 | JUMP | S b h j | f k o p r |
| 17 | 0 | CALL | G g x | R k o r |
| 19 | 0 | CALL | Q | R r |

## mode 2 — `M=r[w]`

| opcode | dyn. count | category | calls | arrays touched |
|---|---|---|---|---|
| 16 | 2130696 | JUMP |  | o |
| 88 | 2130696 | JUMP |  | R k |
| 61 | 1824879 | JUMP |  | E R k o |
| 50 | 1674300 | ARITH/MOVE |  | E R o |
| 53 | 911436 | CALL | m | E R k o |
| 45 | 761854 | ARITH/MOVE |  | E R k o |
| 70 | 759508 | ARITH/MOVE |  | E R o |
| 54 | 759155 | CALL | j | E R k o |
| 5 | 607325 | ARITH/MOVE |  | E R o t |
| 90 | 458356 | JUMP |  | E R k o |
| 91 | 456345 | JUMP |  | E R o |
| 20 | 305168 | ARITH/MOVE |  | E R k o |
| 86 | 303761 | ARITH/MOVE |  | E R k o |
| 29 | 303662 | CALL | Q | R k |
| 33 | 0 | RETURN |  | R Z f |
| 34 | 0 | ARITH/MOVE |  | E R k o |
| 32 | 0 | CALL |  | E R k |
| 38 | 0 | ARITH/MOVE |  | E R n o |
| 37 | 0 | CALL | S | R k o |
| 36 | 0 | CALL | h | E R k o |
| 35 | 0 | CALL | g x | E R k o |
| 27 | 0 | ARITH/MOVE |  | E R k o |
| 28 | 0 | JUMP | S b h j | E U f k o p |
| 26 | 0 | ARITH/MOVE |  | E R k o |
| 31 | 0 | ARITH/MOVE |  | E R k o |
| 30 | 0 | ARITH/MOVE |  | E R k o |
| 51..52 | 0 | ARITH/MOVE |  | E R k o |
| 49 | 0 | ARITH/MOVE |  | B E F R k o |
| 48 | 0 | ARITH/MOVE |  | R Z f k |
| 47 | 0 | ARITH/MOVE |  | E R o |
| 46 | 0 | ARITH/MOVE |  | R o |
| 44 | 0 | ARITH/MOVE |  | E R k o |
| 42 | 0 | JUMP | S b h j | E k o p r |
| 43 | 0 | CALL |  | R k o |
| 40 | 0 | JUMP | S b h j | A E k o p |
| 41 | 0 | RETURN |  | R Z f o |
| 39 | 0 | ARITH/MOVE |  | E R k o |
| 15 | 0 | CALL | j | E R n o |
| 14 | 0 | CALL | j | E R k o |
| 13 | 0 | CALL | g | E R k o |
| 18 | 0 | CALL | b h j | E R k o |
| 17 | 0 | ARITH/MOVE |  | R d k o |
| 19 | 0 | CALL | b h j | E R n o |
| 21 | 0 | ARITH/MOVE |  | B E F R k o |
| 22 | 0 | ARITH/MOVE |  | E R k o |
| 23 | 0 | JUMP | S b h j | E K f k o p |
| 24 | 0 | ARITH/MOVE |  | E R k v |
| 25 | 0 | JUMP |  | E R k o t |
| 4 | 0 | ARITH/MOVE |  | E R k o |
| 3 | 0 | ARITH/MOVE |  | E R k |
| 1 | 0 | CALL | G g x | E R k o |
| 2 | 0 | CALL | b | E R k o |
| ?<53&<26&<13&<6&<3&<1 | 0 | CALL |  | E R k o |
| 10 | 0 | ARITH/MOVE |  | E R k o |
| 9 | 0 | CALL | l | E R k o |
| 11 | 0 | JUMP |  | E R k o |
| 12 | 0 | ARITH/MOVE |  | E R k o |
| 7 | 0 | ARITH/MOVE |  | E R k o |
| 8 | 0 | JUMP |  | E R k o |
| 6 | 0 | JUMP |  | E R o |
| 87 | 0 | ARITH/MOVE |  | B E F R k |
| 85 | 0 | ARITH/MOVE |  | R d k v |
| 89 | 0 | CALL | m | R d k o |
| 84 | 0 | ARITH/MOVE |  | B F n o |
| 83 | 0 | ARITH/MOVE |  | E R k o |
| 82 | 0 | ARITH/MOVE |  | E R k o |
| 79 | 0 | CALL |  | E R k o |
| 81 | 0 | CALL | b h j | R d n o |
| 80 | 0 | ARITH/MOVE |  | E R n o |
| 101 | 0 | CALL |  | R o |
| 100 | 0 | ARITH/MOVE |  | E R k o |
| 99 | 0 | LOOP |  | E R k |
| ?>=53&>=79&>=92&>=99&>=102&>=104&~=105 | 0 | JUMP |  | E R k o |
| 105 | 0 | CALL | b h j | E R n o |
| 102 | 0 | ARITH/MOVE |  | E R k o |
| 103 | 0 | JUMP | S b h j | E f k o p |
| 98 | 0 | ARITH/MOVE |  | E R o |
| 97 | 0 | ARITH/MOVE |  | E R k o |
| 95 | 0 | JUMP |  | E R o |
| 96 | 0 | LOOP-EXIT|JUMP |  | E o |
| 93 | 0 | JUMP | S b h j | E U f k o p |
| 94 | 0 | ARITH/MOVE |  | R d k o |
| 92 | 0 | ARITH/MOVE |  | E R k o |
| 55 | 0 | ARITH/MOVE |  | E R k o |
| 58 | 0 | ARITH/MOVE |  | E R k o |
| 57 | 0 | CALL | G | E R k o |
| 56 | 0 | CALL | q | E R o |
| 65 | 0 | ARITH/MOVE |  | E R k o |
| 64 | 0 | ARITH/MOVE |  | R k o |
| 63 | 0 | ARITH/MOVE |  | B E F R k |
| 62 | 0 | JUMP |  | E R o |
| 60 | 0 | LOOP | X m s | E U k o p r |
| 59 | 0 | JUMP |  | E R k o |
| 72 | 0 | ARITH/MOVE |  | R n o |
| 74 | 0 | ARITH/MOVE |  | E R k t |
| 73 | 0 | ARITH/MOVE |  | R o |
| 76 | 0 | ARITH/MOVE |  | R k t v |
| 75 | 0 | CALL | m | E R n o |
| 77 | 0 | CALL | b h j | E R k o |
| 78 | 0 | CALL | l | E R k o |
| 67 | 0 | ARITH/MOVE |  | R o |
| 68 | 0 | JUMP |  | E R k o |
| 66 | 0 | LOOP | j m | E k o r |
| 69 | 0 | LOOP | H | E F K R U f n p t v |
| 71 | 0 | CALL | l | R d k v |

## mode 3 — `M=o[w]`

| opcode | dyn. count | category | calls | arrays touched |
|---|---|---|---|---|
| 8 | 94 | ARITH/MOVE |  | E R r |
| 14 | 93 | JUMP |  | R k |
| 38 | 93 | JUMP |  | E |
| 40 | 87 | JUMP | S b h j | B E L k q r |
| 46 | 79 | JUMP |  | E R k r |
| 29 | 46 | ARITH/MOVE |  | E R r t |
| 77 | 45 | LOOP | X m s | E L k o p r |
| 23 | 45 | CALL |  | E R n r |
| 78 | 33 | LOOP | j m | E k o r |
| 24 | 33 | ARITH/MOVE |  | R k r |
| 88 | 22 | JUMP |  | E R r |
| 67 | 22 | JUMP |  | E R k r |
| 27 | 21 | JUMP | S b h j | E L k p r s |
| 42 | 18 | LOOP | H | F L R d g n q r t x |
| 85 | 0 | ARITH/MOVE |  | E R k r |
| 84 | 0 | ARITH/MOVE |  | R d k t |
| 83 | 0 | CALL | b h j | E R k r |
| ?>=44&>=66&>=77&>=83&>=86&>=87&~=88 | 0 | CALL | g x | E R k r |
| 86 | 0 | ARITH/MOVE |  | E R k r |
| 82 | 0 | CALL | G g x | E R k r u |
| 81 | 0 | RETURN |  | E R Z r v |
| 80 | 0 | CALL | b h j | E R k r |
| 79 | 0 | ARITH/MOVE |  | E R k r |
| 71 | 0 | ARITH/MOVE |  | E Q R V k |
| 73 | 0 | RETURN |  | R Z p r |
| 72 | 0 | RETURN |  | R Z n p |
| 74 | 0 | CALL | S | E R r |
| 76 | 0 | ARITH/MOVE |  | E R k r |
| 75 | 0 | ARITH/MOVE |  | N R V k |
| 68 | 0 | CALL |  | E R k r |
| 70 | 0 | CALL | g x | E R k r |
| 69 | 0 | ARITH/MOVE |  | R d k r |
| 66 | 0 | CALL | G | E R i k r |
| 48 | 0 | ARITH/MOVE |  | E R |
| 47 | 0 | CALL |  | E R |
| 44 | 0 | ARITH/MOVE |  | E R n r |
| 45 | 0 | ARITH/MOVE |  | E R V k |
| 53 | 0 | ARITH/MOVE |  | B E F R k |
| 54 | 0 | CALL | b h j | E R V k |
| 52 | 0 | ARITH/MOVE |  | E R k r |
| 49 | 0 | ARITH/MOVE |  | E R k r |
| 50 | 0 | ARITH/MOVE |  | E R k r |
| 51 | 0 | CALL | G g x | E R k r |
| 58 | 0 | ARITH/MOVE |  | E R V n |
| 59 | 0 | ARITH/MOVE |  | E R k r |
| 57 | 0 | CALL | Q | R k |
| 55 | 0 | CALL | G | E R k r |
| 56 | 0 | CALL | j | E R k r |
| 62 | 0 | CALL | m | E R k r |
| 61 | 0 | JUMP | e | E R k |
| 60 | 0 | ARITH/MOVE |  | E R Z p |
| 63 | 0 | ARITH/MOVE |  | E R |
| 64 | 0 | RETURN | g | R Z k p |
| 65 | 0 | ARITH/MOVE |  | E R k |
| 1 | 0 | ARITH/MOVE |  | R k |
| ?<44&<22&<11&<5&<2&~=1 | 0 | ARITH/MOVE |  | d n t |
| 3 | 0 | ARITH/MOVE |  | E R k t |
| 4 | 0 | ARITH/MOVE |  | E R k r |
| 2 | 0 | CALL | x | E R k r |
| 9..10 | 0 | CALL |  | E R r |
| 5 | 0 | ARITH/MOVE |  | R k r |
| 7 | 0 | JUMP | S b h j | E L k p r s v |
| 6 | 0 | ARITH/MOVE |  | B E F R r |
| 12 | 0 | ARITH/MOVE |  | E R k |
| 11 | 0 | ARITH/MOVE |  | E R k r |
| 15 | 0 | ARITH/MOVE |  | E R k r |
| 13 | 0 | ARITH/MOVE |  | E R k r |
| 17 | 0 | ARITH/MOVE |  | R n r |
| 18 | 0 | ARITH/MOVE |  | C |
| 16 | 0 | ARITH/MOVE |  | E R V k |
| 19 | 0 | ARITH/MOVE |  | E R V n |
| 21 | 0 | CALL |  | E R V k |
| 20 | 0 | JUMP | S b h j | E L k p r |
| 30 | 0 | CALL |  | E R k r |
| 32 | 0 | ARITH/MOVE |  | E R k r |
| 31 | 0 | ARITH/MOVE |  | R d k r |
| 28 | 0 | ARITH/MOVE |  | R d k t |
| 22 | 0 | CALL | q | E R k |
| 25 | 0 | ARITH/MOVE |  | E R k r |
| 26 | 0 | JUMP | Q c | E R r |
| 33 | 0 | JUMP | S b h j | E L k p r |
| 34 | 0 | CALL |  | E R k |
| 35 | 0 | ARITH/MOVE |  | E R k r |
| 36 | 0 | CALL | G g x | E R i k r |
| 37 | 0 | CALL | l | E R k r |
| 43 | 0 | ARITH/MOVE |  | E R k r |
| 41 | 0 | JUMP | S b h j | B E k q r |
| 39 | 0 | RETURN |  | B R Z |

