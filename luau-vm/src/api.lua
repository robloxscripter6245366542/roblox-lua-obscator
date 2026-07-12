-- luau-vm/src/api.lua
-- Convenience front end: source -> bytecode -> callable, with no loadstring.

local Compiler = require('compiler')
local VM = require('vm')
local Serializer = require('serializer')

local API = {}

function API.compile(src, chunkName)
  return Compiler.compile(src, chunkName)
end

function API.load(src, env, chunkName)
  return VM.load(Compiler.compile(src, chunkName), env or _G)
end

-- Compile to a portable binary bytecode string (no loadstring on either side).
function API.serialize(src, chunkName)
  return Serializer.serialize(Compiler.compile(src, chunkName))
end

-- Load and run bytecode produced by API.serialize.
function API.loadBytecode(bytes, env)
  return VM.load(Serializer.deserialize(bytes), env or _G)
end

function API.run(src, env, chunkName, ...)
  return API.load(src, env, chunkName)(...)
end

API.VM = VM
API.Compiler = Compiler
API.Serializer = Serializer
return API
