# Configuration

Configuration is a plain JSON object, resolved against defaults by
`resolveConfig` (or `parseConfig` for a JSON string). The CLI loads a file via
`--config` and applies flag overrides on top.

## Keys

| Key | Type | Default | Meaning |
|-----|------|---------|---------|
| `seed` | number | `1` | PRNG seed. With `deterministic: true`, fixes all output. |
| `deterministic` | boolean | `true` | When `false`, a random seed is chosen each run (unless `seed` given). |
| `passes.rename` | boolean | `true` | Enable scope-aware renaming. |
| `passes.encodeNumbers` | boolean | `true` | Enable integer-literal encoding. |
| `passes.encodeStrings` | boolean | `true` | Enable string encryption. |
| `passes.opaquePredicates` | boolean | `false` | Enable opaque-predicate guards. |
| `passes.pack` | boolean | `true` | Enable whole-chunk packing (needs `loadstring`). |
| `indentUnit` | string | `""` | `""` = compact; e.g. `"  "` for pretty output. |
| `opaquePredicateRate` | number `[0,1]` | `0.25` | Fraction of eligible statements guarded. |

Invalid values (e.g. `opaquePredicateRate > 1`, non-object JSON) raise an
`ObfuscatorError` tagged `[config]`.

## Example: vanilla-Roblox profile

```json
{
  "seed": 7,
  "passes": { "rename": true, "encodeNumbers": true, "encodeStrings": true, "opaquePredicates": true, "pack": false }
}
```

`pack` is off, so the output is pure Luau that runs in a LocalScript.

## CLI overrides

```
--seed <n>            set seed
--random              deterministic=false
--pretty              indentUnit="  "
--no-<pass>           disable one pass
--only a,b,c          enable only the listed passes
--config <file>       load a JSON config first
```

Precedence: defaults < config file < CLI flags.
