// Validate the JS obfuscator against the corpus by executing output with lua5.4.
const fs = require("fs");
const cp = require("child_process");
const path = require("path");
const Ferret = require(require("path").join(__dirname, "ferret.web.js"));

const suite = process.argv[2] || "/workspace/lua-crypt";
const seed = parseInt(process.argv[3] || "7", 10);
const layersArg = process.argv[4]; // e.g. "numbers,strings" or undefined
const layers = layersArg ? layersArg.split(",") : undefined;

function walk(dir, acc) {
  for (const e of fs.readdirSync(dir, { withFileTypes: true })) {
    const p = path.join(dir, e.name);
    if (e.isDirectory()) walk(p, acc);
    else if (e.name.endsWith(".lua")) acc.push(p);
  }
  return acc;
}
function normalize(s) {
  s = s.replace(/\S*\.lua/g, "CHUNK");
  s = s.replace(/CHUNK:\d+/g, "CHUNK:L");
  s = s.replace(/\s*\(\.\.\.tail calls\.\.\.\)\n?/g, "\n");
  return s;
}
function runLua(file) {
  try {
    return cp.execSync(`lua5.4 '${file}' 2>&1`, { encoding: "latin1", maxBuffer: 1 << 26 });
  } catch (e) {
    return (e.stdout || "") + (e.stderr || "");
  }
}

const files = walk(suite, []).sort();
const tmp = `/tmp/ferret_js_${process.pid}.lua`;
let total = 0, pass = 0, fail = 0, skip = 0, obfErr = 0;
const failures = [];

for (const f of files) {
  total++;
  const src = fs.readFileSync(f, "latin1");
  const o1 = normalize(runLua(f));
  const o2 = normalize(runLua(f));
  if (o1 !== o2) { skip++; continue; }
  let obf;
  try {
    obf = Ferret.obfuscate(src, { seed, layers, chunkname: f });
  } catch (e) {
    obfErr++; fail++; failures.push([f, "OBF ERROR: " + e.message]); continue;
  }
  fs.writeFileSync(tmp, obf, "latin1");
  const oo = normalize(runLua(tmp));
  if (oo === o1) pass++;
  else { fail++; failures.push([f, "MISMATCH"]); }
}
try { fs.unlinkSync(tmp); } catch (e) {}

console.log("=".repeat(56));
console.log(`JS port validation  seed=${seed}  layers=${layers ? layers.join(",") : "(default)"}`);
console.log(`Total: ${total}  Pass: ${pass}  Fail: ${fail}  Skip: ${skip}  ObfErr: ${obfErr}`);
console.log(`Pass rate (of comparable): ${(100 * pass / (pass + fail)).toFixed(1)}%`);
console.log("=".repeat(56));
for (const [f, r] of failures.slice(0, 25)) console.log("  " + f + "  -- " + r);
