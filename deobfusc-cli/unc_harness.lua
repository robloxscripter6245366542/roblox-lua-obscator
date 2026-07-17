
-- ── VM shims (table.create / bit32 / getfenv-setfenv / string.pack) ─────────
if not unpack then unpack = table.unpack end
if not string.pack then string.pack=function(fmt,n) if fmt==">I4" then n=math.floor(n)%4294967296
  return string.char(math.floor(n/16777216)%256,math.floor(n/65536)%256,math.floor(n/256)%256,n%256) end
  error("pack "..tostring(fmt)) end end
if not bit32 then local function _i(v) if type(v)=='boolean' then return v and 1 or 0 end
  if type(v)=='number' then return math.tointeger(v) or (v>=0 and math.floor(v) or math.ceil(v)) end return 0 end
  bit32={band=function(...) local r=0xFFFFFFFF for _,v in ipairs({...}) do r=r&_i(v) end return r end,
  bor=function(...) local r=0 for _,v in ipairs({...}) do r=r|_i(v) end return r end,
  bxor=function(...) local r=0 for _,v in ipairs({...}) do r=r~_i(v) end return r end,
  bnot=function(a) return (~_i(a))&0xFFFFFFFF end, lshift=function(a,b) return (_i(a)<<_i(b))&0xFFFFFFFF end,
  rshift=function(a,b) return (_i(a)>>_i(b))&0xFFFFFFFF end,
  arshift=function(a,b) a=_i(a) b=_i(b) if a>=0x80000000 then a=a-0x100000000 end return a>>b end,
  lrotate=function(a,b) a=_i(a)&0xFFFFFFFF b=_i(b)%32 return ((a<<b)|(a>>(32-b)))&0xFFFFFFFF end,
  rrotate=function(a,b) a=_i(a)&0xFFFFFFFF b=_i(b)%32 return ((a>>b)|(a<<(32-b)))&0xFFFFFFFF end,
  countlz=function(a) a=_i(a)&0xFFFFFFFF if a==0 then return 32 end local c=0 while a<0x80000000 do c=c+1 a=a<<1 end return c end,
  countrz=function(a) a=_i(a)&0xFFFFFFFF if a==0 then return 32 end local c=0 while (a&1)==0 do c=c+1 a=a>>1 end return c end,
  extract=function(a,f,w) w=w or 1 return (_i(a)>>_i(f))&((1<<w)-1) end,
  replace=function(a,v,f,w) w=w or 1 local mm=(1<<w)-1 return (_i(a)&~(mm<<_i(f)))|((_i(v)&mm)<<_i(f)) end,
  test=function(a,b) return (_i(a)&_i(b))~=0 end} end
if not table.create then table.create=function(n,v) local t={} if v~=nil then for i=1,n do t[i]=v end end return t end end
if not table.clear then table.clear=function(t) for k in pairs(t) do t[k]=nil end end end
if not table.find then table.find=function(t,val,i) for j=(i or 1),#t do if t[j]==val then return j end end end end
if not table.freeze then table.freeze=function(t) return t end end
if not table.isfrozen then table.isfrozen=function() return false end end
function getfenv(f) if f==nil then f=1 end if type(f)=="number" then local i=debug.getinfo(f+1,"f") f=i and i.func end
  if type(f)~="function" then return _G end local i=1 while true do local n,v=debug.getupvalue(f,i)
  if n=="_ENV" then return v end if not n then return _G end i=i+1 end end
function setfenv(f,env) if type(f)=="number" then if f==0 then return end local i=debug.getinfo(f+1,"f") f=i and i.func end
  if type(f)~="function" then return f end local i=1 while true do local n=debug.getupvalue(f,i)
  if n=="_ENV" then debug.upvaluejoin(f,i,function() return env end,1) return f end if not n then return f end i=i+1 end end

-- ── capture: loadstring layers ──────────────────────────────────────────────
local _ls=load; local _n=0
local function hook(s,name,...) if type(s)~="string" or #s<4 then return function() end end
  _n=_n+1; local fh=io.open("{WORK}/layer_".._n..".bin","wb") if fh then fh:write(s) fh:close() end
  if s:byte(1)==0x1b then return function() end end
  local code=s if #s>80000 then local vf=io.open("{VMFIX}","rb") if vf then code=vf:read("*a") vf:close() end end
  local fn=_ls(code,name or ("=l".._n)) return fn or function() end end
load=hook; loadstring=hook

