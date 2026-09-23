-- user_scripts/link_bypasser.lua
-- Link Bypasser
-- --------------------------------------------------------------------------
-- A universal "link bypasser" for Roblox executors. Give it a gated / shortened
-- link (the kind used by key systems and ad-walls) and it follows the redirect
-- chain and scrapes the destination so you get "whatever there is" at the end
-- of the link -- the final URL, and any key / token embedded along the way.
--
-- It is provider-agnostic: instead of hard-coding one site it does the generic
-- things every one of these gates relies on -- follow HTTP redirects, read
-- Location / Refresh headers, decode base64 target params, and pull the final
-- link / key out of the returned HTML. Known providers just get extra hints.
--
-- Usage (as a module):
--     local Bypass = loadstring(game:HttpGet(RAW_URL))()
--     local result = Bypass.resolve("https://link-target.net/xxxxx")
--     print(result.final)   -- final destination URL
--     print(result.key)     -- extracted key/token, if one was found
--     print(result.chain)   -- table of every hop it went through
--
-- Usage (as a tool):  running the file directly opens a small GUI where you can
-- paste a link, hit Bypass, and copy the result.
-- --------------------------------------------------------------------------

local Bypass = {}
Bypass.__index = Bypass

Bypass.VERSION = "1.0.0"
Bypass.MAX_HOPS = 15         -- redirect safety limit
Bypass.TIMEOUT  = 15         -- per-request soft timeout (executor dependent)

-- --------------------------------------------------------------------------
-- HTTP layer: adapt to whatever request function the executor exposes.
-- --------------------------------------------------------------------------

local function pick_request()
    -- Ordered by how common / capable each is.
    local candidates = {
        rawget(getfenv and getfenv() or _G, "request"),
        (syn and syn.request),
        (http and http.request),
        rawget(_G, "http_request"),
        (fluxus and fluxus.request),
        rawget(_G, "httprequest"),
    }
    for _, fn in ipairs(candidates) do
        if type(fn) == "function" then
            return fn
        end
    end
    return nil
end

local REQUEST = pick_request()

-- Perform a single HTTP request WITHOUT auto-following redirects, so we can
-- inspect every hop. Returns a normalized table { status, headers, body }.
local function http_raw(url, method, headers, body)
    method  = method or "GET"
    headers = headers or {}
    headers["User-Agent"] = headers["User-Agent"]
        or "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 "
        .. "(KHTML, like Gecko) Chrome/120.0 Safari/537.36"

    if REQUEST then
        local ok, res = pcall(REQUEST, {
            Url = url,
            Method = method,
            Headers = headers,
            Body = body,
        })
        if ok and type(res) == "table" then
            -- Normalize header key casing.
            local h = {}
            for k, v in pairs(res.Headers or res.headers or {}) do
                h[tostring(k):lower()] = v
            end
            return {
                status  = res.StatusCode or res.status_code or res.Status or 0,
                headers = h,
                body    = res.Body or res.body or "",
            }
        end
    end

    -- Fallback: game:HttpGet follows redirects itself, so we only get the
    -- final body. Still useful for scraping the destination link / key.
    local ok, body_only = pcall(function()
        return game:HttpGet(url, true)
    end)
    if ok and type(body_only) == "string" then
        return { status = 200, headers = {}, body = body_only, followed = true }
    end

    return nil
end

-- --------------------------------------------------------------------------
-- Small helpers
-- --------------------------------------------------------------------------

local function trim(s)
    return (s:gsub("^%s+", ""):gsub("%s+$", ""))
end

-- Resolve a possibly-relative URL against a base.
local function absolutize(base, target)
    if not target or target == "" then return target end
    if target:match("^https?://") then return target end
    local scheme, host = base:match("^(https?://)([^/]+)")
    if not scheme then return target end
    if target:sub(1, 2) == "//" then
        return scheme:gsub("://$", ":") .. target
    elseif target:sub(1, 1) == "/" then
        return scheme .. host .. target
    else
        local path = base:match("^https?://[^/]+(.*)$") or "/"
        path = path:gsub("[^/]*$", "")
        return scheme .. host .. path .. target
    end
