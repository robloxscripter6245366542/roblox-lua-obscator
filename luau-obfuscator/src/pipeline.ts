/**
 * The transformation pipeline: source -> AST -> (AST passes) -> generated
 * source -> (source passes) -> obfuscated source. Each pass is gated by its
 * config toggle and is independently enableable.
 */
import { parse } from './parser/parser.js';
import { generate } from './codegen/generator.js';
import { Prng } from './util/prng.js';
import { Logger } from './logger.js';
import type { ResolvedConfig, PassToggles } from './config/config.js';
import type { PassContext } from './passes/pass.js';
import { AST_PASSES, SOURCE_PASSES } from './passes/registry.js';

export interface ObfuscateOptions {
  readonly config: ResolvedConfig;
  readonly chunkName?: string;
  readonly logger?: Logger;
}

export interface ObfuscateResult {
  readonly code: string;
  readonly seed: number;
  readonly appliedPasses: string[];
  readonly inputBytes: number;
  readonly outputBytes: number;
}

function isEnabled(config: ResolvedConfig, passName: string): boolean {
  return config.passes[passName as keyof PassToggles] === true;
}

export function obfuscate(source: string, options: ObfuscateOptions): ObfuscateResult {
  const { config } = options;
  const chunkName = options.chunkName ?? 'input.lua';
  const log = options.logger ?? new Logger('silent');
  const prng = new Prng(config.seed);

  const preludes: string[] = [];
  const usedNames = new Set<string>();
  const applied: string[] = [];

  const ctx: PassContext = {
    prng,
    config,
    log,
    chunkName,
    addPrelude: (src) => { preludes.push(src); },
    freshName: () => {
      let name: string;
      do { name = prng.identifier(false); } while (usedNames.has(name));
      usedNames.add(name);
      return name;
    },
  };

  const chunk = parse(source, chunkName);

  for (const pass of AST_PASSES) {
    if (!isEnabled(config, pass.name)) continue;
    log.info(`pass: ${pass.name}`);
    pass.run(chunk, ctx);
    applied.push(pass.name);
  }

  let code = generate(chunk, { indentUnit: config.indentUnit });
  if (preludes.length > 0) code = preludes.join('\n') + '\n' + code;

  for (const pass of SOURCE_PASSES) {
    if (!isEnabled(config, pass.name)) continue;
    log.info(`pass: ${pass.name}`);
    code = pass.run(code, ctx);
    applied.push(pass.name);
  }

  return {
    code,
    seed: config.seed,
    appliedPasses: applied,
    inputBytes: source.length,
    outputBytes: code.length,
  };
}
