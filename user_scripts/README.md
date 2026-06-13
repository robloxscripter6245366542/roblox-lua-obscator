# User Scripts

Place your Roblox Lua scripts in this directory. Name files with .lua (e.g., `MyScript.lua`).

Guidelines:
- If you want scripts to be private, run them through the obfuscator in this repository before committing.
- Keep one script per file for clarity.
- If a script depends on others, document dependencies at the top of the file.

How to use the loader template:

1. Add your script file to this folder (or keep it obfuscated and add the obfuscated file).
2. You can use `user_scripts/loader_template.lua` as a reference to register scripts manually or as a template for packaging.

Example registration (see loader_template.lua):

```lua
local loader = require(path.to.loader_template)
loader.register("MyScript", [[
    -- Your script code
]])
```
