/* ferret.web.js
 * Browser/Node port of the pure-Lua ferret obfuscator (see ferret/ in this repo).
 * Semantics-preserving Lua obfuscation: numbers -> arithmetic, strings -> salted
 * XOR + load-time decoder, whole chunk -> XOR+base64 with an emitted loader.
 *
 * The build-time keystream here is bit-identical to the Lua runtime decoder it
 * emits (same LCG, computed with BigInt so it matches Lua's 64-bit integer math),
 * so obfuscated output produced in the browser runs correctly on Lua 5.1-5.4/Luau.
 *
 * Exposes Ferret.obfuscate(src, {seed, layers}) in both window and module.exports.
 */
(function (root) {
  "use strict";

  // ---- deterministic PRNG (LCG); BigInt state to match Lua exactly ----------
  function Rng(seed) {
    this.s = BigInt(((seed >>> 0) % 2147483648) >>> 0);
  }
  Rng.MOD = 2147483648n;
  Rng.prototype.int = function () {
    this.s = (this.s * 1103515245n + 12345n) % Rng.MOD;
    return Number(this.s);
  };
  Rng.prototype.range = function (lo, hi) {
    return lo + (this.int() % (hi - lo + 1));
  };
  Rng.prototype.name = function (len) {
    len = len || 6;
    var alpha = "abcdefghijklmnopqrstuvwxyz";
    var hex = "0123456789abcdef";
    var out = "_" + alpha[this.range(0, alpha.length - 1)];
    for (var i = 0; i < len; i++) out += hex[this.range(0, 15)];
    return out;
  };

  // ---- keystream identical to the emitted Lua decoder ------------------------
  // Park-Miller LCG (mult 16807, mod 2^31-1). Every product stays below 2^53,
  // so it is exact in plain JS doubles AND in Luau/Lua 5.1 doubles and Lua 5.4
  // integers -- output decodes identically on every runtime (incl. Roblox).
  function keystream(salt, n) {
    var st = (salt % 2147483646) + 1;
    var out = new Array(n);
    for (var i = 0; i < n; i++) {
      st = (st * 16807) % 2147483647;
      out[i] = st % 256;
    }
    return out;
  }

  // ============================ LEXER ========================================
  var KEYWORDS = {
    "and": 1, "break": 1, "do": 1, "else": 1, "elseif": 1, "end": 1, "false": 1,
    "for": 1, "function": 1, "goto": 1, "if": 1, "in": 1, "local": 1, "nil": 1,
    "not": 1, "or": 1, "repeat": 1, "return": 1, "then": 1, "true": 1, "until": 1,
    "while": 1
  };
  var SYMBOLS = ["...", "..", "::", "==", "~=", "<=", ">=", "//", "<<", ">>",
    "+", "-", "*", "/", "%", "^", "#", "&", "~", "|", "<", ">", "=",
    "(", ")", "{", "}", "[", "]", ";", ":", ",", "."];

  function isDigit(c) { return c >= "0" && c <= "9"; }
  function isHex(c) { return (c >= "0" && c <= "9") || (c >= "a" && c <= "f") || (c >= "A" && c <= "F"); }
  function isAlpha(c) { return (c >= "a" && c <= "z") || (c >= "A" && c <= "Z") || c === "_"; }
  function isAlphaNum(c) { return isAlpha(c) || isDigit(c); }

  // Lua strings are byte strings. A JS string is UTF-16 code units, so a source
  // character like "×" (U+00D7) or an emoji is one JS char whose charCodeAt is a
  // code *point* (possibly > 255), not a byte. Encoding/escaping code points
  // directly corrupts multibyte text and can emit invalid escapes like "\312".
  // Re-encode the whole source to its raw UTF-8 bytes up front (each element a
  // byte 0-255, as a Latin1 string) so every downstream pass — lexing, XOR,
  // base64, decimal-escape emission — is byte-accurate, exactly like the Lua
  // reference implementation.
  function toUtf8Bytes(str) {
    var out = [];
    for (var i = 0; i < str.length; i++) {
      var c = str.charCodeAt(i);
      if (c < 0x80) {
        out.push(c);
      } else if (c < 0x800) {
        out.push(0xC0 | (c >> 6), 0x80 | (c & 0x3F));
      } else if (c >= 0xD800 && c <= 0xDBFF) {
        var c2 = str.charCodeAt(i + 1);
        if (c2 >= 0xDC00 && c2 <= 0xDFFF) {
          var cp = 0x10000 + ((c - 0xD800) << 10) + (c2 - 0xDC00);
          i++;
          out.push(0xF0 | (cp >> 18), 0x80 | ((cp >> 12) & 0x3F),
                   0x80 | ((cp >> 6) & 0x3F), 0x80 | (cp & 0x3F));
        } else {
          out.push(0xEF, 0xBF, 0xBD); // lone high surrogate -> U+FFFD
        }
      } else if (c >= 0xDC00 && c <= 0xDFFF) {
        out.push(0xEF, 0xBF, 0xBD); // lone low surrogate -> U+FFFD
      } else {
        out.push(0xE0 | (c >> 12), 0x80 | ((c >> 6) & 0x3F), 0x80 | (c & 0x3F));
      }
    }
    // Assemble in chunks so a huge byte array never overflows the call stack via
    // String.fromCharCode.apply.
    var parts = [];
    for (var k = 0; k < out.length; k += 8192) {
      parts.push(String.fromCharCode.apply(null, out.slice(k, k + 8192)));
    }
    return parts.join("");
  }

  // Encode a Unicode code point as UTF-8 bytes (mirrors Lua's \u{...}), returned
  // as a byte string so it slots straight into the byte-oriented buffer.
  function utf8esc(cp) {
    if (cp < 0x80) return String.fromCharCode(cp);
    var bytes = [];
    var mfb = 0x3f, x = cp;
    do {
      bytes.push(0x80 + (x % 0x40));
      x = Math.floor(x / 0x40);
      mfb = Math.floor(mfb / 2);
    } while (x > mfb);
    var first = ((255 - mfb) * 2) % 256 + x;
    var res = [first];
    for (var i = bytes.length - 1; i >= 0; i--) res.push(bytes[i]);
    return res.map(function (b) { return String.fromCharCode(b); }).join("");
  }

  function tokenize(src, chunkname) {
    chunkname = chunkname || "input";
    src = toUtf8Bytes(src);
    var tokens = [];
    var pos = 0, line = 1;
    var n = src.length;

    function err(msg) { throw new Error(chunkname + ":" + line + ": " + msg); }
    function peek(o) { return src.charAt(pos + (o || 0)); }

    function newline() {
      var c = peek(); pos++;
      var c2 = peek();
      if ((c2 === "\n" || c2 === "\r") && c2 !== c) pos++;
      line++;
    }

    function readLongBracket() {
      if (peek() !== "[") return null;
      var level = 0, p = pos + 1;
      while (src.charAt(p) === "=") { level++; p++; }
      if (src.charAt(p) !== "[") return null;
      pos = p + 1;
      if (peek() === "\r" || peek() === "\n") newline();
      var buf = [];
      var close = "]" + "=".repeat(level) + "]";
      while (true) {
        if (pos >= n) err("unfinished long bracket");
        var c = peek();
        if (c === "]" && src.substr(pos, close.length) === close) {
          pos += close.length;
          return buf.join("");
        } else if (c === "\n" || c === "\r") {
          buf.push("\n"); newline();
        } else { buf.push(c); pos++; }
      }
    }

    function readString(quote) {
      pos++;
      var buf = [];
      while (true) {
        if (pos >= n) err("unfinished string");
        var c = peek();
        if (c === quote) { pos++; break; }
        else if (c === "\n" || c === "\r") err("unfinished string");
        else if (c === "\\") {
          pos++;
          var e = peek();
          if (e === "n") { buf.push("\n"); pos++; }
          else if (e === "t") { buf.push("\t"); pos++; }
          else if (e === "r") { buf.push("\r"); pos++; }
          else if (e === "a") { buf.push("\x07"); pos++; }
          else if (e === "b") { buf.push("\b"); pos++; }
          else if (e === "f") { buf.push("\f"); pos++; }
          else if (e === "v") { buf.push("\x0b"); pos++; }
          else if (e === "\\") { buf.push("\\"); pos++; }
          else if (e === '"') { buf.push('"'); pos++; }
          else if (e === "'") { buf.push("'"); pos++; }
          else if (e === "\n" || e === "\r") { buf.push("\n"); newline(); }
          else if (e === "x") {
            pos++;
            var h = "";
            for (var k = 0; k < 2; k++) { if (isHex(peek())) { h += peek(); pos++; } }
            if (h.length === 0) err("hexadecimal digit expected");
            buf.push(String.fromCharCode(parseInt(h, 16)));
          } else if (e === "u") {
            // \u{XXXX}: Unicode code point, UTF-8 encoded (Lua 5.3+/Luau).
            pos++;
            if (peek() !== "{") err("missing '{' in \\u{XXXX}");
            pos++;
            var uh = "";
            while (isHex(peek())) { uh += peek(); pos++; }
            if (uh.length === 0) err("hexadecimal digit expected");
            if (peek() !== "}") err("missing '}' in \\u{XXXX}");
            pos++;
            var ucp = parseInt(uh, 16);
            if (ucp > 0x7FFFFFFF) err("UTF-8 value too large");
            buf.push(utf8esc(ucp));
          } else if (e === "z") {
            pos++;
            while (pos < n) {
              var w = peek();
              if (w === "\n" || w === "\r") newline();
              else if (w === " " || w === "\t" || w === "\f" || w === "\x0b") pos++;
              else break;
            }
          } else if (isDigit(e)) {
            var d = "";
            for (var j = 0; j < 3; j++) { if (isDigit(peek())) { d += peek(); pos++; } else break; }
            var num = parseInt(d, 10);
            if (num > 255) err("decimal escape too large");
            buf.push(String.fromCharCode(num));
          } else err("invalid escape sequence '\\" + e + "'");
        } else { buf.push(c); pos++; }
      }
      return buf.join("");
    }

    function readNumber() {
      var start = pos;
      if (peek() === "0" && (peek(1) === "x" || peek(1) === "X")) {
        pos += 2;
        while (isHex(peek()) || peek() === ".") pos++;
        if (peek() === "p" || peek() === "P") {
          pos++;
          if (peek() === "+" || peek() === "-") pos++;
          while (isDigit(peek())) pos++;
        }
      } else {
        while (isDigit(peek()) || peek() === ".") pos++;
        if (peek() === "e" || peek() === "E") {
          pos++;
          if (peek() === "+" || peek() === "-") pos++;
          while (isDigit(peek())) pos++;
        }
      }
      return src.substring(start, pos);
    }

    while (pos < n) {
      var c = peek();
      var tokStart = pos;
      if (c === "\n" || c === "\r") { newline(); }
      else if (c === " " || c === "\t" || c === "\f" || c === "\x0b") { pos++; }
      else if (c === "-" && peek(1) === "-") {
        pos += 2;
        if (peek() === "[") {
          var saved = pos;
          var content = readLongBracket();
          if (content === null) {
            pos = saved;
            while (pos < n && peek() !== "\n" && peek() !== "\r") pos++;
          }
        } else {
          while (pos < n && peek() !== "\n" && peek() !== "\r") pos++;
        }
      } else if (isAlpha(c)) {
        while (isAlphaNum(peek())) pos++;
        var word = src.substring(tokStart, pos);
        tokens.push({ type: KEYWORDS[word] ? "keyword" : "name", value: word, line: line, raw: word });
      } else if (isDigit(c) || (c === "." && isDigit(peek(1)))) {
        var ln = line;
        var numText = readNumber();
        tokens.push({ type: "number", value: numText, line: ln, raw: numText });
      } else if (c === '"' || c === "'") {
        var ln2 = line;
        var sval = readString(c);
        tokens.push({ type: "string", value: sval, line: ln2, raw: src.substring(tokStart, pos), long: false });
      } else if (c === "[" && (peek(1) === "[" || peek(1) === "=")) {
        var ln3 = line;
        var lc = readLongBracket();
        if (lc !== null) {
          tokens.push({ type: "string", value: lc, line: ln3, raw: src.substring(tokStart, pos), long: true });
        } else {
          tokens.push({ type: "symbol", value: "[", line: ln3, raw: "[" });
          pos++;
        }
      } else {
        var matched = null;
        for (var si = 0; si < SYMBOLS.length; si++) {
          if (src.substr(pos, SYMBOLS[si].length) === SYMBOLS[si]) { matched = SYMBOLS[si]; break; }
        }
        if (!matched) err("unexpected symbol near '" + c + "'");
        tokens.push({ type: "symbol", value: matched, line: line, raw: matched });
        pos += matched.length;
      }
    }
    tokens.push({ type: "eof", value: "<eof>", line: line });
    return tokens;
  }

  // ============================ EMIT =========================================
  var SYMCHARS = {};
  "+-*/%^#&~|<>=(){}[];:,.".split("").forEach(function (ch) { SYMCHARS[ch] = true; });
  function isWord(ch) { return ch !== "" && /[A-Za-z0-9_]/.test(ch); }
  function isSym(ch) { return SYMCHARS[ch] === true; }

  function stringLiteral(s) {
    var out = ['"'];
    for (var i = 0; i < s.length; i++) {
      var b = s.charCodeAt(i) & 0xFF; // byte string: never emit an escape > 255
      if (b === 34) out.push('\\"');
      else if (b === 92) out.push("\\\\");
      else if (b >= 32 && b <= 126) out.push(String.fromCharCode(b));
      else out.push("\\" + ("00" + b).slice(-3));
    }
    out.push('"');
    return out.join("");
  }

  function needSpace(prev, cur) {
    var lp = prev.raw.charAt(prev.raw.length - 1);
    var fc = cur.raw.charAt(0);
    if (isWord(lp) && isWord(fc)) return true;
    if (isSym(lp) && isSym(fc)) return true;
    if (prev.type === "number" && fc === ".") return true;
    return false;
  }

  function emit(tokens) {
    var out = [];
    var prev = null, prevLine = 1;
    for (var i = 0; i < tokens.length; i++) {
      var tok = tokens[i];
      if (tok.type === "eof") break;
      if (prev === null) { prevLine = tok.line; }
      else if (tok.line && tok.line > prevLine) { out.push("\n"); prevLine = tok.line; }
      else if (needSpace(prev, tok)) { out.push(" "); }
      out.push(tok.raw);
      prev = tok;
    }
    return out.join("");
  }

  // ============================ LAYERS =======================================
  function encryptString(s, salt) {
    var ks = keystream(salt, s.length);
    var out = [];
    for (var i = 0; i < s.length; i++) out.push(String.fromCharCode(s.charCodeAt(i) ^ ks[i]));
    return out.join("");
  }

  function decoderCallTokens(fnName, cipher, salt, line) {
    return [
      { type: "symbol", value: "(", raw: "(", line: line },
      { type: "name", value: fnName, raw: fnName, line: line },
      { type: "symbol", value: "(", raw: "(", line: line },
      { type: "string", value: cipher, raw: stringLiteral(cipher), line: line },
      { type: "symbol", value: ",", raw: ",", line: line },
      { type: "number", value: salt, raw: String(salt), line: line },
      { type: "symbol", value: ")", raw: ")", line: line },
      { type: "symbol", value: ")", raw: ")", line: line }
    ];
  }

  function stringEncrypt(tokens, rng, names) {
    var out = [];
    for (var i = 0; i < tokens.length; i++) {
      var tok = tokens[i];
      if (tok.type === "string") {
        var salt = rng.range(1, 2147483000);
        var cipher = encryptString(tok.value, salt);
        var rep = decoderCallTokens(names.fs, cipher, salt, tok.line);
        for (var j = 0; j < rep.length; j++) out.push(rep[j]);
      } else out.push(tok);
    }
    return out;
  }

  function numberEncode(tokens, rng) {
    var out = [];
    for (var i = 0; i < tokens.length; i++) {
      var tok = tokens[i];
      if (tok.type === "number" && typeof tok.raw === "string" &&
          /^[0-9]+$/.test(tok.raw) && tok.raw.length <= 9) {
        var num = parseInt(tok.raw, 10);
        var b = rng.range(1, 1000000);
        var a = num + b;
        out.push({ type: "symbol", value: "(", raw: "(", line: tok.line });
        out.push({ type: "number", value: a, raw: String(a), line: tok.line });
        out.push({ type: "symbol", value: "-", raw: "-", line: tok.line });
        out.push({ type: "number", value: b, raw: String(b), line: tok.line });
        out.push({ type: "symbol", value: ")", raw: ")", line: tok.line });
      } else out.push(tok);
    }
    return out;
  }

  function buildPrelude(names) {
    var fs = names.fs, sc = names.sc, sb = names.sb, tc = names.tc, cache = names.cache;
    return [
      "local " + sc + "=string.char",
      "local " + sb + "=string.byte",
      "local " + tc + "=table.concat",
      "local " + cache + "={}",
      "local function " + fs + "(e,s)",
      "local ck=s..'|'..e",
      "local cv=" + cache + "[ck]",
      "if cv~=nil then return cv end",
      "local t={}",
      "local st=s%2147483646+1",
      "for i=1,#e do",
      "st=(st*16807)%2147483647",
      "local k=st%256",
      "local a,b=" + sb + "(e,i),k",
      "local r,p=0,1",
      "while a>0 or b>0 do",
      "local aa,bb=a%2,b%2",
      "if aa~=bb then r=r+p end",
      "a=(a-aa)/2 b=(b-bb)/2 p=p*2",
      "end",
      "t[i]=" + sc + "(r)",
      "end",
      "local out=" + tc + "(t)",
      cache + "[ck]=out",
      "return out",
      "end"
    ].join("\n");
  }

  function makeNames(rng) {
    return { fs: rng.name(6), sc: rng.name(6), sb: rng.name(6), tc: rng.name(6), cache: rng.name(6) };
  }

  // ============================ PACK =========================================
  var B64 = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/";

  function xorStreamStr(data, key) {
    var ks = keystream(key, data.length);
    var out = [];
    for (var i = 0; i < data.length; i++) out.push(String.fromCharCode(data.charCodeAt(i) ^ ks[i]));
    return out.join("");
  }

  function b64encode(data) {
    var out = [], len = data.length;
    for (var i = 0; i < len; i += 3) {
      var b1 = data.charCodeAt(i);
      var b2 = i + 1 < len ? data.charCodeAt(i + 1) : 0;
      var b3 = i + 2 < len ? data.charCodeAt(i + 2) : 0;
      var num = b1 * 65536 + b2 * 256 + b3;
      out.push(B64.charAt(Math.floor(num / 262144) % 64));
      out.push(B64.charAt(Math.floor(num / 4096) % 64));
      out.push(i + 1 < len ? B64.charAt(Math.floor(num / 64) % 64) : "=");
      out.push(i + 2 < len ? B64.charAt(num % 64) : "=");
    }
    return out.join("");
  }

  function chunkStr(s, n) {
    var t = [];
    for (var i = 0; i < s.length; i += n) t.push(s.substr(i, n));
    return t;
  }

  function pack(body, rng) {
    var key = rng.range(1, 2147483000);
    var cipher = xorStreamStr(body, key);
    var encoded = b64encode(cipher);
    var parts = chunkStr(encoded, 100);

    var nP = rng.name(6), nS = rng.name(6), nA = rng.name(6), nBd = rng.name(6),
        nXd = rng.name(6), nSrc = rng.name(6), nLd = rng.name(6), nFn = rng.name(6);

    var L = [];
    var alphaBytes = [];
    for (var i = 0; i < B64.length; i++) alphaBytes.push(String(B64.charCodeAt(i)));
    L.push("local " + nA + "=string.char(" + alphaBytes.join(",") + ")");

    L.push("local " + nP + "={");
    for (var p = 0; p < parts.length; p++) {
      L.push("'" + parts[p] + "'" + (p < parts.length - 1 ? "," : ""));
    }
    L.push("}");
    L.push("local " + nS + "=table.concat(" + nP + ")");

    L.push("local function " + nBd + "(s)");
    L.push("  local r,v,b={},0,0");
    L.push("  s=s:gsub('[^'.." + nA + "..'=]','')");
    L.push("  for i=1,#s do");
    L.push("    local c=s:sub(i,i)");
    L.push("    if c=='=' then break end");
    L.push("    local p=" + nA + ":find(c,1,true)");
    L.push("    if not p then break end");
    L.push("    v=v*64+(p-1) b=b+6");
    L.push("    if b>=8 then b=b-8 r[#r+1]=string.char(math.floor(v/2^b)%256) v=v%(2^b) end");
    L.push("  end");
    L.push("  return table.concat(r)");
    L.push("end");

    L.push("local function " + nXd + "(d,k)");
    L.push("  local r,st={},k%2147483646+1");
    L.push("  for i=1,#d do");
    L.push("    st=(st*16807)%2147483647");
    L.push("    local a,b=d:byte(i),st%256");
    L.push("    local x,p=0,1");
    L.push("    while a>0 or b>0 do");
    L.push("      local aa,bb=a%2,b%2");
    L.push("      if aa~=bb then x=x+p end");
    L.push("      a=(a-aa)/2 b=(b-bb)/2 p=p*2");
    L.push("    end");
    L.push("    r[i]=string.char(x)");
    L.push("  end");
    L.push("  return table.concat(r)");
    L.push("end");

    L.push("local " + nSrc + "=" + nXd + "(" + nBd + "(" + nS + ")," + String(key) + ")");
    L.push("local " + nLd + "=loadstring or load");
    L.push("local " + nFn + "=" + nLd + "(" + nSrc + ",'@obf.lua')");
    L.push("return " + nFn + "()");

    return L.join("\n") + "\n";
  }

  // ============================ PIPELINE =====================================
  var DEFAULT_LAYERS = ["numbers", "strings", "pack"];

  function has(set, name) { return set.indexOf(name) !== -1; }

  function obfuscate(src, opts) {
    opts = opts || {};
    var rng = new Rng(opts.seed || 1);
    var names = makeNames(rng);
    var layers = opts.layers || DEFAULT_LAYERS;

    var tokens = tokenize(src, opts.chunkname);

    if (has(layers, "numbers")) tokens = numberEncode(tokens, rng);

    var usedStrings = false;
    if (has(layers, "strings")) { tokens = stringEncrypt(tokens, rng, names); usedStrings = true; }

    var body = emit(tokens);
    if (usedStrings) body = buildPrelude(names) + "\n" + body;
    if (has(layers, "pack")) body = pack(body, rng);
    return body;
  }

  function roundtrip(src) { return emit(tokenize(src)); }

  var Ferret = { obfuscate: obfuscate, roundtrip: roundtrip, DEFAULT_LAYERS: DEFAULT_LAYERS, tokenize: tokenize };
  root.Ferret = Ferret;
  if (typeof module !== "undefined" && module.exports) module.exports = Ferret;
})(typeof window !== "undefined" ? window : this);
