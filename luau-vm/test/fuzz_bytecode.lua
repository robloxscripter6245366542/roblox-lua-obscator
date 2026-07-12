-- luau-vm/test/fuzz_bytecode.lua
-- Fuzz the LOADER with malformed bytecode. Invariant under test: for ANY input,
-- deserialize + structural validation must return cleanly — never an uncaught
-- host error and never a hang. This is the safety property that matters when a
-- protected script runs attacker-controlled or corrupted bytes.
--
-- Two corruption modes:
--   A. random byte flips           -> almost always caught by the checksum
--   B. body-corrupted + resealed   -> checksum passes, so the STRUCTURAL
--                                     validator is the line of defense
--
--   lua5.4 test/fuzz_bytecode.lua [iterations] [seed]

package.path = 'src/?.lua;' .. package.path
local API = require('api')
local Serializer = require('serializer')
local Validate = require('validate')

local iters = tonumber(arg and arg[1]) or 4000
local seed = tonumber(arg and arg[2]) or 1

-- simple deterministic RNG (Park-Miller)
local st = seed % 2147483647; if st <= 0 then st = st + 2147483646 end
local function rnd(n) st = (st * 16807) % 2147483647; return st % n end

-- a spread of valid seed programs to corrupt
local sources = {
  'return 1+2*3',
  'local s=0 for i=1,10 do s=s+i end return s',
  'local function f(n) if n<2 then return n end return f(n-1)+f(n-2) end return f(10)',
  'local t={} for i=1,5 do t[i]=i*i end return #t',
  'local function c() local n=0 return function() n=n+1 return n end end local g=c() return g()+g()',
  'local m=setmetatable({},{__index=function(_,k) return k end}) return m[3]',
}
local valid = {}
for i, s in ipairs(sources) do valid[i] = API.serialize(s, 'p' .. i) end

-- run an accepted proto under a strict instruction budget so a crafted infinite
-- loop can't hang the fuzzer; any error (including the budget) is caught.
local function runBounded(proto)
  local budget = 2000000
  local ok = pcall(function()
    if debug and debug.sethook then
      debug.sethook(function() error('budget', 2) end, '', budget)
    end
    local out = {}
    local env = setmetatable({ print = function() end }, { __index = _G })
    API.VM.load(proto, env)()
    return out
  end)
  if debug and debug.sethook then debug.sethook() end
  return ok
end

local rejected, accepted, ranOk, hostCrashes = 0, 0, 0, 0
local firstCrash

for i = 1, iters do
  local base = valid[rnd(#valid) + 1]
  local bytes = base
  local mode = (i % 2 == 0) and 'A' or 'B'

  -- corrupt 1..4 bytes somewhere in the body (offset >= 13)
  local nflip = rnd(4) + 1
  local b = { bytes:byte(1, #bytes) }
  for _ = 1, nflip do
    local pos = 13 + rnd(math.max(1, #bytes - 13))
    if pos <= #bytes then b[pos] = rnd(256) end
  end
  bytes = string.char(table.unpack(b))
  if mode == 'B' then bytes = Serializer.reseal(bytes) end
  -- occasionally truncate too
  if rnd(5) == 0 then bytes = bytes:sub(1, rnd(#bytes) + 1) end

  -- THE invariant: Validate.bytecode must not throw for any input.
  local safe, okOrErr, proto = pcall(Validate.bytecode, bytes)
  if not safe then
    hostCrashes = hostCrashes + 1
    if not firstCrash then firstCrash = { i = i, mode = mode, err = tostring(okOrErr) } end
  elseif okOrErr == true then
    accepted = accepted + 1
    if runBounded(proto) then ranOk = ranOk + 1 end -- may also error cleanly; both fine
  else
    rejected = rejected + 1
  end
end

print(string.format('fuzz_bytecode: %d iters — rejected=%d accepted=%d (ran-clean=%d) host-crashes=%d',
  iters, rejected, accepted, ranOk, hostCrashes))
if firstCrash then
  print(string.format('  FIRST HOST CRASH at iter %d (mode %s): %s', firstCrash.i, firstCrash.mode, firstCrash.err))
end
os.exit(hostCrashes == 0 and 0 or 1)
