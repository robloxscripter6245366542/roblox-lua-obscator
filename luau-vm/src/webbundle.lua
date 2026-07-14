-- luau-vm/src/webbundle.lua
-- Browser-friendly bundler: compile a Luau source string to a self-contained,
-- HARDENED VM-protected script. Unlike tools/bundle.lua it never touches the
-- filesystem; the runtime module sources are passed in (the website embeds
-- them), so this runs unchanged inside Fengari (Lua-in-JS) in the browser.
--
-- Hardening applied per build (see harden.lua): opcode permutation, the custom
-- multi-stage GraniteCipher over the serialized blob (byte permutation -> S-box
-- -> chained stream mask -> GraniteSum checksum), a per-build permuted output
-- alphabet, factored (non-literal) sub-seeds, randomized decoder variable names,
-- and comment-stripped runtime sources. Every primitive is our own (no bit32,
-- no Base64/DJB2/FNV/Park-Miller). Still no loadstring, and the original source
-- is never reconstructed — the logic exists only as encrypted bytecode.

local Compiler = require('compiler')
local Serializer = require('serializer')
local Opcodes = require('opcodes')
local Harden = require('harden')

local M = {}

-- Custom output encoding: a 64-symbol pool (letters/digits + `_` `~`, all safe
-- inside a single-quoted Lua string AND a Lua pattern char-class) that is
-- permuted per build, so the output alphabet is never the standard Base64 one.
local B64POOL = 'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789_~'

-- Per-build permutation of the symbol pool (keyed Fisher-Yates over `rng`).
local function permuteAlphabet(rng)
  local a = {}
  for i = 1, 64 do a[i] = B64POOL:sub(i, i) end
  for i = 64, 2, -1 do
    local j = rng.int(i) + 1
    a[i], a[j] = a[j], a[i]
  end
  return table.concat(a)
end

