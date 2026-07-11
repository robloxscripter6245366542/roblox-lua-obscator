/**
 * Pass: string literal encoding.
 *
 * Each string literal is XOR-encrypted with a per-string salt and replaced by a
 * call to a runtime decoder `decode(cipher, salt)`. Identical strings differ in
 * the output (distinct salts). The decoder prelude is registered once and
 * captures `string`/`table` primitives into locals, so a later `_ENV` swap can't
 * break decoding.
 *
 * The decoder is referenced by a `Name` with `binding = null`, so the generator
 * emits its literal (unrenamed) name — matching the prelude declaration.
 */
import type { AstPass, PassContext } from './pass.js';
import type { Call, Chunk, Expr, NameRef } from '../ast/nodes.js';
import { mapExpressions } from '../ast/visitor.js';
import { xorEncrypt } from '../util/encoding.js';
import { stringDecoderPrelude, type StringDecoderNames } from '../runtime/templates.js';

export const encodeStrings: AstPass = {
  kind: 'ast',
  name: 'encodeStrings',
  description: 'Encrypt string literals; decode them at runtime via a mangled helper.',
  run(chunk: Chunk, ctx: PassContext): void {
    const names: StringDecoderNames = {
      decode: ctx.freshName(),
      sc: ctx.freshName(),
      sb: ctx.freshName(),
      tc: ctx.freshName(),
      cache: ctx.freshName(),
    };
    let count = 0;

    mapExpressions(chunk, (e: Expr): Expr => {
      if (e.type !== 'String') return e;
      const salt = ctx.prng.range(1, 2_147_483_000);
      const cipher = xorEncrypt(e.value, salt);
      count++;
      const decoder: NameRef = { type: 'Name', name: names.decode, binding: null, line: e.line };
      const call: Call = {
        type: 'Call',
        func: decoder,
        args: [
          { type: 'String', value: cipher, line: e.line },
          { type: 'Number', raw: String(salt), line: e.line },
        ],
        line: e.line,
      };
      // Wrap in parens so call-with-string sugar stays valid: print "x" -> print((decode(..)))
      return { type: 'Paren', expr: call, line: e.line };
    });

    if (count > 0) {
      ctx.addPrelude(stringDecoderPrelude(names));
      ctx.log.debug(`encodeStrings: ${count} string(s) encrypted`);
    }
  },
};
