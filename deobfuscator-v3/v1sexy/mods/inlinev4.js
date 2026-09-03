/* CRUICAL ISSUE

when using thoseWhoKnow(), make sure the input values WASNT clone(values) because otherwise it's just gonna make every single existing value unchangable
and that's just broken, we want stuff that changed not existed, so use assigned?
use thoseWhoKnowButSet
*/

/* ISSUE 2
when in functions or something that has clone(values) in the previous scope as values, stuff like Env are going to get inlined when they shouldn't because they're in outer,
(they're going to have inlineThing() called on them), but it shouldn't even get called as these aren't actual `values` of the original scope
*/

/* ISSUE 3
for something like:
m = 'hi'
print(m)
q = false
if q then
   while true do
        m = "x"
        print(m)
   end
end
it would NOT inline the first `m` because `dontChange` added m like wayyyy later (before m was even processed!) so fix it.
*/

/* ISSUE 4
J = 123
R = J
R = nil

gets treated as:
inlineThing(R) when R = J (because it's re-assigned)
inlineThing(J) (but it's already too late, R is gone, which was the only use of J)
inlineThing(R) (when r = nil)
*/

/* ISSUE 5
In prometheus, when you see this output:
r = true
while r do
    ...
end
if r gets re-assigned in the loop, it doesnt matter!
why? because the way a while loops works is it keeps going back to the block containing r = true
after executing the body in it
so we can just safely NOT add `r` to the dontChange list
*/

/* ISSUE 6
Everytime you pass clone(values) onto something, it's REALLY REALLY bad.
Why?
Because, first of all:
it's going to try to inline all of these values, and even if it does, it did that for nothing, since it's just a clone and nothing in it is going to matter.
so that's a waste of memory & performance, idk how to fix tho
Second of all, say for example:
V = 1;
print(V)
X = function()
    for i = 1, 2 do
        V = i
    end
end
it becomes
print(V)
X = function()
    for i = 1, 2 do
        V = i
    end
end
because the function thinks `V` is one of it's own values, which it should ONLY be able to read, not give to other stuff as 'outer'.
that sounds wrong

const assigned = new Set()
const newUses = makeEmptyCopy()

const newValues = clone(values)
const newOuter = new Set(Object.keys(values))

inline(
    stat.body,
    newValues,
    newUses,
    nest + 1,
    assigned,
    newOuter
)

*/

const { is, print, Clear, clone, isWeird, fixString } = require("./helper");

const query = require("./query");

const DEBUG = process.argv[1].includes("inline") && process.argv[2];

let settings = {
    simplifyCalls: false,
    simpleInlining: false, // if this is false, this will aggressively inline things.
    RegTable: null,
    Unpack: "unpack",
};

const RESET = "\x1b[0m";
const DIM = "\x1b[2m";
const BOLD = "\x1b[1m";

const COLORS = {
    green: "\x1b[32m",
    red: "\x1b[31m",
    yellow: "\x1b[33m",
    cyan: "\x1b[36m",
    magenta: "\x1b[35m",
    blue: "\x1b[0;94m",
    gray: "\x1b[90m",
};

const ACTION_STYLES = {
    Inlining: {
        color: COLORS.green,
        symbol: "✓",
        label: "INLINE",
    },
    Reassign: {
        color: COLORS.cyan,
        symbol: "→",
        label: "REASSIGN",
    },
    "Not inlining": {
        color: COLORS.red,
        symbol: "✗",
        label: "SKIP",
    },
    "Cleared data": {
        color: COLORS.magenta,
        symbol: "~",
        label: "CLEAR",
    },
    "Can't inline": {
        color: COLORS.red,
        symbol: "✗",
        label: "CANT INLINE",
    },
    "dont change": {
        color: COLORS.yellow,
        symbol: "!",
        label: "DONT CHANGE",
    },
    transform: {
        color: COLORS.cyan,
        symbol: "→",
        label: "REWRITE",
    },
    test: {
        color: COLORS.blue,
        symbol: "?",
        label: "TEST",
    },
};

