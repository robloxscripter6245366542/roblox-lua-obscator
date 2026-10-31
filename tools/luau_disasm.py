"""Luau bytecode parser + disassembler (handles bytecode v14 from the 2026-10-31 Anime Ball dump: size-prefixed protos, CALL re-encoded as op 87 + feedback word). Usage: python3 tools/luau_disasm.py <file-with-hex>"""
import struct, sys

OPS = ["NOP","BREAK","LOADNIL","LOADB","LOADN","LOADK","MOVE","GETGLOBAL","SETGLOBAL","GETUPVAL","SETUPVAL","CLOSEUPVALS",
"GETIMPORT","GETTABLE","SETTABLE","GETTABLEKS","SETTABLEKS","GETTABLEN","SETTABLEN","NEWCLOSURE","NAMECALL","CALL","RETURN",
"JUMP","JUMPBACK","JUMPIF","JUMPIFNOT","JUMPIFEQ","JUMPIFLE","JUMPIFLT","JUMPIFNOTEQ","JUMPIFNOTLE","JUMPIFNOTLT","ADD","SUB",
"MUL","DIV","MOD","POW","ADDK","SUBK","MULK","DIVK","MODK","POWK","AND","OR","ANDK","ORK","CONCAT","NOT","MINUS","LENGTH",
"NEWTABLE","DUPTABLE","SETLIST","FORNPREP","FORNLOOP","FORGLOOP","FORGPREP_INEXT","FASTCALL3","FORGPREP_NEXT","NATIVECALL",
"GETVARARGS","DUPCLOSURE","PREPVARARGS","LOADKX","JUMPX","FASTCALL","COVERAGE","CAPTURE","SUBRK","DIVRK","FASTCALL1",
"FASTCALL2","FASTCALL2K","FORGPREP","JUMPXEQKNIL","JUMPXEQKB","JUMPXEQKN","JUMPXEQKS","IDIV","IDIVK"]
AUX = {"GETGLOBAL","SETGLOBAL","GETIMPORT","GETTABLEKS","SETTABLEKS","NAMECALL","JUMPIFEQ","JUMPIFLE","JUMPIFLT","JUMPIFNOTEQ",
"JUMPIFNOTLE","JUMPIFNOTLT","NEWTABLE","SETLIST","FORGLOOP","LOADKX","FASTCALL2","FASTCALL2K","FASTCALL3","JUMPXEQKNIL",
"JUMPXEQKB","JUMPXEQKN","JUMPXEQKS"}

class R:
    def __init__(s,b): s.b=b; s.i=0
    def u8(s): v=s.b[s.i]; s.i+=1; return v
    def u32(s): v=struct.unpack_from("<I",s.b,s.i)[0]; s.i+=4; return v
    def i32(s): v=struct.unpack_from("<i",s.b,s.i)[0]; s.i+=4; return v
    def f64(s): v=struct.unpack_from("<d",s.b,s.i)[0]; s.i+=8; return v
    def f32(s): v=struct.unpack_from("<f",s.b,s.i)[0]; s.i+=4; return v
    def var(s):
        r=0; sh=0
        while True:
            c=s.u8(); r|=(c&127)<<sh; sh+=7
            if not c&128: return r
    def raw(s,n): v=s.b[s.i:s.i+n]; s.i+=n; return v

def parse(b, opmul=None):
    r=R(b); ver=r.u8()
    if ver==0: return {"error": b[1:].decode("utf8","replace")}
    tv=r.u8() if ver>=4 else 0
    strings=[r.raw(r.var()).decode("utf8","replace") for _ in range(r.var())]
    S=lambda k: strings[k-1] if 0<k<=len(strings) else None
    if tv==3:
        while True:
            idx=r.u8()
            if idx==0: break
            r.var()
    protos=[]
    for _ in range(r.var()):
        p={}
        sized = ver>=7
        if sized:
            psize=r.var(); pstart=r.i
        p["maxstack"],p["params"],p["nups"],p["vararg"]=r.u8(),r.u8(),r.u8(),r.u8()
        if ver>=4:
            p["flags"]=r.u8(); r.raw(r.var())
        p["code"]=[r.u32() for _ in range(r.var())]
        ks=[]
        for _ in range(r.var()):
            t=r.u8()
            if t==0: ks.append(None)
            elif t==1: ks.append(bool(r.u8()))
            elif t==2: ks.append(r.f64())
            elif t==3: ks.append(("str",S(r.var())))
            elif t==4: ks.append(("imp",r.u32()))
            elif t==5: ks.append(("tab",[r.var() for _ in range(r.var())]))
            elif t==6: ks.append(("clo",r.var()))
            elif t==7: ks.append(("vec",r.f32(),r.f32(),r.f32(),r.f32()))
            elif t==8:
                n=r.var(); ks.append(("tabk",[(r.var(),r.i32()) for _ in range(n)]))
            elif t==9: ks.append(("int", struct.unpack_from("<q",r.raw(8))[0]))
            else: raise ValueError("const type %d at %d"%(t,r.i))
        p["k"]=ks
        p["p"]=[r.var() for _ in range(r.var())]
        p["line"]=r.var(); p["name"]=S(r.var())
        if r.u8():
            lg=r.u8(); n=len(p["code"]); r.raw(n); r.raw(4*(((n-1)>>lg)+1))
        if r.u8():
            locs=[]
            for _ in range(r.var()):
                locs.append((S(r.var()),r.var(),r.var(),r.u8()))
            p["locals"]=locs
            p["upnames"]=[S(r.var()) for _ in range(r.var())]
        if sized: p["slack"]=pstart+psize-r.i; r.i=pstart+psize
        protos.append(p)
    main=r.var()
    return {"ver":ver,"tv":tv,"strings":strings,"protos":protos,"main":main,"rest":len(b)-r.i}

