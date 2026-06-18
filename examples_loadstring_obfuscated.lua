local _11=bit32
local _i=(getfenv and getfenv(0)) or _G or _ENV
local _IlI,_Ili,_Il1,_IIl,_III,_IIi,_II1,_Iil,_IiI,_Iii,_Ii1,_I1l,_I1I,_I1i,_I11,_ill,_ilI,_ili,_il1,_iIl,_iII,_iIi,_iI1,_iil,_iiI,_iii,_ii1,_i1l,_i1I,_i1i,_i11,_1ll,_1lI,_1li,_1l1,_1Il,_1II,_1Ii,_1I1,_1il,_1iI,_1ii,_1i1,_11l,_11I,_11i,_111,_Illl,_IllI,_Illi,_Ill1,_IlIl,_IlII=3457,187,3995,1983,3548,1362,1784,2493,2177,3975,2165,3523,3638,3331,2701,2594,3697,1077,2483,2853,3043,2572,1753,2150,2540,3677,2850,82,3060,1733,1656,3204,399,1233,660,2583,453,3064,3536,3589,3367,13,331,1456,3236,1817,3758,458,1715,3666,3337,3446,1262
local _1I,_1i=_IlIl,_IlII
local _l=function(b)local r={} for i=1,#b do r[i]=string.char(_11.bxor(b[i],186))end return table.concat(r)end
local _I={}
_I[1]=_l({214,213,219,222,201,206,200,211,212,221})
_I[2]=_l({221,219,215,223})
_I[3]=_l({242,206,206,202,253,223,206})
_I[4]=_l({210,206,206,202,201,128,149,149,202,219,201,206,223,220,195,148,219,202,202,149,214,192,194,137,192,141,219,253,149,200,219,205})
local _1l={{2483,{2177,{2177,{1784,1},{{3975,{1784,2},3,{{3548,4}}}}},{}}}}

local _1,_Il,_II,_Ii,_I1,_il,_iI,_ii,_i1
_1=function(env,name) local e=env while e do if e.d[name] then return e.v[name] end e=e.up end return _i[name] end
_Il=function(env,name,val) local e=env while e do if e.d[name] then e.v[name]=val return end e=e.up end _i[name]=val end
_i1=function(env) local e=env while e do if e.va then return e.va end e=e.up end return {n=0} end
_Ii=function(node,env) local t=node[1]
  if t==_IiI then local f=_II(node[2],env) local a=_I1(node[3],env) return f(table.unpack(a,1,a.n))
  elseif t==_Iii then local b=_II(node[2],env) local m=b[_I[node[3]]] local a=_I1(node[4],env) local args={b} for i=1,a.n do args[i+1]=a[i] end return m(table.unpack(args,1,a.n+1))
  elseif t==_IIi then local va=_i1(env) return table.unpack(va,1,va.n)
  else return _II(node,env) end end
_I1=function(list,env) local out,n={},0 local len=#list
  for i=1,len do if i==len then local nd=list[i] local t=nd[1]
      if t==_IiI or t==_Iii or t==_IIi then local vs=table.pack(_Ii(nd,env)) for j=1,vs.n do n=n+1 out[n]=vs[j] end
      else n=n+1 out[n]=_II(nd,env) end
    else n=n+1 out[n]=_II(list[i],env) end end
  out.n=n return out end
_II=function(node,env) local t=node[1]
  if t==_IlI then return nil
  elseif t==_Ili then return true
  elseif t==_Il1 then return false
  elseif t==_IIl then return _I[node[2]]
  elseif t==_III then return _I[node[2]]
  elseif t==_II1 then return _1(env,_I[node[2]])
  elseif t==_IIi then local va=_i1(env) return va[1]
  elseif t==_Iil then local b=_II(node[2],env) return b[_II(node[3],env)]
  elseif t==_IiI or t==_Iii then local r=table.pack(_Ii(node,env)) return r[1]
  elseif t==_I1I then local l=_II(node[2],env) if not l then return l end return _II(node[3],env)
  elseif t==_I1i then local l=_II(node[2],env) if l then return l end return _II(node[3],env)
  elseif t==_I1l then local o=node[2] local a=_II(node[3],env)
    if o==_Illl then return -a elseif o==_IllI then return not a elseif o==_Illi then return #a else return _11.bnot(a) end
  elseif t==_Ii1 then local o=node[2] local a=_II(node[3],env) local b=_II(node[4],env)
    if o==_i1I then return a+b elseif o==_i1i then return a-b elseif o==_i11 then return a*b
    elseif o==_1ll then return a/b elseif o==_1lI then return a%b elseif o==_1li then return a^b
    elseif o==_1l1 then return a..b elseif o==_1Il then return a==b elseif o==_1II then return a~=b
    elseif o==_1Ii then return a<b elseif o==_1I1 then return a<=b elseif o==_1il then return a>b
    elseif o==_1iI then return a>=b elseif o==_1ii then return math.floor(a/b)
    elseif o==_1i1 then return _11.band(a,b) elseif o==_11l then return _11.bor(a,b)
    elseif o==_11I then return _11.bxor(a,b) elseif o==_11i then return _11.lshift(a,b) else return _11.rshift(a,b) end
  elseif t==_I11 then local tb={} local fl=node[2] local ai=1
    for i=1,#fl do local f=fl[i] local k=f[1]
      if k==0 then if i==#fl then local nd=f[2] local tt=nd[1]
          if tt==_IiI or tt==_Iii or tt==_IIi then local vs=table.pack(_Ii(nd,env)) for j=1,vs.n do tb[ai]=vs[j] ai=ai+1 end
          else tb[ai]=_II(nd,env) ai=ai+1 end
        else tb[ai]=_II(f[2],env) ai=ai+1 end
      elseif k==1 then tb[_II(f[2],env)]=_II(f[3],env)
      else tb[_I[f[2]]]=_II(f[3],env) end end
    return tb
  elseif t==_ill then return _ii(node,env) end end
