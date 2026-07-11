# Architecture

ferret is a classic multi-stage source-to-source compiler. Data flows in one
direction; each stage has a single responsibility and a typed interface.

```
 source (Luau)
     │
     ▼
┌──────────┐   tokens    ┌──────────┐   AST     ┌──────────────┐
│  Lexer   │────────────▶│  Parser  │──────────▶│  Scope       │
│ lexer/   │             │ parser/  │           │  analysis    │
└──────────┘             └──────────┘           │ analysis/    │
                                                └──────┬───────┘
                                                       │ bindings attached
                                                       ▼
                                            ┌────────────────────┐
                                            │   AST passes        │  (rename,
                                            │   passes/*.ts       │   encodeNumbers,
                                            │   via registry      │   encodeStrings,
                                            └─────────┬───────────┘   opaquePredicates)
                                                      │ mutated AST
                                                      ▼
                                            ┌────────────────────┐
                                            │  Code generator     │  + runtime preludes
                                            │  codegen/           │
                                            └─────────┬───────────┘
                                                      │ Luau source
                                                      ▼
                                            ┌────────────────────┐
                                            │  Source passes      │  (pack)
                                            │  passes/packChunk   │
                                            └─────────┬───────────┘
                                                      ▼
                                          obfuscated Luau  ──▶  Validator
                                                                (validate/)
```

## Modules

| Path | Responsibility |
|------|----------------|
| `src/lexer/` | `token.ts` (token kinds/symbols), `lexer.ts` (byte-oriented tokenizer keeping raw text). |
| `src/parser/` | Recursive-descent parser with precedence climbing → typed AST. |
| `src/ast/` | `nodes.ts` (discriminated-union node types + `Binding`), `visitor.ts` (`mapExpressions`, `mapStatements`). |
| `src/analysis/` | `scope.ts` — lexical scope resolution; attaches a `Binding` to every declaration and reference. |
| `src/passes/` | `pass.ts` (interfaces + context), one file per pass, `registry.ts` (ordered list). |
| `src/codegen/` | `generator.ts` — AST → valid Luau, fully parenthesized, comment-free. |
| `src/runtime/` | `templates.ts` — emitted Luau helper snippets (string decoder, pack loader). |
| `src/validate/` | `validator.ts` — behavior equivalence via a Lua interpreter. |
| `src/config/` | `config.ts` — schema, defaults, JSON loader, validation. |
| `src/cli/` | `cli.ts` — argument parsing, config merge, output, `--validate`. |
| `src/util/` | `prng.ts` (Park-Miller PRNG + keystream), `encoding.ts` (XOR/base64). |

## Design decisions

- **Everything meaningful is done on the AST.** The only text-level step is
  whole-chunk `pack`, which operates after generation because it treats the
  program as an opaque blob. No regex transforms of source.
- **Full parenthesization in the generator.** Rather than track operator
  precedence during emission, every binary/unary node is wrapped in parentheses.
  This makes correctness trivial to reason about; the extra parens are irrelevant
  after packing and cheap otherwise.
- **Bindings, not name maps.** Scope resolution attaches a shared `Binding`
  object to a declaration and all its references (including upvalues across
  closures). Renaming sets `binding.newName` once and every use follows — there
  is no separate rename table to keep in sync.
- **Double-safe arithmetic in emitted runtime.** The keystream is Park-Miller
  (`st = st*16807 % 2147483647`) so all products stay < 2^53 and are exact in
  Luau/Lua 5.1 doubles as well as Lua 5.3/5.4 integers. A naïve LCG passes on
  Lua 5.4 but corrupts strings on Luau; this trap is avoided deliberately.
- **Open/closed passes.** A pass implements `AstPass` or `SourcePass` and is
  listed in `registry.ts`. The pipeline discovers passes from the registry and
  gates each by its config toggle; adding one never edits an existing pass.

## Correctness strategy

Textual round-trip is *not* the invariant (the generator is intentionally not
idempotent). The invariant is **observable behavior**: the validator executes
both programs and compares normalized output. This is enforced by the unit
equivalence suite and the corpus regression. See [testing.md](testing.md).
