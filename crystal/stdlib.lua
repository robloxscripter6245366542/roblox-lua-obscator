-- Crystal Standard Library
-- Injected into the VM globals automatically

local stdlib = {}

-- ── String ────────────────────────────────────────────────────────────────────
stdlib.String = {
    upper   = string.upper,
    lower   = string.lower,
    rep     = string.rep,
    reverse = string.reverse,
    sub     = string.sub,
    find    = string.find,
    format  = string.format,
    split   = function(s, sep)
        local result = {}
        for part in (s .. sep):gmatch("(.-)" .. sep:gsub("%p","%%%1")) do
            result[#result+1] = part
        end
        return result
    end,
    trim = function(s)
        return s:match("^%s*(.-)%s*$")
    end,
    startsWith = function(s, prefix)
        return s:sub(1, #prefix) == prefix
    end,
    endsWith = function(s, suffix)
        return suffix == "" or s:sub(-#suffix) == suffix
    end,
    contains = function(s, sub)
        return s:find(sub, 1, true) ~= nil
    end,
}

-- ── Array ────────────────────────────────────────────────────────────────────
stdlib.Array = {
    push = function(arr, v)
        arr[#arr+1] = v
    end,
    pop = function(arr)
        local v = arr[#arr]
        arr[#arr] = nil
        return v
    end,
    shift = function(arr)
        return table.remove(arr, 1)
    end,
    unshift = function(arr, v)
        table.insert(arr, 1, v)
    end,
    slice = function(arr, i, j)
        local result = {}
        for k = i, j or #arr do
            result[#result+1] = arr[k]
        end
        return result
    end,
    map = function(arr, fn)
        local result = {}
        for i, v in ipairs(arr) do
            result[i] = fn(v)
        end
        return result
    end,
    filter = function(arr, fn)
        local result = {}
        for _, v in ipairs(arr) do
            if fn(v) then result[#result+1] = v end
        end
        return result
    end,
    reduce = function(arr, fn, init)
        local acc = init
        for _, v in ipairs(arr) do
            acc = fn(acc, v)
        end
        return acc
    end,
    find = function(arr, fn)
        for _, v in ipairs(arr) do
            if fn(v) then return v end
        end
    end,
    includes = function(arr, val)
        for _, v in ipairs(arr) do
            if v == val then return true end
        end
        return false
    end,
    join = function(arr, sep)
        local parts = {}
        for _, v in ipairs(arr) do parts[#parts+1] = tostring(v) end
        return table.concat(parts, sep or "")
    end,
    sort = function(arr, fn)
        table.sort(arr, fn)
        return arr
    end,
    len = function(arr)
        return #arr
    end,
    flat = function(arr)
        local result = {}
        local function flatten(t)
            for _, v in ipairs(t) do
                if type(v) == "table" then flatten(v)
                else result[#result+1] = v end
            end
        end
        flatten(arr)
        return result
    end,
    reverse = function(arr)
        local r = {}
        for i = #arr, 1, -1 do r[#r+1] = arr[i] end
        return r
    end,
    unique = function(arr)
        local seen, result = {}, {}
        for _, v in ipairs(arr) do
            if not seen[v] then seen[v] = true; result[#result+1] = v end
        end
        return result
    end,
}

-- ── Math ─────────────────────────────────────────────────────────────────────
stdlib.Math = {
    abs   = math.abs,
    ceil  = math.ceil,
    floor = math.floor,
    round = function(n) return math.floor(n + 0.5) end,
    sqrt  = math.sqrt,
    sin   = math.sin,
    cos   = math.cos,
    tan   = math.tan,
    atan2 = math.atan2 or function(y,x) return math.atan(y,x) end,
    max   = math.max,
    min   = math.min,
    pi    = math.pi,
    huge  = math.huge,
    random = function(a, b)
        if a and b then return math.random(a, b)
        elseif a then return math.random(a)
        else return math.random() end
    end,
    clamp = function(v, lo, hi)
        return math.max(lo, math.min(hi, v))
    end,
    lerp = function(a, b, t)
        return a + (b - a) * t
    end,
    sign = function(n)
        if n > 0 then return 1 elseif n < 0 then return -1 else return 0 end
    end,
}

-- ── Table / Object ───────────────────────────────────────────────────────────
stdlib.Object = {
    keys = function(t)
        local r = {}
        for k in pairs(t) do r[#r+1] = k end
        return r
    end,
    values = function(t)
        local r = {}
        for _, v in pairs(t) do r[#r+1] = v end
        return r
    end,
    entries = function(t)
        local r = {}
        for k, v in pairs(t) do r[#r+1] = { k, v } end
        return r
    end,
    assign = function(target, ...)
        for _, src in ipairs({...}) do
            for k, v in pairs(src) do target[k] = v end
        end
        return target
    end,
    clone = function(t)
        local r = {}
        for k, v in pairs(t) do r[k] = v end
        return r
    end,
    deepClone = function(t)
        local function dc(x)
            if type(x) ~= "table" then return x end
            local r = {}
            for k, v in pairs(x) do r[dc(k)] = dc(v) end
            return setmetatable(r, getmetatable(x))
        end
        return dc(t)
    end,
    freeze = function(t)
        return setmetatable({}, {
            __index = t,
            __newindex = function() error("Crystal: attempt to modify a frozen object") end,
        })
    end,
}

-- ── IO (Roblox-safe stubs) ───────────────────────────────────────────────────
stdlib.IO = {
    print = print,
    warn  = warn or print,
    read  = function() return nil end, -- no stdin in Roblox
    write = function(s) print(s) end,
}

-- ── Time ─────────────────────────────────────────────────────────────────────
stdlib.Time = {
    now   = os.time,
    clock = os.clock,
    wait  = task and task.wait or wait,
}

-- ── Event ────────────────────────────────────────────────────────────────────
stdlib.Event = {
    new = function()
        local handlers = {}
        return {
            connect = function(fn)
                handlers[#handlers+1] = fn
                return { disconnect = function()
                    for i, h in ipairs(handlers) do
                        if h == fn then table.remove(handlers, i); return end
                    end
                end}
            end,
            fire = function(...)
                for _, h in ipairs(handlers) do
                    h(...)
                end
            end,
        }
    end,
}

-- ── Promise (simple) ─────────────────────────────────────────────────────────
stdlib.Promise = {
    new = function(executor)
        local p = {
            _state    = "pending",
            _value    = nil,
            _handlers = {},
        }

        local function resolve(v)
            if p._state ~= "pending" then return end
            p._state = "fulfilled"; p._value = v
            for _, h in ipairs(p._handlers) do
                if h.onFulfilled then h.onFulfilled(v) end
            end
        end

        local function reject(e)
            if p._state ~= "pending" then return end
            p._state = "rejected"; p._value = e
            for _, h in ipairs(p._handlers) do
                if h.onRejected then h.onRejected(e) end
            end
        end

        task.spawn(executor, resolve, reject)

        function p:andThen(onFulfilled, onRejected)
            if self._state == "fulfilled" and onFulfilled then onFulfilled(self._value)
            elseif self._state == "rejected" and onRejected then onRejected(self._value)
            else self._handlers[#self._handlers+1] = { onFulfilled = onFulfilled, onRejected = onRejected }
            end
            return self
        end

        function p:catch(fn)
            return self:andThen(nil, fn)
        end

        return p
    end,
}

return stdlib
