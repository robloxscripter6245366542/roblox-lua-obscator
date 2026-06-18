-- Volt AI — DeepSeek module (SECOND loadstring).
--
-- Load this AFTER Volt.lua. It registers getgenv().VoltAI(messages) -> reply,
-- which Volt's AI tab calls.
--
-- Backend selection:
--   * If getgenv().VoltConfig.aiProxy is set, it routes through that proxy
--     (key stays server-side):  client --HTTPS--> /api/ai --> DeepSeek
--   * Otherwise it calls DeepSeek directly with the embedded (obfuscated) key
--     so the AI works out-of-the-box with no server setup.

local HttpService = game:GetService("HttpService")
local cfg = (getgenv and getgenv().VoltConfig) or {}

-- embedded DeepSeek key — multi-layer obfuscated (reversed order + index-mixed
-- XOR + per-index offset); decoded at runtime, no plaintext in the file.
local function decodeKey()
    local d={80,206,214,162,157,124,117,193,213,235,243,41,117,115,138,187,129,181,39,69,14,52,55,225,212,155,182,146,184,51,254,208,42,50,84}
    local n=#d local o={}
    for i=1,n do
        local b=bit32.bxor(d[n-i+1], (i*29+17)%256)
        o[i]=string.char((b-i*7)%256)
    end
    return table.concat(o)
end

local PROXY = cfg.aiProxy            -- optional: route through a server proxy
local TOKEN = cfg.aiToken
local KEY   = cfg.deepseekKey or decodeKey()
local MODEL = cfg.deepseekModel or "deepseek-chat"

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
    local url, headers, body
    if PROXY and PROXY ~= "" then
        -- proxy mode: send only {messages}; server attaches the key
        url = PROXY
        headers = { ["Content-Type"] = "application/json" }
        if TOKEN then headers["x-volt-token"] = TOKEN end
        body = HttpService:JSONEncode({ messages = messages })
    else
        -- direct mode: call DeepSeek with the embedded key
        url = "https://api.deepseek.com/chat/completions"
        headers = {
            ["Content-Type"]  = "application/json",
            ["Authorization"] = "Bearer " .. KEY,
        }
        body = HttpService:JSONEncode({ model = MODEL, messages = messages, stream = false })
    end

    local res, err = httpRequest({ Url = url, Method = "POST", Headers = headers, Body = body })
    if not res then return "⚠ AI request failed: " .. tostring(err) end

    local code = res.StatusCode or res.status_code or 0
    local raw  = res.Body or res.body or ""
    local ok, decoded = pcall(function() return HttpService:JSONDecode(raw) end)
    if ok and decoded then
        -- proxy returns {reply=...}; DeepSeek returns {choices=[{message={content}}]}
        if decoded.reply and decoded.reply ~= "" then return decoded.reply end
        if decoded.choices and decoded.choices[1] and decoded.choices[1].message
           and decoded.choices[1].message.content ~= "" then
            return decoded.choices[1].message.content
        end
        if decoded.error then
            local e = decoded.error
            return "⚠ DeepSeek: " .. tostring((type(e)=="table" and (e.message or e.type)) or e)
        end
    end
    return "⚠ DeepSeek returned " .. tostring(code)
end

if getgenv then getgenv().VoltAI = VoltAI end
return VoltAI
