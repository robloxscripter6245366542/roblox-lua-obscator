# sample_v15.lua — comparison-chain sub-VM opcode maps

`chain_dispatch_probe.py --list` found 7 candidate comparison-chain loops
inside `sample_v15.lua`'s own loader (`B`, `F`, `j`, `L`, `c`, `d`, `S`) that
`find_vm_groups`'s array-fetch-only regex never sees (see `../mm2.md`). Running
`chain_opcode_semantics.py` against all 7 sorts them into three real
categories, not one:

## Not a new VM: `F` is the payload VM's own lazy-init wrapper

`F` matched the detector (`while true do if F<=0 then ... end`) but its single
`F<=0` branch is `t[1][4]... = ...; F,I = 1, function(...) ... end` — a classic
compute-once-cache-the-closure pattern. That closure's own body starts
`if T==103 then while true do local M=o[w];...` — this **is** the main payload
register-VM already fully mapped elsewhere in this repo
(`v15_payload_opcode_semantics.md`), just inlined as a function literal here.
`classify_leaf` swallowed the whole thing as one leaf (hence the 20 calls and
nearly every array name showing up under a single branch) since there's no
further `F`-comparison chain nested inside to recurse into. Not a mystery, not
a new sub-VM — just the outer bootstrap for a VM this project already
characterized.

## Real handler-dispatch sub-VMs: `c`, `d`, `S`

Same self-referential `t:METHOD(...)` architecture as MM2's decoded inner VM
(`../devirt/mm2_inner_opcode_map.md`) — each opcode range dispatches to one
uniquely-named handler function, zero overlap within each loop:

### `c` — 46 opcode ranges, richness 45

| opcode range | category | handler |
|---|---|---|
| 10..14 | JUMP | t:M |
| 101..103 | JUMP | t:x |
| 104..106 | JUMP | t:c |
| 107..111 | JUMP | t:Z |
| 112..114 | JUMP | t:s |
| 115..117 | JUMP | t:d |
| 118..122 | JUMP | t:Q |
| 123..125 | JUMP | t:C |
| 126..128 | RETURN|JUMP | t:p |
| 129..130 | JUMP | t:E |
| 131..133 | JUMP | t:B |
| 134..136 | JUMP | t:g |
| 137..139 | JUMP | t:m |
| 140..144 | JUMP | t:I |
| 145..150 | JUMP | t:X |
| 15..20 | JUMP | t:j |
| 151..155 | JUMP | t:R |
| 156..158 | JUMP | t:P |
| 159..161 | JUMP | t:z |
| 162..166 | JUMP | t:u |
| 167..169 | JUMP | t:au |
| 2..4 | JUMP | t:G |
| 21..22 | JUMP | t:L |
| 23..25 | JUMP | t:k |
| 26..31 | JUMP | t:o |
| 32..36 | JUMP | t:J |
| 37..39 | JUMP | t:N |
| 40..42 | JUMP | t:D |
| 43..44 | JUMP | t:y |
| 45..47 | JUMP | t:t |
| 48..52 | JUMP | t:i |
| 5..9 | JUMP | t:h |
| 53..57 | JUMP | t:f |
| 58..60 | JUMP | t:w |
| 61..63 | JUMP | t:O |
| 64..68 | JUMP | t:A |
| 69..74 | JUMP | t:F |
| 75..79 | JUMP | t:Y |
| 80..82 | JUMP | t:n |
| 83..85 | JUMP | t:v |
| 86..90 | JUMP | t:V |
| 91..92 | JUMP | t:b |
| 93..95 | JUMP | t:H |
| 96..100 | JUMP | t:S |
| ?<=85&<=42&<=20&<=9&<=4&<=1 | JUMP | t:r |
| ?>85&>128&>150&>161&>166&>169 | JUMP | t:Tu |

### `d` — 71 opcode ranges, richness 69

