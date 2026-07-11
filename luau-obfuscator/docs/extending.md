# Extending: adding a transformation pass

Passes are open/closed: a new pass is a self-contained module that you list in
the registry. No existing pass changes.

## 1. Implement the pass

Create `src/passes/myPass.ts`. Choose `AstPass` (mutate the AST) or `SourcePass`
(rewrite generated text).

```ts
import type { AstPass, PassContext } from './pass.js';
import type { Chunk } from '../ast/nodes.js';
import { mapExpressions } from '../ast/visitor.js';

export const myPass: AstPass = {
  kind: 'ast',
  name: 'myPass',                 // must match the config toggle key
  description: 'One-line summary shown by --list-passes.',
  run(chunk: Chunk, ctx: PassContext): void {
    mapExpressions(chunk, (e) => {
      // return a replacement expression (or e unchanged)
      return e;
    });
  },
};
```

`PassContext` gives you:
- `prng` — deterministic randomness (`range`, `identifier`, `next`),
- `config` — resolved config,
- `log` — leveled logger,
- `addPrelude(src)` — prepend a runtime helper snippet,
- `freshName()` — allocate an opaque helper-local name (disjoint from renamed locals).

**Preserve semantics.** Use `mapExpressions`/`mapStatements` so you touch every
site consistently. Do not wrap statements that declare locals in new blocks
(scope changes); the opaque-predicate pass only wraps `CallStat` for this reason.

## 2. Add a config toggle

In `src/config/config.ts`, add `myPass` to `PassToggles` and `DEFAULT_CONFIG.passes`.

## 3. Register it

In `src/passes/registry.ts`, import and add it to `AST_PASSES` (or `SOURCE_PASSES`)
in the correct order.

## 4. Test, benchmark, document

- Add unit tests (structure) and behavior-equivalence cases in
  `test/unit/equivalence.test.ts`.
- Confirm `npm run corpus -- /path/to/Lua-crypt` stays green.
- Document the pass in `docs/passes.md`.

A feature is not complete until tests, benchmarks, and docs exist for it.
