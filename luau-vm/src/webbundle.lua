-- luau-vm/src/webbundle.lua
-- Browser-friendly bundler: compile a Luau source string to a self-contained
-- VM-protected script. Unlike tools/bundle.lua it never touches the filesystem;
-- the runtime module sources are passed in (the website embeds them), so this
-- runs unchanged inside Fengari (Lua-in-JS) in the browser.

local API = require('api')

local M = {}

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

-- runtimeSrc: table of Lua source strings for { opcodes, bitops, serializer, vm }.
function M.bundle(src, runtimeSrc, chunkName)
  local bytes = API.serialize(src, chunkName or 'input')
  local payload = b64encode(bytes)

  local order = { 'opcodes', 'bitops', 'serializer', 'vm' }
  local parts = {}
  parts[#parts + 1] = '-- ferret VM-protected script (custom bytecode; no loadstring)'
  parts[#parts + 1] = 'local __m,__c={},{}'
  parts[#parts + 1] = 'local function require(n) if __c[n]==nil then __c[n]=__m[n]() end return __c[n] end'
  for _, name in ipairs(order) do
    local s = runtimeSrc[name]
    if not s then error('webbundle: missing runtime source for ' .. name) end
    parts[#parts + 1] = "__m['" .. name .. "']=function()\n" .. s .. '\nend'
  end
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
  local out = body:gsub('__PAYLOAD__', function() return "'" .. payload .. "'" end)
  return out
end

return M