end

-- URL-decode percent escapes.
local function url_decode(s)
    if not s then return s end
    s = s:gsub("+", " ")
    return (s:gsub("%%(%x%x)", function(h)
        return string.char(tonumber(h, 16))
    end))
end

-- Base64 decode (many gates pass the destination as ?r=<base64url>).
local B64 = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/"
local function base64_decode(data)
    if not data or #data == 0 then return nil end
    data = data:gsub("-", "+"):gsub("_", "/")        -- base64url -> base64
    data = data:gsub("[^" .. "%w%+%/%=" .. "]", "")
    if #data == 0 then return nil end
    local ok, out = pcall(function()
        return (data:gsub("=", ""):gsub("[%w%+%/]", function(c)
            local idx = (B64:find(c, 1, true) or 1) - 1
            local bits = ""
            for i = 5, 0, -1 do
                bits = bits .. (math.floor(idx / 2 ^ i) % 2 == 1 and "1" or "0")
            end
            return bits
        end):gsub("%d%d%d?%d?%d?%d?%d?%d?", function(byte)
            if #byte ~= 8 then return "" end
            local n = 0
            for i = 1, 8 do n = n * 2 + (byte:sub(i, i) == "1" and 1 or 0) end
            return string.char(n)
        end))
    end)
    return ok and out or nil
end

-- Try to pull a redirect target out of a URL's query string.
local function target_from_query(url)
    for key in ("url,u,r,to,dest,destination,redirect,link,target,goto,next,out,q"):gmatch("[^,]+") do
        local raw = url:match("[?&]" .. key .. "=([^&]+)")
        if raw then
            local dec = url_decode(raw)
            if dec and dec:match("^https?://") then
                return dec
            end
            local b = base64_decode(raw)
            if b and b:match("^https?://") then
                return b
            end
        end
    end
    return nil
end

-- Scrape a destination link and/or key out of an HTML body.
local function scrape(body, base)
    if type(body) ~= "string" then return nil, nil end
    local result = { link = nil, key = nil }

    -- meta refresh: <meta http-equiv="refresh" content="0;url=...">
    local refresh = body:match('[Hh][Tt][Tt][Pp]%-[Ee][Qq][Uu][Ii][Vv]%s*=%s*["\']?refresh["\']?[^>]-[Uu][Rr][Ll]=([^"\'>%s]+)')
    if refresh then result.link = absolutize(base, url_decode(refresh)) end

    -- JS redirects: window.location = "...", location.href = "..."
    if not result.link then
        local js = body:match('location%.href%s*=%s*["\']([^"\']+)["\']')
              or  body:match('window%.location%s*=%s*["\']([^"\']+)["\']')
              or  body:match('location%.replace%(%s*["\']([^"\']+)["\']')
        if js then result.link = absolutize(base, url_decode(js)) end
    end

    -- Common key / token patterns.
    result.key = body:match('[Kk][Ee][Yy]["\'%s:=]+([%w%-_]+)')
        or body:match('[Tt][Oo][Kk][Ee][Nn]["\'%s:=]+([%w%-_]+)')
        or body:match('id="[Kk]ey"[^>]->([%w%-_]+)<')
        or body:match('class="key"[^>]->([%w%-_]+)<')
    if result.key and #result.key < 6 then result.key = nil end  -- filter noise

    -- Fallback: first external https link that is not an asset/social.
    if not result.link then
        for href in body:gmatch('href%s*=%s*["\'](https?://[^"\']+)["\']') do
            if not href:match('%.css') and not href:match('%.js')
               and not href:match('%.png') and not href:match('%.jpg')
               and not href:match('%.ico') and not href:match('%.svg')
               and not href:match('facebook%.com') and not href:match('twitter%.com')
               and not href:match('discord%.gg') and not href:match('google%.com')
               and not href:match(base:match('^https?://([^/]+)') or "\0") then
                result.link = href
                break
            end
        end
    end

    return result.link, result.key