-- Base64-style 6-bit encoder over an arbitrary 64-char `alpha` (pad char '=').
local function encodeWith(alpha, data)
  local out, len = {}, #data
  local function sym(k) return alpha:sub(k + 1, k + 1) end
  for i = 1, len, 3 do
    local b1 = data:byte(i)
    local b2 = i + 1 <= len and data:byte(i + 1) or 0
    local b3 = i + 2 <= len and data:byte(i + 2) or 0
    local n = b1 * 65536 + b2 * 256 + b3
    out[#out + 1] = sym(math.floor(n / 262144) % 64)
    out[#out + 1] = sym(math.floor(n / 4096) % 64)
    out[#out + 1] = i + 1 <= len and sym(math.floor(n / 64) % 64) or '='
    out[#out + 1] = i + 2 <= len and sym(n % 64) or '='
  end
  return table.concat(out)
end

-- Pick a per-build seed. Deterministic when opts.seed is given (tests); else
-- derived from wall clock + math.random so each build differs.
local function pickSeed(opts)
  if opts and opts.seed then return opts.seed end
  local t = (os and os.time and os.time()) or 0
  local r = math.random(1, 2147483646)
  local s = (t * 2654435761 + r) % 2147483647
  if s <= 0 then s = s + 2147483646 end
  return s
end

-- Strip comments from a runtime source, but only if the result still parses.
local function safeStrip(src)
  local stripped = Harden.stripComments(src)
  local chunk = (loadstring or load)(stripped)
  if chunk then return stripped end
  return src
end

-- Per-build fresh identifier generator: `_` + 5 chars from [a-z0-9]. The leading
-- underscore + lowercase means a name can never collide with a Lua keyword, a
-- stdlib global (string/math/table/...), `_ENV`/`_G`, or `require`, so the
-- emitted decoder's locals are unrecognizable and differ every build.
local function idGen(rng)
  local pool = 'abcdefghijklmnopqrstuvwxyz0123456789'
  local used = {}
  return function()
    while true do
      local s = '_'
      for _ = 1, 5 do local d = rng.int(#pool); s = s .. pool:sub(d + 1, d + 1) end
      if not used[s] then used[s] = true; return s end
    end
  end
end

-- A single inert junk statement: a fresh, never-referenced local whose value is
-- deterministic dead code (arithmetic, a dummy function, or a small table). Adds
-- per-build noise between the real decoder statements without any side effect,
-- so a reader can't tell signal from filler by shape alone.
local function junkStmt(g, rng)
  local kind = rng.int(3)
  local name = g()
  if kind == 0 then
    return 'local ' .. name .. '=' .. (rng.int(90000) + 10000) .. '*'
      .. (rng.int(9000) + 1000) .. '+' .. rng.int(1000)
  elseif kind == 1 then
    return 'local function ' .. name .. '(' .. g() .. ') return '
      .. rng.int(100000) .. ' end'
  else
    return 'local ' .. name .. '={' .. rng.int(1000) .. ',' .. rng.int(1000)
      .. ',' .. rng.int(1000) .. '}'
  end
end

-- runtimeSrc: table of Lua source strings for { opcodes, bitops, serializer, vm }.
function M.bundle(src, runtimeSrc, chunkName, opts)
  local seed = pickSeed(opts)
  local rng = Harden.prng(seed)

  -- 1. compile, 2. permute opcodes, 3. serialize with the permutation,
  -- 4. compress + wrap in a versioned, fingerprinted envelope,
  -- 5. seal with the multi-round GraniteCipher, 6. encode (permuted alphabet).
  -- Opaque-predicate injection (bogus, always-taken/never-taken control flow)
  -- uses an INDEPENDENT prng derived from the build seed, so it does not disturb
  -- the main rng stream used for opcode mutation / cipher below. Deterministic
  -- per build; disable with opts.opaque == false.
  local copts = { chunkName = chunkName }
  if not (opts and opts.opaque == false) then
    copts.opaque = Harden.prng((seed + 2166136261) % 4294967296)
    copts.opaqueDensity = (opts and opts.opaqueDensity) or 350
  end
  local proto = Compiler.compile(src, chunkName or 'input', copts)
  -- opcode MUTATION: each opcode has several interchangeable byte encodings,
  -- picked per instruction, so one opcode appears as different bytes.
  local fwd, inv = Harden.opMutationMap(Opcodes.count, rng, 3)
  local bc = Serializer.serialize(proto, fwd, function() return rng.int(1000003) end)
  local env = Harden.envelope(Harden.compress(bc))
  local rounds = (opts and opts.rounds) or 2
  local sealed, cp = Harden.seal(env, rng, rounds)
  local alpha = permuteAlphabet(rng)
  local payload = encodeWith(alpha, sealed)

  -- per-layer sub-seeds emitted as arithmetic expressions (not grep-able
  -- literals), as Lua table constructors the decoder peels in reverse.
  local function exprList(field)
    local t = {}
    for i = 1, #cp.layers do t[i] = Harden.factorKey(cp.layers[i][field], rng) end
    return '{' .. table.concat(t, ',') .. '}'
  end
  local permList = exprList('permSeed')
  local sboxList = exprList('sboxSeed')
  local maskList = exprList('maskSeed')
  local ivParts = {}
  for i = 1, #cp.layers do ivParts[i] = tostring(cp.layers[i].iv) end
  local ivList = '{' .. table.concat(ivParts, ',') .. '}'
  local invLit = Harden.invMapLiteral(inv)

  -- per-build randomized names for every decoder local (keeps `require` and
  -- stdlib names, which the inlined module sources reference).
  local g = idGen(rng)
  local N = {}
  for _, k in ipairs({
    'mreg', 'mcache', 'b64', 'gm', 'pr', 'alpha', 'sealed', 'ct', 'csa', 'csb',
    'csum', 'want', 'n', 't', 'mr', 'prev', 'k', 'cur', 'sr', 'sb', 'is',
    'ps', 'rg', 'bb', 'plain', 'inv', 'ser', 'vm', 'proto', 'env', 'bit',
    'msk', 'sbs', 'prm', 'ivs', 'rr', 'envb', 'ver', 'fpw', 'fpg', 'pay',
    'dz', 'fa', 'fb', 'ei', 'ec', 'dc', 'seal', 'sk',
  }) do N[k] = g() end

  local order = { 'opcodes', 'bitops', 'serializer', 'seal', 'vm' }
  local parts = {}
  -- banner (ASCII only — the browser build ASCII-sanitizes this source)
  parts[#parts + 1] = '-- ================================================================'
  parts[#parts + 1] = '--  Obfuscated by Granite Lock  |  https://granitelockvm.vercel.app'
  parts[#parts + 1] = '--  Custom bytecode VM  |  encrypted  |  no loadstring'
  parts[#parts + 1] = '-- ================================================================'
  -- module registry: `require` keeps its name (module sources call it by name).
  parts[#parts + 1] = 'local ' .. N.mreg .. ',' .. N.mcache .. '={},{}'
  parts[#parts + 1] = 'local function require(n) if ' .. N.mcache .. '[n]==nil then '
    .. N.mcache .. '[n]=' .. N.mreg .. '[n]() end return ' .. N.mcache .. '[n] end'
  parts[#parts + 1] = junkStmt(g, rng)
  for _, name in ipairs(order) do
    local s = runtimeSrc[name]
    if not s then error('webbundle: missing runtime source for ' .. name) end
    parts[#parts + 1] = N.mreg .. "['" .. name .. "']=function()\n" .. safeStrip(s) .. '\nend'
    if rng.int(2) == 0 then parts[#parts + 1] = junkStmt(g, rng) end
  end
  for _ = 1, rng.int(3) + 2 do parts[#parts + 1] = junkStmt(g, rng) end

  -- custom decoder + GraniteCipher unseal + bootstrap. Verifies the ciphertext
  -- checksum, peels every cipher round in reverse (stream unmask -> inverse
  -- S-box -> inverse permutation), checks the VM version + build fingerprint,
  -- decompresses, then deserializes. All tables (S-box / permutation /
  -- keystream) are regenerated from the emitted sub-seeds via our own PRNG.
  -- No loadstring; bytes -> proto. An active debug hook aborts (best-effort).
  parts[#parts + 1] = table.concat({
    'if type(debug)=="table" and debug.gethook and debug.gethook()~=nil then error("granite: debugger detected") end',
    -- per-build permuted alphabet + decoder (reverse lookup by find)
    'local ' .. N.alpha .. "='" .. alpha .. "'",
    'local function ' .. N.b64 .. '(s)',
    '  local r,v,b={},0,0',
    "  s=s:gsub('[^'.." .. N.alpha .. "..'=]','')",
    '  for i=1,#s do',
    '    local c=s:sub(i,i)',
    "    if c=='=' then break end",
    '    local p=' .. N.alpha .. ':find(c,1,true)',
    '    if not p then break end',
    '    v=v*64+(p-1) b=b+6',
    '    if b>=8 then b=b-8 r[#r+1]=string.char(math.floor(v/2^b)%256) v=v%(2^b) end',
    '  end',
    '  return table.concat(r)',
    'end',
    'local ' .. N.bit .. '=require("bitops")',
    -- custom GraniteRNG (our own PRNG): split multiply + avalanche, identical
    -- stream to build-time Harden.prng.
    'local function ' .. N.gm .. '(a,b) local al=a%65536 return ((al*b)+(((a-al)/65536*b)%65536)*65536)%4294967296 end',
    'local function ' .. N.pr .. '(sd)',
    '  local st=sd%4294967296',
    '  return function(n)',
    '    st=(' .. N.gm .. '(st,3218467781)+2596069031)%4294967296',
    '    local x=' .. N.gm .. '(st,3812015801)',
    '    x=(x%65536)*65536+(x-x%65536)/65536',
    '    x=' .. N.gm .. '(x,1274126177)',
    '    if n then return x%n else return x end',
    '  end',
    'end',
    'local ' .. N.sealed .. '=' .. N.b64 .. "('" .. payload .. "')",
    -- (6) verify our custom GraniteSum checksum over the ciphertext
    'local ' .. N.ct .. '=' .. N.sealed .. ':sub(5)',
    'local ' .. N.csa .. ',' .. N.csb .. '=19088743,1985229328',
    '  for i=1,#' .. N.ct .. ' do ' .. N.csa .. '=(' .. N.csa .. '*178711+' .. N.ct .. ':byte(i)+1)%4294967296 '
      .. N.csb .. '=(' .. N.csb .. '+' .. N.csa .. ')%4294967296 end',
    'local ' .. N.csum .. '=(' .. N.csa .. '+' .. N.gm .. '(' .. N.csb .. ',40503))%4294967296',
    'local ' .. N.want .. '=' .. N.sealed .. ':byte(1)*16777216+' .. N.sealed .. ':byte(2)*65536+'
      .. N.sealed .. ':byte(3)*256+' .. N.sealed .. ':byte(4)',
    'if ' .. N.csum .. '~=' .. N.want .. ' then error("granite: integrity check failed") end',
    'local ' .. N.n .. '=#' .. N.ct,
    'local ' .. N.t .. '={}',
    '  for i=1,' .. N.n .. ' do ' .. N.t .. '[i]=' .. N.ct .. ':byte(i) end',
    -- per-layer sub-seeds (factored expressions) + IVs, peeled in reverse
    'local ' .. N.msk .. '=' .. maskList,
    'local ' .. N.sbs .. '=' .. sboxList,
    'local ' .. N.prm .. '=' .. permList,
    'local ' .. N.ivs .. '=' .. ivList,
    'for ' .. N.rr .. '=#' .. N.msk .. ',1,-1 do',
    -- (5) inverse stream masking (cipher-feedback chaining)
    '  local ' .. N.mr .. '=' .. N.pr .. '(' .. N.msk .. '[' .. N.rr .. '])',
    '  local ' .. N.prev .. '=' .. N.ivs .. '[' .. N.rr .. ']',
    '  for i=1,' .. N.n .. ' do local ' .. N.k .. '=' .. N.mr .. '(256) local ' .. N.cur .. '=' .. N.t .. '[i] '
      .. N.t .. '[i]=' .. N.bit .. '.bxor(' .. N.bit .. '.bxor(' .. N.cur .. ',' .. N.k .. '),' .. N.prev .. ') '
      .. N.prev .. '=' .. N.cur .. ' end',
    -- (4) inverse byte substitution: rebuild the S-box, invert it, apply
    '  local ' .. N.sr .. '=' .. N.pr .. '(' .. N.sbs .. '[' .. N.rr .. '])',
    '  local ' .. N.sb .. '={} for i=0,255 do ' .. N.sb .. '[i]=i end',
    '  for i=255,1,-1 do local j=' .. N.sr .. '(i+1) ' .. N.sb .. '[i],' .. N.sb .. '[j]=' .. N.sb .. '[j],' .. N.sb .. '[i] end',
    '  local ' .. N.is .. '={} for i=0,255 do ' .. N.is .. '[' .. N.sb .. '[i]]=i end',
    '  for i=1,' .. N.n .. ' do ' .. N.t .. '[i]=' .. N.is .. '[' .. N.t .. '[i]] end',
    -- (3) inverse byte permutation: regenerate swap partners, undo in order
    '  local ' .. N.ps .. '={} do local ' .. N.rg .. '=' .. N.pr .. '(' .. N.prm .. '[' .. N.rr .. ']) for i=' .. N.n .. ',2,-1 do '
      .. N.ps .. '[i]=' .. N.rg .. '(i)+1 end end',
    '  for i=2,' .. N.n .. ' do ' .. N.t .. '[i],' .. N.t .. '[' .. N.ps .. '[i]]=' .. N.t .. '[' .. N.ps .. '[i]],' .. N.t .. '[i] end',
    'end',
    'local ' .. N.bb .. '={}',
    '  for i=1,' .. N.n .. ' do ' .. N.bb .. '[i]=string.char(' .. N.t .. '[i]) end',
    'local ' .. N.envb .. '=table.concat(' .. N.bb .. ')',
    -- VM versioning gate
    'local ' .. N.ver .. '=' .. N.envb .. ':byte(1)',
    'if ' .. N.ver .. '~=' .. Harden.VM_VERSION .. ' then error("granite: VM version mismatch") end',
    -- build fingerprint (GraniteSum over version+payload): anti-tamper
    'local ' .. N.pay .. '=' .. N.envb .. ':sub(6)',
    'local ' .. N.fpw .. '=' .. N.envb .. ':byte(2)*16777216+' .. N.envb .. ':byte(3)*65536+'
      .. N.envb .. ':byte(4)*256+' .. N.envb .. ':byte(5)',
    'local ' .. N.fa .. ',' .. N.fb .. '=19088743,1985229328',
    'do local ' .. N.dz .. '=string.char(' .. N.ver .. ')..' .. N.pay,
    '  for i=1,#' .. N.dz .. ' do ' .. N.fa .. '=(' .. N.fa .. '*178711+' .. N.dz .. ':byte(i)+1)%4294967296 '
      .. N.fb .. '=(' .. N.fb .. '+' .. N.fa .. ')%4294967296 end end',
    'local ' .. N.fpg .. '=(' .. N.fa .. '+' .. N.gm .. '(' .. N.fb .. ',40503))%4294967296',
    'if ' .. N.fpg .. '~=' .. N.fpw .. ' then error("granite: tamper check failed") end',
    -- GraniteRLE decompress -> serialized bytecode
    'local function ' .. N.dc .. '(s)',
    '  local fl=s:byte(1) local rest=s:sub(2)',
    '  if fl==0 then return rest end',
    '  local ec=rest:byte(1) local o={} local i=2 local m=#rest',
    '  while i<=m do local c=rest:byte(i)',
    '    if c==ec then o[#o+1]=string.rep(string.char(rest:byte(i+1)),rest:byte(i+2)) i=i+3',
    '    else o[#o+1]=string.char(c) i=i+1 end',
    '  end',
    '  return table.concat(o)',
    'end',
    'local ' .. N.plain .. '=' .. N.dc .. '(' .. N.pay .. ')',
    'local ' .. N.inv .. '=' .. invLit,
    'local ' .. N.ser .. '=require("serializer")',
    'local ' .. N.vm .. '=require("vm")',
    'local ' .. N.proto .. '=' .. N.ser .. '.deserialize(' .. N.plain .. ',' .. N.inv .. ')',
    -- Runtime SEAL: derive an ephemeral per-execution session key (clock +
    -- randomness), then seal the proto tree so instructions are decoded one at a
    -- time, on demand (streamed execution). The full plaintext bytecode is never
    -- resident and the in-memory encrypted form differs every run.
    'local ' .. N.seal .. '=require("seal")',
    'if math.randomseed then math.randomseed((tick and math.floor(tick()*1e6)) or (os and os.time and os.time()) or 0) end',
    'local ' .. N.sk .. '=(((tick and math.floor(tick()*1e6)) or (os and os.time and os.time()) or 1)*131+math.random(1,2147483646))%4294967296',
    'if ' .. N.sk .. '==0 then ' .. N.sk .. '=1 end',
    N.seal .. '.seal(' .. N.proto .. ',' .. N.sk .. ')',
    -- Resolve the global environment for the VM (Roblox Luau has no _ENV).
    'local ' .. N.env,
    'if type(_ENV)=="table" then ' .. N.env .. '=_ENV',
    'elseif getfenv then local __ok,__e=pcall(getfenv,1) ' .. N.env .. '=(__ok and type(__e)=="table") and __e or _G',
    'else ' .. N.env .. '=_G end',
    'return ' .. N.vm .. '.load(' .. N.proto .. ',' .. N.env .. ')()',
  }, '\n')
  return table.concat(parts, '\n')
end

return M
