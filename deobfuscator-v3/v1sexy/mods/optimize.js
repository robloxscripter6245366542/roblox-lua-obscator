const { Clear, clone } = require("./helper");

const isObject = (value) => value && typeof value === "object";

const isTableArrayInit = (stat) => {
    if (!stat || (stat.type !== "LocalStatement" && stat.type !== "AssignmentStatement"))
        return false;

    if (stat.variables?.length !== 1 || stat.init?.length !== 1)
        return false;

    const variable = stat.variables[0];
    const init = stat.init[0];

    if (variable?.type !== "Identifier" || init?.type !== "TableConstructorExpression")
        return false;

    return init.fields.every((field) => field?.type === "TableValue");
};

const makeScope = (parent = null) => ({
    parent,
    bindings: new Map()
});

const getBinding = (scope, name) => {
    for (let current = scope; current; current = current.parent) {
        if (current.bindings.has(name))
            return current.bindings.get(name);
    }

    return null;
};

const setBinding = (scope, name, binding) => {
    scope.bindings.set(name, binding);
};

const assignBinding = (scope, name, binding) => {
    for (let current = scope; current; current = current.parent) {
        if (current.bindings.has(name)) {
            current.bindings.set(name, binding);
            return;
        }
    }

    scope.bindings.set(name, binding);
};

const makeCandidate = (stat) => ({
    stat,
    values: stat.init[0].fields.map((field) => field.value),
    replacedAny: false,
    unresolvedUse: false
});

const flushCandidates = (candidates, startIndex = 0) => {
    for (let i = startIndex; i < candidates.length; i++) {
        const candidate = candidates[i];
        if (candidate.replacedAny && !candidate.unresolvedUse)
            Clear(candidate.stat);
    }
};

const replaceNode = (target, replacement) => {
    Clear(target);
    Object.assign(target, clone(replacement));
};

const visitChildren = (node, scope, candidates) => {
    for (const childKey in node) {
        if (node.type === "LocalStatement" && childKey === "variables")
            continue;
        if (node.type === "FunctionDeclaration" && (childKey === "identifier" || childKey === "parameters" || childKey === "body"))
            continue;
        if (node.type === "ForNumericStatement" && childKey === "variable")
            continue;
        if (node.type === "ForGenericStatement" && childKey === "variables")
            continue;

        visitExpression(node[childKey], scope, candidates, node, childKey);
    }
};

const isWritePosition = (parent, key) => {
    if (!parent) return false;

    return (
        (parent.type === "AssignmentStatement" && key === "variables") ||
        (parent.type === "LocalStatement" && key === "variables") ||
        (parent.type === "CompoundAssignmentStatement" && key === "variable")
    );
};

const visitExpression = (node, scope, candidates, parent = null, key = null) => {
    if (!isObject(node))
        return;

    if (Array.isArray(node)) {
        for (let i = 0; i < node.length; i++)
            visitExpression(node[i], scope, candidates, node, i);
        return;
    }

    if (node.type === "Identifier") {
        const binding = getBinding(scope, node.name);
        if (binding && !isWritePosition(parent, key))
            binding.unresolvedUse = true;
        return;
    }

    if (node.type === "IndexExpression" && node.base?.type === "Identifier") {
        const binding = getBinding(scope, node.base.name);
        if (binding) {
            const index = node.index;
            const isWrite = isWritePosition(parent, key);

            if (
                !isWrite &&
                index?.type === "NumericLiteral" &&
                Number.isInteger(index.value) &&
                index.value >= 1 &&
                index.value <= binding.values.length
            ) {
                const candidateStart = candidates.length;
                flushCandidates(candidates);
                replaceNode(node, binding.values[index.value - 1]);
                binding.replacedAny = true;
                // Keep walking the replacement so nested function bodies inside
                // inlined expression trees still get analyzed.
                visitChildren(node, scope, candidates);
                flushCandidates(candidates, candidateStart);
                return;
            }

            binding.unresolvedUse = true;
        }
    }

    if (node.type === "FunctionDeclaration") {
        visitFunction(node, scope, candidates);
        return;
    }

    visitChildren(node, scope, candidates);
};

const visitBody = (body, parentScope, candidates) => {
    const scope = makeScope(parentScope);

    for (const stat of body)
        visitStatement(stat, scope, candidates);
};

