~~> fix stuff like samples/antitampers/lines.lua (the register numbers are STILL not being handled properly inside functions)~~
> fix inliner not working when there's alot of re-assignments -> 2.1?

> make the inliner also able to remove `TableConstructorExpression`s that dont have any CallExpression or anything that actually matters in them. (UNSURE IF TO ADD)
~~> fix weird issues like functions STILL having their body as a block id during uncff and things inside the issues folder~~

> fix nested if checks being weird asf from inliner
> fix half the code missing on random antitampers after if checks (antitampers/full.lua, /elisium.txt, /weirdo.txt)
> work on inliner -> 2 (TOP PRIORITY)
> fix repeatstatement -- ??
> fix if true then else a = anything that contains `and` or `or` turning into a weird elseif -> 3
> fix nested `and` / `or` not working -> 4
> make localify work on statements (BUT WORK PROPERLY)

> fix isReachable (keeps turning while loops into ifs.. (and repeats into ifs))
> fix random uncff bugs.. (AND INLINER)
> most 'issues' in inliner arent actually issues in inliner, but rather they come from uncff?!
> fix `and` / `or` STILL not properly working
> fix nested function args being broken
> fix broken repeats & whiles on WRD (IDK WHAT THE ISSUE IS......)

> handle namecalls better (maybe check at handlePass?)

# TODO RN:
Fix fornumericstatements being soooo weird..
Fix code generated being kinda ugly
Fix some repeat statements being detected as if statements
Add forgenericstatement support (AGAIN???)
^^ yes, this is 90% done, just add support for 'next' and stuff
Fix 'or's being broken
Add support for Q[1] = true print(Q[1])
Fix uncff having weird ifs that are nested
Add elseif support

>> INLINER ROADMAP <<

[FIX] Fixed bug where things in table indexes, for example:
local N = { f }
if x then
    print(N[1])
end
being print(f) instead of f's value (which comes from later inlining)
[FIX] Fixed ForNumericStatement not properly locking it's variable so that it doesnt get inlined in the statement, for example:
for Y = 1, 2, 3 do
    print(Y)
end
Y previously would be marked as inlineable

>> DEOBF ROADMAP <<

[ADD] Added namecalls

[ADD] Added fully working for loops
[FIX] Fixed inliner sharing ClearedList for functions, fixing like 67 bugs

[ADD] Fixed regtable lookups:) (Things like u[Q[i]] are automatically fixed now!)
[ADD] Fixed for loops

[ADD] Added `or` & `and` support!

[FIX] Fixed beautifier adding indents in if statement when there's no reason to (for example after a `then`)

[ADD] Added inlinev3 to cff, removed inline v2 & v1
[FIX] Made uncff SO SO SO SO SO SO much more accurate, with proper if-else detection now!
[ADD] Added unpack({1}) -> 1

[FIX] Added better support for `or` & `and` detection when

[ADD] Added RepeatStatement support in uncff
[ADD] Inliner now handles returns properly and marks all the variable in that scope as inlineable because they won't be used after that

[ADD] Added repeat support for both uncff & inliner!
[FIX] Inliner is now at least 10x better than any other inliner i've worked on (OR USED!).
[FIX] Fixed ForNumericStatement inlining things incorrectly when it shouldn't even inline.

[ADD] Inliner now optimizes table indexing! For example N = { 1 } print(N[1]) -> N = {1} print(1)

[ADD] Added elseif support & fixed nested if checks being just WRONG
[ADD] Made math solver smarter (Now converts things like 0 < D - 123 to 123 > D)
[ADD] Fixed weird const array bug

[FIX] Fixed weird indents bug
[FIX] Fixed for numeric bugs (maybe not all idk)

[FIX] Solved issue in inliner where x = 123; w = env["new"]; x = w; print(x) would become print(w) instead of print(env["new"])

[ADD] Added globals -> locals like v1, v2, v3

[FIX] upgraded fornumericstatement detection and i think they work better now

[ADDED] Added old 25ms support & detection
[FIX] Fixed encrypt strings
[FIX] Fixed strings being formatted incorrectly

[ADD] Made inliner handle the namecalls, not the cleaner as the cleaner doesn't count uses.
[FIX] Fixed inliner not handling table indexing

[ADD] Inliner now handles unpack({a}) -> a
[FIX] Inliner now handles namecalls also after encrypt strings

[FIX] Inliner now supports a[1] = 1 print(a[1]) as it would support a = { 1 } print(a[1])
[FIX] Fixed recursive functions being BROKEN :(
[FIX] Fixed inliner not properly inlining inside functions, this is a BIG change.
[FIX] Fixed an inliner bug where stuff inside functions would affect the variables outside the functions
[FIX] Fixed ForNumericStatements sometimes having the wrong start and end (due to the last statement)

[FIX] Fixed ForGenericStatement!!! (FOR THE FOURTH TIME)