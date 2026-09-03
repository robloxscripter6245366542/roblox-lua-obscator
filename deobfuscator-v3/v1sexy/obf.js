const fs = require("fs")
const spawn = require("child_process").spawn

const args = process.argv.splice(2)

const preset = args[0]
const presets = new Set([ "weak", "medium", "strong", "encrypt", "yap" ])

const log = (level, ...data) => {
    switch (level) {
        case 1: // red
            return console.log("\x1b[31m" + ([...data].join(" ")), "\x1b[0m")
        case 2: // yellow
            return console.log("\x1b[33m" + ([...data].join(" ")), "\x1b[0m")
        case 3: // green
            return console.log("\x1b[32m" + ([...data].join(" ")), "\x1b[0m")
        default: // none of these options
            if (level != 0)
                return console.log(level, ...data)

            return console.log(...data)
    }
}

if (!presets.has(preset?.toLowerCase()))
    return log(1, `Invalid preset; valid preset names: \`${[...presets.values()].join(", ")}\``);

const file = args[1]

if (!file)
    return log(1, "Please input a file lil ahh boi..")

log(3, "Processing..")

const out = `out/${fs.readdirSync("out").length + 1}.lua`

const s = performance.now()
const proc = spawn("lua", [ "Prometheus/cli.lua", "--p", preset, "--o", out, file ])

proc.stdout.on("data", (a) => log(0, a.toString()))
proc.stderr.on("data", (a) => log(1, a.toString()));

proc.on("exit", (a) => {
    if (!a)
        return log(3, `Successfully saved to ${out} in ${Math.floor(performance.now() - s)} ms.`)
    log(1, `Exited with error code ${a}.`)
})