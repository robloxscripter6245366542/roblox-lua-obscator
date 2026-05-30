#!/usr/bin/env python3
"""
Obfuscates Full_Combined.lua by base64-encoding the source and wrapping
it in a Lua decoder stub with mangled names and string.char-encoded literals.
"""
import base64, sys

def to_chars(s):
    return "string.char(" + ",".join(str(ord(c)) for c in s) + ")"

def split_chunks(s, n=76):
    return [s[i:i+n] for i in range(0, len(s), n)]

def build_obfuscated(source: str) -> str:
    encoded = base64.b64encode(source.encode("utf-8")).decode()
    chunks = split_chunks(encoded, 76)

    # Copyright notice encoded as string.char so it can't be grepped/removed trivially
    notice = "(c) SS Executor  |  Unauthorized copying or redistribution is prohibited."

    lines = []
    lines.append("-- " + to_chars(notice))
    lines.append("-- " + to_chars("https://github.com/robloxscripter6245366542/roblox-lua-obscator"))
    lines.append("")

    # Aliases with single-char mangled names
    lines.append("local _sc=string.char;local _sf=string.find;local _ss=string.sub;local _tc=table.concat;local _mf=math.floor;local _ld=load")
    lines.append("")

    # b64 alphabet hidden behind string.char to block casual grep
    # A-Z = 65-90, a-z = 97-122, 0-9 = 48-57, + = 43, / = 47
    az_upper = list(range(65, 91))
    az_lower = list(range(97, 123))
    digits   = list(range(48, 58))
    specials = [43, 47]
    all_chars = az_upper + az_lower + digits + specials
    lines.append("local _alpha=_sc(" + ",".join(str(c) for c in all_chars) + ")")
    lines.append("")

    # Base64 decode function — all identifiers are short/mangled
    lines.append("local function _dec(_s)")
    lines.append("    local _r,_v,_b={},0,0")
    lines.append("    _s=_s:gsub('[^'.._alpha..'=]','')")
    lines.append("    for _i=1,#_s do")
    lines.append("        local _ch=_ss(_s,_i,_i)")
    lines.append("        if _ch=='=' then break end")
    lines.append("        local _p=_sf(_alpha,_ch,1,true)")
    lines.append("        if not _p then break end")
    lines.append("        _v=_v*64+(_p-1)")
    lines.append("        _b=_b+6")
    lines.append("        if _b>=8 then")
    lines.append("            _b=_b-8")
    lines.append("            _r[#_r+1]=_sc(_mf(_v/2^_b)%256)")
    lines.append("            _v=_v%(2^_b)")
    lines.append("        end")
    lines.append("    end")
    lines.append("    return _tc(_r)")
    lines.append("end")
    lines.append("")

    # Encoded payload split across concatenated string pieces
    lines.append("local _payload=''")
    for chunk in chunks:
        lines.append("_payload=_payload..'%s'" % chunk)
    lines.append("")

    # Decode, compile, run
    lines.append("local _fn,_er=_ld(_dec(_payload))")
    lines.append("if not _fn then")
    lines.append("    warn(" + to_chars("[SS Executor] Obf decode error: ") + ".._er)")
    lines.append("else")
    lines.append("    _fn()")
    lines.append("end")

    return "\n".join(lines) + "\n"


if __name__ == "__main__":
    src_path = "Full_Combined.lua"
    out_path = "Full_Combined.lua"   # overwrite in place

    with open(src_path, "r", encoding="utf-8") as f:
        source = f.read()

    result = build_obfuscated(source)

    with open(out_path, "w", encoding="utf-8") as f:
        f.write(result)

    print(f"Done. Output: {out_path}  ({len(result):,} bytes, {result.count(chr(10))} lines)")
