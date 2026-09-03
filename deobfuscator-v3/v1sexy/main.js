// @ts-check

/* out/46.lua
The sanity check is
do local valid = 'wj';for i = 0, 4 do
        if i == 0 then
            if valid ~= 'wj' then
                while true do end
            end
            valid = true;
        elseif i == 1 then
            if valid == true then
            end
        elseif i == 2 then
            valid = false;
        elseif i == 3 then
            if valid == false then
            else
                while true do end
            end
        elseif i == 4 then
            valid = false;
        end
    end
do valid = true end
*/

/**
 * @typedef {Object<any,any>} AstObject
 * @property {string} type
*/

const fs = require("fs").promises

const beautify = require("./mods/beautifier"), { parse, defaultOptions } = require("./mods/luaparse"), simpleAst = require("./mods/simple-ast");
const { inline, setInlineOptions } = require("./mods/inlinev4"),
    localify = require("./mods/localify")
const { is, search, searchIs, print } = require("./mods/helper");
const indexCleaner = require("./mods/indexCleaner");
const indexFixer = require("./mods/indexFixer");
const query = require("./mods/query");

//const { LuauState } = await import("luau-web")
//import("luau-web").then((a) => LuauState = a.LuauState)

/**
    @param {string} path
    @param {any} args
*/

const runStep = (path, ...args) => require("./reversing/" + path)(...args)

/** @param {any} a */
const Do = (a) => a()
/** @param {any} a */
const Dont = (...a) => {}

defaultOptions.comments = false