end

-- --------------------------------------------------------------------------
-- Core: resolve a link by following the chain as far as it goes.
-- --------------------------------------------------------------------------

function Bypass.resolve(start_url)
    assert(type(start_url) == "string" and start_url ~= "", "resolve(url): url required")
    if not start_url:match("^https?://") then
        start_url = "https://" .. start_url
    end

    local out = {
        input = start_url,
        final = start_url,
        key   = nil,
        chain = {},
        ok    = false,
        note  = nil,
    }

    local current = start_url
    local seen = {}

    for hop = 1, Bypass.MAX_HOPS do
        if seen[current] then
            out.note = "loop detected at hop " .. hop
            break
        end
        seen[current] = true
        table.insert(out.chain, current)

        -- 1) Destination baked into the query string? Jump straight there.
        local q = target_from_query(current)
        if q and q ~= current and not seen[q] then
            out.final = q
            current = q
        end

        -- 2) Make the request.
        local res = http_raw(current)
        if not res then
            out.note = "request failed at hop " .. hop
            break
        end

        -- 3) 3xx redirect via Location header.
        local loc = res.headers["location"]
        if res.status and res.status >= 300 and res.status < 400 and loc then
            current = absolutize(current, loc)
            out.final = current
        else
            -- 4) Header-level refresh, or scrape the body.
            local refresh_h = res.headers["refresh"]
            local refresh_url = refresh_h and refresh_h:match("[Uu][Rr][Ll]=(.+)$")
            local link, key = scrape(res.body, current)
            if key and not out.key then out.key = key end

            local next_url = (refresh_url and absolutize(current, trim(refresh_url))) or link
            if next_url and next_url ~= current and not seen[next_url] then
                current = next_url
                out.final = next_url
            else
                -- Nowhere left to go: this is the destination.
                if link then out.final = link end
                out.ok = true
                break
            end
        end
    end

    if not out.ok and #out.chain >= Bypass.MAX_HOPS then
        out.note = "hit max hops (" .. Bypass.MAX_HOPS .. ")"
    end
    if out.final and out.final ~= out.input then out.ok = true end
    return out
end

-- Convenience: just give me the final URL string.
function Bypass.bypass(url)
    local r = Bypass.resolve(url)
    return r.final, r.key
end

-- Copy helper for executors that expose a clipboard function.
function Bypass.copy(text)
    local clip = setclipboard or toclipboard or (Clipboard and Clipboard.set)
    if type(clip) == "function" then pcall(clip, text) return true end
    return false
end

-- --------------------------------------------------------------------------
-- Optional GUI (only builds when run inside a Roblox client).
-- --------------------------------------------------------------------------

