# AST reference

Defined in `src/ast/nodes.ts` as discriminated unions on `type`; every node
carries a `line`. Passes get exhaustiveness checking from the compiler.

## Chunk / Block

- `Chunk { body: Block }` — top level.
- `Block = Stmt[]`.

## Statements (`Stmt`)

| type | fields | notes |
|------|--------|-------|
| `LocalAssign` | `names: DeclName[]`, `exprs: Expr[]` | `local a,b = …` |
| `Assign` | `targets: Expr[]`, `exprs: Expr[]` | targets are `Name`/`Field`/`Index` |
| `CompoundAssign` | `target`, `op`, `value` | Luau `a += b`; kept verbatim (single evaluation) |
| `CallStat` | `call: Call \| MethodCall` | expression statement |
| `Do` / `While` / `Repeat` | blocks + conditions | `repeat` cond sees body scope |
| `If` | `clauses: {cond,body}[]`, `elseBody` | |
| `NumericFor` | `variable`, `start`, `stop`, `step`, `body` | |
| `GenericFor` | `names: DeclName[]`, `exprs`, `body` | |
| `FunctionDecl` | `base`, `path`, `method`, `func`, `isLocal` | `function a.b:c()` / `local function` |
| `Return` / `Break` / `Continue` / `Goto` / `Label` | | |

## Expressions (`Expr`)

Literals `Nil`/`True`/`False`/`Vararg`/`Number`/`String`; `Name` (with
`binding`); `Paren`; `Field`; `Index`; `Call`; `MethodCall`; `Function`;
`Table`; `Binop`; `Unop`.

- `Number` keeps `raw` (preserves int/float/hex forms exactly).
- `String` keeps the decoded `value`; the generator re-encodes it to a portable
  ASCII literal.
- `Paren` is preserved because parentheses truncate multi-value expressions to
  one value — dropping them would change semantics.

## Bindings

`Binding { originalName, newName, fixed, kind }` is attached by
`analysis/scope.ts` to each `DeclName`/`Param` and to every `Name` reference
(`binding = null` for globals). The generator emits `newName` when set. `fixed`
marks names that must not be renamed (implicit `self`).

## Traversal

`ast/visitor.ts`:
- `mapExpressions(chunk, e => Expr)` — post-order rewrite of every expression.
- `mapStatements(chunk, s => Stmt[])` — rewrite/expand statement lists (recurses
  into nested blocks and function declaration bodies).
