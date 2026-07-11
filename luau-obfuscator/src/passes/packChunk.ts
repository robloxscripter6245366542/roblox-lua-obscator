/**
 * Pass: whole-chunk packing (source pass).
 *
 * Encrypts the fully generated source (XOR keystream + base64) and emits a
 * mangled loader that decodes, decrypts, compiles, and runs it. Requires
 * `loadstring` at runtime (Roblox executors, or a server with LoadStringEnabled);
 * for vanilla client scripts, disable this pass.
 */
import type { SourcePass, PassContext } from './pass.js';
import { xorEncrypt, base64Encode, chunkString } from '../util/encoding.js';
import { packLoader, type PackNames } from '../runtime/templates.js';

export const packChunk: SourcePass = {
  kind: 'source',
  name: 'pack',
  description: 'Encrypt the whole chunk and emit a standalone loader (needs loadstring).',
  run(source: string, ctx: PassContext): string {
    const key = ctx.prng.range(1, 2_147_483_000);
    const cipher = xorEncrypt(source, key);
    const parts = chunkString(base64Encode(cipher), 100);
    const names: PackNames = {
      alphabet: ctx.freshName(),
      payload: ctx.freshName(),
      joined: ctx.freshName(),
      b64dec: ctx.freshName(),
      xordec: ctx.freshName(),
      src: ctx.freshName(),
      loader: ctx.freshName(),
      fn: ctx.freshName(),
    };
    ctx.log.debug(`pack: ${source.length} bytes -> ${parts.length} base64 chunk(s)`);
    return packLoader(parts, key, names);
  },
};
