-- build.lua  —  concatenate src/ modules into Full_Combined_source.lua
-- Usage:  lua5.4 build.lua

local ORDER = {
    "src/core/01_services.lua",
    "src/core/02_bridge.lua",
    "src/core/03_theme.lua",
    "src/core/04_ui.lua",
    "src/core/05_window.lua",
    "src/tabs/01_execute.lua",
    "src/tabs/02_server.lua",
    "src/tabs/03_sandbox.lua",
    "src/tabs/04_player.lua",
    "src/tabs/05_remotespy.lua",
    "src/tabs/06_scanner.lua",
    "src/tabs/07_deobfusc.lua",
    "src/tabs/08_checker.lua",
    "src/tabs/09_scripts.lua",
    "src/tabs/10_environ.lua",
    "src/core/06_init.lua",
}

local HEADER = [[local _ok,_err = pcall(function()
]]

local FOOTER = [[
end)
if not _ok then
    warn("[Nexus] STARTUP ERROR: "..tostring(_err))
    -- Show visible notification so mobile users see the error
    pcall(function()
        game:GetService("StarterGui"):SetCore("SendNotification",{
            Title="Nexus Error",
            Text=tostring(_err):sub(1,120),
            Duration=12,
        })
    end)
end
]]

local parts = {HEADER}
local total  = 0

for _, path in ipairs(ORDER) do
    local f = io.open(path, "r")
    if not f then
        io.stderr:write("ERROR: cannot open " .. path .. "\n")
        os.exit(1)
    end
    local src = f:read("*a")
    f:close()
    parts[#parts+1] = "-- ════════════════════════════════════════\n"
    parts[#parts+1] = "-- SOURCE: " .. path .. "\n"
    parts[#parts+1] = "-- ════════════════════════════════════════\n"
    parts[#parts+1] = src
    parts[#parts+1] = "\n"
    total = total + #src
    print(("  %-45s  %d bytes"):format(path, #src))
end

parts[#parts+1] = FOOTER

local out = table.concat(parts)
local fout = io.open("Full_Combined_source.lua", "w")
if not fout then
    io.stderr:write("ERROR: cannot write Full_Combined_source.lua\n")
    os.exit(1)
end
fout:write(out)
fout:close()

print(("\nDone — %d source bytes → Full_Combined_source.lua (%d bytes total)"):format(total, #out))
