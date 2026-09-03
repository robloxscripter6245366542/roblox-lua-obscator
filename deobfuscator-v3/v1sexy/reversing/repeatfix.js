const { clone } = require("../mods/helper");
const { inline, setInlineOptions } = require("../mods/inlinev4");

setInlineOptions({
    simpleInlining: true,
});

const isRepeatExitGuard = (stat) =>
    stat?.type === "IfStatement" &&
    stat.clauses?.length === 1 &&
    stat.clauses[0]?.type === "IfClause" &&
    stat.clauses[0].body?.length === 1 &&
    stat.clauses[0].body[0]?.type === "ReturnStatement" &&
    (stat.clauses[0].body[0].arguments?.length ?? 0) === 0;

const isLoopish = (stat) =>
    stat?.type === "ForNumericStatement" ||
    stat?.type === "ForGenericStatement" ||
    stat?.type === "WhileStatement";

const compact = (body) => body.filter((stat) => stat?.type);

const recurseInto = (stat) => {
    if (!stat?.type) return;

    switch (stat.type) {
        case "IfStatement":
            for (const clause of stat.clauses ?? [])
                transformBody(clause.body ?? []);
            break;
        case "WhileStatement":
        case "RepeatStatement":
        case "ForNumericStatement":
        case "ForGenericStatement":
        case "DoStatement":
        case "FunctionDeclaration":
            transformBody(stat.body ?? []);
            break;
    }
};

function transformBody(body) {
    for (const stat of body)
        recurseInto(stat);

    for (let i = 0; i < body.length - 1; i++) {
        if (!isLoopish(body[i]))
            continue;

        const trailing = compact(body.slice(i + 1));
        if (!trailing.length)
            continue;

        const last = trailing[trailing.length - 1];
        if (!isRepeatExitGuard(last))
            continue;

        const normalized = clone(trailing);
        inline(normalized);

        const finalGuard = compact(normalized).at(-1);
        if (!isRepeatExitGuard(finalGuard))
            continue;

        const repeatBody = [body[i], ...compact(normalized).slice(0, -1)];
        body.splice(i, body.length - i, {
            type: "RepeatStatement",
            body: repeatBody,
            condition: finalGuard.clauses[0].condition,
        });
        return;
    }
}

module.exports = (output) => transformBody(output);
