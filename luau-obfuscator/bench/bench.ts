/**
 * Benchmarks: parse / transform / generate throughput, output-size ratio, and
 * scalability. Generates synthetic Luau of increasing size and reports timings.
 *
 *   node dist/bench/bench.js [--sizes 100,1000,10000]
 */
import { performance } from 'node:perf_hooks';
import { parse } from '../src/parser/parser.js';
import { generate } from '../src/codegen/generator.js';
import { obfuscate } from '../src/pipeline.js';
import { resolveConfig } from '../src/config/config.js';

function synth(functions: number): string {
  const out: string[] = ['local M = {}'];
  for (let i = 0; i < functions; i++) {
    out.push(
      `function M.f${i}(a, b, ...)`,
      `  local t = { a, b, "item${i}", ${i} }`,
      `  local s = 0`,
      `  for k = 1, #t do if type(t[k]) == "number" then s = s + t[k] end end`,
      `  return s, ("f${i}:" .. tostring(s))`,
      `end`,
    );
  }
  out.push('return M');
  return out.join('\n');
}

function time<T>(fn: () => T): [T, number] {
  const t0 = performance.now();
  const v = fn();
  return [v, performance.now() - t0];
}

function main(): void {
  const arg = process.argv.find((a) => a.startsWith('--sizes'));
  const sizes = arg ? arg.split('=')[1]!.split(',').map(Number) : [50, 200, 1000, 4000];
  const config = resolveConfig({ seed: 7 });

  process.stdout.write(
    ['funcs', 'srcKB', 'parse ms', 'gen ms', 'obf ms', 'out/in', 'kB/s'].map((s) => s.padStart(10)).join('') + '\n',
  );

  for (const n of sizes) {
    const src = synth(n);
    const [, tParse] = time(() => parse(src));
    const chunk = parse(src);
    const [, tGen] = time(() => generate(chunk));
    const [res, tObf] = time(() => obfuscate(src, { config }));
    const kbps = (src.length / 1024) / (tObf / 1000);
    const row = [
      String(n),
      (src.length / 1024).toFixed(1),
      tParse.toFixed(2),
      tGen.toFixed(2),
      tObf.toFixed(2),
      (res.outputBytes / res.inputBytes).toFixed(2),
      kbps.toFixed(0),
    ];
    process.stdout.write(row.map((s) => s.padStart(10)).join('') + '\n');
  }
}

main();
