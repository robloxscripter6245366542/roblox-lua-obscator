-- Crystal HTTP/HTTPS Module
-- Built-in networking for Crystal programs.
-- Works in both Roblox (via HttpService) and standard Lua (via socket/curl).
-- Usage from Crystal: HTTP.get(url), HTTP.post(url, body), HTTP.fetch(url, opts)

local HTTP = {}

-- ── Detect environment ────────────────────────────────────────────────────────

local isRoblox = (game ~= nil and typeof ~= nil)

-- ── Roblox HttpService backend ────────────────────────────────────────────────

local function robloxBackend()
    local HttpService = game:GetService("HttpService")

    local function request(method, url, opts)
        opts = opts or {}
        local ok, result = pcall(function()
            return HttpService:RequestAsync({
                Url     = url,
                Method  = method:upper(),
                Headers = opts.headers or { ["Content-Type"] = "application/json" },
                Body    = opts.body and (
                    type(opts.body) == "table"
                        and HttpService:JSONEncode(opts.body)
                        or tostring(opts.body)
                ) or nil,
            })
        end)

        if not ok then
            return { ok = false, status = 0, body = nil, error = tostring(result) }
        end

        local res = result
        local body = res.Body
        -- Auto-decode JSON
        if body and (res.Headers["Content-Type"] or ""):find("application/json") then
            local jok, json = pcall(function() return HttpService:JSONDecode(body) end)
            if jok then body = json end
        end

        return {
            ok      = res.Success,
            status  = res.StatusCode,
            headers = res.Headers,
            body    = body,
            raw     = res.Body,
        }
    end

    return {
        get = function(url, opts)
            return request("GET", url, opts)
        end,
        post = function(url, body, opts)
            opts = opts or {}
            opts.body = body
            return request("POST", url, opts)
        end,
        put = function(url, body, opts)
            opts = opts or {}
            opts.body = body
            return request("PUT", url, opts)
        end,
        patch = function(url, body, opts)
            opts = opts or {}
            opts.body = body
            return request("PATCH", url, opts)
        end,
        delete = function(url, opts)
            return request("DELETE", url, opts)
        end,
        fetch = function(url, opts)
            opts = opts or {}
            local method = (opts.method or "GET"):upper()
            return request(method, url, opts)
        end,
        json = function(url, opts)
            local res = request("GET", url, opts)
            if not res.ok then return nil, res.error end
            if type(res.body) == "table" then return res.body end
            local jok, json = pcall(function()
                return HttpService:JSONDecode(res.raw or "")
            end)
            if jok then return json end
            return nil, "JSON parse failed"
        end,
        encode = function(t) return HttpService:JSONEncode(t) end,
        decode = function(s) return HttpService:JSONDecode(s) end,
    }
end

-- ── Standard Lua backend (via os.execute / io.popen with curl) ───────────────

