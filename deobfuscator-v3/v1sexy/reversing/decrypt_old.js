const beautify = require("../mods/beautifier")
const {
    search,
    searchOr,
    searchIs,
    is,
    print,
    Clear
} = require("../mods/helper")
const {
    spawn
} = require("child_process")
const simpleAst = require("../mods/simple-ast")
const fs = require("fs").promises
//const beautify = require("../mods/beautifier")
//const inline = require("./inline")

module.exports = async (output, extraDos, funcIdentifiers, state) => {
    // GENIUS IDEA:
    // All strings in the script are already encrypted,
    // so if we find ANY call like:
    // a("string", number)
    // that's a decryption!
    // as there cant be normal strings, they're all encrypted :)

    const encryptionKeys = {
        param_mul_45: null,
        param_mul_8: null,
        param_add_45: null,

        secret_key_8: null
    }

    let step = 0,
        stopE = false,
        decryptor,
        stringsTable;

    const firstFunc = (body) => {
        let step = 0;
        for (let stat of body) {
            const isWhile = stat.type == "WhileStatement"
            if (isWhile)
                stat = stat.body.find((a) => a.type)

            if (step == 0 && stat.type == "AssignmentStatement" && is(stat.init, [{
                    type: "BinaryExpression",
                    /*right: {
                        type: "NumericLiteral",
                        value: 35184372088832
                    },*/
                    left: {
                        type: "BinaryExpression"
                    },
                    operator: "%"
                }])) {
                // we can get param_mul_45 & param_add_45 here
                // (regtable[upvalues[2]] * param_mul_45 + param_add_45) % 35184372088832.0;

                const expr = stat.init[0].left
                if (expr.operator == "+") {
                    encryptionKeys.param_add_45 = expr.right.raw
                    encryptionKeys.param_mul_45 = expr.left.right.raw
                    step++
                }
            } else if (step == 1 && stat.type == "AssignmentStatement" && is(stat.init, [{
                    type: "BinaryExpression",
                    operator: "%",
                    right: {
                        type: "NumericLiteral",
                        value: 257
                    }
                }])) {
                const expr = stat.init[0].left

                if (expr.operator == "*") {
                    encryptionKeys.param_mul_8 = expr.right.raw
                    step++
                }
            } else if (step == 1 && stat.type == "RepeatStatement") {
                encryptionKeys.param_mul_8 = stat.body[0].init[0].left.right.raw
            }
        }
        return step
    }

    if (extraDos.length) {
        const encryption = extraDos[extraDos.length - 2].body
        for (let stat of encryption) {
            if (stat.type == "FunctionDeclaration") {
                if (is(stat, {
                        isLocal: true,
                        body: [{
                            type: "IfStatement",
                            clauses: [{
                                type: "IfClause",
                                condition: {
                                    type: "BinaryExpression"
                                }
                            }]
                        }]
                    })) { // params 8 .. 45 here
                    const body = stat.body[0].clauses[0].body
                    firstFunc(body)
                } else if (is(stat, {
                        isLocal: false,
                        body: [{
                                type: "LocalStatement"
                            },
                            {
                                type: "IfStatement"
                            }
                        ]
                    })) {
                    Clear(stat.body[stat.body.length - 1]) // remove the ReturnStatement
                    stat.body = stat.body.filter((a) => a.type)
                    if (isDecryptor(stat))
                        decryptor = stat.identifier
                }
            }
        }
    }

    function isDecryptor(func) {
        if (encryptionKeys.secret_key_8) return;

        let IfStat = func.body[func.body.length - 1]
        if (IfStat.type == "ReturnStatement")
            IfStat = func.body[func.body.length - 2]

        const elsebody = is(IfStat, {
                type: "IfStatement",
                clauses: [{},
                    {
                        type: "ElseClause"
                    }
                ]
            }) ? IfStat.clauses[1].body : func.body
        
        let last = [];

        for (let stat of elsebody) {
            /*
                on wrd:
                i[nil] = {};
i[q] = H % 35184372088832;
i[nil] = H % 255 + 2;
l[H] = "";
for undefined = 1, J["string"]["len"](K) do
    R = J["string"]["byte"](K, nil) + i[R]() + 172;
    k = nil;
    R = l[H] .. i[nil][R % 256 + 1];
    l[H] = R;
end;
                on the new thing:
d = h[2];
K, L = O[nil], h[1];
if K[d] then
    return d;
end;
O[1] = {};
k = O[j];
O[C] = d % 35184372088832;
O[F] = d % 255 + 2;
w = "";
K[d] = "";
D = #L;
j = 225;
for undefined = 1, 225 do
    C = nil;
    j = (W["string"]["byte"](L, nil) + O[nil]() + j) % 256;
    w = w .. k[j + 1];
end;
j, C, F = nil, w, nil;
w, k = nil, nil;
K[d] = C;
return;
            */
            if (stat.type == "ForNumericStatement" || stat.type == "WhileStatement") {
                print("ofc")

                // A = string.byte(E, b) + p[A]() + a;
                // a = A % 256;
                // G[m] = G[m] .. L[111];

                let ident;
                for (let i = 0; i < stat.body.length; i++) {
                    if (
                        is(
                            stat.body[i], {
                                type: "AssignmentStatement",
                                init: [{
                                    type: "BinaryExpression",
                                    //operator: "+"
                                }]
                            }
                        )
                    ) {
                        const init = stat.body[i].init[0]
                        const secretKey = init.operator == "%" ? init.left.right.name : init.right //.name // identifier
                        
                        if (secretKey.type == "NumericLiteral") {
                            encryptionKeys.secret_key_8 = secretKey.value
                            stopE = true
                            break
                        }
                        for (let i = last.length - 1; i > 0; i--) {
                            //print(i, last[i])
                            if (last[i].variables[0].name == secretKey) {
                                encryptionKeys.secret_key_8 = last[i].init[0].raw
                                stopE = true
                                break
                            }
                        }
                        //ident = stat.body[i].variables[0].name
                        break
                    }
                }
            }
            if (stat.type == "AssignmentStatement" || stat.type == "LocalStatement") last.push(stat)
        }
        return true
    }

    for (let stat of searchOr(output, "AssignmentStatement", "LocalStatement")) {
        if (stopE) break

        for (let func of stat.init) { //const func = stat.init[0
            if (func?.type != "FunctionDeclaration") continue

            const ImportantFunc = func.body.find((a) => is(a, {
                type: "IfStatement",
                clauses: [{
                    type: "IfClause",
                    condition: {
                        type: "BinaryExpression"
                    }
                }]
            }))

            if (ImportantFunc && step != 2) { // we can find all param_... from here
                const body = ImportantFunc.clauses[0].body
                //print(beautify(body))
                step = firstFunc(body)
                //step = firstFunc(body) || step
            } else {
                const isDecrypt = isDecryptor(func)

                if (!isDecrypt) continue

                decryptor = stat.variables[0]
                //Clear(stat) // u can do ts to remove junk
            }
        }
    }

    let code = [],
        encrypted = []

    if (encryptionKeys.param_add_45 && !encryptionKeys.secret_key_8) {
        // it's most likely inlined, look for it!
        for (let func of searchIs(output, {
                type: "CallExpression",
                base: {
                    type: "FunctionDeclaration"
                }
            })) {
            if (isDecryptor(func.base)) {
                print("decryptor is inlined")
                encrypted.push(func)
                decryptor = func.base
                break
            }
        }
    }

    print("Encryption Keys:", encryptionKeys)

    if (!encryptionKeys.param_mul_45) throw new Error("Encrypt strings is off")

    //print("Encryption Keys:", encryptionKeys)

    for (let key in encryptionKeys) {
        if (!encryptionKeys[key]) throw new Error(`UNABLE TO FIND DECRYPTION KEY ${key}`)
        print("FOUND DECRYPTION KEY", key, encryptionKeys[key])
        code.push(`${key} = ${encryptionKeys[key]};`)
    }

    if (!decryptor) return console.error("UNABLE TO FIND DECRYPTOR!!")

    const decryptors = [decryptor]
    const isDecryptor2 = (x) => decryptors.find((a) => is(a, x))

    if (decryptor.type == "Identifier")
        for (let ass of searchIs(output, {
                type: "AssignmentStatement",
                variables: [{
                    type: "Identifier"
                }],
                init: [
                    decryptor
                ]
            })) {
            //decryptor = ass.variables[0]
            //break
            decryptors.push(ass.variables[0])
        }

    for (let idx of search(output, "IndexExpression")) {
        const call = idx.index
        if (is(call, {
                type: "CallExpression",
                //base: decryptor,
                arguments: [{
                        type: "StringLiteral"
                    },
                    {
                        type: "NumericLiteral"
                    }
                ]
            })) {
            if (isDecryptor2(call.base)) {
                stringsTable = idx.base
                break
            }
        }
    }

    for (let call of searchIs(output, {
            type: "CallExpression",
            arguments: [{
                    type: "StringLiteral"
                },
                {
                    type: "NumericLiteral"
                }
            ]
        }))
        encrypted.push(call)

    // (C[Z[1]][C[Z[2]])("a", 123)
    for (let idx of searchIs(output, {
            type: "IndexExpression",
            base: {},
            index: {
                type: "CallExpression",
                base: {
                    type: "IndexExpression",
                    base: funcIdentifiers.regtable
                },
                arguments: [{
                        type: "StringLiteral"
                    },
                    {
                        type: "NumericLiteral"
                    }
                ]
            }
        })) {
        //print("yap",call)
        const call = idx.index
        const base = call.base

        if (
            (base.index.type == "IndexExpression" && base.index.base.name == funcIdentifiers.upvalues && base.index.index.type == "NumericLiteral") || base.index.type == "Identifier"
        ) {
            idx.base = stringsTable
            encrypted.push(call)
        }
    }

    if (!encrypted.length) return console.error("ENCRYPTED STRINGS LIST IS EMPTY")

    /*let stringDef = "strings={"

    for (let x of encrypted) {
        const [enc, seed] = x.arguments //x.index.arguments
        stringDef += `{${enc.raw},${seed.raw}};`
    }

    code.push(stringDef + "}")*/

    const Table = simpleAst.emptyTable()

    for (let x of encrypted) {
        const [enc, seed] = x.arguments //x.index.arguments
        //Table.fields.push({
            //type: "TableValue",
            //type: simpleAst.fieldsTable()
        //})//`{${enc.raw},${seed.raw}};`
        Table.fields.push(
            {
                type: "TableValue",
                value: simpleAst.fieldsTable([enc, seed])
            }
        )
    }

    const StringsDef = {
        type: "AssignmentStatement",
        variables: [ { type: "Identifier", name: "strings" } ],
        init: [ Table ]
    }

    code.push(beautify([StringsDef]))

    let codeStr = code.join("\n") + `\ndo
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

    local data = {}
    for _, v in next, strings do
        data[#data + 1] = STRINGS[DECRYPT(v[1], v[2])]:gsub("\\n", '\\\\n')
    end
    print(table.concat(data, "\\n"))
end`

    const File = "decrypt.lua"
    await fs.writeFile(File, codeStr)

    await new Promise((res) => {
        const proc = spawn("luau", [File])

        proc.stdout.on("data", (a) => {
            const data = a.toString().split("\n")
            const len = data.length

            for (let i = 0; i < len - 1; i++) {
                const encoded = encrypted[i]
                const val = data[i].substring(0, data[i].length - 1) // remove the trailing \r

                Clear(encoded)

                encoded.type = "StringLiteral"
                encoded.raw = `"${val}"`
            }

            res()
        })

        proc.stderr.on("data", (a) => {
            print(`ERROR ${a.toString()}`)
            res()
        })

        proc.on("error", (a) => console.error(`[ERRORED] ${a.toString()}`))
    })

    print("done ya bro")

    for (let i of searchIs(output, {
            type: "IndexExpression",
            base: stringsTable
        })) {
        const idx = i.index
        Clear(i)
        for (let j in idx) i[j] = idx[j]
    }

    return output
}