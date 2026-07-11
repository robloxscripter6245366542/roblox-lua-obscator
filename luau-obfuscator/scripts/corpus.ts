/**
 * Corpus regression runner. Obfuscates every `.lua` file under a directory,
 * executes original vs obfuscated with an interpreter, and reports a pass rate.
 * Non-deterministic programs are skipped; tracebacks are normalized.
 *
 *   node dist/scripts/corpus.js <dir> [--seed N] [--only a,b] [--lua-bin bin]
 *
 * Intended for the LuaCrypt test suite; exits non-zero on any real mismatch.
 */
import { readdirSync, readFileSync } from 'node:fs';
import { join } from 'node:path';
import { obfuscate } from '../src/pipeline.js';
import { resolveConfig, type PassToggles } from '../src/config/config.js';
import { validateEquivalence } from '../src/validate/validator.js';

function walk(dir: string, acc: string[] = []): string[] {
  for (const e of readdirSync(dir, { withFileTypes: true })) {
    const p = join(dir, e.name);
    if (e.isDirectory()) walk(p, acc);
    else if (e.name.endsWith('.lua')) acc.push(p);
  }
  return acc;
}

function main(): void {
  const dir = process.argv[2];
  if (!dir) { process.stderr.write('usage: corpus <dir> [--seed N] [--only a,b] [--lua-bin bin]\n'); process.exit(2); }

  let seed = 7;
  let luaBin = process.env.LUA_BIN ?? 'lua5.4';
  let only: string[] | undefined;
  for (let i = 3; i < process.argv.length; i++) {
    const a = process.argv[i]!;
    if (a === '--seed') seed = Number(process.argv[++i]);
    else if (a === '--lua-bin') luaBin = process.argv[++i]!;
    else if (a === '--only') only = (process.argv[++i] ?? '').split(',');
  }

  const names = ['rename', 'encodeNumbers', 'encodeStrings', 'opaquePredicates', 'pack'] as const;
  const passes = Object.fromEntries(
    names.map((p) => [p, only ? only.includes(p) : p !== 'opaquePredicates']),
  ) as unknown as PassToggles;
  const config = resolveConfig({ seed, passes });

  const files = walk(dir).sort();
  let pass = 0; let fail = 0; let skip = 0; let err = 0;
  const failures: string[] = [];

  for (const f of files) {
    const src = readFileSync(f, 'latin1');
    let code: string;
    try { code = obfuscate(src, { config, chunkName: f }).code; }
    catch (e) { err++; fail++; failures.push(`${f}  OBF ERROR: ${(e as Error).message}`); continue; }
    const r = validateEquivalence(src, code, { luaBin });
    if (r.status === 'match') pass++;
    else if (r.status === 'nondeterministic') skip++;
    else { fail++; failures.push(`${f}  MISMATCH`); }
  }

  const comparable = pass + fail;
  process.stdout.write(
    `\ncorpus: ${dir}\n`
    + `interpreter: ${luaBin}  seed: ${seed}\n`
    + `total: ${files.length}  pass: ${pass}  fail: ${fail}  skip: ${skip}  errors: ${err}\n`
    + (comparable ? `pass rate: ${(100 * pass / comparable).toFixed(1)}%\n` : ''),
  );
  for (const line of failures.slice(0, 30)) process.stdout.write('  ' + line + '\n');
  process.exit(fail === 0 ? 0 : 1);
}

main();
