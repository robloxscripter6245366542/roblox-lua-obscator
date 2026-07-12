-- Regression corpus: {name, source} pairs exercising language features.
return {
  { 'literals', 'print(1, 2.5, "hi", true, false, nil)' },
  { 'arith', 'print(1+2, 10-3, 4*5, 20/4, 2^10, 17%5, 17//5)' },
  { 'unary', 'print(-5, not true, not nil, #"abcd", #({1,2,3}))' },
  { 'compare', 'print(1<2, 2<=2, 3>1, 3>=4, 1==1, 1~=2, "a"<"b")' },
  { 'logic', 'print(true and 1, false and 1, nil or 5, 3 or 4, false or nil)' },
  { 'concat', 'print("a".."b".."c", 1 .. 2, "x" .. 3.5)' },
  { 'locals', 'local a,b,c = 1,2 print(a,b,c) local x = a+b print(x)' },
  { 'multiassign', 'local a,b = 1,2 a,b = b,a print(a,b)' },
  { 'if', 'local x=5 if x>3 then print("big") elseif x>1 then print("mid") else print("small") end' },
  { 'while', 'local i=0 local s=0 while i<5 do i=i+1 s=s+i end print(s)' },
  { 'repeat', 'local i=0 repeat i=i+1 until i>=3 print(i)' },
  { 'numfor', 'local s=0 for i=1,10 do s=s+i end print(s)' },
  { 'numfor-step', 'local t={} for i=10,1,-2 do t[#t+1]=i end print(table.concat(t,","))' },
  { 'genfor-ipairs', 'local t={"a","b","c"} for i,v in ipairs(t) do print(i,v) end' },
  { 'genfor-pairs', 'local t={x=1} local k,v for kk,vv in pairs(t) do k,v=kk,vv end print(k,v)' },
  { 'func', 'local function add(a,b) return a+b end print(add(3,4))' },
  { 'recursion', 'local function fib(n) if n<2 then return n end return fib(n-1)+fib(n-2) end print(fib(10))' },
  { 'closure', 'local function c() local n=0 return function() n=n+1 return n end end local f=c() print(f(),f(),f())' },
  { 'closure-share', 'local function pair() local x=0 return function() x=x+1 return x end, function() return x end end local inc,get=pair() inc() inc() print(get())' },
  { 'varargs', 'local function sum(...) local t=0 for _,v in ipairs({...}) do t=t+v end return t end print(sum(1,2,3,4,5))' },
  { 'varargs-select', 'local function f(...) return select("#", ...), select(2, ...) end print(f("a","b","c"))' },
  { 'multiret', 'local function mr() return 1,2,3 end local a,b,c = mr() print(a,b,c) print(mr())' },
  { 'multiret-mid', 'local function mr() return 1,2 end print(mr(), 99)' },
  -- Note: a constructor with a conflicting positional+keyed index (e.g. {20,[2]=9})
  -- resolves differently on Lua 5.4 vs Luau; real code avoids it. Use distinct keys.
  { 'table-ctor', 'local t={10,20,30,x="y",[5]=99} print(t[1],t[2],t[3],t.x,t[5])' },
  { 'table-nested', 'local t={a={b={c=42}}} print(t.a.b.c)' },
  { 'method', 'local o={n=7} function o:get() return self.n end print(o:get())' },
  { 'method-args', 'local o={} function o:add(a,b) return a+b end print(o:add(10,20))' },
  { 'metatable-index', 'local base={greet=function() return "hi" end} local t=setmetatable({}, {__index=base}) print(t.greet())' },
  { 'metatable-add', 'local mt={__add=function(a,b) return a.v+b.v end} local x=setmetatable({v=3},mt) local y=setmetatable({v=4},mt) print(x+y)' },
  { 'string-methods', 'print(("hello"):upper(), ("WORLD"):lower(), ("%d-%d"):format(3,4))' },
  { 'nested-func', 'local function outer(x) local function inner(y) return x+y end return inner(10) end print(outer(5))' },
  { 'shadow', 'local x=1 do local x=2 do local x=3 print(x) end print(x) end print(x)' },
  { 'pcall', 'local ok,err = pcall(function() error("boom") end) print(ok, tostring(err):match("boom"))' },
  { 'and-or-chain', 'local a=nil local b=a and a.x or "default" print(b)' },
  { 'bitwise', 'print(5 & 3, 5 | 2, 5 ~ 1, 1 << 4, 256 >> 2)' },
  { 'coroutine', 'local co=coroutine.wrap(function() for i=1,3 do coroutine.yield(i*10) end end) print(co(),co(),co())' },
  { 'coroutine-resume', 'local c=coroutine.create(function(a) local b=coroutine.yield(a+1) return b*2 end) print(coroutine.resume(c,10)) print(coroutine.resume(c,5))' },
  { 'meta-call', 'local t=setmetatable({}, {__call=function(self,x) return x+1 end}) print(t(41))' },
  { 'meta-newindex', 'local log={} local t=setmetatable({}, {__newindex=function(tb,k,v) log[#log+1]=k.."="..tostring(v) end}) t.a=1 t.b=2 print(table.concat(log,","))' },
  { 'meta-eq-lt', 'local mt={__eq=function() return true end,__lt=function(a,b) return a.v<b.v end} local x=setmetatable({v=1},mt) local y=setmetatable({v=2},mt) print(x==y, x<y, y<x)' },
  { 'table-sort', 'local t={3,1,4,1,5,9,2,6} table.sort(t, function(a,b) return a>b end) print(table.concat(t,","))' },
  { 'closure-per-iter', 'local fns={} for i=1,3 do fns[i]=function() return i end end print(fns[1](),fns[2](),fns[3]())' },
  { 'upvalue-mutate-loop', 'local total=0 local add=function(x) total=total+x end for i=1,5 do add(i) end print(total)' },
  { 'nested-upvalue', 'local function a() local x=1 return function() local function b() x=x+1 return x end return b end end print(a()()(), a()()())' },
  { 'string-gsub', 'local s=("hello world"):gsub("o","0") print(s)' },
  { 'deep-recursion', 'local function sum(n) if n==0 then return 0 end return n+sum(n-1) end print(sum(100))' },
  { 'mixed', [[
local function map(t, f)
  local r = {}
  for i, v in ipairs(t) do r[i] = f(v) end
  return r
end
local sq = map({1,2,3,4}, function(x) return x*x end)
print(table.concat(sq, ","))
]] },
}