/**
 * @param {string} path
*/
const deobfuscate = async (path, outFile="out.lua") => {
    const { LuauState } = await import("luau-web")

    const Options = {
        fork: null,
        iterStats: []
    }

    const src = (await fs.readFile(path)).toString()

    const content = beautify(src) // solves math alot faster than search()
    const start = performance.now()

    //print(content)

    if (/getgenv\(\)\[.+\] = function\(/.test(content)) {
        // @ts-ignore
        Options.fork = "25ms"
    }

    //if (process.argv[3])
    //    fs.writeFile("igbro.lua", content)

    /** @type {Array<AstObject>} */
    let output = []

    let fileAst;
    try {
        fileAst = parse(content)
    } catch (err) {
        console.error(`Unable to parse AST, message: ${err}`)
        return "Unable to parse AST.";
    }

    const State = await LuauState.createAsync()

    // Look for the largest while statement with a condition being {Identifier}

    query(fileAst, "CompoundAssignmentStatement").forEach((stat) => {
        //print(stat)
        const { variable, op, value } = stat
        Object.assign(stat, {
            type: "AssignmentStatement",
            variables: [ variable ],
            init: [{
                type: "BinaryExpression",
                operator: op,
                left: variable,
                right: value
            }]
        })
    })

    const MainFunctions = searchIs(fileAst, {
        type: "CallExpression",
        base: {
            type: "FunctionDeclaration"
        },
        arguments: []
    }) // CallExpression with .base being the function

    const VarargTable = simpleAst.varargTable()

    let MainFunction, EnvIdx;

    for (let f of MainFunctions) {
        if 
            // @ts-ignore
            (f.arguments.find((lastArg) => is(lastArg, VarargTable))
        ) {

            MainFunction = f
            // get Env here i guess

            for (let i = 0; i < f.arguments.length; i++) {
                const arg = f.arguments[i]

                if (
                    is(arg, {
                        type: "LogicalExpression",
                        operator: "or",
                        left: {
                            left: {
                                name: "getfenv"
                            }
                        }
                    })
                ) {
                    EnvIdx = i;
                    break
                }
            }

            break
        }
    }

    /*for (
        let Stat of searchIs(fileAst, {
            body: []
        })
    ) {
        if (MainFunction.base == Stat) continue

        const body = Stat.body;
        const newbody = []

        for (let i of body) {
            if (i.type == "AssignmentStatement") {
                const vars = i.variables
                if (vars.length <= 1 || vars.length != i.init.length) {
                    newbody.push(i)
                    continue
                }

                // turn it into multiple stats
                for (let x = 0; x < i.init.length; x++) {
                    newbody.push({
                        type: "AssignmentStatement",
                        variables: [ vars[x] ],
                        init: [ i.init[x] ]
                    })
                }
            }
            else
                newbody.push(i)
        }

        Stat.body = newbody
    }*/

    if (!MainFunction) {
        await fs.writeFile("formatted.lua", beautify(fileAst))

        throw new Error("Unable to locate MainFunction :(")
    }

    // @ts-ignore
    const Env = MainFunction.base.parameters[EnvIdx]

    if (!Env) throw new Error("Unable to find the Env parameter")

    let
        /** @type {AstObject} */
        WhileStat,
        /** @type {AstObject} */
        Pc,
        /** @type {AstObject} */
        ReturnVar,
        /** @type {AstObject} */
        Upvalues,
        /** @type {AstObject} */
        FunctionParams,
        /** @type {AstObject} */
        Unpack,
        Select = {
            type: "Identifier",
            name: "select"
        },
        /** @type {number} */
        StartOpc,
        /** @type {Record<string, boolean>} */
        Dispatchers = {};

    // get Unpack first:

    Do(() => {
        let Counter = 0;
        for (let Param of MainFunction.arguments) {
            if (
                is(Param, {
                    type: "LogicalExpression",
                    operator: "or",
                    left: { name: "unpack" }
                })
            )  Unpack = MainFunction.base.parameters[Counter]
            else if (
                is(Param, {
                    name: "select"
                })) Select = MainFunction.base.parameters[Counter]
            
            Counter++
        }

        const Body = MainFunction.base.body
        const Last = Body[Body.length - 1]

        if (
            is(Last, {
                type: "ReturnStatement",
                arguments: [
                    {
                        base: {
                            type: "CallExpression",
                            base: {
                                type: "Identifier"
                            },
                            arguments: [
                                {
                                    type: "NumericLiteral"
                                },
                                {
                                    type: "TableConstructorExpression"
                                }
                            ]
                        }
                    }
                ]
            })
        )
            StartOpc = Last.arguments[0].base.arguments[0].value
    })

    for (let { parameters, body } of search(MainFunction, "FunctionDeclaration")) {
        const Param = parameters[0]
        const LastStat = body[body.length - 1], LastStat_2 = body[body.length - 2]

        if (
            is(LastStat, {
                type: "ReturnStatement",
                arguments: [{
                    type: "CallExpression",
                    base: Unpack
                }]
            }) && 
            is(LastStat_2, {
                type: "AssignmentStatement",
                init: [{
                    type: "UnaryExpression",
                    operator: "#"
                }],
                variables: [ Param ]
            })
        )
        {
            ReturnVar = LastStat.arguments[0].arguments[0], Pc = Param, Upvalues = parameters[2], FunctionParams = parameters[1];

            for (let stat of body)
                if (stat.type == "WhileStatement") {
                    WhileStat = stat
                    break
                }
        }
    }

    const {
        RegTable,
    } = runStep("functions", MainFunction.base, Dispatchers)

    //try {
        output = await runStep("constarray", fileAst, output, State, Options)
    //} catch (err) {
        //console.error("Unable to decrypt constant array",err)
    //}

    if (process.argv[4])
        await fs.writeFile("formatted.lua", beautify(fileAst))

    Do(() => {
        const IfStat = search(WhileStat, "IfStatement")[0] || WhileStat
        
        const data = runStep("uncff", IfStat, StartOpc, {
            pc: Pc,
            dispatchers: Dispatchers,
            returnVar: ReturnVar,
            env: Env,
            upv: Upvalues,
            params: FunctionParams,
            reg: RegTable
        })

	    for (let i of data)
		    output.push(i)
    })

    runStep("repeatfix", output)

    //output = await runStep("constarray", fileAst, output, State)

    const dontLocalify = new Set()

    if (!process.argv[5]) {
        setInlineOptions({
            simplifyCalls: true,
            RegTable,
            Unpack: Unpack?.name
        })

        try {
            inline(output);
        } catch (err) {
            console.error("UNABLE TO INLINE",err)
        }

        try {
            indexFixer(output)
        } catch (err) {
            console.error("failed to fix indexes",err)
        }

        runStep("cleaner", output, {
            Env,
            FunctionParams,
            RegTable,
            Parameters: {
                Select,
                Unpack
            }
        }, dontLocalify)
    }

    await new Promise(async (res) => {
        try {
            const s = performance.now()
            output = await runStep("decrypt", output, Options.iterStats, {
                upvalues: Upvalues,
                regtable: RegTable
            }, State)

            print("Successfully decrypted strings in",Math.floor(performance.now()-s),"ms!")
        } catch (err) {
            const m = "Encrypt strings is off"
            // @ts-ignore
            if (err.message == m)
                print(m)
            else
                console.error(`Errored while decrypting strings:`, err)
        }

        res(1);
    })

    //fixNamecalls(output, { Unpack: Unpack?.name })
    indexCleaner(output, Env) // cuz EncryptStrings can add more stuff

    if (!process.argv[5])
        localify(output, dontLocalify);

    try {
        indexFixer(output)
    } catch (err) {
        console.error("failed to fix final indexes", err)
    }

    print("Done in",(performance.now() - start).toFixed(2),"ms.")
    await fs.writeFile(outFile, beautify(
        [
            {
                type: "LocalStatement",
                variables: [ simpleAst.ident("Env") ],
                init: [{
                    type: "CallExpression",
                    base: simpleAst.ident("getfenv"),
                    arguments: []
                }]
            },
            {
                type: "LocalStatement",
                variables: [ RegTable ],
                init: [simpleAst.emptyTable()]
            }
        ].concat(output),
        {
            solveMath: false
        }
    ))
}

deobfuscate(process.argv[2], process.argv[3])