local function build_gui()
    local players = game:GetService("Players")
    local ok, gui = pcall(function()
        local root = Instance.new("ScreenGui")
        root.Name = "LinkBypasser"
        root.ResetOnSpawn = false
        root.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
        root.Parent = (gethui and gethui())
            or (players.LocalPlayer and players.LocalPlayer:WaitForChild("PlayerGui"))
            or game:GetService("CoreGui")

        local frame = Instance.new("Frame")
        frame.Size = UDim2.fromOffset(380, 190)
        frame.Position = UDim2.new(0.5, -190, 0.35, 0)
        frame.BackgroundColor3 = Color3.fromRGB(24, 24, 30)
        frame.BorderSizePixel = 0
        frame.Active = true
        frame.Draggable = true
        frame.Parent = root
        Instance.new("UICorner", frame).CornerRadius = UDim.new(0, 10)

        local title = Instance.new("TextLabel")
        title.Size = UDim2.new(1, 0, 0, 34)
        title.BackgroundTransparency = 1
        title.Text = "  Link Bypasser  v" .. Bypass.VERSION
        title.TextColor3 = Color3.fromRGB(235, 235, 245)
        title.Font = Enum.Font.GothamBold
        title.TextSize = 15
        title.TextXAlignment = Enum.TextXAlignment.Left
        title.Parent = frame

        local input = Instance.new("TextBox")
        input.Size = UDim2.new(1, -24, 0, 38)
        input.Position = UDim2.fromOffset(12, 44)
        input.BackgroundColor3 = Color3.fromRGB(38, 38, 48)
        input.PlaceholderText = "Paste gated / short link here..."
        input.Text = ""
        input.TextColor3 = Color3.fromRGB(240, 240, 240)
        input.PlaceholderColor3 = Color3.fromRGB(140, 140, 150)
        input.Font = Enum.Font.Gotham
        input.TextSize = 13
        input.ClearTextOnFocus = false
        input.TextXAlignment = Enum.TextXAlignment.Left
        input.TextWrapped = true
        input.Parent = frame
        Instance.new("UICorner", input).CornerRadius = UDim.new(0, 6)
        local pad = Instance.new("UIPadding", input)
        pad.PaddingLeft = UDim.new(0, 8); pad.PaddingRight = UDim.new(0, 8)

        local status = Instance.new("TextLabel")
        status.Size = UDim2.new(1, -24, 0, 48)
        status.Position = UDim2.fromOffset(12, 90)
        status.BackgroundColor3 = Color3.fromRGB(30, 30, 38)
        status.Text = "Ready."
        status.TextColor3 = Color3.fromRGB(180, 220, 180)
        status.Font = Enum.Font.Code
        status.TextSize = 12
        status.TextWrapped = true
        status.TextXAlignment = Enum.TextXAlignment.Left
        status.TextYAlignment = Enum.TextYAlignment.Top
        status.Parent = frame
        Instance.new("UICorner", status).CornerRadius = UDim.new(0, 6)
        local pad2 = Instance.new("UIPadding", status)
        pad2.PaddingLeft = UDim.new(0, 8); pad2.PaddingTop = UDim.new(0, 6)

        local btn = Instance.new("TextButton")
        btn.Size = UDim2.new(1, -24, 0, 30)
        btn.Position = UDim2.fromOffset(12, 148)
        btn.BackgroundColor3 = Color3.fromRGB(70, 110, 200)
        btn.Text = "Bypass"
        btn.TextColor3 = Color3.fromRGB(255, 255, 255)
        btn.Font = Enum.Font.GothamBold
        btn.TextSize = 14
        btn.Parent = frame
        Instance.new("UICorner", btn).CornerRadius = UDim.new(0, 6)

        btn.MouseButton1Click:Connect(function()
            local url = trim(input.Text)
            if url == "" then
                status.Text = "Paste a link first."
                status.TextColor3 = Color3.fromRGB(230, 180, 120)
                return
            end
            status.Text = "Resolving..."
            status.TextColor3 = Color3.fromRGB(200, 200, 120)
            task.spawn(function()
                local r = Bypass.resolve(url)
                local msg = "Final: " .. tostring(r.final)
                if r.key then msg = msg .. "\nKey: " .. r.key end
                msg = msg .. "\nHops: " .. #r.chain
                if r.note then msg = msg .. "  (" .. r.note .. ")" end
                status.Text = msg
                status.TextColor3 = r.ok and Color3.fromRGB(150, 220, 150)
                                          or Color3.fromRGB(230, 150, 150)
                Bypass.copy(r.key or r.final)
            end)
        end)

        return root
    end)
    return ok and gui or nil
end

-- Auto-launch the GUI only when executed directly inside a running client.
local is_client = pcall(function() return game:GetService("RunService"):IsClient() end)
if is_client and not script then
    -- Executor context: no `script` global, we're the top-level chunk.
    build_gui()
end

Bypass.buildGui = build_gui
return Bypass
