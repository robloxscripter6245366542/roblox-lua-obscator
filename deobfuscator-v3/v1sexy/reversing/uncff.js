const {
	is,
	print,
	search,
	searchIs,
	Clear,
	isBetween,
	clone,
	removeValue
} = require("../mods/helper.js");

const { inline, setInlineOptions } = require("../mods/inlinev4.js");

const beautify = require("../mods/beautifier.js");
const simpleAst = require("../mods/simple-ast.js");

setInlineOptions({
	simpleInlining: true, // so we don't lose data in stats
});

const Identifier = {
		type: "Identifier",
	},
	AssignmentStatement = {
		type: "AssignmentStatement",
	};

const data = {
	findBlock: null,
	pc: null,
	env: null,
};

const getLast = (a, b, c) => {
	let l = a[a.length - (1 + (b ?? 0))];
	let n = 1;

	if (!l || c) return l;

	while (l && l.variables && is(l.variables[0], data.pc)) {
		l = a[a.length - (1 + (b ?? 0 + n))];
		n++;
	}
	return l;
};

const getVar = (...a) => getLast(...a)?.variables?.[0];
const getInit = (...a) => getLast(...a)?.init?.[0];

function unflatten(ifNode, start, identifiers) {
	const { upv, env, dispatchers, returnVar, pc, params, reg } = identifiers;

	if (!pc) throw new Error("cannot detect state variable - cff");
	if (!upv) throw new Error("missing upvalues table - cff");
	if (!env) throw new Error("missing env variable - cff");
	if (!returnVar) throw new Error("missing return variable - cff");

	((data.params = params),
		(data.pc = pc),
		(data.reg = reg),
		(data.env = env),
		(data.returnVar = returnVar),
		(data.dispatchers = dispatchers),
		(data.findBlock = (n) =>
			rawBlocks.find((a) => isBetween(n, a.range.min, a.range.max))));

	const rawBlocks = [];

	print("starting from", start);

	searchIf(ifNode, -Infinity, Infinity, rawBlocks, []);

	const Blocks = rawBlocks.map((a) => analyzeBlock(a));
	const findBlock = (n) =>
		Blocks.find((a) => isBetween(n, a.range.min, a.range.max));

	data.findBlock = findBlock;

	const entry = findBlock(start) || Blocks[0];

	const reconstructed = new Set();
	const constructed = reconstruct(entry, reconstructed);

	const Funcs = search(Blocks, "FunctionDeclaration");

	for (let Func of Funcs) {
		const Start = Func.body;
		if (typeof Start == "number") {
			Func.body = [
				/*{
					type: "CommentStatement",
					text: Start
				},*/
				{
					type: "LocalStatement",
					init: [Func.args],
					variables: [upv],
				}
			].concat(reconstruct(findBlock(Start), reconstructed));
			delete Func.args;
		}
	}

	return constructed;
}

function searchIf(node, min, max, out, prefix) {
	if (node.type !== "IfStatement") {
		if (node.type == "WhileStatement" && is(node.condition, data.pc)) {
			// while $PC do
			pushLeaf(
				node.body,
				{
					min,
					max,
				},
				out,
				prefix,
			);
			return;
		}

		out.push({
			range: {
				min,
				max,
			},
			stats: prefix.concat(node),
		});
		return;
	}

	let curMin = min,
		curMax = max;

	for (const clause of node.clauses) {
		if (clause.type === "IfClause" || clause.type === "ElseifClause") {
			const cond = clause.condition;

			if (cond.type != "BinaryExpression") continue;

			const numericOnLeft = cond.left.type === "NumericLiteral";
			const limit =
				(numericOnLeft ? cond.left.value : cond.right.value) ?? Infinity;

			const isLessThan =
				(cond.operator === "<" && !numericOnLeft) ||
				(cond.operator === ">" && numericOnLeft);

			if (isLessThan) // x < limit (or limit > x)
			{
				pushLeaf(
					clause.body,
					{
						min: curMin,
						max: limit,
					},
					out,
					prefix,
				);
				curMin = limit;
			} else {
				pushLeaf(
					clause.body,
					{
						min: limit,
						max: curMax,
					},
					out,
					prefix,
				);
				curMax = limit;
			}
		} else if (clause.type === "ElseClause") {
			pushLeaf(
				clause.body,
				{
					min: curMin,
					max,
				},
				out,
				prefix,
			);
		}
	}
}