def detect_mul(protos):
    # encoded op = op*mul & 255. Try 1 and 227; pick the one whose last insn is RETURN most often.
    best=None
    for mul in (1,227):
        inv=pow(mul,-1,256)
        hits=sum(1 for p in protos if p["code"] and ((p["code"][-1]&255)*inv)%256==OPS.index("RETURN"))
        if best is None or hits>best[1]: best=(mul,hits)
    return best[0]

def kstr(k):
    if isinstance(k,tuple):
        if k[0]=="str": return repr(k[1])
        return "%s%s"%(k[0],k[1:])
    return repr(k)

def disasm(res):
    protos=res["protos"]; mul=detect_mul(protos); inv=pow(mul,-1,256); out=[]
    strings=res["strings"]
    for pi,p in enumerate(protos):
        out.append("\nfunction #%d %s (params=%d up=%d line=%d)%s"%(pi,p["name"] or "?",p["params"],p["nups"],p["line"]," [main]" if pi==res["main"] else ""))
        if p.get("upnames"): out.append("  upvalues: "+", ".join(str(u) for u in p["upnames"]))
        code=p["code"]; i=0
        while i<len(code):
            w=code[i]; op=((w&255)*inv)%256; name=OPS[op] if op<len(OPS) else "OP%d"%op
            A=(w>>8)&255; B=(w>>16)&255; C=(w>>24)&255; D=w>>16
            if D>=32768: D-=65536
            E=w>>8
            if E>=1<<23: E-=1<<24
            if op==87: name="CALL"   # v14: CALL re-encoded with a trailing feedback word
            aux=code[i+1] if (name in AUX or op==87) and i+1<len(code) else None
            note=""
            if name in ("LOADK",): note=kstr(p["k"][D]) if 0<=D<len(p["k"]) else ""
            elif name in ("GETGLOBAL","SETGLOBAL","GETTABLEKS","SETTABLEKS","NAMECALL") and aux is not None and aux<len(p["k"]): note=kstr(p["k"][aux])
            elif name=="GETIMPORT" and 0<=D<len(p["k"]):
                k=p["k"][D]
                if isinstance(k,tuple) and k[0]=="imp":
                    v=k[1]; n=v>>30; ids=[(v>>20)&1023,(v>>10)&1023,v&1023][:n]
                    note=".".join(str(p["k"][x][1]) if x<len(p["k"]) and isinstance(p["k"][x],tuple) else "?" for x in ids)
            elif name in ("JUMPXEQKS","JUMPXEQKN") and aux is not None and (aux&0xFFFFFF)<len(p["k"]): note="%s %s"%(kstr(p["k"][aux&0xFFFFFF]),"NOT" if aux>>31 else "")
            elif name in ("ADDK","SUBK","MULK","DIVK","MODK","POWK","ANDK","ORK","IDIVK") and C<len(p["k"]): note=kstr(p["k"][C])
            elif name in ("SUBRK","DIVRK") and B<len(p["k"]): note=kstr(p["k"][B])
            elif name in ("NEWCLOSURE","DUPCLOSURE"): note="-> proto %s"%(p["p"][D] if name=="NEWCLOSURE" and 0<=D<len(p["p"]) else D)
            elif name in ("JUMP","JUMPBACK","JUMPIF","JUMPIFNOT","JUMPXEQKNIL","JUMPXEQKB","JUMPXEQKN","JUMPXEQKS","JUMPIFEQ","JUMPIFLE","JUMPIFLT","JUMPIFNOTEQ","JUMPIFNOTLE","JUMPIFNOTLT","FORNPREP","FORNLOOP","FORGPREP","FORGLOOP","FORGPREP_NEXT","FORGPREP_INEXT"): note="-> %d"%(i+1+D)
            elif name=="JUMPX": note="-> %d"%(i+1+E)
            out.append("  %4d %-14s A=%-3d B=%-3d C=%-3d D=%-6d %s"%(i,name,A,B,C,D,note))
            i+=2 if aux is not None else 1
    return "\n".join(out)

def summary(res):
    return {"ver":res["ver"],"strings":len(res["strings"]),"protos":len(res["protos"]),"rest":res["rest"]}

if __name__=="__main__":
    data=bytes.fromhex(open(sys.argv[1]).read().strip())
    res=parse(data); print(summary(res)); print(disasm(res))
