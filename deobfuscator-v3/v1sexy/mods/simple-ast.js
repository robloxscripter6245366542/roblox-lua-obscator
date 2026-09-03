const ast = require('./ast')

const fieldsTable = (fields) => {
        return {
            type: "TableConstructorExpression",
            fields:
                Array.isArray(fields) ?
                fields.map((a) => {
                    return {
                        type: "TableValue",
                        value: a
                    }
                }) :
                [{
                    type: "TableValue",
                    value: fields
                }]
        }
    }

module.exports = {
    emptyTable: () => {
        return {
            type: "TableConstructorExpression",
            fields: []
        }
    },
    fieldsTable,
    varargTable: () => fieldsTable([ast.varargLiteral()]),
    ident: ast.identifier
}