-- ============================================================
--  WINDHUB v6.0  --  Universal Loader  (Vercel CDN)
--
--  PASTE THIS into your executor (one line):
--
--    loadstring(game:HttpGet("https://roblox-lua-obscator-git-claude-rem-b354df-saguine-opus-projects.vercel.app/WindHub_Loader.lua"))()
--
--  SUPPORTED: Delta, Codex, Xeno, Wave, Optimware/Opium, Volt, Potassium
--  NO KEY SYSTEM. Just paste and run.
-- ============================================================

warn("[WindHub Loader] Starting...")

-- CDN priority: jsDelivr (fastest global edge) → Vercel → GitHub raw
local URLS = {
    "https://cdn.jsdelivr.net/gh/robloxscripter6245366542/roblox-lua-obscator@claude/remove-key-system-qxfa4f/WindHub.lua",
    "https://roblox-lua-obscator-git-claude-rem-b354df-saguine-opus-projects.vercel.app/WindHub.lua",
    "https://raw.githubusercontent.com/robloxscripter6245366542/roblox-lua-obscator/claude/remove-key-system-qxfa4f/WindHub.lua",
}

-- Toast notification helper
local function toast(msg, col)
    pcall(function()
        local sg = Instance.new("ScreenGui")
        sg.Name = "_WHToast"
        sg.ResetOnSpawn = false
        local ok1 = pcall(function() sg.Parent = game:GetService("CoreGui") end)
        if not ok1 then
            pcall(function()
                sg.Parent = game:GetService("Players").LocalPlayer:WaitForChild("PlayerGui")
            end)
        end
        local f = Instance.new("Frame", sg)
        f.Size = UDim2.new(0, 420, 0, 64)
        f.Position = UDim2.new(0.5, -210, 0, 14)
        f.BackgroundColor3 = Color3.fromRGB(10, 10, 16)
        f.BorderSizePixel = 0
        Instance.new("UICorner", f).CornerRadius = UDim.new(0, 9)
        local s = Instance.new("UIStroke", f)
        s.Color = col or Color3.fromRGB(80, 160, 255)
        s.Thickness = 1.5
        local t = Instance.new("TextLabel", f)
        t.Size = UDim2.new(1, -14, 1, 0)
        t.Position = UDim2.new(0, 7, 0, 0)
        t.BackgroundTransparency = 1
        t.TextColor3 = col or Color3.fromRGB(80, 200, 255)
        t.Font = Enum.Font.GothamBold
        t.TextSize = 12
        t.TextXAlignment = Enum.TextXAlignment.Left
        t.TextWrapped = true
        t.Text = "WindHub v6.0  |  " .. msg
        game:GetService("Debris"):AddItem(sg, 8)
    end)
end

-- HTTP fetch -- tries each URL with multiple methods
local function fetchURL(url)
    local body = nil

    -- Method 1: game:HttpGet
    pcall(function()
        local r = game:HttpGet(url)
        if r and #r > 500 then body = r end
    end)
    if body then return body end

    -- Method 2: executor request tables
    local req = (rawget(_G,"syn") and rawget(_G,"syn").request)
        or rawget(_G,"http_request")
        or rawget(_G,"request")
        or (rawget(_G,"http") and rawget(_G,"http").request)
        or (rawget(_G,"fluxus") and rawget(_G,"fluxus").request)
    if req then
        pcall(function()
            local r = req({ Url = url, Method = "GET" })
            if r and r.Body and #r.Body > 500 then body = r.Body end
        end)
    end
    if body then return body end

    -- Method 3: HttpService:GetAsync
    pcall(function()
        local r = game:GetService("HttpService"):GetAsync(url)
        if r and #r > 500 then body = r end
    end)

    return body
end

-- Try each URL in order
toast("Connecting to WindHub CDN...", Color3.fromRGB(80, 160, 255))
local body = nil
local usedURL = ""

for i, url in ipairs(URLS) do
    local label = (i == 1) and "jsDelivr CDN" or (i == 2) and "Vercel CDN" or "GitHub mirror"
    toast("Fetching from " .. label .. "...", Color3.fromRGB(80, 160, 255))
    body = fetchURL(url)
    if body and #body > 500 then
        usedURL = url
        break
    end
    warn("[WindHub] " .. label .. " failed, trying next...")
end

if not body or #body < 500 then
    toast("ERROR: All sources failed. Enable HTTP in executor!", Color3.fromRGB(255, 60, 60))
    warn("[WindHub] Could not download WindHub.lua from any source.")
    warn("[WindHub] Make sure HTTP Requests are ENABLED in your executor settings.")
    return
end

local kb = math.floor(#body / 1024)
toast("Downloaded " .. kb .. " KB - compiling...", Color3.fromRGB(80, 200, 120))
warn("[WindHub] Downloaded " .. kb .. " KB, compiling...")

-- Compile
local fn, compErr = loadstring(body)
if not fn then
    local errMsg = tostring(compErr)
    -- Show first 120 chars of error in toast so user can see it without console
    local shortErr = errMsg:sub(1, 120)
    toast("Compile ERROR: " .. shortErr, Color3.fromRGB(255, 60, 60))
    warn("[WindHub] COMPILE ERROR: " .. errMsg)
    return
end

toast("Launching WindHub v6.0...", Color3.fromRGB(80, 200, 120))
warn("[WindHub] Compiled OK, launching...")

-- Execute
local ran, runErr = pcall(fn)
if not ran then
    local errMsg = tostring(runErr)
    toast("Runtime ERROR: " .. errMsg:sub(1, 120), Color3.fromRGB(255, 60, 60))
    warn("[WindHub] RUNTIME ERROR: " .. errMsg)
end
