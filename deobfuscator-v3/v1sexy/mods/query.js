/**
 * Partial structural match — checks whether `node` satisfies all
 * constraints defined by `pattern` (extra keys on `node` are ignored).
 *
 * @param {*}      node
 * @param {*}      pattern
 * @returns {boolean}
 */
const is = (node, pattern) => {
	const match = (node, pat) => {
		if (!node || !pat || typeof node !== "object" || typeof pat !== "object")
			return node === pat;

		for (const key in pat) {
			if (!(key in node)) return false;
			const a = node[key],
				b = pat[key];

			if (Array.isArray(a) && Array.isArray(b)) {
				if (a.length < b.length) return false;
				for (let i = 0; i < b.length; i++) if (!match(a[i], b[i])) return false;
			} else if (typeof a === "object" && typeof b === "object") {
				if (!match(a, b)) return false;
			} else if (a !== b) return false;
		}
		return true;
	};
	return match(node, pattern);
};

/**
 * Unified AST traversal and search.
 *
 * ─────────────────────────────────────────────────────────────────────────────
 * MATCHERS  (first argument after `root`)
 * ─────────────────────────────────────────────────────────────────────────────
 *
 *   string              — match nodes whose `.type === matcher`
 *                         replaces: search(), searchV2()
 *
 *   string[]            — match nodes whose `.type` is any value in the array
 *                         replaces: searchOr()
 *
 *   plain object        — match nodes that structurally satisfy the pattern
 *                         (uses `is()`, so extra keys are ignored)
 *                         replaces: searchIs(), deepSearch()
 *
 *   { sequence: [...] } — match consecutive sibling nodes in arrays
 *                         whose `.type` values equal the sequence elements;
 *                         each result is the matching sub-array slice.
 *                         replaces: searchPattern()
 *
 * ─────────────────────────────────────────────────────────────────────────────
 * OPTIONS
 * ─────────────────────────────────────────────────────────────────────────────
 *
 *   dontTouch  {Set}              Nodes to skip entirely (subtree included).
 *                                 replaces: searchV2()'s dontTouch parameter
 *
 *   skipKey    {(node, key) => boolean}
 *                                 Return true to skip traversing node[key].
 *                                 replaces: searchV2()'s hard-coded key rules
 *
 *   stopAtMatch {boolean}         When true, matched nodes are not recursed
 *                                 into — only the shallowest matches are
 *                                 returned. replaces: searchOr()'s early-exit
 *
 *   outsideOf  {string|string[]}  Node type(s) to treat as opaque walls —
 *                                 neither matched nor descended into.
 *                                 e.g. outsideOf: "FunctionDeclaration"
 *
 * ─────────────────────────────────────────────────────────────────────────────
 * MIGRATION GUIDE
 * ─────────────────────────────────────────────────────────────────────────────
 *
 *   search(root, "Foo")
 *     → query(root, "Foo")
 *
 *   searchV2(root, "Foo", dontTouchSet)
 *     → query(root, "Foo", {
 *         dontTouch: dontTouchSet,
 *         skipKey: (node, key) =>
 *           ((node.type === "AssignmentStatement" || node.type === "LocalStatement") && key === "variables") ||
 *           (node.type === "FunctionDeclaration" && (key === "identifier" || key === "parameters")) ||
 *           (node.type === "ForNumericStatement" && key === "variable") ||
 *           (node.type === "ForGenericStatement" && key === "variables")
 *       })
 *
 *   searchIs(root, pattern)
 *     → query(root, pattern)
 *
 *   searchOr(root, "A", "B", "C")
 *     → query(root, ["A", "B", "C"], { stopAtMatch: true })
 *
 *   deepSearch(root, pattern)
 *     → query(root, pattern)
 *
 *   searchPattern(root, "A", "B", "C")
 *     → query(root, { sequence: ["A", "B", "C"] })
 *
 * @param {object} root
 * @param {string | string[] | object | { sequence: string[] }} matcher
 * @param {{ dontTouch?: Set, skipKey?: Function, outsideOf?: string|string[], stopAtMatch?: boolean }} [opts]
 * @returns {Array}
 */
const query = (root, matcher, opts = {}) => {
	if (opts.dontTouch && !opts.skipKey)
		opts.skipKey = (node, key) =>
           ((node.type === "AssignmentStatement" || node.type === "LocalStatement") && key === "variables") ||
           (node.type === "FunctionDeclaration" && (key === "identifier" || key === "parameters")) ||
           (node.type === "ForNumericStatement" && key === "variable") ||
           (node.type === "ForGenericStatement" && key === "variables")
	const {
		dontTouch = new Set(),
		skipKey = () => false,
		outsideOf,
		stopAtMatch = false,
	} = opts;

	const walls = outsideOf
		? new Set(Array.isArray(outsideOf) ? outsideOf : [outsideOf])
		: null;

	const results = [];

	if (!root || typeof root !== "object") return results;

	if (
		matcher !== null &&
		typeof matcher === "object" &&
		!Array.isArray(matcher) &&
		Array.isArray(matcher.sequence)
	) {
		const seq = matcher.sequence;
		if (seq.length === 0) return results;

		const walk = (node) => {
			if (!node || typeof node !== "object") return;
			if (dontTouch.has(node)) return;
			if (!Array.isArray(node) && walls?.has(node.type)) return;

			if (Array.isArray(node)) {
				// Scan for matching runs
				for (let i = 0; i <= node.length - seq.length; i++) {
					if (seq.every((t, j) => node[i + j]?.type === t))
						results.push(node.slice(i, i + seq.length));
				}
				for (const item of node) walk(item);
			} else {
				for (const key in node) {
					if (skipKey(node, key)) continue;
					walk(node[key]);
				}
			}
		};

		walk(root);
		return results;
	}

	let matchFn;

	if (typeof matcher === "string") {
		// Single type
		matchFn = (node) => node.type === matcher;
	} else if (Array.isArray(matcher)) {
		// OR across multiple types — fast Set lookup
		const typeSet = new Set(matcher);
		matchFn = (node) => typeSet.has(node.type);
	} else {
		// Plain object → structural pattern match
		matchFn = (node) => is(node, matcher);
	}

	// Iterative DFS (stack keeps ordering stable, WeakSet guards against cycles)
	const stack = [root];
	const seen = new WeakSet();

	while (stack.length) {
		const node = stack.pop();

		if (!node || typeof node !== "object") continue;
		if (dontTouch.has(node)) continue;
		if (walls?.has(node.type)) continue;
		if (seen.has(node)) continue;
		seen.add(node);

		const matched = matchFn(node);
		if (matched) results.push(node);

		// stopAtMatch: don't recurse into a matched node — only surface matches
		if (matched && stopAtMatch) continue;

		for (const key in node) {
			if (skipKey(node, key)) continue;
			const value = node[key];
			if (Array.isArray(value)) {
				// Push in reverse so the stack processes children left-to-right
				for (let i = value.length - 1; i >= 0; i--) stack.push(value[i]);
			} else if (value && typeof value === "object") {
				stack.push(value);
			}
		}
	}

	return results;
};

module.exports = query