| opcode range | category | handler |
|---|---|---|
| 10..13 | JUMP | t:vu |
| 100..103 | JUMP | t:lA |
| 104..106 | JUMP | t:WA |
| 107..110 | RETURN|JUMP | t:KA |
| 111..114 | JUMP | t:UA |
| 115..118 | JUMP | t:rA |
| 119..121 | JUMP | t:GA |
| 122..125 | JUMP | t:hA |
| 126..129 | JUMP | t:MA |
| 130..133 | JUMP | t:jA |
| 134..136 | JUMP | t:LA |
| 137..140 | JUMP | t:kA |
| 14..16 | JUMP | t:Vu |
| 141..142 | JUMP | t:oA |
| 143..144 | JUMP | t:JA |
| 145..148 | JUMP | t:NA |
| 149..151 | JUMP | t:DA |
| 152..155 | JUMP | t:yA |
| 156..159 | JUMP | t:tA |
| 160..163 | JUMP | t:iA |
| 164..166 | JUMP | t:fA |
| 167..170 | JUMP | t:wA |
| 17..20 | JUMP | t:bu |
| 171..174 | JUMP | t:OA |
| 175..178 | JUMP | t:AA |
| 179..181 | JUMP | t:FA |
| 182..185 | JUMP | t:YA |
| 186..189 | JUMP | t:nA |
| 190..193 | JUMP | t:vA |
| 194..196 | JUMP | t:VA |
| 197..200 | JUMP | t:bA |
| 201..202 | JUMP | t:HA |
| 203..204 | JUMP | t:SA |
| 205..208 | JUMP | t:xA |
| 209..211 | JUMP | t:cA |
| 21..24 | JUMP | t:Hu |
| 212..215 | JUMP | t:ZA |
| 216..219 | JUMP | t:sA |
| 220..223 | JUMP | t:dA |
| 224..226 | JUMP | t:QA |
| 227..230 | JUMP | t:CA |
| 231..232 | JUMP | t:pA |
| 233..234 | JUMP | t:EA |
| 25..28 | JUMP | t:Su |
| 29..31 | JUMP | t:xu |
| 3..6 | JUMP | t:Yu |
| 32..35 | JUMP | t:cu |
| 36..37 | JUMP | t:Zu |
| 38..39 | JUMP | t:su |
| 40..41 | JUMP | t:du |
| 42..43 | JUMP | t:Qu |
| 44..46 | JUMP | t:Cu |
| 47..50 | JUMP | t:pu |
| 51..54 | JUMP | t:Eu |
| 55..58 | JUMP | t:Bu |
| 59..61 | JUMP | t:gu |
| 62..65 | JUMP | t:mu |
| 66..67 | JUMP | t:Iu |
| 68..69 | JUMP | t:Xu |
| 7..9 | JUMP | t:nu |
| 70..73 | JUMP | t:Ru |
| 74..76 | JUMP | t:Pu |
| 77..80 | JUMP | t:zu |
| 81..84 | JUMP | t:uu |
| 85..88 | JUMP | t:aA |
| 89..91 | JUMP | t:TA |
| 92..93 | JUMP | t:qA |
| 94..95 | JUMP | t:eA |
| 96..99 | JUMP | t:_A |
| ?<=118&<=58&<=28&<=13&<=6&<=2 | JUMP | t:Fu |
| ?>118&>178&>208&>223&>230&>234 | JUMP | t:BA |

### `S` — 11 opcode ranges, richness 13

| opcode range | category | handler |
|---|---|---|
| 10..14 | JUMP | t:Mu |
| 15..19 | JUMP | t:ju |
| 2..4 | JUMP | t:ru |
| 20..24 | JUMP | t:Lu |
| 25..26 | JUMP | t:ku |
| 27..29 | JUMP | t:ou |
| 30..34 | RETURN|JUMP | t:Ju |
| 5..6 | JUMP | t:Gu |
| 7..9 | JUMP | t:hu |
| ?<=19&<=9&<=4&<=1 | JUMP | t:Uu |
| ?>19&>29&>34 | JUMP | t:Nu |

## Pure register/array steppers: `B` (PRNG) and `L` (RC4 keystream)

No named-handler calls at all (`calls=[]` on every branch) — these compute
directly with arithmetic and array indexing rather than dispatching out.
Resolved against `sample_v15.lua`'s own numeric-keyed builtin table (the same
technique `loadstring_alias_dump.py` uses for MM2) to identify the actual
algorithms, not guessed from shape alone:

- **`B` — a chained linear-congruential PRNG.** Its `B<=0` branch is three
  rounds of `x = (a*x + c) mod 2^28` (`268435456`) with different `(a,c)`
  constants each round, writing back into the same table slot. Classic
  multi-round LCG bit-mixing, used somewhere as a random/hash source.
- **`L` — RC4 keystream generation, XORed into a buffer.** Its numeric-keyed
  calls resolve to `t[66]=bit32.lshift`, `t[16]=bit32.band`, `t[57]=bit32.bor`,
  `t[68]=bit32.bxor`, `t[64]=buffer.readu32`, `t[31]=buffer.writeu32`.
  Substituting those in, the `L<=0` branch is exactly textbook RC4-PRGA: an
  index `i` advancing mod 256, `j = (j + S[i]) mod 256`, swap `S[i]`/`S[j]`,
  keystream byte from `S[(S[i]+S[j]) mod 256]`, four such bytes packed into a
  32-bit word and XORed against a source buffer, written to a destination
  buffer. This is very likely (part of) how Luraph's own runtime decrypts its
  XOR-encrypted bytecode/string blobs — RC4 stream-cipher keystream generation
  is exactly what that needs.

## Small / not fully characterized: `j` (8 opcode ranges, richness 7)

Calls a handful of names (`M`, `O`, short single-letter locals, not the
`t:METHOD` self-referential style) in a pattern that looks like a small
logging/message-dispatch state machine (string concatenation, a byte
comparison gating a boolean branch) — plausible but not confirmed against
resolved builtin names the way `B` and `L` were. Left open.

| opcode range | category | handler |
|---|---|---|
| 1 | JUMP | M |
| 2 | JUMP |  |
| 3 | JUMP | g |
| 4 | RETURN |  |
| 5 | JUMP | S |
| 6 | JUMP | O |
| ?<=3&<=1&<=0 | JUMP |  |
| ?>3&>5&>6 | JUMP | M |
