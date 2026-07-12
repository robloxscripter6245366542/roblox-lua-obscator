-- Verification: compare native execution against the VM for each case.
-- Portable across Lua 5.4 (load + env sandbox) and Luau (loadstring + global
-- print override), so the same corpus validates both runtimes.
local here = (arg and arg[0] and arg[0]:match('^(.*)/test/')) or '.'
package.path = here .. '/src/?.lua;' .. here .. '/test/?.lua;' .. package.path

local API = require('api')

local hasLoadEnv = _VERSION ~= 'Luau' and load ~= nil
local compileRef = load or loadstring

local function collectPrint(out)
  return function(...)
    local parts = {}
    for i = 1, select('#', ...) do parts[i] = tostring((select(i, ...))) end
    out[#out + 1] = table.concat(parts, '\t')
  end
end

local function runNative(src)
  local out = {}
  local fn, err
  if hasLoadEnv then
    local env = setmetatable({ print = collectPrint(out) }, { __index = _G })
    fn, err = load(src, 'native', 't', env)
  else
    local oldp = print
    _G.print = collectPrint(out)
    fn, err = compileRef(src)
    if fn then local ok = pcall(fn); _G.print = oldp
      if not ok then out[#out + 1] = '<error>' end
      return table.concat(out, '\n')
    end
    _G.print = oldp
  end
  if not fn then return 'COMPILE-ERROR: ' .. tostring(err) end
  if not pcall(fn) then out[#out + 1] = '<error>' end
  return table.concat(out, '\n')
end

local function runVM(src)
  local out = {}
  local proto
  local ok, err = pcall(function() proto = API.compile(src) end)
  if not ok then return 'VM-COMPILE-ERROR: ' .. tostring(err) end
  local fn
  if hasLoadEnv then
    local env = setmetatable({ print = collectPrint(out) }, { __index = _G })
    fn = API.VM.load(proto, env)
  else
    local oldp = print
    _G.print = collectPrint(out)
    fn = API.VM.load(proto, _G)
    local ok2 = pcall(fn)
    _G.print = oldp
    if not ok2 then out[#out + 1] = '<error>' end
    return table.concat(out, '\n')
  end
  if not pcall(fn) then out[#out + 1] = '<error>' end
  return table.concat(out, '\n')
end

-- Run through serialize -> deserialize -> execute, exercising the binary format.
local function runVMSerialized(src)
  local out = {}
  local bytes
  local ok, err = pcall(function() bytes = API.serialize(src) end)
  if not ok then return 'VM-SER-ERROR: ' .. tostring(err) end
  local fn
  if hasLoadEnv then
    local env = setmetatable({ print = collectPrint(out) }, { __index = _G })
    fn = API.loadBytecode(bytes, env)
    if not pcall(fn) then out[#out + 1] = '<error>' end
    return table.concat(out, '\n')
  else
    local oldp = print
    _G.print = collectPrint(out)
    fn = API.loadBytecode(bytes, _G)
    local ok2 = pcall(fn)
    _G.print = oldp
    if not ok2 then out[#out + 1] = '<error>' end
    return table.concat(out, '\n')
  end
end

local cases = require('cases')

local pass, fail, skip = 0, 0, 0
local failures = {}
for _, case in ipairs(cases) do
  local a = runNative(case[2])
  if a:match('^COMPILE%-ERROR') then
    -- source isn't valid for this runtime (e.g. 5.4 bitwise ops under Luau)
    skip = skip + 1
  else
    local b = runVM(case[2])
    local c = runVMSerialized(case[2])
    if a == b and a == c then pass = pass + 1
    else fail = fail + 1; failures[#failures + 1] = { case[1], a, b, c } end
  end
end

print(string.format('verify: %d passed, %d failed, %d skipped  (VM + serialized paths)', pass, fail, skip))
for _, f in ipairs(failures) do
  print('\nFAIL: ' .. f[1])
  print('  native    : ' .. tostring(f[2]):gsub('\n', ' | '))
  print('  vm        : ' .. tostring(f[3]):gsub('\n', ' | '))
  print('  vm(serial): ' .. tostring(f[4]):gsub('\n', ' | '))
end
if os and os.exit then os.exit(fail == 0 and 0 or 1) end
