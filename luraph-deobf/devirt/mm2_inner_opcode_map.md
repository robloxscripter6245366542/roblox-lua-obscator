# MM2 decoded inner-stage VM — opcode-to-handler map

The decoded 170,974-byte second-stage chunk from `../mm2.md` ("The third VM
layer" section) is itself a full Luraph-style constant-pool+handler table
(~183 handler functions), not one function. Built by running the newly-added
`chain_opcode_semantics.py` — reusing `v15_payload_opcodes.py`'s AST-based
`walk_dispatch`/`classify_leaf` completely unchanged, extended with one fix
(local/method-call detection — previously only calls to GLOBAL library
functions like `buffer.readu8` were recognized, which is why every branch
first classified as a bare call-less JUMP even though each one's whole body
is a single method call) — against all three of its real comparison-chain
dispatch loops. **164 opcode ranges mapped to 165 distinct handler names,
zero overlap** — very likely the complete dispatch surface (~183 handler
functions total minus this VM's own entry point `z8`, its static initializer
`Kv`, and a handful of numeric-keyed library aliases like `[110]=Vector2.new`
that are never dispatched to by opcode, just referenced directly from
handler bodies).

The decoded chunk itself is **not vendored** in this repo (same policy as the
outer sample) — only this structural map (opcode range, category, and the
handler's own short, Luraph-generated name) is committed.

## dispatch loop `K` — 9 opcode ranges, richness 9

| opcode range | category | handler |
|---|---|---|
| 12..16 | JUMP | t:Tv |
| 17..20 | JUMP | t:GP |
| 21..24 | RETURN|JUMP | t:XP |
| 25..28 | JUMP | t:WP |
| 29..30 | JUMP | t:gP |
| 4..7 | JUMP | t:Jv |
| 8..11 | JUMP | t:Rv t:yv |
| ?<=16&<=7&<=3 | JUMP | t:Ev |
| ?>16&>24&>28&>30 | JUMP | t:BP |

## dispatch loop `G` — 69 opcode ranges, richness 69

| opcode range | category | handler |
|---|---|---|
| 10..13 | JUMP | t:LP |
| 100..103 | JUMP | t:dP |
| 104..106 | JUMP | t:AP |
| 107..110 | JUMP | t:oP |
| 111..114 | JUMP | t:wP |
| 115..118 | JUMP | t:jP |
| 119..121 | JUMP | t:KP |
| 122..125 | JUMP | t:EP |
| 126..129 | JUMP | t:JP |
| 130..133 | JUMP | t:yP |
| 134..136 | JUMP | t:RP |
| 137..140 | JUMP | t:TP |
| 14..16 | JUMP | t:SP |
| 141..144 | JUMP | t:G8 |
| 145..148 | JUMP | t:X8 |
| 149..151 | JUMP | t:W8 |
| 152..155 | JUMP | t:g8 |
| 156..159 | JUMP | t:B8 |
| 160..163 | JUMP | t:x8 |
| 164..166 | JUMP | t:P8 |
| 167..170 | JUMP | t:Q8 |
| 17..20 | JUMP | t:_P |
| 171..174 | JUMP | t:s8 |
| 175..178 | JUMP | t:Y8 |
| 179..181 | JUMP | t:t8 |
| 182..185 | JUMP | t:f8 |
| 186..189 | JUMP | t:a8 |
| 190..193 | RETURN|JUMP | t:e8 |
| 194..196 | JUMP | t:m8 |
| 197..200 | JUMP | t:L8 |
| 201..204 | JUMP | t:S8 |
| 205..206 | JUMP | t:_8 |
| 207..208 | JUMP | t:M8 |
| 209..211 | JUMP | t:l8 |
| 21..24 | JUMP | t:MP |
| 212..215 | JUMP | t:V8 |
| 216..219 | JUMP | t:r8 |
| 220..223 | JUMP | t:i8 |
| 224..226 | JUMP | t:I8 |
| 227..230 | JUMP | t:k8 |
| 231..234 | JUMP | t:n8 |
| 235..236 | JUMP | t:h8 |
| 25..28 | JUMP | t:lP |
| 29..31 | JUMP | t:VP |
| 3..6 | JUMP | t:eP |
| 32..35 | JUMP | t:rP |
| 36..39 | JUMP | t:iP |
| 40..43 | JUMP | t:IP |
| 44..46 | JUMP | t:kP |
| 47..50 | JUMP | t:nP |
| 51..54 | JUMP | t:hP |
| 55..58 | JUMP | t:pP |
| 59..61 | JUMP | t:zP |
| 62..65 | JUMP | t:OP |
| 66..69 | JUMP | t:NP |
| 7..9 | JUMP | t:mP |
| 70..73 | JUMP | t:HP |
| 74..76 | JUMP | t:ZP |
| 77..78 | JUMP | t:UP |
| 79..80 | JUMP | t:bP |
| 81..82 | JUMP | t:DP |
| 83..84 | JUMP | t:FP |
| 85..88 | JUMP | t:uP |
| 89..91 | JUMP | t:cP |
| 92..93 | JUMP | t:CP |
| 94..95 | JUMP | t:vP |
| 96..99 | JUMP | t:qP |
| ?<=118&<=58&<=28&<=13&<=6&<=2 | JUMP | t:aP |
| ?>118&>178&>208&>223&>230&>234&>236 | JUMP | t:p8 |

## dispatch loop `_` — 86 opcode ranges, richness 62

| opcode range | category | handler |
|---|---|---|
| 10..14 | JUMP | t:e |
| 101..102 | JUMP | t:c |
| 103..105 | JUMP | t:C |
| 106..110 | JUMP | t:v |
| 111..115 | JUMP | t:q |
| 116..121 | JUMP | t:d |
| 122..123 | JUMP | t:A |
| 124..126 | JUMP | t:o |
| 127..131 | JUMP | t:w |
| 132..136 | JUMP | t:j |
| 137..141 | JUMP | t:K |
| 142..146 | JUMP | t:E |
| 147..148 | JUMP | t:J |
| 149..151 | JUMP | t:y |
| 15..19 | JUMP | t:m |
| 152..156 | JUMP | t:R |
| 157..159 | JUMP | t:T |
| 160..162 | JUMP | t:Gv |
| 163..167 | JUMP | t:Xv |
| 168..172 | JUMP | t:Wv |
| 173..177 | JUMP | t:gv |
| 178..179 | JUMP | t:Bv |
| 180..182 | JUMP | t:xv |
| 183..187 | JUMP | t:Pv |
| 188..192 | JUMP | t:Qv |
| 193..197 | JUMP | t:sv |
| 198..200 | JUMP | t:Yv |
| 20..21 | JUMP | t:L |
| 201..203 | JUMP | t:tv |
| 204..208 | JUMP | t:fv |
| 209..210 | JUMP | t:av |
| 211..213 | JUMP | t:ev |
| 214..218 | JUMP | t:mv |
| 219..223 | JUMP | t:Lv |
| 22..24 | JUMP | t:S |
| 224..225 | JUMP | t:Sv |
| 226..228 | JUMP | t:_v |
| 229..233 | JUMP | t:Mv |
| 234..238 | JUMP | t:lv |
| 239..241 | JUMP | t:Vv |
| 242..244 | JUMP | t:rv |
| 245..246 | JUMP | t:iv |
| 247..249 | JUMP | t:Iv |
| 25..26 | JUMP | t:_ |
| 250..254 | JUMP | t:kv |
| 255..259 | JUMP | t:nv |
| 260..264 | JUMP | t:hv |
| 265..266 | JUMP | t:pv |
| 267..269 | JUMP | t:zv |
| 27..29 | JUMP | t:M |
| 270..274 | JUMP | t:Ov |
| 275..279 | JUMP | t:Nv |
| 280..282 | JUMP | t:Hv |
| 283..285 | JUMP | t:Zv |
| 286..287 | JUMP | t:Uv |
| 288..290 | JUMP | t:bv |
| 291..295 | JUMP | t:Dv |
| 296..300 | JUMP | t:Fv |
| 30..34 | JUMP | t:l |
| 301..305 | JUMP | t:uv |
| 306..310 | JUMP | t:cv |
| 311..315 | JUMP | t:Cv |
| 316..317 | JUMP | t:vv |
| 318..320 | JUMP | t:qv |
| 35..39 | RETURN|JUMP | t:V |
| 40..44 | JUMP | t:r |
| 45..49 | JUMP | t:i |
| 5..6 | JUMP | t:f |
| 50..54 | JUMP | t:I |
| 55..59 | JUMP | t:k |
| 60..61 | JUMP | t:n |
| 62..64 | JUMP | t:h |
| 65..69 | JUMP | t:p |
| 7..9 | JUMP | t:a |
| 70..71 | JUMP | t:z |
| 72..74 | JUMP | t:O |
| 75..80 | JUMP | t:N |
| 81..82 | JUMP | t:H |
| 83..85 | JUMP | t:Z |
| 86..87 | JUMP | t:U |
| 88..90 | JUMP | t:b |
| 91..95 | JUMP | t:D |
| 96..97 | JUMP | t:F |
| 98..100 | JUMP | t:u |
| ?<=162&<=80&<=39&<=19&<=9&<=4 | JUMP | t:t |
| ?>162&>244&>285&>305&>315&>320 | JUMP | t:dv |
