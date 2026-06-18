-- ============================================================
--  WINDHUB v6.0  --  Universal Loader
--
--  PASTE THIS ONE LINE into your executor:
--
--    loadstring(game:HttpGet("https://raw.githubusercontent.com/robloxscripter6245366542/roblox-lua-obscator/claude/remove-key-system-qxfa4f/WindHub_Loader.lua"))()
--
--  SUPPORTED: Delta, Codex, Xeno, Wave, Optimware/Opium, Volt, Potassium
--  NO KEY SYSTEM. Just paste and run.
-- ============================================================

local WINDHUB_URL = "https://raw.githubusercontent.com/robloxscripter6245366542/roblox-lua-obscator/claude/remove-key-system-qxfa4f/WindHub.lua"

-- Toast helper
local function toast(msg, col)
    pcall(function()
        local sg = Instance.new("ScreenGui")
        sg.Name = "_WHToast"
        sg.ResetOnSpawn = false
        pcall(function() sg.Parent = game:GetService("CoreGui") end)
        if not sg.Parent then
            pcall(function() sg.Parent = game:GetService("Players").LocalPlayer:WaitForChild("PlayerGui") end)
        end
        local f = Instance.new("Frame", sg)
        f.Size = UDim2.new(0, 380, 0, 62)
        f.Position = UDim2.new(0.5, -190, 0, 18)
        f.BackgroundColor3 = Color3.fromRGB(12, 12, 18)
        f.BorderSizePixel = 0
        Instance.new("UICorner", f).CornerRadius = UDim.new(0, 9)
        local s = Instance.new("UIStroke", f)
        s.Color = col or Color3.fromRGB(80, 160, 255)
        s.Thickness = 1.5
        local t = Instance.new("TextLabel", f)
        t.Size = UDim2.new(1, -16, 1, 0)
        t.Position = UDim2.new(0, 8, 0, 0)
        t.BackgroundTransparency = 1
        t.TextColor3 = col or Color3.fromRGB(80, 200, 255)
        t.Font = Enum.Font.GothamBold
        t.TextSize = 14
        t.TextXAlignment = Enum.TextXAlignment.Left
        t.TextWrapped = true
        t.Text = "WindHub v6.0  |  " .. msg
        game:GetService("Debris"):AddItem(sg, 5)
    end)
end

toast("Fetching script...", Color3.fromRGB(80, 180, 255))

-- HTTP fetch — try multiple methods
local body = nil

-- Method 1: game:HttpGet
local ok1 = pcall(function()
    body = game:HttpGet(WINDHUB_URL, true)
end)

-- Method 2: executor request table
if not ok1 or not body or #body < 200 then
    body = nil
    local req = rawget(_G, "syn") and rawget(_G,"syn").request
        or rawget(_G, "http_request")
        or rawget(_G, "request")
        or rawget(_G, "http") and rawget(_G,"http").request
        or rawget(_G, "fluxus") and rawget(_G,"fluxus").request
    if req then
        pcall(function()
            local r = req({ Url = WINDHUB_URL, Method = "GET" })
            if r and r.Body and #r.Body > 200 then
                body = r.Body
            end
        end)
    end
end

-- Method 3: HttpService
if not body or #body < 200 then
    pcall(function()
        body = game:GetService("HttpService"):GetAsync(WINDHUB_URL, true)
    end)
end

if not body or #body < 200 then
    toast("ERROR: Could not download script.\nEnable HTTP in executor settings.", Color3.fromRGB(255, 80, 80))
    warn("[WindHub] Download failed. Make sure HTTP is enabled in your executor.")
    return
end

toast("Compiling " .. math.floor(#body/1024) .. " KB...", Color3.fromRGB(80, 180, 255))

-- Compile
local fn, compErr = loadstring(body)
if not fn then
    toast("Compile error — check output", Color3.fromRGB(255, 80, 80))
    warn("[WindHub] Compile error: " .. tostring(compErr))
    return
end

toast("Running WindHub v6.0...", Color3.fromRGB(80, 220, 80))

-- Execute
local ran, runErr = pcall(fn)
if not ran then
    toast("Runtime error — check output", Color3.fromRGB(255, 80, 80))
    warn("[WindHub] Runtime error: " .. tostring(runErr))
    return
end
