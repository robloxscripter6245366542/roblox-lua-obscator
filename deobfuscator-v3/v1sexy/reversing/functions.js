const { is, print, Clear } = require("../mods/helper")
const query = require("../mods/query");

module.exports = (body, dispatchers) => {
    let funcs, CurrentSlot = 0;
    for (let [assign, ret] of query(body, { sequence: [ "AssignmentStatement", "ReturnStatement" ] })) {
        if (
            assign.variables.length == assign.init.length && assign.variables.length > 3 &&
            is(ret, {
                type: "ReturnStatement",
                arguments: [{
                    type: "CallExpression"
                }]
            })) {
            funcs = assign
            break
        }
    }

    if (!funcs) throw new Error("`funcs` is null")

    const identifiers = {
        AddSlot: null,
        ClearSlot: null,
        RegTable: null
    }

    for (let Counter = 0; Counter < funcs.init.length; Counter++) {
        const func = funcs.init[Counter];

        if (func.type == "FunctionDeclaration") {
            const Variable = funcs.variables[Counter].name
            const Body = func.body;
            const LastStat = Body[Body.length - 1], LastStat_2 = Body[Body.length - 2]
            if (
                is(LastStat_2, {
                    type: "LocalStatement",
                    init: [{
                        type: "FunctionDeclaration",
                        body: [{
                            type: "ReturnStatement",
                            arguments: [{
                                type: "CallExpression"
                            }]
                        }]
                    }]
                }) &&
                is(LastStat, {
                    type: "ReturnStatement",
                    arguments: [{
                        type: "Identifier"
                    }]
                })
            )
                dispatchers[Variable] = true
            else if (
                LastStat.type == "IfStatement" && is(LastStat_2, {
                    type: "AssignmentStatement",
                    variables: [{
                        type: "IndexExpression"
                    }],
                    init: [{
                        type: "BinaryExpression",
                        operator: '-'
                    }]
                })
            )
                identifiers.RegTable = LastStat.clauses[0].body[0].variables[1].base, identifiers.ClearSlot = Variable
            else if (
                LastStat.type == "ReturnStatement" && is(LastStat_2, {
                    type: "AssignmentStatement",
                    variables: [{
                        type: "IndexExpression"
                    }],
                    init: [{
                        value: 1
                    }]
                })
            )
                identifiers.AddSlot = Variable
        }
    }

    for (let call of query(body, "CallExpression")) {
        const base = call.base, len = call.arguments.length

        if (base.name == identifiers.AddSlot && !len) {
            Clear(call)
            call.type = "NumericLiteral", call.value = ++CurrentSlot, call.raw = '' + CurrentSlot
        } else if (base.name == identifiers.ClearSlot && len == 1) {
            Clear(call)
            call.type = "NilLiteral", call.raw = "nil", call.value = "nil"
        }
    }

    return identifiers
}