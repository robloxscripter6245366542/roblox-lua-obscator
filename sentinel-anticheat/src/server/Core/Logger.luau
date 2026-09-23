--!strict
-- Sentinel Logger — level-gated structured logging.
local Config = require(game:GetService("ReplicatedStorage").SentinelShared.Config)

local LEVELS = { silent = 0, warn = 1, info = 2, debug = 3 }

local Logger = {}

local function enabled(level: string): boolean
	return (LEVELS[Config.LogLevel] or 2) >= (LEVELS[level] or 2)
end

local function fmt(level: string, msg: string): string
	return ("[Sentinel][%s] %s"):format(level:upper(), msg)
end

function Logger.debug(msg: string)
	if enabled("debug") then print(fmt("debug", msg)) end
end
function Logger.info(msg: string)
	if enabled("info") then print(fmt("info", msg)) end
end
function Logger.warn(msg: string)
	if enabled("warn") then warn(fmt("warn", msg)) end
end

return Logger
