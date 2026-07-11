# @ferret/luau-obfuscator

A production-quality, **AST-based, semantics-preserving** source-to-source
obfuscator for **Luau** (Roblox) and Lua 5.1–5.4. It parses the complete
executable grammar, transforms the AST through a configurable pass pipeline, and
regenerates valid Luau whose behavior is identical to the input.

> For protecting code **you own**. Obfuscation raises the cost of reading and
> copying source; it is not a substitute for server authority or access control.

## Highlights

- **Correctness first.** Every transform preserves behavior. A validator executes
  the original and the obfuscated program and diffs their output; the corpus
  regression runs the LuaCrypt suite and the unit suite includes behavior
  equivalence checks on Lua 5.4.
- **Verified on real Luau**, not just Lua: the runtime keystream is double-safe
  (Park-Miller, products < 2^53) so encrypted strings decode identically on
  Roblox.
- **Modular & typed.** Strict TypeScript. Clear stages: lexer → parser → AST →
  scope analysis → passes → generator → validator.
- **Extensible.** New passes are self-contained modules added to one registry;
  no existing code changes (open/closed).
- **Configurable.** Every pass is independently toggleable; deterministic or
  random seeds; compact or pretty output.

## Install & build

```sh
cd luau-obfuscator
npm install
npm run build
```

## CLI

```sh
# all passes, deterministic
node dist/src/cli/cli.js input.lua -o out.lua --seed 7 --validate

# vanilla-Roblox-safe (no loadstring): disable pack
node dist/src/cli/cli.js input.lua --no-pack

# only rename, pretty-printed
node dist/src/cli/cli.js input.lua --only rename --pretty

# list passes
node dist/src/cli/cli.js --list-passes
```

`--validate` runs the original vs the output through `lua5.4` (or `--lua-bin`)
and confirms identical behavior.

## Library

```ts
import { obfuscate, resolveConfig } from '@ferret/luau-obfuscator';

const config = resolveConfig({ seed: 7, passes: { pack: false } });
const { code } = obfuscate(sourceString, { config });
```

## Passes

| Pass | Kind | Effect |
|------|------|--------|
| `rename` | AST | Rename locals/params/loop vars to opaque names, respecting scope. |
| `encodeNumbers` | AST | Rewrite integer literals as equivalent arithmetic. |
| `encodeStrings` | AST | Encrypt string literals; decode at runtime via a mangled helper. |
| `opaquePredicates` | AST | Guard random call statements with runtime-true predicates. |
| `pack` | source | Encrypt the whole chunk + emit a loader (needs `loadstring`). |

See [`docs/passes.md`](docs/passes.md) for details and semantics notes.

## Roblox / Luau targeting

- **Vanilla LocalScript/ModuleScript:** disable `pack` (`--no-pack`). The output
  uses only core Luau (`string`/`table` + arithmetic) and runs anywhere.
- **Executors / server with `LoadStringEnabled`:** enable `pack` for an
  encrypted-blob loader.

## Configuration

A JSON file (`--config ferret.config.json`) or inline overrides. See
[`docs/configuration.md`](docs/configuration.md).

```json
{
  "seed": 7,
  "deterministic": true,
  "passes": { "rename": true, "encodeNumbers": true, "encodeStrings": true, "opaquePredicates": false, "pack": true },
  "indentUnit": "",
  "opaquePredicateRate": 0.25
}
```

## Development

```sh
npm run typecheck   # strict tsc
npm run lint        # eslint (flat config)
npm test            # unit + behavior-equivalence (needs lua5.4)
npm run coverage    # v8 coverage
npm run bench       # throughput / size / scalability
npm run corpus -- /path/to/Lua-crypt   # corpus regression
```

## Docs

- [Architecture](docs/architecture.md) · [AST](docs/ast.md) · [Passes](docs/passes.md)
- [Configuration](docs/configuration.md) · [Testing](docs/testing.md) · [Extending](docs/extending.md)

## Scope & limitations

- The parser covers the **executable** Luau grammar (statements, control flow,
  functions/closures, varargs, tables, operators, labels/goto, `continue`,
  compound assignment). **Type annotations and string interpolation are not yet
  parsed** — such files are rejected with a precise diagnostic rather than
  mis-transformed. Adding a type-annotation front end is the next milestone.
- `debug.getlocal`/`getupvalue`/`traceback` observe renamed locals by design;
  programs that assert on those values will differ (this is correct behavior for
  an obfuscator). See [docs/testing.md](docs/testing.md).
