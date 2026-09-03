const is = (ast, pattern) => {
    const match = (node, pat) => {
        if (!node || !pat || typeof node !== "object" || typeof pat !== "object")
            return node === pat

        for (const key in pat) {
            if (!(key in node)) return false
            const a = node[key],
                b = pat[key]

            if (Array.isArray(a) && Array.isArray(b)) {
                if (a.length < b.length) return false
                for (let i = 0; i < b.length; i++)
                    if (!match(a[i], b[i])) return false
            } else if (typeof a === "object" && typeof b === "object") {
                if (!match(a, b)) return false
            } else if (a !== b) return false
        }
        return true
    }
    return match(ast, pattern)
}

const search = (root, searchFor, results = []) => {
    if (!root || typeof root !== "object") return results

    const stack = [root]
    const seen = new WeakSet()

    while (stack.length) {
        const node = stack.pop()
        if (!node || typeof node !== "object") continue
        if (seen.has(node)) continue
        seen.add(node)

        if (node.type === searchFor)
            results.push(node)

        for (const key in node) {
            const value = node[key]
            if (Array.isArray(value))
                for (let i = value.length - 1; i >= 0; i--)
                    stack.push(value[i])
            else if (value && typeof value === "object")
                stack.push(value)
        }
    }

    return results
}

const searchV2 = (root, searchFor, dontTouch = new Set()) => {
    const results = []

    if (!root || typeof root !== "object") return results

    const stack = [root]
    const seen = new WeakSet()

    while (stack.length) {
        const node = stack.pop()

        if (!node || typeof node !== "object") continue
        if (dontTouch.has(node)) continue
        if (seen.has(node)) continue
        
        seen.add(node)

        if (node.type === searchFor)
            results.push(node)

        for (const key in node) {
            if (
                ((node.type === "AssignmentStatement" || node.type === "LocalStatement") && key === "variables") ||
                (node.type === "FunctionDeclaration" && (key === "identifier" || key === "parameters")) ||
                (node.type === "ForNumericStatement" && key === "variable") ||
                (node.type === "ForGenericStatement" && key === "variables")
            ) continue

            const value = node[key]
            if (Array.isArray(value))
                for (let i = value.length - 1; i >= 0; i--)
                    stack.push(value[i])
            else if (value && typeof value === "object")
                stack.push(value)
        }
    }

    return results
}

const searchIs = (root, searchFor, results = []) => {
    if (!root || typeof root !== "object") return results

    const stack = [root]
    const seen = new WeakSet()

    while (stack.length) {
        const node = stack.pop()
        if (!node || typeof node !== "object") continue
        if (seen.has(node)) continue
        seen.add(node)

        if (is(node, searchFor))
            results.push(node)

        for (const key in node) {
            const value = node[key]
            if (Array.isArray(value))
                for (let i = value.length - 1; i >= 0; i--)
                    stack.push(value[i])
            else if (value && typeof value === "object")
                stack.push(value)
        }
    }

    return results
}

const searchOr = (node, ...search) => {
    if (!node || typeof node !== "object") return []

    for (let i of [...search]) {
        if (node.type == i)
            return [node]
    }

    const results = []

    for (const key in node) {
        const value = node[key]

        if (Array.isArray(value))
            for (const item of value)
                for (let i of searchOr(item, ...search))
                    results.push(i) // ✅ collect results
        else if (value && typeof value === "object")
            for (let i of searchOr(value, ...search))
                results.push(i)
    }

    return results
}

const contains = (node, pattern, results) => {
    if (!node || typeof node !== "object") return

    if (is(node, pattern))
        results.push(node)

    if (Array.isArray(node)) {
        for (const item of node)
            contains(item, pattern, results)
    } else {
        for (const key in node)
            contains(node[key], pattern, results)
    }
}

const deepSearch = (node, pattern, results = []) => {
    if (!node || typeof node !== "object") return results

    contains(node, pattern, results)

    return results
}

const searchPattern = (node, ...pattern) => {
    const results = []

    const walk = (node) => {
        if (!node) return

        if (Array.isArray(node)) {
            for (let i = 0; i <= node.length - pattern.length; i++) {
                let match = true
                for (let j = 0; j < pattern.length; j++) {
                    if (!node[i + j] || node[i + j].type !== pattern[j]) {
                        match = false
                        break
                    }
                }
                if (match)
                    results.push(node.slice(i, i + pattern.length))
            }

            for (const item of node)
                walk(item)

            return
        }

        if (typeof node !== "object") return

        for (const key in node)
            walk(node[key])
    }

    walk(node)
    return results
}

