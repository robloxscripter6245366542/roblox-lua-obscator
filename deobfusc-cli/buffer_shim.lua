-- Luau buffer library shim (byte-accurate) for Lua 5.4
if not buffer then
  local function clamp8(v) return math.floor(v) & 0xFF end
  buffer = {}
  local meta = {__index=function() return 0 end}
  function buffer.create(size) local b={__buf=true,n=math.floor(size),d={}}
    for i=0,b.n-1 do b.d[i]=0 end return setmetatable(b,meta) end
  function buffer.fromstring(s) local b={__buf=true,n=#s,d={}}
    for i=1,#s do b.d[i-1]=s:byte(i) end return setmetatable(b,meta) end
  function buffer.tostring(b) local t={} for i=0,b.n-1 do t[i+1]=string.char(b.d[i] or 0) end return table.concat(t) end
  function buffer.len(b) return b.n end
  function buffer.readu8(b,o) return b.d[o] or 0 end
  function buffer.readi8(b,o) local v=b.d[o] or 0 if v>=128 then v=v-256 end return v end
  local function rdu(b,o,n) local v=0 for i=0,n-1 do v=v|((b.d[o+i] or 0)<<(8*i)) end return v end
  function buffer.readu16(b,o) return rdu(b,o,2) end
  function buffer.readu32(b,o) return rdu(b,o,4) end
  function buffer.readi16(b,o) local v=rdu(b,o,2) if v>=32768 then v=v-65536 end return v end
  function buffer.readi32(b,o) local v=rdu(b,o,4) if v>=2147483648 then v=v-4294967296 end return v end
  function buffer.readf32(b,o) return (string.unpack and string.unpack("<f",buffer.readstring(b,o,4))) or 0 end
  function buffer.readf64(b,o) return (string.unpack and string.unpack("<d",buffer.readstring(b,o,8))) or 0 end
  function buffer.writeu8(b,o,v) b.d[o]=clamp8(v) end
  buffer.writei8=buffer.writeu8
  local function wru(b,o,v,n) v=math.floor(v) for i=0,n-1 do b.d[o+i]=(v>>(8*i))&0xFF end end
  function buffer.writeu16(b,o,v) wru(b,o,v,2) end
  function buffer.writeu32(b,o,v) wru(b,o,v,4) end
  buffer.writei16=buffer.writeu16 buffer.writei32=buffer.writeu32
  function buffer.writef32(b,o,v) local s=string.pack("<f",v) for i=1,4 do b.d[o+i-1]=s:byte(i) end end
  function buffer.writef64(b,o,v) local s=string.pack("<d",v) for i=1,8 do b.d[o+i-1]=s:byte(i) end end
  function buffer.readstring(b,o,n) local t={} for i=0,n-1 do t[i+1]=string.char(b.d[o+i] or 0) end return table.concat(t) end
  function buffer.writestring(b,o,s,n) n=n or #s for i=1,n do b.d[o+i-1]=s:byte(i) or 0 end end
  function buffer.copy(dst,doff,src,soff,n) soff=soff or 0 n=n or src.n for i=0,n-1 do dst.d[doff+i]=src.d[soff+i] or 0 end end
  function buffer.fill(b,o,v,n) n=n or (b.n-o) for i=0,n-1 do b.d[o+i]=clamp8(v) end end
end