local function luaBackend()
    local function curl(method, url, opts)
        opts = opts or {}
        local cmd = { "curl", "-s", "-X", method:upper(),
            "-H", "Content-Type: application/json",
            "--max-time", tostring(opts.timeout or 10),
        }
        if opts.headers then
            for k, v in pairs(opts.headers) do
                cmd[#cmd+1] = "-H"
                cmd[#cmd+1] = k .. ": " .. v
            end
        end
        if opts.body then
            local body = type(opts.body) == "table"
                and require("json").encode(opts.body)
                or tostring(opts.body)
            cmd[#cmd+1] = "-d"
            cmd[#cmd+1] = body
        end
        cmd[#cmd+1] = "-w"
        cmd[#cmd+1] = "\\n__STATUS__%{http_code}"
        cmd[#cmd+1] = url

        local handle = io.popen(table.concat(cmd, " "))
        if not handle then
            return { ok = false, status = 0, body = nil, error = "curl not available" }
        end
        local raw = handle:read("*a")
        handle:close()

        local body, statusStr = raw:match("^(.*)\n__STATUS__(%d+)$")
        local status = tonumber(statusStr) or 0
        return {
            ok     = status >= 200 and status < 300,
            status = status,
            body   = body,
            raw    = body,
        }
    end

    return {
        get    = function(url, opts) return curl("GET",    url, opts) end,
        post   = function(url, b, o) o=o or{}; o.body=b; return curl("POST", url, o) end,
        put    = function(url, b, o) o=o or{}; o.body=b; return curl("PUT",  url, o) end,
        patch  = function(url, b, o) o=o or{}; o.body=b; return curl("PATCH",url, o) end,
        delete = function(url, opts) return curl("DELETE", url, opts) end,
        fetch  = function(url, opts)
            opts = opts or {}
            return curl(opts.method or "GET", url, opts)
        end,
        json = function(url, opts)
            local res = curl("GET", url, opts)
            if not res.ok then return nil, res.error end
            local ok2, json = pcall(function() return require("json").decode(res.body) end)
            if ok2 then return json end
            return nil, "JSON parse failed"
        end,
    }
end

-- ── Async wrappers (Roblox task.spawn based) ─────────────────────────────────

local function wrapAsync(backend)
    local asyncAPI = {}
    for method, fn in pairs(backend) do
        asyncAPI[method] = fn
        asyncAPI[method .. "Async"] = function(...)
            local args = {...}
            local done, result, err2 = false, nil, nil
            task.spawn(function()
                local ok, res = pcall(fn, table.unpack(args))
                if ok then result = res else err2 = res end
                done = true
            end)
            -- Return a Promise-like object
            local callbacks = {}
            local errbacks  = {}
            local p = {}
            function p:andThen(fn2)
                if done then
                    if result then fn2(result) end
                else
                    callbacks[#callbacks+1] = fn2
                end
                return self
            end
            function p:catch(fn2)
                if done and err2 then fn2(err2)
                else errbacks[#errbacks+1] = fn2 end
                return self
            end
            -- Poll until done (non-blocking in Roblox)
            task.spawn(function()
                while not done do task.wait() end
                if result then
                    for _, cb in ipairs(callbacks) do cb(result) end
                else
                    for _, cb in ipairs(errbacks)  do cb(err2)   end
                end
            end)
            return p
        end
    end
    return asyncAPI
end

-- ── Query string builder ──────────────────────────────────────────────────────

function HTTP.buildQuery(params)
    local parts = {}
    for k, v in pairs(params) do
        parts[#parts+1] = tostring(k) .. "=" .. tostring(v)
    end
    return table.concat(parts, "&")
end

function HTTP.appendQuery(url, params)
    local qs = HTTP.buildQuery(params)
    if qs == "" then return url end
    return url .. (url:find("?") and "&" or "?") .. qs
end

-- ── Initialize correct backend ────────────────────────────────────────────────

local backend = isRoblox and robloxBackend() or luaBackend()
if isRoblox then
    backend = wrapAsync(backend)
end

-- Merge backend methods into HTTP
for k, v in pairs(backend) do
    HTTP[k] = v
end

-- ── Convenience helpers ───────────────────────────────────────────────────────

-- GET and auto-parse JSON
function HTTP.getJSON(url, opts)
    local res = HTTP.get(url, opts)
    if not res.ok then return nil, ("HTTP %d"):format(res.status) end
    if type(res.body) == "table" then return res.body, nil end
    local ok2, t = pcall(function()
        if isRoblox then
            return game:GetService("HttpService"):JSONDecode(res.raw or "")
        end
        return require("json").decode(res.raw or "")
    end)
    if ok2 then return t, nil end
    return nil, "JSON parse error"
end

-- POST JSON body, return parsed JSON
function HTTP.postJSON(url, body, opts)
    opts = opts or {}
    opts.headers = opts.headers or {}
    opts.headers["Content-Type"] = "application/json"
    local res = HTTP.post(url, body, opts)
    if not res.ok then return nil, ("HTTP %d"):format(res.status) end
    if type(res.body) == "table" then return res.body, nil end
    return res.raw, nil
end

-- Check if HTTPS is available (Roblox only: HttpService must be enabled)
function HTTP.isAvailable()
    if not isRoblox then return true end
    local ok = pcall(function()
        game:GetService("HttpService"):GetAsync("https://example.com")
    end)
    return ok
end

return HTTP
