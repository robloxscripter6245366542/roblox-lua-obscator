-- user_scripts/loader_template.lua
-- Simple loader for registering and running Roblox Lua scripts stored as strings.
-- Designed to be required from Roblox Studio via ModuleScript or used in your tooling.

local Loader = {}
local scripts = {}

-- Optional: set a decoder for obfuscated scripts (function that takes string -> plain code)
Loader.decoder = nil

-- Register a script by name. code should be a string containing Lua source.
function Loader.register(name, code)
    if type(name) ~= "string" then error("script name must be a string") end
    if type(code) ~= "string" then error("script code must be a string") end
    scripts[name] = code
    print("[loader] registered: " .. name)
end

-- Register from a ModuleScript-like table (convenience)
function Loader.registerFromTable(tbl)
    for name, code in pairs(tbl) do
        Loader.register(name, code)
    end
end

-- Load (compile + run) a registered script by name.
-- Returns whatever the script returns, or nil.
function Loader.load(name)
    local code = scripts[name]
    if not code then error("script not found: " .. tostring(name)) end
    if Loader.decoder then
        local ok, decoded = pcall(Loader.decoder, code)
        if ok and type(decoded) == "string" then
            code = decoded
        else
            error("decoder failed for script: " .. tostring(name))
        end
    end

    local fn, err = load(code, "@" .. name)
    if not fn then error("compile error in " .. name .. ": " .. tostring(err)) end

    local ok, result = pcall(fn)
    if not ok then error("runtime error in " .. name .. ": " .. tostring(result)) end
    return result
end

-- Load all registered scripts. Returns a table of results keyed by script name.
function Loader.loadAll()
    local results = {}
    for name, _ in pairs(scripts) do
        results[name] = Loader.load(name)
    end
    return results
end

-- List registered script names
function Loader.list()
    local t = {}
    for k, _ in pairs(scripts) do table.insert(t, k) end
    table.sort(t)
    return t
end

-- Clear registered scripts
function Loader.clear()
    scripts = {}
end

-- Helper: register a script file's contents when used in tooling
-- Example: Loader.registerFile("MyScript.lua", readFile("path/to/MyScript.lua"))
-- (readFile must be provided by your tooling environment)

return Loader