const LUA_TO_JS = (luaStr) =>
    luaStr.replace(/\\(x[0-9a-fA-F]{2}|\d{1,3}|.)/g, (_, e) => {
        if (e[0] === 'x') return String.fromCharCode(parseInt(e.slice(1), 16))
        if (/\d/.test(e[0])) return String.fromCharCode(Number(e))
        return e
    })

const isNumericString = (x) => x.match(/\d+/)?.[0] == x

const isNumericTree = node =>
    node.type === "NumericLiteral" ||
    (
        node.type === "BinaryExpression" &&
        isNumericTree(node.left) &&
        isNumericTree(node.right)
    ) ||
    (
        node.type == "UnaryExpression" &&
        node.operator == "-" &&
        isNumericTree(node.argument)
    ) ||
    (
        (node.type == "StringLiteral" && isNumericString(fixRaw(node))) ||
        (node.type == "InterpolatedStringExpression" && node.parts.length == 1 && isNumericTree(node.parts[0]))
    )

const getNum = (expr) => {
    switch (expr.type) {
        case "NumericLiteral":
            return expr.value;
        case "UnaryExpression":
            return -getNum(expr.argument);
        case "StringLiteral":
            return Number(fixRaw(expr))
        case "InterpolatedStringExpression":
            return Number(fixRaw(expr.parts[0]));
        default:
            return solveMath(expr.left, expr.operator, expr.right);
    }
}

const areNumbers = (lhs, rhs) =>
    isNumericTree(lhs) && isNumericTree(rhs)

const astEqual = (a, b) => {
    if (a === b) return true
    if (!a || !b || a.type !== b.type) return false
    switch (a.type) {
        case "NumericLiteral":   return a.value === b.value
        case "Identifier":       return a.name === b.name
        case "BinaryExpression": return a.operator === b.operator && astEqual(a.left, b.left) && astEqual(a.right, b.right)
        case "UnaryExpression":  return a.operator === b.operator && astEqual(a.argument, b.argument)
        default:                 return false
    }
}

