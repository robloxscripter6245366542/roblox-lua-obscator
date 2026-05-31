local SS = _G._SS
local RS = SS.RS

local Bridge = RS:FindFirstChild("SS_ExecBridge")
SS.Bridge = Bridge

local function pingBridge()
    if not Bridge then return false end
    local ok, r = pcall(function() return Bridge:InvokeServer("ping") end)
    return ok and r and r.ok
end

local function callBridge(action, payload)
    if not Bridge then
        return false, "No bridge.\nInject SS_Executor.lua server-side first."
    end
    local ok, r = pcall(function() return Bridge:InvokeServer(action, payload or {}) end)
    if not ok then return false, tostring(r) end
    return r.ok, r.msg, r.data
end

SS.pingBridge  = pingBridge
SS.callBridge  = callBridge
