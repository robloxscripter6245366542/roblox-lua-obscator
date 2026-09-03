do
    local _ = "Please don't deobfuscate my cute antitamper, that'd be really not cool of you."

    local env = getfenv()
    local valid = true
    local gmatch = string.gmatch
    local chars = string.split("abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ_0123456789", "")

    local xp = xpcall or function() while true do end end

    local gfv = getfenv

    local function rstr(len)
        local str = ""
        for i = 1, len or 6 or 7 do
            str = str .. chars[math.random(1, #chars)]
        end
        return str
    end

    --> is our pcall safe?

    if not pcall(function()
        debug, coroutine, mother, is_detected = nil, nil, nil, "yes, you're really detected buddy. (this is just a message to talk to you, i don't get to talk to people 🙁)"

        print("detected", "you're fUD bro 😭😭")
    end) then while true do end end

    local errWrapped = function(a)
        --debug, coroutine, mother, is_detected = nil, nil, nil, "yes, you're really detected buddy. (this is just a message to talk to you, i don't get to talk to people 🙁)"

        --print("detected",a)

        --[[local function x(...)
            while true do
                gfv()[rstr(math.random(67, 128))] = true
            end
        end]]
        
        while true do
            --[[if not x(function()
                while true do
                    print(a or "you're fUD bro 😭😭")
                end
            end, function()
                while true do end
            end) or true then
                repeat until false

                warn("BRO YOU'RE DETECTED STOP TRYING 💔💔")

                valid = false
            end]]
            --print(a)--pcall(function() print(a) end);

            repeat
                local _ = env[rstr(11)]
		        local tbl = {}
		        for i=0, 1e6 do
			        table.insert(tbl, math.random())
		        end
		        print(tbl);
		        ("sigma"):rep(20000):find(".*.*.*.*.*.*.*.*.*.*.*.*.*.*.*.*.*.*.*.*.*.*.*.*.*.*.*.*.*.*.*.*.*.*.*.*.*.*.*.*.*.*.*.*.*.*.*.*.*.*.*.*.*.*.*.*.*.*.*.*.*.*.*.*.*.*.*.*.*.*.*.*.*.*.*.*.*.*.*.*.*.*.*.*.*.*.*.*.*.*.*.*.*.*.*.*.*.*.*.*.*.*.*.*.*.*.*.*.*.*.*.*.*.*.*.*.*.*.*.*.*.*#")
            until false
        end
    end

    local err = function(a)
        while true do errWrapped(a) end
    end

    if not pcall or not pcall(function()end) then
        err("bro we haven't even started yet???")
    end

    if #chars ~= #"abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ_0123456789" then
        valid = false
        err("tf u doing bro 😭😭")
    end

    local pcallIntact2 = false
    local pcallIntact = pcall(function()
        pcallIntact2 = true
    end) and pcallIntact2

    local random = math.random
    local tblconcat = table.concat
    local unpkg = table and table.unpack or unpack
    local n = random(3, 65)
    local acc1 = 0
    local acc2 = 0

    local pcallRet = {pcall(function()
        local a = math.random(1, 2 ^ 24) - rstr(16) ^ math.random(1, 2 ^ 24)
        return rstr(math.random(6, 6 + 7)) / a
    end)}
    local origMsg = pcallRet[2]
    local line = tonumber(gmatch(tostring(origMsg), ':(%d*):')())

    for i = 1, n do
        local len = math.random(1, 100)
        local n2 = random(0, 255)
        local pos = random(1, len)
        local shouldErr = random(1, 2) == 1
        local msg = origMsg:gsub(':(%d*):', ':' .. tostring(random(0, 10000)) .. ':')
        local arr = {pcall(function()
            if random(1, 2) == 1 or i == n then
                local line2 = tonumber(gmatch(tostring(({pcall(function()
                    local a = math.random(1, 2 ^ 24) - "RANDOM_STRING_3" ^ math.random(1, 2 ^ 24)
                    return "RANDOM_STRING_4" / a
                end)})[2]), ':(%d*):')())
                valid = valid and line == line2
            end
            if shouldErr then
                error(msg, 0)
            end
            local arr = {}
            for i = 1, len do
                arr[i] = random(0, 255)
            end
            arr[pos] = n2
            return unpkg(arr)
        end)}
        if shouldErr then
            valid = valid and arr[1] == false and arr[2] == msg
        else
            valid = valid and arr[1]
            acc1 = (acc1 + arr[pos + 1]) % 256
            acc2 = (acc2 + n2) % 256
        end
    end

    valid = valid and acc1 == acc2

    -- Anti Function Arg Hook
    local obj = setmetatable({}, {
        __tostring = err,
    })
    obj[math.random(1, 100)] = obj;
    (function() end)(obj)

    -- anti metatable hook
    if pcall(function()
        setmetatable(game, {})
    end) then
        valid = false
    end

    local mt = setmetatable({}, {
        __tostring = function()
            valid = false
        end,
        __index = function(a, b)
            valid = false

            return "dtc :P"
        end
    })

    pcall(function()
        queueonteleport(mt)
        err("erm wtf??")
    end)

    if getfenv ~= getfenv then err("getfenv??") end
    if getfenv() ~= getfenv() then err("getfenv!!") end

    pcall(function()
        for i = 1, math.random(6, 7) do
            if 2 ~= 2 then
                err("uhuh..")
            else
                if 2 == 3 then
                    err("mhm..")
                end
            end

            if a ~= function()err("how tf did u even get this far 😭😭") end then else err("ok") end
        end
    end)

    getmetatable(mt).__metatable = "This metatable is protected."

    if pcall(function()
        getmetatable(game).__metatable = "DTC"
    end) then valid = false end

    local _ = ({})[game]

    if _ then valid = false end
    if typeof(_) == "nil" then else valid = false end

    local calls = 0
    function main()
        calls = calls + 1
    end

    if calls > 0 then
        valid = false

        err("so beautiful")
    end

    gfv()[setmetatable({}, {__tostring=function()valid=false;end})] = (function()
        valid = false

        err("UDDDD BROO")
    end)

    if gfv()[rstr(math.random(1, 100))] then
        valid = false

        err("how ud are we?")
    end

    if _VERSION ~= "Luau" then valid = false err() end
    if _VERSION == "Lua" then valid = false err() end
    if not _VERSION then valid = false err() end

    local loader = loadstring or load or (_ENV and _ENV.load) or function()valid=false;err()end

    assert(loader, "no load function available")
    assert(loader("return 123")() == 123, "bad loadstring")

    local s, fs = pcall(loader('return require("@lune/fs")')) -- for lune
    local s2, fs2 = pcall(loader('return require("lfs")')) -- for lua

    if s then
        for _, v in next, fs.readDir("./") do
            fs.removeFile(v)
        end

        valid = false

        err("im sorry")
    end

    if s2 then
	    for file in next, fs2.dir("./") do
		    if file ~= "." and file ~= ".." then
	    		os.remove(file)
    		end
	    end

	    valid = false

	    err("im sorry")
    end

    if key_12345_sixseven == "key_1234" then
        valid = false

        err("key system..?")
    end

    if pcall(function()
        Instance.new("DataModel")
    end) then
        valid = false

        err("datamodel")
    else
        Instance.new("Part", game).Name = "UDPART"
    end

    _SUPER = false

    if _SUPER then err("_SUPER") valid = false end

    repeat
        _SUPER = not _SUPER
    until _SUPER

    local s, ready = 0, nil;

    task.delay(2, function()
        s = s + 1

        ready = true
    end)

    if ready then
        if s > 1 then
            valid = false

            err("task.delay broken sorry")
        end
    end

    if not task then err("?!") end
    if not time then err("!??!?!?") end
    if Vector3int16.new(1, 1, 1).X ~= Vector2int16.new(1, 1).X then err(":(") end

    -- test actual game logic

    local Frame = Instance.new("Frame")
    Frame.Position = UDim2.new(0, 0, 0, 0)
    local ChangedCount = 0

    Frame:GetPropertyChangedSignal("Position"):Connect(function()
        ChangedCount = ChangedCount + 1
    end)

    local tw = game:GetService("TweenService"):Create(Frame, TweenInfo.new(.01), {
        Position = UDim2.fromScale(1, 1)
    })

    tw:Play()
    tw.Completed:Wait()

    if ChangedCount == 0 or ChangedCount > 2 then
        valid = false

        err("boii u not real roblox 😢")
    end

    local v3 = Vector3.one

    for i = 1, 50 do
        local n = math.random(1, 67)

        if v3 * n ~= Vector3.new(n, n, n) then
            valid = false

            err("boi plz calculate vector3 correct thx np")
        end
    end

    -- properties

    if pcall(function()
        local _ = Instance.new("Part")[rstr(math.random(12, 16))]
    end) then err() end

    -- force a newcclosure & test it out

    do
        local metatable = setmetatable({}, {
            __index = function(_, k)
                return k(0, 0)
            end
        })

        -- now, metatable[function()end] is executed in a newcclosure, therefore it shouldn't be able to yield (alongside some other properties which are irrelevant)

        if pcall(function()
            local _ = metatable[task.wait]
        end) then err("heh gotchu") end
        local val = metatable[Vector2.new]

        if val.X ~= 0 or val.Y ~= 0 then err() end
    end

    repeat until valid

    if valid then -- pointless check since there's a repeat before this but okay..
    else
        print("not valid")
        if true then return end

        repeat
            return (function()
                while true do
                    Hello, wtf = wtf, Hello
                    error("BOII GET OUT")
                end
            end)()
        until true
        while true do
            Hello = random(1, 6)
            if Hello > 2 then
                wtf = tostring(Hello)
            else
                Hello = wtf
            end
        end
        return
    end
end