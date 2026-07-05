/* Lua/Luau obfuscator engine — tokenizer + scope-aware renamer + string/number
 * encoding + junk injection + whole-file XOR/base64 wrapper.
 * Works standalone in a <script> tag (window.LuaObfuscator) or under Node (module.exports).
 */
(function (root, factory) {
  if (typeof module === 'object' && module.exports) {
    module.exports = factory();
  } else {
    root.LuaObfuscator = factory();
  }
})(typeof self !== 'undefined' ? self : this, function () {
  'use strict';

  // ══════════════════════════════════════════════════════════════
  //  TOKENIZER
  // ══════════════════════════════════════════════════════════════
  const KEYWORDS = new Set([
    'and', 'break', 'do', 'else', 'elseif', 'end', 'false', 'for', 'function',
    'goto', 'if', 'in', 'local', 'nil', 'not', 'or', 'repeat', 'return',
    'then', 'true', 'until', 'while', 'continue'
  ]);

  function tokenize(src) {
    const tokens = [];
    const n = src.length;
    let i = 0;

    function longBracketLevel(pos) {
      if (src[pos] !== '[') return -1;
      let j = pos + 1, level = 0;
      while (src[j] === '=') { level++; j++; }
      if (src[j] === '[') return level;
      return -1;
    }
    function readLongBracket(pos, level) {
      let j = pos + 1 + level + 1;
      if (src[j] === '\r') { j++; if (src[j] === '\n') j++; }
      else if (src[j] === '\n') { j++; if (src[j] === '\r') j++; }
      const closeSeq = ']' + '='.repeat(level) + ']';
      const closeIdx = src.indexOf(closeSeq, j);
      if (closeIdx === -1) throw new Error('Unterminated long bracket at ' + pos);
      return { content: src.slice(j, closeIdx), end: closeIdx + closeSeq.length };
    }

    while (i < n) {
      const c = src[i];

      if (c === ' ' || c === '\t' || c === '\r' || c === '\n') {
        let j = i;
        while (j < n && /[ \t\r\n]/.test(src[j])) j++;
        tokens.push({ type: 'ws', value: src.slice(i, j) });
        i = j; continue;
      }

      if (c === '-' && src[i + 1] === '-') {
        const lvl = longBracketLevel(i + 2);
        if (lvl >= 0) {
          const { end } = readLongBracket(i + 2, lvl);
          tokens.push({ type: 'longcomment', value: src.slice(i, end) });
          i = end; continue;
        }
        let j = i + 2;
        while (j < n && src[j] !== '\n') j++;
        tokens.push({ type: 'comment', value: src.slice(i, j) });
        i = j; continue;
      }

      {
        const lvl = longBracketLevel(i);
        if (lvl >= 0) {
          const { content, end } = readLongBracket(i, lvl);
          tokens.push({ type: 'longstring', value: src.slice(i, end), content });
          i = end; continue;
        }
      }

      if (c === '"' || c === "'") {
        const quote = c; let j = i + 1; let raw = c;
        while (j < n) {
          const ch = src[j];
          if (ch === '\\') { raw += ch + (src[j + 1] || ''); j += 2; continue; }
          if (ch === quote) { raw += ch; j++; break; }
          if (ch === '\n') throw new Error('Unterminated string at ' + i);
          raw += ch; j++;
        }
        tokens.push({ type: 'string', value: raw });
        i = j; continue;
      }

      // Luau backtick string interpolation — pass through opaque & unmodified
      if (c === '`') {
        let j = i + 1; let raw = c; let depth = 0;
        while (j < n) {
          const ch = src[j];
          if (ch === '\\') { raw += ch + (src[j + 1] || ''); j += 2; continue; }
          if (ch === '{') depth++;
          if (ch === '}') depth = Math.max(0, depth - 1);
          if (ch === '`' && depth === 0) { raw += ch; j++; break; }
          raw += ch; j++;
        }
        tokens.push({ type: 'interpstring', value: raw });
        i = j; continue;
      }

      if (/[0-9]/.test(c) || (c === '.' && /[0-9]/.test(src[i + 1] || ''))) {
        let j = i;
        if (c === '0' && (src[i + 1] === 'x' || src[i + 1] === 'X')) {
          j = i + 2;
          while (j < n && /[0-9a-fA-F]/.test(src[j])) j++;
          if (src[j] === '.') { j++; while (j < n && /[0-9a-fA-F]/.test(src[j])) j++; }
          if (src[j] === 'p' || src[j] === 'P') {
            j++; if (src[j] === '+' || src[j] === '-') j++;
            while (j < n && /[0-9]/.test(src[j])) j++;
          }
        } else {
          while (j < n && /[0-9]/.test(src[j])) j++;
          if (src[j] === '.') { j++; while (j < n && /[0-9]/.test(src[j])) j++; }
          if (src[j] === 'e' || src[j] === 'E') {
            j++; if (src[j] === '+' || src[j] === '-') j++;
            while (j < n && /[0-9]/.test(src[j])) j++;
          }
        }
        tokens.push({ type: 'number', value: src.slice(i, j) });
        i = j; continue;
      }

      if (/[A-Za-z_]/.test(c)) {
        let j = i;
        while (j < n && /[A-Za-z0-9_]/.test(src[j])) j++;
        const word = src.slice(i, j);
        tokens.push({ type: KEYWORDS.has(word) ? 'keyword' : 'name', value: word });
        i = j; continue;
      }

      const three = src.slice(i, i + 3);
      const two = src.slice(i, i + 2);
      if (three === '...' || three === '//=' || three === '..=') {
        tokens.push({ type: 'symbol', value: three }); i += 3; continue;
      }
      if (['==', '~=', '<=', '>=', '..', '::', '//', '+=', '-=', '*=', '/=', '%=', '^='].includes(two)) {
        tokens.push({ type: 'symbol', value: two }); i += 2; continue;
      }
      tokens.push({ type: 'symbol', value: c }); i++;
    }
    tokens.push({ type: 'eof', value: '' });
    return tokens;
  }

  function decodeShortString(raw) {
    const quote = raw[0];
    const body = raw.slice(1, -1);
    let out = '';
    for (let i = 0; i < body.length; i++) {
      const c = body[i];
      if (c !== '\\') { out += c; continue; }
      const nc = body[i + 1];
      if (nc === 'n') { out += '\n'; i++; }
      else if (nc === 't') { out += '\t'; i++; }
      else if (nc === 'r') { out += '\r'; i++; }
      else if (nc === 'a') { out += '\x07'; i++; }
      else if (nc === 'b') { out += '\b'; i++; }
      else if (nc === 'f') { out += '\f'; i++; }
      else if (nc === 'v') { out += '\v'; i++; }
      else if (nc === '\\') { out += '\\'; i++; }
      else if (nc === '"') { out += '"'; i++; }
      else if (nc === "'") { out += "'"; i++; }
      else if (nc === '\n') { out += '\n'; i++; }
      else if (nc === '\r') { out += '\n'; i++; if (body[i + 2] === '\n') i++; }
      else if (nc === 'x') {
        const hex = body.slice(i + 2, i + 4);
        out += String.fromCharCode(parseInt(hex, 16) || 0);
        i += 3;
      } else if (nc >= '0' && nc <= '9') {
        let digits = nc, k = i + 2;
        while (digits.length < 3 && body[k] >= '0' && body[k] <= '9') { digits += body[k]; k++; }
        out += String.fromCharCode(parseInt(digits, 10) & 0xFF);
        i = k - 1;
      } else if (nc === 'z') {
        let k = i + 2;
        while (k < body.length && /\s/.test(body[k])) k++;
        i = k - 1;
      } else if (nc === undefined) {
        // trailing backslash, nothing to do
      } else {
        out += nc; i++;
      }
    }
    return out;
  }

  // ══════════════════════════════════════════════════════════════
  //  UTIL
  // ══════════════════════════════════════════════════════════════
  function randInt(min, max) { return min + Math.floor(Math.random() * (max - min + 1)); }
  const ID_START = 'abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ';
  const ID_CONT = ID_START + '0123456789';

  function makeNameGenerator(source) {
    const used = new Set();
    return function next(len) {
      len = len || randInt(4, 7);
      let name;
      do {
        name = '_' + ID_START[randInt(0, ID_START.length - 1)];
        for (let i = 1; i < len; i++) name += ID_CONT[randInt(0, ID_CONT.length - 1)];
      } while (used.has(name) || source.includes(name));
      used.add(name);
      return name;
    };
  }

  // ══════════════════════════════════════════════════════════════
  //  IDENTIFIER RENAMER (scope-aware, single linear pass)
  // ══════════════════════════════════════════════════════════════
  const CONTINUATION_SYMBOLS = new Set([
    '.', ':', '(', '[', ',', '+', '-', '*', '/', '%', '^', '..', '//',
    '==', '~=', '<', '>', '<=', '>=', '=', '+=', '-=', '*=', '/=', '%=', '^=', '..=', '//='
  ]);
  const CONTINUATION_KEYWORDS = new Set(['and', 'or']);

  function isTerminalToken(tok) {
    if (!tok) return false;
    if (tok.type === 'name' || tok.type === 'number' || tok.type === 'string' ||
      tok.type === 'longstring' || tok.type === 'interpstring') return true;
    if (tok.type === 'keyword' && ['true', 'false', 'nil', 'end'].includes(tok.value)) return true;
    if (tok.type === 'symbol' && [')', ']', '}', '...'].includes(tok.value)) return true;
    return false;
  }
  function continuesExpr(tok) {
    if (tok.type === 'symbol') return CONTINUATION_SYMBOLS.has(tok.value);
    if (tok.type === 'keyword') return CONTINUATION_KEYWORDS.has(tok.value);
    return false;
  }

  // Names that must never be renamed (Roblox/Lua environment & stdlib surface).
  const RESERVED_GLOBALS = new Set([
    'game', 'workspace', 'script', 'shared', '_G', '_ENV', 'plugin',
    'print', 'warn', 'error', 'assert', 'pcall', 'xpcall', 'select', 'type',
    'typeof', 'tostring', 'tonumber', 'ipairs', 'pairs', 'next', 'unpack',
    'rawget', 'rawset', 'rawequal', 'rawlen', 'setmetatable', 'getmetatable',
    'loadstring', 'load', 'require', 'newproxy', 'getfenv', 'setfenv', 'collectgarbage',
    'string', 'table', 'math', 'os', 'io', 'coroutine', 'utf8', 'bit32', 'bit', 'debug',
    'Instance', 'Vector2', 'Vector3', 'CFrame', 'Color3', 'UDim2', 'UDim', 'Enum',
    'BrickColor', 'Ray', 'Region3', 'TweenInfo', 'Rect', 'Random'
  ]);

  function renameIdentifiers(sig, nameGen) {
    const stack = [{ map: new Map() }]; // scope frames (top = innermost)
    const brackets = []; // '(' | '[' | '{'
    const forCtx = []; // stack of booleans: are we inside a for-clause header?
    const deferred = []; // {depth, run()}

    function lookup(name) {
      for (let f = stack.length - 1; f >= 0; f--) {
        if (stack[f].map.has(name)) return stack[f].map.get(name);
      }
      return null;
    }
    function declare(name) {
      if (RESERVED_GLOBALS.has(name)) return name; // don't shadow-rename reserved names defensively
      const mangled = nameGen();
      stack[stack.length - 1].map.set(name, mangled);
      return mangled;
    }

    let prevTok = null;
    let depth = 0; // bracket depth

    for (let idx = 0; idx < sig.length; idx++) {
      const tok = sig[idx];

      // Resolve any deferred activations/pops whose boundary has arrived.
      while (deferred.length && deferred[deferred.length - 1].depth === depth &&
        isTerminalToken(prevTok) && !continuesExpr(tok)) {
        deferred.pop().run();
      }

      if (tok.type === 'symbol') {
        if (tok.value === '(' || tok.value === '[' || tok.value === '{') { brackets.push(tok.value); depth++; }
        else if (tok.value === ')' || tok.value === ']' || tok.value === '}') { brackets.pop(); depth--; }
      }

      if (tok.type === 'keyword') {
        if (tok.value === 'function') {
          // Read optional dotted/colon name chain as *references* (outer scope), then push a frame for params+body.
          let j = idx + 1;
          if (sig[j] && sig[j].type === 'name') {
            const mangled = lookup(sig[j].value);
            if (mangled) sig[j].value = mangled;
            j++;
            while (sig[j] && sig[j].type === 'symbol' && (sig[j].value === '.' || sig[j].value === ':')) {
              j += 2; // skip the dot/colon and the field name (not renamed)
            }
          }
          stack.push({ map: new Map(), kind: 'function' });
          // Parameter list is declared directly into the new frame — always fresh bindings.
          if (sig[j] && sig[j].type === 'symbol' && sig[j].value === '(') {
            j++;
            while (sig[j] && !(sig[j].type === 'symbol' && sig[j].value === ')')) {
              if (sig[j].type === 'name') {
                sig[j]._isDecl = true;
                sig[j].value = declare(sig[j].value);
              }
              j++;
            }
          }
          prevTok = tok; continue;
        }
        if (tok.value === 'local') {
          if (sig[idx + 1] && sig[idx + 1].type === 'keyword' && sig[idx + 1].value === 'function') {
            // local function NAME(...) — NAME is visible inside its own body (recursion).
            const nameTok = sig[idx + 2];
            if (nameTok && nameTok.type === 'name') {
              nameTok._isDecl = true;
              nameTok.value = declare(nameTok.value);
            }
            prevTok = tok; continue; // the `function` keyword token right after will push the body frame
          }
          // Plain `local Name, Name2 = explist` — collect names, defer activation.
          let j = idx + 1;
          const pendingNames = [];
          while (true) {
            if (sig[j] && sig[j].type === 'name') {
              sig[j]._isDecl = true;
              pendingNames.push(sig[j]);
              j++;
              // skip Luau attribute <const>/<close>
              if (sig[j] && sig[j].type === 'symbol' && sig[j].value === '<') {
                while (sig[j] && !(sig[j].type === 'symbol' && sig[j].value === '>')) j++;
                j++;
              }
              if (sig[j] && sig[j].type === 'symbol' && sig[j].value === ',') { j++; continue; }
            }
            break;
          }
          const activateDepth = depth;
          deferred.push({
            depth: activateDepth,
            run: function () {
              for (const nt of pendingNames) nt.value = declare(nt.value);
            }
          });
          prevTok = tok; continue;
        }
        if (tok.value === 'do' || tok.value === 'then' || tok.value === 'repeat') {
          stack.push({ map: new Map(), kind: tok.value });
          if (tok._forPendingNames) {
            for (const nt of tok._forPendingNames) nt.value = declare(nt.value);
          }
          prevTok = tok; continue;
        }
        if (tok.value === 'else') {
          stack.pop();
          stack.push({ map: new Map(), kind: 'else' });
          prevTok = tok; continue;
        }
        if (tok.value === 'elseif') {
          stack.pop();
          prevTok = tok; continue;
        }
        if (tok.value === 'end') {
          if (stack.length > 1) stack.pop();
          prevTok = tok; continue;
        }
        if (tok.value === 'until') {
          const untilDepth = depth;
          deferred.push({
            depth: untilDepth,
            run: function () { if (stack.length > 1) stack.pop(); }
          });
          prevTok = tok; continue;
        }
        if (tok.value === 'for') {
          let j = idx + 1;
          const pendingNames = [];
          while (sig[j] && sig[j].type === 'name') {
            sig[j]._isDecl = true;
            pendingNames.push(sig[j]); j++;
            if (sig[j] && sig[j].type === 'symbol' && sig[j].value === ',') { j++; continue; }
            break;
          }
          // Find the matching `do` for this for-clause (control exprs use OLD scope).
          let k = j, bdepth = 0;
          while (sig[k] && !(bdepth === 0 && sig[k].type === 'keyword' && sig[k].value === 'do')) {
            if (sig[k].type === 'symbol' && ['(', '[', '{'].includes(sig[k].value)) bdepth++;
            if (sig[k].type === 'symbol' && [')', ']', '}'].includes(sig[k].value)) bdepth--;
            k++;
          }
          if (sig[k]) sig[k]._forPendingNames = pendingNames; // stash on the `do` token
          prevTok = tok; continue;
        }
      }

      if (tok.type === 'name' && !tok._isDecl) {
        // Table-constructor bare key detection: `{ name = ... }` / `, name = ...` while inside `{`.
        const topBracket = brackets[brackets.length - 1];
        const next = sig[idx + 1];
        const isKeyPosition = topBracket === '{' &&
          prevTok && prevTok.type === 'symbol' && (prevTok.value === '{' || prevTok.value === ',') &&
          next && next.type === 'symbol' && next.value === '=';
        // Field/method access after `.`/`:` is never a variable reference.
        const isFieldAccess = prevTok && prevTok.type === 'symbol' && (prevTok.value === '.' || prevTok.value === ':');
        if (!isKeyPosition && !isFieldAccess) {
          const mangled = lookup(tok.value);
          if (mangled) tok.value = mangled;
        }
      }

      prevTok = tok;
    }
    // flush any still-pending deferred actions (EOF reached)
    while (deferred.length) deferred.pop().run();
    return sig;
  }

  // ══════════════════════════════════════════════════════════════
  //  NUMBER OBFUSCATION
  // ══════════════════════════════════════════════════════════════
  function obfuscateNumbers(sig) {
    for (const tok of sig) {
      if (tok.type !== 'number') continue;
      if (!/^[0-9]+$/.test(tok.value)) continue; // plain decimal integers only
      const n = parseInt(tok.value, 10);
      if (!Number.isFinite(n) || n > 0x7FFFFFFF) continue;
      const pattern = randInt(0, 2);
      if (pattern === 0) {
        const a = randInt(0, n);
        tok.value = `(${a}+${n - a})`;
      } else if (pattern === 1) {
        const a = randInt(1, 1000);
        tok.value = `(${n + a}-${a})`;
      } else {
        if (n === 0) { tok.value = '(0)'; continue; }
        const a = randInt(2, 9);
        const q = Math.floor(n / a), r = n - q * a;
        tok.value = r === 0 ? `(${a}*${q})` : `(${a}*${q}+${r})`;
      }
    }
    return sig;
  }

  // ══════════════════════════════════════════════════════════════
  //  STRING OBFUSCATION
  // ══════════════════════════════════════════════════════════════
  const MAX_STRING_ENCODE_LEN = 4000;

  function buildStringPass(sig, nameGen) {
    // First: does any string qualify? If not, skip entirely (no helper emitted).
    const candidates = sig.filter(t => (t.type === 'string' || t.type === 'longstring'));
    let qualifies = false;
    for (const tok of candidates) {
      const decoded = tok.type === 'string' ? decodeShortString(tok.value) : tok.content;
      if (decoded.length <= MAX_STRING_ENCODE_LEN) { qualifies = true; break; }
    }
    if (!qualifies) return '';

    const key = [];
    const keyLen = randInt(24, 48);
    for (let i = 0; i < keyLen; i++) key.push(randInt(0, 255));
    const bxorName = nameGen();
    const keyName = nameGen();
    const decodeName = nameGen();

    for (const tok of candidates) {
      const decoded = tok.type === 'string' ? decodeShortString(tok.value) : tok.content;
      if (decoded.length > MAX_STRING_ENCODE_LEN) continue;
      const bytes = [];
      for (let i = 0; i < decoded.length; i++) {
        bytes.push((decoded.charCodeAt(i) & 0xFF) ^ key[i % key.length]);
      }
      tok.value = `(${decodeName}({${bytes.join(',')}}))`;
    }

    return `local function ${bxorName}(a,b)local r,p=0,1 while a>0 or b>0 do if a%2~=b%2 then r=r+p end a=(a-a%2)/2 b=(b-b%2)/2 p=p*2 end return r end ` +
      `local ${keyName}={${key.join(',')}} ` +
      `local function ${decodeName}(t)local r={}for i=1,#t do r[i]=string.char(${bxorName}(t[i],${keyName}[((i-1)%#${keyName})+1]))end return table.concat(r)end `;
  }

  // ══════════════════════════════════════════════════════════════
  //  JUNK CODE
  // ══════════════════════════════════════════════════════════════
  function buildJunk(nameGen, count) {
    let out = '';
    for (let i = 0; i < count; i++) {
      const n1 = nameGen();
      const a = randInt(1, 999), b = randInt(1, 999);
      const kind = randInt(0, 2);
      if (kind === 0) out += `local ${n1}=${a}*${b}-${a * b - 1} `;
      else if (kind === 1) out += `local ${n1}={${a},${b},${a + b}} `;
      else out += `local ${n1}=(${a}>${b})and ${a} or ${b} `;
    }
    return out;
  }

  // ══════════════════════════════════════════════════════════════
  //  RENDER
  // ══════════════════════════════════════════════════════════════
  function render(sig) {
    return sig
      .filter(t => t.type !== 'ws' && t.type !== 'comment' && t.type !== 'longcomment' && t.type !== 'eof')
      .map(t => t.value)
      .join(' ');
  }

  // ══════════════════════════════════════════════════════════════
  //  FINAL WRAPPER — whole-source XOR + shuffled-base64 + scattered key
  // ══════════════════════════════════════════════════════════════
  function shuffledAlphabet() {
    const chars = 'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/'.split('');
    for (let i = chars.length - 1; i > 0; i--) {
      const j = randInt(0, i);
      [chars[i], chars[j]] = [chars[j], chars[i]];
    }
    return chars.join('');
  }

  function xorBytesJS(dataStr, key) {
    const out = [];
    for (let i = 0; i < dataStr.length; i++) {
      out.push(String.fromCharCode((dataStr.charCodeAt(i) & 0xFF) ^ key[i % key.length]));
    }
    return out.join('');
  }

  function b64encCustom(dataStr, alphabet) {
    const out = [];
    const len = dataStr.length;
    for (let i = 0; i < len; i += 3) {
      const b1 = dataStr.charCodeAt(i);
      const b2 = i + 1 < len ? dataStr.charCodeAt(i + 1) : 0;
      const b3 = i + 2 < len ? dataStr.charCodeAt(i + 2) : 0;
      const n = b1 * 65536 + b2 * 256 + b3;
      out.push(alphabet[(n >>> 18) & 63]);
      out.push(alphabet[(n >>> 12) & 63]);
      out.push(i + 1 < len ? alphabet[(n >>> 6) & 63] : '=');
      out.push(i + 2 < len ? alphabet[n & 63] : '=');
    }
    return out.join('');
  }

  function charLit(s) {
    const t = [];
    for (let i = 0; i < s.length; i++) t.push(s.charCodeAt(i));
    return 'string.char(' + t.join(',') + ')';
  }

  function wrapEncrypt(source, nameGen) {
    const keyLen = randInt(48, 96);
    const key = [];
    for (let i = 0; i < keyLen; i++) key.push(randInt(1, 255));
    const alphabet = shuffledAlphabet();

    const encrypted = xorBytesJS(source, key);
    const encoded = b64encCustom(encrypted, alphabet);

    const nGroups = randInt(3, 6);
    const groupNames = [];
    const groups = [];
    let cut = 0;
    for (let g = 0; g < nGroups; g++) {
      const remaining = keyLen - cut;
      const groupsLeft = nGroups - g;
      const size = g === nGroups - 1 ? remaining : Math.max(1, Math.round(remaining / groupsLeft));
      groups.push(key.slice(cut, cut + size));
      groupNames.push(nameGen());
      cut += size;
    }

    const cAlias = nameGen(), fcAlias = nameGen(), sbAlias = nameGen(), tcAlias = nameGen(),
      mfAlias = nameGen(), ldAlias = nameGen(), aAlias = nameGen(), bdName = nameGen(),
      xdName = nameGen(), kName = nameGen(), fnName = nameGen(), erName = nameGen(), pName = nameGen();

    const lines = [];
    lines.push('-- ' + charLit('Obfuscated with the roblox-lua-obscator web tool.'));
    lines.push(`local ${cAlias}=string.char;local ${fcAlias}=string.find;local ${sbAlias}=string.sub`);
    lines.push(`local ${tcAlias}=table.concat;local ${mfAlias}=math.floor;local ${ldAlias}=loadstring or load`);

    groups.forEach((g, idx) => {
      lines.push(`local ${groupNames[idx]}={${g.join(',')}}`);
    });
    lines.push(`local ${kName}={}`);
    groupNames.forEach(gn => {
      lines.push(`for _,v in ipairs(${gn})do ${kName}[#${kName}+1]=v end`);
    });

    const alphaBytes = [];
    for (const ch of alphabet) alphaBytes.push(ch.charCodeAt(0));
    lines.push(`local ${aAlias}=${cAlias}(${alphaBytes.join(',')})`);

    lines.push(`local function ${bdName}(${pName})`);
    lines.push(`  local r,v,b={},0,0`);
    lines.push(`  ${pName}=${pName}:gsub('[^'..${aAlias}..'=]','')`);
    lines.push(`  for n=1,#${pName} do`);
    lines.push(`    local ch=${sbAlias}(${pName},n,n)`);
    lines.push(`    if ch=='=' then break end`);
    lines.push(`    local p=${fcAlias}(${aAlias},ch,1,true)`);
    lines.push(`    if not p then break end`);
    lines.push(`    v=v*64+(p-1);b=b+6`);
    lines.push(`    if b>=8 then`);
    lines.push(`      b=b-8`);
    lines.push(`      r[#r+1]=${cAlias}(${mfAlias}(v/2^b)%256)`);
    lines.push(`      v=v%(2^b)`);
    lines.push(`    end`);
    lines.push(`  end`);
    lines.push(`  return ${tcAlias}(r)`);
    lines.push(`end`);

    lines.push(`local function ${xdName}(d,k)`);
    lines.push(`  local r,kl={},#k`);
    lines.push(`  for i=1,#d do`);
    lines.push(`    local a,bv=d:byte(i),k[((i-1)%kl)+1]`);
    lines.push(`    local rs,bt=0,1`);
    lines.push(`    while a>0 or bv>0 do`);
    lines.push(`      if a%2~=bv%2 then rs=rs+bt end`);
    lines.push(`      a=${mfAlias}(a/2);bv=${mfAlias}(bv/2);bt=bt*2`);
    lines.push(`    end`);
    lines.push(`    r[i]=${cAlias}(rs)`);
    lines.push(`  end`);
    lines.push(`  return ${tcAlias}(r)`);
    lines.push(`end`);

    const chunkWidth = randInt(64, 96);
    const chunks = [];
    for (let i = 0; i < encoded.length; i += chunkWidth) chunks.push(encoded.slice(i, i + chunkWidth));
    const payloadName = nameGen(), tblName = nameGen();
    lines.push(`local ${tblName}={`);
    lines.push(chunks.map(c => `'${c}'`).join(','));
    lines.push('}');
    lines.push(`local ${payloadName}=${tcAlias}(${tblName})`);

    // Small opcode dispatcher for the final decode->decrypt->run sequence,
    // so the tail isn't three linear, easily-signatured statements.
    const stateName = nameGen(), resName = nameGen();
    const opDecode = randInt(1, 1), opDecrypt = 2, opRun = 3; // fixed order but routed through a loop
    lines.push(`local ${stateName},${resName}=1,${payloadName}`);
    lines.push(`while ${stateName}<=3 do`);
    lines.push(`  if ${stateName}==1 then ${resName}=${bdName}(${resName})`);
    lines.push(`  elseif ${stateName}==2 then ${resName}=${xdName}(${resName},${kName})`);
    lines.push(`  else`);
    lines.push(`    local ${fnName},${erName}=${ldAlias}(${resName})`);
    lines.push(`    if not ${fnName} then`);
    lines.push(`      warn(${charLit('[roblox-lua-obscator] load error: ')}..tostring(${erName}))`);
    lines.push(`    else`);
    lines.push(`      ${fnName}()`);
    lines.push(`    end`);
    lines.push(`  end`);
    lines.push(`  ${stateName}=${stateName}+1`);
    lines.push(`end`);

    return lines.join('\n') + '\n';
  }

  // ══════════════════════════════════════════════════════════════
  //  ORCHESTRATOR
  // ══════════════════════════════════════════════════════════════
  function obfuscate(source, options) {
    options = Object.assign({
      renameLocals: true, numbers: true, strings: true, junk: true, wrap: true
    }, options || {});

    const tokens = tokenize(source);
    const sig = tokens.filter(t => t.type !== 'ws' && t.type !== 'comment' && t.type !== 'longcomment');
    const nameGen = makeNameGenerator(source);

    if (options.renameLocals) renameIdentifiers(sig, nameGen);
    if (options.numbers) obfuscateNumbers(sig);
    let stringPreamble = '';
    if (options.strings) stringPreamble = buildStringPass(sig, nameGen);

    let body = stringPreamble + render(sig);
    if (options.junk) body = buildJunk(nameGen, randInt(2, 4)) + body;

    let finalCode = body;
    if (options.wrap) finalCode = wrapEncrypt(body, nameGen);

    return {
      code: finalCode,
      stats: {
        originalSize: source.length,
        outputSize: finalCode.length,
        originalLines: source.split('\n').length
      }
    };
  }

  return { obfuscate, tokenize, decodeShortString };
});
