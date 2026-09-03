const parse = require("./luaparse").parse
const beautify = require("./beautifier")

const walk = (node, fn) => {
    if (!node || typeof node !== "object") return
    fn(node)
    for (const key of Object.keys(node)) {
        const val = node[key]
        if (Array.isArray(val))
            for (const child of val) walk(child, fn)
        else if (val && typeof val === "object" && val.type)
            walk(val, fn)
    }
}

const IS_REGISTER = /^[rv]\d+$/ // r1 or r2 or v1 or v2, ...

const renameUses = (node, env, skipSet = new Set()) => {
    walk(node, n => {
        if (n.type === "Identifier" && !skipSet.has(n) && n.name in env)
            n.name = env[n.name] // env[n.name] must exist as we checked that in 'n.name in env'
    })
}

const localify = (ast, dont=new Set()) => {
    const env = {}
    let varId = 0
    const newReg = () => `v${++varId}`

    for (const stat of ast) {
        if (!stat || dont.has(stat) || stat.type == "LocalStatement") continue

        if (stat.type === "AssignmentStatement") {
            const lhsVars = stat.variables ?? []
            const lhsSet = new Set(lhsVars)

            let dont;

            for (const init of stat.init ?? [])
                renameUses(init, env, lhsSet)

            for (const variable of lhsVars) {
                if (variable.type !== "Identifier") {
                    renameUses(variable, env)
                    dont = true;
                    continue
                }

                if (IS_REGISTER.test(variable.name)) {
                    if (variable.name in env) {
                        dont = true
                        continue
                    }
                    env[variable.name] = variable.name
                    continue
                }

                const reg = newReg()
                env[variable.name] = reg
                variable.name = reg
            }

            if (!dont)
                stat.type = "LocalStatement"
        }
        else if (stat.type === "FunctionDeclaration") {
            const skipSet = new Set()
            const id = stat.identifier

            if (stat.isLocal && id?.type === "Identifier") {
                const old = id.name

                if (IS_REGISTER.test(old))
                    env[old] = old
                else {
                    const reg = newReg()
                    env[old] = reg
                    id.name = reg
                }

                skipSet.add(id)
            }

            renameUses(stat, env, skipSet)
        }
        else
            renameUses(stat, env)
    }
}

if (process.argv[2] && process.argv[1].includes("localify")) {
    const fs = require("fs")

    const src = fs.readFileSync(process.argv[2]).toString()
    const body = parse(src)

    localify(body.body)

    const out = beautify(body, { solveMath: false })
    const outPath = process.argv[3] ?? "localified.lua"
    fs.writeFileSync(outPath, out)
    console.log(`Written to ${outPath}`)
}

module.exports = localify
