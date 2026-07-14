-- luau-vm/tools/bundle.lua
-- Produce a self-contained, HARDENED VM-protected Luau script from a source
-- file. The output bundles the runtime modules (opcodes, bitops, serializer,
-- vm), the encrypted custom bytecode (base64), and a bootstrap that decodes,
-- decrypts, deserializes, and runs it — no loadstring, no original source.
--
--   lua5.4 tools/bundle.lua input.lua [seed] > output.lua
--
-- The hardened bundle assembly lives in src/webbundle.lua and is shared with the
-- website's in-browser bundler, so both paths emit the same output format. Pass
-- an optional integer seed for a reproducible build (otherwise each run differs).
local here = (arg and arg[0] and arg[0]:match('^(.*)/tools/')) or '.'
package.path = here .. '/src/?.lua;' .. package.path

local WebBundle = require('webbundle')

local function readModule(name)
  local f = assert(io.open(here .. '/src/' .. name .. '.lua', 'r'))
  local s = f:read('*a'); f:close()
  return s
end

local input = arg[1]
if not input then io.stderr:write('usage: bundle.lua input.lua [seed]\n'); os.exit(2) end
local seed = arg[2] and tonumber(arg[2]) or nil

local f = assert(io.open(input, 'r'))
local src = f:read('*a'); f:close()

local RT = {}
for _, name in ipairs({ 'opcodes', 'bitops', 'serializer', 'seal', 'vm' }) do RT[name] = readModule(name) end

io.write(WebBundle.bundle(src, RT, input, seed and { seed = seed } or nil))