function pushLeaf(body, range, out, prefix) {
	const last = body[body.length - 1];

	if (last?.type === "IfStatement")
		searchIf(last, range.min, range.max, out, prefix.concat(body.slice(0, -1)));
	else {
		out.push({
			range,
			stats: prefix.concat(body),
		});
	}
}

function analyzeBlock(block) {
	const pc = data.pc,
		returnVar = data.returnVar,
		dispatchers = data.dispatchers,
		stats = block.stats;

	for (let i = 0; i < stats.length; i++) {
		const stat = stats[i];
		if (
			stat.type != "AssignmentStatement" ||
			stat.init[0].type != "CallExpression"
		)
			continue;

		const init = stat.init[0];

		const value = init.base;
		if (
			dispatchers[value.name] &&
			is(init.arguments, [
				{
					type: "NumericLiteral",
				},
				{
					type: "TableConstructorExpression",
				},
			])
		) {
			const start = init.arguments[0];

			stat.init[0] = {
				type: "FunctionDeclaration",
				parameters: [{
					type: "VarargLiteral",
					raw: "...",
					value: "..."
				}],
				body: start.value,
				args: init.arguments[1]
			};
		}
	}

	const processValue = (value, i, ClearStat) => {
		if (value.type == "NumericLiteral") {
			// goto
			//delete stats[i]
			ClearStat();

			return {
				type: "goto",
				stats: stats.filter(Boolean),
				next: value.value,
				range: block.range,
			};
		} else if (
			is(value, {
				type: "LogicalExpression",
				operator: "or",
				left: {
					operator: "and",
					right: {
						type: "NumericLiteral",
					},
				},
				right: {
					type: "NumericLiteral",
				},
			})
		) {
			//delete stats[i]
			ClearStat();
			return {
				type: "conditional",
				stats: stats.filter(Boolean),
				condition: value.left.left,
				trueNext: value.left.right.value,
				falseNext: value.right.value,
				range: block.range,
			};
		} else if (
			is(value, {
				type: "IndexExpression",
				base: data.env,
			}) ||
			is(value, {
				type: "MemberExpression",
				base: data.env,
				indexer: ".",
			})
		) {
			// look for a stat with ${returnVar} =
			//delete stats[i]
			//for (let j = stats.length - 1; j > -1; j--)
			for (let j = stats.length; j > -1; j--) {
				// removed the -1 to support more forks and the prometheus update doing a, b = {}, w[".."]
				const stat = stats[j];
				if (!stat) continue;
				const match = stat.variables.find((a) => is(a, returnVar));
				if (match) {
					//delete stats[i]
					const val = stat.init[stat.variables.indexOf(match)];

					if (val?.type == "TableConstructorExpression") {
						if (stat.variables.length == 1) delete stats[j];
						else {
							stat.variables = stat.variables.filter(
								(a) => a.name != returnVar.name,
							);
							stat.init = stat.init.filter((a) => a != val);
						} // remove the return
						ClearStat(); // remove the pc

						return {
							type: "return",
							stats: stats.filter(Boolean),
							args: val.fields.map((a) => a.value),
							range: block.range,
						};
					}
				}
			}

			//print("Stats:",beautify(stats))

			ClearStat();
			return {
				type: "return",
				stats: stats.filter(Boolean),
				args: [],
				range: block.range,
			};
		} else if (
			is(value, {
				type: "LogicalExpression",
				operator: "or",
				left: pc,
				right: Identifier,
			})
		) {
			let n1,
				n2,
				last = stats[i];

			for (let j = stats.length - 1; j > 0; j--) {
				const stat = stats[j];
				if (
					is(stat, {
						type: "AssignmentStatement",
						init: [
							{
								type: "NumericLiteral",
							},
						],
					}) &&
					is(last, {
						type: "AssignmentStatement",
						variables: [pc],
					})
				) {
					delete stats[j];

					const init = stat.init[0];
					if (n1) {
						n2 = init.value;
						break;
					} else n1 = init.value;
				} else if (stat.type == "AssignmentStatement") last = stat;
			}

			//delete stats[i]
			ClearStat();
			return {
				type: "conditional",
				stats: stats.filter(Boolean),
				condition: pc,
				trueNext: n2,
				falseNext: n1,
				range: block.range,
			};
		}
	};

	for (let i = stats.length - 1; i > -1; i--) {
		const stat = stats[i];
		if (stat.type != "AssignmentStatement") continue;

		// does this have pc?

		let idx = undefined;

		for (let x = 0; x < stat.variables.length; x++) {
			if (is(stat.variables[x], pc)) {
				idx = x;
				break;
			}
		}

		if (typeof idx != "number") continue;

		const value = stat.init[idx];
		const variable = stat.variables[idx];

		const processed = processValue(value, i, () => {
			if (stat.variables.length == 1) delete stats[i];
			else {
				stat.variables = stat.variables.filter((a) => a != variable);
				stat.init = stat.init.filter((a) => a != value);
			}
		});

		if (processed) return processed;
	}

	return {
		type: "block",
		stats: stats,
		range: block.range,
	};
}

