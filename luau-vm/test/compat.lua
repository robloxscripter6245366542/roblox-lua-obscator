-- luau-vm/test/compat.lua
-- Language-compatibility suite: hundreds of differential cases. Each case is run
-- three ways — native (host load), VM (direct), VM (serialize→deserialize) —
-- and their results must all agree. Covers the surface a real Luau program uses:
-- closures/upvalues, recursion (incl. deep), metatables (__index/__newindex/
-- __call/__len/__add/__eq/__lt/__concat/__unm), pcall/xpcall, coroutines,
-- numeric/generic for, varargs, multiple returns, tail calls, select, large
-- constant tables, deep nesting. A final section proves Roblox-style globals
-- (Instance.new, task.wait, Vector3) pass through to the host environment.
--
--   lua5.4 test/compat.lua

package.path = 'src/?.lua;' .. package.path
local API = require('api')
-- Luau ships bit32; lua5.4 does not. Inject the VM's own bitops (same 32-bit
-- semantics Luau uses) so bit32.* cases run identically on both host and VM.
local bit32compat = require('bitops')

-- ── result capture / comparison ──────────────────────────────────────────────
local function fmtScalar(v)
  local t = type(v)
  if t == 'number' then return string.format('%.17g', v)
  elseif t == 'string' then return string.format('%q', v)
  elseif t == 'boolean' then return tostring(v)
  elseif t == 'nil' then return 'nil'
  elseif t == 'function' then return '<fn>'
  else return '<' .. t .. '>' end