const solveMath = (leftExpr, operator, rightExpr) => {
    if (!leftExpr)
        return undefined;
    if (!operator)
        return leftExpr.type == "NumericLiteral" ? leftExpr.value : solveMath(leftExpr.left, leftExpr.operator, leftExpr.right)

    const code = operator.charCodeAt(0)

    const checkEq = (a, b, c) => {
        switch (c ?? code) {
            case 126:
                return a != b
            case 61:
                return a == b
            case 62:
                if (c)
                    return a >= b
                return a > b
            case 60:
                if (c)
                    return a <= b
                return a < b
            default:
                return undefined
        }
    }

    const isEq = operator.charCodeAt(1) == 61

    if (isEq || (code == 60 || code == 62) && operator.length == 1) {
        let value;

        if (!areNumbers(leftExpr, rightExpr)) {
            if (isLiteral(leftExpr) && isLiteral(rightExpr))
                value = checkEq(fixRaw(leftExpr.raw), fixRaw(rightExpr.raw), !isEq ? undefined : code)
        }
        else {
            const left = solveMath(leftExpr), right = solveMath(rightExpr)

            if (typeof left == "number" && typeof right == "number")
                value = checkEq(left, right, !isEq ? undefined : code)
        }

        if (value !== undefined) return value

        const flipOp = op => op == '>' ? '<' : op == '<' ? '>' : op == '>=' ? '<=' : op == '<=' ? '>=' : op
        const toNode = x => typeof x === 'number' ? { type: "NumericLiteral", value: x, raw: '' + x } : x

        let normLeft = toNode(leftExpr), normOp = operator, normRight = toNode(rightExpr)

        if (isNumericTree(normLeft) && !isNumericTree(normRight)) {
            ;[normLeft, normRight] = [normRight, normLeft]
            normOp = flipOp(normOp)
        }

        // algebra tips and tricks 101
        if (normLeft?.type == "BinaryExpression" && isNumericTree(normRight)) {
            const innerOp = normLeft.operator

            if (innerOp == '+' || innerOp == '-') {
                for (const [numPart, varPart, numOnLeft] of [
                    [normLeft.right, normLeft.left, false],
                    [normLeft.left,  normLeft.right, true],
                ]) {
                    if (!isNumericTree(numPart)) continue
                    if (numOnLeft && innerOp == '-') continue

                    const C = getNum(numPart), N = getNum(normRight)
                    if (typeof C !== 'number' || typeof N !== 'number') continue

                    const newRight = innerOp == '+' ? N - C : N + C
                    return {
                        type: "BinaryExpression",
                        left: varPart,
                        operator: normOp,
                        right: { type: "NumericLiteral", value: newRight, raw: '' + newRight }
                    }
                }
            }
        }

        return value
    }

    let left, right;
    if (areNumbers(leftExpr, rightExpr)) {
        const index = '+-/*//\^%'.indexOf(operator)

        left = getNum(leftExpr), right = getNum(rightExpr);

        if (left == null || right == null)
            return;

        let r;
        if (index == 0)
            r = left + right;
        else if (index == 1)
            r = left - right
        else if (index == 2)
            r = left / right
        else if (index == 3)
            r = left * right
        else if (index == 4)
            r = Math.floor(left / right)
        else if (index == 6)
            r = Math.pow(left, right)
        else if (index == 7)
            r = left % right

        return r;
    }
    else {
        // x - x = 0, x / x = 1

        if (astEqual(leftExpr, rightExpr)) {
            if (operator == "-") return { type: "NumericLiteral", value: 0, raw: "0" }
            if (operator == "/") return { type: "NumericLiteral", value: 1, raw: "1" }
        }

        if (operator == "*" || operator == "/" || operator == "^") {
            if (leftExpr?.value == 1)
                return rightExpr
            else if (rightExpr?.value == 1)
                return leftExpr
            else if (operator == "*" && (leftExpr?.value == 0 || rightExpr?.value == 0))
                return { type: "NumericLiteral", value: 0, raw: "0" }
        }
        else if (operator == "+" || operator == "-") {
            if (leftExpr?.value == 0)
                return rightExpr
            else if (rightExpr?.value == 0)
                return leftExpr
        }

        // Constant folding across same-group operators:
        //   (V op1 N1) op2 N2  →  V + delta   or   V * factor
        //   (N1 op1 V) op2 N2  →  same
        if (leftExpr?.type == "BinaryExpression" && isNumericTree(rightExpr)) {
            const innerOp = leftExpr.operator
            const outerOp = operator
            const additive       = (innerOp == '+' || innerOp == '-') && (outerOp == '+' || outerOp == '-')
            const multiplicative = (innerOp == '*' || innerOp == '/') && (outerOp == '*' || outerOp == '/')

            if (additive || multiplicative) {
                for (const [numPart, varPart, numOnLeft] of [
                    [leftExpr.right, leftExpr.left, false],
                    [leftExpr.left,  leftExpr.right, true],
                ]) {
                    if (!isNumericTree(numPart)) continue
                    if (numOnLeft && innerOp != (additive ? '+' : '*')) continue

                    const N1 = getNum(numPart), N2 = getNum(rightExpr)

                    if (additive) {
                        const delta = (innerOp == '+' ? N1 : -N1) + (outerOp == '+' ? N2 : -N2)
                        return solveMath(varPart, '+', { type: "NumericLiteral", value: delta, raw: '' + delta })
                    } else {
                        const factor = (innerOp == '*' ? N1 : 1 / N1) * (outerOp == '*' ? N2 : 1 / N2)
                        return solveMath(varPart, '*', { type: "NumericLiteral", value: factor, raw: '' + factor })
                    }
                }
            }
        }

        const simplifyChild = (expr) => {
            if (expr?.type != "BinaryExpression") return expr
            const simplified = solveMath(expr.left, expr.operator, expr.right)
            if (simplified == null) return null
            return typeof simplified === "number" ? { type: "NumericLiteral", value: simplified, raw: '' + simplified } : simplified
        }

        left = simplifyChild(leftExpr)
        right = simplifyChild(rightExpr)

        if (left == null || right == null) return
        if (left === leftExpr && right === rightExpr) return // nothing simplified, don't loop

        return solveMath(left, operator, right)
    }
}

const Clear = (d) => {
    for (let i in d) delete d[i]
}
const copy = (a) => {
    const n = {};
    for (let i in a) {
        n[i] = a[i]
    }
    return n;
}

const fixRaw = (raw) =>
    typeof raw == "string"
    ? LUA_TO_JS(raw.substring(1, raw.length - 1))
    : 
        raw.raw ? fixRaw(raw.raw) : raw.value

const ProtectEnv = `setfenv(1, { table = table, string = string, math = math, type = type, tonumber = tonumber, tostring = tostring, print = function()end, warn = function() end, ipairs = ipairs, pairs = pairs, getmetatable = getmetatable, setmetatable = setmetatable, wait = function() return 1 end })\n`
const literals = {
    NumericLiteral: true,
    StringLiteral: true,
    VarargLiteral: true,
    BooleanLiteral: true,
    NilLiteral: true
}

const isBetween = (n, min, max) => n >= min && n <= max
const isNumber = (s) => isBetween(s.charCodeAt(0), 48, 57)
const isWeird = (str) => (isNumber(str.substring(0)) || str.match(/[^\w_]/g))
const isLiteral = (a) => literals[a.type] ? true : false