const findNext = (a) => data.findBlock(a.next ?? a.trueNext);

function getResolvedCondition(block) {
	if (!block?.condition) return null;

	const stats = clone(block.stats ?? []);
	/*stats.push({
		type: "AssignmentStatement",
		variables: [],
		init: [clone(block.condition)],
	});*/

	inline(stats);

	//print(beautify(stats), getInit(stats))

	return getInit(stats) ?? block.condition;
}

function reachesTargetViaGoto(start, target, seen = new Set()) {
	if (start === target) return true;
	if (seen.has(start)) return false;

	seen.add(start);

	const block = data.findBlock(start);
	if (!block || block.type !== "goto") return false;

	return reachesTargetViaGoto(block.next, target, seen);
}

function extractComparatorRhs(block, operator, previousExpr, shortCircuitTarget, seen = new Set(), nest=0) {
	if (!block || !previousExpr) return null;

	// Prevent going into stuff we already saw
	const blockId = block.range?.min;
	if (typeof blockId === "number") {
		if (seen.has(blockId)) return null;
		seen.add(blockId);
	}

	// Empty goto
	if (block.type === "goto" && !block.stats?.length) {
		return extractComparatorRhs(
			data.findBlock(block.next), operator, previousExpr, shortCircuitTarget, seen, nest+1
		);
	}

	const stats = block.stats ?? [];
	let init = getInit(stats); // last stat's init value

	if (!(init && is(init, previousExpr))) {
		const p = getVar(stats)
		if (p && is(p, previousExpr))
			init = p;
	}

	// Non-conditional: verify init matches previousExpr, then extract inlined RHS
	if (block.type !== "conditional") {
		if (!init || !is(init, previousExpr)) return null;
		const cloned = clone(stats);
		inline(cloned);
		const rhs = getInit(cloned);
		return rhs && !is(rhs, previousExpr) ? rhs : null;
	}

	// Conditional: check this block is seeded by previousExpr
	if (!(init && is(init, previousExpr)) && !is(block.condition, previousExpr)) return null;

	// Verify the short-circuit branch leads to the expected bailout
	const shortCircuitNext = operator === "and" ? block.falseNext : block.trueNext;
	if (!reachesTargetViaGoto(shortCircuitNext, shortCircuitTarget)) return null;

	const resolved = getResolvedCondition(block);
	if (!resolved) return null;

	// Recurse into the continue branch to find further chained conditions
	const continueNext = operator === "and" ? block.trueNext : block.falseNext;
	const nested = extractComparatorRhs(
		data.findBlock(continueNext), operator, block.condition, shortCircuitTarget, seen, nest+1
	);

	if (!nested || is(nested, resolved)) return resolved;

	return { type: "LogicalExpression", operator, left: resolved, right: nested };
}