-- ── capture: decoded blobs (byte readers) + decrypted strings ───────────────
do local seen={}
  local function blob(s) if type(s)=="string" and #s>256 and not seen[#s] then seen[#s]=true
    local f=io.open("{WORK}/blob_"..#s..".bin","wb") if f then f:write(s) f:close() end end end
  local ob=string.byte; string.byte=function(s,i,j) blob(s) return ob(s,i,j) end
  local ou=string.unpack; if ou then string.unpack=function(f,s,p) blob(s) return ou(f,s,p) end end
  local sf=io.open("{WORK}/strings.txt","w"); local ss={}
  local function rec(s) if type(s)=="string" and #s>=4 and #s<6000 and not ss[s] then
    local L,P=0,0 for i=1,#s do local b=s:byte(i) if b>=32 and b<127 then P=P+1
      if (b>=65 and b<=90) or (b>=97 and b<=122) then L=L+1 end end end
    if P>=#s*0.85 and L>=2 then ss[s]=true sf:write(s.."\n") sf:flush() end end end
  local oc=string.char; string.char=function(...) local r=oc(...) rec(r) return r end
  local ocat=table.concat; table.concat=function(t,a,b,c) local r=ocat(t,a,b,c) rec(r) return r end
  local osu=string.sub; string.sub=function(s,a,b) local r=osu(s,a,b) rec(r) return r end
  local og=string.gsub; string.gsub=function(s,p,r2,n) local r,c= og(s,p,r2,n) rec(r) return r,c end
end

-- ── HTTP capture (used by unc_env service handlers) ─────────────────────────
local _http=io.open("{WORK}/http.txt","w")
__UNC_ONHTTP = function(tag,a,b)
  local line="[HTTP "..tag.."] "..tostring(a)..(b and (" :: "..tostring(b)) or "")
  io.stderr:write(line.."\n") if _http then _http:write(line.."\n") _http:flush() end
end

-- ── load the UNC executor environment, publish as globals ───────────────────
__UNC_ENV_SRC = [==[]==]  -- placeholder
local UNC = (function() {UNC_ENV} end)()
UNC.onhttp = __UNC_ONHTTP
game=UNC.game; workspace=UNC.workspace; Instance=UNC.Instance; Enum=UNC.Enum
Vector3=UNC.Vector3; Vector2=UNC.Vector2; UDim=UNC.UDim; UDim2=UNC.UDim2; Color3=UNC.Color3
CFrame=UNC.CFrame; TweenInfo=UNC.TweenInfo; NumberRange=UNC.NumberRange; Rect=UNC.Rect
ColorSequence=UNC.ColorSequence; NumberSequence=UNC.NumberSequence
ColorSequenceKeypoint=UNC.ColorSequenceKeypoint; NumberSequenceKeypoint=UNC.NumberSequenceKeypoint
BrickColor=UNC.BrickColor; Font=UNC.Font; Ray=UNC.Ray; PhysicalProperties=UNC.PhysicalProperties

-- ── UNC function set ────────────────────────────────────────────────────────
function typeof(x) local t=type(x) if t=="table" then return x.__type or "Instance" end return t end
typeof=typeof
identifyexecutor=function() return "Synapse X","2.0" end; getexecutorname=identifyexecutor
iscclosure=function() return false end; islclosure=function() return true end
isexecutorclosure=function() return true end; checkcaller=function() return true end
newcclosure=function(f) return f end; clonefunction=function(f) return f end
hookfunction=function(a,b) return b end; hookmetamethod=function() return function() end end
getrawmetatable=function(o) return getmetatable(o) or {} end
setrawmetatable=function(o,m) return o end; setreadonly=function() end; isreadonly=function() return false end
getnamecallmethod=function() return "" end; setnamecallmethod=function() end
getgenv=function() return _G end; getrenv=function() return _G end; getsenv=function() return {} end
getreg=function() return {} end; getgc=function() return {} end; getinstances=function() return {} end
getnilinstances=function() return {} end; getconnections=function() return {} end
gethui=function() return Instance.new("ScreenGui") end; cloneref=function(o) return o end
compareinstances=function(a,b) return a==b end; fireclickdetector=function() end
firetouchinterest=function() end; fireproximityprompt=function() end
firesignal=function() end; getcallbackvalue=function() return nil end
setclipboard=function(s) __UNC_ONHTTP("setclipboard", s) end; toclipboard=setclipboard
queue_on_teleport=function() end; getscriptbytecode=function() return "" end
getscriptclosure=function() return function() end end; decompile=function() return "-- decompile unavailable" end
request=function(o) __UNC_ONHTTP("request", o and o.Url) return {Success=true,StatusCode=200,Body="{}",Headers={}} end
http={request=request}; http_request=request; syn={request=request,protect_gui=function() end,crypt={}}
crypt={base64encode=function(s) return s end, base64decode=function(s) return s end,
  base64={encode=function(s) return s end, decode=function(s) return s end},
  encrypt=function(s) return s end, decrypt=function(s) return s end,
  generatebytes=function() return "" end, generatekey=function() return "" end, hash=function() return "" end}
base64_encode=function(s) return s end; base64_decode=function(s) return s end
readfile=function() return "" end; writefile=function() end; appendfile=function() end
isfile=function() return false end; isfolder=function() return false end; makefolder=function() end
delfile=function() end; delfolder=function() end; listfiles=function() return {} end
loadfile=function() return function() end end; dofile=function() end
Drawing=setmetatable({new=function() return setmetatable({Remove=function() end,Destroy=function() end},
  {__index=function() return 0 end,__newindex=function() end}) end, Fonts={}},{__index=function() return function() end end})
WebSocket={connect=function() return setmetatable({Send=function() end,Close=function() end,
  OnMessage=UNC.newSignal(nil,"OnMessage"),OnClose=UNC.newSignal(nil,"OnClose")},{}) end}
debug=debug or {}
debug.getupvalue=debug.getupvalue or function() return nil end
debug.getupvalues=function() return {} end; debug.setupvalue=debug.setupvalue or function() end
debug.getconstant=function() return nil end; debug.getconstants=function() return {} end
debug.setconstant=function() end; debug.getproto=function() return function() end end
debug.getprotos=function() return {} end; debug.getstack=function() return {} end
debug.setstack=function() end; debug.getregistry=function() return {} end
cache={invalidate=function() end, iscached=function() return true end, replace=function() end}
Random=setmetatable({new=function(seed) return setmetatable({
  NextInteger=function(_,a,b) a=a or 0 b=b or 1 return math.random(math.floor(a),math.floor(b)) end,
  NextNumber=function(_,a,b) if a then return a+(b-a)*math.random() end return math.random() end,
  NextUnitVector=function() return Vector3.new(0,1,0) end,
  Clone=function(s2) return s2 end, Shuffle=function() end},{}) end},{__call=function() return Random.new() end})

-- ── task / scheduler + UI DRIVER ────────────────────────────────────────────
-- A render/animation loop yields via task.wait OR Signal:Wait (RenderStepped /
-- Heartbeat). BOTH route through __TICK so the driver fires the verify button
-- regardless of which yield the hub uses, then forces the loop's exit flags.
local _w=0; local _round=0
local function drive()
  if _w==40 or (_w>40 and _w%400==0) then
    _round=_round+1
    io.stderr:write("[unc] driver round "..(_round)..": firing "..#UNC.clicks.." button signal(s)\n")
    for _,sig in ipairs(UNC.clicks) do pcall(function() sig:Fire() end) pcall(function() sig:Fire(true) end) end
    -- also flip common exit flags so the render loop can terminate
    getgenv().UI_CLOSED=true; getgenv().SCRIPT_KEY=getgenv().SCRIPT_KEY or "KEYLESS"
    getgenv().Verified=true; getgenv().keySystem=false
  end
end
__TICK=function() _w=_w+1 drive() if _w>4000 then error("[unc] budget",0) end end
local function tick(n) __TICK() return n or 0 end
wait=tick; spawn=function(f,...) if type(f)=="function" then pcall(f,...) end return f end
delay=function(_,f,...) if type(f)=="function" then pcall(f,...) end end
task={wait=tick, spawn=spawn, delay=function(_,f,...) if type(f)=="function" then pcall(f,...) end end,
  defer=function(f,...) if type(f)=="function" then pcall(f,...) end return f end, cancel=function() end}
getgenv().UI_CLOSED=false; shared={}; _G.shared=shared
script=Instance.new("LocalScript")

-- universal fallback for anything still undefined
do local U; local mt={__index=function() return U end,__call=function() return U end,
  __newindex=function() end,__tostring=function() return "" end,__concat=function() return "" end,
  __len=function() return 0 end,__add=function() return 0 end,__sub=function() return 0 end,
  __mul=function() return 0 end,__div=function() return 0 end,__mod=function() return 0 end,
  __pow=function() return 0 end,__unm=function() return 0 end,__eq=function() return false end,
  __lt=function() return false end,__le=function() return false end}; U=setmetatable({},mt)
  setmetatable(_G,{__index=function(_,k) if type(k)=="string" then
    local f=io.open("{WORK}/globals.txt","a") if f then f:write(k.."\n") f:close() end end return U end})
end
