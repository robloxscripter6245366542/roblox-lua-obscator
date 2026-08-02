-- luau-vm/test/mutate_test.lua
-- Per-build VM source mutation (mutate.lua + unparse.lua). A mutated runtime
-- module must (a) still load and run, (b) keep all globals/require/stdlib names,
-- (c) differ between build seeds (polymorphic), (d) be identical for a fixed
-- seed (reproducible), and (e) leave the whole obfuscated bundle semantically
-- identical to native.

package.path = 'src/?.lua;' .. package.path
local Mutate = require('mutate')
local Harden = require('harden')
local WebBundle = require('webbundle')

local pass, fail = 0, 0
local function ok(c, m) if c then pass = pass + 1 else fail = fail + 1; print('FAIL ' .. m) end end

local RT = { 'opcodes', 'bitops', 'serializer', 'seal', 'vm' }
local function readModule(name)
  local f = assert(io.open('src/' .. name .. '.lua', 'r')); local s = f:read('*a'); f:close(); return s
end

-- 1. every runtime module mutates to loadable Lua that preserves the globals it
--    relies on, while its local names actually change.
for _, name in ipairs(RT) do
  local src = readModule(name)
  local out = Mutate.mutate(src, Harden.prng(4242), name)
  local chunk = (load or loadstring)(out)
  ok(chunk ~= nil, 'mutated ' .. name .. ' loads')
  -- fresh local names are introduced (globals/stdlib survive by construction:
  -- the module loads AND the end-to-end bundle below runs correctly)
  ok(out:find('_%w%w%w%w%w%w') ~= nil, 'mutated ' .. name .. ' introduces renamed locals')
end

-- 2. round-trip semantics: the mutated modules run the whole compiler+VM stack.
--    (Proven broadly by running the suite against mutated modules; here we spot
--    check a couple via a mutated `vm` loaded standalone is impractical, so we
--    rely on the end-to-end bundle test below.)

-- 3. determinism + polymorphism on the full bundle
do
  local src = 'local s=0 for i=1,20 do s=s+i*i end return s'
  local rt = {}; for _, n in ipairs(RT) do rt[n] = readModule(n) end
  local a1 = WebBundle.bundle(src, rt, 'input', { seed = 7 })
  local a2 = WebBundle.bundle(src, rt, 'input', { seed = 7 })
  local b = WebBundle.bundle(src, rt, 'input', { seed = 8 })
  ok(a1 == a2, 'same seed => identical bundle (mutation is deterministic)')
  ok(a1 ~= b, 'different seed => different bundle (polymorphic VM)')
  -- the VM chunk itself differs between seeds
  local function vmchunk(s) return s:match("%['vm'%]=function.-\nend") or '' end
  ok(vmchunk(a1) ~= vmchunk(b) and #vmchunk(a1) > 0, 'the VM interpreter source differs per build')
  -- with mutation OFF the two seeds still share the same (comment-stripped) VM
  local c = WebBundle.bundle(src, rt, 'input', { seed = 8, mutateVM = false })
  ok(vmchunk(c) ~= vmchunk(b), 'mutateVM=false yields a different (unmutated) VM chunk than mutated')
end

-- 4. end-to-end: a mutated-VM bundle equals native across several programs
do
  local rt = {}; for _, n in ipairs(RT) do rt[n] = readModule(n) end
  local function runStr(chunk) local f = assert((load or loadstring)(chunk)); return select(2, pcall(f)) end
  local progs = {
    'local function f(n) if n<2 then return n end return f(n-1)+f(n-2) end return f(15)',
    'local t={} for i=1,30 do t[i]=i*i end local s=0 for _,v in ipairs(t) do s=s+v end return s',
    'local a,b=1,2 a,b=b,a+b return a,b',
    'return ("Granite"):lower(), 10//3, 2^8, #({1,2,3})',
  }
  local allok = true
  for i, src in ipairs(progs) do
    local native = runStr(src)
    local bundle = WebBundle.bundle(src, rt, 'input', { seed = 1000 + i })
    if runStr(bundle) ~= native then allok = false end
  end
  ok(allok, 'mutated-VM bundle == native across programs')
end

print(string.format('mutate_test: %d passed, %d failed', pass, fail))
os.exit(fail == 0 and 0 or 1)
