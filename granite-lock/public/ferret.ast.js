/* ferret.ast.js
 * AST front end for the ferret obfuscator: parser + scope resolver +
 * scope-aware transforms + Luau code generator.
 *
 * Unlike the token-level passes in ferret.web.js, this parses source into an
 * abstract syntax tree, which lets us reliably:
 *   - rename locals / params / loop vars while respecting scope (never globals,
 *     fields, method names, or table keys),
 *   - regenerate valid Luau,
 *   - (future) rewrite expressions and drop unused code.
 *
 * Reuses the lexer from ferret.web.js (Ferret.tokenize). Works in Node
 * (module.exports) and the browser (window.FerretAST).
 */
(function (root) {
  "use strict";

  var Base = (typeof module !== "undefined" && module.exports)
    ? require("./ferret.web.js")
    : root.Ferret;
  var tokenize = Base.tokenize;

  // ============================ PARSER =======================================
  function Parser(tokens, chunkname) {
    this.toks = tokens;
    this.i = 0;
    this.chunk = chunkname || "input";
  }
  Parser.prototype.peek = function (o) { return this.toks[this.i + (o || 0)]; };
  Parser.prototype.next = function () { return this.toks[this.i++]; };
  Parser.prototype.err = function (msg, tok) {
    tok = tok || this.peek();
    throw new Error(this.chunk + ":" + (tok ? tok.line : "?") + ": " + msg +
      (tok ? " near '" + (tok.value === undefined ? tok.type : tok.value) + "'" : ""));
  };
  Parser.prototype.is = function (type, value) {
    var t = this.peek();
    if (t.type !== type) return false;
    if (value !== undefined && t.value !== value) return false;
    return true;
  };
  Parser.prototype.isSym = function (v) { return this.is("symbol", v); };
  Parser.prototype.isKw = function (v) { return this.is("keyword", v); };
  Parser.prototype.accept = function (type, value) {
    if (this.is(type, value)) return this.next();
    return null;
  };
  Parser.prototype.expect = function (type, value) {
    if (!this.is(type, value)) this.err("expected '" + (value || type) + "'");
    return this.next();
  };
  Parser.prototype.expectName = function () {
    if (!this.is("name")) this.err("name expected");
    return this.next().value;
  };

  // ---- block / statements --------------------------------------------------
  var BLOCK_END = { "end": 1, "else": 1, "elseif": 1, "until": 1 };

  Parser.prototype.parseChunk = function () {
    var body = this.block();
    if (!this.is("eof")) this.err("'<eof>' expected");
    return { t: "Block", body: body };
  };

  Parser.prototype.block = function () {
    var stmts = [];
    while (true) {
      var t = this.peek();
      if (t.type === "eof") break;
      if (t.type === "keyword" && BLOCK_END[t.value]) break;
      if (t.type === "keyword" && t.value === "return") {
        stmts.push(this.retStat());
        break;
      }
      var s = this.statement();
      if (s) stmts.push(s);
    }
    return stmts;
  };

  Parser.prototype.retStat = function () {
    var line = this.next().line; // 'return'
    var exprs = [];
    var t = this.peek();
    var endsBlock = t.type === "eof" || (t.type === "keyword" && BLOCK_END[t.value]);
    if (!endsBlock && !this.isSym(";")) exprs = this.exprList();
    this.accept("symbol", ";");
    return { t: "Return", exprs: exprs, line: line };
  };

  Parser.prototype.statement = function () {
    var t = this.peek();
    if (t.type === "symbol" && t.value === ";") { this.next(); return null; }
    if (t.type === "symbol" && t.value === "::") return this.labelStat();
    if (t.type === "keyword") {
      switch (t.value) {
        case "break": this.next(); return { t: "Break", line: t.line };
        case "goto": this.next(); return { t: "Goto", label: this.expectName(), line: t.line };
        case "do": { this.next(); var b = this.block(); this.expect("keyword", "end"); return { t: "Do", body: b, line: t.line }; }
        case "while": return this.whileStat();
        case "repeat": return this.repeatStat();
        case "if": return this.ifStat();
        case "for": return this.forStat();
        case "function": return this.funcStat();
        case "local": return this.localStat();
      }
    }
    return this.exprStat();
  };

  Parser.prototype.labelStat = function () {
    var line = this.next().line; // '::'
    var name = this.expectName();
    this.expect("symbol", "::");
    return { t: "Label", name: name, line: line };
  };

  Parser.prototype.whileStat = function () {
    var line = this.next().line;
    var cond = this.expr();
    this.expect("keyword", "do");
    var body = this.block();
    this.expect("keyword", "end");
    return { t: "While", cond: cond, body: body, line: line };
  };

  Parser.prototype.repeatStat = function () {
    var line = this.next().line;
    var body = this.block();
    this.expect("keyword", "until");
    var cond = this.expr();
    return { t: "Repeat", body: body, cond: cond, line: line };
  };

  Parser.prototype.ifStat = function () {
    var line = this.next().line;
    var clauses = [];
    var cond = this.expr();
    this.expect("keyword", "then");
    clauses.push({ cond: cond, body: this.block() });
    while (this.isKw("elseif")) {
      this.next();
      var c = this.expr();
      this.expect("keyword", "then");
      clauses.push({ cond: c, body: this.block() });
    }
    var elseBody = null;
    if (this.accept("keyword", "else")) elseBody = this.block();
    this.expect("keyword", "end");
    return { t: "If", clauses: clauses, elseBody: elseBody, line: line };
  };

  Parser.prototype.forStat = function () {
    var line = this.next().line;
    var first = this.expectName();
    if (this.isSym("=")) {
      this.next();
      var start = this.expr();
      this.expect("symbol", ",");
      var stop = this.expr();
      var step = null;
      if (this.accept("symbol", ",")) step = this.expr();
      this.expect("keyword", "do");
      var body = this.block();
      this.expect("keyword", "end");
      return { t: "NumericFor", var: { name: first }, start: start, stop: stop, step: step, body: body, line: line };
    }
    var names = [{ name: first }];
    while (this.accept("symbol", ",")) names.push({ name: this.expectName() });
    this.expect("keyword", "in");
    var exprs = this.exprList();
    this.expect("keyword", "do");
    var gbody = this.block();
    this.expect("keyword", "end");
    return { t: "GenericFor", names: names, exprs: exprs, body: gbody, line: line };
  };

  Parser.prototype.funcStat = function () {
    var line = this.next().line; // 'function'
    // funcname: Name {'.' Name} [':' Name]
    var base = { name: this.expectName() };
    var path = [];
    var method = null;
    while (this.isSym(".")) { this.next(); path.push(this.expectName()); }
    if (this.accept("symbol", ":")) method = this.expectName();
    var func = this.funcBody(line, method !== null);
    return { t: "FunctionDecl", base: base, path: path, method: method, func: func, isLocal: false, line: line };
  };

  Parser.prototype.localStat = function () {
    var line = this.next().line; // 'local'
    if (this.accept("keyword", "function")) {
      var name = { name: this.expectName() };
      var func = this.funcBody(line, false);
      return { t: "FunctionDecl", base: name, path: [], method: null, func: func, isLocal: true, line: line };
    }
    var names = [this.localName()];
    while (this.accept("symbol", ",")) names.push(this.localName());
    var exprs = [];
    if (this.accept("symbol", "=")) exprs = this.exprList();
    return { t: "LocalAssign", names: names, exprs: exprs, line: line };
  };

  Parser.prototype.localName = function () {
    var name = this.expectName();
    var attrib = null;
    if (this.accept("symbol", "<")) { attrib = this.expectName(); this.expect("symbol", ">"); }
    return { name: name, attrib: attrib };
  };

  Parser.prototype.funcBody = function (line, isMethod) {
    this.expect("symbol", "(");
    var params = [];
    var isVararg = false;
    if (isMethod) params.push({ name: "self", implicit: true });
    if (!this.isSym(")")) {
      do {
        if (this.isSym("...")) { this.next(); isVararg = true; break; }
        params.push({ name: this.expectName() });
      } while (this.accept("symbol", ","));
    }
    this.expect("symbol", ")");
    var body = this.block();
    this.expect("keyword", "end");
    return { t: "Function", params: params, isVararg: isVararg, body: body, line: line };
  };

  Parser.prototype.exprStat = function () {
    var line = this.peek().line;
    var first = this.suffixedExpr();
    if (this.isSym("=") || this.isSym(",")) {
      var targets = [first];
      while (this.accept("symbol", ",")) targets.push(this.suffixedExpr());
      this.expect("symbol", "=");
      var exprs = this.exprList();
      for (var k = 0; k < targets.length; k++) {
        var tg = targets[k];
        if (tg.t !== "Name" && tg.t !== "Index" && tg.t !== "Field")
          this.err("cannot assign to this expression");
      }
      return { t: "Assign", targets: targets, exprs: exprs, line: line };
    }
    if (first.t !== "Call" && first.t !== "MethodCall") this.err("syntax error (expected statement)");
    return { t: "CallStat", call: first, line: line };
  };

  // ---- expressions ---------------------------------------------------------
  var BINPRI = {
    "or": [1, 1], "and": [2, 2],
    "<": [3, 3], ">": [3, 3], "<=": [3, 3], ">=": [3, 3], "~=": [3, 3], "==": [3, 3],
    "|": [4, 4], "~": [5, 5], "&": [6, 6], "<<": [7, 7], ">>": [7, 7],
    "..": [9, 8], "+": [10, 10], "-": [10, 10],
    "*": [11, 11], "/": [11, 11], "//": [11, 11], "%": [11, 11],
    "^": [14, 13]
  };
  var UNARY_PRI = 12;
  var UNOPS = { "-": 1, "not": 1, "#": 1, "~": 1 };

  Parser.prototype.exprList = function () {
    var list = [this.expr()];
    while (this.accept("symbol", ",")) list.push(this.expr());
    return list;
  };

  Parser.prototype.expr = function () { return this.subExpr(0); };

  Parser.prototype.isBinop = function () {
    var t = this.peek();
    if (t.type === "symbol" && BINPRI[t.value]) return t.value;
    if (t.type === "keyword" && (t.value === "and" || t.value === "or")) return t.value;
    return null;
  };
  Parser.prototype.isUnop = function () {
    var t = this.peek();
    if (t.type === "symbol" && (t.value === "-" || t.value === "#" || t.value === "~")) return t.value;
    if (t.type === "keyword" && t.value === "not") return t.value;
    return null;
  };

  Parser.prototype.subExpr = function (limit) {
    var e;
    var u = this.isUnop();
    if (u) {
      var line = this.next().line;
      var operand = this.subExpr(UNARY_PRI);
      e = { t: "Unop", op: u, operand: operand, line: line };
    } else {
      e = this.simpleExpr();
    }
    var op;
    while ((op = this.isBinop()) && BINPRI[op][0] > limit) {
      var oline = this.next().line;
      var right = this.subExpr(BINPRI[op][1]);
      e = { t: "Binop", op: op, left: e, right: right, line: oline };
    }
    return e;
  };

  Parser.prototype.simpleExpr = function () {
    var t = this.peek();
    if (t.type === "number") { this.next(); return { t: "Number", raw: t.raw, line: t.line }; }
    if (t.type === "string") { this.next(); return { t: "String", value: t.value, raw: t.raw, long: t.long, line: t.line }; }
    if (t.type === "keyword") {
      if (t.value === "nil") { this.next(); return { t: "Nil", line: t.line }; }
      if (t.value === "true") { this.next(); return { t: "True", line: t.line }; }
      if (t.value === "false") { this.next(); return { t: "False", line: t.line }; }
      if (t.value === "function") { var l = this.next().line; return this.funcBody(l, false); }
    }
    if (t.type === "symbol") {
      if (t.value === "...") { this.next(); return { t: "Vararg", line: t.line }; }
      if (t.value === "{") return this.tableConstructor();
    }
    return this.suffixedExpr();
  };

  Parser.prototype.primaryExpr = function () {
    var t = this.peek();
    if (t.type === "symbol" && t.value === "(") {
      this.next();
      var e = this.expr();
      this.expect("symbol", ")");
      return { t: "Paren", expr: e, line: t.line };
    }
    if (t.type === "name") { this.next(); return { t: "Name", name: t.value, line: t.line }; }
    this.err("unexpected symbol");
  };

  Parser.prototype.suffixedExpr = function () {
    var e = this.primaryExpr();
    while (true) {
      var t = this.peek();
      if (t.type === "symbol" && t.value === ".") {
        this.next();
        e = { t: "Field", obj: e, name: this.expectName(), line: t.line };
      } else if (t.type === "symbol" && t.value === "[") {
        this.next();
        var idx = this.expr();
        this.expect("symbol", "]");
        e = { t: "Index", obj: e, index: idx, line: t.line };
      } else if (t.type === "symbol" && t.value === ":") {
        this.next();
        var m = this.expectName();
        var args = this.callArgs();
        e = { t: "MethodCall", obj: e, method: m, args: args, line: t.line };
      } else if ((t.type === "symbol" && (t.value === "(" || t.value === "{")) || t.type === "string") {
        var a = this.callArgs();
        e = { t: "Call", func: e, args: a, line: t.line };
      } else break;
    }
    return e;
  };

  Parser.prototype.callArgs = function () {
    var t = this.peek();
    if (t.type === "string") { this.next(); return [{ t: "String", value: t.value, raw: t.raw, long: t.long, line: t.line }]; }
    if (t.type === "symbol" && t.value === "{") return [this.tableConstructor()];
    this.expect("symbol", "(");
    var args = [];
    if (!this.isSym(")")) args = this.exprList();
    this.expect("symbol", ")");
    return args;
  };

  Parser.prototype.tableConstructor = function () {
    var line = this.expect("symbol", "{").line;
    var fields = [];
    while (!this.isSym("}")) {
      if (this.isSym("[")) {
        this.next();
        var key = this.expr();
        this.expect("symbol", "]");
        this.expect("symbol", "=");
        fields.push({ kind: "keyed", key: key, value: this.expr() });
      } else if (this.is("name") && this.peek(1).type === "symbol" && this.peek(1).value === "=") {
        var nm = this.next().value;
        this.next(); // '='
        fields.push({ kind: "named", key: nm, value: this.expr() });
      } else {
        fields.push({ kind: "item", value: this.expr() });
      }
      if (!this.accept("symbol", ",") && !this.accept("symbol", ";")) break;
    }
    this.expect("symbol", "}");
    return { t: "Table", fields: fields, line: line };
  };

  function parse(src, chunkname) {
    var toks = tokenize(src, chunkname);
    return new Parser(toks, chunkname).parseChunk();
  }

  // ============================ GENERATOR ====================================
  // Emits valid Luau. Binops/unops are fully parenthesized so precedence is
  // always preserved without tracking it. nameOf(node) lets the rename pass
  // swap identifiers by returning binding.newName when present.
  function stringLit(s) {
    var out = ['"'];
    for (var i = 0; i < s.length; i++) {
      var b = s.charCodeAt(i);
      if (b === 34) out.push('\\"');
      else if (b === 92) out.push("\\\\");
      else if (b >= 32 && b <= 126) out.push(String.fromCharCode(b));
      else out.push("\\" + ("00" + b).slice(-3));
    }
    out.push('"');
    return out.join("");
  }

  function Gen() { this.buf = []; }
  Gen.prototype.w = function (s) { this.buf.push(s); };
  Gen.prototype.result = function () { return this.buf.join(""); };

  // nameOf: declaration/reference identifier -> emitted text
  function nameOf(obj) { return obj.binding && obj.binding.newName ? obj.binding.newName : obj.name; }

  Gen.prototype.block = function (stmts, indent) {
    for (var i = 0; i < stmts.length; i++) {
      var s = stmts[i];
      var line = this.stmt(s, indent);
      // guard the prefixexp ambiguity: a statement starting with '(' could
      // otherwise fuse with the previous line as a call.
      if (line.charAt(0) === "(") this.w(indent + ";" + line + "\n");
      else this.w(indent + line + "\n");
    }
  };

  Gen.prototype.stmt = function (s, indent) {
    switch (s.t) {
      case "LocalAssign": {
        var ns = s.names.map(function (n) {
          return nameOf(n) + (n.attrib ? "<" + n.attrib + ">" : "");
        }).join(",");
        var out = "local " + ns;
        if (s.exprs.length) out += "=" + this.exprList(s.exprs);
        return out;
      }
      case "Assign":
        return this.targetList(s.targets) + "=" + this.exprList(s.exprs);
      case "CallStat":
        return this.expr(s.call);
      case "Do":
        return "do\n" + this.subBlock(s.body, indent) + indent + "end";
      case "While":
        return "while " + this.expr(s.cond) + " do\n" + this.subBlock(s.body, indent) + indent + "end";
      case "Repeat":
        return "repeat\n" + this.subBlock(s.body, indent) + indent + "until " + this.expr(s.cond);
      case "If": {
        var out = "";
        for (var i = 0; i < s.clauses.length; i++) {
          out += (i === 0 ? "if " : indent + "elseif ") + this.expr(s.clauses[i].cond) + " then\n"
            + this.subBlock(s.clauses[i].body, indent);
        }
        if (s.elseBody) out += indent + "else\n" + this.subBlock(s.elseBody, indent);
        out += indent + "end";
        return out;
      }
      case "NumericFor": {
        var o = "for " + nameOf(s.var) + "=" + this.expr(s.start) + "," + this.expr(s.stop);
        if (s.step) o += "," + this.expr(s.step);
        o += " do\n" + this.subBlock(s.body, indent) + indent + "end";
        return o;
      }
      case "GenericFor": {
        var names = s.names.map(nameOf).join(",");
        return "for " + names + " in " + this.exprList(s.exprs) + " do\n"
          + this.subBlock(s.body, indent) + indent + "end";
      }
      case "FunctionDecl": {
        var head;
        if (s.isLocal) {
          return "local function " + nameOf(s.base) + this.funcTail(s.func, indent);
        }
        head = nameOf(s.base);
        for (var p = 0; p < s.path.length; p++) head += "." + s.path[p];
        if (s.method) head += ":" + s.method;
        return "function " + head + this.funcTail(s.func, indent);
      }
      case "Return":
        return s.exprs.length ? "return " + this.exprList(s.exprs) : "return";
      case "Break": return "break";
      case "Goto": return "goto " + s.label;
      case "Label": return "::" + s.name + "::";
      default: throw new Error("gen: unknown stmt " + s.t);
    }
  };

  Gen.prototype.subBlock = function (stmts, indent) {
    var g = new Gen();
    g.block(stmts, indent + "  ");
    return g.result();
  };

  Gen.prototype.funcTail = function (fn, indent) {
    var params = fn.params.filter(function (p) { return !p.implicit; }).map(nameOf);
    if (fn.isVararg) params.push("...");
    return "(" + params.join(",") + ")\n" + this.subBlock(fn.body, indent) + indent + "end";
  };

  Gen.prototype.targetList = function (list) {
    var self = this;
    return list.map(function (e) { return self.expr(e); }).join(",");
  };
  Gen.prototype.exprList = function (list) {
    var self = this;
    return list.map(function (e) { return self.expr(e); }).join(",");
  };

  Gen.prototype.expr = function (e) {
    switch (e.t) {
      case "Nil": return "nil";
      case "True": return "true";
      case "False": return "false";
      case "Vararg": return "...";
      case "Number": return e.raw;
      case "String": return stringLit(e.value);
      case "Name": return nameOf(e);
      case "Paren": return "(" + this.expr(e.expr) + ")";
      case "Field": return this.expr(e.obj) + "." + e.name;
      case "Index": return this.expr(e.obj) + "[" + this.expr(e.index) + "]";
      case "Call": return this.callTarget(e.func) + "(" + this.exprList(e.args) + ")";
      case "MethodCall": return this.callTarget(e.obj) + ":" + e.method + "(" + this.exprList(e.args) + ")";
      case "Binop": return "(" + this.expr(e.left) + " " + e.op + " " + this.expr(e.right) + ")";
      case "Unop": return "(" + e.op + " " + this.expr(e.operand) + ")";
      case "Function": return "function" + this.funcTail(e, "");
      case "Table": return this.table(e);
      default: throw new Error("gen: unknown expr " + e.t);
    }
  };

  // A call/method target that is itself a paren/expr may need wrapping so the
  // suffix binds correctly; Name/Field/Index/Call/MethodCall/Paren are fine.
  Gen.prototype.callTarget = function (e) {
    if (e.t === "Name" || e.t === "Field" || e.t === "Index" ||
        e.t === "Call" || e.t === "MethodCall" || e.t === "Paren") return this.expr(e);
    return "(" + this.expr(e) + ")";
  };

  Gen.prototype.table = function (e) {
    var self = this;
    if (e.fields.length === 0) return "{}";
    var parts = e.fields.map(function (f) {
      if (f.kind === "item") return self.expr(f.value);
      if (f.kind === "named") return f.key + "=" + self.expr(f.value);
      return "[" + self.expr(f.key) + "]=" + self.expr(f.value);
    });
    return "{" + parts.join(",") + "}";
  };

  function generate(ast) {
    var g = new Gen();
    g.block(ast.body, "");
    return g.result();
  }

  // ============================ SCOPE RESOLVER ===============================
  // Attaches a binding object to every declaration name and every Name
  // reference. References that resolve to no local binding are globals and are
  // left untouched. Upvalues need no special case: a closure referencing an
  // outer local resolves to that same binding, so renaming it once is enough.
  function newScope(parent) { return { vars: {}, parent: parent }; }

  function declare(ctx, scope, obj, fixed) {
    var b = { name: obj.name, newName: null, fixed: !!fixed };
    obj.binding = b;
    scope.vars[obj.name] = b;
    ctx.bindings.push(b);
    return b;
  }
  function resolveRef(scope, node) {
    var s = scope;
    while (s) {
      if (Object.prototype.hasOwnProperty.call(s.vars, node.name)) { node.binding = s.vars[node.name]; return; }
      s = s.parent;
    }
    node.binding = null; // global / builtin
  }

  function rExpr(ctx, e, scope) {
    if (!e) return;
    switch (e.t) {
      case "Name": resolveRef(scope, e); break;
      case "Paren": rExpr(ctx, e.expr, scope); break;
      case "Field": rExpr(ctx, e.obj, scope); break;
      case "Index": rExpr(ctx, e.obj, scope); rExpr(ctx, e.index, scope); break;
      case "Call": rExpr(ctx, e.func, scope); e.args.forEach(function (a) { rExpr(ctx, a, scope); }); break;
      case "MethodCall": rExpr(ctx, e.obj, scope); e.args.forEach(function (a) { rExpr(ctx, a, scope); }); break;
      case "Binop": rExpr(ctx, e.left, scope); rExpr(ctx, e.right, scope); break;
      case "Unop": rExpr(ctx, e.operand, scope); break;
      case "Function": rFunction(ctx, e, scope); break;
      case "Table":
        e.fields.forEach(function (f) {
          if (f.kind === "keyed") rExpr(ctx, f.key, scope);
          rExpr(ctx, f.value, scope);
        });
        break;
      default: break; // literals, Vararg
    }
  }

  function rFunction(ctx, fn, scope) {
    var fs = newScope(scope);
    fn.params.forEach(function (p) { declare(ctx, fs, p, p.implicit === true); });
    fn.body.forEach(function (st) { rStmt(ctx, st, fs); });
  }

  function rBlock(ctx, stmts, parent) {
    var s = newScope(parent);
    stmts.forEach(function (st) { rStmt(ctx, st, s); });
  }

  function rStmt(ctx, s, scope) {
    switch (s.t) {
      case "LocalAssign":
        s.exprs.forEach(function (e) { rExpr(ctx, e, scope); });
        s.names.forEach(function (n) { declare(ctx, scope, n, false); });
        break;
      case "Assign":
        s.targets.forEach(function (e) { rExpr(ctx, e, scope); });
        s.exprs.forEach(function (e) { rExpr(ctx, e, scope); });
        break;
      case "CallStat": rExpr(ctx, s.call, scope); break;
      case "Do": rBlock(ctx, s.body, scope); break;
      case "While": rExpr(ctx, s.cond, scope); rBlock(ctx, s.body, scope); break;
      case "Repeat": {
        // until can see locals declared in the body -> shared scope
        var bs = newScope(scope);
        s.body.forEach(function (st) { rStmt(ctx, st, bs); });
        rExpr(ctx, s.cond, bs);
        break;
      }
      case "If":
        s.clauses.forEach(function (c) { rExpr(ctx, c.cond, scope); rBlock(ctx, c.body, scope); });
        if (s.elseBody) rBlock(ctx, s.elseBody, scope);
        break;
      case "NumericFor": {
        rExpr(ctx, s.start, scope); rExpr(ctx, s.stop, scope); rExpr(ctx, s.step, scope);
        var fs = newScope(scope);
        declare(ctx, fs, s.var, false);
        s.body.forEach(function (st) { rStmt(ctx, st, fs); });
        break;
      }
      case "GenericFor": {
        s.exprs.forEach(function (e) { rExpr(ctx, e, scope); });
        var gs = newScope(scope);
        s.names.forEach(function (n) { declare(ctx, gs, n, false); });
        s.body.forEach(function (st) { rStmt(ctx, st, gs); });
        break;
      }
      case "FunctionDecl":
        if (s.isLocal) {
          declare(ctx, scope, s.base, false); // visible in its own body (recursion)
          rFunction(ctx, s.func, scope);
        } else {
          resolveRef(scope, s.base);          // function a.b:c -> 'a' is a reference
          rFunction(ctx, s.func, scope);
        }
        break;
      case "Return": s.exprs.forEach(function (e) { rExpr(ctx, e, scope); }); break;
      default: break; // Break, Goto, Label
    }
  }

  function resolveScopes(ast) {
    var ctx = { bindings: [] };
    var top = newScope(null);
    ast.body.forEach(function (st) { rStmt(ctx, st, top); });
    return ctx;
  }

  // ---- rename ---------------------------------------------------------------
  function RenameRng(seed) { this.s = ((seed || 1) >>> 0) % 2147483647 || 1; }
  RenameRng.prototype.next = function () { this.s = (this.s * 16807) % 2147483647; return this.s; };
  RenameRng.prototype.name = function () {
    // "_" + digit + 6 hex. The leading digit keeps this namespace disjoint from
    // ferret.web.js's decoder/loader locals (which are "_" + letter + hex), so a
    // renamed local can never collide with the string-decoder or pack loader.
    var hex = "0123456789abcdef";
    var out = "_" + (this.next() % 10);
    for (var i = 0; i < 6; i++) out += hex[this.next() % 16];
    return out;
  };

  var KEYWORDS = { "and":1,"break":1,"do":1,"else":1,"elseif":1,"end":1,"false":1,"for":1,
    "function":1,"goto":1,"if":1,"in":1,"local":1,"nil":1,"not":1,"or":1,"repeat":1,
    "return":1,"then":1,"true":1,"until":1,"while":1 };

  function renameLocals(bindings, rng) {
    var used = {};
    bindings.forEach(function (b) {
      if (b.fixed) return;
      var nm;
      do { nm = rng.name(); } while (used[nm] || KEYWORDS[nm]);
      used[nm] = true;
      b.newName = nm;
    });
  }

  // Parse -> resolve -> rename locals -> regenerate valid Luau.
  function renameSource(src, opts) {
    opts = opts || {};
    var ast = parse(src, opts.chunkname);
    var ctx = resolveScopes(ast);
    renameLocals(ctx.bindings, opts.rng || new RenameRng(opts.seed || 1));
    return generate(ast);
  }

  // Full pipeline: AST rename (scope-aware) then the token-level layers from
  // ferret.web.js (numbers / strings / pack). "rename" is handled here; the
  // rest are delegated so both engines share one implementation.
  function obfuscate(src, opts) {
    opts = opts || {};
    var layers = opts.layers || ["rename", "numbers", "strings", "pack"];
    var out = src;
    if (layers.indexOf("rename") !== -1) {
      out = renameSource(out, { seed: opts.seed, chunkname: opts.chunkname });
    }
    var rest = layers.filter(function (l) { return l !== "rename"; });
    if (rest.length === 0) return out;
    return Base.obfuscate(out, { seed: opts.seed, layers: rest, chunkname: opts.chunkname });
  }

  var API = {
    parse: parse, generate: generate, resolveScopes: resolveScopes,
    renameLocals: renameLocals, renameSource: renameSource, RenameRng: RenameRng,
    obfuscate: obfuscate
  };
  root.FerretAST = API;
  if (typeof module !== "undefined" && module.exports) module.exports = API;
})(typeof window !== "undefined" ? window : this);
