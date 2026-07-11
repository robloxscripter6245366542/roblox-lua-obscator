# Transformation passes

Every pass is semantics-preserving and independently toggleable
(`config.passes.<name>`). AST passes run first, in registry order; then the
source is generated; then source passes run.

## `rename` (AST)

Renames local variables to opaque names while respecting lexical scope.

- **Renamed:** locals, function parameters, numeric/generic loop variables, and
  `local function` names.
- **Never renamed:** globals/builtins, table field names, method names, table
  keys, and the implicit method `self`.
- Upvalues are handled for free: a closure reference resolves to the same
  `Binding` as the enclosing declaration, so one rename covers every use at any
  depth.
- Names use the `_<digit><6 hex>` namespace, disjoint from runtime helper locals
  (`_<letter>…`), so a renamed local can never collide with a decoder/loader
  local.

Correctness notes: RHS of `local x = x` resolves before the new `x` is declared;
`local function f` is visible in its own body (recursion); `repeat … until` sees
body locals.

## `encodeNumbers` (AST)

Rewrites plain non-negative decimal **integer** literals `n` as `(a - b)` with
`a - b === n`. Only `+`/`-` of integers are used, so integer/float typing is
preserved. Hex, float, exponent, binary, and digit-separator literals are left
untouched — no value or type ever changes.

## `encodeStrings` (AST)

Replaces each string literal with `decode(cipher, salt)`:

- `cipher` is the string XOR-encrypted with a per-string salt (distinct salts →
  identical strings differ in the output).
- The decoder prelude is emitted once, capturing `string.char`/`string.byte`/
  `table.concat` into locals so a later `_ENV` swap cannot break it, and memoizes
  by `salt|cipher`.
- The call is wrapped in parentheses so call-with-string sugar stays valid:
  `print "x"` → `print((decode("…", n)))`.

The decoder keystream matches `util/prng.ts` exactly and is double-safe, so
decoding is identical on Lua 5.1–5.4 and Luau.

## `opaquePredicates` (AST)

Wraps a random subset of **call statements** in `if <always-true> then … end`.
The guard is the identity `a*a - b*b == (a-b)*(a+b)` (true for all numbers) with
literal `a`,`b`, so it evaluates to `true` at runtime but is not a constant
literal. Only call statements are wrapped — they declare nothing, so relocating
them inside an `if` cannot change scope or control flow. Rate is
`config.opaquePredicateRate`.

## `pack` (source)

Encrypts the fully generated chunk (XOR keystream + base64) and emits a mangled
loader that decodes, decrypts, compiles (`loadstring`), and runs it.

- **Requires `loadstring`** — available in Roblox executors, or on the server with
  `LoadStringEnabled`. Not available in vanilla client scripts; disable `pack`
  (`--no-pack`) for those.
- The loader chunk name is `@obf.lua` so runtime errors report a stable location.

## Adding a pass

See [extending.md](extending.md). In short: implement `AstPass`/`SourcePass`,
add a config toggle, register it, and add tests + docs.