function reconstruct(block, visited, stopVal, isInLoop, previous) {
	if (!block) return [];

	const findBlock = data.findBlock;

	const id = block.range.min;
	const currId = block; //id + 1 // so that isBetween() finds the correct block

	if (visited.has(id)) return [];

	if (
		stopVal !== null &&
		stopVal >= block.range.min &&
		stopVal < block.range.max
	)
		return [];

	const nextVisited = visited; //new Set(visited)
	nextVisited.add(id);

	const stats = block.stats;
	const last = stats[stats.length - 1];

	if (block.type === "return")
		return stats.concat({
			type: "ReturnStatement",
			arguments: block.args,
		});

	if (block.type === "goto") {
		const nextBlock = findBlock(block.next);
		if (isInLoop && nextBlock.type == "return")
			return stats.concat({
				type: "BreakStatement",
			});
		return stats.concat(
				reconstruct(nextBlock, nextVisited, stopVal, isInLoop, currId),
			)/*[ { type: "CommentStatement", text: `goto ${block.next}` } ].concat*/
	}

	if (block.type === "conditional") {
		const { trueNext, falseNext } = block;

		const trueBlock = findBlock(trueNext);
		const falseBlock = findBlock(falseNext);

		const testVisited = new Set(nextVisited);
		testVisited.delete(id);

		//const trueLoops = isReachable(trueNext, block.range, testVisited, new Set([falseNext]));
		//const falseLoops = isReachable(falseNext, block.range, testVisited, new Set([trueNext]));

		const trueLoops = isReachable(trueNext, block.range.min, testVisited, new Set([falseNext]));
		//print("trueLoops:",trueLoops,trueNext)
		const falseLoops = isReachable(falseNext, block.range.min, testVisited, new Set([trueNext]));
		//print("falseLoops:", falseLoops, falseNext)

		let condition = block.condition;

		const cloned = clone(stats);

		inline(cloned);

		if (
			trueLoops &&
			is(getInit(cloned, 0, true), {
				type: "LogicalExpression",
				operator: "and",
				right: {
					type: "Identifier",
				},
				left: {
					type: "LogicalExpression",
					operator: "or",
				},
			})
		) {
			const LastStats = previous?.stats;

			if (LastStats?.length) {
				//const LastStat = getLast(LastStats.filter(Boolean));

				let start, step, variable;

				/*for (let stat of LastStats)
					if (stat && is(stat, { init: [{ type: "BinaryExpression", operator: "-" }] })) {
						LastStat = stat
						break
					}*/
				for (let j = LastStats.length - 1; j > -1; j--) {
					const stat = LastStats[j];

					if (
						stat && stat.type == "AssignmentStatement"
					) {
						for (let i = 0; stat.init?.length && i < stat.init.length; i++) {
							const init = stat.init[i]
							if (init?.type == "BinaryExpression") {
								const op = init.operator
								if (op == "-") {
									variable = stat.variables[i]
									start = init.left;
									step = init.right;
									removeValue(stat, i);
								}
								else if (op == ">" || op == "<")
									removeValue(stat, i)
							}
						}
					}
				}
				// The last stat's variable is always the iterator and it's value is start - step

				const endSearch = searchIs(cloned, {
					type: "LogicalExpression",
					operator: "and",
					left: Identifier,
					right: {
						type: "BinaryExpression",
						//operator: ">=",
						left: Identifier,
						right: Identifier,
					},
				})[0];

				if (endSearch?.right && start && step) {
					const end =
						endSearch.right.operator == "<="
							? endSearch.right.left
							: endSearch.right.right;
					// no clue why but it works, sooo

					const Statement = {
						type: "ForNumericStatement",
						variable, //: LastStat.variables[0],
						start, //: LastStat.init[0].left,
						step, //: LastStat.init[0].right,
						end,
						body: reconstruct(
							findBlock(trueNext),
							new Set(nextVisited), // prevents stack overflow
							block.range.min, // since we're in the useless blocks thing, pass it's id so that if we go back to it that means that thing's body is looping over, meaning STOP.
							isInLoop,
						),
					};

					return [Statement].concat(
						reconstruct(findBlock(falseNext), nextVisited, stopVal, isInLoop),
					);
				}
			}
		}

		if (trueLoops || (falseLoops && !is(getVar(stats, 0, true), condition))) {
			const bodyIsTrue = trueLoops;

			const bodyNext = bodyIsTrue ? block.trueNext : block.falseNext;
			const exitNext = bodyIsTrue ? block.falseNext : block.trueNext;

			if (!bodyIsTrue) condition = negateCondition(condition);

			const bodyBlock = findBlock(bodyNext);
			const exitBlock = findBlock(exitNext);

			const selfLoop = !bodyBlock || bodyBlock.range.min === block.range.min;

			let body;

			if (selfLoop) body = stats;
			else body = reconstruct(bodyBlock, nextVisited, null, true, currId);

			if (stats.length == 1 && is(stats[0].variables[0], condition) && stats[0].variables.length == 2) {
				// ForGenericStatement
				const stat = stats[0];
				if (
					is(stat.init[0], {
						type: "CallExpression",
						arguments: [
							{
								type: "Identifier",
							},
							{
								type: "Identifier",
							},
						],
					})
				) {
					// Most likely ForGenericStatement.
					const forstat = {
						type: "ForGenericStatement",
						variables: stat.variables,
						iterators: [],
						body,
					};

					const prev = previous;

					if (prev?.type == "goto") {
						// search for:
						// any = VARIABLE[NUMBER]
						// where VARIABLE is a table
						// we can just look backwards for that, though it's not the most efficient approach.

						/*
						for i, v in next, yap, game:GetChildren() do
						no previous indexes
						U, r = D(y, U); -> next(yap, game:GetChildren())

						for i, v in next, game:GetChildren() do

						q, S = "next", "game";
                                        o = nil;
                                        A = nil;
                                        C = "GetChildren";
                                        U = N[q];
                                        X = f;
                                        q = N[S];
                                        C = q[C];
                                        G = nil;
                                        C = {
                                            C(q) --> game:GetChildren()
                                        };
                                        V, S = C[2], C[1];
						V, C = U(S, V); -> next(game:GetChildren())
						*/

						const prevStats = prev.stats;

						let dobreak;

						for (let i = prevStats.length - 1; i > -1; i--) {
							if (dobreak) break;
							const stat = prevStats[i];
							const idxFormat = {
								type: "IndexExpression",
								base: { type: "Identifier" },
								index: { type: "NumericLiteral" },
							};
							if (stat?.type == "AssignmentStatement") {
								for (let j = 0; j < stat.init.length; j++) {
									const val = stat.init[j];
									if (is(val, idxFormat)) {
										// search for the maximum
										let max = val.index.value;
										for (let x of stat.init)
											if (is(x, idxFormat)) max = Math.max(max, x.index.value);
										// if max == 2 then it's probably next, ...
										// if max == 3 then its something like for ... in ipairs(x) do

										// we're done, now look for VARIABLE and find it's value
										const VARIABLE = val.base;

										for (let k = i; k > -1; k--) {
											if (
												is(prevStats[k], {
													type: "AssignmentStatement",
													variables: [VARIABLE],
													init: [
														{
															type: "TableConstructorExpression",
														},
													],
												})
											) {
												if (max == 2)
													forstat.iterators.push(stats[0].init[0].base);

												forstat.iterators.push(
													prevStats[k].init[0].fields[0].value,
												);

												delete prevStats[k];
												delete prevStats[i];
											}
										}
										dobreak = true;
										break;
									}
								}
							}
						}

						if (forstat.iterators.length)
							return [forstat].concat(
								reconstruct(exitBlock, nextVisited, stopVal, isInLoop, currId),
							);
					}
				}
			}

			const whileStmt = {
				type: "WhileStatement",
				condition,
				body,
			};

			const after = reconstruct(
				exitBlock,
				nextVisited,
				stopVal,
				isInLoop,
				currId,
			);

			if (selfLoop) return [whileStmt].concat(after);

			return stats.concat([whileStmt], after);
		} else if (falseLoops) {
			// RepeatStatement
			inline(stats);
			const cond = getInit(stats, 0, true);

			delete stats[stats.length - 1];

			const Repeat = {
				type: "RepeatStatement",
				body: stats,
				condition: cond,
			};

			//const exitBlock = findBlock(block.falseNext)
			const exitBlock = findBlock(trueNext);

			//nextVisited.delete(exitBlock.range.min)

			const after = reconstruct(
				exitBlock,
				nextVisited,
				stopVal,
				isInLoop,
				currId,
			);

			return [Repeat].concat(after);
		}

		const join = findJoin(trueNext, falseNext);
		const stopAt = join ?? stopVal;

		const ifStmt = {
			type: "IfStatement",
			clauses: [],
		};

		const last = getInit(stats);
		const lastVar = getVar(stats);

		if (
			trueBlock &&
			falseBlock &&
			(trueBlock.type == "conditional" || trueBlock.stats.length) &&
			is(last, condition)
		) {
			const trueBody = trueBlock.stats;
			const falseBody = falseBlock.stats;

			const lastStat = getLast(stats);

			const andRhs = extractComparatorRhs(trueBlock, "and", last, falseNext);

			//print("andRhs:",andRhs,"last:",last)

			if (andRhs && !is(andRhs, last)) {
				// `and` v1 + nested support
				lastStat.init[0] = {
					type: "LogicalExpression",
					operator: "and",
					left: last,
					right: andRhs,
				};

				return stats.concat(
					reconstruct(falseBlock, nextVisited, stopVal, isInLoop, currId),
				);
			}

			const orRhs = extractComparatorRhs(falseBlock, "or", last, trueNext);

			if (orRhs && !is(orRhs, last)) {
				// works fine
				// or + nested support

				lastStat.init[0] = {
					type: "LogicalExpression",
					operator: "or",
					left: last,
					right: orRhs,
				};
				//return stats.concat(trueBody)
				return stats.concat(
					reconstruct(trueBlock, nextVisited, stopVal, isInLoop, currId),
				);
			} else if (join) {
				if (join != falseNext) {
					// elseClause, we're in an `or` probably?
					// trueBody is what comes AFTER this check
					// reconstruct(falseBlock) is what we need

					const fixedFalseBody = reconstruct(
						falseBlock,
						nextVisited,
						join,
						isInLoop,
						currId,
					);
					if (is(getInit(fixedFalseBody), last)) {
						// does NOT always work fine
						inline(fixedFalseBody);

						const rhs = getVar(fixedFalseBody);

						lastStat.init[0] = {
							type: "LogicalExpression",
							operator: "or",
							left: last,
							right: rhs,
						};

						return fixedFalseBody.concat(
							stats.concat(
								reconstruct(trueBlock, nextVisited, stopVal, isInLoop, currId),
							),
						);
					}
				} // it's prolly after this
				else if (falseBody.length) {
					//print("yea")
					const firstStatInJoin = falseBody.find((a) => a.type); //[0]

					if (is(firstStatInJoin.init[0], lastVar)) {
						//trueBody = reconstruct(trueBlock, nextVisited, stopVal, isInLoop)
						//print(beautify(trueBody))
						inline(trueBody);

						firstStatInJoin.init[0] = {
							type: "LogicalExpression",
							operator: "and",
							left: lastVar,
							right: getInit(trueBody),
						};
						return stats.concat(
							reconstruct(falseBlock, nextVisited, stopVal, isInLoop, currId),
						);
					}
				}
			}
		}

		ifStmt.clauses.push({
			type: "IfClause",
			condition,
			body: reconstruct(
				trueBlock,
				nextVisited,
				stopAt == trueNext ? null : stopAt,
				isInLoop,
				currId,
			)
		});

		if (join && join != falseNext) {
			const test = (falseBlock, a) => {
				const ig = findNext(falseBlock); // we want .trueNext so findNext gives just that (or just .next if it's a goto)

				if (ig && isBetween(join, ig.range.min, ig.range.max)) {
					// the next block after this is where they join
					if (nextVisited.has(join))
						// meow
						return stats.concat(ifStmt);

					/*if (falseBlock.type == "conditional") {
                        ifStmt.clauses.push({
                            type: "ElseClause",
                            body: falseBlock.stats.concat(reconstruct(ig, nextVisited, stopVal, isInLoop, currId))
                        })
                        return stats.concat([ifStmt])
                    }*/

					ifStmt.clauses.push({
						type: "ElseClause",
						body: falseBlock.stats,
					});

					return stats.concat(
						[ifStmt],
						reconstruct(ig, nextVisited, stopVal, isInLoop, currId),
					);
				} else {
					/*else if (falseBlock.type == "conditional") { // elseif maybe .. but it could also be `and` or `or`?
                    let currBlock = falseBlock
                    while (currBlock.type == "conditional") {
                        const newStats = [
                            ...currBlock.stats,
                            {
                                type: "AssignmentStatement",
                                variables: [{
                                    type: "Identifier",
                                    name: "_"
                                }],
                                init: [currBlock.condition]
                            }
                        ]
                        
                        inline(newStats)

                        const condition = getInit(newStats)

                        nextVisited.add(join)

                        ifStmt.clauses.push({
                            type: "IfClause",
                            condition: condition,
                            body: reconstruct(findBlock(currBlock.trueNext), nextVisited, stopAt, isInLoop, currBlock)
                        })
                        currBlock = findBlock(currBlock.falseNext)
                    }

                    print("curr block:",currBlock,join)

                    return test(currBlock, true)
                } */
					//if (nextVisited.has(falseBlock.range.min))
					//    nextVisited.delete(falseBlock.range.min)
					if (!nextVisited.has(falseBlock.range.min))
						ifStmt.clauses.push({
							type: "ElseClause",
							body: reconstruct(
								falseBlock,
								nextVisited,
								stopVal,
								isInLoop,
								currId,
							),
						});
				}
			};

			const tested = test(falseBlock);
			if (tested) return tested;
		}

		if(condition.name=="Z")print("sorry bud",stopAt,falseNext,trueNext)

		//return stats.concat([ifStmt], reconstruct(falseBlock, nextVisited, stopVal, isInLoop, currId))
		return stats.concat(
			[ifStmt],
			reconstruct(falseBlock, nextVisited, stopVal, isInLoop, currId),
		);
	}

	return stats;
}

