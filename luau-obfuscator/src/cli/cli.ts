#!/usr/bin/env node
/**
 * ferret CLI.
 *
 *   luau-obfuscate <input.lua> [-o out.lua] [options]
 *
 * Options:
 *   -o, --output <file>      output path (default: <input>.obf.lua)
 *   -c, --config <file>      JSON config file (ferret.config.json)
 *   --seed <n>               deterministic seed
 *   --random                 non-deterministic (random seed each run)
 *   --no-<pass>              disable a pass (rename|encodeNumbers|encodeStrings|opaquePredicates|pack)
 *   --only <a,b,c>           enable only the listed passes
 *   --pretty                 indent output (default: compact)
 *   --validate               run the obfuscated output vs original and report equivalence
 *   --lua-bin <bin>          interpreter for --validate (default: lua5.4)
 *   --list-passes            print the pass catalogue and exit
 *   --log-level <level>      silent|error|warn|info|debug
 *   -h, --help               show help
 */
import { readFileSync, writeFileSync, existsSync } from 'node:fs';
import { obfuscate } from '../pipeline.js';
import { resolveConfig, parseConfig, type UserConfig, type PassToggles } from '../config/config.js';
import { passCatalogue } from '../passes/registry.js';
import { Logger, type LogLevel } from '../logger.js';
import { validateEquivalence } from '../validate/validator.js';
import { ObfuscatorError } from '../diagnostics.js';

const PASS_NAMES = ['rename', 'encodeNumbers', 'encodeStrings', 'opaquePredicates', 'pack'] as const;

function die(msg: string): never {
  process.stderr.write(`luau-obfuscate: ${msg}\n`);
  process.exit(1);
}

function help(): void {
  process.stdout.write(`ferret - production Luau obfuscator

Usage:
  luau-obfuscate <input.lua> [-o out.lua] [options]

Options:
  -o, --output <file>    output path (default <input>.obf.lua)
  -c, --config <file>    JSON config file
  --seed <n>             deterministic seed
  --random               random seed each run
  --no-<pass>            disable a pass (${PASS_NAMES.join(' | ')})
  --only <a,b,c>         enable only the listed passes
  --pretty               indent output
  --validate             run original vs obfuscated and report equivalence
  --lua-bin <bin>        interpreter for --validate (default lua5.4)
  --list-passes          list passes and exit
  --log-level <level>    silent|error|warn|info|debug
  -h, --help             this help
`);
}

interface Args {
  input?: string;
  output?: string;
  configFile?: string;
  seed?: number;
  random?: boolean;
  pretty?: boolean;
  validate?: boolean;
  luaBin?: string;
  logLevel?: LogLevel;
  only?: string[];
  disabled: Set<string>;
}

function parseArgs(argv: string[]): Args {
  const args: Args = { disabled: new Set() };
  for (let i = 0; i < argv.length; i++) {
    const a = argv[i]!;
    if (a === '-h' || a === '--help') { help(); process.exit(0); }
    else if (a === '--list-passes') {
      for (const p of passCatalogue()) process.stdout.write(`${p.name.padEnd(18)} [${p.kind}] ${p.description}\n`);
      process.exit(0);
    } else if (a === '-o' || a === '--output') args.output = argv[++i];
    else if (a === '-c' || a === '--config') args.configFile = argv[++i];
    else if (a === '--seed') args.seed = Number(argv[++i]);
    else if (a === '--random') args.random = true;
    else if (a === '--pretty') args.pretty = true;
    else if (a === '--validate') args.validate = true;
    else if (a === '--lua-bin') args.luaBin = argv[++i];
    else if (a === '--log-level') args.logLevel = argv[++i] as LogLevel;
    else if (a === '--only') args.only = (argv[++i] ?? '').split(',').map((s) => s.trim()).filter(Boolean);
    else if (a.startsWith('--no-')) args.disabled.add(a.slice(5));
    else if (a.startsWith('-')) die(`unknown option '${a}'`);
    else if (args.input === undefined) args.input = a;
    else die(`unexpected argument '${a}'`);
  }
  return args;
}

function main(): void {
  const args = parseArgs(process.argv.slice(2));
  if (!args.input) { help(); process.exit(args.input ? 0 : 2); }
  if (!existsSync(args.input)) die(`input not found: ${args.input}`);

  let user: UserConfig = {};
  if (args.configFile) {
    if (!existsSync(args.configFile)) die(`config not found: ${args.configFile}`);
    // resolve early so file errors surface here, then re-merge CLI overrides below
    parseConfig(readFileSync(args.configFile, 'utf8'));
    user = JSON.parse(readFileSync(args.configFile, 'utf8')) as UserConfig;
  }

  if (args.seed !== undefined) user.seed = args.seed;
  if (args.random) user.deterministic = false;
  if (args.pretty) user.indentUnit = '  ';

  const passes: Record<string, boolean> = { ...(user.passes ?? {}) };
  if (args.only) {
    for (const p of PASS_NAMES) passes[p] = args.only.includes(p);
  }
  for (const d of args.disabled) {
    if (!(PASS_NAMES as readonly string[]).includes(d)) die(`unknown pass '${d}'`);
    passes[d] = false;
  }
  user.passes = passes as Partial<PassToggles>;

  const config = resolveConfig(user);
  const logger = new Logger(args.logLevel ?? 'warn');

  const source = readFileSync(args.input, 'latin1');
  const result = obfuscate(source, { config, chunkName: args.input, logger });

  const output = args.output ?? args.input.replace(/\.lua$/, '') + '.obf.lua';
  writeFileSync(output, result.code, 'latin1');

  process.stdout.write(
    `luau-obfuscate: ${args.input} -> ${output}\n`
    + `  input : ${result.inputBytes} bytes\n`
    + `  output: ${result.outputBytes} bytes\n`
    + `  seed  : ${result.seed}\n`
    + `  passes: ${result.appliedPasses.join(', ') || '(none)'}\n`,
  );

  if (args.validate) {
    const v = validateEquivalence(source, result.code, { luaBin: args.luaBin ?? 'lua5.4' });
    if (v.status === 'match') process.stdout.write('  validate: ✓ behavior preserved\n');
    else if (v.status === 'nondeterministic') process.stdout.write('  validate: ~ original is non-deterministic (skipped)\n');
    else {
      process.stderr.write('  validate: ✗ BEHAVIOR MISMATCH\n');
      process.exit(3);
    }
  }
}

try {
  main();
} catch (e) {
  if (e instanceof ObfuscatorError) die(e.message);
  throw e;
}
