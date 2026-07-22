-- luau-vm/test/bundle_scale_test.lua
-- Large sources must still produce a correct, runnable bundle. The bundler
-- auto-scales its heaviest passes (opaque density, junk density, cipher rounds)
-- down as the source grows so big scripts don't exhaust the in-browser
-- interpreter -- but the result must remain semantically identical to native.

package.path = 'src/?.lua;' .. package.path
local WebBundle = require('webbundle')

local pass, fail = 0, 0
local function ok(c, m) if c then pass = pass + 1 else fail = fail + 1; print('FAIL ' .. m) end end

local function readModule(name)
  local f = assert(io.open('src/' .. name .. '.lua', 'r')); local s = f:read('*a'); f:close(); return s
end
local RT = {}
for _, n in ipairs({ 'opcodes', 'bitops', 'serializer', 'seal', 'vm' }) do RT[n] = readModule(n) end

-- build a source of roughly `nstmt` statements with a known result. Uses a
-- single accumulator (not thousands of locals) so plain lua5.4 -- capped at 200
-- locals per function -- can serve as the native reference.
local function genSource(nstmt)
  local l = { 'local sum=0' }
  for i = 0, nstmt - 1 do l[#l + 1] = 'sum=sum+(' .. i .. '*3+1)%97' end
  l[#l + 1] = 'return sum'
  return table.concat(l, '\n')
end

local function runStr(chunk)
  local f = assert((load or loadstring)(chunk))
  return select(2, pcall(f))
end

-- small / medium / large: each obfuscated bundle must equal the native result
for _, nstmt in ipairs({ 30, 900, 3000, 7000 }) do
  local src = genSource(nstmt)
  local native = runStr(src)
  local bundle = WebBundle.bundle(src, RT, 'input', { seed = 2024 })
  ok(runStr(bundle) == native, 'bundle(' .. #src .. ' bytes, ' .. nstmt .. ' stmts) == native (' .. tostring(native) .. ')')
end

-- auto-scale must actually shrink a large build vs. forcing full strength
do
  local src = genSource(6000)
  local scaled = WebBundle.bundle(src, RT, 'input', { seed = 7 })
  local full = WebBundle.bundle(src, RT, 'input', { seed = 7, opaqueDensity = 350, junkDensity = 600, rounds = 2 })
  ok(#scaled < #full, 'auto-scaled large build is smaller than full-strength (' .. #scaled .. ' < ' .. #full .. ')')
  ok(runStr(scaled) == runStr(src), 'auto-scaled large build still correct')
end

-- a small script keeps full strength: forcing the same knobs changes nothing
do
  local src = genSource(30)
  local a = WebBundle.bundle(src, RT, 'input', { seed = 9 })
  local b = WebBundle.bundle(src, RT, 'input', { seed = 9, opaqueDensity = 350, junkDensity = 600, rounds = 2 })
  ok(a == b, 'small script already at full strength (auto == explicit-full)')
end

print(string.format('bundle_scale_test: %d passed, %d failed', pass, fail))
os.exit(fail == 0 and 0 or 1)
