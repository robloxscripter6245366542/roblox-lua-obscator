module.exports = {
    labelStatement: function(e) {
        return {
            type: "LabelStatement",
            label: e
        }
    },
    breakStatement: function() {
        return {
            type: "BreakStatement"
        }
    },
    gotoStatement: function(e) {
        return {
            type: "GotoStatement",
            label: e
        }
    },
    returnStatement: function(e) {
        return {
            type: "ReturnStatement",
            arguments: e
        }
    },
    ifStatement: function(e) {
        return {
            type: "IfStatement",
            clauses: e
        }
    },
    ifClause: function(e, t) {
        return {
            type: "IfClause",
            condition: e,
            body: t
        }
    },
    elseifClause: function(e, t) {
        return {
            type: "ElseifClause",
            condition: e,
            body: t
        }
    },
    elseClause: function(e) {
        return {
            type: "ElseClause",
            body: e
        }
    },
    whileStatement: function(e, t) {
        return {
            type: "WhileStatement",
            condition: e,
            body: t
        }
    },
    doStatement: function(e) {
        return {
            type: "DoStatement",
            body: e
        }
    },
    repeatStatement: function(e, t) {
        return {
            type: "RepeatStatement",
            condition: e,
            body: t
        }
    },
    localStatement: function(e, t) {
        return {
            type: "LocalStatement",
            variables: e,
            init: t
        }
    },
    assignmentStatement: function(e, t) {
        return {
            type: "AssignmentStatement",
            variables: e,
            init: t
        }
    },
    callStatement: function(e) {
        return {
            type: "CallStatement",
            expression: e
        }
    },
    functionStatement: function(e, t, n, r) {
        return {
            type: "FunctionDeclaration",
            identifier: e,
            isLocal: n,
            parameters: t,
            body: r
        }
    },
    forNumericStatement: function(e, t, n, r, a) {
        return {
            type: "ForNumericStatement",
            variable: e,
            start: t,
            end: n,
            step: r,
            body: a
        }
    },
    forGenericStatement: function(e, t, n) {
        return {
            type: "ForGenericStatement",
            variables: e,
            iterators: t,
            body: n
        }
    },
    chunk: function(e) {
        return {
            type: "Chunk",
            body: e
        }
    },
    identifier: function(e) {
        return {
            type: "Identifier",
            name: e
        }
    },
    literal: function(e, t, n) {
        return {
            type: e = e === StringLiteral ? "StringLiteral" : e === NumericLiteral ? "NumericLiteral" : e === BooleanLiteral ? "BooleanLiteral" : e === NilLiteral ? "NilLiteral" : "VarargLiteral",
            value: t,
            raw: n
        }
    },
    varargLiteral: function() {
        return {
            type: "VarargLiteral",
            value: "...",
            raw: "..."
        }
    },
    tableKey: function(e, t) {
        return {
            type: "TableKey",
            key: e,
            value: t
        }
    },
    tableKeyString: function(e, t) {
        return {
            type: "TableKeyString",
            key: e,
            value: t
        }
    },
    tableValue: function(e) {
        return {
            type: "TableValue",
            value: e
        }
    },
    tableConstructorExpression: function(e) {
        return {
            type: "TableConstructorExpression",
            fields: e
        }
    },
    binaryExpression: function(op, left, right) {
        return {
            type: "and" === op || "or" === op ? "LogicalExpression" : "BinaryExpression",
            operator: op,
            left: left,
            right: right
        }
    },
    unaryExpression: function(e, t) {
        return {
            type: "UnaryExpression",
            operator: e,
            argument: t
        }
    },
    memberExpression: function(e, t, n) {
        return {
            type: "MemberExpression",
            indexer: t,
            identifier: n,
            base: e
        }
    },
    indexExpression: function(e, t) {
        return {
            type: "IndexExpression",
            base: e,
            index: t
        }
    },
    callExpression: function(e, t) {
        return {
            type: "CallExpression",
            base: e,
            arguments: t
        }
    },
    tableCallExpression: function(e, t) {
        return {
            type: "TableCallExpression",
            base: e,
            arguments: t
        }
    },
    stringCallExpression: function(e, t) {
        return {
            type: "StringCallExpression",
            base: e,
            argument: t
        }
    },
    comment: function(e, t) {
        return {
            type: "Comment",
            value: e,
            raw: t
        }
    }
};