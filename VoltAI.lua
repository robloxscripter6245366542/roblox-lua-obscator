-- Volt AI — DeepSeek module (SECOND loadstring).
--
-- Load this AFTER Volt.lua. It registers getgenv().VoltAI(messages) -> reply,
-- which Volt's AI tab calls. Requests go through the encrypted proxy so the
-- DeepSeek API key never touches the client:
--
--     Volt (client) --HTTPS--> /api/ai --Bearer key--> DeepSeek
--
-- The proxy holds DEEPSEEK_KEY as a server-side env var. Self-host? override:
--     getgenv().VoltConfig = { aiProxy = "https://your-app.vercel.app/api/ai" }
-- before running this loadstring.

local HttpService = game:GetService("HttpService")

local cfg = (getgenv and getgenv().VoltConfig) or {}
local PROXY = cfg.aiProxy or "https://roblox-lua-obscator.vercel.app/api/ai"
local TOKEN = cfg.aiToken

-- executor-agnostic POST
local function httpRequest(opts)
    local fn = (syn and syn.request) or (http and http.request)
        or http_request or request or (fluxus and fluxus.request)
    if type(fn) ~= "function" then return nil, "no executor HTTP function" end
    local ok, res = pcall(fn, opts)
    if not ok then return nil, tostring(res) end
    return res
end

-- messages: OpenAI-style array {{role=,content=},...}  ->  reply string
local function VoltAI(messages)
    local headers = { ["Content-Type"] = "application/json" }
    if TOKEN then headers["x-volt-token"] = TOKEN end

    local res, err = httpRequest({
        Url     = PROXY,
        Method  = "POST",
        Headers = headers,
        Body    = HttpService:JSONEncode({ messages = messages }),
    })
    if not res then return "⚠ AI request failed: " .. tostring(err) end

    local code = res.StatusCode or res.status_code or 0
    local raw  = res.Body or res.body or ""
    local ok, decoded = pcall(function() return HttpService:JSONDecode(raw) end)
    if code >= 200 and code < 300 and ok and decoded and decoded.reply and decoded.reply ~= "" then
        return decoded.reply
    end
    -- surface a useful server error (missing key, upstream 402, etc.)
    if ok and decoded and decoded.error then
        return "⚠ DeepSeek proxy: " .. tostring(decoded.error)
    end
    return "⚠ DeepSeek proxy returned " .. tostring(code)
end

if getgenv then getgenv().VoltAI = VoltAI end
return VoltAI