function findJoin(trueNext, falseNext, ...extra) {
	// where trueNext and falseNext touch
	function GetSuccessors(id) {
		const b = data.findBlock(id);
		if (!b) return [];
		switch (b.type) {
			case "goto":
				return [b.next];
			case "conditional":
				return [b.trueNext, b.falseNext];
			default:
				return [];
		}
	}

	if (trueNext === falseNext) return trueNext;

	const seenTrue = new Set([trueNext, ...extra]);
	const seenFalse = new Set([falseNext]);
	const qTrue = [trueNext, ...extra];
	const qFalse = [falseNext];
	let iT = 0,
		iF = 0;

	while (iT < qTrue.length || iF < qFalse.length) {
		if (iT < qTrue.length) {
			for (const s of GetSuccessors(qTrue[iT++])) {
				if (seenFalse.has(s)) return s; // false frontier already saw this → join
				if (!seenTrue.has(s)) {
					seenTrue.add(s);
					qTrue.push(s);
				}
			}
		}
		if (iF < qFalse.length) {
			for (const s of GetSuccessors(qFalse[iF++])) {
				if (seenTrue.has(s)) return s; // true frontier already saw this → join
				if (!seenFalse.has(s)) {
					seenFalse.add(s);
					qFalse.push(s);
				}
			}
		}
	}
}

//function isReachable(start, targetRange, visited, blocked = new Set(), seen = new Set()) {
function isReachable(start, min, visited, blocked = new Set(), seen = new Set()) {
	const q = [start];

	//print("Started from",start,"minimum:",min)

	while (q.length) {
		const v = q.shift();
		//print("Current element:", v)
		if (seen.has(v) || blocked.has(v)) continue;

		seen.add(v);

		//if (isBetween(v, targetRange.min, targetRange.max)) return true;
		//if (v === targetRange.min) return true;
		if (v == min) return true;

		const b = data.findBlock(v);
		if (!b || visited.has(b.range.min)) continue;

		if (b.type === "goto") q.push(b.next);
		else if (b.type === "conditional") {
			if (b.trueNext == start || b.falseNext == start)
				return true;
			//print("Hit conditional, trueNext:", b.trueNext,"falseNext:",b.falseNext)
			q.push(b.trueNext);
			q.push(b.falseNext);
		}
	}

	return false;
}

function negateCondition(cond) {
	return {
		type: "UnaryExpression",
		operator: "not",
		argument: cond,
	};
}

module.exports = unflatten;
