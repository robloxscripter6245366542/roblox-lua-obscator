-- ============================================================
--  WINDHUB v6.0  --  Universal Loadstring Loader
--
--  Paste ONE of these into your executor:
--
--  FULL (main branch, stable):
--    loadstring(game:HttpGet("https://raw.githubusercontent.com/robloxscripter6245366542/roblox-lua-obscator/main/WindHub.lua"))()
--
--  LATEST (dev branch, bleeding edge):
--    loadstring(game:HttpGet("https://raw.githubusercontent.com/robloxscripter6245366542/roblox-lua-obscator/claude/remove-key-system-qxfa4f/WindHub.lua"))()
--
--  SUPPORTED EXECUTORS:
--    Delta  |  Codex  |  Xeno  |  Wave  |  Optimware/Opium  |  Volt  |  Potassium
--
--  NO KEY SYSTEM. Just paste and run.
-- ============================================================

local WINDHUB_URL = "https://raw.githubusercontent.com/robloxscripter6245366542/roblox-lua-obscator/claude/remove-key-system-qxfa4f/WindHub.lua"

-- Executor detection
local _exec = "Unknown"
if delta then _exec = "Delta"
elseif codex then _exec = "Codex"
elseif XENO_LOADED or xeno then _exec = "Xeno"
elseif wave then _exec = "Wave"
elseif optimware or opium then _exec = "Optimware"
elseif volt then _exec = "Volt"
elseif potassium then _exec = "Potassium"
elseif syn then _exec = "Synapse (unsupported)"
elseif fluxus then _exec = "Fluxus (unsupported)"
end

local SUPPORTED = { Delta=true, Codex=true, Xeno=true, Wave=true, Optimware=true, Volt=true, Potassium=true }

if not SUPPORTED[_exec] then
    local sg = Instance.new("ScreenGui")
    sg.Name = "WindHubError"
    sg.ResetOnSpawn = false
    pcall(function() sg.Parent = game:GetService("CoreGui") end)
    local f = Instance.new("Frame", sg)
    f.Size = UDim2.new(0, 400, 0, 120)
    f.Position = UDim2.new(0.5, -200, 0.5, -60)
    f.BackgroundColor3 = Color3.fromRGB(20, 20, 20)
    f.BorderSizePixel = 0
    Instance.new("UICorner", f).CornerRadius = UDim.new(0, 10)
    local t = Instance.new("TextLabel", f)
    t.Size = UDim2.new(1, -20, 1, -20)
    t.Position = UDim2.new(0, 10, 0, 10)
    t.BackgroundTransparency = 1
    t.TextColor3 = Color3.fromRGB(255, 80, 80)
    t.Font = Enum.Font.GothamBold
    t.TextSize = 16
    t.TextWrapped = true
    t.RichText = true
    t.Text = "<b>WindHub v6.0</b>\n\nUnsupported executor: <b>" .. _exec .. "</b>\n\nSupported: Delta, Codex, Xeno, Wave, Optimware, Volt, Potassium"
    game:GetService("Debris"):AddItem(sg, 6)
    warn("[WindHub] Unsupported executor: " .. _exec .. ". Use Delta, Codex, Xeno, Wave, Optimware, Volt, or Potassium.")
    return
end

-- Loading notification
local function showLoadingToast(msg)
    pcall(function()
        local sg = Instance.new("ScreenGui")
        sg.Name = "WindHubLoader"
        sg.ResetOnSpawn = false
        pcall(function() sg.Parent = game:GetService("CoreGui") end)
        local f = Instance.new("Frame", sg)
        f.Size = UDim2.new(0, 360, 0, 70)
        f.Position = UDim2.new(0.5, -180, 0, 20)
        f.BackgroundColor3 = Color3.fromRGB(15, 15, 20)
        f.BorderSizePixel = 0
        Instance.new("UICorner", f).CornerRadius = UDim.new(0, 8)
        local stroke = Instance.new("UIStroke", f)
        stroke.Color = Color3.fromRGB(100, 180, 255)
        stroke.Thickness = 1.5
        local t = Instance.new("TextLabel", f)
        t.Size = UDim2.new(1, -20, 1, 0)
        t.Position = UDim2.new(0, 10, 0, 0)
        t.BackgroundTransparency = 1
        t.TextColor3 = Color3.fromRGB(100, 200, 255)
        t.Font = Enum.Font.GothamBold
        t.TextSize = 15
        t.TextXAlignment = Enum.TextXAlignment.Left
        t.RichText = true
        t.Text = "<b>WindHub v6.0</b>  |  " .. msg
        game:GetService("Debris"):AddItem(sg, 4)
    end)
end

showLoadingToast("Loading on " .. _exec .. "...")

-- HTTP fetch with fallback
local body = nil
local ok, err = pcall(function()
    body = game:HttpGet(WINDHUB_URL, true)
end)

if not ok or not body or body == "" then
    local req = (syn and syn.request)
        or (http and http.request)
        or http_request
        or request
        or (fluxus and fluxus.request)
    if req then
        local r = pcall(function()
            local res = req({ Url = WINDHUB_URL, Method = "GET" })
            if res and res.Body and #res.Body > 100 then
                body = res.Body
            end
        end)
    end
end

if not body or #body < 100 then
    warn("[WindHub] Failed to fetch WindHub.lua. Check your internet or HTTP permissions.")
    showLoadingToast("ERROR: Could not fetch script!")
    return
end

-- Compile
local fn, compErr = loadstring(body)
if not fn then
    warn("[WindHub] Compile error: " .. tostring(compErr))
    showLoadingToast("ERROR: Compile failed!")
    return
end

-- Execute
showLoadingToast("Executing WindHub v6.0...")
local ran, runErr = pcall(fn)
if not ran then
    warn("[WindHub] Runtime error: " .. tostring(runErr))
    showLoadingToast("ERROR: Runtime error!")
    return
end

-- Done
showLoadingToast("Loaded successfully!")