const clone = (root) => {
    if (root === null || typeof root !== 'object')
        return root

    const seen = new WeakMap()
    const rootClone = Array.isArray(root) ? new Array(root.length) : {}
    seen.set(root, rootClone)

    const stack = [{
        src: root,
        dst: rootClone
    }]

    while (stack.length > 0) {
        const {
            src,
            dst
        } = stack.pop()
        const keys = Array.isArray(src) ? src.keys() : Object.keys(src)

        for (const k of keys) {
            const val = src[k]
            if (val !== null && typeof val === 'object') {
                if (seen.has(val)) {
                    dst[k] = seen.get(val)
                } else {
                    dst[k] = Array.isArray(val) ? new Array(val.length) : {}
                    seen.set(val, dst[k])
                    stack.push({
                        src: val,
                        dst: dst[k]
                    })
                }
            } else {
                dst[k] = val
            }
        }
    }

    return rootClone
}

const values = {
    10: "\\n",
    13: "\\r"
}

const unescapeLuau = (str) => {
	let result = "";
	let i = 0;
	while (i < str.length) {
		if (str[i] !== "\\") {
			result += str[i++];
			continue;
		}
		i++; // skip backslash
		if (i >= str.length) break;
		const c = str[i];
		switch (c) {
			case "a":
				result += "\x07";
				i++;
				break;
			case "b":
				result += "\b";
				i++;
				break;
			case "f":
				result += "\f";
				i++;
				break;
			case "n":
				result += "\n";
				i++;
				break;
			case "r":
				result += "\r";
				i++;
				break;
			case "t":
				result += "\t";
				i++;
				break;
			case "v":
				result += "\v";
				i++;
				break;
			case "\\":
				result += "\\";
				i++;
				break;
			case "'":
				result += "'";
				i++;
				break;
			case '"':
				result += '"';
				i++;
				break;
			// \<newline> — line break continuation (consume the newline)
			case "\r":
				i++;
				if (str[i] === "\n") i++;
				break;
			case "\n":
				i++;
				break;
			// \xXX — two-digit hex
			case "x": {
				result += String.fromCharCode(parseInt(str.slice(i + 1, i + 3), 16));
				i += 3;
				break;
			}
			// \u{XXXX} — unicode codepoint
			case "u": {
				const close = str.indexOf("}", i + 2);
				result += String.fromCodePoint(parseInt(str.slice(i + 2, close), 16));
				i = close + 1;
				break;
			}
			// \z — skip all following whitespace
			case "z": {
				i++;
				while (i < str.length && /\s/.test(str[i])) i++;
				break;
			}
			default: {
				// \ddd — up to 3 decimal digits (0–255)
				if (/\d/.test(c)) {
					let num = "";
					while (num.length < 3 && i < str.length && /\d/.test(str[i]))
						num += str[i++];
					result += String.fromCharCode(parseInt(num, 10));
				} else {
					// Unknown escape — preserve as-is
					result += "\\" + c;
					i++;
				}
			}
		}
	}
	return result;
};

function fixString(input, q, decodeEscapes = true) {
    input = typeof input === "string" ? input : String(input ?? "");
    if (decodeEscapes)
        input = unescapeLuau(input);
    q ??= '"';
    const qB = q.codePointAt(0);

    let result = "";

    for (const char of input) {
        const cp = char.codePointAt(0);

        if (cp === qB) {
            result += "\\" + q;
            continue;
        }

        if (cp === 92) {
            result += "\\\\";
            continue;
        }

        if (cp === 10) {
            result += "\\n";
            continue;
        }
        if (cp === 13) {
            result += "\\r";
            continue;
        }
        if (cp === 9) {
            result += "\\t";
            continue;
        }

        // Keep printable ASCII (including punctuation) readable.
        if (cp >= 0x20 && cp <= 0x7e) {
            result += char;
            continue;
        }

        // Lua strings are byte sequences; keep single-byte codepoints stable.
        const bytes = cp <= 0xff ? [cp] : Buffer.from(String.fromCodePoint(cp), "utf8");
        for (const byte of bytes) {
            result += `\\x${byte.toString(16).padStart(2, "0")}`;
        }
    }

    return result;
}

function removeValue(valueStat, idx) {
    const vars = valueStat.variables,
		init = valueStat.init;

	valueStat.init = init.filter((a) => a != init[idx]);
	valueStat.variables = vars.filter((a) => a != vars[idx]);

	if (valueStat.variables.length == 0) Clear(valueStat);
}

module.exports = {
    is,
    search,
    searchV2,
    searchOr,
    searchIs,
    deepSearch,
    searchPattern,
    solveMath,
    protectEnv: ProtectEnv,
    print: console.log,
    Clear,
    copy,
    fixRaw,
    isBetween,
    isNumber,
    isWeird,
    isLiteral,
    clone,
    fixString,
    removeValue
}