const debug = DEBUG
    ? (nest, action, ...args) => {
        const indent = "  ".repeat(nest);
        const level = `${COLORS.gray}[L${nest}]${RESET}`;
        const style = ACTION_STYLES[action] ?? {
            color: COLORS.gray,
            symbol: "·",
            label: action.padEnd(8),
        };

        const coloredLabel = `${style.color}${BOLD}${style.symbol} ${style.label}${RESET}`;
        const rest = args.map((a, i) => {
            if (i === 0) return `${BOLD}${a}${RESET}`;

            if (
                typeof a === "string" &&
                /Expression|Statement|Literal|Identifier|Constructor/.test(a)
            )
                return `${DIM}${a}${RESET}`;

            return a;
        });

        const distance = 16;
        const spaces = " ".repeat(Math.abs(distance - style.label.length));

        console.log(`${indent}${level} ${coloredLabel}${spaces}`, ...rest);
    }
    : () => { };

/**
 * @typedef {Object<any,any>} AstObject
 * @property {string} type
 */

const assignPattern = {
    init: [],
    variables: [],
};

const dontInline = new Set([
    //"FunctionDeclaration",
    "TableConstructorExpression",
    //, "CallExpression"
]);
const simple = new Set([
    "NumericLiteral",
    "StringLiteral",
    "BooleanLiteral",
    "VarargLiteral",
    "NilLiteral",
    "Identifier",
]);

const dontChangeList = new Set();
const dontTouch = new Set(); // dontChange but for the actual AST objects

const minors = new Set();
const wasInlined = new Set();
const nonerz = new Set(["CallExpression", "NamecallExpression"]);
const tableAssigns = new Set(); // for inliner handling a[1] = true print(a[1])

const usedInDifferentScopesList = new Set();
const globalDifferentScopes = new Set();
const definedInScopeGlobal = {};

const isSimple = (a) => simple.has(a?.type); // won't matter if we inline this or not
const isUnusedRemovableTable = (a) => {
    if (a?.type != "TableConstructorExpression") return false;

    const fields = a.fields ?? [];
    if (fields.length == 0 || !fields.find((a) => a.value && !isSimple(a.value)))
        // the table is full of non isSimple values
        return true;

    return (
        fields.length == 1 &&
        fields[0]?.type == "TableValue" &&
        fields[0].value?.type == "VarargLiteral"
    );
};
const needsInline = (a) => !dontInline.has(a.type); // inlining this won't ruin performance or break behavior (maybe it will but not that important)

