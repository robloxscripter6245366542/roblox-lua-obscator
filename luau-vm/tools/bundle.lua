-- luau-vm/tools/bundle.lua
-- Produce a self-contained, VM-protected Luau script from a source file.
-- The output bundles the runtime modules (opcodes, bitops, serializer, vm), the
-- serialized custom bytecode (base64), and a bootstrap that decodes,
-- deserializes, and runs it — no loadstring, no original source.
--
--   lua5.4 tools/bundle.lua input.lua > output.lua
--
-- The runtime-bundle assembly here is mirrored by the website's JS bundler; this
-- Lua version validates the output format end-to-end.
local here = (arg and arg[0] and arg[0]:match('^(.*)/tools/')) or '.'
package.path = here .. '/src/?.lua;' .. package.path

local API = require('api')

-- base64 (matches the decoder emitted below)
local B64 = 'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/'
local function b64encode(data)
  local out, len = {}, #data
  for i = 1, len, 3 do
    local b1 = data:byte(i)
    local b2 = i + 1 <= len and data:byte(i + 1) or 0
    local b3 = i + 2 <= len and data:byte(i + 2) or 0
    local n = b1 * 65536 + b2 * 256 + b3
    out[#out + 1] = B64:sub(math.floor(n / 262144) % 64 + 1, math.floor(n / 262144) % 64 + 1)
    out[#out + 1] = B64:sub(math.floor(n / 4096) % 64 + 1, math.floor(n / 4096) % 64 + 1)
    out[#out + 1] = i + 1 <= len and B64:sub(math.floor(n / 64) % 64 + 1, math.floor(n / 64) % 64 + 1) or '='
    out[#out + 1] = i + 2 <= len and B64:sub(n % 64 + 1, n % 64 + 1) or '='
  end
  return table.concat(out)
end

local function readModule(name)
  local f = assert(io.open(here .. '/src/' .. name .. '.lua', 'r'))
  local s = f:read('*a'); f:close()
  return s
end

-- Assemble the self-contained runtime bundle around a base64 bytecode payload.
local function bundle(payloadB64)
  local RUNTIME = { 'opcodes', 'bitops', 'serializer', 'vm' }
  local parts = {}
  parts[#parts + 1] = '-- ferret VM-protected script (custom bytecode; no loadstring)'
  parts[#parts + 1] = 'local __m,__c={},{}'
  parts[#parts + 1] = 'local function require(n) if __c[n]==nil then __c[n]=__m[n]() end return __c[n] end'
  for _, name in ipairs(RUNTIME) do
    parts[#parts + 1] = "__m['" .. name .. "']=function()\n" .. readModule(name) .. '\nend'
  end
  -- base64 decoder + bootstrap
  parts[#parts + 1] = [[
local __A='ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/'
local function __b64(s)
  local r,v,b={},0,0
  s=s:gsub('[^'..__A..'=]','')
  for i=1,#s do
    local c=s:sub(i,i)
    if c=='=' then break end
    local p=__A:find(c,1,true)
    if not p then break end
    v=v*64+(p-1) b=b+6
    if b>=8 then b=b-8 r[#r+1]=string.char(math.floor(v/2^b)%256) v=v%(2^b) end
  end
  return table.concat(r)
end
local __Ser=require('serializer')
local __VM=require('vm')
local __proto=__Ser.deserialize(__b64(__PAYLOAD__))
local __env=(getfenv and getfenv(1)) or (type(_ENV)=='table' and _ENV) or _G
return __VM.load(__proto,__env)()]]
  local body = table.concat(parts, '\n')
  local out = body:gsub('__PAYLOAD__', function() return "'" .. payloadB64 .. "'" end)
  return out -- drop gsub's second return (the count)
end

local input = arg[1]
if not input then io.stderr:write('usage: bundle.lua input.lua\n'); os.exit(2) end
local f = assert(io.open(input, 'r'))
local src = f:read('*a'); f:close()

local bytes = API.serialize(src, input)
io.write(bundle(b64encode(bytes)))
