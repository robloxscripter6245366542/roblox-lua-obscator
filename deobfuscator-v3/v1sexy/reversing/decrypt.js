const beautify = require("../mods/beautifier");
const { is, print, Clear, fixString } = require("../mods/helper");

const simpleAst = require("../mods/simple-ast");
const query = require("../mods/query");

const simple = new Set(["NumericLiteral", "NilLiteral", "StringLiteral", "CallExpression", "IndexExpression"])
const isSimple = (type) => simple.has(type);

module.exports = async (output, extraDos, funcIdentifiers, state) => {
	// GENIUS IDEA:
	// All strings in the script are already encrypted,
	// so if we find ANY call like:
	// a("string", number)
	// that's a decryption!
	// as there cant be normal strings, they're all encrypted :)

	// fix table indexes here aswell

	const encrypted = []

	const encryptionKeys = {
		param_mul_45: null,
		param_mul_8: null,
		param_add_45: null,

		secret_key_8: null,
	};

	let step = 0,
		stopE = false,
		stopC = false,
		decryptor

	const firstFunc = (body) => {
		let step = 0;
		for (let stat of body) {
			if (stat.type == "WhileStatement") stat = stat.body.find((a) => a.type);
			else if (stat.type == "IfStatement") stat = stat.clauses[0].body.find((a) => a.type)

			if (
				step == 0 &&
				stat.type == "AssignmentStatement" &&
				is(stat.init, [
					{
						type: "BinaryExpression",
						/*right: {
                        type: "NumericLiteral",
                        value: 35184372088832
                    },*/
						left: {
							type: "BinaryExpression",
						},
						operator: "%",
					},
				])
			) {
				// we can get param_mul_45 & param_add_45 here
				// (regtable[upvalues[2]] * param_mul_45 + param_add_45) % 35184372088832.0;

				const expr = stat.init[0].left;
				if (expr.operator == "+") {
					encryptionKeys.param_add_45 = expr.right.raw;
					encryptionKeys.param_mul_45 = expr.left.right.raw;
					step++;
				}
			} else if (
				step == 1 &&
				stat.type == "AssignmentStatement" &&
				is(stat.init, [
					{
						type: "BinaryExpression",
						operator: "%",
						right: {
							type: "NumericLiteral",
							value: 257,
						},
					},
				])
			) {
				const expr = stat.init[0].left;

				if (expr.operator == "*") {
					encryptionKeys.param_mul_8 = expr.right.raw;
					step++;
				}
			} else if (step == 1 && stat.type == "RepeatStatement") {
				encryptionKeys.param_mul_8 = stat.body.find(
					(a) => a.type,
				).init[0].left.right.raw;
				stopC = true
			}
		}
		return step;
	};

	if (extraDos.length) {
		const encryption = extraDos[extraDos.length - 2].body;
		for (let stat of encryption) {
			if (stat.type == "FunctionDeclaration") {
				if (
					is(stat, {
						isLocal: true,
						body: [
							{
								type: "IfStatement",
								clauses: [
									{
										type: "IfClause",
										condition: {
											type: "BinaryExpression",
										},
									},
								],
							},
						],
					})
				) {
					// params 8 .. 45 here
					const body = stat.body[0].clauses[0].body;
					firstFunc(body);
				} else if (
					is(stat, {
						isLocal: false,
						body: [
							{
								type: "LocalStatement",
							},
							{
								type: "IfStatement",
							},
						],
					})
				) {
					Clear(stat.body[stat.body.length - 1]); // remove the ReturnStatement
					stat.body = stat.body.filter((a) => a.type);
					if (isDecryptor(stat)) decryptor = stat.identifier;
				}
			}
		}
	}

	function isDecryptor(func) {
		if (encryptionKeys.secret_key_8) return;
		if (func.parameters.length < 2) return;

		let IfStat = func.body[func.body.length - 1];
		if (IfStat.type == "ReturnStatement")
			IfStat = func.body[func.body.length - 2];

		let last = [];

		const isWeird = is(IfStat, {
			type: "IfStatement",
			clauses: [
				{},
				{
					type: "ElseClause",
				},
			],
		}); // this isnt src code

		const elsebody = isWeird ? IfStat.clauses[1].body : func.body;

		for (let stat of elsebody) {
			if (!stat?.type) continue;

			if (stat.type == "ForNumericStatement" || stat.type == "WhileStatement") {
				// A = string.byte(E, b) + p[A]() + a;
				// a = A % 256;
				// G[m] = G[m] .. L[111];

				for (let i = 0; i < stat.body.length; i++) {
					if (
						is(stat.body[i], {
							type: "AssignmentStatement",
							init: [
								{
									type: "BinaryExpression",
									//operator: "+"
								},
							],
						})
					) {
						const init = stat.body[i].init[0];
						//const secretKey = init.operator == "%" ? init.left.right.name : init.right //.name // identifier
						//print(init, isWeird)
						//const secretKey = isWeird
						//	? init.left.right.name
						//	: init.right.index.left.left.right;

						let secretKey;

						try {
							secretKey = init.left.right.name
						} catch {
							secretKey = init.right.index.left.left.right;
						}

						if (secretKey.type == "NumericLiteral") {
							encryptionKeys.secret_key_8 = secretKey.raw;
							stopE = true;
							break;
						}
						for (let i = last.length - 1; i > 0; i--) {
							//print(i, last[i])
							if (last[i].variables[0].name == secretKey) {
								encryptionKeys.secret_key_8 = last[i].init[0].raw;
								stopE = true;
								break;
							}
						}
						//ident = stat.body[i].variables[0].name
						break;
					}
				}
			}
			if (stat.type == "AssignmentStatement" || stat.type == "LocalStatement")
				last.push(stat);
		}
		return true;
	}

	for (let func of query(output, "FunctionDeclaration")) {
		if (stopE && stopC) break;
		if (!func.isLocal) continue;

		const ImportantFunc = func.body.find((a) =>
			is(a, {
				type: "IfStatement",
				clauses: [
					{
						type: "IfClause",
						condition: {
							type: "BinaryExpression",
						},
					},
				],
			}),
		);

		if (ImportantFunc && step != 2) {
			// we can find all param_... from here
			const body = ImportantFunc.clauses[0].body;
			//print(beautify(body))
			step = firstFunc(body);
			if (step == 2)
				Clear(func)
			//step = firstFunc(body) || step
		} else {
			const isDecrypt = isDecryptor(func);

			if (!isDecrypt) continue;

			decryptor = func.identifier;
			Clear(func)
			//Clear(stat) // u can do ts to remove junk
		}
	}

	let code = []

	if (encryptionKeys.param_add_45 && !encryptionKeys.secret_key_8) {
		// it's most likely inlined, look for it!
		for (let func of query(output, {
			type: "CallExpression",
			base: {
				type: "FunctionDeclaration",
			},
		})) {
			if (isDecryptor(func.base)) {
				print("decryptor is inlined");
				encrypted.push(func);
				decryptor = func.base;
				break;
			}
		}
	}

	print("Encryption Keys:", encryptionKeys);

	if (!encryptionKeys.param_mul_45) throw new Error("Encrypt strings is off");

	//print("Encryption Keys:", encryptionKeys)

	for (let key in encryptionKeys) {
		if (!encryptionKeys[key])
			throw new Error(`UNABLE TO FIND DECRYPTION KEY ${key}`);
		print("FOUND DECRYPTION KEY", key, encryptionKeys[key]);
		code.push(`${key} = ${encryptionKeys[key]};`);
	}

	if (!decryptor) return console.error("UNABLE TO FIND DECRYPTOR!!");

	/*for (let call of query(output, {
		type: "CallExpression",
		arguments: [
			{
				type: "StringLiteral",
			},
			{
				type: "NumericLiteral",
			},
		],
	}))
		encrypted.push(call);

	print("Strings table:",stringsTable)*/

	// (C[Z[1]][C[Z[2]])("a", 123)
	for (let idx of query(output, {
		type: "IndexExpression",
		index: {
			type: "CallExpression",
			arguments: [
				{
					type: "StringLiteral",
				},
				{
					type: "NumericLiteral",
				},
			],
		},
	})) {
		//print("yap",call)
		//const call = idx.index;
		//const base = call.base;

		/*if (
			(base.index.type == "IndexExpression" &&
				base.index.base.name == funcIdentifiers.upvalues &&
				base.index.index.type == "NumericLiteral") ||
			base.index.type == "Identifier"
		) {
			//idx.base = stringsTable;
			//encrypted.push(call);
			encrypted.push(idx)
		}*/

		encrypted.push(idx);
	}

	if (!encrypted.length) {
		console.error("ENCRYPTED STRINGS LIST IS EMPTY");
		return output;
	}

	/*let stringDef = "strings={"

    for (let x of encrypted) {
        const [enc, seed] = x.arguments //x.index.arguments
        stringDef += `{${enc.raw},${seed.raw}};`
    }

    code.push(stringDef + "}")*/

	const Table = simpleAst.emptyTable();

	for (let x of encrypted) {
		//const [enc, seed] = x.arguments; //x.index.arguments
		const [enc, seed] = x.index.arguments
		//Table.fields.push({
		//type: "TableValue",
		//type: simpleAst.fieldsTable()
		//})//`{${enc.raw},${seed.raw}};`
		Table.fields.push({
			type: "TableValue",
			value: simpleAst.fieldsTable([enc, seed]),
		});
	}

	const StringsDef = {
		type: "AssignmentStatement",
		variables: [{ type: "Identifier", name: "strings" }],
		init: [Table],
	};

	code.push(beautify([StringsDef]));

	let codeStr =
		code.join("\n") +
		`\ndo
	local floor = math.floor
	local random = math.random;
	local remove = table.remove;
	local char = string.char;
	local state_45 = 0
	local state_8 = 2
	local digits = {}
	local charmap = {};
	local i = 0;

	local nums = {};
	for i = 1, 256 do
		nums[i] = i;
	end

	repeat
		local idx = random(1, #nums);
		local n = remove(nums, idx);
		charmap[n] = char(n - 1);
	until #nums == 0;

	local prev_values = {}
	local function get_next_pseudo_random_byte()
		if #prev_values == 0 then
			state_45 = (state_45 * param_mul_45 + param_add_45) % 35184372088832
			repeat
				state_8 = state_8 * param_mul_8 % 257
			until state_8 ~= 1
			local r = state_8 % 32
			local n = floor(state_45 / 2 ^ (13 - (state_8 - r) / 32)) % 2 ^ 32 / 2 ^ r
			local rnd = floor(n % 1 * 2 ^ 32) + floor(n)
			local low_16 = rnd % 65536
			local high_16 = (rnd - low_16) / 65536
			local b1 = low_16 % 256
			local b2 = (low_16 - b1) / 256
			local b3 = high_16 % 256
			local b4 = (high_16 - b3) / 256
			prev_values = { b1, b2, b3, b4 }
		end
		return table.remove(prev_values)
	end

	local realStrings = {};
	local STRINGS = setmetatable({}, {
		__index = realStrings;
		__metatable = nil;
	});
  	local function DECRYPT(str, seed)
		local realStringsLocal = realStrings;
		if(realStringsLocal[seed]) then else
			prev_values = {};
			local chars = charmap;
			state_45 = seed % 35184372088832
			state_8 = seed % 255 + 2
			local len = string.len(str);
			realStringsLocal[seed] = "";
			local prevVal = secret_key_8;
			for i=1, len do
				prevVal = (string.byte(str, i) + get_next_pseudo_random_byte() + prevVal) % 256
				realStringsLocal[seed] = realStringsLocal[seed] .. chars[prevVal + 1];
			end
		end
		return seed;
	end
    local function DECRYPT_PACKED(idx)
        local v = strings[idx]
        if not v then
            return 0
        end

        local value = STRINGS[DECRYPT(v[1], v[2])]
        return #value, string.byte(value, 1, #value)
    end

    return DECRYPT_PACKED
end`;

	const Loader = state.loadstring(codeStr);
	if (typeof Loader == "string") throw new Error(Loader);
	const fromBytes = (bytes) => {
		let out = "";
		for (const byte of bytes)
			out += String.fromCharCode((Number(byte) || 0) & 0xff);
		return out;
	};

	const DecryptPacked = (await Loader())[0];
	if (typeof DecryptPacked != "function")
		throw new Error("UNABLE TO LOAD DECRYPTOR FUNCTION");

	for (let i = 0; i < encrypted.length; i++) {
		const encoded = encrypted[i];
		const packed = await DecryptPacked(i + 1);

		if (!Array.isArray(packed)) continue;

		const length = Number(packed[0]) || 0;
		const val = fromBytes(packed.slice(1, 1 + length));

		Clear(encoded);

		encoded.type = "StringLiteral";
		encoded.value = val;
		encoded.raw = `"${fixString(val, '"', false)}"`;
	}

	/*for (let i of query(output, {
		type: "IndexExpression",
		base: stringsTable,
	})) {
		const idx = i.index;
		Clear(i);
		for (let j in idx) i[j] = idx[j];
	}*/


	return output;
};
