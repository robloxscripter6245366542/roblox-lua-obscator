-- Devirtualised from Luraph v14.7 bytecode by luraph-deobf/devirt/lift.py
-- Register-level transliteration (semantically faithful, not original source).
-- e[] = VM register file; K(i) = constant #i; L_n = basic-block labels.
-- mode: structured (trace-linearised CFG).
-- 91 protos, 9179 instructions, 8962 (97%) with a known opcode.
-- 1113 concrete values inlined from execution.
local regs = {}

local function proto1(...)  -- 1402 instrs, 464 blocks (structured)
  local e = regs
  ::L_1::
  ::L_965::
  -- UNKNOWN op? [a=0 b=196 c=0 d=nil]
  ::L_966::
  ::L_395::
  ::L_719::
  ::L_1208::
  ::L_950::
  ::L_906::
  ::L_241::
  ::L_695::
  ::L_797::
  ::L_107::
  ::L_404::
  ::L_323::
  ::L_1226::
  ::L_408::
  e[354] = (e[405] == e[507])  -- COMPARE [a=405 b=354 c=507 d=nil]
  e[14][K(2139)] = e[1571]  -- SETTABLE [a=14 b=2139 c=1571 d=151] -- settable/void-call (inferred)
  e[15] = e[151][K(0)]  -- GETINDEX? [a=151 b=0 c=15 d=nil]
  call(e[15], e[507])  -- CALL [a=15 b=14 c=507 d=nil] -- void call
  ::L_346::
  ::L_1159::
  ::L_18::
  ::L_875::
  ::L_285::
  ::L_295::
  ::L_1155::
  ::L_528::
  ::L_183::
  ::L_158::
  ::L_1317::
  ::L_1090::
  ::L_755::
  ::L_982::
  ::L_1140::
  ::L_713::
  ::L_87::
  ::L_1196::
  ::L_541::
  ::L_374::
  ::L_922::
  ::L_1340::
  ::L_883::
  ::L_1293::
  ::L_334::
  ::L_469::
  ::L_646::
  ::L_667::
  ::L_41::
  ::L_273::
  -- UNKNOWN op? [a=138 b=307 c=115 d=nil]
  e[15] = e[212][K(0)]  -- GETINDEX? [a=212 b=0 c=15 d=nil]
  call(e[15], e[190])  -- CALL [a=15 b=14 c=190 d=nil] -- void call
  e[14][K(1707)] = e[964]  -- SETTABLE [a=14 b=1707 c=964 d=110] -- settable/void-call (inferred)
  e[14][K(2405)] = e[1597]  -- SETTABLE [a=14 b=2405 c=1597 d=75] -- settable/void-call (inferred)
  e[15] = e[368][K(0)]  -- GETINDEX? [a=368 b=0 c=15 d=nil]
  call(e[15], e[490])  -- CALL [a=15 b=14 c=490 d=nil] -- void call
  ::L_280::
  ::L_1305::
  ::L_599::
  ::L_169::
  ::L_1052::
  ::L_523::
  ::L_213::
  ::L_573::
  ::L_961::
  ::L_855::
  ::L_723::
  ::L_727::
  ::L_1262::
  ::L_187::
  ::L_1190::
  ::L_788::
  ::L_805::
  ::L_307::
  ::L_290::
  ::L_743::
  ::L_949::
  ::L_689::
  ::L_488::
  ::L_1100::
  ::L_318::
  ::L_1104::
  ::L_628::
  ::L_591::
  ::L_780::
  ::L_484::
  ::L_381::
  ::L_246::
  ::L_226::
  ::L_264::
  ::L_311::
  ::L_1364::
  ::L_1119::
  ::L_495::
  ::L_1165::
  ::L_737::
  ::L_362::
  ::L_430::
  ::L_209::
  ::L_605::
  ::L_177::
  ::L_1301::
  ::L_569::
  ::L_977::
  ::L_23::
  ::L_1254::
  ::L_28::
  ::L_391::
  ::L_130::
  ::L_1127::
  ::L_65::
  ::L_640::
  ::L_1248::
  ::L_1282::
  ::L_366::
  ::L_651::
  ::L_1200::
  ::L_685::
  ::L_578::
  ::L_558::
  ::L_972::
  ::L_1021::
  ::L_1278::
  ::L_901::
  ::L_1387::
  ::L_72::
  ::L_769::
  ::L_205::
  -- UNKNOWN op? [a=341 b=230 c=378 d=nil]
  e[15] = e[35][K(0)]  -- GETINDEX? [a=35 b=0 c=15 d=nil]
  call(e[15], e[2312])  -- CALL [a=15 b=14 c=2312 d=nil] -- void call
  e[15] = e[46][K(0)]  -- GETINDEX? [a=46 b=0 c=15 d=nil]
  goto L_209
  call(e[15], e[1287])  -- CALL [a=15 b=14 c=1287 d=nil] -- void call
  e[14][K(1072)] = e[149]  -- SETTABLE [a=14 b=1072 c=149 d=125] -- settable/void-call (inferred)
  e[15] = e[131][K(0)]  -- GETINDEX? [a=131 b=0 c=15 d=nil]
  call(e[15], e[1235])  -- CALL [a=15 b=14 c=1235 d=nil] -- void call
  e[14][K(139)] = e[1589]  -- SETTABLE [a=14 b=139 c=1589 d=29] -- settable/void-call (inferred)
  e[15] = e[287][K(0)]  -- GETINDEX? [a=287 b=0 c=15 d=nil]
  call(e[15], e[1040])  -- CALL [a=15 b=14 c=1040 d=nil] -- void call
  ::L_9::
  goto L_1114
  e[15] = e[381][K(0)]  -- GETINDEX? [a=381 b=0 c=15 d=nil]
  call(e[15], e[1116])  -- CALL [a=15 b=14 c=1116 d=nil] -- void call
  e[15] = e[178][K(0)]  -- GETINDEX? [a=178 b=0 c=15 d=nil]
  call(e[15], e[892])  -- CALL [a=15 b=14 c=892 d=nil] -- void call
  ::L_14::
  goto L_1205
  e[15] = e[311][K(0)]  -- GETINDEX? [a=311 b=0 c=15 d=nil]
  call(e[15], e[1107])  -- CALL [a=15 b=14 c=1107 d=nil] -- void call
  e[15] = e[195][K(0)]  -- GETINDEX? [a=195 b=0 c=15 d=nil]
  goto L_18
  e[15] = call(e[15], e[0])  -- GETGLOBAL/CALL [a=15 b=1684 c=0 d=getfenv]
  call(e[15], e[107])  -- CALL [a=15 b=14 c=107 d=nil] -- void call
  e[15] = e[75][K(0)]  -- GETINDEX? [a=75 b=0 c=15 d=nil]
  call(e[15], e[680])  -- CALL [a=15 b=14 c=680 d=nil] -- void call
  goto L_23
  e[15] = e[320][K(0)]  -- GETINDEX? [a=320 b=0 c=15 d=nil]
  call(e[15], e[2026])  -- CALL [a=15 b=14 c=2026 d=nil] -- void call
  e[15] = e[157][K(0)]  -- GETINDEX? [a=157 b=0 c=15 d=nil]
  call(e[15], e[1771])  -- CALL [a=15 b=14 c=1771 d=nil] -- void call
  goto L_28
  call(e[15], e[1559])  -- CALL [a=15 b=14 c=1559 d=nil] -- void call
  e[15] = e[176][K(0)]  -- GETINDEX? [a=176 b=0 c=15 d=nil]
  call(e[15], e[1536])  -- CALL [a=15 b=14 c=1536 d=nil] -- void call
  e[14][K(2417)] = e[1046]  -- SETTABLE [a=14 b=2417 c=1046 d=160] -- settable/void-call (inferred)
  ::L_33::
  goto L_535
  e[14][K(1419)] = e[709]  -- SETTABLE [a=14 b=1419 c=709 d=51] -- settable/void-call (inferred)
  e[15] = e[318][K(0)]  -- GETINDEX? [a=318 b=0 c=15 d=nil]
  call(e[15], e[1347])  -- CALL [a=15 b=14 c=1347 d=nil] -- void call
  e[15] = e[267][K(0)]  -- GETINDEX? [a=267 b=0 c=15 d=nil]
  call(e[15], e[194])  -- CALL [a=15 b=14 c=194 d=nil] -- void call
  e[15] = e[354][K(0)]  -- GETINDEX? [a=354 b=0 c=15 d=nil]
  call(e[15], e[1307])  -- CALL [a=15 b=14 c=1307 d=nil] -- void call
  goto L_41
  call(e[15], e[2144])  -- CALL [a=15 b=14 c=2144 d=nil] -- void call
  e[15] = call(e[15], e[0])  -- GETGLOBAL/CALL [a=15 b=1408 c=0 d=typeof]
  call(e[15], e[1380])  -- CALL [a=15 b=14 c=1380 d=nil] -- void call
  e[15] = call(e[15], e[0])  -- GETGLOBAL/CALL [a=15 b=1441 c=0 d=string]
  call(e[15], e[319])  -- CALL [a=15 b=14 c=319 d=nil] -- void call
  e[15] = e[226][K(0)]  -- GETINDEX? [a=226 b=0 c=15 d=nil]
  call(e[15], e[464])  -- CALL [a=15 b=14 c=464 d=nil] -- void call
  ::L_49::
  goto L_82
  call(e[15], e[919])  -- CALL [a=15 b=14 c=919 d=nil] -- void call
  e[14][K(564)] = e[508]  -- SETTABLE [a=14 b=564 c=508 d=35] -- settable/void-call (inferred)
  e[15] = e[81][K(0)]  -- GETINDEX? [a=81 b=0 c=15 d=nil]
  call(e[15], e[377])  -- CALL [a=15 b=14 c=377 d=nil] -- void call
  e[15] = e[39][K(0)]  -- GETINDEX? [a=39 b=0 c=15 d=nil]
  ::L_55::
  goto L_1150
  call(e[15], e[2004])  -- CALL [a=15 b=14 c=2004 d=nil] -- void call
  e[15] = call(e[15], e[0])  -- GETGLOBAL/CALL [a=15 b=1396 c=0 d=task]
  call(e[15], e[113])  -- CALL [a=15 b=14 c=113 d=nil] -- void call
  e[15] = e[122][K(0)]  -- GETINDEX? [a=122 b=0 c=15 d=nil]
  call(e[15], e[2302])  -- CALL [a=15 b=14 c=2302 d=nil] -- void call
  ::L_61::
  goto L_620
  call(e[15], e[2249])  -- CALL [a=15 b=14 c=2249 d=nil] -- void call
  e[14][K(1487)] = e[2374]  -- SETTABLE [a=14 b=1487 c=2374 d=138] -- settable/void-call (inferred)
  e[14][K(264)] = e[246]  -- SETTABLE [a=14 b=264 c=246 d=168] -- settable/void-call (inferred)
  goto L_65
  e[14][K(609)] = e[1190]  -- SETTABLE [a=14 b=609 c=1190 d=155] -- settable/void-call (inferred)
  e[15] = e[42][K(0)]  -- GETINDEX? [a=42 b=0 c=15 d=nil]
  call(e[15], e[1285])  -- CALL [a=15 b=14 c=1285 d=nil] -- void call
  e[15] = e[11][K(0)]  -- GETINDEX? [a=11 b=0 c=15 d=nil]
  call(e[15], e[585])  -- CALL [a=15 b=14 c=585 d=nil] -- void call
  e[15] = e[6][K(0)]  -- GETINDEX? [a=6 b=0 c=15 d=nil]
  goto L_72
  call(e[15], e[1336])  -- CALL [a=15 b=14 c=1336 d=nil] -- void call
  e[15] = e[322][K(0)]  -- GETINDEX? [a=322 b=0 c=15 d=nil]
  call(e[15], e[1232])  -- CALL [a=15 b=14 c=1232 d=nil] -- void call
  e[14][K(1642)] = e[1914]  -- SETTABLE [a=14 b=1642 c=1914 d=190] -- settable/void-call (inferred)
  e[14][K(1631)] = e[158]  -- SETTABLE [a=14 b=1631 c=158 d=164] -- settable/void-call (inferred)
  e[15] = e[220][K(0)]  -- GETINDEX? [a=220 b=0 c=15 d=nil]
  call(e[15], e[1249])  -- CALL [a=15 b=14 c=1249 d=nil] -- void call
  e[15] = e[139][K(0)]  -- GETINDEX? [a=139 b=0 c=15 d=nil]
  call(e[15], e[1325])  -- CALL [a=15 b=14 c=1325 d=nil] -- void call
  ::L_82::
  goto L_1172
  e[15] = e[189][K(0)]  -- GETINDEX? [a=189 b=0 c=15 d=nil]
  call(e[127], e[2155])  -- CALL [a=127 b=14 c=2155 d=nil] -- void call
  e[15] = e[142][K(0)]  -- GETINDEX? [a=142 b=0 c=15 d=nil]
  call(e[15], e[474])  -- CALL [a=15 b=14 c=474 d=nil] -- void call
  goto L_87
  e[25] = K(15)  -- LOADK_S [a=0 b=15 c=25 d=nil]
  e[26] = "253010"  -- LOADK [a=26 b=387 c=0 d=�]
  e[25] = 2  -- LOADK_N [a=0 b=0 c=25 d=nil]
  ::L_91::
  goto L_1188
  e[19] = {}  -- NEWTABLE [a=19 b=0 c=0 d=nil]
  e[25] = K(16)  -- LOADK_S [a=0 b=16 c=25 d=nil]
  e[26] = K(9)  -- LOADK_S [a=0 b=9 c=26 d=nil]
  e[27] = "177180172183"  -- LOADK [a=27 b=884 c=0 d=����]
  e[28] = 4  -- LOADK [a=28 b=70 c=0 d=4]
  e[29] = 4  -- LOADK [a=29 b=70 c=0 d=4]
  e[26] = 183  -- LOADK_N [a=0 b=26 c=4 d=nil]
  e[26] = arith(e[26], e[2351])  -- ARITH [a=26 b=26 c=2351 d=nil]  -- = 56
  e[25] = 56  -- LOADK_N [a=0 b=0 c=25 d=nil]
  e[25] = e[25] + 27114  -- ADD [a=25 b=2295 c=25 d=27114]  -- = 27170
  e[25] = arith(e[25], e[238])  -- UNOP/arith? [a=25 b=25 c=238 d=nil]  -- = 14
  call(e[25], e[2411])  -- CALL [a=25 b=19 c=2411 d=nil] -- void call
  e[19][K(1747)] = e[409]  -- SETTABLE [a=19 b=1747 c=409 d=652] -- settable/void-call (inferred)
  call(e[29], e[17])  -- CALL? [a=29 b=0 c=17 d=nil] -- void call
  goto L_107
  e[14][K(320)] = e[340]  -- SETTABLE [a=14 b=320 c=340 d=68] -- settable/void-call (inferred)
  e[15] = e[69][K(0)]  -- GETINDEX? [a=69 b=0 c=15 d=nil]
  call(e[15], e[990])  -- CALL [a=15 b=14 c=990 d=nil] -- void call
  e[15] = e[28][K(0)]  -- GETINDEX? [a=28 b=0 c=15 d=nil]
  ::L_112::
  goto L_1176
  e[32] = {}  -- NEWTABLE [a=32 b=0 c=0 d=nil]
  e[34] = {}  -- NEWTABLE [a=34 b=0 c=0 d=nil]
  e[34][K(426)] = e[1284]  -- SETTABLE [a=34 b=426 c=1284 d=289] -- settable/void-call (inferred)
  e[32][K(843)] = e[1399]  -- SETTABLE [a=32 b=843 c=1399 d=1206] -- settable/void-call (inferred)
  call(e[37], e[30])  -- CALL? [a=37 b=0 c=30 d=nil] -- void call
  ::L_118::
  goto L_896
  e[19] = {}  -- NEWTABLE [a=19 b=0 c=0 d=nil]
  e[18] = {}  -- NEWTABLE [a=18 b=0 c=0 d=nil]
  e[25] = K(14)  -- LOADK_S [a=0 b=14 c=25 d=nil]
  e[26] = 325  -- LOADK [a=26 b=1590 c=0 d=325]
  e[25] = 325  -- LOADK_N [a=0 b=0 c=25 d=nil]
  e[25] = arith(e[25], e[407])  -- UNOP/arith? [a=25 b=25 c=407 d=nil]  -- = 383
  e[25] = e[25] + 5717  -- ADD [a=25 b=146 c=25 d=5717]  -- = 6100
  e[25] = arith(e[25], e[1358])  -- UNOP/arith? [a=25 b=25 c=1358 d=nil]  -- = 15
  call(e[25], e[840])  -- CALL [a=25 b=18 c=840 d=nil] -- void call
  e[19][K(1263)] = e[1635]  -- SETTABLE [a=19 b=1263 c=1635 d=196] -- settable/void-call (inferred)
  call(e[29], e[17])  -- CALL? [a=29 b=0 c=17 d=nil] -- void call
  goto L_130
  e[31] = {}  -- NEWTABLE [a=31 b=0 c=0 d=nil]
  e[34] = {}  -- NEWTABLE [a=34 b=0 c=0 d=nil]
  e[32] = {}  -- NEWTABLE [a=32 b=0 c=0 d=nil]
  e[34][K(1905)] = e[1284]  -- SETTABLE [a=34 b=1905 c=1284 d=313] -- settable/void-call (inferred)
  e[31][K(1905)] = e[22]  -- SETTABLE [a=31 b=1905 c=22 d=313] -- settable/void-call (inferred)
  e[32][K(656)] = e[2364]  -- SETTABLE [a=32 b=656 c=2364 d=1365] -- settable/void-call (inferred)
  call(e[37], e[30])  -- CALL? [a=37 b=0 c=30 d=nil] -- void call
  ::L_138::
  goto L_1325
  e[15] = e[353][K(0)]  -- GETINDEX? [a=353 b=0 c=15 d=nil]
  call(e[15], e[621])  -- CALL [a=15 b=14 c=621 d=nil] -- void call
  e[15] = e[371][K(0)]  -- GETINDEX? [a=371 b=0 c=15 d=nil]
  call(e[15], e[1444])  -- CALL [a=15 b=14 c=1444 d=nil] -- void call
  e[14][K(1936)] = e[1146]  -- SETTABLE [a=14 b=1936 c=1146 d=120] -- settable/void-call (inferred)
  e[15] = e[255][K(0)]  -- GETINDEX? [a=255 b=0 c=15 d=nil]
  call(e[15], e[1947])  -- CALL [a=15 b=14 c=1947 d=nil] -- void call
  e[15] = e[143][K(0)]  -- GETINDEX? [a=143 b=0 c=15 d=nil]
  call(e[15], e[1216])  -- CALL [a=15 b=14 c=1216 d=nil] -- void call
  e[15] = e[341][K(0)]  -- GETINDEX? [a=341 b=0 c=15 d=nil]
  call(e[15], e[638])  -- CALL [a=15 b=14 c=638 d=nil] -- void call
  e[14][K(2385)] = e[789]  -- SETTABLE [a=14 b=2385 c=789 d=91] -- settable/void-call (inferred)
  e[14][K(1750)] = e[510]  -- SETTABLE [a=14 b=1750 c=510 d=183] -- settable/void-call (inferred)
  e[15] = e[175][K(0)]  -- GETINDEX? [a=175 b=0 c=15 d=nil]
  ::L_153::
  goto L_945
  e[15] = e[182][K(0)]  -- GETINDEX? [a=182 b=0 c=15 d=nil]
  call(e[15], e[2254])  -- CALL [a=15 b=14 c=2254 d=nil] -- void call
  e[15] = e[296][K(0)]  -- GETINDEX? [a=296 b=0 c=15 d=nil]
  call(e[15], e[2044])  -- CALL [a=15 b=14 c=2044 d=nil] -- void call
  goto L_158
  e[14][K(14)] = e[781]  -- SETTABLE [a=14 b=14 c=781 d=107] -- settable/void-call (inferred)
  e[15] = e[45][K(0)]  -- GETINDEX? [a=45 b=0 c=15 d=nil]
  call(e[15], e[466])  -- CALL [a=15 b=14 c=466 d=nil] -- void call
  e[15] = e[8][K(0)]  -- GETINDEX? [a=8 b=0 c=15 d=nil]
  call(e[15], e[1273])  -- CALL [a=15 b=14 c=1273 d=nil] -- void call
  ::L_164::
  goto L_475
  call(e[15], e[651])  -- CALL [a=15 b=14 c=651 d=nil] -- void call
  e[15] = e[207][K(0)]  -- GETINDEX? [a=207 b=0 c=15 d=nil]
  call(e[15], e[538])  -- CALL [a=15 b=14 c=538 d=nil] -- void call
  e[14][K(2304)] = e[157]  -- SETTABLE [a=14 b=2304 c=157 d=96] -- settable/void-call (inferred)
  goto L_169
  call(e[15], e[1262])  -- CALL [a=15 b=14 c=1262 d=nil] -- void call
  e[15] = e[72][K(0)]  -- GETINDEX? [a=72 b=0 c=15 d=nil]
  e[252][K(14)] = e[132]  -- SETTABLE/CALL [a=252 b=14 c=132 d=nil] -- settable/void-call (inferred)
  e[53][K(139)] = e[185]  -- SETTABLE/CALL [a=53 b=139 c=185 d=nil] -- settable/void-call (inferred)
  call(e[239], e[97])  -- CALL [a=239 b=251 c=97 d=nil] -- void call
  call(e[15], e[37])  -- CALL [a=15 b=137 c=37 d=nil] -- void call
  e[15] = e[63][K(0)]  -- GETINDEX? [a=63 b=0 c=15 d=nil]
  goto L_177
  call(e[15], e[857])  -- CALL [a=15 b=14 c=857 d=nil] -- void call
  e[15] = e[80][K(0)]  -- GETINDEX? [a=80 b=0 c=15 d=nil]
  call(e[15], e[2063])  -- CALL [a=15 b=14 c=2063 d=nil] -- void call
  e[15] = e[32][K(0)]  -- GETINDEX? [a=32 b=0 c=15 d=nil]
  call(e[15], e[365])  -- CALL [a=15 b=14 c=365 d=nil] -- void call
  goto L_183
  call(e[15], e[436])  -- CALL [a=15 b=14 c=436 d=nil] -- void call
  e[15] = e[184][K(0)]  -- GETINDEX? [a=184 b=0 c=15 d=nil]
  call(e[15], e[274])  -- CALL [a=15 b=14 c=274 d=nil] -- void call
  goto L_187
  e[15] = call(e[15], e[0])  -- GETGLOBAL/CALL [a=15 b=654 c=0 d=next]
  call(e[15], e[1593])  -- CALL [a=15 b=14 c=1593 d=nil] -- void call
  e[15] = e[380][K(0)]  -- GETINDEX? [a=380 b=0 c=15 d=nil]
  call(e[15], e[195])  -- CALL [a=15 b=14 c=195 d=nil] -- void call
  e[15] = e[272][K(0)]  -- GETINDEX? [a=272 b=0 c=15 d=nil]
  call(e[15], e[502])  -- CALL [a=15 b=14 c=502 d=nil] -- void call
  e[15] = e[146][K(0)]  -- GETINDEX? [a=146 b=0 c=15 d=nil]
  ::L_195::
  goto L_453
  goto L_118
  ::L_197::
  goto L_1094
  call(e[15], e[1739])  -- CALL [a=15 b=14 c=1739 d=nil] -- void call
  e[15] = e[275][K(0)]  -- GETINDEX? [a=275 b=0 c=15 d=nil]
  call(e[15], e[815])  -- CALL [a=15 b=14 c=815 d=nil] -- void call
  e[15] = e[385][K(0)]  -- GETINDEX? [a=385 b=0 c=15 d=nil]
  call(e[15], e[1758])  -- CALL [a=15 b=14 c=1758 d=nil] -- void call
  goto L_1218
  -- UNKNOWN op? [a=44 b=281 c=205 d=nil]
  goto L_205
  e[15] = e[379][K(0)]  -- GETINDEX? [a=379 b=0 c=15 d=nil]
  call(e[15], e[266])  -- CALL [a=15 b=14 c=266 d=nil] -- void call
  e[15] = e[132][K(0)]  -- GETINDEX? [a=132 b=0 c=15 d=nil]
  goto L_213
  call(e[15], e[1310])  -- CALL [a=15 b=14 c=1310 d=nil] -- void call
  e[15] = e[14][K(0)]  -- GETINDEX? [a=14 b=0 c=15 d=nil]
  e[187][K(14)] = e[210]  -- SETTABLE/CALL [a=187 b=14 c=210 d=nil] -- settable/void-call (inferred)
  e[162][K(186)] = e[273]  -- SETTABLE/CALL [a=162 b=186 c=273 d=nil] -- settable/void-call (inferred)
  call(e[3], e[250])  -- CALL [a=3 b=28 c=250 d=nil] -- void call
  call(e[15], e[241])  -- CALL [a=15 b=20 c=241 d=nil] -- void call
  e[15] = e[37][K(0)]  -- GETINDEX? [a=37 b=0 c=15 d=nil]
  call(e[15], e[2297])  -- CALL [a=15 b=14 c=2297 d=nil] -- void call
  e[14][K(2351)] = e[673]  -- SETTABLE [a=14 b=2351 c=673 d=127] -- settable/void-call (inferred)
  e[15] = e[128][K(0)]  -- GETINDEX? [a=128 b=0 c=15 d=nil]
  call(e[15], e[795])  -- CALL [a=15 b=14 c=795 d=nil] -- void call
  e[15] = e[57][K(0)]  -- GETINDEX? [a=57 b=0 c=15 d=nil]
  goto L_226
  e[15] = e[273][K(0)]  -- GETINDEX? [a=273 b=0 c=15 d=nil]
  call(e[15], e[1462])  -- CALL [a=15 b=14 c=1462 d=nil] -- void call
  e[15] = e[154][K(0)]  -- GETINDEX? [a=154 b=0 c=15 d=nil]
  ::L_230::
  goto L_674
  -- UNKNOWN op? [a=128 b=14 c=353 d=nil]
  e[14][K(821)] = e[1488]  -- SETTABLE [a=14 b=821 c=1488 d=89] -- settable/void-call (inferred)
  e[15] = e[225][K(0)]  -- GETINDEX? [a=225 b=0 c=15 d=nil]
  call(e[15], e[2403])  -- CALL [a=15 b=14 c=2403 d=nil] -- void call
  e[15] = e[249][K(0)]  -- GETINDEX? [a=249 b=0 c=15 d=nil]
  ::L_236::
  goto L_1045
  e[15] = e[215][K(0)]  -- GETINDEX? [a=215 b=0 c=15 d=nil]
  call(e[15], e[479])  -- CALL [a=15 b=14 c=479 d=nil] -- void call
  e[15] = call(e[15], e[0])  -- GETGLOBAL/CALL [a=15 b=1398 c=0 d=unpack]
  call(e[15], e[2419])  -- CALL [a=15 b=14 c=2419 d=nil] -- void call
  goto L_241
  e[15] = call(e[15], e[0])  -- GETGLOBAL/CALL [a=15 b=2035 c=0 d=utf8]
  call(e[15], e[1083])  -- CALL [a=15 b=14 c=1083 d=nil] -- void call
  e[15] = e[331][K(0)]  -- GETINDEX? [a=331 b=0 c=15 d=nil]
  call(e[15], e[2178])  -- CALL [a=15 b=14 c=2178 d=nil] -- void call
  goto L_246
  e[15] = e[365][K(0)]  -- GETINDEX? [a=365 b=0 c=15 d=nil]
  call(e[15], e[1158])  -- CALL [a=15 b=14 c=1158 d=nil] -- void call
  e[15] = e[333][K(0)]  -- GETINDEX? [a=333 b=0 c=15 d=nil]
  ::L_250::
  goto L_801
  e[14] = e[14]  -- MOVE [a=14 b=14 c=1973 d=nil]
  ::L_252::
  do return end  -- JMP/RETURN [a=0 b=0 c=14 d=nil]
  call(e[15], e[1834])  -- CALL [a=15 b=14 c=1834 d=nil] -- void call
  e[15] = call(e[15], e[0])  -- GETGLOBAL/CALL [a=15 b=149 c=0 d=Instance]
  call(e[15], e[1673])  -- CALL [a=15 b=14 c=1673 d=nil] -- void call
  e[14][K(1677)] = e[304]  -- SETTABLE [a=14 b=1677 c=304 d=167] -- settable/void-call (inferred)
  e[15] = e[336][K(0)]  -- GETINDEX? [a=336 b=0 c=15 d=nil]
  call(e[15], e[1122])  -- CALL [a=15 b=14 c=1122 d=nil] -- void call
  e[14][K(90)] = e[1716]  -- SETTABLE [a=14 b=90 c=1716 d=23] -- settable/void-call (inferred)
  e[14][K(208)] = e[1646]  -- SETTABLE [a=14 b=208 c=1646 d=133] -- settable/void-call (inferred)
  -- UNKNOWN op? [a=179 b=0 c=15 d=nil]
  call(e[15], e[930])  -- CALL [a=15 b=14 c=930 d=nil] -- void call
  e[15] = e[374][K(0)]  -- GETINDEX? [a=374 b=0 c=15 d=nil]
  goto L_264
  call(e[15], e[459])  -- CALL [a=15 b=14 c=459 d=nil] -- void call
  e[14][K(1221)] = e[1415]  -- SETTABLE [a=14 b=1221 c=1415 d=90] -- settable/void-call (inferred)
  e[14][K(1620)] = e[1967]  -- SETTABLE [a=14 b=1620 c=1967 d=149] -- settable/void-call (inferred)
  e[14][K(381)] = e[1724]  -- SETTABLE [a=14 b=381 c=1724 d=84] -- settable/void-call (inferred)
  goto L_935
  -- UNKNOWN op? [a=420 b=39 c=137 d=nil]
  -- UNKNOWN op? [a=20 b=209 c=159 d=nil]
  dataop(e[70], e[229], e[322])  -- DATAOP [a=70 b=229 c=322 d=nil]
  goto L_273
  e[15] = e[119][K(0)]  -- GETINDEX? [a=119 b=0 c=15 d=nil]
  call(e[15], e[468])  -- CALL [a=15 b=14 c=468 d=nil] -- void call
  e[15] = e[125][K(0)]  -- GETINDEX? [a=125 b=0 c=15 d=nil]
  call(e[15], e[898])  -- CALL [a=15 b=14 c=898 d=nil] -- void call
  goto L_285
  e[15] = e[254][K(0)]  -- GETINDEX? [a=254 b=0 c=15 d=nil]
  e[15][K(14)] = e[446]  -- SETTABLE/CALL [a=15 b=14 c=446 d=nil] -- settable/void-call (inferred)
  e[14][K(2150)] = e[1940]  -- SETTABLE [a=14 b=2150 c=1940 d=85] -- settable/void-call (inferred)
  e[216] = (e[216] == e[15])  -- COMPARE [a=216 b=0 c=15 d=nil]
  goto L_290
  e[15] = e[58][K(0)]  -- GETINDEX? [a=58 b=0 c=15 d=nil]
  call(e[15], e[427])  -- CALL [a=15 b=14 c=427 d=nil] -- void call
  e[15] = e[123][K(0)]  -- GETINDEX? [a=123 b=0 c=15 d=nil]
  call(e[15], e[1611])  -- CALL [a=15 b=14 c=1611 d=nil] -- void call
  goto L_295
  e[15] = e[106][K(0)]  -- GETINDEX? [a=106 b=0 c=15 d=nil]
  call(e[15], e[826])  -- CALL [a=15 b=14 c=826 d=nil] -- void call
  e[15] = e[99][K(0)]  -- GETINDEX? [a=99 b=0 c=15 d=nil]
  -- UNKNOWN op? [a=15 b=14 c=172 d=nil]
  e[15] = e[61][K(0)]  -- GETINDEX? [a=61 b=0 c=15 d=nil]
  e[205][K(14)] = e[234]  -- SETTABLE/CALL [a=205 b=14 c=234 d=nil] -- settable/void-call (inferred)
  e[117][K(174)] = e[226]  -- SETTABLE/CALL [a=117 b=174 c=226 d=nil] -- settable/void-call (inferred)
  call(e[80], e[48])  -- CALL [a=80 b=117 c=48 d=nil] -- void call
  call(e[15], e[207])  -- CALL [a=15 b=128 c=207 d=nil] -- void call
  e[15] = e[29][K(0)]  -- GETINDEX? [a=29 b=0 c=15 d=nil]
  call(e[15], e[2127])  -- CALL [a=15 b=14 c=2127 d=nil] -- void call
  goto L_307
  e[15] = e[248][K(0)]  -- GETINDEX? [a=248 b=0 c=15 d=nil]
  call(e[15], e[1338])  -- CALL [a=15 b=14 c=1338 d=nil] -- void call
  e[15] = e[384][K(0)]  -- GETINDEX? [a=384 b=0 c=15 d=nil]
  goto L_311
  ::L_312::
  goto L_656
  -- UNKNOWN op? [a=299 b=0 c=26 d=nil]
  call(e[15], e[410])  -- CALL [a=15 b=14 c=410 d=nil] -- void call
  e[15] = call(e[15], e[0])  -- GETGLOBAL/CALL [a=15 b=325 c=0 d=UDim2]
  e[15] = e[15][K(15)]  -- GETTABLE [a=15 b=15 c=396 d=nil]
  call(e[15], e[25])  -- CALL [a=15 b=14 c=25 d=nil] -- void call
  goto L_318
  e[15] = e[349][K(0)]  -- GETINDEX? [a=349 b=0 c=15 d=nil]
  call(e[15], e[902])  -- CALL [a=15 b=14 c=902 d=nil] -- void call
  e[15] = e[205][K(0)]  -- GETINDEX? [a=205 b=0 c=15 d=nil]
  call(e[15], e[689])  -- CALL [a=15 b=14 c=689 d=nil] -- void call
  goto L_323
  call(e[15], e[1254])  -- CALL [a=15 b=14 c=1254 d=nil] -- void call
  e[15] = e[116][K(0)]  -- GETINDEX? [a=116 b=0 c=15 d=nil]
  call(e[15], e[501])  -- CALL [a=15 b=14 c=501 d=nil] -- void call
  e[15] = e[54][K(0)]  -- GETINDEX? [a=54 b=0 c=15 d=nil]
  ::L_328::
  call(e[15], e[1343])  -- CALL [a=15 b=14 c=1343 d=nil] -- void call
  e[14][K(361)] = e[1681]  -- SETTABLE [a=14 b=361 c=1681 d=170] -- settable/void-call (inferred)
  e[15] = e[23][K(0)]  -- GETINDEX? [a=23 b=0 c=15 d=nil]
  call(e[15], e[2217])  -- CALL [a=15 b=14 c=2217 d=nil] -- void call
  e[15] = call(e[15], e[0])  -- GETGLOBAL/CALL [a=15 b=1474 c=0 d=Vector3]
  call(e[15], e[26])  -- CALL [a=15 b=14 c=26 d=nil] -- void call
  goto L_334
  e[15] = e[15][K(15)]  -- GETTABLE [a=15 b=15 c=174 d=nil]
  call(e[15], e[1168])  -- CALL [a=15 b=14 c=1168 d=nil] -- void call
  e[15] = e[206][K(0)]  -- GETINDEX? [a=206 b=0 c=15 d=nil]
  call(e[15], e[560])  -- CALL [a=15 b=14 c=560 d=nil] -- void call
  goto L_582
  -- UNKNOWN op? [a=484 b=163 c=394 d=nil]
  goto L_328
  e[25] = e[25] + 22809  -- ADD [a=25 b=1855 c=25 d=22809]  -- = 22959
  e[25] = arith(e[25], e[1706])  -- UNOP/arith? [a=25 b=25 c=1706 d=nil]  -- = 14
  call(e[25], e[1675])  -- CALL [a=25 b=20 c=1675 d=nil] -- void call
  e[19][K(1729)] = e[1585]  -- SETTABLE [a=19 b=1729 c=1585 d=1349] -- settable/void-call (inferred)
  call(e[29], e[17])  -- CALL? [a=29 b=0 c=17 d=nil] -- void call
  ::L_352::
  goto L_1071
  call(e[15], e[2293])  -- CALL [a=15 b=14 c=2293 d=nil] -- void call
  call(e[0], e[18])  -- CALL [a=0 b=14 c=18 d=nil] -- void call
  e[15] = e[56][K(0)]  -- GETINDEX? [a=56 b=0 c=15 d=nil]
  ::L_356::
  goto L_792
  e[15] = e[67][K(0)]  -- GETINDEX? [a=67 b=0 c=15 d=nil]
  call(e[15], e[1792])  -- CALL [a=15 b=14 c=1792 d=nil] -- void call
  e[15] = e[91][K(0)]  -- GETINDEX? [a=91 b=0 c=15 d=nil]
  call(e[15], e[1920])  -- CALL [a=15 b=14 c=1920 d=nil] -- void call
  e[14][K(1480)] = e[197]  -- SETTABLE [a=14 b=1480 c=197 d=142] -- settable/void-call (inferred)
  goto L_362
  e[15] = e[197][K(0)]  -- GETINDEX? [a=197 b=0 c=15 d=nil]
  call(e[15], e[1231])  -- CALL [a=15 b=14 c=1231 d=nil] -- void call
  e[14][K(414)] = e[1065]  -- SETTABLE [a=14 b=414 c=1065 d=71] -- settable/void-call (inferred)
  goto L_366
  e[15] = e[105][K(0)]  -- GETINDEX? [a=105 b=0 c=15 d=nil]
  call(e[15], e[971])  -- CALL [a=15 b=14 c=971 d=nil] -- void call
  e[15] = e[93][K(0)]  -- GETINDEX? [a=93 b=0 c=15 d=nil]
  ::L_370::
  goto L_587
  e[14][K(2152)] = e[1464]  -- SETTABLE [a=14 b=2152 c=1464 d=61] -- settable/void-call (inferred)
  e[15] = e[5][K(0)]  -- GETINDEX? [a=5 b=0 c=15 d=nil]
  call(e[15], e[248])  -- CALL [a=15 b=14 c=248 d=nil] -- void call
  goto L_374
  e[15] = e[244][K(190)]  -- GETINDEX? [a=244 b=190 c=15 d=nil]
  call(e[15], e[137])  -- CALL [a=15 b=14 c=137 d=nil] -- void call
  e[15] = e[284][K(0)]  -- GETINDEX? [a=284 b=0 c=15 d=nil]
  call(e[15], e[1924])  -- CALL [a=15 b=14 c=1924 d=nil] -- void call
  e[15] = e[148][K(0)]  -- GETINDEX? [a=148 b=0 c=15 d=nil]
  call(e[15], e[164])  -- CALL [a=15 b=14 c=164 d=nil] -- void call
  goto L_381
  call(e[15], e[168])  -- CALL [a=15 b=14 c=168 d=nil] -- void call
  e[15] = e[49][K(0)]  -- GETINDEX? [a=49 b=0 c=15 d=nil]
  call(e[15], e[1440])  -- CALL [a=15 b=14 c=1440 d=nil] -- void call
  e[15] = e[121][K(0)]  -- GETINDEX? [a=121 b=0 c=15 d=nil]
  call(e[15], e[993])  -- CALL [a=15 b=14 c=993 d=nil] -- void call
  e[15] = call(e[15], e[0])  -- GETGLOBAL/CALL [a=15 b=2191 c=0 d=coroutine]
  call(e[15], e[1805])  -- CALL [a=15 b=14 c=1805 d=nil] -- void call
  e[14][K(49)] = e[1196]  -- SETTABLE [a=14 b=49 c=1196 d=103] -- settable/void-call (inferred)
  e[14][K(2099)] = e[1077]  -- SETTABLE [a=14 b=2099 c=1077 d=28] -- settable/void-call (inferred)
  goto L_391
  e[14][K(2136)] = e[1191]  -- SETTABLE [a=14 b=2136 c=1191 d=67] -- settable/void-call (inferred)
  e[15] = e[181][K(0)]  -- GETINDEX? [a=181 b=0 c=15 d=nil]
  call(e[15], e[2088])  -- CALL [a=15 b=14 c=2088 d=nil] -- void call
  goto L_395
  e[14][K(1070)] = e[1318]  -- SETTABLE [a=14 b=1070 c=1318 d=101] -- settable/void-call (inferred)
  e[14][K(1615)] = e[835]  -- SETTABLE [a=14 b=1615 c=835 d=117] -- settable/void-call (inferred)
  e[15] = e[107][K(0)]  -- GETINDEX? [a=107 b=0 c=15 d=nil]
  call(e[15], e[2185])  -- CALL [a=15 b=14 c=2185 d=nil] -- void call
  e[15] = e[22][K(0)]  -- GETINDEX? [a=22 b=0 c=15 d=nil]
  call(e[15], e[918])  -- CALL [a=15 b=14 c=918 d=nil] -- void call
  e[15] = e[118][K(0)]  -- GETINDEX? [a=118 b=0 c=15 d=nil]
  goto L_404
  e[14][K(1144)] = e[592]  -- SETTABLE [a=14 b=1144 c=592 d=119] -- settable/void-call (inferred)
  e[15] = e[165][K(0)]  -- GETINDEX? [a=165 b=0 c=15 d=nil]
  call(e[15], e[678])  -- CALL [a=15 b=14 c=678 d=nil] -- void call
  goto L_408
  call(e[15], e[769])  -- CALL [a=15 b=14 c=769 d=nil] -- void call
  call(e[211], e[200])  -- CALL [a=211 b=168 c=200 d=nil] -- void call
  e[14][K(212)] = e[254]  -- SETTABLE [a=14 b=212 c=254 d=nil] -- settable/void-call (inferred)
  e[75][K(394)] = e[37]  -- SETTABLE/CALL [a=75 b=394 c=37 d=43] -- settable/void-call (inferred)
  e[38][K(32)] = e[348]  -- SETTABLE/CALL [a=38 b=32 c=348 d=nil] -- settable/void-call (inferred)
  e[15] = e[247][K(0)]  -- GETINDEX? [a=247 b=0 c=15 d=nil]
  call(e[15], e[1890])  -- CALL [a=15 b=14 c=1890 d=nil] -- void call
  e[14][K(1416)] = e[775]  -- SETTABLE [a=14 b=1416 c=775 d=137] -- settable/void-call (inferred)
  e[15] = e[235][K(0)]  -- GETINDEX? [a=235 b=0 c=15 d=nil]
  call(e[15], e[1007])  -- CALL [a=15 b=14 c=1007 d=nil] -- void call
  e[15] = e[306][K(0)]  -- GETINDEX? [a=306 b=0 c=15 d=nil]
  call(e[15], e[2390])  -- CALL [a=15 b=14 c=2390 d=nil] -- void call
  e[14][K(74)] = e[682]  -- SETTABLE [a=14 b=74 c=682 d=36] -- settable/void-call (inferred)
  e[14][K(272)] = e[1735]  -- SETTABLE [a=14 b=272 c=1735 d=63] -- settable/void-call (inferred)
  e[15] = e[180][K(0)]  -- GETINDEX? [a=180 b=0 c=15 d=nil]
  call(e[15], e[430])  -- CALL [a=15 b=14 c=430 d=nil] -- void call
  ::L_425::
  goto L_834
  e[15] = e[15][K(15)]  -- GETTABLE [a=15 b=15 c=470 d=nil]
  call(e[15], e[2142])  -- CALL [a=15 b=14 c=2142 d=nil] -- void call
  e[15] = e[256][K(0)]  -- GETINDEX? [a=256 b=0 c=15 d=nil]
  call(e[15], e[626])  -- CALL [a=15 b=14 c=626 d=nil] -- void call
  goto L_430
  e[31] = {}  -- NEWTABLE [a=31 b=0 c=0 d=nil]
  e[33] = {}  -- NEWTABLE [a=0 b=33 c=0 d=nil]
  e[32] = {}  -- NEWTABLE [a=32 b=0 c=0 d=nil]
  e[33][K(1732)] = e[4]  -- SETTABLE [a=33 b=1732 c=4 d=880] -- settable/void-call (inferred)
  e[31][K(1732)] = e[104]  -- SETTABLE [a=31 b=1732 c=104 d=880] -- settable/void-call (inferred)
  e[32][K(1732)] = e[4]  -- SETTABLE [a=32 b=1732 c=4 d=880] -- settable/void-call (inferred)
  e[32][K(1405)] = e[1214]  -- SETTABLE [a=32 b=1405 c=1214 d=396] -- settable/void-call (inferred)
  call(e[37], e[30])  -- CALL? [a=37 b=0 c=30 d=nil] -- void call
  ::L_439::
  goto L_1181
  call(e[15], e[1267])  -- CALL [a=15 b=14 c=1267 d=nil] -- void call
  e[15] = e[346][K(0)]  -- GETINDEX? [a=346 b=0 c=15 d=nil]
  call(e[15], e[798])  -- CALL [a=15 b=14 c=798 d=nil] -- void call
  e[15] = e[312][K(0)]  -- GETINDEX? [a=312 b=0 c=15 d=nil]
  call(e[15], e[1897])  -- CALL [a=15 b=14 c=1897 d=nil] -- void call
  e[14][K(1857)] = e[1883]  -- SETTABLE [a=14 b=1857 c=1883 d=105] -- settable/void-call (inferred)
  e[15] = e[307][K(0)]  -- GETINDEX? [a=307 b=0 c=15 d=nil]
  ::L_447::
  goto L_820
  call(e[15], e[2067])  -- CALL [a=15 b=14 c=2067 d=nil] -- void call
  e[15] = e[270][K(0)]  -- GETINDEX? [a=270 b=0 c=15 d=nil]
  call(e[15], e[176])  -- CALL [a=15 b=14 c=176 d=nil] -- void call
  e[15] = e[221][K(0)]  -- GETINDEX? [a=221 b=0 c=15 d=nil]
  call(e[15], e[1371])  -- CALL [a=15 b=14 c=1371 d=nil] -- void call
  ::L_453::
  goto L_1243
  call(e[15], e[1540])  -- CALL [a=15 b=14 c=1540 d=nil] -- void call
  e[14][K(1668)] = e[498]  -- SETTABLE [a=14 b=1668 c=498 d=161] -- settable/void-call (inferred)
  e[15] = e[339][K(0)]  -- GETINDEX? [a=339 b=0 c=15 d=nil]
  call(e[15], e[386])  -- CALL [a=15 b=14 c=386 d=nil] -- void call
  e[15] = e[350][K(0)]  -- GETINDEX? [a=350 b=0 c=15 d=nil]
  ::L_459::
  goto L_1085
  e[15] = e[325][K(0)]  -- GETINDEX? [a=325 b=0 c=15 d=nil]
  call(e[15], e[642])  -- CALL [a=15 b=14 c=642 d=nil] -- void call
  e[15] = e[145][K(0)]  -- GETINDEX? [a=145 b=0 c=15 d=nil]
  call(e[15], e[1019])  -- CALL [a=15 b=14 c=1019 d=nil] -- void call
  ::L_464::
  goto L_1108
  e[14][K(1476)] = e[967]  -- SETTABLE [a=14 b=1476 c=967 d=80] -- settable/void-call (inferred)
  e[15] = e[260][K(0)]  -- GETINDEX? [a=260 b=0 c=15 d=nil]
  call(e[15], e[848])  -- CALL [a=15 b=14 c=848 d=nil] -- void call
  e[15] = e[326][K(0)]  -- GETINDEX? [a=326 b=0 c=15 d=nil]
  goto L_469
  e[14][K(1162)] = e[849]  -- SETTABLE [a=14 b=1162 c=849 d=141] -- settable/void-call (inferred)
  e[14][K(1847)] = e[245]  -- SETTABLE [a=14 b=1847 c=245 d=188] -- settable/void-call (inferred)
  e[15] = e[104][K(0)]  -- GETINDEX? [a=104 b=0 c=15 d=nil]
  call(e[15], e[341])  -- CALL [a=15 b=14 c=341 d=nil] -- void call
  e[15] = e[62][K(0)]  -- GETINDEX? [a=62 b=0 c=15 d=nil]
  ::L_475::
  goto L_775
  e[15] = e[55][K(0)]  -- GETINDEX? [a=55 b=0 c=15 d=nil]
  e[80][K(14)] = e[97]  -- SETTABLE/CALL [a=80 b=14 c=97 d=nil] -- settable/void-call (inferred)
  e[96][K(212)] = e[1922]  -- SETTABLE/CALL [a=96 b=212 c=1922 d=nil] -- settable/void-call (inferred)
  call(e[89], e[189])  -- CALL [a=89 b=27 c=189 d=nil] -- void call
  call(e[15], e[45])  -- CALL [a=15 b=90 c=45 d=nil] -- void call
  e[15] = e[51][K(0)]  -- GETINDEX? [a=51 b=0 c=15 d=nil]
  call(e[15], e[1776])  -- CALL [a=15 b=14 c=1776 d=nil] -- void call
  e[15] = e[110][K(0)]  -- GETINDEX? [a=110 b=0 c=15 d=nil]
  goto L_484
  call(e[15], e[1475])  -- CALL [a=15 b=14 c=1475 d=nil] -- void call
  e[15] = e[7][K(0)]  -- GETINDEX? [a=7 b=0 c=15 d=nil]
  call(e[15], e[221])  -- CALL [a=15 b=14 c=221 d=nil] -- void call
  goto L_488
  e[15] = e[167][K(0)]  -- GETINDEX? [a=167 b=0 c=15 d=nil]
  call(e[15], e[1390])  -- CALL [a=15 b=14 c=1390 d=nil] -- void call
  e[14][K(1978)] = e[765]  -- SETTABLE [a=14 b=1978 c=765 d=123] -- settable/void-call (inferred)
  e[15] = e[219][K(0)]  -- GETINDEX? [a=219 b=0 c=15 d=nil]
  call(e[15], e[617])  -- CALL [a=15 b=14 c=617 d=nil] -- void call
  e[15] = e[252][K(0)]  -- GETINDEX? [a=252 b=0 c=15 d=nil]
  goto L_495
  e[15] = e[241][K(0)]  -- GETINDEX? [a=241 b=0 c=15 d=nil]
  call(e[15], e[1446])  -- CALL [a=15 b=14 c=1446 d=nil] -- void call
  e[14][K(968)] = e[455]  -- SETTABLE [a=14 b=968 c=455 d=135] -- settable/void-call (inferred)
  e[15] = e[278][K(0)]  -- GETINDEX? [a=278 b=0 c=15 d=nil]
  call(e[15], e[2387])  -- CALL [a=15 b=14 c=2387 d=nil] -- void call
  e[15] = e[190][K(0)]  -- GETINDEX? [a=190 b=0 c=15 d=nil]
  call(e[15], e[2052])  -- CALL [a=15 b=14 c=2052 d=nil] -- void call
  e[15] = call(e[15], e[0])  -- GETGLOBAL/CALL [a=15 b=1735 c=0 d=tonumber]
  call(e[15], e[1757])  -- CALL [a=15 b=14 c=1757 d=nil] -- void call
  ::L_505::
  goto L_988
  e[21] = {}  -- NEWTABLE [a=21 b=0 c=0 d=nil]
  e[19] = {}  -- NEWTABLE [a=19 b=0 c=0 d=nil]
  e[25] = 969  -- LOADK_N [a=2262 b=1953 c=25 d=505]
  e[25] = arith(e[25], e[1406])  -- ARITH [a=25 b=25 c=1406 d=nil]  -- = 609
  e[25] = e[25] + 19776  -- ADD [a=25 b=1723 c=25 d=19776]  -- = 20385
  e[25] = arith(e[25], e[1481])  -- UNOP/arith? [a=25 b=25 c=1481 d=nil]  -- = 206
  call(e[25], e[523])  -- CALL [a=25 b=21 c=523 d=nil] -- void call
  e[19][K(1112)] = e[1760]  -- SETTABLE [a=19 b=1112 c=1760 d=950] -- settable/void-call (inferred)
  call(e[29], e[17])  -- CALL? [a=29 b=0 c=17 d=nil] -- void call
  ::L_516::
  goto L_612
  e[14][K(1935)] = e[412]  -- SETTABLE [a=14 b=1935 c=412 d=22] -- settable/void-call (inferred)
  e[15] = e[38][K(0)]  -- GETINDEX? [a=38 b=0 c=15 d=nil]
  call(e[15], e[891])  -- CALL [a=15 b=14 c=891 d=nil] -- void call
  e[15] = e[50][K(0)]  -- GETINDEX? [a=50 b=0 c=15 d=nil]
  call(e[15], e[182])  -- CALL [a=15 b=14 c=182 d=nil] -- void call
  e[15] = e[98][K(0)]  -- GETINDEX? [a=98 b=0 c=15 d=nil]
  goto L_523
  e[15] = e[363][K(0)]  -- GETINDEX? [a=363 b=0 c=15 d=nil]
  call(e[15], e[718])  -- CALL [a=15 b=14 c=718 d=nil] -- void call
  e[15] = call(e[15], e[0])  -- GETGLOBAL/CALL [a=15 b=1190 c=0 d=Enum]
  goto L_528
  call(e[15], e[323])  -- CALL [a=15 b=14 c=323 d=nil] -- void call
  e[14][K(613)] = e[831]  -- SETTABLE [a=14 b=613 c=831 d=15] -- settable/void-call (inferred)
  e[15] = e[124][K(0)]  -- GETINDEX? [a=124 b=0 c=15 d=nil]
  call(e[15], e[338])  -- CALL [a=15 b=14 c=338 d=nil] -- void call
  e[15] = e[47][K(0)]  -- GETINDEX? [a=47 b=0 c=15 d=nil]
  ::L_534::
  goto L_352
  ::L_535::
  goto L_1379
  e[15] = e[342][K(0)]  -- GETINDEX? [a=342 b=0 c=15 d=nil]
  call(e[15], e[1982])  -- CALL [a=15 b=14 c=1982 d=nil] -- void call
  e[15] = e[308][K(0)]  -- GETINDEX? [a=308 b=0 c=15 d=nil]
  call(e[15], e[2109])  -- CALL [a=15 b=14 c=2109 d=nil] -- void call
  e[14][K(1497)] = e[828]  -- SETTABLE [a=14 b=1497 c=828 d=145] -- settable/void-call (inferred)
  goto L_541
  e[14][K(1660)] = e[492]  -- SETTABLE [a=14 b=1660 c=492 d=82] -- settable/void-call (inferred)
  e[15] = e[217][K(0)]  -- GETINDEX? [a=217 b=0 c=15 d=nil]
  call(e[15], e[363])  -- CALL [a=15 b=14 c=363 d=nil] -- void call
  e[15] = call(e[15], e[55])  -- GETGLOBAL/CALL [a=15 b=1724 c=55 d=pcall]
  ::L_546::
  goto L_887
  call(e[15], e[148])  -- CALL [a=15 b=14 c=148 d=nil] -- void call
  e[15] = call(e[15], e[0])  -- GETGLOBAL/CALL [a=15 b=1908 c=0 d=Vector2]
  call(e[15], e[393])  -- CALL [a=15 b=14 c=393 d=nil] -- void call
  e[14][K(354)] = e[1207]  -- SETTABLE [a=14 b=354 c=1207 d=16] -- settable/void-call (inferred)
  e[15] = e[211][K(0)]  -- GETINDEX? [a=211 b=0 c=15 d=nil]
  call(e[15], e[2130])  -- CALL [a=15 b=14 c=2130 d=nil] -- void call
  e[15] = e[186][K(0)]  -- GETINDEX? [a=186 b=0 c=15 d=nil]
  call(e[15], e[415])  -- CALL [a=15 b=14 c=415 d=nil] -- void call
  e[15] = e[251][K(0)]  -- GETINDEX? [a=251 b=0 c=15 d=nil]
  call(e[15], e[1104])  -- CALL [a=15 b=14 c=1104 d=nil] -- void call
  goto L_558
  call(e[15], e[1813])  -- CALL [a=15 b=14 c=1813 d=nil] -- void call
  e[14][K(1327)] = e[1795]  -- SETTABLE [a=14 b=1327 c=1795 d=77] -- settable/void-call (inferred)
  e[15] = e[261][K(0)]  -- GETINDEX? [a=261 b=0 c=15 d=nil]
  call(e[15], e[1526])  -- CALL [a=15 b=14 c=1526 d=nil] -- void call
  e[15] = e[141][K(0)]  -- GETINDEX? [a=141 b=0 c=15 d=nil]
  call(e[15], e[392])  -- CALL [a=15 b=14 c=392 d=nil] -- void call
  e[14][K(196)] = e[456]  -- SETTABLE [a=14 b=196 c=456 d=93] -- settable/void-call (inferred)
  e[15] = e[319][K(0)]  -- GETINDEX? [a=319 b=0 c=15 d=nil]
  call(e[15], e[1479])  -- CALL [a=15 b=14 c=1479 d=nil] -- void call
  e[14][K(982)] = e[807]  -- SETTABLE [a=14 b=982 c=807 d=130] -- settable/void-call (inferred)
  goto L_569
  call(e[15], e[958])  -- CALL [a=15 b=14 c=958 d=nil] -- void call
  e[15] = e[359][K(0)]  -- GETINDEX? [a=359 b=0 c=15 d=nil]
  call(e[15], e[327])  -- CALL [a=15 b=14 c=327 d=nil] -- void call
  goto L_573
  call(e[15], e[1718])  -- CALL [a=15 b=14 c=1718 d=nil] -- void call
  e[15] = e[314][K(0)]  -- GETINDEX? [a=314 b=0 c=15 d=nil]
  call(e[15], e[255])  -- CALL [a=15 b=14 c=255 d=nil] -- void call
  e[15] = e[258][K(0)]  -- GETINDEX? [a=258 b=0 c=15 d=nil]
  goto L_578
  e[14][K(1829)] = e[1398]  -- SETTABLE [a=14 b=1829 c=1398 d=32] -- settable/void-call (inferred)
  e[15] = e[364][K(0)]  -- GETINDEX? [a=364 b=0 c=15 d=nil]
  call(e[15], e[252])  -- CALL [a=15 b=14 c=252 d=nil] -- void call
  ::L_582::
  goto L_1269
  e[15] = e[276][K(0)]  -- GETINDEX? [a=276 b=0 c=15 d=nil]
  call(e[15], e[1115])  -- CALL [a=15 b=14 c=1115 d=nil] -- void call
  e[15] = e[332][K(0)]  -- GETINDEX? [a=332 b=0 c=15 d=nil]
  call(e[15], e[596])  -- CALL [a=15 b=14 c=596 d=nil] -- void call
  ::L_587::
  goto L_1309
  call(e[15], e[1669])  -- CALL [a=15 b=14 c=1669 d=nil] -- void call
  e[15] = e[60][K(0)]  -- GETINDEX? [a=60 b=0 c=15 d=nil]
  call(e[15], e[708])  -- CALL [a=15 b=14 c=708 d=nil] -- void call
  goto L_591
  e[15] = e[113][K(0)]  -- GETINDEX? [a=113 b=0 c=15 d=nil]
  call(e[15], e[1616])  -- CALL [a=15 b=14 c=1616 d=nil] -- void call
  e[15] = e[33][K(0)]  -- GETINDEX? [a=33 b=0 c=15 d=nil]
  call(e[15], e[719])  -- CALL [a=15 b=14 c=719 d=nil] -- void call
  e[15] = e[3][K(0)]  -- GETINDEX? [a=3 b=0 c=15 d=nil]
  call(e[15], e[189])  -- CALL [a=15 b=14 c=189 d=nil] -- void call
  e[15] = e[92][K(0)]  -- GETINDEX? [a=92 b=0 c=15 d=nil]
  goto L_599
  e[14][K(864)] = e[1885]  -- SETTABLE [a=14 b=864 c=1885 d=172] -- settable/void-call (inferred)
  e[15] = e[70][K(0)]  -- GETINDEX? [a=70 b=0 c=15 d=nil]
  call(e[15], e[349])  -- CALL [a=15 b=14 c=349 d=nil] -- void call
  e[14][K(1651)] = e[259]  -- SETTABLE [a=14 b=1651 c=259 d=114] -- settable/void-call (inferred)
  e[15] = e[12][K(0)]  -- GETINDEX? [a=12 b=0 c=15 d=nil]
  goto L_605
  call(e[15], e[2262])  -- CALL [a=15 b=14 c=2262 d=nil] -- void call
  e[15] = e[111][K(0)]  -- GETINDEX? [a=111 b=0 c=15 d=nil]
  call(e[15], e[403])  -- CALL [a=15 b=14 c=403 d=nil] -- void call
  e[15] = e[114][K(0)]  -- GETINDEX? [a=114 b=0 c=15 d=nil]
  call(e[15], e[1404])  -- CALL [a=15 b=14 c=1404 d=nil] -- void call
  e[15] = e[30][K(0)]  -- GETINDEX? [a=30 b=0 c=15 d=nil]
  ::L_612::
  goto L_49
  call(e[15], e[1058])  -- CALL [a=15 b=14 c=1058 d=nil] -- void call
  e[12] = e[237][K(0)]  -- GETINDEX? [a=237 b=0 c=12 d=nil]
  call(e[15], e[1121])  -- CALL [a=15 b=14 c=1121 d=nil] -- void call
  e[14][K(2062)] = e[1983]  -- SETTABLE [a=14 b=2062 c=1983 d=81] -- settable/void-call (inferred)
  e[15] = e[236][K(0)]  -- GETINDEX? [a=236 b=0 c=15 d=nil]
  call(e[15], e[1973])  -- CALL [a=15 b=14 c=1973 d=nil] -- void call
  e[15] = e[347][K(0)]  -- GETINDEX? [a=347 b=0 c=15 d=nil]
  ::L_620::
  goto L_252
  e[15] = e[100][K(0)]  -- GETINDEX? [a=100 b=0 c=15 d=nil]
  call(e[15], e[1326])  -- CALL [a=15 b=14 c=1326 d=nil] -- void call
  e[15] = e[4][K(0)]  -- GETINDEX? [a=4 b=0 c=15 d=nil]
  call(e[15], e[996])  -- CALL [a=15 b=14 c=996 d=nil] -- void call
  e[14][K(671)] = e[302]  -- SETTABLE [a=14 b=671 c=302 d=173] -- settable/void-call (inferred)
  e[15] = e[97][K(0)]  -- GETINDEX? [a=97 b=0 c=15 d=nil]
  call(e[15], e[818])  -- CALL [a=15 b=14 c=818 d=nil] -- void call
  goto L_628
  e[15] = e[53][K(0)]  -- GETINDEX? [a=53 b=0 c=15 d=nil]
  call(e[15], e[1151])  -- CALL [a=15 b=14 c=1151 d=nil] -- void call
  e[15] = call(e[15], e[0])  -- GETGLOBAL/CALL [a=15 b=1876 c=0 d=setmetatable]
  call(e[15], e[2071])  -- CALL [a=15 b=14 c=2071 d=nil] -- void call
  e[15] = e[82][K(0)]  -- GETINDEX? [a=82 b=0 c=15 d=nil]
  ::L_634::
  goto L_1397
  call(e[15], e[726])  -- CALL [a=15 b=14 c=726 d=nil] -- void call
  e[14][K(1658)] = e[1524]  -- SETTABLE [a=14 b=1658 c=1524 d=162] -- settable/void-call (inferred)
  e[15] = e[214][K(0)]  -- GETINDEX? [a=214 b=0 c=15 d=nil]
  call(e[15], e[1898])  -- CALL [a=15 b=14 c=1898 d=nil] -- void call
  e[15] = e[169][K(0)]  -- GETINDEX? [a=169 b=0 c=15 d=nil]
  goto L_640
  e[14][K(2040)] = e[2327]  -- SETTABLE [a=14 b=2040 c=2327 d=169] -- settable/void-call (inferred)
  e[15] = call(e[15], e[0])  -- GETGLOBAL/CALL [a=15 b=2077 c=0 d=debug]
  call(e[15], e[1610])  -- CALL [a=15 b=14 c=1610 d=nil] -- void call
  ::L_644::
  goto L_1258
  if e[25] then goto L_346 else goto L_646 end  -- back-edge (loop)
  call(e[15], e[1374])  -- CALL [a=15 b=14 c=1374 d=nil] -- void call
  e[15] = e[196][K(0)]  -- GETINDEX? [a=196 b=0 c=15 d=nil]
  call(e[15], e[1099])  -- CALL [a=15 b=14 c=1099 d=nil] -- void call
  e[15] = e[356][K(0)]  -- GETINDEX? [a=356 b=0 c=15 d=nil]
  goto L_651
  call(e[15], e[1584])  -- CALL [a=15 b=14 c=1584 d=nil] -- void call
  e[14][K(2115)] = e[2206]  -- SETTABLE [a=14 b=2115 c=2206 d=129] -- settable/void-call (inferred)
  e[15] = call(e[15], e[0])  -- GETGLOBAL/CALL [a=15 b=2035 c=0 d=utf8]
  ::L_656::
  goto L_425
  e[20] = {}  -- NEWTABLE [a=0 b=20 c=0 d=nil]
  e[19] = {}  -- NEWTABLE [a=19 b=0 c=0 d=nil]
  e[25] = K(17)  -- LOADK_S [a=0 b=17 c=25 d=nil]
  e[26] = -2  -- LOADK_N [a=1810 b=26 c=1440 d=nil]
  e[25] = 1  -- LOADK_N [a=0 b=0 c=25 d=nil]
  e[25] = e[25] + 6318  -- ADD [a=25 b=785 c=25 d=6318]  -- = 6319
  e[25] = arith(e[25], e[2095])  -- UNOP/arith? [a=25 b=25 c=2095 d=nil]  -- = 15
  call(e[25], e[2])  -- CALL [a=25 b=20 c=2 d=nil] -- void call
  e[19][K(988)] = e[54]  -- SETTABLE [a=19 b=988 c=54 d=312] -- settable/void-call (inferred)
  call(e[29], e[17])  -- CALL? [a=29 b=0 c=17 d=nil] -- void call
  goto L_667
  e[25] = K(221)  -- LOADK [a=25 b=221 c=0 d=370]
  ::L_669::
  goto L_346
  e[14][K(1828)] = e[2024]  -- SETTABLE [a=14 b=1828 c=2024 d=12] -- settable/void-call (inferred)
  e[15] = e[301][K(0)]  -- GETINDEX? [a=301 b=0 c=15 d=nil]
  call(e[15], e[872])  -- CALL [a=15 b=14 c=872 d=nil] -- void call
  ::L_673::
  goto L_33
  ::L_674::
  goto L_1025
  call(e[15], e[1410])  -- CALL [a=15 b=14 c=1410 d=nil] -- void call
  e[14][K(1954)] = e[912]  -- SETTABLE [a=14 b=1954 c=912 d=30] -- settable/void-call (inferred)
  e[14][K(846)] = e[935]  -- SETTABLE [a=14 b=846 c=935 d=179] -- settable/void-call (inferred)
  e[15] = e[352][K(0)]  -- GETINDEX? [a=352 b=0 c=15 d=nil]
  call(e[15], e[397])  -- CALL [a=15 b=14 c=397 d=nil] -- void call
  e[15] = e[242][K(0)]  -- GETINDEX? [a=242 b=0 c=15 d=nil]
  ::L_681::
  goto L_1212
  call(e[15], e[806])  -- CALL [a=15 b=14 c=806 d=nil] -- void call
  e[15] = e[257][K(0)]  -- GETINDEX? [a=257 b=0 c=15 d=nil]
  call(e[15], e[942])  -- CALL [a=15 b=14 c=942 d=nil] -- void call
  goto L_685
  call(e[15], e[1693])  -- CALL [a=15 b=14 c=1693 d=nil] -- void call
  e[15] = e[209][K(0)]  -- GETINDEX? [a=209 b=0 c=15 d=nil]
  call(e[15], e[832])  -- CALL [a=15 b=14 c=832 d=nil] -- void call
  goto L_689
  call(e[15], e[1093])  -- CALL [a=15 b=14 c=1093 d=nil] -- void call
  e[15] = e[338][K(0)]  -- GETINDEX? [a=338 b=0 c=15 d=nil]
  call(e[15], e[2013])  -- CALL [a=15 b=14 c=2013 d=nil] -- void call
  e[14][K(658)] = e[2415]  -- SETTABLE [a=14 b=658 c=2415 d=140] -- settable/void-call (inferred)
  e[14][K(1048)] = e[1927]  -- SETTABLE [a=14 b=1048 c=1927 d=153] -- settable/void-call (inferred)
  goto L_695
  e[19] = {}  -- NEWTABLE [a=19 b=0 c=0 d=nil]
  e[21] = {}  -- NEWTABLE [a=21 b=0 c=0 d=nil]
  e[25] = K(20)  -- LOADK_S [a=0 b=20 c=25 d=nil]
  e[26] = K(9)  -- LOADK_S [a=0 b=9 c=26 d=nil]
  e[27] = "222"  -- LOADK [a=27 b=1800 c=0 d=�]
  e[28] = 1  -- LOADK [a=28 b=107 c=0 d=1]
  call(e[29], e[0])  -- CALL [a=29 b=0 c=0 d=nil] -- void call
  e[26] = 222  -- LOADK_N [a=0 b=26 c=4 d=nil]
  e[27] = 4  -- LOADK [a=27 b=70 c=0 d=4]
  e[25] = 3758096397  -- LOADK_N [a=0 b=25 c=0 d=nil]
  e[26] = K(9)  -- LOADK_S [a=0 b=9 c=26 d=nil]
  e[27] = "194142145190^"  -- LOADK [a=27 b=1691 c=0 d=��^]
  e[28] = 5  -- LOADK [a=28 b=18 c=0 d=5]
  call(e[29], e[0])  -- CALL [a=29 b=0 c=0 d=nil] -- void call
  e[26] = 94  -- LOADK_N [a=0 b=26 c=4 d=nil]
  e[25] = (e[26] == e[25])  -- COMPARE [a=26 b=25 c=25 d=nil]  -- = true
  if e[25] then goto L_1188 else goto L_713 end
  e[15] = call(e[15], e[0])  -- GETGLOBAL/CALL [a=15 b=967 c=0 d=rawset]
  call(e[15], e[210])  -- CALL [a=15 b=14 c=210 d=nil] -- void call
  e[15] = e[84][K(0)]  -- GETINDEX? [a=84 b=0 c=15 d=nil]
  call(e[15], e[562])  -- CALL [a=15 b=14 c=562 d=nil] -- void call
  e[15] = e[83][K(0)]  -- GETINDEX? [a=83 b=0 c=15 d=nil]
  goto L_719
  e[15] = e[194][K(0)]  -- GETINDEX? [a=194 b=0 c=15 d=nil]
  call(e[15], e[1993])  -- CALL [a=15 b=14 c=1993 d=nil] -- void call
  e[15] = e[288][K(0)]  -- GETINDEX? [a=288 b=0 c=15 d=nil]
  goto L_723
  e[14][K(280)] = e[2282]  -- SETTABLE [a=14 b=280 c=2282 d=186] -- settable/void-call (inferred)
  e[14][K(2186)] = e[654]  -- SETTABLE [a=14 b=2186 c=654 d=86] -- settable/void-call (inferred)
  e[14][K(1414)] = e[1600]  -- SETTABLE [a=14 b=1414 c=1600 d=121] -- settable/void-call (inferred)
  goto L_727
  e[32] = {}  -- NEWTABLE [a=32 b=0 c=0 d=nil]
  e[34] = {}  -- NEWTABLE [a=34 b=0 c=0 d=nil]
  e[34][K(1703)] = e[53]  -- SETTABLE [a=34 b=1703 c=53 d=299] -- settable/void-call (inferred)
  e[32][K(75)] = e[1382]  -- SETTABLE [a=32 b=75 c=1382 d=92] -- settable/void-call (inferred)
  call(e[37], e[30])  -- CALL? [a=37 b=0 c=30 d=nil] -- void call
  ::L_733::
  goto L_280
  e[14][K(339)] = e[303]  -- SETTABLE [a=14 b=339 c=303 d=122] -- settable/void-call (inferred)
  e[15] = e[224][K(0)]  -- GETINDEX? [a=224 b=0 c=15 d=nil]
  call(e[15], e[1599])  -- CALL [a=15 b=14 c=1599 d=nil] -- void call
  goto L_737
  e[32] = {}  -- NEWTABLE [a=32 b=0 c=0 d=nil]
  e[31] = {}  -- NEWTABLE [a=31 b=0 c=0 d=nil]
  e[31][K(1026)] = e[22]  -- SETTABLE [a=31 b=1026 c=22 d=614] -- settable/void-call (inferred)
  e[32][K(2279)] = e[494]  -- SETTABLE [a=32 b=2279 c=494 d=547] -- settable/void-call (inferred)
  call(e[37], e[30])  -- CALL? [a=37 b=0 c=30 d=nil] -- void call
  goto L_743
  call(e[15], e[528])  -- CALL [a=15 b=14 c=528 d=nil] -- void call
  e[14][K(1591)] = e[859]  -- SETTABLE [a=14 b=1591 c=859 d=60] -- settable/void-call (inferred)
  e[15] = e[361][K(0)]  -- GETINDEX? [a=361 b=0 c=15 d=nil]
  call(e[15], e[573])  -- CALL [a=15 b=14 c=573 d=nil] -- void call
  ::L_748::
  goto L_459
  e[15] = call(e[15], e[0])  -- GETGLOBAL/CALL [a=15 b=1488 c=0 d=setfenv]
  call(e[15], e[407])  -- CALL [a=15 b=14 c=407 d=nil] -- void call
  e[14][K(558)] = e[1768]  -- SETTABLE [a=14 b=558 c=1768 d=157] -- settable/void-call (inferred)
  e[15] = e[19][K(0)]  -- GETINDEX? [a=19 b=0 c=15 d=nil]
  call(e[15], e[1245])  -- CALL [a=15 b=14 c=1245 d=nil] -- void call
  e[15] = call(e[15], e[0])  -- GETGLOBAL/CALL [a=15 b=1364 c=0 d=math]
  goto L_755
  call(e[15], e[1507])  -- CALL [a=15 b=14 c=1507 d=nil] -- void call
  e[15] = e[383][K(0)]  -- GETINDEX? [a=383 b=0 c=15 d=nil]
  call(e[15], e[293])  -- CALL [a=15 b=14 c=293 d=nil] -- void call
  e[15] = e[163][K(0)]  -- GETINDEX? [a=163 b=0 c=15 d=nil]
  call(e[15], e[1202])  -- CALL [a=15 b=14 c=1202 d=nil] -- void call
  e[15] = call(e[15], e[0])  -- GETGLOBAL/CALL [a=15 b=1464 c=0 d=table]
  call(e[15], e[283])  -- CALL [a=15 b=14 c=283 d=nil] -- void call
  e[15] = e[232][K(0)]  -- GETINDEX? [a=232 b=0 c=15 d=nil]
  call(e[15], e[1108])  -- CALL [a=15 b=14 c=1108 d=nil] -- void call
  ::L_765::
  goto L_673
  e[14][K(668)] = e[2284]  -- SETTABLE [a=14 b=668 c=2284 d=124] -- settable/void-call (inferred)
  e[15] = e[27][K(0)]  -- GETINDEX? [a=27 b=0 c=15 d=nil]
  call(e[15], e[2060])  -- CALL [a=15 b=14 c=2060 d=nil] -- void call
  goto L_769
  call(e[15], e[1737])  -- CALL [a=15 b=14 c=1737 d=nil] -- void call
  e[15] = e[292][K(0)]  -- GETINDEX? [a=292 b=0 c=15 d=nil]
  call(e[15], e[2082])  -- CALL [a=15 b=14 c=2082 d=nil] -- void call
  e[14][K(649)] = e[391]  -- SETTABLE [a=14 b=649 c=391 d=178] -- settable/void-call (inferred)
  e[15] = e[227][K(0)]  -- GETINDEX? [a=227 b=0 c=15 d=nil]
  ::L_775::
  goto L_546
  call(e[15], e[2166])  -- CALL [a=15 b=14 c=2166 d=nil] -- void call
  e[15] = e[65][K(0)]  -- GETINDEX? [a=65 b=0 c=15 d=nil]
  call(e[15], e[819])  -- CALL [a=15 b=14 c=819 d=nil] -- void call
  e[15] = e[94][K(0)]  -- GETINDEX? [a=94 b=0 c=15 d=nil]
  goto L_780
  e[14][K(242)] = e[693]  -- SETTABLE [a=14 b=242 c=693 d=112] -- settable/void-call (inferred)
  e[15] = e[66][K(0)]  -- GETINDEX? [a=66 b=0 c=15 d=nil]
  call(e[15], e[1500])  -- CALL [a=15 b=14 c=1500 d=nil] -- void call
  ::L_784::
  goto L_370
  e[15] = e[233][K(0)]  -- GETINDEX? [a=233 b=0 c=15 d=nil]
  call(e[15], e[1547])  -- CALL [a=15 b=14 c=1547 d=nil] -- void call
  e[14][K(1848)] = e[1258]  -- SETTABLE [a=14 b=1848 c=1258 d=83] -- settable/void-call (inferred)
  goto L_788
  e[25] = K(13)  -- LOADK_S [a=0 b=13 c=25 d=nil]
  e[26] = K(790)  -- LOADK [a=26 b=790 c=0 d===>>l]
  e[25] = K(0)  -- LOADK_N [a=0 b=0 c=25 d=nil]
  ::L_792::
  goto L_1295
  call(e[15], e[1992])  -- CALL [a=15 b=14 c=1992 d=nil] -- void call
  e[15] = e[59][K(0)]  -- GETINDEX? [a=59 b=0 c=15 d=nil]
  call(e[15], e[1991])  -- CALL [a=15 b=14 c=1991 d=nil] -- void call
  e[14][K(1502)] = e[514]  -- SETTABLE [a=14 b=1502 c=514 d=176] -- settable/void-call (inferred)
  goto L_797
  e[15] = call(e[15], e[0])  -- GETGLOBAL/CALL [a=15 b=1398 c=0 d=unpack]
  call(e[15], e[358])  -- CALL [a=15 b=14 c=358 d=nil] -- void call
  e[15] = e[268][K(0)]  -- GETINDEX? [a=268 b=0 c=15 d=nil]
  ::L_801::
  goto L_197
  call(e[15], e[506])  -- CALL [a=15 b=14 c=506 d=nil] -- void call
  e[15] = e[335][K(0)]  -- GETINDEX? [a=335 b=0 c=15 d=nil]
  call(e[15], e[1200])  -- CALL [a=15 b=14 c=1200 d=nil] -- void call
  goto L_805
  e[15] = e[153][K(0)]  -- GETINDEX? [a=153 b=0 c=15 d=nil]
  call(e[15], e[1428])  -- CALL [a=15 b=14 c=1428 d=nil] -- void call
  e[15] = e[315][K(0)]  -- GETINDEX? [a=315 b=0 c=15 d=nil]
  call(e[15], e[1953])  -- CALL [a=15 b=14 c=1953 d=nil] -- void call
  ::L_810::
  goto L_1064
  e[15] = call(e[15], e[0])  -- GETGLOBAL/CALL [a=15 b=1567 c=0 d=getmetatable]
  call(e[15], e[78])  -- CALL [a=15 b=14 c=78 d=nil] -- void call
  e[14][K(1353)] = e[763]  -- SETTABLE [a=14 b=1353 c=763 d=10] -- settable/void-call (inferred)
  ::L_814::
  goto L_1041
  e[15] = e[271][K(0)]  -- GETINDEX? [a=271 b=0 c=15 d=nil]
  call(e[15], e[1781])  -- CALL [a=15 b=14 c=1781 d=nil] -- void call
  e[15] = e[373][K(0)]  -- GETINDEX? [a=373 b=0 c=15 d=nil]
  call(e[15], e[1237])  -- CALL [a=15 b=14 c=1237 d=nil] -- void call
  e[15] = e[166][K(0)]  -- GETINDEX? [a=166 b=0 c=15 d=nil]
  ::L_820::
  goto L_534
  call(e[15], e[1852])  -- CALL [a=15 b=14 c=1852 d=nil] -- void call
  e[1802] = {}  -- NEWTABLE [a=14 b=1802 c=1098 d=34]
  e[14][K(782)] = e[276]  -- SETTABLE [a=14 b=782 c=276 d=108] -- settable/void-call (inferred)
  e[15] = e[344][K(0)]  -- GETINDEX? [a=344 b=0 c=15 d=nil]
  call(e[15], e[1024])  -- CALL [a=15 b=14 c=1024 d=nil] -- void call
  e[14][K(1607)] = e[2225]  -- SETTABLE [a=14 b=1607 c=2225 d=181] -- settable/void-call (inferred)
  ::L_827::
  goto L_814
  e[14][K(360)] = e[1744]  -- SETTABLE [a=14 b=360 c=1744 d=118] -- settable/void-call (inferred)
  e[15] = e[282][K(0)]  -- GETINDEX? [a=282 b=0 c=15 d=nil]
  call(e[15], e[889])  -- CALL [a=15 b=14 c=889 d=nil] -- void call
  e[15] = e[155][K(0)]  -- GETINDEX? [a=155 b=0 c=15 d=nil]
  call(e[15], e[1581])  -- CALL [a=15 b=14 c=1581 d=nil] -- void call
  e[15] = e[192][K(0)]  -- GETINDEX? [a=192 b=0 c=15 d=nil]
  ::L_834::
  goto L_842
  e[15] = call(e[15], e[0])  -- GETGLOBAL/CALL [a=15 b=1539 c=0 d=bit32]
  call(e[15], e[438])  -- CALL [a=15 b=14 c=438 d=nil] -- void call
  e[15] = e[323][K(0)]  -- GETINDEX? [a=323 b=0 c=15 d=nil]
  call(e[15], e[372])  -- CALL [a=15 b=14 c=372 d=nil] -- void call
  e[15] = e[293][K(0)]  -- GETINDEX? [a=293 b=0 c=15 d=nil]
  call(e[15], e[1513])  -- CALL [a=15 b=14 c=1513 d=nil] -- void call
  e[14][K(31)] = e[657]  -- SETTABLE [a=14 b=31 c=657 d=40] -- settable/void-call (inferred)
  ::L_842::
  goto L_1391
  call(e[15], e[518])  -- CALL [a=15 b=14 c=518 d=nil] -- void call
  e[15] = e[137][K(0)]  -- GETINDEX? [a=137 b=0 c=15 d=nil]
  call(e[15], e[1624])  -- CALL [a=15 b=14 c=1624 d=nil] -- void call
  ::L_846::
  goto L_464
  e[15] = e[136][K(0)]  -- GETINDEX? [a=136 b=0 c=15 d=nil]
  call(e[15], e[1916])  -- CALL [a=15 b=14 c=1916 d=nil] -- void call
  e[15] = e[298][K(0)]  -- GETINDEX? [a=298 b=0 c=15 d=nil]
  call(e[15], e[1791])  -- CALL [a=15 b=14 c=1791 d=nil] -- void call
  e[15] = call(e[15], e[0])  -- GETGLOBAL/CALL [a=15 b=589 c=0 d=identifyexecutor]
  call(e[15], e[1913])  -- CALL [a=15 b=14 c=1913 d=nil] -- void call
  e[15] = e[285][K(0)]  -- GETINDEX? [a=285 b=0 c=15 d=nil]
  call(e[15], e[2329])  -- CALL [a=15 b=14 c=2329 d=nil] -- void call
  goto L_855
  call(e[15], e[292])  -- CALL [a=15 b=14 c=292 d=nil] -- void call
  e[15] = call(e[15], e[0])  -- GETGLOBAL/CALL [a=15 b=1983 c=0 d=xpcall]
  call(e[15], e[1959])  -- CALL [a=15 b=14 c=1959 d=nil] -- void call
  e[14][K(584)] = e[1746]  -- SETTABLE [a=14 b=584 c=1746 d=136] -- settable/void-call (inferred)
  ::L_860::
  goto L_810
  e[21] = {}  -- NEWTABLE [a=21 b=0 c=0 d=nil]
  e[19] = {}  -- NEWTABLE [a=19 b=0 c=0 d=nil]
  e[25] = K(16)  -- LOADK_S [a=0 b=16 c=25 d=nil]
  e[26] = 388  -- LOADK [a=26 b=621 c=0 d=388]
  e[25] = 388  -- LOADK_N [a=0 b=0 c=25 d=nil]
  e[26] = K(13)  -- LOADK_S [a=0 b=13 c=26 d=nil]
  e[27] = "><  H<T> l==h <"  -- LOADK [a=27 b=1963 c=0 d=><]
  e[26] = 16  -- LOADK_N [a=0 b=0 c=26 d=nil]
  e[25] = arith(e[25], e[25])  -- ARITH [a=26 b=25 c=25 d=nil]  -- = 372
  e[25] = e[25] + 4942  -- ADD [a=25 b=1569 c=25 d=4942]  -- = 5314
  e[25] = arith(e[25], e[2204])  -- UNOP/arith? [a=25 b=25 c=2204 d=nil]  -- = 50
  call(e[25], e[2336])  -- CALL [a=25 b=21 c=2336 d=nil] -- void call
  e[19][K(235)] = e[1627]  -- SETTABLE [a=19 b=235 c=1627 d=897] -- settable/void-call (inferred)
  call(e[29], e[17])  -- CALL? [a=29 b=0 c=17 d=nil] -- void call
  goto L_875
  e[20] = {}  -- NEWTABLE [a=0 b=20 c=0 d=nil]
  e[19] = {}  -- NEWTABLE [a=19 b=0 c=0 d=nil]
  e[25] = K(13)  -- LOADK_S [a=0 b=13 c=25 d=nil]
  e[26] = "  nc213<< H<="  -- LOADK [a=26 b=730 c=0]
  e[167] = 223  -- LOADK_N [a=81 b=4 c=167 d=nil]
  e[25] = (e[25] == e[25])  -- COMPARE [a=25 b=274 c=25 d=267]  -- = false
  if e[25] then goto L_1112 else goto L_883 end
  call(e[15], e[2056])  -- CALL [a=15 b=14 c=2056 d=nil] -- void call
  e[14][K(1220)] = e[2087]  -- SETTABLE [a=14 b=1220 c=2087 d=74] -- settable/void-call (inferred)
  e[14][K(1060)] = e[773]  -- SETTABLE [a=14 b=1060 c=773 d=158] -- settable/void-call (inferred)
  ::L_887::
  goto L_356
  call(e[15], e[2274])  -- CALL [a=15 b=14 c=2274 d=nil] -- void call
  e[15] = e[130][K(0)]  -- GETINDEX? [a=130 b=0 c=15 d=nil]
  e[165][K(14)] = e[71]  -- SETTABLE/CALL [a=165 b=14 c=71 d=nil] -- settable/void-call (inferred)
  e[191][K(79)] = e[206]  -- SETTABLE/CALL [a=191 b=79 c=206 d=nil] -- settable/void-call (inferred)
  call(e[147], e[133])  -- CALL [a=147 b=245 c=133 d=nil] -- void call
  call(e[15], e[126])  -- CALL [a=15 b=124 c=126 d=nil] -- void call
  e[15] = call(e[15], e[0])  -- GETGLOBAL/CALL [a=15 b=677 c=0 d=rawget]
  call(e[15], e[70])  -- CALL [a=15 b=14 c=70 d=nil] -- void call
  ::L_896::
  goto L_153
  ::L_897::
  goto L_860
  e[15] = e[243][K(0)]  -- GETINDEX? [a=243 b=0 c=15 d=nil]
  call(e[15], e[224])  -- CALL [a=15 b=14 c=224 d=nil] -- void call
  e[15] = e[274][K(0)]  -- GETINDEX? [a=274 b=0 c=15 d=nil]
  goto L_901
  e[15] = e[159][K(0)]  -- GETINDEX? [a=159 b=0 c=15 d=nil]
  call(e[15], e[2085])  -- CALL [a=15 b=14 c=2085 d=nil] -- void call
  e[15] = e[305][K(0)]  -- GETINDEX? [a=305 b=0 c=15 d=nil]
  call(e[15], e[1671])  -- CALL [a=15 b=14 c=1671 d=nil] -- void call
  goto L_906
  e[32] = {}  -- NEWTABLE [a=32 b=0 c=0 d=nil]
  e[34] = {}  -- NEWTABLE [a=34 b=0 c=0 d=nil]
  e[34][K(1169)] = e[71]  -- SETTABLE [a=34 b=1169 c=71 d=822] -- settable/void-call (inferred)
  e[32][K(2414)] = e[1879]  -- SETTABLE [a=32 b=2414 c=1879 d=506] -- settable/void-call (inferred)
  call(e[37], e[30])  -- CALL? [a=37 b=0 c=30 d=nil] -- void call
  ::L_912::
  goto L_439
  call(e[15], e[665])  -- CALL [a=15 b=14 c=665 d=nil] -- void call
  e[15] = call(e[15], e[0])  -- GETGLOBAL/CALL [a=15 b=1940 c=0 d=type]
  call(e[15], e[2280])  -- CALL [a=15 b=14 c=2280 d=nil] -- void call
  e[15] = e[376][K(0)]  -- GETINDEX? [a=376 b=0 c=15 d=nil]
  call(e[15], e[1780])  -- CALL [a=15 b=14 c=1780 d=nil] -- void call
  e[15] = e[230][K(0)]  -- GETINDEX? [a=230 b=0 c=15 d=nil]
  call(e[15], e[2080])  -- CALL [a=15 b=14 c=2080 d=nil] -- void call
  e[15] = call(e[15], e[0])  -- GETGLOBAL/CALL [a=15 b=2046 c=0 d=game]
  call(e[15], e[1092])  -- CALL [a=15 b=14 c=1092 d=nil] -- void call
  goto L_922
  e[14][K(600)] = e[312]  -- SETTABLE [a=14 b=600 c=312 d=189] -- settable/void-call (inferred)
  e[14][K(1451)] = e[1003]  -- SETTABLE [a=14 b=1451 c=1003 d=24] -- settable/void-call (inferred)
  e[15] = e[15][K(0)]  -- GETINDEX? [a=15 b=0 c=15 d=nil]
  call(e[15], e[1525])  -- CALL [a=15 b=14 c=1525 d=nil] -- void call
  e[15] = e[24][K(0)]  -- GETINDEX? [a=24 b=0 c=15 d=nil]
  call(e[15], e[683])  -- CALL [a=15 b=14 c=683 d=nil] -- void call
  e[15] = e[96][K(0)]  -- GETINDEX? [a=96 b=0 c=15 d=nil]
  call(e[15], e[695])  -- CALL [a=15 b=14 c=695 d=nil] -- void call
  e[14][K(2305)] = e[1296]  -- SETTABLE [a=14 b=2305 c=1296 d=69] -- settable/void-call (inferred)
  e[15] = e[76][K(0)]  -- GETINDEX? [a=76 b=0 c=15 d=nil]
  ::L_933::
  goto L_953
  e[25] = 150  -- LOADK [a=25 b=893 c=0 d=150]
  ::L_935::
  goto L_644
  e[14][K(2402)] = e[1441]  -- SETTABLE [a=14 b=2402 c=1441 d=132] -- settable/void-call (inferred)
  e[15] = e[95][K(0)]  -- GETINDEX? [a=95 b=0 c=15 d=nil]
  call(e[15], e[2105])  -- CALL [a=15 b=14 c=2105 d=nil] -- void call
  e[15] = e[21][K(0)]  -- GETINDEX? [a=21 b=0 c=15 d=nil]
  call(e[15], e[713])  -- CALL [a=15 b=14 c=713 d=nil] -- void call
  ::L_941::
  goto L_1135
  call(e[15], e[2122])  -- CALL [a=15 b=14 c=2122 d=nil] -- void call
  e[15] = e[191][K(0)]  -- GETINDEX? [a=191 b=0 c=15 d=nil]
  call(e[15], e[207])  -- CALL [a=15 b=14 c=207 d=nil] -- void call
  ::L_945::
  goto L_14
  call(e[15], e[896])  -- CALL [a=15 b=14 c=896 d=nil] -- void call
  e[14][K(1839)] = e[143]  -- SETTABLE [a=14 b=1839 c=143 d=76] -- settable/void-call (inferred)
  e[203] = e[152][K(0)]  -- GETINDEX? [a=152 b=0 c=203 d=nil]
  goto L_949
  e[25] = (e[2186] == e[25])  -- COMPARE [a=2186 b=25 c=25 d=nil]  -- = true
  if e[25] then goto L_644 end  -- back-edge (loop)
  ::L_953::
  goto L_933
  call(e[15], e[1705])  -- CALL [a=15 b=14 c=1705 d=nil] -- void call
  e[15] = e[2][K(0)]  -- GETINDEX? [a=2 b=0 c=15 d=nil]
  e[156][K(14)] = e[96]  -- SETTABLE/CALL [a=156 b=14 c=96 d=nil] -- settable/void-call (inferred)
  e[155][K(117)] = e[489]  -- SETTABLE/CALL [a=155 b=117 c=489 d=nil] -- settable/void-call (inferred)
  call(e[19], e[135])  -- CALL [a=19 b=162 c=135 d=nil] -- void call
  call(e[15], e[157])  -- CALL [a=15 b=171 c=157 d=nil] -- void call
  e[15] = e[73][K(0)]  -- GETINDEX? [a=73 b=0 c=15 d=nil]
  goto L_961
  e[15] = e[281][K(0)]  -- GETINDEX? [a=281 b=0 c=15 d=nil]
  call(e[15], e[2401])  -- CALL [a=15 b=14 c=2401 d=nil] -- void call
  e[14][K(824)] = e[1738]  -- SETTABLE [a=14 b=824 c=1738 d=156] -- settable/void-call (inferred)
  goto L_965
  call(e[15], e[1178])  -- CALL [a=15 b=14 c=1178 d=nil] -- void call
  e[14][K(736)] = e[1694]  -- SETTABLE [a=14 b=736 c=1694 d=31] -- settable/void-call (inferred)
  e[14][K(82)] = e[475]  -- SETTABLE [a=14 b=82 c=475 d=33] -- settable/void-call (inferred)
  e[15] = e[117][K(0)]  -- GETINDEX? [a=117 b=0 c=15 d=nil]
  call(e[15], e[480])  -- CALL [a=15 b=14 c=480 d=nil] -- void call
  goto L_972
  e[15] = e[173][K(0)]  -- GETINDEX? [a=173 b=0 c=15 d=nil]
  call(e[15], e[691])  -- CALL [a=15 b=14 c=691 d=nil] -- void call
  e[15] = e[303][K(0)]  -- GETINDEX? [a=303 b=0 c=15 d=nil]
  call(e[15], e[1663])  -- CALL [a=15 b=14 c=1663 d=nil] -- void call
  goto L_977
  e[15] = e[370][K(0)]  -- GETINDEX? [a=370 b=0 c=15 d=nil]
  call(e[15], e[1810])  -- CALL [a=15 b=14 c=1810 d=nil] -- void call
  e[15] = e[174][K(0)]  -- GETINDEX? [a=174 b=0 c=15 d=nil]
  call(e[15], e[1708])  -- CALL [a=15 b=14 c=1708 d=nil] -- void call
  goto L_982
  call(e[15], e[1655])  -- CALL [a=15 b=14 c=1655 d=nil] -- void call
  e[14][K(1742)] = e[2192]  -- SETTABLE [a=14 b=1742 c=2192 d=95] -- settable/void-call (inferred)
  e[15] = e[112][K(0)]  -- GETINDEX? [a=112 b=0 c=15 d=nil]
  call(e[15], e[1618])  -- CALL [a=15 b=14 c=1618 d=nil] -- void call
  e[14][K(888)] = e[887]  -- SETTABLE [a=14 b=888 c=887 d=175] -- settable/void-call (inferred)
  ::L_988::
  goto L_516
  e[15] = e[147][K(0)]  -- GETINDEX? [a=147 b=0 c=15 d=nil]
  call(e[15], e[1918])  -- CALL [a=15 b=14 c=1918 d=nil] -- void call
  e[15] = e[172][K(0)]  -- GETINDEX? [a=172 b=0 c=15 d=nil]
  call(e[15], e[2138])  -- CALL [a=15 b=14 c=2138 d=nil] -- void call
  e[15] = call(e[15], e[0])  -- GETGLOBAL/CALL [a=15 b=1053 c=0 d=Path2DControlPoint]
  e[15] = e[15][K(15)]  -- GETTABLE [a=15 b=15 c=396 d=nil]
  call(e[15], e[1361])  -- CALL [a=15 b=14 c=1361 d=nil] -- void call
  e[14][K(1114)] = e[2038]  -- SETTABLE [a=14 b=1114 c=2038 d=128] -- settable/void-call (inferred)
  ::L_997::
  goto L_669
  e[15] = e[1][K(0)]  -- GETINDEX? [a=1 b=0 c=15 d=nil]
  call(e[15], e[1748])  -- CALL [a=15 b=14 c=1748 d=nil] -- void call
  e[85][K(1633)] = e[234]  -- SETTABLE [a=85 b=1633 c=234 d=187] -- settable/void-call (inferred)
  e[14][K(684)] = e[1926]  -- SETTABLE [a=14 b=684 c=1926 d=73] -- settable/void-call (inferred)
  e[15] = e[36][K(0)]  -- GETINDEX? [a=36 b=0 c=15 d=nil]
  call(e[15], e[1519])  -- CALL [a=15 b=14 c=1519 d=nil] -- void call
  e[15] = e[9][K(0)]  -- GETINDEX? [a=9 b=0 c=15 d=nil]
  call(e[15], e[2340])  -- CALL [a=15 b=14 c=2340 d=nil] -- void call
  ::L_1006::
  goto L_1336
  call(e[15], e[598])  -- CALL [a=15 b=14 c=598 d=nil] -- void call
  call(e[87], e[148])  -- CALL [a=87 b=234 c=148 d=nil] -- void call
  e[14][K(32)] = e[93]  -- SETTABLE [a=14 b=32 c=93 d=nil] -- settable/void-call (inferred)
  e[250][K(933)] = e[95]  -- SETTABLE/CALL [a=250 b=933 c=95 d=41] -- settable/void-call (inferred)
  e[165][K(236)] = e[853]  -- SETTABLE/CALL [a=165 b=236 c=853 d=nil] -- settable/void-call (inferred)
  e[14][K(909)] = e[2250]  -- SETTABLE [a=14 b=909 c=2250 d=19] -- settable/void-call (inferred)
  e[15] = e[115][K(0)]  -- GETINDEX? [a=115 b=0 c=15 d=nil]
  call(e[15], e[574])  -- CALL [a=15 b=14 c=574 d=nil] -- void call
  e[15] = e[78][K(0)]  -- GETINDEX? [a=78 b=0 c=15 d=nil]
  call(e[15], e[1193])  -- CALL [a=15 b=14 c=1193 d=nil] -- void call
  ::L_1017::
  goto L_997
  call(e[15], e[1966])  -- CALL [a=15 b=14 c=1966 d=nil] -- void call
  e[14][K(725)] = e[866]  -- SETTABLE [a=14 b=725 c=866 d=17] -- settable/void-call (inferred)
  e[14][K(1894)] = e[1529]  -- SETTABLE [a=14 b=1894 c=1529 d=48] -- settable/void-call (inferred)
  goto L_1021
  e[15] = e[25][K(0)]  -- GETINDEX? [a=25 b=0 c=15 d=nil]
  call(e[15], e[1628])  -- CALL [a=15 b=14 c=1628 d=nil] -- void call
  e[14][K(198)] = e[1408]  -- SETTABLE [a=14 b=198 c=1408 d=88] -- settable/void-call (inferred)
  ::L_1025::
  goto L_765
  e[19] = {}  -- NEWTABLE [a=19 b=0 c=0 d=nil]
  e[18] = {}  -- NEWTABLE [a=18 b=0 c=0 d=nil]
  e[25] = K(12)  -- LOADK_S [a=0 b=12 c=25 d=nil]
  e[26] = K(15)  -- LOADK_S [a=0 b=15 c=26 d=nil]
  call(e[13], e[15])  -- CALL [a=13 b=20 c=15 d=nil] -- void call
  e[27][K(497)] = e[155]  -- SETTABLE/CALL [a=27 b=497 c=155 d=�] -- settable/void-call (inferred)
  e[51] = K(179)  -- LOADK_S [a=51 b=179 c=220 d=nil]
  e[26] = 1  -- LOADK_N [a=0 b=0 c=26 d=nil]
  e[26] = arith(e[26], e[1200])  -- UNOP/arith? [a=26 b=26 c=1200 d=nil]  -- = 334
  e[25] = 23  -- LOADK_N [a=0 b=0 c=25 d=nil]
  e[25] = e[25] + 8991  -- ADD [a=25 b=2000 c=25 d=8991]  -- = 9014
  e[25] = arith(e[25], e[772])  -- UNOP/arith? [a=25 b=25 c=772 d=nil]  -- = 15
  call(e[25], e[2159])  -- CALL [a=25 b=18 c=2159 d=nil] -- void call
  e[19][K(2375)] = e[12]  -- SETTABLE [a=19 b=2375 c=12 d=674] -- settable/void-call (inferred)
  call(e[29], e[17])  -- CALL? [a=29 b=0 c=17 d=nil] -- void call
  ::L_1041::
  goto L_138
  e[15] = call(e[15], e[0])  -- GETGLOBAL/CALL [a=15 b=1258 c=0 d=error]
  call(e[15], e[2412])  -- CALL [a=15 b=14 c=2412 d=nil] -- void call
  e[15] = e[89][K(0)]  -- GETINDEX? [a=89 b=0 c=15 d=nil]
  ::L_1045::
  goto L_966
  call(e[15], e[2228])  -- CALL [a=15 b=14 c=2228 d=nil] -- void call
  e[15] = e[164][K(0)]  -- GETINDEX? [a=164 b=0 c=15 d=nil]
  call(e[15], e[2400])  -- CALL [a=15 b=14 c=2400 d=nil] -- void call
  e[15] = e[259][K(0)]  -- GETINDEX? [a=259 b=0 c=15 d=nil]
  call(e[15], e[1198])  -- CALL [a=15 b=14 c=1198 d=nil] -- void call
  e[15] = e[262][K(0)]  -- GETINDEX? [a=262 b=0 c=15 d=nil]
  goto L_1052
  e[14][K(1153)] = e[2156]  -- SETTABLE [a=14 b=1153 c=2156 d=100] -- settable/void-call (inferred)
  e[15] = e[250][K(0)]  -- GETINDEX? [a=250 b=0 c=15 d=nil]
  e[94][K(14)] = e[243]  -- SETTABLE/CALL [a=94 b=14 c=243 d=nil] -- settable/void-call (inferred)
  e[118][K(220)] = e[1450]  -- SETTABLE/CALL [a=118 b=220 c=1450 d=nil] -- settable/void-call (inferred)
  call(e[47], e[167])  -- CALL [a=47 b=182 c=167 d=nil] -- void call
  call(e[15], e[34])  -- CALL [a=15 b=54 c=34 d=nil] -- void call
  e[15] = e[234][K(0)]  -- GETINDEX? [a=234 b=0 c=15 d=nil]
  call(e[15], e[2298])  -- CALL [a=15 b=14 c=2298 d=nil] -- void call
  e[15] = e[239][K(0)]  -- GETINDEX? [a=239 b=0 c=15 d=nil]
  call(e[15], e[2092])  -- CALL [a=15 b=14 c=2092 d=nil] -- void call
  e[15] = e[185][K(0)]  -- GETINDEX? [a=185 b=0 c=15 d=nil]
  ::L_1064::
  goto L_941
  e[15] = e[140][K(0)]  -- GETINDEX? [a=140 b=0 c=15 d=nil]
  call(e[15], e[1840])  -- CALL [a=15 b=14 c=1840 d=nil] -- void call
  e[15] = e[366][K(0)]  -- GETINDEX? [a=366 b=0 c=15 d=nil]
  call(e[15], e[1958])  -- CALL [a=15 b=14 c=1958 d=nil] -- void call
  e[14][K(167)] = e[1213]  -- SETTABLE [a=14 b=167 c=1213 d=39] -- settable/void-call (inferred)
  e[15] = e[161][K(0)]  -- GETINDEX? [a=161 b=0 c=15 d=nil]
  ::L_1071::
  goto L_61
  e[14][K(2409)] = e[870]  -- SETTABLE [a=14 b=2409 c=870 d=159] -- settable/void-call (inferred)
  e[15] = e[77][K(0)]  -- GETINDEX? [a=77 b=0 c=15 d=nil]
  call(e[15], e[1406])  -- CALL [a=15 b=14 c=1406 d=nil] -- void call
  e[15] = e[43][K(0)]  -- GETINDEX? [a=43 b=0 c=15 d=nil]
  call(e[15], e[2011])  -- CALL [a=15 b=14 c=2011 d=nil] -- void call
  e[15] = e[18][K(0)]  -- GETINDEX? [a=18 b=0 c=15 d=nil]
  call(e[15], e[2170])  -- CALL [a=15 b=14 c=2170 d=nil] -- void call
  e[14][K(458)] = e[812]  -- SETTABLE [a=14 b=458 c=812 d=180] -- settable/void-call (inferred)
  e[14][K(735)] = e[539]  -- SETTABLE [a=14 b=735 c=539 d=116] -- settable/void-call (inferred)
  e[15] = e[86][K(0)]  -- GETINDEX? [a=86 b=0 c=15 d=nil]
  call(e[15], e[299])  -- CALL [a=15 b=14 c=299 d=nil] -- void call
  e[14][K(17)] = e[1582]  -- SETTABLE [a=14 b=17 c=1582 d=106] -- settable/void-call (inferred)
  e[15] = call(e[15], e[0])  -- GETGLOBAL/CALL [a=15 b=640 c=0 d=iscclosure]
  ::L_1085::
  goto L_1006
  call(e[15], e[784])  -- CALL [a=15 b=14 c=784 d=nil] -- void call
  e[15] = e[269][K(0)]  -- GETINDEX? [a=269 b=0 c=15 d=nil]
  call(e[15], e[522])  -- CALL [a=15 b=14 c=522 d=nil] -- void call
  e[15] = e[183][K(0)]  -- GETINDEX? [a=183 b=0 c=15 d=nil]
  goto L_1090
  e[15] = e[263][K(0)]  -- GETINDEX? [a=263 b=0 c=15 d=nil]
  call(e[15], e[1543])  -- CALL [a=15 b=14 c=1543 d=nil] -- void call
  e[14][K(1363)] = e[2146]  -- SETTABLE [a=14 b=1363 c=2146 d=72] -- settable/void-call (inferred)
  ::L_1094::
  goto L_195
  e[32] = {}  -- NEWTABLE [a=32 b=0 c=0 d=nil]
  e[34] = {}  -- NEWTABLE [a=34 b=0 c=0 d=nil]
  e[34][K(2090)] = e[1284]  -- SETTABLE [a=34 b=2090 c=1284 d=1227] -- settable/void-call (inferred)
  e[32][K(1228)] = e[2264]  -- SETTABLE [a=32 b=1228 c=2264 d=197] -- settable/void-call (inferred)
  call(e[37], e[30])  -- CALL? [a=37 b=0 c=30 d=nil] -- void call
  goto L_1100
  e[14][K(1485)] = e[842]  -- SETTABLE [a=14 b=1485 c=842 d=78] -- settable/void-call (inferred)
  e[15] = e[48][K(0)]  -- GETINDEX? [a=48 b=0 c=15 d=nil]
  call(e[15], e[1859])  -- CALL [a=15 b=14 c=1859 d=nil] -- void call
  goto L_1104
  e[14][K(285)] = e[1208]  -- SETTABLE [a=14 b=285 c=1208 d=109] -- settable/void-call (inferred)
  e[15] = e[266][K(0)]  -- GETINDEX? [a=266 b=0 c=15 d=nil]
  call(e[15], e[606])  -- CALL [a=15 b=14 c=606 d=nil] -- void call
  ::L_1108::
  goto L_236
  e[15] = e[329][K(0)]  -- GETINDEX? [a=329 b=0 c=15 d=nil]
  call(e[15], e[178])  -- CALL [a=15 b=14 c=178 d=nil] -- void call
  e[15] = e[295][K(0)]  -- GETINDEX? [a=295 b=0 c=15 d=nil]
  ::L_1112::
  goto L_447
  if e[25] then goto L_950 end  -- back-edge (loop)
  ::L_1114::
  goto L_1206
  e[15] = e[208][K(0)]  -- GETINDEX? [a=208 b=0 c=15 d=nil]
  call(e[15], e[1609])  -- CALL [a=15 b=14 c=1609 d=nil] -- void call
  e[15] = call(e[15], e[0])  -- GETGLOBAL/CALL [a=15 b=870 c=0 d=Random]
  call(e[15], e[102])  -- CALL [a=15 b=14 c=102 d=nil] -- void call
  goto L_1119
  e[15] = e[87][K(0)]  -- GETINDEX? [a=87 b=0 c=15 d=nil]
  e[254][K(14)] = e[177]  -- SETTABLE/CALL [a=254 b=14 c=177 d=nil] -- settable/void-call (inferred)
  e[27][K(221)] = e[1541]  -- SETTABLE/CALL [a=27 b=221 c=1541 d=nil] -- settable/void-call (inferred)
  call(e[135], e[61])  -- CALL [a=135 b=164 c=61 d=nil] -- void call
  call(e[15], e[74])  -- CALL [a=15 b=78 c=74 d=nil] -- void call
  e[15] = e[31][K(0)]  -- GETINDEX? [a=31 b=0 c=15 d=nil]
  call(e[15], e[1275])  -- CALL [a=15 b=14 c=1275 d=nil] -- void call
  goto L_1127
  e[14][K(1837)] = e[1876]  -- SETTABLE [a=14 b=1837 c=1876 d=64] -- settable/void-call (inferred)
  e[71] = e[351][K(0)]  -- GETINDEX? [a=351 b=0 c=71 d=nil]
  call(e[15], e[599])  -- CALL [a=15 b=14 c=599 d=nil] -- void call
  e[15] = e[171][K(0)]  -- GETINDEX? [a=171 b=0 c=15 d=nil]
  call(e[15], e[1387])  -- CALL [a=15 b=14 c=1387 d=nil] -- void call
  e[15] = e[188][K(0)]  -- GETINDEX? [a=188 b=0 c=15 d=nil]
  call(e[15], e[170])  -- CALL [a=15 b=14 c=170 d=nil] -- void call
  ::L_1135::
  goto L_846
  e[15] = e[102][K(0)]  -- GETINDEX? [a=102 b=0 c=15 d=nil]
  call(e[15], e[1402])  -- CALL [a=15 b=14 c=1402 d=nil] -- void call
  e[15] = e[71][K(0)]  -- GETINDEX? [a=71 b=0 c=15 d=nil]
  call(e[15], e[1180])  -- CALL [a=15 b=14 c=1180 d=nil] -- void call
  goto L_1140
  e[15] = e[283][K(0)]  -- GETINDEX? [a=283 b=0 c=15 d=nil]
  call(e[15], e[1491])  -- CALL [a=15 b=14 c=1491 d=nil] -- void call
  e[15] = e[133][K(0)]  -- GETINDEX? [a=133 b=0 c=15 d=nil]
  call(e[15], e[1330])  -- CALL [a=15 b=14 c=1330 d=nil] -- void call
  e[14][K(1460)] = e[593]  -- SETTABLE [a=14 b=1460 c=593 d=184] -- settable/void-call (inferred)
  ::L_1146::
  goto L_1321
  call(e[15], e[1128])  -- CALL [a=15 b=14 c=1128 d=nil] -- void call
  e[14][K(1102)] = e[1435]  -- SETTABLE [a=14 b=1102 c=1435 d=37] -- settable/void-call (inferred)
  e[15] = call(e[15], e[0])  -- GETGLOBAL/CALL [a=15 b=1516 c=0 d=CFrame]
  ::L_1150::
  goto L_505
  call(e[15], e[1264])  -- CALL [a=15 b=14 c=1264 d=nil] -- void call
  e[15] = e[74][K(0)]  -- GETINDEX? [a=74 b=0 c=15 d=nil]
  call(e[15], e[1370])  -- CALL [a=15 b=14 c=1370 d=nil] -- void call
  e[15] = e[101][K(0)]  -- GETINDEX? [a=101 b=0 c=15 d=nil]
  goto L_1155
  e[15] = e[64][K(0)]  -- GETINDEX? [a=64 b=0 c=15 d=nil]
  call(e[15], e[2235])  -- CALL [a=15 b=14 c=2235 d=nil] -- void call
  e[14][K(1023)] = e[1076]  -- SETTABLE [a=14 b=1023 c=1076 d=148] -- settable/void-call (inferred)
  goto L_1159
  e[15] = e[228][K(0)]  -- GETINDEX? [a=228 b=0 c=15 d=nil]
  call(e[15], e[1110])  -- CALL [a=15 b=132 c=1110 d=nil] -- void call
  e[14][K(804)] = e[1770]  -- SETTABLE [a=14 b=804 c=1770 d=113] -- settable/void-call (inferred)
  e[14][K(1678)] = e[1445]  -- SETTABLE [a=14 b=1678 c=1445 d=102] -- settable/void-call (inferred)
  e[15] = e[382][K(0)]  -- GETINDEX? [a=382 b=0 c=15 d=nil]
  goto L_1165
  call(e[15], e[1156])  -- CALL [a=15 b=14 c=1156 d=nil] -- void call
  e[15] = e[253][K(0)]  -- GETINDEX? [a=253 b=0 c=15 d=nil]
  call(e[15], e[645])  -- CALL [a=15 b=14 c=645 d=nil] -- void call
  e[15] = e[203][K(0)]  -- GETINDEX? [a=203 b=0 c=15 d=nil]
  call(e[15], e[962])  -- CALL [a=15 b=14 c=962 d=nil] -- void call
  e[15] = e[135][K(0)]  -- GETINDEX? [a=135 b=0 c=15 d=nil]
  ::L_1172::
  goto L_912
  e[15] = e[358][K(0)]  -- GETINDEX? [a=358 b=0 c=15 d=nil]
  call(e[15], e[2028])  -- CALL [a=15 b=14 c=2028 d=nil] -- void call
  e[15] = e[362][K(0)]  -- GETINDEX? [a=362 b=0 c=15 d=nil]
  ::L_1176::
  goto L_230
  call(e[15], e[2407])  -- CALL [a=15 b=14 c=2407 d=nil] -- void call
  e[15] = e[16][K(0)]  -- GETINDEX? [a=16 b=0 c=15 d=nil]
  call(e[15], e[936])  -- CALL [a=15 b=14 c=936 d=nil] -- void call
  e[15] = e[52][K(0)]  -- GETINDEX? [a=52 b=0 c=15 d=nil]
  ::L_1181::
  goto L_55
  e[0][K(0)] = e[0]  -- SETTABLE/CALL [a=0 b=0 c=0 d=nil] -- settable/void-call (inferred)
  e[0] = e[0][K(2)]  -- GETTABLE/CLOSURE [a=0 b=2 c=13 d=nil]
  e[14] = {}  -- NEWTABLE [a=0 b=0 c=14 d=nil]
  e[14][K(796)] = e[920]  -- SETTABLE [a=14 b=796 c=920 d=104] -- settable/void-call (inferred)
  e[15] = e[108][K(0)]  -- GETINDEX? [a=108 b=0 c=15 d=nil]
  call(e[15], e[2245])  -- CALL [a=15 b=14 c=2245 d=nil] -- void call
  ::L_1188::
  goto L_1348
  if e[25] then goto L_1295 else goto L_1190 end
  e[31] = {}  -- NEWTABLE [a=31 b=0 c=0 d=nil]
  e[32] = {}  -- NEWTABLE [a=32 b=0 c=0 d=nil]
  e[31][K(165)] = e[4]  -- SETTABLE [a=31 b=165 c=4 d=545] -- settable/void-call (inferred)
  e[32][K(1170)] = e[401]  -- SETTABLE [a=32 b=1170 c=401 d=1374] -- settable/void-call (inferred)
  call(e[37], e[30])  -- CALL? [a=37 b=0 c=30 d=nil] -- void call
  goto L_1196
  e[15] = e[300][K(0)]  -- GETINDEX? [a=300 b=0 c=15 d=nil]
  call(e[15], e[1656])  -- CALL [a=15 b=14 c=1656 d=nil] -- void call
  e[15] = e[348][K(0)]  -- GETINDEX? [a=348 b=0 c=15 d=nil]
  goto L_1200
  call(e[15], e[336])  -- CALL [a=15 b=14 c=336 d=nil] -- void call
  e[14][K(2367)] = e[1157]  -- SETTABLE [a=14 b=2367 c=1157 d=21] -- settable/void-call (inferred)
  e[14][K(181)] = e[1341]  -- SETTABLE [a=14 b=181 c=1341 d=154] -- settable/void-call (inferred)
  e[14][K(440)] = e[316]  -- SETTABLE [a=14 b=440 c=316 d=147] -- settable/void-call (inferred)
  ::L_1205::
  goto L_1373
  ::L_1206::
  goto L_112
  e[25] = 306  -- LOADK [a=25 b=2082 c=0 d=306]
  goto L_1208
  call(e[15], e[2182])  -- CALL [a=15 b=14 c=2182 d=nil] -- void call
  e[15] = e[13][K(0)]  -- GETINDEX? [a=13 b=0 c=15 d=nil]
  call(e[15], e[400])  -- CALL [a=15 b=14 c=400 d=nil] -- void call
  ::L_1212::
  goto L_1358
  call(e[15], e[1950])  -- CALL [a=15 b=14 c=1950 d=nil] -- void call
  e[15] = e[202][K(0)]  -- GETINDEX? [a=202 b=0 c=15 d=nil]
  call(e[15], e[1109])  -- CALL [a=15 b=14 c=1109 d=nil] -- void call
  e[15] = e[150][K(0)]  -- GETINDEX? [a=150 b=0 c=15 d=nil]
  call(e[15], e[1910])  -- CALL [a=15 b=14 c=1910 d=nil] -- void call
  ::L_1218::
  goto L_733
  e[15] = e[289][K(0)]  -- GETINDEX? [a=289 b=0 c=15 d=nil]
  call(e[15], e[1215])  -- CALL [a=15 b=14 c=1215 d=nil] -- void call
  e[14][K(687)] = e[636]  -- SETTABLE [a=14 b=687 c=636 d=143] -- settable/void-call (inferred)
  e[14][K(869)] = e[1489]  -- SETTABLE [a=14 b=869 c=1489 d=174] -- settable/void-call (inferred)
  e[15] = e[129][K(0)]  -- GETINDEX? [a=129 b=0 c=15 d=nil]
  call(e[15], e[922])  -- CALL [a=15 b=14 c=922 d=nil] -- void call
  e[15] = e[168][K(0)]  -- GETINDEX? [a=168 b=0 c=15 d=nil]
  goto L_1226
  e[279][K(0)] = e[15]  -- SETTABLE [a=279 b=0 c=15 d=nil] -- settable/void-call (inferred)
  e[215][K(14)] = e[18]  -- SETTABLE/CALL [a=215 b=14 c=18 d=nil] -- settable/void-call (inferred)
  e[83][K(95)] = e[450]  -- SETTABLE/CALL [a=83 b=95 c=450 d=nil] -- settable/void-call (inferred)
  call(e[10], e[7])  -- CALL [a=10 b=18 c=7 d=nil] -- void call
  call(e[15], e[98])  -- CALL [a=15 b=97 c=98 d=nil] -- void call
  e[15] = e[324][K(0)]  -- GETINDEX? [a=324 b=0 c=15 d=nil]
  call(e[15], e[1463])  -- CALL [a=15 b=14 c=1463 d=nil] -- void call
  e[15] = e[198][K(0)]  -- GETINDEX? [a=198 b=0 c=15 d=nil]
  call(e[15], e[787])  -- CALL [a=15 b=14 c=787 d=nil] -- void call
  e[14][K(2289)] = e[1815]  -- SETTABLE [a=14 b=2289 c=1815 d=27] -- settable/void-call (inferred)
  e[15] = call(e[15], e[0])  -- GETGLOBAL/CALL [a=15 b=2035 c=0 d=utf8]
  e[15] = e[15][K(15)]  -- GETTABLE [a=15 b=15 c=1409 d=nil]
  call(e[15], e[1246])  -- CALL [a=15 b=14 c=1246 d=nil] -- void call
  e[14][K(2418)] = e[211]  -- SETTABLE [a=14 b=2418 c=211 d=185] -- settable/void-call (inferred)
  e[15] = e[317][K(0)]  -- GETINDEX? [a=317 b=0 c=15 d=nil]
  call(e[15], e[1789])  -- CALL [a=15 b=14 c=1789 d=nil] -- void call
  ::L_1243::
  goto L_827
  e[15] = e[229][K(0)]  -- GETINDEX? [a=229 b=0 c=15 d=nil]
  call(e[15], e[1900])  -- CALL [a=15 b=14 c=1900 d=nil] -- void call
  e[15] = e[345][K(0)]  -- GETINDEX? [a=345 b=0 c=15 d=nil]
  call(e[15], e[1239])  -- CALL [a=15 b=14 c=1239 d=nil] -- void call
  goto L_1248
  e[32] = {}  -- NEWTABLE [a=32 b=0 c=0 d=nil]
  e[32][K(903)] = e[4]  -- SETTABLE [a=32 b=903 c=4 d=375] -- settable/void-call (inferred)
  e[32][K(223)] = e[115]  -- SETTABLE [a=32 b=223 c=115 d=524] -- settable/void-call (inferred)
  call(e[37], e[30])  -- CALL? [a=37 b=0 c=30 d=nil] -- void call
  goto L_1254
  e[15] = e[103][K(0)]  -- GETINDEX? [a=103 b=0 c=15 d=nil]
  call(e[15], e[1889])  -- CALL [a=15 b=14 c=1889 d=nil] -- void call
  e[15] = e[79][K(0)]  -- GETINDEX? [a=79 b=0 c=15 d=nil]
  ::L_1258::
  goto L_1017
  e[15] = e[291][K(0)]  -- GETINDEX? [a=291 b=0 c=15 d=nil]
  call(e[15], e[992])  -- CALL [a=15 b=14 c=992 d=nil] -- void call
  e[14][K(2200)] = e[799]  -- SETTABLE [a=14 b=2200 c=799 d=111] -- settable/void-call (inferred)
  goto L_1262
  e[15] = e[302][K(0)]  -- GETINDEX? [a=302 b=0 c=15 d=nil]
  e[35][K(14)] = e[88]  -- SETTABLE/CALL [a=35 b=14 c=88 d=nil] -- settable/void-call (inferred)
  e[235][K(65)] = e[1648]  -- SETTABLE/CALL [a=235 b=65 c=1648 d=nil] -- settable/void-call (inferred)
  call(e[198], e[26])  -- CALL [a=198 b=99 c=26 d=nil] -- void call
  call(e[15], e[197])  -- CALL [a=15 b=251 c=197 d=nil] -- void call
  e[15] = e[309][K(0)]  -- GETINDEX? [a=309 b=0 c=15 d=nil]
  ::L_1269::
  goto L_1146
  e[15] = call(e[15], e[0])  -- GETGLOBAL/CALL [a=15 b=1205 c=0 d=tostring]
  call(e[15], e[535])  -- CALL [a=15 b=14 c=535 d=nil] -- void call
  e[15] = call(e[15], e[0])  -- GETGLOBAL/CALL [a=15 b=1937 c=0 d=assert]
  call(e[15], e[1951])  -- CALL [a=15 b=14 c=1951 d=nil] -- void call
  e[15] = e[310][K(0)]  -- GETINDEX? [a=310 b=0 c=15 d=nil]
  call(e[15], e[1548])  -- CALL [a=15 b=14 c=1548 d=nil] -- void call
  e[15] = e[210][K(0)]  -- GETINDEX? [a=210 b=0 c=15 d=nil]
  call(e[15], e[1575])  -- CALL [a=15 b=14 c=1575 d=nil] -- void call
  goto L_1278
  e[14][K(352)] = e[1138]  -- SETTABLE [a=14 b=352 c=1138 d=182] -- settable/void-call (inferred)
  e[15] = e[127][K(0)]  -- GETINDEX? [a=127 b=0 c=15 d=nil]
  call(e[15], e[531])  -- CALL [a=15 b=14 c=531 d=nil] -- void call
  goto L_1282
  e[15] = e[334][K(0)]  -- GETINDEX? [a=334 b=0 c=15 d=nil]
  call(e[15], e[1804])  -- CALL [a=15 b=14 c=1804 d=nil] -- void call
  e[14][K(776)] = e[2366]  -- SETTABLE [a=14 b=776 c=2366 d=146] -- settable/void-call (inferred)
  e[15] = e[245][K(0)]  -- GETINDEX? [a=245 b=0 c=15 d=nil]
  call(e[15], e[1754])  -- CALL [a=15 b=14 c=1754 d=nil] -- void call
  e[15] = e[134][K(0)]  -- GETINDEX? [a=134 b=0 c=15 d=nil]
  call(e[15], e[1137])  -- CALL [a=15 b=14 c=1137 d=nil] -- void call
  e[15] = e[193][K(0)]  -- GETINDEX? [a=193 b=0 c=15 d=nil]
  call(e[15], e[389])  -- CALL [a=15 b=14 c=389 d=nil] -- void call
  e[15] = call(e[15], e[0])  -- GETGLOBAL/CALL [a=15 b=1539 c=0 d=bit32]
  goto L_1293
  e[25] = K(361)  -- LOADK [a=25 b=361 c=0 d=170]
  ::L_1295::
  goto L_1112
  e[25] = e[25] + 26443  -- ADD [a=25 b=1369 c=25 d=26443]  -- = 26445
  e[25] = arith(e[25], e[1133])  -- UNOP/arith? [a=25 b=25 c=1133 d=nil]  -- = 286
  call(e[25], e[2344])  -- CALL [a=25 b=21 c=2344 d=nil] -- void call
  e[19][K(399)] = e[350]  -- SETTABLE [a=19 b=399 c=350 d=1249] -- settable/void-call (inferred)
  call(e[29], e[17])  -- CALL? [a=29 b=0 c=17 d=nil] -- void call
  goto L_1301
  call(e[15], e[791])  -- CALL [a=15 b=14 c=791 d=nil] -- void call
  e[15] = e[90][K(0)]  -- GETINDEX? [a=90 b=0 c=15 d=nil]
  call(e[15], e[138])  -- CALL [a=15 b=14 c=138 d=nil] -- void call
  goto L_1305
  e[15] = call(e[15], e[0])  -- GETGLOBAL/CALL [a=15 b=732 c=0 d=UDim]
  call(e[15], e[503])  -- CALL [a=15 b=14 c=503 d=nil] -- void call
  e[15] = e[246][K(0)]  -- GETINDEX? [a=246 b=0 c=15 d=nil]
  ::L_1309::
  goto L_634
  e[15] = e[218][K(0)]  -- GETINDEX? [a=218 b=0 c=15 d=nil]
  call(e[15], e[268])  -- CALL [a=15 b=14 c=268 d=nil] -- void call
  e[15] = e[277][K(0)]  -- GETINDEX? [a=277 b=0 c=15 d=nil]
  ::L_1313::
  goto L_1
  call(e[15], e[309])  -- CALL [a=15 b=14 c=309 d=nil] -- void call
  e[15] = e[204][K(0)]  -- GETINDEX? [a=204 b=0 c=15 d=nil]
  call(e[15], e[591])  -- CALL [a=15 b=14 c=591 d=nil] -- void call
  goto L_1317
  e[15] = e[199][K(0)]  -- GETINDEX? [a=199 b=0 c=15 d=nil]
  call(e[15], e[1011])  -- CALL [a=15 b=14 c=1011 d=nil] -- void call
  e[15] = e[162][K(0)]  -- GETINDEX? [a=162 b=0 c=15 d=nil]
  ::L_1321::
  goto L_681
  e[14][K(269)] = e[2187]  -- SETTABLE [a=14 b=269 c=2187 d=163] -- settable/void-call (inferred)
  e[14][K(1765)] = e[1647]  -- SETTABLE [a=14 b=1765 c=1647 d=115] -- settable/void-call (inferred)
  e[14][K(961)] = e[1567]  -- SETTABLE [a=14 b=961 c=1567 d=65] -- settable/void-call (inferred)
  ::L_1325::
  goto L_784
  call(e[15], e[829])  -- CALL [a=15 b=14 c=829 d=nil] -- void call
  e[14][K(554)] = e[2069]  -- SETTABLE [a=14 b=554 c=2069 d=131] -- settable/void-call (inferred)
  e[15] = e[297][K(0)]  -- GETINDEX? [a=297 b=0 c=15 d=nil]
  call(e[15], e[260])  -- CALL [a=15 b=14 c=260 d=nil] -- void call
  e[14][K(2123)] = e[1821]  -- SETTABLE [a=14 b=2123 c=1821 d=18] -- settable/void-call (inferred)
  e[15] = e[378][K(0)]  -- GETINDEX? [a=378 b=0 c=15 d=nil]
  call(e[15], e[2223])  -- CALL [a=15 b=14 c=2223 d=nil] -- void call
  e[15] = e[201][K(0)]  -- GETINDEX? [a=201 b=0 c=15 d=nil]
  call(e[15], e[2094])  -- CALL [a=15 b=14 c=2094 d=nil] -- void call
  e[14][K(696)] = e[396]  -- SETTABLE [a=14 b=696 c=396 d=55] -- settable/void-call (inferred)
  ::L_1336::
  goto L_312
  e[15] = e[85][K(0)]  -- GETINDEX? [a=85 b=0 c=15 d=nil]
  call(e[15], e[664])  -- CALL [a=15 b=14 c=664 d=nil] -- void call
  e[15] = e[109][K(0)]  -- GETINDEX? [a=109 b=0 c=15 d=nil]
  goto L_1340
  e[15] = e[240][K(0)]  -- GETINDEX? [a=240 b=0 c=15 d=nil]
  call(e[15], e[620])  -- CALL [a=15 b=14 c=620 d=nil] -- void call
  e[15] = call(e[15], e[0])  -- GETGLOBAL/CALL [a=15 b=945 c=0 d=islclosure]
  call(e[15], e[1698])  -- CALL [a=15 b=14 c=1698 d=nil] -- void call
  e[15] = e[170][K(0)]  -- GETINDEX? [a=170 b=0 c=15 d=nil]
  call(e[15], e[1838])  -- CALL [a=15 b=14 c=1838 d=nil] -- void call
  e[15] = e[304][K(0)]  -- GETINDEX? [a=304 b=0 c=15 d=nil]
  ::L_1348::
  goto L_164
  call(e[15], e[379])  -- CALL [a=15 b=14 c=379 d=nil] -- void call
  e[15] = call(e[15], e[0])  -- GETGLOBAL/CALL [a=15 b=492 c=0 d=select]
  call(e[15], e[65])  -- CALL [a=15 b=14 c=65 d=nil] -- void call
  e[15] = e[265][K(0)]  -- GETINDEX? [a=265 b=0 c=15 d=nil]
  call(e[15], e[1393])  -- CALL [a=15 b=14 c=1393 d=nil] -- void call
  e[14][K(1518)] = e[2319]  -- SETTABLE [a=14 b=1518 c=2319 d=177] -- settable/void-call (inferred)
  e[14][K(893)] = e[1389]  -- SETTABLE [a=14 b=893 c=1389 d=150] -- settable/void-call (inferred)
  e[15] = e[156][K(0)]  -- GETINDEX? [a=156 b=0 c=15 d=nil]
  ::L_1358::
  goto L_1313
  e[14][K(2164)] = e[1535]  -- SETTABLE [a=14 b=2164 c=1535 d=139] -- settable/void-call (inferred)
  e[15] = e[20][K(0)]  -- GETINDEX? [a=20 b=0 c=15 d=nil]
  call(e[15], e[1113])  -- CALL [a=15 b=14 c=1113 d=nil] -- void call
  e[15] = e[40][K(0)]  -- GETINDEX? [a=40 b=0 c=15 d=nil]
  call(e[15], e[162])  -- CALL [a=15 b=14 c=162 d=nil] -- void call
  goto L_1364
  e[14][K(222)] = e[871]  -- SETTABLE [a=14 b=222 c=871 d=171] -- settable/void-call (inferred)
  e[15] = e[10][K(0)]  -- GETINDEX? [a=10 b=0 c=15 d=nil]
  call(e[15], e[294])  -- CALL [a=15 b=14 c=294 d=nil] -- void call
  ::L_1369::
  goto L_748
  e[14][K(2021)] = e[2034]  -- SETTABLE [a=14 b=2021 c=2034 d=126] -- settable/void-call (inferred)
  e[15] = e[177][K(0)]  -- GETINDEX? [a=177 b=0 c=15 d=nil]
  call(e[15], e[1490])  -- CALL [a=15 b=14 c=1490 d=nil] -- void call
  ::L_1373::
  goto L_250
  e[14][K(1386)] = e[2140]  -- SETTABLE [a=14 b=1386 c=2140 d=144] -- settable/void-call (inferred)
  e[15] = e[213][K(0)]  -- GETINDEX? [a=213 b=0 c=15 d=nil]
  call(e[15], e[1355])  -- CALL [a=15 b=14 c=1355 d=nil] -- void call
  e[14][K(926)] = e[1205]  -- SETTABLE [a=14 b=926 c=1205 d=79] -- settable/void-call (inferred)
  ::L_1379::
  goto L_9
  e[34] = {}  -- NEWTABLE [a=34 b=0 c=0 d=nil]
  e[32] = {}  -- NEWTABLE [a=32 b=0 c=0 d=nil]
  e[33] = {}  -- NEWTABLE [a=0 b=33 c=0 d=nil]
  e[34][K(997)] = e[53]  -- SETTABLE [a=34 b=997 c=53 d=231] -- settable/void-call (inferred)
  e[33][K(997)] = e[22]  -- SETTABLE [a=33 b=997 c=22 d=231] -- settable/void-call (inferred)
  e[32][K(543)] = e[10]  -- SETTABLE [a=32 b=543 c=10 d=535] -- settable/void-call (inferred)
  call(e[37], e[30])  -- CALL? [a=37 b=0 c=30 d=nil] -- void call
  goto L_1387
  call(e[15], e[289])  -- CALL [a=15 b=14 c=289 d=nil] -- void call
  e[15] = e[200][K(0)]  -- GETINDEX? [a=200 b=0 c=15 d=nil]
  call(e[15], e[786])  -- CALL [a=15 b=14 c=786 d=nil] -- void call
  ::L_1391::
  goto L_1369
  e[15] = e[375][K(0)]  -- GETINDEX? [a=375 b=0 c=15 d=nil]
  call(e[15], e[313])  -- CALL [a=15 b=14 c=313 d=nil] -- void call
  e[15] = e[294][K(0)]  -- GETINDEX? [a=294 b=0 c=15 d=nil]
  call(e[15], e[1590])  -- CALL [a=15 b=14 c=1590 d=nil] -- void call
  e[14][K(1503)] = e[1453]  -- SETTABLE [a=14 b=1503 c=1453 d=70] -- settable/void-call (inferred)
  ::L_1397::
  goto L_897
  call(e[15], e[521])  -- CALL [a=15 b=14 c=521 d=nil] -- void call
  e[14][K(1010)] = e[1636]  -- SETTABLE [a=14 b=1010 c=1636 d=134] -- settable/void-call (inferred)
  e[15] = e[17][K(0)]  -- GETINDEX? [a=17 b=0 c=15 d=nil]
  call(e[15], e[1710])  -- CALL [a=15 b=14 c=1710 d=nil] -- void call
  goto L_91
end

local function proto2(...)  -- 730 instrs, 281 blocks (structured)
  local e = regs
  ::L_1::
  ::L_684::
  ::L_15::
  ::L_83::
  ::L_455::
  ::L_206::
  ::L_428::
  ::L_189::
  ::L_537::
  ::L_443::
  ::L_477::
  ::L_371::
  ::L_629::
  goto L_1
  e[91] = {}  -- NEWTABLE [a=91 b=0 c=0 d=nil]
  e[91][K(1250)] = e[4]  -- SETTABLE [a=91 b=1250 c=4 d=212] -- settable/void-call (inferred)
  e[91][K(679)] = e[97]  -- SETTABLE [a=91 b=679 c=97 d=424] -- settable/void-call (inferred)
  ::L_5::
  call(e[96], e[89])  -- CALL? [a=96 b=0 c=89 d=nil] -- void call
  ::L_6::
  goto L_79
  ::L_7::
  e[17] = e[8][109]  -- GETTABLE/CLOSURE? [a=8 b=0 c=17 d=nil]  -- = 109
  ::L_8::
  e[18] = e[11][K(0)]  -- GETTABLE/CLOSURE? [a=11 b=0 c=18 d=nil]
  ::L_9::
  e[19] = e[2][K(0)]  -- GETTABLE/CLOSURE? [a=2 b=0 c=19 d=nil]
  ::L_10::
  if e[12] then goto L_8 end  -- back-edge (loop)
  ::L_11::
  goto L_163
  ::L_12::
  e[1] = e[5]  -- MOVE [a=5 b=1 c=341 d=nil]
  ::L_13::
  e[7] = e[4][K(0)]  -- GETTABLE/CLOSURE? [a=4 b=0 c=7 d=nil]
  ::L_14::
  e[8] = e[2][K(0)]  -- GETTABLE/CLOSURE? [a=2 b=0 c=8 d=nil]
  goto L_15
  e[58] = e[2][K(0)]  -- GETTABLE/CLOSURE? [a=2 b=0 c=58 d=nil]
  e[59] = e[24][K(0)]  -- GETTABLE/CLOSURE? [a=24 b=0 c=59 d=nil]
  e[60] = e[14][K(0)]  -- GETTABLE/CLOSURE? [a=14 b=0 c=60 d=nil]
  e[61] = e[31][K(0)]  -- GETTABLE/CLOSURE? [a=31 b=0 c=61 d=nil]
  ::L_20::
  goto L_393
  e[91] = {}  -- NEWTABLE [a=91 b=0 c=0 d=nil]
  e[93] = {}  -- NEWTABLE [a=93 b=0 c=0 d=nil]
  e[90] = {}  -- NEWTABLE [a=90 b=0 c=0 d=nil]
  e[90][K(929)] = e[116]  -- SETTABLE [a=90 b=929 c=116 d=173] -- settable/void-call (inferred)
  e[93][K(929)] = e[112]  -- SETTABLE [a=93 b=929 c=112 d=173] -- settable/void-call (inferred)
  e[91][K(587)] = e[370]  -- SETTABLE [a=91 b=587 c=370 d=143] -- settable/void-call (inferred)
  call(e[96], e[89])  -- CALL? [a=96 b=0 c=89 d=nil] -- void call
  ::L_28::
  goto L_172
  e[62] = e[54][K(0)]  -- GETTABLE/CLOSURE? [a=54 b=0 c=62 d=nil]
  e[63] = e[31][K(0)]  -- GETTABLE/CLOSURE? [a=31 b=0 c=63 d=nil]
  e[64] = e[90][K(0)]  -- GETTABLE/CLOSURE? [a=90 b=0 c=64 d=nil]
  ::L_32::
  goto L_462
  e[55] = e[22][K(0)]  -- GETTABLE/CLOSURE? [a=22 b=0 c=55 d=nil]
  e[56] = e[2][K(0)]  -- GETTABLE/CLOSURE? [a=2 b=0 c=56 d=nil]
  e[57] = e[23][K(0)]  -- GETTABLE/CLOSURE? [a=23 b=0 c=57 d=nil]
  ::L_36::
  goto L_504
  e[60] = e[22][K(0)]  -- GETTABLE/CLOSURE? [a=22 b=0 c=60 d=nil]
  e[61] = e[19][K(0)]  -- GETTABLE/CLOSURE? [a=19 b=0 c=61 d=nil]
  e[62] = e[21][K(0)]  -- GETTABLE/CLOSURE? [a=21 b=0 c=62 d=nil]
  e[63] = e[2][K(0)]  -- GETTABLE/CLOSURE? [a=2 b=0 c=63 d=nil]
  e[64] = e[27][K(0)]  -- GETTABLE/CLOSURE? [a=27 b=0 c=64 d=nil]
  e[65] = e[8][K(0)]  -- GETTABLE/CLOSURE? [a=8 b=0 c=65 d=nil]
  e[66] = e[52][K(0)]  -- GETTABLE/CLOSURE? [a=52 b=0 c=66 d=nil]
  ::L_44::
  goto L_708
  e[53] = e[2][K(0)]  -- GETTABLE/CLOSURE? [a=2 b=0 c=53 d=nil]
  if e[47] then goto L_7 end  -- back-edge (loop)
  e[45] = e[47][K(0)]  -- GETTABLE/CLOSURE? [a=47 b=0 c=45 d=nil]
  e[46] = e[48][K(0)]  -- GETTABLE/CLOSURE? [a=48 b=0 c=46 d=nil]
  e[44] = e[49][K(0)]  -- GETTABLE/CLOSURE? [a=49 b=0 c=44 d=nil]
  e[8] = e[50][27]  -- GETTABLE/CLOSURE? [a=50 b=0 c=8 d=nil]  -- = 27
  ::L_51::
  goto L_668
  e[23] = e[32][K(0)]  -- GETTABLE/CLOSURE? [a=32 b=0 c=23 d=nil]
  e[21] = e[33][K(0)]  -- GETTABLE/CLOSURE? [a=33 b=0 c=21 d=nil]
  call(e[27], e[26])  -- CALL? [a=27 b=0 c=26 d=nil] -- void call
  e[1] = e[28]  -- MOVE [a=28 b=1 c=379 d=nil]
  -- UNKNOWN op? [a=26 b=0 c=30 d=nil]
  e[31] = e[27][K(0)]  -- GETTABLE/CLOSURE? [a=27 b=0 c=31 d=nil]
  ::L_58::
  goto L_100
  e[25] = e[8][96]  -- GETTABLE/CLOSURE? [a=8 b=0 c=25 d=nil]  -- = 96
  e[26] = e[165][K(0)]  -- GETTABLE/CLOSURE? [a=165 b=0 c=26 d=nil]
  e[205][K(197)] = e[27]  -- SETTABLE/CALL [a=205 b=197 c=27 d=nil] -- settable/void-call (inferred)
  call(e[20], e[167])  -- CALL [a=20 b=212 c=167 d=nil] -- void call
  e[44] = K(174)  -- LOADK_S [a=44 b=174 c=149 d=nil]
  ::L_64::
  goto L_121
  e[162] = e[8][62]  -- GETTABLE/CLOSURE? [a=8 b=0 c=162 d=nil]  -- = 62
  e[39] = e[28][K(0)]  -- GETTABLE/CLOSURE? [a=28 b=0 c=39 d=nil]
  e[40] = e[30][K(0)]  -- GETTABLE/CLOSURE? [a=30 b=0 c=40 d=nil]
  ::L_68::
  goto L_301
  e[59] = e[33][K(0)]  -- GETTABLE/CLOSURE? [a=33 b=0 c=59 d=nil]
  e[60] = e[2][K(0)]  -- GETTABLE/CLOSURE? [a=2 b=0 c=60 d=nil]
  e[61] = e[5][K(0)]  -- GETTABLE/CLOSURE? [a=5 b=0 c=61 d=nil]
  ::L_72::
  goto L_549
  e[69] = e[12][K(0)]  -- GETTABLE/CLOSURE? [a=12 b=0 c=69 d=nil]
  if e[61] then goto L_9 end  -- back-edge (loop)
  e[8] = e[61][K(0)]  -- GETTABLE/CLOSURE? [a=61 b=0 c=8 d=nil]
  e[60] = e[62][K(0)]  -- GETTABLE/CLOSURE? [a=62 b=0 c=60 d=nil]
  e[1] = e[61]  -- MOVE [a=61 b=1 c=645 d=nil]
  e[63] = e[2][K(0)]  -- GETTABLE/CLOSURE? [a=2 b=0 c=63 d=nil]
  ::L_79::
  goto L_705
  e[57] = e[47][K(0)]  -- GETTABLE/CLOSURE? [a=47 b=0 c=57 d=nil]
  e[58] = e[48][K(0)]  -- GETTABLE/CLOSURE? [a=48 b=0 c=58 d=nil]
  e[59] = e[8][120]  -- GETTABLE/CLOSURE? [a=8 b=0 c=59 d=nil]  -- = 120
  goto L_83
  e[9] = e[3][K(0)]  -- GETTABLE/CLOSURE? [a=3 b=0 c=9 d=nil]
  if e[5] then goto L_5 end  -- back-edge (loop)
  e[4] = e[5][K(0)]  -- GETTABLE/CLOSURE? [a=5 b=0 c=4 d=nil]
  e[3] = e[6][K(0)]  -- GETTABLE/CLOSURE? [a=6 b=0 c=3 d=nil]
  call(e[8], e[5])  -- CALL? [a=8 b=0 c=5 d=nil] -- void call
  ::L_89::
  goto L_401
  e[1] = e[40]  -- MOVE [a=40 b=1 c=596 d=nil]
  e[42] = e[39][K(0)]  -- GETTABLE/CLOSURE? [a=39 b=0 c=42 d=nil]
  e[43] = e[38][K(0)]  -- GETTABLE/CLOSURE? [a=38 b=0 c=43 d=nil]
  e[44] = e[2][K(0)]  -- GETTABLE/CLOSURE? [a=2 b=0 c=44 d=nil]
  e[45] = e[8][81]  -- GETTABLE/CLOSURE? [a=8 b=0 c=45 d=nil]  -- = 81
  ::L_95::
  goto L_410
  ::L_96::
  goto L_411
  e[42] = e[45][K(0)]  -- GETTABLE/CLOSURE? [a=45 b=0 c=42 d=nil]
  e[43] = e[46][K(0)]  -- GETTABLE/CLOSURE? [a=46 b=0 c=43 d=nil]
  e[8] = e[47][93]  -- GETTABLE/CLOSURE? [a=47 b=0 c=8 d=nil]  -- = 93
  ::L_100::
  goto L_125
  e[32] = e[2][K(0)]  -- GETTABLE/CLOSURE? [a=2 b=0 c=32 d=nil]
  e[33] = e[8][58]  -- GETTABLE/CLOSURE? [a=8 b=0 c=33 d=nil]  -- = 58
  if e[28] then goto L_6 end  -- back-edge (loop)
  e[8] = e[28][62]  -- GETTABLE/CLOSURE? [a=28 b=0 c=8 d=nil]  -- = 62
  e[27] = e[29][K(0)]  -- GETTABLE/CLOSURE? [a=29 b=0 c=27 d=nil]
  e[26] = e[30][K(0)]  -- GETTABLE/CLOSURE? [a=30 b=0 c=26 d=nil]
  call(e[31], e[28])  -- CALL? [a=31 b=0 c=28 d=nil] -- void call
  e[1] = e[32]  -- MOVE [a=32 b=1 c=1428 d=nil]
  e[34] = e[26][K(0)]  -- GETTABLE/CLOSURE? [a=26 b=0 c=34 d=nil]
  e[35] = e[31][K(0)]  -- GETTABLE/CLOSURE? [a=31 b=0 c=35 d=nil]
  e[36] = e[9][K(0)]  -- GETTABLE/CLOSURE? [a=9 b=0 c=36 d=nil]
  e[37] = e[2][K(0)]  -- GETTABLE/CLOSURE? [a=2 b=0 c=37 d=nil]
  ::L_113::
  goto L_216
  e[64] = e[53][K(0)]  -- GETTABLE/CLOSURE? [a=53 b=0 c=64 d=nil]
  e[65] = e[40][K(0)]  -- GETTABLE/CLOSURE? [a=40 b=0 c=65 d=nil]
  e[66] = e[2][K(0)]  -- GETTABLE/CLOSURE? [a=2 b=0 c=66 d=nil]
  e[67] = e[39][K(0)]  -- GETTABLE/CLOSURE? [a=39 b=0 c=67 d=nil]
  e[68] = e[55][K(0)]  -- GETTABLE/CLOSURE? [a=55 b=0 c=68 d=nil]
  e[69] = e[43][K(0)]  -- GETTABLE/CLOSURE? [a=43 b=0 c=69 d=nil]
  e[70] = e[16][K(0)]  -- GETTABLE/CLOSURE? [a=16 b=0 c=70 d=nil]
  ::L_121::
  goto L_587
  e[28] = e[18][K(0)]  -- GETTABLE/CLOSURE? [a=18 b=0 c=28 d=nil]
  e[29] = e[21][K(0)]  -- GETTABLE/CLOSURE? [a=21 b=0 c=29 d=nil]
  e[30] = e[17][K(0)]  -- GETTABLE/CLOSURE? [a=17 b=0 c=30 d=nil]
  ::L_125::
  goto L_133
  e[40] = e[48][K(0)]  -- GETTABLE/CLOSURE? [a=48 b=0 c=40 d=nil]
  e[45][K(173)] = e[44]  -- SETTABLE/CALL [a=45 b=173 c=44 d=nil] -- settable/void-call (inferred)
  e[1] = e[46]  -- MOVE [a=46 b=1 c=573 d=nil]
  ::L_129::
  goto L_365
  e[19] = e[29][K(0)]  -- GETTABLE/CLOSURE? [a=29 b=0 c=19 d=nil]
  e[24] = e[30][K(0)]  -- GETTABLE/CLOSURE? [a=30 b=0 c=24 d=nil]
  e[8] = e[31][58]  -- GETTABLE/CLOSURE? [a=31 b=0 c=8 d=nil]  -- = 58
  ::L_133::
  goto L_306
  e[31] = e[2][K(0)]  -- GETTABLE/CLOSURE? [a=2 b=0 c=31 d=nil]
  e[32] = e[15][K(0)]  -- GETTABLE/CLOSURE? [a=15 b=0 c=32 d=nil]
  e[33] = e[10][K(0)]  -- GETTABLE/CLOSURE? [a=10 b=0 c=33 d=nil]
  ::L_137::
  goto L_533
  e[35] = e[42][K(0)]  -- GETTABLE/CLOSURE? [a=42 b=0 c=35 d=nil]
  e[36] = e[43][K(0)]  -- GETTABLE/CLOSURE? [a=43 b=0 c=36 d=nil]
  -- UNKNOWN op? [a=44 b=0 c=34 d=nil]
  call(e[39], e[0])  -- CALL [a=39 b=0 c=0 d=nil] -- void call
  ::L_142::
  goto L_89
  ::L_143::
  goto L_20
  e[71] = e[56][K(0)]  -- GETTABLE/CLOSURE? [a=56 b=0 c=71 d=nil]
  e[72] = e[51][K(0)]  -- GETTABLE/CLOSURE? [a=51 b=0 c=72 d=nil]
  if e[59] then goto L_14 end  -- back-edge (loop)
  e[58] = e[59][K(0)]  -- GETTABLE/CLOSURE? [a=59 b=0 c=58 d=nil]
  goto L_202
  ::L_149::
  -- UNKNOWN op? [a=452 b=337 c=152 d=nil]
  e[44] = e[35][K(0)]  -- GETTABLE/CLOSURE? [a=35 b=0 c=44 d=nil]
  e[45] = e[34][K(0)]  -- GETTABLE/CLOSURE? [a=34 b=0 c=45 d=nil]
  e[46] = e[38][K(0)]  -- GETTABLE/CLOSURE? [a=38 b=0 c=46 d=nil]
  e[47] = e[33][K(0)]  -- GETTABLE/CLOSURE? [a=33 b=0 c=47 d=nil]
  ::L_154::
  goto L_723
  e[31] = e[33][K(0)]  -- GETTABLE/CLOSURE? [a=33 b=0 c=31 d=nil]
  e[29] = e[34][K(0)]  -- GETTABLE/CLOSURE? [a=34 b=0 c=29 d=nil]
  e[8] = e[35][117]  -- GETTABLE/CLOSURE? [a=35 b=0 c=8 d=nil]  -- = 117
  e[30] = e[36][K(0)]  -- GETTABLE/CLOSURE? [a=36 b=0 c=30 d=nil]
  ::L_159::
  goto L_694
  e[45] = e[47][K(0)]  -- GETTABLE/CLOSURE? [a=47 b=0 c=45 d=nil]
  call(e[46], e[0])  -- CALL [a=46 b=0 c=0 d=nil] -- void call
  e[1] = e[47]  -- MOVE [a=47 b=1 c=1910 d=nil]
  ::L_163::
  goto L_700
  e[10] = e[12][K(0)]  -- GETTABLE/CLOSURE? [a=12 b=0 c=10 d=nil]
  e[9] = e[13][K(0)]  -- GETTABLE/CLOSURE? [a=13 b=0 c=9 d=nil]
  e[8] = e[14][69]  -- GETTABLE/CLOSURE? [a=14 b=0 c=8 d=nil]  -- = 69
  e[11] = e[15][K(0)]  -- GETTABLE/CLOSURE? [a=15 b=0 c=11 d=nil]
  call(e[12], e[0])  -- CALL [a=12 b=0 c=0 d=nil] -- void call
  e[1] = e[13]  -- MOVE [a=13 b=1 c=1374 d=nil]
  ::L_170::
  e[15] = e[12][K(0)]  -- GETTABLE/CLOSURE? [a=12 b=0 c=15 d=nil]
  e[16] = e[7][K(0)]  -- GETTABLE/CLOSURE? [a=7 b=0 c=16 d=nil]
  ::L_172::
  goto L_281
  -- UNKNOWN op? [a=30 b=0 c=169 d=nil]
  e[46] = e[10][K(0)]  -- GETTABLE/CLOSURE? [a=10 b=0 c=46 d=nil]
  if e[36] then goto L_11 end  -- back-edge (loop)
  e[31] = e[36][K(0)]  -- GETTABLE/CLOSURE? [a=36 b=0 c=31 d=nil]
  e[8] = e[37][111]  -- GETTABLE/CLOSURE? [a=37 b=0 c=8 d=nil]  -- = 111
  ::L_178::
  goto L_645
  e[1] = e[226]  -- MOVE [a=226 b=1 c=1330 d=nil]
  e[18][K(100)] = e[16]  -- SETTABLE/CALL [a=18 b=100 c=16 d=nil] -- settable/void-call (inferred)
  call(e[8], e[46])  -- CALL [a=8 b=85 c=46 d=nil] -- void call
  e[181] = K(5)  -- LOADK_S [a=181 b=5 c=226 d=nil]
  e[17] = e[7][K(0)]  -- GETTABLE/CLOSURE? [a=7 b=0 c=17 d=nil]
  e[18] = e[9][K(0)]  -- GETTABLE/CLOSURE? [a=9 b=0 c=18 d=nil]
  e[19] = e[2][K(0)]  -- GETTABLE/CLOSURE? [a=2 b=0 c=19 d=nil]
  e[20] = e[13][K(0)]  -- GETTABLE/CLOSURE? [a=13 b=0 c=20 d=nil]
  if e[14] then goto L_7 end  -- back-edge (loop)
  e[8] = e[14][36]  -- GETTABLE/CLOSURE? [a=14 b=0 c=8 d=nil]  -- = 36
  goto L_189
  e[58] = e[25][K(0)]  -- GETTABLE/CLOSURE? [a=25 b=0 c=58 d=nil]
  e[59] = e[28][K(0)]  -- GETTABLE/CLOSURE? [a=28 b=0 c=59 d=nil]
  e[60] = e[29][K(0)]  -- GETTABLE/CLOSURE? [a=29 b=0 c=60 d=nil]
  e[61] = e[8][116]  -- GETTABLE/CLOSURE? [a=8 b=0 c=61 d=nil]  -- = 116
  ::L_194::
  goto L_591
  e[14] = e[9][K(0)]  -- GETTABLE/CLOSURE? [a=9 b=0 c=14 d=nil]
  e[15] = e[7][K(0)]  -- GETTABLE/CLOSURE? [a=7 b=0 c=15 d=nil]
  e[16] = e[10][K(0)]  -- GETTABLE/CLOSURE? [a=10 b=0 c=16 d=nil]
  ::L_198::
  goto L_6
  e[52] = e[42][K(0)]  -- GETTABLE/CLOSURE? [a=42 b=0 c=52 d=nil]
  if e[44] then goto L_9 end  -- back-edge (loop)
  e[41] = e[44][K(0)]  -- GETTABLE/CLOSURE? [a=44 b=0 c=41 d=nil]
  ::L_202::
  goto L_96
  e[8] = e[60][K(0)]  -- GETTABLE/CLOSURE? [a=60 b=0 c=8 d=nil]
  e[56] = e[61][K(0)]  -- GETTABLE/CLOSURE? [a=61 b=0 c=56 d=nil]
  e[57] = e[62][K(0)]  -- GETTABLE/CLOSURE? [a=62 b=0 c=57 d=nil]
  goto L_206
  e[69] = e[45][K(0)]  -- GETTABLE/CLOSURE? [a=45 b=0 c=69 d=nil]
  if e[60] then goto L_10 end  -- back-edge (loop)
  e[59] = e[60][K(0)]  -- GETTABLE/CLOSURE? [a=60 b=0 c=59 d=nil]
  ::L_210::
  goto L_311
  e[1] = e[51]  -- MOVE [a=51 b=1 c=2235 d=nil]
  e[53] = e[3][K(144)]  -- GETTABLE/CLOSURE? [a=3 b=144 c=53 d=nil]
  e[54] = e[4][K(0)]  -- GETTABLE/CLOSURE? [a=4 b=0 c=54 d=nil]
  e[55] = e[41][K(0)]  -- GETTABLE/CLOSURE? [a=41 b=0 c=55 d=nil]
  e[56] = e[5][K(0)]  -- GETTABLE/CLOSURE? [a=5 b=0 c=56 d=nil]
  ::L_216::
  goto L_347
  e[56] = e[62][K(0)]  -- GETTABLE/CLOSURE? [a=62 b=0 c=56 d=nil]
  e[1] = e[61]  -- MOVE [a=61 b=1 c=268 d=nil]
  e[63] = e[43][K(0)]  -- GETTABLE/CLOSURE? [a=43 b=0 c=63 d=nil]
  ::L_221::
  goto L_724
  e[60] = e[52][K(0)]  -- GETTABLE/CLOSURE? [a=52 b=0 c=60 d=nil]
  e[61] = e[51][K(0)]  -- GETTABLE/CLOSURE? [a=51 b=0 c=61 d=nil]
  e[62] = e[2][K(0)]  -- GETTABLE/CLOSURE? [a=2 b=0 c=62 d=nil]
  if e[53] then goto L_10 end  -- back-edge (loop)
  e[51] = e[53][K(0)]  -- GETTABLE/CLOSURE? [a=53 b=0 c=51 d=nil]
  e[8] = e[54][110]  -- GETTABLE/CLOSURE? [a=54 b=0 c=8 d=nil]  -- = 110
  e[52] = e[55][K(0)]  -- GETTABLE/CLOSURE? [a=55 b=0 c=52 d=nil]
  e[1] = e[53]  -- MOVE [a=53 b=1 c=1104 d=nil]
  ::L_230::
  goto L_32
  e[1] = e[51]  -- MOVE [a=51 b=1 c=389 d=nil]
  e[153][K(90)] = e[53]  -- SETTABLE/CALL [a=153 b=90 c=53 d=nil] -- settable/void-call (inferred)
  call(e[8], e[168])  -- CALL [a=8 b=79 c=168 d=nil] -- void call
  e[10] = K(183)  -- LOADK_S [a=10 b=183 c=152 d=nil]
  e[54] = e[12][K(0)]  -- GETTABLE/CLOSURE? [a=12 b=0 c=54 d=nil]
  e[55] = e[2][K(0)]  -- GETTABLE/CLOSURE? [a=2 b=0 c=55 d=nil]
  e[51] = K(51)  -- LOADK_N [a=0 b=51 c=5 d=nil]
  e[8] = e[51][105]  -- GETTABLE/CLOSURE? [a=51 b=0 c=8 d=nil]  -- = 105
  call(e[52], e[51])  -- CALL? [a=52 b=0 c=51 d=nil] -- void call
  e[1] = e[53]  -- MOVE [a=53 b=1 c=1343 d=nil]
  e[55] = e[19][K(0)]  -- GETTABLE/CLOSURE? [a=19 b=0 c=55 d=nil]
  e[56] = e[21][K(0)]  -- GETTABLE/CLOSURE? [a=21 b=0 c=56 d=nil]
  e[57] = e[10][K(0)]  -- GETTABLE/CLOSURE? [a=10 b=0 c=57 d=nil]
  e[58] = e[15][K(0)]  -- GETTABLE/CLOSURE? [a=15 b=0 c=58 d=nil]
  e[59] = e[8][105]  -- GETTABLE/CLOSURE? [a=8 b=0 c=59 d=nil]  -- = 105
  ::L_246::
  goto L_221
  e[32] = e[22][K(0)]  -- GETTABLE/CLOSURE? [a=22 b=0 c=32 d=nil]
  e[87] = e[8][19]  -- GETTABLE/CLOSURE? [a=8 b=0 c=87 d=nil]  -- = 19
  e[34] = e[24][K(0)]  -- GETTABLE/CLOSURE? [a=24 b=0 c=34 d=nil]
  e[35] = e[21][K(0)]  -- GETTABLE/CLOSURE? [a=21 b=0 c=35 d=nil]
  e[36] = e[10][K(0)]  -- GETTABLE/CLOSURE? [a=10 b=0 c=36 d=nil]
  e[37] = e[9][K(0)]  -- GETTABLE/CLOSURE? [a=9 b=0 c=37 d=nil]
  e[38] = e[20][K(0)]  -- GETTABLE/CLOSURE? [a=20 b=0 c=38 d=nil]
  if e[26] then goto L_13 end  -- back-edge (loop)
  e[22] = e[26][K(0)]  -- GETTABLE/CLOSURE? [a=26 b=0 c=22 d=nil]
  e[25] = e[27][K(0)]  -- GETTABLE/CLOSURE? [a=27 b=0 c=25 d=nil]
  e[20] = e[28][K(0)]  -- GETTABLE/CLOSURE? [a=28 b=0 c=20 d=nil]
  ::L_258::
  goto L_129
  e[16] = e[18][K(0)]  -- GETTABLE/CLOSURE? [a=18 b=0 c=16 d=nil]
  e[15] = e[19][K(0)]  -- GETTABLE/CLOSURE? [a=19 b=0 c=15 d=nil]
  call(e[18], e[17])  -- CALL? [a=18 b=0 c=17 d=nil] -- void call
  ::L_262::
  goto L_493
  e[0] = {}  -- NEWTABLE [a=0 b=1 c=0 d=nil]
  e[2] = {}  -- NEWTABLE [a=0 b=0 c=2 d=nil]
  call(e[4], e[3])  -- CALL? [a=4 b=0 c=3 d=nil] -- void call
  ::L_266::
  goto L_11
  e[42] = e[32][K(0)]  -- GETTABLE/CLOSURE? [a=32 b=0 c=42 d=nil]
  e[43] = e[33][K(0)]  -- GETTABLE/CLOSURE? [a=33 b=0 c=43 d=nil]
  e[44] = e[8][117]  -- GETTABLE/CLOSURE? [a=8 b=0 c=44 d=nil]  -- = 117
  ::L_270::
  goto L_142
  e[1] = e[19]  -- MOVE [a=19 b=1 c=1490 d=nil]
  e[21] = e[10][K(0)]  -- GETTABLE/CLOSURE? [a=10 b=0 c=21 d=nil]
  e[22] = e[2][K(0)]  -- GETTABLE/CLOSURE? [a=2 b=0 c=22 d=nil]
  e[23] = e[16][K(0)]  -- GETTABLE/CLOSURE? [a=16 b=0 c=23 d=nil]
  e[24] = e[8][36]  -- GETTABLE/CLOSURE? [a=8 b=0 c=24 d=nil]  -- = 36
  e[25] = e[14][K(0)]  -- GETTABLE/CLOSURE? [a=14 b=0 c=25 d=nil]
  e[26] = e[17][K(0)]  -- GETTABLE/CLOSURE? [a=17 b=0 c=26 d=nil]
  e[27] = e[18][K(0)]  -- GETTABLE/CLOSURE? [a=18 b=0 c=27 d=nil]
  e[28] = e[7][K(0)]  -- GETTABLE/CLOSURE? [a=7 b=0 c=28 d=nil]
  e[29] = e[15][K(0)]  -- GETTABLE/CLOSURE? [a=15 b=0 c=29 d=nil]
  ::L_281::
  goto L_488
  e[17] = e[8][69]  -- GETTABLE/CLOSURE? [a=8 b=0 c=17 d=nil]  -- = 69
  e[18] = e[2][K(0)]  -- GETTABLE/CLOSURE? [a=2 b=0 c=18 d=nil]
  if e[13] then goto L_6 end  -- back-edge (loop)
  ::L_285::
  goto L_513
  ::L_286::
  goto L_610
  e[61] = e[32][K(0)]  -- GETTABLE/CLOSURE? [a=32 b=0 c=61 d=nil]
  e[62] = e[49][K(0)]  -- GETTABLE/CLOSURE? [a=49 b=0 c=62 d=nil]
  e[55] = K(55)  -- LOADK_N [a=0 b=55 c=8 d=nil]
  e[8] = e[55][K(0)]  -- GETTABLE/CLOSURE? [a=55 b=0 c=8 d=nil]
  ::L_291::
  goto L_520
  e[61] = e[36][K(0)]  -- GETTABLE/CLOSURE? [a=36 b=0 c=61 d=nil]
  e[62] = e[2][K(0)]  -- GETTABLE/CLOSURE? [a=2 b=0 c=62 d=nil]
  e[63] = e[54][K(0)]  -- GETTABLE/CLOSURE? [a=54 b=0 c=63 d=nil]
  e[64] = e[58][K(0)]  -- GETTABLE/CLOSURE? [a=58 b=0 c=64 d=nil]
  e[65] = e[16][K(0)]  -- GETTABLE/CLOSURE? [a=16 b=0 c=65 d=nil]
  e[66] = e[46][K(0)]  -- GETTABLE/CLOSURE? [a=46 b=0 c=66 d=nil]
  e[67] = e[50][K(0)]  -- GETTABLE/CLOSURE? [a=50 b=0 c=67 d=nil]
  e[68] = e[42][K(0)]  -- GETTABLE/CLOSURE? [a=42 b=0 c=68 d=nil]
  goto L_524
  ::L_301::
  -- UNKNOWN op? [a=442 b=247 c=277 d=nil]
  e[41] = e[29][K(0)]  -- GETTABLE/CLOSURE? [a=29 b=0 c=41 d=nil]
  e[42] = e[27][K(0)]  -- GETTABLE/CLOSURE? [a=27 b=0 c=42 d=nil]
  if e[32] then goto L_11 end  -- back-edge (loop)
  e[28] = e[32][K(0)]  -- GETTABLE/CLOSURE? [a=32 b=0 c=28 d=nil]
  ::L_306::
  goto L_154
  ::L_307::
  goto L_315
  e[18] = e[24][K(0)]  -- GETTABLE/CLOSURE? [a=24 b=0 c=18 d=nil]
  e[8] = e[25][19]  -- GETTABLE/CLOSURE? [a=25 b=0 c=8 d=nil]  -- = 19
  e[19] = e[26][K(0)]  -- GETTABLE/CLOSURE? [a=26 b=0 c=19 d=nil]
  ::L_311::
  goto L_656
  e[20] = e[61][K(0)]  -- GETTABLE/CLOSURE? [a=61 b=0 c=20 d=nil]
  e[8] = e[62][K(0)]  -- GETTABLE/CLOSURE? [a=62 b=0 c=8 d=nil]
  call(e[60], e[0])  -- CALL [a=60 b=0 c=0 d=nil] -- void call
  ::L_315::
  goto L_494
  e[79] = {}  -- NEWTABLE [a=79 b=0 c=0 d=nil]
  e[77] = {}  -- NEWTABLE [a=77 b=0 c=0 d=nil]
  e[83] = K(20)  -- LOADK_S [a=0 b=20 c=83 d=nil]
  e[84] = K(12)  -- LOADK_S [a=0 b=12 c=84 d=nil]
  call(e[34], e[220])  -- CALL [a=34 b=150 c=220 d=nil] -- void call
  e[85][K(1410)] = e[64]  -- SETTABLE/CALL [a=85 b=1410 c=64 d=251] -- settable/void-call (inferred)
  e[30] = K(147)  -- LOADK_S [a=30 b=147 c=126 d=nil]
  e[84] = 24  -- LOADK_N [a=0 b=0 c=84 d=nil]
  e[85] = 10  -- LOADK [a=85 b=1353 c=0 d=10]
  e[83] = 100663296  -- LOADK_N [a=0 b=83 c=0 d=nil]
  e[83] = e[83] + -100651856  -- ADD [a=83 b=1279 c=83 d=-100651856]  -- = 11440
  e[83] = arith(e[83], e[378])  -- UNOP/arith? [a=83 b=83 c=378 d=nil]  -- = 292
  call(e[83], e[105])  -- CALL [a=83 b=79 c=105 d=nil] -- void call
  e[77][K(1017)] = e[128]  -- SETTABLE [a=77 b=1017 c=128 d=307] -- settable/void-call (inferred)
  call(e[88], e[75])  -- CALL? [a=88 b=0 c=75 d=nil] -- void call
  ::L_331::
  goto L_51
  e[57][K(0)] = e[56]  -- SETTABLE/CALL [a=57 b=0 c=56 d=nil] -- settable/void-call (inferred)
  e[1] = e[58]  -- MOVE [a=58 b=1 c=2387 d=nil]
  e[238][K(216)] = e[60]  -- SETTABLE/CALL [a=238 b=216 c=60 d=nil] -- settable/void-call (inferred)
  call(e[8], e[248])  -- CALL [a=8 b=3 c=248 d=nil] -- void call
  e[119] = K(253)  -- LOADK_S [a=119 b=253 c=5 d=nil]
  e[61] = e[25][K(0)]  -- GETTABLE/CLOSURE? [a=25 b=0 c=61 d=nil]
  e[62] = e[57][K(0)]  -- GETTABLE/CLOSURE? [a=57 b=0 c=62 d=nil]
  e[63] = e[56][K(0)]  -- GETTABLE/CLOSURE? [a=56 b=0 c=63 d=nil]
  e[64] = e[2][K(0)]  -- GETTABLE/CLOSURE? [a=2 b=0 c=64 d=nil]
  e[65] = e[28][K(0)]  -- GETTABLE/CLOSURE? [a=28 b=0 c=65 d=nil]
  e[66] = e[26][K(0)]  -- GETTABLE/CLOSURE? [a=26 b=0 c=66 d=nil]
  ::L_343::
  goto L_556
  if e[56] then goto L_11 end  -- back-edge (loop)
  e[55] = e[56][K(0)]  -- GETTABLE/CLOSURE? [a=56 b=0 c=55 d=nil]
  e[8] = e[57][K(0)]  -- GETTABLE/CLOSURE? [a=57 b=0 c=8 d=nil]
  ::L_347::
  goto L_331
  e[57] = e[35][K(0)]  -- GETTABLE/CLOSURE? [a=35 b=0 c=57 d=nil]
  e[58] = e[2][K(0)]  -- GETTABLE/CLOSURE? [a=2 b=0 c=58 d=nil]
  e[59] = e[33][K(0)]  -- GETTABLE/CLOSURE? [a=33 b=0 c=59 d=nil]
  e[60] = e[8][8]  -- GETTABLE/CLOSURE? [a=8 b=0 c=60 d=nil]  -- = 8
  e[51] = K(51)  -- LOADK_N [a=0 b=51 c=10 d=nil]
  e[8] = e[51][11]  -- GETTABLE/CLOSURE? [a=51 b=0 c=8 d=nil]  -- = 11
  ::L_354::
  goto L_230
  e[91] = {}  -- NEWTABLE [a=91 b=0 c=0 d=nil]
  e[91][K(2287)] = e[81]  -- SETTABLE [a=91 b=2287 c=81 d=544] -- settable/void-call (inferred)
  e[91][K(1030)] = e[2137]  -- SETTABLE [a=91 b=1030 c=2137 d=411] -- settable/void-call (inferred)
  call(e[96], e[89])  -- CALL? [a=96 b=0 c=89 d=nil] -- void call
  ::L_359::
  goto L_542
  e[93] = {}  -- NEWTABLE [a=93 b=0 c=0 d=nil]
  e[91] = {}  -- NEWTABLE [a=91 b=0 c=0 d=nil]
  e[93][K(1120)] = e[8]  -- SETTABLE [a=93 b=1120 c=8 d=572] -- settable/void-call (inferred)
  e[91][K(724)] = e[1095]  -- SETTABLE [a=91 b=724 c=1095 d=611] -- settable/void-call (inferred)
  call(e[96], e[89])  -- CALL? [a=96 b=0 c=89 d=nil] -- void call
  ::L_365::
  goto L_566
  e[48] = e[44][K(0)]  -- GETTABLE/CLOSURE? [a=44 b=0 c=48 d=nil]
  e[49] = e[2][K(0)]  -- GETTABLE/CLOSURE? [a=2 b=0 c=49 d=nil]
  e[50] = e[45][K(0)]  -- GETTABLE/CLOSURE? [a=45 b=0 c=50 d=nil]
  if e[46] then goto L_5 end  -- back-edge (loop)
  e[44] = e[46][K(0)]  -- GETTABLE/CLOSURE? [a=46 b=0 c=44 d=nil]
  goto L_371
  e[48] = e[41][K(0)]  -- GETTABLE/CLOSURE? [a=41 b=0 c=48 d=nil]
  e[49] = e[2][K(0)]  -- GETTABLE/CLOSURE? [a=2 b=0 c=49 d=nil]
  e[50] = e[40][K(0)]  -- GETTABLE/CLOSURE? [a=40 b=0 c=50 d=nil]
  e[51] = e[43][K(0)]  -- GETTABLE/CLOSURE? [a=43 b=0 c=51 d=nil]
  ::L_376::
  goto L_198
  e[78] = {}  -- NEWTABLE [a=0 b=78 c=0 d=nil]
  e[77] = {}  -- NEWTABLE [a=77 b=0 c=0 d=nil]
  e[83] = K(14)  -- LOADK_S [a=0 b=14 c=83 d=nil]
  e[62] = 194  -- LOADK [a=62 b=708 c=0 d=194]
  e[83] = 194  -- LOADK_N [a=0 b=0 c=83 d=nil]
  e[84] = K(9)  -- LOADK_S [a=0 b=9 c=84 d=nil]
  e[85] = "250173.136"  -- LOADK [a=85 b=1218 c=0 d=��.�]
  e[86] = 1  -- LOADK [a=86 b=107 c=0 d=1]
  e[87] = 4  -- LOADK [a=87 b=70 c=0 d=4]
  e[84] = 250  -- LOADK_N [a=0 b=84 c=4 d=nil]
  e[83] = arith(e[83], e[84])  -- ARITH [a=83 b=83 c=84 d=nil]  -- = 444
  e[83] = e[83] + 8492  -- ADD [a=83 b=1126 c=83 d=8492]  -- = 8936
  e[83] = arith(e[83], e[878])  -- UNOP/arith? [a=83 b=83 c=878 d=nil]  -- = 7
  call(e[83], e[85])  -- CALL [a=83 b=78 c=85 d=nil] -- void call
  e[77][K(2331)] = e[1741]  -- SETTABLE [a=77 b=2331 c=1741 d=494] -- settable/void-call (inferred)
  call(e[88], e[75])  -- CALL? [a=88 b=0 c=75 d=nil] -- void call
  ::L_393::
  goto L_270
  e[62] = e[17][K(0)]  -- GETTABLE/CLOSURE? [a=17 b=0 c=62 d=nil]
  e[63] = e[51][K(0)]  -- GETTABLE/CLOSURE? [a=51 b=0 c=63 d=nil]
  e[64] = e[8][120]  -- GETTABLE/CLOSURE? [a=8 b=0 c=64 d=nil]  -- = 120
  if e[55] then goto L_10 end  -- back-edge (loop)
  e[54] = e[55][K(0)]  -- GETTABLE/CLOSURE? [a=55 b=0 c=54 d=nil]
  goto L_406
  e[71] = (e[16] == e[119])  -- COMPARE [a=16 b=71 c=119 d=nil]
  ::L_401::
  e[147][K(148)] = e[441]  -- SETTABLE/CALL [a=147 b=148 c=441 d=nil] -- settable/void-call (inferred)
  e[1] = e[9]  -- MOVE [a=9 b=1 c=708 d=nil]
  e[11] = e[5][K(0)]  -- GETTABLE/CLOSURE? [a=5 b=0 c=11 d=nil]
  e[12] = e[2][K(0)]  -- GETTABLE/CLOSURE? [a=2 b=0 c=12 d=nil]
  e[13] = e[6][K(0)]  -- GETTABLE/CLOSURE? [a=6 b=0 c=13 d=nil]
  ::L_406::
  goto L_417
  e[8] = e[56][77]  -- GETTABLE/CLOSURE? [a=56 b=0 c=8 d=nil]  -- = 77
  e[1] = e[55]  -- MOVE [a=55 b=1 c=489 d=nil]
  e[57] = e[37][K(0)]  -- GETTABLE/CLOSURE? [a=37 b=0 c=57 d=nil]
  ::L_410::
  goto L_444
  ::L_411::
  goto L_354
  e[92] = {}  -- NEWTABLE [a=0 b=92 c=0 d=nil]
  e[91] = {}  -- NEWTABLE [a=91 b=0 c=0 d=nil]
  e[92][K(723)] = e[2]  -- SETTABLE [a=92 b=723 c=2 d=380] -- settable/void-call (inferred)
  e[91][K(932)] = e[509]  -- SETTABLE [a=91 b=932 c=509 d=96] -- settable/void-call (inferred)
  call(e[96], e[89])  -- CALL? [a=96 b=0 c=89 d=nil] -- void call
  ::L_417::
  goto L_376
  e[14] = e[7][K(0)]  -- GETTABLE/CLOSURE? [a=7 b=0 c=14 d=nil]
  e[15] = e[8][K(0)]  -- GETTABLE/CLOSURE? [a=8 b=0 c=15 d=nil]
  if e[9] then goto L_7 end  -- back-edge (loop)
  e[8] = e[9][109]  -- GETTABLE/CLOSURE? [a=9 b=0 c=8 d=nil]  -- = 109
  e[7] = e[10][K(0)]  -- GETTABLE/CLOSURE? [a=10 b=0 c=7 d=nil]
  ::L_423::
  goto L_483
  e[1] = e[54]  -- MOVE [a=54 b=1 c=172 d=nil]
  e[56] = e[2][K(0)]  -- GETTABLE/CLOSURE? [a=2 b=0 c=56 d=nil]
  e[57] = e[53][K(0)]  -- GETTABLE/CLOSURE? [a=53 b=0 c=57 d=nil]
  goto L_428
  e[1] = e[59]  -- MOVE [a=59 b=1 c=2166 d=nil]
  e[61] = e[8][K(0)]  -- GETTABLE/CLOSURE? [a=8 b=0 c=61 d=nil]
  e[62] = e[57][K(0)]  -- GETTABLE/CLOSURE? [a=57 b=0 c=62 d=nil]
  e[63] = e[58][K(0)]  -- GETTABLE/CLOSURE? [a=58 b=0 c=63 d=nil]
  ::L_433::
  goto L_113
  e[92] = {}  -- NEWTABLE [a=0 b=92 c=0 d=nil]
  e[91] = {}  -- NEWTABLE [a=91 b=0 c=0 d=nil]
  e[92][K(1472)] = e[100]  -- SETTABLE [a=92 b=1472 c=100 d=179] -- settable/void-call (inferred)
  e[91][K(512)] = e[724]  -- SETTABLE [a=91 b=512 c=724 d=514] -- settable/void-call (inferred)
  call(e[96], e[89])  -- CALL? [a=96 b=0 c=89 d=nil] -- void call
  ::L_439::
  goto L_611
  e[65] = e[60][K(0)]  -- GETTABLE/CLOSURE? [a=60 b=0 c=65 d=nil]
  if e[61] then goto L_5 end  -- back-edge (loop)
  e[60] = e[61][K(0)]  -- GETTABLE/CLOSURE? [a=61 b=0 c=60 d=nil]
  goto L_443
  ::L_444::
  goto L_713
  e[58] = e[8][77]  -- GETTABLE/CLOSURE? [a=8 b=0 c=58 d=nil]  -- = 77
  e[59] = e[53][K(0)]  -- GETTABLE/CLOSURE? [a=53 b=0 c=59 d=nil]
  e[60] = e[29][K(0)]  -- GETTABLE/CLOSURE? [a=29 b=0 c=60 d=nil]
  e[61] = e[2][K(0)]  -- GETTABLE/CLOSURE? [a=2 b=0 c=61 d=nil]
  ::L_449::
  goto L_285
  e[64] = e[59][K(0)]  -- GETTABLE/CLOSURE? [a=59 b=0 c=64 d=nil]
  e[65] = e[2][K(0)]  -- GETTABLE/CLOSURE? [a=2 b=0 c=65 d=nil]
  e[66] = e[13][K(0)]  -- GETTABLE/CLOSURE? [a=13 b=0 c=66 d=nil]
  e[67] = e[33][K(0)]  -- GETTABLE/CLOSURE? [a=33 b=0 c=67 d=nil]
  e[68] = e[3][K(0)]  -- GETTABLE/CLOSURE? [a=3 b=0 c=68 d=nil]
  goto L_455
  if e[51] then goto L_9 end  -- back-edge (loop)
  e[49] = e[51][K(0)]  -- GETTABLE/CLOSURE? [a=51 b=0 c=49 d=nil]
  e[48] = e[52][K(0)]  -- GETTABLE/CLOSURE? [a=52 b=0 c=48 d=nil]
  e[47] = e[53][K(0)]  -- GETTABLE/CLOSURE? [a=53 b=0 c=47 d=nil]
  e[50] = e[54][K(0)]  -- GETTABLE/CLOSURE? [a=54 b=0 c=50 d=nil]
  e[8] = e[55][8]  -- GETTABLE/CLOSURE? [a=55 b=0 c=8 d=nil]  -- = 8
  ::L_462::
  goto L_210
  e[65] = e[17][K(0)]  -- GETTABLE/CLOSURE? [a=17 b=0 c=65 d=nil]
  e[66] = e[43][K(0)]  -- GETTABLE/CLOSURE? [a=43 b=0 c=66 d=nil]
  if e[55] then goto L_12 end  -- back-edge (loop)
  e[8] = e[55][K(0)]  -- GETTABLE/CLOSURE? [a=55 b=0 c=8 d=nil]
  e[54] = e[56][K(0)]  -- GETTABLE/CLOSURE? [a=56 b=0 c=54 d=nil]
  e[1] = e[55]  -- MOVE [a=55 b=1 c=1916 d=nil]
  e[57] = e[3][K(0)]  -- GETTABLE/CLOSURE? [a=3 b=0 c=57 d=nil]
  e[58] = e[41][K(0)]  -- GETTABLE/CLOSURE? [a=41 b=0 c=58 d=nil]
  e[59] = e[2][K(0)]  -- GETTABLE/CLOSURE? [a=2 b=0 c=59 d=nil]
  e[60] = e[8][K(0)]  -- GETTABLE/CLOSURE? [a=8 b=0 c=60 d=nil]
  ::L_473::
  goto L_286
  e[1] = e[44]  -- MOVE [a=44 b=1 c=2254 d=nil]
  e[46] = e[36][K(0)]  -- GETTABLE/CLOSURE? [a=36 b=0 c=46 d=nil]
  e[47] = e[8][80]  -- GETTABLE/CLOSURE? [a=8 b=0 c=47 d=nil]  -- = 80
  goto L_477
  e[91] = {}  -- NEWTABLE [a=91 b=0 c=0 d=nil]
  e[90] = {}  -- NEWTABLE [a=90 b=0 c=0 d=nil]
  e[90][K(5)] = e[1]  -- SETTABLE [a=90 b=5 c=1 d=65] -- settable/void-call (inferred)
  e[91][K(1622)] = e[98]  -- SETTABLE [a=91 b=1622 c=98 d=217] -- settable/void-call (inferred)
  call(e[96], e[89])  -- CALL? [a=96 b=0 c=89 d=nil] -- void call
  ::L_483::
  goto L_64
  e[6] = e[11][K(0)]  -- GETTABLE/CLOSURE? [a=11 b=0 c=6 d=nil]
  e[5] = e[12][K(0)]  -- GETTABLE/CLOSURE? [a=12 b=0 c=5 d=nil]
  call(e[11], e[9])  -- CALL? [a=11 b=0 c=9 d=nil] -- void call
  e[1] = e[12]  -- MOVE [a=12 b=1 c=891 d=nil]
  ::L_488::
  goto L_194
  if e[19] then goto L_11 end  -- back-edge (loop)
  e[18] = e[19][K(0)]  -- GETTABLE/CLOSURE? [a=19 b=0 c=18 d=nil]
  e[17] = e[20][K(0)]  -- GETTABLE/CLOSURE? [a=20 b=0 c=17 d=nil]
  e[14] = e[21][K(0)]  -- GETTABLE/CLOSURE? [a=21 b=0 c=14 d=nil]
  ::L_493::
  goto L_638
  ::L_494::
  goto L_95
  e[1] = e[61]  -- MOVE [a=61 b=1 c=996 d=nil]
  e[63] = e[56][K(0)]  -- GETTABLE/CLOSURE? [a=56 b=0 c=63 d=nil]
  e[64] = e[2][K(0)]  -- GETTABLE/CLOSURE? [a=2 b=0 c=64 d=nil]
  ::L_498::
  goto L_439
  e[93] = {}  -- NEWTABLE [a=93 b=0 c=0 d=nil]
  e[91] = {}  -- NEWTABLE [a=91 b=0 c=0 d=nil]
  e[93][K(704)] = e[461]  -- SETTABLE [a=93 b=704 c=461 d=332] -- settable/void-call (inferred)
  e[91][K(542)] = e[1699]  -- SETTABLE [a=91 b=542 c=1699 d=709] -- settable/void-call (inferred)
  call(e[96], e[89])  -- CALL? [a=96 b=0 c=89 d=nil] -- void call
  ::L_504::
  goto L_343
  e[58] = e[26][K(0)]  -- GETTABLE/CLOSURE? [a=26 b=0 c=58 d=nil]
  e[59] = e[18][K(0)]  -- GETTABLE/CLOSURE? [a=18 b=0 c=59 d=nil]
  e[60] = e[52][K(0)]  -- GETTABLE/CLOSURE? [a=52 b=0 c=60 d=nil]
  ::L_508::
  goto L_623
  call(e[59], e[0])  -- CALL [a=59 b=0 c=0 d=nil] -- void call
  e[1] = e[60]  -- MOVE [a=60 b=1 c=1121 d=nil]
  e[62] = e[20][K(0)]  -- GETTABLE/CLOSURE? [a=20 b=0 c=62 d=nil]
  e[63] = e[8][K(0)]  -- GETTABLE/CLOSURE? [a=8 b=0 c=63 d=nil]
  ::L_513::
  goto L_449
  ::L_514::
  goto L_433
  e[54] = e[47][K(0)]  -- GETTABLE/CLOSURE? [a=47 b=0 c=54 d=nil]
  e[55] = e[49][K(0)]  -- GETTABLE/CLOSURE? [a=49 b=0 c=55 d=nil]
  e[56] = e[48][K(0)]  -- GETTABLE/CLOSURE? [a=48 b=0 c=56 d=nil]
  e[57] = e[8][27]  -- GETTABLE/CLOSURE? [a=8 b=0 c=57 d=nil]  -- = 27
  if e[51] then goto L_7 end  -- back-edge (loop)
  ::L_520::
  goto L_619
  e[1] = e[55]  -- MOVE [a=55 b=1 c=585 d=nil]
  e[57] = e[12][K(0)]  -- GETTABLE/CLOSURE? [a=12 b=0 c=57 d=nil]
  e[58] = e[8][K(0)]  -- GETTABLE/CLOSURE? [a=8 b=0 c=58 d=nil]
  ::L_524::
  goto L_68
  e[69] = e[38][K(0)]  -- GETTABLE/CLOSURE? [a=38 b=0 c=69 d=nil]
  e[70] = e[55][K(0)]  -- GETTABLE/CLOSURE? [a=55 b=0 c=70 d=nil]
  e[71] = e[40][K(0)]  -- GETTABLE/CLOSURE? [a=40 b=0 c=71 d=nil]
  e[72] = e[34][K(0)]  -- GETTABLE/CLOSURE? [a=34 b=0 c=72 d=nil]
  e[73] = e[8][K(0)]  -- GETTABLE/CLOSURE? [a=8 b=0 c=73 d=nil]
  e[74] = e[10][K(0)]  -- GETTABLE/CLOSURE? [a=10 b=0 c=74 d=nil]
  e[59] = K(59)  -- LOADK_N [a=0 b=59 c=16 d=nil]
  e[8] = e[59][K(0)]  -- GETTABLE/CLOSURE? [a=59 b=0 c=8 d=nil]
  ::L_533::
  goto L_508
  if e[22] then goto L_12 end  -- back-edge (loop)
  e[21] = e[22][K(0)]  -- GETTABLE/CLOSURE? [a=22 b=0 c=21 d=nil]
  e[17] = e[23][K(0)]  -- GETTABLE/CLOSURE? [a=23 b=0 c=17 d=nil]
  goto L_537
  e[13] = e[15][K(0)]  -- GETTABLE/CLOSURE? [a=15 b=0 c=13 d=nil]
  call(e[16], e[14])  -- CALL? [a=16 b=0 c=14 d=nil] -- void call
  e[1] = e[17]  -- MOVE [a=17 b=1 c=1540 d=nil]
  e[19] = e[14][K(0)]  -- GETTABLE/CLOSURE? [a=14 b=0 c=19 d=nil]
  ::L_542::
  goto L_674
  e[46] = e[6][K(0)]  -- GETTABLE/CLOSURE? [a=6 b=0 c=46 d=nil]
  if e[40] then goto L_170 end  -- back-edge (loop)
  e[39] = e[40][K(0)]  -- GETTABLE/CLOSURE? [a=40 b=0 c=39 d=nil]
  e[38] = e[41][K(0)]  -- GETTABLE/CLOSURE? [a=41 b=0 c=38 d=nil]
  e[8] = e[42][80]  -- GETTABLE/CLOSURE? [a=42 b=0 c=8 d=nil]  -- = 80
  call(e[43], e[40])  -- CALL? [a=43 b=0 c=40 d=nil] -- void call
  ::L_549::
  goto L_473
  e[55] = K(55)  -- LOADK_N [a=0 b=55 c=7 d=nil]
  e[8] = e[55][K(0)]  -- GETTABLE/CLOSURE? [a=55 b=0 c=8 d=nil]
  call(e[55], e[0])  -- CALL [a=55 b=0 c=0 d=nil] -- void call
  e[1] = e[56]  -- MOVE [a=56 b=1 c=1122 d=nil]
  e[58] = e[18][K(0)]  -- GETTABLE/CLOSURE? [a=18 b=0 c=58 d=nil]
  e[59] = e[55][K(0)]  -- GETTABLE/CLOSURE? [a=55 b=0 c=59 d=nil]
  ::L_556::
  goto L_36
  e[67] = e[23][K(0)]  -- GETTABLE/CLOSURE? [a=23 b=0 c=67 d=nil]
  if e[58] then goto L_10 end  -- back-edge (loop)
  e[57] = e[58][K(0)]  -- GETTABLE/CLOSURE? [a=58 b=0 c=57 d=nil]
  ::L_560::
  goto L_601
  e[48] = e[8][111]  -- GETTABLE/CLOSURE? [a=8 b=0 c=48 d=nil]  -- = 111
  if e[39] then goto L_10 end  -- back-edge (loop)
  e[8] = e[39][81]  -- GETTABLE/CLOSURE? [a=39 b=0 c=8 d=nil]  -- = 81
  e[37] = e[40][K(0)]  -- GETTABLE/CLOSURE? [a=40 b=0 c=37 d=nil]
  e[38] = e[41][K(0)]  -- GETTABLE/CLOSURE? [a=41 b=0 c=38 d=nil]
  ::L_566::
  goto L_137
  e[78] = {}  -- NEWTABLE [a=0 b=78 c=0 d=nil]
  e[77] = {}  -- NEWTABLE [a=77 b=0 c=0 d=nil]
  e[83] = K(17)  -- LOADK_S [a=0 b=17 c=83 d=nil]
  e[84] = K(19)  -- LOADK_S [a=0 b=19 c=84 d=nil]
  e[85] = K(9)  -- LOADK_S [a=0 b=9 c=85 d=nil]
  -- UNKNOWN op? [a=86 b=2184 c=0 d=]
  e[87] = 1  -- LOADK [a=87 b=107 c=0 d=1]
  call(e[88], e[0])  -- CALL [a=88 b=0 c=0 d=nil] -- void call
  e[85] = 15  -- LOADK_N [a=0 b=85 c=4 d=nil]
  e[84] = 4294967280  -- LOADK_N [a=0 b=0 c=84 d=nil]
  e[83] = 4  -- LOADK_N [a=0 b=0 c=83 d=nil]
  e[83] = e[83] + 5530  -- ADD [a=83 b=1907 c=83 d=5530]  -- = 5534
  e[83] = arith(e[83], e[1280])  -- UNOP/arith? [a=83 b=83 c=1280 d=nil]  -- = 28
  call(e[83], e[127])  -- CALL [a=83 b=78 c=127 d=nil] -- void call
  e[77][K(79)] = e[115]  -- SETTABLE [a=77 b=79 c=115 d=286] -- settable/void-call (inferred)
  call(e[88], e[75])  -- CALL? [a=88 b=0 c=75 d=nil] -- void call
  ::L_583::
  goto L_28
  e[65] = e[29][K(0)]  -- GETTABLE/CLOSURE? [a=29 b=0 c=65 d=nil]
  e[66] = e[57][K(0)]  -- GETTABLE/CLOSURE? [a=57 b=0 c=66 d=nil]
  e[67] = e[24][K(0)]  -- GETTABLE/CLOSURE? [a=24 b=0 c=67 d=nil]
  ::L_587::
  goto L_709
  e[59] = K(59)  -- LOADK_N [a=0 b=59 c=12 d=nil]
  e[8] = e[59][K(0)]  -- GETTABLE/CLOSURE? [a=59 b=0 c=8 d=nil]
  e[1] = e[59]  -- MOVE [a=59 b=1 c=1011 d=nil]
  ::L_591::
  goto L_291
  if e[54] then goto L_8 end  -- back-edge (loop)
  e[53] = e[54][K(0)]  -- GETTABLE/CLOSURE? [a=54 b=0 c=53 d=nil]
  e[8] = e[55][120]  -- GETTABLE/CLOSURE? [a=55 b=0 c=8 d=nil]  -- = 120
  ::L_595::
  goto L_680
  e[91] = {}  -- NEWTABLE [a=91 b=0 c=0 d=nil]
  e[93] = {}  -- NEWTABLE [a=93 b=0 c=0 d=nil]
  e[93][K(359)] = e[112]  -- SETTABLE [a=93 b=359 c=112 d=140] -- settable/void-call (inferred)
  e[91][K(2380)] = e[2017]  -- SETTABLE [a=91 b=2380 c=2017 d=724] -- settable/void-call (inferred)
  call(e[96], e[89])  -- CALL? [a=96 b=0 c=89 d=nil] -- void call
  ::L_601::
  goto L_560
  e[8] = e[59][K(0)]  -- GETTABLE/CLOSURE? [a=59 b=0 c=8 d=nil]
  e[56] = e[60][K(0)]  -- GETTABLE/CLOSURE? [a=60 b=0 c=56 d=nil]
  call(e[58], e[0])  -- CALL [a=58 b=0 c=0 d=nil] -- void call
  e[1] = e[59]  -- MOVE [a=59 b=1 c=427 d=nil]
  e[61] = e[58][K(0)]  -- GETTABLE/CLOSURE? [a=58 b=0 c=61 d=nil]
  e[62] = e[2][K(0)]  -- GETTABLE/CLOSURE? [a=2 b=0 c=62 d=nil]
  e[63] = e[30][K(0)]  -- GETTABLE/CLOSURE? [a=30 b=0 c=63 d=nil]
  e[64] = e[17][K(0)]  -- GETTABLE/CLOSURE? [a=17 b=0 c=64 d=nil]
  ::L_610::
  goto L_583
  ::L_611::
  goto L_359
  e[8] = e[13][97]  -- GETTABLE/CLOSURE? [a=13 b=0 c=8 d=nil]  -- = 97
  e[12] = e[14][K(0)]  -- GETTABLE/CLOSURE? [a=14 b=0 c=12 d=nil]
  call(e[13], e[0])  -- CALL [a=13 b=0 c=0 d=nil] -- void call
  ::L_615::
  goto L_178
  e[39] = e[35][K(0)]  -- GETTABLE/CLOSURE? [a=35 b=0 c=39 d=nil]
  e[40] = e[31][K(0)]  -- GETTABLE/CLOSURE? [a=31 b=0 c=40 d=nil]
  e[41] = e[34][K(0)]  -- GETTABLE/CLOSURE? [a=34 b=0 c=41 d=nil]
  ::L_619::
  goto L_266
  e[50] = e[51][K(0)]  -- GETTABLE/CLOSURE? [a=51 b=0 c=50 d=nil]
  e[49] = e[52][K(0)]  -- GETTABLE/CLOSURE? [a=52 b=0 c=49 d=nil]
  e[47] = e[53][K(0)]  -- GETTABLE/CLOSURE? [a=53 b=0 c=47 d=nil]
  ::L_623::
  goto L_630
  e[61] = e[11][K(0)]  -- GETTABLE/CLOSURE? [a=11 b=0 c=61 d=nil]
  e[62] = e[8][110]  -- GETTABLE/CLOSURE? [a=8 b=0 c=62 d=nil]  -- = 110
  e[53] = K(53)  -- LOADK_N [a=0 b=53 c=10 d=nil]
  e[8] = e[53][116]  -- GETTABLE/CLOSURE? [a=53 b=0 c=8 d=nil]  -- = 116
  call(e[53], e[0])  -- CALL [a=53 b=0 c=0 d=nil] -- void call
  goto L_629
  ::L_630::
  goto L_661
  e[8] = e[54][120]  -- GETTABLE/CLOSURE? [a=54 b=0 c=8 d=nil]  -- = 120
  e[48] = e[55][K(0)]  -- GETTABLE/CLOSURE? [a=55 b=0 c=48 d=nil]
  e[1] = e[51]  -- MOVE [a=51 b=1 c=1151 d=nil]
  e[53] = e[2][K(0)]  -- GETTABLE/CLOSURE? [a=2 b=0 c=53 d=nil]
  e[54] = e[50][K(0)]  -- GETTABLE/CLOSURE? [a=50 b=0 c=54 d=nil]
  e[55] = e[49][K(0)]  -- GETTABLE/CLOSURE? [a=49 b=0 c=55 d=nil]
  e[56] = e[32][K(0)]  -- GETTABLE/CLOSURE? [a=32 b=0 c=56 d=nil]
  ::L_638::
  goto L_423
  e[16] = e[22][K(0)]  -- GETTABLE/CLOSURE? [a=22 b=0 c=16 d=nil]
  e[15] = e[23][K(0)]  -- GETTABLE/CLOSURE? [a=23 b=0 c=15 d=nil]
  e[8] = e[24][96]  -- GETTABLE/CLOSURE? [a=24 b=0 c=8 d=nil]  -- = 96
  call(e[21], e[19])  -- CALL? [a=21 b=0 c=19 d=nil] -- void call
  e[1] = e[22]  -- MOVE [a=22 b=1 c=2182 d=nil]
  e[24] = e[19][K(0)]  -- GETTABLE/CLOSURE? [a=19 b=0 c=24 d=nil]
  ::L_645::
  goto L_58
  e[35] = e[38][K(0)]  -- GETTABLE/CLOSURE? [a=38 b=0 c=35 d=nil]
  e[34] = e[39][K(0)]  -- GETTABLE/CLOSURE? [a=39 b=0 c=34 d=nil]
  e[33] = e[40][K(0)]  -- GETTABLE/CLOSURE? [a=40 b=0 c=33 d=nil]
  e[30] = e[41][K(0)]  -- GETTABLE/CLOSURE? [a=41 b=0 c=30 d=nil]
  e[32] = e[42][K(0)]  -- GETTABLE/CLOSURE? [a=42 b=0 c=32 d=nil]
  call(e[38], e[36])  -- CALL? [a=38 b=0 c=36 d=nil] -- void call
  e[1] = e[39]  -- MOVE [a=39 b=1 c=293 d=nil]
  e[41] = e[36][K(0)]  -- GETTABLE/CLOSURE? [a=36 b=0 c=41 d=nil]
  e[42] = e[2][K(0)]  -- GETTABLE/CLOSURE? [a=2 b=0 c=42 d=nil]
  e[43] = e[37][K(0)]  -- GETTABLE/CLOSURE? [a=37 b=0 c=43 d=nil]
  ::L_656::
  goto L_149
  e[20] = e[27][K(0)]  -- GETTABLE/CLOSURE? [a=27 b=0 c=20 d=nil]
  e[25][K(62)] = e[22]  -- SETTABLE/CALL [a=25 b=62 c=22 d=nil] -- settable/void-call (inferred)
  e[1] = e[26]  -- MOVE [a=26 b=1 c=1310 d=nil]
  e[28] = e[25][K(0)]  -- GETTABLE/CLOSURE? [a=25 b=0 c=28 d=nil]
  ::L_661::
  goto L_719
  e[91] = {}  -- NEWTABLE [a=91 b=0 c=0 d=nil]
  e[91][K(924)] = e[4]  -- SETTABLE [a=91 b=924 c=4 d=688] -- settable/void-call (inferred)
  e[91][K(2286)] = e[2332]  -- SETTABLE [a=91 b=2286 c=2332 d=630] -- settable/void-call (inferred)
  call(e[96], e[89])  -- CALL? [a=96 b=0 c=89 d=nil] -- void call
  ::L_666::
  goto L_666
  ::L_668::
  goto L_262
  call(e[50], e[47])  -- CALL? [a=50 b=0 c=47 d=nil] -- void call
  e[194] = e[51]  -- MOVE [a=51 b=194 c=2400 d=nil]
  e[245][K(158)] = e[53]  -- SETTABLE/CALL [a=245 b=158 c=53 d=nil] -- settable/void-call (inferred)
  call(e[50], e[51])  -- CALL [a=50 b=180 c=51 d=nil] -- void call
  e[41] = K(227)  -- LOADK_S [a=41 b=227 c=148 d=nil]
  ::L_674::
  goto L_514
  e[20] = e[16][K(0)]  -- GETTABLE/CLOSURE? [a=16 b=0 c=20 d=nil]
  e[21] = e[15][K(0)]  -- GETTABLE/CLOSURE? [a=15 b=0 c=21 d=nil]
  e[22] = e[2][K(0)]  -- GETTABLE/CLOSURE? [a=2 b=0 c=22 d=nil]
  if e[17] then goto L_6 end  -- back-edge (loop)
  e[14] = e[17][K(0)]  -- GETTABLE/CLOSURE? [a=17 b=0 c=14 d=nil]
  ::L_680::
  goto L_258
  call(e[54], e[0])  -- CALL [a=54 b=0 c=0 d=nil] -- void call
  e[1] = e[55]  -- MOVE [a=55 b=1 c=137 d=nil]
  e[57] = e[54][K(0)]  -- GETTABLE/CLOSURE? [a=54 b=0 c=57 d=nil]
  goto L_684
  e[77] = {}  -- NEWTABLE [a=77 b=0 c=0 d=nil]
  e[83] = K(16)  -- LOADK_S [a=0 b=16 c=83 d=nil]
  e[84] = -45  -- LOADK_N [a=695 b=84 c=1947 d=nil]
  e[83] = 4294967251  -- LOADK_N [a=0 b=25 c=83 d=nil]
  e[83] = e[83] + -4294958618  -- ADD [a=83 b=808 c=83 d=-4294958618]  -- = 8633
  e[83] = arith(e[83], e[2154])  -- UNOP/arith? [a=83 b=83 c=2154 d=nil]  -- = 1
  call(e[83], e[2347])  -- CALL [a=83 b=77 c=2347 d=nil] -- void call
  e[77][K(987)] = e[2010]  -- SETTABLE [a=77 b=987 c=2010 d=667] -- settable/void-call (inferred)
  call(e[88], e[75])  -- CALL? [a=88 b=0 c=75 d=nil] -- void call
  ::L_694::
  goto L_159
  e[26] = e[37][K(0)]  -- GETTABLE/CLOSURE? [a=37 b=0 c=26 d=nil]
  e[27] = e[38][K(0)]  -- GETTABLE/CLOSURE? [a=38 b=0 c=27 d=nil]
  call(e[35], e[32])  -- CALL? [a=35 b=0 c=32 d=nil] -- void call
  e[1] = e[36]  -- MOVE [a=36 b=1 c=1541 d=nil]
  e[38] = e[2][K(0)]  -- GETTABLE/CLOSURE? [a=2 b=0 c=38 d=nil]
  ::L_700::
  goto L_615
  e[49] = e[8][93]  -- GETTABLE/CLOSURE? [a=8 b=0 c=49 d=nil]  -- = 93
  e[50] = e[46][K(0)]  -- GETTABLE/CLOSURE? [a=46 b=0 c=50 d=nil]
  e[51] = e[44][K(0)]  -- GETTABLE/CLOSURE? [a=44 b=0 c=51 d=nil]
  e[52] = e[45][K(0)]  -- GETTABLE/CLOSURE? [a=45 b=0 c=52 d=nil]
  ::L_705::
  goto L_44
  e[64] = e[59][K(0)]  -- GETTABLE/CLOSURE? [a=59 b=0 c=64 d=nil]
  e[61] = K(61)  -- LOADK_N [a=0 b=61 c=4 d=nil]
  ::L_708::
  do return end  -- JMP/RETURN [a=0 b=0 c=61 d=nil]
  ::L_709::
  goto L_498
  e[68] = e[31][K(0)]  -- GETTABLE/CLOSURE? [a=31 b=0 c=68 d=nil]
  e[69] = e[8][K(0)]  -- GETTABLE/CLOSURE? [a=8 b=0 c=69 d=nil]
  e[70] = e[14][K(0)]  -- GETTABLE/CLOSURE? [a=14 b=0 c=70 d=nil]
  ::L_713::
  goto L_143
  e[91] = {}  -- NEWTABLE [a=91 b=0 c=0 d=nil]
  e[90] = {}  -- NEWTABLE [a=90 b=0 c=0 d=nil]
  e[90][K(462)] = e[37]  -- SETTABLE [a=90 b=462 c=37 d=248] -- settable/void-call (inferred)
  e[91][K(729)] = e[1017]  -- SETTABLE [a=91 b=729 c=1017 d=444] -- settable/void-call (inferred)
  call(e[96], e[89])  -- CALL? [a=96 b=0 c=89 d=nil] -- void call
  ::L_719::
  goto L_307
  e[29] = e[23][K(0)]  -- GETTABLE/CLOSURE? [a=23 b=0 c=29 d=nil]
  e[30] = e[19][K(0)]  -- GETTABLE/CLOSURE? [a=19 b=0 c=30 d=nil]
  e[31] = e[7][K(0)]  -- GETTABLE/CLOSURE? [a=7 b=0 c=31 d=nil]
  ::L_723::
  goto L_246
  ::L_724::
  goto L_595
  e[64] = e[60][K(0)]  -- GETTABLE/CLOSURE? [a=60 b=0 c=64 d=nil]
  e[65] = e[56][K(0)]  -- GETTABLE/CLOSURE? [a=56 b=0 c=65 d=nil]
  e[66] = e[2][K(0)]  -- GETTABLE/CLOSURE? [a=2 b=0 c=66 d=nil]
  e[67] = e[57][K(0)]  -- GETTABLE/CLOSURE? [a=57 b=0 c=67 d=nil]
  e[68] = e[8][K(0)]  -- GETTABLE/CLOSURE? [a=8 b=0 c=68 d=nil]
  goto L_72
end

local function proto3(...)  -- 63 instrs, 12 blocks (structured)
  local e = regs
  ::L_1::
  ::L_34::
  ::L_12::
  goto L_1
  e[22] = {}  -- NEWTABLE [a=22 b=0 c=0 d=nil]
  e[23] = {}  -- NEWTABLE [a=23 b=0 c=0 d=nil]
  e[24] = {}  -- NEWTABLE [a=0 b=24 c=0 d=nil]
  ::L_5::
  e[25] = {}  -- NEWTABLE [a=25 b=0 c=0 d=nil]
  e[25][K(51)] = e[8]  -- SETTABLE [a=25 b=51 c=8 d=44] -- settable/void-call (inferred)
  e[24][K(40)] = e[4]  -- SETTABLE [a=24 b=40 c=4 d=47] -- settable/void-call (inferred)
  e[25][K(40)] = e[48]  -- SETTABLE [a=25 b=40 c=48 d=47] -- settable/void-call (inferred)
  e[22][K(125)] = e[4]  -- SETTABLE [a=22 b=125 c=4 d=43] -- settable/void-call (inferred)
  e[23][K(60)] = e[60]  -- SETTABLE [a=23 b=60 c=60 d=35] -- settable/void-call (inferred)
  e[28][K(180)] = e[21]  -- SETTABLE/CALL [a=28 b=180 c=21 d=nil] -- settable/void-call (inferred)
  goto L_12
  e[45] = e[215][K(149)]  -- GETTABLE/CLOSURE? [a=215 b=149 c=45 d=nil]
  e[6] = e[4][K(0)]  -- GETTABLE/CLOSURE? [a=4 b=0 c=6 d=nil]
  goto L_5
  ::L_16::
  -- UNKNOWN op? [a=444 b=209 c=415 d=nil]
  e[22] = {}  -- NEWTABLE [a=22 b=0 c=0 d=nil]
  e[24] = {}  -- NEWTABLE [a=0 b=24 c=0 d=nil]
  e[23] = {}  -- NEWTABLE [a=23 b=0 c=0 d=nil]
  e[22][K(118)] = e[99]  -- SETTABLE [a=22 b=118 c=99 d=13] -- settable/void-call (inferred)
  e[24][K(118)] = e[93]  -- SETTABLE [a=24 b=118 c=93 d=13] -- settable/void-call (inferred)
  e[23][K(118)] = e[4]  -- SETTABLE [a=23 b=118 c=4 d=13] -- settable/void-call (inferred)
  e[23][K(55)] = e[55]  -- SETTABLE [a=23 b=55 c=55 d=37] -- settable/void-call (inferred)
  call(e[28], e[21])  -- CALL? [a=28 b=0 c=21 d=nil] -- void call
  goto L_37
  e[0] = {}  -- NEWTABLE [a=0 b=4 c=0 d=nil]
  call(e[4], e[11])  -- CALL [a=4 b=30 c=11 d=nil] -- void call
  e[198][K(1)] = e[185]  -- SETTABLE/CALL [a=198 b=1 c=185 d=nil] -- settable/void-call (inferred)
  e[249][K(137)] = e[107]  -- SETTABLE/CALL [a=249 b=137 c=107 d=nil] -- settable/void-call (inferred)
  e[82] = K(86)  -- LOADK_S [a=82 b=86 c=177 d=nil]
  e[2] = e[2][K(1)]  -- GETTABLE [a=2 b=1 c=65 d=nil]
  e[5] = e[5][K(1)]  -- GETTABLE [a=5 b=1 c=78 d=nil]
  call(e[5], e[107])  -- CALL [a=5 b=3 c=107 d=nil] -- void call
  goto L_34
  ::L_36::
  goto L_38
  ::L_37::
  goto L_16
  ::L_38::
  -- UNKNOWN op? [a=0 b=25 c=0 d=nil]
  e[12] = {}  -- NEWTABLE [a=12 b=0 c=0 d=nil]
  e[10] = {}  -- NEWTABLE [a=10 b=0 c=0 d=nil]
  e[16] = K(11)  -- LOADK_S [a=0 b=11 c=16 d=nil]
  e[17] = K(8)  -- LOADK_S [a=0 b=8 c=17 d=nil]
  e[18] = ">i8"  -- LOADK [a=18 b=6 c=112 d=>i8]
  -- UNKNOWN op? [a=19 b=801 c=0 d=       �]
  e[17] = 228  -- LOADK_N [a=0 b=17 c=0 d=nil]
  e[18] = 432  -- LOADK [a=18 b=1804 c=0 d=432]
  -- UNKNOWN op? [a=43 b=16 c=0 d=nil]
  e[17] = K(9)  -- LOADK_S [a=0 b=9 c=17 d=nil]
  call(e[171], e[161])  -- CALL [a=171 b=250 c=161 d=nil] -- void call
  e[18][K(1964)] = e[230]  -- SETTABLE/CALL [a=18 b=1964 c=230 d==f��] -- settable/void-call (inferred)
  e[58] = K(206)  -- LOADK_S [a=58 b=206 c=196 d=nil]
  call(e[198], e[173])  -- CALL [a=198 b=123 c=173 d=nil] -- void call
  e[19][K(65)] = e[165]  -- SETTABLE/CALL [a=19 b=65 c=165 d=2] -- settable/void-call (inferred)
  e[20] = K(101)  -- LOADK_S [a=20 b=101 c=46 d=nil]
  call(e[20], e[0])  -- CALL [a=20 b=0 c=0 d=nil] -- void call
  e[17] = 102  -- LOADK_N [a=0 b=17 c=4 d=nil]
  e[16] = arith(e[16], e[17])  -- ARITH [a=16 b=16 c=17 d=nil]  -- = 262
  e[16] = e[16] + 29065  -- ADD [a=16 b=2325 c=16 d=29065]  -- = 29327
  e[16] = arith(e[16], e[1002])  -- UNOP/arith? [a=16 b=16 c=1002 d=nil]  -- = 286
  call(e[16], e[1])  -- CALL [a=16 b=12 c=1 d=nil] -- void call
  e[10][K(106)] = e[55]  -- SETTABLE [a=10 b=106 c=55 d=36] -- settable/void-call (inferred)
  call(e[20], e[8])  -- CALL? [a=20 b=0 c=8 d=nil] -- void call
  goto L_36
end

local function proto4(...)  -- 68 instrs, 30 blocks (structured)
  local e = regs
  ::L_1::
  ::L_12::
  ::L_59::
  goto L_1
  if e[109] then goto L_42 end
  ::L_3::
  goto L_53
  e[0] = {}  -- NEWTABLE [a=0 b=6 c=0 d=nil]
  ::L_5::
  e[2] = e[2][K(1)]  -- GETTABLE [a=2 b=1 c=70 d=nil]
  e[4] = e[4][K(1)]  -- GETTABLE [a=4 b=1 c=18 d=nil]
  ::L_7::
  goto L_54
  e[1] = e[7]  -- MOVE [a=7 b=1 c=338 d=nil]
  e[9] = e[4][K(0)]  -- GETTABLE/CLOSURE? [a=4 b=0 c=9 d=nil]
  e[10] = e[6][70]  -- GETTABLE/CLOSURE? [a=6 b=0 c=10 d=nil]  -- = 70
  e[12] = e[3][K(0)]  -- GETTABLE/CLOSURE? [a=3 b=0 c=12 d=nil]
  goto L_12
  ::L_13::
  goto L_3
  e[5] = e[5][K(1)]  -- GETTABLE [a=5 b=1 c=319 d=nil]
  -- UNKNOWN op? [a=6 b=0 c=7 d=nil]
  e[8] = e[244][K(0)]  -- GETTABLE/CLOSURE? [a=244 b=0 c=8 d=nil]
  e[9] = e[4][K(144)]  -- GETTABLE/CLOSURE? [a=4 b=144 c=9 d=nil]
  e[10] = e[2][K(0)]  -- GETTABLE/CLOSURE? [a=2 b=0 c=10 d=nil]
  ::L_19::
  do return end  -- JMP/RETURN [a=5 b=237 c=0 d=nil]
  e[14] = {}  -- NEWTABLE [a=14 b=0 c=0 d=nil]
  e[13] = {}  -- NEWTABLE [a=13 b=0 c=0 d=nil]
  e[20] = K(12)  -- LOADK_S [a=0 b=12 c=20 d=nil]
  e[21] = K(17)  -- LOADK_S [a=0 b=17 c=21 d=nil]
  e[22] = 171  -- LOADK [a=22 b=222 c=15 d=171]
  e[21] = 0  -- LOADK_N [a=155 b=0 c=21 d=nil]
  e[163] = 32  -- LOADK_N [a=0 b=0 c=163 d=nil]
  e[20] = e[20] + 3450  -- ADD [a=20 b=565 c=20 d=3450]  -- = 3482
  e[20] = arith(e[20], e[1650])  -- UNOP/arith? [a=20 b=20 c=1650 d=nil]  -- = 11
  call(e[20], e[103])  -- CALL [a=20 b=13 c=103 d=nil] -- void call
  e[14][K(98)] = e[81]  -- SETTABLE [a=14 b=98 c=81 d=64] -- settable/void-call (inferred)
  call(e[22], e[12])  -- CALL? [a=22 b=0 c=12 d=nil] -- void call
  ::L_32::
  goto L_7
  e[25] = {}  -- NEWTABLE [a=25 b=0 c=0 d=nil]
  e[27] = {}  -- NEWTABLE [a=27 b=0 c=0 d=nil]
  e[26] = {}  -- NEWTABLE [a=0 b=26 c=0 d=nil]
  e[27][K(22)] = e[112]  -- SETTABLE [a=27 b=22 c=112 d=15] -- settable/void-call (inferred)
  e[26][K(108)] = e[99]  -- SETTABLE [a=26 b=108 c=99 d=16] -- settable/void-call (inferred)
  e[25][K(117)] = e[81]  -- SETTABLE [a=25 b=117 c=81 d=19] -- settable/void-call (inferred)
  e[25][K(20)] = e[4]  -- SETTABLE [a=25 b=20 c=4 d=17] -- settable/void-call (inferred)
  e[25][K(5)] = e[118]  -- SETTABLE [a=25 b=5 c=118 d=65] -- settable/void-call (inferred)
  e[30][K(213)] = e[23]  -- SETTABLE/CALL [a=30 b=213 c=23 d=nil] -- settable/void-call (inferred)
  ::L_42::
  goto L_13
  if e[1] then do return end else goto L_44 end
  ::L_44::
  goto L_64
  e[24] = {}  -- NEWTABLE [a=24 b=0 c=0 d=nil]
  e[25] = {}  -- NEWTABLE [a=25 b=0 c=0 d=nil]
  e[26] = {}  -- NEWTABLE [a=0 b=26 c=0 d=nil]
  e[24][K(124)] = e[4]  -- SETTABLE [a=24 b=124 c=4 d=24] -- settable/void-call (inferred)
  e[26][K(104)] = e[4]  -- SETTABLE [a=26 b=104 c=4 d=25] -- settable/void-call (inferred)
  e[24][K(19)] = e[110]  -- SETTABLE [a=24 b=19 c=110 d=26] -- settable/void-call (inferred)
  e[25][K(27)] = e[34]  -- SETTABLE [a=25 b=27 c=34 d=66] -- settable/void-call (inferred)
  e[30][K(145)] = e[23]  -- SETTABLE/CALL [a=30 b=145 c=23 d=nil] -- settable/void-call (inferred)
  ::L_53::
  goto L_63
  ::L_54::
  goto L_65
  e[7] = e[7][K(1)]  -- GETTABLE [a=7 b=1 c=18 d=nil]
  call(e[7], e[65])  -- CALL [a=7 b=3 c=65 d=nil] -- void call
  e[5] = e[5][K(1)]  -- GETTABLE [a=5 b=1 c=18 d=nil]
  e[6] = 70  -- LOADK [a=6 b=1503 c=0 d=70]
  goto L_59
  if e[7] then goto L_5 end  -- back-edge (loop)
  e[4] = e[7][K(0)]  -- GETTABLE/CLOSURE? [a=7 b=0 c=4 d=nil]
  e[6] = e[8][109]  -- GETTABLE/CLOSURE? [a=8 b=0 c=6 d=nil]  -- = 109
  ::L_63::
  goto L_66
  ::L_64::
  goto L_19
  ::L_65::
  goto L_32
  ::L_66::
  goto L_44
  goto L_1
  -- UNKNOWN op? [a=358 b=269 c=244 d=nil]
end

local function proto5(...)  -- 81 instrs, 34 blocks (structured)
  local e = regs
  ::L_1::
  ::L_54::
  ::L_21::
  ::L_48::
  ::L_67::
  ::L_29::
  ::L_37::
  ::L_62::
  ::L_39::
  ::L_79::
  ::L_20::
  goto L_1
  e[22] = {}  -- NEWTABLE [a=22 b=0 c=0 d=nil]
  e[24] = {}  -- NEWTABLE [a=24 b=0 c=0 d=nil]
  ::L_5::
  e[23] = {}  -- NEWTABLE [a=0 b=23 c=0 d=nil]
  e[24][K(53)] = e[8]  -- SETTABLE [a=24 b=53 c=8 d=50] -- settable/void-call (inferred)
  e[23][K(53)] = e[20]  -- SETTABLE [a=23 b=53 c=20 d=50] -- settable/void-call (inferred)
  e[22][K(122)] = e[103]  -- SETTABLE [a=22 b=122 c=103 d=21] -- settable/void-call (inferred)
  e[27][K(180)] = e[20]  -- SETTABLE/CALL [a=27 b=180 c=20 d=nil] -- settable/void-call (inferred)
  -- UNKNOWN op? [a=403 b=474 c=14 d=nil]
  e[12] = {}  -- NEWTABLE [a=12 b=0 c=0 d=nil]
  e[10] = {}  -- NEWTABLE [a=10 b=0 c=0 d=nil]
  e[16] = K(16)  -- LOADK_S [a=0 b=16 c=16 d=nil]
  e[17] = 365  -- LOADK [a=17 b=1708 c=0 d=365]
  e[18] = 322  -- LOADK [a=18 b=1859 c=0 d=322]
  e[16] = 47  -- LOADK_N [a=0 b=16 c=0 d=nil]
  e[16] = (e[16] == e[16])  -- COMPARE [a=16 b=338 c=16 d=193]  -- = true
  if e[16] then goto L_21 else goto L_20 end  -- back-edge (loop)
  e[22] = {}  -- NEWTABLE [a=22 b=0 c=0 d=nil]
  e[24] = {}  -- NEWTABLE [a=24 b=0 c=0 d=nil]
  e[24][K(47)] = e[87]  -- SETTABLE [a=24 b=47 c=87 d=57] -- settable/void-call (inferred)
  e[22][K(119)] = e[55]  -- SETTABLE [a=22 b=119 c=55 d=22] -- settable/void-call (inferred)
  e[27][K(16)] = e[20]  -- SETTABLE/CALL [a=27 b=16 c=20 d=nil] -- settable/void-call (inferred)
  goto L_29
  e[22] = {}  -- NEWTABLE [a=22 b=0 c=0 d=nil]
  e[23] = {}  -- NEWTABLE [a=0 b=23 c=0 d=nil]
  e[24] = {}  -- NEWTABLE [a=24 b=0 c=0 d=nil]
  e[24][K(5)] = e[41]  -- SETTABLE [a=24 b=5 c=41 d=65] -- settable/void-call (inferred)
  e[23][K(5)] = e[93]  -- SETTABLE [a=23 b=5 c=93 d=65] -- settable/void-call (inferred)
  e[22][K(38)] = e[91]  -- SETTABLE [a=22 b=38 c=91 d=55] -- settable/void-call (inferred)
  call(e[27], e[20])  -- CALL? [a=27 b=0 c=20 d=nil] -- void call
  goto L_37
  if e[16] then goto L_56 else goto L_39 end
  ::L_40::
  goto L_40
  e[23] = {}  -- NEWTABLE [a=0 b=23 c=0 d=nil]
  e[22] = {}  -- NEWTABLE [a=22 b=0 c=0 d=nil]
  e[24] = {}  -- NEWTABLE [a=24 b=0 c=0 d=nil]
  e[23][K(56)] = e[111]  -- SETTABLE [a=23 b=56 c=111 d=69] -- settable/void-call (inferred)
  e[24][K(56)] = e[8]  -- SETTABLE [a=24 b=56 c=8 d=69] -- settable/void-call (inferred)
  e[22][K(89)] = e[13]  -- SETTABLE [a=22 b=89 c=13 d=40] -- settable/void-call (inferred)
  e[27][K(2)] = e[20]  -- SETTABLE/CALL [a=27 b=2 c=20 d=nil] -- settable/void-call (inferred)
  goto L_48
  e[16] = K(9)  -- LOADK_S [a=0 b=9 c=16 d=nil]
  dataop(e[164], e[1587], e[0])  -- DATAOP [a=164 b=1587 c=0 d=@�]  -- = "021@132"
  e[18] = 1  -- LOADK [a=18 b=107 c=0 d=1]
  call(e[19], e[0])  -- CALL [a=19 b=0 c=0 d=nil] -- void call
  e[16] = 21  -- LOADK_N [a=0 b=16 c=4 d=nil]
  goto L_54
  ::L_56::
  e[16] = K(190)  -- LOADK [a=16 b=190 c=0 d=331]
  -- UNKNOWN op? [a=16 b=2009 c=16 d=32690]
  e[16] = arith(e[16], e[2008])  -- UNOP/arith? [a=16 b=16 c=2008 d=nil]  -- = 50
  call(e[16], e[45])  -- CALL [a=16 b=12 c=45 d=nil] -- void call
  e[10][K(73)] = e[13]  -- SETTABLE [a=10 b=73 c=13 d=23] -- settable/void-call (inferred)
  e[19][K(165)] = e[8]  -- SETTABLE/CALL [a=19 b=165 c=8 d=nil] -- settable/void-call (inferred)
  goto L_62
  ::L_63::
  goto L_63
  e[0] = {}  -- NEWTABLE [a=0 b=4 c=0 d=nil]
  -- UNKNOWN op? [a=198 b=1 c=26 d=nil]
  e[5] = {}  -- NEWTABLE [a=0 b=0 c=5 d=nil]
  goto L_67
  -- UNKNOWN op? [a=5 b=4 c=65 d=nil]
  e[199] = 109  -- LOADK [a=199 b=285 c=0 d=109]
  e[5] = e[2][K(0)]  -- GETTABLE/CLOSURE? [a=2 b=0 c=5 d=nil]
  ::L_71::
  goto L_71
  e[6] = e[3][109]  -- GETTABLE/CLOSURE? [a=3 b=0 c=6 d=nil]  -- = 109
  ::L_73::
  goto L_5
  e[22] = {}  -- NEWTABLE [a=22 b=0 c=0 d=nil]
  e[23] = {}  -- NEWTABLE [a=0 b=23 c=0 d=nil]
  e[23][K(62)] = e[111]  -- SETTABLE [a=23 b=62 c=111 d=73] -- settable/void-call (inferred)
  e[22][K(120)] = e[119]  -- SETTABLE [a=22 b=120 c=119 d=81] -- settable/void-call (inferred)
  e[27][K(145)] = e[20]  -- SETTABLE/CALL [a=27 b=145 c=20 d=nil] -- settable/void-call (inferred)
  goto L_79
  goto L_73
end

local function proto6(...)  -- 100 instrs, 41 blocks (structured)
  local e = regs
  ::L_3::
  ::L_79::
  ::L_68::
  ::L_8::
  e[4] = e[0][K(0)]  -- GETTABLE/CLOSURE? [a=0 b=0 c=4 d=nil]
  e[5] = 126  -- LOADK [a=5 b=2021 c=0 d=126]
  ::L_10::
  ::L_47::
  ::L_36::
  ::L_45::
  ::L_93::
  ::L_63::
  ::L_30::
  ::L_89::
  ::L_75::
  ::L_57::
  goto L_10
  ::L_2::
  -- UNKNOWN op? [a=469 b=155 c=250 d=nil]
  goto L_3
  e[0] = {}  -- NEWTABLE [a=0 b=7 c=0 d=nil]
  e[2] = e[2][K(1)]  -- GETTABLE [a=2 b=1 c=1805 d=nil]
  e[8] = e[8][K(1)]  -- GETTABLE [a=8 b=1 c=18 d=nil]
  call(e[8], e[78])  -- CALL [a=8 b=7 c=78 d=nil] -- void call
  goto L_8
  e[15] = {}  -- NEWTABLE [a=15 b=0 c=0 d=nil]
  e[14] = {}  -- NEWTABLE [a=14 b=0 c=0 d=nil]
  e[21] = K(12)  -- LOADK_S [a=0 b=12 c=21 d=nil]
  e[22] = 295  -- LOADK [a=22 b=1710 c=127 d=295]
  -- UNKNOWN op? [a=0 b=254 c=138 d=nil]
  call(e[21], e[237])  -- CALL [a=21 b=214 c=237 d=nil] -- void call
  e[73][K(21)] = e[253]  -- SETTABLE/CALL [a=73 b=21 c=253 d=nil] -- settable/void-call (inferred)
  e[153] = arith(e[11], e[2122])  -- ARITH [a=153 b=11 c=2122 d=nil]
  e[21] = e[21] + 12235  -- ADD [a=21 b=1471 c=21 d=12235]  -- = 12023
  e[21] = arith(e[21], e[625])  -- UNOP/arith? [a=21 b=21 c=625 d=nil]  -- = 4
  call(e[21], e[91])  -- CALL [a=21 b=14 c=91 d=nil] -- void call
  e[15][K(111)] = e[57]  -- SETTABLE [a=15 b=111 c=57 d=3] -- settable/void-call (inferred)
  call(e[22], e[13])  -- CALL? [a=22 b=0 c=13 d=nil] -- void call
  ::L_24::
  goto L_77
  call(e[8], e[70])  -- CALL [a=8 b=7 c=70 d=nil] -- void call
  e[8] = e[8]["gmatch"]  -- GETTABLE [a=8 b=1 c=1828 d=nil]  -- = "gmatch"
  e[8] = e[8][K(3)]  -- GETTABLE/CLOSURE [a=8 b=3 c=8 d=nil]
  goto L_30
  e[25] = {}  -- NEWTABLE [a=25 b=0 c=0 d=nil]
  e[26] = {}  -- NEWTABLE [a=0 b=26 c=0 d=nil]
  e[26][K(19)] = e[4]  -- SETTABLE [a=26 b=19 c=4 d=26] -- settable/void-call (inferred)
  e[25][K(104)] = e[116]  -- SETTABLE [a=25 b=104 c=116 d=25] -- settable/void-call (inferred)
  call(e[30], e[23])  -- CALL? [a=30 b=0 c=23 d=nil] -- void call
  goto L_36
  e[249] = e[249]["isyieldable"]  -- GETTABLE [a=249 b=1 c=1353 d=nil]  -- = "isyieldable"
  e[6][K(210)] = e[182]  -- SETTABLE/CALL [a=6 b=210 c=182 d=nil] -- settable/void-call (inferred)
  e[253][K(2)] = e[225]  -- SETTABLE/CALL [a=253 b=2 c=225 d=nil] -- settable/void-call (inferred)
  e[151][K(205)] = e[8]  -- SETTABLE/CALL [a=151 b=205 c=8 d=nil] -- settable/void-call (inferred)
  e[247][K(164)] = e[76]  -- SETTABLE/CALL [a=247 b=164 c=76 d=nil] -- settable/void-call (inferred)
  e[60] = K(147)  -- LOADK_S [a=60 b=147 c=38 d=nil]
  e[8] = e[8][K(1)]  -- GETTABLE [a=8 b=1 c=1380 d=nil]
  goto L_45
  if e[2] then goto L_56 else goto L_47 end
  e[27] = {}  -- NEWTABLE [a=27 b=0 c=0 d=nil]
  e[24] = {}  -- NEWTABLE [a=24 b=0 c=0 d=nil]
  e[25] = {}  -- NEWTABLE [a=25 b=0 c=0 d=nil]
  e[25][K(22)] = e[4]  -- SETTABLE [a=25 b=22 c=4 d=15] -- settable/void-call (inferred)
  e[24][K(22)] = e[122]  -- SETTABLE [a=24 b=22 c=122 d=15] -- settable/void-call (inferred)
  e[27][K(22)] = e[96]  -- SETTABLE [a=27 b=22 c=96 d=15] -- settable/void-call (inferred)
  e[24][K(100)] = e[4]  -- SETTABLE [a=24 b=100 c=4 d=14] -- settable/void-call (inferred)
  e[25][K(58)] = e[42]  -- SETTABLE [a=25 b=58 c=42 d=80] -- settable/void-call (inferred)
  ::L_56::
  e[30][K(132)] = e[23]  -- SETTABLE/CALL [a=30 b=132 c=23 d=nil] -- settable/void-call (inferred)
  goto L_57
  ::L_58::
  goto L_2
  e[1] = e[8]  -- MOVE [a=8 b=1 c=327 d=nil]
  e[10] = e[4][K(0)]  -- GETTABLE/CLOSURE? [a=4 b=0 c=10 d=nil]
  e[8] = K(8)  -- LOADK_N [a=0 b=8 c=0 d=nil]
  e[123] = e[8][K(0)]  -- GETTABLE/CLOSURE? [a=8 b=0 c=123 d=nil]
  goto L_63
  e[10] = e[5][69]  -- GETTABLE/CLOSURE? [a=5 b=0 c=10 d=nil]  -- = 69
  e[147][K(126)] = e[11]  -- SETTABLE/CALL [a=147 b=126 c=11 d=nil] -- settable/void-call (inferred)
  call(e[6], e[41])  -- CALL [a=6 b=89 c=41 d=nil] -- void call
  e[241] = K(199)  -- LOADK_S [a=241 b=199 c=99 d=nil]
  goto L_68
  e[1] = (e[8] == e[138])  -- COMPARE [a=8 b=1 c=138 d=nil]
  e[10] = e[5][126]  -- GETTABLE/CLOSURE? [a=5 b=0 c=10 d=nil]  -- = 126
  e[11] = e[7][K(0)]  -- GETTABLE/CLOSURE? [a=7 b=0 c=11 d=nil]
  e[8] = K(8)  -- LOADK_N [a=0 b=8 c=4 d=nil]
  e[109] = e[8][69]  -- GETTABLE/CLOSURE? [a=8 b=0 c=109 d=nil]  -- = 69
  goto L_75
  ::L_77::
  goto L_81
  if e[581] then goto L_24 else goto L_79 end  -- back-edge (loop)
  ::L_81::
  goto L_2
  e[24] = {}  -- NEWTABLE [a=24 b=0 c=0 d=nil]
  e[27] = {}  -- NEWTABLE [a=27 b=0 c=0 d=nil]
  e[25] = {}  -- NEWTABLE [a=25 b=0 c=0 d=nil]
  e[27][K(92)] = e[94]  -- SETTABLE [a=27 b=92 c=94 d=70] -- settable/void-call (inferred)
  e[24][K(66)] = e[99]  -- SETTABLE [a=24 b=66 c=99 d=74] -- settable/void-call (inferred)
  e[25][K(57)] = e[56]  -- SETTABLE [a=25 b=57 c=56 d=77] -- settable/void-call (inferred)
  e[30][K(17)] = e[23]  -- SETTABLE/CALL [a=30 b=17 c=23 d=nil] -- settable/void-call (inferred)
  goto L_89
  call(e[189], e[18])  -- CALL [a=189 b=7 c=18 d=nil] -- void call
  e[8] = e[4][K(0)]  -- GETTABLE/CLOSURE? [a=4 b=0 c=8 d=nil]
  e[9] = e[2][K(0)]  -- GETTABLE/CLOSURE? [a=2 b=0 c=9 d=nil]
  goto L_93
  e[26] = {}  -- NEWTABLE [a=0 b=26 c=0 d=nil]
  e[25] = {}  -- NEWTABLE [a=25 b=0 c=0 d=nil]
  e[26][K(1)] = e[84]  -- SETTABLE [a=26 b=1 c=84 d=38] -- settable/void-call (inferred)
  e[26][K(21)] = e[84]  -- SETTABLE [a=26 b=21 c=84 d=90] -- settable/void-call (inferred)
  e[25][K(68)] = e[52]  -- SETTABLE [a=25 b=68 c=52 d=76] -- settable/void-call (inferred)
  e[30][K(24)] = e[23]  -- SETTABLE/CALL [a=30 b=24 c=23 d=nil] -- settable/void-call (inferred)
  goto L_58
end

local function proto7(...)  -- 129 instrs, 36 blocks (structured)
  local e = regs
  ::L_1::
  ::L_122::
  ::L_72::
  ::L_92::
  ::L_110::
  ::L_102::
  ::L_38::
  do return end  -- JMP/RETURN [a=0 b=0 c=4 d=nil]
  e[26] = 7  -- LOADK [a=26 b=81 c=0 d=7]
  -- UNKNOWN op? [a=27 b=3 c=118 d=12]
  call(e[67], e[81])  -- CALL [a=67 b=85 c=81 d=nil] -- void call
  e[28][K(118)] = e[144]  -- SETTABLE/CALL [a=28 b=118 c=144 d=13] -- settable/void-call (inferred)
  e[181] = K(241)  -- LOADK_S [a=181 b=241 c=25 d=nil]
  e[29] = 3  -- LOADK [a=29 b=111 c=0 d=3]
  e[30] = 8  -- LOADK [a=30 b=84 c=0 d=8]
  e[31] = 9  -- LOADK [a=31 b=88 c=0 d=9]
  e[32] = 14  -- LOADK [a=32 b=100 c=0 d=14]
  ::L_11::
  goto L_88
  e[41] = {}  -- NEWTABLE [a=0 b=41 c=0 d=nil]
  e[40] = {}  -- NEWTABLE [a=40 b=0 c=0 d=nil]
  e[46] = K(16)  -- LOADK_S [a=0 b=16 c=46 d=nil]
  -- UNKNOWN op? [a=47 b=832 c=0 d=415]
  e[48] = 162  -- LOADK [a=48 b=1658 c=166 d=162]
  e[49] = 221  -- LOADK [a=49 b=1991 c=0 d=221]
  e[46] = 480  -- LOADK_N [a=0 b=46 c=4 d=nil]
  e[47] = K(8)  -- LOADK_S [a=0 b=8 c=47 d=nil]
  e[48] = "<i8"  -- LOADK [a=48 b=77 c=47 d=<i8]
  call(e[95], e[228])  -- CALL [a=95 b=208 c=228 d=nil] -- void call
  e[49][K(1868)] = e[137]  -- SETTABLE/CALL [a=49 b=1868 c=137 d=�      ] -- settable/void-call (inferred)
  e[13] = K(40)  -- LOADK_S [a=13 b=40 c=137 d=nil]
  e[47] = 418  -- LOADK_N [a=0 b=47 c=0 d=nil]
  e[46] = arith(e[46], e[46])  -- ARITH [a=47 b=46 c=46 d=nil]  -- = 62
  e[152][K(833)] = e[46]  -- SETTABLE/CALL [a=152 b=833 c=46 d=23163] -- settable/void-call (inferred)
  e[46][K(64)] = e[213]  -- SETTABLE/CALL [a=46 b=64 c=213 d=nil] -- settable/void-call (inferred)
  e[18][K(20)] = e[22]  -- SETTABLE/CALL [a=18 b=20 c=22 d=nil] -- settable/void-call (inferred)
  e[127][K(39)] = e[140]  -- SETTABLE/CALL [a=127 b=39 c=140 d=nil] -- settable/void-call (inferred)
  e[247] = K(85)  -- LOADK_S [a=247 b=85 c=211 d=nil]
  e[46] = arith(e[46], e[1197])  -- UNOP/arith? [a=46 b=46 c=1197 d=nil]  -- = 14
  call(e[46], e[94])  -- CALL [a=46 b=41 c=94 d=nil] -- void call
  e[40][K(33)] = e[7]  -- SETTABLE [a=40 b=33 c=7 d=39] -- settable/void-call (inferred)
  call(e[49], e[38])  -- CALL? [a=49 b=0 c=38 d=nil] -- void call
  goto L_82
  ::L_36::
  e[439] = {}  -- NEWTABLE [a=439 b=17 c=494 d=nil]
  e[4] = e[2][69]  -- GETTABLE/CLOSURE? [a=2 b=0 c=4 d=nil]  -- = 69
  goto L_38
  ::L_39::
  goto L_11
  e[52] = {}  -- NEWTABLE [a=52 b=0 c=0 d=nil]
  e[53] = {}  -- NEWTABLE [a=0 b=53 c=0 d=nil]
  e[53][K(383)] = e[23]  -- SETTABLE [a=53 b=383 c=23 d=104] -- settable/void-call (inferred)
  e[52][K(2199)] = e[30]  -- SETTABLE [a=52 b=2199 c=30 d=88] -- settable/void-call (inferred)
  call(e[57], e[50])  -- CALL? [a=57 b=0 c=50 d=nil] -- void call
  ::L_45::
  goto L_63
  e[0] = {}  -- NEWTABLE [a=0 b=3 c=0 d=nil]
  e[4] = {}  -- NEWTABLE [a=32 b=4 c=0 d=nil]
  e[5] = 1  -- LOADK [a=5 b=16 c=0 d=1]
  ::L_50::
  goto L_45
  e[13] = 3  -- LOADK [a=13 b=111 c=0 d=3]
  e[57] = 7  -- LOADK [a=57 b=81 c=0 d=7]
  e[15] = 11  -- LOADK [a=15 b=103 c=217 d=11]
  -- UNKNOWN op? [a=16 b=22 c=0 d=15]
  e[17] = 4  -- LOADK [a=17 b=9 c=0 d=4]
  e[69] = 8  -- LOADK [a=69 b=84 c=0 d=8]
  call(e[253], e[173])  -- CALL [a=253 b=101 c=173 d=nil] -- void call
  e[19][K(3)] = e[116]  -- SETTABLE/CALL [a=19 b=3 c=116 d=12] -- settable/void-call (inferred)
  e[222] = K(205)  -- LOADK_S [a=222 b=205 c=145 d=nil]
  e[20] = 16  -- LOADK [a=20 b=108 c=0 d=16]
  e[21] = 1  -- LOADK [a=21 b=16 c=0 d=1]
  e[22] = 6  -- LOADK [a=22 b=23 c=0 d=6]
  ::L_63::
  goto L_86
  e[54] = {}  -- NEWTABLE [a=54 b=0 c=0 d=nil]
  e[51] = {}  -- NEWTABLE [a=51 b=0 c=0 d=nil]
  e[52] = {}  -- NEWTABLE [a=52 b=0 c=0 d=nil]
  e[51][K(110)] = e[4]  -- SETTABLE [a=51 b=110 c=4 d=20] -- settable/void-call (inferred)
  e[54][K(22)] = e[8]  -- SETTABLE [a=54 b=22 c=8 d=15] -- settable/void-call (inferred)
  e[51][K(108)] = e[4]  -- SETTABLE [a=51 b=108 c=4 d=16] -- settable/void-call (inferred)
  e[52][K(30)] = e[39]  -- SETTABLE [a=52 b=30 c=39 d=46] -- settable/void-call (inferred)
  call(e[57], e[50])  -- CALL? [a=57 b=0 c=50 d=nil] -- void call
  goto L_72
  e[52] = {}  -- NEWTABLE [a=52 b=0 c=0 d=nil]
  e[51] = {}  -- NEWTABLE [a=51 b=0 c=0 d=nil]
  e[53] = {}  -- NEWTABLE [a=0 b=53 c=0 d=nil]
  e[54] = {}  -- NEWTABLE [a=54 b=0 c=0 d=nil]
  e[53][K(2361)] = e[73]  -- SETTABLE [a=53 b=2361 c=73 d=119] -- settable/void-call (inferred)
  e[51][K(111)] = e[4]  -- SETTABLE [a=51 b=111 c=4 d=3] -- settable/void-call (inferred)
  e[54][K(111)] = e[8]  -- SETTABLE [a=54 b=111 c=8 d=3] -- settable/void-call (inferred)
  e[52][K(46)] = e[1528]  -- SETTABLE [a=52 b=46 c=1528 d=87] -- settable/void-call (inferred)
  e[57][K(182)] = e[50]  -- SETTABLE/CALL [a=57 b=182 c=50 d=nil] -- settable/void-call (inferred)
  ::L_82::
  goto L_118
  e[10] = 6  -- LOADK [a=10 b=23 c=0 d=6]
  e[11] = 10  -- LOADK [a=11 b=42 c=0 d=10]
  e[12] = 14  -- LOADK [a=12 b=100 c=0 d=14]
  ::L_86::
  goto L_50
  ::L_88::
  goto L_39
  e[33] = 4  -- LOADK [a=33 b=9 c=0 d=4]
  e[121] = 5  -- LOADK [a=121 b=99 c=154 d=5]
  e[35] = 10  -- LOADK [a=35 b=42 c=0 d=10]
  goto L_92
  e[53] = {}  -- NEWTABLE [a=0 b=53 c=0 d=nil]
  e[51] = {}  -- NEWTABLE [a=51 b=0 c=0 d=nil]
  e[54] = {}  -- NEWTABLE [a=54 b=0 c=0 d=nil]
  e[52] = {}  -- NEWTABLE [a=52 b=0 c=0 d=nil]
  e[51][K(35)] = e[4]  -- SETTABLE [a=51 b=35 c=4 d=53] -- settable/void-call (inferred)
  e[54][K(69)] = e[8]  -- SETTABLE [a=54 b=69 c=8 d=54] -- settable/void-call (inferred)
  e[53][K(105)] = e[114]  -- SETTABLE [a=53 b=105 c=114 d=56] -- settable/void-call (inferred)
  e[52][K(39)] = e[1]  -- SETTABLE [a=52 b=39 c=1 d=103] -- settable/void-call (inferred)
  e[57][K(137)] = e[50]  -- SETTABLE/CALL [a=57 b=137 c=50 d=nil] -- settable/void-call (inferred)
  goto L_102
  e[91] = 5  -- LOADK [a=91 b=99 c=0 d=5]
  call(e[226], e[30])  -- CALL [a=226 b=179 c=30 d=nil] -- void call
  e[7][K(88)] = e[51]  -- SETTABLE/CALL [a=7 b=88 c=51 d=9] -- settable/void-call (inferred)
  e[43] = K(136)  -- LOADK_S [a=43 b=136 c=252 d=nil]
  e[8] = 13  -- LOADK [a=8 b=118 c=0 d=13]
  e[9] = 2  -- LOADK [a=9 b=93 c=0 d=2]
  goto L_110
  e[53] = {}  -- NEWTABLE [a=0 b=53 c=0 d=nil]
  e[52] = {}  -- NEWTABLE [a=52 b=0 c=0 d=nil]
  e[51] = {}  -- NEWTABLE [a=51 b=0 c=0 d=nil]
  e[53][K(21)] = e[126]  -- SETTABLE [a=53 b=21 c=126 d=90] -- settable/void-call (inferred)
  e[51][K(21)] = e[4]  -- SETTABLE [a=51 b=21 c=4 d=90] -- settable/void-call (inferred)
  e[52][K(1270)] = e[16]  -- SETTABLE [a=52 b=1270 c=16 d=124] -- settable/void-call (inferred)
  call(e[57], e[50])  -- CALL? [a=57 b=0 c=50 d=nil] -- void call
  ::L_118::
  goto L_1
  e[6] = 11  -- LOADK [a=6 b=103 c=0 d=11]
  e[24] = 16  -- LOADK [a=24 b=108 c=0 d=16]
  e[25] = 2  -- LOADK [a=25 b=93 c=0 d=2]
  goto L_122
  e[36] = 15  -- LOADK [a=36 b=22 c=0 d=15]
  e[4][K(0)] = e[32]  -- SETTABLE [a=4 b=0 c=32 d=nil] -- settable/void-call (inferred)
  call(e[4], e[78])  -- CALL [a=4 b=3 c=78 d=nil] -- void call
  e[2] = 69  -- LOADK [a=2 b=2305 c=0 d=69]
  goto L_36
end

local function proto8(...)  -- 7 instrs, 5 blocks (structured)
  local e = regs
  ::L_1::
  ::L_5::
  do return end  -- JMP/RETURN [a=0 b=0 c=3 d=nil]
  e[0] = {}  -- NEWTABLE [a=0 b=2 c=0 d=nil]
  e[2] = e[2][K(1)]  -- GETTABLE [a=2 b=1 c=113 d=nil]
  e[3] = e[2][K(0)]  -- GETTABLE/CLOSURE? [a=2 b=0 c=3 d=nil]
  goto L_5
  goto L_1
  e[297] = (e[494] == e[31])  -- COMPARE [a=494 b=297 c=31 d=nil]
end

local function proto9(...)  -- 105 instrs, 42 blocks (structured)
  local e = regs
  ::L_93::
  ::L_38::
  ::L_6::
  e[24] = {}  -- NEWTABLE [a=24 b=0 c=0 d=nil]
  e[24][K(106)] = e[23]  -- SETTABLE [a=24 b=106 c=23 d=36] -- settable/void-call (inferred)
  e[26][K(106)] = e[9]  -- SETTABLE [a=26 b=106 c=9 d=36] -- settable/void-call (inferred)
  e[25][K(27)] = e[60]  -- SETTABLE [a=25 b=27 c=60 d=66] -- settable/void-call (inferred)
  call(e[30], e[23])  -- CALL? [a=30 b=0 c=23 d=nil] -- void call
  ::L_11::
  ::L_35::
  ::L_89::
  ::L_50::
  ::L_98::
  ::L_64::
  goto L_11
  ::L_2::
  goto L_23
  ::L_3::
  goto L_14
  e[26] = {}  -- NEWTABLE [a=0 b=26 c=0 d=nil]
  e[25] = {}  -- NEWTABLE [a=25 b=0 c=0 d=nil]
  goto L_6
  goto L_66
  if e[1] then do return end else goto L_14 end
  ::L_14::
  goto L_2
  e[25] = {}  -- NEWTABLE [a=25 b=0 c=0 d=nil]
  e[25][K(36)] = e[99]  -- SETTABLE [a=25 b=36 c=99 d=100] -- settable/void-call (inferred)
  e[25][K(111)] = e[40]  -- SETTABLE [a=25 b=111 c=40 d=3] -- settable/void-call (inferred)
  call(e[30], e[23])  -- CALL? [a=30 b=0 c=23 d=nil] -- void call
  ::L_19::
  goto L_47
  e[136] = e[136][K(1)]  -- GETTABLE [a=136 b=1 c=18 d=nil]
  call(e[6], e[319])  -- CALL [a=6 b=5 c=319 d=nil] -- void call
  e[4] = 23  -- LOADK [a=4 b=90 c=0 d=23]
  ::L_23::
  goto L_91
  e[24] = {}  -- NEWTABLE [a=24 b=0 c=0 d=nil]
  e[25] = {}  -- NEWTABLE [a=25 b=0 c=0 d=nil]
  e[27] = {}  -- NEWTABLE [a=27 b=0 c=0 d=nil]
  e[24][K(126)] = e[9]  -- SETTABLE [a=24 b=126 c=9 d=34] -- settable/void-call (inferred)
  e[27][K(126)] = e[39]  -- SETTABLE [a=27 b=126 c=39 d=34] -- settable/void-call (inferred)
  e[25][K(93)] = e[37]  -- SETTABLE [a=25 b=93 c=37 d=2] -- settable/void-call (inferred)
  call(e[30], e[23])  -- CALL? [a=30 b=0 c=23 d=nil] -- void call
  ::L_31::
  goto L_33
  ::L_32::
  goto L_43
  ::L_33::
  goto L_91
  -- UNKNOWN op? [a=91 b=42 c=148 d=10]
  goto L_35
  e[217] = e[223][97]  -- GETTABLE/CLOSURE? [a=223 b=0 c=217 d=nil]  -- = 97
  e[7] = e[2][K(0)]  -- GETTABLE/CLOSURE? [a=2 b=0 c=7 d=nil]
  goto L_38
  e[0] = {}  -- NEWTABLE [a=0 b=5 c=0 d=nil]
  -- UNKNOWN op? [a=0 b=5 c=26 d=nil]
  e[2] = e[2][K(1)]  -- GETTABLE [a=2 b=1 c=18 d=nil]
  ::L_43::
  goto L_19
  e[6] = e[6]["format"]  -- GETTABLE [a=6 b=1 c=613 d=nil]  -- = "format"
  e[2] = e[2][K(3)]  -- GETTABLE/CLOSURE [a=2 b=3 c=6 d=nil]
  e[4] = 97  -- LOADK [a=4 b=1083 c=0 d=97]
  ::L_47::
  goto L_32
  e[6] = e[6][K(1)]  -- GETTABLE [a=6 b=1 c=2412 d=nil]
  call(e[6], e[319])  -- CALL [a=6 b=5 c=319 d=nil] -- void call
  goto L_50
  e[27] = {}  -- NEWTABLE [a=27 b=0 c=0 d=nil]
  e[24] = {}  -- NEWTABLE [a=24 b=0 c=0 d=nil]
  e[25] = {}  -- NEWTABLE [a=25 b=0 c=0 d=nil]
  e[26] = {}  -- NEWTABLE [a=0 b=26 c=0 d=nil]
  e[26][K(66)] = e[119]  -- SETTABLE [a=26 b=66 c=119 d=74] -- settable/void-call (inferred)
  e[25][K(66)] = e[4]  -- SETTABLE [a=25 b=66 c=4 d=74] -- settable/void-call (inferred)
  e[26][K(57)] = e[122]  -- SETTABLE [a=26 b=57 c=122 d=77] -- settable/void-call (inferred)
  e[24][K(57)] = e[4]  -- SETTABLE [a=24 b=57 c=4 d=77] -- settable/void-call (inferred)
  e[26][K(62)] = e[122]  -- SETTABLE [a=26 b=62 c=122 d=73] -- settable/void-call (inferred)
  e[24][K(62)] = e[4]  -- SETTABLE [a=24 b=62 c=4 d=73] -- settable/void-call (inferred)
  e[27][K(54)] = e[53]  -- SETTABLE [a=27 b=54 c=53 d=41] -- settable/void-call (inferred)
  e[25][K(33)] = e[103]  -- SETTABLE [a=25 b=33 c=103 d=39] -- settable/void-call (inferred)
  call(e[30], e[23])  -- CALL? [a=30 b=0 c=23 d=nil] -- void call
  goto L_64
  ::L_65::
  goto L_91
  ::L_66::
  goto L_3
  e[11] = {}  -- NEWTABLE [a=11 b=0 c=0 d=nil]
  e[12] = {}  -- NEWTABLE [a=0 b=12 c=0 d=nil]
  e[17] = K(16)  -- LOADK_S [a=0 b=16 c=17 d=nil]
  e[18] = K(11)  -- LOADK_S [a=0 b=11 c=18 d=nil]
  e[19] = K(9)  -- LOADK_S [a=0 b=9 c=19 d=nil]
  e[20] = "7197"  -- LOADK [a=20 b=487 c=0 d=7�]
  ::L_73::
  e[56] = 2  -- LOADK [a=56 b=65 c=49 d=2]
  call(e[177], e[0])  -- CALL [a=177 b=252 c=0 d=nil] -- void call
  e[19] = 197  -- LOADK_N [a=0 b=19 c=4 d=nil]
  e[20] = K(8)  -- LOADK_S [a=0 b=8 c=20 d=nil]
  e[172] = "<i8"  -- LOADK [a=172 b=77 c=23 d=<i8]
  e[22] = "c001000000000000000000"  -- LOADK [a=22 b=1955 c=0 d=c      ]
  e[20] = 355  -- LOADK_N [a=0 b=20 c=0 d=nil]
  e[21] = 272  -- LOADK [a=21 b=1548 c=0 d=272]
  e[18] = 0  -- LOADK_N [a=0 b=18 c=4 d=nil]
  e[19] = 366  -- LOADK [a=19 b=574 c=0 d=366]
  e[17] = 366  -- LOADK_N [a=0 b=17 c=0 d=nil]
  e[17] = e[17] + 16534  -- ADD [a=17 b=2242 c=17 d=16534]  -- = 16900
  e[17] = arith(e[17], e[721])  -- UNOP/arith? [a=17 b=17 c=721 d=nil]  -- = 6
  call(e[17], e[110])  -- CALL [a=17 b=12 c=110 d=nil] -- void call
  e[11][K(3)] = e[33]  -- SETTABLE [a=11 b=3 c=33 d=12] -- settable/void-call (inferred)
  call(e[22], e[9])  -- CALL? [a=22 b=0 c=9 d=nil] -- void call
  goto L_89
  goto L_31
  ::L_91::
  e[339] = (e[44] == e[33])  -- COMPARE [a=44 b=339 c=33 d=nil]
  if e[12] then goto L_73 else goto L_93 end  -- back-edge (loop)
  e[6] = e[6][K(1)]  -- GETTABLE [a=6 b=1 c=2280 d=nil]
  call(e[6], e[26])  -- CALL [a=6 b=5 c=26 d=nil] -- void call
  e[4] = 10  -- LOADK [a=4 b=1353 c=0 d=10]
  goto L_98
  e[6] = e[6][K(1)]  -- GETTABLE [a=6 b=1 c=18 d=nil]
  call(e[6], e[1805])  -- CALL [a=6 b=105 c=1805 d=nil] -- void call
  e[6] = e[6][K(1)]  -- GETTABLE [a=6 b=1 c=18 d=nil]
  call(e[6], e[113])  -- CALL [a=6 b=5 c=113 d=nil] -- void call
  e[6] = e[6][K(1)]  -- GETTABLE [a=6 b=1 c=18 d=nil]
  call(e[6], e[1353])  -- CALL [a=6 b=5 c=1353 d=nil] -- void call
  goto L_65
end

local function proto10(...)  -- 99 instrs, 42 blocks (structured)
  local e = regs
  ::L_1::
  -- UNKNOWN op? [a=139 b=57 c=161 d=nil]
  ::L_7::
  goto L_7
  ::L_2::
  goto L_48
  ::L_3::
  goto L_29
  ::L_4::
  goto L_41
  goto L_64
  e[27] = {}  -- NEWTABLE [a=27 b=0 c=0 d=nil]
  e[25] = {}  -- NEWTABLE [a=25 b=0 c=0 d=nil]
  e[27][K(932)] = e[1004]  -- SETTABLE [a=27 b=932 c=1004 d=96] -- settable/void-call (inferred)
  e[25][K(81)] = e[16]  -- SETTABLE [a=25 b=81 c=16 d=7] -- settable/void-call (inferred)
  call(e[30], e[23])  -- CALL? [a=30 b=0 c=23 d=nil] -- void call
  ::L_13::
  goto L_1
  e[2] = 25  -- LOADK [a=2 b=283 c=0 d=25]
  ::L_15::
  goto L_91
  -- UNKNOWN op? [a=6 b=0 c=8 d=nil]
  ::L_17::
  goto L_7
  ::L_18::
  goto L_85
  ::L_19::
  goto L_35
  e[27] = {}  -- NEWTABLE [a=27 b=0 c=0 d=nil]
  e[25] = {}  -- NEWTABLE [a=25 b=0 c=0 d=nil]
  e[26] = {}  -- NEWTABLE [a=0 b=26 c=0 d=nil]
  e[27][K(56)] = e[8]  -- SETTABLE [a=27 b=56 c=8 d=69] -- settable/void-call (inferred)
  e[26][K(56)] = e[122]  -- SETTABLE [a=26 b=56 c=122 d=69] -- settable/void-call (inferred)
  e[27][K(45)] = e[8]  -- SETTABLE [a=27 b=45 c=8 d=68] -- settable/void-call (inferred)
  e[26][K(45)] = e[110]  -- SETTABLE [a=26 b=45 c=110 d=68] -- settable/void-call (inferred)
  e[25][K(59)] = e[9]  -- SETTABLE [a=25 b=59 c=9 d=42] -- settable/void-call (inferred)
  call(e[30], e[23])  -- CALL? [a=30 b=0 c=23 d=nil] -- void call
  ::L_29::
  goto L_4
  e[25] = {}  -- NEWTABLE [a=25 b=0 c=0 d=nil]
  e[27] = {}  -- NEWTABLE [a=27 b=0 c=0 d=nil]
  e[27][K(64)] = e[79]  -- SETTABLE [a=27 b=64 c=79 d=85] -- settable/void-call (inferred)
  e[25][K(111)] = e[111]  -- SETTABLE [a=25 b=111 c=111 d=3] -- settable/void-call (inferred)
  call(e[30], e[23])  -- CALL? [a=30 b=0 c=23 d=nil] -- void call
  ::L_35::
  goto L_3
  e[27] = {}  -- NEWTABLE [a=27 b=0 c=0 d=nil]
  e[25] = {}  -- NEWTABLE [a=25 b=0 c=0 d=nil]
  e[27][K(108)] = e[112]  -- SETTABLE [a=27 b=108 c=112 d=16] -- settable/void-call (inferred)
  e[25][K(117)] = e[69]  -- SETTABLE [a=25 b=117 c=69 d=19] -- settable/void-call (inferred)
  call(e[30], e[23])  -- CALL? [a=30 b=0 c=23 d=nil] -- void call
  ::L_41::
  goto L_54
  ::L_42::
  goto L_19
  e[25] = {}  -- NEWTABLE [a=25 b=0 c=0 d=nil]
  e[26] = {}  -- NEWTABLE [a=0 b=26 c=0 d=nil]
  e[26][K(38)] = e[81]  -- SETTABLE [a=26 b=38 c=81 d=55] -- settable/void-call (inferred)
  e[25][K(368)] = e[97]  -- SETTABLE [a=25 b=368 c=97 d=94] -- settable/void-call (inferred)
  call(e[30], e[23])  -- CALL? [a=30 b=0 c=23 d=nil] -- void call
  ::L_48::
  goto L_79
  e[0] = {}  -- NEWTABLE [a=0 b=6 c=0 d=nil]
  e[2] = 34  -- LOADK [a=2 b=1802 c=0 d=34]
  ::L_51::
  goto L_91
  ::L_52::
  goto L_2
  if e[60] then do return end else goto L_54 end
  ::L_54::
  goto L_51
  e[128] = e[128]["running"]  -- GETTABLE [a=128 b=1 c=909 d=nil]  -- = "running"
  e[7] = e[7][K(4)]  -- GETTABLE/CLOSURE [a=7 b=4 c=7 d=nil]
  call(e[7], e[1380])  -- CALL [a=7 b=5 c=1380 d=nil] -- void call
  e[6] = e[6][K(1)]  -- GETTABLE [a=6 b=1 c=102 d=nil]
  e[7] = e[2][36]  -- GETTABLE/CLOSURE? [a=2 b=0 c=7 d=nil]  -- = 36
  goto L_15
  e[7] = e[7]["match"]  -- GETTABLE [a=7 b=1 c=725 d=nil]  -- = "match"
  e[178] = e[178][K(3)]  -- GETTABLE/CLOSURE [a=178 b=3 c=7 d=nil]
  call(e[7], e[1805])  -- CALL [a=7 b=5 c=1805 d=nil] -- void call
  ::L_64::
  goto L_13
  e[14] = {}  -- NEWTABLE [a=0 b=14 c=0 d=nil]
  e[13] = {}  -- NEWTABLE [a=13 b=0 c=0 d=nil]
  e[19] = K(9)  -- LOADK_S [a=0 b=9 c=19 d=nil]
  -- UNKNOWN op? [a=188 b=2070 c=0]
  e[78] = e[46]  -- MOVE [a=46 b=78 c=0 d=3]  -- = 3
  call(e[22], e[0])  -- CALL [a=22 b=0 c=0 d=nil] -- void call
  e[19] = 12  -- LOADK_N [a=0 b=19 c=4 d=nil]
  e[19] = arith(e[19], e[19])  -- ARITH [a=1370 b=19 c=19 d=nil]  -- = 433
  e[19] = arith(e[19], e[962])  -- UNOP/arith? [a=19 b=19 c=962 d=nil]  -- = 903
  e[19] = e[19] + 15362  -- ADD [a=19 b=1592 c=19 d=15362]  -- = 16265
  e[19] = arith(e[19], e[156])  -- UNOP/arith? [a=19 b=19 c=156 d=nil]  -- = 3
  call(e[19], e[44])  -- CALL [a=19 b=14 c=44 d=nil] -- void call
  e[13][K(99)] = e[58]  -- SETTABLE [a=13 b=99 c=58 d=5] -- settable/void-call (inferred)
  call(e[22], e[11])  -- CALL? [a=22 b=0 c=11 d=nil] -- void call
  ::L_79::
  goto L_18
  e[1] = e[7]  -- MOVE [a=7 b=1 c=1838 d=nil]
  e[9] = e[5][K(0)]  -- GETTABLE/CLOSURE? [a=5 b=0 c=9 d=nil]
  e[10] = e[241][K(0)]  -- GETTABLE/CLOSURE? [a=241 b=0 c=10 d=nil]
  goto L_7
  ::L_85::
  -- UNKNOWN op? [a=0 b=93 c=0 d=nil]
  e[26] = {}  -- NEWTABLE [a=0 b=26 c=0 d=nil]
  e[25] = {}  -- NEWTABLE [a=25 b=0 c=0 d=nil]
  e[26][K(91)] = e[81]  -- SETTABLE [a=26 b=91 c=81 d=62] -- settable/void-call (inferred)
  e[25][K(114)] = e[94]  -- SETTABLE [a=25 b=114 c=94 d=18] -- settable/void-call (inferred)
  call(e[30], e[23])  -- CALL? [a=30 b=0 c=23 d=nil] -- void call
  ::L_91::
  goto L_52
  if e[94] then do return end else goto L_93 end
  ::L_93::
  goto L_17
  goto L_42
  e[7] = e[7]["find"]  -- GETTABLE [a=7 b=1 c=2123 d=nil]  -- = "find"
  -- UNKNOWN op? [a=7 b=3 c=7 d=nil]
  call(e[7], e[113])  -- CALL [a=7 b=5 c=113 d=nil] -- void call
  e[2] = 36  -- LOADK [a=2 b=74 c=0 d=36]
  goto L_91
end

local function proto11(...)  -- 8 instrs, 5 blocks (structured)
  local e = regs
  ::L_1::
  ::L_3::
  goto L_1
  call(e[4], e[1353])  -- CALL [a=4 b=2 c=1353 d=nil] -- void call
  goto L_3
  e[0] = {}  -- NEWTABLE [a=0 b=3 c=0 d=nil]
  e[4] = e[4]["char"]  -- GETTABLE [a=4 b=1 c=354 d=nil]  -- = "char"
  e[4] = e[4][K(3)]  -- GETTABLE/CLOSURE [a=4 b=3 c=4 d=nil]
  goto L_1
  -- UNKNOWN op? [a=301 b=440 c=116 d=nil]
end

local function proto12(...)  -- 51 instrs, 17 blocks (structured)
  local e = regs
  ::L_1::
  -- UNKNOWN op? [a=57 b=441 c=326 d=nil]
  ::L_47::
  ::L_7::
  ::L_14::
  ::L_44::
  ::L_25::
  ::L_31::
  goto L_1
  e[6] = e[6][K(1)]  -- GETTABLE [a=6 b=1 c=18 d=nil]
  call(e[6], e[2412])  -- CALL [a=6 b=5 c=2412 d=nil] -- void call
  e[4] = e[4][K(1)]  -- GETTABLE [a=4 b=1 c=18 d=nil]
  e[3] = e[3][K(1)]  -- GETTABLE [a=3 b=1 c=18 d=nil]
  ::L_6::
  e[6] = e[2][K(0)]  -- GETTABLE/CLOSURE? [a=2 b=0 c=6 d=nil]
  goto L_7
  e[23] = {}  -- NEWTABLE [a=0 b=23 c=0 d=nil]
  e[22] = {}  -- NEWTABLE [a=22 b=0 c=0 d=nil]
  e[22][K(32)] = e[16]  -- SETTABLE [a=22 b=32 c=16 d=29] -- settable/void-call (inferred)
  e[23][K(115)] = e[93]  -- SETTABLE [a=23 b=115 c=93 d=28] -- settable/void-call (inferred)
  e[22][K(40)] = e[51]  -- SETTABLE [a=22 b=40 c=51 d=47] -- settable/void-call (inferred)
  call(e[27], e[20])  -- CALL? [a=27 b=0 c=20 d=nil] -- void call
  goto L_14
  e[24] = {}  -- NEWTABLE [a=24 b=0 c=0 d=nil]
  e[22] = {}  -- NEWTABLE [a=22 b=0 c=0 d=nil]
  e[21] = {}  -- NEWTABLE [a=21 b=0 c=0 d=nil]
  e[23] = {}  -- NEWTABLE [a=0 b=23 c=0 d=nil]
  e[22][K(55)] = e[114]  -- SETTABLE [a=22 b=55 c=114 d=37] -- settable/void-call (inferred)
  e[24][K(55)] = e[2323]  -- SETTABLE [a=24 b=55 c=2323 d=37] -- settable/void-call (inferred)
  e[23][K(60)] = e[117]  -- SETTABLE [a=23 b=60 c=117 d=35] -- settable/void-call (inferred)
  e[21][K(60)] = e[4]  -- SETTABLE [a=21 b=60 c=4 d=35] -- settable/void-call (inferred)
  e[22][K(67)] = e[127]  -- SETTABLE [a=22 b=67 c=127 d=48] -- settable/void-call (inferred)
  call(e[27], e[20])  -- CALL? [a=27 b=0 c=20 d=nil] -- void call
  goto L_25
  e[0] = {}  -- NEWTABLE [a=0 b=5 c=0 d=nil]
  call(e[250], e[1828])  -- CALL [a=250 b=5 c=1828 d=nil] -- void call
  e[51] = e[51][K(1)]  -- GETTABLE [a=51 b=1 c=18 d=nil]
  e[6] = e[6][K(241)]  -- GETTABLE [a=6 b=241 c=18 d=nil]
  call(e[6], e[2280])  -- CALL [a=6 b=5 c=2280 d=nil] -- void call
  goto L_31
  e[13] = {}  -- NEWTABLE [a=0 b=13 c=0 d=nil]
  e[12] = {}  -- NEWTABLE [a=12 b=0 c=0 d=nil]
  e[18] = K(13)  -- LOADK_S [a=0 b=13 c=18 d=nil]
  e[156] = "= I3 c189><"  -- LOADK [a=156 b=1423 c=54 d==]
  e[18] = 192  -- LOADK_N [a=0 b=0 c=18 d=nil]
  e[141] = (e[18] == e[164])  -- COMPARE [a=18 b=141 c=164 d=nil]  -- = -158
  e[18] = arith(e[18], e[1406])  -- UNOP/arith? [a=18 b=18 c=1406 d=nil]  -- = 202
  e[18] = e[18] + 30623  -- ADD [a=18 b=1603 c=18 d=30623]  -- = 30825
  e[18] = arith(e[18], e[2339])  -- UNOP/arith? [a=18 b=18 c=2339 d=nil]  -- = 0
  call(e[18], e[61])  -- CALL [a=18 b=13 c=61 d=nil] -- void call
  e[12][K(116)] = e[104]  -- SETTABLE [a=12 b=116 c=104 d=45] -- settable/void-call (inferred)
  call(e[19], e[10])  -- CALL? [a=19 b=0 c=10 d=nil] -- void call
  goto L_44
  goto L_47
  e[7] = e[3][K(0)]  -- GETTABLE/CLOSURE? [a=3 b=0 c=7 d=nil]
  e[8] = e[4][K(0)]  -- GETTABLE/CLOSURE? [a=4 b=0 c=8 d=nil]
  goto L_6
end

local function proto13(...)  -- 103 instrs, 41 blocks (structured)
  local e = regs
  ::L_1::
  ::L_74::
  ::L_83::
  ::L_19::
  ::L_14::
  ::L_23::
  ::L_37::
  ::L_12::
  e[33][K(71)] = e[73]  -- SETTABLE [a=33 b=71 c=73 d=49] -- settable/void-call (inferred)
  call(e[38], e[31])  -- CALL? [a=38 b=0 c=31 d=nil] -- void call
  goto L_14
  ::L_2::
  goto L_55
  e[54] = e[185][K(0)]  -- GETTABLE/CLOSURE? [a=185 b=0 c=54 d=nil]
  if e[12] then goto L_9 end
  e[6] = e[12][K(0)]  -- GETTABLE/CLOSURE? [a=12 b=0 c=6 d=nil]
  e[5] = e[13][96]  -- GETTABLE/CLOSURE? [a=13 b=0 c=5 d=nil]  -- = 96
  ::L_7::
  goto L_69
  ::L_8::
  goto L_75
  ::L_9::
  e[33] = {}  -- NEWTABLE [a=33 b=0 c=0 d=nil]
  e[33][K(124)] = e[16]  -- SETTABLE [a=33 b=124 c=16 d=24] -- settable/void-call (inferred)
  e[33][K(29)] = e[4]  -- SETTABLE [a=33 b=29 c=4 d=32] -- settable/void-call (inferred)
  goto L_12
  ::L_15::
  goto L_93
  e[0] = {}  -- NEWTABLE [a=0 b=10 c=0 d=nil]
  call(e[11], e[0])  -- CALL [a=11 b=0 c=0 d=nil] -- void call
  e[5] = 69  -- LOADK [a=5 b=2305 c=0 d=69]
  goto L_19
  e[17] = e[5][96]  -- GETTABLE/CLOSURE? [a=5 b=0 c=17 d=nil]  -- = 96
  e[18] = e[10][K(0)]  -- GETTABLE/CLOSURE? [a=10 b=0 c=18 d=nil]
  dataop(e[9], e[0], e[19])  -- DATAOP [a=9 b=0 c=19 d=nil]
  goto L_23
  e[12] = e[12][K(125)]  -- GETTABLE [a=12 b=125 c=18 d=nil]
  call(e[12], e[354])  -- CALL [a=12 b=3 c=354 d=nil] -- void call
  e[12] = e[12][K(1)]  -- GETTABLE [a=12 b=1 c=18 d=nil]
  call(e[12], e[725])  -- CALL [a=12 b=3 c=725 d=nil] -- void call
  e[7] = e[7][K(1)]  -- GETTABLE [a=7 b=1 c=18 d=nil]
  e[8] = e[8][K(1)]  -- GETTABLE [a=8 b=1 c=18 d=nil]
  e[12] = e[8][K(0)]  -- GETTABLE/CLOSURE? [a=8 b=0 c=12 d=nil]
  ::L_31::
  goto L_31
  e[13] = e[7][K(81)]  -- GETTABLE/CLOSURE? [a=7 b=81 c=13 d=nil]
  e[14] = e[6][K(0)]  -- GETTABLE/CLOSURE? [a=6 b=0 c=14 d=nil]
  e[15] = e[4][K(0)]  -- GETTABLE/CLOSURE? [a=4 b=0 c=15 d=nil]
  e[16] = e[10][K(0)]  -- GETTABLE/CLOSURE? [a=10 b=0 c=16 d=nil]
  e[17] = e[5][96]  -- GETTABLE/CLOSURE? [a=5 b=0 c=17 d=nil]  -- = 96
  goto L_37
  e[32] = {}  -- NEWTABLE [a=32 b=0 c=0 d=nil]
  e[33] = {}  -- NEWTABLE [a=33 b=0 c=0 d=nil]
  e[33][K(128)] = e[4]  -- SETTABLE [a=33 b=128 c=4 d=51] -- settable/void-call (inferred)
  e[32][K(128)] = e[100]  -- SETTABLE [a=32 b=128 c=100 d=51] -- settable/void-call (inferred)
  e[33][K(64)] = e[71]  -- SETTABLE [a=33 b=64 c=71 d=85] -- settable/void-call (inferred)
  call(e[38], e[31])  -- CALL? [a=38 b=0 c=31 d=nil] -- void call
  ::L_44::
  goto L_49
  if e[12] then goto L_1 end  -- back-edge (loop)
  e[12] = e[12][K(9)]  -- GETTABLE/CLOSURE [a=12 b=9 c=12 d=nil]
  call(e[12], e[613])  -- CALL [a=12 b=3 c=613 d=nil] -- void call
  ::L_48::
  goto L_48
  ::L_49::
  goto L_8
  e[1] = e[12]  -- MOVE [a=12 b=1 c=1307 d=nil]
  e[55] = e[4][K(62)]  -- GETTABLE/CLOSURE? [a=4 b=62 c=55 d=nil]
  e[15] = e[3][K(0)]  -- GETTABLE/CLOSURE? [a=3 b=0 c=15 d=nil]
  e[16] = e[2][K(0)]  -- GETTABLE/CLOSURE? [a=2 b=0 c=16 d=nil]
  goto L_7
  ::L_55::
  -- UNKNOWN op? [a=144 b=265 c=418 d=nil]
  e[35] = {}  -- NEWTABLE [a=35 b=0 c=0 d=nil]
  e[33] = {}  -- NEWTABLE [a=33 b=0 c=0 d=nil]
  e[35][K(116)] = e[41]  -- SETTABLE [a=35 b=116 c=41 d=45] -- settable/void-call (inferred)
  e[33][K(93)] = e[51]  -- SETTABLE [a=33 b=93 c=51 d=2] -- settable/void-call (inferred)
  call(e[38], e[31])  -- CALL? [a=38 b=0 c=31 d=nil] -- void call
  ::L_61::
  goto L_44
  e[33] = {}  -- NEWTABLE [a=33 b=0 c=0 d=nil]
  e[35] = {}  -- NEWTABLE [a=35 b=0 c=0 d=nil]
  e[34] = {}  -- NEWTABLE [a=0 b=34 c=0 d=nil]
  e[34][K(76)] = e[32]  -- SETTABLE [a=34 b=76 c=32 d=98] -- settable/void-call (inferred)
  e[35][K(76)] = e[87]  -- SETTABLE [a=35 b=76 c=87 d=98] -- settable/void-call (inferred)
  e[33][K(83)] = e[22]  -- SETTABLE [a=33 b=83 c=22 d=75] -- settable/void-call (inferred)
  call(e[38], e[31])  -- CALL? [a=38 b=0 c=31 d=nil] -- void call
  ::L_69::
  goto L_15
  e[4] = e[14][K(0)]  -- GETTABLE/CLOSURE? [a=14 b=0 c=4 d=nil]
  e[11] = e[15][13617]  -- GETTABLE/CLOSURE? [a=15 b=0 c=11 d=nil]  -- = 13617
  e[10] = e[119][K(0)]  -- GETTABLE/CLOSURE? [a=119 b=0 c=10 d=nil]
  if e[14] then do return end else goto L_74 end
  ::L_75::
  goto L_61
  e[33] = {}  -- NEWTABLE [a=33 b=0 c=0 d=nil]
  e[32] = {}  -- NEWTABLE [a=32 b=0 c=0 d=nil]
  e[34] = {}  -- NEWTABLE [a=0 b=34 c=0 d=nil]
  e[32][K(111)] = e[110]  -- SETTABLE [a=32 b=111 c=110 d=3] -- settable/void-call (inferred)
  e[34][K(111)] = e[23]  -- SETTABLE [a=34 b=111 c=23 d=3] -- settable/void-call (inferred)
  e[33][K(84)] = e[117]  -- SETTABLE [a=33 b=84 c=117 d=8] -- settable/void-call (inferred)
  call(e[38], e[31])  -- CALL? [a=38 b=0 c=31 d=nil] -- void call
  goto L_83
  ::L_84::
  goto L_92
  ::L_86::
  goto L_86
  e[33] = {}  -- NEWTABLE [a=33 b=0 c=0 d=nil]
  e[34] = {}  -- NEWTABLE [a=0 b=34 c=0 d=nil]
  e[34][K(10)] = e[108]  -- SETTABLE [a=34 b=10 c=108 d=72] -- settable/void-call (inferred)
  e[33][K(1568)] = e[93]  -- SETTABLE [a=33 b=1568 c=93 d=86] -- settable/void-call (inferred)
  call(e[38], e[31])  -- CALL? [a=38 b=0 c=31 d=nil] -- void call
  ::L_92::
  goto L_2
  ::L_93::
  goto L_1
  e[23] = {}  -- NEWTABLE [a=23 b=0 c=0 d=nil]
  e[25] = {}  -- NEWTABLE [a=25 b=0 c=0 d=nil]
  e[29] = 637  -- LOADK_N [a=1633 b=1116 c=29 d=450]
  e[29] = arith(e[29], e[2367])  -- ARITH [a=29 b=29 c=2367 d=nil]  -- = 616
  e[39][12546] = e[29]  -- SETTABLE/CALL [a=39 b=1869 c=29 d=11930] -- settable/void-call (inferred)
  e[29] = arith(e[29], e[1366])  -- UNOP/arith? [a=29 b=29 c=1366 d=nil]  -- = 292
  call(e[29], e[119])  -- CALL [a=29 b=25 c=119 d=nil] -- void call
  e[23][K(22)] = e[71]  -- SETTABLE [a=23 b=22 c=71 d=15] -- settable/void-call (inferred)
  call(e[30], e[21])  -- CALL? [a=30 b=0 c=21 d=nil] -- void call
  goto L_84
end

local function proto14(...)  -- 94 instrs, 39 blocks (structured)
  local e = regs
  ::L_1::
  ::L_46::
  ::L_18::
  ::L_9::
  e[30] = {}  -- NEWTABLE [a=0 b=30 c=0 d=nil]
  e[30][K(72)] = e[99]  -- SETTABLE [a=30 b=72 c=99 d=89] -- settable/void-call (inferred)
  e[31][K(72)] = e[112]  -- SETTABLE [a=31 b=72 c=112 d=89] -- settable/void-call (inferred)
  e[29][K(33)] = e[55]  -- SETTABLE [a=29 b=33 c=55 d=39] -- settable/void-call (inferred)
  call(e[34], e[27])  -- CALL? [a=34 b=0 c=27 d=nil] -- void call
  ::L_14::
  ::L_37::
  ::L_85::
  ::L_88::
  ::L_93::
  goto L_9
  e[29] = {}  -- NEWTABLE [a=29 b=0 c=0 d=nil]
  e[29][K(22)] = e[4]  -- SETTABLE [a=29 b=22 c=4 d=15] -- settable/void-call (inferred)
  e[29][K(95)] = e[27]  -- SETTABLE [a=29 b=95 c=27 d=61] -- settable/void-call (inferred)
  call(e[34], e[27])  -- CALL? [a=34 b=0 c=27 d=nil] -- void call
  ::L_6::
  goto L_66
  e[29] = {}  -- NEWTABLE [a=29 b=0 c=0 d=nil]
  ::L_8::
  e[31] = {}  -- NEWTABLE [a=31 b=0 c=0 d=nil]
  goto L_9
  e[11] = e[2][K(128)]  -- GETTABLE/CLOSURE? [a=2 b=128 c=11 d=nil]
  call(e[12], e[0])  -- CALL [a=12 b=0 c=0 d=nil] -- void call
  e[13] = e[6][K(0)]  -- GETTABLE/CLOSURE? [a=6 b=0 c=13 d=nil]
  goto L_18
  e[19] = {}  -- NEWTABLE [a=19 b=0 c=0 d=nil]
  e[21] = {}  -- NEWTABLE [a=21 b=0 c=0 d=nil]
  e[25] = K(13)  -- LOADK_S [a=0 b=13 c=25 d=nil]
  e[26] = "=l  "  -- LOADK [a=26 b=1277 c=0 d==l]
  e[25] = 8  -- LOADK_N [a=0 b=235 c=25 d=nil]
  e[25] = arith(e[25], e[1802])  -- UNOP/arith? [a=25 b=25 c=1802 d=nil]  -- = 42
  e[25] = arith(e[25], e[242])  -- UNOP/arith? [a=25 b=25 c=242 d=nil]  -- = 154
  e[25] = e[52] + 10642  -- ADD [a=25 b=710 c=52 d=10642]  -- = 10796
  e[25] = arith(e[25], e[1820])  -- UNOP/arith? [a=25 b=25 c=1820 d=nil]  -- = 292
  call(e[25], e[52])  -- CALL [a=25 b=21 c=52 d=nil] -- void call
  e[19][K(67)] = e[105]  -- SETTABLE [a=19 b=67 c=105 d=48] -- settable/void-call (inferred)
  call(e[26], e[17])  -- CALL? [a=26 b=0 c=17 d=nil] -- void call
  ::L_31::
  goto L_56
  e[31] = {}  -- NEWTABLE [a=31 b=0 c=0 d=nil]
  e[29] = {}  -- NEWTABLE [a=29 b=0 c=0 d=nil]
  e[31][K(13)] = e[71]  -- SETTABLE [a=31 b=13 c=71 d=67] -- settable/void-call (inferred)
  e[29][K(40)] = e[64]  -- SETTABLE [a=29 b=40 c=64 d=47] -- settable/void-call (inferred)
  call(e[34], e[27])  -- CALL? [a=34 b=0 c=27 d=nil] -- void call
  goto L_37
  ::L_39::
  goto L_6
  e[28] = {}  -- NEWTABLE [a=28 b=0 c=0 d=nil]
  e[29] = {}  -- NEWTABLE [a=29 b=0 c=0 d=nil]
  e[29][K(73)] = e[4]  -- SETTABLE [a=29 b=73 c=4 d=23] -- settable/void-call (inferred)
  e[28][K(19)] = e[104]  -- SETTABLE [a=28 b=19 c=104 d=26] -- settable/void-call (inferred)
  e[29][K(71)] = e[114]  -- SETTABLE [a=29 b=71 c=114 d=49] -- settable/void-call (inferred)
  call(e[34], e[27])  -- CALL? [a=34 b=0 c=27 d=nil] -- void call
  goto L_46
  ::L_47::
  goto L_31
  ::L_48::
  goto L_48
  ::L_49::
  goto L_39
  e[29] = {}  -- NEWTABLE [a=29 b=0 c=0 d=nil]
  e[30] = {}  -- NEWTABLE [a=0 b=30 c=0 d=nil]
  e[30][K(101)] = e[9]  -- SETTABLE [a=30 b=101 c=9 d=59] -- settable/void-call (inferred)
  e[29][K(368)] = e[40]  -- SETTABLE [a=29 b=368 c=40 d=94] -- settable/void-call (inferred)
  call(e[34], e[27])  -- CALL? [a=34 b=0 c=27 d=nil] -- void call
  goto L_47
  ::L_56::
  -- UNKNOWN op? [a=384 b=153 c=484 d=nil]
  e[1] = e[9]  -- MOVE [a=9 b=1 c=689 d=nil]
  -- UNKNOWN op? [a=7 b=0 c=11 d=nil]
  e[12] = e[118][K(0)]  -- GETTABLE/CLOSURE? [a=118 b=0 c=12 d=nil]
  ::L_60::
  goto L_1
  ::L_62::
  goto L_71
  e[13] = e[3][K(0)]  -- GETTABLE/CLOSURE? [a=3 b=0 c=13 d=nil]
  e[14] = e[6][K(0)]  -- GETTABLE/CLOSURE? [a=6 b=0 c=14 d=nil]
  e[15] = e[2][K(0)]  -- GETTABLE/CLOSURE? [a=2 b=0 c=15 d=nil]
  ::L_66::
  goto L_78
  -- UNKNOWN op? [a=3 b=1828 c=1497 d=12]
  e[5] = 96  -- LOADK [a=5 b=2304 c=0 d=96]
  e[9] = e[8][K(0)]  -- GETTABLE/CLOSURE? [a=8 b=0 c=9 d=nil]
  e[10] = e[5][96]  -- GETTABLE/CLOSURE? [a=5 b=0 c=10 d=nil]  -- = 96
  ::L_71::
  goto L_14
  e[29] = {}  -- NEWTABLE [a=29 b=0 c=0 d=nil]
  e[28] = {}  -- NEWTABLE [a=28 b=0 c=0 d=nil]
  e[29][K(97)] = e[4]  -- SETTABLE [a=29 b=97 c=4 d=79] -- settable/void-call (inferred)
  e[28][K(97)] = e[108]  -- SETTABLE [a=28 b=97 c=108 d=79] -- settable/void-call (inferred)
  e[29][K(91)] = e[91]  -- SETTABLE [a=29 b=91 c=91 d=62] -- settable/void-call (inferred)
  call(e[34], e[27])  -- CALL? [a=34 b=0 c=27 d=nil] -- void call
  ::L_78::
  goto L_62
  e[150] = e[8][K(137)]  -- GETTABLE/CLOSURE? [a=8 b=137 c=150 d=nil]
  if e[9] then goto L_8 end  -- back-edge (loop)
  e[8] = e[9][K(0)]  -- GETTABLE/CLOSURE? [a=9 b=0 c=8 d=nil]
  e[2] = e[10][K(0)]  -- GETTABLE/CLOSURE? [a=10 b=0 c=2 d=nil]
  e[6] = e[11][K(0)]  -- GETTABLE/CLOSURE? [a=11 b=0 c=6 d=nil]
  e[9] = e[8][K(0)]  -- GETTABLE/CLOSURE? [a=8 b=0 c=9 d=nil]
  goto L_85
  e[0] = {}  -- NEWTABLE [a=0 b=8 c=0 d=nil]
  if e[932] then goto L_60 else goto L_88 end  -- back-edge (loop)
  -- UNKNOWN op? [a=194 b=0 c=10 d=nil]
  e[11] = e[2][K(0)]  -- GETTABLE/CLOSURE? [a=2 b=0 c=11 d=nil]
  e[12] = 13617  -- LOADK [a=12 b=1432 c=0 d=13617]
  e[13] = e[6][K(0)]  -- GETTABLE/CLOSURE? [a=6 b=0 c=13 d=nil]
  goto L_93
  goto L_49
end

local function proto15(...)  -- 75 instrs, 22 blocks (structured)
  local e = regs
  ::L_1::
  ::L_51::
  ::L_39::
  e[14] = {}  -- NEWTABLE [a=14 b=0 c=0 d=nil]
  e[15] = {}  -- NEWTABLE [a=0 b=15 c=0 d=nil]
  do return end  -- JMP/RETURN [a=1446 b=164 c=20 d=350]
  e[10] = e[10][false]  -- GETTABLE [a=10 b=1 c=90 d=nil]  -- = false
  e[9][K(10)] = e[8]  -- SETTABLE/CALL [a=9 b=10 c=8 d=nil] -- settable/void-call (inferred)
  call(e[8], e[2280])  -- CALL [a=8 b=4 c=2280 d=nil] -- void call
  -- UNKNOWN op? [a=500 b=377 c=102 d=nil]
  ::L_7::
  goto L_40
  e[21] = K(13)  -- LOADK_S [a=0 b=13 c=21 d=nil]
  e[22] = ">c132 =Jj="  -- LOADK [a=22 b=1008 c=0 d=>c132]
  e[89] = 140  -- LOADK_N [a=0 b=0 c=89 d=nil]
  e[20] = arith(e[20], e[243])  -- ARITH [a=21 b=20 c=243 d=nil]  -- = 611
  e[20] = e[20] + 19300  -- ADD [a=20 b=1654 c=20 d=19300]  -- = 19911
  e[20] = arith(e[20], e[2051])  -- UNOP/arith? [a=20 b=20 c=2051 d=nil]  -- = 8
  call(e[20], e[24])  -- CALL [a=20 b=15 c=24 d=nil] -- void call
  e[20] = K(13)  -- LOADK_S [a=0 b=13 c=20 d=nil]
  e[219] = "<>h=f"  -- LOADK [a=219 b=813 c=0 d=<>h=f]
  -- UNKNOWN op? [a=192 b=0 c=247 d=nil]
  e[20] = arith(e[20], e[1951])  -- UNOP/arith? [a=20 b=20 c=1951 d=nil]  -- = 52
  e[20] = arith(e[20], e[2115])  -- UNOP/arith? [a=20 b=20 c=2115 d=nil]  -- = 181
  e[20] = e[20] + 2320  -- ADD [a=20 b=2360 c=20 d=2320]  -- = 2501
  e[20] = arith(e[20], e[1322])  -- UNOP/arith? [a=20 b=20 c=1322 d=nil]  -- = 1
  call(e[20], e[24])  -- CALL [a=20 b=14 c=24 d=nil] -- void call
  e[14][K(35)] = e[16]  -- SETTABLE [a=14 b=35 c=16 d=53] -- settable/void-call (inferred)
  call(e[22], e[12])  -- CALL? [a=22 b=0 c=12 d=nil] -- void call
  ::L_28::
  goto L_1
  ::L_29::
  goto L_46
  e[146] = e[146]["byte"]  -- GETTABLE [a=146 b=212 c=1451 d=nil]  -- = "byte"
  e[8] = e[8][K(2)]  -- GETTABLE/CLOSURE [a=8 b=2 c=8 d=nil]
  call(e[8], e[2412])  -- CALL [a=8 b=65 c=2412 d=nil] -- void call
  ::L_33::
  goto L_33
  e[5] = e[5][K(1)]  -- GETTABLE [a=5 b=1 c=283 d=nil]
  e[6] = e[6][K(1)]  -- GETTABLE [a=6 b=1 c=25 d=nil]
  e[8] = e[231][K(0)]  -- GETTABLE/CLOSURE? [a=231 b=0 c=8 d=nil]
  e[9] = e[6][K(0)]  -- GETTABLE/CLOSURE? [a=6 b=0 c=9 d=nil]
  e[10] = e[5][K(0)]  -- GETTABLE/CLOSURE? [a=5 b=0 c=10 d=nil]
  goto L_39
  ::L_40::
  goto L_61
  e[26] = {}  -- NEWTABLE [a=0 b=26 c=0 d=nil]
  e[25] = {}  -- NEWTABLE [a=25 b=0 c=0 d=nil]
  e[26][K(106)] = e[81]  -- SETTABLE [a=26 b=106 c=81 d=36] -- settable/void-call (inferred)
  e[25][K(81)] = e[32]  -- SETTABLE [a=25 b=81 c=32 d=7] -- settable/void-call (inferred)
  call(e[30], e[23])  -- CALL? [a=30 b=0 c=23 d=nil] -- void call
  ::L_46::
  goto L_29
  e[25] = {}  -- NEWTABLE [a=25 b=0 c=0 d=nil]
  e[25][K(29)] = e[9]  -- SETTABLE [a=25 b=29 c=9 d=32] -- settable/void-call (inferred)
  e[25][K(32)] = e[94]  -- SETTABLE [a=25 b=32 c=94 d=29] -- settable/void-call (inferred)
  call(e[30], e[23])  -- CALL? [a=30 b=0 c=23 d=nil] -- void call
  goto L_51
  e[0] = {}  -- NEWTABLE [a=0 b=7 c=0 d=nil]
  e[8] = e[8]["cancel"]  -- GETTABLE [a=8 b=1 c=2367 d=nil]  -- = "cancel"
  e[7] = e[7][K(3)]  -- GETTABLE/CLOSURE [a=7 b=3 c=8 d=nil]
  e[8] = {}  -- NEWTABLE [a=0 b=0 c=8 d=nil]
  e[9] = e[9][true]  -- GETTABLE [a=9 b=1 c=1935 d=nil]  -- = true
  call(e[9], e[1716])  -- CALL [a=9 b=8 c=1716 d=nil] -- void call
  e[9] = e[9][true]  -- GETTABLE [a=9 b=1 c=1935 d=nil]  -- = true
  ::L_61::
  goto L_28
  e[24] = {}  -- NEWTABLE [a=24 b=0 c=0 d=nil]
  e[26] = {}  -- NEWTABLE [a=0 b=26 c=0 d=nil]
  e[25] = {}  -- NEWTABLE [a=25 b=0 c=0 d=nil]
  e[27] = {}  -- NEWTABLE [a=27 b=0 c=0 d=nil]
  e[27][K(42)] = e[929]  -- SETTABLE [a=27 b=42 c=929 d=10] -- settable/void-call (inferred)
  e[26][K(110)] = e[4]  -- SETTABLE [a=26 b=110 c=4 d=20] -- settable/void-call (inferred)
  e[24][K(110)] = e[110]  -- SETTABLE [a=24 b=110 c=110 d=20] -- settable/void-call (inferred)
  e[27][K(110)] = e[96]  -- SETTABLE [a=27 b=110 c=96 d=20] -- settable/void-call (inferred)
  e[24][K(100)] = e[110]  -- SETTABLE [a=24 b=100 c=110 d=14] -- settable/void-call (inferred)
  e[24][K(118)] = e[122]  -- SETTABLE [a=24 b=118 c=122 d=13] -- settable/void-call (inferred)
  e[26][K(117)] = e[122]  -- SETTABLE [a=26 b=117 c=122 d=19] -- settable/void-call (inferred)
  e[25][K(89)] = e[81]  -- SETTABLE [a=25 b=89 c=81 d=40] -- settable/void-call (inferred)
  call(e[30], e[23])  -- CALL? [a=30 b=0 c=23 d=nil] -- void call
  goto L_7
end

local function proto16(...)  -- 134 instrs, 59 blocks (structured)
  local e = regs
  ::L_1::
  ::L_106::
  ::L_53::
  ::L_79::
  ::L_113::
  goto L_1
  e[28] = K(13)  -- LOADK_S [a=0 b=13 c=28 d=nil]
  e[240] = " >JH=c126 >"  -- LOADK [a=240 b=1751 c=0]
  -- UNKNOWN op? [a=0 b=0 c=28 d=nil]
  e[27] = arith(e[27], e[27])  -- ARITH [a=28 b=27 c=27 d=nil]  -- = -131
  e[154][K(675)] = e[27]  -- SETTABLE/CALL [a=154 b=675 c=27 d=14495] -- settable/void-call (inferred)
  e[27][K(51)] = e[11]  -- SETTABLE/CALL [a=27 b=51 c=11 d=nil] -- settable/void-call (inferred)
  e[74][K(164)] = e[146]  -- SETTABLE/CALL [a=74 b=164 c=146 d=nil] -- settable/void-call (inferred)
  ::L_9::
  e[142][K(122)] = e[111]  -- SETTABLE/CALL [a=142 b=122 c=111 d=nil] -- settable/void-call (inferred)
  e[133] = K(109)  -- LOADK_S [a=133 b=109 c=25 d=nil]
  e[27] = arith(e[27], e[1788])  -- UNOP/arith? [a=27 b=27 c=1788 d=nil]  -- = 52
  ::L_12::
  call(e[27], e[58])  -- CALL [a=27 b=23 c=58 d=nil] -- void call
  e[21][K(1875)] = e[97]  -- SETTABLE [a=21 b=1875 c=97 d=114] -- settable/void-call (inferred)
  call(e[29], e[19])  -- CALL? [a=29 b=0 c=19 d=nil] -- void call
  ::L_15::
  goto L_98
  e[12] = e[12]["spawn"]  -- GETTABLE [a=12 b=1 c=1954 d=nil]  -- = "spawn"
  e[8] = e[8][K(11)]  -- GETTABLE/CLOSURE [a=8 b=11 c=12 d=nil]
  e[3] = 19  -- LOADK [a=3 b=909 c=0 d=19]
  ::L_19::
  goto L_90
  e[1] = e[12]  -- MOVE [a=12 b=1 c=1231 d=nil]
  e[251] = e[236][K(61)]  -- GETTABLE/CLOSURE? [a=236 b=61 c=251 d=nil]
  e[15] = e[6][K(0)]  -- GETTABLE/CLOSURE? [a=6 b=0 c=15 d=nil]
  e[12] = K(12)  -- LOADK_N [a=0 b=12 c=4 d=nil]
  e[6] = e[12][K(0)]  -- GETTABLE/CLOSURE? [a=12 b=0 c=6 d=nil]
  ::L_25::
  goto L_27
  e[17] = e[5][K(0)]  -- GETTABLE/CLOSURE? [a=5 b=0 c=17 d=nil]
  ::L_27::
  goto L_12
  -- UNKNOWN op? [a=12 b=1 c=18 d=nil]
  e[188][K(9)] = e[80]  -- SETTABLE/CALL [a=188 b=9 c=80 d=nil] -- settable/void-call (inferred)
  e[228][K(109)] = e[2123]  -- SETTABLE/CALL [a=228 b=109 c=2123 d=nil] -- settable/void-call (inferred)
  call(e[25], e[14])  -- CALL [a=25 b=199 c=14 d=nil] -- void call
  call(e[12], e[50])  -- CALL [a=12 b=80 c=50 d=nil] -- void call
  e[2] = e[2][K(1)]  -- GETTABLE [a=2 b=1 c=18 d=nil]
  e[5] = e[5][K(1)]  -- GETTABLE [a=5 b=1 c=18 d=nil]
  ::L_35::
  goto L_133
  e[32] = {}  -- NEWTABLE [a=32 b=0 c=0 d=nil]
  e[32][K(75)] = e[16]  -- SETTABLE [a=32 b=75 c=16 d=92] -- settable/void-call (inferred)
  e[32][K(2268)] = e[50]  -- SETTABLE [a=32 b=2268 c=50 d=134] -- settable/void-call (inferred)
  call(e[37], e[30])  -- CALL? [a=37 b=0 c=30 d=nil] -- void call
  ::L_40::
  goto L_91
  if e[61] then do return end else goto L_42 end
  ::L_42::
  goto L_55
  ::L_43::
  goto L_118
  e[34] = {}  -- NEWTABLE [a=34 b=0 c=0 d=nil]
  e[33] = {}  -- NEWTABLE [a=0 b=33 c=0 d=nil]
  e[31] = {}  -- NEWTABLE [a=31 b=0 c=0 d=nil]
  e[32] = {}  -- NEWTABLE [a=32 b=0 c=0 d=nil]
  e[33][K(120)] = e[88]  -- SETTABLE [a=33 b=120 c=88 d=81] -- settable/void-call (inferred)
  e[31][K(120)] = e[100]  -- SETTABLE [a=31 b=120 c=100 d=81] -- settable/void-call (inferred)
  e[34][K(120)] = e[112]  -- SETTABLE [a=34 b=120 c=112 d=81] -- settable/void-call (inferred)
  e[32][K(1134)] = e[97]  -- SETTABLE [a=32 b=1134 c=97 d=99] -- settable/void-call (inferred)
  call(e[37], e[30])  -- CALL? [a=37 b=0 c=30 d=nil] -- void call
  goto L_53
  if e[27] then goto L_1 end  -- back-edge (loop)
  ::L_55::
  goto L_99
  ::L_56::
  goto L_89
  e[21] = {}  -- NEWTABLE [a=21 b=0 c=0 d=nil]
  e[23] = {}  -- NEWTABLE [a=23 b=0 c=0 d=nil]
  e[27] = (e[2385] == e[2062])  -- COMPARE [a=2385 b=27 c=2062 d=nil]  -- = false
  if e[27] then goto L_63 end
  goto L_64
  if e[87] then goto L_117 end
  ::L_63::
  goto L_42
  ::L_64::
  goto L_100
  e[27] = K(13)  -- LOADK_S [a=0 b=13 c=27 d=nil]
  call(e[119], e[13])  -- CALL [a=119 b=82 c=13 d=nil] -- void call
  e[28][K(505)] = e[129]  -- SETTABLE/CALL [a=28 b=505 c=129 d==f=>=J<] -- settable/void-call (inferred)
  e[148] = K(130)  -- LOADK_S [a=148 b=130 c=15 d=nil]
  e[27] = K(0)  -- LOADK_N [a=0 b=0 c=27 d=nil]
  ::L_70::
  goto L_63
  ::L_71::
  goto L_71
  e[34] = {}  -- NEWTABLE [a=34 b=0 c=0 d=nil]
  e[33] = {}  -- NEWTABLE [a=0 b=33 c=0 d=nil]
  e[32] = {}  -- NEWTABLE [a=32 b=0 c=0 d=nil]
  e[34][K(9)] = e[96]  -- SETTABLE [a=34 b=9 c=96 d=4] -- settable/void-call (inferred)
  e[33][K(111)] = e[32]  -- SETTABLE [a=33 b=111 c=32 d=3] -- settable/void-call (inferred)
  e[32][K(43)] = e[1357]  -- SETTABLE [a=32 b=43 c=1357 d=71] -- settable/void-call (inferred)
  e[37][K(228)] = e[30]  -- SETTABLE/CALL [a=37 b=228 c=30 d=nil] -- settable/void-call (inferred)
  goto L_79
  -- UNKNOWN op? [a=12 b=1 c=857 d=nil]
  -- UNKNOWN op? [a=215 b=0 c=64 d=nil]
  e[52][K(227)] = e[15]  -- SETTABLE/CALL [a=52 b=227 c=15 d=nil] -- settable/void-call (inferred)
  call(e[3], e[140])  -- CALL [a=3 b=26 c=140 d=nil] -- void call
  e[123] = K(129)  -- LOADK_S [a=123 b=129 c=116 d=nil]
  e[16] = e[4][K(0)]  -- GETTABLE/CLOSURE? [a=4 b=0 c=16 d=nil]
  e[12] = K(12)  -- LOADK_N [a=0 b=12 c=5 d=nil]
  goto L_95
  if e[90] then goto L_9 end  -- back-edge (loop)
  ::L_89::
  goto L_15
  ::L_90::
  goto L_70
  ::L_91::
  goto L_124
  e[7] = e[7][K(104)]  -- GETTABLE [a=7 b=104 c=18 d=nil]
  e[12] = e[7][K(0)]  -- GETTABLE/CLOSURE? [a=7 b=0 c=12 d=nil]
  e[13] = e[8][K(0)]  -- GETTABLE/CLOSURE? [a=8 b=0 c=13 d=nil]
  ::L_95::
  goto L_114
  e[3] = e[12][4]  -- GETTABLE/CLOSURE? [a=12 b=0 c=3 d=nil]  -- = 4
  goto L_90
  ::L_98::
  e[62] = K(150)  -- LOADK_N [a=275 b=150 c=62 d=nil]
  ::L_99::
  goto L_43
  ::L_100::
  goto L_109
  e[32] = {}  -- NEWTABLE [a=32 b=0 c=0 d=nil]
  e[33] = {}  -- NEWTABLE [a=0 b=33 c=0 d=nil]
  e[33][K(571)] = e[4]  -- SETTABLE [a=33 b=571 c=4 d=112] -- settable/void-call (inferred)
  e[32][K(98)] = e[35]  -- SETTABLE [a=32 b=98 c=35 d=64] -- settable/void-call (inferred)
  call(e[37], e[30])  -- CALL? [a=37 b=0 c=30 d=nil] -- void call
  goto L_106
  e[0] = {}  -- NEWTABLE [a=0 b=11 c=0 d=nil]
  e[3] = 121  -- LOADK [a=3 b=1414 c=0 d=121]
  ::L_109::
  goto L_90
  e[27] = K(15)  -- LOADK_S [a=0 b=15 c=27 d=nil]
  e[28] = "014"  -- LOADK [a=28 b=794 c=0 d=]
  e[27] = 1  -- LOADK_N [a=47 b=0 c=27 d=nil]
  goto L_113
  ::L_114::
  goto L_56
  e[14] = e[6][K(0)]  -- GETTABLE/CLOSURE? [a=6 b=0 c=14 d=nil]
  e[15] = e[3][19]  -- GETTABLE/CLOSURE? [a=3 b=0 c=15 d=nil]  -- = 19
  ::L_117::
  e[16] = e[2][K(0)]  -- GETTABLE/CLOSURE? [a=2 b=0 c=16 d=nil]
  ::L_118::
  goto L_25
  e[34] = {}  -- NEWTABLE [a=34 b=0 c=0 d=nil]
  e[32] = {}  -- NEWTABLE [a=32 b=0 c=0 d=nil]
  e[34][K(115)] = e[41]  -- SETTABLE [a=34 b=115 c=41 d=28] -- settable/void-call (inferred)
  e[32][K(125)] = e[117]  -- SETTABLE [a=32 b=125 c=117 d=43] -- settable/void-call (inferred)
  e[37][K(162)] = e[30]  -- SETTABLE/CALL [a=37 b=162 c=30 d=nil] -- settable/void-call (inferred)
  ::L_124::
  goto L_19
  e[31] = {}  -- NEWTABLE [a=31 b=0 c=0 d=nil]
  e[32] = {}  -- NEWTABLE [a=32 b=0 c=0 d=nil]
  e[33] = {}  -- NEWTABLE [a=0 b=33 c=0 d=nil]
  e[32][K(122)] = e[4]  -- SETTABLE [a=32 b=122 c=4 d=21] -- settable/void-call (inferred)
  e[33][K(122)] = e[42]  -- SETTABLE [a=33 b=122 c=42 d=21] -- settable/void-call (inferred)
  e[31][K(122)] = e[100]  -- SETTABLE [a=31 b=122 c=100 d=21] -- settable/void-call (inferred)
  e[32][K(50)] = e[89]  -- SETTABLE [a=32 b=50 c=89 d=91] -- settable/void-call (inferred)
  call(e[37], e[30])  -- CALL? [a=37 b=0 c=30 d=nil] -- void call
  ::L_133::
  goto L_40
  goto L_35
end

local function proto17(...)  -- 60 instrs, 15 blocks (structured)
  local e = regs
  ::L_1::
  ::L_45::
  do return end  -- JMP/RETURN [a=0 b=0 c=5 d=nil]
  ::L_2::
  goto L_2
  e[11] = {}  -- NEWTABLE [a=0 b=11 c=0 d=nil]
  e[10] = {}  -- NEWTABLE [a=10 b=0 c=0 d=nil]
  e[16] = K(14)  -- LOADK_S [a=0 b=14 c=16 d=nil]
  e[17] = K(8)  -- LOADK_S [a=0 b=8 c=17 d=nil]
  e[18] = ">i8"  -- LOADK [a=18 b=6 c=0 d=>i8]
  e[19] = "000000000000000000000012"  -- LOADK [a=19 b=1521 c=0 d=       ]
  e[0][12] = e[0]  -- SETTABLE/CALL [a=0 b=17 c=0 d=nil] -- settable/void-call (inferred)
  e[18] = K(9)  -- LOADK_S [a=0 b=9 c=18 d=nil]
  e[19] = "193X|"  -- LOADK [a=19 b=629 c=0 d=�X|]
  e[103] = 1  -- LOADK [a=103 b=107 c=0 d=1]
  call(e[223], e[143])  -- CALL [a=223 b=0 c=143 d=nil] -- void call
  e[18] = 193  -- LOADK_N [a=78 b=18 c=4 d=nil]
  call(e[27], e[204])  -- CALL [a=27 b=124 c=204 d=nil] -- void call
  e[19][K(1151)] = e[35]  -- SETTABLE/CALL [a=19 b=1151 c=35 d=275] -- settable/void-call (inferred)
  e[86] = K(201)  -- LOADK_S [a=86 b=201 c=129 d=nil]
  e[16] = 479  -- LOADK_N [a=0 b=16 c=4 d=nil]
  call(e[16], e[202])  -- CALL [a=16 b=129 c=202 d=nil] -- void call
  e[49][K(16)] = e[107]  -- SETTABLE/CALL [a=49 b=16 c=107 d=nil] -- settable/void-call (inferred)
  e[212] = arith(e[113], e[1476])  -- ARITH [a=212 b=113 c=1476 d=nil]
  e[16] = e[16] + 21679  -- ADD [a=16 b=2207 c=16 d=21679]  -- = 22078
  e[16] = arith(e[16], e[298])  -- UNOP/arith? [a=16 b=16 c=298 d=nil]  -- = 5
  call(e[16], e[89])  -- CALL [a=16 b=11 c=89 d=nil] -- void call
  e[10][K(93)] = e[61]  -- SETTABLE [a=10 b=93 c=61 d=2] -- settable/void-call (inferred)
  call(e[21], e[8])  -- CALL? [a=21 b=0 c=8 d=nil] -- void call
  ::L_27::
  goto L_27
  e[0] = {}  -- NEWTABLE [a=0 b=4 c=0 d=nil]
  e[5] = e[34][K(0)]  -- GETINDEX? [a=34 b=0 c=5 d=nil]
  call(e[5], e[354])  -- CALL [a=5 b=2 c=354 d=nil] -- void call
  ::L_31::
  goto L_31
  ::L_32::
  goto L_32
  e[23] = {}  -- NEWTABLE [a=23 b=0 c=0 d=nil]
  e[24] = {}  -- NEWTABLE [a=24 b=0 c=0 d=nil]
  e[23][K(54)] = e[99]  -- SETTABLE [a=23 b=54 c=99 d=41] -- settable/void-call (inferred)
  e[23][K(125)] = e[4]  -- SETTABLE [a=23 b=125 c=4 d=43] -- settable/void-call (inferred)
  e[24][K(29)] = e[33]  -- SETTABLE [a=24 b=29 c=33 d=32] -- settable/void-call (inferred)
  e[29][K(1)] = e[22]  -- SETTABLE/CALL [a=29 b=1 c=22 d=nil] -- settable/void-call (inferred)
  ::L_39::
  goto L_39
  e[250] = e[250]["sub"]  -- GETTABLE [a=250 b=1 c=2099 d=nil]  -- = "sub"
  e[5] = e[5][K(4)]  -- GETTABLE/CLOSURE [a=5 b=4 c=98 d=nil]
  call(e[5], e[725])  -- CALL [a=5 b=2 c=725 d=nil] -- void call
  e[3] = 4  -- LOADK [a=3 b=70 c=226 d=4]
  e[5] = e[3][4]  -- GETTABLE/CLOSURE? [a=3 b=0 c=5 d=nil]  -- = 4
  goto L_45
  ::L_46::
  goto L_46
  ::L_47::
  goto L_47
  e[26] = {}  -- NEWTABLE [a=26 b=0 c=0 d=nil]
  e[23] = {}  -- NEWTABLE [a=23 b=0 c=0 d=nil]
  e[24] = {}  -- NEWTABLE [a=24 b=0 c=0 d=nil]
  e[25] = {}  -- NEWTABLE [a=0 b=25 c=0 d=nil]
  e[25][K(3)] = e[110]  -- SETTABLE [a=25 b=3 c=110 d=12] -- settable/void-call (inferred)
  e[25][K(100)] = e[4]  -- SETTABLE [a=25 b=100 c=4 d=14] -- settable/void-call (inferred)
  e[23][K(118)] = e[4]  -- SETTABLE [a=23 b=118 c=4 d=13] -- settable/void-call (inferred)
  e[25][K(118)] = e[122]  -- SETTABLE [a=25 b=118 c=122 d=13] -- settable/void-call (inferred)
  e[26][K(88)] = e[48]  -- SETTABLE [a=26 b=88 c=48 d=9] -- settable/void-call (inferred)
  e[24][K(40)] = e[16]  -- SETTABLE [a=24 b=40 c=16 d=47] -- settable/void-call (inferred)
  e[29][K(174)] = e[22]  -- SETTABLE/CALL [a=29 b=174 c=22 d=nil] -- settable/void-call (inferred)
  goto L_1
  e[359] = {}  -- NEWTABLE [a=374 b=359 c=40 d=nil]
end

local function proto18(...)  -- 9 instrs, 5 blocks (structured)
  local e = regs
  ::L_1::
  call(e[322], e[58])  -- CALL? [a=322 b=121 c=58 d=nil] -- void call
  ::L_8::
  goto L_1
  e[0] = {}  -- NEWTABLE [a=0 b=3 c=0 d=nil]
  e[4] = e[4]["concat"]  -- GETTABLE [a=4 b=1 c=139 d=nil]  -- = "concat"
  e[3] = e[3][K(2)]  -- GETTABLE/CLOSURE [a=3 b=2 c=4 d=nil]
  e[4] = e[3][K(0)]  -- GETTABLE/CLOSURE? [a=3 b=0 c=4 d=nil]
  goto L_8
  do return end  -- JMP/RETURN [a=0 b=0 c=4 d=nil]
end

local function proto19(...)  -- 157 instrs, 62 blocks (structured)
  local e = regs
  ::L_1::
  ::L_113::
  ::L_73::
  ::L_59::
  ::L_40::
  ::L_128::
  ::L_21::
  ::L_142::
  ::L_107::
  ::L_153::
  ::L_8::
  ::L_28::
  ::L_118::
  ::L_97::
  ::L_75::
  ::L_131::
  goto L_1
  e[37] = {}  -- NEWTABLE [a=37 b=0 c=0 d=nil]
  e[38] = {}  -- NEWTABLE [a=38 b=0 c=0 d=nil]
  e[37][K(68)] = e[4]  -- SETTABLE [a=37 b=68 c=4 d=76] -- settable/void-call (inferred)
  e[38][K(88)] = e[115]  -- SETTABLE [a=38 b=88 c=115 d=9] -- settable/void-call (inferred)
  e[43][K(103)] = e[36]  -- SETTABLE/CALL [a=43 b=103 c=36 d=nil] -- settable/void-call (inferred)
  goto L_8
  if e[1] then do return end else goto L_11 end
  ::L_11::
  goto L_48
  e[17] = e[4][K(0)]  -- GETTABLE/CLOSURE? [a=4 b=0 c=17 d=nil]
  e[18] = e[185][K(0)]  -- GETTABLE/CLOSURE? [a=185 b=0 c=18 d=nil]
  ::L_14::
  e[19] = e[7][58]  -- GETTABLE/CLOSURE? [a=7 b=0 c=19 d=nil]  -- = 58
  e[20] = e[3][K(0)]  -- GETTABLE/CLOSURE? [a=3 b=0 c=20 d=nil]
  ::L_16::
  goto L_60
  e[18] = e[11][K(0)]  -- GETTABLE/CLOSURE? [a=11 b=0 c=18 d=nil]
  e[19] = e[3][K(0)]  -- GETTABLE/CLOSURE? [a=3 b=0 c=19 d=nil]
  e[20] = e[4][K(0)]  -- GETTABLE/CLOSURE? [a=4 b=0 c=20 d=nil]
  e[21] = e[7][7]  -- GETTABLE/CLOSURE? [a=7 b=0 c=21 d=nil]  -- = 7
  goto L_21
  e[1] = e[18]  -- MOVE [a=18 b=1 c=599 d=nil]
  e[16] = e[7][58]  -- GETTABLE/CLOSURE? [a=7 b=0 c=16 d=nil]  -- = 58
  e[17] = e[6][K(0)]  -- GETTABLE/CLOSURE? [a=6 b=0 c=17 d=nil]
  e[18] = e[9][K(0)]  -- GETTABLE/CLOSURE? [a=9 b=0 c=18 d=nil]
  e[19] = e[5][K(0)]  -- GETTABLE/CLOSURE? [a=5 b=0 c=19 d=nil]
  e[20] = e[10][K(0)]  -- GETTABLE/CLOSURE? [a=10 b=0 c=20 d=nil]
  goto L_28
  e[7] = e[18][58]  -- GETTABLE/CLOSURE? [a=18 b=0 c=7 d=nil]  -- = 58
  if e[1] then do return end else goto L_31 end
  ::L_31::
  goto L_62
  e[38] = {}  -- NEWTABLE [a=38 b=0 c=0 d=nil]
  e[40] = {}  -- NEWTABLE [a=40 b=0 c=0 d=nil]
  e[37] = {}  -- NEWTABLE [a=37 b=0 c=0 d=nil]
  e[40][K(301)] = e[979]  -- SETTABLE [a=40 b=301 c=979 d=146] -- settable/void-call (inferred)
  e[37][K(301)] = e[23]  -- SETTABLE [a=37 b=301 c=23 d=146] -- settable/void-call (inferred)
  e[38][K(15)] = e[2210]  -- SETTABLE [a=38 b=15 c=2210 d=120] -- settable/void-call (inferred)
  call(e[43], e[36])  -- CALL? [a=43 b=0 c=36 d=nil] -- void call
  goto L_40
  e[14] = e[14]["resume"]  -- GETTABLE [a=14 b=1 c=74 d=nil]  -- = "resume"
  -- UNKNOWN op? [a=88 b=248 c=14 d=nil]
  e[176][K(215)] = e[14]  -- SETTABLE/CALL [a=176 b=215 c=14 d=nil] -- settable/void-call (inferred)
  call(e[6], e[81])  -- CALL [a=6 b=23 c=81 d=nil] -- void call
  e[212] = K(220)  -- LOADK_S [a=212 b=220 c=228 d=nil]
  e[15] = e[2][K(0)]  -- GETTABLE/CLOSURE? [a=2 b=0 c=15 d=nil]
  e[16] = e[12][K(0)]  -- GETTABLE/CLOSURE? [a=12 b=0 c=16 d=nil]
  ::L_48::
  goto L_11
  e[40] = {}  -- NEWTABLE [a=40 b=0 c=0 d=nil]
  e[39] = {}  -- NEWTABLE [a=0 b=39 c=0 d=nil]
  e[38] = {}  -- NEWTABLE [a=38 b=0 c=0 d=nil]
  e[40][K(59)] = e[1004]  -- SETTABLE [a=40 b=59 c=1004 d=42] -- settable/void-call (inferred)
  e[38][K(59)] = e[103]  -- SETTABLE [a=38 b=59 c=103 d=42] -- settable/void-call (inferred)
  e[39][K(59)] = e[93]  -- SETTABLE [a=39 b=59 c=93 d=42] -- settable/void-call (inferred)
  e[39][K(118)] = e[84]  -- SETTABLE [a=39 b=118 c=84 d=13] -- settable/void-call (inferred)
  e[38][K(76)] = e[89]  -- SETTABLE [a=38 b=76 c=89 d=98] -- settable/void-call (inferred)
  call(e[43], e[36])  -- CALL? [a=43 b=0 c=36 d=nil] -- void call
  goto L_59
  ::L_60::
  goto L_67
  e[21] = e[9][K(0)]  -- GETTABLE/CLOSURE? [a=9 b=0 c=21 d=nil]
  ::L_62::
  goto L_14
  goto L_76
  e[1] = e[14]  -- MOVE [a=14 b=1 c=531 d=nil]
  e[16] = e[12][K(0)]  -- GETTABLE/CLOSURE? [a=12 b=0 c=16 d=nil]
  e[17] = e[5][K(0)]  -- GETTABLE/CLOSURE? [a=5 b=0 c=17 d=nil]
  ::L_67::
  goto L_16
  e[38] = {}  -- NEWTABLE [a=38 b=0 c=0 d=nil]
  e[39] = {}  -- NEWTABLE [a=0 b=39 c=0 d=nil]
  e[39][K(119)] = e[100]  -- SETTABLE [a=39 b=119 c=100 d=22] -- settable/void-call (inferred)
  e[38][K(85)] = e[2195]  -- SETTABLE [a=38 b=85 c=2195 d=60] -- settable/void-call (inferred)
  call(e[43], e[36])  -- CALL? [a=43 b=0 c=36 d=nil] -- void call
  goto L_73
  if e[63] then goto L_1 else goto L_75 end  -- back-edge (loop)
  ::L_76::
  goto L_1
  e[25] = {}  -- NEWTABLE [a=25 b=0 c=0 d=nil]
  e[24] = {}  -- NEWTABLE [a=24 b=0 c=0 d=nil]
  e[31] = K(11)  -- LOADK_S [a=0 b=11 c=31 d=nil]
  e[32] = K(14)  -- LOADK_S [a=0 b=14 c=32 d=nil]
  e[33] = K(8)  -- LOADK_S [a=0 b=8 c=33 d=nil]
  e[34] = "<i8"  -- LOADK [a=34 b=77 c=247 d=<i8]
  e[35] = "131000000000000000000000"  -- LOADK [a=35 b=793 c=0 d=�       ]
  -- UNKNOWN op? [a=0 b=33 c=0 d=nil]
  e[32] = 131  -- LOADK_N [a=0 b=0 c=32 d=nil]
  call(e[75], e[227])  -- CALL [a=75 b=76 c=227 d=nil] -- void call
  e[33][K(82)] = e[113]  -- SETTABLE/CALL [a=33 b=82 c=113 d=33] -- settable/void-call (inferred)
  e[224] = K(40)  -- LOADK_S [a=224 b=40 c=56 d=nil]
  e[31] = 1  -- LOADK_N [a=0 b=31 c=0 d=nil]
  e[31] = e[31] + 27359  -- ADD [a=31 b=2243 c=31 d=27359]  -- = 27360
  e[31] = arith(e[31], e[441])  -- UNOP/arith? [a=31 b=31 c=441 d=nil]  -- = 21
  call(e[31], e[250])  -- CALL [a=31 b=24 c=250 d=nil] -- void call
  e[25][K(2361)] = e[1683]  -- SETTABLE [a=25 b=2361 c=1683 d=119] -- settable/void-call (inferred)
  call(e[35], e[23])  -- CALL? [a=35 b=0 c=23 d=nil] -- void call
  goto L_97
  e[37] = {}  -- NEWTABLE [a=37 b=0 c=0 d=nil]
  e[38] = {}  -- NEWTABLE [a=38 b=0 c=0 d=nil]
  e[40] = {}  -- NEWTABLE [a=40 b=0 c=0 d=nil]
  e[40][K(2218)] = e[112]  -- SETTABLE [a=40 b=2218 c=112 d=156] -- settable/void-call (inferred)
  e[38][K(2218)] = e[4]  -- SETTABLE [a=38 b=2218 c=4 d=156] -- settable/void-call (inferred)
  e[37][K(2229)] = e[23]  -- SETTABLE [a=37 b=2229 c=23 d=155] -- settable/void-call (inferred)
  e[38][K(28)] = e[1683]  -- SETTABLE [a=38 b=28 c=1683 d=78] -- settable/void-call (inferred)
  e[43][K(182)] = e[36]  -- SETTABLE/CALL [a=43 b=182 c=36 d=nil] -- settable/void-call (inferred)
  goto L_107
  e[38] = {}  -- NEWTABLE [a=38 b=0 c=0 d=nil]
  e[39] = {}  -- NEWTABLE [a=0 b=39 c=0 d=nil]
  e[39][K(57)] = e[4]  -- SETTABLE [a=39 b=57 c=4 d=77] -- settable/void-call (inferred)
  e[38][K(93)] = e[62]  -- SETTABLE [a=38 b=93 c=62 d=2] -- settable/void-call (inferred)
  e[43][K(162)] = e[36]  -- SETTABLE/CALL [a=43 b=162 c=36 d=nil] -- settable/void-call (inferred)
  goto L_113
  e[0] = {}  -- NEWTABLE [a=0 b=12 c=0 d=nil]
  call(e[13], e[0])  -- CALL [a=13 b=0 c=0 d=nil] -- void call
  e[6] = e[6][K(1)]  -- GETTABLE [a=6 b=1 c=18 d=nil]
  e[3] = e[0][K(0)]  -- GETTABLE/CLOSURE? [a=0 b=0 c=3 d=nil]
  goto L_118
  e[38] = {}  -- NEWTABLE [a=38 b=0 c=0 d=nil]
  e[40] = {}  -- NEWTABLE [a=40 b=0 c=0 d=nil]
  e[37] = {}  -- NEWTABLE [a=37 b=0 c=0 d=nil]
  e[40][K(1568)] = e[48]  -- SETTABLE [a=40 b=1568 c=48 d=86] -- settable/void-call (inferred)
  e[37][K(2)] = e[4]  -- SETTABLE [a=37 b=2 c=4 d=84] -- settable/void-call (inferred)
  e[38][K(587)] = e[122]  -- SETTABLE [a=38 b=587 c=122 d=143] -- settable/void-call (inferred)
  e[43][K(129)] = e[36]  -- SETTABLE/CALL [a=43 b=129 c=36 d=nil] -- settable/void-call (inferred)
  goto L_128
  e[8] = e[8][K(1)]  -- GETTABLE [a=8 b=1 c=18 d=nil]
  e[7] = 35  -- LOADK [a=7 b=564 c=0 d=35]
  goto L_131
  e[38] = {}  -- NEWTABLE [a=38 b=0 c=0 d=nil]
  e[38][K(1557)] = e[4]  -- SETTABLE [a=38 b=1557 c=4 d=141] -- settable/void-call (inferred)
  e[38][K(29)] = e[770]  -- SETTABLE [a=38 b=29 c=770 d=32] -- settable/void-call (inferred)
  call(e[43], e[36])  -- CALL? [a=43 b=0 c=36 d=nil] -- void call
  -- UNKNOWN op? [a=488 b=448 c=228 d=nil]
  e[6] = e[15][K(0)]  -- GETTABLE/CLOSURE? [a=15 b=0 c=6 d=nil]
  e[9] = e[16][K(0)]  -- GETTABLE/CLOSURE? [a=16 b=0 c=9 d=nil]
  e[8] = e[17][K(0)]  -- GETTABLE/CLOSURE? [a=17 b=0 c=8 d=nil]
  e[7] = e[18][58]  -- GETTABLE/CLOSURE? [a=18 b=169 c=7 d=nil]  -- = 58
  goto L_142
  -- UNKNOWN op? [a=14 b=8 c=50 d=nil]
  e[114][K(147)] = e[13]  -- SETTABLE/CALL [a=114 b=147 c=13 d=nil] -- settable/void-call (inferred)
  call(e[14], e[221])  -- CALL [a=14 b=137 c=221 d=nil] -- void call
  e[15] = K(151)  -- LOADK_S [a=15 b=151 c=35 d=nil]
  e[3] = e[15][K(0)]  -- GETTABLE/CLOSURE? [a=15 b=0 c=3 d=nil]
  e[12] = e[16][K(0)]  -- GETTABLE/CLOSURE? [a=16 b=0 c=12 d=nil]
  e[4] = e[17][K(0)]  -- GETTABLE/CLOSURE? [a=17 b=0 c=4 d=nil]
  goto L_153
  e[45] = e[8][K(0)]  -- GETTABLE/CLOSURE? [a=8 b=0 c=45 d=nil]
  if e[14] then goto L_8 end  -- back-edge (loop)
  -- UNKNOWN op? [a=14 b=217 c=13 d=nil]
  goto L_31
end

local function proto20(...)  -- 93 instrs, 35 blocks (structured)
  local e = regs
  ::L_1::
  ::L_52::
  -- UNKNOWN op? [a=34 b=251 c=353 d=nil]
  e[11] = e[6][K(0)]  -- GETTABLE/CLOSURE? [a=6 b=0 c=11 d=nil]
  e[12] = e[7][77]  -- GETTABLE/CLOSURE? [a=7 b=0 c=12 d=nil]  -- = 77
  ::L_83::
  ::L_8::
  if e[30] then goto L_60 end
  ::L_9::
  ::L_92::
  goto L_9
  ::L_60::
  e[23] = K(17)  -- LOADK_S [a=0 b=17 c=23 d=nil]
  e[24] = K(8)  -- LOADK_S [a=0 b=8 c=24 d=nil]
  -- UNKNOWN op? [a=25 b=6 c=0 d=>i8]
  e[26] = "000000000000000000000Z"  -- LOADK [a=26 b=1086 c=137 d=       Z]
  e[124] = 90  -- LOADK_N [a=0 b=124 c=0 d=nil]
  e[23] = 1  -- LOADK_N [a=0 b=0 c=23 d=nil]
  e[22] = 1  -- LOADK_N [a=0 b=0 c=22 d=nil]
  e[147][K(2215)] = e[22]  -- SETTABLE/CALL [a=147 b=2215 c=22 d=19748] -- settable/void-call (inferred)
  e[22][K(70)] = e[22]  -- SETTABLE/CALL [a=22 b=70 c=22 d=nil] -- settable/void-call (inferred)
  e[63][K(23)] = e[158]  -- SETTABLE/CALL [a=63 b=23 c=158 d=nil] -- settable/void-call (inferred)
  e[182][K(109)] = e[157]  -- SETTABLE/CALL [a=182 b=109 c=157 d=nil] -- settable/void-call (inferred)
  e[199] = K(228)  -- LOADK_S [a=199 b=228 c=145 d=nil]
  e[22] = arith(e[22], e[159])  -- UNOP/arith? [a=22 b=22 c=159 d=nil]  -- = 205
  call(e[22], e[30])  -- CALL [a=22 b=18 c=30 d=nil] -- void call
  e[16][K(42)] = e[119]  -- SETTABLE [a=16 b=42 c=119 d=10] -- settable/void-call (inferred)
  call(e[26], e[14])  -- CALL? [a=26 b=0 c=14 d=nil] -- void call
  ::L_76::
  ::L_29::
  goto L_8
  e[30] = {}  -- NEWTABLE [a=0 b=30 c=0 d=nil]
  e[29] = {}  -- NEWTABLE [a=29 b=0 c=0 d=nil]
  e[30][K(40)] = e[99]  -- SETTABLE [a=30 b=40 c=99 d=47] -- settable/void-call (inferred)
  ::L_5::
  e[29][K(28)] = e[119]  -- SETTABLE [a=29 b=28 c=119 d=78] -- settable/void-call (inferred)
  e[34][K(215)] = e[27]  -- SETTABLE/CALL [a=34 b=215 c=27 d=nil] -- settable/void-call (inferred)
  ::L_7::
  goto L_22
  ::L_10::
  goto L_56
  e[30] = {}  -- NEWTABLE [a=0 b=30 c=0 d=nil]
  e[29] = {}  -- NEWTABLE [a=29 b=0 c=0 d=nil]
  e[31] = {}  -- NEWTABLE [a=31 b=0 c=0 d=nil]
  e[28] = {}  -- NEWTABLE [a=28 b=0 c=0 d=nil]
  e[28][K(29)] = e[42]  -- SETTABLE [a=28 b=29 c=42 d=32] -- settable/void-call (inferred)
  e[30][K(29)] = e[23]  -- SETTABLE [a=30 b=29 c=23 d=32] -- settable/void-call (inferred)
  e[28][K(84)] = e[81]  -- SETTABLE [a=28 b=84 c=81 d=8] -- settable/void-call (inferred)
  e[31][K(127)] = e[94]  -- SETTABLE [a=31 b=127 c=94 d=31] -- settable/void-call (inferred)
  e[30][K(38)] = e[81]  -- SETTABLE [a=30 b=38 c=81 d=55] -- settable/void-call (inferred)
  e[29][K(97)] = e[81]  -- SETTABLE [a=29 b=97 c=81 d=79] -- settable/void-call (inferred)
  e[34][K(14)] = e[27]  -- SETTABLE/CALL [a=34 b=14 c=27 d=nil] -- settable/void-call (inferred)
  ::L_22::
  goto L_7
  e[0] = {}  -- NEWTABLE [a=0 b=7 c=0 d=nil]
  if e[81] then goto L_78 end
  ::L_25::
  goto L_76
  e[10] = e[2][K(0)]  -- GETTABLE/CLOSURE? [a=2 b=0 c=10 d=nil]
  e[11] = e[6][K(0)]  -- GETTABLE/CLOSURE? [a=6 b=0 c=11 d=nil]
  e[12] = e[7][58]  -- GETTABLE/CLOSURE? [a=7 b=0 c=12 d=nil]  -- = 58
  goto L_29
  goto L_42
  -- UNKNOWN op? [a=8 b=1 c=769 d=nil]
  e[234] = e[58][K(0)]  -- GETTABLE/CLOSURE? [a=58 b=0 c=234 d=nil]
  e[201][K(89)] = e[11]  -- SETTABLE/CALL [a=201 b=89 c=11 d=nil] -- settable/void-call (inferred)
  call(e[3], e[54])  -- CALL [a=3 b=103 c=54 d=nil] -- void call
  e[221] = K(168)  -- LOADK_S [a=221 b=168 c=51 d=nil]
  e[142][K(181)] = e[12]  -- SETTABLE/CALL [a=142 b=181 c=12 d=nil] -- settable/void-call (inferred)
  call(e[7], e[87])  -- CALL [a=7 b=4 c=87 d=nil] -- void call
  e[194] = K(209)  -- LOADK_S [a=194 b=209 c=154 d=nil]
  if e[8] then goto L_5 end  -- back-edge (loop)
  e[6] = e[8][K(0)]  -- GETTABLE/CLOSURE? [a=8 b=0 c=6 d=nil]
  e[7] = e[9][38]  -- GETTABLE/CLOSURE? [a=9 b=0 c=7 d=nil]  -- = 38
  ::L_42::
  goto L_48
  e[8] = e[8]["create"]  -- GETTABLE [a=8 b=1 c=1802 d=nil]  -- = "create"
  e[5] = e[5][K(4)]  -- GETTABLE/CLOSURE [a=5 b=4 c=8 d=nil]
  e[7] = 58  -- LOADK [a=7 b=407 c=0 d=58]
  e[8] = (e[8] == e[0])  -- COMPARE [a=8 b=1106 c=0 d=48937]  -- = 48937
  e[9] = e[62][K(0)]  -- GETTABLE/CLOSURE? [a=62 b=0 c=9 d=nil]
  ::L_48::
  goto L_25
  call(e[8], e[0])  -- CALL [a=8 b=0 c=0 d=nil] -- void call
  e[9] = e[5][K(0)]  -- GETTABLE/CLOSURE? [a=5 b=0 c=9 d=nil]
  e[10] = e[2][K(0)]  -- GETTABLE/CLOSURE? [a=2 b=0 c=10 d=nil]
  goto L_52
  ::L_53::
  goto L_83
  e[2] = e[2][K(1)]  -- GETTABLE [a=2 b=1 c=18 d=nil]
  e[178] = 77  -- LOADK [a=178 b=1327 c=0 d=77]
  ::L_56::
  goto L_48
  e[16] = {}  -- NEWTABLE [a=16 b=0 c=0 d=nil]
  e[18] = {}  -- NEWTABLE [a=18 b=0 c=0 d=nil]
  e[22] = K(11)  -- LOADK_S [a=0 b=11 c=22 d=nil]
  goto L_60
  ::L_78::
  goto L_1
  goto L_10
  e[31] = {}  -- NEWTABLE [a=31 b=0 c=0 d=nil]
  e[29] = {}  -- NEWTABLE [a=29 b=0 c=0 d=nil]
  e[28] = {}  -- NEWTABLE [a=28 b=0 c=0 d=nil]
  e[28][K(34)] = e[4]  -- SETTABLE [a=28 b=34 c=4 d=63] -- settable/void-call (inferred)
  e[31][K(91)] = e[8]  -- SETTABLE [a=31 b=91 c=8 d=62] -- settable/void-call (inferred)
  e[29][K(98)] = e[124]  -- SETTABLE [a=29 b=98 c=124 d=64] -- settable/void-call (inferred)
  e[29][K(35)] = e[88]  -- SETTABLE [a=29 b=35 c=88 d=53] -- settable/void-call (inferred)
  call(e[34], e[27])  -- CALL? [a=34 b=0 c=27 d=nil] -- void call
  goto L_92
  goto L_53
end

local function proto21(...)  -- 11 instrs, 7 blocks (structured)
  local e = regs
  ::L_1::
  ::L_9::
  goto L_1
  ::L_2::
  goto L_5
  e[0] = {}  -- NEWTABLE [a=0 b=4 c=0 d=nil]
  e[5] = e[5]["rep"]  -- GETTABLE [a=5 b=1 c=564 d=nil]  -- = "rep"
  ::L_5::
  e[2] = e[2][K(3)]  -- GETTABLE/CLOSURE [a=2 b=3 c=5 d=nil]
  e[4] = 38  -- LOADK [a=4 b=393 c=0 d=38]
  e[5] = e[2][K(0)]  -- GETTABLE/CLOSURE? [a=2 b=0 c=5 d=nil]
  e[6] = e[4][38]  -- GETTABLE/CLOSURE? [a=4 b=0 c=6 d=nil]  -- = 38
  goto L_9
  goto L_2
  -- UNKNOWN op? [a=126 b=418 c=408 d=nil]
end

local function proto22(...)  -- 95 instrs, 34 blocks (structured)
  local e = regs
  ::L_1::
  ::L_35::
  ::L_89::
  -- UNKNOWN op? [a=48 b=443 c=210 d=nil]
  -- UNKNOWN op? [a=8 b=0 c=0 d=nil]
  e[191] = e[3][K(0)]  -- GETTABLE/CLOSURE? [a=3 b=0 c=191 d=nil]
  e[10] = e[4][K(0)]  -- GETTABLE/CLOSURE? [a=4 b=0 c=10 d=nil]
  e[11] = e[7][K(0)]  -- GETTABLE/CLOSURE? [a=7 b=0 c=11 d=nil]
  e[12] = e[2][7]  -- GETTABLE/CLOSURE? [a=2 b=0 c=12 d=nil]  -- = 7
  ::L_8::
  e[26] = {}  -- NEWTABLE [a=26 b=0 c=0 d=nil]
  e[28] = {}  -- NEWTABLE [a=0 b=28 c=0 d=nil]
  ::L_10::
  e[26][K(53)] = e[4]  -- SETTABLE [a=26 b=53 c=4 d=50] -- settable/void-call (inferred)
  e[28][K(53)] = e[124]  -- SETTABLE [a=28 b=53 c=124 d=50] -- settable/void-call (inferred)
  e[26][K(128)] = e[73]  -- SETTABLE [a=26 b=128 c=73 d=51] -- settable/void-call (inferred)
  e[27][K(106)] = e[124]  -- SETTABLE [a=27 b=106 c=124 d=36] -- settable/void-call (inferred)
  call(e[32], e[25])  -- CALL? [a=32 b=0 c=25 d=nil] -- void call
  ::L_15::
  ::L_29::
  goto L_89
  if e[25] then goto L_10 end  -- back-edge (loop)
  ::L_3::
  goto L_5
  ::L_4::
  goto L_65
  ::L_5::
  goto L_15
  ::L_6::
  goto L_23
  e[27] = {}  -- NEWTABLE [a=27 b=0 c=0 d=nil]
  goto L_8
  e[26] = {}  -- NEWTABLE [a=26 b=0 c=0 d=nil]
  e[29] = {}  -- NEWTABLE [a=29 b=0 c=0 d=nil]
  e[27] = {}  -- NEWTABLE [a=27 b=0 c=0 d=nil]
  e[29][K(7)] = e[8]  -- SETTABLE [a=29 b=7 c=8 d=82] -- settable/void-call (inferred)
  e[26][K(44)] = e[88]  -- SETTABLE [a=26 b=44 c=88 d=83] -- settable/void-call (inferred)
  e[27][K(99)] = e[120]  -- SETTABLE [a=27 b=99 c=120 d=5] -- settable/void-call (inferred)
  e[32][K(141)] = e[25]  -- SETTABLE/CALL [a=32 b=141 c=25 d=nil] -- settable/void-call (inferred)
  ::L_23::
  goto L_81
  goto L_46
  e[8] = e[8]["pack"]  -- GETTABLE [a=8 b=1 c=82 d=nil]  -- = "pack"
  e[3] = e[3][K(5)]  -- GETTABLE/CLOSURE [a=3 b=5 c=8 d=nil]
  e[2] = 7  -- LOADK [a=2 b=319 c=0 d=7]
  goto L_29
  e[8] = e[8]["unpack"]  -- GETTABLE [a=8 b=1 c=1829 d=nil]  -- = "unpack"
  e[4] = e[4][K(146)]  -- GETTABLE/CLOSURE [a=4 b=146 c=8 d=nil]
  call(e[53], e[131])  -- CALL [a=53 b=18 c=131 d=nil] -- void call
  e[2][K(1363)] = e[14]  -- SETTABLE/CALL [a=2 b=1363 c=14 d=72] -- settable/void-call (inferred)
  e[173] = K(128)  -- LOADK_S [a=173 b=128 c=0 d=nil]
  goto L_35
  ::L_36::
  goto L_6
  e[29] = {}  -- NEWTABLE [a=29 b=0 c=0 d=nil]
  e[27] = {}  -- NEWTABLE [a=27 b=0 c=0 d=nil]
  e[26] = {}  -- NEWTABLE [a=26 b=0 c=0 d=nil]
  e[29][K(21)] = e[279]  -- SETTABLE [a=29 b=21 c=279 d=90] -- settable/void-call (inferred)
  e[26][K(50)] = e[88]  -- SETTABLE [a=26 b=50 c=88 d=91] -- settable/void-call (inferred)
  e[26][K(83)] = e[42]  -- SETTABLE [a=26 b=83 c=42 d=75] -- settable/void-call (inferred)
  e[27][K(2199)] = e[92]  -- SETTABLE [a=27 b=2199 c=92 d=88] -- settable/void-call (inferred)
  e[32][K(63)] = e[25]  -- SETTABLE/CALL [a=32 b=63 c=25 d=nil] -- settable/void-call (inferred)
  ::L_45::
  goto L_70
  ::L_46::
  goto L_73
  e[16] = {}  -- NEWTABLE [a=16 b=0 c=0 d=nil]
  e[22] = K(18)  -- LOADK_S [a=0 b=18 c=22 d=nil]
  e[23] = K(13)  -- LOADK_S [a=0 b=13 c=23 d=nil]
  e[118] = "<b l>=>"  -- LOADK [a=118 b=838 c=157 d=<b]
  e[11] = 9  -- LOADK_N [a=0 b=0 c=11 d=nil]
  call(e[122], e[138])  -- CALL [a=122 b=4 c=138 d=nil] -- void call
  e[24][K(1828)] = e[242]  -- SETTABLE/CALL [a=24 b=1828 c=242 d=12] -- settable/void-call (inferred)
  e[35] = K(252)  -- LOADK_S [a=35 b=252 c=226 d=nil]
  e[22] = 36864  -- LOADK_N [a=0 b=22 c=0 d=nil]
  e[23] = K(13)  -- LOADK_S [a=0 b=13 c=23 d=nil]
  e[24] = "=c158= l>f="  -- LOADK [a=24 b=1438 c=0 d==c158=]
  e[23] = 170  -- LOADK_N [a=0 b=0 c=23 d=nil]
  e[22] = arith(e[22], e[22])  -- ARITH [a=23 b=22 c=22 d=nil]  -- = 36694
  e[22] = e[22] + -30595  -- ADD [a=22 b=707 c=22 d=-30595]  -- = 6099
  e[22] = arith(e[22], e[537])  -- UNOP/arith? [a=22 b=22 c=537 d=nil]  -- = 1
  call(e[22], e[66])  -- CALL [a=22 b=16 c=66 d=nil] -- void call
  e[16][K(104)] = e[92]  -- SETTABLE [a=16 b=104 c=92 d=25] -- settable/void-call (inferred)
  call(e[24], e[14])  -- CALL? [a=24 b=0 c=14 d=nil] -- void call
  ::L_65::
  goto L_87
  e[27] = {}  -- NEWTABLE [a=27 b=0 c=0 d=nil]
  e[27][K(127)] = e[99]  -- SETTABLE [a=27 b=127 c=99 d=31] -- settable/void-call (inferred)
  e[27][K(9)] = e[16]  -- SETTABLE [a=27 b=9 c=16 d=4] -- settable/void-call (inferred)
  call(e[32], e[25])  -- CALL? [a=32 b=0 c=25 d=nil] -- void call
  ::L_70::
  goto L_1
  e[0] = {}  -- NEWTABLE [a=0 b=7 c=0 d=nil]
  if e[52] then goto L_3 end  -- back-edge (loop)
  ::L_73::
  goto L_45
  e[229] = e[8]  -- MOVE [a=8 b=229 c=490 d=nil]
  e[1] = e[7][K(0)]  -- GETTABLE/CLOSURE? [a=7 b=0 c=1 d=nil]
  e[125][K(141)] = e[11]  -- SETTABLE/CALL [a=125 b=141 c=11 d=nil] -- settable/void-call (inferred)
  call(e[6], e[15])  -- CALL [a=6 b=185 c=15 d=nil] -- void call
  e[132] = K(85)  -- LOADK_S [a=132 b=85 c=33 d=nil]
  e[8] = K(8)  -- LOADK_N [a=0 b=8 c=4 d=nil]
  e[7] = e[8][K(0)]  -- GETTABLE/CLOSURE? [a=8 b=0 c=7 d=nil]
  ::L_81::
  goto L_4
  -- UNKNOWN op? [a=8 b=1939 c=0 d=4286]
  e[33] = e[3][K(0)]  -- GETTABLE/CLOSURE? [a=3 b=0 c=33 d=nil]
  e[10] = e[4][K(0)]  -- GETTABLE/CLOSURE? [a=4 b=0 c=10 d=nil]
  e[11] = e[7][K(0)]  -- GETTABLE/CLOSURE? [a=7 b=0 c=11 d=nil]
  e[12] = e[2][58]  -- GETTABLE/CLOSURE? [a=2 b=0 c=12 d=nil]  -- = 58
  ::L_87::
  goto L_8
  goto L_36
end

local function proto23(...)  -- 9 instrs, 6 blocks (structured)
  local e = regs
  ::L_1::
  ::L_5::
  goto L_1
  e[0] = {}  -- NEWTABLE [a=0 b=3 c=0 d=nil]
  e[4] = e[4]["defer"]  -- GETTABLE [a=4 b=1 c=736 d=nil]  -- = "defer"
  e[2] = e[2][K(3)]  -- GETTABLE/CLOSURE [a=2 b=3 c=4 d=nil]
  goto L_5
  e[4] = e[2][K(0)]  -- GETTABLE/CLOSURE? [a=2 b=0 c=4 d=nil]
  do return end  -- JMP/RETURN [a=0 b=0 c=4 d=nil]
  -- UNKNOWN op? [a=298 b=27 c=355 d=nil]
end

local function proto24(...)  -- 63 instrs, 27 blocks (structured)
  local e = regs
  ::L_1::
  e[238] = K(264)  -- LOADK_N [a=414 b=264 c=238 d=nil]
  ::L_36::
  ::L_33::
  ::L_58::
  ::L_14::
  goto L_36
  e[0] = {}  -- NEWTABLE [a=0 b=5 c=0 d=nil]
  -- UNKNOWN op? [a=2 b=1 c=18 d=nil]
  e[207] = e[207][K(1)]  -- GETTABLE [a=207 b=1 c=18 d=nil]
  call(e[6], e[59])  -- CALL [a=6 b=41 c=59 d=nil] -- void call
  e[58][K(1)] = e[196]  -- SETTABLE/CALL [a=58 b=1 c=196 d=nil] -- settable/void-call (inferred)
  e[234][K(252)] = e[18]  -- SETTABLE/CALL [a=234 b=252 c=18 d=nil] -- settable/void-call (inferred)
  e[193] = K(169)  -- LOADK_S [a=193 b=169 c=5 d=nil]
  call(e[6], e[909])  -- CALL [a=6 b=4 c=909 d=nil] -- void call
  e[5] = 62  -- LOADK [a=5 b=1913 c=0 d=62]
  e[6] = e[5][62]  -- GETTABLE/CLOSURE? [a=5 b=0 c=6 d=nil]  -- = 62
  e[7] = e[3][K(0)]  -- GETTABLE/CLOSURE? [a=3 b=0 c=7 d=nil]
  e[8] = e[2][K(0)]  -- GETTABLE/CLOSURE? [a=2 b=0 c=8 d=nil]
  goto L_14
  if e[18] then goto L_26 end
  ::L_16::
  goto L_41
  e[162] = K(1092)  -- LOADK [a=162 b=1092 c=34 d=59]
  ::L_18::
  goto L_26
  ::L_19::
  goto L_59
  ::L_20::
  goto L_50
  e[24] = {}  -- NEWTABLE [a=24 b=0 c=0 d=nil]
  e[22] = {}  -- NEWTABLE [a=22 b=0 c=0 d=nil]
  e[24][K(95)] = e[1793]  -- SETTABLE [a=24 b=95 c=1793 d=61] -- settable/void-call (inferred)
  e[22][K(55)] = e[114]  -- SETTABLE [a=22 b=55 c=114 d=37] -- settable/void-call (inferred)
  call(e[27], e[20])  -- CALL? [a=27 b=0 c=20 d=nil] -- void call
  ::L_26::
  goto L_18
  e[18] = arith(e[18], e[2155])  -- ARITH [a=18 b=18 c=2155 d=nil]  -- = -196
  e[18] = e[18] + 15848  -- ADD [a=18 b=376 c=18 d=15848]  -- = 15652
  e[18] = arith(e[18], e[655])  -- UNOP/arith? [a=18 b=18 c=655 d=nil]  -- = 6
  call(e[18], e[101])  -- CALL [a=18 b=12 c=101 d=nil] -- void call
  e[12][K(117)] = e[52]  -- SETTABLE [a=12 b=117 c=52 d=19] -- settable/void-call (inferred)
  call(e[19], e[10])  -- CALL? [a=19 b=0 c=10 d=nil] -- void call
  goto L_33
  goto L_42
  ::L_37::
  goto L_20
  call(e[136], e[87])  -- CALL [a=136 b=95 c=87 d=nil] -- void call
  e[18][K(560)] = e[243]  -- SETTABLE/CALL [a=18 b=560 c=243 d=232] -- settable/void-call (inferred)
  e[230] = K(89)  -- LOADK_S [a=230 b=89 c=241 d=nil]
  ::L_41::
  goto L_19
  ::L_42::
  goto L_16
  e[24] = {}  -- NEWTABLE [a=24 b=0 c=0 d=nil]
  e[22] = {}  -- NEWTABLE [a=22 b=0 c=0 d=nil]
  e[23] = {}  -- NEWTABLE [a=0 b=23 c=0 d=nil]
  e[24][K(111)] = e[41]  -- SETTABLE [a=24 b=111 c=41 d=3] -- settable/void-call (inferred)
  e[23][K(9)] = e[111]  -- SETTABLE [a=23 b=9 c=111 d=4] -- settable/void-call (inferred)
  e[22][K(126)] = e[16]  -- SETTABLE [a=22 b=126 c=16 d=34] -- settable/void-call (inferred)
  e[27][K(133)] = e[20]  -- SETTABLE/CALL [a=27 b=133 c=20 d=nil] -- settable/void-call (inferred)
  ::L_50::
  goto L_1
  e[22] = {}  -- NEWTABLE [a=22 b=0 c=0 d=nil]
  e[21] = {}  -- NEWTABLE [a=21 b=0 c=0 d=nil]
  e[23] = {}  -- NEWTABLE [a=0 b=23 c=0 d=nil]
  e[23][K(20)] = e[114]  -- SETTABLE [a=23 b=20 c=114 d=17] -- settable/void-call (inferred)
  e[21][K(20)] = e[4]  -- SETTABLE [a=21 b=20 c=4 d=17] -- settable/void-call (inferred)
  e[22][K(110)] = e[100]  -- SETTABLE [a=22 b=110 c=100 d=20] -- settable/void-call (inferred)
  e[27][K(1)] = e[20]  -- SETTABLE/CALL [a=27 b=1 c=20 d=nil] -- settable/void-call (inferred)
  goto L_58
  ::L_59::
  do return end  -- JMP/RETURN [a=4 b=210 c=0 d=nil]
  e[12] = {}  -- NEWTABLE [a=12 b=0 c=0 d=nil]
  -- UNKNOWN op? [a=2122 b=889 c=18 d=468]
  if e[18] then goto L_19 end  -- back-edge (loop)
  goto L_37
end

local function proto25(...)  -- 117 instrs, 51 blocks (structured)
  local e = regs
  ::L_1::
  -- UNKNOWN op? [a=0 b=59 c=0 d=nil]
  e[0] = {}  -- NEWTABLE [a=0 b=10 c=0 d=nil]
  ::L_42::
  e[411] = {}  -- NEWTABLE [a=81 b=376 c=411 d=nil]
  e[33] = {}  -- NEWTABLE [a=33 b=0 c=0 d=nil]
  e[35] = {}  -- NEWTABLE [a=35 b=0 c=0 d=nil]
  e[35][K(106)] = e[53]  -- SETTABLE [a=35 b=106 c=53 d=36] -- settable/void-call (inferred)
  e[35][K(60)] = e[41]  -- SETTABLE [a=35 b=60 c=41 d=35] -- settable/void-call (inferred)
  e[33][K(7)] = e[16]  -- SETTABLE [a=33 b=7 c=16 d=82] -- settable/void-call (inferred)
  call(e[38], e[31])  -- CALL? [a=38 b=0 c=31 d=nil] -- void call
  ::L_81::
  goto L_1
  e[11] = e[11][K(1)]  -- GETTABLE [a=11 b=1 c=2274 d=nil]
  call(e[11], e[102])  -- CALL [a=11 b=5 c=102 d=nil] -- void call
  ::L_4::
  e[11] = e[160][K(0)]  -- GETINDEX? [a=160 b=0 c=11 d=nil]
  call(e[11], e[2367])  -- CALL [a=11 b=5 c=2367 d=nil] -- void call
  ::L_6::
  goto L_33
  e[14] = e[6][117]  -- GETTABLE/CLOSURE? [a=6 b=0 c=14 d=nil]  -- = 117
  e[15] = e[8][K(0)]  -- GETTABLE/CLOSURE? [a=8 b=0 c=15 d=nil]
  e[16] = e[2][K(0)]  -- GETTABLE/CLOSURE? [a=2 b=0 c=16 d=nil]
  ::L_10::
  goto L_60
  ::L_11::
  -- UNKNOWN op? [a=11 b=1 c=1889 d=nil]
  e[13] = e[6][5]  -- GETTABLE/CLOSURE? [a=6 b=0 c=13 d=nil]  -- = 5
  e[14] = e[10][K(0)]  -- GETTABLE/CLOSURE? [a=10 b=0 c=14 d=nil]
  ::L_14::
  goto L_97
  e[34] = {}  -- NEWTABLE [a=0 b=34 c=0 d=nil]
  e[33] = {}  -- NEWTABLE [a=33 b=0 c=0 d=nil]
  e[34][K(94)] = e[103]  -- SETTABLE [a=34 b=94 c=103 d=52] -- settable/void-call (inferred)
  e[33][K(85)] = e[128]  -- SETTABLE [a=33 b=85 c=128 d=60] -- settable/void-call (inferred)
  call(e[38], e[31])  -- CALL? [a=38 b=0 c=31 d=nil] -- void call
  ::L_20::
  goto L_51
  if e[42] then goto L_91 end
  ::L_25::
  goto L_38
  e[33] = {}  -- NEWTABLE [a=33 b=0 c=0 d=nil]
  e[32] = {}  -- NEWTABLE [a=32 b=0 c=0 d=nil]
  e[34] = {}  -- NEWTABLE [a=0 b=34 c=0 d=nil]
  ::L_29::
  e[34][K(123)] = e[23]  -- SETTABLE [a=34 b=123 c=23 d=102] -- settable/void-call (inferred)
  e[32][K(123)] = e[4]  -- SETTABLE [a=32 b=123 c=4 d=102] -- settable/void-call (inferred)
  e[33][K(101)] = e[86]  -- SETTABLE [a=33 b=101 c=86 d=59] -- settable/void-call (inferred)
  call(e[38], e[31])  -- CALL? [a=38 b=0 c=31 d=nil] -- void call
  ::L_33::
  goto L_101
  e[8] = e[8][K(1)]  -- GETTABLE [a=8 b=1 c=18 d=nil]
  -- UNKNOWN op? [a=11 b=1 c=18 d=nil]
  e[11][K(5)] = e[1935]  -- SETTABLE/CALL [a=11 b=5 c=1935 d=nil] -- settable/void-call (inferred)
  e[3] = e[3][K(1)]  -- GETTABLE [a=3 b=1 c=18 d=nil]
  ::L_38::
  goto L_58
  e[11] = e[11]["status"]  -- GETTABLE [a=11 b=1 c=167 d=nil]  -- = "status"
  e[2] = e[2][K(4)]  -- GETTABLE/CLOSURE [a=2 b=4 c=11 d=nil]
  e[6] = 5  -- LOADK [a=6 b=18 c=0 d=5]
  goto L_42
  if e[115] then goto L_29 end  -- back-edge (loop)
  ::L_44::
  goto L_48
  e[11] = e[11]["yield"]  -- GETTABLE [a=11 b=1 c=1102 d=nil]  -- = "yield"
  e[11] = e[11][K(4)]  -- GETTABLE/CLOSURE [a=11 b=4 c=11 d=nil]
  call(e[11], e[909])  -- CALL [a=11 b=5 c=909 d=nil] -- void call
  ::L_48::
  goto L_44
  ::L_50::
  goto L_62
  ::L_51::
  goto L_10
  e[159] = e[159]["close"]  -- GETTABLE [a=159 b=1 c=31 d=nil]  -- = "close"
  e[7] = e[7][K(4)]  -- GETTABLE/CLOSURE [a=7 b=4 c=11 d=nil]
  e[11] = e[11]["wrap"]  -- GETTABLE [a=11 b=1 c=933 d=nil]  -- = "wrap"
  e[9] = e[9][K(4)]  -- GETTABLE/CLOSURE [a=9 b=4 c=11 d=nil]
  ::L_56::
  goto L_81
  ::L_58::
  goto L_42
  goto L_25
  ::L_60::
  goto L_14
  e[17] = e[10][K(0)]  -- GETTABLE/CLOSURE? [a=10 b=0 c=17 d=nil]
  ::L_62::
  goto L_11
  e[33] = {}  -- NEWTABLE [a=33 b=0 c=0 d=nil]
  e[34] = {}  -- NEWTABLE [a=0 b=34 c=0 d=nil]
  e[35] = {}  -- NEWTABLE [a=35 b=0 c=0 d=nil]
  e[32] = {}  -- NEWTABLE [a=32 b=0 c=0 d=nil]
  e[32][K(46)] = e[4]  -- SETTABLE [a=32 b=46 c=4 d=87] -- settable/void-call (inferred)
  e[34][K(72)] = e[4]  -- SETTABLE [a=34 b=72 c=4 d=89] -- settable/void-call (inferred)
  e[35][K(72)] = e[48]  -- SETTABLE [a=35 b=72 c=48 d=89] -- settable/void-call (inferred)
  e[32][K(72)] = e[4]  -- SETTABLE [a=32 b=72 c=4 d=89] -- settable/void-call (inferred)
  e[33][K(53)] = e[121]  -- SETTABLE [a=33 b=53 c=121 d=50] -- settable/void-call (inferred)
  call(e[38], e[31])  -- CALL? [a=38 b=0 c=31 d=nil] -- void call
  goto L_106
  e[23] = {}  -- NEWTABLE [a=23 b=0 c=0 d=nil]
  e[21] = {}  -- NEWTABLE [a=21 b=0 c=0 d=nil]
  e[27] = K(14)  -- LOADK_S [a=0 b=14 c=27 d=nil]
  e[28] = K(7)  -- LOADK_S [a=0 b=7 c=28 d=nil]
  e[29] = 319  -- LOADK [a=29 b=1947 c=111 d=319]
  e[30] = 31  -- LOADK [a=30 b=736 c=0 d=31]
  e[89][2147483807] = e[44]  -- SETTABLE/CALL [a=89 b=28 c=44 d=nil] -- settable/void-call (inferred)
  e[29] = 371  -- LOADK [a=29 b=2085 c=0 d=371]
  ::L_91::
  e[27] = 2147484159  -- LOADK_N [a=0 b=27 c=0 d=nil]
  e[27] = e[27] + -2147469792  -- ADD [a=27 b=2005 c=27 d=-2147469792]  -- = 14367
  e[27] = arith(e[27], e[267])  -- UNOP/arith? [a=27 b=27 c=267 d=nil]  -- = 286
  call(e[27], e[122])  -- CALL [a=27 b=23 c=122 d=nil] -- void call
  e[21][K(989)] = e[110]  -- SETTABLE [a=21 b=989 c=110 d=107] -- settable/void-call (inferred)
  call(e[30], e[19])  -- CALL? [a=30 b=0 c=19 d=nil] -- void call
  ::L_97::
  goto L_20
  if e[11] then goto L_4 end  -- back-edge (loop)
  ::L_99::
  -- UNKNOWN op? [a=11 b=80 c=10 d=nil]
  e[6] = e[12][32]  -- GETTABLE/CLOSURE? [a=12 b=0 c=6 d=nil]  -- = 32
  ::L_101::
  goto L_42
  e[71] = 117  -- LOADK [a=71 b=1615 c=102 d=117]
  e[11] = e[7][K(0)]  -- GETTABLE/CLOSURE? [a=7 b=0 c=11 d=nil]
  e[12] = e[3][K(0)]  -- GETTABLE/CLOSURE? [a=3 b=0 c=12 d=nil]
  e[13] = e[9][K(0)]  -- GETTABLE/CLOSURE? [a=9 b=0 c=13 d=nil]
  ::L_106::
  goto L_6
  e[33] = {}  -- NEWTABLE [a=33 b=0 c=0 d=nil]
  e[35] = {}  -- NEWTABLE [a=35 b=0 c=0 d=nil]
  e[35][K(1134)] = e[112]  -- SETTABLE [a=35 b=1134 c=112 d=99] -- settable/void-call (inferred)
  e[33][K(1134)] = e[4]  -- SETTABLE [a=33 b=1134 c=4 d=99] -- settable/void-call (inferred)
  e[35][K(103)] = e[94]  -- SETTABLE [a=35 b=103 c=94 d=11] -- settable/void-call (inferred)
  e[33][K(47)] = e[53]  -- SETTABLE [a=33 b=47 c=53 d=57] -- settable/void-call (inferred)
  call(e[38], e[31])  -- CALL? [a=38 b=0 c=31 d=nil] -- void call
  goto L_50
  if e[23] then goto L_99 end  -- back-edge (loop)
  goto L_56
end

local function proto26(...)  -- 10 instrs, 7 blocks (structured)
  local e = regs
  ::L_5::
  ::L_4::
  e[5] = e[2][32]  -- GETTABLE/CLOSURE? [a=2 b=0 c=5 d=nil]  -- = 32
  goto L_5
  ::L_2::
  if e[337] then do return end else goto L_3 end
  ::L_3::
  e[4] = e[3][K(0)]  -- GETTABLE/CLOSURE? [a=3 b=0 c=4 d=nil]
  goto L_4
  ::L_6::
  goto L_6
  e[0] = {}  -- NEWTABLE [a=0 b=3 c=0 d=nil]
  e[3] = e[3][K(1)]  -- GETTABLE [a=3 b=1 c=393 d=nil]
  e[2] = 32  -- LOADK [a=2 b=1829 c=0 d=32]
  goto L_2
end

local function proto27(...)  -- 89 instrs, 36 blocks (structured)
  local e = regs
  ::L_1::
  ::L_44::
  ::L_12::
  ::L_31::
  ::L_24::
  ::L_53::
  ::L_80::
  ::L_40::
  e[241] = e[241][K(163)]  -- GETTABLE/CLOSURE [a=241 b=163 c=11 d=nil]
  e[6] = e[6][K(72)]  -- GETTABLE [a=6 b=72 c=1757 d=nil]
  e[1951] = e[7][K(1)]  -- GETINDEX? [a=7 b=1 c=1951 d=nil]
  e[5] = e[5][K(1)]  -- GETTABLE [a=5 b=1 c=18 d=nil]
  e[3] = e[3][K(1)]  -- GETTABLE [a=3 b=1 c=18 d=nil]
  e[11] = e[4][K(0)]  -- GETTABLE/CLOSURE? [a=4 b=0 c=11 d=nil]
  e[12] = e[8][111]  -- GETTABLE/CLOSURE? [a=8 b=0 c=12 d=nil]  -- = 111
  goto L_80
  goto L_9
  e[11] = {}  -- NEWTABLE [a=0 b=0 c=11 d=nil]
  e[209][K(2)] = e[9]  -- SETTABLE/CALL [a=209 b=2 c=9 d=nil] -- settable/void-call (inferred)
  e[157][K(162)] = e[1935]  -- SETTABLE/CALL [a=157 b=162 c=1935 d=nil] -- settable/void-call (inferred)
  call(e[227], e[175])  -- CALL [a=227 b=108 c=175 d=nil] -- void call
  call(e[11], e[220])  -- CALL [a=11 b=70 c=220 d=nil] -- void call
  e[8] = 111  -- LOADK [a=8 b=2200 c=0 d=111]
  ::L_9::
  goto L_15
  e[11] = e[11]["delay"]  -- GETTABLE [a=11 b=1 c=394 d=nil]  -- = "delay"
  ::L_11::
  e[4][K(10)] = e[11]  -- SETTABLE/CALL [a=4 b=10 c=11 d=nil] -- settable/void-call (inferred)
  goto L_12
  e[16] = e[9][K(0)]  -- GETTABLE/CLOSURE? [a=9 b=0 c=16 d=nil]
  e[17] = e[6][K(0)]  -- GETTABLE/CLOSURE? [a=6 b=0 c=17 d=nil]
  ::L_15::
  goto L_11
  if e[1233] then goto L_19 end
  ::L_18::
  goto L_1
  ::L_19::
  goto L_46
  e[9][K(64)] = e[1673]  -- SETTABLE/CALL [a=9 b=64 c=1673 d=nil] -- settable/void-call (inferred)
  e[8] = 80  -- LOADK [a=8 b=1476 c=0 d=80]
  ::L_22::
  goto L_15
  if e[2] then goto L_58 else goto L_24 end
  e[33] = {}  -- NEWTABLE [a=33 b=0 c=0 d=nil]
  e[35] = {}  -- NEWTABLE [a=35 b=0 c=0 d=nil]
  e[35][K(110)] = e[41]  -- SETTABLE [a=35 b=110 c=41 d=20] -- settable/void-call (inferred)
  e[33][K(110)] = e[16]  -- SETTABLE [a=33 b=110 c=16 d=20] -- settable/void-call (inferred)
  e[33][K(126)] = e[29]  -- SETTABLE [a=33 b=126 c=29 d=34] -- settable/void-call (inferred)
  e[38][K(152)] = e[31]  -- SETTABLE/CALL [a=38 b=152 c=31 d=nil] -- settable/void-call (inferred)
  goto L_31
  ::L_33::
  goto L_54
  e[33] = {}  -- NEWTABLE [a=33 b=0 c=0 d=nil]
  e[35] = {}  -- NEWTABLE [a=35 b=0 c=0 d=nil]
  e[35][K(54)] = e[112]  -- SETTABLE [a=35 b=54 c=112 d=41] -- settable/void-call (inferred)
  e[33][K(29)] = e[62]  -- SETTABLE [a=33 b=29 c=62 d=32] -- settable/void-call (inferred)
  e[38][K(14)] = e[31]  -- SETTABLE/CALL [a=38 b=14 c=31 d=nil] -- settable/void-call (inferred)
  goto L_40
  e[3][K(0)] = e[13]  -- SETTABLE/CALL [a=3 b=0 c=13 d=nil] -- settable/void-call (inferred)
  e[14] = e[5][K(0)]  -- GETTABLE/CLOSURE? [a=5 b=0 c=14 d=nil]
  e[15] = e[7][K(0)]  -- GETTABLE/CLOSURE? [a=7 b=0 c=15 d=nil]
  goto L_44
  e[0] = {}  -- NEWTABLE [a=0 b=10 c=0 d=nil]
  ::L_46::
  goto L_15
  e[33] = {}  -- NEWTABLE [a=33 b=0 c=0 d=nil]
  e[35] = {}  -- NEWTABLE [a=35 b=0 c=0 d=nil]
  e[33][K(66)] = e[16]  -- SETTABLE [a=33 b=66 c=16 d=74] -- settable/void-call (inferred)
  e[35][K(83)] = e[41]  -- SETTABLE [a=35 b=83 c=41 d=75] -- settable/void-call (inferred)
  e[33][K(117)] = e[108]  -- SETTABLE [a=33 b=117 c=108 d=19] -- settable/void-call (inferred)
  e[38][K(16)] = e[31]  -- SETTABLE/CALL [a=38 b=16 c=31 d=nil] -- settable/void-call (inferred)
  goto L_53
  ::L_54::
  goto L_33
  e[21] = {}  -- NEWTABLE [a=21 b=0 c=0 d=nil]
  e[23] = {}  -- NEWTABLE [a=23 b=0 c=0 d=nil]
  e[27] = K(19)  -- LOADK_S [a=0 b=19 c=27 d=nil]
  ::L_58::
  e[28] = K(22)  -- LOADK_S [a=0 b=22 c=28 d=nil]
  -- UNKNOWN op? [a=29 b=1678 c=27 d=102]
  -- UNKNOWN op? [a=30 b=2280 c=0 d=13]
  e[28] = 0  -- LOADK_N [a=0 b=28 c=0 d=nil]
  e[27] = 4294967295  -- LOADK_N [a=0 b=0 c=27 d=nil]
  e[8][K(648)] = e[27]  -- SETTABLE/CALL [a=8 b=648 c=27 d=-4294966594] -- settable/void-call (inferred)
  e[27][K(229)] = e[163]  -- SETTABLE/CALL [a=27 b=229 c=163 d=nil] -- settable/void-call (inferred)
  e[186][K(38)] = e[78]  -- SETTABLE/CALL [a=186 b=38 c=78 d=nil] -- settable/void-call (inferred)
  e[206][K(88)] = e[89]  -- SETTABLE/CALL [a=206 b=88 c=89 d=nil] -- settable/void-call (inferred)
  e[125] = K(58)  -- LOADK_S [a=125 b=58 c=73 d=nil]
  e[27] = arith(e[27], e[672])  -- UNOP/arith? [a=27 b=27 c=672 d=nil]  -- = 151
  call(e[27], e[103])  -- CALL [a=27 b=23 c=103 d=nil] -- void call
  e[21][K(37)] = e[108]  -- SETTABLE [a=21 b=37 c=108 d=33] -- settable/void-call (inferred)
  call(e[30], e[19])  -- CALL? [a=30 b=0 c=19 d=nil] -- void call
  goto L_18
  e[32] = {}  -- NEWTABLE [a=32 b=0 c=0 d=nil]
  e[35] = {}  -- NEWTABLE [a=35 b=0 c=0 d=nil]
  e[33] = {}  -- NEWTABLE [a=33 b=0 c=0 d=nil]
  e[35][K(101)] = e[8]  -- SETTABLE [a=35 b=101 c=8 d=59] -- settable/void-call (inferred)
  e[32][K(101)] = e[4]  -- SETTABLE [a=32 b=101 c=4 d=59] -- settable/void-call (inferred)
  e[35][K(85)] = e[8]  -- SETTABLE [a=35 b=85 c=8 d=60] -- settable/void-call (inferred)
  e[33][K(108)] = e[119]  -- SETTABLE [a=33 b=108 c=119 d=16] -- settable/void-call (inferred)
  call(e[38], e[31])  -- CALL? [a=38 b=0 c=31 d=nil] -- void call
  goto L_22
end

local function proto28(...)  -- 135 instrs, 50 blocks (structured)
  local e = regs
  ::L_1::
  ::L_5::
  ::L_128::
  ::L_27::
  ::L_125::
  ::L_60::
  ::L_11::
  goto L_27
  e[1] = e[11]  -- MOVE [a=11 b=1 c=2407 d=nil]
  e[13] = e[3][K(0)]  -- GETTABLE/CLOSURE? [a=3 b=0 c=13 d=nil]
  e[14] = e[5][K(0)]  -- GETTABLE/CLOSURE? [a=5 b=0 c=14 d=nil]
  goto L_5
  ::L_6::
  goto L_112
  ::L_7::
  goto L_106
  e[4] = e[4][K(1)]  -- GETTABLE [a=4 b=1 c=18 d=nil]
  ::L_9::
  e[11] = e[11][K(1)]  -- GETTABLE [a=11 b=1 c=18 d=nil]
  call(e[11], e[25])  -- CALL [a=11 b=3 c=25 d=nil] -- void call
  goto L_11
  call(e[12], e[2])  -- CALL [a=12 b=0 c=2 d=nil] -- void call
  e[10] = e[13][13533]  -- GETTABLE/CLOSURE? [a=13 b=0 c=10 d=nil]  -- = 13533
  e[4] = e[14][K(0)]  -- GETTABLE/CLOSURE? [a=14 b=0 c=4 d=nil]
  e[5] = e[15][K(0)]  -- GETTABLE/CLOSURE? [a=15 b=0 c=5 d=nil]
  ::L_16::
  goto L_132
  e[7] = e[7][K(1)]  -- GETTABLE [a=7 b=1 c=18 d=nil]
  e[11] = e[11][K(1)]  -- GETTABLE [a=11 b=1 c=18 d=nil]
  call(e[11], e[2289])  -- CALL [a=11 b=211 c=2289 d=nil] -- void call
  e[11] = e[9][81]  -- GETTABLE/CLOSURE? [a=9 b=0 c=11 d=nil]  -- = 81
  ::L_21::
  goto L_67
  e[39] = {}  -- NEWTABLE [a=0 b=39 c=0 d=nil]
  e[38] = {}  -- NEWTABLE [a=38 b=0 c=0 d=nil]
  e[39][K(581)] = e[4]  -- SETTABLE [a=39 b=581 c=4 d=126] -- settable/void-call (inferred)
  e[38][K(10)] = e[1808]  -- SETTABLE [a=38 b=10 c=1808 d=72] -- settable/void-call (inferred)
  call(e[43], e[36])  -- CALL? [a=43 b=0 c=36 d=nil] -- void call
  goto L_27
  ::L_28::
  goto L_34
  e[38] = {}  -- NEWTABLE [a=38 b=0 c=0 d=nil]
  e[40] = {}  -- NEWTABLE [a=40 b=0 c=0 d=nil]
  e[40][K(71)] = e[41]  -- SETTABLE [a=40 b=71 c=41 d=49] -- settable/void-call (inferred)
  e[38][K(91)] = e[59]  -- SETTABLE [a=38 b=91 c=59 d=62] -- settable/void-call (inferred)
  call(e[43], e[36])  -- CALL? [a=43 b=0 c=36 d=nil] -- void call
  ::L_34::
  goto L_42
  e[38] = {}  -- NEWTABLE [a=38 b=0 c=0 d=nil]
  e[39] = {}  -- NEWTABLE [a=0 b=39 c=0 d=nil]
  e[39][K(2106)] = e[84]  -- SETTABLE [a=39 b=2106 c=84 d=131] -- settable/void-call (inferred)
  e[38][K(2106)] = e[4]  -- SETTABLE [a=38 b=2106 c=4 d=131] -- settable/void-call (inferred)
  e[38][K(115)] = e[16]  -- SETTABLE [a=38 b=115 c=16 d=28] -- settable/void-call (inferred)
  call(e[43], e[36])  -- CALL? [a=43 b=0 c=36 d=nil] -- void call
  goto L_1
  ::L_42::
  e[377][K(318)] = e[268]  -- SETTABLE/CALL [a=377 b=318 c=268 d=nil] -- settable/void-call (inferred)
  e[0] = {}  -- NEWTABLE [a=0 b=9 c=0 d=nil]
  call(e[10], e[0])  -- CALL [a=10 b=0 c=0 d=nil] -- void call
  e[11] = e[11][K(1)]  -- GETTABLE [a=11 b=1 c=18 d=nil]
  call(e[11], e[90])  -- CALL [a=11 b=3 c=90 d=nil] -- void call
  e[11] = e[11][K(1)]  -- GETTABLE [a=11 b=1 c=18 d=nil]
  call(e[43], e[1451])  -- CALL [a=43 b=3 c=1451 d=nil] -- void call
  -- UNKNOWN op? [a=2 b=1 c=18 d=nil]
  e[11] = e[11][K(1)]  -- GETTABLE [a=11 b=1 c=18 d=nil]
  call(e[11], e[283])  -- CALL [a=11 b=3 c=283 d=nil] -- void call
  ::L_52::
  goto L_7
  ::L_53::
  goto L_72
  ::L_54::
  goto L_54
  ::L_55::
  goto L_52
  e[18] = e[9][81]  -- GETTABLE/CLOSURE? [a=9 b=0 c=18 d=nil]  -- = 81
  e[19] = e[6][K(0)]  -- GETTABLE/CLOSURE? [a=6 b=0 c=19 d=nil]
  if e[11] then goto L_9 end  -- back-edge (loop)
  e[9] = e[11][81]  -- GETTABLE/CLOSURE? [a=11 b=0 c=9 d=nil]  -- = 81
  goto L_60
  ::L_61::
  goto L_79
  goto L_28
  if e[27] then do return end else goto L_64 end
  ::L_64::
  goto L_71
  e[15] = e[2][K(0)]  -- GETTABLE/CLOSURE? [a=2 b=0 c=15 d=nil]
  e[16] = e[6][K(0)]  -- GETTABLE/CLOSURE? [a=6 b=0 c=16 d=nil]
  ::L_67::
  goto L_11
  e[4][K(0)] = e[12]  -- SETTABLE/CALL [a=4 b=0 c=12 d=nil] -- settable/void-call (inferred)
  e[13] = e[7][K(0)]  -- GETTABLE/CLOSURE? [a=7 b=0 c=13 d=nil]
  e[14] = e[5][K(0)]  -- GETTABLE/CLOSURE? [a=5 b=0 c=14 d=nil]
  ::L_71::
  goto L_64
  ::L_72::
  goto L_21
  e[40] = {}  -- NEWTABLE [a=40 b=0 c=0 d=nil]
  e[38] = {}  -- NEWTABLE [a=38 b=0 c=0 d=nil]
  e[40][K(45)] = e[112]  -- SETTABLE [a=40 b=45 c=112 d=68] -- settable/void-call (inferred)
  e[38][K(117)] = e[111]  -- SETTABLE [a=38 b=117 c=111 d=19] -- settable/void-call (inferred)
  e[38][K(35)] = e[108]  -- SETTABLE [a=38 b=35 c=108 d=53] -- settable/void-call (inferred)
  call(e[43], e[36])  -- CALL? [a=43 b=0 c=36 d=nil] -- void call
  ::L_79::
  goto L_16
  e[23] = {}  -- NEWTABLE [a=0 b=23 c=0 d=nil]
  e[22] = {}  -- NEWTABLE [a=22 b=0 c=0 d=nil]
  e[28] = K(20)  -- LOADK_S [a=0 b=20 c=28 d=nil]
  e[29] = K(11)  -- LOADK_S [a=0 b=11 c=29 d=nil]
  e[30] = K(9)  -- LOADK_S [a=0 b=9 c=30 d=nil]
  e[31] = "Q245014"  -- LOADK [a=31 b=1833 c=0 d=Q�]
  e[32] = 3  -- LOADK_S [a=32 b=78 c=0 d=3]
  -- UNKNOWN op? [a=33 b=78 c=0 d=3]
  e[89] = 14  -- LOADK_N [a=0 b=89 c=4 d=nil]
  e[31] = K(8)  -- LOADK_S [a=0 b=8 c=31 d=nil]
  e[32] = ">i8"  -- LOADK [a=32 b=6 c=0 d=>i8]
  e[33] = "000000000000000000000e"  -- LOADK [a=33 b=318 c=0 d=       e]
  e[31] = 101  -- LOADK_N [a=193 b=31 c=0 d=nil]
  e[32] = K(9)  -- LOADK_S [a=0 b=9 c=32 d=nil]
  e[33] = "013"  -- LOADK [a=33 b=1080 c=0]
  e[11] = 1  -- LOADK [a=11 b=107 c=129 d=1]
  e[35] = 1  -- LOADK [a=35 b=107 c=0 d=1]
  e[32] = 13  -- LOADK_N [a=0 b=32 c=4 d=nil]
  e[29] = 4  -- LOADK_N [a=0 b=29 c=4 d=nil]
  e[30] = 13  -- LOADK [a=30 b=2280 c=0 d=13]
  e[28] = 2097152  -- LOADK_N [a=0 b=28 c=0 d=nil]
  e[28] = e[28] + -2074833  -- ADD [a=28 b=1670 c=28 d=-2074833]  -- = 22319
  e[28] = arith(e[28], e[1360])  -- UNOP/arith? [a=28 b=28 c=1360 d=nil]  -- = 11
  call(e[28], e[67])  -- CALL [a=28 b=23 c=67 d=nil] -- void call
  e[22][K(95)] = e[59]  -- SETTABLE [a=22 b=95 c=59 d=61] -- settable/void-call (inferred)
  call(e[35], e[20])  -- CALL? [a=35 b=0 c=20 d=nil] -- void call
  ::L_106::
  goto L_61
  e[40] = {}  -- NEWTABLE [a=40 b=0 c=0 d=nil]
  e[38] = {}  -- NEWTABLE [a=38 b=0 c=0 d=nil]
  e[40][K(3)] = e[112]  -- SETTABLE [a=40 b=3 c=112 d=12] -- settable/void-call (inferred)
  e[38][K(81)] = e[38]  -- SETTABLE [a=38 b=81 c=38 d=7] -- settable/void-call (inferred)
  call(e[43], e[36])  -- CALL? [a=43 b=0 c=36 d=nil] -- void call
  ::L_112::
  goto L_55
  e[38] = {}  -- NEWTABLE [a=38 b=0 c=0 d=nil]
  e[39] = {}  -- NEWTABLE [a=0 b=39 c=0 d=nil]
  e[40] = {}  -- NEWTABLE [a=40 b=0 c=0 d=nil]
  e[37] = {}  -- NEWTABLE [a=37 b=0 c=0 d=nil]
  e[39][K(75)] = e[4]  -- SETTABLE [a=39 b=75 c=4 d=92] -- settable/void-call (inferred)
  e[38][K(2199)] = e[24]  -- SETTABLE [a=38 b=2199 c=24 d=88] -- settable/void-call (inferred)
  e[37][K(11)] = e[4]  -- SETTABLE [a=37 b=11 c=4 d=95] -- settable/void-call (inferred)
  e[39][K(11)] = e[126]  -- SETTABLE [a=39 b=11 c=126 d=95] -- settable/void-call (inferred)
  e[40][K(46)] = e[8]  -- SETTABLE [a=40 b=46 c=8 d=87] -- settable/void-call (inferred)
  e[40][K(1568)] = e[8]  -- SETTABLE [a=40 b=1568 c=8 d=86] -- settable/void-call (inferred)
  e[38][K(23)] = e[85]  -- SETTABLE [a=38 b=23 c=85 d=6] -- settable/void-call (inferred)
  call(e[43], e[36])  -- CALL? [a=43 b=0 c=36 d=nil] -- void call
  goto L_125
  e[9] = 77  -- LOADK [a=9 b=1327 c=0 d=77]
  goto L_128
  e[15] = e[2][K(0)]  -- GETTABLE/CLOSURE? [a=2 b=0 c=15 d=nil]
  e[16] = e[4][K(0)]  -- GETTABLE/CLOSURE? [a=4 b=0 c=16 d=nil]
  e[17] = e[166][K(88)]  -- GETTABLE/CLOSURE? [a=166 b=88 c=17 d=nil]
  ::L_132::
  goto L_6
  e[6] = e[16][K(0)]  -- GETTABLE/CLOSURE? [a=16 b=0 c=6 d=nil]
  if e[62] then do return end else goto L_135 end
  ::L_135::
  goto L_53
end

local function proto29(...)  -- 169 instrs, 81 blocks (structured)
  local e = regs
  ::L_1::
  ::L_57::
  ::L_118::
  ::L_162::
  ::L_9::
  ::L_155::
  goto L_9
  e[21] = e[147][K(0)]  -- GETTABLE/CLOSURE? [a=147 b=0 c=21 d=nil]
  e[13] = e[3][K(0)]  -- GETTABLE/CLOSURE? [a=3 b=0 c=13 d=nil]
  e[14] = e[8][K(0)]  -- GETTABLE/CLOSURE? [a=8 b=0 c=14 d=nil]
  ::L_5::
  goto L_54
  if e[52] then goto L_52 end
  ::L_7::
  goto L_67
  ::L_8::
  goto L_56
  ::L_10::
  e[13] = e[2][K(246)]  -- GETTABLE/CLOSURE? [a=2 b=246 c=13 d=nil]
  e[9] = K(9)  -- LOADK_N [a=0 b=9 c=5 d=nil]
  e[5] = e[9][K(0)]  -- GETTABLE/CLOSURE? [a=9 b=0 c=5 d=nil]
  e[157] = e[141][81]  -- GETTABLE/CLOSURE? [a=141 b=0 c=157 d=nil]  -- = 81
  e[214][K(71)] = e[10]  -- SETTABLE/CALL [a=214 b=71 c=10 d=nil] -- settable/void-call (inferred)
  call(e[4], e[99])  -- CALL [a=4 b=169 c=99 d=nil] -- void call
  e[179] = K(187)  -- LOADK_S [a=179 b=187 c=27 d=nil]
  e[11] = 13533  -- LOADK [a=11 b=1832 c=0 d=13533]
  e[12] = e[5][K(0)]  -- GETTABLE/CLOSURE? [a=5 b=0 c=12 d=nil]
  ::L_19::
  goto L_152
  call(e[9], e[1451])  -- CALL [a=9 b=2 c=1451 d=nil] -- void call
  call(e[157], e[39])  -- CALL [a=157 b=16 c=39 d=nil] -- void call
  e[7][K(319)] = e[244]  -- SETTABLE/CALL [a=7 b=319 c=244 d=7] -- settable/void-call (inferred)
  e[240] = K(131)  -- LOADK_S [a=240 b=131 c=211 d=nil]
  ::L_24::
  goto L_102
  e[20] = {}  -- NEWTABLE [a=20 b=0 c=0 d=nil]
  e[18] = {}  -- NEWTABLE [a=18 b=0 c=0 d=nil]
  e[20][K(76)] = e[112]  -- SETTABLE [a=20 b=76 c=112 d=98] -- settable/void-call (inferred)
  e[18][K(52)] = e[67]  -- SETTABLE [a=18 b=52 c=67 d=58] -- settable/void-call (inferred)
  call(e[23], e[16])  -- CALL? [a=23 b=0 c=16 d=nil] -- void call
  ::L_30::
  goto L_48
  e[9] = e[9][K(1)]  -- GETTABLE [a=9 b=1 c=535 d=nil]
  call(e[9], e[90])  -- CALL [a=9 b=2 c=90 d=nil] -- void call
  e[9] = e[9][K(1)]  -- GETTABLE [a=9 b=1 c=1593 d=nil]
  ::L_34::
  goto L_19
  e[8] = e[11][K(0)]  -- GETTABLE/CLOSURE? [a=11 b=0 c=8 d=nil]
  ::L_36::
  goto L_102
  e[9] = e[9]["info"]  -- GETTABLE [a=9 b=1 c=1419 d=nil]  -- = "info"
  e[9] = e[9][K(4)]  -- GETTABLE/CLOSURE [a=9 b=4 c=9 d=nil]
  call(e[9], e[283])  -- CALL [a=9 b=2 c=283 d=nil] -- void call
  ::L_40::
  goto L_53
  -- UNKNOWN op? [a=9 b=0 c=4 d=nil]
  call(e[179], e[231])  -- CALL [a=179 b=134 c=231 d=nil] -- void call
  e[7][K(407)] = e[99]  -- SETTABLE/CALL [a=7 b=407 c=99 d=58] -- settable/void-call (inferred)
  e[241] = K(11)  -- LOADK_S [a=241 b=11 c=189 d=nil]
  e[9] = e[7][58]  -- GETTABLE/CLOSURE? [a=7 b=0 c=9 d=nil]  -- = 58
  e[10] = e[4][K(0)]  -- GETTABLE/CLOSURE? [a=4 b=0 c=10 d=nil]
  ::L_48::
  goto L_124
  e[0] = {}  -- NEWTABLE [a=0 b=8 c=0 d=nil]
  if e[116] then goto L_81 end
  ::L_51::
  goto L_68
  ::L_52::
  goto L_97
  ::L_53::
  goto L_83
  ::L_54::
  goto L_163
  goto L_9
  ::L_56::
  -- UNKNOWN op? [a=34 b=295 c=207 d=nil]
  goto L_57
  goto L_24
  if e[5] then goto L_120 end
  ::L_60::
  goto L_123
  e[18] = {}  -- NEWTABLE [a=18 b=0 c=0 d=nil]
  e[20] = {}  -- NEWTABLE [a=20 b=0 c=0 d=nil]
  e[20][K(59)] = e[112]  -- SETTABLE [a=20 b=59 c=112 d=42] -- settable/void-call (inferred)
  e[18][K(722)] = e[128]  -- SETTABLE [a=18 b=722 c=128 d=108] -- settable/void-call (inferred)
  call(e[23], e[16])  -- CALL? [a=23 b=0 c=16 d=nil] -- void call
  ::L_66::
  goto L_51
  ::L_67::
  goto L_88
  ::L_68::
  goto L_36
  ::L_69::
  goto L_107
  e[1] = e[9]  -- MOVE [a=9 b=1 c=1991 d=nil]
  e[11] = e[3][K(47)]  -- GETTABLE/CLOSURE? [a=3 b=47 c=11 d=nil]
  e[12] = e[8][K(0)]  -- GETTABLE/CLOSURE? [a=8 b=0 c=12 d=nil]
  e[13] = e[7][77]  -- GETTABLE/CLOSURE? [a=7 b=0 c=13 d=nil]  -- = 77
  ::L_74::
  goto L_110
  ::L_75::
  goto L_7
  e[18] = {}  -- NEWTABLE [a=18 b=0 c=0 d=nil]
  e[17] = {}  -- NEWTABLE [a=17 b=0 c=0 d=nil]
  e[17][K(109)] = e[100]  -- SETTABLE [a=17 b=109 c=100 d=109] -- settable/void-call (inferred)
  e[18][K(109)] = e[4]  -- SETTABLE [a=18 b=109 c=4 d=109] -- settable/void-call (inferred)
  ::L_81::
  e[18][K(83)] = e[722]  -- SETTABLE [a=18 b=83 c=722 d=75] -- settable/void-call (inferred)
  call(e[23], e[16])  -- CALL? [a=23 b=0 c=16 d=nil] -- void call
  ::L_83::
  goto L_108
  e[18] = {}  -- NEWTABLE [a=18 b=0 c=0 d=nil]
  e[18][K(43)] = e[4]  -- SETTABLE [a=18 b=43 c=4 d=71] -- settable/void-call (inferred)
  e[18][K(35)] = e[301]  -- SETTABLE [a=18 b=35 c=301 d=53] -- settable/void-call (inferred)
  e[23][K(251)] = e[16]  -- SETTABLE/CALL [a=23 b=251 c=16 d=nil] -- settable/void-call (inferred)
  ::L_88::
  goto L_146
  e[18] = {}  -- NEWTABLE [a=18 b=0 c=0 d=nil]
  e[19] = {}  -- NEWTABLE [a=0 b=19 c=0 d=nil]
  e[17] = {}  -- NEWTABLE [a=17 b=0 c=0 d=nil]
  e[18][K(42)] = e[4]  -- SETTABLE [a=18 b=42 c=4 d=10] -- settable/void-call (inferred)
  e[19][K(118)] = e[81]  -- SETTABLE [a=19 b=118 c=81 d=13] -- settable/void-call (inferred)
  e[17][K(118)] = e[88]  -- SETTABLE [a=17 b=118 c=88 d=13] -- settable/void-call (inferred)
  e[18][K(13)] = e[39]  -- SETTABLE [a=18 b=13 c=39 d=67] -- settable/void-call (inferred)
  e[23][K(33)] = e[16]  -- SETTABLE/CALL [a=23 b=33 c=16 d=nil] -- settable/void-call (inferred)
  ::L_97::
  goto L_103
  -- UNKNOWN op? [a=6 b=0 c=9 d=nil]
  e[10] = e[10][K(1)]  -- GETTABLE [a=10 b=1 c=1610 d=nil]
  e[11] = e[11]["The debug library is required on Luau platforms. Please open a support ticket."]  -- GETTABLE [a=11 b=1 c=1894 d=nil]  -- = "The debug library is required on Luau platforms. Please open a support ticket."
  e[9] = K(9)  -- LOADK_N [a=0 b=9 c=0 d=nil]
  ::L_102::
  goto L_8
  ::L_103::
  goto L_129
  e[1] = e[9]  -- MOVE [a=9 b=1 c=626 d=nil]
  e[11] = e[5][K(0)]  -- GETTABLE/CLOSURE? [a=5 b=0 c=11 d=nil]
  e[12] = e[4][K(0)]  -- GETTABLE/CLOSURE? [a=4 b=0 c=12 d=nil]
  ::L_107::
  goto L_9
  ::L_108::
  goto L_60
  e[127] = e[8][K(29)]  -- GETTABLE/CLOSURE? [a=8 b=29 c=127 d=nil]
  ::L_110::
  goto L_9
  if e[9] then goto L_5 end  -- back-edge (loop)
  e[7] = e[9][72]  -- GETTABLE/CLOSURE? [a=9 b=237 c=7 d=nil]  -- = 72
  e[252][K(10)] = e[3]  -- SETTABLE/CALL [a=252 b=10 c=3 d=nil] -- settable/void-call (inferred)
  call(e[10], e[171])  -- CALL [a=10 b=199 c=171 d=nil] -- void call
  e[80] = K(125)  -- LOADK_S [a=80 b=125 c=28 d=nil]
  goto L_34
  if e[58] then goto L_10 else goto L_118 end  -- back-edge (loop)
  e[18] = {}  -- NEWTABLE [a=18 b=0 c=0 d=nil]
  ::L_120::
  e[18][K(571)] = e[4]  -- SETTABLE [a=18 b=571 c=4 d=112] -- settable/void-call (inferred)
  e[18][K(47)] = e[56]  -- SETTABLE [a=18 b=47 c=56 d=57] -- settable/void-call (inferred)
  call(e[23], e[16])  -- CALL? [a=23 b=0 c=16 d=nil] -- void call
  ::L_123::
  goto L_69
  ::L_124::
  goto L_66
  e[11] = 46582  -- LOADK [a=11 b=1455 c=0 d=46582]
  e[12] = e[5][K(0)]  -- GETTABLE/CLOSURE? [a=5 b=0 c=12 d=nil]
  e[13] = e[3][K(0)]  -- GETTABLE/CLOSURE? [a=3 b=0 c=13 d=nil]
  e[192] = e[8][K(39)]  -- GETTABLE/CLOSURE? [a=8 b=39 c=192 d=nil]
  ::L_129::
  goto L_40
  e[17] = {}  -- NEWTABLE [a=17 b=0 c=0 d=nil]
  e[19] = {}  -- NEWTABLE [a=0 b=19 c=0 d=nil]
  e[18] = {}  -- NEWTABLE [a=18 b=0 c=0 d=nil]
  e[19][K(93)] = e[99]  -- SETTABLE [a=19 b=93 c=99 d=2] -- settable/void-call (inferred)
  e[17][K(93)] = e[3]  -- SETTABLE [a=17 b=93 c=3 d=2] -- settable/void-call (inferred)
  e[18][K(39)] = e[2238]  -- SETTABLE [a=18 b=39 c=2238 d=103] -- settable/void-call (inferred)
  call(e[23], e[16])  -- CALL? [a=23 b=0 c=16 d=nil] -- void call
  ::L_137::
  goto L_148
  e[7] = 81  -- LOADK [a=7 b=2062 c=93 d=81]
  e[84][K(133)] = e[9]  -- SETTABLE/CALL [a=84 b=133 c=9 d=nil] -- settable/void-call (inferred)
  call(e[7], e[22])  -- CALL [a=7 b=137 c=22 d=nil] -- void call
  e[133] = K(168)  -- LOADK_S [a=133 b=168 c=189 d=nil]
  e[10] = e[4][K(0)]  -- GETTABLE/CLOSURE? [a=4 b=0 c=10 d=nil]
  e[11] = 46582  -- LOADK [a=11 b=1455 c=0 d=46582]
  e[12] = e[5][K(0)]  -- GETTABLE/CLOSURE? [a=5 b=0 c=12 d=nil]
  e[13] = e[3][K(0)]  -- GETTABLE/CLOSURE? [a=3 b=0 c=13 d=nil]
  ::L_146::
  goto L_74
  if e[102] then goto L_57 end  -- back-edge (loop)
  ::L_148::
  goto L_75
  e[9] = e[7][7]  -- GETTABLE/CLOSURE? [a=7 b=0 c=9 d=nil]  -- = 7
  e[10] = e[4][K(0)]  -- GETTABLE/CLOSURE? [a=4 b=0 c=10 d=nil]
  call(e[11], e[0])  -- CALL [a=11 b=0 c=0 d=nil] -- void call
  ::L_152::
  goto L_1
  e[13] = e[3][K(0)]  -- GETTABLE/CLOSURE? [a=3 b=0 c=13 d=nil]
  e[14] = e[8][K(0)]  -- GETTABLE/CLOSURE? [a=8 b=0 c=14 d=nil]
  goto L_155
  e[17] = {}  -- NEWTABLE [a=17 b=0 c=0 d=nil]
  e[18] = {}  -- NEWTABLE [a=18 b=0 c=0 d=nil]
  e[17][K(2210)] = e[100]  -- SETTABLE [a=17 b=2210 c=100 d=128] -- settable/void-call (inferred)
  e[18][K(2210)] = e[4]  -- SETTABLE [a=18 b=2210 c=4 d=128] -- settable/void-call (inferred)
  e[18][K(88)] = e[54]  -- SETTABLE [a=18 b=88 c=54 d=9] -- settable/void-call (inferred)
  call(e[23], e[16])  -- CALL? [a=23 b=0 c=16 d=nil] -- void call
  goto L_162
  ::L_163::
  goto L_30
  e[18] = {}  -- NEWTABLE [a=18 b=0 c=0 d=nil]
  e[17] = {}  -- NEWTABLE [a=17 b=0 c=0 d=nil]
  e[17][K(12)] = e[4]  -- SETTABLE [a=17 b=12 c=4 d=138] -- settable/void-call (inferred)
  e[18][K(69)] = e[770]  -- SETTABLE [a=18 b=69 c=770 d=54] -- settable/void-call (inferred)
  call(e[23], e[16])  -- CALL? [a=23 b=0 c=16 d=nil] -- void call
  goto L_137
end

local function proto30(...)  -- 49 instrs, 16 blocks (structured)
  local e = regs
  ::L_1::
  ::L_11::
  ::L_5::
  -- UNKNOWN op? [a=192 b=434 c=144 d=nil]
  e[0] = {}  -- NEWTABLE [a=0 b=4 c=0 d=nil]
  e[159] = e[159][K(1)]  -- GETTABLE [a=159 b=1 c=1361 d=nil]
  e[2] = e[2][K(1)]  -- GETTABLE [a=2 b=1 c=1959 d=nil]
  ::L_9::
  ::L_21::
  ::L_25::
  goto L_9
  ::L_3::
  goto L_3
  goto L_42
  e[7] = e[3][K(0)]  -- GETTABLE/CLOSURE? [a=3 b=0 c=7 d=nil]
  goto L_11
  e[20] = {}  -- NEWTABLE [a=20 b=0 c=0 d=nil]
  e[23] = {}  -- NEWTABLE [a=23 b=0 c=0 d=nil]
  e[21] = {}  -- NEWTABLE [a=21 b=0 c=0 d=nil]
  e[23][K(29)] = e[644]  -- SETTABLE [a=23 b=29 c=644 d=32] -- settable/void-call (inferred)
  e[20][K(32)] = e[4]  -- SETTABLE [a=20 b=32 c=4 d=29] -- settable/void-call (inferred)
  e[23][K(127)] = e[644]  -- SETTABLE [a=23 b=127 c=644 d=31] -- settable/void-call (inferred)
  e[21][K(24)] = e[4]  -- SETTABLE [a=21 b=24 c=4 d=30] -- settable/void-call (inferred)
  e[21][K(125)] = e[104]  -- SETTABLE [a=21 b=125 c=104 d=43] -- settable/void-call (inferred)
  e[26][K(143)] = e[19]  -- SETTABLE/CALL [a=26 b=143 c=19 d=nil] -- settable/void-call (inferred)
  goto L_21
  e[162] = 72  -- LOADK [a=162 b=1363 c=0 d=72]
  e[5] = e[4][72]  -- GETTABLE/CLOSURE? [a=4 b=0 c=5 d=nil]  -- = 72
  e[6] = e[2][K(0)]  -- GETTABLE/CLOSURE? [a=2 b=0 c=6 d=nil]
  goto L_25
  e[11] = {}  -- NEWTABLE [a=11 b=0 c=0 d=nil]
  e[12] = {}  -- NEWTABLE [a=0 b=12 c=0 d=nil]
  e[17] = K(15)  -- LOADK_S [a=0 b=15 c=17 d=nil]
  e[18] = "F134"  -- LOADK [a=18 b=1261 c=225 d=F�]
  e[17] = 2  -- LOADK_N [a=0 b=123 c=17 d=nil]
  -- UNKNOWN op? [a=17 b=17 c=2138 d=nil]
  e[17] = (e[17] == e[1581])  -- COMPARE [a=17 b=17 c=1581 d=nil]  -- = 860
  e[92][K(1874)] = e[17]  -- SETTABLE/CALL [a=92 b=1874 c=17 d=3224] -- settable/void-call (inferred)
  e[17][K(11)] = e[48]  -- SETTABLE/CALL [a=17 b=11 c=48 d=nil] -- settable/void-call (inferred)
  e[73][K(245)] = e[139]  -- SETTABLE/CALL [a=73 b=245 c=139 d=nil] -- settable/void-call (inferred)
  e[158][K(23)] = e[2]  -- SETTABLE/CALL [a=158 b=23 c=2 d=nil] -- settable/void-call (inferred)
  e[232] = K(199)  -- LOADK_S [a=232 b=199 c=124 d=nil]
  e[17] = arith(e[17], e[2002])  -- UNOP/arith? [a=17 b=17 c=2002 d=nil]  -- = 3
  call(e[17], e[81])  -- CALL [a=17 b=12 c=81 d=nil] -- void call
  e[11][K(9)] = e[99]  -- SETTABLE [a=11 b=9 c=99 d=4] -- settable/void-call (inferred)
  call(e[18], e[9])  -- CALL? [a=18 b=0 c=9 d=nil] -- void call
  ::L_42::
  goto L_1
  e[22] = {}  -- NEWTABLE [a=0 b=22 c=0 d=nil]
  e[21] = {}  -- NEWTABLE [a=21 b=0 c=0 d=nil]
  e[22][K(119)] = e[9]  -- SETTABLE [a=22 b=119 c=9 d=22] -- settable/void-call (inferred)
  e[21][K(93)] = e[99]  -- SETTABLE [a=21 b=93 c=99 d=2] -- settable/void-call (inferred)
  e[26][K(249)] = e[19]  -- SETTABLE/CALL [a=26 b=249 c=19 d=nil] -- settable/void-call (inferred)
  goto L_5
end

local function proto31(...)  -- 10 instrs, 6 blocks (structured)
  local e = regs
  -- UNKNOWN op? [a=85 b=104 c=490 d=nil]
  ::L_3::
  ::L_5::
  do return end  -- JMP/RETURN [a=0 b=0 c=5 d=nil]
  e[5] = e[2][K(0)]  -- GETTABLE/CLOSURE? [a=2 b=0 c=5 d=nil]
  goto L_5
  e[0] = {}  -- NEWTABLE [a=0 b=4 c=0 d=nil]
  e[2] = e[2][K(3)]  -- GETTABLE [a=2 b=3 c=456 d=nil]
  e[5] = e[372][K(0)]  -- GETINDEX? [a=372 b=0 c=5 d=nil]
  call(e[5], e[25])  -- CALL [a=5 b=4 c=25 d=nil] -- void call
  goto L_3
end

local function proto32(...)  -- 100 instrs, 41 blocks (structured)
  local e = regs
  ::L_1::
  ::L_11::
  ::L_59::
  ::L_86::
  -- UNKNOWN op? [a=490 b=151 c=465 d=nil]
  e[31] = {}  -- NEWTABLE [a=31 b=0 c=0 d=nil]
  e[31][K(117)] = e[4]  -- SETTABLE [a=31 b=117 c=4 d=19] -- settable/void-call (inferred)
  e[31][K(11)] = e[11]  -- SETTABLE [a=31 b=11 c=11 d=95] -- settable/void-call (inferred)
  call(e[36], e[29])  -- CALL? [a=36 b=0 c=29 d=nil] -- void call
  goto L_86
  e[30] = {}  -- NEWTABLE [a=30 b=0 c=0 d=nil]
  e[33] = {}  -- NEWTABLE [a=33 b=0 c=0 d=nil]
  e[31] = {}  -- NEWTABLE [a=31 b=0 c=0 d=nil]
  e[32] = {}  -- NEWTABLE [a=0 b=32 c=0 d=nil]
  e[33][K(1901)] = e[112]  -- SETTABLE [a=33 b=1901 c=112 d=97] -- settable/void-call (inferred)
  e[32][K(1901)] = e[42]  -- SETTABLE [a=32 b=1901 c=42 d=97] -- settable/void-call (inferred)
  ::L_8::
  e[30][K(1901)] = e[99]  -- SETTABLE [a=30 b=1901 c=99 d=97] -- settable/void-call (inferred)
  ::L_9::
  e[31][K(52)] = e[80]  -- SETTABLE [a=31 b=52 c=80 d=58] -- settable/void-call (inferred)
  call(e[36], e[29])  -- CALL? [a=36 b=0 c=29 d=nil] -- void call
  goto L_11
  ::L_12::
  goto L_99
  e[0] = {}  -- NEWTABLE [a=0 b=6 c=0 d=nil]
  call(e[7], e[0])  -- CALL [a=7 b=0 c=0 d=nil] -- void call
  e[2] = e[2][K(1)]  -- GETTABLE [a=2 b=1 c=18 d=nil]
  e[8] = e[8][K(1)]  -- GETTABLE [a=8 b=1 c=18 d=nil]
  ::L_17::
  goto L_57
  ::L_18::
  goto L_92
  e[2] = e[12][K(99)]  -- GETTABLE/CLOSURE? [a=12 b=99 c=2 d=nil]
  e[8] = e[13][K(0)]  -- GETTABLE/CLOSURE? [a=13 b=0 c=8 d=nil]
  if e[55] then do return end else goto L_22 end
  ::L_22::
  goto L_17
  e[32] = {}  -- NEWTABLE [a=0 b=32 c=0 d=nil]
  e[31] = {}  -- NEWTABLE [a=31 b=0 c=0 d=nil]
  e[33] = {}  -- NEWTABLE [a=33 b=0 c=0 d=nil]
  e[30] = {}  -- NEWTABLE [a=30 b=0 c=0 d=nil]
  e[33][K(30)] = e[644]  -- SETTABLE [a=33 b=30 c=644 d=46] -- settable/void-call (inferred)
  e[30][K(51)] = e[4]  -- SETTABLE [a=30 b=51 c=4 d=44] -- settable/void-call (inferred)
  e[32][K(59)] = e[61]  -- SETTABLE [a=32 b=59 c=61 d=42] -- settable/void-call (inferred)
  e[32][K(116)] = e[19]  -- SETTABLE [a=32 b=116 c=19 d=45] -- settable/void-call (inferred)
  e[31][K(36)] = e[3]  -- SETTABLE [a=31 b=36 c=3 d=100] -- settable/void-call (inferred)
  call(e[36], e[29])  -- CALL? [a=36 b=0 c=29 d=nil] -- void call
  ::L_33::
  goto L_12
  e[5] = 110  -- LOADK [a=5 b=1707 c=0 d=110]
  ::L_35::
  goto L_59
  e[21] = {}  -- NEWTABLE [a=21 b=0 c=0 d=nil]
  e[19] = {}  -- NEWTABLE [a=19 b=0 c=0 d=nil]
  e[25] = K(13)  -- LOADK_S [a=0 b=13 c=25 d=nil]
  e[26] = "><J< n=n<="  -- LOADK [a=26 b=845 c=0 d=><J<]
  e[25] = 20  -- LOADK_N [a=0 b=0 c=25 d=nil]
  e[26] = K(8)  -- LOADK_S [a=0 b=8 c=26 d=nil]
  e[126] = "<i8"  -- LOADK [a=126 b=77 c=0 d=<i8]
  e[28] = "030000000000000000000000"  -- LOADK [a=28 b=699 c=0]
  e[26] = 30  -- LOADK_N [a=0 b=26 c=158 d=nil]
  e[25] = arith(e[25], e[25])  -- ARITH [a=32 b=25 c=25 d=nil]  -- = -10
  -- UNKNOWN op? [a=25 b=25 c=2052 d=nil]
  e[25] = e[25] + 16210  -- ADD [a=25 b=2334 c=25 d=16210]  -- = 16568
  e[25] = arith(e[25], e[1174])  -- UNOP/arith? [a=25 b=25 c=1174 d=nil]  -- = 292
  call(e[25], e[10])  -- CALL [a=25 b=21 c=10 d=nil] -- void call
  e[19][K(368)] = e[37]  -- SETTABLE [a=19 b=368 c=37 d=94] -- settable/void-call (inferred)
  call(e[28], e[17])  -- CALL? [a=28 b=0 c=17 d=nil] -- void call
  ::L_52::
  goto L_33
  e[10] = e[3][K(0)]  -- GETTABLE/CLOSURE? [a=3 b=0 c=10 d=nil]
  -- UNKNOWN op? [a=5 b=0 c=11 d=nil]
  goto L_9
  if e[59] then do return end else goto L_57 end
  ::L_57::
  goto L_1
  ::L_60::
  goto L_64
  e[9] = e[222][K(0)]  -- GETINDEX? [a=222 b=0 c=9 d=nil]
  call(e[9], e[2099])  -- CALL [a=9 b=4 c=2099 d=nil] -- void call
  e[9] = e[2][K(0)]  -- GETTABLE/CLOSURE? [a=2 b=0 c=9 d=nil]
  ::L_64::
  goto L_52
  e[32] = {}  -- NEWTABLE [a=0 b=32 c=0 d=nil]
  e[31] = {}  -- NEWTABLE [a=31 b=0 c=0 d=nil]
  e[32][K(62)] = e[23]  -- SETTABLE [a=32 b=62 c=23 d=73] -- settable/void-call (inferred)
  e[31][K(85)] = e[92]  -- SETTABLE [a=31 b=85 c=92 d=60] -- settable/void-call (inferred)
  call(e[36], e[29])  -- CALL? [a=36 b=0 c=29 d=nil] -- void call
  ::L_70::
  goto L_70
  e[1] = e[9]  -- MOVE [a=9 b=1 c=1966 d=nil]
  -- UNKNOWN op? [a=5 b=0 c=11 d=nil]
  e[12] = e[184][K(0)]  -- GETTABLE/CLOSURE? [a=184 b=0 c=12 d=nil]
  e[13] = e[3][K(0)]  -- GETTABLE/CLOSURE? [a=3 b=0 c=13 d=nil]
  ::L_75::
  goto L_75
  e[14] = e[8][K(0)]  -- GETTABLE/CLOSURE? [a=8 b=0 c=14 d=nil]
  e[15] = e[2][K(0)]  -- GETTABLE/CLOSURE? [a=2 b=0 c=15 d=nil]
  e[16] = e[4][K(0)]  -- GETTABLE/CLOSURE? [a=4 b=0 c=16 d=nil]
  if e[9] then goto L_8 end  -- back-edge (loop)
  goto L_94
  e[31] = {}  -- NEWTABLE [a=31 b=0 c=0 d=nil]
  e[33] = {}  -- NEWTABLE [a=33 b=0 c=0 d=nil]
  e[33][K(69)] = e[112]  -- SETTABLE [a=33 b=69 c=112 d=54] -- settable/void-call (inferred)
  e[31][K(101)] = e[85]  -- SETTABLE [a=31 b=101 c=85 d=59] -- settable/void-call (inferred)
  call(e[36], e[29])  -- CALL? [a=36 b=0 c=29 d=nil] -- void call
  ::L_92::
  goto L_60
  ::L_94::
  goto L_35
  e[7] = e[9][10114]  -- GETTABLE/CLOSURE? [a=9 b=0 c=7 d=nil]  -- = 10114
  e[137] = (e[137] == e[73])  -- COMPARE [a=137 b=0 c=73 d=nil]  -- = 80
  e[3] = e[11][K(0)]  -- GETTABLE/CLOSURE? [a=11 b=0 c=3 d=nil]
  ::L_99::
  goto L_18
  goto L_22
end

local function proto33(...)  -- 106 instrs, 43 blocks (structured)
  local e = regs
  ::L_1::
  ::L_74::
  ::L_98::
  ::L_8::
  e[27] = {}  -- NEWTABLE [a=27 b=0 c=0 d=nil]
  e[29] = {}  -- NEWTABLE [a=29 b=0 c=0 d=nil]
  e[26] = {}  -- NEWTABLE [a=26 b=0 c=0 d=nil]
  e[28][K(127)] = e[73]  -- SETTABLE [a=28 b=127 c=73 d=31] -- settable/void-call (inferred)
  e[26][K(127)] = e[4]  -- SETTABLE [a=26 b=127 c=4 d=31] -- settable/void-call (inferred)
  e[26][K(89)] = e[100]  -- SETTABLE [a=26 b=89 c=100 d=40] -- settable/void-call (inferred)
  e[29][K(60)] = e[2323]  -- SETTABLE [a=29 b=60 c=2323 d=35] -- settable/void-call (inferred)
  e[29][K(106)] = e[87]  -- SETTABLE [a=29 b=106 c=87 d=36] -- settable/void-call (inferred)
  e[29][K(37)] = e[48]  -- SETTABLE [a=29 b=37 c=48 d=33] -- settable/void-call (inferred)
  e[27][K(10)] = e[111]  -- SETTABLE [a=27 b=10 c=111 d=72] -- settable/void-call (inferred)
  e[32][K(64)] = e[25]  -- SETTABLE/CALL [a=32 b=64 c=25 d=nil] -- settable/void-call (inferred)
  ::L_19::
  ::L_78::
  ::L_63::
  e[189] = (e[399] == e[88])  -- COMPARE [a=399 b=189 c=88 d=nil]
  e[11] = e[6][K(0)]  -- GETTABLE/CLOSURE? [a=6 b=0 c=11 d=nil]
  e[12] = e[5][K(0)]  -- GETTABLE/CLOSURE? [a=5 b=0 c=12 d=nil]
  goto L_98
  goto L_27
  if e[2224] then goto L_48 end
  ::L_6::
  goto L_47
  e[28] = {}  -- NEWTABLE [a=0 b=28 c=0 d=nil]
  goto L_8
  e[27] = {}  -- NEWTABLE [a=27 b=0 c=0 d=nil]
  e[29] = {}  -- NEWTABLE [a=29 b=0 c=0 d=nil]
  e[27][K(53)] = e[4]  -- SETTABLE [a=27 b=53 c=4 d=50] -- settable/void-call (inferred)
  e[27][K(128)] = e[4]  -- SETTABLE [a=27 b=128 c=4 d=51] -- settable/void-call (inferred)
  e[29][K(71)] = e[279]  -- SETTABLE [a=29 b=71 c=279 d=49] -- settable/void-call (inferred)
  e[27][K(56)] = e[383]  -- SETTABLE [a=27 b=56 c=383 d=69] -- settable/void-call (inferred)
  e[32][K(56)] = e[25]  -- SETTABLE/CALL [a=32 b=56 c=25 d=nil] -- settable/void-call (inferred)
  ::L_27::
  goto L_104
  e[16] = {}  -- NEWTABLE [a=16 b=0 c=0 d=nil]
  e[18] = {}  -- NEWTABLE [a=18 b=0 c=0 d=nil]
  e[22] = K(8)  -- LOADK_S [a=0 b=8 c=22 d=nil]
  e[18] = ">i8"  -- LOADK [a=18 b=6 c=178 d=>i8]
  e[24] = "000000000000000000000027"  -- LOADK [a=24 b=1545 c=0 d=       ]
  -- UNKNOWN op? [a=0 b=22 c=0 d=nil]
  e[22] = arith(e[22], e[1837])  -- ARITH [a=22 b=22 c=1837 d=nil]  -- = -37
  -- UNKNOWN op? [a=22 b=22 c=1642 d=nil]
  -- UNKNOWN op? [a=22 b=950 c=22 d=9126]
  e[22] = arith(e[22], e[1822])  -- UNOP/arith? [a=22 b=22 c=1822 d=nil]  -- = 105
  call(e[22], e[46])  -- CALL [a=22 b=18 c=46 d=nil] -- void call
  e[16][K(9)] = e[92]  -- SETTABLE [a=16 b=9 c=92 d=4] -- settable/void-call (inferred)
  call(e[24], e[113])  -- CALL? [a=24 b=0 c=113 d=nil] -- void call
  ::L_41::
  goto L_70
  e[2] = e[9][80]  -- GETTABLE/CLOSURE? [a=9 b=0 c=2 d=nil]  -- = 80
  e[8] = 49401  -- LOADK [a=8 b=2260 c=0 d=49401]
  e[9] = e[2][80]  -- GETTABLE/CLOSURE? [a=2 b=0 c=9 d=nil]  -- = 80
  e[10] = e[4][K(0)]  -- GETTABLE/CLOSURE? [a=4 b=0 c=10 d=nil]
  e[11] = e[6][K(0)]  -- GETTABLE/CLOSURE? [a=6 b=0 c=11 d=nil]
  ::L_47::
  goto L_102
  ::L_48::
  goto L_72
  -- UNKNOWN op? [a=8 b=0 c=0 d=nil]
  e[9] = e[2][K(5)]  -- GETTABLE/CLOSURE? [a=2 b=5 c=9 d=nil]
  e[10] = e[4][K(243)]  -- GETTABLE/CLOSURE? [a=4 b=243 c=10 d=nil]
  e[47][K(128)] = e[11]  -- SETTABLE/CALL [a=47 b=128 c=11 d=nil] -- settable/void-call (inferred)
  call(e[6], e[155])  -- CALL [a=6 b=163 c=155 d=nil] -- void call
  e[234] = K(233)  -- LOADK_S [a=234 b=233 c=190 d=nil]
  e[76][K(154)] = e[12]  -- SETTABLE/CALL [a=76 b=154 c=12 d=nil] -- settable/void-call (inferred)
  call(e[5], e[147])  -- CALL [a=5 b=21 c=147 d=nil] -- void call
  e[18] = K(89)  -- LOADK_S [a=18 b=89 c=246 d=nil]
  ::L_58::
  goto L_8
  e[5] = e[5][K(1)]  -- GETTABLE [a=5 b=1 c=598 d=nil]
  e[8] = 10114  -- LOADK [a=8 b=1204 c=0 d=10114]
  e[9] = e[2][80]  -- GETTABLE/CLOSURE? [a=2 b=0 c=9 d=nil]  -- = 80
  e[10] = e[4][K(0)]  -- GETTABLE/CLOSURE? [a=4 b=0 c=10 d=nil]
  goto L_63
  e[12] = e[2][117]  -- GETTABLE/CLOSURE? [a=2 b=0 c=12 d=nil]  -- = 117
  e[13] = e[3][K(0)]  -- GETTABLE/CLOSURE? [a=3 b=0 c=13 d=nil]
  if e[8] then goto L_6 end  -- back-edge (loop)
  e[6] = e[8][K(0)]  -- GETTABLE/CLOSURE? [a=8 b=0 c=6 d=nil]
  ::L_68::
  goto L_41
  ::L_69::
  goto L_19
  ::L_70::
  goto L_8
  ::L_72::
  goto L_6
  if e[48] then goto L_58 else goto L_74 end  -- back-edge (loop)
  e[1] = e[8]  -- MOVE [a=8 b=1 c=990 d=nil]
  e[10] = e[6][K(0)]  -- GETTABLE/CLOSURE? [a=6 b=0 c=10 d=nil]
  e[11] = e[7][K(0)]  -- GETTABLE/CLOSURE? [a=7 b=0 c=11 d=nil]
  goto L_78
  e[26] = {}  -- NEWTABLE [a=26 b=0 c=0 d=nil]
  e[29] = {}  -- NEWTABLE [a=29 b=0 c=0 d=nil]
  e[27] = {}  -- NEWTABLE [a=27 b=0 c=0 d=nil]
  e[29][K(21)] = e[112]  -- SETTABLE [a=29 b=21 c=112 d=90] -- settable/void-call (inferred)
  e[26][K(21)] = e[88]  -- SETTABLE [a=26 b=21 c=88 d=90] -- settable/void-call (inferred)
  e[27][K(111)] = e[1568]  -- SETTABLE [a=27 b=111 c=1568 d=3] -- settable/void-call (inferred)
  e[32][K(111)] = e[25]  -- SETTABLE/CALL [a=32 b=111 c=25 d=nil] -- settable/void-call (inferred)
  ::L_86::
  goto L_86
  -- UNKNOWN op? [a=4 b=1 c=1655 d=nil]
  e[2] = 117  -- LOADK [a=2 b=1615 c=0 d=117]
  e[8] = 49401  -- LOADK [a=8 b=2260 c=0 d=49401]
  e[6] = arith(e[0], e[6])  -- ARITH [a=2 b=0 c=6 d=nil]  -- = 117
  e[10] = e[4][K(0)]  -- GETTABLE/CLOSURE? [a=4 b=0 c=10 d=nil]
  e[11] = e[6][K(0)]  -- GETTABLE/CLOSURE? [a=6 b=0 c=11 d=nil]
  e[12] = e[5][K(0)]  -- GETTABLE/CLOSURE? [a=5 b=0 c=12 d=nil]
  goto L_69
  e[0] = {}  -- NEWTABLE [a=0 b=7 c=0 d=nil]
  if e[63] then goto L_68 end  -- back-edge (loop)
  ::L_102::
  goto L_58
  e[12] = e[5][K(0)]  -- GETTABLE/CLOSURE? [a=5 b=0 c=12 d=nil]
  ::L_104::
  goto L_8
  if e[4] then goto L_63 end  -- back-edge (loop)
  goto L_1
end

local function proto34(...)  -- 66 instrs, 22 blocks (structured)
  local e = regs
  ::L_1::
  ::L_40::
  ::L_44::
  ::L_10::
  goto L_1
  ::L_2::
  goto L_6
  call(e[14], e[2289])  -- CALL [a=14 b=3 c=2289 d=nil] -- void call
  e[6] = e[6]["new"]  -- GETTABLE [a=6 b=24 c=696 d=nil]  -- = "new"
  -- UNKNOWN op? [a=2 b=5 c=6 d=nil]
  ::L_6::
  goto L_6
  e[4] = 80  -- LOADK [a=4 b=1476 c=233 d=80]
  e[6] = e[2][K(0)]  -- GETTABLE/CLOSURE? [a=2 b=0 c=6 d=nil]
  e[7] = e[4][80]  -- GETTABLE/CLOSURE? [a=4 b=0 c=7 d=nil]  -- = 80
  goto L_10
  ::L_11::
  goto L_30
  e[24] = {}  -- NEWTABLE [a=24 b=0 c=0 d=nil]
  e[26] = {}  -- NEWTABLE [a=26 b=0 c=0 d=nil]
  e[24][K(9)] = e[16]  -- SETTABLE [a=24 b=9 c=16 d=4] -- settable/void-call (inferred)
  e[26][K(99)] = e[1004]  -- SETTABLE [a=26 b=99 c=1004 d=5] -- settable/void-call (inferred)
  e[24][K(59)] = e[114]  -- SETTABLE [a=24 b=59 c=114 d=42] -- settable/void-call (inferred)
  e[29][K(31)] = e[22]  -- SETTABLE/CALL [a=29 b=31 c=22 d=nil] -- settable/void-call (inferred)
  ::L_18::
  goto L_18
  e[0] = {}  -- NEWTABLE [a=0 b=5 c=0 d=nil]
  e[6] = {}  -- NEWTABLE [a=0 b=0 c=6 d=nil]
  e[6][K(1353)] = e[26]  -- SETTABLE [a=6 b=1353 c=26 d=10] -- settable/void-call (inferred)
  e[6][K(70)] = e[78]  -- SETTABLE [a=6 b=70 c=78 d=4] -- settable/void-call (inferred)
  e[6][K(18)] = e[107]  -- SETTABLE [a=6 b=18 c=107 d=5] -- settable/void-call (inferred)
  ::L_24::
  goto L_65
  e[23] = {}  -- NEWTABLE [a=23 b=0 c=0 d=nil]
  e[24] = {}  -- NEWTABLE [a=24 b=0 c=0 d=nil]
  e[23][K(81)] = e[4]  -- SETTABLE [a=23 b=81 c=4 d=7] -- settable/void-call (inferred)
  e[24][K(27)] = e[93]  -- SETTABLE [a=24 b=27 c=93 d=66] -- settable/void-call (inferred)
  e[29][K(155)] = e[22]  -- SETTABLE/CALL [a=29 b=155 c=22 d=nil] -- settable/void-call (inferred)
  ::L_30::
  goto L_2
  e[24] = {}  -- NEWTABLE [a=24 b=0 c=0 d=nil]
  e[25] = {}  -- NEWTABLE [a=0 b=25 c=0 d=nil]
  e[26] = {}  -- NEWTABLE [a=26 b=0 c=0 d=nil]
  e[25][K(128)] = e[4]  -- SETTABLE [a=25 b=128 c=4 d=51] -- settable/void-call (inferred)
  e[26][K(71)] = e[8]  -- SETTABLE [a=26 b=71 c=8 d=49] -- settable/void-call (inferred)
  e[25][K(35)] = e[117]  -- SETTABLE [a=25 b=35 c=117 d=53] -- settable/void-call (inferred)
  e[25][K(53)] = e[4]  -- SETTABLE [a=25 b=53 c=4 d=50] -- settable/void-call (inferred)
  e[24][K(103)] = e[51]  -- SETTABLE [a=24 b=103 c=51 d=11] -- settable/void-call (inferred)
  e[29][K(96)] = e[22]  -- SETTABLE/CALL [a=29 b=96 c=22 d=nil] -- settable/void-call (inferred)
  goto L_40
  goto L_11
  ::L_43::
  -- UNKNOWN op? [a=280 b=53 c=85 d=nil]
  goto L_44
  e[12] = {}  -- NEWTABLE [a=0 b=12 c=0 d=nil]
  e[11] = {}  -- NEWTABLE [a=11 b=0 c=0 d=nil]
  e[17] = K(17)  -- LOADK_S [a=0 b=17 c=17 d=nil]
  e[18] = K(13)  -- LOADK_S [a=0 b=13 c=18 d=nil]
  -- UNKNOWN op? [a=19 b=1265 c=0 d==<><jL]
  e[18] = 24  -- LOADK_N [a=207 b=0 c=18 d=nil]
  e[17] = 3  -- LOADK_N [a=38 b=0 c=17 d=nil]
  e[18] = K(9)  -- LOADK_S [a=0 b=9 c=18 d=nil]
  e[101] = "]013"  -- LOADK [a=101 b=1442 c=0 d=]]
  call(e[214], e[7])  -- CALL [a=214 b=120 c=7 d=nil] -- void call
  e[20][K(107)] = e[163]  -- SETTABLE/CALL [a=20 b=107 c=163 d=1] -- settable/void-call (inferred)
  e[200] = K(166)  -- LOADK_S [a=200 b=166 c=185 d=nil]
  e[21] = 1  -- LOADK [a=21 b=107 c=0 d=1]
  e[18] = 93  -- LOADK_N [a=0 b=18 c=4 d=nil]
  e[17] = arith(e[17], e[17])  -- ARITH [a=18 b=17 c=17 d=nil]  -- = -90
  e[17] = e[17] + 6824  -- ADD [a=17 b=2209 c=17 d=6824]  -- = 6734
  e[17] = arith(e[17], e[1421])  -- UNOP/arith? [a=17 b=17 c=1421 d=nil]  -- = 6
  call(e[17], e[111])  -- CALL [a=17 b=12 c=111 d=nil] -- void call
  e[11][K(54)] = e[125]  -- SETTABLE [a=11 b=54 c=125 d=41] -- settable/void-call (inferred)
  call(e[21], e[9])  -- CALL? [a=21 b=0 c=9 d=nil] -- void call
  ::L_65::
  goto L_43
  goto L_24
end

local function proto35(...)  -- 131 instrs, 54 blocks (structured)
  local e = regs
  ::L_1::
  ::L_119::
  ::L_10::
  e[26] = K(107)  -- LOADK [a=26 b=107 c=0 d=1]
  call(e[27], e[0])  -- CALL [a=27 b=0 c=0 d=nil] -- void call
  e[24] = K(24)  -- LOADK_N [a=0 b=24 c=4 d=nil]
  ::L_13::
  ::L_33::
  ::L_101::
  ::L_93::
  ::L_21::
  ::L_41::
  ::L_57::
  ::L_15::
  ::L_46::
  goto L_13
  e[24] = e[24] + 14530  -- ADD [a=24 b=1797 c=24 d=14530]  -- = 14541
  e[24] = arith(e[24], e[1862])  -- UNOP/arith? [a=24 b=24 c=1862 d=nil]  -- = 9
  call(e[24], e[63])  -- CALL [a=24 b=17 c=63 d=nil] -- void call
  e[18][K(22)] = e[41]  -- SETTABLE [a=18 b=22 c=41 d=15] -- settable/void-call (inferred)
  -- UNKNOWN op? [a=28 b=70 c=16 d=nil]
  ::L_7::
  goto L_105
  e[24] = K(9)  -- LOADK_S [a=0 b=9 c=24 d=nil]
  e[158] = K(2265)  -- LOADK [a=158 b=2265 c=0 d=lM]
  goto L_10
  ::L_14::
  goto L_7
  e[24] = K(21)  -- LOADK_S [a=0 b=21 c=24 d=nil]
  e[25] = K(6)  -- LOADK_S [a=0 b=6 c=25 d=nil]
  e[24] = K(0)  -- LOADK_N [a=0 b=0 c=24 d=nil]
  ::L_19::
  goto L_68
  if e[91] then goto L_80 else goto L_21 end
  e[32] = {}  -- NEWTABLE [a=0 b=32 c=0 d=nil]
  e[33] = {}  -- NEWTABLE [a=33 b=0 c=0 d=nil]
  e[31] = {}  -- NEWTABLE [a=31 b=0 c=0 d=nil]
  e[30] = {}  -- NEWTABLE [a=30 b=0 c=0 d=nil]
  e[30][K(60)] = e[4]  -- SETTABLE [a=30 b=60 c=4 d=35] -- settable/void-call (inferred)
  e[33][K(60)] = e[8]  -- SETTABLE [a=33 b=60 c=8 d=35] -- settable/void-call (inferred)
  e[32][K(88)] = e[104]  -- SETTABLE [a=32 b=88 c=104 d=9] -- settable/void-call (inferred)
  e[31][K(66)] = e[51]  -- SETTABLE [a=31 b=66 c=51 d=74] -- settable/void-call (inferred)
  call(e[36], e[29])  -- CALL? [a=36 b=0 c=29 d=nil] -- void call
  ::L_31::
  goto L_44
  if e[97] then goto L_15 else goto L_33 end  -- back-edge (loop)
  e[25] = K(9)  -- LOADK_S [a=0 b=9 c=25 d=nil]
  -- UNKNOWN op? [a=26 b=2134 c=238 d=�]
  e[27] = 1  -- LOADK [a=27 b=107 c=0 d=1]
  e[28] = 1  -- LOADK [a=28 b=107 c=0 d=1]
  e[25] = 236  -- LOADK_N [a=0 b=25 c=4 d=nil]
  e[24] = (e[24] == e[24])  -- COMPARE [a=24 b=25 c=24 d=nil]  -- = true
  if e[24] then goto L_55 else goto L_41 end
  e[8] = e[8][K(1)]  -- GETTABLE [a=8 b=1 c=1092 d=nil]
  e[3] = 93  -- LOADK [a=3 b=196 c=0 d=93]
  ::L_44::
  goto L_19
  if e[24] then goto L_33 else goto L_46 end  -- back-edge (loop)
  e[17] = {}  -- NEWTABLE [a=17 b=0 c=0 d=nil]
  e[18] = {}  -- NEWTABLE [a=18 b=0 c=0 d=nil]
  e[24] = K(13)  -- LOADK_S [a=0 b=13 c=24 d=nil]
  e[25] = " h>d=<>c73<"  -- LOADK [a=25 b=883 c=0]
  e[24] = 83  -- LOADK_N [a=0 b=0 c=24 d=nil]
  e[24] = (e[531] == e[24])  -- COMPARE [a=531 b=24 c=24 d=nil]  -- = true
  if e[24] then goto L_73 end
  ::L_54::
  goto L_89
  ::L_55::
  goto L_76
  if e[24] then goto L_68 else goto L_57 end
  e[24] = K(13)  -- LOADK_S [a=0 b=13 c=24 d=nil]
  e[25] = ">I7=>=J "  -- LOADK [a=25 b=686 c=0 d=>I7=>=J]
  e[24] = 11  -- LOADK_N [a=0 b=0 c=24 d=nil]
  ::L_61::
  goto L_55
  e[31] = {}  -- NEWTABLE [a=31 b=0 c=0 d=nil]
  e[33] = {}  -- NEWTABLE [a=33 b=0 c=0 d=nil]
  e[31][K(23)] = e[4]  -- SETTABLE [a=31 b=23 c=4 d=6] -- settable/void-call (inferred)
  e[33][K(23)] = e[461]  -- SETTABLE [a=33 b=23 c=461 d=6] -- settable/void-call (inferred)
  e[31][K(56)] = e[16]  -- SETTABLE [a=31 b=56 c=16 d=69] -- settable/void-call (inferred)
  call(e[36], e[29])  -- CALL? [a=36 b=0 c=29 d=nil] -- void call
  ::L_68::
  goto L_1
  ::L_69::
  goto L_61
  e[6] = e[6][K(1)]  -- GETTABLE [a=6 b=1 c=18 d=nil]
  e[4] = e[4][K(1)]  -- GETTABLE [a=4 b=1 c=18 d=nil]
  e[3] = 120  -- LOADK [a=3 b=1936 c=0 d=120]
  ::L_73::
  goto L_31
  goto L_123
  ::L_76::
  -- UNKNOWN op? [a=151 b=31 c=483 d=nil]
  e[30] = {}  -- NEWTABLE [a=30 b=0 c=0 d=nil]
  e[33] = {}  -- NEWTABLE [a=33 b=0 c=0 d=nil]
  e[31] = {}  -- NEWTABLE [a=31 b=0 c=0 d=nil]
  ::L_80::
  e[32] = {}  -- NEWTABLE [a=0 b=32 c=0 d=nil]
  e[33][K(571)] = e[41]  -- SETTABLE [a=33 b=571 c=41 d=112] -- settable/void-call (inferred)
  e[32][K(571)] = e[88]  -- SETTABLE [a=32 b=571 c=88 d=112] -- settable/void-call (inferred)
  e[31][K(1233)] = e[99]  -- SETTABLE [a=31 b=1233 c=99 d=111] -- settable/void-call (inferred)
  e[30][K(1875)] = e[42]  -- SETTABLE [a=30 b=1875 c=42 d=114] -- settable/void-call (inferred)
  e[30][K(1357)] = e[88]  -- SETTABLE [a=30 b=1357 c=88 d=113] -- settable/void-call (inferred)
  e[33][K(2224)] = e[112]  -- SETTABLE [a=33 b=2224 c=112 d=117] -- settable/void-call (inferred)
  e[31][K(38)] = e[109]  -- SETTABLE [a=31 b=38 c=109 d=55] -- settable/void-call (inferred)
  call(e[36], e[29])  -- CALL? [a=36 b=0 c=29 d=nil] -- void call
  ::L_89::
  goto L_109
  e[24] = 218  -- LOADK [a=24 b=1541 c=0 d=218]
  goto L_73
  if e[1528] then goto L_19 else goto L_93 end  -- back-edge (loop)
  e[8] = e[8][K(1)]  -- GETTABLE [a=8 b=1 c=18 d=nil]
  e[7] = e[7][K(1)]  -- GETTABLE [a=7 b=1 c=18 d=nil]
  e[3] = 118  -- LOADK [a=3 b=360 c=0 d=118]
  goto L_19
  e[4] = e[4][K(1)]  -- GETTABLE [a=4 b=1 c=407 d=nil]
  e[9] = e[138][K(0)]  -- GETINDEX? [a=138 b=0 c=9 d=nil]
  call(e[9], e[1954])  -- CALL [a=9 b=5 c=1954 d=nil] -- void call
  goto L_101
  e[9] = e[9][K(1)]  -- GETTABLE [a=9 b=1 c=503 d=nil]
  e[6] = e[6][K(9)]  -- GETTABLE [a=6 b=9 c=396 d=nil]
  e[3] = 119  -- LOADK [a=3 b=1144 c=0 d=119]
  ::L_105::
  goto L_31
  e[7] = call(e[7], e[0])  -- GETGLOBAL/CALL [a=7 b=1975 c=0 d=loadstring]
  -- UNKNOWN op? [a=210 b=1 c=2071 d=nil]
  call(e[9], e[736])  -- CALL [a=9 b=5 c=736 d=nil] -- void call
  ::L_109::
  goto L_54
  e[138] = e[158][K(0)]  -- GETINDEX? [a=158 b=0 c=138 d=nil]
  call(e[9], e[1829])  -- CALL [a=9 b=35 c=1829 d=nil] -- void call
  -- UNKNOWN op? [a=101 b=1 c=1591 d=nil]
  e[9] = e[9][K(2)]  -- GETTABLE/CLOSURE [a=9 b=2 c=234 d=nil]
  e[201] = e[4][K(0)]  -- GETTABLE/CLOSURE? [a=4 b=0 c=201 d=nil]
  e[11] = e[8][K(0)]  -- GETTABLE/CLOSURE? [a=8 b=0 c=11 d=nil]
  e[12] = e[7][K(0)]  -- GETTABLE/CLOSURE? [a=7 b=0 c=12 d=nil]
  -- UNKNOWN op? [a=3 b=0 c=13 d=nil]
  e[14] = e[6][K(0)]  -- GETTABLE/CLOSURE? [a=6 b=0 c=14 d=nil]
  goto L_119
  e[0] = {}  -- NEWTABLE [a=0 b=8 c=0 d=nil]
  e[9] = e[149][K(0)]  -- GETINDEX? [a=149 b=0 c=9 d=nil]
  call(e[9], e[139])  -- CALL [a=9 b=5 c=139 d=nil] -- void call
  ::L_123::
  goto L_69
  e[31] = {}  -- NEWTABLE [a=31 b=0 c=0 d=nil]
  e[32] = {}  -- NEWTABLE [a=0 b=32 c=0 d=nil]
  e[33] = {}  -- NEWTABLE [a=33 b=0 c=0 d=nil]
  e[32][K(989)] = e[88]  -- SETTABLE [a=32 b=989 c=88 d=107] -- settable/void-call (inferred)
  e[33][K(989)] = e[41]  -- SETTABLE [a=33 b=989 c=41 d=107] -- settable/void-call (inferred)
  e[31][K(83)] = e[100]  -- SETTABLE [a=31 b=83 c=100 d=75] -- settable/void-call (inferred)
  call(e[36], e[29])  -- CALL? [a=36 b=0 c=29 d=nil] -- void call
  goto L_14
end

local function proto36(...)  -- 76 instrs, 28 blocks (structured)
  local e = regs
  ::L_1::
  ::L_22::
  do return end  -- JMP/RETURN [a=3 b=250 c=0 d=nil]
  e[17] = K(10)  -- LOADK_S [a=0 b=10 c=17 d=nil]
  e[18] = 3.141592653589793  -- LOADK_S [a=0 b=6 c=18 d=nil]
  call(e[186], e[85])  -- CALL [a=186 b=0 c=85 d=nil] -- void call
  ::L_5::
  goto L_40
  ::L_6::
  goto L_67
  e[17] = K(9)  -- LOADK_S [a=0 b=9 c=17 d=nil]
  e[18] = K(1457)  -- LOADK [a=18 b=1457 c=0 d=f�]
  e[19] = K(65)  -- LOADK [a=19 b=65 c=0 d=2]
  call(e[20], e[0])  -- CALL [a=20 b=0 c=0 d=nil] -- void call
  e[17] = K(17)  -- LOADK_N [a=0 b=17 c=4 d=nil]
  ::L_12::
  goto L_39
  ::L_13::
  goto L_58
  call(e[247], e[1802])  -- CALL [a=247 b=3 c=1802 d=nil] -- void call
  e[2] = e[2][K(1)]  -- GETTABLE [a=2 b=1 c=18 d=nil]
  e[4] = e[4][K(1)]  -- GETTABLE [a=4 b=1 c=18 d=nil]
  e[5] = e[2][K(0)]  -- GETTABLE/CLOSURE? [a=2 b=0 c=5 d=nil]
  ::L_18::
  goto L_20
  if e[17] then goto L_40 end
  ::L_20::
  goto L_38
  e[6] = e[4][K(0)]  -- GETTABLE/CLOSURE? [a=4 b=0 c=6 d=nil]
  goto L_22
  ::L_23::
  goto L_12
  e[23] = {}  -- NEWTABLE [a=23 b=0 c=0 d=nil]
  e[24] = {}  -- NEWTABLE [a=0 b=24 c=0 d=nil]
  e[25] = {}  -- NEWTABLE [a=25 b=0 c=0 d=nil]
  e[24][K(60)] = e[99]  -- SETTABLE [a=24 b=60 c=99 d=35] -- settable/void-call (inferred)
  e[24][K(100)] = e[99]  -- SETTABLE [a=24 b=100 c=99 d=14] -- settable/void-call (inferred)
  e[25][K(126)] = e[1284]  -- SETTABLE [a=25 b=126 c=1284 d=34] -- settable/void-call (inferred)
  e[23][K(1)] = e[29]  -- SETTABLE [a=23 b=1 c=29 d=38] -- settable/void-call (inferred)
  call(e[28], e[21])  -- CALL? [a=28 b=0 c=21 d=nil] -- void call
  ::L_32::
  goto L_32
  e[0] = {}  -- NEWTABLE [a=0 b=4 c=0 d=nil]
  -- UNKNOWN op? [a=327 b=0 c=5 d=nil]
  call(e[5], e[82])  -- CALL [a=5 b=3 c=82 d=nil] -- void call
  e[5] = e[144][K(0)]  -- GETINDEX? [a=144 b=0 c=5 d=nil]
  ::L_37::
  goto L_13
  ::L_38::
  goto L_23
  ::L_39::
  goto L_1
  ::L_40::
  goto L_48
  e[18] = 12  -- LOADK [a=18 b=1828 c=0 d=12]
  e[16] = 12288  -- LOADK_N [a=0 b=16 c=0 d=nil]
  e[16] = e[16] + -4483  -- ADD [a=16 b=2315 c=16 d=-4483]  -- = 7805
  e[16] = arith(e[16], e[2116])  -- UNOP/arith? [a=16 b=16 c=2116 d=nil]  -- = 5
  call(e[16], e[119])  -- CALL [a=16 b=10 c=119 d=nil] -- void call
  e[10][K(23)] = e[29]  -- SETTABLE [a=10 b=23 c=29 d=6] -- settable/void-call (inferred)
  call(e[20], e[8])  -- CALL? [a=20 b=0 c=8 d=nil] -- void call
  ::L_48::
  goto L_37
  e[22] = {}  -- NEWTABLE [a=22 b=0 c=0 d=nil]
  e[24] = {}  -- NEWTABLE [a=0 b=24 c=0 d=nil]
  e[23] = {}  -- NEWTABLE [a=23 b=0 c=0 d=nil]
  e[25] = {}  -- NEWTABLE [a=25 b=0 c=0 d=nil]
  e[25][K(9)] = e[96]  -- SETTABLE [a=25 b=9 c=96 d=4] -- settable/void-call (inferred)
  e[24][K(9)] = e[4]  -- SETTABLE [a=24 b=9 c=4 d=4] -- settable/void-call (inferred)
  e[22][K(9)] = e[20]  -- SETTABLE [a=22 b=9 c=20 d=4] -- settable/void-call (inferred)
  e[23][K(89)] = e[114]  -- SETTABLE [a=23 b=89 c=114 d=40] -- settable/void-call (inferred)
  call(e[28], e[21])  -- CALL? [a=28 b=0 c=21 d=nil] -- void call
  ::L_58::
  goto L_18
  e[25] = {}  -- NEWTABLE [a=25 b=0 c=0 d=nil]
  e[24] = {}  -- NEWTABLE [a=0 b=24 c=0 d=nil]
  e[23] = {}  -- NEWTABLE [a=23 b=0 c=0 d=nil]
  e[25][K(62)] = e[48]  -- SETTABLE [a=25 b=62 c=48 d=73] -- settable/void-call (inferred)
  e[24][K(62)] = e[4]  -- SETTABLE [a=24 b=62 c=4 d=73] -- settable/void-call (inferred)
  e[23][K(118)] = e[99]  -- SETTABLE [a=23 b=118 c=99 d=13] -- settable/void-call (inferred)
  call(e[28], e[21])  -- CALL? [a=28 b=0 c=21 d=nil] -- void call
  goto L_5
  ::L_67::
  -- UNKNOWN op? [a=9 b=463 c=274 d=nil]
  e[10] = {}  -- NEWTABLE [a=10 b=0 c=0 d=nil]
  e[16] = K(7)  -- LOADK_S [a=0 b=7 c=16 d=nil]
  e[17] = K(8)  -- LOADK_S [a=0 b=8 c=17 d=nil]
  e[18] = ">i8"  -- LOADK [a=18 b=6 c=0 d=>i8]
  e[19] = "000000000000000000000248"  -- LOADK [a=19 b=1417 c=0 d=       �]
  e[32][248] = e[0]  -- SETTABLE/CALL [a=32 b=17 c=0 d=nil] -- settable/void-call (inferred)
  e[17] = (e[17] == e[272])  -- COMPARE [a=17 b=17 c=272 d=nil]  -- = false
  if e[17] then goto L_39 end  -- back-edge (loop)
  goto L_6
end

local function proto37(...)  -- 133 instrs, 62 blocks (structured)
  local e = regs
  ::L_3::
  ::L_96::
  ::L_88::
  ::L_28::
  if e[298] then do return end else goto L_24 end
  ::L_24::
  e[26] = {}  -- NEWTABLE [a=26 b=0 c=0 d=nil]
  e[26][K(29)] = e[4]  -- SETTABLE [a=26 b=29 c=4 d=32] -- settable/void-call (inferred)
  e[26][K(127)] = e[1134]  -- SETTABLE [a=26 b=127 c=1134 d=31] -- settable/void-call (inferred)
  call(e[31], e[24])  -- CALL? [a=31 b=0 c=24 d=nil] -- void call
  goto L_28
  if e[59] then goto L_121 else goto L_3 end
  ::L_4::
  goto L_4
  ::L_5::
  e[0] = {}  -- NEWTABLE [a=0 b=6 c=0 d=nil]
  e[7] = e[7][K(1)]  -- GETTABLE [a=7 b=1 c=18 d=nil]
  ::L_7::
  call(e[7], e[564])  -- CALL [a=7 b=6 c=564 d=nil] -- void call
  ::L_8::
  goto L_59
  ::L_10::
  goto L_12
  -- UNKNOWN op? [a=122 b=0 c=136 d=nil]
  ::L_12::
  goto L_59
  e[27] = {}  -- NEWTABLE [a=0 b=27 c=0 d=nil]
  e[26] = {}  -- NEWTABLE [a=26 b=0 c=0 d=nil]
  e[27][K(95)] = e[81]  -- SETTABLE [a=27 b=95 c=81 d=61] -- settable/void-call (inferred)
  e[26][K(95)] = e[16]  -- SETTABLE [a=26 b=95 c=16 d=61] -- settable/void-call (inferred)
  e[26][K(42)] = e[973]  -- SETTABLE [a=26 b=42 c=973 d=10] -- settable/void-call (inferred)
  call(e[31], e[24])  -- CALL? [a=31 b=0 c=24 d=nil] -- void call
  goto L_130
  if e[1] then goto L_5 end  -- back-edge (loop)
  ::L_21::
  goto L_29
  goto L_70
  ::L_29::
  goto L_71
  goto L_72
  e[7] = e[316][K(44)]  -- GETINDEX? [a=316 b=44 c=7 d=nil]
  call(e[7], e[564])  -- CALL [a=7 b=6 c=564 d=nil] -- void call
  e[2] = 27  -- LOADK [a=2 b=2289 c=0 d=27]
  ::L_35::
  goto L_59
  e[25] = {}  -- NEWTABLE [a=25 b=0 c=0 d=nil]
  e[26] = {}  -- NEWTABLE [a=26 b=0 c=0 d=nil]
  e[28] = {}  -- NEWTABLE [a=28 b=0 c=0 d=nil]
  e[28][K(50)] = e[112]  -- SETTABLE [a=28 b=50 c=112 d=91] -- settable/void-call (inferred)
  e[26][K(50)] = e[4]  -- SETTABLE [a=26 b=50 c=4 d=91] -- settable/void-call (inferred)
  e[25][K(50)] = e[81]  -- SETTABLE [a=25 b=50 c=81 d=91] -- settable/void-call (inferred)
  e[26][K(43)] = e[85]  -- SETTABLE [a=26 b=43 c=85 d=71] -- settable/void-call (inferred)
  call(e[31], e[24])  -- CALL? [a=31 b=0 c=24 d=nil] -- void call
  ::L_44::
  goto L_60
  if e[30] then goto L_61 end
  ::L_46::
  goto L_97
  e[10] = e[2][27]  -- GETTABLE/CLOSURE? [a=2 b=0 c=10 d=nil]  -- = 27
  ::L_48::
  goto L_7
  e[1] = e[7]  -- MOVE [a=7 b=1 c=1737 d=nil]
  e[9] = e[2][65]  -- GETTABLE/CLOSURE? [a=2 b=0 c=9 d=nil]  -- = 65
  ::L_51::
  e[10] = e[6][K(0)]  -- GETTABLE/CLOSURE? [a=6 b=0 c=10 d=nil]
  e[92] = e[5][K(0)]  -- GETTABLE/CLOSURE? [a=5 b=0 c=92 d=nil]
  if e[7] then goto L_5 end  -- back-edge (loop)
  e[2] = e[7][44]  -- GETTABLE/CLOSURE? [a=7 b=0 c=2 d=nil]  -- = 44
  ::L_55::
  goto L_10
  e[1] = e[7]  -- MOVE [a=7 b=1 c=872 d=nil]
  e[9] = e[4][K(0)]  -- GETTABLE/CLOSURE? [a=4 b=0 c=9 d=nil]
  e[10] = e[6][K(0)]  -- GETTABLE/CLOSURE? [a=6 b=0 c=10 d=nil]
  ::L_59::
  goto L_65
  ::L_60::
  goto L_82
  ::L_61::
  e[148] = e[255]  -- MOVE [a=255 b=148 c=1624 d=nil]
  e[9] = e[3][K(0)]  -- GETTABLE/CLOSURE? [a=3 b=0 c=9 d=nil]
  e[10] = e[6][K(0)]  -- GETTABLE/CLOSURE? [a=6 b=0 c=10 d=nil]
  e[7] = K(7)  -- LOADK_N [a=0 b=7 c=4 d=nil]
  ::L_65::
  goto L_94
  e[11] = e[2][106]  -- GETTABLE/CLOSURE? [a=2 b=0 c=11 d=nil]  -- = 106
  if e[7] then goto L_5 end  -- back-edge (loop)
  e[2] = e[7][65]  -- GETTABLE/CLOSURE? [a=7 b=0 c=2 d=nil]  -- = 65
  e[4] = e[8][K(0)]  -- GETTABLE/CLOSURE? [a=8 b=0 c=4 d=nil]
  ::L_70::
  goto L_8
  ::L_71::
  goto L_35
  ::L_72::
  goto L_101
  e[25] = {}  -- NEWTABLE [a=25 b=0 c=0 d=nil]
  e[26] = {}  -- NEWTABLE [a=26 b=0 c=0 d=nil]
  e[27] = {}  -- NEWTABLE [a=0 b=27 c=0 d=nil]
  e[28] = {}  -- NEWTABLE [a=28 b=0 c=0 d=nil]
  e[28][K(103)] = e[112]  -- SETTABLE [a=28 b=103 c=112 d=11] -- settable/void-call (inferred)
  e[27][K(103)] = e[84]  -- SETTABLE [a=27 b=103 c=84 d=11] -- settable/void-call (inferred)
  e[25][K(103)] = e[99]  -- SETTABLE [a=25 b=103 c=99 d=11] -- settable/void-call (inferred)
  e[26][K(24)] = e[67]  -- SETTABLE [a=26 b=24 c=67 d=30] -- settable/void-call (inferred)
  call(e[31], e[24])  -- CALL? [a=31 b=0 c=24 d=nil] -- void call
  ::L_82::
  goto L_48
  e[25] = {}  -- NEWTABLE [a=25 b=0 c=0 d=nil]
  e[26] = {}  -- NEWTABLE [a=26 b=0 c=0 d=nil]
  e[25][K(94)] = e[103]  -- SETTABLE [a=25 b=94 c=103 d=52] -- settable/void-call (inferred)
  e[26][K(85)] = e[115]  -- SETTABLE [a=26 b=85 c=115 d=60] -- settable/void-call (inferred)
  call(e[31], e[24])  -- CALL? [a=31 b=0 c=24 d=nil] -- void call
  goto L_88
  e[7] = e[7][K(1)]  -- GETTABLE [a=7 b=1 c=18 d=nil]
  call(e[7], e[74])  -- CALL [a=7 b=6 c=74 d=nil] -- void call
  -- UNKNOWN op? [a=5 b=17 c=189 d=nil]
  e[8] = e[3][K(0)]  -- GETTABLE/CLOSURE? [a=3 b=0 c=8 d=nil]
  e[9] = e[4][K(0)]  -- GETTABLE/CLOSURE? [a=4 b=0 c=9 d=nil]
  ::L_94::
  goto L_46
  e[3] = e[7][K(0)]  -- GETTABLE/CLOSURE? [a=7 b=0 c=3 d=nil]
  goto L_96
  ::L_97::
  goto L_55
  ::L_98::
  goto L_21
  if e[19] then goto L_51 end  -- back-edge (loop)
  ::L_101::
  goto L_98
  e[25] = {}  -- NEWTABLE [a=25 b=0 c=0 d=nil]
  e[27] = {}  -- NEWTABLE [a=0 b=27 c=0 d=nil]
  e[26] = {}  -- NEWTABLE [a=26 b=0 c=0 d=nil]
  e[26][K(1270)] = e[110]  -- SETTABLE [a=26 b=1270 c=110 d=124] -- settable/void-call (inferred)
  e[25][K(1509)] = e[4]  -- SETTABLE [a=25 b=1509 c=4 d=116] -- settable/void-call (inferred)
  e[27][K(15)] = e[119]  -- SETTABLE [a=27 b=15 c=119 d=120] -- settable/void-call (inferred)
  e[25][K(435)] = e[4]  -- SETTABLE [a=25 b=435 c=4 d=115] -- settable/void-call (inferred)
  e[26][K(10)] = e[1233]  -- SETTABLE [a=26 b=10 c=1233 d=72] -- settable/void-call (inferred)
  call(e[31], e[24])  -- CALL? [a=31 b=0 c=24 d=nil] -- void call
  ::L_111::
  goto L_111
  e[14] = {}  -- NEWTABLE [a=14 b=0 c=0 d=nil]
  e[16] = {}  -- NEWTABLE [a=16 b=0 c=0 d=nil]
  e[20] = K(9)  -- LOADK_S [a=0 b=9 c=20 d=nil]
  e[21] = "Lg"  -- LOADK [a=21 b=991 c=59 d=Lg]
  e[22] = 1  -- LOADK [a=22 b=107 c=3 d=1]
  e[23] = 1  -- LOADK [a=23 b=107 c=0 d=1]
  e[20] = 76  -- LOADK_N [a=0 b=20 c=4 d=nil]
  e[21] = K(8)  -- LOADK_S [a=0 b=8 c=21 d=nil]
  e[74] = ">i8"  -- LOADK [a=74 b=6 c=0 d=>i8]
  ::L_121::
  e[23] = "000000000000000000000255"  -- LOADK [a=23 b=1238 c=0 d=       �]
  e[21] = 255  -- LOADK_N [a=0 b=21 c=0 d=nil]
  e[20] = arith(e[20], e[20])  -- ARITH [a=21 b=20 c=20 d=nil]  -- = -179
  e[20] = arith(e[250], e[1758])  -- ARITH [a=20 b=250 c=1758 d=nil]  -- = -638
  e[20] = e[20] + 32682  -- ADD [a=20 b=641 c=20 d=32682]  -- = 32044
  e[20] = arith(e[20], e[482])  -- UNOP/arith? [a=20 b=20 c=482 d=nil]  -- = 286
  call(e[20], e[119])  -- CALL [a=20 b=16 c=119 d=nil] -- void call
  e[14][K(32)] = e[51]  -- SETTABLE [a=14 b=32 c=51 d=29] -- settable/void-call (inferred)
  call(e[23], e[12])  -- CALL? [a=23 b=0 c=12 d=nil] -- void call
  ::L_130::
  goto L_44
  e[3] = e[0][K(0)]  -- GETTABLE/CLOSURE? [a=0 b=0 c=3 d=nil]
  e[2] = 106  -- LOADK [a=2 b=17 c=0 d=106]
  goto L_59
end

local function proto38(...)  -- 10 instrs, 6 blocks (structured)
  local e = regs
  ::L_1::
  ::L_3::
  e[0] = {}  -- NEWTABLE [a=0 b=4 c=0 d=nil]
  e[2] = e[357][K(0)]  -- GETINDEX? [a=357 b=0 c=2 d=nil]
  e[4] = 65  -- LOADK [a=4 b=961 c=0 d=65]
  e[5] = e[4][65]  -- GETTABLE/CLOSURE? [a=4 b=0 c=5 d=nil]  -- = 65
  goto L_1
  e[6] = e[2][K(0)]  -- GETTABLE/CLOSURE? [a=2 b=0 c=6 d=nil]
  goto L_3
  ::L_4::
  goto L_4
  -- UNKNOWN op? [a=239 b=335 c=159 d=nil]
end

local function proto39(...)  -- 9 instrs, 4 blocks (structured)
  local e = regs
  ::L_4::
  e[0] = {}  -- NEWTABLE [a=0 b=4 c=0 d=nil]
  e[4] = e[26][K(0)]  -- GETINDEX? [a=26 b=0 c=4 d=nil]
  e[2] = 44  -- LOADK [a=2 b=1673 c=0 d=44]
  e[5] = e[2][44]  -- GETTABLE/CLOSURE? [a=2 b=0 c=5 d=nil]  -- = 44
  -- UNKNOWN op? [a=440 b=247 c=261 d=nil]
  e[6] = e[4][K(0)]  -- GETTABLE/CLOSURE? [a=4 b=0 c=6 d=nil]
  goto L_4
end

local function proto40(...)  -- 44 instrs, 9 blocks (structured)
  local e = regs
  ::L_1::
  e[502][K(294)] = e[132]  -- SETTABLE/CALL [a=502 b=294 c=132 d=nil] -- settable/void-call (inferred)
  e[0] = {}  -- NEWTABLE [a=0 b=3 c=0 d=nil]
  e[2] = e[330][K(0)]  -- GETINDEX? [a=330 b=0 c=2 d=nil]
  e[34] = e[159][K(0)]  -- GETTABLE/CLOSURE? [a=159 b=0 c=34 d=nil]
  ::L_32::
  do return end  -- JMP/RETURN [a=0 b=207 c=4 d=nil]
  ::L_2::
  goto L_2
  e[8] = {}  -- NEWTABLE [a=8 b=0 c=0 d=nil]
  e[7] = {}  -- NEWTABLE [a=7 b=0 c=0 d=nil]
  e[9] = {}  -- NEWTABLE [a=0 b=9 c=0 d=nil]
  e[14] = K(19)  -- LOADK_S [a=0 b=19 c=14 d=nil]
  e[15] = K(13)  -- LOADK_S [a=0 b=13 c=15 d=nil]
  e[50] = ">h<"  -- LOADK [a=50 b=1714 c=0 d=>h<]
  e[35] = 2  -- LOADK_N [a=0 b=14 c=35 d=nil]
  e[14] = 4294967293  -- LOADK_N [a=0 b=0 c=14 d=nil]
  e[85] = arith(e[14], e[1742])  -- UNOP/arith? [a=85 b=14 c=1742 d=nil]  -- = 4294967388
  e[54] = e[14] + -4294956211  -- ADD [a=54 b=460 c=14 d=-4294956211]  -- = 11177
  e[14] = arith(e[14], e[1510])  -- UNOP/arith? [a=14 b=14 c=1510 d=nil]  -- = 4
  call(e[14], e[127])  -- CALL [a=14 b=7 c=127 d=nil] -- void call
  e[14] = K(17)  -- LOADK_S [a=0 b=17 c=14 d=nil]
  e[15] = K(19)  -- LOADK_S [a=0 b=19 c=15 d=nil]
  e[16] = 138  -- LOADK [a=16 b=1487 c=0 d=138]
  e[15] = 4294967157  -- LOADK_N [a=0 b=0 c=15 d=nil]
  e[14] = 0  -- LOADK_N [a=0 b=0 c=14 d=nil]
  e[14] = e[14] + 30277  -- ADD [a=14 b=744 c=14 d=30277]  -- = 30277
  e[14] = arith(e[14], e[1183])  -- UNOP/arith? [a=14 b=14 c=1183 d=nil]  -- = 2
  call(e[14], e[127])  -- CALL [a=14 b=9 c=127 d=nil] -- void call
  e[8][K(93)] = e[104]  -- SETTABLE [a=8 b=93 c=104 d=2] -- settable/void-call (inferred)
  call(e[16], e[6])  -- CALL? [a=16 b=0 c=6 d=nil] -- void call
  ::L_25::
  goto L_25
  goto L_32
  e[19] = {}  -- NEWTABLE [a=19 b=0 c=0 d=nil]
  e[18] = {}  -- NEWTABLE [a=18 b=0 c=0 d=nil]
  e[20] = {}  -- NEWTABLE [a=0 b=20 c=0 d=nil]
  e[20][K(84)] = e[108]  -- SETTABLE [a=20 b=84 c=108 d=8] -- settable/void-call (inferred)
  e[18][K(88)] = e[22]  -- SETTABLE [a=18 b=88 c=22 d=9] -- settable/void-call (inferred)
  e[19][K(88)] = e[4]  -- SETTABLE [a=19 b=88 c=4 d=9] -- settable/void-call (inferred)
  e[20][K(3)] = e[100]  -- SETTABLE [a=20 b=3 c=100 d=12] -- settable/void-call (inferred)
  e[20][K(103)] = e[100]  -- SETTABLE [a=20 b=103 c=100 d=11] -- settable/void-call (inferred)
  e[19][K(29)] = e[4]  -- SETTABLE [a=19 b=29 c=4 d=32] -- settable/void-call (inferred)
  e[19][K(61)] = e[16]  -- SETTABLE [a=19 b=61 c=16 d=27] -- settable/void-call (inferred)
  call(e[24], e[17])  -- CALL? [a=24 b=0 c=17 d=nil] -- void call
  goto L_1
end

local function proto41(...)  -- 54 instrs, 19 blocks (structured)
  local e = regs
  ::L_1::
  ::L_50::
  ::L_14::
  goto L_1
  e[195] = e[195][K(1)]  -- GETTABLE [a=195 b=1 c=18 d=nil]
  e[20] = 120  -- LOADK [a=20 b=1936 c=0 d=120]
  e[7] = e[2][K(0)]  -- GETTABLE/CLOSURE? [a=2 b=0 c=7 d=nil]
  -- UNKNOWN op? [a=4 b=0 c=8 d=nil]
  ::L_7::
  e[9] = e[3][K(0)]  -- GETTABLE/CLOSURE? [a=3 b=0 c=9 d=nil]
  e[10] = e[6][120]  -- GETTABLE/CLOSURE? [a=6 b=0 c=10 d=nil]  -- = 120
  ::L_9::
  goto L_22
  e[0] = {}  -- NEWTABLE [a=0 b=6 c=0 d=nil]
  e[3] = e[3][K(1)]  -- GETTABLE [a=3 b=1 c=18 d=nil]
  e[5] = e[5][K(1)]  -- GETTABLE [a=5 b=1 c=18 d=nil]
  e[4] = e[0][K(0)]  -- GETTABLE/CLOSURE? [a=0 b=0 c=4 d=nil]
  goto L_14
  e[30] = {}  -- NEWTABLE [a=30 b=0 c=0 d=nil]
  e[29] = {}  -- NEWTABLE [a=0 b=29 c=0 d=nil]
  e[28] = {}  -- NEWTABLE [a=28 b=0 c=0 d=nil]
  e[29][K(9)] = e[23]  -- SETTABLE [a=29 b=9 c=23 d=4] -- settable/void-call (inferred)
  e[30][K(23)] = e[112]  -- SETTABLE [a=30 b=23 c=112 d=6] -- settable/void-call (inferred)
  e[28][K(93)] = e[128]  -- SETTABLE [a=28 b=93 c=128 d=2] -- settable/void-call (inferred)
  call(e[33], e[26])  -- CALL? [a=33 b=0 c=26 d=nil] -- void call
  ::L_22::
  goto L_51
  e[11] = e[5][K(0)]  -- GETTABLE/CLOSURE? [a=5 b=0 c=11 d=nil]
  ::L_24::
  goto L_7
  e[30] = {}  -- NEWTABLE [a=30 b=0 c=0 d=nil]
  e[28] = {}  -- NEWTABLE [a=28 b=0 c=0 d=nil]
  e[27] = {}  -- NEWTABLE [a=27 b=0 c=0 d=nil]
  e[27][K(54)] = e[4]  -- SETTABLE [a=27 b=54 c=4 d=41] -- settable/void-call (inferred)
  e[27][K(59)] = e[124]  -- SETTABLE [a=27 b=59 c=124 d=42] -- settable/void-call (inferred)
  e[28][K(125)] = e[122]  -- SETTABLE [a=28 b=125 c=122 d=43] -- settable/void-call (inferred)
  e[30][K(125)] = e[1842]  -- SETTABLE [a=30 b=125 c=1842 d=43] -- settable/void-call (inferred)
  e[28][K(35)] = e[126]  -- SETTABLE [a=28 b=35 c=126 d=53] -- settable/void-call (inferred)
  call(e[33], e[26])  -- CALL? [a=33 b=0 c=26 d=nil] -- void call
  ::L_34::
  goto L_34
  e[15] = {}  -- NEWTABLE [a=15 b=0 c=0 d=nil]
  e[16] = {}  -- NEWTABLE [a=0 b=16 c=0 d=nil]
  e[21] = K(11)  -- LOADK_S [a=0 b=11 c=21 d=nil]
  e[22] = 320  -- LOADK [a=22 b=1393 c=0 d=320]
  e[23] = 10  -- LOADK [a=23 b=1353 c=0 d=10]
  e[24] = K(13)  -- LOADK_S [a=0 b=13 c=24 d=nil]
  e[25] = ">xb=>="  -- LOADK [a=25 b=614 c=219 d=>xb=>=]
  e[225] = 2  -- LOADK_N [a=0 b=0 c=225 d=nil]
  e[0] = e[0][0]  -- GETTABLE/CLOSURE [a=0 b=68 c=4 d=nil]  -- = 0
  e[21] = arith(e[21], e[1631])  -- ARITH [a=21 b=21 c=1631 d=nil]  -- = -164
  e[21] = e[21] + 18797  -- ADD [a=21 b=263 c=21 d=18797]  -- = 18633
  e[21] = arith(e[21], e[265])  -- UNOP/arith? [a=21 b=21 c=265 d=nil]  -- = 2
  call(e[21], e[111])  -- CALL [a=21 b=16 c=111 d=nil] -- void call
  e[15][K(94)] = e[93]  -- SETTABLE [a=15 b=94 c=93 d=52] -- settable/void-call (inferred)
  call(e[25], e[13])  -- CALL? [a=25 b=0 c=13 d=nil] -- void call
  goto L_50
  ::L_51::
  goto L_9
  ::L_52::
  goto L_52
  goto L_24
  -- UNKNOWN op? [a=270 b=237 c=285 d=nil]
end

local function proto42(...)  -- 200 instrs, 92 blocks (structured)
  local e = regs
  ::L_1::
  ::L_193::
  ::L_57::
  goto L_1
  e[2] = K(2)  -- LOADK_N [a=9 b=2 c=74 d=nil]
  e[10] = e[4][K(0)]  -- GETTABLE/CLOSURE? [a=4 b=0 c=10 d=nil]
  e[11] = e[11]["rawset"]  -- GETTABLE [a=11 b=1 c=1476 d=nil]  -- = "rawset"
  ::L_5::
  do return end  -- JMP/RETURN [a=178 b=201 c=0 d=nil]
  ::L_6::
  goto L_186
  ::L_7::
  goto L_194
  ::L_8::
  goto L_92
  ::L_9::
  if e[106] then goto L_84 end
  ::L_10::
  goto L_29
  e[10] = e[10]["lastlinedefined"]  -- GETTABLE [a=10 b=1 c=1363 d=nil]  -- = "lastlinedefined"
  e[10][K(166)] = e[1997]  -- SETTABLE/CALL [a=10 b=166 c=1997 d=nil] -- settable/void-call (inferred)
  e[10] = e[10]["source"]  -- GETTABLE [a=10 b=1 c=684 d=nil]  -- = "source"
  e[11] = e[11]["=[C]"]  -- GETTABLE [a=11 b=1 c=1220 d=nil]  -- = "=[C]"
  e[10][K(11)] = e[9]  -- SETTABLE/CALL [a=10 b=11 c=9 d=nil] -- settable/void-call (inferred)
  ::L_16::
  goto L_136
  e[28] = {}  -- NEWTABLE [a=28 b=0 c=0 d=nil]
  e[29] = {}  -- NEWTABLE [a=29 b=0 c=0 d=nil]
  e[28][K(2229)] = e[84]  -- SETTABLE [a=28 b=2229 c=84 d=155] -- settable/void-call (inferred)
  e[29][K(1808)] = e[938]  -- SETTABLE [a=29 b=1808 c=938 d=125] -- settable/void-call (inferred)
  call(e[34], e[27])  -- CALL? [a=34 b=0 c=27 d=nil] -- void call
  ::L_22::
  goto L_170
  e[31] = {}  -- NEWTABLE [a=31 b=0 c=0 d=nil]
  e[29] = {}  -- NEWTABLE [a=29 b=0 c=0 d=nil]
  e[31][K(52)] = e[94]  -- SETTABLE [a=31 b=52 c=94 d=58] -- settable/void-call (inferred)
  e[29][K(52)] = e[16]  -- SETTABLE [a=29 b=52 c=16 d=58] -- settable/void-call (inferred)
  e[29][K(60)] = e[1331]  -- SETTABLE [a=29 b=60 c=1331 d=35] -- settable/void-call (inferred)
  call(e[34], e[27])  -- CALL? [a=34 b=0 c=27 d=nil] -- void call
  ::L_29::
  goto L_176
  ::L_30::
  goto L_76
  e[9] = e[88][K(0)]  -- GETINDEX? [a=88 b=0 c=9 d=nil]
  call(e[9], e[74])  -- CALL [a=9 b=2 c=74 d=nil] -- void call
  e[8] = 119  -- LOADK [a=8 b=1144 c=0 d=119]
  ::L_34::
  goto L_161
  ::L_35::
  goto L_22
  if e[5] then goto L_117 end
  ::L_37::
  goto L_135
  e[8] = 13  -- LOADK [a=8 b=2280 c=0 d=13]
  ::L_39::
  goto L_106
  e[17] = {}  -- NEWTABLE [a=17 b=0 c=0 d=nil]
  e[19] = {}  -- NEWTABLE [a=19 b=0 c=0 d=nil]
  e[23] = K(16)  -- LOADK_S [a=0 b=16 c=23 d=nil]
  e[24] = K(17)  -- LOADK_S [a=0 b=17 c=24 d=nil]
  e[125] = 154  -- LOADK [a=125 b=181 c=0 d=154]
  e[24] = 1  -- LOADK_N [a=0 b=0 c=24 d=nil]
  e[25] = K(15)  -- LOADK_S [a=0 b=15 c=25 d=nil]
  call(e[134], e[90])  -- CALL [a=134 b=238 c=90 d=nil] -- void call
  e[26][K(239)] = e[162]  -- SETTABLE/CALL [a=26 b=239 c=162 d=�] -- settable/void-call (inferred)
  e[168] = K(157)  -- LOADK_S [a=168 b=157 c=164 d=nil]
  e[25] = 1  -- LOADK_N [a=0 b=0 c=25 d=nil]
  ::L_51::
  e[23] = 0  -- LOADK_N [a=0 b=23 c=0 d=nil]
  e[23] = e[23] + 20668  -- ADD [a=23 b=2320 c=23 d=20668]  -- = 20668
  e[23] = arith(e[23], e[2162])  -- UNOP/arith? [a=23 b=23 c=2162 d=nil]  -- = 105
  call(e[23], e[93])  -- CALL [a=23 b=19 c=93 d=nil] -- void call
  e[17][K(57)] = e[16]  -- SETTABLE [a=17 b=57 c=16 d=77] -- settable/void-call (inferred)
  call(e[26], e[15])  -- CALL? [a=26 b=0 c=15 d=nil] -- void call
  goto L_57
  call(e[9], e[1548])  -- CALL [a=9 b=81 c=1548 d=nil] -- void call
  e[11] = e[5][K(0)]  -- GETTABLE/CLOSURE? [a=5 b=0 c=11 d=nil]
  e[12] = e[3][K(0)]  -- GETTABLE/CLOSURE? [a=3 b=0 c=12 d=nil]
  goto L_111
  e[9] = e[9][K(2)]  -- GETTABLE [a=9 b=2 c=74 d=nil]
  e[10] = e[10][K(2)]  -- GETTABLE [a=10 b=2 c=736 d=nil]
  e[11] = e[11]["setmetatable"]  -- GETTABLE [a=11 b=1 c=1837 d=nil]  -- = "setmetatable"
  ::L_65::
  goto L_125
  e[29] = {}  -- NEWTABLE [a=29 b=0 c=0 d=nil]
  e[30] = {}  -- NEWTABLE [a=0 b=30 c=0 d=nil]
  e[30][K(764)] = e[88]  -- SETTABLE [a=30 b=764 c=88 d=157] -- settable/void-call (inferred)
  e[29][K(1528)] = e[469]  -- SETTABLE [a=29 b=1528 c=469 d=118] -- settable/void-call (inferred)
  e[34][K(243)] = e[27]  -- SETTABLE/CALL [a=34 b=243 c=27 d=nil] -- settable/void-call (inferred)
  ::L_71::
  goto L_184
  e[12] = e[3][K(0)]  -- GETTABLE/CLOSURE? [a=3 b=0 c=12 d=nil]
  e[13] = e[8][8]  -- GETTABLE/CLOSURE? [a=8 b=0 c=13 d=nil]  -- = 8
  ::L_74::
  goto L_9
  if e[2361] then goto L_30 end  -- back-edge (loop)
  ::L_76::
  goto L_7
  goto L_39
  ::L_78::
  goto L_96
  if e[77] then goto L_118 end
  ::L_80::
  goto L_168
  e[10][K(68)] = e[9]  -- SETTABLE/CALL [a=10 b=68 c=9 d=nil] -- settable/void-call (inferred)
  e[10] = e[10]["short_src"]  -- GETTABLE [a=10 b=1 c=2305 d=nil]  -- = "short_src"
  e[10][K(188)] = e[904]  -- SETTABLE/CALL [a=10 b=188 c=904 d=nil] -- settable/void-call (inferred)
  ::L_84::
  call(e[10], e[89])  -- CALL [a=10 b=228 c=89 d=nil] -- void call
  e[157][K(1)] = e[125]  -- SETTABLE/CALL [a=157 b=1 c=125 d=nil] -- settable/void-call (inferred)
  e[189][K(3)] = e[1503]  -- SETTABLE/CALL [a=189 b=3 c=1503 d=nil] -- settable/void-call (inferred)
  e[189] = K(232)  -- LOADK_S [a=189 b=232 c=85 d=nil]
  e[10][K(9)] = e[4]  -- SETTABLE/CALL [a=10 b=9 c=4 d=nil] -- settable/void-call (inferred)
  e[10] = e[10]["isvararg"]  -- GETTABLE [a=10 b=1 c=414 d=nil]  -- = "isvararg"
  e[11] = e[11][true]  -- GETTABLE [a=11 b=1 c=1935 d=nil]  -- = true
  e[10][K(11)] = e[9]  -- SETTABLE/CALL [a=10 b=11 c=9 d=nil] -- settable/void-call (inferred)
  ::L_92::
  goto L_10
  ::L_93::
  goto L_143
  ::L_94::
  goto L_124
  if e[61] then goto L_51 end  -- back-edge (loop)
  ::L_96::
  goto L_192
  e[30] = {}  -- NEWTABLE [a=0 b=30 c=0 d=nil]
  e[29] = {}  -- NEWTABLE [a=29 b=0 c=0 d=nil]
  e[29][K(99)] = e[88]  -- SETTABLE [a=29 b=99 c=88 d=5] -- settable/void-call (inferred)
  e[30][K(99)] = e[4]  -- SETTABLE [a=30 b=99 c=4 d=5] -- settable/void-call (inferred)
  e[30][K(51)] = e[104]  -- SETTABLE [a=30 b=51 c=104 d=44] -- settable/void-call (inferred)
  e[30][K(1778)] = e[81]  -- SETTABLE [a=30 b=1778 c=81 d=188] -- settable/void-call (inferred)
  e[29][K(1778)] = e[4]  -- SETTABLE [a=29 b=1778 c=4 d=188] -- settable/void-call (inferred)
  e[29][K(28)] = e[84]  -- SETTABLE [a=29 b=28 c=84 d=78] -- settable/void-call (inferred)
  e[34][K(14)] = e[27]  -- SETTABLE/CALL [a=34 b=14 c=27 d=nil] -- settable/void-call (inferred)
  ::L_106::
  goto L_8
  ::L_107::
  goto L_162
  if e[9] then goto L_5 end  -- back-edge (loop)
  e[4] = e[9][K(0)]  -- GETTABLE/CLOSURE? [a=9 b=0 c=4 d=nil]
  e[8] = e[10][65]  -- GETTABLE/CLOSURE? [a=10 b=0 c=8 d=nil]  -- = 65
  ::L_111::
  goto L_128
  e[12] = e[2][K(0)]  -- GETTABLE/CLOSURE? [a=2 b=0 c=12 d=nil]
  e[9] = K(9)  -- LOADK_N [a=0 b=9 c=5 d=nil]
  e[81][K(35)] = e[3]  -- SETTABLE/CALL [a=81 b=35 c=3 d=nil] -- settable/void-call (inferred)
  call(e[9], e[225])  -- CALL [a=9 b=202 c=225 d=nil] -- void call
  e[89] = K(227)  -- LOADK_S [a=89 b=227 c=120 d=nil]
  ::L_117::
  goto L_169
  ::L_118::
  goto L_65
  e[28] = {}  -- NEWTABLE [a=28 b=0 c=0 d=nil]
  e[29] = {}  -- NEWTABLE [a=29 b=0 c=0 d=nil]
  e[28][K(571)] = e[118]  -- SETTABLE [a=28 b=571 c=118 d=112] -- settable/void-call (inferred)
  e[29][K(981)] = e[60]  -- SETTABLE [a=29 b=981 c=60 d=162] -- settable/void-call (inferred)
  call(e[34], e[27])  -- CALL? [a=34 b=0 c=27 d=nil] -- void call
  ::L_124::
  goto L_35
  ::L_125::
  goto L_16
  goto L_9
  e[8] = 44  -- LOADK [a=8 b=1673 c=0 d=44]
  ::L_128::
  goto L_161
  ::L_129::
  goto L_161
  e[0] = arith(e[0], e[9])  -- ARITH [a=0 b=0 c=9 d=nil]
  e[6] = e[9][K(0)]  -- GETTABLE/CLOSURE? [a=9 b=0 c=6 d=nil]
  e[9] = {}  -- NEWTABLE [a=0 b=0 c=9 d=nil]
  e[10] = e[10]["namewhat"]  -- GETTABLE [a=10 b=1 c=2136 d=nil]  -- = "namewhat"
  e[11] = e[11][""]  -- GETTABLE [a=11 b=1 c=320 d=nil]  -- = ""
  ::L_135::
  goto L_6
  ::L_136::
  goto L_94
  e[10] = e[10]["what"]  -- GETTABLE [a=10 b=1 c=2405 d=nil]  -- = "what"
  e[236] = e[236]["C"]  -- GETTABLE [a=236 b=107 c=1839 d=nil]  -- = "C"
  e[10][K(11)] = e[9]  -- SETTABLE/CALL [a=10 b=11 c=9 d=nil] -- settable/void-call (inferred)
  e[10] = e[10]["linedefined"]  -- GETTABLE [a=10 b=1 c=1327 d=nil]  -- = "linedefined"
  e[10][K(9)] = e[1997]  -- SETTABLE/CALL [a=10 b=9 c=1997 d=nil] -- settable/void-call (inferred)
  e[10] = e[10]["currentline"]  -- GETTABLE [a=10 b=1 c=1485 d=nil]  -- = "currentline"
  ::L_143::
  goto L_178
  e[30] = {}  -- NEWTABLE [a=0 b=30 c=0 d=nil]
  e[31] = {}  -- NEWTABLE [a=31 b=0 c=0 d=nil]
  e[29] = {}  -- NEWTABLE [a=29 b=0 c=0 d=nil]
  e[31][K(973)] = e[1627]  -- SETTABLE [a=31 b=973 c=1627 d=130] -- settable/void-call (inferred)
  e[29][K(12)] = e[16]  -- SETTABLE [a=29 b=12 c=16 d=138] -- settable/void-call (inferred)
  e[30][K(12)] = e[103]  -- SETTABLE [a=30 b=12 c=103 d=138] -- settable/void-call (inferred)
  e[29][K(3)] = e[88]  -- SETTABLE [a=29 b=3 c=88 d=12] -- settable/void-call (inferred)
  e[29][K(80)] = e[2241]  -- SETTABLE [a=29 b=80 c=2241 d=93] -- settable/void-call (inferred)
  e[34][K(171)] = e[27]  -- SETTABLE/CALL [a=34 b=171 c=27 d=nil] -- settable/void-call (inferred)
  ::L_153::
  goto L_129
  e[9] = K(9)  -- LOADK_N [a=0 b=9 c=4 d=nil]
  e[87] = e[9][8]  -- GETTABLE/CLOSURE? [a=9 b=0 c=87 d=nil]  -- = 8
  ::L_156::
  goto L_106
  e[1] = e[20]  -- MOVE [a=20 b=1 c=2127 d=nil]
  e[11] = e[8][106]  -- GETTABLE/CLOSURE? [a=8 b=0 c=11 d=nil]  -- = 106
  e[12] = e[4][K(0)]  -- GETTABLE/CLOSURE? [a=4 b=0 c=12 d=nil]
  e[13] = e[2][K(0)]  -- GETTABLE/CLOSURE? [a=2 b=0 c=13 d=nil]
  ::L_161::
  goto L_107
  ::L_162::
  goto L_118
  e[29] = {}  -- NEWTABLE [a=29 b=0 c=0 d=nil]
  e[31] = {}  -- NEWTABLE [a=31 b=0 c=0 d=nil]
  e[31][K(1779)] = e[94]  -- SETTABLE [a=31 b=1779 c=94 d=171] -- settable/void-call (inferred)
  e[29][K(989)] = e[28]  -- SETTABLE [a=29 b=989 c=28 d=107] -- settable/void-call (inferred)
  call(e[34], e[27])  -- CALL? [a=34 b=0 c=27 d=nil] -- void call
  ::L_168::
  goto L_78
  ::L_169::
  goto L_93
  ::L_170::
  goto L_37
  -- UNKNOWN op? [a=9 b=1 c=695 d=nil]
  e[201][K(75)] = e[11]  -- SETTABLE/CALL [a=201 b=75 c=11 d=nil] -- settable/void-call (inferred)
  call(e[2], e[213])  -- CALL [a=2 b=0 c=213 d=nil] -- void call
  e[215] = K(41)  -- LOADK_S [a=215 b=41 c=212 d=nil]
  e[12] = e[8][13]  -- GETTABLE/CLOSURE? [a=8 b=0 c=12 d=nil]  -- = 13
  ::L_176::
  goto L_153
  e[0] = {}  -- NEWTABLE [a=0 b=8 c=0 d=nil]
  ::L_178::
  goto L_161
  e[10][K(9)] = e[1997]  -- SETTABLE/CALL [a=10 b=9 c=1997 d=nil] -- settable/void-call (inferred)
  e[102][K(200)] = e[7]  -- SETTABLE/CALL [a=102 b=200 c=7 d=nil] -- settable/void-call (inferred)
  call(e[9], e[119])  -- CALL [a=9 b=153 c=119 d=nil] -- void call
  e[164] = K(210)  -- LOADK_S [a=164 b=210 c=79 d=nil]
  e[8] = 106  -- LOADK [a=8 b=17 c=0 d=106]
  ::L_184::
  goto L_161
  if e[121] then goto L_74 end  -- back-edge (loop)
  ::L_186::
  goto L_190
  e[9] = e[4][K(0)]  -- GETTABLE/CLOSURE? [a=4 b=0 c=9 d=nil]
  e[10] = e[234][K(161)]  -- GETTABLE/CLOSURE? [a=234 b=161 c=10 d=nil]
  e[11] = e[6][K(0)]  -- GETTABLE/CLOSURE? [a=6 b=0 c=11 d=nil]
  ::L_190::
  goto L_71
  goto L_156
  ::L_192::
  -- UNKNOWN op? [a=96 b=189 c=50 d=nil]
  goto L_193
  ::L_194::
  goto L_34
  e[29] = {}  -- NEWTABLE [a=29 b=0 c=0 d=nil]
  e[29][K(44)] = e[88]  -- SETTABLE [a=29 b=44 c=88 d=83] -- settable/void-call (inferred)
  e[29][K(120)] = e[103]  -- SETTABLE [a=29 b=120 c=103 d=81] -- settable/void-call (inferred)
  e[29][K(81)] = e[58]  -- SETTABLE [a=29 b=81 c=58 d=7] -- settable/void-call (inferred)
  call(e[34], e[27])  -- CALL? [a=34 b=0 c=27 d=nil] -- void call
  goto L_80
end

local function proto43(...)  -- 66 instrs, 19 blocks (structured)
  local e = regs
  ::L_1::
  goto L_1
  ::L_2::
  goto L_59
  ::L_3::
  goto L_51
  e[2] = 65  -- LOADK [a=2 b=961 c=0 d=65]
  ::L_5::
  e[110] = e[3][K(0)]  -- GETTABLE/CLOSURE? [a=3 b=0 c=110 d=nil]
  e[6] = e[2][65]  -- GETTABLE/CLOSURE? [a=2 b=0 c=6 d=nil]  -- = 65
  ::L_7::
  goto L_5
  e[0] = {}  -- NEWTABLE [a=0 b=4 c=0 d=nil]
  e[49] = e[49][K(135)]  -- GETTABLE [a=49 b=135 c=74 d=nil]
  call(e[6], e[243])  -- CALL [a=6 b=177 c=243 d=nil] -- void call
  e[230][K(4)] = e[98]  -- SETTABLE/CALL [a=230 b=4 c=98 d=nil] -- settable/void-call (inferred)
  e[251][K(116)] = e[107]  -- SETTABLE/CALL [a=251 b=116 c=107 d=nil] -- settable/void-call (inferred)
  e[0] = K(132)  -- LOADK_S [a=0 b=132 c=91 d=nil]
  e[7] = e[7]["getmetatable"]  -- GETTABLE [a=7 b=1 c=961 d=nil]  -- = "getmetatable"
  goto L_5
  e[3] = e[3][K(1)]  -- GETTABLE [a=3 b=1 c=210 d=nil]
  ::L_17::
  goto L_2
  e[9] = {}  -- NEWTABLE [a=9 b=0 c=0 d=nil]
  e[10] = {}  -- NEWTABLE [a=10 b=0 c=0 d=nil]
  e[16] = K(11)  -- LOADK_S [a=0 b=11 c=16 d=nil]
  e[17] = 32  -- LOADK [a=17 b=1829 c=155 d=32]
  e[18] = K(15)  -- LOADK_S [a=0 b=15 c=18 d=nil]
  e[19] = "o196"  -- LOADK [a=19 b=1181 c=0 d=o�]
  e[18] = 2  -- LOADK_N [a=198 b=0 c=18 d=nil]
  e[19] = K(9)  -- LOADK_S [a=0 b=9 c=19 d=nil]
  e[20] = "Q"  -- LOADK [a=20 b=583 c=96 d=Q]
  e[21] = 1  -- LOADK [a=21 b=107 c=0 d=1]
  call(e[22], e[0])  -- CALL [a=22 b=0 c=0 d=nil] -- void call
  e[19] = 81  -- LOADK_N [a=0 b=19 c=4 d=nil]
  e[16] = 0  -- LOADK_N [a=141 b=16 c=4 d=nil]
  e[212][K(16)] = e[170]  -- SETTABLE/CALL [a=212 b=16 c=170 d=nil] -- settable/void-call (inferred)
  e[16][K(224)] = e[255]  -- SETTABLE/CALL [a=16 b=224 c=255 d=nil] -- settable/void-call (inferred)
  e[69] = arith(e[188], e[254])  -- ARITH [a=69 b=188 c=254 d=nil]
  e[16] = e[16] + 21166  -- ADD [a=16 b=429 c=16 d=21166]  -- = 21644
  e[16] = arith(e[16], e[382])  -- UNOP/arith? [a=16 b=16 c=382 d=nil]  -- = 5
  call(e[16], e[99])  -- CALL [a=16 b=9 c=99 d=nil] -- void call
  e[10][K(53)] = e[81]  -- SETTABLE [a=10 b=53 c=81 d=50] -- settable/void-call (inferred)
  call(e[22], e[8])  -- CALL? [a=22 b=0 c=8 d=nil] -- void call
  ::L_39::
  goto L_7
  e[25] = {}  -- NEWTABLE [a=25 b=0 c=0 d=nil]
  e[26] = {}  -- NEWTABLE [a=0 b=26 c=0 d=nil]
  e[24] = {}  -- NEWTABLE [a=24 b=0 c=0 d=nil]
  e[24][K(19)] = e[4]  -- SETTABLE [a=24 b=19 c=4 d=26] -- settable/void-call (inferred)
  e[24][K(122)] = e[4]  -- SETTABLE [a=24 b=122 c=4 d=21] -- settable/void-call (inferred)
  e[26][K(124)] = e[4]  -- SETTABLE [a=26 b=124 c=4 d=24] -- settable/void-call (inferred)
  e[26][K(24)] = e[4]  -- SETTABLE [a=26 b=24 c=4 d=30] -- settable/void-call (inferred)
  e[25][K(101)] = e[47]  -- SETTABLE [a=25 b=101 c=47 d=59] -- settable/void-call (inferred)
  call(e[30], e[23])  -- CALL? [a=30 b=0 c=23 d=nil] -- void call
  ::L_49::
  goto L_57
  goto L_17
  ::L_51::
  -- UNKNOWN op? [a=358 b=83 c=176 d=nil]
  e[26] = {}  -- NEWTABLE [a=0 b=26 c=0 d=nil]
  e[25] = {}  -- NEWTABLE [a=25 b=0 c=0 d=nil]
  e[26][K(81)] = e[111]  -- SETTABLE [a=26 b=81 c=111 d=7] -- settable/void-call (inferred)
  e[25][K(111)] = e[111]  -- SETTABLE [a=25 b=111 c=111 d=3] -- settable/void-call (inferred)
  e[30][K(211)] = e[23]  -- SETTABLE/CALL [a=30 b=211 c=23 d=nil] -- settable/void-call (inferred)
  ::L_57::
  goto L_3
  ::L_59::
  goto L_39
  e[25] = {}  -- NEWTABLE [a=25 b=0 c=0 d=nil]
  e[26] = {}  -- NEWTABLE [a=0 b=26 c=0 d=nil]
  e[26][K(88)] = e[99]  -- SETTABLE [a=26 b=88 c=99 d=9] -- settable/void-call (inferred)
  e[25][K(88)] = e[9]  -- SETTABLE [a=25 b=88 c=9 d=9] -- settable/void-call (inferred)
  e[25][K(93)] = e[71]  -- SETTABLE [a=25 b=93 c=71 d=2] -- settable/void-call (inferred)
  e[30][K(85)] = e[23]  -- SETTABLE/CALL [a=30 b=85 c=23 d=nil] -- settable/void-call (inferred)
  goto L_49
end

local function proto44(...)  -- 5 instrs, 5 blocks (structured)
  local e = regs
  ::L_1::
  ::L_3::
  goto L_1
  e[0] = {}  -- NEWTABLE [a=0 b=2 c=0 d=nil]
  goto L_3
  goto L_1
  -- UNKNOWN op? [a=482 b=356 c=461 d=nil]
end

local function proto45(...)  -- 44 instrs, 12 blocks (structured)
  local e = regs
  ::L_1::
  goto L_1
  e[23] = {}  -- NEWTABLE [a=23 b=0 c=0 d=nil]
  e[25] = {}  -- NEWTABLE [a=25 b=0 c=0 d=nil]
  e[22] = {}  -- NEWTABLE [a=22 b=0 c=0 d=nil]
  e[24] = {}  -- NEWTABLE [a=0 b=24 c=0 d=nil]
  e[24][K(104)] = e[114]  -- SETTABLE [a=24 b=104 c=114 d=25] -- settable/void-call (inferred)
  e[22][K(19)] = e[20]  -- SETTABLE [a=22 b=19 c=20 d=26] -- settable/void-call (inferred)
  e[25][K(19)] = e[96]  -- SETTABLE [a=25 b=19 c=96 d=26] -- settable/void-call (inferred)
  e[23][K(19)] = e[4]  -- SETTABLE [a=23 b=19 c=4 d=26] -- settable/void-call (inferred)
  e[23][K(1)] = e[9]  -- SETTABLE [a=23 b=1 c=9 d=38] -- settable/void-call (inferred)
  e[22][K(1)] = e[4]  -- SETTABLE [a=22 b=1 c=4 d=38] -- settable/void-call (inferred)
  e[23][K(110)] = e[55]  -- SETTABLE [a=23 b=110 c=55 d=20] -- settable/void-call (inferred)
  call(e[28], e[21])  -- CALL? [a=28 b=0 c=21 d=nil] -- void call
  ::L_14::
  goto L_37
  ::L_16::
  goto L_19
  e[0] = {}  -- NEWTABLE [a=0 b=5 c=0 d=nil]
  e[5] = e[3][K(0)]  -- GETTABLE/CLOSURE? [a=3 b=0 c=5 d=nil]
  ::L_19::
  do return end  -- JMP/RETURN [a=0 b=0 c=5 d=nil]
  e[10] = {}  -- NEWTABLE [a=10 b=0 c=0 d=nil]
  e[12] = {}  -- NEWTABLE [a=12 b=0 c=0 d=nil]
  e[16] = K(11)  -- LOADK_S [a=0 b=11 c=16 d=nil]
  e[17] = K(11)  -- LOADK_S [a=0 b=11 c=17 d=nil]
  e[92] = 467  -- LOADK [a=92 b=1671 c=0 d=467]
  e[0][467] = e[31]  -- SETTABLE/CALL [a=0 b=114 c=31 d=nil] -- settable/void-call (inferred)
  e[18] = K(8)  -- LOADK_S [a=0 b=8 c=18 d=nil]
  e[19] = "<i8"  -- LOADK [a=19 b=77 c=0 d=<i8]
  e[20] = "128000000000000000000000"  -- LOADK [a=20 b=974 c=0 d=�       ]
  e[18] = 128  -- LOADK_N [a=0 b=18 c=0 d=nil]
  e[16] = 128  -- LOADK_N [a=0 b=16 c=0 d=nil]
  e[16] = e[16] + 19613  -- ADD [a=16 b=2352 c=16 d=19613]  -- = 19741
  e[16] = arith(e[16], e[1625])  -- UNOP/arith? [a=16 b=16 c=1625 d=nil]  -- = 46
  call(e[16], e[20])  -- CALL [a=16 b=12 c=20 d=nil] -- void call
  e[10][K(22)] = e[108]  -- SETTABLE [a=10 b=22 c=108 d=15] -- settable/void-call (inferred)
  call(e[20], e[8])  -- CALL? [a=20 b=0 c=8 d=nil] -- void call
  ::L_37::
  goto L_16
  e[0] = {}  -- NEWTABLE [a=0 b=47 c=103 d=nil]
  e[3] = e[3][K(1)]  -- GETTABLE [a=3 b=1 c=1913 d=nil]
  e[5] = e[5][K(4)]  -- GETTABLE [a=5 b=4 c=74 d=nil]
  e[6] = e[2][K(0)]  -- GETTABLE/CLOSURE? [a=2 b=0 c=6 d=nil]
  e[7] = e[7]["tonumber"]  -- GETTABLE [a=7 b=1 c=272 d=nil]  -- = "tonumber"
  goto L_14
  -- UNKNOWN op? [a=283 b=384 c=180 d=nil]
end

local function proto46(...)  -- 37 instrs, 14 blocks (structured)
  local e = regs
  ::L_1::
  ::L_19::
  ::L_36::
  do return end  -- JMP/RETURN [a=0 b=0 c=4 d=nil]
  ::L_3::
  goto L_27
  e[0] = {}  -- NEWTABLE [a=0 b=3 c=0 d=nil]
  e[4] = e[4][K(2)]  -- GETTABLE [a=4 b=2 c=74 d=nil]
  e[5] = e[5][K(2)]  -- GETTABLE [a=5 b=2 c=90 d=nil]
  e[6] = e[6]["tostring"]  -- GETTABLE [a=6 b=1 c=926 d=nil]  -- = "tostring"
  do return end  -- JMP/RETURN [a=0 b=195 c=0 d=nil]
  e[9] = {}  -- NEWTABLE [a=9 b=0 c=0 d=nil]
  e[1] = 124  -- LOADK_N [a=2280 b=2200 c=1 d=111]
  e[15] = arith(e[15], e[926])  -- ARITH [a=15 b=15 c=926 d=nil]  -- = 45
  e[151] = e[15] + 31268  -- ADD [a=151 b=1818 c=15 d=31268]  -- = 31313
  e[15] = arith(e[15], e[424])  -- UNOP/arith? [a=15 b=15 c=424 d=nil]  -- = 4
  call(e[15], e[84])  -- CALL [a=15 b=9 c=84 d=nil] -- void call
  e[9][K(93)] = e[106]  -- SETTABLE [a=9 b=93 c=106 d=2] -- settable/void-call (inferred)
  e[16][K(72)] = e[7]  -- SETTABLE/CALL [a=16 b=72 c=7 d=nil] -- settable/void-call (inferred)
  goto L_19
  e[18] = {}  -- NEWTABLE [a=18 b=0 c=0 d=nil]
  e[20] = {}  -- NEWTABLE [a=0 b=20 c=0 d=nil]
  e[19] = {}  -- NEWTABLE [a=19 b=0 c=0 d=nil]
  e[20][K(100)] = e[22]  -- SETTABLE [a=20 b=100 c=22 d=14] -- settable/void-call (inferred)
  e[18][K(3)] = e[22]  -- SETTABLE [a=18 b=3 c=22 d=12] -- settable/void-call (inferred)
  e[19][K(42)] = e[16]  -- SETTABLE [a=19 b=42 c=16 d=10] -- settable/void-call (inferred)
  call(e[24], e[17])  -- CALL? [a=24 b=0 c=17 d=nil] -- void call
  ::L_27::
  goto L_1
  e[19] = {}  -- NEWTABLE [a=19 b=0 c=0 d=nil]
  e[19][K(60)] = e[4]  -- SETTABLE [a=19 b=60 c=4 d=35] -- settable/void-call (inferred)
  e[19][K(111)] = e[37]  -- SETTABLE [a=19 b=111 c=37 d=3] -- settable/void-call (inferred)
  e[24][K(49)] = e[17]  -- SETTABLE/CALL [a=24 b=49 c=17 d=nil] -- settable/void-call (inferred)
  -- UNKNOWN op? [a=396 b=352 c=118 d=nil]
  e[3] = 8  -- LOADK [a=3 b=1805 c=0 d=8]
  e[4] = e[3][8]  -- GETTABLE/CLOSURE? [a=3 b=195 c=4 d=nil]  -- = 8
  goto L_36
  goto L_3
end

local function proto47(...)  -- 168 instrs, 89 blocks (structured)
  local e = regs
  ::L_1::
  ::L_164::
  ::L_71::
  ::L_53::
  ::L_146::
  ::L_56::
  ::L_133::
  ::L_43::
  ::L_127::
  ::L_94::
  ::L_11::
  ::L_149::
  ::L_26::
  do return end  -- JMP/RETURN [a=0 b=0 c=11 d=nil]
  ::L_2::
  -- UNKNOWN op? [a=0 b=56 c=0 d=nil]
  e[17] = {}  -- NEWTABLE [a=17 b=0 c=0 d=nil]
  e[18] = {}  -- NEWTABLE [a=0 b=18 c=0 d=nil]
  e[18][K(20)] = e[42]  -- SETTABLE [a=18 b=20 c=42 d=17] -- settable/void-call (inferred)
  e[18][K(66)] = e[3]  -- SETTABLE [a=18 b=66 c=3 d=74] -- settable/void-call (inferred)
  e[17][K(1528)] = e[108]  -- SETTABLE [a=17 b=1528 c=108 d=118] -- settable/void-call (inferred)
  e[22][K(139)] = e[15]  -- SETTABLE/CALL [a=22 b=139 c=15 d=nil] -- settable/void-call (inferred)
  ::L_9::
  goto L_16
  ::L_10::
  goto L_10
  e[12] = e[12]["pcall"]  -- GETTABLE [a=12 b=1 c=381 d=nil]  -- = "pcall"
  goto L_10
  e[10] = e[10][K(1)]  -- GETTABLE [a=10 b=1 c=18 d=nil]
  e[9] = 39  -- LOADK [a=9 b=167 c=0 d=39]
  ::L_16::
  goto L_56
  e[140] = e[140][K(7)]  -- GETTABLE [a=140 b=7 c=74 d=nil]
  e[11] = e[6][K(0)]  -- GETTABLE/CLOSURE? [a=6 b=0 c=11 d=nil]
  e[12] = e[12]["xpcall"]  -- GETTABLE [a=12 b=1 c=2062 d=nil]  -- = "xpcall"
  ::L_20::
  goto L_9
  ::L_21::
  goto L_114
  if e[61] then do return end else goto L_23 end
  ::L_23::
  goto L_50
  goto L_11
  e[11] = e[9][11]  -- GETTABLE/CLOSURE? [a=9 b=0 c=11 d=nil]  -- = 11
  goto L_26
  e[9] = 92  -- LOADK [a=9 b=358 c=0 d=92]
  ::L_28::
  goto L_55
  e[11] = e[11][K(7)]  -- GETTABLE [a=11 b=7 c=74 d=nil]
  e[12] = e[12][K(7)]  -- GETTABLE [a=12 b=7 c=18 d=nil]
  e[13] = e[13]["gmatch"]  -- GETTABLE [a=13 b=1 c=1828 d=nil]  -- = "gmatch"
  ::L_32::
  goto L_23
  ::L_33::
  dataop(e[11], e[7], e[74])  -- DATAOP [a=11 b=7 c=74 d=nil]
  e[12] = e[12][K(7)]  -- GETTABLE [a=12 b=7 c=70 d=nil]
  e[13] = e[13]["typeof"]  -- GETTABLE [a=13 b=1 c=198 d=nil]  -- = "typeof"
  goto L_11
  ::L_37::
  goto L_68
  e[17] = {}  -- NEWTABLE [a=17 b=0 c=0 d=nil]
  e[19] = {}  -- NEWTABLE [a=19 b=0 c=0 d=nil]
  e[19][K(52)] = e[8]  -- SETTABLE [a=19 b=52 c=8 d=58] -- settable/void-call (inferred)
  e[17][K(383)] = e[47]  -- SETTABLE [a=17 b=383 c=47 d=104] -- settable/void-call (inferred)
  call(e[22], e[15])  -- CALL? [a=22 b=0 c=15 d=nil] -- void call
  goto L_43
  e[19] = {}  -- NEWTABLE [a=19 b=0 c=0 d=nil]
  e[17] = {}  -- NEWTABLE [a=17 b=0 c=0 d=nil]
  e[19][K(37)] = e[41]  -- SETTABLE [a=19 b=37 c=41 d=33] -- settable/void-call (inferred)
  e[17][K(2268)] = e[29]  -- SETTABLE [a=17 b=2268 c=29 d=134] -- settable/void-call (inferred)
  e[22][K(254)] = e[15]  -- SETTABLE/CALL [a=22 b=254 c=15 d=nil] -- settable/void-call (inferred)
  ::L_49::
  goto L_32
  ::L_50::
  goto L_117
  goto L_49
  if e[1357] then goto L_56 else goto L_53 end  -- back-edge (loop)
  ::L_54::
  goto L_139
  ::L_55::
  goto L_118
  call(e[12], e[0])  -- CALL [a=12 b=677 c=0 d=rawget] -- void call
  goto L_10
  e[9] = 119  -- LOADK [a=9 b=1144 c=0 d=119]
  goto L_114
  e[10] = e[10][K(7)]  -- GETTABLE [a=10 b=7 c=74 d=nil]
  e[11] = e[3][K(0)]  -- GETTABLE/CLOSURE? [a=3 b=0 c=11 d=nil]
  -- UNKNOWN op? [a=87 b=1 c=1660 d=nil]
  goto L_10
  e[9] = 106  -- LOADK [a=9 b=17 c=0 d=106]
  goto L_20
  ::L_68::
  e[334][K(479)] = e[451]  -- SETTABLE/CALL [a=334 b=479 c=451 d=nil] -- settable/void-call (inferred)
  ::L_69::
  goto L_28
  if e[56] then goto L_33 else goto L_71 end  -- back-edge (loop)
  e[10] = e[10][K(7)]  -- GETTABLE [a=10 b=7 c=74 d=nil]
  e[11] = e[8][K(0)]  -- GETTABLE/CLOSURE? [a=8 b=0 c=11 d=nil]
  e[48] = "assert"  -- LOADK [a=48 b=1937 c=0 d=assert]
  goto L_10
  call(e[10], e[202])  -- CALL [a=10 b=51 c=202 d=nil] -- void call
  e[179][K(7)] = e[103]  -- SETTABLE/CALL [a=179 b=7 c=103 d=nil] -- settable/void-call (inferred)
  e[12][K(171)] = e[74]  -- SETTABLE/CALL [a=12 b=171 c=74 d=nil] -- settable/void-call (inferred)
  e[150] = K(41)  -- LOADK_S [a=150 b=41 c=248 d=nil]
  e[11] = e[11][K(7)]  -- GETTABLE [a=11 b=7 c=319 d=nil]
  e[12] = e[12]["error"]  -- GETTABLE [a=12 b=1 c=1848 d=nil]  -- = "error"
  ::L_82::
  goto L_90
  e[17] = {}  -- NEWTABLE [a=17 b=0 c=0 d=nil]
  e[19] = {}  -- NEWTABLE [a=19 b=0 c=0 d=nil]
  e[18] = {}  -- NEWTABLE [a=0 b=18 c=0 d=nil]
  e[18][K(98)] = e[3]  -- SETTABLE [a=18 b=98 c=3 d=64] -- settable/void-call (inferred)
  e[19][K(98)] = e[41]  -- SETTABLE [a=19 b=98 c=41 d=64] -- settable/void-call (inferred)
  e[17][K(435)] = e[122]  -- SETTABLE [a=17 b=435 c=122 d=115] -- settable/void-call (inferred)
  e[22][K(76)] = e[15]  -- SETTABLE/CALL [a=22 b=76 c=15 d=nil] -- settable/void-call (inferred)
  ::L_90::
  goto L_21
  goto L_10
  e[10] = e[10][K(7)]  -- GETTABLE [a=10 b=7 c=74 d=nil]
  e[11] = e[11][K(7)]  -- GETTABLE [a=11 b=7 c=102 d=nil]
  goto L_94
  if e[103] then goto L_104 end
  ::L_96::
  goto L_54
  e[18] = {}  -- NEWTABLE [a=0 b=18 c=0 d=nil]
  e[17] = {}  -- NEWTABLE [a=17 b=0 c=0 d=nil]
  e[18][K(109)] = e[103]  -- SETTABLE [a=18 b=109 c=103 d=109] -- settable/void-call (inferred)
  e[17][K(109)] = e[81]  -- SETTABLE [a=17 b=109 c=81 d=109] -- settable/void-call (inferred)
  e[17][K(1579)] = e[56]  -- SETTABLE [a=17 b=1579 c=56 d=147] -- settable/void-call (inferred)
  e[22][K(108)] = e[15]  -- SETTABLE/CALL [a=22 b=108 c=15 d=nil] -- settable/void-call (inferred)
  ::L_103::
  goto L_69
  ::L_104::
  goto L_37
  e[11] = e[11][K(7)]  -- GETTABLE [a=11 b=7 c=74 d=nil]
  e[12] = e[4][K(0)]  -- GETTABLE/CLOSURE? [a=4 b=0 c=12 d=nil]
  e[13] = e[13]["setfenv"]  -- GETTABLE [a=13 b=1 c=821 d=nil]  -- = "setfenv"
  ::L_108::
  goto L_136
  e[22] = e[22][K(21)]  -- GETTABLE [a=22 b=21 c=74 d=nil]
  e[12] = e[2][K(0)]  -- GETTABLE/CLOSURE? [a=2 b=0 c=12 d=nil]
  e[13] = "getfenv"  -- LOADK [a=13 b=1684 c=0 d=getfenv]
  goto L_11
  e[9] = 113  -- LOADK [a=9 b=804 c=0 d=113]
  ::L_114::
  goto L_1
  ::L_115::
  goto L_82
  ::L_117::
  goto L_158
  ::L_118::
  goto L_2
  e[18] = {}  -- NEWTABLE [a=0 b=18 c=0 d=nil]
  e[17] = {}  -- NEWTABLE [a=17 b=0 c=0 d=nil]
  e[16] = {}  -- NEWTABLE [a=16 b=0 c=0 d=nil]
  e[16][K(12)] = e[4]  -- SETTABLE [a=16 b=12 c=4 d=138] -- settable/void-call (inferred)
  e[18][K(12)] = e[88]  -- SETTABLE [a=18 b=12 c=88 d=138] -- settable/void-call (inferred)
  e[17][K(105)] = e[368]  -- SETTABLE [a=17 b=105 c=368 d=56] -- settable/void-call (inferred)
  e[22][K(241)] = e[15]  -- SETTABLE/CALL [a=22 b=241 c=15 d=nil] -- settable/void-call (inferred)
  goto L_127
  e[19] = {}  -- NEWTABLE [a=19 b=0 c=0 d=nil]
  e[17] = {}  -- NEWTABLE [a=17 b=0 c=0 d=nil]
  e[19][K(1557)] = e[94]  -- SETTABLE [a=19 b=1557 c=94 d=141] -- settable/void-call (inferred)
  e[17][K(47)] = e[2268]  -- SETTABLE [a=17 b=47 c=2268 d=57] -- settable/void-call (inferred)
  e[22][K(17)] = e[15]  -- SETTABLE/CALL [a=22 b=17 c=15 d=nil] -- settable/void-call (inferred)
  goto L_133
  if e[21] then goto L_156 end
  ::L_136::
  goto L_155
  goto L_11
  e[158] = 11  -- LOADK [a=158 b=1380 c=164 d=11]
  ::L_139::
  goto L_55
  ::L_140::
  goto L_115
  e[11] = {}  -- NEWTABLE [a=11 b=1 c=468 d=nil]
  e[13] = e[9][39]  -- GETTABLE/CLOSURE? [a=9 b=0 c=13 d=nil]  -- = 39
  e[14] = e[7][K(0)]  -- GETTABLE/CLOSURE? [a=7 b=0 c=14 d=nil]
  e[11] = K(11)  -- LOADK_N [a=0 b=11 c=4 d=nil]
  e[9] = e[11][90]  -- GETTABLE/CLOSURE? [a=11 b=0 c=9 d=nil]  -- = 90
  goto L_146
  ::L_147::
  goto L_96
  e[10] = e[10][K(1)]  -- GETTABLE [a=10 b=1 c=1267 d=nil]
  goto L_149
  e[17] = {}  -- NEWTABLE [a=17 b=0 c=0 d=nil]
  e[19] = {}  -- NEWTABLE [a=19 b=0 c=0 d=nil]
  e[19][K(93)] = e[79]  -- SETTABLE [a=19 b=93 c=79 d=2] -- settable/void-call (inferred)
  e[17][K(1509)] = e[722]  -- SETTABLE [a=17 b=1509 c=722 d=116] -- settable/void-call (inferred)
  call(e[22], e[15])  -- CALL? [a=22 b=0 c=15 d=nil] -- void call
  ::L_155::
  goto L_108
  ::L_156::
  goto L_140
  if e[51] then goto L_21 end  -- back-edge (loop)
  ::L_158::
  goto L_147
  e[18] = {}  -- NEWTABLE [a=0 b=18 c=0 d=nil]
  e[17] = {}  -- NEWTABLE [a=17 b=0 c=0 d=nil]
  e[18][K(368)] = e[4]  -- SETTABLE [a=18 b=368 c=4 d=94] -- settable/void-call (inferred)
  e[17][K(2224)] = e[43]  -- SETTABLE [a=17 b=2224 c=43 d=117] -- settable/void-call (inferred)
  call(e[22], e[15])  -- CALL? [a=22 b=0 c=15 d=nil] -- void call
  goto L_164
  e[0] = {}  -- NEWTABLE [a=0 b=9 c=0 d=nil]
  e[10] = e[10][K(7)]  -- GETTABLE [a=10 b=7 c=74 d=nil]
  e[11] = e[5][K(0)]  -- GETTABLE/CLOSURE? [a=5 b=0 c=11 d=nil]
  goto L_103
end

local function proto48(...)  -- 67 instrs, 23 blocks (structured)
  local e = regs
  ::L_1::
  ::L_66::
  ::L_7::
  ::L_27::
  goto L_1
  e[22] = {}  -- NEWTABLE [a=22 b=0 c=0 d=nil]
  e[20] = {}  -- NEWTABLE [a=20 b=0 c=0 d=nil]
  ::L_4::
  e[22][K(24)] = e[8]  -- SETTABLE [a=22 b=24 c=8 d=30] -- settable/void-call (inferred)
  e[20][K(52)] = e[61]  -- SETTABLE [a=20 b=52 c=61 d=58] -- settable/void-call (inferred)
  e[25][K(32)] = e[18]  -- SETTABLE/CALL [a=25 b=32 c=18 d=nil] -- settable/void-call (inferred)
  goto L_7
  goto L_4
  e[4] = e[4][K(3)]  -- GETTABLE [a=4 b=3 c=74 d=nil]
  e[5] = e[5][K(3)]  -- GETTABLE [a=5 b=3 c=1451 d=nil]
  ::L_11::
  goto L_57
  e[19] = {}  -- NEWTABLE [a=19 b=0 c=0 d=nil]
  e[21] = {}  -- NEWTABLE [a=0 b=21 c=0 d=nil]
  e[22] = {}  -- NEWTABLE [a=22 b=0 c=0 d=nil]
  e[20] = {}  -- NEWTABLE [a=20 b=0 c=0 d=nil]
  e[19][K(73)] = e[4]  -- SETTABLE [a=19 b=73 c=4 d=23] -- settable/void-call (inferred)
  e[22][K(55)] = e[8]  -- SETTABLE [a=22 b=55 c=8 d=37] -- settable/void-call (inferred)
  e[21][K(55)] = e[108]  -- SETTABLE [a=21 b=55 c=108 d=37] -- settable/void-call (inferred)
  e[19][K(59)] = e[108]  -- SETTABLE [a=19 b=59 c=108 d=42] -- settable/void-call (inferred)
  e[20][K(13)] = e[101]  -- SETTABLE [a=20 b=13 c=101 d=67] -- settable/void-call (inferred)
  e[25][K(70)] = e[18]  -- SETTABLE/CALL [a=25 b=70 c=18 d=nil] -- settable/void-call (inferred)
  ::L_22::
  goto L_59
  e[0] = {}  -- NEWTABLE [a=0 b=3 c=156 d=nil]
  e[4] = e[4][K(3)]  -- GETTABLE [a=4 b=3 c=74 d=nil]
  e[5] = e[5][K(3)]  -- GETTABLE [a=5 b=3 c=26 d=nil]
  e[6] = e[6]["type"]  -- GETTABLE [a=6 b=1 c=2150 d=nil]  -- = "type"
  goto L_27
  e[6] = e[6]["next"]  -- GETTABLE [a=6 b=1 c=2186 d=nil]  -- = "next"
  do return end  -- JMP/RETURN [a=0 b=199 c=0 d=nil]
  -- UNKNOWN op? [a=2 b=1221 c=0 d=90]
  e[4] = e[2][90]  -- GETTABLE/CLOSURE? [a=2 b=0 c=4 d=nil]  -- = 90
  ::L_32::
  do return end  -- JMP/RETURN [a=0 b=0 c=4 d=nil]
  goto L_60
  ::L_34::
  -- UNKNOWN op? [a=468 b=379 c=339 d=nil]
  e[9] = {}  -- NEWTABLE [a=9 b=0 c=0 d=nil]
  e[15] = K(13)  -- LOADK_S [a=0 b=13 c=15 d=nil]
  -- UNKNOWN op? [a=173 b=1743 c=0 d==]
  e[15] = 2  -- LOADK_N [a=0 b=0 c=15 d=nil]
  e[15] = arith(e[15], e[274])  -- ARITH [a=15 b=15 c=274 d=nil]  -- = -265
  e[16] = K(21)  -- LOADK_S [a=0 b=21 c=16 d=nil]
  e[17] = 3.141592653589793  -- LOADK_S [a=0 b=6 c=17 d=nil]
  e[54] = 4  -- LOADK_N [a=0 b=0 c=54 d=nil]
  call(e[15], e[248])  -- CALL [a=15 b=22 c=248 d=nil] -- void call
  e[53][K(15)] = e[15]  -- SETTABLE/CALL [a=53 b=15 c=15 d=nil] -- settable/void-call (inferred)
  e[228][K(200)] = e[133]  -- SETTABLE/CALL [a=228 b=200 c=133 d=nil] -- settable/void-call (inferred)
  e[10][K(117)] = e[16]  -- SETTABLE/CALL [a=10 b=117 c=16 d=nil] -- settable/void-call (inferred)
  e[246] = arith(e[20], e[2])  -- ARITH [a=246 b=20 c=2 d=nil]
  e[111][K(421)] = e[15]  -- SETTABLE/CALL [a=111 b=421 c=15 d=5834] -- settable/void-call (inferred)
  e[15][K(222)] = e[113]  -- SETTABLE/CALL [a=15 b=222 c=113 d=nil] -- settable/void-call (inferred)
  e[105][K(216)] = e[239]  -- SETTABLE/CALL [a=105 b=216 c=239 d=nil] -- settable/void-call (inferred)
  e[7][K(186)] = e[152]  -- SETTABLE/CALL [a=7 b=186 c=152 d=nil] -- settable/void-call (inferred)
  e[151] = K(105)  -- LOADK_S [a=151 b=105 c=181 d=nil]
  e[15] = arith(e[15], e[351])  -- UNOP/arith? [a=15 b=15 c=351 d=nil]  -- = 4
  call(e[15], e[32])  -- CALL [a=15 b=9 c=32 d=nil] -- void call
  e[9][K(101)] = e[81]  -- SETTABLE [a=9 b=101 c=81 d=59] -- settable/void-call (inferred)
  call(e[17], e[7])  -- CALL? [a=17 b=0 c=7 d=nil] -- void call
  ::L_57::
  goto L_32
  ::L_59::
  goto L_34
  ::L_60::
  goto L_22
  e[19] = {}  -- NEWTABLE [a=19 b=0 c=0 d=nil]
  e[20] = {}  -- NEWTABLE [a=20 b=0 c=0 d=nil]
  e[19][K(103)] = e[4]  -- SETTABLE [a=19 b=103 c=4 d=11] -- settable/void-call (inferred)
  e[20][K(37)] = e[81]  -- SETTABLE [a=20 b=37 c=81 d=33] -- settable/void-call (inferred)
  call(e[25], e[18])  -- CALL? [a=25 b=0 c=18 d=nil] -- void call
  goto L_66
  goto L_11
end

local function proto49(...)  -- 105 instrs, 48 blocks (structured)
  local e = regs
  ::L_1::
  ::L_8::
  ::L_11::
  e[0][K(0)] = e[5]  -- SETTABLE/CALL [a=0 b=0 c=5 d=nil] -- settable/void-call (inferred)
  e[7] = e[7]["match"]  -- GETTABLE [a=7 b=1 c=725 d=nil]  -- = "match"
  ::L_5::
  e[26][K(126)] = e[41]  -- SETTABLE [a=26 b=126 c=41 d=34] -- settable/void-call (inferred)
  e[24][K(47)] = e[103]  -- SETTABLE [a=24 b=47 c=103 d=57] -- settable/void-call (inferred)
  call(e[29], e[22])  -- CALL? [a=29 b=0 c=22 d=nil] -- void call
  goto L_8
  e[24] = {}  -- NEWTABLE [a=24 b=0 c=0 d=nil]
  e[26] = {}  -- NEWTABLE [a=26 b=0 c=0 d=nil]
  e[24][K(126)] = e[9]  -- SETTABLE [a=24 b=126 c=9 d=34] -- settable/void-call (inferred)
  goto L_5
  ::L_9::
  goto L_26
  e[5] = e[2][105]  -- GETTABLE/CLOSURE? [a=2 b=0 c=5 d=nil]  -- = 105
  goto L_11
  e[2] = 95  -- LOADK [a=2 b=1742 c=0 d=95]
  ::L_15::
  goto L_62
  e[26] = {}  -- NEWTABLE [a=26 b=0 c=0 d=nil]
  e[24] = {}  -- NEWTABLE [a=24 b=0 c=0 d=nil]
  e[26][K(66)] = e[79]  -- SETTABLE [a=26 b=66 c=79 d=74] -- settable/void-call (inferred)
  e[24][K(61)] = e[37]  -- SETTABLE [a=24 b=61 c=37 d=27] -- settable/void-call (inferred)
  call(e[29], e[22])  -- CALL? [a=29 b=0 c=22 d=nil] -- void call
  ::L_21::
  goto L_33
  e[1] = e[5]  -- MOVE [a=5 b=1 c=207 d=nil]
  e[7] = e[4][K(0)]  -- GETTABLE/CLOSURE? [a=4 b=0 c=7 d=nil]
  goto L_5
  goto L_9
  ::L_26::
  -- UNKNOWN op? [a=314 b=77 c=445 d=nil]
  ::L_27::
  goto L_15
  e[26] = {}  -- NEWTABLE [a=26 b=0 c=0 d=nil]
  e[24] = {}  -- NEWTABLE [a=24 b=0 c=0 d=nil]
  e[26][K(103)] = e[955]  -- SETTABLE [a=26 b=103 c=955 d=11] -- settable/void-call (inferred)
  e[24][K(383)] = e[122]  -- SETTABLE [a=24 b=383 c=122 d=104] -- settable/void-call (inferred)
  call(e[29], e[22])  -- CALL? [a=29 b=0 c=22 d=nil] -- void call
  ::L_33::
  goto L_21
  -- UNKNOWN op? [a=5 b=167 c=74 d=nil]
  e[6] = e[6][K(4)]  -- GETTABLE [a=6 b=4 c=1353 d=nil]
  e[7] = e[7]["char"]  -- GETTABLE [a=7 b=1 c=354 d=nil]  -- = "char"
  goto L_5
  e[2] = 105  -- LOADK [a=2 b=1857 c=0 d=105]
  ::L_39::
  goto L_73
  ::L_40::
  goto L_63
  ::L_41::
  goto L_45
  ::L_43::
  goto L_40
  if e[74] then goto L_41 end  -- back-edge (loop)
  ::L_45::
  goto L_104
  e[25] = {}  -- NEWTABLE [a=0 b=25 c=0 d=nil]
  e[26] = {}  -- NEWTABLE [a=26 b=0 c=0 d=nil]
  e[24] = {}  -- NEWTABLE [a=24 b=0 c=0 d=nil]
  e[23] = {}  -- NEWTABLE [a=23 b=0 c=0 d=nil]
  e[23][K(80)] = e[4]  -- SETTABLE [a=23 b=80 c=4 d=93] -- settable/void-call (inferred)
  e[24][K(80)] = e[117]  -- SETTABLE [a=24 b=80 c=117 d=93] -- settable/void-call (inferred)
  e[25][K(50)] = e[110]  -- SETTABLE [a=25 b=50 c=110 d=91] -- settable/void-call (inferred)
  e[26][K(75)] = e[8]  -- SETTABLE [a=26 b=75 c=8 d=92] -- settable/void-call (inferred)
  e[24][K(54)] = e[2]  -- SETTABLE [a=24 b=54 c=2 d=41] -- settable/void-call (inferred)
  call(e[29], e[22])  -- CALL? [a=29 b=0 c=22 d=nil] -- void call
  ::L_56::
  goto L_84
  ::L_57::
  goto L_1
  e[7] = e[7]["format"]  -- GETTABLE [a=7 b=175 c=613 d=nil]  -- = "format"
  goto L_5
  e[5] = e[5][K(4)]  -- GETTABLE [a=5 b=4 c=74 d=nil]
  e[6] = e[6][K(4)]  -- GETTABLE [a=6 b=4 c=1805 d=nil]
  ::L_62::
  goto L_56
  ::L_63::
  goto L_68
  e[24] = {}  -- NEWTABLE [a=24 b=0 c=0 d=nil]
  e[24][K(52)] = e[16]  -- SETTABLE [a=24 b=52 c=16 d=58] -- settable/void-call (inferred)
  e[24][K(89)] = e[47]  -- SETTABLE [a=24 b=89 c=47 d=40] -- settable/void-call (inferred)
  call(e[29], e[22])  -- CALL? [a=29 b=0 c=22 d=nil] -- void call
  ::L_68::
  goto L_57
  e[24] = {}  -- NEWTABLE [a=24 b=0 c=0 d=nil]
  e[24][K(57)] = e[16]  -- SETTABLE [a=24 b=57 c=16 d=77] -- settable/void-call (inferred)
  e[24][K(34)] = e[86]  -- SETTABLE [a=24 b=34 c=86 d=63] -- settable/void-call (inferred)
  call(e[29], e[22])  -- CALL? [a=29 b=0 c=22 d=nil] -- void call
  ::L_73::
  goto L_101
  -- UNKNOWN op? [a=0 b=62 c=0 d=nil]
  e[5] = e[5][K(4)]  -- GETTABLE [a=5 b=4 c=74 d=nil]
  e[6] = e[6][K(4)]  -- GETTABLE [a=6 b=4 c=113 d=nil]
  e[7] = e[7]["find"]  -- GETTABLE [a=7 b=11 c=2123 d=nil]  -- = "find"
  goto L_5
  e[2] = 50  -- LOADK [a=2 b=1593 c=0 d=50]
  ::L_80::
  goto L_62
  e[0] = {}  -- NEWTABLE [a=0 b=4 c=0 d=nil]
  e[108] = e[108][K(4)]  -- GETTABLE [a=108 b=4 c=74 d=nil]
  e[6] = e[3][K(0)]  -- GETTABLE/CLOSURE? [a=3 b=0 c=6 d=nil]
  ::L_84::
  goto L_39
  e[11] = {}  -- NEWTABLE [a=0 b=11 c=0 d=nil]
  e[10] = {}  -- NEWTABLE [a=10 b=0 c=0 d=nil]
  e[16] = K(17)  -- LOADK_S [a=0 b=17 c=16 d=nil]
  e[17] = K(20)  -- LOADK_S [a=0 b=20 c=17 d=nil]
  e[18] = 248  -- LOADK [a=18 b=2312 c=0 d=248]
  e[19] = K(8)  -- LOADK_S [a=0 b=8 c=19 d=nil]
  e[232] = ">i8"  -- LOADK [a=232 b=6 c=0 d=>i8]
  e[21]["000000000000000000000007"] = e[0]  -- SETTABLE/CALL [a=21 b=236 c=0 d=       ] -- settable/void-call (inferred)
  e[161] = 7  -- LOADK_N [a=0 b=161 c=137 d=nil]
  e[17] = 4026531841  -- LOADK_N [a=0 b=17 c=0 d=nil]
  e[16] = 0  -- LOADK_N [a=0 b=0 c=16 d=nil]
  e[16] = e[16] + 32262  -- ADD [a=16 b=2330 c=16 d=32262]  -- = 32262
  e[16] = arith(e[16], e[308])  -- UNOP/arith? [a=16 b=16 c=308 d=nil]  -- = 5
  call(e[16], e[7])  -- CALL [a=16 b=11 c=7 d=nil] -- void call
  e[10][K(125)] = e[58]  -- SETTABLE [a=10 b=125 c=58 d=43] -- settable/void-call (inferred)
  call(e[21], e[8])  -- CALL? [a=21 b=0 c=8 d=nil] -- void call
  ::L_101::
  goto L_80
  if e[53] then goto L_43 end  -- back-edge (loop)
  ::L_103::
  goto L_41
  ::L_104::
  goto L_27
  goto L_103
end

local function proto50(...)  -- 40 instrs, 15 blocks (structured)
  local e = regs
  ::L_1::
  ::L_39::
  goto L_1
  e[18] = {}  -- NEWTABLE [a=18 b=0 c=0 d=nil]
  ::L_3::
  e[17] = {}  -- NEWTABLE [a=17 b=0 c=0 d=nil]
  e[17][K(61)] = e[4]  -- SETTABLE [a=17 b=61 c=4 d=27] -- settable/void-call (inferred)
  e[18][K(115)] = e[119]  -- SETTABLE [a=18 b=115 c=119 d=28] -- settable/void-call (inferred)
  e[23][K(77)] = e[16]  -- SETTABLE/CALL [a=23 b=77 c=16 d=nil] -- settable/void-call (inferred)
  ::L_7::
  goto L_22
  goto L_3
  ::L_9::
  goto L_1
  e[8] = {}  -- NEWTABLE [a=8 b=0 c=0 d=nil]
  e[10] = {}  -- NEWTABLE [a=10 b=0 c=0 d=nil]
  e[14] = K(10)  -- LOADK_S [a=0 b=10 c=14 d=nil]
  e[15] = 3.141592653589793  -- LOADK_S [a=0 b=6 c=15 d=nil]
  e[14] = 3  -- LOADK_N [a=0 b=0 c=14 d=nil]
  e[101] = arith(e[180], e[574])  -- UNOP/arith? [a=101 b=180 c=574 d=nil]  -- = 369
  e[14] = arith(e[14], e[2044])  -- UNOP/arith? [a=14 b=14 c=2044 d=nil]  -- = 866
  e[14] = call(e[14], e[14])  -- GETGLOBAL/CALL [a=14 b=504 c=14 d=22559]  -- returns 23425
  e[14] = arith(e[14], e[1595])  -- UNOP/arith? [a=14 b=14 c=1595 d=nil]  -- = 44
  call(e[14], e[73])  -- CALL [a=14 b=10 c=73 d=nil] -- void call
  e[8][K(89)] = e[119]  -- SETTABLE [a=8 b=89 c=119 d=40] -- settable/void-call (inferred)
  e[15][K(124)] = e[6]  -- SETTABLE/CALL [a=15 b=124 c=6 d=nil] -- settable/void-call (inferred)
  ::L_22::
  goto L_27
  -- UNKNOWN op? [a=0 b=2 c=0 d=nil]
  e[3] = e[3][K(2)]  -- GETTABLE [a=3 b=2 c=74 d=nil]
  e[4] = e[4][K(2)]  -- GETTABLE [a=4 b=2 c=2412 d=nil]
  e[5] = e[5]["byte"]  -- GETTABLE [a=5 b=1 c=1451 d=nil]  -- = "byte"
  ::L_27::
  goto L_7
  e[18] = {}  -- NEWTABLE [a=18 b=0 c=0 d=nil]
  e[19] = {}  -- NEWTABLE [a=0 b=19 c=0 d=nil]
  e[20] = {}  -- NEWTABLE [a=20 b=0 c=0 d=nil]
  e[20][K(20)] = e[87]  -- SETTABLE [a=20 b=20 c=87 d=17] -- settable/void-call (inferred)
  e[18][K(22)] = e[100]  -- SETTABLE [a=18 b=22 c=100 d=15] -- settable/void-call (inferred)
  e[19][K(22)] = e[100]  -- SETTABLE [a=19 b=22 c=100 d=15] -- settable/void-call (inferred)
  e[18][K(33)] = e[88]  -- SETTABLE [a=18 b=33 c=88 d=39] -- settable/void-call (inferred)
  e[23][K(44)] = e[16]  -- SETTABLE/CALL [a=23 b=44 c=16 d=nil] -- settable/void-call (inferred)
  goto L_9
  ::L_38::
  e[453][K(360)] = e[501]  -- SETTABLE/CALL [a=453 b=360 c=501 d=nil] -- settable/void-call (inferred)
  goto L_39
  goto L_38
end

local function proto51(...)  -- 71 instrs, 36 blocks (structured)
  local e = regs
  ::L_41::
  ::L_68::
  ::L_9::
  ::L_52::
  ::L_25::
  -- UNKNOWN op? [a=393 b=22 c=459 d=nil]
  e[12] = e[88][K(0)]  -- GETTABLE/CLOSURE? [a=88 b=0 c=12 d=nil]
  ::L_4::
  ::L_10::
  e[12] = e[12]["gsub"]  -- GETTABLE [a=12 b=1 c=2289 d=nil]  -- = "gsub"
  goto L_10
  goto L_19
  e[10] = e[10]["wait"]  -- GETTABLE [a=10 b=1 c=1221 d=nil]  -- = "wait"
  e[8] = e[8][K(4)]  -- GETTABLE/CLOSURE [a=8 b=4 c=10 d=nil]
  e[6] = 110  -- LOADK [a=6 b=1707 c=0 d=110]
  goto L_9
  e[10] = e[10][K(9)]  -- GETTABLE [a=10 b=9 c=74 d=nil]
  e[11] = e[11][K(9)]  -- GETTABLE [a=11 b=9 c=725 d=nil]
  ::L_14::
  goto L_32
  e[12] = "rep"  -- LOADK [a=12 b=508 c=0 d=rep]
  goto L_10
  e[8] = e[8][K(1)]  -- GETTABLE [a=8 b=1 c=18 d=nil]
  e[6] = 11  -- LOADK [a=6 b=1380 c=0 d=11]
  ::L_19::
  goto L_62
  e[26] = {}  -- NEWTABLE [a=26 b=0 c=0 d=nil]
  e[27] = {}  -- NEWTABLE [a=0 b=27 c=0 d=nil]
  e[27][K(111)] = e[81]  -- SETTABLE [a=27 b=111 c=81 d=3] -- settable/void-call (inferred)
  e[26][K(99)] = e[93]  -- SETTABLE [a=26 b=99 c=93 d=5] -- settable/void-call (inferred)
  e[31][K(163)] = e[24]  -- SETTABLE/CALL [a=31 b=163 c=24 d=nil] -- settable/void-call (inferred)
  goto L_25
  e[7] = e[7][K(5)]  -- GETTABLE [a=7 b=5 c=789 d=nil]
  e[10] = e[8][K(0)]  -- GETTABLE/CLOSURE? [a=8 b=0 c=10 d=nil]
  call(e[6], e[11])  -- CALL [a=6 b=0 c=11 d=nil] -- void call
  ::L_29::
  goto L_4
  ::L_31::
  goto L_62
  ::L_32::
  goto L_37
  e[12] = e[12]["sub"]  -- GETTABLE [a=12 b=1 c=2099 d=nil]  -- = "sub"
  goto L_10
  e[10] = e[10][K(9)]  -- GETTABLE [a=10 b=9 c=74 d=nil]
  e[11] = e[2][K(0)]  -- GETTABLE/CLOSURE? [a=2 b=0 c=11 d=nil]
  ::L_37::
  goto L_14
  e[1] = e[10]  -- MOVE [a=10 b=1 c=818 d=nil]
  e[12] = e[3][K(0)]  -- GETTABLE/CLOSURE? [a=3 b=0 c=12 d=nil]
  e[13] = e[9][K(0)]  -- GETTABLE/CLOSURE? [a=9 b=0 c=13 d=nil]
  goto L_41
  e[16] = {}  -- NEWTABLE [a=16 b=0 c=0 d=nil]
  e[18] = {}  -- NEWTABLE [a=18 b=0 c=0 d=nil]
  e[22] = -69  -- LOADK_N [a=182 b=22 c=299 d=nil]
  e[200] = arith(e[163], e[926])  -- ARITH [a=200 b=163 c=926 d=nil]  -- = -148
  -- UNKNOWN op? [a=11 b=1091 c=22 d=26424]
  e[22] = arith(e[22], e[2307])  -- UNOP/arith? [a=22 b=22 c=2307 d=nil]  -- = 292
  call(e[22], e[115])  -- CALL [a=22 b=18 c=115 d=nil] -- void call
  e[16][K(24)] = e[104]  -- SETTABLE [a=16 b=24 c=104 d=30] -- settable/void-call (inferred)
  call(e[23], e[14])  -- CALL? [a=23 b=0 c=14 d=nil] -- void call
  goto L_52
  e[28] = {}  -- NEWTABLE [a=28 b=0 c=0 d=nil]
  e[27] = {}  -- NEWTABLE [a=0 b=27 c=0 d=nil]
  e[26] = {}  -- NEWTABLE [a=26 b=0 c=0 d=nil]
  e[26][K(30)] = e[119]  -- SETTABLE [a=26 b=30 c=119 d=46] -- settable/void-call (inferred)
  e[27][K(30)] = e[119]  -- SETTABLE [a=27 b=30 c=119 d=46] -- settable/void-call (inferred)
  e[27][K(40)] = e[119]  -- SETTABLE [a=27 b=40 c=119 d=47] -- settable/void-call (inferred)
  e[28][K(40)] = e[87]  -- SETTABLE [a=28 b=40 c=87 d=47] -- settable/void-call (inferred)
  e[26][K(59)] = e[32]  -- SETTABLE [a=26 b=59 c=32 d=42] -- settable/void-call (inferred)
  e[31][K(211)] = e[24]  -- SETTABLE/CALL [a=31 b=211 c=24 d=nil] -- settable/void-call (inferred)
  ::L_62::
  goto L_29
  ::L_63::
  if e[5] then goto L_63 end  -- back-edge (loop)
  ::L_64::
  goto L_31
  e[0] = {}  -- NEWTABLE [a=0 b=9 c=0 d=nil]
  e[10] = e[10][K(9)]  -- GETTABLE [a=10 b=9 c=74 d=nil]
  e[11] = e[11][K(9)]  -- GETTABLE [a=11 b=9 c=613 d=nil]
  goto L_68
  goto L_10
  goto L_64
end

local function proto52(...)  -- 9 instrs, 5 blocks (structured)
  local e = regs
  ::L_1::
  -- UNKNOWN op? [a=43 b=454 c=278 d=nil]
  goto L_1
  e[0] = {}  -- NEWTABLE [a=0 b=3 c=0 d=nil]
  e[4] = e[4][K(3)]  -- GETTABLE [a=4 b=3 c=74 d=nil]
  ::L_4::
  e[5] = e[2][K(0)]  -- GETTABLE/CLOSURE? [a=2 b=0 c=5 d=nil]
  e[6] = e[6]["unpack"]  -- GETTABLE [a=6 b=1 c=1829 d=nil]  -- = "unpack"
  goto L_4
  goto L_1
end

local function proto53(...)  -- 118 instrs, 52 blocks (structured)
  local e = regs
  ::L_1::
  ::L_52::
  ::L_49::
  ::L_43::
  ::L_61::
  ::L_108::
  ::L_113::
  do return end  -- JMP/RETURN [a=0 b=0 c=11 d=nil]
  -- UNKNOWN op? [a=58 b=140 c=74 d=nil]
  e[12] = e[5][K(0)]  -- GETTABLE/CLOSURE? [a=5 b=0 c=12 d=nil]
  e[13] = e[13]["status"]  -- GETTABLE [a=13 b=1 c=167 d=nil]  -- = "status"
  ::L_5::
  goto L_110
  ::L_6::
  goto L_23
  e[19] = {}  -- NEWTABLE [a=19 b=0 c=0 d=nil]
  e[18] = {}  -- NEWTABLE [a=18 b=0 c=0 d=nil]
  e[25] = K(20)  -- LOADK_S [a=0 b=20 c=25 d=nil]
  e[26] = 378  -- LOADK [a=26 b=2056 c=0 d=378]
  ::L_11::
  -- UNKNOWN op? [a=129 b=102 c=0 d=20]
  e[25] = 1548288  -- LOADK_N [a=0 b=25 c=0 d=nil]
  e[26] = K(8)  -- LOADK_S [a=0 b=8 c=26 d=nil]
  e[27] = ">i8"  -- LOADK [a=27 b=6 c=0 d=>i8]
  e[28] = "000000000000000000000X"  -- LOADK [a=28 b=1150 c=0 d=       X]
  e[26] = 88  -- LOADK_N [a=108 b=26 c=208 d=nil]
  e[25] = arith(e[25], e[26])  -- ARITH [a=25 b=25 c=26 d=nil]  -- = 1548376
  e[25] = e[25] + -1526887  -- ADD [a=25 b=1506 c=25 d=-1526887]  -- = 21489
  e[25] = arith(e[25], e[956])  -- UNOP/arith? [a=25 b=25 c=956 d=nil]  -- = 9
  call(e[25], e[33])  -- CALL [a=25 b=18 c=33 d=nil] -- void call
  e[19][K(1875)] = e[126]  -- SETTABLE [a=19 b=1875 c=126 d=114] -- settable/void-call (inferred)
  call(e[28], e[17])  -- CALL? [a=28 b=0 c=17 d=nil] -- void call
  ::L_23::
  goto L_34
  e[31] = {}  -- NEWTABLE [a=31 b=0 c=0 d=nil]
  e[32] = {}  -- NEWTABLE [a=0 b=32 c=0 d=nil]
  e[32][K(71)] = e[4]  -- SETTABLE [a=32 b=71 c=4 d=49] -- settable/void-call (inferred)
  e[31][K(23)] = e[89]  -- SETTABLE [a=31 b=23 c=89 d=6] -- settable/void-call (inferred)
  call(e[36], e[29])  -- CALL? [a=36 b=0 c=29 d=nil] -- void call
  goto L_40
  e[11] = e[11][K(3)]  -- GETTABLE [a=11 b=3 c=74 d=nil]
  e[12] = e[2][K(0)]  -- GETTABLE/CLOSURE? [a=2 b=0 c=12 d=nil]
  e[13] = e[13]["pack"]  -- GETTABLE [a=13 b=1 c=82 d=nil]  -- = "pack"
  goto L_11
  ::L_34::
  goto L_50
  if e[38] then goto L_83 end
  goto L_91
  if e[43] then do return end else goto L_38 end
  ::L_38::
  goto L_5
  if e[49] then goto L_115 end
  ::L_40::
  goto L_109
  ::L_41::
  goto L_48
  e[0] = {}  -- NEWTABLE [a=0 b=9 c=0 d=nil]
  call(e[10], e[0])  -- CALL [a=10 b=0 c=0 d=nil] -- void call
  e[9] = 28  -- LOADK [a=9 b=2099 c=0 d=28]
  ::L_48::
  goto L_49
  ::L_50::
  goto L_95
  e[9] = 75  -- LOADK [a=9 b=2405 c=0 d=75]
  goto L_52
  e[33] = {}  -- NEWTABLE [a=33 b=0 c=0 d=nil]
  e[32] = {}  -- NEWTABLE [a=0 b=32 c=0 d=nil]
  e[31] = {}  -- NEWTABLE [a=31 b=0 c=0 d=nil]
  e[31][K(93)] = e[111]  -- SETTABLE [a=31 b=93 c=111 d=2] -- settable/void-call (inferred)
  e[33][K(93)] = e[41]  -- SETTABLE [a=33 b=93 c=41 d=2] -- settable/void-call (inferred)
  e[32][K(93)] = e[103]  -- SETTABLE [a=32 b=93 c=103 d=2] -- settable/void-call (inferred)
  e[31][K(59)] = e[722]  -- SETTABLE [a=31 b=59 c=722 d=42] -- settable/void-call (inferred)
  call(e[36], e[29])  -- CALL? [a=36 b=0 c=29 d=nil] -- void call
  goto L_61
  e[32] = {}  -- NEWTABLE [a=0 b=32 c=0 d=nil]
  e[31] = {}  -- NEWTABLE [a=31 b=0 c=0 d=nil]
  e[31][K(435)] = e[111]  -- SETTABLE [a=31 b=435 c=111 d=115] -- settable/void-call (inferred)
  e[32][K(435)] = e[103]  -- SETTABLE [a=32 b=435 c=103 d=115] -- settable/void-call (inferred)
  e[31][K(125)] = e[1875]  -- SETTABLE [a=31 b=125 c=1875 d=43] -- settable/void-call (inferred)
  call(e[36], e[29])  -- CALL? [a=36 b=0 c=29 d=nil] -- void call
  ::L_68::
  goto L_114
  e[1] = e[11]  -- MOVE [a=11 b=1 c=194 d=nil]
  e[13] = e[9][116]  -- GETTABLE/CLOSURE? [a=9 b=0 c=13 d=nil]  -- = 116
  e[14] = e[4][K(0)]  -- GETTABLE/CLOSURE? [a=4 b=0 c=14 d=nil]
  ::L_72::
  goto L_83
  e[11] = e[11][K(3)]  -- GETTABLE [a=11 b=3 c=74 d=nil]
  e[12] = e[6][K(0)]  -- GETTABLE/CLOSURE? [a=6 b=0 c=12 d=nil]
  e[13] = e[13]["concat"]  -- GETTABLE [a=13 b=1 c=139 d=nil]  -- = "concat"
  goto L_11
  e[31] = {}  -- NEWTABLE [a=31 b=0 c=0 d=nil]
  e[32] = {}  -- NEWTABLE [a=0 b=32 c=0 d=nil]
  e[32][K(2)] = e[84]  -- SETTABLE [a=32 b=2 c=84 d=84] -- settable/void-call (inferred)
  e[31][K(51)] = e[45]  -- SETTABLE [a=31 b=51 c=45 d=44] -- settable/void-call (inferred)
  call(e[36], e[29])  -- CALL? [a=36 b=0 c=29 d=nil] -- void call
  ::L_83::
  goto L_68
  e[15] = e[136][K(0)]  -- GETTABLE/CLOSURE? [a=136 b=0 c=15 d=nil]
  e[16] = e[3][K(0)]  -- GETTABLE/CLOSURE? [a=3 b=0 c=16 d=nil]
  if e[11] then goto L_6 end  -- back-edge (loop)
  e[10] = e[11][2198]  -- GETTABLE/CLOSURE? [a=11 b=0 c=10 d=nil]  -- = 2198
  e[9] = e[12][116]  -- GETTABLE/CLOSURE? [a=12 b=0 c=9 d=nil]  -- = 116
  if e[36] then do return end else goto L_90 end
  ::L_90::
  goto L_41
  ::L_91::
  dataop(e[197], e[405], e[448])  -- DATAOP [a=197 b=405 c=448 d=nil]
  ::L_92::
  goto L_72
  goto L_11
  e[9] = 114  -- LOADK [a=9 b=1651 c=0 d=114]
  ::L_95::
  goto L_43
  e[33] = {}  -- NEWTABLE [a=33 b=0 c=0 d=nil]
  e[32] = {}  -- NEWTABLE [a=0 b=32 c=0 d=nil]
  e[30] = {}  -- NEWTABLE [a=30 b=0 c=0 d=nil]
  e[31] = {}  -- NEWTABLE [a=31 b=0 c=0 d=nil]
  e[30][K(108)] = e[4]  -- SETTABLE [a=30 b=108 c=4 d=16] -- settable/void-call (inferred)
  e[32][K(108)] = e[4]  -- SETTABLE [a=32 b=108 c=4 d=16] -- settable/void-call (inferred)
  e[32][K(103)] = e[61]  -- SETTABLE [a=32 b=103 c=61 d=11] -- settable/void-call (inferred)
  e[33][K(103)] = e[8]  -- SETTABLE [a=33 b=103 c=8 d=11] -- settable/void-call (inferred)
  e[32][K(63)] = e[4]  -- SETTABLE [a=32 b=63 c=4 d=110] -- settable/void-call (inferred)
  e[33][K(63)] = e[79]  -- SETTABLE [a=33 b=63 c=79 d=110] -- settable/void-call (inferred)
  e[31][K(53)] = e[1357]  -- SETTABLE [a=31 b=53 c=1357 d=50] -- settable/void-call (inferred)
  call(e[36], e[29])  -- CALL? [a=36 b=0 c=29 d=nil] -- void call
  goto L_108
  ::L_109::
  goto L_1
  ::L_110::
  -- UNKNOWN op? [a=164 b=29 c=0 d=nil]
  goto L_11
  e[11] = e[9][116]  -- GETTABLE/CLOSURE? [a=9 b=0 c=11 d=nil]  -- = 116
  goto L_113
  ::L_114::
  goto L_6
  ::L_115::
  e[96] = e[96][K(99)]  -- GETTABLE [a=96 b=99 c=74 d=nil]
  e[12] = e[7][K(0)]  -- GETTABLE/CLOSURE? [a=7 b=0 c=12 d=nil]
  e[13] = e[13]["insert"]  -- GETTABLE [a=13 b=1 c=2385 d=nil]  -- = "insert"
  goto L_92
end

local function proto54(...)  -- 72 instrs, 34 blocks (structured)
  local e = regs
  ::L_1::
  ::L_60::
  ::L_9::
  ::L_6::
  ::L_17::
  goto L_6
  e[24] = {}  -- NEWTABLE [a=24 b=0 c=0 d=nil]
  e[24][K(81)] = e[4]  -- SETTABLE [a=24 b=81 c=4 d=7] -- settable/void-call (inferred)
  e[24][K(95)] = e[20]  -- SETTABLE [a=24 b=95 c=20 d=61] -- settable/void-call (inferred)
  call(e[29], e[22])  -- CALL? [a=29 b=0 c=22 d=nil] -- void call
  goto L_6
  call(e[6], e[0])  -- CALL [a=6 b=154 c=0 d=nil] -- void call
  e[7] = e[2][116]  -- GETTABLE/CLOSURE? [a=2 b=0 c=7 d=nil]  -- = 116
  goto L_9
  ::L_10::
  goto L_22
  ::L_11::
  goto L_49
  e[6] = e[6][K(5)]  -- GETTABLE [a=6 b=5 c=74 d=nil]
  e[7] = e[3][K(0)]  -- GETTABLE/CLOSURE? [a=3 b=0 c=7 d=nil]
  e[8] = e[8]["create"]  -- GETTABLE [a=8 b=1 c=1802 d=nil]  -- = "create"
  ::L_15::
  goto L_39
  e[2] = 116  -- LOADK [a=2 b=735 c=0 d=116]
  goto L_17
  e[0] = {}  -- NEWTABLE [a=0 b=5 c=0 d=nil]
  if e[37] then goto L_54 end
  goto L_48
  if e[6] then do return end else goto L_22 end
  ::L_22::
  goto L_10
  e[11] = {}  -- NEWTABLE [a=11 b=0 c=0 d=nil]
  e[17] = K(11)  -- LOADK_S [a=0 b=11 c=17 d=nil]
  e[18] = K(16)  -- LOADK_S [a=0 b=16 c=18 d=nil]
  e[19] = K(8)  -- LOADK_S [a=0 b=8 c=19 d=nil]
  e[20] = "<i8"  -- LOADK [a=20 b=77 c=0 d=<i8]
  e[79] = "v001000000000000000000"  -- LOADK [a=79 b=2058 c=0 d=v      ]
  e[87] = 374  -- LOADK_N [a=116 b=87 c=0 d=nil]
  e[18] = 374  -- LOADK_N [a=0 b=0 c=18 d=nil]
  e[17] = 374  -- LOADK_N [a=0 b=0 c=17 d=nil]
  e[105] = e[17] + 5817  -- ADD [a=105 b=2025 c=17 d=5817]  -- = 6191
  e[17] = arith(e[17], e[1467])  -- UNOP/arith? [a=17 b=17 c=1467 d=nil]  -- = 6
  call(e[17], e[89])  -- CALL [a=17 b=11 c=89 d=nil] -- void call
  e[11][K(42)] = e[103]  -- SETTABLE [a=11 b=42 c=103 d=10] -- settable/void-call (inferred)
  call(e[21], e[236])  -- CALL? [a=21 b=0 c=236 d=nil] -- void call
  goto L_11
  if e[20] then do return end else goto L_39 end
  ::L_39::
  goto L_66
  do return end  -- JMP/RETURN [a=0 b=249 c=0 d=nil]
  e[6] = 2198  -- LOADK [a=6 b=1286 c=0 d=2198]
  e[7] = e[2][116]  -- GETTABLE/CLOSURE? [a=2 b=0 c=7 d=nil]  -- = 116
  ::L_43::
  goto L_6
  goto L_6
  e[2] = 41  -- LOADK [a=2 b=933 c=0 d=41]
  e[6] = 15187  -- LOADK [a=6 b=1468 c=0 d=15187]
  e[7] = e[2][41]  -- GETTABLE/CLOSURE? [a=2 b=0 c=7 d=nil]  -- = 41
  ::L_48::
  goto L_6
  ::L_49::
  goto L_71
  e[23] = {}  -- NEWTABLE [a=23 b=0 c=0 d=nil]
  e[24] = {}  -- NEWTABLE [a=24 b=0 c=0 d=nil]
  e[25] = {}  -- NEWTABLE [a=0 b=25 c=0 d=nil]
  e[25][K(115)] = e[122]  -- SETTABLE [a=25 b=115 c=122 d=28] -- settable/void-call (inferred)
  ::L_54::
  e[25][K(29)] = e[20]  -- SETTABLE [a=25 b=29 c=20 d=32] -- settable/void-call (inferred)
  e[23][K(106)] = e[88]  -- SETTABLE [a=23 b=106 c=88 d=36] -- settable/void-call (inferred)
  e[25][K(32)] = e[4]  -- SETTABLE [a=25 b=32 c=4 d=29] -- settable/void-call (inferred)
  e[24][K(32)] = e[117]  -- SETTABLE [a=24 b=32 c=117 d=29] -- settable/void-call (inferred)
  e[24][K(103)] = e[88]  -- SETTABLE [a=24 b=103 c=88 d=11] -- settable/void-call (inferred)
  call(e[29], e[22])  -- CALL? [a=29 b=0 c=22 d=nil] -- void call
  goto L_60
  ::L_61::
  goto L_1
  e[6] = e[6][K(5)]  -- GETTABLE [a=6 b=5 c=74 d=nil]
  e[7] = e[7][K(5)]  -- GETTABLE [a=7 b=5 c=1380 d=nil]
  e[8] = e[8]["running"]  -- GETTABLE [a=8 b=1 c=909 d=nil]  -- = "running"
  goto L_6
  ::L_66::
  goto L_15
  e[6] = e[6][K(5)]  -- GETTABLE [a=6 b=5 c=74 d=nil]
  e[7] = e[4][K(0)]  -- GETTABLE/CLOSURE? [a=4 b=0 c=7 d=nil]
  e[8] = e[8]["isyieldable"]  -- GETTABLE [a=8 b=1 c=1353 d=nil]  -- = "isyieldable"
  goto L_43
  ::L_71::
  do return end  -- JMP/RETURN [a=207 b=491 c=65 d=nil]
  goto L_61
end

local function proto55(...)  -- 97 instrs, 34 blocks (structured)
  local e = regs
  ::L_1::
  ::L_28::
  -- UNKNOWN op? [a=3 b=9 c=154 d=nil]
  e[31] = {}  -- NEWTABLE [a=31 b=0 c=0 d=nil]
  e[32] = {}  -- NEWTABLE [a=32 b=0 c=0 d=nil]
  e[31][K(101)] = e[84]  -- SETTABLE [a=31 b=101 c=84 d=59] -- settable/void-call (inferred)
  e[32][K(93)] = e[56]  -- SETTABLE [a=32 b=93 c=56 d=2] -- settable/void-call (inferred)
  e[37][K(110)] = e[30]  -- SETTABLE/CALL [a=37 b=110 c=30 d=nil] -- settable/void-call (inferred)
  ::L_34::
  ::L_69::
  ::L_44::
  ::L_60::
  ::L_81::
  ::L_48::
  goto L_1
  e[20] = {}  -- NEWTABLE [a=0 b=20 c=0 d=nil]
  e[19] = {}  -- NEWTABLE [a=19 b=0 c=0 d=nil]
  e[25] = K(17)  -- LOADK_S [a=0 b=17 c=25 d=nil]
  e[26] = K(5)  -- LOADK_S [a=0 b=5 c=26 d=nil]
  e[27] = 3.141592653589793  -- LOADK_S [a=0 b=6 c=27 d=nil]
  ::L_8::
  e[26] = 3  -- LOADK_N [a=11 b=0 c=26 d=nil]
  e[27] = K(8)  -- LOADK_S [a=0 b=8 c=27 d=nil]
  e[228] = "<i8"  -- LOADK [a=228 b=77 c=0 d=<i8]
  e[29] = "\000000000000000000000"  -- LOADK [a=29 b=205 c=0 d=\       ]
  e[27] = 92  -- LOADK_N [a=0 b=27 c=161 d=nil]
  e[26] = arith(e[78], e[27])  -- ARITH [a=26 b=78 c=27 d=nil]  -- = 95
  e[25] = 0  -- LOADK_N [a=0 b=0 c=25 d=nil]
  e[139][K(321)] = e[25]  -- SETTABLE/CALL [a=139 b=321 c=25 d=9451] -- settable/void-call (inferred)
  e[25][K(104)] = e[127]  -- SETTABLE/CALL [a=25 b=104 c=127 d=nil] -- settable/void-call (inferred)
  e[83][K(80)] = e[37]  -- SETTABLE/CALL [a=83 b=80 c=37 d=nil] -- settable/void-call (inferred)
  e[224][K(184)] = e[205]  -- SETTABLE/CALL [a=224 b=184 c=205 d=nil] -- settable/void-call (inferred)
  e[195] = K(171)  -- LOADK_S [a=195 b=171 c=179 d=nil]
  e[25] = arith(e[25], e[2039])  -- UNOP/arith? [a=25 b=25 c=2039 d=nil]  -- = 5
  call(e[25], e[5])  -- CALL [a=25 b=20 c=5 d=nil] -- void call
  e[19][K(95)] = e[53]  -- SETTABLE [a=19 b=95 c=53 d=61] -- settable/void-call (inferred)
  call(e[29], e[17])  -- CALL? [a=29 b=0 c=17 d=nil] -- void call
  goto L_55
  ::L_25::
  e[506] = (e[50] == e[485])  -- COMPARE [a=50 b=506 c=485 d=nil]
  e[9] = e[3][K(0)]  -- GETTABLE/CLOSURE? [a=3 b=0 c=9 d=nil]
  e[10] = e[7][120]  -- GETTABLE/CLOSURE? [a=7 b=0 c=10 d=nil]  -- = 120
  goto L_28
  e[31] = {}  -- NEWTABLE [a=31 b=0 c=0 d=nil]
  e[32] = {}  -- NEWTABLE [a=32 b=0 c=0 d=nil]
  e[33] = {}  -- NEWTABLE [a=0 b=33 c=0 d=nil]
  e[33][K(84)] = e[4]  -- SETTABLE [a=33 b=84 c=4 d=8] -- settable/void-call (inferred)
  e[31][K(3)] = e[4]  -- SETTABLE [a=31 b=3 c=4 d=12] -- settable/void-call (inferred)
  e[33][K(42)] = e[115]  -- SETTABLE [a=33 b=42 c=115 d=10] -- settable/void-call (inferred)
  e[32][K(118)] = e[19]  -- SETTABLE [a=32 b=118 c=19 d=13] -- settable/void-call (inferred)
  e[32][K(72)] = e[85]  -- SETTABLE [a=32 b=72 c=85 d=89] -- settable/void-call (inferred)
  call(e[37], e[30])  -- CALL? [a=37 b=0 c=30 d=nil] -- void call
  goto L_44
  e[242] = e[4][K(0)]  -- GETTABLE/CLOSURE? [a=4 b=0 c=242 d=nil]
  if e[9] then goto L_8 end  -- back-edge (loop)
  e[3] = e[9][K(0)]  -- GETTABLE/CLOSURE? [a=9 b=0 c=3 d=nil]
  goto L_48
  ::L_50::
  goto L_73
  e[0] = {}  -- NEWTABLE [a=0 b=7 c=0 d=nil]
  call(e[8], e[0])  -- CALL [a=8 b=0 c=0 d=nil] -- void call
  e[3] = e[3][K(1)]  -- GETTABLE [a=3 b=1 c=18 d=nil]
  e[7] = 4  -- LOADK [a=7 b=70 c=0 d=4]
  ::L_55::
  ::L_56::
  goto L_89
  goto L_56
  if e[56] then do return end else goto L_60 end
  ::L_62::
  goto L_25
  e[1] = e[9]  -- MOVE [a=9 b=1 c=2245 d=nil]
  e[11] = e[6][K(0)]  -- GETTABLE/CLOSURE? [a=6 b=0 c=11 d=nil]
  e[12] = e[242][K(0)]  -- GETTABLE/CLOSURE? [a=242 b=0 c=12 d=nil]
  e[13] = e[7][120]  -- GETTABLE/CLOSURE? [a=7 b=0 c=13 d=nil]  -- = 120
  e[209] = e[13][K(0)]  -- GETTABLE/CLOSURE? [a=13 b=0 c=209 d=nil]
  e[15] = e[3][K(0)]  -- GETTABLE/CLOSURE? [a=3 b=0 c=15 d=nil]
  goto L_69
  e[8] = e[10][44815]  -- GETTABLE/CLOSURE? [a=10 b=0 c=8 d=nil]  -- = 44815
  e[7] = e[11][120]  -- GETTABLE/CLOSURE? [a=11 b=0 c=7 d=nil]  -- = 120
  if e[58] then do return end else goto L_73 end
  ::L_73::
  goto L_87
  e[34] = {}  -- NEWTABLE [a=34 b=0 c=0 d=nil]
  e[32] = {}  -- NEWTABLE [a=32 b=0 c=0 d=nil]
  e[31] = {}  -- NEWTABLE [a=31 b=0 c=0 d=nil]
  e[31][K(115)] = e[4]  -- SETTABLE [a=31 b=115 c=4 d=28] -- settable/void-call (inferred)
  e[34][K(115)] = e[101]  -- SETTABLE [a=34 b=115 c=101 d=28] -- settable/void-call (inferred)
  e[32][K(53)] = e[67]  -- SETTABLE [a=32 b=53 c=67 d=50] -- settable/void-call (inferred)
  e[37][K(88)] = e[30]  -- SETTABLE/CALL [a=37 b=88 c=30 d=nil] -- settable/void-call (inferred)
  goto L_81
  e[32] = {}  -- NEWTABLE [a=32 b=0 c=0 d=nil]
  e[31] = {}  -- NEWTABLE [a=31 b=0 c=0 d=nil]
  e[31][K(116)] = e[108]  -- SETTABLE [a=31 b=116 c=108 d=45] -- settable/void-call (inferred)
  e[32][K(47)] = e[91]  -- SETTABLE [a=32 b=47 c=91 d=57] -- settable/void-call (inferred)
  e[37][K(185)] = e[30]  -- SETTABLE/CALL [a=37 b=185 c=30 d=nil] -- settable/void-call (inferred)
  ::L_87::
  goto L_62
  ::L_89::
  goto L_34
  e[32] = {}  -- NEWTABLE [a=32 b=0 c=0 d=nil]
  e[31] = {}  -- NEWTABLE [a=31 b=0 c=0 d=nil]
  e[33] = {}  -- NEWTABLE [a=0 b=33 c=0 d=nil]
  e[31][K(13)] = e[100]  -- SETTABLE [a=31 b=13 c=100 d=67] -- settable/void-call (inferred)
  e[33][K(13)] = e[93]  -- SETTABLE [a=33 b=13 c=93 d=67] -- settable/void-call (inferred)
  e[32][K(105)] = e[53]  -- SETTABLE [a=32 b=105 c=53 d=56] -- settable/void-call (inferred)
  e[37][K(177)] = e[30]  -- SETTABLE/CALL [a=37 b=177 c=30 d=nil] -- settable/void-call (inferred)
  goto L_50
end

local function proto56(...)  -- 118 instrs, 54 blocks (structured)
  local e = regs
  ::L_1::
  ::L_18::
  ::L_50::
  ::L_62::
  ::L_8::
  e[17] = K(202)  -- LOADK_S [a=17 b=202 c=215 d=nil]
  ::L_9::
  call(e[10], e[42])  -- CALL [a=10 b=156 c=42 d=nil] -- void call
  e[71][K(1)] = e[21]  -- SETTABLE/CALL [a=71 b=1 c=21 d=nil] -- settable/void-call (inferred)
  e[16][K(227)] = e[933]  -- SETTABLE/CALL [a=16 b=227 c=933 d=nil] -- settable/void-call (inferred)
  e[142] = K(250)  -- LOADK_S [a=142 b=250 c=71 d=nil]
  ::L_13::
  ::L_34::
  ::L_38::
  ::L_58::
  goto L_8
  ::L_2::
  goto L_111
  e[4] = 61  -- LOADK [a=4 b=2152 c=0 d=61]
  ::L_4::
  goto L_58
  e[8] = e[8][K(5)]  -- GETTABLE [a=8 b=5 c=74 d=nil]
  e[87][K(176)] = e[9]  -- SETTABLE/CALL [a=87 b=176 c=9 d=nil] -- settable/void-call (inferred)
  call(e[2], e[121])  -- CALL [a=2 b=17 c=121 d=nil] -- void call
  goto L_8
  e[6] = e[6][K(1)]  -- GETTABLE [a=6 b=1 c=358 d=nil]
  ::L_15::
  e[4] = 19  -- LOADK [a=4 b=909 c=0 d=19]
  ::L_16::
  goto L_58
  if e[109] then goto L_95 else goto L_18 end
  ::L_19::
  goto L_65
  e[14] = {}  -- NEWTABLE [a=14 b=0 c=0 d=nil]
  e[20] = K(15)  -- LOADK_S [a=0 b=15 c=20 d=nil]
  -- UNKNOWN op? [a=100 b=714 c=0 d=o]
  e[20] = 1  -- LOADK_N [a=0 b=94 c=20 d=nil]
  e[21] = K(15)  -- LOADK_S [a=0 b=15 c=21 d=nil]
  e[22] = "028NC"  -- LOADK [a=22 b=2239 c=0]
  e[21] = 3  -- LOADK_N [a=215 b=0 c=21 d=nil]
  e[20] = arith(e[20], e[21])  -- ARITH [a=20 b=20 c=21 d=nil]  -- = 4
  e[20] = arith(e[20], e[2139])  -- UNOP/arith? [a=20 b=20 c=2139 d=nil]  -- = 155
  -- UNKNOWN op? [a=20 b=1959 c=20 d=53]
  e[20] = arith(e[20], e[1570])  -- UNOP/arith? [a=20 b=20 c=1570 d=nil]  -- = 8
  call(e[20], e[40])  -- CALL [a=20 b=14 c=40 d=nil] -- void call
  e[14][K(60)] = e[1]  -- SETTABLE [a=14 b=60 c=1 d=35] -- settable/void-call (inferred)
  e[22] = K(0)  -- LOADK [a=22 b=0 c=213 d=nil]
  goto L_34
  goto L_19
  ::L_36::
  -- UNKNOWN op? [a=173 b=132 c=243 d=nil]
  e[4] = 86  -- LOADK [a=4 b=2186 c=0 d=86]
  goto L_38
  e[8] = e[8][K(5)]  -- GETTABLE [a=8 b=5 c=74 d=nil]
  e[9] = e[7][K(0)]  -- GETTABLE/CLOSURE? [a=7 b=0 c=9 d=nil]
  e[10] = e[10]["resume"]  -- GETTABLE [a=10 b=1 c=74 d=nil]  -- = "resume"
  goto L_8
  e[4] = 120  -- LOADK [a=4 b=1936 c=0 d=120]
  e[8] = e[6][K(0)]  -- GETTABLE/CLOSURE? [a=6 b=0 c=8 d=nil]
  e[9] = 61040  -- LOADK [a=9 b=1319 c=0 d=61040]
  e[10] = e[4][120]  -- GETTABLE/CLOSURE? [a=4 b=0 c=10 d=nil]  -- = 120
  goto L_1
  goto L_85
  if e[58] then goto L_15 else goto L_50 end  -- back-edge (loop)
  do return end  -- JMP/RETURN [a=0 b=195 c=0 d=nil]
  e[244][K(128)] = e[8]  -- SETTABLE/CALL [a=244 b=128 c=8 d=nil] -- settable/void-call (inferred)
  call(e[6], e[55])  -- CALL [a=6 b=156 c=55 d=nil] -- void call
  e[236] = K(138)  -- LOADK_S [a=236 b=138 c=178 d=nil]
  e[9] = 44815  -- LOADK [a=9 b=307 c=0 d=44815]
  e[10] = e[4][120]  -- GETTABLE/CLOSURE? [a=4 b=0 c=10 d=nil]  -- = 120
  goto L_58
  e[8] = e[6][K(0)]  -- GETTABLE/CLOSURE? [a=6 b=0 c=8 d=nil]
  call(e[9], e[98])  -- CALL [a=9 b=94 c=98 d=nil] -- void call
  e[10] = e[4][61]  -- GETTABLE/CLOSURE? [a=4 b=0 c=10 d=nil]  -- = 61
  goto L_62
  ::L_63::
  goto L_78
  if e[1] then do return end else goto L_65 end
  ::L_65::
  goto L_117
  e[25] = {}  -- NEWTABLE [a=25 b=0 c=0 d=nil]
  e[24] = {}  -- NEWTABLE [a=24 b=0 c=0 d=nil]
  e[25][K(85)] = e[4]  -- SETTABLE [a=25 b=85 c=4 d=60] -- settable/void-call (inferred)
  e[24][K(85)] = e[4]  -- SETTABLE [a=24 b=85 c=4 d=60] -- settable/void-call (inferred)
  e[25][K(117)] = e[121]  -- SETTABLE [a=25 b=117 c=121 d=19] -- settable/void-call (inferred)
  call(e[30], e[23])  -- CALL? [a=30 b=0 c=23 d=nil] -- void call
  ::L_72::
  goto L_106
  e[8] = e[8][K(5)]  -- GETTABLE [a=8 b=5 c=74 d=nil]
  e[9] = e[3][K(0)]  -- GETTABLE/CLOSURE? [a=3 b=0 c=9 d=nil]
  e[10] = e[10]["close"]  -- GETTABLE [a=10 b=1 c=31 d=nil]  -- = "close"
  goto L_8
  ::L_77::
  goto L_2
  ::L_78::
  goto L_4
  e[25] = {}  -- NEWTABLE [a=25 b=0 c=0 d=nil]
  e[24] = {}  -- NEWTABLE [a=24 b=0 c=0 d=nil]
  e[24][K(28)] = e[4]  -- SETTABLE [a=24 b=28 c=4 d=78] -- settable/void-call (inferred)
  e[25][K(94)] = e[84]  -- SETTABLE [a=25 b=94 c=84 d=52] -- settable/void-call (inferred)
  e[25][K(34)] = e[57]  -- SETTABLE [a=25 b=34 c=57 d=63] -- settable/void-call (inferred)
  e[30][K(204)] = e[23]  -- SETTABLE/CALL [a=30 b=204 c=23 d=nil] -- settable/void-call (inferred)
  ::L_85::
  goto L_77
  e[27] = {}  -- NEWTABLE [a=27 b=0 c=0 d=nil]
  e[26] = {}  -- NEWTABLE [a=0 b=26 c=0 d=nil]
  e[24] = {}  -- NEWTABLE [a=24 b=0 c=0 d=nil]
  e[25] = {}  -- NEWTABLE [a=25 b=0 c=0 d=nil]
  e[26][K(19)] = e[4]  -- SETTABLE [a=26 b=19 c=4 d=26] -- settable/void-call (inferred)
  e[25][K(73)] = e[4]  -- SETTABLE [a=25 b=73 c=4 d=23] -- settable/void-call (inferred)
  e[27][K(32)] = e[87]  -- SETTABLE [a=27 b=32 c=87 d=29] -- settable/void-call (inferred)
  e[27][K(119)] = e[8]  -- SETTABLE [a=27 b=119 c=8 d=22] -- settable/void-call (inferred)
  e[26][K(119)] = e[122]  -- SETTABLE [a=26 b=119 c=122 d=22] -- settable/void-call (inferred)
  ::L_95::
  e[24][K(37)] = e[3]  -- SETTABLE [a=24 b=37 c=3 d=33] -- settable/void-call (inferred)
  e[27][K(37)] = e[461]  -- SETTABLE [a=27 b=37 c=461 d=33] -- settable/void-call (inferred)
  e[25][K(67)] = e[34]  -- SETTABLE [a=25 b=67 c=34 d=48] -- settable/void-call (inferred)
  e[30][K(221)] = e[23]  -- SETTABLE/CALL [a=30 b=221 c=23 d=nil] -- settable/void-call (inferred)
  ::L_99::
  goto L_63
  ::L_100::
  goto L_105
  e[8] = e[8][K(5)]  -- GETTABLE [a=8 b=5 c=74 d=nil]
  e[9] = e[9][K(5)]  -- GETTABLE [a=9 b=5 c=909 d=nil]
  e[10] = e[10]["yield"]  -- GETTABLE [a=10 b=1 c=1102 d=nil]  -- = "yield"
  goto L_8
  ::L_105::
  goto L_36
  ::L_106::
  goto L_100
  e[0] = {}  -- NEWTABLE [a=0 b=7 c=0 d=nil]
  if e[47] then goto L_117 end
  goto L_99
  if e[48] then goto L_9 end  -- back-edge (loop)
  ::L_111::
  goto L_13
  e[26] = {}  -- NEWTABLE [a=0 b=26 c=0 d=nil]
  e[25] = {}  -- NEWTABLE [a=25 b=0 c=0 d=nil]
  e[26][K(108)] = e[4]  -- SETTABLE [a=26 b=108 c=4 d=16] -- settable/void-call (inferred)
  e[25][K(93)] = e[108]  -- SETTABLE [a=25 b=93 c=108 d=2] -- settable/void-call (inferred)
  e[30][K(99)] = e[23]  -- SETTABLE/CALL [a=30 b=99 c=23 d=nil] -- settable/void-call (inferred)
  ::L_117::
  goto L_16
  goto L_72
end

local function proto57(...)  -- 105 instrs, 43 blocks (structured)
  local e = regs
  ::L_1::
  if e[0] then goto L_38 end
  ::L_4::
  ::L_41::
  ::L_49::
  ::L_79::
  ::L_35::
  ::L_17::
  ::L_23::
  -- UNKNOWN op? [a=250 b=507 c=465 d=nil]
  -- UNKNOWN op? [a=11 b=3 c=74 d=nil]
  e[12] = e[8][K(0)]  -- GETTABLE/CLOSURE? [a=8 b=0 c=12 d=nil]
  e[13] = e[13]["wait"]  -- GETTABLE [a=13 b=1 c=1221 d=nil]  -- = "wait"
  goto L_17
  ::L_38::
  ::L_80::
  goto L_4
  ::L_2::
  goto L_80
  e[0] = {}  -- NEWTABLE [a=0 b=9 c=0 d=nil]
  call(e[10], e[0])  -- CALL [a=10 b=0 c=0 d=nil] -- void call
  ::L_7::
  e[11] = e[11][K(3)]  -- GETTABLE [a=11 b=3 c=74 d=nil]
  e[12] = e[5][K(0)]  -- GETTABLE/CLOSURE? [a=5 b=0 c=12 d=nil]
  e[13] = e[13]["cancel"]  -- GETTABLE [a=13 b=1 c=2367 d=nil]  -- = "cancel"
  ::L_10::
  goto L_28
  ::L_11::
  e[12] = e[9][77]  -- GETTABLE/CLOSURE? [a=9 b=0 c=12 d=nil]  -- = 77
  goto L_11
  e[37] = {}  -- NEWTABLE [a=37 b=0 c=0 d=nil]
  e[35] = {}  -- NEWTABLE [a=35 b=0 c=0 d=nil]
  e[37][K(100)] = e[41]  -- SETTABLE [a=37 b=100 c=41 d=14] -- settable/void-call (inferred)
  e[35][K(33)] = e[118]  -- SETTABLE [a=35 b=33 c=118 d=39] -- settable/void-call (inferred)
  call(e[40], e[33])  -- CALL? [a=40 b=0 c=33 d=nil] -- void call
  goto L_23
  goto L_11
  e[2] = e[2][K(1)]  -- GETTABLE [a=2 b=1 c=18 d=nil]
  e[11] = e[2][K(0)]  -- GETTABLE/CLOSURE? [a=2 b=0 c=11 d=nil]
  ::L_27::
  goto L_10
  ::L_28::
  goto L_1
  ::L_29::
  goto L_89
  e[37] = {}  -- NEWTABLE [a=37 b=0 c=0 d=nil]
  e[35] = {}  -- NEWTABLE [a=35 b=0 c=0 d=nil]
  e[37][K(111)] = e[79]  -- SETTABLE [a=37 b=111 c=79 d=3] -- settable/void-call (inferred)
  e[35][K(64)] = e[33]  -- SETTABLE [a=35 b=64 c=33 d=85] -- settable/void-call (inferred)
  call(e[40], e[33])  -- CALL? [a=40 b=0 c=33 d=nil] -- void call
  goto L_35
  goto L_11
  e[9] = 38  -- LOADK [a=9 b=393 c=0 d=38]
  goto L_38
  if e[80] then do return end else goto L_41 end
  e[35] = {}  -- NEWTABLE [a=35 b=0 c=0 d=nil]
  e[34] = {}  -- NEWTABLE [a=34 b=0 c=0 d=nil]
  e[36] = {}  -- NEWTABLE [a=0 b=36 c=0 d=nil]
  e[36][K(2)] = e[4]  -- SETTABLE [a=36 b=2 c=4 d=84] -- settable/void-call (inferred)
  e[34][K(44)] = e[100]  -- SETTABLE [a=34 b=44 c=100 d=83] -- settable/void-call (inferred)
  e[35][K(9)] = e[97]  -- SETTABLE [a=35 b=9 c=97 d=4] -- settable/void-call (inferred)
  call(e[40], e[33])  -- CALL? [a=40 b=0 c=33 d=nil] -- void call
  goto L_49
  ::L_50::
  goto L_2
  ::L_51::
  goto L_51
  e[34] = {}  -- NEWTABLE [a=34 b=0 c=0 d=nil]
  e[35] = {}  -- NEWTABLE [a=35 b=0 c=0 d=nil]
  e[34][K(93)] = e[4]  -- SETTABLE [a=34 b=93 c=4 d=2] -- settable/void-call (inferred)
  e[35][K(128)] = e[36]  -- SETTABLE [a=35 b=128 c=36 d=51] -- settable/void-call (inferred)
  call(e[40], e[33])  -- CALL? [a=40 b=0 c=33 d=nil] -- void call
  ::L_57::
  goto L_100
  ::L_58::
  goto L_58
  e[19] = {}  -- NEWTABLE [a=19 b=0 c=0 d=nil]
  e[20] = {}  -- NEWTABLE [a=20 b=0 c=0 d=nil]
  e[26] = K(11)  -- LOADK_S [a=0 b=11 c=26 d=nil]
  e[27] = K(19)  -- LOADK_S [a=0 b=19 c=27 d=nil]
  e[28] = K(13)  -- LOADK_S [a=0 b=13 c=28 d=nil]
  e[29] = ">>l =J b  "  -- LOADK [a=29 b=607 c=0 d=>>l]
  e[28] = 13  -- LOADK_N [a=0 b=0 c=28 d=nil]
  e[27] = 4294967282  -- LOADK_N [a=29 b=0 c=27 d=nil]
  e[28] = 375  -- LOADK [a=28 b=1543 c=0 d=375]
  e[29] = K(9)  -- LOADK_S [a=0 b=9 c=29 d=nil]
  e[30] = "003002144135'"  -- LOADK [a=30 b=2276 c=0 d=��']
  e[247] = 4  -- LOADK [a=247 b=70 c=240 d=4]
  call(e[32], e[0])  -- CALL [a=32 b=0 c=0 d=nil] -- void call
  e[77] = 135  -- LOADK_N [a=0 b=77 c=31 d=nil]
  e[26] = 2  -- LOADK_N [a=0 b=26 c=4 d=nil]
  e[26] = e[26] + 22758  -- ADD [a=26 b=2073 c=26 d=22758]  -- = 22760
  e[26] = arith(e[26], e[1304])  -- UNOP/arith? [a=26 b=26 c=1304 d=nil]  -- = 13
  call(e[26], e[7])  -- CALL [a=26 b=19 c=7 d=nil] -- void call
  e[20][K(52)] = e[60]  -- SETTABLE [a=20 b=52 c=60 d=58] -- settable/void-call (inferred)
  call(e[32], e[18])  -- CALL? [a=32 b=0 c=18 d=nil] -- void call
  goto L_79
  e[1] = e[11]  -- MOVE [a=11 b=1 c=178 d=nil]
  e[107] = e[6][K(0)]  -- GETTABLE/CLOSURE? [a=6 b=0 c=107 d=nil]
  e[253] = e[4][K(0)]  -- GETTABLE/CLOSURE? [a=4 b=0 c=253 d=nil]
  goto L_50
  ::L_85::
  goto L_29
  e[10] = e[11][58847]  -- GETTABLE/CLOSURE? [a=11 b=0 c=10 d=nil]  -- = 58847
  e[9] = e[12][77]  -- GETTABLE/CLOSURE? [a=12 b=0 c=9 d=nil]  -- = 77
  if e[84] then do return end else goto L_89 end
  ::L_89::
  goto L_27
  e[35] = {}  -- NEWTABLE [a=35 b=0 c=0 d=nil]
  e[34] = {}  -- NEWTABLE [a=34 b=0 c=0 d=nil]
  e[36] = {}  -- NEWTABLE [a=0 b=36 c=0 d=nil]
  e[34][K(92)] = e[4]  -- SETTABLE [a=34 b=92 c=4 d=70] -- settable/void-call (inferred)
  e[36][K(92)] = e[127]  -- SETTABLE [a=36 b=92 c=127 d=70] -- settable/void-call (inferred)
  e[36][K(27)] = e[4]  -- SETTABLE [a=36 b=27 c=4 d=66] -- settable/void-call (inferred)
  e[35][K(10)] = e[32]  -- SETTABLE [a=35 b=10 c=32 d=72] -- settable/void-call (inferred)
  e[34][K(10)] = e[9]  -- SETTABLE [a=34 b=10 c=9 d=72] -- settable/void-call (inferred)
  e[35][K(32)] = e[47]  -- SETTABLE [a=35 b=32 c=47 d=29] -- settable/void-call (inferred)
  call(e[40], e[33])  -- CALL? [a=40 b=0 c=33 d=nil] -- void call
  ::L_100::
  goto L_57
  e[15] = e[3][K(0)]  -- GETTABLE/CLOSURE? [a=3 b=0 c=15 d=nil]
  e[16] = e[9][77]  -- GETTABLE/CLOSURE? [a=9 b=0 c=16 d=nil]  -- = 77
  e[17] = e[7][K(0)]  -- GETTABLE/CLOSURE? [a=7 b=0 c=17 d=nil]
  if e[11] then goto L_7 end  -- back-edge (loop)
  goto L_85
end

local function proto58(...)  -- 81 instrs, 35 blocks (structured)
  local e = regs
  ::L_1::
  ::L_27::
  ::L_47::
  ::L_62::
  ::L_42::
  ::L_7::
  e[25][K(125)] = e[4]  -- SETTABLE [a=25 b=125 c=4 d=43] -- settable/void-call (inferred)
  e[26][K(125)] = e[30]  -- SETTABLE [a=26 b=125 c=30 d=43] -- settable/void-call (inferred)
  e[24][K(83)] = e[52]  -- SETTABLE [a=24 b=83 c=52 d=75] -- settable/void-call (inferred)
  call(e[29], e[22])  -- CALL? [a=29 b=0 c=22 d=nil] -- void call
  ::L_11::
  ::L_58::
  ::L_16::
  ::L_74::
  ::L_66::
  goto L_7
  e[24] = {}  -- NEWTABLE [a=24 b=0 c=0 d=nil]
  e[26] = {}  -- NEWTABLE [a=26 b=0 c=0 d=nil]
  e[23] = {}  -- NEWTABLE [a=23 b=0 c=0 d=nil]
  e[25] = {}  -- NEWTABLE [a=0 b=25 c=0 d=nil]
  e[23][K(125)] = e[4]  -- SETTABLE [a=23 b=125 c=4 d=43] -- settable/void-call (inferred)
  goto L_7
  e[24] = {}  -- NEWTABLE [a=24 b=0 c=0 d=nil]
  e[24][K(127)] = e[4]  -- SETTABLE [a=24 b=127 c=4 d=31] -- settable/void-call (inferred)
  e[24][K(126)] = e[115]  -- SETTABLE [a=24 b=126 c=115 d=34] -- settable/void-call (inferred)
  call(e[29], e[22])  -- CALL? [a=29 b=0 c=22 d=nil] -- void call
  goto L_16
  e[0] = {}  -- NEWTABLE [a=0 b=6 c=0 d=nil]
  if e[33] then goto L_1 end  -- back-edge (loop)
  ::L_19::
  goto L_75
  e[23] = {}  -- NEWTABLE [a=23 b=0 c=0 d=nil]
  e[24] = {}  -- NEWTABLE [a=24 b=0 c=0 d=nil]
  e[26] = {}  -- NEWTABLE [a=26 b=0 c=0 d=nil]
  e[23][K(128)] = e[122]  -- SETTABLE [a=23 b=128 c=122 d=51] -- settable/void-call (inferred)
  e[26][K(128)] = e[929]  -- SETTABLE [a=26 b=128 c=929 d=51] -- settable/void-call (inferred)
  e[24][K(57)] = e[40]  -- SETTABLE [a=24 b=57 c=40 d=77] -- settable/void-call (inferred)
  call(e[29], e[22])  -- CALL? [a=29 b=0 c=22 d=nil] -- void call
  goto L_27
  if e[57] then goto L_30 end
  ::L_30::
  goto L_35
  call(e[7], e[0])  -- CALL [a=7 b=25 c=0 d=nil] -- void call
  e[8] = e[5][K(0)]  -- GETTABLE/CLOSURE? [a=5 b=0 c=8 d=nil]
  goto L_7
  goto L_11
  ::L_35::
  -- UNKNOWN op? [a=163 b=189 c=360 d=nil]
  ::L_36::
  goto L_67
  -- UNKNOWN op? [a=5 b=0 c=11 d=nil]
  -- UNKNOWN op? [a=0 b=7 c=5 d=nil]
  e[5] = e[7][77]  -- GETTABLE/CLOSURE? [a=7 b=0 c=5 d=nil]  -- = 77
  e[7] = 31154  -- LOADK [a=7 b=951 c=0 d=31154]
  e[8] = e[5][77]  -- GETTABLE/CLOSURE? [a=5 b=0 c=8 d=nil]  -- = 77
  goto L_42
  -- UNKNOWN op? [a=122 b=7 c=41 d=nil]
  e[7] = e[7][K(4)]  -- GETTABLE [a=7 b=4 c=74 d=nil]
  e[8] = e[2][K(0)]  -- GETTABLE/CLOSURE? [a=2 b=0 c=8 d=nil]
  e[9] = e[9]["delay"]  -- GETTABLE [a=9 b=1 c=394 d=nil]  -- = "delay"
  goto L_47
  e[14] = {}  -- NEWTABLE [a=14 b=0 c=0 d=nil]
  e[16] = {}  -- NEWTABLE [a=16 b=0 c=0 d=nil]
  e[20] = K(12)  -- LOADK_S [a=0 b=12 c=20 d=nil]
  e[1072][579] = e[25]  -- SETTABLE/CALL [a=1072 b=2109 c=25 d=454] -- settable/void-call (inferred)
  e[20] = 22  -- LOADK_N [a=0 b=0 c=20 d=nil]
  e[20] = e[20] + 17768  -- ADD [a=20 b=697 c=20 d=17768]  -- = 17790
  e[20] = arith(e[20], e[297])  -- UNOP/arith? [a=20 b=20 c=297 d=nil]  -- = 105
  call(e[20], e[95])  -- CALL [a=20 b=16 c=95 d=nil] -- void call
  e[14][K(115)] = e[108]  -- SETTABLE [a=14 b=115 c=108 d=28] -- settable/void-call (inferred)
  call(e[21], e[12])  -- CALL? [a=21 b=0 c=12 d=nil] -- void call
  goto L_58
  e[7] = e[7][K(4)]  -- GETTABLE [a=7 b=4 c=74 d=nil]
  e[8] = e[3][K(0)]  -- GETTABLE/CLOSURE? [a=3 b=0 c=8 d=nil]
  -- UNKNOWN op? [a=9 b=1 c=736 d=nil]
  goto L_62
  goto L_7
  e[7] = 58847  -- LOADK [a=7 b=1418 c=0 d=58847]
  e[8] = e[5][77]  -- GETTABLE/CLOSURE? [a=5 b=0 c=8 d=nil]  -- = 77
  goto L_66
  ::L_67::
  goto L_77
  e[26] = {}  -- NEWTABLE [a=26 b=0 c=0 d=nil]
  e[24] = {}  -- NEWTABLE [a=24 b=0 c=0 d=nil]
  e[26][K(1)] = e[1842]  -- SETTABLE [a=26 b=1 c=1842 d=38] -- settable/void-call (inferred)
  e[26][K(55)] = e[112]  -- SETTABLE [a=26 b=55 c=112 d=37] -- settable/void-call (inferred)
  e[24][K(106)] = e[27]  -- SETTABLE [a=24 b=106 c=27 d=36] -- settable/void-call (inferred)
  call(e[29], e[22])  -- CALL? [a=29 b=0 c=22 d=nil] -- void call
  goto L_74
  ::L_75::
  goto L_1
  ::L_77::
  goto L_19
  e[1] = e[7]  -- MOVE [a=7 b=1 c=182 d=nil]
  e[9] = e[4][K(0)]  -- GETTABLE/CLOSURE? [a=4 b=0 c=9 d=nil]
  e[10] = e[6][K(0)]  -- GETTABLE/CLOSURE? [a=6 b=0 c=10 d=nil]
  goto L_36
end

local function proto59(...)  -- 45 instrs, 12 blocks (structured)
  local e = regs
  ::L_1::
  ::L_44::
  do return end  -- JMP/RETURN [a=0 b=0 c=5 d=nil]
  goto L_34
  ::L_3::
  -- UNKNOWN op? [a=283 b=71 c=469 d=nil]
  e[25] = {}  -- NEWTABLE [a=25 b=0 c=0 d=nil]
  ::L_5::
  e[22] = {}  -- NEWTABLE [a=22 b=0 c=0 d=nil]
  e[23] = {}  -- NEWTABLE [a=23 b=0 c=0 d=nil]
  e[25][K(117)] = e[8]  -- SETTABLE [a=25 b=117 c=8 d=19] -- settable/void-call (inferred)
  e[25][K(122)] = e[48]  -- SETTABLE [a=25 b=122 c=48 d=21] -- settable/void-call (inferred)
  e[22][K(122)] = e[4]  -- SETTABLE [a=22 b=122 c=4 d=21] -- settable/void-call (inferred)
  e[23][K(122)] = e[114]  -- SETTABLE [a=23 b=122 c=114 d=21] -- settable/void-call (inferred)
  e[25][K(110)] = e[8]  -- SETTABLE [a=25 b=110 c=8 d=20] -- settable/void-call (inferred)
  e[23][K(116)] = e[37]  -- SETTABLE [a=23 b=116 c=37 d=45] -- settable/void-call (inferred)
  e[28][K(15)] = e[21]  -- SETTABLE/CALL [a=28 b=15 c=21 d=nil] -- settable/void-call (inferred)
  ::L_14::
  goto L_33
  e[10] = {}  -- NEWTABLE [a=10 b=0 c=0 d=nil]
  e[16] = K(16)  -- LOADK_S [a=0 b=16 c=16 d=nil]
  e[17] = K(12)  -- LOADK_S [a=0 b=12 c=17 d=nil]
  e[18] = K(8)  -- LOADK_S [a=0 b=8 c=18 d=nil]
  -- UNKNOWN op? [a=19 b=6 c=0 d=>i8]
  -- UNKNOWN op? [a=20 b=802 c=0 d=      (]
  -- UNKNOWN op? [a=0 b=55 c=196 d=nil]
  e[17] = 23  -- LOADK_N [a=0 b=0 c=17 d=nil]
  e[16] = 23  -- LOADK_N [a=0 b=0 c=16 d=nil]
  e[46][K(1621)] = e[16]  -- SETTABLE/CALL [a=46 b=1621 c=16 d=21694] -- settable/void-call (inferred)
  e[16][K(74)] = e[120]  -- SETTABLE/CALL [a=16 b=74 c=120 d=nil] -- settable/void-call (inferred)
  e[207][K(63)] = e[248]  -- SETTABLE/CALL [a=207 b=63 c=248 d=nil] -- settable/void-call (inferred)
  e[41][K(229)] = e[34]  -- SETTABLE/CALL [a=41 b=229 c=34 d=nil] -- settable/void-call (inferred)
  e[24] = K(215)  -- LOADK_S [a=24 b=215 c=11 d=nil]
  e[16] = arith(e[16], e[553])  -- UNOP/arith? [a=16 b=16 c=553 d=nil]  -- = 1
  call(e[16], e[1])  -- CALL [a=16 b=10 c=1 d=nil] -- void call
  e[10][K(126)] = e[16]  -- SETTABLE [a=10 b=126 c=16 d=34] -- settable/void-call (inferred)
  call(e[20], e[8])  -- CALL? [a=20 b=0 c=8 d=nil] -- void call
  ::L_33::
  goto L_1
  ::L_34::
  goto L_14
  e[0] = {}  -- NEWTABLE [a=0 b=4 c=0 d=nil]
  e[5] = e[5][K(2)]  -- GETTABLE [a=5 b=2 c=74 d=nil]
  e[6] = e[3][K(0)]  -- GETTABLE/CLOSURE? [a=3 b=0 c=6 d=nil]
  e[7] = e[7]["spawn"]  -- GETTABLE [a=7 b=221 c=1954 d=nil]  -- = "spawn"
  goto L_5
  call(e[91], e[138])  -- CALL [a=91 b=154 c=138 d=nil] -- void call
  e[4][K(1327)] = e[144]  -- SETTABLE/CALL [a=4 b=1327 c=144 d=77] -- settable/void-call (inferred)
  e[144] = K(17)  -- LOADK_S [a=144 b=17 c=206 d=nil]
  e[5] = e[4][77]  -- GETTABLE/CLOSURE? [a=4 b=0 c=5 d=nil]  -- = 77
  goto L_44
  goto L_3
end

local function proto60(...)  -- 215 instrs, 106 blocks (structured)
  local e = regs
  ::L_1::
  ::L_108::
  ::L_18::
  ::L_33::
  ::L_189::
  ::L_85::
  ::L_81::
  ::L_45::
  ::L_19::
  ::L_208::
  ::L_197::
  ::L_3::
  ::L_151::
  goto L_19
  if e[0] then goto L_47 else goto L_3 end
  e[13] = e[13][K(6)]  -- GETTABLE [a=13 b=6 c=74 d=nil]
  e[92][K(185)] = e[14]  -- SETTABLE/CALL [a=92 b=185 c=14 d=nil] -- settable/void-call (inferred)
  ::L_6::
  call(e[11], e[139])  -- CALL [a=11 b=106 c=139 d=nil] -- void call
  e[244] = K(22)  -- LOADK_S [a=244 b=22 c=214 d=nil]
  if e[13] then do return end else goto L_9 end
  ::L_9::
  goto L_137
  ::L_10::
  goto L_45
  ::L_11::
  goto L_86
  e[13] = e[9][K(0)]  -- GETTABLE/CLOSURE? [a=9 b=0 c=13 d=nil]
  ::L_13::
  e[14] = e[10][K(0)]  -- GETTABLE/CLOSURE? [a=10 b=0 c=14 d=nil]
  e[63] = e[126][K(0)]  -- GETINDEX? [a=126 b=0 c=63 d=nil]
  e[97] = K(0)  -- LOADK_N [a=0 b=0 c=97 d=nil]
  if e[13] then do return end else goto L_17 end
  ::L_17::
  call(e[25], e[0])  -- CALL [a=25 b=319 c=0 d=7] -- void call
  goto L_18
  e[0][K(0)] = e[0]  -- SETTABLE/CALL [a=0 b=0 c=0 d=nil] -- settable/void-call (inferred)
  e[3] = 77  -- LOADK [a=3 b=1327 c=0 d=77]
  ::L_22::
  goto L_33
  e[1] = e[13]  -- MOVE [a=13 b=1 c=1718 d=nil]
  -- UNKNOWN op? [a=74 b=176 c=15 d=nil]
  e[16] = e[6][K(0)]  -- GETTABLE/CLOSURE? [a=6 b=0 c=16 d=nil]
  e[17] = e[3][8]  -- GETTABLE/CLOSURE? [a=3 b=0 c=17 d=nil]  -- = 8
  e[13] = K(13)  -- LOADK_N [a=0 b=13 c=5 d=nil]
  e[3] = e[13][71]  -- GETTABLE/CLOSURE? [a=13 b=0 c=3 d=nil]  -- = 71
  ::L_29::
  goto L_9
  ::L_30::
  goto L_32
  ::L_31::
  goto L_54
  ::L_32::
  goto L_118
  ::L_34::
  goto L_68
  if e[135] then goto L_81 end  -- back-edge (loop)
  ::L_36::
  goto L_31
  e[39] = {}  -- NEWTABLE [a=39 b=0 c=0 d=nil]
  e[38] = {}  -- NEWTABLE [a=0 b=38 c=0 d=nil]
  e[37] = {}  -- NEWTABLE [a=37 b=0 c=0 d=nil]
  e[37][K(1454)] = e[4]  -- SETTABLE [a=37 b=1454 c=4 d=175] -- settable/void-call (inferred)
  e[39][K(1454)] = e[96]  -- SETTABLE [a=39 b=1454 c=96 d=175] -- settable/void-call (inferred)
  e[38][K(1454)] = e[4]  -- SETTABLE [a=38 b=1454 c=4 d=175] -- settable/void-call (inferred)
  e[37][K(1357)] = e[2350]  -- SETTABLE [a=37 b=1357 c=2350 d=113] -- settable/void-call (inferred)
  e[42][K(250)] = e[35]  -- SETTABLE/CALL [a=42 b=250 c=35 d=nil] -- settable/void-call (inferred)
  goto L_45
  if e[20] then goto L_66 end
  ::L_47::
  goto L_139
  e[1] = e[134]  -- MOVE [a=134 b=1 c=829 d=nil]
  e[68][K(231)] = e[20]  -- SETTABLE/CALL [a=68 b=231 c=20 d=nil] -- settable/void-call (inferred)
  call(e[13], e[99])  -- CALL [a=13 b=78 c=99 d=nil] -- void call
  e[155] = K(23)  -- LOADK_S [a=155 b=23 c=28 d=nil]
  e[21] = e[5][K(0)]  -- GETTABLE/CLOSURE? [a=5 b=0 c=21 d=nil]
  ::L_53::
  goto L_100
  ::L_54::
  goto L_10
  e[37] = {}  -- NEWTABLE [a=37 b=0 c=0 d=nil]
  e[39] = {}  -- NEWTABLE [a=39 b=0 c=0 d=nil]
  e[39][K(435)] = e[41]  -- SETTABLE [a=39 b=435 c=41 d=115] -- settable/void-call (inferred)
  e[37][K(127)] = e[126]  -- SETTABLE [a=37 b=127 c=126 d=31] -- settable/void-call (inferred)
  call(e[42], e[35])  -- CALL? [a=42 b=0 c=35 d=nil] -- void call
  ::L_60::
  goto L_34
  e[13] = e[13][K(6)]  -- GETTABLE [a=13 b=6 c=74 d=nil]
  e[14] = e[2][K(0)]  -- GETTABLE/CLOSURE? [a=2 b=0 c=14 d=nil]
  e[15] = e[15]["traceback"]  -- GETTABLE [a=15 b=1 c=196 d=nil]  -- = "traceback"
  goto L_13
  ::L_65::
  goto L_29
  ::L_66::
  goto L_119
  if e[43] then goto L_164 end
  ::L_68::
  goto L_78
  e[36] = {}  -- NEWTABLE [a=36 b=0 c=0 d=nil]
  e[39] = {}  -- NEWTABLE [a=39 b=0 c=0 d=nil]
  e[38] = {}  -- NEWTABLE [a=0 b=38 c=0 d=nil]
  e[37] = {}  -- NEWTABLE [a=37 b=0 c=0 d=nil]
  e[36][K(22)] = e[100]  -- SETTABLE [a=36 b=22 c=100 d=15] -- settable/void-call (inferred)
  e[39][K(20)] = e[8]  -- SETTABLE [a=39 b=20 c=8 d=17] -- settable/void-call (inferred)
  e[38][K(20)] = e[111]  -- SETTABLE [a=38 b=20 c=111 d=17] -- settable/void-call (inferred)
  e[37][K(126)] = e[916]  -- SETTABLE [a=37 b=126 c=916 d=34] -- settable/void-call (inferred)
  e[42][K(17)] = e[35]  -- SETTABLE/CALL [a=42 b=17 c=35 d=nil] -- settable/void-call (inferred)
  ::L_78::
  goto L_187
  e[7] = call(e[7], e[0])  -- GETGLOBAL/CALL [a=7 b=1437 c=0 d=workspace]
  e[3] = 122  -- LOADK [a=3 b=339 c=0 d=122]
  goto L_81
  goto L_112
  ::L_83::
  -- UNKNOWN op? [a=321 b=423 c=165 d=nil]
  if e[57] then goto L_33 else goto L_85 end  -- back-edge (loop)
  ::L_86::
  goto L_65
  e[39] = {}  -- NEWTABLE [a=39 b=0 c=0 d=nil]
  e[38] = {}  -- NEWTABLE [a=0 b=38 c=0 d=nil]
  e[37] = {}  -- NEWTABLE [a=37 b=0 c=0 d=nil]
  e[37][K(124)] = e[4]  -- SETTABLE [a=37 b=124 c=4 d=24] -- settable/void-call (inferred)
  e[38][K(124)] = e[9]  -- SETTABLE [a=38 b=124 c=9 d=24] -- settable/void-call (inferred)
  e[39][K(124)] = e[112]  -- SETTABLE [a=39 b=124 c=112 d=24] -- settable/void-call (inferred)
  e[38][K(42)] = e[4]  -- SETTABLE [a=38 b=42 c=4 d=10] -- settable/void-call (inferred)
  e[37][K(103)] = e[119]  -- SETTABLE [a=37 b=103 c=119 d=11] -- settable/void-call (inferred)
  e[42][K(218)] = e[35]  -- SETTABLE/CALL [a=42 b=218 c=35 d=nil] -- settable/void-call (inferred)
  goto L_22
  ::L_97::
  goto L_203
  goto L_13
  e[3] = K(1363)  -- LOADK [a=3 b=1363 c=0 d=72]
  ::L_100::
  goto L_33
  e[22] = e[17][101]  -- GETTABLE/CLOSURE? [a=17 b=0 c=22 d=nil]  -- = 101
  e[23] = e[6][K(0)]  -- GETTABLE/CLOSURE? [a=6 b=0 c=23 d=nil]
  if e[18] then goto L_6 end  -- back-edge (loop)
  e[12] = e[18][23268]  -- GETTABLE/CLOSURE? [a=18 b=0 c=12 d=nil]  -- = 23268
  ::L_105::
  goto L_161
  if e[1] then goto L_130 else goto L_108 end
  e[0] = {}  -- NEWTABLE [a=0 b=11 c=0 d=nil]
  call(e[12], e[0])  -- CALL [a=12 b=0 c=0 d=nil] -- void call
  e[3] = 8  -- LOADK [a=3 b=1805 c=0 d=8]
  ::L_112::
  goto L_45
  ::L_113::
  goto L_36
  call(e[0], e[393])  -- CALL [a=0 b=6 c=393 d=nil] -- void call
  -- UNKNOWN op? [a=13 b=1 c=18 d=nil]
  call(e[13], e[167])  -- CALL [a=13 b=6 c=167 d=nil] -- void call
  e[13] = e[13][K(1)]  -- GETTABLE [a=13 b=1 c=18 d=nil]
  ::L_118::
  goto L_105
  ::L_119::
  goto L_113
  e[38] = {}  -- NEWTABLE [a=0 b=38 c=0 d=nil]
  e[37] = {}  -- NEWTABLE [a=37 b=0 c=0 d=nil]
  e[38][K(581)] = e[118]  -- SETTABLE [a=38 b=581 c=118 d=126] -- settable/void-call (inferred)
  e[37][K(27)] = e[2268]  -- SETTABLE [a=37 b=27 c=2268 d=66] -- settable/void-call (inferred)
  call(e[42], e[35])  -- CALL? [a=42 b=0 c=35 d=nil] -- void call
  ::L_125::
  goto L_134
  e[1] = e[14]  -- MOVE [a=14 b=1 c=226 d=nil]
  e[15] = e[6][K(0)]  -- GETTABLE/CLOSURE? [a=6 b=0 c=15 d=nil]
  e[16] = e[9][K(0)]  -- GETTABLE/CLOSURE? [a=9 b=0 c=16 d=nil]
  e[17] = e[10][K(0)]  -- GETTABLE/CLOSURE? [a=10 b=0 c=17 d=nil]
  ::L_130::
  goto L_97
  if e[10] then goto L_135 end
  goto L_30
  if e[133] then do return end else goto L_134 end
  ::L_134::
  goto L_168
  ::L_135::
  goto L_125
  if e[33] then goto L_1 end  -- back-edge (loop)
  ::L_137::
  goto L_83
  e[78] = 38  -- LOADK [a=78 b=393 c=37 d=38]
  ::L_139::
  goto L_33
  if e[84] then goto L_60 end  -- back-edge (loop)
  ::L_141::
  goto L_53
  goto L_13
  e[3] = 17  -- LOADK [a=3 b=725 c=0 d=17]
  ::L_144::
  goto L_45
  e[14] = 23  -- LOADK [a=14 b=90 c=0 d=23]
  e[239] = 193  -- LOADK [a=239 b=338 c=0 d=193]
  call(e[153], e[208])  -- CALL [a=153 b=32 c=208 d=nil] -- void call
  e[16][K(25)] = e[66]  -- SETTABLE/CALL [a=16 b=25 c=66 d=26] -- settable/void-call (inferred)
  e[96] = K(61)  -- LOADK_S [a=96 b=61 c=206 d=nil]
  ::L_150::
  if e[14] then goto L_168 else goto L_151 end
  e[37] = {}  -- NEWTABLE [a=37 b=0 c=0 d=nil]
  e[38] = {}  -- NEWTABLE [a=0 b=38 c=0 d=nil]
  e[38][K(67)] = e[114]  -- SETTABLE [a=38 b=67 c=114 d=48] -- settable/void-call (inferred)
  e[37][K(2350)] = e[16]  -- SETTABLE [a=37 b=2350 c=16 d=169] -- settable/void-call (inferred)
  call(e[42], e[35])  -- CALL? [a=42 b=0 c=35 d=nil] -- void call
  ::L_158::
  goto L_1
  e[13] = e[3][K(0)]  -- GETTABLE/CLOSURE? [a=3 b=0 c=13 d=nil]
  e[14] = e[7][K(0)]  -- GETTABLE/CLOSURE? [a=7 b=0 c=14 d=nil]
  ::L_161::
  goto L_13
  e[13] = e[19][K(0)]  -- GETTABLE/CLOSURE? [a=19 b=0 c=13 d=nil]
  if e[132] then do return end else goto L_164 end
  ::L_164::
  goto L_150
  e[13] = e[13][K(6)]  -- GETTABLE [a=13 b=6 c=74 d=nil]
  e[14] = e[14][K(6)]  -- GETTABLE [a=14 b=6 c=283 d=nil]
  e[15] = "info"  -- LOADK [a=15 b=709 c=0 d=info]
  ::L_168::
  goto L_141
  e[25] = {}  -- NEWTABLE [a=25 b=0 c=0 d=nil]
  e[26] = {}  -- NEWTABLE [a=26 b=0 c=0 d=nil]
  e[32] = K(16)  -- LOADK_S [a=0 b=16 c=32 d=nil]
  e[33] = K(13)  -- LOADK_S [a=0 b=13 c=33 d=nil]
  e[34] = K(1801)  -- LOADK [a=34 b=1801 c=0 d==>Jc149B]
  e[175] = {}  -- NEWTABLE [a=7 b=175 c=33 d=nil]
  e[216][K(664)] = e[33]  -- SETTABLE/CALL [a=216 b=664 c=33 d=441] -- settable/void-call (inferred)
  e[33][K(169)] = e[88]  -- SETTABLE/CALL [a=33 b=169 c=88 d=nil] -- settable/void-call (inferred)
  e[157][K(217)] = e[33]  -- SETTABLE/CALL [a=157 b=217 c=33 d=nil] -- settable/void-call (inferred)
  e[59][K(227)] = e[156]  -- SETTABLE/CALL [a=59 b=227 c=156 d=nil] -- settable/void-call (inferred)
  e[25] = K(179)  -- LOADK_S [a=25 b=179 c=173 d=nil]
  e[32] = K(0)  -- LOADK_N [a=0 b=0 c=32 d=nil]
  e[32] = e[32] + 22143  -- ADD [a=32 b=906 c=32 d=22143]
  e[32] = arith(e[32], e[741])  -- UNOP/arith? [a=32 b=32 c=741 d=nil]
  call(e[32], e[100])  -- CALL [a=32 b=25 c=100 d=nil] -- void call
  e[26][K(7)] = e[103]  -- SETTABLE [a=26 b=7 c=103 d=82] -- settable/void-call (inferred)
  call(e[34], e[24])  -- CALL? [a=34 b=0 c=24 d=nil] -- void call
  ::L_187::
  goto L_11
  if e[96] then goto L_10 else goto L_189 end  -- back-edge (loop)
  e[37] = {}  -- NEWTABLE [a=37 b=0 c=0 d=nil]
  e[38] = {}  -- NEWTABLE [a=0 b=38 c=0 d=nil]
  e[36] = {}  -- NEWTABLE [a=36 b=0 c=0 d=nil]
  e[38][K(12)] = e[111]  -- SETTABLE [a=38 b=12 c=111 d=138] -- settable/void-call (inferred)
  e[36][K(12)] = e[4]  -- SETTABLE [a=36 b=12 c=4 d=138] -- settable/void-call (inferred)
  e[37][K(37)] = e[111]  -- SETTABLE [a=37 b=37 c=111 d=33] -- settable/void-call (inferred)
  call(e[42], e[35])  -- CALL? [a=42 b=0 c=35 d=nil] -- void call
  goto L_197
  e[38] = {}  -- NEWTABLE [a=0 b=38 c=0 d=nil]
  e[37] = {}  -- NEWTABLE [a=37 b=0 c=0 d=nil]
  e[38][K(301)] = e[22]  -- SETTABLE [a=38 b=301 c=22 d=146] -- settable/void-call (inferred)
  e[37][K(121)] = e[2195]  -- SETTABLE [a=37 b=121 c=2195 d=106] -- settable/void-call (inferred)
  call(e[42], e[35])  -- CALL? [a=42 b=0 c=35 d=nil] -- void call
  ::L_203::
  goto L_144
  e[37] = {}  -- NEWTABLE [a=37 b=0 c=0 d=nil]
  e[37][K(2180)] = e[4]  -- SETTABLE [a=37 b=2180 c=4 d=209] -- settable/void-call (inferred)
  e[37][K(1901)] = e[121]  -- SETTABLE [a=37 b=1901 c=121 d=97] -- settable/void-call (inferred)
  e[42][K(198)] = e[35]  -- SETTABLE/CALL [a=42 b=198 c=35 d=nil] -- settable/void-call (inferred)
  goto L_208
  e[13] = e[9][K(18)]  -- GETTABLE/CLOSURE? [a=9 b=18 c=13 d=nil]
  e[14] = e[8][K(0)]  -- GETTABLE/CLOSURE? [a=8 b=0 c=14 d=nil]
  e[15] = K(1789)  -- LOADK [a=15 b=1789 c=0 d=449]
  e[16] = e[16][K(6)]  -- GETTABLE [a=16 b=6 c=25 d=nil]
  e[14] = K(14)  -- LOADK_N [a=0 b=14 c=0 d=nil]
  if e[13] then do return end else goto L_215 end
  ::L_215::
  goto L_158
end

local function proto61(...)  -- 12 instrs, 8 blocks (structured)
  local e = regs
  -- UNKNOWN op? [a=104 b=80 c=265 d=nil]
  ::L_3::
  goto L_3
  e[0] = {}  -- NEWTABLE [a=0 b=4 c=0 d=nil]
  ::L_5::
  e[5] = e[5][K(3)]  -- GETTABLE [a=5 b=3 c=74 d=nil]
  e[6] = e[2][K(0)]  -- GETTABLE/CLOSURE? [a=2 b=0 c=6 d=nil]
  e[7] = e[7]["unpack"]  -- GETTABLE [a=7 b=1 c=1829 d=nil]  -- = "unpack"
  goto L_5
  e[4] = 71  -- LOADK [a=4 b=414 c=0 d=71]
  ::L_10::
  goto L_10
  e[5] = e[4][71]  -- GETTABLE/CLOSURE? [a=4 b=0 c=5 d=nil]  -- = 71
  do return end  -- JMP/RETURN [a=0 b=0 c=5 d=nil]
end

local function proto62(...)  -- 103 instrs, 42 blocks (structured)
  local e = regs
  ::L_1::
  ::L_71::
  ::L_101::
  ::L_79::
  ::L_7::
  ::L_62::
  ::L_66::
  goto L_1
  e[0] = {}  -- NEWTABLE [a=0 b=5 c=0 d=nil]
  if e[71] then goto L_61 end
  ::L_5::
  goto L_93
  ::L_6::
  if e[53] then goto L_73 else goto L_7 end
  e[6][K(1)] = e[1710]  -- SETTABLE/CALL [a=6 b=1 c=1710 d=nil] -- settable/void-call (inferred)
  -- UNKNOWN op? [a=5 b=0 c=8 d=nil]
  e[9] = e[3][K(0)]  -- GETTABLE/CLOSURE? [a=3 b=0 c=9 d=nil]
  e[10] = e[2][K(0)]  -- GETTABLE/CLOSURE? [a=2 b=0 c=10 d=nil]
  e[6] = K(6)  -- LOADK_N [a=0 b=6 c=5 d=nil]
  e[2] = e[6][K(0)]  -- GETTABLE/CLOSURE? [a=6 b=0 c=2 d=nil]
  ::L_14::
  goto L_44
  e[13] = {}  -- NEWTABLE [a=13 b=0 c=0 d=nil]
  e[15] = {}  -- NEWTABLE [a=15 b=0 c=0 d=nil]
  e[19] = K(8)  -- LOADK_S [a=0 b=8 c=19 d=nil]
  e[20] = ">i8"  -- LOADK [a=20 b=6 c=0 d=>i8]
  e[21] = "000000000000000000001200"  -- LOADK [a=21 b=1478 c=0 d=      �]
  -- UNKNOWN op? [a=156 b=19 c=192 d=nil]
  e[20] = K(8)  -- LOADK_S [a=0 b=8 c=20 d=nil]
  e[237] = ">i8"  -- LOADK [a=237 b=6 c=0 d=>i8]
  e[22] = "000000000000000000000241"  -- LOADK [a=22 b=1312 c=0 d=       �]
  e[20] = 241  -- LOADK_N [a=0 b=20 c=0 d=nil]
  e[19] = arith(e[19], e[206])  -- ARITH [a=19 b=19 c=206 d=nil]  -- = 697
  e[20] = K(9)  -- LOADK_S [a=0 b=9 c=20 d=nil]
  e[21] = "f"  -- LOADK [a=21 b=1914 c=0 d=f]
  e[22] = 1  -- LOADK [a=22 b=107 c=0 d=1]
  e[23] = 1  -- LOADK [a=23 b=107 c=0 d=1]
  e[20] = 102  -- LOADK_N [a=0 b=20 c=4 d=nil]
  e[19] = arith(e[19], e[20])  -- ARITH [a=19 b=19 c=20 d=nil]  -- = 799
  e[19] = e[19] + 16928  -- ADD [a=19 b=1657 c=19 d=16928]  -- = 17727
  e[19] = arith(e[19], e[597])  -- UNOP/arith? [a=19 b=19 c=597 d=nil]  -- = 286
  call(e[19], e[95])  -- CALL [a=19 b=15 c=95 d=nil] -- void call
  e[13][K(10)] = e[47]  -- SETTABLE [a=13 b=10 c=47 d=72] -- settable/void-call (inferred)
  call(e[23], e[11])  -- CALL? [a=23 b=0 c=11 d=nil] -- void call
  ::L_37::
  goto L_57
  e[6] = e[6][K(159)]  -- GETTABLE [a=6 b=159 c=82 d=nil]
  e[7] = e[2][K(0)]  -- GETTABLE/CLOSURE? [a=2 b=0 c=7 d=nil]
  do return end  -- JMP/RETURN [a=7 b=0 c=0 d=nil]
  e[8] = e[8][750480426]  -- GETTABLE [a=8 b=5 c=167 d=nil]  -- = 750480426
  goto L_6
  e[6] = 23268  -- LOADK [a=6 b=588 c=0 d=23268]
  ::L_44::
  goto L_91
  if e[6] then do return end else goto L_46 end
  ::L_46::
  e[7] = e[2][K(0)]  -- GETTABLE/CLOSURE? [a=2 b=0 c=7 d=nil]
  ::L_47::
  goto L_6
  e[27] = {}  -- NEWTABLE [a=0 b=27 c=0 d=nil]
  e[26] = {}  -- NEWTABLE [a=26 b=0 c=0 d=nil]
  e[27][K(69)] = e[99]  -- SETTABLE [a=27 b=69 c=99 d=54] -- settable/void-call (inferred)
  e[26][K(98)] = e[99]  -- SETTABLE [a=26 b=98 c=99 d=64] -- settable/void-call (inferred)
  call(e[31], e[24])  -- CALL? [a=31 b=0 c=24 d=nil] -- void call
  goto L_5
  e[54][K(393)] = e[783]  -- SETTABLE [a=54 b=393 c=783 d=38] -- settable/void-call (inferred)
  e[6] = 24921  -- LOADK [a=6 b=1042 c=0 d=24921]
  e[7] = e[2][K(0)]  -- GETTABLE/CLOSURE? [a=2 b=0 c=7 d=nil]
  ::L_57::
  goto L_6
  e[1] = e[6]  -- MOVE [a=6 b=1 c=638 d=nil]
  e[8] = e[5][K(0)]  -- GETTABLE/CLOSURE? [a=5 b=0 c=8 d=nil]
  goto L_6
  ::L_61::
  e[0] = {}  -- NEWTABLE [a=0 b=44 c=0 d=nil]
  goto L_62
  goto L_47
  ::L_65::
  -- UNKNOWN op? [a=174 b=114 c=149 d=nil]
  goto L_66
  e[26] = {}  -- NEWTABLE [a=26 b=0 c=0 d=nil]
  e[26][K(1)] = e[99]  -- SETTABLE [a=26 b=1 c=99 d=38] -- settable/void-call (inferred)
  e[26][K(91)] = e[86]  -- SETTABLE [a=26 b=91 c=86 d=62] -- settable/void-call (inferred)
  call(e[31], e[24])  -- CALL? [a=31 b=0 c=24 d=nil] -- void call
  goto L_71
  ::L_73::
  e[28] = {}  -- NEWTABLE [a=28 b=0 c=0 d=nil]
  e[26] = {}  -- NEWTABLE [a=26 b=0 c=0 d=nil]
  e[28][K(88)] = e[112]  -- SETTABLE [a=28 b=88 c=112 d=9] -- settable/void-call (inferred)
  e[28][K(84)] = e[94]  -- SETTABLE [a=28 b=84 c=94 d=8] -- settable/void-call (inferred)
  e[26][K(27)] = e[81]  -- SETTABLE [a=26 b=27 c=81 d=66] -- settable/void-call (inferred)
  call(e[31], e[24])  -- CALL? [a=31 b=0 c=24 d=nil] -- void call
  goto L_79
  e[28] = {}  -- NEWTABLE [a=28 b=0 c=0 d=nil]
  e[26] = {}  -- NEWTABLE [a=26 b=0 c=0 d=nil]
  e[27] = {}  -- NEWTABLE [a=0 b=27 c=0 d=nil]
  e[25] = {}  -- NEWTABLE [a=25 b=0 c=0 d=nil]
  e[25][K(110)] = e[4]  -- SETTABLE [a=25 b=110 c=4 d=20] -- settable/void-call (inferred)
  e[27][K(110)] = e[4]  -- SETTABLE [a=27 b=110 c=4 d=20] -- settable/void-call (inferred)
  e[28][K(110)] = e[48]  -- SETTABLE [a=28 b=110 c=48 d=20] -- settable/void-call (inferred)
  e[25][K(104)] = e[110]  -- SETTABLE [a=25 b=104 c=110 d=25] -- settable/void-call (inferred)
  e[27][K(119)] = e[122]  -- SETTABLE [a=27 b=119 c=122 d=22] -- settable/void-call (inferred)
  e[26][K(93)] = e[100]  -- SETTABLE [a=26 b=93 c=100 d=2] -- settable/void-call (inferred)
  call(e[31], e[24])  -- CALL? [a=31 b=0 c=24 d=nil] -- void call
  ::L_91::
  goto L_14
  e[7] = e[2][K(0)]  -- GETTABLE/CLOSURE? [a=2 b=0 c=7 d=nil]
  ::L_93::
  goto L_6
  ::L_95::
  goto L_95
  e[26] = {}  -- NEWTABLE [a=26 b=0 c=0 d=nil]
  e[28] = {}  -- NEWTABLE [a=28 b=0 c=0 d=nil]
  e[28][K(116)] = e[279]  -- SETTABLE [a=28 b=116 c=279 d=45] -- settable/void-call (inferred)
  e[26][K(11)] = e[93]  -- SETTABLE [a=26 b=11 c=93 d=95] -- settable/void-call (inferred)
  call(e[31], e[24])  -- CALL? [a=31 b=0 c=24 d=nil] -- void call
  goto L_101
  if e[86] then goto L_37 end  -- back-edge (loop)
  goto L_65
end

local function proto63(...)  -- 6 instrs, 4 blocks (structured)
  local e = regs
  ::L_1::
  -- UNKNOWN op? [a=431 b=452 c=189 d=nil]
  ::L_3::
  goto L_3
  e[0] = {}  -- NEWTABLE [a=0 b=2 c=0 d=nil]
  e[2][K(167)] = e[1756]  -- SETTABLE [a=2 b=167 c=1756 d=39] -- settable/void-call (inferred)
  goto L_1
end

local function proto64(...)  -- 76 instrs, 36 blocks (structured)
  local e = regs
  ::L_1::
  ::L_8::
  ::L_30::
  ::L_58::
  ::L_64::
  ::L_23::
  -- UNKNOWN op? [a=93 b=416 c=82 d=nil]
  ::L_74::
  ::L_14::
  ::L_49::
  do return end  -- JMP/RETURN [a=234 b=175 c=5 d=nil]
  e[20] = {}  -- NEWTABLE [a=20 b=0 c=0 d=nil]
  e[21] = {}  -- NEWTABLE [a=0 b=21 c=0 d=nil]
  e[20][K(71)] = e[4]  -- SETTABLE [a=20 b=71 c=4 d=49] -- settable/void-call (inferred)
  e[21][K(71)] = e[4]  -- SETTABLE [a=21 b=71 c=4 d=49] -- settable/void-call (inferred)
  e[20][K(69)] = e[24]  -- SETTABLE [a=20 b=69 c=24 d=54] -- settable/void-call (inferred)
  call(e[25], e[18])  -- CALL? [a=25 b=0 c=18 d=nil] -- void call
  goto L_8
  e[21] = {}  -- NEWTABLE [a=0 b=21 c=0 d=nil]
  e[20] = {}  -- NEWTABLE [a=20 b=0 c=0 d=nil]
  e[21][K(35)] = e[4]  -- SETTABLE [a=21 b=35 c=4 d=53] -- settable/void-call (inferred)
  e[20][K(43)] = e[71]  -- SETTABLE [a=20 b=43 c=71 d=71] -- settable/void-call (inferred)
  e[25][K(171)] = e[18]  -- SETTABLE/CALL [a=25 b=171 c=18 d=nil] -- settable/void-call (inferred)
  goto L_14
  ::L_15::
  goto L_24
  e[20] = {}  -- NEWTABLE [a=20 b=0 c=0 d=nil]
  e[22] = {}  -- NEWTABLE [a=22 b=0 c=0 d=nil]
  e[19] = {}  -- NEWTABLE [a=19 b=0 c=0 d=nil]
  e[22][K(91)] = e[484]  -- SETTABLE [a=22 b=91 c=484 d=62] -- settable/void-call (inferred)
  e[19][K(91)] = e[108]  -- SETTABLE [a=19 b=91 c=108 d=62] -- settable/void-call (inferred)
  e[20][K(10)] = e[62]  -- SETTABLE [a=20 b=10 c=62 d=72] -- settable/void-call (inferred)
  call(e[25], e[18])  -- CALL? [a=25 b=0 c=18 d=nil] -- void call
  goto L_23
  ::L_24::
  goto L_39
  e[21] = {}  -- NEWTABLE [a=0 b=21 c=0 d=nil]
  e[20] = {}  -- NEWTABLE [a=20 b=0 c=0 d=nil]
  e[21][K(5)] = e[108]  -- SETTABLE [a=21 b=5 c=108 d=65] -- settable/void-call (inferred)
  e[20][K(22)] = e[52]  -- SETTABLE [a=20 b=22 c=52 d=15] -- settable/void-call (inferred)
  e[25][K(177)] = e[18]  -- SETTABLE/CALL [a=25 b=177 c=18 d=nil] -- settable/void-call (inferred)
  goto L_30
  e[6] = e[4][K(0)]  -- GETTABLE/CLOSURE? [a=4 b=0 c=6 d=nil]
  call(e[6], e[182])  -- CALL [a=6 b=186 c=182 d=nil] -- void call
  e[249][K(99)] = e[166]  -- SETTABLE/CALL [a=249 b=99 c=166 d=nil] -- settable/void-call (inferred)
  e[116][K(96)] = e[226]  -- SETTABLE/CALL [a=116 b=96 c=226 d=nil] -- settable/void-call (inferred)
  e[164][K(16)] = e[163]  -- SETTABLE/CALL [a=164 b=16 c=163 d=nil] -- settable/void-call (inferred)
  do return end  -- JMP/RETURN [a=108 b=113 c=2 d=nil]
  e[63][K(217)] = e[113]  -- SETTABLE/CALL [a=63 b=217 c=113 d=nil] -- settable/void-call (inferred)
  e[7] = e[7][492211299]  -- GETTABLE [a=7 b=2 c=393 d=nil]  -- = 492211299
  ::L_39::
  goto L_46
  e[16] = 144  -- LOADK [a=16 b=1386 c=0 d=144]
  ::L_41::
  goto L_74
  e[0] = {}  -- NEWTABLE [a=0 b=4 c=0 d=nil]
  e[5] = e[3][K(0)]  -- GETTABLE/CLOSURE? [a=3 b=0 c=5 d=nil]
  e[6] = e[120][K(0)]  -- GETINDEX? [a=120 b=0 c=6 d=nil]
  ::L_45::
  goto L_70
  ::L_46::
  goto L_41
  -- UNKNOWN op? [a=0 b=5 c=0 d=nil]
  e[5] = e[4][K(0)]  -- GETTABLE/CLOSURE? [a=4 b=0 c=5 d=nil]
  goto L_49
  e[5] = K(0)  -- LOADK_N [a=0 b=0 c=5 d=nil]
  e[4] = e[5][K(0)]  -- GETTABLE/CLOSURE? [a=5 b=0 c=4 d=nil]
  e[5] = e[5][K(2)]  -- GETTABLE [a=5 b=2 c=82 d=nil]
  ::L_53::
  goto L_53
  ::L_54::
  goto L_1
  call(e[175], e[131])  -- CALL [a=175 b=219 c=131 d=nil] -- void call
  e[16][K(683)] = e[226]  -- SETTABLE/CALL [a=16 b=683 c=226 d=402] -- settable/void-call (inferred)
  e[71] = K(36)  -- LOADK_S [a=71 b=36 c=14 d=nil]
  goto L_58
  e[12] = {}  -- NEWTABLE [a=12 b=0 c=0 d=nil]
  e[10] = {}  -- NEWTABLE [a=10 b=0 c=0 d=nil]
  e[16] = 392  -- LOADK_N [a=1828 b=252 c=16 d=380]
  e[846] = e[846][true]  -- GETTABLE/CLOSURE [a=846 b=16 c=187 d=nil]  -- = true
  if e[16] then goto L_74 else goto L_64 end  -- back-edge (loop)
  e[36] = e[16] + 8855  -- ADD [a=36 b=2259 c=16 d=8855]  -- = 8999
  e[16] = arith(e[16], e[1962])  -- UNOP/arith? [a=16 b=16 c=1962 d=nil]  -- = 46
  call(e[16], e[40])  -- CALL [a=16 b=12 c=40 d=nil] -- void call
  e[10][K(66)] = e[116]  -- SETTABLE [a=10 b=66 c=116 d=74] -- settable/void-call (inferred)
  call(e[17], e[8])  -- CALL? [a=17 b=0 c=8 d=nil] -- void call
  ::L_70::
  goto L_45
  goto L_15
  if e[16] then goto L_64 end  -- back-edge (loop)
  goto L_54
end

local function proto65(...)  -- 8 instrs, 5 blocks (structured)
  local e = regs
  ::L_1::
  goto L_1
  e[1] = e[0][K(1)]  -- GETTABLE/CLOSURE [a=0 b=1 c=0 d=nil]
  e[1] = e[1]  -- MOVE [a=1 b=1 c=189 d=nil]
  e[3] = e[1][K(3)]  -- GETTABLE/CLOSURE [a=1 b=3 c=0 d=nil]
  goto L_1
  ::L_6::
  goto L_6
  goto L_1
  -- UNKNOWN op? [a=172 b=96 c=277 d=nil]
end

local function proto66(...)  -- 75 instrs, 31 blocks (structured)
  local e = regs
  ::L_1::
  ::L_31::
  ::L_49::
  goto L_1
  -- UNKNOWN op? [a=7 b=1 c=1404 d=nil]
  e[9] = e[2][K(0)]  -- GETTABLE/CLOSURE? [a=2 b=0 c=9 d=nil]
  goto L_7
  ::L_5::
  goto L_43
  e[25] = {}  -- NEWTABLE [a=0 b=25 c=0 d=nil]
  ::L_7::
  e[24] = {}  -- NEWTABLE [a=24 b=0 c=0 d=nil]
  e[25][K(67)] = e[4]  -- SETTABLE [a=25 b=67 c=4 d=48] -- settable/void-call (inferred)
  e[24][K(51)] = e[40]  -- SETTABLE [a=24 b=51 c=40 d=44] -- settable/void-call (inferred)
  e[29][K(211)] = e[22]  -- SETTABLE/CALL [a=29 b=211 c=22 d=nil] -- settable/void-call (inferred)
  ::L_11::
  goto L_47
  e[25] = {}  -- NEWTABLE [a=0 b=25 c=0 d=nil]
  e[24] = {}  -- NEWTABLE [a=24 b=0 c=0 d=nil]
  e[23] = {}  -- NEWTABLE [a=23 b=0 c=0 d=nil]
  e[25][K(5)] = e[122]  -- SETTABLE [a=25 b=5 c=122 d=65] -- settable/void-call (inferred)
  e[23][K(101)] = e[4]  -- SETTABLE [a=23 b=101 c=4 d=59] -- settable/void-call (inferred)
  e[25][K(52)] = e[4]  -- SETTABLE [a=25 b=52 c=4 d=58] -- settable/void-call (inferred)
  e[23][K(85)] = e[4]  -- SETTABLE [a=23 b=85 c=4 d=60] -- settable/void-call (inferred)
  e[24][K(116)] = e[53]  -- SETTABLE [a=24 b=116 c=53 d=45] -- settable/void-call (inferred)
  e[29][K(209)] = e[22]  -- SETTABLE/CALL [a=29 b=209 c=22 d=nil] -- settable/void-call (inferred)
  ::L_21::
  goto L_50
  e[0] = {}  -- NEWTABLE [a=0 b=2 c=0 d=nil]
  e[3] = 93  -- LOADK [a=3 b=196 c=0 d=93]
  e[4] = 184  -- LOADK [a=4 b=1460 c=0 d=184]
  e[5] = 47  -- LOADK [a=5 b=1610 c=0 d=47]
  goto L_73
  ::L_27::
  -- UNKNOWN op? [a=224 b=15 c=182 d=nil]
  if e[1] then do return end else goto L_29 end
  ::L_29::
  goto L_36
  if e[0] then goto L_74 else goto L_31 end
  e[24] = {}  -- NEWTABLE [a=24 b=0 c=0 d=nil]
  e[24][K(13)] = e[93]  -- SETTABLE [a=24 b=13 c=93 d=67] -- settable/void-call (inferred)
  e[24][K(30)] = e[32]  -- SETTABLE [a=24 b=30 c=32 d=46] -- settable/void-call (inferred)
  e[29][K(133)] = e[22]  -- SETTABLE/CALL [a=29 b=133 c=22 d=nil] -- settable/void-call (inferred)
  ::L_36::
  goto L_29
  ::L_37::
  goto L_66
  e[24] = {}  -- NEWTABLE [a=24 b=0 c=0 d=nil]
  e[26] = {}  -- NEWTABLE [a=26 b=0 c=0 d=nil]
  e[26][K(93)] = e[94]  -- SETTABLE [a=26 b=93 c=94 d=2] -- settable/void-call (inferred)
  e[24][K(83)] = e[61]  -- SETTABLE [a=24 b=83 c=61 d=75] -- settable/void-call (inferred)
  e[29][K(142)] = e[22]  -- SETTABLE/CALL [a=29 b=142 c=22 d=nil] -- settable/void-call (inferred)
  ::L_43::
  goto L_27
  ::L_44::
  goto L_5
  ::L_45::
  goto L_11
  ::L_47::
  goto L_44
  e[68][K(0)] = e[0]  -- SETTABLE/CALL [a=68 b=0 c=0 d=nil] -- settable/void-call (inferred)
  goto L_49
  ::L_50::
  goto L_43
  e[12] = {}  -- NEWTABLE [a=12 b=0 c=0 d=nil]
  e[13] = {}  -- NEWTABLE [a=0 b=13 c=0 d=nil]
  e[18] = K(22)  -- LOADK_S [a=0 b=22 c=18 d=nil]
  e[19] = K(14)  -- LOADK_S [a=0 b=14 c=19 d=nil]
  e[20] = K(13)  -- LOADK_S [a=0 b=13 c=20 d=nil]
  e[21] = "=h=<L<<c219=>=l<"  -- LOADK [a=21 b=768 c=0 d==h=<L<<c219=>=l<]
  e[20] = 237  -- LOADK_N [a=0 b=0 c=20 d=nil]
  e[19] = 237  -- LOADK_N [a=53 b=0 c=19 d=nil]
  e[20] = 28  -- LOADK [a=20 b=2099 c=7 d=28]
  e[18] = 0  -- LOADK_N [a=0 b=18 c=92 d=nil]
  e[18] = e[18] + 12554  -- ADD [a=18 b=1395 c=18 d=12554]  -- = 12554
  e[18] = arith(e[18], e[2300])  -- UNOP/arith? [a=18 b=18 c=2300 d=nil]  -- = 3
  call(e[18], e[66])  -- CALL [a=18 b=13 c=66 d=nil] -- void call
  e[12][K(40)] = e[122]  -- SETTABLE [a=12 b=40 c=122 d=47] -- settable/void-call (inferred)
  call(e[240], e[10])  -- CALL? [a=240 b=0 c=10 d=nil] -- void call
  ::L_66::
  goto L_21
  e[7] = e[7][K(15)]  -- GETTABLE [a=7 b=15 c=909 d=nil]
  call(e[8], e[87])  -- CALL [a=8 b=59 c=87 d=nil] -- void call
  e[195][K(2)] = e[116]  -- SETTABLE/CALL [a=195 b=2 c=116 d=nil] -- settable/void-call (inferred)
  e[153][K(251)] = e[393]  -- SETTABLE/CALL [a=153 b=251 c=393 d=nil] -- settable/void-call (inferred)
  e[96] = K(228)  -- LOADK_S [a=96 b=228 c=27 d=nil]
  if e[7] then do return end else goto L_73 end
  ::L_73::
  goto L_45
  ::L_74::
  if e[217] then goto L_45 end  -- back-edge (loop)
  goto L_37
end

local function proto67(...)  -- 13 instrs, 8 blocks (structured)
  local e = regs
  ::L_1::
  ::L_12::
  e[385][K(404)] = e[122]  -- SETTABLE/CALL [a=385 b=404 c=122 d=nil] -- settable/void-call (inferred)
  ::L_3::
  e[5] = e[2][750480426]  -- GETTABLE/CLOSURE? [a=2 b=0 c=5 d=nil]  -- = 750480426
  e[6] = e[1][K(6)]  -- GETTABLE/CLOSURE [a=1 b=6 c=0 d=nil]
  e[7] = e[1][750480426]  -- GETTABLE/CLOSURE? [a=1 b=0 c=7 d=nil]  -- = 750480426
  goto L_3
  ::L_8::
  goto L_8
  e[0] = {}  -- NEWTABLE [a=0 b=2 c=0 d=nil]
  e[3] = e[0][K(3)]  -- GETTABLE/CLOSURE [a=0 b=3 c=0 d=nil]
  e[3] = e[3]  -- MOVE [a=3 b=3 c=1462 d=nil]
  goto L_12
  goto L_1
end

local function proto68(...)  -- 97 instrs, 33 blocks (structured)
  local e = regs
  ::L_1::
  ::L_30::
  ::L_79::
  ::L_7::
  ::L_64::
  ::L_78::
  goto L_1
  e[6] = e[6][K(3)]  -- GETTABLE [a=6 b=3 c=25 d=nil]
  e[9] = e[6][K(0)]  -- GETTABLE/CLOSURE? [a=6 b=0 c=9 d=nil]
  do return end  -- JMP/RETURN [a=0 b=98 c=130 d=nil]
  ::L_5::
  goto L_18
  ::L_6::
  goto L_92
  e[31] = {}  -- NEWTABLE [a=0 b=31 c=0 d=nil]
  e[30] = {}  -- NEWTABLE [a=30 b=0 c=0 d=nil]
  e[29] = {}  -- NEWTABLE [a=29 b=0 c=0 d=nil]
  e[29][K(9)] = e[88]  -- SETTABLE [a=29 b=9 c=88 d=4] -- settable/void-call (inferred)
  e[30][K(9)] = e[4]  -- SETTABLE [a=30 b=9 c=4 d=4] -- settable/void-call (inferred)
  e[31][K(117)] = e[4]  -- SETTABLE [a=31 b=117 c=4 d=19] -- settable/void-call (inferred)
  e[29][K(117)] = e[4]  -- SETTABLE [a=29 b=117 c=4 d=19] -- settable/void-call (inferred)
  e[29][K(99)] = e[4]  -- SETTABLE [a=29 b=99 c=4 d=5] -- settable/void-call (inferred)
  e[30][K(122)] = e[21]  -- SETTABLE [a=30 b=122 c=21 d=21] -- settable/void-call (inferred)
  call(e[35], e[28])  -- CALL? [a=35 b=0 c=28 d=nil] -- void call
  ::L_18::
  goto L_90
  ::L_19::
  goto L_1
  ::L_20::
  goto L_36
  e[31] = {}  -- NEWTABLE [a=0 b=31 c=0 d=nil]
  e[30] = {}  -- NEWTABLE [a=30 b=0 c=0 d=nil]
  e[31][K(46)] = e[88]  -- SETTABLE [a=31 b=46 c=88 d=87] -- settable/void-call (inferred)
  e[30][K(97)] = e[61]  -- SETTABLE [a=30 b=97 c=61 d=79] -- settable/void-call (inferred)
  call(e[35], e[28])  -- CALL? [a=35 b=0 c=28 d=nil] -- void call
  ::L_27::
  goto L_27
  call(e[7], e[0])  -- CALL [a=7 b=0 c=0 d=nil] -- void call
  e[8] = 122  -- LOADK [a=8 b=339 c=0 d=122]
  goto L_30
  e[0] = {}  -- NEWTABLE [a=0 b=4 c=0 d=nil]
  call(e[5], e[0])  -- CALL [a=5 b=0 c=0 d=nil] -- void call
  e[6] = e[6][K(3)]  -- GETTABLE [a=6 b=3 c=1829 d=nil]
  goto L_6
  if e[79] then do return end else goto L_36 end
  ::L_36::
  goto L_20
  e[19] = {}  -- NEWTABLE [a=0 b=19 c=0 d=nil]
  e[17] = {}  -- NEWTABLE [a=17 b=0 c=0 d=nil]
  e[18] = {}  -- NEWTABLE [a=18 b=0 c=0 d=nil]
  e[24] = K(18)  -- LOADK_S [a=0 b=18 c=24 d=nil]
  e[25] = K(12)  -- LOADK_S [a=0 b=12 c=25 d=nil]
  e[26] = K(13)  -- LOADK_S [a=0 b=13 c=26 d=nil]
  e[205] = " J> f==>i "  -- LOADK [a=205 b=395 c=0]
  e[26] = 12  -- LOADK_N [a=0 b=0 c=26 d=nil]
  e[25] = 28  -- LOADK_N [a=15 b=0 c=25 d=nil]
  e[145] = 28  -- LOADK [a=145 b=2099 c=0 d=28]
  e[24] = 3221225472  -- LOADK_N [a=0 b=24 c=0 d=nil]
  -- UNKNOWN op? [a=24 b=1154 c=24 d=-3221198031]
  e[24] = arith(e[24], e[328])  -- UNOP/arith? [a=24 b=24 c=328 d=nil]  -- = 15
  call(e[24], e[1568])  -- CALL [a=24 b=17 c=1568 d=nil] -- void call
  e[24] = K(7)  -- LOADK_S [a=0 b=7 c=24 d=nil]
  e[25] = K(8)  -- LOADK_S [a=0 b=8 c=25 d=nil]
  e[50] = ">i8"  -- LOADK [a=50 b=6 c=0 d=>i8]
  e[126] = "000000000000000000000&"  -- LOADK [a=126 b=1619 c=0 d=       &]
  e[25] = 38  -- LOADK_N [a=0 b=25 c=0 d=nil]
  e[25] = arith(e[25], e[795])  -- UNOP/arith? [a=25 b=25 c=795 d=nil]  -- = 541
  e[26] = 11  -- LOADK [a=26 b=1380 c=0 d=11]
  e[24] = 1107968  -- LOADK_N [a=0 b=24 c=0 d=nil]
  e[24] = e[24] + -1092571  -- ADD [a=24 b=1189 c=24 d=-1092571]  -- = 15397
  e[24] = arith(e[24], e[2318])  -- UNOP/arith? [a=24 b=24 c=2318 d=nil]  -- = 8
  call(e[24], e[1568])  -- CALL [a=24 b=19 c=1568 d=nil] -- void call
  e[18][K(110)] = e[61]  -- SETTABLE [a=18 b=110 c=61 d=20] -- settable/void-call (inferred)
  call(e[27], e[16])  -- CALL? [a=27 b=0 c=16 d=nil] -- void call
  goto L_64
  e[31] = {}  -- NEWTABLE [a=0 b=31 c=0 d=nil]
  e[30] = {}  -- NEWTABLE [a=30 b=0 c=0 d=nil]
  e[32] = {}  -- NEWTABLE [a=32 b=0 c=0 d=nil]
  e[31][K(116)] = e[4]  -- SETTABLE [a=31 b=116 c=4 d=45] -- settable/void-call (inferred)
  e[32][K(67)] = e[87]  -- SETTABLE [a=32 b=67 c=87 d=48] -- settable/void-call (inferred)
  e[31][K(69)] = e[61]  -- SETTABLE [a=31 b=69 c=61 d=54] -- settable/void-call (inferred)
  e[31][K(30)] = e[19]  -- SETTABLE [a=31 b=30 c=19 d=46] -- settable/void-call (inferred)
  e[31][K(35)] = e[19]  -- SETTABLE [a=31 b=35 c=19 d=53] -- settable/void-call (inferred)
  e[31][K(125)] = e[61]  -- SETTABLE [a=31 b=125 c=61 d=43] -- settable/void-call (inferred)
  e[30][K(81)] = e[117]  -- SETTABLE [a=30 b=81 c=117 d=7] -- settable/void-call (inferred)
  call(e[35], e[28])  -- CALL? [a=35 b=0 c=28 d=nil] -- void call
  goto L_19
  ::L_77::
  -- UNKNOWN op? [a=215 b=69 c=346 d=nil]
  goto L_78
  e[1] = e[9]  -- MOVE [a=9 b=1 c=1693 d=nil]
  e[11] = e[6][K(0)]  -- GETTABLE/CLOSURE? [a=6 b=0 c=11 d=nil]
  e[12] = e[7][750480426]  -- GETTABLE/CLOSURE? [a=7 b=0 c=12 d=nil]  -- = 750480426
  e[13] = e[2][750480426]  -- GETTABLE/CLOSURE? [a=2 b=0 c=13 d=nil]  -- = 750480426
  ::L_84::
  goto L_84
  e[14] = e[4][750480426]  -- GETTABLE/CLOSURE? [a=4 b=0 c=14 d=nil]  -- = 750480426
  e[135] = e[28][17]  -- GETTABLE/CLOSURE? [a=28 b=0 c=135 d=nil]  -- = 17
  if e[141] then goto L_7 end  -- back-edge (loop)
  e[5] = e[9][10652]  -- GETTABLE/CLOSURE? [a=9 b=0 c=5 d=nil]  -- = 10652
  e[6] = e[10][false]  -- GETTABLE/CLOSURE? [a=10 b=0 c=6 d=nil]  -- = false
  ::L_90::
  goto L_93
  if e[6] then goto L_18 end  -- back-edge (loop)
  ::L_92::
  goto L_77
  ::L_93::
  goto L_79
  e[8] = e[11][17]  -- GETTABLE/CLOSURE? [a=11 b=0 c=8 d=nil]  -- = 17
  e[7] = e[12][750480426]  -- GETTABLE/CLOSURE? [a=12 b=0 c=7 d=nil]  -- = 750480426
  if e[34] then do return end else goto L_97 end
  ::L_97::
  goto L_5
end

local function proto69(...)  -- 104 instrs, 44 blocks (structured)
  local e = regs
  ::L_1::
  ::L_7::
  ::L_64::
  ::L_77::
  ::L_21::
  ::L_72::
  goto L_1
  e[20] = e[20] + 5153  -- ADD [a=20 b=630 c=20 d=5153]  -- = 5296
  e[20] = arith(e[20], e[646])  -- UNOP/arith? [a=20 b=20 c=646 d=nil]  -- = 59
  call(e[20], e[28])  -- CALL [a=20 b=16 c=28 d=nil] -- void call
  e[14][K(11)] = e[125]  -- SETTABLE [a=14 b=11 c=125 d=95] -- settable/void-call (inferred)
  e[23][K(46)] = e[12]  -- SETTABLE/CALL [a=23 b=46 c=12 d=nil] -- settable/void-call (inferred)
  goto L_7
  e[0] = {}  -- NEWTABLE [a=0 b=6 c=0 d=nil]
  if e[78] then goto L_20 end
  goto L_50
  ::L_11::
  -- UNKNOWN op? [a=0 b=123 c=19 d=nil]
  e[27] = {}  -- NEWTABLE [a=0 b=27 c=0 d=nil]
  e[28] = {}  -- NEWTABLE [a=28 b=0 c=0 d=nil]
  e[26] = {}  -- NEWTABLE [a=26 b=0 c=0 d=nil]
  e[28][K(76)] = e[55]  -- SETTABLE [a=28 b=76 c=55 d=98] -- settable/void-call (inferred)
  e[27][K(36)] = e[119]  -- SETTABLE [a=27 b=36 c=119 d=100] -- settable/void-call (inferred)
  e[28][K(36)] = e[8]  -- SETTABLE [a=28 b=36 c=8 d=100] -- settable/void-call (inferred)
  e[26][K(123)] = e[110]  -- SETTABLE [a=26 b=123 c=110 d=102] -- settable/void-call (inferred)
  e[26][K(58)] = e[368]  -- SETTABLE [a=26 b=58 c=368 d=80] -- settable/void-call (inferred)
  ::L_20::
  e[31][K(111)] = e[24]  -- SETTABLE/CALL [a=31 b=111 c=24 d=nil] -- settable/void-call (inferred)
  goto L_21
  e[26] = {}  -- NEWTABLE [a=26 b=0 c=0 d=nil]
  e[28] = {}  -- NEWTABLE [a=28 b=0 c=0 d=nil]
  e[27] = {}  -- NEWTABLE [a=0 b=27 c=0 d=nil]
  e[27][K(13)] = e[122]  -- SETTABLE [a=27 b=13 c=122 d=67] -- settable/void-call (inferred)
  e[28][K(13)] = e[8]  -- SETTABLE [a=28 b=13 c=8 d=67] -- settable/void-call (inferred)
  e[26][K(46)] = e[5]  -- SETTABLE [a=26 b=46 c=5 d=87] -- settable/void-call (inferred)
  call(e[31], e[24])  -- CALL? [a=31 b=0 c=24 d=nil] -- void call
  ::L_29::
  goto L_65
  e[10] = e[3][K(0)]  -- GETTABLE/CLOSURE? [a=3 b=0 c=10 d=nil]
  ::L_31::
  goto L_7
  e[28] = {}  -- NEWTABLE [a=28 b=0 c=0 d=nil]
  e[26] = {}  -- NEWTABLE [a=26 b=0 c=0 d=nil]
  e[27] = {}  -- NEWTABLE [a=0 b=27 c=0 d=nil]
  e[28][K(91)] = e[112]  -- SETTABLE [a=28 b=91 c=112 d=62] -- settable/void-call (inferred)
  e[27][K(91)] = e[23]  -- SETTABLE [a=27 b=91 c=23 d=62] -- settable/void-call (inferred)
  e[27][K(85)] = e[81]  -- SETTABLE [a=27 b=85 c=81 d=60] -- settable/void-call (inferred)
  e[26][K(5)] = e[125]  -- SETTABLE [a=26 b=5 c=125 d=65] -- settable/void-call (inferred)
  e[31][K(69)] = e[24]  -- SETTABLE/CALL [a=31 b=69 c=24 d=nil] -- settable/void-call (inferred)
  ::L_40::
  goto L_43
  ::L_41::
  goto L_44
  if e[20] then goto L_1 end  -- back-edge (loop)
  ::L_43::
  goto L_86
  ::L_44::
  goto L_57
  e[25] = {}  -- NEWTABLE [a=25 b=0 c=0 d=nil]
  e[26] = {}  -- NEWTABLE [a=26 b=0 c=0 d=nil]
  e[25][K(69)] = e[4]  -- SETTABLE [a=25 b=69 c=4 d=54] -- settable/void-call (inferred)
  e[26][K(54)] = e[11]  -- SETTABLE [a=26 b=54 c=11 d=41] -- settable/void-call (inferred)
  e[31][K(111)] = e[24]  -- SETTABLE/CALL [a=31 b=111 c=24 d=nil] -- settable/void-call (inferred)
  ::L_50::
  goto L_95
  e[20] = K(9)  -- LOADK_S [a=0 b=9 c=20 d=nil]
  e[21] = "252202143224130"  -- LOADK [a=21 b=1899 c=0 d=�ʏ��]
  e[22] = 3  -- LOADK [a=22 b=78 c=136 d=3]
  call(e[23], e[0])  -- CALL [a=23 b=0 c=0 d=nil] -- void call
  e[20] = 143  -- LOADK_N [a=0 b=20 c=4 d=nil]
  ::L_57::
  goto L_41
  e[6] = 17  -- LOADK [a=6 b=725 c=0 d=17]
  e[3] = e[4][750480426]  -- GETTABLE/CLOSURE? [a=4 b=0 c=3 d=nil]  -- = 750480426
  e[119] = 14411  -- LOADK [a=119 b=2015 c=0 d=14411]
  e[8] = e[2][K(0)]  -- GETTABLE/CLOSURE? [a=2 b=0 c=8 d=nil]
  -- UNKNOWN op? [a=90 b=0 c=9 d=nil]
  e[10] = e[3][750480426]  -- GETTABLE/CLOSURE? [a=3 b=0 c=10 d=nil]  -- = 750480426
  goto L_64
  ::L_65::
  goto L_31
  e[20] = K(8)  -- LOADK_S [a=0 b=8 c=20 d=nil]
  -- UNKNOWN op? [a=31 b=6 c=0 d=>i8]
  call(e[33], e[204])  -- CALL [a=33 b=217 c=204 d=nil] -- void call
  e[22][K(2172)] = e[215]  -- SETTABLE/CALL [a=22 b=2172 c=215 d=      �] -- settable/void-call (inferred)
  e[80] = K(75)  -- LOADK_S [a=80 b=75 c=242 d=nil]
  e[20] = K(20)  -- LOADK_N [a=0 b=20 c=0 d=nil]
  goto L_72
  e[7] = e[2][K(0)]  -- GETTABLE/CLOSURE? [a=2 b=0 c=7 d=nil]
  e[8] = e[5][750480426]  -- GETTABLE/CLOSURE? [a=5 b=0 c=8 d=nil]  -- = 750480426
  e[9] = e[3][750480426]  -- GETTABLE/CLOSURE? [a=3 b=0 c=9 d=nil]  -- = 750480426
  e[7] = K(7)  -- LOADK_N [a=0 b=7 c=0 d=nil]
  goto L_77
  if e[5] then goto L_7 end  -- back-edge (loop)
  if e[80] then do return end else goto L_80 end
  ::L_80::
  goto L_11
  call(e[7], e[0])  -- CALL [a=7 b=0 c=0 d=nil] -- void call
  e[196][K(178)] = e[8]  -- SETTABLE/CALL [a=196 b=178 c=8 d=nil] -- settable/void-call (inferred)
  call(e[2], e[159])  -- CALL [a=2 b=191 c=159 d=nil] -- void call
  e[150] = K(90)  -- LOADK_S [a=150 b=90 c=5 d=nil]
  e[9] = e[6][K(0)]  -- GETTABLE/CLOSURE? [a=6 b=0 c=9 d=nil]
  ::L_86::
  goto L_29
  e[2] = e[7][false]  -- GETTABLE/CLOSURE? [a=7 b=0 c=2 d=nil]  -- = false
  e[7] = 10652  -- LOADK [a=7 b=2277 c=0 d=10652]
  e[8] = e[2][false]  -- GETTABLE/CLOSURE? [a=2 b=0 c=8 d=nil]  -- = false
  e[9] = e[6][17]  -- GETTABLE/CLOSURE? [a=6 b=0 c=9 d=nil]  -- = 17
  e[10] = e[3][750480426]  -- GETTABLE/CLOSURE? [a=3 b=0 c=10 d=nil]  -- = 750480426
  ::L_93::
  goto L_7
  ::L_95::
  goto L_40
  e[16] = {}  -- NEWTABLE [a=16 b=0 c=0 d=nil]
  e[14] = {}  -- NEWTABLE [a=14 b=0 c=0 d=nil]
  goto L_20
  e[21] = K(13)  -- LOADK_S [a=0 b=13 c=21 d=nil]
  if e[182] then do return end else goto L_101 end
  ::L_101::
  e[21] = 21  -- LOADK_N [a=0 b=0 c=21 d=nil]
  e[61] = (e[21] == e[20])  -- COMPARE [a=21 b=61 c=20 d=nil]  -- = true
  if e[20] then goto L_41 end  -- back-edge (loop)
  goto L_93
end

local function proto70(...)  -- 72 instrs, 21 blocks (structured)
  local e = regs
  ::L_1::
  ::L_55::
  ::L_18::
  -- UNKNOWN op? [a=303 b=393 c=480 d=nil]
  e[25] = {}  -- NEWTABLE [a=0 b=25 c=0 d=nil]
  e[24] = {}  -- NEWTABLE [a=24 b=0 c=0 d=nil]
  e[26] = {}  -- NEWTABLE [a=26 b=0 c=0 d=nil]
  e[25][K(37)] = e[9]  -- SETTABLE [a=25 b=37 c=9 d=33] -- settable/void-call (inferred)
  e[26][K(37)] = e[461]  -- SETTABLE [a=26 b=37 c=461 d=33] -- settable/void-call (inferred)
  e[24][K(105)] = e[32]  -- SETTABLE [a=24 b=105 c=32 d=56] -- settable/void-call (inferred)
  call(e[29], e[22])  -- CALL? [a=29 b=0 c=22 d=nil] -- void call
  goto L_55
  e[14] = {}  -- NEWTABLE [a=0 b=14 c=0 d=nil]
  e[13] = {}  -- NEWTABLE [a=13 b=0 c=0 d=nil]
  e[19] = K(17)  -- LOADK_S [a=0 b=17 c=19 d=nil]
  e[20] = K(21)  -- LOADK_S [a=0 b=21 c=20 d=nil]
  e[21] = 3.141592653589793  -- LOADK_S [a=0 b=6 c=21 d=nil]
  e[152] = 4  -- LOADK_N [a=210 b=0 c=152 d=nil]
  e[128] = 2  -- LOADK_N [a=0 b=248 c=128 d=nil]
  e[20] = K(5)  -- LOADK_S [a=0 b=5 c=20 d=nil]
  e[21] = 3.141592653589793  -- LOADK_S [a=0 b=6 c=21 d=nil]
  e[20] = 3  -- LOADK_N [a=0 b=0 c=20 d=nil]
  e[19] = arith(e[19], e[20])  -- ARITH [a=19 b=19 c=20 d=nil]  -- = 5
  e[19] = e[19] + 20032  -- ADD [a=19 b=1555 c=19 d=20032]  -- = 20037
  e[19] = arith(e[19], e[1881])  -- UNOP/arith? [a=19 b=19 c=1881 d=nil]  -- = 4
  call(e[19], e[51])  -- CALL [a=19 b=14 c=51 d=nil] -- void call
  e[13][K(10)] = e[5]  -- SETTABLE [a=13 b=10 c=5 d=72] -- settable/void-call (inferred)
  call(e[21], e[11])  -- CALL? [a=21 b=0 c=11 d=nil] -- void call
  goto L_18
  e[25] = {}  -- NEWTABLE [a=0 b=25 c=0 d=nil]
  e[24] = {}  -- NEWTABLE [a=24 b=0 c=0 d=nil]
  e[23] = {}  -- NEWTABLE [a=23 b=0 c=0 d=nil]
  e[25][K(81)] = e[4]  -- SETTABLE [a=25 b=81 c=4 d=7] -- settable/void-call (inferred)
  e[23][K(81)] = e[110]  -- SETTABLE [a=23 b=81 c=110 d=7] -- settable/void-call (inferred)
  e[24][K(84)] = e[4]  -- SETTABLE [a=24 b=84 c=4 d=8] -- settable/void-call (inferred)
  e[23][K(84)] = e[117]  -- SETTABLE [a=23 b=84 c=117 d=8] -- settable/void-call (inferred)
  e[24][K(32)] = e[16]  -- SETTABLE [a=24 b=32 c=16 d=29] -- settable/void-call (inferred)
  call(e[29], e[22])  -- CALL? [a=29 b=0 c=22 d=nil] -- void call
  ::L_28::
  goto L_1
  e[0] = {}  -- NEWTABLE [a=0 b=2 c=0 d=nil]
  e[97][K(0)] = e[3]  -- SETTABLE/CALL [a=97 b=0 c=3 d=nil] -- settable/void-call (inferred)
  e[5] = e[0][K(5)]  -- GETTABLE/CLOSURE [a=0 b=5 c=0 d=nil]
  e[5] = e[5]  -- MOVE [a=5 b=5 c=522 d=nil]
  e[7] = e[2][750480426]  -- GETTABLE/CLOSURE? [a=2 b=0 c=7 d=nil]  -- = 750480426
  e[8] = e[1][750480426]  -- GETTABLE/CLOSURE? [a=1 b=0 c=8 d=nil]  -- = 750480426
  ::L_38::
  goto L_71
  e[4] = e[5][false]  -- GETTABLE/CLOSURE? [a=5 b=0 c=4 d=nil]  -- = false
  e[3] = e[6][false]  -- GETTABLE/CLOSURE? [a=6 b=0 c=3 d=nil]  -- = false
  e[5] = e[3][false]  -- GETTABLE/CLOSURE? [a=3 b=0 c=5 d=nil]  -- = false
  ::L_42::
  do return end  -- JMP/RETURN [a=0 b=0 c=5 d=nil]
  e[5] = e[5]  -- MOVE [a=5 b=5 c=1611 d=nil]
  e[7] = e[229][true]  -- GETTABLE/CLOSURE? [a=229 b=0 c=7 d=nil]  -- = true
  -- UNKNOWN op? [a=5 b=172 c=3 d=nil]
  goto L_38
  e[26] = {}  -- NEWTABLE [a=26 b=0 c=0 d=nil]
  e[24] = {}  -- NEWTABLE [a=24 b=0 c=0 d=nil]
  e[25] = {}  -- NEWTABLE [a=0 b=25 c=0 d=nil]
  e[25][K(13)] = e[16]  -- SETTABLE [a=25 b=13 c=16 d=67] -- settable/void-call (inferred)
  e[24][K(116)] = e[111]  -- SETTABLE [a=24 b=116 c=111 d=45] -- settable/void-call (inferred)
  e[26][K(116)] = e[979]  -- SETTABLE [a=26 b=116 c=979 d=45] -- settable/void-call (inferred)
  e[24][K(127)] = e[5]  -- SETTABLE [a=24 b=127 c=5 d=31] -- settable/void-call (inferred)
  call(e[29], e[22])  -- CALL? [a=29 b=0 c=22 d=nil] -- void call
  ::L_65::
  goto L_65
  e[9] = e[4][K(0)]  -- GETTABLE/CLOSURE? [a=4 b=0 c=9 d=nil]
  e[10] = e[1][K(10)]  -- GETTABLE/CLOSURE [a=1 b=10 c=0 d=nil]
  e[5] = K(5)  -- LOADK_N [a=0 b=5 c=6 d=nil]
  e[4] = e[5][true]  -- GETTABLE/CLOSURE? [a=5 b=0 c=4 d=nil]  -- = true
  e[5] = e[0][K(5)]  -- GETTABLE/CLOSURE [a=0 b=5 c=0 d=nil]
  ::L_71::
  goto L_42
  goto L_28
end

local function proto71(...)  -- 14 instrs, 7 blocks (structured)
  local e = regs
  ::L_1::
  -- UNKNOWN op? [a=126 b=367 c=356 d=nil]
  ::L_12::
  ::L_6::
  goto L_12
  e[7] = e[3][750480426]  -- GETTABLE/CLOSURE? [a=3 b=0 c=7 d=nil]  -- = 750480426
  e[8] = e[2][750480426]  -- GETTABLE/CLOSURE? [a=2 b=0 c=8 d=nil]  -- = 750480426
  e[6] = K(6)  -- LOADK_N [a=0 b=6 c=0 d=nil]
  e[4] = e[6][true]  -- GETTABLE/CLOSURE? [a=6 b=0 c=4 d=nil]  -- = true
  goto L_6
  e[0] = {}  -- NEWTABLE [a=0 b=5 c=0 d=nil]
  e[4] = e[4][K(5)]  -- GETTABLE [a=4 b=5 c=1954 d=nil]
  e[6] = e[4][K(0)]  -- GETTABLE/CLOSURE? [a=4 b=0 c=6 d=nil]
  goto L_1
  e[6] = e[4][true]  -- GETTABLE/CLOSURE? [a=4 b=0 c=6 d=nil]  -- = true
  do return end  -- JMP/RETURN [a=0 b=0 c=6 d=nil]
end

local function proto72(...)  -- 168 instrs, 76 blocks (structured)
  local e = regs
  ::L_1::
  ::L_123::
  ::L_98::
  ::L_46::
  ::L_136::
  ::L_13::
  ::L_29::
  ::L_61::
  ::L_132::
  ::L_118::
  do return end  -- JMP/RETURN [a=0 b=0 c=10 d=nil]
  e[17] = e[9][K(0)]  -- GETTABLE/CLOSURE? [a=9 b=0 c=17 d=nil]
  e[18] = e[5][K(0)]  -- GETTABLE/CLOSURE? [a=5 b=0 c=18 d=nil]
  e[19] = e[1][750480426]  -- GETTABLE/CLOSURE? [a=1 b=0 c=19 d=nil]  -- = 750480426
  if e[10] then goto L_10 end
  ::L_6::
  goto L_147
  ::L_7::
  goto L_53
  ::L_8::
  e[28] = e[28] + 10560  -- ADD [a=28 b=367 c=28 d=10560]  -- = 10739
  e[28] = arith(e[28], e[2313])  -- UNOP/arith? [a=28 b=28 c=2313 d=nil]  -- = 6
  ::L_10::
  call(e[28], e[435])  -- CALL [a=28 b=23 c=435 d=nil] -- void call
  e[22][K(2361)] = e[32]  -- SETTABLE [a=22 b=2361 c=32 d=119] -- settable/void-call (inferred)
  call(e[29], e[20])  -- CALL? [a=29 b=0 c=20 d=nil] -- void call
  goto L_13
  ::L_14::
  goto L_124
  e[22] = {}  -- NEWTABLE [a=22 b=0 c=0 d=nil]
  e[23] = {}  -- NEWTABLE [a=0 b=23 c=0 d=nil]
  e[28] = 77  -- LOADK_N [a=990 b=28 c=440 d=nil]
  e[28] = (e[889] == e[96])  -- COMPARE [a=889 b=28 c=96 d=nil]  -- = true
  if e[28] then goto L_130 end
  ::L_20::
  goto L_158
  ::L_21::
  goto L_81
  e[10] = e[4][K(0)]  -- GETTABLE/CLOSURE? [a=4 b=0 c=10 d=nil]
  ::L_23::
  do return end  -- JMP/RETURN [a=0 b=0 c=10 d=nil]
  ::L_24::
  goto L_69
  e[10] = e[0][K(10)]  -- GETTABLE/CLOSURE [a=0 b=10 c=0 d=nil]
  e[10] = e[10]  -- MOVE [a=10 b=10 c=266 d=nil]
  e[12] = e[6][750480426]  -- GETTABLE/CLOSURE? [a=6 b=0 c=12 d=nil]  -- = 750480426
  e[13] = e[7][true]  -- GETTABLE/CLOSURE? [a=7 b=0 c=13 d=nil]  -- = true
  goto L_29
  e[13] = e[9][93]  -- GETTABLE/CLOSURE? [a=9 b=0 c=13 d=nil]  -- = 93
  e[14] = e[7][true]  -- GETTABLE/CLOSURE? [a=7 b=0 c=14 d=nil]  -- = true
  e[15] = e[8][false]  -- GETTABLE/CLOSURE? [a=8 b=0 c=15 d=nil]  -- = false
  e[16] = e[6][750480426]  -- GETTABLE/CLOSURE? [a=6 b=0 c=16 d=nil]  -- = 750480426
  ::L_35::
  goto L_20
  e[13] = e[1][K(13)]  -- GETTABLE/CLOSURE [a=1 b=13 c=221 d=nil]
  e[14] = e[7][K(0)]  -- GETTABLE/CLOSURE? [a=7 b=0 c=14 d=nil]
  e[15] = e[8][K(0)]  -- GETTABLE/CLOSURE? [a=8 b=0 c=15 d=nil]
  e[16] = e[2][750480426]  -- GETTABLE/CLOSURE? [a=2 b=0 c=16 d=nil]  -- = 750480426
  ::L_40::
  goto L_48
  ::L_41::
  goto L_24
  e[8] = e[14][K(0)]  -- GETTABLE/CLOSURE? [a=14 b=0 c=8 d=nil]
  e[6] = e[15][750480426]  -- GETTABLE/CLOSURE? [a=15 b=0 c=6 d=nil]  -- = 750480426
  e[4] = e[16][K(0)]  -- GETTABLE/CLOSURE? [a=16 b=0 c=4 d=nil]
  if e[6] then do return end else goto L_46 end
  e[9] = 64  -- LOADK [a=9 b=1837 c=0 d=64]
  ::L_48::
  goto L_24
  ::L_50::
  goto L_21
  e[28] = K(353)  -- LOADK [a=28 b=353 c=0 d=264]
  ::L_53::
  goto L_7
  e[32] = {}  -- NEWTABLE [a=32 b=0 c=0 d=nil]
  e[33] = {}  -- NEWTABLE [a=0 b=33 c=0 d=nil]
  e[31] = {}  -- NEWTABLE [a=31 b=0 c=0 d=nil]
  e[31][K(28)] = e[4]  -- SETTABLE [a=31 b=28 c=4 d=78] -- settable/void-call (inferred)
  e[33][K(28)] = e[16]  -- SETTABLE [a=33 b=28 c=16 d=78] -- settable/void-call (inferred)
  e[32][K(81)] = e[674]  -- SETTABLE [a=32 b=81 c=674 d=7] -- settable/void-call (inferred)
  call(e[37], e[30])  -- CALL? [a=37 b=0 c=30 d=nil] -- void call
  goto L_61
  e[1][750480426] = e[14]  -- SETTABLE [a=1 b=0 c=14 d=nil] -- settable/void-call (inferred)
  e[15] = e[2][750480426]  -- GETTABLE/CLOSURE? [a=2 b=0 c=15 d=nil]  -- = 750480426
  e[16] = e[8][true]  -- GETTABLE/CLOSURE? [a=8 b=0 c=16 d=nil]  -- = true
  e[17] = e[9][116]  -- GETTABLE/CLOSURE? [a=9 b=0 c=17 d=nil]  -- = 116
  e[18] = e[1][K(18)]  -- GETTABLE/CLOSURE [a=1 b=18 c=0 d=nil]
  e[19] = e[5][true]  -- GETTABLE/CLOSURE? [a=5 b=0 c=19 d=nil]  -- = true
  ::L_68::
  goto L_99
  ::L_69::
  goto L_6
  e[32] = {}  -- NEWTABLE [a=32 b=0 c=0 d=nil]
  e[31] = {}  -- NEWTABLE [a=31 b=0 c=0 d=nil]
  e[31][K(106)] = e[4]  -- SETTABLE [a=31 b=106 c=4 d=36] -- settable/void-call (inferred)
  e[32][K(124)] = e[60]  -- SETTABLE [a=32 b=124 c=60 d=24] -- settable/void-call (inferred)
  call(e[37], e[30])  -- CALL? [a=37 b=0 c=30 d=nil] -- void call
  goto L_35
  if e[24] then do return end else goto L_77 end
  ::L_77::
  goto L_40
  e[17] = e[92][K(17)]  -- GETTABLE/CLOSURE [a=92 b=17 c=83 d=nil]
  if e[10] then goto L_8 end  -- back-edge (loop)
  e[3] = e[10][34133]  -- GETTABLE/CLOSURE? [a=10 b=0 c=3 d=nil]  -- = 34133
  ::L_81::
  goto L_154
  e[32] = {}  -- NEWTABLE [a=32 b=0 c=0 d=nil]
  e[34] = {}  -- NEWTABLE [a=34 b=0 c=0 d=nil]
  e[33] = {}  -- NEWTABLE [a=0 b=33 c=0 d=nil]
  e[31] = {}  -- NEWTABLE [a=31 b=0 c=0 d=nil]
  e[32][K(2229)] = e[4]  -- SETTABLE [a=32 b=2229 c=4 d=155] -- settable/void-call (inferred)
  e[34][K(2229)] = e[112]  -- SETTABLE [a=34 b=2229 c=112 d=155] -- settable/void-call (inferred)
  e[31][K(2229)] = e[84]  -- SETTABLE [a=31 b=2229 c=84 d=155] -- settable/void-call (inferred)
  e[33][K(2229)] = e[103]  -- SETTABLE [a=33 b=2229 c=103 d=155] -- settable/void-call (inferred)
  e[32][K(122)] = e[57]  -- SETTABLE [a=32 b=122 c=57 d=21] -- settable/void-call (inferred)
  call(e[37], e[30])  -- CALL? [a=37 b=0 c=30 d=nil] -- void call
  ::L_92::
  goto L_77
  e[34] = {}  -- NEWTABLE [a=34 b=0 c=0 d=nil]
  e[32] = {}  -- NEWTABLE [a=32 b=0 c=0 d=nil]
  e[34][K(91)] = e[112]  -- SETTABLE [a=34 b=91 c=112 d=62] -- settable/void-call (inferred)
  e[32][K(973)] = e[30]  -- SETTABLE [a=32 b=973 c=30 d=130] -- settable/void-call (inferred)
  call(e[37], e[30])  -- CALL? [a=37 b=0 c=30 d=nil] -- void call
  goto L_98
  ::L_99::
  goto L_129
  if e[10] then goto L_10 end  -- back-edge (loop)
  e[8] = e[10][true]  -- GETTABLE/CLOSURE? [a=10 b=0 c=8 d=nil]  -- = true
  e[9] = e[11][116]  -- GETTABLE/CLOSURE? [a=11 b=0 c=9 d=nil]  -- = 116
  e[6] = e[12][750480426]  -- GETTABLE/CLOSURE? [a=12 b=0 c=6 d=nil]  -- = 750480426
  e[3] = e[13][48092]  -- GETTABLE/CLOSURE? [a=13 b=0 c=3 d=nil]  -- = 48092
  e[7] = e[14][true]  -- GETTABLE/CLOSURE? [a=14 b=0 c=7 d=nil]  -- = true
  e[5] = e[15][true]  -- GETTABLE/CLOSURE? [a=15 b=0 c=5 d=nil]  -- = true
  if e[75] then do return end else goto L_108 end
  ::L_108::
  goto L_50
  e[0] = {}  -- NEWTABLE [a=0 b=2 c=0 d=nil]
  call(e[9], e[3])  -- CALL? [a=9 b=0 c=3 d=nil] -- void call
  e[10] = e[0][K(10)]  -- GETTABLE/CLOSURE [a=0 b=10 c=0 d=nil]
  e[10] = e[10]  -- MOVE [a=10 b=10 c=1776 d=nil]
  e[12] = e[6][K(0)]  -- GETTABLE/CLOSURE? [a=6 b=0 c=12 d=nil]
  ::L_114::
  goto L_23
  e[23][K(7)] = e[5]  -- SETTABLE/CALL [a=23 b=7 c=5 d=nil] -- settable/void-call (inferred)
  e[5] = e[8][true]  -- GETTABLE/CLOSURE? [a=8 b=101 c=5 d=nil]  -- = true
  e[10] = e[5][true]  -- GETTABLE/CLOSURE? [a=5 b=0 c=10 d=nil]  -- = true
  goto L_118
  -- UNKNOWN op? [a=28 b=846 c=19 d=179]
  ::L_121::
  goto L_130
  if e[152] then do return end else goto L_123 end
  ::L_124::
  goto L_108
  e[32] = {}  -- NEWTABLE [a=32 b=0 c=0 d=nil]
  e[32][K(1509)] = e[4]  -- SETTABLE [a=32 b=1509 c=4 d=116] -- settable/void-call (inferred)
  e[32][K(100)] = e[1875]  -- SETTABLE [a=32 b=100 c=1875 d=14] -- settable/void-call (inferred)
  call(e[37], e[30])  -- CALL? [a=37 b=0 c=30 d=nil] -- void call
  ::L_129::
  goto L_114
  ::L_130::
  goto L_92
  if e[28] then goto L_7 else goto L_132 end  -- back-edge (loop)
  e[10] = e[0][K(10)]  -- GETTABLE/CLOSURE [a=0 b=10 c=0 d=nil]
  e[10] = e[10]  -- MOVE [a=10 b=10 c=2170 d=nil]
  e[12] = e[5][K(0)]  -- GETTABLE/CLOSURE? [a=5 b=0 c=12 d=nil]
  goto L_136
  e[34] = {}  -- NEWTABLE [a=34 b=0 c=0 d=nil]
  e[33] = {}  -- NEWTABLE [a=0 b=33 c=0 d=nil]
  e[32] = {}  -- NEWTABLE [a=32 b=0 c=0 d=nil]
  e[32][K(2238)] = e[4]  -- SETTABLE [a=32 b=2238 c=4 d=148] -- settable/void-call (inferred)
  e[33][K(2238)] = e[42]  -- SETTABLE [a=33 b=2238 c=42 d=148] -- settable/void-call (inferred)
  e[34][K(2238)] = e[112]  -- SETTABLE [a=34 b=2238 c=112 d=148] -- settable/void-call (inferred)
  e[32][K(71)] = e[16]  -- SETTABLE [a=32 b=71 c=16 d=49] -- settable/void-call (inferred)
  call(e[37], e[30])  -- CALL? [a=37 b=0 c=30 d=nil] -- void call
  goto L_1
  ::L_147::
  -- UNKNOWN op? [a=423 b=443 c=153 d=nil]
  -- UNKNOWN op? [a=119 b=91 c=3 d=nil]
  e[5] = e[11][K(0)]  -- GETTABLE/CLOSURE? [a=11 b=0 c=5 d=nil]
  e[7] = e[12][true]  -- GETTABLE/CLOSURE? [a=12 b=0 c=7 d=nil]  -- = true
  e[9] = e[13][118]  -- GETTABLE/CLOSURE? [a=13 b=0 c=9 d=nil]  -- = 118
  goto L_41
  if e[6] then do return end else goto L_154 end
  ::L_154::
  goto L_68
  -- UNKNOWN op? [a=176 b=221 c=208 d=nil]
  e[5] = e[12][K(0)]  -- GETTABLE/CLOSURE? [a=12 b=0 c=5 d=nil]
  e[9] = e[13][93]  -- GETTABLE/CLOSURE? [a=13 b=0 c=9 d=nil]  -- = 93
  ::L_158::
  goto L_121
  e[32] = {}  -- NEWTABLE [a=32 b=0 c=0 d=nil]
  e[31] = {}  -- NEWTABLE [a=31 b=0 c=0 d=nil]
  e[34] = {}  -- NEWTABLE [a=34 b=0 c=0 d=nil]
  e[34][K(15)] = e[8]  -- SETTABLE [a=34 b=15 c=8 d=120] -- settable/void-call (inferred)
  e[31][K(15)] = e[4]  -- SETTABLE [a=31 b=15 c=4 d=120] -- settable/void-call (inferred)
  e[31][K(114)] = e[115]  -- SETTABLE [a=31 b=114 c=115 d=18] -- settable/void-call (inferred)
  e[32][K(770)] = e[100]  -- SETTABLE [a=32 b=770 c=100 d=137] -- settable/void-call (inferred)
  call(e[37], e[30])  -- CALL? [a=37 b=0 c=30 d=nil] -- void call
  goto L_14
end

local function proto73(...)  -- 249 instrs, 125 blocks (structured)
  local e = regs
  ::L_1::
  ::L_138::
  ::L_180::
  ::L_152::
  ::L_76::
  ::L_93::
  ::L_7::
  ::L_247::
  ::L_11::
  ::L_162::
  ::L_16::
  -- UNKNOWN op? [a=2 b=1 c=18 d=nil]
  e[4] = e[0][K(0)]  -- GETTABLE/CLOSURE? [a=0 b=0 c=4 d=nil]
  e[12] = 86  -- LOADK [a=12 b=2186 c=0 d=86]
  e[13] = 183  -- LOADK [a=13 b=1750 c=0 d=183]
  ::L_53::
  ::L_217::
  goto L_152
  e[39] = {}  -- NEWTABLE [a=39 b=0 c=0 d=nil]
  ::L_3::
  e[40] = {}  -- NEWTABLE [a=0 b=40 c=0 d=nil]
  e[40][K(1233)] = e[122]  -- SETTABLE [a=40 b=1233 c=122 d=111] -- settable/void-call (inferred)
  e[39][K(2)] = e[402]  -- SETTABLE [a=39 b=2 c=402 d=84] -- settable/void-call (inferred)
  ::L_6::
  e[44][K(217)] = e[37]  -- SETTABLE/CALL [a=44 b=217 c=37 d=nil] -- settable/void-call (inferred)
  goto L_7
  e[2] = e[16][K(0)]  -- GETTABLE/CLOSURE? [a=16 b=0 c=2 d=nil]
  e[8] = e[17][K(0)]  -- GETTABLE/CLOSURE? [a=17 b=0 c=8 d=nil]
  if e[8] then goto L_142 else goto L_11 end
  ::L_12::
  e[13] = e[8][K(0)]  -- GETTABLE/CLOSURE? [a=8 b=0 c=13 d=nil]
  e[181] = e[4][true]  -- GETTABLE/CLOSURE? [a=4 b=0 c=181 d=nil]  -- = true
  e[15] = e[7][118]  -- GETTABLE/CLOSURE? [a=7 b=0 c=15 d=nil]  -- = 118
  ::L_15::
  goto L_203
  ::L_21::
  goto L_41
  e[39] = {}  -- NEWTABLE [a=39 b=0 c=0 d=nil]
  e[38] = {}  -- NEWTABLE [a=38 b=0 c=0 d=nil]
  e[38][K(1333)] = e[114]  -- SETTABLE [a=38 b=1333 c=114 d=123] -- settable/void-call (inferred)
  e[39][K(53)] = e[1602]  -- SETTABLE [a=39 b=53 c=1602 d=50] -- settable/void-call (inferred)
  call(e[44], e[37])  -- CALL? [a=44 b=0 c=37 d=nil] -- void call
  ::L_27::
  goto L_190
  e[39] = {}  -- NEWTABLE [a=39 b=0 c=0 d=nil]
  e[40] = {}  -- NEWTABLE [a=0 b=40 c=0 d=nil]
  e[40][K(21)] = e[111]  -- SETTABLE [a=40 b=21 c=111 d=90] -- settable/void-call (inferred)
  e[39][K(1793)] = e[979]  -- SETTABLE [a=39 b=1793 c=979 d=165] -- settable/void-call (inferred)
  e[44][K(13)] = e[37]  -- SETTABLE/CALL [a=44 b=13 c=37 d=nil] -- settable/void-call (inferred)
  ::L_33::
  goto L_121
  e[0][K(0)] = e[0]  -- SETTABLE/CALL [a=0 b=0 c=0 d=nil] -- settable/void-call (inferred)
  call(e[5], e[181])  -- CALL [a=5 b=149 c=181 d=nil] -- void call
  e[201][K(1)] = e[9]  -- SETTABLE/CALL [a=201 b=1 c=9 d=nil] -- settable/void-call (inferred)
  e[1][K(154)] = e[18]  -- SETTABLE/CALL [a=1 b=154 c=18 d=nil] -- settable/void-call (inferred)
  e[123] = K(84)  -- LOADK_S [a=123 b=84 c=240 d=nil]
  e[7] = 118  -- LOADK [a=7 b=360 c=0 d=118]
  call(e[12], e[0])  -- CALL [a=12 b=0 c=0 d=nil] -- void call
  ::L_41::
  goto L_115
  e[39] = {}  -- NEWTABLE [a=39 b=0 c=0 d=nil]
  e[40] = {}  -- NEWTABLE [a=0 b=40 c=0 d=nil]
  e[41] = {}  -- NEWTABLE [a=41 b=0 c=0 d=nil]
  e[40][K(823)] = e[84]  -- SETTABLE [a=40 b=823 c=84 d=193] -- settable/void-call (inferred)
  e[41][K(823)] = e[112]  -- SETTABLE [a=41 b=823 c=112 d=193] -- settable/void-call (inferred)
  e[39][K(122)] = e[973]  -- SETTABLE [a=39 b=122 c=973 d=21] -- settable/void-call (inferred)
  e[44][K(83)] = e[37]  -- SETTABLE/CALL [a=44 b=83 c=37 d=nil] -- settable/void-call (inferred)
  ::L_49::
  goto L_130
  ::L_50::
  goto L_21
  ::L_51::
  goto L_151
  if e[83] then goto L_49 else goto L_53 end  -- back-edge (loop)
  e[26] = {}  -- NEWTABLE [a=26 b=0 c=0 d=nil]
  e[28] = {}  -- NEWTABLE [a=28 b=0 c=0 d=nil]
  e[32] = K(7)  -- LOADK_S [a=0 b=7 c=32 d=nil]
  e[33] = K(13)  -- LOADK_S [a=0 b=13 c=33 d=nil]
  e[34] = K(1013)  -- LOADK [a=34 b=1013 c=0]
  e[33] = K(0)  -- LOADK_N [a=0 b=0 c=33 d=nil]
  e[34] = K(8)  -- LOADK_S [a=0 b=8 c=34 d=nil]
  e[35] = K(6)  -- LOADK [a=35 b=6 c=0 d=>i8]
  e[36] = K(1132)  -- LOADK [a=36 b=1132 c=0 d=      []
  e[34] = K(34)  -- LOADK_N [a=0 b=34 c=0 d=nil]
  e[33] = arith(e[33], e[33])  -- ARITH [a=34 b=33 c=33 d=nil]
  dataop(e[34], e[90], e[110])  -- DATAOP [a=34 b=90 c=110 d=23]
  e[32] = K(32)  -- LOADK_N [a=0 b=32 c=0 d=nil]
  e[32] = e[32] + -1434437039  -- ADD [a=32 b=1274 c=32 d=-1434437039]
  e[32] = arith(e[32], e[169])  -- UNOP/arith? [a=32 b=32 c=169 d=nil]
  call(e[32], e[2350])  -- CALL [a=32 b=28 c=2350 d=nil] -- void call
  e[26][K(1778)] = e[1248]  -- SETTABLE [a=26 b=1778 c=1248 d=188] -- settable/void-call (inferred)
  call(e[36], e[24])  -- CALL? [a=36 b=0 c=24 d=nil] -- void call
  ::L_72::
  goto L_235
  e[2] = e[16][750480426]  -- GETTABLE/CLOSURE? [a=16 b=0 c=2 d=nil]  -- = 750480426
  goto L_151
  if e[20] then do return end else goto L_76 end
  e[39] = {}  -- NEWTABLE [a=39 b=0 c=0 d=nil]
  e[38] = {}  -- NEWTABLE [a=38 b=0 c=0 d=nil]
  e[38][K(118)] = e[100]  -- SETTABLE [a=38 b=118 c=100 d=13] -- settable/void-call (inferred)
  e[39][K(1538)] = e[37]  -- SETTABLE [a=39 b=1538 c=37 d=152] -- settable/void-call (inferred)
  call(e[44], e[37])  -- CALL? [a=44 b=0 c=37 d=nil] -- void call
  ::L_82::
  goto L_33
  goto L_164
  ::L_84::
  goto L_1
  ::L_85::
  goto L_197
  e[8] = e[8][K(54)]  -- GETTABLE [a=8 b=54 c=1935 d=nil]
  e[16] = K(445)  -- LOADK [a=16 b=445 c=0 d=-2]
  e[17] = e[8][K(0)]  -- GETTABLE/CLOSURE? [a=8 b=0 c=17 d=nil]
  ::L_89::
  goto L_97
  e[20] = e[102][K(0)]  -- GETTABLE/CLOSURE? [a=102 b=0 c=20 d=nil]
  e[21] = e[2][K(0)]  -- GETTABLE/CLOSURE? [a=2 b=0 c=21 d=nil]
  if e[16] then goto L_6 else goto L_93 end  -- back-edge (loop)
  e[2] = e[9][750480426]  -- GETTABLE/CLOSURE? [a=9 b=0 c=2 d=nil]  -- = 750480426
  ::L_95::
  goto L_152
  ::L_96::
  goto L_85
  ::L_97::
  goto L_125
  e[18] = e[4][K(0)]  -- GETTABLE/CLOSURE? [a=4 b=0 c=18 d=nil]
  e[19] = e[7][K(0)]  -- GETTABLE/CLOSURE? [a=7 b=0 c=19 d=nil]
  e[20] = e[5][K(0)]  -- GETTABLE/CLOSURE? [a=5 b=0 c=20 d=nil]
  e[21] = e[2][K(0)]  -- GETTABLE/CLOSURE? [a=2 b=0 c=21 d=nil]
  ::L_102::
  goto L_116
  e[40] = {}  -- NEWTABLE [a=0 b=40 c=0 d=nil]
  e[39] = {}  -- NEWTABLE [a=39 b=0 c=0 d=nil]
  e[40][K(44)] = e[4]  -- SETTABLE [a=40 b=44 c=4 d=83] -- settable/void-call (inferred)
  e[39][K(1514)] = e[7]  -- SETTABLE [a=39 b=1514 c=7 d=241] -- settable/void-call (inferred)
  e[44][K(94)] = e[37]  -- SETTABLE/CALL [a=44 b=94 c=37 d=nil] -- settable/void-call (inferred)
  ::L_108::
  goto L_82
  if e[229] then do return end else goto L_110 end
  ::L_110::
  goto L_186
  e[1] = e[249]  -- MOVE [a=249 b=1 c=1852 d=nil]
  e[23] = e[16][K(0)]  -- GETTABLE/CLOSURE? [a=16 b=0 c=23 d=nil]
  e[21] = K(21)  -- LOADK_N [a=0 b=21 c=0 d=nil]
  e[16] = e[21][K(0)]  -- GETTABLE/CLOSURE? [a=21 b=0 c=16 d=nil]
  ::L_115::
  goto L_215
  ::L_116::
  goto L_241
  e[22] = e[8][K(0)]  -- GETTABLE/CLOSURE? [a=8 b=0 c=22 d=nil]
  ::L_118::
  goto L_16
  e[11] = e[18][K(0)]  -- GETTABLE/CLOSURE? [a=18 b=0 c=11 d=nil]
  if e[152] then do return end else goto L_121 end
  ::L_121::
  goto L_165
  e[1] = e[16]  -- MOVE [a=16 b=1 c=2185 d=nil]
  e[142] = e[8][K(0)]  -- GETTABLE/CLOSURE? [a=8 b=0 c=142 d=nil]
  e[19] = e[6][K(0)]  -- GETTABLE/CLOSURE? [a=6 b=0 c=19 d=nil]
  ::L_125::
  goto L_89
  e[39] = {}  -- NEWTABLE [a=39 b=0 c=0 d=nil]
  e[39][K(1921)] = e[16]  -- SETTABLE [a=39 b=1921 c=16 d=237] -- settable/void-call (inferred)
  e[39][K(1901)] = e[722]  -- SETTABLE [a=39 b=1901 c=722 d=97] -- settable/void-call (inferred)
  e[44][K(239)] = e[37]  -- SETTABLE/CALL [a=44 b=239 c=37 d=nil] -- settable/void-call (inferred)
  ::L_130::
  goto L_108
  if e[152] then do return end else goto L_132 end
  ::L_132::
  goto L_144
  e[39] = {}  -- NEWTABLE [a=39 b=0 c=0 d=nil]
  e[40] = {}  -- NEWTABLE [a=0 b=40 c=0 d=nil]
  e[40][K(1779)] = e[117]  -- SETTABLE [a=40 b=1779 c=117 d=171] -- settable/void-call (inferred)
  e[39][K(1687)] = e[1248]  -- SETTABLE [a=39 b=1687 c=1248 d=236] -- settable/void-call (inferred)
  e[44][K(103)] = e[37]  -- SETTABLE/CALL [a=44 b=103 c=37 d=nil] -- settable/void-call (inferred)
  goto L_138
  e[0] = {}  -- NEWTABLE [a=0 b=9 c=0 d=nil]
  call(e[11], e[10])  -- CALL? [a=11 b=0 c=10 d=nil] -- void call
  e[8] = e[8][K(3)]  -- GETTABLE [a=8 b=3 c=2367 d=nil]
  ::L_142::
  goto L_84
  ::L_143::
  goto L_206
  ::L_144::
  goto L_240
  ::L_145::
  goto L_192
  e[1] = e[16]  -- MOVE [a=16 b=1 c=2122 d=nil]
  -- UNKNOWN op? [a=8 b=41 c=232 d=nil]
  if e[16] then goto L_3 end  -- back-edge (loop)
  e[10] = e[16][K(0)]  -- GETTABLE/CLOSURE? [a=16 b=0 c=10 d=nil]
  e[8] = e[17][K(0)]  -- GETTABLE/CLOSURE? [a=17 b=0 c=8 d=nil]
  ::L_151::
  goto L_118
  if e[0] then goto L_96 end  -- back-edge (loop)
  ::L_154::
  goto L_50
  e[16] = K(445)  -- LOADK [a=16 b=445 c=0 d=-2]
  e[17] = e[8][K(0)]  -- GETTABLE/CLOSURE? [a=8 b=0 c=17 d=nil]
  e[18] = e[4][K(0)]  -- GETTABLE/CLOSURE? [a=4 b=0 c=18 d=nil]
  e[19] = e[7][K(0)]  -- GETTABLE/CLOSURE? [a=7 b=0 c=19 d=nil]
  e[20] = e[5][K(0)]  -- GETTABLE/CLOSURE? [a=5 b=0 c=20 d=nil]
  e[21] = e[2][K(0)]  -- GETTABLE/CLOSURE? [a=2 b=0 c=21 d=nil]
  e[22] = e[11][K(0)]  -- GETTABLE/CLOSURE? [a=11 b=0 c=22 d=nil]
  goto L_162
  ::L_164::
  goto L_166
  ::L_165::
  goto L_27
  ::L_166::
  goto L_154
  e[2] = e[9][K(0)]  -- GETTABLE/CLOSURE? [a=9 b=0 c=2 d=nil]
  e[16] = e[16][K(1)]  -- GETTABLE [a=16 b=1 c=18 d=nil]
  -- UNKNOWN op? [a=17 b=2142 c=0 d=99]
  e[18] = K(49)  -- LOADK [a=18 b=49 c=0 d=103]
  e[202] = K(70)  -- LOADK [a=202 b=70 c=0 d=4]
  ::L_172::
  goto L_228
  e[1] = e[16]  -- MOVE [a=16 b=1 c=1669 d=nil]
  e[18] = e[9][750480426]  -- GETTABLE/CLOSURE? [a=9 b=0 c=18 d=nil]  -- = 750480426
  e[19] = e[2][750480426]  -- GETTABLE/CLOSURE? [a=2 b=0 c=19 d=nil]  -- = 750480426
  e[16] = K(16)  -- LOADK_N [a=0 b=16 c=4 d=nil]
  ::L_177::
  goto L_72
  e[0][K(0)] = e[0]  -- SETTABLE/CALL [a=0 b=0 c=0 d=nil] -- settable/void-call (inferred)
  goto L_180
  e[39] = {}  -- NEWTABLE [a=39 b=0 c=0 d=nil]
  e[39][K(1568)] = e[16]  -- SETTABLE [a=39 b=1568 c=16 d=86] -- settable/void-call (inferred)
  e[39][K(1248)] = e[11]  -- SETTABLE [a=39 b=1248 c=11 d=163] -- settable/void-call (inferred)
  call(e[44], e[37])  -- CALL? [a=44 b=0 c=37 d=nil] -- void call
  ::L_185::
  goto L_95
  ::L_186::
  goto L_219
  ::L_187::
  goto L_236
  e[14] = 8  -- LOADK [a=14 b=1805 c=0 d=8]
  ::L_190::
  if e[12] then goto L_152 end  -- back-edge (loop)
  if e[8] then goto L_177 end  -- back-edge (loop)
  ::L_192::
  goto L_143
  -- UNKNOWN op? [a=111 b=0 c=16 d=nil]
  e[17] = e[2][750480426]  -- GETTABLE/CLOSURE? [a=2 b=0 c=17 d=nil]  -- = 750480426
  e[16] = K(0)  -- LOADK_N [a=0 b=0 c=16 d=nil]
  e[8] = e[16][false]  -- GETTABLE/CLOSURE? [a=16 b=0 c=8 d=nil]  -- = false
  ::L_197::
  goto L_231
  e[41] = {}  -- NEWTABLE [a=41 b=0 c=0 d=nil]
  e[39] = {}  -- NEWTABLE [a=39 b=0 c=0 d=nil]
  e[41][K(108)] = e[41]  -- SETTABLE [a=41 b=108 c=41 d=16] -- settable/void-call (inferred)
  e[39][K(64)] = e[22]  -- SETTABLE [a=39 b=64 c=22 d=85] -- settable/void-call (inferred)
  call(e[44], e[37])  -- CALL? [a=44 b=0 c=37 d=nil] -- void call
  ::L_203::
  goto L_15
  e[16] = e[5][K(0)]  -- GETTABLE/CLOSURE? [a=5 b=0 c=16 d=nil]
  -- UNKNOWN op? [a=2 b=0 c=17 d=nil]
  ::L_206::
  goto L_12
  e[38] = {}  -- NEWTABLE [a=38 b=0 c=0 d=nil]
  e[39] = {}  -- NEWTABLE [a=39 b=0 c=0 d=nil]
  e[41] = {}  -- NEWTABLE [a=41 b=0 c=0 d=nil]
  e[39][K(1579)] = e[4]  -- SETTABLE [a=39 b=1579 c=4 d=147] -- settable/void-call (inferred)
  e[41][K(1579)] = e[112]  -- SETTABLE [a=41 b=1579 c=112 d=147] -- settable/void-call (inferred)
  e[38][K(1579)] = e[114]  -- SETTABLE [a=38 b=1579 c=114 d=147] -- settable/void-call (inferred)
  e[39][K(587)] = e[1148]  -- SETTABLE [a=39 b=587 c=1148 d=143] -- settable/void-call (inferred)
  e[44][K(141)] = e[37]  -- SETTABLE/CALL [a=44 b=141 c=37 d=nil] -- settable/void-call (inferred)
  ::L_215::
  goto L_145
  if e[0] then goto L_51 else goto L_217 end  -- back-edge (loop)
  e[2] = (e[2] == e[8])  -- COMPARE [a=2 b=16 c=8 d=nil]
  ::L_219::
  goto L_215
  e[39] = {}  -- NEWTABLE [a=39 b=0 c=0 d=nil]
  e[41] = {}  -- NEWTABLE [a=41 b=0 c=0 d=nil]
  e[38] = {}  -- NEWTABLE [a=38 b=0 c=0 d=nil]
  e[41][K(5)] = e[8]  -- SETTABLE [a=41 b=5 c=8 d=65] -- settable/void-call (inferred)
  e[38][K(5)] = e[4]  -- SETTABLE [a=38 b=5 c=4 d=65] -- settable/void-call (inferred)
  e[39][K(970)] = e[916]  -- SETTABLE [a=39 b=970 c=916 d=186] -- settable/void-call (inferred)
  call(e[44], e[37])  -- CALL? [a=44 b=0 c=37 d=nil] -- void call
  ::L_227::
  goto L_187
  ::L_228::
  goto L_110
  if e[17] then goto L_215 end  -- back-edge (loop)
  if e[233] then do return end else goto L_231 end
  ::L_231::
  goto L_172
  if e[8] then goto L_152 end  -- back-edge (loop)
  goto L_185
  if e[74] then do return end else goto L_235 end
  ::L_235::
  goto L_49
  ::L_236::
  goto L_132
  e[4] = e[4][true]  -- GETTABLE [a=4 b=161 c=1935 d=nil]  -- = true
  e[8] = e[8][K(3)]  -- GETTABLE [a=8 b=3 c=1935 d=nil]
  goto L_152
  ::L_240::
  e[243] = K(58)  -- LOADK_S [a=243 b=58 c=15 d=nil]
  ::L_241::
  goto L_102
  e[39] = {}  -- NEWTABLE [a=39 b=0 c=0 d=nil]
  e[41] = {}  -- NEWTABLE [a=41 b=0 c=0 d=nil]
  e[41][K(8)] = e[112]  -- SETTABLE [a=41 b=8 c=112 d=205] -- settable/void-call (inferred)
  e[39][K(1509)] = e[103]  -- SETTABLE [a=39 b=1509 c=103 d=116] -- settable/void-call (inferred)
  call(e[44], e[37])  -- CALL? [a=44 b=0 c=37 d=nil] -- void call
  goto L_247
  if e[215] then do return end else goto L_249 end
  ::L_249::
  goto L_227
end

local function proto74(...)  -- 71 instrs, 31 blocks (structured)
  local e = regs
  ::L_1::
  ::L_70::
  ::L_33::
  ::L_12::
  goto L_33
  e[2] = e[8][true]  -- GETTABLE/CLOSURE? [a=8 b=0 c=2 d=nil]  -- = true
  ::L_3::
  goto L_68
  -- UNKNOWN op? [a=0 b=201 c=0 d=nil]
  e[3] = (e[0] == e[3])  -- COMPARE [a=0 b=3 c=3 d=nil]  -- = true
  e[4] = e[3][true]  -- GETTABLE/CLOSURE? [a=3 b=0 c=4 d=nil]  -- = true
  ::L_7::
  goto L_7
  do return end  -- JMP/RETURN [a=0 b=0 c=4 d=nil]
  ::L_9::
  -- UNKNOWN op? [a=356 b=135 c=425 d=nil]
  ::L_10::
  goto L_63
  e[3] = e[3][false]  -- GETTABLE/CLOSURE [a=3 b=3 c=2 d=nil]  -- = false
  goto L_12
  e[23] = {}  -- NEWTABLE [a=23 b=0 c=0 d=nil]
  e[25] = {}  -- NEWTABLE [a=25 b=0 c=0 d=nil]
  e[25][K(9)] = e[12]  -- SETTABLE [a=25 b=9 c=12 d=4] -- settable/void-call (inferred)
  e[23][K(9)] = e[4]  -- SETTABLE [a=23 b=9 c=4 d=4] -- settable/void-call (inferred)
  e[23][K(126)] = e[111]  -- SETTABLE [a=23 b=126 c=111 d=34] -- settable/void-call (inferred)
  call(e[28], e[21])  -- CALL? [a=28 b=0 c=21 d=nil] -- void call
  ::L_20::
  goto L_3
  if e[121] then goto L_10 end  -- back-edge (loop)
  ::L_22::
  goto L_9
  e[22] = {}  -- NEWTABLE [a=22 b=0 c=0 d=nil]
  e[25] = {}  -- NEWTABLE [a=25 b=0 c=0 d=nil]
  e[23] = {}  -- NEWTABLE [a=23 b=0 c=0 d=nil]
  e[24] = {}  -- NEWTABLE [a=0 b=24 c=0 d=nil]
  e[24][K(91)] = e[23]  -- SETTABLE [a=24 b=91 c=23 d=62] -- settable/void-call (inferred)
  e[25][K(33)] = e[8]  -- SETTABLE [a=25 b=33 c=8 d=39] -- settable/void-call (inferred)
  e[23][K(89)] = e[4]  -- SETTABLE [a=23 b=89 c=4 d=40] -- settable/void-call (inferred)
  e[22][K(89)] = e[117]  -- SETTABLE [a=22 b=89 c=117 d=40] -- settable/void-call (inferred)
  e[23][K(43)] = e[3]  -- SETTABLE [a=23 b=43 c=3 d=71] -- settable/void-call (inferred)
  call(e[28], e[21])  -- CALL? [a=28 b=0 c=21 d=nil] -- void call
  goto L_33
  e[13] = {}  -- NEWTABLE [a=13 b=0 c=0 d=nil]
  e[14] = {}  -- NEWTABLE [a=0 b=14 c=0 d=nil]
  e[19] = K(15)  -- LOADK_S [a=0 b=15 c=19 d=nil]
  -- UNKNOWN op? [a=20 b=905 c=0 d=�jY]
  e[125] = 3  -- LOADK_N [a=0 b=81 c=125 d=nil]
  e[19] = arith(e[19], e[19])  -- ARITH [a=168 b=19 c=19 d=nil]  -- = 321
  e[19] = arith(e[19], e[1642])  -- UNOP/arith? [a=19 b=19 c=1642 d=nil]  -- = 511
  e[19] = e[19] + 18266  -- ADD [a=19 b=1041 c=19 d=18266]  -- = 18777
  e[19] = arith(e[19], e[1225])  -- UNOP/arith? [a=19 b=19 c=1225 d=nil]  -- = 5
  call(e[19], e[95])  -- CALL [a=19 b=14 c=95 d=nil] -- void call
  e[13][K(118)] = e[105]  -- SETTABLE [a=13 b=118 c=105 d=13] -- settable/void-call (inferred)
  call(e[20], e[11])  -- CALL? [a=20 b=0 c=11 d=nil] -- void call
  ::L_48::
  goto L_56
  ::L_49::
  goto L_49
  e[25] = {}  -- NEWTABLE [a=25 b=0 c=0 d=nil]
  e[23] = {}  -- NEWTABLE [a=23 b=0 c=0 d=nil]
  e[23][K(98)] = e[84]  -- SETTABLE [a=23 b=98 c=84 d=64] -- settable/void-call (inferred)
  e[25][K(98)] = e[122]  -- SETTABLE [a=25 b=98 c=122 d=64] -- settable/void-call (inferred)
  e[23][K(71)] = e[110]  -- SETTABLE [a=23 b=71 c=110 d=49] -- settable/void-call (inferred)
  call(e[28], e[21])  -- CALL? [a=28 b=0 c=21 d=nil] -- void call
  ::L_56::
  goto L_20
  e[0] = {}  -- NEWTABLE [a=0 b=1 c=0 d=nil]
  e[2] = e[1][false]  -- GETTABLE/CLOSURE? [a=1 b=0 c=2 d=nil]  -- = false
  e[3] = {}  -- NEWTABLE [a=2280 b=0 c=3 d=nil]
  e[4] = 106  -- LOADK [a=4 b=17 c=0 d=106]
  e[255] = 227  -- LOADK [a=255 b=896 c=0 d=227]
  e[121] = 82  -- LOADK [a=121 b=1660 c=0 d=82]
  ::L_63::
  if e[4] then goto L_68 end
  -- UNKNOWN op? [a=1 b=236 c=0 d=nil]
  e[8] = e[8]  -- MOVE [a=8 b=8 c=1992 d=nil]
  e[10] = e[2][false]  -- GETTABLE/CLOSURE? [a=2 b=0 c=10 d=nil]  -- = false
  e[8] = K(8)  -- LOADK_N [a=0 b=8 c=0 d=nil]
  ::L_68::
  goto L_1
  if e[0] then goto L_48 else goto L_70 end  -- back-edge (loop)
  goto L_22
end

local function proto75(...)  -- 7 instrs, 3 blocks (structured)
  local e = regs
  ::L_1::
  -- UNKNOWN op? [a=442 b=436 c=23 d=nil]
  goto L_1
  e[0] = {}  -- NEWTABLE [a=0 b=2 c=0 d=nil]
  e[2] = (e[0] == e[2])  -- COMPARE [a=0 b=2 c=2 d=nil]  -- = true
  e[3] = e[2][true]  -- GETTABLE/CLOSURE? [a=2 b=0 c=3 d=nil]  -- = true
  do return end  -- JMP/RETURN [a=0 b=0 c=3 d=nil]
end

local function proto76(...)  -- 51 instrs, 13 blocks (structured)
  local e = regs
  ::L_26::
  do return end  -- JMP/RETURN [a=137 b=213 c=4 d=nil]
  ::L_2::
  -- UNKNOWN op? [a=495 b=130 c=323 d=nil]
  e[20] = {}  -- NEWTABLE [a=20 b=0 c=0 d=nil]
  e[21] = {}  -- NEWTABLE [a=0 b=21 c=0 d=nil]
  e[20][K(19)] = e[4]  -- SETTABLE [a=20 b=19 c=4 d=26] -- settable/void-call (inferred)
  e[21][K(19)] = e[4]  -- SETTABLE [a=21 b=19 c=4 d=26] -- settable/void-call (inferred)
  e[20][K(128)] = e[119]  -- SETTABLE [a=20 b=128 c=119 d=51] -- settable/void-call (inferred)
  e[25][K(115)] = e[18]  -- SETTABLE/CALL [a=25 b=115 c=18 d=nil] -- settable/void-call (inferred)
  ::L_9::
  goto L_22
  e[21] = {}  -- NEWTABLE [a=0 b=21 c=0 d=nil]
  e[19] = {}  -- NEWTABLE [a=19 b=0 c=0 d=nil]
  e[22] = {}  -- NEWTABLE [a=22 b=0 c=0 d=nil]
  e[20] = {}  -- NEWTABLE [a=20 b=0 c=0 d=nil]
  e[19][K(33)] = e[4]  -- SETTABLE [a=19 b=33 c=4 d=39] -- settable/void-call (inferred)
  e[19][K(29)] = e[100]  -- SETTABLE [a=19 b=29 c=100 d=32] -- settable/void-call (inferred)
  e[22][K(55)] = e[8]  -- SETTABLE [a=22 b=55 c=8 d=37] -- settable/void-call (inferred)
  e[21][K(55)] = e[108]  -- SETTABLE [a=21 b=55 c=108 d=37] -- settable/void-call (inferred)
  e[20][K(119)] = e[71]  -- SETTABLE [a=20 b=119 c=71 d=22] -- settable/void-call (inferred)
  e[25][K(151)] = e[18]  -- SETTABLE/CALL [a=25 b=151 c=18 d=nil] -- settable/void-call (inferred)
  ::L_20::
  goto L_49
  ::L_22::
  goto L_9
  e[0] = {}  -- NEWTABLE [a=0 b=3 c=0 d=nil]
  e[3] = e[2][750480426]  -- GETTABLE/CLOSURE? [a=2 b=0 c=3 d=nil]  -- = 750480426
  e[233] = e[147][750480426]  -- GETTABLE/CLOSURE? [a=147 b=0 c=233 d=nil]  -- = 750480426
  goto L_26
  e[9] = {}  -- NEWTABLE [a=0 b=9 c=0 d=nil]
  e[8] = {}  -- NEWTABLE [a=8 b=0 c=0 d=nil]
  e[7] = {}  -- NEWTABLE [a=7 b=0 c=0 d=nil]
  e[14] = -255  -- LOADK_N [a=339 b=14 c=2298 d=nil]
  e[14] = arith(e[14], e[2094])  -- ARITH [a=14 b=14 c=2094 d=nil]  -- = -616
  e[14] = e[127] + 3946  -- ADD [a=14 b=2285 c=127 d=3946]  -- = 3330
  e[14] = arith(e[14], e[2237])  -- UNOP/arith? [a=14 b=14 c=2237 d=nil]  -- = 4
  call(e[14], e[104])  -- CALL [a=14 b=7 c=104 d=nil] -- void call
  e[14] = K(22)  -- LOADK_S [a=0 b=22 c=14 d=nil]
  e[15] = K(22)  -- LOADK_S [a=0 b=22 c=15 d=nil]
  -- UNKNOWN op? [a=191 b=1978 c=0 d=123]
  e[17] = 1  -- LOADK [a=17 b=107 c=0 d=1]
  e[15] = 61  -- LOADK_N [a=0 b=15 c=53 d=nil]
  call(e[131], e[101])  -- CALL [a=131 b=108 c=101 d=nil] -- void call
  e[16][K(2289)] = e[74]  -- SETTABLE/CALL [a=16 b=2289 c=74 d=27] -- settable/void-call (inferred)
  e[238] = K(57)  -- LOADK_S [a=238 b=57 c=101 d=nil]
  e[14] = 0  -- LOADK_N [a=0 b=14 c=0 d=nil]
  e[14] = e[14] + 26073  -- ADD [a=14 b=2321 c=14 d=26073]  -- = 26073
  e[14] = arith(e[14], e[1084])  -- UNOP/arith? [a=14 b=14 c=1084 d=nil]  -- = 3
  call(e[14], e[104])  -- CALL [a=14 b=9 c=104 d=nil] -- void call
  e[8][K(53)] = e[110]  -- SETTABLE [a=8 b=53 c=110 d=50] -- settable/void-call (inferred)
  call(e[17], e[6])  -- CALL? [a=17 b=0 c=6 d=nil] -- void call
  ::L_49::
  goto L_20
  goto L_2
end

local function proto77(...)  -- 89 instrs, 31 blocks (structured)
  local e = regs
  ::L_1::
  ::L_40::
  ::L_75::
  ::L_5::
  ::L_8::
  e[27] = {}  -- NEWTABLE [a=27 b=0 c=0 d=nil]
  e[29][K(108)] = e[112]  -- SETTABLE [a=29 b=108 c=112 d=16] -- settable/void-call (inferred)
  e[27][K(111)] = e[5]  -- SETTABLE [a=27 b=111 c=5 d=3] -- settable/void-call (inferred)
  call(e[32], e[25])  -- CALL? [a=32 b=0 c=25 d=nil] -- void call
  ::L_12::
  ::L_65::
  goto L_1
  e[11] = e[3][K(0)]  -- GETTABLE/CLOSURE? [a=3 b=0 c=11 d=nil]
  goto L_5
  e[29] = {}  -- NEWTABLE [a=29 b=0 c=0 d=nil]
  goto L_8
  e[0] = {}  -- NEWTABLE [a=0 b=7 c=0 d=nil]
  if e[73] then goto L_80 end
  ::L_15::
  goto L_19
  -- UNKNOWN op? [a=5 b=0 c=9 d=nil]
  e[10] = e[2][K(0)]  -- GETTABLE/CLOSURE? [a=2 b=0 c=10 d=nil]
  e[11] = e[3][93]  -- GETTABLE/CLOSURE? [a=3 b=0 c=11 d=nil]  -- = 93
  ::L_19::
  goto L_8
  e[17] = {}  -- NEWTABLE [a=17 b=0 c=0 d=nil]
  e[15] = {}  -- NEWTABLE [a=15 b=0 c=0 d=nil]
  e[21] = K(16)  -- LOADK_S [a=0 b=16 c=21 d=nil]
  e[22] = -21  -- LOADK_N [a=591 b=22 c=2329 d=nil]
  e[23] = K(13)  -- LOADK_S [a=0 b=13 c=23 d=nil]
  e[150] = ">i=<T<HI ="  -- LOADK [a=150 b=1127 c=0 d=>i=<T<HI]
  e[23] = e[0][14]  -- GETINDEX? [a=0 b=0 c=23 d=nil]  -- = 14
  e[21] = 4294967269  -- LOADK_N [a=0 b=21 c=41 d=nil]
  e[80][K(2112)] = e[21]  -- SETTABLE/CALL [a=80 b=2112 c=21 d=-4294964356] -- settable/void-call (inferred)
  e[21][K(182)] = e[61]  -- SETTABLE/CALL [a=21 b=182 c=61 d=nil] -- settable/void-call (inferred)
  e[58][K(140)] = e[119]  -- SETTABLE/CALL [a=58 b=140 c=119 d=nil] -- settable/void-call (inferred)
  e[18][K(222)] = e[32]  -- SETTABLE/CALL [a=18 b=222 c=32 d=nil] -- settable/void-call (inferred)
  e[186] = K(42)  -- LOADK_S [a=186 b=42 c=86 d=nil]
  e[21] = arith(e[21], e[2391])  -- UNOP/arith? [a=21 b=21 c=2391 d=nil]  -- = 286
  call(e[21], e[27])  -- CALL [a=21 b=17 c=27 d=nil] -- void call
  e[15][K(89)] = e[3]  -- SETTABLE [a=15 b=89 c=3 d=40] -- settable/void-call (inferred)
  e[24][K(184)] = e[13]  -- SETTABLE/CALL [a=24 b=184 c=13 d=nil] -- settable/void-call (inferred)
  goto L_12
  ::L_39::
  if e[86] then do return end else goto L_40 end
  ::L_41::
  goto L_41
  e[28] = {}  -- NEWTABLE [a=0 b=28 c=0 d=nil]
  e[26] = {}  -- NEWTABLE [a=26 b=0 c=0 d=nil]
  e[27] = {}  -- NEWTABLE [a=27 b=0 c=0 d=nil]
  e[29] = {}  -- NEWTABLE [a=29 b=0 c=0 d=nil]
  e[29][K(61)] = e[96]  -- SETTABLE [a=29 b=61 c=96 d=27] -- settable/void-call (inferred)
  e[28][K(19)] = e[124]  -- SETTABLE [a=28 b=19 c=124 d=26] -- settable/void-call (inferred)
  e[26][K(115)] = e[4]  -- SETTABLE [a=26 b=115 c=4 d=28] -- settable/void-call (inferred)
  e[27][K(45)] = e[16]  -- SETTABLE [a=27 b=45 c=16 d=68] -- settable/void-call (inferred)
  e[27][K(54)] = e[33]  -- SETTABLE [a=27 b=54 c=33 d=41] -- settable/void-call (inferred)
  call(e[32], e[25])  -- CALL? [a=32 b=0 c=25 d=nil] -- void call
  ::L_52::
  goto L_39
  e[8] = K(8)  -- LOADK_N [a=0 b=8 c=4 d=nil]
  -- UNKNOWN op? [a=18 b=231 c=2 d=nil]
  call(e[129], e[37])  -- CALL [a=129 b=170 c=37 d=nil] -- void call
  e[8][K(681)] = e[170]  -- SETTABLE/CALL [a=8 b=681 c=170 d=34133] -- settable/void-call (inferred)
  e[43] = K(116)  -- LOADK_S [a=43 b=116 c=209 d=nil]
  e[9] = e[5][false]  -- GETTABLE/CLOSURE? [a=5 b=0 c=9 d=nil]  -- = false
  e[10] = e[2][K(0)]  -- GETTABLE/CLOSURE? [a=2 b=0 c=10 d=nil]
  e[11] = e[3][93]  -- GETTABLE/CLOSURE? [a=3 b=0 c=11 d=nil]  -- = 93
  ::L_61::
  goto L_8
  call(e[8], e[0])  -- CALL [a=8 b=0 c=0 d=nil] -- void call
  e[9] = e[5][K(0)]  -- GETTABLE/CLOSURE? [a=5 b=0 c=9 d=nil]
  e[10] = e[2][K(0)]  -- GETTABLE/CLOSURE? [a=2 b=0 c=10 d=nil]
  goto L_65
  -- UNKNOWN op? [a=0 b=66 c=0 d=nil]
  e[6][K(4)] = e[2]  -- SETTABLE/CALL [a=6 b=4 c=2 d=nil] -- settable/void-call (inferred)
  e[5] = e[5][false]  -- GETTABLE [a=5 b=91 c=90 d=nil]  -- = false
  call(e[104], e[155])  -- CALL [a=104 b=124 c=155 d=nil] -- void call
  e[3][K(196)] = e[176]  -- SETTABLE/CALL [a=3 b=196 c=176 d=93] -- settable/void-call (inferred)
  e[149] = K(100)  -- LOADK_S [a=149 b=100 c=66 d=nil]
  e[8] = 57934  -- LOADK [a=8 b=2176 c=0 d=57934]
  goto L_15
  if e[1528] then goto L_61 else goto L_75 end  -- back-edge (loop)
  e[27] = {}  -- NEWTABLE [a=27 b=0 c=0 d=nil]
  e[28] = {}  -- NEWTABLE [a=0 b=28 c=0 d=nil]
  e[29] = {}  -- NEWTABLE [a=29 b=0 c=0 d=nil]
  e[27][K(69)] = e[4]  -- SETTABLE [a=27 b=69 c=4 d=54] -- settable/void-call (inferred)
  ::L_80::
  e[28][K(69)] = e[84]  -- SETTABLE [a=28 b=69 c=84 d=54] -- settable/void-call (inferred)
  e[29][K(69)] = e[112]  -- SETTABLE [a=29 b=69 c=112 d=54] -- settable/void-call (inferred)
  e[29][K(46)] = e[112]  -- SETTABLE [a=29 b=46 c=112 d=87] -- settable/void-call (inferred)
  e[27][K(93)] = e[64]  -- SETTABLE [a=27 b=93 c=64 d=2] -- settable/void-call (inferred)
  e[32][K(248)] = e[25]  -- SETTABLE/CALL [a=32 b=248 c=25 d=nil] -- settable/void-call (inferred)
  ::L_85::
  goto L_85
  e[1] = e[8]  -- MOVE [a=8 b=1 c=930 d=nil]
  -- UNKNOWN op? [a=7 b=0 c=10 d=nil]
  e[11] = e[2][K(0)]  -- GETTABLE/CLOSURE? [a=2 b=0 c=11 d=nil]
  goto L_52
end

local function proto78(...)  -- 7 instrs, 4 blocks (structured)
  local e = regs
  e[87][K(106)] = e[73]  -- SETTABLE/CALL [a=87 b=106 c=73 d=nil] -- settable/void-call (inferred)
  e[0] = {}  -- NEWTABLE [a=0 b=3 c=0 d=nil]
  e[3] = e[3][K(2)]  -- GETTABLE [a=3 b=2 c=1935 d=nil]
  e[4] = e[3][K(0)]  -- GETTABLE/CLOSURE? [a=3 b=0 c=4 d=nil]
  ::L_6::
  goto L_6
  do return end  -- JMP/RETURN [a=0 b=0 c=4 d=nil]
end

local function proto79(...)  -- 133 instrs, 55 blocks (structured)
  local e = regs
  ::L_1::
  ::L_12::
  ::L_127::
  ::L_55::
  if e[363] then do return end else goto L_100 end
  ::L_100::
  e[7] = 114  -- LOADK [a=7 b=1651 c=104 d=114]
  e[9] = e[9][true]  -- GETTABLE/CLOSURE [a=9 b=9 c=2 d=nil]  -- = true
  -- UNKNOWN op? [a=6 b=117 c=11 d=nil]
  e[12] = e[7][114]  -- GETTABLE/CLOSURE? [a=7 b=0 c=12 d=nil]  -- = 114
  e[13] = e[2][750480426]  -- GETTABLE/CLOSURE? [a=2 b=0 c=13 d=nil]  -- = 750480426
  ::L_105::
  ::L_80::
  goto L_1
  dataop(e[6], e[0], e[85])  -- DATAOP [a=6 b=0 c=85 d=nil]  -- = true
  e[12] = e[7][116]  -- GETTABLE/CLOSURE? [a=7 b=0 c=12 d=nil]  -- = 116
  e[13] = e[2][750480426]  -- GETTABLE/CLOSURE? [a=2 b=0 c=13 d=nil]  -- = 750480426
  e[14] = 48092  -- LOADK [a=14 b=2348 c=0 d=48092]
  ::L_6::
  e[15] = e[3][K(0)]  -- GETTABLE/CLOSURE? [a=3 b=0 c=15 d=nil]
  e[16] = e[9][K(0)]  -- GETTABLE/CLOSURE? [a=9 b=0 c=16 d=nil]
  ::L_8::
  goto L_11
  e[0] = {}  -- NEWTABLE [a=0 b=9 c=0 d=nil]
  call(e[10], e[0])  -- CALL [a=10 b=0 c=0 d=nil] -- void call
  ::L_11::
  if e[54] then goto L_44 else goto L_12 end
  ::L_13::
  goto L_17
  ::L_14::
  goto L_86
  ::L_15::
  goto L_35
  -- UNKNOWN op? [a=61 b=1025 c=10 d=45243]
  ::L_17::
  goto L_56
  e[33] = {}  -- NEWTABLE [a=0 b=33 c=0 d=nil]
  e[32] = {}  -- NEWTABLE [a=32 b=0 c=0 d=nil]
  e[33][K(98)] = e[93]  -- SETTABLE [a=33 b=98 c=93 d=64] -- settable/void-call (inferred)
  e[33][K(11)] = e[100]  -- SETTABLE [a=33 b=11 c=100 d=95] -- settable/void-call (inferred)
  e[32][K(118)] = e[84]  -- SETTABLE [a=32 b=118 c=84 d=13] -- settable/void-call (inferred)
  call(e[37], e[30])  -- CALL? [a=37 b=0 c=30 d=nil] -- void call
  ::L_24::
  goto L_8
  e[32] = {}  -- NEWTABLE [a=32 b=0 c=0 d=nil]
  e[31] = {}  -- NEWTABLE [a=31 b=0 c=0 d=nil]
  e[34] = {}  -- NEWTABLE [a=34 b=0 c=0 d=nil]
  e[31][K(2361)] = e[4]  -- SETTABLE [a=31 b=2361 c=4 d=119] -- settable/void-call (inferred)
  e[34][K(1509)] = e[8]  -- SETTABLE [a=34 b=1509 c=8 d=116] -- settable/void-call (inferred)
  e[31][K(2224)] = e[115]  -- SETTABLE [a=31 b=2224 c=115 d=117] -- settable/void-call (inferred)
  e[34][K(1875)] = e[96]  -- SETTABLE [a=34 b=1875 c=96 d=114] -- settable/void-call (inferred)
  e[32][K(106)] = e[2]  -- SETTABLE [a=32 b=106 c=2 d=36] -- settable/void-call (inferred)
  call(e[37], e[30])  -- CALL? [a=37 b=0 c=30 d=nil] -- void call
  ::L_34::
  goto L_84
  ::L_35::
  goto L_61
  ::L_36::
  goto L_24
  e[15] = e[3][true]  -- GETTABLE/CLOSURE? [a=3 b=0 c=15 d=nil]  -- = true
  e[16] = e[7][116]  -- GETTABLE/CLOSURE? [a=7 b=0 c=16 d=nil]  -- = 116
  if e[11] then goto L_6 end  -- back-edge (loop)
  -- UNKNOWN op? [a=11 b=0 c=10 d=nil]
  e[6] = e[12][true]  -- GETTABLE/CLOSURE? [a=12 b=0 c=6 d=nil]  -- = true
  e[7] = e[13][116]  -- GETTABLE/CLOSURE? [a=13 b=0 c=7 d=nil]  -- = 116
  e[3] = e[14][true]  -- GETTABLE/CLOSURE? [a=14 b=0 c=3 d=nil]  -- = true
  ::L_44::
  goto L_15
  if e[98] then goto L_105 end  -- back-edge (loop)
  ::L_46::
  goto L_74
  e[31] = {}  -- NEWTABLE [a=31 b=0 c=0 d=nil]
  e[32] = {}  -- NEWTABLE [a=32 b=0 c=0 d=nil]
  e[34] = {}  -- NEWTABLE [a=34 b=0 c=0 d=nil]
  e[31][K(36)] = e[4]  -- SETTABLE [a=31 b=36 c=4 d=100] -- settable/void-call (inferred)
  e[32][K(123)] = e[4]  -- SETTABLE [a=32 b=123 c=4 d=102] -- settable/void-call (inferred)
  e[34][K(123)] = e[112]  -- SETTABLE [a=34 b=123 c=112 d=102] -- settable/void-call (inferred)
  e[32][K(2241)] = e[1134]  -- SETTABLE [a=32 b=2241 c=1134 d=129] -- settable/void-call (inferred)
  call(e[37], e[30])  -- CALL? [a=37 b=0 c=30 d=nil] -- void call
  goto L_55
  ::L_56::
  goto L_109
  e[14] = 16433  -- LOADK [a=14 b=1131 c=0 d=16433]
  e[15] = e[3][true]  -- GETTABLE/CLOSURE? [a=3 b=0 c=15 d=nil]  -- = true
  e[16] = e[9][true]  -- GETTABLE/CLOSURE? [a=9 b=0 c=16 d=nil]  -- = true
  ::L_61::
  goto L_11
  e[11] = e[6][true]  -- GETTABLE/CLOSURE? [a=6 b=0 c=11 d=nil]  -- = true
  e[12] = e[7][116]  -- GETTABLE/CLOSURE? [a=7 b=0 c=12 d=nil]  -- = 116
  e[13] = e[151][750480426]  -- GETTABLE/CLOSURE? [a=151 b=0 c=13 d=nil]  -- = 750480426
  ::L_65::
  goto L_129
  e[34] = {}  -- NEWTABLE [a=34 b=0 c=0 d=nil]
  e[31] = {}  -- NEWTABLE [a=31 b=0 c=0 d=nil]
  e[32] = {}  -- NEWTABLE [a=32 b=0 c=0 d=nil]
  e[31][K(93)] = e[103]  -- SETTABLE [a=31 b=93 c=103 d=2] -- settable/void-call (inferred)
  e[34][K(93)] = e[112]  -- SETTABLE [a=34 b=93 c=112 d=2] -- settable/void-call (inferred)
  e[32][K(47)] = e[80]  -- SETTABLE [a=32 b=47 c=80 d=57] -- settable/void-call (inferred)
  call(e[37], e[30])  -- CALL? [a=37 b=0 c=30 d=nil] -- void call
  ::L_74::
  goto L_93
  e[2] = e[5][750480426]  -- GETTABLE/CLOSURE? [a=5 b=0 c=2 d=nil]  -- = 750480426
  e[7] = 31  -- LOADK [a=7 b=736 c=0 d=31]
  e[11] = e[6][false]  -- GETTABLE/CLOSURE? [a=6 b=0 c=11 d=nil]  -- = false
  e[12] = e[7][31]  -- GETTABLE/CLOSURE? [a=7 b=0 c=12 d=nil]  -- = 31
  e[13] = e[2][750480426]  -- GETTABLE/CLOSURE? [a=2 b=0 c=13 d=nil]  -- = 750480426
  goto L_80
  e[7] = 116  -- LOADK [a=7 b=735 c=0 d=116]
  e[9] = e[9][K(49)]  -- GETTABLE [a=9 b=49 c=1935 d=nil]
  e[2] = e[4][750480426]  -- GETTABLE/CLOSURE? [a=4 b=0 c=2 d=nil]  -- = 750480426
  ::L_84::
  goto L_34
  if e[128] then goto L_127 end  -- back-edge (loop)
  ::L_86::
  goto L_126
  e[32] = {}  -- NEWTABLE [a=32 b=0 c=0 d=nil]
  e[34] = {}  -- NEWTABLE [a=34 b=0 c=0 d=nil]
  e[34][K(89)] = e[112]  -- SETTABLE [a=34 b=89 c=112 d=40] -- settable/void-call (inferred)
  e[34][K(108)] = e[39]  -- SETTABLE [a=34 b=108 c=39 d=16] -- settable/void-call (inferred)
  e[32][K(100)] = e[106]  -- SETTABLE [a=32 b=100 c=106 d=14] -- settable/void-call (inferred)
  call(e[37], e[30])  -- CALL? [a=37 b=0 c=30 d=nil] -- void call
  ::L_93::
  goto L_36
  e[111] = 16433  -- LOADK [a=111 b=1131 c=0 d=16433]
  e[15] = e[3][true]  -- GETTABLE/CLOSURE? [a=3 b=0 c=15 d=nil]  -- = true
  e[16] = e[9][K(0)]  -- GETTABLE/CLOSURE? [a=9 b=0 c=16 d=nil]
  goto L_11
  e[1] = e[11]  -- MOVE [a=11 b=1 c=1275 d=nil]
  e[13] = e[9][true]  -- GETTABLE/CLOSURE? [a=9 b=0 c=13 d=nil]  -- = true
  e[14] = e[6][true]  -- GETTABLE/CLOSURE? [a=6 b=0 c=14 d=nil]  -- = true
  ::L_109::
  goto L_13
  e[20] = {}  -- NEWTABLE [a=20 b=0 c=0 d=nil]
  e[26] = K(20)  -- LOADK_S [a=0 b=20 c=26 d=nil]
  e[27] = K(5)  -- LOADK_S [a=0 b=5 c=27 d=nil]
  e[28] = 3.141592653589793  -- LOADK_S [a=0 b=6 c=28 d=nil]
  -- UNKNOWN op? [a=0 b=0 c=27 d=nil]
  e[28] = K(13)  -- LOADK_S [a=0 b=13 c=28 d=nil]
  e[1696] = (e[29] == e[0])  -- COMPARE [a=29 b=1696 c=0 d=>]  -- = "> i>>JL>=c235>"
  e[237] = 251  -- LOADK_N [a=0 b=0 c=237 d=nil]
  e[27] = arith(e[27], e[28])  -- ARITH [a=27 b=27 c=28 d=nil]  -- = 254
  e[28] = 11  -- LOADK [a=28 b=1380 c=22 d=11]
  e[26] = 532676608  -- LOADK_N [a=0 b=26 c=0 d=nil]
  e[26] = e[26] + -532671605  -- ADD [a=26 b=1629 c=26 d=-532671605]  -- = 5003
  e[26] = arith(e[26], e[1141])  -- UNOP/arith? [a=26 b=26 c=1141 d=nil]  -- = 8
  call(e[26], e[7])  -- CALL [a=26 b=20 c=7 d=nil] -- void call
  e[20][K(105)] = e[5]  -- SETTABLE [a=20 b=105 c=5 d=56] -- settable/void-call (inferred)
  call(e[29], e[18])  -- CALL? [a=29 b=0 c=18 d=nil] -- void call
  ::L_126::
  goto L_65
  goto L_14
  ::L_129::
  goto L_46
  call(e[14], e[0])  -- CALL [a=14 b=0 c=0 d=nil] -- void call
  e[15] = e[3][true]  -- GETTABLE/CLOSURE? [a=3 b=0 c=15 d=nil]  -- = true
  e[16] = e[9][true]  -- GETTABLE/CLOSURE? [a=9 b=0 c=16 d=nil]  -- = true
  goto L_11
end

local function proto80(...)  -- 87 instrs, 37 blocks (structured)
  local e = regs
  ::L_1::
  ::L_63::
  ::L_5::
  ::L_48::
  ::L_10::
  goto L_1
  e[4] = e[4][K(32)]  -- GETTABLE [a=4 b=32 c=18 d=nil]
  e[6] = 45243  -- LOADK [a=6 b=1025 c=0 d=45243]
  e[7] = e[3][true]  -- GETTABLE/CLOSURE? [a=3 b=0 c=7 d=nil]  -- = true
  goto L_5
  ::L_6::
  e[24] = {}  -- NEWTABLE [a=24 b=0 c=0 d=nil]
  e[24][K(127)] = e[4]  -- SETTABLE [a=24 b=127 c=4 d=31] -- settable/void-call (inferred)
  e[24][K(34)] = e[115]  -- SETTABLE [a=24 b=34 c=115 d=63] -- settable/void-call (inferred)
  call(e[29], e[22])  -- CALL? [a=29 b=0 c=22 d=nil] -- void call
  goto L_10
  e[15] = {}  -- NEWTABLE [a=15 b=0 c=0 d=nil]
  e[13] = {}  -- NEWTABLE [a=13 b=0 c=0 d=nil]
  e[19] = K(14)  -- LOADK_S [a=0 b=14 c=19 d=nil]
  e[20] = K(13)  -- LOADK_S [a=0 b=13 c=20 d=nil]
  e[380] = (e[21] == e[0])  -- COMPARE [a=21 b=380 c=0]  -- = " =c113L <==d<=> "
  -- UNKNOWN op? [a=0 b=0 c=20 d=nil]
  e[20] = (e[20] == e[1559])  -- COMPARE [a=20 b=20 c=1559 d=nil]  -- = true
  if e[20] then goto L_86 end
  ::L_19::
  goto L_75
  ::L_20::
  goto L_79
  e[7] = e[3][true]  -- GETTABLE/CLOSURE? [a=3 b=0 c=7 d=nil]  -- = true
  e[14][K(125)] = e[8]  -- SETTABLE/CALL [a=14 b=125 c=8 d=nil] -- settable/void-call (inferred)
  call(e[5], e[194])  -- CALL [a=5 b=186 c=194 d=nil] -- void call
  e[195] = K(128)  -- LOADK_S [a=195 b=128 c=128 d=nil]
  e[9] = e[4][true]  -- GETTABLE/CLOSURE? [a=4 b=0 c=9 d=nil]  -- = true
  ::L_26::
  goto L_6
  e[5] = 41  -- LOADK [a=5 b=933 c=0 d=41]
  e[3] = e[2][true]  -- GETTABLE/CLOSURE? [a=2 b=0 c=3 d=nil]  -- = true
  call(e[6], e[0])  -- CALL [a=6 b=143 c=0 d=nil] -- void call
  ::L_32::
  goto L_20
  e[24] = {}  -- NEWTABLE [a=24 b=0 c=0 d=nil]
  e[23] = {}  -- NEWTABLE [a=23 b=0 c=0 d=nil]
  e[26] = {}  -- NEWTABLE [a=26 b=0 c=0 d=nil]
  e[26][K(22)] = e[8]  -- SETTABLE [a=26 b=22 c=8 d=15] -- settable/void-call (inferred)
  e[23][K(5)] = e[117]  -- SETTABLE [a=23 b=5 c=117 d=65] -- settable/void-call (inferred)
  e[26][K(108)] = e[96]  -- SETTABLE [a=26 b=108 c=96 d=16] -- settable/void-call (inferred)
  e[24][K(98)] = e[19]  -- SETTABLE [a=24 b=98 c=19 d=64] -- settable/void-call (inferred)
  call(e[29], e[22])  -- CALL? [a=29 b=0 c=22 d=nil] -- void call
  ::L_41::
  goto L_26
  e[20] = K(5)  -- LOADK_S [a=0 b=5 c=20 d=nil]
  e[21] = K(6)  -- LOADK_S [a=0 b=6 c=21 d=nil]
  e[20] = K(0)  -- LOADK_N [a=17 b=0 c=20 d=nil]
  ::L_45::
  goto L_64
  e[0] = {}  -- NEWTABLE [a=0 b=5 c=0 d=nil]
  -- UNKNOWN op? [a=1509 b=62 c=5 d=nil]
  goto L_48
  e[8] = e[5][116]  -- GETTABLE/CLOSURE? [a=5 b=234 c=8 d=nil]  -- = 116
  e[181][K(73)] = e[9]  -- SETTABLE/CALL [a=181 b=73 c=9 d=nil] -- settable/void-call (inferred)
  call(e[4], e[40])  -- CALL [a=4 b=39 c=40 d=nil] -- void call
  e[132] = K(20)  -- LOADK_S [a=132 b=20 c=53 d=nil]
  ::L_53::
  goto L_6
  e[24] = {}  -- NEWTABLE [a=24 b=0 c=0 d=nil]
  e[25] = {}  -- NEWTABLE [a=0 b=25 c=0 d=nil]
  e[25][K(51)] = e[4]  -- SETTABLE [a=25 b=51 c=4 d=44] -- settable/void-call (inferred)
  e[24][K(46)] = e[101]  -- SETTABLE [a=24 b=46 c=101 d=87] -- settable/void-call (inferred)
  call(e[29], e[22])  -- CALL? [a=29 b=0 c=22 d=nil] -- void call
  ::L_59::
  goto L_59
  if e[20] then goto L_64 end
  goto L_85
  -- UNKNOWN op? [a=456 b=304 c=502 d=nil]
  goto L_63
  ::L_64::
  goto L_32
  e[22] = 286  -- LOADK_N [a=0 b=0 c=22 d=nil]
  e[223][K(453)] = e[19]  -- SETTABLE/CALL [a=223 b=453 c=19 d=28545] -- settable/void-call (inferred)
  e[19][K(214)] = e[218]  -- SETTABLE/CALL [a=19 b=214 c=218 d=nil] -- settable/void-call (inferred)
  e[185][K(5)] = e[222]  -- SETTABLE/CALL [a=185 b=5 c=222 d=nil] -- settable/void-call (inferred)
  e[131][K(252)] = e[193]  -- SETTABLE/CALL [a=131 b=252 c=193 d=nil] -- settable/void-call (inferred)
  e[42] = K(237)  -- LOADK_S [a=42 b=237 c=236 d=nil]
  e[19] = arith(e[19], e[310])  -- UNOP/arith? [a=19 b=19 c=310 d=nil]  -- = 265
  call(e[19], e[40])  -- CALL [a=19 b=15 c=40 d=nil] -- void call
  e[13][K(61)] = e[116]  -- SETTABLE [a=13 b=61 c=116 d=27] -- settable/void-call (inferred)
  call(e[21], e[11])  -- CALL? [a=21 b=0 c=11 d=nil] -- void call
  ::L_75::
  goto L_19
  call(e[63], e[72])  -- CALL [a=63 b=198 c=72 d=nil] -- void call
  e[20][K(182)] = e[13]  -- SETTABLE/CALL [a=20 b=182 c=13 d=286] -- settable/void-call (inferred)
  e[155] = K(52)  -- LOADK_S [a=155 b=52 c=194 d=nil]
  ::L_79::
  goto L_86
  e[24] = {}  -- NEWTABLE [a=24 b=0 c=0 d=nil]
  e[24][K(93)] = e[16]  -- SETTABLE [a=24 b=93 c=16 d=2] -- settable/void-call (inferred)
  e[24][K(71)] = e[4]  -- SETTABLE [a=24 b=71 c=4 d=49] -- settable/void-call (inferred)
  e[24][K(110)] = e[116]  -- SETTABLE [a=24 b=110 c=116 d=20] -- settable/void-call (inferred)
  e[29][K(134)] = e[22]  -- SETTABLE/CALL [a=29 b=134 c=22 d=nil] -- settable/void-call (inferred)
  ::L_85::
  goto L_45
  ::L_86::
  goto L_41
  goto L_53
end

local function proto81(...)  -- 8 instrs, 4 blocks (structured)
  local e = regs
  ::L_1::
  e[0] = {}  -- NEWTABLE [a=0 b=2 c=0 d=nil]
  e[2] = (e[0] == e[2])  -- COMPARE [a=0 b=2 c=2 d=nil]  -- = false
  e[3] = e[2][false]  -- GETTABLE/CLOSURE? [a=2 b=0 c=3 d=nil]  -- = false
  e[4] = e[2][false]  -- GETTABLE/CLOSURE? [a=2 b=0 c=4 d=nil]  -- = false
  goto L_1
  call(e[354], e[135])  -- CALL [a=354 b=343 c=135 d=nil] -- void call
end

local function proto82(...)  -- 54 instrs, 24 blocks (structured)
  local e = regs
  ::L_1::
  ::L_20::
  do return end  -- JMP/RETURN [a=0 b=122 c=0 d=nil]
  e[152] = 262  -- LOADK [a=152 b=1792 c=228 d=262]
  ::L_3::
  goto L_32
  e[7] = {}  -- NEWTABLE [a=7 b=0 c=0 d=nil]
  -- UNKNOWN op? [a=2401 b=1310 c=13 d=213]
  e[13] = (e[13] == e[1072])  -- COMPARE [a=13 b=13 c=1072 d=nil]  -- = false
  if e[13] then goto L_13 end
  ::L_8::
  goto L_8
  e[13] = K(13)  -- LOADK_S [a=0 b=13 c=13 d=nil]
  e[14][K(161)] = e[0]  -- SETTABLE/CALL [a=14 b=161 c=0 d=<d>=i5<<>H] -- settable/void-call (inferred)
  e[13] = K(0)  -- LOADK_N [a=0 b=0 c=13 d=nil]
  ::L_12::
  ::L_13::
  goto L_21
  if e[13] then goto L_32 end
  ::L_15::
  goto L_1
  e[0] = {}  -- NEWTABLE [a=0 b=2 c=0 d=nil]
  e[3] = e[3][K(2)]  -- GETTABLE [a=3 b=2 c=909 d=nil]
  e[210] = e[210][750480426]  -- GETTABLE [a=210 b=2 c=167 d=nil]  -- = 750480426
  if e[3] then do return end else goto L_20 end
  ::L_21::
  goto L_48
  e[19] = {}  -- NEWTABLE [a=19 b=0 c=0 d=nil]
  e[17] = {}  -- NEWTABLE [a=17 b=0 c=0 d=nil]
  e[19][K(99)] = e[929]  -- SETTABLE [a=19 b=99 c=929 d=5] -- settable/void-call (inferred)
  e[17][K(118)] = e[111]  -- SETTABLE [a=17 b=118 c=111 d=13] -- settable/void-call (inferred)
  e[22][K(227)] = e[15]  -- SETTABLE/CALL [a=22 b=227 c=15 d=nil] -- settable/void-call (inferred)
  goto L_3
  ::L_28::
  -- UNKNOWN op? [a=431 b=64 c=402 d=nil]
  ::L_29::
  goto L_12
  ::L_32::
  goto L_38
  e[13] = e[13] + 8993  -- ADD [a=13 b=1400 c=13 d=8993]  -- = 9255
  e[13] = arith(e[13], e[2108])  -- UNOP/arith? [a=13 b=13 c=2108 d=nil]  -- = 1
  call(e[13], e[127])  -- CALL [a=13 b=7 c=127 d=nil] -- void call
  e[7][K(32)] = e[22]  -- SETTABLE [a=7 b=32 c=22 d=29] -- settable/void-call (inferred)
  e[14][K(48)] = e[5]  -- SETTABLE/CALL [a=14 b=48 c=5 d=nil] -- settable/void-call (inferred)
  ::L_38::
  goto L_15
  e[19] = {}  -- NEWTABLE [a=19 b=0 c=0 d=nil]
  e[16] = {}  -- NEWTABLE [a=16 b=0 c=0 d=nil]
  e[18] = {}  -- NEWTABLE [a=0 b=18 c=0 d=nil]
  e[17] = {}  -- NEWTABLE [a=17 b=0 c=0 d=nil]
  e[19][K(42)] = e[8]  -- SETTABLE [a=19 b=42 c=8 d=10] -- settable/void-call (inferred)
  e[16][K(93)] = e[4]  -- SETTABLE [a=16 b=93 c=4 d=2] -- settable/void-call (inferred)
  e[18][K(93)] = e[118]  -- SETTABLE [a=18 b=93 c=118 d=2] -- settable/void-call (inferred)
  e[17][K(29)] = e[115]  -- SETTABLE [a=17 b=29 c=115 d=32] -- settable/void-call (inferred)
  e[22][K(230)] = e[15]  -- SETTABLE/CALL [a=22 b=230 c=15 d=nil] -- settable/void-call (inferred)
  ::L_48::
  goto L_28
  e[18] = {}  -- NEWTABLE [a=0 b=18 c=0 d=nil]
  e[17] = {}  -- NEWTABLE [a=17 b=0 c=0 d=nil]
  e[18][K(114)] = e[9]  -- SETTABLE [a=18 b=114 c=9 d=18] -- settable/void-call (inferred)
  e[17][K(122)] = e[32]  -- SETTABLE [a=17 b=122 c=32 d=21] -- settable/void-call (inferred)
  call(e[22], e[15])  -- CALL? [a=22 b=0 c=15 d=nil] -- void call
  goto L_29
end

local function proto83(...)  -- 97 instrs, 37 blocks (structured)
  local e = regs
  ::L_1::
  ::L_33::
  ::L_72::
  ::L_94::
  ::L_24::
  goto L_1
  goto L_25
  ::L_4::
  -- UNKNOWN op? [a=395 b=301 c=135 d=nil]
  e[11] = {}  -- NEWTABLE [a=11 b=0 c=0 d=nil]
  e[17] = K(13)  -- LOADK_S [a=0 b=13 c=17 d=nil]
  e[544] = (e[18] == e[226])  -- COMPARE [a=18 b=544 c=226]  -- = " <l >L>"
  e[17] = 16  -- LOADK_N [a=0 b=0 c=17 d=nil]
  e[17] = (e[17] == e[17])  -- COMPARE [a=17 b=1336 c=17 d=318]  -- = true
  if e[17] then goto L_62 end
  ::L_11::
  goto L_80
  ::L_12::
  goto L_84
  e[18] = K(15)  -- LOADK_S [a=0 b=15 c=18 d=nil]
  e[19] = ""  -- LOADK [a=19 b=340 c=0]
  e[18] = 0  -- LOADK_N [a=34 b=0 c=18 d=nil]
  e[17] = arith(e[17], e[18])  -- ARITH [a=17 b=17 c=18 d=nil]  -- = 142
  e[17] = e[17] + 3787  -- ADD [a=17 b=1367 c=17 d=3787]  -- = 3929
  e[17] = arith(e[17], e[946])  -- UNOP/arith? [a=17 b=17 c=946 d=nil]  -- = 2
  call(e[17], e[101])  -- CALL [a=17 b=11 c=101 d=nil] -- void call
  e[11][K(62)] = e[124]  -- SETTABLE [a=11 b=62 c=124 d=73] -- settable/void-call (inferred)
  if e[19] then do return end else goto L_22 end
  ::L_22::
  goto L_11
  if e[5] then goto L_96 else goto L_24 end
  ::L_25::
  goto L_40
  e[22] = {}  -- NEWTABLE [a=22 b=0 c=0 d=nil]
  e[21] = {}  -- NEWTABLE [a=21 b=0 c=0 d=nil]
  e[24] = {}  -- NEWTABLE [a=24 b=0 c=0 d=nil]
  e[24][K(81)] = e[8]  -- SETTABLE [a=24 b=81 c=8 d=7] -- settable/void-call (inferred)
  e[21][K(81)] = e[4]  -- SETTABLE [a=21 b=81 c=4 d=7] -- settable/void-call (inferred)
  e[22][K(111)] = e[10]  -- SETTABLE [a=22 b=111 c=10 d=3] -- settable/void-call (inferred)
  call(e[27], e[20])  -- CALL? [a=27 b=0 c=20 d=nil] -- void call
  goto L_33
  e[24] = {}  -- NEWTABLE [a=24 b=0 c=0 d=nil]
  e[22] = {}  -- NEWTABLE [a=22 b=0 c=0 d=nil]
  e[24][K(89)] = e[79]  -- SETTABLE [a=24 b=89 c=79 d=40] -- settable/void-call (inferred)
  e[22][K(98)] = e[33]  -- SETTABLE [a=22 b=98 c=33 d=64] -- settable/void-call (inferred)
  e[27][K(198)] = e[20]  -- SETTABLE/CALL [a=27 b=198 c=20 d=nil] -- settable/void-call (inferred)
  ::L_39::
  goto L_39
  ::L_40::
  e[0][K(77)] = e[0]  -- SETTABLE/CALL [a=0 b=77 c=0 d=nil] -- settable/void-call (inferred)
  e[0] = {}  -- NEWTABLE [a=0 b=4 c=0 d=nil]
  call(e[5], e[86])  -- CALL [a=5 b=124 c=86 d=nil] -- void call
  e[123][K(1)] = e[21]  -- SETTABLE/CALL [a=123 b=1 c=21 d=nil] -- settable/void-call (inferred)
  e[109][K(176)] = e[18]  -- SETTABLE/CALL [a=109 b=176 c=18 d=nil] -- settable/void-call (inferred)
  e[149] = K(4)  -- LOADK_S [a=149 b=4 c=88 d=nil]
  e[89][K(2)] = e[84]  -- SETTABLE/CALL [a=89 b=2 c=84 d=nil] -- settable/void-call (inferred)
  e[100][K(135)] = e[1102]  -- SETTABLE/CALL [a=100 b=135 c=1102 d=nil] -- settable/void-call (inferred)
  call(e[139], e[135])  -- CALL [a=139 b=43 c=135 d=nil] -- void call
  call(e[5], e[250])  -- CALL [a=5 b=241 c=250 d=nil] -- void call
  e[5] = e[4][K(0)]  -- GETTABLE/CLOSURE? [a=4 b=0 c=5 d=nil]
  e[6] = e[41][K(0)]  -- GETINDEX? [a=41 b=0 c=6 d=nil]
  if e[5] then do return end else goto L_53 end
  ::L_53::
  goto L_58
  ::L_54::
  goto L_73
  e[8] = e[8][K(2)]  -- GETTABLE [a=8 b=2 c=1102 d=nil]
  e[6] = false  -- LOADK_N [a=0 b=6 c=0 d=nil]
  e[5] = K(0)  -- LOADK_N [a=0 b=0 c=5 d=nil]
  ::L_58::
  goto L_22
  e[5] = e[5][K(147)]  -- GETTABLE [a=5 b=147 c=2367 d=nil]
  e[6] = e[6][K(2)]  -- GETTABLE [a=6 b=2 c=102 d=nil]
  e[0] = (e[242] == e[154])  -- COMPARE [a=242 b=0 c=154 d=nil]
  ::L_62::
  goto L_54
  e[23] = {}  -- NEWTABLE [a=0 b=23 c=0 d=nil]
  e[22] = {}  -- NEWTABLE [a=22 b=0 c=0 d=nil]
  e[24] = {}  -- NEWTABLE [a=24 b=0 c=0 d=nil]
  e[24][K(122)] = e[461]  -- SETTABLE [a=24 b=122 c=461 d=21] -- settable/void-call (inferred)
  e[23][K(22)] = e[4]  -- SETTABLE [a=23 b=22 c=4 d=15] -- settable/void-call (inferred)
  e[22][K(34)] = e[368]  -- SETTABLE [a=22 b=34 c=368 d=63] -- settable/void-call (inferred)
  call(e[27], e[20])  -- CALL? [a=27 b=0 c=20 d=nil] -- void call
  goto L_72
  ::L_73::
  goto L_4
  e[17] = K(13)  -- LOADK_S [a=0 b=13 c=17 d=nil]
  e[18] = K(1403)  -- LOADK [a=18 b=1403 c=0 d=<h]
  e[17] = K(0)  -- LOADK_N [a=0 b=0 c=17 d=nil]
  goto L_12
  e[5] = e[5][K(2)]  -- GETTABLE [a=5 b=2 c=25 d=nil]
  do return end  -- JMP/RETURN [a=0 b=0 c=5 d=nil]
  ::L_80::
  goto L_96
  call(e[235], e[211])  -- CALL [a=235 b=208 c=211 d=nil] -- void call
  e[17][K(1480)] = e[165]  -- SETTABLE/CALL [a=17 b=1480 c=165 d=142] -- settable/void-call (inferred)
  e[78] = K(147)  -- LOADK_S [a=78 b=147 c=0 d=nil]
  ::L_84::
  goto L_62
  e[23] = {}  -- NEWTABLE [a=0 b=23 c=0 d=nil]
  e[24] = {}  -- NEWTABLE [a=24 b=0 c=0 d=nil]
  e[22] = {}  -- NEWTABLE [a=22 b=0 c=0 d=nil]
  e[21] = {}  -- NEWTABLE [a=21 b=0 c=0 d=nil]
  e[21][K(95)] = e[81]  -- SETTABLE [a=21 b=95 c=81 d=61] -- settable/void-call (inferred)
  e[24][K(95)] = e[112]  -- SETTABLE [a=24 b=95 c=112 d=61] -- settable/void-call (inferred)
  e[23][K(95)] = e[111]  -- SETTABLE [a=23 b=95 c=111 d=61] -- settable/void-call (inferred)
  e[22][K(3)] = e[124]  -- SETTABLE [a=22 b=3 c=124 d=12] -- settable/void-call (inferred)
  e[27][K(210)] = e[20]  -- SETTABLE/CALL [a=27 b=210 c=20 d=nil] -- settable/void-call (inferred)
  goto L_94
  if e[17] then goto L_12 end  -- back-edge (loop)
  ::L_96::
  goto L_53
  goto L_1
end

local function proto84(...)  -- 92 instrs, 42 blocks (structured)
  local e = regs
  ::L_1::
  ::L_14::
  ::L_22::
  ::L_11::
  ::L_91::
  ::L_69::
  ::L_85::
  ::L_73::
  ::L_29::
  goto L_1
  e[20] = {}  -- NEWTABLE [a=20 b=0 c=0 d=nil]
  e[22] = {}  -- NEWTABLE [a=0 b=22 c=0 d=nil]
  e[21] = {}  -- NEWTABLE [a=21 b=0 c=0 d=nil]
  e[23] = {}  -- NEWTABLE [a=23 b=0 c=0 d=nil]
  e[23][K(72)] = e[2049]  -- SETTABLE [a=23 b=72 c=2049 d=89] -- settable/void-call (inferred)
  e[22][K(72)] = e[4]  -- SETTABLE [a=22 b=72 c=4 d=89] -- settable/void-call (inferred)
  e[20][K(72)] = e[99]  -- SETTABLE [a=20 b=72 c=99 d=89] -- settable/void-call (inferred)
  e[21][K(66)] = e[50]  -- SETTABLE [a=21 b=66 c=50 d=74] -- settable/void-call (inferred)
  call(e[26], e[19])  -- CALL? [a=26 b=0 c=19 d=nil] -- void call
  goto L_11
  goto L_34
  if e[30] then do return end else goto L_14 end
  e[21] = {}  -- NEWTABLE [a=21 b=0 c=0 d=nil]
  e[20] = {}  -- NEWTABLE [a=20 b=0 c=0 d=nil]
  e[20][K(3)] = e[4]  -- SETTABLE [a=20 b=3 c=4 d=12] -- settable/void-call (inferred)
  e[21][K(60)] = e[99]  -- SETTABLE [a=21 b=60 c=99 d=35] -- settable/void-call (inferred)
  e[21][K(73)] = e[103]  -- SETTABLE [a=21 b=73 c=103 d=23] -- settable/void-call (inferred)
  call(e[26], e[19])  -- CALL? [a=26 b=0 c=19 d=nil] -- void call
  goto L_22
  call(e[3], e[0])  -- CALL? [a=3 b=0 c=0 d=nil] -- void call
  call(e[9], e[6])  -- CALL? [a=9 b=8 c=6 d=nil] -- void call
  -- UNKNOWN op? [a=0 b=0 c=0 d=nil]
  ::L_27::
  goto L_39
  e[0][K(0)] = e[0]  -- SETTABLE/CALL [a=0 b=0 c=0 d=nil] -- settable/void-call (inferred)
  goto L_29
  ::L_30::
  if e[1] then goto L_30 end  -- back-edge (loop)
  if e[0] then goto L_83 end
  ::L_32::
  goto L_27
  e[5][K(1)] = e[0]  -- SETTABLE/CALL [a=5 b=1 c=0 d=nil] -- settable/void-call (inferred)
  ::L_34::
  goto L_81
  e[177] = e[0][K(177)]  -- GETTABLE/CLOSURE [a=0 b=177 c=0 d=nil]
  e[5] = e[5]  -- MOVE [a=5 b=5 c=1110 d=nil]
  if e[5] then do return end else goto L_38 end
  ::L_38::
  goto L_30
  ::L_39::
  goto L_74
  e[1] = K(93)  -- LOADK [a=1 b=93 c=0 d=2]
  e[0] = e[0][K(0)]  -- GETTABLE/CLOSURE [a=0 b=0 c=1 d=nil]
  e[1] = {}  -- NEWTABLE [a=0 b=0 c=1 d=nil]
  e[2] = K(16)  -- LOADK [a=2 b=16 c=0 d=1]
  -- UNKNOWN op? [a=3 b=0 c=0 d=nil]
  e[4] = K(16)  -- LOADK [a=4 b=16 c=0 d=1]
  ::L_46::
  if e[2] then goto L_81 end
  e[12] = {}  -- NEWTABLE [a=12 b=0 c=0 d=nil]
  e[10] = {}  -- NEWTABLE [a=10 b=0 c=0 d=nil]
  e[16] = K(20)  -- LOADK_S [a=0 b=20 c=16 d=nil]
  e[17] = K(19)  -- LOADK_S [a=0 b=19 c=17 d=nil]
  -- UNKNOWN op? [a=225 b=2186 c=0 d=86]
  e[17] = 4294967209  -- LOADK_N [a=0 b=0 c=17 d=nil]
  e[18] = 27  -- LOADK [a=18 b=2289 c=0 d=27]
  e[16] = 4294964543  -- LOADK_N [a=0 b=16 c=0 d=nil]
  e[16] = e[16] + -4294941339  -- ADD [a=16 b=2093 c=16 d=-4294941339]  -- = 23204
  e[16] = arith(e[16], e[1764])  -- UNOP/arith? [a=16 b=16 c=1764 d=nil]  -- = 205
  call(e[16], e[10])  -- CALL [a=16 b=12 c=10 d=nil] -- void call
  e[10][K(1568)] = e[85]  -- SETTABLE [a=10 b=1568 c=85 d=86] -- settable/void-call (inferred)
  call(e[18], e[8])  -- CALL? [a=18 b=0 c=8 d=nil] -- void call
  ::L_60::
  goto L_60
  e[22] = {}  -- NEWTABLE [a=0 b=22 c=0 d=nil]
  e[21] = {}  -- NEWTABLE [a=21 b=0 c=0 d=nil]
  e[23] = {}  -- NEWTABLE [a=23 b=0 c=0 d=nil]
  e[23][K(128)] = e[8]  -- SETTABLE [a=23 b=128 c=8 d=51] -- settable/void-call (inferred)
  e[22][K(128)] = e[114]  -- SETTABLE [a=22 b=128 c=114 d=51] -- settable/void-call (inferred)
  e[21][K(22)] = e[64]  -- SETTABLE [a=21 b=22 c=64 d=15] -- settable/void-call (inferred)
  call(e[26], e[19])  -- CALL? [a=26 b=0 c=19 d=nil] -- void call
  goto L_69
  e[1] = 41  -- LOADK [a=1 b=933 c=0 d=41]
  e[2] = 152  -- LOADK [a=2 b=436 c=0 d=152]
  -- UNKNOWN op? [a=3 b=2200 c=0 d=111]
  goto L_73
  ::L_74::
  goto L_1
  e[21] = {}  -- NEWTABLE [a=21 b=0 c=0 d=nil]
  e[22] = {}  -- NEWTABLE [a=0 b=22 c=0 d=nil]
  e[21][K(104)] = e[4]  -- SETTABLE [a=21 b=104 c=4 d=25] -- settable/void-call (inferred)
  e[22][K(61)] = e[4]  -- SETTABLE [a=22 b=61 c=4 d=27] -- settable/void-call (inferred)
  e[21][K(33)] = e[46]  -- SETTABLE [a=21 b=33 c=46 d=39] -- settable/void-call (inferred)
  call(e[26], e[19])  -- CALL? [a=26 b=0 c=19 d=nil] -- void call
  ::L_81::
  goto L_87
  ::L_82::
  if e[0] then goto L_32 end  -- back-edge (loop)
  ::L_83::
  goto L_82
  if e[12] then do return end else goto L_85 end
  goto L_46
  ::L_87::
  -- UNKNOWN op? [a=2 b=296 c=171 d=nil]
  e[5] = e[343][K(0)]  -- GETINDEX? [a=343 b=0 c=5 d=nil]
  -- UNKNOWN op? [a=112 b=0 c=171 d=nil]
  call(e[6], e[3])  -- CALL? [a=6 b=0 c=3 d=nil] -- void call
  goto L_91
  goto L_38
end

local function proto85(...)  -- 59 instrs, 20 blocks (structured)
  local e = regs
  ::L_1::
  ::L_22::
  ::L_51::
  ::L_55::
  ::L_10::
  goto L_1
  e[0] = {}  -- NEWTABLE [a=0 b=1 c=0 d=nil]
  call(e[2], e[0])  -- CALL [a=2 b=0 c=0 d=nil] -- void call
  e[0][K(0)] = e[247]  -- SETTABLE/CALL [a=0 b=0 c=247 d=nil] -- settable/void-call (inferred)
  e[243][K(1)] = e[2]  -- SETTABLE/CALL [a=243 b=1 c=2 d=nil] -- settable/void-call (inferred)
  e[0][K(2)] = e[2]  -- SETTABLE/CALL [a=0 b=2 c=2 d=nil] -- settable/void-call (inferred)
  e[0][K(3)] = e[2]  -- SETTABLE/CALL [a=0 b=3 c=2 d=nil] -- settable/void-call (inferred)
  e[0][K(4)] = e[2]  -- SETTABLE/CALL [a=0 b=4 c=2 d=nil] -- settable/void-call (inferred)
  e[0][K(5)] = e[2]  -- SETTABLE/CALL [a=0 b=5 c=2 d=nil] -- settable/void-call (inferred)
  goto L_10
  e[11] = K(15)  -- LOADK_S [a=0 b=15 c=11 d=nil]
  e[12] = "'@"  -- LOADK [a=12 b=1335 c=0 d='@]
  e[11] = 2  -- LOADK_N [a=0 b=103 c=11 d=nil]
  ::L_14::
  goto L_34
  e[18] = {}  -- NEWTABLE [a=18 b=0 c=0 d=nil]
  e[17] = {}  -- NEWTABLE [a=0 b=17 c=0 d=nil]
  e[16] = {}  -- NEWTABLE [a=16 b=0 c=0 d=nil]
  e[17][K(99)] = e[4]  -- SETTABLE [a=17 b=99 c=4 d=5] -- settable/void-call (inferred)
  e[18][K(99)] = e[40]  -- SETTABLE [a=18 b=99 c=40 d=5] -- settable/void-call (inferred)
  e[16][K(35)] = e[128]  -- SETTABLE [a=16 b=35 c=128 d=53] -- settable/void-call (inferred)
  call(e[21], e[14])  -- CALL? [a=21 b=0 c=14 d=nil] -- void call
  goto L_22
  ::L_23::
  goto L_23
  e[15] = {}  -- NEWTABLE [a=15 b=0 c=0 d=nil]
  e[17] = {}  -- NEWTABLE [a=0 b=17 c=0 d=nil]
  e[18] = {}  -- NEWTABLE [a=18 b=0 c=0 d=nil]
  e[16] = {}  -- NEWTABLE [a=16 b=0 c=0 d=nil]
  e[16][K(118)] = e[4]  -- SETTABLE [a=16 b=118 c=4 d=13] -- settable/void-call (inferred)
  e[15][K(116)] = e[4]  -- SETTABLE [a=15 b=116 c=4 d=45] -- settable/void-call (inferred)
  e[18][K(60)] = e[87]  -- SETTABLE [a=18 b=60 c=87 d=35] -- settable/void-call (inferred)
  e[17][K(30)] = e[4]  -- SETTABLE [a=17 b=30 c=4 d=46] -- settable/void-call (inferred)
  e[16][K(73)] = e[52]  -- SETTABLE [a=16 b=73 c=52 d=23] -- settable/void-call (inferred)
  call(e[21], e[14])  -- CALL? [a=21 b=0 c=14 d=nil] -- void call
  ::L_34::
  goto L_58
  -- UNKNOWN op? [a=11 b=605 c=11 d=7537]
  e[11] = arith(e[11], e[2057])  -- UNOP/arith? [a=11 b=11 c=2057 d=nil]  -- = 0
  call(e[11], e[9])  -- CALL [a=11 b=4 c=9 d=nil] -- void call
  e[5][K(101)] = e[128]  -- SETTABLE [a=5 b=101 c=128 d=59] -- settable/void-call (inferred)
  call(e[13], e[3])  -- CALL? [a=13 b=0 c=3 d=nil] -- void call
  ::L_40::
  goto L_52
  e[4] = {}  -- NEWTABLE [a=4 b=0 c=0 d=nil]
  e[5] = {}  -- NEWTABLE [a=5 b=0 c=0 d=nil]
  e[11] = K(18)  -- LOADK_S [a=0 b=18 c=11 d=nil]
  e[12] = K(13)  -- LOADK_S [a=0 b=13 c=12 d=nil]
  e[13] = ">i2JB  >"  -- LOADK [a=13 b=296 c=222 d=>i2JB]
  e[12] = 7  -- LOADK_N [a=238 b=0 c=12 d=nil]
  e[13] = 24  -- LOADK [a=13 b=1451 c=0 d=24]
  e[11] = 117440512  -- LOADK_N [a=0 b=11 c=0 d=nil]
  e[11] = (e[992] == e[11])  -- COMPARE [a=992 b=11 c=11 d=nil]  -- = false
  if e[11] then goto L_53 else goto L_51 end
  ::L_52::
  goto L_1
  ::L_53::
  goto L_14
  if e[11] then goto L_34 else goto L_55 end  -- back-edge (loop)
  e[11] = K(1900)  -- LOADK [a=11 b=1900 c=0 d=451]
  goto L_53
  ::L_58::
  -- UNKNOWN op? [a=124 b=426 c=82 d=nil]
  goto L_40
end

local function proto86(...)  -- 72 instrs, 22 blocks (structured)
  local e = regs
  ::L_1::
  ::L_25::
  ::L_53::
  ::L_7::
  e[227][K(52)] = e[0]  -- SETTABLE/CALL [a=227 b=52 c=0 d=nil] -- settable/void-call (inferred)
  e[23] = {}  -- NEWTABLE [a=23 b=0 c=0 d=nil]
  e[24] = {}  -- NEWTABLE [a=24 b=0 c=0 d=nil]
  e[23][K(105)] = e[4]  -- SETTABLE [a=23 b=105 c=4 d=56] -- settable/void-call (inferred)
  e[24][K(35)] = e[100]  -- SETTABLE [a=24 b=35 c=100 d=53] -- settable/void-call (inferred)
  call(e[29], e[22])  -- CALL? [a=29 b=0 c=22 d=nil] -- void call
  ::L_13::
  goto L_1
  e[0][K(0)] = e[0]  -- SETTABLE/CALL [a=0 b=0 c=0 d=nil] -- settable/void-call (inferred)
  e[1] = call(e[1], e[0])  -- GETGLOBAL/CALL [a=1 b=1441 c=0 d=string]
  e[66] = e[66][K(1)]  -- GETTABLE [a=66 b=1 c=1003 d=nil]
  -- UNKNOWN op? [a=2 b=1441 c=0 d=string]
  goto L_7
  e[2] = e[2][K(2)]  -- GETTABLE [a=2 b=2 c=508 d=nil]
  e[4] = e[2][K(0)]  -- GETTABLE/CLOSURE? [a=2 b=0 c=4 d=nil]
  e[5] = " "  -- LOADK [a=5 b=2292 c=0]
  e[6] = 8  -- LOADK [a=6 b=84 c=0 d=8]
  e[4] = "        "  -- LOADK_N [a=0 b=4 c=0 d=nil]
  e[5] = e[321][K(0)]  -- GETINDEX? [a=321 b=0 c=5 d=nil]
  e[6] = e[231][K(0)]  -- GETINDEX? [a=231 b=0 c=6 d=nil]
  e[7] = e[328][K(0)]  -- GETINDEX? [a=328 b=0 c=7 d=nil]
  e[8] = e[337][K(0)]  -- GETINDEX? [a=337 b=0 c=8 d=nil]
  e[9] = e[187][K(0)]  -- GETINDEX? [a=187 b=0 c=9 d=nil]
  goto L_25
  ::L_26::
  goto L_28
  goto L_57
  ::L_28::
  -- UNKNOWN op? [a=357 b=494 c=44 d=nil]
  e[23] = {}  -- NEWTABLE [a=23 b=0 c=0 d=nil]
  e[24] = {}  -- NEWTABLE [a=24 b=0 c=0 d=nil]
  e[25] = {}  -- NEWTABLE [a=0 b=25 c=0 d=nil]
  e[26] = {}  -- NEWTABLE [a=26 b=0 c=0 d=nil]
  e[26][K(81)] = e[79]  -- SETTABLE [a=26 b=81 c=79 d=7] -- settable/void-call (inferred)
  e[25][K(81)] = e[4]  -- SETTABLE [a=25 b=81 c=4 d=7] -- settable/void-call (inferred)
  e[23][K(91)] = e[117]  -- SETTABLE [a=23 b=91 c=117 d=62] -- settable/void-call (inferred)
  e[25][K(91)] = e[4]  -- SETTABLE [a=25 b=91 c=4 d=62] -- settable/void-call (inferred)
  e[24][K(91)] = e[4]  -- SETTABLE [a=24 b=91 c=4 d=62] -- settable/void-call (inferred)
  e[26][K(23)] = e[1176]  -- SETTABLE [a=26 b=23 c=1176 d=6] -- settable/void-call (inferred)
  e[24][K(19)] = e[19]  -- SETTABLE [a=24 b=19 c=19 d=26] -- settable/void-call (inferred)
  call(e[29], e[22])  -- CALL? [a=29 b=0 c=22 d=nil] -- void call
  ::L_41::
  goto L_26
  e[24] = {}  -- NEWTABLE [a=24 b=0 c=0 d=nil]
  e[23] = {}  -- NEWTABLE [a=23 b=0 c=0 d=nil]
  e[24][K(53)] = e[4]  -- SETTABLE [a=24 b=53 c=4 d=50] -- settable/void-call (inferred)
  e[23][K(53)] = e[42]  -- SETTABLE [a=23 b=53 c=42 d=50] -- settable/void-call (inferred)
  e[24][K(71)] = e[71]  -- SETTABLE [a=24 b=71 c=71 d=49] -- settable/void-call (inferred)
  call(e[29], e[22])  -- CALL? [a=29 b=0 c=22 d=nil] -- void call
  ::L_48::
  goto L_41
  e[212] = e[9][K(170)]  -- GETTABLE/CLOSURE? [a=9 b=170 c=212 d=nil]
  do return end  -- JMP/RETURN [a=0 b=0 c=10 d=nil]
  goto L_53
  e[10] = e[9][K(0)]  -- GETTABLE/CLOSURE? [a=9 b=0 c=10 d=nil]
  do return end  -- JMP/RETURN [a=10 b=0 c=0 d=nil]
  if e[10] then goto L_1 end  -- back-edge (loop)
  ::L_57::
  goto L_48
  e[13] = {}  -- NEWTABLE [a=13 b=0 c=0 d=nil]
  e[14] = {}  -- NEWTABLE [a=0 b=14 c=0 d=nil]
  e[19] = K(17)  -- LOADK_S [a=0 b=17 c=19 d=nil]
  e[20] = 254  -- LOADK [a=20 b=206 c=0 d=254]
  e[183] = 1  -- LOADK_N [a=169 b=136 c=183 d=nil]
  e[20] = K(15)  -- LOADK_S [a=0 b=15 c=20 d=nil]
  e[21] = "207"  -- LOADK [a=21 b=2308 c=0 d=�]
  e[20] = 1  -- LOADK_N [a=0 b=0 c=20 d=nil]
  e[19] = arith(e[19], e[20])  -- ARITH [a=19 b=19 c=20 d=nil]  -- = 2
  e[19] = e[19] + 11908  -- ADD [a=19 b=604 c=19 d=11908]  -- = 11910
  e[19] = arith(e[19], e[1171])  -- UNOP/arith? [a=19 b=19 c=1171 d=nil]  -- = 1
  call(e[19], e[99])  -- CALL [a=19 b=14 c=99 d=nil] -- void call
  e[13][K(61)] = e[118]  -- SETTABLE [a=13 b=61 c=118 d=27] -- settable/void-call (inferred)
  call(e[21], e[11])  -- CALL? [a=21 b=0 c=11 d=nil] -- void call
  goto L_13
end

local function proto87(...)  -- 224 instrs, 116 blocks (structured)
  local e = regs
  ::L_1::
  ::L_35::
  ::L_175::
  ::L_44::
  ::L_83::
  ::L_41::
  if e[6] then goto L_222 end
  ::L_42::
  ::L_143::
  ::L_48::
  ::L_152::
  ::L_189::
  ::L_131::
  ::L_213::
  ::L_98::
  ::L_161::
  ::L_33::
  ::L_14::
  ::L_27::
  goto L_1
  ::L_222::
  ::L_139::
  ::L_55::
  if e[1] then goto L_137 end
  e[0][K(0)] = e[0]  -- SETTABLE/CALL [a=0 b=0 c=0 d=nil] -- settable/void-call (inferred)
  e[1] = e[1][K(1)]  -- GETTABLE/CLOSURE [a=1 b=1 c=0 d=nil]
  e[2] = e[2][K(2)]  -- GETTABLE/CLOSURE [a=2 b=2 c=0 d=nil]
  do return end  -- JMP/RETURN [a=2 b=0 c=0 d=nil]
  ::L_137::
  if e[6] then goto L_159 end
  -- UNKNOWN op? [a=0 b=36 c=1 d=nil]
  goto L_139
  ::L_159::
  ::L_85::
  goto L_159
  e[32] = {}  -- NEWTABLE [a=32 b=0 c=0 d=nil]
  e[33] = {}  -- NEWTABLE [a=33 b=0 c=0 d=nil]
  e[32][K(1528)] = e[4]  -- SETTABLE [a=32 b=1528 c=4 d=118] -- settable/void-call (inferred)
  e[33][K(326)] = e[2421]  -- SETTABLE [a=33 b=326 c=2421 d=223] -- settable/void-call (inferred)
  call(e[38], e[31])  -- CALL? [a=38 b=0 c=31 d=nil] -- void call
  ::L_7::
  goto L_182
  e[15] = e[1][K(15)]  -- GETTABLE/CLOSURE [a=1 b=15 c=62 d=nil]
  e[16] = e[2][K(16)]  -- GETTABLE/CLOSURE [a=2 b=16 c=0 d=nil]
  do return end  -- JMP/RETURN [a=16 b=0 c=0 d=nil]
  e[17] = e[2][K(17)]  -- GETTABLE/CLOSURE [a=2 b=17 c=0 d=nil]
  if e[17] then goto L_1 end  -- back-edge (loop)
  do return end  -- JMP/RETURN [a=0 b=0 c=15 d=nil]
  ::L_15::
  goto L_61
  do return end  -- JMP/RETURN [a=16 b=0 c=0 d=nil]
  e[17] = e[0][K(17)]  -- GETTABLE/CLOSURE [a=0 b=17 c=0 d=nil]
  if e[17] then goto L_1 end  -- back-edge (loop)
  dataop(e[15], e[0], e[0])  -- DATAOP [a=15 b=0 c=0 d=nil]
  e[14][K(15)] = e[5]  -- SETTABLE/CALL [a=14 b=15 c=5 d=nil] -- settable/void-call (inferred)
  ::L_22::
  goto L_208
  ::L_23::
  goto L_7
  e[108] = e[2][K(108)]  -- GETTABLE/CLOSURE [a=2 b=108 c=0 d=nil]
  do return end  -- JMP/RETURN [a=14 b=0 c=0 d=nil]
  if e[14] then goto L_174 else goto L_27 end
  e[26][K(15)] = e[78]  -- SETTABLE/CALL [a=26 b=15 c=78 d=nil] -- settable/void-call (inferred)
  e[14] = e[0][K(14)]  -- GETTABLE/CLOSURE [a=0 b=14 c=0 d=nil]
  do return end  -- JMP/RETURN [a=14 b=0 c=0 d=nil]
  ::L_31::
  goto L_209
  e[27] = K(360)  -- LOADK [a=27 b=360 c=0 d=118]
  goto L_33
  e[0][K(0)] = e[0]  -- SETTABLE/CALL [a=0 b=0 c=0 d=nil] -- settable/void-call (inferred)
  goto L_35
  e[235] = {}  -- NEWTABLE [a=0 b=112 c=235 d=nil]
  e[6] = 0  -- LOADK [a=6 b=4 c=0 d=0]
  e[7] = 255  -- LOADK [a=7 b=2263 c=0 d=255]
  e[8] = 1  -- LOADK [a=8 b=16 c=0 d=1]
  goto L_41
  if e[0] then goto L_23 else goto L_44 end  -- back-edge (loop)
  e[14][K(15)] = e[5]  -- SETTABLE/CALL [a=14 b=15 c=5 d=nil] -- settable/void-call (inferred)
  e[254] = e[3][K(254)]  -- GETTABLE/CLOSURE [a=3 b=254 c=0 d=nil]
  -- UNKNOWN op? [a=2 b=15 c=242 d=nil]
  goto L_48
  e[161] = e[1][K(188)]  -- GETINDEX? [a=1 b=188 c=161 d=nil]
  e[11] = e[0][K(11)]  -- GETTABLE/CLOSURE [a=0 b=11 c=0 d=nil]
  do return end  -- JMP/RETURN [a=11 b=0 c=0 d=nil]
  e[12] = e[0][K(12)]  -- GETTABLE/CLOSURE [a=0 b=12 c=0 d=nil]
  ::L_53::
  goto L_67
  e[3] = 1  -- LOADK [a=3 b=16 c=0 d=1]
  goto L_55
  e[3] = e[0][K(3)]  -- GETTABLE/CLOSURE [a=0 b=3 c=0 d=nil]
  ::L_61::
  goto L_172
  e[33] = {}  -- NEWTABLE [a=33 b=0 c=0 d=nil]
  e[34] = {}  -- NEWTABLE [a=0 b=34 c=0 d=nil]
  e[34][K(66)] = e[32]  -- SETTABLE [a=34 b=66 c=32 d=74] -- settable/void-call (inferred)
  e[33][K(22)] = e[10]  -- SETTABLE [a=33 b=22 c=10 d=15] -- settable/void-call (inferred)
  call(e[38], e[31])  -- CALL? [a=38 b=0 c=31 d=nil] -- void call
  ::L_67::
  goto L_72
  if e[12] then goto L_1 end  -- back-edge (loop)
  do return end  -- JMP/RETURN [a=0 b=0 c=10 d=nil]
  e[11] = e[1][K(11)]  -- GETTABLE/CLOSURE [a=1 b=11 c=0 d=nil]
  goto L_165
  ::L_72::
  -- UNKNOWN op? [a=131 b=401 c=52 d=nil]
  e[28] = K(15)  -- LOADK_S [a=0 b=15 c=28 d=nil]
  e[129] = K(340)  -- LOADK [a=129 b=340 c=0]
  e[28] = K(0)  -- LOADK_N [a=0 b=0 c=28 d=nil]
  e[29] = K(893)  -- LOADK [a=29 b=893 c=0 d=150]
  e[26] = K(26)  -- LOADK_N [a=0 b=26 c=4 d=nil]
  e[26] = e[26] + 16149  -- ADD [a=26 b=1979 c=26 d=16149]
  e[26] = arith(e[26], e[1147])  -- UNOP/arith? [a=26 b=26 c=1147 d=nil]
  call(e[26], e[30])  -- CALL [a=26 b=20 c=30 d=nil] -- void call
  e[20][K(108)] = e[1816]  -- SETTABLE [a=20 b=108 c=1816 d=16] -- settable/void-call (inferred)
  call(e[30], e[18])  -- CALL? [a=30 b=0 c=18 d=nil] -- void call
  goto L_83
  e[0][K(0)] = e[0]  -- SETTABLE/CALL [a=0 b=0 c=0 d=nil] -- settable/void-call (inferred)
  goto L_85
  e[20] = {}  -- NEWTABLE [a=20 b=0 c=0 d=nil]
  e[26] = K(11)  -- LOADK_S [a=0 b=11 c=26 d=nil]
  e[27] = K(9)  -- LOADK_S [a=0 b=9 c=27 d=nil]
  e[28] = K(716)  -- LOADK [a=28 b=716 c=0]
  e[29] = K(78)  -- LOADK [a=29 b=78 c=0 d=3]
  e[30] = K(78)  -- LOADK [a=30 b=78 c=0 d=3]
  e[27] = K(27)  -- LOADK_N [a=0 b=27 c=4 d=nil]
  e[28] = K(15)  -- LOADK_S [a=0 b=15 c=28 d=nil]
  e[29] = K(1731)  -- LOADK [a=29 b=1731 c=0 d=*]
  e[28] = K(0)  -- LOADK_N [a=0 b=0 c=28 d=nil]
  dataop(e[27], e[27], e[28])  -- DATAOP [a=27 b=27 c=28 d=nil]
  if e[27] then goto L_114 else goto L_98 end
  e[15] = e[2][K(15)]  -- GETTABLE/CLOSURE [a=2 b=15 c=0 d=nil]
  do return end  -- JMP/RETURN [a=15 b=0 c=0 d=nil]
  e[34] = {}  -- NEWTABLE [a=0 b=34 c=0 d=nil]
  e[35] = {}  -- NEWTABLE [a=35 b=0 c=0 d=nil]
  e[32] = {}  -- NEWTABLE [a=32 b=0 c=0 d=nil]
  e[33] = {}  -- NEWTABLE [a=33 b=0 c=0 d=nil]
  e[33][K(247)] = e[4]  -- SETTABLE [a=33 b=247 c=4 d=191] -- settable/void-call (inferred)
  e[34][K(247)] = e[22]  -- SETTABLE [a=34 b=247 c=22 d=191] -- settable/void-call (inferred)
  e[35][K(247)] = e[346]  -- SETTABLE [a=35 b=247 c=346 d=191] -- settable/void-call (inferred)
  e[35][K(40)] = e[122]  -- SETTABLE [a=35 b=40 c=122 d=47] -- settable/void-call (inferred)
  e[32][K(40)] = e[4]  -- SETTABLE [a=32 b=40 c=4 d=47] -- settable/void-call (inferred)
  e[33][K(1454)] = e[22]  -- SETTABLE [a=33 b=1454 c=22 d=175] -- settable/void-call (inferred)
  call(e[38], e[31])  -- CALL? [a=38 b=0 c=31 d=nil] -- void call
  ::L_113::
  goto L_15
  ::L_114::
  goto L_196
  if e[27] then goto L_14 end  -- back-edge (loop)
  ::L_116::
  goto L_31
  e[10] = e[1][K(10)]  -- GETTABLE/CLOSURE [a=1 b=10 c=0 d=nil]
  e[11] = e[0][K(11)]  -- GETTABLE/CLOSURE [a=0 b=11 c=20 d=nil]
  do return end  -- JMP/RETURN [a=11 b=0 c=0 d=nil]
  e[12] = e[0][K(12)]  -- GETTABLE/CLOSURE [a=0 b=12 c=0 d=nil]
  if e[12] then goto L_1 end  -- back-edge (loop)
  do return end  -- JMP/RETURN [a=0 b=0 c=10 d=nil]
  e[11] = e[1][K(11)]  -- GETTABLE/CLOSURE [a=1 b=11 c=0 d=nil]
  e[12] = e[0][K(12)]  -- GETTABLE/CLOSURE [a=0 b=12 c=0 d=nil]
  do return end  -- JMP/RETURN [a=12 b=0 c=0 d=nil]
  e[13] = e[0][K(13)]  -- GETTABLE/CLOSURE [a=0 b=13 c=0 d=nil]
  ::L_127::
  goto L_194
  e[10] = K(4)  -- LOADK [a=10 b=4 c=0 d=0]
  e[11] = K(2263)  -- LOADK [a=11 b=2263 c=0 d=255]
  e[12] = K(16)  -- LOADK [a=12 b=16 c=0 d=1]
  goto L_131
  e[0][K(0)] = e[0]  -- SETTABLE/CALL [a=0 b=0 c=0 d=nil] -- settable/void-call (inferred)
  e[6] = K(16)  -- LOADK [a=6 b=16 c=0 d=1]
  e[7] = e[0][K(7)]  -- GETTABLE/CLOSURE [a=0 b=7 c=0 d=nil]
  do return end  -- JMP/RETURN [a=7 b=0 c=0 d=nil]
  e[8] = K(16)  -- LOADK [a=8 b=16 c=0 d=1]
  goto L_137
  if e[13] then goto L_1 end  -- back-edge (loop)
  do return end  -- JMP/RETURN [a=0 b=0 c=11 d=nil]
  e[10][K(11)] = e[5]  -- SETTABLE/CALL [a=10 b=11 c=5 d=nil] -- settable/void-call (inferred)
  goto L_143
  e[33] = {}  -- NEWTABLE [a=33 b=0 c=0 d=nil]
  e[34] = {}  -- NEWTABLE [a=0 b=34 c=0 d=nil]
  e[32] = {}  -- NEWTABLE [a=32 b=0 c=0 d=nil]
  e[32][K(84)] = e[4]  -- SETTABLE [a=32 b=84 c=4 d=8] -- settable/void-call (inferred)
  e[32][K(115)] = e[99]  -- SETTABLE [a=32 b=115 c=99 d=28] -- settable/void-call (inferred)
  e[34][K(115)] = e[100]  -- SETTABLE [a=34 b=115 c=100 d=28] -- settable/void-call (inferred)
  e[33][K(59)] = e[1816]  -- SETTABLE [a=33 b=59 c=1816 d=42] -- settable/void-call (inferred)
  call(e[38], e[31])  -- CALL? [a=38 b=0 c=31 d=nil] -- void call
  goto L_152
  do return end  -- JMP/RETURN [a=15 b=0 c=0 d=nil]
  e[16] = e[0][K(16)]  -- GETTABLE/CLOSURE [a=0 b=16 c=0 d=nil]
  if e[16] then goto L_1 end  -- back-edge (loop)
  do return end  -- JMP/RETURN [a=0 b=0 c=14 d=nil]
  e[15] = {}  -- NEWTABLE [a=1 b=15 c=0 d=nil]
  e[16] = e[2][K(16)]  -- GETTABLE/CLOSURE [a=2 b=16 c=0 d=nil]
  goto L_159
  if e[0] then goto L_127 else goto L_161 end  -- back-edge (loop)
  e[27] = K(10)  -- LOADK_S [a=0 b=10 c=27 d=nil]
  e[28] = K(6)  -- LOADK_S [a=0 b=6 c=28 d=nil]
  e[27] = K(0)  -- LOADK_N [a=0 b=0 c=27 d=nil]
  ::L_165::
  goto L_114
  e[12] = e[0][K(12)]  -- GETTABLE/CLOSURE [a=0 b=12 c=0 d=nil]
  do return end  -- JMP/RETURN [a=12 b=0 c=0 d=nil]
  e[13] = e[0][K(13)]  -- GETTABLE/CLOSURE [a=0 b=13 c=0 d=nil]
  if e[13] then goto L_1 end  -- back-edge (loop)
  do return end  -- JMP/RETURN [a=0 b=0 c=11 d=nil]
  e[10][K(11)] = e[5]  -- SETTABLE/CALL [a=10 b=11 c=5 d=nil] -- settable/void-call (inferred)
  ::L_172::
  goto L_222
  if e[29] then goto L_1 end  -- back-edge (loop)
  ::L_174::
  -- UNKNOWN op? [a=1 b=0 c=0 d=nil]
  goto L_175
  e[1] = 1  -- LOADK [a=1 b=16 c=0 d=1]
  e[2] = e[0][K(2)]  -- GETTABLE/CLOSURE [a=0 b=2 c=0 d=nil]
  do return end  -- JMP/RETURN [a=2 b=0 c=0 d=nil]
  e[14] = e[0][K(14)]  -- GETTABLE/CLOSURE [a=0 b=14 c=0 d=nil]
  do return end  -- JMP/RETURN [a=14 b=0 c=0 d=nil]
  ::L_182::
  goto L_174
  if e[0] then goto L_116 end  -- back-edge (loop)
  ::L_184::
  goto L_113
  e[33] = {}  -- NEWTABLE [a=33 b=0 c=0 d=nil]
  e[33][K(124)] = e[100]  -- SETTABLE [a=33 b=124 c=100 d=24] -- settable/void-call (inferred)
  e[33][K(1228)] = e[2106]  -- SETTABLE [a=33 b=1228 c=2106 d=197] -- settable/void-call (inferred)
  call(e[38], e[31])  -- CALL? [a=38 b=0 c=31 d=nil] -- void call
  goto L_189
  e[15] = e[2][K(15)]  -- GETTABLE/CLOSURE [a=2 b=15 c=0 d=nil]
  -- UNKNOWN op? [a=79 b=68 c=0 d=nil]
  e[15] = e[15][K(5)]  -- GETTABLE/CLOSURE [a=15 b=5 c=15 d=nil]
  if e[15] then goto L_27 end  -- back-edge (loop)
  ::L_194::
  goto L_22
  ::L_196::
  if e[10] then goto L_42 end  -- back-edge (loop)
  ::L_197::
  goto L_184
  e[32] = {}  -- NEWTABLE [a=32 b=0 c=0 d=nil]
  e[33] = {}  -- NEWTABLE [a=33 b=0 c=0 d=nil]
  e[34] = {}  -- NEWTABLE [a=0 b=34 c=0 d=nil]
  e[35] = {}  -- NEWTABLE [a=35 b=0 c=0 d=nil]
  e[34][K(929)] = e[111]  -- SETTABLE [a=34 b=929 c=111 d=173] -- settable/void-call (inferred)
  e[35][K(12)] = e[126]  -- SETTABLE [a=35 b=12 c=126 d=138] -- settable/void-call (inferred)
  e[32][K(55)] = e[99]  -- SETTABLE [a=32 b=55 c=99 d=37] -- settable/void-call (inferred)
  e[33][K(55)] = e[4]  -- SETTABLE [a=33 b=55 c=4 d=37] -- settable/void-call (inferred)
  e[33][K(1896)] = e[35]  -- SETTABLE [a=33 b=1896 c=35 d=224] -- settable/void-call (inferred)
  call(e[38], e[31])  -- CALL? [a=38 b=0 c=31 d=nil] -- void call
  ::L_208::
  goto L_53
  ::L_209::
  goto L_42
  e[15] = e[2][K(15)]  -- GETTABLE/CLOSURE [a=2 b=15 c=0 d=nil]
  do return end  -- JMP/RETURN [a=15 b=0 c=0 d=nil]
  if e[15] then goto L_44 else goto L_213 end  -- back-edge (loop)
  e[35] = {}  -- NEWTABLE [a=35 b=0 c=0 d=nil]
  e[32] = {}  -- NEWTABLE [a=32 b=0 c=0 d=nil]
  e[33] = {}  -- NEWTABLE [a=33 b=0 c=0 d=nil]
  e[33][K(71)] = e[42]  -- SETTABLE [a=33 b=71 c=42 d=49] -- settable/void-call (inferred)
  e[35][K(71)] = e[122]  -- SETTABLE [a=35 b=71 c=122 d=49] -- settable/void-call (inferred)
  e[32][K(71)] = e[4]  -- SETTABLE [a=32 b=71 c=4 d=49] -- settable/void-call (inferred)
  e[33][K(218)] = e[2158]  -- SETTABLE [a=33 b=218 c=2158 d=195] -- settable/void-call (inferred)
  call(e[38], e[31])  -- CALL? [a=38 b=0 c=31 d=nil] -- void call
  goto L_222
  goto L_197
end

local function proto88(...)  -- 91 instrs, 32 blocks (structured)
  local e = regs
  ::L_1::
  ::L_33::
  goto L_1
  e[24] = {}  -- NEWTABLE [a=24 b=0 c=0 d=nil]
  e[22] = {}  -- NEWTABLE [a=22 b=0 c=0 d=nil]
  ::L_4::
  e[21] = {}  -- NEWTABLE [a=21 b=0 c=0 d=nil]
  e[21][K(119)] = e[20]  -- SETTABLE [a=21 b=119 c=20 d=22] -- settable/void-call (inferred)
  e[24][K(119)] = e[96]  -- SETTABLE [a=24 b=119 c=96 d=22] -- settable/void-call (inferred)
  e[22][K(117)] = e[73]  -- SETTABLE [a=22 b=117 c=73 d=19] -- settable/void-call (inferred)
  call(e[27], e[20])  -- CALL? [a=27 b=0 c=20 d=nil] -- void call
  ::L_9::
  goto L_23
  e[1] = e[0][K(1)]  -- GETTABLE/CLOSURE [a=0 b=1 c=0 d=nil]
  e[2] = e[1]["        "]  -- GETTABLE/CLOSURE [a=1 b=2 c=0 d=nil]  -- = "        "
  e[3] = 1  -- LOADK [a=3 b=16 c=0 d=1]
  e[4] = 4  -- LOADK [a=4 b=9 c=0 d=4]
  if e[1] then goto L_4 end  -- back-edge (loop)
  e[138] = e[2][K(138)]  -- GETTABLE/CLOSURE [a=2 b=138 c=0 d=nil]
  e[6] = e[4][32]  -- GETTABLE/CLOSURE? [a=4 b=0 c=6 d=nil]  -- = 32
  e[211] = 64  -- LOADK [a=211 b=98 c=165 d=64]
  ::L_18::
  goto L_50
  e[17] = K(10)  -- LOADK_S [a=0 b=10 c=17 d=nil]
  e[18] = K(6)  -- LOADK_S [a=0 b=6 c=18 d=nil]
  e[0] = (e[0] == e[115])  -- COMPARE [a=0 b=0 c=115 d=nil]
  ::L_23::
  goto L_43
  e[11] = {}  -- NEWTABLE [a=11 b=0 c=0 d=nil]
  e[17] = K(19)  -- LOADK_S [a=0 b=19 c=17 d=nil]
  e[18] = 197  -- LOADK [a=18 b=891 c=11 d=197]
  e[17] = 4294967098  -- LOADK_N [a=0 b=0 c=17 d=nil]
  e[18] = K(5)  -- LOADK_S [a=0 b=5 c=18 d=nil]
  e[19] = 3.141592653589793  -- LOADK_S [a=0 b=6 c=19 d=nil]
  e[18] = 3  -- LOADK_N [a=0 b=70 c=18 d=nil]
  e[17] = (e[17] == e[17])  -- COMPARE [a=17 b=101 c=17 d=nil]  -- = false
  if e[17] then goto L_43 else goto L_33 end
  ::L_34::
  goto L_42
  ::L_35::
  goto L_18
  -- UNKNOWN op? [a=17 b=917 c=17 d=20586]
  e[17] = arith(e[17], e[237])  -- UNOP/arith? [a=17 b=17 c=237 d=nil]  -- = 5
  call(e[17], e[22])  -- CALL [a=17 b=11 c=22 d=nil] -- void call
  e[11][K(60)] = e[88]  -- SETTABLE [a=11 b=60 c=88 d=35] -- settable/void-call (inferred)
  call(e[19], e[9])  -- CALL? [a=19 b=0 c=9 d=nil] -- void call
  goto L_9
  ::L_42::
  e[387] = arith(e[68], e[421])  -- ARITH [a=387 b=68 c=421 d=nil]
  ::L_43::
  goto L_58
  ::L_44::
  goto L_44
  e[24] = {}  -- NEWTABLE [a=24 b=0 c=0 d=nil]
  e[22] = {}  -- NEWTABLE [a=22 b=0 c=0 d=nil]
  e[24][K(106)] = e[87]  -- SETTABLE [a=24 b=106 c=87 d=36] -- settable/void-call (inferred)
  e[22][K(51)] = e[58]  -- SETTABLE [a=22 b=51 c=58 d=44] -- settable/void-call (inferred)
  call(e[27], e[20])  -- CALL? [a=27 b=0 c=20 d=nil] -- void call
  ::L_50::
  goto L_80
  e[5] = K(5)  -- LOADK_N [a=0 b=5 c=0 d=nil]
  e[5] = arith(e[5], e[5])  -- ARITH [a=1948 b=5 c=5 d=nil]  -- = 1610612736
  e[6] = e[2][K(6)]  -- GETTABLE/CLOSURE [a=2 b=6 c=0 d=nil]
  e[7] = e[3][32]  -- GETTABLE/CLOSURE? [a=3 b=0 c=7 d=nil]  -- = 32
  e[8] = 32  -- LOADK [a=8 b=29 c=0 d=32]
  e[6] = K(6)  -- LOADK_N [a=0 b=6 c=0 d=nil]
  e[6] = arith(e[6], e[6])  -- ARITH [a=577 b=6 c=6 d=nil]  -- = 0
  ::L_58::
  goto L_82
  e[21] = {}  -- NEWTABLE [a=21 b=0 c=0 d=nil]
  e[22] = {}  -- NEWTABLE [a=22 b=0 c=0 d=nil]
  e[23] = {}  -- NEWTABLE [a=0 b=23 c=0 d=nil]
  e[22][K(24)] = e[4]  -- SETTABLE [a=22 b=24 c=4 d=30] -- settable/void-call (inferred)
  e[21][K(19)] = e[4]  -- SETTABLE [a=21 b=19 c=4 d=26] -- settable/void-call (inferred)
  e[23][K(20)] = e[81]  -- SETTABLE [a=23 b=20 c=81 d=17] -- settable/void-call (inferred)
  e[21][K(20)] = e[4]  -- SETTABLE [a=21 b=20 c=4 d=17] -- settable/void-call (inferred)
  e[22][K(127)] = e[114]  -- SETTABLE [a=22 b=127 c=114 d=31] -- settable/void-call (inferred)
  e[21][K(2)] = e[4]  -- SETTABLE [a=21 b=2 c=4 d=84] -- settable/void-call (inferred)
  e[23][K(2)] = e[93]  -- SETTABLE [a=23 b=2 c=93 d=84] -- settable/void-call (inferred)
  e[22][K(2)] = e[23]  -- SETTABLE [a=22 b=2 c=23 d=84] -- settable/void-call (inferred)
  e[22][K(125)] = e[126]  -- SETTABLE [a=22 b=125 c=126 d=43] -- settable/void-call (inferred)
  call(e[27], e[20])  -- CALL? [a=27 b=0 c=20 d=nil] -- void call
  ::L_72::
  goto L_34
  e[7] = e[1][32]  -- GETTABLE/CLOSURE? [a=1 b=0 c=7 d=nil]  -- = 32
  e[8] = 8  -- LOADK [a=8 b=84 c=0 d=8]
  e[6] = K(6)  -- LOADK_N [a=0 b=6 c=0 d=nil]
  e[5] = arith(e[5], e[6])  -- ARITH [a=5 b=5 c=6 d=nil]  -- = 1610625064
  ::L_77::
  do return end  -- JMP/RETURN [a=0 b=0 c=5 d=nil]
  ::L_78::
  goto L_78
  e[17] = 211  -- LOADK [a=17 b=769 c=0 d=211]
  ::L_80::
  goto L_35
  if e[17] then goto L_35 end  -- back-edge (loop)
  ::L_82::
  goto L_77
  e[5] = arith(e[5], e[6])  -- ARITH [a=5 b=5 c=6 d=nil]  -- = 1610612736
  e[123] = e[94][K(123)]  -- GETTABLE/CLOSURE [a=94 b=123 c=79 d=nil]
  e[7] = e[2][32]  -- GETTABLE/CLOSURE? [a=2 b=0 c=7 d=nil]  -- = 32
  e[8] = 16  -- LOADK [a=8 b=108 c=0 d=16]
  e[6] = K(6)  -- LOADK_N [a=0 b=6 c=0 d=nil]
  e[6] = arith(e[6], e[6])  -- ARITH [a=1272 b=6 c=6 d=nil]  -- = 12288
  e[5] = arith(e[5], e[6])  -- ARITH [a=5 b=5 c=6 d=nil]  -- = 1610625024
  e[6] = e[2][K(6)]  -- GETTABLE/CLOSURE [a=2 b=6 c=0 d=nil]
  goto L_72
end

local function proto89(...)  -- 76 instrs, 36 blocks (structured)
  local e = regs
  ::L_57::
  ::L_16::
  ::L_42::
  e[1] = e[2][1]  -- GETTABLE/CLOSURE? [a=2 b=0 c=1 d=nil]  -- = 1
  if e[45] then goto L_4 end
  ::L_44::
  ::L_27::
  ::L_12::
  ::L_47::
  do return end  -- JMP/RETURN [a=0 b=0 c=5 d=nil]
  ::L_4::
  ::L_49::
  ::L_7::
  goto L_44
  e[2] = arith(e[7], e[2])  -- ARITH [a=93 b=7 c=2 d=nil]  -- = 768
  e[3] = arith(e[3], e[3])  -- ARITH [a=93 b=3 c=3 d=nil]  -- = 2097152
  goto L_4
  e[5] = arith(e[1], e[93])  -- ARITH [a=5 b=1 c=93 d=nil]  -- = 1
  if e[12] then goto L_4 else goto L_7 end  -- back-edge (loop)
  e[5] = arith(e[1], e[93])  -- ARITH [a=5 b=1 c=93 d=nil]  -- = 0
  e[6] = arith(e[2], e[93])  -- ARITH [a=6 b=2 c=93 d=nil]  -- = 0
  if e[6] then goto L_7 else goto L_12 end  -- back-edge (loop)
  e[6] = arith(e[6], e[25])  -- ARITH [a=233 b=6 c=25 d=nil]  -- = 0
  e[1] = arith(e[6], e[1])  -- ARITH [a=93 b=6 c=1 d=nil]  -- = 0
  e[3] = arith(e[3], e[3])  -- ARITH [a=93 b=3 c=3 d=nil]  -- = 64
  goto L_16
  e[20] = {}  -- NEWTABLE [a=20 b=0 c=0 d=nil]
  e[22] = {}  -- NEWTABLE [a=0 b=22 c=0 d=nil]
  e[21] = {}  -- NEWTABLE [a=21 b=0 c=0 d=nil]
  e[22][K(118)] = e[99]  -- SETTABLE [a=22 b=118 c=99 d=13] -- settable/void-call (inferred)
  e[20][K(118)] = e[16]  -- SETTABLE [a=20 b=118 c=16 d=13] -- settable/void-call (inferred)
  e[21][K(115)] = e[9]  -- SETTABLE [a=21 b=115 c=9 d=28] -- settable/void-call (inferred)
  call(e[26], e[19])  -- CALL? [a=26 b=0 c=19 d=nil] -- void call
  ::L_24::
  goto L_4
  e[4] = arith(e[4], e[3])  -- ARITH [a=4 b=4 c=3 d=nil]  -- = 40
  goto L_27
  e[22] = {}  -- NEWTABLE [a=0 b=22 c=0 d=nil]
  e[21] = {}  -- NEWTABLE [a=21 b=0 c=0 d=nil]
  e[20] = {}  -- NEWTABLE [a=20 b=0 c=0 d=nil]
  e[23] = {}  -- NEWTABLE [a=23 b=0 c=0 d=nil]
  e[23][K(95)] = e[929]  -- SETTABLE [a=23 b=95 c=929 d=61] -- settable/void-call (inferred)
  e[20][K(34)] = e[20]  -- SETTABLE [a=20 b=34 c=20 d=63] -- settable/void-call (inferred)
  e[22][K(34)] = e[20]  -- SETTABLE [a=22 b=34 c=20 d=63] -- settable/void-call (inferred)
  e[20][K(91)] = e[20]  -- SETTABLE [a=20 b=91 c=20 d=62] -- settable/void-call (inferred)
  e[20][K(38)] = e[4]  -- SETTABLE [a=20 b=38 c=4 d=55] -- settable/void-call (inferred)
  e[23][K(38)] = e[79]  -- SETTABLE [a=23 b=38 c=79 d=55] -- settable/void-call (inferred)
  e[21][K(84)] = e[124]  -- SETTABLE [a=21 b=84 c=124 d=8] -- settable/void-call (inferred)
  call(e[26], e[19])  -- CALL? [a=26 b=0 c=19 d=nil] -- void call
  ::L_41::
  goto L_24
  goto L_68
  e[5] = e[4][40]  -- GETTABLE/CLOSURE? [a=4 b=0 c=5 d=nil]  -- = 40
  goto L_47
  e[4] = arith(e[4], e[3])  -- ARITH [a=4 b=4 c=3 d=nil]  -- = 8
  goto L_49
  if e[74] then goto L_4 end  -- back-edge (loop)
  ::L_51::
  goto L_55
  e[7] = arith(e[7], e[1])  -- ARITH [a=5 b=7 c=1 d=nil]  -- = 768
  e[1] = arith(e[7], e[1])  -- ARITH [a=93 b=7 c=1 d=nil]  -- = 384
  e[7] = arith(e[7], e[2])  -- ARITH [a=22 b=7 c=2 d=nil]  -- = 768
  ::L_55::
  e[0] = {}  -- NEWTABLE [a=0 b=1 c=242 d=nil]
  if e[74] then goto L_4 else goto L_57 end  -- back-edge (loop)
  e[12] = {}  -- NEWTABLE [a=0 b=12 c=0 d=nil]
  e[11] = {}  -- NEWTABLE [a=11 b=0 c=0 d=nil]
  e[17] = K(12)  -- LOADK_S [a=0 b=12 c=17 d=nil]
  e[18] = arith(e[1446], e[18])  -- ARITH [a=1616 b=1446 c=18 d=401]  -- = 753
  e[105] = 22  -- LOADK_N [a=0 b=0 c=105 d=nil]
  e[158] = e[253] + 27003  -- ADD [a=158 b=1210 c=253 d=27003]  -- = 27025
  e[17] = arith(e[17], e[140])  -- UNOP/arith? [a=17 b=17 c=140 d=nil]  -- = 6
  call(e[17], e[69])  -- CALL [a=17 b=12 c=69 d=nil] -- void call
  e[11][K(104)] = e[128]  -- SETTABLE [a=11 b=104 c=128 d=25] -- settable/void-call (inferred)
  call(e[18], e[9])  -- CALL? [a=18 b=0 c=9 d=nil] -- void call
  ::L_68::
  goto L_51
  e[0] = {}  -- NEWTABLE [a=0 b=2 c=0 d=nil]
  e[3] = 1  -- LOADK [a=3 b=16 c=0 d=1]
  e[4] = 0  -- LOADK [a=4 b=4 c=0 d=0]
  goto L_49
  -- UNKNOWN op? [a=427 b=298 c=409 d=nil]
  if e[1] then goto L_42 end  -- back-edge (loop)
  goto L_41
end

local function proto90(...)  -- 168 instrs, 80 blocks (structured)
  local e = regs
  ::L_1::
  if e[210] then do return end else goto L_111 end
  ::L_111::
  ::L_51::
  goto L_111
  if e[18] then goto L_34 end
  ::L_3::
  goto L_122
  ::L_4::
  e[1] = e[0][K(1)]  -- GETTABLE/CLOSURE [a=0 b=1 c=0 d=nil]
  goto L_160
  e[2] = e[0][K(2)]  -- GETTABLE/CLOSURE [a=0 b=2 c=0 d=nil]
  do return end  -- JMP/RETURN [a=2 b=0 c=0 d=nil]
  e[3] = K(16)  -- LOADK [a=3 b=16 c=0 d=1]
  e[4] = e[1][K(4)]  -- GETTABLE/CLOSURE [a=1 b=4 c=0 d=nil]
  e[5] = e[2][K(0)]  -- GETTABLE/CLOSURE? [a=2 b=0 c=5 d=nil]
  e[6] = K(16)  -- LOADK [a=6 b=16 c=0 d=1]
  ::L_12::
  goto L_17
  e[6] = arith(e[6], e[7])  -- ARITH [a=4 b=6 c=7 d=nil]
  e[7] = arith(e[7], e[7])  -- ARITH [a=4 b=7 c=7 d=nil]
  ::L_15::
  goto L_116
  if e[7] then goto L_116 end
  ::L_17::
  goto L_12
  e[7] = K(110)  -- LOADK [a=7 b=110 c=0 d=20]
  e[4] = K(4)  -- LOADK_N [a=0 b=4 c=4 d=nil]
  e[4] = arith(e[4], e[4])  -- ARITH [a=940 b=4 c=4 d=nil]
  e[4] = arith(e[4], e[1])  -- ARITH [a=4 b=4 c=1 d=nil]
  ::L_22::
  goto L_102
  if e[48] then goto L_4 end  -- back-edge (loop)
  ::L_24::
  goto L_117
  e[24] = {}  -- NEWTABLE [a=24 b=0 c=0 d=nil]
  e[26] = {}  -- NEWTABLE [a=26 b=0 c=0 d=nil]
  e[25] = {}  -- NEWTABLE [a=0 b=25 c=0 d=nil]
  e[26][K(116)] = e[1842]  -- SETTABLE [a=26 b=116 c=1842 d=45] -- settable/void-call (inferred)
  e[26][K(30)] = e[122]  -- SETTABLE [a=26 b=30 c=122 d=46] -- settable/void-call (inferred)
  e[25][K(30)] = e[16]  -- SETTABLE [a=25 b=30 c=16 d=46] -- settable/void-call (inferred)
  e[24][K(30)] = e[23]  -- SETTABLE [a=24 b=30 c=23 d=46] -- settable/void-call (inferred)
  e[24][K(536)] = e[51]  -- SETTABLE [a=24 b=536 c=51 d=122] -- settable/void-call (inferred)
  call(e[29], e[22])  -- CALL? [a=29 b=0 c=22 d=nil] -- void call
  ::L_34::
  goto L_44
  e[18] = e[18] + 29874  -- ADD [a=18 b=748 c=18 d=29874]
  e[18] = arith(e[18], e[1878])  -- UNOP/arith? [a=18 b=18 c=1878 d=nil]
  call(e[18], e[66])  -- CALL [a=18 b=14 c=66 d=nil] -- void call
  e[12][K(2)] = e[1901]  -- SETTABLE [a=12 b=2 c=1901 d=84] -- settable/void-call (inferred)
  call(e[21], e[10])  -- CALL? [a=21 b=0 c=10 d=nil] -- void call
  ::L_40::
  goto L_60
  e[18] = K(21)  -- LOADK_S [a=0 b=21 c=18 d=nil]
  e[19] = K(6)  -- LOADK_S [a=0 b=6 c=19 d=nil]
  e[18] = K(0)  -- LOADK_N [a=0 b=0 c=18 d=nil]
  ::L_44::
  goto L_153
  -- UNKNOWN op? [a=0 b=5 c=4 d=nil]
  e[164] = (e[234] == e[0])  -- COMPARE [a=234 b=164 c=0 d=nil]
  e[7] = e[2][K(0)]  -- GETTABLE/CLOSURE? [a=2 b=0 c=7 d=nil]
  goto L_70
  e[5] = K(16)  -- LOADK [a=5 b=16 c=0 d=1]
  e[3] = K(4)  -- LOADK [a=3 b=4 c=0 d=0]
  goto L_51
  ::L_52::
  goto L_142
  e[12] = {}  -- NEWTABLE [a=12 b=0 c=0 d=nil]
  e[14] = {}  -- NEWTABLE [a=14 b=0 c=0 d=nil]
  e[18] = K(15)  -- LOADK_S [a=0 b=15 c=18 d=nil]
  -- UNKNOWN op? [a=19 b=2050 c=0 d=�]
  e[18] = K(0)  -- LOADK_N [a=0 b=0 c=18 d=nil]
  dataop(e[18], e[338], e[18])  -- DATAOP [a=18 b=338 c=18 d=193]
  if e[18] then goto L_153 end
  ::L_60::
  goto L_160
  ::L_61::
  goto L_84
  e[6] = arith(e[6], e[7])  -- ARITH [a=16 b=6 c=7 d=nil]
  e[7] = arith(e[7], e[7])  -- ARITH [a=4 b=7 c=7 d=nil]
  ::L_64::
  goto L_15
  e[85] = arith(e[5], e[1309])  -- ARITH [a=85 b=5 c=1309 d=nil]
  dataop(e[7], e[93], e[7])  -- DATAOP [a=7 b=93 c=7 d=2]
  dataop(e[7], e[6], e[7])  -- DATAOP [a=7 b=6 c=7 d=nil]
  e[8] = arith(e[4], e[8])  -- ARITH [a=1315 b=4 c=8 d=nil]
  e[8] = arith(e[3], e[8])  -- ARITH [a=8 b=3 c=8 d=nil]
  ::L_70::
  goto L_132
  e[8] = K(29)  -- LOADK [a=8 b=29 c=0 d=32]
  e[6] = K(6)  -- LOADK_N [a=0 b=6 c=0 d=nil]
  dataop(e[6], e[16], e[6])  -- DATAOP [a=6 b=16 c=6 d=1]
  -- UNKNOWN op? [a=6 b=6 c=0 d=nil]
  if e[119] then goto L_4 end  -- back-edge (loop)
  ::L_76::
  goto L_167
  ::L_77::
  goto L_77
  e[24] = {}  -- NEWTABLE [a=24 b=0 c=0 d=nil]
  e[26] = {}  -- NEWTABLE [a=26 b=0 c=0 d=nil]
  e[26][K(2210)] = e[8]  -- SETTABLE [a=26 b=2210 c=8 d=128] -- settable/void-call (inferred)
  e[24][K(57)] = e[581]  -- SETTABLE [a=24 b=57 c=581 d=77] -- settable/void-call (inferred)
  call(e[29], e[22])  -- CALL? [a=29 b=0 c=22 d=nil] -- void call
  ::L_83::
  goto L_126
  ::L_84::
  goto L_134
  e[25] = {}  -- NEWTABLE [a=0 b=25 c=0 d=nil]
  e[23] = {}  -- NEWTABLE [a=23 b=0 c=0 d=nil]
  e[24] = {}  -- NEWTABLE [a=24 b=0 c=0 d=nil]
  e[23][K(83)] = e[99]  -- SETTABLE [a=23 b=83 c=99 d=75] -- settable/void-call (inferred)
  e[25][K(2268)] = e[4]  -- SETTABLE [a=25 b=2268 c=4 d=134] -- settable/void-call (inferred)
  e[24][K(95)] = e[1901]  -- SETTABLE [a=24 b=95 c=1901 d=61] -- settable/void-call (inferred)
  call(e[29], e[22])  -- CALL? [a=29 b=0 c=22 d=nil] -- void call
  ::L_92::
  goto L_97
  e[128] = (e[1371] == e[18])  -- COMPARE [a=1371 b=128 c=18 d=nil]
  if e[18] then goto L_1 end  -- back-edge (loop)
  ::L_95::
  goto L_76
  -- UNKNOWN op? [a=18 b=92 c=0 d=nil]
  ::L_97::
  goto L_141
  e[5] = e[1][K(5)]  -- GETTABLE/CLOSURE [a=1 b=5 c=0 d=nil]
  e[6] = e[2][K(82)]  -- GETTABLE/CLOSURE? [a=2 b=82 c=6 d=nil]
  e[7] = K(122)  -- LOADK [a=7 b=122 c=0 d=21]
  e[8] = K(127)  -- LOADK [a=8 b=127 c=0 d=31]
  ::L_102::
  goto L_121
  ::L_103::
  goto L_161
  e[25] = {}  -- NEWTABLE [a=0 b=25 c=0 d=nil]
  e[24] = {}  -- NEWTABLE [a=24 b=0 c=0 d=nil]
  e[25][K(5)] = e[81]  -- SETTABLE [a=25 b=5 c=81 d=65] -- settable/void-call (inferred)
  e[24][K(2229)] = e[98]  -- SETTABLE [a=24 b=2229 c=98 d=155] -- settable/void-call (inferred)
  call(e[29], e[22])  -- CALL? [a=29 b=0 c=22 d=nil] -- void call
  goto L_64
  e[24] = {}  -- NEWTABLE [a=24 b=0 c=0 d=nil]
  e[24][K(80)] = e[114]  -- SETTABLE [a=24 b=80 c=114 d=93] -- settable/void-call (inferred)
  e[24][K(250)] = e[11]  -- SETTABLE [a=24 b=250 c=11 d=154] -- settable/void-call (inferred)
  call(e[29], e[22])  -- CALL? [a=29 b=0 c=22 d=nil] -- void call
  ::L_116::
  goto L_95
  ::L_117::
  do return end  -- JMP/RETURN [a=0 b=0 c=7 d=nil]
  e[6] = arith(e[6], e[7])  -- ARITH [a=4 b=6 c=7 d=nil]
  do return end  -- JMP/RETURN [a=0 b=0 c=7 d=nil]
  if e[154] then do return end else goto L_121 end
  ::L_121::
  goto L_150
  ::L_122::
  goto L_24
  e[18] = K(15)  -- LOADK_S [a=0 b=15 c=18 d=nil]
  e[19] = K(1049)  -- LOADK [a=19 b=1049 c=0 d=�]
  e[18] = K(0)  -- LOADK_N [a=0 b=0 c=18 d=nil]
  ::L_126::
  goto L_34
  e[18] = K(9)  -- LOADK_S [a=0 b=9 c=18 d=nil]
  if e[19] then do return end else goto L_129 end
  ::L_129::
  e[20] = K(107)  -- LOADK [a=20 b=107 c=0 d=1]
  e[21] = K(107)  -- LOADK [a=21 b=107 c=0 d=1]
  e[18] = K(18)  -- LOADK_N [a=0 b=18 c=4 d=nil]
  ::L_132::
  goto L_1
  dataop(e[7], e[7], e[8])  -- DATAOP [a=7 b=7 c=8 d=nil]
  ::L_134::
  do return end  -- JMP/RETURN [a=207 b=0 c=7 d=nil]
  ::L_135::
  goto L_135
  e[24] = {}  -- NEWTABLE [a=24 b=0 c=0 d=nil]
  e[26] = {}  -- NEWTABLE [a=26 b=0 c=0 d=nil]
  e[26][K(932)] = e[75]  -- SETTABLE [a=26 b=932 c=75 d=96] -- settable/void-call (inferred)
  e[24][K(1702)] = e[94]  -- SETTABLE [a=24 b=1702 c=94 d=135] -- settable/void-call (inferred)
  call(e[29], e[22])  -- CALL? [a=29 b=0 c=22 d=nil] -- void call
  ::L_141::
  goto L_52
  ::L_142::
  goto L_155
  e[25] = {}  -- NEWTABLE [a=0 b=25 c=0 d=nil]
  e[24] = {}  -- NEWTABLE [a=24 b=0 c=0 d=nil]
  e[24][K(1134)] = e[4]  -- SETTABLE [a=24 b=1134 c=4 d=99] -- settable/void-call (inferred)
  e[25][K(99)] = e[16]  -- SETTABLE [a=25 b=99 c=16 d=5] -- settable/void-call (inferred)
  e[24][K(99)] = e[4]  -- SETTABLE [a=24 b=99 c=4 d=5] -- settable/void-call (inferred)
  e[24][K(94)] = e[111]  -- SETTABLE [a=24 b=94 c=111 d=52] -- settable/void-call (inferred)
  call(e[29], e[22])  -- CALL? [a=29 b=0 c=22 d=nil] -- void call
  ::L_150::
  goto L_3
  e[4] = (e[4] == e[4])  -- COMPARE [a=4 b=7 c=4 d=nil]
  if e[7] then goto L_15 end  -- back-edge (loop)
  ::L_153::
  goto L_61
  ::L_155::
  goto L_103
  e[18] = K(8)  -- LOADK_S [a=0 b=8 c=18 d=nil]
  e[19] = K(6)  -- LOADK [a=19 b=6 c=0 d=>i8]
  e[20] = K(844)  -- LOADK [a=20 b=844 c=0 d=       �]
  e[18] = K(18)  -- LOADK_N [a=0 b=18 c=0 d=nil]
  ::L_160::
  goto L_92
  ::L_161::
  goto L_40
  e[24] = {}  -- NEWTABLE [a=24 b=0 c=0 d=nil]
  e[26] = {}  -- NEWTABLE [a=26 b=0 c=0 d=nil]
  e[26][K(105)] = e[8]  -- SETTABLE [a=26 b=105 c=8 d=56] -- settable/void-call (inferred)
  e[24][K(39)] = e[44]  -- SETTABLE [a=24 b=39 c=44 d=103] -- settable/void-call (inferred)
  call(e[29], e[22])  -- CALL? [a=29 b=0 c=22 d=nil] -- void call
  ::L_167::
  goto L_83
  goto L_22
end

local function proto91(...)  -- 79 instrs, 30 blocks (structured)
  local e = regs
  ::L_1::
  ::L_58::
  ::L_67::
  ::L_45::
  ::L_5::
  ::L_33::
  ::L_28::
  ::L_24::
  ::L_70::
  ::L_59::
  ::L_61::
  ::L_43::
  ::L_37::
  e[289] = (e[289] == e[215])  -- COMPARE [a=289 b=453 c=215 d=nil]
  e[10] = {}  -- NEWTABLE [a=10 b=0 c=0 d=nil]
  e[16] = K(18)  -- LOADK_S [a=0 b=18 c=16 d=nil]
  e[17] = K(20)  -- LOADK_S [a=0 b=20 c=17 d=nil]
  e[18] = K(1487)  -- LOADK [a=18 b=1487 c=47 d=138]
  e[19] = K(8)  -- LOADK_S [a=0 b=8 c=19 d=nil]
  e[20] = K(77)  -- LOADK [a=20 b=77 c=0 d=<i8]
  -- UNKNOWN op? [a=21 b=1079 c=0 d=       ]
  e[19] = K(19)  -- LOADK_N [a=0 b=19 c=0 d=nil]
  e[17] = K(17)  -- LOADK_N [a=0 b=17 c=0 d=nil]
  e[18] = K(1380)  -- LOADK [a=18 b=1380 c=0 d=11]
  e[16] = K(16)  -- LOADK_N [a=66 b=16 c=0 d=nil]
  e[16] = e[16] + 16155  -- ADD [a=16 b=141 c=16 d=16155]
  e[16] = arith(e[16], e[712])  -- UNOP/arith? [a=16 b=16 c=712 d=nil]
  call(e[16], e[43])  -- CALL [a=16 b=10 c=43 d=nil] -- void call
  e[10][K(45)] = e[92]  -- SETTABLE [a=10 b=45 c=92 d=68] -- settable/void-call (inferred)
  call(e[21], e[8])  -- CALL? [a=21 b=0 c=8 d=nil] -- void call
  goto L_24
  e[4] = arith(e[2], e[16])  -- ARITH [a=4 b=2 c=16 d=nil]
  dataop(e[4], e[93], e[11])  -- DATAOP [a=4 b=93 c=11 d=2]
  e[5] = arith(e[4], e[4])  -- ARITH [a=5 b=4 c=4 d=nil]
  goto L_5
  goto L_38
  e[0] = {}  -- NEWTABLE [a=0 b=3 c=0 d=nil]
  if e[3] then goto L_1 else goto L_28 end  -- back-edge (loop)
  e[4] = arith(e[2], e[16])  -- ARITH [a=4 b=2 c=16 d=nil]
  dataop(e[4], e[93], e[4])  -- DATAOP [a=4 b=93 c=4 d=2]
  dataop(e[4], e[1], e[4])  -- DATAOP [a=4 b=1 c=4 d=nil]
  goto L_33
  dataop(e[1], e[5], e[5])  -- DATAOP [a=1 b=5 c=5 d=nil]
  e[5] = (e[4] == e[5])  -- COMPARE [a=4 b=5 c=5 d=nil]
  if e[5] then goto L_59 else goto L_37 end  -- back-edge (loop)
  ::L_38::
  do return end  -- JMP/RETURN [a=0 b=234 c=5 d=nil]
  e[24] = {}  -- NEWTABLE [a=24 b=0 c=0 d=nil]
  e[24][K(1)] = e[4]  -- SETTABLE [a=24 b=1 c=4 d=38] -- settable/void-call (inferred)
  e[24][K(23)] = e[55]  -- SETTABLE [a=24 b=23 c=55 d=6] -- settable/void-call (inferred)
  call(e[29], e[22])  -- CALL? [a=29 b=0 c=22 d=nil] -- void call
  goto L_43
  e[5] = K(4)  -- LOADK [a=5 b=4 c=0 d=0]
  goto L_45
  e[26] = {}  -- NEWTABLE [a=26 b=0 c=0 d=nil]
  e[25] = {}  -- NEWTABLE [a=0 b=25 c=0 d=nil]
  e[24] = {}  -- NEWTABLE [a=24 b=0 c=0 d=nil]
  e[23] = {}  -- NEWTABLE [a=23 b=0 c=0 d=nil]
  e[24][K(66)] = e[99]  -- SETTABLE [a=24 b=66 c=99 d=74] -- settable/void-call (inferred)
  e[23][K(103)] = e[4]  -- SETTABLE [a=23 b=103 c=4 d=11] -- settable/void-call (inferred)
  e[25][K(62)] = e[23]  -- SETTABLE [a=25 b=62 c=23 d=73] -- settable/void-call (inferred)
  e[26][K(100)] = e[8]  -- SETTABLE [a=26 b=100 c=8 d=14] -- settable/void-call (inferred)
  e[25][K(114)] = e[4]  -- SETTABLE [a=25 b=114 c=4 d=18] -- settable/void-call (inferred)
  e[26][K(10)] = e[2323]  -- SETTABLE [a=26 b=10 c=2323 d=72] -- settable/void-call (inferred)
  e[24][K(32)] = e[13]  -- SETTABLE [a=24 b=32 c=13 d=29] -- settable/void-call (inferred)
  call(e[29], e[22])  -- CALL? [a=29 b=0 c=22 d=nil] -- void call
  goto L_58
  if e[5] then goto L_5 else goto L_61 end  -- back-edge (loop)
  e[24] = {}  -- NEWTABLE [a=24 b=0 c=0 d=nil]
  e[23] = {}  -- NEWTABLE [a=23 b=0 c=0 d=nil]
  e[23][K(111)] = e[9]  -- SETTABLE [a=23 b=111 c=9 d=3] -- settable/void-call (inferred)
  e[24][K(101)] = e[104]  -- SETTABLE [a=24 b=101 c=104 d=59] -- settable/void-call (inferred)
  call(e[29], e[22])  -- CALL? [a=29 b=0 c=22 d=nil] -- void call
  goto L_67
  e[5] = K(16)  -- LOADK [a=5 b=16 c=0 d=1]
  goto L_70
  e[5] = arith(e[223], e[16])  -- ARITH [a=5 b=223 c=16 d=nil]
  -- UNKNOWN op? [a=6 b=2 c=16 d=nil]
  e[5] = arith(e[5], e[5])  -- ARITH [a=144 b=5 c=5 d=nil]
  e[5] = arith(e[178], e[16])  -- UNOP/arith? [a=5 b=178 c=16 d=nil]
  dataop(e[5], e[93], e[5])  -- DATAOP [a=5 b=93 c=5 d=2]
  dataop(e[4], e[5], e[4])  -- DATAOP [a=4 b=5 c=4 d=nil]
  e[5] = arith(e[4], e[16])  -- ARITH [a=5 b=4 c=16 d=nil]
  e[5] = arith(e[5], e[4])  -- ARITH [a=5 b=5 c=4 d=nil]
  do return end  -- JMP/RETURN [a=0 b=0 c=5 d=nil]
end