const visitFunction = (node, outerScope, candidates) => {
    const scope = makeScope(outerScope);

    if (node.isLocal && node.identifier?.type === "Identifier") {
        const selfBinding = getBinding(outerScope, node.identifier.name);
        if (selfBinding !== null)
            setBinding(scope, node.identifier.name, selfBinding);
    }

    for (const param of node.parameters ?? [])
        if (param?.type === "Identifier")
            setBinding(scope, param.name, null);

    visitBody(node.body ?? [], scope, candidates);
};

const visitStatement = (stat, scope, candidates) => {
    if (!isObject(stat) || Array.isArray(stat))
        return;

    switch (stat.type) {
        case "LocalStatement": {
            for (const init of stat.init ?? [])
                visitExpression(init, scope, candidates, stat, "init");

            for (let i = 0; i < (stat.variables?.length ?? 0); i++) {
                const variable = stat.variables[i];
                if (variable?.type !== "Identifier")
                    continue;

                const binding = isTableArrayInit(stat) && i === 0 ? makeCandidate(stat) : null;
                setBinding(scope, variable.name, binding);

                if (binding)
                    candidates.push(binding);
            }
            return;
        }
        case "AssignmentStatement": {
            for (const init of stat.init ?? [])
                visitExpression(init, scope, candidates, stat, "init");

            for (const variable of stat.variables ?? [])
                visitExpression(variable, scope, candidates, stat, "variables");

            if (isTableArrayInit(stat)) {
                const binding = makeCandidate(stat);
                assignBinding(scope, stat.variables[0].name, binding);
                candidates.push(binding);
            } else {
                for (const variable of stat.variables ?? [])
                    if (variable?.type === "Identifier")
                        assignBinding(scope, variable.name, null);
            }
            return;
        }
        case "CallStatement":
            visitExpression(stat.expression, scope, candidates, stat, "expression");
            return;
        case "FunctionDeclaration":
            if (stat.identifier?.type === "Identifier" && stat.isLocal)
                setBinding(scope, stat.identifier.name, null);
            else if (stat.identifier?.type === "Identifier")
                assignBinding(scope, stat.identifier.name, null);
            visitFunction(stat, scope, candidates);
            return;
        case "IfStatement":
            for (const clause of stat.clauses ?? []) {
                if (clause.condition)
                    visitExpression(clause.condition, scope, candidates, clause, "condition");
                visitBody(clause.body ?? [], scope, candidates);
            }
            return;
        case "WhileStatement":
            visitExpression(stat.condition, scope, candidates, stat, "condition");
            visitBody(stat.body ?? [], scope, candidates);
            return;
        case "RepeatStatement": {
            const repeatScope = makeScope(scope);
            for (const inner of stat.body ?? [])
                visitStatement(inner, repeatScope, candidates);
            visitExpression(stat.condition, repeatScope, candidates, stat, "condition");
            return;
        }
        case "DoStatement":
            visitBody(stat.body ?? [], scope, candidates);
            return;
        case "ForNumericStatement": {
            visitExpression(stat.start, scope, candidates, stat, "start");
            visitExpression(stat.end, scope, candidates, stat, "end");
            if (stat.step)
                visitExpression(stat.step, scope, candidates, stat, "step");

            const loopScope = makeScope(scope);
            if (stat.variable?.type === "Identifier")
                setBinding(loopScope, stat.variable.name, null);
            for (const inner of stat.body ?? [])
                visitStatement(inner, loopScope, candidates);
            return;
        }
        case "ForGenericStatement": {
            for (const iterator of stat.iterators ?? [])
                visitExpression(iterator, scope, candidates, stat, "iterators");

            const loopScope = makeScope(scope);
            for (const variable of stat.variables ?? [])
                if (variable?.type === "Identifier")
                    setBinding(loopScope, variable.name, null);
            for (const inner of stat.body ?? [])
                visitStatement(inner, loopScope, candidates);
            return;
        }
        case "ReturnStatement":
            for (const arg of stat.arguments ?? [])
                visitExpression(arg, scope, candidates, stat, "arguments");
            return;
        default:
            for (const key in stat)
                visitExpression(stat[key], scope, candidates, stat, key);
    }
};

module.exports = (output) => {
    const candidates = [];

    visitBody(output, null, candidates);
    flushCandidates(candidates);
};