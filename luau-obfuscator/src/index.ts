/**
 * Public API for the ferret Luau obfuscator.
 *
 * @example
 * import { obfuscate, resolveConfig } from '@ferret/luau-obfuscator';
 * const { code } = obfuscate(src, { config: resolveConfig({ seed: 7 }) });
 */
export { obfuscate } from './pipeline.js';
export type { ObfuscateOptions, ObfuscateResult } from './pipeline.js';
export { resolveConfig, parseConfig, DEFAULT_CONFIG } from './config/config.js';
export type { ResolvedConfig, UserConfig, PassToggles } from './config/config.js';
export { passCatalogue, ALL_PASSES } from './passes/registry.js';
export { Logger } from './logger.js';
export type { LogLevel } from './logger.js';
export { ObfuscatorError } from './diagnostics.js';

// stage-level exports for tooling and tests
export { tokenize } from './lexer/lexer.js';
export { parse, Parser } from './parser/parser.js';
export { generate, Generator, stringLiteral } from './codegen/generator.js';
export { analyzeScopes } from './analysis/scope.js';
export * as ast from './ast/nodes.js';
export { Prng, keystream } from './util/prng.js';
