#!/usr/bin/env python3
"""
unc_executor.py — virtual UNC executor (runs after vm_decoder.py).

Runs a Luraph hub inside a near-complete virtual Roblox executor: the full
UNC/sUNC function surface + a faithful Instance/Signal/datatype layer
(unc_env.lua), the VM shims, and capture of all loadstring layers, decoded
bytecode, runtime-decrypted strings and HTTP/RemoteEvent calls. A UI driver
fires button signals so key-verify paths can execute.

This is the maximal "execute it like a real executor and capture everything"
stage. Note: a hub that busy-loops inside its own VM bytecode (render/poll loop)
may not yield in a headless run, so some gated HTTP may stay unreached — that is
a property of the hub's scheduling, not the environment's completeness.

Usage: unc_executor.py <workdir-from-vm_decoder> [original.lua]
Outputs in <workdir>: uloop_*/blob_*/strings.txt/http.txt/globals.txt
"""
import sys, os, re, subprocess, glob, shutil

HERE = os.path.dirname(os.path.abspath(__file__))

UNC_HARNESS = open(os.path.join(HERE, 'unc_harness.lua'), encoding='latin-1').read()

def main():
    if len(sys.argv) < 2:
        print("usage: unc_executor.py <workdir-from-vm_decoder> [original.lua]"); sys.exit(1)
    work = sys.argv[1]
    vmfix = os.path.join(work, 'vm_interp.fixed.lua')
    patched = os.path.join(work, 'patched.lua')
    if not (os.path.exists(vmfix) and os.path.exists(patched)):
        print("[!] run vm_decoder.py first (need vm_interp.fixed.lua + patched.lua)"); sys.exit(2)

    # original obfuscated body: strip vm_decoder's own stub harness, keep the script.
    # vm_decoder's patched.lua = HARNESS + src; we re-wrap src with the UNC harness.
    body = open(patched, encoding='latin-1').read()
    # the original script begins after vm_decoder's universal-fallback block;
    # simplest robust split: re-read the source the user passed if given.
    if len(sys.argv) > 2 and os.path.exists(sys.argv[2]):
        src = open(sys.argv[2], encoding='latin-1').read()
        m = re.search(r'do Q=\{6824.*?end;end;end;', src, re.DOTALL) or re.search(r'do Q=\{6824.*?end;end;', src, re.DOTALL)
        if m: src = src[:m.start()] + src[m.end():]
        src = src.replace(',unpack,', ',table.unpack or unpack,', 1)
    else:
        # fall back: take everything after the last harness sentinel
        marker = 'setmetatable(_G,{ __index'
        idx = body.rfind('end })')
        src = body[body.find('\n', idx):] if idx > 0 else body

    unc_env = open(os.path.join(HERE, 'unc_env.lua'), encoding='latin-1').read()
    harness = (UNC_HARNESS
               .replace('{UNC_ENV}', unc_env)
               .replace('{WORK}', work)
               .replace('{VMFIX}', vmfix))
    runlua = os.path.join(work, 'unc_run.lua')
    with open(runlua, 'wb') as f:
        f.write((harness + src).encode('latin-1', 'replace'))
    for fn in ('strings.txt', 'http.txt', 'globals.txt'):
        p = os.path.join(work, fn)
        if os.path.exists(p): os.remove(p)

    lua = next((b for b in ('lua5.4', 'lua5.3', 'lua') if shutil.which(b)), None)
    print(f"[*] UNC executor running ({lua}) ...")
    try: subprocess.run([lua, runlua], capture_output=True, timeout=120)
    except subprocess.TimeoutExpired: print("[*] hub looped (headless); captures written")

    print("\n=== UNC EXECUTOR RESULTS ===")
    print("loadstring layers:", len(glob.glob(os.path.join(work, 'layer_*.bin'))))
    print("decoded blobs    :", len(glob.glob(os.path.join(work, 'blob_*.bin'))) +
                                 len(glob.glob(os.path.join(work, 'vm_blob_*.bin'))))
    gp = os.path.join(work, 'globals.txt')
    if os.path.exists(gp):
        gl = sorted(set(l.strip() for l in open(gp) if l.strip()))
        print(f"undefined globals: {len(gl)}" + (f"  ({', '.join(gl[:15])})" if gl else "  (fully satisfied)"))
    hp = os.path.join(work, 'http.txt')
    if os.path.exists(hp) and os.path.getsize(hp):
        print("--- HTTP CAPTURED ---"); print(open(hp).read()[:2000])
    else:
        print("HTTP calls       : none reached (hub busy-loops headlessly)")
    sp = os.path.join(work, 'strings.txt')
    if os.path.exists(sp):
        lines = [l.rstrip('\n') for l in open(sp, encoding='latin-1')]
        hot = [l for l in lines if re.search(r'https?://|\.com|\.net|/v[0-9]|key|whitelist|webhook|hwid|verify', l, re.I)]
        print(f"decrypted strings: {len(lines)}")
        for l in hot[:40]: print("   ", l[:160])

if __name__ == '__main__':
    main()
