-- luau-vm/test/luau_syntax_test.lua
-- Modern Luau surface syntax that Roblox scripts use heavily but plain Lua 5.4
-- has no notion of: erased type annotations (locals, params, returns, aliases,
-- casts, generics, optionals, typed loops), `continue`, if-then-else
-- expressions, and string interpolation. Reference values are the expected Luau
-- results, checked through the VM directly and via serialize->deserialize.

package.path = 'src/?.lua;' .. package.path
local API = require('api')
local VM = require('vm')
local Ser = require('serializer')

local pass, fail = 0, 0
local function ok(c, m) if c then pass = pass + 1 else fail = fail + 1; print('FAIL ' .. m) end end

local function runVM(src, serialized)
  local out = {}
  local env = setmetatable({ print = function(...)
    local t = {}; for i = 1, select('#', ...) do t[i] = tostring((select(i, ...))) end
    out[#out + 1] = table.concat(t, '\t')
  end }, { __index = _G })
  local proto = API.compile(src)
  if serialized then proto = Ser.deserialize(Ser.serialize(proto)) end
  VM.load(proto, env)()
  return table.concat(out, '\n')
end

local cases = {
  -- type annotations (erased)
  { 'local x: number = 5 print(x)', '5' },
  { 'local a: number, b: string = 1, "z" print(a,b)', '1\tz' },
  { 'local function add(a: number, b: number): number return a+b end print(add(3,4))', '7' },
  { 'local f = function(x: number): number return x*2 end print(f(8))', '16' },
  { 'type Pt = {x: number, y: number} local p: Pt = {x=3,y=4} print(p.x+p.y)', '7' },
  { 'export type Id = string local s: Id = "ok" print(s)', 'ok' },
  { 'local function id<T>(v: T): T return v end print(id(99))', '99' },
  { 'local x = (5 :: any) print(x + 1)', '6' },
  { 'local function g(a: number?): number return a or -1 end print(g(nil), g(7))', '-1\t7' },
  { 'local t: {[string]: number} = {a=2,b=3} local s=0 for k: string, v: number in t do s=s+v end print(s)', '5' },
  { 'local function h(...: number): number local s=0 for _,v in {...} do s=s+v end return s end print(h(1,2,3))', '6' },
  { 'local f: (number)->number = function(x) return x+1 end print(f(10))', '11' },
  -- continue
  { 'local s=0 for i=1,10 do if i%2==0 then continue end s=s+i end print(s)', '25' },
  { 'local i,s=0,0 while i<10 do i=i+1 if i==5 then continue end s=s+i end print(s)', '50' },
  { 'local n,s=0,0 repeat n=n+1 if n==3 then continue end s=s+n until n>=5 print(s)', '12' },
  { 'local s=0 for _,v in {10,20,30,40} do if v==20 then continue end s=s+v end print(s)', '80' },
  { 'local continue = 5 print(continue + 1)', '6' }, -- `continue` as an identifier
  -- if-then-else expression
  { 'local x = if 3>2 then "y" else "n" print(x)', 'y' },
  { 'local n=0 local s = if n<0 then "neg" elseif n==0 then "zero" else "pos" print(s)', 'zero' },
  { 'local a=5 print((if a%2==0 then "even" else "odd"))', 'odd' },
  -- string interpolation
  { 'local w="World" print(`Hello {w}!`)', 'Hello World!' },
  { 'local a,b=3,4 print(`{a}+{b}={a+b}`)', '3+4=7' },
  { 'local t={n=2} print(`n is {t.n}`)', 'n is 2' },
  { 'print(`literal brace \\{ ok`)', 'literal brace { ok' },
  { 'local x=10 print(`x={if x>5 then "big" else "small"}`)', 'x=big' },
}

for i, c in ipairs(cases) do
  local ok1, r1 = pcall(runVM, c[1], false)
  local ok2, r2 = pcall(runVM, c[1], true)
  ok(ok1 and r1 == c[2], 'luau #' .. i .. ' direct: got ' .. tostring(ok1 and r1 or r1) .. ' want ' .. c[2])
  ok(ok2 and r2 == c[2], 'luau #' .. i .. ' serialized: got ' .. tostring(ok2 and r2 or r2) .. ' want ' .. c[2])
end

print(string.format('luau_syntax_test: %d passed, %d failed', pass, fail))
os.exit(fail == 0 and 0 or 1)