/**
    @param {Array<AstObject>} ast
    @param {Record<string, AstObject>} [values]
    @param {Record<string, Object<AstObject>>} [uses]
    @param {number} [nest]
    @param {} [newAssign]
*/
const inline = (
    ast, // the ast
    values = {}, // values of variables
    uses = {},
    nest = 0, // nest (not needed)
    newAssign, // the set that includes the changed variables (we modify this)
    outer = new Set(), // variables that exist out of the current scope
    ...extra
) => {
    if (!Array.isArray(ast)) return; // print("AST is not an array!!", ast);

    //const dontChange = dontChangeS ?? dontChangeList

    /** @type {Set} */
    const dontChange = extra[0] ?? dontChangeList;
    /** @type {Set} */
    const usedInDifferentScopes = extra[1] ?? usedInDifferentScopesList;
    const definedInScope = extra[2] ?? definedInScopeGlobal;

    const assignedInThisScope = new Set();

    /** @type {Record<string, Record<number, AstObject>>} Identifier = { Field: Value } */
    const tableAssigns = {}

    const Debug = (...a) => debug(nest, ...a);

    const replaceAll = (list, val) => {
        for (let i of list) if (!dontTouch.has(i)) Object.assign(i, val);
    };

    const clearStat = (Variable, why) => {
        //if (why) {
        Debug("Cleared data", Variable, why ?? "no reason given");
        //}
        delete values[Variable];
        delete uses[Variable];
    };

    const isDifferentScope = (name) => {
        const originalAst = definedInScope[name];
        if (originalAst && originalAst != ast)
            return true;
        return false;
    }

    const countVarUse = (val, u, z) => {
        const name = val.name;

        if (isDifferentScope(name)) {
            usedInDifferentScopes.add(name);
            globalDifferentScopes.add(val)
        }

        const parent = u ?? uses;
        const list = parent[name];
        if (list) list.push(val);
        else if (z) parent[name] = [val];
    };

    const countUse = (val, ...a) => {
        //(val.type == "Identifier" ? countVarUse : countUses)(val, ...a)
        if (val.type == "Identifier") countVarUse(val);
        else countUses(val, undefined, undefined, ...a);
    };
    const countUses = (stat, list, x, caspoor) => {
        const iterateOver = query(stat, "Identifier", {
            dontTouch: caspoor,
        });

        for (const a of iterateOver) countVarUse(a, list, x);
    };

    const getInit = (valueStat, variable) => {
        const vars = valueStat.variables;

        if (!vars) return [null, -1]

        let idx = 0,
            found = vars.length == 1;

        if (vars.length > 1)
            for (let i = vars.length - 1; i >= 0; i--) {
                // so things like a, a = 1, 2 get properly handled as `a = 2`
                const v = vars[i];
                if (v.name == variable) {
                    found = true;
                    idx = i;
                    break;
                }
            }

        if (!found) return [null, -1];

        const val = valueStat.init[idx] ?? {
            type: "NilLiteral",
            raw: "nil",
        };

        return [val, idx];
    };

    /**
     * inlines `variable` into it's uses regardless of any conditions
     */
    const inlineStat = (variable, oldUses, valueStat, y) => {
        oldUses ??= uses[variable];
        valueStat ??= values[variable];

        const [idx, val] = y;

        const vars = valueStat.variables,
            init = valueStat.init;

        valueStat.init = init.filter((a) => a != init[idx]);
        valueStat.variables = vars.filter((a) => a != vars[idx]);

        if (valueStat.variables.length == 0) Clear(valueStat);

        replaceAll(oldUses, val);
        clearStat(variable, "inlineStat called");

        //print(require("./beautifier")(ast))
    };

    const removeFromValue = (value, idx) => {
        // this presumes any 'CallExpression' or such returns 1 value to simplify things.
        //delete value.init[idx]
        //delete value.variables[idx]

        const init = value.init[idx],
            variable = value.variables[idx];

        value.init = value.init.filter((a) => a != init);
        if (!value.init.length) {
            // it's already empty, we can clear.
            return Clear(value);
        }
        value.variables = value.variables.filter((a) => a != variable);
    };

    const handleFunc = (init) => {
        /*const newValues = clone(values),
            newUses = makeEmptyCopy()//clone(uses);
        for (let param of init.parameters)
            if (param.type == "Identifier") {
                delete newValues[param.name];
                delete newUses[param.name];
            }

        inline(
            init.body, // ast
            newValues, // values
            newUses, // uses
            nest + 1, // nest
            null, // newAssign
            new Set(), // outer
            new Set(), // usedInDifferentScopes
            new Set(), // ???
            //definedInScope// definedInScope
        );

        mergeUses(newUses)*/
        handleBody(init, init.parameters, true)
    };

    const getValue = (thing) => {
        if (thing.type == "Identifier") {
            const variable = thing.name;
            const value = values[variable];
            //if (value) return getValue(getInit(value, variable)[0]);
            if (value) return getInit(value, variable)[0];
        }
        return thing;
    };

    const handlePass = (inits, stat) => {
        for (let init of inits ?? []) {
            const dontTouchSet = new Set();
            let funcDetected;

            switch (init.type) {
                case null:
                    break;
                case "CallExpression": {
                    if (stat.variables.length > 1) {
                        for (let { name } of stat.variables) {
                            const u = uses[name];
                            if (name && u) {
                                inlineThing(values[name], u, name, true);
                                addToDiddyList(name, "CallExpression init");
                            }
                        }
                        return; // unsafe to inline
                    }
                    break;
                }
                case "FunctionDeclaration":
                    funcDetected = true;
                    handleFunc(init);
                    break;
                case "LogicalExpression":
                    for (let x of query(init, "FunctionDeclaration")) {
                        handleFunc(x);
                        dontTouchSet.add(x);
                    }
                    break;
            }

            if (!funcDetected) countUse(init, dontTouchSet);
        }

        let i = -1;

        for (let variable of stat.variables) {
            i++;

            if (variable.type == "MemberExpression" || variable.type == "IndexExpression") {
                // both of these have .base
                // memberexpression has .identifier and .indexer
                // indexexpression has .index

                const base = variable.base

                if (base?.type == "Identifier") { // use ? just to be sure? idk
                    let list = tableAssigns[base.name]// ?? {}
                    const key = variable.type == "MemberExpression" ? variable.identifier : variable.index

                    if (isSimple(key) && key.type != "Identifier") {
                        if (!list) {
                            list = {}
                            tableAssigns[base.name] = list
                        }

                        const idx = key.value ?? key.name;
                        if (idx || idx == null) // to prevent re-assigns, because i dont wanna deal with them..
                            list[idx] = null
                        else
                            list[idx] = inits[i]
                    }
                }

                //countUses(variable, undefined, undefined, new Set([base]))

                countUse(variable)

                continue
            }

            if (is(variable, inits[i])) {
                countUses(variable);
                continue;
            }

            const name = variable.name;

            assignedInThisScope.add(name);

            if (newAssign) newAssign.add(name);

            const kapara = values[name],
                oldUses = uses[name];
            if (kapara) {
                // already existed before
                Debug("Reassign", name, "reassigned to", inits[i]); //, inits[i])
                inlineThing(kapara, oldUses, name, !outer.has(name));
                // since it's been reassigned, we can delete it from previous ignoring sets
                dontChange.delete(name);

                delete definedInScope[name];
                //definedInScope[name] = ast
            }
            else definedInScope[name] = ast; // it's been reassigned, clear the definedInScope thing cuz we don't know anything about it

            values[name] = stat;
            if (!oldUses || kapara)
                // if it had no previous uses (first assign) or it DID (not first assign) but it had a value (not no value)
                uses[name] = [];
        }
    };

    const inlineThing = (value, list, variable, reassigned, iReallyDc, skip) => {
        if (!value || !value.init)
            return Debug("Not inlining", variable, ": no value", value);

        const length = list.length;
        const [init, idx] = getInit(value, variable);

        if (idx == -1) {
            Debug("ERROR", "Unable to get init of variable", variable);
            return;
        }

        if (!skip) {
            const name = init.name;

            if (init.type == "Identifier" && uses[name]?.length == 1) {
                // solves issue #4
                if (dontChange.has(name)) {
                    Debug(
                        "Not inlining",
                        `issue #4 (${variable} = ${name} and ${name} has 1 use), however '${name}' is in dontChange.`,
                    );
                    if (!reassigned) clearStat(name, "issue #4 but dontchange");
                    // we can still inline this anyways due to it being simple lol

                    return inlineThing(value, list, variable, reassigned, iReallyDc, true);
                    // the variable is simple (because we know it's an identifier) so we can skip most checks and go to the core inlining part
                }
                Debug(
                    "test",
                    `yoo issue #4 (${variable} = ${name} and ${name} has 1 use.), probably ${reassigned ? "returning" : `inlining ${name}`}`,
                );

                const val = values[name];
                const valueOfInit = val?.type ? getInit(val, name)[0] : null;

                if (query(valueOfInit, value.variables[idx]).length) {
                    /*
                        this fixes:
                        V, Z, A = P[1], P[2], P[3];
                        P = V;
                        A = P(Z, A);

                        becoming
                        P = P[1]
                        A = P(P[2], P[3])

                        which is incorrect because it should've at least became
                        A = P[1](P[2], P[3])

                        ! so for now just don't inline it until we find a better way
                    */

                    Debug("Not inlining", variable, "issue #4 cycle");
                    return;
                }

                // if it's a simple literal u can change the value to the identifier's value, so for example:
                // A = 1
                // B = A
                // print(B)

                // can be inlined directly to

                // B = 1
                // print(B)

                // i'm not sure why i thought it NEEDS to be a simple literal to be able to inline?
                // there's already checks for that

                //if (!isSimple(valueOfInit))

                if (reassigned) return;

                //  return;
                value.init[idx] = valueOfInit;
                return true;
            }

            const canInline = needsInline(init);

            if (
                dontChange.has(variable) &&
                !reassigned &&
                !(length == 0 && isUnusedRemovableTable(init))
            ) {
                // uh so && !reassigned is because if it's a re-assign we know we're FORCED to inline it :(
                Debug("dont change", variable, init.type);
                return; // dontChange.delete(variable)
            }

            if (iReallyDc) {
                Debug("Inlining", "Forcefully inlining", variable, init.type);
                inlineStat(variable, list, value, [idx, init]);
                return true;
            }

            if (length == 0) {
                if (
                    settings.simplifyCalls &&
                    value.variables.length == 1 &&
                    init.type == "CallExpression"
                ) {
                    Clear(value);
                    value.type = "CallStatement";
                    value.expression = init;

                    dontChange.delete(variable);
                    clearStat(
                        variable,
                        "callexpression->callstatement deletes the variable",
                    );

                    return Debug("transform", variable, "CallExpression->CallStatement");
                }
                //else if (init.type == "TableConstructorExpression") {
                //  print("Yoo",init.fields)
                // if ALL the init's fields are simple literals u can remove..?
                // the reason this isn't implemented yet is because there can be
                // tables like:
                // UserIds = { 1, 2, 3, ... }
                // Games = { "HelloWorld" }
                // But never used, however they are important.
                //}
                else if (isUnusedRemovableTable(init)) {
                    inlineStat(variable, list, value, [idx, init]);
                    Debug("transform", variable, "Dropped unused table");
                    return true;
                } else if (reassigned && isSimple(init)) {
                    removeFromValue(value, idx);
                }

                return Debug(
                    "Not inlining",
                    variable,
                    "(has 0 uses)",
                    init.type,
                    reassigned ? "(reassigned)" : "(wasnt reassigned)",
                );
            }

            //if (!canInline && isDifferentScope(variable))// && !reassigned)
            // if it's not allowed to inline (table or function for example) and it was used in a scope other than this, making it potentially different in those scopes
            //    return Debug("Can't inline", variable, init.type, length);
            //print(canInline)

            if (!canInline) {
                if (isDifferentScope(variable) || (list.length == 1 && globalDifferentScopes.has(list[0])))
                    return Debug("Can't inline", variable, init.type, length);
                //Debug("test", "bro what",variable,list[0])
            }
        }

        const simple = isSimple(init);

        if (length != 1 && (!simple || settings.simpleInlining)) {
            return Debug("Not inlining", variable, `${length} uses (${init.type})`);
        }

        if (
            outer.has(variable) &&
            !newAssign.has(variable) // it's a variable outside of this scope AND it wasn't re-assigned
        )
            return Debug("Not inlining", variable, "is in outer vars");

        Debug("Inlining", variable, init.type, `(${list.length} uses)`);
        inlineStat(variable, list, value, [idx, init]);
        return true;
    };

    const finallyInline = (uses, values) => {
        for (let variable in uses) {
            Debug("test", "Finally inlining", variable);

            const list = uses[variable];
            const value = values[variable];

            inlineThing(value, list, variable);
        }
    };

    const addToDiddyList = (v, r) => {
        Debug(
            "dont change",
            "added",
            v,
            "to the dontChange list",
            `(${r ?? "no reason specified"})`,
        );
        dontChange.add(v);
    };

    const thoseWhoChangedButSet = (vals, innerValues) => {
        // those who know but for sets
        if (innerValues) {
            for (let v of vals) {
                if (innerValues[v]?.length)
                    // if it still exists and didnt get inlined
                    //dontChange.add(v)
                    //addToDiddyList(v, "thoseWhoChanged (is in innerValues)");
                    clearStat(v, "thoseWhoChanged (is in innerValues)");
            }
            return;
        }

        for (let v of vals) // every value that has changed, which means it's value is uncertain
            //dontChange.add(v)
            addToDiddyList(v, "thoseWhoChanged (plain add)");
    };

    const mergeInto = (target, source) => {
        for (let i = 0; i < source.length; i++) target.push(source[i]);
    };

    const mergeUses = (from, exclude) => {
        if (exclude) {
            for (let v in uses)
                if (!exclude.has(v))
                    //Object.assign(uses[v], n[v] ?? [])
                    mergeInto(uses[v], from[v] ?? []);
            return;
        }

        for (let v in uses)
            //Object.assign(uses[v], n[v] ?? [])
            mergeInto(uses[v], from[v] ?? []);
    };

    /**
     * Creates a copy of the current `values` to turn into an empty uses dict.
     */

    const makeEmptyCopy = () => {
        const yap = {};
        for (let v in values) yap[v] = [];
        return yap;
    };

    /**
     * Counts everything inside `stat` that isn't .body
     */
    const countStatUses = (stat) => {
        for (let i in stat) {
            if (i == "body") continue;
            const val = stat[i];
            if (!val) continue;

            countUse(val);
        }
    };

    const handleBody = (stat, ignore = [], isFunc) => {
        countStatUses(stat);

        const assigned = new Set();

        const newUses = makeEmptyCopy();

        const newValues = clone(values);
        const newOuter = new Set(assignedInThisScope);
        const newDontChange = new Set(dontChange); // inherit but don't pollute parent

        for (let i of ignore) {
            if (typeof i != "string")
                i = i.name
            newDontChange.add(i);

            delete newValues[i];
            delete newUses[i];
        }

        Debug("test", "entering", stat.type);

        inline(
            stat.body,
            newValues,
            newUses,
            nest + 1,
            assigned,
            newOuter,
            newDontChange, // scoped dontChange
        );

        Debug("test", "exited", stat.type);

        if (isFunc) {
            mergeUses(newUses, assigned)
            return;
        }

        const reassignedWithPendingUses = new Set();
        for (let v of assigned)
            if (newUses[v]?.length > 0)
                reassignedWithPendingUses.add(v);

        thoseWhoChangedButSet(assigned, newUses);
        mergeUses(newUses, reassignedWithPendingUses);
    };

    for (let stat of ast) {
        if (!stat) continue;

        if (stat.type == "CompoundAssignmentStatement") {
            // x += 1 -> x = x + 1
            const { variable, op, value } = stat;
            Clear(stat);

            stat.type = "AssignmentStatement";
            stat.variables = [variable];
            stat.init = [
                {
                    type: "BinaryExpression",
                    operator: op,
                    left: variable,
                    right: value,
                },
            ];

            dontTouch.add(stat.variables[0]); // fixes x = x + 1 becoming 0 = 0 + 1
            dontTouch.add(stat.init[0]);

            handlePass(stat.init, stat);
        } else if (is(stat, assignPattern)) handlePass(stat.init, stat);
        else {
            switch (stat.type) {
                case "ForGenericStatement":
                    for (const { name } of stat.variables) {
                        const usages = uses[name];

                        if (usages) {
                            inlineThing(values[name], usages, name);
                            clearStat(name, "in ForGenericStatement");
                        }
                    }
                    break;
                case "ForNumericStatement": {
                    handleBody(stat, [stat.variable.name]);
                    continue;
                }
                case "IfStatement": {
                    for (let clause of stat.clauses) {
                        handleBody(clause);
                    }

                    continue;
                }
                case "WhileStatement": {
                    const cond = stat.condition;
                    const dontChangeV1 = dontChange.has(cond.name);

                    handleBody(stat);

                    if (!dontChangeV1) dontChange.delete(cond.name); // solves issue #5

                    continue;
                }
                case "RepeatStatement": {
                    handleBody(stat)

                    continue;
                }
                case "ReturnStatement": {
                    countUses(stat);
                    continue;
                }
            }

            (stat.body ? handleBody : countUses)(stat);
        }
    }

    finallyInline(uses, values);

    return values;
};

if (DEBUG) {
    const fs = require("fs");

    const beautify = require("./beautifier");
    const { parse, defaultOptions } = require("./luaparse");
    defaultOptions.comments = false;

    const body = parse(fs.readFileSync("input.lua").toString());

    const s = performance.now();

    inline(body.body);

    const t = performance.now() - s;

    fs.writeFileSync(
        "inlined.lua",
        beautify(body, {
            solveMath: false,
        }),
    );
    print("took", Number(t.toFixed(2)), "ms to beautify");
}

module.exports = {
    inline,
    setInlineOptions: (a) => {
        settings = a;
    }
};
