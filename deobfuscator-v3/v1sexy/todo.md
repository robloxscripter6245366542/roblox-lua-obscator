TODO: Add .optimize command
TODO: Remove default antitamper from outputs
TODO: Fixed nested ifs ruining the output (due to isReachable)

TO DETECT A BREAK: While in a loop while, explore the branches, if one of these leads into something that never comes back into the while loop, it's either a return or a break.
TODO: Fix repeats and & isReachable
TODO: Fix ors and ands
TODO: Add variable renamer
TODO: Fix string decryption not working on large scripts that have things like JA[1] = "..." JA[2] = 123 JA[3] = decrypt(JA[1], JA[2]), maybe use the luau runtime?
TODO: Add a .decrypt command which decrypts all strings with the set keys
TODO: Make prometheus deobf also output the encryption keys used so people can .decrypt

# UPDATE V1.0.1

[FIX] Fixed scripts with extremely large constant arrays not working (just plain errors.)

# UPDATE V1.0.2

[FIX] Fixed prom deobf having memory leaks, getting 'unable to obfuscate' 99% of the time and fixed ib2 deobf not working at all

# UPDATE V1.0.3

[ADD] Added back .access, you're no longer able to use this bot with only credits.
[CHANGE] Changed it so you cannot gift the same person twice in a row.
[FIX] Fixed decompiler issues

# UPDATE V1.0.4 (MOSTLY BOT CHANGES)

[CHANGE] Codes (premium & credits) are now handled in the SQL database instead of json files (💀), meaning they're ALOT faster
[CHANGE] Credit redeeming is alot easier now, you only need to .redeem code
[ADD] Added back credits to the shop
[CHANGE] You can now gift people directly from .creds (@user)
[CHANGE] You no longer see 'next reset: ' if you have more than 2 credits
[CHANGE] You can now see how many credits people have after gifting them

# UPDATE V1.0.5 (BOT CHANGES TOO)

[FIX] Fixed ib2 deobf not working most of the time
[CHANGE] Made the gift icon prettier
[ADD] Added cancel processing to .l
[REMOVE] Removed .claimcreds & .obf
[ADD] added a cute typing indicator emoji for deobf commands

# UPDATE v1.0.6 (DEOBF CHANGES)

[CHANGE] Made it so the string encryption functions are no longer in the output
[FIX] Removed the weird x < y before for loops
[ADD] Added constant array support for scripts that dont have WrapInFunction on
[FIX] Registers and variables are now named in order, not r17 being the first variable
[FIX] Fixed: r1 = true r1 = false becoming local r1 = true local r1 = false
[ADD] Added nested `and` and `or` support
[FIX] Fixed certain whiles turning into ifs and ifs turning into whiles
[ADD] Added .luau files support for .l and other commands
[ADD] Added compound assigns (+=, -=, ...) support in deobf