end
-- stable structural dump (ignores identity + metatables) so returned tables compare
local function dump(v, d)
  if type(v) ~= 'table' or d <= 0 then return fmtScalar(v) end
  local keys = {}
  for k in pairs(v) do keys[#keys + 1] = k end
  table.sort(keys, function(a, b) return tostring(a) < tostring(b) end)
  local parts = {}
  for _, k in ipairs(keys) do parts[#parts + 1] = tostring(k) .. '=' .. dump(v[k], d - 1) end
  return '{' .. table.concat(parts, ',') .. '}'
end

local function baseEnv(extra)
  local env = setmetatable({ bit32 = rawget(_G, 'bit32') or bit32compat }, { __index = _G })
  if extra then for k, v in pairs(extra) do env[k] = v end end
  return env
end

-- run a chunk, capture returns (or a position-stripped error) as one string
local function capNative(src, env)
  local f, err = load(src, 'c', 't', env)
  if not f then return 'LOADERR:' .. tostring(err) end
  local p = table.pack(pcall(f))
  if not p[1] then return 'ERR:' .. (tostring(p[2]):gsub('^.-:%d+: ', '')) end
  local out = {}
  for i = 2, p.n do out[i - 1] = dump(p[i], 6) end
  return table.concat(out, '\30')
end
local function capVM(src, env, serialized)
  local ok, protoOrErr = pcall(API.compile, src, 'c')
  if not ok then return 'COMPILEERR:' .. tostring(protoOrErr) end
  local proto = protoOrErr
  if serialized then proto = API.Serializer.deserialize(API.Serializer.serialize(proto)) end
  local p = table.pack(pcall(API.VM.load(proto, env)))
  if not p[1] then return 'ERR:' .. (tostring(p[2]):gsub('^.-:%d+: ', '')) end
  local out = {}
  for i = 2, p.n do out[i - 1] = dump(p[i], 6) end
  return table.concat(out, '\30')
end

local pass, fail = 0, 0
local firstFails = {}
local function case(name, src, env)
  env = env or baseEnv()
  -- fresh env per run so cross-run mutation can't leak
  local nat = capNative(src, baseEnvClone(env))
  local vm = capVM(src, baseEnvClone(env), false)
  local vms = capVM(src, baseEnvClone(env), true)
  if nat == vm and nat == vms then
    pass = pass + 1
  else
    fail = fail + 1
    if #firstFails < 8 then
      firstFails[#firstFails + 1] = string.format('%s\n   native=%s\n   vm    =%s\n   vmser =%s', name, nat, vm, vms)
    end
  end
end

-- shallow clone of an env table (so each of the 3 runs gets its own globals)
function baseEnvClone(env)
  local c = setmetatable({}, getmetatable(env))
  for k, v in pairs(env) do c[k] = v end
  return c
end

-- ── curated cases ─────────────────────────────────────────────────────────────
-- closures / upvalues
case('closure-counter', 'local function mk() local n=0 return function() n=n+1 return n end end local c=mk() return c(),c(),c()')
case('nested-closures', [[
local function outer(a) return function(b) return function(c) return a+b+c end end end
return outer(1)(2)(3)]])
case('shared-upvalue', [[
local function pair() local v=0 local function g() return v end local function s(x) v=x end return g,s end
local g,s=pair() s(42) return g()]])
case('per-iteration-capture', [[
local fns={} for i=1,3 do fns[i]=function() return i end end
return fns[1](),fns[2](),fns[3]()]])
case('upvalue-mutation-loop', [[
local t={} local sum=0 for i=1,4 do t[i]=function() sum=sum+i return sum end end
return t[1](),t[2](),t[3](),t[4]()]])

-- recursion
case('mutual-recursion', [[
local function isEven(n) if n==0 then return true else return isOdd(n-1) end end
function isOdd(n) if n==0 then return false else return isEven(n-1) end end
return isEven(10), isOdd(7)]])
case('ackermann-small', [[
local function ack(m,n) if m==0 then return n+1 elseif n==0 then return ack(m-1,1) else return ack(m-1,ack(m,n-1)) end end
return ack(2,3)]])

-- metatables
case('meta-index-table', 'local base={greet="hi"} local t=setmetatable({},{__index=base}) return t.greet')
case('meta-index-fn', 'local t=setmetatable({},{__index=function(_,k) return k.."!" end}) return t.abc')
case('meta-newindex', [[
local store={} local t=setmetatable({},{__newindex=function(_,k,v) store[k]=v*2 end})
t.x=5 return store.x, rawget(t,"x")]])
case('meta-call', 'local t=setmetatable({},{__call=function(self,a,b) return a*b end}) return t(6,7)')
case('meta-len', 'local t=setmetatable({},{__len=function() return 99 end}) return #t')
case('meta-add-eq-lt', [[
local V={} V.__index=V
V.__add=function(a,b) return setmetatable({x=a.x+b.x},V) end
V.__eq=function(a,b) return a.x==b.x end
V.__lt=function(a,b) return a.x<b.x end
local function n(x) return setmetatable({x=x},V) end
local s=n(3)+n(4) return s.x, n(5)==n(5), n(2)<n(9)]])
case('meta-concat-unm', [[
local V=setmetatable({v="A"},{__concat=function(a,b) return "cat" end,__unm=function() return "neg" end})
return (V.."x"), (-V)]])
case('meta-tostring', 'local t=setmetatable({},{__tostring=function() return "CUSTOM" end}) return tostring(t)')
case('rawequal-rawlen', 'local t={1,2,3} return rawequal(t,t), rawlen(t), rawlen("abcd")')

-- pcall / xpcall / error
case('pcall-success', 'return pcall(function() return 1,2,3 end)')
-- error messages embed a source position that legitimately differs between host
-- and VM (the VM doesn't map bytecode back to source lines — a documented
-- limitation), so these cases strip the "file:line: " prefix and assert the
-- error *value* propagates correctly.
case('pcall-error', 'local ok,e=pcall(function() error("boom") end) return ok, (tostring(e):gsub("^.-:%d+: ",""))')
case('pcall-error-table', 'local ok,e=pcall(function() error({code=42}) end) return ok, e.code')
case('xpcall-handler', 'local ok,e=xpcall(function() error("x") end, function(m) return "handled" end) return ok,e')
case('error-level0', 'local ok,e=pcall(function() error("nolvl",0) end) return ok,e')
case('nested-pcall', [[
local ok,e=pcall(function()
  local ok2=pcall(function() error("inner") end)
  if not ok2 then error("outer") end
end)
return ok, (tostring(e):gsub("^.-:%d+: ",""))]])
case('assert-pass-fail', 'local ok,e=pcall(function() assert(1==1,"ok") assert(false,"failmsg") end) return ok, (tostring(e):gsub("^.-:%d+: ",""))')

-- coroutines
case('coroutine-basic', [[
local co=coroutine.create(function(a) local b=coroutine.yield(a+1) return b*2 end)
local _,r1=coroutine.resume(co,10)
local _,r2=coroutine.resume(co,5)
return r1,r2,coroutine.status(co)]])
case('coroutine-wrap', [[
local gen=coroutine.wrap(function() for i=1,3 do coroutine.yield(i*i) end end)
return gen(),gen(),gen()]])
case('coroutine-producer', [[
local function producer() return coroutine.wrap(function() coroutine.yield("a") coroutine.yield("b") end) end
local p=producer() local out={} for v in p do out[#out+1]=v end return table.concat(out,",")]])

-- for loops
case('numeric-for-step', 'local s=0 for i=10,1,-2 do s=s+i end return s')
case('numeric-for-float', 'local s=0 for i=0,1,0.25 do s=s+i end return s')
case('generic-for-pairs', [[
local t={a=1,b=2,c=3} local sum=0 for k,v in pairs(t) do sum=sum+v end return sum]])
case('generic-for-ipairs', 'local t={5,10,15} local s=0 for i,v in ipairs(t) do s=s+i*v end return s')
case('generic-for-custom', [[
local function range(n) local i=0 return function() i=i+1 if i<=n then return i end end end
local s=0 for x in range(5) do s=s+x end return s]])
case('nested-loops', 'local c=0 for i=1,5 do for j=1,5 do if (i+j)%2==0 then c=c+1 end end end return c')

-- varargs / multiple returns / select
case('varargs-count', 'local function f(...) return select("#",...) end return f(1,nil,3,nil)')
case('varargs-sum', 'local function f(...) local s=0 for _,v in ipairs({...}) do s=s+v end return s end return f(1,2,3,4,5)')
case('select-index', 'return select(2, "a","b","c","d")')
case('multiple-returns-spread', [[
local function two() return 10,20 end
local function sum(...) local s=0 for _,v in ipairs({...}) do s=s+v end return s end
return sum(two(), two()), (two())]])
case('table-pack-unpack', 'local t=table.pack(1,2,3) return t.n, table.unpack(t)')
case('vararg-forward', [[
local function inner(...) return select("#",...), ... end
local function outer(...) return inner(...) end
return outer("x","y","z")]])

-- tail calls
case('tail-call-loop', [[
local function count(n,acc) if n==0 then return acc end return count(n-1,acc+n) end
return count(50,0)]])

-- strings / numbers
case('string-methods', 'return ("Hello"):lower(), ("ab"):rep(3), ("x,y,z"):gsub(",","-"), #"abc"')
case('string-format', 'return string.format("%d/%s/%.2f/%x", 5, "z", 3.14159, 255)')
case('string-find-match', 'local a,b=string.find("hello world","wor") return a,b, string.match("key=val","(%w+)=(%w+)")')
case('string-byte-char', 'return string.byte("A"), string.char(66,67,68)')
case('number-formats', 'return 0xff, 1e3, 0.5, 3//2, 2^8, 7%3, -7%3')
case('math-lib', 'return math.floor(3.7), math.ceil(3.2), math.abs(-5), math.max(1,9,3), math.min(4,2,8), math.sqrt(16)')
case('tostring-tonumber', 'return tostring(42), tonumber("3.14"), tonumber("ff",16), tonumber("nope")')
case('bit32-ops', 'return bit32.band(12,10), bit32.bor(12,10), bit32.bxor(12,10), bit32.lshift(1,4), bit32.rshift(64,3)')

-- tables
case('table-insert-remove', [[
local t={} table.insert(t,1) table.insert(t,2) table.insert(t,1,0)
local r=table.remove(t) return t[1],t[2],t[3],r]])
case('table-sort-closure', [[
local t={5,2,8,1,9,3} table.sort(t,function(a,b) return a>b end)
return table.concat(t,",")]])
case('table-concat', 'return table.concat({1,2,3,4},"-",2,3)')
case('mixed-table', 'local t={10,20,30,x="a",y="b"} return #t, t.x, t[2]')
case('nested-table-access', 'local t={a={b={c={d=42}}}} return t.a.b.c.d')

-- ── parameterized expansion (drives the count into the hundreds) ──────────────
-- fib for many n
for n = 0, 30 do
  case('fib-' .. n, string.format(
    'local function f(x) if x<2 then return x end return f(x-1)+f(x-2) end return f(%d)', n))
end
-- factorial / sum for a range
for n = 1, 40 do
  case('fact-' .. n, string.format(
    'local function f(x) if x<=1 then return 1 end return x*f(x-1) end return f(%d) %% 1000000007', n))
end
for n = 1, 50 do
  case('gauss-' .. n, string.format('local s=0 for i=1,%d do s=s+i end return s', n))
end
-- arithmetic matrix: every operator over many operand pairs (host vs VM must agree
-- on integer//float subtypes, modulo sign, power, etc.)
for a = -4, 4 do
  for b = 1, 5 do
    case(string.format('arith-%d-%d', a, b), string.format(
      'local a,b=%d,%d return a+b,a-b,a*b,a/b,a%%b,a//b,a^b,-a', a, b))
    case(string.format('cmp-%d-%d', a, b), string.format(
      'local a,b=%d,%d return a<b,a<=b,a>b,a>=b,a==b,a~=b', a, b))
  end
end
-- string rep/sub/format over many sizes
for n = 1, 20 do
  case('strrep-' .. n, string.format('local s=("ab"):rep(%d) return #s, s:sub(1,3), s:sub(-2)', n))
end
-- closures producing sequences of varying length
for n = 1, 30 do
  case('seq-' .. n, string.format([[
local function mk() local v=0 return function() v=v+1 return v end end
local c=mk() local out={} for _=1,%d do out[#out+1]=c() end return table.concat(out,",")]], n))
end
-- large constant tables of varying size (constant-pool + SETLIST stress)
for _, sz in ipairs({ 8, 16, 32, 64, 128, 200, 256, 400 }) do
  local items = {}
  for i = 1, sz do items[i] = tostring(i * 3) end
  case('bigtable-' .. sz, 'local t={' .. table.concat(items, ',') .. '} local s=0 for i=1,#t do s=s+t[i] end return s, #t')
end
-- deep expression nesting of varying depth
for _, d in ipairs({ 5, 10, 20, 40, 80 }) do
  local expr = '1'
  for _ = 1, d do expr = '(' .. expr .. '+1)' end
  case('deep-expr-' .. d, 'return ' .. expr)
end
-- deep if/block nesting
for _, d in ipairs({ 4, 8, 16, 32 }) do
  local body, tail = '', ''
  for i = 1, d do body = body .. string.format('if x>=%d then ', i); tail = tail .. ' end' end
  case('deep-if-' .. d, 'local function f(x) local r=0 ' .. body .. 'r=x' .. tail .. ' return r end return f(' .. d .. ')')
end
-- deep table constant nesting
for _, d in ipairs({ 4, 8, 16, 24 }) do
  local open, close = '', ''
  for _ = 1, d do open = open .. '{v='; close = '}' .. close end
  case('deep-tbl-' .. d, 'local t=' .. open .. '7' .. close .. ' local x=t for _=1,' .. d .. ' do x=x.v end return x')
end

-- ── Roblox-API pass-through (host provides globals; VM must forward) ──────────
-- These stub Instance.new / task.wait / Vector3 the way Roblox would provide
-- them; the point is the VM forwards global lookups, field reads, and method
-- calls to the host env unchanged. Both native and VM use the same stubs, so a
-- match proves faithful forwarding (Roblox supplies the real implementations).
local function robloxEnv()
  local Vector3 = {}
  Vector3.__index = Vector3
  Vector3.__add = function(a, b) return setmetatable({ x = a.x + b.x, y = a.y + b.y, z = a.z + b.z }, Vector3) end
  function Vector3.new(x, y, z) return setmetatable({ x = x or 0, y = y or 0, z = z or 0 }, Vector3) end
  function Vector3:Dot(o) return self.x * o.x + self.y * o.y + self.z * o.z end
  -- signal object with :Connect (returns a connection with :Disconnect); :fire is
  -- the test-only loopback that drives connected handlers.
  local function makeSignal()
    local hs = {}
    return {
      Connect = function(_, fn) hs[#hs + 1] = fn; return { Disconnect = function() end } end,
      fire = function(_, ...) for _, h in ipairs(hs) do h(...) end end,
    }
  end
  local Instance = {
    new = function(class)
      local props = { ClassName = class, Name = class }
      if class == 'RemoteEvent' or class == 'BindableEvent' then
        local sig = makeSignal()
        props.OnClientEvent = sig; props.OnServerEvent = sig; props.Event = sig
        props.FireServer = function(_, ...) sig:fire(...) end     -- loopback for test
        props.FireClient = function(_, _plr, ...) sig:fire(...) end
        props.Fire = function(_, ...) sig:fire(...) end
      elseif class == 'RemoteFunction' or class == 'BindableFunction' then
        props.InvokeServer = function(self, ...) return self.OnServerInvoke(...) end
        props.Invoke = function(self, ...) return self.OnInvoke(...) end
      end
      return setmetatable({}, {
        __index = function(_, k) if k == 'Destroy' then return function() props.destroyed = true end end return props[k] end,
        __newindex = function(_, k, v) props[k] = v end,
      })
    end,
  }
  local task = { wait = function(t) return t or 0 end, spawn = function(f, ...) f(...) end }
  return baseEnv({ Vector3 = Vector3, Instance = Instance, task = task })
end
case('roblox-vector3', 'local v=Vector3.new(1,2,3)+Vector3.new(4,5,6) return v.x,v.y,v.z, v:Dot(Vector3.new(2,0,0))', robloxEnv())
case('roblox-instance', 'local p=Instance.new("Part") p.Name="Hello" return p.ClassName, p.Name', robloxEnv())
case('roblox-task-wait', 'local a=task.wait(0.5) local sum=0 task.spawn(function(n) sum=n end, 7) return a, sum', robloxEnv())
case('roblox-mixed', [[
local parts={}
for i=1,5 do local p=Instance.new("Part") p.Name="P"..i p.Position=Vector3.new(i,i*2,i*3) parts[i]=p end
local total=Vector3.new(0,0,0)
for _,p in ipairs(parts) do total=total+p.Position end
return total.x,total.y,total.z, #parts, parts[3].Name]], robloxEnv())

-- remotes / signals: the host calls BACK into VM closures (event handlers,
-- RemoteFunction callbacks). Proves VM functions are real callable values.
case('remote-event-connect', [[
local ev=Instance.new("RemoteEvent")
local total=0
ev.OnClientEvent:Connect(function(a,b) total=total+a*b end)
ev:FireServer(3,4); ev:FireServer(5,6)
return total]], robloxEnv())
case('remote-function-callback', [[
local rf=Instance.new("RemoteFunction")
rf.OnServerInvoke=function(x,y) return x*10+y end
return rf:InvokeServer(5,2)]], robloxEnv())
case('remote-handler-upvalues', [[
local ev=Instance.new("RemoteEvent")
local log={}
local function make(prefix) return function(msg) log[#log+1]=prefix..msg end end
ev.OnClientEvent:Connect(make("got:"))
ev:FireServer("hello"); ev:FireServer("world")
return table.concat(log,",")]], robloxEnv())
case('bindable-event', [[
local be=Instance.new("BindableEvent")
local sum=0
be.Event:Connect(function(n) sum=sum+n end)
for i=1,5 do be:Fire(i) end
return sum]], robloxEnv())
case('remote-multiple-connections', [[
local ev=Instance.new("RemoteEvent")
local a,b=0,0
ev.OnClientEvent:Connect(function(n) a=a+n end)
ev.OnClientEvent:Connect(function(n) b=b+n*2 end)
ev:FireServer(10)
return a,b]], robloxEnv())

-- ── report ────────────────────────────────────────────────────────────────────
print(string.format('compat: %d cases, %d passed, %d failed', pass + fail, pass, fail))
for _, f in ipairs(firstFails) do print('FAIL ' .. f) end
os.exit(fail == 0 and 0 or 1)
