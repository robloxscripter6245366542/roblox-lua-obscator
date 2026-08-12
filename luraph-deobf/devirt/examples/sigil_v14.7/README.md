# Worked example — `sample_sigil.lua` (Luraph v14.7)

A full deobfuscation of the repo's `../../sample_sigil.lua` sample, produced
end-to-end with the tools in this folder. Every artifact here is regenerable;
the commands that produced each are listed below.

## Files

| File | What it is |
|------|-----------|
| `vm_interpreter.lua` | The Luraph VM engine, peeled statically then re-indented with `beautify_lua.py`. **Token-identical** to the recovered source (whitespace only) and parses as Luau. 8,006 lines. |
| `program.devirtualized.lua` | The program's own logic, lifted from the VM bytecode: 91 protos, 9,179 instructions, 97% of opcodes resolved, 22,554 concrete constants inlined. Compiles under `luac5.4`. |
| `opcodes.full.json` | The per-build opcode map recovered for this sample (125 opcodes classified). |
| `behaviour_and_iocs.md` | The program's runtime config/behaviour, captured under a network-blocked sandbox. |

## What it turned out to be

A **SigilUI key-system loader** for the "Jnkie" hub — fetches
`https://cdn.jnkie.com/SigilUI.lua`, key file `Jnkie_key`, shop funnel to
`jnkie.com`, `discord.gg/jnkie`. No webhook/token/HWID exfil on the executed
paths. See `behaviour_and_iocs.md`.

## The honest limit

This is a **semantically faithful recovery**, not the original authored source.
Luraph permanently discards variable names, comments and formatting, so the
VM's identifiers (`fj`, `D`, `S`, …) and the program's registers (`e[...]`) are
mechanical, not original. The remaining ~3% of opcodes sit on paths that never
executed under the stub (e.g. behind the key check).

## Reproduce

```bash
cd luraph-deobf
# A Luau runtime is required. Either build the CLI (bash dynamic/build_luau.sh)
# or use Lune via a one-line shim:
cargo install lune
printf '#!/bin/sh\nexec lune run "$@"\n' > /tmp/luau && chmod +x /tmp/luau
L=/tmp/luau

# 1) static peel -> VM source + bytecode
python3 -m luauvmp luraph sample_sigil.lua -o /tmp/s1
mkdir -p /tmp/peeled
cp /tmp/s1.vm.lua /tmp/peeled/stage_0.lua
cp /tmp/s1.bytecode.bin /tmp/peeled/stage_1.bin

# 2) readable VM engine
python3 devirt/beautify_lua.py /tmp/peeled/stage_0.lua vm_interpreter.lua

# 3) recover the opcode map, capture values, lift the program
cd devirt
python3 run_vm.py    --vmdir /tmp/peeled --luau $L --mode cf       --out /tmp/cf.txt
python3 semantics.py --vmdir /tmp/peeled --luau $L --steps 14000   --out /tmp/sem.txt >/dev/null
python3 build_map.py --sem /tmp/sem.txt --cf /tmp/cf.txt --curated opcodes.json --out opcodes.full.json
python3 capture_values.py --vmdir /tmp/peeled --luau $L --out /tmp/values.txt
python3 run_vm.py    --vmdir /tmp/peeled --luau $L --mode fulldump --out /tmp/full.txt
python3 lift.py /tmp/full.txt --map opcodes.full.json --values /tmp/values.txt -o program.devirtualized.lua

# 4) runtime behaviour / IOCs (network blocked)
cd ../dynamic
python3 run.py ../sample_sigil.lua --luau $L --timeout 120 --strings
```
