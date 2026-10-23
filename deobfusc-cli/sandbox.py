#!/usr/bin/env python3
"""
sandbox.py — maximal dynamic deobfuscation sandbox (runs after vm_decoder.py).

Re-runs the target inside vm_decoder's fully-stubbed Roblox/Lua-5.4 environment
but additionally wraps the string-builder primitives (string.char/sub/gsub/
reverse, table.concat) to capture every runtime-DECRYPTED string — the plaintext
urls / keys / remote-names / config that Luraph stores encrypted and rebuilds at
runtime. Also captures all loadstring layers, the decompressed bytecode, HTTP
calls and requested globals (inherited from vm_decoder's harness).

For layered-loadstring obfuscators this fully peels every layer. For Luraph the
hub logic stays as bytecode (never re-loaded as a string), but all reachable
decrypted strings + endpoints are surfaced.

Usage: sandbox.py <workdir-from-vm_decoder> [original.lua]
Outputs in <workdir>: strings.txt (decrypted), plus layer_*/blob_*/http.txt/globals.txt
"""
import sys, os, re, subprocess, glob, shutil

HERE = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, HERE)
import vm_decoder as VD

# string-capture block injected ahead of vm_decoder's harness
CAPTURE = r'''
do
  local sf = assert(io.open("{WORK}/strings.txt","w"))
  local seen = {}
  local function interesting(s)
    if type(s)~="string" then return false end
    local n=#s; if n<4 or n>6000 then return false end
    local letters,printable=0,0
    for i=1,n do local b=s:byte(i)
      if b>=32 and b<127 then printable=printable+1
        if (b>=65 and b<=90) or (b>=97 and b<=122) then letters=letters+1 end end end
    return printable>=n*0.85 and letters>=2
  end
  local function rec(s) if interesting(s) and not seen[s] then seen[s]=true sf:write(s.."\n") sf:flush() end end
  local och=string.char;      string.char   =function(...) local r=och(...)      rec(r) return r end
  local ocat=table.concat;    table.concat  =function(t,s,i,j) local r=ocat(t,s,i,j) rec(r) return r end
  local osub=string.sub;      string.sub    =function(s,a,b) local r=osub(s,a,b)  rec(r) return r end
  local ogs=string.gsub;      string.gsub   =function(s,p,r2,n) local r,c=ogs(s,p,r2,n) rec(r) return r,c end
  local orv=string.reverse; if orv then string.reverse=function(s) local r=orv(s) rec(r) return r end end
end
'''

def main():
    if len(sys.argv) < 2:
        print("usage: sandbox.py <workdir-from-vm_decoder> [original.lua]"); sys.exit(1)
    work = sys.argv[1]
    vmfix = os.path.join(work, 'vm_interp.fixed.lua')
    if not os.path.exists(vmfix):
        print("[!] run vm_decoder.py first (need vm_interp.fixed.lua)"); sys.exit(2)
    # reuse the original patched.lua source tail produced by vm_decoder
    patched = os.path.join(work, 'patched.lua')
    if not os.path.exists(patched):
        print("[!] missing patched.lua — run vm_decoder.py"); sys.exit(2)
    src_body = open(patched, encoding='latin-1').read()
    # prepend the capture block (it sits before everything else)
    out = CAPTURE.replace('{WORK}', work) + src_body
    sp = os.path.join(work, 'sandbox.lua')
    with open(sp, 'wb') as f: f.write(out.encode('latin-1', 'replace'))

    for fn in ('strings.txt',):
        p = os.path.join(work, fn)
        if os.path.exists(p): os.remove(p)

    lua = next((b for b in ('lua5.4', 'lua5.3', 'lua') if shutil.which(b)), None)
    print(f"[*] sandbox running ({lua}) — capturing layers + decrypted strings ...")
    try: subprocess.run([lua, sp], capture_output=True, timeout=120)
    except subprocess.TimeoutExpired: print("[*] payload looped (expected); captures written")

    print("\n=== SANDBOX RESULTS ===")
    layers = glob.glob(os.path.join(work, 'layer_*.bin'))
    blobs  = sorted(glob.glob(os.path.join(work, 'vm_blob_*.bin')), key=os.path.getsize)
    print(f"loadstring layers : {len(layers)}")
    if blobs: print(f"decoded blobs     : {len(blobs)} (largest {os.path.getsize(blobs[-1])} B)")
    stp = os.path.join(work, 'strings.txt')
    if os.path.exists(stp):
        lines = [l.rstrip('\n') for l in open(stp, encoding='latin-1')]
        print(f"decrypted strings : {len(lines)}")
        hot = [l for l in lines if re.search(r'https?://|\.com|\.net|\.gg|/v[0-9]|key|token|webhook|discord|remote|whitelist|hwid', l, re.I)]
        if hot:
            print("  --- notable (urls/keys/endpoints) ---")
            for l in hot[:50]: print("   ", l[:160])
        else:
            print("  (no urls/keys reached — gated behind UI interaction in a passive run)")
    print("\n[done]", work)

if __name__ == '__main__':
    main()