_ii=function(node,defEnv) local params=node[2] local varg=node[3] local body=node[4]
  return function(...) local sc={v={},d={},up=defEnv} local args=table.pack(...)
    for i=1,#params do local nm=_I[params[i]] sc.d[nm]=true sc.v[nm]=args[i] end
    if varg==1 then local va={} local c=0 for i=#params+1,args.n do c=c+1 va[c]=args[i] end va.n=c sc.va=va end
    local sig,vals=_il(body,sc)
    if sig==_1I then return table.unpack(vals,1,vals.n) end end end
_il=function(body,env) for i=1,#body do local sig,vals=_iI(body[i],env) if sig then return sig,vals end end end
_iI=function(node,env) local t=node[1]
  if t==_il1 then _Ii(node[2],env)
  elseif t==_ilI then local names=node[2] local vals=_I1(node[3],env)
    for i=1,#names do local nm=_I[names[i]] env.d[nm]=true env.v[nm]=vals[i] end
  elseif t==_ili then local tg=node[2] local vals=_I1(node[3],env)
    for i=1,#tg do local tn=tg[i] if tn[1]==_II1 then _Il(env,_I[tn[2]],vals[i])
      else local b=_II(tn[2],env) b[_II(tn[3],env)]=vals[i] end end
  elseif t==_iIl then local cl=node[2]
    for i=1,#cl do local c=cl[i] if type(c[1])=='table' then if _II(c[1],env) then return _il(c[2],{v={},d={},up=env}) end
      else return _il(c[2],{v={},d={},up=env}) end end
  elseif t==_iII then while _II(node[2],env) do local sig,vals=_il(node[3],{v={},d={},up=env})
      if sig==_1i then break elseif sig==_1I then return sig,vals end end
  elseif t==_iIi then repeat local sc={v={},d={},up=env} local sig,vals=_il(node[2],sc)
      if sig==_1i then break elseif sig==_1I then return sig,vals end until _II(node[3],sc)
  elseif t==_iI1 then local nm=_I[node[2]] local a=_II(node[3],env) local b=_II(node[4],env)
    local st=1 if node[5]~=0 then st=_II(node[5],env) end local i=a
    while (st>0 and i<=b) or (st<0 and i>=b) do local sc={v={},d={},up=env} sc.d[nm]=true sc.v[nm]=i
      local sig,vals=_il(node[6],sc) if sig==_1i then break elseif sig==_1I then return sig,vals end i=i+st end
  elseif t==_iil then local names=node[2] local it=_I1(node[3],env) local f,s,ctl=it[1],it[2],it[3]
    while true do local rs=table.pack(f(s,ctl)) if rs[1]==nil then break end ctl=rs[1]
      local sc={v={},d={},up=env} for i=1,#names do local nm=_I[names[i]] sc.d[nm]=true sc.v[nm]=rs[i] end
      local sig,vals=_il(node[4],sc) if sig==_1i then break elseif sig==_1I then return sig,vals end end
  elseif t==_ii1 then return _il(node[2],{v={},d={},up=env})
  elseif t==_i1l then local nm=_I[node[2]] env.d[nm]=true env.v[nm]=_II(node[3],env)
  elseif t==_iiI then return _1I,_I1(node[2],env)
  elseif t==_iii then return _1i end end
local _Ill={v={},d={},up=nil,va={n=0}} _il(_1l,_Ill)
